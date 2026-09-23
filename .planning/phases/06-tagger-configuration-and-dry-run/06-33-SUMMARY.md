---
phase: 06-tagger-configuration-and-dry-run
plan: 33
subsystem: phase-06 instruments
tags: [gap-closure, round-3, wave-14, self-test, announced-vs-actual, vacuity, d-04, r3-07, r3-08]
gap_closure: true
gap_closure_round: 3
wave: 14

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "round 2 landed (06-22..06-29), so GC-13's gate and its note are in place and are what this plan corrects"
provides:
  - "case 6 of check-beets-config.sh --self-test announces the gate it actually has; the ungated expected-red count is gone and the success line prints the two values the gate reads"
  - "the third-conjunct alternative recorded in band as considered and refused, with the reason (implied by the other two conjuncts, therefore vacuous)"
  - "GC-13's justification no longer rests on a reason that does not apply, and gives a comment-stripped census recipe in place of a number"
  - "the inverted arm polarity of assert_beet_invocation_contract recorded at the site under the greppable opening IF THIS FUNCTION IS EVER CALLED LIVE"
  - "a drive that shows the R3-08 defect before it was removed: 'expect 1 red' over '2 red, as expected', green, exit 0"
affects: [phase-06 review round 4]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "an announcement nothing compares is a repudiation defect even when it is currently true — remove the announcement or gate it, never leave it decorative"
    - "a conjunct implied by the conjuncts beside it can never independently fail; adding one to close a finding about honest announcements trades one defect class for a worse one"
    - "record a REFUSED alternative with its reason at the site, or the next reader restores it as an obvious omission"
    - "a raw grep count is not a call-site census: it matches the comments that discuss the function, including the comment that reports the census"
    - "pin the comment-stripped count when the change itself adds prose naming the symbol — a raw pin fails the correct fix"
    - "prove a comment-only claim twice: zero non-comment lines in the diff AND byte-identical program output across it"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-33-checker-case6-and-contract.txt
  modified:
    - scripts/check-beets-config.sh

key-decisions:
  - "R3-08 closed by REMOVING the announcement, per the plan's pre-made decision. The review's second option — keep the count and add `ARM1_FAILS -eq $expect_reds` as a third conjunct — was refused because when the two existing conjuncts hold the summed counter is necessarily 1, so the conjunct is implied by them and could never independently fail. The refusal is recorded in band with its reason, which matters more than the removal"
  - "R3-07 closed as a claim correction plus a recorded precondition. The function was NOT wired into the live path and its arms were NOT re-polarised. Both are deliberate and both are checked: the comment-stripped call-site count is still 2 and both arms are pinned by literal"
  - "⚠️ THE REVIEW'S OWN CENSUS WAS WRONG AND THE PLAN SAID SO FIRST. R3-07 claims `assert_beet_invocation_contract` has 'exactly two hits'. Raw grep gives 4 at base (definition, one call, two comment mentions) and 5 after this plan. The conclusion is unaffected — exactly two are code, and the code call is inside run_self_test — but a verification that pinned the review's number would have failed on arrival. Corrected in band rather than silently, and the comment-stripped form is what both the script and the verify now pin"
  - "⚠️ THE PLAN'S <verify> BLOCKS cd INTO $(git rev-parse --show-toplevel). In this worktree that resolves to the worktree root, which is correct. Every measurement in this summary and in the artifact was taken from the worktree root — sixth plan across the round to record this"
  - "THE ARTIFACT WAS SPLIT ACROSS THE TWO COMMITS rather than written whole at task 1. Task 1's commit contains only the R3-08 half plus a forward pointer; the R3-07 half was appended in task 2 after its figures were measured. Writing task 2's counts into a task-1 commit would have been an unmeasured claim in an artifact whose whole purpose is measured claims"
  - "NO ESTATE CONTACT. --self-test is estate-free: no ssh, no docker exec, no live checker run, no network. Both scratch copies lived in a directory from `mktemp -d` and it was deleted; nothing was written inside the repository working tree except the two files listed above"
  - "NO REQUIREMENT CHECKBOX MOVED. CONF-04 is not closed and the phase is not declared complete, per the plan's own verification block"

patterns-established:
  - "Drive the defect before removing it: force the value the banner reports but the gate ignores, and capture the run printing two contradictory numbers while exiting 0"
  - "When prose you are adding will itself move a count, pin the comment-stripped count and say in band why the raw one must not be pinned"

requirements-completed: []

# Metrics
duration: 30min
completed: 2026-09-23
---

# Phase 6 Plan 33: Case 6's Announcement and the Contract Function's Census — Summary

Two INFO findings closed in `scripts/check-beets-config.sh`, both inside the machinery plan 06-22
added to prevent exactly their shape: **R3-08**, a banner that announced an expected red count no
gate compared, and **R3-07**, a justification whose stated reason did not apply to the change it
justified, plus an arm polarity that is harmless today and wrong the moment anyone wires the
function live.

## What changed

### R3-08 — case 6 announces the gate it actually has (code change)

After GC-13, case 6 gates on `ARM1_REAL_VIOLATIONS` and `ARM1_SYNTH_REJECTED`. Its expected-red
count survived only to print in the banner, and the success line still printed the summed counter —
a number nothing compared. The banner could say "expect 1 red" over a run that produced none or
two, which is the announced-vs-actual drift `ST_PLANNED_CASES` was added twenty lines below to
prevent, in miniature.

- The banner-only count is deleted from case 6. `run_case`'s `expect_reds="$2"`, its
  `ARM1_FAILS -eq $expect_reds` gate and its in-band note explaining why the sum is correct *there*
  are untouched; cases 1-5 and 7 are unaffected.
- The banner now reads `(gate: real violations=0 AND synthetic rejected=1)`.
- The success line prints `real violations=$ARM1_REAL_VIOLATIONS, synthetic rejected=$ARM1_SYNTH_REJECTED`.
- The two failure arms, which already named which half was wrong, are unchanged.

**The alternative was refused, and the refusal is recorded at the gate.** Keeping the count and
adding `ARM1_FAILS -eq $expect_reds` as a third conjunct looks symmetric but is not: when the two
existing conjuncts hold, real violations are 0 and the synthetic was rejected once, so the summed
counter is necessarily 1 and the third conjunct is *implied by the other two*. It could never
independently fail. That is the vacuous-assertion class CR-01, GC-03 and GC-05 each removed.

### R3-07 — the justification corrected, the precondition recorded (comments only)

- The sentence *"because the live arm-1 summary line is a second consumer of it"* is gone. The
  preserved value is correct; that reason was not. The counter does have a live consumer, but
  `assert_beet_invocation_contract` never runs live, so the live summary line consumes the counter
  and never sees this function's contribution to it. The replacement gives the true, narrower
  reason — the self-test's per-case bookkeeping and the live summary share one counter — and gives
  the census as a **recipe** rather than a number.
- The review's census sentence is corrected in band: it printed the code-only figure as a raw grep
  count. Raw was 4 at base and is 5 now; the durable figure is the comment-stripped 2.
- The polarity precondition is recorded immediately above the function under the greppable opening
  `IF THIS FUNCTION IS EVER CALLED LIVE`, naming what must change **in the same commit as any
  wiring**, why it is harmless under `--self-test`, and why someone will be tempted (a live run
  currently never checks the `-l` + `-c` source contract at all).

## Evidence

Artifact: `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-33-checker-case6-and-contract.txt`.

**The R3-08 defect, driven before it was removed.** On a scratch copy from `mktemp -d`, the summed
counter was forced to 2 at the end of the function while both gated values stayed correct:

| | banner | success line | run |
|---|---|---|---|
| pre-fix | `(expect 1 red)` | `2 red, as expected` | ✅ all 7 cases, exit 0 |
| post-fix | `(gate: real violations=0 AND synthetic rejected=1)` | `real violations=0, synthetic rejected=1` | ✅ all 7 cases, exit 0 |

Two contradictory numbers in plain sight, green, exit 0 — then nothing left to contradict.

**R3-07 changed no behaviour, proven twice.** Task 2's diff is 30 changed lines of which **0** are
non-comment lines; and `--self-test` output (SGR escapes stripped, nothing else normalised) is
**byte-identical** across it (`cmp` rc 0).

**Counts, all measured from the worktree root.**

| Check | Before | After |
|---|---|---|
| `grep -cF 'expect_reds=1'` | 1 | 0 |
| `grep -cF 'expect_reds="$2"'` (run_case) | 1 | 1 |
| `grep -cF 'ARM1_FAILS -eq $expect_reds'` (run_case) | 1 | 1 |
| `grep -cF ': $ARM1_FAILS red, as expected'` | 2 | 1 |
| `grep -cF 'because the live arm-1 summary line is a second consumer of it'` | 1 | 0 |
| `grep -cF 'IF THIS FUNCTION IS EVER CALLED LIVE'` | 0 | 1 |
| comment-stripped `assert_beet_invocation_contract` | 2 | **2** |
| raw `assert_beet_invocation_contract` | 4 | 5 (not pinned, by design) |
| `grep -cF 'ARM1_FAILS=0'` | 3 | 3 |
| `grep -cF 'arm-1 assertion failures:'` | 1 | 1 |
| `grep -cF 'ST_PLANNED_CASES=7'` | 1 | 1 |
| `bash -n`, `--self-test` | rc 0 | rc 0 |

Both arms pinned unchanged: `cfg_fail "D-04 contract, driven` = 1, and comment-stripped
`the checker is BLIND` = 1.

## NOT-DRIVEN register

Stated plainly, because this phase's whole method is that an unexercised claim must say so.

| Not driven | Why, and what would drive it |
|---|---|
| **The live path of `assert_beet_invocation_contract`** | It has none, deliberately. The function is called from exactly one place and that place is `run_self_test`. Nothing in this plan wires it live, and the comment-stripped call-site count of 2 is checked rather than asserted. Driving a live path would require creating one — a behaviour change to the live checker, outside a hardening round's brief. |
| **The inverted arm polarity** | Recorded as a precondition, not exercised. Exercising it means calling the function live, which this plan refuses to do. The claim that a correct live run would increment `FAILURES` while a blind checker would increment nothing is **static reasoning over `cfg_fail`'s body**, not a measured outcome. |
| **Case 6's failure arms** | Unchanged and not re-driven here; they were driven by 06-23/GC-13 when they were written. This plan pins their literals (`want 0`, `want 1 —`) rather than re-exercising them. |
| **The live checker as a whole** | No estate contact of any kind. `--self-test` is estate-free; no ssh, no `docker exec`, no network. Nothing in this plan observed the real beets container. |
| **The forced-counter scratch copies** | The forcing exists only to make the R3-08 defect visible. It was applied to disposable copies under `mktemp -d`, never to the repository script, and the scratch directory was deleted. |

## Deviations from Plan

**None of Rules 1-4 fired.** Both tasks executed as written, including the plan's pre-made decision
on which R3-08 fix to take. Two things worth recording that are *not* deviations:

1. **The worktree spawned one commit behind the declared base** (`5c5108a` vs `fff070a`), as the
   execution prompt anticipated. Corrected by the prescribed `git reset --hard`. Recorded, not a
   deviation.
2. **The artifact was written in two halves rather than one.** Task 1's commit carries only the
   R3-08 half plus an explicit forward pointer saying the R3-07 half is appended by task 2 and that
   nothing about R3-07 is claimed yet. This is a stricter reading of the plan than the plan's own
   `<files>` lists require, taken because the alternative would have put task 2's unmeasured counts
   into a task-1 commit — a measured-claims artifact containing an unmeasured claim.

## Known Stubs

None. No placeholder values, no unwired data paths, no TODO markers introduced.

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema change. The plan installs
nothing and the only executable change is the text two `echo -e` lines print.

## Self-Check: PASSED

- `scripts/check-beets-config.sh` — FOUND, modified in both commits
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-33-checker-case6-and-contract.txt` — FOUND, created
- commit `d560394` (task 1) — FOUND
- commit `c4c708e` (task 2) — FOUND
- `git diff fff070a..HEAD --name-only` lists exactly the two files above; `scripts/setup-neocortex-memory.sh`, `stacks/selfhosted/neocortex-memory/` and `stacks/selfhosted/agentic-os/` are untouched
- Both tasks' automated verify blocks re-run green after the final commit
