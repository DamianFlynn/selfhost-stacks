---
phase: 04-collapse-to-one-tagger
plan: 04
subsystem: docs
tags: [docs, amendment, sweep, d-20, d-24, d-07, d-14, f10, f15]

# Dependency graph
requires:
  - phase: 04-collapse-to-one-tagger
    provides: "04-03's repo deletions (wrtag/soulbeet definitions, wrtag Renovate pin) and PRE_DELETION_SHA 5d0af70"
  - phase: 03-tagger-spike
    provides: "03-DECISION.md: the session.py --pretend evidence, the D-14 sentence, the 144-folder denominator, section 9 / DEF-03-21"
provides:
  - "ROADMAP Phase 4 criterion 4 satisfiable at full strength: dated D-20 amendment naming the MB-only tag_album() probe pair with the D-17 negative control on the D-29 album"
  - "ROADMAP criterion 5 F10 note: rw counter reported as '0 excluding the documented D-21 consumer exception', Jellyfin on its own line"
  - "REQUIREMENTS TAGR-05 ADDENDUM: the survivor's vendored config is in scope; the probe, not --pretend, is the instrument"
  - "PROJECT.md: entry-points table matches the repo; D-24 Discogs rotation recorded as a reasoned dismissal"
  - "CLAUDE.md + STACK.md: no instruction to keep, fix or unpin wrtag; D-14 sentence verbatim; 144-folder denominator; correction survives regeneration (parity proven)"
affects: [04-05, 04-07, 04-08, 04-09, 04-13, phase-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Generator-parity check: a read-only replica of gsd-tools generateStackSection() diffs CLAUDE.md's GSD:stack region against what regeneration from STACK.md would emit. Hand-edit both, then require parity, rather than running the generator"
    - "A correction in STACK.md survives regeneration only on a single line starting with '#', '|', '- ' or '* '. Blockquotes and prose are dropped"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-04-SUMMARY.md
  modified:
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/PROJECT.md
    - CLAUDE.md
    - .planning/research/STACK.md

key-decisions:
  - "Criterion 4's substitute instrument is a pair: the MB-only tag_album() probe (live embedart config -> 0 MB candidates; fixed config -> >=1) plus one hand-read beet import -t -W -C, both on a throwaway -l. The substance is kept, not reduced"
  - "D-24: Discogs token rotation is dismissed, not deferred. It is recorded in the sec=sys form with the operator's words verbatim; the four causes stay on record in 03-DECISION section 9 and DEF-03-21"
  - "D-14 sentence placed verbatim once per file (the headline finding 1 bullet); the What NOT to Use rows point to it rather than repeating it"
  - "The 144 figure is written with its split ('7,451 unsorted files, 144 folders in all'), not as '7,451 files across 144 folders', which would pair two numbers that describe different sets"
  - "CLAUDE.md was hand-edited and the generator was NOT run; byte parity with generator output was proven instead"

requirements-completed: []
requirements-partial: [TAGR-03, TAGR-05]

# Metrics
duration: ~13min
completed: 2026-09-11
---

# Phase 4 Plan 04: Documentary Corrections Summary

**Criterion 4 now names an instrument that can satisfy it at full strength. The session.py evidence
explains why `--pretend` returns zero candidates by construction, and the MB-only probe pair with
its D-17 negative control replaces it. Criterion 5 states its Jellyfin exception honestly. The D-24
Discogs rotation is on record as a reasoned dismissal. CLAUDE.md and its generator source no longer
tell anyone to keep, fix or unpin wrtag, and carry the D-14 sentence verbatim.**

## Performance

- **Duration:** about 13 min (21:45:30Z to 21:58:28Z)
- **Tasks:** 3 of 3
- **Files modified:** 5 (plus this SUMMARY)

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | D-20 amendments: ROADMAP criteria 4 and 5, REQUIREMENTS TAGR-05 addendum | `d96b9db` |
| 2 | PROJECT.md: entry-points table and the D-24 reasoned dismissal | `f8c8ccf` |
| 3 | CLAUDE.md and STACK.md: D-07/D-14 corrections in both (F15) | `8dc5b53` |

## What changed, per file

- **`.planning/ROADMAP.md`**: two added blockquotes inside Phase 4's success criteria, and nothing
  else. `git diff -U0` shows exactly two hunks (`+526,25` and `+554,9`) and zero removed lines.
  - Criterion 4: `**Amended 2026-09-11 by plan 04-04 (D-20).**` It quotes the `--pretend` clause and
    cites `beets/importer/session.py` v2.13.1 (`ImportSession.run()` appends only
    `stagefuncs.log_files` under `pretend`, and `lookup_candidates` only on the other branch). It
    names the pair: `scripts/spike03-discogs-probe.py --mb-only`, run inside the survivor on its
    `manual` profile against `Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost`. That run goes live
    `plugins: embedart` config → 0 MB candidates, then fixed config → ≥ 1. The second half is one
    agent-driven `beet import -t -W -C` aborted at the prompt. Both runs use a throwaway `-l`. The
    amendment ends "The substance is kept, not reduced".
  - Criterion 5: `**Amended 2026-09-11 by plan 04-04 (F10).**` It reads "0 excluding the documented
    D-21 consumer exception", identifies that exception as Phase 1's D-21, and puts Jellyfin on its
    own line.
  - Plan checkboxes and the Progress table were **not** touched.
- **`.planning/REQUIREMENTS.md`**: one line. The TAGR-05 traceability row gains
  `**ADDENDUM 2026-09-11 (04-04, D-20/D-27)**`. It covers scope (the survivor's
  `stacks/selfhosted/arrs/beets/config.yaml` plus `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml`)
  and the instrument (the probe pair, not `--pretend`), and ends "The text above is deliberately not
  rewritten." The TAGR-05 requirement text at lines 129-130 is unchanged.
- **`.planning/PROJECT.md`**: four hunks.
  - Line 11: the #306 annotation.
  - The soulbeet and wrtag entry-point rows, amended in-band and dated. The original cells stay
    readable, with a "*Was (2026-08-17):*" prefix on the wrtag state. The wrtag row paraphrases the
    rule and does not quote it.
  - A dated Reversibility note. It defers the outcome to plan 04-13's `beets.md` section.
  - A new Key Decisions row for D-24, in the `sec=sys` form.
  - The 7,451 count at line 72 is unchanged.
- **`.planning/research/STACK.md`** (the generator source):
  - A new `## Corrections after Phase 4 (2026-09-11)` section at the top, in the beets.md:981-990
    shape: what changed, why, and what was left standing and why.
  - A dated correction bullet under headline finding 1, carrying the D-14 sentence verbatim.
  - The migration paragraph is withdrawn, paraphrased rather than quoted.
  - The "fixable in one line" non-evidence line is corrected.
  - A decided/executed note under *Recommendation*.
  - The rate-limit row uses 144.
  - The four-line install block becomes one line: wrtag removed.
  - A soulbeet-config note.
  - Both *What NOT to Use* wrtag rows, the wrtag *Alternatives* row, the wrtag-wins variant bullet
    and the `v0.30.0+` compatibility row are corrected and dated.
- **`CLAUDE.md`**: 10 hunks. Every one falls inside a GSD region: line 102 in `project` (91-157),
  and the other nine in `stack` (159-344). The stack-region lines are byte-identical to what the
  generator emits from the new STACK.md.

## Acceptance

| Check | Result |
|---|---|
| Task 1 plan `<verify>` | `2` / `1` / `1`, pass |
| `grep -c 'Amended .* by plan 04-04'` ROADMAP | **2** |
| Phase 4 section: `session.py` / `lookup_candidates` / `Scarecrow` / `substance is kept, not reduced` / `excluding the documented D-21 consumer exception` | 1 / 1 / 2 / 1 / 1 |
| Phase 4 section: `Research\*\*: not needed` | **0** (see Deviation 2) |
| Original criterion-4 clause present | the literal one-line grep returns 0, a **defective assertion** (Deviation 1). Joined lines 521-522 match = **1**, and ROADMAP removed lines = **0** |
| TAGR-05 row contains `ADDENDUM` and `beets/config.yaml`; requirement text unchanged | yes; the only REQUIREMENTS hunk is `@@ -267 +267 @@` |
| Task 2 plan `<verify>` | `3` / `1` / `1`, pass |
| `not an oversight or a silence` ≥ 2 / `there is nothing there that has any value` = 1 / `DEF-03-21` ≥ 1 | 3 / 1 / 1 |
| Soulbeet and wrtag rows each contain `04-03` | 1 / 1 |
| `git diff PROJECT.md \| grep -E '^\+.*[A-Za-z0-9]{40}'` | **0 lines**. An extra screen for `discogs.env`, `/secrets/`, `user_token` and `token=` on added lines also returned **0** |
| Task 3 plan `<verify>` loop | pass, for both files |
| Per file: `works on none of v0.20.0, v0.33.0 or v0.34.0` / `EITHER fix the pin` / `1,000 folders` / `drop the Renovate rule pinning` | CLAUDE.md 1/0/0/0; STACK.md 1/0/0/0 (each was 0/1/1/1 before) |
| `grep -c '1-115' CLAUDE.md`, before → after | **1 → 1**. STACK.md is also 1 → 1 |
| `GSD:stack-start source:research/STACK.md` / `GSD:project-start source:PROJECT.md` | 1 / 1 |
| STACK.md heading `Corrections after Phase 4` | present (`## Corrections after Phase 4 (2026-09-11)`) |
| Generator parity, CLAUDE.md stack region vs generator output | **PARITY**, 181 lines before the edit and 182 after |
| CLAUDE.md #306 line equals PROJECT.md #306 line | identical |
| `git diff --stat` touches only the five files | yes |

### Generator parity: the instrument

`gsd-tools generate-claude-md` builds the stack region with `generateStackSection()`
(`~/.claude/get-shit-done/bin/lib/profile-output.cjs:328-357`). That function keeps only STACK.md
lines that start with `#`, `|`, `- ` or `* `. I wrote a read-only replica of its extraction loop,
kept only in the session scratchpad, which diffs the result against CLAUDE.md's region. Parity held
on the **unedited** files (181 lines), which proves the replica is faithful before I relied on it.
It was run again after the edits (182 lines), and a third time as a guard immediately before the
Task 3 commit. **The generator itself was never run**, so no SDK writer touched CLAUDE.md.

This is what makes F15's "the correction survives regeneration" true. Every correction that has to
reach CLAUDE.md was written in STACK.md as a single self-contained `- `, `|` or `#` line. The
explanatory prose in STACK.md's Corrections section is deliberately dropped by the generator, and
CLAUDE.md carries only that section's heading and one bullet.

## Deviations from Plan

### 1. [Defective assertion] Task 1's "original criterion 4 line is still present" grep cannot match

- **What:** the criterion looks for `` a `--pretend` run on one known-good album `` on one line. In
  ROADMAP that clause wraps across lines 521-522 (`…and a `--pretend`` / `run on one known-good
  album…`). The grep returned 0 before this plan too.
- **Evidence the outcome is correct:** joining lines 521-522 matches exactly once, and
  `git diff .planning/ROADMAP.md | grep -c '^-[^-]'` = **0**, so no original line was altered. Both
  conditions were a hard guard on the Task 1 commit. The prose was not edited to satisfy the grep.

### 2. [Already in place] The Research-line replacement was not made

- The action asks to replace `**Research**: not needed — retirement is deletion plus documented
  config changes.` That line no longer existed. The Phase 4 section already read
  `**Research**: done 2026-09-11 (`04-RESEARCH.md`). *Originally "not needed — …"; … fifteen facts
  … (F1–F15), ruled on as D-27–D-35.*`, which is in HEAD before this plan and was written at
  planning time. It already states everything the replacement would, so rewriting it would only be
  churn. The acceptance check (`Research\*\*: not needed` in the Phase 4 section = 0) holds without
  an edit. The other four phases' `not needed` lines are not Phase 4's and were left alone.

### 3. [Addition, needed for Task 3 (e)] PROJECT.md line 11 annotated

- Task 3 (e) makes CLAUDE.md line 102 (#306) match PROJECT.md "after Task 2". But Task 2's action
  did not name PROJECT.md line 11, which would have made (e) a no-op. I annotated line 11 in Task 2
  ("#306 (soulbeet; plan 04-03 deleted its definition from the repo on 2026-09-11, and closing the
  issue is pending plan 04-07)") and mirrored it byte for byte into CLAUDE.md. `gh issue view 306`
  confirmed the issue is **OPEN**, so "pending" is accurate.

### 4. [Accuracy] The 144 figure was written with its split, not as a straight substitution

- (c) says to keep 7,451 and replace the folder figure with 144. A straight swap would read
  "7,451 files across 144 folders", but 03-DECISION § AMENDMENT 03-07 § 1 says the 7,451 files are
  `unsorted`'s **120** folders, and 144 folders hold **7,728** files. The row now reads "7,451
  `unsorted` files, 144 folders in all", followed by the dated split and the Phase 3 test outcome for
  that row (T2: 21.8 min projected, zero HTTP 429, not fired). Both of the plan's numbers are
  present and neither is misattributed. The withdrawn figure is paraphrased as "about seven times
  the measured count".

### 5. [Scope, within the plan's files] Sweep hits beyond (a)-(e) corrected

- These were corrected because each tells a reader wrtag at v0.33.0 would work, or presents it as a
  live option, and every one is in 04-RESEARCH's D-07 sweep row for CLAUDE.md or is that row's
  STACK.md source:
  - STACK.md's "fixable in one line" non-evidence line;
  - the soulbeet-config note under Installation;
  - the `v0.30.0+` compatibility row (CLAUDE.md 325);
  - the wrtag-wins variant bullet (CLAUDE.md 315);
  - the wrtag *Alternatives* row (CLAUDE.md 283).
- **Left standing deliberately:** the head-to-head table, the overturning table's other rows, the
  `wrtag` "Retire" row, the Sources bullets, the v0.20.0 source analysis and the v0.30.0 migration
  table. All were correct against what they measured, and the Corrections section says so.

### 6. [Placement] The D-14 sentence appears once per file

- (a) could be read as putting it in the headline finding **and** in each What NOT to Use row. It is
  verbatim once per file, in the headline-finding-1 bullet. The rows point to "headline finding 1"
  so CLAUDE.md, which loads into every session, does not repeat a 60-word sentence. The acceptance
  check is ≥ 1, and it is met.

**Total:** 1 defective assertion (recorded, not edited around), 1 item already in place, 1 needed
addition, 1 accuracy adjustment, 1 bounded sweep widening, 1 placement choice. No file outside the
plan's five was touched.

## Truthfulness notes: stated as future, because they are future

- `scripts/spike03-discogs-probe.py` has **no** `--mb-only` mode today (`grep -c mb-only` = 0). The
  ROADMAP amendment says plan 04-08 adds it.
- `stacks/selfhosted/arrs/beets/config.yaml` does **not** exist today; the directory holds only
  `beets.yaml`. The TAGR-05 addendum says plan 04-08 creates it and that it does not exist at the
  addendum's commit.
- No host runtime state is claimed as done. PROJECT.md's wrtag row cites 04-01's measurement (no
  wrtag container among 97, unfiltered `docker ps -a`) and says the image, appdata and DNS record
  remain until 04-07. The Reversibility note says the database reduction is "in progress, not done".

## Observations for the orchestrator (not fixed, out of scope)

1. **CLAUDE.md's `project` region was already out of sync with PROJECT.md before this plan.** Its
   Reversibility bullet lacks PROJECT.md's "four beets databases" passage, and now also lacks
   today's dated note. A `generate-claude-md` run would rewrite that bullet. Only line 102 was in
   scope here, per (e). The `stack` region, by contrast, is proven in parity.
2. **Nobody owns an obligation that beets.md recorded for Phase 4.** `stacks/selfhosted/arrs/beets.md:989`
   says *"Phase 4 owns amending the constraint in `CLAUDE.md` and `PROJECT.md`"*. That is the "beets
   has no `undo`" constraint, which beets-flask rc6's `UNDO IMPORT` narrows. A grep of every
   `04-*-PLAN.md`, `04-CONTEXT.md` and `04-RESEARCH.md` for `UNDO IMPORT|no undo|undo command`
   returns **nothing**, so no Phase 4 plan picks it up. Recommend adding it to 04-13's final sweep or
   deferring it explicitly.
3. PROJECT.md Key Decisions row 1 ("Tagger choice deferred to a spike phase", `— Pending`) is stale,
   because Phase 3 decided. That is phase-transition housekeeping (`/gsd-transition`), not this
   plan's.
4. STACK.md's *Recommendation* prose still says "~110 of ~170 backlog folders". That is a different
   backlog count on an unstated basis, and it was left as dated snapshot text. It is not in CLAUDE.md,
   because the generator drops prose.

## Requirements

- **TAGR-05:** not completed by this plan. Its scope and instrument are now stated correctly (the
  addendum). The config edits and the probe are 04-08, 04-09 and 04-10.
- **TAGR-03:** its documentary half is advanced. No repo document now instructs anyone to keep, fix
  or unpin wrtag.
- STATE.md was **not** touched, and no `gsd-sdk query state.*` or `roadmap.*` verb was called.
  `git diff --stat d3c3bb0 HEAD -- .planning/STATE.md` is empty. No ROADMAP plan checkbox or
  Progress-table line appears in the diff.

## Known Stubs

None.

## Threat Flags

None. T-04-04-01 is mitigated: the D-24 row carries no token value, prefix or path, and the diff was
screened for 40-character runs and secret-path strings, 0 each. T-04-04-02 is mitigated: the
original criterion-4 wording is quoted and still present, both amendments are dated and attributed,
and "substance is kept, not reduced" is stated. T-04-04-03 is mitigated: the correction lands in
STACK.md, and generator parity is proven.

## Self-Check: PASSED

- FOUND commits `d96b9db`, `f8c8ccf` and `8dc5b53` (`git log`). Post-commit deletion check: 0
  deleted files in each.
- FOUND `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `CLAUDE.md`
  and `.planning/research/STACK.md`, each carrying the strings in the Acceptance table (re-grepped
  after writing).
- Generator parity: PASS (182 lines). CLAUDE.md hunks outside a GSD region: 0.
