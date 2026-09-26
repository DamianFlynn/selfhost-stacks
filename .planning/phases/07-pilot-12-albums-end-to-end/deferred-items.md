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
