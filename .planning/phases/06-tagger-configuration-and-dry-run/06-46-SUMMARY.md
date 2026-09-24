---
phase: 06-tagger-configuration-and-dry-run
plan: 46
subsystem: infra
tags: [r6-01, r6-03, wr-01, wr-03, shellcheck, check-music-freeze, remediation-output, def-06-45-04, conf-01, conf-02, conf-06, round-6]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-REVIEW.md` § WR-01 — the single shellcheck finding across all six reviewed scripts, with its exact one-line fix"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-REVIEW.md` § WR-03 — the pinned-count maintenance trap and its fix option (a)"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "`06-DISPOSITIONS-GAP3.md` — the named reference environment (macOS, non-root, python3 present) that makes the 7 / 140 self-test figures comparable, and `DEF-06-39-02`'s by-name exclusion of `ST_PLANNED_CASES=7`"
  - phase: 05-inbox-structure-and-the-junk-gate
    provides: "`deferred-items.md` item 1 — this exact pinned-count trap firing in the field, with the remedy already written down, so the emitted remediation matches it rather than inventing a second one"
provides:
  - "`scripts/check-music-freeze.sh` — the five-field tagger-capable inventory read names every column it binds (`xn _xs xsrc _xdst xflag`), closing the only shellcheck finding in the reviewed set"
  - "`scripts/check-music-freeze.sh` — both pinned-count fail arms now emit a remediation line naming the literal edit required, and the one thing the maintainer must NOT do"
  - "`artifacts/06-46-freeze-fixes.txt` — the driven transcript: shellcheck before/after across six scripts, four driven harness outcomes, and the driven control for the zero-expecting recipe"
affects: [round-6-wr-01, round-6-wr-03, quick-health-check-fold-in]

tech-stack:
  added: []
  patterns:
    - "Underscore-prefix an unused column in a multi-field `read` rather than collapsing it to a bare `_`: the prefix is shellcheck's deliberately-unused convention AND keeps the column identity legible, so a future column insertion is visible instead of silent"
    - "When a pinned count fails loud but for a reason the tripper did not cause, the fix is not new assertion logic — it is making the EXISTING failure name the literal edit, the same-commit rule, and the prohibited shortcut"
    - "Emit remediation with a plain `echo` beside the existing `fail`, never as a second `fail`: one violation must not double-count, and the failure total is an asserted invariant"
    - "Never let a zero-expecting count stand unproven — run the identical recipe against a control built to make it non-zero first, and capture both drives (`DEF-06-45-04` class)"
    - "Drive a branch that needs estate contact from a scratch harness extracted verbatim by line range from the file being committed, and state in the artifact that this proves the arm TEXT and its interpolation, not the live block"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-46-freeze-fixes.txt"
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-46-SUMMARY.md"
  modified:
    - "scripts/check-music-freeze.sh"

key-decisions:
  - "THE NAMED FORM WAS TAKEN, NOT THE REVIEW'S BARE-UNDERSCORE ALTERNATIVE. WR-01 offered `read -r xn _ xsrc _ xflag`; two anonymous positions discard the column NAMES, and a five-field read with anonymous positions is precisely where a future column insertion hides — which is the whole reason WR-01 is a finding rather than a nit. The binding is `xn _xs xsrc _xdst xflag`: shellcheck-clean AND self-describing."
  - "THE PREMISE WAS CHECKED BEFORE THE EDIT, NOT ASSUMED. `/usr/bin/grep -nE '\\b(xs|xdst)\\b'` at the base commit returned exactly one line — the binding itself — so neither column is consumed anywhere in the loop body. Had either been referenced, WR-01 would have been a wrong finding and this plan's premise false; the plan's own STOP condition was live and did not fire."
  - "THE COLUMN ORDER WAS READ FROM THE PRODUCER, NOT INFERRED FROM THE NAMES. The `docker inspect --format` at `:981-983` emits `name|state|source|destination|rw-flag`, so `_xs` is the container STATE and `_xdst` the mount DESTINATION — confirming the two underscore-prefixed names are the two the body does not use (`xn`, `xsrc`, `xflag` are)."
  - "THE ZERO-EXPECTING RECIPE WAS DRIVEN AGAINST A CONTROL BEFORE ITS `0` WAS PUBLISHED. The identical `grep -vE '^[[:space:]]*#' | grep -cE '\\$\\{?(xs|xdst)\\b'` returned **1** against a one-line control containing `echo \"$xs $xdst\"` and **0** against the real script. The `0` is therefore evidence the references are gone, not evidence the instrument cannot detect — the `DEF-06-45-04` defect class this round exists to stop repeating."
  - "NO PREDICATE, NO CONSTANT AND NO FAILURE COUNT MOVED, AND ALL THREE WERE MEASURED AGAINST THE BASE COMMIT. `TAGGER_DEF_EXPECTED=2` and `DECLARED_INTERP_EXPECTED=\"${DECLARED_INTERP_EXPECTED:-12}\"` are byte-identical to `75c7989`; the comment-stripped `fail ` call-site count is **24** at both ends, re-measured at the base commit before being trusted. The remediation lines are plain `echo`, so `FAILURES` is untouched and one violation cannot double-count."
  - "THE OVERRIDE PROHIBITION IS WRITTEN AS POLICY OVER A DOCUMENTED CAPABILITY, NOT AS A DENIAL OF IT. The constant's own header already states that `DECLARED_INTERP_EXPECTED` can declare a red green and resolve nothing. Contradicting that would have made the new line dishonest, so the emitted sentence names the override's ONLY sanctioned use — making the check REDDER, i.e. driving the failure branch — and says in its own words that it is a policy on top of a stated capability."
  - "THE TAGGER REMEDIATION REFUSES THE COUNT BUMP BY NAME. It requires a third definition be added the way the two existing ones are — a `TAGGER_DEF_<NAME>` path constant AND a `TAGGER_DEF_<NAME>_CLASS` one-line class string, both into the expected SET built at the `DEF_EXPECTED` sort, with `TAGGER_DEF_EXPECTED` moved in the same commit — because D-11 asserts the pair BY NAME AND BY CLASS and a bare count can never read as a pass."
  - "`ST_PLANNED_CASES=7` WAS NOT TOUCHED, AND THAT WAS ASSERTED RATHER THAN CLAIMED. `git diff --exit-code HEAD -- scripts/check-beets-config.sh` returns 0 in the verify block, with the `HEAD --` load-bearing: a bare `git diff --exit-code <path>` is blind to a staged edit and this plan stages twice. WR-03's third is dispositioned ACCEPTED in `06-50`, and round 4 excluded it by name (`DEF-06-39-02`)."

patterns-established:
  - "A gap-closure plan that ends the round measurably cleaner than it started on a whole-set instrument (5 clean → 6 clean on `shellcheck -S warning`), rather than merely differently"
  - "Extracting a fail arm verbatim by line range from the file being committed, running it green and red from stub values, and recording all four outcomes with the interpolation visible in the red transcript"

requirements-completed: []

duration: 20min
completed: 2026-09-24
---

# Phase 06 Plan 46: R6-01 and R6-03(a) in `check-music-freeze.sh` Summary

**`shellcheck -S warning` is now clean on all six reviewed scripts where it was clean on five, and both pinned-count failures in `check-music-freeze.sh` print the literal edit the maintainer must make and the one shortcut they must not take — achieved with four added lines, no changed predicate, no moved constant and no changed failure count, every claim driven including the zero-expecting one.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 2 of 2, both `auto`, each committed individually
- **Files modified:** 1 script (4 lines added, 1 changed), 1 new artifact
- **Estate contact:** none. Zero `ssh`, zero `docker`, zero `--run` — as the plan required.
- **Package installs:** none. `RESEARCH.md`'s Package Legitimacy Gate was not triggered.

## What Changed

| Site | Before | After |
| --- | --- | --- |
| `:1044` tagger-capable inventory read | `read -r xn xs xsrc xdst xflag` — two SC2034 findings | `read -r xn _xs xsrc _xdst xflag` + one `R6-01` comment; field count still five |
| `DECLARED_INTERP_EXPECTED` fail arm | `fail` + row dump, remedy implicit | same `fail`, same dump, plus an `echo` naming the constant, `12 → 13` live, the read-by-hand precondition, the same-commit rule and the override prohibition |
| `TAGGER_DEF_EXPECTED` fail arm | `fail` + expected/found dump | same `fail`, same dump, plus an `echo` refusing the count bump and requiring a named `TAGGER_DEF_<NAME>` + `_CLASS` pair |

## The Measurements

**Before/after on the whole reviewed set.** Five clean, one carrying WR-01's two SC2034 findings — the only shellcheck finding across all six — became six clean, exit 0 with zero output on each.

**Both fail arms driven in both directions** from a harness extracted verbatim by line range out of the file this plan commits (interp block `511-518`; tagger block `831-847`, started one line early at the `DEF_EXPECTED` sort so the expected SET is derived by the real code rather than stubbed). Green arms: the remediation line is ABSENT. Red arms: PRESENT, with the stub values interpolated — the interp arm renders `from 12 to 13` from `$DECLARED_INTERP_EXPECTED` and `$INTERP_COUNT`. All four transcripts are pasted verbatim into the artifact, not narrated.

**The artifact states its own limit in one clause:** the harness proves the arm TEXT and its interpolation; it does **not** prove the live block, which needs estate contact this plan makes none of.

**The two untouched instruments were re-measured, not carried forward:** `check-beets-config.sh --self-test` exit 0 at 7 cases (6 red), `phase06-oracle.sh --self-test` exit 0 at 140 cases — both the named-reference-environment figures, and this run IS that environment (macOS 27.0 arm64, non-root uid 501, `python3` present at `/opt/homebrew/bin/python3`, GNU bash 5.3.15, ShellCheck 0.11.0, BSD grep at `/usr/bin/grep`).

**Hygiene.** `file` reports the artifact as UTF-8 text; the NUL screen is a byte-count comparison across `tr -d '\000'` (12,740 = 12,740), because `grep -c $'\000'` and `awk 'index($0,"\000")'` both reduce the needle to the empty string and are vacuous — round 5's finding, honoured here. No credential, no API key, no host address.

## Scope Fence Honoured

No new assertion logic. No pass/fail predicate changed. `DECLARED_INTERP_EXPECTED` stays at its default and `TAGGER_DEF_EXPECTED` stays at `2`, both asserted against the base commit `75c7989` rather than the index. The `check-beets-config.sh` `ST_PLANNED_CASES=7` third of WR-03 is untouched and byte-identical, asserted with `git diff --exit-code HEAD -- <path>` per the plan's `HEAD --` rule.

## Deviations from Plan

None — the plan executed exactly as written. The plan's one STOP condition (either `$xs` or `$xdst` being referenced in the loop body, which would have made WR-01 a wrong finding) was checked before editing and did not fire.

## Threat Register Outcome

| Threat ID | Outcome |
| --- | --- |
| T-06R6-01 | Predicates and constants asserted byte-unchanged against the base commit; `fail ` call-site count 24 at both ends |
| T-06R6-02 | The override prohibition is stated as policy over the header's documented capability, not as a contradiction of it |
| T-06R6-03 | Only counts and repo-relative paths reach the new lines; no credential, host or key |
| T-06R6-04 | Both remediation lines are `echo` with a single double-quoted argument, never `printf` with a data-derived format |
| T-06R6-05 | `bash -n` and `shellcheck -S warning` clean on every edit; the round ends six-clean |
| T-06R6-39 | The one zero-expecting count published here was driven against a control returning 1 first; both drives captured |
| T-06-SC | No package-manager install of any kind was performed |

## Commits

| Task | Commit | Content |
| --- | --- | --- |
| 1 | `e515970` | R6-01 — `xn _xs xsrc _xdst xflag`, one comment line |
| 2 | `049e9a3` | R6-03(a) — both remediation lines + the driven transcript |

## Known Stubs

None. Both edits are complete and emitted output is live on the failure path.

## Self-Check: PASSED

All three files present on disk (`scripts/check-music-freeze.sh`, `artifacts/06-46-freeze-fixes.txt`, `06-46-SUMMARY.md`); all three commits present in `git log` (`e515970`, `049e9a3`, `21c263e`).
