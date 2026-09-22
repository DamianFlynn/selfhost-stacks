---
phase: 06-tagger-configuration-and-dry-run
plan: 26
subsystem: testing
tags: [health-checks, shell, quoting, remote-command-strings, gc-17, gc-14, gc-09, diagnosis, failing-block-tail]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "the D-04 ladder as plan 06-23 left it (condition P, the thirteenth notice, the 200/99 corrected counts), the consumers exit-3 arm from 06-17, and the D-03/D-04 overridable roots from 06-10/06-16"
provides:
  - "all four overridable paths that cross into a remote command string rendered once with printf '%q' — three named by the review plus a fourth the review missed"
  - "the printf '%q' bash dependency stated in band once and cross-referenced, naming GC-17 and GC-11"
  - "the CONSUMERS_SCRIPT override named on all six arms that can report it, not only the one that can go green"
  - "a failing-block tail rebuilt from a mechanical EXIT_CODE=1 enumeration, naming all 13 blocks that can reach it"
  - "the consumers block's expected warning named in the tail with ROADMAP entry criterion E6 as its clearing condition, without claiming CONF-04 closed"
  - "DEF-06-21-07 driven, and passing"
  - "a 98-site EXIT_CODE=1 enumeration attributed to 14 owning blocks, reusable by any future tail edit"
affects: [06-29, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "a `-F` substring test cannot verify a rename whose new token is a SUPERSTRING of the old one — `cd $X` is a prefix of `cd $X_Q`, so the plan's own verify failed on a correct fix"
    - "match a wrapped message against its RENDERED text, not its source: flattening `echo \"…\"` lines interleaves the quote delimiters into the prose and reports false FAILs"
    - "`OUT=$(eval \"$LADDER\")` runs in a subshell and silently discards the EXIT_CODE the harness exists to measure — redirect to a file in the current shell"
    - "rebuild an enumerated list from the enumeration, not from the review's examples: right about two blocks and wrong about a third is the same defect"
    - "a knob whose only purpose is to make a branch driveable is worthless if the knob's own value cannot survive the transport"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-26-qhc-knobs-and-tail.txt
  modified:
    - scripts/quick-health-check.sh

key-decisions:
  - "FOUR SITES, NOT THREE. DRIFT_CMD was found while planning and is closed with the review's three. Fixing three of four instances of a class inside one file, in the round whose subject is siblings that drifted apart, would have been GC-08 committed deliberately"
  - "SIX ARMS, NOT TWO. The plan's action named the exit-3 arm and the generic else; its own must-have truth #3 says 'every arm that can report it'. Six arms can report while overridden and one already did, so five gained the notice — including the empty-output and 124 arms, whose existing text NAMES THE DEPLOYED PATH in its re-run advice"
  - "⚠️ THE PLAN'S TASK-1 VERIFY IS WRONG AND IS REPORTED, NOT ABSORBED. `grep -cF 'cd $D04_REPO_ROOT'` expects 0 but -F matches a SUBSTRING, and that token is a PREFIX of the fixed `cd $D04_REPO_ROOT_Q` — so the plan's verify reports 1 on a correctly fixed file. Method wrong, conclusion right; a corrected whole-token method is recorded"
  - "⚠️ THE PLAN'S <verify> BLOCKS cd INTO THE MAIN CHECKOUT, which does not carry these edits. Not obeyed. Every measurement was taken from the worktree root resolved via `git rev-parse --show-toplevel`"
  - "scripts/phase06-oracle.sh NOT OPENED. GC-15 is two dex_cmd sites in that file and belongs to plan 06-27; the adjudication's summary line crosses the two labels and an executor following it would have fixed the wrong file and reported success"
  - "NOT pushed and NOT pulled. The four sites were driven against a SCRATCH checkout under /tmp on LXC 100, removed afterwards. Two round-1 plans instructed a push-and-pull and two executors correctly refused"
  - "NO new EXIT-CODE BEHAVIOUR CHANGED notice. This plan creates no new fatal condition — it names conditions that already existed. Header count 13 before and after; 06-23 owns the only new notice this round"
  - "This plan claims NOTHING about ROADMAP entry criterion E6 or CONF-04. The tail now SAYS CONF-04 is open; saying so is not closing it"

patterns-established:
  - "Drive a quoting fix by sending the real constructed string over the real transport, before and after, and read what the WRONG diagnosis said — 'exit 3 = no checkout' naming a checkout that exists is the finding, not the shell error"
  - "Pair a live end-to-end drive with an extracted-ladder harness when the live run's exit status is not discriminating because something else on the estate is independently red"

requirements-completed: []

# Metrics
duration: 95min
completed: 2026-09-22
---

# Phase 6 Plan 26: Knob Quoting, Override Visibility and the Failing-Block Tail — Summary

Four overridable paths no longer word-split on the remote shell, the
`CONSUMERS_SCRIPT` override is named on every arm that can report it rather than
only on the one that can go green, and the failing-block tail names all thirteen
blocks that can reach it instead of eleven.

## What Was Done

### Task 1 — GC-17: quote all four remote-command interpolations — commit `96bf5ff`

Three sites were named by the cross-family review (`cd $D03_REPO_ROOT`,
`D04_CMD="cd $D04_REPO_ROOT …`, `bash $CONSUMERS_SCRIPT`). A **fourth of the same
shape**, `DRIFT_CMD="set -o pipefail; cd $DRIFT_REPO_ROOT …`, was found while
planning and is closed with them. Each knob is now rendered once with
`printf '%q'` beside its own override-contract block, and only the rendered form
crosses the ssh boundary. The bash dependency is stated in band once, at the
first `_Q` assignment, cross-referenced from the other three, naming GC-17 and
GC-11 — and graded fail-closed, because a non-bash transport gives a loud syntax
error and a non-zero status, not a mangled command.

**Driven live**, against a scratch git checkout on LXC 100 whose path contains
spaces (`/tmp/qhc-06-26/probe root with space`), with all four knobs set at once:

| site | before | after |
|---|---|---|
| drift `cd` | `bash: line 1: cd: too many arguments` → ssh 3 | `cd` succeeds, reaches its `git show HEAD:<path>` half (exit 4) |
| D-03 render `cd` | same, ssh 3 | `cd` succeeds, `docker compose … config` renders from the scratch tree |
| D-04 scan `cd` | same, ssh 3 | `cd` succeeds, scans the scratch tree (`raw=57`), drives condition K's `executable == 0` arm |
| consumers `bash <file>` | exit **127**, landed in the generic `else` as ❌ BROKEN | reaches the **exit-3 arm** |

The interesting half is not the shell error, it is **the diagnosis it produced**:
all three `cd` sites reported *"3 = no `<path>` checkout"* while naming a path
that existed. The operator is sent to look for a directory that is right there.
The consumers site was worse — the exit-3 arm, the branch the knob exists to make
driveable, **could not be reached at all** through a space-bearing override.

The additive contract was re-confirmed in the same run: every knob printed its
warning, forced `EXIT_CODE=1`, and not one of the four blocks went green. The
exit 1 comes from the contract, not from a shell error.

`scripts/phase06-oracle.sh` was not opened.

### Task 2 — GC-14: name the override on every arm — commit `33ed08b`

`CONSUMERS_OVERRIDDEN` was consulted in exactly one place — the `-eq 0` arm,
where it stops a tick. The ladder has **six** arms that can report while
overridden; five had no notice at all. All six carry it now:

| arm | before | after |
|---|---|---|
| empty output ("172.16.1.159 unreachable") | — | notice |
| 124 bound expiry | — | notice |
| exit 0, summary anchor not found | — | notice |
| exit 0, summary found | notice | notice (unchanged) |
| exit 3, summary anchor not found | — | notice |
| exit 3, CONF-04 pending | — | notice |
| generic `else` | — | notice |

The empty-output and 124 arms needed it most: their existing text names the
**deployed** path in its re-run advice, and the empty-output arm additionally
says *"172.16.1.159 unreachable"* — a confident wrong diagnosis when the real
cause is a stub that printed nothing.

Five live drives with scratch stubs, plus an **isolated per-arm `EXIT_CODE`
proof** from a ladder extracted out of the shipping file. Nine fixture rows, and
the EXIT_CODE column is **identical pre and post in every one** — the override
column is the entire delta, moving only 0 → 1. The single green arm is still the
single green arm. No `warn()` site was promoted into `FAILURES`; the CONF-04
verdict text, the pending counts and all anchor guards are untouched.

**`DEF-06-21-07` is driven and it PASSES.** Pointed at a stub whose `📊 6. Summary`
heading is renumbered to `📊 7.`, the exit-3 arm reports
`⚠️ UNKNOWN — the audit exited 3 but its '📊 6. Summary' block was not found`
and prints **no counts**. That is exactly the condition the deferred item
specified, and it needed no estate contact beyond a `/tmp` stub. Not a new
finding — it behaves as 06-17 designed it. It is residue of WR-03 and can close.

### Task 3 — GC-09: rebuild the failing-block tail — commit `5ffbc3d`

The tail was rebuilt from a **mechanical enumeration**, not from the review's two
examples: every executable `EXIT_CODE=1` site attributed to its owning block by
grep'd anchor. 98 sites across 14 blocks; 13 can reach the tail (the coreutils
startup gate `exit 1`s on the spot). The tail named **11 of 13**. The two missing
ones — the D-03 vendored-config mount block and the D-04 throwaway `-l` scan —
hold **30 of the 98 sites**, second and third largest after the dashboard probe.

Coverage was proven mechanically, before and after, against the tail's **rendered**
text: 11/13 → **13/13**.

The tail also now names the consumers block's expected ⚠️ with **E6** as its
clearing condition — stated so it is not an invitation to ignore the block, and
explicitly saying CONF-04 is **not** closed.

A sixth comment paragraph records that the tail fell behind three plans (06-16,
06-17, 06-23) despite four in-band restatements of the same-commit discipline,
why that keeps happening (the rule is remembered while you edit the tail and
forgotten while you edit a block — and it is only needed in the second case), and
points the next author at the enumeration rather than the list. **No new numbered
exit-code notice**: this task creates no new fatal condition.

## Deviations from Plan

### 1. [Rule 1 — corrected plan instruction] The plan's Task-1 verify method is wrong

- **Found during:** Task 1 verification.
- **Issue:** the plan asserts
  `test "$(grep -v '^[[:space:]]*#' … | grep -cF 'cd $D04_REPO_ROOT')" -eq 0`
  for each of the four tokens. `grep -F` matches a **substring**, and
  `cd $D04_REPO_ROOT` is a **prefix** of the fixed line's `cd $D04_REPO_ROOT_Q`.
  Measured on the correctly fixed file, the plan's own method returns **1** for
  all four — i.e. it fails on the fix it asked for.
- **Fix:** the token is tested with its trailing separator, which makes it a
  whole token: all four return **0**. Both measurements are in the artifact §1.4.
- **Not absorbed:** method wrong, conclusion right. Reported here rather than
  silently substituted. This is the fifth plan this round whose verify carried a
  wrong premise.

### 2. [Rule 1 — corrected plan instruction] Every `<verify>` block `cd`s into the main checkout

- **Issue:** all three `<verify>` blocks open with
  `cd /Users/damian/Development/damianflynn/selfhost-stacks`. That is the **main
  checkout**, which does not carry this plan's edits. Obeying it literally
  measures the unmodified file and reports a green that describes nothing.
- **Fix:** not obeyed. Every command was run from the worktree root, resolved
  from `git rev-parse --show-toplevel`, never from a hard-coded repo path. Stated
  at the top of the artifact so the transcript can be trusted.

### 3. [Rule 2 — scope widened to close the class] GC-14 landed on six arms, not two

- **Issue:** the plan's action (a) names two arms; its own must-have truth #3
  says *"visible on every arm that can report it"*. Six arms can report while
  overridden. Closing two of six inside one block is the same shape as fixing
  three of four GC-17 sites.
- **Fix:** all six carry the notice. Diagnosis only — the per-arm `EXIT_CODE`
  table (artifact §2.3) shows nine fixture rows identical pre and post.

### 4. [Rule 3 — tooling] Two silent-pass traps in this plan's own harnesses

Both caught, both recorded, because each would have produced a harness that
"passed" by measuring nothing:

- `OUT=$(eval "$LADDER")` runs in a **command-substitution subshell**, so the
  ladder's `EXIT_CODE=1` was discarded and every row reported 0 — including rows
  that demonstrably set it. Caught only because the one row that *should* read 0
  read the same as the other eight. Fixed by redirecting to a file in the current
  shell.
- The tail-coverage checker first flattened the tail's **source** lines, which
  interleaves the `echo "` / `"` delimiters into the prose, so a phrase wrapping
  across two echo lines is split by `" echo "`. It reported FAIL for the
  dashboard probe and for D-04, both of which *are* named. Fixed by executing the
  tail's echo lines and matching the **rendered** text.

The ladder extraction also carries the `f && /^fi$/{exit}` guard and an assertion
that ≥40 lines came out, per 06-23's deviation 3.

### 5. [Reported, not absorbed] The plan's inherited 199/98 counts are stale

The plan does not pin them, but for the record: the **base commit already reads
200/99**, confirming 06-23's correction independently. This plan moved neither —
raw 200 / comment-stripped 99 at the base commit and after each of its three
tasks. Plan 06-28's GC-10 evidence should use **200 / 99** for a post-merge HEAD
reading.

## New Findings for Plan 06-29 to Disposition

### NEW-06-26-01 — the D-04 could-not-look message hard-codes a path the block may not have visited

Surfaced by the Task 1 drive. The D-04 no-sentinel arm prints
`(ssh exit 3; 3 = no /mnt/fast/stacks checkout, 4 = 'git grep' failed)` while the
`cd` above it uses `$D04_REPO_ROOT`. Under an override the operator is told a path
that was never visited. **Its two siblings get this right** — the drift arm and
the D-03 render arm both interpolate their own knob — so this is the same
three-of-four-siblings shape as GC-17 and the same wrong-diagnosis class as
GC-14, one block across. Verdict unaffected (the arm sets `EXIT_CODE=1`
regardless). Visible in the artifact's BEFORE transcript: the message says
`/mnt/fast/stacks` while the run was pointed at
`/tmp/qhc-06-26/probe root with space`. **Not fixed here — out of scope.**

### Pre-existing, unrelated, deliberately not fixed

`check-music-freeze.sh` is ❌ on the live estate in every run:
`interpolated-host-path inventory MOVED: expected=12, found=13`. That is the
host's own deployed copy at a pre-Phase-6 commit. Nothing in this plan touches
that file. Recorded so it is not mistaken for fallout.

## Verification Results

All checks run **from the worktree**, with `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD)
rather than the shell's `grep` alias to ugrep 7.8.4.

| check | result |
|---|---|
| `bash -n scripts/quick-health-check.sh` | PASS |
| four raw interpolations remaining (whole-token method) | PASS — 0 / 0 / 0 / 0 |
| four raw interpolations, **the plan's `-F` prefix method** | **DEVIATION — 1 / 1 / 1 / 1. Method wrong; see Deviation 1** |
| `printf '%q'` renderings, non-comment (≥4) | PASS — 4 |
| additive override contract sites `OVERRIDDEN=1` (≥4) | PASS — 9 |
| `CONSUMERS_OVERRIDDEN`, non-comment (≥5) | PASS — 9 (was 3) |
| `CONF-04 MEASURED AND OPEN` occurrences (==1) | PASS — 1, unchanged |
| `📊 6\. Summary` anchor guards (≥2) | PASS — 5 before, 5 after |
| per-arm `EXIT_CODE` across 9 fixtures, pre vs post | PASS — identical in all 9 |
| tail names D-04 / D-03 / E6 | PASS |
| tail does not claim `CONF-04 is closed` | PASS — 0 |
| `image-drift block CANNOT fail` (==1) | PASS — 1 |
| `EXIT-CODE BEHAVIOUR CHANGED` headers (==13) | PASS — 13 |
| tail coverage of the enumeration | PASS — 11/13 before, **13/13** after |
| D-04 self-scan counts, base vs after each task | PASS — 200 / 99 throughout, no movement |
| `git diff --name-only 9b28021 HEAD` | PASS — only `scripts/quick-health-check.sh` and the artifact |
| `scripts/phase06-oracle.sh` untouched | PASS |
| no `git push`; host not asked to pull; host scratch removed | PASS |
| unoverridden control run of the fixed file | PASS — D-03 green, tail renders, no regression |

## NOT-DRIVEN Register

| item | why it was not driven |
|---|---|
| a knob value containing a **quote** or a `$` rather than a space | `printf '%q'` handles all three identically and the space case is what the finding is about. Argued, not measured. |
| a knob value containing a **newline** | The only case that reaches bash ANSI-C `$'…'` quoting, and therefore the only one that exercises the stated bash dependency. Argued from GC-11's reproduction in `phase06-oracle.sh`; fail-closed either way. |
| the consumers **124** and **empty-output** arms against the LIVE script | Their new notices were driven in the extracted-ladder harness, not end to end: producing a real bound expiry or a real empty answer on a healthy estate needs a wedged host or a contrived sleep. |
| the D-03 / D-04 blocks actually printing the tail's new text on a run where only they are red | The tail is one unconditional message; its content does not vary by which block failed. The coverage check is the proof that applies. |
| the **live** exit-3 consumers arm on the deployed audit | It cannot be reached: the host's `check-music-consumers.sh` is a pre-Phase-6 copy with **zero** `exit 3` occurrences (host HEAD `c67d497`). That is exactly why `CONSUMERS_SCRIPT` exists, and why GC-17's fourth site mattered. |
| the drift block completing a real comparison under the override | The scratch checkout is built from the host's pre-Phase-6 tree, which has no `flask-config.yaml`, so the fourth pair legitimately gives exit 4. That is a fact about the host's commit, not about the fix. |

## What This Does NOT Claim

It does **not** discharge ROADMAP entry criterion **E6** and it does **not** close
**CONF-04** — the tail now *says* CONF-04 is open, and saying so is not closing
it. It does **not** touch `scripts/phase06-oracle.sh`; GC-15 lives there and
belongs to plan 06-27. It does **not** claim the estate is healthy: the live runs
show the music freeze harness ❌ on a pre-existing condition this plan did not
cause and deliberately did not fix.

## Commits

| commit | task |
|---|---|
| `96bf5ff` | Task 1 — four `printf '%q'` renderings, the bash dependency note, the live before/after drive |
| `33ed08b` | Task 2 — the override notice on six arms, five live drives, the per-arm EXIT_CODE proof, DEF-06-21-07 |
| `5ffbc3d` | Task 3 — the tail rebuilt from the enumeration, the E6 clause, the sixth comment paragraph |
| `d630bc8` | this SUMMARY and the artifact's control-run addendum |

## Self-Check: PASSED

- `scripts/quick-health-check.sh` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-26-qhc-knobs-and-tail.txt` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/06-26-SUMMARY.md` — FOUND
- commits `96bf5ff`, `33ed08b`, `5ffbc3d`, `d630bc8` — all present in `git log`
- `git diff --name-only 9b28021 HEAD` returns only `scripts/quick-health-check.sh`
  and the artifact (plus this SUMMARY)
- `git diff --diff-filter=D --name-only 9b28021 HEAD` returns **nothing** — no file
  was deleted by any commit in this plan
- working tree clean; no shared orchestrator artifacts (STATE.md, ROADMAP.md,
  deferred-items.md) touched — NEW-06-26-01 is recorded in this SUMMARY and the
  artifact rather than in the shared `deferred-items.md`, deliberately, because
  three other wave-2 agents are running against the same file
- the LXC 100 scratch tree `/tmp/qhc-06-26` was removed after the drives
