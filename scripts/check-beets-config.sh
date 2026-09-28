#!/usr/bin/env bash
# check-beets-config.sh - Assert the EFFECTIVE beets config of the process that actually imports
# Usage: bash scripts/check-beets-config.sh [--baseline] [--self-test]
#
# Where it runs:
#   ON THE WORKSTATION, from the repo root. It is ssh-delegating, like
#   scripts/quick-health-check.sh and scripts/check-music-consumers.sh, because everything it
#   reads lives inside a container on LXC 100 (root@172.16.1.159) and each read is expressible
#   as one bounded remote command. Nothing is installed anywhere, and the ONE write this script
#   makes is named below rather than denied.
#
# READ-ONLY BY CONTRACT, WITH ONE NAMED EXCEPTION. Every remote invocation is a read - a `docker
# logs` fetch, a `docker exec` that dumps configuration, and a `sha256sum` - with exactly one
# exception: arm 2 TRUNCATES a zero-byte no-op overlay at a fixed path inside the container's
# /tmp (${OVERLAY}, below). It is truncated rather than created-if-absent, its emptiness is
# MEASURED before it is used rather than assumed, and nothing removes it afterwards. That single
# zero-byte file is the whole of what this script writes anywhere.
#
# No import runs and no library is modified. Stronger than that: every `beet` invocation here
# carries `-l ${THROWAWAY_DB}`, so the real /config/library.db is never OPENED either (D-04). The
# two pieces of beets state that CAN move under a careless read - /config/library.db and
# /config/state.pickle - are still hashed before and after and asserted unchanged (D-29 layer 3),
# which now CORROBORATES that redirect instead of carrying the whole claim on its own.
#
# --------------------------------------------------------------------------------------------
# WHY THIS SCRIPT EXISTS: "the effective config" is ambiguous, and the ambiguity deletes files
# --------------------------------------------------------------------------------------------
# beets-flask rc6's `BeetsFlaskConfig.commit_to_beets()` ends with
#
#     beets.config.set(self.to_dict(extra_fields=True))
#
# and `to_dict()` serialises the WHOLE `BeetsSchema` dataclass - defaults included - which
# confuse inserts at its HIGHEST priority. So a key the vendored config leaves silent is NOT
# beets' default; it is rc6's. Three of rc6's differ from beets', and one of the three is a
# delete: `import.duplicate_action` becomes the silent-removal value instead of `ask`,
# `match.medium_rec_thresh` becomes 0.10 instead of 0.25, and `directory` becomes a path that
# does not exist in this container.
#
# That injection happens ONLY inside the server process. `beet config -d` cannot see it. So the
# two available readings are not two views of one object - they are TWO ROUTES TO TWO DIFFERENT
# OBJECTS, and this script keeps them apart by name:
#
#   ARM 1  CONFIG_ROUTE=server-committed   AUTHORITATIVE. Read inside the container through
#                                          `get_config(commit_to_beets=True)` followed by
#                                          `beets.config.dump(full=True, redact=True)`. This is
#                                          the object that will actually import. EVERY ASSERTION
#                                          BELOW IS MADE AGAINST THIS ARM AND NO OTHER.
#   ARM 2  CONFIG_ROUTE_CLI=confuse        The CLI view: `beet -c <no-op overlay> config -d`,
#                                          plus `config -p -d` for the files it was assembled
#                                          from. RECORDED AND COMPARED, never asserted from.
#
# Differences between the arms are EXPECTED and are the finding, not the failure. What IS a
# failure: arm 1 unreadable, arm 1 blind (see the positive control), or any asserted key wrong
# in arm 1 - regardless of what arm 2 says about it.
#
# What it covers:
#   0. Toolchain preconditions                    harness
#   1. Readiness gate (the watchdog line)         T-06-34
#   1b. Inbox registration, newest line only      07-REVIEW WR7-05 (the D-21 / CR7-01 inbox set)
#   2. ARM 1 - the server-committed config        D-30 arm 1
#   3. ARM 2 - the CLI/confuse view               D-30 arm 2, redaction no-op (T-06-33)
#   4. Assertions, all read from ARM 1            CONF-01, CONF-02, CONF-05, SAFE-01, T-06-31
#      4b. OD-2: fetchart from Cover Art Archive, art_filename, preferred.media, the plugin set
#   5. The two-arm comparison, REPORTED           D-30
#   6. Summary
#
# EXIT-CODE CONVENTION (stated here, not inherited - the same reason check-music-freeze.sh:35-42
# states it): check-renovate.sh exits zero on nearly every finding and quick-health-check.sh
# never exits non-zero at all, so silence cannot be inherited safely.
#   default mode  - every red finding increments FAILURES and the script ends non-zero.
#   --baseline    - every finding is printed and the script always ends zero, so a before-state
#                   can be recorded while a config is still being brought to its target.
#   --self-test   - no ssh, no docker. FIFTEEN cases, THIRTEEN of which MUST go red (cases 1-7
#                   are described next; 5a/5b drive the OD-2 plugin-set and media reds; the six
#                   inbox-registration cases, added 2026-09-27 for WR7-05, are described at
#                   assert_inbox_registration), exiting non-zero unless every expectation is met.
#                   Eight drive the assertion function over synthetic dumps; the last of those
#                   (case 7) is deliberately larger than the
#                   64 KiB pipe buffer, because the GC-01 defect was invisible to every smaller
#                   case. The remaining one is a SOURCE assertion, because the assertion
#                   function is pure over a dump and cannot see an invocation flag - it requires
#                   the D-04 `-l` + `-c` contract of every `beet` call in this file and proves
#                   itself against a synthetic -c-only line. A control that can only pass is
#                   uninformative.
#
# ENV OVERRIDES - exactly one, in the ${VAR:-default} form so a grep can prove it exists. THE
# RECIPE, to run rather than to trust (converted from a bare assertion by plan 06-38's R4-05 audit):
#     /usr/bin/grep -c 'EXTRA_FORBIDDEN_SUBSTRINGS="${EXTRA_FORBIDDEN_SUBSTRINGS:[-]}"' \
#         scripts/check-beets-config.sh
# THE HYPHEN IS BRACKETED ON PURPOSE AND MUST STAY THAT WAY. `[-]` matches the real assignment,
# while this recipe line is NOT itself an occurrence - so writing the recipe in band does not
# perturb the number it asks you to measure. That is the same device the R3-05 block in
# scripts/quick-health-check.sh uses, and unbracketing it here would re-create the exact defect
# R4-05 exists to retire. Do NOT reach for the obvious `grep -c ':-'` instead: it also catches
# Python slices in the embedded extractor and an unrelated ${ver:-...} default, and answers with a
# number that has nothing to do with env overrides.
#     EXTRA_FORBIDDEN_SUBSTRINGS   colon-separated, APPENDED to a built-in list of substrings
#                                  that must not appear anywhere in arm 1's dump.
#   It is ADDITIVE: it can only add failures, never remove one. There is no override that can
#   manufacture a pass, and THERE IS NO SENTINEL THAT SKIPS A CHECK - not in this file and not
#   anywhere in this repository. Do not add one, however convenient one looks while debugging.
#
#   LXC_HOST, CONTAINER, BEET_BIN, PY_BIN, EXEC_USER_FLAG, OVERLAY, THROWAWAY_DB and the two
#   timeouts are deliberately PLAIN CONSTANTS for the reason check-music-freeze.sh:85-89 gives
#   about SURVIVOR_DB: an override on any of them could produce a PASS by pointing the read at a
#   different container, a different interpreter or a different host - and an override on
#   THROWAWAY_DB specifically could point `-l` back at the real library, which is the one thing
#   D-04 exists to forbid. Changing one is a one-line edit here, in the commit that changes the
#   policy.
#
# THE READINESS GATE IS A LOG LINE, NOT A CONTAINER STATE FIELD. The docker state field that
# reports a container is up flips the moment the process is exec'd, before rc6's entrypoint has
# migrated its database and started the server; a read taken in that window answers from an
# incomplete process while `docker logs` is still empty. The gate here is the watchdog's
# inbox-registration line, which cannot be printed before the server exists. The LSIO lesson in
# stacks/selfhosted/arrs/beets/beets.yaml - grep it for `lsiown -R abc:abc`, one hit - is the same
# lesson from the other image - but
# note its `lsiown` half does NOT transfer: rc6's entrypoint_fix_permissions.sh chowns only
# /home/beetle /logs /repo and never touches /config, so there is no boot-time chown race here
# and reproducing that gate would record a hazard this image does not have.
#
# THE POSITIVE CONTROL (S3(c)). Arm 1's dump must contain at least one key that can ONLY have
# come from rc6's schema - one that neither vendored file sets. `gui.num_preview_workers` and
# `gui.terminal.start_path` are both such keys. If they are absent, the text in hand is not the
# server-committed object, every "correct" reading taken from it is unverified, and the run is
# UNKNOWN, not green. A dump that cannot see something it is known to contain has not measured a
# clean config; it has failed to look.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- plain constants. NOT overrides - see ENV OVERRIDES in the header. ---
LXC_HOST="172.16.1.159"
CONTAINER="beets-flask"
# The exec identity, written as the LITERAL FLAG rather than assembled from a bare username, so
# a grep over this file can prove which uid every exec runs as without reconstructing an
# expansion. `beetle` is uid 568 in this image - the service account that owns /config.
EXEC_USER_FLAG="-u beetle"
# Absolute paths on purpose: `beet` is NOT on PATH for a `docker exec`, and a different `beet`
# would read a different config and answer a different question.
BEET_BIN="/venv/bin/beet"
PY_BIN="/venv/bin/python"
OVERLAY="/tmp/phase06-check-beets-config-noop.yaml"
# The throwaway library that every `beet` invocation in this file is pointed at (D-04). `.blb` is
# beets' own library extension, and this path is INSIDE THE CONTAINER, not on the LXC.
THROWAWAY_DB="/tmp/p6-cbc-throwaway.blb"
LIBRARY_DB="/config/library.db"
STATEFILE="/config/state.pickle"
REMOTE_TIMEOUT=120
READY_ATTEMPTS=6
READY_SLEEP=5
READY_LINE="Registering watchdog with debounce"
# WR7-05 (2026-09-27). The inbox set the watchdog must register while Phase 7 holds: 01-auto is
# de-registered (D-21) and 03-asis is registered `autotag: "off"` (CR7-01), so EXACTLY these two
# paths, sorted, space-separated. Plain constants, not overrides - an override could name whatever
# set happens to be registered and call it a pass. Phase 8 moves them in the commit that
# re-registers 01-auto.
REG_EXPECTED="/downloads/complete/nzb/_inbox/02-review /downloads/complete/nzb/_inbox/03-asis"
REG_FORBIDDEN_NAME="01-auto"
REG_MARKER="for inboxes: "

# --- the one env override; ADDITIVE, so it can only make this check redder ---
EXTRA_FORBIDDEN_SUBSTRINGS="${EXTRA_FORBIDDEN_SUBSTRINGS:-}"
FORBIDDEN_BUILTIN=("Compilations" "/music/imported")

SSH_OPTS=(-n -o BatchMode=yes -o ConnectTimeout=8)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASELINE_MODE=0
SELFTEST_MODE=0
for arg in "$@"; do
  case "$arg" in
    --baseline) BASELINE_MODE=1 ;;
    --self-test) SELFTEST_MODE=1 ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: bash scripts/check-beets-config.sh [--baseline] [--self-test]" >&2
      exit 2
      ;;
  esac
done

FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

# =============================================================================================
# S3(a) - UNKNOWN sentinels, initialised before anything runs. "0" or "" on a read that could
# not look is the exact false green this file exists to refuse.
# =============================================================================================
CONFIG_ROUTE="unavailable"        # arm 1 - the server-committed object
CONFIG_ROUTE_CLI="unavailable"    # arm 2 - the confuse/CLI view
READY_ROUTE="unavailable"         # how readiness was established
INBOX_REG="UNKNOWN"               # WR7-05: PASS | RED | UNKNOWN - never defaults to PASS
ARM1_BLIND=1
ARM2_BLIND=1
ARM1_JSON=""
ARM2_JSON=""
ARM1_FAILS=0
# GC-13: the two halves of the D-04 source contract, reported separately so that a real violation
# and a blind checker cannot sum to the expected total and cancel into a pass. -1 is an UNKNOWN
# sentinel in the S3(a) style: neither value satisfies its own gate, so a case-6 gate reached
# without assert_beet_invocation_contract having run FAILS rather than passing on a zero.
ARM1_REAL_VIOLATIONS=-1
ARM1_SYNTH_REJECTED=-1
TOOLS_MISSING=0
LIB_HASH_BEFORE="UNKNOWN"
LIB_HASH_AFTER="UNKNOWN"
OVERLAY_SIZE="UNKNOWN"          # arm 2's no-op overlay, MEASURED - never assumed empty
REDACTION_VERDICT="UNKNOWN"
DIFF_ROWS=0

# cfg_fail routes a red either into the real FAILURES counter or, under --self-test, into a
# per-case counter only - so a synthetic case that is SUPPOSED to go red does not contaminate
# the script's own exit code.
cfg_fail() {
  ARM1_FAILS=$((ARM1_FAILS + 1))
  if [[ $SELFTEST_MODE -eq 1 ]]; then
    echo -e "    ${RED}· $*${NC}"
  else
    fail "$*"
  fi
}
cfg_pass() {
  if [[ $SELFTEST_MODE -eq 1 ]]; then
    echo -e "    ${GREEN}· $*${NC}"
  else
    pass "$*"
  fi
}

# =============================================================================================
# The dump-to-JSON extractor.
#
# BOTH ARMS EMIT THE SAME TEXT FORMAT - arm 1 calls `beets.config.dump(full=True, redact=True)`
# directly and `beet config -d` calls exactly that same function - so ONE extractor serves both
# and the comparison is symmetric by construction rather than by two hand-written readers that
# might disagree.
#
# It is NOT a YAML parser and must not be replaced by one: confuse's dump of this repo's `paths`
# stanza is not valid YAML. Keys like
#     albumtype:=dj disctotal:2..: DJ/$albumartist/...
# carry colons inside the KEY, so the split is on the LAST ": " in the line, which is the only
# rule that recovers both halves correctly.
# =============================================================================================
read -r -d '' DUMP_TO_JSON <<'PYEOF' || true
import json, re, sys

def split_flow(inner):
    """Split a YAML flow-sequence body on commas that are NOT inside quotes.

    A plain inner.split(',') is wrong and fails QUIETLY: confuse dumps this config's
    gui.library.artist_separators as [',', ;, '&'], whose FIRST ELEMENT IS A QUOTED COMMA.
    Splitting naively turns one element into two half-quotes and the list silently gains an
    entry. No key asserted by this script carries a quoted comma today, which is exactly why
    the defect would have sat here unnoticed until one did.
    """
    out, buf, quote = [], '', None
    for ch in inner:
        if quote:
            buf += ch
            if ch == quote:
                quote = None
        elif ch in ("'", '"'):
            quote = ch
            buf += ch
        elif ch == ',':
            out.append(buf)
            buf = ''
        else:
            buf += ch
    out.append(buf)
    return out

def scalar(v):
    v = v.strip()
    if v.startswith('[') and v.endswith(']'):
        inner = v[1:-1].strip()
        return [] if not inner else [scalar(x) for x in split_flow(inner)]
    if len(v) >= 2 and v[0] == v[-1] and v[0] in ("'", '"'):
        return v[1:-1]
    if v in ('yes', 'true', 'True'):
        return True
    if v in ('no', 'false', 'False'):
        return False
    if v == '':
        return None
    if re.fullmatch(r'-?\d+', v):
        return int(v)
    if re.fullmatch(r'-?\d+\.\d+', v):
        return float(v)
    return v

def skippable(line):
    return (not line.strip()) or line.lstrip().startswith('#')

def parse_block(lines, start, base_indent):
    out, i = {}, start
    while i < len(lines):
        raw = lines[i]
        if skippable(raw):
            i += 1
            continue
        indent = len(raw) - len(raw.lstrip(' '))
        if indent < base_indent:
            break
        s = raw.strip()
        if s.startswith('- '):
            break
        if ': ' in s:
            k, v = s.rsplit(': ', 1)
            out[k.strip()] = scalar(v)
            i += 1
            continue
        if s.endswith(':'):
            k = s[:-1].strip()
            j = i + 1
            while j < len(lines) and skippable(lines[j]):
                j += 1
            if j < len(lines):
                nxt = lines[j]
                nind = len(nxt) - len(nxt.lstrip(' '))
                if nxt.strip().startswith('- ') and nind >= indent:
                    items = []
                    while j < len(lines):
                        n = lines[j]
                        if skippable(n):
                            j += 1
                            continue
                        ni = len(n) - len(n.lstrip(' '))
                        if n.strip().startswith('- ') and ni >= indent:
                            items.append(scalar(n.strip()[2:]))
                            j += 1
                        else:
                            break
                    out[k] = items
                    i = j
                    continue
                if nind > indent:
                    sub, j2 = parse_block(lines, j, nind)
                    out[k] = sub
                    i = j2
                    continue
            out[k] = None
            i += 1
            continue
        i += 1
    return out, i

text = sys.stdin.read()
tree, _ = parse_block(text.splitlines(), 0, 0)
json.dump(tree, sys.stdout)
PYEOF

dump_to_json() {  # stdin: dump text -> stdout: JSON ("" on failure)
  python3 -c "$DUMP_TO_JSON" 2>/dev/null || true
}

# jget: read one value out of a JSON document. Returns the literal string UNKNOWN when the key
# is absent, null, or the document is unreadable - never an empty string that an equality test
# could accidentally satisfy.
jget() {
  local json="$1" filter="$2" out rc=0
  out="$(printf '%s' "$json" | jq -cr "$filter" 2>/dev/null)" || rc=$?
  if [[ $rc -ne 0 || -z "$out" || "$out" == "null" ]]; then
    printf 'UNKNOWN'
    return 0
  fi
  printf '%s' "$out"
}

expect_eq() {  # key, want, got
  local k="$1" want="$2" got="$3"
  if [[ "$got" == "UNKNOWN" ]]; then
    cfg_fail "$k: UNKNOWN, not green — absent from the server-committed dump, or unreadable"
  elif [[ "$got" == "$want" ]]; then
    cfg_pass "$k = $got"
  else
    cfg_fail "$k = '$got' — want '$want'"
  fi
}

expect_ne() {  # key, forbidden, got, why
  local k="$1" bad="$2" got="$3" why="$4"
  if [[ "$got" == "UNKNOWN" ]]; then
    cfg_fail "$k: UNKNOWN, not green — absent from the server-committed dump, or unreadable"
  elif [[ "$got" == "$bad" ]]; then
    cfg_fail "$k = '$got' — $why"
  else
    cfg_pass "$k = $got (not '$bad')"
  fi
}

# =============================================================================================
# THE D-04 SOURCE CONTRACT, AND WHY IT IS CHECKED AGAINST THIS FILE'S OWN TEXT.
#
# assert_effective_config() below is pure over a DUMP, so it cannot see invocation flags - which
# means the thing plan 06-15 actually fixed (the missing `-l`) is invisible to every existing
# self-test case. This pair of functions closes that: they read this script's own source and
# require every line that invokes `beet` to carry BOTH `-l` and `-c`.
#
# EVERY PATTERN BELOW IS ASSEMBLED FROM `d` RATHER THAN WRITTEN AS A LITERAL. If the literal
# expansions appeared here, this checker would match its OWN pattern lines and report itself as
# a violation - and the repo-wide D-04 grep in quick-health-check.sh would count them too. The
# variable is the only thing keeping the detector out of its own haystack.
# =============================================================================================
beet_invocation_violations() {  # stdin: shell source -> stdout: one line per non-compliant call
  local d='$' line
  local pat_bin="${d}{BEET_BIN}" pat_lib="${d}{THROWAWAY_DB}" pat_ovl="${d}{OVERLAY}"
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" == *"$pat_bin"* ]] || continue
    if [[ "$line" != *"$pat_lib"* || "$line" != *"$pat_ovl"* ]]; then
      printf '%s\n' "$line"
    fi
  done
}

# GC-13: this function reports THREE outcomes but used to report them through ONE counter. Two of
# them increment ARM1_FAILS (a real source violation, and the correctly-rejected synthetic) and
# the third — the synthetic NOT rejected, i.e. the checker is blind — increments nothing. Summed,
# "one real violation" + "a blind checker" equals the expected total of 1. The two are therefore
# ALSO reported separately below, and case 6 gates on both independently. ARM1_FAILS keeps exactly
# the value it always had, and that is correct — but R3-07 found that the reason recorded here for
# preserving it was not. The old wording said the live summary line was a second consumer of this
# function's contribution to the counter. It is not: this function is called from exactly ONE
# place, and that place is run_self_test, so it never executes on a live run at all. The live
# summary line consumes the counter; it never sees anything this function put in it. The real
# reason to preserve the value is narrower — the self-test's per-case bookkeeping and the live
# summary share one counter, so changing it here would move a number in a path this change has no
# business touching.
#
# The census, given as a RECIPE rather than a number you must take on trust, and comment-STRIPPED,
# because a raw count also matches every comment that discusses the function, this one included:
#   /usr/bin/grep -v '^[[:space:]]*#' scripts/check-beets-config.sh \
#     | /usr/bin/grep -c 'assert_beet_invocation_contract'
# The answer is 2 — the definition, and the one call inside run_self_test. Anything higher means
# someone has wired it somewhere else, and the paragraph below applies. R3-07's own evidence line
# printed that code-only figure as though it were a raw grep count; that is the same
# self-referential measurement error this round is closing, so it is corrected here rather than
# inherited.
#
# THE RAW COUNT IS DELIBERATELY NOT PINNED HERE — R4-05, corrected 2026-09-23 by plan 06-38.
# Round 3's correcting hunk did pin one, and its own text falsified it in the act of writing it: a
# number written into a file that greps itself is moved by the sentence that states it, and the
# recipe line that same hunk added at the head of this census is what moved this one. The hedge it
# attached, conceding that such a figure drifts as comments about the symbol accumulate, is not a
# fix — the hunk that wrote the hedge is what drifted it. So the figure is WITHDRAWN, not re-stated,
# which is what the sibling R3-05 block in scripts/quick-health-check.sh did in this same round:
# there the header count is the durable one and the raw count is deliberately unpinned; here the
# COMMENT-STRIPPED figure above is the durable one, and it is the only one this file offers.
# Re-pinning the raw figure to a fresh number would simply set up the next drift, which would
# arrive with the next comment that mentions the symbol. If you need the raw figure, run the recipe
# above WITHOUT its `grep -v` pass — and do not write the answer back into this comment.
# The measurement across three refs that established the drift is recorded once, in
# .planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP2.md § Corrections
# item 1, and nothing in this file reads from that register.
#
# EVERY OTHER IN-BAND COUNT CLAIM IN THIS FILE WAS AUDITED IN THE SAME PASS — plan 06-38; the
# table is in artifacts/06-38-checker-count-audit.txt. Each was measured against its own recipe.
# The claims that count a token in ANOTHER version-controlled file (beets.yaml's `lsiown -R
# abc:abc` and `MIGRATE ITS SCHEMA`, check-music-freeze.sh's `zfs_query() {`) were left alone:
# prose added HERE cannot move them. ST_PLANNED_CASES was EXCLUDED BY NAME — it is a gated pin
# over an unconditionally executed set, not a prose claim about a grep, and it is the one number
# in this file that is supposed to be a number. The single claim a naive grep would have answered
# wrongly, the env-override census in this file's header, was converted to a bracketed recipe.
# No executable line moved, and the audit found nothing that needed one. The artifact records the
# enumeration method AND ITS KNOWN GAPS: one reader, one pass, an open-ended keyword list — it is
# not a completeness proof, and three consecutive rounds each found an instance of this class that
# the previous round's reader had missed.
#
# IF THIS FUNCTION IS EVER CALLED LIVE, its two arms must be re-polarised in the same change.
# Today the CORRECT outcome — the synthetic line was rejected — routes through cfg_fail, while the
# DEFECTIVE outcome — the checker rejected nothing, so it is blind — is a bare echo. Under
# --self-test that is fine: cfg_fail feeds a per-case counter rather than the script's exit code,
# and case 6's ARM1_SYNTH_REJECTED gate catches the blind arm, so neither outcome is lost. Live it
# is backwards with respect to FAILURES — a CORRECT run would increment it and a BLIND checker
# would increment nothing. Wiring this live therefore requires routing the blind arm through
# cfg_fail and the correctly-rejected-synthetic arm through a self-test-only echo, IN THE SAME
# COMMIT AS THE WIRING. Expect the temptation: a live run currently never checks the -l + -c
# source contract at all, which is exactly why this function is the obvious thing to reach for.
assert_beet_invocation_contract() {
  local d='$' real synth synth_bad n
  ARM1_FAILS=0
  # Re-initialised per call, so a second call cannot inherit the first call's state.
  ARM1_REAL_VIOLATIONS=0
  ARM1_SYNTH_REJECTED=0

  real="$(beet_invocation_violations <"${BASH_SOURCE[0]}")"
  if [[ -n "$real" ]]; then
    n="$(printf '%s\n' "$real" | wc -l | tr -d ' ')"
    ARM1_REAL_VIOLATIONS="$n"
    cfg_fail "D-04 contract: $n beet invocation(s) in this script's own source do NOT carry both -l and -c — $(printf '%s' "$real" | tr -s ' ')"
  else
    cfg_pass "D-04 contract: every beet invocation in this script's own source carries -l ${d}{THROWAWAY_DB} AND -c ${d}{OVERLAY}"
  fi

  # The driven negative. A checker that only ever sees compliant input has not been shown to
  # reject anything, so it is handed a synthetic line carrying -c and no -l, and the REJECTION
  # is what counts as this case's red.
  synth_bad="    beet_exec \"${d}{BEET_BIN} -c ${d}{OVERLAY} config -d\""
  synth="$(printf '%s\n' "$synth_bad" | beet_invocation_violations)"
  if [[ -n "$synth" ]]; then
    ARM1_SYNTH_REJECTED=1
    cfg_fail "D-04 contract, driven: the synthetic -c-only invocation was REJECTED, as it must be — $(printf '%s' "$synth" | tr -s ' ')"
  else
    echo -e "    ${RED}· D-04 contract: the synthetic -c-only invocation was NOT rejected — the checker is BLIND${NC}"
  fi
}

# =============================================================================================
# THE ASSERTION FUNCTION. Pure: JSON in, findings out, ARM1_FAILS set. No ssh, no docker, no
# globals read other than the forbidden-substring lists - which is what lets --self-test drive
# every red branch below without a container.
# =============================================================================================
assert_effective_config() {
  local json="$1" raw="$2"
  ARM1_FAILS=0

  # ---- S3(c) positive control, FIRST. Two keys that neither vendored file sets and that can
  # only have arrived through rc6's schema injection. Their absence means the text in hand is
  # not the server-committed object at all.
  local pc1 pc2
  pc1="$(jget "$json" '.gui.num_preview_workers')"
  pc2="$(jget "$json" '.gui.terminal.start_path')"
  if [[ "$pc1" == "UNKNOWN" || "$pc2" == "UNKNOWN" ]]; then
    cfg_fail "positive control: gui.num_preview_workers='$pc1' gui.terminal.start_path='$pc2' — neither vendored file sets these, so their absence means this is NOT the server-committed object. Every reading below is UNKNOWN, not green."
  else
    cfg_pass "positive control: rc6 schema keys present in the dump (gui.num_preview_workers=$pc1, gui.terminal.start_path=$pc2) — this IS the server-committed object"
  fi

  # ---- CONF-01: copy, never move. There is no `beet undo`; a bulk run with move set consumes
  # its own source and the only reversal is a ZFS rollback of two datasets.
  expect_eq "CONF-01 import.copy" "true"  "$(jget "$json" '.import.copy')"
  expect_eq "CONF-01 import.move" "false" "$(jget "$json" '.import.move')"

  # ---- CONF-02: BOTH keys, each named separately. The first without the second is the trap -
  # `ImportTask.finalize()` writes history for a SKIPPED task unless incremental_skip_later is
  # set, so one quiet pass marks every hard album as done and the remaining work goes invisible
  # rather than unfinished.
  expect_eq "CONF-02 import.incremental"            "true" "$(jget "$json" '.import.incremental')"
  expect_eq "CONF-02 import.incremental_skip_later" "true" "$(jget "$json" '.import.incremental_skip_later')"

  # ---- CONF-05: match disambiguation.
  local countries has_gb has_uk
  countries="$(jget "$json" '.match.preferred.countries | @json')"
  has_gb="$(jget "$json" '.match.preferred.countries | if type=="array" then (index("GB") != null) else "UNKNOWN" end')"
  has_uk="$(jget "$json" '.match.preferred.countries | if type=="array" then (index("UK") != null) else "UNKNOWN" end')"
  if [[ "$has_gb" == "UNKNOWN" ]]; then
    # The list itself is absent or is not a list. That is ONE finding about ONE key, so the UK
    # sub-check below is not reached: reporting the same absence twice would inflate the red
    # count without adding a second thing that is wrong.
    cfg_fail "CONF-05 match.preferred.countries: UNKNOWN, not green — absent, or not a list"
  else
    if [[ "$has_gb" == "true" ]]; then
      cfg_pass "CONF-05 match.preferred.countries contains GB — $countries"
    else
      cfg_fail "CONF-05 match.preferred.countries does NOT contain GB — $countries"
    fi
    # IN-01: routed through expect_ne rather than hand-rolled, so the two helpers stay symmetric
    # and this case inherits expect_ne's UNKNOWN arm. The explanatory sentence is the load-bearing
    # part of this check and is preserved word for word.
    expect_ne "CONF-05 match.preferred.countries contains UK" "true" "$has_uk" \
      "MusicBrainz stores GB, so UK matches nothing and fails SILENTLY: the import simply prefers a different release"
  fi
  expect_eq "CONF-05 match.preferred.original_year" "true" "$(jget "$json" '.match.preferred.original_year')"

  local extra_n
  extra_n="$(jget "$json" '.musicbrainz.extra_tags | if type=="array" then length else "UNKNOWN" end')"
  if [[ "$extra_n" == "UNKNOWN" ]]; then
    cfg_fail "CONF-05 musicbrainz.extra_tags: UNKNOWN, not green — absent, or not a list"
  elif [[ "$extra_n" -gt 0 ]]; then
    cfg_pass "CONF-05 musicbrainz.extra_tags is a non-empty list ($extra_n entries): $(jget "$json" '.musicbrainz.extra_tags | @json')"
  else
    cfg_fail "CONF-05 musicbrainz.extra_tags is EMPTY — candidate ranking has nothing to discriminate on"
  fi

  # ---- The four rc6 schema-default landmines. Each of these is a key the vendored config must
  # pin, because silence here is not beets' default but rc6's - and for the first one rc6's is a
  # delete with no prompt across a library with measured duplicate groups.
  expect_eq "T-06-31 import.duplicate_action" "ask"  "$(jget "$json" '.import.duplicate_action')"
  expect_eq "match.medium_rec_thresh"         "0.25" "$(jget "$json" '.match.medium_rec_thresh')"
  expect_eq "directory"                       "/media/Music"         "$(jget "$json" '.directory')"
  expect_eq "statefile"                       "/config/state.pickle" "$(jget "$json" '.statefile')"
  expect_eq "library"                         "/config/library.db"   "$(jget "$json" '.library')"

  # ---- SAFE-01: the three destructive automatic switches, all off. An ABSENT key here is not
  # an off switch - it is the on switch, waiting for the plugin name to be added.
  expect_eq "SAFE-01 scrub.auto"     "false" "$(jget "$json" '.scrub.auto')"
  expect_eq "SAFE-01 lastgenre.auto" "false" "$(jget "$json" '.lastgenre.auto')"
  expect_eq "SAFE-01 embedart.auto"  "false" "$(jget "$json" '.embedart.auto')"

  # ---- OD-2 (07-UAT gaps 1–3): album art from Cover Art Archive, and media preference.
  # An album that lands with no art leaves every consumer to guess, and both guesses were wrong
  # (07-UAT gaps 1 and 2). fetchart writes a sidecar cover.jpg and never touches the audio;
  # embedart is the plugin that would. `media` entries are regexes that beets wraps as
  # `(\d+x)?(…)`, so `CD` also matches `2xCD` (07-UAT gap 3).
  expect_eq "OD-2 fetchart.auto"            "true"                  "$(jget "$json" '.fetchart.auto')"
  expect_eq "OD-2 fetchart.sources"         '["coverart"]'          "$(jget "$json" '.fetchart.sources | @json')"
  expect_eq "OD-2 art_filename"             "cover"                 "$(jget "$json" '.art_filename')"
  expect_eq "OD-2 match.preferred.media"    '["Digital Media","CD"]' "$(jget "$json" '.match.preferred.media | @json')"

  # ---- The path stanza.
  local comp_v def_v
  comp_v="$(jget "$json" '.paths.comp')"
  def_v="$(jget "$json" '.paths.default')"
  if [[ "$comp_v" == "UNKNOWN" || "$def_v" == "UNKNOWN" ]]; then
    cfg_fail "paths.comp / paths.default: UNKNOWN, not green — one or both absent (comp='$comp_v' default='$def_v')"
  elif [[ "$comp_v" == "$def_v" ]]; then
    cfg_pass "paths.comp equals paths.default — the inherited compilation rule is OVERRIDDEN, which is the only way to neutralise it (there is no syntax for deleting an inherited path rule)"
  else
    cfg_fail "paths.comp ('$comp_v') does not equal paths.default ('$def_v')"
  fi

  local n_comp
  n_comp="$(jget "$json" '.paths | if type=="object" then ([.[] | select(type=="string") | select(test("Compilations"))] | length) else "UNKNOWN" end')"
  if [[ "$n_comp" == "UNKNOWN" ]]; then
    cfg_fail "paths: UNKNOWN, not green — the stanza is absent or is not a mapping"
  elif [[ "$n_comp" -eq 0 ]]; then
    cfg_pass "paths: no rule routes anything into a Compilations/ tree"
  else
    cfg_fail "paths: $n_comp rule(s) still route into a Compilations/ tree"
  fi

  expect_eq "per_disc_numbering" "true"            "$(jget "$json" '.per_disc_numbering')"
  expect_eq "asciify_paths"      "false"           "$(jget "$json" '.asciify_paths')"
  expect_eq "va_name"            "Various Artists" "$(jget "$json" '.va_name')"

  # ---- plugins: exactly {musicbrainz, fetchart}, in any order. Since beets 2.4.0 MusicBrainz is
  # itself a plugin; a customised list that omits it silently disables autotagging and the
  # symptom presents as "no match found", never as a config error. fetchart is the one reviewed
  # addition (OD-2, below). embedart must never be listed: it rewrites the audio file (SAFE-01),
  # and neither may any plugin outside this reviewed set.
  local plug_set
  plug_set="$(jget "$json" '.plugins | if type=="array" then (sort | @json) else "UNKNOWN" end')"
  if [[ "$plug_set" == "UNKNOWN" ]]; then
    cfg_fail "plugins: UNKNOWN, not green — absent, or not a list"
  elif [[ "$plug_set" == '["fetchart","musicbrainz"]' ]]; then
    cfg_pass "plugins is exactly {musicbrainz, fetchart}"
  else
    cfg_fail "plugins = $(jget "$json" '.plugins | @json') — want exactly {musicbrainz, fetchart}; embedart must never be listed (SAFE-01: it rewrites audio files), nor any plugin outside the reviewed set"
  fi

  # ---- Forbidden substrings over the RAW dump text, built-ins plus the additive override.
  #
  # GC-01. THE HERE-STRING IS LOAD-BEARING. Both tests below used to read
  #   printf '%s' "$raw" | grep -qF -- "$forb"
  # under this file's `set -euo pipefail`. `grep -q` exits the instant it matches, `printf` is
  # still writing, takes SIGPIPE and exits 141, `pipefail` hands 141 to the PIPELINE, and the
  # `if` therefore evaluated FALSE. Direction of the failure: a substring that IS present was
  # reported ABSENT - a false GREEN over a live condition, not a false red. Measured on this
  # workstation with the match on line 1: FOUND at 8/16/32/48/56 KiB, MISSED at 64/72/96/128 KiB,
  # so the ceiling is the 64 KiB pipe buffer and the defect is POSITION-DEPENDENT (a match near
  # the bottom of a large dump is caught even by the broken form). `$raw` is the whole arm-1
  # server-committed dump, which grows with every beets release and every plugin enabled.
  # A here-string feeds grep from a temporary file: there is no writer to take SIGPIPE, no
  # pipeline for `pipefail` to propagate from, and the `if` reads grep's own status. `set +o
  # pipefail` around the test is NOT the fix - turning the option off weakens every other
  # statement in the same scope to buy one test. Self-test case 7 crosses the ceiling and is
  # driven both ways; see artifacts/06-22-pipefail-141.txt.
  local forb
  for forb in "${FORBIDDEN_BUILTIN[@]}"; do
    if grep -qF -- "$forb" <<<"$raw"; then
      cfg_fail "forbidden substring present in the server-committed dump: '$forb'"
    fi
  done
  if [[ -n "$EXTRA_FORBIDDEN_SUBSTRINGS" ]]; then
    # IN-07: field splitting on ':' is WANTED here; pathname expansion is NOT. The old
    # `local IFS=':'; for forb in $EXTRA_FORBIDDEN_SUBSTRINGS` gave both, so a value carrying
    # `*` or `?` globbed against the repo root. `read -r -a` splits on IFS and cannot glob at
    # all, which is the behaviour wanted and only that behaviour.
    local -a forb_arr=()
    IFS=':' read -r -a forb_arr <<<"$EXTRA_FORBIDDEN_SUBSTRINGS"
    for forb in "${forb_arr[@]}"; do
      [[ -z "$forb" ]] && continue
      # GC-01: here-string, same reason as the built-in loop above. One explanation, not two.
      if grep -qF -- "$forb" <<<"$raw"; then
        cfg_fail "forbidden substring present (EXTRA_FORBIDDEN_SUBSTRINGS): '$forb'"
      fi
    done
  fi
}

# =============================================================================================
# WR7-05 - THE INBOX REGISTRATION ASSERTION. Pure: log text in, verdict out. No ssh, no docker.
#
# Reads the MOST RECENT registration line in the text it is given, never "any line": a line from
# before a restart is exactly what the old READY_LINE grep accepted, and it is how a stale 01-auto
# registration could satisfy a gate. The live caller narrows the text further, to
# `docker logs --since <the container's StartedAt>`, so only the current process can answer.
#
# The line format is OBSERVED, not assumed - rc6 prints a Python list repr of the inbox PATHS:
#   [INFO] beets-flask.wdog: Registering watchdog with debounce of 30 seconds for inboxes: ['/downloads/complete/nzb/_inbox/02-review', '/downloads/complete/nzb/_inbox/03-asis']
# (07-09-fence-and-grant.txt § Step 3 and 07-11-p10-undo-rerun.txt § RESTORE (3), both captured
# after D-21 deployed). The list is re-joined from its parsed items and compared with the original,
# so a format the parser does not fully understand is UNKNOWN, never a partial read.
#
# Returns 0 PASS, 1 RED (01-auto named; fewer than two; any path outside REG_EXPECTED; or any
# sorted list that is not exactly REG_EXPECTED), 2 UNKNOWN (no registration line; list unparseable).
# ⚠ UNOBSERVED: whether rc6 lists an `autotag: "off"` inbox on this line. 03-asis was `bootleg` in
# every capture above. If `off` inboxes are not listed, this reads ONE inbox and goes RED - loud,
# which is the right direction; resolve it from a live capture, never by widening REG_EXPECTED.
# =============================================================================================
INBOX_REG_WHY=""
INBOX_REG_LINE=""
INBOX_REG_NAMES=""
assert_inbox_registration() {  # $1 = log text; -> rc 0/1/2, INBOX_REG_WHY / _LINE / _NAMES
  local text="$1" line inner items rejoined sorted n bad=0 item why=""
  INBOX_REG_WHY=""; INBOX_REG_LINE=""; INBOX_REG_NAMES=""
  line="$(printf '%s\n' "$text" | grep -F -- "$READY_LINE" | grep -F -- "$REG_MARKER" | tail -n 1 || true)"
  line="${line%$'\r'}"
  if [[ -z "$line" ]]; then
    INBOX_REG_WHY="no registration line naming inboxes was found in the text read. That is NOT 'the set is right' - nothing was compared."
    return 2
  fi
  INBOX_REG_LINE="$line"
  inner="${line#*"$REG_MARKER"}"
  inner="${inner%"${inner##*[![:space:]]}"}"
  if [[ "$inner" != \[*\] ]]; then
    INBOX_REG_WHY="the registration line does not end in a [...] list, so its inboxes could not be read: $inner"
    return 2
  fi
  inner="${inner#[}"; inner="${inner%]}"
  items="$(printf '%s' "$inner" | grep -oE "'[^']*'" | sed "s/^'//; s/'\$//" || true)"
  rejoined="$(printf '%s\n' "$items" | awk 'NF { printf "%s\x27%s\x27", (n++ ? ", " : ""), $0 }')"
  if [[ "$rejoined" != "$inner" ]]; then
    INBOX_REG_WHY="the inbox list did not parse cleanly (re-joined items differ from the line), so nothing was compared: [$inner]"
    return 2
  fi
  n="$(printf '%s\n' "$items" | grep -c . || true)"
  INBOX_REG_NAMES="$(printf '%s\n' "$items" | sed 's#.*/##' | grep . | tr '\n' ' ' | sed 's/ $//' || true)"
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ "${item##*/}" == "$REG_FORBIDDEN_NAME" ]]; then
      why+="${why:+; }$REG_FORBIDDEN_NAME is registered ($item) - D-21 did not deploy, or was reverted"
      bad=1
    elif [[ " $REG_EXPECTED " != *" $item "* ]]; then
      why+="${why:+; }unexpected inbox $item"
      bad=1
    fi
  done <<< "$items"
  if [[ $n -lt 2 ]]; then
    why+="${why:+; }fewer than two inboxes registered ($n)"
    bad=1
  fi
  sorted="$(printf '%s\n' "$items" | grep . | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//' || true)"
  if [[ $bad -eq 0 && "$sorted" != "$REG_EXPECTED" ]]; then
    why="the registered set is not exactly the expected set (duplicate?): got [$sorted]"
    bad=1
  fi
  if [[ $bad -ne 0 ]]; then
    INBOX_REG_WHY="$why"
    return 1
  fi
  return 0
}

# =============================================================================================
# --self-test. SEVEN cases, SIX of which MUST go red: 6 synthetic dumps plus one assertion over
# this file's own source. Same device as scripts/spike03-wrtag-arms.sh:23-27: drive the
# fail-closed branches without touching the estate. A control that can only pass is uninformative.
#
# Case 7 exists because of GC-01: every dump the other cases feed is a few hundred bytes, so this
# self-test STRUCTURALLY could not see a defect whose threshold is the 64 KiB pipe buffer. Case 7
# crosses that threshold on purpose and asserts that it still does.
# =============================================================================================
synthetic_correct_dump() {
  cat <<'DUMPEOF'
gui:
    inbox:
        debounce_before_autotag: 30
        temp_dir: /tmp/beets-flask/upload
    terminal:
        enabled: no
        start_path: /repo
    num_preview_workers: 4
directory: /media/Music
library: /config/library.db
statefile: /config/state.pickle
plugins: [musicbrainz, fetchart]
art_filename: cover
per_disc_numbering: yes
asciify_paths: no
va_name: Various Artists
max_filename_length: 0
import:
    copy: yes
    move: no
    incremental: yes
    incremental_skip_later: yes
    duplicate_action: ask
    write: yes
match:
    medium_rec_thresh: 0.25
    preferred:
        countries: [GB, US]
        original_year: yes
        media: [Digital Media, CD]
musicbrainz:
    extra_tags:
    - year
    - catalognum
paths:
    singleton: Singles/$artist/$title%sunique{}
    albumtype:=dj disctotal:2..: DJ/$albumartist/$album%aunique{}/$disc-$track $title
    comp: $albumartist/$album%aunique{}/$track $title
    default: $albumartist/$album%aunique{}/$track $title
scrub:
    auto: no
lastgenre:
    auto: no
embedart:
    auto: no
fetchart:
    auto: yes
    sources: [coverart]
DUMPEOF
}

run_self_test() {
  # ST_PLANNED_CASES is the ANNOUNCED count; st_cases is what actually ran, and the two are
  # compared at the end. A banner that says one number while another number of cases ran is the
  # self-invalidating-prose defect this phase has already hit twice - so the closing banners are
  # DERIVED, and a mismatch between the announcement and reality is itself a self-test failure.
  local ST_PLANNED_CASES=15
  echo "🧪 --self-test — $ST_PLANNED_CASES cases: 8 synthetic dumps, the D-04 contract over this file's own source, and 6 inbox-registration lines (WR7-05)"
  rule
  echo ""

  local st_failures=0 st_cases=0 st_red_cases=0
  local case_name expect_reds raw json

  # The mutated value is built from a variable rather than written inline, so no transcript of
  # this run reproduces the key/value pair that a grep over a phase artifact treats as a live
  # finding. Same reason 06-04's artifact paraphrases its own detector strings.
  local delete_action="remove"

  run_case() {  # name, expected-red-count, dump-text
    case_name="$1"; expect_reds="$2"; raw="$3"
    json="$(printf '%s' "$raw" | dump_to_json)"
    echo -e "  ${BLUE}case: $case_name  (expect $expect_reds red)${NC}"
    assert_effective_config "$json" "$raw"
    st_cases=$((st_cases + 1))
    if [[ $expect_reds -gt 0 ]]; then st_red_cases=$((st_red_cases + 1)); fi
    # GC-13 note: this comparison is a SUM, and it is correct HERE - every red it counts comes
    # from the same pure function over one synthetic dump, so the total is the whole outcome.
    # Case 6 below is the one that must NOT compare a sum; see its own note.
    if [[ $ARM1_FAILS -eq $expect_reds ]]; then
      echo -e "  ${GREEN}✅ case '$case_name': $ARM1_FAILS red, as expected${NC}"
    else
      echo -e "  ${RED}❌ case '$case_name': $ARM1_FAILS red, expected $expect_reds${NC}"
      st_failures=$((st_failures + 1))
    fi
    echo ""
  }

  # 1. An EMPTY dump. Every sentinel must stay UNKNOWN and the positive control must fire.
  run_case "empty dump (blind)" 26 ""

  # 2. The rc6 schema default for the duplicate-handling key - the silent delete path. Exactly
  #    one red, and it must be that key: a case that goes red for two reasons proves nothing
  #    about which branch fired.
  run_case "the silent-delete duplicate action" 1 \
    "$(synthetic_correct_dump | sed "s/^\( *duplicate_action: \)ask\$/\1${delete_action}/")"

  # 3. incremental without incremental_skip_later - the CONF-02 trap.
  run_case "incremental set, incremental_skip_later not" 1 \
    "$(synthetic_correct_dump | sed 's/^\( *incremental_skip_later: \)yes$/\1no/')"

  # 4. The country code MusicBrainz does not store. TWO reds by design: GB is missing AND the
  #    non-matching code is present. They are separate findings and are counted separately.
  run_case "preferred.countries carrying the wrong country code" 2 \
    "$(synthetic_correct_dump | sed 's/^\( *countries: \)\[GB, US\]$/\1[UK, US]/')"

  # 5. Fully correct. Zero red.
  run_case "fully correct" 0 "$(synthetic_correct_dump)"

  # 5a. embedart listed beside the reviewed pair. Exactly one red, the plugins assertion: the
  #     embedart.auto switch below stays off, so this proves the plugin SET is checked, not the switch.
  run_case "embedart appended to plugins (OD-2)" 1 \
    "$(synthetic_correct_dump | sed 's/^plugins: \[musicbrainz, fetchart\]$/plugins: [musicbrainz, fetchart, embedart]/')"

  # 5b. No media preference - the 07-UAT gap 3 shape. Exactly one red, preferred.media.
  run_case "preferred.media absent (OD-2)" 1 \
    "$(synthetic_correct_dump | sed '/^ *media: \[Digital Media, CD\]$/d')"

  # 6. NOT a dump case. The five above drive a pure function over synthetic TEXT and therefore
  #    cannot see an invocation flag; this one reads this script's own SOURCE and requires the
  #    D-04 `-l` + `-c` contract of every `beet` call in it. Its red is a driven negative: a
  #    synthetic -c-only line that the checker must reject. Strip `-l` from any of the three real
  #    invocations and ARM1_REAL_VIOLATIONS goes non-zero; make the synthetic compliant and
  #    ARM1_SYNTH_REJECTED goes to 0. Either alone, or both together, fails this case and takes
  #    --self-test non-zero — "both together" being the GC-13 cancellation the old gate passed.
  case_name="the -l + -c contract over this script's own source"
  echo -e "  ${BLUE}case: $case_name  (gate: real violations=0 AND synthetic rejected=1)${NC}"
  assert_beet_invocation_contract
  st_cases=$((st_cases + 1))
  st_red_cases=$((st_red_cases + 1))
  # GC-13. This gate used to compare ARM1_FAILS against the single expected total 1, and
  # assert_beet_invocation_contract funnels two DISTINCT outcomes into that one counter — so
  # "one real violation in this file's source" plus "the checker is blind" summed to 1 and the
  # case reported `1 red, as expected`. Two faults cancelled into a pass. The two are now gated
  # independently, and a failure names WHICH half is wrong: "1 red, expected 1" is exactly what
  # made the defect invisible.
  #
  # R3-08. GC-13 then left this case's expected-red count alive as a BANNER-ONLY value: nothing
  # compared it any more, so the banner could announce one expected red over a run that produced
  # none or two — a smaller instance of the very announced-vs-actual drift that ST_PLANNED_CASES
  # was added twenty lines below to prevent. The announcement is gone; the banner now states the
  # gate, and the success line prints the two values the gate actually read, so the two cannot
  # disagree. The review's alternative — keep the count and add a third conjunct comparing it —
  # was CONSIDERED AND REFUSED: when the two conjuncts below hold there are no real violations and
  # the synthetic was rejected once, so the summed counter is necessarily one and the third
  # conjunct is IMPLIED by the other two. It could never independently fail. That is the
  # vacuous-assertion class CR-01, GC-03 and GC-05 each removed, and recording the refusal matters
  # more than the removal — otherwise the next reader restores it as an obvious omission.
  if [[ $ARM1_REAL_VIOLATIONS -eq 0 && $ARM1_SYNTH_REJECTED -eq 1 ]]; then
    echo -e "  ${GREEN}✅ case '$case_name': real violations=$ARM1_REAL_VIOLATIONS, synthetic rejected=$ARM1_SYNTH_REJECTED${NC}"
  else
    if [[ $ARM1_REAL_VIOLATIONS -ne 0 ]]; then
      echo -e "  ${RED}❌ case '$case_name': real D-04 violations in this script's own source = $ARM1_REAL_VIOLATIONS, want 0${NC}"
    fi
    if [[ $ARM1_SYNTH_REJECTED -ne 1 ]]; then
      echo -e "  ${RED}❌ case '$case_name': synthetic-negative rejected = $ARM1_SYNTH_REJECTED, want 1 — the checker did NOT reject a line it must reject, so it has not been shown to detect anything${NC}"
    fi
    st_failures=$((st_failures + 1))
  fi
  echo ""

  # 7. GC-01's REGRESSION case, and the only case in this file whose input is estate-sized.
  #    Every case above feeds a few hundred bytes, which is why --self-test structurally could
  #    not see a defect whose threshold is the 64 KiB pipe buffer. This one prefixes the correct
  #    dump with a single top-level key whose double-quoted scalar opens with the forbidden
  #    substring and is then padded past 65536 bytes.
  #      - the substring sits at the TOP because the defect is POSITION-DEPENDENT: under the old
  #        `printf | grep -q` form a match near the bottom is still caught, so a bottom-anchored
  #        case would tick green against the broken code and prove nothing;
  #      - the pad is `x`, which cannot terminate a YAML double-quoted scalar and does not
  #        contain `/music/imported`, so dump_to_json returns the same keys it returns for the
  #        unpadded dump and the expected red count is EXACTLY 1 - the forbidden-substring red
  #        and nothing else;
  #      - the size is MEASURED, not assumed. A case that quietly shrinks below the ceiling is a
  #        case that has stopped testing anything, so an under-65536 result is a FAILURE here,
  #        never a silent skip.
  local pad7 raw7 bytes7
  pad7="$(printf '%*s' 70000 '' | tr ' ' 'x')"
  raw7="_pad_gc01: \"Compilations${pad7}\"
$(synthetic_correct_dump)"
  bytes7="$(printf '%s' "$raw7" | wc -c | tr -d ' ')"
  if [[ $bytes7 -le 65536 ]]; then
    echo -e "  ${RED}❌ case 7 PRECONDITION FAILED: raw dump is $bytes7 bytes, at or below the 65536-byte pipe-buffer ceiling — this case has stopped testing what it exists to test${NC}"
    st_failures=$((st_failures + 1))
  else
    echo -e "  ${BLUE}case 7 precondition: raw dump is $bytes7 bytes, above the 65536-byte pipe-buffer ceiling${NC}"
  fi
  run_case "a forbidden substring at the TOP of a >64 KiB dump (GC-01 regression)" 1 "$raw7"

  # 8-13. WR7-05, the inbox registration assertion. Expected return codes, not red counts: 0 PASS,
  #   1 RED, 2 UNKNOWN - and UNKNOWN is its own expectation, so a blind read that came back RED
  #   (or PASS) fails its case. The line prefix is the observed rc6 shape (see the function).
  local reg_pre="[INFO] beets-flask.wdog: Registering watchdog with debounce of 30 seconds for inboxes: "
  local ib="/downloads/complete/nzb/_inbox"
  run_reg_case() {  # name, expected rc, log text
    local rc=0
    echo -e "  ${BLUE}case: $1  (expect rc $2)${NC}"
    assert_inbox_registration "$3" || rc=$?
    st_cases=$((st_cases + 1))
    if [[ $2 -ne 0 ]]; then st_red_cases=$((st_red_cases + 1)); fi
    if [[ $rc -eq $2 ]]; then
      echo -e "  ${GREEN}✅ case '$1': rc $rc, as expected${NC}${INBOX_REG_WHY:+ — $INBOX_REG_WHY}"
    else
      echo -e "  ${RED}❌ case '$1': rc $rc, expected $2${NC}${INBOX_REG_WHY:+ — $INBOX_REG_WHY}"
      st_failures=$((st_failures + 1))
    fi
    echo ""
  }
  run_reg_case "registration: the expected set {02-review, 03-asis}" 0 \
    "2026-09-26T14:58:40Z ${reg_pre}['${ib}/02-review', '${ib}/03-asis']"
  run_reg_case "registration: 01-auto present (the pre-D-21 line)" 1 \
    "${reg_pre}['${ib}/01-auto', '${ib}/02-review', '${ib}/03-asis']"
  run_reg_case "registration: one inbox only" 1 \
    "${reg_pre}['${ib}/02-review']"
  run_reg_case "registration: an unexpected name" 1 \
    "${reg_pre}['${ib}/02-review', '${ib}/04-hold']"
  run_reg_case "registration: no registration line at all (UNKNOWN)" 2 \
    "[INFO] beets-flask: server started
[INFO] something else entirely"
  # The NEWEST line decides, in both directions: an old good line must not rescue a bad newest one.
  run_reg_case "registration: an older good line, the NEWEST names 01-auto" 1 \
    "${reg_pre}['${ib}/02-review', '${ib}/03-asis']
${reg_pre}['${ib}/01-auto', '${ib}/02-review', '${ib}/03-asis']"

  rule
  # The announced count and the count that actually ran must agree, or the banner below is prose
  # that invalidates itself.
  if [[ $st_cases -ne $ST_PLANNED_CASES ]]; then
    echo -e "${RED}❌ --self-test: $st_cases cases ran but $ST_PLANNED_CASES were announced — the banner and the body disagree${NC}"
    return 1
  fi
  if [[ $st_failures -gt 0 ]]; then
    echo -e "${RED}❌ --self-test: $st_failures of $st_cases cases did not behave as expected${NC}"
    return 1
  fi
  echo -e "${GREEN}✅ --self-test: all $st_cases cases behaved as expected ($st_red_cases of them red)${NC}"
  return 0
}

if [[ $SELFTEST_MODE -eq 1 ]]; then
  if run_self_test; then exit 0; else exit 1; fi
fi

# =============================================================================================
# 0. Toolchain preconditions. A missing binary here is a harness failure, not the caller's local
#    problem - the same stance as check-music-consumers.sh:462-475.
# =============================================================================================
echo "🧰 0. Toolchain preconditions"
rule
for t in ssh jq python3 base64; do
  if command -v "$t" >/dev/null 2>&1; then
    ver="$("$t" --version 2>/dev/null | head -1 || true)"
    [[ -z "$ver" ]] && ver="$("$t" -V 2>&1 | head -1 || true)"
    pass "$t $(command -v "$t") — ${ver:-version unknown}"
  else
    fail "$t NOT FOUND — a missing binary here is a harness failure, not a caller's local problem"
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  fi
done

DOCKER_RC=0
ssh "${SSH_OPTS[@]}" "root@${LXC_HOST}" "timeout ${REMOTE_TIMEOUT} docker version --format '{{.Server.Version}}'" \
  >"$WORKDIR/docker-version" 2>"$WORKDIR/docker-version.err" || DOCKER_RC=$?
if [[ $DOCKER_RC -eq 124 ]]; then
  fail "docker (remote): UNKNOWN, not green — the version query exceeded its ${REMOTE_TIMEOUT}s bound. Nothing was read."
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
elif [[ $DOCKER_RC -ne 0 ]]; then
  fail "docker (remote, root@${LXC_HOST}): NOT REACHABLE (ssh exit $DOCKER_RC) — $(head -1 "$WORKDIR/docker-version.err" 2>/dev/null)"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
else
  pass "docker (remote, root@${LXC_HOST}) server $(tr -d '[:space:]' <"$WORKDIR/docker-version")"
fi
echo ""

# =============================================================================================
# 1. Readiness gate. A log line that cannot be printed before the server exists - never the
#    container-liveness field, which flips before rc6's entrypoint has finished.
# =============================================================================================
echo "⏳ 1. Readiness gate — the watchdog registration line"
rule
if [[ $TOOLS_MISSING -gt 0 ]]; then
  fail "readiness: UNKNOWN, not green — the toolchain is incomplete, so nothing was polled"
else
  attempt=0
  while [[ $attempt -lt $READY_ATTEMPTS ]]; do
    attempt=$((attempt + 1))
    LOGS_RC=0
    ssh "${SSH_OPTS[@]}" "root@${LXC_HOST}" "timeout ${REMOTE_TIMEOUT} docker logs ${CONTAINER} 2>&1" \
      >"$WORKDIR/container.log" 2>"$WORKDIR/container.log.err" || LOGS_RC=$?
    if [[ $LOGS_RC -eq 124 ]]; then
      fail "readiness: UNKNOWN, not green — 'docker logs' exceeded its ${REMOTE_TIMEOUT}s bound (rc=124). Nothing was read; this is NOT 'the server is down'."
      break
    elif [[ $LOGS_RC -ne 0 ]]; then
      fail "readiness: UNKNOWN, not green — 'docker logs ${CONTAINER}' exited $LOGS_RC: $(head -1 "$WORKDIR/container.log.err" 2>/dev/null)"
      break
    fi
    if grep -qF -- "$READY_LINE" "$WORKDIR/container.log"; then
      READY_ROUTE="watchdog-log-line"
      pass "readiness: the watchdog registration line is present (attempt $attempt of $READY_ATTEMPTS)"
      info "$(grep -F -- "$READY_LINE" "$WORKDIR/container.log" | tail -1)"
      break
    fi
    if [[ $attempt -lt $READY_ATTEMPTS ]]; then
      warn "readiness: not yet — the watchdog line is absent after attempt $attempt; sleeping ${READY_SLEEP}s"
      sleep "$READY_SLEEP"
    else
      # IN-03: the loop sleeps only BETWEEN attempts, so the wait is one sleep short of
      # attempts x sleep. Rendering the larger number overstates what was actually waited.
      fail "readiness: UNKNOWN, not green — the watchdog registration line never appeared in $(( (READY_ATTEMPTS - 1) * READY_SLEEP ))s. A rejected config kills the WATCHDOG while the page keeps serving, so a serving UI is not evidence."
    fi
  done
fi
echo ""

# =============================================================================================
# 1b. Inbox registration (WR7-05). The readiness gate above only proves a registration line
#     exists SOMEWHERE in the log history - a line from before a restart satisfies it. This
#     section reads the logs of the CURRENT process only (`--since` the container's StartedAt)
#     and asserts the inbox set on its NEWEST registration line: exactly 02-review and 03-asis.
#     See assert_inbox_registration for the verdicts and the observed line format.
#     One remote command, bounded Linux-side at each docker call, with no pipe; its exit status
#     is read, and 124 / 97 (StartedAt empty) / any other non-zero are UNKNOWN, never a pass.
#     Polled like the readiness gate: a restart can put the gate above on a PRE-restart line
#     while the new process has not registered yet, and that window is "not yet", not a red.
# =============================================================================================
echo "📥 1b. Inbox registration — the newest line since the container's StartedAt (WR7-05)"
rule
if [[ "$READY_ROUTE" == "unavailable" ]]; then
  fail "inbox registration: UNKNOWN, not green — the readiness gate never opened, so no registration line was read"
else
  REG_REMOTE="set -o pipefail; s=\$(timeout ${REMOTE_TIMEOUT} docker inspect -f '{{.State.StartedAt}}' ${CONTAINER}) || exit \$?; [ -n \"\$s\" ] || exit 97; echo \"STARTED_AT=\$s\"; timeout ${REMOTE_TIMEOUT} docker logs --since \"\$s\" ${CONTAINER} 2>&1"
  attempt=0
  while [[ $attempt -lt $READY_ATTEMPTS ]]; do
    attempt=$((attempt + 1))
    REG_RC=0
    ssh "${SSH_OPTS[@]}" "root@${LXC_HOST}" "$REG_REMOTE" \
      >"$WORKDIR/registration.log" 2>"$WORKDIR/registration.log.err" || REG_RC=$?
    if [[ $REG_RC -eq 124 ]]; then
      fail "inbox registration: UNKNOWN, not green — a docker call exceeded its ${REMOTE_TIMEOUT}s bound (rc=124). Nothing was compared."
      break
    elif [[ $REG_RC -eq 97 ]]; then
      fail "inbox registration: UNKNOWN, not green — ${CONTAINER} reported an EMPTY StartedAt, so the current process's logs could not be bounded. Nothing was compared."
      break
    elif [[ $REG_RC -ne 0 ]]; then
      fail "inbox registration: UNKNOWN, not green — the StartedAt/logs read exited $REG_RC: $(head -1 "$WORKDIR/registration.log.err" 2>/dev/null)"
      break
    fi
    REG_STARTED="$(sed -n '1s/^STARTED_AT=//p' "$WORKDIR/registration.log")"
    if [[ -z "$REG_STARTED" ]]; then
      fail "inbox registration: UNKNOWN, not green — the read returned no STARTED_AT header, so what was read is not known to be the current process's log"
      break
    fi
    REG_TEXT="$(sed '1d' "$WORKDIR/registration.log")"
    REG_VERDICT=0
    assert_inbox_registration "$REG_TEXT" || REG_VERDICT=$?
    if [[ $REG_VERDICT -eq 2 && $attempt -lt $READY_ATTEMPTS ]]; then
      warn "inbox registration: not yet — $INBOX_REG_WHY (attempt $attempt of $READY_ATTEMPTS, since $REG_STARTED); sleeping ${READY_SLEEP}s"
      sleep "$READY_SLEEP"
      continue
    fi
    info "StartedAt $REG_STARTED; newest registration line: ${INBOX_REG_LINE:-(none)}"
    case "$REG_VERDICT" in
      0) INBOX_REG="PASS"
         pass "inbox registration: exactly {$INBOX_REG_NAMES} on the newest line of the current process — 01-auto absent (D-21), 03-asis present (CR7-01)" ;;
      1) INBOX_REG="RED"
         fail "inbox registration: RED — $INBOX_REG_WHY. Registered: {${INBOX_REG_NAMES}}; expected exactly {02-review 03-asis}." ;;
      *) INBOX_REG="UNKNOWN"
         fail "inbox registration: UNKNOWN, not green — $INBOX_REG_WHY" ;;
    esac
    break
  done
fi
echo ""

# =============================================================================================
# The `docker exec` wrapper. Named function, recorded route, read-only by contract - the shape
# of zfs_query() in check-music-freeze.sh - grep it for `zfs_query() {`, one hit, the definition
# itself - applied to a container instead of a pool.
#
# Absolute /venv paths and -u beetle are both load-bearing: `beet` is not on PATH for an exec,
# and the exec runs as whatever uid is asked for. No credential is ever passed with -e on a
# docker exec - an exec's environment is visible to anything that can read the daemon.
# =============================================================================================
BEET_EXEC_RC=0
beet_exec() {  # stdout -> $WORKDIR/exec.out ; stderr -> $WORKDIR/exec.err ; rc -> BEET_EXEC_RC
  BEET_EXEC_RC=0
  ssh "${SSH_OPTS[@]}" "root@${LXC_HOST}" \
    "timeout ${REMOTE_TIMEOUT} docker exec ${EXEC_USER_FLAG} ${CONTAINER} $*" \
    >"$WORKDIR/exec.out" 2>"$WORKDIR/exec.err" || BEET_EXEC_RC=$?
}

hash_beets_state() {  # -> stdout: "<sha256>  <path>" lines, or empty
  beet_exec "sha256sum ${LIBRARY_DB} ${STATEFILE}"
  if [[ $BEET_EXEC_RC -eq 0 ]]; then cat "$WORKDIR/exec.out"; fi
}

# =============================================================================================
# 2. ARM 1 — the SERVER-COMMITTED config. THE AUTHORITATIVE ARM.
# =============================================================================================
echo "🅰  2. ARM 1 — the server-committed effective config (CONFIG_ROUTE)"
rule

if [[ "$READY_ROUTE" == "unavailable" ]]; then
  fail "ARM 1: UNKNOWN, not green — the readiness gate never opened, so no exec was issued"
else
  LIB_HASH_BEFORE="$(hash_beets_state | tr '\n' ' ' | tr -s ' ')"
  [[ -z "$LIB_HASH_BEFORE" ]] && LIB_HASH_BEFORE="UNKNOWN"
  info "D-29 layer 3, before: ${LIB_HASH_BEFORE}"

  # The payload is base64'd into the remote command so no quoting layer between bash, ssh, the
  # remote shell and docker exec can mangle it, and so the remote pipeline has NO pipe - which
  # keeps ssh's exit status honest and makes a 124 detectable.
  read -r -d '' PY_ARM1 <<'PYARM1' || true
import beets
from beets_flask.config.beets_config import get_config
get_config(commit_to_beets=True)
print(beets.config.dump(full=True, redact=True))
PYARM1
  PY_ARM1_B64="$(printf '%s' "$PY_ARM1" | base64 | tr -d '\n')"

  beet_exec "${PY_BIN} -c \"import base64;exec(base64.b64decode('${PY_ARM1_B64}'))\""
  if [[ $BEET_EXEC_RC -eq 124 ]]; then
    fail "ARM 1: UNKNOWN, not green — the exec exceeded its ${REMOTE_TIMEOUT}s bound (rc=124). Nothing was read."
  elif [[ $BEET_EXEC_RC -ne 0 ]]; then
    fail "ARM 1: the get_config(commit_to_beets=True) route FAILED (rc=$BEET_EXEC_RC). This is a finding, not a reason to substitute arm 2 — they are different objects."
    echo "      ---- verbatim stderr ----"
    sed 's/^/      /' "$WORKDIR/exec.err" || true
    echo "      -------------------------"
  elif [[ ! -s "$WORKDIR/exec.out" ]]; then
    fail "ARM 1: UNKNOWN, not green — the route exited 0 but produced an EMPTY dump"
  else
    cp "$WORKDIR/exec.out" "$WORKDIR/arm1.dump"
    info "arm1.dump bytes: $(wc -c <"$WORKDIR/arm1.dump" | tr -d ' ')"
    CONFIG_ROUTE="server-committed"
    ARM1_JSON="$(dump_to_json <"$WORKDIR/arm1.dump")"
    if [[ -z "$ARM1_JSON" ]]; then
      fail "ARM 1: UNKNOWN, not green — the dump was read ($(wc -l <"$WORKDIR/arm1.dump" | tr -d ' ') lines) but could not be reduced to a key map"
    else
      ARM1_BLIND=0
      pass "ARM 1 read via CONFIG_ROUTE=${CONFIG_ROUTE} — $(wc -l <"$WORKDIR/arm1.dump" | tr -d ' ') lines, $(printf '%s' "$ARM1_JSON" | jq -r 'keys | length') top-level keys"
    fi
  fi
fi
echo ""

# =============================================================================================
# 3. ARM 2 — the CLI/confuse view, plus the two things only this arm can answer.
#
# `beet config -d` REDACTS fields marked sensitive unless -c/--clear is passed. This repo holds
# no beets credential (Phase 4 D-24), so redaction must be a NO-OP - and that is ASSERTED here
# rather than assumed. A difference between the redacted and unredacted dumps is a credential in
# a config destined for a public repo, and it stops the plan.
# =============================================================================================
echo "🅱  3. ARM 2 — the CLI/confuse view (CONFIG_ROUTE_CLI)"
rule

if [[ "$READY_ROUTE" == "unavailable" ]]; then
  fail "ARM 2: UNKNOWN, not green — the readiness gate never opened, so no exec was issued"
else
  # A no-op overlay: an empty file. The -c overlay sits ABOVE the vendored config, so anything
  # written into it would win; empty is the only value that leaves arm 2 an honest reading of
  # what the container actually assembles.
  #
  # WR-04: the create TRUNCATES, and the result is then MEASURED. `touch` guarantees existence,
  # not emptiness, and this path is a fixed, predictable name inside a world-writable /tmp - so a
  # file left by an aborted run, or written by anything else in the container, would outrank the
  # vendored config and silently rewrite arm 2's answer. An overlay that is merely PRESENT is not
  # an overlay that is EMPTY, and only the second of those is a no-op.
  OVERLAY_TRUNC_RC=0
  beet_exec "sh -c ': > ${OVERLAY}'"
  OVERLAY_TRUNC_RC=$BEET_EXEC_RC
  if [[ $OVERLAY_TRUNC_RC -eq 0 ]]; then
    beet_exec "sh -c 'wc -c < ${OVERLAY}'"
    if [[ $BEET_EXEC_RC -eq 0 ]]; then
      OVERLAY_SIZE="$(tr -d '[:space:]' <"$WORKDIR/exec.out")"
      [[ -z "$OVERLAY_SIZE" ]] && OVERLAY_SIZE="UNKNOWN"
    fi
  fi

  if [[ $OVERLAY_TRUNC_RC -ne 0 ]]; then
    fail "ARM 2: UNKNOWN, not green — could not truncate the no-op overlay ${OVERLAY} (rc=$OVERLAY_TRUNC_RC). No 'config' call was issued."
  elif [[ "$OVERLAY_SIZE" != "0" ]]; then
    fail "ARM 2: UNKNOWN, not green — the no-op overlay ${OVERLAY} measured '${OVERLAY_SIZE}' bytes, not 0. A non-empty overlay outranks the vendored config, so arm 2 would report something other than what the container assembles. No 'config' call was issued."
  else
    pass "ARM 2 no-op overlay ${OVERLAY}: truncated, then MEASURED at ${OVERLAY_SIZE} bytes — nothing in it can outrank the vendored config"
    # D-04: `-l ${THROWAWAY_DB}` on every one of the three invocations below, and `-l` FIRST so
    # the flag order matches the rule as quick-health-check.sh states it. WHY, in three parts.
    # `beet` opens the library for EVERY subcommand including `config` - Phase 1 measured a bare
    # `beet config` running 11 migrations unasked - grep stacks/selfhosted/arrs/beets/beets.yaml
    # for `MIGRATE ITS SCHEMA`, one hit, on the sentence making that claim.
    # With `-l` the real /config/library.db is never opened at all, which upgrades the D-29
    # layer-3 comparison below from proving nothing CHANGED to corroborating that nothing was
    # OPENED. And the overlay is still required alongside it, because `-l` alone does not redirect
    # `statefile:` - that is a separate pickle which `-l` does not cover.
    beet_exec "${BEET_BIN} -l ${THROWAWAY_DB} -c ${OVERLAY} config -d"
    if [[ $BEET_EXEC_RC -eq 124 ]]; then
      fail "ARM 2: UNKNOWN, not green — 'config -d' exceeded its ${REMOTE_TIMEOUT}s bound (rc=124)"
    elif [[ $BEET_EXEC_RC -ne 0 ]]; then
      fail "ARM 2: 'config -d' exited $BEET_EXEC_RC — $(head -1 "$WORKDIR/exec.err" 2>/dev/null)"
    elif [[ ! -s "$WORKDIR/exec.out" ]]; then
      fail "ARM 2: UNKNOWN, not green — 'config -d' exited 0 but produced an EMPTY dump"
    else
      cp "$WORKDIR/exec.out" "$WORKDIR/arm2.dump"
      CONFIG_ROUTE_CLI="confuse"
      ARM2_JSON="$(dump_to_json <"$WORKDIR/arm2.dump")"
      [[ -n "$ARM2_JSON" ]] && ARM2_BLIND=0
      pass "ARM 2 read via CONFIG_ROUTE_CLI=${CONFIG_ROUTE_CLI} — $(wc -l <"$WORKDIR/arm2.dump" | tr -d ' ') lines"
    fi

    # The source-file list: which files confuse actually assembled this from.
    beet_exec "${BEET_BIN} -l ${THROWAWAY_DB} -c ${OVERLAY} config -p -d"
    if [[ $BEET_EXEC_RC -ne 0 || ! -s "$WORKDIR/exec.out" ]]; then
      fail "ARM 2 source list: UNKNOWN, not green — 'config -p -d' exited $BEET_EXEC_RC"
    else
      cp "$WORKDIR/exec.out" "$WORKDIR/arm2.paths"
      pass "ARM 2 assembled from $(wc -l <"$WORKDIR/arm2.paths" | tr -d ' ') file(s):"
      sed 's/^/      /' "$WORKDIR/arm2.paths"
    fi

    # T-06-33: the redaction no-op, asserted.
    if [[ "$CONFIG_ROUTE_CLI" == "confuse" ]]; then
      beet_exec "${BEET_BIN} -l ${THROWAWAY_DB} -c ${OVERLAY} config -d -c"
      if [[ $BEET_EXEC_RC -ne 0 || ! -s "$WORKDIR/exec.out" ]]; then
        fail "T-06-33 redaction no-op: UNKNOWN, not green — the unredacted dump could not be read (rc=$BEET_EXEC_RC)"
      elif cmp -s "$WORKDIR/arm2.dump" "$WORKDIR/exec.out"; then
        REDACTION_VERDICT="no-op"
        pass "T-06-33: the redacted and unredacted dumps are byte-identical — no beets credential exists, asserted rather than assumed"
      else
        REDACTION_VERDICT="DIFFERS"
        fail "T-06-33: the redacted and unredacted dumps DIFFER — that difference is a credential, in a config destined for a public repo. Stop."
      fi
    fi
  fi

  # D-29 layer 3, after. `beet` opens the library for every subcommand, which is why this hash
  # pair was the original evidence that reading a config moved neither the library nor the
  # incremental statefile. With `-l ${THROWAWAY_DB}` now on all three invocations it is no longer
  # carrying that claim alone: the real library should never have been OPENED, and an equal pair
  # here corroborates the redirect. An UNEQUAL pair is still the harder finding of the two.
  LIB_HASH_AFTER="$(hash_beets_state | tr '\n' ' ' | tr -s ' ')"
  [[ -z "$LIB_HASH_AFTER" ]] && LIB_HASH_AFTER="UNKNOWN"
  info "D-29 layer 3, after:  ${LIB_HASH_AFTER}"
  if [[ "$LIB_HASH_BEFORE" == "UNKNOWN" || "$LIB_HASH_AFTER" == "UNKNOWN" ]]; then
    fail "D-29 layer 3: UNKNOWN, not green — one or both hash reads failed, so 'nothing moved' is unproven"
  elif [[ "$LIB_HASH_BEFORE" == "$LIB_HASH_AFTER" ]]; then
    pass "D-29 layer 3: library.db and state.pickle are byte-identical either side of this run"
  else
    fail "D-29 layer 3: library.db and/or state.pickle MOVED across a read-only run"
  fi
fi
echo ""

# =============================================================================================
# 4. Assertions — ALL READ FROM ARM 1, the object that will actually import.
# =============================================================================================
echo "🔎 4. Assertions over the server-committed config (ARM 1 only)"
rule
if [[ $ARM1_BLIND -eq 1 ]]; then
  fail "CONF-01/CONF-02/CONF-05 and the rc6 landmines: UNKNOWN, not green — arm 1 was never read, so nothing below was measured"
else
  assert_effective_config "$ARM1_JSON" "$(cat "$WORKDIR/arm1.dump")"
fi
echo ""

# =============================================================================================
# 5. The two-arm comparison. REPORTED, NOT ASSERTED EQUAL. A difference here is the finding
#    D-30 wants; it is not a failure on its own. The failure conditions are stated in section 4.
# =============================================================================================
echo "⚖️  5. ARM 1 vs ARM 2 — reported, not asserted equal"
rule
COMPARE_KEYS=(
  '.directory' '.library' '.statefile' '.plugins'
  '.per_disc_numbering' '.asciify_paths' '.va_name' '.max_filename_length'
  '.import.copy' '.import.move' '.import.incremental' '.import.incremental_skip_later'
  '.import.duplicate_action' '.import.write'
  '.match.medium_rec_thresh' '.match.preferred.countries' '.match.preferred.original_year'
  '.musicbrainz.extra_tags'
  '.scrub.auto' '.lastgenre.auto' '.embedart.auto'
  '.paths.comp' '.paths.default' '.paths.singleton'
  '.gui.num_preview_workers' '.gui.terminal.start_path'
)
if [[ $ARM1_BLIND -eq 1 || $ARM2_BLIND -eq 1 ]]; then
  warn "comparison: UNKNOWN — arm1_blind=$ARM1_BLIND arm2_blind=$ARM2_BLIND. This is reported, not asserted; section 4 owns the failure."
else
  printf '  %-42s %-28s %s\n' "KEY" "ARM 1 (server-committed)" "ARM 2 (confuse/CLI)"
  for k in "${COMPARE_KEYS[@]}"; do
    v1="$(jget "$ARM1_JSON" "$k | @json")"
    v2="$(jget "$ARM2_JSON" "$k | @json")"
    if [[ "$v1" != "$v2" ]]; then
      DIFF_ROWS=$((DIFF_ROWS + 1))
      printf '  %-42s %-28s %s\n' "$k" "$v1" "$v2"
    fi
  done
  if [[ $DIFF_ROWS -eq 0 ]]; then
    info "the two arms agree on all ${#COMPARE_KEYS[@]} compared keys"
  else
    info "$DIFF_ROWS of ${#COMPARE_KEYS[@]} compared keys differ — expected, and the point of D-30"
  fi
fi
echo ""

# Reported, never asserted: import.write is Phase 7 behaviour. Every Phase 6 invocation
# overrides it to no through a -c overlay, so the EFFECTIVE value under a Phase 6 run is NOT
# the value printed here. The :ro mount (D-05) and the statefile hash (D-29) are the two
# independent controls that do not depend on this key being right.
if [[ $ARM1_BLIND -eq 0 ]]; then
  warn "REPORTED, not asserted: import.write = $(jget "$ARM1_JSON" '.import.write') in the server-committed config. That is Phase 7 behaviour; a Phase 6 invocation overrides it to no through its own -c overlay."
  echo ""
fi

# =============================================================================================
# 6. Summary
# =============================================================================================
echo "📊 6. Summary"
rule
echo "  CONFIG_ROUTE (arm 1):        $CONFIG_ROUTE"
echo "  CONFIG_ROUTE_CLI (arm 2):    $CONFIG_ROUTE_CLI"
echo "  READY_ROUTE:                 $READY_ROUTE"
echo "  inbox registration (WR7-05): $INBOX_REG   (newest line since StartedAt; expected: 02-review 03-asis)"
echo "  arm 1 blind:                 $ARM1_BLIND   (1 = nothing below section 4 was measured)"
echo "  arm 2 blind:                 $ARM2_BLIND"
echo "  inter-arm differences:       $DIFF_ROWS of ${#COMPARE_KEYS[@]} compared keys (reported, not asserted)"
echo "  redaction no-op (T-06-33):   $REDACTION_VERDICT"
echo "  no-op overlay size (WR-04):  $OVERLAY_SIZE   (bytes; anything but 0 refuses arm 2)"
echo "  D-29 before:                 $LIB_HASH_BEFORE"
echo "  D-29 after:                  $LIB_HASH_AFTER"
echo "  toolchain missing:           $TOOLS_MISSING"
echo "  arm-1 assertion failures:    $ARM1_FAILS"
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

echo -e "${GREEN}✅ CONF-01 (copy not move), CONF-02 (incremental AND incremental_skip_later), CONF-05"
echo -e "   (GB not UK, original_year, musicbrainz.extra_tags), the four rc6 schema-default"
echo -e "   landmines, the SAFE-01 three, the OD-2 art and media keys with the exact plugin set,"
echo -e "   and the path stanza are all asserted TRUE of the"
echo -e "   SERVER-COMMITTED config — the object that will actually import.${NC}"
