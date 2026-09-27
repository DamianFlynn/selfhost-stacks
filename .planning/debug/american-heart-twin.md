---
status: diagnosed
trigger: "american-heart-twin: Benson Boone American Heart appears twice in Jellyfin and MA (UAT 07 test 5)"
created: 2026-09-28T00:00:00Z
updated: 2026-09-28T12:00:00Z
---

## Current Focus

hypothesis: CONFIRMED (composite) — deliberate test pair landed as designed (operator chose Keep both, DEF-07-12-07); both matches are format-wrong CD releases that are MB duplicates of ONE product; MA merging is MA-by-design recording identity, not a defect
test: done
expecting: n/a
next_action: return ROOT CAUSE FOUND; operator decision needed (back out P04 / keep both / defer)

## Symptoms

expected: American Heart appears once per consumer, OR a deliberate, correct, distinguishable twin (two genuinely different MB releases, each album playing its own files).
actual: Two American Heart albums in Jellyfin and MA; operator flags as unwanted.
errors: none
reproduction: UAT test 5 in .planning/phases/07-pilot-12-albums-end-to-end/07-UAT.md
started: imported 2026-09-26 (P02 21:58:27Z, P04 23:11:42Z), plan 07-12

## Eliminated

## Evidence

- timestamp: 2026-09-28
  checked: MB WS/2 release-group 8e25d6da (5 releases) + each release with recordings (read-only, 1 req/s)
  found: c0df8104 = CD, US, barcode 093624834588, jewel case, Amazon ASIN B0F4FYXYJ4, integer-second track lengths. c33163f3 = CD, XE (+US event), SAME barcode 093624834588, catno 093624834588, Discogs 34320172. Same format, same barcode, same 10 recordings -> two MB entries for ONE physical CD. Digital releases exist: b3a1e018 (XW, Spotify, 093624830603) and cfb585a2 (XW, iTunes/Deezer, 093624834960). e4fdb1dc is the US marbled vinyl. All five share the same 10 recording MBIDs.
  implication: the twin is NOT two genuinely different releases in any meaningful sense, and BOTH matches are format-wrong for WEB sources (a CD cannot be 24-bit; the MP3 is a WEB rip). Correct targets are the XW Digital Media releases.
- timestamp: 2026-09-28
  checked: /mnt/fast/appdata/arrs/beets/config/config.yaml match.preferred
  found: countries ['GB','US'], original_year yes; NO preferred.media. XW (worldwide digital) never matches GB/US.
  implication: the config structurally favours US physical releases over digital ones, which is why the 3-way tie (DEF-07-12-05) was vinyl/CD/CD. Which of the tied cards the UI sent is secondary.
- timestamp: 2026-09-28
  checked: library.db (mode=ro) albums 2,9 and items
  found: same mb_releasegroupid, same barcode, same 10 mb_trackid (recording) + ISRC per position; album 2 FLAC 24/44.1 ~1.6 Mbps, album 9 MP3 320k; media 'CD' on both; catalognum '' (2) vs '093624834588' (9) -> the %aunique suffix. items.length equals the MATCHED MB track length (157.0 vs 156.56), not the file.
  implication: the %aunique disambiguator is the shared barcode, so it distinguishes nothing a listener can read.
- timestamp: 2026-09-28
  checked: mutagen durations of both library dirs (read-only, inside beets-flask /venv)
  found: all 10 pairs identical to 0.1 ms (156.5821 ... 172.5200); FLAC 24-bit, MP3 44.1.
  implication: same recording/master in two formats; not different content.
- timestamp: 2026-09-28
  checked: source tags (nzb/music P02, P04)
  found: no barcode/UPC/MBID tags; only date+organization. Folder names say WEB for both.
  implication: which digital release (Spotify vs iTunes barcode) is not determinable from the files.
- timestamp: 2026-09-28
  checked: Jellyfin GET Items (from LXC 100 via t3_proxy)
  found: two MusicAlbum items, both named plain 'American Heart': 018bd709 -> Benson Boone/American Heart (MB c0df8104, 10 FLAC), e44d9655 -> Benson Boone/American Heart [093624834588] (MB c33163f3, 10 MP3). Each holds its own 10 files, no crossover.
  implication: Jellyfin representation is correct-but-indistinguishable (same display name; suffix is folder-only).
- timestamp: 2026-09-28
  checked: MA music/albums/get + album_tracks for 167, 169 (GET-equivalent reads, no sync)
  found: album_tracks(167) == album_tracks(169), same 10 library track ids. Each track has 2 file mappings (FLAC 24 + MP3 16); tracks 1541 (Sorry I'm Here) and 1548 (Mystical Magical) ALSO carry the NOW 121 (P05) MP3 mapping. Both album entities carry external_ids including NOW 121's album MBID 0a74adf8, RG b3cb0f03 and barcode 00196872951165 (verified 0a74adf8 = NOW 121 in MB and library.db album 6). Album 169's first image is the NOW 121 track file, then the archive.org CAA art for 0a74adf8.
  implication: MA library tracks are keyed on recording identity (MBID/ISRC), so the same recording from any album merges into one track with multiple mappings; MA plays the best mapping, so P04's MP3s are effectively shadowed by P02's FLAC. That is MA design, not the defect. But the album-level external_id bleed of NOW 121 into both American Heart albums is real and is the mechanism behind the wrong MA cover on album 169 (the separate cover diagnosis).
- timestamp: 2026-09-28
  checked: ROADMAP/REQUIREMENTS/07-CONTEXT/deferred-items/beets.md for DUPE, twin, duplicate policy
  found: DUPE-01/02 cover dj-mixes vs unsorted folder-name collisions; D-03 folds them into an archive phase to be INSERTED between 8 and 9 (not yet created, /gsd-phase work). D-04 drew the Benson pair deliberately to fire %aunique; D-28 verifies it in MA. No same-album-different-format policy (keep best / keep both / duplicate_action) is decided anywhere; config has duplicate_action: ask; the P04 landing was the operator's 'Keep both' (DEF-07-12-07). 07-15 recorded the twin representation 'other' with NO verdict (P7R2-07).
  implication: this is an undecided policy, now forced by the operator's UAT rejection.

## Resolution

root_cause: Not a single defect. (a) The duplicate is the designed outcome of a deliberate test pair (D-04), landed by an explicit 'Keep both' (DEF-07-12-07), under a same-album-different-format policy that was never decided; the operator has now rejected it. (c) Both landings are format-wrong matches: c0df8104 and c33163f3 are two MB entries for the same US CD (same barcode 093624834588), while the sources are WEB rips; the config's preferred.countries [GB,US] with no preferred.media pushes XW digital releases below physical ones, so the 3-way tie was physical-only. The %aunique suffix is that shared barcode, so the twin is indistinguishable in both UIs. (b) MA's shared-track merge is by design (recording identity), but the same merge carries NOW 121's album external_ids into both American Heart album entities, which is the cross-album cover path.
fix: (not applied - diagnose only)
verification:
files_changed: []
