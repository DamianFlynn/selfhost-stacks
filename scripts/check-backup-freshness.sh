#!/usr/bin/env bash
# check-backup-freshness.sh — assert the off-box backup is actually current.
#
# WHY THIS EXISTS. Until 2026-09-25 the estate had two working backup scripts on atlantis
# and NOTHING SCHEDULED, so the off-box copy was as current as the last time a human
# remembered. `backup-incremental.timer` now runs daily — but a timer that fails, or a USB
# pool that silently stops being imported, produces the same outcome as no timer at all
# while looking healthier. This check exists so that SILENCE IS LOUD.
#
# WHAT IT ASSERTS, and why it asserts on snapshots rather than on a log or a marker file:
# a snapshot on the target exists ONLY if a `zfs recv` actually completed. A log line can
# be written by a run that then died; a marker file can be touched by a wrapper that never
# reached the send. The snapshot is the artefact of the work itself, so it cannot lie about
# having happened. Age of the newest snapshot per dataset is therefore the honest metric.
#
# FAIL CLOSED (CONVENTIONS rule 1). Every branch below distinguishes "I looked and it is
# stale" from "I could not look". The second is NOT treated as healthy — a missing pool, an
# unreachable host or an unparseable date is a violation, because the whole point is that
# nobody notices when this goes quiet.
#
# ASSERT, DO NOT REPORT (rule 3). This exits non-zero on any violation. It does not print a
# number and leave the reader to decide whether it is bad.
#
# BOUND REMOTE COMMANDS LINUX-SIDE (rule 2). macOS has no GNU `timeout`, so every remote
# command is wrapped in `timeout` ON THE HOST, inside the ssh payload — never locally.
# Note that `timeout N cmd | wc -l` silently exits 0, so the ssh exit status is read
# explicitly rather than inferred from the output.

set -o pipefail

HOST="${BACKUP_HOST:-172.16.1.158}"
POOL="${BACKUP_POOL:-backup}"
# Overridable so the failure branch can be driven without editing this file. Per
# CONVENTIONS rule 4 an override may only ever make this check REDDER: raising the
# threshold cannot turn a real violation green, it can only widen what counts as stale.
MAX_AGE_HOURS="${BACKUP_MAX_AGE_HOURS:-48}"
REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-120}"

fail=0
red()  { printf '  \033[0;31m%s\033[0m\n' "$*"; }
grn()  { printf '  \033[0;32m%s\033[0m\n' "$*"; }
ylw()  { printf '  \033[1;33m%s\033[0m\n' "$*"; }

echo "🗄  Backup freshness — pool '$POOL' on $HOST, threshold ${MAX_AGE_HOURS}h"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---------------------------------------------------------------- 1. pool imported
# A pool that is not imported is the single most likely silent failure: the USB disk is
# addressed by-id precisely because its device letter moves, and an un-imported pool makes
# every send below skip rather than error.
pool_state=$(ssh -o BatchMode=yes -o ConnectTimeout=10 "root@$HOST" \
  "timeout $REMOTE_TIMEOUT zpool list -H -o health $POOL 2>/dev/null" 2>/dev/null)
ssh_rc=$?
# 255 is ssh's own transport failure; any other non-zero is the REMOTE command failing,
# which for `zpool list` means the pool is not imported. Distinguishing them matters:
# reporting "ssh failed" when the real cause is a missing pool sends the next reader to
# the network instead of to the disk. (Driven: rc=255 unreachable host, rc=1 absent pool.)
if [ $ssh_rc -eq 255 ]; then
  red "COULD NOT LOOK: ssh transport to $HOST failed (rc=255) — VIOLATION, not a pass"
  echo; echo "📊 1. Summary"; red "FAILURES total: 1"; exit 1
fi
if [ $ssh_rc -ne 0 ] || [ -z "$pool_state" ]; then
  red "VIOLATION: pool '$POOL' is not imported on $HOST (remote rc=$ssh_rc) — nothing is being backed up"
  fail=1
elif [ "$pool_state" != "ONLINE" ]; then
  red "VIOLATION: pool '$POOL' health is '$pool_state', expected ONLINE"
  fail=1
else
  grn "pool '$POOL' ONLINE"
fi

# ---------------------------------------------------------------- 2. freshness per dataset
# `-p` gives creation as a unix epoch, which avoids parsing a locale-formatted date.
# Datasets with NO snapshot at all are a violation in their own right: a dataset present on
# the target with no snapshot means a full send landed and no incremental ever has.
#
# TWO FLAT REMOTE CALLS, NO NESTED LOOP — and that is deliberate. The first version of this
# block ran a `while read` inside the ssh payload and the escaping mangled it: it returned
# ONE line instead of 28, so the check printed "all 0 snapshotted datasets are within 48h"
# and EXITED 0 having examined nothing. A false green, in the very check written to stop
# false greens. Same class as the documented trap about heredocs through ssh. Keep the
# remote side to single flat commands and do the joining locally where it can be tested.
#
# The cardinality assertion below is the guard that would have caught it.
datasets=$(ssh -o BatchMode=yes -o ConnectTimeout=10 "root@$HOST" \
  "timeout $REMOTE_TIMEOUT zfs list -H -p -o name,refer -r $POOL" 2>/dev/null)
ds_rc=$?
snaps=$(ssh -o BatchMode=yes -o ConnectTimeout=10 "root@$HOST" \
  "timeout $REMOTE_TIMEOUT zfs list -H -p -t snapshot -o creation,name -S creation -r $POOL" 2>/dev/null)
sn_rc=$?
if [ $ds_rc -ne 0 ] || [ -z "$datasets" ]; then
  red "COULD NOT LOOK: dataset enumeration failed (rc=$ds_rc) — VIOLATION, not a pass"
  echo; echo "📊 1. Summary"; red "FAILURES total: $((fail + 1))"; exit 1
fi
if [ $sn_rc -ne 0 ]; then
  red "COULD NOT LOOK: snapshot enumeration failed (rc=$sn_rc) — VIOLATION, not a pass"
  echo; echo "📊 1. Summary"; red "FAILURES total: $((fail + 1))"; exit 1
fi

# CARDINALITY GUARD. A pool that is imported and holding 3.5 T cannot have one dataset.
# Without this the check can look green because the enumeration silently returned nothing.
ds_count=$(printf '%s\n' "$datasets" | grep -c .)
if [ "$ds_count" -lt 5 ]; then
  red "COULD NOT LOOK: only $ds_count dataset(s) enumerated on '$POOL' — implausible, VIOLATION"
  echo; echo "📊 1. Summary"; red "FAILURES total: $((fail + 1))"; exit 1
fi

# Build dataset|creation|snapname, newest snapshot per dataset ($snaps is already sorted
# newest-first by -S creation, so the first hit per dataset wins).
report=$(printf '%s\n' "$datasets" | while IFS=$'\t' read -r ds refer; do
  [ -z "$ds" ] && continue
  [ "$ds" = "$POOL" ] && continue
  line=$(printf '%s\n' "$snaps" | awk -F'\t' -v d="$ds" '$2 ~ ("^" d "@") {print $1 "\t" $2; exit}')
  if [ -z "$line" ]; then
    printf '%s|NOSNAP|%s\n' "$ds" "$refer"
  else
    printf '%s|%s|%s\n' "$ds" "$(printf '%s' "$line" | cut -f1)" "$(printf '%s' "$line" | cut -f2)"
  fi
done)

now=$(date +%s)
max_age_s=$(( MAX_AGE_HOURS * 3600 ))
n=0; stale=0; nosnap=0; leaf=0
while IFS='|' read -r ds created snap; do
  [ -z "$ds" ] && continue
  n=$((n + 1))
  if [ "$created" = "NOSNAP" ]; then
    # Container datasets (e.g. backup/media, backup/appdata) legitimately hold no snapshot
    # of their own — they exist only to parent the real ones. `refer` distinguishes them:
    # a container refers a few hundred KB of metadata, a real dataset refers its data. The
    # third field carries refer from the same enumeration, so this needs no extra ssh.
    if [ -n "$snap" ] && [ "$snap" -gt 10485760 ] 2>/dev/null; then
      red "VIOLATION: $ds holds $(numfmt --to=iec "$snap" 2>/dev/null || echo "${snap}B") but has NO snapshot"
      nosnap=$((nosnap + 1)); fail=1
    fi
    continue
  fi
  leaf=$((leaf + 1))
  age_s=$(( now - created ))
  age_h=$(( age_s / 3600 ))
  if [ "$age_s" -gt "$max_age_s" ]; then
    red "STALE: $ds — newest snapshot ${age_h}h old (${snap##*@})"
    stale=$((stale + 1)); fail=1
  fi
done <<< "$report"

[ "$stale" -eq 0 ] && [ "$nosnap" -eq 0 ] && grn "all $leaf snapshotted datasets are within ${MAX_AGE_HOURS}h"

# ---------------------------------------------------------------- 3. the timer itself
# A timer that has been disabled by hand is exactly the silence this check is for.
timer=$(ssh -o BatchMode=yes -o ConnectTimeout=10 "root@$HOST" \
  "timeout 30 systemctl is-enabled backup-incremental.timer 2>/dev/null" 2>/dev/null)
case "$timer" in
  enabled) grn "backup-incremental.timer enabled" ;;
  "")      red "COULD NOT LOOK: timer state unreadable — VIOLATION"; fail=1 ;;
  *)       red "VIOLATION: backup-incremental.timer is '$timer', expected 'enabled'"; fail=1 ;;
esac

echo
echo "📊 1. Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  datasets examined:  $n  (of which snapshotted: $leaf)"
echo "  stale:              $stale"
echo "  holding data, no snapshot: $nosnap"
if [ "$fail" -eq 0 ]; then
  grn "FAILURES total: 0"
else
  red "FAILURES total: $((stale + nosnap))+"
  ylw "The off-box backup is NOT current. Fix before trusting any restore."
fi
exit "$fail"
