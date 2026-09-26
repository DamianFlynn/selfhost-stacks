# Phase 07 — deferred items

Findings filed by Phase 7 plans that are not fixed in the plan that found them. Append-only;
each line names the plan that filed it.

DEF-07-10-01: P10 album-artist directory — oracle Various/ (as-is tag), MB VA match predicts Various Artists/ (va_name); MATCH-CHANGED-TAG class, predicted before import; 07-EXPECTED-TREE.txt not edited (D-07)
  Filed by 07-10 run 6 Task 1 Step 3(c), before staging. Source: beetsplug/musicbrainz.py:687-695
  (beets 2.12.0) sets the album artist to `va_name` for a release credited to Various Artists;
  the oracle was rendered from the as-is tag `Various`. Whether it materialises depends on the
  candidate the operator confirms; plan 07-10 Task 3's oracle diff records the outcome.
  Refined at 07-10 run 6 Step 5 (preview read, before import): rank 1 b057dee8… is va=true, so the
  prediction holds for it, and its album text is "Now That’s What I Call Music! 117" (Title-case
  `Now`, U+2019) against the oracle's "NOW That's …" — the directory diverges on both components.
  OUTCOME (07-10 run 6 Task 3, 19:4xZ): MATERIALISED exactly as predicted. Operator confirmed
  rank 1 b057dee8…, and all 50 files landed under /media/Music/Various Artists/Now That’s What I
  Call Music! 117/ against the oracle's Various/NOW That's What I Call Music! 117/. Jellyfin reads
  AlbumArtist "Various Artists". MATCH-CHANGED-TAG; oracle not edited.

DEF-07-10-02: P10 file names — 13 of 50 APPENDED oracle names differ beyond the directory because MusicBrainz titles replaced the file's own TITLE tag (title case, U+2019 apostrophes, "CYRIL remix", and 01-24 "Bextor - Murder On The Dancefloor" -> "Murder on the Dancefloor", which corrects a wrongly split source tag); MATCH-CHANGED-TAG class; DD-TT prefixes agree 50/50, TEMPLATE-DEFECT 0; 07-EXPECTED-TREE.txt not edited (D-07)
  Filed by 07-10 run 6 Task 3. The full before -> after list is in artifacts/07-10-p01-import.txt § Task 3.

DEF-07-10-03: check-music-import.sh class 1 is blind on a real beets 2.12 library — item paths are stored RELATIVE to `directory: /media/Music`, and the dumper passes them unjoined to os.scandir(os.path.dirname(p)) and its sibling check, so criterion 7 exits 3 (UNKNOWN) on P10 with "directory could not be enumerated for class 1"; classes 2 and 3 read clean (findings 0)
  Filed by 07-10 run 6 Task 3. Instrument defect (scripts/check-music-import.sh, e8d24c2), not a
  library defect. The self-test fixtures used absolute paths, so it never exercised this. Not fixed in
  07-10 (outside its files; a fix needs a deploy to /mnt/fast/stacks). The likely fix is to join
  relative paths with the effective `directory` (or read beets' own absolute-path API) and add a
  relative-path fixture to --self-test. Every later criterion-7 reading (07-11 re-run, 07-12, 07-13)
  stays UNKNOWN until it is fixed. For 07-11's gate.
  RESOLVED 2026-09-26 (operator-approved quick fix between 07-10 and 07-11, "Fix first"): commit
  245dfa7 — the dumper joins each relative item path to beets' `directory`, read through beets' own
  config loader in the container (absolute paths unchanged; unreadable/non-absolute directory with a
  relative path present -> dumper exit 5, run UNKNOWN; the judge also refuses non-absolute paths).
  --self-test cases 11-13 (relative paths through the real dumper) went RED on the unfixed dumper and
  GREEN 13/13 after, on the workstation and on LXC 100. Deployed to /mnt/fast/stacks at 245dfa7, sha256
  f75c577f… = repo. Live criterion 7 on P10, 2026-09-26T20:05:06Z: EXIT 0, class1=50 class2=50
  class3=2 checkable rows, FINDINGS 0, UNKNOWN 0; library.db sha256 unchanged. Details:
  artifacts/07-10-p01-import.txt § DEF-07-10-03 FIX.

DEF-07-11-05: Jellyfin writes `.nfo` into the Music library on NEW-ITEM creation, despite the Music freeze — 07-10's targeted `POST /Library/Media/Updated` created `Various Artists/artist.nfo` (born 2026-09-26T19:51:43Z) and `Various Artists/Now That’s What I Call Music! 117/album.nfo` (born 19:52:05Z), both owner 100000:100000 (container root through LXC 100's idmap), mode 777
  Filed by 07-11 run 1 Task 1 (RESUME RECONCILIATION -> INCONSISTENT, 51 files vs the token's 50;
  STOP STATE 07-11-RECONCILE-FAIL). Jellyfin Music library options read-only 20:08:10Z:
  SaveLocalMetadata=false, EnableRealtimeMonitor=false, but MetadataSavers=["Nfo"] — the Nfo saver is
  not gated by SaveLocalMetadata. CLAUDE.md § Constraints "Jellyfin side effects" says the freeze
  gates the automatic save path and that an explicit FullRefresh still writes; this is a third path
  (targeted update of new files), not covered by that sentence. 07-10's 19:47:42Z entry/owner read
  preceded the write, so its criterion-3 PASS was true when taken. Consequences: (a) the TREE paired
  witness for UNDO IMPORT cannot read `post 0` if the undo leaves these non-beets files, and removing
  them by hand is criterion 5's forbidden hand-repair; (b) 2 files not 568:568 = an unresolved q2
  (criterion 3 owner) count; (c) the same step runs for every album still to land in 07-12/07-13.
  Not fixed: operator decides out of band (e.g. whether to clear MetadataSavers for Music before any
  further targeted update, how the undo witness counts non-beets files, and what happens to these two).
  RESOLVED 2026-09-26 (operator-approved pre-undo cleanup between 07-11 run 1 and its re-entry, "Fix saver
  + remove 2 files"; NOT part of UNDO IMPORT): (a) Music library MetadataSavers ["Nfo"] -> [] by one
  POST /Library/VirtualFolders/LibraryOptions at 20:16:27Z (HTTP 204), body = the GET's LibraryOptions
  with only that key changed; AFTER read shows Music differs only in MetadataSavers and Shows, Movies,
  Collections and TV Recordings LibraryOptions sha256 unchanged; no scan triggered. (b) The two sidecars
  deleted from atlantis as real root at 20:17:16Z behind a two-layer fence, forensic copies kept under
  /mnt/fast/safety/phase07/def-07-11-05/deleted-sidecars/ (artist.nfo 5ed045f8…, album.nfo e65682e1…).
  After: P10 dir 50 files, all .flac, all 568:568; `Various Artists/` holds only the album dir; library
  entries not 568: 0; library.db a9e7036f… / state.pickle 224fe279… unchanged, items 50. The ledger's
  STOP STATE 07-11-RECONCILE-FAIL stands; 07-11 re-enters from Task 1. Details:
  artifacts/07-11-p10-undo-rerun.txt § DEF-07-11-05 REMEDIATION.

DEF-07-11-06: No check asserts the Jellyfin Music library's `MetadataSavers` is empty, so DEF-07-11-05 can regress invisibly
  Filed 2026-09-26 with the DEF-07-11-05 remediation. scripts/check-music-freeze.sh reads no Jellyfin
  library option at all; the only reader is scripts/check-music-consumers.sh (folded into
  quick-health-check.sh), whose option table (~line 422) asserts SaveLocalMetadata == false and
  EnableRealtimeMonitor == false only — nothing in scripts/ reads MetadataSavers, the setting that
  actually wrote the two .nfo. If "Nfo" returns (UI edit, library re-creation, a Jellyfin
  upgrade resetting defaults), the next targeted update writes into Music again with every check green.
  Proposed follow-up, NOT implemented: add a `MetadataSavers` row to that table asserting Music
  `LibraryOptions.MetadataSavers == []` (fail closed
  on an unreadable response, CONVENTIONS §1), and assert no library entry is owned by anything but
  568:568. Out of scope for the operator-approved remediation.

DEF-07-11-01: `UNDO IMPORT` does not cover `state.pickle`; D-14's claim is falsified for the incremental state
  Filed by 07-11 run 2 Task 2 (UNDO WITNESS, 2026-09-26T20:27Z). After the operator pressed UNDO IMPORT on
  beets-flask session 788f3bba (DELETION_COMPLETED 20:25:05Z): TREE COVERED yes (pre 50 → post 0; live tree
  cmp-IDENTICAL to @pre-07-pilot), DB COVERED yes (pre 50 → post 0), STATE COVERED no (pre 1 → post 1).
  /config/state.pickle sha256 224fe279… before and after (mtime = the import's 19:44:28Z write); the decoded
  taghistory entry (b'/downloads/complete/nzb/_inbox/02-review/VA.Now.That.s.What.I.Call.Music_.117.2024..CD.FLAC..CDNOW117',)
  survives. Source reading (not measured): beets-flask's undo deletes items by gui_import_id and never touches
  beets' ImportState, so a fresh read of the same folder under `incremental: yes` is expected to be skipped
  silently, while a re-import of the same beets-flask session reuses its stored tasks and is expected not to be.
  `stacks/selfhosted/arrs/beets.md`'s recovery-fence text should say UNDO IMPORT covers tree + library only.
  Remedy options at 07-11's Task 2 gate: hold / restore-then-rerun (file copy from the arrs snapshot) / rerun.
  D-17 NOT FIRED for 07-11 run 2.
  Update 2026-09-26T21:05Z (07-11 run 2 Task 3): the operator chose restore-then-rerun. With beets-flask stopped,
  state.pickle was FILE-copied from fast/appdata/arrs@pre-07-pilot (224fe279… -> f6a9a1ad… = fence; taghistory
  entry ABSENT after restart); the operator then re-imported through session 788f3bba (candidate 073c7ff8 /
  b057dee8…, rank 1). Result: EQUALITY VERDICT: PASS (paths, audio_md5, diff output and mb_albumid identical to
  run 1; state.pickle byte-identical to run 1's post-import 224fe279…) and QUALITY: PASS. Operator lesson: a
  complete undo in beets-flask is UNDO IMPORT **plus** the state.pickle file restore — UNDO IMPORT alone does not
  revert the incremental state. Still OPEN for plan 07-17 to write into stacks/selfhosted/arrs/beets.md. Not
  measured: whether a same-session re-import goes through without the restore.

DEF-07-12-01: P06 (S7, the singleton folder) cannot take its FROZEN singleton route through the D-20 front end — beets-flask 02-review imports albums only
  Filed by 07-12 run 1 Task 1 (2026-09-26T21:2xZ, before any import). The preview built an ALBUM task for the
  one-file folder; beets-flask does not implement singletons (source, read-only, beets_flask 2.x in the container:
  importer/session.py:212 "Importing singletons is not supported yet.", :445-447 NotImplementedError,
  importer/stages.py:484 TODO, disk.py:43). The FROZEN oracle row
  `/media/Music/Singles/Cyril/Stumblin' In (LUNAX Remix) (Extended Mix).mp3` assumed `beet import -s` and the
  `singleton:` path rule, so it cannot be met by any 02-review import; an album import of rank 1 39fb4603… is
  predicted at `/media/Music/CYRIL/Stumblin’ In (LUNAX remix) (extended mix)/01 Stumblin’ In (LUNAX remix) (extended mix).mp3`.
  Route divergence, not a template defect; 07-EXPECTED-TREE.txt not edited (D-07). Consequence for Phase 9: the
  config's `singleton:` rule is unreachable from the chosen front end; singles need a decision (album-of-one,
  or a CLI arm). Outcome recorded by 07-12 Task 3 if P06 is imported.

DEF-07-12-02: P01's re-stage produced a DIFFERENT MusicBrainz candidate set from identical files — 07-10's pre-named exception candidate f890ca09… is absent
  Filed by 07-12 run 1 Task 1 (preview 2026-09-26T21:18:50Z). Staged sha256 set == the 07-07 manifest (32) in both
  07-10 run 5 (16:03Z) and here; config unchanged (search_limit 5). Run 5's top five: f890ca09 (US CD E2K 94287,
  0.1207), 60fa00b3 (CA), b8a2b280 (FR Qobuz), 4b7a5129, f5ef2123. Now: 61f964df (US digital, no label/barcode,
  0.1014), 4b7a5129, acc1a8e4, a1f33a31, f5ef2123 — three of five replaced, including the rank 1 named at
  07-10's gate. Not measured: why (MusicBrainz search ranking/data changes, or beets' extra_tags query). Effect:
  a D-29 decision is tied to a preview, not to a folder — a re-preview can change the candidate a prior gate
  named; any re-run (D-17/07-16) that expects the same rank 1 must re-read the preview, not assume it. The
  new preview's beets-flask folder hash (8569f3f4…) differs from the dangling row's (d2772a06…), so both rows
  now share one path in beets-flask's DB (not edited).

DEF-07-12-03: The beets-flask inbox page puts every staged folder's hash+path into ONE GET query string — it hit Authelia's 4096 B read buffer (HTTP 431) at 10 folders, and grows with the inbox
  Filed by 07-12 run 1 (2026-09-26). Measured by the orchestrator: the inbox loader GETs /api_v1/session/minimal
  and /api_v1/session/status with repeated folder_hash/folder_path params for every folder; Traefik forward-auth
  hands the whole URI to Authelia; `server.buffers.read: 4096` → fasthttp "small read buffer" → 431 (traefik
  access.log 21:49:57–58Z). Operator-approved fix applied 21:54:22Z: /mnt/fast/appdata/traefik/authelia/configuration.yml
  `server.buffers` read/write 4096 → 16384 (backup configuration.yml.bak-20260926-431, sha256 10b08744…; live
  cee7cb9e…; validate-config rc 0; healthy; 0 buffer errors since). NOT IN GIT: the Authelia config lives in
  appdata, so the change is invisible to the repo and would be lost by a rebuild from the repo. It is also
  estate-wide (see project memory "431 on any *.deercrest.info = Authelia's read buffer").
  Open: (1) Phase 9's bulk inbox (144 folders, long paths) scales the same URL roughly 14× beyond the 10 folders
  that broke 4096 B, so 16384 B is expected to be exceeded. Measure bytes per folder and decide: a larger buffer,
  bypass forward-auth for /api_v1 on the beets host, or batch the inbox in chunks. (2) Record the buffer value
  in the repo (DEPLOYMENT.md / the traefik stack docs) so the drift is visible.

DEF-07-12-04: P01 and P09 were imported against the operator's `hold` — the beets-flask UI has no hold state, so a staged folder is one click from import
  Filed by 07-12 run 1 (2026-09-26T22:40Z). Measured (worker log + beets-flask DB + frontend source, read-only):
  each import was its own per-folder job from the folder page (`candidate_ids={task: cand}`, not an "import
  best" batch). P01's request carried the page's DEFAULT (rank 1 61f964df), so pressing import on its page with
  nothing changed imported it despite D-29 NONE PASSES. P09's request carried `asis-f11a22ac…`, which is not the
  default, so the as-is card was selected. Both were undone at the operator's instruction ("Undo P01 + P09, keep
  rest") with UNDO IMPORT (tree and DB) and then a state.pickle surgery (state), because UNDO IMPORT does not
  revert state (DEF-07-11-01). The D-29 exception gate and the `hold` disposition exist only in the plan and the
  artifact; the front end does not enforce them, and a held album left staged in 02-review stays importable.
  Consequence for Phase 9 and the pilot's remaining plans: unstage held folders promptly (move them out of
  02-review) rather than leaving them beside importable ones. Alternatively, stage one album at a time into
  02-review, so the inbox never shows a held folder next to an importable one. Undo cost measured here: two
  UNDO IMPORTs plus a stop/replace/start of state.pickle.

DEF-07-12-05: P02 landed on c0df8104 (rank 2), not the agreed rank 1 e4fdb1dc, and P04's request carried e4fdb1dc, not the agreed c33163f3 — the UI shows an exact three-way tie as near-identical cards
  Filed by 07-12 run 1 (2026-09-26T22:40Z). Measured: ranks 1–3 tie to full float precision on both Benson Boone
  folders (P02 0.25/27.5; P04 0.5067567567567568/29.0). The frontend's stable distance sort keeps API (row) order
  e4fdb1dc, c0df8104, c33163f3, so the default is e4fdb1dc on both. P02's request carried c0df8104 (card 2: CD,
  no catalognum), a non-default card. P04's carried the default e4fdb1dc, not the agreed card 3. The agreed
  candidate reached the request on 4 of 6 albums (P03, P05, P06, P12). The operator KEPT P02 on c0df8104
  (verbatim "Undo P01 + P09, keep rest"). c0df8104 passes D-29 identically to e4fdb1dc, but its empty
  catalognum changes the %aunique{} outcome for P04 (measured in 07-12 § E). Proposed, not implemented: the gate
  table names candidates by the fields the UI displays (media, catno, country) as well as by MBID, and every
  landing is checked against the agreed MBID before the next folder is imported.

DEF-07-12-06: New procedure — PARTIAL state.pickle surgery (remove named taghistory entries), for when a full undo must keep other albums' incremental state
  Filed by 07-12 run 1 (2026-09-26T22:37Z) with DEF-07-11-01, for plan 07-17 / stacks/selfhosted/arrs/beets.md.
  07-11's restore (file-copy the fence state.pickle) is only correct when NO other album has landed since the
  fence. Here six had, so copying the fence back would have erased their taghistory. Procedure used (07-12 § C):
  decode /tmp copies; assert live == fence ∪ keep ∪ remove exactly; build {tagprogress, taghistory − remove} with
  pickle.dump (protocol 4, beets' own writer, beets/importer/state.py:100-110); prove new == fence ∪ keep; stop
  beets-flask; `cp -p` a backup; `cp` the new file onto the live one (owner/mode/inode preserved); start; keys
  check; re-decode. The procedure was authorised by the operator's verbatim statement recorded in § C. Not
  measured: behaviour if tagprogress is non-empty (it was {} throughout); the procedure asserts {} and stops
  otherwise.

DEF-07-12-07: A DuplicateException in beets-flask cannot be cleared by a plain retry — the duplicate toggle keys off duplicate_ids computed at PREVIEW time; the folder page's candidate SEARCH is the retry route
  Filed by 07-12 run 1 (2026-09-26T23:20Z), for plan 07-17 / stacks/selfhosted/arrs/beets.md (operator-facing).
  P04's first import (22:00:12Z) failed with DuplicateException (import.duplicate_action: ask) because P02 landed
  after P04's preview, so every P04 candidate still carried duplicate_ids '' and the UI hid the duplicate-action
  toggle; the request carried duplicate_actions={}. The candidate search (AddCandidatesSession, 23:09:41Z)
  recomputed duplicate_ids on five of six candidates (the original c33163f3 card was left ''), ADDED the searched
  release as a second card for the same release, and showed the toggle; the import at 23:11:42Z carried
  duplicate_actions {task: 'keep'} and landed P04 beside P02 without touching P02. The frontend stores the action
  per TASK and sends it with whatever card is selected. Lesson: after any import lands, re-search (or re-preview)
  every still-staged folder that could be its duplicate before importing it; only "Keep both" is safe ("Remove
  old items" deletes the landed album, "Merge" folds it). Not measured: whether a full inbox re-preview does the same.

DEF-07-12-08: P03 landed beside a PRE-EXISTING, untracked copy of the same album — `Benson Boone/Fireworks & Rollerblades (2024)/` (in @pre-07-pilot, not in library.db)
  Filed by 07-12 run 1 (2026-09-26T23:20Z), for the Phase 8/9 duplicate reconciliation (and 07-15's MA/Jellyfin
  count reading). The 34 GB library pre-dates beets' library.db, so beets' duplicate check cannot see it: P03's
  `Fireworks & Rollerblades/` (15 FLAC, MB ef528afc) now sits next to the 2024 copy (15 FLAC + 15 lyrics +
  album.nfo + folder.jpg), which this plan did not touch (live == snapshot by name/size/mtime/owner). Jellyfin and
  MA will see two albums with the same name. Any pilot album whose artist already exists in the library can do the
  same; 07-15 should expect it when reading MA/Jellyfin counts.

DEF-07-12-09: diff-music-tags.sh's join key (`audio_md5` = ffmpeg `-c copy` md5 of the ENCODED stream) is NOT tag-invariant for an MP3 whose last frame is truncated and which carries ID3v1 — P04 track 01 reads MISSING_AFTER 1 / NEW_AFTER 1 although nothing was lost
  Filed by 07-12 Task 3 (2026-09-26T23:22Z), instrument defect for the scripts owner (Phase 8/9 relies on this diff
  at volume). Measured: source vs landed copy, same size; the MPEG frame region between ID3v2 and ID3v1 is
  byte-identical; the 1,346 differing bytes are 1,344 in ID3v2 and 2 in ID3v1; decoded PCM md5 equal (598bce1e…);
  ffmpeg reports "Header missing" at the end of both, so the copy demuxer's final packet runs into the ID3v1 bytes
  beets rewrote. Hand pairing: 0 fields dropped. Candidate fixes (not applied): hash the frame region with ID3v1
  stripped, or fall back to a PCM md5 when the copy md5 changes but the PCM md5 and the path pairing agree. Until
  fixed, any MISSING_AFTER on MP3 needs the same byte check before it is read as loss.

DEF-07-12-10: A match whose MusicBrainz release has an EMPTY field keeps the file's junk value — P03 album/file country 'PMEDIA'
  Filed by 07-12 Task 3 (2026-09-26T23:20Z), for Phase 9 tag hygiene. P03's release group tag 'PMEDIA' sat in
  COMPILATION, PUBLISHER and RELEASECOUNTRY. The match overwrote COMPILATION (0) and PUBLISHER (Night Street Records),
  but MB release ef528afc has no country, so RELEASECOUNTRY stayed 'PMEDIA' in the file and in library.db
  (albums.country). Not a loss and not a criterion 3/4 failure. It is a wrong value surviving a match, and a `zero`
  rule or an overwrite-null policy would catch it.

DEF-07-12-11: Jellyfin's targeted file-scope `Created` update does NOT materialise an album under a NEW top-level artist directory — P06 (`CYRIL/…`) is absent from Jellyfin
  Filed by 07-12 Task 3 (2026-09-26T23:28Z), for plan 07-15 (Jellyfin/MA reading) and the Phase 9 pipeline design.
  One POST of 127 paths (204). Five albums under existing artist folders (`Benson Boone/`, `Various Artists/`)
  appeared within ~90 s. P06's single file under the new `CYRIL/` did not: Jellyfin logged `Music (/media/Music) will
  be refreshed`, and that refresh did not add the child folder. The library root has 14 children against 15 artist
  dirs on disk, `SearchTerm=Stumblin` finds 0, and no MusicArtist Cyril exists, still at 23:28:48Z. With realtime
  monitoring off for Music (by design, DEF-07-11-05), every new-artist import will stay invisible to Jellyfin until
  something else refreshes the root's children. Not remedied (the plan allows ONE targeted POST). Options for the
  operator: a targeted update naming the new directory itself, or a Music-library-only scan. The scan would need
  its own no-sidecar check, because MetadataSavers is [] but a FullRefresh-class call is still banned.

DEF-07-12-12: ADDED ORDER FAIL — P04 landed last (23:11Z) and P06 before P05, against the declared P02, P03, P04, P05, P06, P09, P12
  Filed by 07-12 Task 3 (2026-09-26T23:30Z). Cause: P04's first import failed (DuplicateException, DEF-07-12-07) and
  was re-decided after the others. P06 before P05 was the operator's click order. The %aunique{} premise (P02 before
  P04) is MET, and the albums between them share no (albumartist, album) with either, so the firing is unaffected.
