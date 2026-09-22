---
phase: 06-tagger-configuration-and-dry-run
plan: 16
subsystem: testing
tags: [beets, shell, health-checks, d-04, fail-closed, vacuity-guard, exemption-register, wr-10, in-13]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "the D-04 block as plan 06-10 wrote it, and plan 06-15's three now-compliant check-beets-config.sh invocations"
provides:
  - "a D-04 assertion that matches the variable-built `beet` invocations this repo actually makes — executable count 0 -> 8, measured"
  - "a vacuity guard: a zero executable count is UNKNOWN and fatal, never a green tick"
  - "a NAMED, COUNTED and PINNED exemption register (D04_EXEMPT_RE / D04_EXEMPT_BASELINE=5) so an unasserted invocation cannot arrive in silence"
  - "WR-10: a `timeout` kill on the D-04 scan reports as a bound expiry, not as `git grep` having failed"
  - "IN-13: D03_REPO_ROOT, so the D-03 CLI-render `exit 3` branch is driveable"
  - "a NOT-DRIVEN list (six items) for plan 06-21's disposition register"
affects: [06-17, 06-19, 06-21, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "widen the REMOTE pattern with a second `-e`, never an alternation, when the command string must stay free of `|`"
    - "command-position + follower test: a variable-as-command is an invocation only if anchored AND followed by a flag or subcommand; anchor alone admits `[[ $X -eq 0 ]]`, follower alone admits argument passing"
    - "every printed count is either asserted or pinned — a number that is printed but not tested is a decoration, not an assertion"
    - "drive a detector against a host SCRATCH checkout rather than deploying unmerged work to make a count line up"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-16-d04-driven.txt
  modified:
    - scripts/quick-health-check.sh
    - stacks/selfhosted/arrs/beets.md

key-decisions:
  - "The REMOTE grep had to widen too — the plan specified only the local regex, but `git grep -w -E 'beet'` is case sensitive and never returned a single `$BEET_BIN` line, so the local widening alone would have pinned the new guard to a permanent UNKNOWN"
  - "The oracle's exemption key is `$SCRATCH_OVERLAY`, not the plan's `$SCRATCH/overlay.yaml` — that string does not exist in the file"
  - "NOT pushed and pulled: a `git pull` on LXC 100 would have deployed the whole of unmerged Phase 6 to the live estate to make a health-check count line up. A host scratch checkout was used instead, which is D04_REPO_ROOT's documented purpose"
  - "The documentation pin was left at 2 when this plan's own runbook prose tripped it — raising it would have retired the check on its first use"

patterns-established:
  - "When a plan's verify cannot fail, fix the verify and pin the honest invariant instead of the aspirational one"
  - "Record a NOT-DRIVEN list: what was asserted by construction is not what was observed firing, and conflating them is how a vacuous check survives"

requirements-completed: [CONF-01, CONF-02, CONF-03]

# Metrics
duration: 70min
completed: 2026-09-22
---

# Phase 6 Plan 16: the D-04 detector, made able to fail Summary

**The D-04 assertion asserted over an empty set for the whole of Phase 6 and printed a green tick saying so; it now sees all 8 variable-built invocations, refuses a zero as UNKNOWN, names and pins the 5 it does not assert over, and was driven red six times live.**

## Performance

- **Duration:** ~70 min (including a mid-run restart after a transient API 529)
- **Completed:** 2026-09-22T06:30Z
- **Tasks:** 3
- **Files:** 2 modified, 1 artifact created — `754 insertions(+), 14 deletions(-)` against base `ce9bb5d`

## Accomplishments

- **The defect is reproduced live, with no overrides, on the deployed estate.** The pre-fix and post-fix scripts were run against `/mnt/fast/stacks` in the same minute:
  - pre-fix: `✅ no executable beet invocation opens the real library (0 invocation-shaped lines outside *.md)`
  - post-fix: `⚠️  UNKNOWN — the invocation pattern matched NO executable line (0)`

  The old green line states its own emptiness in its own text and calls it a pass. That is the whole finding, and it is now two transcripts rather than an argument.
- **Executable invocation count 0 → 8**, hand-reproduced from the host and agreeing with the block's printed figures at **every position on both trees** (191 / 90 / 10 / 8 = 3 + 5 / 2 on this plan's tree; 46 / 26 / 2 / 0 / 2 on the deployed tree). No disagreement anywhere.
- **All three asserted lines are 06-15's, and all three are compliant** — the exemption baseline of 5 assumed `check-beets-config.sh` was compliant rather than exempt, and it is.
- **Six branches driven**, five planned and one unplanned. The unplanned one is the best evidence in the plan: the explanatory sentence written for `beets.md` *about* this fix was itself an invocation shape and took the documentation count to 3 against its pin of 2.
- **Three findings retired:** CR-01's detector half, WR-10, IN-13.

## Task Commits

1. **Task 1: widened pattern, vacuity guard, pinned exemption register, ELEVENTH notice** — `5f4d0c0` (fix)
2. **Task 2: IN-13, the overridable D-03 render root** — `18b06a5` (fix)
3. **Task 3: six live drives, the artifact, and the runbook quoted back into step** — `8ec9a1d` (docs)

## Files Created/Modified

- `scripts/quick-health-check.sh` — remote scan widened with a second `-e`; `D04_INV_RE` fourth branch; `elif [ "$D04_N_EXE" -eq 0 ]` vacuity guard; `D04_EXEMPT_BASELINE` + `D04_EXEMPT_RE` + the exempt/asserted partition; exempt count on the `counts:` line and the green line; WR-10's 124-before-`-gt 1` ordering; `D03_REPO_ROOT`; the ELEVENTH exit-code notice.
- `stacks/selfhosted/arrs/beets.md` — the superseded 2026-09-21 row kept verbatim under a dated correction; both new patterns quoted byte-identically (verified by extracting them from the script and matching); measured counts; the exemption register with all three reasons.
- `artifacts/06-16-d04-driven.txt` — 477 lines: the scratch-checkout decision and its cost, hand counts vs block counts for both trees, six drives with before/after sha256, the pre-existing red named, and the NOT-DRIVEN list.

## Decisions Made

**The remote grep had to widen, and the plan did not ask for it.** The plan's Edit 1 says the regex "is evaluated LOCALLY … so adding an alternation branch carries no pipe into the remote command". True, but it presupposes the remote grep returns those lines. It does not: `git grep -w -E 'beet'` is **case sensitive**, and every invocation in this repo is `$BEET` / `$BEET_BIN`. Measured: of the 8 executable invocation-shaped lines, the old remote pattern returns **zero**. Widening only the local regex would have left `D04_N_EXE` at 0 and turned the new vacuity guard into a permanent UNKNOWN — the exact failure the plan's own objective warns about. Fixed with a **second `-e`** rather than an alternation, so no `|` enters the command string and the `timeout $REMOTE_TIMEOUT.*|` invariant is untouched (measured unchanged).

**The oracle's exemption key is `$SCRATCH_OVERLAY`.** The plan specifies `$SCRATCH/overlay.yaml`; that string does not appear in `phase06-oracle.sh`. The plan's line citations were also stale by ~200 lines (`:1970/:1983/:2102` → `:2166/:2179/:2313`; `:419/:421` → `:462/:464`). Found by `grep -n` on anchor text, per the standing note that this phase's citations go stale.

**The invocation shape needs BOTH an anchor and a follower test.** Measured: the naive "preceded by whitespace or a quote" form matches **26** lines, **18** of which run nothing (`[[ $BEET_EXEC_RC -eq 0 ]]`, `"$BEETS_DB_COUNT"`, `remote_exec … "$BEET" "$PY"`). Command-position anchoring alone still admits `"$BEETS_DB_COUNT" == "1"`; the follower test alone still admits the `[[ ]]` tests. Together they give exactly 8. The follower test deliberately admits a **bare** subcommand with no flags, so it cannot be accused of only matching invocations that were already compliant.

**Not pushed, not pulled — and this is the one decision worth challenging.** The plan's task 3 says "Push and pull first … or the whole artifact measures the wrong tree." The host is at `c67d497`, pre-Phase-6. Complying would have meant pushing a worktree branch past the orchestrator's merge and then deploying **all of unmerged Phase 6** to the live estate in order to make a health-check count line up. A host scratch checkout at `/tmp/p6-16-scratch` was used instead — which is what `D04_REPO_ROOT` documents itself as existing for ("how plan 06-10 drove those branches to red and back to green without touching the estate"). The estate ended at `c67d497` with no new dirty entries and all `/tmp/p6-16*` removed.

**The cost of that choice is stated rather than hidden:** `D04_REPO_ROOT` is additive, so every scratch-backed run is barred from printing green. **The ✅ line is therefore asserted by construction, not observed** — and it is not observable by any route today, because against the real tree the executable count is genuinely 0. See N-1.

**The documentation pin stayed at 2.** See deviation 4.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] The remote scan pattern could not return the lines the plan asked the local regex to match**

- **Found during:** Task 1, before any edit
- **Issue:** `git grep -n -I -w -E 'beet'` is case sensitive. The five variable-built invocation sites the plan names were never in the haystack. Widening only `D04_INV_RE` would have produced `D04_N_EXE=0` and a permanently-UNKNOWN block.
- **Fix:** Added `-e 'BEET[A-Z_]*'` as a **second pattern** (not an alternation — that would put a `|` in the remote command string and trip the file's own invariant).
- **Verification:** raw 110 → 191 on this plan's tree; executable 0 → 8. Both measured before and after.

**2. [Rule 1 — Bug] The plan's task-1 invariant check is vacuous on this workstation, and its acceptance criterion was never satisfiable**

- **Found during:** Task 1
- **Issue:** Two separate defects in one line. (a) `grep -n "timeout \$REMOTE_TIMEOUT.*|"` inside a double-quoted bash string: BSD grep (macOS — where this script runs) reads a bare mid-pattern `$` as an anchor, so the pattern matches **0** lines. Measured: unescaped → 0 matches, `\$`-escaped → 8. This is the same platform split 06-15 hit. (b) With the pattern corrected it returns **5** lines, not zero — three documented pre-existing false positives plus two comment lines that quote the pattern verbatim. The criterion "returns only lines also containing `pipefail` or ending in `grep -q`" was false on the **base commit** too.
- **Fix:** Single-quoted the pattern and replaced the aspirational assertion with the honest one: the count of **non-comment** unguarded matches is pinned at **3** and must not move. Measured on base and on the result: `8 / 5 / 3` both times — this edit moved nothing.
- **Verification:** `p16-invariant.sh` run against both files side by side.

**3. [Rule 1 — Bug] Both the plan's verifies reach their verdict through the pipefail/SIGPIPE shape this phase has been bitten by three times**

- **Found during:** Tasks 1 and 2
- **Issue:** `printf … | grep -q` and, worse, `awk … | grep -n | head -1 | grep -q .` — `head` closing the pipe can propagate 141 and fire the FAILURE branch on a correct file. A false-RED generator.
- **Fix:** Both verifies rewritten over temp files; no early-exit consumer in any pipeline. Also **strengthened** rather than merely repaired: the task-1 verify now extracts `D04_INV_RE` and `D04_EXEMPT_RE` **from the script** and runs them over a real scan, asserting executable > 0, exempt = 5, asserted = 3, every asserted line compliant, and that no line of `quick-health-check.sh` matches its own pattern (06-15's detector-out-of-its-own-haystack property, preserved and now tested).
- **Verification:** Falsifiability proven by running the same extraction against the base file — base yields `exe=0` ("vacuity guard would fire"), result yields `exe=8`.

**4. [Rule 1 — Bug, in this plan's own output] The runbook prose written to describe the fix was itself a copy-pasteable bare invocation**

- **Found during:** Task 3
- **Issue:** The sentence `> a **bare** `"$BEET" config`, so it cannot be accused…` is, character for character, an invocation shape under the branch this plan had just written. Documentation count went **2 → 3** against a pin of 2 — a red.
- **Fix:** The sentence was **rephrased** and `D04_DOC_BASELINE` was **left at 2**. Raising the pin to accommodate the first thing it caught would have retired the check on its first use. The distinction from the two historic quotations at `beets.md:106`/`:170`, which *are* kept verbatim, is that those are the Nov-2025 record; this sentence was written today and is a record of nothing. The incident and the reasoning are in the runbook itself and in artifact section 5.
- **Verification:** 2 → 3 → 2, measured each time.
- **Why it matters:** this is the strongest evidence in the plan that the detector works, because nobody wrote that line to be caught.

**5. [Rule 1 — Bug] The plan's exemption key for the oracle does not exist in the file**

- **Found during:** Task 1
- **Issue:** The plan specifies keying on `$SCRATCH/overlay.yaml`; `phase06-oracle.sh` uses `$SCRATCH_OVERLAY`. A register built on the plan's string would have matched nothing and the exempt count would have been 0 against a pin of 5 — a permanent red.
- **Fix:** Keyed on the real substring. Same for the stale line citations throughout.
- **Verification:** exempt = 5, naming the five intended lines.

### Ordering deviation (not a fix)

**WR-10 landed in task 1's commit (`5f4d0c0`), not task 2's.** The 124 test and the pattern widening both edit the same six-line `D04_CMD` string; splitting them would have meant editing one line twice. Task 2's verify still checks and passes it.

### Over-strict check of my own, corrected

My first hardened task-2 verify demanded the awk range's **end** delimiter be globally unique. `^exit 0"` occurs twice in the file. That is harmless here because the **start** delimiter is unique and awk closes at the first end match after it; the check was relaxed to assert start-uniqueness plus a length bound on the extract. Recorded because the distinction (a recurring **start** is what makes a range run away, per 06-20) is the useful part.

---

**Total deviations:** 5 auto-fixed (4 × Rule 1, 1 × Rule 3) + 1 ordering note + 1 self-correction
**Impact on plan:** No scope creep — every change is inside the three files the plan named. **Three of the five were defects that would have produced a vacuous or false-red check**, in a gap-closure plan whose entire purpose is removing a vacuous check. Deviation 1 would have left the block permanently UNKNOWN; deviation 5 would have left it permanently red.

## Issues Encountered

A transient API 529 terminated this executor mid-task-3, after the artifact was written but before `beets.md` was finished. No work was lost — both prior tasks were already committed, the worktree was intact, and the run resumed from the rephrase that was in flight.

## Verification Results

| Check | Result |
|---|---|
| `bash -n` | clean |
| `shellcheck -S error` | clean |
| Notice headers / raw | 11 / 14 (measured 10 / 13 before) |
| Remote-pipeline invariant, non-comment unguarded | 3 — **unchanged from base** |
| Functional: executable / exempt / asserted | 8 / 5 / 3 |
| Every asserted line compliant | yes (3 of 3) |
| Detector matches its own pattern? | no — property preserved |
| Hand count vs block count, both trees | agreement at **every** position |
| Control 1 — real violation | ❌ exactly one red naming it; removed; scratch sha256 equal |
| Control 2 — vacuity guard | ⚠️ UNKNOWN; raw/stripped unchanged 191/90; repo file sha256 equal |
| Control 3 — exemption pin | ❌ naming all 5; no pass produced |
| Control 4 — WR-10 124 | **DRIVEN**; negative control shows pre-fix says `ssh exit 4` |
| Control 5 — IN-13 `exit 3` | **DRIVEN**; UNKNOWN, not a pass |
| Control 6 — doc pin (unplanned) | condition measured 2 → 3 → 2; pin not raised |
| Repo `git status --porcelain` | empty at every checkpoint |
| Estate HEAD after all work | `c67d497`, unchanged; all `/tmp/p6-16*` removed |

## NOT DRIVEN — asserted by construction, for plan 06-21's disposition register

Full text in artifact section 6.

| id | claim | why not observed |
|---|---|---|
| N-1 | the **✅ green line** | not demonstrable by any route today — against the real tree the executable count is genuinely 0 (guard correctly refuses); against a scratch tree the override correctly refuses. All four conditions it requires were measured satisfied; `D04_OVERRIDDEN` is the only remaining gate and its three assignments each also set `EXIT_CODE=1` |
| N-2 | the **`EXIT_CODE=1` contribution** of the two new fatal conditions | both MESSAGES observed firing live; the exit status could not be isolated because the standing Phase 5 `interpolated-host-path` red forces exit 1 in every run. Asserted structurally by the task-1 verify |
| N-3 | the **`-l /config/library.db`** sub-condition | control 1 drove the missing-`-l` half of the same `if`; this route into the shared branch was not. Pre-existing logic |
| N-4 | the **overlay-key half of `D04_EXEMPT_RE`** | control 1's planted line went into a *third* file, proving the register does not swallow arbitrary files but not the per-line keying *inside* the two exempt files. **The weakest link in the register and the obvious next drive** |
| N-5 | the **sentinel** and **`exit 3`** branches of the D-04 scan | pre-existing, untouched, not re-driven. Note the sentinel's `-ne 124` case only became meaningful with WR-10 |
| N-6 | the **doc-pin red as captured block output** | the condition was measured via the script's own extracted regexes, not captured from a live run with the offending line at a scanned HEAD |

## Known Stubs

None. Every branch this plan added was driven except where listed above, and each exception is named with its reason rather than left implicit.

## Notes for the next plan

- **The block reports UNKNOWN on the deployed estate today, and that is correct.** `/mnt/fast/stacks` is at `c67d497`, pre-Phase-6, so the executable count there is genuinely 0. It clears on the same `git push` + `git pull --ff-only` the vendored-drift block is already waiting on, and on nothing else. **The push is still the operator's call and has not been made.**
- **N-4 is the one worth closing:** plant a non-compliant invocation *inside* `phase06-oracle.sh` that does not carry `$SCRATCH_OVERLAY`, and confirm it lands in the asserted set rather than the exempt set.
- **`D04_DOC_BASELINE` is at 2 and earned it.** If a future plan needs to quote a bare invocation in `beets.md`, rephrase rather than raise the pin — the reasoning is recorded inline in the runbook.

## Next Phase Readiness

- CR-01 is fully closed: 06-15 fixed the live half, this plan fixed the detector half.
- WR-10 and IN-13 retired.
- No blockers. `STATE.md` and `ROADMAP.md` deliberately untouched — the orchestrator owns those after the wave merges.

## Self-Check: PASSED

- All three files exist on disk: `scripts/quick-health-check.sh`, `stacks/selfhosted/arrs/beets.md`, `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-16-d04-driven.txt` (477 lines).
- All three commits resolve in `git log`: `5f4d0c0`, `18b06a5`, `8ec9a1d`.
- Claims re-checked against the tree rather than restated: notice headers = 11 and raw = 14; `D04_DOC_BASELINE` still `:-2`; `D04_EXEMPT_BASELINE` `:-5`; executable/exempt/asserted = 8/5/3 via regexes extracted from the script; the runbook's two pattern quotes are byte-identical to the script (asserted with `grep -Fqx` against the live lines, not by eye); the superseded 2026-09-21 row is still present verbatim; `git status --porcelain` empty.

---
*Phase: 06-tagger-configuration-and-dry-run, plan 16*
*Completed: 2026-09-22*
