---
phase: 06-tagger-configuration-and-dry-run
plan: 21
subsystem: documentation
tags: [code-review, dispositions, roadmap, carry-forward, wr-09, cr-01, wiring]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-REVIEW.md's 24 findings, 06-VERIFICATION.md's NOT WIRED row, and the recorded outcomes of gap-closure plans 06-15 through 06-20"
provides:
  - "06-DISPOSITIONS.md: a 24-row register, one per finding, on a closed four-word vocabulary, with per-class counts that sum to 24 and the sum stated"
  - "06-REVIEW.md is WIRED: an appended dated block naming the register, the plans and the verification; finding text and frontmatter counts byte-unchanged"
  - "ROADMAP Phase 7 entry criteria E10 (CR-01's residue) and E11 (WR-09), reachable from where the next phase reads"
  - "deferred-items.md: DEF-06-21-01..08 — the WR-09 carry, one per FIXED (undriven) finding, the two weakest links 06-16 and 06-17 nominated, and the systemic plan-verify defect class"
  - "stacks/selfhosted/arrs/beets.md: the uncovered /downloads:rw + 01-auto write path stated in the runbook, where someone stands before dropping a folder into an inbox"
affects: [phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A closed disposition vocabulary with a mandatory FIXED (undriven) class — a FIXED recorded for a branch nobody has seen fire manufactures confidence"
    - "Derive the per-class counts FROM the table rows, then assert the header's stated counts equal them: a typed count drifts and then reads as authority"
    - "A multi-word assertion over markdown prose must run against a JOINED copy — grep is line-oriented and the phrase wraps"
    - "When an acceptance criterion names a string that does not exist, the obvious repair (write the string in) may be the exact change the criterion existed to prevent"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS.md
  modified:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW.md
    - .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md
    - .planning/ROADMAP.md
    - stacks/selfhosted/arrs/beets.md

key-decisions:
  - "IN-03 and IN-07 are classified FIXED (undriven) on this plan's judgement, not 06-15's — 06-15 recorded them retired and said nothing about driving them, and applying the vocabulary's own test to a branch no run reached is the honest reading"
  - "WR-09 is CARRIED, not ACCEPTED: it has a scheduled owner (E3) and a named decision point, which is not the same as a reason to leave it alone. ACCEPTED is therefore ZERO across all 24 findings"
  - "A drive over a synthetic fixture counts as driven; the evidence cell names the fixture and any outstanding real-run drive is recorded as residue rather than upgraded into the disposition"
  - "The Phase 6 status row's Notes cell gained a dated clause; the orchestrator-owned `20/21` and `In Progress` cells were NOT touched, reconciling the plan's Edit 2 with the orchestrator's ownership of that row"
  - "config.yaml was not edited, as the threat model requires — WR-09's stronger fix would change the sha256 of the object every CONF-01/02/05 proof was measured against"

patterns-established:
  - "Count table ROWS, never file-wide token occurrences: the vocabulary section spells every disposition word, so a bare grep -c over the register inflates the class counts"
  - "Assert the wording that IS byte-present, not the wording a plan believes is present"

requirements-completed: []

# Metrics
duration: ~55min
completed: 2026-09-22
---

# Phase 6 Plan 21: Wiring the code review into the project's memory Summary

**All 24 findings in `06-REVIEW.md` now carry an explicit disposition — 19 FIXED, 4 FIXED
(undriven), 0 ACCEPTED, 1 CARRIED — recorded in a register the next phase can reach from two
named ROADMAP entry criteria, with the one finding nobody fixed (WR-09) stated in the runbook
where someone stands before dropping a folder into an inbox.**

## Performance

- **Duration:** ~55 min
- **Completed:** 2026-09-22
- **Tasks:** 2 of 2
- **Files:** 1 created, 4 modified. **No file deleted** (`git diff --diff-filter=D 591f00c..HEAD`
  is empty).

## The disposition class counts, quoted so a re-verification need not re-read the register

| disposition | count |
|---|---|
| FIXED | **19** |
| FIXED (undriven) | **4** |
| ACCEPTED | **0** |
| CARRIED | **1** |
| **sum** | **24** |

**19 + 4 + 0 + 1 = 24**, and the review's own frontmatter counts **1 + 10 + 13 = 24**. The two
totals agree. These figures are **derived from the 24 table rows by the verify**, which then
asserts the register's *stated* header counts equal the derived ones — so a typed count cannot
drift and then read as authority (mutation M9 proves that assertion fires).

## Which findings are closed, deferred, or recorded as deliberate non-findings

### CLOSED — fixed and driven (19)

| plan | findings |
|---|---|
| 06-15 | CR-01 (live half), WR-04, WR-05, IN-01, IN-04 |
| 06-16 | CR-01 (detector half), WR-10, IN-13 |
| 06-17 | WR-03 |
| 06-18 | WR-07, WR-08 |
| 06-19 | WR-01, WR-02, WR-06, IN-09, IN-12 |
| 06-20 | IN-02, IN-05, IN-10 |
| 06-20 + 06-19 | IN-08 (both halves; neither marked satisfied before the other landed) |

### CLOSED IN CODE BUT NOT DRIVEN (4)

Each names the condition that would drive it and carries a `deferred-items.md` entry. **This class
exists so that a written-but-unseen branch is not recorded as a proven one.**

| finding | plan | why undriven | deferred as |
|---|---|---|---|
| IN-03 | 06-15 | the corrected text is inside the readiness-gate **failure** branch; every run reached ready | `DEF-06-21-04` |
| IN-06 | 06-18 | `--self-test` never reaches step 5, where the run-tagged names are used | `DEF-06-21-02` |
| IN-07 | 06-15 | the whole loop is behind `if [[ -n "$EXTRA_FORBIDDEN_SUBSTRINGS" ]]`, default empty | `DEF-06-21-05` |
| IN-11 | 06-18 | needs a genuinely dirty `$SCRATCH` inside the live container | `DEF-06-21-03` |

**IN-06 and IN-11 were recorded as undriven by plan 06-18 itself. IN-03 and IN-07 are this plan's
classification, not 06-15's** — 06-15 listed them under "four hygiene findings retired" and said
nothing about driving them. Applying the vocabulary's own test (did a summary record the changed
branch firing?) to a branch no run reached gives `FIXED (undriven)`. Calling them `FIXED` would
have asserted a drive that did not happen. Flagged here because it is a judgement I made rather
than one I inherited.

### DEFERRED (1 finding, plus 3 residues and 1 systemic item)

| id | what | owner |
|---|---|---|
| `DEF-06-21-01` | **WR-09** — `import.write: yes` over a `:rw` `/downloads` with an `autotag: auto` inbox | ROADMAP **E11**, decided beside the `rw` grant (**E3**); stated in `beets.md` |
| `DEF-06-21-06` | the overlay-key half of `D04_EXEMPT_RE` — 06-16's own N-4, *"the obvious next drive"* | ROADMAP **E10** |
| `DEF-06-21-07` | the exit-3 arm's `📊 6. Summary` anchor guard — 06-17's own N-3, *"the weakest link"* | needs no estate contact; `CONSUMERS_SCRIPT` makes it driveable |
| `DEF-06-21-08` | the systemic **plan-verify defect class** (see below) | whoever plans the next phase |

**Why WR-09 is CARRIED and not ACCEPTED:** ACCEPTED means deliberately not changed. WR-09 *is*
going to be changed — it has a scheduled owner and a named commit to move in. Recording it as
ACCEPTED would have implied a decision to live with it. That is why **ACCEPTED is zero across all
24 findings**, which is itself worth noticing: no review finding was judged not worth changing.

### DELIBERATE NON-FINDINGS — recorded so they are not re-reported

1. **The exit-code numbering difference** between the two sibling instruments
   (`phase06-incremental-control.sh` UNKNOWN=2 / usage=3; `phase06-oracle.sh` UNKNOWN=3 /
   usage=2). IN-08 was about **precedence**, which is fixed; renumbering would invalidate
   committed evidence citing those codes. Left alone by 06-20, confirmed by 06-19.
2. **The D-04 block reports UNKNOWN on the live estate.** Correct — the host is at `c67d497`,
   pre-Phase-6, so the executable count there is genuinely 0 and the new vacuity guard rightly
   refuses.
3. **`quick-health-check.sh` will exit non-zero on the consumers block** once this phase is pushed
   and the host pulls, until E6 discharges CONF-04. Intended; the twelfth notice says so inline.

### Did any finding end with no disposition?

**No.** All 24 finding IDs (CR-01, WR-01…WR-10, IN-01…IN-13) carry exactly one disposition row in
`06-DISPOSITIONS.md`, in review order, each drawn from the closed four-word vocabulary. The verify
extracts the rows by pattern, counts them (**24**), asserts every one carries a vocabulary word,
and asserts no word outside the closed four appears in the disposition column. No summary recorded
an outcome that could not be classified, so nothing was forced into a class and nothing was left
out.

## Task Commits

1. **Task 1: the 24-row register, and `06-REVIEW.md` wired** — `22779bf` (docs)
2. **Task 2: E10/E11, the deferred entries, and the runbook statement** — `b739159` (docs)

## Nothing was re-closed

Asserted, not claimed:

- `REQUIREMENTS.md` — **not in the diff**. `- [ ] CONF-04` stands.
- `stacks/selfhosted/arrs/beets/config.yaml` — **not in the diff** (threat T-06-125).
- `.planning/STATE.md` — **not in the diff**; the orchestrator owns that write.
- The Phase 6 status row keeps `1 open requirement: CONF-04 is OPEN on its Jellyfin half`,
  `must never be summed` and the `tank/downloads@pre-phase5` sentence **byte-present** (asserted
  with `grep -qF`, and mutation N4 proves the assertion fires).
- E1 through E9 are present and unrenumbered; `git diff` on `ROADMAP.md` removes **no**
  `E<n>. **` line. The one deleted line is the status row, rewritten in place with its protected
  sentences intact.

**CONF-04's two verdicts are recorded separately and are never summed.** The E6 measurements
taken on 2026-09-22 (JF pending 3 / at target 0, MA reported 1 / at target 2, `FAILURES` 0) are
carried into the register as a record, not as a discharge.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Task 2's acceptance criterion and verify assert a string that has NEVER existed in `ROADMAP.md` — and the obvious repair would have made the forbidden change**

- **Found during:** Task 2, before any edit.
- **Issue:** Both the acceptance criteria and the verify require
  `grep -q "Closed — 1 open requirement" .planning/ROADMAP.md`. **That string does not appear
  anywhere in the file, and never has.** Measured: `grep -n 'Closed — 1 open requirement'` returns
  nothing on the base commit. The Phase 6 status row actually reads
  `| 20/21 | In Progress| Original 14/14 closed 2026-09-21 with **1 open requirement: CONF-04 is
  OPEN on its Jellyfin half** …`. The plan also cites the row at **two different line numbers**
  (`:1238` in `read_first`, `:1208` in the action); the real line is **1238**.
- **Why this one is dangerous rather than merely broken:** the verify fires a false RED, and the
  obvious way to make it green is to **write that string into the status row** — which would
  change the Phase 6 status wording, i.e. precisely the tampering the criterion and threat
  **T-06-123** exist to prevent. An unsatisfiable criterion that invites the forbidden edit is a
  worse shape than one that merely cannot pass.
- **Fix:** replaced with `grep -qF` assertions on the three sentences that **are** byte-present
  (the CONF-04 open-requirement clause, `must never be summed`, and the `tank/downloads@pre-phase5`
  sentence), **plus a new assertion** that the orchestrator-owned `| 20/21 | In Progress|` cells
  are unchanged — which the plan's version never checked at all. Strengthened, not relaxed.
- **Verification:** mutations N4 (soften the CONF-04 wording) and N5 (alter the status cell) both
  fire; the unmutated control passes.

**2. [Rule 1 — Bug] Task 2's verify uses an UNBOUNDED `awk` range whose start pattern occurs twice — the exact hazard the plan's own `read_first` warned about**

- **Found during:** Task 2.
- **Issue:** `awk "/Entry criteria inherited from Phase 6/,/^\*\*Plans\*\*/"` . The plan's
  `read_first` explicitly warns that `grep -n 'Entry criteria inherited from Phase 6'` **returns
  two hits** (Phase 7's first, Phase 9's second) — then its own verify uses a plain awk range,
  which **restarts at the second hit**. Measured: the range captures **96 lines** spanning both
  blocks and **11** `E<n>.` lines, where Phase 7's block alone is 77 lines and 9 criteria. So
  Phase 9's own `E1.` and `E2.` could satisfy the E1/E2 presence checks even if Phase 7's were
  deleted.
- **Compounding it:** the companion assertion `grep -cE "^  E[0-9]+\. \*\*" "$R" -ge 11` was
  **already true on the base commit** (9 + Phase 9's 2 = 11), so it could pass without E10 or E11
  existing at all — vacuous.
- **Fix:** bounded extraction (`/start/ && !st {st=1} st {print} st && /end/ {exit}`), the
  extract length-checked (40 < n < 200) so losing the delimiter is caught rather than silently
  restoring the runaway, an explicit assertion that the extract did **not** reach Phase 9's block,
  and the E-count required to be **exactly 11 inside the Phase 7 block** rather than ≥ 11
  file-wide.
- **Verification:** mutation N11 (remove the `**Plans**: TBD` delimiter) fires; N1 and N2 (E10
  removed, E9 renumbered) fire.

**3. [Rule 1 — Bug] Both of task 2's `git diff | grep -q` guards are false-GREEN generators**

- **Found during:** Task 2.
- **Issue:** `git diff --name-only | grep -q "REQUIREMENTS.md" && { exit 1; }` and
  `git diff ROADMAP.md | grep "^-" | grep -qE "E[1-9]\. \*\*" && { exit 1; }`, both under
  `set -o pipefail`. `grep -q` exits on its first match and closes the pipe; the upstream takes
  SIGPIPE; pipefail propagates **141**, which is non-zero, so the `&&` **never fires** — the guard
  silently passes **exactly when the violation is present**. This is the inverse of the familiar
  141 shape: here it manufactures a pass rather than a failure.
- **Fix:** both rewritten over temp files, with no pipeline carrying a verdict. The
  forbidden-file guard was widened from `REQUIREMENTS.md` alone to also cover
  `beets/config.yaml` (which the plan's acceptance criteria name but its verify never checked)
  and `STATE.md`, and it now reads the **staged** diff as well as the unstaged one.
- **Verification:** the guard's own logic exercised against a synthetic name list.

**4. [Rule 1 — Bug, mine] My first strengthened assertion was a false RED on correct prose — grep is line-oriented, markdown wraps**

- **Found during:** Task 2, running my own mutation harness: the **unmutated control failed**.
- **Issue:** I strengthened the E11 check from a bare `grep -q '01-auto'` (too weak — satisfied by
  the `/downloads/complete/nzb/_inbox/01-auto` path string alone) to a phrase match on
  `` `01-auto` inbox is registered ``. That phrase **wraps across two source lines** in the
  rendered criterion, and `grep` matches within a line, so it could never match correct text.
- **Fix:** multi-word assertions over prose now run against a **joined, whitespace-collapsed**
  copy of the extracted criterion (`tr '\n' ' ' | tr -s ' '`). The strengthened intent is kept;
  only the matching surface changed.
- **Recorded because** it is the same category I was auditing for, introduced by me while fixing
  it — 06-19 recorded the identical experience. **The cure is the same either way: drive the
  assertion red *and* confirm the control still passes, before trusting it.** My control failing
  is what caught this; had I only checked that mutations fired, I would have shipped a verify that
  can never pass.

**5. [Rule 1 — Bug, mine] Counting prose occurrences instead of table rows**

- **Found during:** Task 2, first run of the repaired verify.
- **Issue:** `fu=$(grep -c '**FIXED (undriven)**' 06-DISPOSITIONS.md)` returned **5** against **4**
  actual rows, because the register's vocabulary section and its § on how the classes were
  separated both spell the phrase. A false RED reporting "4 deferred entries for 5 findings".
- **Fix:** the class counts are extracted from the **table rows only** (a leading
  `| **<ID>** |` pattern), in both verifies. This is the same discipline the register itself
  applies: count the thing, not the mentions of the thing.

### Two no-op mutations, corrected (not deviations, but worth the line)

Two of my eleven task-2 mutations initially reported `rc=0` — **not because the verify was blind,
but because the mutations themselves could not fire**: `sed` is line-oriented too, so a mutation
targeting a wrapped phrase changes nothing. A mutation that does not perturb anything looks
exactly like an assertion that does not work. Both were retargeted at single-line substrings and
then fired. This is 06-15's deviation 5 in a different costume: **confirm the perturbation
happened before trusting what the run says about it.**

### Stale line citations (the fifth consecutive plan)

Every ROADMAP citation in this plan's `read_first` needed checking. `:1059-1134` for the Phase 7
block is right; `:1089`/`:1093`/`:1105` for E3/E4/E6 are right; but the status row is cited as
**`:1238`** in one place and **`:1208`** in another within the same plan, and the string it tells
me to match does not exist (deviation 1). Resolved by `grep -n` on anchor text throughout, per the
standing note.

---

**Total deviations:** 5 auto-fixed (all Rule 1) + 2 corrected no-op mutations + 1 citation note.
**Impact on plan:** No scope creep — every change is inside the five files the plan names.
**Three of the five were defects in the plan's own verification, and two were mine.** The plan's
three would have produced, respectively: a false RED whose obvious repair is the forbidden edit; a
vacuous check satisfiable by another phase's criteria; and a guard that silently passes when the
violation is present. In a plan whose whole purpose is recording honestly what was and was not
proven, that is worth stating plainly.

## Issues Encountered

None beyond the deviations. No estate contact was needed or made: this plan touches no runtime,
runs no instrument, and performs no ssh. The host remains at `c67d497` and **was not pushed to**.

## Verification Results

| Check | Result |
|---|---|
| All 24 finding IDs present, one row each, in review order | **24 rows**, verified by pattern extraction |
| Every row carries a word from the closed vocabulary | yes; no out-of-vocabulary word in the disposition column |
| Class counts derived from rows | FIXED 19 / undriven 4 / ACCEPTED 0 / CARRIED 1 — **sum 24** |
| Header's stated counts equal the derived counts | yes (M9 proves the assertion fires) |
| Reconciliation stated explicitly | `19 + 4 + 0 + 1 = **24**` and `1 + 10 + 13 = **24**` |
| Every FIXED / FIXED (undriven) row cites plan + commit + artifact | 23 of 23 |
| Every FIXED (undriven) row names its driving condition | 4 of 4 |
| Every CARRIED row names an existing target | 1 of 1 (`DEF-06-21-01`, **E11**) |
| The string `low priority` anywhere in the register | **absent** |
| `06-REVIEW.md` contains `06-DISPOSITIONS` | yes |
| `06-REVIEW.md` frontmatter | `critical: 1`, `warning: 10`, `info: 13`, `total: 24` — all intact |
| `06-REVIEW.md` diff | **32 additions, 0 deletions**, hunk `@@ -589,0 +590,32 @@` — appended after the `_Reviewed:` block |
| All 24 `### <ID>:` finding headings still in the review | 24 of 24 |
| Phase 7 block: E1–E11 present, none renumbered | **exactly 11** criteria, inside the bounded first block |
| Extraction did not reach Phase 9's block | asserted |
| Phase 6 status row: protected sentences byte-present | 3 of 3 (`grep -qF`) |
| Phase 6 status row: `\| 20/21 \| In Progress\|` unchanged | yes |
| `git diff` on ROADMAP removes no `E<n>. **` line | confirmed; 1 deleted line total (the status row, rewritten in place) |
| `REQUIREMENTS.md` / `beets/config.yaml` / `STATE.md` in the diff | **no** |
| Files changed vs base `591f00c` | exactly the 5 the plan names |
| Files deleted | **none** (`--diff-filter=D` empty) |
| **D-04 doc pin after the `beets.md` edit** | **still 2** — patterns extracted from the script and re-run; the only two doc-class lines remain the historic `beets.md:106`/`:170` quotations |
| D-04 executable / exempt / asserted after the edit | **8 / 5 / 3** — unchanged |
| Task 1 verify: mutations | **10 fire**, unmutated control passes |
| Task 2 verify: mutations | **11 fire**, unmutated control passes |
| Credential scan over all added lines | clean — no secret, token or password |

## Known Stubs

None. Every claim in the register cites a commit that resolves in `git log` and an artifact that
exists on disk; the four rows whose branches were never driven say so in their own class rather
than being written as proven.

## Threat Flags

None. This plan adds no network endpoint, no auth path, no file-access pattern and no schema
change. It is documentation only. T-06-126 (a credential entering the public runbook while
documenting the uncovered write path) was checked explicitly: the WR-09 statement names paths,
mount modes and inbox names only — see the credential scan above.

## Notes for Phase 7

- **E10 and E11 are the two new inherited criteria.** E10 carries CR-01's residue (the pinned
  exemption register — **do not raise the pin to make a run green**; `D04_DOC_BASELINE` is at 2
  and 06-16 rephrased its own prose rather than raise it). E11 carries WR-09 and is decided
  **in the same commit as E3's `rw` grant**.
- **`DEF-06-21-06` is the highest-value single drive left from the whole gap closure**, because it
  protects the fix for the phase's only Critical finding: plant an invocation in
  `phase06-oracle.sh` that does **not** carry the overlay substring, and confirm it lands in the
  **asserted** set, not the exempt set.
- **CONF-04 is not closed and was not touched here.** E6 still owns the discharge.
- **`DEF-06-21-08` is for whoever plans the next phase**, not for an executor: the plan-verify
  defect class is a planner-side problem, and this plan added two fresh shapes to the catalogue
  (an unsatisfiable criterion whose obvious repair is the forbidden edit; a line-oriented phrase
  assertion over wrapped markdown prose).

## Self-Check: PASSED

Every claim re-measured against the tree and the log, not restated.

| Claim | Check | Result |
|---|---|---|
| `06-DISPOSITIONS.md` created | `[ -f … ]` | FOUND |
| `06-REVIEW.md`, `deferred-items.md`, `ROADMAP.md`, `beets.md` modified | `git diff --name-only 591f00c HEAD` | all 4 FOUND, and **only** these plus the register |
| Commit `22779bf` | `git log` | FOUND |
| Commit `b739159` | `git log` | FOUND |
| Class counts 19/4/0/1 | derived from the rows by the verify, not typed | sum **24** |
| Both verifies against the committed state | re-run | `06-21 task 1 OK`, `06-21 task 2 OK`, rc 0 |
| Verify falsifiability | 10 + 11 mutations | all fire; both controls pass |
| No file deleted | `git diff --diff-filter=D 591f00c HEAD` | empty |
| `git status --porcelain` | after each commit | empty |
| Estate contact | none — no ssh, no push, no instrument run | host untouched at `c67d497` |

One claim was **corrected by this check rather than confirmed**: my first draft of the deviation
list described four deviations. Re-reading the mutation transcripts showed a **fifth** (deviation
5, counting prose occurrences instead of table rows) which I had fixed in passing without
recording — the same "written from memory instead of measured" failure 06-18 and 06-19 each caught
in their own self-checks.

`STATE.md` was deliberately **not** modified — the orchestrator owns that write.

---
*Phase: 06-tagger-configuration-and-dry-run, plan 21*
*Completed: 2026-09-22*
