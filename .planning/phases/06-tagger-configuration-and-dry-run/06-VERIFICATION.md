---
phase: 06-tagger-configuration-and-dry-run
verified: 2026-09-23T15:30:00Z
status: gaps_found
score: 5/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 6/6
  gaps_closed:
    - "CR-01 (D-04 vacuous 'no bare beet invocation' assertion) — re-confirmed still closed, both halves, by direct grep + self-test re-run"
    - "GC-01/GC-03 (round 2 BLOCKER: forbidden-substring pipeline, CR-01 one nesting level in) — re-confirmed closed"
    - "All 10 round-3 findings (R3-01..R3-10) — re-confirmed dispositioned, 9 FIXED + 1 FIXED (undriven)"
    - "All 10 round-4 findings (R4-01..R4-10, aliased WR-01..06/IN-01..04) — re-confirmed dispositioned, 9 FIXED + 1 FIXED (undriven), independently re-measured (ST_PLANNED_CASES=140, check-beets-config.sh 7 cases/6 red)"
  gaps_remaining:
    - "CONF-04 Jellyfin half — still OPEN, unchanged since the prior verification. The prior VERIFICATION.md scored this truth VERIFIED on the basis that the OPEN state is 'correctly recorded' rather than on the requirement being satisfied. That is a category error this re-verification does not repeat: CONF-04 and ROADMAP Phase 6 success criterion 4 are NOT fully true, and REQUIREMENTS.md still carries an unchecked box for it."
  regressions: []
gaps:
  - truth: "CONF-04: a multi-artist track separated with ';' shows its artists parsed correctly in BOTH Jellyfin and Music Assistant"
    status: partial
    reason: "Music Assistant half is discharged and independently verifiable (config + committed read-back). The Jellyfin half is not: PreferNonstandardArtistsTag is a probe-time option and 0 of 1,244 library rows have been re-probed since it was enabled, so the three pinned census rows still read their pre-change baseline (0/4, 1/2, 1/2). REQUIREMENTS.md:152 carries an unchecked '- [ ] CONF-04', ROADMAP.md's own Phase 6 status line reads 'In Progress' (not Complete), and the roadmap itself names this a Phase 7 entry criterion (E6) still to be discharged. This is not a hidden defect — it is transparently tracked — but a requirement that is explicitly still open cannot be reported as a verified truth."
    artifacts:
      - path: ".planning/REQUIREMENTS.md:152"
        issue: "CONF-04 checkbox unticked; no plan in rounds 1-4 moved it"
      - path: "scripts/check-music-consumers.sh"
        issue: "Correctly reports the Jellyfin rows as pending (exit 3 gate, WR-03/06-17) rather than falsely green — the instrumentation is honest, but the underlying fact it reports is that the requirement is unmet"
    missing:
      - "A live Jellyfin re-probe of at least the three pinned multi-artist tracks (or equivalent write activity) confirming ARTISTS-tag parsing reaches 4/2/2, which by the roadmap's own design cannot happen before Phase 7's first write"
deferred:
  - truth: "CONF-04 Jellyfin-half discharge mechanism"
    addressed_in: "Phase 7"
    evidence: "ROADMAP.md Phase 7 section: 'Entry criteria inherited from Phase 6 ... E6' names CONF-04's Jellyfin half explicitly, and ROADMAP.md Phase 6 success-criterion-4 text states 'It discharges on Phase 7's first write.' (Note: this evidence explains WHY the gap exists and WHO owns closing it — it does not change today's truth value, which is why the item is listed under both gaps and deferred: the requirement is unmet today, and the closing mechanism is correctly Phase 7's, not Phase 6's to retry.)"
  - truth: "Container-side SIGTERM/SIGPIPE delivery to beets-flask's in-container programs (R4-04/DEF-06-39-04)"
    addressed_in: "Phase 7 (existing entry criterion E12)"
    evidence: "06-DISPOSITIONS-GAP3.md: 'Condition that would drive it: a live --arm a / --arm b pair ... attaches to the existing Phase 7 entry criterion E12'; ROADMAP.md's Phase 7 entry-criteria section already carries E12 as the catch-all for gap-closure's undriven live-estate residue."
human_verification: []
---

# Phase 6: Tagger Configuration and Dry Run Verification Report

**Phase Goal:** The surviving tagger's configuration is shown to produce the intended tree on
paper, at the last cheap moment before a path-format error can be applied at scale.
**Verified:** 2026-09-23T15:30:00Z
**Status:** gaps_found
**Re-verification:** Yes — the existing `06-VERIFICATION.md` (status: passed, score: 6/6, dated
2026-09-22T10:30:49Z) was written after gap-closure round 1 and is stale: rounds 2, 3 and 4 have
since run against the same four instrument scripts, and CONF-04's Jellyfin half — a required
Phase 6 requirement — remains open. This report supersedes it.

## Why this re-verification does not simply confirm the prior "passed" result

The prior `06-VERIFICATION.md` scored truth #4 ("CONF-04 ... correctly recorded as OPEN") as
**VERIFIED**. Read literally, that truth is about the *bookkeeping being honest*, not about the
*requirement being satisfied* — and the bookkeeping genuinely is honest (REQUIREMENTS.md,
ROADMAP.md and `check-music-consumers.sh` all say OPEN, consistently, everywhere). But a
goal-backward verification has to ask whether CONF-04 itself — "the one delimiter both consumers
handle" — is true today, and it is not: only one of the two consumers has been demonstrated. Scoring
that as a passed truth is the same shape of error this phase's own reviews spent four rounds
chasing in the code (a claim that reads as true on its surface but is falsified by the text or state
sitting right next to it). This re-verification counts CONF-04 by what it requires, not by whether
its openness is well-documented.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CONF-01: effective config shows imports copying, never moving | VERIFIED | `stacks/selfhosted/arrs/beets/config.yaml:311-312` reads `copy: yes` / `move: no`, unchanged since 06-01 (git log shows no edits to this file since `1a64286`, predating all four gap-closure rounds). `bash scripts/check-beets-config.sh --self-test` executed directly in this verification: exit 0, `--self-test: all 7 cases behaved as expected (6 of them red)` — independently re-run, not read from a summary. |
| 2 | CONF-02: `incremental: yes` **with** `incremental_skip_later: yes`, trap proven to fire | VERIFIED | `config.yaml:323-324` unchanged. `bash scripts/phase06-incremental-control.sh --self-test` executed directly: exit 0, all branches including the RED-vs-UNKNOWN precedence case behaved as expected. The two-arm design (proven in 06-08/06-11) is untouched by rounds 2-4, which only hardened exit codes and signal handling around it. |
| 3 | CONF-03/CONF-06: dry-run over bucket-A sample produces the intended tree, fixture proven to predate the run | VERIFIED | `06-EXPECTED-TREE.txt` git history still one commit (`cb9f49a`). `bash scripts/phase06-oracle.sh --self-test` executed directly in this verification: exit 0, `self-test: 140 case(s), every fail-closed branch behaved exactly as expected` — I independently re-derived 140 by running the self-test on this machine (macOS, uid 501 non-root, `python3` present at `/opt/homebrew/bin/python3`), matching the reference environment `06-DISPOSITIONS-GAP3.md` names for that exact figure. This directly falsifies any residual doubt about R4-02's fix: the count is not copied from a document, it is measured. The destination-path logic itself (the 174-destination zero-diff) is unchanged since 06-11 and was not touched by any of the four review rounds, which only hardened the instrument's safety/honesty around it. |
| 4 | CONF-04: two consumers, two verdicts — MA discharged, Jellyfin still OPEN | **FAILED (partial)** | `REQUIREMENTS.md:152` still `- [ ] CONF-04` (confirmed by direct grep, count 1). ROADMAP.md's Phase 6 status row still reads `In Progress`, not `Complete`, and explicitly states "1 open requirement: CONF-04 is OPEN on its Jellyfin half." `scripts/check-music-consumers.sh` still gates on the pending state via `exit 3` (WR-03/06-17), so the estate-facing signal is honest, but the underlying fact is that 0 of 1,244 library rows have been re-probed and the three pinned multi-artist tracks still read baseline. This is the one required Phase 6 requirement not satisfied. |
| 5 | CONF-05: match disambiguation demonstrated by a real rank-flip | VERIFIED | `config.yaml:357,362,369` — `countries: ['GB', 'US']` (no `UK`), `original_year: yes`, `extra_tags: [year, catalognum, country, media, label]` — unchanged since 06-01. Not touched by any of the four review rounds. The driven rank-0 flip (`06-12-country-preference.txt`) is a committed artifact, unaffected. |
| 6 | Supporting must-have (backs CONF-01/02/03): no `beet` CLI invocation in the committed tree can open the real library without a throwaway `-l` and a `-c` overlay (D-04/CR-01), surviving four consecutive rounds of adversarial review of its own fixes | VERIFIED | Four rounds of code review (`06-REVIEW.md` 24 findings, `06-REVIEW-GAP.md` 17, `06-REVIEW-GAP2.md` 10, `06-REVIEW-GAP3.md` 10) each targeted the *previous* round's own diff and each is fully dispositioned in its own register (`06-DISPOSITIONS.md`, `-GAP.md`, `-GAP2.md`, `-GAP3.md`) with zero `ACCEPTED`/unresolved rows across all four. Round 4 — the most recent, and the one this re-verification checked in depth — found **0 Critical**, and both its `FIXED` and `FIXED (undriven)` dispositions are traceable to specific commits and artifacts. I independently confirmed: `bash -n` clean on all four scripts; all three self-testable scripts (`check-beets-config.sh`, `phase06-incremental-control.sh`, `phase06-oracle.sh`) exit 0 when run directly by me just now; `git status` clean; the R4-05 self-referential-count fix (`check-beets-config.sh:82,89,448`) present verbatim; the round-4 ID-mapping table's in-band citations (`R4-01`..`R4-10`) present 33 times across the four scripts (grep-counted directly, not read from the register). `scripts/quick-health-check.sh` was NOT executed by me — it requires ssh/estate contact, which is out of scope for this verification per the no-estate-contact constraint, and it has no `--self-test` mode (confirmed: zero hits for `self-test` in the file). This is a "could not look," not a "nothing is wrong": the block's live behaviour against the deployed estate remains unobserved by anyone, in every round, and is recorded as such below rather than assumed clean. |

**Score:** 5/6 truths verified. Truth 4 (CONF-04) FAILS on its own merits, correctly and
transparently tracked as OPEN by the codebase, but still unmet.

### Deferred Items

Items not met today but explicitly and specifically owned by a later milestone phase.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | CONF-04 Jellyfin-half discharge mechanism | Phase 7 (entry criterion E6) | ROADMAP.md names E6 explicitly for this; criterion-4 text states "It discharges on Phase 7's first write" — the mechanism (a Jellyfin re-probe) structurally cannot exist before Phase 7 writes content. **Listed here for completeness, but this does NOT remove CONF-04 from the gaps list above** — Phase 6 itself, not just Phase 7, lists CONF-04 among its six required requirements, and the roadmap's own phase-status row already reads "In Progress" rather than "Complete" for exactly this reason. Deferring the *mechanism* to Phase 7 is correct; deferring the *verification verdict* to Phase 7 would let this phase report itself complete on a requirement it did not close, which is the trap this report is written to avoid. |
| 2 | Container-side SIGTERM/SIGPIPE delivery, unobserved inside beets-flask (R4-04/DEF-06-39-04) | Phase 7 (existing entry criterion E12) | `06-DISPOSITIONS-GAP3.md` names the exact live-arm condition and attaches it to E12, which already exists in ROADMAP.md's Phase 7 entry-criteria section as the catch-all for gap-closure's live-estate residue. This is genuinely out of Phase 6's own success criteria (it concerns instrument robustness, not CONF-01..06's truth value) and is correctly deferred. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `stacks/selfhosted/arrs/beets/config.yaml` | Single vendored config, CONF-01/02/03/05 keys pinned | VERIFIED | Read directly; all cited keys present and correct. Unchanged across all four gap-closure rounds (git log shows the file's last edit predates round 1). |
| `scripts/check-beets-config.sh` | D-04-compliant, self-tested, R4-05 count-hygiene fixed | VERIFIED | `--self-test` executed directly: exit 0, 7 cases, 6 red. R4-05 fix present in source at lines 82, 89, 448. |
| `scripts/phase06-incremental-control.sh` | CONF-02 two-arm negative control, signal-safe (R4-03/R4-04) | VERIFIED, one residual noted | `--self-test` executed directly: exit 0, all branches pass including the precedence case. R4-03's INT/TERM/HUP handler fix is committed and driven (per disposition register, under `/bin/dash`); R4-04's SIGPIPE-vs-SIGTERM delivery mechanism is explicitly `FIXED (undriven)` — the code changed but nobody has observed which signal the container transport actually delivers. This is disclosed, not hidden, and is deferred to Phase 7 E12 above. |
| `scripts/phase06-oracle.sh` | CONF-03/06 destination-path oracle, self-test count re-measured (R4-02) | VERIFIED | `--self-test` executed directly: exit 0, 140 cases — independently reproduced by me on this machine, matching the reference environment named in the disposition register exactly (macOS, non-root, python3 present). |
| `scripts/quick-health-check.sh` | R4-01/07/08 quoting and census fixes | **COULD NOT LOOK (execution)** — VERIFIED (static) | `bash -n` clean; R4-01's fix (rendering `DRIFT_*_Q` forms before interpolation) and R4-07/R4-08's census widening are present in source per direct grep. No `--self-test` mode exists in this script and it requires ssh/estate contact to exercise, which this verification does not perform. Both the code review (round 4) and this verification therefore rest on static reasoning for this file, and that limitation is stated rather than smoothed over — this matches the disposition register's own stated grade for these findings. |
| `06-EXPECTED-TREE.txt` | Fixture committed before the run it judges | VERIFIED | Still at commit `cb9f49a`, unedited (git log shows one commit). |
| `06-DISPOSITIONS.md` / `-GAP.md` / `-GAP2.md` / `-GAP3.md` | Four disposition registers, one per review round | VERIFIED | All four read; each fully reconciles its own review's finding count (24, 17, 10, 10) with zero unresolved rows. |
| `06-REVIEW.md` / `-GAP.md` / `-GAP2.md` / `-GAP3.md` | Four review reports, each wired to its register | VERIFIED | `06-REVIEW-GAP3.md` carries the ID-mapping table and is wired per ROADMAP's own account; prior three confirmed wired in the prior verification pass and unchanged since. |
| `deferred-items.md` | Named carry-forward for undriven/deferred residue | VERIFIED | 36 unique `DEF-*` entries counted directly (`grep -oE "DEF-[0-9]{2}-[0-9]{2}-[0-9]{2}"` → 36 unique), matching the figure `06-39-SUMMARY.md`'s own self-check states (36 = 30 + 6). |
| `REQUIREMENTS.md` | CONF-01..06 traceability, honest about what is unmet | VERIFIED (as a document), FAILED (as evidence CONF-04 is satisfied) | The document itself is accurate and detailed — it is the thing that most clearly proves CONF-04 is still open, which is exactly why this verification does not mark CONF-04 passed. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `scripts/quick-health-check.sh` D-04 block | the three instrument scripts' `beet` invocations | `D04_INV_RE` + `D04_EXEMPT_RE`, widened by R3-01/R4-01 | WIRED (static — see artifact table above) | Present in source; not exercised against the live estate by this verification or by round 4's own review. |
| `check-music-consumers.sh` CONF-04 rows | `quick-health-check.sh` exit code | `exit 3` gate (06-17, unchanged since) | WIRED | Confirmed by direct read: the pending-state gate and its consuming `elif` arm are both present in source, unchanged since the prior verification pass. |
| `06-EXPECTED-TREE.txt` | `beet move -p` output | `diff` via `manifest_compare` | WIRED (regression, static) | Unchanged; the live 174-line zero-diff run is a committed artifact from 06-11, not re-executed here (re-running it would perform a real MusicBrainz-backed dry run, out of this verification's no-estate-contact scope, and is not required to re-confirm a file that has not changed). |
| Phase 6 requirements (`06-*-PLAN.md` `requirements:` frontmatter) | `REQUIREMENTS.md` CONF-01..06 mapping | plan frontmatter cross-check | WIRED, no orphans | Checked all 39 plans directly: every plan's `requirements:` field cites only CONF-01..06, and all six IDs appear across the plan set. No requirement mapped to Phase 6 in REQUIREMENTS.md is missing a plan, and no plan cites an ID outside CONF-01..06. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `check-beets-config.sh` self-test | `bash scripts/check-beets-config.sh --self-test` | exit 0, "all 7 cases behaved as expected (6 of them red)" | PASS (independently executed) |
| `phase06-incremental-control.sh` self-test | `bash scripts/phase06-incremental-control.sh --self-test` | exit 0, all branches including RED-vs-UNKNOWN precedence pass | PASS (independently executed) |
| `phase06-oracle.sh` self-test | `bash scripts/phase06-oracle.sh --self-test` | exit 0, "140 case(s), every fail-closed branch behaved exactly as expected" | PASS (independently executed; 140 matches the re-measured, not the stale-134, figure) |
| `quick-health-check.sh` any mode | n/a | not run | SKIP — requires ssh/estate contact, explicitly out of scope for this verification; also zero prior executions across all four gap-closure rounds (recorded fact, not an oversight introduced here) |
| Syntax check, all four instrument scripts | `bash -n <script>` ×4 | all four exit 0 | PASS (independently executed) |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention exists in this repository/phase; the phase's own
"probes" are the `--self-test` modes of the four instrument scripts, covered under Behavioral
Spot-Checks above and executed directly rather than trusted from SUMMARY narration.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| CONF-01 | 06-01, 06-07, 06-15, 06-22 | Imports copy, never move | SATISFIED | Truth #1, #6 |
| CONF-02 | 06-01, 06-07, 06-08, 06-16, 06-20, 06-25, 06-37 | `incremental` + `incremental_skip_later`, two-arm proof | SATISFIED | Truth #2, #6 |
| CONF-03 | 06-01, 06-05, 06-09, 06-11, 06-16, 06-18, 06-19, 06-23..36 | Path formats produce the intended tree | SATISFIED | Truth #3, #6 |
| CONF-04 | 06-02, 06-03, 06-13, 06-17, 06-26 | Multi-artist parsing in both consumers | **NOT SATISFIED (MA half only)** | Truth #4 — FAILED on the Jellyfin half; correctly tracked OPEN in REQUIREMENTS.md and ROADMAP.md |
| CONF-05 | 06-01, 06-07, 06-11, 06-12, 06-15, 06-22 | Match disambiguation demonstrated | SATISFIED | Truth #5 |
| CONF-06 | 06-02, 06-09, 06-11, 06-18, 06-19, 06-24..39 | The dry-run's instrument proves the tree, wrote nothing | SATISFIED | Truth #3 (same evidence chain) |

No orphaned requirements: REQUIREMENTS.md's phase-6 row lists exactly CONF-01..06, and every plan's
`requirements:` frontmatter (all 39 plans, confirmed by direct grep) cites a subset of that same
set — checked in this verification, not assumed from the prior pass.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No `TBD`/`FIXME`/`XXX` found in any of the four instrument scripts (checked directly by this verification, not copied from the prior report) | — | Debt-marker gate does not fire |
| `scripts/phase06-incremental-control.sh` | INT/TERM/HUP handlers | R4-04: SIGPIPE-vs-SIGTERM delivery mechanism is `FIXED (undriven)` — code changed, live signal path unobserved | Info (residue, `DEF-06-39-04`, deferred to Phase 7 E12) | Named, owned, reproducible; not a live violation of the phase's own requirements |
| `scripts/quick-health-check.sh` | D-04 block | Executed zero times against the live estate, across all four gap-closure rounds and this verification | Info, but load-bearing | This is the phase's own most-reviewed safety assertion and it has never once been observed firing against real state. Correctly disclosed in ROADMAP.md and `deferred-items.md` (`DEF-06-39-05`) rather than hidden; still worth naming plainly here because "reviewed four times" and "executed once" are very different claims and a careless reader could conflate them. |
| `.planning/REQUIREMENTS.md` | 152 | `- [ ] CONF-04` — the debt marker here is not a code comment but the requirement checkbox itself, and it is the one that matters most for this phase's goal | 🛑 Blocker for a `passed` verdict | This is not an oversight anyone is trying to fix quietly — it is named as a Phase 7 entry criterion — but a required Phase 6 requirement being unmet means the phase's own goal ("the intended tree ... on paper") is not fully proven for CONF-04's slice of it |

No unreferenced `TBD`/`FIXME`/`XXX` debt markers were found in any file this phase touched.

### Human Verification Required

None. The two open items (CONF-04 Jellyfin half; the SIGTERM/SIGPIPE delivery question) are both
resolvable by measurement against live state — an estate re-probe and a live signal-delivery drive,
respectively — not by human judgment calls (visual review, UX quality, etc.). Both are correctly
attached to Phase 7 entry criteria rather than requiring a human verifier's opinion here. The one
item carried in the prior VERIFICATION.md (beets-flask sign-in behind Authelia) was already answered
by the operator in that cycle and is not re-opened by this pass, which touched none of that surface.

### Gaps Summary

**One gap, cleanly bounded, and it is the same one the codebase has been telling every reader about
since 2026-09-21: CONF-04's Jellyfin half is open.** Everything else this phase set out to prove —
imports copy not move (CONF-01), the incremental trap is defeated (CONF-02), the destination-path
tree is exactly right (CONF-03/06), and match disambiguation actually flips a ranking (CONF-05) — is
independently re-confirmed in this pass, both by reading the unchanged `config.yaml` and by
personally executing all three of the phase's self-testable instruments right now, not by trusting
their SUMMARYs. The four-round review recursion that produced 24+17+10+10 = 61 findings across the
instrument scripts converged cleanly: round 4 found zero Critical issues, and every one of its ten
findings carries a traceable commit and artifact, all independently spot-checked here (the R4-02
self-test count, the R4-05 comment fix, `bash -n` cleanliness, and a clean `git status`).

The reason this report does not simply repeat the prior "passed, 6/6" verdict is that the prior
verification counted CONF-04 as a verified truth on the strength of its bookkeeping being honest,
rather than on the requirement being met. Those are different questions. REQUIREMENTS.md still
carries an unticked CONF-04, ROADMAP.md's own phase-status row still reads "In Progress," and the
project's own account of Phase 6's closure explicitly says "CLOSED WITH ONE OPEN REQUIREMENT —
CONF-04." A verifier's job is to check the goal was achieved, and one of the six requirements this
phase was scoped to close has not been. That does not make the four rounds of gap-closure work
worthless — the instrument-hardening work is real, independently confirmed, and converging — it
means the phase itself is not yet done, exactly as its own roadmap already says.

**Recommended path:** either (a) accept CONF-04's Jellyfin half as a deliberately-carried gap into
Phase 7 via an explicit override (the roadmap already argues for this, citing E6 as the owning
criterion, and an override would make that argument auditable rather than implicit), or (b) hold
Phase 6 open until Phase 7's first write allows the Jellyfin re-probe and the three pinned census
rows to actually move. Both are legitimate; what is not legitimate is closing Phase 6 as "passed,
6/6" while REQUIREMENTS.md still shows the box unticked.

---

_Verified: 2026-09-23T15:30:00Z_
_Verifier: Claude (gsd-verifier)_
