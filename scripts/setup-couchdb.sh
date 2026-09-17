#!/bin/bash
# Setup script for the CouchDB stack (neocortex Obsidian LiveSync backend, neocortex v2 TODO-214)
#
# Runs ON LXC 100 as root. Every subcommand is idempotent, so a rebuilt LXC is brought back by
# re-running it: the repo (this script, compose.yaml, neocortex.ini) is the source of truth and
# the only host state is the data on the Terraform-mounted fast/appdata/automation dataset and the
# gitignored .env.
#
#   scripts/setup-couchdb.sh prepare              mount check, directories as 5984, runtime ini
#   scripts/setup-couchdb.sh env      < stdin     write stacks/selfhosted/couchdb/.env (0600)
#   docker compose -f stacks/selfhosted/couchdb/compose.yaml up -d
#   scripts/setup-couchdb.sh provision < stdin    system dbs, db `neocortex`, user `damian`, _security
#   scripts/setup-couchdb.sh verify               the non-secret checks, from the host
#
# Secrets arrive on stdin only (never argv, never echoed):
#   env       stdin = the .env body (COUCHDB_USER, COUCHDB_PASSWORD, PUID, PGID, TZ, DOMAINNAME)
#   provision stdin = one line, the `damian` member password (Bitwarden neocortex/shared/livesync-damian)
# The admin credentials are read from the .env on this host.

set -euo pipefail

STACKS=/mnt/fast/stacks
STACK_DIR="$STACKS/stacks/selfhosted/couchdb"
ENV_FILE="$STACK_DIR/.env"
PARENT=/mnt/fast/appdata/automation
BASE="$PARENT/couchdb"
LOCALD="$BASE/etc/local.d"
DB=neocortex
MEMBER=damian

die() { echo "✗ $*" >&2; exit 1; }
ok()  { echo "✓ $*"; }

require_dataset() {
  # /mnt/fast/appdata is NOT a mountpoint inside the unprivileged LXC; only named child datasets are
  # bind-mounted (infra/lxc-selfhost.tf). Creating anything before this check could land on ext4 /.
  mountpoint -q "$PARENT" || die "$PARENT is not a mountpoint — the automation dataset is not mounted; nothing created"
  [ "$(findmnt -n -o SOURCE -T "$PARENT")" = "fast/appdata/automation" ] \
    || die "$PARENT is mounted from '$(findmnt -n -o SOURCE -T "$PARENT")', expected fast/appdata/automation"
}

admin_auth() {
  [ -f "$ENV_FILE" ] || die "no $ENV_FILE — run: scripts/setup-couchdb.sh env < <env body>"
  local u p
  u=$(sed -n 's/^COUCHDB_USER=//p' "$ENV_FILE")
  p=$(sed -n 's/^COUCHDB_PASSWORD=//p' "$ENV_FILE")
  [ -n "$u" ] && [ -n "$p" ] || die "COUCHDB_USER/COUCHDB_PASSWORD empty in $ENV_FILE"
  printf '%s:%s' "$u" "$p"
}

couch_url() {
  # Straight to the container on t3_proxy: no Cloudflare hairpin, no dependency on public DNS.
  local ip
  ip=$(docker inspect -f '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}' couchdb 2>/dev/null) \
    || die "container couchdb is not running — docker compose -f $STACK_DIR/compose.yaml up -d"
  [ -n "$ip" ] || die "couchdb has no t3_proxy address"
  printf 'http://%s:5984' "$ip"
}

# curl with the admin credentials in a config read from a process substitution (/dev/fd, never
# argv, never ps-visible). Not `-K -`: several requests send their JSON body on stdin.
acurl() {
  local auth=$1; shift
  auth=${auth//\\/\\\\}; auth=${auth//\"/\\\"}
  curl -sS -K <(printf 'user = "%s"\n' "$auth") "$@"
}

cmd_prepare() {
  require_dataset
  ok "dataset: $PARENT is fast/appdata/automation"
  install -d -m 0750 -o 5984 -g 5984 "$BASE" "$BASE/data" "$BASE/etc" "$LOCALD"
  [ "$(findmnt -n -o TARGET -T "$BASE/data")" = "$PARENT" ] || die "$BASE/data does not resolve through $PARENT"
  ok "directories under $BASE owned 5984:5984"
  # neocortex.ini is bind-mounted read-only from the repo by compose.yaml; the placeholder only
  # gives Docker a file to mount over. zz-runtime.ini sorts last in local.d, so CouchDB writes every
  # runtime/_config change (admin hash, uuid, cookie secret) there instead of into the repo file.
  for f in neocortex.ini zz-runtime.ini; do
    [ -e "$LOCALD/$f" ] || install -m 0640 -o 5984 -g 5984 /dev/null "$LOCALD/$f"
  done
  ok "local.d: neocortex.ini mountpoint + zz-runtime.ini present"
}

cmd_env() {
  [ -d "$STACK_DIR" ] || die "no $STACK_DIR — git -C $STACKS pull --ff-only origin main first"
  local tmp; tmp=$(mktemp "$STACK_DIR/.env.XXXXXX")
  chmod 0600 "$tmp"
  cat > "$tmp"
  for k in COUCHDB_USER COUCHDB_PASSWORD PUID PGID TZ DOMAINNAME; do
    grep -q "^$k=." "$tmp" || { rm -f "$tmp"; die ".env body is missing a non-empty $k — nothing written"; }
  done
  mv "$tmp" "$ENV_FILE"
  ok ".env written (0600); keys: $(cut -d= -f1 "$ENV_FILE" | tr '\n' ' ')"
}

cmd_provision() {
  local auth url pw code
  auth=$(admin_auth); url=$(couch_url)
  IFS= read -r pw || true
  [ -n "$pw" ] || die "no member password on stdin"
  for sysdb in _users _replicator; do
    code=$(acurl "$auth" -o /dev/null -w '%{http_code}' -X PUT "$url/$sysdb")
    case $code in 201|202|412) ok "system db $sysdb ($code)";; *) die "PUT $sysdb → $code";; esac
  done
  code=$(acurl "$auth" -o /dev/null -w '%{http_code}' -X PUT "$url/$DB")
  case $code in 201|202|412) ok "database $DB ($code)";; *) die "PUT $DB → $code";; esac
  # User doc: create, or update the password in place (keeps _rev), so a rotation is a re-run.
  local rev body
  rev=$(acurl "$auth" "$url/_users/org.couchdb.user:$MEMBER" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("_rev",""))')
  body=$(PW="$pw" REV="$rev" python3 -c 'import json,os
d={"name":"'"$MEMBER"'","password":os.environ["PW"],"roles":[],"type":"user"}
if os.environ["REV"]: d["_rev"]=os.environ["REV"]
print(json.dumps(d))')
  code=$(printf '%s' "$body" | acurl "$auth" -o /dev/null -w '%{http_code}' -X PUT \
         -H 'Content-Type: application/json' --data-binary @- "$url/_users/org.couchdb.user:$MEMBER")
  unset pw body
  case $code in 201|202) ok "user $MEMBER (${rev:+updated}${rev:-created}, $code)";; *) die "PUT user → $code";; esac
  code=$(printf '{"admins":{"names":[],"roles":[]},"members":{"names":["%s"],"roles":[]}}' "$MEMBER" \
         | acurl "$auth" -o /dev/null -w '%{http_code}' -X PUT -H 'Content-Type: application/json' \
           --data-binary @- "$url/$DB/_security")
  case $code in 200|201) ok "$DB/_security: members = [$MEMBER]";; *) die "PUT _security → $code";; esac
}

cmd_verify() {
  local auth url
  auth=$(admin_auth); url=$(couch_url)
  echo "anonymous /           → $(curl -s -o /dev/null -w '%{http_code}' "$url/") (expect 401)"
  echo "admin /_up            → $(acurl "$auth" "$url/_up")"
  echo "admin /$DB           → $(acurl "$auth" "$url/$DB" | python3 -c 'import sys,json; d=json.load(sys.stdin); print({k:d.get(k) for k in ("db_name","doc_count")})')"
  echo "security members      → $(acurl "$auth" "$url/$DB/_security" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("members"))')"
  echo "binds                 → $(docker inspect couchdb --format '{{range .Mounts}}{{.Source}}:{{.Destination}}:{{.RW}} {{end}}')"
  echo "data dataset          → $(findmnt -n -o TARGET,SOURCE -T "$BASE/data")"
  echo "health                → $(docker inspect couchdb --format '{{.State.Health.Status}}')"
}

case "${1:-}" in
  prepare)   cmd_prepare ;;
  env)       cmd_env ;;
  provision) cmd_provision ;;
  verify)    cmd_verify ;;
  *) echo "usage: $0 prepare|env|provision|verify" >&2; exit 2 ;;
esac
