---
phase: 03-tagger-spike
verified: 2026-09-04T18:40:00Z
status: passed
score: 8/8 roadmap success criteria verified; 5/5 orchestrator-specific checks verified
overrides_applied: 0
gaps: []
deferred: []
human_verification: []
---

# Phase 3: Tagger Spike Verification Report

**Phase Goal:** One tagger *and* the interface the operator will actually meet it through are
chosen from measurements taken on this library's own content, against overturning thresholds
committed to before the evidence is collected.
**Verified:** 2026-09-04
**Status:** passed
**Re-verification:** No — initial verification

## Method note

This is a spike phase. Its deliverable is a decision backed by measurement, not working software.
Verification below is goal-backward against that standard: every threshold, every teardown claim
and every "not measured" gap was independently re-derived from git history and the live estate —
none of it was taken from SUMMARY.md narrative.

## Goal Achievement

### Observable Truths (ROADMAP Phase 3 success criteria)

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Discogs match rate recorded over ~20 normalised DJ folders, un-normalised rate recorded beside it | ✓ VERIFIED | `03-DECISION.md` T1 row: weighted strict 27.08% (normalised), un-normalised weighted strict 27.08% / loose 40.16% reported beside it; unweighted 25.00% also reported. Traced to `03-DISCOGS-EVIDENCE.md` |
| 2 | Twenty folder imports timed with `discogs` enabled, extrapolated against 60 req/min ceiling to a stated hours-for-backlog figure | ✓ VERIFIED | T2: 21.8 min projected for 144-folder backlog (naive baseline 22.0 min), pure-API floor 7.43 min at confirmed ceiling of 60 req/min, M=3.125 req/folder measured on both instruments |
| 3 | wrtag disqualifier run and outcome recorded either way, at v0.20.0/v0.33.0/v0.34.0 on single- and multi-disc | ✓ VERIFIED | `03-WRTAG-EVIDENCE.md` (referenced), `03-DECISION.md` axis-one row 3: v0.20.0 renders with `-1 -` prefix bug + multi-disc template error; v0.33.0/v0.34.0 refuse at startup, exit 2. Independently confirmed live: images `sentriz/wrtag:v0.33.0`/`v0.34.0` pruned post-measurement, `v0.20.0` retained untouched (it predates this phase) |
| 4 | Recorded decision names one tagger and states concretely what happens to Mastermix/DMC/Music Factory content under it | ✓ VERIFIED | `03-DECISION.md` § Criterion 4: beets named; `beet import -A` after normalisation, `--set albumtype=dj` routing; DMC stratum explicitly scored (0/4 strict); beets-flask `bootleg` inbox as the same primitive via a different front end |
| 5 | Pre-committed overturning thresholds written before evidence collection; decision states what was tested and what each returned | ✓ VERIFIED — independently re-derived, see "Honesty fence" below | T1/T2/T3 threshold text byte-identical to commit `137b6d9e`, pushed to `origin/main` before any evidence plan ran |
| 6 | Decision recorded along two separately-scored axes (engine, front end) | ✓ VERIFIED | `03-DECISION.md` § Axis one (beets, on Discogs coverage + path-format render) and § Axis two (front end, on the policy-inbox architecture vs raw prompt), explicitly stated as scored on different evidence with different reasoning — "None of them is 'beets won axis one, therefore its front end wins'" |
| 7 | beets-flask evaluated by name on axis two, known frictions recorded as part of the evaluation | ✓ VERIFIED | `03-DECISION.md` § Criterion 7 / `03-BEETS-FLASK.md`: all 8 researched frictions carry an observed/not-exercised verdict, plus a 9th found during deployment (config-schema rejection of `plugins:` as a string). Deployed as `metasauce/beets-flask:v2.0.0-rc6`, digest recorded |
| 8 | Honest ergonomics verdict in the operator's own terms — "it works and I will still open it," not "it works" | ✓ VERIFIED | `03-DECISION.md` § Criterion 8: operator's verbatim quote reproduced, explicitly distinguishing legibility ("I understand what's happening") from correctness (the same interface silently dropped 9 files and mis-tagged 4 tracks) |

**Score:** 8/8 ROADMAP success criteria verified.

### Orchestrator-specific verification (independently re-derived, not taken on trust)

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Honesty fence: T1/T2/T3 text, falsifiable form and instruments byte-identical to pre-evidence commit `137b6d9e92cb44d9c6a48b3963bb33fe0194622f`; all deletions are PENDING cells or verbatim-preserved claim-audit rows | ✓ VERIFIED | `git show 137b6d9e:.../03-DECISION.md` diffed cell-by-cell against the current file. Threshold/Falsifiable-form/Instrument columns for T1, T2, T3 match exactly (only `Tested?`/`Returned` changed). All 36 diff-deleted lines are `PENDING` table cells; rows 3a/3b of the D-12 claim audit have their original wording preserved as a literal prefix with appended confirmation text, not rewritten. `03-ERGONOMICS-SHEET.md` lines 1-86 (definitions, counting rules, column structure) are byte-identical to the pre-evidence commit; only the ten result rows and later amendment sections changed |
| 2 | T1 FIRED (27.08% weighted vs 40%), T2 NOT FIRED, T3 FIRED, each traceable to a committed artefact | ✓ VERIFIED | All three verdicts read directly from `03-DECISION.md`'s threshold table with full supporting numbers, cross-referenced to `03-DISCOGS-EVIDENCE.md` (T1/T2) and `03-ERGONOMICS-SHEET.md` (T3, operator's verbatim self-assessment obtained at 03-11 close) |
| 3 | Criterion 5's custody: `137b6d9e…` is an ancestor of `origin/main` | ✓ VERIFIED | `git merge-base --is-ancestor 137b6d9e92cb44d9c6a48b3963bb33fe0194622f origin/main` → true (and true against local HEAD) |
| 4 | Teardown happened on the estate, not just in the record | ✓ VERIFIED — live SSH checks, read-only | See "Teardown verification" table below |
| 5 | Honesty of gaps: unmeasured items are recorded as unmeasured, not disguised as passes | ✓ VERIFIED | See "Honesty of gaps" section below |

### Teardown verification (live, read-only, `root@172.16.1.159` / `root@172.16.1.158`)

| Claim in `03-DECISION.md` | Live check | Result |
|---|---|---|
| All three spike containers absent, no status filter | `docker ps -a --format '{{.Names}}' \| grep -i spike` | **no matches** |
| Container count 104 (baseline 103 +1 unattributed, non-spike) | `docker ps -a --format '{{.Names}}' \| wc -l` | **104** — matches |
| `/mnt/fast/spike-03/` removed | `ls /mnt/fast/spike-03` | **No such file or directory** |
| Only `/mnt/fast/secrets/discogs.env` remains, `600 root:root` | `ls -la /mnt/fast/secrets/`, `stat` | **discogs.env, jellyfin-deercrest.env, ma-deercrest.env** all present at `600 root:root`; no spike-created token copy anywhere under `/mnt/fast` |
| `/mnt/tank/downloads/spike-03` (45 G scratch tree) removed | `ls /mnt/tank/downloads/spike-03` | **No such file or directory** |
| Real backlog untouched: `find .../complete/nzb -type f \| wc -l` unchanged | live count | **8,934** — matches the decision record's before/after figure exactly |
| `tank/downloads@spike-03-t0` and `@spike-03-t2-wav` destroyed; `@pre-project`/`@pre-chown` kept | `zfs list -t snapshot` on atlantis | Both spike snapshots **absent**; `tank/downloads@pre-project`, `tank/downloads@pre-chown`, `tank/media/Music@pre-project` all **present** |
| Images: `beets:2.13.1-ls349` and `beets-flask:v2.0.0-rc6` retained; `wrtag:v0.33.0`/`v0.34.0` pruned; `wrtag:v0.20.0` left alone (predates phase) | `docker images \| grep -E "beets\|wrtag"` | Exactly `2.13.1-ls349`, `v2.0.0-rc6`, `v0.20.0` present; **v0.33.0 and v0.34.0 absent** — matches the per-image decision table exactly |
| `df -h /` ≈ 35 G free of 126 G (72% used) at close | `df -h /` | **35G avail, 72% used** — matches |
| `zfs diff tank/media/Music@pre-project` returns 2,674 lines, all `M`, and this is *not* asserted clean (DEF-03-19) | `zfs diff` on atlantis | **2,674 lines, all `M`** — matches the decision record's own non-clean figure exactly; the record correctly does not claim "clean" |

No mutating command was run. No token value or rotation action was touched.

### Honesty of gaps

| Claimed gap | Verified present as claimed | Evidence |
|---|---|---|
| 9 of 10 ergonomics rows `wall_clock_s`/`interventions` not measured | ✓ | `03-ERGONOMICS-SHEET.md` § "Amendment B" table: only `clean-1`/terminal carries numbers (30s, 1, 1); all four other terminal rows are `not run`; all five flask rows are `not measured`, and the record explicitly refuses to substitute the tool's own "Imported 39 seconds ago" string as a wall-clock figure |
| 4 of 5 terminal-arm rows "not run" | ✓ | Confirmed same table; operator decision (AMENDMENT B-3), recorded as such rather than backfilled |
| Criterion 8's verdict labelled scribe-assembled | ✓ | `03-DECISION.md` § Criterion 8 explicitly separates the operator's one contemporaneous verbatim from "the executor's contemporaneous notes, not the operator's voice" |
| DEF-03-17 resting on one product page | ✓ | `deferred-items.md` DEF-03-17: "Only **one** product page was checked; coverage across all 99 Mastermix folders is **unproven**" — stated as a caveat, not smoothed over |
| DEF-03-19 (`zfs diff` non-clean since 2026-08-18) with three plans asserting otherwise | ✓ | `deferred-items.md` DEF-03-19 and `03-DECISION.md` § Teardown 11 both state the assertion is unsatisfiable and record it as such rather than waving it through; independently reproduced live (2,674 lines, all `M`) |
| 144-vs-151 denominator ruling | ✓ | `deferred-items.md` DEF-03-18: three readings (151, 145, 144) reconciled exactly, with 144 ruled authoritative "not because it is most recent... but because it is the frozen basis of T1's estimator," and the backlog explicitly noted as a live, growing tree |

**One inaccuracy found in the record itself, immaterial to the decision.** § *"Recorded, not corrected: `grep -c PENDING` cannot return 0"* claims a narrower instrument (`grep -cE '\| *PENDING *(\|\|$)|verdict:\*\* PENDING|status: PENDING'`) returns 0 on the current document. Independently re-run, it returns **1**, not 0 — the one match is the code block that quotes the grep command itself (a self-referential false positive from the literal string `PENDING` inside the quoted command shown in prose), not an unresolved result cell. Manual inspection confirms no actual unfilled `PENDING` result cell remains. This is a stated-instrument-vs-actual-output mismatch inside the document's own self-audit, not a hidden unresolved threshold or verdict — recorded here because the task's skepticism requirement asks that a check's construction be scrutinised as closely as its claimed result.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| TAGR-01 | 03-01, 03-02, 03-03, 03-04, 03-05, 03-06, 03-07, 03-11 | Tagger decision recorded with numbers — Discogs coverage on normalised folders, import timing vs API ceiling | ✓ SATISFIED | T1/T2 resolved with full evidence chain (see truths 1-2, 5 above) |
| TAGR-02 | 03-01, 03-04, 03-05, 03-08, 03-09, 03-11 | Surviving tagger can own the whole tree, including content that will never match MusicBrainz | ✓ SATISFIED | Criterion 4 (truth 4); wrtag disqualified on measurement (criterion 3); D-13 bake-off settles the normalisation-tool question independent of the engine winner |
| TAGR-06 | 03-01, 03-02, 03-10, 03-11 | Operator ergonomics weighted and recorded, including evaluation of a reviewable-queue front end | ✓ SATISFIED | Axis two (truth 6), beets-flask by name (truth 7), operator's own-words verdict (truth 8) |

All three requirement IDs declared across the phase's plan frontmatter are present in
`.planning/REQUIREMENTS.md` (lines 122-131) and are traceable to specific evidence. No orphaned
requirements: `.planning/REQUIREMENTS.md`'s phase table maps exactly TAGR-01, TAGR-02, TAGR-06 to
Phase 3, and no other requirement ID names Phase 3.

**⚠ Tracking discrepancy (not a phase-goal gap):** `.planning/REQUIREMENTS.md` still lists TAGR-01,
TAGR-02 and TAGR-06 as `Pending` with unchecked `- [ ]` boxes (lines 122-131, 262-264), and no commit
in this phase's history touches `.planning/REQUIREMENTS.md` (`git log -- .planning/REQUIREMENTS.md`
shows nothing between phase-1/phase-2/02.1's closing commits and now). Every prior completed phase
(1, 2, 02.1) closed with a commit that flipped its requirement rows to a `COMPLETE (...)` narrative
in this same file. Phase 3 did not follow that convention. This does not affect whether the phase's
decision is correct or evidenced — it is a bookkeeping gap in the requirements-traceability record.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `.planning/STATE.md` | frontmatter + "Current Position" | Stale: `status: executing`, `completed_phases: 3`, "Phase: 03 (tagger-spike) — EXECUTING, Plan: 1 of 11", `last_activity: "Phase 03 execution started"` | ⚠️ Warning | `git log -1 -- .planning/STATE.md` shows the last commit touching this file is `41de755 docs(phase-03): begin phase 03 execution`. Two 03-11 commits (`dd427ba`, `c2badb3`) explicitly state in their own commit messages "STATE.md and ROADMAP.md are deliberately untouched" — deliberate at the plan level, but nothing in the phase closed it out afterward. `.planning/ROADMAP.md` *was* separately updated (commit `994f5b9 docs(phase-03): update tracking after wave 8`) and correctly shows Phase 3 `[x]` complete, so the two tracking files now disagree with each other. Recommend updating `STATE.md`'s Current Position and progress counters before Phase 4 execution begins, so the next phase does not start against a stale "Plan 1 of 11" pointer |
| `.planning/REQUIREMENTS.md` | 122-131, 262-264 | TAGR-01/02/06 still `Pending`/unchecked despite being satisfied | ⚠️ Warning | See Requirements Coverage section above |
| `CLAUDE.md`, `.planning/PROJECT.md` | § *What NOT to Use*, § *Version Compatibility*, § *Technology Stack* | Carry claims this phase measured false (v0.33.0 path-format claim; "7,451 files across ~1,000 folders"; the 45 GB `1-115` set framed as non-existent) | ℹ️ Info — explicitly deferred by design | `03-DECISION.md` § *"Four claims this phase falsified, corrected here rather than in the documents that carry them"* states plainly these were **not** corrected in the originals, citing D-03 (this phase does not edit shared/frozen documents) and explicitly assigns "Phase 4 owns editing the originals." This is a disclosed, intentional scope boundary, not a hidden gap — flagged here only so Phase 4's plan-writer does not miss picking it up |
| No `TBD`/`FIXME`/`XXX`/`HACK`/`PLACEHOLDER` debt markers found in any file this phase modified | — | — | — | Scanned all ~125 files touched across the phase's commit range. All `TBD` occurrences found are either provenance markers explicitly preserved by design (the ergonomics sheet's original `TBD` cells, kept verbatim as evidence of pre-trial state) or belong to later, not-yet-planned ROADMAP phases (4-9), which is the roadmap's normal convention |

### Human Verification Required

None. The items that would ordinarily need a human (the ergonomics trial, the T3 self-assessment,
the rotation-timing decision) were already exercised by the operator during phase execution and are
recorded verbatim in the decision record; this verification confirmed those records against git
history and the live estate rather than re-running them.

### Gaps Summary

No gap blocks the phase goal. The decision record is exceptionally rigorous: it independently
audits its own six unsound acceptance-criteria constructions from within the phase (DEF-03-05,
DEF-03-06, DEF-03-19, DEF-03-20, plus the axis-one config-dump-cannot-prove-plugin-load finding and
the D-13 field-loss-gate limitation), rather than letting any of them pass silently. The honesty
fence was independently re-derived via `git diff` against the pre-evidence commit and holds exactly.
The teardown was independently re-verified live over SSH (read-only) and matches the written record
number-for-number, including the one place the record admits an unsatisfiable assertion (`zfs diff`
non-clean).

Two process/bookkeeping items are worth closing before or alongside Phase 4 kickoff, listed above
under Anti-Patterns: `STATE.md`'s stale Current Position, and `REQUIREMENTS.md`'s unflipped
TAGR-01/02/06 rows. Neither affects the correctness or evidentiary basis of the tagger decision
itself.

---

_Verified: 2026-09-04T18:40:00Z_
_Verifier: Claude (gsd-verifier)_
