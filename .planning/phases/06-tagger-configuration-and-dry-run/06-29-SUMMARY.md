---
phase: 06-tagger-configuration-and-dry-run
plan: 29
subsystem: phase-06 planning record
tags: [gap-closure, round-2, wave-4, dispositions, register, deferred-items, roadmap, state]
gap_closure: true
gap_closure_round: 2
wave: 4

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plans 06-22..06-28 complete and merged, so every GC finding has a commit and an artifact to cite"
provides:
  - "06-DISPOSITIONS-GAP.md: the 17-row round-2 register, one row per GC finding, with a provenance clause naming who confirmed each and how"
  - "06-REVIEW-GAP.md WIRED — the seventeen findings can no longer be lost at a context boundary"
  - "deferred-items.md: DEF-06-29-01..11, each with an exact driving condition; DEF-06-21-07 closed as DRIVEN AND PASSING; DEF-06-21-02's description corrected"
  - "ROADMAP Phase 7 entry criterion E12, carrying the round-2 residue that closes only on the live pilot"
  - "a re-measured D-04 count vector at HEAD, settling an internal inconsistency in 06-28's own artifact"
affects: [06-verification, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "a disposition column of all-FIXED is a property of how the round was PLANNED, not evidence that nothing is outstanding — say so in the file or the zero reads as completion"
    - "an artifact's summary table and its later section can disagree when the later section was added by a second commit; re-measure rather than quoting either"
    - "record who confirmed a finding and how, per row — 'unverifiable' and 'false' are different words and the first decays into the second across a context boundary"
    - "carry items that belong to no finding and no other plan in the LAST plan of a round; an item everyone correctly declines is an item nobody owns"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP.md
  modified:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP.md
    - .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "17 FIXED / 0 FIXED (undriven) / 0 ACCEPTED / 0 CARRIED — and the empty honest middle is FLAGGED rather than presented as good news. It is empty because every round-2 plan's <verify> demanded a driven artifact, not because nothing is left; the residue is carried as DEF-06-29-01..11"
  - "The four-word vocabulary was NOT extended. No fifth word was invented to describe a row that was driven only over a synthetic fixture — 06-21's rule (synthetic drives count, real-run drives are residue) was applied unchanged, and the four closest calls are named so a later reader can disagree with the judgement rather than the record"
  - "⚠️ THE ORCHESTRATOR'S BRIEFED COUNT WAS WRONG AND IS REPORTED, NOT ABSORBED. Briefed raw/stripped 200/99 at HEAD; measured 202/101. The briefing quoted 06-28's artifact RESULTS table, which disagrees with that same artifact's later section (202/101 at 64886ab). Re-measured with both regexes extracted from the shipping file"
  - "A FOURTH correction was recorded beyond the plan's three, because it is GC-10's own defect firing once more inside round 2's record of GC-10"
  - "STATE.md and ROADMAP.md hand-edited with Edit, NOT via gsd-sdk state.* / roadmap.* verbs, per the orchestrator's standing warning. Both diffs inspected before commit"
  - "Four carried items belong to no GC finding and to no other plan — live un-rotated secrets on LXC 100, two path-safety violations, deployed-host staleness, and the D-04 no-sentinel arm — and are homed as DEF-06-29-08..11 rather than left in a prompt"

patterns-established:
  - "State a zero in a register column with its cause, or the zero is read as its most flattering meaning"
  - "When a briefing and a source artifact disagree on a number, measure it; when the artifact disagrees with itself, say which half was written first"

requirements-completed: []

# Metrics
duration: 45min
completed: 2026-09-22
---

# Phase 6 Plan 29: The Round-2 Disposition Register — Summary

All seventeen round-2 findings `GC-01` … `GC-17` now carry an explicit disposition with a plan, a
commit, an artifact and a clause naming who confirmed the finding and how; `06-REVIEW-GAP.md` is
wired to that register; and the round's residue — including four items that belong to no finding
at all — is carried by name with an exact driving condition each.

## What Was Done

### Task 1 — the seventeen-row register (commit `58419b2`)

`06-DISPOSITIONS-GAP.md`, modelled on `06-DISPOSITIONS.md` and reusing its structure exactly.

**The finding→plan mapping was verified against `06-REVIEW-GAP.md`, not taken on trust.** All
seventeen are accounted for, each by exactly one plan: 06-22 (GC-01, GC-13), 06-23 (GC-03, GC-16),
06-24 (GC-02, GC-06), 06-25 (GC-08), 06-26 (GC-17, GC-14, GC-09), 06-27 (GC-05, GC-15, GC-12,
GC-07, GC-11), 06-28 (GC-04, GC-10). The review's own class counts were re-derived from its body
rather than from its frontmatter: warnings are GC-02…GC-08 (7), info GC-09…GC-15 (7), blocker
GC-01 (1) — 15, plus GC-16 and GC-17.

**Counts reconcile three ways to 17:** the frontmatter's 1 + 7 + 7 = 15 plus two adjudication
findings; the adjudicated classes 1 + 9 + 7; and the dispositions 17 + 0 + 0 + 0.

**Dispositions: 17 FIXED, 0 FIXED (undriven), 0 ACCEPTED, 0 CARRIED.** The vocabulary is closed and
unextended. Applying 06-21's separation test — *did a summary record the changed branch being
observed to fire?*, with synthetic-fixture drives counting and real-run drives recorded as residue
— put all seventeen on the driven side. **The empty honest middle is flagged in the file rather
than presented as good news:** it is empty because every round-2 plan's `<verify>` demanded a
driven artifact and every one delivered a pre-fix reproduction, a post-fix refusal and a passing
partner. That is a property of how the round was planned, not a claim that nothing is outstanding.
The four closest calls (GC-16, GC-15, GC-02, and the comment/documentation-only rows) are named
explicitly so a later reader can disagree with the judgement rather than the record.

Every row carries a **provenance clause**: confirmed by the cross-family reviewer / confirmed
independently by the orchestrator with a local reproduction / verified during round-2 planning by
opening the target / verified by the executing plan. No row says "unverifiable" for anything
subsequently verified.

Seven artifact paths are cited and all seven exist.

### Task 2 — wiring, residue, roadmap and state (commit `a2ad4a4`)

**(a) `06-REVIEW-GAP.md` is WIRED.** An appended block below the adjudication points at the
register, states the three-way reconciliation, and tells the reader to prefer the register over
the adjudication's own summary line for GC-15. Nothing above it was edited; the adjudication's two
in-band `> CORRECTION` blocks stand verbatim.

**(b) Residue carried by name — `DEF-06-29-01` … `DEF-06-29-11`.** Seven are residue of rows that
are themselves FIXED; **four belong to no GC finding and to no other plan**, and are homed here
because this is the last plan of the round:

| entry | what |
|---|---|
| `DEF-06-29-01` | 23 lines / 24 pipelines of `\| grep -q` under `pipefail`, **five inverted**, citing `artifacts/06-22-pipefail-141.txt`; distinguished from `DEF-06-21-08` (planner-side) as **shipped code**, with the `quick-health-check.sh` hazard named |
| `DEF-06-29-02` | the ninth stale citation (`check-music-freeze.sh:144` → `:160`), anchor pre-verified |
| `DEF-06-29-03` | 06-24's latent verify conflict — the ≥5-sites check **forbids the DRY fix** |
| `DEF-06-29-04` | the live arm-1 dump has never been sized, so GC-01's live margin is unknown |
| `DEF-06-29-05` | the four hardenings that close only on Phase 7's pilot; also **E12** |
| `DEF-06-29-06` | thirteen citations that resolve **today** |
| `DEF-06-29-07` | seven wrong-premise `<verify>` checks + the `cd`-to-main-checkout template defect |
| `DEF-06-29-08` | NEW-06-26-01 — the D-04 no-sentinel arm names a path it may not have visited |
| `DEF-06-29-09` | **three live un-rotated secrets on LXC 100**; repo-side hole closed, keys are not |
| `DEF-06-29-10` | the two path-safety violations that actually occurred |
| `DEF-06-29-11` | deployed-host staleness that **looks like** phase fallout and is not |

`DEF-06-21-07` is marked **DRIVEN AND PASSING** and closed — 06-26 executed its stated condition
exactly and the arm reported UNKNOWN with no counts. `DEF-06-21-02`'s *description* is corrected
per 06-27, with its substance, disposition and driving condition explicitly unchanged.

**(c) ROADMAP.** 06-29 ticked; plan count 28/29 → 29/29; the `**Phase 6 disposition:**` paragraph
amended with the literal `ROUND 2`, what it closed, and that re-verification was not performed;
the progress-table Notes cell extended; and **new Phase 7 entry criterion E12** carrying the
undriven-until-the-pilot residue, in E10/E11's style.

**(d) STATE.md § Current Position** rewritten to say round 2 executed, what it closed, the
instrument state at HEAD, and — prominently — that **re-verification is outstanding and no
verification result is claimed**. The three non-phase items are surfaced there too, because a
secret that is nobody's phase item is exactly what gets lost between phases.

**(e)** Both the roadmap amendment and STATE.md say explicitly that `/gsd-verify` was not run.

## Deviations from Plan

### 1. [Rule 1 — reported, not absorbed] The briefed count for HEAD is wrong, and the source artifact disagrees with itself

- **Found during:** Task 1, cross-checking the D-04 figures before writing them.
- **Issue:** the execution briefing states *"raw/stripped is 200 / 99 at HEAD"*. Plan 06-28's own
  SUMMARY and artifact record **202 / 101** after its Task 2 commit `64886ab`. The artifact is
  **internally inconsistent**: its RESULTS table reads `06-28 AFTER … 200 / 99` while a later
  section — added by the plan's *second* commit — reads `64886ab … 202 / 101` and explains the
  `+2` as the plan's own prose. The table was written before the prose landed and not re-read.
- **Fix:** re-measured at HEAD `23b2b82` with the block's own pipeline, both regexes **extracted**
  from `scripts/quick-health-check.sh` rather than retyped (06-23 widened `D04_INV_RE` this round),
  every grep answered by `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD): **raw 202, comment-stripped 101,
  pinned vector 10 / 8 / 3 / 5 / 2 unmoved.**
- **Recorded as a FOURTH correction** in the register's corrections section, beyond the three the
  plan named — because it is **GC-10's own defect firing one more time inside round 2's record of
  GC-10**, which is the most useful possible demonstration of why 06-28 dropped those rows. The
  register therefore does **not** pin them either.

### 2. [Rule 2 — scope widened to close the class] Eleven deferred entries, not seven

- **Issue:** the register, written first, referred to the residue as `DEF-06-29-01 … DEF-06-29-07`.
  Four of the carried items handed to this plan are not residue of any GC finding — the live
  secrets, the two path-safety violations, the host staleness, and NEW-06-26-01 — and had nowhere
  else to go. Every other plan in the round correctly declined them (06-26 and 06-28 both recorded
  theirs in a SUMMARY rather than risk a collision on the shared `deferred-items.md`).
- **Fix:** entries 08–11 written, and the register's range sentence corrected in the same round to
  `01 … 11` with a paragraph saying why four of the eleven are not GC residue. The correction to my
  own file is recorded here rather than made silently.

### 3. [Reported] The plan's `<verify>` blocks `cd` into the main checkout — the sixth plan this round

Both `<verify>` blocks open with `cd /Users/damian/Development/damianflynn/selfhost-stacks`. This
plan ran **on** the main working tree by design (sequential executor, no worktree), so obeying it
was harmless **here** — but it is the same line that made five worktree agents measure an
unmodified file. Recorded rather than passed over, and carried as `DEF-06-29-07`. **The template is
the defect.**

### 4. [Rule 3 — tooling] `gsd-sdk state.*` and `roadmap.*` verbs deliberately not used

Per the orchestrator's standing warning and STATE.md's own parenthetical: `state.begin-phase` has
truncated STATE.md sentences mid-line, and `roadmap.update-plan-progress` **blanked the entire
Phase 6 Notes cell** — 1,791 characters including the *"must never be summed"* warning — on every
invocation. Both files were hand-edited with `Edit` and both diffs inspected before commit. The
Phase 6 row still has **6 pipe-delimited columns** (matching its siblings) and still contains
*"must never be summed"*.

## Verification Results

Both tasks' `<automated>` blocks pass in full, run from the repo root with `/usr/bin/grep`.

| check | result |
|---|---|
| all of `GC-01` … `GC-17` named in the register | PASS — 17/17 |
| closed vocabulary present (`FIXED`, `CARRIED`) | PASS — 24 / 4 |
| reconciliation stated | PASS |
| `GC-17` appears ≥2 (finding + correction) | PASS — 8 |
| `E6` named in the register | PASS — 5 |
| artifact paths cited, and every one exists | PASS — **7 cited, 7 exist** |
| `06-REVIEW-GAP.md` wired to the register | PASS — 1 (was 0) |
| adjudication intact above the new block | PASS — `Cross-family adjudication` 1, `gemini-3.1-pro-preview` 2 |
| `DEF-06-29-*` present, citing the inventory artifact | PASS — 17 refs / 1 |
| ROADMAP round-2 wave lists intact | PASS — 4 |
| disposition paragraph records `ROUND 2` | PASS — 1 |
| disposition paragraph does **not** claim CONF-04 closed | PASS — 0 |
| ROADMAP Phase 6 row column count vs siblings | PASS — 6 = 6 = 6 |
| `must never be summed` survives in ROADMAP | PASS — 2 |
| `E10` / `E11` / `E12` all present | PASS — 3 |
| STATE.md points at the register | PASS — 2 |
| STATE.md standing warnings survive | PASS — `tank/downloads@pre-phase5` 3, `--auto` 1 |
| STATE.md diff confined to the intended region | PASS — 4 hunks, all in § Current Position / Status; every removed line deliberate |
| `- [ ] **CONF-04**` still in REQUIREMENTS.md | PASS — 1 |
| `git diff --name-only -- .planning/REQUIREMENTS.md` | PASS — empty |
| `git diff --diff-filter=D` per commit | PASS — **no file deleted** |
| no `/gsd-verify` run, no verification result claimed | PASS |
| no estate contact, no `git push`, no host pull | PASS |

**Measurement provenance:** every grep above was answered by `/usr/bin/grep` (BSD grep
2.6.0-FreeBSD), called by absolute path. The Bash tool inherits the operator's zsh `grep` → ugrep
7.8.4 alias, which was kept out of every measurement.

## NOT-DRIVEN Register

Stated rather than implied, per this phase's convention.

| item | why it was not driven |
|---|---|
| The instruments' `--self-test` state at HEAD | Quoted from the orchestrator's verification on this same merged tree (oracle 134 cases, `check-beets-config.sh` 7 cases, incremental control all branches, `bash -n` clean on four scripts). This plan edits no script and re-running them is not its mandate. The one number it did re-measure — the D-04 vector — it re-measured because a source disagreed with itself. |
| Every `DEF-06-29-*` driving condition | By construction: an entry exists *because* its condition has not been met. Each is written to be executable by the next reader rather than descriptive. |
| The register being READ by the next phase | The mechanical claim — the review points at the register, the register names every finding, ROADMAP and STATE point at both — is what was measured. That a reader follows the chain is the design argument, not a measurement. This is the exact claim `06-VERIFICATION.md` tested for round 1 when it marked `06-REVIEW.md` NOT WIRED. |
| The four corrections being believed over the source | A `> CORRECTION` block and a register row are the strongest available instruments; a reader can still follow the uncorrected summary line. Mitigated by stating the GC-15/GC-17 crossing in **three** places (the review, the register, this summary). |

## What This Does NOT Claim

It does **not** re-verify the phase — no `/gsd-verify` was run and **no verification result is
claimed**. It does **not** close **CONF-04**: `REQUIREMENTS.md` is untouched, `- [ ] **CONF-04**`
stands, its two verdicts are recorded separately and **never summed**, and entry criterion **E6**
still owns the Jellyfin half. It moves **no** requirement checkbox and does **not** declare Phase 6
complete — that is the verifier's call. Round 1's carried items stay carried: **E10** (CR-01's
residue) and **E11** (WR-09) are unchanged. It touches no script and makes no estate contact.

## Threat Flags

None. This plan installs nothing, opens no network path, reads no credential and edits only
planning documents. `T-06-29-LOST` and `T-06-29-DECAY` are both mitigated — the first by the wired
register, the second by the per-row provenance clause. `T-06-29-STATE` is mitigated by hand-editing
STATE.md and inspecting the diff. `T-06-29-SC` is `accept` and vacuously true.

One threat-relevant item is **surfaced, not introduced**: `DEF-06-29-09` records three live
un-rotated secrets on LXC 100. The repo-side exposure was closed by commit `456ad06`; the keys are
not rotated and the file is still on the host. It is outside this phase and needs an owner.

## Known Stubs

None.

## Commits

| commit | task |
|---|---|
| `58419b2` | Task 1 — the 17-row register, the three-way reconciliation, the provenance clauses, the four corrections |
| `a2ad4a4` | Task 2 — the wiring block, `DEF-06-29-01..11`, `DEF-06-21-07` closed, ROADMAP + E12, STATE.md |

## Recommended Next

1. **`/gsd-verify 06`.** Round 2 has landed; whether the phase closes is the verifier's call and
   this plan deliberately did not make it.
2. **A fresh code review of round 2's OWN changes**, before the phase closes. Round 2 exists
   because round 1 was declared closed and verified **6/6** before anyone read its own diff — and
   it still carried a BLOCKER. Verification asks whether the must-haves were met; review asks
   whether the code that meets them is correct. Those are different questions, and this phase has
   now paid for the difference once.
3. **Decide on the push.** Three live reds (`DEF-06-29-11`) clear only on `git push` + host
   `git pull --ff-only` — and pushing deliberately makes `quick-health-check.sh` exit non-zero on
   the consumers block until **E6**. That is a decision, not a task.
4. **Rotate the three keys in `DEF-06-29-09`.** It is not a Phase 6 item, which is precisely how it
   would be lost.

## Self-Check: PASSED

Files claimed created/modified, checked on disk:

| Path | Result |
|---|---|
| `.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP.md` | FOUND |
| `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP.md` | FOUND |
| `.planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md` | FOUND |
| `.planning/ROADMAP.md` | FOUND |
| `.planning/STATE.md` | FOUND |

Commits claimed, checked in `git log`: `58419b2` FOUND, `a2ad4a4` FOUND.
`git diff --diff-filter=D` across both: **empty — no file deleted.**
