# Phase 3 minimum-viable DJ tag normalisation

Companion to [`03-SAMPLE.md`](03-SAMPLE.md) (the 24 drawn folders and their strata), to
[`03-DECISION.md`](03-DECISION.md) (D-07, D-08 and the pre-committed thresholds) and to
[`scripts/normalise-dj-tags.py`](../../../scripts/normalise-dj-tags.py), which is the artefact this
document records the run of.

Nothing here is applied by `docker compose`. This is the reviewed dry-run diff D-08 asks for, the
recorded artist-policy choice plan 03-07 interprets its four-cell comparison against, and the
field-loss verdict from the tooling Phase 1 already built.

State as of 2026-09-03 — **normalised arm written; `raw/` intact; no Discogs request issued.**

> **OD-4 — D-08's constraint stands; its worked example is replaced.**
>
> D-08 says the normalisation script principally repairs swapped `artist`/`album`. **That defect is
> not present in this data.** All 764 files in Phase 1's `dj-mixes` ffprobe fence (SAFE-03) were
> measured: `album` carries a correct-ish issue string in **657 of 764**, while `artist` is a
> placeholder (`Mastermix` 197, `VA` 160, `Various Artists` 138, missing 77, `Various` 20), and
> **107 files have no `album` at all** — which `beetsplug/discogs`' own documentation says means
> *no query is issued whatsoever*. `03-SAMPLE.md` § *Corrections this survey supersedes* confirms
> the same reading independently.
>
> The three measured rules below replace the example. **D-08's constraint is unchanged**: minimum
> viable, `--dry-run` mode, committed under `scripts/`, and explicitly **not** the DJCC-01
> field-mapping tool — that is v2 and the lowest-confidence research area in the project.

---

## Where it ran, and why not on the host

`scripts/normalise-dj-tags.py` runs **inside a container**, which no other script in `scripts/`
does. **OD-6** is the reason and it was measured, not assumed: LXC 100 has `python3` 3.13.5 but no
`pip3`, no `python3-venv`, `import ensurepip` raises `ModuleNotFoundError` (so `python3 -m venv`
cannot work at all) and `/usr/lib/python3.13/EXTERNALLY-MANAGED` is present (so PEP 668 blocks a
system pip install). `import mutagen` is impossible on the host. mutagen **1.48.1** is present in
the LSIO beets image as a beets dependency — confirmed at run time,
`docker exec beets-spike python3 -c 'import mutagen'` on Python 3.12.14.

| Step | Service | `normalised/` mount mode |
|---|---|---|
| Dry run | `beets-spike` | **`RW=false`** — asserted from `docker inspect` |
| `--apply` | `beets-spike-rw` | `RW=true` — the single writer arm, up for this step only |
| Everything downstream (03-06, 03-07, 03-10) | `beets-spike` | `RW=false` |

The dry run was deliberately run on the read-only service. **A dry run that is not dry is not
merely detectable here — it is impossible**: a write would have failed `EROFS` rather than
succeeding quietly and being caught afterwards by a check that might not have looked at that file.
`raw/` is `RW=false` on **both** services, so the paired arm's survival is a property of the mount
table rather than of the script's good behaviour.

---

## The three rules, and the one place the plan's wording was not followed

| # | Trigger (data-driven, not stratum-driven) | Action | Stratum it is aimed at |
|---|---|---|---|
| 1 | `album` empty or missing | derive `<Label> <Series> <NNN>` from the containing folder name, sanitised | V3 |
| 2 | `album` present and changes under canonicalisation | strip trailing ` WEB`, trailing ` - Disc N`, `Vol.` noise, `_` → space, collapse and trim whitespace, normalise the `Label - ` separator | V5 |
| 3 | any `artist` missing in the folder, **or** any `artist` inside beets' `VA_ARTISTS` | set every file in the folder to one consistent value chosen by `--artist-policy` | V2, V4 |
| 4 | — | **touch nothing else** | — |

**Deviation from the plan's literal rule-2 wording, stated rather than buried.** The plan says
*"strip … a leading `Mastermix - ` prefix"*. Applied literally, `Mastermix - Issue 410` becomes
`Issue 410`, which is **not** the form rule 1 derives (`Mastermix Issue NNN`) and is a hopelessly
generic Discogs query. The two halves of the sample would then carry two different album shapes
into the same measurement. What is actually noise is the **separator**, so the separator is what is
removed: `Mastermix - Issue 410` → `Mastermix Issue 410`. Rules 1 and 2 now share one canonical
target form. The same handling is applied to `DMC - `, by the same logic that gives rule 1 "or the
analogous DMC form".

`Vol.` noise is matched as `\bVol\.?\s*(?=\d)` — the digit lookahead is load-bearing. Without it
the pattern eats the `Vol` out of a legitimate `Volume 5` and leaves `ume 5`.

---

## Dry-run result

`docker exec beets-spike python3 …/normalise-dj-tags.py /mnt/tank/downloads/spike-03/normalised
--out /mnt/fast/spike-03/out/normalise-dryrun.ndjson`

| Quantity | Value |
|---|---|
| Exit code | **0** |
| Folders seen / files seen | **24** / **335** — exactly the draw |
| Files that would change | **205** |
| Files unchanged | **130** |
| NDJSON records (one per file × field) | **292** |
| Failure ledger (`.failed`) | **0 lines** |
| Files skipped | **0** |
| Elapsed | 7.7 s |

### Per-rule hit counts against the strata that should fire

`jq -s 'group_by(.rule) | map({rule: .[0].rule, n: length})'` returns `1 → 30`, `2 → 155`,
`3 → 107`.

| Rule | Expected stratum | Folders it fired on | Verdict |
|---|---|---|---|
| 1 — derive `album` | V3 | `VA-Mastermix.Crate.071.Afro.House-2025` (20), `VA-Mastermix.Issue.446-202` (10) | **subset of V3, and it is all of V3** — the sample draws exactly 2 V3 folders and both fired |
| 2 — canonicalise `album` | V5 | all **6** V5 folders (88 files) **plus 7 V2 folders** (67 files) | **not a subset.** Explained below |
| 3 — consistent `artist` | V2 ∪ V4 | all **9** V2 folders (87 files) **plus 2 folders outside V2 ∪ V4** (20 files) | **not a subset.** Explained below |

Full per-rule, per-folder breakdown, verbatim from `jq -r '[.rule, .folder] | @tsv' | sort | uniq -c`:

| Rule | Folder | Files | `03-SAMPLE.md` stratum | In expected set? |
|---|---|---|---|---|
| 1 | `VA-Mastermix.Crate.071.Afro.House-2025` | 20 | V3 | yes |
| 1 | `VA-Mastermix.Issue.446-202` | 10 | V3 | yes |
| 2 | `Mastermix_Issue_410` | 10 | V5 | yes |
| 2 | `Mastermix_Issue_410.1` | 10 | V5 | yes |
| 2 | `Mastermix_Issue_418_April_2021` | 10 | V5 | yes |
| 2 | `VA-Mastermix-Issue.Vol.451-202` | 10 | V5 | yes |
| 2 | `VA-DMC-Essential.Hits.233-WEB-2024-MST` | 24 | V5 | yes |
| 2 | `VA-DMC-Essential.Hits.234-WEB-2024-MST` | 24 | V5 | yes |
| 2 | `Mastermix_Issue_413` | 10 | **V2** | **no — see finding 1** |
| 2 | `VA-Mastermix-Issue.457-WEB-2024-MST` | 10 | **V2** | **no — see finding 1** |
| 2 | `VA-Mastermix-Issue.458-WEB-2024-MST` | 10 | **V2** | **no — see finding 1** |
| 2 | `VA-Mastermix-Issue.459-WEB-2024-MST` | 10 | **V2** | **no — see finding 1** |
| 2 | `VA-Mastermix-Issue.461-WEB-2024-MST` | 10 | **V2** | **no — see finding 1** |
| 2 | `VA-DMC-Commercial.Collection.498-WEB-2024-MST` | 9 | **V2** | **no — see finding 1** |
| 2 | `VA-DMC-Commercial.Collection.499-WEB-2024-MST` | 8 | **V2** | **no — see finding 1** |
| 3 | `Mastermix.Issue.421.2021` | 10 | V2 | yes |
| 3 | `Mastermix_Issue_413` | 10 | V2 | yes |
| 3 | `Mastermix_Issue_415` | 10 | V2 | yes |
| 3 | `VA-Mastermix-Issue.457-WEB-2024-MST` | 10 | V2 | yes |
| 3 | `VA-Mastermix-Issue.458-WEB-2024-MST` | 10 | V2 | yes |
| 3 | `VA-Mastermix-Issue.459-WEB-2024-MST` | 10 | V2 | yes |
| 3 | `VA-Mastermix-Issue.461-WEB-2024-MST` | 10 | V2 | yes |
| 3 | `VA-DMC-Commercial.Collection.498-WEB-2024-MST` | 9 | V2 | yes |
| 3 | `VA-DMC-Commercial.Collection.499-WEB-2024-MST` | 8 | V2 | yes |
| 3 | `Mastermix_Issue_418_April_2021` | 10 | **V5** | **no — see finding 2** |
| 3 | `VA-Mastermix.Issue.446-202` | 10 | **V3** | **no — see finding 3** |

### Finding 1 — V2 and V5 are not disjoint in the data, and the survey assigns one stratum per folder

Seven of the nine V2 folders **also** carry a V5-shaped album. `VA-Mastermix-Issue.458-WEB-2024-MST`
is the clearest case: `artist="VA"` (the V2 test) **and** `album="Mastermix - Issue 458 WEB"` (two of
V5's six noise markers). `spike03-variant-survey.sh` assigns exactly one stratum per folder in a
fixed test order and V2 is tested before V5, so the folder is recorded V2 and its V5-ness is
invisible in the census.

**This is a property of the classification, not a rule misfire.** The rules are data-driven — rule 2
fires when the album is noisy, whoever else is looking at that folder — and the plan's
subset-of-V5 expectation implicitly assumed the strata partition the *defects* rather than the
*folders*. They partition the folders.

It matters to plan 03-07 in a specific, bounded way: **the V2 per-stratum rate that 03-07 multiplies
by `backlog_weight` 0.2708 is not measuring the artist rule alone.** Seven of nine V2 folders had
their album canonicalised in the same pass. V2's measured lift is the joint effect of rules 2 and 3;
it cannot be attributed to rule 3 alone without a further arm. Named here so 03-07 does not
attribute it silently.

### Finding 2 — `Mastermix_Issue_418_April_2021` is V4-shaped and classified V5

All ten files have **no `artist` frame at all** — which is V4's definition (`artist` absent, 77 files
in the fence) — *and* `album="Mastermix - Issue 418"`, which is V5. The survey tests V5 before V4 and
records V5. Rule 3's trigger (`any artist missing in the folder`) is exactly V4's test, so it fires.

This is the rule behaving correctly on a folder whose stratum label understates its defects.
`03-SAMPLE.md` records V4's `backlog_weight` as **0.0000** — V4 exists once, in `dj-mixes`, and
nowhere in the deduplicated backlog — so this does not perturb the roll-up. It does mean the sample
carries one V4-shaped folder despite the draw table showing `V4 → 0`.

### Finding 3 — `VA-Mastermix.Issue.446-202` is two folders wearing one name

Its 20 files split cleanly in half and the two halves are unrelated in tag state:

| Half | `artist` | `album` | Rule that fires |
|---|---|---|---|
| 10 files | `Mastermix` | `Mastermix Issue 446` | **none** — already canonical |
| 10 files | `Various` | *(missing)* | rule 1 (derive) **and** rule 3 (artist) |

`Various` is inside `VA_ARTISTS`, so rule 3's trigger fires for the folder; the ten already-correct
files compare equal to the chosen value and are left alone, which is the idempotence property doing
its job rather than a second rule. The folder is classified V3 on the strength of the ten
album-less files.

**No rule fired on any V1 or V6 folder.** That is the strongest single line in this table: V1 is
defined as the case needing nothing, V6 as real per-track artists with clean albums, and the rules
left all twelve of those folders (120 files) untouched. Had rule 2 fired on a V1 folder it would
have meant the canonicalisation was too eager; had rule 3 fired on V6 it would have meant real
per-track artists were being flattened. Neither happened.

---

## The artist-policy choice

**Rule 3 sets `artist` to the DJ service label — `Mastermix` or `DMC`, derived from the folder's
canonical album — and that is `--artist-policy label`, the recorded default.**

The mechanism, from primary source at beets 2.13.1:

```python
# beets/autotag/distance.py
VA_ARTISTS = ("", "various artists", "various", "va", "unknown")

# beets/autotag/match.py  tag_album()
va_likely = ((not consensus["artist"]) or (search_artist.lower() in VA_ARTISTS)
             or any(item.comp for item in items))

# beetsplug/discogs/__init__.py  get_search_query_with_filters()
query = f"{artist} {name}" if va_likely else name
```

| Policy | Value written | Inside `VA_ARTISTS`? | `va_likely` | Discogs query for `VA-Mastermix-Issue.457-WEB-2024-MST` |
|---|---|---|---|---|
| **`label` (chosen)** | `Mastermix` | no | **false** | `Mastermix Issue 457` |
| `various` | `Various Artists` | yes | true | `Various Artists Mastermix Issue 457` |
| `keep` | *(unchanged)* | — | true, via `VA` | `VA Mastermix Issue 457` |

`label` was chosen because it is the only one of the three that sends **the canonical release string
and nothing else**. `03-RESEARCH.md` § *Headline finding 4* names V1 — `artist="Mastermix"`,
`album="Mastermix Issue NNN"` — as *"already the good case (`va_likely=false` → query = album
alone)"*, and rule 3 under `label` is precisely the transformation that turns V2 and V4 into V1.
`CLAUDE.md` § *Autotagging ceiling* records Discogs resolving `Mastermix Issue 430` and
`DMC Commercial Collection 350` **as album strings**, which is the shape `label` produces.

Two consequences, recorded because plan 03-07 reads them:

1. **The policy is a re-runnable experimental parameter, not a hard-coded assumption.** `--apply
   --artist-policy various` over `raw/`-refreshed copies is a one-flag second arm if 03-07 wants
   the counterfactual. Every NDJSON record carries its `artist_policy`, so a result set cannot be
   read without knowing which arm produced it.
2. **Consensus is the point, not the value.** A folder holding seven `Va` and one `Massive Attack`
   has no `consensus["artist"]` at all, so `va_likely` is true whatever the modal value is. Rule 3
   only achieves `va_likely=false` by writing the **same** value to every file in the folder.

### The cost of consensus: three real per-track artists are overwritten

```
…/VA-DMC-Commercial.Collection.498-…/06_inner_life_fe._jocelyn_brown_-… :: artist: Inner Life Fe. Jocelyn Brown -> DMC
…/VA-DMC-Commercial.Collection.498-…/08_massive_attack_-_teardrop_… :: artist: Massive Attack -> DMC
…/VA-DMC-Commercial.Collection.499-…/05_corrs_-_breathless_… :: artist: Corrs -> DMC
```

Those three files carry a genuinely correct per-track artist and rule 3 replaces it, because the
other 14 files in the same two folders carry `Va`. This is stated rather than glossed: it is a real
loss of accurate metadata, on three files, in exchange for the folder-level consensus the Discogs
query needs. It is acceptable **only** because these are reflinked copies — the originals are intact
in `raw/` (asserted below) and in `complete/nzb/`, and the artist name is also in the filename.

If plan 03-07 finds these two folders match on Discogs, the match was bought partly with this
trade; if a later phase productionises rule 3, this is the case that needs a per-file exemption.

---

## Sample diff

Twenty-six lines, verbatim from `normalise-dryrun.stdout`, drawn across every stratum on which any
rule fired. Paths are abbreviated at `…/normalised/` only; nothing else is edited.

```
…/VA-Mastermix.Crate.071.Afro.House-2025/&Me, Rampa, Adam Port, Alan Dixon, Keinemusik Feat. Arabic Piano - Thandaza 123.mp3 :: album: <MISSING> -> Mastermix Crate 071
…/VA-Mastermix.Crate.071.Afro.House-2025/Adam Port & Stryv Feat. Malachiii X Keinemusik - Move 120.mp3 :: album: <MISSING> -> Mastermix Crate 071
…/VA-Mastermix.Issue.446-202/80s Rewind New Romantics - Various.mp3 :: album: <MISSING> -> Mastermix Issue 446
…/VA-Mastermix.Issue.446-202/80s Rewind New Romantics - Various.mp3 :: artist: Various -> Mastermix
…/Mastermix_Issue_410/Mastermix - 4-Play 80s Groove To Dance.mp3 :: album: Mastermix - Issue 410 -> Mastermix Issue 410
…/Mastermix_Issue_410/Mastermix - Cool Cuts August 2020.mp3 :: album: Mastermix - Issue 410 -> Mastermix Issue 410
…/Mastermix_Issue_418_April_2021/Mastermix Big Room Anthems  Contains Expletives .mp3 :: album: Mastermix - Issue 418 -> Mastermix Issue 418
…/Mastermix_Issue_418_April_2021/Mastermix Big Room Anthems  Contains Expletives .mp3 :: artist: <MISSING> -> Mastermix
…/VA-Mastermix-Issue.Vol.451-202/01 - 10 Of The Best [90's House] [House] [Mastermix Issue] 6A 122.mp3 :: album: Mastermix - Issue Vol.451  -> Mastermix Issue 451
…/VA-Mastermix-Issue.Vol.451-202/02 - After Midnight [Rock] [Mastermix Issue] 9A 124.mp3 :: album: Mastermix - Issue Vol.451  -> Mastermix Issue 451
…/VA-DMC-Essential.Hits.233-WEB-2024-MST/01_anitta_-_fria_(felix_jaehn_remix)_128-mst.mp3 :: album: DMC - Essential Hits 233 WEB -> DMC Essential Hits 233
…/VA-DMC-Essential.Hits.233-WEB-2024-MST/02_bingo_players_and_disco_fries_ft_fatman_scoop_-_our_house_130-mst.mp3 :: album: DMC - Essential Hits 233 WEB -> DMC Essential Hits 233
…/Mastermix_Issue_413/Various Artists - 10's Dance Retro Mix.mp3 :: album: Mastermix - Issue 413 -> Mastermix Issue 413
…/Mastermix_Issue_413/Various Artists - 10's Dance Retro Mix.mp3 :: artist: Various Artists -> Mastermix
…/VA-Mastermix-Issue.457-WEB-2024-MST/01_va_-_chart_hits_457-mst.mp3 :: album: Mastermix Issue 457 WEB -> Mastermix Issue 457
…/VA-Mastermix-Issue.457-WEB-2024-MST/01_va_-_chart_hits_457-mst.mp3 :: artist: VA -> Mastermix
…/VA-Mastermix-Issue.458-WEB-2024-MST/01_va_-_chart_hits_458-mst.mp3 :: album: Mastermix - Issue 458 WEB -> Mastermix Issue 458
…/VA-Mastermix-Issue.458-WEB-2024-MST/01_va_-_chart_hits_458-mst.mp3 :: artist: VA -> Mastermix
…/Mastermix.Issue.421.2021/01. Mastermix - Club Cuts.mp3 :: artist: Various Artists -> Mastermix
…/Mastermix.Issue.421.2021/01. Mastermix - The Ibiza Sessions (Balearic Beats).mp3 :: artist: Various Artists -> Mastermix
…/Mastermix_Issue_415/101 Club Beats.mp3 :: artist: Various Artists -> Mastermix
…/Mastermix_Issue_415/102. Cool Cuts Nu Disco.mp3 :: artist: Various Artists -> Mastermix
…/VA-DMC-Commercial.Collection.498-WEB-2024-MST/01_va_-_dance_chart_dmc498_-_part_01-mst.mp3 :: album: DMC - Commercial Collection 498 WEB -> DMC Commercial Collection 498
…/VA-DMC-Commercial.Collection.498-WEB-2024-MST/01_va_-_dance_chart_dmc498_-_part_01-mst.mp3 :: artist: Va -> DMC
…/VA-DMC-Commercial.Collection.499-WEB-2024-MST/01_va_-_rock_the_dance_floor_dmc499-mst.mp3 :: album: DMC - Commercial Collection 499 WEB -> DMC Commercial Collection 499
…/VA-DMC-Commercial.Collection.499-WEB-2024-MST/01_va_-_rock_the_dance_floor_dmc499-mst.mp3 :: artist: Va -> DMC
```

The distinct transitions across all 292 records, with counts:

| Count | Transition |
|---|---|
| 40 | `artist: VA -> Mastermix` |
| 30 | `artist: Various Artists -> Mastermix` |
| 24 | `album: DMC - Essential Hits 234 WEB -> DMC Essential Hits 234` |
| 24 | `album: DMC - Essential Hits 233 WEB -> DMC Essential Hits 233` |
| 20 | `album: Mastermix - Issue 410 -> Mastermix Issue 410` |
| 20 | `album: <MISSING> -> Mastermix Crate 071` |
| 14 | `artist: Va -> DMC` |
| 10 | `artist: Various -> Mastermix` |
| 10 | `artist: <MISSING> -> Mastermix` |
| 10 | `album: Mastermix Issue 461 WEB -> Mastermix Issue 461` |
| 10 | `album: Mastermix Issue 459 WEB -> Mastermix Issue 459` |
| 10 | `album: Mastermix Issue 457 WEB -> Mastermix Issue 457` |
| 10 | `album: Mastermix - Issue Vol.451  -> Mastermix Issue 451` |
| 10 | `album: Mastermix - Issue 458 WEB -> Mastermix Issue 458` |
| 10 | `album: Mastermix - Issue 418 -> Mastermix Issue 418` |
| 10 | `album: <MISSING> -> Mastermix Issue 446` |
| 9 | `album: DMC - Commercial Collection 498 WEB -> DMC Commercial Collection 498` |
| 8 | `album: DMC - Commercial Collection 499 WEB -> DMC Commercial Collection 499` |
| 5 | `album: Mastermix - Issue 413 -> Mastermix Issue 413` |
| 5 | `album: Mastermix - Issue 413  -> Mastermix Issue 413` (trailing space) |
| 1 | `artist: Massive Attack -> DMC` |
| 1 | `artist: Inner Life Fe. Jocelyn Brown -> DMC` |
| 1 | `artist: Corrs -> DMC` |

The two `Mastermix - Issue 413` rows differing only by a trailing space are worth keeping visible:
`Mastermix_Issue_413` carries the **same album with and without a trailing space on five files
each**, which is exactly the kind of split that produces two Discogs queries from one folder.

---

## The dry run wrote nothing — two instruments over the whole subtree

A `find -newer` plus a handful of spot hashes is the weakest evidence in this phase: it passes a
tool that preserves mtimes, and it passes any write that lands outside the sampled files. The
five-file spot check is **not** used here.

| Instrument | `normalised/` | `raw/` |
|---|---|---|
| 1 — `find <subtree> -newer /mnt/fast/spike-03/out/.dryrun-stamp -type f` | **0 lines** | **0 lines** |
| 2 — `diff` of before/after `%p\t%s\t%T@` subtree manifest (`.meta`) | **empty** | **empty** |
| 2 — `diff` of before/after `sha256sum` subtree manifest (`.sha`) | **empty** | **empty** |

Both manifests cover **364 files per subtree** — the 335 audio files plus the 29 non-audio entries
(20 `.nfo`, 4 `.m3u`, 4 `.sfv`, 1 `.rtf`) that a rules-only check would never have looked at. They
live under `/mnt/fast/spike-03/out/manifests/`.

Structural backstop, which is the stronger of the two arguments: the dry run executed on
`beets-spike`, where `docker inspect` reports `normalised RW=false` and `raw RW=false`. A write
would have failed `EROFS`.

---

## What is deliberately NOT changed

| Field | Frames present in this sample (BEFORE) | Why it is left alone |
|---|---|---|
| `title` | `TIT2` ×335 | Not needed to make a Discogs query valid. D-08 scope |
| `track` | `TRCK` ×225, `TPOS` ×130 | Same. A wrong track number is a `beet import -t` finding, not a normalisation one |
| `date` | `TDRC` ×280 | Same — and the ID3 version pin exists specifically so this field cannot move as a side effect |
| `genre` | `TCON` ×285 | Same |
| **`TKEY`** | **×40** | **Phase 1's irreplaceable fence.** Harmonic-mixing key, not recoverable from any online source |
| **`EnergyLevel`** | inside `TXXX` ×110 | Same. DJ-added, not recoverable |
| everything else | `GEOB` ×295, `COMM` ×245, `APIC` ×230, `TPE2` ×180, `TBPM` ×110, `TENC`/`TLAN` ×105, `TCOP` ×50, `TCOM`/`TPE4`/`TPUB` ×40, `TIT3` ×30, `WOAR` ×20, `TSOA`/`TSSE` ×10 | mutagen writes preserve every frame it is not asked to set |

The 148 `TKEY` and 45 `EnergyLevel` figures D-08 quotes are across the whole 764-file `dj-mixes`
fence; **40 `TKEY` and 110 `TXXX`** is this 335-file sample's own share, measured directly on the
BEFORE side. They survived: `FIELDS_DROPPED = 0`, and the whole-tree frame-ID comparison below
shows every `TKEY` and `TXXX` frame still present.

The enforcement is structural rather than by discipline. `WRITABLE_FIELDS = ("album", "artist")` is
a frozen constant, `FIELD_FRAME` maps only those two to `TALB` and `TPE1`, and `write_tags()` raises
`AssertionError` on any other field before it touches the file. No rule in the code reads or writes
any of the fields in the table above — the module docstring is the only place they are named, and
only to say so.

---

## Three corrections found by applying, and why the tree was re-materialised

The first `--apply` was **not** clean, and the way it was not clean is the most transferable thing
in this document. `diff-music-tags.sh` exited **1** with `MISSING_AFTER: 37` — 37 files apparently
lost — while `FIELDS_DROPPED` was **0**. Nothing had been lost at all. Chasing that discrepancy
turned up **three** separate ways `mutagen` writes more than it is asked to, none of which the
plan's own gate could see.

**mutagen does not write back what it read.** It re-serialises its own normalised in-memory model
of the tag, and three of its defaults quietly broaden the write:

| # | Default | What it did | How it was found | How it is now prevented |
|---|---|---|---|---|
| 1 | `ID3.save(v1=UPDATE)` regenerates the whole 128-byte ID3v1 block from the ID3v2 frames | moved `audio_md5` on **37 of 335** files | `diff-music-tags.sh` exit 1, then a byte comparison against the `raw/` twin | the pre-write ID3v1 block is restored **byte-for-byte** after every save |
| 2 | `ID3.load(load_v1=True)` merges the ID3v1 tag into the ID3v2 frame set as a synthetic `COMM:ID3v1 Comment:eng` frame | **107 of 335** files gained an `ID3v1 Comment` key, and the frame was written to disk | frame-header dump: `raw/` has **one** COMM frame and padding at offset 183, the written file has **two** and padding at 225 | `load_v1=False` |
| 3 | `v2_version` is a **load-time** option; the default `4` translates `TYER`/`TDAT`/`TIME` to `TDRC` in memory, and `save(v2_version=3)` does **not** undo it | a `TYER` frame of 5 bytes came back as a `TDRC` frame of 6 — a v2.4-only frame ID inside a v2.3 tag | the same frame-header dump | `v2_version` is set at **load**, from the major version read out of the file's own 10-byte header |

Defect 3 is the one worth carrying furthest: **`ffprobe` maps both `TYER` and `TDRC` to `date`, so
`diff-music-tags.sh` reported nothing at all.** The phase's own field-loss gate is blind to it. It
was found only because defect 1 forced a byte-level look at the file.

Defect 1 is a finding about the *instrument*, not about the write, and it is logged as
**DEF-03-03** in [`deferred-items.md`](deferred-items.md) rather than fixed:
`snapshot-music-tags.sh:35` claims its key *"hashes the ENCODED AUDIO BITSTREAM ONLY"*, and it does
not — ffmpeg's mp3 demuxer emits the trailing ID3v1 bytes as part of the `-c copy` stream on some
files. All 37 movers carry an ID3v1 trailer; **0** of them do not; and with the last 128 bytes
removed, every mover's md5 matches its untouched `raw/` twin exactly. The audio was never touched:
with the ID3v2 tag and the last 128 bytes excluded, `cmp` against the `raw/` twin returns **zero**
differing bytes on every file examined.

**Because a fourth such default is exactly the shape that had now recurred three times, the script
gained a backstop rather than only a fix.** `assert_frame_set_unchanged()` re-parses the ID3v2 tag
off disk **without mutagen** after every write and requires the frame-ID multiset to equal what it
was plus the frames this script wrote. Frame encodings and sizes may move — mutagen NUL-terminates
latin-1 text, which is legal and harmless; frame *identity* may not. A violation is a hard failure
into the `.failed` ledger, not a silently larger diff. It fired **0** times on the final run.

**The tree was re-materialised from `raw/` between attempts**, on atlantis, by the same
`cp -r --reflink=always --preserve=timestamps` + `chown 568:568` route plan 03-03 documented
(`FICLONE` is `EPERM` inside the unprivileged container). `raw/` is `:ro` on both services and was
verified byte-identical to `normalised/` immediately after each re-materialisation, so every
attempt started from a provably un-normalised tree and **every number below comes from one clean
invocation**, not from a patched-up state.

> **A bind mount pins the directory INODE, not the path.** Re-materialising `normalised/` left
> `beets-spike` bound to the deleted inode, and its next dry run reported *"folders seen: 0, files
> seen: 0"* and exited **0**. A vacuous pass, on the phase's primary measurement container. It was
> caught here because 0 is an obviously wrong answer — but plans 03-06, 03-07 and 03-10 all measure
> *rates*, where "0 candidates" is a plausible-looking result that would falsify T1 on an artefact.
> `beets-spike` was force-recreated and re-verified: **335** mp3 visible, `normalised RW=false`, and
> all four plugins loading (`discogs, fromfilename, importsource, musicbrainz`) on
> `beet … version` — the 03-04 instrument, not a `config -d` block.

---

## Applied

```
ssh -o BatchMode=yes -o ConnectTimeout=5 root@172.16.1.158 \
    'zfs list -t snapshot -H -o name tank/downloads@spike-03-t0'  >> snapshot-proof.txt
docker compose -f 03-spike-beets.yaml --profile manual up -d beets-spike-rw
docker exec beets-spike-rw python3 …/normalise-dj-tags.py …/normalised --apply \
    --snapshot-proof …/snapshot-proof.txt --out …/normalise-apply.ndjson
docker compose -f 03-spike-beets.yaml --profile manual rm -sf beets-spike-rw
```

| Property | Value |
|---|---|
| Snapshot proof | `tank/downloads@spike-03-t0` — present |
| **Route** | **`ssh:172.16.1.158`** (atlantis), captured `2026-09-03T21:55:47Z` |
| Apply exit code | **0** |
| Folders / files seen | **24** / **335** |
| **Files changed** | **205** |
| Files unchanged | **130** |
| Rule 1 / 2 / 3 hits | **30** / **155** / **107** — identical to the dry run |
| Records with `written: false` | **0** |
| Files skipped | **0** |
| **Failure ledger** | **0 lines** — dry run, apply and idempotence run, all three |
| Frame-set assertion failures | **0** |
| Elapsed | 13.99 s |
| Writer arm up → removed | `22:26:47Z` → `22:27:03Z`, **16 seconds** |
| `beets-spike-rw` in `docker ps -a` afterwards | **absent** |

**The dry run was an exact prediction of the apply.** Sorting both NDJSON outputs on
`(path, field, rule, old, new)` and hashing gives
`9b7e1799a2b14fe0969f82ea6e43579a74d92d7b8dc8fd8bae4aea11b2ab7271` for **both**. Not "the same
counts" — the same 292 rows, byte for byte. That is what makes the reviewed dry run a review of
what actually happened rather than of something adjacent to it.

**Idempotence, as a genuine second `--apply` rather than an inference.** Immediately after the
write, through the same writer arm, over the same tree: exit **0**, **0** files changed, **0**
NDJSON records, **0** stdout lines, **0** failures. Every rule is a fixed point on its own output.

---

## Field-loss verdict

`bash scripts/diff-music-tags.sh /mnt/fast/spike-03/out/spike03-before.ndjson.gz
/mnt/fast/spike-03/out/spike03-after.ndjson.gz`

The AFTER side was captured with `bash scripts/snapshot-music-tags.sh spike03-after --roots
/mnt/tank/downloads/spike-03/normalised` — 335 files seen, 335 records written, 0 failed.

| Category | Count | Gate |
|---|---|---|
| MATCHED | **306** | — |
| **MISSING_AFTER** | **0** | **gate: must be 0** |
| NEW_AFTER | **0** | — |
| **FIELDS_DROPPED** | **0** | **gate: must be 0** |
| FIELDS_GAINED | **35** | `album` 25, `artist` 10 |
| FIELDS_CHANGED | **237** | `album` 145, `artist` 92 |
| Matched files whose BEFORE tag set was empty | **0** | the vacuous-pass guard did not fire |
| **`diff-music-tags.sh` exit code** | **0** | its own contract: 0 = no net metadata loss |

**The set of changed field names is exactly `{album, artist}`, and so is the set of gained names**
— asserted on the tool's own `--json` parsed category output, not by grepping its prose. Nothing
was dropped.

`MATCHED` is 306 rather than 335 because the tool keys on `audio_md5` and the draw deliberately
contains **two near-duplicate pairs** (`Mastermix_Issue_410` / `_410.1` and
`VA-Mastermix.Issue.426-2021` / `.1`), collapsing 29 records. `duplicate_keys_before` and
`duplicate_keys_after` are both **29** — `diff-music-tags.sh:22-24, 267-276` classifies those as
informational and they do not affect the exit code. **Expected, not a bug.**

**The vacuous-pass guard did not fire**, and it had real work to do. `diff-music-tags.sh:288-292`
warns when every matched file had zero tag fields on the BEFORE side, in which case "no fields
dropped" is vacuously true and the result must be read as **untested, not passed**; it exists
because 134 of `dj-mixes`' 764 files are WAV and carry no format tags. It is silent here because
**the draw contains zero WAV** — all 335 files are MP3, all ID3v2.3, carrying between them 295
`GEOB`, 285 `TCON`, 245 `COMM`, 230 `APIC`, 130 `TPOS`, 110 `TXXX`, 110 `TBPM` and **40 `TKEY`**
frames on the BEFORE side. There was a great deal there to drop. None of it was dropped.

### The same verdict, PATH-keyed, over all 335 files

Because `audio_md5` collapses the 29 duplicates — and because DEF-03-03 shows it is not
tag-invariant in general — the verdict was recomputed keyed on `source_path`, using
`diff-music-tags.sh`'s own `FLATTEN_JQ` so the flattening is identical. Path is a valid key here
and `audio_md5` is the questionable one, because **this plan renames nothing and moves nothing.**

| Quantity | Value |
|---|---|
| Matched | **335 of 335** |
| MISSING_AFTER / NEW_AFTER | **0** / **0** |
| **FIELDS_DROPPED** | **0** |
| Dropped field names | **none** |
| Gained field names | `album` **30**, `artist` **10** — and nothing else |
| Changed field names | `album` **155**, `artist` **97** — and nothing else |

Those numbers reconcile exactly with the rules: rule 1 creates 30 `album` frames where none
existed; rule 2 changes 155; rule 3 accounts for 107, of which 10 create an `artist` frame that was
absent and 97 change one that was present.

### Third instrument: the on-disk ID3v2 frame-ID multiset, parsed without mutagen

The strongest available statement of "touch nothing else", made against the untouched `raw/` twin
of every single file rather than against a capture:

| Assertion | Result |
|---|---|
| Files compared | **335** |
| ID3v2 major version, `raw/` → `normalised/` | **(3, 3) on all 335** — no file was promoted to v2.4 |
| Files whose frame-ID multiset differs from their `raw/` twin | **40** |
| The complete list of those differences | `TALB` 0 → 1 on **30** files · `TPE1` 0 → 1 on **10** files |

**Forty files differ, and the difference is the forty frames the rules were asked to create.** No
frame was removed anywhere, no frame ID changed anywhere, and no frame was added anywhere else —
including the `COMM:ID3v1 Comment` frame that the first attempt added to 107 files.

---

## Second instrument

`diff-music-tags.sh` reads a captured NDJSON. A live `ffprobe` reads the file on disk. If A and B
disagree, **neither number is recorded** until the disagreement is explained.

Five files, one for each stratum on which a rule fired, plus a **V1 control** on which no rule
should fire — captured live before the write and again after it:

| # | File | Stratum / rules | `album` before → after | `artist` before → after | Dropped | Gained | Changed | Tag keys |
|---|---|---|---|---|---|---|---|---|
| 1 | `VA-Mastermix.Crate.071…/&Me, Rampa, … - Thandaza 123.mp3` | V3, rule 1 | *(absent)* → `Mastermix Crate 071` | unchanged | none | `album` | none | 4 → 5 |
| 2 | `Mastermix_Issue_410/Mastermix - Cool Cuts August 2020.mp3` | V5, rule 2 | `Mastermix - Issue 410` → `Mastermix Issue 410` | `Mastermix` unchanged | none | none | `album` | 14 → 14 |
| 3 | `Mastermix_Issue_413/Various Artists - 10's Dance Retro Mix.mp3` | V2, rules 2+3 | `Mastermix - Issue 413` → `Mastermix Issue 413` | `Various Artists` → `Mastermix` | none | none | `album, artist` | 7 → 7 |
| 4 | `Mastermix_Issue_418_April_2021/Mastermix Big Room Anthems  Contains Expletives .mp3` | V5/V4-shaped, rules 2+3 | `Mastermix - Issue 418` → `Mastermix Issue 418` | *(absent)* → `Mastermix` | none | `artist` | `album` | 6 → 7 |
| 5 | `VA-DMC-Essential.Hits.233…/01_anitta_-_fria_…mp3` | V5, rule 2 | `DMC - Essential Hits 233 WEB` → `DMC Essential Hits 233` | `Anitta` unchanged | none | none | `album` | 9 → 9 |
| **C** | `Mastermix.Issue.420.2021/4200101 - Mastermix - Club Cuts.mp3` | **V1, control** | `Issue 420` unchanged | `Mastermix` unchanged | none | none | **none** | 16 → 16 |

Aggregated over all six, the only fields that moved at all are **`album` (5)** and **`artist`
(2)**. **6 of 6 agree with the diff**, and the control confirms the rules leave V1 alone.

File 1 is the one to look at twice: it **gained** an album derived from its folder name, and its
`tkey` and `tbpm` are both still present afterwards. That is rule 1 and rule 4 working on the same
file — the fence-protected DJ metadata survived the frame created beside it.

---

## `raw/` is untouched — the paired arm is intact

Criterion 1 is a **paired** comparison: the same 24 folders, normalised and un-normalised. If
`raw/` moves, the pair is gone and the comparison is not regenerable.

| Instrument | Result |
|---|---|
| `find /mnt/tank/downloads/spike-03/raw -newer …/snapshot-proof.txt -type f` | **0 lines** |
| `diff` of `raw.t3before.meta` / `raw.t3after.meta` (364 files) | **empty** |
| `diff` of `raw.t3before.sha` / `raw.t3after.sha` (364 files) | **empty** |
| The same two instruments across the dry run | **0 lines** / **empty** |
| `docker inspect beets-spike` — `raw` mount | **`RW=false`** |
| `docker inspect beets-spike-rw` — `raw` mount | **`RW=false`** |

The last two rows are the load-bearing ones: `raw/` is read-only on **both** services, so its
survival is a property of the mount table, not of the script's good behaviour. The script never had
to be trusted with it — which is also why re-materialising `normalised/` from it was safe.

---

## Health of the estate around the run

| Assertion | Result |
|---|---|
| `bash scripts/check-music-freeze.sh` | **exit 0** — `tagger-class writers: 0`, `unclassified writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` |
| Beets databases under `/mnt/fast/appdata` (`*.blb` **and** `library.db`, per DEF-03-02) modified after `beets-spike` was created | **0 of 4** |
| `.bak` files under `/mnt/fast/appdata/arrs` created in the same window | **0** |
| `/tmp` entries matching `spike` on LXC 100 | **0** |
| `df -h /` | **35 G free**, unchanged across the plan |
| `/mnt/fast/spike-03/out` footprint | **6.1 M**, 132 manifest files |
| Library entries newer than this plan started (`2026-09-03 21:40`), read from atlantis | **0** |
| Newest `ctime` anywhere in `/mnt/tank/media/Music` | **2026-08-18 22:43:54** — sixteen days before this plan ran |
| `zfs diff tank/media/Music@pre-project` from atlantis (route `ssh:172.16.1.158`) | **2,674 lines, every one `M`** — pre-existing, see below |

The four beets databases are dated 2025-10-27, 2025-11-18, 2026-08-18 and **2026-09-03 21:17:20**.
The last is sabnzbd's `library.blb`, and 21:17 is **before** this plan's first write and before
`beets-spike` was recreated at 22:24:53 — the same live post-processing path plans 03-04 and 03-08
both attributed. The decisive argument is again the mount table, not the clock: neither spike
container mounts `/mnt/fast/appdata` at any mode. `tagger-class writers: 0` carries the standing
**DEF-03-01** caveat — `check-music-freeze.sh`'s `TAGGER_PATTERN` cannot match `sabnzbd`, so for
that one tagger the counter is silence rather than a clean reading.

**`zfs diff` on the library does not return clean, and did not before this plan started.** Plan
03-03 established this in full: 2,674 is the exact entry count of the library, every line is `M`
with zero additions, removals or renames, and the modification is Phase 1 plan 01-08's `chown` to
`568:568`, which ran *after* `@pre-project` was taken. The verification line as written in the plan
is unsatisfiable and always was. Recorded as **pre-existing and not caused here**, not as a pass —
Phase 1 produced six unearned passes and this is not a seventh. The two independent readings that
make that a measurement rather than an assertion are in the table above: zero library entries newer
than the plan's start, and a newest `ctime` sixteen days old.
