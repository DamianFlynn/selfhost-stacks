#!/usr/bin/env bash
# neocortex-backup-lxc.sh — the LXC 100 half of the neocortex backup (neocortex v2 TODO-217).
#
# This host NEVER talks to a cloud, never runs restic, never initiates an outbound
# connection. It only prepares a run directory and streams it to the mini, which is the
# single restic client. Everything here is driven through a FORCED COMMAND: the mini's
# key in root's authorized_keys pins this script, so `ssh lxc100 <anything>` can only
# reach the four operations below.
#
#   health              readiness JSON; NO side effects (safe as a preflight)
#   prepare  <run-id>   build the run directory (pg dump + couchdb tar + manifest)
#   fetch    <run-id>   stream a deterministic tar of that run to stdout
#   cleanup  <run-id>   remove ONLY that validated run directory
#
# Run id shape: 20260918T143000Z-a1b2c3d4 — anything else is rejected before any work.
#
# WHY the dump is uncompressed (--compress=0): restic deduplicates and compresses its own
# chunks. A gzip-compressed dump changes wholesale every night, so restic would store a
# fresh ~400 MB blob each run; uncompressed, the unchanged pages dedupe away.
set -euo pipefail
umask 077

readonly BASE=/mnt/fast/appdata/automation/backups/neocortex
readonly STAGING=$BASE/staging
readonly PG_CONTAINER=agentic-os-db
readonly PG_DB=agentic_os
readonly COUCH_CONTAINER=couchdb
readonly COUCH_DB=neocortex
readonly COUCH_ENV=/mnt/fast/stacks/stacks/selfhosted/couchdb/.env
readonly COUCH_DATA=/mnt/fast/appdata/automation/couchdb
readonly RUN_ID_RE='^[0-9]{8}T[0-9]{6}Z-[a-f0-9]{8}$'

die() { printf 'neocortex-backup-lxc: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- argument gate ----
# Under a forced command the operator's words arrive in SSH_ORIGINAL_COMMAND; on a local
# run they are "$@". Either way they are parsed the same way and never eval'd.
parse_request() {
  local raw=("$@")
  if [[ ${#raw[@]} -eq 0 && -n ${SSH_ORIGINAL_COMMAND:-} ]]; then
    # Deliberately word-split on whitespace only. No glob, no eval, no quotes honoured:
    # a request is at most two bare words.
    set -f
    # shellcheck disable=SC2206
    raw=(${SSH_ORIGINAL_COMMAND})
    set +f
  fi
  [[ ${#raw[@]} -ge 1 ]] || die "no operation (expected: health | prepare <run-id> | fetch <run-id> | cleanup <run-id>)"
  [[ ${#raw[@]} -le 2 ]] || die "too many arguments"
  OP=${raw[0]}
  RUN_ID=${raw[1]:-}
  case $OP in
    health)                  [[ -z $RUN_ID ]] || die "health takes no argument" ;;
    prepare|fetch|cleanup)   [[ -n $RUN_ID ]] || die "$OP needs a run id"
                             [[ $RUN_ID =~ $RUN_ID_RE ]] || die "malformed run id" ;;
    *)                       die "unknown operation" ;;
  esac
  readonly OP RUN_ID
}

run_dir() { printf '%s/%s' "$STAGING" "$RUN_ID"; }

couch_admin_curl() {
  # Credentials reach curl through a config on /dev/fd — never argv, never the log.
  # Deviation from the plan, recorded in the todo: the admin password is READ from the
  # CouchDB stack's own .env rather than copied into a second secrets file, so there is
  # one place to rotate instead of two.
  local path=$1
  # shellcheck disable=SC1090
  ( set -a; . "$COUCH_ENV"; set +a
    printf 'user = "%s:%s"\nurl = "http://%s:5984%s"\n' \
      "$COUCHDB_USER" "$COUCHDB_PASSWORD" "$COUCH_CONTAINER" "$path" \
      | docker run -i --rm --network t3_proxy curlimages/curl:latest -s -K - )
}

couch_stat() { couch_admin_curl "/$COUCH_DB" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["doc_count"], d["update_seq"].split("-")[0])'; }

# ------------------------------------------------------------------------ health ----
op_health() {
  local mount_ok=no pg_ok=no couch_ok=no space_kb
  findmnt -T "$COUCH_DATA" -o SOURCE -n 2>/dev/null | grep -q 'fast/appdata/automation' && mount_ok=yes
  docker inspect -f '{{.State.Running}}' "$PG_CONTAINER" 2>/dev/null | grep -q true && pg_ok=yes
  docker inspect -f '{{.State.Running}}' "$COUCH_CONTAINER" 2>/dev/null | grep -q true && couch_ok=yes
  space_kb=$(df -Pk "$BASE" | awk 'NR==2 {print $4}')
  python3 - "$mount_ok" "$pg_ok" "$couch_ok" "$space_kb" "$(ls -1 "$STAGING" 2>/dev/null | wc -l)" <<'PY'
import json, sys
mount, pg, couch, space, staged = sys.argv[1:6]
print(json.dumps({
    "ok": mount == "yes" and pg == "yes" and couch == "yes",
    "automation_dataset_mounted": mount == "yes",
    "postgres_running": pg == "yes",
    "couchdb_running": couch == "yes",
    "staging_free_kb": int(space),
    "staged_runs": int(staged),
}))
PY
}

# ----------------------------------------------------------------------- prepare ----
op_prepare() {
  local dir; dir=$(run_dir)
  [[ -e $dir ]] && die "run directory already exists"
  install -d -m 0700 "$STAGING" "$dir"
  # A partial run must not linger: `cleanup` deliberately refuses a directory with no
  # manifest, so prepare removes its own mess. Cleared once the manifest is written.
  trap 'rm -rf -- "$dir"' ERR

  # --- Postgres: dump inside the container, verify with the SAME image's pg_restore so
  #     the reader can never be an older major than the writer.
  docker exec "$PG_CONTAINER" sh -lc \
    "pg_dump -Fc --compress=0 -U \"\$POSTGRES_USER\" -d $PG_DB" > "$dir/agentic_os.dump"
  [[ -s $dir/agentic_os.dump ]] || die "pg_dump produced an empty file"
  # pg_restore cannot read a custom-format dump from stdin ("could not open input file
  # \"-\"") — it seeks. Mount the run directory read-only and name the file instead.
  docker run --rm -v "$dir:/w:ro" pgvector/pgvector:pg18 pg_restore --list /w/agentic_os.dump > "$dir/agentic_os.toc" \
    || die "pg_restore --list refused the dump"
  grep -q ';' "$dir/agentic_os.toc" || die "pg_restore --list produced no table of contents"

  # --- CouchDB: quiesce, tar the whole tree with ownership/mode/symlink/mtime, restart
  #     from an EXIT trap so a failure anywhere below still brings the service back.
  local before after
  before=$(couch_stat) || die "couchdb unreadable before backup"
  trap 'docker start '"$COUCH_CONTAINER"' >/dev/null 2>&1 || true' EXIT
  docker stop "$COUCH_CONTAINER" >/dev/null || die "could not stop couchdb"
  tar --numeric-owner --format=pax -C "$(dirname "$COUCH_DATA")" -cf "$dir/couchdb.tar" "$(basename "$COUCH_DATA")"
  docker start "$COUCH_CONTAINER" >/dev/null || die "could not restart couchdb"
  trap - EXIT
  local waited=0
  until couch_admin_curl /_up | grep -q '"status":"ok"'; do
    waited=$((waited + 2)); [[ $waited -le 60 ]] || die "couchdb did not come back within 60s"; sleep 2
  done
  after=$(couch_stat) || die "couchdb unreadable after backup"
  [[ $before == "$after" ]] || die "couchdb doc_count/update_seq changed across the backup ($before -> $after)"

  # --- manifest LAST, so its presence means every artifact above succeeded.
  ( cd "$dir" && sha256sum agentic_os.dump couchdb.tar > sha256sums.txt )
  python3 - "$dir" "$RUN_ID" "$before" <<'PY' > "$dir/lxc-manifest.json"
import hashlib, json, os, sys, subprocess, datetime
d, run_id, couch = sys.argv[1:4]
doc_count, update_seq = couch.split()
def h(p):
    x = hashlib.sha256()
    with open(os.path.join(d, p), "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            x.update(b)
    return x.hexdigest()
print(json.dumps({
    "run_id": run_id,
    "created_utc": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat(),
    "host": subprocess.run(["hostname"], capture_output=True, text=True).stdout.strip(),
    "postgres": {"database": "agentic_os", "dump": "agentic_os.dump",
                 "bytes": os.path.getsize(os.path.join(d, "agentic_os.dump")), "sha256": h("agentic_os.dump"),
                 "format": "custom, --compress=0 (restic dedupes)"},
    "couchdb": {"database": "neocortex", "archive": "couchdb.tar",
                "bytes": os.path.getsize(os.path.join(d, "couchdb.tar")), "sha256": h("couchdb.tar"),
                "doc_count": int(doc_count), "update_seq": update_seq},
}, indent=2))
PY
  trap - ERR
  printf 'prepared %s\n' "$RUN_ID" >&2
  cat "$dir/lxc-manifest.json"
}

# ------------------------------------------------------------------------- fetch ----
op_fetch() {
  local dir; dir=$(run_dir)
  [[ -d $dir ]] || die "no such run"
  [[ -f $dir/lxc-manifest.json ]] || die "run has no manifest — prepare did not complete"
  # Deterministic: fixed member order, numeric owner, no directory entry.
  tar --numeric-owner --format=pax -C "$dir" -cf - \
      lxc-manifest.json sha256sums.txt agentic_os.toc agentic_os.dump couchdb.tar
}

# ----------------------------------------------------------------------- cleanup ----
op_cleanup() {
  local dir; dir=$(run_dir)
  [[ -d $dir ]] || die "no such run"
  [[ -f $dir/lxc-manifest.json ]] || die "refusing to remove a run with no manifest"
  # $dir is built from STAGING + a regex-validated run id, so it cannot escape STAGING.
  rm -rf -- "$dir"
  printf 'cleaned %s\n' "$RUN_ID"
}

parse_request "$@"
case $OP in
  health)  op_health ;;
  prepare) op_prepare ;;
  fetch)   op_fetch ;;
  cleanup) op_cleanup ;;
esac
