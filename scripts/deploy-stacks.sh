#!/usr/bin/env bash
# deploy-stacks.sh - Git-driven deploy agent for LXC 100: pull + recreate ONLY the services whose
#                    running image tag git no longer pins. DRY-RUN BY DEFAULT.
# Usage: bash scripts/deploy-stacks.sh [--apply] [--stack NAME] [-h|--help]
#
# WHAT IT IS. The APPLY half that scripts/check-drift.sh (D-01) deliberately left unwritten.
#   Drift is the trigger: this script RUNS check-drift.sh in report mode and consumes its
#   `IMAGE_DRIFT` lines and its `📊 Summary` block. It never re-implements the classifier, so the
#   two can never disagree about what is drifted. Runbook: stacks/selfhosted/monitoring/README.md
#   § Deploy agent. Written after 2026-10-21, when the host was 101 commits behind, ~40 containers
#   had drifted, and a batch pull hit ENOSPC on the 126G rootfs because nothing pruned old images.
#
# WHERE IT RUNS: ON LXC 100 (root@172.16.1.159), against the checkout at /mnt/fast/stacks. It
#   needs bash >= 4 and GNU df; both guards below exit 2 (environment, not a failed assertion).
#     ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/deploy-stacks.sh'
#
# MODES.
#   (default)      DRY-RUN. Fetches refs (never the working tree), reports what a pull would bring,
#                  lists every drifted container as WOULD-DEPLOY / pending (held: <reason>) /
#                  QUIET-DEFERRED, and pulls, recreates and prunes NOTHING.
#   --apply        `git pull --ff-only`, then per compose project: disk guard, `pull` + `up -d
#                  --no-deps` of the drifted services only, `docker image prune -af`, and finally
#                  re-verify with check-drift.sh. There is NO environment variable that turns apply
#                  on; the systemd drop-in scripts/systemd/selfhost-deploy-apply.conf passes this
#                  flag and is the one explicit enable step.
#   --stack NAME   Restrict to one compose project (the `com.docker.compose.project` label).
#
# EXIT CODES (D-G).
#   0  run completed with no failure. A DRY-RUN WITH PENDING DRIFT IS 0: the metric is the signal.
#   1  any counted failure, or a could-not-look (classifier red, docker down, unknown hold name).
#   2  usage / environment: bash < 4, non-GNU df, unknown flag, unknown --stack, malformed knob.
#   3  REFUSED: the checkout is dirty or HEAD is not an ancestor of origin/main. The drift report
#      still prints; nothing deploys. The agent NEVER stashes, resets, checks out or overwrites -
#      the host has carried uncommitted production edits before. A human commits or discards.
#   4  another run holds the lock (/run/selfhost-deploy.lock). Nothing measured, nothing written.
#
# ENV KNOBS - every one may only make the agent MORE conservative (CONVENTIONS rule 4):
#   DEPLOY_HOLD_EXTRA           names ADDED to the hold list. Nothing can remove a built-in hold;
#                               that is a code change, reviewed in git, by design.
#   DEPLOY_MEDIA_EXTRA          names ADDED to the media quiet-window class.
#   DEPLOY_MEDIA_WINDOW         default 03-06: local hours, start inclusive, end exclusive.
#   DEPLOY_DISK_HEADROOM_BYTES  default 10 GiB on top of the 20 GiB D-17 floor. A LOWER value is
#                               ignored with a warning; only a stricter guard is honoured.
#   DEPLOY_PROM_DIR             textfile directory; exists to point test runs at a scratch dir.
#
# HOLD LIST POLICY. Stateful or procedure-bound services are never deployed by a timer. Their drift
#   prints `pending (held: <reason>)` and is cleared only by a human following the procedure. Every
#   hold name must resolve to a container on the host OR a `container_name:` declared in the repo
#   (beets is `run --rm` only); a hold that matches neither is FATAL - a renamed container would
#   otherwise be deployed straight past its hold.
#
# KNOWN LIMITS.
#   1. Drift is measured against the checkout's HEAD. In dry-run, when the host is behind, apply can
#      deploy MORE than the dry-run listed; the dry-run prints the compose files a pull would change.
#   2. Floating tags and digest-pinned mismatches are never deployed: check-drift.sh does not call
#      them IMAGE_DRIFT.
#   3. A red check-drift.sh (e.g. a new unresolvable container) blocks every deploy. Fail closed.
#   4. `docker image prune -af` removes the PREVIOUS image of anything just upgraded. Rollback is a
#      `git revert` of the bump on main; the next apply run then deploys the old tag as drift.
#   5. A manual `--stack` run writes deploy.prom with that subset's counts; the next timer run
#      overwrites it.
#
# SECRETS. No credential reaches argv. Registry auth stays in docker's credential store, `.env`
#   files are never read, and no remote URL is ever printed (`git fetch`/`pull` stderr is dropped
#   because an https remote can embed a token).

# --- shell/platform guards (exit 2 - environment error, not a failed assertion) -----------------
if [[ -z "${BASH_VERSINFO:-}" || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo "deploy-stacks.sh requires bash >= 4 (associative arrays); this is bash ${BASH_VERSION:-unknown}." >&2
  echo "It runs ON LXC 100, not on the macOS workstation:" >&2
  echo "  ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/deploy-stacks.sh'" >&2
  exit 2
fi
if ! [[ "$(df -B1 --output=avail / 2>/dev/null | tail -1 | tr -d ' ')" =~ ^[0-9]+$ ]]; then
  echo "deploy-stacks.sh requires GNU df ('df -B1 --output=avail'); BSD df would turn the disk" >&2
  echo "guard into a wrong number rather than an error. Run it ON LXC 100." >&2
  exit 2
fi

set -euo pipefail

main() {
  # The whole body lives in main(), invoked by the LAST line, and stdin is closed first. Two reasons:
  # apply mode `git pull`s the checkout this very file lives in, and bash reads a script
  # incrementally - a file rewritten under a running bash executes a splice of two versions. And
  # under `ssh ... 'bash -s' < script`, any child that reads stdin would eat the rest of the script.
  exec </dev/null

  # ===============================================================================================
  # Constants - one place
  # ===============================================================================================
  local DEPLOY_REPO=/mnt/fast/stacks
  local PROM_DIR_DEFAULT=/mnt/fast/appdata/monitoring/node-exporter-textfile
  local DEPLOY_PROM_DIR="${DEPLOY_PROM_DIR:-$PROM_DIR_DEFAULT}"
  local PROM_FILE=deploy.prom
  # D-17 floor, duplicated ON PURPOSE from scripts/check-jellyfin-transcode.sh (a constant here,
  # not a sourced file). Change both or neither.
  local FLOOR_BYTES=21474836480
  local HEADROOM_DEFAULT=10737418240
  local DEPLOY_DISK_HEADROOM_BYTES="${DEPLOY_DISK_HEADROOM_BYTES:-$HEADROOM_DEFAULT}"
  local T_GIT=120 T_CLASSIFY=300 T_PULL=900 T_UP=300 T_PRUNE=300 T_POST=300 T_INSPECT=60
  # D-E: stop STARTING stacks after 20 min. Worst stack = 900+300+300 s = 25 min, post-checks
  # <= 15 min, so a run fits the service's TimeoutStartSec=60min. That cap is one term of the
  # 7500 s staleness threshold in rules.yaml - see scripts/systemd/selfhost-deploy.timer.
  local RUN_BUDGET_SECONDS=1200
  local LOCK_FILE=/run/selfhost-deploy.lock
  local DEPLOY_MEDIA_WINDOW="${DEPLOY_MEDIA_WINDOW:-03-06}"
  local DEPLOY_HOLD_EXTRA="${DEPLOY_HOLD_EXTRA:-}"
  local DEPLOY_MEDIA_EXTRA="${DEPLOY_MEDIA_EXTRA:-}"

  # L-03. `name|reason`. There is deliberately NO knob that removes an entry: DEPLOY_HOLD_EXTRA only
  # adds. immich_kiosk is deliberately NOT held (stateless; expected to deploy).
  local -a DEPLOY_HOLD=(
    "jellyfin|major-upgrade procedure; HW transcode stays OFF (D-30); Renovate manual-review"
    "immich_server|Immich upgrade procedure — server/ml/postgres/redis move together"
    "immich_machine_learning|Immich upgrade procedure — server/ml/postgres/redis move together"
    "immich_postgres|Immich upgrade procedure — server/ml/postgres/redis move together"
    "immich_redis|Immich upgrade procedure — server/ml/postgres/redis move together"
    "karakeep-meilisearch|Meilisearch dump/upgrade procedure; never a bare image bump"
    "couchdb|Obsidian LiveSync replicates live; Renovate manual-review — deploy by hand, check _up and doc_count"
    "neocortex-memory-api|Node bump needs 'docker compose run --rm deps' then /v1/health"
    "beets|music project #305 — manual; Renovate manual-review"
    "beets-flask|music project #305 — manual; Renovate manual-review"
  )
  # L-04. Deployed only inside DEPLOY_MEDIA_WINDOW; jellyfin itself is held outright.
  local -a DEPLOY_MEDIA=( dispatcharr seerr audiobookshelf wizarr jellystat jellystat-db )

  local RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

  local FAILURES=0 UNKNOWNS=0 FAILED_STACKS=0 DEPLOYED=0 WOULD_DEPLOY=0 HELD=0 QUIET=0
  local BUDGET_DEFERRED=0 GUARD_DEFERRED=0 DISK_TRIPPED=0 REFUSED=0 COMMITS_BEHIND=UNKNOWN
  local -a REFUSED_REASONS=() HELD_SERIES=()

  fail()    { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
  unknown() { echo -e "  ${YELLOW}⚠️  UNKNOWN — $*${NC}"; UNKNOWNS=$((UNKNOWNS + 1)); FAILURES=$((FAILURES + 1)); }
  pass()    { echo -e "  ${GREEN}✅ $*${NC}"; }
  warn()    { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
  info()    { echo -e "  ${BLUE}$*${NC}"; }
  rule()    { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
  usage()   { echo "usage: bash scripts/deploy-stacks.sh [--apply] [--stack NAME] [-h|--help]" >&2; }
  gib()     { [[ -n "${1:-}" ]] && awk -v b="$1" 'BEGIN{printf "%.2f", b/1073741824}' || printf 'UNKNOWN'; }
  prom_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
  strip_ansi()  { sed 's/\x1b\[[0-9;]*m//g'; }

  # ===============================================================================================
  # Arguments and knob validation (exit 2)
  # ===============================================================================================
  local APPLY=0 STACK=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) APPLY=1 ;;
      --stack)
        [[ $# -ge 2 && -n "$2" ]] || { echo "--stack needs a NAME" >&2; usage; exit 2; }
        STACK="$2"; shift ;;
      -h|--help) grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) echo "unknown option: $1" >&2; usage; exit 2 ;;
    esac
    shift
  done

  local W_START W_END
  if [[ ! "$DEPLOY_MEDIA_WINDOW" =~ ^([0-9]{2})-([0-9]{2})$ ]]; then
    echo "DEPLOY_MEDIA_WINDOW='$DEPLOY_MEDIA_WINDOW' is not HH-HH" >&2; exit 2
  fi
  W_START=$((10#${BASH_REMATCH[1]})); W_END=$((10#${BASH_REMATCH[2]}))
  if (( W_START >= W_END || W_END > 24 )); then
    echo "DEPLOY_MEDIA_WINDOW='$DEPLOY_MEDIA_WINDOW' needs start < end <= 24" >&2; exit 2
  fi
  local HOUR IN_WINDOW=0
  HOUR=$((10#$(date +%H)))      # 10# - "08" and "09" are invalid octal
  (( HOUR >= W_START && HOUR < W_END )) && IN_WINDOW=1

  if [[ ! "$DEPLOY_DISK_HEADROOM_BYTES" =~ ^[0-9]+$ ]]; then
    echo "DEPLOY_DISK_HEADROOM_BYTES='$DEPLOY_DISK_HEADROOM_BYTES' is not a byte count" >&2; exit 2
  fi
  local HEADROOM="$HEADROOM_DEFAULT" HEADROOM_IGNORED=0
  if (( DEPLOY_DISK_HEADROOM_BYTES >= HEADROOM_DEFAULT )); then
    HEADROOM="$DEPLOY_DISK_HEADROOM_BYTES"
  else
    HEADROOM_IGNORED=1
  fi
  local REQUIRED=$((FLOOR_BYTES + HEADROOM))

  local -A HOLD_REASON=() IS_MEDIA=() HOLD_IS_EXTRA=()
  local entry n
  for entry in "${DEPLOY_HOLD[@]}"; do HOLD_REASON["${entry%%|*}"]="${entry#*|}"; done
  local -a extra=()
  read -ra extra <<< "${DEPLOY_HOLD_EXTRA//,/ }"
  for n in "${extra[@]+"${extra[@]}"}"; do
    [[ "$n" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "DEPLOY_HOLD_EXTRA name '$n' is malformed" >&2; exit 2; }
    [[ -n "${HOLD_REASON[$n]+set}" ]] || { HOLD_REASON["$n"]="operator hold (DEPLOY_HOLD_EXTRA)"; HOLD_IS_EXTRA["$n"]=1; }
  done
  read -ra extra <<< "${DEPLOY_MEDIA_EXTRA//,/ }"
  for n in "${DEPLOY_MEDIA[@]}" "${extra[@]+"${extra[@]}"}"; do
    [[ "$n" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "DEPLOY_MEDIA_EXTRA name '$n' is malformed" >&2; exit 2; }
    IS_MEDIA["$n"]=1
  done

  # ===============================================================================================
  # Banner
  # ===============================================================================================
  echo "🚚 Deploy agent (git-driven; image drift is the trigger)"
  rule
  if [[ $APPLY -eq 1 ]]; then
    echo "  mode:        APPLY (pulls, recreates and prunes)"
  else
    echo "  mode:        DRY-RUN (pulls, recreates and prunes NOTHING; --apply to act)"
  fi
  echo "  host:        $(hostname)"
  echo "  local time:  $(date '+%Y-%m-%dT%H:%M:%S') $(date +%Z)"
  if [[ $IN_WINDOW -eq 1 ]]; then
    echo "  media window: $DEPLOY_MEDIA_WINDOW (local) — INSIDE: media-class drift may deploy"
  else
    echo "  media window: $DEPLOY_MEDIA_WINDOW (local) — OUTSIDE: media-class drift is QUIET-DEFERRED"
  fi
  echo "  repo:        $DEPLOY_REPO"
  [[ -n "$STACK" ]] && echo "  stack:       $STACK (only this compose project)"
  [[ "$DEPLOY_PROM_DIR" != "$PROM_DIR_DEFAULT" ]] && warn "override in effect: DEPLOY_PROM_DIR=$DEPLOY_PROM_DIR"
  [[ -n "$DEPLOY_HOLD_EXTRA" ]] && warn "override in effect: DEPLOY_HOLD_EXTRA=$DEPLOY_HOLD_EXTRA (adds holds)"
  [[ -n "$DEPLOY_MEDIA_EXTRA" ]] && warn "override in effect: DEPLOY_MEDIA_EXTRA=$DEPLOY_MEDIA_EXTRA (adds media class)"
  [[ "$DEPLOY_MEDIA_WINDOW" != "03-06" ]] && warn "override in effect: DEPLOY_MEDIA_WINDOW=$DEPLOY_MEDIA_WINDOW"
  if [[ $HEADROOM_IGNORED -eq 1 ]]; then
    warn "DEPLOY_DISK_HEADROOM_BYTES=$DEPLOY_DISK_HEADROOM_BYTES is LOWER than the default and is IGNORED —"
    echo "         this knob may only make the guard stricter. Using $HEADROOM_DEFAULT."
  elif (( HEADROOM != HEADROOM_DEFAULT )); then
    warn "override in effect: DEPLOY_DISK_HEADROOM_BYTES=$HEADROOM (stricter)"
  fi
  echo "  disk guard:  required free $REQUIRED bytes ($(gib "$REQUIRED") GiB) = D-17 floor 20 GiB + headroom $(gib "$HEADROOM") GiB"
  echo ""

  # ===============================================================================================
  # Lock - one run at a time (exit 4, nothing written)
  # ===============================================================================================
  if ! command -v flock >/dev/null 2>&1; then
    echo -e "${RED}❌ flock NOT FOUND — cannot serialise runs; refusing to run unlocked${NC}" >&2
    exit 1
  fi
  if ! { exec 9>>"$LOCK_FILE"; } 2>/dev/null; then
    echo -e "${RED}❌ cannot open $LOCK_FILE — cannot serialise runs; refusing to run unlocked${NC}" >&2
    exit 1
  fi
  if ! flock -n 9; then
    echo -e "${YELLOW}⏳ another deploy run holds $LOCK_FILE — exiting 4, nothing measured or written${NC}"
    exit 4
  fi

  # Summary + exit, shared by every path below. Never writes the metric itself.
  print_summary() {
    echo "📊 Summary"
    rule
    # No other file folds this block in today, so the heading is not yet a cross-file anchor. Keep
    # it literal anyway (CONVENTIONS rule 11) in case one ever does.
    echo "  mode:               $([[ $APPLY -eq 1 ]] && echo APPLY || echo DRY-RUN)"
    echo "  deployed:           $DEPLOYED"
    echo "  would-deploy:       $WOULD_DEPLOY"
    echo "  held:               $HELD"
    echo "  quiet-deferred:     $QUIET"
    echo "  budget-deferred:    $BUDGET_DEFERRED"
    echo "  guard-deferred:     $GUARD_DEFERRED"
    echo "  failed stacks:      $FAILED_STACKS"
    echo "  disk guard tripped: $DISK_TRIPPED"
    echo "  refused:            $REFUSED${REFUSED_REASONS[*]:+ (${REFUSED_REASONS[*]})}"
    echo "  commits behind:     $COMMITS_BEHIND"
    echo "  could-not-look:     $UNKNOWNS"
    echo "  FAILURES total:     $FAILURES"
    echo ""
  }
  finish() {
    print_summary
    if [[ $UNKNOWNS -gt 0 ]]; then
      echo -e "${RED}❌ could not look — nothing actionable; deploy.prom left untouched so it goes stale${NC}"; exit 1
    fi
    if [[ $REFUSED -eq 1 ]]; then
      echo -e "${RED}⛔ REFUSED (${REFUSED_REASONS[*]}) — nothing deployed. A human resolves the checkout: commit or discard the edit, reconcile local commits.${NC}"; exit 3
    fi
    if [[ $FAILURES -gt 0 ]]; then
      echo -e "${RED}❌ $FAILURES failure(s)${NC}"; exit 1
    fi
    echo -e "${GREEN}✅ run complete ($([[ $APPLY -eq 1 ]] && echo "$DEPLOYED deployed" || echo "$WOULD_DEPLOY would deploy"); pending drift is reported by the metric, not this exit code)${NC}"
    exit 0
  }

  # ===============================================================================================
  # 0. Routes and preconditions - every miss is a COULD-NOT-LOOK
  # ===============================================================================================
  echo "🧰 0. Routes and preconditions"
  rule
  local t
  for t in docker git jq timeout flock df awk sed sort; do
    if command -v "$t" >/dev/null 2>&1; then pass "$t $(command -v "$t")"; else unknown "$t NOT FOUND"; fi
  done
  local PS_OUT="" DOCKER_ROOT=""
  if command -v docker >/dev/null 2>&1 && timeout 30 docker ps -q >/dev/null 2>&1 \
     && PS_OUT=$(timeout 30 docker ps -a --format '{{.Names}}	{{.Label "com.docker.compose.project"}}' 2>/dev/null); then
    pass "docker daemon answers"
    DOCKER_ROOT=$(timeout 30 docker info --format '{{.DockerRootDir}}' 2>/dev/null) || DOCKER_ROOT=""
    if [[ -d "$DOCKER_ROOT" ]]; then pass "DockerRootDir $DOCKER_ROOT"; else unknown "DockerRootDir not readable from 'docker info'"; fi
  else
    unknown "docker daemon unreachable — nothing below can be measured"
  fi
  if [[ -d "$DEPLOY_REPO/.git" && -f "$DEPLOY_REPO/scripts/check-drift.sh" ]]; then
    pass "checkout and scripts/check-drift.sh present at $DEPLOY_REPO"
  else
    unknown "no checkout (or no scripts/check-drift.sh) at $DEPLOY_REPO"
  fi
  if [[ -d "$DEPLOY_PROM_DIR" && -w "$DEPLOY_PROM_DIR" ]]; then
    pass "textfile directory $DEPLOY_PROM_DIR writable"
  else
    unknown "textfile directory $DEPLOY_PROM_DIR absent or not writable"
  fi

  # Hold-name verification. A hold that matches nothing protects nothing — a renamed container
  # would be deployed. A name passes if a container of that name exists, or (built-ins only) the
  # repo declares it as a `container_name:` (beets is `run --rm` only and exists only while used).
  local -A HOST_NAMES=() HOST_PROJECTS=()
  local hn hp
  if [[ -n "$PS_OUT" ]]; then
    while IFS=$'\t' read -r hn hp; do
      [[ -z "$hn" ]] && continue
      HOST_NAMES["$hn"]=1
      [[ -n "$hp" ]] && HOST_PROJECTS["$hp"]=1
    done <<< "$PS_OUT"
    for n in $(printf '%s\n' "${!HOLD_REASON[@]}" | sort); do
      if [[ -n "${HOST_NAMES[$n]+set}" ]]; then
        pass "hold '$n' matches a container"
      elif [[ -z "${HOLD_IS_EXTRA[$n]+set}" ]] && grep -rqsE --include='*.yaml' --include='*.yml' \
           "^[[:space:]]*container_name:[[:space:]]*[\"']?${n//./\\.}[\"']?[[:space:]]*(#.*)?$" "$DEPLOY_REPO/stacks"; then
        info "hold '$n' has no container now but is declared in the repo (container_name) — kept"
      else
        unknown "hold '$n' matches NO container — a hold that matches nothing protects nothing; a"
        echo "         renamed container would be deployed straight past it. Fix the name."
      fi
    done
    for n in $(printf '%s\n' "${!IS_MEDIA[@]}" | sort); do
      [[ -n "${HOST_NAMES[$n]+set}" ]] || warn "media-class name '$n' matches no container (renamed? it would deploy outside the window)"
    done
  fi
  if [[ -n "$STACK" && -n "$PS_OUT" && -z "${HOST_PROJECTS[$STACK]+set}" ]]; then
    echo -e "${RED}❌ --stack '$STACK' is not the compose project of any container on this host${NC}" >&2
    echo "   projects: $(printf '%s\n' "${!HOST_PROJECTS[@]}" | sort | tr '\n' ' ')" >&2
    exit 2
  fi
  echo ""
  [[ $UNKNOWNS -gt 0 ]] && finish

  # ===============================================================================================
  # 1. Checkout gate (L-01) - refuse, never repair
  # ===============================================================================================
  echo "🔒 1. Checkout gate"
  rule
  local porcelain="" line
  if ! porcelain=$(timeout 60 git -C "$DEPLOY_REPO" status --porcelain 2>/dev/null); then
    unknown "'git status' failed on $DEPLOY_REPO"; echo ""; finish
  fi
  if [[ -n "$porcelain" ]]; then
    REFUSED=1; REFUSED_REASONS+=( dirty )
    # Refused is its own outcome (exit 3, its own gauge), not a counted failure.
    echo -e "  ${RED}⛔ checkout is DIRTY — REFUSED. The agent never stashes, resets or overwrites. Paths (first 20):${NC}"
    while IFS= read -r line; do echo "      ${line:3}"; done < <(printf '%s\n' "$porcelain" | head -20)
  else
    pass "working tree clean (git status --porcelain is empty)"
  fi
  # Refs only: the working tree is untouched. stderr dropped - it can carry the remote URL.
  if timeout "$T_GIT" git -C "$DEPLOY_REPO" fetch --quiet origin >/dev/null 2>&1; then
    pass "fetched origin (refs only)"
  else
    unknown "'git fetch origin' failed or timed out — what a pull would bring is unknowable"; echo ""; finish
  fi
  local anc_rc=0
  timeout 30 git -C "$DEPLOY_REPO" merge-base --is-ancestor HEAD origin/main 2>/dev/null || anc_rc=$?
  if [[ $anc_rc -eq 1 ]]; then
    REFUSED=1; REFUSED_REASONS+=( not-fast-forward )
    local lr
    lr=$(timeout 30 git -C "$DEPLOY_REPO" rev-list --left-right --count HEAD...origin/main 2>/dev/null) || lr="? ?"
    echo -e "  ${RED}⛔ HEAD is NOT an ancestor of origin/main — REFUSED (ahead ${lr%%[[:space:]]*}, behind ${lr##*[[:space:]]}).${NC}"
    echo "         Local commits or a diverged history need a human."
  elif [[ $anc_rc -ne 0 ]]; then
    unknown "'git merge-base --is-ancestor' failed (rc=$anc_rc)"; echo ""; finish
  else
    pass "HEAD is an ancestor of origin/main (fast-forwardable)"
  fi
  COMMITS_BEHIND=$(timeout 30 git -C "$DEPLOY_REPO" rev-list --count HEAD..origin/main 2>/dev/null) || COMMITS_BEHIND=UNKNOWN
  info "commits behind origin/main: $COMMITS_BEHIND"
  if [[ $REFUSED -eq 0 && "$COMMITS_BEHIND" =~ ^[0-9]+$ && $COMMITS_BEHIND -gt 0 ]]; then
    if [[ $APPLY -eq 1 ]]; then
      if timeout "$T_GIT" git -C "$DEPLOY_REPO" pull --ff-only --quiet origin main >/dev/null 2>&1; then
        pass "pulled $COMMITS_BEHIND commit(s) (--ff-only); now at $(git -C "$DEPLOY_REPO" rev-parse --short HEAD)"
        COMMITS_BEHIND=$(timeout 30 git -C "$DEPLOY_REPO" rev-list --count HEAD..origin/main 2>/dev/null) || COMMITS_BEHIND=UNKNOWN
      else
        unknown "'git pull --ff-only' failed — deploying NOTHING against a half-known checkout"; echo ""; finish
      fi
    else
      info "a pull would bring (first 50):"
      timeout 30 git -C "$DEPLOY_REPO" log --oneline HEAD..origin/main 2>/dev/null | head -50 | sed 's/^/      /' || true
      info "compose files under stacks/ that change on pull:"
      timeout 30 git -C "$DEPLOY_REPO" diff --name-only HEAD origin/main -- stacks/ 2>/dev/null | sed 's/^/      /' || true
      warn "drift below is measured against HEAD; these files change on pull, so apply may deploy more"
    fi
  fi
  echo ""

  # ===============================================================================================
  # 2. Classify (L-02, D-A) - check-drift.sh IS the classifier; this only consumes its anchors
  # ===============================================================================================
  echo "🔀 2. Classify (via scripts/check-drift.sh, report mode)"
  rule
  local cd_out="" cd_rc=0
  cd_out=$(timeout "$T_CLASSIFY" bash "$DEPLOY_REPO/scripts/check-drift.sh" 2>&1 | strip_ansi) || cd_rc=$?
  # pipefail: cd_rc is check-drift's (or timeout's) status; strip_ansi does not fail.
  # No early `exit` in these awks: under pipefail a reader that quits early can SIGPIPE the writer.
  sum_field() { printf '%s\n' "$cd_out" | awk -v k="  $1:" 'f && !d && index($0,k)==1 {s=substr($0,length(k)+1); split(s,a," "); print a[1]; d=1} $0=="📊 Summary"{f=1}'; }
  local drift_lines s_drift s_cnl s_fail heading=0
  drift_lines=$(printf '%s\n' "$cd_out" | awk '$1=="IMAGE_DRIFT" {print $2"\t"$3"\t"$5}')
  [[ $'\n'"$cd_out"$'\n' == *$'\n📊 Summary\n'* ]] && heading=1
  s_drift=$(sum_field "image drift"); s_cnl=$(sum_field "could-not-look"); s_fail=$(sum_field "FAILURES total")
  local n_lines=0
  [[ -n "$drift_lines" ]] && n_lines=$(printf '%s\n' "$drift_lines" | wc -l | tr -d ' ')
  local cls_ok=0 why=""
  if [[ $heading -eq 0 ]]; then
    why="the '📊 Summary' heading is missing (rc=$cd_rc$([[ $cd_rc -eq 124 ]] && echo ', TIMEOUT'))"
  elif [[ ! "$s_drift" =~ ^[0-9]+$ || "$s_drift" -ne "$n_lines" ]]; then
    why="anchor guard: 'image drift: ${s_drift:-?}' != $n_lines parsed IMAGE_DRIFT line(s)"
  elif [[ $cd_rc -eq 0 && "$s_drift" -eq 0 ]]; then
    cls_ok=1
  elif [[ $cd_rc -eq 1 && "$s_fail" == "0" && "$s_cnl" == "0" && "$s_drift" -gt 0 ]]; then
    cls_ok=1
  else
    why="check-drift.sh is red for a non-drift reason (rc=$cd_rc, FAILURES total=${s_fail:-?}, could-not-look=${s_cnl:-?})"
  fi
  if [[ $cls_ok -eq 0 ]]; then
    unknown "classifier is red — $why"
    printf '%s\n' "$cd_out" | grep -E '❌|UNKNOWN' | head -20 | sed 's/^/      /' || true
    if [[ -n "$drift_lines" ]]; then
      warn "REPORTED ONLY — classifier is red, nothing is actionable:"
      printf '%s\n' "$drift_lines" | awk -F'\t' '{print "      "$1}'
    fi
    echo ""; finish
  fi
  pass "classifier green: $n_lines drifted container(s), rc=$cd_rc, FAILURES total 0, could-not-look 0"

  local -A STACK_SVCS=() STACK_CNAMES=() CNAME_STACK=()
  local nm pj wd cf sv rest f
  if [[ $n_lines -gt 0 ]]; then
    local -a dnames=()
    mapfile -t dnames < <(printf '%s\n' "$drift_lines" | cut -f1)
    local FMT='{{.Name}}|:|{{index .Config.Labels "com.docker.compose.project"}}|:|{{index .Config.Labels "com.docker.compose.project.working_dir"}}|:|{{index .Config.Labels "com.docker.compose.project.config_files"}}|:|{{index .Config.Labels "com.docker.compose.service"}}'
    local labels=""
    if ! labels=$(timeout "$T_INSPECT" docker inspect --type container --format "$FMT" "${dnames[@]}" 2>/dev/null); then
      unknown "'docker inspect' of the drifted containers failed — nothing is attributable"; echo ""; finish
    fi
    local -A L_PROJ=() L_WD=() L_CF=() L_SVC=()
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      nm="${line%%|:|*}"; rest="${line#*|:|}"; nm="${nm#/}"
      pj="${rest%%|:|*}"; rest="${rest#*|:|}"
      wd="${rest%%|:|*}"; rest="${rest#*|:|}"
      cf="${rest%%|:|*}"; sv="${rest#*|:|}"
      L_PROJ["$nm"]="$pj"; L_WD["$nm"]="$wd"; L_CF["$nm"]="$cf"; L_SVC["$nm"]="$sv"
    done <<< "$labels"

    local running declared key
    while IFS=$'\t' read -r nm running declared; do
      pj="${L_PROJ[$nm]:-}"
      if [[ -n "$STACK" && "$pj" != "$STACK" ]]; then
        [[ -n "$pj" ]] && continue    # another project: out of scope for this run
      fi
      if [[ -n "${HOLD_REASON[$nm]+set}" ]]; then
        HELD=$((HELD + 1)); HELD_SERIES+=( "$nm|${HOLD_REASON[$nm]}" )
        echo -e "  ${YELLOW}HELD${NC}            $nm  $running -> $declared  pending (held: ${HOLD_REASON[$nm]})"
        continue
      fi
      wd="${L_WD[$nm]:-}"; cf="${L_CF[$nm]:-}"; sv="${L_SVC[$nm]:-}"
      if [[ -z "$pj" || -z "$wd" || -z "$cf" || -z "$sv" || "$pj$wd$cf$sv" == *"<no value>"* ]]; then
        FAILED_STACKS=$((FAILED_STACKS + 1))
        fail "$nm drifted but carries no complete compose labels (project/working_dir/config_files/service) — never guessed"
        continue
      fi
      if [[ -n "${IS_MEDIA[$nm]+set}" && $IN_WINDOW -eq 0 ]]; then
        QUIET=$((QUIET + 1))
        echo -e "  ${BLUE}QUIET-DEFERRED${NC}  $nm  $running -> $declared  pending (media window $DEPLOY_MEDIA_WINDOW local)"
        continue
      fi
      echo -e "  ${GREEN}DEPLOY${NC}          $nm  $running -> $declared  ($pj/$sv)"
      key="$pj"$'\t'"$wd"$'\t'"$cf"
      STACK_SVCS["$key"]="${STACK_SVCS[$key]:-}${STACK_SVCS[$key]:+ }$sv"
      STACK_CNAMES["$key"]="${STACK_CNAMES[$key]:-}${STACK_CNAMES[$key]:+ }$nm"
      CNAME_STACK["$nm"]="$key"
    done <<< "$drift_lines"
  fi
  if [[ ${#STACK_SVCS[@]} -eq 0 && $HELD -eq 0 && $QUIET -eq 0 ]]; then
    info "nothing drifted${STACK:+ in $STACK}"
  fi
  echo ""

  # ===============================================================================================
  # 3. Per stack (L-05, L-06, D-C, D-E)
  # ===============================================================================================
  echo "🚀 3. Per stack"
  rule
  local FREE="" FREE_PATH=""
  measure_free() {
    local a b
    a=$(df -B1 --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9') || a=""
    b=$(df -B1 --output=avail "$DOCKER_ROOT" 2>/dev/null | tail -1 | tr -dc '0-9') || b=""
    FREE=""; FREE_PATH=""
    [[ -z "$a" || -z "$b" ]] && return 0
    if (( b < a )); then FREE="$b"; FREE_PATH="$DOCKER_ROOT"; else FREE="$a"; FREE_PATH="/"; fi
  }
  run_logged() {   # run_logged SECONDS cmd... - bounded, output indented, returns the command's rc
    local secs="$1" out="" rc=0; shift
    out=$(timeout "$secs" "$@" 2>&1) || rc=$?
    [[ -n "$out" ]] && printf '%s\n' "$out" | tail -15 | sed 's/^/      /'
    return "$rc"
  }
  local -A STACK_FAILED=()
  local -a keys=()
  mapfile -t keys < <(printf '%s\n' "${!STACK_SVCS[@]}" | grep -v '^$' | sort || true)
  local k i stopped=0 nsvc
  local -a svcs cargs cfiles
  for i in "${!keys[@]}"; do
    k="${keys[$i]}"
    IFS=$'\t' read -r pj wd cf <<< "$k"
    read -ra svcs <<< "${STACK_SVCS[$k]}"
    nsvc=${#svcs[@]}
    cargs=( -p "$pj" --project-directory "$wd" )
    IFS=',' read -ra cfiles <<< "$cf"
    for f in "${cfiles[@]}"; do [[ -n "$f" ]] && cargs+=( -f "$f" ); done

    if [[ $REFUSED -eq 1 ]]; then
      WOULD_DEPLOY=$((WOULD_DEPLOY + nsvc))
      warn "$pj: ${svcs[*]} — REFUSED run, reported only, nothing deployed"
      continue
    fi
    if [[ $stopped -eq 1 ]]; then
      GUARD_DEFERRED=$((GUARD_DEFERRED + nsvc))
      warn "$pj: ${svcs[*]} — not attempted: the disk guard stopped this run"
      continue
    fi
    if (( SECONDS > RUN_BUDGET_SECONDS )); then
      BUDGET_DEFERRED=$((BUDGET_DEFERRED + nsvc))
      warn "$pj: ${svcs[*]} — pending (deferred: run budget ${RUN_BUDGET_SECONDS}s spent; next run takes it)"
      continue
    fi

    measure_free
    if [[ -z "$FREE" ]]; then
      fail "$pj: free space could not be measured on / or $DOCKER_ROOT — fail closed, stack not attempted"
      FAILED_STACKS=$((FAILED_STACKS + 1)); STACK_FAILED["$k"]=1
      continue
    fi
    local verdict="ok"
    (( FREE < REQUIRED )) && verdict="below"
    echo "  disk: $FREE_PATH free $FREE bytes ($(gib "$FREE") GiB), required $REQUIRED ($(gib "$REQUIRED") GiB)"

    if [[ $APPLY -eq 0 ]]; then
      WOULD_DEPLOY=$((WOULD_DEPLOY + nsvc))
      echo -e "  ${GREEN}WOULD-DEPLOY${NC} $pj: ${svcs[*]}"
      echo "      $(printf '%q ' timeout "$T_PULL" docker compose "${cargs[@]}" pull --quiet "${svcs[@]}")"
      echo "      $(printf '%q ' timeout "$T_UP" docker compose "${cargs[@]}" up -d --no-deps "${svcs[@]}")"
      if [[ $verdict == ok ]]; then
        echo "      disk verdict: ok"
      else
        echo "      disk verdict: apply would prune first — post-prune free space cannot be predicted in dry-run"
      fi
      continue
    fi

    # --- APPLY ---
    if [[ $verdict == below ]]; then
      warn "$pj: below required free space — docker image prune -af, then re-measure"
      run_logged "$T_PRUNE" docker image prune -af || fail "$pj: pre-stack prune failed (rc=$?)"
      measure_free
      if [[ -z "$FREE" ]] || (( FREE < REQUIRED )); then
        DISK_TRIPPED=1; stopped=1
        fail "DISK GUARD TRIPPED before $pj: ${FREE:-UNKNOWN} bytes free < $REQUIRED required — STOPPING the run"
        GUARD_DEFERRED=$((GUARD_DEFERRED + nsvc))
        continue
      fi
      pass "after prune: $FREE_PATH free $(gib "$FREE") GiB"
    fi
    echo "  ▶ $pj: ${svcs[*]}"
    local rc=0 ok=1
    run_logged "$T_PULL" docker compose "${cargs[@]}" pull --quiet "${svcs[@]}" || rc=$?
    if [[ $rc -ne 0 ]]; then
      ok=0; fail "$pj: pull failed (rc=$rc$([[ $rc -eq 124 ]] && echo ', TIMEOUT after '"$T_PULL"'s'))"
    else
      run_logged "$T_UP" docker compose "${cargs[@]}" up -d --no-deps "${svcs[@]}" || rc=$?
      if [[ $rc -ne 0 ]]; then
        ok=0; fail "$pj: up -d failed (rc=$rc$([[ $rc -eq 124 ]] && echo ', TIMEOUT after '"$T_UP"'s'))"
      fi
    fi
    if [[ $ok -eq 1 ]]; then
      DEPLOYED=$((DEPLOYED + nsvc)); pass "$pj: deployed ${svcs[*]}"
    else
      FAILED_STACKS=$((FAILED_STACKS + 1)); STACK_FAILED["$k"]=1
    fi
    rc=0
    run_logged "$T_PRUNE" docker image prune -af || rc=$?
    [[ $rc -ne 0 ]] && fail "$pj: post-stack prune failed (rc=$rc)"
  done
  [[ ${#keys[@]} -eq 0 ]] && info "no deployable stack this run"
  echo ""

  # ===============================================================================================
  # 4. Post-deploy (L-08) - apply AND something deployed only
  # ===============================================================================================
  if [[ $APPLY -eq 1 && $DEPLOYED -gt 0 ]]; then
    echo "🔁 4. Post-deploy verification"
    rule
    local v_out="" v_rc=0 still
    v_out=$(timeout "$T_POST" bash "$DEPLOY_REPO/scripts/check-drift.sh" 2>&1 | strip_ansi) || v_rc=$?
    info "check-drift.sh report mode rc=$v_rc"
    while IFS= read -r still; do
      [[ -z "$still" ]] && continue
      k="${CNAME_STACK[$still]:-}"
      [[ -z "$k" ]] && continue
      fail "$still: pulled and recreated but STILL DRIFTED"
      if [[ -z "${STACK_FAILED[$k]+set}" ]]; then
        STACK_FAILED["$k"]=1; FAILED_STACKS=$((FAILED_STACKS + 1))
      fi
    done < <(printf '%s\n' "$v_out" | awk '$1=="IMAGE_DRIFT" {print $2}')
    v_rc=0; run_logged "$T_POST" bash "$DEPLOY_REPO/scripts/check-drift.sh" --prom >/dev/null || v_rc=$?
    if [[ $v_rc -eq 0 ]]; then pass "check-drift.sh --prom refreshed the drift metric"; else fail "check-drift.sh --prom rc=$v_rc"; fi
    v_rc=0; run_logged "$T_POST" bash "$DEPLOY_REPO/scripts/check-jellyfin-transcode.sh" >/dev/null || v_rc=$?
    if [[ $v_rc -eq 0 ]]; then pass "check-jellyfin-transcode.sh green (D-17 / floor holds)"; else fail "check-jellyfin-transcode.sh rc=$v_rc"; fi
    echo ""
  fi

  # ===============================================================================================
  # 5. Metrics (L-07, D-F) - written on every run that got past the classifier, refused included
  # ===============================================================================================
  echo "📈 5. node-exporter textfile"
  rule
  local now prev_success="" success_ts="" mode_v=0
  now=$(date +%s)
  [[ $APPLY -eq 1 ]] && mode_v=1
  if [[ -f "$DEPLOY_PROM_DIR/$PROM_FILE" ]]; then
    prev_success=$(awk '$1=="selfhost_deploy_last_success_timestamp_seconds"{print $2; exit}' "$DEPLOY_PROM_DIR/$PROM_FILE" 2>/dev/null) || prev_success=""
  fi
  if [[ $FAILURES -eq 0 && $REFUSED -eq 0 ]]; then success_ts="$now"; else success_ts="$prev_success"; fi
  local TMP="$DEPLOY_PROM_DIR/.${PROM_FILE}.tmp.$$" g r
  gauge() { echo "# HELP $1 $2"; echo "# TYPE $1 gauge"; [[ -n "${3:-}" ]] && echo "$1 $3"; return 0; }
  if {
    gauge selfhost_deploy_last_run_timestamp_seconds "Unix time this deploy run completed (dry-run and refused runs included)." "$now"
    gauge selfhost_deploy_last_success_timestamp_seconds "Unix time of the last run with zero failures and not refused; carried forward otherwise." "$success_ts"
    gauge selfhost_deploy_apply_mode "1 if the run was --apply, 0 if dry-run." "$mode_v"
    gauge selfhost_deploy_refused "1 if the checkout was dirty or not fast-forwardable; nothing deployed." "$REFUSED"
    echo "# HELP selfhost_deploy_refused_reason One series per refusal reason."
    echo "# TYPE selfhost_deploy_refused_reason gauge"
    for r in "${REFUSED_REASONS[@]+"${REFUSED_REASONS[@]}"}"; do printf 'selfhost_deploy_refused_reason{reason="%s"} 1\n' "$(prom_escape "$r")"; done
    [[ "$COMMITS_BEHIND" =~ ^[0-9]+$ ]] && gauge selfhost_deploy_commits_behind "Commits the checkout is behind origin/main after this run (fetched)." "$COMMITS_BEHIND"
    gauge selfhost_deploy_deployed_services "Services pulled and recreated by this run." "$DEPLOYED"
    gauge selfhost_deploy_pending_services "Drifted deployable services not deployed: dry-run/refused would-deploy, run-budget and disk-guard deferrals." "$((WOULD_DEPLOY + BUDGET_DEFERRED + GUARD_DEFERRED))"
    gauge selfhost_deploy_held_services "Drifted services on the hold list (deployed only by a human)." "$HELD"
    echo "# HELP selfhost_deploy_held_service One series per held drifted container."
    echo "# TYPE selfhost_deploy_held_service gauge"
    for g in "${HELD_SERIES[@]+"${HELD_SERIES[@]}"}"; do
      printf 'selfhost_deploy_held_service{name="%s",reason="%s"} 1\n' "$(prom_escape "${g%%|*}")" "$(prom_escape "${g#*|}")"
    done
    gauge selfhost_deploy_quiet_deferred_services "Drifted media-class services waiting for the media window." "$QUIET"
    gauge selfhost_deploy_failed_stacks "Stacks (or unattributable drifted containers) that failed this run." "$FAILED_STACKS"
    gauge selfhost_deploy_disk_guard_tripped "1 if the disk guard stopped this run." "$DISK_TRIPPED"
  } > "$TMP" 2>/dev/null && chmod 0644 "$TMP" && mv -f "$TMP" "$DEPLOY_PROM_DIR/$PROM_FILE"; then
    pass "wrote $DEPLOY_PROM_DIR/$PROM_FILE atomically (temp name does not end in .prom)"
  else
    rm -f "$TMP" 2>/dev/null || true
    unknown "could not write $DEPLOY_PROM_DIR/$PROM_FILE"
  fi
  echo ""
  finish
}

main "$@"
