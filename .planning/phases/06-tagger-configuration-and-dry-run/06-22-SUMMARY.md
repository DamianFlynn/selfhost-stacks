---
phase: 06-tagger-configuration-and-dry-run
plan: 22
subsystem: verification-harness
tags: [gap-closure, gc-01, gc-13, pipefail, sigpipe, self-test, inventory, false-green]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-REVIEW-GAP.md GC-01 (BLOCKER) and GC-13 (INFO), and scripts/check-beets-config.sh as shipped by plans 06-15..06-20"
provides:
  - "scripts/check-beets-config.sh: both forbidden-substring tests read grep's own status via a here-string — no pipeline, so no SIGPIPE, so no pipefail-141 false green"
  - "self-test case 7: a 71,013-byte synthetic dump carrying the forbidden substring at the TOP, with its size ASSERTED in band — the first case in this file whose input is estate-sized"
  - "self-test case 6 gates on two independent counters (ARM1_REAL_VIOLATIONS == 0 AND ARM1_SYNTH_REJECTED == 1), so a real violation and a blind checker can no longer cancel into a pass"
  - "self-test banners DERIVED from what actually ran, with announced-vs-ran disagreement itself a failure"
  - "artifacts/06-22-pipefail-141.txt: the 8-128 KiB sweep, the position-dependence control, the pre-fix MISS / post-fix CATCH drive, the four-mutant GC-13 cancellation drive, and the repo-wide inventory with size classes and failure directions"
affects: [plan-06-24, plan-06-29, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A here-string, not `set +o pipefail`, is the fix for `printf | grep -q` under pipefail: turning an option off around one test weakens every other statement in that scope"
    - "A regression case must cross the threshold the defect lives at. Every other case in this file is a few hundred bytes, which is why --self-test structurally could not see a 64 KiB defect"
    - "Anchor the forbidden substring at the TOP of the fixture: the SIGPIPE defect is position-dependent and a bottom-anchored case ticks green against the broken code"
    - "Assert the fixture's size in band. A case that quietly shrinks below the threshold is a case that has stopped testing anything — an under-size result must FAIL, never silently skip"
    - "Prove a regression case DISCRIMINATES by running it against the pre-fix code, not only against the fix"
    - "Never funnel two distinct outcomes into one counter compared against one expected total — two faults sum to the expected value and cancel into a pass"
    - "A gate's failure message must name WHICH half is wrong: '1 red, expected 1' is exactly what made GC-13 invisible"
    - "UNKNOWN sentinels for integer gates: -1 at script level, so a gate reached without its producer having run FAILS rather than passing on a zero"
    - "Filtering comment lines is necessary and NOT sufficient when inventorying `set -o pipefail`: it survives inside REMOTE command strings on executable lines. Anchor to `^[[:space:]]*set `"
    - "Failure DIRECTION is the property that matters, not the presence of the shape: a positive assertion fails toward a false RED (noisy, safe); an inverted one fails toward a false GREEN"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-22-pipefail-141.txt
  modified:
    - scripts/check-beets-config.sh

key-decisions:
  - "LC_ALL=C was deliberately NOT added alongside the here-string. Multibyte behaviour is unchanged by this fix and changing two things at once would have destroyed the measurement"
  - "run_case's identical-looking `ARM1_FAILS -eq $expect_reds` comparison is LEFT ALONE. Every red it counts comes from the same pure function over one synthetic dump, so there the sum IS the whole outcome. Only case 6 funnelled two different kinds of outcome"
  - "ARM1_FAILS keeps exactly the value it always had, because the live arm-1 summary line is a second consumer of it and this plan must not change the live transcript"
  - "The pipefail/grep -q remainder (23 lines / 24 pipelines) is INVENTORIED, not swept. Three of the affected scripts are folded into quick-health-check.sh, and unreviewed edits to the estate's health path inside a gap-closure round is the wrong trade"
  - "quick-health-check.sh's six sites are OUT of scope on measurement, not on assumption: it carries no local `set` line at all. Recorded because that correctness is a property of an absent line, not of a control"

metrics:
  duration-minutes: 48
  completed: 2026-09-22
  tasks: 3
  commits: 3
  files-changed: 2
---

# Phase 6 Plan 22: GC-01 / GC-13 Gap Closure Summary

A forbidden substring present anywhere in the arm-1 config dump is now reported at every input
size, including above the 64 KiB pipe buffer where the shipped `printf | grep -q` silently
reported it as absent — and the self-test carries the case that would have caught it, proven
discriminating against the pre-fix code.

## What Was Built

### Task 1 — GC-01, the pipefail-141 false green (commit `b153c3b`)

Both forbidden-substring tests in `scripts/check-beets-config.sh` used
`printf '%s' "$raw" | grep -qF -- "$forb"` under `set -euo pipefail`. `grep -q` exits on first
match, `printf` takes SIGPIPE and exits 141, `pipefail` hands 141 to the pipeline, and the `if`
evaluates **false** — so a substring that *is* present is reported **absent**. A false GREEN over
a live condition.

Reproduced before touching anything, on BSD grep 2.6.0-FreeBSD / bash 5.3.15 / macOS 27.0:

| input | pre-fix pipeline rc | post-fix here-string rc |
|---|---|---|
| 8 / 16 / 32 / 48 / 56 KiB | 0 — FOUND | 0 — FOUND |
| **64 / 72 / 96 / 128 KiB** | **141 — MISSED** | **0 — FOUND** |

And position-dependent, same 128 KiB input: match at TOP → 141 (missed); match at BOTTOM → 0
(found). That control is why case 7 anchors at the top.

Both sites now use `grep -qF -- "$forb" <<<"$raw"`. `-F` and the `--` end-of-options guard are
kept. The reasoning — the old shape, the measured ceiling, the direction of the failure, and why
a here-string rather than `set +o pipefail` — is recorded in band at the first site only, with a
one-line cross-reference at the second.

**Self-test case 7** feeds `synthetic_correct_dump` prefixed by one top-level key whose
double-quoted scalar opens with `Compilations` and is padded to **71,013 bytes**. The size is
measured with `wc -c` and an under-65536 result is a self-test FAILURE, not a silent skip. The
pad is `x` — cannot terminate a YAML double-quoted scalar, does not contain `/music/imported` —
so `dump_to_json` returns the same keys as the unpadded dump and the expected red count is
exactly 1: the forbidden-substring red and nothing else.

Case counts are now **derived** from what ran. `ST_PLANNED_CASES=7` is announced up front and
compared against `st_cases` at the end; a disagreement between the banner and the body is itself
a self-test failure. No hard-coded 6 survives anywhere in the file.

### Task 2 — GC-13, two faults cancelling into a pass (commit `ad5a854`)

`assert_beet_invocation_contract` reports three outcomes through one counter: a real source
violation increments `ARM1_FAILS`, a correctly-rejected synthetic also increments it, and a
**not**-rejected synthetic — the checker being blind — increments nothing. Case 6 compared that
sum against `1`, so "one real violation" + "a blind checker" summed to exactly 1 and the case
reported `✅ … 1 red, as expected`.

The function now also sets `ARM1_REAL_VIOLATIONS` and `ARM1_SYNTH_REJECTED`, re-initialised per
call, carrying `-1` UNKNOWN sentinels at script level so a gate reached without the function
having run fails rather than passing on a zero. Case 6 requires `real == 0 && synth_rejected == 1`
and, on failure, prints which half is wrong and its observed value.

### Task 3 — the inventory (commit `76d1575`)

25 of 29 scripts under `scripts/` set `pipefail` for their own shell. **28 lines / 29 pipelines**
carried the `… | grep -q` shape; 5 are closed by this round (2 here, 3 in `phase06-oracle.sh` by
plan 06-24); the remainder is **23 lines / 24 pipelines**, each recorded with file, line,
provenance, size class and failure direction.

Five of the remainder are **inverted** — they fail toward a false green, or toward the
destructive answer:

| site | why it matters |
|---|---|
| `check-jellyfin-transcode.sh:490` | match → `fail`; a 141 reports `/data/transcode` gone when it is present |
| `check-jellyfin-transcode.sh:513` | match → `fail`; **the only remaining site whose input is unbounded** (`docker volume ls -q`, ~1,008 volumes to the ceiling) |
| `check-music-consumers.sh:939` | match → `export_fail`; a 141 reports `fsid=` absent when it is set |
| `spike03-image-headroom.sh:316/317` | match → PROTECT; a 141 drops a referenced image into the reap list |
| `spike03-image-headroom.sh:408` | match → `fail` |

Nothing outside `scripts/check-beets-config.sh` was edited:
`git diff --name-only bf509f4 HEAD -- scripts/` lists that file and nothing else.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug in the plan's own premise] The comment filter is necessary but not sufficient**
- **Found during:** Task 3
- **Issue:** 06-22-PLAN.md instructs "filter comment lines before matching — `quick-health-check.sh`
  mentions [pipefail] repeatedly and does **not** set it, which is why its own `| grep -q` sites
  are not in scope." Filtering comments alone still classifies `quick-health-check.sh` as a
  setter, because three of its mentions are on **executable** lines — inside REMOTE command
  strings (`ssh … "set -o pipefail; …"` at `:1105`, `:1132`, and `DRIFT_CMD` at `:1346`). Those
  set pipefail on the far side of an ssh and have no bearing on the local `| grep -q` sites in
  the same file. The first inventory run I did with only a comment filter produced a 26-script
  setter list that wrongly included it, and an empty "not in scope" section — which would have
  silently pulled six out-of-scope sites into the table.
- **Fix:** the grep is anchored to `^[[:space:]]*set [-a-z]+ pipefail`, admitting only a line
  whose first word is `set`. `quick-health-check.sh` is then correctly excluded, and the
  exclusion is proven rather than asserted: `grep -cE '^[[:space:]]*set ' scripts/quick-health-check.sh`
  returns **0** — it carries no local `set` line at all. The plan's conclusion was right; its
  stated method was not. Both are recorded in the artifact.
- **Files modified:** artifact only (the inventory is read-only by design)
- **Commit:** `76d1575`

**2. [Rule 2 — Missing correctness control] UNKNOWN sentinels for the two new integer counters**
- **Found during:** Task 2
- **Issue:** the plan says to initialise both counters at the top of the function. That covers
  re-entry, but a script-level default of `0` for `ARM1_REAL_VIOLATIONS` is the *passing* value —
  a gate reached without the producer having run would tick green on a counter nobody set. That
  is the same fail-open shape the S3(a) UNKNOWN sentinels at the top of this file exist to refuse.
- **Fix:** script-level `ARM1_REAL_VIOLATIONS=-1` and `ARM1_SYNTH_REJECTED=-1`. Neither value
  satisfies its own gate, so an unrun producer FAILS the case. Per-call re-initialisation to
  `0`/`0` is unchanged and still present.
- **Files modified:** `scripts/check-beets-config.sh`
- **Commit:** `ad5a854`

**3. [Rule 2 — Missing correctness control] The announced case count is asserted, not just typed**
- **Found during:** Task 1
- **Issue:** the plan asks for the four prose counts to be updated and for the numbers to be
  derived. Updating them by hand is exactly how they drifted the first time. The opening echo
  necessarily runs before any case does, so it cannot be derived.
- **Fix:** `ST_PLANNED_CASES=7` feeds the opening echo, `st_cases` counts what actually ran, and
  a mismatch between them returns 1 with its own message. The two closing banners are fully
  derived (`$st_cases`, `$st_red_cases`). Adding a case without updating the announcement now
  fails the self-test rather than producing a banner that lies.
- **Files modified:** `scripts/check-beets-config.sh`
- **Commit:** `b153c3b`

### Additional drives beyond the plan

The plan asks for the GC-13 combined mutant plus the two single mutants — three drives. A
**fourth** was added: the combined mutant with the **OLD summed gate restored**. Without it the
evidence shows only that the new gate fails; it does not show that the old one *passed*, which is
the actual claim GC-13 makes. That fourth run reproduces the defect directly:

```
M0-both-OLDgate   real violation present AND checker blind, old summed gate
  · D-04 contract: 1 beet invocation(s) … do NOT carry both -l and -c
  · D-04 contract: the synthetic -c-only invocation was NOT rejected — the checker is BLIND
  [OLD GATE] case '…': 1 red, as expected
  ✅ --self-test: all 7 cases behaved as expected (6 of them red)
  RC=0
```

The sweep was also run against both `grep` paths reachable from a bash script, and the operator's
interactive-shell `grep` (ugrep 7.8.4, via a zsh alias) is named in the artifact as a contaminant
that nearly got into the measurement. Inside a `bash` script — which is how this checker runs —
`command -v grep` is `/usr/bin/grep`, BSD grep 2.6.0-FreeBSD, the same one GC-01 was measured
against.

## Verification Performed

| Check | Result |
|---|---|
| `bash -n scripts/check-beets-config.sh` | parses clean |
| `bash scripts/check-beets-config.sh --self-test` | exit **0**, `all 7 cases behaved as expected (6 of them red)` |
| No pipeline in either forbidden-substring test (comments excluded) | 0 — was 2 |
| Both tests use `<<<"$raw"` (comments excluded) | 2 — was 0 |
| `ARM1_FAILS -eq $expect_reds` surviving (comments excluded) | 1 — `run_case`'s, was 2 |
| Live summary consumer `arm-1 assertion failures` | 1, unchanged |
| No prose count of six cases | 0 |
| Case 7 raw dump size | 71,013 bytes, asserted in band |
| Case 7 pre-fix | **0 red — the MISS**; self-test exits 1 |
| Case 7 post-fix | **1 red — the CATCH**; self-test exits 0 |
| GC-13 combined mutant, new gate | FAILS, naming both halves; RC=1 |
| GC-13 combined mutant, old gate | **PASSES, RC=0** — the defect reproduced |
| GC-13 single mutants (real-only, blind-only) | both FAIL, each naming its half; RC=1 |
| No estate contact | `--self-test` returns before the live path; `Toolchain preconditions` never printed. No ssh, no docker, no container, no `git push`/`git pull` |
| `git diff --name-only bf509f4 HEAD -- scripts/` | `scripts/check-beets-config.sh` only |

All four mutant copies and the pre-fix copy lived in the session scratch directory and were
deleted after their runs.

## NOT-DRIVEN Register

Changed but not observed firing:

| Change | Why it was not driven | Risk |
|---|---|---|
| `ARM1_REAL_VIOLATIONS=-1` / `ARM1_SYNTH_REJECTED=-1` script-level sentinels | Reaching case 6's gate without `assert_beet_invocation_contract` having run requires editing the case itself; no reachable input produces it. The -1 values are a guard against a future edit, not against a current path | Low. The gate is `-eq 0` / `-eq 1`, and -1 satisfies neither, so the branch taken on an unrun producer is provably the failing one by inspection of two integer comparisons |
| The `st_cases != ST_PLANNED_CASES` banner-vs-body gate | Firing it means announcing a count that differs from the number of `run_case` calls — a source edit, not an input | Low. Same shape: one integer comparison, and the untaken branch is the same `return 1` the failure path already uses |
| `EXTRA_FORBIDDEN_SUBSTRINGS` (the second here-string site) | The env override is unset in every self-test case, so the IN-07 block is never entered. The fix at that site is byte-identical in shape to the driven one and sits in the same loop body | Low, but stated rather than implied. The first site is driven at 71 KiB; this one is not driven at any size |
| The forbidden-substring scan against the **real** arm-1 dump | Requires the live path — ssh to LXC 100 and a `docker exec` into `beets-flask`. This plan makes no estate contact by design | Medium and pre-existing: GC-01 states the mechanism is proven but whether it fires against the live dump **today** is size-dependent and unconfirmed. This plan removes the mechanism; it does not measure the live dump's size. Whoever next runs the live path should record `wc -c` of `$WORKDIR/arm1.dump` — that number is the margin, and it was never written down |

## Threat Flags

None. This plan installs nothing (no npm/pip/cargo invocation anywhere in it), opens no network
path, reads no credential, and touches no file outside `scripts/check-beets-config.sh` and its
own artifact. `T-06-GC01` and `T-06-GC13` are both mitigated and driven; `T-06-22-SC` (supply
chain) is `accept` and remains vacuously true.

## Known Stubs

None.

## Handoff

- **Plan 06-24** owns `scripts/phase06-oracle.sh:1809`, `:1828`, `:1831` (GC-06). `:1831` is the
  inverted one and is the dangerous half; the other two fail toward a false red.
- **Plan 06-29** should carry the remainder — **23 lines / 24 pipelines**, five of them inverted —
  as a named deferred item citing
  `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-22-pipefail-141.txt`.
- **Anyone tightening `scripts/quick-health-check.sh`**: its six `| grep -q` sites are correct
  today *only* because that file carries no local `set` line. Adding `set -euo pipefail` to it
  arms all six at once.

## Self-Check: PASSED

Files claimed created/modified, checked on disk:

| Path | Result |
|---|---|
| `scripts/check-beets-config.sh` | FOUND (59,229 bytes) |
| `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-22-pipefail-141.txt` | FOUND (28,536 bytes) |
| `.planning/phases/06-tagger-configuration-and-dry-run/06-22-SUMMARY.md` | FOUND |

Commits claimed, checked in `git log`:

| Hash | Result |
|---|---|
| `b153c3b` | FOUND — `fix(06-22): remove the pipefail-141 pipeline …` |
| `ad5a854` | FOUND — `fix(06-22): count case 6's two outcomes independently …` |
| `76d1575` | FOUND — `docs(06-22): inventory the \| grep -q shape repo-wide …` |
