---
phase: 06-tagger-configuration-and-dry-run
plan: 25
subsystem: testing
tags: [bash, dash, mktemp, o-excl, tmpfile-hardening, fail-closed, trap-cleanup, beets, phase06-incremental-control, gap-closure]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "scripts/phase06-incremental-control.sh as plan 06-20 left it — the two-arm CONF-02 negative control, its EXIT CODES block and its RED-vs-UNKNOWN precedence"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-REVIEW-GAP.md findings GC-08 (this plan) and GC-07 (plan 06-27), and the IN-06 row in 06-DISPOSITIONS.md with deferred-items.md DEF-06-21-02"
provides:
  - "No fixed /tmp/p6-* name survives in an executable line of scripts/phase06-incremental-control.sh: the manifest program mints one directory, the taghistory program mints its own program path"
  - "A minting-unavailable REFUSAL in both remote programs — a BLIND line in the local vocabulary and exit 2 (UNKNOWN), with no fallback to the fixed name — driven red in both interpreters with a passing partner"
  - "Cleanup on a trap in both programs, so an early could-not-look exit cannot leak a minted name nobody can guess"
  - "artifacts/06-25-incremental-tempnames.txt: the seven sites with greppable anchors, the measured shared container/user, the measured /tmp writer picture, the ONE threat-model decision plan 06-27 quotes for GC-07, and seven recorded drives"
affects: [06-27, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mint an in-container temp name with mktemp and rely on O_EXCL CREATION, not on the name being secret — the template prefix stays greppable and is not claimed to be a mitigation"
    - "A failed mint is a refusal, never a fallback: a fallback fires precisely when the environment is least trustworthy, and is the original defect wearing a mitigation's label"
    - "Put minted-state cleanup on a trap, not on the success path: once names are minted, a leftover from an early exit is unfindable"
    - "Guard a trap's rm with a `case` re-test of the template prefix, and `${VAR:-}` so it is safe under set -u"
    - "Drive a fail-closed branch by emptying PATH into a stub directory — install nothing, remove nothing from the system"
    - "Answer a threat-model question ONCE in one artifact and have the sibling plan quote it, rather than answering it twice in two files"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-25-incremental-tempnames.txt
  modified:
    - scripts/phase06-incremental-control.sh

key-decisions:
  - "THE IN-06 THREAT-MODEL ANSWER, stated once for both siblings: the threat is real and the treatment is a container-minted name, but the property relied on is mktemp's O_EXCL CREATION, not secrecy. That is precisely why RUN_TAG=\"$$\" was the wrong mechanism for the right threat — a PID is enumerable, it is the WORKSTATION's PID with no relationship to the container's namespace, and it is a label chosen by the writer rather than a name minted by the kernel. Both GC-07 and GC-08 resolve the same way. Recorded in artifacts/06-25-incremental-tempnames.txt § 4 in a form plan 06-27 can quote verbatim."
  - "GC-07's third objection (the step-1 probe is what actually refuses a pre-placed name) is TRUE OF THE ORACLE AND FALSE OF THIS FILE — the incremental control has no such probe over these names. That is why the sibling needed a code change and not only a corrected comment."
  - "Cleanup went onto a trap rather than onto every exit path, because the old rm -f sat only after the last BLIND, so every could-not-look already leaked all three files — and minting makes a leftover unfindable rather than merely untidy."
  - "One minted DIRECTORY for the three manifest files rather than three minted files: one minting rung in the BLIND ladder instead of three, and one thing to clean up."
  - "The POSIX `set -C` fallback was NOT written, because mktemp was MEASURED present (GNU coreutils 9.7) in the container. Shipping an unexercised fallback for a condition that does not hold would have been a second untested path."
  - "The oracle's $SCRATCH (/tmp/p6) and its $$-tagged names were NOT touched here. That is plan 06-27's half; this plan states the answer and does not edit the other file."

metrics:
  duration: ~55m
  completed: 2026-09-22
  tasks: 2
  commits: 3
  files-modified: 1
  files-created: 1
---

# Phase 6 Plan 25: Incremental Control Temp-Name Hardening (GC-08) Summary

Closed GC-08 by minting every in-container scratch name with `mktemp` inside the container — one
directory for the three manifest files, one file for the write-then-execute taghistory program —
with a driven fail-closed refusal and trap cleanup, and settled the IN-06 threat-model question
once, in a form plan 06-27 applies to the oracle's `RUN_TAG` comment.

## What Was Built

**The finding was verified, not assumed.** GC-08 was recorded as UNVERIFIABLE from the diff the
cross-family reviewer was given — evidence not supplied, finding not disputed. Re-checked here
against the pre-fix file at commit `bf509f4`: **the premise holds at all seven sites.** Three
`/tmp/p6-man.*` files written with `>` inside `write_prog_manifest` (pre-fix `:436`, `:442`,
`:444`, read back at `:438`, `:446`, cleaned at `:449`), and `/tmp/p6-taghist.py` written with `>`
at `:474` and **executed by `"$PY"` on the next line** at `:475`. Each is recorded in the artifact
with a greppable anchor as well as its number, because this round shifted lines above them.

**Both instruments do share a container and a user** — measured from the two files' own constants,
not assumed: `CONTAINER="beets-flask"` / `-u beetle` here, `CONTAINER="${CONTAINER:-beets-flask}"`
/ `CONTAINER_USER="${CONTAINER_USER:-beetle}"` in the oracle.

**Who can write that `/tmp`, measured 2026-09-22 (LXC 100 was reachable, so this is not UNKNOWN):**
`/tmp` is mode `1777`; `docker top` shows every process in `beets-flask` other than PID 1 —
redis, the HTTP server, five rq workers and their multiprocessing children — running as **uid 568,
the same uid this instrument execs as**. `fs.protected_symlinks=1` and `fs.protected_regular=2` are
both on, but they only refuse a follow when the pre-placed name belongs to a *different* uid, so
they do not cover this case. `mktemp` is GNU coreutils 9.7 and `/bin/sh` is dash.

**The change.** `write_prog_manifest` mints one directory (`mktemp -d /tmp/p6-mf.XXXXXXXX`) and
places `meta`/`z`/`zs` inside it; `write_prog_taghistory` mints its program path
(`mktemp /tmp/p6-taghist.XXXXXXXX`), writes it, executes *that* path, and removes it. A failed mint
prints a BLIND line in the file's existing vocabulary and exits **2 (UNKNOWN — could-not-look)**,
joining the same ladder as every other blind case. **There is no fallback to the fixed name.**
Cleanup moved onto a trap whose `rm` is gated by a `case` re-test of the template prefix.

The header gained the contract paragraph in the shape the oracle's IN-06 paragraph takes, but with
the true claim rather than the overstated one.

## Key Implementation Details

- **The property is creation, not secrecy.** `/tmp/p6-mf.` and `/tmp/p6-taghist.` remain greppable
  prefixes and the header says so explicitly. `mktemp` creates with `O_EXCL`, so it *fails* rather
  than opening a name that already exists and will not follow a symlink into being. Unpredictability
  is not claimed anywhere, which is the whole substance of GC-07's objection to `$$`.
- **The parse contract is byte-identical.** `PROBE-RC` and `STATEFILE-SHA` are emitted by the same
  two lines in the same order; `MANIFEST-META-BEGIN` / `-END` / `MANIFEST-SHA-BEGIN` / `-END` /
  `MANIFEST OK` are unmoved. No exit code was renumbered — the numbering difference against the
  oracle is a recorded deliberate non-finding.
- **Arms A and B are untouched.** `classify_taghistory` and `classify_reoffer` were not edited, and
  the probe text they consume was not edited. CONF-02 is discharged by those outcomes.

## Verification and the driven branches

`bash -n` parses clean; `--self-test` exits 0 with `all branches behaved as expected` (1
occurrence) at both commits. `git diff --name-only -- scripts/` lists only this file.

Seven drives, all recorded in the artifact with their outputs:

| # | What | Where | Result |
|---|------|-------|--------|
| D1 | manifest, mint unavailable | local `/bin/sh`, empty stub `PATH` | exit **2**, `MANIFEST BLIND could not mint …`, **0** sentinels |
| D2 | taghistory, mint unavailable | local `/bin/sh`, empty stub `PATH` | exit **2**, `TAGHIST BLIND could not mint …`, **0** `PROBE-RC` lines |
| D3 | manifest, mint available | **container dash** | exit 0, all four sentinels + `MANIFEST OK`, 0 BLIND |
| D4 | taghistory, mint available | **container dash** | exit 0, path minted → written → **executed** → removed; `PROBE-RC 0` and `STATEFILE-SHA` present in order |
| D5 | both, mint unavailable | **container dash**, `-e PATH=/nonexistent-stub` | both exit **2** with their BLIND lines |
| D6 | early exit after a successful mint | local, stub with `mktemp` only | exit 2 at `find -printf rc=127`, and the minted dir **was left** — no `rm` on the stub PATH for the trap to call |
| D7 | same, with `rm` added to the stub | local | exit 2, same BLIND line, `ls -d /tmp/p6-mf.*` returns nothing — the trap cleans up on the early exit |

D6 is reported rather than hidden: it is an artefact of the stub, and it is also the honest limit
of the trap — cleanup depends on `rm` being resolvable, which it is in the container.

Container cleanup asserted afterwards: `ls -d /tmp/p6-mf.*` → `NONE-p6-mf`, `ls -d
/tmp/p6-taghist.*` → `NONE-p6-taghist`; `/tmp` holds only the two pre-existing phase-06 leftovers.
The only container writes these drives made were the programs' own minted scratch files.

## NOT-DRIVEN register

| Item | Why not driven | Condition that would drive it |
|------|----------------|-------------------------------|
| **The live two-arm control (`--arm a` / `--arm b`)** | It **imports**, and importing is out of scope for a hardening round. Its observable outcomes (arm A POPULATED / not re-offered, arm B EMPTY / re-offered) are carried by two classifiers and one probe text, none of which this plan edited. | The next real `--arm a` / `--arm b` pair. Also confirm no `/tmp/p6-mf.*` or `/tmp/p6-taghist.*` survives that run. |
| **The minted names under a genuinely concurrent second run** | Nothing here ran two copies of an arm at once. `mktemp`'s O_EXCL makes a collision a refusal rather than a clobber, but that is reasoning, not a measurement. | Two back-to-back or overlapping `--arm` runs; assert neither reuses a minted name and both clean up. |
| **The oracle's `$$`-tagged names (IN-06 / DEF-06-21-02)** | Out of scope here by design — plan 06-27 owns that file. The disposition record stands unedited. | Unchanged: the next real `phase06-oracle.sh --run`, per DEF-06-21-02. |
| **A real adversarial pre-placement in the container's `/tmp`** | Deliberately not attempted. The measurement establishes *reachability of the name*, not a live adversary, and planting a symlink in a running service's `/tmp` is not a safe experiment on this estate. | Would need a throwaway container, not `beets-flask`. |

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 — Blocking] The `<verify>` blocks `cd` to the MAIN CHECKOUT, which does not carry
these edits**
- **Found during:** both tasks. Each `<automated>` block opens with
  `cd /Users/damian/Development/damianflynn/selfhost-stacks`.
- **Issue:** this plan executed in a git worktree. Obeying that line literally would have measured
  the *unmodified* file and reported a green describing nothing.
- **Fix:** every verify command was run from the worktree root instead. All 25 checks across both
  tasks pass there. Recorded in the artifact § 9.
- **Note:** the same defect and the same correction were recorded by plan 06-24 in this round, so
  it is a property of the round's plans rather than a one-off.

**2. [Rule 1 — Bug] The manifest cleanup was success-path-only, which minting would have made
worse**
- **Found during:** Task 2. Pre-fix `:449` — `rm -f` sat after the last BLIND, so *every*
  could-not-look exit already leaked all three fixed files. GC-08 did not name this.
- **Fix:** cleanup moved onto a trap in both programs, gated by a `case` re-test of the template
  prefix. Driven by D6/D7.
- **Why it mattered more after the change:** a fixed leftover is findable by name; a minted one is
  not.

### Plan instructions corrected rather than absorbed

**The plan's own verify checks constrain the template prefixes, which the plan text does not say.**
Task 2 check 1 asserts `grep -cF '/tmp/p6-man'` is `0` on executable lines, so the obvious
templates `/tmp/p6-man.XXXXXX` and `/tmp/p6-manifest.XXXXXX` both **fail it as substrings**. The
prefix used is `/tmp/p6-mf.` for that reason. The conclusion the plan wanted is unaffected; the
naming is noted so a reader does not "restore" the obvious prefix and break the check.

**The plan's task 2(d) says to drive both directions with the local `/bin/sh`.** The fail-closed
half works there, but the *passing partner* cannot: macOS BSD `find` has no `-printf`, so the local
program can only ever reach `MANIFEST BLIND find -printf rc=…`. D3/D4 were therefore driven in the
container, which is the real interpreter anyway, and D5 adds the container-side fail-closed drive
the plan did not ask for. The local drives are kept as D1/D2.

### Authentication gates

None. `ssh root@172.16.1.159` and `docker exec` worked on first use with existing credentials.

## Threat Flags

None. This plan removes surface rather than adding it: it introduces no endpoint, no auth path, no
schema change, and no new file access outside the container's own `/tmp`. Nothing was pushed, no
host pull was requested, and no import was run.

## Known Stubs

None.

## Provenance of the measurements

Workstation: Darwin 27.0.0; `command -v grep` inside a script is `/usr/bin/grep`, `grep (BSD grep,
GNU compatible) 2.6.0-FreeBSD` — recorded because the operator's interactive zsh aliases `grep` to
ugrep, so an interactive re-run may be answered by a different tool. Container: `/bin/sh` →
`/usr/bin/dash`, `mktemp (GNU coreutils) 9.7`. No `printf | grep` pipeline was used for any
measurement in this plan, so the round's `pipefail`/SIGPIPE-141 trap did not arise here.

## Commits

| Commit | Scope |
|--------|-------|
| `871a531` | Task 1 — taghistory mint + refusal + trap; the artifact with the seven sites, the measurements and the shared decision |
| `c908c09` | Task 2 — manifest mint + one BLIND rung + trap; the header contract paragraph |
| (this file) | SUMMARY |
