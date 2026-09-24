---
phase: 06-tagger-configuration-and-dry-run
plan: 48
subsystem: docs
tags: [r6-06, r6-07, def-06-45-04, def-06-39-06, non-detecting-recipe, control-drive, bracketing-convention, scope-decision, base-commit-immutability, round-6]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`deferred-items.md` § DEF-06-45-04 — the carried finding that `06-43-conf04-verdict.txt` SECTION O publishes a non-detecting `grep -cF` recipe against a bracketed needle, with the explicit instruction that the dated artifact is left unedited"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`artifacts/06-43-conf04-verdict.txt` SECTION O — the three recipes `(O-a)`/`(O-b)`/`(O-c)`, the four-file counted set named so it is not a moving target, and the `--- ROUND AUDIT BEGIN/END ---` block"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-VERIFICATION.md` § Anti-Patterns Found — the independent re-drive of the non-detecting recipe, and the Info observation that the forbidden token now appears twice in `ROADMAP.md` prose, recorded 'for a future round'"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`deferred-items.md` § DEF-06-39-06 — the parent class: a count written into a file that greps itself must be bracketed, and verified AFTER being written in band, not before"
provides:
  - "`artifacts/06-48-recipe-control-and-scope.txt` — the both-ways control matrix for the corrected `-cE` detector, the re-derived counts over the full counted set, the base-commit sha256 immutability proof for the dated artifact, the driven demonstration that a bare `git diff --exit-code <path>` is blind to a staged edit, and the scope decision with its measurement"
  - "`deferred-items.md` § DEF-06-48-01 — the corrected `-cE` detector published where a copier will find it, closing `DEF-06-45-04`"
  - "`deferred-items.md` § DEF-06-48-02 — the DECISION that the bracketing convention's scope stays `artifacts/`, with its reasoning, its two named `ROADMAP.md` sites and its revisit condition"
affects: [round-6-r6-06, round-6-r6-07, 06-50-dispositions-gap4, any-future-forbidden-mode-audit]

tech-stack:
  added: []
  patterns:
    - "`-F` and a bracketed needle are mutually exclusive by construction: `-F` suppresses exactly the metacharacter interpretation the bracketing mitigation depends on, so the pair can only ever measure the mitigation form and never the real token"
    - "A zero-expecting count is evidence only when the identical recipe has been observed returning non-zero against a control built to make it fire; publish both drives, not just the zero"
    - "Immutability across a whole plan is proven against a captured BASE COMMIT, not against `HEAD` — `HEAD` moves as the plan commits, and a bare `git diff --exit-code <path>` compares against the INDEX and is blind to a staged edit"
    - "Correct a defective recipe in a NEW artifact plus a `DEF-` entry; never retro-edit the dated artifact that published it, because editing evidence to make a later reading true destroys its value as evidence"
    - "Scope a convention by FUNCTION, not by directory name: any file whose content is counted by a published recipe must write the counted token bracketed"
    - "Name a document's sites by surrounding heading or table row, never by line number — line citations in this repository go stale on arrival, and the verification's own two citations for these same sites already had"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-48-recipe-control-and-scope.txt"
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-48-SUMMARY.md"
  modified:
    - ".planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md"

key-decisions:
  - "THE CORRECTION LANDS IN A NEW ARTIFACT, NOT IN THE DATED ONE, AND THE PROOF OF THAT IS BASE-COMMIT ANCHORED. `06-43-conf04-verdict.txt` is evidence. Its SECTION O is left byte-identical to plan 06-48's base commit `ce35877`, proven by a sha256 pair (`d85ebe4b…` both sides) rather than by `git diff --exit-code HEAD --`, because `HEAD` moved twice during this plan's own execution and a comparison against a moving reference cannot express immutability across a plan."
  - "THE BRACKETING CONVENTION'S SCOPE STAYS `artifacts/` — NOT WIDENED TO `ROADMAP.md`, NOT DROPPED. Scoped by FUNCTION rather than by directory name: any file whose content is counted by a published recipe must bracket the counted token. `ROADMAP.md` is deliberately readable prose and has never been inside a published detector's counted scope, so widening would pay a readability cost for zero measurement benefit; dropping is equally wrong, because inside `artifacts/` the hazard is live and has fired in six consecutive rounds. The revisit condition is the first detector whose counted scope includes a prose document — the convention follows the detector."
  - "BOTH HALVES ARE STATED WITHOUT EITHER BEING SOFTENED INTO THE OTHER. The published `0` is TRUE of the estate — re-derived here across seven files — AND it was not earned by the command printed beside it. 'It was true anyway' is not a defence of a vacuous detector, and 'the detector was vacuous' is not grounds for doubting the estate. A true number from a vacuous instrument is the worst shape there is, because it survives review."
  - "THE CONTROL'S CONTENT IS DELIBERATELY NOT REPRODUCED IN ANY COMMITTED FILE. Quoting the real unbracketed token in order to prove the control contains it would have made the artifact an occurrence of the thing it counts. That the control does contain it is proven by the (1-a) result instead: a `-cE` match against a bracketed character class can only come from a real `R` in the file. All three controls lived only in the session scratch directory and none was staged."
  - "THE `-cF` STRING IS KEPT IN THE ARTIFACT, THE `-cF` RECIPE IS NOT. The defect is quoted in order to explain it — deleting the broken form would leave a copier no way to recognise it — but every PUBLISHED recipe in the artifact is `-cE` or `-ciE`, and the warning names the dated artifact explicitly as the place not to copy from."

metrics:
  duration: "~35 min"
  completed: "2026-09-24"
  tasks: 2
  commits: 3
  files_changed: 3
---

# Phase 6 Plan 48: The Corrected Detector, Driven; and the Bracketing Scope, Decided — Summary

A recipe that could never have matched the thing it forbids is replaced by one proven to match it,
and a convention that was drifting toward whichever direction the next writer pushed it is now a
written decision with reasoning and a revisit condition.

## What Was Done

### Task 1 — `R6-06`: the corrected detector, driven against a control (commit `da5a606`)

Created `artifacts/06-48-recipe-control-and-scope.txt` (sections 1–5 at this commit), header
carrying the full 40-character **BASE COMMIT** `ce358779329c4e37112a843bba877883e9a238f9`, captured
by `git rev-parse HEAD` **before anything was written**.

**The control matrix, driven both ways.** A one-line scratch control carrying the forbidden mode's
real unbracketed token:

| Form | Command | Result |
|---|---|---|
| corrected | `/usr/bin/grep -cE 'Full[R]efresh' <control>` | **1** |
| as published | `/usr/bin/grep -cF 'Full[R]efresh' <control>` | **0** |

The published `-cF` form is **proven non-detecting**; the corrected `-cE` form is **proven
non-vacuous**. `(O-b)`'s phrase recipe was driven against its own control too (**1**), so its zeros
are also the zeros of a working instrument — a confirmation, not a correction, since `(O-b)` was
already `-ciE` and sound. `(O-c)` is untouched. The correction is **surgical to `(O-a)`**.

**`(O-a-corrected)` published in full**, over SECTION O's four named files copied verbatim so the
set is not a moving target, with the warning that `-F` and a bracketed needle are mutually exclusive
by construction and that a copier must take the `-cE` form from here and not the `-cF` form from the
dated artifact.

**Counts re-derived, not restated.** Seven files — the four SECTION O artifacts, the verdict
artifact itself, `scripts/check-music-consumers.sh` and `scripts/quick-health-check.sh` — measured
per file with both the corrected `(O-a-corrected)` and the unchanged `(O-b)`: **0 on all fourteen
readings**. Section 1 is named in band as the drive that makes those zeros evidence about the estate
rather than about the instrument.

**The dated artifact proven immutable against the base commit**, which is the comparison this plan
actually owed:

```
git show <BASE>:…/06-43-conf04-verdict.txt | /sbin/sha256sum
  d85ebe4b68b830d11519fcf2e04f9c66f08351472b33ebb453669a064cedd35c  -
/sbin/sha256sum …/06-43-conf04-verdict.txt
  d85ebe4b68b830d11519fcf2e04f9c66f08351472b33ebb453669a064cedd35c  …
```

`shasum -a 256` was run as a cross-check and agreed on both sides, so the digest is not an artefact
of one implementation.

### Task 2 — `R6-06` + `R6-07`: the record and the scope decision (commit `bcdefd0`)

Two entries appended to `deferred-items.md` after `DEF-06-45-05`, in the file's established shape,
plus **Section 6** appended to the artifact so the decision and its measurement live together.

**`DEF-06-48-01`** publishes the corrected `-cE` recipe in full, cites the control drive by section
(`§ 1`), records the re-derived zeros (`§ 3`), states that `(O-b)` was already sound, and marks
`DEF-06-45-04` **CLOSED** — with the one clause that says what closing means here: the recipe is
corrected *somewhere a copier will find it*, not in the dated artifact. `DEF-06-39-06` is
cross-referenced as the parent class rather than restated.

**`DEF-06-48-02`** is a decision entry:

> The bracketing convention's scope **stays `artifacts/`** — it is **NOT widened to `ROADMAP.md`
> prose**, and it is **NOT dropped**.

with four numbered reasons, the two `ROADMAP.md` sites named by **surrounding heading and table
row**, and an explicit statement that **no `ROADMAP.md` edit is made or required**, so a later reader
does not go looking for one or "finish the job".

## Key Measurements

| Measurement | Value |
|---|---|
| BASE COMMIT | `ce358779329c4e37112a843bba877883e9a238f9` |
| control drive, corrected `-cE` / published `-cF` | **1** / **0** |
| `(O-b)` phrase control drive | **1** |
| line-citation control drive | **1** |
| re-derived token count, 7 files | **0** each |
| re-derived phrase count, 7 files | **0** each |
| `06-43-conf04-verdict.txt` sha256, base vs now | `d85ebe4b…` / `d85ebe4b…` — IDENTICAL |
| `DEF-06-45-04` body sha256, base vs now | `b86042f3…` / `b86042f3…` — IDENTICAL |
| `^## DEF-` headings, base → now | **41 → 43** (= base + 2), **0** base headings missing |
| `ROADMAP.md` token occurrences, re-measured `-cE` | **2** |
| `ROADMAP.md`, `REQUIREMENTS.md`, `scripts/` under `HEAD --` | exit **0** each |

## Deviations from Plan

None to the plan's instructions. One in-band correction to this plan's **own first draft**, recorded
rather than smoothed — see below.

## The Self-Referential Hazard Fired Again, Inside the Entry Describing It

`DEF-06-48-02`'s first draft quoted its scratch control line **plainly** in order to explain the
drive. The plan's own zero-expecting screen —
`/usr/bin/grep -cE 'ROADMAP\.md:[0-9]+'` restricted to the two new entries — then returned **1**,
not 0. The entry had become an occurrence of what it measures, and a naive reading of that 1 would
have said *a line citation was written* when what had actually been written was a description of the
detector.

The quote is now bracketed in the entry (`ROADMAP.md:[1]615`) while the scratch control keeps the
plain form, which is why the control still returns 1 and the entries now return 0. This is
`DEF-06-39-06`'s class firing for the **seventh consecutive round**, and — as in every previous
instance — it was caught **by measuring after the edit landed, not by an assertion written
beforehand**. Recorded in band in the artifact at § 6 (6-b) and in `DEF-06-48-02` itself.

## What This Plan Did NOT Do

- **`artifacts/06-43-conf04-verdict.txt` SECTION O is unedited.** Proven against the base commit.
- **`DEF-06-45-04`'s own body is unedited.** Proven against the base commit by its own digest. It is
  closed by `DEF-06-48-01` *referring* to it, not by anything written into it.
- **No `ROADMAP.md` edit, no `REQUIREMENTS.md` edit, no script edit.** All three assert exit 0 under
  `git diff --exit-code HEAD --` — the `HEAD --` is load-bearing, and the artifact drives why in a
  throwaway repository: with an edit staged, `git diff --exit-code protected.txt` exits **0** while
  `git diff --exit-code HEAD -- protected.txt` exits **1**.
- **No CONF-04 work of any kind, and no requirement state moved.** `REQUIREMENTS.md:152` still reads
  an unticked `CONF-04`; the `negative-carry-e6` override and Phase 7 entry criterion E6 are exactly
  where round 5 left them.
- **`06-VERIFICATION.md` was not re-scored.** That is `/gsd-verify 06`'s call.
- **Zero estate contact.** No `ssh`, no `docker`, no HTTP verb of any kind, no package-manager
  install, no snapshot taken or destroyed. Every command ran on the workstation against files
  already in this repository plus three scratch control files, none of which was staged or committed.

## Known Stubs

None.

## Self-Check: PASSED

- `artifacts/06-48-recipe-control-and-scope.txt` — FOUND, `file` reports `Unicode text, UTF-8 text`
  (no NUL bytes; a NUL-bearing artifact shipped once in this phase, plan 06-41, caught only by
  `file`).
- `deferred-items.md` — FOUND, carries exactly one `^## DEF-06-48-01` and one `^## DEF-06-48-02`.
- Commit `da5a606` — FOUND. Commit `bcdefd0` — FOUND.
- Both plan `<automated>` verify blocks re-run at their respective commits: **PASS**.
