---
phase: 06-tagger-configuration-and-dry-run
plan: 43
subsystem: infra
tags: [conf-04, d-22, jellyfin, branch-verdict, recorded-negative, operator-gate, round-audit, def-06-39-06]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-42's measured after-state — the three `ROW|` verdicts all reading `verdict=AT-BASELINE`, the empty 1,244-row census delta, the byte-identical post-refresh `zfs diff`, the 91/944/88 sidecar manifest and the single `SAFETY: PASS` halt-gate line"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-42's independent corroboration on untouched code — `INSTRUMENT RUN: MEASURED` over `HOST CHECKOUT: MATCH ee82fb2`, with `JF_AT_TARGET: 0`, `JF_PENDING: 3`, `MA_AT_TARGET: 2`, `MA_REPORTED: 1` and `EXIT CODE: 3`"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-VERIFICATION.md § Recommended path — the two options the operator was offered, which branch B hands back"
provides:
  - "`BRANCH: B` — one machine-readable line, COMPUTED by a five-step rule from four recorded inputs and independently recomputed by the plan's own verify block, which fails the task on disagreement"
  - "THE MTIME HYPOTHESIS IS RECORDED DISPROVEN: all three pinned rows read AT-BASELINE after a refresh Jellyfin's own log confirms reached all three Audio items. 06-03's mechanism (b) is measured false for this estate at Jellyfin 10.11.11"
  - "artifacts/06-43-conf04-verdict.txt, 443 lines — SECTIONS L (the numbers), M (the branch), N (what it does and does not mean), O (the round-wide audit) and P (the operator's decision)"
  - "THE OPERATOR'S DECISION, recorded verbatim with a UTC timestamp: `negative-carry-e6` — record the negative and carry CONF-04's Jellyfin half to Phase 7 entry criterion E6 under an explicit override"
  - "A mechanical round-wide audit: 0 forbidden-mode tokens across all five round-5 artifacts, 0 forbidden UI-button phrases, 1 write verb for the entire round, 0 content changes, 3 mtime changes, both snapshots PRESENT and still held"
  - "The non-summing rule and the E6 second-measurement carve-out written into the record, so 06-44 and 06-45 read them rather than re-deriving them"
affects: [06-44, 06-45, phase-07-entry-criterion-E6]

tech-stack:
  added: []
  patterns:
    - "Make the verdict a COMPUTATION WITH A CHECK, not a judgement: define the branch by an explicit ordered rule over named inputs, then have the verify block re-evaluate the same rule from the same lines and fail the task on disagreement — so the agent that writes the conclusion cannot be the thing the conclusion rests on"
    - "Splice a prior artifact's delimited block in MECHANICALLY (`sed` extract, `awk` placeholder substitution) rather than retyping it, and `diff` the two blocks in the verify — a transcription slip between the measurement and the verdict then cannot survive"
    - "Name, in the rule itself, the inputs a reader will reach for and that the rule deliberately DOES NOT use — here the exit code (which is 3 on both branches and so cannot distinguish them) and the two MA counters — because an unstated exclusion is re-included by the next reader"
    - "Write a counted token in BRACKETED form EVERYWHERE it appears, including inside the paragraph that forbids it, not only inside the recipe that counts it. A prohibition written plainly is an occurrence of the thing it prohibits"
    - "Screen a committed artifact against its OWN published detectors before committing, not only against credentials — the count a document publishes about itself is the count most likely to be wrong"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-43-conf04-verdict.txt"
  modified:
    - ".planning/STATE.md"
    - ".planning/ROADMAP.md"

key-decisions:
  - "THE BRANCH IS `B`, AND IT WAS COMPUTED RATHER THAN CHOSEN. Rules 1 and 2 did not fire (`SAFETY: PASS`, `INSTRUMENT RUN: MEASURED`); rule 3 failed on all three conjuncts (AT-TARGET count 0, `JF_AT_TARGET` 0, `JF_PENDING` 3); rule 4 fired on all three. The verify block recomputed the same value from the same four inputs and matched. The orchestrator's own reading of the branch was re-derived from the artifacts rather than accepted."
  - "THE OPERATOR SELECTED `negative-carry-e6` — option (a) of `06-VERIFICATION.md` § Recommended path: record the negative and carry CONF-04's Jellyfin half to Phase 7 entry criterion E6 under an explicit override, so the roadmap's existing argument becomes auditable rather than implicit. The branch-A acceptance option was neither offered nor selected on a `BRANCH: B`, so no refusal is recorded, because none occurred."
  - "THE EXIT CODE AND BOTH MA COUNTERS ARE RECORDED AND ARE EXPLICITLY NOT INPUTS. `check-music-consumers.sh` exits 3 on branch A and branch B alike because `MA_ARTIST_PENDING` stays 1 either way; an exit code that cannot distinguish A from B cannot decide between them, and wiring it in would be the first step toward summing the two halves. A surviving `MA_REPORTED: 1` does not disqualify branch A."
  - "SECTION N states the non-summing rule verbatim and carries the branch-A counterfactual (the script would STILL exit 3, and that must not be tuned out) even though branch A did not fire — because the same rule is re-evaluated at Phase 7's first write and the carve-out must survive until then."
  - "E6's SECOND measurement — whether a second ≥4-artist track yields four artists in Music Assistant or three, the only thing separating 'MA caps at 3' from '`Twista` specifically failed to map' — is stated on every branch as NOT closed by this round. Round 5 never had it in scope and produced no evidence bearing on it."
  - "Neither snapshot was released and no rollback was executed. `tank/media/Music@pre-06-41-conf04-reprobe` is recorded as PRESENT and STILL HELD — its release is a separate operator decision, deliberately not bundled into this gate — and `tank/downloads@pre-phase5` (D-32, Phase 7 entry criterion E4) is untouched."
  - "No requirement record moved. CONF-04 stays unticked at `REQUIREMENTS.md:152` on branch B; an override is a recorded, argued carry of an OPEN requirement and must never be written as a close. `06-VERIFICATION.md` was not touched and remains stale; re-scoring it is `/gsd-verify 06`'s call, which 06-45 recommends rather than performs."

patterns-established:
  - "A three-branch verdict artifact where all three outcomes are legitimate, the branch is a single `BRANCH: (A|B|PARTIAL)` line, and downstream plans READ that line rather than re-deriving the conclusion from the measurements"
  - "A corroboration gate on the affirmative branch only: `BRANCH: A` is unreachable without `INSTRUMENT RUN: MEASURED`, so an uncorroborated close cannot be written, while a negative branch needs no second instrument to be honest"

requirements-completed: []

duration: 25min
completed: 2026-09-24
---

# Phase 06 Plan 43: The CONF-04 Verdict Summary

**`BRANCH: B` — the mtime hypothesis is measured disproven, computed by an ordered five-step rule from four recorded inputs and re-derived by the plan's own verify block; the operator chose `negative-carry-e6`, carrying CONF-04's Jellyfin half to Phase 7 entry criterion E6 under an explicit override, and no requirement record has moved.**

## Performance

- **Duration:** ~25 min across the gate
- **Tasks:** 2 of 2 (1 auto, 1 `checkpoint:decision` with `gate="blocking"`)
- **Files created:** 1 artifact (443 lines)
- **Estate contact:** none. No API call, no ssh command, no write of any kind. Every number was re-read out of artifacts already committed.

## Accomplishments

- **Computed the branch instead of claiming it.** The rule is stated in SECTION M, evaluated step by step against the measured values, and the `<automated>` verify block independently re-evaluates the same rule from the same lines and fails the task on disagreement. Written `B`, recomputed `B`.
- **Copied the measurement forward mechanically.** SECTION L's `--- ROW VERDICTS BEGIN/END ---` block was extracted from 06-42 with `sed` and spliced in by `awk` over a placeholder, never retyped — then `diff`ed against 06-42's in the verify. The U+2019 in the ARTPOP path survives byte-for-byte.
- **Kept the two verdicts apart at the one step where it would be easiest to break.** SECTION M names both things the rule deliberately does not use — the exit code (3 on both branches) and the two MA counters — and SECTION N carries `check-music-consumers.sh`'s own point (c) verbatim: the Jellyfin and MA verdicts are separate and are never summed.
- **Named the survivor.** SECTION N states on every branch that Phase 7 entry criterion E6's *second* measurement is not closed by this round, and additionally names E5 — row 1 of `ARTIST_PROOF_ROWS` is one of the 30 items carrying a populated `Artists` list with zero linked entities, which is why a per-file refresh performing no artist-entity creation was always the weakest lever on that row.
- **Audited the whole round mechanically.** 0 forbidden-mode tokens, 0 forbidden UI-button phrases, 1 write verb, 0 content changes, 3 mtime changes, both snapshots present — each count with the instrument that produced it recorded beside it.
- **Took the operator's decision before any record moved**, and re-proved that precondition with `git status --porcelain` at the moment the gate resolved.

## Task Commits

1. **Task 1: compute the branch and audit the round** — `88857e3` (docs)
2. **Task 2: record the operator decision (SECTION P)** — `7775a3d` (docs)

## Files Created/Modified

- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-43-conf04-verdict.txt` (443 lines) — SECTION L the numbers and the four recorded inputs, SECTION M the rule and the one `BRANCH:` line, SECTION N what the branch does and does not mean, SECTION O the delimited round audit, SECTION P the operator's decision.
- `.planning/STATE.md`, `.planning/ROADMAP.md` — execution record only. Neither carries a CONF-04 verdict and neither moves a checkbox.

## The Branch, and How It Was Reached

| Input | Source | Value | Used by the rule? |
|---|---|---|---|
| `verdict=` ×3 | 06-42 SECTION C, spliced block | all three `AT-BASELINE` | **yes** |
| `SAFETY:` | 06-42 SECTION K | `PASS` | **yes** |
| `INSTRUMENT RUN:` | 06-42 instrument re-run | `MEASURED` | **yes** |
| `JF_AT_TARGET:` | 06-42 instrument re-run | `0` | **yes** |
| `JF_PENDING:` | 06-42 instrument re-run | `3` | **yes** |
| `HOST CHECKOUT:` | 06-42 instrument re-run | `MATCH ee82fb2…` | records how `MEASURED` was earned |
| `EXIT CODE:` | 06-42 instrument re-run | `3` | **no — 3 on A and B alike** |
| `MA_AT_TARGET:` / `MA_REPORTED:` | 06-42 instrument re-run | `2` / `1` | **no — never summed with the JF half** |

Rule 1 no (`PASS`) → rule 2 no (`MEASURED`) → rule 3 no (AT-TARGET count 0, not 3; `JF_AT_TARGET` 0, not 3; `JF_PENDING` 3, not 0) → **rule 4 fires** → `BRANCH: B`.

## The Operator's Decision

Recorded in SECTION P at **2026-09-24T14:30:37Z (UTC)**. The selection, verbatim:

```
negative-carry-e6
```

In full, as the option was put: *"Branch B / PARTIAL — record the negative, carry the Jellyfin half to Phase 7 E6 under an explicit override."* This is option (a) of `06-VERIFICATION.md` § Recommended path.

**What it authorises:** 06-44 and 06-45 to write the record that matches the measured branch — the recorded negative, the Jellyfin half carried to E6, and the override written down so the roadmap's existing argument becomes auditable rather than implicit.

**What it does not authorise**, each named because a reader could otherwise infer it: ticking CONF-04 (the box stays unticked — an override is a carry of an OPEN requirement, not a close); re-scoring `06-VERIFICATION.md` to 6/6 (that is `/gsd-verify 06`'s call, and 06-45 recommends rather than performs it); any further or wider refresh; releasing either snapshot; or closing E6.

The branch-A acceptance option was neither offered nor selected on a `BRANCH: B`. Had it been, it would have been refused and the refusal recorded in SECTION P. No refusal is recorded because none occurred.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The artifact matched the detector it publishes — the forbidden UI-button phrase was written plainly twice**

- **Found during:** Task 2, in the pre-commit screen — *after* the edit landed, not by an assertion written beforehand.
- **Issue:** SECTION O declares that the forbidden UI button's phrase is written in bracketed form so the recipe is not itself an occurrence of what it measures, and publishes a count of `0`. But the artifact carried the phrase **plainly** in two places: the hard-fence paragraph at the top (written in Task 1) and SECTION P's does-not-authorise list (written in Task 2). `/usr/bin/grep -ciE` over the file returned **2** against a published **0**. The count over the four *source* artifacts was never wrong — what was wrong is that this file was itself an occurrence of its own detector, which is the exact `DEF-06-39-06` class, now in its sixth consecutive round.
- **Fix:** Both occurrences rewritten to the bracketed `[m]etadata` form; a new `in this artifact : 0 (expected 0)` row added inside the `--- ROUND AUDIT ---` block so the number is asserted rather than assumed; the top paragraph amended to say *why* it brackets the phrase even while forbidding it; and the miss recorded in band in SECTION O rather than silently corrected. Re-measured after the fix: 0 in this artifact, 0 across the four source artifacts.
- **Files modified:** `artifacts/06-43-conf04-verdict.txt`
- **Commit:** `7775a3d`

**2. [Rule 3 - Blocking] The branch-A option id could not be written plainly in SECTION P**

- **Found during:** Task 2, reading this plan's own Task 2 verify block before writing.
- **Issue:** The verify treats a literal occurrence of the branch-A option id *anywhere in the file* as a recorded selection of it and then requires `BRANCH: A`. The orchestrator asked for an in-band note that the option was unavailable on this branch — which, written plainly, would have asserted it was chosen and failed the gate over a true statement.
- **Fix:** The id is written in bracketed form in SECTION P, consistent with the mitigation already established in SECTION O, with the reason stated in band rather than left to be rediscovered. The substantive statement — the option was not offered, was not selected, and would have been refused — is made in full.
- **Files modified:** `artifacts/06-43-conf04-verdict.txt`
- **Commit:** `7775a3d`

### Deliberate Non-Deviations

- **The orchestrator's stated branch was re-derived, not accepted.** Its dispatch said "recompute this yourself; do not copy this line as the answer," and the rule was evaluated independently against the artifacts. It agreed.
- **Nothing was escalated on a negative branch.** No second refresh, no wider refresh mode, no aggressive per-item mode, no additional file touched, no `zfs rollback`. The hard fence is untouched by branch B and is unreachable from it.
- **Neither snapshot released.** `tank/media/Music@pre-06-41-conf04-reprobe` is recorded PRESENT and still held; its release is a separate operator decision and was deliberately not bundled into this gate.
- **`06-VERIFICATION.md` was not touched** and remains stale, as does every requirement record. This plan edited one repository file plus the two execution-record files.
- **`/usr/bin/grep` was used for every workstation-side screen** — the bare name is shadowed by a shell function in this session and has silently matched nothing before (06-41).

## Authentication Gates

None. This plan issued no authenticated call and read no secret.

## Known Stubs

None. This plan produced no code — one verdict artifact.

## Threat Flags

None. No network endpoint, auth path, file-access pattern or schema change. Zero HTTP requests of any verb. Credential-screened before both commits (public repository): the file was confirmed UTF-8 with a measured NUL delta of 0 bytes (by `raw − tr -d '\000'`, not the vacuous `grep -c $'\000'` shape 06-41 flagged), and the only long opaque string in it is the commit id `ee82fb20…` already committed to this repository.

## Self-Check: PASSED

Re-asserted against disk and git *after* this summary was written.

- `artifacts/06-43-conf04-verdict.txt` — FOUND, 443 lines.
- Commits `88857e3` and `7775a3d` — both FOUND in `git log`.
- Exactly one `^BRANCH: (A|B|PARTIAL)$` line, reading `B`; recomputed from the four inputs by the verify block and matching.
- Exactly three `^ROW|` lines, all `verdict=AT-BASELINE`; block `diff`-identical to 06-42's.
- `SECTION L`, `SECTION M`, `SECTION N`, `SECTION O`, `SECTION P — OPERATOR DECISION` — all present.
- Exactly one `--- ROUND AUDIT BEGIN/END ---` pair.
- Forbidden-mode token: 0 in this artifact and 0 in every `artifacts/06-4*.txt`. Forbidden UI phrase: 0 in this artifact and 0 across the four source artifacts.
- Both task verify blocks re-run at final state: `TASK 1 VERIFY: OK`, `TASK 2 VERIFY: OK`.
- `REQUIREMENTS.md:152` still reads `- [ ] **CONF-04**`; `stacks/selfhosted/arrs/beets.md` and `06-VERIFICATION.md` untouched.

## What This Hands 06-44 and 06-45

- One line to read rather than a conclusion to re-derive: **`BRANCH: B`**.
- The operator's authorisation for the *carry*, not for a close: `negative-carry-e6`.
- The non-summing rule and the E6 second-measurement carve-out, both written down, so neither has to be reconstructed from the instrument's source.
- An unticked CONF-04, an untouched `06-VERIFICATION.md`, and a `In Progress` Phase 6 status row — all three still exactly where 06-42 left them.
- `tank/media/Music@pre-06-41-conf04-reprobe`, still standing.
