---
status: resolved
phase: 07-pilot-12-albums-end-to-end
source: [07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md, 07-04-SUMMARY.md, 07-05-SUMMARY.md, 07-06-SUMMARY.md, 07-07-SUMMARY.md, 07-08-SUMMARY.md, 07-09-SUMMARY.md, 07-10-SUMMARY.md, 07-11-SUMMARY.md, 07-12-SUMMARY.md, 07-13-SUMMARY.md, 07-14-SUMMARY.md, 07-15-SUMMARY.md, 07-16-SUMMARY.md, 07-17-SUMMARY.md]
started: 2026-09-27T21:48:57Z
updated: 2026-09-28T14:41:02Z
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

## Operator Decisions (gap-closure scope)

Asked 2026-09-28T07:45:22Z after diagnosis, and answered verbatim by option label:
- Twin policy: "Back out the MP3 (P04)". Keep the P02 FLAC. UNDO IMPORT of P04, stop beets-flask, partial state.pickle surgery removing only P04's taghistory entry (beets.md procedure, DEF-07-12-06), then an MA sync and a Jellyfin scan. The operator authorised these estate writes by choosing this option.
- Round scope: "Pipeline + pilot repair (Recommended)". beets fetchart (Cover Art Archive → cover.jpg, embedart stays OFF) + match.preferred.media, art backfill for P10 (P04 is moot if backed out), a single-item replacement of Jellyfin's stored 117 Primary image, an MA refresh of albums 167 (and 169 if it still exists), and Apple Music demoted/disabled for MusicAlbum. The operator authorised these library and consumer writes by choosing this option.
HARD EXCLUSIONS for the planner: no zfs rollback of any dataset; no Jellyfin FullRefresh or library-wide metadata refresh (image-only, single item); no `beet write`/`beet update`/embedart over the library (DJ/ tags are DB-only, DEF-07-13-01); no re-match of P02 in this round (its CD match is recorded, and preferred.media applies to future imports); no new pilot draws.

## Gap Round 2026-09-28

Plans 07-18..07-23 ran the gap-closure round the operator scoped above (OD-1 and OD-2). 07-23 re-measured the
end state read-only (`artifacts/07-23-end-state.txt`) and measured all three gaps closed. The operator then looked
at both consumers and answered at 07-23's gate. Both answers were given through AskUserQuestion and are recorded
verbatim (2026-09-28T14:39:32Z, the time recorded in 07-23-end-state.txt):
- View ("do both show the correct covers and exactly one American Heart?"): "accept"
- Count ("'8 landed + P04 backed out (OD-1) + 3 held' — does that still meet the pilot count?"): "reconfirm (Recommended)"

Normalised: `DISPOSITION VIEW: accept`, `DISPOSITION COUNT: reconfirm`. Criterion 1's pilot count, accepted at test 9
as "9 landed + 3 held", is re-confirmed by the operator as 8 landed (P10 P02 P03 P05 P06 P12 P07 P08), P04 backed out
by the operator's own OD-1, and 3 held (P01 P09 P11). The Tests section above is left as the historical record. This
file scores nothing: `/gsd-verify 07` scores the phase, once, after this round.

## Gaps

- truth: "All nine pilot albums are present in Jellyfin with MusicBrainz titles and correct cover art"
  status: closed
  reason: "User reported: both pass, but cover art is wrong on 117"
  severity: major
  test: 2
  root_cause: "P10 (NOW 117) carries NO art: 0/50 embedded pictures, no sidecar, and none at source either. beets runs plugins [musicbrainz] only, no fetchart, embedart.auto no, and albums.artpath is NULL for all nine. So Jellyfin's MusicAlbum ImageFetcherOrder [Apple Music, Fanart, TheAudioDB] fell back to an Apple Music NAME search in the default US storefront, which lacks the UK-only NOW 1xx series. Its top hit is 'NOW That's What I Call Disney 3' (id 1440812619). The stored folder.jpg (sha256 09d8b5f8c9dd…) is byte-identical to Apple's Disney 3 artwork. The log at 20:51:47+01:00 shows 'Apple Music album ID is not available, using search'. Cover Art Archive has the correct 117 image (b057dee8), and MA uses it."
  artifacts:
    - path: "/mnt/fast/appdata/arrs/beets/config/config.yaml (+ repo copy stacks/selfhosted/arrs/beets/)"
      issue: "No art plugin: an album without art at source lands with none"
    - path: "Jellyfin Music library options — MusicAlbum ImageFetcherOrder; /config/plugins/Apple Music_3.0.6.2 (no config, US store)"
      issue: "Apple Music name-search is first in order and guesses wrong for UK compilations"
    - path: "Jellyfin /config/metadata/library/d1/d18d5c99c4451068e6b3d6999cd48a3d/folder.jpg"
      issue: "Stored wrong (Disney 3) primary image. Adding cover.jpg alone will not replace it"
  missing:
    - "Pipeline: every imported album carries its own art (e.g. beets fetchart from Cover Art Archive writing cover.jpg with embedart off to respect no-file-rewrite, or a pre-import gate that holds art-less albums)"
    - "Backfill cover.jpg for P10 (and P04), a write to /mnt/tank/media/Music, needs operator authorisation"
    - "Jellyfin: demote/disable Apple Music for MusicAlbum or set GB storefront"
    - "Jellyfin: replace item d18d5c99…'s Primary image (single-item image replace or DELETE /Items/…/Images/Primary). This is a consumer write needing operator authorisation. Verify MetadataSavers=[] first (Music freeze / .nfo history)"
  debug_session: ".planning/debug/pilot-cover-art-crossover.md"
  closed_by: [07-19, 07-20, 07-21, 07-23]
  closure_evidence: "Closed 2026-09-28. Pipeline: fetchart with Cover Art Archive as its only source, writing cover.jpg with embedart off, plus match.preferred.media, proven in a throwaway (artifacts/07-19-pipeline-config.txt) and deployed with the NOW 117 cover.jpg backfill, sha256 6d83625a… and artpath set on album 1 (artifacts/07-20-deploy-backfill.txt § B, § C). Jellyfin: Apple Music removed from the MusicAlbum ImageFetchers and the NOW 117 Primary replaced image-only (artifacts/07-21-jellyfin.txt § W1, § W3). Re-measured read-only by 07-23: the stored Primary of d18d5c99… is 6d83625a…, equal to P10's cover.jpg and not the Disney 3 artwork 09d8b5f8…; the freeze PASSes; .nfo 91; entries not 568:568 0 (artifacts/07-23-end-state.txt § 3 and the line 'GAP 1 (Jellyfin NOW 117 cover): MEASURED CLOSED'). Operator look at 07-23's gate: DISPOSITION VIEW: accept."
- truth: "Each pilot album shows its own cover art in Music Assistant"
  status: closed
  reason: "User reported: benson boon is in twice (was also on jellygin, but the cover art is wrong here) and 117 cover art is ok"
  severity: major
  test: 5
  root_cause: "P04 (American Heart [093624834588]) has no art of its own (0/10 embedded, no sidecar). 'Sorry I'm Here for Someone Else' is on P02, P04 and NOW 121 (P05) #27 with the same recording MBID 545aa58c… and ISRC USWB12500464, so MA merges them into ONE library track (1541) whose album is NOW 121 (165). Through that track, MA albums 167 and 169 pick up NOW 121's external ids (MB album 0a74adf8, release group b3cb0f03, barcode 00196872951165) and images. P02 still shows correctly only because its own embedded FLAC art ranks first. P04's first image is NOW 121's #27 embedded picture. The P04 file tags carry only their own ids, so the contamination is MA-internal."
  artifacts:
    - path: "MA library albums 167 and 169 (images, external_ids), track 1541"
      issue: "Cross-album id/image bleed through a shared recording"
    - path: "Library dir Benson Boone/American Heart [093624834588]/"
      issue: "No art"
  missing:
    - "Same pipeline fix as the test 2 gap (own art on every album): the durable fix, since the bleed recurs for any art-less album sharing a recording with a compilation"
    - "MA: 'Refresh item' (or remove + re-sync) on albums 169 and 167. A consumer write needing operator authorisation. Album 167 carries the latent NOW 121 MB album id first, even though it displays correctly"
  debug_session: ".planning/debug/pilot-cover-art-crossover.md"
  closed_by: [07-18, 07-19, 07-20, 07-22, 07-23]
  closure_evidence: "Closed 2026-09-28. The art-less P04 album (MA 169) that carried NOW 121's image was backed out (artifacts/07-18-p04-backout.txt), the own-art pipeline was proven and deployed (07-19, 07-20), and one provider-scoped MA fs sync removed 169 and re-created P02 as album 170 with its own first image and its own external ids only (artifacts/07-22-ma.txt § S, § R, § F, § P; DEF-07-22-04). Re-measured read-only by 07-23: 169 is absent; each of the 8 pilot directories is mapped by exactly one MA album; no album's first image is another album's cover. The strict own-SOURCE count is 7/8, because P12 (album 3) leads with Spotify's copy of its own NOW 116 front, which is pre-existing, recorded in 07-22 § P, and named rather than smoothed. P03 (album 168) carries a second MB album id, filed as DEF-07-23-01, an observation and not a cover defect (artifacts/07-23-end-state.txt § 4 and the line 'GAP 2 (MA cover per album): MEASURED CLOSED'). Operator look at 07-23's gate: DISPOSITION VIEW: accept."
- truth: "Benson Boone's American Heart appears once per consumer, or the two appearances are an accepted, deliberate twin"
  status: closed
  reason: "User reported: benson boon is in twice (was also on jellygin, but the cover art is wrong here)"
  severity: minor
  test: 5
  root_cause: "Three stacked causes, no single defect. (a) Designed outcome with an undecided policy: the pair was drawn deliberately (07-CONTEXT D-04), P04 landed via the operator's 'Keep both' (DEF-07-12-07), and no same-album-different-format policy exists (DUPE-01/02 cover folder-name collisions only; live duplicate_action: ask). (c) Both matches are the wrong format: c0df8104 (P02) and c33163f3 (P04) are two MB entries for the SAME US CD (barcode 093624834588, same 10 recordings), while the sources are WEB rips. The correct targets are the XW Digital Media releases b3a1e018 (093624830603) or cfb585a2 (093624834960). This is structural: match.preferred.countries ['GB','US'] with no preferred.media means an XW digital release can never win, so the DEF-07-12-05 tie contained only CD/vinyl. The %aunique suffix [093624834588] is that shared barcode (catalognum '' vs '093624834588') and tells a listener nothing. (b) MA's recording-identity track merge (by design) shows both albums over one set of 10 tracks, with P04's MP3s shadowed by P02's FLAC. Jellyfin holds each album's own files correctly, but the two cannot be told apart. Durations match pair-for-pair to 0.1 ms (24/44.1 FLAC vs 320k MP3, same master)."
  artifacts:
    - path: "/mnt/fast/appdata/arrs/beets/config/config.yaml:381-392"
      issue: "preferred.countries without preferred.media: WEB downloads match physical CD/vinyl releases"
    - path: "library.db albums 2 and 9"
      issue: "Two format-wrong matches of one CD"
    - path: "/mnt/tank/media/Music/Benson Boone/American Heart/ and …/American Heart [093624834588]/"
      issue: "Same audio, two formats, indistinguishable names"
  missing:
    - "OPERATOR DECISION: policy for the same album in two formats. A = back out P04 (UNDO IMPORT + stop + partial state.pickle surgery per beets.md + MA sync + Jellyfin scan, all writes needing authorisation). B = keep both, re-match to Digital Media releases and disambiguate by format. C = defer to the DUPE/archive phase (not yet inserted) with a named policy"
    - "Regardless of decision: add match.preferred.media (e.g. Digital Media) or an equivalent gate, filed for Phase 8/9, or every WEB download keeps matching CD/vinyl"
  debug_session: ".planning/debug/american-heart-twin.md"
  closed_by: [07-18, 07-19, 07-20, 07-21, 07-22, 07-23]
  closure_evidence: "Closed 2026-09-28 by the operator's OD-1 policy A (back out the MP3, keep the P02 FLAC). 07-18 ran UNDO IMPORT of P04 plus the partial state.pickle surgery removing only P04's taghistory entry, under the round fence @pre-07-18 (artifacts/07-18-p04-backout.txt). 07-19 and 07-20 added and deployed match.preferred.media ['Digital Media', 'CD'] for future imports (DEF-07-19-05 records its effect on CD rips). 07-21 dropped the P04 MusicAlbum from Jellyfin, and 07-22's sync dropped MA album 169, with check 4d 1/1. Re-measured read-only by 07-23: tree 0 entries matching *093624834588* and one American Heart directory, P02 manifest equal to 07-18; beets 8 albums / 187 items with album 9, P04's items and P04's state key all absent; Jellyfin one American Heart and e44d9655… count 0; MA one American Heart (170); criterion 8 347/347 (artifacts/07-23-end-state.txt § 1-4 and the line 'GAP 3 (American Heart twin): MEASURED CLOSED'). Operator look at 07-23's gate: DISPOSITION VIEW: accept. P02 keeps its CD match c0df8104…, by the round's hard exclusion (no re-match of P02)."
