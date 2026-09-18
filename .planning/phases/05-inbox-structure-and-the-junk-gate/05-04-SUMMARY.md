---
phase: 05-inbox-structure-and-the-junk-gate
plan: 04
subsystem: junk-gate
tags: [approval-gate, destructive, zfs-diff, sweep, rename, D-11, D-13, D-20, D-23]
requires:
  - "05-01 — tank/downloads@pre-phase5 and its proof file; the sweep refuses to run without it"
  - "05-01 — _inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}, the sweep's destinations"
  - "05-03 — scripts/phase05-junk-sweep.sh and the 52-row candidate list that IS the gate"
provides:
  - "A swept music tree: ROADMAP criterion 2 as amended by D-12 with D-14 folded in is TRUE"
  - "/mnt/tank/downloads/lidarr-import RETIRED — Phase 1's D-23 closed here, not passed to Phase 8"
  - "_inbox/02-review pre-seeded with Madonna (60 audio) and Michael Jackson (473 audio)"
  - "99-quarantine holding the two Garth Brooks _FAILED_ directories, 1.92 GB of FLAC, by operator choice"
  - "host:/mnt/fast/safety/phase05/junk-sweep-result.txt — the per-row outcome record"
  - "scripts/phase05-junk-sweep.sh: move-only is now a property of the ROW, not of the rule"
affects: [05-05, 05-06, 05-07, 05-10, 05-11, 06, 07]
tech-stack:
  added: []
  patterns:
    - "move-only is a property of the ROW (a destination field) rather than of the RULE — so an operator can spare an item without relabelling it and weakening its own re-validation"
    - "amend an approved list MECHANICALLY, by one awk program, never by retyping a path that names something about to be destroyed"
    - "drive the amendment procedure itself on a synthetic fixture before pointing it at the live list"
    - "reconcile a destructive run against zfs diff, attributing every removed and renamed line to an approved row — the assertion that catches what nobody listed"
key-files:
  created:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-approval-record.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-junk-candidates-approved.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-junk-sweep-result.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-zfs-diff-reconciliation.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-estate-verification.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-fixture-proof.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-closing-state.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-fixture.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-04-verify.sh
  modified:
    - scripts/phase05-junk-sweep.sh
key-decisions:
  - "Move-only keyed on the destination field, not on rule==R8 — relabelling the two R1 rows R8 would have misreported them AND weakened their TOCTOU re-validation from rule+audio+size down to audio alone"
  - "The eight .covers rows were STRUCK from the list, not redirected — a row in the list is a row the sweep moves, so striking is the only treatment that leaves them provably untouched"
  - "99-quarantine ends non-empty by operator choice, discharging Task 3's acceptance on its second branch with every one of the 51 entries named"
requirements-completed: [INBX-02]
duration: ~60 min
completed: 2026-09-18
---

# Phase 5 Plan 04: The Sweep Ran — 40 Rows Removed, 4 Moved, 8 Untouched Summary

**The junk that would have corrupted every later measurement is gone rather than parked, the
1.92 GB of real FLAC inside a failed job was spared rather than destroyed by rule, and every
removed and renamed path on the dataset is attributed to an approved row by `zfs diff` — zero
unexplained, zero missing.**

## Performance

- **Duration:** ~60 min
- **Started:** 2026-09-18T16:37Z
- **Completed:** 2026-09-18T17:40Z
- **Tasks:** 3
- **Commits:** 4 (plus this one)

## What the operator approved, and what was acted on

The decision gate was satisfied before anything moved. The approval is bound to content by
hash in **both** directions:

| | rows | sha256 |
|---|---:|---|
| as read by the operator | 52 | `126ce3a0793500bea182814f7a2f8adb041b7dce75d1c6b6f28e3f6db3de8f48` |
| as amended, and acted on | 44 | `fe2d3e2ef81451be178fe4c122e66d7075295b19ae822a125296a17b534d72e9` |

The as-read hash is **byte-identical to the copy plan 05-03 committed**, so the content
approved is the content in the repository — asserted, not assumed. It was re-read three
times (at approval, immediately before the amendment, and as the preserved as-read copy) and
re-checked a fourth time **immediately before the first destructive call**, where it matched.

| | rows | disposition |
|---|---:|---|
| R2 `_UNPACK_`, R4 empty directories, R6 named D-06 sidecars | 40 | moved to a quarantine batch, then **removed** |
| R1 `_FAILED_` Garth Brooks ×2 | 2 | **moved to 99-quarantine, never removed** (amendment 2) |
| R8 PROPOSAL Madonna, Michael Jackson | 2 | moved to `_inbox/02-review`, never removed |
| R4 `.covers` | 8 | **excluded entirely — no action of any kind** (amendment 1) |
| | **52** | accounted for |

The amendment was applied by **one awk program**, never by retyping a path — every row here
names something that would be destroyed, and a retyped path is a path that can be mistyped.
A `diff` of rule+path+destination between the as-read and amended files shows exactly two
changes and nothing else: eight `.covers` lines deleted, two R1 lines gaining a seventh
field. A containment check confirmed every surviving row existed **verbatim** in the as-read
file apart from those two.

## The script change, and why it is not the obvious one

The script could only express move-not-remove for rows labelled **R8**. The obvious encoding
of amendment 2 was therefore to relabel the two Garth Brooks rows R8. **That is the wrong fix
twice over**, and the second reason is the one that matters:

1. it misreports *why* the row was proposed — they are `_FAILED_` directories, not D-20 content;
2. it **weakens their TOCTOU protection**. Stage 1 re-derives an R8 row on *audio count alone*;
   a row that keeps its real rule is re-derived on **rule, audio count and size**. Relabelling
   would have quietly traded away two thirds of the guard on the only two rows in the run that
   contain irreplaceable audio.

So move-only became a property of the **row** — does it carry a seventh field naming a
destination? — rather than of the rule. An operator can now spare any row by hand without
touching its rule label, and the strict re-validation follows the label. A destination-less R8
row still fails closed; that branch was preserved explicitly rather than left to survive as a
side effect of the old test.

## The change was driven on a fixture before it was pointed at the estate

Same method 05-03 used: a synthetic tree with `DOWNLOADS` relocated, so the whole scope fence
moves with it. Three runs, **34 assertions, all held**
(`artifacts/05-04-fixture-proof.txt`). The fixture drives the *amendment procedure* too — the
identical awk program, run against a list `enumerate` produced — not merely the script change.

| Run | What it drives | Result |
|---|---|---|
| 1 | positive control: enumerate → amend → sweep. The R1 row moved and **not** removed with its audio intact and its `(devid,inode)` pair unchanged; the R8 row to 02-review; the two destination-less rows moved **and** removed; the batch left empty; the excluded `.covers` untouched | exit 0 ✓ |
| 2 | an R8 PROPOSAL row with **no** destination — the regression this change could have introduced | exit 1, left in place, 0 removed ✓ |
| 3 | the whole-sweep TOCTOU abort still fires: an approved row grows by 10 bytes after approval | exit 1, `size moved`, nothing moved ✓ |

## The run

`sweep` exited **0**. 44 rows approved, **44 moved, 0 move failures, 40 removed, 0 removal
failures.** The script's own re-validation stage passed all 44 rows against fresh state first.

Reclaimed space is **informational only**, as the plan requires: the removed rows total
**572,466,519 B (0.53 GiB)** as measured at enumerate time. ZFS frees asynchronously and
`zfs list` can lag a large removal by about 20 s, so no floor is asserted. Absence is the
instrument that is not subject to the lag, and it is asserted per path.

## Verified three ways, and the third is the one that can catch what nobody listed

**1. The estate, by direct assertion — 28 checks, all held** (`05-04-estate-verification.txt`):

| Check | Result |
|---|---|
| `_FAILED_`/`_UNPACK_` directories across the five music paths, outside 99-quarantine | **0** |
| `*.rar` / `*.r[0-9][0-9]` / `*.part[0-9]*.rar` **files**, same scope | **0** |
| the Potter directory under `unsorted/` | gone |
| the empty 512 B `dj-mixes` decoy | gone |
| all 40 remove rows absent from their original location | 40 / 40 |
| Garth Ropin at 99-quarantine, FLAC count | **10** (matches the approved audio count) |
| Garth Ultimate Hits at 99-quarantine, FLAC count | **34** (matches) |
| Madonna at 02-review, audio count | **60** (matches) |
| Michael Jackson at 02-review, audio count | **473** (matches) |
| the 8 excluded `.covers` directories, each still holding its art | **8 / 8 intact** |
| the 5 value-bearing KEEP sidecars, by `(devid,inode)` | all five unchanged |
| the plan's own verbatim Task 2 `find` | **0** |
| D-22 / criterion 4 — `_`-prefixed directories under `/mnt/tank/media/Music` | **0** |

**2. `zfs diff` against `tank/downloads@pre-phase5`** — the reconciliation, in full at
`artifacts/05-04-zfs-diff-reconciliation.txt`:

| | `+` | `M` | `-` | `R` |
|---|---:|---:|---:|---:|
| before the sweep | 20056 | 2 | **0** | **0** |
| after the sweep | 21036 | 7 | 87 | 4 |
| after the `lidarr-import` rmdir | 22041 | 6 | 88 | 4 |

- the **4 renames are exactly the 4 approved move rows**, to exactly the approved destinations;
- **all 87 removed lines are accounted for**: 40 approved remove rows plus 47 descendants of
  the two `_UNPACK_` directories, which a recursive removal reports individually (29 under
  Katy Perry, 20 under Ed Sheeran, the directories included);
- **0 unexplained**, **0 approved rows missing**, **0 destructive lines under `incomplete/`
  (D-15) or `/mnt/tank/media` (D-20)**, **0 touching any of the 8 excluded `.covers`
  directories or 5 KEEP sidecars**;
- diffing the destructive lines of the last two captures returns exactly **one** new line —
  `- /mnt/tank/downloads/lidarr-import`, this plan's `rmdir`, and nothing else.

The `+` growth is SABnzbd's own churn under `incomplete/` and is **not** attributable to this
plan; the in-scope claim is carried entirely by the `-` and `R` analysis.

**3. The sweep's own per-row record** — `05-04-junk-sweep-result.txt`, every row named with
one of moved / removed, and no failures to explain.

## lidarr-import retired, D-23 closed

Both artist folders moved out as **renames** (`lidarr-import` and `_inbox` are both devid 68 —
one dataset, atomic inode-preserving `rename(2)`), and the directory was then removed with
`rmdir`, the **empty-only** form. No recursive removal was used and none could have been.
Phase 1's D-23 is closed here rather than passed to Phase 8.

**The D-17 / D-20 tension, stated rather than hidden:** D-17 says the tree is created empty and
only 99-quarantine receives content; D-20 explicitly permits routing these two folders to the
inbox, and D-20 is the more specific decision, so it governs. **Phase 6 and Phase 7 must not be
surprised: `_inbox/02-review` is NOT empty.** It holds `Madonna` and `Michael Jackson`.

## 99-quarantine does not end empty, and that is the operator's choice

The sweep's timestamped batch directory `20260918T165406Z` was emptied by the removal stage and
then `rmdir`'d. What remains is the two Garth Brooks directories, kept deliberately under
amendment 2 because the failed job left 1.92 GB of real FLAC behind.

`find 99-quarantine -mindepth 1 | wc -l` therefore returns **51, not 0**. Task 3's acceptance
criterion offers two branches and this discharges the second — every entry named:
2 directories, **44 `.flac`** (10 + 34, matching the approved audio counts exactly), 1 `.m3u`,
2 `.nfo`, and 2 random-named `.zip` artefacts of the failed jobs, left in place because they
arrived inside directories the operator chose to keep and striking them was not approved.

No `chmod` and no `chown` was attempted anywhere. A rename preserves ownership, so the moved
content carries `apps:apps 777` — D-26 working as designed; plan 05-10 normalises tree-wide.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 — Blocking] The script could not express the operator's amendment 2**
- **Found during:** Task 1
- **Issue:** `sweep` decided move-only from `rule == "R8"`. The operator approved two **R1**
  rows to be moved rather than removed, and there was no way to say so without relabelling
  them R8 — which would have misreported them and weakened their re-validation from
  rule+audio+size to audio alone.
- **Fix:** move-only keyed on the presence of the seventh (destination) field. The
  destination-less-R8 fail-closed branch was preserved explicitly rather than left implicit.
- **Files modified:** `scripts/phase05-junk-sweep.sh`
- **Verification:** `bash -n` clean; comment-stripped banned-primitive greps unchanged
  (`-delete` 0, `xargs` 0, `rm -rf` 1, `/tmp` 0); all three fixture runs green.
- **Commit:** `477704d`

**2. [Rule 1 — Bug] Two assertions in my own verification harness failed on a CORRECT estate**
- **Found during:** Task 2, on the real run, and Task 1 on the fixture
- **Issue:** Three instruments, two defects, and both are shapes this estate has recorded before.
  (a) `$(grep -c 'pattern' file || echo 0)` — `grep -c` prints the count **and exits 1** when
  the count is zero, so the healthy outcome emitted `"0\n0"` and the assertion **failed exactly
  when the estate was correct**. (b) A fixture assertion counted the presence of a literal
  `removed: 0` line and compared that count to 0, so it too failed on the correct outcome — a
  mechanical check satisfied by prose *about* the thing rather than by the thing. (c) A third
  counted entries at depth 2 of `99-quarantine` to prove the batch was empty, and caught the
  move-only row's own audio file instead; it was asserting the wrong directory.
- **Fix:** all three now read the **value** the run reported, via `awk`, and the batch check
  parses the batch path out of the run's own output. The reasons are recorded in band in
  `05-04-verify.sh` and `05-04-fixture.sh` so nobody reintroduces them.
- **Verification:** re-run — 19/19 list assertions and 28/28 estate assertions held.
- **Commits:** `7b169c9`, `e0f4fc9`

**3. [Rule 2 — Missing critical] A shell-quoting artifact made an inline assertion lie**
- **Found during:** Task 1
- **Issue:** The first attempt at asserting the amended list's shape ran the `awk` programs
  inline through `ssh` inside a single-quoted string. The tab field separator did not survive
  three levels of quoting: `NF==6` and `NF==7` **both** returned 0 and `malformed` returned 44
  on a file that was demonstrably correct. Had the expected values happened to be zero, this
  would have read as a clean pass.
- **Fix:** every assertion moved into a host-resident script, `05-04-verify.sh`, with the
  reason recorded in its header.
- **Verification:** re-run from the file — all 19 held, and the numbers now agree with the
  independent `diff` of the as-read and amended lists.
- **Commit:** `7b169c9`

### Deliberately not fixed

- **The plan's acceptance criterion for the five KEEP sidecars is unsatisfiable as written.**
  It requires each inode to match *"the value recorded in 05-03-SUMMARY.md"* — **05-03 recorded
  no inode values**, only that zero candidate rows named those files. The baseline used instead
  is this plan's own pre-sweep read, taken before the first destructive call and recorded in
  `05-04-approval-record.txt`. The assertion is therefore still capable of failing; it is just
  keyed to a baseline this plan established rather than one that did not exist.
- **`scripts/quick-health-check.sh` still exits 1** for the pre-existing, unrelated
  `interpolated-host-path inventory MOVED: expected=12, found=13` red, logged in
  `deferred-items.md` by plan 05-02. Not attributable to this plan and not touched.
- **The two random-named `.zip` files** inside the kept Garth Brooks directories. Named, left
  in place — striking them was not approved.

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 bug, 1 missing critical).
**Impact:** The blocking fix was required to implement the operator's amendment honestly rather
than by an encoding that would have degraded the safety of the only two rows carrying
irreplaceable audio. The other two were defects in **my own instruments**, both of which
reported failure on a correct estate — fixed rather than accommodated, because an instrument
that fails when things are right is one that will be ignored when things are wrong.

## Issues Encountered

None that blocked. The two harness defects are recorded as deviations above precisely because
they are the interesting part: on two separate occasions a green estate produced a red
assertion, and in both cases the correct move was to repair the instrument, never the
expectation.

## Evidence

| Check | Result |
|---|---|
| as-read list sha256 == committed 05-03 artifact | identical, `126ce3a0…` |
| amended list sha256, re-checked at the moment of the sweep | `fe2d3e2e…`, matched |
| snapshot proof present and naming `tank/downloads@pre-phase5` | yes, `c536d056…` |
| fixture assertions (3 runs) | **34 / 34** |
| list-shape assertions | **19 / 19** |
| estate assertions | **28 / 28** |
| `zfs diff` destructive lines unexplained by the approved list | **0** |
| approved remove rows missing from the `zfs diff` removed set | **0** |
| destructive lines under `incomplete/` or `/mnt/tank/media` | **0** |
| excluded `.covers` directories intact | **8 / 8** |
| KEEP sidecars with unchanged `(devid,inode)` | **5 / 5** |
| `test -e /mnt/tank/downloads/lidarr-import` | **false** |
| `incomplete/` before / after | 259 entries / 108,927,263 B, **byte-identical** |
| credential screen over every committed artifact | 0 matches |

The `incomplete/` equality is **more** than was expected and is not claimed as proof: it is a
live directory drained at roughly one job per 72 s and simply happened to be idle across the
window. The fence proof is the `zfs diff`.

## Known Stubs

None. Every deliverable of this plan is a completed act on the estate, verified by an
instrument that has been shown capable of failing.

## Still open, deliberately

- **INBX-01/02/03 stay UNTICKED here.** All requirement ticks belong to plan 05-11. INBX-02 is
  *satisfiable* now; ticking it is not this plan's job.
- **`_inbox/02-review` is pre-seeded** with 533 audio files across two artist folders. Phase 6
  and Phase 7 must expect it.
- **99-quarantine holds 1.92 GB** the operator chose to keep. Whether the Garth Brooks FLAC is
  usable — the jobs failed, so it may be incomplete — is not decided here and is not scheduled.
- **Criterion 2's Potter clause is satisfied by a different fact than anyone expected.** 05-03
  found the `.mkv` had already left the tree on its own; only the empty directory remained, and
  that is what this sweep removed. 05-11 should tick the criterion knowing this, not on the
  strength of a sweep that removed a video file.

## Threat Flags

None. This plan added no network endpoint, no auth path and no schema change. The one script
change **reduced** risk: the fail-closed branch for a destination-less PROPOSAL row is now
explicit instead of implicit, and the strictest re-validation path now applies to the two rows
carrying irreplaceable audio, where before it would not have.

## Self-Check: PASSED

All nine created artifacts exist on disk. All four commits (`477704d`, `7b169c9`, `e0f4fc9`,
`9e79d43`) are present in `git log`. The off-repo deliverable
`host:/mnt/fast/safety/phase05/junk-sweep-result.txt` exists and reports 44 moved / 40 removed
/ 0 failures.

---
*Phase: 05-inbox-structure-and-the-junk-gate*
*Completed: 2026-09-18*
