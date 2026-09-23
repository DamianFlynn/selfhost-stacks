---
phase: 06-tagger-configuration-and-dry-run
plan: 32
subsystem: phase-06-instrumentation
tags: [gap-closure, round-3, shell-hardening, trap, fence, posix-sh]
gap_closure: true
gap_closure_round: 3
closes_findings: [R3-09, R3-10]
requirements: [CONF-03, CONF-06]
requires:
  - "06-25 (GC-08) — minted both in-container scratch names and put cleanup on a trap"
  - "06-29 — round 2's dispositions"
provides:
  - "both in-container traps fire on interrupt/terminate/hangup as well as exit"
  - "GC-02's two-stage character-class predicate on both in-container fences"
  - "a claim narrowed from an absolute to what the predicate actually gives"
  - "an sh -n proof over both extracted heredoc bodies — the gate bash -n cannot give"
affects:
  - "scripts/phase06-incremental-control.sh (the only code file touched)"
tech-stack:
  added: []
  patterns:
    - "prefix test + character-class remainder test guarding every destructive path"
    - "heredoc-body extraction + sh -n, because bash -n parses heredocs as data"
key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-32-incremental-trap-fences.txt"
  modified:
    - "scripts/phase06-incremental-control.sh"
decisions:
  - "The best-effort sweep over unminted /tmp names was REFUSED, not forgotten — a wider destructive reach than an INFO litter finding justifies on a shared container /tmp; carried to the deferred register by plan 06-34"
  - "No eighth --self-test section was added — the seven announcements would each need editing for a proof that heredoc extraction plus sh -n gives more directly"
metrics:
  duration: "~35 min"
  completed: 2026-09-23
  tasks: 2
  commits: 2
---

# Phase 06 Plan 32: Incremental-Control Trap Fences Summary

Both in-container traps in `scripts/phase06-incremental-control.sh` now survive a bounded remote
kill and refuse a traversal, and the comment beside them claims only what the predicate gives.

## What Was Done

Two INFO findings from gap-closure round 3, both one-token fixes with a real consequence, both
instances of the pattern this round exists to stop: a fence whose comment is stronger than its code.

### R3-09 — the traps were registered on the exit pseudo-signal alone (commit `928f9c2`)

GC-08's argument for moving cleanup onto a trap was correct and survives unedited: every `BLIND`
arm in these programs exits early, and the old trailing `rm -f` sat after the last one, so any
could-not-look left all three scratch files behind. What was incomplete was the signal set. A POSIX
shell runs an exit trap on normal termination and on `exit` — **not** on an uncaught `SIGTERM`.
Both programs are delivered as `sh -s` through `timeout $REMOTE_TIMEOUT docker exec` (the bound
defaults to 120 s), and a bound expiry is a routine outcome for a manifest over a large tree, not an
exotic one. On the narrow list, that expiry left behind exactly what GC-08's own comment names as
the worse case — *"a MINTED leftover is worse litter than a fixed one, because nobody knows its
name"* — one unguessable directory per timed-out run, in a `/tmp` the same header records as mode
1777.

Both traps now carry the interrupt, terminate and hangup signals alongside exit. The residual is
stated in band rather than claimed away: **`SIGKILL` cannot be trapped, so a hard kill still leaves
the directory.** The widening shrinks the window; it does not close it.

### R3-10 — both new fences were bare globs, and one claimed an absolute (commit `befe732`)

GC-02's entire content, in the sibling `scripts/phase06-oracle.sh`, is that a shell glob matches `/`
while the character class `[A-Za-z0-9._-]` does not. In the **same round**, this file shipped two
fresh fences of exactly the bare-glob shape, both adjacent to `rm -rf` / `rm -f`, and the comment
beside one claimed it *"can never remove anything else"*.

Both fences now use the sibling's two-stage predicate: the template prefix, then a remainder that
must be non-empty and drawn entirely from `[A-Za-z0-9._-]`. The empty pattern is written with double
quotes, not single — the trap body is a single-quoted string, so an inner single quote would
terminate it. The absolute claim is gone; the comment states the predicate, cites
`scripts/phase06-oracle.sh` so the two files now state **one** rule rather than two, and records
that the defect was **latent, not reachable**: `MANDIR` and `THPROG` are only ever `mktemp` output,
and `mktemp` will not emit a traversal.

## Evidence

The predicate was driven offline as a standalone `sh` snippet — **not** as a trap, and with no `rm`,
`rmdir` or unlink of any kind in the drive file, which prints `WOULD-REMOVE` / `REFUSED` instead:

| Input | old | new |
|---|---|---|
| `/tmp/p6-mf.a/../../../home` | WOULD-REMOVE | **REFUSED** |
| `/tmp/p6-mf.660lOc4t` (real `mktemp -d`) | WOULD-REMOVE | WOULD-REMOVE |
| `""` (empty string) | REFUSED | REFUSED |
| `/tmp/p6-mf.` (bare prefix) | WOULD-REMOVE | **REFUSED** |

The same four rows were driven for the `/tmp/p6-taghist.` fence with identical outcomes. Row 1 is
the input the fence exists to refuse, and the old fence accepted it. Row 2 is the positive control —
a fence tightened without one typically ships broken on the intended path. Both minted names were
removed after the drive, outside it, with a plain `rmdir` and `rm -f`.

**The gate `bash -n` cannot give.** Both traps live inside `<<'REOF'` heredocs, which `bash -n`
parses as *data* — so a malformed multi-line trap would pass `bash -n`, pass `--self-test` (which
drives neither program), and fail only on the estate, the one place this phase is not allowed to go.
Both bodies were extracted with `awk` and parsed as POSIX sh:

| body | lines | predicate occurrences | `sh -n` |
|---|---|---|---|
| `manifest.sh` | 65 | 1 | PASS (rc 0) |
| `taghist.sh` | 31 | 1 | PASS (rc 0) |

Outer gates: `bash -n` clean and `--self-test` exit 0 after **both** tasks, seven announced sections
and no eighth.

Full record: `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-32-incremental-trap-fences.txt`

## NOT-DRIVEN Register

Stated rather than glossed, because this round exists to stop claims outrunning evidence.

| Not driven | Why | What would drive it |
|---|---|---|
| **Both traps as executed in the container** | No estate contact this phase — no `ssh`, no `docker exec`, no `--run`, no `--arm`. What was proven locally is that the program text parses as POSIX sh and that the predicate behaves as claimed; nothing here observed either trap firing inside `beets-flask` | The next real `--arm a` / `--arm b` pair, which should also confirm no `p6-mf` or `p6-taghist` name survives the run |
| **The `SIGTERM` behaviour itself** | Static reasoning about POSIX `sh` and about what `timeout` sends at expiry. The review records its own finding the same way | A live run under a deliberately short `REMOTE_TIMEOUT`, checking the container's `/tmp` afterwards |
| **The refused `/tmp/p6-mf.*` sweep** | Deliberately not implemented, so there is nothing to drive | Nothing — it is a refusal, not a gap. **Flagged for plan 06-34's deferred register** with its reason attached |

## Deviations from Plan

**None — the plan executed exactly as written.**

One expected, pre-announced condition, recorded because the prompt asked for it rather than as a
deviation: the worktree spawned at `5c5108a`, one commit behind the expected base
`fff070a`. The startup `git reset --hard` corrected it, as the plan's `<worktree_branch_check>`
anticipated.

## Method Note

This plan executed in a git worktree at
`/Users/damian/Development/damianflynn/selfhost-stacks/.claude/worktrees/agent-a38ffc2ea047406c2`.
The plan's `<verify>` blocks open with `cd "$(git rev-parse --show-toplevel)"`, which inside a
worktree resolves to the **worktree root** — which is correct here, and is where every measurement
was taken. The main checkout does not carry these edits until the wave merges. Same correction plans
06-24 and 06-25 recorded in round 2, for the same reason.

All scratch files lived in `/tmp/p6-32-drive.T18Pzmx9`, minted with `mktemp -d`. Nothing was written
into the repo working tree: `git status --porcelain --untracked-files=all -- scripts/` listed only
`scripts/phase06-incremental-control.sh`.

## What Was Not Touched

- `scripts/phase06-oracle.sh` — it already carries GC-02's predicate. This plan copies the *shape*;
  it does not move the code or alias the two sites.
- Exit codes, sentinels and the `PROBE-RC` / `STATEFILE-SHA` contract, as `06-25` § 5 recorded them.
  The fences narrow; they do not change what either program emits.
- `scripts/setup-neocortex-memory.sh`, `stacks/selfhosted/neocortex-memory/`,
  `stacks/selfhosted/agentic-os/` — out of scope.
- **No requirement checkbox moved. CONF-04 is not closed. The phase is not declared complete.**
- `STATE.md` and `ROADMAP.md` — the orchestrator owns those writes after the wave merges.

## Commits

| Commit | Task | Subject |
|---|---|---|
| `928f9c2` | 1 | widen both in-container traps past the exit pseudo-signal (R3-09) |
| `befe732` | 2 | give both in-container fences GC-02's predicate, and narrow the claim (R3-10) |
| `51bd3a0` | — | this summary |

## Self-Check: PASSED

All three claimed files exist on disk and all three commits are present in this worktree branch's
history. Checked from the worktree root, which is where the work was done.

| Claim | Result |
|---|---|
| `scripts/phase06-incremental-control.sh` | FOUND |
| `.../artifacts/06-32-incremental-trap-fences.txt` | FOUND |
| `.../06-32-SUMMARY.md` | FOUND |
| commit `928f9c2` | FOUND |
| commit `befe732` | FOUND |
| commit `51bd3a0` | FOUND |
