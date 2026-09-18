---
phase: 05-inbox-structure-and-the-junk-gate
plan: 03
subsystem: junk-gate
tags: [approval-gate, two-process, scope-fence, enumerate, read-only, tsv, D-13]
requires:
  - "05-01 — tank/downloads@pre-phase5 and its proof file at /mnt/fast/safety/phase05/snapshot-proof.txt"
  - "05-01 — _inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}, the sweep's destinations"
  - "05-02 — ROADMAP criterion 2 amended to the five music paths, incomplete/ ruled out under D-15"
provides:
  - "scripts/phase05-junk-sweep.sh — enumerate (read-only) and sweep (acting), joined by a file on disk"
  - "host:/mnt/fast/safety/phase05/junk-candidates.tsv — 52 rows, the file that IS the gate; awaiting operator approval"
  - "artifacts/05-03-junk-candidates.tsv — the committed copy of that list"
  - "artifacts/05-03-enumerate.log — the run transcript"
  - "artifacts/05-03-gate-fixture-proof.txt — all four control paths driven on a synthetic fixture"
  - "D-06's cd2.bmp verdict, resolved by opening it: NOW 77 disc 2"
affects: [05-04, 05-05, 05-06, 05-07, 05-11]
tech-stack:
  added: []
  patterns:
    - "two processes joined by a file on disk — a branch can be skipped, a missing file cannot"
    - "refusal-not-fallback as the first statement of the acting subcommand, so it is reachable with no access to the estate"
    - "scope fence re-asserted PER ITEM, not once on the roots"
    - "rule precedence as an ordered chain so one path yields exactly one row"
    - "containment suppression — a descendant of an emitted directory is not emitted separately"
    - "assert the shape of the file you just wrote, rather than trust the code that wrote it"
key-files:
  created:
    - scripts/phase05-junk-sweep.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-03-junk-candidates.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-03-enumerate.log
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-03-gate-fixture-proof.txt
  modified: []
decisions:
  - "R4 is ordered ahead of R7 for directories, which makes R7's directory clause unreachable — recorded in band rather than left as a rule that can never fire"
  - "The eight .covers rows are VALUE-FLAGGED, not hard-KEPT: deciding to keep is the operator's call and this half of the gate only proposes"
  - "The gate was driven end to end on a synthetic fixture with DOWNLOADS relocated, before it was ever pointed at the estate"
metrics:
  duration: ~75 min
  completed: 2026-09-18
  tasks: 2
  commits: 3
---

# Phase 5 Plan 03: The Junk Gate Exists and the Operator Has One File to Read — Summary

The rules that define junk for this estate are written down and greppable, the operator has exactly
one file to read, and **nothing has been moved and nothing has been removed** — asserted on the
reversibility fence, not assumed.

## What was done

**Task 1 — `scripts/phase05-junk-sweep.sh` (943 lines).** Two subcommands joined by
`$APPROVED_LIST`. `enumerate` is read-only and returns 0 always; `sweep` opens with two refusals
before it requires anything else, so both are reachable on a workstation with no access to tank.
Eight rules R1–R8, a five-root scope fence re-asserted per item, `incomplete/` and `/mnt/tank/media`
refused by name with their own messages, and exactly one removal call taking a single quoted
absolute path from the approved file.

**Task 2 — the live enumeration.** Committed and pushed first (delivery is git; nothing else copies
files into `/mnt/fast/stacks`), pulled on LXC 100, and ran from the repo checkout. 69 s, 52 rows,
23.1 GB proposed.

## The gate was proven before it was pointed at the estate

Four control paths driven on a synthetic fixture with `DOWNLOADS` relocated to
`/mnt/fast/safety/phase05/fixture` — the whole fence moves with it, so the machinery is exercised
without the estate being reachable. Transcript: `artifacts/05-03-gate-fixture-proof.txt`.

| Control | Expected | Observed |
|---|---|---|
| `sweep` with the approved list absent | exit 2, refusal naming the path | exit 2 ✓ |
| `sweep` with the snapshot proof absent | exit 2, refusal naming `tank/downloads@pre-phase5` | exit 2 ✓ |
| `sweep` with a proof naming `@pre-project` (the month-stale one) | exit 2 | exit 2 ✓ |
| A row changed after approval (10 bytes added) | exit 1, **whole** sweep aborts, nothing moved | exit 1, `size moved 2 -> 10`, fixture intact ✓ |
| Positive control — full sweep | all rows acted on | 19 moved, 17 removed, 2 R8 moved-not-removed, batch dir empty, all five KEEP sidecars intact ✓ |
| `enumerate` with a list already present (T-05-03-05) | exit 2 | exit 2, driven again on the **live** estate before the re-run ✓ |

The positive control matters as much as the refusals: a gate that has only ever been seen refusing
is an instrument nobody has shown can do its job.

## Pre-declared expectations beside what was found, item by item

The plan pre-declared the rows so a verifier meets a known list. Four items differ, and **every
difference is the live tree having moved, or the pre-measurement having counted a name rather than
a thing** — none is a rule failing to fire.

| Pre-declared | Found | Verdict |
|---|---|---|
| 4 music `_FAILED_`/`_UNPACK_` directories | **4** — R1 ×2 (both Garth Brooks), R2 ×2 (Ed Sheeran, Katy Perry) | **exact match** |
| 6 stray `.rar`, 3 inside the `_UNPACK_` dirs, 1 a genuine stray in `music/` | **R3 = 0 rows.** 4 rar-shaped regular files exist, all 4 inside the two `_UNPACK_` directories and all 4 **suppressed as descendants** of their emitted parent. The "genuine stray" is **not a file** — see below | **differs, and the difference is a near-miss caught** |
| the empty 512-byte `dj-mixes` decoy | **1 row, R4, `audio_count=0`** | **exact match** |
| `unsorted/Harry.Potter…MOOVEE` | **1 row — but R4, not R5, and 0 bytes.** The directory is now **empty at every depth**; the `.mkv` has left the tree since 05-PREMEASURE measured it | **differs — the rip is already gone** |
| 9 named D-06 sidecars | **9 rows, R6**, all nine matched by name | **exact match** |
| 2 R8 PROPOSAL rows for `lidarr-import` | **2 rows** — Madonna 3.6 GB / 60 audio, Michael Jackson 16.9 GB / 473 audio | **exact match** |

**Expected absent, asserted rather than assumed — every one returned 0:** rows under
`/mnt/tank/downloads/incomplete`; rows under `/mnt/tank/media`; rows outside the five scope roots;
rows naming the m3u map, `back.bmp`, `cd1.bmp`, `cd2.bmp` or the volume-115 cue; the real 45 G `Now!`
folder as a candidate row; and each of the four TV/movie `_FAILED_` names (`Chicago.PD.S13E02`,
`Goldie.and.Bear.S02E26E27`, `Prep.and.Landing.2009`, `Disclosure.Day.2026`).

## Two defects the live run found, and they are the same defect twice

Both are the class the threat register calls **T-05-03-04 — a value-bearing item proposed for
removal by type alone.** The plan mitigated it with a hard KEEP list and R6's nine named files,
which covers the `Now!` collection root and nothing else. The estate had two more instances.

**1. `.rar` is a name, not a type.**
`complete/nzb/music/[002+114] Def_Leppard-Slang-2LP-24BIT-FLAC-1995-REETKEVER.part001.rar` is a
**directory**, and it holds one real 24-bit FLAC. `05-PREMEASURE.md` § 5 counted it among "6 stray
`.rar` files"; it is neither a file nor a stray. The script never proposed it, because R3 runs only
on the `-type f` walk and as a directory with `audio_count=1` no other rule fires either — but that
was luck made into a property rather than a property by design, so it is now **stated in the file
with both of its live counter-examples**. The second is worse: sixteen
`complete/nzb/tv/Star.Trek.Voyager.S01E**…WEBDL-1080p.R75` **directories** whose release-group
suffix satisfies the multipart `.r[0-9][0-9]` form exactly. Out of scope, and unreachable through
`-type f` — but anyone who "simplifies" that walk proposes deleting a season of television.

**2. Eight `.covers` directories were proposed indistinguishably from empty shells.**
Four release folders, each duplicated between `dj-mixes/` and `unsorted/`, every one holding a real
cover JPEG. PROJECT.md records cover scans as *more reliable than any autotagger*, and D-06's
transferable lesson is that file type predicted nothing — three `.bmp` that looked like generic
artwork carried a full tracklist, a barcode and a catalogue number. They are **NOT hard-KEPT**:
deciding to keep is the operator's call and this half of the gate only proposes. What changed is
that such a row can no longer arrive looking like an empty shell — it carries a `⚠ VALUE FLAG` in
its reason, `enumerate` lists all eight with their contents in a section of their own, and the
count appears in the summary.

## cd2.bmp — D-06's one open verdict, closed by opening it

D-06 recorded `cd2.bmp` as *"presumed NOW 77 disc 2 — NOT individually opened; verify at
execution"*. Rendered to JPEG with `ffmpeg` and read. **It is NOW 77, COMPACT DISC 2.**

| Field | `cd1.bmp` | `cd2.bmp` |
|---|---|---|
| Disc | `COMPACT DISC 1` | `COMPACT DISC 2` |
| Release catalogue | `50999 9 09 790 2 6` | `50999 9 09 790 2 6` (same) |
| Per-disc number | `(50999 9 09 791 2 5)` | `(50999 9 09 793 2 3)` |
| Label / rights | EMI TV, Universal, LC 0542, MADE IN EU, © 2010 | identical |
| md5 | `c6b34acf…` | `320ff6ea…` — **different files, not duplicates** |
| Dimensions | 1200×1200, 24bpp | 1200×1200, 24bpp |

The presumption holds and needs no adjustment in plan 05-07. Two details are recorded **as read**
rather than tidied: the two files are byte-*sized* identically (4,320,054 B each) but are different
images with different md5s, and disc 2's per-disc number is **793**, not the 792 a reader would
predict from disc 1's 791. Renders kept off-repo at `/mnt/fast/safety/phase05/scans/` — they are
copyrighted artwork and this repository is public.

## What the operator is being asked to approve

`/mnt/fast/safety/phase05/junk-candidates.tsv`, 52 rows, 23.1 GB.

| Rule | Rows | Bytes | What it is |
|---|---:|---:|---|
| R1 `_FAILED_` | 2 | 2,062,021,915 | both Garth Brooks; **note `audio_count` 10 and 34 — these hold real audio** |
| R2 `_UNPACK_` | 2 | 572,313,557 | Ed Sheeran, Katy Perry; `audio_count` 0, contents are the 4 `.rar` |
| R3 stray archive | 0 | 0 | all 4 suppressed under their R2 parent |
| R4 zero audio | 37 | 257,878 | 29 empty shells + **8 VALUE-FLAGGED `.covers`** |
| R5 video in a music path | 0 | 0 | the rip left the tree; its empty directory is R4 |
| R6 named D-06 sidecar | 9 | 152,962 | 7 EAC logs + 2 volume-less playlists |
| R7 zero-byte / empty | 0 | 0 | subsumed by R4 for directories; no zero-byte files exist |
| R8 PROPOSAL | 2 | 20,480,246,125 | **89% of the total bytes, and not junk** — D-20 content |

**Three things to read before approving, stated because a bare 23.1 GB is misleading:**
1. **R8 is 20.5 GB of the 23.1 GB and is content, not junk.** It is moved, never removed.
2. **The two R1 rows hold real audio** (10 and 34 files). A `_FAILED_` directory is not necessarily
   empty, which is exactly why R1 and R2 now report a real `audio_count` rather than blank.
3. **The eight `.covers` rows.** Strike the lines to keep them.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] Tab is an IFS *whitespace* character, so empty fields vanish on read-back**
- **Found during:** Task 1, on the synthetic fixture
- **Issue:** `IFS=$'\t' read -r a b c` does **not** treat tab as a plain delimiter — bash collapses
  runs of it and strips it from the ends. An R1 row emitted with an empty `audio_count` came back
  with the *reason sentence* sitting in the audio-count variable and the reason empty. It parses
  cleanly and exits 0. `sweep` compares the audio count it re-derives against the approved one, so
  the shift would have aborted the entire sweep over a comparison of a number against a sentence.
- **Fix:** R1/R2 now compute and report a real audio count (which is better information anyway —
  see reading note 2 above); `enumerate` **asserts the shape of the file it just wrote**, 6 or 7
  fields, none empty; a path whose own name contains a tab is excluded and counted rather than
  emitted. The mechanism is recorded in the header so nobody re-introduces an empty column.
- **Commit:** `7f82795`

**2. [Rule 1 — Bug] R7 fired on the `dj-mixes` decoy where the plan requires R4**
- **Found during:** Task 1, on the fixture
- **Issue:** a directory empty at every depth necessarily contains zero audio files, so R4 and R7
  are not disjoint. R7 was checked first, so the decoy came out tagged R7 — and the plan's
  acceptance criterion names R4 for that exact item.
- **Fix:** R4 ordered ahead of R7 for directories. This makes **R7's directory clause unreachable**,
  which is recorded in band rather than left as a rule that can never fire; the information is not
  lost, because the R4 reason says *"and is empty at every depth (R7 directory clause, subsumed)"*
  on the 29 rows where it applies.
- **Commit:** `7f82795`

**3. [Rule 2 — Missing critical functionality] Value-bearing directories proposed by type alone**
- **Found during:** Task 2, on the live tree
- **Issue:** the T-05-03-04 mitigation as specified covers the `Now!` collection root only. Eight
  `.covers` directories holding real cover art arrived looking identical to 29 empty shells.
- **Fix:** a `VALUE FLAG` annotation on the row, a dedicated `enumerate` section listing each one
  with its contents, and a count in the summary. Deliberately **not** a hard KEEP.
- **Commit:** `5e180a6`

**4. [Rule 2 — Missing critical functionality] R3's type discipline was implicit**
- **Found during:** Task 2, while reconciling `R3 = 0` against the pre-declared 6
- **Issue:** the safety of R3 rested on the caller passing `-type f`, with nothing in the file
  saying why that must never change — against two live counter-examples on this estate.
- **Fix:** both counter-examples recorded at the rule, by path.
- **Commit:** `5e180a6`

### Deliberately not fixed

- **`scripts/quick-health-check.sh` still exits 1** for the pre-existing, unrelated
  `interpolated-host-path inventory MOVED: expected=12, found=13` red, logged in `deferred-items.md`
  by plan 05-02. Not attributable to this plan and not touched.
- **My own ad-hoc probe was malformed** — `find … -maxdepth 4 -iname '*.rar' -o -maxdepth 4 -iname
  '*.r[0-9][0-9]'` has no `-type f` and `-o` binds loosely, so it returned sixteen Star Trek
  directories. Recorded rather than quietly re-run, because it is how counter-example 2 was found
  and because the same shape in the *script* would have been a content-destroying defect.

### Scope

This plan **moved nothing and removed nothing.** Plan 05-04 is the destructive half and is
operator-gated on the file this plan produced.

## Evidence

| Check | Result |
|---|---|
| `bash -n scripts/phase05-junk-sweep.sh` | exit 0 |
| `--help` | exit 0, prints the header block |
| no arguments | exit **2** |
| `sweep` with no approved list, on the workstation | exit **2**, refusal names the expected path |
| `grep -v '^[[:space:]]*#' … \| grep -c -- '-delete'` | **0** |
| `… \| grep -c 'xargs'` | **0** |
| `… \| grep -c 'rm -rf'` | **1** |
| `… \| grep -c '/tmp'` | **0** |
| header literals `EXIT-CODE CONVENTION` / `THE KEY (D-13)` / `Where it runs` | 1 / 1 / 1 |
| `grep -c 'incomplete'` | 3, every match in the fence or its comment, never a scope root |
| `grep -c 'tank/downloads@pre-phase5'` | 1 |
| host SHA after `git pull --ff-only`, and payload re-grepped host-side | `5e180a6`, `VALUE FLAG` → 2 |
| `junk-candidates.tsv` rows / malformed rows | 52 / **0** |
| col 2 under `incomplete/` or `/mnt/tank/media` | **0** |
| col 2 outside the five scope roots | **0** |
| four TV/movie names | **0** each |
| five hard-KEEP sidecars | **0** each |
| real `Now!` folder as a candidate row | **0** |
| `dj-mixes` decoy | 1 row, `R4`, `audio=0` |
| Potter path | exactly 1 |
| R8 rows with a destination column | 2, both `_inbox/02-review` |
| `zfs diff tank/downloads@pre-phase5 tank/downloads` **before** | `M 2`, `+ 8216`, **`-` 0, `R` 0** |
| `zfs diff …` **after** | `M 2`, `+ 8215`, **`-` 0, `R` 0**; no `-`/`R` line touches any scope root |
| credential screen over both committed artifacts | 0 matches |

The `+` count moving 8216 → 8215 is SABnzbd's own churn in `incomplete/`: a file created after the
snapshot and then removed disappears from `zfs diff` entirely, leaving no `-` line. It is not
attributable to this plan, and the in-scope check is the one that carries the claim.

## Known Stubs

None. Both deliverables are complete and exercised: the script has had all four of its control
paths driven, and the candidate list is written, asserted and committed.

## Still open, deliberately

- **`junk-candidates.tsv` is NOT approved.** Plan 05-04 must not run `sweep` until the operator has
  read it — in particular the eight `.covers` rows and the two R8 rows.
- **The list is a point-in-time view.** `sweep` re-derives every row and aborts the whole run on any
  conflict, which was driven; but if approval is slow enough that SABnzbd has landed new jobs, the
  likely outcome is an abort and a re-enumeration, and that is the design working.
- **Criterion 2's Potter clause is now satisfied by a different fact than anyone expected** — the
  rip left the tree on its own and only its empty directory remains. Worth stating in 05-11 so the
  criterion is not ticked on the strength of a sweep that did not remove it.

## Threat Flags

None. This plan added no network endpoint, no auth path and no schema change. It reduced surface:
the scope fence is now re-asserted per item in both subcommands, and two paths are refused by name.
