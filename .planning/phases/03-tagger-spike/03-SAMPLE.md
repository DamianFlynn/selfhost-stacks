# Phase 3 variant survey and sample draw

Companion to [`03-DECISION.md`](03-DECISION.md) (the pre-committed thresholds and the estimator
this document supplies the weights for) and to
[`stacks/selfhosted/arrs/beets.md`](../../../stacks/selfhosted/arrs/beets.md) (the Phase 1 durable
record whose census style this follows).

Nothing here is applied by `docker compose`. This is the record of which folders this phase
measures on, why those and not others, and which previously-committed figures it retracts.

State as of 2026-09-03 - **sample drawn, scratch tree materialised, no Discogs request issued.**

> **The population is the 60 audio-bearing `dj-mixes` folders union the DMC folders in
> `unsorted`, widened per [OD-3](03-DECISION.md) before any evidence was collected.** OD-3 was
> committed in plan 03-02 (commit `137b6d9e92cb44d9c6a48b3963bb33fe0194622f`), which this plan
> depends on and which ran to completion before a single folder here was classified. The widening
> exists because `dj-mixes` contains **no DMC content at all** while ROADMAP criterion 4 names DMC
> explicitly, and every DMC folder lives in `unsorted`.

Instruments used throughout, both read-only and both from Phase 1's fence:

| Instrument | What it is | Used for |
|---|---|---|
| `dj-mixes-ffprobe/` (SAFE-03) | one raw ffprobe JSON per audio file, 764 files across 60 folders | the `dj-mixes` half of the classification |
| `tags/pre-project.ndjson.gz` (QUAL-01) | 9,736 records, complete ffprobe output, `audio_md5`-keyed | the `unsorted` + `music` half, and the de-duplication join |
| `cover-scans/` | 54 images across 30 folders | the scan-bearing exclusion |
| live `ffmpeg -map 0:a -c copy -f md5` | a fresh read of the encoded bitstream | the second, independent de-duplication reading |

Produced by [`scripts/spike03-variant-survey.sh`](../../../scripts/spike03-variant-survey.sh),
whose machine-readable output stays at the fence
(`/mnt/fast/safety/music-pre-project/spike-03-variant-survey.ndjson`) rather than in this repo -
this repository has zero committed non-Markdown data artefacts and that convention is kept.

---

## The census

204 audio-bearing folders across all three backlog trees, 8,492 audio files, every one classified
into exactly one stratum. The survey exits 1 if any folder matches none; it exited 0.

| Stratum | Folders | Files | WAV | Scan-bearing | Backlog folders | Backlog files |
|---|---|---|---|---|---|---|
| V1 | 51 | 534 | 0 | 15 | 37 | 402 |
| V2 | 69 | 725 | 0 | 22 | 39 | 427 |
| V3 | 17 | 242 | 94 | 7 | 11 | 125 |
| V4 | 1 | 10 | 0 | 0 | **0** | 0 |
| V5 | 48 | 1,116 | 0 | 10 | 43 | 1,066 |
| V6 | 18 | 5,865 | 174 | 6 | 14 | 5,708 |
| **Total** | **204** | **8,492** | **268** | **60** | **144** | **7,728** |

Format histogram across all three trees: `mp3` 8,075, `wav` 268, `flac` 147, `wv` 2.

And the `dj-mixes` tree alone, which is where 20 of the 24 sampled folders come from:

| Stratum | Folders | Files | WAV | Scan-bearing | **Eligible for the draw** |
|---|---|---|---|---|---|
| V1 | 14 | 132 | 0 | 4 | 10 |
| V2 | 30 | 298 | 0 | 19 | 11 |
| V3 | 6 | 117 | 47 | 4 | 2 |
| V4 | 1 | 10 | 0 | 0 | 1 |
| V5 | 5 | 50 | 0 | 0 | 5 |
| V6 | 4 | 157 | 87 | 3 | 1 |
| **Total** | **60** | **764** | **134** | **30** | **30** |

60 folders and 764 files reproduce Phase 1's fence exactly. 134 WAV reproduces
`beets.md`'s corrected figure exactly.

---

## Corrections this survey supersedes

Stated as retractions, not quiet replacements, in the `beets.md:55-58` house style. Each was
measured by two independent instruments before being written down.

**60 audio-bearing folders, not 84.** Of `dj-mixes`' 84 entries, **24 contain zero files**. The
84 figure counted empty shells. Retire "84 dj-mixes folders" wherever it appears. *(This one
holds - it was already corrected in 03-DECISION.md and this survey confirms it.)*

**The 45 GB `1-115` set EXISTS. Retract the retraction.** 03-DECISION.md § *Denominators* states
that `VA-Now_That.s_What_I_Call_Music__1-115_2023` is one of the 24 empty shells and that *"the
'45 GB `1-115` set' that `PROJECT.md` and `CLAUDE.md` instruct a later phase to split per volume
does not exist on disk"*, and instructs a later phase to retire that instruction. **That is wrong,
and it is wrong in the dangerous direction.** Only the `dj-mixes` copy is an empty shell. The
`unsorted` copy is `45G`, flat, and holds **4,746 audio files** - measured by `du -sh` and by a
`find` audio-extension count, and present in QUAL-01. **`PROJECT.md`'s and `CLAUDE.md`'s
instruction to split it per volume before pointing beets at anything stands and must not be
retired.** The failure mode this catches is exact: a folder checked in one tree and declared
absent from the estate.

**The backlog denominator is 144 folders (7,728 files), not 143 (7,726).** 03-DECISION.md commits
`nzb/music` at **23** folders / **275** files. Two independent instruments return **24** and
**277**: a live audio-extension `find` on LXC 100, and Phase 1's own QUAL-01 capture grouped by
scan root. The corrected split is `unsorted` 120 folders / 7,451 files + `music` 24 / 277 = **144
folders / 7,728 files**. **T1's threshold value - 40% - is unaffected.** A measured fact is being
corrected by a better instrument, before any rate exists; the goalposts have not moved. Plans
03-07 and 03-11 must use 144.

**`dj-mixes` duplicates `unsorted`'s AUDIO but not its TAGS.** 03-DECISION.md and 03-RESEARCH.md
call `dj-mixes` a *"byte-for-byte duplicate copy of a subset of `unsorted`"*, on evidence of
separate inodes, link count 1 and **identical sizes**. Identical size is not identical bytes. All
60 `dj-mixes` folders have an `unsorted` namesake, and **21 of the 60 classify into a different
stratum in the two trees** - in every one of the 21 the `unsorted` copy reads V1 and the
`dj-mixes` copy reads V2/V3/V4/V5. Worked example, `Mastermix_Issue_415`, where the two copies
have **identical `size_bytes` and identical `audio_md5` on all ten files**:

| Copy | `artist` | `album` | Stratum |
|---|---|---|---|
| `dj-mixes` | `Various Artists` (10/10) | `Mastermix Issue 415 (Januar 2021)` | V2 |
| `unsorted` | `Mastermix` (9/10) | `Mastermix` (9/10) | V5 |

ID3v2 padding absorbs the difference, which is why the sizes match. **The audio is the duplicate;
the tag state is not.** This matters directly to the estimator: the sample's per-stratum rates are
measured on `dj-mixes` copies, and the weights are computed over `unsorted` + `music`. Named here
as a bounded hazard for plan 03-07, not silently carried.

**The scan-bearing exclusion is 30 folders, not 27.** Phase 1's `cover-scans` fence holds 54
images across **30** directories, and all 30 are `dj-mixes` audio-bearing folders (`comm -12`
against the fence folder list returns 30 of 30). D-06 says 27. Excluding 30 of 60 leaves the draw
**30 eligible `dj-mixes` folders**, which is what forced the reallocation recorded under
*The draw* below.

**There is no `artist`/`album` swap.** Confirmed, not superseded: `album` carries a correct-ish
issue string in **657** of 764 `dj-mixes` files while `artist` is a placeholder (`Mastermix` 197,
`VA` 160, `Various Artists` 138, missing 77, `Various` 20), and **107** files have no `album` at
all. D-08's constraint holds; only its worked example was wrong, exactly as OD-4 records.

**A seventh correction, made by this survey rather than to it: `album == artist` is not the good
case.** 24 `unsorted` folders carry `album` equal to `artist` - literally `album="Mastermix"`
under `artist="Mastermix"`. The V1 rule as written in 03-03-PLAN.md ("`album` is a clean issue
string") does not say what to do with a value that is present, carries none of V5's six noise
markers, and identifies no release. Left in V1 they inflate "the best case" by one sixth of the
whole backlog. A Discogs query for `Mastermix` resolves the **label**, not the release - a
confident wrong match, which CLAUDE.md § *Autotagging ceiling* names as worse than no match. They
are classified **V5**, because V5's remedy (canonicalise the album, D-08/OD-4 rule 1: derive
`Mastermix Issue NNN` from the folder name) is exactly what they need. The effect is large and is
stated so it can be argued with: **V1 drops from 61 backlog folders to 37, V5 rises from 19 to
43.** The test is `album == artist` case-folded, deliberately **not** "album contains no digits" -
most legitimate mainstream album titles contain no digits and that rule would have swallowed the
entire bucket-A population.

---

## Stratum prevalence across the 144-folder backlog

The weights plan 03-07 multiplies its per-stratum strict rates by, per
[03-DECISION.md § *The estimator T1 is tested against*](03-DECISION.md), whose method was committed
in `137b6d9e92cb44d9c6a48b3963bb33fe0194622f` **before any of these numbers existed**. The sample
is stratified and deliberately never random, so its unweighted average is skewed by construction
and is not a population estimate; these weights are what turn it into one.

| Stratum | `backlog_folders` | `backlog_weight` | `sampled_folders` | `estimable` |
|---|---|---|---|---|
| V1 | 37 | 0.2569 | 6 | yes |
| V2 | 39 | 0.2708 | 9 | yes |
| V3 | 11 | 0.0764 | 2 | yes |
| V4 | **0** | **0.0000** | 0 | n/a - zero weight, contributes nothing |
| V5 | 43 | 0.2986 | 6 | yes |
| V6 | 14 | 0.0972 | 1 | yes, but see the hazard below |
| **Sum** | **144** | **0.9999** | **24** | |

`sum(backlog_folders)` is exactly **144**, the denominator. `sum(backlog_weight)` is **0.9999**;
the 0.0001 shortfall is six independent roundings to four decimal places (max error
6 x 0.00005 = 0.0003) and is within tolerance. The exact fractions are 37/144, 39/144, 11/144,
0/144, 43/144, 14/144.

**`dj-mixes` is excluded from the weight denominator.** It duplicates `unsorted`'s audio
byte-for-byte and counting it would double-weight the same recordings. It is surveyed - it is
where 20 of the 24 sampled folders come from - but it contributes 0 to `backlog_folders`.

**No stratum is a hole.** A hole would be a stratum with `backlog_weight > 0` and
`sampled_folders == 0`, which plan 03-07 would then have to bound rather than silently drop.
There is none: every weighted stratum has at least one sampled folder. **V4 is the only unsampled
stratum and its weight is exactly 0.0000** - it exists once, in `dj-mixes`, and nowhere in the
deduplicated backlog, so it cannot contribute to the roll-up whatever its rate turns out to be.

**Two precision hazards, named rather than buried:**

1. **V6 rests on one sampled folder** (`VA-Mastermix.Crate.068-070-2025`, 60 files). Its rate is
   therefore 0% or 100% with nothing in between, against a weight of 0.0972. Only **one** V6
   `dj-mixes` folder is non-scan-bearing, so this is a floor imposed by the population, not a
   choice. Plan 03-07 should report V6's contribution as a bound, not a point estimate.
2. **One V6 folder holds 61% of the backlog's files.**
   `VA-Now_That.s_What_I_Call_Music__1-115_2023` is 4,746 of the backlog's 7,728 audio files but
   1 of its 144 folders - 0.69% of the weight. The estimator is folder-weighted **by design**,
   because Discogs requests scale with folders (03-DECISION.md § *Denominators*), and this is the
   sharpest illustration of why the per-`audio_md5` cross-check exists beside it. Report both.

---

## The draw

**Sort key, stated so the 24 folders can be re-derived without re-running anything:** within each
stratum, the eligible folders are sorted by their **full folder path**, byte-ordered with
**`LC_ALL=C`** (locale-independent - a locale-dependent collation is not reproducible across
hosts), and the first N are taken. The documented tie-breaker, unused here because no two full
paths collided, is the `audio_md5` of the folder's first `LC_ALL=C`-sorted file.

Verbatim, against the survey NDJSON:

```bash
O=/mnt/fast/safety/music-pre-project/spike-03-variant-survey.ndjson
NZB=/mnt/tank/downloads/complete/nzb

elig() {
  jq -sr --arg nzb "$NZB" '
    .[] | select(.record_type=="folder") | select(.scan_bearing | not)
    | [ ($nzb + "/" + .tree + "/" + .folder), .tree, .stratum ] | @tsv' "$O"
}

for pair in V1:6 V2:7 V3:2 V5:4 V6:1; do
  s="${pair%%:*}"; n="${pair##*:}"
  elig | awk -F'\t' -v s="$s" '$2=="dj-mixes" && $3==s {print}' \
       | LC_ALL=C sort -t$'\t' -k1,1 | head -n "$n"
done

elig | awk -F'\t' '$2=="unsorted" && $1 ~ /DMC/ {print}' \
     | LC_ALL=C sort -t$'\t' -k1,1 | head -n 4
```

Run twice and `diff`'d: **identical, zero lines of difference**, 24 rows both times.

**Per-stratum targets, and the reallocation.** D-06 suggests V1x4, V2x5, V3x4, V5x4, V6x3 = 20
from `dj-mixes`. Two strata cannot fill their target from the 30 eligible folders: **V3 has 2
eligible against a target of 4**, and **V6 has 1 against a target of 3**. The four freed slots go
to the two largest eligible strata, **V2 (11 eligible) and V1 (10)**, two each - which are also
the two heaviest by backlog weight after V5, so the reallocation buys precision where the
estimator is most sensitive rather than where folders happen to be plentiful.

| Stratum | D-06 target | Eligible | Drawn | Reason for the difference |
|---|---|---|---|---|
| V1 | 4 | 10 | **6** | +2 reallocated from V3 and V6 |
| V2 | 5 | 11 | **7** | +2 reallocated from V3 and V6 |
| V3 | 4 | 2 | **2** | only 2 non-scan-bearing V3 folders exist in `dj-mixes` |
| V4 | - | 1 | **0** | not in D-06's allocation, and its backlog weight is 0.0000 |
| V5 | 4 | 5 | **4** | target met |
| V6 | 3 | 1 | **1** | only 1 non-scan-bearing V6 folder exists in `dj-mixes` |
| DMC (`unsorted`) | 4 | 13 | **4** | OD-3; first 4 by the same key |

The 24 drawn folders, 20 `dj-mixes` + 4 `unsorted`, every one `scan_bearing = false`:

| # | Folder | Tree | Stratum | `n_files` | `fmt_histogram` | `has_album_count` | `has_artist_count` | `scan_bearing` |
|---|---|---|---|---|---|---|---|---|
| 1 | `Mastermix.Issue.420.2021` | dj-mixes | V1 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 2 | `Mastermix_Issue_404` | dj-mixes | V1 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 3 | `Mastermix_Issue_412` | dj-mixes | V1 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 4 | `VA-Mastermix.Issue.426-2021` | dj-mixes | V1 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 5 | `VA-Mastermix.Issue.426-2021.1` | dj-mixes | V1 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 6 | `VA-Mastermix.Issue.427.2CD-2021` | dj-mixes | V1 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 7 | `Mastermix.Issue.421.2021` | dj-mixes | V2 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 8 | `Mastermix_Issue_413` | dj-mixes | V2 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 9 | `Mastermix_Issue_415` | dj-mixes | V2 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 10 | `VA-Mastermix-Issue.457-WEB-2024-MST` | dj-mixes | V2 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 11 | `VA-Mastermix-Issue.458-WEB-2024-MST` | dj-mixes | V2 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 12 | `VA-Mastermix-Issue.459-WEB-2024-MST` | dj-mixes | V2 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 13 | `VA-Mastermix-Issue.461-WEB-2024-MST` | dj-mixes | V2 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 14 | `VA-Mastermix.Crate.071.Afro.House-2025` | dj-mixes | V3 | 20 | `{"mp3":20}` | **0** | 20 | false |
| 15 | `VA-Mastermix.Issue.446-202` | dj-mixes | V3 | 20 | `{"mp3":20}` | 10 | 20 | false |
| 16 | `Mastermix_Issue_410` | dj-mixes | V5 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 17 | `Mastermix_Issue_410.1` | dj-mixes | V5 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 18 | `Mastermix_Issue_418_April_2021` | dj-mixes | V5 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 19 | `VA-Mastermix-Issue.Vol.451-202` | dj-mixes | V5 | 10 | `{"mp3":10}` | 10 | 10 | false |
| 20 | `VA-Mastermix.Crate.068-070-2025` | dj-mixes | V6 | 60 | `{"mp3":60}` | 60 | 60 | false |
| 21 | `VA-DMC-Commercial.Collection.498-WEB-2024-MST` | unsorted | V2 | 9 | `{"mp3":9}` | 9 | 9 | false |
| 22 | `VA-DMC-Commercial.Collection.499-WEB-2024-MST` | unsorted | V2 | 8 | `{"mp3":8}` | 8 | 8 | false |
| 23 | `VA-DMC-Essential.Hits.233-WEB-2024-MST` | unsorted | V5 | 24 | `{"mp3":24}` | 24 | 24 | false |
| 24 | `VA-DMC-Essential.Hits.234-WEB-2024-MST` | unsorted | V5 | 24 | `{"mp3":24}` | 24 | 24 | false |

**335 audio files across 24 folders** - 270 in the `dj-mixes` twenty, 65 in the DMC four. Every
file is MP3; **the draw contains zero WAV**, which is a limitation to state rather than a
convenience: 134 of `dj-mixes`' 764 files are WAV and all of them sit in V3 and V6 folders that
are either scan-bearing or were not drawn. Plan 03-09's D-13 bake-off, which exists partly to test
whether wrtag's taglib backend handles WAV better than mutagen, therefore cannot use this sample
and needs WAV folders named separately.

**The DMC folders' shape is verified, not assumed** (03-RESEARCH.md Assumptions Log A5). All
thirteen DMC folders in `unsorted`, the four drawn included, return **zero lines** from
`find <folder> -mindepth 2 -type d`: flat, audio at the top level, structurally comparable to a
`dj-mixes` folder.

The four drawn DMC folders span two DMC series (`Commercial Collection` and `Essential Hits`) and
two strata (V2 and V5), which is the most coverage four folders can buy from a population that is
V2 x10 and V5 x3.

---

## De-duplication proof

`dj-mixes` and `unsorted` share content, so a naive union over both trees would sample the same
audio twice. Filenames differ between the trees; the encoded bitstream does not. The assertion is
therefore made on `audio_md5`, never on names.

**Instrument 1 - the QUAL-01 join.** Both sides' folders are keyed as `<tree>/<folder>` and joined
against `/mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz` (9,736 records,
`audio_md5`-keyed). An exact set membership on the folder key, not a prefix test - a prefix test
would also match `Mastermix_Issue_410.1` when asked for `Mastermix_Issue_410`, and both are in the
population.

**Instrument 2 - a live reading.** `ffmpeg -nostdin -v error -i <f> -map 0:a -c copy -f md5 -` run
now over all 65 files on the `unsorted` (DMC) side, the same key definition
`snapshot-music-tags.sh:292` uses, with no output file path given so the read stays read-only.

| Quantity | Value |
|---|---|
| `dj-mixes` draw | 20 folders, 270 files, **241 distinct `audio_md5`** |
| `unsorted` (DMC) draw | 4 folders, 65 files, **65 distinct `audio_md5`** |
| **Shared `audio_md5` between the two sides** | **0** |
| Instrument 2 agreement with instrument 1 on the DMC side | **65 of 65** hashes identical |
| Instrument 2 shared with the `dj-mixes` side | **0** |

The 270 - 241 = **29 repeated hashes are within the `dj-mixes` side**, not across the two sides:
`Mastermix_Issue_410` / `Mastermix_Issue_410.1` and `VA-Mastermix.Issue.426-2021` /
`VA-Mastermix.Issue.426-2021.1` are re-downloads of the same releases. They were drawn by the
deterministic key rather than hand-picked, and they are left in deliberately - a tagger's
behaviour on a near-duplicate pair is worth observing, and removing them would have made the draw
non-reproducible from the stated key.

No swap was needed: the disjointness assertion passed on the first draw.

---

## The bucket-A and hard-shape candidates for plan 03-10

D-10 asks plan 03-10 for five album slots. Four are named here so 03-10 does not rediscover them;
the fifth is deliberately left open because D-10 requires it to be chosen after criterion 1 runs.

**All three albums 03-RESEARCH.md observed for these slots are unusable, and this is the
retraction.** Every one was checked with `ls -1A` and `find -mindepth 2 -type d`:

| Research's candidate | Measured reality |
|---|---|
| `Ed Sheeran - ÷ (2017) FLAC` | **completely empty** - zero files of any kind |
| `Lady Gaga - The Fame (2008) FLAC` | **one file**, `Lady Gaga - Poker Face.flac`. A single track, not an album |
| `Def Leppard - CD Collection Volume 1 - ... - 7CD` | **one file**, `7-05. Me And My Wine (Remix).flac`, `album` tag `Rarities - Volume One`. Not a 7CD set; an orphan track whose folder name is a filename |

This is the same failure mode as the `1-115` retraction above, in the other direction: a folder
name read as a statement about its contents. **9 of `nzb/music`'s 24 audio-bearing folders hold
exactly one file.**

The replacements, each verified flat and verified for file count:

| Slot | Album | Path | Files | Stratum | Verified |
|---|---|---|---|---|---|
| `clean-1` | Taylor Swift - *1989 (Taylor's Version)* | `nzb/music/Taylor.Swift-1989..Taylors.Version.-WEB-2023-MyMo` | 21 mp3 | V1 | flat (`-mindepth 2 -type d` = 0), single artist across all 21 |
| `clean-2` | Garth Brooks - *Ropin' The Wind* | `nzb/music/_FAILED_Garth.Brooks-Ropin.The.Wind-CDP.7.06330-2-CD-FLAC-1991-EMG` | 10 flac | V1 | flat, single artist, complete album. The `_FAILED_` prefix is a SABnzbd unpack marker on the folder name; the ten FLAC are present and probe clean |
| `hard-va-compilation` | *Now That's What I Call Music 116* | `nzb/unsorted/VA-Now_That.s_What_I_Call_Music__116__2023` | 47 mp3 | V6 | flat, **46 distinct per-track artists**, not scan-bearing |
| `hard-flat-multidisc` | Lady Gaga - *Born This Way: The Collection* | `nzb/music/Lady Gaga-Born This Way-The Collection [2011] FLAC` | 31 flac | V1 | flat, and genuinely multi-disc-in-one-folder: `01. Marry The Night` and `01. Born This Way (Zedd Remix)` are both at the top level |
| `dj-no-match` | **TBD - plan 03-07** | | | | D-10 requires this to be chosen after criterion 1 runs, from the folders Discogs returned no candidate for |

Recorded alternative for `hard-flat-multidisc` if Born This Way proves too easy:
`nzb/music/_FAILED_Garth.Brooks-The.Ultimate.Hits-2CD-FLAC-2007-WRS`, 34 flac, flat, whose `album`
tag reads `The Ultimate Hits (Disc 2 of 2)` while both discs sit in the one folder.

---

## Scratch tree

Two roots, deliberately on different filesystems (D-07):

| Root | Path | Filesystem | Contents |
|---|---|---|---|
| `SCRATCH_TANK` | `/mnt/tank/downloads/spike-03` | `tank/downloads` (ZFS) - a **sibling of `complete/`**, therefore the same dataset, which is what makes `cp --reflink` work at all | `raw/`, `normalised/`, `normalised-metadata/`, `wrtag-src/`, `bf-inbox/`, `bf-clean/` |
| `SCRATCH_FAST` | `/mnt/fast/spike-03` | **LXC 100's 128 G ext4 root** - see the finding below | `out/`, `beets-config/`, `bf-config/`, `wrtag-lib/` |

**`/mnt/fast/spike-03` is not on the `fast` pool, and the plan's stated reason for choosing it does
not hold.** The plan puts outputs there "so they do not consume `/` on LXC 100". Measured with
`findmnt --target`, `/mnt/fast/spike-03` resolves to `/dev/mapper/pve-vm--100--disk--0`, `ext4`,
mounted at `/`. Only the *children* of `/mnt/fast` that appear as `mp` entries in
`/etc/pve/lxc/100.conf` are real bind mounts - `stacks`, `appdata/*`, `home/*`, `transcode`,
`tools`. `spike-03` is not among them, and **neither is `safety`**: Phase 1's entire recovery
fence, 698 MB, also sits on the container root. This is the same defect class project MEMORY
records for `/mnt/fast/appdata`. It is **not a blocker here** - `/` has 34 GiB free against
03-01's 8 GiB OD-1 floor and this plan wrote 321 KB there - but the constraint is real and every
later Phase 3 plan that writes a beets `library.db`, a wrtag library or a container log under
`/mnt/fast/spike-03` is writing to `/`, not to ZFS. Watch the OD-1 floor, not the pool.

### The reflink command, verbatim, and why it does not run where the plan says

`cp -a --reflink=always` **fails from LXC 100**, and not for the reason the plan anticipates:

```
cp: failed to clone '/mnt/tank/downloads/spike-03/raw/.../4200101 - Mastermix - Club Cuts.mp3'
    from '/mnt/tank/downloads/complete/nzb/dj-mixes/.../4200101 - Mastermix - Club Cuts.mp3':
    Operation not permitted
cp: preserving permissions for '/mnt/tank/downloads/spike-03/raw/Mastermix.Issue.420.2021':
    Operation not permitted
```

Two separate failures in one command. The first is **EPERM, not EXDEV** - the dataset is right
(`spike-03` is a sibling of `complete/` exactly as designed), but the `FICLONE` ioctl is refused
to an unprivileged container. Failing loud rather than degrading to a full copy is precisely what
`--reflink=always` is for, and it worked: the run stopped on folder 1 of 24 instead of silently
writing 17 GB. The second is the documented `aclmode=restricted` EPERM on `tank`, which is why
`-a` cannot be used and which fails **even as real root on atlantis**.

The copy is therefore **delegated to atlantis**, the same route and the same reasoning as the
`zfs` calls, with `-a` replaced by `-r --preserve=timestamps`:

```bash
# ON ATLANTIS (172.16.1.158). Data and mtimes are preserved; mode and ownership are not
# attempted, because chmod is EPERM on tank even as real root and everything there is 0777
# by ACL inheritance already.
cp -r --reflink=always --preserve=timestamps "$src" /mnt/tank/downloads/spike-03/raw/
cp -r --reflink=always --preserve=timestamps "$raw" /mnt/tank/downloads/spike-03/normalised/
chown -R 568:568 /mnt/tank/downloads/spike-03
```

The `chown` is the one thing this plan does that its own text says not to do. The prohibition is
stated because `chown` fails from LXC 100 (sparse idmap); from atlantis it succeeds, and it is the
same route Phase 1 plan 01-08 used to normalise the library to `apps:apps`. Without it the scratch
tree is `root:root` while every later plan runs beets and beets-flask as `568:568`. Mode is left
strictly alone.

### Space

| Measurement | Before | After |
|---|---|---|
| `df -h /mnt/tank/downloads` avail | 9.0T | 9.0T |
| `zfs list tank/downloads` USED / AVAIL | 2.00T / 8.99T | 2.01T / 8.99T (`AVAIL` 9,886,085,972,096 B) |
| `du -sh /mnt/tank/downloads/spike-03` | n/a | **17 G apparent**, both copies |
| `du -sh` of the sources | 8.9 GB (8.0 GB `dj-mixes` twenty + 0.9 GB DMC four) | |

`du` reports the full 17 G because it cannot see block cloning. The pool can:
`bcloneused 36.7G`, `bclonesaved 45.0G`, `bcloneratio 2.22x`, `feature@block_cloning active`.
`AVAIL` did not move. **ZFS frees space asynchronously and `zfs list` can lag a large delete by
~20 s**, so the deletion in plan 03-11 must be re-measured after a pause rather than immediately.

### Inode proof - reflinks, not hard links

A reflink is a separate inode sharing blocks. A hard link would share the inode, and a
normalisation write would then reach back into `complete/`.

```
source folder   inode=243329 links=2 owner=apps:apps mode=777  complete/nzb/dj-mixes/Mastermix.Issue.420.2021
raw/ copy       inode=230657 links=2 owner=apps:apps mode=777  spike-03/raw/Mastermix.Issue.420.2021
normalised copy inode=231389 links=2 owner=apps:apps mode=777  spike-03/normalised/Mastermix.Issue.420.2021

source file     inode=243457 links=1 size=36235155  .../4200101 - Mastermix - Club Cuts.mp3
raw/ file       inode=230662 links=1 size=36235155  .../4200101 - Mastermix - Club Cuts.mp3
normalised file inode=231394 links=1 size=36235155  .../4200101 - Mastermix - Club Cuts.mp3
```

Three distinct inodes, link count 1 on every file, identical sizes.

### The snapshot

Taken **after `raw/` was populated and before the first write into `normalised/`**, which is what
makes it `normalise-dj-tags.py`'s rollback: rolling back to it removes `normalised/` and leaves
`raw/` to re-reflink from.

| Property | Value |
|---|---|
| Snapshot | `tank/downloads@spike-03-t0` |
| Created | `Thu Sep 3 21:40 2026` (atlantis local) |
| `USED` / `REFER` at creation | `0B` / `2.01T` |
| **Route** | **`ssh:172.16.1.158`** |
| `normalised/` entries at snapshot time | **0** (asserted before taking it) |

The route is recorded because it is not an implementation detail. `zfs` **does not and cannot
exist on LXC 100** - the container is unprivileged and the pool lives on atlantis - so the query
went over `ssh -o BatchMode=yes -o ConnectTimeout=5 root@172.16.1.158`, the `zfs_query()` shape
from `check-music-freeze.sh:123-131`. Had atlantis been unreachable the snapshot state would be
**UNKNOWN**, and this task would have failed rather than skipped: that snapshot is the only
rollback behind the normalisation step, and two further fallbacks (`unsorted` itself, and
`tank/downloads@pre-project`) exist behind it.

### The before-state

`bash scripts/snapshot-music-tags.sh spike03-before --roots /mnt/tank/downloads/spike-03/normalised`

| Property | Value |
|---|---|
| Path | `/mnt/fast/spike-03/out/spike03-before.ndjson.gz` (321,820 B) |
| Records | **335** - exactly the sum of `n_files` across the 24 drawn folders |
| Distinct `audio_md5` | **306** (the 29-record gap is the two near-duplicate pairs in the draw) |
| `.failed` ledger | **0 lines** |
| Read | 8,884,347,244 B in 70 s, 121 MB/s, 0.209 s/file |

This is the BEFORE side of plan 03-05's field-loss gate. `snapshot-music-tags.sh` has no `--out`
flag - it writes `<BASENAME>` into the fence's `tags/` directory by construction - so the run
wrote `/mnt/fast/safety/music-pre-project/tags/spike03-before.*` and all three artefacts were then
copied to `$SCRATCH_FAST/out/`. Both locations are on the same filesystem and both are the
plan's own; nothing was written to the system temp directory.

### Verification

| Assertion | Result |
|---|---|
| `raw/` entries | **24** |
| `normalised/` entries | **24** |
| Per-folder audio file counts vs the draw table's `n_files`, both sides | **0 mismatches** across all 48 checks |
| `find complete/nzb/dj-mixes -newer <scratch> -type f` | **0 lines** |
| `find complete/nzb/unsorted -newer <scratch> -type f` | **0 lines** |
| `ls -1 /tmp \| grep -c spike-03` | **0** |
| `zcat spike03-before.ndjson.gz \| wc -l` | **335** |
| `.failed` entries | **0** |
| `bash scripts/check-music-freeze.sh` | **exit 0**, `tagger-class writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` |
| De-duplication re-asserted from the live before-snapshot, **both sides read live** | dj-mixes 241 / DMC 65 distinct `audio_md5`, **0 shared** - identical to the QUAL-01 join |

**`zfs diff tank/media/Music@pre-project` does not return clean, and it did not return clean
before this plan started.** It reports **2,674 lines, every one `M`** - zero additions, zero
removals, zero renames. 2,674 is the exact entry count of the library, and the modification is
Phase 1 plan 01-08's `chown` to `568:568`, which ran *after* `@pre-project` was taken. CLAUDE.md
records that chown and cites the same 2,674. The verification line as written is therefore
unsatisfiable and always was. Proven not to be this plan's doing by two further readings:
`find /mnt/tank/media/Music -newermt "2026-09-03 20:00"` returns **0**, and the newest `ctime`
anywhere in the library is **2026-08-18 22:43:54**, sixteen days before this plan ran.
