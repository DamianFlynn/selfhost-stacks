---
phase: 06-tagger-configuration-and-dry-run
verified: 2026-09-22T10:30:49Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "D-04's 'no bare beet invocation opens the real library' assertion (backing CONF-01/02/03) actually catches every beet invocation in the committed tree — CR-01, both halves"
  gaps_remaining: []
  regressions: []
human_verification_carried_forward:
  - test: "Sign in at https://beets.deercrest.info/ in a real browser"
    status: "answered by the operator 2026-09-22, discharged on its load-bearing half (Authelia challenges, UI loads after auth); the web-terminal absence sub-clause remains asserted by config (`gui.terminal.enabled: false`) and container log rather than confirmed by eye. Recorded here as carried forward from the prior VERIFICATION.md, not re-opened — this re-verification's scope is CR-01 and did not touch beets-flask's auth path."
---

# Phase 6: Tagger Configuration and Dry Run Verification Report

**Phase Goal:** The surviving tagger's configuration is shown to produce the intended tree on
paper, at the last cheap moment before a path-format error can be applied at scale.
**Verified:** 2026-09-22T10:30:49Z
**Status:** passed
**Re-verification:** Yes — after gap closure (plans 06-15 through 06-21, wave 6-9, executed
2026-09-22)

## What changed since the prior verification

The prior pass (`2026-09-21T23:59:00Z`) scored 5/6 must-haves. The single failure was CR-01:
`scripts/quick-health-check.sh`'s D-04 "no bare `beet` invocation opens the real library"
assertion asserted over an **empty set** (the literal-token pattern could not see this phase's
own `$BEET_BIN`-built invocations) and printed a green tick over nothing, while a live violation
sat uncaught in `scripts/check-beets-config.sh` (three invocations opening the real
`/config/library.db` with no `-l`). Seven gap-closure plans (06-15..06-21) were executed to close
CR-01 and disposition all 24 findings from the post-closure code review (`06-REVIEW.md`). This
re-verification re-checks CR-01 at full depth and re-confirms the five previously-passed truths
with a regression check, per the re-verification protocol.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CONF-01: effective config shows imports copying, never moving | VERIFIED (regression check) | `stacks/selfhosted/arrs/beets/config.yaml:311-312` still reads `copy: yes` / `move: no`. `bash scripts/check-beets-config.sh --self-test` re-run in this verification: exit 0, `all 6 cases behaved as expected (5 of them red)` — one more case than the prior pass (06-15 added a sixth, source-level case; see truth 6). |
| 2 | CONF-02: `incremental: yes` **with** `incremental_skip_later: yes`, trap proven to fire | VERIFIED (regression check) | `config.yaml:323-324` unchanged. `scripts/phase06-incremental-control.sh` unchanged in its two-arm negative-control design; plan 06-20 (a gap-closure plan touching this file) only added a loud `exit 3` on usage errors, an unpinned path count, and a stated RED-vs-UNKNOWN precedence — none of which alters the two-arm proof itself. `06-20-SUMMARY.md` Self-Check: PASSED. |
| 3 | CONF-03/CONF-06: dry-run over bucket-A sample produces the intended tree, fixture proven to predate the run | VERIFIED (regression check) | `06-EXPECTED-TREE.txt` git history still shows exactly one commit (`cb9f49a`), unchanged since the prior pass. `scripts/phase06-oracle.sh` was touched by gap-closure plans 06-18 (remote-command construction: allow-list fences, positional-parameter paths) and 06-19 (fail-closed assertions: vacuity guards, empty-manifest guard, DJ-stratum guard) — both are hardening of the instrument's *safety and honesty*, not changes to the destination-path logic the 174-line zero-diff already proved. Neither plan re-ran `--run` (correctly: importing is out of scope for a config-hardening gap closure), so the committed 06-11 zero-diff artifact remains the evidence for the tree itself, and both plans' own self-tests pass. |
| 4 | CONF-04: two consumers, two verdicts, correctly recorded as OPEN (not summed, not falsely marked complete) | VERIFIED — unchanged, correctly still open | `REQUIREMENTS.md:152` still `- [ ] CONF-04` (unchecked). `ROADMAP.md:993` still reads "CLOSED WITH ONE OPEN REQUIREMENT — CONF-04". Gap-closure plan 06-17 added a machine-readable `exit 3` to `check-music-consumers.sh` for CONF-04's pending state (WR-03) — this makes the open state *visible to tooling*, it does not close it. Measured 2026-09-22 by 06-17: JF pending 3 / at target 0, MA reported 1 / at target 2 — same figures 06-14 recorded at Phase 6's original close. Per the task's explicit instruction, this is a deliberate, correct state and is not a gap. |
| 5 | CONF-05: match disambiguation demonstrated by driving a real rank-flip | VERIFIED (regression check) | `config.yaml:357` still `countries: ['GB', 'US']`, no `UK`. Not touched by any gap-closure plan. The driven rank-0 flip on `Benson Boone / American Heart` (`artifacts/06-12-country-preference.txt`) is unaffected. |
| 6 | Supporting must-have (backing CONF-01/02/03): no `beet` CLI invocation in the committed tree can open the real library without a throwaway `-l` and a `-c` overlay (D-04) — **the prior FAILED truth** | **VERIFIED — FIXED, both halves, driven** | **Live half (plan 06-15, commit `8d74d40`):** `grep -c` over comment-stripped `scripts/check-beets-config.sh` for `${BEET_BIN} -l ${THROWAWAY_DB} -c ${OVERLAY} config` returns exactly 3 (confirmed directly: lines 892, 908, 919). `THROWAWAY_DB="/tmp/p6-cbc-throwaway.blb"` is a plain constant (line 130), no `${VAR:-}` override form. The throwaway library was *measured* to exist in the container (53248 bytes, beetle-owned) — the real `/config/library.db` was never opened, not merely never changed. `--self-test` re-run in this verification: exit 0, 6 cases, 5 red, including the new case 6 (`D-04 contract: every beet invocation in this script's own source carries -l ${THROWAWAY_DB} AND -c ${OVERLAY}`), directly observed printing its driven-red line for the synthetic `-c`-only invocation. **Detector half (plan 06-16, commit `5f4d0c0`):** confirmed directly in `scripts/quick-health-check.sh`: `D04_INV_RE` (line 1766) now carries a `BEET[A-Z_]*` alternation branch; `elif [ "$D04_N_EXE" -eq 0 ]` vacuity guard exists (line 1791) printing `⚠️ UNKNOWN`; `D04_EXEMPT_BASELINE="${D04_EXEMPT_BASELINE:-5}"` (line 794) and `D04_EXEMPT_RE` (line 1770) are present, keyed on both `phase06-oracle.sh`'s `$SCRATCH_OVERLAY` and `phase06-incremental-control.sh`'s `$ROOT/overlay.yaml`, with an exempt-count-off-pin red (line 1812-1813). Measured executable count went 0 → 8 (3 asserted + 5 exempt), hand-reproduced from the host's own `git grep` and agreeing with the block's printed figures at every position (`artifacts/06-16-d04-driven.txt`). Six branches driven live, including an unplanned one: the runbook prose describing the fix was itself an invocation shape and tripped the doc-baseline pin (2→3), which was then rephrased rather than the pin raised — direct evidence the detector works on content nobody wrote to be caught. |

**Score:** 6/6 truths verified (up from 5/6 — CR-01 is closed)

### Deferred / Carried Residue (informational, not gaps)

Per the task's explicit instruction, these recorded states are correct and are not reported as
failures:

1. **CONF-04's Jellyfin half is OPEN by design** — named ROADMAP Phase 7 entry criterion **E6**.
2. **The D-04 block in `quick-health-check.sh` reports UNKNOWN against the live estate** — the
   host (`/mnt/fast/stacks`) is at a pre-Phase-6 commit (`c67d497`); the block correctly refuses to
   report green until the operator pushes and the host pulls. Confirmed in this verification by
   reading `06-16-SUMMARY.md`'s "N-1" entry and `06-DISPOSITIONS.md`'s "deliberate non-findings"
   §2, both of which state this explicitly and give the exact clearing condition.
3. **`quick-health-check.sh` will exit non-zero on the consumers block** once Phase 6 is deployed,
   until E6 discharges CONF-04 — documented inline (the "twelfth notice") and in
   `06-DISPOSITIONS.md`'s "deliberate non-findings" §3.

Additionally, two residues are worth naming because they are the honest edges of this gap
closure's own work, not new defects introduced by it:

4. **`DEF-06-21-06`** — the D-04 exemption register's per-line keying (as opposed to the
   file-level partition) has not been driven: control 1 in `06-16-d04-driven.txt` proved a
   non-compliant invocation planted in a *third* file lands in the asserted (red) set, but did not
   prove that a non-compliant invocation planted *inside* `phase06-oracle.sh` without the
   `$SCRATCH_OVERLAY` substring correctly falls out of the exemption and into the asserted set.
   Named by plan 06-16 itself as "the obvious next drive" and carried in `deferred-items.md` with
   an exact reproduction condition. This is residue of a now-FIXED critical finding, not a live
   gap — the register today matches the file-path half of its own contract, which is what
   prevented the original CR-01 defect (a detector that saw nothing at all).
5. Four review findings are dispositioned `FIXED (undriven)` (IN-03, IN-06, IN-07, IN-11) — code
   changed and committed, but the runtime branch they live in was never observed firing during gap
   closure because reaching it needs a live-estate condition (a stopped container, an aborted
   mid-run oracle, etc.) that gap closure was scoped not to manufacture. Each is named with its
   exact driving condition in `deferred-items.md` (`DEF-06-21-02` through `-05`). None of these
   affects CONF-01 through CONF-06.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `stacks/selfhosted/arrs/beets/config.yaml` | Single vendored config, CONF-01/02/03/05 keys pinned | VERIFIED | Unchanged since prior pass; not touched by gap closure. |
| `scripts/check-beets-config.sh` (now 940 lines) | D-04-compliant, truncation-proven, header-honest | VERIFIED | All three invocations D-04 compliant; `--self-test` exit 0, 6/6 cases (was 5/5); live re-run recorded `FAILURES total: 0` with D-29 hashes identical (`artifacts/06-15-check-beets-config-rerun.txt`). |
| `scripts/quick-health-check.sh` | Two-arm CONF-01/02/05 read-back host + non-vacuous D-04 assertion | VERIFIED | D-04 block widened, guarded, exempt-pinned — confirmed directly in source (line numbers above). Also gained WR-10 (124-preserving), IN-13 (`D03_REPO_ROOT`), and the WR-03 CONF-04 fold-in arm (plan 06-17). |
| `scripts/phase06-oracle.sh` (2173+ lines) | CONF-03/06 destination-path oracle | VERIFIED (substantive), hardened | Plans 06-18/06-19 added command-injection fencing and fail-closed vacuity guards without altering the destination-path logic the committed zero-diff already proved. |
| `scripts/phase06-incremental-control.sh` | CONF-02 two-arm negative control | VERIFIED (substantive), hardened | Plan 06-20 aligned exit codes/precedence with its sibling; two-arm design unchanged. |
| `06-EXPECTED-TREE.txt` | Fixture committed before the run it judges | VERIFIED | Still at commit `cb9f49a`, unedited. |
| `06-REVIEW.md` | Code review findings, CR-01 fixed or explicitly accepted | **NOW WIRED** | Was "NOT WIRED" in the prior pass. Now carries an appended block at line 605 pointing to `06-DISPOSITIONS.md`, which resolves all 24 findings (19 FIXED, 4 FIXED (undriven), 0 ACCEPTED, 1 CARRIED — reconciliation 19+4+0+1=24=1+10+13, confirmed by direct read). |
| `06-DISPOSITIONS.md` (new) | Per-finding disposition register | VERIFIED | 24/24 findings accounted for, each with plan, commit and artifact citation; read in full. |
| `deferred-items.md` | Named carry-forward for undriven/deferred residue | VERIFIED | 8 entries (`DEF-06-10-01` through `DEF-06-21-08`), each with a named owner, urgency and exact driving condition; read in full. |
| `artifacts/06-15-*.txt` through `06-20-*.txt` (6 new) | Driven-red transcripts for the gap closure | VERIFIED | All 6 present on disk, non-trivial sizes (25KB–60KB), referenced correctly by their SUMMARYs. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `scripts/quick-health-check.sh` D-04 block | `check-beets-config.sh` / `phase06-oracle.sh` / `phase06-incremental-control.sh` beet invocations | widened `D04_INV_RE` regex + `D04_EXEMPT_RE` partition | **WIRED (was NOT_WIRED)** | Directly confirmed: pattern matches `$BEET_BIN`-style invocations; the three `check-beets-config.sh` lines land in the asserted set (compliant, green); the 5 oracle/incremental-control lines land in the named, counted, pinned exempt set. Executable count 0→8 hand-reproduced against the host's own `git grep`. |
| `06-EXPECTED-TREE.txt` | `beet move -p` output | `diff` via `manifest_compare`, 5 preconditions | WIRED (regression) | Unchanged; not touched by gap closure. |
| `06-12-country-preference.txt` | `check-beets-config.sh` CONF-05 read-back | shared `preferred.countries` key | WIRED (regression) | Unchanged. |
| `check-music-consumers.sh` CONF-04 rows | `quick-health-check.sh` exit code | new `exit 3` gate + fold-in `elif` arm | **WIRED (was PARTIAL)** | Confirmed directly: `check-music-consumers.sh` line 1674 `exit 3` sits below the CONF-04 pending block and above the green banner (source-order gate, not a text match), so the banner is structurally unreachable while any D-22 row is pending. `quick-health-check.sh` line 2252 `elif [ "$CONSUMERS_RC" -eq 3 ]` consumes it and sets `EXIT_CODE=1`. Driven in both directions per `06-17-SUMMARY.md` (rc=3 with banner provably absent; forced-green copy produces rc=0 with banner, proving the gate releases as well as blocks). `FAILURES` is never incremented by this path — pending stays distinct from measured failure, by design. |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| CONF-01 | 06-01, 06-07, 06-15 | Imports copy, never move | SATISFIED | Truth #1, #6 |
| CONF-02 | 06-01, 06-07, 06-08, 06-16, 06-20 | `incremental` + `incremental_skip_later` | SATISFIED | Truth #2, #6 |
| CONF-03 | 06-01, 06-05, 06-09, 06-11, 06-16, 06-18, 06-19 | Path formats produce the intended tree | SATISFIED | Truth #3, #6 |
| CONF-04 | 06-02, 06-03, 06-13, 06-17 | Multi-artist parsing in both consumers | **PARTIALLY SATISFIED, CORRECTLY RECORDED AS OPEN** | Truth #4 — unchanged from prior pass, now with a machine-readable `exit 3` signal |
| CONF-05 | 06-01, 06-07, 06-11, 06-12 | Match disambiguation demonstrated | SATISFIED | Truth #5 |
| CONF-06 | 06-02, 06-09, 06-11, 06-18, 06-19 | The dry-run's instrument proves the tree, wrote nothing | SATISFIED | Truth #3 (same evidence chain) |

No orphaned requirements: `REQUIREMENTS.md:349` phase-6 mapping still lists exactly CONF-01…06,
matching every plan's `requirements:` frontmatter field (checked across all 21 plans, including
the seven gap-closure plans, three of which — 06-15, 06-16, 06-18/06-19/06-20's cited
requirements — correctly cite the CONF-IDs they touch and none cite new ones).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No `TBD`/`FIXME`/`XXX` found in any of the five scripts this phase (and its gap closure) modified | — | Debt-marker gate does not fire |
| `scripts/quick-health-check.sh` | D-04 block region | `D04_EXEMPT_RE`'s per-line keying not driven for a non-compliant line planted *inside* an exempt file | Info (residue, `DEF-06-21-06`) | Named, owned, reproducible — not a live violation; the file-level exemption boundary (the original CR-01 attack surface) is proven |
| Various | — | Four findings `FIXED (undriven)` (IN-03, IN-06, IN-07, IN-11) | Info (residue, `DEF-06-21-02/03/04/05`) | Code changed and committed; branch not yet observed firing because it needs a live-estate condition gap closure was scoped not to manufacture |

The prior pass's Blocker finding (the D-04 vacuity, `scripts/quick-health-check.sh:1449-1594`) and
its paired Warning (the three unguarded `check-beets-config.sh` invocations) are both resolved —
confirmed by direct source read, not by re-stating the SUMMARY claim.

### Human Verification Required

None newly identified by this re-verification. One item carried forward from the prior pass
(beets-flask sign-in behind Authelia) was already answered by the operator in that prior cycle and
discharged on its load-bearing half; its residual sub-clause (web-terminal absence, confirmed by
config and log rather than by eye) was not re-opened because this re-verification's scope is CR-01
and gap-closure content, none of which touches beets-flask's auth path. See frontmatter
`human_verification_carried_forward`.

### Gaps Summary

None. The phase's central claim — CONF-01, CONF-02, CONF-03/06 and CONF-05 — remains strongly
proven and was regression-checked in this pass with no drift. CONF-04 remains correctly,
transparently OPEN on its Jellyfin half, now with a machine-readable signal (`exit 3`) that did not
exist at the prior verification. The sole prior gap, CR-01 (the D-04 vacuous assertion), is closed
on both halves: the live violation in `check-beets-config.sh` was fixed and proven by a throwaway
`-l` plus a measured-empty overlay; the detector in `quick-health-check.sh` was widened, given a
vacuity guard, and given a named/counted/pinned exemption register — all three driven live against
the deployed estate with before/after hashes. `06-REVIEW.md`, previously marked NOT WIRED, is now
wired to a 24-row disposition register that accounts for every finding with a plan, commit and
artifact citation, reconciling exactly (19 FIXED + 4 FIXED (undriven) + 0 ACCEPTED + 1 CARRIED =
24 = 1 critical + 10 warning + 13 info).

Two small residues remain, both correctly classified as informational rather than gaps: the D-04
exemption register's per-line keying inside an exempt file has not itself been driven red
(`DEF-06-21-06`, named by the gap-closure plan that introduced it as "the obvious next drive"), and
four hygiene fixes are committed but not yet observed firing because their branches need a
live-estate condition (a stopped container, a mid-run abort) that this gap closure was correctly
scoped not to manufacture. Neither affects any of the six CONF requirements' truth value.

---

_Verified: 2026-09-22T10:30:49Z_
_Verifier: Claude (gsd-verifier)_
