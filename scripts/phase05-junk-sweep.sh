#!/usr/bin/env bash
# phase05-junk-sweep.sh - Enumerate rule-shaped junk on the MUSIC download paths, write it to a
#                         file an operator reads and approves, then act on ONLY that approved file.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident because it walks roughly 2 TB of tree across five roots, counting audio files at
#   every depth beneath each candidate directory; that is not expressible as one ssh'd command, and
#   the estate convention (check-music-freeze.sh:6-12, spike03-image-headroom.sh:5-10) is that such
#   work lives on the host and is reached by a single ssh from the workstation.
#   Delivery is git: this repo is checked out at /mnt/fast/stacks and nothing else copies files in.
#
# Usage:
#   bash scripts/phase05-junk-sweep.sh enumerate   # READ-ONLY: measure and write the candidate list
#   bash scripts/phase05-junk-sweep.sh sweep       # MUTATES: acts on the approved candidate list
#   bash scripts/phase05-junk-sweep.sh --help      # print this header
#
# Workflow (plans 05-03 and 05-04):
#   ssh root@172.16.1.159
#   cd /mnt/fast/stacks && git pull --ff-only
#   bash scripts/phase05-junk-sweep.sh enumerate         # -> writes the candidate list, exits 0
#   <<< OPERATOR READS AND APPROVES THE LIST; struck rows are deleted FROM THE FILE >>>
#   bash scripts/phase05-junk-sweep.sh sweep             # -> acts on exactly what survived
#
# Outputs:
#   $APPROVED_LIST  (default /mnt/fast/safety/phase05/junk-candidates.tsv)
#                   One candidate per line, TAB-separated, SIX fields:
#                     rule  abs_path  type  bytes  audio_count  reason
#                   R8 rows carry a SEVENTH field, the proposed destination. This file IS the gate.
#   stdout          The human report. Nothing else is written anywhere.
#
# CONTRACT:
#   `enumerate`  READ-ONLY BY CONTRACT. It creates $OUT_DIR if absent and writes $APPROVED_LIST.
#                It moves nothing, it removes nothing, and it refuses to overwrite an existing
#                $APPROVED_LIST - an approved file must never be silently replaced by a fresh scan.
#   `sweep`      MUTATES LIVE STATE on a dataset an active downloader is writing to.
#
# THE KEY (D-13) - WHY THIS IS TWO SUBCOMMANDS AND NOT ONE SCRIPT WITH A PROMPT:
#   D-13 makes the approval gate the review itself, and the operator's standing verdict governs its
#   shape: "It's fine for a bot to drive us, but for me, as a human, no." Read and approve a file;
#   never sit at a prompt.
#
#   The approval therefore has to sit between two PROCESSES joined by a file on disk, not between
#   two branches of one process: a branch can be skipped by a flag, an env var or a future edit, a
#   missing file cannot. `enumerate` writes $APPROVED_LIST and stops. `sweep` reads $APPROVED_LIST
#   or refuses. That is the whole design, and it is why this file has no interactive prompt, no
#   --yes flag and no --force.
#
#   ONE approved file gates BOTH stages. D-13 says the gate blocks the move and the delete alike,
#   so `sweep` moves each approved row into $QUARANTINE and then removes what arrived there, under
#   that single approval. It is not two approvals.
#
# BANNED PRIMITIVES (the Phase 5 equivalent of the analog's prune prohibition):
#   No find with a removal action. No pipe into an argument-batching remover. No removal over a
#   glob. Every one of those decides for itself what to destroy, at the moment it runs, with no
#   list a human ever saw. There is exactly ONE removal call in this file; it takes a single quoted
#   absolute path read from $APPROVED_LIST, with a `--` guard in front of it.
#   The ban is enforced by a comment-stripped grep at acceptance, so the banned tokens are kept out
#   of echoed strings as well as out of code - spike03-image-headroom.sh:382-385 records that an
#   echoed banner string satisfies such a grep exactly as well as real code does.
#
# THE SCOPE FENCE - the single most important behaviour in this file:
#   Five roots, named as constants, and nothing else is ever touched:
#     $NZB/music  $NZB/unsorted  $NZB/dj-mixes  $DOWNLOADS/lidarr-import  $INBOX
#   Every path, in both subcommands, is resolved with realpath and re-checked against those roots
#   PER ITEM - not once on the roots. `normalise-dj-tags.py` learned that a per-target fence alone
#   is not enough. Two paths are refused BY NAME with their own message:
#     - $DOWNLOADS/incomplete (D-15) - SABnzbd's live working directory, drained at roughly one
#       music job per 72 seconds. Moving or removing anything under it can break an active job.
#     - /mnt/tank/media (Phase 1 D-20) - nobody holds rw on the library until Phase 6.
#
# EXIT-CODE CONVENTION (stated here deliberately, not inherited - the estate has no single one;
# see check-music-freeze.sh:31-38 for why that silence is itself a hazard):
#   enumerate  0 always. It REPORTS; it does not assert. A candidate is a proposal, not a failure,
#              and the whole point of running it is to find out what is there.
#   sweep      0  every approved row is gone from its original location and every row marked for
#                 removal is gone from the quarantine batch as well
#              1  at least one removal or move failed, or a listed row became unsafe between
#                 approval and sweep
#              2  usage error, or $APPROVED_LIST is missing, or $SNAPSHOT_PROOF is missing or does
#                 not name the required snapshot (refusal, never a fallback)
#
# HAZARD NOTES:
#   - NOTHING is written to the system temp directory. On LXC 100 that directory is tmpfs backed by
#     host RAM; a 1.1 GB file staged there previously took the whole 28 GB box down and killed ssh
#     on both the host and the container. Every byte this script writes lands under /mnt/fast.
#   - THE TREE IS LIVE. 05-PREMEASURE.md Limits: roughly one music job per 72 seconds. Any
#     enumeration is a point-in-time view and is stale the moment it is written. `sweep` therefore
#     re-derives every row against fresh state immediately before acting, and ANY conflict aborts
#     the WHOLE sweep with nothing moved and nothing removed. The approval says which items the
#     operator is willing to lose, not that they are still junk.
#   - ZFS FREES SPACE ASYNCHRONOUSLY. `zfs list` can lag a large removal by about 20 seconds, so
#     this script does NOT assert a reclaimed-space floor after acting. It asserts the ABSENCE of
#     each path and reports reclaimed space as informational, with the lag named.
#   - THE SNAPSHOT IS THE ONLY ROLLBACK. `mv` has no undo and neither has a removal. `zfs` cannot
#     resolve on LXC 100, so the check is delegated: produce the proof on atlantis and leave it at
#     $SNAPSHOT_PROOF. An unreachable atlantis means the snapshot state is UNKNOWN, which is a
#     refusal, not a skip and not a pass.
#   - A CONTAINER-SIDE OWNERSHIP READING IS NOT THE DISK. LXC 100 is unprivileged with a sparse
#     idmap, so unmapped on-disk ids surface as 65534. This script never asserts ownership; if you
#     add such an assertion, read it from atlantis.
#
# NO FIELD IN THE CANDIDATE FILE IS EVER EMPTY, AND THAT IS A CORRECTNESS REQUIREMENT, NOT TIDINESS:
#   TAB IS AN IFS *WHITESPACE* CHARACTER. Setting `IFS=$'\t'` does NOT make it behave like a plain
#   delimiter: bash still collapses runs of it and still strips it from the ends, so a row written
#   with an empty field is read back SHORT and every field after the gap SHIFTS LEFT BY ONE.
#   Measured on a synthetic fixture while this script was being written: an R1 row emitted as
#   `R1 <tab> path <tab> dir <tab> bytes <tab> <tab> reason` came back with the REASON sitting in
#   the audio-count variable and the reason variable empty - a row that parses cleanly, exits 0 and
#   is wrong. `sweep` compares the audio count it re-derives against the approved one, so that
#   shift would have compared a count against a sentence and aborted the whole run for no reason.
#   Every rule therefore emits a real value in every column, and `enumerate` ASSERTS the shape of
#   the file it just wrote (6 or 7 fields, none empty) before it reports success.
#
# CONTAINMENT SUPPRESSION (stated because it changes what the operator sees):
#   A descendant of an emitted directory is NOT emitted separately. Removing the parent removes the
#   child, so listing both would ask the operator to approve the same bytes twice and would hand
#   `sweep` a second row that is already gone. The suppressed counts are reported per rule on
#   stdout so the suppression is visible rather than silent.

set -euo pipefail

DOWNLOADS="${DOWNLOADS:-/mnt/tank/downloads}"
NZB="$DOWNLOADS/complete/nzb"
INBOX="$NZB/_inbox"
QUARANTINE="$INBOX/99-quarantine"
REVIEW="$INBOX/02-review"
OUT_DIR="${OUT_DIR:-/mnt/fast/safety/phase05}"
APPROVED_LIST="${APPROVED_LIST:-$OUT_DIR/junk-candidates.tsv}"
SNAPSHOT_NAME="tank/downloads@pre-phase5"
SNAPSHOT_PROOF="${SNAPSHOT_PROOF:-$OUT_DIR/snapshot-proof.txt}"
ZFS_HOST="${ZFS_HOST:-172.16.1.158}"
LIBRARY_ROOT="/mnt/tank/media"
INCOMPLETE_ROOT="$DOWNLOADS/incomplete"

# The five scope roots. Everything else on the estate is out of bounds, in both subcommands.
SCOPE_ROOTS=(
  "$NZB/music"
  "$NZB/unsorted"
  "$NZB/dj-mixes"
  "$DOWNLOADS/lidarr-import"
  "$INBOX"
)

LIDARR_ROOT="$DOWNLOADS/lidarr-import"
NOW_FOLDER="$NZB/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023"

AUDIO_EXTS=(mp3 flac wav m4a aac ogg opus wma alac aif aiff ape dsf dff mpc wv)
VIDEO_EXTS=(mkv mp4 avi m4v mov ts m2ts wmv mpg mpeg flv)

# R6 - the D-06 sidecars whose verdict is "review and remove", NAMED INDIVIDUALLY and never matched
# by extension. The same folder holds four sidecars that must be KEPT, and D-06 reached both sets of
# verdicts by OPENING the files: file type predicted nothing. Seven EAC rip-verification logs
# (volumes 110 x2, 111 x2, 113, 114, 115) and two small playlists with no volume identity.
# Note the typographic apostrophe in three of these names; they are the literal bytes on disk.
R6_BASENAMES=(
  "Various - NOW That's What I Call Music! 114.log"
  "Various - Now That's What I Call Music! 113.log"
  "Various Artists - NOW That’s What I Call Music! 115.log"
  "Various Artists - Now That's What I Call Music!, Vol. 110 Disc 1.log"
  "Various Artists - Now That's What I Call Music!, Vol. 110 Disc 2.log"
  "Various Artists - Now That's What I Call Music!, Vol. 111 Disc 1.log"
  "Various Artists - Now That's What I Call Music!, Vol. 111 Disc 2.log"
  "play.m3u"
  "00. play.m3u"
)

# KEEP - hard exclusions, checked BEFORE any rule fires. Nothing here can ever be emitted.
#   * the 9,541-line m3u map: D-02 depends on it - it carries each track's ORIGINAL path, which is
#     the only surviving record of volume number and CD attribution after the flatten
#   * back.bmp / cd1.bmp / cd2.bmp: NOW 77 case scans. back.bmp corroborates the tags three ways -
#     it states 44 tracks, CD1 1-22 and CD2 1-22; the tags for volume 77 read 44 files with
#     tracktotal 22 and 22; the file count is 44. It also carries a barcode and catalogue number
#     UK:CDNOW77, a precise release identifier for the Phase 6 Discogs lookup
#   * the volume-115 cue: EAC cue sheet with per-track TITLE and PERFORMER
KEEP_BASENAMES=(
  "00.Now That's What I Call Music! 1-115(2023).m3u"
  "back.bmp"
  "cd1.bmp"
  "cd2.bmp"
  "NOW That’s What I Call Music! 115.cue"
)

# KEEP - whole paths that must never be proposed, whatever a rule says. The real Now! collection is
# 45 G of audio; the inbox tree is this phase's own deliverable and its six policy directories are
# EMPTY BY DESIGN (D-17), which is exactly what R7 looks for.
KEEP_PATHS=(
  "$NOW_FOLDER"
  "$INBOX"
  "$INBOX/01-auto"
  "$INBOX/02-review"
  "$INBOX/03-asis"
  "$INBOX/04-hold"
  "$INBOX/99-quarantine"
  "$INBOX/_done"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

usage() {
  echo "usage: bash scripts/phase05-junk-sweep.sh {enumerate|sweep}" >&2
  echo "       bash scripts/phase05-junk-sweep.sh --help" >&2
  exit 2
}

ACTION="${1:-}"
case "$ACTION" in
  -h|--help)
    # Self-documenting help (check-music-freeze.sh:96-99): the header block IS the help text, so
    # the two can never drift apart.
    grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

# --- the scope fence ----------------------------------------------------------------------------

# assert_in_scope PATH [context]
# Resolves PATH and refuses anything that is not one of the five roots or a descendant. Refuses the
# two named trees with their own message. Exits 2 - a refusal, never a skip and never a fallback.
# Called PER ITEM, in both subcommands, deliberately.
assert_in_scope() {
  local given="$1" ctx="${2:-}" real="" root=""

  real="$(realpath -m -- "$given" 2>/dev/null)" || real=""
  if [ -z "$real" ]; then
    echo "❌ REFUSING: could not resolve path ${ctx}" >&2
    echo "   given: $given" >&2
    exit 2
  fi

  if [ "$real" = "$INCOMPLETE_ROOT" ] || [ "${real#"$INCOMPLETE_ROOT"/}" != "$real" ]; then
    echo "❌ REFUSING: $INCOMPLETE_ROOT is out of scope BY NAME (D-15)." >&2
    echo "   The refused tree is the 'incomplete' working directory, never a scope root." >&2
    echo "   given:    $given" >&2
    echo "   resolved: $real" >&2
    echo "   That tree is SABnzbd's live working directory, drained at roughly one music job per" >&2
    echo "   72 seconds. Moving or removing anything under it can break an active download, and a" >&2
    echo "   stalled job there is SABnzbd's to resolve through SABnzbd." >&2
    exit 2
  fi

  if [ "$real" = "$LIBRARY_ROOT" ] || [ "${real#"$LIBRARY_ROOT"/}" != "$real" ]; then
    echo "❌ REFUSING: $LIBRARY_ROOT is out of scope BY NAME (Phase 1 D-20)." >&2
    echo "   given:    $given" >&2
    echo "   resolved: $real" >&2
    echo "   Nobody holds rw on the library until Phase 6. Every write this phase performs lands" >&2
    echo "   under $DOWNLOADS." >&2
    exit 2
  fi

  for root in "${SCOPE_ROOTS[@]}"; do
    if [ "$real" = "$root" ] || [ "${real#"$root"/}" != "$real" ]; then
      printf '%s' "$real"
      return 0
    fi
  done

  echo "❌ REFUSING: path is outside the five scope roots ${ctx}" >&2
  echo "   given:    $given" >&2
  echo "   resolved: $real" >&2
  echo "   required: one of, or a descendant of:" >&2
  for root in "${SCOPE_ROOTS[@]}"; do echo "     $root" >&2; done
  exit 2
}

is_scope_root() {
  local p="$1" root
  for root in "${SCOPE_ROOTS[@]}"; do
    [ "$p" = "$root" ] && return 0
  done
  return 1
}

is_kept_path() {
  local p="$1" k
  for k in "${KEEP_PATHS[@]}"; do
    [ "$p" = "$k" ] && return 0
  done
  return 1
}

is_kept_basename() {
  local b="$1" k
  for k in "${KEEP_BASENAMES[@]}"; do
    [ "$b" = "$k" ] && return 0
  done
  return 1
}

# VALUE FLAG (added at execution, 2026-09-18, mitigating T-05-03-04 in a class the plan did not
# anticipate). The threat register says a value-bearing sidecar must never be proposed for removal
# by type alone, and mitigates it with a hard KEEP list plus R6's nine named files. That mitigation
# covers the `Now!` collection root only. The live enumeration then proposed EIGHT `.covers`
# directories - four release folders, each duplicated between dj-mixes/ and unsorted/ - every one of
# which holds a real cover JPEG. PROJECT.md records cover scans as "more reliable than any
# autotagger", and D-06's transferable lesson is that file type predicted nothing: three .bmp that
# looked like generic artwork turned out to carry a full tracklist, a barcode and a catalogue number.
#
# These rows are NOT hard-KEPT. Deciding to keep is the operator's call and this half of the gate
# only proposes. What is added is that such a row cannot arrive looking identical to an empty shell:
# its reason carries the flag and `enumerate` lists them in a section of their own.
VALUE_HINT_BASENAMES=( ".covers" "covers" "cover" "artwork" "art" "scans" "scan" "booklet" "images" "folder.jpg" )
looks_value_bearing() {
  local b="${1,,}" k
  for k in "${VALUE_HINT_BASENAMES[@]}"; do
    [ "$b" = "$k" ] && return 0
  done
  return 1
}

# A path whose own name contains a tab would corrupt the TSV that IS the gate. Such a path is
# EXCLUDED from the candidate list rather than emitted - fail closed: an item nobody can approve is
# an item nothing will act on.
TSV_UNSAFE=0
tsv_safe() {
  case "$1" in
    *$'\t'*) TSV_UNSAFE=$((TSV_UNSAFE + 1)); return 1 ;;
  esac
  return 0
}

is_r6_basename() {
  local b="$1" k
  for k in "${R6_BASENAMES[@]}"; do
    [ "$b" = "$k" ] && return 0
  done
  return 1
}

# --- measurement helpers ------------------------------------------------------------------------

AUDIO_EXPR=()
VIDEO_EXPR=()
build_exprs() {
  local e first
  AUDIO_EXPR=( '(' ); first=1
  for e in "${AUDIO_EXTS[@]}"; do
    [ "$first" -eq 1 ] && first=0 || AUDIO_EXPR+=( '-o' )
    AUDIO_EXPR+=( -iname "*.${e}" )
  done
  AUDIO_EXPR+=( ')' )

  VIDEO_EXPR=( '(' ); first=1
  for e in "${VIDEO_EXTS[@]}"; do
    [ "$first" -eq 1 ] && first=0 || VIDEO_EXPR+=( '-o' )
    VIDEO_EXPR+=( -iname "*.${e}" )
  done
  VIDEO_EXPR+=( ')' )
}

# count_matching DIR EXPRNAME -> a digit string, or the literal UNKNOWN.
# UNKNOWN is a third answer and is kept distinct from zero: "could not look" is not "there are
# none" (README section Health Checks). A rule that keys on zero NEVER fires on UNKNOWN.
count_matching() {
  local dir="$1" which="$2" out="" rc=0
  if [ "$which" = "audio" ]; then
    out="$(find -P "$dir" -type f "${AUDIO_EXPR[@]}" -print 2>/dev/null | wc -l)" || rc=$?
  else
    out="$(find -P "$dir" -type f "${VIDEO_EXPR[@]}" -print 2>/dev/null | wc -l)" || rc=$?
  fi
  if [ "$rc" -ne 0 ]; then printf 'UNKNOWN'; return 0; fi
  out="$(printf '%s' "$out" | tr -dc '0-9')"
  printf '%s' "${out:-UNKNOWN}"
}

count_entries() {
  local dir="$1" out="" rc=0
  out="$(find -P "$dir" -mindepth 1 -print 2>/dev/null | wc -l)" || rc=$?
  if [ "$rc" -ne 0 ]; then printf 'UNKNOWN'; return 0; fi
  out="$(printf '%s' "$out" | tr -dc '0-9')"
  printf '%s' "${out:-UNKNOWN}"
}

path_bytes() {
  local p="$1" out="" rc=0
  if [ -d "$p" ]; then
    out="$(du -sb -- "$p" 2>/dev/null | awk 'NR==1{print $1}')" || rc=$?
  else
    out="$(stat -c %s -- "$p" 2>/dev/null)" || rc=$?
  fi
  if [ "$rc" -ne 0 ]; then printf '0'; return 0; fi
  out="$(printf '%s' "$out" | tr -dc '0-9')"
  printf '%s' "${out:-0}"
}

# R3 IS APPLIED TO REGULAR FILES ONLY, AND THAT IS A SAFETY PROPERTY, NOT AN IMPLEMENTATION DETAIL.
# Measured on the live tree 2026-09-18, both halves of the trap present on this estate:
#   * `complete/nzb/music/[002+114] Def_Leppard-Slang-2LP-24BIT-FLAC-1995-REETKEVER.part001.rar`
#     is a DIRECTORY whose name ends in .rar, and it holds one real 24-bit FLAC. 05-PREMEASURE.md
#     § 5 counted it among "6 stray .rar files"; it is not a file and it is not a stray. Matching
#     the name without checking the type would have proposed destroying content.
#   * `complete/nzb/tv/Star.Trek.Voyager.S01E06...WEBDL-1080p.R75` and fifteen siblings are
#     DIRECTORIES whose names end in a release-group suffix that satisfies the multipart
#     `.r[0-9][0-9]` form exactly. They are out of scope anyway, but the shape is the same.
# Both are reached only through the `-type f` walk, so neither can ever be emitted. Do not
# "simplify" the caller by dropping `-type f`.
has_rar_shape() {
  local b="$1"
  case "$b" in
    *.rar|*.RAR|*.Rar) return 0 ;;
  esac
  # multipart forms: .rNN and .partNNN.rar (the latter is already caught above)
  if printf '%s' "$b" | grep -Eq '\.[rR][0-9][0-9]$'; then return 0; fi
  return 1
}

has_video_ext() {
  local b="$1" e
  for e in "${VIDEO_EXTS[@]}"; do
    case "${b,,}" in
      *".${e}") return 0 ;;
    esac
  done
  return 1
}

# --- rule evaluation ----------------------------------------------------------------------------

# dir_rule PATH -> "RULE<TAB>audio<TAB>reason" or empty when no rule fires.
# Precedence is R1 > R2 > R5 > R4 > R7. It is an ordered chain rather than a set because a single
# path must produce a single row: two rows for one path would ask the operator to approve the same
# bytes twice and would hand `sweep` a second row that is already gone.
#
# R4 IS DELIBERATELY ORDERED AHEAD OF R7 FOR DIRECTORIES, AND THAT MAKES R7's DIRECTORY CLAUSE
# UNREACHABLE. A directory empty at every depth necessarily contains zero audio files, so the two
# rules are not disjoint and one of them has to win. R4 wins because it is the rule this phase was
# specified against - the empty 512-byte dj-mixes decoy is R4's named example - and because "zero
# audio in a music path" is the reason the operator is being asked to approve. The information is
# not lost: when the directory is also empty at every depth the R4 reason says so on the row.
# R7 therefore reaches only zero-byte regular files in practice. Recorded rather than quietly
# dropped, because a rule that can never fire is exactly the shape this estate keeps paying for.
dir_rule() {
  local p="$1" base audio video entries
  base="$(basename -- "$p")"

  audio="$(count_matching "$p" audio)"
  [ "$audio" = "UNKNOWN" ] && return 0

  # R1/R2 report the real audio count too. A _UNPACK_ directory that already holds successfully
  # unpacked audio is a materially different proposition from an empty one, and the operator
  # approving the row is the person who needs to see that.
  case "$base" in
    _FAILED_*) printf 'R1\t%s\tdirectory basename begins with _FAILED_ (an abandoned download job)' "$audio"; return 0 ;;
    _UNPACK_*) printf 'R2\t%s\tdirectory basename begins with _UNPACK_ (an interrupted unpack)' "$audio"; return 0 ;;
  esac

  video="$(count_matching "$p" video)"

  if [ "$video" != "UNKNOWN" ] && [ "$video" -gt 0 ] && [ "$audio" -eq 0 ]; then
    printf 'R5\t%s\tdirectory holds %s video file(s) and zero audio files at any depth - video in a music path' "$audio" "$video"
    return 0
  fi

  entries="$(count_entries "$p")"

  if [ "$audio" -eq 0 ]; then
    if [ "$entries" != "UNKNOWN" ] && [ "$entries" -eq 0 ]; then
      printf 'R4\t%s\tdirectory contains zero audio files at any depth, and is empty at every depth (R7 directory clause, subsumed)' "$audio"
    else
      printf 'R4\t%s\tdirectory contains zero audio files at any depth' "$audio"
    fi
    return 0
  fi

  if [ "$entries" != "UNKNOWN" ] && [ "$entries" -eq 0 ]; then
    printf 'R7\t%s\tdirectory is empty at every depth' "$audio"
    return 0
  fi

  return 0
}

# file_rule PATH -> "RULE<TAB>reason" or empty. Precedence R6 > R3 > R5 > R7.
file_rule() {
  local p="$1" base sz
  base="$(basename -- "$p")"

  if is_r6_basename "$base" && [ "$(dirname -- "$p")" = "$NOW_FOLDER" ]; then
    printf 'R6\tD-06 named sidecar with no retained value (EAC rip log or volume-less playlist)'
    return 0
  fi

  if has_rar_shape "$base"; then
    printf 'R3\tstray archive volume left behind by an unpack'
    return 0
  fi

  if has_video_ext "$base"; then
    printf 'R5\tvideo file inside a music path'
    return 0
  fi

  sz="$(path_bytes "$p")"
  if [ "$sz" = "0" ]; then
    printf 'R7\tzero-byte regular file'
    return 0
  fi

  return 0
}

# --- enumerate ----------------------------------------------------------------------------------

declare -A EMITTED_DIRS=()
CANDIDATE_DIRS=()
VALUE_FLAGGED=()

collect_dirs() {
  local root="$1" p real r rulepart audio reason
  [ -d "$root" ] || { warn "scope root absent, skipped: $root"; return 0; }

  while IFS= read -r -d '' p; do
    real="$(assert_in_scope "$p" "(enumerate, directory)")"
    tsv_safe "$real" || continue
    is_scope_root "$real" && continue
    is_kept_path "$real" && continue
    # lidarr-import is triaged by D-20's own rule, never by R4/R7.
    if [ "$real" = "$LIDARR_ROOT" ] || [ "${real#"$LIDARR_ROOT"/}" != "$real" ]; then continue; fi

    r="$(dir_rule "$real")"
    [ -z "$r" ] && continue
    IFS=$'\t' read -r rulepart audio reason <<< "$r"
    CANDIDATE_DIRS+=( "${rulepart}"$'\t'"${real}"$'\t'"${audio}"$'\t'"${reason}" )
  done < <(find -P "$root" -mindepth 1 -type d -print0 2>/dev/null || true)
}

# True when $1 is a strict descendant of any already-emitted candidate directory.
covered_by_dir() {
  local p="$1" d
  for d in "${!EMITTED_DIRS[@]}"; do
    [ "$p" = "$d" ] && continue
    if [ "${p#"$d"/}" != "$p" ]; then return 0; fi
  done
  return 1
}

do_enumerate() {
  # A fresh enumeration must never silently replace a list an operator has already worked on.
  if [ -e "$APPROVED_LIST" ]; then
    echo "❌ candidate list already exists: $APPROVED_LIST" >&2
    echo "   Refusing to overwrite it. If it has been approved, run 'sweep'. If it is stale," >&2
    echo "   move it aside by hand and re-run 'enumerate'." >&2
    exit 2
  fi

  build_exprs
  mkdir -p "$OUT_DIR"

  echo "🧹 Phase 5 - junk gate, enumerate (READ-ONLY)"
  rule
  echo "  host:        $(hostname)"
  echo "  date:        $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "  out dir:     $OUT_DIR"
  echo "  list:        $APPROVED_LIST"
  echo -e "  mode:        ${BLUE}enumerate (read-only)${NC}"
  echo ""
  echo "  scope roots (five, and nothing else):"
  local root
  for root in "${SCOPE_ROOTS[@]}"; do echo "    $root"; done
  echo ""
  info "$INCOMPLETE_ROOT is out of scope by name (D-15)"
  info "$LIBRARY_ROOT is out of scope by name (Phase 1 D-20)"
  echo ""

  echo "📂 1. Candidate directories"
  rule
  for root in "${SCOPE_ROOTS[@]}"; do
    collect_dirs "$root"
  done

  # Suppress any candidate directory that sits under another candidate directory. Sorting by path
  # puts every ancestor before its descendants, so one pass is enough.
  local sorted=() line rulepart real audio reason
  if [ "${#CANDIDATE_DIRS[@]}" -gt 0 ]; then
    while IFS= read -r line; do sorted+=( "$line" ); done < <(printf '%s\n' "${CANDIDATE_DIRS[@]}" | sort -t$'\t' -k2,2)
  fi

  local rows=() suppressed_dirs=0
  for line in "${sorted[@]:-}"; do
    [ -z "$line" ] && continue
    IFS=$'\t' read -r rulepart real audio reason <<< "$line"
    if covered_by_dir "$real"; then
      suppressed_dirs=$((suppressed_dirs + 1))
      continue
    fi
    EMITTED_DIRS["$real"]=1
    if looks_value_bearing "$(basename -- "$real")"; then
      reason="${reason} ⚠ VALUE FLAG: this basename is one artwork or scans are usually kept under, and PROJECT.md records cover scans as more reliable than any autotagger. OPEN IT BEFORE APPROVING."
      VALUE_FLAGGED+=( "$real" )
    fi
    rows+=( "${rulepart}"$'\t'"${real}"$'\t'"dir"$'\t'"$(path_bytes "$real")"$'\t'"${audio}"$'\t'"${reason}" )
  done
  info "candidate directories emitted: ${#rows[@]}   suppressed as descendants: ${suppressed_dirs}"
  echo ""

  if [ "${#VALUE_FLAGGED[@]}" -gt 0 ]; then
    echo "🖼  1b. VALUE-FLAGGED rows - these are proposals, and they are the ones most likely to be wrong"
    rule
    warn "${#VALUE_FLAGGED[@]} candidate director(ies) carry a basename that usually holds artwork or scans."
    warn "D-06 reached every one of its verdicts by OPENING the files; file type predicted nothing."
    local vf
    for vf in "${VALUE_FLAGGED[@]}"; do
      info "$vf  ->  $(find -P "$vf" -type f -printf '%f ' 2>/dev/null | head -c 200)"
    done
    echo ""
  fi

  echo "📄 2. Candidate files"
  rule
  local p f_real r frule freason suppressed_files=0 kept_hits=0
  for root in "${SCOPE_ROOTS[@]}"; do
    [ -d "$root" ] || continue
    while IFS= read -r -d '' p; do
      f_real="$(assert_in_scope "$p" "(enumerate, file)")"
      tsv_safe "$f_real" || continue
      if is_kept_basename "$(basename -- "$f_real")" && [ "$(dirname -- "$f_real")" = "$NOW_FOLDER" ]; then
        kept_hits=$((kept_hits + 1))
        continue
      fi
      if [ "$f_real" = "$LIDARR_ROOT" ] || [ "${f_real#"$LIDARR_ROOT"/}" != "$f_real" ]; then continue; fi
      r="$(file_rule "$f_real")"
      [ -z "$r" ] && continue
      if covered_by_dir "$f_real"; then
        suppressed_files=$((suppressed_files + 1))
        continue
      fi
      IFS=$'\t' read -r frule freason <<< "$r"
      rows+=( "${frule}"$'\t'"${f_real}"$'\t'"file"$'\t'"$(path_bytes "$f_real")"$'\t'"0"$'\t'"${freason}" )
    done < <(find -P "$root" -type f -print0 2>/dev/null || true)
  done
  info "candidate files emitted (running total includes directories above): ${#rows[@]}"
  info "files suppressed as descendants of an emitted directory: ${suppressed_files}"
  info "hard-KEEP sidecars skipped before any rule fired: ${kept_hits}   (target 5)"
  echo ""

  echo "🤔 3. R8 - ambiguous, NOT auto-junk (D-20)"
  rule
  # lidarr-import holds content, not junk. D-17 says only 99-quarantine receives content; D-20 is
  # the specific exception that overrides it for these folders. The tension is recorded rather than
  # hidden: these rows are PROPOSALs and the operator decides, per folder.
  if [ -d "$LIDARR_ROOT" ]; then
    local a dest
    while IFS= read -r -d '' p; do
      f_real="$(assert_in_scope "$p" "(enumerate, lidarr-import)")"
      tsv_safe "$f_real" || continue
      is_scope_root "$f_real" && continue
      a="$(count_matching "$f_real" audio)"
      if [ "$a" = "UNKNOWN" ]; then
        warn "could not count audio under $f_real - NOT emitted, and that is not the same as zero"
        continue
      fi
      if [ "$a" -gt 0 ]; then dest="_inbox/02-review"; else dest="99-quarantine"; fi
      rows+=( "R8"$'\t'"${f_real}"$'\t'"dir"$'\t'"$(path_bytes "$f_real")"$'\t'"${a}"$'\t'"PROPOSAL - content, not junk (D-20). Operator decides the destination."$'\t'"${dest}" )
      info "PROPOSAL $f_real  audio=${a}  -> ${dest}"
    done < <(find -P "$LIDARR_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
  else
    info "$LIDARR_ROOT is absent - no R8 rows"
  fi
  echo ""

  echo "📝 4. Writing the candidate list"
  rule
  local building="${APPROVED_LIST}.building"
  : > "$building"
  if [ "${#rows[@]}" -gt 0 ]; then
    printf '%s\n' "${rows[@]}" | sort -t$'\t' -k1,1 -k2,2 >> "$building"
  fi
  mv "$building" "$APPROVED_LIST"
  pass "wrote $(wc -l < "$APPROVED_LIST" | tr -dc '0-9') row(s) to $APPROVED_LIST"

  # ASSERT THE SHAPE OF THE FILE THAT IS THE GATE, rather than trust the code that wrote it.
  # 6 or 7 fields, none of them empty - see the header note on tab being IFS whitespace.
  local shape_bad
  shape_bad="$(awk -F'\t' '
    NF < 6 || NF > 7 { bad++; next }
    { for (i = 1; i <= NF; i++) if ($i == "") { bad++; next } }
    END { print bad + 0 }' "$APPROVED_LIST")"
  if [ "$shape_bad" != "0" ]; then
    warn "${shape_bad} row(s) in $APPROVED_LIST are malformed (not 6-7 non-empty tab fields)."
    warn "sweep will not parse them the way enumerate wrote them. Do NOT approve this list."
  else
    pass "every row carries 6 or 7 non-empty tab-separated fields"
  fi
  if [ "$TSV_UNSAFE" -gt 0 ]; then
    warn "${TSV_UNSAFE} path(s) excluded because their own name would corrupt the candidate file"
  fi
  echo ""

  echo "📊 5. Per-rule summary"
  rule
  printf '  %-5s %-8s %-18s %s\n' "RULE" "ROWS" "BYTES" "MEANING"
  local rid label n b
  for rid in R1 R2 R3 R4 R5 R6 R7 R8; do
    case "$rid" in
      R1) label="_FAILED_ directory" ;;
      R2) label="_UNPACK_ directory" ;;
      R3) label="stray archive volume" ;;
      R4) label="zero audio at any depth" ;;
      R5) label="video in a music path" ;;
      R6) label="named D-06 sidecar" ;;
      R7) label="zero-byte file / empty dir" ;;
      R8) label="PROPOSAL - content, operator decides" ;;
    esac
    n="$(awk -F'\t' -v r="$rid" '$1==r{c++} END{print c+0}' "$APPROVED_LIST")"
    b="$(awk -F'\t' -v r="$rid" '$1==r{s+=$4} END{print s+0}' "$APPROVED_LIST")"
    printf '  %-5s %-8s %-18s %s\n' "$rid" "$n" "$b" "$label"
  done
  echo ""
  echo "  total rows:  $(wc -l < "$APPROVED_LIST" | tr -dc '0-9')"
  echo "  total bytes: $(awk -F'\t' '{s+=$4} END{print s+0}' "$APPROVED_LIST")"
  echo "  VALUE-FLAGGED rows (open these before approving): ${#VALUE_FLAGGED[@]}"
  echo ""

  warn "NOTHING HAS BEEN MOVED AND NOTHING HAS BEEN REMOVED."
  warn "An operator must read and approve $APPROVED_LIST before 'sweep' will act. Strike any row"
  warn "you do not want acted on by removing that LINE from the file."
  warn "This list is a POINT-IN-TIME view of a tree written at roughly one music job per 72 s."
  warn "'sweep' re-derives every row against fresh state and aborts the whole run on any conflict."
  echo ""
  # enumerate reports, it does not assert.
  return 0
}

# --- sweep --------------------------------------------------------------------------------------

do_sweep() {
  # REFUSAL ONE, and it is the FIRST statement of the acting subcommand so it is reachable and
  # testable anywhere - including on a workstation with no access to tank at all.
  if [ ! -f "$APPROVED_LIST" ]; then
    echo "❌ approved candidate list not found: $APPROVED_LIST" >&2
    echo "   Run 'bash scripts/phase05-junk-sweep.sh enumerate' first, then have the list read and" >&2
    echo "   approved by the operator. Refusing to guess what may be moved or removed." >&2
    exit 2
  fi

  # REFUSAL TWO, for the same reason and with the same reachability.
  if [ ! -f "$SNAPSHOT_PROOF" ]; then
    echo "❌ snapshot proof not found: $SNAPSHOT_PROOF" >&2
    echo "   $SNAPSHOT_NAME is this subcommand's ONLY rollback, and zfs cannot resolve on LXC 100," >&2
    echo "   so the check is delegated. Produce the proof on atlantis:" >&2
    echo "     ssh -o BatchMode=yes -o ConnectTimeout=5 root@${ZFS_HOST} \\" >&2
    echo "       'zfs list -t snapshot -H -o name ${SNAPSHOT_NAME}' > $SNAPSHOT_PROOF" >&2
    echo "   An unreachable atlantis means the snapshot state is UNKNOWN, which is a refusal, not a" >&2
    echo "   skip and not a pass." >&2
    exit 2
  fi
  if ! grep -qF "$SNAPSHOT_NAME" "$SNAPSHOT_PROOF"; then
    echo "❌ snapshot proof does not name $SNAPSHOT_NAME: $SNAPSHOT_PROOF" >&2
    echo "   The 2026-08-18 @pre-project and @pre-chown snapshots are a month stale and are NOT a" >&2
    echo "   Phase 5 baseline. A proof naming the wrong snapshot must fail, and does." >&2
    exit 2
  fi

  build_exprs

  echo "🧨 Phase 5 - junk gate, sweep (APPROVED LIST ONLY)"
  rule
  echo "  host:      $(hostname)"
  echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "  list:      $APPROVED_LIST"
  echo "  proof:     $SNAPSHOT_PROOF  (names $SNAPSHOT_NAME)"
  echo -e "  mode:      ${RED}sweep (MUTATES LIVE STATE)${NC}"
  echo ""

  echo "🔒 1. Re-deriving every listed row against FRESH state"
  rule
  local conflicts=0 listed=0
  local rrule rpath rtype rbytes raudio rreason rdest
  local real now_rule now_audio now_reason now_bytes r
  while IFS=$'\t' read -r rrule rpath rtype rbytes raudio rreason rdest; do
    [ -z "${rrule:-}" ] && continue
    listed=$((listed + 1))
    real="$(assert_in_scope "$rpath" "(sweep, approved row)")"

    if [ ! -e "$real" ]; then
      fail "$rrule $real no longer exists - the list is stale"
      conflicts=$((conflicts + 1))
      continue
    fi

    if [ "$rrule" = "R8" ]; then
      now_audio="$(count_matching "$real" audio)"
      if [ "$now_audio" != "$raudio" ]; then
        fail "$rrule $real audio count moved ${raudio} -> ${now_audio} since approval"
        conflicts=$((conflicts + 1))
      fi
      continue
    fi

    if [ "$rtype" = "dir" ]; then
      r="$(dir_rule "$real")"
      IFS=$'\t' read -r now_rule now_audio now_reason <<< "${r:-}"
    else
      r="$(file_rule "$real")"
      IFS=$'\t' read -r now_rule now_reason <<< "${r:-}"
      now_audio="0"
    fi

    if [ "${now_rule:-}" != "$rrule" ]; then
      fail "$rrule $real no longer matches its rule (now '${now_rule:-none}') - it changed since approval"
      conflicts=$((conflicts + 1))
      continue
    fi
    if [ "${now_audio:-0}" != "$raudio" ]; then
      fail "$rrule $real audio count moved ${raudio} -> ${now_audio} since approval"
      conflicts=$((conflicts + 1))
      continue
    fi
    now_bytes="$(path_bytes "$real")"
    if [ "$now_bytes" != "$rbytes" ]; then
      fail "$rrule $real size moved ${rbytes} -> ${now_bytes} since approval"
      conflicts=$((conflicts + 1))
      continue
    fi
  done < "$APPROVED_LIST"

  if [ "$conflicts" -gt 0 ]; then
    echo ""
    fail "aborting: ${conflicts} approved row(s) changed after approval. NOTHING MOVED, NOTHING REMOVED."
    fail "Move $APPROVED_LIST aside, re-run 'enumerate', and have the new list re-approved."
    exit 1
  fi
  pass "all ${listed} approved row(s) still match the state they were approved against"
  echo ""

  echo "📦 2. Moving approved rows into quarantine"
  rule
  local stamp batch idx=0 moved=0 move_errors=0
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  batch="$QUARANTINE/$stamp"
  mkdir -p "$batch"
  info "batch directory: $batch"

  # index -> quarantined path, for the removal stage. Two stages under ONE approval (D-13).
  local -a Q_PATHS=() Q_RULES=() Q_ORIGINS=()
  while IFS=$'\t' read -r rrule rpath rtype rbytes raudio rreason rdest; do
    [ -z "${rrule:-}" ] && continue
    real="$(assert_in_scope "$rpath" "(sweep, move)")"
    idx=$((idx + 1))

    local target
    if [ "$rrule" = "R8" ]; then
      case "${rdest:-}" in
        "_inbox/02-review") target="$REVIEW/$(basename -- "$real")" ;;
        "99-quarantine")    target="$QUARANTINE/$(basename -- "$real")" ;;
        *) fail "$rrule $real has an unrecognised destination '${rdest:-}' - left in place"
           move_errors=$((move_errors + 1)); continue ;;
      esac
    else
      target="$batch/$(printf '%03d' "$idx")__$(basename -- "$real")"
    fi

    if mv -- "$real" "$target" 2>/dev/null; then
      if [ -e "$target" ] && [ ! -e "$real" ]; then
        pass "moved $real -> $target"
        moved=$((moved + 1))
        if [ "$rrule" != "R8" ]; then
          Q_PATHS+=( "$target" ); Q_RULES+=( "$rrule" ); Q_ORIGINS+=( "$real" )
        fi
      else
        fail "$rrule move of $real did not land at $target - state is UNKNOWN, not moved"
        move_errors=$((move_errors + 1))
      fi
    else
      # Collect rather than abort: one stuck item must not strand the rest.
      fail "$rrule could not move $real - left in place"
      move_errors=$((move_errors + 1))
    fi
  done < "$APPROVED_LIST"
  echo ""

  echo "🗑  3. Removing what arrived in the quarantine batch"
  rule
  # R8 PROPOSAL rows are deliberately NOT here: they were moved to their proposed destination and
  # are content, not junk (D-20).
  local removed=0 remove_errors=0 i qpath
  for i in "${!Q_PATHS[@]}"; do
    qpath="${Q_PATHS[$i]}"
    if [ ! -e "$qpath" ]; then
      info "already gone: $qpath"
      continue
    fi
    if rm -rf -- "$qpath" 2>/dev/null && [ ! -e "$qpath" ]; then
      pass "removed ${Q_RULES[$i]} $(basename -- "$qpath")"
      removed=$((removed + 1))
    else
      fail "${Q_RULES[$i]} removal failed, still present: $qpath"
      remove_errors=$((remove_errors + 1))
    fi
  done
  echo ""

  echo "🔍 4. Asserting absence - the only instrument that is not subject to the ZFS lag"
  rule
  # ZFS frees space asynchronously and `zfs list` can lag a large removal by about 20 seconds, so a
  # reclaimed-space floor asserted here would be measuring the lag, not the work. Absence is exact.
  local absent_ok=0
  for i in "${!Q_ORIGINS[@]}"; do
    if [ -e "${Q_ORIGINS[$i]}" ]; then
      fail "still present at its original location: ${Q_ORIGINS[$i]}"
    else
      absent_ok=$((absent_ok + 1))
    fi
  done
  pass "${absent_ok} row(s) absent from their original location"
  info "reclaimed space is INFORMATIONAL only - ZFS frees asynchronously and can lag by ~20 s"
  echo ""

  echo "📊 5. Summary"
  rule
  echo "  rows approved:        ${listed}"
  echo "  moved:                ${moved}"
  echo "  move failures:        ${move_errors}   (target 0)"
  echo "  removed:              ${removed}"
  echo "  removal failures:     ${remove_errors}   (target 0)"
  echo "  quarantine batch:     ${batch}"
  echo ""

  if [ "$FAILURES" -gt 0 ]; then
    echo -e "${RED}❌ $FAILURES failed check(s)${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ sweep complete - every approved row acted on${NC}"
  return 0
}

case "$ACTION" in
  enumerate) do_enumerate ;;
  sweep)     do_sweep ;;
  *)         usage ;;
esac
