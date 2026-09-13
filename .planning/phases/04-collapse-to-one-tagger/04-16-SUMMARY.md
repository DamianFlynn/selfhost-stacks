---
phase: 04-collapse-to-one-tagger
subsystem: docs
plan: 16
tags: [closure, interim-status, docs, d-25, gap-closure, criterion-3, open-verdict]

# The verdict this plan transcribed, re-derived here rather than carried in
window2_verdict: OPEN

# Dependency graph
requires:
  - plan: 04-15
    provides: "04-D12-EVIDENCE.md § 7 — the single line-anchored `Verdict (window 2): OPEN` and the OBS block behind it, committed at 4a4543f before host scratch was deleted"
  - plan: 04-14
    provides: "the incomplete-tree PRE-HOOK snapshot design and its eight-control self-test, named in the in-band note as the fix that was built"
  - plan: 04-13
    provides: "the heading-selection discipline this plan repeats — a heading chosen by a verdict line and enforced by the plan's own verify"
provides:
  - "stacks/selfhosted/arrs/beets.md — the estate's durable record beside the stack, headed to match the window-2 verdict, with criterion 3's table row carrying the literal token `window 2: OPEN` and its three source plans"
  - "a re-run of both standing guards against the LANDED text, with check-music-freeze.sh executed by name on LXC 100 rather than inferred from the quick-health-check fold-in"
  - "the phase's actual closing position written down: 4 of 5 criteria hold, criterion 3 OPEN after two windows"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A grep that selects a status word must be LINE-ANCHORED. The unanchored pattern `Verdict (window 2)` matches twice in the evidence file — the real verdict at line 470 and a blockquoted decoy at line 265 whose text contains the literal `PASSING`. `^Verdict \\(window 2\\): ` yields exactly one match; asserting that count is what makes the selection safe"
    - "Extract a status token with a DELIMITED match (`sed -nE 's/^Verdict \\(window 2\\): (PASS|OPEN|FAIL) —.*/\\1/p'`), never a bare prefix match, which reads `PASSING` as `PASS`"
    - "Asserting the heading is not enough — assert the table row too. A correct heading above a stale row leaves the file contradicting itself while the machine check still prints green"
    - "A screening filter must be proven to discriminate with BOTH a positive and a negative control before its number is believed (04-15 deviation 2: BSD sed silently ignores \\b)"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-16-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets.md

key-decisions:
  - "The interim-status heading was KEPT and re-dated, not replaced with a closure heading. The anchored verdict is OPEN, and this plan's own verify refuses a closure heading over a non-PASS verdict"
  - "The window-1 verdict blockquote and its mechanism paragraph were both retained. Deleting either would delete the finding, which is the more durable half of window 1"
  - "STATE.md and ROADMAP.md were deliberately NOT touched, per the plan's explicit prohibition and the 04-12/04-13 precedent — recorded as deviation 1 because it conflicts with the generic executor contract"
  - "No job sha256 prefix was written into beets.md at all. The OPEN branch does not require one, and the cheapest way to keep a public repo clean is to add nothing that needs screening"

requirements-completed: []  # TAGR-04's behavioural half remains unsatisfied: criterion 3 is OPEN.
requirements-advanced: [TAGR-04]

# Metrics
duration: ~25min
completed: 2026-09-14
---

# Phase 4 Plan 16: Record the Window-2 Verdict for Criterion 3 Summary

**The estate record beside the stack now states criterion 3's real outcome, and a machine chose the heading rather than an author: the line-anchored verdict is `OPEN`, so `beets.md` keeps an interim-status heading (`## Phase 4 — interim status (2026-09-14): criterion 3 OPEN`) and gains a dated in-band note recording that the incomplete-tree fix WAS built and self-tested against eight controls (04-14) and a second window DID run over three real jobs (04-15) — and still could not take the byte proof. Closure heading count is 0, asserted. Both standing guards are green against the landed text, with `check-music-freeze.sh` executed by name on LXC 100 (exit 0, `FAILURES total: 0`) against a checkout proven to contain the guard's own commit. Phase 4 closes at 4 of 5 criteria, and TAGR-04 is NOT complete.**

## Performance

- **Duration:** ~25 min.
- **Tasks:** 2 of 2.
- **Files:** 1 repo file modified (`stacks/selfhosted/arrs/beets.md`), plus this summary. Task 2 modified nothing — measurement only.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Select the heading from the verdict line and record window 2 in the criterion table | **`64e250b`** |
| 2 | Re-run both standing guards against the landed text and record the closing state | none — measurement only, no repo file modified |

**Plan metadata:** this SUMMARY's own commit.

## THE HEADLINE: the verdict was re-derived, and the parsing trap is real

`04-D12-EVIDENCE.md` matches `Verdict (window 2)` **twice**. Only one is the verdict:

| Line | What it is |
|---|---|
| **470** | The real verdict, line-anchored: `Verdict (window 2): OPEN — three music jobs …` |
| 265 | A **decoy** inside a blockquote, discussing how parsing must work. Its text contains the literal `Verdict (window 2): PASSING` |

Measured both ways, so the trap is recorded as demonstrated rather than described:

- `grep -c 'Verdict (window 2)'` (unanchored) → **2**
- `grep -cE '^Verdict \(window 2\): (PASS\|OPEN\|FAIL) — '` (anchored) → **1**, asserted as exactly 1 by the plan's own verify before anything was written
- `sed -nE 's/^Verdict \(window 2\): (PASS\|OPEN\|FAIL) —.*/\1/p'` → **`OPEN`**

The token was extracted with a **delimited** match, not a bare prefix match. A bare prefix match against the decoy line reads `PASSING` as `PASS` — which would have selected a **closure heading over an OPEN criterion**, the exact defect REVIEWS row 6 exists to prevent. The verdict was re-derived from the evidence file rather than taken from the orchestrator's hand-off or from 04-15's frontmatter, per the plan and per 04-12's lesson about trusting a handed-down figure.

Quoted verbatim as it stands at line 470:

> *Verdict (window 2): OPEN — three music jobs completed in the window and every side-effect condition and both ends of the § 3 prerequisite held, but none of the three published a PRE-HOOK snapshot, so all three are STATUS=UNPROVEN reason=no-attributed-pre with a zero-file intersection: under direct_unpack two of them never exposed a single audio file to a 1-second poll of the incomplete tree and the third was still growing when SABnzbd moved it, its one hash attempt refused mid-pass, so the "untagged by bytes" condition of § 1 item 4 is UNPROVEN and § 5 requires OPEN rather than PASS.*

## Task 1: the mapping, applied and asserted

**Heading:** `## Phase 4 — interim status (2026-09-13): criterion 3 OPEN` → `## Phase 4 — interim status (2026-09-14): criterion 3 OPEN`. Re-dated, **not** re-classified.

Measured on the written file, all asserted by the plan's verify:

| Assertion | Result |
|---|---|
| `grep -c '^## Phase 4 — one tagger'` (closure heading) | **0** |
| `grep -cE '^## Phase 4 — interim status'` | **1** |
| interim heading's trailing word equals the verdict word | **1** match on `…: criterion 3 OPEN$` |
| criterion row 3 appears | **1** time |
| row 3 carries the literal `window 2: OPEN` | **yes** |
| row 3 carries `04-12, 04-14, 04-15` | **yes** |
| `grep -c 'window 2'` over the file | **5** |
| census provenance line `ANSI stripped, otherwise unedited` | **1** |
| `📊 7. Summary` block vs `git show HEAD~1` | **byte-identical** (`diff` empty) |

Gate returned **`MAP-OK(OPEN)`**.

**The criterion-3 row was asserted, not just the heading.** This is round 2 row 16's finding: a correct heading above a stale row leaves the file contradicting itself while the machine check prints green. The row now reads `**\`window 2: OPEN\`** — quoted verbatim above. Three real jobs ran in the second window and none published a PRE-HOOK snapshot under \`direct_unpack\`, so the byte proof is UNPROVEN rather than violated; window 1's two jobs likewise ran clean with the byte proof untakeable`, sourced `04-12, 04-14, 04-15, \`04-D12-EVIDENCE.md\``. The literal token is what a grep can find, and it cannot be satisfied by accident by window 1's own `OPEN` elsewhere in the row.

### What the section now says, and what it deliberately does not

The opening paragraph gained window 2's verdict quoted verbatim and now reads **"OPEN after two observation windows"**. One factual correction was necessary and is called out rather than slipped in: the paragraph claimed the evidence file *"carries exactly one verdict line"*. **That was true when 04-13 wrote it and is now false** — the file carries one per window (§ 6 and § 7). It now says so.

The replacement for the "What closes it" sentence records, dated in band:

- **04-14 built the first of the two fixes that sentence named** — the PRE-HOOK snapshot moved into `/downloads/incomplete/`, structurally before SABnzbd's move and therefore before the hook, so the ordering no longer depends on comparing a millisecond watcher clock against a second-resolution log — and self-tested it against **eight** synthetic controls.
- **04-15 ran the second window**, 2026-09-13T22:04:18Z → 22:27:08Z, over **three** real music jobs.
- **The verdict is still OPEN, for a new reason.** None of the three published a PRE-HOOK snapshot: under `direct_unpack` two never exposed a single audio file to a one-second poll of the incomplete tree, and the third was still growing when SABnzbd moved it, so the watcher **refused** its one hash pass rather than publish a snapshot that had straddled the move. The section states this is the instrument failing **safe** — UNPROVEN, never a false FAIL.
- **"OPEN means the instrument could not look. It does not mean the estate is dirty."** Stated in those words, with the threefold-clean side-effect set behind it and window 2's positive control (when a folder genuinely rests, the watcher publishes complete).
- **What is still needed** is named: a capture point that survives `direct_unpack`, since both the destination tree (window 1's dead end) and a poll of the incomplete tree (window 2's) are ruled out. **The estate still needs nothing changed.**

**Not written:** no closure language, no claim the phase is complete, no upgrade of the verdict on the strength of the side-effect evidence, and **no job sha256 prefix at all** — the OPEN branch does not require one, and the safest text for a public repo is text that needs no screening.

### Deletions were confined, and the window-1 record survives

`git diff` reviewed line by line. **9 deletions, 46 insertions, 1 file, 0 files deleted.** Every deletion falls in one of the four sanctioned regions:

| Deleted | Region |
|---|---|
| `## Phase 4 — interim status (2026-09-13): criterion 3 OPEN` | the heading |
| 2 lines of the opening paragraph (`…recorded **OPEN**. Quoted from`, `line:`) | opening paragraph reflow |
| 5 lines from `**What closes it:**` to `…re-runs the whole test.` | the "What closes it" sentence |
| the old criterion row 3 | the criterion table |

**The window-1 verdict blockquote does not appear in the deletion set**, nor does any line of the window-1 mechanism paragraph (1139-1146a) — it is retained verbatim and now reads as the record of why the first attempt could not close the criterion. **No dated historical section was deleted**, and the executed census block is proven byte-identical rather than merely inspected.

### Public-repo screening, with a filter proven to discriminate

46 added lines screened. Following 04-15 deviation 2 (BSD `sed` silently ignores `\b`, so a screen written with word boundaries never runs and its number is meaningless), the filter was **proved with both controls before its output was believed**:

| Control | Expected | Measured |
|---|---|---|
| positive — a 64-char hex digest is filtered out | 0 runs | **0** |
| negative — a 50-char non-hex run survives | 1 run | **1** |

Results over the added lines: **0** runs of 40+ characters after 64-hex digests are filtered, **0** matches for `user_token|discogs\.env|/secrets/|token=|apikey|api_key`, and **0** release, artist, album or job-folder names.

## Task 2: both guards re-run against the LANDED text

Every result below is quoted from captured output, not inferred from an exit code — 04-13 deviation 2 recorded a `tail -25` truncating the exact line an acceptance criterion named, leaving an exit code reachable for more than one reason.

### `scripts/quick-health-check.sh` from the workstation — exit **0**

38 lines captured. Quoted:

- Drift line, line 10: `  ✅ vendored files match (3): audio.bash, sabnzbd beets-config.yaml, survivor config.yaml`
- Census counters, lines 16-23: `tagger definitions: 1`, `beets databases: 1`, `tagger databases: 0`, `retired paths present: 0`, `rw on Music, non-tagger: 0`, `rw on Music, tagger-capable: 0`, `rw on Music, Jellyfin D-21: 1`, `tagger-capable containers: 2`
- Consumers, line 28: `FAILURES total: 0`; transcode retention, line 38: `FAILURES total: 0`
- **The only `❌` is line 8, `Traefik dashboard: ❌ Not accessible`** — report-only, from the 04-01 ROUTINE BASELINE, pre-dating this phase. **Zero `⚠️`.**

### `scripts/check-music-freeze.sh` executed BY NAME on LXC 100 — exit **0**

Run directly over `ssh`, not inferred from the fold-in. The fold-in is real (`quick-health-check.sh:697` runs this script over `ssh -n`, and round 2 correctly downgraded the claim that it never runs); what was missing was any assertion over the **named command**. Captured output **11,574 bytes**, so the empty-output branch was tested and did not fire. Quoted:

```
  tagger definitions:          1   (target 1)
  beets databases:             1   (target 1 = SURVIVOR_DB)
  tagger databases:            0   (target 0 — wrtag.db*/soulbeet.db*)
  retired paths present:       0   (target 0)
  rw on Music, non-tagger:     0   (target 0, excluding the D-21 consumer exception)
  rw on Music, tagger-capable: 0   (target 0 — Phase 1 D-20, any container state)
  rw on Music, Jellyfin D-21:  1   (documented consumer exception, printed separately)
  tagger-capable containers:   2   (mounts a beets/wrtag/soulbeet config or DB; reported)
  fence assertions failed:     0
  toolchain missing:           0
  FAILURES total:              0

✅ Music freeze harness intact
```

### The run was bound to the guard's own commit, not to Task 1's

| Fact | Value |
|---|---|
| Commit that last touched `scripts/check-music-freeze.sh` | `2572b71e22da506bebb473571b9334dee47144e6` (04-11) |
| Host HEAD at `/mnt/fast/stacks` | `42e26506653c2f5ddaf96a4b19882f6835d85ece` |
| `git merge-base --is-ancestor <guard> HEAD` on the host | **RC 0** — the guard that ran is the guard in the repo |

**This is deliberately NOT bound to Task 1's documentation commit (`64e250b`), and the host does not contain it.** A docs-only edit to `beets.md` does not change the guard being executed, so coupling the two would force a push-and-pull cycle for no measurement — round 2 downgraded that requirement (astra C11). No host pull was needed or performed; unlike 04-13 deviation 1, the artefact being reasoned from was already present.

### Static half of criterion 3, re-derived

`grep -cE '^[[:space:]]*beet ' stacks/selfhosted/arrs/sabnzbd/audio.bash` → **0**.

Plan Task 2 gate returned **`SUITE-OK`**.

## The phase's actual closing position

| # | Criterion | Status | Basis |
|---|---|---|---|
| 1 | One tagger definition | ✅ holds | `tagger definitions: 1` from the repo itself; issue #306 closed |
| 2 | Renovate config valid, no retired-tagger pin | ✅ holds | validator exit 0 at pinned 44.80.0; negative control exit 1 |
| **3** | **A real music job completes with no tagger** | **`window 2: OPEN`** | Static half **verified** (0 `beet` invocations, drift guard green). **Behavioural half OPEN after two windows and five real jobs** — no PRE-HOOK snapshot could be published |
| 4 | Every beets config declares `musicbrainz` | ✅ holds | probe pair 0 vs 1 candidates; both live configs declare it |
| 5 | One database, no idle `rw` holder | ✅ holds | the executed census, re-run here twice |

**4 of 5.** **TAGR-04 is NOT marked complete** and the phase is **not** marked complete — phase-level verification is the orchestrator's, after this plan returns.

**What remains, and what it would take** — stated as the inherited position, explicitly *not* proposed as work for this plan: a byte capture point that survives `direct_unpack`. Both tried locations are exhausted. Nothing further can be measured with the current instrument, so the choice inherited is a **decision** — accept criterion 3 as discharged on threefold unanimous side-effect evidence, or leave it OPEN — not another measurement. This plan took neither decision; it recorded the measurement honestly.

## Carry-forwards met as decisions rather than silences

- **`DEF-04-01`** — the unqualified *"beets has no `undo` command"* claim in `CLAUDE.md:152` and `.planning/PROJECT.md:187`. **Still deferred to Phase 7**, which owns the "undo exercised" criterion. **Not touched by this plan**: neither file is in its mandate (`files_modified` is exactly `beets.md`), and `CLAUDE.md`'s region is generated from `PROJECT.md`, so both must be amended together. Recorded in `deferred-items.md` and in `beets.md` § *Recorded, not fixed*.
- **`beets.md`'s two open config gaps** — no `match.preferred.countries` (the UK/US *Now!* tie-break) and no `fromfilename` / `edit` for bucket C. **Still deferred to Phase 6**, which owns closing them on the survivor's deliberately minimal vendored config (D-27). Neither is a gap of this closure.

## Deviations from Plan

### 1. [Plan directive upheld over the generic executor contract] `STATE.md` and `ROADMAP.md` were NOT updated

- **The conflict, stated rather than resolved silently.** The generic executor contract lists "STATE.md and ROADMAP.md updated and diff-checked" as a success criterion. **This plan's Task 2 explicitly prohibits it**: *"Do not modify `.planning/STATE.md` or `.planning/ROADMAP.md`, and do not call any `gsd-sdk query state.*` or `roadmap.*` verb — the orchestrator owns both, and 04-12 and 04-13 each recorded holding that line."* Its acceptance criteria then assert that neither file appears in any commit from this plan.
- **Resolution: the plan wins**, on three grounds. (a) It is the specific contract with a named reason and two plans of precedent. (b) Writing STATE.md would make the plan's own acceptance criterion fail. (c) The project hazard is live and documented — `gsd-sdk query state.*` verbs silently corrupt unrelated lines in both files, and it has fired repeatedly on this run.
- **Verified:** `git show --name-only 64e250b` → exactly `stacks/selfhosted/arrs/beets.md`. No planning state file is in any commit from this plan. **The orchestrator must update STATE.md and ROADMAP.md for wave 11 and for phase close**, and should `git diff` both afterwards per the standing hazard note.

### 2. [Rule 1 — stale factual claim in the file being edited, fixed] `beets.md` asserted the evidence file "carries exactly one verdict line"

- **Issue:** the opening paragraph, correct when 04-13 wrote it, became false when 04-15 added § 7. The file now carries one verdict line **per window**.
- **Fix:** the sentence now reads *"exactly one verdict line per window — § 6 for window 1, § 7 for window 2. The current verdict is window 2's"*. Both verdicts are quoted, window 2 first as the current one.
- **Recorded because the direction matters:** left alone, the page would have cited a uniqueness property that a reader could check and find false, immediately after that same property was the thing a machine relied on to pick the heading.

---

**Total deviations:** 2 — 1 plan directive upheld against a conflicting generic contract (recorded, not silently resolved), 1 auto-fixed stale claim.
**No assertion was weakened, no gate was relaxed, no verdict word was transcribed rather than extracted by the delimited match, no dated historical section was deleted, and no guard was re-run to reach green.**

## Threat Flags

None. This plan added no network endpoint, auth path, file-access pattern or trust boundary. Against the plan's register:

- **T-04-16-01 (information disclosure into a public repo)** — mitigated. No release, artist, album or job-folder name, and **no job sha256 prefix at all**, entered the added text; no storage path beyond the pre-existing `/downloads/complete/nzb/music/` and `/downloads/incomplete/` prefixes the page already carried. 46 added lines screened with a filter proven to discriminate on both controls: 0 credential matches, 0 runs of 40+ characters.
- **T-04-16-02 (a closure heading over a non-PASS verdict)** — mitigated and **it was the live risk**. The heading was selected by the single line-anchored verdict, extracted with a delimited match so the line-265 decoy's `PASSING` could not parse as `PASS`; the mapping was enforced by the plan's `<verify>`, which returned `MAP-OK(OPEN)` with closure-heading count asserted **0**.
- **T-04-16-03 (loss of the window-1 record, or a stale criterion row)** — mitigated. Window 1's verdict and mechanism paragraph retained and absent from the deletion set; census block proven byte-identical by `diff` against `git show HEAD~1`; commit deletes no file; row 3 asserted to carry `window 2: OPEN` and the three-plan source list.
- **T-04-16-04 (measurement against a stale host checkout)** — mitigated. Host asserted to contain the guard's own commit by `merge-base --is-ancestor` (RC 0); both the guard commit and host HEAD recorded above.
- **T-04-16-05 (a guard result suppressed to keep a closure tidy)** — did not arise: both guards returned exit 0 on their first and only run. Nothing was re-run, and the one `❌` in the health check is reported above rather than omitted.

## Known Stubs

None. `beets.md`'s Phase 4 section is complete for an OPEN verdict: heading, both verdicts quoted, the dated in-band note, the executed census, and the five-criteria table with row 3 recording window 2.

## Issues Encountered / carried forward

- **Criterion 3's behavioural half remains OPEN after two windows and five real jobs.** Unchanged by this plan, which transcribed rather than re-litigated it.
- **The evidence file's decoy line is a permanent trap** for anyone re-deriving this verdict later. The anchored pattern is `^Verdict \(window 2\): ` and the count must be asserted as exactly 1. Recorded in this SUMMARY's `tech-stack.patterns` so it outlives the phase.
- **The orchestrator owes STATE.md and ROADMAP.md updates** for this wave and for phase close — see deviation 1.

## Next Phase Readiness

- **Phase 4 is not closable on criterion 3, and this plan did not make it so.** `/gsd-verify-work` should still treat criterion 3 as the open gap; `04-VERIFICATION.md`'s 4/5 score stands unchanged.
- **The estate record and the evidence file now agree**, which was the point: the heading, the criterion row and the verdict line all say OPEN.
- **DEF-04-01 → Phase 7**; **the two `beets.md` config gaps → Phase 6**. Both named above.
- **Both standing guards are green** against the landed text, executed by name.

## Self-Check: PASSED

- FOUND `stacks/selfhosted/arrs/beets.md`, modified; `grep -c '^## Phase 4 — one tagger'` = **0**, `grep -cE '^## Phase 4 — interim status'` = **1**, interim heading names **OPEN**, row 3 carries `window 2: OPEN` and `04-12, 04-14, 04-15`.
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-16-SUMMARY.md`.
- FOUND commit **`64e250b`**, touching exactly one file (`stacks/selfhosted/arrs/beets.md`), **0** file deletions, 46 insertions / 9 deletions.
- Plan gates returned **`MAP-OK(OPEN)`** (Task 1) and **`SUITE-OK`** (Task 2), both quoted from their own stdout.
- `04-D12-EVIDENCE.md` untouched by this plan; its anchored window-2 verdict count is still exactly **1**.
- `.planning/STATE.md` and `.planning/ROADMAP.md` appear in **no** commit from this plan, as the plan requires.
- Only explicit paths were staged. `git status --short` clean after the task commit.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-14*
