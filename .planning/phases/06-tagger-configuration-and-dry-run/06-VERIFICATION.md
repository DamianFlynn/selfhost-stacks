---
phase: 06-tagger-configuration-and-dry-run
verified: 2026-09-21T23:59:00Z
status: gaps_found
score: 5/6 must-haves verified
overrides_applied: 0
gaps:
  - truth: "D-04's 'no bare beet invocation opens the real library' assertion (plan 06-10 must-have, backing CONF-01/02/03) actually catches every beet invocation in the committed tree"
    status: failed
    reason: "Independently reproduced: the D-04 scan in scripts/quick-health-check.sh:1449-1594 text-matches the literal token `beet`, but every beet invocation added by this phase's own scripts is built from a variable ($BEET_BIN / $BEET), so D04_N_EXE=0 and the block prints a green tick over an empty set with no vacuity guard (unlike the two counts one screen above it, which do guard). Confirmed live: `scripts/check-beets-config.sh:769,785,796` run `${BEET_BIN} -c ${OVERLAY} config -d` (and `config -p -d`, `config -d -c`) against the real /config/library.db with NO `-l` at all — a real violation of the exact rule plan 06-10 (D-04) was built to enforce, sitting in a script this same phase committed. Documented as CR-01 (Critical) in 06-REVIEW.md, reviewed 2026-09-21T22:33:04Z, and confirmed by direct grep in this verification (raw=91, invocation-shaped-outside-.md=0, three variable-built violations found in check-beets-config.sh). Mitigated in practice by the D-29 library.db/state.pickle hash comparison (so no data damage occurred), but the detector itself is broken and the violation is real."
    artifacts:
      - path: "scripts/quick-health-check.sh"
        issue: "D-04 block (:1449-1594) has no vacuity guard on D04_N_EXE, unlike its own sibling guards on the raw and comment-stripped counts one screen above"
      - path: "scripts/check-beets-config.sh"
        issue: "Lines 769, 785, 796 open the real /config/library.db with no -l flag, violating the D-04 rule the phase itself wrote"
    missing:
      - "Add the vacuity guard to the D-04 block (elif D04_N_EXE -eq 0 -> UNKNOWN, not a pass)"
      - "Widen the D-04 pattern to catch variable-built invocations ($BEET_BIN/$BEET), or add -l /tmp/throwaway.blb to the three check-beets-config.sh calls, or record a named exemption"
      - "Carry CR-01 forward into deferred-items.md or ROADMAP.md's Phase 7 entry-criteria list (E1-E8) — it currently exists only in 06-REVIEW.md and would be lost the next time nobody re-reads that file"
human_verification:
  - test: "Sign in at https://beets.deercrest.info/ in a real browser"
    expected: "Authelia challenges first; the beets-flask UI loads only after authentication; no web terminal is offered anywhere in the UI (gui.terminal.enabled is false, confirmed in the deployed config, but not yet confirmed in a browser)"
    why_human: "The automated proof is a curl 302 against the origin, which carries no cookies — this estate's own documented failure mode (authelia-431-read-buffer.md) is exactly a curl test passing while every browser fails. Plan 06-06's own <human-check> is recorded as UNANSWERED in 06-06-SUMMARY.md and 06-06-PLAN.md."
---

# Phase 6: Tagger Configuration and Dry Run — Verification Report

**Phase Goal:** The intended tree proven on paper before it is produced on disk
**Verified:** 2026-09-21T23:59:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CONF-01: effective config shows imports copying, never moving | VERIFIED | `scripts/check-beets-config.sh` `expect_eq` on `import.copy=true` / `import.move=false`, read from arm 1 (`server-committed`, the object that actually imports), gated by a positive control (`gui.num_preview_workers`, `gui.terminal.start_path` — rc6 schema keys the CLI view cannot see) that proves the dump is genuinely the right object. `stacks/selfhosted/arrs/beets.md:1949+` quotes the 2026-09-21T22:04Z re-run: exit 0, `FAILURES total: 0`. |
| 2 | CONF-02: `incremental: yes` **with** `incremental_skip_later: yes`, and the trap is proven to fire | VERIFIED | Config read-back (`expect_eq`) plus `scripts/phase06-incremental-control.sh`, a genuine two-arm negative control: overlays A/B differ by exactly one key (`diff` returns exactly two lines), and drive opposite observable outcomes on first run — arm A (`no`) populates taghistory and does NOT re-offer the folder (trap fires); arm B (`yes`) leaves taghistory empty and DOES re-offer it (trap defeated). This is a falsifiable assertion, not a tautology. |
| 3 | CONF-03/CONF-06: a dry-run over a bucket-A sample produces the intended tree, with the fixture proven to predate the run it judges | VERIFIED | `06-EXPECTED-TREE.txt` is at git commit `cb9f49a` (`docs(06-05): commit the expected tree BEFORE the run it judges`), sha256 `37b2083e…`, 351 lines — confirmed via `git log --oneline` showing exactly one commit, i.e. never edited after landing. `artifacts/06-11-oracle-run.txt` + `06-11-wrote-nothing.txt` record `beet move -p` (not `--pretend`, per the D-33 instrument correction) over 174 real destinations, exit 0, ZERO LINES OF DIFFERENCE, five preconditions gating the diff, and a three-layer "wrote nothing" proof with actual sha256 hashes of `library.db`/`state.pickle` quoted identical before and after (independently spot-checked in this verification: hashes and mtimes are present and consistent between the artifact and the beets.md closure quote). |
| 4 | CONF-04: two consumers, two verdicts, correctly recorded as OPEN (not summed, not falsely marked complete) | VERIFIED (as a tracking claim — the underlying Jellyfin half is intentionally still open) | `REQUIREMENTS.md` line 152 shows `- [ ] CONF-04` (unchecked); row 286 records MA discharged / Jellyfin OPEN as two separate verdicts; `06-14-SUMMARY.md` frontmatter `requirements-completed: [CONF-01, CONF-02, CONF-03, CONF-05, CONF-06]` deliberately excludes CONF-04; `beets.md`'s criterion-4 table shows the two consumer rows side by side and states "never averaged into one verdict". `ROADMAP.md:1208` reads `Closed — 1 open requirement`, not `Complete`. All of this matches what the phase itself claims — verified, not merely repeated. |
| 5 | CONF-05: match disambiguation demonstrated by driving a real rank-flip, not merely set | VERIFIED | Config read-back shows `preferred.countries=["GB","US"]` (no `UK` entry), `preferred.original_year=true`, `musicbrainz.extra_tags` a 5-entry list. `artifacts/06-12-country-preference.txt` records the *Now!* row coming out identical under both country orderings (honestly reported, not hidden) and the demonstration relocated to the `Benson Boone / American Heart` row, where `['XW','US']` and `['US','XW']` produce a genuine rank-0 flip (XW vs US) at distance 0.0 — a real, falsifiable one-key experiment. |
| 6 | Supporting must-have (plan 06-10, backing CONF-01/02/03): no beet CLI invocation in the committed tree can open the real library without a throwaway `-l` and a `-c` overlay (D-04) | **FAILED** | Independently reproduced in this verification: `git grep -n -I -w -E 'beet' HEAD -- scripts stacks` → 91 raw hits, 0 invocation-shaped outside `*.md`. The scan is vacuous because this phase's own scripts build every `beet` call from a variable. `scripts/check-beets-config.sh:769,785,796` run `${BEET_BIN} -c ${OVERLAY} config -d`/`-p -d`/`-d -c` against the real `/config/library.db` with **no `-l` at all** — the exact violation the rule exists to catch, in the phase's own deliverable, undetected by the phase's own detector. Documented as CR-01 (Critical) in `06-REVIEW.md`, unresolved (only commit since the review, `e4a17fc`, adds the review document itself — no fix). Mitigated for THIS run by the D-29 hash comparison (library.db/state.pickle proven byte-identical), so no data damage occurred, but the assertion itself does not work and the finding has not been carried into `deferred-items.md` or `ROADMAP.md`'s Phase 7/9 entry criteria (checked E1-E8: none names it). |

**Score:** 5/6 truths verified (the sixth is a real, reproducible defect, not a documentation gap)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `stacks/selfhosted/arrs/beets/config.yaml` | Single vendored config, both containers, CONF-01/02/03/05 keys pinned explicitly | VERIFIED | Reviewed clean by 06-REVIEW.md (key-by-key comment-vs-effect check); `paths:` order on disk matches the order comments claim is load-bearing; no credential present. |
| `scripts/check-beets-config.sh` (914 lines) | Two-arm CONF-01/02/05 assertion against the object that actually imports | VERIFIED (substantive), with the CR-01 caveat above | Real `expect_eq`/`expect_ne` assertions with a positive control that can fail; `--self-test` exit 0, 5/5 cases (per 06-REVIEW.md, re-confirmed by phase close). |
| `scripts/phase06-oracle.sh` (2173 lines) | CONF-03/06 destination-path oracle | VERIFIED (substantive) | `--self-test` exit 0; `--run` produced the 174-destination zero-diff artifact reviewed above; `--baseline` and precondition gates confirmed present. |
| `scripts/phase06-incremental-control.sh` (959 lines) | CONF-02 two-arm negative control | VERIFIED (substantive) | Genuine one-key-apart overlays driving opposite outcomes; `--self-test` exit 0. |
| `06-EXPECTED-TREE.txt` | Fixture committed before the run it judges | VERIFIED | git history shows exactly one commit (`cb9f49a`), predating the 06-11 oracle run; hash matches the value quoted at phase close. |
| `06-REVIEW.md` | Code review findings, CR-01 fixed or explicitly accepted | **NOT WIRED** | The Critical finding (CR-01) and all 10 Warnings remain unaddressed; no fix commit, no override, no carry-forward reference from ROADMAP.md or deferred-items.md. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `scripts/quick-health-check.sh` D-04 block | `check-beets-config.sh` / `phase06-oracle.sh` / `phase06-incremental-control.sh` beet invocations | text-matched `beet` token scan | **NOT_WIRED** | The three scripts this phase built call `beet` exclusively through a variable, so the literal-token scan cannot see them at all — an unrelated code path (a comment or `.md` mention) is all it ever matches. |
| `06-EXPECTED-TREE.txt` | `beet move -p` output (`phase06-oracle.sh --run`) | `diff` via `manifest_compare`, gated by 5 preconditions | WIRED | Reproduced from the artifact: exit 0, zero lines of difference, preconditions evaluated first. |
| `06-12-country-preference.txt` | `check-beets-config.sh`'s CONF-05 read-back | shared `preferred.countries` config key, cross-checked by a live MusicBrainz rank experiment | WIRED | Config value and the driven experiment agree and are independently reproducible from the artifact. |
| `check-music-consumers.sh` CONF-04 rows | `quick-health-check.sh` exit code | fold-in / exit propagation | **PARTIAL** | Documented separately as WR-03 in 06-REVIEW.md: the CONF-04 "pending" rows print a yellow warning but do not affect `FAILURES`, so a regression back to baseline after Phase 7 discharges it would still exit 0. Not fixed as of this verification. |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| CONF-01 | 06-01, 06-07 | Imports copy, never move | SATISFIED | See Truth #1 |
| CONF-02 | 06-01, 06-07, 06-08 | `incremental` + `incremental_skip_later` | SATISFIED | See Truth #2 |
| CONF-03 | 06-01, 06-05, 06-09, 06-11 | Path formats produce the intended tree | SATISFIED | See Truth #3 |
| CONF-04 | 06-02, 06-03, 06-13 | Multi-artist parsing in both consumers | **PARTIALLY SATISFIED, CORRECTLY RECORDED AS OPEN** | MA half discharged; Jellyfin half open by measurement, not by omission — matches project's own disposition, not a verification-hidden gap |
| CONF-05 | 06-01, 06-07, 06-11, 06-12 | Match disambiguation demonstrated | SATISFIED | See Truth #5 |
| CONF-06 | 06-02, 06-09, 06-11 | The dry-run's instrument (`beet move -p`) proves the tree, and wrote nothing | SATISFIED | See Truth #3 (same evidence chain; CONF-06 is CONF-03's instrument per REQUIREMENTS.md's own note) |

No orphaned requirements: REQUIREMENTS.md's phase-6 mapping (line 349) lists exactly CONF-01…06, matching every plan's `requirements:` frontmatter field.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `scripts/quick-health-check.sh` | 1449-1594 | Assertion evaluates over an empty/wrong set with no vacuity guard (CR-01) | Blocker | The estate's standing "no bare beet invocation" rule cannot currently fail, and a live violation of that exact rule sits uncaught in the same phase's own deliverable |
| `scripts/check-beets-config.sh` | 769, 785, 796 | Opens real `/config/library.db` with no `-l` (mitigated by hash proof) | Warning | Rule violation with a working compensating control (D-29 hash comparison), not a live data-integrity incident |
| `scripts/check-music-consumers.sh` | 1304, 1408, 1587-1601 | CONF-04 "pending" state cannot fail the run's exit code (WR-03) | Warning | A future regression on the discharged rows would still print exit 0 |
| Various (WR-01, 02, 04, 06-10, IN-01…13) | — | Assorted quoting, vacuity-guard, and hygiene defects documented in 06-REVIEW.md | Warning/Info | None fixed as of this verification (single post-review commit only adds the review document) |

No `TBD`/`FIXME`/`XXX` markers were found in the phase's modified files (the debt-marker gate does not fire); the gap above is a code-review finding, not an inline debt marker.

### Human Verification Required

### 1. Beets-flask UI sign-in behind Authelia

**Test:** Sign in at `https://beets.deercrest.info/` in a real browser.
**Expected:** Authelia challenges first; the beets-flask UI loads only after authentication; no web terminal is offered anywhere in the UI.
**Why human:** The automated proof is a curl-based 302, which carries no cookies. This estate's own documented failure mode (`authelia-431-read-buffer.md`) is precisely a curl test passing while every browser fails. Plan 06-06's own `<human-check>` block is recorded as UNANSWERED in both `06-06-PLAN.md` and `06-06-SUMMARY.md`.

### Gaps Summary

The phase's central claim — CONF-01, CONF-02, CONF-03/06 and CONF-05 — is genuinely and strongly proven. The evidence is not vacuous: `check-beets-config.sh` asserts against a positive-control-gated read of the object that will actually import; `phase06-incremental-control.sh` is a real one-key-apart negative control driven to opposite outcomes; `phase06-oracle.sh` produces a 174-line zero-diff against a fixture independently confirmed (via `git log`) to predate the run it judges, backed by a three-layer hash proof that nothing was written. CONF-04 is correctly and honestly recorded as OPEN on its Jellyfin half — this matches the project's own disposition and `ROADMAP.md`'s `Closed — 1 open requirement` line, not a hidden gap.

The one substantive gap this verification adds beyond what the phase already disclosed: the phase's own post-closure code review (`06-REVIEW.md`, run 2026-09-21T22:33:04Z, after 06-14 closed the phase) found a Critical, reproducible defect — the D-04 "no bare beet invocation" safety assertion is vacuous over exactly the scripts this phase built, and a real violation of that rule sits in `check-beets-config.sh` itself (undetected by the detector, though mitigated in practice by an unrelated hash-based control). That finding, plus 10 Warnings, remains completely unaddressed: the only commit after the review adds the review document itself, with no fix, no override, and no carry-forward into `deferred-items.md` or `ROADMAP.md`'s Phase 7/9 entry-criteria list. Given this phase's stated dominant defect class was exactly "assertions that cannot fail," an unresolved, self-diagnosed instance of that same defect class — undiscovered by tracking after the fact — is reported here as a gap rather than smoothed into the pass.

Also outstanding, and already correctly flagged by the phase itself: plan 06-06's human-check (browser sign-in behind Authelia) has never been answered.

---

_Verified: 2026-09-21T23:59:00Z_
_Verifier: Claude (gsd-verifier)_
