#!/bin/bash
# dump-onroot-pg.sh -- rescue the databases that no `zfs send` can reach.
#
# WHY: teslamate-db, paperless_postgres and n8n-db store their data on LXC 100's ext4
# ROOT (a docker named volume, or /automation), not on a ZFS dataset. They are therefore
# invisible to every send in backup-incremental.sh and would be lost entirely in an LXC
# rebuild. n8n's holds workflows AND credentials; teslamate's holds every drive logged.
#
# WHERE IT WRITES, and why here rather than a new dataset: a new child of fast/appdata
# would need a Terraform change, because LXC 100 receives only the CHILDREN of
# fast/appdata as bind mounts -- `zfs create` alone would not appear in the container.
# fast/appdata/automation is already a replicated dataset, so writing here gets these
# protected today with no Terraform dependency. backup-incremental.sh enumerates
# fast/appdata/* dynamically, so these are picked up with no further change.
#
# ASSERTS SIZE, because a broken pipe exits 0 and leaves a small file that looks like a
# backup -- the exact failure run-backup.sh already guards against for Immich.
set -o pipefail

DEST=/mnt/fast/appdata/automation/pgdumps
KEEP=7
MIN_BYTES=${MIN_BYTES:-20000}
STAMP=$(date +%Y%m%d-%H%M)
mkdir -p "$DEST"

fail=0
for c in teslamate-db paperless_postgres n8n-db; do
  if ! docker inspect "$c" >/dev/null 2>&1; then
    echo "  SKIP $c -- container not present"; continue
  fi
  user=$(docker inspect "$c" -f '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
         | sed -n 's/^POSTGRES_USER=//p' | head -1)
  user=${user:-postgres}
  out="$DEST/$c-$STAMP.sql.gz"
  docker exec -t "$c" pg_dumpall --clean --if-exists --username="$user" 2>/dev/null | gzip > "$out"
  rc=${PIPESTATUS[0]}
  sz=$(stat -c %s "$out" 2>/dev/null || echo 0)
  if [ "$rc" -ne 0 ] || [ "$sz" -lt "$MIN_BYTES" ]; then
    echo "  FAIL $c: rc=$rc bytes=$sz -- DO NOT TRUST, removing the stub"
    rm -f "$out"; fail=1
  else
    echo "  ok   $c (user=$user): $(numfmt --to=iec "$sz")"
  fi
  # retain the newest $KEEP per container
  ls -1t "$DEST/$c-"*.sql.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
done

echo "  dest: $DEST  total: $(du -sh "$DEST" 2>/dev/null | cut -f1)"
exit $fail
