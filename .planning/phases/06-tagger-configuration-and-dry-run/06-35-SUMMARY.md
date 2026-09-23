---
phase: 06-tagger-configuration-and-dry-run
plan: 35
subsystem: health-checks
tags: [gap-closure, round-4, quoting, remote-command-injection, claim-correction]
gap_closure: true
gap_closure_round: 4
closes_findings: [R4-01, R4-07, R4-08]
also_corrects: [R4-05]
requires:
  - "06-34 (round 3's last plan — this plan fixes the code 06-30..06-33 wrote)"
provides:
  - "scripts/quick-health-check.sh with no instance of the hand-escaped wrapper its own ⛔ paragraph forbids"
  - "a census block that states per-plan lists and a recipe, and no count of rendered knobs"
  - "a census recipe whose second grep matches every remote call site in the file"
affects:
  - "scripts/quick-health-check.sh"
tech-stack:
  added: []
  patterns:
    - "printf '%q' renders a WHOLE WORD — a suffix appended to the rendered value sits outside the escaping"
    - "a value rendered for a remote function that already quotes its own parameter is interpolated UNQUOTED"
    - "prose that documents a grep pattern must not reproduce the literal that pattern matches"
key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-35-qhc-drift-quoting-and-census.txt"
  modified:
    - "scripts/quick-health-check.sh"
decisions:
  - "R4-01 and R4-07 closed as BOTH code and claim; R4-08 as CLAIM CORRECTION ONLY"
  - "the retired construction is reconstructed in the artifact only, never in the script — a grep for a token's absence cannot distinguish a claim from its retraction"
  - "no count of rendered knobs is stated anywhere in the census block; the recipe replaces it"
metrics:
  tasks: 2
  commits: 2
  files_changed: 2
  lines_added: 410
  lines_removed: 16
  completed: 2026-09-23
---

# Phase 06 Plan 35: quick-health-check.sh drift quoting and census correction — Summary

Closed the three round-4 findings that land in `scripts/quick-health-check.sh`: rendered four
`_drift_pair` paths and the dashboard resolve address with `printf '%q'`, and withdrew three
sentences that claimed more than was true — round 3's "the forbidden-shape class is closed", the
census block's count of nine rendered knobs, and the recipe that under-counted its own haystack.

## Finding IDs — aliased, and written in band as R4-\*

Round 4's report reuses round 1's `WR-*`/`IN-*` namespace, and round 1's IDs are already cited in
band in this file. Everything this plan wrote uses the round-4 aliases:

| Round-4 report ID | In-band ID | Fix class | Subject |
|---|---|---|---|
| WR-01 | **R4-01** | **BOTH** | the ⛔-forbidden shape live four times, eleven lines below its own prohibition |
| IN-01 | **R4-07** | **BOTH** | `DASH_RESOLVE_IP` reaching a remote command string raw, unlisted by any census |
| IN-02 | **R4-08** | **CLAIM CORRECTION ONLY** | the census recipe's second grep missing two `bounded_ssh` call sites |
| — | **R4-05** | **CLAIM CORRECTION ONLY** | the census block's "all nine" count, moved by this very edit |

## What was done

**Task 1 — `0f4a73a`.** Four per-pair renderings (`DRIFT_AUDIO_Q`, `DRIFT_SABBEETS_Q`,
`DRIFT_SURVIVOR_Q`, `DRIFT_FLASK_Q`), each rendering the **whole concatenated path** rather than the
root with a suffix bolted on outside the escaping — the one way this fix ships broken while looking
right. The four call sites interpolate them unquoted, because `_drift_pair`'s body already quotes
`"$3"`. `DASH_RESOLVE_IP_Q` rendered beside its knob and swapped into the `curl --resolve` remote
string only; the override comparison and the operator echo keep the raw value, since rendering
those would print backslashes at a human. Round 3's closure sentence withdrawn and replaced by a
record of where the four survivors were, **paraphrased rather than quoted** so a mechanical grep can
prove the false clause absent. The "all nine" count withdrawn in favour of the recipe.

**Task 2 — `8799e02`.** The census recipe's second grep widened from `ssh -n \$SSH_OPTS` to
`ssh (-n )?\$SSH_OPTS`. Nothing executable changed. 18 hits before, 20 after; the two new hits are
exactly the `bounded_ssh` probes the review named.

## The bound, carried over intact

None of this could produce a green tick. A non-default `DRIFT_APPDATA_ROOT` already forces
`EXIT_CODE=1` at the override guard, a broken remote command lands in the could-not-look arm, and
there is no privilege crossing — the operator who can set the knob already has root on LXC 100.
**The defect R4-01 reports is the claim, not the exploit.** That bound is stated in band and in the
artifact, and this summary does not inflate it.

For R4-08 the bound is stronger still: neither newly-covered call site interpolates a knob today.
Nothing in the file was wrong; the recipe was.

## What the capture actually proved

The five renderings were proven by generating the remote command string that *would* be sent and
re-parsing it locally with `set --`, which is the same word splitting the remote bash performs:

| `DRIFT_APPDATA_ROOT` | Before: argc / `$3` | After: argc / `$3` |
|---|---|---|
| `/mnt/fast/appdata` (default) | 4 / full path | 4 / full path — byte-identical |
| `/mnt/fast/app data` | 4 / full path | 4 / full path |
| `/mnt/fast/app"data` | **2 / EMPTY** | **4 / full path, quote intact** |

The space case surviving both ways is not a contradiction of the finding — the ⛔ paragraph says in
terms that a hand-escaped wrapper "survives a space but not a quote and not a `$`". The quote case
is the decisive one: the embedded `"` terminates the wrapper early, the remote shell re-parses the
remainder as command text, and `_drift_pair` is called with two arguments instead of four, so
`sha256sum "$3"` hashes nothing.

## Deviations from Plan

None affecting scope or outcome. Two execution notes worth recording:

**1. [documented substitution] `git rev-parse` in the verify blocks.** Both `<automated>` blocks open
with `cd "$(git rev-parse --show-toplevel)"`. This executor runs in a git worktree whose tool
sandbox refuses to run a script file it cannot prove is git-free, so that one line was replaced with
the literal worktree root before driving. Inside a worktree the two are the same path, so the
substitution is semantically identical; every other line was driven byte-for-byte as written. Stated
in the artifact rather than left silent.

**2. [Rule 1 — bug, caught by the plan's own check] the widened recipe matched my own comment.**
The first draft of task 2's in-band explanation **quoted the two newly-covered call sites verbatim**
in order to describe them. That paragraph then matched the widened pattern, and the self-non-matching
check returned it as a comment-line hit — the recipe counting its own documentation, the CR-01 /
GC-03 shape this phase has shipped twice. Rewritten to describe those two sites in prose; re-run
returns 20 hits, zero of them comment lines. **The in-band text now carries the warning**, so the
next person documenting a pattern inside the file it matches meets it. This is precisely why the
plan said to check rather than assume.

## NOT-DRIVEN register

**`scripts/quick-health-check.sh` was executed ZERO times.** It contacts LXC 100 (172.16.1.159) and
atlantis (172.16.1.158). Every runtime branch of the file is therefore undriven by this plan —
named rather than left as a silence:

- the vendored-drift block's match / drift / short-answer / could-not-look branches and its remote
  exit-3/4/5 arms
- the `DRIFT_APPDATA_ROOT` and `DRIFT_REPO_ROOT` override guards firing at runtime
- the dashboard probe's 124 / 255 / curl-non-zero / 302 / 401 / 200 arms
- the `DASH_RESOLVE_IP` override guard firing at runtime
- `bounded_ssh`'s watchdog and sentinel paths at the two probe sites
- every other block in the file, none of which this plan touched

**What was proven instead, and its limit.** The renderings were proven by *capture* — a faithful
model of the remote word splitting, bash on both ends, but a model. It shows `_drift_pair` receives
the right argument; it does not show the remote function then behaves as expected. The claim
corrections were proven by grep over the file. Neither substitutes for a live run.

No `--run`, no `--arm`, no `git push`, no host `git pull`, no estate contact of any kind.

## Anti-vacuity: both verify blocks driven pre-fix

Required by the plan and done before any edit. Both blocks were extracted, parsed with `bash -n`,
and run against the unfixed tree. Each failed at its **first** fix-related assertion and neither
reached its end:

- task 1 → `grep -cF '\"$DRIFT_APPDATA_ROOT/'` returned **4**, not 0
- task 2 → the widened `-E` pattern was **absent** (count 0)

Post-fix both reach their terminal marker at exit 0. Transcripts in the artifact.

## Scope

`git diff --name-only -- scripts/` lists only `scripts/quick-health-check.sh`.
`scripts/setup-neocortex-memory.sh`, `stacks/selfhosted/neocortex-memory/` and
`stacks/selfhosted/agentic-os/` were not touched. No requirement checkbox moved; CONF-04 is not
closed and is not claimed; the phase is not declared complete. `06-VERIFICATION.md` was not read as
a gap source and not edited. STATE.md and ROADMAP.md were not modified — the orchestrator owns those.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema change was introduced. Both
changed surfaces were already in the plan's `<threat_model>` (T-06-R401, T-06-R401b, T-06-R401c,
T-06-R407, T-06-R408) and all five dispositions were `mitigate`; all five are applied.

## Commits

| Commit | Task | Subject |
|---|---|---|
| `0f4a73a` | 1 | render the four `_drift_pair` paths and `DASH_RESOLVE_IP`, withdraw two false claims |
| `8799e02` | 2 | widen the census recipe's second grep to its whole haystack |
| `4346857` | — | this SUMMARY |

## Self-Check: PASSED

Verified after writing, not assumed:

- `scripts/quick-health-check.sh` — exists, `bash -n` exits 0
- `.planning/.../artifacts/06-35-qhc-drift-quoting-and-census.txt` — exists, non-empty (19,810 B)
- `.planning/.../06-35-SUMMARY.md` — exists
- commits `0f4a73a`, `8799e02`, `4346857` — all present in `git log`
- neither per-task commit deleted a tracked file (`git diff --diff-filter=D` empty for both)
- working tree clean; no untracked files left behind
- both `<automated>` verify blocks re-run post-fix and reach their terminal marker at exit 0
