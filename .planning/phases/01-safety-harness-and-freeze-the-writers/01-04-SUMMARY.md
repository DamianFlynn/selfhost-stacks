---
phase: 01-safety-harness-and-freeze-the-writers
plan: 04
subsystem: quality-gate
tags: [ffmpeg, ffprobe, jq, ndjson, gzip, snapshot, diff, quality, dupe, qual-01]
requires:
  - scripts/snapshot-music-tags.sh (01-03)
  - scripts/diff-music-tags.sh (01-03)
  - /mnt/fast/safety/music-pre-project/tags/ (01-02 — the fence directory the capture lands in)
  - tank/media/Music@pre-project and tank/downloads@pre-project (01-02 — the coarse undo behind the fine one)
provides:
  - /mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz (9,736 records, 11,504,507 B)
  - /mnt/fast/safety/music-pre-project/tags/pre-project.done (9,736 lines)
  - /mnt/fast/safety/music-pre-project/tags/pre-project.failed (0 bytes)
  - /mnt/fast/safety/music-pre-project/audit/self-diff-20260818T134638Z.txt (recorded exit-0 proof)
  - /mnt/fast/safety/music-pre-project/audit/capture-20260818T131103Z.log
  - a QUAL-01 stanza in MANIFEST.txt emitted by the generator, not hand-appended
affects:
  - Phase 5 (unblocked — staging may now proceed; the before-state exists)
  - Phase 7 (QUAL-02 has its BEFORE side; diff-music-tags.sh is the gate)
  - 01-08 (the chown may now run; the snapshot predates the phase's first library mutation)
  - 01-09 (QUAL-01 is closed by this plan)
  - v2 DUPE-01 (828 duplicate-audio groups measured across the whole backlog)
  - SAFE-03 (158 TKEY-bearing files found OUTSIDE dj-mixes — the 01-02 dump did not cover them)
tech-stack:
  added: []
  patterns:
    - freeze-music-apply.sh derived-state manifest: every fenced class described by the generator
    - detached capture under setsid+nohup with the log teed inside the fence's audit/ dir
key-files:
  created: []
  modified:
    - scripts/freeze-music-apply.sh
decisions:
  - "the QUAL-01 record count is emitted by the manifest GENERATOR, not appended by hand — section 7 rewrites MANIFEST.txt wholesale, so a hand-appended line survives exactly until the next `fence` run"
  - "the capture ran before plan 01-08's chown, so the field-level before-state predates every library write this phase makes; ffprobe records neither uid:gid nor mode, so the ordering is provably free on content and was decided on risk"
  - "tmux and screen are both absent on LXC 100; setsid+nohup is the detach mechanism that works there"
metrics:
  duration: ~55 minutes
  completed: 2026-08-18
  tasks: 2 of 2
  commits: 2
  files_created: 0
  files_modified: 1
  records_captured: 9736
  bytes_read: 182667439814
  wall_clock_seconds: 1877
---

# Phase 01 Plan 04: QUAL-01 Before-State Capture Summary

The before-state exists. **9,736 records over 182.67 GB read in 31m17s, zero failures, every visited
file in exactly one ledger, and the self-diff exits 0 with all five difference categories at zero
against 8,672 matched join keys.** The library is byte-for-byte untouched — ownership still reads
2,543 / 87 / 2,586, identical to the 01-01 baseline. Section 6 of the freeze harness is now
**completely green for the first time**: `tags/` non-empty and no running container able to reach
`/mnt/fast/safety`. QUAL-01 is satisfied, and Phase 5 is unblocked.

## What Was Built

| Task | Output | Commit |
|------|--------|--------|
| 1 | The capture itself — 9,736 records inside the fence | host state, not tracked |
| 2 | Self-diff exit 0 recorded; manifest made self-describing | `93b5070` |

## The census — measured, and the plan's figures were wrong

The plan's Task 1 acceptance criterion offers two branches: the accounted-for count is 9,764, **or**
the SUMMARY states the exact live census per scan root and explains every difference. **This is the
second branch.** The count is 9,736 and the difference is fully explained.

| Scan root | Plan / D-02 | Live census | Records captured | Difference |
|-----------|------------:|------------:|-----------------:|------------|
| `downloads/complete/nzb/unsorted` | 7,451 | **7,451** | **7,451** | none |
| `downloads/complete/nzb/dj-mixes` | 794 | **764** | **764** | **−30** — see below |
| `downloads/complete/nzb/music` | 275 | **277** | **277** | **+2** |
| `media/Music` | 1,244 | **1,244** | **1,244** | none |
| **Total** | **9,764** | **9,736** | **9,736** | **−28** |

Both differences are settled facts, not rounding:

- **`dj-mixes` −30.** The 794 figure counted the 30 JPEG cover scans as if they were tracks and
  missed the 24 BMP scans entirely (`764 audio + 30 jpg = 794`). Established in 01-02, re-confirmed
  independently in 01-03, and now confirmed a third time by a live extension-anchored count.
  PROJECT.md, ROADMAP.md and REQUIREMENTS.md carry the correction as of `3ff10cb`.
- **`music` +2.** The live tree holds 277 audio files (178 mp3 + 97 flac + 2 wv), not 275. The
  two `.wv` (WavPack) files are the likely source of the original undercount — `wv` is in the
  scanner's `AUDIO_EXT` list and both were captured cleanly.

**There is no coverage hole.** `9,736 records + 0 failed = 9,736 done = 9,736 files seen`, and the
per-root record counts equal the per-root live census exactly, root by root. No file appears in
neither ledger.

## Ledgers and integrity

| Check | Result |
|-------|--------|
| `wc -l pre-project.done` | **9,736** |
| `zcat pre-project.ndjson.gz \| wc -l` | **9,736** |
| `wc -l pre-project.failed` | **0** (file is 0 bytes; sha256 `e3b0c442…b855`, the empty-string digest) |
| `zcat … \| jq -e .` | **exit 0** — every line valid JSON |
| `audio_md5` not matching `^[0-9a-f]{32}$` | **0** |
| `gzip -t` | **OK** — all 9,736 concatenated members read as one stream |
| duplicate `source_path` in the NDJSON | **0** |
| duplicate lines in `.done` | **0** |
| `grep -c TKEY` | **306** (non-zero, as required) |
| Compressed size | **11,504,507 B (10.97 MiB)** |
| sha256 | `7b3a09aeb44d4aba544d239b5edcf1a69496c764656abef23d1764d15225fd88` |

**`.failed` is empty. There are no failed entries and therefore no reasons to give.** 9,736 of 9,736
files were probed successfully on the first pass — no retry run was needed. This matches 01-02's
result on the `dj-mixes` subset (764/764) and extends it to the full population.

## Runtime — 31m17s against a 36-minute projection

| Root | Files | Bytes | Projected (01-03) | **Actual** | Delta |
|------|------:|------:|------------------:|-----------:|------:|
| `unsorted` | 7,451 | 103,124,912,222 | 24m34s | **22m36s** | −8% |
| `dj-mixes` | 764 | 25,796,916,217 | 3m51s | **2m54s** | −25% |
| `music` | 277 | 17,354,005,465 | 2m06s | **1m26s** | −32% |
| `media/Music` | 1,244 | 36,391,605,910 | 5m46s | **4m18s** | −25% |
| **Total** | **9,736** | **182,667,439,814** | **36m17s (2,177s)** | **31m17s (1,877s)** | **−13.8%** |

Overall **0.193 s/file, 92.81 MB/s**. 01-03's two-point cost model (`a = 0.1255 s/file`,
`b = 0.005482 s/MB`) was **conservative by 14%** — it over-predicted every root, and by the most on
the large-average-file roots, which is the signature of the marginal MB term being slightly
pessimistic rather than the fixed per-file term being wrong. The model was fit to good purpose: it
turned "a multi-hour run" into a decision to sit through it, and that decision was correct.

Started `2026-08-18T13:11:03Z`, complete by `13:42`. Run detached under `setsid`+`nohup` with the log
teed to `audit/capture-20260818T131103Z.log`. **It ran to completion in a single pass — the resume
path was never needed here** (it was proven in 01-03 instead, 26 + 39 = 65 exactly).

## Distinct keys: 8,672 against 9,736 records — the first backlog-wide duplicate measurement

**1,064 excess records across 828 duplicate-audio groups spanning 1,892 records.** This is expected
and informative, exactly as the plan anticipated: identical audio in two locations produces the same
`audio_md5`. It is also the first hard DUPE-01 measurement at full scale — 01-03 could only see one
folder pair.

| Group size | Distinct hashes |
|-----------:|----------------:|
| 1 (unique) | 7,844 |
| 2 | 730 |
| 3 | 10 |
| 4 | 38 |
| 5 | 50 |

**Where the duplicates live:**

| Roots spanned by the group | Groups |
|---|---:|
| `unsorted` + `dj-mixes` | **725** |
| `unsorted` alone (internal duplication) | **103** |
| any group touching `music` or `media/Music` | **0** |

Three findings fall out of this that the plan did not anticipate:

1. **The existing library shares no audio bitstream with any backlog file — zero groups touch
   `media/Music`.** Every one of the 1,244 library files is unique by audio hash across the whole
   9,736-file population. This is materially good news for Phase 7: an import cannot collide with an
   already-tagged library track by content, so the "did the import degrade the existing library"
   question is about destination *paths*, not about re-importing content already present.
2. **`unsorted` duplicates itself 103 times over, independently of `dj-mixes`.** The 85 shared
   folder names between the two roots were the known problem; internal duplication inside `unsorted`
   was not. The 50 five-member and 38 four-member groups are the visible shape of it — e.g. the
   `VA-Mastermix.Issue.468-470-2025` / `…-2025.1` / `VA-Mastermix.Issue.469-2025` triple, three
   copies of the same rip under three names.
3. **725 of the 828 groups are the `unsorted`/`dj-mixes` overlap**, which now has a number rather
   than a folder-name estimate. 01-03 warned against generalising from the single Now! 120 pair; the
   generalisation turns out to hold broadly, but it is 725 groups, not 85 folders, and the group
   sizes say the relationship is not a clean one-to-one.

## SAFE-03 finding: TKEY and EnergyLevel exist outside `dj-mixes`

The 01-02 fence dumped full `ffprobe` for the 764 `dj-mixes` files and found 148 `TKEY` and 45
`EnergyLevel`. The full capture reproduces both numbers exactly — and finds more elsewhere:

| Key | `dj-mixes` | `unsorted` | Total |
|-----|-----------:|-----------:|------:|
| `TKEY` | 148 | **158** | 306 |
| `EnergyLevel` | 45 | **45** | 90 |

Of `unsorted`'s 158 `TKEY`-bearing hashes, **148 are the same audio as `dj-mixes`' 148** — the
duplication above. **10 are not.** Those ten are Mastermix issue content sitting in `unsorted` with
no counterpart in `dj-mixes`, e.g.
`unsorted/VA-Mastermix.Issue.469-2025/Mastermix - Summer Dance 2 127.mp3`.

**SAFE-03's dedicated dump does not cover them**, because that dump was scoped to `dj-mixes` by
folder. They are covered now, by this snapshot. Whoever plans the DJ-content work should note that
DJ-service content is not confined to the `dj-mixes` folder, and that a folder-scoped selection of
"the DJ collection" will miss files that carry the very tags SAFE-03 exists to protect.

## The self-diff — exit 0, and why that is only half the evidence

Run with `pre-project.ndjson.gz` as **both** BEFORE and AFTER, output recorded to
`audit/self-diff-20260818T134638Z.txt` (527 KB — the full run including the informational duplicate
listing, not a summary).

```
BEFORE: pre-project.ndjson.gz  (9736 records, 8672 distinct audio_md5)
AFTER : pre-project.ndjson.gz  (9736 records, 8672 distinct audio_md5)
```

| Category | Count |
|----------|------:|
| MATCHED | **8,672** |
| MISSING_AFTER | **0** |
| NEW_AFTER | **0** |
| FIELDS_DROPPED | **0** |
| FIELDS_GAINED | **0** |
| FIELDS_CHANGED | **0** |
| **Exit code** | **0** |

`MATCHED` equals the distinct-`audio_md5` count of 8,672, as the acceptance criterion requires.
(01-03's deviation 7 applies again at scale: `MATCHED` counts distinct join keys, so it is
necessarily below the 9,736 record count wherever duplicate audio exists. That is the correct
semantics for a key-based join, and `before_keys`/`after_keys` both report 8,672.)

**This exercised `diff-music-tags.sh` — the `audio_md5` join, the format/stream tag flattening and
the exit-code contract — not a checksum of the file against itself, and not a re-run of the snapshot
compared by hash.** Re-running would prove determinism, a strictly weaker claim than that the
comparison mechanism works.

**The paired negative control is plan 01-03 Task 3**, which ran the same tool against a deliberately
mutated copy — one `TKEY` dropped, one `title` rewritten — and got **exit 1** with exactly those two
rows and nothing else. A tool that always returned 0 would pass a self-diff. It is only the
combination of the 01-03 exit-1 control and this exit-0 self-diff that makes the result evidence.
Usage errors return 2, also exercised in 01-03. All three exit codes of the contract Phase 7 gates
on are now demonstrated.

**Vacuous-pass guard: correctly silent.** 55 of the 8,672 matched keys had an empty BEFORE tag set —
0.6%, nowhere near the "every matched file" condition that fires the warning. Composition: 94 WAV
records (47 in `unsorted` + their 47 duplicates in `dj-mixes`, collapsing to 47 keys), 5 FLAC and 2
WavPack in `music`, and 1 FLAC in the library. This confirms 01-03's finding from the other
direction: `unsorted`'s WAV content is overwhelmingly **not** tag-free — only 47 of its 134 WAV files
carry no tags at all.

## Fence audit — section 6 green for the first time

```
🧱 6. Fence presence and spot-check (SAFE-02/03/04, D-06/D-08/D-10)
  ✅ fence exists: /mnt/fast/safety/music-pre-project (568:568 755)
  ✅ snapshot present: tank/media/Music@pre-project (via ssh:172.16.1.158)
  ✅ snapshot present: tank/downloads@pre-project (via ssh:172.16.1.158)
  ✅ fence subdirectory non-empty: library-db/ (15 files)
  ✅ fence subdirectory non-empty: dj-mixes-ffprobe/ (764 files)
  ✅ fence subdirectory non-empty: cover-scans/ (54 files)
  ✅ fence subdirectory non-empty: tags/ (3 files)
  ✅ no running container mounts any path under /mnt/fast/safety (D-08, proven not asserted)
```

`fence assertions failed: 0`. **`FAILURES total` dropped 7 → 6**, and the single assertion that
turned green is exactly the one this plan owns. The D-03/D-06/D-08 claim that the snapshot is
"stored where no tagger can write it" is **proven by enumeration** over the same running-container
mount census WRIT-01 uses — not asserted.

## Read-only proof

| Check | Result |
|-------|--------|
| Files modified under `unsorted` since capture start | **0** |
| Files modified under `dj-mixes` since capture start | **0** |
| Files modified under `music` since capture start | **0** |
| Files modified under `media/Music` since capture start | **0** |
| Library ownership mismatches | **2,543** — identical to the 01-01 baseline |
| Library dir-mode mismatches | **87** — identical |
| Library file-mode mismatches | **2,586** — identical |
| System temp dir | only pre-existing systemd/X11 sockets; **nothing this run created** |
| `/mnt/fast` free | 20 GB, unchanged — the capture cost 11.5 MB |

`ffmpeg` was invoked only as `-f md5 -` to stdout and never given an output file path. **The library
must not be mutated by this plan, and it was not.**

## Deviations from Plan

### 1. [Rule 2 - Missing critical functionality] A hand-appended manifest line would have been silently erased

- **Found during:** Task 2, reading `freeze-music-apply.sh` section 7 before appending.
- **Issue:** The plan says to "append the snapshot to `MANIFEST.txt` — its sha256, record count and
  byte size". But `MANIFEST.txt` is **derived state**: section 7 of `freeze-music-apply.sh` rewrites
  it wholesale on every `fence` run, and the script's own header documents it as "the one exception
  … it is derived state and is rewritten". A hand-appended stanza would survive exactly until the
  next `fence` invocation and then vanish with no error — and `fence` is re-run routinely, since it
  is the idempotent apply script for the whole recovery fence. The acceptance criterion
  (`grep -c 'pre-project.ndjson.gz' MANIFEST.txt >= 1`) would have passed at the moment of the check
  and quietly become false later.
- **Fix:** the stanza is emitted **by the generator**. A `## QUAL-01 tag snapshots` section now
  enumerates every `tags/*.ndjson.gz` with record count, distinct `audio_md5`, `.done`/`.failed`
  line counts, byte size and sha256, and prints an explicit "(none — QUAL-01 capture has not been
  run; see plan 01-04)" when the class is empty. Re-running `fence` regenerates it correctly. The
  byte size and sha256 were already covered by the existing per-class and per-artifact sections; the
  **record count and distinct-key count were not, and they are the figures that matter** — Phase 7
  joins on `audio_md5`, and a short capture is indistinguishable from a complete one by byte size
  and digest alone.
- **Files modified:** `scripts/freeze-music-apply.sh`
- **Commit:** `93b5070`

### 2. [Rule 3 - Blocking] Neither `tmux` nor `screen` exists on LXC 100

- **Found during:** Task 1 pre-flight.
- **Issue:** The plan's verification step 4 says to run the capture "under `tmux`, `screen` or
  `nohup`". The first two are **absent** on LXC 100 — verified, not assumed. This is the third
  factual error found in this phase's tooling assumptions (01-01 found the `ffprobe`/`zfs` claims
  wrong, 01-02 found `rsync` absent).
- **Fix:** `setsid` + `nohup` with stdin from `/dev/null` and the log teed inside the fence. The
  process survived the controlling ssh session closing and ran to completion. No package was
  installed — that would have been a package-manager action and out of scope for auto-fix.

### 3. [Finding] The 01-03 cost model over-predicted every root by 8–32%

Actual 1,877s against a projected 2,177s. Not a problem, and the direction is the safe one, but
recorded so the model is not treated as calibrated: it is conservative, and it is conservative most
on large-average-file roots. If parallelism is ever considered (01-03 identified it as the only
lever, the job being CPU-bound on md5 and single-threaded), the baseline to beat is 1,877s.

### 4. [Finding] `music` holds 277 files, not 275 — two WavPack files

See the census table. `.wv` is already in the scanner's `AUDIO_EXT` list so both were captured, but
the D-02 figure of 275 was wrong and any future arithmetic against it will be off by two.

### 5. [Finding] SAFE-03's `TKEY`/`EnergyLevel` population is not confined to `dj-mixes`

See the SAFE-03 section. 10 `TKEY`-bearing files live in `unsorted` with no `dj-mixes` counterpart
and are therefore **outside 01-02's dedicated ffprobe dump**. SAFE-03 remains satisfied — the tags
are captured, twice over now — but the folder-scoped definition of "the DJ collection" is leaky.

### 6. [Finding] The existing library is audio-disjoint from the entire backlog

Zero of the 828 duplicate groups touch `media/Music`. Recorded because it changes what Phase 7 has
to worry about: not content collision, only destination-path collision.

## Known Limitation Carried Forward — a Phase 7 gate, not a footnote

**A duplicated `audio_md5` makes the diff join last-wins.** The join indexes each side by hash, so
when two records share a hash the later line wins and the earlier one's tags are never compared.
01-03 recorded this against 20 shared keys in a trial; **at full scale it applies to 828 groups
covering 1,892 records — 19.4% of the capture.**

The consequence for Phase 7 is concrete and unchanged: **BEFORE will contain both backlog copies
while AFTER contains one imported file, so any tag difference between the two duplicate sources is
invisible to the diff.** The 725 `unsorted`/`dj-mixes` groups are precisely the population where
this bites, and 01-03 already established that the two copies are not guaranteed identical in
anything but audio — `beets.md` records that sizes across the shared folder names differ in both
directions.

`diff-music-tags.sh` surfaces every such pair in its informational section with all paths, so the
condition is always visible and never silent — the recorded self-diff lists all 828. But visibility
is not resolution. **DUPE-01 should be resolved before Phase 7's QUAL-02 gate is treated as
complete.** This is deliberately recorded rather than fixed: silently merging duplicate records
would hide exactly the ambiguity that needs a human decision.

## Requirements Status

**QUAL-01 is satisfied and marked complete.**

- *A re-runnable before-state tag snapshot* — `snapshot-music-tags.sh` is committed and the
  `.done` ledger makes any re-run resume rather than restart.
- *covering every file that is a candidate for import* — all 8,492 backlog files plus the 1,244
  library files (D-02), reconciled root by root with zero coverage holes.
- *recording the full tag set per file* — complete `-show_format -show_streams` output, no
  whitelist; `TKEY` and `EnergyLevel` fall out automatically, 306 and 90 occurrences respectively.
- *keyed by a stable identifier* — `audio_md5` over the encoded bitstream (D-01/D-05), 9,736 of
  9,736 well-formed.
- *stored where no tagger can write it* — inside the fence on `/mnt/fast` (a different physical
  device from `tank`), with zero running containers mounting any path beneath it, proven by
  enumeration.
- *roadmap criterion 6* — met by exercising the diff script, exit 0, recorded under `audit/`, with
  01-03's mutated-copy exit-1 as the paired negative control.

The capture completed **before any file was staged or imported and before this phase's first library
mutation** (01-08's `chown`), which was the ordering the plan's objective argued for.

## Threat Flags

None. No new trust boundary. The run was read-only against all four scan roots (proven: 0 files
modified under any of them), wrote only inside the fence, made no network calls, and installed no
packages. T-01-15 (`/tmp` on tmpfs) held — the system temp directory contains nothing this run
created. T-01-24 stands as dispositioned `accept`: the NDJSON carries full local paths and all
embedded tag text, stays on the operator's own host, is not committed to git, and remains excluded
from the D-07 off-box copy.

## Known Stubs

None. Every artifact this plan promised exists and is populated; nothing is deferred or mocked.

## Self-Check: PASSED

- `/mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz` — FOUND, 11,504,507 B, `gzip -t` OK,
  9,736 valid-JSON records, sha256 `7b3a09ae…25fd88`
- `/mnt/fast/safety/music-pre-project/tags/pre-project.done` — FOUND, 9,736 lines, 0 duplicates
- `/mnt/fast/safety/music-pre-project/tags/pre-project.failed` — FOUND, 0 bytes
- `/mnt/fast/safety/music-pre-project/audit/self-diff-20260818T134638Z.txt` — FOUND, 527,393 B,
  records exit 0
- `/mnt/fast/safety/music-pre-project/audit/capture-20260818T131103Z.log` — FOUND, ends `EXIT=0`
- `grep -c 'pre-project.ndjson.gz' MANIFEST.txt` — returns **2** (QUAL-01 stanza + artifact digest)
- `scripts/freeze-music-apply.sh` — modified, `bash -n` clean, mode 100755 in the index
- Commit `93b5070` — FOUND, pushed to `origin/main`; LXC 100 `/mnt/fast/stacks` is at `93b5070`
- Fence ownership invariant intact: **0** files or directories under the fence not `apps:apps`
- Library untouched: 2,543 / 87 / 2,586 — identical to the 01-01 baseline
- No `trial.*` artifact anywhere under `/mnt/fast/safety`; no scratch file left in `tags/`
