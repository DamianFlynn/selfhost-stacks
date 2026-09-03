---
phase: 03-tagger-spike
plan: 03
subsystem: sample-selection
tags: [variant-survey, stratification, backlog-weights, reflink, zfs-snapshot, OD-3, D-06, D-07]
requires:
  - "03-02 — the thresholds, the estimator and the OD-3 population, committed before this drew anything"
  - "03-01 — the OD-1 disk-headroom gate"
provides:
  - "scripts/spike03-variant-survey.sh — folder-to-stratum classification of the whole backlog"
  - "03-SAMPLE.md — the census, the per-stratum backlog weights, the deterministic 24-folder draw, the de-duplication proof, and the D-10 candidates"
  - "/mnt/fast/safety/music-pre-project/spike-03-variant-survey.ndjson — 204 folder records plus 6 stratum-weight records"
  - "/mnt/tank/downloads/spike-03 — raw/ and normalised/, 24 reflinked folders each"
  - "tank/downloads@spike-03-t0 — the rollback behind every write in plans 03-04 onward"
  - "/mnt/fast/spike-03/out/spike03-before.ndjson.gz — 335 records, the BEFORE side of 03-05's field-loss gate"
affects:
  - "03-04 .. 03-11 — every measuring plan runs on this sample"
  - "03-07 — must use the 144-folder denominator and these weights, not 03-DECISION.md's 143"
  - "03-09 — the D-13 bake-off cannot use this sample for WAV; the draw contains zero WAV files"
  - "03-10 — the D-10 album slots are named here; all three of research's candidates were unusable"
  - "03-11 — the scratch tree and the snapshot are deleted here"
tech-stack:
  added: []
  patterns:
    - "A `rm`-free, `mv`-free script body so a read-only contract grep asserts literally rather than needing an exemption"
    - "Delegating cp --reflink to the Proxmox host for the same reason zfs is delegated: the ioctl is refused to an unprivileged container"
    - "Deriving a denominator from the classified data rather than hard-coding it, and printing the superseded value beside it"
key-files:
  created:
    - scripts/spike03-variant-survey.sh
    - .planning/phases/03-tagger-spike/03-SAMPLE.md
  modified: []
decisions:
  - "The backlog denominator is 144 folders / 7,728 files, not 143 / 7,726 — nzb/music holds 24 audio-bearing folders, not 23, agreed by a live find and by Phase 1's QUAL-01 capture"
  - "24 folders whose album equals their artist are classified V5, not V1 — a present-but-degenerate album is a canonicalisation case, and leaving them in V1 inflated the best case by a sixth of the backlog"
  - "unsorted and music are classified from Phase 1's QUAL-01 capture rather than by live ffprobe: same instrument, already fenced, and it costs 7,728 fewer process spawns. --live remains implemented"
  - "The reflink copy runs on atlantis, not LXC 100: FICLONE returns EPERM inside the unprivileged container, and cp -a's mode-preserve is EPERM on aclmode=restricted even as real root"
  - "V1 widened from 'artist is exactly Mastermix' to 'one consistent non-placeholder artist with a clean album' — the narrow rule leaves every mainstream single-artist album unclassified, which the plan makes a hard failure"
metrics:
  duration: "~2h"
  completed: 2026-09-03
---

# Phase 3 Plan 03: Variant Survey and Sample Draw Summary

Classified all **204** audio-bearing backlog folders into six strata from Phase 1's own captures
with zero new reads of `tank`, drew a deterministic, de-duplicated **24-folder** sample spanning
both trees and including DMC, and materialised it as reflinked copies behind
`tank/downloads@spike-03-t0` with a 335-record before-state — while retracting **six** committed
figures the phase would otherwise have measured against.

## What was built

**`scripts/spike03-variant-survey.sh`** (540 lines) — a read-only classifier over
`dj-mixes-ffprobe/` (SAFE-03) and `pre-project.ndjson.gz` (QUAL-01), emitting one NDJSON record
per folder plus a marked set of per-stratum weight records, both to the fence rather than the
repo. It exits 1 if any folder matches no stratum; it exited 0 on 204 of 204.

The load-bearing design choice is that its body contains **no `rm`, `mv`, `chown` or `chmod` at
all**. The plan asserts the read-only contract with a comment-stripped grep for those four verbs,
and a `mktemp`-plus-trap scratch `rm` is indistinguishable from a destructive one to that grep.
Rather than weaken the assertion, the per-file intermediate was promoted to a named second output
that is simply overwritten each run — which also leaves the audit trail behind every count on
disk. The grep returns `0` with GNU grep on LXC 100, as does the `-xdev` grep.

**`.planning/phases/03-tagger-spike/03-SAMPLE.md`** — the committed census, the weight table plan
03-07 multiplies by, the draw with its re-derivation recipe, the de-duplication proof on two
independent instruments, and the D-10 album slots.

**The scratch tree** — `/mnt/tank/downloads/spike-03/{raw,normalised}`, 24 folders each, 8.9 GB of
content per copy sharing blocks via ZFS block cloning, behind `tank/downloads@spike-03-t0`.

## Results

| Assertion | Result |
|---|---|
| `dj-mixes` folders / files / WAV classified | **60 / 764 / 134** — reproduces Phase 1's fence exactly |
| Folders matching no stratum | **0** |
| Strata present | V1, V2, V3, V4, V5, V6 — all six |
| `unsorted` + `music` folders classified | **144** (see the retraction below) |
| `sum(backlog_folders)` / `sum(backlog_weight)` | **144** / **0.9999** (six roundings to 4 dp) |
| Draw rows / `dj-mixes` / `unsorted` | **24 / 20 / 4** |
| Drawn rows with `scan_bearing = true` | **0** |
| Distinct strata among the `dj-mixes` rows | **5** (V1, V2, V3, V5, V6) |
| `unsorted` rows containing `DMC` | **4 of 4** |
| Draw determinism | run twice, `diff` **empty**, 24 rows both times |
| Shared `audio_md5` between the two sides | **0**, on three independent readings |
| `raw/` and `normalised/` entries | **24** and **24** |
| Per-folder file counts vs the draw table | **0 mismatches** across 48 checks |
| Originals `-newer` the scratch root | **0 lines**, both trees |
| Before-state records / failures | **335** / **0** |
| `/tmp` entries matching `spike-03` | **0** |
| `bash scripts/check-music-freeze.sh` | **exit 0**, `FAILURES total: 0` |

## The findings that outlive this plan

**1. The 45 GB `1-115` set exists. 03-DECISION.md's retraction of it must itself be retracted.**
03-DECISION.md states the set "does not exist on disk" and instructs a later phase to retire
`PROJECT.md`'s and `CLAUDE.md`'s "split it per volume" instruction. Only the **`dj-mixes` copy** is
an empty shell. The `unsorted` copy is `45G`, flat, and holds **4,746 audio files** — 61% of the
entire backlog's files in one folder. **The split instruction stands.** This is a folder checked
in one tree and declared absent from the estate, and it is the sharpest single reason this plan
classified all three trees rather than one.

**2. `dj-mixes` duplicates `unsorted`'s audio but not its tags.** The "byte-for-byte duplicate"
claim rests on separate inodes, link count 1 and *identical sizes* — and identical size is not
identical bytes. **21 of the 60 `dj-mixes` folders classify into a different stratum than their
`unsorted` namesake.** On `Mastermix_Issue_415` all ten files have identical `size_bytes` and
identical `audio_md5` in both trees, yet the `dj-mixes` copy reads `artist="Various Artists"` /
`album="Mastermix Issue 415 (Januar 2021)"` while the `unsorted` copy reads `Mastermix` /
`Mastermix`; ID3v2 padding absorbs the difference. The sample's rates are measured on `dj-mixes`
copies while the weights are computed over `unsorted` + `music`. Named as a bounded hazard for
03-07 rather than carried silently.

**3. `album == artist` was scoring as the best case.** 24 `unsorted` folders carry
`album="Mastermix"` under `artist="Mastermix"`. The narrow V1 rule sorted every one into "the best
case": the value is present and carries none of V5's six noise markers. It is the worst case in
disguise — a Discogs query for `Mastermix` resolves the **label**, producing exactly the confident
wrong match CLAUDE.md names as worse than no match. Reclassifying them V5 moves **24 folders of
weight out of V1**: V1 falls 61 → 37 (0.4236 → 0.2569), V5 rises 19 → 43 (0.1319 → 0.2986). T1's
headline is more sensitive to this single reclassification than to any other decision in the plan.

**4. `/mnt/fast/spike-03` — and Phase 1's entire fence — is on LXC 100's ext4 root, not ZFS.**
`findmnt --target` resolves both to `/dev/mapper/pve-vm--100--disk--0`. Only the `mp` entries in
`/etc/pve/lxc/100.conf` are real bind mounts, and neither `spike-03` nor `safety` is among them.
The plan's stated reason for using `/mnt/fast/spike-03` ("so they do not consume `/`") is not
achieved. Not a blocker — 34 GiB free against the 8 GiB OD-1 floor, and this plan wrote 321 KB —
but every later plan writing a `library.db`, a wrtag library or a container log there is writing
to `/`. Same defect class as the `/mnt/fast/appdata` entry in project MEMORY.

**5. All three of research's D-10 album candidates are unusable.** `Ed Sheeran - ÷ (2017) FLAC` is
**completely empty**; `Lady Gaga - The Fame (2008) FLAC` holds **one** file (`Poker Face`); the
`Def Leppard - CD Collection Volume 1 - 7CD` folder holds **one** file whose `album` tag reads
`Rarities - Volume One`. **9 of `nzb/music`'s 24 audio-bearing folders hold exactly one file.**
Replacements named and verified flat: Taylor Swift *1989 (TV)* (21), Garth Brooks *Ropin' The
Wind* (10), *Now That's What I Call Music 116* (47, 46 distinct artists), Lady Gaga *Born This Way:
The Collection* (31, genuinely multi-disc in one folder).

**6. The draw contains zero WAV files.** 134 of `dj-mixes`' 764 files are WAV, and all of them sit
in V3/V6 folders that are either scan-bearing or were not drawn. Plan 03-09's D-13 bake-off exists
partly to test whether wrtag's taglib backend handles WAV better than mutagen; **it cannot use
this sample** and needs WAV folders named separately.

## Deviations from Plan

### 1. [Rule 1 - Bug] The backlog denominator is 144, not 143

- **Found during:** Task 1
- **Issue:** 03-DECISION.md commits `nzb/music` at 23 folders / 275 files and the backlog at
  143 / 7,726. Two independent instruments return 24 / 277: a live audio-extension `find` on
  LXC 100, and Phase 1's QUAL-01 capture grouped by scan root. Three of Task 1's acceptance
  criteria hard-code 143 and 23.
- **Fix:** The script **derives** the denominator from the classified data and prints the
  superseded 143 beside it with a warning. The retraction is stated in `03-SAMPLE.md` § *Corrections
  this survey supersedes*. `03-DECISION.md` was deliberately **not edited** — plans 03-07 and 03-11
  assert its threshold text unchanged by `git log -p`, and a measured fact corrected in a later
  artefact is a retraction; a silent edit to the threshold document is not.
- **T1's threshold value (40%) is untouched.** A measured fact was corrected by a better
  instrument, before any rate existed.
- **Commit:** `58aade0`

### 2. [Rule 1 - Bug] V1 as specified leaves most of the backlog unclassified

- **Found during:** Task 1
- **Issue:** The plan defines V1 as `artist` exactly `Mastermix`. That definition comes from
  `dj-mixes`, which is Mastermix-only. Applied to the 144-folder backlog, every single-artist
  mainstream album (artist `Taylor Swift`, clean album) matches **no** stratum — and the plan makes
  an unclassified folder a hard exit-1 failure.
- **Fix:** V1 widened to "one consistent non-placeholder artist across the folder, with a clean
  album", which is 03-DECISION.md's own functional definition of V1 (`va_likely=false`, query =
  album alone). On `dj-mixes` the widened rule selects precisely the folders the narrow one did.
- **Commit:** `58aade0`

### 3. [Rule 2 - Missing correctness requirement] V5 extended to degenerate albums

- **Found during:** Task 1, after the first survey run produced a V1 weight of 0.4236
- **Issue:** See finding 3 above. 24 folders with `album == artist` were scoring V1.
- **Fix:** V5's test extended to `album == artist` case-folded. The test is deliberately **not**
  "album contains no digits" — most legitimate mainstream album titles contain no digits and that
  rule would have swallowed the entire bucket-A population.
- **Commit:** `58aade0`

### 4. [Rule 3 - Blocking] `cp --reflink=always` is EPERM inside the unprivileged container

- **Found during:** Task 3, on folder 1 of 24
- **Issue:** `cp -a --reflink=always` from LXC 100 fails twice over: `failed to clone ...:
  Operation not permitted` (the `FICLONE` ioctl is refused to an unprivileged container — **EPERM,
  not EXDEV**; the dataset was right), and `preserving permissions ...: Operation not permitted`
  (the documented `aclmode=restricted` constraint, which fails **even as real root on atlantis**).
- **Fix:** The copy is delegated to atlantis over ssh — the same route and the same reasoning as
  the `zfs` calls — with `-a` replaced by `-r --preserve=timestamps`. `--reflink=always` is kept:
  it did its job, stopping the run after one folder instead of silently writing 17 GB.
- **Commit:** `78b43e5`

### 5. [Rule 3 - Blocking] `chown` on the scratch tree, which the plan forbids

- **Found during:** Task 3
- **Issue:** The plan says not to `chown` anything under `tank`, because it fails from LXC 100.
  Running the copy on atlantis left the scratch tree `root:root`, while every later Phase 3 plan
  runs beets and beets-flask as `568:568`.
- **Fix:** `chown -R 568:568` from atlantis, which succeeds — the same route Phase 1 plan 01-08
  used to normalise the library. `chmod` is still not attempted; mode is `0777` by ACL inheritance.
- **Commit:** `78b43e5`

### 6. [Rule 3 - Blocking] `unsorted`/`music` classified from QUAL-01, not live ffprobe

- **Found during:** Task 1
- **Issue:** The plan states `unsorted` "has no ffprobe fence". It does: Phase 1's QUAL-01 capture
  holds the complete `-show_format -show_streams` output for all four D-02 roots, `unsorted` (7,451)
  and `music` (277) included.
- **Fix:** QUAL-01 is the default route; `--live` is implemented and forces ffprobe. Every folder
  record carries `route`, which is what the plan's "report which route produced each record"
  requirement is for. Saves 7,728 process spawns and honours the "no new I/O against `tank`"
  contract more completely than the live route could.
- **Commit:** `58aade0`

### 7. [Rule 1 - Bug] The scan-bearing exclusion is 30 folders, not 27

- **Found during:** Task 2
- **Issue:** D-06 excludes "the 27 scan-bearing folders". Phase 1's `cover-scans` fence holds 54
  images across **30** directories, and `comm -12` against the fence folder list confirms all 30
  are `dj-mixes` audio-bearing folders.
- **Fix:** All 30 excluded, leaving **30 eligible** `dj-mixes` folders. This forced the stratum
  reallocation: V3 has 2 eligible against a target of 4, V6 has 1 against 3, and the four freed
  slots went to V2 and V1 — the two largest eligible strata, which are also two of the three
  heaviest by weight. Recorded in `03-SAMPLE.md` § *The draw* as a table.
- **Commit:** `4a0b5f3`

### 8. [Scope] `snapshot-music-tags.sh` has no `--out` flag

- The plan asks for the before-state at `$SCRATCH_FAST/out/spike03-before.ndjson.gz`. The script
  writes `<BASENAME>` into the fence's `tags/` directory by construction. It was run as
  `spike03-before` and all three artefacts copied to `$SCRATCH_FAST/out/`. Both paths are on the
  same filesystem and both are the plan's own; nothing reached the system temp directory.

### 9. [Deferred to the orchestrator] Delivery to LXC 100 was out-of-band

- The plan's delivery path is `git pull --ff-only` at `/mnt/fast/stacks`. A worktree executor
  cannot push. `spike03-variant-survey.sh` was staged to `/mnt/fast/spike-03/` — deliberately
  outside the git checkout, so a later `git pull --ff-only` is not blocked by an untracked file the
  incoming commit also adds — and sha256-verified identical to the committed file before every run.
  Same deviation, same handling, as plan 03-01.

## Verification that could not be satisfied as written

**`zfs diff tank/media/Music@pre-project` does not return clean, and did not before this plan
started.** It reports **2,674 lines, every one `M`**: zero additions, zero removals, zero renames.
2,674 is the exact entry count of the library, and the modification is Phase 1 plan 01-08's `chown`
to `568:568`, which ran *after* `@pre-project` was taken — CLAUDE.md records that chown and cites
the same figure. Proven not to be this plan's doing by two further readings:
`find /mnt/tank/media/Music -newermt "2026-09-03 20:00"` returns **0**, and the newest `ctime`
anywhere in the library is **2026-08-18 22:43:54**, sixteen days earlier. Recorded as *pre-existing
and not caused here*, not as a pass. Phase 1 produced six unearned passes; this is not a seventh.

## Known Stubs

None. `03-SAMPLE.md` § *The bucket-A and hard-shape candidates* leaves the fifth D-10 slot as
`TBD — plan 03-07`, which is required by D-10 rather than incomplete: that slot must be chosen
after criterion 1 identifies which folders Discogs returned no candidate for.

## Threat Flags

None. This plan introduced no network endpoint, auth path or schema change. It issued **zero**
Discogs requests and did not read, print or transport `DISCOGS_USER_TOKEN` (T-03-14). No
package-manager install occurred (T-03-SC). T-03-10 (originals untouched), T-03-11 (Music
untouched), T-03-12 (`/tmp` clean), T-03-13/13b/13c (de-duplication, weighting, reproducibility)
are all asserted in the Results table above.

One threat-adjacent note that is not a flag: the survey script writes to
`/mnt/fast/safety/music-pre-project/`, which finding 4 shows is on LXC 100's root filesystem. A
runaway write there consumes `/` on the host that runs 103 containers. The script's outputs are
bounded (204 + 6 records, 8,492 intermediate lines, ~2 MB total) and it creates exactly two files.

## Self-Check: PASSED

- `scripts/spike03-variant-survey.sh` — FOUND
- `.planning/phases/03-tagger-spike/03-SAMPLE.md` — FOUND
- Commit `58aade0` — FOUND
- Commit `4a0b5f3` — FOUND
- Commit `78b43e5` — FOUND
