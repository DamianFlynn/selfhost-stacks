---
phase: 07-pilot-12-albums-end-to-end
plan: 10
subsystem: music-tagging / first import through beets-flask 02-review
tags: [gate-album, p10, d-29, d-07-oracle, jellyfin-targeted-update, ma-barrier, phase7]
requires: [07-07, 07-09]
provides: ["STATE 07-10-LANDED — P10 in the library, the state plan 07-11 undoes and re-runs", "07-SAMPLE-AMENDMENT.md A1 (gate slot P10; P01 DISPOSITION exception-gate)", "the BARRIER READ procedure (/root/ma-read-0710.sh) used by 07-11 … 07-15"]
affects: [07-11, 07-12, 07-13, 07-15]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/07-SAMPLE-AMENDMENT.md
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
    - .planning/phases/07-pilot-12-albums-end-to-end/07-10-SUMMARY.md
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-10-p01-import.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
decisions:
  - "Operator: gate slot P01 -> P10 (\"swap gate album\", then \"ok now 117\") — amendment A1, committed alone (d59fd27)"
  - "Operator: P10 imported with the named rank-1 candidate b057dee8-02ea-4b48-8681-f5e3255bc47d through the beets-flask UI (D-20)"
  - "Operator: P01 DISPOSITION exception-gate — re-staged at the END of 07-12 and asked again at a D-29 EXCEPTION gate (default hold)"
  - "A relayed 'imported' answer is not evidence: live library.db items plus the beets-flask session/task state must agree before it is recorded"
requirements-completed: [IMPT-01, CONS-04, QUAL-02, QUAL-03]
metrics:
  completed: 2026-09-26
  runs: 6
  run6-duration: "18:42:53Z – 19:55Z (includes the operator gate wait)"
---

# Phase 7 Plan 10: P10 (Now 117) imported through 02-review and verified — Summary

The library now holds one beets-imported album. P10 (`Now That's What I Call Music! 117`) was
matched to MusicBrainz release `b057dee8…` (rank 1 of 5, recommendation strong, 24+26 == 24+26),
confirmed by the operator in beets-flask's `02-review`, and landed as 50 FLAC under
`/media/Music/Various Artists/Now That’s What I Call Music! 117/`. It has been read by every
per-album instrument: criteria 3, 4, 8 and the Jellyfin half of 6 pass. Criterion 7 is UNKNOWN
because the instrument is blind on beets' relative item paths. Music Assistant has provably not
seen it. This is the state plan 07-11 undoes.

## Runs

| Run | What | Outcome |
|-----|------|---------|
| 1–5 | P01 (`The Essential Michael Jackson`) — see `07-10-PARTIAL.md` | MA sync FOUND, barrier applied, P01 staged; D-29 refused all 5 candidates (disc 1 holds tracks 7–21 only) → `STOP STATE 07-10-HOLD`, gate-slot swap |
| 6 | P10 behind amendment A1 | staged by reflink, D-29 rank 1 passes, operator imported, verified → `STATE 07-10-LANDED` |

## Run 6 readings

| Check | Reading |
|-------|---------|
| Amendment A1 | committed alone, `d59fd27`; 5 machine lines verbatim; `P01 DISPOSITION: exception-gate` appended |
| Preconditions | 07-09-GRANTED; import keys copy=true move=false write=true; fence 2/2; inboxes 0; library.db 0 |
| D-13 | deployed `diff-music-tags.sh` sha256 = repo, `AMBIGUOUS_BEFORE` present |
| Barrier | VERIFIED five times: 18:45:16Z (pre-stage), 18:48:56Z (post-preview), 18:49:53Z (pre-gate), 19:46:13Z and 19:54:06Z (post-import); no MA sync or restart since 09:17Z |
| D-29 | rank 1 b057dee8 passes all three; ranks 2–5 refused on per-disc count |
| Criterion 3 | 50/50 files: ffprobe tags = DB row on 7 fields (0 mismatches, comparator driven); 50/50 `568:568` from atlantis; 0 EPERM-class lines (read from `/logs/*.log`, not `docker logs`) |
| Criterion 4 | `diff-music-tags.sh` exit 0; MATCHED 50; dropped 0; ambiguous 0/0; empty-BEFORE 0; gained 2008 (all MB fields); changed 190, each reasoned |
| Oracle (D-07) | 50/50 diverge at directory level (`Various/NOW That's…` → `Various Artists/Now That’s…`), 13 also at file name; all MATCH-CHANGED-TAG, TEMPLATE-DEFECT 0, DD-TT prefixes 50/50 |
| Criterion 7 | **UNKNOWN** — `check-music-import.sh` exit 3: class 1 can't enumerate relative item paths (DEF-07-10-03); classes 2/3 clean, findings 0 |
| Criterion 8 | P10 source manifest (52 rows) identical to pre-stage and equal to 07-07's |
| Criterion 6, Jellyfin | one targeted file-scope `POST /Library/Media/Updated` → 204; one album, AlbumArtist `Various Artists`, 50 tracks, discs {1,2}, 1..24 / 1..26 |
| MA | provider-filtered 70 / 1,244 / 66 = 07-07 baseline (bogus-id control 0/0/0); no `*117*` album |

## Findings (for plan 07-11's gate)

- **DEF-07-10-01**, materialised as predicted before import. beets writes `va_name` "Various
  Artists" and MB's album text, so the directory is not the oracle's `Various/NOW That's …`.
- **DEF-07-10-02**: 13 file names follow MusicBrainz titles, not the source tags. This includes
  the corrected split of `Sophie Ellis` / `Bextor - Murder On The Dancefloor`.
- **DEF-07-10-03**: `check-music-import.sh` class 1 is blind on beets 2.12's relative item paths,
  so every criterion-7 reading stays UNKNOWN until it's fixed. It's an instrument defect, not
  fixed here.
- E6 input, recorded and not scored. Jellyfin's `Artists` array equals the ARTISTS tag on 12/12
  multi-artist tracks. `ArtistItems` links only artists that already exist as entities (5 of 50
  tracks), because a targeted update doesn't create artist entities.

## Deviations from Plan

- **The premature "imported" relay (process, not a product defect).** The first "imported"
  answer (~19:01Z) was relayed before the operator had opened the beets-flask web UI. The
  operator's words: "i forgot to open the web ui the first time, sorry". A continuation checked
  live state before recording anything (library.db 0 items, session still `PREVIEW_COMPLETED`,
  no chosen candidate) and stopped. The operator then imported at 19:44:19Z. beets-flask's file
  log carries exactly one `run_import_candidate`, which confirms no confirm was lost. No
  deferred item was filed. Lesson kept in the artifact: record an import only after the live
  state agrees with the answer.
- **[Rule 3] EPERM count read from `/logs/*.log`.** beets-flask's import worker logs to files
  inside the container. `docker logs` held 0 lines for the import window, so the plan's
  implied route would have read a vacuous zero.
- **Ledger at Task 2.** On the import path the plan writes no Task 2 ledger token (the newest
  must stay `07-10-GATE-STAGED` until `LANDED`). The P01 disposition is therefore carried in
  the `STATE 07-10-LANDED` line and in the amendment, not in a separate ledger line.

## Carried forward

- The staged P10 copy is still in `_inbox/02-review`, because `import.copy` leaves it. 07-11
  owns it.
- The dangling P01 preview row `d2772a06…` / session `8ad1c311…` is untouched. 07-12 reads it
  before re-staging P01 under `exception-gate`.
- MA fs-sync tasks are still disabled. The re-enable is owed at 07-15, after its MA proof.
- MA has not been synced. Its half of criterion 6 belongs to 07-15.

## Self-Check: PASSED

- `07-10-SUMMARY.md`, `07-SAMPLE-AMENDMENT.md`, `deferred-items.md` and `07-10-PARTIAL.md` all exist.
- Commits d59fd27, 1e5ad90, 6b91d00 and 4ad2b12 exist, and the Task 3 verify passed before the final commit.
