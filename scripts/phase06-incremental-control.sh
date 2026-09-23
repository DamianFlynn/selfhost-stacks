#!/usr/bin/env bash
# phase06-incremental-control.sh - Phase 6 / D-31: prove the `incremental` trap FIRES, and prove
#                                 the configured key DEFEATS it. Two arms, one config key apart.
#
# Where it runs:
#   FROM THE REPO ROOT ON THE WORKSTATION (macOS). It ssh-delegates to LXC 100
#   (root@172.16.1.159) and `docker exec`s into the `beets-flask` container, because the beets
#   that matters is the 2.12.0 inside that image and the source tree only exists on that host.
#   Every remote command is bounded LINUX-SIDE by `timeout` - macOS has no GNU timeout, and a
#   `cmd | wc -l` silently exits 0 (CLAUDE.md, README § Health Checks), so no remote pipeline
#   carries a verdict here: each remote program reads every exit status explicitly.
#
#   The container's /bin/sh is dash [MEASURED 2026-09-21], which does NOT support
#   `set -o pipefail`. That is why the remote programs contain no pipeline whose failure could
#   be swallowed, and why they are shipped on stdin with their arguments as positional
#   parameters rather than interpolated - a quoted heredoc cannot leak a local expansion into a
#   remote command line.
#
# Usage:
#   bash scripts/phase06-incremental-control.sh --arm a        # incremental_skip_later: no
#   bash scripts/phase06-incremental-control.sh --arm b        # incremental_skip_later: yes
#   bash scripts/phase06-incremental-control.sh --baseline     # D-29 layer 3 sample only
#   bash scripts/phase06-incremental-control.sh --cleanup      # remove both throwaway trees
#   bash scripts/phase06-incremental-control.sh --self-test    # no ssh, no docker
#   bash scripts/phase06-incremental-control.sh --help
#
# EXIT CODES - stated explicitly because three of the four are not failures of this script:
#   0  PASS      the arm produced its EXPECTED outcome (or the self-test / baseline was green)
#   1  FAIL      the arm produced the OPPOSITE outcome, or an assertion about real state failed.
#                This is a measurement, not a crash: record it and stop.
#   2  UNKNOWN   an instrument COULD NOT LOOK - remote timeout (124), unreadable pickle, a
#                vanished tree. "Could not look" is a distinct outcome from "nothing is wrong"
#                and it is NEVER a pass.
#   3  REFUSED   a preflight refused to run: dirty destination, source outside the fence, the
#                two overlays not exactly one key apart, or a USAGE error (a missing or illegal
#                `--arm` value). Nothing was measured.
#
#   PRECEDENCE, when one run BOTH measured a failure AND had an instrument that could not look:
#   2 (UNKNOWN) OUTRANKS 1 (FAIL). The two conditions are not mutually exclusive, so this is a
#   decision, not an accident of ordering. Reason: this estate's standing rule (CLAUDE.md and
#   README § Health Checks) is that "could not look" is kept distinct from "nothing is wrong"
#   and is never folded into another verdict - reporting a measured red while an instrument was
#   blind asserts a cause the run did not establish. THE SIBLING INSTRUMENT WRITTEN IN THIS SAME
#   PHASE, scripts/phase06-oracle.sh, IMPLEMENTS THE IDENTICAL CONVENTION: it consults its
#   UNKNOWN counter before its RED counter. (Its numbering differs - there UNKNOWN is 3 and
#   usage/refusal is 2 - but the precedence is the same, and each header names the other.)
#   Driven by `--self-test` section 7/7, which asserts the blind verdict wins when both hold,
#   and by section 6/7 for the re-offer classifier the same run depends on.
# ==============================================================================================
#
# WHAT THIS MEASURES (D-31, CONF-02)
#   `ImportTask.finalize()` calls `save_history()` on a SKIPPED task unless
#   `incremental_skip_later` is set:
#       if session.config["incremental"] and not (
#           self.skip and session.config["incremental_skip_later"]
#       ):
#           self.save_history()
#   [SOURCE: beets/importer/tasks.py@2.12.0:310-319, read out of the running container]
#   and `manipulate_files` calls `task.finalize(session)` OUTSIDE its `if not task.skip:` block
#   [SOURCE: beets/importer/stages.py@2.12.0:288-314], so a skipped task really does reach it.
#
#   So with `incremental: yes` and `incremental_skip_later: no`, one quiet pass permanently marks
#   every hard album complete and the backlog becomes INVISIBLE rather than imported. This
#   project's standing rule - stated separately in Phases 2, 02.1 and 4 - is that reading a
#   setting back is not proof it applies. So this script makes the trap fire, then makes it not
#   fire, and the two arms differ in exactly one key.
#
# THE SKIP IS DETERMINISTIC AND OFFLINE, BY CONSTRUCTION
#   `_summary_judgment()` returns APPLY only when the recommendation is `strong`; otherwise it
#   returns `quiet_fallback` [SOURCE: beets/ui/commands/import_/session.py@2.12.0:328-360].
#   Both overlays set `plugins: []`, so NO metadata source is enabled, no candidate can be
#   produced, and the recommendation can never be `strong`. The skip therefore does not depend
#   on MusicBrainz being reachable, on what MusicBrainz happens to return today, or on the
#   network at all. A control whose outcome moves with a third party's database is not a control.
#
# WHY --pretend IS USED FOR STEP 4 AND FOR NOTHING ELSE
#   Step 4 asks ONE question: is the folder still OFFERED? That is exactly what `--pretend`
#   answers - it prints the albums and files it WOULD import - and it answers it without
#   reaching `finalize`, the only place `save_history()` and `save_progress()` are called. So
#   using it to read the state cannot itself mutate the state being read. That is the whole of
#   its licence here.
#
#   D-33 PROHIBITION: `--pretend` is NEVER a tree oracle, here or anywhere in this phase. It
#   prints SOURCE paths and no destination, so a long `--pretend` transcript says nothing
#   whatever about where files would land or what they would be named. The tree oracle is
#   `beet move -p`, whose lines contain ` -> `. Do not substitute one for the other.
#
# WHY BOTH ARMS PRE-SEED AN EMPTY STATE FILE
#   MEASURED 2026-09-21: with `incremental_skip_later: yes` beets never CREATES the state file
#   at all - nothing is recorded, so `_save()` is never called. An absent file would then make
#   "taghistory is empty" and "I could not look at taghistory" the same observation, which is
#   the exact collapse this repo forbids. So both arms write a readable, empty
#   {"tagprogress": {}, "taghistory": set()} pickle first - the identical byte sequence beets'
#   own `_save()` writes [SOURCE: beets/importer/state.py@2.12.0]. It is done by the SAME code
#   in BOTH arms, so it cannot flatter either one, and it gives arm B a positive reading
#   (readable, zero entries) instead of an absence.
#
# ENV OVERRIDES - three, all in the ${VAR:-default} form so a grep can prove they exist:
#     REMOTE_TIMEOUT  seconds bounding every remote command (default 120). A 124 is reported as
#                     UNKNOWN, never as a pass, so this cannot turn a measured negative green -
#                     it only decides whether the instrument gets to finish.
#     OUT_DIR         where the captures land (default under $TMPDIR). Report-only.
#     SRC_FOLDER      the throwaway source folder INSIDE the container. Fenced to
#                     $SRC_ALLOW_PREFIX with no `..` component. A wrong value makes this REDDER,
#                     not greener: a folder with no audio files yields no import task, so arm A's
#                     taghistory stays empty and arm A FAILS.
#
#   PLAIN CONSTANTS, deliberately not overrides, because an override on any of them could
#   MANUFACTURE A PASS: the two throwaway roots, the container name, the real library/state
#   paths, and the two D-29 baseline hashes. Point the "real" paths anywhere else and the
#   unchanged-state assertion becomes vacuous. Changing one of these is a one-line edit here, in
#   the commit that changes the policy. There is no sentinel that skips a check, however
#   convenient one looks while debugging - do not add one.
#
# IN-CONTAINER TEMP NAMES ARE MINTED BY THE CONTAINER, NOT CHOSEN BY THE WORKSTATION
#   [GC-08; the sibling half of the same question is GC-07 against scripts/phase06-oracle.sh.
#    Evidence, measurements and the one decision both files share:
#    .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-25-incremental-tempnames.txt]
#
#   The remote programs below used to write to FIXED names in the container's /tmp - three
#   /tmp/p6-man.* manifest files, and /tmp/p6-taghist.py, which was written with `>` and then
#   EXECUTED by the interpreter on the very next line. MEASURED 2026-09-22 inside `beets-flask`:
#   /tmp is mode 1777, and every process in that container other than PID 1 runs as uid 568 -
#   the SAME uid this script's `docker exec -u beetle` uses. So the kernel's own
#   fs.protected_symlinks=1 / fs.protected_regular=2 (both measured on LXC 100) do NOT help here:
#   they only refuse a follow when the pre-placed name is owned by a DIFFERENT uid.
#
#   THE PROPERTY THIS NOW RELIES ON IS CREATION, NOT SECRECY. `mktemp` creates with O_EXCL, so it
#   FAILS rather than opening a name that already exists, and it will not follow a symlink into
#   being. The X's are not a secret and are not claimed to be one - a template prefix is still
#   greppable in this file. Unpredictability is not the mitigation; refusing-to-open-what-is-
#   already-there is. This is stated deliberately, because the claim it replaces ("suffixing with
#   the run's PID removes the predictability") was a claim the code could not keep: $$ there is
#   the WORKSTATION's bash PID, a label with no relationship to the container's namespace.
#
#   A MINT THAT FAILS IS A REFUSAL, NEVER A FALLBACK. Both programs print a BLIND line in the
#   local vocabulary and exit 2 (UNKNOWN - could-not-look, which is never a pass). There is
#   deliberately no fallback to the fixed name: a fallback is the original defect wearing a
#   mitigation's label, and it would fire precisely when the environment is least trustworthy.
#   Driven in both directions - see § "the fail-closed drive" in the artifact named above.

set -euo pipefail

# --- Constants (see the override contract above; none of these is an override) ---------------
LXC_HOST="root@172.16.1.159"
CONTAINER="beets-flask"
BEET="/venv/bin/beet"
PY="/venv/bin/python"
REAL_LIB="/config/library.db"
REAL_STATE="/config/state.pickle"
ARM_A_ROOT="/tmp/p6a"
ARM_B_ROOT="/tmp/p6b"
SRC_ALLOW_PREFIX="/downloads/complete/nzb/"

# D-29 layer 3 baseline. PROVENANCE: plan 06-04's post-first-start capture,
# .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-04-first-start.txt, which
# 06-04 measured to be byte-identical to its own pre-start capture (rc6's migrations moved its
# OWN sqlite job database, not beets' library). 06-06 and 06-07 both re-read these unchanged.
BASELINE_LIB_SHA256="fbbdde0c416e72b9884e56c562fd88eaa4da447926e1cb6cc17c3e04aee7da1a"
BASELINE_STATE_SHA256="f6a9a1ad7aa553e42e53a8056fa80724785111180a5e2122be4f8732d1e4bc7c"

# --- Overrides --------------------------------------------------------------------------------
REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-120}"
OUT_DIR="${OUT_DIR:-${TMPDIR:-/tmp}/phase06-incremental-control}"
SRC_FOLDER="${SRC_FOLDER:-/downloads/complete/nzb/music/Cyril - Stumblin In (LUNAX Remix) (Extended Mix)-(5021732254740)-SINGLE-WEB-2024-ZzZz [9c1feafc0] [2af13ead9]-xpost}"

SSH_OPTS="-o ConnectTimeout=10 -o BatchMode=yes"

# --- Reporting --------------------------------------------------------------------------------
say()  { printf '%s\n' "$*"; }
rule() { printf '%s\n' "----------------------------------------------------------------------"; }
ok()   { printf '  [ ok ] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
blind(){ printf '  [BLIND] %s\n' "$*"; }

print_header() {
  sed -n '2,/^set -euo pipefail$/p' "$0" | sed -e '/^set -euo pipefail$/d' -e 's/^# \{0,1\}//'
}

# --- Portable local hashing (macOS has shasum, Linux has sha256sum) --------------------------
local_sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    return 2
  fi
}

# Single-quote a string for safe transport through the remote login shell.
shq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

# --- The source fence -------------------------------------------------------------------------
# CR-01's lesson: a string-prefix guard is bypassed by `..`. Both halves are asserted - the
# literal prefix AND the absence of any `..` path component - because the resolved path cannot be
# computed locally for a path that only exists inside a container.
FENCE_WHY=""
fence_eval() { # $1 = candidate  $2 = required prefix
  local given="$1" prefix="$2"
  FENCE_WHY=""
  case "$given" in
    /*) : ;;
    *) FENCE_WHY="'$given' is not absolute"; return 1 ;;
  esac
  case "$given" in
    "$prefix"*) : ;;
    *) FENCE_WHY="'$given' is not under the allow-prefix '$prefix'"; return 1 ;;
  esac
  case "/$given/" in
    */../*) FENCE_WHY="'$given' contains a '..' component, which escapes the prefix check"; return 1 ;;
  esac
  return 0
}

# --- Three-outcome manifest comparison (0 identical / 1 differs / >=2 could not compare) -----
DIFF_OUT=""
DIFF_WHY=""
manifest_compare() { # $1 = before file  $2 = after file
  local b="$1" a="$2" f="" rc=0 errf="" err=""
  DIFF_OUT=""; DIFF_WHY=""
  for f in "$b" "$a"; do
    if [ ! -e "$f" ]; then DIFF_WHY="manifest '$f' does not exist - it was never captured"; return 2; fi
    if [ ! -f "$f" ]; then DIFF_WHY="manifest '$f' is not a regular file"; return 2; fi
    if [ ! -r "$f" ]; then DIFF_WHY="manifest '$f' is not readable"; return 2; fi
    if [ ! -s "$f" ]; then DIFF_WHY="manifest '$f' is EMPTY - an empty listing compares equal to any other empty listing, which would pass vacuously"; return 2; fi
  done
  errf="$(mktemp "${TMPDIR:-/tmp}/p6-08-diff-XXXXXX")" || { DIFF_WHY="could not create a temp file for diff's stderr"; return 2; }
  DIFF_OUT="$(diff -- "$b" "$a" 2>"$errf")" || rc=$?
  err="$(cat "$errf" 2>/dev/null || true)"
  rm -f "$errf"
  if [ "$rc" -ge 2 ]; then
    DIFF_WHY="diff could not compare '$b' and '$a' (rc=$rc)"
    [ -z "$err" ] || DIFF_WHY="$DIFF_WHY: $err"
    return 2
  fi
  if [ -n "$err" ]; then DIFF_WHY="diff exited $rc but wrote to stderr, which is unexplained: $err"; return 2; fi
  [ "$rc" -eq 1 ] && return 1
  if [ -n "$DIFF_OUT" ]; then DIFF_WHY="diff exited 0 but printed a difference, which is unexplained"; return 2; fi
  return 0
}

# --- The overlays, generated here so they cannot drift from the arms that use them ------------
# Both live in the container's /tmp. MEASURED 2026-09-21: the container's /tmp is on the docker
# OVERLAY (126 G, 25 G free on LXC 100's ext4 root), NOT on LXC 100's tmpfs - so the tmpfs-RAM
# hazard the plan cites does not apply as written. Keep them tiny anyway: that 126 G root is the
# same filesystem six stacks already write to silently.
emit_overlay() { # $1 = arm root  $2 = incremental_skip_later value
  cat <<EOF
# generated by scripts/phase06-incremental-control.sh - throwaway, never committed
library: $1/lib.db
statefile: $1/state.pickle
directory: $1/tree
plugins: []
import:
  incremental: yes
  incremental_skip_later: $2
  copy: no
  move: no
  link: no
  hardlink: no
  reflink: no
  write: no
  delete: no
  autotag: yes
  timid: no
  quiet: yes
  quiet_fallback: skip
  resume: no
  duplicate_action: skip
EOF
}

# `-l` does NOT redirect `statefile:` - `ImportState.__init__` reads
# `config["statefile"].as_filename()` and there is no CLI flag for it
# [SOURCE: beets/importer/state.py@2.12.0]. That is why the overlay names `library`, `statefile`
# AND `directory`, and why an arm run with `-l` alone would poison the real state.pickle.

# Assert the two overlays are exactly one KEY apart. The three path keys necessarily differ
# (separate throwaway trees), so the assertion is made in two halves, and the first is stronger
# than counting diff lines:
#   1. canonicalise arm B's root to arm A's; the result must be BYTE-IDENTICAL to arm A except
#      for the one key. A stray whitespace change therefore cannot hide inside a two-line diff.
#   2. the surviving diff must be exactly two `<`/`>` lines, and both must name
#      incremental_skip_later.
ONEKEY_WHY=""
assert_one_key_apart() { # $1 = overlay A  $2 = overlay B
  local a="$1" b="$2" canon="" d="" nlines=0 nnamed=0 rc=0
  ONEKEY_WHY=""
  for f in "$a" "$b"; do
    [ -s "$f" ] || { ONEKEY_WHY="overlay '$f' is missing or empty"; return 2; }
  done
  canon="$(mktemp "${TMPDIR:-/tmp}/p6-08-canon-XXXXXX")" || { ONEKEY_WHY="could not create a temp file"; return 2; }
  sed "s#${ARM_B_ROOT}#${ARM_A_ROOT}#g" "$b" > "$canon" || { rm -f "$canon"; ONEKEY_WHY="could not canonicalise '$b'"; return 2; }
  d="$(diff -- "$a" "$canon" 2>/dev/null)" || rc=$?
  rm -f "$canon"
  if [ "$rc" -ge 2 ]; then ONEKEY_WHY="diff could not compare the overlays (rc=$rc)"; return 2; fi
  if [ "$rc" -eq 0 ]; then ONEKEY_WHY="the overlays are IDENTICAL once the roots are canonicalised - there is no variable, so there is no control"; return 1; fi
  nlines="$(printf '%s\n' "$d" | grep -c '^[<>]' || true)"
  nnamed="$(printf '%s\n' "$d" | grep '^[<>]' | grep -c 'incremental_skip_later' || true)"
  if [ "$nlines" -ne 2 ] || [ "$nnamed" -ne 2 ]; then
    ONEKEY_WHY="the overlays differ in $nlines line(s), of which $nnamed name incremental_skip_later - expected 2 and 2. The arms would be measuring the difference rather than the key."
    return 1
  fi
  return 0
}

# --- taghistory: read out of the PICKLE, never out of a log ----------------------------------
# A log line saying nothing was recorded is indistinguishable from a log that was never written.
# `ImportState._open()` swallows every read error with a `log.debug` [SOURCE: state.py@2.12.0],
# so beets' own silence proves nothing either. This program is the instrument, and it is the
# SAME text that `--self-test` drives over synthetic pickles - not a paraphrase of it.
TAGHISTORY_PROBE_PY='
import pickle, sys
p = sys.argv[1]
try:
    with open(p, "rb") as f:
        d = pickle.load(f)
except FileNotFoundError:
    print("TAGHISTORY ABSENT " + p); raise SystemExit(0)
except Exception as e:
    print("TAGHISTORY UNREADABLE %s: %s" % (type(e).__name__, e)); raise SystemExit(0)
if not isinstance(d, dict):
    print("TAGHISTORY UNREADABLE not-a-dict:%s" % type(d).__name__); raise SystemExit(0)
if "taghistory" not in d:
    print("TAGHISTORY UNREADABLE key-absent keys=%r" % sorted(d.keys())); raise SystemExit(0)
h = d["taghistory"]
try:
    n = len(h)
except Exception as e:
    print("TAGHISTORY UNREADABLE unsized:%s" % e); raise SystemExit(0)
if n == 0:
    print("TAGHISTORY EMPTY 0")
else:
    print("TAGHISTORY POPULATED %d %r" % (n, sorted(h)))
'

# Pure classifier over the probe's output. Four outcomes, and EMPTY is never conflated with
# ABSENT or UNREADABLE. No marker line at all is itself UNREADABLE: python missing, the
# interpreter gone, a truncated transport.
TAGHIST_CLASS=""
TAGHIST_DETAIL=""
classify_taghistory() { # $1 = the probe's captured stdout
  local out="$1" line=""
  TAGHIST_CLASS=""; TAGHIST_DETAIL=""
  line="$(printf '%s\n' "$out" | grep '^TAGHISTORY ' | head -n 1 || true)"
  if [ -z "$line" ]; then
    TAGHIST_CLASS="unreadable"
    TAGHIST_DETAIL="the probe emitted no TAGHISTORY line at all"
    return 0
  fi
  TAGHIST_DETAIL="$line"
  case "$line" in
    "TAGHISTORY POPULATED "*)  TAGHIST_CLASS="populated" ;;
    "TAGHISTORY EMPTY "*)      TAGHIST_CLASS="empty" ;;
    "TAGHISTORY ABSENT "*)     TAGHIST_CLASS="absent" ;;
    "TAGHISTORY UNREADABLE "*) TAGHIST_CLASS="unreadable" ;;
    *)                         TAGHIST_CLASS="unreadable"; TAGHIST_DETAIL="unrecognised marker: $line" ;;
  esac
  return 0
}

# --- The step-4 re-offer classifier -----------------------------------------------------------
# Factored out of run_arm so `--self-test` and an offline drive can feed it a synthetic
# transcript. A classifier that is only reasoned about is an assumption, not a control.
#
# THREE OUTCOMES, unchanged: `not-offered` (beets reports the paths skipped), `offered` (an
# `Album: ` line is present), and the `indeterminate` fall-through - which the caller treats as
# BLIND, never as green - for anything else, including the `contradictory` case where both
# markers appear at once.
#
# THE PATH COUNT IS NOT PINNED. [IN-10, plan 06-20] This used to match the literal
# `Skipped 1 paths.`, but SRC_FOLDER is an OFFERED override (see the header's override contract)
# and a source folder yielding two albums prints a count of 2 - which fell through to
# `indeterminate`, i.e. BLIND, so the negative control silently stopped discriminating while
# still appearing to run, for exactly the case the override invites. Only the COUNT is widened:
# every other unrecognised transcript still reaches `indeterminate`.
classify_reoffer() { # $1 = a file holding the --pretend transcript; echoes the mode
  local f="$1" mode="indeterminate"
  if grep -qE 'Skipped [0-9]+ paths\.' "$f"; then mode="not-offered"; fi
  if grep -q '^Album: ' "$f"; then
    if [ "$mode" = "not-offered" ]; then mode="contradictory"; else mode="offered"; fi
  fi
  printf '%s\n' "$mode"
}

# --- Remote plumbing --------------------------------------------------------------------------
RE_OUT=""; RE_ERR=""; RE_RC=0
remote_exec() { # $1 = local program file; rest = positional args for the remote `sh -s`
  local prog="$1"; shift
  local qargs="" a=""
  for a in "$@"; do qargs="$qargs $(shq "$a")"; done
  RE_RC=0
  # No pipeline on this line: the container's dash has no pipefail and the rc is the verdict.
  ssh $SSH_OPTS "$LXC_HOST" "timeout $REMOTE_TIMEOUT docker exec -i -u beetle $CONTAINER sh -s$qargs" < "$prog" > "$RE_OUT" 2> "$RE_ERR" || RE_RC=$?
  return 0
}

# THERE IS DELIBERATELY NO NARROW BLINDNESS CLASSIFIER HERE. [IN-02, plan 06-20]
# A named helper used to sit at this point testing only `RE_RC` in {124, 2, 255}, and NOTHING
# CALLED IT - every caller instead tests `[ "$RE_RC" -ne 0 ]`, which is strictly WIDER: it also
# catches 1, 125 (docker could not run), 126 (not executable) and 127 (command not found). A
# named classification that a reader assumes is in force while a different, wider test actually
# decides is a repudiation hazard, and routing the callers through the narrow one would have
# been a regression dressed as a cleanup. So the wider inline test stays and the dead name is
# gone. Any future blindness helper MUST be at least as wide as `-ne 0` and MUST be called.

# --- Remote programs (quoted heredocs: nothing local expands into them) ----------------------
write_prog_prepare() { cat > "$1" <<'REOF'
# $1 = arm root  $2 = source folder  $3 = beet path (unused here)  $4 = python path
set -u
ROOT="$1"; SRC="$2"; PY="$4"
case "$ROOT" in /tmp/p6a|/tmp/p6b) : ;; *) echo "PREP REFUSED root '$ROOT' is not one of the two throwaway roots"; exit 3 ;; esac
if [ -e "$ROOT" ]; then
  LST="$(find "$ROOT" -mindepth 1 2>/dev/null)"; FRC=$?
  if [ "$FRC" -ne 0 ]; then echo "PREP BLIND find on '$ROOT' rc=$FRC"; exit 2; fi
  N=0
  if [ -n "$LST" ]; then N="$(printf '%s\n' "$LST" | grep -c .)"; fi
  if [ "$N" -ne 0 ]; then
    echo "PREP REFUSED dirty-destination '$ROOT' holds $N entries - a wrote-nothing assertion against a dirty destination proves nothing"
    exit 3
  fi
  rmdir "$ROOT" 2>/dev/null || true
fi
echo "PREP DEST clean $ROOT"
mkdir -p "$ROOT/src" "$ROOT/tree" || { echo "PREP BLIND could not create '$ROOT'"; exit 2; }
if [ ! -d "$SRC" ]; then echo "PREP BLIND source '$SRC' is not a directory"; exit 2; fi
if [ ! -r "$SRC" ] || [ ! -x "$SRC" ]; then echo "PREP BLIND source '$SRC' is not readable and searchable"; exit 2; fi
CNT=0
for F in "$SRC"/*; do
  [ -f "$F" ] || continue
  cp "$F" "$ROOT/src/" || { echo "PREP BLIND cp failed for '$F' - NOTE: cp, never mv"; exit 2; }
  CNT=$((CNT + 1))
done
if [ "$CNT" -eq 0 ]; then echo "PREP BLIND no regular files copied from '$SRC'"; exit 2; fi
echo "PREP COPIED $CNT files (copy, never move)"
"$PY" - "$ROOT/state.pickle" <<'PYEOF'
import pickle, sys
with open(sys.argv[1], "wb") as f:
    pickle.dump({"tagprogress": {}, "taghistory": set()}, f)
print("PREP SEEDED", sys.argv[1])
PYEOF
SEED_SHA="$(sha256sum "$ROOT/state.pickle")"; SRC_RC=$?
if [ "$SRC_RC" -ne 0 ]; then echo "PREP BLIND could not hash the seeded state file"; exit 2; fi
echo "PREP SEED_SHA $SEED_SHA"
rm -f "$ROOT.stamp"
touch "$ROOT.stamp" || { echo "PREP BLIND could not create the stamp outside the mounts"; exit 2; }
sleep 1
echo "PREP STAMP $ROOT.stamp (outside every mount this arm reads or writes)"
echo "PREP OK"
REOF
}

write_prog_manifest() { cat > "$1" <<'REOF'
# $1 = source folder
# LC_ALL=C on BOTH the find ordering and the sort: a locale-dependent collation makes two
# identical trees compare different, which would read as "the import wrote something".
set -u
SRC="$1"
if [ ! -d "$SRC" ]; then echo "MANIFEST BLIND '$SRC' is not a directory"; exit 2; fi
# GC-08: ONE minted directory for all three scratch files, rather than three fixed names in a
# world-writable /tmp. The property is mktemp's O_EXCL creation, not the secrecy of the prefix.
# The minting failure joins the SAME `MANIFEST BLIND ... exit 2` ladder as every other
# could-not-look below it; it is NOT a fallback to the fixed names.
MANDIR="$(mktemp -d /tmp/p6-mf.XXXXXXXX 2>/dev/null)" || MANDIR=""
if [ -z "$MANDIR" ]; then
  echo "MANIFEST BLIND could not mint a scratch directory with mktemp - refusing to fall back to fixed names in a world-writable /tmp"
  exit 2
fi
# CLEANUP IS ON A TRAP, not on the success path. Chosen because every BLIND below exits early and
# the old `rm -f` sat only after the last one, so any could-not-look left all three files behind -
# and a MINTED leftover is worse litter than a fixed one, because nobody knows its name.
#
# R3-10: WHAT THE TRAP'S RE-CHECK ACTUALLY GIVES, replacing an absolute that this comment used to
# state and the code never supported. The removal happens only if the value begins with the
# template prefix AND the remainder is non-empty and drawn entirely from the class
# [A-Za-z0-9._-]. That class excludes `/`, so a traversal in the remainder is refused; the
# prefix-only shape this replaces did NOT exclude `/`, because a shell glob matches it - which is
# the whole content of GC-02 on the three destructive sites in scripts/phase06-oracle.sh, shipped
# in the same round as the fence it is now correcting here. The two files state ONE rule.
# THE DEFECT WAS LATENT, NOT REACHABLE, and this comment says so rather than dramatising it:
# MANDIR is only ever mktemp output, and mktemp will not emit a traversal. What is closed is the
# inconsistency between two sibling instruments and a claim stronger than its code - which is
# precisely how the real fence eventually gets deleted as duplicated.
# `""` and not `''` for the empty pattern: the trap body is a single-quoted string, so an inner
# single quote would terminate it. dash treats the two patterns identically.
#
# R3-09: THE SIGNAL LIST IS NOT JUST THE EXIT PSEUDO-SIGNAL, and that is not decoration. A POSIX
# shell runs an exit trap on normal termination and on `exit`, but NOT on an uncaught SIGTERM. This
# program is delivered as `sh -s` through `timeout $REMOTE_TIMEOUT docker exec` (the bound defaults
# to 120s), so a bound expiry is a ROUTINE outcome for a manifest over a large tree, not an exotic
# one - and on the narrow list that expiry left behind exactly the minted leftover the CLEANUP
# paragraph at the top of this block calls the worse litter, one directory per timed-out run, in a
# /tmp this file's header records as mode 1777.
# THE RESIDUAL, stated rather than claimed away: SIGKILL cannot be trapped, so a hard kill still
# leaves the directory. Widening the list SHRINKS the window; it does not close it.
# NOT DONE, deliberately: the best-effort sweep of other names carrying this template prefix that
# the review floats as a second idea. Removing a name THIS RUN DID NOT MINT is a wider destructive
# reach than the finding justifies on a shared container /tmp, in a round whose whole subject is
# fences reaching further than their comments admit. Carried to the deferred register by plan
# 06-34 rather than silently dropped.
trap 'case "${MANDIR:-}" in
        /tmp/p6-mf.*) case "${MANDIR#/tmp/p6-mf.}" in ""|*[!A-Za-z0-9._-]*) : ;; *) rm -rf "$MANDIR" ;; esac ;;
      esac' EXIT INT TERM HUP
echo "MANIFEST-META-BEGIN"
LC_ALL=C find "$SRC" -type f -printf '%p\t%s\t%T@\n' > "$MANDIR/meta"; MRC=$?
if [ "$MRC" -ne 0 ]; then echo "MANIFEST BLIND find -printf rc=$MRC"; exit 2; fi
LC_ALL=C sort "$MANDIR/meta"; SRC2=$?
if [ "$SRC2" -ne 0 ]; then echo "MANIFEST BLIND sort rc=$SRC2"; exit 2; fi
echo "MANIFEST-META-END"
echo "MANIFEST-SHA-BEGIN"
LC_ALL=C find "$SRC" -type f -print0 > "$MANDIR/z"; ZRC=$?
if [ "$ZRC" -ne 0 ]; then echo "MANIFEST BLIND find -print0 rc=$ZRC"; exit 2; fi
LC_ALL=C sort -z < "$MANDIR/z" > "$MANDIR/zs"; ZSRC=$?
if [ "$ZSRC" -ne 0 ]; then echo "MANIFEST BLIND sort -z rc=$ZSRC"; exit 2; fi
xargs -0 -r sha256sum < "$MANDIR/zs"; XRC=$?
if [ "$XRC" -ne 0 ]; then echo "MANIFEST BLIND sha256sum rc=$XRC"; exit 2; fi
echo "MANIFEST-SHA-END"
echo "MANIFEST OK"
REOF
}

write_prog_import() { cat > "$1" <<'REOF'
# $1 = arm root  $2 = beet path  $3 = "real" | "pretend"
set -u
ROOT="$1"; BEET="$2"; MODE="$3"
if [ ! -s "$ROOT/overlay.yaml" ]; then echo "IMPORT BLIND overlay missing at '$ROOT/overlay.yaml'"; exit 2; fi
echo "IMPORT-BEGIN mode=$MODE"
IRC=0
if [ "$MODE" = "pretend" ]; then
  "$BEET" -c "$ROOT/overlay.yaml" import --pretend "$ROOT/src" 2>&1 || IRC=$?
else
  "$BEET" -c "$ROOT/overlay.yaml" import "$ROOT/src" 2>&1 || IRC=$?
fi
echo "IMPORT-END rc=$IRC"
REOF
}

write_prog_taghistory() { cat > "$1" <<'REOF'
# $1 = arm root  $2 = python path  $3 = the probe program text
set -u
ROOT="$1"; PY="$2"; PROG="$3"
# GC-08, and this is the worse of the two sites: the program is written with `>` and then
# EXECUTED on the next line, so the name it is written to is inside the trust boundary. A
# pre-placed symlink at a fixed name redirects the write; a pre-placed regular file the redirect
# cannot truncate leaves the PREVIOUS contents to be executed. The path is therefore minted by
# the container with mktemp (O_EXCL), and a mint that fails is a refusal - exit 2 is UNKNOWN,
# which the caller already treats as could-not-look and never as a pass. NO FALLBACK.
THPROG="$(mktemp /tmp/p6-taghist.XXXXXXXX 2>/dev/null)" || THPROG=""
if [ -z "$THPROG" ]; then
  echo "TAGHIST BLIND could not mint a program path with mktemp - refusing to write-then-execute a fixed name in a world-writable /tmp"
  exit 2
fi
# R3-09, same reasoning as the manifest trap above and stated once there: an exit trap does not run
# on an uncaught SIGTERM, and both programs arrive through a `timeout`-bounded `docker exec`, so the
# narrow list would have leaked a minted name on a routine bound expiry. The SIGKILL residual and
# the refusal to sweep unminted names are recorded at that site.
# R3-10, likewise the same predicate and stated once above: prefix, then a remainder that must be
# non-empty and free of any byte outside [A-Za-z0-9._-] - a class that excludes `/`, which the
# prefix-only shape it replaces did not. GC-02 carries the identical rule in
# scripts/phase06-oracle.sh. Latent here too: THPROG is only ever mktemp output.
trap 'case "${THPROG:-}" in
        /tmp/p6-taghist.*) case "${THPROG#/tmp/p6-taghist.}" in ""|*[!A-Za-z0-9._-]*) : ;; *) rm -f "$THPROG" ;; esac ;;
      esac' EXIT INT TERM HUP
printf '%s\n' "$PROG" > "$THPROG"
"$PY" "$THPROG" "$ROOT/state.pickle" 2>&1
PRC=$?
echo "PROBE-RC $PRC"
SH="$(sha256sum "$ROOT/state.pickle" 2>/dev/null)" || SH="(state file absent or unhashable)"
echo "STATEFILE-SHA $SH"
REOF
}

write_prog_realstate() { cat > "$1" <<'REOF'
# $1 = real library.db  $2 = real state.pickle
set -u
L="$1"; S="$2"
for F in "$L" "$S"; do
  if [ ! -f "$F" ]; then echo "REALSTATE BLIND '$F' is not a regular file"; exit 2; fi
  if [ ! -r "$F" ]; then echo "REALSTATE BLIND '$F' is not readable"; exit 2; fi
done
OUT="$(sha256sum "$L" "$S")"; RRC=$?
if [ "$RRC" -ne 0 ]; then echo "REALSTATE BLIND sha256sum rc=$RRC"; exit 2; fi
printf '%s\n' "$OUT"
echo "REALSTATE-MTIMES"
LC_ALL=C find "$L" "$S" -maxdepth 0 -printf '%p\t%s\t%T@\n'
echo "REALSTATE OK"
REOF
}

write_prog_newer() { cat > "$1" <<'REOF'
# $1 = arm root  $2 = source folder
set -u
ROOT="$1"; SRC="$2"
if [ ! -f "$ROOT.stamp" ]; then echo "NEWER BLIND the stamp '$ROOT.stamp' is gone, so -newer has no reference"; exit 2; fi
if [ ! -d "$SRC" ]; then echo "NEWER BLIND '$SRC' is not a directory"; exit 2; fi
N="$(find "$SRC" -newer "$ROOT.stamp" -type f 2>/dev/null)"; NRC=$?
if [ "$NRC" -ne 0 ]; then echo "NEWER BLIND find rc=$NRC"; exit 2; fi
if [ -z "$N" ]; then echo "NEWER CLEAN 0 files under the rw downloads mount are newer than the stamp"; else
  echo "NEWER DIRTY the arm wrote to the source tree:"; printf '%s\n' "$N"
fi
echo "NEWER OK"
REOF
}

write_prog_cleanup() { cat > "$1" <<'REOF'
# $1,$2 = the two throwaway roots
set -u
for ROOT in "$1" "$2"; do
  case "$ROOT" in /tmp/p6a|/tmp/p6b) : ;; *) echo "CLEANUP REFUSED '$ROOT' is not a throwaway root"; exit 3 ;; esac
  rm -rf "$ROOT" "$ROOT.stamp"
  if [ -e "$ROOT" ]; then echo "CLEANUP FAILED '$ROOT' still exists"; exit 1; fi
  if [ -e "$ROOT.stamp" ]; then echo "CLEANUP FAILED '$ROOT.stamp' still exists"; exit 1; fi
  echo "CLEANUP GONE $ROOT and $ROOT.stamp"
done
echo "CLEANUP OK"
REOF
}

# --- D-29 layer 3 ------------------------------------------------------------------------------
REAL_LIB_SHA=""; REAL_STATE_SHA=""
sample_real_state() { # writes $1 as the capture label; sets REAL_LIB_SHA / REAL_STATE_SHA
  local label="$1" prog=""
  prog="$OUT_DIR/prog.realstate.sh"
  write_prog_realstate "$prog"
  RE_OUT="$OUT_DIR/realstate.$label.out"; RE_ERR="$OUT_DIR/realstate.$label.err"
  remote_exec "$prog" "$REAL_LIB" "$REAL_STATE"
  REAL_LIB_SHA=""; REAL_STATE_SHA=""
  if [ "$RE_RC" -ne 0 ]; then return 2; fi
  REAL_LIB_SHA="$(grep " $REAL_LIB\$" "$RE_OUT" | awk '{print $1}' || true)"
  REAL_STATE_SHA="$(grep " $REAL_STATE\$" "$RE_OUT" | awk '{print $1}' || true)"
  if [ -z "$REAL_LIB_SHA" ] || [ -z "$REAL_STATE_SHA" ]; then return 2; fi
  return 0
}

assert_real_state() { # $1 = label; 0 = unchanged, 1 = MOVED, 2 = could not look
  local label="$1" rc=0
  sample_real_state "$label" || rc=$?
  if [ "$rc" -ne 0 ]; then
    blind "D-29 layer 3 ($label): could not sample the real library.db / state.pickle (rc=$RE_RC)"
    bad "  This is UNKNOWN, not green - the unchanged claim is UNPROVEN, which is not the same as false."
    sed 's/^/         /' "$RE_ERR" 2>/dev/null || true
    return 2
  fi
  say "  $label  library.db   $REAL_LIB_SHA"
  say "  $label  state.pickle $REAL_STATE_SHA"
  if [ "$REAL_LIB_SHA" = "$BASELINE_LIB_SHA256" ] && [ "$REAL_STATE_SHA" = "$BASELINE_STATE_SHA256" ]; then
    ok "D-29 layer 3 ($label): both identical to the named 06-04 post-first-start baseline"
    return 0
  fi
  bad "D-29 layer 3 ($label): the real state MOVED from the 06-04 baseline"
  [ "$REAL_LIB_SHA" = "$BASELINE_LIB_SHA256" ] || bad "  library.db expected $BASELINE_LIB_SHA256"
  # The backticks around -l must stay escaped: inside a double-quoted string they are command
  # substitution, and this message is the D-29 layer-3 violation branch — the one place the text
  # has to survive intact. Unescaped, the shell tried to RUN `-l`, printed "-l: command not found"
  # to stderr, and dropped the flag from the message. Found by shellcheck SC2215, fixed 2026-09-21.
  [ "$REAL_STATE_SHA" = "$BASELINE_STATE_SHA256" ] || bad "  state.pickle expected $BASELINE_STATE_SHA256 - \`-l\` does not redirect statefile, so an overlay without it poisons this file"
  return 1
}

# --- One arm ----------------------------------------------------------------------------------
# --- The arm verdict, and the RED-vs-UNKNOWN precedence ---------------------------------------
# THE TWO CONDITIONS ARE NOT MUTUALLY EXCLUSIVE. A single arm can both measure a failure and
# have an instrument that could not look, so which one is consulted first is a DECISION, not an
# accident of ordering - which is why it is factored out here, stated in the EXIT CODES block
# and driven by `--self-test` rather than left implicit in run_arm's tail.
#
# THE DECISION: a blind instrument OUTRANKS a measured red. [IN-08, plan 06-20] Reason: this
# estate's standing rule is that "could not look" is kept distinct from "nothing is wrong" and
# is never folded into another verdict; reporting a measured red while an instrument was blind
# asserts a cause the run did not establish. The sibling instrument written in this same phase,
# scripts/phase06-oracle.sh, consults its UNKNOWN counter first for the same reason. Before this
# plan the two disagreed, so no reader could infer the convention from either.
#
# Neither condition's MEANING nor its exit code changed here - only which is consulted first.
arm_verdict() { # $1 = failed (0/1)  $2 = unknown (0/1)  $3 = arm label; returns 2 / 1 / 0
  local failed="$1" unknown="$2" arm="${3:-?}"
  if [ "$unknown" -ne 0 ]; then
    say "  ARM $arm: UNKNOWN (an instrument could not look - not a pass; this OUTRANKS a measured red in the same run)"
    return 2
  fi
  if [ "$failed" -ne 0 ]; then
    say "  ARM $arm: FAIL (a measured negative - record it, do not retune)"
    return 1
  fi
  return 0
}

run_arm() { # $1 = a|b
  local arm="$1" root="" want_hist="" want_offer="" prog="" rc=0 failed=0 unknown=0
  local sha_local="" sha_remote="" mode=""

  case "$arm" in
    a) root="$ARM_A_ROOT"; want_hist="populated"; want_offer="no" ;;
    b) root="$ARM_B_ROOT"; want_hist="empty";     want_offer="yes" ;;
    *) bad "unknown arm '$arm' - expected a or b"; return 3 ;;
  esac

  say ""
  say "== phase06-incremental-control.sh --arm $arm =="
  rule
  say "  root                     $root"
  say "  source folder            $SRC_FOLDER"
  say "  expected taghistory      $want_hist"
  say "  expected re-offer        $want_offer"
  say "  REMOTE_TIMEOUT           ${REMOTE_TIMEOUT}s"
  say ""

  # -- preflight 1: the fence on the override --------------------------------------------------
  if ! fence_eval "$SRC_FOLDER" "$SRC_ALLOW_PREFIX"; then
    bad "REFUSED: $FENCE_WHY"
    return 3
  fi
  ok "source fence: '$SRC_FOLDER' is under '$SRC_ALLOW_PREFIX' with no '..' component"

  # -- preflight 2: the overlays are exactly one key apart -------------------------------------
  emit_overlay "$ARM_A_ROOT" no  > "$OUT_DIR/overlay.a.yaml"
  emit_overlay "$ARM_B_ROOT" yes > "$OUT_DIR/overlay.b.yaml"
  rc=0; assert_one_key_apart "$OUT_DIR/overlay.a.yaml" "$OUT_DIR/overlay.b.yaml" || rc=$?
  case "$rc" in
    0) ok "overlay control: exactly one key apart (incremental_skip_later), byte-identical otherwise" ;;
    1) bad "REFUSED: $ONEKEY_WHY"; return 3 ;;
    *) blind "REFUSED: could not compare the overlays - $ONEKEY_WHY"; return 3 ;;
  esac

  # -- step 1: prepare (refuse dirty dest, copy never move, seed the state file, stamp) --------
  prog="$OUT_DIR/prog.prepare.sh"; write_prog_prepare "$prog"
  RE_OUT="$OUT_DIR/$arm.prepare.out"; RE_ERR="$OUT_DIR/$arm.prepare.err"
  remote_exec "$prog" "$root" "$SRC_FOLDER" "$BEET" "$PY"
  sed 's/^/    /' "$RE_OUT" || true
  if [ "$RE_RC" -eq 3 ]; then bad "step 1 REFUSED (rc=3) - nothing was measured"; return 3; fi
  if [ "$RE_RC" -ne 0 ]; then
    blind "step 1 could not prepare (rc=$RE_RC). This is UNKNOWN, not green."
    sed 's/^/    /' "$RE_ERR" 2>/dev/null || true
    return 2
  fi
  ok "step 1: destination clean, source COPIED (never moved), state file seeded empty, stamp taken"

  # -- deliver the overlay and hash both sides -------------------------------------------------
  sha_local="$(local_sha256 "$OUT_DIR/overlay.$arm.yaml")" || { blind "no local sha256 tool"; return 2; }
  RE_RC=0
  ssh $SSH_OPTS "$LXC_HOST" "timeout $REMOTE_TIMEOUT docker exec -i -u beetle $CONTAINER sh -c $(shq "cat > $root/overlay.yaml && sha256sum $root/overlay.yaml")" < "$OUT_DIR/overlay.$arm.yaml" > "$OUT_DIR/$arm.overlay.out" 2> "$OUT_DIR/$arm.overlay.err" || RE_RC=$?
  if [ "$RE_RC" -ne 0 ]; then blind "could not deliver the overlay (rc=$RE_RC). UNKNOWN, not green."; return 2; fi
  sha_remote="$(awk '{print $1}' "$OUT_DIR/$arm.overlay.out" | head -n 1)"
  if [ "$sha_local" != "$sha_remote" ]; then
    bad "the delivered overlay does not match what was generated: local $sha_local vs remote $sha_remote"
    return 1
  fi
  ok "overlay delivered to $root/overlay.yaml, sha256 matched on both sides ($sha_local)"

  # -- D-29 sample, before this arm ------------------------------------------------------------
  rc=0; assert_real_state "$arm.before" || rc=$?
  [ "$rc" -eq 1 ] && failed=1
  [ "$rc" -eq 2 ] && unknown=1

  # -- source manifest, before -----------------------------------------------------------------
  prog="$OUT_DIR/prog.manifest.sh"; write_prog_manifest "$prog"
  RE_OUT="$OUT_DIR/$arm.srcman.before.out"; RE_ERR="$OUT_DIR/$arm.srcman.before.err"
  remote_exec "$prog" "$SRC_FOLDER"
  if [ "$RE_RC" -ne 0 ]; then blind "source manifest (before) could not be taken (rc=$RE_RC). UNKNOWN, not green."; unknown=1; fi

  # -- step 2: the real, in-place import that must SKIP ----------------------------------------
  prog="$OUT_DIR/prog.import.sh"; write_prog_import "$prog"
  RE_OUT="$OUT_DIR/$arm.import1.out"; RE_ERR="$OUT_DIR/$arm.import1.err"
  remote_exec "$prog" "$root" "$BEET" "real"
  say ""
  say "  --- step 2: import run 1 (real, in-place; copy:no move:no write:no) ---"
  sed 's/^/    /' "$RE_OUT" || true
  if [ "$RE_RC" -ne 0 ]; then
    blind "step 2's remote call failed (rc=$RE_RC). UNKNOWN, not green."
    sed 's/^/    /' "$RE_ERR" 2>/dev/null || true
    return 2
  fi
  if grep -q 'Skipping\.' "$RE_OUT"; then
    ok "step 2: beets took the quiet_fallback and SKIPPED, so finalize() ran with task.skip true"
  else
    bad "step 2: no 'Skipping.' in the transcript - the task was not skipped, so this arm measures nothing about the skip path"
    failed=1
  fi

  # -- step 3: taghistory, out of the pickle ---------------------------------------------------
  prog="$OUT_DIR/prog.taghistory.sh"; write_prog_taghistory "$prog"
  RE_OUT="$OUT_DIR/$arm.taghistory.out"; RE_ERR="$OUT_DIR/$arm.taghistory.err"
  remote_exec "$prog" "$root" "$PY" "$TAGHISTORY_PROBE_PY"
  say ""
  say "  --- step 3: taghistory read out of $root/state.pickle ---"
  sed 's/^/    /' "$RE_OUT" || true
  if [ "$RE_RC" -ne 0 ]; then
    blind "step 3's remote call failed (rc=$RE_RC). UNKNOWN, not green."
    unknown=1
  else
    classify_taghistory "$(cat "$RE_OUT")"
    say "  classified: $TAGHIST_CLASS"
    case "$TAGHIST_CLASS" in
      "$want_hist") ok "step 3: taghistory is '$TAGHIST_CLASS', which is arm $arm's EXPECTED outcome" ;;
      unreadable|absent)
        blind "step 3: taghistory is '$TAGHIST_CLASS' - $TAGHIST_DETAIL"
        bad "  This is UNKNOWN, not green. An unreadable or absent pickle is NOT 'empty'."
        unknown=1 ;;
      *)
        bad "step 3: taghistory is '$TAGHIST_CLASS', expected '$want_hist' - $TAGHIST_DETAIL"
        failed=1 ;;
    esac
  fi

  # -- step 4: is the folder still OFFERED? (--pretend, and only for this) ---------------------
  prog="$OUT_DIR/prog.import.sh"
  RE_OUT="$OUT_DIR/$arm.import2.out"; RE_ERR="$OUT_DIR/$arm.import2.err"
  remote_exec "$prog" "$root" "$BEET" "pretend"
  say ""
  say "  --- step 4: re-run with --pretend (offered/not-offered only; NEVER a tree oracle, D-33) ---"
  sed 's/^/    /' "$RE_OUT" || true
  if [ "$RE_RC" -ne 0 ]; then
    blind "step 4's remote call failed (rc=$RE_RC). UNKNOWN, not green."
    unknown=1
  else
    mode="$(classify_reoffer "$RE_OUT")"
    say "  classified: $mode"
    case "$want_offer:$mode" in
      no:not-offered)
        ok "step 4: the folder is NOT re-offered and beets reports it skipped - the trap FIRED (permanently marked done)" ;;
      yes:offered)
        ok "step 4: the folder IS re-offered - the trap is DEFEATED by incremental_skip_later" ;;
      *:indeterminate|*:contradictory)
        blind "step 4: the transcript is $mode - neither a 'Skipped N paths.' line alone nor an 'Album: ' line alone"
        bad "  This is UNKNOWN, not green."
        unknown=1 ;;
      *)
        bad "step 4: the folder was '$mode', expected '$want_offer' re-offer. THIS IS THE RESULT - record it and stop; do not adjust the overlays until the expected answer appears."
        failed=1 ;;
    esac
  fi

  # -- step 5: source untouched, and the real state unmoved ------------------------------------
  prog="$OUT_DIR/prog.manifest.sh"
  RE_OUT="$OUT_DIR/$arm.srcman.after.out"; RE_ERR="$OUT_DIR/$arm.srcman.after.err"
  remote_exec "$prog" "$SRC_FOLDER"
  say ""
  say "  --- step 5: the rw downloads mount was not written ---"
  if [ "$RE_RC" -ne 0 ]; then
    blind "source manifest (after) could not be taken (rc=$RE_RC). UNKNOWN, not green."
    unknown=1
  else
    rc=0; manifest_compare "$OUT_DIR/$arm.srcman.before.out" "$OUT_DIR/$arm.srcman.after.out" || rc=$?
    case "$rc" in
      0) ok "source manifest (path+size+mtime+sha256): IDENTICAL before and after this arm" ;;
      1) bad "source manifest CHANGED - the arm wrote to /mnt/tank/downloads despite write:no:"
         printf '%s\n' "$DIFF_OUT" | head -n 20 | sed 's/^/         /'
         failed=1 ;;
      *) blind "source manifest COULD NOT COMPARE: $DIFF_WHY"
         bad "  This is UNKNOWN, not green."
         unknown=1 ;;
    esac
  fi

  prog="$OUT_DIR/prog.newer.sh"; write_prog_newer "$prog"
  RE_OUT="$OUT_DIR/$arm.newer.out"; RE_ERR="$OUT_DIR/$arm.newer.err"
  remote_exec "$prog" "$root" "$SRC_FOLDER"
  sed 's/^/    /' "$RE_OUT" || true
  if [ "$RE_RC" -ne 0 ]; then
    blind "the -newer instrument could not look (rc=$RE_RC). UNKNOWN, not green."
    unknown=1
  elif grep -q '^NEWER DIRTY' "$RE_OUT"; then
    bad "the -newer instrument found writes under the source tree"
    failed=1
  fi

  say ""
  rc=0; assert_real_state "$arm.after" || rc=$?
  [ "$rc" -eq 1 ] && failed=1
  [ "$rc" -eq 2 ] && unknown=1

  say ""
  rule
  rc=0; arm_verdict "$failed" "$unknown" "$arm" || rc=$?
  if [ "$rc" -ne 0 ]; then return "$rc"; fi
  say "  ARM $arm: PASS - taghistory $want_hist, re-offer $want_offer, source untouched, real state unmoved"
  return 0
}

# --- --cleanup --------------------------------------------------------------------------------
run_cleanup() {
  local prog="$OUT_DIR/prog.cleanup.sh"
  say ""
  say "== --cleanup: remove both throwaway trees and assert they are GONE =="
  rule
  write_prog_cleanup "$prog"
  RE_OUT="$OUT_DIR/cleanup.out"; RE_ERR="$OUT_DIR/cleanup.err"
  remote_exec "$prog" "$ARM_A_ROOT" "$ARM_B_ROOT"
  sed 's/^/    /' "$RE_OUT" || true
  if [ "$RE_RC" -eq 3 ]; then bad "cleanup REFUSED"; return 3; fi
  if [ "$RE_RC" -ne 0 ]; then
    blind "cleanup could not complete (rc=$RE_RC). UNKNOWN, not green."
    sed 's/^/    /' "$RE_ERR" 2>/dev/null || true
    return 2
  fi
  ok "both throwaway trees and both stamps are gone"
  return 0
}

# --- --self-test ------------------------------------------------------------------------------
# This repo's substitute for a unit-test framework. Needs no ssh and no docker, writes only under
# a temp directory, and DRIVES THE RED BRANCHES - a fail-closed instrument that is never seen to
# fail closed is an assumption, not a control.
ST_FAIL=0
st_expect() { # $1 = label  $2 = expected  $3 = got
  if [ "$2" = "$3" ]; then ok "$3 (expected): $1"; else bad "REGRESSION: expected '$2', got '$3': $1"; ST_FAIL=$((ST_FAIL + 1)); fi
}

self_test() {
  local td="" py="" got="" rc=0 f="" verdict="" vf="" vu="" expect="" desc=""
  td="$(mktemp -d "${TMPDIR:-/tmp}/p6-08-selftest-XXXXXX")"

  say ""
  say "== --self-test 1/7: the taghistory classifier, over REAL pickles =="
  rule
  py=""
  for f in /venv/bin/python python3 python; do
    if command -v "$f" >/dev/null 2>&1; then py="$f"; break; fi
  done
  printf '%s\n' "$TAGHISTORY_PROBE_PY" > "$td/probe.py"
  if [ -n "$py" ]; then
    say "  driving the SAME probe source the container runs, with $py"
    "$py" - "$td/pop.pickle" "$td/empty.pickle" <<'PYEOF'
import pickle, sys
with open(sys.argv[1], "wb") as f:
    pickle.dump({"tagprogress": {}, "taghistory": {(b"/tmp/p6a/src",)}}, f)
with open(sys.argv[2], "wb") as f:
    pickle.dump({"tagprogress": {}, "taghistory": set()}, f)
PYEOF
    printf 'this is not a pickle at all\n' > "$td/garbage.pickle"
    printf 'nonsense' > "$td/notadict.pickle"
    "$py" - "$td/notadict.pickle" <<'PYEOF'
import pickle, sys
with open(sys.argv[1], "wb") as f:
    pickle.dump(["a", "list", "not", "a", "dict"], f)
PYEOF
    "$py" - "$td/nokey.pickle" <<'PYEOF'
import pickle, sys
with open(sys.argv[1], "wb") as f:
    pickle.dump({"tagprogress": {}}, f)
PYEOF
    classify_taghistory "$("$py" "$td/probe.py" "$td/pop.pickle" 2>&1)";      st_expect "a populated taghistory"          "populated"  "$TAGHIST_CLASS"
    classify_taghistory "$("$py" "$td/probe.py" "$td/empty.pickle" 2>&1)";    st_expect "a readable EMPTY taghistory"    "empty"      "$TAGHIST_CLASS"
    classify_taghistory "$("$py" "$td/probe.py" "$td/absent.pickle" 2>&1)";   st_expect "an ABSENT state file"           "absent"     "$TAGHIST_CLASS"
    classify_taghistory "$("$py" "$td/probe.py" "$td/garbage.pickle" 2>&1)";  st_expect "an unpicklable state file"      "unreadable" "$TAGHIST_CLASS"
    classify_taghistory "$("$py" "$td/probe.py" "$td/notadict.pickle" 2>&1)"; st_expect "a pickle that is not a dict"    "unreadable" "$TAGHIST_CLASS"
    classify_taghistory "$("$py" "$td/probe.py" "$td/nokey.pickle" 2>&1)";    st_expect "a dict with no taghistory key"  "unreadable" "$TAGHIST_CLASS"
  else
    warn "no python found locally; driving the classifier over synthetic marker lines instead."
    warn "The probe source itself is then UNEXERCISED here - that is a weaker test, and it is said so."
    classify_taghistory "TAGHISTORY POPULATED 1 [(b'/tmp/p6a/src',)]"; st_expect "synthetic populated" "populated"  "$TAGHIST_CLASS"
    classify_taghistory "TAGHISTORY EMPTY 0";                          st_expect "synthetic empty"     "empty"      "$TAGHIST_CLASS"
    classify_taghistory "TAGHISTORY ABSENT /nope";                     st_expect "synthetic absent"    "absent"     "$TAGHIST_CLASS"
    classify_taghistory "TAGHISTORY UNREADABLE boom";                  st_expect "synthetic unreadable" "unreadable" "$TAGHIST_CLASS"
  fi
  classify_taghistory "beets said nothing at all"; st_expect "no marker line at all (python missing, truncated transport)" "unreadable" "$TAGHIST_CLASS"

  say ""
  say "== --self-test 2/7: the one-key overlay refusal =="
  rule
  emit_overlay "$ARM_A_ROOT" no  > "$td/ok.a.yaml"
  emit_overlay "$ARM_B_ROOT" yes > "$td/ok.b.yaml"
  rc=0; assert_one_key_apart "$td/ok.a.yaml" "$td/ok.b.yaml" || rc=$?
  got="accept"; [ "$rc" -eq 0 ] || got="refuse"
  st_expect "the real overlay pair (one key apart)" "accept" "$got"

  # two keys apart
  sed 's/^  write: no/  write: yes/' "$td/ok.b.yaml" > "$td/two.b.yaml"
  rc=0; assert_one_key_apart "$td/ok.a.yaml" "$td/two.b.yaml" || rc=$?
  got="accept"; [ "$rc" -eq 0 ] || got="refuse"
  st_expect "a pair differing in TWO keys (write flipped as well)" "refuse" "$got"
  [ "$got" = "refuse" ] && say "        reason: $ONEKEY_WHY"

  # one key plus a whitespace-only change: the diff is still two lines, so a line count alone
  # would pass it. The canonicalise-and-compare half is what catches it.
  sed 's/^  quiet: yes/  quiet: yes /' "$td/ok.b.yaml" > "$td/ws.b.yaml"
  rc=0; assert_one_key_apart "$td/ok.a.yaml" "$td/ws.b.yaml" || rc=$?
  got="accept"; [ "$rc" -eq 0 ] || got="refuse"
  st_expect "a pair with a stray trailing-whitespace change" "refuse" "$got"
  [ "$got" = "refuse" ] && say "        reason: $ONEKEY_WHY"

  # identical: no variable, so no control
  emit_overlay "$ARM_B_ROOT" no > "$td/same.b.yaml"
  rc=0; assert_one_key_apart "$td/ok.a.yaml" "$td/same.b.yaml" || rc=$?
  got="accept"; [ "$rc" -eq 0 ] || got="refuse"
  st_expect "a pair with NO differing key (identical once canonicalised)" "refuse" "$got"
  [ "$got" = "refuse" ] && say "        reason: $ONEKEY_WHY"

  rc=0; assert_one_key_apart "$td/ok.a.yaml" "$td/does-not-exist.yaml" || rc=$?
  got="accept"; [ "$rc" -eq 2 ] && got="couldnotlook"
  st_expect "a missing overlay file is could-not-look, not accept" "couldnotlook" "$got"

  say ""
  say "== --self-test 3/7: the dirty-destination and root refusals, driven locally =="
  rule
  # The refusal lives in the remote program, so drive that program's text with the local sh.
  write_prog_prepare "$td/prep.sh"
  rc=0; sh "$td/prep.sh" "/tmp/not-a-throwaway-root" "$SRC_FOLDER" "$BEET" "$PY" >"$td/prep1.out" 2>&1 || rc=$?
  got="accept"; [ "$rc" -eq 3 ] && got="refuse"
  st_expect "a root outside the two throwaway roots" "refuse" "$got"
  [ "$got" = "refuse" ] && sed 's/^/        /' "$td/prep1.out"

  # The DIRTY-DESTINATION refusal. Driven for real, against a real non-empty directory at the
  # real constant root - on the workstation, where /tmp/p6a is meaningless and is removed again
  # immediately. A refusal that is only reasoned about is an assumption.
  if [ -e "$ARM_A_ROOT" ]; then
    warn "skipping the dirty-destination case: '$ARM_A_ROOT' already exists on THIS machine"
    warn "and the self-test refuses to touch a tree it did not create. That is a gap, and it is said so."
    ST_FAIL=$((ST_FAIL + 1))
  else
    mkdir -p "$ARM_A_ROOT/left-over-from-a-previous-run"
    rc=0; sh "$td/prep.sh" "$ARM_A_ROOT" "$SRC_FOLDER" "$BEET" "$PY" >"$td/prep2.out" 2>&1 || rc=$?
    got="accept"; [ "$rc" -eq 3 ] && got="refuse"
    st_expect "a DIRTY destination (root holds a leftover entry)" "refuse" "$got"
    sed 's/^/        /' "$td/prep2.out"
    rm -rf "$ARM_A_ROOT"
  fi

  # A clean destination with an unreachable source must be BLIND (2), never an accept: the
  # container's /downloads does not exist on the workstation, so this is the could-not-look path.
  if [ -e "$ARM_B_ROOT" ]; then
    warn "skipping the clean-destination blind case: '$ARM_B_ROOT' already exists on THIS machine"
    ST_FAIL=$((ST_FAIL + 1))
  else
    rc=0; sh "$td/prep.sh" "$ARM_B_ROOT" "$SRC_FOLDER" "$BEET" "$PY" >"$td/prep3.out" 2>&1 || rc=$?
    got="accept"; [ "$rc" -eq 2 ] && got="couldnotlook"; [ "$rc" -eq 3 ] && got="refuse"
    st_expect "a clean destination with an unreachable source" "couldnotlook" "$got"
    sed 's/^/        /' "$td/prep3.out"
    rm -rf "$ARM_B_ROOT"
  fi

  say ""
  say "== --self-test 4/7: the three-outcome manifest comparison =="
  rule
  printf 'a\tb\tc\n' > "$td/m1"; printf 'a\tb\tc\n' > "$td/m2"; printf 'a\tb\tX\n' > "$td/m3"; : > "$td/m4"
  rc=0; manifest_compare "$td/m1" "$td/m2" || rc=$?
  got="identical"; [ "$rc" -eq 1 ] && got="differs"; [ "$rc" -ge 2 ] && got="couldnotlook"
  st_expect "two identical manifests" "identical" "$got"
  rc=0; manifest_compare "$td/m1" "$td/m3" || rc=$?
  got="identical"; [ "$rc" -eq 1 ] && got="differs"; [ "$rc" -ge 2 ] && got="couldnotlook"
  st_expect "two differing manifests" "differs" "$got"
  rc=0; manifest_compare "$td/m1" "$td/missing" || rc=$?
  got="identical"; [ "$rc" -eq 1 ] && got="differs"; [ "$rc" -ge 2 ] && got="couldnotlook"
  st_expect "a manifest that was never captured" "couldnotlook" "$got"
  rc=0; manifest_compare "$td/m4" "$td/m4" || rc=$?
  got="identical"; [ "$rc" -eq 1 ] && got="differs"; [ "$rc" -ge 2 ] && got="couldnotlook"
  st_expect "two EMPTY manifests (must not pass vacuously)" "couldnotlook" "$got"

  say ""
  say "== --self-test 5/7: the source fence =="
  rule
  while IFS='|' read -r expect given desc; do
    case "${expect:-}" in ""|"#"*) continue ;; esac
    rc=0; fence_eval "$given" "$SRC_ALLOW_PREFIX" || rc=1
    got="accept"; [ "$rc" -eq 0 ] || got="refuse"
    st_expect "$desc" "$expect" "$got"
    [ "$got" = "refuse" ] && say "        reason: $FENCE_WHY"
  done <<'CASES'
accept|/downloads/complete/nzb/music/Some Folder|the legitimate shape of SRC_FOLDER
refuse|/downloads/complete/nzb/../../../etc|a `..` walk out of the allow-prefix
refuse|/mnt/tank/media/Music/Abba|the library itself - never a source for a throwaway import
refuse|relative/path|a relative path
refuse|/downloads/incomplete/music|inside /downloads but outside the allow-prefix
CASES

  say ""
  say "== --self-test 6/7: the step-4 re-offer classifier, over synthetic transcripts =="
  rule
  # IN-10. The PAIR is the point: widening the path count must classify the multi-album case
  # WITHOUT changing the single-album answer. A widening proven on only the new case is how a
  # widening becomes a regression.
  # The counts are printf ARGUMENTS, never spelled into the fixture text, so the guard that
  # forbids a pinned count anywhere in this file keeps its teeth: the only place a count can be
  # written literally is a match pattern, which is precisely what IN-10 forbids.
  for f in 1 2 17; do
    printf 'Skipped %s paths.\n' "$f" > "$td/reoffer.skip.$f"
    st_expect "a skipped-path count of $f" "not-offered" "$(classify_reoffer "$td/reoffer.skip.$f")"
  done
  printf 'Album: /tmp/p6b/src\n  01.mp3\n'        > "$td/reoffer.album"
  printf 'Skipped %s paths.\nAlbum: /tmp/p6b/src\n' 2 > "$td/reoffer.both"
  printf 'beets said something else entirely\n'   > "$td/reoffer.junk"
  : > "$td/reoffer.empty"
  st_expect "an Album: line and no skip"                           "offered"       "$(classify_reoffer "$td/reoffer.album")"
  st_expect "BOTH markers at once (must not resolve to either)"    "contradictory" "$(classify_reoffer "$td/reoffer.both")"
  st_expect "an unrecognised transcript (still falls through)"     "indeterminate" "$(classify_reoffer "$td/reoffer.junk")"
  st_expect "an EMPTY transcript (must not pass vacuously)"        "indeterminate" "$(classify_reoffer "$td/reoffer.empty")"

  say ""
  say "== --self-test 7/7: the RED-vs-UNKNOWN precedence (a blind instrument outranks a measured red) =="
  rule
  # IN-08. Two cases at minimum, because one proves only that a branch exists; the full 2x2 is
  # cheap and shows the ordering is a decision over two non-exclusive conditions.
  # $1 = failed  $2 = unknown
  while IFS='|' read -r vf vu expect desc; do
    case "${vf:-}" in ""|"#"*) continue ;; esac
    rc=0; got="$(arm_verdict "$vf" "$vu" "precedence-case" 2>&1)" || rc=$?
    case "$rc" in 0) verdict="pass" ;; 1) verdict="fail" ;; 2) verdict="unknown" ;; *) verdict="rc$rc" ;; esac
    st_expect "$desc" "$expect" "$verdict"
    if [ -n "$got" ]; then say "        verdict line:$got"; else say "        (silent - a pass prints its own line in run_arm)"; fi
  done <<'PRECEDENCE'
1|1|unknown|a measured failure AND a blind read in the same run - the BLIND verdict must win
1|0|fail|a measured failure with NO blind read - the red must stand
0|1|unknown|a blind read with no measured failure
0|0|pass|neither - the arm passes
PRECEDENCE

  rm -rf "$td"
  say ""
  rule
  if [ "$ST_FAIL" -ne 0 ]; then say "  --self-test: $ST_FAIL regression(s)"; return 1; fi
  say "  --self-test: all branches behaved as expected (including every refusal and every blind case)"
  return 0
}

# --- Argument parsing -------------------------------------------------------------------------
# A USAGE ERROR IS NOT A MEASUREMENT. [IN-05, plan 06-20] `--arm` used to be
# `ARM="${2:-}"; shift 2`, and with one argument left `shift 2` returns non-zero, so `set -e`
# terminated the script with status 1 - THE CODE RESERVED FOR "the arm produced the OPPOSITE
# outcome" - and printed nothing at all. A mis-typed invocation then read as a measured negative.
# The defect is in the `shift 2` IDIOM, so no flag in this dispatch uses it: each shifts ONCE
# unconditionally and takes a value only if one is actually present. Usage errors exit 3, loudly.
usage_error() { # $1 = what was wrong; exits 3 (REFUSED/usage) per the EXIT CODES block
  printf 'phase06-incremental-control.sh: %s\n\n' "$1" >&2
  print_header >&2
  exit 3
}

MODE=""
ARM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --arm)
      MODE="arm"; shift
      if [ $# -gt 0 ]; then ARM="$1"; shift; else ARM=""; fi
      case "$ARM" in
        a|b) : ;;
        "") usage_error "--arm requires a value; the legal values are 'a' and 'b'" ;;
        *)  usage_error "--arm: '$ARM' is not a legal arm; the legal values are 'a' and 'b'" ;;
      esac
      ;;
    --baseline) MODE="baseline"; shift ;;
    --cleanup) MODE="cleanup"; shift ;;
    --self-test) MODE="selftest"; shift ;;
    --help|-h) print_header; exit 0 ;;
    *) printf 'unknown argument: %s\n\n' "$1" >&2; print_header >&2; exit 3 ;;
  esac
done

if [ -z "$MODE" ]; then print_header; exit 3; fi

if [ "$MODE" = "selftest" ]; then
  self_test
  exit $?
fi

mkdir -p "$OUT_DIR"
say "captures: $OUT_DIR"

case "$MODE" in
  baseline)
    say ""
    say "== --baseline: D-29 layer 3 sample of the REAL library.db and state.pickle =="
    rule
    RC=0; assert_real_state "adhoc" || RC=$?
    exit "$RC"
    ;;
  cleanup)
    run_cleanup
    exit $?
    ;;
  arm)
    run_arm "$ARM"
    exit $?
    ;;
esac
