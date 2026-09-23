---
phase: 06-tagger-configuration-and-dry-run
plan: 38
subsystem: tooling / config checker
tags: [gap-closure, round-4, claim-correction, self-referential-counts, comment-only]
gap_closure: true
gap_closure_round: 4
closes_findings: [R4-05]
requires: ["06-34"]
provides:
  - "a census paragraph in scripts/check-beets-config.sh that pins no raw count"
  - "an audited and dispositioned set of in-band count claims in that file"
  - "a bracketed, self-non-matching recipe for the env-override census"
affects:
  - scripts/check-beets-config.sh
tech-stack:
  added: []
  patterns:
    - "state a recipe, not a number, in any file that greps itself"
    - "bracketed-pattern device so a recipe written in band is not an occurrence of what it measures"
    - "comment-stripped counts, or inequalities, instead of raw equalities"
key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-38-checker-count-audit.txt
  modified:
    - scripts/check-beets-config.sh
decisions:
  - "R4-05 fixed by WITHDRAWING the raw figure, not by re-pinning it to 5"
  - "ST_PLANNED_CASES=7 excluded from the audit by name and left untouched"
  - "the plan's raw `| grep -q` assertion replaced with its comment-stripped form (Rule 1 deviation)"
metrics:
  tasks: 2
  commits: 2
  files_changed: 2
  executable_lines_changed: 0
  completed: 2026-09-23
---

# Phase 06 Plan 38: Withdraw the Raw Census Count and Audit the Checker's Count Claims — Summary

R4-05 closed as a **claim correction**: the raw grep figure in
`scripts/check-beets-config.sh`'s census was **withdrawn rather than re-pinned**, and every other
in-band count claim in that one file was measured against its own recipe and dispositioned.

## Disposition, stated plainly

**R4-05's fix was a CLAIM CORRECTION.** No behaviour change, no executable line moved, no estate
contact. `--self-test` output is **byte-identical to the pre-plan baseline** (`cmp` rc 0) and still
reports all 7 cases behaving as expected, 6 of them red.

## Finding ID aliasing

Round 4's report reuses round 1's `WR-*`/`IN-*` namespace, and round 1's IDs are already cited in
band in this file. In band and in every verify block this round's finding is written **`R4-05`**,
never the bare report ID `WR-05`.

| Round-4 report ID | In-band ID |
| --- | --- |
| WR-05 | **R4-05** |

## Task 1 — the withdrawal

Round 3's hunk correcting R3-07 wrote `(raw is 4, and rises with prose like this)`. Measured: raw
was **5** — it was 4 at the round-3 diff base, and the recipe line that same hunk added made it 5.
The hedge was not a fix; the hunk that wrote the hedge is what rose it.

The figure was **deleted, not corrected to a new number**. Re-pinning would have set up the fourth
drift, arriving with the next comment naming the symbol. The replacement:

- states the raw count is **deliberately not pinned**, with the reason in one clause;
- cites the sibling precedent (`R3-05` in `scripts/quick-health-check.sh`, same round — read only,
  plan 06-35 owns that file) and `06-DISPOSITIONS-GAP2.md` § Corrections item 1 for the three-ref
  measurement, rather than re-deriving numbers in band;
- **paraphrases** the retired construction instead of pasting it, per Lessons 4, so a grep for its
  absence can and does return 0;
- contains **no raw figure anywhere**, including in the sentence disowning it.

The comment-stripped census (`The answer is 2`) was correct and was left exactly as it stood. It was
**re-measured after the edit landed**, not before — verifying a census only against the pre-edit
tree is the precise mistake R4-05 records.

One self-inflicted instance was caught and is recorded in the artifact rather than hidden: the first
draft said the moving recipe line was "four lines above", a positional claim already wrong by eleven
lines. No assertion in the plan would have failed on it; re-reading the applied edit caught it.

## Task 2 — the audit

Twelve claims enumerated by a keyword sweep **plus** an end-to-end read, each measured:

| Disposition | Claims |
| --- | --- |
| **WRONG → withdrawn** | the R3-07 raw census figure (R4-05, task 1) |
| **ACCURATE BUT SELF-MOVING → converted to a recipe** | the env-override census in the file header |
| **ACCURATE AND STABLE → left alone** | the comment-stripped census; the self-test banner breakdown; GC-13's three-outcomes/one-counter claim; the two-arm polarity claim; three claims counting tokens in *other* version-controlled files (`beets.yaml` ×2, `check-music-freeze.sh`) |
| **EXCLUDED by name** | `ST_PLANNED_CASES=7`; case 7's 64 KiB precondition; the GC-01 here-string form |

The one genuine conversion: the header asserted "a grep can prove it exists" and then **did not
supply the grep** — and the obvious one (`grep -c ':-'`) answers 5, catching Python slices in the
embedded extractor and an unrelated `${ver:-...}` default. It now carries a **bracketed** recipe,
`EXTRA_FORBIDDEN_SUBSTRINGS:[-]`, which was **verified to answer 1 after being written in band** —
i.e. proven not to match itself rather than assumed to — with a one-clause note on why the hyphen
stays bracketed.

`ST_PLANNED_CASES=7` was **not touched** and is recorded as an EXCLUDED row with its reason: it is a
gated pin over an unconditionally executed set, not a prose claim, and it is the one number in this
file that is supposed to be a number. "Fixing" it would have broken a working guard.

The artifact states the enumeration method **and its known gaps**, and explicitly does **not**
describe itself as a completeness proof.

## How comment-only was proven (not asserted)

Per task, and again across the whole plan, with the **vacuity guard first** — this phase has printed
a green tick over an empty set twice (CR-01, GC-03):

1. `git diff -U0 | grep -c '^[+-][^+-]'` ≥ 1 — the diff is non-empty.
2. the same diff filtered for non-comment lines → **0**.
3. `--self-test` captured before and after and compared: **`cmp` rc 0**. Determinism of that
   comparison was established first by running `--self-test` twice against the *unedited* tree;
   without that control, a `cmp` rc 0 across an edit proves nothing.
4. `bash -n` rc 0, `--self-test` rc 0, 7 cases.

Both `<automated>` blocks were extracted, `bash -n`'d and run against the **unfixed** tree before any
edit. Task 1 failed at its first assertion (`test 1 -eq 0` on the withdrawn parenthetical); task 2
failed at `test -s "$ART"`. Neither reached its end, so neither was vacuous. Both transcripts are in
the artifact.

## Deviations from plan

### 1. [Rule 1 — Bug] The plan's own task-2 verify block could not pass at its own base commit

**Found during:** Task 2 verification.

**Issue:** the block asserted `grep -cF '| grep -q' scripts/check-beets-config.sh` **== 0**. That
answers **2** at the plan's base commit `24d6624` and **2** after both tasks — *unchanged by this
plan*. The two hits are **comments** quoting the retired construction to explain why GC-01 replaced
it. This is `06-DISPOSITIONS-GAP2.md` § Lessons 4 verbatim: a grep for a token's absence cannot
distinguish a claim from its retraction.

**Fix:** substituted the **comment-stripped** form, which is § Lessons 3's standing prescription:

```
test "$(/usr/bin/grep -v '^[[:space:]]*#' scripts/check-beets-config.sh \
          | /usr/bin/grep -cF '| grep -q')" -eq 0
```

Measured **0 at base and 0 now**. It still fails loudly on a real executable regression, which is the
property GC-01 cares about.

**No code was changed to make a test pass.** The assertion was wrong about the tree; the tree was
right. Satisfying the raw form would have required **deleting the two comments explaining the
phase's only BLOCKER**. Recorded in the artifact § 5a and in the commit message rather than quietly
patched, because an unrecorded substitution is indistinguishable from an executor weakening a test
it could not pass.

**Commit:** `301876f`.

### 2. [Rule 1 — Bug] This plan's own artifact pinned a raw count twice and was wrong twice

Caught by measuring, not by any test. The artifact pinned the raw `ST_PLANNED_CASES` count at 4
(wrong when written — it was 6), corrected it to 6, and then **task 2's own audit-pointer comment
moved it again**. Withdrawn at row 3 rather than corrected a third time. A separate figure in the
same artifact was pinned at 18 and measured 22; corrected and relabelled a dated observation.

That is two further drifts of the defect class, *inside the audit of that defect class*, in the plan
closing its third consecutive instance. Logged as `F-06-38-02`.

## Findings for plan 06-39 to defer by name

Claims requiring a **code** change to `scripts/check-beets-config.sh`: **NONE**. This is a genuine
empty result — every row was measured — not an unperformed check.

| ID | Finding |
| --- | --- |
| **F-06-38-01** | Round-4 gap-closure **verify blocks** should be swept for raw self-referential counts. Plan 06-38's task-2 block asserted a raw count against a file whose comments legitimately quote the token; it could not pass at the plan's own base commit. The defect class this round closes *in the scripts* is also present *in the verification that checks them*, and nothing in the round's brief was looking there. Mitigation: any verify assertion counting a token in a file that discusses that token should use the comment-stripped recipe or an inequality, never a raw equality. |
| **F-06-38-02** | Artifacts are subject to the same hazard as scripts. This plan's artifact pinned raw counts and was wrong twice, once moved by the plan's own new comment. |

## Environment notes worth carrying forward

- `/usr/bin/sed` on this workstation is **BSD**. `sed '0,/re/s//…/'` is a GNU extension that BSD sed
  accepts silently, substitutes nothing, and exits 0. **No `sed` was used**; every edit was an
  exact-match string replace, which fails loudly when the anchor does not match.
- The worktree isolation layer **refuses `bash -x <file>`**. Plain `bash <file>` and `bash -n <file>`
  are permitted. A wrapper that `set -x`'d and then sourced the block *by variable* was also
  refused; **inlining `set -x` into a copy of the block** is what worked.

## Scope discipline

- No estate contact — `--self-test` only. No `--run`, ssh, docker, or live `library.db`.
- Exactly two files changed across the whole plan:
  `scripts/check-beets-config.sh` and the audit artifact. `git diff --name-only -- scripts/` lists
  one path.
- `scripts/quick-health-check.sh` and `scripts/phase06-oracle.sh` read only — plans 06-35 and 06-36
  own those this round and run in parallel.
- **No requirement checkbox moved. CONF-04 is not closed and is not claimed. The phase is not
  declared complete.**
- `06-VERIFICATION.md` not read as a gap source and not touched.
- STATE.md and ROADMAP.md untouched — the orchestrator owns those after the wave merges.

## Self-Check: PASSED

- `scripts/check-beets-config.sh` — FOUND, modified, comment-only.
- `artifacts/06-38-checker-count-audit.txt` — FOUND, non-empty.
- Commit `b5831b2` (task 1) — FOUND.
- Commit `301876f` (task 2) — FOUND.
- `bash -n` rc 0; `--self-test` rc 0, 7 cases; `cmp` vs pre-plan baseline rc 0.
- Whole-plan non-comment changed lines in the script: **0**.
