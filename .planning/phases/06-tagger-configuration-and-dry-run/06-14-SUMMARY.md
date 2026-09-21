---
phase: 06-tagger-configuration-and-dry-run
plan: 14
subsystem: infra
tags: [beets, beets-flask, musicbrainz, jellyfin, music-assistant, zfs, phase-closure, traceability]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plans 06-01…06-13 — the vendored config, the three assertion scripts, the committed expected tree, the oracle run, the country-preference proof and the MA read-back"
  - phase: 05-inbox-structure-and-the-junk-gate
    provides: "the clean sample the dry run was drawn from, and the `tank/downloads@pre-phase5` fence this plan refuses to release"
provides:
  - "The Phase 6 closure in `stacks/selfhosted/arrs/beets.md`: a five-row criteria table with a verdict, a verbatim runnable command and a plan number per criterion, all re-measured from live state at close"
  - "Three instrument corrections recorded as dated notes with the original criterion text left standing (D-33, D-29, D-34)"
  - "A `Still open at Phase 6 close` register, the C-7 cosmetic note, the D-32 standing instruction and D-08's read-only answer"
  - "The close-time `quick-health-check.sh` per-block verdict table, with both reds named and neither attributed to Phase 6"
  - "CONF-01…CONF-06 moved off Pending in `REQUIREMENTS.md`, CONF-04 as OPEN rather than half-ticked"
  - "Nine named Phase 7 entry criteria and two named Phase 9 entry criteria in `ROADMAP.md`"
affects: [07-pilot-12-albums, 09-bucket-a-in-batches]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phase closure by re-measurement: every criterion's instrument is re-run at sign-off and its fresh output quoted, rather than the verdict being copied from a plan summary"
    - "A half-discharged requirement is recorded as OPEN with its remaining step named, never as `Complete (<the half that worked>)`"
    - "Carried-forward items are written into the NEXT phase's ROADMAP entry criteria, not left in the closing phase's artifacts"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-14-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md

key-decisions:
  - "Phase 6 is recorded as CLOSED WITH ONE OPEN REQUIREMENT, not Complete — CONF-04's Jellyfin half is OPEN by measurement and is a named Phase 7 entry criterion"
  - "CONF-04's two halves are recorded as two verdicts on the same row and are never summed; the overall verdict is the weaker of them"
  - "`tank/downloads@pre-phase5` is NOT released at Phase 6 sign-off — Phase 6 wrote nothing, so it produced no evidence Phase 5's changes were correct (D-32)"
  - "The oracle and the two-arm incremental control were NOT re-driven live at close, because doing so would import; their instruments were re-exercised via `--self-test` and their results cited to committed artifacts"
  - "The ROADMAP criterion texts for 3, 4 and 5 were NOT rewritten — corrections are dated notes beside them, the precedent TAGR-05 set"

patterns-established:
  - "Instrument correction by dated annotation: the wrong instrument stays visible, because the history of the mistake is part of the evidence"
  - "A verify predicate that cannot pass against legitimate state is a plan defect to be scoped and controlled, not worked around by editing the state"

requirements-completed: [CONF-01, CONF-02, CONF-03, CONF-05, CONF-06]

# Metrics
duration: 22min
completed: 2026-09-21
---

# Phase 6 Plan 14: Phase Closure Summary

**Phase 6 closed on instruments re-run at sign-off — four criteria TRUE, CONF-04 OPEN on its Jellyfin half alone — with the DJ-routing mechanism gap, the `bootleg` gate, the DUPE blocker and six more items written into Phase 7's ROADMAP entry criteria where the next phase will actually read them.**

## Performance

- **Duration:** ~22 min
- **Started:** 2026-09-21T21:56Z (approx.)
- **Completed:** 2026-09-21T22:18Z
- **Tasks:** 2 (plus one in-task correction driven by the phase-verification run)
- **Files modified:** 3

## Accomplishments

- **All five ROADMAP criteria re-measured from live state at close**, not carried forward. `scripts/check-beets-config.sh` re-run 2026-09-21T22:04Z → exit 0, `FAILURES total: 0`, `arm 1 blind: 0`, 23 assertions green against the **server-committed** config. Both `--self-test`s re-run → exit 0. Both consumers re-read directly through their own APIs at 22:06Z.
- **CONF-04 recorded honestly as two verdicts that are never summed.** Jellyfin re-measured at **0/4, 1/2, 1/2** — every pinned row still at its pre-change baseline, because `PreferNonstandardArtistsTag` is probe-time and 0 of 1,244 rows have been re-probed. Music Assistant re-measured at **3/4, 2/2, 2/2** on the running 2.11.0b2, with a planted-miss negative control returning 0 so the selector is shown able to fail.
- **`06-EXPECTED-TREE.txt` provenance re-asserted** — still at its original commit `cb9f49a`, sha256 `37b2083e…`, 351 lines. A fixture edited after the run it judges proves nothing.
- **Three instrument corrections as dated notes, originals left standing:** D-33 (`beet move -p`, not `--pretend`), D-29 (three layers, not a file count), D-34 (the `ARTISTS` tag, not `;` in `ARTIST`).
- **Nine Phase 7 entry criteria and two Phase 9 entry criteria** written into the ROADMAP, each named rather than noted.
- **A close-time `quick-health-check.sh` run recorded per block**, with both reds named and neither caused by Phase 6 — and one carried-forward claim corrected because the run measured a different cause.

## Task Commits

1. **Task 1: re-measure all five criteria and write the Phase 6 closure into `beets.md`** — `bdf09de` (docs)
2. **Task 2: move the CONF traceability rows off Pending and update the ROADMAP** — `7ad0a8e` (docs)
3. **Phase verification: record the health-check block verdicts and correct the drift-block cause** — `d351608` (docs)

## Files Created/Modified

- `stacks/selfhosted/arrs/beets.md` — the Phase 6 closure: criteria table, the three instrument corrections, the C-7 note, D-32 as a standing instruction, D-08's read-only answer, the `Still open at Phase 6 close` register, the how-to-re-run block, and the close-time health-check verdict table
- `.planning/REQUIREMENTS.md` — CONF-01/02/03/05/06 → Complete (Phase 6) with evidence and caveats; CONF-04 → **OPEN** with its remaining step; the requirement checkbox list follows, CONF-04 left unticked
- `.planning/ROADMAP.md` — criteria 3, 4 and 5 annotated with dated corrections (no criterion text rewritten); the wave list marked complete with in-band amendments; a closed-with-one-open-requirement disposition; Phase 7's nine and Phase 9's two entry criteria; the progress row moved to `14/14 — Closed, 1 open requirement`
- `.planning/phases/06-tagger-configuration-and-dry-run/06-14-SUMMARY.md` — this file

## Decisions Made

- **Phase 6 is not marked Complete.** CONF-04 is OPEN on a named half, so the ROADMAP progress row reads `Closed — 1 open requirement` with the open requirement and its Phase 7 discharge named in the same cell. A phase marked Complete with an open requirement is how an open requirement stops being read.
- **The oracle and the incremental control were not re-driven live.** Both would import, and Phase 6's premise is that it does not write. Their *judges* were re-exercised (`--self-test`, exit 0) and their *results* cited to committed artifacts with their hashes and commit ids. This is stated in band in the closure so nobody reads the table as five fresh live runs.
- **The carried claim about the vendored-drift block was replaced by the measurement.** The wave context said the file was not drifted with matching hashes; the close-time run showed the block never compared anything at all (`ssh exit 4`, `git show HEAD:…/flask-config.yaml` failing because the host's HEAD predates plan 06-04's file). "Could not look" is not "nothing is wrong", so the unverified hash claim was removed rather than repeated.
- **The host-side census's green `tagger definitions: 1 (target 1)` is recorded as a false comfort**, not as evidence: it is the pre-D-11 instrument reading a pre-Phase-6 checkout, and the untracked host-side `flask.yaml` is invisible to `git ls-files`. The D-11 named-pair expectation did not run at close.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 2's verify predicate `grep -q "Plans\*\*: TBD" "$m"` cannot pass**

- **Found during:** Task 2 (traceability and ROADMAP)
- **Issue:** The predicate is unscoped and fails if the literal appears **anywhere** in `ROADMAP.md`. Phases 7, 8 and 9 legitimately still carry `**Plans**: TBD` — they have no plans yet — so the check can only be made to pass by deleting a truthful statement from three unrelated phase entries. That would be editing the state to fit the instrument.
- **Fix:** Re-ran the check **scoped to the Phase 6 entry** (`sed -n '/^### Phase 6: /,/^### Phase 7: /p'`), which is what the check meant, with a **positive control first** proving the extractor can see a TBD (it finds Phase 7's). Scoped result: the Phase 6 entry carries no TBD. No TBD was removed from any phase that has none.
- **Files modified:** none — this was a change to the verification, not to the artifacts
- **Verification:** all other predicates in the same verify ran unchanged and passed; full run exits 0
- **Committed in:** `7ad0a8e` (recorded in the commit message)

**2. [Rule 1 - Bug] A carried-forward claim in the closure was contradicted by the close-time measurement**

- **Found during:** phase verification (`scripts/quick-health-check.sh`)
- **Issue:** The closure carried the wave context's reading that the vendored file is "not drifted (repo and host both `949bd1f3…`)". The run measured something different and stronger: the block reports `UNKNOWN — could not look` with `ssh exit 4`, because `git show HEAD:stacks/selfhosted/arrs/beets/flask-config.yaml` **fails** on the host's HEAD. Nothing was compared. Leaving the hash claim standing would have laundered an unverified reading into a closure document.
- **Fix:** Replaced the claim with the measured cause, quoted from the transcript; added the per-block verdict table; added the `tagger definitions: 1` false-comfort note.
- **Files modified:** `stacks/selfhosted/arrs/beets.md`
- **Verification:** task 1's verify re-run (exit 0) and the credential screen re-run (clean, positive control fired) after the edit
- **Committed in:** `d351608`

---

**Total deviations:** 2 auto-fixed (1 blocking instrument defect, 1 accuracy correction)
**Impact on plan:** No scope creep — both kept the closure honest, which is the plan's stated purpose. Neither changed what was delivered.

## Issues Encountered

- **`scripts/check-music-consumers.sh` could not be run as the criterion-4 instrument at close.** It is host-resident by design (Jellyfin is only reachable over `t3_proxy` from LXC 100, and both credentials live at `/mnt/fast/secrets/`), and the host's checkout predates Phase 6, so the copy there has **no § 4 at all**. Deploying the repo copy to the host would have been an out-of-band change to an unsynced estate. Resolved by re-measuring the same facts directly through the two APIs the script uses — `GET /Library/VirtualFolders` and `/Items?Fields=ArtistItems` for Jellyfin, `auth/login` + `music/tracks/library_items` for MA — read-only, credentials never in argv (`-H @<(printf …)`, `$ENV.…` for jq), with a planted-miss negative control on the MA side. The closure and the CONF-04 row both name `check-music-consumers.sh` as the standing instrument and this run as the close-time measurement.
- **The freeze fold-in's known hang (DEF-06-10-01) did not fire** on this run; `quick-health-check.sh` completed in roughly two minutes.

## Threat Flags

None. This plan changed three documentation files, installed nothing and ran only read-only assertions already in the repo. The T-06-76 credential screen over the Phase 6 section of `beets.md` was run with a positive control first (it fired on a planted `JELLYFIN_API_KEY=` line) and returned **clean**: the only hits are three prose lines using the word "token" to mean a `grep` label token in `check-music-freeze.sh`'s summary. No key, password, JWT or hash of a secret is quoted anywhere in the new text.

## Known Stubs

None. This plan produced no code and no placeholder content.

## User Setup Required

None required by this plan — but **one operator decision is outstanding and is recorded rather than assumed**: the Phase 6 commits are **unpushed**, so LXC 100 is at `c67d497` and carries none of the Phase 6 scripts. Clearing it needs `git push`, then `git pull --ff-only` on LXC 100, and that pull will refuse until the untracked `/mnt/fast/stacks/stacks/selfhosted/arrs/beets/flask.yaml` is removed host-side. Nothing in this plan did any of that.

## Next Phase Readiness

**Phase 7 can start, and it inherits nine named entry criteria** (E1–E9 in its ROADMAP entry): the DJ-routing mechanism gap with its three candidate routes and the unexercised path rule 2; the `bootleg` album-populated gate; the `rw` grant as its first act; `tank/downloads@pre-phase5` not released until its pilot passes; the `Def Leppard` repair; CONF-04's open Jellyfin half with the two measurements it needs; the DUPE-01/02 decision; the `%aunique{}` MA fallback risk list; and the match-check order. **Phase 9 inherits two**: the folder-count lag with `NOT EXERCISED` standing, and the per-file Discogs release-id shortcut.

**Blockers and concerns, stated plainly:**

- **CONF-04 is OPEN** and cannot be closed by any amount of further configuration — it needs a write.
- **DUPE-01 / DUPE-02 have no roadmap decision**, and Phase 7's diff join is silently last-wins until they do. This is the nearest unowned blocker to the next phase.
- **The estate is not in sync with the repo**, and the health check correctly reports UNKNOWN rather than green because of it.

## Self-Check: PASSED

- `stacks/selfhosted/arrs/beets.md` — FOUND, modified in `bdf09de` and `d351608`
- `.planning/REQUIREMENTS.md` — FOUND, modified in `7ad0a8e`
- `.planning/ROADMAP.md` — FOUND, modified in `7ad0a8e`
- `.planning/phases/06-tagger-configuration-and-dry-run/06-14-SUMMARY.md` — FOUND (this file)
- Commits `bdf09de`, `7ad0a8e`, `d351608` — all present in `git log`
- Task 1 verify exit 0; task 2 verify exit 0 (with the scoped correction above); `git diff --stat` against the base shows **exactly** the three declared files; credential screen clean with its positive control fired
- `STATE.md` was **not** modified

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-21*
