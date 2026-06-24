#!/usr/bin/env bash
# PostgreSQL major-version migration script
# Run on the Proxmox host (or LXC) AFTER git pull but BEFORE docker compose up -d
#
# Usage:
#   ./scripts/pg-migrate.sh [instance...]
#   ./scripts/pg-migrate.sh all          # run all in order
#   ./scripts/pg-migrate.sh openwebui    # single instance
#
# Workflow:
#   git pull                              # compose files now reference PG18
#   bash scripts/pg-migrate.sh all       # migrates data for each instance
#   docker compose up -d                  # everything starts on PG18

set -euo pipefail

STACKS=/mnt/fast/stacks/stacks/selfhosted
BACKUP_DIR=/tmp/pg-backups
mkdir -p "$BACKUP_DIR"

# ─── core migration function ──────────────────────────────────────────────────
# migrate_pg CONTAINER STACK_DIR COMPOSE_FILE PG_SERVICE [EXTRA_SQL]
#   CONTAINER    = running docker container name
#   STACK_DIR    = path to the stack directory (for docker compose commands)
#   COMPOSE_FILE = compose file name within STACK_DIR (e.g. compose.yaml)
#   PG_SERVICE   = service name inside the compose file
#   EXTRA_SQL    = optional SQL to run in new container after restore (e.g. ALTER EXTENSION)
migrate_pg() {
  local container="$1"
  local stack_dir="$2"
  local compose_file="$3"
  local pg_service="$4"
  local extra_sql="${5:-}"

  local backup="$BACKUP_DIR/${container}.sql"

  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  Migrating: $container"
  echo "  Stack:     $stack_dir/$compose_file"
  echo "══════════════════════════════════════════════════"

  # Check container is actually running
  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "  SKIP: $container is not running — skipping"
    return 0
  fi

  # Show current PG version
  local old_ver dump_user restore_user
  old_ver=$(docker exec "$container" sh -c \
    'psql -U "${POSTGRES_USER:-postgres}" -tAc "SHOW server_version;" 2>/dev/null || echo unknown')
  dump_user=$(docker exec "$container" sh -c 'echo ${POSTGRES_USER:-postgres}' 2>/dev/null || echo "postgres")
  restore_user="$dump_user"
  echo "  Current version: $old_ver  (user: $dump_user)"

  # 1. Dump all databases
  echo "  → Dumping to $backup ..."
  docker exec "$container" pg_dumpall -U "$dump_user" > "$backup"
  echo "  → Dump complete ($(du -sh "$backup" | cut -f1))"

  # 2. Locate the data directory on the host so we can clear it for PG18.
  #
  # PG18 Docker images changed their storage layout: they expect the volume
  # mounted at /var/lib/postgresql and init data inside a versioned subdir
  # (e.g. 18/docker/ for Alpine, 18/main/ for Debian).  Old data at the
  # volume root triggers a "PostgreSQL data already here" abort.
  #
  # Three mount patterns to handle:
  #   a) Direct bind mount at /var/lib/postgresql/data (pre-PG18 standard)
  #   b) Direct bind mount at /var/lib/postgresql (PG18 standard)
  #   c) Named volume (type: none, o: bind) — Docker reports Type=volume but
  #      the real data is at the "device" path in the volume options, NOT at
  #      /var/lib/docker/volumes/…/_data.  We must use `docker volume inspect`
  #      to find the actual host path.
  local pgdata_src
  pgdata_src=""

  # Case a: direct bind at /var/lib/postgresql/data
  pgdata_src=$(docker inspect "$container" \
    --format '{{range .Mounts}}{{if and (eq .Type "bind") (eq .Destination "/var/lib/postgresql/data")}}{{.Source}}{{end}}{{end}}' \
    2>/dev/null || echo "")

  # Case b: direct bind at /var/lib/postgresql
  if [ -z "$pgdata_src" ]; then
    pgdata_src=$(docker inspect "$container" \
      --format '{{range .Mounts}}{{if and (eq .Type "bind") (eq .Destination "/var/lib/postgresql")}}{{.Source}}{{end}}{{end}}' \
      2>/dev/null || echo "")
  fi

  # Case c: named volume (look up the real device path)
  if [ -z "$pgdata_src" ]; then
    local vol_name
    vol_name=$(docker inspect "$container" \
      --format '{{range .Mounts}}{{if and (eq .Type "volume") (eq .Destination "/var/lib/postgresql/data")}}{{.Name}}{{end}}{{end}}' \
      2>/dev/null || echo "")
    if [ -z "$vol_name" ]; then
      vol_name=$(docker inspect "$container" \
        --format '{{range .Mounts}}{{if and (eq .Type "volume") (eq .Destination "/var/lib/postgresql")}}{{.Name}}{{end}}{{end}}' \
        2>/dev/null || echo "")
    fi
    if [ -n "$vol_name" ]; then
      # Bind-type named volume? Check for a "device" option.
      local dev_path
      dev_path=$(docker volume inspect "$vol_name" \
        --format '{{index .Options "device"}}' 2>/dev/null || echo "")
      if [ -n "$dev_path" ]; then
        pgdata_src="$dev_path"
        echo "  → Named volume $vol_name → bind device: $pgdata_src"
      else
        pgdata_src=$(docker volume inspect "$vol_name" --format '{{.Mountpoint}}' 2>/dev/null || echo "")
        echo "  → Named volume $vol_name → Docker-managed: $pgdata_src"
      fi
    fi
  fi

  # 3. Stop all services in the stack that depend on this postgres
  echo "  → Stopping stack ..."
  docker compose -f "${stack_dir}/${compose_file}" stop

  # 4. Remove old container (volume data is preserved on the host)
  echo "  → Removing old container ..."
  docker rm "$container" 2>/dev/null || true

  # 4b. Clear old PG data so PG18 can initialise a fresh cluster, then restore.
  #
  # PG18 stores data inside a versioned subdirectory (18/ for PG18).  The
  # postgres:18-alpine entrypoint runs two phases:
  #   1. As root: creates 18/ (mode 0770 due to root umask 007), then re-execs
  #      as the postgres user (UID 70 on Alpine, 999 on Debian).
  #   2. As postgres: mkdir -p 18/docker — but 18/ is root:root 0770 at this
  #      point, so "others" (UID 70) cannot traverse it → Permission denied.
  #
  # Fix: pre-create 18/ with chmod 777 BEFORE starting the container.  When
  # root's mkdir -p finds 18/ already exists, it skips creation (and thus does
  # not reset the mode), so UID 70 can still traverse it on the second pass.
  if [ -n "$pgdata_src" ] && [ -d "$pgdata_src" ]; then
    echo "  → Clearing old data at: $pgdata_src"
    find "${pgdata_src:?}" -mindepth 1 -delete
    chmod 755 "${pgdata_src:?}"
    mkdir -p "${pgdata_src:?}/18"
    chmod 777 "${pgdata_src:?}/18"
    echo "  → Pre-created 18/ with 0777 (world-traversable for UID 70/999)"
  fi

  # 5. Pull new image and start PG18
  echo "  → Starting PG18 container ..."
  docker compose -f "${stack_dir}/${compose_file}" pull "$pg_service"
  docker compose -f "${stack_dir}/${compose_file}" up -d "$pg_service"

  # 6. Wait for PG18 to be ready
  echo "  → Waiting for PG18 to accept connections ..."
  local attempts=0
  until docker exec "$container" pg_isready -q 2>/dev/null; do
    sleep 2
    attempts=$((attempts + 1))
    if [ $attempts -ge 30 ]; then
      echo "  ERROR: PG18 did not become ready after 60s"
      echo "  Backup is at: $backup"
      exit 1
    fi
  done
  echo "  → PG18 is ready"

  # 7. Restore
  # Always connect to 'postgres' as the initial database — pg_dumpall output
  # begins with \connect commands that switch databases, and the custom
  # POSTGRES_USER database may not yet exist at connect time.
  echo "  → Restoring dump ..."
  docker exec -i "$container" psql -U "$restore_user" -d postgres < "$backup"
  echo "  → Restore complete"

  # 8. Optional extra SQL (e.g. ALTER EXTENSION vector UPDATE)
  if [ -n "$extra_sql" ]; then
    echo "  → Running post-restore SQL: $extra_sql"
    docker exec "$container" psql -U "$restore_user" -d postgres -c "$extra_sql"
  fi

  # 9. Start remaining services
  echo "  → Starting remaining services ..."
  docker compose -f "${stack_dir}/${compose_file}" up -d

  echo "  ✓ $container migrated successfully"
}

# ─── instance definitions ─────────────────────────────────────────────────────

do_openwebui() {
  migrate_pg \
    "ai-postgress" \
    "$STACKS/openwebui" \
    "compose.yaml" \
    "ai-postgress" \
    "ALTER EXTENSION vector UPDATE;"
}

do_jellystat() {
  # jellystat.yaml is included by media/compose.yaml which defines t3_proxy network
  migrate_pg \
    "jellystat-db" \
    "$STACKS/media" \
    "compose.yaml" \
    "jellystat-db"
}

do_n8n() {
  # n8n-postgres.yaml is included by automation/compose.yaml
  migrate_pg \
    "n8n-db" \
    "$STACKS/automation" \
    "compose.yaml" \
    "n8n-db"
}

do_pwpush() {
  # pwpush.yaml is included by automation/compose.yaml
  migrate_pg \
    "pwpush-db" \
    "$STACKS/automation" \
    "compose.yaml" \
    "pwpush-db"
}

do_mattermost() {
  # mattermost-db.yaml is included by mattermost/compose.yaml which defines network
  migrate_pg \
    "mattermost-db" \
    "$STACKS/mattermost" \
    "compose.yaml" \
    "mattermost-db"
}

do_booklore() {
  migrate_pg \
    "booklore_postgres" \
    "$STACKS/books" \
    "compose.yaml" \
    "booklore_postgres"
}

do_paperless() {
  migrate_pg \
    "paperless_postgres" \
    "$STACKS/documents" \
    "compose.yaml" \
    "paperless_postgres"
}

do_keeper() {
  migrate_pg \
    "cal-postgres" \
    "$STACKS/keeper-sh" \
    "compose.yaml" \
    "postgres"
}

do_open_archiver() {
  migrate_pg \
    "open-archiver_postgres" \
    "$STACKS/open-archiver" \
    "compose.yaml" \
    "postgres"
}

do_postiz() {
  # postiz.yaml is included by postiz/compose.yaml which defines volumes
  migrate_pg \
    "postiz_postgres" \
    "$STACKS/postiz" \
    "compose.yaml" \
    "postiz_postgres"
}

do_calcom() {
  migrate_pg \
    "calcom_postgres" \
    "$STACKS/saas" \
    "compose.yaml" \
    "calcom_postgres"
}

do_social_postiz() {
  # social/compose.yaml is self-contained (defines networks+volumes inline)
  migrate_pg \
    "postiz_postgres" \
    "$STACKS/social" \
    "compose.yaml" \
    "postiz_postgres"
}

do_rybbit() {
  migrate_pg \
    "rybbit_postgres" \
    "$STACKS/social" \
    "compose.yaml" \
    "rybbit_postgres"
}

do_teleport() {
  migrate_pg \
    "teleport_postgres" \
    "$STACKS/teleport" \
    "compose.yaml" \
    "teleport_postgres"
}

# ─── dispatch ─────────────────────────────────────────────────────────────────

run_all() {
  echo "Running all PG migrations in order (PG15 → PG16 → PG17 → PG18)"
  echo "Backups will be saved to: $BACKUP_DIR"
  echo ""
  # PG15 first (most behind)
  do_openwebui
  do_jellystat
  # PG16
  do_n8n
  do_pwpush
  do_mattermost
  # PG17
  do_booklore
  do_paperless
  do_keeper
  do_open_archiver
  do_postiz
  do_calcom
  do_social_postiz
  do_rybbit
  do_teleport
  echo ""
  echo "All migrations complete. Backups retained at $BACKUP_DIR"
}

case "${1:-all}" in
  all)           run_all ;;
  openwebui)     do_openwebui ;;
  jellystat)     do_jellystat ;;
  n8n)           do_n8n ;;
  pwpush)        do_pwpush ;;
  mattermost)    do_mattermost ;;
  booklore)      do_booklore ;;
  paperless)     do_paperless ;;
  keeper)        do_keeper ;;
  open-archiver) do_open_archiver ;;
  postiz)        do_postiz ;;
  calcom)        do_calcom ;;
  social-postiz) do_social_postiz ;;
  rybbit)        do_rybbit ;;
  teleport)      do_teleport ;;
  *)
    echo "Unknown instance: $1"
    echo "Valid: all openwebui jellystat n8n pwpush mattermost booklore paperless"
    echo "       keeper open-archiver postiz calcom social-postiz rybbit teleport"
    exit 1
    ;;
esac
