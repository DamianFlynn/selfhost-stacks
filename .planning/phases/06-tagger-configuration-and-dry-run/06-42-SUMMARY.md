---
phase: 06-tagger-configuration-and-dry-run
plan: 42
subsystem: infra
tags: [jellyfin, conf-04, d-22, artistitems, zfs-diff, census-delta, negative-result, instrument-corroboration]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-40's before-state — the three pinned rows at 0/1/1, the 1,244-row ArtistItems census, the four D-34 option values, the .nfo/.lrc/.jpg hash manifest and its three fingerprints, the beets state fingerprints, and the three files' content sha256"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-41's drive — the snapshot fence tank/media/Music@pre-06-41-conf04-reprobe, three new mtimes with byte-identical content, the file-scope POST that returned 204, POST_UTC 1790237579, and the LibraryMonitor lines naming all three Audio items"
provides:
  - "MEASURED NEGATIVE: an mtime change plus a targeted Default-mode refresh did NOT make Jellyfin re-read the ARTISTS tag. All three pinned rows read AT-BASELINE (0/1/1), not at target (4/2/2)"
  - "The result is interpretable rather than UNKNOWN, because 06-41's LibraryMonitor evidence proves the refresh started and reached all three items — 'never started' and 'started and changed nothing' are told apart"
  - "artifacts/06-42-conf04-reprobe-after.txt, 654 lines — SECTIONS C through K: the three rows with machine-recomputable verdicts, the full census, an EMPTY census delta, the OQ-1 negative control, and the four-way safety re-assert ending SAFETY: PASS"
  - "artifacts/06-42-consumers-rerun.txt, 352 lines — the deployed unmodified instrument's own view, in seven fixed-format parseable lines, taken BEFORE any branch is computed"
  - "Two independent instruments agreeing on the same answer: the hand-built API read (SECTION C) and the deployed script's § 4b (JF_AT_TARGET 0 / JF_PENDING 3)"
  - "Proof that the round was SAFE: zfs diff byte-identical to 06-41's, 0 of 91 .nfo changed, all three sidecar fingerprints identical, no option moved, the census delta empty"
affects: [06-43, 06-44, 06-45, phase-07-entry-criterion-E6]

tech-stack:
  added: []
  patterns:
    - "Record the moment of a read-back as an epoch NUMBER before reading anything, so the mandatory settle window is a subtraction across two artifacts rather than a sentence either file makes about itself"
    - "Emit each per-row verdict twice — once as prose and once as a fixed eight-field `ROW|` line — so the verify block recomputes the verdict from the row's own numbers and a misclassification fails a script instead of resting on the agent that wrote it"
    - "When a prior artifact records a fingerprint VALUE but not the command that produced it, recover the recipe against that artifact's own oracle (compute four candidates, keep the one that reproduces the known hash) rather than assuming a construction — otherwise a later comparison measures the two constructions, not the estate"
    - "Do not re-transcribe an unchanged 1,244-row block. State the row counts, the differing-line count and the extraction that produced them; the delta is the assertion and the earlier artifact stays the authoritative row-level record"
    - "Run the independent instrument BEFORE the operator gate, not after it, so the one automated cross-check that could catch a wrong branch has already run when the branch is chosen"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-42-conf04-reprobe-after.txt"
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-42-consumers-rerun.txt"
  modified:
    - ".planning/STATE.md"
    - ".planning/ROADMAP.md"

key-decisions:
  - "THE RE-PROBE HYPOTHESIS IS MEASURED FALSE AND IS RECORDED AS SUCH. 06-03 listed 'the file's mtime changing' as a mechanism that would re-run the prober; it did not. The rows were not re-refreshed, the mode was not widened, and no further file was touched. A null result is a legitimate recorded negative, and what it means for CONF-04 is 06-43's decision behind the operator gate — not this plan's."
  - "The census delta is EMPTY, and that single block carries two facts that are NOT softened into one: nothing outside the three touched files moved, AND the three themselves did not move either. Both come from the same 1,244-row comparison and both are stated."
  - "The .lrc/.jpg fingerprint recipe was RECOVERED, not assumed. 06-40 records the fingerprint values but not the command; four candidate constructions were computed and exactly one reproduced 06-40's own .nfo fingerprint, so the .lrc and .jpg comparisons are like-for-like. The other three are recorded as wrong constructions, not as findings."
  - "SECTION D does not re-transcribe the 1,244 census rows. They are byte-identical to 06-40 SECTION 3 (0 differing lines over all five fields), and 1,244 lines whose only content is 'unchanged' would bury the delta rather than support it. The row counts, the diff count and the extraction method are recorded instead."
  - "MetadataSavers = [\"Nfo\"] is recorded as a FIRST measurement, not as a comparison: 06-40 never recorded it, so this run cannot prove it did not change. Stated in band rather than presented as a clean diff, with a note that a future round should pin it."
  - "06-41's claim that the host copy of check-music-consumers.sh is pre-Phase-6 (c67d497) with no ARTIST_PROOF_ROWS was MEASURED FALSE this run and corrected in the artifact. The host copy is byte-identical to the repo copy. 06-41's statement was correct for its own run and is superseded, not retroactively contradicted."
  - "Task 3's HOST CHECKOUT was STALE by two commits when the task began, because this plan's own tasks 1 and 2 had just moved local HEAD. The plan's own named remedy was applied — push, `git pull --ff-only` on the host, re-run — rather than relaxing the test or writing MEASURED over a STALE checkout. The recorded MATCH is on the real equality."
  - "exit 3 was recorded and NOT treated as a defect. FAILURES total is 0, so it is the pending gate and not the failure gate; the Jellyfin and MA verdicts are never summed, and no line of any script was changed to make the process end on 0."

patterns-established:
  - "Two-control redundancy for 'nothing was written': a post-event `zfs diff` compared by sha256 against the pre-event block, plus a full path+size+mtime+content manifest. They fail for different reasons, and agreement is the claim"
  - "A halt gate as a single machine-readable line (`SAFETY: PASS` / `SAFETY: FAIL — <assertion>`) with the rollback command recorded but explicitly NOT executed — a rollback of a live shared dataset is an operator decision, and the snapshot exists so there is time to ask"

requirements-completed: []

duration: 15min
completed: 2026-09-24
---

# Phase 06 Plan 42: CONF-04 Re-Probe After-State Summary

**Measured negative: the mtime change plus the targeted Default-mode refresh did not make Jellyfin re-read the ARTISTS tag — all three pinned rows sit at their 2026-09-20 baselines (0/1/1, not 4/2/2) — and two independent controls prove the round wrote nothing and moved nothing else.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-09-24T13:35Z (first measured remote read: 13:38:51Z)
- **Completed:** 2026-09-24T13:50Z
- **Tasks:** 3 of 3
- **Files created:** 2 artifacts (1,006 lines total)

## Accomplishments

- **Answered question 1 and recorded a negative.** All three pinned rows read AT-BASELINE with a zero `;`-in-entity-name count. Row 1: 0 entities (target 4). Rows 2 and 3: 1 entity each (target 2). The verdicts are emitted in a fixed eight-field `ROW|` block and each one survived independent recomputation from its own `target`/`baseline`/`measured`/`uniqids`/`semis` by `check-music-consumers.sh` § 4b's five-step order.
- **Made the negative interpretable rather than UNKNOWN.** 06-41's `LibraryMonitor` lines named all three Audio items by full internal path, 60 s after a POST that returned 204. The refresh started and reached the items; it changed nothing. Those are different facts and this round's value was telling them apart (T-06-42-01).
- **Answered question 2 from four directions, all clean.** `zfs diff` against the fence is **byte-identical** to 06-41's block (sha `a33ada4a…`) — three M entries, zero sidecar entries, zero DO-NOT-RESCAN entries. The `.nfo` manifest differs on **0 of 91 lines**. All three sidecar counts and fingerprints (91/944/88) are identical. The four D-34 options and `SaveLyricsWithMedia` all hold. `SAFETY: PASS`.
- **Enumerated every row that moved, and the list is empty.** The 1,244-row census delta is **0 changed rows**, with 0 differing lines over all five fields and no path present on one side only. The six OQ-1 `TRUSTFALL` rows are unchanged in count and Id set — the negative control held.
- **Corroborated independently, on untouched code, before any branch was computed.** The deployed instrument ran from its own deployed path and reported `JF_AT_TARGET: 0`, `JF_PENDING: 3` (sum 3, the pinned rows) with `FAILURES total: 0`. Two instruments, two routes, one answer.

## Task Commits

1. **Task 1: read the three pinned rows and the whole census back** — `8b1b917` (docs)
2. **Task 2: the four-way safety re-assert** — `ee82fb2` (docs)
3. **Task 3: re-run the deployed, unmodified instrument** — `f85e539` (docs)

## Files Created/Modified

- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-42-conf04-reprobe-after.txt` (654 lines) — SECTIONS C–K: the three rows with per-row three-state verdicts and the parseable `ROW|` block, the full census, the empty `CENSUS DELTA` block, the OQ-1 negative control, the post-refresh `ZFS DIFF POST` block, the sidecar manifest comparison, the option re-read, the beets/D-32 fence check, and the `SAFETY:` halt gate.
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-42-consumers-rerun.txt` (352 lines) — the seven fixed-format lines, the four-part argument for why `MEASURED` is earned, the in-band interpretation of exit 3, and the full ANSI-stripped 217-line transcript.

## The Measurement

| Row | internal path | target | baseline | measured | uniq Ids | `;` | verdict |
|-----|---------------|--------|----------|----------|----------|-----|---------|
| 1 | `…/Lady Gaga/ARTPOP (2013)/CD 01-05 … Jewels n’ Drugs.flac` | 4 | 0 | **0** | 0 | 0 | AT-BASELINE |
| 2 | `…/Katy Perry/Teenage Dream (2010)/CD 01-03 … California Gurls.flac` | 2 | 1 | **1** | 1 | 0 | AT-BASELINE |
| 3 | `…/P!nk/The Truth About Love (2012)/CD 01-04 … Just Give Me a Reason.flac` | 2 | 1 | **1** | 1 | 0 | AT-BASELINE |

Settle window: `READBACK_UTC` 1790257176 − `POST_UTC` 1790237579 = **19,597 s**, against a floor of 120.

`PreferNonstandardArtistsTag` is still `true`, so the option did not revert. The prober simply did not run on these files. The mechanism 06-03 hypothesised — "(b) the file's mtime changing" — is now measured and did not fire.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The `.lrc`/`.jpg` fingerprint recipe was undocumented**

- **Found during:** Task 2
- **Issue:** 06-40 SECTION 6 records the three fingerprint *values* but never the command that produced them, only the prose "an aggregate sha256 over the LC_ALL=C-sorted `path<TAB>size<TAB>mtime-epoch` list". Guessing a construction would have made the comparison a test of my guess rather than of the estate — a wrong guess reads as a changed set.
- **Fix:** Computed four candidate constructions on atlantis and used 06-40's own `.nfo` fingerprint (`e99b1992…be7c2`) as an oracle. Exactly one reproduced it: `find <root> -type f -name '*.EXT' -printf '%p\t%s\t%T@\n' | LC_ALL=C sort | sha256sum`. The recovery, and the fact that the other three are wrong constructions rather than findings, is recorded in SECTION H.
- **Files modified:** `artifacts/06-42-conf04-reprobe-after.txt`
- **Commit:** `ee82fb2`

**2. [Rule 3 - Blocking] The host checkout went stale mid-plan, by this plan's own commits**

- **Found during:** Task 3
- **Issue:** Tasks 1 and 2 committed the after-state artifact, moving local HEAD from `e7e5406` to `ee82fb2` while LXC 100 stayed on `e7e5406`. Task 3 requires `HOST CHECKOUT: MATCH` before `INSTRUMENT RUN: MEASURED` may be written, and a `STALE` checkout would have disqualified `BRANCH: A` in 06-43.
- **Fix:** Applied the remedy the plan itself names — `git push origin main`, `git pull --ff-only` on LXC 100, re-verify both HEADs, then run. Both HEADs now read `ee82fb2` and the deployed script's sha256 is byte-identical to the repo copy. The test was not relaxed; the staleness and its cause are recorded in band.
- **Files modified:** none in-repo (a push and a host fast-forward)
- **Commit:** `f85e539`

**3. [Rule 1 - Bug] A stale claim in 06-41 about the host's script copy**

- **Found during:** Task 3
- **Issue:** 06-41 SECTION B asserts the host copy at `/mnt/fast/stacks` is pre-Phase-6 (`c67d497`) and carries no `ARTIST_PROOF_ROWS`. Left unchallenged, a later reader would conclude the deployed instrument cannot see the pinned rows and would invent a copy step the plan forbids.
- **Fix:** Measured the host copy: sha256 `1ed695cf…ee819`, byte-identical to the repo copy, table present, working tree clean. Recorded as a correction in `06-42-consumers-rerun.txt`, framed as superseding 06-41's run-time-correct statement rather than contradicting it retroactively.
- **Files modified:** `artifacts/06-42-consumers-rerun.txt`
- **Commit:** `f85e539`

### Deliberate Non-Deviations

- **The rows did not move, and nothing was escalated.** The forbidden aggressive per-item refresh mode was not issued, not widened to, and not reachable on any branch. No second refresh, no additional file touched, no `zfs rollback` executed.
- **No instrument script was edited**, so the corroboration is earned on untouched code. 06-44 owns those edits and runs later by construction.
- **`exit 3` was left alone.** `FAILURES total: 0` confirms the pending gate fired, not the failure gate. It is recorded, and it is deliberately not an input to 06-43's branch — the MA row holds it at 3 whichever way the Jellyfin half reads.

## Authentication Gates

None. The Jellyfin API key was read from `/mnt/fast/secrets/jellyfin-deercrest.env` (measured mode `600 root`), sourced without `set -a`, and delivered through `-H @<(printf ...)` so it never entered argv on a host whose `/proc` is world-readable. Its contents are recorded in neither artifact.

## Known Stubs

None. This plan produced no code — two measurement artifacts only.

## Threat Flags

None. Every Jellyfin call was a GET against endpoints 06-40 already used; no new network endpoint, auth path, file-access pattern or schema change was introduced. Zero POST/PUT/DELETE were issued, and nothing under `/mnt/tank/media` was written, moved, chowned, chmodded or snapshotted.

## What This Hands 06-43

- `SAFETY: PASS` — no operator decision is needed about the estate's integrity.
- Three `ROW|` lines all reading `verdict=AT-BASELINE`, each recomputable from its own numbers.
- `INSTRUMENT RUN: MEASURED` over `HOST CHECKOUT: MATCH`, with `JF_AT_TARGET: 0` and `JF_PENDING: 3` — which is what 06-43's branch recompute reads.
- The fence `tank/media/Music@pre-06-41-conf04-reprobe` still standing, and its rollback command recorded and unexecuted.

The open question 06-43 owns: what a measured negative means for CONF-04. The evidence says the option is correct, the refresh reached the items, and the prober still did not re-read the tag — consistent with `check-music-consumers.sh` § 4b's own recorded expectation that this discharges on Phase 7's first write rather than by rescanning.
