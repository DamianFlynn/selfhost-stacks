---
phase: 07-pilot-12-albums-end-to-end
plan: 15
subsystem: music consumers / criterion 6 in Jellyfin then Music Assistant, D-28, E6, D-24 after-census
tags: [criterion-6, cons-04, music-assistant, jellyfin, d-28, aunique, e6, d-24, ma-barrier, phase7]
requires: [07-14, 07-13, 07-12, 07-10]
provides:
  - "STATE 07-15-CONSUMERS-READ: all 9 landed albums read in Jellyfin (first) and Music Assistant (last, after one sync)"
  - "check-music-consumers.sh section 4d (D-28 %aunique{} albums in MA, pinned AUNIQUE_ROWS); the D-22 MA section renumbered 4e"
  - "MA fs-sync barrier lifted: the four music_sync_filesystem_local--XJaJWNUS_* tasks re-enabled and read back"
  - "DEF-07-15-01: MA artist-entity display names drift without their links moving"
affects: [07-16, 07-17, phase-8, phase-9]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/07-15-SUMMARY.md
  modified:
    - scripts/check-music-consumers.sh
    - CONVENTIONS.md
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-15-consumers.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Operator at the Task 2 gate: \"sync\", recorded verbatim with DISPOSITION: sync"
  - "Exactly one music/sync, for the provider list [filesystem_local--XJaJWNUS] only, guarded by a sentinel against a second issue"
  - "MA album identity is the ALBUM-level provider mapping (item_id == directory). MA models a track as a recording that can carry several mappings, so a track-path-only test would false-flag shared recordings"
  - "The existing section 4d (D-22 MA) was renumbered 4e so the plan's D-28 section could take 4d"
  - "The red branches were driven on a throwaway copy of the script with substituted rows, not through a new override knob (CONVENTIONS §4)"
  - "The D-24 pin was not moved (AFTER == BEFORE by sha)"
requirements-addressed: [CONS-04, IMPT-01]
requirements-completed: []
metrics:
  completed: 2026-09-27
  runs: 2 (Task 1 + Task 2 pre-gate; continuation for the sync arm and Task 3)
  duration: "continuation 13:54Z – 14:10Z (sync 13:55:48Z – 13:56:37Z)"
  tasks: 3
---

# Phase 7 Plan 15: Criterion 6 in both consumers, D-28, E6 and D-24 after — Summary

**All nine landed albums were read in both consumers in the carried order. Jellyfin was read first
(9/9, Task 1). Music Assistant was read last, after exactly one sync of the local filesystem
provider (`music/sync {"providers":["filesystem_local--XJaJWNUS"]}` at 13:55:48Z; MA logged "Found
211 changed/new items", which is the 197 pilot files plus the 14 E5 files). In MA every album
resolves by its directory to exactly one MA album, and every file maps to exactly one MA track.
There are 0 duplicates. P05 is one `Various Artists` album of 44 tracks. P10 is one album of 50
tracks on discs {1,2}. D-28: both `%aunique{}` albums (the Benson Boone twins) read album artist
`Benson Boone` in MA, so the silent `folder_name` fallback did not fire. Afterwards the four MA
fs-sync tasks were re-enabled and read back 4/4.**

## What was done

- **Task 1** (de1c1fa, previous agent): Jellyfin criterion 6 read 9/9. E6's first measurement:
  33 of 33 multi-artist imports have Jellyfin `ArtistItems` equal to the tag. The aunique
  inventory was rebuilt (one firing set, P02/P04, no change vs 07-12). D-24 AFTER equals BEFORE.
- **Task 2** (ee0cc4f, previous agent): read the MA pre-state (2.11.0b2, provider XJaJWNUS,
  70/1244/66, 0 pilot albums visible). BARRIER VERIFIED. MA SYNC SINCE 07-10: NONE SEEN.
- **Gate:** the operator answered `sync`, recorded with `DISPOSITION: sync`. The barrier was
  re-read and VERIFIED at 13:54:58Z, before any MA write.
- **Sync:** one call, with the provider list asserted to be exactly the local instance. It ran the
  four scheduled tasks on demand, and all four finished `success` by 13:56:37Z. The call did not
  re-enable their schedule. Counts went from 70/1244/66 to 79/1412/201.
- **MA readings:** the `CRITERION 6 — MUSIC ASSISTANT` table in `07-15-consumers.txt`, plus D-28,
  `TWIN REPRESENTATION`, E6 and the context readings.
- **Task 3 script work** (c246e2f): added section 4d with the `AUNIQUE_ROWS` pin and registered
  it in CONVENTIONS §5 in the same commit. Renumbered the D-22 MA section to 4e. The edited
  script, run on LXC 100 with a sha-equal copy, exited 3 (CONF-04 pending, FAILURES 0), with D-28
  at 2/2. All four failure arms were driven red. It was deployed by push, then a separate host
  porcelain read (clean), then `pull --ff-only`, with the host sha matching the workstation's.
- **Re-enable:** four `tasks/set_enabled enabled:true` calls, one per id. The read-back shows 4/4
  `enabled=true` with `next_run` 2026-09-28T01:55:48Z. The ledger has `MA RE-ENABLE: DONE
  2026-09-27T14:03:56Z`.

## Results (measured; the verdict column is left for /gsd-verify)

| P-ID | Jellyfin album artist / tracks / discs | MA album / album artist / tracks / discs |
|---|---|---|
| P10 | Various Artists / 50 / {1,2} | 166 / Various Artists / 50 / {1:24, 2:26} |
| P02 | Benson Boone / 10 / {1} | 167 / Benson Boone / 10 / {1} |
| P03 | Benson Boone / 15 / {1} | 168 / Benson Boone / 15 / {1} |
| P04 | Benson Boone / 10 / {1} | 169 / Benson Boone / 10 / {1} |
| P05 | Various Artists / 44 / {1} | 165 / Various Artists / 44 / {1} (one album) |
| P06 | CYRIL / 1 / {1} | 164 / CYRIL / 1 / {1} (name `Stumblin’ In`, version `LUNAX remix extended mix`) |
| P12 | Various Artists / 47 / {1,2} | 3 (pre-existing Spotify album, now also locally mapped) / Various Artists / 47 / {1,2} |
| P07 | Mastermix / 10 / {1,2} | 163 / Mastermix / 10 / {1,2} (album_type unknown) |
| P08 | Various Artists / 10 / {null} | 162 / Various Artists / 10 / {0} (DEF-07-13-03) |

- **D-28:** 2 of 2. Album 167 (P02) and album 169 (P04) both read `Benson Boone`, and 0
  fallbacks fired. The standing check reads the same result.
- **TWIN REPRESENTATION (P02/P04):** `other`. MA holds two albums, each with its own album-level
  mapping, and they share the same ten MA tracks. Each track carries two provider mappings (FLAC +
  MP3). No verdict is attached.
- **E6 second measurement:** NOT TAKEN. F1 (P09) did not land, and no landed track carries 4 or
  more ARTISTS values (the maximum is 3). No F1 proof row was added. Beside it, MA reads the 33
  landed 2–3-artist tracks 33/33 with the same count and name set as the tag.
- **ffprobe ID3v2.4 multi-value finding (Task 1):** `ffprobe` truncates a multi-value ID3v2.4
  `TXXX:ARTISTS` frame to its first value. The E6 census therefore used mutagen, and any future
  E6/D-05 read of MP3 files must do the same.
- **D-24:** AFTER equals BEFORE (29 items, sha `fa2e7a51…`). Row 1 for DEF-06-45-03 did not
  move, and the pin is unchanged.
- **"Brian Coll" (DEF-07-14-01):** after the sync, 0 MA tracks carry that artist. Entity 116 now
  reads `Def Leppard`, and 257 Def Leppard tracks read `Def Leppard`. The mechanism is unmeasured.
- **Def Leppard (2015) / album 116:** album 116 now has album artist `Def Leppard` (it was empty).
  It is still mapped to the top-level `Def Leppard` folder, and all 14 tracks read album 116.
  **"Sea Of Love"** now has album 116; before, it had none (the 02-07 hard error).
- **Fireworks pair (DEF-07-12-08):** MA shows two albums, 137 (the untracked `(2024)` copy) and
  168 (P03). Both are Benson Boone with 15 tracks, and both list the same 15 MA tracks. This was
  recorded and not touched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The plan's new section name collided with an existing `# 4d.`**
- **Found during:** Task 3
- **Issue:** the plan fixes the new section's title as `4d. %aunique{} albums in Music Assistant
  (D-28)` (its verify greps for it), but `check-music-consumers.sh` already had `4d. D-22 …` for
  the MA artist rows.
- **Fix:** renumbered the D-22 MA section to `4e` everywhere it is referenced: the header coverage
  list, three header paragraphs, the section banner (with a dated note), the echo line, and the
  CONF-04 block's "See 4b/4e". The CONF-04 block keeps its line count and its `Discharges on
  ROADMAP` last line. Nothing outside the script referenced `4d` (checked with `git grep`, which
  excludes `.planning`).
- **Commit:** c246e2f

**2. [Rule 1 - Instrument] The identity test was adapted to MA's track model**
- **Found during:** Task 3 MA reading
- **Issue:** the plan's assertion "tracks belong to MA album(s) whose mapped paths are all under
  that directory" assumes one mapping per track. MA 2.11 models a track as a recording entity that
  can carry several provider mappings (29 pilot files attached to shared recordings). Read
  literally, the test flags P10, P03 and P05 as "mixed in" when nothing is.
- **Fix:** the album is identified by its album-level mapping. The test asserts that every file
  maps to exactly one MA track, that every such track is in the album, and that every album track
  has at least one local mapping under the directory (under the union for the twins). The shared
  recordings are listed explicitly. The same identity rule is used by the standing section 4d.
- **Commit:** c246e2f

## Known Stubs

None.

## Deferred Issues

- **DEF-07-15-01** (filed): MA artist-entity display names drift while their links stay the same.
  Pinned D-22 row 1 now reads `Twista | Lady Gaga | Too $hort` over the same entity ids that read
  `T.I. | Lady GaGa | Too $hort` on 2026-09-21. As a result, section 4e's runtime text "'Twista'
  exists nowhere in MA's library artists" is now stale, and the E6 second measurement's "different
  missing name" discriminator must record entity ids. It was not edited here because it belongs to
  the CONF-04/E6 owner.
- Section 4e's track search uses `MA_LIBRARY_SCAN_LIMIT=2000`, and MA now holds 1,412
  provider-local tracks. It has headroom, but each later import eats into it. Section 3 has a
  truncation guard and 4e does not. This is noted here and was not changed.

## Threat Flags

None. The only MA writes were the one sync and the four `set_enabled` calls, both within the plan's
threat register (T-07-15-01, T-07-15-07). No credential appears in the artifact.

## Self-Check: PASSED

- Files present: `07-15-SUMMARY.md`, `07-15-consumers.txt`, `07-pilot-ledger.txt`,
  `check-music-consumers.sh`, `CONVENTIONS.md`.
- Commits present: de1c1fa, ee0cc4f, c246e2f.
- Plan verifies: Task 1 PASS, Task 2 PASS, Task 3 PASS (run 2026-09-27T14:0xZ).
  `REQUIREMENTS.md` is unchanged, and the artifact contains no `Full[R]efresh`.
