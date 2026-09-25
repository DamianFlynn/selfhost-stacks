---
phase: 07-pilot-12-albums-end-to-end
plan: 02
subsystem: quality-gates
tags: [qual-02, diff-music-tags, d-11, d-12, ambiguous-join, self-test, fail-closed]
requires: []
provides:
  - "scripts/diff-music-tags.sh classifies divergent duplicate audio_md5 groups as AMBIGUOUS on BOTH sides and exits 3 UNKNOWN through BOTH output arms"
  - "a permanent 5-case `--self-test`, every case driven through the text arm and the --json arm"
  - "the first real-data census of the Phase 1 QUAL-01 capture: 828 duplicate groups = 514 identical + 314 divergent"
affects: [07-06, 07-09, 07-10, 07-11, 07-12]
tech-stack:
  added: []
  patterns: ["self-test drives the script as its own subprocess", "exit ladder 3 > 1 > 0 in both output arms", "dated in-place retraction (CORRECTED …) rather than deletion"]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-02-ambiguous-drive.txt
  modified:
    - scripts/diff-music-tags.sh
    - CONVENTIONS.md
decisions:
  - "Ambiguity is defined over the FLATTENED tag map including original key casing ((map(.t) | unique | length) > 1); identical duplicates collapse through `index` and never fire"
  - "Exit 3 (UNKNOWN) outranks exit 1 (loss) in both arms — a blind instrument wins over a measured red, the phase06-oracle.sh order"
  - "Every self-test case runs through BOTH the text and --json arms rather than adding separate --json cases, so ST_PLANNED_CASES stays 5"
  - "A self-diff of the full Phase 1 capture now exits 3 (314 AMBIGUOUS keys) where it exited 0 — the correct reading, not a regression"
metrics:
  duration: "~25 min"
  completed: 2026-09-25
  tasks: 3
  files: 3
---

# Phase 7 Plan 02: diff-music-tags Fails Closed on an Ambiguous Join Summary

QUAL-02's diff script used to keep whichever duplicate record came last. It now names every
`audio_md5` whose duplicate records carry differing tag maps, on the BEFORE side and on the AFTER
side, and exits 3 UNKNOWN through both the text and the `--json` arm. This was proven red, then
green, on five fixtures. It was then proven on the real Phase 1 capture, where it fired on 314
real groups and stayed quiet on 514 identical ones.

## What was done

- **Task 1: `--self-test` (commit `506f74f`).** Five fixture pairs in the `emit_record` shape
  (A: identical duplicate → 0; B: divergent duplicate on BEFORE → 3; C: divergent duplicate on
  AFTER only → 3; D: plain loss → 1; E: loss plus ambiguity → 3). Each pair is driven as a
  subprocess of the script itself (`bash "$0" …`), through `--summary-only` and again through
  `--json`, and both exit codes must match. The fixtures go under `$PWD` in a
  `mktemp -d .diff-music-tags-selftest.XXXXXX` directory. They are removed by an `rm -rf` fenced at
  its call site: non-empty, absolute, basename-pattern. The **RED step** was observed before the
  fix: A and D passed, while B exited 0, C exited 0 and E exited 1. B is the defect exactly: the
  TKEY-bearing record is first, so last-wins drops it. CONVENTIONS §5 gained the
  `ST_PLANNED_CASES` pin in the same commit.
- **Task 2: the fix (commit `0e3775f`).**
  - `JOIN_JQ` gains `def ambiguous`, applied to `$B` and `$A`. The fix adds
    `counts.ambiguous_before/_after` and the `ambiguous_before/_after` arrays.
  - The exit ladder is 3, then 1, then 0 in both arms. The green line sits textually after both
    checks. The exit-3 message says UNKNOWN in words and names the keys.
  - The header now lists exit 3 and a PRECEDENCE paragraph.
  - Both "never affects / does not affect the exit code" sentences are still there, each followed
    by `CORRECTED 2026-09-25, plan 07-02, D-11`.
  - The summary prints `AMBIGUOUS_BEFORE:` and `AMBIGUOUS_AFTER:`. The empty-BEFORE counter is
    unchanged.
  - The self-test now passes 5/5, 4 of them red by design.
- **Task 3: the real-data drive on LXC 100 (commit `d4de9a0`).** The Phase 1 capture was copied to
  `/mnt/fast/safety/phase07/diff-drive/`. The committed script was scp'd alongside it, and the
  sha256 matched on both ends (`4bbfaf60…`). The host `--self-test` passed 5/5 on bash 5.2.37 and
  jq 1.7. The self-diff of the capture read 9736 records and 8672 keys, and exited **3 on both
  arms**. `duplicate_keys_before` was 828 and `AMBIGUOUS_BEFORE` was 314. An independent jq census
  computed **514 identical + 314 divergent = 828**. The run took about 3.2 s. The capture's sha256
  was `7b3a09ae…` both before and after. The copy was removed by an exact-path-fenced `rm`.

## Real-data finding the pilot must carry

The arm fired on raw real data, so no real-derived positive was needed. 282 of the 314 divergent
groups pair `dj-mixes` with `unsorted`, which is the DUPE-01 overlap. The other 32 lie entirely
within `unsorted`. The fields that differ are mostly genre, album, album_artist, title, track and
artist. Before this plan, the literal "self-diff returns zero differences" check passed on this
capture while comparing those 314 keys against whichever record the walk emitted last. Any QUAL-02
BEFORE capture that spans both roots of a DUPE-01 pair will now read UNKNOWN. That is the control
that D-13's amended `unsorted` rule depends on, and it is doing its job. Plans 07-06, 07-10 and
07-11 should scope their captures with this in mind.

## Verification

- All three `<automated>` verify blocks passed.
- Comment-stripped `/tmp/` grep: the control line returned 1 and the script returned 0.
- No `.diff-music-tags-selftest.*` or `.diff-music-tags.*` scratch was left behind, on the
  workstation or on the host.
- shellcheck 0.11.0 reports 3 findings, all severity info: SC2329 and SC2016 ×2. The same 3 are
  present on the pre-plan file, so this plan introduced none. It is not clean.
- A manual `--json` drive of a divergent pair exits 3. A self-diff of an unduplicated fixture exits
  0, and an unknown option exits 2.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `bc` absent on LXC 100.**
- **Found during:** Task 3.
- **Issue:** the step 5/6 wall-clock lines failed with `bc: command not found`. The exit codes were
  unaffected.
- **Fix:** step 8 re-timed both arms with integer `date +%s%N` arithmetic.
- **Record:** both the failure and the re-run are kept in the artifact.

**2. [Rule 1 - Bug, in my own census program, not the script] The census failed twice.**
- **Found during:** Task 3.
- **Issue:** the census's field-breakdown expression indexed `.t[.]` with the record instead of the
  key. A local sed fix then failed on its own quoting, so attempt 2 re-ran the unmodified program.
- **Fix:** attempt 3 applied the fix with Python. The census program's sha256 is recorded.
- **Record:** all three attempts are kept in the transcript.

**3. [Scope add] Removed the `--json` output file too.** The `--json` output file
(`counts.json.part`) was removed alongside the copy, under its own exact-path fence. Left on the
host: `diff-music-tags.sh` and `census.jq`, which are small and kept for reproducibility.

The rest of the plan was executed as written. QUAL-02 was **not** marked complete in
REQUIREMENTS.md, because this plan hardens the gate and no import has run through it yet.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: scripts/diff-music-tags.sh, CONVENTIONS.md, artifacts/07-02-ambiguous-drive.txt
- FOUND commits: 506f74f, 0e3775f, d4de9a0
- 823fe04 remains an ancestor of HEAD
