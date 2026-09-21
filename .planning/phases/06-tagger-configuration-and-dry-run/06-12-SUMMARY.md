---
phase: 06-tagger-configuration-and-dry-run
plan: 12
subsystem: testing
tags: [beets, musicbrainz, conf-05, preferred-countries, d-30, oq-4, beets-flask, preview, d-28, negative-control]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-05's committed fixtures — 06-SAMPLE.md's ten drawn rows and 06-EXPECTED-TREE.txt's 174 destination lines"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-11's oracle run — arm 1's measured destination list, which diffed to ZERO lines against the fixture"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-07's verdict that a `-c` overlay wins under rc6, and plan 06-04's D-29 layer-3 baselines"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-06's inbox-liveness route — the api_v1 endpoints, the folder_hash join, and the dangling-state finding this plan relied on"
provides:
  - "CONF-05 discharged by DEMONSTRATION: `match.preferred.countries` shown to change the chosen release, one key apart, with the GB literal proven and `UK` proven silently inert"
  - "OQ-4 RESOLVED: rc6's `preview` produces no destination paths, answered three independent ways; the agreement basis redefined and recorded"
  - "D-30 arm 2 ran, and the two arms AGREE — 15 of 15 tuples, zero lines either side"
  - "An in-band amendment to D-35: two named 02-review transits this phase, not one"
  - "A dated correction to the vendored config's own explanation of why `['GB','US']` is set"
affects: [06-13, 06-14, 07, 09]

tech-stack:
  added: []
  patterns:
    - "A zero-valued penalty is DROPPED by Distance.items(), so the predicate for a working preference is the ABSENCE of its term, not its presence"
    - "The same enum is rendered as its NAME by sqlite and as its VALUE by the HTTP API — a predicate must accept both or it cannot match"
    - "beets-flask state outlives the folder it describes, which makes a fixed instrument re-runnable with no second transit"
    - "Distinguish 'the extractor raised' from 'the extractor found nothing' in the verdict line, or a crash reports as an empty result"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-12-country-preference.txt
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-12-preview-crosscheck.txt
  modified:
    - .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md

key-decisions:
  - "CONF-05 is rested on THREE measurements, not one: the GB choice with its track count, the GB-vs-UK literal, and a one-key rank-0 flip on a second sampled row — because the S4 Now! rows provably cannot discriminate the setting"
  - "The chosen-MBID half of OQ-4's fallback basis was REJECTED with its reason: arm 1 imported as-is and has no MBID, arm 2 chose none, so comparing them would have compared two absences"
  - "`search_limit: 25` is recorded as an INSTRUMENT widening and explicitly not proposed for the vendored config"
  - "Path rule 2 was NOT executed: three documents assign it here, this plan's own body does not, and reaching outside the drawn sample is the hand-picking D-26 forbids. Logged as DEF-06-12-01, unowned"
  - "No config was edited to make the two arms agree; nothing under stacks/selfhosted/arrs/beets/ was touched at all"

requirements-completed: [CONF-05]

duration: 63min
completed: 2026-09-21
---

# Phase 6 Plan 12: CONF-05 Demonstrated and the Two Arms Agree Summary

**`match.preferred.countries` was driven rather than read back — twelve real MusicBrainz lookups, each pair one key apart — and it is now proven to change which release is chosen; and rc6's `preview` was shown to produce no destination paths at all, so the D-30 cross-check was rebased onto the per-item field tuple, where the two arms agree 15 of 15 with zero lines either side.**

## Performance

- **Duration:** ~63 min of execution (interrupted mid-task-2 by an API quota reset and resumed)
- **Tasks:** 2 of 2, both committed
- **Live runs:** 4 (1 instrument-defect RED, 1 GREEN, 1 instrument-defect RED, 1 GREEN)
- **MusicBrainz lookups:** 12 driven + 1 `beet import -t` + 1 flask preview
- **Artifacts created:** 2 (82 KB + 85 KB)
- **02-review transits:** 1 (this plan), 2 (phase total)

## Accomplishments

- **CONF-05 is discharged by demonstration, and it took three measurements because one was not enough.** The S4 *Now!* row chooses GB (`3b7a8210…`, 2xCD, 2018, original 1983) with 30 tracks against 30 files and zero unmatched either way, recommendation `strong`. But its A/B/C negative controls come out **identical at rank 0**, so the plan's own escape clause fired and the second S4 row was run — also identical. The demonstration proper is a **one-key rank-0 flip** on the S1 row, where `['XW','US']` and `['US','XW']` choose *different* releases, both 10-track. Plus the literal: under `['GB']` the GB release carries no country penalty, under `['UK']` it gains a full one and so does every other candidate — uniform, cancelling, inert, with no warning anywhere. The config's own comment about `UK` is now evidence.
- **OQ-4 is resolved, and no record of it existed anywhere in this project before.** rc6's `preview` shows **candidates, not a tree**. Three independent answers that agree: `PreviewSession`'s own docstring ("Only fetches candidates"), a **zero-match** grep for `destination` across the whole installed `beets_flask` package, and the persisted schema, whose only four path-bearing columns (`folder.full_path`, `task.toppath`, `task.paths`, `task.old_paths`) are all *source* paths. What preview *does* store is written down in full, because the next phase will want it.
- **D-30 arm 2 ran and the arms AGREE** — 15 of 15 `(albumartist, album, padded track, title, extension)` tuples, zero lines either side, on a basis that was redefined *and* whose weaker half was refused. Corroborated by arm 2's own field view resolving to the same `default` path rule arm 1 took (`disctotal 1`, `albumtype ''`, `comp False`, `singleton None`).
- **The vendored config's explanation of its own setting is corrected, with a date.** `config.yaml:351-354` blames `['GB','US']` on "the *Now!* series picking US pressings over the UK ones this library actually holds." Measured: the US releases MusicBrainz offers for these titles are the **American NOW franchise, 21-22 tracks against 30 files** — a different series, not a US pressing of the same release, losing on track distance by orders of magnitude more than the country term can supply. The setting stays; the mechanism named is not the one measured.
- **Five instrument defects across four runs, every one recorded rather than quietly corrected** — including the **seventh** predicate-cannot-match bug of this phase. See Deviations; three of the five produced a confident-looking wrong answer.
- **Two fences fired on their own before anything ran.** Task 1's preflight *refused to start* because a leftover development scratch directory held 5 entries; task 2's transit discipline held its source manifest byte-identical across all three reads. A preflight that has never fired is not a preflight, so the refusal is in the transcript.

## Task Commits

1. **Task 1: CONF-05 driven** — `4f6e4ef` (docs)
2. **Task 2: D-30 arm 2, OQ-4 resolved** — `18542f9` (docs)
3. **Two deferred items** — `060b6af` (docs)

## Files Created/Modified

- `artifacts/06-12-country-preference.txt` — 1,104 lines. The twelve-overlay matrix with each pair's one-key diff; nine numbered findings; the full candidate tables with per-key distance breakdowns; the verbatim `beet import -t` transcript; the raw ID3 frame set that carries `TXXX:COUNTRY = UK` and the D-28 Discogs id; the `dj-mixes` Discogs scan; the fence and the credential screen.
- `artifacts/06-12-preview-crosscheck.txt` — 1,013 lines. OQ-4's three answers; the redefined basis with the rejected half and its reason; the AGREE verdict with both sides printed; the arm-1-versus-arm-2 difference table; the D-35 amendment; the debounce timeline and the watchdog's own two log lines; both HTTP API views; the two instrument defects; the `bootleg` gate; and both run transcripts in full.
- `deferred-items.md` — two entries (DEF-06-12-01, DEF-06-12-02).

Nothing under `stacks/selfhosted/arrs/` was touched. The driver scripts and raw JSON live at the fence (`/mnt/fast/safety/phase06/06-12-stage/`), per `06-SAMPLE.md:61-65`.

## Decisions Made

**1. CONF-05 rests on three measurements, and says so.** The honest reading of the S4 rows is that *this content cannot discriminate the setting at rank 0*: the GB release beats its nearest rival by 0.53 while the entire country term is worth at most 0.0075 (weight 0.5 against a denominator dominated by 30 per-track distances). No ordering of two codes closes that. Rather than call a non-event a demonstration, or widen the sample until something flipped, the plan's own instruction was followed (second S4 row) and the flip was found on another **already-drawn** row. The split is stated in the artifact: findings 1 and 5 prove the committed `GB` literal; finding 6 proves the mechanism is decisive. Neither alone is the demonstration.

**2. The chosen-MBID half of OQ-4's fallback basis was refused.** The plan offers "chosen MBID plus the `albumartist`/`album`/`track` triple". The MBID half is unusable: plan 06-11's arm 1 imported the sample **as-is** (`-A`), so `lookup_candidates` never ran and arm 1 has no MBID; arm 2 is a preview, so `chosen_candidate_id` is `None` by definition. Comparing them would have been comparing two absences and reading it as agreement — the exact failure mode this phase keeps producing. The triple is the half with values on both sides and it is the whole basis used.

**3. The comparison decomposes arm 1 rather than re-rendering arm 2.** Arm 2's fields are not pushed through a reimplementation of `Item.destination()`; arm 1's measured output is taken apart and arm 2's measured input is read. The stated limit is that this cannot see `replace:`, `legalize_path`, `asciify_paths` or `max_filename_length`, because only arm 1 renders a path.

**4. `search_limit: 25` is an instrument widening and is not proposed as a config change.** It exists only to answer "is a US alternative available at all", which the committed default of 5 cannot. Its finding is logged as DEF-06-12-02 as a thing to **measure** in Phase 7, explicitly not as a value to raise.

**5. Path rule 2 was not executed, and the ownership gap is logged rather than silently filled.** `06-SAMPLE.md`, `06-09-SUMMARY.md` and `06-11-SUMMARY.md` all assign the `albumtype:=dj disctotal:2..` class assertion to plan 06-12. **`06-12-PLAN.md` contains no task for it** — not in its tasks, `must_haves`, `artifacts` or `success_criteria`. Inventing one would have meant reaching outside the drawn sample for a folder chosen *because* it carries the attribute under test, which is the hand-picking D-26 exists to prevent. DEF-06-12-01 names the seven eligible folders, writes out the exact assertion, and says why it must not wait for Phase 7's first real import.

**6. The fix to task 2's instrument was verified with no second transit.** beets-flask's `folder`/`session`/`task`/`items` rows outlive the directory they describe (06-06's dangling-state finding), so the fixed instrument re-read the state the single transit had already persisted. `02-review` was empty throughout run 2 and is asserted so in its own transcript. The D-35 amendment therefore stands at two phase transits, not three.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `plugins.load_plugins()` takes no argument at 2.12.0 — the first run produced no candidates at all**
- **Found during:** Task 1, live run 1
- **Issue:** `load_plugins(config["plugins"].as_str_seq())` raised `TypeError: load_plugins() takes 0 positional arguments but 1 was given` on all three overlays. Every probe exited 1 with zero bytes of stdout, and the downstream table renderer then failed on the empty JSON — two cascading failures from one wrong signature.
- **Fix:** `plugins.load_plugins()`; the function reads `config["plugins"]` itself.
- **Verification:** the re-run loaded `['musicbrainz']` and returned five candidates, and the plugin list is printed in every one of the twelve JSON dumps.
- **Committed in:** `4f6e4ef`

**2. [Rule 1 - Bug] the country-penalty predicate would have gone RED *because the setting worked*** — the sixth predicate-cannot-match bug of this phase
- **Found during:** Task 1, reading the first successful run's output
- **Issue:** `Distance.add_priority()` charges `index × (1/len(options))`, so a value matching the **first** entry scores **0.0** — and `Distance.items()`, quoting its own docstring, "Does not include penalties with a zero value." The chosen GB candidate therefore has **no** `country` key at all. A predicate asserting "the chosen candidate carries a country penalty" reports a violation precisely when the preference is working perfectly.
- **Fix:** the assertion is inverted and doubled — the chosen GB candidate must carry **no** country penalty, **and** all four non-GB candidates must carry one. Both halves are asserted and both pass.
- **Committed in:** `4f6e4ef`

**3. [Rule 1 - Bug] `items.fixed_values["path"]` is a base64 dict, and the resulting crash was reported as "arm 2 produced no items"**
- **Found during:** Task 2, live run 1
- **Issue:** the value is `{"__type__": "bytes", "data": "<base64>"}`, so `os.path.basename()` raised `TypeError: expected str, bytes or os.PathLike object, not dict`. The driver caught the non-zero exit and printed "the comparison could not be made", while the compare script's exit-1 branch is labelled "arm 2 produced no items" — and arm 2 had produced **all 15**. A wrong cause attached to a real failure is how the next reader concludes the preview found nothing.
- **Fix:** `decode_path()` handles `str`, `bytes` and the dict encoding and **refuses** anything else with a `TypeError` rather than guessing; the verdict line now distinguishes "the extractor raised (with the exception text)" from "the extractor ran and found nothing".
- **Verification:** two self-test cases — the dict form must decode, and an `int` must be refused.
- **Committed in:** `18542f9`

**4. [Rule 1 - Bug] THE SEVENTH PREDICATE-CANNOT-MATCH BUG — the same enum, two representations, one predicate**
- **Found during:** Task 2, live run 1
- **Issue:** the poll loop broke on the literal `"progress": 20`, but the two instruments that report progress disagree: sqlite's `session.progress` stores the enum **name** `PREVIEW_COMPLETED`, while `GET /api_v1/session/` renders the enum **value** `20`. **Both forms are in the artifact for the same session at the same instant.** The loop read the sqlite form, could never match, spun out its full 180 s bound and printed "COULD NOT LOOK: the session did not reach PREVIEW_COMPLETED within 180 s" — which was false; it reached it on the second poll, 48 s after the copy.
- **Why it failed loudly rather than silently:** only because the wait had a bound and the loop printed every poll. Written as a bare `if done: break` with no bound, it would have been a clean-looking green.
- **Fix:** `is_done()` accepts the enum name, the integer and the integer-as-string, for both terminal preview states.
- **Verification:** ten self-test cases, **six of them planted values that must NOT pass** — `LOOKING_UP_CANDIDATES` (mid-flight), `OFFERING_MATCHES` (an ImportSession state), `IMPORT_COMPLETED` (an import finished, which must never read as a preview pass), a mid-flight integer, `None` and `""`. All ten pass. The predicate was confirmed able to FAIL before its clean result was believed.
- **Committed in:** `18542f9`

**5. [Rule 1 - Bug] a prediction made before the run was WRONG, and is recorded as wrong**
- **Found during:** Task 1, reading overlays D and H
- **Issue:** the instrument was built expecting `preferred.original_year: no` to flip rank 0 between the two 30-track GB candidates (2009 and 2018 pressings). It does not — both choose `07971e8a…`.
- **Fix:** none needed; the artifact states the prediction and its failure explicitly rather than dropping the arm. The key is still shown to be *exercised* (the chosen candidate's `year 2018` and `original_year 1983` differ, and it carries a `year` penalty of 0.012149 = 35/43 raw), and the honest note that this setting therefore **penalises** the reissue the sample actually holds.
- **Committed in:** `4f6e4ef`

### Scope notes, not deviations

- **Task 1 widened the MusicBrainz candidate pool** to `search_limit: 25` on three of twelve overlays. Recorded in the artifact as an instrument change, labelled as not-a-config-change, and logged as DEF-06-12-02.
- **Task 2 made a second `02-review` transit**, which D-35's parenthetical did not anticipate. Recorded as an in-band amendment naming both transits exhaustively, per the plan's explicit instruction.

---

**Total deviations:** 5 auto-fixed, all Rule 1, all in the instrument. None in the configuration under test, none in the fixtures, none in the estate.
**Impact on plan:** none on scope. Deviations 2, 3 and 4 are the substantive ones: each produced a confident answer about something other than what it claimed to measure.

## Issues Encountered

**`scripts/check-music-freeze.sh` exits 1, and it is the documented Phase 5 red.** The plan's verification asks for exit 0. Run on LXC 100 after both arms: `FAILURES total: 1`, and the single failure is `interpolated-host-path inventory MOVED: expected=12, found=13` — the pre-existing Phase 5 open item already recorded in `06-10-SUMMARY.md` and `06-11-SUMMARY.md` and already carried into 06-14's closure. **Every music block is green:** tagger-class writers 0 (target 0), unclassified writers 0 (target 0), rw on Music non-tagger 0 (target 0), ownership mismatches 0, tagger definitions 1 of 1, beets databases 1 of 1, tagger databases 0 of 0, retired paths 0, all four fence subdirectories non-empty. The block verdicts were read, not the exit code, exactly as 06-10's plan instructs.

**Task 1's first run never started, and that is the preflight working.** A leftover `/tmp/p6smoke` from instrument development held 5 entries, so the driver refused and exited 2 before touching anything. It is in the record because a fence that has never fired is not a fence.

**Execution was interrupted mid-task-2 by an API spend limit and resumed after the quota reset.** Task 1 was already committed (`4f6e4ef`) and was not redone. The interruption fell between task 2's run 1 (the transit, which had completed and torn down cleanly, with `02-review` back to zero) and its diagnosis, so no folder was left staged and no estate state was left mid-flight.

**`album_info.data` carries no track list.** Arm 2's per-candidate track count reads 0 out of that table because the tracks live in `track_info`, keyed by `album_id`. **No track count is claimed for arm 2.** Task 1's track-count checks came from `tag_album()`'s own `AlbumInfo` objects, where the list is present. Recorded so nobody later reads a `0` there as "the candidate has no tracks".

## Known Stubs

None. Both artifacts exist, are non-empty, and carry machine-generated evidence rather than a claim about it. Both task verify commands exit 0.

Deliberately **not** done here, and each with a named home:

- **Path rule 2 (`albumtype:=dj disctotal:2..`) was not executed.** Three documents assign it to this plan; this plan's body does not. **DEF-06-12-01**, currently unowned — the natural homes are 06-13, 06-14, or Phase 7 alongside the OQ-2 DJ-routing item, which is the same subject. This is the only rule in the committed `paths:` stanza that no Phase 6 instrument has evaluated.
- **No GB-versus-US rank-0 flip exists anywhere in the sampled content**, at either search limit. The flip demonstrated is XW-versus-US. A GB/US flip needs a release MusicBrainz holds as both editions with the same tracklist, and this draw contains none.
- **The `bootleg` gate is still unexercised.** `03-asis` is registered (D-06) with `autotag: bootleg` and is measured **empty**, as it has been all phase. The gate — never route a folder to `bootleg` without first asserting `album` is populated and distinct across the intended groups — is carried to **Phase 7 routing time**, alongside OQ-2.
- **`preferred.media` is not set in the committed config** and was not exercised.
- **The preview UI was never opened.** Every arm-2 reading is from the HTTP API and the read-only sqlite. What a human *sees* in the preview pane is still unrecorded; what rc6 *stores* is what is recorded, and the two need not be the same set.
- **Whether the dangling `dbfolder`/`session` rows survive a container restart.** The container was deliberately not restarted. Same stated limit as 06-06.

## Threat Flags

None. Nothing was installed. Every command was read-only or confined to `/tmp/p6c` / `/tmp/p6p` inside a container whose `/media` mount was asserted `RW=false` from `docker inspect` before anything ran. Both artifacts were re-screened for credentials before committing (T-06-65): they carry paths, MusicBrainz IDs, catalogue numbers, folder hashes, session UUIDs, config keys, two already-published sha256 baselines, and one public Discogs release URL. No Discogs credential was loaded and none exists to load (Phase 4 D-24, D-28); the only outbound host contacted was `musicbrainz.org`.

## Next Phase Readiness

- **06-13 and 06-14 can proceed.** Neither depends on anything this plan left open. 06-13 still owns re-proving Music Assistant's live `2.11.0b2` and moving `MA_VERSION_PROVEN` in the same commit; this plan did not touch `check-music-consumers.sh`. **CONF-04's write side is already covered there** — 06-02 recorded the requirement and 06-03 has since extended that script with the D-34 `PreferNonstandardArtistsTag` flag and the D-22 entity checks, so there was nothing for this plan to add; it was read before being assumed missing.
- **Phase 7 inherits four named items, all registered:**
  1. **DEF-06-12-01, path rule 2** — unowned within Phase 6, and the only unevaluated rule in the stanza. A rule that has never been rendered is exactly where a `00-01`-shaped defect hides; Phase 3 found one of those in the tagger this project retired.
  2. **The `bootleg` album-populated gate** — `03-asis` registered, never run, and the same button produced Phase 3's best and worst results purely on that one condition with no UI signal either way.
  3. **OQ-2 / C-6, the DJ routing mechanism** — `--set albumtype=dj` has no per-inbox equivalent in rc6's `InboxFolderSchema`. Arm 1 supplied it by hand from a shell; arm 2 cannot. Same shape as item 1.
  4. **DEF-06-12-02, the candidate-pool size** — measure, per folder in the pilot, whether the accepted candidate was in the first 5.
- **The order of the match checks is now measured, and it is not the obvious one.** The second S4 row's top candidate is Finnish, at distance 0.50006, with a **track count of 30 that matches the folder's 30 files exactly** — and beets itself refuses it, `recommendation: none`. So "never accept a match without a track-count check" is necessary and **not sufficient**: there, the count is the misleading signal and the recommendation is the true one. Phase 7 should gate on the recommendation first, then the count, then the per-track distance — and treat a `none` recommendation with a matching count as the specific shape most likely to be waved through by a human in a hurry.
- **Two consumer-facing facts for Phase 7's first real import.** `TXXX:COUNTRY = UK` and `TXXX:ORGANIZATION` are not mediafile fields, so beets reads `country` and `label` as empty and **drops both from the MusicBrainz query** — three of the five configured `extra_tags` are doing work on this content and two are inert-because-unfed, not misconfigured. And the stale `dbfolder`/`session` pair left behind by any folder renamed, moved or removed between preview and import is now confirmed on two folders; neither it nor the watchdog's `FileNotFoundError` is a fault, and both look like one read cold.

## Self-Check: PASSED

- `artifacts/06-12-country-preference.txt` — FOUND (1,104 lines, 81,753 bytes)
- `artifacts/06-12-preview-crosscheck.txt` — FOUND (1,013 lines, 85,360 bytes)
- `deferred-items.md` — FOUND, +65 lines, two new entries
- commit `4f6e4ef` — FOUND
- commit `18542f9` — FOUND
- commit `060b6af` — FOUND
- task 1 verify command — exit 0 (`CONF-05 driven proof recorded`)
- task 2 verify command — exit 0 (`D-30 arm 2 recorded; 02-review empty`)
- `02-review` — 0 entries at `-mindepth 1`, from a bounded remote command
- estate after both arms — `library.db` `fbbdde0c…`, `state.pickle` `f6a9a1ad…`, both at their 06-04/06-11 baselines with mtimes unmoved; `/tmp/p6c`, `/tmp/p6p` and `/tmp/p6smoke` all gone
- all three source folders — sha256 manifests (content **and** metadata) identical before and after
- `check-music-freeze.sh` on LXC 100 — exit 1, the documented Phase 5 red; every music block green
- no modification to `STATE.md` or `ROADMAP.md`; nothing under `stacks/` touched

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-21*
