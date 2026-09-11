#!/usr/bin/env bash
# check-music-freeze.sh - Read-only audit of the music-library safety harness
# Usage: bash scripts/check-music-freeze.sh [--baseline] [--sidecars]
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   It is host-resident rather than workstation-resident because `stat` over the library,
#   `find` across 1,200+ files and the docker mount enumeration cannot each be expressed as
#   one ssh'd command. Plan 01-09 folds it into the workstation-resident
#   scripts/quick-health-check.sh with a single
#     ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-music-freeze.sh'
#   which is how both estate conventions are honoured without mixing them inside one file.
#   That fold-in passes NO environment, which is exactly what keeps section 6b out of the routine
#   result until plan 04-11 promotes it - see CANDIDATE -> PROMOTED below.
#
# READ-ONLY BY CONTRACT. This script inspects; it never writes, moves, chowns, chmods or
# snapshots. Every mutation in phase 1 belongs to scripts/freeze-music-writers.sh (plan 01-08)
# and to the fence run (plan 01-02).
#
# What it covers:
#   0. Toolchain preconditions            CONS-04
#   1. Running-container rw holders       WRIT-01, D-08, D-26
#   2. Declared rw mounts in stack YAML   WRIT-01 false-pass guard, D-22
#   3. /mnt/tank/media layout             D-19 precondition (never asserts)
#   4. Ownership census                   WRIT-04, D-11 (owner asserted); D-12 mode half is
#                                         REPORTED, not asserted - see MODE SCOPE below
#   5. Sidecar inventory                  SAFE-05, D-18 (never asserts)
#                                         widened 2026-08-18 by plan 01-06 to include .png and
#                                         .txt — see the block above section 5 for why
#   6. Fence presence and spot-check      SAFE-02, SAFE-03, SAFE-04, D-06, D-08, D-10
#  6b. Tagger census (CANDIDATE)          D-21, D-25 - NOT in the routine result until plan
#                                         04-11 promotes it. See CANDIDATE -> PROMOTED below.
#   7. Summary
#
# EXIT-CODE CONVENTION (established here deliberately; the estate has none):
#   default mode  - every red finding increments FAILURES and the script ends non-zero.
#   --baseline    - every finding is printed and the script always ends zero, so the
#                   before-state can be recorded while the harness does not yet exist.
#   Why this is stated rather than inherited: check-renovate.sh exits zero on every finding
#   except a missing renovate.json, and quick-health-check.sh never exits non-zero at all.
#   Inheriting that silence is what let the docker `created`-state blind spot hide two down
#   containers for six weeks under a green check.
#
#   --sidecars    - emit the sorted sidecar path list on stdout and route the whole report to
#                   stderr, so the list can be redirected to a file on its own.
#
# CANDIDATE -> PROMOTED (Phase 4, plan 04-06, REVIEWS row 1):
#   Section 6b is a CANDIDATE check. While TAGGER_CENSUS_PROMOTED is 0 it runs ONLY when the
#   caller sets CENSUS_CANDIDATE=1. The routine fold-in from scripts/quick-health-check.sh sets
#   NOTHING, so a routine run prints one line saying 6b is a candidate, touches no counter, and
#   the routine result stays exactly at its pre-phase state. That is deliberate and it is the
#   whole point: 6b asserts THIS PHASE'S OUTCOME (the retired databases and trees are gone), and
#   that outcome is not true until plan 04-11 does the host teardown. Wiring it into the routine
#   fatal path in wave 2 would leave quick-health-check.sh red at every wave boundary from 2 to 6
#   - and that file's own header says it is built so it "does not inherit a permanent red".
#   A check that is red for a condition nobody has got to yet trains the reader to ignore it,
#   which is the 01-09 trap, and it also masks any GENUINE new failure in the same block.
#
#   Plan 04-11 sets TAGGER_CENSUS_PROMOTED to 1 in the same commit as the run where the candidate
#   is first green. After that 6b ALWAYS runs and CENSUS_CANDIDATE is ignored - the variable can
#   never disable 6b, only ask for it early.
#
# ENV OVERRIDES - three, all in the ${VAR:-default} form so a grep can prove they exist:
#     CENSUS_CANDIDATE           run section 6b before it is promoted
#     RETIRED_DB_PATHS           EXTRA retired paths, colon-separated, APPENDED to the built-ins
#     CENSUS_EXTRA_LIBRARY_ROOTS EXTRA roots treated as reaching Music, APPENDED to touches_library
#   They exist so plan 04-06's driven negative controls - the proofs that this census fails closed
#   rather than reporting green because it could not look - can be run WITHOUT MUTATING ANY REAL
#   FILE and, critically, WITHOUT EVER MOUNTING THE REAL LIBRARY rw to stage a control.
#
#   EVERY ONE OF THEM CAN ONLY MAKE THIS CHECK RED, NEVER GREEN. Both path variables are ADDITIVE:
#   they append to a built-in list and cannot replace or shorten it, so no value suppresses an
#   assertion or drops a path from the census. CENSUS_CANDIDATE only ADDS a section. There is no
#   sentinel that skips a check, however convenient one looks while debugging - do not add one.
#
#   SURVIVOR_DB and APPDATA_ROOT are deliberately PLAIN CONSTANTS, not overrides. An override on
#   either could produce a PASS (point SURVIVOR_DB at whichever database happens to exist, or
#   point APPDATA_ROOT at an empty directory and census nothing), and REVIEWS row 1 forbids any
#   override that can manufacture success. Changing either is a one-line edit here, in the commit
#   that changes the policy.
#
# MODE SCOPE (2026-08-18, plan 01-09 acting on plan 01-08's finding):
#   Section 4 asserts OWNERSHIP but only REPORTS the two mode counts. It used to assert all
#   three, and the mode pair is a PERMANENT red: every entry under the library is 0777 (88 dirs,
#   2,586 files) and cannot be changed. `chmod` fails EPERM on `tank` even as real root on the
#   Proxmox host - re-verified against a brand-new scratch file - because acltype=nfsv4 with
#   aclmode=restricted plus aclinherit=passthrough gives even freshly created files a non-trivial
#   NFSv4 ACL that chmod may not rewrite. The only fix is `zfs set aclmode=passthrough`, under
#   which a chmod then rewrites the ACL on all 2,674 entries - a bigger change than the problem.
#   D-12 is therefore SCOPED OUT by user decision and the modes stay 0777.
#
#   Why report instead of assert: plan 01-09 folds this script into quick-health-check.sh, which
#   runs routinely. A check that is red forever trains the reader to ignore it, which is the exact
#   failure the fold-in exists to prevent - see the docker `created`-state blind spot below. The
#   counts are still printed in section 4 and in the summary, so a REGRESSION is still visible;
#   what is removed is only the assertion that they must be 755/644.
#   If the ACL constraint is ever lifted, restore the two fail() calls in section 4.
#
# ZFS NOTE (2026-08-18, deviation from plan 01-01 as written):
#   LXC 100 is an unprivileged container. The tank datasets are bind-mounted into it, but the
#   `zfs` command itself is NOT installed here and cannot be - the pool lives on the Proxmox
#   host "atlantis". Section 0 and section 6 therefore delegate every zfs query to ZFS_HOST
#   over ssh, and report which route was used. Nothing here changes a dataset.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LIBRARY="/mnt/tank/media/Music"
MEDIA_ROOT="/mnt/tank/media"
FENCE="/mnt/fast/safety/music-pre-project"
STACKS="$REPO_ROOT/stacks/selfhosted"   # /mnt/fast/stacks/stacks/selfhosted on LXC 100
UIDGID="568:568"
DIR_MODE="755"
FILE_MODE="644"
ZFS_HOST="172.16.1.158"                 # Proxmox host "atlantis" - the only place zfs exists

# Lidarr's renamer writes paths and tags but mounts no beets state, so it stays NAME-classified.
# Everything else is classified by what it MOUNTS - see is_tagger_mount() and D-21/DEF-03-01. The
# name-based list this replaced could not see beets running inside sabnzbd, so it reported
# "tagger-class writers: 0" while structurally BLIND rather than while clean.
RENAMER_PATTERN='lidarr'
CONSUMER_PATTERN='jellyfin'

# Phase 4 census constants (D-21, D-25). NOT overrides - see ENV OVERRIDES in the header.
SURVIVOR_DB="/mnt/fast/appdata/arrs/beets/config/library.db"
APPDATA_ROOT="/mnt/fast/appdata"
CENSUS_FIND_TIMEOUT=90
# Positive control for the database census: a SQLite DB known to live under APPDATA_ROOT, fenced
# by plan 01-06 and recorded in the fence MANIFEST under "## Jellyfin databases". It is added to
# the candidate names for CONTROL ONLY - it is never counted as a beets or tagger database. If the
# census cannot see this, the census cannot see anything, and "0 beets databases" would be a lie.
JELLYFIN_CONTROL_DB="jellyfin.db"
TAGGER_CENSUS_PROMOTED=0

# --- env overrides (see ENV OVERRIDES in the header; every one can only make this check red) ---
CENSUS_CANDIDATE="${CENSUS_CANDIDATE:-0}"
RETIRED_DB_PATHS="${RETIRED_DB_PATHS:-}"
CENSUS_EXTRA_LIBRARY_ROOTS="${CENSUS_EXTRA_LIBRARY_ROOTS:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASELINE_MODE=0
SIDECAR_LIST=0
for arg in "$@"; do
  case "$arg" in
    --baseline) BASELINE_MODE=1 ;;
    --sidecars) SIDECAR_LIST=1 ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: bash scripts/check-music-freeze.sh [--baseline] [--sidecars]" >&2
      exit 2
      ;;
  esac
done

# In --sidecars mode fd 3 carries the machine-readable path list and the human report is
# pushed to stderr, so `... --sidecars > sidecars-baseline.txt` yields the list and nothing else.
if [[ $SIDECAR_LIST -eq 1 ]]; then
  exec 3>&1 1>&2
else
  exec 3>/dev/null
fi

FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

# Delegate zfs to the Proxmox host when it is not resolvable locally. Read-only queries only.
ZFS_ROUTE="unavailable"
zfs_query() {
  if command -v zfs >/dev/null 2>&1; then
    zfs "$@"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${ZFS_HOST}" zfs "$@"
  fi
}

# True when $1 is the library, an ancestor of it, or a path inside it - i.e. any of these
# grants write reach into /mnt/tank/media/Music.
touches_library() {
  local p="${1%/}"
  case "$p" in
    "$LIBRARY"|"$LIBRARY"/*) return 0 ;;
    /mnt/tank/media|/mnt/tank|/mnt|/) return 0 ;;
    *) return 1 ;;
  esac
}

# touches_library, WIDENED by the additive CENSUS_EXTRA_LIBRARY_ROOTS override (Phase 4, 04-06).
# The override exists so a fixture container can be proven to fail the rw-on-Music assertion
# WITHOUT ever mounting the real library rw: the fixture mounts a scratch directory, and that
# scratch root is declared as reaching Music only for the duration of the control. It is purely
# additive - it can add a path that must fail, never remove one.
census_reaches_library() {
  local p="${1%/}"
  [[ -z "$p" ]] && return 1
  if touches_library "$p"; then return 0; fi
  local r
  while IFS= read -r r; do
    [[ -z "$r" ]] && continue
    r="${r%/}"
    case "$p" in
      "$r"|"$r"/*) return 0 ;;
    esac
  done <<< "$(printf '%s' "$CENSUS_EXTRA_LIBRARY_ROOTS" | tr ':' '\n')"
  return 1
}

# D-21 / DEF-03-01: classify a container as tagger-capable by WHAT IT MOUNTS, not by its name.
#
# True when the mount's host-side .Source is:
#   * a FILE whose basename is a beets/wrtag/soulbeet config or database. Both spellings of the
#     beets config are matched on purpose: sabnzbd mounts beets-config.yaml (hyphen) and soulbeet
#     mounted beets_config.yaml (underscore). Matching only one is how a resurrected soulbeet
#     would slip past this classifier (REVIEWS row 14). soulbeet.db* is listed for the same
#     reason even though soulbeet's data/ has been empty since 2026-01-05.
#   * a DIRECTORY under APPDATA_ROOT that CONTAINS one of those names within -maxdepth 3, or a
#     config.yaml with a top-level plugins: or library: key. This is the branch that catches
#     sabnzbd, whose /config bind holds .config/beets/library.db - the exact live tagging path
#     the old name-based classifier was blind to.
#
# Pitfall 15: this labels sabnzbd tagger-capable PERMANENTLY, because D-11 keeps its beets config
# bind-mounted. That is CORRECT and it is not a failure - sabnzbd holds no /mnt/tank/media mount
# at any mode. Tagger-capability is REPORTED; it is the rw-on-Music counter that is asserted.
is_tagger_mount() {
  local src="${1%/}"
  [[ -z "$src" ]] && return 1
  local base hit c
  if [[ -f "$src" ]]; then
    base="$(basename "$src")"
    case "$base" in
      beets-config.yaml|beets_config.yaml|library.db*|*.blb*|wrtag.db*|soulbeet.db*) return 0 ;;
    esac
    return 1
  fi
  if [[ -d "$src" ]]; then
    case "$src/" in
      "$APPDATA_ROOT"/*) : ;;
      *) return 1 ;;
    esac
    hit="$(find "$src" -maxdepth 3 -type f \
      \( -name 'beets-config.yaml' -o -name 'beets_config.yaml' -o -name 'library.db*' \
         -o -name '*.blb*' -o -name 'wrtag.db*' -o -name 'soulbeet.db*' \) \
      -print -quit 2>/dev/null || true)"
    if [[ -n "$hit" ]]; then return 0; fi
    while IFS= read -r c; do
      [[ -z "$c" ]] && continue
      if grep -qE '^(plugins|library):' "$c" 2>/dev/null; then return 0; fi
    done <<< "$(find "$src" -maxdepth 3 -type f -name 'config.yaml' -print 2>/dev/null || true)"
    return 1
  fi
  return 1
}

echo "🎵 Music Freeze Harness Audit"
rule
echo "  library:   $LIBRARY"
echo "  fence:     $FENCE"
echo "  stacks:    $STACKS"
echo "  host:      $(hostname)"
echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "  mode:      ${YELLOW}--baseline (report only, always exits 0)${NC}"
else
  echo "  mode:      assert (exits non-zero on any failed check)"
fi
echo ""

# 0. Toolchain preconditions (CONS-04)
echo "🧰 0. Toolchain preconditions (CONS-04)"
rule
TOOLS_MISSING=0
for t in ffprobe ffmpeg jq gzip sha256sum; do
  if command -v "$t" >/dev/null 2>&1; then
    ver="$("$t" --version 2>/dev/null | head -1 || true)"
    [[ -z "$ver" ]] && ver="$("$t" -version 2>/dev/null | head -1 || true)"
    pass "$t $(command -v "$t") — ${ver:-version unknown}"
  else
    fail "$t NOT FOUND — CONS-04's completion test is written in ffprobe; a missing binary here is a harness failure, not a caller's local problem"
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  fi
done

if command -v zfs >/dev/null 2>&1; then
  ZFS_ROUTE="local"
  pass "zfs $(command -v zfs) — local"
elif zfs_query list -H -o name tank >/dev/null 2>&1; then
  ZFS_ROUTE="ssh:${ZFS_HOST}"
  pass "zfs delegated to root@${ZFS_HOST} (LXC 100 is unprivileged; the pool lives on the Proxmox host)"
else
  fail "zfs unreachable both locally and at root@${ZFS_HOST} — section 6 snapshot assertions cannot be made"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi
echo ""

# 1. Running-container rw holders on the library (WRIT-01, D-26)
echo "🐳 1. Running-container rw holders on the library (WRIT-01, D-26)"
rule
MOUNT_ROWS=""
if command -v docker >/dev/null 2>&1; then
  RUNNING_IDS="$(docker ps -q || true)"
  if [[ -n "$RUNNING_IDS" ]]; then
    # New logic - nothing in this repo enumerates .Mounts. '|' is the field separator because
    # bind-mount sources are absolute paths and ':' appears inside none of them but is the
    # docker-compose mapping separator, which makes ':' ambiguous when parsed back out.
    MOUNT_ROWS="$(docker inspect --format \
      '{{$n := .Name}}{{range .Mounts}}{{$n}}|{{.Source}}|{{.Destination}}|{{if .RW}}rw{{else}}ro{{end}}{{"\n"}}{{end}}' \
      $RUNNING_IDS 2>/dev/null | sed 's#^/##' | grep -v '^[[:space:]]*$' || true)"
  fi
  info "$(docker ps -q | wc -l | tr -d ' ') running containers, $(printf '%s\n' "$MOUNT_ROWS" | grep -c . || true) mounts enumerated"
else
  fail "docker not found — WRIT-01 cannot be verified on this host"
fi

# Which RUNNING containers are tagger-capable, by mount (D-21). Deduplicated on name|source
# first, because is_tagger_mount() may run a find over a bind-mounted appdata directory and the
# same source appears once per container that mounts it.
#
# NOTE on scope, recorded rather than changed here: `docker ps -q` above is BLIND when docker
# errors - it is wrapped in `|| true`, so a failed daemon yields an empty list and this section
# reports "0 rw holders" for a census that never happened. Section 6b covers that case with an
# explicit UNKNOWN once it is promoted. Section 1 is deliberately left exactly as it was, so the
# ROUTINE result of this script is untouched by plan 04-06.
TAGGER_CAPABLE_NAMES=""
while IFS='|' read -r cname csrc; do
  [[ -z "${cname:-}" ]] && continue
  if printf '%s\n' "$TAGGER_CAPABLE_NAMES" | grep -qxF "$cname"; then continue; fi
  if [[ "$cname" =~ $RENAMER_PATTERN ]] || is_tagger_mount "${csrc:-}"; then
    TAGGER_CAPABLE_NAMES+="${cname}"$'\n'
  fi
done <<< "$(printf '%s\n' "$MOUNT_ROWS" | awk -F'|' 'NF{print $1"|"$2}' | sort -u || true)"

TAGGER_WRITERS=""
CONSUMER_WRITERS=""
UNCLASSIFIED_WRITERS=""
while IFS='|' read -r cname csrc cdst cflag; do
  [[ -z "${cname:-}" ]] && continue
  [[ "${cflag:-ro}" != "rw" ]] && continue
  touches_library "$csrc" || continue
  entry="$cname ($csrc:$cdst:rw)"
  if printf '%s\n' "$TAGGER_CAPABLE_NAMES" | grep -qxF "$cname"; then
    TAGGER_WRITERS+="${entry}"$'\n'
  elif [[ "$cname" =~ $CONSUMER_PATTERN ]]; then
    CONSUMER_WRITERS+="${entry}"$'\n'
  else
    UNCLASSIFIED_WRITERS+="${entry}"$'\n'
  fi
done <<< "$MOUNT_ROWS"

count_lines() { printf '%s' "${1:-}" | grep -c . || true; }
TAGGER_COUNT="$(count_lines "$TAGGER_WRITERS")"
CONSUMER_COUNT="$(count_lines "$CONSUMER_WRITERS")"
UNCLASSIFIED_COUNT="$(count_lines "$UNCLASSIFIED_WRITERS")"

echo ""
echo "  tagger-class writers: $TAGGER_COUNT"
[[ -n "$TAGGER_WRITERS" ]] && printf '%s' "$TAGGER_WRITERS" | sed 's/^/      /'
echo "  consumer-class writers: $CONSUMER_COUNT (documented exception, D-21)"
[[ -n "$CONSUMER_WRITERS" ]] && printf '%s' "$CONSUMER_WRITERS" | sed 's/^/      /'
echo "  unclassified writers: $UNCLASSIFIED_COUNT"
[[ -n "$UNCLASSIFIED_WRITERS" ]] && printf '%s' "$UNCLASSIFIED_WRITERS" | sed 's/^/      /'
echo ""
echo "  Note: a bare total is deliberately NOT asserted. Jellyfin is expected to remain the"
echo "  sole rw holder (D-21), so 'total == 1' would read as a pass for the wrong reason."

if [[ "$TAGGER_COUNT" -eq 0 ]]; then
  pass "no tagger-class container holds rw on the library"
else
  fail "$TAGGER_COUNT tagger-class rw holders on the library (WRIT-01 requires 0)"
fi
if [[ "$UNCLASSIFIED_COUNT" -eq 0 ]]; then
  pass "no unclassified rw holders"
else
  fail "$UNCLASSIFIED_COUNT unclassified rw holders — classify or narrow each (D-19)"
fi
echo ""

# 2. Declared rw mounts across stack YAML (the false-pass guard)
echo "📄 2. Declared rw mounts across stack YAML (false-pass guard)"
rule
echo "  Why this is a separate class from section 1: arrs/beets/beets.yaml is commented out of"
echo "  arrs/compose.yaml, so no running container exists for it and section 1 cannot see it —"
echo "  while its YAML still declares a path into the library. A running-container-only audit"
echo "  reports a false pass here. (arrs/soulbeet.yaml was the second such file until plan 04-03"
echo "  deleted it; the class it illustrated is unchanged.)"
echo ""

DECLARED_ROWS=""
while IFS= read -r hit; do
  [[ -z "$hit" ]] && continue
  f="${hit%%:*}"
  rest="${hit#*:}"
  ln="${rest%%:*}"
  body="${rest#*:}"
  # skip commented-out volume lines - they declare nothing
  case "$(printf '%s' "$body" | sed 's/^[[:space:]]*//')" in '#'*) continue ;; esac
  mapping="$(printf '%s' "$body" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*#.*$//' | sed 's/[[:space:]]*$//')"
  host_side="${mapping%%:*}"
  suffix="${mapping##*:}"
  case "$suffix" in
    ro) sfx="ro" ;;
    rw) sfx="rw" ;;
    *)  sfx="NO-SUFFIX" ;;
  esac
  DECLARED_ROWS+="${f#"$REPO_ROOT"/}|${ln}|${mapping}|${sfx}|${host_side}"$'\n'
done <<< "$(grep -rn '/mnt/tank/media' "$STACKS" --include='*.yaml' --include='*.yml' 2>/dev/null || true)"

DECLARED_COUNT="$(count_lines "$DECLARED_ROWS")"
info "$DECLARED_COUNT declared /mnt/tank/media volume lines"
echo ""
printf '  %-46s %-5s %-10s %s\n' "FILE" "LINE" "SUFFIX" "MAPPING"
while IFS='|' read -r f ln mapping sfx host_side; do
  [[ -z "${f:-}" ]] && continue
  printf '  %-46s %-5s %-10s %s\n' "$f" "$ln" "$sfx" "$mapping"
done <<< "$DECLARED_ROWS"
echo ""
echo "  NO-SUFFIX means neither :ro nor :rw was written, and docker defaults that to rw."

DECLARED_MUSIC_RW=""
while IFS='|' read -r f ln mapping sfx host_side; do
  [[ -z "${f:-}" ]] && continue
  [[ "$sfx" == "ro" ]] && continue
  touches_library "$host_side" || continue
  [[ "$f" == "stacks/selfhosted/media/jellyfin.yaml" ]] && continue
  DECLARED_MUSIC_RW+="${f}:${ln} ${mapping} [${sfx}]"$'\n'
done <<< "$DECLARED_ROWS"

DECLARED_MUSIC_RW_COUNT="$(count_lines "$DECLARED_MUSIC_RW")"
if [[ "$DECLARED_MUSIC_RW_COUNT" -eq 0 ]]; then
  pass "no file other than media/jellyfin.yaml declares a rw or unsuffixed host path reaching the library"
else
  fail "$DECLARED_MUSIC_RW_COUNT declared rw/unsuffixed host paths reach the library outside media/jellyfin.yaml:"
  printf '%s' "$DECLARED_MUSIC_RW" | sed 's/^/         /'
fi
echo ""

# 3. /mnt/tank/media layout (D-19 precondition) - never asserts
echo "🗂  3. $MEDIA_ROOT layout (D-19 precondition)"
rule
MEDIA_ENTRIES=""
if [[ -d "$MEDIA_ROOT" ]]; then
  MEDIA_ENTRIES="$(ls -1 "$MEDIA_ROOT" 2>/dev/null || true)"
  while IFS= read -r e; do
    [[ -z "$e" ]] && continue
    echo "      $(stat -c '%F %n' "$MEDIA_ROOT/$e" 2>/dev/null || echo "unreadable $MEDIA_ROOT/$e")"
  done <<< "$MEDIA_ENTRIES"
else
  warn "$MEDIA_ROOT not present on this host"
fi
MEDIA_COUNT="$(count_lines "$MEDIA_ENTRIES")"
echo ""
echo "  D-19 mount sources must be chosen only from the names above."
echo "  (A docker bind mount whose source does not exist is silently created as an empty"
echo "   directory rather than erroring, so a typo here breaks an arr without any signal.)"
echo ""

# 4. Ownership census (WRIT-04, D-11/D-12)
echo "🔐 4. Ownership census (WRIT-04, D-11/D-12) — target ${UIDGID}, dirs ${DIR_MODE}, files ${FILE_MODE}"
rule
OWN_MISMATCH=0
DIRMODE_MISMATCH=0
FILEMODE_MISMATCH=0
ARTIST_COUNT=0
STRAY_COUNT=0
if [[ -d "$LIBRARY" ]]; then
  echo "      $(stat -c '%u:%g %a %n' "$LIBRARY")   <- library root"
  echo ""
  echo "  Immediate children (artist folders, plus any stray top-level file):"
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    if [[ -d "$d" ]]; then
      ARTIST_COUNT=$((ARTIST_COUNT + 1))
      echo "      $(stat -c '%u:%g %a %n' "$d")"
    else
      STRAY_COUNT=$((STRAY_COUNT + 1))
      echo "      $(stat -c '%u:%g %a %n' "$d")   <- STRAY top-level file, not an artist folder"
    fi
  done <<< "$(find "$LIBRARY" -mindepth 1 -maxdepth 1 | sort || true)"

  # WIDENED 2026-08-18 (plan 01-08): the census now includes the library ROOT itself.
  #
  # It used to be `-mindepth 1`, which silently excluded /mnt/tank/media/Music from its own
  # ownership assertion - and the root is mis-owned (01-01 recorded it at 568:65534, outside the
  # 13-folder census). A chown -R fixes it, but the audit could not see it either way, so this
  # assertion could have reported "0 entries differ" while the directory every NFS client mounts
  # was still wrong. That is the same false-pass class this phase has now hit five times.
  #
  # Consequence for comparability: totals move from 2673 to 2674 and the ownership mismatch count
  # from 2543 to 2544 against the 01-01 baseline. The tree did not change - the instrument did.
  # The -mindepth 1 subtotal is still printed below so the 01-01 numbers stay directly comparable.
  CENSUS="$(find "$LIBRARY" -printf '%U:%G %m %y\n' 2>/dev/null || true)"
  OWN_MISMATCH="$(printf '%s\n' "$CENSUS" | awk -v want="$UIDGID" 'NF && $1 != want' | grep -c . || true)"
  DIRMODE_MISMATCH="$(printf '%s\n' "$CENSUS" | awk -v want="$DIR_MODE" '$3 == "d" && $2 != want' | grep -c . || true)"
  FILEMODE_MISMATCH="$(printf '%s\n' "$CENSUS" | awk -v want="$FILE_MODE" '$3 == "f" && $2 != want' | grep -c . || true)"
  TOTAL_ENTRIES="$(printf '%s\n' "$CENSUS" | grep -c . || true)"
  SUBTREE_CENSUS="$(find "$LIBRARY" -mindepth 1 -printf '%U:%G %m %y\n' 2>/dev/null || true)"
  SUBTREE_OWN="$(printf '%s\n' "$SUBTREE_CENSUS" | awk -v want="$UIDGID" 'NF && $1 != want' | grep -c . || true)"
  SUBTREE_TOTAL="$(printf '%s\n' "$SUBTREE_CENSUS" | grep -c . || true)"

  echo ""
  info "$ARTIST_COUNT artist folders, $STRAY_COUNT stray top-level files, $TOTAL_ENTRIES entries including the library root"
  echo "      (of which $SUBTREE_TOTAL are below the root, $SUBTREE_OWN mis-owned — the -mindepth 1"
  echo "       figures this section used to report, kept for comparability with the 01-01 baseline)"
  echo "  Distinct uid:gid present:"
  printf '%s\n' "$CENSUS" | awk 'NF {print $1}' | sort | uniq -c | sed 's/^/      /'
  echo "  Distinct modes present (mode type count):"
  printf '%s\n' "$CENSUS" | awk 'NF {print $2, $3}' | sort | uniq -c | sed 's/^/      /'
  echo ""
  # ⚠️  READ THIS BEFORE TRUSTING THE uid:gid FIGURES ABOVE (plan 01-08, 2026-08-18).
  #
  # When this script runs on LXC 100 it reports the CONTAINER's view, not what is on disk.
  # LXC 100 is unprivileged with a sparse idmap (/etc/pve/lxc/100.conf): uid/gid 568 map
  # identity, but everything outside the mapped ranges surfaces as 65534 (nobody/nogroup).
  # So the real on-disk owners collapse as follows:
  #
  #     on disk (Proxmox host)   this script on LXC 100
  #     0:545                 -> 65534:65534
  #     3000:545              -> 65534:65534     (the .DS_Store - a DIFFERENT uid, hidden)
  #     568:545               -> 568:65534
  #     100000:100000         -> 0:0             (i.e. root INSIDE the container)
  #     100911:100911         -> 911:911
  #
  # Two consequences that cost this plan a false start:
  #   1. Distinct-owner counts here UNDERCOUNT - two different on-disk uids can collapse to one.
  #   2. chown CANNOT be run from LXC 100 at all. Unmapped ids are not chownable from inside a
  #      user namespace, so `chown -R` fails EPERM on every entry even as container root. The
  #      normalisation must run on the Proxmox host. See freeze-music-apply.sh `ownership`.
  # Ground truth: ssh root@172.16.1.158 'find /mnt/tank/media/Music -printf "%U:%G\n" | sort | uniq -c'

  if [[ "$OWN_MISMATCH" -eq 0 ]]; then
    pass "ownership: 0 entries differ from $UIDGID"
  else
    fail "ownership: $OWN_MISMATCH entries differ from $UIDGID"
  fi
  # The two mode counts are REPORTED, never asserted - see MODE SCOPE in the header. D-12 is
  # scoped out because chmod is impossible on this pool, so asserting here is a permanent red.
  if [[ "$DIRMODE_MISMATCH" -eq 0 ]]; then
    pass "directory mode: 0 directories differ from $DIR_MODE"
  else
    warn "directory mode: $DIRMODE_MISMATCH differ from $DIR_MODE — REPORTED not asserted (D-12 scoped out, chmod impossible on tank)"
  fi
  if [[ "$FILEMODE_MISMATCH" -eq 0 ]]; then
    pass "file mode: 0 files differ from $FILE_MODE"
  else
    warn "file mode: $FILEMODE_MISMATCH differ from $FILE_MODE — REPORTED not asserted (D-12 scoped out, chmod impossible on tank)"
  fi
else
  fail "$LIBRARY not present on this host"
fi
echo ""

# 5. Sidecar inventory (SAFE-05, D-18) - never asserts
#
# WIDENED 2026-08-18 (plan 01-06). D-18 and the roadmap name .nfo/.jpg/.lrc and nothing else.
# The 01-01 baseline run measured 43 .png and 175 .txt already sitting in the library that the
# narrow definition never counted - and Jellyfin writes .png for logo, clearart and disc art. An
# hour of watching only the narrow set can therefore report a clean pass while Jellyfin writes a
# .png in plain sight. The set below is the one the SAFE-05 watch uses; the narrow D-18 subtotal
# is still printed separately so the widening stays auditable against the 01-01 numbers.
#
# .DS_Store is counted but deliberately NOT part of the watched set: it is written by a macOS
# client over a share, which is an uncounted writer this phase can neither see from a container
# mount audit nor close from Jellyfin or Lidarr settings. Counting it here keeps it visible.
echo "🖼  5. Sidecar inventory (SAFE-05, D-18, widened by 01-06)"
rule
SIDECARS=""
DSSTORE=""
if [[ -d "$LIBRARY" ]]; then
  SIDECARS="$(find "$LIBRARY" -type f \
    \( -name '*.nfo' -o -name '*.jpg' -o -name '*.lrc' -o -name '*.png' -o -name '*.txt' \) \
    -printf '%p\n' 2>/dev/null | sort || true)"
  DSSTORE="$(find "$LIBRARY" -type f -name '.DS_Store' -printf '%p\n' 2>/dev/null | sort || true)"
fi
SIDECAR_TOTAL="$(count_lines "$SIDECARS")"
NFO_COUNT="$(printf '%s\n' "$SIDECARS" | grep -c '\.nfo$' || true)"
JPG_COUNT="$(printf '%s\n' "$SIDECARS" | grep -c '\.jpg$' || true)"
LRC_COUNT="$(printf '%s\n' "$SIDECARS" | grep -c '\.lrc$' || true)"
PNG_COUNT="$(printf '%s\n' "$SIDECARS" | grep -c '\.png$' || true)"
TXT_COUNT="$(printf '%s\n' "$SIDECARS" | grep -c '\.txt$' || true)"
DSSTORE_COUNT="$(count_lines "$DSSTORE")"
NARROW_TOTAL=$((NFO_COUNT + JPG_COUNT + LRC_COUNT))
info "$SIDECAR_TOTAL sidecars found (widened set)"
echo "      .nfo: $NFO_COUNT"
echo "      .jpg: $JPG_COUNT"
echo "      .lrc: $LRC_COUNT"
echo "      .png: $PNG_COUNT   <- added by 01-06; Jellyfin writes .png for logo/clearart/disc"
echo "      .txt: $TXT_COUNT   <- added by 01-06"
echo ""
echo "      narrow D-18 subtotal (.nfo/.jpg/.lrc only): $NARROW_TOTAL"
echo "      widened total (what the SAFE-05 watch measures): $SIDECAR_TOTAL"
echo "      .DS_Store files under the library: $DSSTORE_COUNT   <- macOS client, an uncounted writer"
[[ -n "$DSSTORE" ]] && printf '%s\n' "$DSSTORE" | sed 's/^/         /'
echo ""
echo "  D-18: these are inventoried and left in place. This inventory is the baseline the"
echo "  SAFE-05 one-hour watched-folder test diffs against — without it a pre-existing .nfo is"
echo "  indistinguishable from a newly written one. Re-run with --sidecars to emit the paths."
printf '%s\n' "$SIDECARS" >&3
echo ""

# 6. Fence presence and spot-check (SAFE-02/03/04, D-06/D-08/D-10)
echo "🧱 6. Fence presence and spot-check (SAFE-02/03/04, D-06/D-08/D-10)"
rule
FENCE_FAILURES=0
fence_fail() { fail "$*"; FENCE_FAILURES=$((FENCE_FAILURES + 1)); }

if [[ -d "$FENCE" ]]; then
  pass "fence exists: $FENCE ($(stat -c '%u:%g %a' "$FENCE"))"
else
  fence_fail "fence directory missing: $FENCE"
fi

for snap in tank/media/Music@pre-project tank/downloads@pre-project; do
  if [[ "$ZFS_ROUTE" == "unavailable" ]]; then
    fence_fail "snapshot $snap unverifiable — no zfs route (see section 0)"
  elif zfs_query list -t snapshot -H -o name "$snap" >/dev/null 2>&1; then
    pass "snapshot present: $snap (via $ZFS_ROUTE)"
  else
    fence_fail "snapshot missing: $snap (checked via $ZFS_ROUTE)"
  fi
done

for sub in library-db dj-mixes-ffprobe cover-scans tags; do
  if [[ -d "$FENCE/$sub" ]] && [[ -n "$(ls -A "$FENCE/$sub" 2>/dev/null || true)" ]]; then
    pass "fence subdirectory non-empty: $sub/ ($(find "$FENCE/$sub" -type f | wc -l | tr -d ' ') files)"
  else
    fence_fail "fence subdirectory missing or empty: $sub/"
  fi
done

# D-08 - "no tagger can write here" is proven from the same enumeration WRIT-01 uses.
FENCE_MOUNTS=""
while IFS='|' read -r cname csrc cdst cflag; do
  [[ -z "${cname:-}" ]] && continue
  case "${csrc%/}" in
    /mnt/fast/safety|/mnt/fast/safety/*) FENCE_MOUNTS+="${cname} (${csrc}:${cdst}:${cflag})"$'\n' ;;
  esac
done <<< "$MOUNT_ROWS"
FENCE_MOUNT_COUNT="$(count_lines "$FENCE_MOUNTS")"
if [[ "$FENCE_MOUNT_COUNT" -eq 0 ]]; then
  pass "no running container mounts any path under /mnt/fast/safety (D-08, proven not asserted)"
else
  fence_fail "$FENCE_MOUNT_COUNT running containers mount a path under /mnt/fast/safety:"
  printf '%s' "$FENCE_MOUNTS" | sed 's/^/         /'
fi
echo ""

# 6b. Tagger census (Phase 4 — D-21, D-25)
#
# DELIBERATELY NUMBERED 6b AND NOT 7. scripts/quick-health-check.sh anchors its fold-in on the
# literal string "📊 7. Summary". Renumbering that heading to make room for a new section would
# send the fold-in into its WR-09 UNKNOWN branch - silently, because a grep that selects nothing
# looks exactly like a check with nothing to report.
#
# CANDIDATE until plan 04-11 promotes it - see CANDIDATE -> PROMOTED in the header.
CENSUS_RAN=0
TAGGER_DEFS="UNKNOWN"
BEETS_DB_COUNT="UNKNOWN"
TAGGER_DB_COUNT="UNKNOWN"
RETIRED_PRESENT=0
RW_NONTAGGER="UNKNOWN"
RW_TAGGER="UNKNOWN"
RW_JELLYFIN="UNKNOWN"
TAGGER_CAPABLE_ALL="UNKNOWN"

if [[ $TAGGER_CENSUS_PROMOTED -eq 0 ]] && [[ "$CENSUS_CANDIDATE" != "1" ]]; then
  echo "  6b. Tagger census: CANDIDATE — not in the routine check until plan 04-11 promotes it (run with CENSUS_CANDIDATE=1)"
else
  CENSUS_RAN=1
  echo "🧮 6b. Tagger census (D-21, D-25)"
  rule

  # ---- (i) tagger definitions in git -----------------------------------------------------------
  # One definition may declare a tagger image, and it must be the survivor. Phase 5 introduces
  # metasauce/beets-flask; when it lands, THIS ASSERTION MUST BE REVISED in the same commit -
  # it is listed in the pattern below on purpose so a Phase 5 definition goes red here rather
  # than arriving unnoticed.
  GIT_LS=""
  GIT_RC=0
  GIT_LS="$(git ls-files stacks 2>/dev/null)" || GIT_RC=$?
  if [[ $GIT_RC -ne 0 ]] || [[ -z "$GIT_LS" ]]; then
    fail "tagger definition census: UNKNOWN — 'git ls-files stacks' exited $GIT_RC or listed nothing. Nothing was counted; this is NOT 'one definition'."
  else
    DEF_FILES="$(printf '%s\n' "$GIT_LS" \
      | { xargs -r -d '\n' grep -lE '^[[:space:]]*image:[[:space:]]*(lscr\.io/linuxserver/beets|sentriz/wrtag|ghcr\.io/terry90/soulbeet|metasauce/beets-flask)' 2>/dev/null || true; } \
      | sort)"
    TAGGER_DEFS="$(count_lines "$DEF_FILES")"
    if [[ "$TAGGER_DEFS" == "1" ]] && [[ "$DEF_FILES" == "stacks/selfhosted/arrs/beets/beets.yaml" ]]; then
      pass "tagger definitions: expected=1 at stacks/selfhosted/arrs/beets/beets.yaml — found exactly that"
    else
      fail "tagger definitions: expected=1 at stacks/selfhosted/arrs/beets/beets.yaml — found $TAGGER_DEFS:"
      printf '%s\n' "$DEF_FILES" | sed 's/^/         /'
    fi
  fi

  # ---- (ii) database discovery and classification ----------------------------------------------
  # NO -xdev. appdata/arrs and appdata/media are separate ZFS child datasets, and `find -xdev`
  # over /mnt/fast stops at the dataset boundary and returns ZERO results with EXIT 0 (Pitfall 12,
  # measured). That instrument would have reported "no beets databases on the estate".
  #
  # PRUNE LIST: EMPTY, and that is a measurement, not an oversight. The full walk was timed on
  # LXC 100 at execution (plan 04-06): find RC 0 in 1 s across the whole of APPDATA_ROOT,
  # including the 143 G hoarder tree. Nothing needed pruning, so nothing is pruned - which is the
  # safe direction, because every prune is a chance to drop the positive control.
  #
  # find RC: 0 and 1 are BOTH accepted. RC 1 means unreadable subpaths, which this estate really
  # does produce and which still returns a complete-enough result set (measured, RESEARCH
  # § Runtime State Inventory). Anything else - and 124 in particular - is "could not look".
  CENSUS_BLIND=0
  FIND_RC=0
  CANDIDATES="$(timeout "$CENSUS_FIND_TIMEOUT" find "$APPDATA_ROOT" -type f \
      \( -name 'library.db*' -o -name '*.blb*' -o -name 'wrtag.db*' -o -name 'soulbeet.db*' \
         -o -name "$JELLYFIN_CONTROL_DB" -o -name '*.bak' \) \
      -print 2>/dev/null)" || FIND_RC=$?
  if [[ $FIND_RC -eq 124 ]]; then
    fail "database census: UNKNOWN — census blind: find exceeded its ${CENSUS_FIND_TIMEOUT}s bound (rc=124). Nothing was counted."
    CENSUS_BLIND=1
  elif [[ $FIND_RC -ne 0 ]] && [[ $FIND_RC -ne 1 ]]; then
    fail "database census: UNKNOWN — census blind: find exited $FIND_RC (only 0 and 1 are accepted; 1 = unreadable subpaths)."
    CENSUS_BLIND=1
  fi

  BEETS_DBS=""
  TAGGER_DBS=""
  OTHER_SQLITE=""
  UNCLASSIFIED_DBS=""
  CONTROL_FOUND=0
  if [[ $CENSUS_BLIND -eq 0 ]]; then
    while IFS= read -r p; do
      [[ -z "$p" ]] && continue
      pbase="$(basename "$p")"
      # A .bak is only a candidate if it is really a SQLite file. sabnzbd.ini.bak and
      # qBittorrent.conf.bak are ordinary text backups and are not database evidence.
      phdr="$(head -c 16 "$p" 2>/dev/null | tr -d '\000' || true)"
      if [[ "$phdr" != "SQLite format 3" ]]; then
        case "$pbase" in
          *.bak) continue ;;
          *) UNCLASSIFIED_DBS+="$p (database-shaped name, not a SQLite file)"$'\n'; continue ;;
        esac
      fi
      if [[ "$pbase" == "$JELLYFIN_CONTROL_DB" ]]; then CONTROL_FOUND=1; fi
      ptbl="$(sqlite3 "file:${p}?mode=ro" '.tables' 2>/dev/null | tr -s '[:space:]' ' ' || true)"
      if [[ -z "$ptbl" ]]; then
        UNCLASSIFIED_DBS+="$p (SQLite header but unreadable)"$'\n'
        continue
      fi
      case "$pbase" in
        wrtag.db*|soulbeet.db*) TAGGER_DBS+="$p"$'\n'; continue ;;
      esac
      pn=0
      for w in items albums item_attributes album_attributes; do
        case " $ptbl " in *" $w "*) pn=$((pn + 1)) ;; esac
      done
      if [[ $pn -eq 4 ]]; then
        BEETS_DBS+="$p"$'\n'
      else
        OTHER_SQLITE+="$p"$'\n'
      fi
    done <<< "$CANDIDATES"

    # Positive control. A census that cannot see a database it is KNOWN to contain has not
    # measured zero - it has failed to look, and those are different answers.
    if [[ $CONTROL_FOUND -eq 0 ]]; then
      fail "database census: UNKNOWN — census blind: the Jellyfin positive-control database ($JELLYFIN_CONTROL_DB, fenced by plan 01-06, MANIFEST § 'Jellyfin databases') was NOT in the result set. Zero beets databases would be unreadable from this run."
      CENSUS_BLIND=1
    fi
  fi

  if [[ $CENSUS_BLIND -eq 1 ]]; then
    BEETS_DB_COUNT="UNKNOWN"
    TAGGER_DB_COUNT="UNKNOWN"
  else
    BEETS_DB_COUNT="$(count_lines "$BEETS_DBS")"
    TAGGER_DB_COUNT="$(count_lines "$TAGGER_DBS")"
    if [[ "$BEETS_DB_COUNT" == "1" ]] && [[ "$(printf '%s' "$BEETS_DBS" | head -1)" == "$SURVIVOR_DB" ]]; then
      pass "beets databases: expected=1 at $SURVIVOR_DB — found exactly that"
    else
      fail "beets databases: expected=1 at $SURVIVOR_DB — found $BEETS_DB_COUNT:"
      printf '%s' "$BEETS_DBS" | sed 's/^/         /'
    fi
    while IFS= read -r t; do
      [[ -z "$t" ]] && continue
      fail "tagger database PRESENT: $t (target 0 — wrtag/soulbeet state must not survive this phase)"
    done <<< "$TAGGER_DBS"
    while IFS= read -r u; do
      [[ -z "$u" ]] && continue
      fail "unclassified database candidate: $u"
    done <<< "$UNCLASSIFIED_DBS"
    if [[ -n "$OTHER_SQLITE" ]]; then
      info "other SQLite files matched by the candidate names (REPORTED, not failed — another app's database, and the Jellyfin positive control):"
      printf '%s' "$OTHER_SQLITE" | sed 's/^/         /'
    fi
  fi

  # ---- (iii) retired paths -------------------------------------------------------------------
  RETIRED_ALL="/mnt/fast/appdata/media/wrtag
/mnt/fast/appdata/arrs/soulbeet
/mnt/fast/appdata/arrs/beets/config/musiclibrary.blb
/mnt/fast/appdata/arrs/beets/config/config.yaml.old
/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb
/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log
/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets"
  if [[ -n "$RETIRED_DB_PATHS" ]]; then
    RETIRED_ALL+=$'\n'"$(printf '%s' "$RETIRED_DB_PATHS" | tr ':' '\n')"
  fi
  while IFS= read -r rp; do
    [[ -z "$rp" ]] && continue
    if [[ -e "$rp" ]]; then
      fail "retired path PRESENT: $rp"
      RETIRED_PRESENT=$((RETIRED_PRESENT + 1))
    fi
  done <<< "$RETIRED_ALL"
  if [[ $RETIRED_PRESENT -eq 0 ]]; then
    pass "retired paths: 0 of the retired tagger paths still exist"
  fi

  # ---- (iv) all-states mount census ------------------------------------------------------------
  # `docker ps -q` lists RUNNING containers only. "Idle" in this phase's goal includes exited and
  # created - and the estate's own six-week blind spot was two `created` containers reported as a
  # clean estate. This enumeration is unfiltered.
  DOCKER_RC=0
  ALL_IDS=""
  ALL_ROWS=""
  CENSUS_OBSERVED=0
  if command -v docker >/dev/null 2>&1; then
    ALL_IDS="$(docker ps -aq 2>/dev/null)" || DOCKER_RC=$?
  else
    DOCKER_RC=127
  fi
  if [[ $DOCKER_RC -eq 0 ]] && [[ -n "$ALL_IDS" ]]; then
    ALL_ROWS="$(docker inspect --format \
      '{{$n := .Name}}{{$s := .State.Status}}{{range .Mounts}}{{$n}}|{{$s}}|{{.Source}}|{{.Destination}}|{{if .RW}}rw{{else}}ro{{end}}{{"\n"}}{{end}}' \
      $ALL_IDS 2>/dev/null | sed 's#^/##' | grep -v '^[[:space:]]*$' || true)"
  fi
  if [[ $DOCKER_RC -ne 0 ]]; then
    fail "mount census: UNKNOWN — 'docker ps -aq' exited $DOCKER_RC. No container was enumerated. This is NOT 'no container holds rw on Music'."
  elif [[ -z "$ALL_IDS" ]]; then
    fail "mount census: UNKNOWN — 'docker ps -aq' returned no container id at all. An estate with zero containers is not a state this check can distinguish from a docker that would not answer."
  elif ! printf '%s\n' "$ALL_ROWS" | awk -F'|' 'NF{print $1}' | grep -q "$CONSUMER_PATTERN"; then
    fail "mount census: UNKNOWN — positive control absent: no container matching '$CONSUMER_PATTERN' was enumerated, so the mount census cannot be trusted to have seen anything."
  else
    CENSUS_OBSERVED=1
  fi

  if [[ $CENSUS_OBSERVED -eq 1 ]]; then
    RW_NONTAGGER=0
    RW_TAGGER=0
    RW_JELLYFIN=0
    ALL_TAGGER_NAMES=""
    ALL_TAGGER_ROWS=""
    while IFS='|' read -r cname cstate csrc; do
      [[ -z "${cname:-}" ]] && continue
      if printf '%s\n' "$ALL_TAGGER_NAMES" | grep -qxF "$cname"; then continue; fi
      if [[ "$cname" =~ $RENAMER_PATTERN ]] || is_tagger_mount "${csrc:-}"; then
        ALL_TAGGER_NAMES+="${cname}"$'\n'
        ALL_TAGGER_ROWS+="${cname}|${cstate}"$'\n'
      fi
    done <<< "$(printf '%s\n' "$ALL_ROWS" | awk -F'|' 'NF{print $1"|"$2"|"$3}' | sort -u || true)"
    TAGGER_CAPABLE_ALL="$(count_lines "$ALL_TAGGER_ROWS")"

    # CLASSIFICATION NEVER AUTHORISES A WRITE. Phase 1 D-20 is that NOBODY holds rw on Music
    # until Phase 6 - so every container that does, in ANY state, fails here, whether or not it
    # is tagger-capable. Jellyfin is the single documented D-21 consumer exception and is counted
    # on its own line rather than being folded into a total that would then read as a pass.
    while IFS='|' read -r cname cstate csrc cdst cflag; do
      [[ -z "${cname:-}" ]] && continue
      [[ "${cflag:-ro}" != "rw" ]] && continue
      census_reaches_library "${csrc:-}" || continue
      if [[ "$cname" =~ $CONSUMER_PATTERN ]]; then
        RW_JELLYFIN=$((RW_JELLYFIN + 1))
        info "rw on Music, D-21 consumer exception: $cname [$cstate] $csrc:$cdst"
        continue
      fi
      if printf '%s\n' "$ALL_TAGGER_NAMES" | grep -qxF "$cname"; then
        RW_TAGGER=$((RW_TAGGER + 1))
        fail "rw on Music: $cname [$cstate] $csrc:$cdst (tagger-capable)"
      else
        RW_NONTAGGER=$((RW_NONTAGGER + 1))
        fail "rw on Music: $cname [$cstate] $csrc:$cdst (non-tagger)"
      fi
    done <<< "$ALL_ROWS"

    if [[ $RW_NONTAGGER -eq 0 ]] && [[ $RW_TAGGER -eq 0 ]]; then
      pass "no container in any state holds rw reaching Music, apart from the D-21 consumer exception"
    fi

    # Pitfall 15: REPORTED, never asserted. sabnzbd is permanently tagger-capable by D-11 and
    # holds no /mnt/tank/media mount at any mode.
    echo ""
    echo "  Tagger-capable inventory (mounts a beets/wrtag/soulbeet config or database — REPORTED):"
    while IFS='|' read -r tn ts; do
      [[ -z "${tn:-}" ]] && continue
      tmode="none"
      while IFS='|' read -r xn xs xsrc xdst xflag; do
        [[ -z "${xn:-}" ]] && continue
        [[ "$xn" != "$tn" ]] && continue
        if census_reaches_library "${xsrc:-}"; then
          if [[ "${xflag:-ro}" == "rw" ]]; then tmode="rw"; break; fi
          tmode="ro"
        fi
      done <<< "$ALL_ROWS"
      echo "      $tn [$ts] — mode on Music: $tmode"
    done <<< "$ALL_TAGGER_ROWS"
  fi
fi
echo ""

# 7. Summary
echo "📊 7. Summary"
rule
echo "  tagger-class writers:        $TAGGER_COUNT   (target 0)"
echo "  consumer-class writers:      $CONSUMER_COUNT   (Jellyfin, documented exception D-21)"
echo "  unclassified writers:        $UNCLASSIFIED_COUNT   (target 0)"
echo "  declared /mnt/tank/media:    $DECLARED_COUNT volume lines"
echo "  declared rw reaching Music:  $DECLARED_MUSIC_RW_COUNT   (target 0, jellyfin.yaml excluded)"
echo "  media subtrees found:        $MEDIA_COUNT"
echo "  artist folders:              $ARTIST_COUNT   (directories only)"
echo "  stray top-level files:       $STRAY_COUNT"
echo "  ownership mismatches:        $OWN_MISMATCH   (target 0, want $UIDGID)"
echo "  dir-mode mismatches:         $DIRMODE_MISMATCH   (REPORTED not asserted — D-12 scoped out)"
echo "  file-mode mismatches:        $FILEMODE_MISMATCH   (REPORTED not asserted — D-12 scoped out)"
echo "  sidecars found (widened):    $SIDECAR_TOTAL   (nfo $NFO_COUNT / jpg $JPG_COUNT / lrc $LRC_COUNT / png $PNG_COUNT / txt $TXT_COUNT)"
echo "  sidecars found (narrow D-18):$NARROW_TOTAL   (nfo/jpg/lrc only — comparable to the 01-01 baseline)"
echo "  .DS_Store under the library: $DSSTORE_COUNT   (macOS client — an uncounted writer)"
# Phase 4 census counters (D-21, D-25), printed only when section 6b actually ran.
#
# CROSS-FILE CONTRACT: scripts/quick-health-check.sh selects on these label tokens with `grep -E`
# in its freeze fold-in. The tokens it greps for are `tagger definitions`, `beets databases`,
# `tagger databases`, `retired paths present`, `rw on Music` and `tagger-capable`, alongside the
# original `tagger-class`, `unclassified`, `declared rw` and `ownership mismatches`. Renaming a
# label here breaks a consumer in a different file and breaks it SILENTLY. Change both files in
# the same commit.
#
# Each counter prints UNKNOWN rather than a number when its input was not observed. "0" on a
# census that could not look is the exact false green this file exists to refuse.
if [[ $CENSUS_RAN -eq 1 ]]; then
  echo "  tagger definitions:          $TAGGER_DEFS   (target 1)"
  echo "  beets databases:             $BEETS_DB_COUNT   (target 1 = SURVIVOR_DB)"
  echo "  tagger databases:            $TAGGER_DB_COUNT   (target 0 — wrtag.db*/soulbeet.db*)"
  echo "  retired paths present:       $RETIRED_PRESENT   (target 0)"
  echo "  rw on Music, non-tagger:     $RW_NONTAGGER   (target 0, excluding the D-21 consumer exception)"
  echo "  rw on Music, tagger-capable: $RW_TAGGER   (target 0 — Phase 1 D-20, any container state)"
  echo "  rw on Music, Jellyfin D-21:  $RW_JELLYFIN   (documented consumer exception, printed separately)"
  echo "  tagger-capable containers:   $TAGGER_CAPABLE_ALL   (mounts a beets/wrtag/soulbeet config or DB; reported)"
fi
echo "  fence assertions failed:     $FENCE_FAILURES"
echo "  toolchain missing:           $TOOLS_MISSING"
echo "  FAILURES total:              $FAILURES"
echo ""

if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "${YELLOW}--baseline: $FAILURES findings recorded, exiting 0. This is the before-state.${NC}"
  exit 0
fi

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}❌ $FAILURES failed checks${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Music freeze harness intact${NC}"
