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
#   bash scripts/spike03-wrtag-arms.sh --self-test
#
#   --album  REQUIRED. A directory name directly under $SRC. Not a path - just the folder name.
#   --image  Container image reference. Default $WRTAG_IMAGE. THE THREE ARMS DIFFER ONLY HERE.
#   --class  A label for the output filenames, e.g. single-disc / multi-disc. Default "unclassed".
#   --mbid   Pin the MusicBrainz release. Held CONSTANT across the three tags of one disc class.
#   --yes    Pass wrtag's -yes, accepting a low-score match.
#   --self-test  Run the $SRC/$LIB fence against a table of known-good and known-bad paths, and
#            run instrument 2's manifest comparison against identical / differing / missing /
#            unreadable inputs, then exit. Needs no docker and writes only under $TMPDIR. It is
#            the regression check for CR-01 and WR-13.
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
#
#        THE FENCE IS EVALUATED ON THE RESOLVED PATH, NOT ON THE STRING (CR-01). It used to be
#        a pair of `case` patterns over the unresolved $LIB, and `find` resolves `..` through
#        the real filesystem before it acts - so
#            LIB=/mnt/fast/spike-03/wrtag-lib/../../../../etc
#        passed the allow-prefix guard AND the literal `spike-03` component guard, and
#        `find "$LIB" -mindepth 1 -delete` then emptied /etc. A trailing `/..` in a copy-pasted
#        LIB= was sufficient, and this header advertises LIB as a supported override. The
#        string guards are kept as defence in depth; what fence_eval() adds is that the path
#        is resolved FIRST and the fence is applied to what find will actually act on. A path
#        that cannot be resolved is a refusal, never a proceed. `--self-test` runs that fence
#        against the exact bypass string above and against the legitimate defaults.
#     3. `find "$SRC" "$LIB" -newer <stamp> -type f` must return ZERO lines. Cheap, and first.
#        It must also have BEEN ABLE TO LOOK (CR-02): the inputs are asserted present and
#        readable first, find's exit status is read rather than swallowed, and anything it
#        wrote to stderr is a refusal. "could not look" is reported as its own non-green
#        outcome and never as "0 files newer than the stamp" - CLAUDE.md § Health Checks.
#     4. A WHOLE-SUBTREE MANIFEST DIFF over all of $SRC and $LIB must be empty, on both a
#        `%p %s %T@` listing and a sha256sum of every file.
#
#        IT MUST ALSO HAVE BEEN ABLE TO COMPARE (WR-13). `diff` exits 0 identical, 1 differing
#        and >=2 ON TROUBLE - a missing or unreadable manifest - and on trouble it writes to
#        stderr and leaves STDOUT EMPTY. Read as `d="$(diff ... || true)"; [ -z "$d" ]`, that
#        empty stdout was reported as "identical before and after". Both manifests are now
#        asserted present, regular and readable first, diff's exit status is read rather than
#        swallowed, and >=2 is a COULD NOT LOOK outcome - non-green, non-zero - exactly as
#        control 3 does. CLAUDE.md § Health Checks.
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
SELFTEST=""

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
  say "  --self-test  Exercise the \$SRC/\$LIB fence and instrument 2's manifest comparison, then"
  say "               exit. No docker; writes only under \$TMPDIR."
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
    --self-test) SELFTEST="1"; shift ;;
    -h|--help) usage ;;
    *) say "unknown argument: $1"; usage ;;
  esac
done

# --- Preconditions -------------------------------------------------------------------------
# Every one of these is exit 2: they mean the measurement was never set up, which is a
# different answer from "the measurement was made and wrtag failed".
precheck_fail() { bad "$1"; exit 2; }

# --- Path resolution ------------------------------------------------------------------------
# CR-01. Resolve BEFORE checking. `find` resolves `..` and symlinks through the real
# filesystem, so a fence evaluated on the unresolved string is not a fence on what find acts
# on. Resolution that cannot be performed is a refusal, never a proceed.
#
# GNU `realpath -m` is the intended implementation - LXC 100, where this script runs, has it,
# and `-m` resolves components that do not exist yet. python3's os.path.realpath is a fallback
# with the same property, so `--self-test` also runs on a workstation without GNU coreutils
# (the same class of portability trap CLAUDE.md records for GNU `timeout` on macOS).
RESOLVED=""
resolve_or_die() { # $1 = label for the message  $2 = path -> sets RESOLVED
  local label="$1" path="$2" r=""
  [ -n "$path" ] || precheck_fail "$label is empty - refusing"
  if r="$(realpath -m -- "$path" 2>/dev/null)" && [ -n "$r" ]; then
    :
  elif r="$(python3 -c 'import os,sys; sys.stdout.write(os.path.realpath(sys.argv[1]))' \
              "$path" 2>/dev/null)" && [ -n "$r" ]; then
    :
  else
    precheck_fail "$label '$path' could not be resolved: no working 'realpath -m' and no
     python3. REFUSING rather than falling back to checking the unresolved string, which is
     exactly the defect CR-01 was."
  fi
  RESOLVED="$r"
}

# The fence itself, factored into a function so `--self-test` can exercise it without docker,
# without a filesystem and without running an arm. Returns 0 = inside the fence, 1 = refused.
# Sets FENCE_REAL (the resolved path) and FENCE_WHY (the refusal reason).
FENCE_REAL=""
FENCE_WHY=""
fence_eval() { # $1 = given path  $2 = allow prefix  $3 = required path component (may be empty)
  local given="$1" prefix="$2" need="$3" real="" preal=""
  FENCE_REAL=""
  FENCE_WHY=""

  # 1. THE AUTHORITATIVE CHECK (CR-01): the resolved path against the resolved allow prefix.
  #    The prefix is resolved too, so a symlinked mount root does not spuriously refuse a
  #    legitimate path.
  resolve_or_die "allow prefix" "$prefix"
  preal="$RESOLVED"
  resolve_or_die "path" "$given"
  real="$RESOLVED"
  FENCE_REAL="$real"
  case "$real/" in
    "$preal/"*) : ;;
    *) FENCE_WHY="resolves to '$real', which is outside '$preal/'"; return 1 ;;
  esac

  # 2. The required literal component, also on the RESOLVED path.
  if [ -n "$need" ]; then
    case "$real" in
      *"/$need/"*) : ;;
      *) FENCE_WHY="resolves to '$real', which has no '$need' path component"; return 1 ;;
    esac
  fi

  # 3. The ORIGINAL unresolved-string guard, kept as defence in depth rather than replaced.
  case "$given/" in
    "$prefix"*) : ;;
    *) FENCE_WHY="the given string is outside the allowed prefix '$prefix'"; return 1 ;;
  esac

  # 4. A literal `..` component has no legitimate place in either of these paths, and it is the
  #    exact shape that walked through both original guards. Refused by name so the message
  #    says what was wrong and not only where it landed. Deliberately LAST: check 1 already
  #    refuses every `..` that escapes, and this catches the ones that do not.
  case "$given" in
    *"/../"*|*"/.."|"../"*|"..")
      FENCE_WHY="contains a '..' path component - pass the resolved path instead"
      return 1
      ;;
  esac

  return 0
}

# --- Instrument 2's comparison primitive (WR-13) ----------------------------------------------
# WR-13. "COULD NOT COMPARE" IS NOT "IDENTICAL", AND IT IS NOT A PASS.
#
# This used to be `d="$(diff "$b" "$a" || true)"` followed by `[ -z "$d" ] && ok "identical"`.
# `diff` exits 0 when the files match, 1 when they differ, and >=2 ON TROUBLE - a manifest that
# was never written, one removed under it, an EACCES, a directory where a file was expected. On
# trouble it writes the reason to STDERR and leaves STDOUT EMPTY, so `|| true` swallowed the
# status and the emptiness test read the failure as "identical before and after" - a green tick
# on the instrument this script's header calls the strong one. With CR-02 unfixed, both
# wrote-nothing instruments could pass vacuously in the same run.
#
# Factored out of the reporting wrapper so `--self-test` can drive all three outcomes over real
# files without docker and without running an arm.
#
# Returns 0 = identical, 1 = differs (DIFF_OUT holds the diff), 2 = COULD NOT COMPARE
# (DIFF_WHY holds the reason). 2 is deliberately a distinct return value rather than folded into
# 1: the caller reports the two differently because they are different findings, and only one of
# them is about wrtag.
DIFF_OUT=""
DIFF_WHY=""
manifest_compare() { # $1 = before file  $2 = after file
  local b="$1" a="$2" f="" rc=0 errf="" err=""
  DIFF_OUT=""
  DIFF_WHY=""

  # Assert the inputs BEFORE looking, the same order CR-02 uses for instrument 1. These do not
  # replace reading diff's exit status - they name the failure precisely instead of leaving the
  # reader with a bare "rc=2". Note that a `-r` test passes for root on a mode-000 file, so the
  # status read below is the load-bearing half on LXC 100, where this script actually runs.
  for f in "$b" "$a"; do
    if [ ! -e "$f" ]; then
      DIFF_WHY="manifest '$f' does not exist - it was never captured, or something removed it"
      return 2
    fi
    if [ ! -f "$f" ]; then
      DIFF_WHY="manifest '$f' is not a regular file"
      return 2
    fi
    if [ ! -r "$f" ]; then
      DIFF_WHY="manifest '$f' is not readable"
      return 2
    fi
  done

  # diff's stderr is captured rather than discarded: on rc>=2 it carries the only description of
  # what went wrong, and it is quoted back to the operator.
  errf="$(mktemp "${TMPDIR:-/tmp}/spike03-diff-XXXXXX")" || {
    DIFF_WHY="could not create a temp file to capture diff's stderr"
    return 2
  }
  DIFF_OUT="$(diff -- "$b" "$a" 2>"$errf")" || rc=$?
  err="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"

  if [ "$rc" -ge 2 ]; then
    DIFF_WHY="diff could not compare '$b' and '$a' (rc=$rc)"
    [ -z "$err" ] || DIFF_WHY="$DIFF_WHY: $err"
    return 2
  fi
  # rc 0 or 1, but diff still complained. Anything on stderr from a diff that claims to have
  # succeeded is unexplained, and an unexplained instrument is not evidence.
  if [ -n "$err" ]; then
    DIFF_WHY="diff exited $rc but wrote to stderr, which is unexplained: $err"
    return 2
  fi
  if [ "$rc" -eq 1 ]; then
    return 1
  fi
  # Belt and braces: rc 0 with output on stdout should be impossible. If it ever happens the
  # files are not known to match, so do not claim they do.
  if [ -n "$DIFF_OUT" ]; then
    DIFF_WHY="diff exited 0 but printed a difference, which is unexplained"
    return 2
  fi
  return 0
}

# Self-test helper for the above. Kept beside manifest_compare so the two are read together and
# a future edit to one is not made without seeing the other. Always returns 0 and accumulates
# into MC_FAIL, so a failing case reports rather than aborting the remaining cases.
MC_FAIL=0
mc_check() { # $1 = expected: identical|differs|couldnotlook   $2 = before  $3 = after  $4 = desc
  local want="$1" b="$2" a="$3" desc="$4" rc=0 got=""
  manifest_compare "$b" "$a" || rc=$?
  case "$rc" in
    0) got="identical" ;;
    1) got="differs" ;;
    *) got="couldnotlook" ;;
  esac
  if [ "$got" = "$want" ]; then
    ok "$got (expected): $desc"
    [ "$got" != "couldnotlook" ] || say "        reason: $DIFF_WHY"
    return 0
  fi
  bad "INSTRUMENT 2 REGRESSION: expected $want, got $got: $desc"
  [ "$got" != "couldnotlook" ] || bad "        reason: $DIFF_WHY"
  MC_FAIL=$((MC_FAIL + 1))
  return 0
}

# --- Regression check for CR-01 and WR-13 -----------------------------------------------------
self_test() {
  local fails=0 rc=0 expect given prefix need desc got td
  say ""
  say "== spike03-wrtag-arms.sh --self-test: the \$SRC / \$LIB fence (CR-01) =="
  rule
  while IFS='|' read -r expect given prefix need desc; do
    case "${expect:-}" in ""|"#"*) continue ;; esac
    rc=0
    fence_eval "$given" "$prefix" "$need" || rc=1
    got="accept"
    [ "$rc" -eq 0 ] || got="refuse"
    if [ "$got" = "$expect" ]; then
      ok "$got (expected): $given"
      [ "$got" = "accept" ] || say "        reason: $FENCE_WHY"
      say "        $desc"
    else
      bad "FENCE REGRESSION: expected $expect, got $got: $given"
      bad "        $desc"
      fails=$((fails + 1))
    fi
  done <<'CASES'
refuse|/mnt/fast/spike-03/wrtag-lib/../../../../etc|/mnt/fast/spike-03/|spike-03|CR-01: the exact bypass string from the code review. It passed BOTH original string guards and `find -delete` would have emptied /etc.
refuse|/mnt/fast/spike-03/wrtag-lib/..|/mnt/fast/spike-03/|spike-03|A trailing `/..` in a copy-pasted LIB= - the cheapest form of the same bypass.
refuse|/mnt/fast/spike-03/wrtag-lib/../other|/mnt/fast/spike-03/|spike-03|Resolves back INSIDE the fence, so checks 1-3 pass; refused by the `..` component guard.
refuse|/etc|/mnt/fast/spike-03/|spike-03|Plainly outside the fence, no `..` involved.
refuse|/mnt/fast/wrtag-lib|/mnt/fast/spike-03/|spike-03|Inside /mnt/fast but outside the phase scratch root.
refuse|/mnt/tank/downloads/spike-03/wrtag-src/../../../../var/tmp|/mnt/tank/downloads/||SRC: `..` escaping the downloads allow-prefix.
accept|/mnt/fast/spike-03/wrtag-lib|/mnt/fast/spike-03/|spike-03|The legitimate $LIB default must still be accepted.
accept|/mnt/tank/downloads/spike-03/wrtag-src|/mnt/tank/downloads/||The legitimate $SRC default must still be accepted.
CASES

  # A symlink case, built at run time. Neither the unresolved-string guard nor the `..` guard
  # can see through a symlink; only check 1 can. This is what makes "resolve first" load
  # bearing rather than cosmetic.
  td="$(mktemp -d "${TMPDIR:-/tmp}/spike03-fence-XXXXXX")"
  mkdir -p "$td/root/spike-03" "$td/outside"
  ln -s "$td/outside" "$td/root/spike-03/escape"
  rc=0
  fence_eval "$td/root/spike-03/escape" "$td/root/spike-03/" "spike-03" || rc=1
  if [ "$rc" -eq 1 ]; then
    ok "refuse (expected): <tmp>/root/spike-03/escape -> <tmp>/outside"
    say "        reason: $FENCE_WHY"
    say "        A symlink out of the fence. Invisible to a string guard; caught by resolution."
  else
    bad "FENCE REGRESSION: a symlink out of the scratch root was ACCEPTED"
    fails=$((fails + 1))
  fi
  rm -f "$td/root/spike-03/escape"
  rmdir "$td/root/spike-03" "$td/root" "$td/outside" "$td" 2>/dev/null || true

  # --- Instrument 2's manifest comparison (WR-13) --------------------------------------------
  # Driven over REAL files rather than a table of strings, because the defect is in what `diff`
  # does with inputs it cannot read - which cannot be simulated with a string.
  local mt=""
  say ""
  say "== spike03-wrtag-arms.sh --self-test: instrument 2's manifest comparison (WR-13) =="
  rule
  MC_FAIL=0
  mt="$(mktemp -d "${TMPDIR:-/tmp}/spike03-manifest-XXXXXX")"

  printf 'a/one.mp3\t1\t1.0\na/two.mp3\t2\t2.0\n' > "$mt/before.meta"
  cp "$mt/before.meta" "$mt/after.meta"
  mc_check identical "$mt/before.meta" "$mt/after.meta" \
    "IDENTICAL manifests - the green case, which must still be green."

  printf 'a/one.mp3\t1\t1.0\na/two.mp3\t2\t2.0\na/three.mp3\t3\t3.0\n' > "$mt/after.meta"
  mc_check differs "$mt/before.meta" "$mt/after.meta" \
    "DIFFERING manifests - a file appeared, so the dry run was not dry."

  mc_check couldnotlook "$mt/absent.meta" "$mt/after.meta" \
    "MISSING BEFORE - the exact WR-13 defect. diff exits 2, writes to stderr and leaves stdout
        empty, and the old \`\$(diff ... || true)\` read that empty stdout as 'identical'."
  mc_check couldnotlook "$mt/before.meta" "$mt/absent.meta" \
    "MISSING AFTER - the same defect from the other side."

  mkdir -p "$mt/adirectory.meta"
  mc_check couldnotlook "$mt/before.meta" "$mt/adirectory.meta" \
    "A DIRECTORY where a manifest should be. Unlike mode 000 below, this case is constructible
        as root, so it still runs on LXC 100 where this script is actually used."

  if [ "$(id -u)" = "0" ]; then
    warn "SKIPPED as root: an UNREADABLE manifest (mode 000)."
    say  "        root bypasses the read permission bit, so the case cannot be constructed here -"
    say  "        reported rather than silently counted as a pass (CLAUDE.md § Health Checks). It"
    say  "        runs as a non-root user; and the rc>=2 branch catches an EACCES on any host,"
    say  "        which is what makes the instrument sound where the \`-r\` test cannot be."
  else
    cp "$mt/before.meta" "$mt/noread.meta"
    chmod 000 "$mt/noread.meta"
    mc_check couldnotlook "$mt/noread.meta" "$mt/after.meta" \
      "An UNREADABLE manifest (mode 000)."
    chmod 644 "$mt/noread.meta"
  fi

  if [ -d "$mt" ]; then rm -rf "$mt"; fi
  fails=$((fails + MC_FAIL))

  say ""
  if [ "$fails" -ne 0 ]; then
    bad "self-test: $fails case(s) FAILED"
    return 1
  fi
  ok "self-test: every fence and instrument-2 case behaved as expected"
  return 0
}

if [ -n "$SELFTEST" ]; then
  if self_test; then exit 0; else exit 1; fi
fi

[ -n "$ALBUM" ] || usage

command -v docker >/dev/null 2>&1 \
  || precheck_fail "docker not found - this script runs ON LXC 100, not the workstation"

if ! fence_eval "$SRC" "$SRC_ALLOW_PREFIX" ""; then
  precheck_fail "SRC '$SRC' $FENCE_WHY - refusing"
fi
SRC="$FENCE_REAL"

if ! fence_eval "$LIB" "$LIB_ALLOW_PREFIX" "spike-03"; then
  precheck_fail "LIB '$LIB' $FENCE_WHY - refusing.
     The path format is rooted at /music/library, so whatever is bound there IS the write
     target. It must be scratch (D-22). \$LIB is also emptied with \`find -delete\` before
     every arm, so this fence is evaluated on the RESOLVED path (CR-01)."
fi
LIB="$FENCE_REAL"

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
# $LIB is the RESOLVED path by now: fence_eval() checked it against the resolved
# LIB_ALLOW_PREFIX and against the literal 'spike-03' component, and assigned the resolved
# value back over $LIB. The component check is repeated here, immediately beside the delete,
# because that is where a future edit will look for it - and because after CR-01 a guard that
# is not adjacent to the dangerous call is a guard that gets left behind by a refactor.
# -delete rather than `rm -rf` so a bug cannot turn into a recursive removal of an unexpected
# root.
case "$LIB" in
  */spike-03/*) : ;;
  *) precheck_fail "refusing to empty '$LIB' - it does not contain a spike-03 path component" ;;
esac
# The delete's own failures are NOT hidden. `2>/dev/null || true` here used to mean that an
# EACCES subtree, a read-only remount or a vanished $LIB all looked like a clean empty - and
# the emptiness assertion three lines down would then pass vacuously on a stale tree.
DEL_ERR="$OUT/wrtag-${ARM}.lib-empty.err"
DEL_RC=0
find "$LIB" -mindepth 1 -delete 2>"$DEL_ERR" || DEL_RC=$?
if [ "$DEL_RC" -ne 0 ] || [ -s "$DEL_ERR" ]; then
  bad "could not empty \$LIB (find -delete rc=$DEL_RC) - refusing to run this arm:"
  sed 's/^/         /' "$DEL_ERR" >&2 || true
  exit 1
fi
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

# CR-02. "COULD NOT LOOK" IS NOT "NOTHING CHANGED", AND IT IS NOT A PASS.
#
# This used to be `find ... 2>/dev/null || true` feeding a count. `2>/dev/null` discarded the
# error and `|| true` discarded the exit code, so EVERY failure mode of find - $SRC gone, $LIB
# gone, a re-materialised bind mount pointing at a vanished inode (03-05 finding 3, and the
# realistic trigger on this estate), EACCES on a subtree, the stamp deleted - produced an empty
# result, a zero count and a green tick claiming the dry run wrote nothing. That is the exact
# failure CLAUDE.md § Health Checks forbids, inside the assertion this script exists to make,
# and it is the first of the four controls the header claims.
#
# So: assert the inputs are there and readable BEFORE looking, then read find's exit status
# instead of swallowing it, and route "could not look" to its own non-green outcome. Note the
# house rule that `cmd | wc -l` silently exits 0 - `set -euo pipefail` is set at the top of
# this file, and the count below is taken from an already-captured string, not from a pipeline
# whose head could have failed unnoticed.
INSTR1_BLIND=""
for probe_dir in "$SRC" "$LIB"; do
  if [ ! -d "$probe_dir" ]; then
    INSTR1_BLIND="'$probe_dir' is not a directory (vanished, or a stale bind mount)"
    break
  fi
  if [ ! -r "$probe_dir" ] || [ ! -x "$probe_dir" ]; then
    INSTR1_BLIND="'$probe_dir' is not readable and searchable"
    break
  fi
done
if [ -z "$INSTR1_BLIND" ] && [ ! -f "$STAMP" ]; then
  INSTR1_BLIND="the stamp '$STAMP' is gone, so -newer has no reference"
fi

NEWER_ERR="$OUT/wrtag-${ARM}.find-newer.err"
: > "$NEWER_ERR"
if [ -n "$INSTR1_BLIND" ]; then
  bad "instrument 1 COULD NOT LOOK: $INSTR1_BLIND"
  bad "  This is NOT a pass. 'could not look' is a distinct outcome from 'nothing changed'"
  bad "  (CLAUDE.md § Health Checks), and the wrote-nothing claim is UNPROVEN for this arm."
  FAILED=1
else
  NEWER_RC=0
  NEWER="$(find "$SRC" "$LIB" -newer "$STAMP" -type f 2>"$NEWER_ERR")" || NEWER_RC=$?
  if [ "$NEWER_RC" -ne 0 ] || [ -s "$NEWER_ERR" ]; then
    bad "instrument 1 COULD NOT LOOK (find rc=$NEWER_RC) - this is NOT a pass:"
    sed 's/^/         /' "$NEWER_ERR" >&2 || true
    bad "  The wrote-nothing claim is UNPROVEN for this arm, which is not the same as false."
    FAILED=1
  elif [ -z "$NEWER" ]; then
    ok "instrument 1 (find -newer, \$SRC and \$LIB): 0 files newer than the stamp"
  else
    NEWER_COUNT="$(printf '%s\n' "$NEWER" | grep -c . || true)"
    bad "instrument 1: $NEWER_COUNT files are newer than the stamp - THE DRY RUN WROTE:"
    printf '%s\n' "$NEWER" | sed 's/^/         /'
    FAILED=1
  fi
fi

# --- Instrument 2: whole-subtree manifest diff ---------------------------------------------
manifest "$SRC" src after
manifest "$LIB" lib after

# WR-13. The comparison itself is manifest_compare(), defined beside the fence near the top of
# this file so `--self-test` can drive all three of its outcomes without docker. This is only
# the reporting half: 0 identical, 1 differs, >=2 COULD NOT COMPARE. The last is reported in the
# same vocabulary CR-02 gave instrument 1, so the two instruments read consistently and neither
# can be mistaken for the other.
diff_manifest() { # $1 = label  $2 = kind (meta|sha)
  local b="$MANIFESTS/${ARM}.$1.before.$2" a="$MANIFESTS/${ARM}.$1.after.$2" rc=0
  manifest_compare "$b" "$a" || rc=$?
  case "$rc" in
    0)
      ok "instrument 2 (${1}.${2} manifest): identical before and after"
      return 0
      ;;
    1)
      bad "instrument 2 (${1}.${2} manifest): CHANGED - the dry run was not dry:"
      printf '%s\n' "$DIFF_OUT" | head -n 40 | sed 's/^/         /'
      return 1
      ;;
    *)
      bad "instrument 2 (${1}.${2} manifest) COULD NOT LOOK: $DIFF_WHY"
      bad "  This is NOT a pass. 'could not look' is a distinct outcome from 'nothing changed'"
      bad "  (CLAUDE.md § Health Checks), and the wrote-nothing claim is UNPROVEN for this arm."
      return 1
      ;;
  esac
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
  bad "ARM ${ARM}: WROTE SOMETHING, or the wrote-nothing assertion COULD NOT BE MADE."
  bad "Read the instrument lines above - the two are different findings and only one of them"
  bad "is about wrtag. Exiting 1."
  exit 1
fi
ok "ARM ${ARM}: ran and wrote nothing, on both mounts, by both instruments."
say "  container exit code was $RC - recorded as the measurement, not as a script failure."
exit 0
