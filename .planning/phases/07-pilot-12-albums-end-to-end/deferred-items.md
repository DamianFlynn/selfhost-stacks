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
  PARTLY RESOLVED 2026-09-27 (post-07-12 remediation, operator: P09 -> "Unstage it now (Recommended)"): P09's staged
  reflink copy was removed from 02-review at 11:46:45Z (staged sha set == 07-07 manifest before; source unchanged
  100/100 after; library.db 177 items unchanged). P01 was unstaged by 07-12 Task 3. No held folder is staged now:
  02-review holds only the seven already-imported albums' copies. The UI still has no hold state. That gap stays
  open for Phase 9. Evidence: artifacts/07-12-nine-imports.txt § POST-07-12 REMEDIATION R1.

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
  RESOLVED 2026-09-27, but NOT by the remediation: Jellyfin's own SCHEDULED `Scan Media Library` (12-h interval,
  09:10:34Z–11:33:29Z) added it. MusicArtist CYRIL was created 09:11:06Z and the album 09:11:08Z. At 11:49:43Z
  there was 1 album (AlbumArtist CYRIL, 1 track) and the totals were 77 / 1,421 (+1 / +1). The operator-approved
  targeted POST naming `/media/Music/CYRIL` was therefore NOT issued (precondition failed). No sidecar was written:
  0 entries newer than 23:23Z, .nfo 91, all 568:568, MetadataSavers []. Consequence for Phase 9: a new-artist
  import becomes visible within ≤ 12 h with no action. The stronger point is that Jellyfin scans the WHOLE library
  every 12 h regardless of what the plans issue, so "no library scan" constrains only our own calls. Evidence:
  artifacts/07-12-nine-imports.txt § POST-07-12 REMEDIATION R2.

DEF-07-12-12: ADDED ORDER FAIL — P04 landed last (23:11Z) and P06 before P05, against the declared P02, P03, P04, P05, P06, P09, P12
  Filed by 07-12 Task 3 (2026-09-26T23:30Z). Cause: P04's first import failed (DuplicateException, DEF-07-12-07) and
  was re-decided after the others. P06 before P05 was the operator's click order. The %aunique{} premise (P02 before
  P04) is MET, and the albums between them share no (albumartist, album) with either, so the firing is unaffected.

DEF-07-13-01: route-dj-album.sh's `modify` wrote every tag of every DJ file (import.write: yes) — BPM ranges truncated, keys lower-cased, ID3 2.3 -> 2.4, TBPM 0 / TDRC 0000 added — and still could not put `albumtype=dj` on the file
  Filed 2026-09-27 by 07-13 (Task 1 § PREDICTION, then re-measured through the script itself). Step (c) ran
  `modify -a -M -y id:N albumtype=dj` without `-W`, so beets 2.12.0 inherited import.write and rewrote each file from
  its DB row. On scratch copies of the staged P07/P08/P11 (throwaway -l/-c library, beets-flask's own beets), the old
  script changed 30/30 files: P07 TBPM '116-117' -> '116' on 7/10, P11 TKEY '5A' -> '5a' on 9/9, TBPM '0' and TDRC
  '0000' added on P08/P11, frames +5 to +8 per file. The album-type frame was never written, because mediafile maps
  albumtype and albumtypes onto one frame and the item's empty albumtypes, written second, deletes it. The script's
  own DB read-back printed ✅ over the damaged files. The DJ fields are the operator's working material (D-17), so no
  DJ album could be routed as written. Caught before any real --apply; nothing in the library was touched.
  RESOLVED 2026-09-27 (commit 998625b, deployed to LXC 100 12:19:32Z, sha256 51c52799… = repo): step (c) is
  `modify -a -M -W -y` (DB-only), step (b) refuses without `-W, --nowrite`, and `move` was shown in source to write
  no tag. The fixed script, driven over the same copies, left 30/30 files byte-identical through import -A, modify
  and move, and routed 30/30 under DJ/ with albumtype dj in the DB. 07-13-PLAN.md was amended (641498a): the check
  is now DB-side plus file-bytes-unchanged, and there is no file-tag albumtype. D-04 pins unchanged (exempt 12).
  STILL OPEN as a hazard, not a defect: DJ files carry no `dj`, so a future `beet update` over a routed album un-sets
  it in the DB (`update -p` shows `albumtype: dj -> ''` on 10/10 items), and `beet write` would redo the damage. Phase 9
  must not run either over DJ/. Evidence: artifacts/07-13-dj-pair.txt § 07-13 ROUTE -W FIX (F1–F5).

DEF-07-13-02: A targeted `Created` update that INCLUDES the new top-level folder path materialised both DJ albums under the new `DJ/` — DEF-07-12-11 did not recur
  Filed 2026-09-27 by 07-13 Task 3. OBSERVATION, not a defect. 07-12's P06 POST carried file paths only, and the new
  top-level `CYRIL/` did not appear until Jellyfin's scheduled 12-h scan (DEF-07-12-11). 07-13's one POST (12:41:26Z, HTTP
  204) carried `/media/Music/DJ` itself plus the 20 file paths. Both albums were present 80 s later: MusicAlbum 77 -> 79,
  Audio 1,421 -> 1,441, one album per directory, no sidecar, MetadataSavers still []. One observation on one Jellyfin
  version, not a controlled comparison: the body differed in the folder entry, and nothing else was varied. For 07-15 and
  Phase 9: include the new top-level folder in the targeted body before concluding a scheduled scan is needed. Evidence:
  artifacts/07-13-dj-pair.txt § Criterion 6, Jellyfin half.

DEF-07-13-03: P08 (Mastermix Issue 421) carries no disc tag — two CDs tagged as one, so tracks 1..5 appear twice
  Filed 2026-09-27 by 07-13 Task 3. Source-tag quality, not a pipeline defect. The files' own tags put all ten tracks on
  disc 0 with track numbers 1..5 twice. As-is import keeps that, and routing writes no tag (DEF-07-13-01), so beets holds
  disc 0 and Jellyfin shows one disc indexed 1,1,2,2,…,5,5. The file names still render uniquely, because the titles
  differ, and the FROZEN oracle lines already expect this. Fixing it is tag normalisation (the Phase 9 mutagen script),
  not beets, and not a `beet write` over DJ/ (DEF-07-13-01's open hazard). Evidence: § G2, § Criterion 6.

DEF-07-14-01: Music Assistant reports the track artist "Brian Coll" on 86 Def Leppard tracks across 5 albums, and no file carries that string
  Filed 2026-09-27 by 07-14. This is an MA-side observation, not E5, and not a file defect. The MA read-only API (ma-0714.sh,
  2026-09-27T12:56:02Z, re-read 13:18:42Z unchanged) gives track_artists ["Brian Coll"] with artist item_id "116",
  the same number as the Def Leppard album id 116. It covers 13 of the 14 tracks of Def Leppard (2015), plus Las Vegas
  Residency 18, High ’n’ Dry 10, On Through the Night 10 and Rock of Ages 35. The files carry Artist=Def Leppard, and
  Jellyfin reads Def Leppard. The likely class is an MA join/id collision in its library DB, but that is unmeasured. The E5 repair does not touch it.
  For 07-15: after the MA sync, read it separately from E5, and do not score it as E5 success or failure. If it
  persists, it is a Phase 8 MA item. Evidence: artifacts/07-14-e5-repair.txt § 3 OBSERVATION and § TASK 2.

DEF-07-15-01: Music Assistant artist-entity DISPLAY NAMES drift without their links moving — ARTPOP row 1 now reads `Twista | Lady Gaga | Too $hort` where 06-13 read `T.I. | Lady GaGa | Too $hort`
  Filed 2026-09-27 by 07-15 Task 3. The pinned D-22 row 1 (`Jewels n’ Drugs`, ARTISTS tag of 4) still links the SAME
  three MA entities (159, 209, 217) and so still reads 3 — at its MA baseline — but entity 159, displayed `T.I.` on
  2026-09-21, is now displayed `Twista` (with a Spotify mapping for Twista), and 209 `Lady GaGa` is now `Lady Gaga`.
  `T.I.` now exists nowhere in the provider's artists. The rename predates 07-15's sync (Task 2's 13:29Z pre-read shows
  it). Same class as DEF-07-14-01 (entity 116 displayed "Brian Coll", now `Def Leppard`). Consequences: (1) section 4e's
  runtime text "'Twista' exists nowhere in MA's library artists" is now factually stale; (2) the E6 second measurement's
  discriminator ("a different missing name than Twista") reads a display name that can move on its own, so a future
  reading must record entity ids, not only names. Owner: CONF-04 / E6 (Phase 8 MA work). Evidence:
  artifacts/07-15-consumers.txt § E6 SECOND MEASUREMENT (OBSERVATION).

DEF-07-19-04: A fetchart `cover.jpg` in /media/Music is indistinguishable, by extension, from a Jellyfin-written `.jpg` sidecar
  Filed 2026-09-28 by 07-19 Task 2. OBSERVATION, not a defect. After 07-20 deploys OD-2, every MusicBrainz-matched album
  that Cover Art Archive serves lands with `cover.jpg` (beets `artpath`). `scripts/check-music-freeze.sh` § 5's sidecar
  inventory never asserts, but its `.jpg` count will grow by one per such album. A future SAFE-05 watched-folder diff
  keyed on extension would then read beets' write as a Jellyfin write. Before calling a new `.jpg` a Jellyfin sidecar,
  attribute it: a `cover.jpg` that equals an album's `artpath` is beets'. `check-music-import.sh` is unaffected, because its
  orphan scan skips non-audio. Owner: whoever next runs a SAFE-05 sidecar diff (Phase 8/9). Evidence:
  artifacts/07-19-pipeline-config.txt § ORACLE (other consumers).

DEF-07-19-05: `preferred.media: ['Digital Media', 'CD']` ranks a Digital Media release above a CD for a CD rip too
  Filed 2026-09-28 by 07-19 Task 2. OBSERVATION for 07-20's deploy gate. The staged files carry no `media` tag (likely
  media '' on P02 and P10), so beets cannot tell a CD rip from a WEB rip, and the preference applies to every source. It
  does what OD-2 asked for WEB rips: P02 flips from c0df8104 (CD) to b3a1e018 (Digital Media, an exact tie with cfb585a2).
  It also keeps CD above vinyl. But a CD rip whose MusicBrainz Digital Media edition has the SAME tracklist and medium
  count would now match the digital edition. P10 kept b057dee8 (CD) only because its digital edition 8a4b23b7 differs
  in mediums: the margin was 0.115 under NEW, against 0.121 under CURRENT. Nothing has gone wrong yet. It is a measured
  consequence of the ordering for the operator to accept or refine at 07-20. Evidence:
  artifacts/07-19-pipeline-config.txt § RANKING, readings R1–R5.

DEF-07-20-01: check-beets-config.sh T-06-33 goes red as soon as fetchart loads, from plugin DEFAULTS rather than a credential
  Filed 2026-09-28 by 07-20 Task 2 step B9. It halted the deploy. T-06-33 asserts that `beet config -d` (redacted) is
  byte-identical to `beet config -d -c`. fetchart marks fanarttv_key, google_key, google_engine and lastfm_key
  `.redact = True` whatever their value, so the redacted dump prints REDACTED where the unredacted dump prints null (three
  keys) or beets' shipped google_engine default. The two dumps also list the keys in a different order. The repo
  config.yaml sets none of the four. 07-19 did not catch it because its live pre-deploy run had no fetchart loaded.
  Candidate fix, for the operator to decide: key-scope T-06-33 so it compares the redacted keys' unredacted values
  against the plugin defaults (null, or fetchart's shipped google_engine) and fails only on a non-default value. The
  alternative is to pin the four keys explicitly in config.yaml. A future real key still has to trip it. State at
  filing: new config installed, beets-flask STOPPED, backfill not taken. Evidence:
  artifacts/07-20-deploy-backfill.txt § B9, B9a, B-STOP.
  RESOLVED 2026-09-28 (operator: "Fix check, resume (Recommended)", 12:22:07Z) by commit 58e2d3d. T-06-33 is now
  assert_redaction_noop in scripts/check-beets-config.sh, key-scoped as the candidate fix above proposed. Byte-identical
  dumps still PASS. Otherwise only fetchart's four allowlisted keys may differ, each reading REDACTED with an empty value
  or the installed plugin's default. That default is derived live from beetsplug.fetchart's add_default_config against a
  bare confuse root, not pinned. Every other difference is RED, and unreadable or undiffable input is UNKNOWN. No value is
  printed. Self-test 15 -> 20 cases (RED before, GREEN after, artifact § R3-R4). Live: check-beets-config RC=0 at
  12:29:09Z with "plugin-defaults-only [fanarttv_key=empty google_engine=default google_key=empty lastfm_key=empty]".
  The deploy and the P10 backfill then completed (§ B resumed, § C). A future real key in any of the four still trips it.
