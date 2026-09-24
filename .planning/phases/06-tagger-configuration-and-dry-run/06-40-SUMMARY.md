---
phase: 06-tagger-configuration-and-dry-run
plan: 40
subsystem: infra
tags: [jellyfin, zfs, beets, conf-04, before-state, read-only, artist-entities]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-03's measured finding that a targeted Default-mode refresh does not re-run the audio prober on a file whose mtime has not changed, and the lever it named — '(b) the file's mtime changing'"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "scripts/check-music-consumers.sh ARTIST_PROOF_ROWS / JELLYFIN_D34_OPTIONS — the pinned table this plan measures against and derives its touch list from"
provides:
  - "The complete dated before-state for the CONF-04 Jellyfin re-probe: artifacts/06-40-conf04-reprobe-before.txt, 1,810 lines, sections 0-9"
  - "The 1,244-row ArtistItems census, TSV, LC_ALL=C sorted by path — 06-42's diff basis"
  - "The three pinned rows in full at their 2026-09-20 baselines (0, 1, 1) with entity names, Ids and item Ids"
  - "The four D-34 options read with has() rather than jq's // — PreferNonstandardArtistsTag true, the three freeze fields false"
  - "A per-file sha256+mtime manifest of all 91 .nfo under tank/media/Music, plus .lrc/.jpg counts and fingerprints — the write-detection control"
  - "The resolved, mechanically proved three-path touch list for 06-41, with the construction recorded as a reusable recipe"
  - "The six OQ-1 TRUSTFALL DO-NOT-RESCAN rows listed by name with their entity Ids"
affects: [06-41, 06-42, 06-43, 06-45, phase-07-entry-criterion-E6]

tech-stack:
  added: []
  patterns:
    - "Ship the source-of-truth script to the measuring host over ssh STDIN from a quoted heredoc, assert its sha256 against the workstation copy BEFORE parsing it, then derive the work list from it by prefix substitution — never retype a path"
    - "Prove a derived list with two instruments that share no code (awk extraction + cmp, and an independent grep -qF against the same script), so a bug in the extractor cannot satisfy both"
    - "Record mtimes as ISO-8601 UTC AND as epochs, so the artifact is TZ-proof and a later reader never has to guess"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-40-conf04-reprobe-before.txt"
  modified:
    - ".planning/ROADMAP.md"
    - ".planning/STATE.md"

key-decisions:
  - "The plan's claim that the Jellyfin container 'is at 192.168.90.25 today' is FALSE — docker inspect returned 192.168.90.17 at run time. Recorded as measured in the artifact, the ROADMAP and STATE rather than transcribed from the plan. The rule (resolve fresh, never pin) is untouched and is why the number was measured at all."
  - "The .lrc (944) and .jpg (88) sets get counts plus one path+size+mtime fingerprint sha256 each, rather than a per-file manifest. The plan required counts; a thousand extra lines would have buried the .nfo manifest that is the actual control. The fingerprint is labelled in band as a path+size+mtime hash and NOT a content hash."
  - "The touch list was built and proved on atlantis from a sha256-verified copy of check-music-consumers.sh, not from a list assembled at the workstation. The workstation's copy of the script is HEAD; the host's copy at /mnt/fast/stacks is pre-Phase-6 (c67d497) and does not carry ARTIST_PROOF_ROWS at all, so parsing the host copy would have silently produced an empty list."
  - "A seventh assertion (e2) was added beyond the plan's (a)-(f): each reverse-substituted path must be findable in the script with grep -qF. It shares no code with the awk extractor that produced the list, so the two cannot fail together."

patterns-established:
  - "Pattern: a corrupted STATE.md multi-line field is repaired by REJOINING the orphaned continuation, never by deleting it — and the repair is recorded in band so the fourth instance of the defect class is visible as a pattern rather than as a one-off"
  - "Pattern: 'could not look' is carried through every branch — each measurement's failure path writes UNKNOWN, explicitly labelled as NOT a zero, NOT a false, NOT 'fewer files'"

requirements-completed: []

duration: 17min
completed: 2026-09-24
---

# Phase 6 Plan 40: CONF-04 Re-probe Before-State Summary

**Every fact the CONF-04 re-probe could move is now a dated, sourced number — the three pinned rows
sit at 0, 1, 1 exactly as recorded on 2026-09-20, `PreferNonstandardArtistsTag` reads `true` so the
round's premise is live, and the three-path touch list is derived from the assertion table rather
than retyped and mechanically proved to exclude all six DO-NOT-RESCAN rows — with nothing written,
no snapshot taken and no permission changed.**

## Performance

- **Duration:** ~17 min
- **Started:** 2026-09-24T06:13:28Z
- **Completed:** 2026-09-24T06:30:00Z
- **Tasks:** 3 of 3
- **Files modified:** 3 (1 artifact created, ROADMAP.md and STATE.md updated)

## Accomplishments

- **The round's premise was measured, not assumed.** `PreferNonstandardArtistsTag` reads **`true`**
  and `UseCustomTagDelimiters` / `SaveLocalMetadata` / `EnableRealtimeMonitor` all read **`false`**,
  each via `has($k)` rather than jq's `//` — which treats `false` as empty and would have reported a
  correctly-false option as ABSENT. The Music library `ItemId` was **read back** from
  `/Library/VirtualFolders` and asserted equal to the pinned `JELLYFIN_MUSIC_LIBRARY_ID`; a mismatch
  would have meant the entire round was aimed at a recreated object.
- **The three pinned rows read 0, 1, 1** — the 2026-09-20 Jellyfin baselines, unmoved. The plan's
  halt condition did not fire and no number needed smoothing or escalating. Entity names, entity
  Ids, item Ids, the `;`-in-name count (0 on all three) and the flat `Artists` list (recorded as
  diagnosis only, never asserted) are all captured.
- **The census is complete, not truncated:** `TotalRecordCount` **1244** equals the returned array
  length, both recorded explicitly, and the length distribution (30 / 1208 / 5 / 1) is identical to
  06-03's. One TSV line per item, `LC_ALL=C` sorted by path, so 06-42 can enumerate every moved row
  by name.
- **The write-detection control is in place:** all **91** `.nfo` under `/mnt/tank/media/Music`
  hashed individually with mtimes — Phase 1's number, unmoved — beside `.lrc` **944** and `.jpg`
  **88** with a path+size+mtime fingerprint each.
- **Both fences are confirmed:** `tank/media/Music@pre-06-41-conf04-reprobe` asserted **ABSENT**
  with `grep -qxF` (so a name merely *containing* the string could not satisfy it), and D-32's
  `tank/downloads@pre-phase5` asserted **PRESENT**.
- **The touch list is derived and double-proved.** `check-music-consumers.sh` was shipped to
  atlantis over ssh STDIN from a quoted heredoc, its sha256 asserted byte-identical to the
  workstation copy *before* parsing, and the three paths extracted from `ARTIST_PROOF_ROWS` then
  prefix-substituted. All six planned assertions PASS — 3 lines, all `test -f`, all beginning with
  `/mnt/tank/media/Music/` by `index()==1` rather than a substring match, `TRUSTFALL` substring
  count **0**, `cmp -s` byte-identical on the reverse substitution including the U+2019, and three
  content sha256 values — plus an independent seventh that shares no code with the extractor.
- **Nothing was written, and that is a measurement rather than a promise.** GET only; zero
  POST/PUT/DELETE; zero snapshots; zero permission changes and none attempted. The
  `tank/media/Music` snapshot set was re-read twice after the first read and was byte-identical
  both times. All four `/tmp` scratch files were deleted and verified absent — `/tmp/06-40-*` on
  atlantis is empty.

## Task Commits

1. **Task 1: The Jellyfin before-state — census, the three pinned rows, and the D-34 options** —
   `d5f49cd` (docs)
2. **Task 2: The filesystem before-state on atlantis — mtimes, every `.nfo`, and the snapshot
   inventory** — `f309bdb` (docs)
3. **Task 3: Resolve and prove the touch list — three paths, zero of them DO-NOT-RESCAN** —
   `69cd2a8` (docs)

**Plan metadata:** see the final `docs(06-40)` commit (SUMMARY.md + STATE.md + ROADMAP.md).

## Files Created/Modified

- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-40-conf04-reprobe-before.txt`
  — the whole product of this plan. 1,810 lines. Sections 0 (provenance and the endpoint audit),
  1 (the four D-34 options), 2 (the three pinned rows in full), 3 (the 1,244-row census),
  4 (the six OQ-1 DO-NOT-RESCAN rows), 5 (the three pinned files on disk), 6 (the `.nfo` hash
  manifest and the `.lrc`/`.jpg` counts), 7 (the dataset and its snapshots), 8 (beets' own state
  and the D-32 fence), 9 (the resolved touch list, the six assertions, and the reusable recipe).
- `.planning/ROADMAP.md` — 06-40 ticked; the Phase 6 progress cell moved 39/45 → 40/45 and gained a
  wave-18 paragraph. The pre-existing Notes cell was **appended to by hand**, not regenerated:
  `roadmap.update-plan-progress` has wiped a multi-thousand-character Notes cell on this repo before
  while `--stat` looked correct.
- `.planning/STATE.md` — the round-5 wave-18 block, the frontmatter counters, **and a repair**
  (see Deviations).

## Decisions Made

See `key-decisions` in the frontmatter. The load-bearing one: the artifact records the Jellyfin
route **as measured** (`192.168.90.17`), contradicting the plan's own text, with the contradiction
stated in band in all three places a reader might look.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] STATE.md had been corrupted by a `state.*` write before this plan started**

- **Found during:** Task 3 wrap-up, while preparing the state update (`git diff .planning/STATE.md`)
- **Issue:** The `Plan:` field had been replaced with a bare `Plan: 1 of 45`, orphaning its
  continuation `dispositioned all 24 findings of 06-REVIEW.md; re-verification is 6/6…` as a
  dangling sentence fragment under a new line. `Status: Ready to execute` → `Status: Executing
  Phase 06` did the same to `against 06-REVIEW-GAP.md (GC-01 blocker …)`. This is the documented
  `state.*` multi-line-field defect; STATE.md itself records two prior instances and this is the
  fourth.
- **Fix:** Both continuations rejoined by hand — `Plan: 40 of 45 executed. Round 1 (06-15..06-21,
  waves 6-9, 2026-09-22) closed CR-01 and` / `Status: Executing Phase 06 — gap-closure ROUND 5,
  wave 18 (plan 06-40) COMPLETE. Round 2 ran`. **Nothing was deleted.** The position was also
  corrected: the SDK wrote `1 of 45` while the plan executing was 40.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `git diff .planning/STATE.md | grep '^-[^-]'` returns exactly four lines — the
  timestamp, and the three lines deliberately rewritten. No content line was lost.
- **Committed in:** the final metadata commit

**2. [Rule 2 - Missing critical verification] A seventh touch-list assertion (e2) was added**

- **Found during:** Task 3
- **Issue:** The plan's assertion (e) compares the reverse-substituted touch list against the
  script's internal paths — but both sides descend from the same `awk` extraction, so a defect in
  the extractor would satisfy the comparison while producing a wrong list.
- **Fix:** Added (e2): each reverse-substituted path must be findable in the shipped script with
  `grep -qF`. It shares no code with the extractor, so the two instruments cannot fail together.
  Recorded in the artifact with its own PASS verdict and its rationale stated in band.
- **Files modified:** the artifact (Section 9)
- **Verification:** driven — all three paths found, `(e2) … PASS`
- **Committed in:** `69cd2a8`

**3. [Rule 1 - Bug] Section 4's DO-NOT-RESCAN listing was mangled by an external sort on a
multi-line record, and was re-run**

- **Found during:** Task 1, on first inspection of the output
- **Issue:** The six TRUSTFALL rows were emitted as three-line records and then piped through
  `sort -t'|' -k2`, which sorted the individual lines and separated every `names:` / `ids:` line
  from the path it belonged to. Every value was correct; the association between them was destroyed
  — the worst shape for a record whose whole job is to say *which* six files must not be touched.
- **Fix:** Sorting moved inside `jq` (`sort_by(.Path)`), no external sort. The whole Task 1 capture
  was re-run rather than patched, so the artifact carries one coherent timestamp.
- **Files modified:** the artifact (Section 4)
- **Verification:** re-read — six rows, each with its own names and Ids adjacent
- **Committed in:** `d5f49cd`

---

**Total deviations:** 3 auto-fixed (2× Rule 1, 1× Rule 2)
**Impact on plan:** No scope change. Two are defects in this plan's own instruments, caught by
reading the output rather than by an assertion — which is itself the phase's recurring lesson. The
third is a pre-existing corruption in a file this plan was required to update.

## Issues Encountered

**The plan's stated Jellyfin address was wrong, and the artifact says so.** 06-40-PLAN.md asserts
the container "is at 192.168.90.25 today" and that 06-03's `192.168.90.17` is stale. `docker
inspect` returned **192.168.90.17**. The rule the plan was defending — resolve fresh via `docker
inspect` on `t3_proxy`, never pin a literal — is exactly what surfaced the discrepancy, and is
untouched. The measured value is recorded in the artifact, the ROADMAP and STATE, each with the
correction stated rather than the number quietly swapped.

**The host copy of `check-music-consumers.sh` is not the source of truth.** LXC 100's
`/mnt/fast/stacks` is at pre-Phase-6 `c67d497` and does not carry `ARTIST_PROOF_ROWS`; parsing it
would have produced an **empty** touch list and an (a)-assertion failure rather than a wrong list,
but only by luck. The workstation copy at HEAD was shipped to atlantis and sha256-verified before
parsing.

**`find -xdev` hid the beets state.** `/mnt/fast/appdata` is not a mountpoint — only its children
are datasets — so the first search for `library.db` returned nothing at all. Re-run without `-xdev`
and cross-checked against `docker inspect beets-flask`'s `/config` bind, which is the reason the
path in the artifact is sourced rather than guessed.

## User Setup Required

None. This plan is read-only on the estate and required no operator action. **06-41 is
`autonomous: false` and gates on the operator before it mutates anything.**

## Known Stubs

None. This plan produces one artifact and every section in it is measured.

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema was introduced — this plan
issues GETs and reads.

## Self-Check: PASSED

Verified after writing this summary, against disk and `git log`, not against the text above:

- `artifacts/06-40-conf04-reprobe-before.txt` — FOUND (1,810 lines, 10 `SECTION n` headings:
  0-9 plus the END banner's reference)
- `06-40-SUMMARY.md` — FOUND
- Commits `d5f49cd`, `f309bdb`, `69cd2a8`, `a9dfb9c` — all FOUND
- `git status --porcelain` — clean; nothing left uncommitted
- Forbidden-token screen over the artifact: the aggressive refresh mode's literal token count is
  `0` and the "replace all metadata" phrase count is `0`
- Credential screen over the artifact: no `MediaBrowser Token` value, no `X-Emby-Token` value, no
  `*ArrApiKey`, no MA password. The credential file's MODE (`600 root`) is recorded; its contents
  are not
- `/tmp/06-40-*` on atlantis: empty — every scratch file deleted and verified absent
