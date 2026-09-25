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
