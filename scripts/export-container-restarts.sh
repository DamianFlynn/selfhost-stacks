#!/usr/bin/env bash
# export-container-restarts.sh — container RESTART state into a node-exporter textfile, every 2 min.
#
# WHAT IT MEASURES, AND WHY: per running/restarting container, whether docker reports it in state
# `restarting` and its RestartCount; plus the estate counts of restarting and RUNNING-unhealthy
# containers. Added by quick 261111-rmv after Jellyfin crash-looped ~21 h (RestartCount 1,229) and
# nothing alerted; the history lives in .planning/quick/261111-rmv-restart-loop-alerting/.
#
# RUNS ON LXC 100 ONLY (it reads the local docker daemon), from
# scripts/systemd/selfhost-container-restarts.{service,timer}. READ-ONLY BY CONTRACT apart from its
# one textfile, $RESTARTS_PROM_DIR/container-restarts.prom.
#
# EXIT CODES
#   0  measurement written, WHATEVER THE COUNTS. The gauges are the signal and Grafana owns the
#      alert — the same argument as check-drift.sh's --prom exit-code block: a non-zero on a
#      restarting container would park the unit `failed` for a condition the rule already owns,
#      and make a genuine could-not-look indistinguishable from it.
#   1  could not look. NOTHING is written.
#   2  usage.
#
# FAIL CLOSED: this script never writes 0 on a failed read. On any could-not-look path the existing
# file is left byte-identical, its last_success timestamp goes stale, and the Grafana rule
# `Restart exporter is stale` fires. A file full of zeros after a failed read would be a false
# green, which is the exact failure this exporter exists to end.
#
# ⚠️ ONE DECISION ACROSS THREE FILES: the 360 s staleness threshold in
# stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml (`Restart exporter is
# stale`) = 125 s worst start gap (selfhost-container-restarts.timer, OnCalendar=*:0/2 +
# AccuracySec=5s) + 60 s runtime cap (selfhost-container-restarts.service, TimeoutStartSec=60)
# + 120 s for one missed run + 15 s scrape ≈ 320 s, rounded up to 360. The timeouts below (30 s +
# 60 s, and a retry) are why the service cap must stay at 60 s or the runs must stay short.

set -uo pipefail

if [[ $# -gt 0 ]]; then
  echo "usage: $0   (no arguments; RESTARTS_PROM_DIR overrides the output dir for testing only)" >&2
  exit 2
fi

# The override exists ONLY so the fail-closed branches can be driven against a scratch dir. Using
# it leaves the real file to go stale, i.e. it can only make the estate redder (CONVENTIONS rule 4).
RESTARTS_PROM_DIR="${RESTARTS_PROM_DIR:-/mnt/fast/appdata/monitoring/node-exporter-textfile}"
RESTARTS_PROM_FILE=container-restarts.prom

could_not_look() {
  echo "UNKNOWN: $* — NOT writing $RESTARTS_PROM_DIR/$RESTARTS_PROM_FILE (it stays byte-identical and goes stale)." >&2
  exit 1
}

prom_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

[[ -d "$RESTARTS_PROM_DIR" && -w "$RESTARTS_PROM_DIR" ]] \
  || could_not_look "textfile dir $RESTARTS_PROM_DIR does not exist or is not writable"

SEP='|:|'
FMT="{{.Name}}${SEP}{{.State.Status}}${SEP}{{.RestartCount}}${SEP}{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}"

enumerate() {
  IDS=""
  if ! IDS=$(timeout 30 docker ps -aq 2>/dev/null); then
    could_not_look "'docker ps -aq' exited non-zero"
  fi
  if [[ -z "$IDS" ]]; then
    could_not_look "'docker ps -aq' returned no containers; on this estate that is a broken daemon, not 'nothing is wrong'"
  fi
}

enumerate
INSPECT_OUT=""
# shellcheck disable=SC2086
if ! INSPECT_OUT=$(timeout 60 docker inspect --format "$FMT" $IDS 2>/dev/null); then
  # Expected cause: a container removed between ps and inspect (a deploy). Re-enumerate, retry ONCE.
  enumerate
  # shellcheck disable=SC2086
  INSPECT_OUT=$(timeout 60 docker inspect --format "$FMT" $IDS 2>/dev/null) \
    || could_not_look "'docker inspect' failed twice"
fi
[[ -n "$INSPECT_OUT" ]] || could_not_look "'docker inspect' returned nothing"

RESTARTING_COUNT=0
RUNNING_UNHEALTHY_COUNT=0
FLAG_SERIES=()
COUNT_SERIES=()
RESTARTING_NAMES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  name="${line%%"$SEP"*}"; rest="${line#*"$SEP"}"
  state="${rest%%"$SEP"*}"; rest="${rest#*"$SEP"}"
  rc="${rest%%"$SEP"*}"; health="${rest#*"$SEP"}"
  name="${name#/}"
  [[ -n "$state" && -n "$name" ]] || could_not_look "unparseable inspect line: $line"
  [[ "$rc" =~ ^[0-9]+$ ]] || could_not_look "RestartCount not numeric for $name: '$rc'"

  [[ "$state" == "running" && "$health" == "unhealthy" ]] && RUNNING_UNHEALTHY_COUNT=$((RUNNING_UNHEALTHY_COUNT + 1))
  if [[ "$state" == "restarting" ]]; then
    RESTARTING_COUNT=$((RESTARTING_COUNT + 1))
    RESTARTING_NAMES+=( "$name" )
  fi
  if [[ "$state" == "running" || "$state" == "restarting" ]]; then
    esc="$(prom_escape "$name")"
    flag=0; [[ "$state" == "restarting" ]] && flag=1
    FLAG_SERIES+=( "selfhost_container_restarting{name=\"$esc\"} $flag" )
    COUNT_SERIES+=( "selfhost_container_restart_count{name=\"$esc\"} $rc" )
  fi
done <<< "$INSPECT_OUT"

TMP="$RESTARTS_PROM_DIR/.${RESTARTS_PROM_FILE}.tmp.$$"   # must NOT end in .prom: node-exporter globs *.prom
# Each metric family is written contiguously (HELP, TYPE, its samples); the per-container families
# are not interleaved, because the exposition format requires a family's samples to be grouped.
# The success timestamp is written LAST.
{
  echo "# HELP selfhost_containers_restarting Containers in docker state 'restarting'."
  echo "# TYPE selfhost_containers_restarting gauge"
  echo "selfhost_containers_restarting $RESTARTING_COUNT"
  echo "# HELP selfhost_containers_running_unhealthy RUNNING containers reporting docker health status 'unhealthy' (duplicates check-drift's selfhost_containers_unhealthy at 2-minute resolution, on purpose; no rule reads it)."
  echo "# TYPE selfhost_containers_running_unhealthy gauge"
  echo "selfhost_containers_running_unhealthy $RUNNING_UNHEALTHY_COUNT"
  echo "# HELP selfhost_container_restarting 1 if the container is in state 'restarting', else 0. One series per running or restarting container."
  echo "# TYPE selfhost_container_restarting gauge"
  for s in "${FLAG_SERIES[@]+"${FLAG_SERIES[@]}"}"; do echo "$s"; done
  echo "# HELP selfhost_container_restart_count docker RestartCount. One series per running or restarting container; resets to 0 when the container is recreated."
  echo "# TYPE selfhost_container_restart_count gauge"
  for s in "${COUNT_SERIES[@]+"${COUNT_SERIES[@]}"}"; do echo "$s"; done
  echo "# HELP selfhost_container_restarts_last_success_timestamp_seconds Unix time of the last SUCCESSFUL measurement. It does NOT mean nothing is restarting."
  echo "# TYPE selfhost_container_restarts_last_success_timestamp_seconds gauge"
  echo "selfhost_container_restarts_last_success_timestamp_seconds $(date +%s)"
} > "$TMP" || { rm -f "$TMP"; could_not_look "could not write temp file $TMP"; }
chmod 0644 "$TMP"
mv -f "$TMP" "$RESTARTS_PROM_DIR/$RESTARTS_PROM_FILE" || { rm -f "$TMP"; could_not_look "mv into place failed"; }

echo "wrote $RESTARTS_PROM_DIR/$RESTARTS_PROM_FILE: series=${#COUNT_SERIES[@]} restarting=$RESTARTING_COUNT running_unhealthy=$RUNNING_UNHEALTHY_COUNT${RESTARTING_NAMES[0]+ names=${RESTARTING_NAMES[*]}}"
exit 0
