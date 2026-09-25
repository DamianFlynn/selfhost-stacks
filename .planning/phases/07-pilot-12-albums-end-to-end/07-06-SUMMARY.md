---
phase: 07-pilot-12-albums-end-to-end
plan: 06
subsystem: music-pipeline / pilot sample and oracle
tags: [d-04, d-05, d-06, d-07, d-26, qual-03, impt-01, e6, e2, sample, expected-tree]
requires:
  - 06-SAMPLE.md and 06-EXPECTED-TREE.txt @ cb9f49a (the Phase 6 draw and oracle)
  - /mnt/fast/safety/phase06/ fence scripts + audit.json
provides:
  - 07-SAMPLE.md — the twelve named by P-ID and full path, with the ONE execution order and the machine-readable EXECUTION SET / DJ TWINS lines 07-12 and 07-13 consume
  - 07-EXPECTED-TREE.txt — 132 FROZEN lines (byte-identical from cb9f49a) + 207 APPENDED lines
  - artifacts/07-06-draw.txt — derivation transcript, twice-run digests, D-26 table, four byte-identity digests
affects: [07-07, 07-10, 07-12, 07-13]
tech-stack:
  added: []
  patterns:
    - "declaration committed alone before measurement; section digest re-proved after the append"
    - "in-container reads via docker exec -i with the program on stdin (or -c text); nothing staged in /config"
    - "positive control driven before an empty eligible set was believed"
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/07-SAMPLE.md
    - .planning/phases/07-pilot-12-albums-end-to-end/07-EXPECTED-TREE.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-06-draw.txt
  modified: []
decisions:
  - "E6 second measurement NOT TAKEN: 0 of 159 fresh folders / 3,163 files carry >=4 artists (only 9 files carry ARTISTS at all, each with 1 entry); the reader fires 4/4 on the library's Jewels n' Drugs control. F1 reallocated to a fourth D-06 draw."
  - "Drawn: P09 VA-Mastermix.90.s.12.inch.USB.Top.Up-2024, P10 Now 117 (2-disc FLAC), P11 Mastermix_Issue_415, P12 Now 116, all from unsorted/. DJ TWINS AMONG FRESH DRAWS: P11."
  - "P11's appended lines are rendered through the DJ branch (albumtype=dj) because the declared order sends every twin to 07-13, which routes it by D-08 like P07/P08; done by labelling its generator input S5, with the generator unchanged. P09 is DJ content but not a twin, so it stays in 07-12 and renders under Various Artists/ (rule 6)."
  - "D-26 predicate TRUE on both S5 folders; E2's bootleg gate stays untested-by-import and carried."
metrics:
  duration: "~75 min"
  completed: 2026-09-26
  tasks: 3
  files: 3
---

# Phase 7 Plan 06: The Twelve Named Before the Run Summary

Committed the pilot's twelve albums before the run, using a seeded draw whose targets were committed before any eligible set was known. The ≥4-artist slot was recorded NOT TAKEN because no folder in the population has that shape, and a positive control fired first. Also committed the oracle: 132 lines carried byte-identical from `cb9f49a` plus 207 lines rendered by the unmodified Phase 6 generator.

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | `70cd38c` | **Declaration anchor.** `07-SAMPLE.md` holds only the declaration: slots, exclusions (S6 library / S4 bucket B / D-01 mechanical), population, F1 predicate and NOT TAKEN rule, seed and key, P-IDs, `### EXECUTION ORDER` and both `EXECUTION SET` lines. No eligibility count, drawn fresh folder or measured attribute (read by eye; the only estate numbers are quoted from earlier commits and labelled). |
| 2 | `d64f638` | The draw, the twelve-row table, the D-18 register, D-26, the `%aunique{}` prediction, and what the sample does NOT cover. |
| 3 | `88beeff` | `07-EXPECTED-TREE.txt` with FROZEN and APPENDED sections. |

## Results

- **The eight reused folders:** all present, checked by `test -d` from atlantis as real root. Their field view reproduces 06-SAMPLE's table and D-18 register.
- **Population:** 165 folders / 3,275 files including the reused folders, against the expected 162 / 3,236. The extra +3 / +39 are all new `music/` downloads, and `unsorted` reproduces 119 / 2,705 exactly. The draw's population is 159 folders / 3,163 files.
- **F1:** 0 eligible, so the result is **E6 second measurement: NOT TAKEN — eligible set empty**.
- **The draw:** ran twice. `population-a/b`, `draw-a/b` (JSON and log) and `fields-a/b` are byte-identical pairs, with 0 lines of difference.
- **The fresh four (P09–P12):** 207 files, 0 WAV. P10 is a second multi-disc release and renders under `Various/`, not `Various Artists/`. P09 has no `track` on any file, so every name renders `00`. P11 has two `album` values and is the **first pilot folder carrying `TKEY` and `TXXX:EnergyLevel`** (9 of 10 files).
- **D-26:** TRUE on `Mastermix.Issue.420.2021` and TRUE on `Mastermix.Issue.421.2021`. For information only, P11 would read FALSE.
- **Oracle, frozen section:** the two selectors (stratum, source prefix) agree on the 132 lines. Four digests were taken (shasum and openssl, on the `git show` extraction and on the file section) and all equal `2f7c1127…`. The plan's line-by-line verify passes.
- **Oracle, re-derivation:** re-deriving all 132 reused lines today gives the FROZEN lines exactly, including the 20 S5 lines. So the config has not changed since the anchor, and nothing needed filing in `deferred-items.md`.
- **Appended lines:** 207, matching the fresh audio total. There are 0 bracketed non-year integers; the recipe was driven first against the `[12]` control (1 hit) and a `[2024]` control (0 hits). 0 duplicate destinations. `:` renders as `_` as expected.
- **Nothing written:** the `/mnt/fast/appdata/arrs/beets/config/` listing is identical before and after (`ca1ff4cf…`). `library.db` is `fbbdde0c…` with 0 items and 0 albums. No container was started or restarted.

## Deviations from Plan

1. **[Rule 2 - Correctness] The F1 reader was driven against a positive control before the empty set was recorded.** I ran the same program over the library's S6 folders and it read `Jewels n' Drugs` as 4/4 (CONVENTIONS rule 1: a recipe that never matches is not evidence of absence). The raw-reader ID3 branch has no positive reading, because no MP3 in the population carries `TXXX:ARTISTS`. This is stated as a limitation.
2. **[Rule 3 - Blocking] The byte-identical `phase06-fields.py` was run with `-c "$(cat …)"` and the folder list on `/dev/stdin`.** It takes its folder list as a file argument, and this route avoids staging that list in `/config`.
3. **P11's generator input was labelled S5** (see decisions). It is an input-selection choice with no code change, and it follows from the declared routing of twins to 07-13. The header records it under P2.

## Operator Notes

- Two of the four fresh draws are Mastermix DJ content, and two are *Now!* volumes outside `1-115`. The seeded key chose them, not a person.
- **P09 (100 files, DJ content, not a name twin) stays in 07-12's set** and imports as an ordinary album under `Various Artists/`. If DJ routing is wanted for it, that is an operator call for 07-12. This plan did not make it.
- P11 moves to 07-13 via 07-12 Task 1 (`MOVED TO 07-13: P11`). Its QUAL-02 diff may read UNKNOWN (exit 3) because of 07-02's AMBIGUOUS arm.
- The `%aunique{}` prediction depends on the match. If MusicBrainz stores the same `label` on P02 and P04, the numeric-id fallback becomes reachable.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: 07-SAMPLE.md, 07-EXPECTED-TREE.txt, artifacts/07-06-draw.txt
- FOUND commits: 70cd38c, d64f638, 88beeff; declaration commit precedes the draw commit
- `823fe04` is still an ancestor of HEAD
