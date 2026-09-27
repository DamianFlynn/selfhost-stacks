---
status: diagnosed
trigger: "pilot-cover-art-crossover: Jellyfin shows NOW 117 (P10) with NOW Disney 3 cover; MA shows one American Heart (P02/P04) with NOW 121 (P05) cover"
created: 2026-09-28T00:00:00Z
updated: 2026-09-28T00:50:00Z
---

## Current Focus

hypothesis: CONFIRMED. Two separate consumer-side gap-fill mechanisms, both triggered by the same upstream fact: P10 (NOW 117) and P04 (American Heart [093624834588]) landed with no art at all (the source had none, and beets has no art plugin).
test: done (see Evidence)
expecting: n/a
next_action: return ROOT CAUSE FOUND to the caller (goal find_root_cause_only). No write performed or needed for diagnosis.

## Symptoms

expected: Each of the nine landed pilot albums shows its own cover art in Jellyfin and Music Assistant.
actual: Jellyfin: NOW 117 (P10) shows NOW That's What I Call Disney 3 art. MA: one American Heart tile shows NOW 121 (P05) art. Everything else correct.
errors: none
reproduction: UAT tests 2 and 5 in .planning/phases/07-pilot-12-albums-end-to-end/07-UAT.md
started: Phase 7 UAT 2026-09-27; imports 2026-09-26/27; P10 imported, undone, re-imported (07-11); P01/P09 undone (07-12) freeing beets album ids 5 and 7.

## Eliminated

- hypothesis: (b-reuse) consumer caches keyed on the beets album ids 5/7 freed by the undo
  evidence: neither consumer references beets ids. The Jellyfin item id is path-derived: the 117 image survived the undo only because the re-import recreated the same path, and the image was already wrong at the first fetch (19:52Z). MA ids 162-169 are MA's own. The MA crossover is a track merge, not an id collision.
  timestamp: 2026-09-28

- hypothesis: (c-CAA) Cover Art Archive holds the wrong image for 117's MBID
  evidence: the CAA front for release b057dee8 / RG 62315ade is the correct 117 cover (sha256 6d83625a…). MA uses it and shows 117 correctly.
  timestamp: 2026-09-28

- hypothesis: (a) the files/sidecars/beets art depict the wrong cover (Disney 3 / NOW 121)
  evidence: P10 and P04 library dirs AND sources carry no image at all (no sidecar, no embedded picture); beets has no art plugin and artpath NULL; no Disney album exists locally
  timestamp: 2026-09-28

## Evidence

- timestamp: 2026-09-28
  checked: find non-audio files in all pilot album dirs under /mnt/tank/media/Music (atlantis, root); find -iname '*disney*' maxdepth 3
  found: zero sidecar images (no cover.jpg/folder.jpg) in any pilot dir; no Disney album exists in the local library
  implication: Disney 3 art cannot come from a local file; it must come from a consumer-side source (online provider / cache)

- timestamp: 2026-09-28
  checked: embedded pictures per file via mutagen in beets-flask (/venv/bin/python3, read-only)
  found: American Heart (P02 FLAC) 10/10 APIC type3 d37d1a4718b3; American Heart [093624834588] (P04 MP3) 0/10 NO picture; Fireworks 15/15 3f9a0657e4d1; NOW 117 (P10 FLAC) 0/50 NO picture; NOW 121 44/44 3c56c8b8297d; NOW 116 47/47 e30284141418; CYRIL, Issue 420, Issue 421 all embedded
  implication: the two albums showing wrong art are exactly the two with no local art at all; each consumer had to source art from elsewhere

- timestamp: 2026-09-28
  checked: beets config /mnt/fast/appdata/arrs/beets/config/config.yaml; library.db albums (mode=ro)
  found: plugins: [musicbrainz] only (no fetchart, no embedart; embedart.auto: no); albums.artpath NULL for all 9 albums
  implication: beets neither fetched nor embedded nor linked any art; it only carried through whatever pictures the source files had (import.write rewrites tags but keeps existing picture frames)

- timestamp: 2026-09-28
  checked: non-audio files in all 12 source folders (/root/phase07-0707/folders.tsv); embedded pictures in P10, P04, P05 source audio
  found: P10 source has only .cue + .log, 0/50 files with a picture; P04 source 0/10 with a picture; P05 source 44/44 picture 3c56c8b8297d == library copy. (P12 source has Front.webp/Back.webp sidecars beets did not carry, but its files embed art anyway.)
  implication: NOW 117 and American Heart [093624834588] were artless from the source; beets did not lose anything. The wrong image is chosen by each consumer when filling the gap. Hypothesis (a) "the files depict the wrong cover" ELIMINATED.

- timestamp: 2026-09-28
  checked: Jellyfin GET /Items (MusicAlbum, SearchTerm=Now) and /Items/{id}/Images, from LXC 100 via the t3_proxy IP
  found: NOW 117 item d18d5c99c4451068e6b3d6999cd48a3d, DateCreated 2026-09-26T21:02:47Z, ProviderIds MB album b057dee8…, RG 62315ade… (correct). Primary = /config/metadata/library/d1/d18d5c99…/folder.jpg, 1400x1400, 658823 B, sha256 09d8b5f8c9dd…, mtime 2026-09-26 20:52:05 +0100 (19:52:05Z). The image pre-dates the current item's DateCreated, which comes after the undo and re-import.
  implication: the art lives only in Jellyfin's internal metadata dir, not /media/Music, and came from a remote provider. The path-derived item id kept it across the undo.

- timestamp: 2026-09-28
  checked: the image itself, and CAA /release/b057dee8… and /release-group/62315ade…
  found: Jellyfin's folder.jpg visually IS "NOW That's What I Call Disney 3". The CAA front for 117 (id 40802828337) is the correct 117 cover.
  implication: CAA is not the source.

- timestamp: 2026-09-28
  checked: Jellyfin GET /Library/VirtualFolders (Music); /config/log/log_2026092[678].log (read-only grep)
  found: MusicAlbum ImageFetcherOrder [Apple Music, Fanart, TheAudioDB]; plugin Apple Music_3.0.6.2 with no configuration file (defaults). At 20:51:47 +01:00, AlbumImageProvider logged "Apple Music album ID is not available, using search with term 'Various Artists Now That’s What I Call Music! 117'". At 20:52:05.780 it logged "Found 7 albums", and folder.jpg was written at 20:52:05.919. The only other album-image search in three days of logs is "Benson Boone American Heart" (2026-09-27 00:24:54 +01:00, = P04, the other artless album).
  implication: Jellyfin goes to the Apple search only for albums with no local or embedded art.

- timestamp: 2026-09-28
  checked: the iTunes Search API with the same term, entity=album, limit=7, country=us vs gb; the Apple CDN artwork for collection 1440812619
  found: the US top hit is 1440812619 "NOW That's What I Call Disney 3" (7 results, matching the log's "Found 7"). The GB top hit is 1736129549 "NOW That's What I Call Music! 117". https://is1-ssl.mzstatic.com/image/thumb/Music126/v4/54/2a/6a/542a6af7-a622-5a58-c690-ba418119d394/14UMGIM43021.rgb.jpg/1400x1400cc.jpg is 658823 B, sha256 09d8b5f8c9dd…, BYTE-IDENTICAL to Jellyfin's folder.jpg.
  implication: CONFIRMED for Jellyfin. The Apple Music plugin searched the US storefront by name and took the first hit.

- timestamp: 2026-09-28
  checked: MA music/albums/get 165, 166, 167, 169; music/tracks/library_items search "Sorry I"; the beets items for that title (read-only); P04 file tags (mutagen)
  found: MA album 169 (P04) images = [embedded picture of "Various Artists/NOW That’s What I Call Music! 121/27 Sorry I’m Here for Someone Else.mp3", CAA thumb for mbid-0a74adf8 (= NOW 121)], nothing of its own. Album 167 (P02) has the same two foreign images, but its own FLAC embedded art is listed first. MA track 1541 is ONE track mapped to THREE files (NOW 121 #27, P04 #01, P02 #01), and its album is 165. In beets, all three share mb_trackid 545aa58c… and ISRC USWB12500464. The external_ids of MA albums 167 AND 169 include NOW 121's musicbrainz_albumid 0a74adf8…, RG b3cb0f03… and barcode 00196872951165, listed before their own. The P04 file tags hold only their own ids (Album Id c33163f3…, RG 8e25d6da…, BARCODE 093624834588). P04's own CAA release exists (HTTP 200) but is unused. MA 166 (117) uses the CAA mbid-b057dee8 image, which is correct.
  implication: CONFIRMED for MA. The shared-recording track merge contaminates the album twins with the compilation's ids and images. P04 has no own art to outrank them.

## Resolution

root_cause: |
  Upstream (both consumers): P10 NOW 117 and P04 American Heart [093624834588] landed with NO cover art: no sidecar and no embedded picture, in the library AND in the source. beets runs with plugins [musicbrainz] only and embedart.auto no, so the pipeline never supplies art.
  (1) Jellyfin: the Apple Music plugin is first in the MusicAlbum image fetchers. It searched by name in the US storefront, which does not carry the UK NOW 1xx series, and took the first hit: NOW Disney 3. The stored image is byte-identical to Apple's artwork.
  (2) MA: one MA track (1541) merges the shared recording from NOW 121 #27, P02 #01 and P04 #01. Through it, American Heart albums 167 and 169 inherit NOW 121's MB album id, RG, barcode and images. 169 has no art of its own, so NOW 121's art is shown.
fix: (not applied; diagnose-only)
verification:
files_changed: []
