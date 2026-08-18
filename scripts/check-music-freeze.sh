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
#   4. Ownership census                   WRIT-04, D-11, D-12
#   5. Sidecar inventory                  SAFE-05, D-18 (never asserts)
#                                         widened 2026-08-18 by plan 01-06 to include .png and
#                                         .txt — see the block above section 5 for why
#   6. Fence presence and spot-check      SAFE-02, SAFE-03, SAFE-04, D-06, D-08, D-10
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

TAGGER_PATTERN='beets|soulbeet|wrtag|lidarr'
CONSUMER_PATTERN='jellyfin'

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

TAGGER_WRITERS=""
CONSUMER_WRITERS=""
UNCLASSIFIED_WRITERS=""
while IFS='|' read -r cname csrc cdst cflag; do
  [[ -z "${cname:-}" ]] && continue
  [[ "${cflag:-ro}" != "rw" ]] && continue
  touches_library "$csrc" || continue
  entry="$cname ($csrc:$cdst:rw)"
  if [[ "$cname" =~ $TAGGER_PATTERN ]]; then
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
echo "  Why this is a separate class from section 1: arrs/beets/beets.yaml and arrs/soulbeet.yaml"
echo "  are both commented out of arrs/compose.yaml, so no running container exists for either and"
echo "  section 1 cannot see them — while their YAML still declares a rw path into the library."
echo "  A running-container-only audit reports a false pass here."
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
  if [[ "$DIRMODE_MISMATCH" -eq 0 ]]; then
    pass "directory mode: 0 directories differ from $DIR_MODE"
  else
    fail "directory mode: $DIRMODE_MISMATCH directories differ from $DIR_MODE"
  fi
  if [[ "$FILEMODE_MISMATCH" -eq 0 ]]; then
    pass "file mode: 0 files differ from $FILE_MODE"
  else
    fail "file mode: $FILEMODE_MISMATCH files differ from $FILE_MODE"
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
echo "  dir-mode mismatches:         $DIRMODE_MISMATCH   (target 0, want $DIR_MODE)"
echo "  file-mode mismatches:        $FILEMODE_MISMATCH   (target 0, want $FILE_MODE)"
echo "  sidecars found (widened):    $SIDECAR_TOTAL   (nfo $NFO_COUNT / jpg $JPG_COUNT / lrc $LRC_COUNT / png $PNG_COUNT / txt $TXT_COUNT)"
echo "  sidecars found (narrow D-18):$NARROW_TOTAL   (nfo/jpg/lrc only — comparable to the 01-01 baseline)"
echo "  .DS_Store under the library: $DSSTORE_COUNT   (macOS client — an uncounted writer)"
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
