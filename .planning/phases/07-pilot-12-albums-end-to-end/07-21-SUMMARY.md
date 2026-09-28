---
phase: 07-pilot-12-albums-end-to-end
plan: 21
subsystem: music-pipeline / Jellyfin consumer
tags: [jellyfin, apple-music, image-fetchers, primary-image, p04-backout, freeze]
status: complete
requires: ["07-18", "07-20"]
provides:
  - "Music library MusicAlbum ImageFetchers = [Fanart, TheAudioDB]; Apple Music moved last in ImageFetcherOrder"
  - "NOW 117 (d18d5c99…) stored Primary == P10 cover.jpg 6d83625a… (was the Disney 3 artwork 09d8b5f8…)"
  - "P04 album e44d9655… removed from Jellyfin; P02 018bd709… keeps 10 tracks"
affects: ["07-22", "07-23"]
tech-stack:
  added: []
  patterns:
    - "One POST per script run, preceded by a fresh freeze GET and a prepared-body sha re-check"
    - "LibraryOptions change proven by AFTER canonical sha == body sha, plus SAME on every other library"
key-files:
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-21-jellyfin.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Gate 2026-09-28T12:41:57Z: operator 'apply (Recommended)': send all three writes in order, re-reading the freeze before each"
  - "Apple Music stays a MusicAlbum METADATA fetcher; only image fetching was in OD-2's scope"
metrics:
  completed: 2026-09-28
  tasks: "3 of 3"
  duration: "~10m (Task 1 12:37Z to Task 3 12:45Z, plus the gate)"
---

# Phase 7 Plan 21: Jellyfin repair — Apple Music off for album images, NOW 117 cover, P04 drop (Summary)

Jellyfin no longer takes album covers from Apple Music's US storefront. NOW 117's stored cover is now
its own cover.jpg, byte for byte. The backed-out P04 album has gone from the library. Three single
POSTs made these changes, each preceded by a Music freeze PASS. No refresh or scan call was made, and
nothing new was written under `/media/Music`.

## What was done

| Step | Write | Result |
|------|-------|--------|
| T1 | GETs only (commit 83e795b) | Freeze PASS; BEFORE hashes; Disney Primary safety-copied; three bodies prepared and self-checked |
| T2 | Gate | "apply (Recommended)" at 12:41:57Z → `DISPOSITION: apply` |
| W1 | `POST /Library/VirtualFolders/LibraryOptions` → 204 | Music sha `cc00f50d` → `c68f71f4` (== body); Shows/Collections/Movies/TV Recordings SAME; 0 scan/refresh/nfo/saver log lines |
| W2 | `POST /Library/Media/Updated` (11 Deleted paths) → 204 | P04 gone at +91 s; MusicAlbum 79 → 78; P02 present, 10 tracks |
| W3 | `POST /Items/d18d5c99…/Images/Primary` → 204 | Stored `6d83625a…64e8` == cover.jpg, 3540×3540, not re-encoded |
| After | atlantis real root | `.nfo` 91, `.jpg` 89, not-568:568 0, `find -newer` stamp 0, P10 listing identical |

Artifact markers: `APPLE MUSIC (MusicAlbum): DISABLED`, `JELLYFIN P04: REMOVED (targeted Deleted update)`,
`PRIMARY IMAGE: REPLACED (… == cover.jpg: yes; != Disney 09d8b5f8…: yes)`, `JELLYFIN NO-SIDECAR: PASS`.

## Undo, if ever wanted

- W1: POST `/mnt/fast/safety/phase07/0721/lo-before-7e64e319….json`, wrapped with the library Id.
- W2: none needed. A scan re-adds P04 only if its files return.
- W3: upload `/mnt/fast/safety/phase07/0721/p10-primary-before.jpg` (09d8b5f8…).

## Deviations from Plan

None in the writes. Two recording notes:
- The P10 listing compare had to normalise one name. Task 1 wrote the directory's own row under its
  basename, and the Task 3 `find .` writes it as `.`. With that name normalised, the sha matches Task 1's
  `407c00e0…` exactly.
- W2's log carried one `refresh` line. It came from Jellyfin's LibraryMonitor revalidating
  `Benson Boone/` in response to the Deleted notification. This plan did not call it. Filed as
  DEF-07-21-01 (observation). Nothing was written.

## Findings

- **DEF-07-21-01** (observation): a targeted `Media/Updated` makes Jellyfin revalidate the parent artist
  folder. It is safe here because of the freeze, not because the call is narrow. Keep the pre-write freeze
  assertion on any future targeted update.

## Known Stubs

None.

## Open for 07-23

- The operator visually checks NOW 117's cover in the Jellyfin UI.
- The D-28 red in quick-health-check is known and is fixed by 07-22. It was not touched here.

## Self-Check: PASSED

- 83e795b (Task 1) and 34967ef (Task 3) exist on local main. Both are unpushed; the plan does not ask for a push.
- The artifact passes both the Task 2 and Task 3 automated verify blocks, and has 0 matches for the refresh-endpoint patterns.
