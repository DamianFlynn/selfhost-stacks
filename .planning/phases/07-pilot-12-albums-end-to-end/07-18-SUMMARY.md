---
phase: 07-pilot-12-albums-end-to-end
plan: 18
subsystem: music-tagging / beets back-out of the American Heart twin (P04), beets half of 07-UAT gap 3
tags: [uat-gap-3, od-1, undo-import, state-pickle, partial-surgery, unstage, round-fence, phase7]
requires: [07-12, 07-15, 07-17]
provides: ["STATE 07-18-BACKED-OUT: 8 albums / 187 items landed (P10 P02 P03 P05 P06 P12 P07 P08); P04 backed out of tree, DB and incremental state", "round fence tank/media/Music@pre-07-18 + fast/appdata/arrs@pre-07-18 (held)", "second use of the partial state.pickle surgery (DEF-07-12-06), one key"]
affects: [07-20, 07-21, 07-22]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-18-p04-backout.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/07-18-SUMMARY.md
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/SNAPSHOT-REGISTER.md
decisions:
  - "Operator OD-1 (2026-09-28): \"Back out the MP3 (P04)\" and keep the P02 FLAC"
  - "Operator gate (2026-09-28, ~09:3xZ): \"undo-unstage (Recommended)\". UNDO IMPORT was pressed on P04, and the staged copy is removed. The nzb/music source stays."
  - "State step is the partial surgery that removes only P04's key. The fence file copy is wrong here, because P02..P08 landed after @pre-07-pilot."
requirements-completed: [QUAL-04, IMPT-01]
metrics:
  completed: 2026-09-28
  duration: "09:21Z – 09:36Z (includes the operator gate)"
  tasks: 3
---

# Phase 7 Plan 18: P04 backed out, P02 kept — Summary

**P04 (the Benson Boone *American Heart* MP3 twin, beets album 9, c33163f3…) has been removed from the
tree, from library.db and from beets' incremental state. P02's FLAC (album 2, c0df8104…) is byte-for-byte
unchanged. The library now holds 8 albums and 187 items. P04's staged copy is gone, and its `nzb/music`
source is untouched.**

## What was done

- **Task 1** (3300cbd, gate pre-read 20d2188) recorded the pre-state. That was 9 albums / 197 items, P04's state key
  PRESENT, P02's per-file manifest `171e1202…`, and the P04 source equal to its 07-07 rows. It then took the
  round fence `@pre-07-18` on both datasets in one step, with safety copies that were sha-equal, and registered it.
- **Task 2 gate:** the operator pressed UNDO IMPORT and answered `undo-unstage (Recommended)`. This is recorded
  verbatim with `DISPOSITION: undo-unstage` (d796a5c).
- **Verified before any write (§ D):** the `run_import_undo` job carried P04's folder hash `8c4fb033…`, not
  P02's `5fb195c7…` (09:29:41Z–09:29:42Z). Album 9 and its 10 items were absent, leaving 8 albums / 187 items.
  The P02 DB digests (row, items, both flexattr tables) and the per-file manifest (size, sha256, mtime, ctime)
  were all equal. The P04 state key was still PRESENT, which reproduces DEF-07-11-01.
- **Partial state surgery (§ E):** the build asserted the key set, `tagprogress == {}`, live == Task 1's list,
  and P04 ∈ live. It then wrote protocol 4 and decoded the result back as new == live − {P04} (9 → 8). beets-flask
  was stopped for the change. On atlantis the executor asserted the live sha, took a backup with `cp -p`, and
  copied the new file over the live one, so owner 568:568, mode 770 and inode 33942 were preserved. beets-flask
  was then started and was ready at the first poll, with a new two-inbox watchdog line. Every folder logged
  "skipping enqueue", and no job ran.
  `state.pickle d1958008… → b8ce8afd…`. Backup: `/mnt/fast/safety/phase07/0718/state.pickle.pre-0718-surgery`.
  `check-beets-config.sh` exit 0 (copy=true move=false write=true).
- **Unstage (§ F):** the two-layer fence refused all five driven negatives and accepted the P04 name. The staged
  copy's (relpath, sha256) set equalled the 07-07 manifest. `rm -rf` removed only
  `_inbox/02-review/Benson_Boone_-_American_Heart-WEB-2025-BENSONBOONE`. The source is UNCHANGED (10 rows). The
  11 `sorted_walk` tracebacks in the log are the expected noise.
- **Close (§ G):** `CRITERION 8 (P04): UNCHANGED (10 rows)`. `check-music-import.sh` exit 0 (187 items, 0
  findings). `.nfo` 91, not-568 0. The fence was re-listed and is still held.

## Deviations from Plan

None that change the outcome. There are two small method notes:
- The `stat %.9y` mtime field in `state-replace-0718.sh` was truncated in its output. The mtime was re-read inside the
  container instead (09:32:56.57Z). The sha, owner, mode, size and inode assertions were unaffected.
- `deferred-items.md` was not modified, because there was no new finding. The dangling beets-flask folder/session
  row for P04 has the same known shape as P09 after 07-12 R1.

## Known Stubs

None.

## Threat Flags

None. No new surface: no Jellyfin or Music Assistant verb was issued, and no zfs verb was used apart from the Task 1
snapshots and re-lists.

## What is left

- Jellyfin still shows P04 (`e44d9655…`) → plan 07-21. Music Assistant album 169 still maps P04 → plan 07-22.
- The fence `@pre-07-18` is held until the operator releases it (with `@pre-07-pilot` at Phase 9 batch 1's fence).

## Self-Check: PASSED

- Commits 3300cbd, 20d2188, d796a5c and eb74f36 are present in `git log`.
- The artifact and ledger lines are present, and the plan's Task 2 and Task 3 `<automated>` verify both exit 0.
