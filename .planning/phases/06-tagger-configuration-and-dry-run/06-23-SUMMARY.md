---
phase: 06-tagger-configuration-and-dry-run
plan: 23
subsystem: testing
tags: [health-checks, shell, d-04, cr-01, gc-03, gc-16, exit-codes, fail-closed, regex, vacuity-guard]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "the D-04 block and its conditions K/L as plan 06-16 left them, the exempt/doc pins recorded by 06-16, and the GC-03/GC-16 findings adjudicated in 06-REVIEW-GAP.md"
provides:
  - "condition P — the D-04 ladder refuses a ZERO ASSERTED count as UNKNOWN with EXIT_CODE=1, closing CR-01 one nesting level in"
  - "a green condition that cannot contradict the `N of M` it prints, because it now requires a non-zero asserted count itself"
  - "D04_INV_RE branch 4 anchored on shell separators and `docker` as well as content start and opening quote, symmetric with its three literal siblings"
  - "the thirteenth EXIT-CODE BEHAVIOUR CHANGED notice, with measured self-referential counts and the condition-letter trap recorded"
  - "the 199 / 98 / 10 / 8 / 3 / 5 / 2 count vector, in quotable form, for plan 06-28's GC-10 evidence"
  - "a driven artifact with the defect reproduced pre-fix, refused post-fix, and a passing partner"
affects: [06-28, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "a guard on the count you PRINT is not a guard on the set you ITERATE — condition K guarded `executable`, the loop iterated `executable minus exempt`"
    - "extract the code under test out of the shipping file with awk and run it over a synthetic fixture; a hand-transcribed ladder proves nothing about the ladder that ships"
    - "the `f && /^fi$/{exit}` guard: a bare terminator pattern matched 17 times earlier in the file and silently extracted zero lines"
    - "a detector that scans its own source file perturbs its own counts — state the delta, do not let a verify pin absorb it"
    - "find the next free condition letter by grep, not by counting forward from the previous notice: the twelfth notice used M/N/O out of order"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-23-d04-assert-vacuity.txt
  modified:
    - scripts/quick-health-check.sh

key-decisions:
  - "CONDITION LETTER IS P, NOT M. The plan said 'the next free letter after L'. Measured by `grep -nE '^#[[:space:]]+[A-Z]\\.[[:space:]]'`: A-O are all taken, because the twelfth notice used M, N and O out of alphabetical order. The letter was taken from the measurement, not from the plan, and the trap is recorded in the notice itself"
  - "⚠️ RAW AND COMMENT-STRIPPED MOVE 199 -> 200 and 98 -> 99. Reported, not absorbed. Cause is exactly one line: condition P's own message, which carries the literal token BY PLAN REQUIREMENT and is an `echo`, so it survives the comment strip. Downstream counts and BOTH PINS are untouched at 10 / 8 / 3 / 5 / 2. The widening itself is proven additive by running old vs new regex over identical input"
  - "The new notice and the rewritten block comment were written to add ZERO further scan matches, and that choice is stated in the notice rather than left silent — measured 35 before, 36 after, the +1 being the echo line alone"
  - "⚠️ UNKNOWN, not ❌, for the vacuous asserted set. An empty asserted set is a could-not-look, and this file's standing convention keeps that distinct from a measured failure — the three sibling guards use the same prefix"
  - "NOT pushed and NOT pulled. The host is at a pre-Phase-6 commit; deploying unmerged Phase 6 to make a check line up is out of bounds and is a recorded deliberate non-finding"
  - "This plan claims NOTHING about ROADMAP entry criterion E10 or CONF-04. It closes the NESTED instance of CR-01 and the blind spot beside it; CR-01's carried residue stays carried"

patterns-established:
  - "Ship a new guard with a driven RED and a driven passing partner in the same transcript — and when a second guard is belt-and-braces, drive it alone by deleting the first from a mutant copy"
  - "Prove a regex widening additive by comparing matched LINE SETS under diff, not only the counts"

requirements-completed: []

# Metrics
duration: 70min
completed: 2026-09-22
---

# Phase 6 Plan 23: D-04 Asserted-Set Vacuity and the Fourth-Branch Blind Spot — Summary

The D-04 verdict ladder can no longer print a green tick over an empty asserted set, and its
variable-expansion regex branch now sees invocations after `&&`, `;` and `docker exec` exactly as
its three literal siblings already did.

## What Was Done

### Task 1 — condition P: refuse a vacuous asserted set (GC-03) — commit `8605b0e`

Plan 06-16 added **condition K**, refusing a zero **executable** count. But the set the block
actually iterates is `D04_INVOKE_ASSERT` = executable **minus exempt**, and nothing guarded that
being zero. With every executable line exempt, K passes (5 ≠ 0), the exempt pin passes (5 = 5), the
doc pin passes, and `while … <<< "$D04_INVOKE_ASSERT"` over the empty string runs **zero** times —
so `D04_BAD` stays 0 and the block printed a tick whose own parenthesis read `0 of 5`.

That is **CR-01 — the Critical this phase's gap closure exists to close — reproduced one nesting
level in**, and it was *driven*, not argued:

| ladder | fixture | verdict | exit |
|---|---|---|---|
| **pre-fix** | all-exempt (exe 5 / exempt 5 / assert 0) | `✅ … (0 of 5 …)` | **0** |
| **post-fix** | same fixture | `⚠️ UNKNOWN — every invocation-shaped executable line is EXEMPT (5 of 5)` | **1** |
| **post-fix** | real tree (exe 8 / exempt 5 / assert 3) | `✅ … (3 of 8 …)` | **0** |
| post-fix, condition P deleted | all-exempt | no ✅ line at all | 0 |

Three changes shipped together:

- **(a)** a fourth ladder arm, `[ "$D04_N_ASSERT" -eq 0 ]`, in condition K's vocabulary and with
  the siblings' `⚠️ UNKNOWN` prefix.
- **(b)** `[ "$D04_N_ASSERT" -gt 0 ]` inside the green condition, so the tick and the
  `$D04_N_ASSERT of $D04_N_EXE` it prints cannot disagree whatever future ladder edit lands above.
- **(c)** the **thirteenth** `EXIT-CODE BEHAVIOUR CHANGED` notice, headers 12 → 13 and raw 15 → 16,
  both measured before and after rather than assumed.

The counter subtlety the plan flagged was measured rather than reasoned: `printf '%s\n' ""` emits a
blank line, but `grep -c '^HEAD:'` returns **0** for it, so `D04_N_ASSERT` genuinely is 0 on an
empty set and `-eq 0` is the right condition. The `while` loop was separately confirmed at zero
iterations.

### Task 2 — branch 4's anchor set (GC-16) — commit `58e4aaf`

Branch 4's leading alternation gained the shell-separator and `docker` anchors its three literal
siblings already carried. The **trailing** flag-or-subcommand requirement is untouched — that half
is what holds the executable count at 8 rather than 26.

```
OLD: (^HEAD:[^:]*:[0-9]*:[[:space:]]*(sudo[[:space:]]+)?|")
NEW: (^HEAD:[^:]*:[0-9]*:[[:space:]]*(sudo[[:space:]]+)?|"|[[:space:]](&&|;)[[:space:]]*|docker[[:space:]][^`]*[[:space:]])
```

**Additivity, measured over identical input** (the 199-line scan of base commit `bf509f4`, so the
regex is the only variable):

| count | OLD branch 4 | NEW branch 4 |
|---|---|---|
| raw | 199 | 199 |
| comment-stripped | 98 | 98 |
| invocation-shaped | 10 | 10 |
| executable | 8 | 8 |
| asserted | 3 | 3 |
| exempt | 5 | 5 |
| documentation | 2 | 2 |

Identical — and the matched **line sets** are byte-identical under `diff`, which is the stronger
statement. No pin moved.

Controls: `&& $BEET_BIN config -d` and `docker exec -u beetle c $BEET_BIN config -d` go **0/2 → 2/2**;
content-start `$BEET_BIN config -d` and literal `&& beet config -d` stay **2/2**; four mention /
argument-passing shapes stay **0/4** under both. The most useful negative is
`if [[ $BEET_EXEC_RC -eq 0 ]]; then` — it contains a `;`, so it is where the new separator anchor
could have over-matched. It does not, because the anchor requires whitespace before the separator
and the line reads `]];`. The follower test *would* have admitted it (` -eq` satisfies
`[[:space:]]+(-|[a-z])`), which is the clearest demonstration that both halves earn their place.

The block comment was brought **forward** to the widened behaviour. Recorded in it, so it is not
re-argued: the cross-family reviewer graded GC-16 BLOCKER on the claim that the comment promised
separator anchoring — **that justification was false**, the comment described the code accurately.
The gap was substantive and graded WARNING, with **no current instance in the tree**.

## Deviations from Plan

### 1. [Rule 1 — corrected plan instruction] The condition letter is **P**, not the "next free letter after L"

- **Found during:** Task 1(c).
- **Issue:** The plan says to "name the new condition with the next free letter after L". Measured
  with `grep -nE '^#[[:space:]]+[A-Z]\.[[:space:]]'`: **M, N and O are already taken** — the twelfth
  notice used them, with O in its "what now exits 1" section and M/N below it, out of alphabetical
  order. Following the plan literally would have produced a second condition M.
- **Fix:** used **P**, and recorded the trap in the notice itself with the grep that finds the next
  free letter, so the next author does not count forward from the previous notice's highest letter.
- **Files:** `scripts/quick-health-check.sh`. **Commit:** `8605b0e`.

### 2. [Rule 1 — reported, not absorbed] Raw and comment-stripped move 199 → 200 and 98 → 99

**This is a deviation from the plan's own verify block and from must-have truth #4, and it is
reported rather than papered over.**

- **Found during:** Task 1(a), confirmed by measurement after the Task 1 commit.
- **Issue:** `scripts/quick-health-check.sh` is itself inside D-04's scan scope (`scripts/`). The
  plan **requires** condition P's message to say *"this is NOT 'no bare beet invocations'"*, and
  that line is an `echo`, so it survives the comment strip and lands in **both** the raw and the
  comment-stripped count. Measured against final HEAD: **raw 200, comment-stripped 99**.
- **Why it was not "fixed":** the only ways to avoid it are to drop the plan-required sentence, or
  to mangle the token so the output text breaks. Both are worse than a stated delta. The four
  existing sibling guards each contribute the same line for the same reason and are already inside
  the 199; this is the fifth.
- **What did NOT move, checked rather than assumed:** the line is **not invocation-shaped** under
  any of the four branches (`grep -cE "$D04_INV_RE"` over it returns 0), so invocation-shaped /
  executable / asserted / exempt / documentation are unchanged at **10 / 8 / 3 / 5 / 2**, and
  **neither pin moved**. Both relational guards still hold: raw ≠ 0, and raw (200) ≠ stripped (99).
- **The widening's own additivity is unaffected**, because it was proven by running the old and new
  regex over *identical* input, which is the comparison the claim is actually about.
- **Containment:** the new notice and the rewritten block comment were written to add **zero**
  further matches — measured, `grep -c -w -E` with the block's two `-e` patterns over this file
  reads **35** at `bf509f4` and **36** after both commits, the +1 being the echo line alone. Where
  prose needed to name a shape, it points at the artifact instead of spelling it out, and that
  decision is stated in the notice so it can be checked.
- **Action for the phase:** plan 06-28's GC-10 evidence should quote **199 / 98 / 10 / 8 / 3 / 5 / 2**
  as the old-vs-new comparison (identical input) and **200 / 99 / 10 / 8 / 3 / 5 / 2** as the
  post-merge HEAD reading. Both are in the artifact.

### 3. [Rule 3 — blocking, tooling] The ladder-extraction terminator needed a guard

- **Issue:** `awk '/D04_HITS=\$\(printf/{f=1} /^fi$/{exit} f'` extracted **zero** lines, because
  `^fi$` occurs 17 times earlier in the file and `exit` fired before `f` was ever set.
- **Fix:** `f && /^fi$/{exit}`. Recorded in the artifact because a silently-empty extraction would
  have produced a harness that "passed" by doing nothing.

## Verification Results

| check | result |
|---|---|
| `bash -n scripts/quick-health-check.sh` | PASS |
| vacuity guard present (`D04_N_ASSERT" -eq 0`, non-comment) | PASS |
| green condition requires non-zero asserted (`D04_N_ASSERT" -gt 0`, non-comment) | PASS |
| exit-code notice headers = 13 | PASS |
| refusal uses the UNKNOWN vocabulary (`Nothing was asserted over`) | PASS |
| artifact exists, 16 KB, cites GC-03 and GC-16, records `0 of 5` and `199` | PASS |
| `D04_INV_RE=` assignments = 1 | PASS |
| widened regex matches the two previously-invisible shapes (2 of 2) | PASS |
| unchanged controls still match (2 of 2) | PASS |
| negative controls still refused (0 of 4, both regexes) | PASS |
| pinned counts against final HEAD: inv / exe / exempt / assert / doc | PASS — 10 / 8 / 5 / 3 / 2 |
| pinned counts against final HEAD: raw / comment-stripped | **DEVIATION — 200 / 99, expected 199 / 98.** Cause, containment and evidence in Deviation 2 above |
| `git diff --name-only -- scripts/` lists only `quick-health-check.sh` | PASS |
| no `git push`; host not asked to pull | PASS |

## NOT-DRIVEN Register

Stated rather than implied, per this phase's convention.

| item | why it was not driven |
|---|---|
| The **live** D-04 block against the estate | The block reads the **host's** HEAD at `/mnt/fast/stacks` and the host is at a pre-Phase-6 commit. Deploying unmerged Phase 6 to make a check line up is out of bounds — a recorded deliberate non-finding (`06-DISPOSITIONS.md`, deliberate non-findings §2). |
| **Condition P firing against a real tree** | No real tree has an empty asserted set — that is precisely why GC-16 ships with it. Driven against a synthetic fixture built by deleting three *real* lines out of a *real* scan. |
| **The two widened anchors matching a real line** | GC-16 is a latent blind spot with **no current instance in the tree**. Driven against synthetic positive controls; additivity proven against the real tree. If a real `&&`- or `docker`-anchored variable invocation ever lands, the executable count moves and the pins report it. |
| The ssh / sentinel / timeout arms above the ladder | Untouched by this plan; plan 06-16 owns their proof. |
| The `D04_EXEMPT_BASELINE` / `D04_DOC_BASELINE` / `D04_REPO_ROOT` override arms | Untouched by this plan; unchanged, and 06-16 owns their proof. |
| The green condition raising a **red** on a vacuous set | It cannot, and the artifact says so: driven with condition P removed, it withholds the tick but leaves `EXIT_CODE=0`. That is why the **arm** is the primary fix and `-gt 0` is belt and braces. |

## What This Does NOT Claim

It does **not** discharge ROADMAP entry criterion **E10** and it does **not** close **CONF-04**.
CR-01's carried residue stays carried — see the CR-01 row in `06-DISPOSITIONS.md`. What closed here
is the **nested** instance inside the D-04 ladder, and the branch-asymmetric blind spot beside it.

## Commits

| commit | task |
|---|---|
| `8605b0e` | Task 1 — condition P, the strengthened green condition, the thirteenth notice, the driven artifact |
| `58e4aaf` | Task 2 — branch 4's widened anchor set, the forward-brought comment, the additivity proof and controls |
| `dad5e96` | this SUMMARY |

## Self-Check: PASSED

- `scripts/quick-health-check.sh` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-23-d04-assert-vacuity.txt` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/06-23-SUMMARY.md` — FOUND
- commits `8605b0e`, `58e4aaf`, `dad5e96` — all present in `git log`
- `git diff --name-only bf509f4 HEAD -- scripts` returns **only** `scripts/quick-health-check.sh`
- working tree clean; no shared orchestrator artifacts (STATE.md, ROADMAP.md) touched
