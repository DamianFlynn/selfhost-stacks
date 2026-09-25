# Phase 7 pilot sample — the twelve, named before the run

Companion to [`07-EXPECTED-TREE.txt`](07-EXPECTED-TREE.txt) (the oracle the run is judged
against) and to [`../06-tagger-configuration-and-dry-run/06-SAMPLE.md`](../06-tagger-configuration-and-dry-run/06-SAMPLE.md)
(the Phase 6 draw six of these rows are reused from). Plan 07-06.

This file is written in two commits, and the order of the commits is the evidence. The first
section below is committed **alone**, before any eligible set is measured; the second is appended
after, and the first is never edited (its digest at the declaration commit is re-checked when the
second is written).

---

## DECLARED BEFORE THE DRAW (committed before any eligibility was measured)

At this commit no eligibility count has been taken, no fresh folder has been drawn, and no attribute
of any folder has been measured for this plan. Every number below that describes the estate is
either quoted from an earlier committed document and labelled as such, or is a target.

### 1. The twelve slots and their sources (D-04)

| Slot | Source | Folder (full path) |
|---|---|---|
| S1a | reused, 06-SAMPLE S1 | `/mnt/tank/downloads/complete/nzb/music/Benson Boone-American Heart-24BIT-44KHZ-WEB-FLAC-2025-OBZEN-xpost` |
| S1b | reused, 06-SAMPLE S1 | `/mnt/tank/downloads/complete/nzb/music/Benson.Boone.-.Fireworks.&.Rollerblades.(2024).[16Bit-44.1kHz].FLAC.[PMEDIA].⭐️-xpost` |
| S1c | reused, 06-SAMPLE S1 | `/mnt/tank/downloads/complete/nzb/music/Benson_Boone_-_American_Heart-WEB-2025-BENSONBOONE` |
| S2 | reused, 06-SAMPLE S2 — **the multi-disc release** (QUAL-03) | `/mnt/tank/downloads/complete/nzb/music/Michael.Jackson.-.The.Essential.Michael.Jackson.-.(2005).[upc.827969428726].[FLAC.24-96]-maladicta-xpost` |
| S3 | reused, 06-SAMPLE S3 — **the various-artist compilation** (QUAL-03) | `/mnt/tank/downloads/complete/nzb/music/Now_.That.s.What.I.Call.Music.121.2025.320kbps.MP3.InChY` |
| S7 | reused, 06-SAMPLE S7 — the singleton folder | `/mnt/tank/downloads/complete/nzb/music/Cyril - Stumblin In (LUNAX Remix) (Extended Mix)-(5021732254740)-SINGLE-WEB-2024-ZzZz [9c1feafc0] [2af13ead9]-xpost` |
| S5a | reused, 06-SAMPLE S5 — DJ service | `/mnt/tank/downloads/complete/nzb/dj-mixes/Mastermix.Issue.420.2021` |
| S5b | reused, 06-SAMPLE S5 — DJ service | `/mnt/tank/downloads/complete/nzb/dj-mixes/Mastermix.Issue.421.2021` |
| F1 | fresh — the ≥4-artist stratum (D-05) | *drawn after this commit* |
| F2 | fresh — D-06 population | *drawn after this commit* |
| F3 | fresh — D-06 population | *drawn after this commit* |
| F4 | fresh — D-06 population | *drawn after this commit* |

The two S1 Benson Boone `American Heart` folders are the same album as FLAC and as MP3 — the
predicted `%aunique{}` firing, and the pair `import.duplicate_action: skip` silently dropped ten
files from in Phase 6 run 1. The eight reused folders are named here by exact path; the draw
asserts each still exists and **stops** on a missing one — no substitution.

### 2. Exclusions, each with its reason

- **S6 — `/mnt/tank/media/Music/Katy Perry/Teenage Dream (2010)`.** A **LIBRARY** folder, drawn
  read-only under Phase 6 D-05's `:ro`. It is already imported and is **not an import candidate at
  all**.
- **S4 — `/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023/Vol 001`.**
  Bucket B; criterion 1 says twelve **bucket-A** albums.
- **D-01 — `/mnt/tank/downloads/mybook-music-archive` and `/mnt/tank/downloads/mac-music-archive`.**
  Unreachable by construction, not by preference: `scripts/snapshot-music-tags.sh` pins four
  QUAL-01 capture roots by name (`unsorted`, `dj-mixes`, `complete/nzb/music`, `media/Music`) and
  neither archive is one of them, so criterion 4's field-level diff would be uncomputable for any
  album drawn from them. The population in § 3 is defined by two roots that exclude both.
- **Staging — `/mnt/tank/downloads/complete/nzb/_inbox/*`.** Staging, not population; drawing from
  it would sample content twice and couple this draw to another plan's in-flight state.
- **Non-music `nzb/*`** — `movies`, `tv`, `software`, `readarr`.

### 3. The fresh population (D-06)

Folders **directly** under `/mnt/tank/downloads/complete/nzb/music/` and
`/mnt/tank/downloads/complete/nzb/unsorted/` that hold ≥1 audio file, where audio is the extension
set of `scripts/snapshot-music-tags.sh` `AUDIO_EXT`
(`mp3 wav flac m4a aiff aif wma ogg opus aac wv ape alac`, case-insensitive), counted recursively
within the folder — **excluding**:

- the 115 `VA-Now_That.s_What_I_Call_Music__1-115_2023/Vol NNN` folders and their parent
  `VA-Now_That.s_What_I_Call_Music__1-115_2023` itself;
- the eight reused folders in § 1 (six of which sit under `music/`).

**Expectation, to be re-measured, not assumed:** D-06 quotes **162 folders / 3,236 audio files** at
2026-09-21 (06-SAMPLE.md § *The population, declared first*: `unsorted` 119 / 2,705 + `music`
43 / 531). That figure *includes* the six reused `music/` folders; the draw records the live count
both with and without them and states any difference from 162 / 3,236.

*Known consequence, not a predicate:* a fresh draw whose folder name collides with a `dj-mixes`
folder name is a DUPE-01 twin. Plan 07-02's `diff-music-tags.sh` exits 3 UNKNOWN on an AMBIGUOUS
duplicate `audio_md5` group, and on the Phase 1 capture 282 of the 314 ambiguous groups pair
`dj-mixes` with `unsorted`. A twin is therefore **not** excluded (excluding it would be selecting on
an outcome); it is flagged by the draw and routed to plan 07-13 (§ 7).

### 4. F1 — the ≥4-artist stratum (D-05), target 1

**Eligible** when the folder is in the § 3 population and **at least one audio file** in it has
**≥4 distinct non-empty entries** in either:

- beets' own multi-valued `artists` field, read by `mediafile.MediaFile(path).artists` inside
  `beets-flask` (`/venv/bin/python`, opened for read, `save()` never called — 06-SAMPLE's third
  instrument); **or**
- its raw `ARTISTS` tag, split on `;`, each part whitespace-stripped.

Distinctness is exact string equality after stripping. `ARTIST` (singular) with a delimiter does
**not** qualify — the predicate is on the multi-valued field only, which is the field Music
Assistant's artist-list cap (E6) is about.

**Reallocation rule.** If the F1 eligible set is **empty**, F1 becomes a fourth D-06 draw (drawn
from the same population by the same key, before F2–F4), and this document records
**"E6 second measurement: NOT TAKEN — eligible set empty"**. It is **never** satisfied by a row with
fewer than four artists.

### 5. F2 … F4 — target 3

The § 3 population minus F1's draw. No further predicate.

### 6. Seed, key, order, determinism

- **Seed:** `gsd-07-pilot-draw-2026-09-25` (fixed in the plan text before any measurement).
- **Key:** for each eligible folder, `sha256(SEED + "\n" + path_bytes)`, where `path_bytes` is the
  full folder path encoded `utf-8` with `surrogateescape` — the byte string `LC_ALL=C sort` orders
  on. Sort ascending by hex digest; ties (none expected) broken by `LC_ALL=C` path order; take the
  first N.
- **Draw order:** F1 first (N = 1 from F1's eligible set); then F2–F4 (N = 3) from the § 3
  population with F1's folder removed.
- **Determinism rule:** the whole derivation runs twice into `draw-a.json` / `draw-b.json` (plus
  logs) and the two are `diff`ed; **zero lines of difference** is required, and both digests are
  recorded. A draw run once is not demonstrably deterministic.

### 7. P-IDs and the execution order

P-IDs are fixed now, because `%aunique{}` is evaluated against the library **at import time**.

| P-ID | Slot | Folder |
|---|---|---|
| P01 | S2 | `…/music/Michael.Jackson.-.The.Essential.Michael.Jackson.-.(2005).[upc.827969428726].[FLAC.24-96]-maladicta-xpost` (gated first, D-10) |
| P02 | S1a | `…/music/Benson Boone-American Heart-24BIT-44KHZ-WEB-FLAC-2025-OBZEN-xpost` |
| P03 | S1b | `…/music/Benson.Boone.-.Fireworks.&.Rollerblades.(2024).[16Bit-44.1kHz].FLAC.[PMEDIA].⭐️-xpost` |
| P04 | S1c | `…/music/Benson_Boone_-_American_Heart-WEB-2025-BENSONBOONE` — **after P02, deliberately**, so the pair's second arrival is the one that meets the ambiguity |
| P05 | S3 | `…/music/Now_.That.s.What.I.Call.Music.121.2025.320kbps.MP3.InChY` |
| P06 | S7 | `…/music/Cyril - Stumblin In (LUNAX Remix) (Extended Mix)-(5021732254740)-SINGLE-WEB-2024-ZzZz [9c1feafc0] [2af13ead9]-xpost` |
| P07 | S5a | `…/dj-mixes/Mastermix.Issue.420.2021` |
| P08 | S5b | `…/dj-mixes/Mastermix.Issue.421.2021` |
| P09 | F1 | *drawn after this commit* |
| P10 | F2 | *drawn after this commit* |
| P11 | F3 | *drawn after this commit* |
| P12 | F4 | *drawn after this commit* |

P-IDs are **identifiers**, not a sequence.

### EXECUTION ORDER

P01 (plan 07-10, then its undo/re-run in 07-11); then P02, P03, P04, P05, P06, P09, P10, P11, P12 (plan 07-12); then P07, P08 and any DJ twin (plan 07-13, so DJ routing happens in one place).

EXECUTION SET 07-12: P02 P03 P04 P05 P06 P09 P10 P11 P12
EXECUTION SET 07-13: P07 P08

A fresh draw that the draw flags as a `dj-mixes` twin is moved from the first set to 07-13 by plan
07-12 Task 1 (recorded there as `MOVED TO 07-13:`); **this declaration is never edited**.

The only order-sensitive constraint is **P02 before P04** (the `%aunique{}` prediction). Plans 07-12
and 07-13 assert the order after the fact from beets' `albums.added`, so the prediction is read
against the order that actually happened.

---

## THE DRAW (measured after the declaration commit)

Everything below was measured on 2026-09-26, after the declaration commit `70cd38c`. Read-only
throughout: `beets-flask` was entered with `docker exec -i … /venv/bin/python` with the program on
stdin (or as `-c` text), nothing was staged in `/mnt/fast/appdata/arrs/beets/config/` (listing
before and after identical, sha256 `ca1ff4cf…` both), and the real `library.db` is unchanged
(`fbbdde0c…`, **0 items / 0 albums**, opened `mode=ro`). Derivation outputs stay at the fence
`/mnt/fast/safety/phase07/draw/`; their digests are in
[`artifacts/07-06-draw.txt`](artifacts/07-06-draw.txt).

### The eight reused folders — present

All eight asserted with `test -d` **from atlantis as real root** (`id -u` = 0), exact paths from
§ 1: **8 PRESENT, 0 MISSING**. Their beets field view (re-read today with the byte-identical Phase 6
reader) reproduces 06-SAMPLE's table on every column.

### The population, measured

| Set | Folders | Audio files |
|---|---|---|
| `nzb/music/` top-level folders with ≥1 audio file | 46 | 570 |
| `nzb/unsorted/` top-level folders with ≥1 audio file, *Now!* `1-115` parent excluded | 119 | 2,705 |
| **D-06 population incl. the six reused `music/` folders** | **165** | **3,275** |
| D-06 expectation (2026-09-21) | 162 | 3,236 |
| **difference** | **+3** | **+39** — all in `music/` (43 → 46 folders, 531 → 570 files): new downloads since 2026-09-21; `unsorted` reproduces 119 / 2,705 exactly |
| **fresh population (reused removed) — the draw's population** | **159** | **3,163** |

Excluded and counted: 4,746 audio files in the *Now!* `1-115` set (reproduces Phase 6's figure);
0 loose audio files directly in either root; 0 audio-less top-level folders. Population extensions:
mp3 2,688 · flac 339 · wav 134 · wv 2.

### F1 — the ≥4-artist stratum

**F1 eligible: 0 of 159 folders (0 of 3,163 files).** Only **9** files in the whole D-06 population
carry a multi-valued `artists` / raw `ARTISTS` tag at all — all nine in
`Michael Jackson-Off the Wall-16BIT-WEB-FLAC-1979-coodu-xpost`, each with exactly **one** entry.
Both readers (mediafile `artists` and raw `ARTISTS` split on `;`) agree file-for-file.

**The instrument was driven against a positive control before the zero was believed**
(CONVENTIONS rule 1; a recipe that has never matched is not evidence of absence): the same program
over the library's S6 folders reads `CD 01-05 Lady Gaga - Jewels n’ Drugs.flac` as **4 / 4**
(`Lady Gaga`, `T.I.`, `Too $hort`, `Twista` — E6's first measurement itself) and five 2-artist files
as 2 / 2. The predicate fires where the shape exists; the D-06 population does not hold it.

**E6 second measurement: NOT TAKEN — eligible set empty.** Per the declared reallocation rule, F1
became a fourth D-06 draw. It was **not** satisfied by a row with fewer than four artists.
*Limitation stated:* no MP3 in the population carries `TXXX:ARTISTS`, so the raw reader's ID3 branch
has no positive reading here; mediafile's `artists` (which reads the same frame for MP3) is the
covering half and also reads 0.

### F2 … F4 (and reallocated F1) — the draw

Eligible: **159**. Seed `gsd-07-pilot-draw-2026-09-25`, key as declared; first four by digest:

| P-ID | Slot | Key (sha256, first 16) | Folder |
|---|---|---|---|
| P09 | F1 (reallocated — NOT TAKEN) | `00c30dca93a1df50` | `/mnt/tank/downloads/complete/nzb/unsorted/VA-Mastermix.90.s.12.inch.USB.Top.Up-2024` |
| P10 | F2 | `00dd601ffb1e6dfc` | `/mnt/tank/downloads/complete/nzb/unsorted/VA.Now.That.s.What.I.Call.Music_.117.2024..CD.FLAC..CDNOW117` |
| P11 | F3 | `036c6290d12d7457` | `/mnt/tank/downloads/complete/nzb/unsorted/Mastermix_Issue_415` |
| P12 | F4 | `037905778e0a4152` | `/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__116__2023` |

**Determinism:** the field pass ran twice (`population-a/b.ndjson`, byte-identical) and the draw
ran twice (`draw-a.json` / `draw-b.json` and their logs): **zero lines of difference**, digests in
the artifact. All four fresh draws are from `unsorted/` — the population Phase 9 must process.

**DJ twin check** (fresh folder name vs the 60 `dj-mixes` folder names, exact match):
`Mastermix_Issue_415` exists as `/mnt/tank/downloads/complete/nzb/dj-mixes/Mastermix_Issue_415` —
a DUPE-01 twin; per § 7 it moves to plan 07-13's set (recorded by 07-12 Task 1). The other three
have no `dj-mixes` namesake.

DJ TWINS AMONG FRESH DRAWS: P11

*Worth knowing, not a rule:* P09 is DJ-service content (`Mastermix 90s 12inch USB Top Up`) that is
**not** a twin by name, so by the declared rules it stays in 07-12's set and imports like an
ordinary album. Two of the four fresh draws are *Now!* volumes (116, 117) outside the `1-115` set.
Nobody chose them; the key did.

### The twelve

Stratum is the Phase 6 precedence `S5 → S7 → S2 → S3 → S1 → other`, information only for the fresh
rows (all `unsorted/`, so S1 — which requires `music/` — cannot fire for them). `disctotal` / `disc`
are beets' own fields; `albumartist` gives the raw tag values then beets' as-is guess.

| P-ID | Folder | Stratum | Files | Extensions | `disctotal` | `disc` | Distinct `artist` | `albumartist` tag → as-is | `album` | `comp` |
|---|---|---|---|---|---|---|---|---|---|---|
| P01 | /mnt/tank/downloads/complete/nzb/music/Michael.Jackson.-.The.Essential.Michael.Jackson.-.(2005).[upc.827969428726].[FLAC.24-96]-maladicta-xpost | **S2 (multi-disc)** | 32 | flac 32 | `{2}` | `{1,2}` | 4 | `Michael Jackson` → `Michael Jackson` | The Essential Michael Jackson | false |
| P02 | /mnt/tank/downloads/complete/nzb/music/Benson Boone-American Heart-24BIT-44KHZ-WEB-FLAC-2025-OBZEN-xpost | S1 | 10 | flac 10 | `{0}` | `{1}` | 1 | `Benson Boone` → `Benson Boone` | American Heart | false |
| P03 | /mnt/tank/downloads/complete/nzb/music/Benson.Boone.-.Fireworks.&.Rollerblades.(2024).[16Bit-44.1kHz].FLAC.[PMEDIA].⭐️-xpost | S1 | 15 | flac 15 | `{1}` | `{1}` | 1 | `Benson Boone` → `Benson Boone` | Fireworks & Rollerblades | false |
| P04 | /mnt/tank/downloads/complete/nzb/music/Benson_Boone_-_American_Heart-WEB-2025-BENSONBOONE | S1 | 10 | mp3 10 | `{1}` | `{1}` | 1 | `Benson Boone` → `Benson Boone` | American Heart | false |
| P05 | /mnt/tank/downloads/complete/nzb/music/Now_.That.s.What.I.Call.Music.121.2025.320kbps.MP3.InChY | **S3 (compilation)** | 44 | mp3 44 | `{1}` | `{1}` | 39 | *(none)* → `Various Artists` | NOW That's What I Call Music! 121 | **true** |
| P06 | /mnt/tank/downloads/complete/nzb/music/Cyril - Stumblin In (LUNAX Remix) (Extended Mix)-(5021732254740)-SINGLE-WEB-2024-ZzZz [9c1feafc0] [2af13ead9]-xpost | S7 | 1 | mp3 1 | `{0}` | `{0}` | 1 | *(none)* → `Cyril` | Stumblin' In (LUNAX Remix) (Extended Mix) | false |
| P07 | /mnt/tank/downloads/complete/nzb/dj-mixes/Mastermix.Issue.420.2021 | S5 | 10 | mp3 10 | `{0}` | `{1,2}` | 1 | `Mastermix` → `Mastermix` | Issue 420 | false |
| P08 | /mnt/tank/downloads/complete/nzb/dj-mixes/Mastermix.Issue.421.2021 | S5 | 10 | mp3 10 | `{0}` | `{0}` | 1 | `Various Artists` → `Various Artists` | Mastermix Issue 421 | false |
| P09 | /mnt/tank/downloads/complete/nzb/unsorted/VA-Mastermix.90.s.12.inch.USB.Top.Up-2024 | other | 100 | mp3 100 | `{0}` | `{0}` | 82 | `Various Artists` → `Various Artists` | Mastermix 90s 12inch USB Top Up | false |
| P10 | /mnt/tank/downloads/complete/nzb/unsorted/VA.Now.That.s.What.I.Call.Music_.117.2024..CD.FLAC..CDNOW117 | S2 | 50 | flac 50 | `{2}` | `{1,2}` | 50 | `Various` → `Various` | NOW That's What I Call Music! 117 | false |
| P11 | /mnt/tank/downloads/complete/nzb/unsorted/Mastermix_Issue_415 | other | 10 | mp3 10 | `{0}` | `{0}` | 2 | `Mastermix` → `Mastermix` | **two values**: `Mastermix`, `Mastermix Issue 415 (Januar 2021)` | false |
| P12 | /mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__116__2023 | S3 | 47 | mp3 47 | `{0}` | `{0}` | 46 | *(none)* → `Various Artists` | Now That's What I Call Music 116 | **true** |

**339 audio files across 12 folders** — 132 reused (the FROZEN count `07-EXPECTED-TREE.txt` must
carry) + **207 fresh** (P09 100 + P10 50 + P11 10 + P12 47; the APPENDED count). F1's ≥4-artist
file(s): none — NOT TAKEN above.

Shapes the fresh rows carry that the reused ones do not, read off the table: **P10 is a second
multi-disc release, and a `Various` (not `Various Artists`) placeholder that the as-is guess keeps
single-artist** (`comp` false, 50/50 plurality on the tag), so it renders under `Various/`, not
`Various Artists/`; **P09 has no `track` on any of its 100 files** (`00` in every rendered name) and
an `albumartist` of `Various Artists` that does *not* set `comp`; **P11 has two `album` values**
(9 + 1 files).

### The D-18 register, per folder (raw mutagen frame read)

Counts are files carrying the frame (`TBPM`/`bpm`, `TKEY`/`initialkey`, `TXXX:EnergyLevel`,
`TCON`/`genre`, `COMM*`/`comment`), read by `mutagen.File()` inside `beets-flask`, never saved.

| P-ID | Folder | bpm | `TKEY` | `TXXX:EnergyLevel` | genre | comment |
|---|---|---|---|---|---|---|
| P01 | Michael.Jackson.-.The.Essential.… | 0 | 0 | 0 | 0 | 0 |
| P02 | Benson Boone-American Heart-…-OBZEN-xpost | 0 | 0 | 0 | 10 | 0 |
| P03 | Benson.Boone.-.Fireworks.&.Rollerblades… | 0 | 0 | 0 | 0 | 15 |
| P04 | Benson_Boone_-_American_Heart-WEB-…-BENSONBOONE | 0 | 0 | 0 | 10 | 0 |
| P05 | Now_.That.s.What.I.Call.Music.121… | 0 | 0 | 0 | 44 | 0 |
| P06 | Cyril - Stumblin In … | 0 | 0 | 0 | 1 | 1 |
| P07 | Mastermix.Issue.420.2021 | **10** | 0 | 0 | 10 | 0 |
| P08 | Mastermix.Issue.421.2021 | 0 | 0 | 0 | 10 | 0 |
| P09 | VA-Mastermix.90.s.12.inch.USB.Top.Up-2024 | **100** | 0 | 0 | 100 | 0 |
| P10 | VA.Now.That.s.What.I.Call.Music_.117… | 0 | 0 | 0 | 0 | 0 |
| P11 | Mastermix_Issue_415 | 0 | **9** | **9** | 9 | 0 |
| P12 | VA-Now_That.s_What_I_Call_Music__116__2023 | 0 | 0 | 0 | 47 | 47 |

The reused rows reproduce 06-SAMPLE's register. **P11 is the first pilot folder carrying `TKEY` and
`TXXX:EnergyLevel`** (9 of 10 files each) — the D-18 key/energy branch Phase 6 recorded as
unexercised now has a named folder, and it routes through 07-13 with the DJ pair.

### D-26 — the album-populated-and-distinct predicate, asserted read-only

`album` per file via `mediafile` (beets' own reader) on both S5 folders, the natural `bootleg`
candidates. Predicate: every file's `album` non-empty **and** exactly one distinct value per folder.

| Folder | File | `album` |
|---|---|---|
| Mastermix.Issue.420.2021 | 4200101 - Mastermix - Club Cuts.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200102 - Mastermix - Mastermixed 5.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200103 - Mastermix - Reggae Fusion.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200104 - Mastermix - Into The 80s.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200105 - Mastermix - Triple Tracker Crazibiza.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200201 - Mastermix - The Ibiza Sessions Jackin' House.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200202 - Mastermix - Party On Fire.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200203 - Mastermix - Classic Disco vs. Nu Disco.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200204 - Mastermix - Hit The Dancefloor Latin Pop.mp3 | Issue 420 |
| Mastermix.Issue.420.2021 | 4200205 - Mastermix - Summer Slam 00s Club Classics.mp3 | Issue 420 |
| Mastermix.Issue.421.2021 | 01. Mastermix - Club Cuts.mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 01. Mastermix - The Ibiza Sessions (Balearic Beats).mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 02. Mastermix - Deep House Covers 2021.mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 02. Mastermix - Pride (The Mix 2021).mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 03. Mastermix - Electro Swing Party.mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 03. Mastermix - Where The Rap Party At.mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 04. Mastermix - Jackin' House Floorfillers.mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 04. Mastermix - Lounge & Bar Grooves.mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 05. Mastermix - Cool Summer Dance Triple Tracker.mp3 | Mastermix Issue 421 |
| Mastermix.Issue.421.2021 | 05. Mastermix - The Secret Garden.mp3 | Mastermix Issue 421 |

**Verdict: `Mastermix.Issue.420.2021` — TRUE** (10/10 populated, 1 distinct value).
**`Mastermix.Issue.421.2021` — TRUE** (10/10 populated, 1 distinct value).
*Information, outside the predicate's declared scope:* the fresh DJ twin P11 `Mastermix_Issue_415`
would read **FALSE** (two distinct `album` values) — the shape in which `bootleg` grouping by
existing metadata would split one release in two.

`03-asis` / `bootleg` is **NOT used by the pilot** — D-20 routes all twelve through `02-review` — so
**E2's gate stays untested-by-import and is carried**; this reading makes its precondition a tested
predicate, nothing more.

### The predicted `%aunique{}` firing, given the execution order

The real `library.db` holds **0 items / 0 albums** today, so every collision is intra-pilot. Among
the twelve, exactly one `(as-is albumartist, album)` pair is ambiguous: **P02 / P04,
`Benson Boone / American Heart`**. P05 (`… 121`), P10 (`… 117`) and P12 (`… 116`) differ in
`album`; nothing else collides.

Under the ordered import (P02 before P04, § EXECUTION ORDER):

- **P02** is imported into a library with no other `American Heart` — `%aunique{}` returns `""`.
  Even once P04 lands, P02's disambiguator value (`label`) is empty, so its rendered suffix stays
  `""`.
- **P04** is the second arrival and meets the ambiguity: `albumtype` (empty both) and `year` (2025
  both) do not separate; `label` does (empty vs `Night Street Records, Inc. - Warner Records Inc.`)
  — **P04 is predicted to carry ` [Night Street Records, Inc. - Warner Records Inc.]`**, which is
  the frozen Phase 6 prediction.
- ⚠ **A MusicBrainz match (D-20, `02-review`) may populate `label` on both.** Different labels →
  both separated by `label`, P02 still rendered at its own import time with no suffix. The same
  label on both → `label` no longer separates, the next disambiguator (`catalognum`, …) decides,
  and if none does beets falls back to the numeric database id. The prediction is therefore
  conditional on the match, and plans 07-12 read it against the `label` values actually stored.

### What this sample does NOT cover

1. **E6's second measurement** — NOT TAKEN; the D-06 population holds no file with ≥4 artists
   (above). It stays open for a population that has one.
2. **DJ path rule 2** (`albumtype:=dj disctotal:2..`) — no pilot row reaches it (P07/P08/P11 carry
   no `disctotal`); it is **covered read-only by plan 07-05** (D-09, `Mastermix_Issue_403`, 10/10
   rendered correctly).
3. **Zero WAV** — 134 WAV sit in the population and none was drawn; the WAV ID3-offset rule is still
   untested by this sample. No `wv`, `m4a` or `ogg` either.
4. **Strata not reached by the fresh draws:** S1 (requires `music/`; all four fresh rows are
   `unsorted/`) and S7. They are covered by the reused rows only.
5. **P11 is a DUPE-01 twin**, so any QUAL-02 comparison spanning its two roots can read **UNKNOWN
   (exit 3)** under plan 07-02's AMBIGUOUS arm — expected, and the reason it moves to 07-13.
