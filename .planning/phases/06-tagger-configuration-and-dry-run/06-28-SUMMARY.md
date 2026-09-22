---
phase: 06-tagger-configuration-and-dry-run
plan: 28
subsystem: phase-06 instruments and documentation
tags: [gap-closure, round-2, wave-3, citations, anchors, d-04, counts, gc-04, gc-10]
gap_closure: true
gap_closure_round: 2
wave: 3

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "every file-editing plan of rounds 1 and 2 landed (06-22..06-27), so the line numbers this plan repairs have stopped moving"
provides:
  - "no cross-file file:line reference to the sibling instrument or to beets.yaml survives in phase06-oracle.sh or check-beets-config.sh"
  - "beets.md's exemption register keyed on the two alternations of D04_EXEMPT_RE itself, so register and regex cannot drift apart"
  - "a 23-reference citation audit covering all five files this round touched, each resolved and each judgement recorded"
  - "a D-04 counts table that is re-measured, states which figures are pinned, and no longer claims an agreement its own presence invalidates"
  - "the three-point count vector 200/99 -> 202/101 with the pinned 10/8/3/5/2 unmoved throughout"
affects: [06-29, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "an anchor must be UNIQUE, SINGLE-LINE and part of the thing pointed at — verified with grep -c in the target BEFORE being written into the citer, not after"
    - "a grep for the ABSENCE of a token cannot tell a claim from its retraction: quoting a stale number in order to disown it fails the check that removes it"
    - "diffing a line-numbered scan after an edit that shifts line numbers reports ~60 spurious rows; strip the line number and comm the sorted content"
    - "a repository page inside its own detector's scan scope cannot state that detector's unpinned counts — the act of writing them moves them"
    - "spot-checking one of a cited PAIR does not clear the pair: one half had rotted and the other had not"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-28-citations-and-counts.txt
  modified:
    - scripts/phase06-oracle.sh
    - scripts/check-beets-config.sh
    - stacks/selfhosted/arrs/beets.md

key-decisions:
  - "NINE STALE, NOT FOUR. Enumerated all 23 cross-file references in the five files this round touched rather than starting from the review's table. Five of the nine stale references were not named by the review — and one of them (beets.yaml:54-60) had to be fixed for the plan's OWN verify test 2 to pass, so repairing only the named four would have failed the plan"
  - "⚠️ THE PLAN'S INHERITED COUNTS WERE STALE TWICE OVER. beets.md read 191/90; the plan body quoted 199/98. Measured independently at base: 200/99. Confirms 06-23's correction and 06-26's independent reading. Every number in the plan's objective table was re-derived, none trusted"
  - "UNPINNED ROWS DROPPED, NOT RESTATED. The plan offered both shapes and recommended the drop; the drop was taken, and then DEMONSTRATED — this plan's own GC-10 prose moved raw 200->202 in the same commit that removed the figures"
  - "⚠️ THE PLAN'S <verify> BLOCKS cd INTO THE MAIN CHECKOUT. Not obeyed. Every measurement taken from the worktree root via git rev-parse --show-toplevel. Fifth plan this round to record this"
  - "⚠️ A SIXTH WRONG-PREMISE VERIFY CHECK. `grep -cF '2166, 2179, 2313' == 0` fails when the replacement quotes the old numbers to disown them. Resolved honestly — positions moved into the artifact, page describes the rot by magnitude"
  - "quick-health-check.sh NOT EDITED. It carries a ninth stale citation (NEW-06-28-01) but is not in this plan's files_modified and is the one file three plans landed in this round. Reported, not fixed"
  - "NOT pushed and NOT pulled. No estate contact of any kind; this plan is comments and documentation only"

patterns-established:
  - "Key a human-readable register on the MACHINE-READABLE pattern it documents, so the two cannot drift; state the count (which is pinned) rather than positions (which never were)"
  - "Record a citation's before/after position in the audit artifact, not in the page that replaced it — a stale number quoted in its own retraction is still copyable"

requirements-completed: []

# Metrics
duration: 55min
completed: 2026-09-22
---

# Phase 6 Plan 28: Citation Anchors and the D-04 Counts Table — Summary

Every cross-file citation this round's gap closure rests on now points at a greppable anchor proven
to resolve, and `beets.md`'s counts table is re-measured and no longer claims an agreement its own
presence invalidates.

## What Was Done

### Task 1 — GC-04: anchors instead of line numbers — commit `ab5ff32`

The plan's objective carries a four-row table of stale citations and explicitly says **not** to start
from it. Starting instead from a mechanical enumeration of every cross-file `file:line` reference in
the five files this round touched — 23 references — and resolving each by opening the cited line:

| | references | stale | resolves |
|---|---|---|---|
| `scripts/phase06-oracle.sh` | 3 | 3 | — |
| `scripts/check-beets-config.sh` | 7 | 3 | 4 |
| `scripts/quick-health-check.sh` *(audit only)* | 6 | 1 | 5 |
| `scripts/phase06-incremental-control.sh` | 0 | — | — |
| `stacks/selfhosted/arrs/beets.md` | 5 + 2 register rows | 3 | 4 |
| **total** | **23** | **9** | **13** |

**Nine stale, of which the review named four.** The five it did not name are the substance of this
task, because one of them was load-bearing on the plan's own verification:

- **`check-beets-config.sh` → `beets.yaml:54-60`**, cited as *"the LSIO lesson … its `lsiown` half"*.
  Lines 54-60 are the **vendoring rationale**; the word `lsiown` does not appear in them. The lesson
  is at `beets.yaml:73`. This matters beyond accuracy: the plan's verify test 2 requires **zero**
  `beets\.yaml:[0-9]+` references to survive in that file, so repairing only the citation the review
  named would have left the plan failing its own check.
- **`check-beets-config.sh` → `check-music-freeze.sh:191-199`**, cited as `zfs_query()`. That range is
  the `--sidecars` fd-3 redirection block; `zfs_query()` is defined at **209**.
- **`beets.md` → `CLAUDE.md:152` and `.planning/PROJECT.md:187`** for the *"beets has no `undo`
  command"* claim. `CLAUDE.md:152` resolves. `PROJECT.md:187` is about the LXC idmap — the claim is at
  **207**. **Half-rotted**: one of a cited pair still worked, which is exactly what makes this class
  survive a spot-check.
- The two `beets.md` **exemption-register rows**, counted as two repairs.

The four the review did name were all re-derived rather than trusted, and all had moved **again**
since planning:

| citation | plan predicted | actually, at execution |
|---|---|---|
| sibling fences (oracle ×3) | `:387`, `:520` | **414**, **571** |
| oracle's exempt invocations (`beets.md`) | `2478`, `2491`, `2625` | **2781**, **2794**, **2930** |
| sibling's exempt invocations (`beets.md`) | resolved correctly at planning | **502**, **504** (rotted during the round) |

Every anchor was `grep -c`'d in its **target** for uniqueness and the single-line property **before**
being written into the citing file:

| anchor | target | hits | implied |
|---|---|---|---|
| `PREP REFUSED root` | sibling | 1 | ≥1 |
| `CLEANUP REFUSED` | sibling | 1 | ≥1 |
| `$ROOT/overlay.yaml` | sibling | 3 | ≥2 |
| `MIGRATE ITS SCHEMA` | `beets.yaml` | 1 | =1 |
| `lsiown -R abc:abc` | `beets.yaml` | 1 | ≥1 |
| `zfs_query() {` | `check-music-freeze.sh` | 1 | ≥1 |
| `$SCRATCH_OVERLAY` | oracle | 5 | ≥3 |
| ``beets has no `undo` command`` | `CLAUDE.md` / `PROJECT.md` | 1 / 1 | ≥1 each |

Two anchor choices are worth recording. `PREP REFUSED` alone appears **twice** in the sibling (the
fence and a dirty-destination message), so the anchor written in is `PREP REFUSED root`, which is
unique and lands on the fence — the thing actually being pointed at. And the plan's warning about
`MIGRATE ITS SCHEMA` was confirmed rather than inherited: the claim sentence **wraps across two
lines**, so `11 migrations unasked` is not a single-line anchor even though it reads like one.

The **exemption register** was rekeyed on `$SCRATCH_OVERLAY` and `$ROOT/overlay.yaml` — which are
**literally the two alternations of `D04_EXEMPT_RE`**. The register and the regex therefore cannot
drift apart, and the grep that finds the lines is the same test the check applies. Both rows were
replaced, not only the rotted one, so the table cannot half-rot. Counts (3 and 2) replace positions,
because the count is what `D04_EXEMPT_BASELINE` pins; the positions never were.

Thirteen references **resolve correctly and were deliberately left alone**, each judgement recorded
in the artifact rather than omitted. One of them — `beets.md` → `check-music-freeze.sh:824` — already
carries its own drift record (*"`:793` when this row was written"*), and is the single citation in the
set that documents its own rot.

### Task 2 — GC-10: the counts table — commits `64886ab`, `ba810fb`

**The inherited numbers were stale twice over.** `beets.md` read raw 191 / comment-stripped 90; the
plan body quoted 199 / 98. Measured independently at base commit `456ad06`: **200 / 99** — agreeing
with 06-23's post-merge reading and 06-26's independent confirmation. Three agents, three
measurements, one answer.

Both regexes were **extracted** from `scripts/quick-health-check.sh`, never retyped (06-23 widened
`D04_INV_RE` in this same round), with the extraction asserted non-empty *and* unique before use.

The self-invalidating claim — *"hand-reproduced from the host and compared against the block's own
printed figures — agreement at every position, both trees"* — is gone, and the two unpinned rows with
it. The plan recommended dropping them over restating them as a transition. Taking the drop was then
**demonstrated rather than argued**:

| measurement point | raw | stripped | inv / exe / assert / exempt / doc |
|---|---|---|---|
| `456ad06` base | 200 | 99 | **10 / 8 / 3 / 5 / 2** |
| `ab5ff32` after Task 1 | 200 | 99 | **10 / 8 / 3 / 5 / 2** |
| `64886ab` after Task 2 | **202** | **101** | **10 / 8 / 3 / 5 / 2** |

The +2 is **this plan's own prose explaining why the counts are not recorded** — two `beets.md` lines
containing `` `beet`/`BEET*` `` and `BEET[A-Z_]*`. Writing the explanation moved the counts, in the
same commit that removed the figures. That is GC-10's defect reproduced one last time by the fix for
it, and it is the whole case for the drop: a transition written into this page would have been stale
the instant the sentence containing it was finished.

Locating that delta needed care. The edits shifted line numbers in two files, so a naive `diff` of
the line-numbered scan reports ~60 spurious rows; the true delta came from stripping the line number
and `comm`-ing the sorted content. Net effect confirmed as exactly two added `beets.md` lines plus
one reworded `check-beets-config.sh` comment (net zero).

**No pinned figure moved at any point.** The plan's stop-and-report condition did not fire.

## Deviations from Plan

### 1. [Rule 2 — scope widened to close the class] Nine stale citations, not four

The review named four. The enumeration the plan mandates found nine. Fixing four of nine would have
been, in the plan's own words, *"the same defect in a smaller coat"* — and, concretely, would have
left verify test 2 failing, because the unnamed `beets.yaml:54-60` is in the file that test measures.
All nine repaired; the ninth (in `quick-health-check.sh`) reported rather than fixed, see below.

### 2. [Reported, not absorbed] A sixth wrong-premise verify check

`test "$(grep -cF '2166, 2179, 2313' $M)" -eq 0`.

The first draft of the register replacement **quoted** the old line numbers in order to disown them —
correct prose, and a failing check, measured at 1. A grep for the absence of a token cannot
distinguish a claim from its retraction. This is the same trap 06-27 hit with
`grep -ci 'removes the predictability'`, and the **sixth** wrong-premise verify across this round's
seven plans.

Satisfied honestly, not worked around: the before/after positions moved into the artifact (which is
the audit deliverable a reader checks), and `beets.md` now describes the rot by magnitude. The check
passes for the reason it intends — the page presents no stale number anyone can copy. The same
treatment was applied to the `undo`-claim pair for consistency.

### 3. [Reported, not absorbed] The `<verify>` blocks `cd` into the main checkout

Both `<verify>` blocks open with `cd /Users/damian/Development/damianflynn/selfhost-stacks`, which
does not carry this worktree's edits. Obeying it would have measured the unmodified files and
reported a green describing nothing. Not obeyed; every command run from the worktree root resolved
via `git rev-parse --show-toplevel`. Plans 06-24, 06-25, 06-26 and 06-27 recorded the same
correction. **The template is the defect, not the agent.**

### 4. [Reported] The plan's own citation table was stale on arrival

Every one of the plan's predicted positions had moved again by execution — the oracle's exempt
invocations by ~300 further lines than predicted, and the sibling's register row from *correct at
planning* to *rotted*. The plan anticipated this and required re-derivation; recorded because it is
the fourth independent confirmation of `DEF-06-21-08`.

### 5. [Tooling] `grep` is aliased to ugrep

The Bash tool inherits the operator's zsh `grep` → ugrep 7.8.4 alias (`which grep` shows the
function). Every measurement used `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD) by absolute path — what
the shipping scripts use. Regexes were passed with `-f <file>` rather than inline, so the extracted
pattern is never re-quoted through a second shell expansion.

## New Findings for Plan 06-29 to Disposition

### NEW-06-28-01 — `quick-health-check.sh` cites a line number that has rotted

`scripts/quick-health-check.sh` cites `scripts/check-music-freeze.sh:144` for
`TAGGER_CENSUS_PROMOTED=1`. Line 144 is an unrelated comment about the criterion-1 row; the
assignment is at **:160**.

Same class as GC-04, in the one file this plan does not own — `quick-health-check.sh` is not in this
plan's `files_modified`, plan 06-26 owns it this round, and three plans landed in it. Reported rather
than edited, consistent with how 06-26 and 06-27 handled out-of-scope discoveries.

**No functional impact** — nothing asserts on the citation. The replacement anchor is already
verified: `TAGGER_CENSUS_PROMOTED=1` is 1 hit in the target, so the assignment is its own anchor.

### Carried from wave 2, not this plan's to write

`deferred-items.md` was **not** touched — plan 06-29 owns it. Recorded here so they are not lost:
NEW-06-26-01 (the D-04 no-sentinel arm naming a path it may not have visited), DEF-06-21-02's
description drift corrected in band by 06-27, the 23 lines / 24 pipelines of `printf … | grep -q`
SIGPIPE-141 shape from 06-22, and 06-24's latent verify conflict over the oracle's three fence copies.

## Verification Results

All checks run **from the worktree root**, with `/usr/bin/grep`.

| check | result |
|---|---|
| `bash -n` both scripts | PASS |
| `phase06-oracle.sh --self-test` | PASS — exit 0, **134 cases** (unchanged from 06-24/06-27) |
| `check-beets-config.sh --self-test` | PASS — exit 0, **7 cases** (6 red) |
| `incremental-control.sh:343` / `:473` in oracle (==0) | PASS — 0 / 0 |
| `beets.yaml:71-78` in check-beets-config (==0) | PASS — 0 |
| `2166, 2179, 2313` in beets.md (==0) | PASS — 0 *(after Deviation 2)* |
| `(sibling|beets.yaml):[0-9]+` in oracle / cbc (==0) | PASS — 0 / 0 |
| anchors present at citing sites | PASS — 1 / 3 / 1 / 1 |
| anchors resolve in target files | PASS — 2 / 1 / 1 / 5 / 3 |
| `| raw | 191 |` and `| comment-stripped | 90 |` gone | PASS — 0 / 0 |
| `agreement at every position, both trees` gone | PASS — 0 |
| `invocation-shaped` / `D04_DOC_BASELINE` / `GC-10` survive | PASS — 4 / 1 / 2 |
| pinned vector after **every** commit | PASS — 10 / 8 / 3 / 5 / 2 throughout |
| raw / comment-stripped movement attributed by content | PASS — +2, both this plan's own prose |
| artifact non-empty, names GC-04 / GC-10 / 06-23 | PASS — 5 / 8 / 7 |
| `git diff --name-only 456ad06 HEAD` | PASS — exactly the 4 files in `files_modified` |
| `git diff --diff-filter=D` vs base | PASS — **no file deleted** |
| `06-REVIEW-GAP.md` / `06-REVIEW.md` edited | PASS — not touched |
| `STATE.md` / `ROADMAP.md` / `deferred-items.md` touched | PASS — none |
| no `git push`, no host pull, no estate contact | PASS |

## NOT-DRIVEN Register

Stated rather than implied, per this phase's convention.

| item | why it was not driven |
|---|---|
| The **live** D-04 block against the estate | It reads the **host's** HEAD at `/mnt/fast/stacks`, and the host is at pre-Phase-6 `c67d497`. Deploying unmerged Phase 6 to make a check line up is out of bounds — a recorded deliberate non-finding. The count vector was measured against this worktree's HEAD with the block's own pipeline instead. |
| The anchors being **used** by a human | The mechanical claim — each anchor is unique, single-line, and present in the file named — is what was measured. That a reader finds them more durable than a line number is the design argument, not a measurement. |
| The repaired comments changing any **behaviour** | They cannot: every edit in `phase06-oracle.sh` and `check-beets-config.sh` is inside a `#` comment. Both self-tests exit 0 with unchanged case counts (134, 7), which is the check that would catch an accidental non-comment edit — and it is the check that caught one in 06-27. |
| `check-music-freeze.sh`, `check-music-consumers.sh`, `quick-health-check.sh` | Read for citation resolution, never edited. Their own self-tests were not re-run; nothing in them changed. |
| The **thirteen** correctly-resolving citations re-checked at any later commit | Resolved once, at this plan's base. They are line numbers and will rot again — which is the argument for anchoring them in a future plan, and is why each was recorded rather than silently passed over. |

## What This Does NOT Claim

It does **not** discharge any ROADMAP entry criterion and does **not** close **CONF-04**. It does not
touch `scripts/quick-health-check.sh`, `scripts/phase06-incremental-control.sh`, `06-REVIEW-GAP.md`
or `06-REVIEW.md`. It does not claim the thirteen surviving `file:line` references are durable — only
that they resolve **today**, which is precisely the property that expires. And it does not claim the
estate is healthy: no estate contact was made at all.

## Commits

| commit | task |
|---|---|
| `ab5ff32` | Task 1 — the 23-reference enumeration, nine anchors proven and written, the audit artifact |
| `64886ab` | Task 2 — the re-measured counts table, the unpinned rows dropped, the self-invalidating claim removed |
| `ba810fb` | Task 2 — the three-point count vector, the content-compared delta, the verification transcript |

## Self-Check: PASSED

- `scripts/phase06-oracle.sh` — FOUND
- `scripts/check-beets-config.sh` — FOUND
- `stacks/selfhosted/arrs/beets.md` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-28-citations-and-counts.txt` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/06-28-SUMMARY.md` — FOUND
- commits `ab5ff32`, `64886ab`, `ba810fb` — all present in `git log 456ad06..HEAD`
- `git diff --name-only 456ad06 HEAD` returns exactly the four files in `files_modified`
- `git diff --diff-filter=D --name-only 456ad06 HEAD` returns **nothing** — no file deleted
- working tree clean; no shared orchestrator artifacts (STATE.md, ROADMAP.md, deferred-items.md) touched
