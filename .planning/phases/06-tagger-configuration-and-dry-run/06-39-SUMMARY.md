---
phase: 06-tagger-configuration-and-dry-run
plan: 39
subsystem: planning-record
tags: [gap-closure, round-4, disposition-register, id-namespace-collision, record-not-a-re-close]
gap_closure: true
gap_closure_round: 4
closes_findings: []
requires:
  - "06-35, 06-36, 06-37, 06-38 (round 4's four fix plans, all merged to main)"
provides:
  - "06-DISPOSITIONS-GAP3.md — the ten-row round-4 disposition register with the WR-*/IN-* -> R4-* mapping table"
  - "06-REVIEW-GAP3.md WIRED to that register, by pure append"
  - "DEF-06-39-01..06 carrying round 4's residue and its refusals"
  - "ROADMAP and STATE describing round 4 accurately, edited by hand"
affects:
  - ".planning/ROADMAP.md"
  - ".planning/STATE.md"
tech-stack:
  added: []
  patterns:
    - "a review's ID namespace must be unique per round and chosen BEFORE the review is written — these IDs become permanent in-band citations"
    - "a pin over a set with environment-conditional members must adjust where the condition is decided, or it is a constant pretending to be an invariant"
    - "BSD grep parses a leading `-` in a pattern as an option and exits 2; `-e` is load-bearing on any pattern starting with a dash"
key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP3.md"
  modified:
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP3.md"
    - ".planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md"
    - ".planning/ROADMAP.md"
    - ".planning/STATE.md"
decisions:
  - "R4-04 recorded as FIXED (undriven) — 06-37 asked for 'FIXED — code half undriven', which is not one of the four permitted words; the closed vocabulary's name for that condition is FIXED (undriven), the same grade its ancestor R3-09 carried"
  - "134 recorded as a CORRECTION to the source material, not a silent re-pin: the re-measured base is 140 and the finding's conclusion is unaffected"
  - "06-REVIEW-GAP2.md and 06-DISPOSITIONS-GAP2.md deliberately NOT edited despite both carrying the stale 134 — they are dated records"
  - "the operator's 'GAP-CLOSURE ROUND 5' label in STATE.md corrected in band to round 4 rather than deleted"
  - "ROADMAP and STATE edited by hand with Read+Edit; no gsd-sdk state.* or roadmap.* verb was run"
metrics:
  tasks: 3
  commits: 3
  files_changed: 5
  completed: 2026-09-23
---

# Phase 06 Plan 39: Round 4's Record — Summary

**All ten findings of `06-REVIEW-GAP3.md` carry an explicit disposition and an explicit fix-kind in
one register whose counts reconcile three ways, under both their review ID and their in-band `R4-*`
alias; the review is wired to it; round 4's residue and its three refusals are carried as a new
`DEF-06-39-*` series that renumbers nothing; and ROADMAP and STATE describe the round accurately —
by hand, closing nothing.**

## Stated explicitly, because the plan requires it

- **No verification was run.** Plan 06-39 did not invoke `/gsd-verify` and **claims no verification
  result**. `/gsd-verify 06` has not been run since round 2.
- **No requirement checkbox moved.** `REQUIREMENTS.md` is untouched and shows clean in
  `git status`. `- [ ] **CONF-04**` stands, measured at 1 occurrence.
- **CONF-04 remains OPEN** on its Jellyfin half, and Phase 7 entry criterion **E6** still owns the
  discharge. Its two verdicts — Jellyfin pending, Music Assistant discharged — are never summed.
- **`06-VERIFICATION.md` is STALE and was not touched.** It records round **1's** closure, dated
  2026-09-22, with `status: passed` and `gaps_remaining: []`, written before rounds 2, 3 and 4
  existed. It shows clean in `git status`.
- **The phase is NOT declared complete.** That is the verifier's call.

## The counts

| Route | Figures | Total |
|---|---|---|
| The review's own frontmatter | 0 Critical + 6 Warning + 4 Info | **10** |
| Dispositions | 9 FIXED + 1 FIXED (undriven) + 0 ACCEPTED + 0 CARRIED | **10** |
| Fix kinds | 3 CODE + 3 CLAIM CORRECTION + 4 BOTH | **10** |

Every figure was read off `06-35-SUMMARY.md`, `06-36-SUMMARY.md`, `06-37-SUMMARY.md` and
`06-38-SUMMARY.md`, not from this plan. The plan carried a cross-check expectation of *roughly*
3 CODE / 3 CLAIM CORRECTION / 4 BOTH to be overridden by the summaries if they disagreed — **they did
not disagree**, and that agreement is recorded in the register rather than the plan's number being
reused.

**Ownership:** 06-35 R4-01/R4-07/R4-08, 06-36 R4-02/R4-06/R4-09/R4-10, 06-37 R4-03/R4-04,
06-38 R4-05. **No cross-family adjudication ran this round** — round 2 had one, rounds 3 and 4 did
not, stated explicitly because an absent adjudication nobody mentions reads like a lost one.

## The ID namespace collision, measured

Round 4's report reuses **round 1's** `WR-*`/`IN-*` namespace, and round 1's IDs are already cited in
band in all four reviewed scripts. Measured at HEAD with `/usr/bin/grep -cF`:

| File | Round-1 in-band hits for IDs round 4 reuses |
|---|---|
| `scripts/quick-health-check.sh` | `WR-01` 7, `WR-02` 1, `WR-03` 5, `WR-05` 2 |
| `scripts/phase06-oracle.sh` | `WR-01` 4, `WR-02` 2, `WR-06` 6 |
| `scripts/check-beets-config.sh` | `WR-04` 2, `IN-01` 1, `IN-03` 1 |
| `scripts/phase06-incremental-control.sh` | `IN-02` 1 |

At the review's own `diff_base` `fff070a` — so round 4's edits cannot inflate it —
`/usr/bin/grep -coE 'WR-0[1-9]|IN-0[1-9]'` returns **35 / 28 / 5 / 4**, i.e. **72** pre-existing
citations in that namespace across the four files round 4 reviewed. None of them has anything to do
with round 4: `WR-01` in `quick-health-check.sh` is the 2026-09-14 `extended.conf`
destructive-switches finding; `WR-06` in `phase06-oracle.sh` is the CONF-04 write-side report
finding.

The register carries the full mapping table **immediately after the Source table**, plus the recipe
to re-derive the counts rather than pinning them (this file's own subject matter). The alias table is
also the **first thing** in `06-REVIEW-GAP3.md`'s wiring block, because that is where a reader
following a `WR-02` citation lands.

## What was done

**Task 1 — `a4f42fd`.** `06-DISPOSITIONS-GAP3.md`, mirroring `06-DISPOSITIONS-GAP2.md`'s structure:
*Why this file exists* → *Source* → **the ID mapping table** → *Counts* → the closed vocabulary → ten
rows in ID order grouped Warnings then Info → *What was driven and what was not* →
*Verified-and-clean, closed against a round 5* → *Corrections to the source material* → *What this
register does NOT do* → *Lessons*. Every row carries both IDs, a disposition from the closed
four-word vocabulary, a fix kind, the owning plan, the commit, the artifact path, and a **provenance
clause** distinguishing grep-verified from executed from statically reasoned.

**Task 2 — `2cded38`.** A wiring block appended to `06-REVIEW-GAP3.md` (**107 insertions, 0
deletions** — a pure append; all six `### WR-` and four `### IN-` headings and the frontmatter counts
verified unedited), and six new `DEF-06-39-*` entries (**250 insertions, 0 deletions**).

**Task 3 — `be1e8ac`.** ROADMAP (**71 insertions, 6 deletions**) and STATE (**89 insertions, 4
deletions**), both edited by hand.

## The register's four load-bearing judgement calls

**1. R4-04 is `FIXED (undriven)`.** `06-37-SUMMARY.md` asks for it to be carried as *"FIXED — code
half undriven"*, which is not one of the four permitted words. The closed vocabulary's name for
exactly that condition is **FIXED (undriven)** — the same grade R3-09, this finding's direct
ancestor, carried in round 3's register. The nuance is preserved in full in the row: the handler
*shape* was driven under `/bin/dash` in both directions with a positive control; the *delivery* of
SIGPIPE by the container transport was never observed and is graded BELIEVED. **No fifth disposition
word was invented** (`grep -ciF 'PARTIALLY FIXED'` = 0).

**2. `ST_PLANNED_CASES=134` was already stale, and that is a correction, not a re-pin.** The review,
the 06-36 plan, `06-DISPOSITIONS-GAP2.md` and `06-REVIEW-GAP2.md` all record 134. Plan 06-36
re-measured the base by **ablation** and got **140** — 134 plus the six cases R4-06 added in the same
round. The finding's conclusion is entirely unaffected: a fixed constant compared with `-ne` against
a set with environment-conditional members is not an invariant, whatever the constant is. Recorded
the way round 2 recorded the GC-15/GC-17 label crossing — **in band, not silently, and not as a
downgrade of the finding**.

**3. The three documents carrying 134 were deliberately NOT edited.** `06-REVIEW-GAP2.md` and
`06-DISPOSITIONS-GAP2.md` are dated records of round 3; `06-REVIEW-GAP3.md` is a dated record of
round 4. The live figure is in the script, beside the constant, with its reference environment named.
Editing a shipped review is how round 2's label crossing happened.

**4. STATE's "GAP-CLOSURE ROUND 5" label was corrected in band, not deleted.** The operator's
decision paragraph called the round against `06-REVIEW-GAP3.md` "round 5"; it is the phase's fourth
gap-closure round. The label is corrected with a parenthetical saying so, because an off-by-one
silently removed is exactly the kind of thing a later reader reconstructs wrongly.

## Instruments re-measured at HEAD by this plan

Not carried forward from any plan's text:

| Instrument | Result |
|---|---|
| `phase06-oracle.sh --self-test` | exit **0**, **140** announced cases — base now **skip-aware** |
| `check-beets-config.sh --self-test` | exit **0**, **7** cases (6 red) |
| `phase06-incremental-control.sh --self-test` | exit **0** |
| `bash -n` on all four scripts | clean |
| `sh -n` **and** `/bin/dash -n` on both extracted in-container programs | clean |

The oracle's base is valid only in the **named reference environment**: macOS 27.0 (darwin), non-root
(uid 501), `python3` PRESENT, bash, BSD grep at `/usr/bin/grep`, BWK awk. The heredoc parse is the
gate `bash -n` cannot give, since it parses heredocs as data.

## The `DEF-06-39-*` series

**30 → 36 entries. Every pre-existing series present at exactly its committed count, derived from
HEAD rather than typed:** `DEF-06-21-*` **8**, `DEF-06-29-*` **11**, `DEF-06-34-*` **6**. Nothing
renumbered, reworded or removed; the file's diff is 250 insertions and **0 deletions**.

| ID | Subject |
|---|---|
| `DEF-06-39-01` | the ID namespace collision, the measured counts, and the per-round-unique-namespace rule — with the revisit condition that a round 5 be given `R5-*` **before** it is written |
| `DEF-06-39-02` | **REFUSED ×3**: no cleanup `trap` on `phase06-oracle.sh` (R4-10); `ST_PLANNED_CASES=7` excluded from the count audit by name; the four layer-3 copies not hoisted (per `DEF-06-29-03`) |
| `DEF-06-39-03` | the announced-case base is environment-dependent; the reference environment named; the two things ablation did **not** prove; a fourth skip would go undetected (`-ge 3` is a floor, not a census) |
| `DEF-06-39-04` | the container-side signal behaviour unobserved on **both** paths, graded NOT ESTABLISHED / BELIEVED / unclosable; cross-references `DEF-06-34-06` for SIGKILL; attaches to the **existing** **E12** |
| `DEF-06-39-05` | `quick-health-check.sh` executed **zero** times in round 4 either; every assertion is a capture or a grep; cross-references `DEF-06-29-11` for why a live run today would be uninformative |
| `DEF-06-39-06` | the self-referential-count hazard has migrated into the `<automated>` verify blocks (06-38's `F-06-38-01`/`F-06-38-02`) |

**Nothing already owned was duplicated.** `DEF-06-29-01`, `DEF-06-29-09`, `DEF-06-29-11`,
`DEF-06-34-04`, `DEF-06-34-06` and **E6** are referenced by name where relevant and not re-opened.
**No new Phase 7 entry criterion was added** — the live-run part attaches to the existing **E12**.

## The Notes cell survived

The Phase 6 milestone Notes cell is the exact thing the SDK verb blanked three times in this project.
It was **appended to, not rewritten**: still a single line, **5177 → 8018 bytes** (floor derived from
HEAD, not typed), with its round-1, round-2 and round-3 sentences all intact (`Round 2 COMPLETE` and
`Round 3 COMPLETE` both still present). The plan-count cell moved `34/34` → `39/39`, consistent with
the plan-count line's **39 plans in 17 waves** — verified against 38 committed `06-NN-SUMMARY.md`
files plus this one.

## What was NOT driven — the summary this record must not flatten

Ten undifferentiated `FIXED`s would reproduce, one level up, the exact over-claim the review is
about. Carried per finding in the register and summarised there:

1. **`scripts/quick-health-check.sh` was executed ZERO times** — by the review and by plan 06-35.
   Every R4-01 / R4-07 assertion is a capture (`echo`, never sent, re-parsed locally with `set --`)
   or a grep. The capture is a faithful model of the remote word splitting, and it is a **model**.
2. **The oracle's layer-3 block is reachable only from a live `--run`.** R4-06's six new cases prove
   the **parser**, not the block, the remote `sha256sum` invocation, `dex_cmd`'s rendering, or the
   container's output format. Same residue `DEF-06-34-04` already owns.
3. **The container-side signal behaviour is unobserved inside `beets-flask` on both paths.** The
   local `dash` drive proves the **handler shape**, not the **delivery**.
4. **Three findings closed with zero executable change** (R4-05, R4-08, R4-10), one proved
   mechanically: 0 non-comment changed lines and byte-identical `--self-test` output (`cmp` rc 0),
   with the comparison's determinism established first by a double run against the unedited tree.
5. **The root and `python3`-absent conditions were ABLATED, not entered.** Nothing ran as uid 0; the
   interpreter was never removed.

## Deviations from Plan

### 1. [Rule 1 — Bug] This plan's own task-3 verify block could not run: BSD grep parses the leading `-` as an option

- **Found during:** Task 3 verification.
- **Issue:** the block asserts `test "$($G -cF "- [x] $p-PLAN.md" $R)" -eq 1` for each of the five
  plans. On BSD grep — `/usr/bin/grep` on this workstation — a pattern beginning with `-` is parsed
  as an option: the command exits **2** with a usage message, and under `set -eu` the block aborts
  **for the wrong reason**, before testing anything. **The plan text names this exact trap eleven
  lines further down**, on the CONF-04 assertion, and explains why `-e` is load-bearing there — and
  then omits `-e` on the five tick assertions above it.
- **Fix:** added `-e` to the five tick assertions, with the reason inlined as a comment. Nothing else
  in the block changed; every other assertion ran byte-for-byte as written and passed.
- **Files modified:** none — the substitution is in the executed verify harness, not in any repo
  file. No ROADMAP or STATE content was changed to satisfy a test.
- **Verification:** all five ticks confirmed present at exactly 1 occurrence each.

**This is `DEF-06-39-06` firing again inside the round that records it** — a verify block that could
not pass at the tree it was written against, in the plan whose own lesson section says to sweep the
`<automated>` blocks before executing. It is the third such instance this round (06-36's `| grep -q`
count, 06-38's raw-count assertion, and this one), and like both of the others it was caught by
**running the block**, not by reading it.

### 2. [documented, not a deviation in outcome] `state.begin-phase` corrupted STATE.md before this plan started

The orchestrator ran `gsd-sdk query state.begin-phase` at the start of this execution, and it
corrupted STATE.md exactly as the file's own standing warning predicts: it replaced only the **first**
line of two multi-line fields, orphaning both continuations (`dispositioned all 24 findings of
06-REVIEW.md; …` left without a subject; `against 06-REVIEW-GAP.md …` likewise), deleted
`last_activity` from the frontmatter, and inserted stray blank lines into an unrelated list hundreds
of lines away. That change was reverted with `git checkout` before this plan ran, so the file on disk
was the good pre-execution version. **This plan ran no `state.*` or `roadmap.*` verb of any kind**;
both files were edited with Read + Edit and both diffs were read in full — bodies, not `--stat` —
before committing. The measured result: STATE 4 deleted lines, **all four intentional and named in
the commit message**, with the multi-line `Plan:` field's continuation left attached; ROADMAP 6
deleted lines, being the five unticked plan lines and the milestone row.

**Total deviations: 1 auto-fixed (a defect in this plan's own verify block), 1 recorded environment
fact.** Neither changed what was written.

## Scope

- No estate contact: no ssh, no docker, no `--run`, no `--arm`, no `git push`, no host `git pull`.
- No file under `scripts/` was touched. `scripts/setup-neocortex-memory.sh`,
  `stacks/selfhosted/neocortex-memory/` and `stacks/selfhosted/agentic-os/` untouched.
- `06-REVIEW.md`, `06-REVIEW-GAP.md` and `06-REVIEW-GAP2.md` were **not** touched — ten files cite
  round 1's record, and rounds 2 and 3 are wired to their own registers.
- `REQUIREMENTS.md` and `06-VERIFICATION.md` both clean in `git status`.
- `06-REVIEW-GAP3.md` and `deferred-items.md` were **appended to only**: 0 deletions in each.

## Known Stubs

None. This plan produces a record; it wires no data path and introduces no placeholder.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change at a trust boundary
was introduced — this plan writes and edits Markdown under `.planning/` only. All seven threats in
the plan's `<threat_model>` carry `mitigate` except `T-06-39-SC` (`accept`; this plan installs
nothing), and all six mitigations are applied: per-finding rows with provenance (T-06-R4REC), the ID
mapping table plus `DEF-06-39-01` (T-06-R4ID), the fix-kind column and the not-driven notes
(T-06-R4OVER), the refusal entries (T-06-R4REF), `06-VERIFICATION.md` named stale in three places and
asserted untouched (T-06-R4VER), and hand edits with both diffs read and the Notes-cell floor derived
from HEAD (T-06-R4SDK).

## Commits

| Commit | Task | Subject |
|---|---|---|
| `a4f42fd` | 1 | the ten-row round-4 disposition register with the ID mapping table |
| `2cded38` | 2 | wire `06-REVIEW-GAP3.md` to its register and carry round 4's residue as `DEF-06-39-*` |
| `be1e8ac` | 3 | tell ROADMAP and STATE the truth about round 4, by hand |

## Next

**`/gsd-verify 06`.** Whether a *fifth* review — of round 4's own diff — is warranted is stated both
ways in STATE and in the ROADMAP disposition paragraph, as the operator's call and not this plan's.
If one is commissioned: give it a fresh `R5-*` namespace **before** it is written (`DEF-06-39-01`),
and sweep its `<automated>` blocks for raw self-referential counts **before** executing
(`DEF-06-39-06`).

## Self-Check: PASSED

Verified after writing, not assumed. Every figure below was re-measured at HEAD.

**Files claimed, checked on disk:** `06-DISPOSITIONS-GAP3.md`, `06-REVIEW-GAP3.md`,
`deferred-items.md`, `06-39-SUMMARY.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — all FOUND.

**Commits claimed, checked in `git log`:** `a4f42fd`, `2cded38`, `be1e8ac`, `a52ad7d` — all FOUND.
**None of the four deleted a tracked file** (`git diff --diff-filter=D` empty for each).

**Counts re-measured, against the figures this summary states:**

| Claim | Measured | Expected |
|---|---|---|
| `06-NN-SUMMARY.md` files on disk | **39** | 39 |
| `^## DEF-` entries | **36** | 36 (30 + 6) |
| `^## DEF-06-39-` entries | **6** | 6 |
| `DEF-06-21-*` / `DEF-06-29-*` / `DEF-06-34-*` | **8 / 11 / 6** | unchanged from HEAD |
| `^### WR-` / `^### IN-` in the review | **6 / 4** | 6 / 4, unedited |
| Phase 6 Notes cell | **8018 B**, one line | > 5177 B at HEAD |
| `- [ ] **CONF-04**` in `REQUIREMENTS.md` | **1** | 1, untouched |
| `PARTIALLY FIXED` in the register | **0** | 0 — no fifth word invented |

**Scope re-measured:** `git diff --name-only 57f9bae..HEAD` lists **exactly six** files — the four
record files plus ROADMAP and STATE. **No file under `scripts/` was touched.** `REQUIREMENTS.md` and
`06-VERIFICATION.md` both show clean in `git status`. `06-REVIEW.md`, `06-REVIEW-GAP.md` and
`06-REVIEW-GAP2.md` do not appear in the diff.

**Append-only assertions:** `06-REVIEW-GAP3.md` 107 insertions / **0 deletions**;
`deferred-items.md` 250 insertions / **0 deletions**.

**Verify blocks:** all three tasks' `<automated>` blocks re-run against the committed tree and reach
their end at exit 0 — task 3's with `-e` added to its five tick assertions, the one documented
substitution, recorded as deviation 1 above.

**Working tree clean; no untracked files left behind.**
