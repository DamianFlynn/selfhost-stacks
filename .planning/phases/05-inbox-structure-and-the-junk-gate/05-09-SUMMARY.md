---
phase: 05-inbox-structure-and-the-junk-gate
plan: 09
subsystem: now-collection-album-write
tags: [tag-write, rule-4, D-10, id3v1-preservation, audio-md5-join, field-loss-gate, idempotence, vacuous-criterion, host-reboot]
requires:
  - "05-01 — tank/downloads@pre-phase5, the ONLY undo for an in-place tag write; verified on atlantis before the first byte moved"
  - "05-07 — the 115 `Vol NNN` folders rule 4 derives from, and phase05-now-before.ndjson.gz, the QUAL-01 diff baseline"
  - "05-08 — rule 4, the `now` collection fence, and the 4,746-proposal dry run the operator approved"
provides:
  - "host:the Now! collection carrying ONE album string per volume folder — 115 folders, 115 distinct canonical values"
  - "host:/mnt/fast/safety/phase05/now-album-apply.ndjson — 751 applied changes with old and new, reconstructed from the ZFS snapshot"
  - "host:/mnt/fast/safety/phase05/now-album-reapply.ndjson — 4,746 records, 0 written: the full-scale idempotence proof"
  - "host:/mnt/fast/safety/music-pre-project/tags/phase05-now-after.ndjson.gz — 4,746 records, 0 failed"
  - "host:/mnt/fast/safety/phase05/now-album-diff.txt — the field-loss gate verdict, exit 0"
  - ".planning/…/artifacts/05-09-* — the pilot record, the full-apply record and five driven harnesses"
affects: [05-10, 05-11, 06, 07]
tech-stack:
  added: []
  patterns:
    - "pilot a bulk write on the one case that is NOT already correct — a pilot on an already-canonical target passes vacuously and exercises nothing"
    - "take the scope of a write from the FILESYSTEM (a path/mtime/size fingerprint either side) and reconcile it as a SET against the authorising artefact, never from the writer's own counters"
    - "use a ZFS snapshot as the before-side for a byte-level assertion — it is immutable, predates everything, and was not produced by the tool under test"
    - "when a plan's acceptance criterion passes suspiciously easily, prove it can FAIL before quoting it; replace it rather than edit around it"
    - "an instrument needs BOTH arms: 'the untouched files are identical' is worthless until 'the written files differ' has been shown on the same instrument"
key-files:
  created:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-09-pilot-vol036.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-09-full-apply.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-09-treecmp.py
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-09-movedset.py
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-09-framecheck.py
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-09-albumscan.py
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-09-contentctl.py
  modified: []
key-decisions:
  - "The pilot was moved from the plan's `Vol 077` to `Vol 036` on the operator's amendment, and the reason is recorded: `Vol 077` has ZERO proposed changes, so its gate would have passed vacuously — `Vol 036` is the only volume whose files do not all share one album value"
  - "The plan's `zfs diff` scope criterion is non-discriminating on this collection and was replaced rather than quoted: 05-07 renamed every mp3, and `zfs diff` collapses renamed-and-modified into a single `R`, so it reports 0 `M` lines on any mp3 whether 751 files were written or none"
  - "The lost apply NDJSON was reconstructed from the ZFS snapshot by a third parser rather than re-run and presented as original, then cross-checked 751/751 against the operator-approved dry run"
requirements-completed: []
duration: ~2 h 25 min
completed: 2026-09-19
---

# Phase 5 Plan 09: One Field, 751 Files, and Two Instruments That Had to Be Replaced Summary

**751 in-place tag writes across 22 volumes, `album` the only field that moved on any of them, and
`audio_md5` — the key Phase 7's entire before/after diff joins on — unmoved on every one. The
deliverable is asserted by a parser that is neither the one that wrote the tag nor the one that
captured it: 115 volume folders, 115 distinct canonical album strings, and not one folder carrying
two. The 3,995 already-correct files were never touched, proven by a fingerprint rather than
claimed. Two instruments failed on the way and both were replaced rather than worked around — the
plan's `zfs diff` criterion, which passes identically whether this plan wrote 751 files or zero,
and my own container invocation, which discarded the apply record into an ephemeral layer. Atlantis
rebooted mid-verification; 4,751 files were re-fingerprinted across it and nothing moved.**

## Performance

- **Duration:** ~2 h 25 min (fence verified 21:54Z 2026-09-18; content control complete 00:05Z 2026-09-19)
- **Completed:** 2026-09-19
- **Tasks:** 3 (two auto, one decision gate satisfied by the operator's prior approval)
- **Commits:** 2 (plus this one)
- **Pilot apply:** 2.82 s, 40 files. **Full apply:** 288.17 s, 4,746 files. **Idempotence re-run:** 609.52 s

## The amendment, recorded rather than silently followed

The plan text nominates **`Vol 077`** as the pilot, on the reasoning that `back.bmp` corroborates
it three ways. The operator substituted **`Vol 036`**, and the substitution is load-bearing:

- `Vol 077` has **zero** proposed changes. All 44 of its files already carry
  `Now That's What I Call Music! 77`, so every record is `noop: true`. A pilot there writes
  nothing, exercises no write path, and the gate passes **vacuously** — it would have reported
  MATCHED 44 / FIELDS_CHANGED 0 whether `preserve_id3v1_trailer()` worked or not.
- `Vol 036` is the **only** volume whose files do not all share one current album value: 20 read
  `…! Vol.36  CD2` (double space), 16 read `…! Vol.36 CD1`, 4 are already canonical. It is the only
  place a per-file rather than per-folder write is observable, and it is the exact case D-03's trap
  paragraph and rule 4 exist for.

`back.bmp` corroborates the **track count**, not the album string — and it is the album string this
plan writes.

## The approved scope, and the one line of it that was wrong

Approved: **751 files, 22 volumes, 23 distinct (old → new) pairs**, the 3,995 already-canonical
files untouched. All four totals were reproduced exactly. The approval's *sub-breakdown* was not:
it stated "20 volumes lacking the exclamation mark — 705 files", which with the other three rows
sums to 801, not 751. Re-derived from the artefact rather than followed:

| bucket | volumes | files |
|---|---:|---:|
| lacking the `!` (Vol 003–013, 015–017, 021, 023, 024, 027, 029) | **19** | **655** |
| `Vol 001`, numberless `Now That's What I Call Music` | 1 | 30 |
| `Vol 002`, Roman `Now, That's What I Call Music II` | 1 | 30 |
| `Vol 036`, three spellings collapsing to one | 1 | 36 |
| **total** | **22** | **751** |

## Task 1 — the pilot, and the number the whole plan rests on

| measure | declared | observed |
|---|---|---:|
| files seen / changed / no-op / skipped | 40 / 36 / 4 / 0 | **40 / 36 / 4 / 0** |
| failures, `.failed` bytes | 0 / 0 | **0 / 0** |
| distinct `field` / `rule` / `new` values | album / 4 / 1 | **album / 4 / 1** |
| paths outside `Vol 036` | 0 | **0** |
| `counts_reconciled` / `rules_exclusive` | true / true | **true / true** |

**The scope was taken from the filesystem, not from the tool.** A tool reporting on itself cannot
detect a file it affected but never recorded. A 4,751-row path/mtime/size fingerprint either side:

```
paths whose mtime or size moved   36      of which size also changed   0
MOVED BUT NOT WRITTEN             0       WRITTEN BUT NOT MOVED        0
NO-OP FILES THAT MOVED            0       VANISHED / APPEARED          0 / 0
```

The third line is the one that mattered for the remaining volumes: the tool's idempotence contract
says an already-canonical file is *recorded and not written*. On real files, it held.

**The gate:** MATCHED **40**, MISSING_AFTER 0, NEW_AFTER 0, FIELDS_DROPPED 0, FIELDS_GAINED 0,
FIELDS_CHANGED **36**, exit 0. Zero matched files had an empty tag set on the before side, so the
pass is not vacuous. The changed-field set was asserted **mechanically** from `--json`, not by
reading 36 rows: `jq … .field | sort | uniq -c` → **36 album**, one distinct name.

**Why MATCHED 40 is the load-bearing number.** It is a *direct measurement* that `audio_md5` did
not move, not an inference from one. `diff-music-tags.sh` joins on the md5 of the **encoded audio
bitstream**. Had `preserve_id3v1_trailer()` failed, `save(v1=UPDATE)` would have regenerated all
128 bytes of the ID3v1 block from the ID3v2 frames, ffmpeg's mp3 demuxer emits those trailing bytes
as part of the copied stream, and the 36 files would have surfaced as 36 MISSING_AFTER plus 36
NEW_AFTER instead of inside MATCHED. That is not hypothetical — 05-08 drove exactly that failure
from a mutated copy, and Phase 4 measured it on 37 of 335 real files.

## Task 2 — the gate the operator's approval was conditional on

The operator granted the write in advance, conditional on a field-level diff showing `album` as the
only field that moved and `audio_md5` unchanged on every file. **Both conditions were met**
(MATCHED 40, MISSING_AFTER 0, FIELDS_DROPPED 0, FIELDS_CHANGED 36 all `album`), so the sequence
continued without a second halt. Had either failed, the stop was unconditional: the recovery path
is a rollback to `tank/downloads@pre-phase5`, which also discards the junk sweep, the split and
everything downloaded since 2026-09-18T15:42 — an operator decision, never an automatic action.

## Task 3 — the remaining 21 volumes

715 written, **36 + 715 = 751**, exactly the approved scope. `Vol 036` contributed 40 no-ops rather
than 40 rewrites, which is rule 4 being a fixed point on its own output on real files.

**The 715 that moved were compared as a SET, not a count**, against the operator-approved dry run's
effective changes outside `Vol 036`: 715 vs 715, **0 moved-but-not-approved, 0 approved-but-not-moved**.

### The gate, over the whole collection

| category | declared | observed |
|---|---|---:|
| MATCHED | 4,735 | **4,735** |
| MISSING_AFTER / NEW_AFTER | 0 / 0 | **0 / 0** |
| FIELDS_DROPPED / FIELDS_GAINED | 0 / 0 | **0 / 0** |
| FIELDS_CHANGED | 740, `album` only | **740, `album`** |
| matched files with ZERO tag fields before | 0 | **0** |
| exit code | 0 | **0** |

**Two of those numbers are not the ones the plan text pre-declared, and both are correct.** The
plan says "MATCHED equal to the collection's mp3 count", i.e. 4,746 — unachievable, because the
join is on `audio_md5` and 05-07 measured **11 groups sharing one bitstream** (9 inside `Vol 004`,
a three-edition merge). 4,746 records collapse to 4,735 distinct keys on both sides. FIELDS_CHANGED
is 740 for the same reason and reconciles exactly: all 22 files in those 11 groups fall inside the
written set (they live in Vol 002/003/004), so 22 paths collapse to 11 keys and 751 − 11 = 740.
Measured, not argued — distinct changed keys 740, duplicate groups in BEFORE 11.

Asserted mechanically: `jq '.fields_changed[].field' | sort | uniq -c` → **740 album**. One
distinct field name. **No `tracktotal`**, which discharges D-10's explicit exclusion of the
volumes 4/8/9 repair by measurement rather than by intention. Every changed `source_path` is a
**strict subset** of the 751 written paths (0 outside), and 0 of the 740 after-values fail
`^Now That's What I Call Music! \d{1,3}$`.

FIELDS_GAINED 0 is the other half: mutagen synthesised no `COMM:ID3v1 Comment` frame and translated
no `TYER` into `TDRC`. Both load-time defaults the tool sets explicitly against held over 4,746 files.

### The deliverable, read by a third parser

Neither mutagen (which wrote it) nor ffprobe (which captured it) — `albumscan.py` reads TALB
straight out of the ID3v2 frame table:

```
Vol NNN folders scanned                              115
files with NO TALB frame                             0
folders carrying more than one distinct album value  0
distinct album values across the collection          115
every folder's value == its own canonical string     True
value set == the 115 expected canonical strings      True
```

117 distinct values before, **115 after — one per volume folder.** `Vol 036` held three album
strings and now holds one. That is why the write was in scope at all: beets treats one directory
as one album candidate.

### The frame-set and ID3v1 census — the plan asked for 30 files, the snapshot made 4,746 affordable

Against the twins inside `tank/downloads@pre-phase5`, joined by basename, parsed **without**
mutagen:

```
joined 4,746 / unjoined 0 / unparseable 0
ID3v2 FRAME SET MOVED    0
ID3v1 TRAILER MOVED      0        (md5 of the trailing 128 bytes, byte-identical)
```

Run **twice** — once before the full apply, which covers the pilot's 36 files independently of the
pilot's own gate, and once after. PASS both times. **Driven to failure** on wrong-twin joins over
`Vol 036`: 36 frame-set differences, 34 trailer differences, exit 1. An instrument only ever seen
to pass has not been shown to distinguish anything.

## Deviations from Plan

### The plan's own acceptance criterion is vacuous, and was replaced rather than edited around

**1. [Rule 1 — Non-discriminating assertion] `zfs diff` cannot see this plan's writes at all**

- **Found during:** Task 3 verification
- **Issue:** the criterion is "`zfs diff tank/downloads@pre-phase5 tank/downloads` shows
  modifications confined to paths under the collection folder". It was run: 28,845 lines,
  23,996 `+`, 88 `-`, 7 `M`, 4,754 `R`. **`M` lines on any mp3: 0.** The 7 `M` lines are all
  directories. Inside the collection: 115 `+`, 9 `-`, 4,750 `R`, **0 `M`**. That reads like a
  clean pass and is not one — `zfs diff` collapses *renamed AND modified* into a single `R`
  record, and plan 05-07 renamed **every** mp3 in this collection relative to `@pre-phase5`.
  Driven directly: `01. U2 - Discotheque.mp3`, a file this plan demonstrably wrote, carries an
  `R` line and no `M` line. The criterion would report identically whether 751 files were written
  or zero.
- **Fix:** replaced with an instrument that fails in both directions — whole-file md5 against the
  snapshot twin, on two arms. **WRITTEN arm** 25 files over 22 volumes, files matching the
  snapshot **0**; **UNWRITTEN arm** 25 files over 25 volumes, files differing **0**; twins not
  found **0**. The written arm proves the instrument can *see* a write; without it the unwritten
  arm is the same worthless statement `zfs diff` makes. Bounded to 25 per arm deliberately (see
  deviation 3). Corroborated collection-wide by the fingerprint arithmetic, which needs no
  sampling: 36 + 715 + 0 + 0 = **751 moved**, 4,000 never touched.
- **Files modified:** `artifacts/05-09-contentctl.py`
- **Commit:** `892cf2d`

### Auto-fixed issues, both mine, neither reaching content

**2. [Rule 1 — Bug] A missing bind mount discarded the apply NDJSON into the container's ephemeral layer**

- **Found during:** Task 3, immediately after the full apply
- **Issue:** `--out` pointed at `/mnt/fast/safety/phase05/now-album-apply.ndjson`, but only the
  `…/phase05/05-09` subdirectory and the proof *file* were mounted. Docker created the path inside
  the container's writable layer; `--rm` discarded 4,746 records. **The writes were unaffected** —
  the collection was correctly mounted read-write, all 715 files were written, the tool exited 0.
  Only the evidence was lost.
- **Fix:** two parts, neither of which is "run it again and pretend". (a) A corrected re-run with
  the parent mounted: 4,746 records, `written: false` on **all** of them, 0 changed, 0 failures,
  and a fingerprint either side showing **0 mtimes moved across 4,751 files** — which converts the
  accident into the full-scale idempotence proof T-05-09-06 asks for. (b) `now-album-apply.ndjson`
  reconstructed from **measurement**: `old` read from each file's twin inside
  `tank/downloads@pre-phase5`, `new` from the live file, both by a parser that is neither mutagen
  nor ffprobe. Cross-checked against the operator-approved dry run on the full (path, old, new)
  triple: **751 vs 751, 0 in either direction.** Two instruments sharing no input agreeing on every
  row — arguably a better artefact than the one that was lost, because it is not the writer's own
  report.
- **Files modified:** `artifacts/05-09-albumscan.py`
- **Commit:** `892cf2d`

**3. [Rule 1 — Bug] Running two whole-collection reads concurrently rebooted atlantis**

- **Found during:** Task 3 verification
- **Issue:** the 45 GB after-capture (ffmpeg + ffprobe, two processes per file) was left running
  while a full ID3-header pass over the 4,746 snapshot twins was started alongside it. ssh to
  LXC 100 timed out during banner exchange; both hosts returned with `up 0 min` / `up 2 min`. This
  is the documented atlantis memory-pressure signature and two concurrent whole-collection reads is
  a fair reading of the cause.
- **Fix:** every subsequent whole-collection pass run **one at a time**. Recorded here because the
  rule is transferable: on this estate, do not overlap them.
- **What was at risk, and why the answer is nothing:** no write was in flight — both applies had
  completed and been fingerprinted, and the corrected re-run had already shown 0 further mtimes
  moved. Asserted rather than assumed: a fresh fingerprint compared across the reboot shows
  **4,751 rows either side, 0 moved, 0 vanished, 0 appeared**. `zpool status -x`: all pools healthy.
  The interrupted work was read-only and ledger-resumable; the capture resumed from 1,237 and
  finished at 4,746 with 0 failed. The resumed archive was **validated, not trusted** — a hard
  power-off during a gzip-append is exactly when a container file goes bad quietly: `gzip -t`
  exit 0, 4,746 records, 4,746 lines carrying a 32-hex `audio_md5`, 4,735 distinct (the 11 known
  DUPE-01 groups), **0 duplicate `source_path` from the resume**.
- **Commit:** `892cf2d`

### Recorded, not deviations

- **The operator's "20 volumes / 705 files" sub-breakdown is wrong** (it sums to 801). The measured
  figure is 19 volumes / 655 files. Every *total* the operator stated — 751, 22, 23, 3,995 — is
  correct and was reproduced. Corrected in band rather than adopted or dropped.
- **The plan's pre-declared MATCHED and FIELDS_CHANGED figures** (4,746 and "non-zero") are
  superseded by 4,735 and 740 for a reason 05-07 had already measured. Explained above.
- **The 115 volume directories remain `root:root`** and the files `apps:apps`. No `chown`, no
  `chmod` — D-24's tree-wide sweep is plan 05-10 and runs last per D-27.

### Deliberately not fixed

- **`scripts/quick-health-check.sh` still exits 1** for the pre-existing, unrelated
  `interpolated-host-path inventory MOVED: expected=12, found=13` logged in `deferred-items.md`.
  Confirmed unchanged in shape; the blocks this phase cares about are green (`audio.bash` guard
  FAILURES total 0, Jellyfin transcode FAILURES total 0). Bumping the constant is the move this
  estate has repeatedly recorded as the defect rather than the fix.
- **Volumes 4, 8 and 9's tracktotal disagreement.** D-10 declined it; discharged by measurement —
  `tracktotal` does not appear in the changed-field set. Repair is Phase 6's.
- **The 11 duplicate bitstreams.** A DUPE-01 finding, surfaced again here as the arithmetic behind
  MATCHED 4,735 and FIELDS_CHANGED 740. DUPE-01/DUPE-02 still need a roadmap decision before Phase 7.

---

**Total deviations:** 3 auto-fixed — one defect in the plan's own acceptance criteria, two in my
own operation of the estate. **Impact:** none reached the content. The 751 writes are exactly the
751 approved, and the other 4,000 files in the collection were never opened for writing.

## Authentication Gates

None.

## Evidence

| Check | Result |
|---|---|
| `tank/downloads@pre-phase5` on atlantis, before the first write | present, `Fri Sep 18 15:42 2026` |
| snapshot proof names the `now` collection's snapshot | yes — the apply refuses otherwise |
| tool sha256 on LXC 100, before and after `git pull` | `70406a10…` both times, = 05-08's record |
| collection fingerprint before the pilot vs 05-08's | `1b8b90c2e480…` — byte-identical |
| pilot: files seen / changed / no-op / failures | **40 / 36 / 4 / 0**, exit 0 |
| pilot: paths moved vs paths claimed written | **36 = 36**, 0 either way |
| pilot gate: MATCHED / MISSING / DROPPED / GAINED / CHANGED | **40 / 0 / 0 / 0 / 36**, exit 0 |
| pilot: distinct changed field names | **1 — `album`** |
| full apply: folders / files / changed / no-op / failures | **115 / 4,746 / 715 / 4,031 / 0**, exit 0 |
| total written across both passes | **751** = the approved scope |
| moved set vs the approved dry run (as a SET) | **715 = 715**, 0 either way |
| second `--apply`: files changed / mtimes moved | **0 / 0** across 4,751 files |
| full gate: MATCHED / MISSING / NEW / DROPPED / GAINED / CHANGED | **4,735 / 0 / 0 / 0 / 0 / 740**, exit 0 |
| full gate: distinct changed field names | **1 — `album`** |
| changed paths ⊄ the 751 written | **0** |
| duplicate-collapse reconciliation | 751 − 11 = **740**, exact |
| `Vol NNN` folders with ≠ 1 album value | **0** of 115 |
| distinct album values across the collection | **115** (was 117) |
| files with no TALB frame | **0** |
| ID3v2 frame set moved vs the ZFS snapshot, all 4,746 | **0** |
| ID3v1 trailer moved vs the ZFS snapshot, all 4,746 | **0** |
| frame/trailer instrument driven to FAIL | exit 1, 36 frame + 34 trailer differences |
| content control: written arm matching the snapshot | **0 of 25**, over 22 volumes |
| content control: unwritten arm differing from the snapshot | **0 of 25**, over 25 volumes |
| zero-tag-field-on-before-side count | **0** (pilot and full) |
| after-capture: records / failed / `gzip -t` | **4,746 / 0 /** exit 0 |
| collection integrity across the atlantis reboot | 4,751 rows, **0 moved / 0 lost / 0 new** |
| `zfs diff` `M` lines on any mp3 | **0 — and non-discriminating, see deviation 1** |
| `chown` / `chmod` attempted | **none** |
| `/mnt/tank/media/Music` mounted, read or written | **no** — Phase 1's D-20 intact |
| credential screen over the committed artifacts | **0 matches** |

## Known Stubs

None. Every deliverable is a completed operation against real state, with each assertion computed
from the resulting files rather than from the plan that predicted it, and three of the instruments
— the frame/trailer census, the content control and (in 05-07) the reconciliation — each shown
capable of failing.

## Still open, deliberately

- **INBX-03 stays UNTICKED.** All requirement ticks belong to plan 05-11.
- **The 115 volume directories are `root:root`.** Plan **05-10** normalises the whole of
  `tank/downloads` to `568:568` in one verified sweep and picks these up; do not chown them
  piecemeal in the meantime.
- **`tank/downloads@pre-phase5` remains the only undo** for these 751 tag writes as well as for
  05-07's 4,750 renames. Do not delete it before Phase 6 signs off.
- **Every other tag field on this collection** — `artist`, `title`, the BPM-in-title convention,
  the `comment=YearmixFreak 2023` rip artefacts — is Phase 6's. D-10 was one field, and it stayed
  one field.
- **Volumes 4, 8 and 9's tracktotal surplus** is handed to Phase 6 exactly as D-10 decided.
- **DUPE-01 / DUPE-02** still need a roadmap decision before Phase 7.

## Threat Flags

None. This plan added no network endpoint, no auth path and no schema change. It installed no
package from any package manager, so the Package Legitimacy Gate did not fire. It holds no
credential. Every write landed under `tank/downloads`, inside the one collection folder the `now`
fence permits; the default `djmixes` fence was not widened and `SCRATCH_ROOT` was not edited. The
only read-write bind on content was the target path itself, and only for the duration of the write.

## Self-Check: PASSED

All seven created files exist under
`.planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/`. Commits `aec5966` and `892cf2d`
are present in `git log`. The off-repo deliverables on LXC 100 exist with the stated counts:
`now-album-apply.ndjson` (751 records), `now-album-reapply.ndjson` (4,746 records, 0 written),
`now-album-diff.txt` (exit 0), `phase05-now-after.ndjson.gz` (4,746 records, 0 failed), and the
115 `Vol NNN` folders each carrying exactly one album string.

---
*Phase: 05-inbox-structure-and-the-junk-gate*
*Completed: 2026-09-19*
