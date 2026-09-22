#!/bin/bash
# Setup script for the neocortex-memory stack (neocortex v2 Phase 3, TODO-315)
#
# Runs ON LXC 100 as root. Every subcommand is idempotent, so a rebuilt LXC is brought back by
# re-running it: the repo (this script, compose.yaml, bin/) is the source of truth and the only
# host state is the data on the Terraform-mounted fast/appdata/automation dataset, the pinned
# platform checkout, and the gitignored .env.
#
#   scripts/setup-neocortex-memory.sh prepare      mount check, directories as 568:568
#   scripts/setup-neocortex-memory.sh provision    roles, database, extension, the ONE grant
#   docker compose run --rm deps   production node_modules (needs outbound npm)
#   scripts/setup-neocortex-memory.sh migrate      the engine's own migrations, in the container
#   ... mint the first token (README step 6), put it in .env, then: docker compose up -d
#   scripts/setup-neocortex-memory.sh verify       the non-secret checks, from the host
#
# THE ONE RULE THIS SCRIPT EXISTS TO ENFORCE:
#   Database `agentic_os` is Damian's live v1 store. Nothing here writes data, schema or
#   migrations to it. `provision` makes exactly ONE change to it - GRANT SELECT to a new
#   read-only role on two tables - and records the privilege listing before and after so the diff
#   can be shown to be exactly that. Everything else happens in `neocortex_memory`, a new
#   database this script creates.
#
# Secrets never appear in argv and are never echoed. The superuser credentials are read from the
# agentic-os stack's own .env on this host; the two new role passwords are GENERATED here and
# written only to this stack's .env (mode 0600).

set -euo pipefail

STACKS=/mnt/fast/stacks
STACK_DIR="$STACKS/stacks/selfhosted/neocortex-memory"
ENV_FILE="$STACK_DIR/.env"
AGENTIC_ENV="$STACKS/stacks/selfhosted/agentic-os/.env"
PARENT=/mnt/fast/appdata/automation
BASE="$PARENT/neocortex-memory"
CHECKOUT=/mnt/fast/stacks-private/neocortex-platform
DB_CONTAINER=agentic-os-db

NEW_DB=neocortex_memory
LEGACY_DB=agentic_os
API_ROLE=memory_api
RO_ROLE=memory_legacy_ro
# Exactly the tables TODO-311's bridge query reads. `search_events` is deliberately NOT here: the
# bridge never logs, which is half the reason it can be read-only at all. Keep this list in step
# with LEGACY_REQUIRED_COLUMNS in memory/lib/memory/legacy-bridge.js.
RO_TABLES=(memory_chunks memory_sources)

die() { echo "✗ $*" >&2; exit 1; }
ok()  { echo "✓ $*"; }
note() { echo "  $*"; }

require_dataset() {
  # /mnt/fast/appdata is NOT a mountpoint inside the unprivileged LXC; only named child datasets
  # are bind-mounted (infra/lxc-selfhost.tf). Creating anything before this check could land on
  # ext4 / - which was at 80% when this stack was written.
  mountpoint -q "$PARENT" || die "$PARENT is not a mountpoint — the automation dataset is not mounted; nothing created"
  [ "$(findmnt -n -o SOURCE -T "$PARENT")" = "fast/appdata/automation" ] \
    || die "$PARENT is mounted from '$(findmnt -n -o SOURCE -T "$PARENT")', expected fast/appdata/automation"
}

require_db() {
  docker inspect -f '{{.State.Running}}' "$DB_CONTAINER" 2>/dev/null | grep -q true \
    || die "container $DB_CONTAINER is not running"
}

# psql as the agentic-os superuser. Credentials come from that stack's .env via the environment,
# never argv: PGPASSWORD is exported into the docker exec, not printed.
supersql() {
  [ -f "$AGENTIC_ENV" ] || die "no $AGENTIC_ENV — cannot reach the superuser"
  local u p
  u=$(sed -n 's/^POSTGRES_USER=//p' "$AGENTIC_ENV")
  p=$(sed -n 's/^POSTGRES_PASSWORD=//p' "$AGENTIC_ENV")
  [ -n "$u" ] && [ -n "$p" ] || die "POSTGRES_USER/POSTGRES_PASSWORD empty in $AGENTIC_ENV"
  docker exec -i -e PGPASSWORD="$p" "$DB_CONTAINER" psql -v ON_ERROR_STOP=1 -U "$u" "$@"
}

genpw() { head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 32; }

# Read a value out of this stack's .env without printing it.
env_value() { [ -f "$ENV_FILE" ] && sed -n "s/^$1=//p" "$ENV_FILE" || true; }

cmd_prepare() {
  require_dataset
  ok "dataset: $PARENT is fast/appdata/automation"
  install -d -m 0750 -o 568 -g 568 \
    "$BASE" "$BASE/root" "$BASE/models" "$BASE/deps" "$BASE/deps/node_modules"
  [ "$(findmnt -n -o TARGET -T "$BASE/root")" = "$PARENT" ] \
    || die "$BASE/root does not resolve through $PARENT — refusing to continue"
  ok "directories under $BASE owned 568:568, on the dataset"

  [ -d "$CHECKOUT/.git" ] \
    || die "no platform checkout at $CHECKOUT — clone it at the pinned SHA first (README step 2)"

  # The mountpoint for the production node_modules must ALREADY EXIST inside the checkout.
  # compose bind-mounts /app read-only, and Docker cannot create a mountpoint inside a read-only
  # bind -- it fails with "create mountpoint ...: read-only file system" and the container never
  # starts. memory/node_modules is gitignored (**/node_modules/), so an empty directory here is
  # invisible to git and does not dirty the pinned checkout.
  install -d -o 568 -g 568 -m 0755 "$CHECKOUT/memory/node_modules"
  ok "mountpoint $CHECKOUT/memory/node_modules exists (gitignored, empty until mounted over)"
  note "checkout at $(git -C "$CHECKOUT" rev-parse --short HEAD) ($(git -C "$CHECKOUT" rev-parse --abbrev-ref HEAD))"
  git -C "$CHECKOUT" symbolic-ref -q HEAD >/dev/null \
    && echo "  ⚠ the checkout is on a BRANCH, not a detached pinned commit — README step 2" >&2
  ok "prepare complete"
}

# The privilege listing for agentic_os, in a stable form, so before/after can be diffed.
snapshot_legacy_privs() {
  local out=$1
  {
    echo "--- \\l+ (databases)"
    supersql -d postgres -Atc "SELECT datname, pg_get_userbyid(datdba), array_to_string(datacl,',') FROM pg_database ORDER BY datname;"
    echo "--- \\dn+ (schemas in $LEGACY_DB)"
    supersql -d "$LEGACY_DB" -Atc "SELECT nspname, pg_get_userbyid(nspowner), array_to_string(nspacl,',') FROM pg_namespace ORDER BY nspname;"
    echo "--- \\dp (table privileges in $LEGACY_DB)"
    supersql -d "$LEGACY_DB" -Atc "SELECT schemaname||'.'||tablename, array_to_string(relacl,',') FROM pg_tables t JOIN pg_class c ON c.relname=t.tablename ORDER BY 1;"
    echo "--- roles"
    supersql -d postgres -Atc "SELECT rolname FROM pg_roles ORDER BY rolname;"
  } > "$out" 2>&1
}

cmd_provision() {
  require_db
  local before=/tmp/neocortex-memory-privs-before.txt
  local after=/tmp/neocortex-memory-privs-after.txt

  snapshot_legacy_privs "$before"
  ok "recorded the BEFORE privilege listing -> $before"

  # Row counts for every table in agentic_os, so the acceptance check has its baseline.
  supersql -d "$LEGACY_DB" -Atc \
    "SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname;" \
    > /tmp/neocortex-memory-legacy-rowcounts-before.txt
  ok "recorded BEFORE row counts -> /tmp/neocortex-memory-legacy-rowcounts-before.txt"

  # --- the roles. Passwords generated here, written only to .env -----------------------------
  local api_pw ro_pw
  api_pw=$(env_value MEMORY_DATABASE_URL | sed -n "s|^postgres://$API_ROLE:\([^@]*\)@.*|\1|p")
  ro_pw=$(env_value MEMORY_LEGACY_DATABASE_URL | sed -n "s|^postgres://$RO_ROLE:\([^@]*\)@.*|\1|p")
  [ -n "$api_pw" ] || { api_pw=$(genpw); note "generated a new $API_ROLE password"; }
  [ -n "$ro_pw" ]  || { ro_pw=$(genpw);  note "generated a new $RO_ROLE password"; }

  # CREATE ROLE is not idempotent; DO blocks make it so. Passwords are set every run, which is
  # what makes re-running after an .env edit converge instead of drifting.
  supersql -d postgres <<SQL
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$API_ROLE') THEN
    CREATE ROLE $API_ROLE LOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$RO_ROLE') THEN
    CREATE ROLE $RO_ROLE LOGIN;
  END IF;
END \$\$;
ALTER ROLE $API_ROLE LOGIN PASSWORD '$api_pw';
ALTER ROLE $RO_ROLE  LOGIN PASSWORD '$ro_pw';
SQL
  ok "roles $API_ROLE and $RO_ROLE exist with current passwords"

  # --- the new database, owned by memory_api -------------------------------------------------
  # CREATE DATABASE cannot run inside a transaction or a DO block, so test-then-create.
  if ! supersql -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname='$NEW_DB';" | grep -q 1; then
    supersql -d postgres -c "CREATE DATABASE $NEW_DB OWNER $API_ROLE;"
    ok "created database $NEW_DB owned by $API_ROLE"
  else
    ok "database $NEW_DB already exists"
  fi
  supersql -d "$NEW_DB" -c "CREATE EXTENSION IF NOT EXISTS vector;"
  ok "extension vector present in $NEW_DB"

  # $RO_ROLE must be able to read NOTHING in the new database.
  supersql -d "$NEW_DB" -c "REVOKE ALL ON DATABASE $NEW_DB FROM $RO_ROLE;" >/dev/null 2>&1 || true
  ok "$RO_ROLE holds nothing on $NEW_DB"

  # --- THE ONE PERMITTED CHANGE TO agentic_os ------------------------------------------------
  # GRANT SELECT on exactly two tables, to exactly one new role.
  #
  # Deliberately NOT done: REVOKE CONNECT ON DATABASE agentic_os FROM PUBLIC. Postgres grants
  # CONNECT to PUBLIC by default; revoking it would mean re-granting every existing role on the
  # live store the M1 and the old workflows use. The boundary here is PRIVILEGE, not connection -
  # memory_api may connect to agentic_os and can read nothing in it, which is the property the
  # acceptance criteria actually assert.
  local t
  supersql -d "$LEGACY_DB" -c "GRANT USAGE ON SCHEMA public TO $RO_ROLE;"
  for t in "${RO_TABLES[@]}"; do
    supersql -d "$LEGACY_DB" -c "GRANT SELECT ON TABLE public.$t TO $RO_ROLE;"
    note "GRANT SELECT public.$t -> $RO_ROLE"
  done
  ok "the one permitted change to $LEGACY_DB is applied (${#RO_TABLES[@]} tables)"

  snapshot_legacy_privs "$after"
  ok "recorded the AFTER privilege listing -> $after"
  echo
  echo "=== privilege diff (must be ONLY $RO_ROLE's grants and the two new roles) ==="
  diff "$before" "$after" || true
  echo "=== end diff ==="

  # --- write .env (0600), preserving anything already there ----------------------------------
  if [ ! -f "$ENV_FILE" ]; then
    install -m 0600 /dev/null "$ENV_FILE"
    {
      echo "# Generated by setup-neocortex-memory.sh provision on $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "# THIS FILE HOLDS REAL CREDENTIALS AND IS GITIGNORED. Never commit it."
      echo "DOMAINNAME=deercrest.info"
      echo "PUID=568"
      echo "PGID=568"
      echo "TZ=Europe/Dublin"
      echo "MEMORY_DATABASE_URL=postgres://$API_ROLE:$api_pw@$DB_CONTAINER:5432/$NEW_DB"
      echo "MEMORY_LEGACY_DATABASE_URL=postgres://$RO_ROLE:$ro_pw@$DB_CONTAINER:5432/$LEGACY_DB"
      echo "MEMORY_LEGACY_BRIDGE_USER_ID="
      echo "MEMORY_API_TOKENS="
    } > "$ENV_FILE"
    chmod 0600 "$ENV_FILE"
    ok "wrote $ENV_FILE (0600) — MEMORY_API_TOKENS and MEMORY_LEGACY_BRIDGE_USER_ID still empty"
    note "the server will REFUSE TO START until MEMORY_API_TOKENS is filled — README step 6"
  else
    ok "$ENV_FILE already exists — left untouched (delete it to regenerate)"
  fi
  ok "provision complete"
}

cmd_migrate() {
  require_db
  [ -d "$BASE/deps/node_modules" ] && [ -n "$(ls -A "$BASE/deps/node_modules" 2>/dev/null)" ] \
    || die "no node_modules — run: docker compose run --rm deps"
  ( cd "$STACK_DIR" && docker compose run --rm admin memory-migrate )
  ok "migrations applied to $NEW_DB (inside the container, never from a laptop)"
}

cmd_verify() {
  require_db
  local fails=0
  check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else echo "✗ $1" >&2; fails=$((fails+1)); fi; }

  check "database $NEW_DB exists" \
    "supersql -d postgres -Atc \"SELECT 1 FROM pg_database WHERE datname='$NEW_DB'\" | grep -q 1"
  check "extension vector in $NEW_DB" \
    "supersql -d $NEW_DB -Atc \"SELECT 1 FROM pg_extension WHERE extname='vector'\" | grep -q 1"

  # The read-only role really is read-only, asserted positively AND negatively.
  local ro_dsn; ro_dsn=$(env_value MEMORY_LEGACY_DATABASE_URL)
  if [ -n "$ro_dsn" ]; then
    check "$RO_ROLE can SELECT memory_sources in $LEGACY_DB" \
      "docker exec -i $DB_CONTAINER psql -v ON_ERROR_STOP=1 '$ro_dsn' -Atc 'SELECT count(*) FROM memory_sources'"
    check "$RO_ROLE CANNOT create a table in $LEGACY_DB" \
      "! docker exec -i $DB_CONTAINER psql -v ON_ERROR_STOP=1 '$ro_dsn' -Atc 'CREATE TABLE _x(i int)'"
    check "$RO_ROLE CANNOT read users in $LEGACY_DB (not on the grant list)" \
      "! docker exec -i $DB_CONTAINER psql -v ON_ERROR_STOP=1 '$ro_dsn' -Atc 'SELECT 1 FROM users LIMIT 1'"
  else
    note "MEMORY_LEGACY_DATABASE_URL empty — bridge checks skipped (the bridge is off)"
  fi

  # The API role must be powerless on the legacy store. It MAY connect; that is deliberate.
  local api_dsn_legacy; api_dsn_legacy=$(env_value MEMORY_DATABASE_URL | sed "s|/$NEW_DB\$|/$LEGACY_DB|")
  if [ -n "$api_dsn_legacy" ]; then
    check "$API_ROLE CANNOT read memory_sources in $LEGACY_DB" \
      "! docker exec -i $DB_CONTAINER psql -v ON_ERROR_STOP=1 '$api_dsn_legacy' -Atc 'SELECT 1 FROM memory_sources LIMIT 1'"
  fi

  # The service itself, if it is up. No auth needed for /v1/health.
  if docker inspect -f '{{.State.Running}}' neocortex-memory-api 2>/dev/null | grep -q true; then
    check "GET /v1/health answers 200" \
      "docker exec neocortex-memory-api node -e \"require('http').get('http://127.0.0.1:8787/v1/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))\""
    check "no vault env leaked into the container" \
      "[ \"\$(docker exec neocortex-memory-api env | grep -c -E '^(NEOCORTEX_VAULT|AGENTIC_OS_DIR)=')\" = 0 ]"
    check "the checkout is mounted read-only" \
      "docker inspect neocortex-memory-api --format '{{json .HostConfig.Binds}}' | grep -q 'neocortex-platform:/app:ro'"
  else
    note "neocortex-memory-api is not running — service checks skipped"
  fi

  echo
  [ "$fails" -eq 0 ] && ok "verify: all checks passed" || die "verify: $fails check(s) failed"
}

case "${1:-}" in
  prepare)   cmd_prepare ;;
  provision) cmd_provision ;;
  migrate)   cmd_migrate ;;
  verify)    cmd_verify ;;
  *) die "usage: $0 {prepare|provision|migrate|verify}" ;;
esac
