#!/usr/bin/env bash
# spike03-wrtag-arms.sh - Phase 3 criterion 3: run wrtag's path-format disqualifier at ONE image
#                         tag, on ONE album, and prove the dry run wrote nothing.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident because it drives `docker run` and reads two bind-mount trees that only exist
#   there. Nothing here is delegated to atlantis: unlike the reflink copy in
#   scripts/spike03-variant-survey.sh, every path this script touches is readable and writable
#   from inside the container, and no zfs call is needed.
#
# Usage:
#   bash scripts/spike03-wrtag-arms.sh --album <name> [--image <ref>] [--class <label>]
#                                      [--mbid <uuid>] [--yes]
#
#   --album  REQUIRED. A directory name directly under $SRC. Not a path - just the folder name.
#   --image  Container image reference. Default $WRTAG_IMAGE. THE THREE ARMS DIFFER ONLY HERE.
#   --class  A label for the output filenames, e.g. single-disc / multi-disc. Default "unclassed".
#   --mbid   Pin the MusicBrainz release. Held CONSTANT across the three tags of one disc class.
#   --yes    Pass wrtag's -yes, accepting a low-score match.
#
#   The three tags are three invocations of ONE script, not three scripts. That is the point:
#   if the arms differed in any other way the comparison would be measuring the difference
#   rather than the version.
#
# WHY --mbid EXISTS, AND WHY IT IS NOT A THUMB ON THE SCALE
#   Measured here, 2026-09-03, on the FIRST unpinned arm: a 21-track, no-disc-tag,
#   track="N/21" album folder - about as unambiguously single-disc as source material gets -
#   was resolved by MusicBrainz to a TWO-MEDIUM 12" vinyl release (11 + 10). wrtag issues
#   `...&limit=1&query=...tracks:(21)^10` and takes what comes back.
#
#   So the disc class of an arm IS NOT A PROPERTY OF THE FOLDER. It is a property of whichever
#   release MusicBrainz happened to return, which varies with the MB database and with the day.
#   An unpinned experiment cannot hold the disc class constant across three tags, and an
#   acceptance criterion of the form "the single-disc arm renders X" is then unfalsifiable.
#
#   --mbid pins the release, so the ONLY difference between the three tags of a class is the
#   image, and the ONLY difference between the two classes is len(.Release.Media). That is the
#   variable criterion 3 is about. It does not flatter any version: the same MBID is given to
#   all three tags.
#
# WHAT THIS MEASURES (Phase 3, criterion 3)
#   The repo pins sentriz/wrtag to v0.20.0 behind a Renovate rule (renovate.json5:91) whose
#   stated reason is "v0.30.0 changed path-format fields". Criterion 3 asks whether that pin is
#   inverted. The 0.x version number, the current container's brokenness and the age of the
#   Renovate rule are ALL EXPLICITLY NON-EVIDENCE. Only a rendered path is evidence.
#
#   So: same album, same path format, same command, three tags. Record what each renders.
#
# THE PATH FORMAT IS READ FROM THE FILE, NEVER RE-TYPED
#   $WRTAG_YAML is parsed at run time for the line beginning `- WRTAG_PATH_FORMAT=` and
#   everything after the FIRST `=` is taken byte-for-byte, Go template braces and all. A re-typed
#   copy would measure a string this repo does not use, and the whole exercise would prove
#   nothing about this repo's configuration. The sha256 of the extracted value is printed in the
#   banner and belongs in the evidence file, so a reader can re-extract and compare.
#
#   $WRTAG_YAML is overridable ONLY so an ablation arm can point at a differently-formatted
#   file through the SAME extraction code path. Whatever file is used, its path and the sha256
#   of what was extracted are printed. There is no way to pass a format string on the command
#   line, and no format string is embedded in this file.
#
# WHY -dry-run IS SAFE, AND WHY THAT IS NOT THE ONLY CONTROL
#   In source, `-dry-run` makes op.CanModifyDest() false, which skips wrtag.go:267's
#   tags.WriteTags(destPath, destTags, tags.Clear) entirely; cover fetching is gated on the same
#   predicate. That is a source read, and a source read is not a run.
#
#   So there are four independent controls, and the last two are asserted per arm:
#     1. $SRC is bind-mounted :ro. A `move` consumes its source; the mount layer refuses it
#        whether or not -dry-run behaves as documented.
#     2. $LIB is a SCRATCH destination under /mnt/fast/spike-03. D-22 requires the target cannot
#        be the real library, and this repo's path format is rooted at /music/library - so
#        whatever /music/library is bound to IS the target. It is never the real library, and
#        this script refuses to start unless $LIB is inside the phase's own scratch root.
#     3. `find "$SRC" "$LIB" -newer <stamp> -type f` must return ZERO lines. Cheap, and first.
#     4. A WHOLE-SUBTREE MANIFEST DIFF over all of $SRC and $LIB must be empty, on both a
#        `%p %s %T@` listing and a sha256sum of every file.
#
#   Instrument 4 exists because instrument 3 alone is the weakest evidence in this phase: it
#   passes a tool that preserves mtimes, and it passes any write that lands outside whatever
#   files happened to be sampled. The five-file spot hash used earlier in this phase is retired
#   for the same reason - it can only see the five files it looked at. The manifest sees
#   content, size, mtime, additions AND deletions across every file in both trees.
#
#   Both assertions run PER ARM, not once at the end, so a single writing arm is attributable to
#   the tag that wrote.
#
# NETWORK
#   The container gets docker's default bridge. `--network none` is NOT usable: wrtag's only
#   metadata source is MusicBrainz and it must reach musicbrainz.org to match anything at all.
#   This is recorded rather than hidden - the arms DO reach the network, and a run that cannot
#   is a different measurement.
#
# EXIT-CODE CONVENTION (inherited from scripts/check-music-freeze.sh):
#   0  the arm ran and wrote nothing
#   1  the arm wrote something, or the wrote-nothing assertion could not be made
#   2  usage error, a missing album, a refused $SRC/$LIB, or $WRTAG_PATH_FORMAT could not be
#      extracted from $WRTAG_YAML
#
#   A WRTAG TEMPLATE ERROR IS NOT A SCRIPT FAILURE. Nor is a startup path-format validation
#   refusal, nor a non-zero container exit. Those ARE the measurement: they are captured,
#   reported and recorded, and this script still exits 0 for them. Criterion 3 asks what wrtag
#   does with this repo's format; "it refused" and "it rendered garbage" are both answers.
#
# Idempotent:
#   A re-run of any arm reproduces the same rendered paths and again writes nothing. $LIB is
#   emptied before every arm and the emptied-ness is asserted and recorded, so no arm can
#   inherit a previous arm's output and no arm's wrote-nothing assertion can be contaminated by
#   one. The per-arm output files are overwritten, not appended.
#
#   The one thing NOT under this script's control is MusicBrainz: a different match on a
#   different day renders a different path. The matched release MBID is captured for exactly
#   that reason.

set -euo pipefail

# --- Constants (${VAR:-default} so the arms differ only by image tag) ---------------------
WRTAG_IMAGE="${WRTAG_IMAGE:-sentriz/wrtag:v0.20.0}"
WRTAG_YAML="${WRTAG_YAML:-stacks/selfhosted/music/wrtag.yaml}"
SRC="${SRC:-/mnt/tank/downloads/spike-03/wrtag-src}"
LIB="${LIB:-/mnt/fast/spike-03/wrtag-lib}"
OUT="${OUT:-/mnt/fast/spike-03/out}"
MANIFESTS="${MANIFESTS:-$OUT/manifests}"

# Positive allow-lists, not deny-lists. A deny-list here would have to name the real library
# path, and this file must contain no reference to it (D-20/D-22: a script that cannot spell
# the library cannot be edited into mounting it by accident). An allow-list is also strictly
# stronger - it refuses every path outside the phase's own scratch roots, not just one.
SRC_ALLOW_PREFIX="${SRC_ALLOW_PREFIX:-/mnt/tank/downloads/}"
LIB_ALLOW_PREFIX="${LIB_ALLOW_PREFIX:-/mnt/fast/spike-03/}"

ALBUM=""
CLASS="unclassed"
MBID=""
YES=""

say()  { printf '%s\n' "$*"; }
ok()   { printf '  \342\234\223 %s\n' "$*"; }
bad()  { printf '  \342\234\227 %s\n' "$*"; }
warn() { printf '  \342\232\240 %s\n' "$*"; }
rule() { printf '  %s\n' "----------------------------------------------------------------"; }

usage() {
  say "Usage: bash scripts/spike03-wrtag-arms.sh --album <name> [--image <ref>] [--class <label>]"
  say "                                          [--mbid <uuid>] [--yes]"
  say ""
  say "  --album  REQUIRED. A directory name directly under \$SRC (not a path)."
  say "  --image  Container image reference. Default: $WRTAG_IMAGE"
  say "  --class  Label used in the output filenames. Default: $CLASS"
  say "  --mbid   Pin the MusicBrainz release; held constant across the three tags of a class."
  say "  --yes    Pass wrtag's -yes (accept a low-score match)."
  say ""
  say "  env: WRTAG_IMAGE, WRTAG_YAML, SRC, LIB, OUT, MANIFESTS,"
  say "       SRC_ALLOW_PREFIX, LIB_ALLOW_PREFIX"
  say ""
  say "  exit 0 = the arm ran and wrote nothing"
  say "  exit 1 = the arm wrote something, or the assertion could not be made"
  say "  exit 2 = usage error, missing album, refused path, or no path format in \$WRTAG_YAML"
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --album) ALBUM="${2:-}"; shift 2 || usage ;;
    --image) WRTAG_IMAGE="${2:-}"; shift 2 || usage ;;
    --class) CLASS="${2:-}"; shift 2 || usage ;;
    --mbid)  MBID="${2:-}"; shift 2 || usage ;;
    --yes)   YES="1"; shift ;;
    -h|--help) usage ;;
    *) say "unknown argument: $1"; usage ;;
  esac
done

[ -n "$ALBUM" ] || usage

# --- Preconditions -------------------------------------------------------------------------
# Every one of these is exit 2: they mean the measurement was never set up, which is a
# different answer from "the measurement was made and wrtag failed".
precheck_fail() { bad "$1"; exit 2; }

command -v docker >/dev/null 2>&1 \
  || precheck_fail "docker not found - this script runs ON LXC 100, not the workstation"

case "$SRC/" in
  "$SRC_ALLOW_PREFIX"*) : ;;
  *) precheck_fail "SRC '$SRC' is outside the allowed prefix '$SRC_ALLOW_PREFIX' - refusing" ;;
esac
case "$LIB/" in
  "$LIB_ALLOW_PREFIX"*) : ;;
  *) precheck_fail "LIB '$LIB' is outside the allowed prefix '$LIB_ALLOW_PREFIX' - refusing.
     The path format is rooted at /music/library, so whatever is bound there IS the write
     target. It must be scratch (D-22)." ;;
esac

[ -d "$SRC" ] || precheck_fail "SRC does not exist: $SRC"
[ -d "$LIB" ] || precheck_fail "LIB does not exist: $LIB"

# The album check is deliberately early and deliberately exit 2: a typo'd album name must not
# be reported as a wrtag finding.
if [ ! -d "$SRC/$ALBUM" ]; then
  precheck_fail "album not found: $SRC/$ALBUM"
fi

[ -f "$WRTAG_YAML" ] || precheck_fail "path-format file not found: $WRTAG_YAML"

mkdir -p "$OUT" "$MANIFESTS"

# --- Extract WRTAG_PATH_FORMAT from the file, byte-for-byte --------------------------------
# "Everything after the first =" on the first line whose stripped form begins with
# `- WRTAG_PATH_FORMAT=`. sed removes up to and including the first `=` and touches nothing
# after it, so the Go template braces, the spaces inside them and the trailing {{ .Ext }}
# survive exactly as written.
PF_LINE="$(grep -m1 -E '^[[:space:]]*-[[:space:]]*WRTAG_PATH_FORMAT=' "$WRTAG_YAML" || true)"
[ -n "$PF_LINE" ] \
  || precheck_fail "no line matching '- WRTAG_PATH_FORMAT=' in $WRTAG_YAML"
PF="$(printf '%s' "$PF_LINE" | sed -e 's/^[^=]*=//')"
[ -n "$PF" ] \
  || precheck_fail "the WRTAG_PATH_FORMAT line in $WRTAG_YAML has an empty value"

PF_SHA="$(printf '%s' "$PF" | sha256sum | awk '{print $1}')"
PF_LEN="${#PF}"

TAG="${WRTAG_IMAGE##*:}"
ARM="${TAG}-${CLASS}"
STDOUT_FILE="$OUT/wrtag-${ARM}.stdout"
STDERR_FILE="$OUT/wrtag-${ARM}.stderr"
STAMP="$OUT/.wrtag-stamp-${ARM}"

# --- Run banner ----------------------------------------------------------------------------
say ""
say "== spike03 wrtag arm: ${ARM} =="
rule
say "  image            : $WRTAG_IMAGE"
say "  album            : $ALBUM"
say "  disc class       : $CLASS"
say "  source (ro)      : $SRC        -> /music/source"
say "  library (rw)     : $LIB        -> /music/library   [SCRATCH - never the real library]"
say "  path-format file : $WRTAG_YAML"
say "  path-format sha  : $PF_SHA  (${PF_LEN} bytes, read from the file, never re-typed)"
say "  path format      :"
printf '      %s\n' "$PF"
say "  pinned mbid      : ${MBID:-<none - MusicBrainz chooses, and the disc class is NOT controlled>}"
say "  low-score -yes   : ${YES:+passed}${YES:-not passed}"
say "  network          : docker default bridge (wrtag MUST reach musicbrainz.org)"
say "  stdout           : $STDOUT_FILE"
say "  stderr           : $STDERR_FILE"
say ""

# --- Empty $LIB and prove it is empty ------------------------------------------------------
# Guarded twice: LIB_ALLOW_PREFIX above, and the literal 'spike-03' component here. -delete
# rather than `rm -rf` so a bug cannot turn into a recursive removal of an unexpected root.
case "$LIB" in
  */spike-03/*) : ;;
  *) precheck_fail "refusing to empty '$LIB' - it does not contain a spike-03 path component" ;;
esac
find "$LIB" -mindepth 1 -delete 2>/dev/null || true
LIB_ENTRIES="$(find "$LIB" -mindepth 1 | wc -l | tr -d ' ')"
if [ "$LIB_ENTRIES" -ne 0 ]; then
  bad "\$LIB is not empty at the start of this arm ($LIB_ENTRIES entries) - refusing to run,"
  bad "because a wrote-nothing assertion against a dirty destination proves nothing."
  exit 1
fi
ok "\$LIB emptied and verified empty at the start of this arm (0 entries)"

# --- Whole-subtree manifests, BEFORE -------------------------------------------------------
# %p %s %T@ catches path, size and mtime; the sha catches content. Together they catch
# additions and deletions too, because a vanished or new path changes both listings.
manifest() { # $1 = subtree  $2 = label  $3 = when
  LC_ALL=C find "$1" -type f -printf '%p\t%s\t%T@\n' \
    | LC_ALL=C sort > "$MANIFESTS/${ARM}.$2.$3.meta"
  LC_ALL=C find "$1" -type f -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 -r sha256sum > "$MANIFESTS/${ARM}.$2.$3.sha"
}

manifest "$SRC" src before
manifest "$LIB" lib before
SRC_FILES="$(wc -l < "$MANIFESTS/${ARM}.src.before.meta" | tr -d ' ')"
ok "before-manifests captured: \$SRC $SRC_FILES files, \$LIB 0 files"

# --- Stamp, then run -----------------------------------------------------------------------
# The stamp is created OUTSIDE both mounts, so taking it cannot itself perturb what it measures.
rm -f "$STAMP"
touch "$STAMP"
sleep 1   # 1s so a same-second write cannot slip under -newer's granularity

WRTAG_ARGS=(move -dry-run)
[ -n "$MBID" ] && WRTAG_ARGS+=(-mbid "$MBID")
[ -n "$YES" ] && WRTAG_ARGS+=(-yes)
WRTAG_ARGS+=("/music/source/$ALBUM")

say ""
say "  running: wrtag ${WRTAG_ARGS[*]}"
RC=0
docker run --rm \
  --security-opt no-new-privileges:true \
  -v "$SRC":/music/source:ro \
  -v "$LIB":/music/library:rw \
  -e WRTAG_PATH_FORMAT="$PF" \
  -e WRTAG_LOG_LEVEL=debug \
  "$WRTAG_IMAGE" \
  wrtag "${WRTAG_ARGS[@]}" \
  >"$STDOUT_FILE" 2>"$STDERR_FILE" || RC=$?

say "  container exit code: $RC"
if [ "$RC" -ne 0 ]; then
  warn "non-zero container exit - THIS IS THE MEASUREMENT, not a script failure."
  warn "The path-format validation result and any template error are in the capture files."
fi
say ""
say "  --- stderr (first 40 lines) ---"
head -n 40 "$STDERR_FILE" | sed 's/^/      /' || true
say "  --- stdout (first 20 lines) ---"
head -n 20 "$STDOUT_FILE" | sed 's/^/      /' || true
say ""

# Record the container exit code beside the captures so the evidence file does not have to
# depend on this transcript.
printf 'arm=%s image=%s album=%s class=%s mbid=%s yes=%s container_exit=%s path_format_file=%s path_format_sha256=%s\n' \
  "$ARM" "$WRTAG_IMAGE" "$ALBUM" "$CLASS" "${MBID:-none}" "${YES:-0}" "$RC" "$WRTAG_YAML" "$PF_SHA" \
  > "$OUT/wrtag-${ARM}.meta"

# --- Instrument 1: find -newer, on BOTH mounts ---------------------------------------------
say "== wrote-nothing assertion =="
rule
FAILED=0
NEWER="$(find "$SRC" "$LIB" -newer "$STAMP" -type f 2>/dev/null || true)"
NEWER_COUNT="$(printf '%s' "$NEWER" | grep -c . || true)"
if [ "${NEWER_COUNT:-0}" -eq 0 ]; then
  ok "instrument 1 (find -newer, \$SRC and \$LIB): 0 files newer than the stamp"
else
  bad "instrument 1: $NEWER_COUNT files are newer than the stamp - THE DRY RUN WROTE:"
  printf '%s\n' "$NEWER" | sed 's/^/         /'
  FAILED=1
fi

# --- Instrument 2: whole-subtree manifest diff ---------------------------------------------
manifest "$SRC" src after
manifest "$LIB" lib after

diff_manifest() { # $1 = label  $2 = kind (meta|sha)
  local b="$MANIFESTS/${ARM}.$1.before.$2" a="$MANIFESTS/${ARM}.$1.after.$2" d
  d="$(diff "$b" "$a" || true)"
  if [ -z "$d" ]; then
    ok "instrument 2 (${1}.${2} manifest): identical before and after"
    return 0
  fi
  bad "instrument 2 (${1}.${2} manifest): CHANGED - the dry run was not dry:"
  printf '%s\n' "$d" | head -n 40 | sed 's/^/         /'
  return 1
}

diff_manifest src meta || FAILED=1
diff_manifest src sha  || FAILED=1
diff_manifest lib meta || FAILED=1
diff_manifest lib sha  || FAILED=1

LIB_AFTER="$(find "$LIB" -mindepth 1 | wc -l | tr -d ' ')"
say "  \$LIB entries after the arm: $LIB_AFTER (target 0)"
if [ "$LIB_AFTER" -ne 0 ]; then
  bad "\$LIB is not empty after the arm"
  FAILED=1
fi

rm -f "$STAMP"

say ""
if [ "$FAILED" -ne 0 ]; then
  bad "ARM ${ARM}: WROTE SOMETHING. Exiting 1."
  exit 1
fi
ok "ARM ${ARM}: ran and wrote nothing, on both mounts, by both instruments."
say "  container exit code was $RC - recorded as the measurement, not as a script failure."
exit 0
