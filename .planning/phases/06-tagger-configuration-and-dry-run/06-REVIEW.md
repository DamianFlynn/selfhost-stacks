---
phase: 06-tagger-configuration-and-dry-run
reviewed: 2026-09-24T15:08:05Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - scripts/check-beets-config.sh
  - scripts/check-music-consumers.sh
  - scripts/check-music-freeze.sh
  - scripts/phase06-incremental-control.sh
  - scripts/phase06-oracle.sh
  - scripts/quick-health-check.sh
  - stacks/selfhosted/arrs/beets.md
  - stacks/selfhosted/arrs/beets/beets.yaml
  - stacks/selfhosted/arrs/beets/config.yaml
  - stacks/selfhosted/arrs/beets/flask-config.yaml
  - stacks/selfhosted/arrs/beets/flask.yaml
  - stacks/selfhosted/arrs/compose.yaml
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 06: Code Review Report

**Reviewed:** 2026-09-24T15:08:05Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

This phase's changed files are almost entirely bash health-check/verification instruments
(`scripts/check-beets-config.sh`, `scripts/check-music-consumers.sh`,
`scripts/check-music-freeze.sh`, `scripts/phase06-incremental-control.sh`,
`scripts/phase06-oracle.sh`, `scripts/quick-health-check.sh`) plus the beets/beets-flask
configuration and compose definitions they assert against. The code is unusually — almost
uniquely — hardened: every file documents, and defends against, the exact defect classes named in
this review's brief (fail-closed vs. fail-open, `timeout | wc -l` laundering a kill through
`pipefail`, `grep -F` over bracketed literals, NUL-byte test vacuity, quoting through `ssh`/`docker
exec` boundaries, credential handling via `-H @<(...)` instead of argv). Each file's own header
documents 3-6 rounds of prior adversarial review (labelled R1-R5, GC-01…GC-16, IN-01…IN-10,
WR-01…WR-13, CR-01…CR-03) with the specific defect, the measurement that found it, and the fix.

I traced the control flow in each file rather than trusting the comments: the readiness gates, the
two-arm config comparison in `check-beets-config.sh`, the D-22 artist-entity pending/target/baseline
three-state logic in `check-music-consumers.sh`, the destructive-command fences in
`phase06-oracle.sh` and `phase06-incremental-control.sh`, and the `bounded_ssh`/pipefail-repair
blocks in `quick-health-check.sh`. `shellcheck -S warning` is clean on five of the six scripts.
Cross-checked the beets/beets-flask YAML configs and `compose.yaml` against the census patterns and
documentation claims in `beets.md`, `check-music-freeze.sh` and `check-beets-config.sh` — no
committed credentials, no drift between the two active tagger definitions and the census that
asserts them, no non-detecting `grep -F` over a bracketed pattern, no vacuous NUL-byte test, no
unbounded remote pipeline.

No Critical-severity (security/data-loss/crash) defects were found in this pass. The findings below
are code-quality/maintainability items — the most material of which is the codebase's own
extraordinary self-referential density, which is a real cost even though the logic it documents is
sound.

## Warnings

### WR-01: Unused loop variables in the tagger-capable inventory (`check-music-freeze.sh`)

**File:** `scripts/check-music-freeze.sh:1044`
**Issue:** `while IFS='|' read -r xn xs xsrc xdst xflag; do` binds `xs` and `xdst` but neither is
referenced anywhere in the loop body (only `xn`, `xsrc` and `xflag` are used). Confirmed by
`shellcheck -S warning`, which flags both (SC2034) — this is the only shellcheck finding across all
six scripts in scope. Not a functional bug (the fields are still consumed by the read, so parsing
is correct), but an unused binding in a five-field destructuring read is exactly the kind of drift
that hides a real field-count mismatch the next time this row shape changes — there is no signal
today that would catch `xdst` silently starting to hold the wrong column if a field were
inserted/removed upstream.
**Fix:**
```bash
while IFS='|' read -r xn _xs xsrc _xdst xflag; do
```
(or `read -r xn _ xsrc _ xflag` if the positions are never going to be referenced by name again).

### WR-02: Maintainability cost of the extreme comment-to-code ratio

**File:** all six scripts in scope, most acutely `scripts/quick-health-check.sh` (3,148 lines),
`scripts/phase06-oracle.sh` (3,274 lines), and `scripts/check-beets-config.sh` (1,223 lines, of
which the first 123 are header comment before `set -euo pipefail`)
**Issue:** Every file in scope carries a dense internal audit trail — dozens of named defect IDs
(R1-R5, GC-01…GC-16, IN-01…IN-10, WR-01…WR-13, CR-01…CR-03, D-01…D-56, T-06-xx) cross-referencing
each other, prior review rounds, and specific artifact files under `.planning/`. This is a genuine
asset for provenance (every fail-closed branch has a stated reason and a driven test), but it also
means:
  - `quick-health-check.sh` carries at least thirteen numbered "EXIT-CODE BEHAVIOUR CHANGED" notices
    in its header alone before the first executable line is reached.
  - Locating the actual assertion logic inside `phase06-oracle.sh` or `quick-health-check.sh`
    requires scrolling past thousands of lines of historical narrative that a future maintainer
    (human or agent) who was not present for the original rounds has no efficient way to skip —
    there is no separation between "why this exists" (durable) and "what changed in round N"
    (historical), so the two are interleaved at the same visual weight throughout.
  - Several load-bearing invariants are stated only in prose and cross-referenced by grep recipe
    (e.g. `check-beets-config.sh`'s own instruction to run `grep -c 'assert_beet_invocation_contract'`
    to verify a call count, or the `D04_INV_RE`/`D04_EXEMPT_RE` "extracted, not retyped" warning in
    `beets.md`). This pattern is self-aware of its own fragility (the files repeatedly document a
    prior round's number drifting when the file itself was edited), which is itself the signal
    that documentation-as-source-of-truth for a count is the wrong mechanism.
**Fix:** Not a defect to patch line-by-line, but worth a deliberate decision before Phase 7 adds
more: move the historical "notice N" / round-by-round narrative out of the script bodies and into
`.planning/phases/06-tagger-configuration-and-dry-run/` (which already holds the per-plan
artifacts), leaving only the current, durable rationale in the script itself. The scripts already
reference `.planning/...artifacts/*.txt` extensively for evidence — the same convention could carry
the "why this branch exists" history without keeping every superseded paragraph in the executable
file.

### WR-03: Magic-number synchronisation points with no automated cross-check

**File:** `scripts/check-music-freeze.sh:508` (`DECLARED_INTERP_EXPECTED="${DECLARED_INTERP_EXPECTED:-12}"`),
`scripts/check-music-freeze.sh:153` (`TAGGER_DEF_EXPECTED=2`), `scripts/check-beets-config.sh:740`
(`ST_PLANNED_CASES=7`)
**Issue:** Several counts that gate pass/fail are pinned constants that must be hand-moved in the
same commit as an unrelated change elsewhere in the tree (a new interpolated-host-path volume line
in any stack YAML, a new tagger definition, a new self-test case). The scripts do fail loud rather
than silently when the pinned count and the measured count disagree (confirmed by reading the
branches at each site — a mismatch is a `fail`, not a `pass`), so this is not a fail-open risk.
It is, however, a standing maintenance trap: any contributor adding an unrelated
`${VAR}/path:/dest` volume line to any file under `stacks/selfhosted/` will turn
`check-music-freeze.sh` red for a reason that has nothing to do with their change, and the fix
(reading the new line by hand and moving `DECLARED_INTERP_EXPECTED`) is not discoverable from the
failure message alone without already knowing this convention exists.
**Fix:** Low priority given the documented rationale (an override that could suppress the check is
worse than a pinned count that must be moved by hand), but consider: (a) printing the exact
`DECLARED_INTERP_EXPECTED=<N>` edit needed directly in the failure output (today it prints the new
lines but not the literal sed/one-line fix), or (b) a short `docs/CONVENTIONS.md` entry (the repo's
own `CONVENTIONS.md` is currently empty, per `CLAUDE.md`) naming this pattern once so it does not
have to be rediscovered from source every time it fires.

## Info

### IN-01: `CONVENTIONS.md` and `ARCHITECTURE.md` are stated as empty in `CLAUDE.md` while the scripts assume detailed unwritten conventions

**File:** `CLAUDE.md` (`## Conventions` / `## Architecture` sections), cross-referenced against the
pinned-count and fence-duplication conventions used throughout the reviewed scripts
**Issue:** `CLAUDE.md` says "Conventions not yet established" and "Architecture not yet mapped," yet
the scripts in this phase collectively establish several real, load-bearing conventions (the
`${VAR:-default}` env-override contract that must only ever make a check redder; the two-layer
destructive-command fence duplicated on purpose at each call site; the `EXIT_CODE`/pending/UNKNOWN
three-state exit convention; the `📊 N. Summary` heading as a cross-file grep anchor). None of this
is captured in `CONVENTIONS.md` itself — it lives only inside the scripts' own headers. This is not
a bug, but it means the project's actual conventions file is out of date relative to the practice
already established in the code under review.
**Fix:** Optional — backfill `CONVENTIONS.md` with a short index of the patterns named above (fail
closed / bound remote commands Linux-side / assert-not-report / additive-only overrides / the
two-layer fence rule), each pointing at its canonical example, the next time this area is touched.

### IN-02: `stacks/selfhosted/arrs/beets.md` is a single 2,470-line running log rather than a navigable reference

**File:** `stacks/selfhosted/arrs/beets.md`
**Issue:** The file mixes phase-by-phase historical narrative (Phase 1 through Phase 6, each with
its own "closed" verdict block, corrections, and superseded claims kept "as retractions") with the
information a future reader actually needs at a glance (current config state, current criteria
verdicts). Finding the authoritative current state (e.g. the Phase 6 closure table at line ~2067)
requires knowing to jump to the end of the file; nothing at the top of the document points there.
**Fix:** Optional — add a one-line pointer near the top ("current state: see § Phase N closed,
line X") each time a new phase closure section is appended, so a reader does not have to scroll
past five phases of history to find the live picture.

---

_Reviewed: 2026-09-24T15:08:05Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---

## Wiring — where round 6's fixes are recorded

**Appended 2026-09-24 by plan 06-50 (wave 3). Nothing above this line was edited.**

**Round 6's fixes and refusals are dispositioned, finding by finding, in
`.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP4.md`.** That register is
the record a future reader should follow: it names, for each finding, the plan, the commit, the
evidence, what was driven and what was not, and — where nothing was changed — the reason and the
revisit condition.

### ⚠ Read the mapping table before following any citation

**This review's `WR-*` / `IN-*` IDs alias round 1's namespace, which is already cited in band across
all six scripts in scope.** Measured at plan 06-50's base commit `3085da1`, the five IDs this review
reuses account for **39** pre-existing in-band citations across those six files (`WR-01` 16,
`WR-02` 4, `WR-03` 15, `IN-01` 2, `IN-02` 2), and the whole `WR-*` / `IN-*` namespace accounts for
**94** — none of which has anything to do with round 6. A grep for `WR-02` in `phase06-oracle.sh`
finds round 1's empty-manifest finding, not this review's comment-ratio finding.

**So round 6's in-band and register IDs are `R6-01` … `R6-05`** for the five findings here, plus
**`R6-06` … `R6-09`** for the round's four non-review items (the corrected detector, the bracketing
scope decision, the host sync and the snapshot go/no-go). The mapping table sits in
`06-DISPOSITIONS-GAP4.md` **immediately after its Source table**, before any citation is used in
prose. The namespace was chosen **up front**, in the fix plans themselves, rather than aliased
afterwards — the rule `DEF-06-39-01` established after round 4 paid that cost four times over.

| This review | In band / register | Closed by |
|---|---|---|
| `WR-01` | `R6-01` | plan 06-46 |
| `WR-02` | `R6-02` | plan 06-49 (ACCEPTED, with a forward rule) |
| `WR-03` | `R6-03` | plans 06-46 + 06-49 |
| `IN-01` | `R6-04` | plan 06-49 |
| `IN-02` | `R6-05` | plan 06-47 |

### This round's totals

**4 FIXED, 0 FIXED (undriven), 1 ACCEPTED, 0 CARRIED — 5 total**, reconciling three ways: this
review's frontmatter `0 + 3 + 2 = 5`; the dispositions `4 + 0 + 1 + 0 = 5`; the fix kinds
**1 CODE + 3 CLAIM CORRECTION + 1 BOTH** `= 5`.

**This is a record, not a re-close.** Plan 06-50 ran no `/gsd-verify` and claims no verification
result. `REQUIREMENTS.md` is untouched, `- [ ] **CONF-04**` stands, entry criterion **E6** still owns
the Jellyfin half, and `ROADMAP.md`'s Phase 6 status row still reads `In Progress`.

_Dispositioned: 2026-09-24 by plan 06-50_
