---
phase: 06-tagger-configuration-and-dry-run
plan: 50
subsystem: docs
tags: [r6-01, r6-02, r6-03, r6-04, r6-05, r6-06, r6-07, r6-08, r6-09, dispositions-register, id-namespace, d-r6-m4, pending-not-published, conf-06, round-6]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-REVIEW.md` — the round-6 source review, 0 Critical / 3 Warning / 2 Info, whose `WR-*`/`IN-*` IDs alias round 1's namespace"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-DISPOSITIONS-GAP3.md` — the register shape this file matches section for section, and the closed four-word disposition / three-word fix-kind vocabularies"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-46-SUMMARY.md`, `06-47-SUMMARY.md`, `06-48-SUMMARY.md`, `06-49-SUMMARY.md` — the dispositions and fix kinds recorded here are the summaries', re-read from them"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`artifacts/06-47-disposition-consistency.txt` — the four-record audit, which named NO divergence owned by this plan (0 DISAGREE)"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-VERIFICATION.md` — `gaps_found`, 5/6, and its two secondary findings, so § Corrections is accurate rather than invented"
provides:
  - "`06-DISPOSITIONS-GAP4.md` — round 6's disposition register: the nine-row `R6-*` mapping table ahead of the first citation, all five findings plus four round items, the WR-02 ACCEPTED position with a measured self-binding claim, `D-R6-M4`, five refusals, and a named `ROUND CLOSE` placeholder owned by `06-52` task 3"
  - "`06-REVIEW.md` — an append-only wiring block naming the register, the namespace and the aliasing, with the content above the append point proven byte-identical to the base commit"
  - "`.planning/ROADMAP.md` — round 6's disposition amendment in paired `R6-NN (WR-NN)` form, a status-row narrative clause, and a MEASURED plan-count numerator that is not `52/52`"
  - "`.planning/STATE.md` — the round-6 wave-3 position block with both operator actions PENDING and no outcome stated for either"
affects: [06-51, 06-52, phase-7-entry, any-future-round-7]

tech-stack:
  added: []
  patterns:
    - "A wave-N record must not publish a wave-N+1 outcome: write the state as the literal word PENDING in EVERY record (register, ROADMAP, STATE — not the two you were looking at), name the owning plan, name the `DEF-` entry that is the authoritative fallback, and name the plan that folds the real outcome back"
    - "Phrase PENDING prose as a DATED statement about the moment of writing ('were recorded as PENDING when this register was written at wave 3'), never in the bare present tense — the bare form goes false the instant the closer does its job, and it sits outside the table-row anchor that re-checks the rows"
    - "A count assertion over a table must anchor on `^\\|` so that prose discussing the counted word cannot inflate it — and must be driven against BOTH a two-row control (returns 2) and a prose control (returns 0)"
    - "Scope a status-word check to the STATUS CELL by `awk -F'|'` field extraction and lower-case it: a row-wide case-sensitive search cannot fail, and a row-wide case-insensitive one fails on legitimate history in the narrative cell"
    - "Append to a multi-thousand-character table cell and then prove the base cell content is an exact byte PREFIX of the new one — `--stat` looking correct is exactly how a Notes cell got wiped in this project before"
    - "Never introduce a literal `|` into a markdown table cell: it re-splits every downstream field, silently changing what a field-indexed measurement measures"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP4.md"
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-50-SUMMARY.md"
  modified:
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW.md"
    - ".planning/ROADMAP.md"
    - ".planning/STATE.md"

key-decisions:
  - "THE FIVE FINDINGS TAKE FOUR CLOSED-VOCABULARY WORDS AND NO FIFTH WAS INVENTED. 4 FIXED (R6-01, R6-03, R6-04, R6-05) + 1 ACCEPTED (R6-02) = 5, reconciling against the review's frontmatter 0+3+2 and the fix kinds 1 CODE + 3 CLAIM CORRECTION + 1 BOTH. `PENDING` is NOT a disposition word: it appears only on the two non-review rows and is excluded from all three routes, with an explicit sentence naming `06-52` task 3 as the owner of the reconciliation's extension when those rows are filled."
  - "THREE OF THE FIVE FIXES ARE DOCUMENTS WRITTEN, NOT CLAIMS NARROWED, AND THE JUDGEMENT CALL IS STATED RATHER THAN SMOOTHED. The closed fix-kind set has no word for 'durable documentation added', so `CONVENTIONS.md`, the `beets.md` pointer and the `CLAUDE.md` mirror are each recorded as CLAIM CORRECTION — the set's name for *no executable line changed* — with each row saying in its own text what was actually written. Inventing a fourth fix kind would have broken the reconciliation the register exists to publish."
  - "R6-04's TWO HALVES TAKE ONE DISPOSITION AND THE SPLIT IS NAMED IN BOTH THE ROW AND THE REFUSALS SECTION. IN-01 names two files; only `CONVENTIONS.md` was written. The row reads FIXED and states that the architecture half is ACCEPTED, with the reason (the estate is already mapped by four documents linked from `CLAUDE.md` § Documentation) and a revisit condition, rather than splitting the row into a fifth word."
  - "THE ROADMAP NUMERATOR WAS MEASURED, NOT ASSUMED, AND IT IS NOT `52/52`. `ls | grep -cE '^06-[0-9]{2}-SUMMARY\\.md$'` returned **49** at task 2 (0 `-PARTIAL.md` files), which is what the row already read, so no numerator edit was needed at that point; the metadata commit bumps it to **50** once this plan's own summary exists, which is the same measured recipe one commit later. Per `D-R6-M4` the column means EXECUTED, and `06-52` closes it to 52/52 at wave 5."
  - "A LITERAL `|` WAS INTRODUCED INTO THE STATUS ROW AND CAUGHT BY MEASUREMENT, NOT BY REVIEW. The first draft of the round-6 status-row clause quoted the Phase 4 precedent as `16/16 | In Progress`. The Notes cell's `awk -F'|'` field-5 length then read 34,712 against an added text of ~1,890 bytes — the arithmetic did not close, because the pipe had re-split the row from 6 fields into 7. Rewritten without the pipe; field count 6 at base and 6 now; the base cell content proven an exact byte prefix of the new one."
  - "THE `06-46` CHECKBOX WAS TICKED AS A RULE 1 CORRECTION; ITS DESCRIPTION WAS NOT REWRITTEN. `06-46` executed (its `-SUMMARY.md` exists and both task commits are in `git log`) but its ROADMAP plan line still read `- [ ]`, and it is one of the seven lines this plan was told to verify. The box is now `- [x]`. The missing `*(executed …)*` clause that 06-47/48/49 each added is a stylistic gap, not a wrong claim, and was deliberately left rather than invented."

metrics:
  duration: "~40 min"
  completed: "2026-09-24"
  tasks: 2
  commits: 2
  files_created: 1
  files_modified: 3
  estate_contact: "none — zero ssh, zero docker, zero HTTP, zero package installs"
---

# Phase 06 Plan 50: Round 6's Disposition Register and Its Three Records — Summary

Round 6 is now recorded where the next context boundary cannot lose it: a 536-line register with a
fresh `R6-*` namespace mapped to the review's aliased IDs, all five findings dispositioned in one
closed word each, WR-02 resolved one way with a measured self-binding claim — and, in all three
records rather than the two that were being discussed, the two unexecuted operator actions written as
`PENDING` with no outcome stated.

**BASE COMMIT `3085da162460448aba1eb151ad4cabac390abbb1`**, captured by `git rev-parse HEAD` before
anything was written, because every byte-identity claim here is anchored to it and not to a moving
`HEAD`. This plan stages and commits twice, so the blind state was the likely one.

## What Was Built

### Task 1 — `06-DISPOSITIONS-GAP4.md` (commit `21eaad4`)

**536 lines**, matching `06-DISPOSITIONS-GAP3.md` section for section: *Why this file exists*, the
*Source* table, **THE ID MAPPING TABLE**, the aliasing clauses with their measured counts and
re-derivable recipe, `D-R6-M4`, *Counts* reconciling three ways, the closed vocabularies, the
per-finding register, *The WR-02 position*, *What was driven and what was not*,
*Verified-and-clean*, *The round's refusals*, *Corrections to the source material*, *ROUND CLOSE*,
*What this register does NOT do*, and *Lessons*.

**The mapping table precedes the first citation** — its heading is at line 46, the register's first
row at line 205.

| Review ID | In-band | Owner | Disposition |
|---|---|---|---|
| `WR-01` | `R6-01` | 06-46 | **FIXED** (CODE) |
| `WR-02` | `R6-02` | 06-49 | **ACCEPTED** (CLAIM CORRECTION) |
| `WR-03` | `R6-03` | 06-46 + 06-49 | **FIXED** (BOTH) |
| `IN-01` | `R6-04` | 06-49 | **FIXED** (CLAIM CORRECTION) |
| `IN-02` | `R6-05` | 06-47 | **FIXED** (CLAIM CORRECTION) |
| — | `R6-06` | 06-48 | **FIXED** — outside the reconciliation |
| — | `R6-07` | 06-48 | **FIXED** — outside the reconciliation |
| — | `R6-08` | **06-51**, wave 4 | **PENDING** |
| — | `R6-09` | **06-52**, wave 5 | **PENDING** |

**Counts reconcile three ways and the register says so:** review frontmatter `0 + 3 + 2 = 5`;
dispositions `4 + 0 + 1 + 0 = 5`; fix kinds `1 + 3 + 1 = 5`. The three routes agree, so there is no
disagreement to state. An explicit ⚠ paragraph scopes the arithmetic to `R6-01 … R6-05`, places
`R6-06 … R6-09` outside it, and names **`06-52` task 3** as the owner of the extension — *a
reconciliation that is never re-run after its table grows is a check that has stopped checking.*

### Task 2 — the three records (commit `0ab8b4e`)

**(a) `06-REVIEW.md` — 48 insertions, 0 deletions.** A wiring block appended at the very end naming
the register, stating that the review's `WR-*`/`IN-*` IDs **alias** round 1's namespace already cited
in band across all six scripts, giving the five-row ID map, and stating the round's totals.

**(b) `.planning/ROADMAP.md`** — three additive edits: the seven round-6 plan lines **verified**, not
re-appended (each present exactly once; `06-51` and `06-52` each carrying `autonomous: false`); a
63-line round-6 amendment to the Phase 6 disposition paragraph; and a round-6 clause appended to the
Phase 6 status row's narrative cell. The `**Plans**: 45 plans in 23 waves` header is byte-untouched
(count **1**) — it is `06-52`'s.

**(c) `.planning/STATE.md`** — a 69-line round-6 wave-3 block appended to `## Current Position`,
**69 insertions / 0 deletions**, hand-edited. The `Plan:` line already read the measured `49 of 52`
and needed no edit, which is the safest outcome for a multi-line field.

## Key Measurements

| Measurement | Value |
|---|---|
| base commit | `3085da162460448aba1eb151ad4cabac390abbb1` |
| register lines / mapping-table heading line / first register row line | **536** / **46** / **205** |
| `^\|.*R6-0[89].*PEN[D]ING` over the register | **2** (control: 2 rows → **2**, prose line → **0**) |
| `R6-0[1-9]` occurrences in the register | **35** |
| executed plans, `ls \| grep -cE '^06-[0-9]{2}-SUMMARY\.md$'` | **49** at task 2; **0** `-PARTIAL.md` |
| ROADMAP status row | `49/52 \| In Progress`; `52/52` count **0** |
| status **cell** by `awk -F'\|'` field 4, lower-cased | `in progress` (control row reading `COMPLETE` → printed `complete`) |
| phase-6 row field count, base / now | **6** / **6** |
| Notes cell (field 5) bytes, base / now | **33,488** / **35,444** — base content an exact byte **PREFIX** of the new cell |
| ROADMAP deleted lines (whole file) | **2** — the `06-46` checkbox line and the status row, both replaced by their own appended-to forms |
| `WR-02` in ROADMAP, before / after (lines; occurrences) | **6 / 7**; occurrences **6 / 7** |
| bare `WR-0` token in newly written text not preceded by `R6-NN (` | **0** in the 63-line amendment, **0** in the 1,890-byte row clause |
| `R6-02 (WR-02)` paired form in the amendment | **1** |
| STATE.md insertions / deletions | **69 / 0**, single hunk `@@ -301,0 +302,69 @@` |
| STATE / ROADMAP numerators | **49** / **49** — identical, extracted and compared |
| pre-existing `WR-*`/`IN-*` in-band citations, `75c7989` / `3085da1` | **94 / 94** — round 6 added none |
| the five reused IDs, per file | `WR-01` 16, `WR-02` 4, `WR-03` 15, `IN-01` 2, `IN-02` 2 = **39** |
| round 6's whole script footprint | **1** file, **+6 / −1** lines; 3 comment, 2 emitted output, 1 executable; **0** lines of new in-band narrative |
| `REQUIREMENTS.md` / `scripts/` under `git diff --exit-code HEAD --` | **0** each |
| CONF-04 checkbox, ticked / unticked | **0** / **1** (ticked recipe driven to **1** against a control first) |
| forbidden refresh-mode token in ROADMAP, base / now | **2** / **2** — no third occurrence added |
| forbidden token / UI-phrase over the register | **0** / **0** |

**No `state.*` or `roadmap.*` SDK verb was invoked.** Every planning-document edit was made by hand
and its diff **body** read, not just `--stat` — the recorded failure mode in this project is a
`roadmap.update-plan-progress` wiping a multi-thousand-character Notes cell while `--stat` looked
correct.

## Every Zero-Expecting Recipe Was Driven Against A Control First

`DEF-06-45-04`'s defect is a published recipe that can never match, printing a true `0` the recipe did
not earn. Seven screens here expect a specific value; all seven were driven against a control built to
make the **identical** recipe answer differently, outside the repository, none staged.

| Screen | Recipe | Control | Real target |
|---|---|---|---|
| `PENDING` on exactly the two mapping rows | `-cE '^\|.*R6-0[89].*PEN[D]ING'` | **2** (two-row control) | **2** |
| the same recipe over prose | same | **0** (prose control containing the real word) | — |
| a ticked CONF-04 checkbox | `-c '^- \[x\] \*\*CONF-04'` | **1** | **0** |
| an unticked CONF-04 checkbox | `-c '^- \[ \] \*\*CONF-04'` | — | **1** |
| a `52/52` Phase 6 status row | `-cE '^\| 6\. Tagger… \| 52/52 \|'` | **1** | **0** |
| the status cell can read non-`in progress` | `awk -F'\|'` field 4, lower-cased | control row `COMPLETE` → printed `complete` | `in progress` |
| forbidden refresh-mode token | `-cE 'Full[R]efresh'` | **1** (and `-cF` → **0**, a third re-drive of `DEF-06-48-01`) | **0** |
| forbidden UI phrase | `-ciE 'replace all [m]etadata'` | **1** | **0** |

Every `grep` was invoked as `/usr/bin/grep`, by absolute path — the operator's zsh aliases `grep` to
`ugrep` and it has silently matched nothing in this phase before.

## The WR-02 Position, Stated Once

**`R6-02 (WR-02)` is ACCEPTED, with rationale. It is not fixed this round, and the round binds itself
so the cost does not grow.** The proposed fix is a bulk relocation of round-by-round narrative out of
`quick-health-check.sh` (3,148 lines), `phase06-oracle.sh` (3,274) and four siblings — the largest
possible diff across the six most heavily reviewed files in this repository, at the end of a recursion
in which every round's own diff became the next round's findings. The review itself calls that
narrative "a genuine asset for provenance". The durable half is taken as a forward rule
(`CONVENTIONS.md` convention 12, plan 06-49) and the existing narrative is **not** stripped.

**The self-binding claim is measured, not asserted:** one file under `scripts/` changed across the
whole round, `+6 / −1` lines, of which **3** are single-line `R6-01` / `R6-03` citations at the changed
site and **2** are emitted remediation — *failure output*, printed where the maintainer is standing,
which is the opposite of the WR-02 problem — leaving **0** lines of new in-band historical narrative
and **0** new `WR-*`/`IN-*` citations. The recipes that produced all three figures are published in the
register.

## Refusals, Recorded As Loudly As The Work

1. **`ST_PLANNED_CASES=7` was NOT touched** — WR-03's third site, excluded by name by round 4
   (`DEF-06-39-02`): a gated pin over an **unconditionally executed** set, where "fixing" it breaks a
   working guard. Revisit condition recorded.
2. **No `ARCHITECTURE.md` was created** — IN-01's architecture half is **ACCEPTED**; the estate is
   already mapped by `NETWORK.md`, `MEDIA.md`, `DEPLOYMENT.md` and `TAILSCALE.md`, all four linked
   from `CLAUDE.md` § Documentation, so a stub would add a fifth, emptier front door.
3. **`artifacts/06-43-conf04-verdict.txt` was not edited** — a dated record; proven immutable against
   plan 06-48's captured base commit by **sha256** rather than by an index-anchored `git diff`.
4. **The bracketing convention was NOT widened to `ROADMAP.md`** (`DEF-06-48-02`) — scoped by
   function, not directory name; **no `ROADMAP.md` token edit made or required**, and the whole-file
   token count is **2 at base and 2 now**.
5. **No CONF-04 work of any kind** — no re-probe, no mtime touch (a measured negative,
   `DEF-06-45-02`), no refresh verb, no checkbox move. E6 owns the Jellyfin half and E6's second
   measurement stays with Phase 7 on every branch.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug in the record] The `06-46` ROADMAP plan line was unticked for a plan that executed**

- **Found during:** Task 2, step 1 — verifying the seven round-6 plan lines.
- **Issue:** `06-46` has a `-SUMMARY.md` and both task commits are in `git log`, but its ROADMAP plan
  line still read `- [ ]` while `06-47`, `06-48` and `06-49` were `- [x]`. `06-46`'s own metadata
  commit bumped the status-row count and omitted its checkbox.
- **Fix:** Ticked to `- [x]`. The **description was not rewritten** — the missing `*(executed …)*`
  clause its three siblings each added is a stylistic gap, not a wrong claim, and inventing one was
  outside this plan's fence.
- **Also observed, deliberately NOT touched:** `06-45`'s line is unticked in the same way. It belongs
  to round 5, not to the seven lines this plan was told to verify, and is recorded here rather than
  silently fixed or silently ignored.
- **Files modified:** `.planning/ROADMAP.md`. **Commit:** `0ab8b4e`.

**2. [Rule 1 — Bug caught by measurement] A literal `|` in the status-row clause re-split the table row**

- **Found during:** Task 2, step 3 — re-measuring the Notes cell after appending.
- **Issue:** The first draft quoted the Phase 4 precedent as `16/16 | In Progress`. Inside a markdown
  table row that pipe is a **cell delimiter**: the row went from 6 `awk -F'|'` fields to 7, and the
  field-5 length read 34,712 against an added text of ~1,890 bytes. The arithmetic not closing is what
  exposed it; the status-cell criterion (field **4**, upstream of the damage) still passed, so the
  criterion alone would not have caught it.
- **Fix:** Rewritten without the pipe. Field count **6** at base and **6** now; Notes cell
  33,488 → 35,444, and the base content proven an exact byte **prefix** of the new cell.
- **Files modified:** `.planning/ROADMAP.md`. **Commit:** `0ab8b4e`.

**3. [Rule 1 — Nearly published an outcome before it happened] A commit hash that did not exist yet**

- **Found during:** Task 2, step (c) — re-reading the STATE block before staging.
- **Issue:** The block's first draft named *two* task commits, the second being a hash this plan had
  not yet produced. That is the same class as the finding the plan exists to prevent, one level down:
  a record asserting something that has not happened.
- **Fix:** Replaced with `21eaad4` (the register) plus "the commit carrying this block". No fabricated
  hash reached a commit.
- **Files modified:** `.planning/STATE.md`. **Commit:** `0ab8b4e`.

### Nothing Else Deviated

No architectural change, no checkpoint, no authentication gate, no package install, no estate contact.
Plan 06-47's consistency artifact named **no** `ROADMAP.md` divergence owned by this plan (0 DISAGREE),
so the register carries no correction from it — recorded as a result rather than a silence — and
06-47's `COULD NOT LOOK` / no-owner judgement on `deferred-items.md`'s silence is **dispositioned here
as standing**, because silence is not contradiction.

## What This Plan Did NOT Do

- **No verification and no verdict change.** No `/gsd-verify` run; `06-VERIFICATION.md` stands at
  `gaps_found`, 5/6, un-rescored.
- **`.planning/REQUIREMENTS.md` byte-untouched**, `- [ ] **CONF-04**` stands, no checkbox moved, and
  `requirements mark-complete` was not run.
- **`scripts/` byte-untouched** — `git diff --exit-code HEAD -- scripts/` returns 0 at both task
  commits. No artifact written by an earlier plan and no prior `DEF-` entry was edited.
- **The ROADMAP status word was not changed** and the plan count was **not** written `52/52`.
- **The `**Plans**: … plans in … waves` header was not touched** — `06-52`'s, per `D-R6-M4`.
- **`06-REVIEW.md` was not overwritten and nothing above the append point was edited** — proven by
  `head -n 170 | cmp -s` against `git show <base>:…/06-REVIEW.md`.
- **No outcome was stated for `R6-08` or `R6-09`** — no commit the host moved to, no digest verdict,
  no `proceed`/`halt` answer, no `hold`/`release`/`defer` answer. Asserted positively (the block
  carries `R6-08`, `R6-09`, `PENDING`, `DEF-06-51-01`, `DEF-06-52-01`, `06-52`) and negatively (six
  paraphrase screens each returning 0), and read by eye as well as by grep, because a grep alone will
  not catch a paraphrase.

## Known Stubs

**One, by design and by name: `06-DISPOSITIONS-GAP4.md` § `ROUND CLOSE` is a placeholder.** It states
in its own text that it is not yet written, names **plan `06-52` task 3** as its owner, names
`DEF-06-51-01` and `DEF-06-52-01` as its sources and authoritative fallback, and lists the four things
`06-52` owes when it fills the section. This is not an unwired stub: a placeholder that names its
owner is a commitment, where an absent section is an omission nobody notices. If the round halts at
wave 4 or 5, the section stays as written and **that is the correct outcome** — an incomplete record
beats a wrong one.

## Threat Register Outcome

| Threat ID | Outcome |
| --- | --- |
| T-06R6-20 | `06-REVIEW.md` append-only: 48 insertions / 0 deletions, content above the append point `cmp -s`-identical to base `3085da1` |
| T-06R6-21 | No `state.*` / `roadmap.*` verb invoked; STATE 69/0 in a single insertion hunk; ROADMAP's only two deleted lines are the checkbox line and the status row, each replaced by its own appended-to form, with the Notes cell proven prefix-preserved |
| T-06R6-22 | `REQUIREMENTS.md` byte-unchanged under `HEAD --`; unticked-box grep 1 / ticked 0 with the ticked recipe driven; status **cell** pinned case-insensitively to `in progress` by a field-4 extraction driven against a `COMPLETE` control |
| T-06R6-23 | `R6-*` namespace fresh; mapping table at line 46 ahead of the first row at 205; collision counts re-measured (39 / 94, identical at both commits); every round-6 reference in the added ROADMAP text in paired `R6-NN (WR-NN)` form, 0 bare `WR-0` |
| T-06R6-24 | `git diff --exit-code HEAD -- scripts/` returns 0 at both task commits |
| T-06R6-43 | `PENDING` in all **three** records with `06-52` task 3 named as closer in each; numerator the measured executed count, never `52/52`; every PENDING prose sentence dated to the moment of writing |
| T-06-SC | No package-manager install of any kind |

## Commits

| Task | Commit | Content |
| --- | --- | --- |
| 1 | `21eaad4` | `06-DISPOSITIONS-GAP4.md` — the register, 536 lines |
| 2 | `0ab8b4e` | `06-REVIEW.md` wiring block (append-only), ROADMAP round-6 amendment + status-row clause, STATE round-6 block |

## Self-Check

- `06-DISPOSITIONS-GAP4.md` — FOUND, 536 lines, `file` reports `Unicode text, UTF-8 text`.
- `06-50-SUMMARY.md` — FOUND.
- `06-REVIEW.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — FOUND, all modified additively.
- Commits `21eaad4` and `0ab8b4e` — both present in `git log`.
- Both tasks' `<automated>` verify blocks re-run at HEAD: **PASS**.
