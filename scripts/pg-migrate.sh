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
  local old_ver
  old_ver=$(docker exec "$container" psql -U postgres -tAc "SHOW server_version;" 2>/dev/null || \
            docker exec "$container" sh -c 'psql -U "$(echo ${POSTGRES_USER:-postgres})" -tAc "SHOW server_version;"' 2>/dev/null || echo "unknown")
  echo "  Current version: $old_ver"

  # 1. Dump all databases
  echo "  → Dumping to $backup ..."
  docker exec "$container" pg_dumpall -U postgres > "$backup" 2>/dev/null || \
    docker exec "$container" sh -c \
      'pg_dumpall -U "$(echo ${POSTGRES_USER:-postgres})"' > "$backup"
  echo "  → Dump complete ($(du -sh "$backup" | cut -f1))"

  # 2. Stop all services in the stack that depend on this postgres
  echo "  → Stopping stack ..."
  docker compose -f "${stack_dir}/${compose_file}" stop

  # 3. Remove old container (volume is preserved)
  echo "  → Removing old container ..."
  docker rm "$container" 2>/dev/null || true

  # 4. Pull new image and start PG18
  echo "  → Starting PG18 container ..."
  docker compose -f "${stack_dir}/${compose_file}" pull "$pg_service"
  docker compose -f "${stack_dir}/${compose_file}" up -d "$pg_service"

  # 5. Wait for PG18 to be ready
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

  # 6. Restore
  echo "  → Restoring dump ..."
  docker exec -i "$container" psql -U postgres < "$backup" 2>/dev/null || \
    docker exec -i "$container" sh -c \
      'psql -U "$(echo ${POSTGRES_USER:-postgres})"' < "$backup"
  echo "  → Restore complete"

  # 7. Optional extra SQL (e.g. ALTER EXTENSION vector UPDATE)
  if [ -n "$extra_sql" ]; then
    echo "  → Running post-restore SQL: $extra_sql"
    docker exec "$container" psql -U postgres -c "$extra_sql" 2>/dev/null || \
      docker exec "$container" sh -c \
        "psql -U \"\$(echo \${POSTGRES_USER:-postgres})\" -c \"${extra_sql}\""
  fi

  # 8. Start remaining services
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
  migrate_pg \
    "jellystat-db" \
    "$STACKS/media" \
    "jellystat.yaml" \
    "jellystat-db"
}

do_n8n() {
  migrate_pg \
    "n8n-db" \
    "$STACKS/automation" \
    "n8n-postgres.yaml" \
    "n8n-db"
}

do_pwpush() {
  migrate_pg \
    "pwpush-db" \
    "$STACKS/automation" \
    "pwpush.yaml" \
    "pwpush-db"
}

do_mattermost() {
  migrate_pg \
    "mattermost-db" \
    "$STACKS/mattermost" \
    "mattermost-db.yaml" \
    "mattermost-db"
}

do_booklore() {
  migrate_pg \
    "booklore_postgres" \
    "$STACKS/books" \
    "booklore.yaml" \
    "booklore_postgres"
}

do_paperless() {
  migrate_pg \
    "paperless_postgres" \
    "$STACKS/documents" \
    "paperless.yaml" \
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
  migrate_pg \
    "postiz_postgres" \
    "$STACKS/postiz" \
    "postiz.yaml" \
    "postiz_postgres"
}

do_calcom() {
  migrate_pg \
    "calcom_postgres" \
    "$STACKS/saas" \
    "calcom.yaml" \
    "calcom_postgres"
}

do_social_postiz() {
  migrate_pg \
    "postiz_postgres" \
    "$STACKS/social" \
    "postiz.yaml" \
    "postiz_postgres"
}

do_rybbit() {
  migrate_pg \
    "rybbit_postgres" \
    "$STACKS/social" \
    "rybbit.yaml" \
    "rybbit_postgres"
}

do_teleport() {
  migrate_pg \
    "teleport_postgres" \
    "$STACKS/teleport" \
    "teleport.yaml" \
    "teleport_postgres"
}

# ─── dispatch ─────────────────────────────────────────────────────────────────

run_all() {
  echo "Running all PG migrations in order (PG15 → PG16 → PG17)"
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
