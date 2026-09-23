---
phase: 06-tagger-configuration-and-dry-run
plan: 34
subsystem: phase-06 planning record
tags: [gap-closure, round-3, wave-15, disposition-register, deferred-items, refusals, record-not-a-re-close]
gap_closure: true
gap_closure_round: 3
wave: 15

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plans 06-30..06-33 landed and merged, so every R3 finding has an owning plan, a commit and an artifact to cite"
provides:
  - "all ten R3-* findings carry an explicit disposition AND an explicit fix-kind in one register whose counts reconcile three ways to 10"
  - "06-REVIEW-GAP2.md is WIRED to that register by a purely additive appended block — 60 insertions, 0 deletions"
  - "round 3's residue, including all three of its deliberate refusals, is carried by name as DEF-06-34-01..DEF-06-34-06"
  - "the review's nine Verified-and-clean items are closed against round 4 by citation"
  - "ROADMAP and STATE describe round 3 accurately, edited by hand, and close nothing"
affects: [phase-06 verification, phase-06 review round 4, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "a disposition register needs a FIX-KIND column when the review's charge is over-claiming: ten undifferentiated FIXEDs reproduce the defect one level up"
    - "record a refusal as loudly as a fix — a refusal nobody wrote down reads as an oversight and gets re-opened next round"
    - "state an absent adjudication explicitly; an absence nobody mentions is indistinguishable from a loss"
    - "edit STATE.md and ROADMAP.md by hand and read `git diff` before committing — the SDK's state.*/roadmap.* verbs corrupt prose in the files they write"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP2.md
    - .planning/phases/06-tagger-configuration-and-dry-run/06-34-SUMMARY.md
  modified:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP2.md
    - .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The register carries a FIX-KIND column (CODE / CLAIM CORRECTION / BOTH) as well as a disposition. This is the point of the round: the review's charge is that round 2 closed classes partially and claimed completeness, and a register that cannot distinguish a widened fence from a narrowed sentence reproduces exactly that ambiguity one level up"
  - "R3-09 is the single FIXED (undriven) row. The other nine are FIXED under round 2's own test — a synthetic-fixture drive counts as driven, and residue attached to a FIXED row is carried as residue rather than folded into the disposition"
  - "THE ABSENT CROSS-FAMILY ADJUDICATION IS STATED, NOT OMITTED. Round 2 had one and it appended GC-16 and GC-17; round 3 had none. An absence nobody mentions reads like a loss"
  - "THREE refusals were carried, not two. The plan's objective names two plans; 06-33 made two distinct refusals (the vacuous third conjunct, and live wiring), so the count is three across two plans. The ROADMAP wave-15 line was corrected from 'both' to that"
  - "⚠️ THE REVIEW'S OWN CENSUS WAS RE-MEASURED AT THREE REFS RATHER THAN RESTATED. R3-07's 'exactly two hits' is 2 only at the review's own diff_base bf509f4; at fff070a (the tree it was reading) it is 4, and at HEAD it is 5. The finding's conclusion is unaffected — exactly two are code — and it is recorded as a correction in band, not a silent fix and not a downgrade"
  - "NO SDK state.* OR roadmap.* VERB WAS RUN. Both files were edited by hand and `git diff` was read on each before committing: ROADMAP 42 insertions / 2 deletions, STATE 48 / 3, every deletion a line the task intentionally replaced"
  - "THE THREE HISTORICAL DELTA SENTENCES IN quick-health-check.sh ARE FLAGGED AS MUST-NOT-CORRECT in DEF-06-34-03. Each was accurate as of its own edit; 'correcting' them turns three right statements into three wrong ones"
  - "NO VERIFICATION WAS RUN. No requirement checkbox moved. CONF-04 remains OPEN under E6. The phase is NOT declared complete"

patterns-established:
  - "Reconcile a register's counts by at least as many routes as it has columns — here three: the review's frontmatter, the dispositions, and the fix kinds"
  - "Close a review's Verified-and-clean section against the next round by citation, and say which of its items the current round touched, so the list is not assumed stale on arrival"

requirements-completed: []

# Metrics
duration: 35min
completed: 2026-09-23
---

# Phase 6 Plan 34: Round 3's Record — Summary

**All ten `R3-*` findings now carry a disposition *and* a fix-kind in one register whose counts
reconcile three ways to 10; `06-REVIEW-GAP2.md` is wired to it by a block that edits nothing above
itself; and round 3's residue — including all three of its deliberate refusals — is carried by name
rather than dropped.** Nothing was closed, verified or ticked.

## What Was Done

### Task 1 — the ten-row register — commit `20f9628`

`06-DISPOSITIONS-GAP2.md`, mirroring `06-DISPOSITIONS-GAP.md`'s structure rather than inventing a
variant: *Why this file exists* → *Source* table → *Counts* → the vocabulary → one row per finding
in ID order → corrections → lessons.

**Dispositions: 9 FIXED, 1 FIXED (undriven), 0 ACCEPTED, 0 CARRIED.** R3-09 is the single undriven
row — the `SIGTERM` behaviour is static reasoning about POSIX `sh` on both sides, and neither trap
has been observed firing inside the container. The other nine are FIXED under round 2's own test: a
drive over a synthetic fixture counts as driven, and residue attached to a FIXED row is carried as
residue rather than folded into the disposition.

**Fix-kinds: 4 CODE, 3 CLAIM CORRECTION, 3 BOTH.** This column is the point of the round. The
review's central charge is that round 2 closed classes partially and then wrote that it had closed
them completely; ten undifferentiated `FIXED`s would reproduce that ambiguity one level up.

**Counts reconcile three ways:** the review's frontmatter `0 + 5 + 5 = 10`; the dispositions
`9 + 1 + 0 + 0 = 10`; the fix kinds `4 + 3 + 3 = 10`.

Each row carries the owning plan, the commit, the artifact path, and a **provenance clause** that
does not flatten "grep-verified" into "reasoned about" — R3-01, R3-02 and R3-05 were confirmed
independently by the orchestrator, R3-05 by execution twice, and R3-03, R3-04, R3-09 and R3-10 are
explicitly recorded by the review itself as static reasoning that was never executed.

**What was not driven is recorded per surface**, in its own section rather than buried in the rows:
the whole layer-3 block (R3-03, R3-04) reachable only from a live `--run`; the `SIGTERM` behaviour;
`quick-health-check.sh` not executed at all, by the review or by the fix; three findings closed with
zero executable change, two of them proved so mechanically; and — the smaller half, named because it
is smaller — what *was* executed.

**The absent adjudication is stated.** Round 2 had a cross-family adjudication that appended GC-16
and GC-17; round 3 had none. The register says so under its own heading, because an absence nobody
mentions reads like a loss.

**The nine Verified-and-clean items are reproduced under a heading that closes them against round
4**, with a note on the two round 3 touched (the `-1` sentinels are unchanged; R3-06 narrowed the
prose beside the three `rm ` cases and deliberately did not widen the cases).

### Task 2 — the wiring block and the residue — commit `9c16041`

**`06-REVIEW-GAP2.md` gained an appended block and nothing else: 60 insertions, 0 deletions.** All
ten `### R3-` headings, the `findings:` frontmatter and the Verified-and-clean section are
byte-unchanged, asserted mechanically.

The block names the register by full path, states the counts and all three reconciliation routes,
names the four fix plans and this one, names the `DEF-06-34-*` series, records the absent
adjudication, and closes the Verified-and-clean section against round 4.

**It carries one correction in band.** R3-07's **Verified** line claims
`assert_beet_invocation_contract` has "exactly two hits". Re-measured at three refs: `bf509f4` (the
review's own `diff_base`) → **2**; `fff070a` (the tree the review was actually reading) → **4**;
HEAD → **5**. The finding's conclusion is correct and unaffected — exactly two occurrences are
*code*, and the code call is inside `run_self_test` — so this is recorded the way round 2 recorded
the GC-15/GC-17 label crossing: a correction in band, not a silent fix and **not a downgrade of the
finding**.

**Six `DEF-06-34-*` entries**, continuing the series after `DEF-06-29-11`:

| ID | What it carries |
|---|---|
| `DEF-06-34-01` | **REFUSED**: the `/tmp/p6-mf.*` sweep (06-32), with the shared-`/tmp` reasoning and the evidence that would justify revisiting it |
| `DEF-06-34-02` | **REFUSED ×2**: R3-08's vacuous third conjunct and wiring `assert_beet_invocation_contract` live (both 06-33), each with reason and revisit condition |
| `DEF-06-34-03` | the raw exit-code-notice count is deliberately **unpinned**, with both bracketed recipes — and the warning that three historical delta sentences must **not** be "corrected" |
| `DEF-06-34-04` | the layer-3 block is **undriven** (R3-03, R3-04), plus `quick-health-check.sh`'s unexecuted state; attaches to the existing **E12** |
| `DEF-06-34-05` | the `*"rm "*` token test is weaker than a destructive-program check (R3-06), bounded, with the decision not to widen the cases recorded |
| `DEF-06-34-06` | the **`SIGKILL` residual** on both in-container traps — trapping `INT TERM HUP` shrinks the window and cannot close it |

**Nothing already owned was duplicated.** The ~23 remaining `printf … | grep -q` SIGPIPE-141 sites
(`DEF-06-29-01`), CONF-04's Jellyfin half (**E6**) and the three un-rotated secrets
(`DEF-06-29-09`) are referenced, not re-opened. **No new Phase 7 entry criterion was added** —
round 3's live-run residue attaches to the existing **E12**.

### Task 3 — ROADMAP and STATE, by hand — commit `722d735`

**No `gsd-sdk query state.*` or `roadmap.*` verb was run.** Both files were edited with `Edit` and
`git diff` was read on each before committing.

| file | insertions | deletions | every deletion accounted for |
|---|---|---|---|
| `.planning/ROADMAP.md` | 42 | 2 | the unticked `06-34-PLAN.md` line; the `33/34` milestone-row opening |
| `.planning/STATE.md` | 48 | 3 | the three-line `Current Position` header this task replaces |

**ROADMAP.** 06-34's wave-15 line ticked (and corrected from "both of the round's deliberate
refusals" to *three, across the two plans that made them* — 06-33 made two distinct refusals). The
plan-count line already read **34 plans in 15 waves** and the round ended with five plans, so it was
verified, not rewritten. A round-3 amendment was appended after the round-2 one, stating the counts,
the round's character, all three refusals, the undriven surfaces, the R3-07 correction, and —
twice — that this is a record and not a re-close. The Phase 6 milestone **Notes cell was appended
to, never rewritten**: **3,221 → 5,177 bytes**, with the round-1 and round-2 sentences verified
present afterwards. This is the cell the SDK verb blanked three times.

**STATE § Current Position.** `ROUND 3 EXECUTING` → `ROUND 3 DONE, PHASE NOT VERIFIED`; `Plan: 29 of
34` → `34 of 34`; and a round-3 block recording the dispositions, the ownership map, the absent
adjudication, the round's character, the three refusals and the undriven surfaces.

**Instrument baselines re-measured at HEAD**, not carried forward from any plan's text:

| instrument | result |
|---|---|
| `phase06-oracle.sh --self-test` | exit **0**, now **gated** on a pinned `ST_PLANNED_CASES=134` compared against `ST_RUN` as its own arm before the banner |
| `check-beets-config.sh --self-test` | exit **0**, all **7** cases (`ST_PLANNED_CASES=7`) |
| `phase06-incremental-control.sh --self-test` | exit **0** |
| `bash -n` | clean on **all four** scripts |
| `sh -n` on the two extracted in-container programs | clean — `manifest.sh` 65 lines, `taghist.sh` 31 |

The standing re-verification warning is restated for this round; CONF-04's Jellyfin half stays open
under **E6**; and the round-4 question is stated **both ways and named as the operator's call**,
without deciding it.

## Measurements

All greps with `/usr/bin/grep` by absolute path — the operator's zsh aliases `grep` to `ugrep`.

| measurement | value |
|---|---|
| `R3-01` … `R3-10` rows in the register | 10, one each, in ID order |
| register `FIXED` / `CLAIM CORRECTION` / `CODE` occurrences | 20 / 5 / 8 |
| `06-REVIEW-GAP2.md` `^### R3-` headings | **10**, unchanged |
| `06-REVIEW-GAP2.md` diff | **+60 / −0** |
| `^## DEF-06-34-` entries | **6** |
| `assert_beet_invocation_contract` raw, at `bf509f4` / `fff070a` / HEAD | **2 / 4 / 5** |
| `assert_beet_invocation_contract` comment-stripped at HEAD | **2** (the durable figure) |
| Phase 6 Notes cell | 3,221 → **5,177** bytes; `Round 2 COMPLETE` still present |
| `- [ ] **CONF-04**` in `REQUIREMENTS.md` | **1**, and the file is clean in `git status` |

## Deviations from Plan

**None of Rules 1-4 fired.** All three tasks executed as written and all three `<verify>` blocks
pass in full. Three things worth recording that are *not* deviations:

1. **The plan's wave-15 ROADMAP line said "both" refusals; there are three.** 06-32 made one
   (the sweep) and 06-33 made two (the vacuous third conjunct, and live wiring). The plan's own
   task-3(a) instruction permits correcting a wave line that a summary contradicts, so the line was
   corrected rather than left ambiguous, and the register and the DEF entries carry all three.
2. **The plan's `<verify>` blocks open with `cd "$(git rev-parse --show-toplevel)"`.** This plan ran
   on the main working tree, where that resolves correctly — the seventh plan across rounds 2 and 3
   to record the construction, and the first for which it was harmless.
3. **STATE.md's frontmatter was deliberately left untouched**, including
   `progress.completed_plans`. The plan's task-3(f) says to touch nothing else in either file, and
   the frontmatter counters are the SDK's territory — whose verbs this plan is forbidden to run.

## NOT-DRIVEN REGISTER

This plan is a record. It executed nothing that changes the estate and nothing that changes a
script. What it *did* execute, and what it did not:

| | |
|---|---|
| **Executed** | `bash -n` on all four scripts; all three `--self-test` runs; `sh -n` over both extracted heredoc bodies; every `test` in all three `<verify>` blocks; `git show` at three refs for the R3-07 census re-measurement |
| **NOT executed** | `/gsd-verify` — deliberately, and no verification result is claimed anywhere |
| **NOT executed** | `scripts/quick-health-check.sh` — it contacts LXC 100 and atlantis |
| **NOT executed** | any `--run`, any `--arm`, any `ssh`, any `docker exec`, any `git push`, any host `git pull`. No estate contact of any kind |
| **NOT run** | `gsd-sdk query state.*` and `gsd-sdk query roadmap.*`, by explicit instruction. Both files edited by hand with `git diff` read before commit |

The self-tests were run to **measure the baselines STATE records**, not to verify the phase. Exit 0
on three estate-free harnesses is not a phase verdict and is not presented as one.

## Scope Held

- Six files touched, all under `.planning/`. **No file under `scripts/` was modified** — asserted
  by `git diff --name-only` across all three commits.
- `scripts/setup-neocortex-memory.sh`, `stacks/selfhosted/neocortex-memory/` and
  `stacks/selfhosted/agentic-os/` untouched.
- No file deleted by any commit.
- `.planning/REQUIREMENTS.md` **untouched and clean in `git status`**.

## What this plan explicitly did NOT do

Stated here as well as in the register, because it is the thing most likely to be misread:

- **No verification was run.** No `/gsd-verify`, and no verification result is claimed.
- **No requirement checkbox moved.** `REQUIREMENTS.md` is untouched and unstaged.
- **CONF-04 remains OPEN** on its Jellyfin half, and Phase 7 entry criterion **E6** still owns the
  discharge.
- **The phase is NOT declared complete.** That is the verifier's call, on a re-verification this
  plan does not perform. "Round 3 complete" must not be read as "phase complete".

## Known Stubs

None. This plan adds no code path, no placeholder value and no unwired component. Every claim in the
register cites a commit that exists and an artifact that exists, both checked below.

## Threat Flags

None. No network endpoint, auth path, file-access pattern or schema change. `T-06-34-SC` is accepted
as stated in the plan's register: this plan installs nothing.

## Self-Check: PASSED

| Claim | Result |
|---|---|
| `06-DISPOSITIONS-GAP2.md` | FOUND, carries `R3-10` |
| `deferred-items.md` | FOUND, carries `DEF-06-34` ×6 |
| `06-REVIEW-GAP2.md` | FOUND, carries `06-DISPOSITIONS-GAP2`, 10 `### R3-` headings intact |
| `.planning/ROADMAP.md` | FOUND, carries `34 plans in 15 waves`, Wave 14 and Wave 15 blocks |
| `.planning/STATE.md` | FOUND, carries `ROUND 3 IS DONE` and `ST_PLANNED_CASES` |
| commits `55a2db3`, `82f4713`, `43e5d6c`, `ad88ef5`, `e714632`, `928f9c2`, `befe732`, `d560394`, `c4c708e` (cited in the register) | all nine FOUND |
| commit `20f9628` (task 1) | FOUND |
| commit `9c16041` (task 2) | FOUND |
| commit `722d735` (task 3) | FOUND |
| artifacts `06-30-…`, `06-31-…`, `06-32-…`, `06-33-…` | all four FOUND on disk |
