---
phase: 07-pilot-12-albums-end-to-end
plan: 03
subsystem: music-pipeline / post-import detection
tags: [d-25, impt-02, criterion-7, g-03, def-06-45-04, health-check, vacuity-guard]
requires:
  - 07-02 (the diff-music-tags.sh fail-closed pattern and the CONVENTIONS §5 pin list)
  - beets-flask container with /venv/bin/python; /config/library.db (read-only)
provides:
  - scripts/check-music-import.sh — standing criterion-7 sweep, fail-closed, 10-case --self-test (Phase 9 criterion 2 inherits it)
  - quick-health-check.sh "Music import sweep" fatal block (tenth), knob IMPORT_SWEEP_SCRIPT, 14th exit-code notice (conditions Q/R/S)
  - artifacts/07-03-sweep-drive.txt — EXIT_CODE=1 enumeration before/after, controls, host self-test, first live reading, block drive
affects: [07-09, 07-10, 07-12, 07-13, 07-17, phase-09]
tech-stack:
  added: []
  patterns:
    - "remote dumper (python sqlite mode=ro via docker exec, program as argv) + pure local judge (jq) so --self-test drives the identical judge"
    - "dump carries a counted trailer record; missing or inconsistent trailer = UNKNOWN, so a truncated dump cannot read as a smaller clean library"
    - "per-class vacuity guard: any class with 0 checkable rows is exit 3"
key-files:
  created:
    - scripts/check-music-import.sh
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-03-sweep-drive.txt
  modified:
    - scripts/quick-health-check.sh
    - CONVENTIONS.md
decisions:
  - "Class 1's suffix predicate is applied by the judge (jq, same regex as assert_no_collision_suffix, same COLLISION-SUFFIX tag); the dumper only decides which names get a sibling stat. A suffix-shaped name with no boolean sibling result is UNKNOWN."
  - "The dump ends with one trailer record carrying its own item/orphan counts; an empty library is 'trailer with items 0' (UNKNOWN by vacuity), a dump with no trailer is UNKNOWN as could-not-look. Both exit 3, with different reasons."
  - "A directory holding an item that cannot be scandir'd is UNKNOWN (class 1 incomplete), not skipped."
  - "Until the host checkout is updated, the routine health check's new block reports BROKEN (bash exit 127, script not at the deployed path); after a git pull it reports UNKNOWN (0 items) until the first pilot import."
metrics:
  duration: "~60 min"
  completed: 2026-09-26
  tasks: 3
  files: 4
---

# Phase 7 Plan 03: The Criterion-7 Import Sweep Summary

`scripts/check-music-import.sh` now exists as a standing sweep. It looks for the three criterion-7 damage classes: `.N`-suffix collisions (in DB rows and in on-disk files), empty `mb_albumid` on non-DJ album items, and track count versus `tracktotal` per album-disc. It reads `library.db` read-only through Python sqlite inside beets-flask and never invokes `beet`. It fails closed on an empty library and on any class with nothing to check. Every class was driven red by `--self-test` before its zeros were trusted. It is folded into `quick-health-check.sh` as a tenth fatal block. On the real, empty library it exits 3, as designed.

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | `e8d24c2` | `check-music-import.sh`: dumper, judge, summary, exit ladder and a 10-case `--self-test` with an uncounted dumper-level check. CONVENTIONS §5 lists the new `ST_PLANNED_CASES` pin. |
| 2 | `317c1a4` | qhc fold-in block, `IMPORT_SWEEP_SCRIPT` knob, 14th notice, failure tail. The artifact's §1 records the EXIT_CODE=1 enumeration. CONVENTIONS §4 lists the knob. |
| 3 | `54be778` | Artifact §2–§4: local controls, the LXC 100 self-test, the live reading, and the block driven in isolation. |

## Results

- **`--self-test`:** 10 of 10 cases passed on the workstation and on LXC 100 (ssh RC=0), with 7 red by design. The dumper-level check passed on both (python3 3.13.5 on the host).
  - The all-singletons case exits 3 and names classes 2 and 3.
  - The orphan `Title.1.flac` exits 1 and is listed under `on-disk, no item row:`.
  - The Op.64 near-miss exits 0 and is listed under `suffix-shaped, no sibling:`.
- **The self-test can fail:** three mutated copies were each caught — no sibling test, class-3 first-wins, and class-2 vacuity removed.
- **Live run on LXC 100:** exit 3, `items read: 0`, and `checkable rows per class: class1=0 class2=0 class3=0`. That is the vacuity guard firing on real data, so the zeros mean "could not look", not "clean".
- **Nothing was written:** `library.db` read `fbbdde0c…` before and after the live run (the same value as 06-SAMPLE). `state.pickle` read `f6a9a1ad…` before and after. No fixture or `/tmp` dump directory was left behind.
- **Acceptance greps**, each driven against a control first:
  - A comment-stripped `beet ` count of 0 (the control returned 1).
  - An INSERT/UPDATE/DELETE/DROP count of 0 (the control returned 1).
  - `mode=ro` appears 3 times.
- **Exit ladder at `317c1a4`:** the UNKNOWN gate is at line 379, the FINDINGS gate at 383 and the green line at 391.
- **Notice header count:** 13 before and **14 after**, measured after writing. The recipe returned 1 on a control line first. The condition letters are Q, R and S, because P was the last in use.
- **`EXIT_CODE=1` enumeration:** 98 sites before and 104 after. All 6 new sites belong to the music import sweep, and every other block's count is unchanged. The BEFORE vector reproduces 06-26 §3.1 exactly.
- **D-04 scan:** simulated with the block's own regex, the count vector (stripped 101 / invocation 10 / executable 8 / documentation 2) is unchanged. The new script adds 2 raw hits, both in comments, so it needs no exemption.
- **Fold-in block driven in isolation across five arms:** default path (not deployed, exit 127, ❌), the real copy through the override (exit 3, ⚠️ plus the override notice), a stub exiting 0 with the anchor (override, never ✅), a stub exiting 0 without the anchor (UNKNOWN), and a stub exiting 1 (❌). All five set `EXIT_CODE=1`.

## Deviations from Plan

### Auto-fixed / added

1. **[Rule 2 - fail-closed] The dump has a trailer record.** It was not in the plan's text. Without it, a dump killed partway through looks like a smaller clean library. A missing trailer, or one whose counts disagree with the body, is UNKNOWN. The plan said an empty dump with RC 0 is "a genuine empty library". Here an empty library is the trailer alone, and a truly empty dump is could-not-look. Both are exit 3, so the observable outcome is unchanged.
2. **[Rule 2] An unreadable directory holding an item is UNKNOWN.** The class-1 enumeration is incomplete in that case, so it is not skipped silently.
3. **[Rule 2 - doc sync] CONVENTIONS §4's `_Q` knob list gained `IMPORT_SWEEP_SCRIPT`** in the Task 2 commit. The plan only asked for the §5 pin, but an index that omits a knob it enumerates would be stale on arrival.
4. **The dumper-level self-test builds its fixture sqlite file with `CREATE TABLE … AS SELECT`.** This avoids row-writing SQL, so the file honestly carries zero INSERT/UPDATE/DELETE/DROP tokens. `CREATE` appears only in that temp-file builder, and the real DB is only ever opened `mode=ro`. This is stated so the grep result is not read as more than it is.

### TDD gate compliance

Task 1 was `tdd="true"`, but the plan's action names a single `feat` commit. The test and the implementation therefore shipped together in `e8d24c2`, and there is no separate `test(...)` RED commit. Instead, RED capability was proven by mutation: three mutated judges each turned the self-test red (artifact §2).

## Known Stubs

None.

## Operator notes

- **The routine health check now reads ❌ on the import sweep until the host is updated.** The host checkout `/mnt/fast/stacks` does not have the script yet, and nothing was pulled or pushed. After a `git pull` the block reads ⚠️ UNKNOWN until the first pilot import. Both are non-green by design. Memory notes that the host has uncommitted production edits blocking `git pull`, so check `git status` there first.
- The script's live copy used for this drive is at `/mnt/fast/safety/phase07/sweep-drive/check-music-import.sh` (sha256 `70da42b3…`, equal to `317c1a4`'s file).
- `infra/lxc-selfhost.tf` appeared modified in the working tree during this plan. This plan did not touch it or stage it.

## Self-Check: PASSED

- FOUND: scripts/check-music-import.sh, artifacts/07-03-sweep-drive.txt, quick-health-check.sh block, CONVENTIONS.md §4/§5 entries
- FOUND commits: e8d24c2, 317c1a4, 54be778; 823fe04 is still an ancestor of HEAD
