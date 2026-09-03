---
phase: 03-tagger-spike
plan: 05
subsystem: dj-tag-normalisation
tags: [mutagen, id3, dry-run-default, scratch-root-fence, snapshot-proof, manifest-diff, va_likely, TAGR-01, TAGR-02, D-07, D-08, OD-4, OD-6]
requires:
  - "03-03 — the 24-folder sample, the reflinked scratch tree, tank/downloads@spike-03-t0 and the 335-record BEFORE capture"
  - "03-04 — beets-spike (normalised :ro) and beets-spike-rw (the single writer arm), and the /spike-scripts delivery mount"
provides:
  - "scripts/normalise-dj-tags.py — the repo's first committed Python file; dry-run by default, fenced two ways, three measured rules"
  - ".planning/phases/03-tagger-spike/03-NORMALISATION.md — the reviewed dry-run diff, the artist-policy choice, and the field-loss verdict on three instruments"
  - "/mnt/tank/downloads/spike-03/normalised — 205 of 335 files carrying repaired album and artist; criterion 1's normalised arm"
  - "/mnt/tank/downloads/spike-03/raw — the un-normalised paired arm, proven byte-identical throughout"
  - "the artist-policy parameter (label | various | keep) plan 03-07 interprets its four-cell comparison against"
  - "DEF-03-03 — audio_md5 is not tag-invariant, and the whole Phase 1 tag-diff harness joins on it"
affects:
  - "03-07 — criterion 1's normalised arm is now measurable; must read the artist-policy choice and finding 1 before attributing V2's lift"
  - "03-06, 03-07, 03-10 — beets-spike was FORCE-RECREATED here; a bind mount pins the directory inode and the old one was stale"
  - "03-11 — teardown must remove /mnt/fast/spike-03/out (6.1 M, 132 manifests) as well as the scratch tree"
  - "Phase 7 QUAL-02 — the gate joins on audio_md5, which DEF-03-03 shows can report file-level loss where none occurred"
tech-stack:
  added:
    - "mutagen 1.48.1 (already present in the LSIO beets image as a beets dependency; nothing installed)"
  patterns:
    - "Inverting a repo convention deliberately and stating the inversion in a named header block rather than inheriting silently"
    - "Delegating a precondition the runtime cannot check (zfs) to a proof file the caller produces, so unreachable means UNKNOWN rather than skipped"
    - "Asserting a write's blast radius with an instrument INDEPENDENT of the library that performed it — the on-disk frame set parsed without mutagen"
    - "Hashing the sorted proposal set from both the dry run and the apply, so 'the dry run predicted the apply' is a sha256 equality rather than a claim about counts"
    - "Re-materialising the mutated tree from its read-only twin between attempts, so every recorded number comes from one clean invocation"
key-files:
  created:
    - scripts/normalise-dj-tags.py
    - .planning/phases/03-tagger-spike/03-NORMALISATION.md
  modified:
    - .planning/phases/03-tagger-spike/deferred-items.md
    - .gitignore
decisions:
  - "--artist-policy defaults to `label` (Mastermix / DMC): it is the only value of the three OUTSIDE beets' VA_ARTISTS, so va_likely is false and the Discogs query is the canonical album string alone"
  - "Rule 2 removes the label SEPARATOR, not the label — the plan's literal 'strip a leading Mastermix - prefix' lands on 'Issue 410', which is not rule 1's canonical form and is a hopelessly generic query"
  - "The trailing ID3v1 block is restored byte-for-byte after every save; ID3v1 then carries a stale album/artist, which nothing in this project reads"
  - "mutagen's load_v1 and v2_version defaults both broaden the write and are set explicitly; a frame-set assertion parsed WITHOUT mutagen backstops a fourth such default"
  - "The field-loss verdict is recorded on three instruments, not one, because audio_md5 collapses the draw's 29 deliberate near-duplicates and is not tag-invariant"
  - "TAGR-01 and TAGR-02 are NOT marked complete: this plan builds criterion 1's normalised arm, it does not measure the rate — that is plan 03-07"
metrics:
  duration: "~1h"
  completed: 2026-09-03
---

# Phase 3 Plan 05: Minimum-Viable DJ Tag Normalisation Summary

Built and ran the normalisation criterion 1's normalised arm depends on — 205 of 335 files repaired,
`FIELDS_DROPPED = 0`, changed fields exactly `{album, artist}` on three independent instruments —
and found in the process that **mutagen does not write back what it read**: three of its defaults
silently broadened the write, one of them invisible to this phase's own field-loss gate.

## What was built

**`scripts/normalise-dj-tags.py`** (~880 lines) — the repo's **first committed Python file**, so it
establishes the convention rather than following one: `#!/usr/bin/env python3`, the repo's fixed
header section order, `argparse` with the exit-2 usage contract from `diff-music-tags.sh:26-32`,
`logging` to stderr, `json.dumps` for structured output, and exceptions routed to a `.failed` ledger
rather than swallowed. No `tempfile` import and no scratch path at all — mutagen saves in place and
the NDJSON streams to `--out`, flushed per record.

Four design choices carry the weight:

1. **`--dry-run` is the default and the inversion is stated out loud.** A named `FLAG CONVENTION`
   block explains that it inverts `check-music-freeze.sh:31-38` deliberately, because an
   irreversible in-place tag write over reflinked copies earns a stricter default than a read-only
   audit does. Silently inheriting a convention is how the docker `created`-state blind spot hid two
   down containers for six weeks under a green check.
2. **Two hard refusals, both exit 2, both naming the offending value.** A hardcoded
   `SCRATCH_ROOT = /mnt/tank/downloads/spike-03` prefix check over `os.path.realpath`, and an
   `--apply` that refuses without a proof of `tank/downloads@spike-03-t0` — *because that snapshot
   is its only rollback*. `zfs` cannot resolve on LXC 100 or inside the container, so the check is
   **delegated** to a proof file the caller produces from atlantis. An unreachable atlantis produces
   no file, the script exits 2, and the snapshot state is UNKNOWN — never a skip and never a pass.
3. **`WRITABLE_FIELDS = ("album", "artist")` is a frozen constant** and every write asserts
   membership before it happens. `title`, `track`, `date`, `genre`, `TKEY` and `EnergyLevel` appear
   in the file **only** in the docstring, and only to say that no rule reads or writes them.
4. **The blast radius is asserted by an instrument independent of the library doing the writing.**
   `assert_frame_set_unchanged()` re-parses the ID3v2 tag off disk **without mutagen** after every
   save and requires the frame-ID multiset to equal what it was plus the frames this script wrote.
   That backstop exists because three mutagen defaults had already broadened the write; a fourth
   now fails loudly into the ledger instead of silently enlarging the diff.

**`.planning/phases/03-tagger-spike/03-NORMALISATION.md`** (608 lines) — the OD-4 correction, the
reviewed dry-run diff with every out-of-stratum hit explained *before* anything was applied, the
recorded artist-policy choice with its cost, the applied result, and the field-loss verdict on three
instruments.

## Results

| Assertion | Result |
|---|---|
| `python3 -m py_compile` | **exit 0** |
| `--help` names `--dry-run` and `--apply`, states the default | **yes** |
| Target `/mnt/tank/media/Music` | **exit 2**, naming both the given path and the required root |
| `--apply` with no `--snapshot-proof` | **exit 2**, before the banner and before any audio file is opened |
| `--apply` with a proof file not naming the snapshot | **exit 2** |
| Unknown flag | **exit 2** |
| Bare `tempfile.mkstemp()` / `mkdtemp()` / literal `/tmp/` write path | **0** each — no `tempfile` import at all |
| `title`/`track`/`date`/`genre`/`TKEY`/`EnergyLevel` in the code with strings and comments stripped | **0** each |
| **Dry run** — exit / folders / files / would change / unchanged | **0** / **24** / **335** / **205** / **130** |
| Dry-run rule 1 / 2 / 3 hits | **30** / **155** / **107** |
| Dry run wrote nothing — `find -newer`, `normalised/` and `raw/` | **0 lines** each |
| Dry run wrote nothing — whole-subtree `.meta` and `.sha` manifest diffs, both trees | **empty**, all four |
| Dry run ran where `normalised/` is `RW=false` | **asserted from `docker inspect`** |
| **Apply** — exit / files changed / rule hits / skipped / failures | **0** / **205** / **30·155·107** / **0** / **0** |
| Snapshot proof route | **`ssh:172.16.1.158`** (atlantis) |
| **Dry run predicted the apply** | **identical sha256** over the sorted `(path, field, rule, old, new)` set — `9b7e1799…`, all 292 rows |
| Idempotence — a genuine second `--apply` | **0 changed, 0 records, 0 stdout lines, exit 0** |
| Frame-set assertion failures | **0** |
| Writer arm window | `22:26:47Z` → `22:27:03Z`, **16 s** |
| `beets-spike-rw` in `docker ps -a` afterwards | **absent** |
| **`diff-music-tags.sh` exit code** | **0** — `MISSING_AFTER 0`, `NEW_AFTER 0`, **`FIELDS_DROPPED 0`** |
| Changed field names / gained field names | **exactly `{album, artist}`** / **exactly `{album, artist}`** |
| Vacuous-pass guard | **did not fire** — 0 matched files had an empty BEFORE tag set |
| Path-keyed over all 335 files | 335 matched, 0 missing, **0 dropped**, gained `album` 30 + `artist` 10, changed `album` 155 + `artist` 97, nothing else |
| On-disk ID3v2 frame-ID multiset vs the untouched `raw/` twin, parsed without mutagen | **40 of 335 differ**, and the difference is `TALB` 0→1 ×30 and `TPE1` 0→1 ×10 |
| ID3v2 major version, `raw/` → `normalised/` | **(3, 3) on all 335** |
| Live `ffprobe`, 5 files across strata + a V1 control | only `album` (5) and `artist` (2) moved; **6 of 6 agree**; control untouched |
| `raw/` untouched — `find -newer` / `.meta` diff / `.sha` diff | **0 lines** / **empty** / **empty** |
| `raw` mount mode on `beets-spike` and `beets-spike-rw` | **`RW=false`** on both |
| `bash scripts/check-music-freeze.sh` | **exit 0**, `FAILURES total: 0` |
| Beets databases under `/mnt/fast/appdata` (`*.blb` **and** `library.db`) modified during the run | **0 of 4** |
| `.bak` files created under `/mnt/fast/appdata/arrs` | **0** |
| `/tmp` entries matching `spike` | **0** |
| `df -h /` | **35 G free**, unchanged |

## The findings that outlive this plan

**1. mutagen does not write back what it read — and three of its defaults broaden the write.** It
re-serialises its own normalised in-memory model of the tag. Each of these was found by measurement
on the sample, not by reading the docs:

| Default | What it did | How it is now prevented |
|---|---|---|
| `ID3.save(v1=UPDATE)` regenerates the whole 128-byte ID3v1 block from the ID3v2 frames | moved `audio_md5` on **37 of 335** files | the pre-write block is restored **byte-for-byte** |
| `ID3.load(load_v1=True)` merges the ID3v1 tag in as a synthetic `COMM:ID3v1 Comment:eng` frame, which `save()` then writes to disk | **107 of 335** files gained an `ID3v1 Comment` key | `load_v1=False` |
| `v2_version` is a **load-time** option; the default `4` translates `TYER`/`TDAT`/`TIME` to `TDRC`, and `save(v2_version=3)` does **not** undo it | a `TYER` frame of 5 bytes came back as a `TDRC` frame of 6 — a v2.4-only frame ID inside a v2.3 tag | `v2_version` set at **load**, from the file's own 10-byte header |

The third is the one to carry furthest: **`ffprobe` maps both `TYER` and `TDRC` to `date`, so
`diff-music-tags.sh` reported nothing at all.** The phase's own field-loss gate is structurally
blind to it. It was found only because the first defect forced a byte-level look at the file. Any
later phase that uses mutagen to repair tags at scale inherits all three.

**2. `audio_md5` is not tag-invariant, and the entire Phase 1 tag-diff harness joins on it
(DEF-03-03).** `snapshot-music-tags.sh:35` states its key *"hashes the ENCODED AUDIO BITSTREAM
ONLY"*. It does not: ffmpeg's mp3 demuxer emits the trailing 128-byte ID3v1 block as part of the
`-c copy` stream on some files. On a write that touched only `album` and `artist`,
`diff-music-tags.sh` reported **37 files lost** and exited 1 — while `FIELDS_DROPPED` was 0 and
nothing whatsoever had been lost. All 37 movers carry an ID3v1 trailer; **0** of them do not; and
with the last 128 bytes removed each mover's md5 matches its untouched `raw/` twin exactly.

The asymmetry is what makes it dangerous rather than merely noisy: it failed **loud and wrong**
here, but the same property routes a real tag-only corruption on an ID3v1-bearing file into
`MISSING_AFTER`/`NEW_AFTER` rather than into `FIELDS_DROPPED`, which is where Phase 7's QUAL-02 gate
looks. Only **235 of 335** files in this sample carry an ID3v1 trailer, so the behaviour is
per-file: the harness passes and fails on the same tree depending on which files were edited. It
also undermines `03-SAMPLE.md`'s de-duplication proof and plan 03-07's per-`audio_md5` cross-check
whenever a tag write happens between two readings. **Logged, worked around inside this plan, not
fixed** — D-03 freezes that harness and every plan in this wave asserts against its behaviour.

**3. A bind mount pins the directory INODE, not the path — and the failure is a vacuous pass.**
Re-materialising `normalised/` on atlantis left `beets-spike` bound to the deleted inode. Its next
dry run reported *"folders seen: 0, files seen: 0"* and **exited 0**. It was caught here only
because 0 is an obviously wrong answer for a normalisation run — but plans 03-06, 03-07 and 03-10
all measure *rates*, where "0 candidates" is a plausible-looking result that would falsify T1 on an
artefact. Same shape as 03-04's finding that a `config -d` block proves nothing.
**`beets-spike` was force-recreated** and re-verified: 335 mp3 visible, `normalised RW=false`, and
all four plugins loading on `beet … version`. Any later plan that re-materialises a bind-mounted
tree must recreate the containers bound to it.

**4. V2 and V5 are not disjoint in the data, and it changes what plan 03-07 can attribute.** Seven
of the nine sampled V2 folders also carry a V5-shaped album; `spike03-variant-survey.sh` assigns one
stratum per folder and tests V2 first, so their V5-ness is invisible in the census. **V2's measured
lift is therefore the joint effect of rules 2 and 3, not of the artist rule alone**, and 03-07
cannot attribute it to rule 3 without a further arm. Two further folders fire outside their stratum:
`Mastermix_Issue_418_April_2021` is V4-shaped (no `artist` frame at all) but classified V5, and
`VA-Mastermix.Issue.446-202` is two folders wearing one name — ten clean files and ten with a
missing album and `artist="Various"`.

**5. No rule fired on any V1 or V6 folder** — 12 folders, 120 files, untouched. That is the
strongest single line in the dry-run table. Rule 2 firing on a V1 folder would have meant the
canonicalisation was too eager; rule 3 firing on V6 would have meant real per-track artists were
being flattened. Neither happened, and the V1 control file in the `ffprobe` spot check confirms it
independently.

**6. Rule 3 buys folder-level consensus by overwriting three genuinely correct per-track artists.**
`Massive Attack`, `Inner Life Fe. Jocelyn Brown` and `Corrs` become `DMC`, because the other 14
files in those two folders carry `Va`. This is not avoidable within the rule as specified: a folder
holding seven `Va` and one `Massive Attack` has no `consensus["artist"]`, so `va_likely` is true
whatever the modal value is — only writing the **same** value to every file achieves
`va_likely=false`. Stated rather than glossed; if a later phase productionises rule 3, this is the
case needing a per-file exemption.

## Deviations from Plan

### 1. [Rule 1 — Bug] The plan's literal rule-2 wording contradicts its own rule 1

- **Found during:** Task 1, while writing the canonicaliser.
- **Issue:** the plan says *"strip … a leading `Mastermix - ` prefix"*. Applied literally,
  `Mastermix - Issue 410` becomes `Issue 410` — which is **not** the form rule 1 derives
  (`Mastermix Issue NNN`) and is a hopelessly generic Discogs query. The two halves of the sample
  would have carried two different album shapes into the same measurement.
- **Fix:** the **separator** is removed, not the label: `Mastermix - Issue 410` →
  `Mastermix Issue 410`. Rules 1 and 2 now share one canonical target form. Applied to `DMC - ` by
  the same logic that gives rule 1 "or the analogous DMC form". Recorded in `03-NORMALISATION.md`
  § *The three rules* as a stated deviation, not a silent one.
- **Commit:** `637d988`

### 2. [Rule 2 — Missing correctness requirement] `\bVol\.?\s*` eats the `Vol` out of `Volume`

- **Found during:** Task 1.
- **Issue:** the plan lists `Vol.` as noise to strip. The obvious pattern turns a legitimate
  `Volume 5` into `ume 5`.
- **Fix:** `\bVol\.?\s*(?=\d)` — the digit lookahead is load-bearing. Nothing in this sample would
  have tripped it, which is exactly why it is worth writing down.
- **Commit:** `637d988`

### 3. [Rule 1 — Bug] mutagen's ID3v1 regeneration moved `audio_md5` on 37 files

- **Found during:** Task 3, on the first `--apply`. `diff-music-tags.sh` exited **1** with
  `MISSING_AFTER: 37` while `FIELDS_DROPPED` was 0.
- **Issue:** finding 1, row 1 above.
- **Fix:** `preserve_id3v1_trailer()` restores the pre-write block byte-for-byte. That makes "touch
  nothing else" true at the **byte** level rather than at the ID3v2 frame level, and keeps the
  phase's own join key stable for this write. The cost is a stale `album`/`artist` in ID3v1, which
  nothing in this project reads: mutagen ignores ID3v1 on read so beets never sees it, and ffmpeg
  lets ID3v2 win for both fields.
- **The audio was never touched**, and that is proven rather than argued: with the ID3v2 tag and the
  last 128 bytes excluded, `cmp` against the untouched `raw/` twin returns **zero** differing bytes
  on every file examined.
- **Commit:** `030f399`

### 4. [Rule 1 — Bug] `load_v1` and a load-time `v2_version` — two more silent broadenings

- **Found during:** Task 3, chasing the `ID3v1 Comment` field that survived deviation 3's fix.
- **Issue:** finding 1, rows 2 and 3 above. An ID3v2 frame-header dump was decisive: the `raw/` twin
  has **one** COMM frame with padding at offset 183, the written file has **two** with padding at
  225; and a 5-byte `TYER` came back as a 6-byte `TDRC` inside a v2.3 tag.
- **Fix:** `ID3(path, v2_version=<the major version on disk>, load_v1=False)`, with the version read
  from the file's own 10-byte header **before** the tag is loaded.
- **Also fixed the class, not only the two instances:** `assert_frame_set_unchanged()` now re-parses
  the tag off disk without mutagen after every write and fails into the `.failed` ledger if the
  frame-ID multiset moves beyond the frames this script wrote. Fixing only the two known defaults
  would have left the next mutagen release free to do it again undetected.
- **Commit:** `9b94bf2`

### 5. [Rule 3 — Blocking] `beets-spike` was bound to a deleted directory inode

- **Found during:** Task 3, after the first re-materialisation.
- **Issue:** finding 3 above — a dry run that reported 0 folders, 0 files and exit 0.
- **Fix:** `docker compose … up -d --force-recreate beets-spike`, then re-verified: 335 mp3 visible,
  `normalised RW=false`, four plugins loaded. **Out of scope but unavoidable:** every downstream
  plan measures through this container and would have measured an empty tree.
- **Side effect recorded for attribution:** `beets-spike` `.Created` is now `2026-09-03T22:24:53Z`,
  not 03-04's `20:56:46`. Later plans comparing database mtimes against container creation must use
  the new timestamp.
- **Commit:** operational; no repo change.

### 6. [Method] The tree was re-materialised from `raw/` between attempts, and a calibration apply was added

- The plan's Task 3 applies once. Deviations 3 and 4 each required starting again from a provably
  un-normalised tree, which was done on atlantis by the `cp -r --reflink=always
  --preserve=timestamps` + `chown 568:568` route plan 03-03 documented, and verified byte-identical
  to `raw/` each time. **Every number in `03-NORMALISATION.md` comes from one clean invocation of
  the final committed script**, not from a patched-up state.
- A **calibration `--apply` on a single folder**, with a full `ffprobe` field-by-field comparison
  before the bulk write, was added and is not in the plan. It is what caught deviation 3 early. The
  reason it is worth the extra command: the only rollback behind an in-place ID3 write is a snapshot
  of a **2 TB dataset that also carries live downloads** — a rollback nobody would actually take.

### 7. [Scope] `.gitignore` gained `__pycache__/`

This plan introduces Python to a repo that had none, and the file's own verification command
(`python3 -m py_compile`) drops a `__pycache__/` directory beside it. Ignored so a verification run
cannot dirty the tree.

### 8. [Deferred to the orchestrator] Delivery to LXC 100 was out-of-band, and no branch was pushed

Task 1's acceptance criterion asks for the script to be *"committed and pushed to `origin/main`"*,
because `git pull --ff-only` into `/mnt/fast/stacks/scripts` (mounted `:ro` at `/spike-scripts`) is
the delivery path. **A worktree executor cannot push**, and `/mnt/fast/stacks` sits at `c88c268`.
The script was staged to `/mnt/fast/spike-03/out/` — deliberately **outside** the git checkout, so a
later `git pull --ff-only` is not blocked by an untracked file the incoming commit also adds — and
**sha256-verified identical to the committed blob before every run** (`73149e79…` for the final
version, confirmed against `git show HEAD:scripts/normalise-dj-tags.py`). The criterion is
discharged as **committed**; publication is the orchestrator's. Same deviation and same handling as
plans 03-01, 03-03, 03-04 and 03-08.

## Verification that could not be satisfied as written

**`zfs diff tank/media/Music@pre-project` does not return clean, and did not before this plan
started.** It reports **2,674 lines, every one `M`** — zero additions, zero removals, zero renames.
2,674 is the exact entry count of the library and the modification is Phase 1 plan 01-08's `chown`
to `568:568`, which ran *after* `@pre-project` was taken. The verification line as written is
unsatisfiable and always was. Proven not to be this plan's doing by two further readings taken from
atlantis: **0** library entries newer than `2026-09-03 21:40` (when this plan started), and the
newest `ctime` anywhere in the library is **2026-08-18 22:43:54**, sixteen days earlier. Recorded as
*pre-existing and not caused here*, **not** as a pass — identical handling to plan 03-03.

**`tagger-class writers: 0` is silence, not a clean reading, for one tagger.** `check-music-freeze.sh`
exits 0 with all counters at 0, but its `TAGGER_PATTERN` cannot match `sabnzbd`, which runs beets as
a live post-processing path over the same backlog trees this sample was drawn from — **DEF-03-01**,
in the open for the third time in this phase. sabnzbd's `library.blb` was touched at `21:17:20`,
before this plan's first write; the decisive attribution is the mount table, not the clock, and
neither spike container mounts `/mnt/fast/appdata` at any mode.

## Requirements

**TAGR-01 and TAGR-02 are deliberately NOT marked complete.** This plan builds and validates
criterion 1's *normalised arm*; it does not measure a Discogs coverage rate, which is plan 03-07's
job, and it does not establish that the surviving tagger can own the whole tree. Marking them here
would be a false claim on the phase's headline requirements.

## Known Stubs

None. Two intentional not-yet-used states, both required by the design:

- `--artist-policy various` and `--artist-policy keep` are implemented and documented but unused.
  They exist so plan 03-07 can run the counterfactual arm with one flag; every NDJSON record carries
  its `artist_policy`, so a result set cannot be read without knowing which arm produced it.
- The non-MP3 write path (`mutagen.File(path, easy=True)`) is implemented and **untested against
  real files** — the draw contains zero WAV and zero FLAC. Plan 03-09's D-13 bake-off is the first
  thing that will exercise it, and `03-SAMPLE.md` already records that it needs WAV folders named
  separately.

## Threat Flags

No new security surface. Every disposition in the plan's register was exercised:

| Threat | Outcome |
|---|---|
| T-03-23 (tampering with the library or the real backlog) | Held — `SCRATCH_ROOT` prefix check over `os.path.realpath`, tested explicitly against `/mnt/tank/media/Music` and returning **exit 2** naming both paths; `check-music-freeze.sh` exit 0; 0 library entries newer than the plan start |
| T-03-24 (an irreversible write with no rollback) | Held — `--apply` refused **exit 2** with no proof and with an invalid proof, both tested; the real proof was obtained over `ssh:172.16.1.158` and the route is recorded |
| T-03-25 (a dry run that is not dry) | Held on all three layers — dry-run is the default, the run executed where `normalised/` is `RW=false`, and `find -newer` returned 0 lines with **empty** whole-subtree `.meta` and `.sha` manifest diffs on both trees. The five-file spot check was not used |
| T-03-25b (a writable handle outliving its one use) | Held — `beets-spike-rw` was up for **16 seconds** and is **absent** from `docker ps -a` |
| T-03-26 (path-derived metadata written into audio files) | Held — rule 1's folder-derived album is NFC-normalised, path separators and control characters stripped, length bounded, and **re-validated** after the transform rather than trusted; a value with no issue number is rejected outright |
| T-03-27 (loss of `TKEY` / `EnergyLevel` and other fence-protected fields) | Held — `FIELDS_DROPPED = 0` on the audio_md5 join **and** on the path-keyed join; the on-disk frame-ID multiset differs from the untouched twin only by the 40 frames the rules created; the `ffprobe` spot check shows `tkey` and `tbpm` intact on the file that gained an album |
| T-03-28 (an exception silently counted as "no change") | Held — 0 lines in all three `.failed` ledgers, `written: false` on 0 records, and the frame-set assertion adds a second way for a file to fail loudly rather than quietly |
| T-03-29 (LXC 100 host RAM via the system temp directory) | Held — **no `tempfile` import at all**, no scratch path, 0 `/tmp` entries matching `spike`, `/` unchanged at 35 G |
| T-03-30 (tampering with the repo checkout from inside the container) | Held — the script ran from `/mnt/fast/spike-03/out`, outside the checkout, sha256-verified against the committed blob before every run |
| T-03-SC (package installs) | Held — **zero** installs; mutagen 1.48.1 is already in the LSIO beets image as a beets dependency |

One threat-adjacent note that is not a flag: `/mnt/fast/spike-03/out` grew to **6.1 M** across 132
manifest files on LXC 100's ext4 **root** — the 03-03 finding-4 constraint, watched rather than
assumed. `/` is unchanged at 35 G free. Plan 03-11's teardown must remove it.

## Self-Check: PASSED

- `scripts/normalise-dj-tags.py` — FOUND
- `.planning/phases/03-tagger-spike/03-NORMALISATION.md` — FOUND (608 lines, contains `FIELDS_DROPPED`)
- `.planning/phases/03-tagger-spike/deferred-items.md` — FOUND (modified; DEF-03-03 added)
- Commit `637d988` (`feat(03-05)`) — FOUND
- Commit `0e2dfdb` (`docs(03-05)`) — FOUND
- Commit `030f399` (`fix(03-05)`) — FOUND
- Commit `9b94bf2` (`fix(03-05)`) — FOUND
- Commit `e395c4e` (`docs(03-05)`) — FOUND
- Committed script sha256 == the sha256 of the file every recorded run executed (`73149e79…`) — VERIFIED
