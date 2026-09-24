---
phase: 06-tagger-configuration-and-dry-run
plan: 49
subsystem: docs
tags: [r6-04, r6-03b, r6-02, in-01, wr-03, wr-02, conventions, gsd-marker-contract, mirror-correspondence, control-drive, round-6]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-REVIEW.md` § IN-01 — `CLAUDE.md` states conventions as unestablished while the six reviewed scripts enforce several load-bearing ones; and § WR-03 fix option (b), a conventions entry naming the pinned-count pattern once"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-46 — the remediation text on BOTH pinned-count fail arms of `check-music-freeze.sh` (`DECLARED_INTERP_EXPECTED` and `TAGGER_DEF_EXPECTED`), which is the pinned-count convention's canonical example"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`deferred-items.md` § DEF-06-48-02 — the DECIDED scope of the bracketing convention (stays `artifacts/`, scoped by function not directory name, not widened to `ROADMAP.md`, not dropped) and § DEF-06-48-01's `-cE`-never-`-cF` rule"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`deferred-items.md` § DEF-06-45-04 — drive a zero-expecting recipe against a control first; § DEF-06-39-01 — per-round ID namespaces; § DEF-06-39-02 — the three refusals including the absent cleanup trap; § DEF-06-29-03 — the fence-site-count trap"
provides:
  - "`CONVENTIONS.md` — the repository's authoritative conventions index, 319 lines, 13 sections, each with a named canonical example (file plus symbol, never a line number)"
  - "`CLAUDE.md`'s `GSD:conventions` block — a names-only mirror of `CONVENTIONS.md`, proven by ordered name-for-name correspondence"
affects: [round-6-r6-04, round-6-r6-03b, round-6-r6-02, 06-50-dispositions-gap4, every-future-contributor-and-agent]

tech-stack:
  added: []
  patterns:
    - "A generated block's marker names its own source; when the source does not exist, the deliverable is the SOURCE and the block is its mirror — write both, make only one authoritative, and say in the file which one that is"
    - "A mirror is a CORRESPONDENCE, not a quota: assert equal cardinality and index-wise containment between the two ordered lists, and drive the comparator red against a mutated list first, because a `>= N` floor is satisfiable by N wrong names"
    - "Illustrate a rule with an example that OBEYS it; where the codebase carries a counter-example, name it as a stated exception in the same entry and say plainly that policy is weaker than mechanism"
    - "Re-measure every number quoted from an upstream document before writing it down — the review's 1,223 lines for `check-beets-config.sh` measures 1,222 today, and the measured figure is the one that ships"
    - "Assert diff confinement to a marked span by comparing the text OUTSIDE the span byte-for-byte on both sides at the correct offsets, not by trusting the hunk header alone"

key-files:
  created:
    - "CONVENTIONS.md"
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-49-SUMMARY.md"
  modified:
    - "CLAUDE.md"

key-decisions:
  - "THE AUTHORITATIVE DELIVERABLE IS A NEW ROOT-LEVEL `CONVENTIONS.md`, NOT A LONGER `CLAUDE.md` BLOCK. The GSD marker names its own source (`GSD:conventions-start source:CONVENTIONS.md`) and that file did not exist. Writing the index into the generated block alone would have made the next regeneration either overwrite it or orphan it. `CONVENTIONS.md`'s opening paragraph states which file wins, which also resolves the review's own confused reading that 'the repo's own CONVENTIONS.md is currently empty'."
  - "CONVENTION 4'S CANONICAL EXAMPLE IS THE `_Q` OVERRIDE GUARDS IN `quick-health-check.sh`, NOT `DECLARED_INTERP_EXPECTED`. The guards force `EXIT_CODE=1` unconditionally when a knob moves off its default, so a knob can only ever redden — the rule enforced by MECHANISM. `DECLARED_INTERP_EXPECTED` appears in the same entry under an explicit exception clause, quoting its own header's 'a red to a green BY DECLARATION — it resolves nothing', naming 06-46's remediation prohibition as the governing control, and stating in one clause that a rule enforced by policy is weaker than one enforced by mechanism. Citing the counter-example as the exemplar would have made the conventions file contradict the source it cites."
  - "NO SCRIPT, NO PLANNING DOCUMENT AND NO `ARCHITECTURE.md`. The `## Architecture` half of IN-01 is dispositioned ACCEPTED in `06-50`; a stub would add a fifth, emptier front door to an estate already mapped by `NETWORK.md`, `MEDIA.md`, `DEPLOYMENT.md` and `TAILSCALE.md`. `git diff --exit-code HEAD -- scripts/` returns 0 at both task commits and `test ! -e ARCHITECTURE.md` succeeds."
  - "THE NAMESPACE ENTRY IS WRITTEN AS A FORWARD POINTER, NOT AS A PRESENT-TENSE FACT. `06-DISPOSITIONS-GAP4.md` does not exist yet — plan `06-50` writes it at wave 3, after this plan at wave 2. The entry says 'will live in', names 06-50 as its author, and states why: a conventions file asserting a future artifact in the present tense is stale the moment that plan changes shape or halts."
  - "THE MIRROR IS PROVEN BY ORDERED CORRESPONDENCE AND THE COMPARATOR WAS DRIVEN RED. `|A| == |B| == 13` and `B[i]` contains `A[i]` for every `i`. The same loop run against a list with entry 3 mutated to 'Assert, and also report' FAILED at index 3, so the green is evidence rather than a loop that cannot fail."

metrics:
  duration: "~35 min"
  completed: "2026-09-24"
  tasks: 2
  commits: 2
  files_created: 1
  files_modified: 1
  estate_contact: "none — zero ssh, zero docker, zero HTTP, zero package installs"
---

# Phase 06 Plan 49: Conventions Index and Its Generated Mirror — Summary

`CLAUDE.md` said "Conventions not yet established" while the six reviewed scripts enforced a dozen
load-bearing conventions nowhere a contributor would look; the repository now has a 319-line
authoritative `CONVENTIONS.md` whose every entry names a canonical example that was read before it
was written down, and a `CLAUDE.md` block that mirrors it name for name and in order.

## What Was Built

**Task 1 — `CONVENTIONS.md` (new, 319 lines, 13 `## ` sections), commit `0d9c6f2`.**

The file opens by stating that it is authoritative and that `CLAUDE.md`'s `## Conventions` block is
its generated mirror — which is the answer to the review's own confused reading that "the repo's own
`CONVENTIONS.md` is currently empty". It did not exist. The GSD marker in `CLAUDE.md` names it as a
source, so the source is the deliverable and the block is downstream of it.

The thirteen entries, each a rule plus a reason plus a **named canonical example by file and symbol,
never a line number**:

| # | Convention | Canonical example |
|---|---|---|
| 1 | Fail closed; "could not look" ≠ "nothing is wrong" | `check-music-consumers.sh`'s `EXIT-CODE CONVENTION` header and its `exit 3` pending state |
| 2 | Bound remote commands Linux-side | `quick-health-check.sh`'s `bounded_ssh`, with its KNOWN LIMIT paragraph |
| 3 | Assert, do not report | the named-pair tagger census in `check-music-freeze.sh` |
| 4 | `${VAR:-default}` overrides are additive only | the `_Q` override guards in `quick-health-check.sh` — **plus a named exception**, below |
| 5 | Pinned counts: the trap and the remedy | all four live pins by symbol, plus the oracle's skip-aware decrements |
| 6 | The two-layer fence is duplicated on purpose | `phase06-oracle.sh`'s three fence texts and `phase06-incremental-control.sh`'s trap re-check |
| 7 | Credentials never enter argv | `check-music-consumers.sh`'s `-H @<(printf …)` in `jellyfin_api` / `ma_api` |
| 8 | Counted tokens are written bracketed | `quick-health-check.sh`'s two census recipes; scope per `DEF-06-48-02` |
| 9 | Grep hygiene | `/usr/bin/grep` by absolute path; the comment-stripped recipe |
| 10 | Byte-identity anchors to a commit, never the index | plan `06-48`'s base-commit treatment of `06-43-conf04-verdict.txt` |
| 11 | The `📊 N. Summary` heading is a cross-file grep anchor | `quick-health-check.sh`'s fold-in extractions and their anchor guards |
| 12 | Durable rationale stays in band; round history goes to the phase directory | measured line counts, below |
| 13 | Review ID namespaces are unique per round | `DEF-06-39-01`; this round is `R6-01 … R6-09` |

**Task 2 — `CLAUDE.md`'s `GSD:conventions` block, commit `51ca680`.** One paragraph naming
`CONVENTIONS.md` as authoritative, then thirteen names-only lines, one per `## ` heading, in file
order. Both marker lines preserved byte-identical. 16 insertions, 1 deletion, a single hunk.

## The Three Things Worth Reading Before Anything Else

### 1. Convention 4 cites a knob that obeys the rule, and names the one that does not as an exception

This is the plan's whole discipline in one entry, and getting it backwards would have shipped exactly
the "docs describe intent, not reality" defect this repository has already recorded.

The **redder-only rule** is enforced by **mechanism** in `quick-health-check.sh`: each override guard
is a comparison against the default that prints *"override in effect — this run cannot report … green"*
and sets `EXIT_CODE=1` **unconditionally**, so setting a knob can only move the run toward red. There
is deliberately no success-producing override and no skip sentinel anywhere in the file. That is the
canonical example, and it is what the entry illustrates.

`DECLARED_INTERP_EXPECTED` in `check-music-freeze.sh` does **not** obey the rule mechanically, and its
own constant header says so in terms the entry quotes verbatim:

> *"It can only ever move a green to a red or a red to a green BY DECLARATION — it resolves nothing
> and can never make an unparsed line parsed."*

The entry states all three consequences rather than leaving any implied: the capability is
**documented and accepted** (not a hidden bypass, not a new defect — the header argues at length why
a pinned inventory beats a permanently red check, which is the 01-09 trap); what governs it is
therefore **policy, not mechanism**, specifically plan 06-46's remediation text which the failure arm
now prints; and **a rule enforced by policy is weaker than one enforced by mechanism**, stated in one
clause rather than presenting the two as equivalent. The entry closes with an explicit instruction not
to cite it as the exemplar.

### 2. The mirror is an ordered correspondence, and the comparator was driven red first

A `>= 8` floor is satisfiable by eight **wrong** names, which is precisely how a mirror goes quietly
stale while passing its own check. So the assertion is: extract `CONVENTIONS.md`'s `## ` heading texts
in file order into list A; extract the `- ` lines strictly between the two `CLAUDE.md` markers in file
order into list B; assert `|A| == |B|` and that `B[i]` contains `A[i]` for every index *i*.

```
|A| = 13   |B| = 13
[1] … [13] OK — B[i] contains A[i]
MIRROR: ordered name-for-name correspondence HOLDS
```

**Then the comparator was driven red**, because a loop that always says OK proves nothing: running the
identical loop against a copy of B with entry 3 mutated from `Assert, do not report` to
`Assert, and also report` failed at index 3 and reported the mismatch. The green above is therefore
evidence that the lists correspond, not evidence that the comparator cannot tell.

### 3. Four zero-expecting counts, every one DRIVEN against a control first (`DEF-06-45-04` class)

A `0` from a recipe that cannot detect is indistinguishable from a `0` that means clean. Every
zero-expecting screen this plan publishes was first observed returning non-zero against a control
built to make it fire. Controls lived in the session scratch directory, outside the repository, and
none was staged.

| Screen | Control drive | Measured on the real file |
|---|---|---|
| line citations `-cE '\.(sh\|md\|yaml):[0-9]+'` | **1** against a control line naming a script with a line number | **0** on `CONVENTIONS.md` |
| forbidden mode `-cE 'Full[R]efresh'` | **1** against a control carrying the real unbracketed token | **0** on `CONVENTIONS.md` |
| the same needle with `-cF` | **0** against the same control — re-confirming `DEF-06-48-01`: `-F` and a bracketed needle are mutually exclusive | (not used as a screen) |
| UI-option token `-ciE 'replace all [m]etadata'` | **1** against a control carrying the real phrase | **0** on `CONVENTIONS.md` |
| `Conventions not yet established` | **1** against `git show <base>:CLAUDE.md`, which still carries it | **0** on `CLAUDE.md` |

The `-cF` row is recorded even though it screens nothing here: it is the second independent
re-drive of `DEF-06-48-01`'s finding, and it costs one line to state.

## Measurements

All taken **after** the edits landed, never before — a sentence stating a number in a file that greps
itself is an occurrence of what it measures (`DEF-06-39-06`, seven rounds running). Every `grep` by
absolute path, because the operator's zsh aliases `grep` to `ugrep`.

**`CONVENTIONS.md`:**

| Assertion | Required | Measured |
|---|---|---|
| file non-empty, line count | ≥ 60 | **319** |
| `## ` sections | ≥ 10 | **13** |
| lines citing `scripts/` | ≥ 8 | **20** |
| `check-music-freeze.sh` named | ≥ 1 | **4** |
| `DEF-06-48-02` cited | ≥ 1 | **1** |
| `DECLARED_INTERP_EXPECTED` named | ≥ 1 | **3** |
| `TAGGER_DEF_EXPECTED` named | ≥ 1 | **3** |
| `ST_PLANNED_CASES` named (both files) | ≥ 1 | **3** |
| literal `Fail closed` | ≥ 1 | **1** |
| line-number citations | **0** (driven) | **0** |
| forbidden-mode token, `-cE` | **0** (driven) | **0** |
| UI-option token, `-ciE` | **0** (driven) | **0** |

**`CLAUDE.md`, against base commit `3fd748d`:**

| Assertion | Result |
|---|---|
| `GSD:conventions-start source:CONVENTIONS.md` present | **1** |
| `GSD:conventions-end` present | **1** |
| both marker lines byte-identical to base | **`cmp -s` identical** |
| `Conventions not yet established` (driven: base = 1) | **0** |
| `Architecture not yet mapped` | **1** — untouched |
| `CONVENTIONS.md` named in the file | **2** |
| diff hunks | one: `@@ -349 +349,16 @@`, strictly inside the marker pair (base markers at 346 / 350) |
| text outside the span, head (lines 1–346, through the start marker) | **byte-identical** |
| text outside the span, tail (end marker to EOF, base 350.. vs now 365..) | **byte-identical**, 33 lines each side |
| base / working line count | 382 → 397 (= 382 + 15) |
| `test ! -e ARCHITECTURE.md` | **succeeds** |
| `git diff --exit-code HEAD -- scripts/` | **0** at both task commits |

⚠ The `HEAD --` in that last row is load-bearing and is itself convention 10: a bare
`git diff --exit-code <path>` compares the working tree against the **index**, so with an edit staged
it exits 0. This plan stages and commits twice.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Corrected claim] The plan's quoted line count for `check-beets-config.sh` was stale**

- **Found during:** Task 1, writing convention 12's measured cost.
- **Issue:** The plan (and `06-REVIEW.md` § WR-02, its source) states `check-beets-config.sh` at
  **1,223** lines. `wc -l` measures **1,222** today.
- **Fix:** The **measured** number is written into `CONVENTIONS.md`, with the review's figure named
  beside it and one clause saying the difference does not touch the finding. Restating an unverified
  number launders it — and a conventions file that quotes a stale count in the entry *about* stale
  in-band counts would be self-refuting. The other two figures were re-measured and are exact:
  `quick-health-check.sh` **3,148**, `phase06-oracle.sh` **3,274**, and `set -euo pipefail` is at
  line 124 of `check-beets-config.sh`, so the review's "first 123 are header comment" is correct.
- **Files modified:** `CONVENTIONS.md` (convention 12).
- **Commit:** `0d9c6f2`

**2. [Rule 2 — Missing critical content] The fence entry gained `DEF-06-29-03`'s trap**

- **Found during:** Task 1, reading `phase06-incremental-control.sh` and the deferred register for
  convention 6.
- **Issue:** The plan asks convention 6 to say "do not hoist". Read at the register, the situation is
  sharper and the omission would have been a live trap: a committed acceptance check counts fence
  **sites**, so a future plan that legitimately shares one fence text — which makes drift
  *structurally impossible*, strictly stronger than testing for it — will **fail** that check.
- **Fix:** The entry states the rule, then carries `DEF-06-29-03` as a ⚠ note with the instruction to
  replace the site count with a predicate over the property actually wanted before de-duplicating.
  Writing "never hoist" without it would have left a rule that punishes an improvement and makes the
  punishment look like a regression.
- **Files modified:** `CONVENTIONS.md` (convention 6).
- **Commit:** `0d9c6f2`

### Nothing Else Deviated

No architectural change was needed, no checkpoint fired, no authentication gate was hit, no package
was installed, and no estate contact was made or attempted.

## Refusals, Recorded As Loudly As The Work

- **`ARCHITECTURE.md` was NOT created.** IN-01 names two files; only one is written. The architecture
  half is dispositioned ACCEPTED in `06-50` — the scripts establish conventions, not an architecture,
  and the estate's architecture is already mapped across `NETWORK.md`, `MEDIA.md`, `DEPLOYMENT.md` and
  `TAILSCALE.md`, all four linked from `CLAUDE.md` § Documentation. A stub would add a fifth, emptier
  front door. The `GSD:architecture` block's "Architecture not yet mapped" text is deliberately left
  standing, and that is asserted mechanically (count **1**).
- **No script was touched**, and no planning document either — not `deferred-items.md`, not
  `beets.md`, not `ROADMAP.md`, not `REQUIREMENTS.md`, not any file under `artifacts/`.
- **The in-band narrative was NOT stripped.** Convention 12 is a go-forward rule and says so in its
  own text: the existing narrative is load-bearing provenance, removing it in bulk would risk losing
  the reason a fail-closed branch exists, and WR-02 is ACCEPTED rather than retro-fixed this round.
- **Convention 13 is a forward pointer, not a present-tense assertion.** `06-DISPOSITIONS-GAP4.md`
  does not exist; `06-50` writes it at wave 3.
- **No CONF-04 work of any kind.** No requirement checkbox moved, `REQUIREMENTS.md` is untouched, and
  `06-VERIFICATION.md` was not re-scored.

## What This Does Not Prove

- **`CONVENTIONS.md` is a description, not an enforcer.** Nothing executes it. Every rule in it was
  corroborated against a canonical example that was read, but there is no mechanism preventing the
  file from drifting away from the code — and the mirror check added here proves only that
  `CLAUDE.md` matches `CONVENTIONS.md`, not that either matches the scripts.
- **The correspondence check is not committed as a script.** It was run by hand at both directions
  (green on the real pair, red on a mutant) and the recipe is recorded above, but nothing re-runs it.
  A future edit to either list will not be caught automatically.
- **Convention 4's exception is a policy, and this plan does not change that.** Writing the
  distinction down does not convert it into a mechanism.
- **No script in the repository was executed** — not `--self-test`, not `bash -n`. This plan modified
  no executable file, so instrument state at HEAD is exactly what plan 06-46 last measured and is
  deliberately not restated here as though it had been re-driven.

## For The Next Plan

- `06-50` owes: the `06-DISPOSITIONS-GAP4.md` register with round 6's `R6-*` mapping table (convention
  13 forward-points at it by name); the ACCEPTED dispositions for IN-01's architecture half and for
  WR-02; and `check-beets-config.sh`'s `ST_PLANNED_CASES=7` third of WR-03, which 06-46 explicitly
  left to it.
- If `06-50` changes shape or halts, **convention 13's forward pointer is the one sentence in
  `CONVENTIONS.md` that goes stale**, and it is written in a form ("will live in", author named) that
  makes that visible rather than silently false.
- The next contributor who adds a `${VAR}/path:/dest` volume line under `stacks/selfhosted/` will turn
  `check-music-freeze.sh` red for an unrelated reason. Convention 5 is now the place that explains it
  without reading the script.

## Self-Check: PASSED

Files claimed created/modified, verified on disk:

- `CONVENTIONS.md` — FOUND (319 lines)
- `CLAUDE.md` — FOUND, modified
- `.planning/phases/06-tagger-configuration-and-dry-run/06-49-SUMMARY.md` — FOUND

Commits claimed, verified in `git log`:

- `0d9c6f2` — FOUND — `docs(06-49): R6-04 — CONVENTIONS.md, the repo's authoritative conventions index`
- `51ca680` — FOUND — `docs(06-49): sync CLAUDE.md's GSD conventions block with CONVENTIONS.md`

Files claimed NOT modified, verified:

- `scripts/` — `git diff --exit-code HEAD -- scripts/` returns **0**
- `ARCHITECTURE.md` — `test ! -e` succeeds
