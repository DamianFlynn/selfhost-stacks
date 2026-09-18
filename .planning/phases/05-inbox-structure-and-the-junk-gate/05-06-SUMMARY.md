---
phase: 05-inbox-structure-and-the-junk-gate
plan: 06
subsystem: now-collection-split-mapping
tags: [derived-grouping, two-instrument, approval-gate, dry-run-default, read-only, D-02, D-03, D-05, D-06, D-07, D-09, D-13]
requires:
  - "05-01 — tank/downloads@pre-phase5 and the _inbox tree (proof read, not used mutatively; this plan writes nothing to tank)"
  - "05-04 — the junk sweep, which removed 9 of the 14 sidecars; the surviving 5 are what this plan routes"
  - "05-05 — now-tags.ndjson (4,746) and now-manifest.ndjson (4,770), the two inputs"
provides:
  - "scripts/phase05-now-split.sh — plan (read-only) and apply (gated), 1,085 lines"
  - "host:/mnt/fast/safety/phase05/now-split-map.tsv — 4,751 approvable rows, sha256 9ef5da2b…1fba9"
  - "host:/mnt/fast/safety/phase05/now-volume-numbers.tsv — 119 directories -> 115 volume numbers, rule per row"
  - "host:/mnt/fast/safety/phase05/now-album-aliases.tsv — 117 album strings -> one volume each"
  - "host:/mnt/fast/safety/phase05/now-cross-volume-collisions.tsv — the 4 survivors of the merge, each decided"
  - "host:/mnt/fast/safety/phase05/now-missing-tracks.tsv — 13 missing tracks, named track by track"
  - ".planning/…/05-NOW-INVENTORY.md § AMENDMENT 2026-09-18 — operator decisions 1 and 2 recorded"
affects: [05-07, 05-08, 05-09, 05-11, 06]
tech-stack:
  added: []
  patterns:
    - "derive a grouping into a FILE a human can read, with the rule that fired recorded per row, before 4,751 irreversible renames"
    - "seed a cross-check table only from unambiguous rows — seeding it from the collided rows would make the instrument read its own tie-break"
    - "break a placement tie with the file's own embedded metadata, never with source-list order, and record the rejected claim beside the winner"
    - "assert total coverage of a derived integer range (exactly 1..115, no gaps) rather than counting the rows and hoping"
key-files:
  created:
    - scripts/phase05-now-split.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-06-volume-numbers.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-06-album-aliases.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-06-cross-volume-collisions.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-06-missing-tracks.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-06-split-reconciliation.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-06-split-plan.log
  modified:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/05-NOW-INVENTORY.md
key-decisions:
  - "Volume numbers come only from the manifest DIRECTORY component, via a stated rule chain with the rule recorded per row; no regex is applied to any album value anywhere in the tool"
  - "The album alias table is seeded ONLY from files whose leaf is claimed by exactly one volume — seeding from collided files would make the cross-check depend on the tie-break that reads it"
  - "The 4 surviving cross-volume collisions are decided by the file's own album tag, with the rejected claim recorded in the map row itself; zero were guessed and zero needed operator review"
requirements-completed: []
duration: ~55 min
completed: 2026-09-18
---

# Phase 5 Plan 06: The Derived Grouping Is Four Files a Human Can Read Summary

**4,751 rows of mapping produced with nothing moved, 119 manifest directories reduced to exactly
115 volume folders under a driven total-coverage assertion, and the two independent instruments
disagreeing on ZERO of 4,746 files — while the collision 05-05 called this plan's hardest problem
turns out to be 4 files, not 23, and every one was settled by its own embedded album tag rather
than guessed.**

## Performance

- **Duration:** ~55 min
- **Completed:** 2026-09-18T20:48Z
- **Tasks:** 2
- **Commits:** 3 (plus this one)
- **Plan-mode wall clock on LXC 100:** 32 s for 4,746 files against a 4,770-line manifest

## What the mapping actually says

Read before trusting: the mapping is a **point-in-time view** of a tree written at ~1 music job per
72 s. It was taken **2026-09-18T20:45Z**. Plan 05-07 re-validates every row against live state
before it acts, which is built into `apply` rather than left as procedure.

| Measure | Value |
|---|---:|
| map rows | **4,751** — 4,746 mp3 + 5 kept sidecars |
| mapped to a volume | 4,746 |
| routed to `99-quarantine/now-volume-disagreement/` | **0** |
| kept sidecars | 5 |
| refused by the per-row fence | 0 |
| distinct volume folders in the map | **115** |
| destinations containing a `CD1`/`CD2` component | **0** (D-05, flat) |
| distinct source paths / distinct destination paths | 4,751 / 4,751 |

The four buckets are disjoint and sum to `files_seen` = 4,751, asserted rather than printed. Every
file appears **exactly once**, checked as a duplicate-key count on both sides of the map — a file
cannot be moved twice, and a destination cannot be claimed by two sources.

## The volume derivation, and the assertion that makes it trustworthy

119 distinct manifest directories → **exactly the integers 1 through 115, each appearing at least
once, nothing out of range, nothing unparsed.** The rule that fired is recorded per row in
`05-06-volume-numbers.tsv`, so the number assignment is readable without reading the code:

| Rule chain | Rows | Notable |
|---|---:|---|
| `year-prefix+trailing-number` | 104 | the plain case |
| `year-prefix+bracket+trailing-number` | 13 | the `[2019 Reissue]`, `[2020 Reissue]`, `[2021 Reissue]`, `[First 2CD Release]` and the two `1CD` pressings |
| `year-prefix+paren+trailing-number` | 1 | `…! 64 (Last audio cassette release)` — a **parenthesised** annotation, which a bracket-only rule would have mis-parsed |
| `year-prefix+bracket+no-number-is-volume-1` | **1** | volume 1's `1983. …! [2018 Reissue, Remastered]` — D-03's numberless case |

The numberless rule is **asserted to fire exactly once**. If a second directory ever yields no
number the tool stops rather than silently filing both into volume 1.

**No regex touches an album value anywhere in the tool** (`grep` for a sub/gsub/match against
`album` returns nothing). D-03's trap is in the file with its double space intact, twice.

## The album tag as a real instrument, not a formality

`05-06-album-aliases.tsv`: **117 rows, all `unique`** — every album string maps to exactly one
volume, none flagged as multi-volume, none tied. D-03's three traps all resolve correctly:

| Album string | Volume | Files |
|---|---:|---:|
| `Now That's What I Call Music` (no number at all) | **1** | 30 |
| `Now, That's What I Call Music II` (Roman numeral, comma) | **2** | 30 |
| `Now That's What I Call Music! Vol.36 CD1` | **36** | 16 |
| `Now That's What I Call Music! Vol.36  CD2` (**double space**) | **36** | 20 |
| `Now That's What I Call Music! 36` | **36** | 4 |

**Disagreement count: 0 of 4,746.** Pre-declared as expected-to-be-non-zero, and it is zero. That
is the strongest possible reading of the derivation: two instruments built from entirely different
data — a Windows ripper's CP1252 path list and the ID3 tags inside the files — agree on the volume
of every single file. Nothing was routed to `99-quarantine/now-volume-disagreement/`; the path
exists in the tool, is unused, and is documented in the header as **not junk and not to be
deleted**, so that a later reader of `99-quarantine` cannot mistake its purpose.

**The alias table is seeded only from files whose leaf is claimed by exactly one volume.** That is
not a convenience: seeding it from collided files would make the cross-check depend on the very
tie-break that reads it, and a circular instrument cross-checks nothing. The visible consequence is
in the table — `Now That's What I Call Music 4` shows **43** seeding files, not 45, because its two
collided files are excluded from seeding and then placed by it.

## 05-05's hardest problem was 23 files. After the merge it is 4, and all 4 are decided

Operator decision 1 merges the four variant editions into their volume numbers, which dissolves
**19 of the 23** collisions outright: the competing claims were different editions of the *same*
volume number, so they now resolve to one destination. **4 still cross a real volume boundary**, and
each was settled by the file's own embedded `album` tag:

| File | Claims | Won | Rejected | Deciding album tag |
|---|---|---:|---:|---|
| `01. Duran Duran - The Reflex.mp3` | 3, 4 | **4** | 3 | `Now That's What I Call Music 4` |
| `07. Tina Turner - What's Love Got To Do With It.mp3` | 3, 4 | **4** | 3 | `Now That's What I Call Music 4` |
| `12. Kirsty MacColl - Days.mp3` | 15, 31 | **31** | 15 | `Now That's What I Call Music! 31` |
| `07. Robbie Williams - Angels.mp3` | 39, 100 | **100** | 39 | `Now That's What I Call Music! 100` |

**Zero flagged for operator review. Zero guessed.** The rejected claim is carried in the map row
itself (`manifest+albumtag(won=4;rejected=3)`), not only in a side file, so an operator reading the
mapping meets the decision where the file is placed rather than having to cross-reference it.

**The count is 4, not the 1 the plan context anticipated.** The context named `01. Duran Duran - The
Reflex.mp3` as the known boundary-crossing case; three more survive the merge (`Tina Turner` also
3↔4, `Kirsty MacColl` 15↔31, `Robbie Williams` 39↔100). All three extra ones are visible in
`05-05-collided-files.tsv` and were simply not enumerated there by volume number.

## The consequence nobody had measured: the tie-break makes the loser volume short

This is the finding worth carrying forward. A physical file can be placed **once**, so each
tie-break leaves the losing volume short by one file — and that shortfall shows up in the per-volume
identity looking exactly like missing audio. It is not.

**13 tracks are named as missing across 10 (volume, disc) groups** — not the 11 the operator
decision was framed on, and the difference is entirely bookkeeping:

| Cause | Tracks | Volumes |
|---|---:|---|
| **Missing from the source rip** (pre-declared) | **5** | 18, 52, 70, 83, 98 — one each |
| The tie-break placing a file once rather than twice | 4 | 3 (×2), 15, 39 |
| Volume 8's per-disc imbalance, which 05-05 recorded as a cancellation | 4 | 8 disc 2, tracks 9–12 |

**Only 5 of the 13 are genuinely absent audio.** Every one is named by volume, disc and track number
in `05-06-missing-tracks.tsv`, which is what the operator asked for and what a count could never
give: a count cannot be checked against the source rip, a track number can.

The two 1CD volume-4 variants that decision 2 described as short by 4 and by 2 **do not appear** in
the post-merge list at all: merged into `Vol 004`, the union covers every track number its modal
expectation names.

## The merge re-creates D-04's surplus — and it is the same artefact, recorded not banked

Post-merge the per-volume identity reports **11 exceptions**, where 05-05 measured 7 per directory:

```
EXC  Vol 003 | 26 | 28 | -2      EXC  Vol 018 | 31 | 32 | -1
EXC  Vol 004 | 45 | 32 | +13     EXC  Vol 039 | 40 | 41 | -1
EXC  Vol 008 | 42 | 33 |  +9     EXC  Vol 052 | 41 | 42 | -1
EXC  Vol 009 | 44 | 31 | +13     EXC  Vol 070 | 42 | 43 | -1
EXC  Vol 015 | 31 | 32 | -1      EXC  Vol 083 | 42 | 43 | -1
                                 EXC  Vol 098 | 45 | 46 | -1
```

**+13 / +9 / +13 is D-04's surplus, reappearing — and it is the artefact 05-05 § 4 dismantled, not a
regression.** Under the merge, volume-number grouping becomes equivalent to the album-tag grouping
for these three families, so a folder holding the union of several editions' files is measured
against a modal `tracktotal` that can only carry one edition's value. Nothing changed on disk
between the two measurements. Volume 9 reads +13 rather than D-04's +14 because the modal
expectation lands on 31 rather than 30. These three rows mean *"merged folder, expectation not
meaningful"* — they must never be read as *"extra files appeared"*, and 05-NOW-INVENTORY.md now says
so in band.

Volumes 3, 15 and 39 are new exceptions for the tie-break reason above; the remaining five (18, 52,
70, 83, 98) are exactly 05-05's pre-declared shortfalls, unchanged. **Line by line against
05-NOW-INVENTORY.md § 3: 5 confirmed identically, 4/8/9 restated as the merge artefact, 3/15/39 are
new and explained by a named decision, and the two 1CD variant rows are gone because their
directories no longer exist as a grouping.**

## Nothing moved, proven rather than asserted

| Check | Result |
|---|---|
| directories at depth 1 inside `NOW_ROOT` | **0** — plan mode created no volume folder |
| `zfs diff tank/downloads@pre-phase5` entries under the collection | **12**, every one plan 05-04's junk sweep (7 `.log`, 2 `play.m3u`, the 2 decoy folders, 1 `M` on the parent). **Zero `R` lines, zero `+`** |
| mp3 count before and after | 4,746 / 4,746 |
| non-mp3 sidecars | 5, matching 05-NOW-INVENTORY.md |
| `apply` was run | **no** |

## Refusals, all driven rather than described

| Refusal | Driven | Result |
|---|---|---|
| `apply` with no map | workstation, no access to tank | **exit 2**, names the expected path |
| `apply` with a map but a proof naming `tank/downloads@spike-03-t0` | workstation | **exit 2**, names the required snapshot and why the stale ones must fail |
| `apply` with a map but the proof file absent | workstation | **exit 2**, prints the exact atlantis command to produce it |
| `plan` with `NOW_ROOT=/mnt/tank/media/Music` | workstation | **exit 2**, its own message citing Phase 1 D-20, naming given/resolved/forbidden/required |
| `plan` with `NOW_ROOT=/mnt/tank/downloads/incomplete` | workstation | **exit 2**, naming both paths |
| no arguments | workstation | **exit 2** |

Both `apply` refusals are the **first statements** of the subcommand, checked before anything else
is required, which is what makes them reachable on a machine that has none of this content.

Static acceptance over the script: `Vol.36  CD2` present **2×** with the double space intact;
`/tmp` outside comments **0**; `Vol %03d` present; no CD subdirectory ever constructed; the
"not junk, must not be deleted" line present in the header.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] The coverage assertion compared awk array indices as STRINGS**
- **Found during:** Task 2, the first run on LXC 100
- **Issue:** `for (v in seen)` yields `v` as a string **always**, regardless of how the key was
  stored, so `v < a` was a string comparison. `"94" > "115"` is true, and the assertion reported
  **96 of 115 correct volumes as "out of range"** on a list that was in fact perfect. It failed
  closed, which is the right direction — but it was a false red on good data, the same shape 05-04
  and 05-05 each recorded twice.
- **Fix:** coerce with `+ 0` before every range comparison and look the missing-side key up as a
  string. The reason is recorded in band so nobody "simplifies" it back.
- **Files modified:** `scripts/phase05-now-split.sh`
- **Commit:** `3ef165b`

**2. [Rule 2 — Missing critical] The plan's row format could not carry a rejected claim**
- **Found during:** Task 1
- **Issue:** the operator decision requires *"record BOTH the winning assignment and the rejected
  claim(s) in the mapping, visibly"*, while the acceptance criteria require exactly five
  tab-separated fields. A sixth column would have broken the shape; a side file alone would have
  left the mapping silent at the one place a decision was made.
- **Fix:** the `source_instrument` field carries it structurally —
  `manifest+albumtag(won=4;rejected=3)` — **and** the detail is emitted to
  `now-cross-volume-collisions.tsv`. Five fields preserved, decision visible in the row.
- **Commit:** `eca968f`

**3. [Rule 2 — Missing critical] A flagged album string would have quarantined a correct volume**
- **Found during:** Task 1
- **Issue:** the plan says an album string mapping to more than one manifest volume is *"flagged in
  the table rather than resolved"*. Taken literally, an album string flagged over **one** collided
  leaf would leave every file carrying it with no alias volume, and D-02's disagreement rule would
  route all 45 files of volume 4 to quarantine over a single ambiguity.
- **Fix:** the table records `unique` / `MODAL-of:<vols>` / `AMBIGUOUS-TIE:<vols>` and the modal is
  used for the cross-check while the flag stays visible; only a genuine **tie** refuses to resolve.
  Combined with seeding from unambiguous rows only, the measured outcome is **117 of 117 `unique`**,
  so no modal was needed and the safeguard was never exercised on real data.
- **Commit:** `eca968f`

**4. [Rule 3 — Blocking] The plan's stated artifact shape did not match measured reality**
- **Found during:** Task 1
- **Issue:** the plan and its acceptance criteria call for `now-volume-numbers.tsv` to have
  **116 rows** (115 volumes + the collection root). Plan 05-05 measured **119** distinct manifest
  volume directories with the collection root **not** among them — the 116 figure predates that
  measurement and the operator decision that resolves it. Writing to 116 would have made the
  coverage assertion unsatisfiable.
- **Fix:** the file carries **119 rows**, one per distinct directory, and the coverage assertion is
  stated over the derived NUMBERS (exactly 1..115) rather than over the row count — which is the
  stronger property the plan was reaching for. The variant-edition merge is asserted separately:
  every duplicated number must carry a recorded variant annotation, or the tool stops.
- **Commit:** `eca968f`

### Deliberately not fixed

- **`scripts/quick-health-check.sh` still exits 1** for the pre-existing, unrelated
  `interpolated-host-path inventory MOVED: expected=12, found=13` red logged in
  `deferred-items.md` by plan 05-02. Not attributable to this plan and not touched.
- **The 5 genuinely missing tracks.** Named by volume/disc/track. Re-acquisition is out of scope
  for this project; the volumes are split anyway per D-09 and operator decision 2.
- **Volume 8's per-disc imbalance** (disc 1 over, disc 2 short by tracks 9–12). Recorded and now
  named track by track, not repaired — repair means fixing a `tracktotal`, which D-10 declined for
  this phase.
- **The `tracktotal` disagreement on merged volumes 4/8/9.** Reported as an exception with its
  cause stated. Phase 6's.

---

**Total deviations:** 4 auto-fixed (1 bug, 2 missing critical, 1 blocking).
**Impact:** the bug was a false red on correct data, caught because the assertion was written to
fail closed and driven against real state rather than trusted. Two of the three others are places
where following the plan's literal wording would have produced a worse artifact than the plan's
stated intent — both are documented in band so the divergence is visible to the operator at the
05-07 gate.

## Issues Encountered

One harness note, recorded rather than dropped: a verification command of mine ended with a remote
`head -3` under `set -o pipefail`, so ssh returned **141** (SIGPIPE) after every assertion had
already printed its correct result. The exit code was mine, not the estate's. It is the same family
as the `timeout N cmd | wc -l` trap the house rules name — a pipeline's status is not the status of
the thing you care about — and the fix is to read the status with nothing downstream of it.

## Evidence

| Check | Result |
|---|---|
| `bash -n` / `--help` prints the header | **exit 0** / yes |
| plan's Task 1 verify (`apply` with no map) | **exit 2** |
| plan's Task 2 verify (map rows / numbered rows / depth-1 dirs) | **4751 / 119 / 0** |
| bucket equation `4746 + 0 + 5 + 0 == 4751` | **balances** |
| map rows == files_seen | **4751 == 4751** |
| rows not carrying 5 fields | **0** |
| src outside `NOW_ROOT`, or not flat | **0 / 0** |
| dst outside `NOW_ROOT/Vol ` ∪ quarantine ∪ in-place | **0** |
| dst containing a `CD1`/`CD2` component | **0** |
| distinct dst volume folders | **115** |
| duplicate src / duplicate dst | **0 / 0** |
| coverage: exactly 1..115, gaps, out of range | **115 distinct / 0 / 0** |
| numberless-directory rule fired | **exactly 1** |
| merged numbers, all carrying a variant annotation | **3 numbers, 7 directories, 0 without** |
| album alias rows, all `unique` | **117 / 117** |
| join: exact / alnum-key / unresolved / manifest-only | **4744 / 2 / 0 / 0** |
| cross-volume collisions: total / resolved / flagged | **4 / 4 / 0** |
| files routed to quarantine | **0** |
| `zfs diff` renames under the collection attributable to this plan | **0** |
| credential screen over the 6 committed artifacts | **0 matches** |

## Known Stubs

None. Every deliverable is a completed derivation over real state, produced by a tool whose
assertions were each driven to failure at least once — including, unintentionally but usefully, the
coverage assertion.

## Still open, deliberately

- **INBX-03 stays UNTICKED.** All requirement ticks belong to plan 05-11.
- **The map is not approved.** `apply` was not run; nothing moved. 05-07 is the operator gate, and
  its first act should be to confirm the map it acts on is still
  `sha256 9ef5da2b9ed8947529689a107c2bf0d20becbe4a6ec3274878179a4eb181fba9`.
- **The 1.34 MB `now-split-map.tsv` is deliberately NOT committed**, matching 05-05's treatment of
  the NDJSON. Its checksum is recorded here and in 05-NOW-INVENTORY.md so the artifact 05-07 acts on
  is provably the one measured.
- **The four tie-break decisions are reversible but are decisions.** If the operator disagrees with
  any of them at the 05-07 gate, the losing volume gains a file and the winner loses one; the map
  row names both sides so the edit is a one-line change rather than a re-derivation.

## Threat Flags

None. This plan added no network endpoint, no auth path and no schema change. It wrote nothing to
`tank`, installed no package from any package manager, and holds no credential.

## Self-Check: PASSED

All seven created files exist on disk. All three commits (`eca968f`, `3ef165b`, `e6c4d1a`) are
present in `git log`. The off-repo deliverables on LXC 100 all exist with the stated counts:
`now-split-map.tsv` 4,751 rows, `now-volume-numbers.tsv` 119, `now-album-aliases.tsv` 117,
`now-cross-volume-collisions.tsv` 4, `now-missing-tracks.tsv` 10, `now-split-reconciliation.txt`
197.

---
*Phase: 05-inbox-structure-and-the-junk-gate*
*Completed: 2026-09-18*
