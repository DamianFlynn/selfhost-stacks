---
phase: 07-pilot-12-albums-end-to-end
plan: 11
subsystem: music-tagging / undo and re-run of the gate album through beets-flask
tags: [undo-import, state-pickle, incremental, re-run-equality, d-17, phase7]
requires: [07-09, 07-10]
provides: ["P10 LANDED (re-run) — EQUALITY VERDICT: PASS and QUALITY: PASS (P10; …) on the ledger — plan 07-12's precondition", "DEF-07-11-01 — UNDO IMPORT does not revert state.pickle; a complete undo is UNDO IMPORT plus a state.pickle file restore", "D-17 NOT FIRED — tank/media/Music@pre-06-41-conf04-reprobe held for 07-16"]
affects: [07-12, 07-16, 07-17]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-11-p10-undo-rerun.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/07-11-SUMMARY.md
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
    - .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md
decisions:
  - "Operator (out of band, after run 1's RECONCILE-FAIL): fix the Jellyfin Music saver and remove the 2 .nfo files (DEF-07-11-05 remediation)"
  - "Operator, Task 1 gate: undo (pressed UNDO IMPORT on session 788f3bba)"
  - "Operator, Task 2 gate: restore-then-rerun (state.pickle FILE copy from fast/appdata/arrs@pre-07-pilot; never a rollback of that dataset)"
  - "D-17 NOT FIRED by construction on the file-restore branch; the Phase 6 reprobe snapshot is held for 07-16's operator gate"
requirements-completed: [QUAL-04, IMPT-01]
metrics:
  completed: 2026-09-26
  runs: 2
  run2-duration: "20:20:14Z – 21:06Z (includes two operator gates and the re-import)"
---

# Phase 7 Plan 11: P10 undone, state gap found and restored, re-run byte-equal — Summary

**Beets-flask's UNDO IMPORT reverted P10's files and database rows but left its `state.pickle`
entry in place. After a file restore of `state.pickle`, the re-import matched run 1 exactly:
same paths, same audio, same tags, same diff and byte-identical incremental state.**

## Operator-facing lesson (for 07-17 / `beets.md`)

**UNDO IMPORT in beets-flask does NOT revert `state.pickle`.** It deletes the album's files and
its `library.db` rows. It leaves the `taghistory` entry that beets' `incremental` mode uses to
skip folders it has already seen. A complete undo takes two steps:

1. Press UNDO IMPORT.
2. Stop beets-flask. File-copy `state.pickle` back from the `fast/appdata/arrs` snapshot's
   `.zfs/snapshot/`. Never roll back that dataset. Then start beets-flask again.

Without step 2, a fresh read of the same folder is expected to be skipped silently. This is
filed as `DEF-07-11-01`. `beets.md` is not in this plan's files, so plan 07-17 writes it there.

## Runs

| Run | What | Outcome |
|-----|------|---------|
| 1 | Resume reconciliation | The P10 tree held 51 files vs 50: Jellyfin wrote 2 `.nfo` (owner 100000) because Music `MetadataSavers=["Nfo"]` → `STOP STATE 07-11-RECONCILE-FAIL`, DEF-07-11-05 |
| — | Operator remediation | Music `MetadataSavers` → `[]` (one POST, only that key changed); the 2 sidecars deleted after forensic copies |
| 2 | Tasks 1–3 | CONSISTENT → undo → TREE yes / DB yes / STATE no → restore-then-rerun → re-import → EQUALITY PASS, QUALITY PASS, D-17 NOT FIRED |

## Run 2 readings

| Check | Reading |
|-------|---------|
| Undo witness | `TREE COVERED yes (pre 50 → post 0)` (the tree listing is cmp-identical to `@pre-07-pilot`); `DB COVERED yes (pre 50 → post 0)`; `STATE COVERED no (pre 1 → post 1)`, with `state.pickle` byte-unchanged by the undo |
| Restore | writer stopped (Running=false); one literal `cp` from `arrs@pre-07-pilot`; sha256 `f6a9a1ad…` = fence copy; owner and mode kept (same inode); restart gated on readiness (new two-inbox watchdog line); re-decode shows the entry ABSENT |
| Re-import | through the existing session 788f3bba (DELETION_COMPLETED → PREVIEW_COMPLETED → IMPORT_COMPLETED 20:58:05Z); candidate 073c7ff8 = b057dee8…, rank 1; a new taghistory entry was written |
| Criterion 3 | 0 mismatches out of 350 (control re-driven); 50/50 files `568:568`; 0 EPERM-class lines |
| Criterion 4 | diff exit 0; MATCHED 50; dropped 0; MISSING_AFTER 0; gained 2008 / changed 190 (= run 1) |
| Criterion 7 | `check-music-import.sh` (fixed, 245dfa7) exit 0, findings 0 |
| Criterion 8 | source manifest identical (52 rows); staged copy equals the manifest |
| Jellyfin | one targeted `Created` POST, same body as run 1 → 204; one album (same Id), 50 tracks, discs {1,2}; `MetadataSavers []`; **no sidecar** and 0 new entries in the library |
| Equality | (a) paths, (b) `audio_md5` set, (c) diff JSON with `source_path` removed, (d) `mb_albumid`: all identical. The raw diff JSON and `state.pickle` (`224fe279…`) are also byte-identical to run 1 |
| Barrier | VERIFIED at 20:20:50Z, 20:28:25Z, 20:40:23Z, 20:59:48Z and 21:04:58Z; MA 70/1244/66, so MA never saw P10 |

## D-17

`D-17 TRIGGER: NOT FIRED`. Condition (ii) fails because the undo did not cover state, and
condition (iii) fails because the Task 2 answer was `restore-then-rerun`. Conditions (i) and (iv)
hold. `tank/media/Music@pre-06-41-conf04-reprobe` is held for plan 07-16's operator gate. No
zfs write verb was issued in any run. The Phase 6 `DEF-06-52-01` status line is appended, and
`DEF-06-45-01` is still OPEN.

## Deviations from Plan

- **Out-of-band remediation between runs (operator-approved, DEF-07-11-05).** This changed
  Jellyfin configuration and deleted 2 files. It is not part of UNDO IMPORT, and the artifact
  records it in its own section. Its effect was re-checked on the re-run's Jellyfin step: no
  sidecar appeared.
- **Ledger success token added.** After the plan's three lines (landed/verdict, QUALITY, D-17),
  the ledger gets `STATE 07-11-RERUN-LANDED`. Otherwise its newest 07-11 token would still read
  `RECONCILE-FAIL`. 07-12's precondition is unaffected: the line contains neither `P10 LANDED
  (re-run` nor `STOP STATE 07-11-`, and the precondition check was re-run to confirm this.
- **The "rerun without restore" arm was never exercised.** It is recorded as not measured.
  Whether a same-session re-import goes through with the taghistory entry still present is
  known only from reading the source.

## Known Stubs

None.

## Self-Check: PASSED

- The artifact, ledger and both `deferred-items.md` files hold the new lines, and commit
  `4b1782a` exists.
- The Task 1, 2 and 3 automated verifies all exit 0, which was checked right after `4b1782a`.
  `REQUIREMENTS.md` is untouched. The preview of 07-12's precondition line matches.
