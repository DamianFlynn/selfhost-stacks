---
phase: 04-collapse-to-one-tagger
verified: 2026-09-14T00:00:00Z
status: gaps_found
score: 4/5 success criteria verified (1 OPEN, by the phase's own evidence contract, across two observation windows)
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5 success criteria verified
  gaps_closed: []
  gaps_remaining:
    - "ROADMAP Phase 4 success criterion 3 / TAGR-04's behavioural half: a SABnzbd music job completes without invoking any tagger at all, proven by a PRE-HOOK-vs-COMPLETION byte comparison"
  regressions: []
gaps:
  - truth: "The beets block is stripped from audio.bash, and a SABnzbd music job completes without invoking any tagger at all (ROADMAP Phase 4 success criterion 3 / TAGR-04)"
    status: partial
    reason: >
      The static half remains verified: `grep -cE '^[[:space:]]*beet ' stacks/selfhosted/arrs/sabnzbd/audio.bash`
      = 0 (re-run in this verification), and the vendored-file drift guard is green. The behavioural
      half is still explicitly OPEN, now after TWO observation windows and FIVE real music jobs, per
      the phase's own evidence contract (04-D12-EVIDENCE.md, both § 6's `^Verdict: OPEN` line and
      § 7's `^Verdict (window 2): OPEN — ` line, both independently re-confirmed line-anchored in
      this verification: `grep -cE '^Verdict: '` = 1, `grep -cE '^Verdict \(window 2\): '` = 1,
      unanchored `grep -c 'Verdict (window 2)'` = 2 — the second hit is the pre-declared decoy at
      line 265, correctly not the one either 04-16 or this verification read from). Gap-closure plans
      04-14 through 04-16 ran and materially improved the instrument, but did not close the gap:
        - 04-14 rebuilt the watcher to snapshot under `/mnt/tank/downloads/incomplete` — structurally
          before SABnzbd's move and therefore before the hook — and drove it through eight synthetic
          controls (SC-1 through SC-8) before spending a real job on it, including a required FAIL
          (SC-2) and four distinct UNPROVEN outcomes (SC-3, SC-6, SC-7, SC-8). This work is real and
          verified: the two scripts' sha256 values are recorded and the self-test record's eight
          `STATUS=` tokens were lifted from the judge's own stdout, not transcribed.
        - 04-15 ran a second window (2026-09-13T22:04:18Z → 22:27:08Z) over three real music jobs.
          All three returned `STATUS=UNPROVEN reason=no-attributed-pre` with `files_in_both=0`: under
          `direct_unpack=1`, two jobs never exposed a single audio file to a 1-second poll of the
          incomplete tree before SABnzbd moved them, and the third was still growing when moved, with
          its one hash attempt refused mid-pass by the instrument's own protocol (a correctly-firing
          safety mechanism, not a bug). Side effects were clean for the third window running (0
          library.blb, 0 .bak, 0 beets.log, 0 "SUCCESS: Matched with beets"), and the § 3
          `ReplaygainTagging` prerequisite held at both ends, proven this time by `find -newer`
          returning nothing at all (extended.conf was never written during the window).
        - 04-16 transcribed the window-2 verdict into `stacks/selfhosted/arrs/beets.md` under a
          re-dated INTERIM-STATUS heading (`## Phase 4 — interim status (2026-09-14): criterion 3
          OPEN`), not a closure heading, with the criterion-3 table row carrying the literal token
          `window 2: OPEN`. Both the heading and the row were verified present and correctly worded
          in this verification's own read of the live file.
      **The gap is not closed. It is now better understood and has survived a harder, more
      instrumented attempt to close it.** 04-D12-EVIDENCE.md's own § 5 window rules — amended and
      committed at `0022e91`, BEFORE window 2 opened, so they cannot have been fitted to its outcome
      — require OPEN whenever no valid PRE-HOOK snapshot exists, and none exists for any of the five
      real jobs measured across both windows.
    artifacts:
      - path: ".planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md"
        issue: "§ 6 (window 1) and § 7 (window 2) both record Verdict: OPEN / Verdict (window 2): OPEN. § 7's closing section ('What would close it, for whoever carries criterion 3 forward') states both tried capture points — the destination tree and a poll of the incomplete tree — are now exhausted."
      - path: "stacks/selfhosted/arrs/beets.md"
        issue: "Correctly reflects OPEN under an interim-status (not closure) heading, criterion-3 row carries 'window 2: OPEN'"
    missing:
      - "A byte-capture point that survives SABnzbd's direct_unpack=1 — one that does not depend on sampling a folder while SABnzbd is still actively draining it. 04-D12-EVIDENCE.md § 7 states both previously-proposed designs (destination-tree poll, incomplete-tree poll) are now measured exhausted; a third design is needed, or:"
      - "AN EXPLICIT HUMAN DECISION accepting the threefold, unanimous, clean side-effect evidence (5 real jobs, 2 windows, 0 tagger artefacts, 0 success lines, 0 database regeneration) as sufficient grounds to discharge criterion 3 without a byte proof. This is a policy call this verifier is not authorized to make on the developer's behalf — see Gaps Summary below."
deferred:
  - truth: "CLAUDE.md and .planning/PROJECT.md's unqualified 'beets has no undo command' claim, narrower than reality per beets-flask rc6's UNDO IMPORT"
    addressed_in: "Phase 7"
    evidence: "deferred-items.md DEF-04-01, explicit written deferral by plan 04-13, destination is Phase 7's 'undo exercised' criterion"
  - truth: "beets.md's two open config gaps (match.preferred.countries UK/US tie-break; fromfilename/edit for bucket C)"
    addressed_in: "Phase 6"
    evidence: "04-13-SUMMARY / 04-16-SUMMARY living-text table; Phase 6 owns closing them on the survivor's deliberately minimal vendored config (D-27)"
human_verification: []
---

# Phase 4: Collapse to One Tagger — Verification Report (Re-Verification)

**Phase Goal:** One tagger, one database, no idle container holding a rw mount — independently shippable
**Requirements:** TAGR-03, TAGR-04, TAGR-05
**Verified:** 2026-09-14T00:00:00Z
**Status:** gaps_found
**Re-verification:** Yes — following gap-closure plans 04-14, 04-15, 04-16 against the prior 04-VERIFICATION.md (2026-09-13T13:00:00Z, status gaps_found, score 4/5)

## Goal Achievement

### Observable Truths (ROADMAP Phase 4 Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Exactly one tagger definition exists in the repo; losing definitions deleted (not commented out); soulbeet gone, issue #306 closed | ✓ VERIFIED (unchanged, regression check) | Live `quick-health-check.sh` run in this verification: `tagger definitions: 1`. No plan since the prior verification touched tagger definitions. |
| 2 | Renovate no longer pins a retired tagger (including the wrtag `<0.30.0` rule); `renovate-config-validator` passes | ✓ VERIFIED (unchanged, regression check) | No plan since the prior verification touched `renovate.json5`. Prior verification's evidence stands. |
| 3 | The beets block is stripped from `audio.bash`, and a SABnzbd music job completes without invoking any tagger at all | ✗ **STILL OPEN (gap, not regression)** | Static half re-confirmed in this verification: `grep -cE '^[[:space:]]*beet ' stacks/selfhosted/arrs/sabnzbd/audio.bash` → 0. Behavioural half re-examined at full depth (see below): OPEN across two windows and five real jobs. See Gaps below. |
| 4 | Every remaining beets config declares `musicbrainz`; MB-only probe pair shows 0 candidates on the broken config vs ≥1 on the fixed config | ✓ VERIFIED (unchanged, regression check) | No plan since the prior verification touched either beets config. Prior verification's evidence stands. |
| 5 | Estate is strictly better: one tagger, one `library.db`, zero rw library mounts on non-tagger/tagger-capable containers (Jellyfin's D-21 consumer exception printed separately) | ✓ VERIFIED (re-run live, this verification) | `bash scripts/quick-health-check.sh` run live by this verifier, exit 0: `tagger definitions: 1`, `beets databases: 1`, `tagger databases: 0`, `retired paths present: 0`, `rw on Music, non-tagger: 0`, `rw on Music, tagger-capable: 0`, `rw on Music, Jellyfin D-21: 1` (printed separately per the F10 amendment), `tagger-capable containers: 2`, `FAILURES total: 0` across every section (music-freeze, consumers, transcode retention). 96 containers running, drift guard green (`vendored files match (3)`). |

**Score:** 4/5 success criteria verified. Criterion 3 is STILL OPEN by the phase's own written evidence contract — not by any inference of this verification, and not for lack of effort by the three gap-closure plans that ran since the prior report.

### Gap-Closure Plan Verification (04-14, 04-15, 04-16)

| Plan | Claim | Independently re-checked | Result |
|---|---|---|---|
| 04-14 | Built `watch-d12b.sh` / `judge-d12b.sh`, drove 8 synthetic controls (SC-1..SC-8) before spending a real job, amended 04-D12-EVIDENCE.md §§ 1/5 in-band, committed `0022e91` before window 2 opened | `git show --stat 0022e91` confirms exactly one file touched, committer date `2026-09-13 22:52:21 +0100`. `0022e91` is an ancestor of HEAD (`git log` shows it in the commit chain leading to `64e250b`). The SC-2 (must-FAIL) and SC-6/SC-7/SC-8 (must-UNPROVEN) results are recorded in 04-14-SUMMARY.md as lifted from judge stdout | ✓ Confirmed as claimed |
| 04-15 | Ran window 2 (2026-09-13T22:04:18Z → 22:27:08Z) over 3 real jobs, all `STATUS=UNPROVEN reason=no-attributed-pre`, recorded `Verdict (window 2): OPEN` at 04-D12-EVIDENCE.md § 7, committed `4a4543f` | `git show --stat 4a4543f` confirms one file, committer date `2026-09-13 23:56:47 +0100` (after 0022e91, before 64e250b — correct order). Line-anchored re-grep in this verification: `^Verdict \(window 2\): ` → exactly 1 match, reading `OPEN — three music jobs...`. Unanchored count = 2, confirming the decoy at line 265 exists as documented and was correctly not used | ✓ Confirmed as claimed |
| 04-16 | Transcribed window-2 OPEN into `stacks/selfhosted/arrs/beets.md` under an interim-status heading (not closure), row 3 carries literal `window 2: OPEN`, re-ran both standing guards against landed text, committed `64e250b` | `git show --stat 64e250b` confirms one file (`stacks/selfhosted/arrs/beets.md`) touched, committer date `2026-09-14 00:10:46 +0100`. Live read of `beets.md`: heading at line 1126 reads `## Phase 4 — interim status (2026-09-14): criterion 3 OPEN` (not `## Phase 4 — one tagger...` or any closure form); criterion table row 3 reads `**\`window 2: OPEN\`**`. `quick-health-check.sh` re-run live by this verifier independently reproduces the exact census counters 04-16 quotes | ✓ Confirmed as claimed |

**Conclusion: the gap-closure narrative in the task brief is accurate.** All three plans did what they say they did, the evidence contract was genuinely amended before the second window (not fitted after the fact — timestamps and commit ancestry both check out), and the honest result is that criterion 3 remains OPEN, now on stronger and more thoroughly self-tested instrumentation, having failed to produce a valid PRE-HOOK snapshot on any of five real jobs across two windows.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `stacks/selfhosted/arrs/sabnzbd/audio.bash` | beets invocation removed | ✓ VERIFIED | `grep -cE '^[[:space:]]*beet '` → 0; vendored-drift guard green |
| `.planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md` | evidence contract with a verdict for each window | ✓ EXISTS, substantive, both verdicts read OPEN | § 6 verdict line + § 7 verdict line both present, both line-anchored to exactly 1 match each |
| `stacks/selfhosted/arrs/beets.md` | estate record matching the evidence file's verdict | ✓ VERIFIED | Interim-status heading + row 3 both match window-2 OPEN, confirmed by live read |
| Host: `watch-d12b.sh`, `judge-d12b.sh`, `selftest-14.txt` | proven instrument, then removed | ✓ Removal claim internally consistent | Both SUMMARY files record deliberate deletion behind the S5 fence after their evidence was committed; this verifier did not independently re-check host scratch absence (would require a live SSH tree walk not warranted for a negative-existence claim already evidenced by two independent SUMMARY self-checks) |

### Key Link / Instrument Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `audio.bash` (beet invocation) | (removed) | static diff against vendored copy | ✓ WIRED (absence confirmed) | `grep -cE '^[[:space:]]*beet '` → 0, re-run in this verification |
| SABnzbd hook execution | PRE-HOOK byte snapshot, incomplete-tree design (04-14) | `watch-d12b.sh` polling `/mnt/tank/downloads/incomplete` | ✗ **STILL NOT WIRED, for a new and different reason than window 1** | Window 1's failure was a timestamp race (destination-tree poll always too late). Window 14/15's fix removed that race structurally, but on real jobs under `direct_unpack=1`, the audio either never becomes visible to the incomplete-tree poll at all (2 of 3 jobs) or is still being written when SABnzbd moves it (1 of 3, hash pass correctly refused). The instrument works exactly as designed — see the positive control in § 7 (a fourth, excluded row, published complete when a folder genuinely rested) — but no real music job's audio profile has yet given it a window to publish into |
| `check-music-freeze.sh` census | `quick-health-check.sh` routine path | `TAGGER_CENSUS_PROMOTED=1` | ✓ WIRED | Re-run live in this verification, unprompted counters print correctly |
| `quick-health-check.sh` vendored-file drift block | routine path | `VENDORED_DRIFT_PROMOTED=1` | ✓ WIRED | Re-run live: `✅ vendored files match (3)` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full routine health check exits clean (live, this verification) | `bash scripts/quick-health-check.sh` | Exit 0, 96 containers running, all census counters at target, sole `❌` is the pre-existing report-only "Traefik dashboard: Not accessible" (predates this phase) | ✓ PASS |
| audio.bash beet invocation still absent (live, this verification) | `grep -cE '^[[:space:]]*beet ' stacks/selfhosted/arrs/sabnzbd/audio.bash` | 0 | ✓ PASS |
| Window-2 verdict line-anchored and unambiguous (live, this verification) | `grep -cE '^Verdict \(window 2\): '` vs unanchored `grep -c 'Verdict (window 2)'` | 1 vs 2 — confirms both the real verdict and the pre-declared decoy exist exactly as 04-16 describes | ✓ PASS (parsing trap independently reproduced, not just trusted) |
| Window-1 verdict line still intact and unrevised | `grep -cE '^Verdict: '` | 1, text matches prior verification's quotation verbatim | ✓ PASS |
| Gap-closure commits are real, ordered, and ancestors of HEAD | `git show --stat` on `0022e91`, `4a4543f`, `64e250b`; `git log --oneline` | All three exist, touch exactly the files each SUMMARY claims, in the correct chronological order | ✓ PASS |
| Criterion 3 behavioural half proven by real bytes | `04-D12-EVIDENCE.md` §§ 6-7 | Both OPEN | ✗ FAIL (see Gaps — this is the one behavior the phase still cannot close) |

### Probe Execution

No repo-tracked probe scripts exist for this phase (`find scripts -path '*/tests/probe-*.sh'` → empty). The D-12 instrument (`watch-d12b.sh`, `judge-d12b.sh`) was intentionally host-scratch-only per this phase's own conventions and was deliberately deleted by 04-15 after its evidence was committed — this is by design, not an omission, and is recorded as such in both 04-14-SUMMARY.md and 04-15-SUMMARY.md.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| TAGR-03 | 04-01, 04-03, 04-04, 04-05, 04-06, 04-07, 04-13 | ✓ SATISFIED | Criteria 1, 2, 5 hold, unchanged since prior verification |
| TAGR-04 | 04-01, 04-02, 04-03, 04-06, 04-07, 04-10, 04-11, 04-12, 04-13, 04-14, 04-15, 04-16 | ✗ **BLOCKED (partial), unchanged in substance** | The `#306`/audio.bash-strip halves are satisfied. The "a SABnzbd music job completes without invoking any tagger" behavioural half is STILL OPEN after two full observation windows and a rebuilt, self-tested instrument (04-14, 04-15). REQUIREMENTS.md's own Phase 4 checkboxes for TAGR-03/04/05 remain unchecked (`- [ ]`), consistent with this reading — no plan updated them, correctly, since the phase is not closable |
| TAGR-05 | 04-04, 04-08, 04-09, 04-10, 04-11, 04-13 | ✓ SATISFIED | Criterion 4 holds, unchanged since prior verification |

No orphaned requirement IDs found — TAGR-03/04/05 are the only IDs REQUIREMENTS.md maps to Phase 4, and all three are claimed across the 16 plans' frontmatter (04-14/15/16 all declare `requirements: [TAGR-04]` and correctly report `requirements-completed: []` in every one of their three SUMMARY files, because none of them closed the requirement).

### Anti-Patterns Found

None found in phase-modified files that constitute a blocker. No unresolved `TBD`/`FIXME`/`XXX` markers in `04-D12-EVIDENCE.md` or `stacks/selfhosted/arrs/beets.md`. The host-scratch instrument scripts (`watch-d12b.sh`, `judge-d12b.sh`) were never committed to the repo (confirmed: `git ls-files | grep -E 'watch-d12b|judge-d12b|selftest-14'` → empty), consistent with the phase's own read-only-estate convention.

### Deferred Items (recorded, not gaps of this phase)

| Item | Addressed In | Evidence |
|---|---|---|
| `CLAUDE.md:152` / `.planning/PROJECT.md:187` unqualified "beets has no `undo` command" claim | Phase 7 | `deferred-items.md` DEF-04-01, unchanged since prior verification |
| `beets.md`'s two open config gaps (`match.preferred.countries`, `fromfilename`/`edit` for bucket C) | Phase 6 | Unchanged since prior verification |

### Human Verification Required

None routed as a standard "please eyeball this" item — see the Decision Point below instead, which is a different kind of escalation.

## Gaps Summary

**Regression check: none.** All four previously-VERIFIED criteria (1, 2, 4, 5) were re-checked in this
verification — criterion 5 was re-run live against the estate, criteria 1/2/4 were confirmed
untouched by any plan since the prior report — and all four still hold.

**Criterion 3 — "a SABnzbd music job completes without invoking any tagger at all" — remains OPEN.**
This is not a case of a SUMMARY overclaiming and this verification catching it. It is also not a
case of the gap-closure work being wasted: 04-14 rebuilt the instrument from a timestamp-race design
to a structurally-ordered one, proved it capable of returning FAIL and four distinct flavors of
UNPROVEN on eight synthetic controls before touching a real job, and 04-15 then ran that improved
instrument over three more real jobs in a second window. Every one of the five real jobs measured
across both windows — two in window 1, three in window 2 — failed to produce a valid PRE-HOOK
snapshot, for two distinct and now fully measured mechanisms: under SABnzbd's `direct_unpack=1`,
audio frequently never becomes visible to a one-second poll of the `incomplete/` tree before the
move happens, and on the one job where it did become visible, it was still being extracted when the
move occurred, and the instrument correctly refused to publish a snapshot that might have straddled
that move. The instrument's positive control — a fourth, excluded history row where a folder
genuinely rested under `incomplete/` for 57 consecutive stable polls — proves the watcher publishes
correctly when given the chance; real jobs on this estate have simply not given it that chance yet.

**Side-effect evidence is now threefold and unanimous**: across five real post-strip music jobs, zero
beets database activity, zero `.bak` artefacts beyond the pre-declared SABnzbd exception, zero
`SUCCESS: Matched with beets` log lines, and `extended.conf` provably untouched. This is strong
circumstantial evidence the estate is clean. It is explicitly **not** the byte proof criterion 3's
own evidence contract requires, and 04-D12-EVIDENCE.md's own window rules — amended and committed
before window 2 opened, so they cannot have been written to fit its outcome — require OPEN whenever
no valid PRE-HOOK snapshot exists. This verification will not relabel that OPEN as PASSED on the
strength of the weaker evidence; doing so would be exactly the kind of after-the-fact reinterpretation
the amendment's own ordering (contract committed, then window run) was designed to prevent.

**This is now a decision, not a measurement.** 04-D12-EVIDENCE.md § 7 states plainly that both
previously-proposed capture points — a poll of the destination tree (window 1) and a poll of the
incomplete tree (window 2) — are exhausted, and "a third window with the same instrument would most
likely produce the same result." Closing criterion 3 by bytes now requires either:

1. **A new capture mechanism** that does not depend on sampling a folder while SABnzbd is actively
   draining it under `direct_unpack` — for example, hooking SABnzbd's own extraction/unpack
   completion event rather than polling a filesystem tree from outside, or disabling
   `direct_unpack` for one test run so the audio set is stable before the folder ever appears. Both
   are estate/instrument changes beyond what this phase's plans have attempted.
2. **An explicit decision** that the threefold clean side-effect evidence (5 jobs, 2 windows, 0
   tagger artefacts of any kind) is sufficient grounds to discharge criterion 3 without a byte
   proof, accepting the small residual risk that "no evidence of tagging" is not quite the same
   claim as "proven absence of tagging at the byte level."

**Neither option was exercised by 04-14/04-15/04-16, correctly** — all three plans record the
decision as inherited rather than taken, and this verifier is not authorized to make that policy
call unilaterally. If the developer wants to accept option 2 and close the phase on the strength of
the current evidence, the mechanism is a VERIFICATION.md override:

```yaml
overrides:
  - must_have: "The beets block is stripped from audio.bash, and a SABnzbd music job completes without invoking any tagger at all (ROADMAP Phase 4 success criterion 3 / TAGR-04)"
    reason: "Accepting threefold unanimous side-effect evidence (5 real jobs across 2 windows: 0 beets database activity, 0 .bak artefacts beyond the pre-declared exception, 0 SUCCESS log lines, extended.conf provably untouched) as sufficient proof the estate does not tag, in place of an unattainable byte-level PRE-HOOK/COMPLETION comparison under SABnzbd's direct_unpack=1"
    accepted_by: "<developer name>"
    accepted_at: "<ISO timestamp>"
```

Absent that override, the estate is genuinely and measurably better than it started — one tagger
definition, one database, the wrtag pin gone, soulbeet retired and issue #306 closed, both
remaining beets configs declaring `musicbrainz`, zero non-consumer rw mounts — but the ROADMAP
contract for Phase 4 is not fully met, and `status: passed` would misrepresent that a second time.

---

_Verified: 2026-09-14T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
