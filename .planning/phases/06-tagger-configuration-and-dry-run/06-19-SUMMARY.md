---
phase: 06-tagger-configuration-and-dry-run
plan: 19
subsystem: testing
tags: [bash, shellcheck, dash, pipefail, vacuity-guard, fail-closed, beets, phase06-oracle]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "scripts/phase06-oracle.sh as plan 06-18 left it, including the WR-01 site it deliberately did not fix"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "scripts/phase06-incremental-control.sh's empty-manifest guard and its stated RED-vs-UNKNOWN convention (plan 06-20), which this plan copies and names back"
provides:
  - "manifest_compare's empty-manifest guard, carrying the sibling's reason text verbatim: two empty listings can no longer satisfy layer 2 of the wrote-nothing proof by having measured nothing"
  - "report_multi_artist routed to UNKNOWN on an unreadable OR empty input - the green tick over a could-not-look is gone, and the one surviving return 0 states the denominator it read"
  - "assert_field_view(): the field-view read lifted out of step 11 so an empty fields.tsv can be fed to it, and no longer prints '0 items, six columns each'"
  - "SCRATCH_PROBE_PROG: the dirty-destination probe with NO pipeline inside the container, whose four-word answer distinguishes present-but-unreadable from absent-or-empty"
  - "assert_dj_count's VACUOUS refusal on a zero wanted count, naming DEF-06-12-01"
  - "An EXIT CODES block that states the RED-vs-UNKNOWN convention, its reason, and names the sibling back - completing IN-08"
  - "--self-test grown 79 -> 111 cases, every new refusal carrying a passing partner, with a derived case total in the banner"
  - "artifacts/06-19-oracle-vacuity-driven.txt: measured before/after per finding, nine verify mutations plus a control, and a seven-item NOT-DRIVEN register"
affects: [06-21, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read a remote command's status with `out=$(cmd) || exit N` instead of a pipeline: POSIX hands a lone-command-substitution assignment the substitution's status, and dash has no pipefail"
    - "Make the remote ANSWER a word, never an absence: emptiness of stdout must never be evidence, and an unrecognised word must refuse"
    - "Lift an inline judgement into a named function so --self-test can feed it an input; inline, it can only be reasoned about"
    - "Every vacuity guard ships with a PASSING partner in the same transcript - a guard that refuses everything invites its own removal"
    - "Count the self-test's case total in the harness; never type it into the banner"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-19-oracle-vacuity-driven.txt
  modified:
    - scripts/phase06-oracle.sh

key-decisions:
  - "The WR-06 double report is KEPT, with the second message saying in band that it is a restatement. The two sites report different conditions (ssh failure vs the file being unreadable/empty) and can only co-occur for an empty fields.tsv - a case that IS reachable, because rsh_to creates its output file by redirection before ssh runs. Suppressing the second would make the 'CONF-04 write side' label vanish from the transcript on exactly the input it cannot judge; a doubled UNKNOWN is noise, a silent label is the defect class returning."
  - "report_multi_artist's EMPTY-input branch also returns 2, not just the unreadable one. The plan named the unreadable branch; must_haves named 'an empty fields TSV' as routing to UNKNOWN, and zero rows counted out of an empty file is a could-not-look wearing a different hat."
  - "WR-01 is driven in --self-test after all, over local /bin/sh, using the same technique the file's existing WR-08 case uses. The plan said not to fabricate a case; driving the real program text is not fabrication, and it caught the actual defect. What genuinely cannot be driven offline - the container's dash, docker exec's status propagation, a directory unreadable by `beetle` - is named in the NOT-DRIVEN register instead of the whole finding."
  - "The field-view read was FACTORED OUT rather than guarded in place. Inline it could never be fed an empty file, and the plan required the branch driven."
  - "The exit-code NUMBERING difference between the two scripts was left alone, as 06-20 left it. IN-08 is about precedence; renumbering would invalidate committed evidence citing those codes."
  - "No oracle --run and no --baseline. Every change is to a refusal branch, so it can only make a future run redder; 06-11's artifacts stand unchanged."

patterns-established:
  - "Measure a before/after by lifting the SAME function bodies out of the real file at both commits and feeding them one fixture - never by retyping the old string from the review"
  - "Drive the verify red before trusting it: one mutation per change, plus an unmutated control"
  - "A `||` is not a pipeline - an assertion that bans `|` must strip the ORs first, or it is a false red on correct code"

requirements-completed: [CONF-03, CONF-06]

# Metrics
duration: ~65min
completed: 2026-09-22
---

# Phase 6 Plan 19: The Oracle's Vacuity and Could-Not-Look Guards Summary

**`scripts/phase06-oracle.sh` can no longer print a green tick over a blind read: two empty manifests, an unreadable or empty field view, an unexercised DJ stratum and a present-but-unreadable container scratch directory all route to a refusal now, each one proved to fire AND proved to let a correct input through by its own offline self-test.**

## Performance

- **Duration:** ~65 min
- **Completed:** 2026-09-22
- **Tasks:** 3 of 3
- **Files:** 1 modified, 1 created

## Accomplishments

- **WR-02 closed.** `manifest_compare` gained the `-s` guard its sibling has carried from the start, with the reason text copied verbatim rather than paraphrased. Measured: two empty manifests returned **rc 0, "identical before and after"** at `92512d5` and now return **rc 2** with the vacuity reason. The case is reachable with a *clean* ssh status — `find -type f -printf` returns rc 0 and no output on an existing but empty directory — which is what made it a real defect rather than a stylistic one.
- **WR-06 closed, and its old green tick preserved verbatim.** Measured by lifting the same six definitions out of the real file at both commits:
  - before: `✓ CONF-04 write side: the fields TSV is missing or unreadable, so the write side could not be shown` — `UNKNOWNS=0`
  - after: `⚠ UNKNOWN, not green: …` — `UNKNOWNS=1`

  The counter is the half that matters: before the change that branch could not affect the verdict at all.
- **IN-12 closed.** `✓ field view read: 0 items, six columns each` over an empty `fields.tsv` — a tick asserting that every one of zero items had six columns — is now a refusal saying the view was **NOT PRODUCED**. The judgement was factored into `assert_field_view` so it could be fed an empty file.
- **WR-01 closed, and driven red.** The file's one in-container pipeline is gone. The old shape returns **rc 0 and empty output for BOTH an empty directory and an unreadable one** — byte-identical, measured — which is exactly why the precheck ticked green over a could-not-look. The new probe answers `absent` / `empty` / `notadir` / `nonempty <entry>`, and exits **4** on an unreadable directory.
- **IN-09 closed.** `assert_dj_count` refuses a zero wanted count as VACUOUS in its neighbour's own vocabulary, and names `DEF-06-12-01` — path rule 2, the only `paths:` rule no Phase 6 instrument has evaluated. Measured before: `✓ DJ/ destinations = 0, exactly the sampled DJ file count`.
- **IN-08 completed.** The convention — *a blind instrument outranks a measured red* — is now stated in both sibling scripts' EXIT CODES blocks, each naming the other. Plan 06-20 asked that this not be marked satisfied until this landed; it has.
- **Every new guard has a passing partner.** `--self-test` went **79 → 111 cases**, all green, and the closing banner's total is **counted by the harness, never typed**.

## Task Commits

1. **Task 1: the empty manifest, the blind report, the empty field view, the in-container pipeline** — `bc81d5d` (fix)
2. **Task 2: the DJ vacuity guard, the stated precedence, a pair per guard** — `cfec2ec` (fix)
3. **Task 3: the driven record and the NOT-DRIVEN register** — `a17d078` (docs)

## Files Created/Modified

- `scripts/phase06-oracle.sh` — the `-s` guard in `manifest_compare`; `assert_field_view()`; `report_multi_artist`'s two could-not-look branches and its stated denominator; `SCRATCH_PROBE_PROG` and the four-arm `case` at the dirty-destination precheck; `assert_dj_count`'s zero-count refusal; the EXIT CODES precedence paragraph and a matching comment at the verdict tail; `st_grep_why()` and `self_test_vacuity()` (32 new cases); the derived `ST_RUN` banner total.
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-19-oracle-vacuity-driven.txt` — measured before/after per finding, WR-06's verbatim old tick, the WR-01 five-state drive with its driven red, nine verify mutations plus an unmutated control, the IN-08 decision, the no-run statement and the seven-item NOT-DRIVEN register.

## Decisions Made

### The double-report question (task 1, edit 2) — KEEP BOTH, and say so

The plan asked for a decision and for it to be recorded. **Both reports are kept, and the second says in band that it is a restatement.**

The two sites report *different* conditions: step 11's block fires on `RSH_RC -ne 0` (the ssh/docker call failed), `report_multi_artist`'s on the *file* being unreadable or empty. They can only co-occur for an empty `fields.tsv` — and that case **is** reachable, measured rather than assumed: `rsh_to` creates its output file by redirection *before* ssh runs, so after any remote failure the file exists, is readable, and is empty.

Suppressing the second would make the label `CONF-04 write side` vanish from the transcript on exactly the input it cannot judge. A doubled UNKNOWN is noise; a label that goes silent is this phase's defect class returning under a different name. The message therefore carries `(Restated: the field-view read above reports the same condition…)`.

### Scope extensions taken deliberately

- **`report_multi_artist`'s empty-input branch also returns 2.** The plan named only the unreadable branch, but `must_haves` named "an empty fields TSV" as routing to UNKNOWN, and zero rows counted out of an empty file is the same could-not-look.
- **WR-01 *is* driven in `--self-test`.** The plan said it could not be driven offline and asked that no case be fabricated. Driving the real program text with local `/bin/sh` is the same technique the file's existing WR-08 case uses, and it produced the finding's clearest evidence (the old shape's `noread` and `emptydir` answers are byte-identical). What genuinely cannot be driven offline is named in the register instead of writing off the whole finding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Task 1's and task 2's `<verify>` blocks carry three defects and could not be used as written**

- **Found during:** Task 1, first run of the plan's own verify.
- **Issue:** Three separate shapes, all flagged by the cross-plan warning and all present:
  - `printf "%s\n" "$s" | grep -q …` under `set -o pipefail` — `grep -q` exits on first match, `printf` takes SIGPIPE, pipefail propagates **141**, so each assertion fires its failure branch precisely when the file is **correct**.
  - `grep -qE "\-s \"\\\$OUT/fields.tsv\"|\-s \"\\\$fields\""` — inside a double-quoted bash string `\$` collapses to `$`, and **BSD grep** (this is a macOS workstation) then reads `$` as an end-of-line anchor mid-alternative, so neither alternative can ever match.
  - `awk "/EXIT CODES/,/^# =/" "$f" | grep -q …` — the same SIGPIPE shape, and an unbounded-range risk besides.
- **Fix:** the comment-stripped text, each function body and the EXIT CODES block are each materialised to a **file** and grepped there; no pipeline carries a verdict. The EXIT CODES extraction takes only the first block and stops, and asserts the block is non-empty and under 60 lines, so losing the `# =` delimiter is caught. Nothing asserted was weakened; **eleven** assertions were added that the plan's acceptance criteria named but its verify did not check — the `-s` guard being *inside* `manifest_compare`, the comment naming the sibling being in the same function body, the `-s` test *preceding* the `NF != 6` awk, the probe carrying no pipeline and reading find's status, the four `case` arms, the reason being given for the precedence, the implementation matching the stated order, and the banner total matching the cases printed.
- **Files modified:** none in the repo — this is a correction to the verification method.
- **Verification:** the corrected verify is green on the finished file and red under all eight mutations.
- **Committed in:** n/a (verification method; recorded here and in the artifact)

**2. [Rule 1 — Bug] My own first WR-01 assertion was a false red on correct code**

- **Found during:** Task 1, writing the corrected verify.
- **Issue:** the assertion "the probe program carries no pipeline" was written as `grep -qF '|' "$t/prog"`. The probe contains `out=$(find …) || exit 4` — a **logical OR**, which is how it reads find's status and is the whole point of the fix. The check fired on the correct file.
- **Fix:** strip `||` first, then any surviving `|` is a real pipeline; and a second assertion *requires* `|| exit 4` to be present, so the correct construction is asserted rather than merely not banned. Worth recording alongside the plan-verify defects: the same category (a check that cannot pass) can be introduced by the executor as easily as by the planner.
- **Files modified:** none in the repo.
- **Committed in:** n/a

**3. [Rule 2 — Missing critical functionality] There was no self-test case-count banner to update**

- **Found during:** Task 2.
- **Issue:** task 2's acceptance criteria required "the self-test's case count and banner text match the number of cases it actually runs". **No such banner existed** — the closing line printed only `ST_FAIL`, and 06-18's "73 → 80" figure was counted off a transcript by hand, not emitted by the script. A criterion about a banner that does not exist is unsatisfiable either way.
- **Fix:** an `ST_RUN` counter incremented inside `st_case`, and the banner prints it. The total is **derived**, so it cannot drift when a case is added; a typed total would drift and then read as authority. The corrected verify asserts the banner's number equals the number of `(expected):` lines the run actually printed, and mutation M8 (hard-coding `99`) makes that assertion fire.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** `--self-test` reports `111 case(s)`; the verify's independent count agrees; M8 fires.
- **Committed in:** `cfec2ec`

**4. [Rule 2 — Missing critical functionality] The `notadir` and unrecognised-answer arms**

- **Found during:** Task 1, edit 4.
- **Issue:** the plan asked the probe to distinguish three outcomes from a fourth. Two more states are reachable and neither had an arm: `$SCRATCH` existing as a **regular file** (the old `ls -A <file>` printed the filename and was read as "dirty", which happens to be right for the wrong reason), and any answer the probe did not emit. Leaving the latter to fall through would have re-created the defect — "an answer I did not expect" would have been read as "nothing there".
- **Fix:** `notadir` and a `*)` arm, both `precheck_fail`. The `*)` arm is recorded as undriveable-by-design in the register: it exists to catch a future edit that makes the probe and the call site disagree.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Committed in:** `bc81d5d`

**5. [Rule 1 — Bug] A stale self-test description contradicting the fix**

- **Found during:** Task 1.
- **Issue:** `st_case 0 "$rc" "CONF-04 write side is a REPORT and always returns 0."` — after WR-06 it does **not** always return 0, and the function header said the same thing. A description a reader takes as the rule must not describe a rule the code no longer applies (the same correction 06-20 made to its `blind` message).
- **Fix:** both reworded to "returns 0 whenever it COULD LOOK", with a pointer to where the negative pair is driven.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Committed in:** `bc81d5d`

**6. [Rule 3 — Blocking] The plan's line citations were stale, as the prompt predicted**

- Every `<read_first>` citation was off by 200–300 lines after 06-18's merge (`manifest_compare` cited at `:288-328`, actually `:372-412`; the verdict tail cited at `:2160-2175`, actually `:2394-2401`; `:1843` for the pipeline, actually `:2018`). `phase06-incremental-control.sh:186` for the empty-manifest guard is at `:200`. Resolved by `grep -n` against anchor text throughout, as the prompt directed. No content was affected.

---

**Total deviations:** 6 (3 × Rule 1, 2 × Rule 2, 1 × Rule 3)
**Impact on plan:** No scope creep. Two are corrections to verification method (mine and the plan's); three extend the plan's own fixes to states of the same defect family its site list missed; one is a stale-citation correction. Every acceptance criterion in all three tasks is met.

## Issues Encountered

- **The plan's verify blocks were unrunnable as written** (deviation 1) — the fourth consecutive plan in this phase's gap closure to hit this. It is now unambiguously systemic in this phase's plans, not incidental: 06-15, 06-18, 06-20 and 06-19 all found it, and in this plan all *three* named shapes were present in the same two blocks.
- **A verify that bans a character must know the grammar.** Deviation 2 is the mirror: I introduced a false red of exactly the kind I was auditing for, by banning `|` in a program whose correctness depends on `||`. The cure is the same one that works for the planner's version — drive the assertion red *and* confirm the control passes, before trusting it.
- **No other problems.** `shellcheck -S warning` was clean before and after; the 21 default-severity notes are pre-existing and triaged in the artifact, and none of the three functions this plan added is among them.

## NOT-DRIVEN register (for plan 06-21)

Seven items are **asserted by construction** — review-by-reading plus `bash -n` and `shellcheck` — rather than by a firing observation. Full text in `artifacts/06-19-oracle-vacuity-driven.txt` § 9.

| # | Item | Condition that would drive it |
|---|------|-------------------------------|
| 1 | **WR-01 inside the container**: the container's dash (the self-test uses macOS `/bin/sh`), `docker exec`'s propagation of exit 4 into `RSH_RC`, and a `$SCRATCH` unreadable by `beetle` specifically | `/tmp/p6` present and root-owned 0700 inside `beets-flask` — the state an aborted run between step 5 and step 12 actually leaves — before a `--run`. It is a refusal path, so a wrong construction can only refuse a run that would otherwise proceed |
| 2 | The four new refusals **from a real oracle run** (WR-02, WR-06, IN-12, IN-09 are driven over synthetic fixtures only) | Respectively: an empty sampled source folder; a `beet ls` that produces no output; the same; a `06-SAMPLE.md` whose S5 rows sum to zero. None is reachable from this phase's committed sample — which is exactly why all four sat undetected |
| 3 | The **doubled UNKNOWN** for an empty `fields.tsv` seen adjacent in one transcript | A live run whose `beet ls` returns nothing. Driven at the function level for both sites |
| 4 | `assert_field_view`'s **bad-column arm from a real path containing a tab** | A destination path with a literal tab. Behaviour is unchanged from the inline code; only the empty-input arm is new |
| 5 | The `notadir` arm **at the call site** (driven at the program level) | `$SCRATCH` existing as a regular file inside the container |
| 6 | The `*)` **unrecognised-answer** arm | Undriveable by design while the probe and the call site agree — it exists to catch a future edit that makes them disagree |
| 7 | The **exit-code numbering difference** between the two sibling scripts | Not a finding, not addressed; recorded so it is not mistaken for one |

## Known Stubs

None.

## Threat Flags

None. This plan touches no network endpoint, no auth path and no schema. Every behavioural change moves strictly toward refusing: four new refusal branches, one report re-routed from green to UNKNOWN, one in-container pipeline removed, and two comment blocks. The one remote command it changed — the dirty-destination probe — is read-only (`find -mindepth 1 -maxdepth 1`), and the destructive knobs' fences from 06-18 are untouched and still driven by `--self-test`.

The plan's `<threat_model>` assigns `mitigate` to T-06-100 through T-06-106; all seven are mitigated as written, with T-06-103 (WR-01) carrying the NOT-DRIVEN caveat above and T-06-106 (re-running the oracle during a paper phase) satisfied by there having been no `--run` and no `--baseline`.

## Authentication gates

None. No credential was needed and none was used: every drive is local.

## Verification

| Check | Result |
|---|---|
| `bash -n` | exit 0, no output |
| `shellcheck -S warning` | exit 0, no output (0.11.0) |
| `--self-test` | exit 0, **111 / 111**, zero regressions (79 before) |
| `grep -c VACUOUS` (comment-stripped) | **2** — `assert_no_compilations` and `assert_dj_count` |
| EXIT CODES block | bounded at 24 lines; states the precedence, gives the reason, names the sibling |
| stated order matches implementation | `UNKNOWNS" -ne 0` at `:2708` precedes `REDS" -ne 0` at `:2712` |
| in-container pipelines | none — the probe carries `||` only; the two `ls -A … \| head` occurrences are the self-test's DRIVEN RED, run with local `/bin/sh` |
| corrected verify, tasks 1+2 and task 3 | both OK, rc 0 |
| verify driven red | 8 mutations fire, unmutated control passes |
| oracle `--run` / `--baseline` | **none performed** |
| `git status --porcelain` | empty |

## Next Phase Readiness

- **IN-08 is now complete on both halves.** `phase06-oracle.sh` and `phase06-incremental-control.sh` each state the convention and name the other. Plan 06-20 asked that it not be marked satisfied before this landed.
- **CONF-03 / CONF-06 evidence is untouched.** `artifacts/06-11-oracle-run.txt` and `06-11-wrote-nothing.txt` stand. Every change here is to a refusal branch and can only make a future run redder.
- **No estate contact.** No ssh, no docker, no `--run`, no `--baseline`. LXC 100 was not touched by this plan, and the host's `c67d497` checkout was not pushed to or pulled from.

## Self-Check: PASSED

Every claim re-measured after the fact, not restated.

| Claim | Check | Result |
|---|---|---|
| `scripts/phase06-oracle.sh` modified | `[ -f … ]` | FOUND |
| `artifacts/06-19-oracle-vacuity-driven.txt` created | `[ -f … ]` | FOUND |
| `06-19-SUMMARY.md` created | `[ -f … ]` | FOUND |
| Commits `bc81d5d`, `cfec2ec`, `a17d078` | `git log --oneline` | all FOUND |
| `--self-test` exits 0, 111 cases | re-run | rc 0, `111 case(s)` |
| 79 → 111 | counted `(expected):` lines in both transcripts | 79 before, 111 after |
| `bash -n`, `shellcheck -S warning` clean | re-run | rc 0, rc 0 |
| no file deleted by any of the three commits | `git diff --diff-filter=D` per commit | none |
| nothing outside `scripts/phase06-oracle.sh` and this phase's `.planning/` | `git status` + `git show --stat` | confirmed |

`STATE.md` and `ROADMAP.md` were deliberately **not** modified — the orchestrator owns those writes after the wave merges.

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-22*
