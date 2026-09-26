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
