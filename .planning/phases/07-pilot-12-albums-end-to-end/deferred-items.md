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
