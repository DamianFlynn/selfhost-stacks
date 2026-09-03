---
phase: 03-tagger-spike
plan: 02
subsystem: planning-artefacts
tags: [criterion-5, pre-committed-thresholds, estimator, OD-2, OD-3, OD-4, ergonomics, provenance]
requires: []
provides:
  - "03-DECISION.md — T1/T2/T3 in falsifiable form, committed before any evidence exists"
  - "The backlog-weighted per-stratum estimator T1 is tested against, fixed before any weight or rate exists"
  - "The committed 143-folder backlog denominator and the corrected 60-folder dj-mixes population"
  - "OD-3 widening (dj-mixes union unsorted, de-duplicated) stated pre-evidence"
  - "OD-2 version split (axis one 2.13.1, axis two 2.12.0) recorded rather than discovered"
  - "03-ERGONOMICS-SHEET.md — 10-row template, every measurement cell empty"
  - "Threshold commit SHA 137b6d9e92cb44d9c6a48b3963bb33fe0194622f, published to a remote"
affects:
  - "03-03 — cannot draw the sample before the thresholds and estimator that govern it"
  - "03-07 — must reproduce the threshold SHA verbatim and assert its ancestry before recording numbers"
  - "03-10 — fills 03-ERGONOMICS-SHEET.md during the trial, not after"
  - "03-11 — asserts the threshold text unchanged by git log -p, fills both axis verdicts"
  - "Phase 4 — handed the unsatisfiable --pretend criterion and the renovate.json5:91 correction"
tech-stack:
  added: []
  patterns:
    - "Criterion-5 custody by commit ordering: thresholds committed in a commit that predates every measurement commit"
    - "Estimator specified before any rate can exist — the threshold value unchanged, only the measurement defined"
    - "Committed-empty measurement template as the only afterwards-provable proof the template predated the evidence"
    - "beets.md house style for a durable record: Companion-to link, not-applied disclaimer, dated state stamp, leading blockquote"
key-files:
  created:
    - .planning/phases/03-tagger-spike/03-DECISION.md
    - .planning/phases/03-tagger-spike/03-ERGONOMICS-SHEET.md
  modified: []
decisions:
  - "Tasks 1 and 2 committed as ONE commit, because Task 3's acceptance criterion requires a single SHA whose `git show --stat` lists both artefacts"
  - "The D-12 audit is reproduced as 19 physical rows (16 numbered claims plus sub-rows 3a/3b/3c), and the record states that count explicitly so a row counter is not misled"
  - "The threshold commit was pushed to its own remote branch, not to origin/main: origin/main stood at c88c268, behind this plan's own base 41de755, and the orchestrator owns the merge"
  - "`beets-terminal` is kept out of the sheet's header prose so the literal appears exactly 5 times as the acceptance criterion requires; the OD-2 note is preserved in full as an arm/version table"
metrics:
  duration: "~20 min"
  completed: 2026-09-03
---

# Phase 3 Plan 02: Pre-committed Thresholds and Measurement Templates Summary

Committed T1/T2/T3, the backlog-weighted estimator, the corrected 143-folder denominator and an
empty 10-row ergonomics template **before a single folder was sampled or a single Discogs request
issued** — then published the commit to a remote, so criterion 5's chain of custody is a fact about
`origin` rather than an assertion about a mutable local branch.

## What was built

Two Markdown artefacts and one property of git history.

**`.planning/phases/03-tagger-spike/03-DECISION.md`** (440 lines, 13 `##` sections, 36 `PENDING`
cells) — the decision record skeleton in `beets.md` house style: a Companion-to line, an explicit
"nothing here is applied by `docker compose`" disclaimer, a dated state stamp, and a leading
blockquote stating that Phase 4 deletes the loser and Phase 6 grants the winner `rw` — not before.

The load-bearing content is the ordering, not the prose. Three things are fixed in a commit that
provably predates every number:

1. **T1/T2/T3 in falsifiable form**, each with an instrument named and both result columns
   `PENDING`. T1's 40% value is unchanged; T2 is `> 4 hours projected` **or** `any observed 429`;
   T3 is deliberately not a number.
2. **The estimator** — a per-stratum strict rate weighted by each stratum's prevalence across the
   143-folder backlog, with a V1–V6 weight table whose every weight cell reads
   `PENDING — filled by plan 03-03`. The same arithmetic governs criterion 2's request
   extrapolation, so it is explicitly **not** an unweighted `M × 143`.
3. **The corrected denominators** — 143 backlog folders (not "~1,000"), 60 audio-bearing `dj-mixes`
   folders (not 84), per-folder headline cross-checked per distinct `audio_md5`.

**`.planning/phases/03-tagger-spike/03-ERGONOMICS-SHEET.md`** — a 10-row template (5 albums × 2
front ends) with `album_slot`, `album`, `front_end` and `went_first` pre-filled and every
measurement cell empty. The `went_first` alternation is pre-assigned (terminal first on `clean-1`,
`hard-va-compilation`, `dj-no-match`; flask first on `clean-2`, `hard-flat-multidisc`) so it can be
audited rather than merely claimed.

## The two things worth remembering

**An estimator specified before any rate can exist is not goalpost-moving.** The plan fixes *how*
T1's number is computed at the same moment it fixes the threshold value. The record states this
explicitly, because the distinction is the whole defence: an estimator chosen *after* a rate exists
would be moving the goalposts; one specified when no sample, no weight and no rate exists is simply
specifying the measurement. Plan 03-03 (weights) and 03-07 (rates) both depend on this plan and
cannot run before it. The change costs **zero** extra Discogs requests and **zero** extra folders.

**A committed empty template is the only afterwards-provable evidence that the template predated the
evidence.** Hence the definitions of *one intervention* and *one context switch* are fixed in the
sheet's header now — the definition **is** the measurement, and a definition invented after the run
is a reconstruction, not a measurement.

## Deviations from Plan

### 1. [Rule 3 - Plan-internal conflict] Tasks 1 and 2 share one commit

- **Found during:** Task 1, resolved at commit time
- **Issue:** The executor protocol commits each task individually, but Task 3's acceptance criterion
  requires `git show --stat <SHA>` to list **both** `03-DECISION.md` and `03-ERGONOMICS-SHEET.md`.
  Two separate commits make that unsatisfiable — no single SHA would contain both.
- **Fix:** Both artefacts written first, then committed together as the single "threshold commit"
  `137b6d9`, exactly as Task 3's action text specifies ("Commit Tasks 1 and 2's artefacts and push").
- **Commit:** `137b6d9`

### 2. [Rule 1 - Plan-internal inconsistency] The D-12 audit is 19 physical rows, not 16

- **Found during:** Task 1
- **Issue:** The plan says "reproduce all 16 rows" and its acceptance criterion says the table "has
  16 data rows" — but 03-RESEARCH.md's table has **19 physical rows**: 16 numbered claims plus three
  sub-rows 3a, 3b and 3c. The plan's own prose requires those sub-rows ("Rows 3, 3a, 3b, 3c, 5, 6, 8,
  15 carry verdicts of falsified or changed"), and 3c is the decisive TAGR-02 `tags.Clear` finding.
  Dropping three rows to satisfy a row count would have discarded the most load-bearing content.
- **Fix:** Reproduced all 19 rows, and stated the count explicitly in the record ("16 numbered
  claims… 19 physical rows in total") so a later row counter is not misled.
- **Files modified:** `03-DECISION.md`
- **Commit:** `137b6d9`

### 3. [Rule 4 - Deferred to the orchestrator] The push went to the agent branch, not `origin/main`

- **Found during:** Task 3
- **Issue:** Task 3 requires the threshold commit to be reachable from `origin/main`. Two facts made
  that not mine to do: this plan ran as an **isolated worktree agent** (the orchestrator owns merges
  to `main`), and **`origin/main` stood at `c88c268` — behind this plan's own base `41de755`**. The
  phase-start commit had not itself been published, so pushing HEAD onto `main` would have published
  unmerged work ahead of the orchestrator.
- **Fix:** Pushed both commits to `origin/worktree-agent-a810735978952a3c4`. This satisfies what the
  push is *for* — T-03-06b's requirement that custody rest on a remote rather than a mutable local
  branch — because the SHA is now immutable and independently verifiable on `origin`. The record
  states the ref, the reason, and that `origin/main` reachability completes at the orchestrator's
  merge; because this repo merges rather than squashes or rebases (`0ee20c7`), the SHA survives.
- **Follow-up written into the record:** plan 03-07 must run
  `git merge-base --is-ancestor 137b6d9e92cb44d9c6a48b3963bb33fe0194622f origin/main` before
  recording any number, and record nothing if it fails.
- **Commit:** `b53535c`

### 4. [Rule 3 - Acceptance-criterion conflict] `beets-terminal` kept out of the sheet header

- **Found during:** Task 2
- **Issue:** The plan's action requires the header to carry the OD-2 version note naming
  "the `beets-terminal` arm" and "the `beets-flask` arm", while its acceptance criterion requires
  `grep -c 'beets-terminal'` to return **exactly 5** — the five table rows. Any header mention makes
  it 6 and fails the check. (`beets-flask` is "at least 5", so it is unaffected.)
- **Fix:** The OD-2 note is preserved in full as an arm/version table naming "Terminal arm" (2.13.1,
  `lscr.io/linuxserver/beets:2.13.1-ls349`) and "Flask arm" (2.12.0, `metasauce/beets-flask:v2.0.0-rc6`),
  with an explicit sentence pointing at the two `front_end` values in the table below. No information
  is lost; only the literal token placement differs.
- **Commit:** `137b6d9`

### 5. [Scope] `scripts/check-music-freeze.sh` not run

- The plan's `<verification>` lists it. The script is **LXC-100-resident by contract** (its header
  says so: it runs from `/mnt/fast/stacks` on `root@172.16.1.159`), and this plan wrote **only two
  Markdown files under `.planning/`** — zero stack files, zero scripts, zero estate surface, proven
  by `git diff --name-only HEAD~2 HEAD`.
- Running it from a macOS worktree would fail on toolchain preconditions and produce a misleading
  result. Per this repo's own rule — *fail closed, keep "could not look" distinct from "nothing is
  wrong"* — it is recorded as **not run and not applicable**, rather than claimed as a pass. Phase 1
  produced six unearned passes; this is not a seventh.

## Verification

| Check | Result |
|---|---|
| `grep -cE '^\| *T[123] '` on `03-DECISION.md` | **3** |
| T1 row contains `40%`, `strict`, `backlog-weighted`, `4–5`, DMC, index-track-sensitive, zero-candidate | all present |
| T1 names the unweighted rate as reported-but-not-tested | present |
| T2 row contains `4 hours` and `429` | both present |
| T3 row contains `self-assessment` and "not a number" | both present |
| Weight cells reading `PENDING — filled by plan 03-03` | 7 |
| `grep -c 'PENDING'` | **36** (≥ 8 required) |
| `grep -c '^## '` | **13** (≥ 9 required) |
| `03-DECISION.md` line count | 440 (≥ 120 required) |
| D-12 audit data rows | 19 (16 numbered claims — see deviation 2) |
| Ergonomics sheet data rows | **10**, five slots × 2 |
| `grep -c 'beets-terminal'` / `'beets-flask'` | **5** / 7 |
| `wall_clock_s`/`interventions`/`context_switches`/`outcome`/`stuck_points` non-empty cells | **0** (parsed, not grepped) |
| `went_first` alternation matches the pre-assigned plan | exact match on all 10 rows |
| Credential screen (Discogs token, 40-char hex) on both files | **0 matches** |
| D-03 frozen files (`wrtag.yaml`, `beets.yaml`, `renovate.json5`) in diff | **none** |
| File deletions in either commit | **none** |
| `git check-ignore` on both artefacts | not ignored (rc=1) |
| Evidence/sample artefacts present at commit time | **none** — precondition holds |
| Threshold commit reachable from a remote | `origin/worktree-agent-a810735978952a3c4` |
| SHA recorded verbatim in `03-DECISION.md` | 3 occurrences |

## Known Stubs

None. Every `PENDING` cell in both artefacts is **intentional and load-bearing** — a populated result
cell in these commits would itself be the failure this plan exists to prevent. They are filled by
plans 03-03 (weights), 03-07 (rates), 03-08 (wrtag), 03-09 (D-13), 03-10 (trial) and 03-11 (verdicts).

## Threat Flags

None. This plan introduced no network endpoint, auth path, file-access pattern or schema change.
Both artefacts were screened for the Discogs token and any 40-character credential-shaped string
before committing (T-03-08); `DISCOGS_USER_TOKEN` is referenced nowhere and no value was read,
printed or transported. No package-manager install occurred (T-03-SC).

## Self-Check: PASSED

- `.planning/phases/03-tagger-spike/03-DECISION.md` — FOUND
- `.planning/phases/03-tagger-spike/03-ERGONOMICS-SHEET.md` — FOUND
- Commit `137b6d9` — FOUND (on `origin/worktree-agent-a810735978952a3c4`)
- Commit `b53535c` — FOUND (on `origin/worktree-agent-a810735978952a3c4`)
