---
phase: 06-tagger-configuration-and-dry-run
plan: 09
subsystem: testing
tags: [beets, bash, oracle, dry-run, path-templates, shellcheck, ndjson, docker-exec]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-04's D-29 layer-3 baselines (library.db fbbdde0c…, state.pickle f6a9a1ad…) and the beets-flask runtime the oracle drives"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-05's committed fixtures — 06-EXPECTED-TREE.txt (174 path lines) and 06-SAMPLE.md (the ten drawn folders, 174 audio files)"
  - phase: 03-tagger-spike
    provides: "scripts/spike03-wrtag-arms.sh — manifest(), manifest_compare()'s three-outcome vocabulary, the CR-02 could-not-look preflight and the --self-test shape"
provides:
  - "scripts/phase06-oracle.sh — the driven dry-run oracle: throwaway import, beet move -p, the three-layer wrote-nothing proof, the diff against the committed tree, and nine class assertions"
  - "A --self-test that drives 56 cases with no docker and no ssh, including fourteen distinct red / could-not-look branches"
  - "The D-18 protected-field NDJSON ledger generator, in the normalise-dj-tags.py record shape"
  - "A reusable split: every green/red decision is a pure-local function over local files; the remote layer only produces those files"
affects: [06-11, 06-12, 07]

tech-stack:
  added: []
  patterns:
    - "Judging layer / producing layer split — the self-test drives the same functions the real run calls"
    - "The positive control lives INSIDE the measurement; its failure suppresses the diff entirely"
    - "Assertions set ASSERT_WHY + ASSERT_EVIDENCE and return 0/1/2; only the wrapper prints"

key-files:
  created:
    - scripts/phase06-oracle.sh
  modified: []

key-decisions:
  - "beet move -p is the destination-path oracle; beet import --pretend is refused as one, and the verify fails the script if the string appears in an executable line at all"
  - "The sampled folder list and the DJ file count are READ from 06-SAMPLE.md, never re-typed"
  - "The %aunique{} predicted set is derived from the fixture's own PATH LINES, not from prose in its header — the two agree and only the path lines are mechanically checkable"
  - "Exit 3 is a distinct verdict for UNKNOWN, kept separate from 1 (red) and 2 (precheck refusal)"
  - "The D-18 ledger is judged structurally (compact JSON, fixed key order) rather than by parsing values in awk"
  - "--run is required; the script has no default action"

patterns-established:
  - "Pattern: a class assertion returns 0/1/2 and writes evidence to a file, so --self-test compares return codes instead of grepping a human report"
  - "Pattern: an equality (not a floor) wherever a rule could silently fail to match and fall through to a valid-looking default"
  - "Pattern: a positive control paired with every absence assertion — zero Compilations/ is only meaningful when a Various Artists row proves the rule was reached"

requirements-completed: [CONF-03, CONF-06]

duration: 41min
completed: 2026-09-21
---

# Phase 6 Plan 09: The Dry-Run Oracle Summary

**`scripts/phase06-oracle.sh` makes "the intended tree" checkable: `beet move -p` against a copy of the real library, diffed against the committed 174-line fixture, with nine class assertions and a positive control that turns an empty measurement into `UNKNOWN` instead of a zero-diff.**

## Performance

- **Duration:** 41 min
- **Tasks:** 2 of 2
- **Files created:** 1 (1,894 lines)
- **Self-test cases:** 56 pass, 0 fail

## Accomplishments

- **The instrument question is settled in code, not prose.** `beet import --pretend` cannot produce a tree — its pipeline is `read_tasks → log_files` and every line it prints is a *source* path (D-33). The oracle uses `beet move -p`, whose `item.destination()` is the same call a real import makes, and the plan's own verify command fails the script if `import --pretend` appears in an executable line at all.
- **The positive control sits inside the measurement.** Four conditions must hold before the diff is evaluated: every payload line parses as a ` -> ` pair, the pair count *equals* 174, `(N already in place)` is 0, and `/media/Music/` appears in the raw transcript. Any failure yields `UNKNOWN, not green` and exit 3 — the diff is not run at all, so an oracle that emitted nothing cannot produce a zero-diff.
- **All three D-29 layers are implemented, with the source layer a checksum manifest.** Layer 1 reads `RW=false` off `docker inspect` rather than the compose file; layer 2 takes `LC_ALL=C` metadata *and* sha256 manifests over every sampled folder and compares them with the three-outcome vocabulary; layer 3 names `state.pickle` alongside `library.db`, because `-l` does not redirect `statefile:`.
- **Nine class assertions, each with its red branch proven to fire.** CONF-03 top level, D-15, D-13, D-16 (plus the numeric-database-id guard), D-19b, D-19a, the `-1 - ` shape, the `.N` collision shape, and the D-18 NDJSON ledger — plus CONF-04's write side as a report.
- **`--self-test` drives 56 cases with no docker and no ssh**, including a `--pretend`-shaped transcript, a wrong line count, a non-zero already-in-place, a blind preflight, manifest CHANGED and COULD-NOT-COMPARE, ten assertion reds, and a clean fixture producing zero.

## Task Commits

1. **Task 1: the oracle core** — `f3d6be1` (feat)
2. **Task 2: the class assertions** — `6d5ad6a` (feat)

## Files Created/Modified

- `scripts/phase06-oracle.sh` — the driven dry-run oracle. 1,894 lines: a 189-line header that is the `--help` output, a pure-local judging layer, an embedded Python ledger generator, a remote layer, and the `--self-test`.

## Decisions Made

**1. The sampled folder list is read from `06-SAMPLE.md`, never re-typed.** Same principle `spike03-wrtag-arms.sh` applies to its path format: a re-typed copy measures a set this project does not use, and drifts silently. `parse_sample()` pulls the ten rows out of the "ten drawn folders" table and sums the Files column; the run refuses to start unless that sum equals the fixture's path-line count. Both came back 174, which is itself a live cross-check of two committed documents.

**2. The `%aunique{}` predicted set is derived from the fixture's PATH LINES, not its header prose.** The plan says to compare against "the predicted firings in `06-EXPECTED-TREE.txt`'s header". The header documents exactly one firing and the path lines carry exactly that one — `American Heart [Night Street Records, Inc. - Warner Records Inc.]`, verified by inspection — so the two agree, and only the path lines are mechanically checkable. Parsing prose out of a header would be a second place for a bug to hide.

**3. The expected DJ count comes from `06-SAMPLE.md`'s S5 rows and is cross-checked against the fixture's `DJ/` line count.** If the two ever disagree, the D-13 equality would be measured against a number nobody wrote down, so the disagreement is its own red.

**4. Exit 3 is a distinct verdict.** 0 green, 1 red, 2 precheck refusal, 3 UNKNOWN. Collapsing 3 into 1 would make "the dry run wrote something" and "the instrument could not look" read the same in a transcript, which is the exact conflation CLAUDE.md § Health Checks forbids.

**5. The D-18 ledger is judged structurally, not by parsing values.** The generator emits canonical compact JSON with a fixed key order, so the judge matches `"noop":true` and `"failed":` as substrings and counts records (five per sampled file). A value-parser in awk over arbitrary tag text would be a second bug surface, and a `failed` record is routed to COULD NOT LOOK rather than to red — a field that could not be read is not a field that was preserved.

**6. `--run` is required; the script has no default action.** A script whose default is "drive an import into a container that mounts the real library" is a footgun. No-args prints usage and exits 2.

**7. The CONF-03 top-level comparison branches on three path shapes, read off the committed `paths:` stanza.** `DJ/<albumartist>/…` and `Singles/<artist>/…` put the artist in the *second* component, and the singleton rule names `$artist` rather than `$albumartist`. A single "first component equals albumartist" rule would have gone red on 21 of the 174 fixture rows for a reason that is not a defect.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] `import.duplicate_action: skip` added to the `-c` overlay**
- **Found during:** Task 1 (the overlay)
- **Issue:** The plan specifies `copy: no, move: no, write: no, autotag: no` for the overlay. It does not name `duplicate_action`. 06-RESEARCH.md Pitfall 3 records that an absent `import.duplicate_action` is rc6's default, not beets' — and rc6 commits `remove`, deleting duplicates with no prompt. The sample deliberately contains two rips of the same album (the S1 `%aunique{}` pair), so this is not a hypothetical: an unset key could have deleted real source files during a run whose entire premise is that it writes nothing.
- **Fix:** the overlay sets `import.duplicate_action: skip` and the header states why.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** `--self-test` passes; the key is visible in the generated `overlay.yaml` block.
- **Committed in:** `f3d6be1`

**2. [Rule 2 - Missing critical functionality] `set -o pipefail` added to a remote string whose `|` characters are Go template separators**
- **Found during:** Task 1 (the `docker inspect` mount census)
- **Issue:** the plan's verification rule is `grep -n 'timeout $REMOTE_TIMEOUT.*|'` must return only lines that also carry `pipefail`. The mount-census line matched because the Go template `{{.Source}}|{{.Destination}}` contains pipe characters — no shell pipe is involved, but the rule reads the line, not the intent, and leaving a reader to adjudicate that is exactly how a real violation gets waved through later.
- **Fix:** `set -o pipefail` stated on that remote string too, with a comment saying why.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** `grep -n 'timeout \$REMOTE_TIMEOUT.*|' scripts/phase06-oracle.sh | grep -cv pipefail` → 0.
- **Committed in:** `f3d6be1`

**3. [Rule 1 - Bug] `--help` printed the embedded Python's comments as part of the contract**
- **Found during:** Task 2 (after the ledger payload was added)
- **Issue:** the house idiom `grep '^#' "$0" | sed 's/^# \{0,1\}//'` (from `check-music-freeze.sh`) prints *every* comment line in the file. With the Python payload embedded, `--help` grew to 374 lines and interleaved the bash section headers and the payload's own comments into what the plan says must be the header contract.
- **Fix:** `--help` now prints the leading comment block only, stopping at the first non-comment line — 189 lines, ending at the header's closing rule.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** `bash scripts/phase06-oracle.sh --help | wc -l` → 189; the last line is the header's closing `====` rule.
- **Committed in:** `6d5ad6a`

**4. [Rule 1 - Bug] `json.dumps` default separators would have made the ledger unmatchable**
- **Found during:** Task 2 (writing the ledger judge)
- **Issue:** `json.dumps(rec)` emits `"noop": true` with a space; the judge matches `"noop":true`. The judge would have counted *every* record as a proposed change — a predicate that could never match its target, which is the exact bug class that bit three plans in this wave.
- **Fix:** `separators=(",", ":")` on the generator, with a comment stating that the spacing is load bearing for the judging half.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** the self-test's ledger fixtures are written in the compact form and drive both the red and the clean branch.
- **Committed in:** `6d5ad6a`

**5. [Rule 1 - Bug] `mutagen.id3.ID3().load(path)` cannot honour a WAV chunk offset**
- **Found during:** Task 2 (the EnergyLevel raw read)
- **Issue:** the first draft called `ID3().load(path, translate=False)` after computing the WAV `id3 ` chunk offset — but `ID3.load` reads from file offset 0 and takes no offset argument, so the offset would have been computed and then thrown away. That is precisely the `normalise-dj-tags.py:866-883` defect: reading `RIFF` at offset 0 for every WAV and returning silently, a vacuous pass.
- **Fix:** `raw_id3()` computes the offset (raising if there are two `id3 ` chunks, because which one a reader honours is then undefined), records it in the record's `rule` field, and obtains the frame set through mutagen's own `WAVE` handler, which reads that same chunk. MP3 goes through `ID3(path)` at offset 0; FLAC has no ID3 tag at all and takes the Vorbis branch with keys folded to lower case.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** the payload parses as Python under `ast.parse` in the self-test; the offset and the read route are both recorded in every `EnergyLevel` record.
- **Committed in:** `6d5ad6a`

**6. [Rule 3 - Blocking] `PREFLIGHT_WHY` was set but never read**
- **Found during:** Task 1 (`shellcheck -S warning`)
- **Issue:** SC2034. The blind-preflight reason was computed and discarded, so a refusal would have printed "blind" with no cause.
- **Fix:** the self-test prints it on the blind branch.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** `shellcheck -S warning` is clean.
- **Committed in:** `f3d6be1`

---

**Total deviations:** 6 auto-fixed (2 × Rule 2, 3 × Rule 1, 1 × Rule 3)
**Impact on plan:** all six are correctness or could-have-been-vacuous fixes inside the plan's own scope. Deviations 4 and 5 are the ones that matter: both were predicates that would have produced a confident answer while measuring nothing, which is the failure mode this plan exists to prevent.

## Issues Encountered

**The plan's own verify command would have failed on the plan's own prose.** Task 1's verify rejects `import --pretend` anywhere in an executable line. The first draft's `PC_WHY` message explained the control by naming the command it rejects — inside a shell string, which is an executable line. Reworded to "a `--pretend` transcript taken from the importer". Worth recording because the same trap waits for any future edit that tries to explain the D-33 finding in a runtime message rather than in a comment.

**`grep -qE '\bgenre\b[^s]'` was confirmed to fire before its zero result was trusted.** Given the three false-negative predicates this wave has already produced, the check was run against a planted `beet ls genre:rock` line (matched, 1) before its 0 against the script was read as clean. The same control was run for the `-1 - ` and `.N` predicates against planted positives *and* against the real 174-line fixture.

## Known Stubs

None. Every function the real run calls is implemented, and every one of them is driven by `--self-test`.

The one thing that is deliberately *not* done here is running the oracle against the sample — the plan says so explicitly, and plan 06-11 does it after this script's failure branches have been proven to fire. The remote layer is therefore written but unexercised against the live estate; its failure modes are bounded by `timeout`, by the dirty-destination refusal and by the `UNKNOWN` verdict, and the first live run is expected to surface adjustments in the `docker exec` argv quoting or the `beet ls -f` template if anything is going to.

## Threat Flags

None. The plan installs nothing, the script installs nothing, and every command it issues is either read-only or confined to `/tmp/p6` inside a container whose `/media` mount is asserted `RW=false` before anything runs.

## Next Phase Readiness

- **06-11 can run this script** once it has confirmed the four preconditions the header names (P1 one library, P2 `--set albumtype=dj` on S5, P3 `-s` on S7, P4 as-is with `write: no`) — all four are implemented here, so 06-11's job is to run `--baseline`, then `--run`, and record the verdict.
- **06-12 owns rule 2 (`albumtype:=dj disctotal:2..`), which this sample does not exercise.** Both drawn S5 folders resolve to rule 3; seven `dj-mixes` folders in the population carry `disctotal = 2`. That belongs in 06-12 as a named class assertion, not as a row in the committed tree — `06-SAMPLE.md` § "What this sample does NOT cover" item 1 says so and this script does not pretend otherwise.
- **Also untested by this sample, and flagged rather than discovered later:** `TKEY` and `TXXX:EnergyLevel` (zero of the 32 S5+S6 files carry either) and WAV (zero of the 174 files). The D-18 ledger implements all three branches; none of them will have anything to report on this draw, and *having nothing to report is different from not having looked*, which is why the records are emitted either way.
- **OQ-2 / C-6 remains open and is registered in the script itself:** `--set` is a CLI flag with no per-inbox equivalent in rc6's `InboxFolderSchema`, so Phase 6 proves the DJ *path rule*, not the *mechanism* by which a real flask-driven import would set `albumtype=dj`. Nothing in this script may be read as evidence for the latter.

## Self-Check: PASSED

- `scripts/phase06-oracle.sh` — FOUND
- commit `f3d6be1` — FOUND
- commit `6d5ad6a` — FOUND
- `bash -n` — OK
- `shellcheck -S warning` — clean
- `bash scripts/phase06-oracle.sh --self-test` — exit 0, 56 ✓, 0 ✗
- `grep -v '^[[:space:]]*#' … | grep -c 'import --pretend'` — 0
- `grep -n 'timeout $REMOTE_TIMEOUT.*|' … | grep -cv pipefail` — 0

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-21*
