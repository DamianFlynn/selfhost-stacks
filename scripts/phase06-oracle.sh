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
#   PRECEDENCE, when one run BOTH measured a failure AND had an instrument that could not look:
#   3 (UNKNOWN) OUTRANKS 1 (RED). A BLIND INSTRUMENT WINS OVER A MEASURED RED. The two counters
#   are not mutually exclusive, so the order below is a DECISION and not an accident of how the
#   tail happens to be written. Reason, in one sentence: this estate's standing rule (CLAUDE.md
#   and README § Health Checks) is that "could not look" is never folded into another verdict,
#   and reporting a red while an instrument was blind asserts a cause the run did not establish.
#   THE SIBLING INSTRUMENT WRITTEN IN THIS SAME PHASE, scripts/phase06-incremental-control.sh,
#   FOLLOWS THE IDENTICAL CONVENTION - it consults its UNKNOWN counter before its FAIL counter,
#   and its own EXIT CODES block names this file back (IN-08; plan 06-20 aligned it, plan 06-19
#   wrote it down here). Its NUMBERING differs - there UNKNOWN is 2 and usage/refusal is 3 - and
#   that difference is deliberate and NOT a finding: committed evidence in this phase cites those
#   codes, so renumbering either script would invalidate it. Only the precedence is shared.
#   Implemented at the two lines that read `UNKNOWNS" -ne 0` and `REDS" -ne 0` at the foot of
#   this file, in that order.
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
# Every knob below is `${VAR:-default}` and every one of them can only make the verdict REDDER
# OR REFUSE THE RUN: a wrong host, a wrong container or a wrong output directory produces a
# refusal or an UNKNOWN, never a pass.
#
# The "or refuse the run" half is not a softening, it is the correction of a claim that used to
# be FALSE AS WRITTEN. Two of the knobs are not knobs on the verdict at all - `SCRATCH` and
# `STAMP_REMOTE` are ARGUMENTS TO DESTRUCTIVE REMOTE COMMANDS (`rm -rf` inside the container and
# `rm -f` on LXC 100), and a hostile value for either was not made redder by anything: it was
# passed through. `SCRATCH='/tmp/p6 /config'` word-split INSIDE the container into
# `rm -rf /tmp/p6 /config`. Both are now fenced to a LITERAL ALLOW-LIST at BOTH layers - once on
# the sending side before the first ssh of any mode, and once inside the remote program itself,
# adjacent to the `rm`. Grep for:
#
#     DESTRUCTIVE-KNOB FENCE      the sending-side allow-list, reached by --run, --baseline
#                                 and --self-test alike
#     remote_sh_c                 the helper every remote path goes through as a POSITIONAL
#                                 PARAMETER rather than as program text
#
# TWO PATHS ARE PLAIN CONSTANTS AND ARE DELIBERATELY NOT OVERRIDABLE:
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
    # The HEADER BLOCK is the --help output, and only the header block: a bare `grep '^#'` over
    # the whole file would also print every section comment and every line of the embedded Python,
    # which is a different document. Stop at the first line that is not a comment.
    -h|--help)
      LC_ALL=C awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)            say "unknown option: $1" >&2; usage ;;
  esac
done
[ -n "$MODE" ] || usage

# ==============================================================================================
# DESTRUCTIVE-KNOB FENCE  (WR-07; T-06-90 / T-06-91 / T-06-92)
# ==============================================================================================
# Two of the knobs above are not knobs on the VERDICT at all - they are ARGUMENTS TO DESTRUCTIVE
# REMOTE COMMANDS. `$SCRATCH` is `rm -rf`'d inside the container at step 12; `$STAMP_REMOTE` is
# `rm -f`'d on LXC 100 immediately after. `SCRATCH='/tmp/p6 /config'` word-split inside the
# container into `rm -rf /tmp/p6 /config` - deleting the real library.db, the real state.pickle
# and the vendored config - and the dirty-destination precheck could NOT stop it, because with
# two words `[ ! -e … ]` is an ARGUMENT ERROR rather than a refusal.
#
# So both are validated HERE, against literal allow-lists, before the script issues its first
# remote command. This line is reached by every mode the script supports - `--run`, `--baseline`
# and `--self-test` all pass through it, and the first ssh is well over a thousand lines below.
# A fence that only guarded `--run` would leave `--baseline`'s stamp write unfenced, and
# `--baseline` ALWAYS writes the stamp.
#
# The suffix character class is deliberately narrower than the glob: `/tmp/p6-*` on its own would
# still admit `/tmp/p6-x /config`, which is the very shape the fence exists to refuse.
#
# scripts/phase06-incremental-control.sh fences its two throwaway roots with the same literal
# `case` shape (`:343` and `:473`), and that script is not vulnerable to this. This is that shape
# applied here - and it is repeated INSIDE the remote programs too; see `remote_sh_c` and the
# cleanup step for why the duplication is deliberate.
SCRATCH_FENCE_OK=1
case "$SCRATCH" in
  /tmp/p6) : ;;
  /tmp/p6-*)
    case "${SCRATCH#/tmp/p6-}" in
      ''|*[!A-Za-z0-9._-]*) SCRATCH_FENCE_OK=0 ;;
    esac
    ;;
  *) SCRATCH_FENCE_OK=0 ;;
esac
[ "$SCRATCH_FENCE_OK" -eq 1 ] || precheck_fail "REFUSED: SCRATCH='$SCRATCH'.
    SCRATCH is an argument to an 'rm -rf' run inside the container, not a knob on the verdict, so
    it is fenced to a literal allow-list: exactly '/tmp/p6', or '/tmp/p6-' followed by one or more
    characters drawn from [A-Za-z0-9._-]. Nothing else is accepted, and nothing was sent."

STAMP_FENCE_OK=1
case "$STAMP_REMOTE" in
  /mnt/fast/safety/phase06/*)
    case "${STAMP_REMOTE#/mnt/fast/safety/phase06/}" in
      ''|*[!A-Za-z0-9._-]*) STAMP_FENCE_OK=0 ;;
    esac
    ;;
  *) STAMP_FENCE_OK=0 ;;
esac
[ "$STAMP_FENCE_OK" -eq 1 ] || precheck_fail "REFUSED: STAMP_REMOTE='$STAMP_REMOTE'.
    STAMP_REMOTE is an argument to an 'rm -f' run on LXC 100, not a knob on the verdict, so it is
    fenced to the literal prefix '/mnt/fast/safety/phase06/' followed by one or more characters
    drawn from [A-Za-z0-9._-]. Nothing else is accepted, and nothing was sent."

# --- IN-06 (T-06-94): the files BENEATH $SCRATCH are per-run unique -----------------------------
# The container's /tmp is world-writable and these names used to be fixed. A stale root-owned
# leftover turns a read into a BLIND; a pre-placed SYMLINK at a predictable name is followed by
# the `>` redirections below, so the instrument writes or reads something other than what it
# believes. Suffixing with the run's PID removes the predictability.
#
# SCRATCH ITSELF IS DELIBERATELY NOT UNIQUIFIED. The dirty-destination precheck, the cleanup
# assertion, the DESTRUCTIVE-KNOB FENCE's allow-list and the committed 06-11 artifacts all quote
# '/tmp/p6' by name; moving it would falsify all four at once. The directory stays fixed and
# fenced, and only its contents carry the run tag - which keeps every generated path inside the
# allow-list by construction.
RUN_TAG="$$"
SCRATCH_LIB="$SCRATCH/lib.$RUN_TAG.db"
SCRATCH_OVERLAY="$SCRATCH/overlay.$RUN_TAG.yaml"
SCRATCH_STATE="$SCRATCH/state.$RUN_TAG.pickle"

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
    # WR-02. Copied VERBATIM from the sibling instrument written in this same phase,
    # scripts/phase06-incremental-control.sh, which has carried this guard from the start - the
    # two scripts should read the same on the same question, so the reason text is not
    # paraphrased. Reachable with a CLEAN ssh status: `capture_manifests` builds each manifest
    # with `: > file` and appends, and `remote_manifest_meta`'s `find <dir> -type f -printf ...`
    # returns rc 0 AND NO OUTPUT on an existing but empty directory. Without this line, layer 2
    # of the three-layer wrote-nothing proof is satisfied by having measured nothing.
    if [ ! -s "$f" ]; then
      DIFF_WHY="manifest '$f' is EMPTY - an empty listing compares equal to any other empty listing, which would pass vacuously"
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
#
# TWO SANITISATIONS, both MEASURED against beets 2.12.0 rather than assumed, and both applied to a
# SEPARATE `.clean` file so the raw transcript stays the auditable record:
#
#   1. SGR (colour) sequences. `show_path_changes` calls `colordiff(source, dest)`
#      [beets/ui/commands/move.py@v2.12.0:57], which interleaves ESC[…m runs THROUGH BOTH PATHS -
#      `/m<ESC>[1;32media/M<ESC>[39;49;00music/`. Note where that lands: not only does a coloured
#      destination never equal a fixture line, `grep -q '/media/Music/'` over a coloured transcript
#      RETURNS NOTHING, so positive control 4 would have fired for a reason that is not a defect.
#   2. The trailing space on the source line of the narrow form. It is LITERAL and unconditional:
#      `ui.print_(f"{color_source} \n  -> {color_dest}")` [ibid.:50]. Left in place it rides into
#      the pairs file's source column and the CONF-03 join against `beet ls -f` misses every row.
#
# The overlay also sets `ui.color: no`, so on a correct run neither sanitisation has anything to
# do. They run anyway - a transcript that arrives coloured through some other route must normalise
# to the same answer, not to a silent COULD NOT LOOK.
NORM_WHY=""
NORM_PAIRS=0
NORM_INPLACE=0
NORM_INPLACE_SEEN=0
NORM_UNPARSED=0
NORM_CLEAN=""
NORM_SGR=0
normalise_transcript() { # $1 = raw transcript  $2 = pairs out  $3 = destinations out
  local raw="$1" pairs="$2" dests="$3" clean=""
  NORM_WHY=""; NORM_PAIRS=0; NORM_INPLACE=0; NORM_INPLACE_SEEN=0; NORM_UNPARSED=0
  NORM_CLEAN=""; NORM_SGR=0
  if [ ! -f "$raw" ] || [ ! -r "$raw" ]; then
    NORM_WHY="the raw transcript '$raw' is missing or unreadable"
    return 2
  fi
  clean="${raw}.clean"
  # $'\033' and NOT \x1b: \x1b is a GNU sed extension and this script runs on macOS.
  # The trailing-space strip is ADDRESSED to lines that carry no ' -> ', i.e. the source half of
  # the narrow form. A destination whose last component really does end in a space is a path-rule
  # FINDING, and blanket-stripping it here would erase the evidence for it.
  LC_ALL=C sed -e $'s/\033\\[[0-9;]*[A-Za-z]//g' -e '/ -> /!s/[[:space:]][[:space:]]*$//' "$raw" > "$clean" || {
    NORM_WHY="could not sanitise '$raw' into '$clean'"
    return 2
  }
  NORM_SGR="$(LC_ALL=C grep -c $'\033' "$raw" || true)"
  NORM_CLEAN="$clean"
  raw="$clean"
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

# --- Where `(N already in place)` ACTUALLY comes from ------------------------------------------
# MEASURED 2026-09-21 (plan 06-11, first live run). The count is NOT a standalone stdout line.
# `move_items` builds it as a fragment and hands it to the LOGGER:
#
#     unmoved_msg = f" ({num_unmoved} already in place)"
#     log.info("{} {} {}{}{}.", action, len(objs), entity, "s" if ..., unmoved_msg)
#     [SOURCE: beets/ui/commands/move.py@v2.12.0:94-107]
#
# So the real shape is `Moving 164 items (3 already in place).` on STDERR, one line, embedded.
# The standalone-line branch in normalise_transcript therefore CANNOT MATCH REAL OUTPUT: it
# returned "line ABSENT" and N=0, and a control whose predicate cannot fire is not a control.
# That branch is kept - a future beets could print it to stdout, and --self-test drives it - but
# THIS is the instrument, and its absence is a COULD NOT LOOK, never a zero.
#
# It also yields a fifth control for free: the N in `Moving N items` must equal the number of
# pairs actually printed. A transcript truncated in transit satisfies every other control.
MOVING_N=-1
UNMOVED_WHY=""
read_unmoved() { # $1 = the stderr file from `beet move -p`
  local err="$1" line=""
  UNMOVED_WHY=""; MOVING_N=-1
  if [ ! -f "$err" ] || [ ! -r "$err" ]; then
    UNMOVED_WHY="the move stderr '$err' is missing or unreadable, so '(N already in place)' was
    never read at all. That is COULD NOT LOOK, not N=0."
    return 2
  fi
  # Sanitised the same way the transcript is: the logger goes through ui and can colour too.
  line="$(LC_ALL=C sed $'s/\033\\[[0-9;]*[A-Za-z]//g' "$err" \
          | LC_ALL=C grep -E '^(Moving|Copying) [0-9]+ (item|album)s?( \([0-9]+ already in place\))?\.$' \
          | tail -n 1)" || true
  if [ -z "$line" ]; then
    UNMOVED_WHY="no 'Moving N items[ (M already in place)].' line was found in '$err'. beets emits
    it unconditionally through log.info, so its absence means the command did not reach that point
    - the unmoved count is UNKNOWN, not zero."
    return 2
  fi
  MOVING_N="$(printf '%s' "$line" | LC_ALL=C sed -E 's/^[A-Za-z]+ ([0-9]+) .*$/\1/')"
  case "$line" in
    *"already in place)."*)
      NORM_INPLACE_SEEN=1
      NORM_INPLACE="$(printf '%s' "$line" | LC_ALL=C sed -E 's/^.*\(([0-9]+) already in place\)\.$/\1/')"
      ;;
    *)
      # beets appends the fragment ONLY when num_unmoved > 0, so a line with no parenthetical is a
      # POSITIVE statement of zero from the same code path - not an absence of evidence.
      NORM_INPLACE_SEEN=1
      NORM_INPLACE=0
      ;;
  esac
  case "$NORM_INPLACE" in ''|*[!0-9]*) NORM_INPLACE=-1 ;; esac
  case "$MOVING_N" in ''|*[!0-9]*) MOVING_N=-1 ;; esac
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
  # Control 5, added by plan 06-11 after the first live run: `move_items` states how many objects
  # it is about to print. If that number disagrees with the number of pairs parsed, the transcript
  # was truncated in transit - and a truncated transcript satisfies every control above.
  if [ "$MOVING_N" -ge 0 ] && [ "$MOVING_N" -ne "$NORM_PAIRS" ]; then
    PC_WHY="beets logged 'Moving $MOVING_N items' but only $NORM_PAIRS pair(s) were parsed out of
    the transcript. The two come from the same loop, so a disagreement means the stdout was
    truncated between the container and here."
    return 3
  fi
  # The SANITISED text, not the raw: colordiff interleaves SGR runs through the path itself, so
  # `grep -q '/media/Music/'` over a coloured transcript returns nothing and this control would
  # fire for a reason that is not a defect. NORM_CLEAN is set by normalise_transcript, which every
  # caller runs first; the fallback keeps the function total rather than silently grepping nothing.
  if ! LC_ALL=C grep -q "$LIB_ROOT/" "${NORM_CLEAN:-$raw}"; then
    PC_WHY="the transcript contains no '$LIB_ROOT/' substring at all, so whatever was
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
# THE CLASS ASSERTIONS  (D-27)
# ==============================================================================================
# The diff catches WRONG PATHS. These catch NEW FAILURE CLASSES nobody wrote an expected line
# for - which is the whole reason D-27 asks for both halves and not just the cheaper one. Each
# assertion is its own red with its own message, and each prints WHAT IT FOUND rather than only
# that it failed.
#
# Every one of them sets ASSERT_WHY (one line) and writes its evidence rows to ASSERT_EVIDENCE,
# then returns 0 clean / 1 RED / 2 COULD NOT LOOK. None of them prints. That is what lets
# `--self-test` drive the red branch of each one and compare a return code, instead of grepping
# a human-readable report - and it keeps the three-outcome vocabulary the same as layer 2's.
ASSERT_WHY=""
ASSERT_EVIDENCE=""

# --- CONF-03: the top level of every destination is the item's own album artist ----------------
# BYTE-EXACT, case included, and deliberately not case-folded: a capitalisation-only mismatch
# renders a DUPLICATE ARTIST PAGE in Jellyfin, which is the defect CONF-03 exists to prevent.
# Three shapes, all read off the committed `paths:` stanza rather than assumed:
#   rules 3+2  DJ/<albumartist>/<album>/...        -> the SECOND component is the album artist
#   rule 1     Singles/<artist>/<title>.<ext>      -> the SECOND component is $artist, not
#                                                     $albumartist; the singleton rule names
#                                                     $artist and a singleton often has no
#                                                     album artist at all
#   rules 4,5,6 <albumartist>/<album>/...          -> the FIRST component
# A mismatch caused by the `replace:` block sanitising a character out of the album artist is a
# FINDING to read, not a bug in this check: it means the tree cannot round-trip that artist name.
assert_top_level() { # $1 = pairs TSV  $2 = fields TSV
  local pairs="$1" fields="$2" ev="$OUT/assert.toplevel.txt" nbad=0 nblind=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  if [ ! -r "$pairs" ] || [ ! -r "$fields" ]; then
    ASSERT_WHY="the pairs or the fields file is missing or unreadable"
    return 2
  fi
  LC_ALL=C awk -F'\t' -v root="$LIB_ROOT/" '
    NR == FNR { aa[$1] = $2; ar[$1] = $5; seen[$1] = 1; next }
    {
      src = $1; dst = $2
      if (index(dst, root) != 1) { printf "OUTSIDE-ROOT\t%s\n", dst; next }
      rel = substr(dst, length(root) + 1)
      n = split(rel, c, "/")
      if (!seen[src]) { printf "NO-LIBRARY-ROW\t%s\n", src; next }
      if (c[1] == "DJ")           { want = aa[src]; got = c[2]; shape = "DJ/<albumartist>/" }
      else if (c[1] == "Singles") { want = ar[src]; got = c[2]; shape = "Singles/<artist>/" }
      else                        { want = aa[src]; got = c[1]; shape = "<albumartist>/" }
      if (got != want)
        printf "MISMATCH\t%s\tfound <%s> expected <%s>\t%s\n", dst, got, want, shape
    }' "$fields" "$pairs" > "$ev"
  nbad="$(LC_ALL=C grep -c '^MISMATCH' "$ev" || true)"
  nblind="$(LC_ALL=C grep -c -e '^NO-LIBRARY-ROW' -e '^OUTSIDE-ROOT' "$ev" || true)"
  if [ "$nblind" -ne 0 ]; then
    ASSERT_WHY="$nblind destination(s) have no library field row, or sit outside $LIB_ROOT/ - the
    comparison could not be made for them"
    return 2
  fi
  if [ "$nbad" -ne 0 ]; then
    ASSERT_WHY="$nbad destination(s) do not carry their own album artist at the top level"
    return 1
  fi
  ASSERT_WHY="every destination's top level is its item's own album artist, byte-exact"
  return 0
}

# --- D-15: no `Compilations/`, and the compilation stratum must actually have been exercised ---
# The `comp:` key is an OVERRIDE of an inherited rule, not a deletion - there is no way to delete
# the inherited `Compilations/...` rule - so if that key is ever removed, `Compilations/` comes
# straight back silently. Asserting its absence over a sample that contains no compilation at all
# would be vacuous, which is why the `Various Artists` positive control is part of this check and
# not a separate nicety.
assert_no_compilations() { # $1 = destination list
  local dest="$1" ev="$OUT/assert.comp.txt" nc=0 nva=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  [ -r "$dest" ] || { ASSERT_WHY="the destination list is missing or unreadable"; return 2; }
  LC_ALL=C grep -F '/Compilations/' "$dest" > "$ev" || true
  nc="$(wc -l < "$ev" | tr -d ' ')"
  nva="$(LC_ALL=C awk -v root="$LIB_ROOT/" '
    index($0, root) == 1 {
      rel = substr($0, length(root) + 1); split(rel, c, "/")
      if (c[1] == "Various Artists") n++
    } END { print n + 0 }' "$dest")"
  if [ "$nc" -ne 0 ]; then
    ASSERT_WHY="$nc destination(s) contain a Compilations/ component - the comp: override is gone"
    return 1
  fi
  if [ "$nva" -eq 0 ]; then
    printf 'NO-VARIOUS-ARTISTS\tnot one destination has the literal `Various Artists` at its top level\n' > "$ev"
    ASSERT_WHY="zero Compilations/ - but ALSO zero destinations under the literal Various Artists,
    so the compilation stratum never reached the comp: rule and the result is VACUOUS"
    return 1
  fi
  ASSERT_WHY="zero Compilations/ components, and $nva destination(s) under the literal Various Artists"
  return 0
}

# --- D-13: the DJ count is an EQUALITY, not a floor -------------------------------------------
# `albumtype:dj` would be a SUBSTRING match; the config uses `albumtype:=dj` (exact). The failure
# mode that matters is the silent one: a rule that fails to match lets everything fall through to
# `default`, which still produces a perfectly valid-looking tree. Only the equality catches that.
assert_dj_count() { # $1 = destination list  $2 = expected DJ file count
  local dest="$1" want="$2" ev="$OUT/assert.dj.txt" got=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  [ -r "$dest" ] || { ASSERT_WHY="the destination list is missing or unreadable"; return 2; }
  # IN-09. The guard its immediate neighbour assert_no_compilations has had from the start, in the
  # same vocabulary and returning the same code: an unexercised stratum is VACUOUS, not a pass.
  # Without it a sample whose S5 rows sum to zero compares `0 -ne 0`, which is false, and the
  # equality ticks green having tested nothing. The cross-check at step 11 does not save it: that
  # one only fires when the sample and the fixture DISAGREE, and zero against zero agrees.
  if [ "$want" -eq 0 ]; then
    printf 'NO-S5-STRATUM\tthe expected DJ file count is zero, so the albumtype rule was never reached\n' > "$ev"
    ASSERT_WHY="the sample holds NO S5 files, so the albumtype:=dj path rule was never exercised
    and comparing zero against zero is VACUOUS, not a pass. This is also the refusal that turns
    DEF-06-12-01 - path rule 2 (albumtype:=dj disctotal:2..), the one paths: rule no Phase 6
    instrument has ever evaluated, deferred and unowned - from a SILENCE into something the next
    run over a DJ-less sample says out loud."
    return 1
  fi
  LC_ALL=C awk -v root="$LIB_ROOT/" '
    index($0, root) == 1 {
      rel = substr($0, length(root) + 1); split(rel, c, "/")
      if (c[1] == "DJ") print
    }' "$dest" > "$ev"
  got="$(wc -l < "$ev" | tr -d ' ')"
  if [ "$got" -ne "$want" ]; then
    ASSERT_WHY="$got destination(s) under DJ/, but the sample's S5 strata hold $want files. This is
    an EQUALITY: a short count means the albumtype rule did not fire and the difference fell
    through to default, which looks entirely healthy in the tree."
    return 1
  fi
  ASSERT_WHY="DJ/ destinations = $got, exactly the sampled DJ file count"
  return 0
}

# --- D-16: every %aunique{} firing is listed, and the numeric-id fallback is a hard guard -------
# A firing is a trailing ` [...]` on the album component. The predicted set is taken from the
# COMMITTED fixture's own path lines rather than from prose in its header: the header documents
# one firing and the path lines carry exactly that one, and only the path lines are mechanically
# checkable. Both directions are reported, because predicted-but-absent and present-but-
# unpredicted are different findings.
#
# THE GUARD: when NO disambiguator separates an ambiguous set, beets appends the NUMERIC DATABASE
# ID - " [123]" - which is not reproducible across libraries [beets/library/models.py@v2.12.0
# _tmpl_unique]. A bracketed bare integer that is not a four-digit year is therefore a landmine,
# not a disambiguator, and it is a red wherever it appears.
assert_aunique() { # $1 = destination list  $2 = committed expected tree
  local dest="$1" exp="$2" ev="$OUT/assert.aunique.txt" nid=0 nmiss=0 nextra=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  if [ ! -r "$dest" ] || [ ! -r "$exp" ]; then
    ASSERT_WHY="the destination list or the committed tree is missing or unreadable"
    return 2
  fi
  LC_ALL=C awk -F/ 'NF >= 2 { a = $(NF-1); if (a ~ / \[.*\]$/) print a }' "$dest" \
    | LC_ALL=C sort -u > "$OUT/.aunique.got"
  LC_ALL=C grep -v '^#' "$exp" \
    | LC_ALL=C awk -F/ 'NF >= 2 { a = $(NF-1); if (a ~ / \[.*\]$/) print a }' \
    | LC_ALL=C sort -u > "$OUT/.aunique.want"
  : > "$ev"
  LC_ALL=C comm -13 "$OUT/.aunique.got" "$OUT/.aunique.want" | sed 's/^/PREDICTED-BUT-ABSENT\t/' >> "$ev"
  LC_ALL=C comm -23 "$OUT/.aunique.got" "$OUT/.aunique.want" | sed 's/^/PRESENT-BUT-UNPREDICTED\t/' >> "$ev"
  LC_ALL=C sed 's/^/FIRED\t/' "$OUT/.aunique.got" >> "$ev"
  LC_ALL=C awk -F'\t' '$1 == "FIRED" {
      v = $2; sub(/^.* \[/, "", v); sub(/\]$/, "", v)
      if (v ~ /^[0-9]+$/ && !(length(v) == 4 && v + 0 >= 1900 && v + 0 <= 2099))
        printf "NUMERIC-DATABASE-ID\t%s\n", $2
    }' "$ev" > "$OUT/.aunique.id"
  cat "$OUT/.aunique.id" >> "$ev"
  nid="$(wc -l < "$OUT/.aunique.id" | tr -d ' ')"
  nmiss="$(LC_ALL=C grep -c '^PREDICTED-BUT-ABSENT' "$ev" || true)"
  nextra="$(LC_ALL=C grep -c '^PRESENT-BUT-UNPREDICTED' "$ev" || true)"
  if [ "$nid" -ne 0 ]; then
    ASSERT_WHY="$nid firing(s) rendered a bare integer that is not a four-digit year - that is the
    NUMERIC DATABASE ID fallback, which is not reproducible across libraries"
    return 1
  fi
  if [ "$nmiss" -ne 0 ] || [ "$nextra" -ne 0 ]; then
    ASSERT_WHY="%aunique{} firings disagree with the fixture: $nmiss predicted-but-absent,
    $nextra present-but-unpredicted"
    return 1
  fi
  ASSERT_WHY="%aunique{} fired $(wc -l < "$OUT/.aunique.got" | tr -d ' ') time(s), exactly the set the fixture predicts"
  return 0
}

# --- D-19b: every singleton resolution is LISTED; the list is the deliverable -------------------
# Phase 3 measured rc6 turning ONE 20-track release into twenty single-track albums when `album`
# was empty - no error, no prompt, no UI signal. So a folder landing in Singles/ is usually an
# album beets failed to group, not a genuine single. An unexpected singleton is a red; an expected
# one is a listed pass, and it is still listed.
assert_singletons() { # $1 = destination list  $2 = committed expected tree  $3 = pairs TSV
  local dest="$1" exp="$2" pairs="$3" ev="$OUT/assert.singles.txt" nmiss=0 nextra=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  if [ ! -r "$dest" ] || [ ! -r "$exp" ] || [ ! -r "$pairs" ]; then
    ASSERT_WHY="the destination list, the committed tree or the pairs file is unreadable"
    return 2
  fi
  LC_ALL=C grep -F "$LIB_ROOT/Singles/" "$dest" | LC_ALL=C sort -u > "$OUT/.singles.got" || true
  LC_ALL=C grep -v '^#' "$exp" | LC_ALL=C grep -F "$LIB_ROOT/Singles/" | LC_ALL=C sort -u > "$OUT/.singles.want" || true
  : > "$ev"
  # The source FOLDER is what a reader needs in order to go and look, so it is carried alongside.
  LC_ALL=C awk -F'\t' -v root="$LIB_ROOT/Singles/" '
    NR == FNR { src[$2] = $1; next }
    index($0, root) == 1 {
      s = src[$0]; sub(/\/[^\/]*$/, "", s)
      printf "SINGLETON\t%s\tfrom %s\n", $0, (s == "" ? "<no source row>" : s)
    }' "$pairs" "$OUT/.singles.got" >> "$ev"
  LC_ALL=C comm -13 "$OUT/.singles.got" "$OUT/.singles.want" | sed 's/^/EXPECTED-BUT-ABSENT\t/' >> "$ev"
  LC_ALL=C comm -23 "$OUT/.singles.got" "$OUT/.singles.want" | sed 's/^/UNEXPECTED-SINGLETON\t/' >> "$ev"
  nmiss="$(LC_ALL=C grep -c '^EXPECTED-BUT-ABSENT' "$ev" || true)"
  nextra="$(LC_ALL=C grep -c '^UNEXPECTED-SINGLETON' "$ev" || true)"
  if [ "$nmiss" -ne 0 ] || [ "$nextra" -ne 0 ]; then
    ASSERT_WHY="singleton resolutions disagree with the fixture: $nmiss expected-but-absent,
    $nextra UNEXPECTED - and an unexpected singleton is usually an album beets failed to group"
    return 1
  fi
  ASSERT_WHY="$(wc -l < "$OUT/.singles.got" | tr -d ' ') singleton resolution(s), all of them expected and all listed"
  return 0
}

# --- D-19a, BLOCKING: no album directory whose basename equals its parent artist directory ------
# THIS ASSERTION IS THE ONLY GUARD THERE IS, and that is a structural fact rather than a choice:
# beets' query language has NO FIELD-TO-FIELD COMPARISON, so there is no path-template expression
# for "album equals albumartist" and the rule cannot be made to refuse the shape by itself. The
# existing live defect - `Def Leppard/Def Leppard (2015)/`, which derives an EMPTY album artist in
# Music Assistant and hard-errors one FLAC - is scheduled for repair in Phase 7. Phase 6's job is
# to stop anything NEW landing in that shape, so this is blocking.
# The `<parent> (` prefix shape is REPORTED and not failed: it is the shape of the live defect,
# and seeing it in a dry run is worth knowing without being worth blocking on.
assert_album_ne_artist() { # $1 = destination list
  local dest="$1" ev="$OUT/assert.albumartist.txt" neq=0 nrep=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  [ -r "$dest" ] || { ASSERT_WHY="the destination list is missing or unreadable"; return 2; }
  LC_ALL=C awk -F/ 'NF >= 3 {
      a = $(NF-1); p = $(NF-2)
      la = tolower(a); lp = tolower(p)
      if (la == lp) { printf "ALBUM-EQUALS-ARTIST\t%s\n", $0; next }
      if (index(la, lp " (") == 1) printf "REPORT-SAME-PREFIX\t%s\n", $0
    }' "$dest" | LC_ALL=C sort -u > "$ev"
  neq="$(LC_ALL=C grep -c '^ALBUM-EQUALS-ARTIST' "$ev" || true)"
  nrep="$(LC_ALL=C grep -c '^REPORT-SAME-PREFIX' "$ev" || true)"
  if [ "$neq" -ne 0 ]; then
    ASSERT_WHY="$neq destination(s) have an album directory equal to their artist directory
    (case-folded). BLOCKING - there is no beets query that can express this, so this check is it."
    return 1
  fi
  ASSERT_WHY="zero album directories equal their artist directory; $nrep reported with the
    '<artist> (' prefix shape, which is the live Def Leppard defect's shape and is NOT failed here"
  return 0
}

# --- The `-1 - ` shape: the previous tagger's signature failure ---------------------------------
# wrtag v0.20.0 hard-set `Track.Position = -1`, so this repo's path format named every file
# `-1 - Title.ext`. wrtag is retired, but the grep costs nothing and a number that renders as -1
# is a template defect in any engine.
assert_no_minus_one() { # $1 = destination list
  local dest="$1" ev="$OUT/assert.minusone.txt" n=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  [ -r "$dest" ] || { ASSERT_WHY="the destination list is missing or unreadable"; return 2; }
  LC_ALL=C awk -F/ '{ b = $NF; if (index(b, "-1 - ") == 1) printf "MINUS-ONE\t%s\n", $0 }' "$dest" > "$ev"
  n="$(wc -l < "$ev" | tr -d ' ')"
  if [ "$n" -ne 0 ]; then
    ASSERT_WHY="$n destination filename(s) begin with '-1 - '"
    return 1
  fi
  ASSERT_WHY="zero destination filenames begin with '-1 - '"
  return 0
}

# --- The `.N` collision suffix shape ------------------------------------------------------------
# beets appends `.1`, `.2` ... before the extension when a destination already exists. Phase 7's
# criterion 7 sweep exists to hunt these; catching one in a dry run is cheaper than catching it
# in the library. The predicate is `<name>.<digits>.<ext>` on the BASENAME.
assert_no_collision_suffix() { # $1 = destination list
  local dest="$1" ev="$OUT/assert.collision.txt" n=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  [ -r "$dest" ] || { ASSERT_WHY="the destination list is missing or unreadable"; return 2; }
  LC_ALL=C awk -F/ '{ b = $NF; if (b ~ /\.[0-9]+\.[^.\/]+$/) printf "COLLISION-SUFFIX\t%s\n", $0 }' "$dest" > "$ev"
  n="$(wc -l < "$ev" | tr -d ' ')"
  if [ "$n" -ne 0 ]; then
    ASSERT_WHY="$n destination(s) carry a .N disambiguation suffix, which means beets found the
    destination already taken"
    return 1
  fi
  ASSERT_WHY="zero destinations carry a .N collision suffix"
  return 0
}

# --- D-18: the protected DJ fields, as an NDJSON ledger ------------------------------------------
# The ledger itself is generated inside the container (see ledger_payload below). THIS function
# judges it, and it judges structurally rather than by parsing values, because the generator emits
# canonical compact JSON with a fixed key order and a value-parser in awk would be a second place
# for a bug to hide.
#   * exactly FIVE records per sampled file - bpm, initial_key, genres, comments, EnergyLevel -
#     so a file that was skipped is a count failure, not an invisible absence.
#   * A REFUSAL IS A RECORD, NEVER A SKIP: a file that cannot be read produces five `failed`
#     records carrying the exception, in the scripts/normalise-dj-tags.py:1316-1339 shape.
#   * every record must carry `"noop":true`. Phase 6 writes nothing, so any record proposing a
#     different value for a protected field is a red and is printed in full.
assert_protected_fields() { # $1 = NDJSON ledger  $2 = expected sampled file count
  local led="$1" files="$2" ev="$OUT/assert.protected.txt" want=0 got=0 nfail=0 nchg=0 nnull=0
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  [ -r "$led" ] || { ASSERT_WHY="the D-18 ledger '$led' is missing or unreadable"; return 2; }
  want=$((files * 5))
  got="$(wc -l < "$led" | tr -d ' ')"
  : > "$ev"
  LC_ALL=C grep -F '"failed":' "$led" | sed 's/^/LEDGER-FAILED\t/' >> "$ev" || true
  LC_ALL=C grep -v -F '"noop":true' "$led" | sed 's/^/PROPOSED-CHANGE\t/' >> "$ev" || true
  nfail="$(LC_ALL=C grep -c '^LEDGER-FAILED' "$ev" || true)"
  nchg="$(LC_ALL=C grep -c '^PROPOSED-CHANGE' "$ev" || true)"
  # Counted and REPORTED, never merely swallowed into the noop total. These are records where
  # both sides are absent and only the spelling of "absent" differs (mediafile's None against
  # beets' typed null). They are listed in the evidence file so the class is auditable.
  nnull="$(LC_ALL=C grep -c -F '"null_equivalent":true' "$led" || true)"
  LC_ALL=C grep -F '"null_equivalent":true' "$led" | sed 's/^/NULL-EQUIVALENT\t/' >> "$ev" || true
  if [ "$got" -ne "$want" ]; then
    printf 'LEDGER-COUNT\t%s records, expected %s (5 protected fields x %s sampled files)\n' \
      "$got" "$want" "$files" >> "$ev"
    ASSERT_WHY="the ledger holds $got records against an expected $want - a file was not covered,
    and an absence is exactly what a skip looks like"
    return 2
  fi
  if [ "$nfail" -ne 0 ]; then
    ASSERT_WHY="$nfail ledger record(s) are refusals - a protected field could not be read at all"
    return 2
  fi
  if [ "$nchg" -ne 0 ]; then
    ASSERT_WHY="$nchg ledger record(s) propose a CHANGE to a protected DJ field. MusicBrainz
    carries none of bpm / key / energy / operator comments, so an import is the specific thing
    that strips exactly what makes a track playable (D-18)."
    return 1
  fi
  ASSERT_WHY="$got ledger records, five per sampled file, every one a noop - no protected DJ
    field is proposed for change ($nnull of them absent on both sides, listed as NULL-EQUIVALENT)"
  return 0
}

# --- IN-12: the field view must have been PRODUCED before its column count means anything -------
# This used to be three inline lines at step 11, and inline it could only be reasoned about, never
# fed an input. `awk -F'\t' 'NF != 6 {n++} END {print n + 0}'` over an EMPTY fields.tsv yields 0,
# and the script printed `field view read: 0 items, six columns each` - a tick asserting that every
# one of zero items had six columns. Zero items does not mean the columns were right; it means the
# view was never produced. `assert_top_level` does catch it downstream (every pair becomes
# NO-LIBRARY-ROW -> rc 2 -> unknown), so the run VERDICT was already right - the tick was not, and
# a tick that the verdict has to be rescued from is the defect this plan closes.
#
# Returns 0 clean / 2 COULD NOT LOOK. There is no red arm: a malformed field view is never a
# statement about the tree, only about the instrument.
assert_field_view() { # $1 = fields TSV
  local fields="$1" nbad=0 nrows=0
  ASSERT_WHY=""; ASSERT_EVIDENCE=""
  if [ ! -r "$fields" ]; then
    ASSERT_WHY="the field view '$fields' is missing or unreadable, so nothing was read"
    return 2
  fi
  if [ ! -s "$fields" ]; then
    ASSERT_WHY="the field view is EMPTY. ZERO ITEMS DOES NOT MEAN EVERY ITEM HAD SIX COLUMNS - it
    means the view was NOT PRODUCED, and the CONF-03 join has nothing to join against."
    return 2
  fi
  nbad="$(LC_ALL=C awk -F'\t' 'NF != 6 {n++} END {print n + 0}' "$fields")"
  if [ "$nbad" -ne 0 ]; then
    ASSERT_WHY="$nbad row(s) of the field view do not have six tab-separated columns - a path
    containing a tab would do this, and the join behind CONF-03 cannot be trusted."
    return 2
  fi
  nrows="$(wc -l < "$fields" | tr -d ' ')"
  ASSERT_WHY="$nrows items, six columns each"
  return 0
}

# --- CONF-04's write side (D-23 as amended by D-34), REPORTED ------------------------------------
# Returns 0 WHENEVER IT COULD LOOK: this is the dry run SHOWING what an import would write, which
# is what D-23 asked for, corrected by D-34. It is a report, so zero qualifying rows is a finding
# and not a failure - but ONLY when the rows were actually counted.
#
# WR-06. It used to return 0 on an UNREADABLE input too, and `run_assert` maps 0 to `ok`, so the
# console printed a GREEN TICK followed by, verbatim:
#
#     CONF-04 write side: the fields TSV is missing or unreadable, so the write side could not be shown
#
# A green tick whose own text says the instrument did not look - the exact shape CLAUDE.md
# Health Checks exists to outlaw. "A report may never block the run" is a real intent, but it is
# not preserved by ticking over a blind read; it is preserved by keeping `return 0` for the case
# where the file WAS read and simply held no qualifying row. Both could-not-look branches now
# return 2, which `run_assert`'s `*)` arm routes to `unknown()`.
#
# beets CANNOT be configured to emit `;` inside ARTIST - no
# delimiter or join key exists in config_default.yaml at either version - so the multi-artist
# information lands in ARTISTS (TXXX / Vorbis), and `artist` carries MusicBrainz's own join
# phrases concatenated. That is why D-34 enables PreferNonstandardArtistsTag on Jellyfin's Music
# library: it makes the two consumers agree by construction rather than by coincidence.
report_multi_artist() { # $1 = fields TSV
  local fields="$1" ev="$OUT/report.multiartist.txt"
  ASSERT_WHY=""; ASSERT_EVIDENCE="$ev"
  if [ ! -r "$fields" ]; then
    ASSERT_WHY="the fields TSV is missing or unreadable, so the write side could not be shown"
    return 2
  fi
  # An EXISTING but EMPTY field view is the same could-not-look wearing a different hat: the awk
  # below would count zero qualifying rows and the message would read as a measurement. The
  # field-view read at step 11 reports this condition first; this is a DELIBERATE RESTATEMENT and
  # the message says so, because the alternative is that the "CONF-04 write side" label goes
  # SILENT on exactly the input it cannot handle, and a label that vanishes from the transcript is
  # worse than a label that appears twice.
  if [ ! -s "$fields" ]; then
    ASSERT_WHY="the fields TSV is EMPTY, so nothing could be shown and zero rows is not a
    measurement. (Restated: the field-view read above reports the same condition. It is repeated
    here so this label is not silent on the one input it cannot judge.)"
    return 2
  fi
  # `artists` is MULTI_VALUE_DSV and renders joined with a literal backslash + U+2400 in a
  # template, so it is translated to '; ' for display only. The FILE is not touched.
  LC_ALL=C awk -F'\t' '
    NF >= 6 && $6 != "" {
      v = $6; gsub(/\\\342\220\200/, "; ", v)
      printf "WRITE-SIDE\t%s\tartist=<%s>\tartists=<%s>\n", $1, $5, v
    }' "$fields" > "$ev"
  # Two different numbers, and conflating them is how a report starts overstating itself: the
  # predicate above is "carries a NON-EMPTY artists field", which is not the same as "carries
  # MORE THAN ONE artist". Both are stated. The second is the one D-23/D-34 is about.
  local nrows=0 nmulti=0 nread=0
  nrows="$(wc -l < "$ev" | tr -d ' ')"
  nmulti="$(LC_ALL=C grep -c 'artists=<[^>]*; ' "$ev" || true)"
  # The denominator is stated so a zero above is EMPTY-BY-MEASUREMENT and cannot be confused with
  # the empty-input refusal a dozen lines up. This is the only branch that returns 0.
  nread="$(wc -l < "$fields" | tr -d ' ')"
  ASSERT_WHY="$nread field-view row(s) READ; of them $nrows item(s) carry a non-empty artists
    field, $nmulti with MORE THAN ONE artist; beets cannot emit ';' inside ARTIST, so the
    multi-artist information lands in ARTISTS (D-23 amended by D-34)"
  return 0
}

# --- The reporting wrapper the real run uses (the self-test compares return codes instead) -------
run_assert() { # $1 = label  $2.. = assertion and its arguments
  local label="$1" rc=0
  shift
  "$@" || rc=$?
  case "$rc" in
    0) ok "$label: $ASSERT_WHY" ;;
    1)
      bad "$label: $ASSERT_WHY"
      [ ! -s "$ASSERT_EVIDENCE" ] || head -n 20 "$ASSERT_EVIDENCE" | sed 's/^/         /' || true
      ;;
    *)
      unknown "$label: $ASSERT_WHY"
      [ ! -s "$ASSERT_EVIDENCE" ] || head -n 20 "$ASSERT_EVIDENCE" | sed 's/^/         /' || true
      ;;
  esac
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

rsh_from_to() { # $1 = command string  $2 = local stdin file  $3 = local stdout file
  RSH_RC=0
  ssh -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" "root@$LXC_HOST" "$1" < "$2" > "$3" 2> "${3}.err" || RSH_RC=$?
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

# --- remote_sh_c: every remote path crosses the boundary as a PARAMETER  (WR-08; T-06-93) ------
# A path must NEVER be interpolated into the TEXT of a remote `sh -c '…'` program. `printf '%q'`
# quotes for BASH, and bash quotes an apostrophe as `\'` - which TERMINATES the single-quoted
# program the result was embedded in. `Guns N' Roses - Greatest Hits`, an entirely ordinary shape
# for this corpus, then produces `unexpected EOF while looking for matching '` on the far side,
# which reads as an infrastructure fault rather than as a quoting bug in this file. A `$` in a
# folder name is the same defect with a quieter symptom: it expands instead of erroring.
#
# So the program text carries NO PATH AT ALL. Paths are passed as POSITIONAL PARAMETERS of the
# remote `sh -c` and referenced as "$1", "$2" … inside it. `%q` is still used - but on the
# ARGUMENTS, where the result lands in a bash WORD, which is the one context `%q` is correct for.
# The literal `sh` after the program text is $0; without it the first real argument is eaten.
#
# This is also the helper the DESTRUCTIVE-KNOB FENCE's second layer goes through: the remote
# programs that run `rm -rf` / `rm -f` re-test their path against the same literal allow-list
# before running it. The duplication is deliberate and is explained at those two call sites.
remote_sh_c() { # $1 = program text (run by the remote /bin/sh)  $2.. = its positional parameters
  local prog="$1" out="" a=""
  shift
  out="sh -c $(printf '%q' "$prog") sh"
  for a in "$@"; do
    out="$out $(printf '%q' "$a")"
  done
  printf '%s' "$out"
}

# --- The dirty-destination probe, sent into the container at step 1 (WR-01) ---------------------
# It lives HERE, with the remote layer, rather than inline at its one call site, so that
# `--self-test` can execute the program text against local fixtures with no docker and no ssh.
#
# The old shape was ONE PIPELINE sent into the container:
#
#     [ ! -e "$1" ] && echo absent || ls -A "$1" | head -n 1
#
# and it was the single line in this file that broke the house rule at the top: the container's
# /bin/sh IS dash and has NO `pipefail`, so a pipeline's status is `head`'s status, and `head`
# exits 0 whatever `ls` did. A $SCRATCH left root-owned 0700 by an aborted run therefore gave
# `ls: cannot open directory: Permission denied` on stderr, an EMPTY stdout and a ZERO status -
# so neither the RSH_RC guard nor the `[ -n "$RSH_OUT" ]` guard fired, and the precheck whose
# entire job is to refuse printed the green line "absent or empty". A could-not-look reported as
# the good answer. Measured: `/bin/sh -c 'ls -A /nonexistent | head -n 1; echo rc=$?'` -> rc=0.
#
# WHY THIS CONSTRUCTION CANNOT SILENTLY EXIT 0 ON AN UNREADABLE DIRECTORY: there is no pipeline,
# so there is nothing that can launder a status. `find` on a directory it cannot read writes a
# diagnostic to stderr and returns NON-ZERO (GNU find and busybox find alike) - that non-zero is
# precisely the status `| head` used to throw away. It is read by `||` on the very same line,
# because the ONLY command in that assignment is the command substitution, and POSIX specifies
# that such an assignment's exit status IS the substitution's. The probe then exits 4, which
# `docker exec` propagates, which `rsh` records in RSH_RC, which the call site refuses on.
#
# And THE ANSWER IS ALWAYS A WORD, never an absence: `absent`, `empty`, `notadir`, or
# `nonempty <first entry>`. Emptiness of stdout is no longer evidence of anything, so an
# unanticipated outcome falls to the call site's `*)` arm and REFUSES instead of being read as
# "nothing there". stderr is deliberately NOT redirected: find's own diagnostic reaches the
# operator's terminal, where it explains the exit 4.
SCRATCH_PROBE_PROG='if [ ! -e "$1" ]; then echo absent; exit 0; fi
if [ ! -d "$1" ]; then echo notadir; exit 0; fi
out=$(find "$1" -mindepth 1 -maxdepth 1) || exit 4
if [ -z "$out" ]; then echo empty; exit 0; fi
nl="
"
printf "nonempty %s\n" "${out%%$nl*}"'

# ==============================================================================================
# THE RECEIVING-SIDE (SECOND-LAYER) FENCES, AND THE THREE DESTRUCTIVE PROGRAMS THEY GUARD
# (WR-07; GC-02; T-06-90 / T-06-91 / T-06-92)
# ==============================================================================================
# These live HERE, beside the rest of the remote layer, for exactly the reason SCRATCH_PROBE_PROG
# does: `--self-test` must be able to execute the fence TEXT - and the programs' own text - against
# local fixtures, with no docker and no ssh. Their call sites are step 4 (the stamp write) and
# step 12 (cleanup), both far below; both carry a pointer back here.
#
# GC-02, AND WHAT WAS ACTUALLY WRONG - stated once, here, and cross-referenced at the other two
# sites rather than repeated. Until this change the three receiving-side fences were the BARE GLOBS
# `/tmp/p6|/tmp/p6-*` and `/mnt/fast/safety/phase06/*`, while the sending-side fence at :327 has
# always narrowed the suffix to [A-Za-z0-9._-]. That class EXCLUDES `/` and a glob does not, so the
# inner layer accepted `/tmp/p6-x/../../../home` and `/mnt/fast/safety/phase06/../../../../etc/shadow`
# and would have run `rm -rf` / `rm -f` on them - while the comment beside it claimed this was the
# layer that could not be bypassed. The two copies WR-07 asked to be watched for drift had already
# drifted, at birth, in the direction that matters. Nothing was exploitable as shipped, because the
# sending fence runs before the first ssh of every mode; what was false was the CLAIM, and a false
# claim about a fence is how the real fence eventually gets deleted as "duplicated".
#
# The predicate below is now the sending side's, in POSIX form: an outer `case` on the literal root,
# a nested `case` on the suffix refusing the empty string and anything carrying a byte outside
# [A-Za-z0-9._-]. `""` rather than `''` for the empty pattern only because these are single-quoted
# bash strings; dash treats the two patterns identically.
#
# THREE LITERAL COPIES, ON PURPOSE, one per destructive site - so no site inherits another's
# correctness by aliasing, and each can be driven on its own. The trade is deliberate and is the
# lesson of GC-02: the defect was never the duplication, it was that the duplication drifted in
# SILENCE. So drift is now an EXECUTED assertion rather than a request in a review brief -
# `self_test_fences` drives each fence separately, compares the two stamp copies byte for byte, and
# asserts each program actually BEGINS with the fence text the self-test drove.
SCRATCH_FENCE_SH='case "$1" in
  /tmp/p6) : ;;
  /tmp/p6-*)
    case "${1#/tmp/p6-}" in
      ""|*[!A-Za-z0-9._-]*)
        echo "REFUSED: the scratch path is not a throwaway root under /tmp/p6" >&2; exit 3 ;;
    esac
    ;;
  *) echo "REFUSED: the scratch path is not a throwaway root under /tmp/p6" >&2; exit 3 ;;
esac'

STAMP_WRITE_FENCE_SH='case "$1" in
  /mnt/fast/safety/phase06/*)
    case "${1#/mnt/fast/safety/phase06/}" in
      ""|*[!A-Za-z0-9._-]*)
        echo "REFUSED: the stamp path is outside /mnt/fast/safety/phase06/" >&2; exit 3 ;;
    esac
    ;;
  *) echo "REFUSED: the stamp path is outside /mnt/fast/safety/phase06/" >&2; exit 3 ;;
esac'

STAMP_RM_FENCE_SH='case "$1" in
  /mnt/fast/safety/phase06/*)
    case "${1#/mnt/fast/safety/phase06/}" in
      ""|*[!A-Za-z0-9._-]*)
        echo "REFUSED: the stamp path is outside /mnt/fast/safety/phase06/" >&2; exit 3 ;;
    esac
    ;;
  *) echo "REFUSED: the stamp path is outside /mnt/fast/safety/phase06/" >&2; exit 3 ;;
esac'

# The two REFUSED wordings are deliberately DIFFERENT between the scratch path and the stamp path.
# A shared message would cost the reader the site: `rm -rf` inside the container and `rm -f` on
# LXC 100 are different blast radii, and the operator reading a refusal needs to know which fired.
#
# Each program is the fence text followed by its destructive command. The concatenation is what
# makes the self-test meaningful: the text driven by `self_test_fences` is byte-for-byte the text
# that runs on the far side, not a restatement of it.
CLEANUP_PROG="$SCRATCH_FENCE_SH"'
rm -rf "$1"
[ -e "$1" ] && echo present || echo gone'

STAMP_WRITE_PROG="$STAMP_WRITE_FENCE_SH"'
mkdir -p "$(dirname "$1")" && rm -f "$1" && touch "$1" && echo stamped'

STAMP_RM_PROG="$STAMP_RM_FENCE_SH"'
rm -f "$1"'

# The remote manifest. `%p %s %T@` catches path, size and mtime; the sha catches content;
# together they catch additions and deletions too. GNU find's -printf is why this runs on LXC 100
# and not on the macOS workstation.
#
# The -printf FORMAT IS BYTE-FOR-BYTE WHAT IT WAS before the WR-08 change. It has always carried a
# REAL tab and a REAL newline, not the two-character sequences `\t` and `\n` - `printf` resolves
# those escapes while it builds the string - so the tab and the newline are spelled out here as
# `$'\t'` / `$'\n'` rather than being smuggled through a format string. manifest_compare and
# normalise_transcript both key on that field layout, and the committed 174-destination artifact's
# comparability depends on it, so it must not drift.
MANIFEST_TAB=$'\t'
MANIFEST_NL=$'\n'
remote_manifest_meta() { # $1 = subtree
  local prog=""
  prog="LC_ALL=C find \"\$1\" -type f -printf \"%p${MANIFEST_TAB}%s${MANIFEST_TAB}%T@${MANIFEST_NL}\""
  printf 'set -o pipefail; timeout %s %s | LC_ALL=C sort' \
    "$REMOTE_TIMEOUT" "$(remote_sh_c "$prog" "$1")"
}
remote_manifest_sha() { # $1 = subtree
  printf 'set -o pipefail; timeout %s %s | LC_ALL=C sort -z | xargs -0 -r sha256sum' \
    "$REMOTE_TIMEOUT" "$(remote_sh_c 'LC_ALL=C find "$1" -type f -print0' "$1")"
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

# --- The D-18 ledger generator, run by the container's own interpreter --------------------------
# Written to a local file and fed to `docker exec -i ... python -` on stdin, so it is an auditable
# artefact rather than a string buried in a quoted remote command. It runs INSIDE the container
# because that is where beets 2.12.0, mediafile and mutagen live, and using any other copy would
# measure a different reader from the one the pipeline uses.
write_ledger_payload() { # $1 = local output path
  cat > "$1" <<'LEDGER_PY'
"""Emit the D-18 protected-field ledger as NDJSON, one record per (file, field).

Record shape follows scripts/normalise-dj-tags.py:1177-1212 so the two ledgers join cleanly:
path, field, rule, old, new, then `noop: true` when old == new, or `failed` when the file could
not be read. A REFUSAL IS A RECORD, NEVER A SKIP - an absence is exactly what a skip looks like.

Two mechanisms, deliberately different:

  bpm / initial_key / genres / comments ARE beets fields, so the library's item value is
  compared against the value read fresh off the file through mediafile. Note `genres` and not
  the singular: `Item._field_names` has no singular entry in beets 2.x, a query using the
  singular silently matches nothing, and MULTI_VALUE_DSV joins with a literal backslash + U+2400
  in the database.

  EnergyLevel is NOT a beets field and NOT a mediafile field. beets never reads it and never
  writes it, so A BEETS QUERY FOR IT RETURNS EMPTY AND READS AS CLEAN - indistinguishable from
  "gone". The only sound instrument is a RAW frame-set read, and it needs the right offset:
    * MP3  - the ID3 tag starts at file offset 0;
    * WAV  - it starts at the DATA OFFSET OF THE RIFF `id3 ` CHUNK. Without that offset the read
             sees `RIFF` at offset 0 for every WAV and returns silently: a vacuous pass. This is
             the exact defect scripts/normalise-dj-tags.py:866-883 documents;
    * FLAC - there is no ID3 tag; the convention key is a Vorbis comment. Vorbis keys are
             case-insensitive by spec and THIS CORPUS IS INCONSISTENT about it, so every key is
             folded to lower case before lookup.
  No WAV in this estate carries bpm, key or energy at all, so the WAV branch will have nothing to
  report on those three - and HAVING NOTHING TO REPORT IS DIFFERENT FROM NOT HAVING LOOKED, which
  is why the records are emitted either way.
"""
import json
import sys

from beets.library import Item, Library
import mediafile
import mutagen
import mutagen.id3

BEETS_FIELDS = ["bpm", "initial_key", "genres", "comments"]
RULE = "D-18 protected DJ field"

# ABSENT ON BOTH SIDES IS NOT A PROPOSED CHANGE, and telling the two apart needs beets' OWN nulls.
# MEASURED 2026-09-21 (plan 06-11, third live run) straight off the engine:
#     bpm  Integer          null 0
#     comments  String      null ''
#     genres  DelimitedString  null []
#     initial_key  MusicalKey  null None
# mediafile reports an absent tag as None; beets' typed model reports the same absence as that
# field's null. A naive `old != new` therefore called 327 of 870 records a PROPOSED CHANGE when
# every one of them was None -> the field's own null, i.e. nothing lost. Not one record in that
# set had a non-empty `old`. The read is taken from Item._fields at RUNTIME rather than
# hard-coded, so a beets that changes a null cannot leave a stale constant behind here.
# The raw `old` and `new` stay in the record either way - nothing is laundered, the record just
# stops claiming a change that is not one.
_MISSING = object()
NULLS = {f: getattr(Item._fields.get(f), "null", _MISSING) for f in BEETS_FIELDS}


def is_null_for(field, value):
    """True when `value` is 'this field carries nothing', on either side of the comparison."""
    if value is None:
        return True
    null = NULLS.get(field, _MISSING)
    if null is _MISSING:
        return False
    if isinstance(null, (list, tuple)):
        return isinstance(value, (list, tuple)) and len(value) == 0
    return value == null


def out(rec):
    # COMPACT separators on purpose: the judging half of this oracle matches `"noop":true` and
    # `"failed":` structurally rather than parsing values, so the spacing is load bearing.
    sys.stdout.write(json.dumps(rec, ensure_ascii=False, separators=(",", ":")) + "\n")


def norm(v):
    if v is None:
        return None
    if isinstance(v, (list, tuple)):
        return [str(x) for x in v]
    return str(v)


def wave_id3_offset(path):
    """Data offset of the WAV's RIFF `id3 ` chunk, or None. Raises if there are two: which one a
    reader honours is then undefined, and the frame-set read would be checking the wrong chunk."""
    import struct
    offsets = []
    with open(path, "rb") as fh:
        if fh.read(4) != b"RIFF":
            return None
        fh.read(8)
        while True:
            hdr = fh.read(8)
            if len(hdr) < 8:
                break
            cid, size = struct.unpack("<4sI", hdr)
            if cid in (b"id3 ", b"ID3 "):
                offsets.append(fh.tell())
            fh.seek(size + (size & 1), 1)
    if len(offsets) > 1:
        raise ValueError("%d ID3 chunks in one WAV; refusing to guess" % len(offsets))
    return offsets[0] if offsets else None


def raw_id3(path, low):
    """The ID3 frame set and a statement of WHERE it was read from. (tag_or_None, how)."""
    if low.endswith(".wav"):
        offset = wave_id3_offset(path)
        if offset is None:
            return None, "raw ID3 frame set: this WAV carries no id3 chunk"
        handler = mutagen.File(path)
        return (getattr(handler, "tags", None),
                "raw ID3 frame set inside the RIFF id3 chunk, data offset %d" % offset)
    try:
        return mutagen.id3.ID3(path), "raw ID3 frame set at file offset 0"
    except mutagen.id3.ID3NoHeaderError:
        return None, "raw ID3 frame set at file offset 0 (no ID3 tag)"


def energy_level(path):
    """The raw read. Returns (value_or_None, how_it_was_read)."""
    low = path.lower()
    if low.endswith(".flac"):
        handler = mutagen.File(path)
        folded = {}
        if handler is not None and handler.tags is not None:
            for key, value in handler.tags:
                folded.setdefault(key.lower(), []).append(value)
        got = folded.get("energylevel")
        return (got[0] if got else None,
                "raw Vorbis comment, keys folded to lower case - this corpus is inconsistent")
    tag, how = raw_id3(path, low)
    if tag is None:
        return None, how
    for frame in tag.getall("TXXX"):
        if frame.desc == "EnergyLevel":
            return (str(frame.text[0]) if frame.text else "", how)
    return None, how


def main():
    # `directory` IS LOAD BEARING AND IT IS NOT A DEFAULT WORTH TAKING.
    # MEASURED 2026-09-21 (plan 06-11, second live run): beets 2.12.0 stores an item path
    # RELATIVE TO THE LIBRARY DIRECTORY whenever it sits underneath it, and re-absolutises it
    # against `lib.directory` on read [beets/library/models.py@v2.12.0:130 "strip the library
    # prefix to match the stored relative path"; Library._migrations carries a
    # RelativePathMigration]. `Library(db)` alone falls back to platformdirs' user music path,
    # so the twelve S6 items - the ones drawn FROM the library, i.e. exactly the files Phase 7
    # will re-tag - came back as /home/beetle/Music/... and every one of their five fields was a
    # `failed` record. Items under /downloads are outside the directory, are stored absolute, and
    # read correctly either way, which is why only the in-library stratum was affected.
    # `set_music_dir` is left at its default so path conversion binds to the same directory.
    lib = Library(sys.argv[1], directory=sys.argv[2])
    for item in lib.items():
        path = item.path.decode("utf-8", "surrogateescape")
        try:
            mf = mediafile.MediaFile(path)
        except Exception as exc:
            why = "%s: %s" % (type(exc).__name__, str(exc)[:200])
            for field in BEETS_FIELDS + ["EnergyLevel"]:
                out({"path": path, "field": field, "rule": RULE,
                     "old": None, "new": None, "failed": why})
            continue
        for field in BEETS_FIELDS:
            try:
                old_raw = getattr(mf, field, None)
                new_raw = item.get(field, None)
                old = norm(old_raw)
                new = norm(new_raw)
            except Exception as exc:
                out({"path": path, "field": field, "rule": RULE, "old": None, "new": None,
                     "failed": "%s: %s" % (type(exc).__name__, str(exc)[:200])})
                continue
            rec = {"path": path, "field": field, "rule": RULE, "old": old, "new": new}
            if old == new:
                rec["noop"] = True
            elif is_null_for(field, old_raw) and is_null_for(field, new_raw):
                # Both sides carry nothing; only their spellings of "nothing" differ. Marked
                # noop AND flagged, so a reader can count this class rather than take it on
                # trust - and so that a non-empty `old` becoming null stays a RED, which is the
                # thing D-18 actually guards.
                rec["noop"] = True
                rec["null_equivalent"] = True
                rec["rule"] = (
                    RULE
                    + " (absent on both sides: mediafile reports an absent tag as None and beets'"
                    + " Item._fields['%s'].null is %r - no value is lost)" % (field, NULLS[field])
                )
            out(rec)
        try:
            value, how = energy_level(path)
        except Exception as exc:
            out({"path": path, "field": "EnergyLevel", "rule": RULE + " (raw frame set)",
                 "old": None, "new": None,
                 "failed": "%s: %s" % (type(exc).__name__, str(exc)[:200])})
        else:
            # beets cannot propose a change to a field it does not model, so new == old by
            # construction. The VALUE is what matters: it is recorded so a later phase can prove
            # it survived, which a beets query could never do.
            out({"path": path, "field": "EnergyLevel", "rule": RULE + " (" + how + ")",
                 "old": value, "new": value, "noop": True})


main()
LEDGER_PY
}

# ==============================================================================================
# --self-test : drive every fail-closed branch, without docker and without ssh
# ==============================================================================================
ST_FAIL=0
# The case total in the closing banner is COUNTED HERE, never typed into the banner. A typed
# total drifts the moment a case is added and then reads as authority; a derived one cannot.
ST_RUN=0
st_case() { # $1 = expectation  $2 = observed  $3 = description
  ST_RUN=$((ST_RUN + 1))
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
  # MOVING_N is a global set by read_unmoved. Reset it here so one case cannot leak control 5's
  # state into the next - the self-test's fixtures are stdout only and have no stderr companion.
  MOVING_N=-1
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
  local td="" rc=0
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

  # (7) THE REAL SHAPE, measured 2026-09-21: the narrow two-line form, SGR-coloured through both
  #     paths by colordiff, with the literal trailing space on the source half. Untreated this
  #     produces zero fixture matches AND a failed '/media/Music/' grep - a green-looking instrument
  #     measuring nothing. It must normalise to EXACTLY what the plain form produces.
  {
    printf '/src/\033[1;31ma\033[39;49;00m.mp3 \n'
    printf '  -> \033[1;32m%s/A/Al\033[39;49;00m/01 a.mp3\n' "$LIB_ROOT"
    printf '/src/\033[1;31mb\033[39;49;00m.mp3 \n'
    printf '  -> \033[1;32m%s/A/Al\033[39;49;00m/02 b.mp3\n' "$LIB_ROOT"
  } > "$td/st.ansi.txt"
  st_control ok "$td/st.ansi.txt" 2 "an SGR-coloured narrow transcript parses as two pairs."
  cp "$td/st.pairs" "$td/st.ansi.pairs"
  st_control ok "$td/st.narrow.txt" 2 "(re-parsed the plain narrow form for the comparison below)"
  rc=0
  cmp -s "$td/st.ansi.pairs" "$td/st.pairs" || rc=$?
  st_case 0 "$rc" "coloured and plain transcripts normalise to BYTE-IDENTICAL pairs - colour, and"
  info "the literal trailing space on the source half, change nothing about the verdict."
  rc=0; LC_ALL=C grep -q $'\033' "$td/st.ansi.pairs" && rc=1 || true
  st_case 0 "$rc" "no ESC byte survives into the pairs file, so the CONF-03 join can still match."

  say ""
  say "== --self-test: (N already in place) is read from the LOG LINE, not from stdout =="
  rule
  printf 'Moving 2 items.\n' > "$td/st.err.zero"
  rc=0; read_unmoved "$td/st.err.zero" || rc=$?
  st_case 0 "$rc" "'Moving 2 items.' parses."
  st_case 0 "$NORM_INPLACE" "no parenthetical means a POSITIVE zero - beets appends it only when N>0."
  st_case 1 "$NORM_INPLACE_SEEN" "and it is recorded as READ, not as absent."
  st_case 2 "$MOVING_N" "the object count is taken off the same line for control 5."
  printf 'Moving 164 items (3 already in place).\n' > "$td/st.err.some"
  rc=0; read_unmoved "$td/st.err.some" || rc=$?
  st_case 3 "$NORM_INPLACE" "the embedded '(3 already in place)' is extracted, not missed."
  printf '\033[1;33mMoving 2 items (4 already in place).\033[39;49;00m\n' > "$td/st.err.ansi"
  rc=0; read_unmoved "$td/st.err.ansi" || rc=$?
  st_case 4 "$NORM_INPLACE" "the log line is sanitised too - ui colours stderr as readily as stdout."
  rc=0; read_unmoved "$td/st.err.nosuchfile" || rc=$?
  st_case 2 "$rc" "a missing stderr file is COULD NOT LOOK, never N=0."
  [ "$rc" -ne 2 ] || info "reason: $(printf '%s' "$UNMOVED_WHY" | head -n 1)"
  printf 'Traceback (most recent call last):\n' > "$td/st.err.junk"
  rc=0; read_unmoved "$td/st.err.junk" || rc=$?
  st_case 2 "$rc" "stderr with no 'Moving N items' line at all is COULD NOT LOOK."
  # Control 5 itself: the log says one number, the transcript carries another.
  MOVING_N=-1
  normalise_transcript "$td/st.good.txt" "$OUT/st.pairs" "$OUT/st.dests" || true
  printf 'Moving 9 items.\n' > "$td/st.err.mismatch"
  read_unmoved "$td/st.err.mismatch" || true
  rc=0; positive_control "$td/st.good.txt" "$OUT/st.pairs" 2 || rc=$?
  st_case 3 "$rc" "'Moving 9 items' against 2 parsed pairs - a truncated transcript passes every"
  info "other control, which is why control 5 exists."
  MOVING_N=-1

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
  say "== --self-test: remote paths cross the quoting boundary as PARAMETERS (WR-08; T-06-93) =="
  rule
  # The fixture's directory name carries BOTH characters that break the old construction: an
  # APOSTROPHE, which terminates the single-quoted remote program it was interpolated into, and a
  # `$`, which the receiving shell expands. `Guns N' Roses - …` is an entirely ordinary shape for
  # this corpus, and under the old shape it produced a remote SYNTAX ERROR that reads as an
  # infrastructure fault.
  #
  # Entirely local: `remote_sh_c` emits a command STRING, and this runs it with bash here rather
  # than over ssh. The probe deliberately uses plain `find "$1" -type f` and NOT GNU `-printf`,
  # because this is a macOS workstation and the thing under test is the QUOTING, not find.
  local qdir="" qrc=0 qout="" qcmd=""
  rm -rf "$td/st.quote"
  qdir="$td/st.quote/Guns N' Roses - \$Greatest"
  mkdir -p "$qdir"
  : > "$qdir/01 It's \$o.mp3"
  : > "$qdir/02 plain.mp3"

  qcmd="$(remote_sh_c 'LC_ALL=C find "$1" -type f' "$qdir")"
  qrc=0
  qout="$(bash -c "$qcmd" 2>&1)" || qrc=$?
  st_case 0 "$qrc" "the apostrophe-and-\$ fixture reads CLEAN through the positional-parameter shape."
  rc=0
  printf '%s\n' "$qout" | LC_ALL=C grep -qF "01 It's \$o.mp3" || rc=1
  st_case 0 "$rc" "and the listing carries the file's REAL name - apostrophe and \$ both intact."

  # DRIVEN RED. The OLD construction - `printf '%q'` interpolated into the TEXT of a
  # single-quoted remote program - against the same fixture. A case that only proves the new
  # shape works does not prove the old one was broken, and "broken in a way nothing noticed" is
  # the whole of WR-08.
  qcmd="sh -c 'LC_ALL=C find $(printf '%q' "$qdir") -type f'"
  qrc=0
  qout="$(bash -c "$qcmd" 2>&1)" || qrc=$?
  rc=0
  [ "$qrc" -ne 0 ] || rc=1
  st_case 0 "$rc" "DRIVEN RED: the OLD interpolated shape FAILS on the same apostrophe fixture."
  info "old-shape exit $qrc: $(printf '%s' "$qout" | head -n 1)"

  # And the two manifest builders must actually go through the helper: the path has to leave the
  # program text entirely and arrive as `sh -c '<prog>' sh <path>`.
  for qcmd in "$(remote_manifest_meta "$qdir")" "$(remote_manifest_sha "$qdir")"; do
    rc=0
    printf '%s' "$qcmd" | LC_ALL=C grep -qF " sh $(printf '%q' "$qdir")" || rc=1
    st_case 0 "$rc" "a manifest builder passes the path as sh -c's POSITIONAL PARAMETER."
    rc=0
    if printf '%s' "$qcmd" | LC_ALL=C grep -qF "find $(printf '%q' "$qdir")"; then rc=1; fi
    st_case 0 "$rc" "and never interpolates it after 'find' - the old shape is gone, not hidden."
  done
  rm -rf "$td/st.quote"

  say ""
  say "== --self-test: the blind preflight, layer 1 and the host->container mapper =="
  rule
  local got=""
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

# --- The class assertions' red branches --------------------------------------------------------
# Ten reds and then one clean list. A control that can only pass is uninformative, and every one
# of the bugs this wave hit was a predicate that could never have matched in the first place -
# so each of these fixtures is built to MAKE the predicate fire, and the clean case afterwards
# proves the same predicate can also stay quiet.
st_assert() { # $1 = expected rc  $2 = description  $3.. = assertion and its arguments
  local want="$1" desc="$2" rc=0
  shift 2
  "$@" || rc=$?
  st_case "$want" "$rc" "$desc"
}

st_write_clean() { # $1 = directory to build the clean fixture in
  local d="$1"
  {
    printf '%s/Benson Boone/American Heart [Night Street Records]/01 Sorry.mp3\n' "$LIB_ROOT"
    printf '%s/DJ/Mastermix/Issue 420/01 Club Cuts.mp3\n' "$LIB_ROOT"
    printf '%s/DJ/Mastermix/Issue 420/02 Party On Fire.mp3\n' "$LIB_ROOT"
    printf '%s/Singles/Cyril/Stumblin In.mp3\n' "$LIB_ROOT"
    printf "%s/Various Artists/NOW 121/01 Manchild.mp3\n" "$LIB_ROOT"
  } | LC_ALL=C sort > "$d/dest.txt"
  # The fixture stands in for the committed tree in these cases, and it is written by hand so the
  # assertions are compared against a KNOWN set rather than against the real 174-line file - a
  # self-test that needs the production fixture to be correct is testing two things at once.
  {
    printf '# a synthetic stand-in for 06-EXPECTED-TREE.txt; the ^# strip must apply here too\n'
    cat "$d/dest.txt"
  } > "$d/expected.txt"
  {
    printf '/src/a.mp3\t%s/Benson Boone/American Heart [Night Street Records]/01 Sorry.mp3\n' "$LIB_ROOT"
    printf '/src/dj/1.mp3\t%s/DJ/Mastermix/Issue 420/01 Club Cuts.mp3\n' "$LIB_ROOT"
    printf '/src/dj/2.mp3\t%s/DJ/Mastermix/Issue 420/02 Party On Fire.mp3\n' "$LIB_ROOT"
    printf '/src/s/1.mp3\t%s/Singles/Cyril/Stumblin In.mp3\n' "$LIB_ROOT"
    printf '/src/va/1.mp3\t%s/Various Artists/NOW 121/01 Manchild.mp3\n' "$LIB_ROOT"
  } > "$d/pairs.tsv"
  {
    printf '/src/a.mp3\tBenson Boone\tAmerican Heart\t\tBenson Boone\t\n'
    printf '/src/dj/1.mp3\tMastermix\tIssue 420\tdj\tMastermix\t\n'
    printf '/src/dj/2.mp3\tMastermix\tIssue 420\tdj\tMastermix\t\n'
    printf '/src/s/1.mp3\t\tStumblin In\t\tCyril\t\n'
    printf '/src/va/1.mp3\tVarious Artists\tNOW 121\t\tSabrina Carpenter\tSabrina Carpenter; Dua Lipa\n'
  } > "$d/fields.tsv"
}

self_test_classes() {
  local d="$OUT/st-classes" rc=0
  rm -rf "$d"; mkdir -p "$d"
  st_write_clean "$d"

  say ""
  say "== --self-test: the class assertions, red branch first (D-27) =="
  rule

  # (1) CONF-03 - a capitalisation-only top level. NOT case-folded on purpose: this is what
  #     renders a duplicate artist page in Jellyfin.
  sed 's|/Benson Boone/|/benson boone/|' "$d/pairs.tsv" > "$d/pairs.case.tsv"
  st_assert 1 "CONF-03: a capitalisation-only top-level mismatch is a RED, never a tolerance." \
    assert_top_level "$d/pairs.case.tsv" "$d/fields.tsv"
  # ... and the blind case: a destination with no library row behind it.
  printf '/src/orphan.mp3\t%s/Nobody/Album/01 x.mp3\n' "$LIB_ROOT" >> "$d/pairs.case.tsv"
  st_assert 2 "CONF-03: a destination with no library field row is COULD NOT LOOK, not a pass." \
    assert_top_level "$d/pairs.case.tsv" "$d/fields.tsv"

  # (2) D-15 - a Compilations/ path, which is what returns the moment the comp: override is lost.
  sed 's|/Various Artists/|/Compilations/Various Artists/|' "$d/dest.txt" > "$d/dest.comp.txt"
  st_assert 1 "D-15: a Compilations/ component is a RED." \
    assert_no_compilations "$d/dest.comp.txt"
  # ... and the vacuous case: no Compilations/, but no Various Artists either, so nothing was tested.
  LC_ALL=C grep -v '/Various Artists/' "$d/dest.txt" > "$d/dest.nova.txt"
  st_assert 1 "D-15: zero Compilations/ with zero Various Artists is VACUOUS, so it is a RED." \
    assert_no_compilations "$d/dest.nova.txt"

  # (3) D-13 - the DJ count one short. The clean fixture has two DJ rows.
  st_assert 1 "D-13: a DJ count of 2 against an expected 3 is a RED - it is an equality." \
    assert_dj_count "$d/dest.txt" 3
  st_assert 0 "D-13: the same list against its true count of 2 is clean." \
    assert_dj_count "$d/dest.txt" 2

  # (4) D-16 - an unpredicted %aunique{} firing.
  sed 's|American Heart \[Night Street Records\]|American Heart|' "$d/expected.txt" > "$d/expected.noau.txt"
  st_assert 1 "D-16: a firing present in the run but absent from the fixture is a RED." \
    assert_aunique "$d/dest.txt" "$d/expected.noau.txt"
  # (5) D-16's hard guard - a bracketed bare integer is the NUMERIC DATABASE ID fallback.
  sed 's|American Heart \[Night Street Records\]|American Heart [1234567]|' "$d/dest.txt" > "$d/dest.id.txt"
  sed 's|American Heart \[Night Street Records\]|American Heart [1234567]|' "$d/expected.txt" > "$d/expected.id.txt"
  st_assert 1 "D-16 guard: a bracketed non-year integer is the numeric database id - a RED even
    when it matches the fixture, because such a fixture is a landmine." \
    assert_aunique "$d/dest.id.txt" "$d/expected.id.txt"
  # ... and a four-digit year must NOT trip the guard, or the guard is unusable.
  sed 's|American Heart \[Night Street Records\]|American Heart [2025]|' "$d/dest.txt" > "$d/dest.yr.txt"
  sed 's|American Heart \[Night Street Records\]|American Heart [2025]|' "$d/expected.txt" > "$d/expected.yr.txt"
  st_assert 0 "D-16 guard: a bracketed four-digit year is a legitimate disambiguator, not an id." \
    assert_aunique "$d/dest.yr.txt" "$d/expected.yr.txt"

  # (6) D-19b - an unexpected Singles/ resolution: usually an album beets failed to group.
  printf '%s/Singles/Cyril/Another One.mp3\n' "$LIB_ROOT" >> "$d/dest.txt"
  LC_ALL=C sort -o "$d/dest.txt" "$d/dest.txt"
  st_assert 1 "D-19b: a singleton the fixture does not predict is a RED." \
    assert_singletons "$d/dest.txt" "$d/expected.txt" "$d/pairs.tsv"
  LC_ALL=C grep -v 'Another One' "$d/dest.txt" > "$d/dest.clean.txt"
  mv "$d/dest.clean.txt" "$d/dest.txt"

  # (7) D-19a - an album directory equal to its artist directory. BLOCKING.
  printf '%s/Def Leppard/Def Leppard/01 x.flac\n' "$LIB_ROOT" > "$d/dest.eq.txt"
  st_assert 1 "D-19a: album dir == artist dir is BLOCKING - no beets query can express it." \
    assert_album_ne_artist "$d/dest.eq.txt"
  # ... and the live defect's shape is REPORTED, not failed.
  printf '%s/Def Leppard/Def Leppard (2015)/01 x.flac\n' "$LIB_ROOT" > "$d/dest.pref.txt"
  st_assert 0 "D-19a: the '<artist> (' prefix shape is reported and NOT failed." \
    assert_album_ne_artist "$d/dest.pref.txt"

  # (8) the -1 - shape.
  printf '%s/A/Al/-1 - Title.mp3\n' "$LIB_ROOT" > "$d/dest.m1.txt"
  st_assert 1 "the '-1 - ' filename shape is a RED." assert_no_minus_one "$d/dest.m1.txt"
  st_assert 0 "a clean list has no '-1 - ' filename." assert_no_minus_one "$d/dest.txt"

  # (9) the .N collision suffix.
  printf '%s/A/Al/01 Title.1.mp3\n' "$LIB_ROOT" > "$d/dest.sfx.txt"
  st_assert 1 "a .N collision suffix is a RED." assert_no_collision_suffix "$d/dest.sfx.txt"
  st_assert 0 "a clean list carries no .N suffix." assert_no_collision_suffix "$d/dest.txt"

  # (10) D-18 - a proposed change to a protected field, a refusal, and a short ledger.
  {
    printf '{"path":"/src/a.mp3","field":"bpm","rule":"D-18","old":128,"new":128,"noop":true}\n'
    printf '{"path":"/src/a.mp3","field":"initial_key","rule":"D-18","old":null,"new":null,"noop":true}\n'
    printf '{"path":"/src/a.mp3","field":"genres","rule":"D-18","old":["House"],"new":["Pop"]}\n'
    printf '{"path":"/src/a.mp3","field":"comments","rule":"D-18","old":"","new":"","noop":true}\n'
    printf '{"path":"/src/a.mp3","field":"EnergyLevel","rule":"D-18","old":"7","new":"7","noop":true}\n'
  } > "$d/ledger.changed.ndjson"
  st_assert 1 "D-18: a record proposing a different value for a protected field is a RED." \
    assert_protected_fields "$d/ledger.changed.ndjson" 1
  sed 's|"old":\["House"\],"new":\["Pop"\]|"old":["House"],"new":["House"],"noop":true|' \
    "$d/ledger.changed.ndjson" > "$d/ledger.clean.ndjson"
  st_assert 0 "D-18: five noop records for one file is the clean case." \
    assert_protected_fields "$d/ledger.clean.ndjson" 1
  LC_ALL=C grep -v '"field":"EnergyLevel"' "$d/ledger.clean.ndjson" > "$d/ledger.short.ndjson"
  st_assert 2 "D-18: four records where five are due is COULD NOT LOOK - an absence is exactly
    what a skip looks like." \
    assert_protected_fields "$d/ledger.short.ndjson" 1
  sed 's|"noop":true|"failed":"OSError: nope"|' "$d/ledger.clean.ndjson" > "$d/ledger.failed.ndjson"
  st_assert 2 "D-18: a refusal is a RECORD and it is COULD NOT LOOK, never an 'unchanged'." \
    assert_protected_fields "$d/ledger.failed.ndjson" 1

  # (10b) The null-equivalent class, added by plan 06-11 after the third live run. `old` and `new`
  #       DIFFER textually on all four of these - None against beets' own typed null - and the
  #       generator marks them noop. The judge must accept them, and it must STILL go red on a
  #       real strip, which is the pair of cases below.
  {
    printf '{"path":"/src/a.mp3","field":"bpm","rule":"D-18 (absent both sides)","old":null,"new":"0","noop":true,"null_equivalent":true}\n'
    printf '{"path":"/src/a.mp3","field":"initial_key","rule":"D-18","old":null,"new":null,"noop":true}\n'
    printf '{"path":"/src/a.mp3","field":"genres","rule":"D-18 (absent both sides)","old":null,"new":[],"noop":true,"null_equivalent":true}\n'
    printf '{"path":"/src/a.mp3","field":"comments","rule":"D-18 (absent both sides)","old":null,"new":"","noop":true,"null_equivalent":true}\n'
    printf '{"path":"/src/a.mp3","field":"EnergyLevel","rule":"D-18","old":null,"new":null,"noop":true}\n'
  } > "$d/ledger.nulleq.ndjson"
  st_assert 0 "D-18: absent-on-both-sides records are noops, not 327 phantom proposed changes." \
    assert_protected_fields "$d/ledger.nulleq.ndjson" 1
  rc="$(LC_ALL=C grep -c '^NULL-EQUIVALENT' "$OUT/assert.protected.txt" || true)"
  st_case 3 "$rc" "and they are LISTED as NULL-EQUIVALENT rather than vanishing into the total."
  # The one that must still fire: a real value on the old side, beets' null on the new side. That
  # is a STRIP, it is what D-18 exists to catch, and no null-equivalence may excuse it.
  {
    printf '{"path":"/src/a.mp3","field":"bpm","rule":"D-18","old":"128","new":"0"}\n'
    printf '{"path":"/src/a.mp3","field":"initial_key","rule":"D-18","old":null,"new":null,"noop":true}\n'
    printf '{"path":"/src/a.mp3","field":"genres","rule":"D-18","old":null,"new":[],"noop":true,"null_equivalent":true}\n'
    printf '{"path":"/src/a.mp3","field":"comments","rule":"D-18","old":null,"new":"","noop":true,"null_equivalent":true}\n'
    printf '{"path":"/src/a.mp3","field":"EnergyLevel","rule":"D-18","old":"7","new":"7","noop":true}\n'
  } > "$d/ledger.strip.ndjson"
  st_assert 1 "D-18: a real BPM becoming beets' null is a STRIP and stays a RED." \
    assert_protected_fields "$d/ledger.strip.ndjson" 1

  say ""
  say "== --self-test: the clean list must produce ZERO reds across every assertion =="
  rule
  st_assert 0 "CONF-03 clean" assert_top_level "$d/pairs.tsv" "$d/fields.tsv"
  st_assert 0 "D-15 clean" assert_no_compilations "$d/dest.txt"
  st_assert 0 "D-13 clean" assert_dj_count "$d/dest.txt" 2
  st_assert 0 "D-16 clean" assert_aunique "$d/dest.txt" "$d/expected.txt"
  st_assert 0 "D-19b clean" assert_singletons "$d/dest.txt" "$d/expected.txt" "$d/pairs.tsv"
  st_assert 0 "D-19a clean" assert_album_ne_artist "$d/dest.txt"
  st_assert 0 "-1 -  clean" assert_no_minus_one "$d/dest.txt"
  st_assert 0 ".N clean" assert_no_collision_suffix "$d/dest.txt"
  st_assert 0 "D-18 clean" assert_protected_fields "$d/ledger.clean.ndjson" 1
  rc=0; report_multi_artist "$d/fields.tsv" || rc=$?
  st_case 0 "$rc" "CONF-04 write side is a REPORT: it returns 0 whenever it COULD LOOK. (WR-06:
    it no longer returns 0 when it could not - that pair is driven in the vacuity section.)"
  rc="$(LC_ALL=C grep -c '^WRITE-SIDE' "$OUT/report.multiartist.txt" || true)"
  st_case 1 "$rc" "the one multi-artist row in the fixture is shown, not silently dropped."

  # The payload the container runs is emitted here too, so a syntax error in it is caught by
  # --self-test rather than at minute forty of a live run.
  write_ledger_payload "$d/ledger.py"
  rc=0
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$d/ledger.py" || rc=1
    st_case 0 "$rc" "the D-18 ledger payload parses as Python."
    # Structural, not textual: walk the AST and require that the Library() call passes a
    # `directory=` keyword. Defaulting it silently re-absolutises every in-library item against
    # ~/Music, which turned all twelve S6 files into `failed` records on the second live run.
    rc=0
    python3 - "$d/ledger.py" <<'ST_AST' || rc=1
import ast, sys
tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
calls = [n for n in ast.walk(tree)
         if isinstance(n, ast.Call) and getattr(n.func, "id", None) == "Library"]
assert calls, "the payload never constructs a Library at all"
for c in calls:
    kw = {k.arg for k in c.keywords}
    assert "directory" in kw, "Library() called without directory=; in-library items would resolve against ~/Music"
ST_AST
    st_case 0 "$rc" "the ledger's Library() is opened with an explicit directory= - the in-library"
    info "stratum resolves against /media/Music and not against platformdirs' user music path."
  else
    warn "SKIPPED: no python3 on this workstation, so the ledger payload could not be parsed."
    info "Reported rather than silently counted as a pass. The payload runs in the container."
  fi
}

# --- The vacuity and could-not-look guards this file grew in plan 06-19 -------------------------
# EVERY case below is a PAIR. A guard that refuses everything is exactly as useless as one that
# refuses nothing, and three of the four findings this section drives were guards that could never
# fire - so proving a refusal fires is only half of it; the other half is proving the same
# predicate still lets a correct input through.
#
# Nothing here reaches ssh or docker. `st_grep_why` writes the message to a FILE and greps the
# file rather than piping it: `printf ... | grep -q` under `set -o pipefail` propagates SIGPIPE's
# 141 when grep exits on its first match, which fires the failure branch precisely when the text
# IS correct. That shape has produced a false red in three plans of this phase already.
st_grep_why() { # $1 = expected 0/1  $2 = text  $3 = fixed string wanted  $4 = description
  local hit=0
  printf '%s\n' "$2" > "$OUT/st.why.txt"
  LC_ALL=C grep -qF -- "$3" "$OUT/st.why.txt" || hit=1
  st_case "$1" "$hit" "$4"
}

self_test_vacuity() {
  local d="$OUT/st-vacuity" rc=0 out="" probe="" pdir=""
  rm -rf "$d"; mkdir -p "$d"

  say ""
  say "== --self-test: WR-02 an EMPTY manifest cannot compare equal to another empty one =="
  rule
  : > "$d/m.empty.a"
  : > "$d/m.empty.b"
  printf 'a/one.mp3\t1\t1.0\n' > "$d/m.full.a"
  cp "$d/m.full.a" "$d/m.full.b"
  # THE DEFECT ITSELF: before this plan, two empty listings diffed clean and layer 2 of the
  # three-layer wrote-nothing proof was satisfied by having measured nothing.
  st_mc couldnotcompare "$d/m.empty.a" "$d/m.empty.b" \
    "TWO EMPTY manifests are COULD NOT COMPARE, not 'identical before and after'."
  st_grep_why 0 "$DIFF_WHY" "pass vacuously" \
    "and the reason is the sibling's own words, carried over rather than paraphrased."
  st_mc couldnotcompare "$d/m.empty.a" "$d/m.full.b" \
    "an empty BEFORE against a populated AFTER is also COULD NOT COMPARE."
  st_mc couldnotcompare "$d/m.full.a" "$d/m.empty.b" \
    "and so is a populated BEFORE against an empty AFTER - the guard runs over both inputs."
  # THE POSITIVE PAIR. A guard that refuses every manifest would make the instrument useless and
  # invite its removal, which is how a fail-closed check gets deleted rather than fixed.
  st_mc identical "$d/m.full.a" "$d/m.full.b" \
    "two NON-EMPTY identical manifests are still identical - the guard discriminates."
  printf 'a/one.mp3\t1\t9.9\n' > "$d/m.full.b"
  st_mc differs "$d/m.full.a" "$d/m.full.b" \
    "and a real difference is still a RED - the guard did not swallow layer 2's red arm."

  say ""
  say "== --self-test: WR-06 the write-side report cannot tick over a blind read =="
  rule
  cp "$OUT/st-classes/fields.tsv" "$d/fields.good.tsv"
  : > "$d/fields.empty.tsv"
  rc=0; report_multi_artist "$d/nosuchfile.tsv" || rc=$?
  st_case 2 "$rc" "an UNREADABLE fields TSV returns the code run_assert routes to unknown()."
  rc=0; report_multi_artist "$d/fields.empty.tsv" || rc=$?
  st_case 2 "$rc" "an EMPTY-but-readable fields TSV is the same could-not-look, not zero rows."
  rc=0; report_multi_artist "$d/fields.good.tsv" || rc=$?
  st_case 0 "$rc" "a real field view still returns 0 - it is a REPORT and must not block a run."
  st_grep_why 0 "$ASSERT_WHY" "field-view row(s) READ" \
    "and its message states the denominator, so a zero there is empty-BY-MEASUREMENT."
  # The routing itself, through the same wrapper the live run uses. run_assert PRINTS, so it is
  # driven in a subshell and its output inspected: the point of WR-06 was never the return code,
  # it was the tick that reached the operator's terminal.
  run_assert "CONF-04 write side" report_multi_artist "$d/nosuchfile.tsv" > "$d/ra.blind.txt" 2>&1
  rc=0; LC_ALL=C grep -q 'UNKNOWN, not green' "$d/ra.blind.txt" || rc=1
  st_case 0 "$rc" "run_assert routes the blind read to UNKNOWN, not green."
  rc=0; LC_ALL=C grep -q $'\342\234\223' "$d/ra.blind.txt" && rc=1 || true
  st_case 0 "$rc" "and NO GREEN TICK is printed for that label - the whole of WR-06."
  run_assert "CONF-04 write side" report_multi_artist "$d/fields.good.tsv" > "$d/ra.good.txt" 2>&1
  rc=0; LC_ALL=C grep -q $'\342\234\223' "$d/ra.good.txt" || rc=1
  st_case 0 "$rc" "THE PAIR: over a real field view the same label DOES tick, so the routing"
  info "discriminates rather than having been turned off."
  UNKNOWNS=0

  say ""
  say "== --self-test: IN-12 an empty field view is not 'six columns each' =="
  rule
  rc=0; assert_field_view "$d/fields.empty.tsv" || rc=$?
  st_case 2 "$rc" "an EMPTY fields.tsv is COULD NOT LOOK - zero items is not a column count."
  st_grep_why 0 "$ASSERT_WHY" "NOT PRODUCED" \
    "and the message says the view was not produced, not that every item had six columns."
  rc=0; assert_field_view "$d/nosuchfile.tsv" || rc=$?
  st_case 2 "$rc" "a missing fields.tsv is COULD NOT LOOK too."
  printf 'a\tb\tc\td\te\n' > "$d/fields.five.tsv"
  rc=0; assert_field_view "$d/fields.five.tsv" || rc=$?
  st_case 2 "$rc" "a five-column row is still COULD NOT LOOK - the old guard was not lost."
  rc=0; assert_field_view "$d/fields.good.tsv" || rc=$?
  st_case 0 "$rc" "THE PAIR: a well-formed six-column view still passes."

  say ""
  say "== --self-test: IN-09 a DJ stratum that was never exercised is VACUOUS =="
  rule
  rc=0; assert_dj_count "$OUT/st-classes/dest.txt" 0 || rc=$?
  st_case 1 "$rc" "a wanted count of ZERO is refused - 0 against 0 tests nothing."
  st_grep_why 0 "$ASSERT_WHY" "VACUOUS" \
    "in its neighbour's own vocabulary, so the two read the same on the same question."
  st_grep_why 0 "$ASSERT_WHY" "DEF-06-12-01" \
    "and it names the deferral it converts from a silence into a refusal."
  rc=0; assert_dj_count "$OUT/st-classes/dest.txt" 2 || rc=$?
  st_case 0 "$rc" "THE PAIR: the true count of 2 still passes - the guard is not a blanket no."
  rc=0; assert_dj_count "$OUT/st-classes/dest.txt" 3 || rc=$?
  st_case 1 "$rc" "and a WRONG non-zero count is still the equality's RED, unchanged."

  say ""
  say "== --self-test: WR-01 the scratch probe, and the old pipeline it replaces =="
  rule
  # The remote program text is driven HERE, with local /bin/sh, exactly as the WR-08 case above
  # drives remote_sh_c's output with local bash. What is NOT driven is the container: its dash,
  # docker exec's status propagation, and a directory unreadable by `beetle` specifically. Those
  # are recorded as NOT DRIVEN in artifacts/06-19-oracle-vacuity-driven.txt.
  pdir="$d/probe"
  mkdir -p "$pdir/emptydir" "$pdir/full" "$pdir/noread"
  : > "$pdir/full/lib.db"
  : > "$pdir/afile"
  : > "$pdir/noread/x"
  for probe in "nosuch:absent" "emptydir:empty" "afile:notadir"; do
    rc=0
    out="$(/bin/sh -c "$SCRATCH_PROBE_PROG" sh "$pdir/${probe%%:*}" 2>/dev/null)" || rc=$?
    st_case "${probe#*:}" "$out" "the probe answers '${probe#*:}' for $pdir/${probe%%:*}."
  done
  rc=0
  out="$(/bin/sh -c "$SCRATCH_PROBE_PROG" sh "$pdir/full" 2>/dev/null)" || rc=$?
  case "$out" in 'nonempty '*) rc=0 ;; *) rc=1 ;; esac
  st_case 0 "$rc" "a POPULATED scratch answers 'nonempty <entry>', which the case arm refuses on."
  if [ "$(id -u)" = "0" ]; then
    warn "SKIPPED as root: the PRESENT-BUT-UNREADABLE case. root bypasses the read bit, so it"
    info "cannot be constructed here - reported, never silently counted as a pass."
  else
    chmod 000 "$pdir/noread"
    rc=0
    out="$(/bin/sh -c "$SCRATCH_PROBE_PROG" sh "$pdir/noread" 2>/dev/null)" || rc=$?
    st_case 4 "$rc" "a PRESENT-BUT-UNREADABLE scratch exits 4 - find's status is read, not lost."
    st_case "" "$out" "and prints nothing, so no word can be mistaken for 'absent' or 'empty'."
    # DRIVEN RED: the OLD shape, same fixture. It returns 0 and an empty stdout - BYTE-IDENTICAL
    # to what it returns for a genuinely empty directory, which is why the precheck ticked green
    # over a could-not-look. A case that only proves the new shape works does not prove the old
    # one was broken, and "broken in a way nothing noticed" is the whole of WR-01.
    rc=0
    out="$(/bin/sh -c '[ ! -e "$1" ] && echo absent || ls -A "$1" | head -n 1' sh "$pdir/noread" 2>/dev/null)" || rc=$?
    st_case 0 "$rc" "DRIVEN RED: the OLD pipeline exits 0 on the SAME unreadable directory."
    st_case "" "$out" "DRIVEN RED: and prints nothing - indistinguishable from an empty scratch."
    chmod 755 "$pdir/noread"
  fi
  rc=0
  out="$(/bin/sh -c '[ ! -e "$1" ] && echo absent || ls -A "$1" | head -n 1' sh "$pdir/emptydir" 2>/dev/null)" || rc=$?
  st_case "" "$out" "THE PAIR for the driven red: the old shape prints the SAME empty answer for a"
  info "genuinely empty directory, so the two states were not distinguishable at all."
  rm -rf "$pdir"
}

# --- GC-02: the receiving-side fences, driven at the inner layer ALONE --------------------------
# WHY THESE CASES CANNOT DELETE ANYTHING, stated in band because the claim has to be checkable by
# the next reader without running it. Every behavioural case below executes a FENCE TEXT -
# SCRATCH_FENCE_SH / STAMP_WRITE_FENCE_SH / STAMP_RM_FENCE_SH - and never CLEANUP_PROG,
# STAMP_WRITE_PROG or STAMP_RM_PROG. A fence text is a bare `case` that either falls through or
# prints and exits 3; it contains NO `rm`, NO `touch` and NO redirection into a path, and three
# cases below assert exactly that by inspecting the strings. Driving the full programs instead -
# even on paths the fence should refuse - would mean that a REGRESSION in the fence turns this
# self-test into `rm -rf /tmp/p6-x/../../../home`. A self-test case that can destroy a real path
# under a mistake is a worse defect than the traversal hole it is checking for, so the destructive
# half is never executed here at all.
#
# What carries the result from the fence text to the shipped program is STRUCTURAL, not behavioural:
# three cases assert that each PROG literally BEGINS with the fence text that was driven. The
# programs are built by concatenation at their definition, so that prefix relation is the whole
# link, and it breaks loudly if someone hand-edits a fence back into a program body.
#
# THE OUTER FENCE IS ABSENT FROM ALL OF THIS, which is the point. :327 refused every one of these
# paths long before the first ssh; the inner layer's entire documented purpose is to hold when a
# future edit removes that. These cases are the first thing in this file that tests the inner layer
# on its own terms.
ST_FENCE_ERR=""
st_fence() { # $1 = expected exit  $2 = fence text  $3 = the path to drive  $4 = description
  local frc=0
  ST_FENCE_ERR=""
  /bin/sh -c "$2" sh "$3" > "$OUT/st.fence.out" 2> "$OUT/st.fence.err" || frc=$?
  ST_FENCE_ERR="$(cat "$OUT/st.fence.err")"
  st_case "$1" "$frc" "$4"
}

# WHERE THE DRIVEN RED FOR THIS SECTION LIVES, AND WHY IT IS NOT IN THIS FILE. Every other guard in
# this self-test carries its driven red inline, holding the OLD shape as a literal beside the new
# one. That is deliberately NOT done here. The old shape was the bare glob
# `/tmp/p6|/tmp/p6-*` (and its stamp twin), and embedding either literal would leave a grep for the
# weak fence still returning a hit in this file - which is precisely the signal a future reviewer
# will use to check that GC-02 stayed closed. A permanently-hit grep is a broken detector.
# So the regression is driven against a MUTANT COPY of this whole script instead, built in a scratch
# directory with the three fences reverted, and both transcripts are recorded in
# .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-24-oracle-fence-parity.txt.
# That form is also the stronger one: it shows these very cases going RED against a bare-glob build,
# rather than showing a detached string behaving badly.
self_test_fences() {
  local rc=0

  say ""
  say "== --self-test: GC-02 the RECEIVING-side fences refuse traversal, with the outer one gone =="
  rule
  st_fence 3 "$SCRATCH_FENCE_SH" '/tmp/p6-x/../etc' \
    "the inner scratch fence REFUSES /tmp/p6-x/../etc - a glob admits '/', the class does not."
  st_fence 3 "$SCRATCH_FENCE_SH" '/tmp/p6-x/../../../home' \
    "and refuses /tmp/p6-x/../../../home, which the bare glob would have handed to rm -rf."
  st_fence 3 "$SCRATCH_FENCE_SH" '/tmp/p6-x /config' \
    "and refuses the WR-07 word-splitting shape /tmp/p6-x /config at the inner layer too."
  st_fence 3 "$SCRATCH_FENCE_SH" '/tmp/p6-' \
    "an EMPTY suffix after /tmp/p6- is refused - '' is the first arm of the nested case."
  st_fence 3 "$SCRATCH_FENCE_SH" '/etc' \
    "and a path sharing no prefix at all is still refused by the outer arm."
  st_fence 3 "$STAMP_WRITE_FENCE_SH" '/mnt/fast/safety/phase06/../../../../etc/shadow' \
    "the stamp WRITE fence refuses /mnt/fast/safety/phase06/../../../../etc/shadow."
  st_fence 3 "$STAMP_RM_FENCE_SH" '/mnt/fast/safety/phase06/../../../../etc/shadow' \
    "and so does the stamp RM fence - the copy adjacent to 'rm -f', driven separately."
  st_fence 3 "$STAMP_WRITE_FENCE_SH" '/mnt/fast/safety/phase06/' \
    "a bare prefix with no basename is refused: it would make dirname/rm -f act on the directory."

  # THE PASSING PARTNERS. Without these the cases above prove only that the fence refuses
  # everything, which is exactly as useless as one that refuses nothing - the rule this file's
  # vacuity section already states for every other guard.
  st_fence 0 "$SCRATCH_FENCE_SH" '/tmp/p6' \
    "THE PAIR: the literal /tmp/p6 is still ACCEPTED - the fence discriminates."
  st_fence 0 "$SCRATCH_FENCE_SH" '/tmp/p6-scratch01' \
    "THE PAIR: /tmp/p6-scratch01 is still accepted - a real suffix inside the class."
  st_fence 0 "$STAMP_WRITE_FENCE_SH" '/mnt/fast/safety/phase06/oracle.stamp' \
    "THE PAIR: the real stamp path is still accepted by the write fence."
  st_fence 0 "$STAMP_RM_FENCE_SH" '/mnt/fast/safety/phase06/oracle.stamp' \
    "THE PAIR: and by the rm fence - both copies accept the path the run actually uses."

  # The refusal has to be LEGIBLE, and it has to name WHICH path was refused. `rm -rf` inside the
  # container and `rm -f` on LXC 100 are different blast radii.
  st_fence 3 "$SCRATCH_FENCE_SH" '/tmp/p6-x/../etc' "(re-driven to read the scratch refusal text)"
  st_grep_why 0 "$ST_FENCE_ERR" "the scratch path is not a throwaway root under /tmp/p6" \
    "the scratch refusal names the SCRATCH path, so the operator knows which fence fired."
  st_fence 3 "$STAMP_RM_FENCE_SH" '/mnt/fast/safety/phase06/../../../../etc/shadow' \
    "(re-driven to read the stamp refusal text)"
  st_grep_why 0 "$ST_FENCE_ERR" "the stamp path is outside /mnt/fast/safety/phase06/" \
    "and the stamp refusal names the STAMP path - the two wordings are deliberately distinct."

  say ""
  say "== --self-test: GC-02 the driven fence text IS the shipped program's first statement =="
  rule
  rc=1; case "$CLEANUP_PROG"     in "$SCRATCH_FENCE_SH"*)     rc=0 ;; esac
  st_case 0 "$rc" "CLEANUP_PROG BEGINS with the scratch fence text the cases above drove."
  rc=1; case "$STAMP_WRITE_PROG" in "$STAMP_WRITE_FENCE_SH"*) rc=0 ;; esac
  st_case 0 "$rc" "STAMP_WRITE_PROG begins with the stamp write fence text."
  rc=1; case "$STAMP_RM_PROG"    in "$STAMP_RM_FENCE_SH"*)    rc=0 ;; esac
  st_case 0 "$rc" "STAMP_RM_PROG begins with the stamp rm fence text."
  # The safety claim in the comment above, made executable rather than asserted.
  rc=0; case "$SCRATCH_FENCE_SH"     in *"rm "*) rc=1 ;; esac
  st_case 0 "$rc" "the scratch FENCE TEXT contains no 'rm' - the case above cannot delete anything."
  rc=0; case "$STAMP_WRITE_FENCE_SH" in *"rm "*) rc=1 ;; esac
  st_case 0 "$rc" "nor does the stamp write fence text."
  rc=0; case "$STAMP_RM_FENCE_SH"    in *"rm "*) rc=1 ;; esac
  st_case 0 "$rc" "nor the stamp rm fence text."
  # GC-02's root cause was two copies that drifted in SILENCE. This is that drift check, executed.
  # The comparison is reduced to 0/1 rather than passed to st_case directly: st_case ECHOES the
  # observed value, and a multi-line fence text printed into the transcript on every run buries the
  # surrounding cases and makes the banner unreadable.
  rc=0; [ "$STAMP_WRITE_FENCE_SH" = "$STAMP_RM_FENCE_SH" ] || rc=1
  st_case 0 "$rc" \
    "the two stamp fence copies are BYTE-IDENTICAL - drift is now a red case, not a review request."
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
  ST_RUN=0
  REDS=0
  self_test_core
  self_test_classes
  self_test_vacuity
  self_test_fences
  say ""
  if [ "$ST_FAIL" -ne 0 ] || [ "$REDS" -ne 0 ]; then
    printf '  \342\234\227 self-test: %s of %s case(s) FAILED\n' "$((ST_FAIL))" "$((ST_RUN))"
    exit 1
  fi
  ok "self-test: $ST_RUN case(s), every fail-closed branch behaved exactly as expected"
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

# WR-01. The program text is SCRATCH_PROBE_PROG, defined up with the remote layer so that
# `--self-test` can drive it; the reasoning is written out at its definition.
rsh "$(dex_cmd "$(remote_sh_c "$SCRATCH_PROBE_PROG" "$SCRATCH")")"
if [ "$RSH_RC" -ne 0 ]; then
  precheck_fail "could not inspect '$SCRATCH' inside the container (exit $RSH_RC). Exit 4 is the
    probe's own status for 'the path IS there and could NOT BE READ' - most often a scratch
    directory left root-owned 0700 by an aborted run, which $CONTAINER_USER cannot list. That is a
    could-not-look, and it is NOT the same as 'absent or empty'. find's own diagnostic is on this
    terminal, above this line."
fi
case "$RSH_OUT" in
  absent|empty) : ;;
  notadir)
    precheck_fail "'$SCRATCH' exists inside the container but is NOT A DIRECTORY. The run would
    put the throwaway library, the overlay and the statefile underneath it - refusing."
    ;;
  'nonempty '*)
    # IN-11: name the cleanup in the refusal. A run that aborted between step 5 and step 12 leaves
    # a copy of the real library.db here, and without the command below this reads as an
    # unexplained refusal that the operator has to go and read the script to resolve.
    precheck_fail "'$SCRATCH' already exists inside the container and is not empty (first entry:
    ${RSH_OUT#nonempty }). A wrote-nothing assertion against a dirty destination proves nothing -
    refusing. This is what a run aborted between step 5 and step 12 leaves behind. Clear it with:

      ssh root@$LXC_HOST \"docker exec -u $CONTAINER_USER $CONTAINER rm -rf -- '$SCRATCH'\"

    The HOST stamp is a different matter and is NOT what this refusal is about: '--baseline'
    ALWAYS leaves '$STAMP_REMOTE' behind by design, because it is the -newer reference a later
    '--run' needs. Its presence is expected, and nothing here refuses on account of it."
    ;;
  *)
    precheck_fail "the scratch probe answered '$RSH_OUT', which is not one of the four words it
    can emit (absent / empty / notadir / 'nonempty <entry>'). Refusing rather than guessing: an
    unrecognised answer is a could-not-look, and this precheck no longer treats silence as good
    news."
    ;;
esac
ok "container scratch '$SCRATCH' is absent or empty (probed with find, whose status is READ)"

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
# SECOND FENCE LAYER, deliberately duplicated. The sending-side DESTRUCTIVE-KNOB FENCE has already
# refused anything outside /mnt/fast/safety/phase06/; STAMP_WRITE_FENCE_SH runs in the very shell
# that is about to `rm -f`, which is the layer that is actually adjacent to the destructive command.
# The sending layer stops the common case; this one is the one that cannot be bypassed by a future
# edit that forgets the first - and as of GC-02 that sentence is TRUE, which it was not before. The
# text, the reason the two copies are literal rather than aliased, and the account of how they
# drifted at birth are all at THE RECEIVING-SIDE FENCES block beside remote_sh_c; it is not repeated
# here. scripts/phase06-incremental-control.sh:473 has the same shape.
rsh "timeout $REMOTE_TIMEOUT $(remote_sh_c "$STAMP_WRITE_PROG" "$STAMP_REMOTE")"
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
rsh "$(dex_cmd "$(remote_sh_c 'mkdir -p "$1" && cp "$2" "$3" && echo copied' \
  "$SCRATCH" "$REAL_LIB_DB" "$SCRATCH_LIB")")"
rsh_classify "the library copy into $SCRATCH" || exit 3
ok "copied $REAL_LIB_DB -> $SCRATCH_LIB (the ORIGINAL is never opened by this run)"

{
  printf 'library: %s\n' "$SCRATCH_LIB"
  printf 'statefile: %s\n' "$SCRATCH_STATE"
  printf 'directory: %s\n' "$LIB_ROOT"
  printf 'import:\n'
  printf '    copy: no\n'
  printf '    move: no\n'
  printf '    write: no\n'
  printf '    autotag: no\n'
  printf '    resume: no\n'
  printf '    incremental: no\n'
  # MEASURED 2026-09-21 (plan 06-11, first live run): `skip` DROPPED THE SECOND American Heart
  # rip entirely - 164 pairs against 174 sampled files - and with it the ONE %aunique{} firing
  # 06-EXPECTED-TREE.txt predicts. The S1 stratum deliberately drew two rips of one album, so a
  # duplicate action that removes one of them from the library removes the collision the fixture
  # exists to test. `keep` imports both and deletes nothing, which is the only value that is both
  # safe AND faithful to the fixture: `remove` deletes source files with no prompt (Pitfall 3),
  # `merge` rewrites the album, and `ask` under -q silently falls back to skipping.
  printf '    duplicate_action: keep\n'
  # MEASURED 2026-09-21: `beet move -p` calls beets.util.diff.colordiff, which wraps BOTH the
  # source and the destination in SGR sequences - `/m<ESC>[1;32media/M<ESC>[39;49;00music/`. A
  # coloured destination can never equal a fixture line, and a coloured SOURCE cannot join to the
  # `beet ls -f` field view either, so CONF-03 would have read COULD NOT LOOK on all 174 rows.
  # Turned off at the source here; normalise_transcript ALSO strips SGR defensively, because a
  # future beets that colours through a different key must not be able to fail this silently.
  printf 'ui:\n'
  printf '    color: no\n'
} > "$OUT/overlay.yaml"
rsh_from "timeout $REMOTE_TIMEOUT docker exec -i -u $CONTAINER_USER $CONTAINER $(remote_sh_c 'cat > "$1"' "$SCRATCH_OVERLAY")" "$OUT/overlay.yaml"
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
  rsh "$(dex_cmd "$BEET_BIN" -c "$(printf '%q' "$SCRATCH_OVERLAY")" import -A -q $EXTRA "$(printf '%q' "$CPATH")")"
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
rsh_to "$(dex_cmd "$BEET_BIN" -c "$(printf '%q' "$SCRATCH_OVERLAY")" move -p)" "$OUT/oracle.raw.txt"
if [ "$RSH_RC" -ne 0 ]; then
  unknown "beet move -p exited $RSH_RC; the transcript is at $OUT/oracle.raw.txt"
  exit 3
fi
normalise_transcript "$OUT/oracle.raw.txt" "$OUT/oracle.pairs.tsv" "$OUT/oracle.destinations.txt" \
  || { unknown "$NORM_WHY"; exit 3; }
# `rsh_to` puts the command's stderr beside its stdout, and the unmoved count lives there.
read_unmoved "$OUT/oracle.raw.txt.err" || { unknown "$UNMOVED_WHY"; exit 3; }
say "  pairs parsed:            $NORM_PAIRS"
say "  unparsed payload lines:  $NORM_UNPARSED"
say "  SGR-coloured raw lines:  $NORM_SGR   [sanitised into $OUT/oracle.raw.txt.clean]"
say "  'Moving N items':        $MOVING_N   [read from stderr, the same loop that printed the pairs]"
if [ "$NORM_INPLACE_SEEN" -eq 1 ]; then
  say "  (N already in place):    $NORM_INPLACE   [READ from the 'Moving N items…' log line]"
else
  say "  (N already in place):    UNREAD"
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
NEWER_LIST=()
BLIND=""
while IFS="$(printf '\t')" read -r folder _ _; do
  [ -n "$folder" ] || continue
  # NEWER_ARGS feeds the bare-word `find` below, where the result lands in a BASH WORD and `%q`
  # is the correct tool. NEWER_LIST feeds the preflight, where the paths must cross into a remote
  # `sh -c` program and must therefore be PARAMETERS (WR-08). Two shapes, two contexts.
  NEWER_ARGS="$NEWER_ARGS $(printf '%q' "$folder")"
  NEWER_LIST+=("$folder")
done < "$OUT/sample.tsv"
# $1 is the stamp; everything after it is a sampled folder. The `[ -d ] && [ -r ] && [ -x ]` test
# and the BLIND: vocabulary are unchanged - what changed is that a folder named `Guns N' Roses -
# Greatest Hits` no longer terminates the program it was interpolated into.
PREFLIGHT_PROG='S="$1"
shift
for d in "$@"; do
  [ -d "$d" ] && [ -r "$d" ] && [ -x "$d" ] || { echo "BLIND:$d"; exit 0; }
done
[ -f "$S" ] || { echo "BLIND:stamp"; exit 0; }
echo READY'
rsh "set -o pipefail; timeout $REMOTE_TIMEOUT $(remote_sh_c "$PREFLIGHT_PROG" "$STAMP_REMOTE" ${NEWER_LIST[@]+"${NEWER_LIST[@]}"})"
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

# --- Step 11: the class assertions ---------------------------------------------------------------
# These run over the SAME measurement the diff just judged, and they run whether or not the diff
# was clean: a zero-diff tells you the paths match the fixture, and it tells you nothing at all
# about a failure class nobody wrote an expected line for.
say ""
say "== the class assertions (D-27) =="
rule

# A real tab, built locally and single-quoted into the remote string. beets' -f does NOT process
# backslash escapes, so `\t` in the format would be a literal backslash-t and every row would
# collapse into one field - which reads as a parse failure only if something checks the field
# count, and this does.
TAB="$(printf '\t')"
LS_FMT="\$path${TAB}\$albumartist${TAB}\$album${TAB}\$albumtype${TAB}\$artist${TAB}\$artists"
rsh_to "$(dex_cmd "$BEET_BIN" -c "$(printf '%q' "$SCRATCH_OVERLAY")" ls -f "'$LS_FMT'")" "$OUT/fields.tsv"
if [ "$RSH_RC" -ne 0 ]; then
  unknown "the throwaway library's field view could not be read (ssh exit $RSH_RC)"
else
  # IN-12. The judging is in assert_field_view so --self-test can feed it an empty file; this
  # site only prints. Every non-zero return is a could-not-look: there is no red arm.
  FV_RC=0
  assert_field_view "$OUT/fields.tsv" || FV_RC=$?
  case "$FV_RC" in
    0) ok "field view read: $ASSERT_WHY" ;;
    *) unknown "field view read: $ASSERT_WHY" ;;
  esac
fi

write_ledger_payload "$OUT/ledger.py"
# argv[2] is the library directory, and it is not optional - see the payload's own main().
rsh_from_to "timeout $REMOTE_TIMEOUT docker exec -i -u $CONTAINER_USER $CONTAINER $PY_BIN - $(printf '%q' "$SCRATCH_LIB") $(printf '%q' "$LIB_ROOT")" \
  "$OUT/ledger.py" "$OUT/ledger.ndjson"
if [ "$RSH_RC" -ne 0 ]; then
  unknown "the D-18 ledger generator exited $RSH_RC; stderr is at $OUT/ledger.ndjson.err"
fi

# The expected DJ file count comes from 06-SAMPLE.md's own S5 rows - READ, never re-typed - and is
# cross-checked against the committed fixture. If those two ever disagree the equality below would
# be testing a number nobody wrote down.
DJ_SAMPLE="$(LC_ALL=C awk -F'\t' '$2 == "S5" {s += $3} END {print s + 0}' "$OUT/sample.tsv")"
DJ_FIXTURE="$(LC_ALL=C grep -v '^#' "$EXPECTED_TREE" | LC_ALL=C grep -c "^$LIB_ROOT/DJ/" || true)"
if [ "$DJ_SAMPLE" -ne "$DJ_FIXTURE" ]; then
  bad "the sample's S5 strata hold $DJ_SAMPLE files but the fixture carries $DJ_FIXTURE DJ/ lines.
    The D-13 equality below would be measured against a number the two sources disagree on."
fi

run_assert "CONF-03 top level"       assert_top_level "$OUT/oracle.pairs.tsv" "$OUT/fields.tsv"
run_assert "D-15 no Compilations/"   assert_no_compilations "$OUT/oracle.destinations.txt"
run_assert "D-13 DJ count equality"  assert_dj_count "$OUT/oracle.destinations.txt" "$DJ_SAMPLE"
run_assert "D-16 %aunique{} firings" assert_aunique "$OUT/oracle.destinations.txt" "$EXPECTED_TREE"
run_assert "D-19b singletons"        assert_singletons "$OUT/oracle.destinations.txt" "$EXPECTED_TREE" "$OUT/oracle.pairs.tsv"
run_assert "D-19a album != artist"   assert_album_ne_artist "$OUT/oracle.destinations.txt"
run_assert "the '-1 - ' shape"       assert_no_minus_one "$OUT/oracle.destinations.txt"
run_assert "the .N collision shape"  assert_no_collision_suffix "$OUT/oracle.destinations.txt"
run_assert "D-18 protected fields"   assert_protected_fields "$OUT/ledger.ndjson" "$SAMPLE_FILES"

say ""
say "== CONF-04's write side, REPORTED (D-23 as amended by D-34) =="
rule
run_assert "CONF-04 write side" report_multi_artist "$OUT/fields.tsv"
say "  beets CANNOT be configured to emit ';' inside ARTIST - no delimiter or join key exists in"
say "  config_default.yaml at either version. 'artist' carries MusicBrainz's own join phrases"
say "  concatenated, and the multi-artist information lands in ARTISTS (TXXX / Vorbis). That is"
say "  what D-34 aligns Jellyfin to by enabling PreferNonstandardArtistsTag on the Music library."

# --- Step 12: cleanup ----------------------------------------------------------------------------
say ""
# SECOND FENCE LAYER, deliberately duplicated (WR-07; T-06-90; GC-02). The DESTRUCTIVE-KNOB FENCE
# at the top of this file has already refused any SCRATCH outside the allow-list, and remote_sh_c
# passes the path as a parameter so nothing can re-split it in transit. SCRATCH_FENCE_SH is
# nevertheless repeated INSIDE the remote program, because that is the shell about to run `rm -rf`
# and it is the only layer actually adjacent to the destructive command: the sending layer stops the
# common case, the receiving layer is the one a future edit cannot quietly remove the protection
# from. GC-02 is why that last clause is only true as of this change - see THE RECEIVING-SIDE
# FENCES block beside remote_sh_c for the text and the account; it is not repeated here.
# scripts/phase06-incremental-control.sh:473 fences its cleanup the same way.
rsh "$(dex_cmd "$(remote_sh_c "$CLEANUP_PROG" "$SCRATCH")")"
if [ "$RSH_RC" -eq 0 ] && [ "$RSH_OUT" = "gone" ]; then
  ok "container scratch '$SCRATCH' removed and its absence asserted"
else
  bad "container scratch '$SCRATCH' is still present (or its removal could not be confirmed)"
fi
# Same duplication, same reason, same GC-02 correction, for the host-side stamp: STAMP_RM_FENCE_SH,
# cross-referenced rather than restated. self_test_fences asserts it is byte-identical to the write
# side's copy, so the two cannot drift apart again without a case going red.
rsh "timeout $REMOTE_TIMEOUT $(remote_sh_c "$STAMP_RM_PROG" "$STAMP_REMOTE")"

say ""
rule
# The ORDER of these two is the house convention stated in the EXIT CODES block at the top of this
# file: a BLIND INSTRUMENT OUTRANKS A MEASURED RED. Both counters can be non-zero at once, so this
# is a decision. scripts/phase06-incremental-control.sh consults its counters in the same order.
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
