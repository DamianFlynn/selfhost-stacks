---
phase: 06-tagger-configuration-and-dry-run
plan: 20
subsystem: testing
tags: [bash, shellcheck, set-e, argument-parsing, negative-control, beets, phase06-incremental-control]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "scripts/phase06-incremental-control.sh, the CONF-02 proof committed against it in 06-VERIFICATION.md, and the IN-02/IN-05/IN-08/IN-10 findings in 06-REVIEW.md"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "scripts/phase06-oracle.sh as plan 06-18 left it — the sibling whose UNKNOWN-before-RED ordering is adopted here"
provides:
  - "A usage error that exits 3 with a message instead of exiting 1 in silence: no `shift 2` remains in the dispatch, and the documented exit-code table and the behaviour now agree"
  - "classify_reoffer(): the step-4 re-offer classifier, lifted out of run_arm so it can be fed a transcript, reading any integer path count"
  - "arm_verdict(): the RED-vs-UNKNOWN precedence as a single driveable function, blind consulted first, matching phase06-oracle.sh"
  - "An EXIT CODES block that states the precedence convention, its reason and names the sibling, bounded by a `# =` delimiter"
  - "--self-test grown from 5 to 7 sections: 6/7 drives the widened classifier as a pair, 7/7 drives the full 2x2 precedence truth table"
  - "artifacts/06-20-incremental-driven.txt: four offline argument drives behind an unreached ssh/docker shim, the IN-10 before/after table, nine driven-red mutations, and a six-item NOT-DRIVEN register"
affects: [06-19, 06-21, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shift once unconditionally, take the value only if one is present: `shift 2` under `set -e` converts a usage error into a measured verdict, silently"
    - "Factor a classifier out of its caller so a synthetic input can reach it — a classifier that is only reasoned about is an assumption"
    - "Widen a pattern as a PAIR: prove the new case classifies AND the old case is unchanged, or the widening is a regression"
    - "Delete a dead narrow classifier rather than route callers through it, when the inline test it would replace is strictly wider"
    - "Extract a bounded header block to a FILE and grep the file: never let a pipeline carry a verdict (the same rule the script applies to its remote commands)"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-20-incremental-driven.txt
  modified:
    - scripts/phase06-incremental-control.sh

key-decisions:
  - "IN-02 resolved by DELETING remote_is_blind() rather than routing callers through it: the function tested RE_RC in {124,2,255} while every caller tests `-ne 0`, which also catches 1/125/126/127. Adopting the narrow test would have been a regression dressed as a cleanup on an instrument whose value is failing closed. The comment left at the old site deliberately does not spell the identifier, so the grep guard keeps reading 0."
  - "The step-4 classifier was lifted into classify_reoffer() rather than widened in place: while inline it could only be reasoned about, never fed an input, and task 2 required a driven IN-10 control."
  - "The exit-code NUMBERING difference between the two scripts (here UNKNOWN=2/usage=3; oracle UNKNOWN=3/usage=2) was deliberately NOT harmonised. IN-08 reports the PRECEDENCE disagreement, which is now fixed; renumbering would invalidate committed evidence that cites these codes."
  - "scripts/phase06-oracle.sh was deliberately not touched. It already IMPLEMENTS the convention (verified at :2394/:2398); STATING it there and naming this script back is plan 06-19's task and that plan owns the file. Editing a sibling plan's file from a parallel worktree is how a wave produces a merge conflict."
  - "`--arm a` was driven to the LOCAL source-fence refusal rather than via an impossible host/container override, because no such override exists by design — the header records that LXC_HOST, CONTAINER and the real paths are plain constants precisely because an override could manufacture a pass."
  - "No arm was run against the live estate. CONF-02's committed proof is unchanged and was not re-taken."

patterns-established:
  - "PATH shim proof: an `ssh`/`docker` stub that refuses and marks stderr, so 'this refused before any remote call' is instrumented rather than reasoned about"
  - "Mutation testing of the plan's own verify: every assertion re-run against a mutated copy and required to fire before it is trusted"
  - "A guard that fires on your own test fixture is right: fix the fixture (pass the varying value as a printf argument), never relax the guard"

metrics:
  duration: ~50 min
  tasks: 2
  files-created: 1
  files-modified: 1
  completed: 2026-09-22
---

# Phase 6 Plan 20: Aligning the incremental negative control Summary

**One-liner:** Closed four findings on `phase06-incremental-control.sh` — a usage error that exited 1 in silence now exits 3 loudly, the re-offer classifier reads any path count instead of silently going blind on the override it is offered on, the dead blindness classifier is gone, and the RED-vs-UNKNOWN precedence now matches the oracle and says so — every changed branch driven offline with no arm run.

## What was done

### Task 1 — the usage exit, the classifier width, the dead name (commit `18b25e0`)

**IN-05.** `--arm) MODE="arm"; ARM="${2:-}"; shift 2 ;;` — with one argument left, `shift 2`
returns non-zero, `set -e` terminates the script with status **1**, and nothing is printed. 1 is
the code the EXIT CODES block reserves for *"the arm produced the OPPOSITE outcome"*, so a
mis-typed invocation read as a measured negative. The table was already right; the behaviour was
wrong, so the behaviour changed. The dispatch now shifts once unconditionally, takes a value only
if one is present, and validates it against `a|b`. Both failure modes route through a new
`usage_error()` that writes to stderr and exits 3.

The plan asked for an audit of every other `shift 2` in the dispatch: `--arm` was the only one.
The idiom is now absent from the dispatch entirely, and the verify asserts that.

Measured before/after:

| | exit | stdout | stderr |
|---|---|---|---|
| pre-fix shape, `--arm` with no value | 1 | — | — (silent) |
| post-fix, `--arm` with no value | 3 | — | `--arm requires a value; the legal values are 'a' and 'b'` |
| post-fix, `--arm zzz` | 3 | — | `'zzz' is not a legal arm; the legal values are 'a' and 'b'` |

**IN-10 — the sharpest of the four.** The step-4 re-offer classifier matched the literal
`Skipped 1 paths.`. Any `SRC_FOLDER` yielding two albums prints a different count and fell
through to `indeterminate`, which the caller routes to **BLIND**. So the negative control did not
fail on a multi-album source — it *stopped discriminating while still appearing to run*, for
exactly the case the offered `SRC_FOLDER` override invites.

The count is now read as any non-negative integer. Only the count widened; the three outcomes and
the `indeterminate` fall-through for genuinely unrecognised output are unchanged, and a comment
records why the count is not pinned. The classifier was also **lifted out of `run_arm` into
`classify_reoffer()`** — while it was inline it could only be reasoned about, never fed an input,
and task 2 required it driven.

Driven as a pair, because widening a pattern and only proving the new case is how a widening
becomes a regression:

| transcript | OLD (pinned to 1) | NEW (any count) | effect |
|---|---|---|---|
| count 1 | `not-offered` | `not-offered` | unchanged — no regression |
| count 2 | `indeterminate` | `not-offered` | FIXED |
| count 17 | `indeterminate` | `not-offered` | FIXED |
| `Album:` only | `offered` | `offered` | unchanged |
| both markers | `contradictory` | `contradictory` | unchanged |
| unrecognised | `indeterminate` | `indeterminate` | unchanged |
| EMPTY | `indeterminate` | `indeterminate` | unchanged — does not pass vacuously |

The `blind` message in `run_arm` was reworded from `neither 'Skipped 1 paths.' alone` to
`neither a 'Skipped N paths.' line alone`, because a message a reader takes as the rule must not
describe a rule the code no longer applies.

**IN-02 — deleted, not routed through.** `remote_is_blind()` tested `RE_RC` in `{124, 2, 255}`
and nothing called it; every caller tests `[ "$RE_RC" -ne 0 ]`, which also catches 1, 125, 126
and 127. Routing the callers through it would have narrowed the blindness test on an instrument
whose entire value is failing closed — a regression dressed as a cleanup. The wider inline test
stays; the dead name is gone; a comment at the old site records the reason and the rule for any
future helper (at least as wide as `-ne 0`, and called). Occurrences of the identifier: **1 → 0**.

### Task 2 — the precedence, stated and driven (commit `1bcf229`)

**IN-08.** The two instruments written in this phase disagreed on which verdict wins when a run
both measures a failure and has an instrument that could not look. The oracle's order is adopted
as the house convention — **a blind instrument outranks a measured red** — because this estate's
standing rule is that "could not look" is never folded into another verdict: reporting a red
while an instrument was blind asserts a cause the run did not establish.

The verdict tail of `run_arm` was factored into `arm_verdict()` so the ordering is a named,
driveable decision rather than two lines of tail:

```
scripts/phase06-incremental-control.sh:588   if [ "$unknown" -ne 0 ]  -> exit 2 (UNKNOWN)
scripts/phase06-incremental-control.sh:592   if [ "$failed"  -ne 0 ]  -> exit 1 (FAIL)

scripts/phase06-oracle.sh:2394               if [ "$UNKNOWNS" -ne 0 ] -> exit 3 (UNKNOWN)
scripts/phase06-oracle.sh:2398               if [ "$REDS"     -ne 0 ] -> exit 1 (RED)
```

Neither condition's meaning nor its exit code changed — only which is consulted first — and a
comment records that the two are **not mutually exclusive**, which is why the order is a decision.

The EXIT CODES block now states the convention, the one-sentence reason and names
`scripts/phase06-oracle.sh`, and a `# ====` delimiter closes the block so it is a bounded object
(23 lines) rather than "everything to EOF".

`--self-test` grew from 5 sections to 7, banner counts updated in the same edit:
- **6/7** the re-offer classifier over seven synthetic transcripts (the IN-10 pair plus the three
  unchanged outcomes and an empty transcript that must not pass vacuously);
- **7/7** the full 2×2 precedence truth table, including the two the plan required — both
  conditions → blind wins, red-only → red stands.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Task 2's own `<verify>` block was a false-RED generator**

- **Found during:** Task 2, running the plan's verify verbatim against the finished file.
- **Issue:** `awk "/EXIT CODES/,/^# =/" "$f" | grep -qiE "outranks|wins" || { exit 1; }` under
  `set -o pipefail`. `grep -q` exits on first match, awk takes SIGPIPE, pipefail propagates
  **141**, so the `||` branch fires exactly when the convention *is* stated. Compounded by the
  range being unbounded — the script had no `^# =` line at all, so awk emitted 933 lines,
  guaranteeing the SIGPIPE; and because "EXIT CODES" is referenced from two body comments, a
  plain awk range restarts at each mention, so adding one delimiter is not sufficient alone.
- **Measured, on the correct file:** `grep -ciE 'outranks|wins'` over the extracted block → **5
  matches**; `grep -c 'phase06-oracle'` → **2**; the piped form → **rc 141**. The plan's verify
  run verbatim printed `IN-08: the precedence convention is not stated`.
- **Fix (strengthened, not weakened):** (a) a `# ====` delimiter closes the block in the script;
  (b) the extraction takes only the **first** block and stops; (c) the block is written to a file
  and grepped there, so no pipeline carries a verdict — the same rule the script already applies
  to its remote commands; (d) a **new** assertion that the block is non-empty and under 60 lines,
  so a future removal of the delimiter is caught rather than silently restoring the unbounded
  range. Two further assertions were added while there: the blind condition's line number must be
  lower than the measured-failure one **in both scripts**, and `--self-test` must show both named
  precedence cases and report no regression.
- **Driven red by:** mutations B (strip the convention wording → fires) and C (remove the sibling
  pointer → fires).
- **Commit:** `1bcf229`

The corrected command (run clean, rc 0):

```bash
awk '/EXIT CODES/ && !st { st=1 } st { print } st && /^# =/ && !/EXIT CODES/ { exit }' "$f" > "$t/blk"
bl=$(wc -l < "$t/blk" | tr -d ' ')
[ "$bl" -gt 0 ] || { echo "IN-08: the EXIT CODES block could not be extracted"; exit 1; }
[ "$bl" -lt 60 ] || { echo "IN-08: the block is unbounded ($bl lines) - the '# =' delimiter is gone"; exit 1; }
grep -qiE "outranks|wins" "$t/blk" || { echo "IN-08: the precedence convention is not stated"; exit 1; }
grep -q "phase06-oracle"   "$t/blk" || { echo "IN-08: the sibling is not named"; exit 1; }
lu=$(grep -n 'unknown" -ne 0' "$f" | head -n 1 | cut -d: -f1)
lf=$(grep -n 'failed" -ne 0'  "$f" | head -n 1 | cut -d: -f1)
[ "$lu" -lt "$lf" ] || { echo "IN-08: the blind condition ($lu) is not before the measured failure ($lf)"; exit 1; }
```

**2. [Rule 1 — Bug] Task 1's verify hardened against the same shape**

- **Issue:** two `printf "%s\n" "$s" | grep -q ...` pipelines under `pipefail`. Measured on this
  workstation they returned 0 rather than 141 (bash's `printf` builtin survives the EPIPE where
  `awk` does not), so task 1 passed both as written and as hardened — but it is the same shape
  and one bash version away from the same defect.
- **Fix:** the comment-stripped text is written to a file and grepped there; no pipeline carries a
  verdict. Semantics unchanged, and all four static assertions were driven red (mutations 1–4).

**3. [Rule 1 — Bug] The IN-10 guard fired on this plan's own self-test fixture**

- **Found during:** Task 2, first run of the corrected verify: `IN-10: the hard-coded path count
  survives`.
- **Issue:** putting the IN-10 pair into `--self-test` — which the plan only required in the
  artifact — meant a fixture line spelled `Skipped 1 paths.`, tripping task 1's "no such literal
  remains anywhere in the file" assertion.
- **Fix:** the guard was **not** relaxed. The fixture now passes its count as a `printf`
  argument, in a loop over 1, 2 and 17, so the only place a count can be written literally in
  this file is a match pattern — which is exactly what IN-10 forbids. Self-test coverage kept,
  guard keeps its teeth.
- **Commit:** `1bcf229`

### Deliberate scope boundaries (not deviations)

- **`scripts/phase06-oracle.sh` was not touched.** It already implements the convention; stating
  it there and naming this script back is plan **06-19**'s task (wave 7), and that plan owns the
  file. The plan-level verification line *"both EXIT CODES blocks state the same convention and
  name each other"* therefore completes at 06-19, not here. Until then the convention is
  implemented in both and stated in one.
- **The exit-code numbering difference** (here UNKNOWN=2/usage=3, oracle UNKNOWN=3/usage=2) was
  left alone. IN-08 reports the precedence disagreement, which is fixed; renumbering would
  invalidate committed evidence citing these codes. Recorded in the artifact so the next reader
  does not mistake it for a finding.
- **The plan's line citations were stale on arrival**, as expected in this wave: it cited
  `phase06-oracle.sh:2160-2175` for the sibling verdict logic, which after plan 06-18's merged
  changes is at `:2394-2401`. The current file was read, as the prompt directed.

## Authentication gates

None. No credential was needed and none was used: every drive is local.

## Verification

| Check | Result |
|---|---|
| `bash -n` | exit 0, no output |
| `shellcheck -S warning` | exit 0, no output (0.11.0) |
| `--self-test` | exit 0, 7/7 sections, zero regressions |
| `--arm` (no value) | exit **3**, non-empty stderr |
| `--arm zzz` | exit **3**, non-empty stderr |
| `--arm a` (source outside the fence) | exit **3** at preflight 1, ssh/docker shim never reached |
| `grep -c '\bremote_is_blind\b'` | **0** (was 1 — the finding's signature) |
| `shift 2` in the dispatch | none |
| `Skipped 1 paths` literal | none |
| blind condition before measured failure | `:588` < `:592`, matching oracle `:2394` < `:2398` |
| corrected verify, tasks 1 and 2 | both OK, rc 0 |

Nine driven-red mutations, each made to fail before the assertion was trusted: four static
(IN-10 ×2, IN-02, IN-05), one behavioural (the pre-fix dispatch shape → exit 1, silent), one
ordering (pre-fix verdict order → `--self-test` rc 1, 1 regression), two documentary (convention
wording stripped, sibling pointer removed), plus the bounded-block control.

## NOT DRIVEN

Carried into plan 06-21's disposition register. Full text in
`artifacts/06-20-incremental-driven.txt` § 9.

1. **`--arm a` / `--arm b` past preflight 1** — every remote step is undriven by this plan, by the
   plan's own constraint. Both arms perform a real `beet import` on LXC 100. CONF-02's committed
   proof covers them and was not re-taken. Driving it is a measurement decision, not a
   verification step.
2. **`contradictory` and `indeterminate` as reached from a real beets transcript** — driven here
   over synthetic transcripts only, which is the honest level available offline.
3. **`remote_exec`'s blindness statuses (124/255/125/126/127) from a real remote call** — the
   `-ne 0` test that classifies them is unchanged and was already in force. The precedence they
   feed *is* driven, at the `arm_verdict` level, with `unknown=1` supplied directly.
4. **`--baseline` and `--cleanup`** — both reach the network on their first statement; untouched.
5. **The oracle half of IN-08** — stating the convention in `phase06-oracle.sh`. Plan 06-19.
6. **The exit-code numbering difference** — not a finding, not addressed, recorded so it is not
   mistaken for one.

## Known Stubs

None.

## Threat Flags

None. This plan touches no network endpoint, no auth path and no schema; it removed a dead
function, widened one regex, reordered two conditions and made a usage error loud. The one
behavioural surface it changes — `--arm` argument validation — moved strictly toward refusing,
and the source fence, the one-key overlay refusal and the dirty-destination refusal are all
unchanged and still driven by `--self-test`.

## Commits

| Task | Commit | Summary |
|---|---|---|
| 1 | `18b25e0` | usage error exits 3 loudly; classifier reads any path count; dead classifier deleted |
| 2 | `1bcf229` | blind outranks measured red, stated in EXIT CODES and driven by two new self-test sections; artifact |
| — | `b86b570` | this summary |

## Self-Check: PASSED

Every file and commit this summary claims was checked on disk and in the log, not asserted.

- `scripts/phase06-incremental-control.sh` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-20-incremental-driven.txt` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/06-20-SUMMARY.md` — FOUND
- commit `18b25e0` — FOUND
- commit `1bcf229` — FOUND
- commit `b86b570` — FOUND

`git diff --diff-filter=D 015f5c1..HEAD` lists **no deletions** — nothing was removed from the
tree by this plan. `git status --porcelain` is empty: no debris, no uncommitted work.

The corrected verify for both tasks was re-run against the committed state: `06-20 task 1 OK`,
`06-20 task 2 OK`, rc 0.

No file outside `scripts/phase06-incremental-control.sh` and this phase's `.planning/` directory
was touched. `STATE.md` and `ROADMAP.md` were deliberately not modified — the orchestrator owns
those writes after the wave merges.
