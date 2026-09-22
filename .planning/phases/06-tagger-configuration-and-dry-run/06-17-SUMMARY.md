---
phase: 06-tagger-configuration-and-dry-run
plan: 17
subsystem: testing
tags: [health-checks, shell, conf-04, d-22, exit-codes, fail-closed, wr-03, three-state]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "the D-22 artist-entity blocks and their pending third state (plans 06-03, 06-13), the recorded baselines (06-14), and quick-health-check.sh as plan 06-16 left it"
provides:
  - "exit 3 on check-music-consumers.sh: CONF-04 measured-but-not-at-target, documented and distinct from 0 and 1"
  - "a green banner that is UNREACHABLE while any D-22 artist row sits at a recorded baseline"
  - "a quick-health-check.sh fold-in arm that names CONF-04 instead of reporting an unexplained BROKEN, and sets EXIT_CODE=1"
  - "CONSUMERS_SCRIPT — the fourth additive override knob added because an undriveable branch is an unproven branch"
  - "a six-item NOT-DRIVEN register and two verify defects, for plan 06-21's disposition register"
affects: [06-21, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "a three-state check needs a THIRD EXIT CODE, not a third colour — yellow text is invisible to every consumer downstream"
    - "gate by SOURCE ORDER, not by warning text: put the terminating branch above the success banner so the banner is structurally unreachable"
    - "drive a gate in BOTH directions — a gate proven only to block is indistinguishable from a deleted success path"
    - "perturb a COPY, not the tracked file: 'restored' becomes true by construction, and a diff proves the delta"
    - "when a verify's grep is case-sensitive and the file's house style is FULL CAPS, the verify is a false-RED generator"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-17-conf04-exit3.txt
  modified:
    - scripts/check-music-consumers.sh
    - scripts/quick-health-check.sh

key-decisions:
  - "NO warn() call site was routed into FAILURES. The fix is a separate exit code, not a promotion — routing warn() into FAILURES would have collapsed pending into red and destroyed the three-state distinction this plan exists to preserve"
  - "NOT pushed and NOT pulled: the plan's step 1 asks for a deploy to the live estate to make a health-check line up, and the host is at c67d497, pre-Phase-6. A host scratch checkout was used, as 06-16 did"
  - "CONSUMERS_SCRIPT was added because the fold-in arm was otherwise reachable only by deploying unmerged Phase 6. Fourth knob added for the reason D03_REPO_ROOT states in full"
  - "The forced-green control perturbs a COPY rather than editing the tracked file in place — strictly stronger than edit-and-restore, and it yields a diff proving the delta is two lines"

patterns-established:
  - "Assert the CONTENTS of a new branch, not its existence: a verify that only greps for `elif ... -eq 3` passes on an arm that does nothing"
  - "Measure a pipeline's EPIPE headroom rather than declaring it safe — 54,526 B against a 65,536 B ceiling is not safe, it is 17% from broken"

requirements-completed: []

# Metrics
duration: 95min
completed: 2026-09-22
---

# Phase 6 Plan 17: CONF-04's pending state, made machine-readable Summary

**`check-music-consumers.sh` printed a green banner and exited 0 while CONF-04 was measurably open; it now exits 3 with the banner structurally unreachable, and the estate's health entry point calls that CONF-04-pending rather than BROKEN — driven in both directions against the live estate.**

## Performance

- **Duration:** ~95 min
- **Completed:** 2026-09-22
- **Tasks:** 2
- **Files:** 2 modified, 1 artifact created (952 lines) — `1150 insertions(+), 1 deletion(-)` against base `3f63bed`

## Accomplishments

- **The defect and the fix are both photographed against the live estate, in the same session.** Drive 5 (no override, deployed audit) still prints `✅ Both consumers see the library` with no CONF-04 line at all. Drive 3 (this plan's audit) prints `⚠️ CONF-04 MEASURED AND OPEN — artist rows at baseline, not at target (exit 3)`. Same estate, same minute, different script.
- **Exit 3 driven live: rc=3, and the green banner PROVABLY ABSENT** — `grep -c` returns 0 on the transcript. That absence is the fix, and it is asserted rather than eyeballed.
- **The pending counts were predicted before the run and agreed at every position.** From `06-14-SUMMARY.md`: Jellyfin 0/4, 1/2, 1/2 → **3 pending**; MA 3/4, 2/2, 2/2 → **1 reported**. Measured: 3 and 1. `FAILURES total: 0`, which is required — the exit-1 gate outranks.
- **The gate is proven to RELEASE as well as to block.** A gate proven only to block is indistinguishable from a deleted success path. Forcing both counters to zero produced **exit 0 WITH the banner**, and the tracked file's sha256 is byte-identical before and after (`1ed695cf…`).
- **The additive contract on the new knob is driven, not assumed:** an audit that exits 0 through `CONSUMERS_SCRIPT` still cannot print the tick.
- **Two defects found in this plan's own verify blocks**, one of which fired a false RED against correct content. Both fixed by strengthening.
- **Nothing was deployed.** The estate ended at `c67d497` with no new dirty entries and both `/tmp/p6-17-*` scratch trees removed.

## Task Commits

1. **Task 1: exit 3, the gated banner, the header register, the two branch comments** — `dc0fd47` (fix)
2. **Task 2: the fold-in arm, the TWELFTH notice, CONSUMERS_SCRIPT, and five driven transcripts** — `b79b902` (fix)

## Files Created/Modified

- `scripts/check-music-consumers.sh` — `exit 3` gate inserted between the yellow CONF-04 block and the green banner; the exit path's order documented inline as load-bearing; the header's exit-code register gains `pending - exit 3` plus a 35-line `EXIT 3` paragraph carrying all three clauses; both pending branches carry an exit-status contract comment. The green banner text and the `📊 6. Summary` anchor are byte-unchanged.
- `scripts/quick-health-check.sh` — `elif [ "$CONSUMERS_RC" -eq 3 ]` arm (⚠️ marker, echoes the audit's own CONF-04 lines through a **bounded** sed range, applies the `📊 6. Summary` anchor guard, `EXIT_CODE=1`); `CONSUMERS_SCRIPT` knob with its `CONSUMERS_OVERRIDDEN` arm; the TWELFTH exit-code notice with measured bookkeeping. The generic `❌ BROKEN` arm survives untouched.
- `artifacts/06-17-conf04-exit3.txt` — 952 lines: the scratch-checkout decision and its cost, five drives with exit statuses, both full transcripts, the forced-green diff and hashes, the reds attributed by owner, the CONF-04 status paragraph, the NOT-DRIVEN register, and the two verify defects with their measurements.

## Which `warn()` call sites now reach `FAILURES`, and which stay advisory

**NONE of them reach `FAILURES`. Not one.** This is the single most important thing to carry forward from this plan, because the obvious reading of WR-03 — "`warn()` doesn't increment `FAILURES`, so make it" — is the **wrong fix**, and taking it would have destroyed the distinction the file exists to preserve.

`check-music-consumers.sh` has **ten** `warn()` call sites. All ten still print and still touch no counter. `FAILURES` is unchanged by this plan at every site, and `EXPORT_FAILURES` / `MA_FAILURES` / `JELLYFIN_FAILURES` are untouched:

| line | site | status after this plan | why |
|---|---|---|---|
| 802 | `HA_SSH_HOST` empty | **advisory, unchanged** | enrichment skip; the MA-side assertions are the load-bearing ones and they run regardless |
| 807 | `HA_SSH_KEY` absent | **advisory, unchanged** | same; expected on LXC 100 by design, and `HA_ROUTE=skipped` is the documented state |
| 823 | MA version drift | **advisory, unchanged** | the version banner is deliberately report-not-assert (D-21/D-56); promoting it would make an `auto_update` bump a red |
| 1083 | `scope=temp-export` album, no temp provider | **advisory, unchanged** | out-of-scope row (D-15), not a measurement |
| 1120 | album list at query limit (section 3) | **advisory, unchanged** | a floor-not-count caveat; the assertion it qualifies has its own red |
| 1185 | `scope!=library` album in Jellyfin | **advisory, unchanged** | structurally out of Jellyfin's reach by design |
| **1355** | **Jellyfin D-22 row at baseline** | **advisory, BUT now gates `exit 3`** | see below |
| **1464** | **MA D-22 row at baseline** | **advisory, BUT now gates `exit 3`** | see below |
| 1523 | album count at limit (section 5) | **advisory, unchanged** | same floor-not-count caveat as 1120 |
| 1538 | `ha mounts info` skipped | **advisory, unchanged** | enrichment skip |

**Only the two D-22 pending sites changed, and they changed in a different way than "now counts toward `FAILURES`".** Each increments its own counter (`JELLYFIN_ARTIST_PENDING`, `MA_ARTIST_PENDING`) — which it already did — and those two counters are now read by a terminating branch in the exit path that fires `exit 3`. So:

- `FAILURES` stays **0** on an exit-3 run. Asserted by the ordering (`FAILURES -gt 0 → exit 1` sits above) and **measured**: `FAILURES total: 0` in drive 1.
- A **red** run still exits **1**, not 3. A measured failure outranks a pending row.
- The two consumer verdicts are **still separate**. The sum is taken to answer one question — *is any row off target* — and is never a combined CONF-04 answer. The summary still reports the four artist-row figures on four separate lines.

**Why not just promote the two `warn`s to `fail`?** Because pending is not a failure: the rows were read successfully and hold exactly the value they were recorded holding. A permanently-red check is one readers learn to ignore (recorded by plan 01-09 and re-argued at `ARTIST_PROOF_ROWS`), and `jellyfin_fail` here would have made every run red for a state nobody can act on before Phase 7. Exit 3 gives tooling a signal without lying to the reader.

**In `quick-health-check.sh` the effect is deliberately different**, and the asymmetry is intentional: the fold-in arm sets `EXIT_CODE=1`. The estate's entry point has no third state and should not grow one — it exits 0 when healthy and non-zero on any violation, and a requirement that is measured and open is not healthy. So the *audit* distinguishes three states and the *entry point* collapses two of them into "not healthy", with the label carrying the distinction.

## Decisions Made

**Not pushed, not pulled.** The plan's task-2 step 1 says "Push and pull so the host's `/mnt/fast/stacks` carries the changed script". `/mnt/fast/stacks` is at `c67d497`, pre-Phase-6; complying would have deployed **all of unmerged Phase 6** to the live estate to make a health-check line up. A host scratch checkout at `/tmp/p6-17-scratch` was used instead — the route 06-16 established for the identical instruction. This is sound for *this* script specifically because it reads **no repository file**: `grep -n REPO_ROOT` returns exactly two lines (the assignment and a `cd`), and every input is `/mnt/fast/secrets/`, two HTTP APIs and atlantis over ssh. **The cost, stated:** the fold-in's new arm does not fire for an operator today (drive 5 shows it printing the tick) and begins firing on the same push+pull 06-16 is already waiting on.

**`CONSUMERS_SCRIPT` was added, and it is not scope creep.** The fold-in invoked a hard-coded path, so the new arm was reachable by exactly two routes: deploy unmerged work (refused), or make the path overridable. This is the **fourth** knob added in this file for the identical reason, and the third notice to quote it in the same words — *an undriveable branch is an unproven branch* (`DRIFT_REPO_ROOT`, `D04_REPO_ROOT`, plan 06-10; `D03_REPO_ROOT`, plan 06-16). It names a **file**, not a root, because that is what the fold-in invokes, and it deliberately does not reuse any `*_REPO_ROOT` knob for the reason `D03_REPO_ROOT`'s own comment gives: they are different claims sharing a default path, and one knob moving two verdicts is how a run reports on a tree nobody asked it to look at. Its additive contract was **driven** (drive 4), not asserted.

**The forced-green control perturbs a copy.** The plan says to edit the tracked file in place and restore it. A copy is strictly stronger: the tracked file was opened read-only and never written, so "restored" is true by construction rather than by care, there is no window in which a crashed run leaves the forcing in the repository (threat T-06-84), **and** it yields a `diff -u` proving the delta is exactly two lines — which edit-and-restore could not have shown. The plan's own evidence requirement is still met in full: pre/post sha256 of the tracked file recorded and equal.

**The sed range in the new arm is bounded.** `sed -n '/CONF-04 IS NOT CLOSED/,/Discharges on ROADMAP/p'` is followed by `sed -n '1,8p'` rather than trusted, because a range whose end never matches runs to EOF (06-20's finding). `sed -n '1,8p'` and not `head -8`, because `head` closes the pipe and the upstream `sed` takes a SIGPIPE — the 141 shape this phase has been bitten by repeatedly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] The plan's step 1 instructs a deploy of unmerged Phase 6 to the live estate**

- **Found during:** Task 2, before any run
- **Issue:** "Push and pull so the host's `/mnt/fast/stacks` carries the changed script." The host is at `c67d497`. The instruction's effect is far larger than the change being proven.
- **Fix:** Host scratch checkout at `/tmp/p6-17-scratch` (and `/tmp/p6-17-forced`), both removed afterwards. Estate verified at `c67d497` with no new dirty entries.
- **Cost:** stated in the summary above and in artifact § 0 — the arm is not live for an operator until the operator pushes.

**2. [Rule 1 — Bug] Task 1's verify is case-sensitive and fired a FALSE RED against correct content**

- **Found during:** Task 1, first run of the plan's own verify
- **Issue:** `grep -qE "never (be )?summed|NEVER summed"` does not match `ARE NEVER SUMMED`, which is what the file's FULL-CAPS emphasis register produces (`KEEP THIS HEADING LITERAL`, `READ-ONLY BY CONTRACT`, `UNKNOWN, not green`). **Observed firing:** case-sensitive → 0 matches, rc=1; case-insensitive → line 139. The grep immediately before it on the same line already carries `-i`, which is the evidence this is an oversight and not intent. Cross-plan warning #7 in a purely local form.
- **Fix:** `-i`, and **strengthened** rather than merely repaired — the plan's acceptance criterion names *three* clauses (not-a-failure, not-green, never-summed) but its verify checked only one; all three are now asserted, all three must live **inside the header comment block** rather than anywhere in the file, the green banner is checked byte-exact with `grep -Fq`, and the two branch comments are counted.
- **Verification:** falsifiability proven — the repaired verify against the base file returns `exit 3 is absent`, rc=1.

**3. [Rule 1 — Bug] Task 2's verify carries the `printf | grep -q` 141-propagator, ~17% from firing**

- **Found during:** Task 2
- **Issue:** `printf "%s\n" "$s" | grep -q …` twice under `set -o pipefail`. **Measured, not assumed:** it returns 0 today even with a pattern matching the first line — but only because the comment-stripped stream is **54,526 B** against a **65,536 B** macOS pipe ceiling, so the writer never blocks and never observes the closed pipe. `quick-health-check.sh` has grown on every plan of this phase; when the stripped stream crosses 64 KB this assertion begins firing its FAILURE branch exactly when the file is **correct**.
- **Fix:** both pipelines rewritten over a temp file. **Strengthened:** the plan asserted only that the arm *exists* while calling `EXIT_CODE=1` on it "the load-bearing half" — the arm's contents are now asserted (`EXIT_CODE=1` present, anchor guard present, string `BROKEN` absent), via a bounded `awk` range whose **start** delimiter is asserted unique first and whose length is bounded to 3 < n < 40 (measured 18).
- **Verification:** falsifiability proven — against the base file, all three script-side assertions fail (`no dedicated arm for exit 3`; `expected 12 notice headers, found 11`; `no CONSUMERS_SCRIPT knob`).

**4. [Rule 2 — Missing critical functionality] The new fold-in arm was undriveable**

- **Found during:** Task 2
- **Issue:** The plan requires both new branches to be DRIVEN (must-have truth 5), but the fold-in's hard-coded path made the arm reachable only by deploying unmerged work.
- **Fix:** `CONSUMERS_SCRIPT` with the file's standard additive contract, plus a `CONSUMERS_OVERRIDDEN` arm so an override can never produce the tick. Both the arm and its contract were driven.
- **Why Rule 2 rather than scope:** an unproven branch in the estate's single health entry point is exactly the class of defect 06-16 closed (IN-13) and 06-19 escalated. Shipping an undriveable branch would have repeated it.

**5. [Rule 1 — Bug, mine] A raw `elif` inserted after an existing `else`**

- **Found during:** Task 2
- **Issue:** My first edit put the `CONSUMERS_OVERRIDDEN` arm below the `-eq 0` arm's `else`, producing `else` / `elif` — a syntax error.
- **Fix:** replaced the `else` with the `elif` and kept the tick on the final `else`. Caught by `bash -n` before any commit.
- **Recorded because** it is the reason `bash -n` runs before every commit here rather than only at the end.

### Stale line citations (not a fix, but the fourth consecutive plan to hit them)

Every line citation in this plan's `read_first` was stale. `quick-health-check.sh:1946-2007` for the fold-in → actually **2120-2182** on the base, i.e. off by ~175 lines because 06-16 added ~200 lines to the same file in the wave immediately before. `check-music-consumers.sh:1296-1310` for the counters → **476-490**; `:1310-1316` for the `*_fail` wrappers → **485-490**. All found by `grep -n` on anchor text, per the standing note. No citation was trusted.

---

**Total deviations:** 5 auto-fixed (3 × Rule 1, 1 × Rule 2, 1 × Rule 3) + 1 citation note
**Impact on plan:** No scope creep beyond the `CONSUMERS_SCRIPT` knob, which is argued above and follows three in-file precedents. **Two of the five were verify defects**, one of which actively fired a false RED — in a gap-closure plan whose purpose is making a check able to tell the truth.

## Issues Encountered

None beyond the deviations. Both remote runs completed well inside their 180 s bound; no MA slowness, no 124.

## Verification Results

| Check | Result |
|---|---|
| `bash -n`, both scripts | clean |
| `shellcheck -S warning` (consumers) / `-S error` (health) | clean |
| Source order: pending(1669) < `exit 3`(1674) < banner(1679) | **holds** |
| `📊 6. Summary` byte-present and unrenumbered | yes |
| Green banner text byte-unchanged | yes (`grep -Fq` on the literal) |
| Header carries all three clauses, inside the comment block | yes |
| Pending-branch exit-status comments | 2 of 2 |
| Notice headers / raw | **12 / 15** (measured 11 / 14 before) |
| Exit-3 arm extract | 18 lines; `EXIT_CODE=1` yes; anchor guard yes; `BROKEN` absent |
| Generic `❌ BROKEN` arm survives | yes |
| **Drive 1** — live exit 3 | **rc=3**; banner `grep -c` = **0**; JF pending **3**, MA **1**; `FAILURES 0` |
| Predicted vs measured pending counts | agreement at all four positions |
| **Drive 2** — forced green | **rc=0**; banner present ×1; `CONF-04 IS NOT CLOSED` ×0 |
| Tracked file sha256 before / after control | `1ed695cf…` / `1ed695cf…` — **equal** |
| Forced-copy delta | exactly 2 lines (`diff -u`) |
| **Drive 3** — fold-in | new ⚠️ line present; `BROKEN (check-music-consumers.sh` **absent**; health rc **1** |
| **Drive 4** — override contract | tick **suppressed** on an audit that exited 0; health rc 1 |
| **Drive 5** — deployed, no override | tick printed, no CONF-04 line — the defect, still live |
| Verify falsifiability, both tasks | proven against base files |
| `REQUIREMENTS.md` in `git diff --name-only` | no |
| Repo `git status --porcelain` | empty after each commit |
| Estate HEAD after all work | `c67d497`, unchanged; `/tmp/p6-17-*` removed |
| Credential scan of both transcripts | only the two presence-not-value lines |

## NOT DRIVEN — asserted by construction, for plan 06-21's disposition register

Full text in artifact § 9.

| id | claim | why not observed | what would drive it |
|---|---|---|---|
| N-1 | **CONF-04 actually reading at target** | drive 2 reached the banner by FORCING the counters, not by earning it; no route to earning it exists before Phase 7, since the only refresh that re-probes is the aggressive per-item mode, which rewrites `.nfo` and is forbidden | Phase 7's first write or import of one of the three pinned files, then a re-run |
| N-2 | the **`EXIT_CODE=1` contribution of the new arm, in isolation** | the arm was observed firing and the run exited 1, but the standing Phase 5 `interpolated-host-path` red forces exit 1 in **every** run, so the contribution cannot be isolated. Same limitation 06-16 recorded as its own N-2 | clear the `interpolated-host-path` finding, re-run drive 3, observe exit 1 with no other red |
| N-3 | the **new arm's `📊 6. Summary` anchor-guard branch** | written to the same shape as the `-eq 0` arm's guard, which is itself pre-existing and was not re-driven. **The weakest link in this plan's change and the obvious next drive** — it is the only branch protecting the cross-file heading contract on a code path that did not exist before today | renumber the heading in a scratch copy, point `CONSUMERS_SCRIPT` at it, confirm UNKNOWN rather than printed counts |
| N-4 | the **generic `❌ BROKEN` arm** | pre-existing, untouched, now narrower by one status; not re-driven | point `CONSUMERS_SCRIPT` at a script exiting 2 — the audit already exits 2 on an unknown option |
| N-5 | the **`--baseline` path under the new ordering** | source order asserted, but no `--baseline` run was taken | run the audit `--baseline` on the scratch checkout; confirm exit 0 despite 4 pending rows |
| N-6 | **`FAILURES -gt 0` outranking pending** | asserted by source order and by header clause (a); drive 1 confirms `FAILURES` is 0 when exit 3 fires, but no run had `FAILURES > 0` AND pending > 0 simultaneously, so "red outranks pending" is reasoned, not observed | force one export assertion red on a scratch copy while the pending rows stand; confirm exit 1, not 3 |

## Known Stubs

None. Every branch this plan added was driven except N-3 and N-4, each named above with the condition that would drive it.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change at a trust boundary. `CONSUMERS_SCRIPT` widens no surface: it is a path handed to an ssh command that already ran an arbitrary host-side script as root, it is additive-only (it can never produce a pass), and its default is unchanged and was verified unchanged by drive 5. T-06-85 (credential in a transcript) was checked explicitly — see Verification Results.

## Notes for the next plan

- **CONF-04 IS NOT CLOSED and was not closed here.** Its Jellyfin half is still OPEN (all three rows at the 2026-09-20 baseline, because `PreferNonstandardArtistsTag` is probe-time); its MA half is discharged for 2 of 3 rows with row 1 carrying the discrepancy 06-13 characterised. The two verdicts are **still not summed**. `REQUIREMENTS.md`'s `- [ ] CONF-04` is untouched and ROADMAP entry criterion **E6** still owns the discharge and the two measurements Phase 7 must take. **What changed is one thing: the open state now has an exit code.**
- **The measured counts for E6 and for plan 06-21:** JF pending **3**, JF at target **0**, MA reported **1**, MA at target **2**, `FAILURES` **0**, taken 2026-09-22 against the live estate.
- **`quick-health-check.sh` will exit non-zero on the consumers block from the moment Phase 6 is merged and the host pulls, and will stay non-zero until E6 discharges.** That is intended. Do not tune it out; the twelfth notice says so inline.
- **N-3 is the one worth closing** — the anchor guard on the new arm is the only undriven branch that protects a cross-file contract.
- **Do not route any `warn()` into `FAILURES`.** The table above exists so a future reader does not "finish the job" and collapse pending into red.

## Self-Check: PASSED

- Both scripts exist and parse: `scripts/check-music-consumers.sh`, `scripts/quick-health-check.sh` — `bash -n` clean, shellcheck clean.
- Artifact exists: `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-17-conf04-exit3.txt`, 952 lines.
- Both commits resolve in `git log`: `dc0fd47`, `b79b902`.
- Claims re-checked against the tree rather than restated: notice headers = **12** and raw = **15** by the two greps the eighth notice quotes; exit-path line order 1669 < 1674 < 1679; `warn "` call sites = **10**, all still advisory, `FAILURES` untouched at every one; the exit-3 arm extract is 18 lines and contains `EXIT_CODE=1` and the anchor guard and not `BROKEN`; the tracked file's sha256 is `1ed695cf…` both before and after the forced-green control; the estate is at `c67d497` with `/tmp/p6-17-*` gone.
- `STATE.md` and `ROADMAP.md` deliberately untouched — the orchestrator owns those after the wave merges. `REQUIREMENTS.md` untouched by design.

---
*Phase: 06-tagger-configuration-and-dry-run, plan 17*
*Completed: 2026-09-22*
