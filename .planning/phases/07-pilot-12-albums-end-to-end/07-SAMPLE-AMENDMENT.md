# 07-SAMPLE amendment A1 — 2026-09-26

This file amends `07-SAMPLE.md` (last changed in `d64f638`). `07-SAMPLE.md`, `07-EXPECTED-TREE.txt`
and `07-EVIDENCE-MAP.md` are NOT edited by this amendment. Where this file conflicts with
`07-SAMPLE.md`, this file wins. Consumers read each machine line from this file first, and from
`07-SAMPLE.md` only when this file has no such line.

## Machine lines

GATE ALBUM 07-10: P10
EXECUTION SET 07-10: P10
EXECUTION SET 07-12: P02 P03 P04 P05 P06 P09 P11 P12
EXECUTION SET 07-13: P07 P08
EXCEPTION CANDIDATE 07-12: P01
P01 DISPOSITION: PENDING — asked at 07-10 Task 2 (hold | exclude | exception-gate); until answered P01 is not staged and is not counted as landed

The DJ-twin line is not restated here. `DJ TWINS AMONG FRESH DRAWS: P11` is still read from
`07-SAMPLE.md`, and 07-12 still moves P11 to 07-13 by its existing mechanism.

## Why

Plan 07-10 took P01 (`The Essential Michael Jackson`) to the import gate in run 5. The operator's
answers, verbatim:

- "swap gate album" — 07-10 run 5, Task 2, relayed ~2026-09-26T16:3xZ.
- "ok now 117" — 2026-09-26, choosing P10 as the replacement gate album.

P01 is incomplete at source. Disc 1 holds tracks 7–21 only (15 files) and disc 2 holds tracks 1–17.
Every MusicBrainz candidate is 21 + 17, so D-29 step 2 (per-disc track count) refused all five.
The best candidate was rank 1, `f890ca09-0b44-4539-ae13-238266b242fa` (US CD, Epic E2K 94287),
distance 0.1207, recommendation `medium` (derived). Ranks 4–5 map `Earth Song` and `Got to Be
There` onto the wrong files, which would have been a confident wrong match. The gate worked and was
not vacuous. It cannot pass P01, and D-10 needs a gated album that can.

## The new order

1. P10 — plan 07-10, then its undo and re-run in 07-11.
2. P02, P03, P04, P05, P06, P09, P12 — plan 07-12. P11 moves to 07-13 as before (DJ twin).
3. P01 — at the END of 07-12, and only if its newest `P01 DISPOSITION:` line is `exception-gate`.
4. P07, P08, P11 — plan 07-13.

The P02-before-P04 constraint is unchanged.

## P01's three dispositions and what each does to criterion accounting

- `hold` (default): not staged and not imported. Every later count reports P01 as "held,
  disposition undecided".
- `exclude`: a recorded exclusion from the twelve. At most eleven albums can land, and
  `/gsd-verify 07` scores criterion 1 against that. Nothing is re-labelled to hide it.
- `exception-gate`: re-staged at the end of 07-12 and presented at a separate D-29 EXCEPTION gate,
  default hold there. If imported, it lands labelled `P01 LANDED (D-29 EXCEPTION <mbid>)`. Its
  per-disc count mismatch and its criterion-7 `tracktotal` finding are carried as unresolved
  findings, never as a pass.

P01 never counts as landed unless a later `P01 LANDED (D-29 EXCEPTION …)` ledger line exists.

## P10's facts

- Folder: `/mnt/tank/downloads/complete/nzb/unsorted/VA.Now.That.s.What.I.Call.Music_.117.2024..CD.FLAC..CDNOW117`
  (`unsorted/`, so D-13 applies).
- 07-07 source manifest: 52 rows, which are 50 FLAC, one `.cue` and one `.log`.
- Tags: `disctotal = 2`, `disc` {1,2}, albumartist `Various` on 50/50, comp false. The 50 FLAC
  render `01-01 … 01-24` and `02-01 … 02-26` in the oracle.
- Oracle: the 50 APPENDED lines of `07-EXPECTED-TREE.txt` under
  `/media/Music/Various/NOW That's What I Call Music! 117/` (rule 4 `disctotal:2..`; as-is keeps
  `Various`, not `Various Artists/`).
- Criterion 2's multi-disc shape is still covered. P10 was named and drawn in `07-SAMPLE.md` (F2)
  before the first import artifact existed, so moving it to the gate slot is not a redraw.
- It is the only drawn bucket-A album that is multi-disc by tag and gap-free. P12 (Now 116) has no
  disc tags and P05 (Now 121) is two discs tagged as one. Its MusicBrainz per-disc count is not
  known in advance; the 07-10 preview is that check.

## Carried findings

- A dangling beets-flask preview row for P01: folder `d2772a06…`, session `8ad1c311…`
  `PREVIEW_COMPLETED`, `chosen_candidate_id` None. It is not edited. A re-stage of P01 may collide
  with it, so 07-12 reads it before any P01 staging.
- The MA barrier: `music_sync_filesystem_local--XJaJWNUS_{artist,album,playlist,track}` were
  disabled 2026-09-26T15:55:04Z. They are re-verified read-only before every import in 07-10 …
  07-14, and the re-enable (`tasks/set_enabled enabled:true`, same four ids) is owed at plan 07-15,
  after its MA proof.
