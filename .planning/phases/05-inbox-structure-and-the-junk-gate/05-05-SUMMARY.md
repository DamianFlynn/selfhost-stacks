---
phase: 05-inbox-structure-and-the-junk-gate
plan: 05
subsystem: now-collection-inventory
tags: [ffprobe, ndjson, reconciliation, read-only, D-02, D-03, D-04, D-08, D-09, D-10]
requires:
  - "05-01 — tank/downloads@pre-phase5 and the _inbox tree (not used mutatively here; this plan writes nothing to tank)"
  - "05-04 — the sweep, which removed 9 of the 14 sidecars and made every pre-sweep file count stale"
provides:
  - "host:/mnt/fast/safety/phase05/now-tags.ndjson — 4,746 records, the durable replacement for the lost /tmp scan"
  - "host:/mnt/fast/safety/phase05/now-manifest.ndjson — 4,770 parsed m3u entries with their volume directory"
  - "host:/mnt/fast/safety/phase05/now-volume-dirnames.txt — 119 distinct volume directories, UNPARSED"
  - "host:/mnt/fast/safety/phase05/now-collided-files.tsv — the 23 files claimed by more than one volume directory"
  - ".planning/phases/05-inbox-structure-and-the-junk-gate/05-NOW-INVENTORY.md — the record 05-06 and 05-07 read"
  - "scripts/phase05-now-tag-inventory.sh — scan + reconcile, read-only against the collection"
affects: [05-06, 05-07, 05-08, 05-09, 05-11, 06]
tech-stack:
  added: []
  patterns:
    - "group a flattened collection by the ripper's own manifest directory, found from the END of the path, because the manifest carries three different path depths"
    - "a per-(group,disc) expectation is the MODAL value, never the first seen — first-wins lets one collided intruder set the expectation for a whole disc"
    - "reproduce the figure you are overturning before overturning it: the +13/+9/+14 surplus was re-derived exactly under the old grouping, then shown to vanish under the new one"
    - "decode a Windows-written manifest explicitly (CP1252) rather than reading it as UTF-8; report the residual join stage's size instead of hiding it"
key-files:
  created:
    - scripts/phase05-now-tag-inventory.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/05-NOW-INVENTORY.md
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-d04-analysis.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-reconciliation.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-d04-answer.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-volume-dirnames.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-album-values.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-collided-files.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-tracktotal-conflicts.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-05-scan.log
  modified: []
key-decisions:
  - "Group by the manifest volume directory found from the END of the path, not by a fixed field index — 64 of 4,770 lines have a different depth and a fixed index names the collection root as a volume"
  - "The per-(volume,disc) tracktotal is the MODAL value; first-wins produced three false exceptions and was fixed rather than accommodated"
  - "The 2 leaves the ripper wrote as literal `?` are joined on an alphanumerics-only key required to be unique on BOTH sides — never guessed, and 0 remained unresolved"
requirements-completed: []
duration: ~40 min
completed: 2026-09-18
---

# Phase 5 Plan 05: The Inventory Is Durable, and D-04's Surplus Does Not Exist Summary

**4,746 mp3 re-measured and re-probed after the sweep with zero failures, and the open question
D-04 left is closed with evidence: volumes 4, 8 and 9 have no surplus at all — the +13/+9/+14 was
an artefact of grouping on an album tag that cannot tell three separate 1984-1987 editions apart,
and it reproduces exactly under the old grouping before vanishing under the new one.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-09-18T17:05Z
- **Completed:** 2026-09-18T17:40Z
- **Tasks:** 3
- **Commits:** 5 (plus this one)
- **Scan wall clock:** 348 s for 4,746 files, 45 GB, one ffprobe per file

## Re-measured, not inherited

The tree is live and the 05-04 sweep had just changed it. Every figure was taken fresh between
17:08Z and 17:27Z.

| Measure | Measured | 2026-09-18 value | Verdict |
|---|---:|---:|---|
| mp3 files | **4,746** | 4,746 | unchanged — **still the denominator** |
| non-mp3 sidecars | **5** | 14 | as predicted: the sweep removed 9 |
| subdirectories | **0** | 0 | still flat |
| m3u entries | **4,770** | 4,770 | unchanged |
| NDJSON records | **4,746** | — | equals the fresh mp3 count |
| failed ledger | **empty** | — | 0 failures |
| null `album` / `disc` / `track` / `tracktotal` | **0 / 0 / 0 / 0** | 0 / 0 / 0 | no regression |

`jq -e .` over the whole 6.4 MB NDJSON exits **0** — and the instrument was shown to discriminate:
the same pass over a copy with one malformed line appended exits **5**. The copy was deleted.

## The answer D-04 asked for

**The surplus is a grouping artefact.** The album tag on these files is
`Now That's What I Call Music 4` / `8` / `9` — **without the exclamation mark**, one string per
family — while the manifest names **three** directories for volume 4 and two each for 8 and 9. The
old figure was reproduced exactly before it was overturned:

| Family | album-tag files | Σ tracktotal | D-04's surplus | reproduced |
|---|---:|---:|---:|---|
| 4 | 45 | 32 (16+16) | +13 | **+13** |
| 8 | 42 | 33 (17+16) | +9 | **+9** |
| 9 | 44 | 30 (15+15) | +14 | **+14** |

The two instruments **agree exactly on the file sets** — 45 / 42 / 44 distinct physical files under
both the album tag and the manifest directories — so D-04's case 4 does not apply and **no file
from another volume is mis-tagged into these**. Under the manifest grouping there is **no surplus
anywhere in the collection**: `1984. …! 4 [2019 Reissue]` balances 32/32 with zero collisions and
every `(disc,track)` pair distinct. Volume 8 is the single case-2 hit — 4 repeated pairs on disc 1,
every one a leaf-collided file from its own `[Original 1CD Rare]` edition, named in full. **The
split is safe.** Fixing any `tracktotal` stays out of scope per D-10.

## The exception set is not the pre-declared one, and that is the finding

| Pre-declared (D-04, album tag) | Measured (manifest directory) |
|---|---|
| short by 1: 15, 18, 39, 52, 70, 83, 98 | **18, 52, 70, 83, 98 confirmed; 15 and 39 BALANCE** |
| short by 2: 3 | **volume 3 BALANCES** |
| surplus: 4 (+13), 8 (+9), 9 (+14) | **no surplus anywhere** |
| split-tag mess on 36 | **volume 36 BALANCES** 40/40 — one directory, three album spellings |

7 exceptions, **all shortfalls**, 11 files in total; 112 of 119 directories balance exactly. Every
difference from the pre-declared list is named in `05-NOW-INVENTORY.md` § 3 with its volume.

⚠ Recorded rather than banked: `1986. …! 8 [2021 Reissue]` balances 32/32 as a **cancellation** —
disc 1 is 20 files against a stated 16, disc 2 is 12 against 16.

## The 24-entry gap, on its own line: it is COLLISION, not absence

**manifest-only entries (m3u lines with no file on disk): 0.** Never folded into any total.

4,770 manifest lines carry **4,746 distinct leaves**, exactly the disk count. 24 lines beyond the
first share a leaf across 23 distinct leaves — one carried by **three** lines. So **23 physical
files are claimed by more than one volume directory.** This confirms D-04's guess that the cause
was filename collision during the flatten, and it hands plan 05-06 its hardest problem *before* the
split runs: a file cannot be moved into two folders. All 23 are named with every claiming directory
in `artifacts/05-05-collided-files.tsv`.

## Two measurements that overturn a documented figure

1. **119 distinct manifest volume directories, not 116.** The earlier count named the collection
   root as a directory and missed four variant-edition directories. The m3u carries **three** path
   depths — `..\ROOT\VOL\CDn\leaf` (4,706), `..\ROOT\VOL\leaf` (57, the single-CD rare pressings)
   and `Z:\Nieuwetorrent2023\ROOT\VOL\CDn\leaf` (7) — so a fixed field index is wrong on 64 lines
   and silently names the collection root as a volume. The rule used instead reads from the END.
2. **117 album strings splits 96 `Music!` / 21 `Music`**, not 96 / 19. D-03's trap is otherwise
   intact and was re-counted: `Vol.36 CD1` 16, `Vol.36  CD2` 20 (double space), `! 36` 4.

## Read-only, proven rather than asserted

- `find NOW_ROOT -newermt "2026-09-18 17:00Z"` returns **0** entries.
- The collection directory is still `(devid 68, inode 15900)` — inode identical to the value
  `05-PREMEASURE.md` § 3 recorded before the phase began.
- mp3 count before and after the scan: 4,746 / 4,746.
- `NOW_ROOT` outside `complete/nzb/unsorted` is **refused with exit 2** naming both paths, driven on
  LXC 100 against `/mnt/tank/downloads/incomplete` and on the workstation against
  `/mnt/tank/media/Music`.
- Comment-stripped greps over the script: `xargs` **0**, `/tmp` **0**, write-mode redirect targeting
  a `NOW_ROOT` path **0**, `jq` **6**.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] First-wins tracktotal produced three false exceptions**
- **Found during:** Task 2, on the first reconcile run
- **Issue:** the per-`(volume,disc)` expectation took the **first** tracktotal seen. A leaf-collided
  file carries the tags of only one of the directories claiming it, so a single intruder could set
  the expectation for a whole disc — and did. Volumes 3, 8 and 9 were reported as exceptions
  (−1 each) purely because of awk iteration order, and volume 8's disc 1 took `17` from the
  `[Original 1CD Rare]` edition instead of its own `16`.
- **Fix:** the **modal** value per `(volume,disc)`, with every group carrying more than one distinct
  tracktotal counted and listed in `now-tracktotal-conflicts.tsv` so the disagreement stays visible
  rather than being averaged away. Exceptions fell 10 → 7 and all three false ones cleared.
- **Files modified:** `scripts/phase05-now-tag-inventory.sh`
- **Commit:** `e6d7e2d`

**2. [Rule 1 — Bug] `awk printf … (ternary) > FILE` parses as a comparison, not a redirection**
- **Found during:** Task 2, writing the conflicts detail
- **Issue:** the unparenthesised form would have written **nothing** while exiting 0 — an empty
  detail file reading as "no conflicts".
- **Fix:** `printf(...) > FILE`, parenthesised, with the reason recorded in band.
- **Commit:** `e6d7e2d`

**3. [Rule 3 — Blocking] A single quote inside `${VAR:-…}` inside double quotes swallowed the file**
- **Found during:** Task 1
- **Issue:** the manifest's own filename contains an apostrophe. Written as
  `MANIFEST_NAME="${MANIFEST_NAME:-00.Now That's …}"` bash opens a quoted section inside the
  expansion's word part and `bash -n` fails with `unexpected EOF` pointing at the last line of the
  file — 470 lines away from the cause.
- **Fix:** the two-line form, with the reason recorded in band so nobody "simplifies" it back.
- **Commit:** `a151796`

**4. [Rule 2 — Missing critical] `now-collided-files.tsv` was not in the plan and 05-06 cannot work without it**
- **Found during:** Task 2
- **Issue:** the reconciliation *counted* 23 files claimed by more than one volume directory but did
  not name them. A count is not actionable for a split that has to place each file exactly once.
- **Fix:** emitted as a durable output with every claiming directory per file.
- **Commit:** `dd5439e`

### Deliberately not fixed

- **`scripts/quick-health-check.sh` still exits 1** for the pre-existing, unrelated
  `interpolated-host-path inventory MOVED: expected=12, found=13` red logged in
  `deferred-items.md` by plan 05-02. Not attributable to this plan and not touched.
- **The 11-file shortfall against the manifest, and the 7 short volumes.** Pre-declared, split
  anyway per D-09, re-acquisition out of scope for this project.
- **Volume 8's per-disc imbalance (+4 / −4).** Recorded in `05-NOW-INVENTORY.md`, not repaired —
  repairing it means deciding which edition a collided file belongs to, which is 05-06's call.

---

**Total deviations:** 4 auto-fixed (2 bugs, 1 blocking, 1 missing critical).
**Impact:** two of the four were defects in my own instrument that produced *false exceptions on a
correct collection* — the same shape 05-04 recorded twice. Both were repaired rather than
accommodated, and the third would have written an empty file that read as a clean result.

## Issues Encountered

One process note: an exploratory query staged a 415 KB intermediate in the system temp directory on
LXC 100 while I was characterising the m3u's encoding. It was removed within the minute and nothing
the script does goes there — but it is recorded rather than quietly dropped, because the prohibition
exists for a reason and the exploratory step is exactly where it gets forgotten.

## Evidence

| Check | Result |
|---|---|
| plan's Task 2 verify (`wc -l` ×2 + empty failed ledger) | **4746 / 119 / exit 0** |
| plan's Task 3 verify (`Vol.36  CD2`, `manifest-only` greps) | **2 / 1**, file present, 150 lines |
| `jq -e .` over the whole NDJSON | **exit 0**; corrupted copy **exit 5** |
| join: exact / alnum-key / unresolved / unjoined | **4744 / 2 / 0 / 0** |
| manifest-only entries | **0** |
| null album / disc / track / tracktotal | **0 / 0 / 0 / 0** |
| per-volume exceptions | **7**, all shortfalls, 112 of 119 balanced |
| fence refusal, two hosts | exit **2** both, naming given + required |
| entries under `NOW_ROOT` modified since 17:00Z | **0** |
| collection `(devid, inode)` | **68, 15900** — matches `05-PREMEASURE.md` § 3 |
| credential screen over the 7 committed artifacts | **0** matches (positive control: 2) |
| key-shape sweep over the same | **0** |

## Known Stubs

None. Every deliverable is a completed measurement on real state, produced by an instrument shown
capable of failing.

## Still open, deliberately

- **INBX-03 stays UNTICKED.** All requirement ticks belong to plan 05-11.
- **The 23 collided files need a placement rule.** Named, not decided — 05-06's job.
- **119 directories ≠ 115 volumes.** Four are variant editions of volumes 4, 8 and 9. Whether they
  become their own folders or merge into the parent volume is 05-06's decision, under operator
  review, and it is the reason this plan refused to derive a volume number from anything.
- **`tracktotal` repair** on the short volumes and on volume 8's disc imbalance — Phase 6.

## Threat Flags

None. This plan added no network endpoint, no auth path and no schema change. It writes nothing to
`tank` and holds no credential.

## Self-Check: PASSED

All ten created files exist on disk. All five commits (`a151796`, `e6d7e2d`, `dd5439e`, `56f42f6`,
`4c30465`) are present in `git log`. The off-repo deliverables
`host:/mnt/fast/safety/phase05/now-tags.ndjson` (4,746 lines),
`now-manifest.ndjson`, `now-volume-dirnames.txt` (119), `now-album-values.tsv` (117),
`now-collided-files.tsv` (23) and `now-tags.failed` (empty) all exist and carry the stated counts.

---
*Phase: 05-inbox-structure-and-the-junk-gate*
*Completed: 2026-09-18*
