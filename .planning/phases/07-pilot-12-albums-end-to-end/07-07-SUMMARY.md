---
phase: 07-pilot-12-albums-end-to-end
plan: 07
subsystem: music-pipeline / pilot before-states
tags: [qual-02, cons-04, impt-01, d-24, e6, criterion-4, criterion-6, criterion-8, before-state]
requires:
  - 07-SAMPLE.md (P01-P12, folder paths, per-folder audio counts)
  - scripts/snapshot-music-tags.sh (unchanged; deployed sha256 == HEAD)
  - scripts/diff-music-tags.sh plan-07-02 version (fence copy /mnt/fast/safety/phase07/diff-drive/)
provides:
  - pre-07-P01 … pre-07-P12 + pre-07-pilot captures under /mnt/fast/safety/music-pre-project/tags/ (the BEFORE of record for criterion 4)
  - artifacts/07-07-source-manifest-before.tsv — criterion-8 BEFORE manifest (atlantis, real root)
  - scripts/check-music-consumers.sh section 4c — standing D-24 census with a measured pin
  - artifacts/07-07-before-state.txt — capture record, pre-project coverage, D-24/E6/criterion-6 baselines
affects: [07-09, 07-10, 07-12, 07-13, 07-14, 07-15, 07-17]
tech-stack:
  added: []
  patterns:
    - "per-album BEFORE, so a one-album AFTER is never read as eleven albums MISSING_AFTER"
    - "coverage asserted (TotalRecordCount == Items length) before a pin is taken or compared"
    - "pin measured from an empty-pin run, then re-run against the pin to see it hold"
    - "every new failure arm driven on a throwaway copy (Limit=5, N off by one) before being trusted"
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-07-before-state.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-07-source-manifest-before.tsv
  modified:
    - scripts/check-music-consumers.sh
    - CONVENTIONS.md
decisions:
  - "D-24 census pinned at the MEASURED 29 (ARTPOP 15 + Joanne 14), not the prose 30. The 30th zero-ArtistItems item, Def Leppard 'On Through the Night (1980)/… Overture.flac', has an EMPTY Artists list, so it is outside D-24's predicate. It is also not in the 'Def Leppard (2015)/' folder that the E5 repair names."
  - "The existing MA D-22 section was renumbered from 4c to 4d, because this plan and 07-15 both name the D-24 census 'section 4c'. Every 4c reference in the file moved with it, including 'See 4b/4c' in the CONF-04 exit block. That block stays at 8 lines, and the Discharges phrase is still on its last line."
  - "The D-24 changed-set arm is a separate block above the CONF-04 exit-3 block. When artist rows are also pending, the CONF-04 block's exit 3 fires; when they are not, this block exits 3 itself. The CONF-04 block and the green line are byte-unchanged."
  - "The pin carries D24_CENSUS_BASELINE_PATHS beside N and SHA, so that a change prints added and removed paths. If the three disagree with each other, the check goes red."
metrics:
  duration: "~40 min"
  completed: 2026-09-26
  tasks: 2
  files: 4
---

# Phase 7 Plan 07: Pilot Before-States Summary

Took every before-state the pilot is judged against, before any write. That covers per-album full-ffprobe captures of all 339 pilot files (`pre-07-P01` to `pre-07-P12` plus `pre-07-pilot`), measured Phase 1 coverage, and a byte manifest of all 12 source folders read on atlantis as real root. `check-music-consumers.sh` also gained a standing D-24 census with coverage asserted and a measured pin. Nothing was written to `/mnt/tank`, beets state, Jellyfin or Music Assistant.

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | `a9013fd` | per-album BEFORE capture, pre-project coverage, criterion-8 source manifest |
| 2 | `369b27b` | D-24 census section 4c + pins in CONVENTIONS §5 + CONSUMER BASELINES |

## Task 1: BEFORE capture, coverage, manifest

- The deployed `snapshot-music-tags.sh` sha256 `60212666…` equals HEAD. One run per folder produced 12 captures with rc 0 and `roots: 1`. On every album, records equal the 07-SAMPLE count and `.failed` is empty: 32 10 15 10 44 1 10 10 100 50 10 47.
- `pre-07-pilot` is the gzip-member concatenation of the 12: **339 records = sum, 339 distinct `audio_md5`**, sha256 `a05cc33f…`. No capture spans both roots of a DUPE-01 pair.
- **Pre-project coverage is 271/339.** P01–P04 and P06 are 0% (68 `music/` arrivals after 2026-08-18); every other album is 100%. P07, P08 and P11 each have a `dj-mixes`↔`unsorted` twin that is still present. Against pre-project, P08 and P11 exit 3 UNKNOWN, which is the 07-02 E7 contract firing as designed. Restricted to the same folder, all three exit 0 with 0 changed. Across all 271 covered files the tags are unchanged since 2026-08-18.
- **Source manifest:** 347 files (339 audio + 8 non-audio), 12 P-IDs, sha256 `8480c429…`. It is identical on atlantis, on LXC 100 and in the repo. Every top-level folder reads `568:568 777` from atlantis.

## Task 2: D-24 census and consumer baselines

- **Section 4c** makes one `/Items` GET with no SearchTerm. A missing envelope is `jellyfin_fail`. A `TotalRecordCount` that is absent or differs from the `Items` length is `jellyfin_fail` UNKNOWN, and no pin comparison is made. A set that matches the pin passes. A changed set sets `D24_CENSUS_CHANGED` (line 1529) and feeds the exit-3 block (line 1834), so it is never green. Summary label: `D-24 census (Artists, no ArtistItems):`.
- **Arms driven:** the coverage-mismatch arm (copy with `Limit=5`) gave "covers 5 of 1244" and rc 1. The pin-inconsistency arm (copy with N=28) went red with rc 1. The changed arm (run1, empty pin) gave rc 3 and printed 29 `+` paths.
- **Baseline run (run2, committed script `a8078e84…`):** rc 3, FAILURES 0. **TotalRecordCount 1244 == Items 1244 == the JF Audio count.** D-24 measured 29, sha `fa2e7a51…`, at pin.
- **Proof rows:** in Jellyfin, rows are 0/1/1 against baselines 0/1/1, so 3 are PENDING. In MA, row 1 is 3 against a tag of 4 and is REPORTED; rows 2 and 3 are at target.
- **Criterion-6 counts:** Jellyfin has 70 MusicAlbum and 1,244 Audio. MA, filtered to `filesystem_local--XJaJWNUS`, has 70 albums, 1,244 tracks and 66 artists. The unfiltered `albums/count` reads 156 and is labelled as unfiltered.
- The Summary heading `📊 6. Summary`, the `Discharges on ROADMAP` line and the final green line appear on no removed diff line. The grep for `Full[R]efresh|ReplaceAllMetadata=true` over comment-stripped lines counts 1 on a control line and 0 on the file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Section-number collision.** The plan asks for `# 4c. Artists-without-ArtistItems census (D-24)`, but 4c already held the MA D-22 section, and 07-15 cites the D-24 census as "section 4c". Fix: renumbered the MA section to 4d everywhere in the file, including `See 4b/4c` → `See 4b/4d` inside the CONF-04 exit block. That block is still 8 lines with the Discharges phrase last. Commit `369b27b`.

**2. [Rule 2 - Correctness] Pinned path list.** A digest alone cannot print the "added and removed paths" the plan requires. Fix: added `D24_CENSUS_BASELINE_PATHS` with a three-way consistency check, and registered it in the same §5 bullet. Commit `369b27b`.

**3. [Rule 1 - Measurement] 29, not 30.** This is recorded, not fixed. The pin is the measurement, and the reason for the difference is in the artifact.

## Findings for downstream plans

- **For 07-15 (information, not a conclusion):** MA row 1's set has changed while its count has not. It was `T.I. | Lady GaGa | Too $hort` on 2026-09-20 and is now `Twista | Lady Gaga | Too $hort`. With a different name dropped, the evidence leans toward "MA caps at 3" over "Twista failed to map", but this is still one sample.
- **For 07-14/07-15:** the Def Leppard `On Through the Night (1980)` Overture item has no Artists, no ArtistItems and no AlbumArtist. It falls outside D-24's predicate.
- **Follow-up (not fixed):** in `quick-health-check.sh`, the `-eq 3` arm's heading says "artist rows at baseline". If D-24 changes while no artist row is pending, that heading misdescribes the cause, though the result is still non-green. Today it cannot trigger, because 3 JF rows are pending.
- The host checkout (`0c95427`) still runs the old audit. Section 4c goes live in the routine health check only after a pull.
- 07-17 re-takes the source manifest with the same program: `/root/phase07-0707/manifest.sh` on atlantis, sha256 `879f478e…`.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: artifacts/07-07-before-state.txt, artifacts/07-07-source-manifest-before.tsv, scripts/check-music-consumers.sh (section 4c), CONVENTIONS.md (§5 bullet)
- FOUND: commits a9013fd, 369b27b; 823fe04 is an ancestor of HEAD
- Both task `<verify>` blocks pass.
