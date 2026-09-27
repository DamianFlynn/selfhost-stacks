---
phase: 07-pilot-12-albums-end-to-end
plan: 16
subsystem: zfs-snapshot-governance
tags: [zfs, snapshots, D-19, D-17, register, gap-closure]
requires: ["07-15", "07-11 D-17 outcome", "07-09 pre-07-pilot fence"]
provides: [".planning/SNAPSHOT-REGISTER.md — project-level snapshot register with mechanical eligibility"]
affects: ["Phase 9 batch fences (must add rows)", "DEF-06-45-01", "DEF-06-52-01", "DEF-06-52-02"]
tech-stack:
  added: []
  patterns: ["written@<older> = 0 as the mechanical 'same undo point' test", "one autonomous:false prune gate, hold first", "ISSUED:-only unbracketed verb (P-06)"]
key-files:
  created: [.planning/SNAPSHOT-REGISTER.md, .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-16-prune-decision.txt]
  modified: []
decisions:
  - "Operator answered `hold` at the D-19 gate (2026-09-27T18:58:12Z): no snapshot was released"
  - "Register lives at .planning/ (project level), not in a phase directory: snapshots outlive phases"
  - "Clause (c) accepts only a project-row cover; backup-series snapshots can satisfy written@=0 but are never named as covers"
requirements: [QUAL-04]
metrics:
  completed: 2026-09-27
  tasks: 2
  files: 2
---

# Phase 7 Plan 16: Snapshot Register and One-Gate Prune Summary

Every project snapshot on `tank` and `fast` now has an owner, what it undoes, and a release condition, all recorded in `.planning/SNAPSHOT-REGISTER.md`. Prune eligibility is mechanical: there must be a strictly newer project snapshot on the same dataset whose `written@<older>` is 0. Exactly one snapshot qualified, `tank/media/Music@pre-phase5-chown` (0 B used). At the single gate the operator answered **`hold`**, so nothing was released: `PRUNE OUTCOME: NONE (hold)`.

## Tasks

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Measure, write the register, compute eligibility, ask once | 6ca0729 | SNAPSHOT-REGISTER.md, artifacts/07-16-prune-decision.txt |
| 2 | Execute the answer (`hold` arm) and update the register | 7b1fbde | same two files |

## What was measured

- The full `zfs list -t snapshot -r tank fast` listing (181 names, 14:07:16Z) and `written@` for every ordered same-dataset pair (14:08:59Z), all RC 0. Tank had 5.42 TiB free (re-measured) and fast 1.30 TiB.
- ELIGIBLE: `tank/media/Music@pre-phase5-chown`. It is covered by `@pre-06-41-conf04-reprobe` with `written@` = 0. The change it covered was nothing, because 05-10's chown wrote 0 bytes to the library.
- `tank/media/Music@pre-06-41-conf04-reprobe` is **held by D-17 NOT FIRED** (07-11's reason is quoted in the register). It is NOT ELIGIBLE because every newer snapshot has `written@` of at least 109,120 B. DEF-06-45-01 and DEF-06-52-01 stay open.
- `tank/downloads@pre-phase5` is NOT ELIGIBLE by rule (E4/D-17) and was never offered. Neither `@pre-07-pilot` was offered. Each has a MECHANICAL release condition: Phase 9 batch 1's fence, when it has `written@pre-07-pilot` = 0 and a register row that names it as the cover.
- Where no release condition was recorded, the register says `none recorded — could not look further` and gives the exact grep that was run (DEF-06-52-02).

## Task 2 (hold arm)

- Answer recorded verbatim with its UTC time. No `zfs` write verb was issued. SET APPROVED, DESTROYED, REFUSED and FAILED are all `none`.
- A read-only re-list at 18:58:12Z returned 181 names against 181 before. Both set differences are `none`. `@pre-phase5`, both `@pre-07-pilot` and the reprobe are each present by whole-line match.
- The register row for `@pre-phase5-chown` now reads `held (operator, 2026-09-27T18:58:12Z)`, and the register header records the gate outcome.
- The three verb recipes (issued, stray unbracketed destroy, rollback) were run against scratch controls in both directions: each read 1 on the control meant to trip it and 0 on the one that should not.

## Deviations from Plan

None. The plan was executed as written on the `hold` arm.

## Known Stubs

None.

## Next

The plan's gap is closed as far as the register goes. Closing DEF-06-52-01 (the reprobe) still needs a future operator action. Verification runs once, at the end of the phase's rounds.

## Self-Check: PASSED

- FOUND: .planning/SNAPSHOT-REGISTER.md
- FOUND: .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-16-prune-decision.txt
- FOUND: commit 6ca0729, commit 7b1fbde
- Task 1 and Task 2 `<automated>` verify blocks: both pass
