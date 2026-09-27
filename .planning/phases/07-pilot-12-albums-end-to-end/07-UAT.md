---
status: complete
phase: 07-pilot-12-albums-end-to-end
source: [07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md, 07-04-SUMMARY.md, 07-05-SUMMARY.md, 07-06-SUMMARY.md, 07-07-SUMMARY.md, 07-08-SUMMARY.md, 07-09-SUMMARY.md, 07-10-SUMMARY.md, 07-11-SUMMARY.md, 07-12-SUMMARY.md, 07-13-SUMMARY.md, 07-14-SUMMARY.md, 07-15-SUMMARY.md, 07-16-SUMMARY.md, 07-17-SUMMARY.md]
started: 2026-09-27T21:48:57Z
updated: 2026-09-27T23:23:07Z
---

<!-- Test expectations are taken from artifacts/07-17-evidence.txt (measured 2026-09-27T19:0xZ).
     Landed: P10 P02 P03 P04 P05 P06 P12 P07 P08 (9). Held, NOT landed: P01 P09 P11. -->

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test — beets-flask after the rw-grant change
expected: After a restart of beets-flask, the container comes up clean. https://beets.deercrest.info loads behind Authelia, shows inboxes 02-review and 03-asis, and the library reports 9 albums. The mount is read-write on /media/Music only, not on all of /media.
result: pass
evidence: "Run by Claude at operator's request 2026-09-27T22:32:52Z. Pre-check: rq queues import/preview 0, wip 0; library.db/state.pickle 2ff94600…/d1958008…. `compose up -d --force-recreate --no-deps beets-flask` rc 0; after 45 s running, restarts 0, 0 error/traceback/exception log lines; watchdog registered 02-review + 03-asis. Mounts: /mnt/tank/media/Music -> /media/Music rw=true, /mnt/tank/media -> /media rw=false. Edge https://beets.deercrest.info 302 -> auth.deercrest.info (Authelia); internal :5001 / 200, /api_v1/library/stats albums 9 items 197; inbox tree 02-review 9 children, 03-asis 0. DB/state hashes unchanged after restart."

### 2. Jellyfin — the nine pilot albums are present with new metadata
expected: In https://jellyfin.deercrest.info Music, all nine are present with MusicBrainz titles and covers. Benson Boone has American Heart, American Heart [093624834588] and Fireworks & Rollerblades. CYRIL has Stumblin' In (LUNAX remix) (extended mix). Various Artists has NOW That's What I Call Music! 121, Now That's What I Call Music! 117 and Now That's What I Call Music! 116. Under DJ are Mastermix/Issue 420 and Various Artists/Mastermix Issue 421.
result: issue
reported: "both pass, but cover art is wrong on 117"
severity: major
evidence: "Test 2 screenshot: eight albums correct with covers. The ninth, Now That's What I Call Music! 117 (P10), IS in the grid (row 2, first tile), but it shows the cover of 'NOW That's What I Call Disney 3' (Various Artists), so the earlier 'not visible' note was wrong. Test 4 screenshot confirms the album page: title 'Now That's What I Call Music! 117', Various Artists, 50 tracks, 2024, MusicBrainz IDs present, Disney +3 artwork. Reclassified from pass to issue at test 4 (operator reported it there)."

### 3. Jellyfin — the compilation is one album under Various Artists
expected: NOW That's What I Call Music! 121 is one album with 44 tracks and album artist Various Artists. Its ~39 performers do not appear as separate one-track albums.
result: pass
evidence: "Operator screenshot: NOW That's What I Call Music! 121 is one album with album artist Various Artists, 44 tracks, 2h 24m, 2025, genre Pop, and MusicBrainz Album/Album Artist/Release Group IDs. Track artists are per track (Calvin Harris, Clementine Douglas; Sabrina Carpenter; Ed Sheeran; …). The test 2 Albums grid shows no one-track performer albums from it."

### 4. Jellyfin — the multi-disc release keeps its disc numbering
expected: Now That's What I Call Music! 117 is ONE album with 50 tracks, split into Disc 1 (tracks 1–24) and Disc 2 (tracks 1–26). NOW 116 likewise shows Disc 1 (23) and Disc 2 (24).
result: pass
evidence: "Operator screenshots: Now 117 is one album, Various Artists, 50 tracks, 2h 36m, 2024, with a 'Disc 1' section (1 Stick Season … ). Now 116 is one album, Various Artists, 47 tracks, 2h 29m, 2023, with a 'Disc 1' section. Operator confirmed 'both pass' for disc structure. The 117 cover-art defect is recorded against test 2."

### 5. Music Assistant — the same nine, under the correct album artist
expected: In Music Assistant the nine albums appear. NOW 121, 117 and 116 are each a single compilation under Various Artists, and 117 and 116 show discs 1 and 2. Benson Boone has both American Heart albums, which share the same ten tracks (a recorded twin representation, DEF-07-12-05). CYRIL shows as a single. Mastermix Issue 420 and 421 show with type "unknown". No pilot track appears twice.
result: issue
reported: "benson boon is in twice (was also on jellygin, but the cover art is wrong here) and 117 cover art is ok"
severity: major
evidence: "Operator screenshot of MA Albums: Mastermix Issue 421 (Various Artists), Issue 420 (Mastermix), NOW 121 and NOW 116 (Various Artists), Stumblin' In - LUNAX remix e… (CYRIL), Fireworks & Rollerblades, American Heart ×2 (Benson Boone), Now 117 (Various Artists, correct 117 cover). One American Heart tile (row 1, col 4) shows the NOW 121 cover, and the other shows the correct Benson Boone art. The duplicate American Heart is the P02/P04 %aunique twin, which was expected by design (07-SAMPLE P04 'after P02, deliberately'; DEF-07-12-05, MA twin sharing the same ten tracks), but the operator flags it as unwanted in both consumers. Compilation/single/DJ items appear as expected; disc counts and MA types were not visible in this view."

### 6. Playback — a pilot track plays in both consumers
expected: A track from any pilot album (for example American Heart, or a Disc 2 track of NOW 117) plays to the end in Jellyfin and plays through Music Assistant on a real speaker, with the correct title and artist shown.
result: pass

### 7. DJ releases routed to DJ/ with their tags untouched
expected: Mastermix Issue 420 and 421 live under /media/Music/DJ/… and not under Various Artists or Compilations. Their file tags (BPM, key and so on) match the source, because the import was as-is and byte-identical, and "dj" is recorded only in the beets DB.
result: pass
evidence: "Run by Claude at operator's request, read-only. atlantis (id -u 0): /mnt/tank/media/Music/DJ holds exactly Mastermix/Issue 420 and Various Artists/Mastermix Issue 421, and no *mastermix* entry exists outside DJ/. Audio sha256 against the dj-mixes source: Issue 420 src 10 / dst 10 / common 10 / only-dst 0, and Issue 421 the same. So the files are byte-identical and tags untouched, meaning no 'dj' is on any file. Entries under DJ/ not 568:568: 0. beets library.db (mode=ro): album 10 'Issue 420' and album 11 'Mastermix Issue 421' have albumtype 'dj' and mb_albumid '' (as-is), with 10/10 items each under relative path DJ/…. All other albums are 'album' or 'single'."

### 8. Held albums are absent from the library, and every source still exists
expected: The Essential Michael Jackson (P01), Mastermix 90s 12inch USB Top Up (P09) and Mastermix Issue 415 (P11) are NOT in Jellyfin or Music Assistant. All twelve source folders are still in /mnt/tank/downloads/complete/nzb/{music,unsorted,dj-mixes}, so the run copied rather than moved (measured 347/347 files byte-identical).
result: pass
evidence: "Source half run by Claude, read-only, on atlantis: all 12 source folders PRESENT with file counts 32/10/15/10/44/1/11/11/100/52/11/50 = 347, matching the 07-07 manifest. No Essential Michael Jackson / Issue 415 / USB Top Up / 90s 12 entry in /mnt/tank/media/Music (maxdepth 3). Consumer half confirmed by the operator: no local copy of the three held albums in Jellyfin or MA."

### 9. Operator accepts 9 landed of 12 drawn as the pilot outcome
expected: You accept that criterion 1's "twelve albums imported" is met by 9 landed plus 3 held for recorded reasons (P01 incomplete at source, P09 no MusicBrainz candidate passed D-29, P11 a DJ twin held because D-26 was FALSE). The other reading is that the pilot is short and needs more draws first. Both hard shapes landed: the compilation as P05 and P12, and the multi-disc as P10 and P12.
result: pass
evidence: "Operator accepted 9 landed + 3 held (P01, P09, P11) as meeting criterion 1's pilot count."

### 10. Operator accepts how undo was demonstrated
expected: You accept "rollback exercised" (criterion 1) and "undo … with no hand-repair" (criterion 5) as met by: P10 through UNDO IMPORT, then a state.pickle FILE restore from the fence snapshot with beets-flask stopped, then a re-run that reproduced the import byte-equal. There was no zfs rollback of tank/media/Music. The state.pickle step is a documented procedure (beets.md), not an ad-hoc repair, but it is still a manual step outside UNDO IMPORT, which is reservation 5 of your trust verdict.
result: pass
evidence: "Operator accepted the P10 UNDO IMPORT + state.pickle file restore + byte-equal re-run as discharging criterion 1 'rollback exercised' and criterion 5. The manual state.pickle step is carried as a known limitation (trust-verdict reservation 5, DEF-07-11-01/DEF-07-12-06), not as a gap."

### 11. Estate health check is green after the pilot
expected: `scripts/quick-health-check.sh` from the workstation exits 0. That includes check-music-freeze, check-music-consumers and the import sweep (197 items, zero findings). Note that check-music-consumers may still report the known E6/CONF-04 MA discrepancy as its documented exit 3. That is not a Phase 7 regression.
result: pass
evidence: "Run by Claude 2026-09-27T23:22:21Z: overall rc=1, caused solely by the documented CONF-04 consumers-audit exit 3 ('measured, not at target; NOT a failure (FAILURES is 0)'). Every other block ✅: Traefik and Authelia running, 0 unhealthy of 84 running, dashboard 302→Authelia, vendored-file drift match (4), D-03 mount shape (/media/Music RW=true deliberately, confirming the test-1 recreate), D-04, extended.conf disarmed, music freeze intact, import sweep 'No criterion-7 damage', underscore-dir guard, transcode retention, image drift all match."

## Summary

total: 11
passed: 9
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "All nine pilot albums are present in Jellyfin with MusicBrainz titles and correct cover art"
  status: failed
  reason: "User reported: both pass, but cover art is wrong on 117"
  severity: major
  test: 2
  root_cause: ""     # Filled by diagnosis
  artifacts: []      # Filled by diagnosis
  missing: []        # Filled by diagnosis
  debug_session: ""  # Filled by diagnosis
  related: "Same symptom family as the test 5 cover gap: cover art crossing between pilot albums (Jellyfin: 117 shows NOW Disney 3; MA: American Heart shows NOW 121)"
- truth: "Each pilot album shows its own cover art in Music Assistant"
  status: failed
  reason: "User reported: benson boon is in twice (was also on jellygin, but the cover art is wrong here) and 117 cover art is ok"
  severity: major
  test: 5
  root_cause: ""     # Filled by diagnosis
  artifacts: []      # Filled by diagnosis
  missing: []        # Filled by diagnosis
  debug_session: ""  # Filled by diagnosis
  related: "Test 2 gap (Jellyfin 117 wrong cover). In MA, one American Heart album (P02 or P04, twin) shows the NOW 121 (P05) cover"
- truth: "Benson Boone's American Heart appears once per consumer, or the two appearances are an accepted, deliberate twin"
  status: failed
  reason: "User reported: benson boon is in twice (was also on jellygin, but the cover art is wrong here)"
  severity: minor
  test: 5
  root_cause: ""     # Filled by diagnosis. Known context: P02 (FLAC 24-bit, library.db album 2) and P04 (MP3 WEB, album 9, dir 'American Heart [093624834588]') both landed by design to exercise %aunique{} (07-SAMPLE P04 note; DEF-07-12-05 exact MB tie). MA shows both albums sharing the SAME ten tracks (07-15 TWIN REPRESENTATION). The decision is keep-both vs dedupe (DUPE-01/02 work)
  artifacts: []
  missing: []
  debug_session: ""
