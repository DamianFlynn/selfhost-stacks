---
phase: 06-tagger-configuration-and-dry-run
plan: 27
subsystem: phase-06 instruments (the oracle)
tags: [gap-closure, round-2, wave-2, vacuity, quoting, self-test, comments]
gap_closure: true
gap_closure_round: 2
wave: 2
requires: ["06-24", "06-25"]
provides:
  - "scripts/phase06-oracle.sh: one vacuity vocabulary across all four guards"
  - "scripts/phase06-oracle.sh: no overridable path reaches a remote command string unquoted"
  - "scripts/phase06-oracle.sh: a self-test failure banner that names the counter that tripped"
  - "artifacts/06-27-oracle-vacuity-and-claims.txt: the driven before/after for all three"
affects:
  - "the oracle's LIVE EXIT STATUS: a vacuous D-15 or D-13 now exits 3 (UNKNOWN), not 1 (RED)"
closes_findings: [GC-05, GC-15, GC-12, GC-07, GC-11]
tech-stack:
  added: []
  patterns:
    - "a could-not-look returns 2 and routes to unknown(); a measured failure returns 1"
    - "printf '%q' at the call site for bash WORD contexts; remote_sh_c for program text"
key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-27-oracle-vacuity-and-claims.txt
  modified:
    - scripts/phase06-oracle.sh
decisions:
  - "Both vacuity arms return 2, not 1: a rule the run never exercised cannot have measurably failed"
  - "GC-15 quoted at the two call sites, not inside dex_cmd, which would double-quote eighteen existing sites"
  - "REDS is NOT folded into ST_FAIL: they count different things and the self-test exists to keep them apart"
  - "GC-07 applies plan 06-25's single recorded decision; no second decision was made"
metrics:
  tasks: 3
  commits: 3
  duration: ~50m
  completed: 2026-09-22
---

# Phase 6 Plan 27: Oracle Vacuity, Quoting and Claims Summary

Five round-2 findings closed in `scripts/phase06-oracle.sh`: the four vacuity guards now share one
verdict vocabulary (a vacuous D-15 or D-13 exits **3 UNKNOWN**, not **1 RED**), the file's last two
unquoted path interpolations are `%q`-quoted with their consumer confirmed by argv capture, the
self-test banner names the counter that tripped, and two comments that asserted properties the code
does not have now state what is true.

## What was built

| Finding | Change | Driven |
|---|---|---|
| **GC-05** | `assert_no_compilations`' zero-`Various Artists` arm and `assert_dj_count`'s zero-wanted arm return **2**; both self-test expectations moved `1 -> 2` with them | yes, both ways, including the counter |
| **GC-15** | both `dex_cmd sha256sum` sites pass `printf '%q'` output; the consuming `awk` keys stay raw, confirmed not assumed | yes, by capturing the command string and its argv |
| **GC-12** | the dead `UNKNOWNS=0` deleted; the banner names both counters | yes, both ways, on two scratch copies |
| **GC-07** | the `RUN_TAG` comment credits the step-1 probe and applies 06-25's decision | comment-only, proven comment-only |
| **GC-11** | one sentence in `remote_sh_c`'s comment on the `%q`-rendered program text | comment-only, proven comment-only |

**The verdict change is recorded, not silent.** The EXIT CODES block states that a vacuous D-15 or
D-13 now exits 3 where it exited 1, gives the one-sentence reason, says NOTHING WAS RENUMBERED, and
cross-references the precedence paragraph — because the practical effect is the reverse of how it
reads: as a RED a vacuity was *erased* by any unrelated blindness in the same run (3 outranks 1); as
an UNKNOWN it now participates in that precedence and reaches the operator.

`06-DISPOSITIONS.md` § Deliberate non-findings §1 is respected: two assertions moved *between*
existing codes; no code was redefined and the numbering difference against
`phase06-incremental-control.sh` is untouched.

## Verification

All commands run from the **worktree root**, not the main checkout. `/usr/bin/grep` called
explicitly (BSD grep 2.6.0-FreeBSD), not the operator's zsh ugrep alias.

- `bash -n scripts/phase06-oracle.sh` — clean after every task.
- `bash scripts/phase06-oracle.sh --self-test` — exit 0, **134 case(s)**, after every task. Same
  count 06-24 left; no case added, none removed.
- `git diff --name-only 9b28021..HEAD` — exactly the two files in `files_modified`.
- 06-24's invariants still hold: bare-glob fences 0, `printf … | grep -q` pipelines 0.
- Task 3's diff: **0 non-comment lines**; `--self-test` output byte-identical before and after
  (sha256 `400f7183…`), no normalisation needed or applied.

## Deviations from Plan

### 1. [Rule 1 — method defect in my own harness] The first counter drive measured nothing

**Found during:** Task 1. The harness called `out="$(run_assert …)"`. `$(…)` is a subshell, so
`REDS`/`UNKNOWNS` were incremented in a child and discarded — the first run reported
`REDS=0 UNKNOWNS=0` for every case, *including ones that had just printed a red tick*. The counter
is the half GC-05 is about. Corrected by writing `run_assert`'s output to a file and reading it
back. Same defect class as the `OUT=$(eval …)` trap this round has already recorded twice. Recorded
in the artifact rather than quietly fixed.

### 2. [Rule 1 — my own edit] A stray `RUN_TAG_WHY=` assignment in a comment-only task

**Found during:** Task 3, by the comment-only check, not by review. The first draft of the `RUN_TAG`
edit introduced a new variable assignment — a behaviour change in a task that must not have one.
Removed before the check completed. Recorded because the check caught what reading did not.

### 3. [Reported, not absorbed] The plan's suggested GC-07 wording states a reason that is false

The plan asked the corrected comment to give, as the reason the leaf names were not minted here,
that *"`$SCRATCH` **and the per-run names** are quoted by the WR-07 fence, the precheck and the
committed 06-11 artifacts, so renaming them would invalidate committed proof"*. That is true of the
**directory** and false of the **leaf names**: `artifacts/06-11-oracle-run.txt` still quotes
`/tmp/p6/lib.db` and `/tmp/p6/state.pickle` — the **pre-06-18** leaves — so plan 06-18 already
renamed them once and invalidated nothing. The comment keeps the true half (the directory *is*
pinned, by the fence allow-list, the precheck, the cleanup assertion and the artifacts) and records
that minting the leaves is a **scope** decision, not a dependency conflict, so the plan that does it
does not inherit a false obstacle.

### 4. [Reported] A wrong-premise verify check — the fifth this round

`grep -ci 'removes the predictability' $O` must be 0, meaning "no longer claims unpredictability
outright". The first draft *quoted* the old phrase in order to disown it, which is the correct prose
and a failing check: a grep for the **absence** of a token cannot tell a claim from its retraction.
The sentence was reworded to describe the old claim without quoting it, so the check now passes for
the reason it intends. The check was satisfied honestly, not worked around.

### 5. [Reported] The `<verify>` blocks `cd` to the main checkout — the fourth agent this round

Every `<verify>` in this plan opens with `cd /Users/damian/Development/damianflynn/selfhost-stacks`,
which does not carry this worktree's edits. Obeying it would have measured the unmodified file and
reported a green describing nothing. Every command was run from the worktree root instead. Plans
06-24 and 06-25 recorded the same correction. **The template is the defect, not the agent.**

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema change was introduced. The
one security-relevant *reduction* is GC-15's: two operator-controlled values no longer reach a
remote command string unquoted.

## NOT-DRIVEN Register

Everything here is reachable only from a live `--run`, which **imports** — out of scope for a
hardening round. No estate contact, no ssh, no docker, no `--run`, no `git push`.

| Not driven | Driving condition |
|---|---|
| The two `dex_cmd sha256sum` sites **as sent**. What was driven is the command string and the argv a bash far side builds from it; the container never saw it | the next real `--run`: both `layer3.before`/`layer3.after` parse and both `awk` keys match |
| A `REAL_LIB_DB` carrying a space against a real container. **Predicted** (not measured): UNKNOWN + exit 3 at `[ -n "$LIB_SHA_BEFORE" ]`, because `awk`'s `$2` cannot key a whitespace path | a deliberate override on a live run |
| The `RUN_TAG` names themselves — `--self-test` never reaches step 5, the only place `SCRATCH_LIB`/`SCRATCH_OVERLAY`/`SCRATCH_STATE` are used. This is `DEF-06-21-02`'s standing condition, unchanged | the next real `--run` |
| The step-1 probe **inside the container** — its text is driven against local `/bin/sh`; the container's dash, `docker exec`'s status propagation, and a directory unreadable by `beetle` specifically remain undriven, as `artifacts/06-19-oracle-vacuity-driven.txt` already records | the next real `--run` |
| The live vacuity arms — the verdict change is driven through `run_assert` over synthetic fixtures; a real DJ-less or compilation-less **sample** has not been through a live run | a live run over a sample with no S5 stratum or no compilation |
| A non-bash transport to LXC 100 (GC-11's dependency) — quoted from GC-11's own reproduction, not re-measured | changing root's login shell on `$LXC_HOST`, which nothing plans to do |

## Files Not Touched, Deliberately

- `scripts/quick-health-check.sh` — owned by sibling plan 06-26 this wave. GC-15's sites are **not**
  in that file; the adjudication crossed GC-15's label with GC-17's, and this plan inherited the
  correction rather than going looking.
- `deferred-items.md` — a wave-2 collision risk. `DEF-06-21-02`'s substance is unaffected (a comment
  edit changes no treatment); the *description* of what the run tag buys is now corrected in band,
  and updating the entry is plan 06-29's job. Stated here and in the artifact instead of edited.
- `STATE.md`, `ROADMAP.md` — the orchestrator owns those writes after the wave.

## Self-Check: PASSED

Files claimed created/modified, all FOUND on disk:
`06-27-SUMMARY.md`, `artifacts/06-27-oracle-vacuity-and-claims.txt`, `scripts/phase06-oracle.sh`.

Commits claimed, all FOUND in `git log 9b28021..HEAD`:
`613ace8`, `38fd534`, `525ef7c`, `1f0a8a1` (plus this amendment).

`git status --short` is empty — nothing left uncommitted in the worktree.
