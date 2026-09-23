---
phase: 06-tagger-configuration-and-dry-run
plan: 30
subsystem: phase-06 instruments
tags: [gap-closure, round-3, wave-14, quoting, remote-command-strings, census, exit-code-notices, r3-01, r3-05]
gap_closure: true
gap_closure_round: 3
wave: 14

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "round 2's plans 06-22..06-28 landed and 06-29 dispositioned them, so GC-17's census sentence and the thirteenth notice's counts are both at the state the round-3 review measured"
provides:
  - "every overridable knob in quick-health-check.sh that crosses into a remote command string is rendered once with printf '%q', nine renderings in all"
  - "the EXTCONF_PATH value reaches the sabnzbd container as a POSITIONAL PARAMETER of sh -c, so it is never parsed as command text"
  - "the construction GC-17's own prohibition forbids appears nowhere in quick-health-check.sh, including in prose describing its removal"
  - "GC-17's census is a recipe plus a named per-plan list, not a number grep contradicts"
  - "the thirteenth exit-code notice no longer asserts a constant delta; it carries two recipes written so they do not count themselves"
affects: [06-31, 06-32, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "printf '%q' is correct for a bash WORD and WRONG inside the TEXT of a single-quoted remote program — a path crossing into `sh -c` must be a positional parameter, not an interpolation"
    - "render the _Q form beside the knob DEFINITION, never at the use site: a knob with two remote sites (MUSIC_UNDERSCORE_ROOT) proves why"
    - "a self-counting recipe written in band must bracket its own final letter (`CHANGE[D]`) so the recipe is not an occurrence of the thing it measures"
    - "a census that states a NUMBER goes stale silently; a census that states a RECIPE cannot"
    - "do not paste a retired construction into a comment disowning it — a claim and its retraction are indistinguishable to grep, so the mechanical check for its absence can never return zero"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-30-qhc-census-and-counts.txt
  modified:
    - scripts/quick-health-check.sh

key-decisions:
  - "R3-01 executed as BOTH halves, as the plan required: five knobs widened AND the census sentence corrected. Neither half alone closes it — rendering the knobs while leaving 'FOUR such sites' in place would have left a comment that grep contradicts, and correcting the sentence alone would have left the forbidden shape at the EXTCONF site"
  - "THE EXTCONF SITE CHANGED SHAPE, NOT JUST GAINED A _Q — and the capture shows why a _Q alone would have been a half-measure. Driven with `/config/x\";cat /etc/hostname;#`, the pre-change program text parses as TWO commands to the container's /bin/sh. %q renders for a bash WORD; that value landed inside the TEXT of a single-quoted program, the one context %q is not correct for"
  - "THE RETIRED LITERAL IS NOWHERE IN THE FILE, not even quoted in a comment describing what was removed. The shape is described in prose and the literal reconstructed in the artifact instead. This is 06-28's lesson applied on purpose: a grep for the absence of a token cannot tell a claim from its retraction"
  - "R3-05 executed as a CLAIM CORRECTION ONLY, as the plan required. No behaviour change, no code move, no fourteenth notice. Widening anything to make the old number true would have been the exact inversion this round was called to stop"
  - "THE RAW COUNT IS NOT RE-PINNED. The review offered 'raw 15 -> 17' as an option; the drop was taken instead, because this is the third drift of these counts. The header count is stated as the durable one and the raw count as deliberately unpinned"
  - "⚠️ THE PLAN'S <verify> BLOCKS `cd \"$(git rev-parse --show-toplevel)\"`. Every measurement was taken from the worktree root instead. This is now the sixth plan across rounds 2 and 3 to record it"
  - "quick-health-check.sh WAS NOT RUN, not once. Every drive is a captured command string produced by echo. No ssh, no docker, no find, no git pull, no git push, no estate contact of any kind"
  - "CONF-04 is NOT closed, no requirement checkbox moved, and the phase is not declared complete"

patterns-established:
  - "A knob rendered beside its definition rather than its use site cannot be picked up raw by a second future use — stated once at each of the five new renderings"
  - "Replace an in-band count with an in-band RECIPE, and bracket the recipe so it excludes itself; say in one clause why, because the next reader will otherwise unbracket it"

requirements-completed: []

# Metrics
duration: 40min
completed: 2026-09-23
---

# Phase 6 Plan 30: GC-17's Census and the Thirteenth Notice's Delta — Summary

Two round-2 claims in `scripts/quick-health-check.sh` that grep contradicted are now either true or
replaced by a recipe, and the one surviving site using the construction that file's own prohibition
forbids passes its path to the remote shell as a positional parameter instead.

## What Was Done

### Task 1 — R3-01: finish the census, and fix the site it missed — commit `55a2db3`

**Disposition: a CODE WIDENING *and* a CLAIM CORRECTION.** Both halves, because neither alone closes
the finding.

**(a) Five new `printf '%q'` renderings**, each sited immediately below its knob definition and not
at the use site, taking the file from four to nine:

| knob | definition | remote site(s) |
|---|---|---|
| `D03_FLASK_CONTAINER` | ENV OVERRIDES for the D-03 mount assertion | `docker inspect … --format` |
| `D03_CLI_COMPOSE` | same block | `docker compose … -f … config` |
| `D03_CLI_PROFILE` | same block | `docker compose --profile … config` |
| `MUSIC_UNDERSCORE_ROOT` | library underscore-dir guard | `find … -type d -name '_*'` — **two** sites |
| `EXTCONF_PATH` | ENV OVERRIDES for the extended.conf block | `docker exec sabnzbd sh -c …` |

`MUSIC_UNDERSCORE_ROOT` is the one that justifies the siting rule out loud: it has **two** remote
sites, so a rendering written at either use site would leave the other raw.

**(b) The four straightforward sites** now interpolate only the rendered form. Every
override-detection comparison (`[ "$EXTCONF_PATH" != … ]`, `[ "$MUSIC_UNDERSCORE_ROOT" != … ]`) and
every operator-facing `echo` still reads the **raw** value — quoting those would print backslashes
at a human.

**(c) The EXTCONF site changed shape.** It now reads:

```
_ec=\$(timeout $REMOTE_TIMEOUT docker exec sabnzbd sh -c 'cat \"\$1\"' sh $EXTCONF_PATH_Q 2>/dev/null)
```

Traced with the default value (capture only, nothing sent), the remote bash word-splits the
invocation into `[docker] [exec] [sabnzbd] [sh] [-c] [cat "$1"] [sh] [/config/extended.conf]` — the
program text carries no path, and the value arrives as `$1` inside the container's `sh`. Behaviour at
the default is identical to before.

**Why a `_Q` alone would have been a half-measure**, which the capture shows rather than argues.
Driven with `EXTCONF_PATH=/config/x";cat /etc/hostname;#`, the **pre-change** program text is:

```
cat "/config/x";cat /etc/hostname;#"
```

— two commands to the container's `/bin/sh`, not one path. `%q` renders for a bash *word*; this value
landed inside the *text* of a single-quoted program, the one context `%q` is not correct for. Only the
positional form removes the path from the program text.

**The retired literal is nowhere in the file.** Not at the site, not in the comment describing its
removal. The shape is described in prose (*"a hand-escaped `\"` wrapper around the path variable,
inside a single-quoted remote `sh -c`"*) and the literal is reconstructed only in the artifact. This
is deliberate and is 06-28's lesson applied on purpose: a grep for a token's absence cannot tell a
claim from its retraction.

**(d) The census sentence.** `There are FOUR such sites in this file and they were all raw` is gone.
In its place: the named list of the four sites plan 06-26 owned, the named list of the five plan 06-30
owned, an explicit warning that neither list is a current total, and the recipe to re-derive the
census —

```
/usr/bin/grep -nE '^[A-Z0-9_]+="\$\{[A-Z0-9_]+:-' scripts/quick-health-check.sh
/usr/bin/grep -n 'ssh -n \$SSH_OPTS'                scripts/quick-health-check.sh
```

The prohibition paragraph is **unchanged** and gains one clause recording that a documented-forbidden
instance survived a full round three hundred lines beneath it — which is precisely why the census is
now a recipe: the prohibition was never the weak part.

**The bound is kept and not inflated**, as the plan insisted: all nine are ADDITIVE knobs that cannot
produce a green tick, every default contains no spaces, and the `EXTCONF_PATH` injection consequence
is static reasoning that was **never executed**.

### Task 2 — R3-05: retract the stale delta — commit `82f4713`

**Disposition: a CLAIM CORRECTION ONLY.** No behaviour change, no code move, no fourteenth notice.

The thirteenth notice stated, as a measurement across its own edit, `headers 12 -> 13`,
`raw 15 -> 16` and a constant delta of three. Measured at base: headers **13**, raw **17**, delta
**four**. The header half was right; the raw half was invalidated later in the same round by plan
06-26's tail repair — the line saying a new notice was deliberately *not* added, which in saying so
added one raw match.

The three lines are replaced by:

1. a record that the counts were honest when taken and were invalidated within the same round, and
   that this is the **third** drift of these two numbers;
2. the statement that the **header count is durable** and the raw count is **deliberately unpinned**,
   for the reason `06-DISPOSITIONS-GAP.md` gives for the D-04 raw counts — a number written into a
   file that greps itself moves that number;
3. both recipes, with the shared phrase written as `EXIT-CODE BEHAVIOUR CHANGE[D]` — a valid grep
   pattern that matches every real occurrence while the recipe lines are not themselves occurrences —
   and one clause saying why, so nobody unbrackets it.

**The review offered `raw 15 -> 17` as an option; the drop was taken instead.** Re-pinning a number
that has drifted three times would have set the fourteenth notice's author up for the fourth drift.

**No fourteenth notice was added, and that omission is recorded as a decision** in the same paragraph:
this plan changes no exit code, no block count and no condition, and the notice series exists for
behaviour changes, not for corrections to its own arithmetic.

**Left alone, deliberately, and labelled in band:** the three earlier instances of the withdrawn
sentence (dated historical records, each accurate as of its own edit, none re-measured), and the
condition-letter paragraph, which the review independently re-verified as correct and which is
byte-unchanged.

## Measurements

All greps with `/usr/bin/grep` by absolute path — the operator's zsh aliases `grep` to `ugrep`.

| measurement | before | after |
|---|---|---|
| `_Q=$(printf` renderings | 4 | **9** |
| notice **headers** (`^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]`) | 13 | **13** — unmoved |
| notice **raw** (`EXIT-CODE BEHAVIOUR CHANGE[D]`) | 17 | **17** — unmoved |
| the withdrawn constant-delta sentence | 4 | **3** |
| `There are FOUR such sites in this` | 1 | **0** |
| the retired hand-escaped wrapper literal | 1 | **0** |
| `find $MUSIC_UNDERSCORE_ROOT_Q` sites | 0 | **2** |

The raw count did not move because the in-band recipes use the bracketed form — the brackets
demonstrated, not merely argued.

## Deviations from Plan

**None of substance.** Both tasks executed as written, both `<verify>` blocks pass in full, and
`bash -n scripts/quick-health-check.sh` parses clean after each.

One procedural note, recorded because it now recurs: the plan's `<verify>` blocks open with
`cd "$(git rev-parse --show-toplevel)"`, which in a worktree would target the worktree root but is
written as if for the main checkout. Every measurement was taken from the worktree root directly.
This is the sixth plan across rounds 2 and 3 to record it.

## NOT-DRIVEN REGISTER

**`scripts/quick-health-check.sh` was executed ZERO times by this plan.** It contacts LXC 100
(`172.16.1.159`) and the Proxmox host atlantis (`172.16.1.158`), and the plan forbids driving it
against the live estate. Everything below is therefore **unexecuted**, and the changes are asserted by
static trace and by capture only.

| not driven | what would drive it | why not driven here |
|---|---|---|
| the vendored-file drift comparison and all of its arms | a live run against LXC 100 | estate contact; untouched by this plan in any case |
| the D-03 mount assertion — `docker inspect` mount lines, every UNKNOWN arm, the `exit 3` `cd` failure | a live run against LXC 100 | estate contact. **`D03_FLASK_CONTAINER_Q` is asserted by capture, not by a `docker inspect` that ran** |
| the D-03 CLI render — `docker compose … config`, its could-not-look arms | a live run against LXC 100 | estate contact. **`D03_CLI_PROFILE_Q` / `D03_CLI_COMPOSE_Q` asserted by capture** |
| the library underscore-dir guard — the counting scan, the 124 arm, the could-not-look arm, the offending-paths listing, the green tick | a live run against atlantis | estate contact. **`MUSIC_UNDERSCORE_ROOT_Q` asserted by capture at both sites** |
| the extended.conf destructive-switch block — remote exits 3 / 4 / 6 / 124, the `requireBeetsMatch` verdict, the `ConversionFormat` verdict, the parser | a live run against LXC 100 | estate contact. **The reshaped `sh -c` line is asserted by word-split trace, not by a `docker exec` that ran.** The consumer (the `extended.conf` parse) is unchanged and out of scope |
| the D-04 throwaway-`-l` scan and every condition in its ladder, including P | a live run against LXC 100 | estate contact; untouched by this plan |
| the Traefik/Authelia probes, the dashboard probe, the container counts, the image-drift block, the music-freeze harness, the consumers fold-in, the transcode retention audit | a live run | estate contact; untouched by this plan |
| the `EXIT_CODE=1` path and the failure tail | any red verdict from the above | nothing ran, so nothing reached it |

**What *was* proven, and by what means:**

- **By execution:** `bash -n scripts/quick-health-check.sh` (parses clean), and every `test` in both
  `<verify>` blocks.
- **By capture (echo, never sent):** the before/after remote command string for each of the five
  knobs, driven with a space-bearing value and — for `EXTCONF_PATH` — additionally with a
  quote-bearing one, plus the local word-split showing the space surviving as a single word.
- **By static trace:** the default-value `docker exec` line, split into its eight words, showing the
  container's `sh` receives program text `cat "$1"` with `$1 = /config/extended.conf`.

**Not proven, and stated so it is not read as proven:** that the five reshaped remote sites behave
correctly *on the wire*. The capture reproduces the remote shell's parse locally; it does not
substitute for a live run. The default values are unchanged in every case, and all five knobs are
additive and force `EXIT_CODE=1` when non-default, which bounds the exposure of that gap.

## Scope Held

- `git diff --name-only` across both commits lists exactly two paths:
  `scripts/quick-health-check.sh` and the new artifact.
- No file deleted by either commit (`git diff --diff-filter=D` empty both times).
- `scripts/setup-neocortex-memory.sh`, `stacks/selfhosted/neocortex-memory/` and
  `stacks/selfhosted/agentic-os/` untouched — other sessions commit to `main` in this same checkout.
- No `--run`, no `--arm`, no `git push`, no host `git pull`.
- No requirement checkbox moved. **CONF-04 is not closed. The phase is not declared complete.**

## Known Stubs

None. This plan adds no new code path, no placeholder value and no unwired component; it narrows the
quoting of five existing interpolations and corrects two in-band claims.

## Self-Check: PASSED

- `scripts/quick-health-check.sh` — FOUND, modified, parses clean.
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-30-qhc-census-and-counts.txt` —
  FOUND, 199 lines, carries `R3-01`, `R3-05` and `EXTCONF_PATH`.
- Commit `55a2db3` — FOUND.
- Commit `82f4713` — FOUND.
- Both `<verify>` blocks re-run at final state: all assertions pass.
