---
phase: 07-pilot-12-albums-end-to-end
plan: 01
subsystem: planning-records
tags: [evidence-map, d-31, d-13, roadmap-amendment, pre-registration]
requires: []
provides:
  - "07-EVIDENCE-MAP.md — one artifact + one instrument per Phase 7 success criterion, registered before any import"
  - "ROADMAP DUPE-01/02 row amended in band to BULK import, pilot excepted, conditional on D-11"
affects: [07-02, 07-06, 07-07, 07-09, 07-10, 07-11, 07-15, 07-17]
tech-stack:
  added: []
  patterns: ["pre-registered verification target at the phase root (INPUT, not artifact)", "in-band argued amendment with original text kept visible"]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/07-EVIDENCE-MAP.md
  modified:
    - .planning/ROADMAP.md
decisions:
  - "Criterion 1's 'rollback exercised' is offered as discharged by D-15's UNDO IMPORT back-out; no ZFS roll-back of tank/media/Music is planned; /gsd-verify 07 accepts or rejects that mapping"
  - "Criterion 4's BEFORE of record is pre-07-pilot; Phase 1's pre-project capture is the cross-check"
  - "The DUPE unsorted rule now reads 'any BULK import'; the pilot draw is the only exception and holds only while the D-11 AMBIGUOUS arm is committed"
metrics:
  duration: "~10 min"
  completed: 2026-09-25
  tasks: 2
  files: 2
---

# Phase 7 Plan 01: Evidence Map and D-13 Amendment Summary

A pre-registered map naming, for each of the eight Phase 7 criteria, one artifact path, one exact
instrument and what reads as SATISFIED-FOR-SCORING versus UNKNOWN. It is committed before any fence
or import exists. Alongside it, the ROADMAP rule that DUPE reconciliation must come before "any import
of `unsorted`" is narrowed to *bulk* import, with the argument written into the rule itself.

## What was done

- **Task 1 — `07-EVIDENCE-MAP.md`** (commit `823fe04`, only that file in the commit). It has six
  headed sections: header and column contract, the eight criteria, E1…E12 ownership, the C1…C11
  coupling index, the closure protocol and out of scope. It was authored against base
  `60039c7589fb0e188d380848b40697ea50da20b2`. The table has exactly 8 data rows, all with 7 columns,
  and the `measured` column is empty in every row (checked by awk). Row 1 carries the PAIRED
  `PRE-UNDO WITNESS` → `UNDO WITNESS` reading with `P01 STATE KEY(S)` and `VACUOUS`-never-satisfies,
  plus the registered UNDO-IMPORT-for-rollback mapping. Row 4 names `pre-07-pilot` as the BEFORE of
  record and gives the reasons.
- **Task 2 — ROADMAP DUPE row** (commit `dd90e78`). The original sentence stays verbatim. The
  amendment is headed `**Amended 2026-09-25 (Phase 7, D-13):**` and has three parts. First, the new
  BULK scope. Second, a four-clause argument: the risk model; copy plus fence plus undo; D-11 as the
  control; and a conditionality clause. Third, what the amendment does not change: Phase 9, and the
  D-03 move, which is left to `/gsd-phase`. The row is still one table line with 4 pipes. The diff
  body was read and is exactly −1/+1 lines, excluding headers.

## Verification drives

- CONVENTIONS §8.3 control: `/usr/bin/grep -cE 'zfs [r]ollback|zfs [d]estroy|Full[R]efresh'` over a
  one-line control file containing `zfs rollback` returned **1**. The same grep over the map
  returned **0**.
- Task 1 automated verify: `VERIFY-PASS`. `git diff --exit-code HEAD -- .planning/REQUIREMENTS.md`
  exited 0, so no box moved and CONF-04 stays unticked.
- Task 2 automated verify: `VERIFY-PASS`. The anchored `---`/`+++` filter (G-14) counts 1 removed
  line and 1 added line.
- No `roadmap.*`, `state.*` or `commit` SDK verb was used. STATE.md and ROADMAP.md were edited by
  hand, and commits were made with plain `git commit`.

## Deviations from Plan

None - plan executed exactly as written. The only choice made outside the plan's own text was
wording: the map writes the roll-back tokens in bracketed form throughout, and never says "ZFS
rollback" unbracketed.

## Known Stubs

The `measured` column of the eight-criteria table is empty **by design**. Plan 07-17 fills it, and
the map's header states that.

## Self-Check: PASSED

- FOUND: .planning/phases/07-pilot-12-albums-end-to-end/07-EVIDENCE-MAP.md
- FOUND: commit 823fe04
- FOUND: commit dd90e78
