#!/usr/bin/env bash
# check-drift.sh - Read-only audit of IMAGE DRIFT: which running containers are on an image tag
#                  that this repository's compose files no longer pin.
# Usage: bash scripts/check-drift.sh [--prom] [-h|--help]
#
# NAMING - DO NOT CONFLATE TWO KINDS OF "DRIFT". This file's subject is IMAGE drift: the running
#   container's image reference versus the reference git declares. The estate ALREADY uses the word
#   "drift" for something else entirely - vendored-file sha256 mismatch (VENDORED_DRIFT_PROMOTED,
#   DRIFT_APPDATA_ROOT in scripts/quick-health-check.sh). Every identifier, metric name and message
#   here carries the word `image` so a grep can tell the two apart. The env overrides below are the
#   one exception and they are namespaced DRIFT_* only to match the estate's existing prefix; each
#   is documented against this file by name.
#
# THE SENTENCE A READER IS MOST LIKELY TO GET WRONG, so it is first:
#   THIS COMPARES THE IMAGE REFERENCE STRING THE CONTAINER WAS CREATED WITH AGAINST THE REFERENCE
#   STRING GIT PINS. IT IS NOT A DIGEST COMPARISON AND IT IS NOT PROOF THE TWO REFERENCES RESOLVE
#   TO THE SAME BYTES. A green line here means "the tag git declares is the tag docker was handed",
#   nothing more. See KNOWN LIMITS below for the case where that is materially weaker than it looks.
#
# WHERE IT RUNS:
#   ON LXC 100 (root@172.16.1.159). It needs the docker daemon AND the repo checkout at
#   /mnt/fast/stacks, and neither exists on the macOS workstation. It lands on the host by
#   `git pull` into /mnt/fast/stacks - there is no copy step to remember. The workstation only ever
#   ssh's to it, exactly as scripts/check-jellyfin-transcode.sh is used by
#   scripts/quick-health-check.sh.
#
#   It also requires bash >= 4 (associative arrays). macOS ships bash 3.2, so there is an explicit
#   guard below that exits 2 - an ENVIRONMENT error, never a failed assertion. "This instrument
#   cannot be used here" is not "the estate is broken"; same convention as
#   check-jellyfin-transcode.sh's Darwin guard.
#
# READ-ONLY BY CONTRACT. This script inspects. It never pulls, never recreates, never starts or
#   stops anything, never writes into /mnt/fast/stacks, and never mutates .git unless
#   DRIFT_GIT_FETCH=1 is passed deliberately (off by default - see below). The ONLY byte it ever
#   writes is the node-exporter textfile in --prom mode, into DRIFT_PROM_DIR.
#
# V1 IS ALERT-ONLY (D-01). It detects and it tells you. Enabling an auto-apply path later is a flag
#   flip at IMAGE_DRIFT_AUTOAPPLY below, not a rewrite. The apply path is deliberately NOT written.
#
# ---------------------------------------------------------------------------------------------
# HOW THE PIN IS RESOLVED - the crux, and every step of it exists because a MEASURED fact on this
# estate breaks the obvious approach:
#
#   1. Enumerate containers with `docker ps -aq` and `docker inspect` them ONCE, in a single pass.
#      Drift is classified for RUNNING containers only; the `created` and `unhealthy` tallies need
#      the whole set, which is why the enumeration is `-a` and the classification is filtered.
#      (`docker ps` without `-a` does NOT show `created` containers. That blind spot once hid
#      dispatcharr and teleport down for six weeks under a green check.)
#
#   2. Read `.Config.Image`, NOT `docker ps --format '{{.Image}}'`. `.Config.Image` is the exact
#      string the container was created with, registry prefix and digest included -
#      `docker.io/valkey/valkey:8-bookworm@sha256:fea8b3e6...` for immich_redis, byte-identical to
#      the repo pin. `docker ps` NORMALISES that away and is the likely source of the immich_redis
#      false positive this file was written to stop reporting.
#
#   3. Read the labels `com.docker.compose.service` and `com.docker.compose.project.config_files`.
#      MEASURED 2026-09-18: all 97 running containers carry them; zero are missing. So the
#      container -> (compose file, service) mapping is AUTHORITATIVE and needs no guessing. That is
#      what solves the "same image repo pinned in two stack files at different tags" hazard: the
#      map is keyed PER CONTAINER by its own label, never globally by image repo.
#
#   4. Group containers by their `config_files` value (comma-separated; each element becomes its
#      own `-f`) and resolve each DISTINCT GROUP ONCE - not once per container. 24 distinct values
#      exist today against ~100 containers.
#
#   5. Per group run `docker compose <-f each> config --format json`, bounded by `timeout`, and read
#      `.services | to_entries[] | "\(.key)\t\(.value.image // "")"` with jq.
#
#      DO NOT GREP `image:` OUT OF THE FILES AND DO NOT HAND-ROLL A YAML PARSER. Four measured
#      facts make that wrong, and only `docker compose config` handles all four:
#        - `include:` IS IN USE. node-exporter's label points at
#          stacks/selfhosted/monitoring/compose.yaml, which carries no `image:` line at all - the
#          pin lives in the include'd node-exporter.yaml. A grep of the labelled file finds nothing
#          for every include-based stack.
#        - VARIABLE-SUBSTITUTED PINS EXIST (`image: ${BUZZ_IMAGE}`).
#        - COMMENTED-OUT `image:` LINES EXIST and must never enter the pin map.
#        - jq is present at /usr/bin/jq; yq is ABSENT and PyYAML is NOT installed. Installing either
#          is out of scope by decision (threat T-c12-SC): if this file ever wants them, stop and
#          re-plan rather than install.
#
#   6. Look the container's service key up in that group's resolved map to get the declared pin.
#
# NORMALISATION BEFORE COMPARING - each rule exists because a measured pin needs it:
#   - strip a leading `docker.io/` (and `index.docker.io/`), then a `library/` segment immediately
#     after it. Registry-qualified pins exist in this repo: docker.io/oxidized/oxidized,
#     docker.io/pglombardo/pwpush, docker.io/postgres:18, gcr.io/cadvisor/cadvisor.
#   - an absent tag becomes `:latest` - but ONLY when there is no digest. Untagged pins exist
#     (docker.n8n.io/n8nio/n8n).
#   - if EITHER side carries `@sha256:`, the outcome is OK when the full `repo:tag@digest` strings
#     are equal and DIGEST_PINNED - reported, NEVER IMAGE_DRIFT - when they are not. Four
#     digest-pinned lines exist today (immich valkey, immich postgres, authelia, traefik) and a
#     digest-pinned container must never appear in the drift list.
#
# CLASSIFICATION - every running container lands in exactly one bucket:
#   OK             normalised running reference == normalised declared reference
#   IMAGE_DRIFT    both resolved, neither digest-pinned, and they differ
#   DIGEST_PINNED  at least one side is digest-pinned and they differ (reported, not drift)
#   UNRESOLVABLE   a config file in the group is missing, `docker compose config` exited non-zero,
#                  the service key is absent from the resolved map, or the declared image is ""
#
#   UNRESOLVABLE IS A COUNTED OUTCOME OF A SUCCESSFUL RUN, NOT A COULD-NOT-LOOK, and it must never
#   abort the run. /mnt/fast/stacks/immich/compose.yaml DOES NOT EXIST - it is a stale compose
#   project - so immich_redis and immich_postgres are PERMANENTLY unresolvable, and aborting on
#   them would make this check red on the day it ships. That is the 01-09 trap that
#   quick-health-check.sh already carries three notices about: a permanently-red check trains the
#   reader to ignore it. (immich_server and immich_machine_learning belong to a DIFFERENT project
#   whose label points at the real .../stacks/selfhosted/immich/compose.yaml and resolve fine.)
#   The count IS asserted - see DRIFT_EXPECT_UNRESOLVABLE - because a THIRD unresolvable container
#   is a new stale compose project and must go red.
#
# ---------------------------------------------------------------------------------------------
# THE MEASURED FIXTURE, AND A CORRECTION TO THE NUMBER THIS FILE WAS COMMISSIONED AGAINST.
#
#   FIRST RUN, 2026-09-18T07:55:57Z on LXC 100, against /mnt/fast/stacks at origin/main:
#     image drift 14 | unresolvable 2 | digest-pinned 0 | matching 80 | unhealthy 1 | created 0
#
#   THE BRIEF SAID 12 AND NAMED THE TWELVE. This file finds those twelve AND TWO MORE - `n8n` and
#   `socket-proxy` - and the two extras are REAL DRIFT, not false positives. They are the exact
#   hazard step 3 above says the per-container label exists to defeat, caught in the wild on the
#   first run:
#
#     n8n            runs ghcr.io/damianflynn/custom-n8n:2.11.1
#                    label config_files = .../stacks/selfhosted/automation/compose.yaml
#                    which include's n8n.yaml, pinning       custom-n8n:2.22.0   -> DRIFTED
#                    BUT stacks/mpe/n8n/n8n.yaml also carries custom-n8n:2.11.1
#     socket-proxy   runs tecnativa/docker-socket-proxy:v0.4.2
#                    label config_files = .../stacks/selfhosted/traefik/compose.yaml
#                    which include's socket-proxy.yaml, pinning            v0.5.0 -> DRIFTED
#                    BUT stacks/mpe/edge/socket-proxy.yaml also carries    v0.4.2
#
#   So a matcher that asks "does this running reference appear ANYWHERE in the repo?" answers "yes"
#   for both and reports 12. A matcher that asks "does it match the pin in THIS CONTAINER'S OWN
#   PROJECT?" answers "no" for both and reports 14. THE SECOND QUESTION IS THE ONE WORTH ASKING,
#   and it is the one this file asks. 14 is the corrected fixture; 12 is what the superseded method
#   returned. Recorded here rather than only in a plan because the next reader will meet 14, and a
#   number that disagrees with the document that commissioned it needs its reason in-band.
#
#   ⚠️ node-exporter IS ITSELF ONE OF THE DRIFTED (running v1.11.1, pinned v1.12.1). Recreating it
#   to pick up the textfile-collector flag will therefore take the count 14 -> 13. THAT IS THE
#   CHANGE WORKING, NOT A REGRESSION. Do not read a smaller number as a fault.
#
#   ⚠️ SEPARATELY, AND NOT A DRIFT FINDING: on 2026-09-18 `docker ps` reported cadvisor
#   `running / Up 2 weeks (health: starting)` while `docker inspect` on the SAME container id
#   reported `exited`, exit code 137, finished 2026-09-02. Sixteen days dead behind a `docker ps`
#   line that says it is up. This file believes `docker inspect` - which is why cadvisor is
#   excluded from the drift classification (state != running) and counted once under `unhealthy`.
#   Left as an estate finding rather than fixed here: it is outside this change's scope and is
#   logged to the phase's deferred-items.md.
#
# ---------------------------------------------------------------------------------------------
# EXIT CODES - THE TWO MODES DIFFER DELIBERATELY:
#
#   report mode (no arguments)
#     0  clean
#     1  image drift found, OR the unresolvable count/name-set differs from the expectation, OR any
#        could-not-look, OR a non-default path override is in force
#     2  usage error (an unknown flag), matching `quick-health-check.sh --nonsense` -> 2. An
#        unsupported shell/platform is an ENVIRONMENT error and is also 2, never 1.
#
#   --prom mode
#     0  WHENEVER THE MEASUREMENT SUCCEEDED AND THE FILE WAS WRITTEN - REGARDLESS OF THE DRIFT
#        COUNT.
#     1  could-not-look only.
#
#     Why they differ, stated in-band because it is the kind of asymmetry that gets "tidied" away:
#     in --prom mode THE METRIC IS THE SIGNAL. Exiting non-zero on drift would park systemd in
#     `failed` permanently for a condition the Grafana alert rule already owns, and - worse - it
#     would make a genuine could-not-look indistinguishable from ordinary drift at the one place
#     where the difference is the whole point.
#
#     SO, EXPLICITLY: `selfhost_image_drift_last_success_timestamp_seconds` means THE MEASUREMENT
#     RAN. It does NOT mean there is no drift. The drift count is its own gauge.
#
# REPORT MODE EXITS 1 ON DRIFT WITH `FAILURES total: 0`, AND THAT IS NOT A CONTRADICTION.
#   `FAILURES total` counts ONLY fatal findings - failed assertions and could-not-looks. The drift
#   count is REPORTED on its own line and is what pushes the exit to 1 for a human who typed the
#   command. scripts/quick-health-check.sh depends on exactly this split: it treats a non-zero exit
#   with `FAILURES total: 0` and `could-not-look: 0` as "drift exists, say so on the green path",
#   and anything else as fatal. See the CROSS-FILE CONTRACT at the summary block below.
#
# COULD-NOT-LOOK CONDITIONS - each gets its own distinct `⚠️ UNKNOWN` message, never `0 problems
#   found`:
#     - docker unavailable, or `docker ps` exits non-zero
#     - jq absent
#     - timeout absent
#     - the repo checkout absent at DRIFT_REPO
#     - (--prom only) the output directory absent or not writable
#
# ENV OVERRIDES - all in the ${VAR:-default} form so a grep can prove they exist. EVERY ONE OF THEM
#   MAY ONLY MAKE THE CHECK REDDER. This is the DRIFT_APPDATA_ROOT contract already in
#   quick-health-check.sh and the reasoning is copied here on purpose:
#     DRIFT_EXPECT_UNRESOLVABLE        default 2. ASSERTED. Changing it moves WHICH count is
#                                      correct; it cannot stop the comparison happening.
#     DRIFT_EXPECT_UNRESOLVABLE_NAMES  default "immich_redis immich_postgres". ASSERTED as a set.
#     DRIFT_REPO                       default /mnt/fast/stacks. Exists ONLY to drive the
#                                      could-not-look branch, so ANY non-default value forces
#                                      EXIT 1 in report mode whatever the comparison finds.
#     DRIFT_PROM_DIR                   default /mnt/fast/appdata/monitoring/node-exporter-textfile.
#                                      Same treatment in REPORT mode. In --prom mode it does NOT
#                                      force red - the negative control that proves a dead run
#                                      leaves the previous file untouched has to write a real file
#                                      into a scratch directory first, and an override that cannot
#                                      be exercised is an override nobody will exercise. It still
#                                      cannot manufacture a pass: a missing or unwritable directory
#                                      is a could-not-look and nothing is written.
#     DRIFT_GIT_FETCH                  default 0. When 1, `git fetch` before counting commits.
#                                      OFF BY DEFAULT because a timer that mutates .git hourly is a
#                                      host change nobody asked for.
#   There is deliberately NO success-producing override and NO sentinel that skips the check. Do not
#   add one, however convenient it looks while debugging.
#
# ---------------------------------------------------------------------------------------------
# KNOWN LIMITS - stated here rather than hidden, because both make a green weaker than it reads:
#
#   1. A FLOATING TAG THAT HAS MOVED UPSTREAM READS AS NO DRIFT. `:latest`, `:main` and two-part
#      tags like `2.13` all float: the registry re-points them, both sides of this comparison still
#      carry the same string, and this check says OK while the host runs a different image than a
#      fresh `docker pull` would fetch. That is DEPLOYMENT.md § 5's "two-part tags float" trap in a
#      new costume. Measured floating pins in this repo today include
#      ghcr.io/listenarrs/listenarr:latest and ghcr.io/open-webui/mcpo:main. NOT FIXED IN V1 -
#      fixing it means comparing resolved digests against the registry, which is a network
#      dependency and a rate-limit surface this check deliberately does not take on.
#
#   2. `commits behind` IS A LOWER BOUND WITHOUT A FETCH. It is
#      `git rev-list --count HEAD..origin/main`, and without a `git fetch` that uses the
#      LAST-FETCHED origin/main. If nothing has fetched in a week the true number is larger. Set
#      DRIFT_GIT_FETCH=1 to fetch first; it is off by default for the reason given above. The
#      figure is REPORTED, never asserted.
#
# ---------------------------------------------------------------------------------------------
# SECRETS. Nothing here reads, writes or prints a credential. THIS REPOSITORY IS PUBLIC and has one
#   prior exposure still recoverable via `git log -S`; the metric labels emitted in --prom mode are
#   container names and image tags from this estate's own compose files and docker daemon, and
#   nothing external reaches them.

set -euo pipefail

# ---------------------------------------------------------------------------------------------
# THE AUTO-APPLY SEAM (D-01 / D-03). This constant is the whole of it.
#
# It is 0 and there is no code path that reads it beyond the banner below, BY DESIGN. v1 detects
# and alerts; it does not pull, recreate or apply. Flipping this to 1 would mean: after classifying
# a container IMAGE_DRIFT, this script would `docker compose ... pull` and `up -d` that service -
# i.e. it would become a DEPLOY TOOL RUNNING ON AN HOURLY TIMER WITH NOBODY WATCHING. That is a
# separate decision with its own blast radius (D-03), and it needs its own gate, its own dry-run
# and its own rollback before it is written. Do not write the apply path here to "save a step".
IMAGE_DRIFT_AUTOAPPLY=0

# --- shell/platform guard (exit 2 - environment error, not a failed assertion) -----------------
if [[ -z "${BASH_VERSINFO:-}" || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo "check-drift.sh requires bash >= 4 (associative arrays); this is bash ${BASH_VERSION:-unknown}." >&2
  echo "It runs ON LXC 100, not on the macOS workstation:" >&2
  echo "  ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-drift.sh'" >&2
  exit 2
fi

# --- env overrides (see ENV OVERRIDES in the header) ------------------------------------------
DRIFT_REPO_DEFAULT="/mnt/fast/stacks"
DRIFT_PROM_DIR_DEFAULT="/mnt/fast/appdata/monitoring/node-exporter-textfile"
DRIFT_REPO="${DRIFT_REPO:-$DRIFT_REPO_DEFAULT}"
DRIFT_PROM_DIR="${DRIFT_PROM_DIR:-$DRIFT_PROM_DIR_DEFAULT}"
DRIFT_PROM_FILE="image-drift.prom"
DRIFT_GIT_FETCH="${DRIFT_GIT_FETCH:-0}"
DRIFT_EXPECT_UNRESOLVABLE="${DRIFT_EXPECT_UNRESOLVABLE:-2}"
DRIFT_EXPECT_UNRESOLVABLE_NAMES="${DRIFT_EXPECT_UNRESOLVABLE_NAMES:-immich_redis immich_postgres}"
DRIFT_COMPOSE_TIMEOUT="${DRIFT_COMPOSE_TIMEOUT:-60}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROM_MODE=0
for arg in "$@"; do
  case "$arg" in
    --prom) PROM_MODE=1 ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: bash scripts/check-drift.sh [--prom]" >&2
      exit 2
      ;;
  esac
done

FAILURES=0        # fatal findings: failed assertions AND could-not-looks
UNKNOWNS=0        # could-not-looks alone, counted separately so the reader can tell them apart
DRIFT_COUNT=0     # REPORTED, not asserted - see the exit-code note in the header
UNRESOLVABLE_COUNT=0
DIGEST_PINNED_COUNT=0
OK_COUNT=0
UNHEALTHY_COUNT="UNKNOWN"
CREATED_COUNT="UNKNOWN"
COMMITS_BEHIND="UNKNOWN"

fail()    { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
unknown() { echo -e "  ${YELLOW}⚠️  UNKNOWN — $*${NC}"; UNKNOWNS=$((UNKNOWNS + 1)); FAILURES=$((FAILURES + 1)); }
pass()    { echo -e "  ${GREEN}✅ $*${NC}"; }
warn()    { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info()    { echo -e "  ${BLUE}$*${NC}"; }
rule()    { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

echo "🧭 Image drift audit (running image vs the pin in git)"
rule
echo "  repo:       $DRIFT_REPO"
echo "  host:       $(hostname)"
echo "  date:       $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [[ $PROM_MODE -eq 1 ]]; then
  echo "  mode:       --prom (writes $DRIFT_PROM_DIR/$DRIFT_PROM_FILE; exit 0 on a successful"
  echo "              measurement REGARDLESS of the drift count — the metric is the signal)"
else
  echo "  mode:       report (exit 1 on drift, on a failed assertion, or on any could-not-look)"
fi
echo "  auto-apply: IMAGE_DRIFT_AUTOAPPLY=$IMAGE_DRIFT_AUTOAPPLY (v1 is ALERT-ONLY — D-01)"
echo ""

# =============================================================================================
# 0. Routes and preconditions — fail closed; every missing route is a COULD-NOT-LOOK, not a skip
# =============================================================================================
echo "🧰 0. Routes and preconditions"
rule

for t in docker jq timeout git; do
  if command -v "$t" >/dev/null 2>&1; then
    pass "$t $(command -v "$t")"
  else
    unknown "$t NOT FOUND — this script runs ON LXC 100 (root@172.16.1.159), not on the workstation."
  fi
done

# Non-default path overrides force red in REPORT mode. They exist only to drive the
# could-not-look branches, so they can never be used to make a red run report green.
# --prom is exempt for DRIFT_PROM_DIR alone; see ENV OVERRIDES in the header for why.
if [[ "$DRIFT_REPO" != "$DRIFT_REPO_DEFAULT" ]]; then
  fail "DRIFT_REPO override in force ('$DRIFT_REPO' != '$DRIFT_REPO_DEFAULT') — forcing red. This"
  echo "         override exists ONLY to drive the could-not-look branch; it cannot produce a pass."
fi
if [[ "$DRIFT_PROM_DIR" != "$DRIFT_PROM_DIR_DEFAULT" && $PROM_MODE -eq 0 ]]; then
  fail "DRIFT_PROM_DIR override in force ('$DRIFT_PROM_DIR') — forcing red in report mode."
fi

DOCKER_OK=0
if command -v docker >/dev/null 2>&1; then
  if timeout 30 docker ps -q >/dev/null 2>&1; then
    DOCKER_OK=1
    pass "docker daemon answers 'docker ps'"
  else
    unknown "'docker ps' exited non-zero — the daemon is unreachable or wedged. NOTHING below was"
    echo "         measured. This is 'could not look', not 'no drift'."
  fi
fi

REPO_OK=0
if [[ -d "$DRIFT_REPO/.git" ]]; then
  REPO_OK=1
  pass "repo checkout present at $DRIFT_REPO"
else
  unknown "no git checkout at $DRIFT_REPO — the declared pins cannot be read from git."
fi

PROM_DIR_OK=0
if [[ $PROM_MODE -eq 1 ]]; then
  if [[ -d "$DRIFT_PROM_DIR" && -w "$DRIFT_PROM_DIR" ]]; then
    PROM_DIR_OK=1
    pass "textfile directory $DRIFT_PROM_DIR exists and is writable"
  else
    unknown "textfile directory $DRIFT_PROM_DIR is absent or not writable — NOTHING will be written."
    echo "         The existing $DRIFT_PROM_FILE (if any) is left BYTE-IDENTICAL on purpose, so it"
    echo "         goes stale and the staleness alert fires. A fresh timestamp on a failed run is"
    echo "         the one outcome this metric exists to prevent."
  fi
fi
echo ""

# =============================================================================================
# 1. Resolve every running container's declared pin and classify it
# =============================================================================================
echo "🔀 1. Image drift"
rule

declare -A GROUP_MAP      # config_files value -> resolved "service<TAB>image" lines
declare -A GROUP_STATUS   # config_files value -> ok | missing:<path> | failed
declare -a DRIFT_LINES=()
declare -a UNRESOLVABLE_LINES=()
declare -a UNRESOLVABLE_NAMES=()
declare -a DIGEST_LINES=()

# normalise_ref - see NORMALISATION in the header. Every rule here answers a measured pin.
normalise_ref() {
  local ref="$1" digest=""
  if [[ "$ref" == *"@sha256:"* ]]; then
    digest="@${ref#*@}"
    ref="${ref%%@*}"
  fi
  ref="${ref#index.docker.io/}"
  ref="${ref#docker.io/}"
  ref="${ref#library/}"
  # A tag is a colon in the LAST path segment; a colon earlier is a registry port, not a tag.
  local last="${ref##*/}"
  if [[ "$last" != *:* && -z "$digest" ]]; then
    ref="${ref}:latest"
  fi
  printf '%s%s' "$ref" "$digest"
}

resolve_group() {
  local cf="$1"
  [[ -n "${GROUP_STATUS[$cf]+set}" ]] && return 0

  local -a files=() fargs=()
  IFS=',' read -ra files <<< "$cf"

  local f
  for f in "${files[@]}"; do
    [[ -z "$f" ]] && continue
    if [[ ! -f "$f" ]]; then
      GROUP_STATUS["$cf"]="missing:$f"
      GROUP_MAP["$cf"]=""
      return 0
    fi
    fargs+=( -f "$f" )
  done

  if [[ ${#fargs[@]} -eq 0 ]]; then
    GROUP_STATUS["$cf"]="failed"
    GROUP_MAP["$cf"]=""
    return 0
  fi

  local json="" map=""
  if ! json=$(timeout "$DRIFT_COMPOSE_TIMEOUT" docker compose "${fargs[@]}" config --format json 2>/dev/null); then
    GROUP_STATUS["$cf"]="failed"
    GROUP_MAP["$cf"]=""
    return 0
  fi
  if ! map=$(printf '%s' "$json" | jq -r '.services | to_entries[] | "\(.key)\t\(.value.image // "")"' 2>/dev/null); then
    GROUP_STATUS["$cf"]="failed"
    GROUP_MAP["$cf"]=""
    return 0
  fi
  GROUP_STATUS["$cf"]="ok"
  GROUP_MAP["$cf"]="$map"
}

MEASURED=0
if [[ $DOCKER_OK -eq 1 && $REPO_OK -eq 1 ]]; then
  # One inspect pass over ALL containers. `-a` on purpose: `created` containers do not appear in a
  # bare `docker ps`, and that blind spot once hid two down containers for six weeks. Drift is
  # classified for RUNNING containers only; the tallies below need the whole set.
  SEP='|:|'
  FMT="{{.Name}}${SEP}{{.State.Status}}${SEP}{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}${SEP}{{.Config.Image}}${SEP}{{index .Config.Labels \"com.docker.compose.service\"}}${SEP}{{index .Config.Labels \"com.docker.compose.project.config_files\"}}"

  IDS=""
  if ! IDS=$(timeout 30 docker ps -aq 2>/dev/null); then
    unknown "'docker ps -aq' exited non-zero — nothing was enumerated."
  elif [[ -z "$IDS" ]]; then
    unknown "'docker ps -aq' returned no containers at all. On this estate that is a broken daemon,"
    echo "         not an empty host — it is 'could not look', never 'nothing is wrong'."
  else
    INSPECT_OUT=""
    # shellcheck disable=SC2086
    if ! INSPECT_OUT=$(timeout 60 docker inspect --format "$FMT" $IDS 2>/dev/null); then
      unknown "'docker inspect' over the container set exited non-zero — nothing was classified."
    else
      MEASURED=1
      UNHEALTHY_COUNT=0
      CREATED_COUNT=0
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        name="${line%%"$SEP"*}"; rest="${line#*"$SEP"}"
        state="${rest%%"$SEP"*}"; rest="${rest#*"$SEP"}"
        health="${rest%%"$SEP"*}"; rest="${rest#*"$SEP"}"
        running_ref="${rest%%"$SEP"*}"; rest="${rest#*"$SEP"}"
        service="${rest%%"$SEP"*}"; config_files="${rest#*"$SEP"}"
        name="${name#/}"

        [[ "$health" == "unhealthy" ]] && UNHEALTHY_COUNT=$((UNHEALTHY_COUNT + 1))
        [[ "$state" == "created" ]] && CREATED_COUNT=$((CREATED_COUNT + 1))

        [[ "$state" != "running" ]] && continue

        if [[ -z "$config_files" || -z "$service" ]]; then
          UNRESOLVABLE_COUNT=$((UNRESOLVABLE_COUNT + 1))
          UNRESOLVABLE_NAMES+=( "$name" )
          UNRESOLVABLE_LINES+=( "$name  reason=no-compose-label  running=$running_ref" )
          continue
        fi

        resolve_group "$config_files"
        status="${GROUP_STATUS[$config_files]}"
        if [[ "$status" == missing:* ]]; then
          UNRESOLVABLE_COUNT=$((UNRESOLVABLE_COUNT + 1))
          UNRESOLVABLE_NAMES+=( "$name" )
          UNRESOLVABLE_LINES+=( "$name  reason=compose-file-missing (${status#missing:})  running=$running_ref" )
          continue
        fi
        if [[ "$status" != "ok" ]]; then
          UNRESOLVABLE_COUNT=$((UNRESOLVABLE_COUNT + 1))
          UNRESOLVABLE_NAMES+=( "$name" )
          UNRESOLVABLE_LINES+=( "$name  reason=compose-config-failed ($config_files)  running=$running_ref" )
          continue
        fi

        declared=""
        declared=$(printf '%s\n' "${GROUP_MAP[$config_files]}" \
                   | awk -F'\t' -v s="$service" '$1 == s {print $2; exit}') || declared=""
        if [[ -z "$declared" ]]; then
          UNRESOLVABLE_COUNT=$((UNRESOLVABLE_COUNT + 1))
          UNRESOLVABLE_NAMES+=( "$name" )
          UNRESOLVABLE_LINES+=( "$name  reason=service-absent-or-empty-image (service=$service)  running=$running_ref" )
          continue
        fi

        rn="$(normalise_ref "$running_ref")"
        dn="$(normalise_ref "$declared")"
        if [[ "$rn" == "$dn" ]]; then
          OK_COUNT=$((OK_COUNT + 1))
        elif [[ "$rn" == *"@sha256:"* || "$dn" == *"@sha256:"* ]]; then
          DIGEST_PINNED_COUNT=$((DIGEST_PINNED_COUNT + 1))
          DIGEST_LINES+=( "$name  running=$running_ref  declared=$declared" )
        else
          DRIFT_COUNT=$((DRIFT_COUNT + 1))
          DRIFT_LINES+=( "$name  $rn -> $dn" )
        fi
      done <<< "$INSPECT_OUT"
    fi
  fi
fi

if [[ $MEASURED -eq 0 ]]; then
  warn "not measured — see the could-not-look above. This is UNKNOWN, not '0 drifted'."
elif [[ ${#DRIFT_LINES[@]} -eq 0 ]]; then
  pass "no running container is on a tag git no longer pins"
else
  # One line per drifted container. The literal token below is the anchor a reader (and the
  # verification transcript) greps for; it appears exactly once per drifted container and nowhere
  # else in this script's output.
  for l in "${DRIFT_LINES[@]}"; do
    echo -e "  ${RED}IMAGE_DRIFT${NC}  $l"
  done
  warn "$DRIFT_COUNT container(s) drifted. REPORTED, not asserted — v1 is alert-only (D-01) and"
  echo "         nothing here deploys. Merging a Renovate PR changes git only; the host still runs"
  echo "         the old image until someone pulls and recreates. See DEPLOYMENT.md § 5."
fi

if [[ ${#DIGEST_LINES[@]} -gt 0 ]]; then
  echo ""
  info "digest-pinned mismatches (REPORTED, never counted as drift — see NORMALISATION):"
  for l in "${DIGEST_LINES[@]}"; do echo "    DIGEST_PINNED  $l"; done
fi
echo ""

# =============================================================================================
# 2. Unresolvable — a counted outcome of a SUCCESSFUL run, and the count IS asserted
# =============================================================================================
echo "🕳  2. Unresolvable pins"
rule
if [[ $MEASURED -eq 0 ]]; then
  warn "not measured — UNKNOWN, not 0"
else
  if [[ ${#UNRESOLVABLE_LINES[@]} -gt 0 ]]; then
    for l in "${UNRESOLVABLE_LINES[@]}"; do echo "    UNRESOLVABLE  $l"; done
  fi
  GOT_NAMES="$(printf '%s\n' "${UNRESOLVABLE_NAMES[@]+"${UNRESOLVABLE_NAMES[@]}"}" | grep -v '^$' | sort | tr '\n' ' ' | sed 's/ $//')"
  WANT_NAMES="$(printf '%s\n' $DRIFT_EXPECT_UNRESOLVABLE_NAMES | grep -v '^$' | sort | tr '\n' ' ' | sed 's/ $//')"
  if [[ "$UNRESOLVABLE_COUNT" -eq "$DRIFT_EXPECT_UNRESOLVABLE" ]]; then
    pass "unresolvable count $UNRESOLVABLE_COUNT == expected $DRIFT_EXPECT_UNRESOLVABLE"
  else
    fail "unresolvable count $UNRESOLVABLE_COUNT != expected $DRIFT_EXPECT_UNRESOLVABLE — a NEW"
    echo "         unresolvable container means a new stale compose project, or a compose file this"
    echo "         repo no longer carries. Found: [${GOT_NAMES:-none}]"
  fi
  if [[ "$GOT_NAMES" == "$WANT_NAMES" ]]; then
    pass "unresolvable name set matches DRIFT_EXPECT_UNRESOLVABLE_NAMES [$WANT_NAMES]"
  else
    fail "unresolvable name set moved — found [${GOT_NAMES:-none}], expected [$WANT_NAMES]."
    echo "         The count alone would not catch a SWAP, which is why the set is asserted too."
  fi
fi
echo ""

# =============================================================================================
# 3. Container state — the `created` blind spot, and unhealthy
# =============================================================================================
echo "🩺 3. Container state"
rule
if [[ $MEASURED -eq 0 ]]; then
  warn "not measured — unhealthy and created counts are UNKNOWN, not 0"
else
  if [[ "$UNHEALTHY_COUNT" -eq 0 ]]; then
    pass "no container reports health status 'unhealthy'"
  else
    warn "$UNHEALTHY_COUNT container(s) report 'unhealthy' (REPORTED here; the Grafana rule alerts)"
  fi
  if [[ "$CREATED_COUNT" -eq 0 ]]; then
    pass "no container is stuck in state 'created'"
  else
    warn "$CREATED_COUNT container(s) in state 'created' — the documented estate BLIND SPOT:"
    echo "         --filter status=restarting|dead|exited MISSES 'created', and that once hid"
    echo "         dispatcharr and teleport down for six weeks under a clean-looking estate."
  fi
fi
echo ""

# =============================================================================================
# 4. Repo freshness — REPORTED, and a LOWER BOUND without a fetch
# =============================================================================================
echo "🌱 4. Repo freshness (REPORTED, lower bound — see KNOWN LIMITS)"
rule
if [[ $REPO_OK -eq 1 ]]; then
  if [[ "$DRIFT_GIT_FETCH" == "1" ]]; then
    if timeout 60 git -C "$DRIFT_REPO" fetch --quiet origin 2>/dev/null; then
      info "DRIFT_GIT_FETCH=1 — fetched origin before counting"
    else
      warn "DRIFT_GIT_FETCH=1 but the fetch failed; the count below is still a lower bound"
    fi
  fi
  if CB=$(timeout 30 git -C "$DRIFT_REPO" rev-list --count HEAD..origin/main 2>/dev/null); then
    COMMITS_BEHIND="$CB"
    info "commits behind origin/main: $COMMITS_BEHIND  (LOWER BOUND — DRIFT_GIT_FETCH=$DRIFT_GIT_FETCH;"
    echo "         with no fetch this uses the last-fetched ref, so the true figure can be larger)"
  else
    warn "could not count commits behind origin/main (no such ref?) — REPORTED as UNKNOWN"
  fi
else
  warn "repo absent — commits behind is UNKNOWN"
fi
echo ""

# =============================================================================================
# 5. --prom: the node-exporter textfile
#
# THE TIMESTAMP GAUGE IS THE FAIL-CLOSED LEVER AND IS TREATED AS ONE. It is written ONLY on a
# successful measurement. On a could-not-look the existing file is left COMPLETELY UNTOUCHED - no
# partial write, no fresh timestamp - so it goes STALE and the Grafana staleness rule fires. A
# half-written file would also break node-exporter's parse of the whole directory, so the write is
# atomic: a temp file in the SAME directory whose name does NOT end in `.prom` (node-exporter globs
# `*.prom` continuously and would happily parse a half-written one), then `mv` into place.
# =============================================================================================
prom_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

if [[ $PROM_MODE -eq 1 ]]; then
  echo "📈 5. node-exporter textfile"
  rule
  if [[ $MEASURED -eq 0 || $PROM_DIR_OK -eq 0 || $UNKNOWNS -gt 0 ]]; then
    warn "NOT WRITING $DRIFT_PROM_DIR/$DRIFT_PROM_FILE — the measurement did not succeed."
    echo "         Any existing file is left byte-identical so it goes stale and the staleness"
    echo "         alert fires. 'last_success' must never mean 'the run failed but recently'."
  else
    TMP="$DRIFT_PROM_DIR/.${DRIFT_PROM_FILE}.tmp.$$"
    {
      echo "# HELP selfhost_image_drift_containers Running containers whose image tag differs from the pin in git."
      echo "# TYPE selfhost_image_drift_containers gauge"
      echo "selfhost_image_drift_containers $DRIFT_COUNT"
      echo "# HELP selfhost_image_drift_unresolvable_containers Running containers whose declared pin cannot be resolved from the repo."
      echo "# TYPE selfhost_image_drift_unresolvable_containers gauge"
      echo "selfhost_image_drift_unresolvable_containers $UNRESOLVABLE_COUNT"
      echo "# HELP selfhost_image_drift_container One series per drifted container, labelled with the running and declared references."
      echo "# TYPE selfhost_image_drift_container gauge"
      for l in "${DRIFT_LINES[@]+"${DRIFT_LINES[@]}"}"; do
        dn="${l##* -> }"
        head="${l%% -> *}"
        rn="${head##*  }"
        nm="${head%%  *}"
        printf 'selfhost_image_drift_container{name="%s",running="%s",declared="%s"} 1\n' \
          "$(prom_escape "$nm")" "$(prom_escape "$rn")" "$(prom_escape "$dn")"
      done
      echo "# HELP selfhost_containers_unhealthy Containers reporting docker health status 'unhealthy'."
      echo "# TYPE selfhost_containers_unhealthy gauge"
      echo "selfhost_containers_unhealthy $UNHEALTHY_COUNT"
      echo "# HELP selfhost_containers_created Containers stuck in state 'created' (the documented blind spot)."
      echo "# TYPE selfhost_containers_created gauge"
      echo "selfhost_containers_created $CREATED_COUNT"
      echo "# HELP selfhost_repo_commits_behind_origin Commits the host checkout is behind origin/main. LOWER BOUND without a fetch."
      echo "# TYPE selfhost_repo_commits_behind_origin gauge"
      if [[ "$COMMITS_BEHIND" != "UNKNOWN" ]]; then
        echo "selfhost_repo_commits_behind_origin $COMMITS_BEHIND"
      fi
      echo "# HELP selfhost_image_drift_last_success_timestamp_seconds Unix time of the last SUCCESSFUL measurement. It does NOT mean there is no drift."
      echo "# TYPE selfhost_image_drift_last_success_timestamp_seconds gauge"
      echo "selfhost_image_drift_last_success_timestamp_seconds $(date +%s)"
    } > "$TMP"
    chmod 0644 "$TMP"
    mv -f "$TMP" "$DRIFT_PROM_DIR/$DRIFT_PROM_FILE"
    pass "wrote $DRIFT_PROM_DIR/$DRIFT_PROM_FILE atomically (temp name does not end in .prom)"
  fi
  echo ""
fi

# =============================================================================================
# 6. Summary
#
# CROSS-FILE CONTRACT with scripts/quick-health-check.sh. That file anchors on the LITERAL heading
# `📊 Summary` below and selects these tokens:
#     image drift | unresolvable | unhealthy | created | commits behind | could-not-look |
#     FAILURES total
# Renaming a label or the heading breaks a consumer that lives in a DIFFERENT FILE, and it breaks
# it SILENTLY — a grep that selects nothing looks exactly like a check with nothing to report. The
# fold-in has its own guard for that (empty selection => UNKNOWN => exit 1), but the guard tells you
# the heading moved; it cannot tell you which label.
#
# THE SPLIT THE FOLD-IN DEPENDS ON: `FAILURES total` counts ONLY fatal findings (failed assertions
# and could-not-looks). `image drift` is REPORTED and is NOT in that total. A non-zero exit with
# `FAILURES total: 0` and `could-not-look: 0` therefore means "drift exists, nothing is broken".
#
# KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT SILENTLY.
# =============================================================================================
echo "📊 Summary"
rule
# "0 drifted" on a run that could not look is precisely the false green this whole file exists to
# refuse, and it is the shape check-jellyfin-transcode.sh's ENC_ASSERTED discriminator was added to
# stop. MEASURED is the discriminator here: it records whether the classification pass RAN, not
# whether it found anything. An unmeasured run prints UNKNOWN on all four counters, never a tally.
if [[ $MEASURED -eq 0 ]]; then
  echo "  image drift:        UNKNOWN — the classification pass never ran (see could-not-look below)"
  echo "  unresolvable:       UNKNOWN  (expected $DRIFT_EXPECT_UNRESOLVABLE)"
  echo "  digest-pinned:      UNKNOWN"
  echo "  matching:           UNKNOWN"
else
echo "  image drift:        $DRIFT_COUNT  (REPORTED, not asserted — v1 is ALERT-ONLY, D-01)"
echo "  unresolvable:       $UNRESOLVABLE_COUNT  (ASSERTED; expected $DRIFT_EXPECT_UNRESOLVABLE)"
echo "  digest-pinned:      $DIGEST_PINNED_COUNT  (reported; never counted as drift)"
echo "  matching:           $OK_COUNT"
fi
echo "  unhealthy:          $UNHEALTHY_COUNT"
echo "  created:            $CREATED_COUNT"
echo "  commits behind:     $COMMITS_BEHIND  (LOWER BOUND — DRIFT_GIT_FETCH=$DRIFT_GIT_FETCH)"
echo "  could-not-look:     $UNKNOWNS"
echo "  FAILURES total:     $FAILURES  (fatal findings only — image drift is NOT in this total)"
echo ""

if [[ $PROM_MODE -eq 1 ]]; then
  # --prom: 0 on a successful measurement REGARDLESS of drift. The metric is the signal; a systemd
  # unit parked in `failed` for standing drift would make a real could-not-look invisible.
  if [[ $UNKNOWNS -gt 0 || $MEASURED -eq 0 || $PROM_DIR_OK -eq 0 ]]; then
    echo -e "${RED}❌ could not measure — nothing written, the metric will go stale on purpose${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ measurement written ($DRIFT_COUNT drifted; the gauge, not this exit code, is the signal)${NC}"
  exit 0
fi

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}❌ $FAILURES fatal finding(s)${NC}"
  exit 1
fi
if [[ $DRIFT_COUNT -gt 0 ]]; then
  echo -e "${YELLOW}❌ $DRIFT_COUNT container(s) on an image git no longer pins (nothing is broken — see DEPLOYMENT.md § 5)${NC}"
  exit 1
fi
echo -e "${GREEN}✅ every running container matches its pin in git${NC}"
