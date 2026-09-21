---
phase: 06-tagger-configuration-and-dry-run
plan: 15
subsystem: testing
tags: [beets, shell, health-checks, d-04, fail-closed, self-test, docker-exec]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "the D-04 rule as plan 06-10 wrote it into scripts/quick-health-check.sh, and check-beets-config.sh as plans 06-01/06-07 left it"
provides:
  - "check-beets-config.sh's three `beet` invocations are D-04 compliant: `-l /tmp/p6-cbc-throwaway.blb` ahead of `-c ${OVERLAY}` on all three"
  - "measured evidence that the redirect took effect — the throwaway library EXISTS in the container, so the real /config/library.db was never OPENED, not merely never changed"
  - "arm 2's no-op overlay is truncated and MEASURED at 0 bytes, with two fail-closed branches, both driven red against the live estate"
  - "a sixth --self-test case that asserts the `-l` + `-c` contract over the script's OWN SOURCE, proven falsifiable"
  - "a READ-ONLY BY CONTRACT header that names its one write instead of denying it"
affects: [06-16, 06-17, 06-18, 06-19, 06-20, 06-21, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "source-level self-test case: when the assertion function is pure over data and cannot see the thing that was fixed, assert over the script's own text instead"
    - "detector-out-of-its-own-haystack: build every pattern literal from a `d='$'` variable so a source-scanning checker never matches its own pattern lines"
    - "truncate-then-MEASURE: a file that is merely present is not a file that is empty; assert the size before using it"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-15-check-beets-config-rerun.txt
  modified:
    - scripts/check-beets-config.sh

key-decisions:
  - "expect_ne is RETAINED and CALLED (not deleted) — the UK check routes through it, and the load-bearing sentence survives word for word"
  - "The UK check moved inside the readable-list branch, so an absent match.preferred.countries is counted once rather than twice; this is what keeps all five existing self-test red counts unchanged"
  - "The overlay uses a `: >` shell redirect rather than `truncate -s 0` — no coreutils dependency inside the container"
  - "The overlay-emptiness guard's SIZE branch cannot be driven by pre-writing the file (the script truncates before it measures), so it is driven against a `touch`-mutant COPY instead, which is exactly the defect WR-04 described"

patterns-established:
  - "Two fail-closed branches, two drives: 'could not look' and 'looked, and it was not right' are different findings and each needs its own driven red"
  - "Derive verdict lines in an artifact from the captured transcript, never type them, so the summary cannot drift from the evidence"

requirements-completed: [CONF-01, CONF-02, CONF-05]

# Metrics
duration: 18min
completed: 2026-09-21
---

# Phase 6 Plan 15: check-beets-config.sh D-04 compliance Summary

**The script this phase committed to *read* the beets config no longer opens the real `library.db` — all three `beet` invocations carry `-l /tmp/p6-cbc-throwaway.blb`, the throwaway now measurably exists in the container, and arm 2's no-op overlay is truncated and asserted 0 bytes with both fail-closed branches driven red live.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-09-21T23:25Z
- **Completed:** 2026-09-21T23:42Z
- **Tasks:** 3
- **Files modified:** 2 (one script, one artifact) — matching the plan's own `git diff --stat` expectation exactly

## Accomplishments

- **CR-01's live half is closed for the right reason.** The three invocations became compliant, so the D-29 layer-3 hash comparison upgrades from *proving nothing changed* to *corroborating that nothing was opened*. Fixing only the detector (plan 06-16) would have turned this phase's own deliverable red.
- **The redirect is MEASURED, not assumed.** `/tmp/p6-cbc-throwaway.blb` exists in the container, beetle-owned, carrying a beets schema — beets could only have created it by opening that path instead of `/config/library.db`, whose mtime is days older than every run in the artifact.
- **WR-04 closed with a driven negative against exactly the defect it described.** `touch` guaranteed existence, not emptiness. The create now truncates *and the size is asserted*, and the proof is a `touch`-mutant copy run against a planted 44-byte overlay: the new size assertion catches what `touch` alone let through, and no `config` call is issued.
- **The self-test grew a case that can actually fail.** The five existing cases drive a pure function over a synthetic dump and are structurally blind to an invocation flag — so the fix was invisible to the script's own control. Case 6 reads the file's own source; stripping `-l` from one real invocation takes it to 2 red and `--self-test` to exit 1.
- **Four hygiene findings retired** (IN-01, IN-03, IN-04, IN-07) in the file that was about to be re-run and re-proved anyway.

## Task Commits

1. **Task 1: D-04 compliance + provably-empty overlay + honest header** — `8d74d40` (fix)
2. **Task 2: four hygiene findings + the sixth self-test case** — `4aaf79a` (fix)
3. **Task 3: live re-proof with both guard branches driven** — `1e7103b` (docs)

## Files Created/Modified

- `scripts/check-beets-config.sh` — `THROWAWAY_DB` plain constant; `-l` on all three invocations; truncate-and-measure overlay guard; header names its one write; `expect_ne` called; readiness arithmetic corrected; glob-free substring loop; `beet_invocation_violations()` + `assert_beet_invocation_contract()` and self-test case 6.
- `.planning/phases/.../artifacts/06-15-check-beets-config-rerun.txt` — 480 lines: six-case self-test with case 6's red quoted, the post-change live run at exit 0, both D-29 comparisons stated as the two separate claims they are, the throwaway-library measurement with its interpretation, both guard branches driven red and restored to green, and the before/after sha256 of the unchanged script.

## Decisions Made

**`expect_ne`: RETAINED AND CALLED, not deleted.** `grep -c '\bexpect_ne\b'` now returns 4. The `UK` check routes through it and the load-bearing sentence — *"MusicBrainz stores GB, so UK matches nothing and fails SILENTLY: the import simply prefers a different release"* — is byte-present and preserved word for word. Recorded explicitly because the plan asked for this choice by name.

**The throwaway-library measurement: the file EXISTS.** `-rw-r--r-- 1 beetle beetle 53248 /tmp/p6-cbc-throwaway.blb`. Recorded explicitly because plan 06-16 pins an exemption baseline that assumes these three lines are compliant — they are, and the artefact on disk corroborates it rather than the flag alone. The artifact states what the *absent-file* answer would have meant too, because that answer was acceptable for a `config` subcommand and was not pre-judged.

**`: >` rather than `truncate -s 0`.** A POSIX shell redirect needs nothing installed in the container; `truncate` is coreutils and its presence in `beets-flask` was never measured. The plan's acceptance criteria permit either.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] The plan's task-1 verify command contained a pattern that can never match on this estate's workstation**

- **Found during:** Task 1
- **Issue:** The truncate check was written `grep -qE "truncate -s 0|> *\$\{OVERLAY\}"` inside a double-quoted bash string. Bash collapses `\$` to `$`, and BSD grep — macOS, which is where this script runs — reads that `$` as an end-of-line **anchor** in the middle of the alternative, which can never match. The `truncate -s 0` alternative works; the `>` alternative was dead. Under GNU grep it would have passed, so this is a silent platform split: the check would look fine on Linux CI and be vacuous on the machine that actually runs it.
- **Fix:** Single-quoted the pattern so `$` stays literal. Same intent, a pattern that can fire. Verified by probe: plan pattern MISSES the real line, corrected pattern MATCHES.
- **Verification:** `06-15 task 1 OK` after the correction; the probe output distinguishing the two is in the scratchpad reasoning, and the correction is commented in-line in the verify script.

**2. [Rule 1 — Bug] The plan's task-3 verify demanded a string `check-beets-config.sh` cannot emit**

- **Found during:** Task 3
- **Issue:** The verify greps the artifact for the literal `FAILURES total: 0`. The script column-pads its summary (`FAILURES total:              0`), so that literal never appears in any transcript. A verify that can only fail is as bad as one that can only pass.
- **Fix:** Added a **derived** verdict line to the artifact, parsed out of the captured transcript rather than typed, in the same shape `06-07-effective-config.txt` already uses: `Script verdict: EXIT 0, FAILURES total: 0, arm-1 assertion failures: 0, arm 1 blind: 0`. The padded transcript line is present verbatim as well, so both readings are available.
- **Verification:** `06-15 task 3 OK`.

**3. [Rule 1 — Bug] Routing the UK check through `expect_ne` unguarded would have broken the plan's own "counts unchanged" requirement**

- **Found during:** Task 2
- **Issue:** `expect_ne` fires a red on `UNKNOWN`. For an empty dump, `has_gb` and `has_uk` are *always* UNKNOWN together (they are two readings of one key), so the empty-dump case would have gone from 22 red to 23 — contradicting the plan's instruction to keep all five existing counts unchanged, and double-counting one absent key as two findings.
- **Fix:** The UK check moved **inside** the readable-list branch. An unreadable `match.preferred.countries` goes red once, for the list; the UK sub-check is only reached when there is a list to examine. `expect_ne` is still called, its message is still preserved, and all five counts are unchanged (22, 1, 1, 2, 0).
- **Verification:** `--self-test` reports `all 6 cases behaved as expected (5 of them red)`; each case's individual count is checked by the harness.

**4. [Rule 3 — Blocking] Task 3's driven red as specified cannot drive the branch it targets**

- **Found during:** Task 3
- **Issue:** The plan says to *"write a single non-empty line into `${OVERLAY}` … re-run the script, and require it to refuse arm 2"*. That cannot work: the script **truncates the overlay before it measures it**, so any pre-planted content is erased by the script's own first action and the size branch is unreachable from outside. Following the instruction literally produces a green run and a false claim that the branch was driven.
- **Fix:** Drove **both** fail-closed branches instead, and kept them distinct per README § Health Checks rule 1:
  - **Branch A (could not look):** the overlay path is replaced by a *directory* (created and removed as `beetle`, so fully reversible without root), making the `: >` redirect fail. Script exits 1 with `ARM 2: UNKNOWN, not green — could not truncate…`, `CONFIG_ROUTE_CLI: unavailable`, and no `config` call.
  - **Branch B (measured non-empty):** a **copy** of the script with the old `touch` restored, run against a planted 44-byte overlay. Script exits 1 with `…measured '44' bytes, not 0 … No 'config' call was issued.` This drives the branch against precisely the regression WR-04 described.
  - The restored-green run then clears that same stale overlay with **no cleanup command in between**, so the fix itself is what tidies up.
- **Verification:** exit 1 / exit 1 / exit 0 respectively, all three transcripts in the artifact; the repo script's sha256 is byte-identical either side (both perturbations ran against scratchpad copies).

**5. [Rule 1 — Bug, in this plan's own driver] A quoting error made the first branch-B drive a false green**

- **Found during:** Task 3
- **Issue:** The command that plants the non-empty overlay was wrapped in `sh -c '…'` but itself contained single quotes, so the wrapper closed early and the remote ran something else — `rc=0`, output `directory:`, and the overlay left at **0 bytes**. The mutant then correctly reported an empty overlay and exited 0. Every signal looked like "the guard is fine"; nothing had been perturbed. This is the same defect class this repo has been bitten by four times: a check satisfied by something *other than the thing*.
- **Fix:** `rex()` now **refuses** any remote command containing a single quote rather than emitting a mangled one, and the plant is **confirmed by measurement** (`44 bytes`) before the run that depends on it — printed into the artifact, because a drive that silently failed to perturb anything looks exactly like a guard that works.
- **Verification:** branch B now exits 1 with the `measured '44' bytes` refusal.

### Ordering deviation (not a fix)

**IN-04 landed in task 1's commit (`8d74d40`), not task 2's.** The header paragraph naming the non-existent `EXEC_USER` is the same paragraph task 1 had to rewrite to document `THROWAWAY_DB` as a plain constant (T-06-62). Leaving a known-wrong constant name inside a paragraph being rewritten was not defensible. Task 2's verify still checks and passes it.

---

**Total deviations:** 5 auto-fixed (4 × Rule 1 bug, 1 × Rule 3 blocking) + 1 ordering note
**Impact on plan:** No scope creep — every fix was inside the two files the plan named. Three of the five were defects in the plan's own verification commands or drive instructions, which is worth noting: each would have produced a *vacuous pass*, the exact failure mode this gap-closure exists to remove.

## Issues Encountered

None beyond the deviations above. The estate was reachable throughout; no checkpoint was needed.

## Verification Results

| Check | Result |
|---|---|
| `bash -n` | clean |
| `shellcheck -S warning` (0.11.0) | clean |
| `--self-test` | exit 0, `all 6 cases behaved as expected (5 of them red)` |
| Case 6 falsifiability (mutant copy, `-l` stripped) | exit 1 — the case **can** fail |
| Live run, post-change | exit 0, `FAILURES total: 0`, `arm 1 blind: 0`, 23 assertions green |
| D-29 layer 3, within this run | identical (`fbbdde0c…` / `f6a9a1ad…`) |
| D-29 layer 3, vs 2026-09-21T22:04Z run | identical on both 8-char prefixes beets.md records |
| Overlay guard branch A | driven red, exit 1, no `config` call |
| Overlay guard branch B | driven red, exit 1, no `config` call |
| Restored live run | exit 0 |
| Script sha256 either side of perturbation | equal |
| Compliant invocations, comment-stripped | exactly 3 |
| `git diff --stat` vs base | 1 script + 1 artifact |

## Known Stubs

None. Every branch added by this plan is driven — case 6 against a synthetic negative and a mutant copy, both overlay branches against the live estate.

## Notes for plan 06-16

- **The three lines are compliant and stay compliant under the widened D-04 pattern.** They read `${BEET_BIN} -l ${THROWAWAY_DB} -c ${OVERLAY} config …`, with `-l` first so a reader scanning for it finds it before the subcommand.
- **One thing to check when widening the grep's SCOPE.** This plan's artifact (`.planning/…/06-15-check-beets-config-rerun.txt`) necessarily quotes two non-compliant strings as *evidence*: the synthetic `beet_exec "${BEET_BIN} -c ${OVERLAY} config -d"` that case 6 rejects, and the mutation line `beet_exec "touch ${OVERLAY}"`. Today's D-04 scope is *tracked text files under `scripts/` and `stacks/`, minus `*.md`*, so `.planning/` is outside it and nothing trips. If 06-16 widens the scope as well as the pattern, these two lines need the same treatment `beets.md`'s historic quotations get — counted against a pinned baseline, not rewritten, because rewriting evidence to satisfy a grep falsifies the record.
- **`check-beets-config.sh` now contains a source-scanning checker of its own.** Its patterns are assembled from a `d='$'` variable specifically so neither it nor the repo-wide D-04 grep matches the detector's own pattern lines. Keep that property if the file is edited.

## Next Phase Readiness

- CR-01's live half is closed; the detector half is plan 06-16's job and is unblocked.
- WR-04, WR-05, IN-01, IN-03, IN-04 and IN-07 are retired.
- No blockers. `STATE.md` and `ROADMAP.md` deliberately untouched — the orchestrator owns those after the wave merges.

## Self-Check: PASSED

All three files exist on disk; all four commits (`8d74d40`, `4aaf79a`, `1e7103b`, `2e0fb5f`) resolve in `git log`. Claims re-checked against the tree rather than restated: `expect_ne` appears 4 times (retained and called), the preserved UK sentence is byte-present, the throwaway-library measurement (`53248`) appears in the artifact, exactly 3 compliant invocations survive comment-stripping, and `git status --porcelain` is empty.

---
*Phase: 06-tagger-configuration-and-dry-run, plan 15*
*Completed: 2026-09-21*
