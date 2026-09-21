---
phase: 06-tagger-configuration-and-dry-run
plan: 11
subsystem: testing
tags: [beets, dry-run, oracle, path-templates, zero-diff, ndjson, d-29, aunique, docker-exec]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-05's committed fixtures — 06-EXPECTED-TREE.txt (174 path lines) and 06-SAMPLE.md (ten drawn folders, 174 audio files), both committed in wave 2 BEFORE this run"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-09's scripts/phase06-oracle.sh — written but never run against the live estate"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-07's A3/A4/A5 verdicts on the -c overlay, and plan 06-04's D-29 layer-3 baselines"
provides:
  - "CONF-06 discharged: `beet move -p` over 174 files diffs to ZERO LINES against a tree committed before the run, with the positive control shown to have gated it"
  - "CONF-03 discharged: every top level equals its item's own ALBUMARTIST byte-exactly; Various Artists present, no Compilations component"
  - "The three-layer D-29 wrote-nothing proof, with state.pickle named and mtimed alongside library.db"
  - "The D-18 protected-field ledger — 870 records, 0 failed, 0 proposed changes, 195 of them carrying a real value that survived"
  - "An oracle that has now been run, whose four first-run defects are fixed and driven by --self-test (56 -> 73 cases)"
affects: [06-12, 06-13, 06-14, 07]

tech-stack:
  added: []
  patterns:
    - "The positive control is evaluated BEFORE the diff and SUPPRESSES it; run 1 exited 3 and the diff was never run"
    - "Absent-on-both-sides is a third classification, distinct from both 'unchanged' and 'proposed change'"
    - "Read a count from the tool's own log line rather than inventing a predicate for a line shape it never emits"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-11-oracle-run.txt
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-11-wrote-nothing.txt
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-11-dj-fields.ndjson
  modified:
    - scripts/phase06-oracle.sh
    - .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md

key-decisions:
  - "import.duplicate_action moved skip -> keep: `skip` is safe but not faithful, and it silently removed the one %aunique{} collision the sample was drawn to test"
  - "ANSI is turned off at the source (ui.color: no) AND stripped defensively, so a coloured transcript cannot produce a COULD NOT LOOK that looks like a config defect"
  - "The (N already in place) count is read from beets' own `Moving N items.` log line on stderr; its absence is a COULD NOT LOOK, never a zero"
  - "The D-18 ledger's null-equivalence is computed from Item._fields at RUNTIME, not from a hard-coded table"
  - "06-EXPECTED-TREE.txt was not touched; four failing runs are recorded in the artifact instead"

requirements-completed: [CONF-03, CONF-06]

duration: 38min
completed: 2026-09-21
---

# Phase 6 Plan 11: The Oracle Ran Summary

**`beet move -p` over 174 files, imported as-is into a copy of the real library, produced a destination list that diffs to ZERO LINES against a fixture committed two waves earlier — after the positive control caught the first run measuring 164 files instead of 174 and refused to evaluate the diff at all.**

## Performance

- **Duration:** 38 min
- **Tasks:** 2 of 2
- **Live runs:** 5 (1 UNKNOWN, 1 UNKNOWN, 1 RED, 2 GREEN)
- **Artifacts created:** 3 (87 KB + 59 KB + 253 KB)
- **Self-test:** 56 -> 73 cases, all passing

## Accomplishments

- **CONF-06 is a fact.** Zero lines of difference, in both directions, against `06-EXPECTED-TREE.txt` — committed in wave 2, before this instrument existed in runnable form. The fixture was not touched by this plan; `git log` on it carries no 06-11 commit. All four preconditions its header names held and each is evidenced rather than assumed: one library (174 items in one field view), `--set albumtype=dj` on S5 (20 items carry it), `-s` on S7 (the `singleton:` rule resolved), `-A` with `import.write` overridden to `no`.
- **The positive control did its job on the very first run, which is the point of it.** Run 1 produced 164 destination pairs against 174 sampled audio files, exited 3, and **the diff was not evaluated**. Had the equality been a floor — "at least 174" would not have caught it either, but "at least 100" would have passed — a partial import would have diffed clean on every line it had.
- **All three D-29 layers held with no "could not look".** `/media` RW=false read from `docker inspect` and never from compose; checksum manifests over all ten sampled folders (190 files, metadata *and* content, identical before and after, re-verified with `cmp`); `library.db` **and** `state.pickle` byte-identical with mtimes recorded too — 2026-09-12 and 2025-11-18, neither moved. The `-newer` preflight answered `READY` and the sweep found 0.
- **Nine class assertions plus the CONF-04 report, all clean,** including the `%aunique{}` firing reconciled in *both* directions against the pre-run prediction with the numeric-database-id guard armed and not firing, the single singleton resolution listed with its source folder, and a D-18 ledger of 870 records with 0 failures and 0 proposed changes.
- **Four instrument defects found and fixed, every one of which produced a confident green-looking answer while measuring the wrong thing.** They are the substance of this plan as much as the zero-diff is; see Deviations.

## Task Commits

1. **The instrument fixes** — `c0b7123` (fix)
2. **Task 1: the run, the controls, the zero-diff and the three layers** — `a39763a` (docs)
3. **Task 2: the class assertions and the D-18 ledger** — `e961ba8` (docs)
4. **Out-of-scope discoveries** — `1bff5ef` (docs)

## Files Created/Modified

- `artifacts/06-11-oracle-run.txt` — 1,105 lines. Provenance and the four preconditions; the five positive controls with their values; the raw 348-line `beet move -p` transcript verbatim; the normalised 174-line destination list; the zero-diff result; the four first-run failures; all nine class assertions; CONF-04's write side; the OQ-2 registration; and what the run does not cover.
- `artifacts/06-11-wrote-nothing.txt` — 532 lines. The three-layer proof, the manifests and their digests, the full 190-line content manifest, the preflight result, both real-file hashes *and* mtimes, and the verbatim console output of the passing run.
- `artifacts/06-11-dj-fields.ndjson` — 870 records, one per (file, field), in `normalise-dj-tags.py`'s shape.
- `scripts/phase06-oracle.sh` — +315/−18.
- `deferred-items.md` — two new entries.

## Decisions Made

**1. `import.duplicate_action` moved `skip` -> `keep`.** 06-09 added `skip` as a Rule-2 safety deviation against rc6's `remove` default, which deletes duplicates with no prompt. `skip` is safe and it is *not faithful*: the S1 stratum deliberately drew two rips of Benson Boone / American Heart because that pair is the one predicted `%aunique{}` firing, and `skip` removed it from the library. `keep` imports both and deletes nothing — the only value that is both safe and faithful. Safe and faithful are different properties and this is the plan that learned the difference.

**2. Colour is turned off at the source AND stripped defensively.** `ui.color: no` in the overlay is the fix; `normalise_transcript` strips SGR into a `.clean` file regardless, because a transcript that arrives coloured by some other route must normalise to the same verdict rather than to a COULD NOT LOOK that reads like a config defect. The literal trailing space on the source half of the narrow form is stripped with it, **address-restricted to lines carrying no ` -> `** so that a destination genuinely ending in a space would stay visible as the path-rule finding it would be.

**3. `(N already in place)` is read from beets' own log line, and its absence is a refusal.** The old predicate looked for a standalone `(N already in place)` line on stdout. beets emits `Moving 174 items (3 already in place).` on **stderr**, embedded. A predicate that cannot match its target is not a control, and it had been reporting "line ABSENT, N=0". Now parsed from the log line, with a missing line routed to COULD NOT LOOK.

**4. The D-18 ledger's null-equivalence is computed at runtime, not tabulated.** `NULLS = {f: Item._fields[f].null ...}` is read off the engine every run, so a beets that changes a field's null cannot leave a stale constant behind in this script.

**5. The expected tree was not edited, and the failures are in the artifact.** Four runs failed before one passed. None of the four was a defect in the `paths:` stanza or in the fixture. T-06-54's mitigation is not "the tree was not changed" alone — it is that a run which did not pass first time says so, with each failure and its cause written down.

**6. The verbatim console log is filed in the companion artifact.** The task-1 verify greps `06-11-oracle-run.txt` for a literal that also appears in the oracle's own D-15 success message. The choice was to weaken the check or to move the log; the log moved, and both artifacts say why. See DEF-06-11-02.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `import.duplicate_action: skip` dropped ten of the 174 sampled files**
- **Found during:** Task 1, live run 1
- **Issue:** 164 destination pairs against 174 sampled audio files; exit 3, UNKNOWN, diff not evaluated. The missing ten are the whole `Benson_Boone_-_American_Heart-WEB-2025-BENSONBOONE` folder — the second rip of an album already in the throwaway library, and therefore the source of the fixture's single predicted `%aunique{}` firing.
- **Fix:** `duplicate_action: keep` in the `-c` overlay, with the reasoning and the rejection of `remove` / `merge` / `ask` written into the script.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** run 2 onward produce 174 pairs and one `%aunique{}` firing matching the prediction exactly.
- **Committed in:** `c0b7123`

**2. [Rule 1 - Bug] `beet move -p` colours its output, so no destination could ever match the fixture**
- **Found during:** Task 1, live run 1
- **Issue:** `show_path_changes` calls `beets.util.diff.colordiff`, which interleaves SGR runs *through* both paths — `/m<ESC>[1;32media/M<ESC>[39;49;00music/`. Three separate consequences, each of which would have read as something other than what it was: 174 diff failures that look like 174 path-template defects; a CONF-03 join that returns COULD NOT LOOK on all 174 rows because the source column cannot match `beet ls -f`; and `grep -q '/media/Music/'` returning nothing, so positive control 4 fires for a reason that is not a defect.
- **Fix:** `ui.color: no` in the overlay, plus an SGR strip and an address-restricted trailing-whitespace strip in `normalise_transcript`, into a separate `.clean` file so the raw stays auditable.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** a self-test case asserts a coloured narrow transcript normalises **byte-identically** to its plain equivalent, and that no ESC byte survives into the pairs file. Live: `SGR-coloured raw lines: 0`.
- **Committed in:** `c0b7123`

**3. [Rule 1 - Bug] the `(N already in place)` control could never fire — the fifth predicate-cannot-match bug of this phase**
- **Found during:** Task 1, live run 1
- **Issue:** the count is built as a fragment and handed to `log.info` (`beets/ui/commands/move.py@v2.12.0:94-107`), so the real shape is `Moving 164 items (3 already in place).` on **stderr**. The standalone-stdout-line predicate matched nothing, printed "line ABSENT", set N=0 and passed vacuously.
- **Fix:** `read_unmoved()` parses the log line; a missing file or a missing line is COULD NOT LOOK. Yielded control 5 as a bonus — the N in `Moving N items` must equal the pairs parsed, which catches a truncated transcript that satisfies all four earlier controls.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** five self-test cases including two could-not-looks and a coloured log line; plus a dedicated case for control 5.
- **Committed in:** `c0b7123`

**4. [Rule 1 - Bug] the D-18 ledger opened the library without a `directory`, breaking exactly the stratum that matters most**
- **Found during:** Task 2, live run 2
- **Issue:** 60 `failed` records — all twelve S6 files, all five fields, `No such file or directory: '/home/beetle/Music/…'`. beets 2.12.0 stores an item path **relative to the library directory** when it sits underneath it and re-absolutises it against `lib.directory` on read (`beets/library/models.py@v2.12.0:130`; `Library._migrations` carries a `RelativePathMigration`). `Library(db)` alone falls back to platformdirs' user music path. Items under `/downloads` are outside the directory, stored absolute, and read correctly either way — which is why **only** the stratum drawn from the real library broke, i.e. exactly the files Phase 7 will re-tag.
- **Fix:** `Library(db, directory=/media/Music)`, with the library root passed as `argv[2]`.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** a self-test case walks the payload's AST and requires a `directory=` keyword on every `Library()` call. The predicate was confirmed to FAIL against a planted `Library(sys.argv[1])` before its pass was believed.
- **Committed in:** `c0b7123`

**5. [Rule 1 - Bug] the D-18 ledger reported 327 phantom "proposed changes"**
- **Found during:** Task 2, live run 3 (exit 1, RED)
- **Issue:** mediafile reports an absent tag as `None`; beets' typed model reports the same absence as that field's own null. Read straight off the engine: `bpm` Integer null `0`, `comments` String null `''`, `genres` DelimitedString null `[]`, `initial_key` MusicalKey null `None`. A naive `old != new` called 327 of 870 records a change. **Not one of the 327 had a non-empty `old` value** — nothing was being lost.
- **Fix:** both-sides-absent is marked `noop` **and** flagged `null_equivalent` and listed as `NULL-EQUIVALENT` in the evidence file, so the class is counted rather than swallowed. The nulls are read from `Item._fields` at runtime. The raw `old` and `new` stay in every record.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** two paired self-test cases — the null-equivalent ledger must be clean *and* its three records must be listed, while a planted `bpm: "128" -> "0"` (a real strip, which is what D-18 guards) must still go RED.
- **Committed in:** `c0b7123`

**6. [Rule 1 - Bug] the CONF-04 report said "multi-valued" while counting "non-empty"**
- **Found during:** Task 2, reading run 4's output
- **Issue:** the predicate is `$6 != ""`. It reported "12 item(s) carry a multi-valued artists field" when 12 carry a non-empty one and exactly **1** carries more than one artist. A report that overstates by a factor of twelve is how a claim gets laundered into a later document.
- **Fix:** both numbers are computed and stated separately.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Committed in:** `c0b7123`

---

**Total deviations:** 6 auto-fixed, all Rule 1.
**Impact on plan:** none on scope. All six are in the instrument, not in the configuration under test and not in the fixture. Deviations 1, 3 and 5 are the ones that matter: each would have produced a confident answer — a zero-diff, a green control, a red assertion — about something other than what it claimed to measure.

## Issues Encountered

**`scripts/check-music-freeze.sh` exits 1, and it is the documented Phase 5 red.** The plan's verification asks for exit 0. The single failed assertion on LXC 100 is `interpolated-host-path inventory MOVED: expected=12, found=13` — the Phase 5 open item already recorded in `06-10-SUMMARY.md` as pre-existing and verified not caused by Phase 6, and already carried into 06-14's closure. None of the 13 interpolated lines is under `stacks/selfhosted/arrs/beets/`. **Every music-related block is green:** tagger-class writers 0, unclassified writers 0, rw on Music non-tagger 0, rw on Music tagger-capable 0, fence assertions failed 0, ownership mismatches 0, retired paths 0, tagger definitions 1 of target 1, beets databases 1 of target 1. The block verdicts were read, not the exit code, exactly as 06-10's plan instructs.

**Running `check-music-freeze.sh` from the macOS workstation reports 10 failures, and all ten are could-not-looks.** `/mnt/tank` does not exist there, so "media subtrees found: 0" and "artist folders: 0". The script's own header documents the correct invocation (`ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-music-freeze.sh'`); the local run was the wrong one. Recorded because a reader who runs it the obvious way will see ten reds that are not reds, and because it is the same class of mistake this whole plan is about: an instrument that cannot see reporting zero.

**Two aborted runs left `/tmp/p6` behind and it was cleared by hand.** Runs 1 and 2 exited before step 12. `/tmp/p6` held only `lib.db` and `overlay.yaml`; it was removed and its absence asserted, and `library.db` / `state.pickle` were re-hashed after each and found unchanged. Final state: `SCRATCH_GONE`, `STAMP_GONE`, both baselines at their recorded values.

**The negative controls were planted before their clean results were believed.** Given the five predicate-cannot-match bugs this phase has now produced, the `-1 - ` shape predicate and the ledger's `directory=` AST check were both run against planted positives and confirmed to fire. The `Compilations` predicate needed no planting — it fired for real, on the artifact's own prose.

## Known Stubs

None. Every artifact the plan names exists, is non-empty, and carries machine-generated evidence rather than a claim about it.

Deliberately **not** done here, and owned elsewhere:
- **Rule 2 (`albumtype:=dj disctotal:2..`) is not exercised.** Both drawn DJ folders carry no `disctotal`, so both resolved to rule 3. Seven `dj-mixes` folders in the population carry `disctotal=2`. `06-EXPECTED-TREE.txt`'s header, `06-SAMPLE.md` and `06-09-SUMMARY.md` all assign this to **plan 06-12** as a named class assertion. This plan does not duplicate it.
- **CONF-05's *Now!* proof** is a class assertion in 06-12, not a fixture row.
- **The WAV branch of the D-18 ledger had no input.** This draw is 105 MP3 + 69 FLAC and contains no WAV at all. That is a third state, distinct both from "ran and found nothing" (which is what happened for `initial_key` and `EnergyLevel`, 0 of 174 each) and from "was skipped" (which must never happen). The branch is implemented and self-tested; it has not been exercised against a real WAV.

## Threat Flags

None. Nothing was installed; every command was read-only or confined to `/tmp/p6` inside a container whose `/media` mount was asserted RW=false before anything ran. The three artifacts were re-screened for credentials before committing (T-06-59): they carry paths, tag values and config keys only. The one match on a credential pattern is a track title, `Mastermix - The Secret Garden`.

## Next Phase Readiness

- **06-12 can proceed.** It owns rule 2 over one of the seven `disctotal=2` `dj-mixes` folders, and CONF-05's *Now!* proof. The oracle it will reuse has now been run against the live estate, so its remote layer is exercised rather than merely written — the `docker exec` argv quoting and the `beet ls -f` template both work, which is where 06-09 predicted adjustments would surface.
- **Phase 7 inherits three named items,** all registered rather than left unowned:
  1. **OQ-2 / C-6, the DJ routing mechanism.** Phase 6 proved the DJ *path rule*, not the mechanism. `--set albumtype=dj` is a CLI flag with no per-inbox equivalent in rc6's `InboxFolderSchema`; this oracle supplied it by hand from a shell. Three candidate routes are named in the artifact (global `import.set_fields` — wrong; post-import `beet modify` + `beet move`; a hook plugin).
  2. **Every `%aunique{}` firing is a Music Assistant risk to verify.** A firing makes the album folder differ from the album tag by construction, and MA's `missing_album_artist_action: folder_name` silently falls back to `Various Artists` when folder and tag disagree while `config/providers/get` still reads back `folder_name` — the configuration looks right while the behaviour is not. Check MA's resulting album artist, not MA's config.
  3. **`Various Artists/` and `Various/` will both exist** (DEF-06-11-01). CONF-03 passes on both because each equals its item's own `ALBUMARTIST`; the defect is in the tags and no path rule can fix it.
- **The `%aunique{}` equivalence is dated.** The real collision set is empty today (0 items, 0 albums), which is why one firing is correct here. It stops being true the moment Phase 7 imports anything, and the reading must be re-taken then.
- **The multi-disc convention is decided but not reconciled.** This tree produces `02-05`; the existing library carries `CD 02-01 Artist - Title.ext`. Phase 6 does not reconcile them, and the S6 rows are the clearest illustration — their sources carry the old convention and their destinations the new one.

## Self-Check: PASSED

- `artifacts/06-11-oracle-run.txt` — FOUND (1,105 lines, 87 KB)
- `artifacts/06-11-wrote-nothing.txt` — FOUND (532 lines, 59 KB)
- `artifacts/06-11-dj-fields.ndjson` — FOUND (870 records, 253 KB)
- commit `c0b7123` — FOUND
- commit `a39763a` — FOUND
- commit `e961ba8` — FOUND
- commit `1bff5ef` — FOUND
- task 1 verify command — exit 0
- task 2 verify command — exit 0
- `scripts/phase06-oracle.sh --run` — exit 0, VERDICT: GREEN
- `bash -n` and `shellcheck -S warning` — clean
- `scripts/phase06-oracle.sh --self-test` — exit 0, 73 cases
- `git diff --stat 6cddb17..HEAD` — 5 files: the three artifacts, the oracle script, `deferred-items.md`. No shared orchestrator artifact touched.
- `06-EXPECTED-TREE.txt` — UNCHANGED by this plan
- estate after the run — `library.db` fbbdde0c…, `state.pickle` f6a9a1ad…, `/tmp/p6` gone, stamp gone

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-21*
