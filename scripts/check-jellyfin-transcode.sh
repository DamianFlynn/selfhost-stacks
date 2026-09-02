#!/usr/bin/env bash
# check-jellyfin-transcode.sh - Read-only audit of the Jellyfin transcode retention controls
# Usage: bash scripts/check-jellyfin-transcode.sh [--baseline]
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   It is host-resident rather than workstation-resident for two independent reasons:
#     - the docker mount enumeration and the Jellyfin API call cannot each be expressed as one
#       ssh'd command, and
#     - Jellyfin publishes NO host port. It is reachable only from a host that can route to its
#       t3_proxy address, which is this one.
#   Plan 02.1-10 folds it into the workstation-resident scripts/quick-health-check.sh with a
#     ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-jellyfin-transcode.sh'
#   exactly as 01-09 and 02-09 did for check-music-freeze.sh and check-music-consumers.sh.
#
#   PLATFORM CONSTRAINT - this script must NEVER run in default mode on the macOS workstation.
#   It measures free space with `df -B1 --output=avail`, and `--output` is GNU coreutils only.
#   BSD df silently ignores it and prints its own header-and-columns layout, which would parse
#   into a wrong number rather than into an error. A Darwin guard below therefore exits 2 in
#   default mode. `-h` and `--help` still work anywhere, because printing the contract is safe.
#
# READ-ONLY BY CONTRACT. This script inspects; it never writes, restarts, prunes, chowns,
# chmods, mounts or unmounts, and it never starts a transcode. Every mutation in phase 02.1
# belongs to infra/ (the dataset and its quota, plan 02.1-03), to the compose edit and recreate
# (plans 02.1-04/05/06) and to scripts/disable-jellyfin-hwaccel.sh (plan 02.1-07).
#
# What it covers:
#   0. Routes and preconditions            D-19 fail-closed; docker, zfs, Jellyfin, credential
#   1. `/` headroom                        TRAN-05, D-16, D-17
#   2. The mount invariant                 TRAN-01, TRAN-02, D-02, D-18
#   3. The old anonymous volume            TRAN-02 secondary, D-10, D-18
#   4. The transcode quota AND its mount   TRAN-03, D-12, D-13
#   5. The encoding values, read back      TRAN-04, D-20, D-30 - REPORTED, not asserted
#   6. Summary
#
# EXIT-CODE CONVENTION (inherited verbatim from scripts/check-music-freeze.sh:31-42, which is
# where the estate's convention was established; there was none before it):
#   default mode  - every red finding increments FAILURES and the script ends non-zero.
#   --baseline    - every finding is printed and the script always ends zero, so the before-state
#                   can be recorded while the bind, the quota and the settings do not yet exist.
#   usage error   - exit 2, distinct from exit 1 for a failed assertion. An unsupported platform
#                   is an ENVIRONMENT error and therefore also exit 2, never a failed assertion:
#                   "this instrument cannot be used here" is not "the estate is broken".
#   Why this is stated rather than inherited: check-renovate.sh exits zero on every finding except
#   a missing renovate.json, and quick-health-check.sh used to never exit non-zero at all.
#   Inheriting that silence is what let the docker `created`-state blind spot hide two down
#   containers for six weeks under a green check - and is the same silence that let 19 GB
#   accumulate in an anonymous volume over ~36 hours with nothing saying so.
#
#   --baseline exits 0 AFTER printing the summary, not before. The counts are still emitted.
#
# MODE SCOPE - what is REPORTED rather than ASSERTED, and why:
#   Section 5 (the encoding values) is REPORTED. A standing check cannot start a transcode, so it
#   cannot prove a setting FIRES; it can only prove the value has not drifted. Proving they fire
#   is plan 02.1-08's job, once, with the evidence recorded. Do not let this read-back stand in
#   for that proof - CONS-04's rule is that a configured setting is not a firing setting, and
#   Phase 2 paid for learning it (missing_album_artist_action read back correctly while silently
#   not applying).
#
#   Section 4's `df` reading of the transcode directory is REPORTED. Whether ZFS's statvfs
#   reflects a dataset quota is assumption A3 and is proven empirically by plan 02.1-03; until
#   that transcript exists this is corroboration, not evidence.
#
#   Everything else is ASSERTED. D-17's 20 GiB floor is recorded as green with its measured
#   margin at authoring time (see FLOOR_BYTES below) precisely so this check does not start red.
#   A permanently-red check trains the reader to ignore it - that is the 01-09 trap, and it is
#   the reason the mode-bit assertions were removed from check-music-freeze.sh.
#
# ENV OVERRIDES - three, all in the ${VAR:-default} form so a grep can prove they exist:
#     ZFS_HOST             the Proxmox host that owns the pool
#     JELLYFIN_CONTAINER   the container name to inspect
#     JELLYFIN_SECRETS     the credential file to source the API key from
#   They exist so plan 02.1-10's three NEGATIVE CONTROLS - the proofs that this check fails
#   closed rather than reporting green because it could not look - can be run WITHOUT MUTATING
#   ANY REAL FILE. That matters most for JELLYFIN_SECRETS: its real target is mode 600 owned by
#   root, and that mode/owner pair is itself an invariant asserted by check-music-consumers.sh.
#   Pointing the variable at a path that does not exist is a clean control; chmod'ing the real
#   file to stage the same condition would break a different check's assertion to test this one.
#
#   Overriding a path does NOT weaken the gate. The 600-root assertion runs against whatever path
#   is in use, so a control pointing at a non-existent file is refused for the RIGHT reason.
#   Do not relax the gate to accommodate a control.
#
# SECRETS. The Jellyfin API key is read at runtime from $JELLYFIN_SECRETS on LXC 100. NO TOKEN,
# PASSWORD OR KEY APPEARS IN THIS FILE OR ANYWHERE ELSE IN THIS REPOSITORY. The repo is public
# and has one prior credential exposure still recoverable via `git log -S`; a value committed
# here stays recoverable forever even after redaction. Section 5 passes the header to curl by
# process substitution so the key never enters argv and therefore never appears in `ps`.
#
# ZFS NOTE: LXC 100 is an unprivileged container. The fast/* datasets are bind-mounted into it,
# but the `zfs` command itself is NOT installed here and cannot be - the pool lives on the
# Proxmox host "atlantis". Every zfs query goes through zfs_query() and is delegated over ssh.
# Nothing here changes a dataset property.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- env overrides (see ENV OVERRIDES in the header) ------------------------------------------
ZFS_HOST="${ZFS_HOST:-172.16.1.158}"
JELLYFIN_CONTAINER="${JELLYFIN_CONTAINER:-jellyfin}"
JELLYFIN_SECRETS="${JELLYFIN_SECRETS:-/mnt/fast/secrets/jellyfin-deercrest.env}"

# --- fixed expectations -----------------------------------------------------------------------
#
# D-17's floor. 20 GiB in BYTES, never in GiB-rounded block mode: the `-B` flag with a `G`
# argument rounds UP, which is up to 1 GiB of optimism in exactly the direction that hurts
# (03-01's finding, commit b217ada - 2.2 GiB actually free reported as `3G`). The flag is named
# in words rather than written literally so a mechanical grep for it over this file returns zero.
# MEASURED MARGIN AT AUTHORING TIME, and it is NOT what the plan set assumed.
#   2026-09-02T20:56:25Z, on the --baseline run recorded in
#   .planning/phases/02.1-…/artifacts/02.1-02-baseline.txt:
#     / avail   = 21669597184 bytes = 20.18 GiB
#     floor     = 21474836480 bytes = 20.00 GiB
#     MARGIN    =   194760704 bytes =  0.18 GiB = 186 MiB
#
#   The floor was chosen to be green rather than aspirational, and it IS green - but by 186 MiB,
#   not by the ~13 GiB the plan set was written against (which assumed `/` still held the ~33-36
#   GiB it had after 03-01's image reap). The difference is a Jellyfin transcode cache that
#   refilled to 12.55 GiB in the two days since the container came up on 2026-08-31, which is
#   the condition this whole phase exists to fix.
#
#   So this check starts GREEN and starts FRAGILE. Read a red here as real: at 186 MiB there is
#   no room for it to be noise. See artifacts/02.1-D32-watch.txt for the sample series - note
#   that the cache is FLAT between playback sessions, so the budget is spent when the TV is on,
#   not on a wall clock.
FLOOR_BYTES=21474836480          # 20 GiB
QUOTA_BYTES=53687091200          # 50 G, D-12/D-13
TRANSCODE_DIR="/mnt/fast/transcode"
TRANSCODE_PARENT="/mnt/fast"
TRANSCODE_DATASET="fast/transcode"
CACHE_DIR="/mnt/fast/appdata/media/jellyfin/cache"
OLD_VOL_FILE="/mnt/fast/spike-021/old-vol.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASELINE_MODE=0
for arg in "$@"; do
  case "$arg" in
    --baseline) BASELINE_MODE=1 ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: bash scripts/check-jellyfin-transcode.sh [--baseline]" >&2
      exit 2
      ;;
  esac
done

# Platform guard. AFTER the arg loop, so `-h` still prints the contract on the workstation and a
# bad flag is still a usage error. An environment error is exit 2, not a failed assertion.
if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "this script requires GNU coreutils: it measures free space with 'df -B1 --output=avail'," >&2
  echo "and BSD df on macOS ignores --output and prints a different layout, which would parse" >&2
  echo "into a wrong number rather than into an error. Run it on LXC 100:" >&2
  echo "  ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-jellyfin-transcode.sh'" >&2
  exit 2
fi

FAILURES=0
UNREACHABLE=0
TOOLS_MISSING=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

# Delegate zfs to the Proxmox host when it is not resolvable locally. Read-only queries only.
# Copied from check-music-freeze.sh:123-131.
ZFS_ROUTE="unavailable"
zfs_query() {
  if command -v zfs >/dev/null 2>&1; then
    zfs "$@"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${ZFS_HOST}" zfs "$@"
  fi
}

# Bytes available on a filesystem, digits only, so an unreadable df yields the EMPTY STRING and
# is visibly UNKNOWN rather than being silently coerced to a plausible 0. "Could not look" and
# "it is empty" are different answers; 03-01 already paid for conflating them.
# The trailing `|| true` is load-bearing under `set -o pipefail`: without it a df that cannot stat
# the path returns non-zero, the command substitution inherits it, and the ASSIGNMENT aborts the
# whole run under `set -e` — turning "this reading is unknown" into "the script died", which is a
# worse answer than either.
avail_bytes() { df -B1 --output=avail "$1" 2>/dev/null | tail -1 | tr -dc '0-9' || true; }
size_bytes()  { df -B1 --output=size  "$1" 2>/dev/null | tail -1 | tr -dc '0-9' || true; }
gib() { [[ -z "${1:-}" ]] && { printf 'UNKNOWN'; return; }; awk -v b="$1" 'BEGIN{printf "%.2f", b/1073741824}'; }

echo "🎬 Jellyfin Transcode Retention Audit"
rule
echo "  container:  $JELLYFIN_CONTAINER"
echo "  transcode:  $TRANSCODE_DIR  (dataset $TRANSCODE_DATASET)"
echo "  cache:      $CACHE_DIR"
echo "  host:       $(hostname)"
echo "  date:       $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "  mode:       ${YELLOW}--baseline (report only, always exits 0)${NC}"
else
  echo "  mode:       assert (exits non-zero on any failed check)"
fi
echo ""

# =============================================================================================
# 0. Routes and preconditions (D-19 - fail closed, every route is a FAILURE not a skip)
# =============================================================================================
echo "🧰 0. Routes and preconditions (D-19)"
rule

DOCKER_OK=0
if command -v docker >/dev/null 2>&1; then
  DOCKER_OK=1
  pass "docker $(command -v docker)"
else
  fail "docker NOT FOUND — sections 2 and 3 cannot be asserted. This script runs ON LXC 100"
  echo "         (root@172.16.1.159), not on the workstation. A missing docker is a FAILURE,"
  echo "         not a skip: an unreachable instrument reporting green is the exact repudiation"
  echo "         D-19 exists to prevent."
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

for t in curl jq stat; do
  if command -v "$t" >/dev/null 2>&1; then
    pass "$t $(command -v "$t")"
  else
    fail "$t NOT FOUND — a missing binary here is a harness failure, not a caller's local problem"
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  fi
done

if command -v zfs >/dev/null 2>&1; then
  ZFS_ROUTE="local"
  pass "zfs $(command -v zfs) — local"
elif zfs_query list -H -o name fast >/dev/null 2>&1; then
  ZFS_ROUTE="ssh:${ZFS_HOST}"
  pass "zfs delegated to root@${ZFS_HOST} (LXC 100 is unprivileged; the pool lives on the Proxmox host)"
else
  fail "zfs unreachable both locally and at root@${ZFS_HOST} — section 4's authoritative quota and"
  echo "         mounted readings cannot be made. UNKNOWN, not green."
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi
info "ZFS_ROUTE=$ZFS_ROUTE"

# JELLYFIN ADDRESSING - three wrong ways and one right way, all measured 2026-08-31 and recorded
# in check-music-consumers.sh:140-149. Repeated here because the next reader will be reading THIS
# file, and the wrong answers are each plausible:
#   WRONG - the literal 192.168.90.31 that earlier plans pinned. Jellyfin is 192.168.90.25 today
#           and docker IPAM can move it again. Never pin the literal.
#   WRONG - the bare name `jellyfin` from LXC 100. resolv.conf carries `search deercrest.info`,
#           so it resolves to CLOUDFLARE'S PUBLIC EDGE and a health check would return 200 from
#           the public website with the container stopped.
#   WRONG - 172.16.1.76, the LAN address. Unreachable from LXC 100 under macvlan host isolation.
#   RIGHT - docker inspect, resolved fresh on every run. That is what JELLYFIN_ROUTE reports.
JELLYFIN_ROUTE="unavailable"
JELLYFIN_ADDR=""
if [[ $DOCKER_OK -eq 1 ]]; then
  JELLYFIN_ADDR="$(docker inspect "$JELLYFIN_CONTAINER" \
    --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}' 2>/dev/null || true)"
  if [[ -z "$JELLYFIN_ADDR" ]]; then
    fail "could not resolve $JELLYFIN_CONTAINER's t3_proxy address from docker — section 5 cannot run"
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  else
    JELLYFIN_ADDR="${JELLYFIN_ADDR}:8096"
    JELLYFIN_ROUTE="docker-inspect:${JELLYFIN_ADDR}"
    pass "Jellyfin resolved to $JELLYFIN_ADDR via docker inspect (never a pinned literal, never the bare name)"
  fi
fi

# The credential route. Copied from check-music-consumers.sh:500-513, with the wording corrected
# per the plan-02 review finding: this script runs as ROOT and root can read anything, so
# "unreadable" describes a condition that cannot occur here. The refusal fires on the file being
# ABSENT, or on its mode/owner not being exactly `600 root`. Making the path env-overridable does
# not weaken that - the assertion runs against whatever path is in use.
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"
if [[ -e "$JELLYFIN_SECRETS" ]]; then
  JF_MODE="$(stat -c '%a %U' "$JELLYFIN_SECRETS" 2>/dev/null || echo '? ?')"
  if [[ "$JF_MODE" == "600 root" ]]; then
    pass "Jellyfin credential $JELLYFIN_SECRETS ($JF_MODE)"
    # shellcheck disable=SC1090
    . "$JELLYFIN_SECRETS"    # no `set -a`: in-process only
    JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"
  else
    fail "Jellyfin credential $JELLYFIN_SECRETS has mode/owner '$JF_MODE', want '600 root' (D-40) — REFUSING to source it"
    echo "         Section 5 is UNKNOWN below, not green."
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  fi
else
  fail "Jellyfin credential $JELLYFIN_SECRETS is ABSENT — section 5 cannot run (D-40)"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi
echo ""

# =============================================================================================
# 1. Assertion A - `/` headroom (TRAN-05, D-16, D-17)
# =============================================================================================
echo "💾 1. Root filesystem headroom (TRAN-05, D-16, D-17)"
rule
ROOT_AVAIL="$(avail_bytes /)"
ROOT_SIZE="$(size_bytes /)"
if [[ -z "$ROOT_AVAIL" ]]; then
  fail "could not read free space on / — UNKNOWN, not '0 GiB free' and certainly not green."
  echo "         An unreadable df is exactly the instrument failure D-19 refuses to score as a pass."
else
  info "/ avail=$ROOT_AVAIL bytes ($(gib "$ROOT_AVAIL") GiB) of size=${ROOT_SIZE:-UNKNOWN} bytes ($(gib "${ROOT_SIZE:-}") GiB)"
  if [[ "$ROOT_AVAIL" -ge "$FLOOR_BYTES" ]]; then
    pass "/ headroom $(gib "$ROOT_AVAIL") GiB ≥ floor 20.00 GiB — margin $(gib "$((ROOT_AVAIL - FLOOR_BYTES))") GiB"
  else
    fail "/ headroom $(gib "$ROOT_AVAIL") GiB is BELOW the D-17 floor of 20.00 GiB (short by $(gib "$((FLOOR_BYTES - ROOT_AVAIL))") GiB)"
  fi
fi
echo ""

# =============================================================================================
# 2. Assertion B - the mount invariant (TRAN-01, TRAN-02, D-02, D-18)
# =============================================================================================
echo "🐳 2. The mount invariant (TRAN-01, TRAN-02, D-02, D-18)"
rule
CONTAINER_PRESENT=0
VOLUME_MOUNTS="UNKNOWN"
if [[ $DOCKER_OK -eq 0 ]]; then
  fail "docker unavailable — the mount invariant is UNKNOWN, not satisfied"
elif ! docker inspect "$JELLYFIN_CONTAINER" >/dev/null 2>&1; then
  # LOAD-BEARING, AND TESTED DIRECTLY BY PLAN 02.1-10's CONTROL 2.
  # `docker inspect` on a missing container produces EMPTY OUTPUT. The zero-volume-mounts test
  # below is `result == ""`, so an absent container would SATISFY it. Proving the container
  # exists first, with its own distinct message, is what keeps "nothing is mounted" apart from
  # "there is nothing to ask about" - the CR-02 distinction from disable-jellyfin-hwaccel.sh.
  fail "container '$JELLYFIN_CONTAINER' DOES NOT EXIST — the mount assertions below are UNKNOWN."
  echo "         This is NOT 'zero anonymous volumes'. An absent container yields an empty mount"
  echo "         enumeration, which would otherwise pass the very test it makes meaningless."
else
  CONTAINER_PRESENT=1
  pass "container '$JELLYFIN_CONTAINER' exists (asserted before anything is enumerated)"

  # THE INVARIANT, NOT THE INSTANCE (D-18). Asserting that one specific volume id is absent would
  # pass forever once it is deleted, while a FRESH anonymous volume grew unnoticed - the same
  # shape as 01-06's path-set diff that returned a false pass while 83 .nfo were rewritten.
  VOLUME_MOUNTS="$(docker inspect "$JELLYFIN_CONTAINER" \
    --format '{{range .Mounts}}{{if eq .Type "volume"}}x{{end}}{{end}}' 2>/dev/null || true)"
  if [[ -z "$VOLUME_MOUNTS" ]]; then
    pass "zero Type:volume mounts on $JELLYFIN_CONTAINER (the invariant, not the instance — D-18)"
  else
    fail "$JELLYFIN_CONTAINER holds ${#VOLUME_MOUNTS} Type:volume mount(s) — TRAN-02 requires zero:"
    docker inspect "$JELLYFIN_CONTAINER" \
      --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}} -> {{.Destination}}{{"\n"}}{{end}}{{end}}' \
      2>/dev/null | grep -v '^[[:space:]]*$' | sed 's/^/         /' || true
  fi

  # The destinations. VALIDATION.md rows 1 and 2.
  assert_bind() {
    local dest="$1" want_src="$2" row="$3" got
    got="$(docker inspect "$JELLYFIN_CONTAINER" \
      --format "{{range .Mounts}}{{if eq .Destination \"$dest\"}}{{.Type}} {{.Source}}{{end}}{{end}}" \
      2>/dev/null || true)"
    if printf '%s\n' "$got" | grep -qx "bind $want_src"; then
      pass "$dest is 'bind $want_src' ($row)"
    elif [[ -z "$got" ]]; then
      fail "$dest is NOT MOUNTED AT ALL — want 'bind $want_src' ($row)"
    else
      fail "$dest is '$got', want 'bind $want_src' ($row)"
    fi
  }
  assert_bind "/cache/transcodes" "$TRANSCODE_DIR" "VALIDATION row 1, TRAN-01"
  assert_bind "/cache"            "$CACHE_DIR"     "VALIDATION row 2, TRAN-01"

  # The dead /dev/shm:/data/transcode mount (D-02). VALIDATION.md row 3.
  DESTS="$(docker inspect "$JELLYFIN_CONTAINER" \
    --format '{{range .Mounts}}{{.Destination}}{{"\n"}}{{end}}' 2>/dev/null || true)"
  if printf '%s\n' "$DESTS" | grep -qx '/data/transcode'; then
    fail "/data/transcode is still a mount destination — D-02 requires it gone (VALIDATION row 3)"
  else
    pass "/data/transcode appears in no mount destination (D-02, VALIDATION row 3)"
  fi
fi
echo ""

# =============================================================================================
# 3. Assertion C - the old anonymous volume (TRAN-02 secondary, D-10, D-18)
# =============================================================================================
echo "🗑  3. The old anonymous volume (secondary to section 2, per D-18)"
rule
# The id is read from a file written by plan 02.1-01, deliberately NOT hard-coded: this section
# is secondary by design, and an id baked into the script would become a lie the moment the
# volume is recreated under a different name. Section 2 is the assertion that actually holds.
if [[ $DOCKER_OK -eq 0 ]]; then
  fail "docker unavailable — the old volume's existence is UNKNOWN, not 'gone'"
elif [[ -r "$OLD_VOL_FILE" ]]; then
  # `|| true` guards the SIGPIPE that `head -c` raises on `tr` under `set -o pipefail`.
  OLD_VOL="$(tr -dc 'a-f0-9' < "$OLD_VOL_FILE" | head -c 64 || true)"
  if [[ ${#OLD_VOL} -ne 64 ]]; then
    fail "$OLD_VOL_FILE does not contain a 64-character volume id — UNKNOWN"
  elif docker volume ls -q 2>/dev/null | grep -qx "$OLD_VOL"; then
    fail "the anonymous volume ${OLD_VOL:0:12}… STILL EXISTS (VALIDATION row 8, D-10)"
  else
    pass "the anonymous volume ${OLD_VOL:0:12}… is gone (VALIDATION row 8, D-10)"
  fi
else
  info "$OLD_VOL_FILE not readable — the old volume id was not captured, so this SECONDARY"
  echo "         section reports rather than asserts. Section 2's zero-Type:volume invariant is"
  echo "         the load-bearing test and is unaffected."
fi
echo ""

# =============================================================================================
# 4. Assertion D - the transcode quota AND its mount (TRAN-03, D-12, D-13)
# =============================================================================================
echo "📏 4. The transcode quota and its mount (TRAN-03, D-12, D-13)"
rule
# WHY THE MOUNT IS ASSERTED SEPARATELY (VALIDATION.md row 36, added by the cross-AI review):
# A GREEN QUOTA ON AN UNMOUNTED DATASET IS A FALSE PASS. If fast/transcode is unmounted at LXC
# boot, /mnt/fast/transcode is a plain directory on the PARENT dataset, the bind still works,
# the container still writes - and the quota does not apply to any of it. Meanwhile
# `zfs get quota fast/transcode` from atlantis still returns 53687091200 and reads perfectly
# green. That is the same class of boot-race the `mountpoint` export option closed in Phase 2,
# and it is exactly the shape of false pass this phase exists to stop being fooled by.
#
# Two INDEPENDENT instruments assert it. The second one does not reach atlantis at all, which is
# the point: it still answers when the ssh route is down.

# --- instrument 1: the authoritative properties, from atlantis --------------------------------
# The two queries this block makes, spelled out so they are greppable and reviewable:
#     zfs get -Hp -o value quota fast/transcode      -> must equal 53687091200
#     zfs get -Hp -o value mounted fast/transcode    -> must equal yes
# ROUTE CHECKED BEFORE THE QUERY (check-music-freeze.sh:482-490). An unreachable atlantis must be
# its own distinct red, never a `!= 53687091200` mismatch that a reader would parse as drift.
if [[ "$ZFS_ROUTE" == "unavailable" ]]; then
  fail "quota unverifiable — no zfs route (see section 0). UNKNOWN, not 50 G"
  fail "mounted state unverifiable from atlantis — no zfs route (see section 0)"
else
  Q="$(zfs_query get -Hp -o value quota "$TRANSCODE_DATASET" 2>/dev/null | tr -dc '0-9' || true)"
  if [[ -z "$Q" ]]; then
    fail "quota reading for $TRANSCODE_DATASET is EMPTY or non-numeric via $ZFS_ROUTE — UNKNOWN, not a mismatch"
  elif [[ "$Q" == "$QUOTA_BYTES" ]]; then
    pass "quota $TRANSCODE_DATASET = $Q bytes (50 G) via $ZFS_ROUTE (VALIDATION row 9)"
  else
    fail "quota $TRANSCODE_DATASET = $Q bytes, want $QUOTA_BYTES (50 G) via $ZFS_ROUTE (VALIDATION row 9)"
  fi

  M="$(zfs_query get -Hp -o value mounted "$TRANSCODE_DATASET" 2>/dev/null | tr -d '[:space:]' || true)"
  if [[ -z "$M" ]]; then
    fail "mounted reading for $TRANSCODE_DATASET is EMPTY via $ZFS_ROUTE — UNKNOWN, not 'yes'"
  elif [[ "$M" == "yes" ]]; then
    pass "$TRANSCODE_DATASET mounted=yes via $ZFS_ROUTE (VALIDATION row 36, instrument 1)"
  else
    fail "$TRANSCODE_DATASET mounted='$M', want 'yes' — the quota above is a FALSE PASS while this is red"
  fi
fi

# --- instrument 2: a container-side device-id comparison, independent of atlantis --------------
# A separately-mounted dataset has its own device id; an unmounted one collapses into the
# parent's. This needs no ssh and no zfs, so it still answers when instrument 1 cannot.
DEV_TRANSCODE="$(stat -c %d "$TRANSCODE_DIR" 2>/dev/null || true)"
DEV_PARENT="$(stat -c %d "$TRANSCODE_PARENT" 2>/dev/null || true)"
if [[ -z "$DEV_TRANSCODE" || -z "$DEV_PARENT" ]]; then
  fail "could not stat $TRANSCODE_DIR and/or $TRANSCODE_PARENT — mount state UNKNOWN (instrument 2)"
elif [[ "$DEV_TRANSCODE" != "$DEV_PARENT" ]]; then
  pass "$TRANSCODE_DIR device id $DEV_TRANSCODE differs from $TRANSCODE_PARENT's $DEV_PARENT — separately mounted (VALIDATION row 36, instrument 2)"
else
  fail "$TRANSCODE_DIR shares device id $DEV_TRANSCODE with $TRANSCODE_PARENT — it is a PLAIN DIRECTORY, NOT a mounted dataset."
  echo "         The bind would still work and the quota would NOT apply. This is the false pass"
  echo "         row 36 was added to catch."
fi

# Human-readable corroboration only. NOT asserted: findmnt's output format is not a contract.
if command -v findmnt >/dev/null 2>&1; then
  FM="$(findmnt -no FSTYPE,SOURCE "$TRANSCODE_DIR" 2>/dev/null || true)"
  info "findmnt $TRANSCODE_DIR: ${FM:-<no entry>}   (reported, not asserted)"
else
  info "findmnt not present — corroboration skipped (reported only; instruments 1 and 2 stand)"
fi

# REPORTED ONLY (VALIDATION row 12). Whether ZFS's statvfs reflects the dataset quota is
# assumption A3, proven empirically by plan 02.1-03. Until that transcript exists this is a
# corroborating reading, not evidence.
TQ_SIZE="$(size_bytes "$TRANSCODE_DIR")"
info "df size of $TRANSCODE_DIR: ${TQ_SIZE:-UNKNOWN} bytes ($(gib "${TQ_SIZE:-}") GiB)   (REPORTED not asserted — A3, VALIDATION row 12)"
echo ""

# =============================================================================================
# 5. Assertion E - the encoding values, read back (TRAN-04, D-20, D-30)
# =============================================================================================
echo "⚙️  5. The encoding values, read back (TRAN-04, D-20, D-30) — REPORTED, not asserted"
rule
# The key reaches curl through a PROCESS SUBSTITUTION, never through argv, so it cannot appear in
# `ps`. Same treatment as check-music-consumers.sh:418-427. Nothing in this section prints the
# key, and shell tracing is never enabled here.
jf_api() {
  local path="$1"; shift
  curl -s --max-time 20 -G \
    -H @<(printf 'Authorization: MediaBrowser Token="%s"\n' "$JELLYFIN_API_KEY") \
    "http://${JELLYFIN_ADDR}${path}" "$@"
}

if [[ -z "$JELLYFIN_ADDR" ]]; then
  fail "encoding values: UNREACHABLE — no Jellyfin route (see section 0). UNKNOWN, not green"
  UNREACHABLE=$((UNREACHABLE + 1))
elif [[ -z "$JELLYFIN_API_KEY" ]]; then
  fail "encoding values: UNREACHABLE — no API key (see $JELLYFIN_SECRETS, D-40). UNKNOWN, not green"
  UNREACHABLE=$((UNREACHABLE + 1))
else
  # BOUNDED RETRY - VALIDATION.md row 38, added by the cross-AI review.
  # 3 attempts, 2 s apart. Fail-closed is kept (D-19): an exhausted retry still increments
  # FAILURES and the script still ends non-zero. What the retry buys is that the RED IS HONEST
  # ABOUT WHICH KIND OF RED IT IS. This script is folded into the estate's shared health check by
  # plan 02.1-10, and a check that goes red for transient reasons trains the reader to ignore it
  # exactly as a permanently-red one does — D-17's own logic applied to a different axis.
  ENC=""
  for attempt in 1 2 3; do
    ENC="$(jf_api /System/Configuration/encoding 2>/dev/null || true)"
    if [[ -n "$ENC" ]] && printf '%s' "$ENC" | jq -e . >/dev/null 2>&1; then
      break
    fi
    ENC=""
    [[ $attempt -lt 3 ]] && sleep 2
  done

  if [[ -z "$ENC" ]]; then
    fail "encoding values: UNREACHABLE after 3 attempts"
    echo "         This is 'could not look', NOT 'the value moved'. The counter below is separate"
    echo "         from bound violations so the reader can tell the two apart (VALIDATION row 38)."
    UNREACHABLE=$((UNREACHABLE + 1))
  else
    # enc_val - read one key back, distinguishing THREE outcomes that must never share a rendering:
    #   <absent>  the key is not in the object at all
    #   null      the key is present and explicitly null (Jellyfin's "use the default")
    #   the value itself, INCLUDING the literal `false`
    #
    # Do NOT reduce this to `.[$k] // "<absent>"`. jq's `//` is the ALTERNATIVE operator and
    # treats BOTH `null` AND `false` as empty, so every boolean that is genuinely `false` renders
    # as "<absent>". That was this script's first-run defect, caught on its own baseline
    # (2026-09-02): EnableSegmentDeletion, EnableThrottling and EnableHardwareEncoding were all
    # `false` in the API response and all three printed as "<absent>".
    #
    # It is the exact conflation the rest of this file is built to prevent - CR-02's "NOTHING
    # HELD and COULD NOT LOOK are different answers" - and it landed on the most expensive value
    # in the set: EnableHardwareEncoding is the amdgpu mitigation, where "absent" and "false"
    # carry opposite implications for whether a six-hour outage hazard is still contained.
    # It would also have corrupted the before/after comparison: after 02.1-07 sets these to
    # `true`, a reader diffing transcripts would conclude the KEY had appeared rather than that
    # the VALUE had moved.
    enc_val() {
      printf '%s' "$ENC" \
        | jq -r --arg k "$1" 'if has($k) then (if .[$k] == null then "null" else (.[$k]|tostring) end) else "<absent>" end' \
          2>/dev/null || echo '<unparsed>'
    }
    for k in TranscodingTempPath EnableSegmentDeletion SegmentKeepSeconds EnableThrottling ThrottleDelaySeconds; do
      v="$(enc_val "$k")"
      info "$k = $v   (REPORTED not asserted — a standing check cannot prove a setting FIRES; that is 02.1-08's job)"
    done
    # The amdgpu mitigation, printed because REVERTING THESE IS THE HIGHER-COST REGRESSION. They
    # were applied 2026-08-31 18:27 after the amdgpu HMM oops, and the incident they mitigate
    # took the estate down for ~6 hours. The encoding endpoint is a FULL-OBJECT REPLACE, so a
    # partial POST silently re-arms that hazard (D-30).
    for k in HardwareAccelerationType EnableHardwareEncoding; do
      v="$(enc_val "$k")"
      info "$k = $v   (amdgpu mitigation, D-30 — REPORTED; drift here is the expensive regression)"
    done
  fi
fi
echo ""

# =============================================================================================
# 6. Summary
#
# Plan 02.1-10 folds this script into scripts/quick-health-check.sh and selects on the label
# tokens below with `grep -E`. The tokens chosen deliberately as its selectors are:
# `/ headroom`, `volume mounts`, `transcode quota`, `transcode mounted`, `encoding values`,
# `unreachable`, `toolchain missing`, `FAILURES total`. Renaming a heading or a label breaks a
# consumer that lives in a different file, and it breaks it SILENTLY — a grep that selects
# nothing looks exactly like a check with nothing to report.
#
# KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT SILENTLY.
echo "📊 6. Summary"
rule
echo "  / headroom:              ${ROOT_AVAIL:-UNKNOWN} bytes ($(gib "${ROOT_AVAIL:-}") GiB)  (target ≥ $FLOOR_BYTES)"
if [[ $CONTAINER_PRESENT -eq 1 ]]; then
  echo "  volume mounts:           ${#VOLUME_MOUNTS}  (target 0)"
else
  echo "  volume mounts:           UNKNOWN — container absent or docker unavailable  (target 0)"
fi
echo "  transcode quota:         ${Q:-UNKNOWN} bytes  (target $QUOTA_BYTES)"
echo "  transcode mounted:       zfs=${M:-UNKNOWN} devid=${DEV_TRANSCODE:-UNKNOWN} parent=${DEV_PARENT:-UNKNOWN}  (target yes, and devid ≠ parent)"
echo "  encoding values:         REPORTED not asserted  (see section 5)"
echo "  unreachable:             $UNREACHABLE  (could-not-look, counted apart from bound violations — VALIDATION row 38)"
echo "  toolchain missing:       $TOOLS_MISSING"
echo "  FAILURES total:          $FAILURES"
echo ""

if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "${YELLOW}--baseline: $FAILURES findings recorded, exiting 0. This is the before-state.${NC}"
  exit 0
fi

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}❌ $FAILURES failed checks${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Jellyfin transcode retention intact${NC}"
