---
phase: 01-safety-harness-and-freeze-the-writers
plan: 03
subsystem: quality-gate
tags: [ffmpeg, ffprobe, jq, ndjson, gzip, shell, snapshot, diff, quality, dupe]
requires:
  - /mnt/fast/safety/music-pre-project/tags/ (01-02 — the fence directory both tools write into)
  - ffmpeg/ffprobe/jq/gzip on LXC 100 (01-01)
provides:
  - scripts/snapshot-music-tags.sh
  - scripts/diff-music-tags.sh
  - the NDJSON schema both tools agree on (audio_md5 / source_path / scan_root / size_bytes / mtime_epoch / ffprobe)
  - a measured cost model for plan 01-04's full capture
affects:
  - 01-04 (runs the full capture with this script; cost is now measured, not assumed)
  - 01-09 (phase closure — QUAL-01 is not satisfied until 01-04 has run)
  - Phase 5 (must not stage anything until 01-04's capture exists)
  - Phase 7 (consumes diff-music-tags.sh unchanged as the QUAL-02 gate)
  - v2 DUPE-01 (first hard measurement: the two Now! 120 folders are the same rip)
tech-stack:
  added: []
  patterns:
    - setup-mpe.sh / freeze-music-apply.sh host-resident apply-script convention
    - pg-migrate.sh guard-then-SKIP preconditions and banner-per-unit-of-work
    - check-renovate.sh numbered-section + colour + trailing "📊 Summary" audit shape
    - freeze-music-apply.sh build_iname_expr() find-predicate array (no eval globbing)
key-files:
  created:
    - scripts/snapshot-music-tags.sh
    - scripts/diff-music-tags.sh
  modified: []
decisions:
  - "audio_md5 is the join key and source_path an attribute (D-01) — proven by the flat 2CD set, where 10 pairs of tracks share a track number and neither path nor filename disambiguates them"
  - "one gzip member per record rather than one stream, so an interrupt leaves a salvageable file; proven by reading a file written across an interrupt boundary"
  - "the .done ledger is written AFTER the NDJSON line, so a hard kill re-emits at most one record and never loses one; SIGINT/SIGTERM are trapped to stop at a file boundary, making an orderly interrupt exact"
  - "the diff reports duplicate audio_md5 across paths as informational, never as a failure — identical audio in two roots is what D-01 is designed to expose"
  - "the diff warns when every matched file had an empty BEFORE tag set, so a vacuous 'no fields dropped' cannot be misread as a pass"
metrics:
  duration: ~45 minutes
  completed: 2026-08-18
  tasks: 3 of 3
  commits: 3
  files_created: 2
  trial_records: 65 across 4 roots, 0 failures
---

# Phase 01 Plan 03: QUAL-01 Snapshot and Diff Tooling Summary

Both halves of QUAL-01's mechanism ship: `snapshot-music-tags.sh` captures full-`ffprobe` NDJSON
keyed on the encoded audio bitstream, and `diff-music-tags.sh` compares two such snapshots field by
field. Both were proven on real content across four roots and three shapes — 65 records, zero
failures — the self-diff returns 0, the mutated-copy control returns 1 with exactly the right rows,
and the interrupt-and-resume test resumed to the byte. **Plan 01-04's full capture is now a measured
~36 minutes over 9,736 files and 170 GiB, not an assumed multi-hour run.**

## What Was Built

| Task | Output | Commit |
|------|--------|--------|
| 1 | `scripts/snapshot-music-tags.sh`, mode 0755 | `22690ac`, fixed in `8b3d845` |
| 2 | `scripts/diff-music-tags.sh`, mode 0755 | `c9391c3` |
| 3 | Bounded trial on LXC 100 across 4 roots — artifacts removed | host state, not tracked |

## The NDJSON schema the two tools agree on

One JSON object per line, one gzip member per line:

| Field | Type | Notes |
|-------|------|-------|
| `audio_md5` | string, `^[0-9a-f]{32}$` | **The key.** `ffmpeg -nostdin -v error -i F -map 0:a -c copy -f md5 -`, `MD5=` prefix stripped. Encoded bitstream only. |
| `source_path` | string | **Attribute, never the key.** |
| `scan_root` | string | Added beyond the plan's minimum, so per-root counts are one `jq` away. |
| `size_bytes` | number | from `stat -c %s` |
| `mtime_epoch` | number | from `stat -c %Y` |
| `ffprobe` | object | **Complete** `-v quiet -print_format json -show_format -show_streams` output, embedded verbatim as `.` by jq. No field whitelist. |

Companion files: `<basename>.done` (one absolute path per line, the resume ledger) and
`<basename>.failed` (`path<TAB>stage<TAB>exit-code`, rebuilt each run so a fixed file leaves the list).

`diff-music-tags.sh` flattens `format.tags` merged with each audio stream's tags, stream keys
prefixed `stream<N>.`, lower-cased for comparison with the original casing reported.

## Trial results — 65 records, 4 roots, 0 failures

Every line valid JSON (`jq -e .` exit 0), `gzip -t` OK, **65 / 65 `audio_md5` match
`^[0-9a-f]{32}$`, zero empty or malformed.** `trial.failed` was 0 bytes.

### Per-root record counts

| Shape | Root | Records | Codec | Bytes | Secs |
|-------|------|--------:|-------|------:|-----:|
| A | `media/Music/Vengaboys/The Greatest Hits Collection (2024)` | **15** | mp3 | 156,544,215 | 2 |
| B | `unsorted/Now_That_s_What_I_Call_Music__120__2Cd__2025` | **20** | pcm_s16le | 734,234,038 | 5 |
| B′ | `dj-mixes/Now_That_s_What_I_Call_Music__120__2Cd__2025` | **20** | pcm_s16le | 734,234,038 | 5 |
| C | `dj-mixes/Mastermix_Issue_404` | **10** | mp3 | 352,910,546 | 2 |
| | **Total** | **65** | | 1,977,922,837 | 14 |

Shapes A and C were captured whole (15 and 10 audio files); B and B′ were capped at 20 of 43 by
`--limit`, applied per root as required.

### `TKEY` / `EnergyLevel` (D-05 proven)

**Both observed — 7 of the 10 shape-C files carry each**, on exactly the same 7 files. Verbatim:

| File | TKEY | EnergyLevel |
|------|------|-------------|
| `Mastermix - 4 Play Teenage Kicks.mp3` | 11B | 7 |
| `Mastermix - 80s Clubbing Revisited.mp3` | 10A | 6 |
| `Mastermix - Chart Hits Pop Dance.mp3` | 10B | 7 |
| `Mastermix - DJ Playlist Garage Anthems vol.1.mp3` | 7A | 6 |
| `Mastermix - Ireland Rocks!.mp3` | 12B | 7 |
| `Mastermix - Mastermixed February 2020.mp3` | 3A | 7 |
| `Mastermix - The DJ Set Dance Party.mp3` | 4A | 7 |

A whitelist-based capture would have needed both names known in advance. They fall out of the full
output with no maintenance, which is what D-05 asked for.

### Non-audio exclusion — clean

`.lrc`, `.txt`, `.nfo`, `.jpg`, `.bmp` and `.mkv` appear **zero times in `trial.ndjson.gz` and zero
times in `trial.failed`**. The extension census of every captured `source_path` is exactly
`25 mp3 / 40 wav`. The filter excludes rather than fails.

The video-filter case was proven separately by pointing the scanner at the
`Harry.Potter…BluRay.x264-MOOVEE` folder **and** at a real `.mkv`-bearing folder
(`nzb/tv/1.Nashville.S01E09…`): 0 files seen, 0 records, 0 failures. No video file ever reached
`-map 0:a`.

## What shape B's WAV records actually contain — the plan's assumption was wrong

**The WAV files are not tag-poor. Every one of the 40 WAV records carries 6 format tags.** Verbatim,
for `01 - Gigi Perez - Sailor Song.wav`:

```json
"format_tags": { "title": "Sailor Song", "comment": "", "track": "01",
                 "artist": "Gigi Perez", "album": "Now That's What I Call Music! 120 Cd2",
                 "date": "2025" },
"format_name": "wav", "nb_streams": 2,
"stream_tags": [ null, { "comment": "Cover (front)" } ]
```

Three consequences the plan did not anticipate:

1. **The plan's premise that "a record with an empty or near-empty tag set is a legitimate result
   here" does not hold for this folder.** 40 of 40 WAV records carry `title`, `artist`, `album`,
   `track`, `date` and `comment` in a RIFF tag block. Shape B is therefore *not* the vacuous-pass
   case it was chosen to be. The diff tool still guards against that case — it reports
   `matched_with_no_before_fields` and warns loudly when it equals MATCHED — but the guard went
   unexercised on real content here (it was exercised on synthetic input during development).
   **Whether the rest of `unsorted`'s 134 WAV files behave the same way is untested**; only this
   folder's were sampled.
2. **`album` disambiguates the disc even though the path and filename do not** — the tag reads
   `… 120 Cd1` or `… 120 Cd2`. So the 2CD split is recoverable from tags, which materially improves
   Phase 5's odds on this release. Per-track `artist` is also distinct throughout, and the
   flattening keeps it distinct rather than collapsing to an album-level value.
3. **Each WAV carries a second, non-audio stream holding embedded cover art.** `-map 0:a` correctly
   maps only stream 0, and the diff's flattening filters on `codec_type == "audio"`, so the art
   stream's `comment: "Cover (front)"` never contaminates the tag set. This was luck as much as
   design — the plan expected the art to be the loose `.bmp` files, not an embedded stream.

## The flat 2CD set: colliding track numbers produce distinct hashes

**Confirmed, and the collision is far wider than the plan states.** The plan says "there are two
`07 -` and two `09 -` files". In fact **every track number 01 through 21 appears twice** (43 WAV =
21 pairs + one track 22). All 20 sampled hashes are distinct; the ten colliding pairs in the sample:

| Track | Disc 1 | Disc 2 |
|-------|--------|--------|
| 01 | `1653867101ef…` Gracie Abrams | `39a87a68b1de…` Gigi Perez |
| 02 | `edbb3d2c88a4…` ROSÉ & Bruno Mars | `c2dc4752c091…` Billie Eilish |
| 03 | `dd87a3f35cb3…` Lola Young | `286243dc35f1…` Myles Smith |
| 04 | `bf9ef12e3a6c…` Chappell Roan | `439882f65d6f…` Sam Fender |
| 05 | `8aa5195c5a1a…` Sabrina Carpenter | `e850a85a182a…` Teddy Swims |
| 06 | `1dc99bfb9de4…` Charli xcx | `26945864e5e4…` Alex Warren |
| 07 | `98ea86dd4fa1…` Lady Gaga | `61e68a3ec09e…` Coldplay |
| 08 | `50f7b9e15393…` CHRYSTAL | `57ee30ebb470…` The Cure |
| 09 | `45594d2cec05…` KSI | `def64f72f781…` Shawn Mendes |
| 10 | `c7cb5f34aab1…` The Weeknd | `80c7f55d52cc…` Cian Ducrot |

This is the strongest single demonstration of D-01 in the sample: a path-keyed or filename-keyed
snapshot cannot tell these apart; the audio hash separates all twenty.

## B / B′ overlap — the two folders are the same rip

Sampling was deterministic (`find | LC_ALL=C sort`, first 20 per root), so both sides drew the
**identical** filename-ordered list — the 20 files from `01 - Gigi Perez - Sailor Song.wav` through
`10 - The Weeknd & Playboi Carti - Timeless (Super Clean Radio Edit).wav`, as tabulated above.

| Measure | Count |
|---------|------:|
| `audio_md5` present in **both** copies | **20** |
| unique to `unsorted` | **0** |
| unique to `dj-mixes` | **0** |

**A complete 20/20 overlap.** Both folders also report byte-identical totals (734,234,038 B for the
same 20 files). Combined with matching file counts (43 wav + 8 bmp on each side; `dj-mixes` carries
one extra `.nfo`), the conclusion is that these are **the same rip stored twice**, and one copy can
be dropped in v2's DUPE-01 work. This is the first hard measurement feeding DUPE-01 — but it covers
**1 of the 85 shared folder names**, and `beets.md` warns that sizes across those 85 differ in both
directions, so it must not be generalised.

Across all 65 records there are **45 distinct `audio_md5`** and **20 hashes appearing under two
paths** — every one of them a B/B′ pair, listed in full by the diff's informational section. Zero
hashes collided within a single root.

## Interrupt-and-resume — exact

Artifacts deleted, re-run, `SIGTERM` sent to the script PID after 6 s, then the identical command
re-run:

| | `trial.done` lines | NDJSON records | `.failed` |
|---|---:|---:|---:|
| After interrupt | **26** | **26** | 0 |
| Second run added | **39** | **39** | 0 |
| **Total** | **65** | **65** | 0 |

26 + 39 = 65, matching the uninterrupted run exactly, with the same four per-root counts
(15 / 20 / 20 / 10). The second run reported `Resume ledger: 26 path(s) already captured` and
`skipped=26`, and shape A — fully captured before the interrupt — processed 0 files.

- `sort trial.done | uniq -d | wc -l` → **0**
- duplicate `source_path` in the NDJSON → **0**
- `gzip -t` → OK, and `jq -e .` passed every line, so the **gzip members written either side of the
  interrupt boundary read back as one stream**. The exit code was `130`.

## Diff exit codes and row counts

| Run | Exit | MATCHED | MISSING_AFTER | NEW_AFTER | FIELDS_DROPPED | FIELDS_GAINED | FIELDS_CHANGED |
|-----|-----:|--------:|--------------:|----------:|---------------:|--------------:|---------------:|
| Self-diff (`trial` vs `trial`) | **0** | 45 | 0 | 0 | **0** | 0 | 0 |
| Mutated copy | **1** | 45 | **0** | 0 | **1** | 0 | **1** |
| Usage: 0 args / 1 arg / missing input | **2** | — | — | — | — | — | — |

The mutated-copy control dropped `TKEY` from one record and rewrote `title` on another, both chosen
from **unique** hashes (see the limitation below). It returned exactly:

```
ee92e5ad…  …/Mastermix_Issue_404/Mastermix - Ireland Rocks!.mp3   TKEY   12B → (null)
f2304bd4…  …/Vengaboys/… Parada de Tettas.mp3   title   "Parada de Tettas" → "MUTATED FOR THE NEGATIVE CONTROL"
```

The self-diff exercises the join, the flattening and the exit-code contract — not a file checksum.
`--summary-only`, `--full` and `--json` were all exercised; `--json` carries the same exit contract.

## Plan 01-04's projected cost — measured, not assumed

Two large timed samples on real backlog content, chosen at opposite ends of file size:

| Sample | Files | Bytes | Secs | s/file | MB/s | avg MB |
|--------|------:|------:|-----:|-------:|-----:|-------:|
| Small mp3 (`Mastermix.Decades.USB.80s`) | 300 | 2,937,019,441 | 53 | 0.177 | 52.85 | 9.34 |
| Large mp3 (`unsorted`, first 200) | 200 | 7,249,359,021 | 63 | 0.315 | 109.74 | 34.57 |

Fitting `t = a + b·MB` across those two points gives **a = 0.1255 s/file fixed** and
**b = 0.005482 s/MB (182 MB/s marginal)**. The model reproduces the four trial shapes within the
±1 s resolution of their short runs.

**Real D-02 scope, measured on the host rather than taken from the plan:**

| Root | Audio files | Bytes | GiB | avg MB | Projected |
|------|------------:|------:|----:|-------:|----------:|
| `unsorted` | 7,451 | 103,124,912,222 | 96.04 | 13.20 | **24m 34s** |
| `dj-mixes` | 764 | 25,796,916,217 | 24.03 | 32.20 | **3m 51s** |
| `music` | 277 | 17,354,005,465 | 16.16 | 59.75 | **2m 06s** |
| `media/Music` | 1,244 | 36,391,605,910 | 33.89 | 27.90 | **5m 46s** |
| **Total** | **9,736** | **182,667,439,814** | **170.12** | 17.90 | **≈ 36 minutes** |

**What dominates:** per-file process-spawn overhead, narrowly — 1,222 s of the 2,177 s projection
(56%) is the fixed `0.1255 s/file` term against 955 s (44%) of bitstream reading. That is a
consequence of `unsorted` being 7,451 files at a 13.2 MB average. Independently, `time` on the
200-file run reported **50.8 s of CPU against 63 s of wall clock**, so the job is **CPU-bound on
md5 hashing and single-threaded, not disk-bound** — the pool can feed it faster than one core can
hash. If 36 minutes ever became unacceptable, parallelism across roots is the lever, not faster
storage.

**36 minutes is well inside "a couple of hours", so 01-04 can run attended in one sitting.** Output
size projects to **~9.8 MB gzipped** (trial: 65 records in 65,486 B = 1,007 B/record), which is
negligible against the fence's 303 MB.

**ARC behaviour (input to attended-vs-overnight):** the concern that a sequential 170 GiB read would
evict the ARC on a host previously taken down by memory pressure **does not apply as feared** — the
Proxmox host's ARC is **hard-capped at a 2.49 GB target and was sitting at 2.42 GB after the trial's
reads**, with a 99.9% lifetime hit rate. The read cannot balloon it. The host was at 23 of 28 GB
used with 5 GB available throughout. No memory-pressure risk was observed.

## Read-only proof (T-01-13)

`find <root> -newermt "2026-08-18 12:00"` returned **0 modified files** under all three probed scan
roots after the entire trial. `ffmpeg` was invoked only with `-f md5 -` to stdout and never with an
output file path. Neither script contains a `chown`, `chmod`, `mv` or `rm` against any scan root —
the only `rm` in either is `diff-music-tags.sh`'s EXIT trap over its own scratch files, and the only
`chown` is `snapshot-music-tags.sh` setting **its own three output files** to the fence's `568:568`.

## Deviations from Plan

### 1. [Rule 1 - Bug] A zero-file run never created the ledger and printed an error on success

- **Found during:** Task 3, proving the audio filter against the video-bearing folders.
- **Issue:** `.done` was only created on the first successful record. A run that legitimately
  processes zero files — every path already in the ledger, or a root holding only non-audio — hit
  `wc -l < "$DONE_LEDGER"` in the summary and printed
  `No such file or directory` **on an otherwise clean run that then reported "snapshot: complete"**.
  In 01-04's log that reads as a failure. The NDJSON is likewise absent, so a downstream diff
  invocation would report a confusing "input not found".
- **Fix:** the ledger is created up front; the summary reports `(not created - 0 records written)`
  when there is genuinely no NDJSON.
- **Commit:** `8b3d845`

### 2. [Rule 2 - Missing critical functionality] Outputs broke the fence's ownership invariant

- **Found during:** Task 3, listing `tags/` after the filter run.
- **Issue:** everything `freeze-music-apply.sh fence` writes is `apps:apps` with files `644`, and
  `check-music-freeze.sh` asserts it. This script's outputs landed `root:root`, so the very files
  QUAL-01 exists to produce would have shown up as fence drift caused by the tool that created them.
- **Fix:** the three output files are chowned `568:568` and chmodded `644` at the end, best-effort —
  a warning rather than a failure when not run as root, so a non-root operator still gets a usable
  capture. Verified: `trial.*` came back as `apps apps`.
- **Commit:** `8b3d845`

### 3. [Finding] Shape B's WAV files carry full tags — the plan's central assumption about them is wrong

See "What shape B's WAV records actually contain" above. The plan chose this folder specifically as
the near-empty-tag-set case and told the diff not to treat it as a vacuous pass. It is not that case.
The guard exists and is correct, but real content did not exercise it. **Plan 01-04 and Phase 7
should not assume `unsorted`'s WAV content is tag-free.**

### 4. [Finding] The `Harry.Potter…MOOVEE` folder is in `unsorted`, not `dj-mixes`, and is empty

The plan says "`dj-mixes` also contains a `Harry.Potter…BluRay.x264-MOOVEE` folder". It does not —
`dj-mixes` has 84 folders and none is video-ish; the folder is at
`unsorted/Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE` and
**contains zero files** (an empty directory dated Jan 2026). Scanning it alone would have proven
nothing about the filter, so the test was strengthened to include a real `.mkv`-bearing folder
(`nzb/tv/1.Nashville.S01E09.1080p.WEB.h264-ETHEL`). Both returned 0 records and 0 failures. Note
also that **there are no video files anywhere under `unsorted`, `dj-mixes` or `music`** — the `.mkv`
content lives under the sibling `tv/` and `movies/` trees, which are not D-02 scan roots.

### 5. [Finding] Shape A has no `folder.jpg`, and every track number in shape B collides

The plan states shape A "carries `.lrc`, `.txt` and `folder.jpg` sidecars". The real sidecar set is
**12 `.lrc`, 3 `.txt`, 1 `.nfo` and no image at all**. The filter test is unaffected (`.nfo` is just
as good a negative), but the `folder.jpg` assertion could not be tested as written. Separately, the
plan's "two `07 -` and two `09 -` files" understates the collision: **all 21 track numbers appear
twice**, ten pairs of them inside the sample.

### 6. [Finding] The scope is 9,736 files and 170 GiB, not 9,764 files and ~140 GB

Measured directly, extension-anchored, on the host:

| | Plan / D-02 | Measured |
|---|---:|---:|
| `unsorted` | 7,451 | **7,451** ✓ |
| `dj-mixes` | 794 | **764** (630 mp3 + 134 wav — 01-02's correction confirmed again) |
| `music` | 275 | **277** (178 mp3 + 97 flac + 2 wv) |
| library | 1,244 | **1,244** ✓ |
| **Total** | 9,764 / ~140 GB | **9,736 / 170.12 GiB (182.67 GB)** |

The byte figure is the material one: **the read is ~22% larger than the plan assumed.** It is
already folded into the 36-minute projection above.

### 7. [Criterion conflict] "MATCHED equal to the record count" is unsatisfiable by this trial's design

The acceptance criteria require the self-diff to report `MATCHED` equal to the record count. It
reports **45 against 65 records** — necessarily, because the plan deliberately included B′ as an
exact-name twin and 20 hashes are therefore shared. `MATCHED` counts distinct join keys, which is
the correct semantics for a key-based join. The two requirements (include the twin; expect
MATCHED == records) cannot both hold. `MATCHED` equals the **45 distinct `audio_md5`**, and
`before_keys` / `after_keys` report 45 on both sides, so the diff is internally consistent. No code
was changed for this.

### 8. [Known limitation, carried forward to Phase 7] A duplicated `audio_md5` makes the join last-wins

Because the join indexes each side by hash, when two records share a hash the **later line wins** and
the earlier one's tags are not compared. In this trial the `dj-mixes` copy won all 20 shared keys.
This is harmless while the two copies are byte-identical, but it means the mutated-copy control had
to target unique hashes to be meaningful, and more importantly: **in Phase 7, BEFORE will contain
both backlog copies while AFTER contains one imported file, so any tag difference between the two
duplicate sources is invisible to the diff.** The diff surfaces every such pair in its informational
section with both paths, so the condition is always visible — but **DUPE-01 should be resolved
before Phase 7's QUAL-02 gate is treated as complete.** Recorded rather than fixed: silently merging
duplicate records would hide exactly the ambiguity that needs a human decision.

## Requirements Status

**QUAL-01 is not satisfied by this plan and is not marked complete.** This plan authored and proved
the mechanism; the requirement is "a re-runnable before-state tag snapshot", and the snapshot itself
does not exist until **plan 01-04** runs the full capture. `tags/` is deliberately empty again, which
means `check-music-freeze.sh` section 6 still reports one failure — the correct state at the end of
this plan, exactly as 01-02 left it.

## Threat Flags

None. Both scripts are read-only against content, spawn no network calls, install no packages, and
write only inside the fence. The two new files add no trust boundary beyond the ones 01-01 and 01-02
already established.

## Known Stubs

None. Every code path in both scripts is implemented and exercised: all three exit codes of the diff,
all three of its output modes, the snapshot's resume path, its failure path (via the shape checks),
its zero-file path and its interrupt path.

## Self-Check: PASSED

- `scripts/snapshot-music-tags.sh` — FOUND, mode 100755 in the index, `bash -n` clean
- `scripts/diff-music-tags.sh` — FOUND, mode 100755 in the index, `bash -n` clean
- Commit `22690ac` — FOUND
- Commit `c9391c3` — FOUND
- Commit `8b3d845` — FOUND; all three pushed to `origin/main` and LXC 100 `/mnt/fast/stacks` is at `8b3d845`
- `/mnt/fast/safety/music-pre-project/tags/` — FOUND, **empty (0 entries)**; no `trial.*` anywhere under `/mnt/fast/safety`
- LXC 100 system temp dir — holds only pre-existing systemd/X11 sockets; nothing this plan created
- Fence subdirectory counts unchanged from 01-02: `library-db` 15, `dj-mixes-ffprobe` 764, `cover-scans` 54, `audit` 3
- No `*.py`, `pyproject.toml` or `requirements.txt` created anywhere in the repo
