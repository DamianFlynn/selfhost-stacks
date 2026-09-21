#!/usr/bin/env bash
# phase06-oracle.sh - Phase 6 CONF-03 / CONF-06: make "the intended tree" a FACT.
#
# Where it runs:
#   ON THE WORKSTATION (macOS), from the repo root. It ssh-delegates every measurement to
#   LXC 100 (root@172.16.1.159) and `docker exec`s into the `beets-flask` container for the
#   beets half. Nothing is computed locally except the JUDGING, which is deliberate: every
#   function that decides green/red takes local files and local arguments, so `--self-test`
#   drives the same code the real run does, without docker and without ssh.
#
# Usage:
#   bash scripts/phase06-oracle.sh --self-test     # judge the judge; no docker, no ssh
#   bash scripts/phase06-oracle.sh --baseline      # capture BEFORE state only; imports nothing
#   bash scripts/phase06-oracle.sh --run           # the full oracle
#   bash scripts/phase06-oracle.sh --help
#
#   --run is REQUIRED to do anything live. A script whose default action is "drive an import
#   into a container that mounts the real library" is a footgun; no-args prints usage and exits 2.
#
# EXIT CODES - stated explicitly, because three of the four are not "failure"
#   0  the oracle ran, the diff against the committed tree was EMPTY, and no assertion went red
#   1  RED: the diff was non-empty, an assertion failed, or the dry run WROTE SOMETHING
#   2  usage error, or a precheck refusal (dirty destination, unreachable host, missing fixture)
#   3  UNKNOWN, not green: the positive control failed, so the measurement could not be trusted
#      and THE DIFF WAS NOT EVALUATED. This is a distinct outcome from 1 and it is never a pass.
#      CLAUDE.md § Health Checks: "could not look" is kept distinct from "nothing is wrong".
#
# ==============================================================================================
# WHY `beet import --pretend` IS NOT THE INSTRUMENT, AND `beet move -p` IS  (D-33)
# ==============================================================================================
# CONF-06's requirement text names `--pretend`. It cannot do the job, and this is not an opinion:
#
#   if self.config["pretend"]:
#       stages += [stagefuncs.log_files(self)]
#   else:
#       ... group_albums / lookup_candidates / user_query / import_asis ...
#   [SOURCE: beets/importer/session.py@v2.12.0:201-240]
#
#   def log_files(session, task):
#       log.info("Album: {}", displayable_path(task.paths[0]))
#       for item in task.items: log.info("  {}", displayable_path(item["path"]))
#   [SOURCE: beets/importer/stages.py@v2.12.0:266-274]
#
# The pipeline is `read_tasks -> log_files`. `lookup_candidates` is never in it, so NO DESTINATION
# IS EVER COMPUTED. Every line it prints is a SOURCE path. It prints one line per file and exits
# 0, which is exactly why it reads as a pass (Pitfall 1).
#
# The instrument that DOES evaluate the full `paths:` stanza is:
#
#   if pretend:
#       show_path_changes([(item.path, item.destination(basedir=dest)) for ...])
#   [SOURCE: beets/ui/commands/move.py@v2.12.0]
#
# `item.destination()` is the SAME call a real import makes, so `beet move -p` exercises the path
# rules, `%aunique{}`, `replace:`, `asciify_paths`, `legalize_path` and `max_filename_length`.
# Both commands are read-only. The mechanical discriminator between the two transcripts is that
# `move -p` output contains ` -> ` and the string `/media/Music/`, and a `--pretend` transcript
# contains neither. The positive control below asserts exactly that, so a `--pretend` transcript
# handed to this script produces UNKNOWN (exit 3) rather than a zero-diff.
#
# ==============================================================================================
# THE OVERRIDE CONTRACT
# ==============================================================================================
# Every knob below is `${VAR:-default}` and every one of them can only make the verdict REDDER:
# a wrong host, a wrong container or a wrong output directory produces a refusal or an UNKNOWN,
# never a pass. TWO PATHS ARE PLAIN CONSTANTS AND ARE DELIBERATELY NOT OVERRIDABLE:
#
#     EXPECTED_TREE   .planning/phases/06-tagger-configuration-and-dry-run/06-EXPECTED-TREE.txt
#     SAMPLE_DOC      .planning/phases/06-tagger-configuration-and-dry-run/06-SAMPLE.md
#
# An override on either could manufacture a pass by pointing the diff at a file generated from
# the run it is supposed to judge. The whole value of the fixture is the commit that predates
# the run; a knob that lets a caller substitute it destroys that value silently.
#
# The sampled folder list is READ FROM 06-SAMPLE.md, never re-typed here, for the same reason
# scripts/spike03-wrtag-arms.sh reads its path format from the file it is measuring: a re-typed
# copy measures a set this project does not use.
#
# ==============================================================================================
# THE THREE-LAYER "WROTE NOTHING" PROOF  (D-29)
# ==============================================================================================
#   Layer 1 - LIBRARY, structural. `/media` is mounted `RW=false` on beets-flask (D-05). Asserted
#             from `docker inspect`, NEVER read off the compose file: the compose file is the
#             intent, the inspect output is the fact, and only one of them is what the kernel is
#             enforcing while the run happens.
#   Layer 2 - SOURCE, a CHECKSUM MANIFEST and not a count. `%p %s %T@` catches path, size and
#             mtime; a sha256 of every file catches content; together they also catch additions
#             and deletions, because a vanished or a new path changes both listings. Taken over
#             every sampled source folder, BEFORE and AFTER, compared with the three-outcome
#             vocabulary (identical / CHANGED / COULD NOT COMPARE) that plan 03-05's WR-13
#             review put into spike03-wrtag-arms.sh.
#   Layer 3 - BEETS STATE. The real `library.db` AND the real `state.pickle`, sha256 identical
#             before and after. BOTH are named because `-l` does not redirect `statefile:`
#             (Pitfall 4): `ImportState.__init__` reads `config["statefile"].as_filename()` and
#             there is no CLI flag for it, so a throwaway `-l` import still writes the SHARED
#             pickle. state.pickle's mtime moving during a run that was supposed to write
#             nothing is the warning sign.
#   Plus     - a `find -newer $STAMP` sweep with the CR-02 could-not-look preflight. That sweep
#             used to be `find ... 2>/dev/null || true` feeding a count, and every failure mode
#             of find then produced an empty result, a zero count and a green tick claiming the
#             dry run wrote nothing.
#
# ==============================================================================================
# THE POSITIVE CONTROL IS INSIDE THE MEASUREMENT  (S3(c); T-06-42)
# ==============================================================================================
# A census that cannot see something it is KNOWN to contain has not measured zero - it has
# failed to look, and those are different answers (scripts/check-music-freeze.sh:869-874).
# The four controls, all of which must hold before the diff is evaluated at all:
#
#   1. every payload line of the transcript parses as a ` -> ` pair (or the two-line narrow-
#      terminal form). An unclassifiable line is a refusal, not a skip.
#   2. the number of pairs EQUALS the sampled audio-file count. Not "at least".
#   3. the `(N already in place)` count is 0. `move_items` filters out items whose path already
#      equals their destination; on an in-place import nothing can be in place, so a non-zero N
#      means the run measured something other than what it claims to.
#   4. the raw transcript contains the substring `/media/Music/`.
#
# If any of these fails the verdict is "UNKNOWN, not green", the diff is NOT evaluated, and the
# exit code is 3. An oracle that could not look must not be able to produce a zero-diff by
# having produced nothing.
#
# ==============================================================================================
# THE LIBRARY THE ORACLE OPENS, AND WHY IT IS A COPY  (OQ-3 option (a); D-04; T-06-44/45)
# ==============================================================================================
# `%aunique{}` is evaluated against whatever library the item is in. A bare throwaway library has
# no collisions to find, so it reports FEWER firings than a real import would - and on a library
# with 828 measured duplicate groups a zero-firing report is the warning sign, not the good news.
# So the oracle copies the REAL `/config/library.db` to `/tmp/p6/lib.db` INSIDE the container and
# opens the copy with flask's own beets 2.12.0. It must be 2.12.0: beets 2.13.1 opening a 2.12.0
# database migrates the schema under 2.12.0's feet (D-04; Phase 1 measured a bare `beet config`
# running 11 migrations unasked).
#
# The original's sha256 is asserted unchanged before and after, AND asserted equal to the value
# 06-EXPECTED-TREE.txt's header names. That second assertion is what makes the aunique count
# comparable at all: a different library is a different collision set, and the fixture's
# predicted firings were computed against one specific one.
#
# ==============================================================================================
# THE `-c` OVERLAY, AND WHY `-l` IS NOT ENOUGH
# ==============================================================================================
# `docker exec` inherits the CONTAINER's resolved environment, so BEETSDIR=/config applies and
# the vendored /config/config.yaml loads UNDERNEATH the overlay. The overlay must therefore set
# every key it needs to win. It sets:
#     library:   the throwaway copy            (-l alone would do this)
#     statefile: a throwaway pickle            (-l does NOT do this - Pitfall 4)
#     directory: /media/Music                  (what makes the printed destinations the REAL
#                                               library paths CONF-03 is about; /media is :ro so
#                                               it cannot be written regardless)
#     import.copy/move/write/autotag: no       (import.write is `yes` in the vendored config as
#                                               PHASE 7 behaviour - every Phase 6 invocation must
#                                               override it)
#     import.duplicate_action: skip            (Pitfall 3: unset means rc6 commits `remove`, and
#                                               duplicates are deleted with no prompt)
#
# An overlay that sets `copy: no` does NOT thereby set `move: no`; the two are independent keys
# and copy=no with move=yes is a MOVE. Both are named.
#
# ==============================================================================================
# WHY THE IMPORT IS AS-IS (`-A`), WHICH IS A DESIGN DECISION AND NOT AN OMISSION
# ==============================================================================================
# As-is isolates the PATH-TEMPLATE variable - the thing this phase exists to test - from the
# matcher, and it is what makes the expected tree computable BEFORE the run. A match-driven tree
# is not pre-computable: the candidate set is a network result that can change between the
# writing of the fixture and the run of the oracle. CONF-05's *Now!* proof is therefore a
# separate class assertion in plan 06-12, not a row in the committed tree.
#
# Two per-stratum flags come from 06-EXPECTED-TREE.txt's own preconditions:
#   P2  the two S5 (dj-mixes) folders are imported with `--set albumtype=dj`, or they fall
#       through to `default` and land under Mastermix/ and Various Artists/ instead of DJ/.
#       `--set` is a `beet import` CLI flag backed by `import.set_fields`, and rc6's
#       `InboxFolderSchema` HAS NO PER-INBOX EQUIVALENT. So the MECHANISM for real flask-driven
#       DJ routing is an unowned gap, registered for Phase 7 (OQ-2 / C-6). Phase 6 proves the
#       PATH RULE, not the mechanism, and this script must not be read as evidence of the latter.
#   P3  the S7 folder is imported with `-s` (singletons), or beets makes a one-track album and
#       the `singleton:` rule - the first key in the stanza, written out precisely so it is
#       reachable - is never exercised.
#
# ==============================================================================================
# HOUSE RULES OBSERVED
# ==============================================================================================
#   * Every remote command is bounded LINUX-SIDE with `timeout $REMOTE_TIMEOUT` (macOS has no GNU
#     `timeout`), the ssh status is read on the very next line with no local pipe in front of it,
#     and 124 is branched out first. `timeout N cmd | wc -l` silently exits 0, so any remote
#     string carrying a pipe also carries `set -o pipefail`.
#   * THE CONTAINER'S /bin/sh IS dash AND HAS NO `pipefail`. So no command sent INTO the container
#     carries a pipeline at all; each exit status is read explicitly on the LXC side instead.
#   * `sed $'\033'`, never `\x1b` - `\x1b` is a GNU sed extension and this script runs on macOS.
#   * There is no skip, force or auto-accept sentinel anywhere in this file, by construction.
#
# ==============================================================================================

set -euo pipefail

# --- Constants ------------------------------------------------------------------------------
# NOT OVERRIDABLE. See "THE OVERRIDE CONTRACT" above.
PHASE_DIR=".planning/phases/06-tagger-configuration-and-dry-run"
EXPECTED_TREE="$PHASE_DIR/06-EXPECTED-TREE.txt"
SAMPLE_DOC="$PHASE_DIR/06-SAMPLE.md"

# The library the fixture's %aunique{} predictions were computed against. Recorded in
# 06-EXPECTED-TREE.txt's header and in 06-SAMPLE.md § "Nothing was written".
FIXTURE_LIB_SHA256="fbbdde0c416e72b9884e56c562fd88eaa4da447926e1cb6cc17c3e04aee7da1a"
FIXTURE_STATE_SHA256="f6a9a1ad7aa553e42e53a8056fa80724785111180a5e2122be4f8732d1e4bc7c"

# Overridable, and every one of them can only make the verdict redder.
LXC_HOST="${LXC_HOST:-172.16.1.159}"
CONTAINER="${CONTAINER:-beets-flask}"
BEET_BIN="${BEET_BIN:-/venv/bin/beet}"
PY_BIN="${PY_BIN:-/venv/bin/python}"
CONTAINER_USER="${CONTAINER_USER:-beetle}"
REAL_LIB_DB="${REAL_LIB_DB:-/config/library.db}"
REAL_STATE_PICKLE="${REAL_STATE_PICKLE:-/config/state.pickle}"
SCRATCH="${SCRATCH:-/tmp/p6}"
LIB_ROOT="${LIB_ROOT:-/media/Music}"
REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-300}"
SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-5}"
# The stamp is taken OUTSIDE both mounts, so taking it cannot itself perturb what it measures.
# /mnt/fast is LXC 100's own root filesystem; nothing under /mnt/tank is touched by it.
STAMP_REMOTE="${STAMP_REMOTE:-/mnt/fast/safety/phase06/oracle.stamp}"
OUT="${OUT:-${TMPDIR:-/tmp}/phase06-oracle}"

MODE=""
REDS=0
UNKNOWNS=0

say()  { printf '%s\n' "$*"; }
ok()   { printf '  \342\234\223 %s\n' "$*"; }
bad()  { printf '  \342\234\227 %s\n' "$*"; REDS=$((REDS + 1)); }
warn() { printf '  \342\232\240 %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
rule() { printf '  %s\n' "----------------------------------------------------------------"; }
unknown() {
  printf '  \342\232\240 UNKNOWN, not green: %s\n' "$*"
  printf '    This is NOT a pass and it is NOT a failure of the thing measured. The measurement\n'
  printf '    could not be trusted, so the diff was NOT evaluated.\n'
  UNKNOWNS=$((UNKNOWNS + 1))
}
precheck_fail() { printf '  \342\234\227 %s\n' "$*" >&2; exit 2; }

usage() {
  say "Usage: bash scripts/phase06-oracle.sh --run | --baseline | --self-test | --help"
  say ""
  say "  --run        drive the throwaway import, run the oracle, diff and assert."
  say "  --baseline   capture the BEFORE manifests and the layer-3 baselines only."
  say "  --self-test  drive every fail-closed branch against synthetic fixtures. No docker."
  say "  --help       print this file's header, which is the full contract."
  say ""
  say "  env: LXC_HOST CONTAINER BEET_BIN PY_BIN CONTAINER_USER REAL_LIB_DB REAL_STATE_PICKLE"
  say "       SCRATCH LIB_ROOT REMOTE_TIMEOUT SSH_CONNECT_TIMEOUT STAMP_REMOTE OUT"
  say "  The expected-tree and sample paths are CONSTANTS and cannot be overridden."
  say ""
  say "  exit 0 = zero-diff and zero reds   1 = red   2 = usage/precheck   3 = UNKNOWN"
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --run)        MODE="run"; shift ;;
    --baseline)   MODE="baseline"; shift ;;
    --self-test)  MODE="self-test"; shift ;;
    -h|--help)    grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            say "unknown option: $1" >&2; usage ;;
  esac
done
[ -n "$MODE" ] || usage

# ==============================================================================================
# THE PURE-LOCAL JUDGING LAYER
# ==============================================================================================
# Everything below this line decides green/red from LOCAL FILES and LOCAL ARGUMENTS ONLY. The
# remote layer further down does nothing but PRODUCE those files. That split is what makes
# `--self-test` honest: it drives the same functions the real run calls, so a branch that has
# never fired in anger has still been proven to fire.

# --- Layer 2's comparison, in the shape plan 03-05's WR-13 review settled on ------------------
# `diff` exits 0 identical, 1 differing and >=2 ON TROUBLE - a missing or unreadable input - and
# on trouble it writes to stderr and leaves STDOUT EMPTY. Read as `d="$(diff ... || true)";
# [ -z "$d" ]`, that empty stdout was reported as "identical before and after". Three outcomes,
# never two.
DIFF_OUT=""
DIFF_WHY=""
manifest_compare() { # $1 = before file  $2 = after file
  local b="$1" a="$2" f="" rc=0 errf="" err=""
  DIFF_OUT=""
  DIFF_WHY=""
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
  errf="$(mktemp "${TMPDIR:-/tmp}/p6-diff-XXXXXX")" || {
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
  if [ -n "$err" ]; then
    DIFF_WHY="diff exited $rc but wrote to stderr, which is unexplained: $err"
    return 2
  fi
  [ "$rc" -eq 1 ] && return 1
  if [ -n "$DIFF_OUT" ]; then
    DIFF_WHY="diff exited 0 but printed a difference, which is unexplained"
    return 2
  fi
  return 0
}

diff_manifest() { # $1 = label  $2 = kind (meta|sha)   returns 0 clean, 1 red
  local b="$OUT/${1}.before.$2" a="$OUT/${1}.after.$2" rc=0
  manifest_compare "$b" "$a" || rc=$?
  case "$rc" in
    0) ok "layer 2 (${1}.${2} manifest): identical before and after"; return 0 ;;
    1)
      bad "layer 2 (${1}.${2} manifest): CHANGED - THE DRY RUN WAS NOT DRY:"
      printf '%s\n' "$DIFF_OUT" | head -n 40 | sed 's/^/         /'
      return 1
      ;;
    *)
      bad "layer 2 (${1}.${2} manifest) COULD NOT COMPARE: $DIFF_WHY"
      info "'could not look' is a distinct outcome from 'nothing changed' (CLAUDE.md §"
      info "Health Checks). The wrote-nothing claim is UNPROVEN, which is not the same as false."
      return 1
      ;;
  esac
}

# --- Normalising the `beet move -p` transcript -------------------------------------------------
# `show_path_changes` prints either `source -> destination` on one line, or, when the terminal is
# too narrow, the source on one line and `  -> destination` on the next. Both forms are handled;
# a transcript is not allowed to contain a payload line that is neither.
#
# Output: a TSV of source<TAB>destination (for the class assertions, which need to join back to
# the library's own field view) AND a plain LC_ALL=C-sorted destination list (for the diff). The
# RAW transcript is kept beside them on purpose - it is what a reader checks the normalisation
# against, and a normaliser nobody can audit is just a second place for the bug to hide.
NORM_WHY=""
NORM_PAIRS=0
NORM_INPLACE=0
NORM_INPLACE_SEEN=0
NORM_UNPARSED=0
normalise_transcript() { # $1 = raw transcript  $2 = pairs out  $3 = destinations out
  local raw="$1" pairs="$2" dests="$3"
  NORM_WHY=""; NORM_PAIRS=0; NORM_INPLACE=0; NORM_INPLACE_SEEN=0; NORM_UNPARSED=0
  if [ ! -f "$raw" ] || [ ! -r "$raw" ]; then
    NORM_WHY="the raw transcript '$raw' is missing or unreadable"
    return 2
  fi
  : > "$pairs"
  : > "$OUT/.unparsed"
  local prev="" line="" src="" dst=""
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "") continue ;;
      "  -> "*)
        dst="${line#"  -> "}"
        if [ -z "$prev" ]; then
          printf '%s\n' "$line" >> "$OUT/.unparsed"
          continue
        fi
        printf '%s\t%s\n' "$prev" "$dst" >> "$pairs"
        prev=""
        continue
        ;;
      "("*" already in place)")
        NORM_INPLACE_SEEN=1
        NORM_INPLACE="$(printf '%s' "$line" | sed 's/^(\([0-9][0-9]*\) already in place)$/\1/')"
        case "$NORM_INPLACE" in
          ''|*[!0-9]*) NORM_INPLACE=-1 ;;
        esac
        continue
        ;;
    esac
    case "$line" in
      *" -> "*)
        src="${line%%" -> "*}"
        dst="${line#*" -> "}"
        printf '%s\t%s\n' "$src" "$dst" >> "$pairs"
        prev=""
        ;;
      *)
        # Either the first half of a narrow-terminal pair, or a line that does not belong in a
        # `move -p` transcript at all. Deciding which is the NEXT line's job: a source line is
        # only a source line if a `  -> ` follows it. Anything still pending when the file ends,
        # or pending when another bare line arrives, is unparsed - and unparsed is a refusal.
        if [ -n "$prev" ]; then
          printf '%s\n' "$prev" >> "$OUT/.unparsed"
        fi
        prev="$line"
        ;;
    esac
  done < "$raw"
  [ -z "$prev" ] || printf '%s\n' "$prev" >> "$OUT/.unparsed"

  NORM_UNPARSED="$(wc -l < "$OUT/.unparsed" | tr -d ' ')"
  NORM_PAIRS="$(wc -l < "$pairs" | tr -d ' ')"
  LC_ALL=C cut -f2 "$pairs" | LC_ALL=C sort > "$dests"
  return 0
}

# --- The positive control, INSIDE the measurement ---------------------------------------------
PC_WHY=""
positive_control() { # $1 = raw transcript  $2 = pairs  $3 = expected pair count
  local raw="$1" pairs="$2" want="$3"
  PC_WHY=""
  if [ "$NORM_UNPARSED" -ne 0 ]; then
    PC_WHY="$NORM_UNPARSED transcript line(s) are not a ' -> ' pair in either form. A
    \`--pretend\` transcript taken from the importer fails here trivially, which is the point:
    its lines are SOURCE paths and it never computes a destination at all (D-33). First offenders:
$(head -n 5 "$OUT/.unparsed" | sed 's/^/      /')"
    return 3
  fi
  if [ "$NORM_PAIRS" -eq 0 ]; then
    PC_WHY="the transcript yielded ZERO destination pairs. A zero-diff produced by an empty
    oracle is the failure mode this control exists to catch (T-06-42)."
    return 3
  fi
  if [ "$NORM_PAIRS" -ne "$want" ]; then
    PC_WHY="the transcript yielded $NORM_PAIRS destination pairs but the sample holds $want audio
    files. This is an EQUALITY, not a floor: a partial import produces a valid-looking subset."
    return 3
  fi
  if [ "$NORM_INPLACE" -ne 0 ]; then
    PC_WHY="the '(N already in place)' line reports N=$NORM_INPLACE. \`move_items\` filters out
    items whose path already equals their destination, and on an in-place import (copy: no,
    move: no) nothing can be in place - so a non-zero N means the run measured something else."
    return 3
  fi
  if ! LC_ALL=C grep -q "$LIB_ROOT/" "$raw"; then
    PC_WHY="the raw transcript contains no '$LIB_ROOT/' substring at all, so whatever was
    measured, it was not this library's destinations."
    return 3
  fi
  return 0
}

# --- The diff against the committed tree ------------------------------------------------------
# ANY CONSUMER MUST STRIP '^#' BEFORE DIFFING - 06-EXPECTED-TREE.txt says so in its own header,
# because the header is part of the fixture's meaning and is deliberately not moved out.
TREE_DIFF_WHY=""
diff_expected_tree() { # $1 = expected tree file  $2 = normalised destination list
  local exp="$1" got="$2" stripped="" rc=0
  TREE_DIFF_WHY=""
  if [ ! -f "$exp" ] || [ ! -r "$exp" ]; then
    TREE_DIFF_WHY="the committed expected tree '$exp' is missing or unreadable"
    return 2
  fi
  stripped="$OUT/expected.stripped"
  LC_ALL=C grep -v '^#' "$exp" > "$stripped" || true
  manifest_compare "$stripped" "$got" || rc=$?
  case "$rc" in
    0) return 0 ;;
    1) return 1 ;;
    *) TREE_DIFF_WHY="$DIFF_WHY"; return 2 ;;
  esac
}

# --- Mapping a host path to its container path, from the inspect output and not from guesswork -
MAP_OUT=""
MAP_WHY=""
map_host_to_container() { # $1 = host path  $2 = mounts file (Source|Destination|rw|ro per line)
  local hp="$1" mf="$2" best="" bestdst="" src="" dst="" flag=""
  MAP_OUT=""; MAP_WHY=""
  if [ ! -f "$mf" ] || [ ! -r "$mf" ]; then
    MAP_WHY="the mount table '$mf' is missing or unreadable"
    return 2
  fi
  while IFS='|' read -r src dst flag; do
    [ -n "$src" ] || continue
    case "$hp" in
      "$src"|"$src"/*)
        # Longest matching Source wins: /mnt/tank/media must beat /mnt/tank if both are mounted.
        if [ "${#src}" -gt "${#best}" ]; then best="$src"; bestdst="$dst"; fi
        ;;
    esac
  done < "$mf"
  if [ -z "$best" ]; then
    MAP_WHY="no mount on '$CONTAINER' contains the host path '$hp'"
    return 2
  fi
  MAP_OUT="${bestdst}${hp#"$best"}"
  return 0
}

# --- Layer 1, structural: /media must be RW=false ----------------------------------------------
RW_WHY=""
assert_media_readonly() { # $1 = mounts file  $2 = container destination that must be read-only
  local mf="$1" want="$2" src="" dst="" flag="" found=0
  RW_WHY=""
  if [ ! -f "$mf" ] || [ ! -r "$mf" ]; then
    RW_WHY="the mount table '$mf' is missing or unreadable, so RW could not be read at all"
    return 2
  fi
  while IFS='|' read -r src dst flag; do
    [ -n "$dst" ] || continue
    if [ "$dst" = "$want" ]; then
      found=1
      if [ "$flag" != "ro" ]; then
        RW_WHY="'$want' is mounted RW=true (source $src). D-05 requires RW=false for the whole
    of Phase 6, and a read-only mount is the only control here that CANNOT FAIL OPEN."
        return 1
      fi
    fi
  done < "$mf"
  if [ "$found" -eq 0 ]; then
    RW_WHY="no mount with destination '$want' was enumerated at all. This is NOT '/media is
    read-only' - nothing was inspected, so nothing is known."
    return 2
  fi
  return 0
}

# --- Reading the sampled folders out of 06-SAMPLE.md, never re-typing them ----------------------
# The table is "The ten drawn folders": | Folder | Stratum | Files | ... . Parsed rather than
# transcribed for the reason spike03-wrtag-arms.sh reads its path format from the file it
# measures: a re-typed copy measures a set this project does not use, and drifts silently.
SAMPLE_ROWS=0
SAMPLE_FILES=0
SAMPLE_WHY=""
parse_sample() { # $1 = 06-SAMPLE.md  $2 = out TSV: folder<TAB>stratum<TAB>files
  local doc="$1" out="$2"
  SAMPLE_ROWS=0; SAMPLE_FILES=0; SAMPLE_WHY=""
  if [ ! -f "$doc" ] || [ ! -r "$doc" ]; then
    SAMPLE_WHY="the sample document '$doc' is missing or unreadable"
    return 2
  fi
  LC_ALL=C awk -F'|' '
    /^\| *\/mnt\// {
      folder = $2; stratum = $3; files = $4
      gsub(/^ +| +$/, "", folder); gsub(/^ +| +$/, "", stratum); gsub(/^ +| +$/, "", files)
      if (folder != "" && stratum ~ /^S[0-9]+$/ && files ~ /^[0-9]+$/)
        printf "%s\t%s\t%s\n", folder, stratum, files
    }' "$doc" > "$out"
  SAMPLE_ROWS="$(wc -l < "$out" | tr -d ' ')"
  SAMPLE_FILES="$(LC_ALL=C awk -F'\t' '{s += $3} END {print s + 0}' "$out")"
  if [ "$SAMPLE_ROWS" -eq 0 ]; then
    SAMPLE_WHY="no sampled-folder row was parsed out of '$doc'. The table shape has moved, and
    an empty folder list would import nothing and then diff nothing against 174 expected lines."
    return 2
  fi
  return 0
}

# ==============================================================================================
# THE REMOTE LAYER - it PRODUCES files; it never decides anything
# ==============================================================================================
RSH_OUT=""
RSH_RC=0
rsh() { # $1 = command string, run by bash on LXC 100
  RSH_OUT=""
  RSH_RC=0
  RSH_OUT="$(ssh -n -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" "root@$LXC_HOST" "$1")" || RSH_RC=$?
  return 0
}

rsh_to() { # $1 = command string  $2 = local output file
  RSH_RC=0
  ssh -n -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" "root@$LXC_HOST" "$1" > "$2" 2> "${2}.err" || RSH_RC=$?
  return 0
}

rsh_from() { # $1 = command string  $2 = local file fed to the remote command's stdin
  RSH_RC=0
  ssh -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" "root@$LXC_HOST" "$1" < "$2" > /dev/null || RSH_RC=$?
  return 0
}

# Every remote status is classified in the house S1 order: empty output first (deferring when the
# status is 124, because a killed command usually produces none either), then 124, then any other
# non-zero, and only then is anything asserted.
rsh_classify() { # $1 = what was being read; returns 0 usable, 3 could-not-look
  if [ -z "$RSH_OUT" ] && [ "$RSH_RC" -ne 124 ]; then
    unknown "$1 came back empty (ssh exit $RSH_RC). Nothing was read."
    return 3
  fi
  if [ "$RSH_RC" -eq 124 ]; then
    unknown "$1 exceeded its ${REMOTE_TIMEOUT}s bound and was killed. Most likely a wedged dockerd."
    return 3
  fi
  if [ "$RSH_RC" -ne 0 ]; then
    unknown "$1 failed (ssh exit $RSH_RC)."
    return 3
  fi
  return 0
}

# `docker exec` into the container, bounded Linux-side, with NO PIPELINE inside the container -
# its /bin/sh is dash and has no `pipefail`, so a pipeline there would launder a failure.
dex_cmd() { # $1.. = argv inside the container; echoes the remote command string
  printf 'timeout %s docker exec -u %s %s %s' "$REMOTE_TIMEOUT" "$CONTAINER_USER" "$CONTAINER" "$*"
}

# The remote manifest. `%p %s %T@` catches path, size and mtime; the sha catches content;
# together they catch additions and deletions too. GNU find's -printf is why this runs on LXC 100
# and not on the macOS workstation.
remote_manifest_meta() { # $1 = subtree
  printf "set -o pipefail; timeout %s sh -c 'LC_ALL=C find %s -type f -printf \"%%p\\t%%s\\t%%T@\\n\"' | LC_ALL=C sort" \
    "$REMOTE_TIMEOUT" "$(printf '%q' "$1")"
}
remote_manifest_sha() { # $1 = subtree
  printf "set -o pipefail; timeout %s sh -c 'LC_ALL=C find %s -type f -print0' | LC_ALL=C sort -z | xargs -0 -r sha256sum" \
    "$REMOTE_TIMEOUT" "$(printf '%q' "$1")"
}

capture_manifests() { # $1 = when (before|after)  $2 = folders TSV
  local when="$1" list="$2" folder="" i=0
  : > "$OUT/src.$when.meta"
  : > "$OUT/src.$when.sha"
  while IFS="$(printf '\t')" read -r folder _ _; do
    [ -n "$folder" ] || continue
    i=$((i + 1))
    rsh_to "$(remote_manifest_meta "$folder")" "$OUT/.m.$when.$i.meta"
    if [ "$RSH_RC" -ne 0 ]; then
      unknown "layer 2: could not take the $when metadata manifest of '$folder' (ssh exit $RSH_RC)"
      return 3
    fi
    cat "$OUT/.m.$when.$i.meta" >> "$OUT/src.$when.meta"
    rsh_to "$(remote_manifest_sha "$folder")" "$OUT/.m.$when.$i.sha"
    if [ "$RSH_RC" -ne 0 ]; then
      unknown "layer 2: could not take the $when content manifest of '$folder' (ssh exit $RSH_RC)"
      return 3
    fi
    cat "$OUT/.m.$when.$i.sha" >> "$OUT/src.$when.sha"
  done < "$list"
  LC_ALL=C sort -o "$OUT/src.$when.meta" "$OUT/src.$when.meta"
  LC_ALL=C sort -o "$OUT/src.$when.sha" "$OUT/src.$when.sha"
  return 0
}

# ==============================================================================================
# --self-test : drive every fail-closed branch, without docker and without ssh
# ==============================================================================================
ST_FAIL=0
st_case() { # $1 = expectation  $2 = observed  $3 = description
  if [ "$1" = "$2" ]; then
    ok "$2 (expected): $3"
  else
    bad "SELF-TEST REGRESSION: expected '$1', got '$2': $3"
    ST_FAIL=$((ST_FAIL + 1))
  fi
}

st_mc() { # $1 = expected outcome  $2 = before  $3 = after  $4 = description
  local rc=0 got=""
  manifest_compare "$2" "$3" || rc=$?
  case "$rc" in 0) got="identical" ;; 1) got="differs" ;; *) got="couldnotcompare" ;; esac
  st_case "$1" "$got" "$4"
}

# Drives normalise_transcript + positive_control together, which is the pairing that matters:
# the control is only meaningful over a transcript the normaliser has already classified.
st_control() { # $1 = expected (ok|unknown)  $2 = transcript file  $3 = want count  $4 = desc
  local rc=0 got="ok"
  normalise_transcript "$2" "$OUT/st.pairs" "$OUT/st.dests" || rc=$?
  if [ "$rc" -ne 0 ]; then
    got="unknown"
  else
    rc=0
    positive_control "$2" "$OUT/st.pairs" "$3" || rc=$?
    [ "$rc" -eq 0 ] || got="unknown"
  fi
  st_case "$1" "$got" "$4"
  [ "$got" != "unknown" ] || info "reason: $(printf '%s' "$PC_WHY" | head -n 2)"
}

self_test_core() {
  local td=""
  say ""
  say "== --self-test: the transcript normaliser and the positive control (T-06-41/42) =="
  rule
  td="$OUT"

  # (1) A `--pretend`-shaped transcript: source paths only, no ` -> ` anywhere. It prints a line
  #     per file and exits 0, which is exactly why it reads as a pass (Pitfall 1).
  {
    printf 'Album: /downloads/complete/nzb/music/Benson Boone-American Heart\n'
    printf '  /downloads/complete/nzb/music/Benson Boone-American Heart/01 Sorry.mp3\n'
    printf '  /downloads/complete/nzb/music/Benson Boone-American Heart/02 Mr Blue.mp3\n'
  } > "$td/st.pretend.txt"
  st_control unknown "$td/st.pretend.txt" 3 \
    "a --pretend transcript: no ' -> ' in any form, so no destination was ever computed."

  # (2) The right shape, the wrong count. A partial import produces a valid-looking subset, and
  #     a subset that happens to be a prefix of the fixture would diff clean on every line it has.
  {
    printf '/src/a.mp3 -> %s/A/Al/01 a.mp3\n' "$LIB_ROOT"
    printf '/src/b.mp3 -> %s/A/Al/02 b.mp3\n' "$LIB_ROOT"
  } > "$td/st.short.txt"
  st_control unknown "$td/st.short.txt" 3 "right shape, two pairs against an expected three."

  # (3) A non-zero '(N already in place)'.
  {
    printf '/src/a.mp3 -> %s/A/Al/01 a.mp3\n' "$LIB_ROOT"
    printf '/src/b.mp3 -> %s/A/Al/02 b.mp3\n' "$LIB_ROOT"
    printf '(4 already in place)\n'
  } > "$td/st.inplace.txt"
  st_control unknown "$td/st.inplace.txt" 2 \
    "'(4 already in place)' - move_items filtered items out, so the census is not the sample."

  # (4) The two-line narrow-terminal form must normalise IDENTICALLY to the wide form. If it did
  #     not, a terminal width would change the verdict, which is not a property an oracle may have.
  {
    printf '/src/a.mp3\n'
    printf '  -> %s/A/Al/01 a.mp3\n' "$LIB_ROOT"
    printf '/src/b.mp3\n'
    printf '  -> %s/A/Al/02 b.mp3\n' "$LIB_ROOT"
  } > "$td/st.narrow.txt"
  st_control ok "$td/st.narrow.txt" 2 "the narrow-terminal two-line form parses as two pairs."

  # (5) A transcript with no '/media/Music/' substring at all - the warning sign Pitfall 1 names.
  {
    printf '/src/a.mp3 -> /tmp/elsewhere/A/Al/01 a.mp3\n'
    printf '/src/b.mp3 -> /tmp/elsewhere/A/Al/02 b.mp3\n'
  } > "$td/st.elsewhere.txt"
  st_control unknown "$td/st.elsewhere.txt" 2 \
    "no '$LIB_ROOT/' anywhere: whatever was measured, it was not this library."

  # (6) The fully correct case. A control that can only fail is as uninformative as one that can
  #     only pass.
  {
    printf '/src/a.mp3 -> %s/A/Al/01 a.mp3\n' "$LIB_ROOT"
    printf '/src/b.mp3 -> %s/A/Al/02 b.mp3\n' "$LIB_ROOT"
  } > "$td/st.good.txt"
  st_control ok "$td/st.good.txt" 2 "a well-formed two-pair transcript, count matching."

  say ""
  say "== --self-test: layer 2's three outcomes (D-29; WR-13) =="
  rule
  printf 'a/one.mp3\t1\t1.0\na/two.mp3\t2\t2.0\n' > "$td/st.before.meta"
  cp "$td/st.before.meta" "$td/st.after.meta"
  st_mc identical "$td/st.before.meta" "$td/st.after.meta" \
    "IDENTICAL manifests - the green case, which must still be green."
  printf 'a/one.mp3\t1\t1.0\na/two.mp3\t2\t9.9\n' > "$td/st.after.meta"
  st_mc differs "$td/st.before.meta" "$td/st.after.meta" \
    "a CHANGED mtime - the dry run was not dry."
  printf 'deadbeef  a/one.mp3\n' > "$td/st.before.sha"
  printf 'cafebabe  a/one.mp3\n' > "$td/st.after.sha"
  st_mc differs "$td/st.before.sha" "$td/st.after.sha" \
    "a CHANGED sha256 - content moved while path, size and mtime could all have held."
  st_mc couldnotcompare "$td/st.absent.meta" "$td/st.after.meta" \
    "a MISSING before-manifest: diff exits 2, writes to stderr and leaves stdout EMPTY."
  mkdir -p "$td/st.adir.meta"
  st_mc couldnotcompare "$td/st.before.meta" "$td/st.adir.meta" \
    "a DIRECTORY where a manifest should be - constructible as root, unlike mode 000."
  if [ "$(id -u)" = "0" ]; then
    warn "SKIPPED as root: an UNREADABLE manifest (mode 000). root bypasses the read bit, so"
    info "the case cannot be constructed here - reported, never silently counted as a pass."
  else
    cp "$td/st.before.meta" "$td/st.noread.meta"
    chmod 000 "$td/st.noread.meta"
    st_mc couldnotcompare "$td/st.noread.meta" "$td/st.after.meta" "an UNREADABLE manifest."
    chmod 644 "$td/st.noread.meta"
  fi

  say ""
  say "== --self-test: the blind preflight, layer 1 and the host->container mapper =="
  rule
  local rc=0 got=""
  # A blind source directory. This is the CR-02 case: `find ... 2>/dev/null || true` feeding a
  # count turned every failure mode into a zero and a green tick.
  rc=0; got="ok"
  preflight_readable "$td/st.nosuchdir" || rc=$?
  [ "$rc" -eq 0 ] || got="blind"
  st_case blind "$got" "a source directory that does not exist is a refusal, not '0 files newer'."
  [ "$got" != "blind" ] || info "reason: $PREFLIGHT_WHY"
  rc=0; got="ok"
  preflight_readable "$td" || rc=$?
  [ "$rc" -eq 0 ] || got="blind"
  st_case ok "$got" "a real, readable directory must still be accepted."

  printf '/mnt/tank/media|/media|ro\n/mnt/tank/downloads|/downloads|rw\n/mnt/fast/appdata/arrs/beets/config|/config|rw\n' \
    > "$td/st.mounts"
  rc=0; assert_media_readonly "$td/st.mounts" /media || rc=$?
  st_case 0 "$rc" "/media enumerated as ro - layer 1 holds."
  printf '/mnt/tank/media|/media|rw\n' > "$td/st.mounts.rw"
  rc=0; assert_media_readonly "$td/st.mounts.rw" /media || rc=$?
  st_case 1 "$rc" "/media enumerated as rw - D-05 violated, and this must be a RED not a warning."
  printf '/mnt/tank/downloads|/downloads|rw\n' > "$td/st.mounts.none"
  rc=0; assert_media_readonly "$td/st.mounts.none" /media || rc=$?
  st_case 2 "$rc" "no /media mount enumerated at all - UNKNOWN, never 'it is read-only'."

  rc=0; map_host_to_container /mnt/tank/media/Music/Katy "$td/st.mounts" || rc=$?
  st_case "/media/Music/Katy" "$MAP_OUT" "longest-prefix mapping picks /mnt/tank/media over /mnt/tank."
  rc=0; map_host_to_container /var/tmp/elsewhere "$td/st.mounts" || rc=$?
  st_case 2 "$rc" "a host path under no mount is a refusal, not a silently unmapped path."

  say ""
  say "== --self-test: the sampled-folder table is READ, never re-typed =="
  rule
  rc=0; parse_sample "$SAMPLE_DOC" "$td/st.sample.tsv" || rc=$?
  st_case 0 "$rc" "06-SAMPLE.md's ten-folder table parses."
  st_case 10 "$SAMPLE_ROWS" "ten rows, one per drawn folder."
  st_case 174 "$SAMPLE_FILES" "the Files column sums to 174, the fixture's own line count."
  rc=0; parse_sample "$td/st.nosuchfile.md" "$td/st.sample2.tsv" || rc=$?
  st_case 2 "$rc" "a missing sample document is a refusal, never an empty folder list."
}

# --- The CR-02 could-not-look preflight, shared by the -newer sweep and the manifests ----------
PREFLIGHT_WHY=""
preflight_readable() { # $1 = local directory that must exist and be searchable
  PREFLIGHT_WHY=""
  if [ ! -d "$1" ]; then
    PREFLIGHT_WHY="'$1' is not a directory (vanished, or a stale bind mount)"
    return 1
  fi
  if [ ! -r "$1" ] || [ ! -x "$1" ]; then
    PREFLIGHT_WHY="'$1' is not readable and searchable"
    return 1
  fi
  return 0
}

# ==============================================================================================
# MAIN
# ==============================================================================================
mkdir -p "$OUT"

if [ "$MODE" = "self-test" ]; then
  ST_FAIL=0
  REDS=0
  self_test_core
  say ""
  if [ "$ST_FAIL" -ne 0 ] || [ "$REDS" -ne 0 ]; then
    printf '  \342\234\227 self-test: %s case(s) FAILED\n' "$((ST_FAIL))"
    exit 1
  fi
  ok "self-test: every fail-closed branch behaved exactly as expected"
  exit 0
fi

# --- Step 0: the fixtures must be present before anything live happens -------------------------
[ -f "$EXPECTED_TREE" ] || precheck_fail "the committed expected tree is missing: $EXPECTED_TREE"
[ -f "$SAMPLE_DOC" ]    || precheck_fail "the sample document is missing: $SAMPLE_DOC"

say ""
say "== phase06-oracle.sh: $MODE =="
rule
say "  host       root@$LXC_HOST   container $CONTAINER   engine $BEET_BIN"
say "  expected   $EXPECTED_TREE   (CONSTANT - not overridable)"
say "  sample     $SAMPLE_DOC      (CONSTANT - not overridable)"
say "  out        $OUT"
say ""

parse_sample "$SAMPLE_DOC" "$OUT/sample.tsv" || precheck_fail "$SAMPLE_WHY"
ok "sampled folders read from 06-SAMPLE.md: $SAMPLE_ROWS folders, $SAMPLE_FILES audio files"

EXPECTED_LINES="$(LC_ALL=C grep -cv '^#' "$EXPECTED_TREE" || true)"
if [ "$EXPECTED_LINES" -ne "$SAMPLE_FILES" ]; then
  precheck_fail "the fixture holds $EXPECTED_LINES path lines but the sample holds $SAMPLE_FILES
    audio files. The two are checked against each other in the fixture's own self-check, so a
    disagreement means one of them has moved and the diff is not comparable."
fi
ok "fixture and sample agree on the denominator: $EXPECTED_LINES lines / $SAMPLE_FILES files"

# --- Step 1: reach the host, and refuse a dirty destination -----------------------------------
rsh "timeout $REMOTE_TIMEOUT docker inspect -f '{{.State.Status}}' $CONTAINER"
rsh_classify "the container status of $CONTAINER" || exit 3
[ "$RSH_OUT" = "running" ] || precheck_fail "$CONTAINER is '$RSH_OUT', not running"
ok "container $CONTAINER is running"

rsh "$(dex_cmd sh -c "'[ ! -e $SCRATCH ] && echo absent || ls -A $SCRATCH | head -n 1'")"
if [ "$RSH_RC" -ne 0 ]; then
  precheck_fail "could not inspect '$SCRATCH' inside the container (ssh exit $RSH_RC)"
fi
if [ "$RSH_OUT" != "absent" ] && [ -n "$RSH_OUT" ]; then
  precheck_fail "'$SCRATCH' already exists inside the container and is not empty (first entry:
    $RSH_OUT). A wrote-nothing assertion against a dirty destination proves nothing - refusing."
fi
ok "container scratch '$SCRATCH' is absent or empty"

# --- Step 2: layer 1, structural, read from docker inspect and never from the compose file ----
# The `|` characters below are Go TEMPLATE separators, not shell pipes - but the house greppable
# rule (`grep -n 'timeout $REMOTE_TIMEOUT.*|'` must return only lines that also carry `pipefail`)
# reads the line, not the intent, so `set -o pipefail` is stated here too rather than leaving a
# reader to adjudicate. It costs nothing and it keeps the rule mechanical.
rsh_to "set -o pipefail; timeout $REMOTE_TIMEOUT docker inspect --format '{{range .Mounts}}{{.Source}}|{{.Destination}}|{{if .RW}}rw{{else}}ro{{end}}{{\"\n\"}}{{end}}' $CONTAINER" "$OUT/mounts.txt"
if [ "$RSH_RC" -ne 0 ]; then
  unknown "the mount table of $CONTAINER could not be read (ssh exit $RSH_RC)"
  exit 3
fi
RC=0
assert_media_readonly "$OUT/mounts.txt" /media || RC=$?
case "$RC" in
  0) ok "layer 1 (structural): /media is mounted RW=false on $CONTAINER" ;;
  1) bad "layer 1: $RW_WHY" ;;
  *) unknown "layer 1: $RW_WHY"; exit 3 ;;
esac

# --- Step 3: the layer-3 baselines, and the library identity the fixture assumes ---------------
rsh "$(dex_cmd sha256sum "$REAL_LIB_DB" "$REAL_STATE_PICKLE")"
rsh_classify "the layer-3 baseline hashes" || exit 3
printf '%s\n' "$RSH_OUT" > "$OUT/layer3.before"
LIB_SHA_BEFORE="$(LC_ALL=C awk -v p="$REAL_LIB_DB" '$2 == p {print $1}' "$OUT/layer3.before")"
STATE_SHA_BEFORE="$(LC_ALL=C awk -v p="$REAL_STATE_PICKLE" '$2 == p {print $1}' "$OUT/layer3.before")"
[ -n "$LIB_SHA_BEFORE" ] || { unknown "no sha256 line for $REAL_LIB_DB"; exit 3; }
[ -n "$STATE_SHA_BEFORE" ] || { unknown "no sha256 line for $REAL_STATE_PICKLE"; exit 3; }
say "  library.db    before: $LIB_SHA_BEFORE"
say "  state.pickle  before: $STATE_SHA_BEFORE"

if [ "$LIB_SHA_BEFORE" = "$FIXTURE_LIB_SHA256" ]; then
  ok "the library this run opens IS the one 06-EXPECTED-TREE.txt's header names"
else
  bad "the real library.db sha256 is $LIB_SHA_BEFORE, but the fixture's %aunique{} predictions
    were computed against $FIXTURE_LIB_SHA256. A different library is a DIFFERENT COLLISION SET,
    so the aunique count below is not comparable with the fixture's and the diff may fail for a
    reason that is not a configuration defect. Re-derive the fixture before reading the diff."
fi
if [ "$STATE_SHA_BEFORE" != "$FIXTURE_STATE_SHA256" ]; then
  warn "state.pickle is not at its recorded baseline ($FIXTURE_STATE_SHA256). The real library
    has never recorded incremental history, so any other value is positive evidence that a real
    import ran at some point. Reported, not failed - the hard gate is before == after."
fi

# --- Step 4: BEFORE manifests over every sampled source folder (D-29 layer 2) -------------------
say ""
say "== layer 2: BEFORE manifests over every sampled source folder =="
rule
capture_manifests before "$OUT/sample.tsv" || exit 3
ok "before-manifests captured: $(wc -l < "$OUT/src.before.meta" | tr -d ' ') files across $SAMPLE_ROWS folders"

# The stamp is created OUTSIDE both mounts, so taking it cannot itself perturb what it measures.
rsh "timeout $REMOTE_TIMEOUT sh -c 'mkdir -p $(dirname "$STAMP_REMOTE") && rm -f $STAMP_REMOTE && touch $STAMP_REMOTE && echo stamped'"
rsh_classify "the -newer stamp" || exit 3
ok "stamp taken outside both mounts: $STAMP_REMOTE"
sleep 1

if [ "$MODE" = "baseline" ]; then
  say ""
  ok "--baseline complete. Nothing was imported and nothing was run against the sample."
  say "  Artefacts under $OUT: sample.tsv mounts.txt layer3.before src.before.{meta,sha}"
  exit 0
fi

# --- Step 5: the throwaway library, from a COPY of the real one --------------------------------
say ""
say "== the throwaway library and the -c overlay =="
rule
rsh "$(dex_cmd sh -c "'mkdir -p $SCRATCH && cp $REAL_LIB_DB $SCRATCH/lib.db && echo copied'")"
rsh_classify "the library copy into $SCRATCH" || exit 3
ok "copied $REAL_LIB_DB -> $SCRATCH/lib.db (the ORIGINAL is never opened by this run)"

{
  printf 'library: %s/lib.db\n' "$SCRATCH"
  printf 'statefile: %s/state.pickle\n' "$SCRATCH"
  printf 'directory: %s\n' "$LIB_ROOT"
  printf 'import:\n'
  printf '    copy: no\n'
  printf '    move: no\n'
  printf '    write: no\n'
  printf '    autotag: no\n'
  printf '    resume: no\n'
  printf '    incremental: no\n'
  printf '    duplicate_action: skip\n'
} > "$OUT/overlay.yaml"
rsh_from "timeout $REMOTE_TIMEOUT docker exec -i -u $CONTAINER_USER $CONTAINER sh -c 'cat > $SCRATCH/overlay.yaml'" "$OUT/overlay.yaml"
[ "$RSH_RC" -eq 0 ] || { unknown "could not place the overlay inside the container (ssh exit $RSH_RC)"; exit 3; }
ok "overlay placed: library, statefile AND directory all redirected (-l alone redirects none but the first)"

# --- Step 6: the as-is import into the throwaway ------------------------------------------------
say ""
say "== the as-is import into the throwaway library =="
rule
while IFS="$(printf '\t')" read -r folder stratum files; do
  [ -n "$folder" ] || continue
  map_host_to_container "$folder" "$OUT/mounts.txt" || { unknown "$MAP_WHY"; exit 3; }
  CPATH="$MAP_OUT"
  EXTRA=""
  case "$stratum" in
    S5) EXTRA="--set albumtype=dj" ;;
    S7) EXTRA="-s" ;;
  esac
  say "  $stratum  $files files  $CPATH ${EXTRA:+[$EXTRA]}"
  rsh "$(dex_cmd "$BEET_BIN" -c "$SCRATCH/overlay.yaml" import -A -q $EXTRA "$(printf '%q' "$CPATH")")"
  if [ "$RSH_RC" -ne 0 ]; then
    unknown "the as-is import of '$CPATH' exited $RSH_RC. A partial library would make the
    line-count control fire anyway, but the cause belongs here, not there."
    exit 3
  fi
done < "$OUT/sample.tsv"
ok "all $SAMPLE_ROWS sampled folders imported as-is into the throwaway"

# --- Step 7: the oracle itself ------------------------------------------------------------------
say ""
say "== the oracle: beet move -p =="
rule
rsh_to "$(dex_cmd "$BEET_BIN" -c "$SCRATCH/overlay.yaml" move -p)" "$OUT/oracle.raw.txt"
if [ "$RSH_RC" -ne 0 ]; then
  unknown "beet move -p exited $RSH_RC; the transcript is at $OUT/oracle.raw.txt"
  exit 3
fi
normalise_transcript "$OUT/oracle.raw.txt" "$OUT/oracle.pairs.tsv" "$OUT/oracle.destinations.txt" \
  || { unknown "$NORM_WHY"; exit 3; }
say "  pairs parsed:            $NORM_PAIRS"
say "  unparsed payload lines:  $NORM_UNPARSED"
if [ "$NORM_INPLACE_SEEN" -eq 1 ]; then
  say "  (N already in place):    $NORM_INPLACE   [line present]"
else
  say "  (N already in place):    0   [line ABSENT - beets prints it only when N > 0, so absence"
  say "                                is informative but weaker than a printed zero]"
fi

# --- Step 8: the positive control, BEFORE the diff is evaluated ---------------------------------
PC_RC=0
positive_control "$OUT/oracle.raw.txt" "$OUT/oracle.pairs.tsv" "$SAMPLE_FILES" || PC_RC=$?
if [ "$PC_RC" -ne 0 ]; then
  unknown "$PC_WHY"
  say ""
  say "  The diff against $EXPECTED_TREE was NOT evaluated. Exiting 3."
  exit 3
fi
ok "positive control: every line is a ' -> ' pair, $NORM_PAIRS == $SAMPLE_FILES, N in place = 0,"
info "and '$LIB_ROOT/' appears in the raw transcript. The measurement can be trusted to have looked."

# --- Step 9: AFTER manifests and the three-layer verdict ----------------------------------------
say ""
say "== the three-layer wrote-nothing verdict =="
rule
capture_manifests after "$OUT/sample.tsv" || exit 3
diff_manifest src meta || true
diff_manifest src sha  || true

rsh "$(dex_cmd sha256sum "$REAL_LIB_DB" "$REAL_STATE_PICKLE")"
rsh_classify "the layer-3 hashes after the run" || exit 3
printf '%s\n' "$RSH_OUT" > "$OUT/layer3.after"
LIB_SHA_AFTER="$(LC_ALL=C awk -v p="$REAL_LIB_DB" '$2 == p {print $1}' "$OUT/layer3.after")"
STATE_SHA_AFTER="$(LC_ALL=C awk -v p="$REAL_STATE_PICKLE" '$2 == p {print $1}' "$OUT/layer3.after")"
if [ "$LIB_SHA_AFTER" = "$LIB_SHA_BEFORE" ]; then
  ok "layer 3: the real library.db is byte-identical before and after"
else
  bad "layer 3: the real library.db CHANGED ($LIB_SHA_BEFORE -> $LIB_SHA_AFTER)"
fi
if [ "$STATE_SHA_AFTER" = "$STATE_SHA_BEFORE" ]; then
  ok "layer 3: the real state.pickle is byte-identical before and after"
else
  bad "layer 3: the real state.pickle CHANGED ($STATE_SHA_BEFORE -> $STATE_SHA_AFTER). -l does
    not redirect statefile:, so this is what a missing overlay key looks like."
fi

# The -newer sweep, with its could-not-look preflight. `find ... 2>/dev/null || true` feeding a
# count is exactly how a failed find produced an empty result, a zero count and a green tick.
NEWER_ARGS=""
BLIND=""
while IFS="$(printf '\t')" read -r folder _ _; do
  [ -n "$folder" ] || continue
  NEWER_ARGS="$NEWER_ARGS $(printf '%q' "$folder")"
done < "$OUT/sample.tsv"
rsh "set -o pipefail; timeout $REMOTE_TIMEOUT sh -c 'for d in $NEWER_ARGS; do [ -d \"\$d\" ] && [ -r \"\$d\" ] && [ -x \"\$d\" ] || { echo BLIND:\$d; exit 0; }; done; [ -f $STAMP_REMOTE ] || { echo BLIND:stamp; exit 0; }; echo READY'"
if [ "$RSH_RC" -ne 0 ]; then
  unknown "the -newer preflight could not run (ssh exit $RSH_RC)"
else
  case "$RSH_OUT" in
    READY)
      rsh "timeout $REMOTE_TIMEOUT find $NEWER_ARGS -newer $STAMP_REMOTE -type f"
      if [ "$RSH_RC" -ne 0 ]; then
        bad "the -newer sweep COULD NOT LOOK (exit $RSH_RC). This is NOT '0 files newer'."
      elif [ -z "$RSH_OUT" ]; then
        ok "-newer sweep: 0 files newer than the stamp across all $SAMPLE_ROWS sampled folders"
      else
        bad "-newer sweep: files are newer than the stamp - THE DRY RUN WROTE:"
        printf '%s\n' "$RSH_OUT" | head -n 20 | sed 's/^/         /'
      fi
      ;;
    BLIND:*)
      BLIND="${RSH_OUT#BLIND:}"
      bad "the -newer sweep COULD NOT LOOK: '$BLIND' is missing, unreadable or unsearchable.
    'could not look' is a distinct outcome from 'nothing changed' (CLAUDE.md § Health Checks)."
      ;;
    *) bad "the -newer preflight returned an unrecognised answer: $RSH_OUT" ;;
  esac
fi

# --- Step 10: the diff against the committed tree ------------------------------------------------
say ""
say "== the diff against 06-EXPECTED-TREE.txt =="
rule
TD_RC=0
diff_expected_tree "$EXPECTED_TREE" "$OUT/oracle.destinations.txt" || TD_RC=$?
case "$TD_RC" in
  0) ok "ZERO LINES OF DIFFERENCE against the committed expected tree. This is the pass." ;;
  1)
    bad "the oracle's tree DIFFERS from the committed fixture. Both directions follow: a '<'
    line is expected-but-absent, a '>' line is present-but-unexpected."
    printf '%s\n' "$DIFF_OUT" | sed 's/^/         /'
    ;;
  *) unknown "the diff could not be evaluated: $TREE_DIFF_WHY" ;;
esac

# --- Step 11: cleanup ----------------------------------------------------------------------------
say ""
rsh "$(dex_cmd sh -c "'rm -rf $SCRATCH; [ -e $SCRATCH ] && echo present || echo gone'")"
if [ "$RSH_RC" -eq 0 ] && [ "$RSH_OUT" = "gone" ]; then
  ok "container scratch '$SCRATCH' removed and its absence asserted"
else
  bad "container scratch '$SCRATCH' is still present (or its removal could not be confirmed)"
fi
rsh "timeout $REMOTE_TIMEOUT rm -f $STAMP_REMOTE"

say ""
rule
if [ "$UNKNOWNS" -ne 0 ]; then
  say "  VERDICT: UNKNOWN, not green - $UNKNOWNS instrument(s) could not look."
  exit 3
fi
if [ "$REDS" -ne 0 ]; then
  say "  VERDICT: RED - $REDS assertion(s) failed."
  exit 1
fi
ok "VERDICT: GREEN - zero-diff against the committed tree, and nothing was written."
exit 0
