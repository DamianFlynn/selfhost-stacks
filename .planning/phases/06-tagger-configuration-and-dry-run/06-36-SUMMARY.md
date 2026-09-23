---
phase: 06-tagger-configuration-and-dry-run
plan: 36
subsystem: verification-instruments
tags: [oracle, self-test, awk, gap-closure, round-4]
gap_closure: true
gap_closure_round: 4
closes_findings: [R4-02, R4-06, R4-09, R4-10]
requires:
  - "scripts/phase06-oracle.sh as plan 06-34 left it (round 3 complete)"
provides:
  - "a skip-aware announced-case gate whose base is valid in a NAMED reference environment"
  - "six st_case assertions pinning the layer-3 sha256 line parser, including an identity case"
  - "the four layer-3 consumers taking the requested path through ENVIRON, not awk -v"
  - "an in-band statement of the could-not-look cleanup gap at R3-04's two exit 3 arms"
affects:
  - "scripts/phase06-oracle.sh --self-test on root and python3-less workstations"
tech-stack:
  added: []
  patterns:
    - "environment-conditional self-test skips adjust the announced count at their own site"
    - "an identity case pins a driven program text to its live copies, counted on a live-only marker"
    - "awk ENVIRON[] instead of -v for values that must not take escape processing"
key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-36-oracle-pin-parser-and-cleanup.txt
  modified:
    - scripts/phase06-oracle.sh
decisions:
  - "R4-10 closed as a CLAIM CORRECTION with no trap added: a cleanup trap would fire on the forensic exit 3s too"
  - "the announced-case base stays a typed number, but is now typed for a NAMED environment and adjusted mechanically for every departure from it"
  - "the st_grep_why preamble was reworded to stop being a permanently-hit detector for its own prohibition"
metrics:
  duration: "~45 min"
  completed: 2026-09-23
  tasks: 3
  commits: 3
---

# Phase 06 Plan 36: Oracle pin, layer-3 parser and cleanup gap — Summary

Closed the four round-4 findings that land in `scripts/phase06-oracle.sh`: the announced-case pin
now self-adjusts at each deliberate skip and its gate stops asserting a cause it cannot know; the
layer-3 sha256 line parser gained six cases in the pinned set including an identity case pinned to
the four live consumers; those consumers now take the requested path through `ENVIRON` rather than
`awk -v`; and the could-not-look cleanup gap is stated in band, graded as pre-existing, with no
trap added.

## Finding IDs are ALIASED this round

Round 4's report reuses round 1's `WR-*` / `IN-*` namespace, and `WR-02` and `WR-06` already mean
something else **in band in this very file**. Everything written into the script and the artifact
uses `R4-*`:

| Round-4 report ID | In-band ID | Fix type | Subject |
|---|---|---|---|
| WR-02 | **R4-02** | **BOTH** | `ST_PLANNED_CASES=134` not invariant over the self-test's own documented skips |
| WR-06 | **R4-06** | **CODE** | the sha256 line parser had no case in the set R3-02 pinned in the same round |
| IN-03 | **R4-09** | **CODE** | `awk -v p=` applies escape processing to an overridable knob |
| IN-04 | **R4-10** | **CLAIM CORRECTION** | R3-04's two `exit 3` arms leave the scratch and stamp behind, unstated |

## What was done

### R4-09 — CODE (task 1, commit `fa6204a`)

All four layer-3 consumers changed from `LC_ALL=C awk -v p="$REAL_LIB_DB" '… rest == p …'` to
`LC_ALL=C p="$REAL_LIB_DB" awk '… rest == ENVIRON["p"] …'`. `awk -v` runs the value through escape
processing before the program sees it, so a backslash-bearing knob was compared in a form the
operator never typed. Changed at **all four** sites for R3-03's own reason: four consumers of one
output format must not carry two parsers.

Bounded in band rather than inflated: the old form already **failed closed** (mangled comparison →
empty hash → `unknown` → `exit 3`), so this buys correctness for a backslash-bearing knob, not a
new safety property. R3-03's deliberate refusal of GNU sha256sum's escaped **output** form is
untouched — `ENVIRON` changes how the *requested* path arrives, not how the *printed* line is read.

Driven both directions on the backslash case (artifact § 1, probe 7): under `ENVIRON` it matches,
under the old `-v` form it does not.

### R4-10 — CLAIM CORRECTION ONLY (task 1, commit `fa6204a`)

An in-band note at R3-04's two `exit 3` guards, graded as the review graded it: the class is
**pre-existing** and shared with the two `exit 3` arms immediately above; leaving state behind on a
could-not-look is arguably right for a forensic instrument; the two leftovers are named
(`$SCRATCH`, `$STAMP_REMOTE`); and the operator clean-up command is **cited by anchor** — the
step-1 precheck's `'nonempty '*` refusal arm — rather than duplicated, because two copies of a
destructive command line in one file is how GC-02's fences drifted apart in this very file.

**No trap added.** `grep -c '^[[:space:]]*trap '` is still 0.

### R4-06 — CODE (task 2, commit `5c7eac6`)

Six `st_case` assertions in `self_test_vacuity` over **one non-empty fixture**, so every refusal is
a refusal over a file whose other lines the positives matched:

1. a path containing a **space** matched exactly (the case R3-03 exists for)
2. a path containing a **backslash** matched exactly (R4-09 driven)
3. a **GNU backslash-escaped** line refused (R3-03's deliberate refusal, now pinned as intended)
4. a **suffix-only near-miss** refused (exact equality, never a suffix test)
5. a **truncated** line refused (the emptiness guards still fire)
6. the **identity case**: exactly 4 lines of this script carry both the driven program text and
   the live-only `"$OUT/layer3.` marker

The identity case counts on the live-only marker **as well as** on the program text, deliberately:
the self-test's own copy is in the same file, so a bare count would have been self-referential and
would have moved the moment the block was added — the defect GC-10, R3-05 and R4-05 each are. It
resolves the script path **fail-closed**: unreadable prints a `warn`/`info` pair and is driven RED
with `COULD-NOT-LOOK`, never a silent pass. The four live copies were **not** hoisted into one
shared variable, per `DEF-06-29-03`.

**Driven to FAIL on four scratch copies.** Mutating one live consumer's field index, its two-space
separator, or its hex class each takes the identity case 4 → 3 and prints `SELF-TEST REGRESSION`.
Those are the exact three edits the review said currently go green.

### R4-02 — BOTH (task 3, commit `ef8181f`, run LAST)

**The before state, reproduced against the plan's own base commit `24d6624`:**

| Condition | Result |
|---|---|
| this workstation | rc=0, 134 cases |
| `python3` absent | rc=1, `132 case(s) ran but 134 were announced - A SECTION DID NOT RUN` |
| as root (both arms) | rc=1, `129 … - A SECTION DID NOT RUN` |
| `self_test_fences` dropped | rc=1, `111 … - A SECTION DID NOT RUN` |

The same message for two deliberate skips and one genuinely dropped section. The gate could not
tell them apart and told the operator it could.

**CODE:** each of the three environment-conditional arms now decrements `ST_PLANNED_CASES` beside
the `warn` that reports its skip.

**CLAIM 1:** the base is re-measured and the environment it is valid in is named in band.
**CLAIM 2:** the gate names three causes it cannot distinguish, rules out the deliberate skip, and
keeps its existing virtue of withholding the banner rather than printing an unbacked claim.

## The measured numbers, stated explicitly

**All deltas measured by ABLATION**, not counted by eye — `st_mc`, `st_assert` and `st_grep_why`
all funnel into `st_case`, so lines and cases are not the same thing. Each arm was forced to take
its skip branch on a scratch copy and `ST_RUN` read off the gate's own output.

| Arm | Forced `ST_RUN` | Delta |
|---|---|---|
| *(base — no arm forced)* | **140** | — |
| `self_test_core` — root, mode-000 manifest | 139 | **1** |
| `self_test_classes` — no `python3` | 138 | **2** |
| `self_test_vacuity` — root, present-but-unreadable | 136 | **4** |
| both root arms | 135 | 5 (= 1+4) |
| all three | 133 | 7 (= 1+2+4) |

Additive, which is the property that makes three independent decrements correct. 1 / 2 / 4 also
matches the review's table, measured independently.

**Re-measured base: `ST_PLANNED_CASES = 140`** (134 + the six cases task 2 added).

**The environment it was measured in — the REFERENCE ENVIRONMENT, named in band beside the
constant:** macOS 27.0 (darwin), **non-root (uid 501)**, **`python3` PRESENT**, bash, BSD grep at
`/usr/bin/grep`, BWK awk. The figure was **not** copied from the plan, from `06-REVIEW-GAP3.md` or
from `06-DISPOSITIONS-GAP2.md` — all three record 134, and task 2 moved it.

## The non-vacuity control, which is the drive that matters

Dropping `self_test_fences` from the dispatcher still exits **1** (`117 case(s) ran but 140 were
announced`), and deleting one `st_case` from an unconditional section still exits **1** (139 vs
140). Had either gone green, the skip-awareness would have disabled the guard it replaced and the
green root / python3-less runs would have been satisfied by a gate that no longer gates anything.
A deliberate skip adjusts the announcement; a dropped section adjusts **nothing**.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] `| grep -q` count was already 1 pre-fix, and the hit was the comment forbidding it**
- **Found during:** Task 2
- **Issue:** Task 2's verify requires `/usr/bin/grep -cF '| grep -q' scripts/phase06-oracle.sh` to
  be **0**. Pre-fix it was **1**. The single hit was not a live pipeline — it was the `st_grep_why`
  preamble, whose subject is that this shape must not be used. The verify could never have passed.
- **Fix:** Reworded the sentence to describe the construction in words instead of quoting it, and
  added an in-band note saying so and saying why. This is the reasoning the file already applies to
  the retired bare-glob fences ("A permanently-hit grep is a broken detector", GC-02 block). No
  executable line changed; the detector discriminates again.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Commit:** `5c7eac6`

**2. [Rule 3 — Blocking] the plan's `0,/re/` sed mutation is a GNU extension that BSD sed silently no-ops**
- **Found during:** Task 2
- **Issue:** Task 2's verify mutates with `/usr/bin/sed '0,/print \$1 }/s//print $2 }/'`. `0,/re/`
  is a GNU sed extension. BSD sed — `/usr/bin/sed` on this macOS workstation — accepts it **without
  complaint and substitutes nothing**: rc 0, output byte-identical to input, no diagnostic.
  Measured. The block's very next line is `! cmp -s`, so under `set -e` it aborts there and the
  mutation drive never runs. `1,/re/s//…/` is worse — BSD's empty-RE reuse mangles the whole file.
  No `gsed` is installed.
- **Fix:** Substituted a first-match-only `awk` with identical semantics that **exits 9 if it
  matches nothing**, so a no-op mutation is loud rather than silent. Recorded in the artifact § 3
  with the control transcript, because a mutation that silently does nothing is exactly the failure
  class this round is about.
- **Files modified:** none shipped (verify-harness only)
- **Commit:** `5c7eac6` (documented in the artifact committed there)

**3. [Rule 3 — Blocking] `cd "$(git rev-parse --show-toplevel)"` resolved literally in the executed verify blocks**
- **Found during:** pre-fix verification
- **Issue:** The execution sandbox refuses to run a shell script it cannot statically prove does
  not invoke git outside its own worktree, so the verify blocks could not be executed as written.
- **Fix:** The first line was resolved to the literal worktree root, which **is**
  `git rev-parse --show-toplevel` in this checkout — a semantic no-op. Recorded in artifact § 0
  because the traces show the literal path.
- **Files modified:** none

### Notes on plan predictions that were slightly off

- The plan predicted task 2's verify block would fail pre-fix at the `ENVIRON["p"] >= 5` test. It
  failed one test **earlier**, at the `R4-06` marker count, because that test is first in the
  block. Both are pre-fix-false; the block is non-vacuous either way.
- The plan's mutant A ("the FIRST live consumer") is in fact the **driven copy** at
  `self_test_vacuity`, because the self-test section precedes the live block in the file. Three
  additional mutants were run against genuine live consumers to get the property the acceptance
  criterion actually wants; all four are recorded.

## Verification

| Block | Pre-fix | Final |
|---|---|---|
| Task 1 | rc=1 at the first test (`awk -v p=` count was 2, wanted 0) | **rc=0** |
| Task 2 | rc=1 at the first test (`R4-06` count was 0) | rc=1 — **by design, at one line only** |
| Task 3 | rc=1 at the first test (decrement count was 0, wanted ≥3) | **rc=0** |

Task 2's block is **time-ordered**: it asserts the self-test exits 1 at the announcement gate
because task 3 has not run yet. It passed when it was task 2's turn. After task 3 re-measured the
pin the self-test exits 0 and that one assertion inverts; re-running the block with **only** the
two time-ordered lines inverted gives rc=0, proving every static test and the mutant drive still
hold. Traced and recorded in artifact § 6.

`bash -n scripts/phase06-oracle.sh` exits 0. `--self-test` exits 0 at 140 cases.
`git diff --name-only -- scripts/` lists only `scripts/phase06-oracle.sh`.

**No estate contact anywhere.** Every transcript is `--self-test`, `awk` over a `mktemp -d`
fixture, or `grep` over the script. No ssh, no docker, no `--run`, no `--arm`.
`scripts/phase06-oracle.sh` was never mutated in place. `scripts/check-beets-config.sh` (plan
06-38's file this round), `scripts/setup-neocortex-memory.sh`, `stacks/selfhosted/neocortex-memory/`
and `stacks/selfhosted/agentic-os/` were not touched. `06-VERIFICATION.md` was not read or touched.
**No requirement checkbox moved. CONF-04 is not closed. The phase is not declared complete.**

## NOT-DRIVEN register

- **THE LAYER-3 BLOCK ITSELF.** Steps 3 and 9 are reachable only from a live `--run`, which this
  phase does not perform. The six new cases prove **the parser** over synthetic `sha256sum` output;
  they do **not** prove the block, the remote `sha256sum` invocation, `dex_cmd`'s rendering, or
  that the container's `sha256sum` prints the `<hash><SP><SP><path>` form these fixtures assume.
- **THE `exit 3` ARMS, EXECUTED.** R4-10 is a claim correction: the guards were read, not run.
  That the scratch and stamp survive such an exit is reasoned from step 12 being below them in a
  straight-line script with no `trap` — verified by grep, not by an interrupted live run.
- **ROOT, GENUINELY.** The root drives force the `[ "$(id -u)" = "0" ]` test on scratch copies.
  Nothing ran as uid 0. Proven: the skip branch self-adjusts. Not proven: that a real root run has
  no other behavioural difference.
- **`python3` GENUINELY ABSENT.** The `command -v python3` test was ablated, not the interpreter
  removed. The review used a stripped PATH and got the same shortfall.
- **A FOURTH ENVIRONMENT-CONDITIONAL SKIP.** If one is added and its author forgets the decrement,
  the gate fires with the corrected three-cause message — which points at the right question — but
  nothing detects the omission itself. The verify's `-ge 3` is a floor, not a census.
- **THE SIBLING.** `scripts/check-beets-config.sh` carries the same `ST_PLANNED_CASES` idiom with
  an unconditional set of 7; plan 06-38 owns it this round. Not read, not run, not touched.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change at a trust boundary
was introduced. The only shipped behaviour changes are inside `--self-test` (which contacts
nothing) and the form in which an already-fenced, already-`%q`-rendered path crosses into `awk`.

## Commits

| Commit | Task | Subject |
|---|---|---|
| `fa6204a` | 1 | layer-3 paths cross into awk via ENVIRON; the could-not-look cleanup gap stated (R4-09, R4-10) |
| `5c7eac6` | 2 | drive the layer-3 sha256 parser in the pinned set; pin the driven text to the shipped text (R4-06) |
| `ef8181f` | 3 | the announced case count adjusts where the skip is decided; the gate stops asserting one cause (R4-02) |
| `003a317` | — | this SUMMARY |

## Self-Check: PASSED

All three claimed files exist on disk; all four claimed commits are in `git log`. Working tree is
clean apart from this appended self-check. `STATE.md` and `ROADMAP.md` are **unmodified** — the
orchestrator owns those writes after the wave merges.
