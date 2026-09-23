---
phase: 06-tagger-configuration-and-dry-run
plan: 31
subsystem: testing
tags: [bash, self-test, sha256sum, awk, fail-closed, gap-closure, oracle]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plans 06-22..06-28 wrote the code this plan repairs; 06-29 dispositioned it; GC-02/GC-05/GC-12/GC-15 are the round-2 fixes these four findings land on"
provides:
  - "A pinned self-test case count (ST_PLANNED_CASES=134) gated as its own arm, proven discriminating by ablation"
  - "One whitespace-tolerant sha256sum parser at all four layer-3 consumers"
  - "Two emptiness guards on the layer-3 AFTER hashes, symmetric with BEFORE"
  - "A self_test_fences safety claim narrowed to the property its cases actually assert"
affects: [phase-06 gap-closure round 3 verification, phase-07 pilot import]

tech-stack:
  added: []
  patterns:
    - "Announced-vs-actual case-count pin, mirroring scripts/check-beets-config.sh's ST_PLANNED_CASES idiom"
    - "Ablation drive: prove a guard discriminates by deleting exactly one line in a scratch copy and running both directions"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-31-oracle-pin-and-layer3.txt
  modified:
    - scripts/phase06-oracle.sh

key-decisions:
  - "Global case-count pin taken over the review's per-section sentinel alternative: it is the sibling's existing idiom, and inventing a second idiom for one job is a cost the alternative does not price in"
  - "The layer-3 parser compares the whole remainder for EXACT equality rather than testing a suffix — a suffix test can match a line it was not asked about, turning R3-03's false UNKNOWN into a false GREEN"
  - "R3-06's three cases were deliberately NOT widened; the prose was narrowed instead, and that decision is recorded in band so the narrower sentence is not read as a weakening"
  - "The pin gate is a separate arm from the ST_FAIL/REDS gate, ordered before it, mirroring the sibling — GC-12(b) exists because two failures once shared one banner"

patterns-established:
  - "A universal claim in a banner needs a pinned set behind it; a reported count is not an asserted one"
  - "A could-not-look is never folded into another verdict — and where UNKNOWN outranks RED, folding it into RED also demotes the verdict"

requirements-completed: []

duration: 6min
completed: 2026-09-23
---

# Phase 06 Plan 31: Oracle Pin and Layer-3 Summary

**The oracle's self-test now asserts its own case count instead of reporting it — an ablation that drops `self_test_fences` turns a green 111-case run into a named failure — and the layer-3 block can finally measure a space-bearing path while routing both sides' could-not-looks to UNKNOWN.**

## Performance

- **Duration:** ~6 min (first task commit 08:45:01+01:00 → last 08:50:29+01:00)
- **Tasks:** 3 of 3
- **Files modified:** 1 code file, 1 artifact created
- **Commits:** 3

## Accomplishments

### R3-02 — the case-count pin (Task 3, commit `e714632`)

`ST_PLANNED_CASES=134` is declared beside the dispatcher and compared against `ST_RUN` before
the banner. **Driven in both directions**, in a scratch copy from `mktemp -d`, deleted after:

| Direction | Ablation | Result |
|---|---|---|
| Catches | `self_test_fences` removed from the dispatcher — a **one-line** diff (`2604d2603`) | exit **1**, `✗ self-test: 111 case(s) ran but 134 were announced - A SECTION DID NOT RUN` |
| Does not over-fire | the real file, unmodified | exit **0**, banner reports the pinned **134** |

The load-bearing measurement: the mutant run produced **zero** failed cases and **zero** reds.
`ST_FAIL` was 0 and `REDS` was 0, so the pre-existing gate **would have passed it green** over a
set that had silently lost the only executed test of the `rm -rf` / `rm -f` receiving-side
fences. R3-02's scenario is reproduced, not argued. 23 cases vanished and nothing else changed.

The pin value was **measured, not copied from the plan**. Task 3 ran last on purpose so the count
had stopped moving. The plan's planning-time baseline of 134 turned out to agree — and it agrees
for a checkable reason, not by luck: task 1 changed the layer-3 block, which `--self-test` never
executes, and task 2's diff was **0 non-comment lines**.

### R3-03 — the layer-3 hash consumer (Task 1, commit `43e5d6c`)

All four consumers now carry one parser: strip a leading `<hex><SP><SP>` from a copy of the line,
compare the **remainder** for exact equality, take the digest as field 1. Driven against synthetic
`sha256sum` output with no estate contact, on the workstation's own awk (which *is* the real
consumer — the awk reads local files):

| Probe | Old key | New key |
|---|---|---|
| space-bearing path `/config/my library.db` | `[]` — the defect | `[aaaa…1111]` |
| no-space path (control) | `[2222…9999]` | `[2222…9999]` — no regression |
| line does not name the requested path | — | `[]` |
| `p='library.db'` (suffix probe) | — | `[]` |
| `p='my library.db'` (suffix probe) | — | `[]` |
| GNU backslash-escaped line (newline in path) | — | `[]` — fail-closed, refused not mis-parsed |

Both properties the plan demanded were established: the hash **is** returned for a space-bearing
path, and **empty** is returned for a line that does not name the requested path — so the
emptiness guards still fire and this cannot become a false green.

The GC-15 paragraph keeps its correct account of why `%q` is right for the *sending* side and no
longer claims the consumers were fine; it names R3-03.

### R3-04 — the layer-3 AFTER emptiness guards (Task 1, commit `43e5d6c`)

The AFTER block now has the BEFORE block's two guards, **above** the comparisons. Driven as
detached copies of both shapes, with both controls:

| Input | Old shape | New shape |
|---|---|---|
| empty AFTER hash | RED, `(<64-hex> -> )` — arrow at an empty string, exit 1 | **UNKNOWN**, exit 3 |
| genuinely different hash | RED, exit 1 | RED, exit 1 — unchanged |
| matching hash | green, exit 0 | green, exit 0 — unchanged |

The guard changes the verdict on exactly one input and leaves both real outcomes where they were.
Recorded in band in the file's own vocabulary: a could-not-look is never folded into another
verdict, and because UNKNOWN outranks RED here, folding it into RED also **demoted** the verdict.

### R3-06 — the `self_test_fences` claim (Task 2, commit `ad88ef5`)

Dispositioned as a **claim correction only**, and held to that: **0 non-comment lines** in the
diff, `*"rm "*` still returns 3, fence texts byte-unchanged. The prose now states only what is
executed, and writes out the gap — `touch` unasserted; redirection unasserted, with the `>&2`
point resolved under **both** readings (a blanket no-redirection claim is false as stated since
`>&2` appears in all three fence texts; the narrower "nothing redirected into a PATH" sense does
hold since `>&2` opens nothing — but under either reading the property is unasserted, and that is
the correction that matters). The two-character token bound is stated rather than left implicit.
The decision **not** to widen the cases is recorded in band.

## Deviations from Plan

**None affecting scope or approach.** Three mechanical corrections were made during execution,
each caught by the plan's own verify block — worth recording because all three are the same
failure mode the plan warned about (a comment that quotes a string is indistinguishable, to grep,
from the code that uses it):

1. My R3-04 comment quoted the `layer 3: the real library.db CHANGED` verdict verbatim, taking
   that grep from 1 to 2. Reworded to describe the verdict instead of quoting it, with the reason
   stated in band.
2. The phrase `no case below executes a destructive program` wrapped across two comment lines, so
   the single-line grep missed it. Reflowed onto one line.
3. My reflow of the surviving paragraph broke `A self-test case that can destroy a real path`
   across lines. Restored to one line.

None changed behaviour; all three were prose layout inside comments.

**Worktree note, not a deviation:** the worktree spawned at `5c5108a`, one commit behind the
expected base `fff070a`. The startup check reset it, as the plan's `<worktree_branch_check>`
anticipated.

## NOT-DRIVEN REGISTER

Stated explicitly because this plan makes claims about code it did not execute in situ.

| Not driven | Why | What was done instead |
|---|---|---|
| **The whole layer-3 block** (both BEFORE and AFTER) | Reachable only from a live `--run`. This plan performs no `--run` and no `--arm`, per its own verification section | The two *changed parts* were driven as detached copies: the awk consumer verbatim, and the guard/compare arms in the shape the file now carries. §§ 1–2 of the artifact |
| `--run` / `--arm` / any estate contact | Out of scope for a hardening round; importing is Phase 7 work | `--self-test` is estate-free, which is why the R3-02 proof was cheap |
| A space-bearing `REAL_LIB_DB` against the **real** container | Needs a live run and an estate knob change | Synthetic input in the exact format `sha256sum` emits |
| R3-06 | Claim correction with no executable component **by design** | Verified by grep that the cases and fence texts are byte-unchanged |

## Verification

Plan-level verification, all re-run from the worktree root after the final commit:

- `bash -n scripts/phase06-oracle.sh` — clean after every task
- `bash scripts/phase06-oracle.sh --self-test` — exits 0 after every task
- No exit code renumbered (`06-DISPOSITIONS.md` § Deliberate non-findings §1 respected) — confirmed by diffing the whole plan range against `fff070a`
- Every scratch copy lived under `mktemp -d`, outside the repo, and was deleted. The script's own `$OUT` defaults to `${TMPDIR:-/tmp}/phase06-oracle` — checked before running the mutant
- `git diff --name-only -- scripts/` lists only `scripts/phase06-oracle.sh`
- `scripts/setup-neocortex-memory.sh`, `stacks/selfhosted/neocortex-memory/` and `stacks/selfhosted/agentic-os/` untouched
- **No requirement checkbox moved.** CONF-04 is not closed; the phase is not declared complete. `requirements-completed` is deliberately empty despite the plan's `requirements: [CONF-03, CONF-06]` frontmatter, because the plan's verification section forbids moving checkboxes

All three tasks' `<verify>` blocks pass, and tasks 1 and 2 were re-run after task 3 to confirm no
regression.

**Measurement location:** every measurement in this plan was taken from the worktree root
`.claude/worktrees/agent-a840cc0bbe924fbad`, which is what `cd "$(git rev-parse --show-toplevel)"`
in each verify block resolves to for this executor.

## Known Stubs

None. No placeholder values, no unwired data paths, no TODO/FIXME introduced.

## Threat Flags

None. This plan adds no network endpoint, no auth path, no file-access pattern and no schema
change. It installs nothing (T-06-31-SC accepted as such in the plan's register). The four
threats it mitigates — T-06-R302, T-06-R303, T-06-R304, T-06-R306 — are each addressed above.

## Self-Check: PASSED

- `scripts/phase06-oracle.sh` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-31-oracle-pin-and-layer3.txt` — FOUND
- Commit `43e5d6c` — FOUND
- Commit `ad88ef5` — FOUND
- Commit `e714632` — FOUND
