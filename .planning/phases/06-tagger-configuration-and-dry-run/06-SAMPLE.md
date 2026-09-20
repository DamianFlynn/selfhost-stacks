# Phase 6 dry-run sample — the stratified, seeded draw

Companion to [`06-EXPECTED-TREE.txt`](06-EXPECTED-TREE.txt) (the committed pre-run oracle this
draw supplies the rows for) and to
[`stacks/selfhosted/arrs/beets/config.yaml`](../../../stacks/selfhosted/arrs/beets/config.yaml)
(the `paths:` stanza the oracle judges, committed in `d4fead8` **before** a single folder here was
classified).

Nothing here is applied by `docker compose`. This is the record of which folders Phase 6's dry run
measures on, why those and not others, and how the ten can be re-derived without re-running
anything.

State as of 2026-09-21 — **sample drawn, expected tree committed, nothing imported, nothing under
`/mnt/tank` written.**

> **The population, the stratum targets and the draw key were all fixed before any folder was
> classified**, which is the whole of D-26. The four shapes D-26 names — a multi-artist release
> (D-23 as amended by D-34), a multi-disc release (D-14), a compilation (D-15) and a *Now!* volume
> (criterion 5) — are strata S6, S2, S3 and S4 below, each with its target written down before the
> eligible set was known. Hand-picking was rejected for the reason D-26 gives: it proves the config
> works on cases chosen because the config works on them.

---

## Instruments

Three, all read-only, and the first two disagree in a way that had to be resolved before anything
could be drawn.

| Instrument | What it is | Used for |
|---|---|---|
| `tags/pre-project.ndjson.gz` (Phase 1 QUAL-01) | 9,736 ffprobe records, `audio_md5`-keyed, captured 2026-08-18 | the **cross-check on counts**, and nothing else — see the staleness finding below |
| a live `ffprobe` pass, 2026-09-21 | `-show_entries format=filename,size:format_tags`, no output path given so the read stays read-only | the folder inventory and the first-pass census |
| **`mediafile` inside `beets-flask`** (`/venv/bin/python`, beets 2.12.0) | beets' own tag reader, `MediaFile(path)` opened for read, `save()` never called | **the authoritative field view** — every stratum predicate below is evaluated on beets' own fields, not on an ffprobe key |

**Why the third instrument exists, stated rather than assumed.** A stratum predicate written
against an ffprobe tag key is a predicate about a *different quantity* from the one the `paths:`
queries test. The clearest case is `disctotal`: ffprobe reports `disc: "1/2"` and `disc: "1"`
identically enough that a naive reading calls both multi-disc, while beets reports `disctotal = 2`
for the first and `disctotal = None` (which the `disctotal:2..` query sees as `0`) for the second.
The first draw of this document used the ffprobe reading and selected a folder that beets' own
`disctotal:2..` rule would **not** have matched. It was replaced before anything was committed, and
the replacement is recorded in the reallocation table below rather than quietly swapped.

**The Phase 1 snapshot's paths are stale and the sample must not be drawn from them.** Measured:

| Scan root | records in the snapshot | paths that no longer resolve |
|---|---|---|
| `/mnt/tank/downloads/complete/nzb/unsorted` | 7,451 | **4,746** |
| `/mnt/tank/downloads/complete/nzb/music` | 277 | **44** |
| `/mnt/tank/downloads/complete/nzb/dj-mixes` | 764 | 0 |
| `/mnt/tank/media/Music` | 1,244 | 0 |

The 4,746 are exactly Phase 5's split of `VA-Now_That.s_What_I_Call_Music__1-115_2023` into 115
`Vol NNN` folders; the 44 are Phase 5's `_FAILED_` renames in `music`. The snapshot is therefore
kept as the **counting** instrument — the live pass reproduces `unsorted` 7,451, `dj-mixes` 764 and
`media/Music` 1,244 exactly — and is used for nothing else. `music` is the one root where the two
disagree on content and not just on names: the snapshot holds 277 files, the live pass 531, because
the tree has taken new downloads since 2026-08-18.

Machine-readable derivation output stays at the fence under `/mnt/fast/safety/phase06/`
(`fields.ndjson`, 9,990 records; `folders.ndjson`; `draw-a.json`; `audit.json`; the five scripts),
per [`03-SAMPLE.md:29-32`](../03-tagger-spike/03-SAMPLE.md). Only this Markdown draw and
`06-EXPECTED-TREE.txt` are committed, and task 2 of plan 06-05 states in that file itself why it is
the deliberate exception.

---

## The population, declared first

| Set | Path | Folders | Audio files | Used for |
|---|---|---|---|---|
| backlog — `unsorted`, excluding the *Now!* set | `/mnt/tank/downloads/complete/nzb/unsorted/` | 119 | 2,705 | S1 S2 S3 S7 |
| backlog — `music` | `/mnt/tank/downloads/complete/nzb/music/` | 43 | 531 | S1 S2 S3 S7 |
| the *Now!* `1-115` set | `…/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023/Vol NNN` | **115** | 4,746 | S4 only |
| DJ services | `/mnt/tank/downloads/complete/nzb/dj-mixes/` | 60 | 764 | S5 only |
| the real library | `/mnt/tank/media/Music/` | 70 | 1,244 | **S6 only**, and read-only (`:ro`, D-05) |
| **total inventoried** | | **407** | **9,990** | |

`119 + 115 = 234` folders under `unsorted` reconcile to the 120 top-level entries Phase 3 counted:
119 ordinary folders plus the *Now!* parent, whose 4,746 files now sit one level down.
`2,705 + 4,746 = 7,451`, which is Phase 1's figure exactly. `dj-mixes` at 60 folders / 764 files
reproduces Phase 3's census exactly.

**Exclusions, by name.**

- `/mnt/tank/downloads/mac-music-archive/` — **18,172 files, out of scope by decision** (CLAUDE.md
  § *Corrections after Phase 4*). It is not inventoried above and no predicate can reach it.
- `/mnt/tank/downloads/complete/nzb/_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}`
  — **staging, not population.** Measured now: `01-auto` 0 audio files, `02-review` 0, `03-asis` 0,
  `04-hold` **533**, `99-quarantine` **44**, `_done` 0. The 533 in `04-hold` are D-35's emptying of
  `02-review`; drawing from staging would sample the same content twice and would couple this draw
  to another plan's in-flight state.
- `nzb/{movies,tv,software,readarr}` — not music.

**The backlog denominator has moved and this document does not pretend otherwise.** CLAUDE.md
records 144 folders (`unsorted` 120 / 7,451 plus `nzb/music` 24 / 277), measured 2026-09-11. The
equivalent live figure today is **162 audio-bearing folders** (`unsorted` 119 + `music` 43), because
Phase 5 split the *Now!* set out of one folder into 115 and because `music` has taken new
downloads. Both numbers are right about the day they were taken. Phase 6 draws a stratified sample
and computes no population rate, so nothing here depends on which denominator is used; the figure is
stated so it is not silently inherited by a later plan that *does* need a rate.

---

## The stratum targets, stated before the draw

| Stratum | Shape | Target | Serves |
|---|---|---|---|
| S1 | mainstream single-disc album, bucket A | 3 | CONF-03 baseline, CONF-06 |
| S2 | multi-disc release (`disctotal >= 2`) | 1 | D-14, pitfall 7 |
| S3 | various-artist compilation | 1 | D-15, CONF-03's `Various Artists/` not `Compilations/` |
| S4 | a *Now!* volume | 1 | criterion 5, CONF-05 |
| S5 | DJ-service folder from `dj-mixes/` | 2 | D-13, D-18 |
| S6 | multi-artist release carrying `;` in `ARTISTS` | 1 | D-23 as amended by D-34, CONF-04 write side |
| S7 | a folder that will resolve to singletons | 1 | D-19b |

**Every folder is assigned to exactly one stratum, by the first matching rule in this order:**
`S4 → S5 → S6 → S7 → S2 → S3 → S1`. The order is declared rather than alphabetical and it mirrors
the `paths:` stanza's own precedence: the config puts `singleton:` first, `disctotal:2..` **before**
`comp:` (so a multi-disc compilation still gets its disc prefix), and `default` last. A draw whose
stratum precedence disagreed with the rule precedence it is meant to exercise would silently send
a folder to a stratum whose path rule it never reaches.

The predicates, all evaluated on beets' own fields via the third instrument:

| Stratum | Predicate |
|---|---|
| S4 | folder is one of the 115 `Vol NNN` directories |
| S5 | folder is under `dj-mixes/` |
| S6 | library folder where at least one file carries `;` in `ARTISTS` or `ALBUMARTISTS`, and whose path does not contain `TRUSTFALL` |
| S7 | backlog folder with exactly one audio file, **or** where no file carries a non-empty `album` |
| S2 | backlog folder where **every** file has `disctotal >= 2` |
| S3 | backlog folder whose as-is album-artist guess resolves to **Various Artists** (see below) |
| S1 | backlog folder in `music/`, `>= 5` files, every file has an `album`, exactly one distinct `album` value, the as-is guess is single-artist and not a various-artists placeholder, and every file has `disctotal < 2` |

**The as-is album-artist guess is beets' own, replicated exactly, not approximated.**
`ImportTask.align_album_level_fields()` takes the plurality of `albumartist or artist` across the
items; if that value's frequency equals the item count, **or** exceeds 1 and is at least
`SINGLE_ARTIST_THRESH = 0.25` of the items, the album is single-artist and `comp` is false;
otherwise the album artist becomes `config['va_name']` and `comp` is true.
`[SOURCE: beets/importer/tasks.py@v2.12.0, read out of the running container]` S3 is defined on the
outcome of that rule rather than on an `albumartist` tag value, because the outcome is what decides
whether the `comp:` path rule fires at all.

---

## The draw mechanism — no random-number generator, and no randomising shell utility

**Sort key, stated so the ten folders can be re-derived without re-running anything:** within each
stratum the eligible folders are sorted by their **full folder path, byte-ordered with `LC_ALL=C`**
— locale-independent, because a locale-dependent collation is not reproducible across hosts — and
the first N are taken. In Python that key is `path.encode("utf-8", "surrogateescape")`, which is the
same byte ordering `LC_ALL=C sort` applies and which survives a path that is not valid UTF-8.

**The documented tie-breaker, unused here because no two full folder paths collided:** the `sha256`
of the folder's first `LC_ALL=C`-sorted file. Phase 3 named the same tie-breaker on `audio_md5`; the
change to `sha256` is only because Phase 6 has no `audio_md5` instrument of its own and a digest of
the whole file is strictly stronger.

Verbatim, against the fence:

```bash
FENCE=/mnt/fast/safety/phase06

# 1. the live tag pass — read-only, no output path given to ffprobe
python3 "$FENCE/phase06-live-tags.py" /mnt/tank/downloads/complete/nzb/unsorted > "$FENCE/live-unsorted.ndjson"
python3 "$FENCE/phase06-live-tags.py" /mnt/tank/downloads/complete/nzb/music    > "$FENCE/live-music.ndjson"
python3 "$FENCE/phase06-live-tags.py" /mnt/tank/downloads/complete/nzb/dj-mixes > "$FENCE/live-djmixes.ndjson"
python3 "$FENCE/phase06-live-tags.py" /mnt/tank/media/Music                     > "$FENCE/live-library.ndjson"
python3 "$FENCE/phase06-folders.py" "$FENCE"/live-*.ndjson > "$FENCE/folders.ndjson"

# 2. beets' OWN field view of every one of the 9,990 files, read inside the runtime
docker exec beets-flask /venv/bin/python /config/phase06-fields.py /config/phase06-folders.txt \
  > "$FENCE/fields.ndjson"

# 3. the draw itself — stratify, LC_ALL=C sort, head -n N per stratum
python3 "$FENCE/phase06-strata.py" "$FENCE/fields.ndjson" "$FENCE/s6-container.json" \
  > "$FENCE/draw-a.json" 2> "$FENCE/draw-a.log"
```

**Run twice and `diff`'d: identical, zero lines of difference**, 10 rows and the same 7 eligibility
counts both times (`draw-a.json` vs `draw-b.json`, `draw-a.log` vs `draw-b.log`). A draw that has
only ever been run once is not demonstrably deterministic.

**Two constraints on the S6 row, both honoured.** The row comes from the **`ARTISTS`-tag** set, not
from the `ARTIST`-delimited **`TRUSTFALL`** set — those six are plan 06-03's DO-NOT-RESCAN set and,
per OQ-1, their current reading is probably stale DB state; `TRUSTFALL` is excluded by an explicit
path test in the predicate, not by the sort happening to miss it. And the one false positive
research found — `…/14. Busta Rhymes Feat; Q-Tip , Kanye West & Lil Wayne - Thank You.mp3`, whose
`Feat;` is a typo rather than a delimiter — is in `unsorted`, is therefore outside S6's population
by construction (S6 is library-only), and is named here so the exclusion is a stated fact rather
than an accident of scope.

The S6 eligible set re-measured live is exactly the set 06-RESEARCH.md recorded: **6 files carrying
`;` in `ARTISTS`, across 3 albums** — `Katy Perry/Teenage Dream (2010)` ×1,
`Lady Gaga/ARTPOP (2013)` ×2, `P!nk/The Truth About Love (2012)` ×3 — plus the 6 `ARTIST`-delimited
`TRUSTFALL` files, which the predicate excludes.

---

## Per-stratum targets, eligibility and the reallocation

| Stratum | Target | Eligible | Drawn | Reason for the difference |
|---|---|---|---|---|
| S1 | 3 | 19 | **3** | target met |
| S2 | 1 | 12 | **1** | target met |
| S3 | 1 | 19 | **1** | target met |
| S4 | 1 | 115 | **1** | target met |
| S5 | 2 | 60 | **2** | target met |
| S6 | 1 | **3** | **1** | target met; the eligible set is only 3 albums estate-wide and that is a property of the library, not of the draw |
| S7 | 1 | 20 | **1** | target met |

No stratum underfilled, so no slot was reallocated and the drawn set is exactly the declared
targets. Two substitutions happened **inside** the derivation, before any commit, and both are
recorded here rather than left invisible:

| Substitution | Was | Became | Reason |
|---|---|---|---|
| S2's row | `…/music/Michael.Jackson.-.Gold.(2008).[FLAC].vtwin88cube-xpost` | `…/music/Michael.Jackson.-.The.Essential.Michael.Jackson.-.(2005).…-maladicta-xpost` | The first predicate read "multi-disc" off ffprobe's `disc` key. beets reports `disctotal` on the `Gold` folder as absent, so the `disctotal:2..` rule would **not** have matched it and S2 would have exercised nothing. The replacement has `disctotal = 2` on all 32 files in beets' own field view. |
| the population's tag instrument | Phase 1's `pre-project.ndjson.gz` | a live pass plus beets' `mediafile` | 4,746 of the snapshot's `unsorted` paths and 44 of its `music` paths no longer resolve after Phase 5. See § *Instruments*. |

**The `%aunique{}` rejection rule was armed and did not fire.** The draw carries a post-selection
guard: a candidate is rejected, and the next eligible row taken, if adding it would create an
ambiguous `(albumartist, album)` set that **no** `aunique.disambiguators` value separates — because
that is the case in which beets appends the numeric database id
`[SOURCE: beets/library/models.py@v2.12.0 _tmpl_unique]`, and a committed expected tree containing
one is a landmine. **Zero candidates were rejected** (`draw-a.json` → `"rejects": []`). One
ambiguous pair *was* drawn and is resolved by a real disambiguator; it is recorded under
§ *The predicted `%aunique{}` firing* below and in `06-EXPECTED-TREE.txt`'s header.

---

## The ten drawn folders

Every row tabulated with the attributes it was drawn on. `disctotal` and `disc` are **beets' own
fields**, not ffprobe keys; `album artist` gives the raw tag values first and then the value beets'
as-is guess produces, because the two differ on three of the ten rows and only the second one
reaches a path template.

| Folder | Stratum | Files | Extensions | `disctotal` | `disc` | Distinct `artist` | `albumartist` tag → as-is | `album` | `comp` |
|---|---|---|---|---|---|---|---|---|---|
| /mnt/tank/downloads/complete/nzb/music/Benson Boone-American Heart-24BIT-44KHZ-WEB-FLAC-2025-OBZEN-xpost | S1 | 10 | flac 10 | `{0}` | `{1}` | 1 | `Benson Boone` → `Benson Boone` | American Heart | false |
| /mnt/tank/downloads/complete/nzb/music/Benson.Boone.-.Fireworks.&.Rollerblades.(2024).[16Bit-44.1kHz].FLAC.[PMEDIA].⭐️-xpost | S1 | 15 | flac 15 | `{1}` | `{1}` | 1 | `Benson Boone` → `Benson Boone` | Fireworks & Rollerblades | false |
| /mnt/tank/downloads/complete/nzb/music/Benson_Boone_-_American_Heart-WEB-2025-BENSONBOONE | S1 | 10 | mp3 10 | `{1}` | `{1}` | 1 | `Benson Boone` → `Benson Boone` | American Heart | false |
| /mnt/tank/downloads/complete/nzb/music/Michael.Jackson.-.The.Essential.Michael.Jackson.-.(2005).[upc.827969428726].[FLAC.24-96]-maladicta-xpost | S2 | 32 | flac 32 | `{2}` | `{1,2}` | 4 | `Michael Jackson` → `Michael Jackson` | The Essential Michael Jackson | false |
| /mnt/tank/downloads/complete/nzb/music/Now_.That.s.What.I.Call.Music.121.2025.320kbps.MP3.InChY | S3 | 44 | mp3 44 | `{1}` | `{1}` | **39** | *(none)* → `Various Artists` | NOW That's What I Call Music! 121 | **true** |
| /mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023/Vol 001 | S4 | 30 | mp3 30 | `{2}` | `{1,2}` | 27 | `Various` → `Various` | Now That's What I Call Music! 1 | false |
| /mnt/tank/downloads/complete/nzb/dj-mixes/Mastermix.Issue.420.2021 | S5 | 10 | mp3 10 | `{0}` | `{1,2}` | 1 | `Mastermix` → `Mastermix` | Issue 420 | false |
| /mnt/tank/downloads/complete/nzb/dj-mixes/Mastermix.Issue.421.2021 | S5 | 10 | mp3 10 | `{0}` | `{0}` | 1 | `Various Artists` → `Various Artists` | Mastermix Issue 421 | false |
| /mnt/tank/media/Music/Katy Perry/Teenage Dream (2010) | S6 | 12 | flac 12 | `{1}` | `{1}` | 1 | `Katy Perry` → `Katy Perry` | Teenage Dream | false |
| /mnt/tank/downloads/complete/nzb/music/Cyril - Stumblin In (LUNAX Remix) (Extended Mix)-(5021732254740)-SINGLE-WEB-2024-ZzZz [9c1feafc0] [2af13ead9]-xpost | S7 | 1 | mp3 1 | `{0}` | `{0}` | 1 | *(none)* → `Cyril` | Stumblin' In (LUNAX Remix) (Extended Mix) | false |

**174 audio files across 10 folders.** That figure is the line count `06-EXPECTED-TREE.txt` must
carry, and the two are checked against each other in that file's own self-check.

### The D-18 register, per drawn folder

The plan asks for this on S5 and S6; it is given for all ten because the DJ fields are what a
`write: yes` import must not damage wherever they appear. Counts are files carrying the field.

| Folder | Stratum | bpm | initialkey (`TKEY`) | `TXXX:EnergyLevel` | genre | comment |
|---|---|---|---|---|---|---|
| Benson Boone-American Heart-…-OBZEN-xpost | S1 | 0 | 0 | — | 10 | 0 |
| Benson.Boone.-.Fireworks.&.Rollerblades…-xpost | S1 | 0 | 0 | — | 0 | 15 |
| Benson_Boone_-_American_Heart-WEB-…-BENSONBOONE | S1 | 0 | 0 | — | 10 | 0 |
| Michael.Jackson.-.The.Essential.…-maladicta-xpost | S2 | 0 | 0 | — | 0 | 0 |
| Now_.That.s.What.I.Call.Music.121…InChY | S3 | 0 | 0 | — | 44 | 0 |
| VA-Now_…_1-115_2023/Vol 001 | S4 | 0 | 0 | — | 30 | 30 |
| **Mastermix.Issue.420.2021** | **S5** | **10** | **0** | **0 of 10** | **10** | 0 |
| **Mastermix.Issue.421.2021** | **S5** | 0 | **0** | **0 of 10** | **10** | 0 |
| **Katy Perry/Teenage Dream (2010)** | **S6** | **12** | **0** | **0 of 12** | **12** | 0 |
| Cyril - Stumblin In …-xpost | S7 | 0 | 0 | — | 1 | 1 |

`TKEY` and `TXXX:EnergyLevel` were counted by a **raw mutagen frame-set read**, not by a beets
query, because `EnergyLevel` is neither a beets field nor a mediafile field and a beets query for it
returns empty — which reads as "clean" and is indistinguishable from "gone" (06-RESEARCH.md
§ *How beets treats each field on import*).

---

## The predicted `%aunique{}` firing

One ambiguous pair exists in the drawn set, and it is deliberate rather than accidental: the S1
draw took **two different rips of the same album**, `Benson Boone / American Heart` as 24-bit FLAC
and as MP3. They were drawn by the stated key, not chosen, and they are the sample's only test of
D-16.

| Album | Ambiguous set | `albumtype` | `year` | `label` | First disambiguator that separates | Rendered |
|---|---|---|---|---|---|---|
| `Benson Boone / American Heart` (FLAC) | 2 | *(empty, both)* | 2025, both | *(empty)* | **`label`** | *(empty — the value is empty, so `%aunique{}` returns `""`)* |
| `Benson Boone / American Heart` (MP3) | 2 | *(empty, both)* | 2025, both | `Night Street Records, Inc. - Warner Records Inc.` | **`label`** | ` [Night Street Records, Inc. - Warner Records Inc.]` |

This is the asymmetric case and it is worth having in the fixture: `albumtype` and `year` are
identical across the pair so neither separates it, `label` is present on one side and absent on the
other so it separates the pair at size 2 — and beets then returns `""` for the side whose
disambiguator value is empty and the bracketed label for the side whose is not. The result is one
album folder with no suffix and one with a 49-character bracketed label, both under
`Benson Boone/`. The numeric-database-id fallback is **not** reached, which is why this pair
survives the guard in `06-EXPECTED-TREE.txt` instead of being substituted out.

`%aunique{}` fires nowhere else in the sample, and the reason is measured, not assumed: **the real
`library.db` holds 0 items and 0 albums** (`sqlite3 … select count(*)`, opened read-only,
`/mnt/fast/appdata/arrs/beets/config/library.db`, sha256 `fbbdde0c…`). D-16's warning that a
throwaway library reports *fewer* firings than the real one is therefore inert for Phase 6 —
06-RESEARCH.md's options (a) "run against a copy of the real database" and (b) "record the count as
a lower bound" are, today, **the same count**, because the real collision set is empty. That will
stop being true the moment Phase 7 imports anything, and the claim is dated accordingly.

---

## What this sample does NOT cover

Stated as limitations rather than discovered later as gaps.

1. **Path rule 2 — `albumtype:=dj disctotal:2..` — is not exercised.** Both drawn S5 folders
   resolve to rule 3 (`albumtype:=dj`, single disc), because `Mastermix.Issue.420.2021` carries
   `disc` values `{1,2}` but **no `disctotal` at all**, and `Mastermix.Issue.421.2021` carries
   neither. The shape does exist in the population — **7 of the 60 `dj-mixes` folders**
   (`Mastermix_Issue_403`, `_404`, `_413`, `_418_April_2021`, `VA-Mastermix.Issue.422-2021`,
   `.427.2CD-2021`, `.429-2022`) carry `disctotal = 2` on all ten files — but none of them is
   among the first two by the `LC_ALL=C` key, and widening the target to reach them would be
   hand-picking. Plan 06-11 should assert rule 2 as a **named class assertion** over one of those
   seven rather than expect a row for it here.
2. **`TKEY` and `TXXX:EnergyLevel` are not exercised.** Zero of the 32 files in the two S5 folders
   and the S6 folder carry either. The estate holds 306 `TKEY` and 90 `EnergyLevel` files
   (06-RESEARCH.md § *What the corpus actually carries*), so D-18's key/energy branches need their
   own named folders, exactly as Phase 3's WAV gap did.
3. **No WAV, and no FLAC in the DJ strata.** The draw is 174 files: 105 mp3, 69 flac, **0 wav**.
   268 WAV exist estate-wide and all sit in `dj-mixes` and `unsorted` folders the key did not
   reach. The WAV ID3-offset rule (06-RESEARCH.md consequence 1) is therefore untested by this
   sample.
4. **S3's plurality is tied, and the tie cannot change the outcome.** `Now … 121`'s most common
   `albumartist or artist` value is `Sabrina Carpenter` with frequency **2** over 44 files, and at
   least one other artist ties it. The tie is recorded rather than broken, because
   `2 / 44 = 0.045` is below `SINGLE_ARTIST_THRESH = 0.25` for *any* artist that could win it, so
   the album resolves to `Various Artists` whichever way the tie falls. If a future draw hits a tie
   near the threshold, the tie-breaker above applies and the outcome must be re-derived.
5. **`Mastermix.Issue.421.2021` has `disc = 0`, not `disc = 1`.** Its files carry no disc tag at
   all. Nothing in the path templates reads `$disc` for a single-disc DJ release, so this is
   invisible in the expected tree — but it is the reason that folder cannot be used to test the
   multi-disc rule either, and it is the shape that would render `00-01` if a future rule change
   put `$disc` into a single-disc path.

---

## Nothing was written

| Assertion | Result |
|---|---|
| Entries under the ten sampled folders | 200 (`LC_ALL=C find`, including non-audio and the folder itself); 174 audio |
| Newest `ctime` anywhere under the ten sampled folders | **2026-09-19 20:42** (`Vol 001`, Phase 5's own work) — predates this plan |
| Newest `mtime` anywhere under the ten sampled folders | 2026-09-18 22:06 |
| `library.db` sha256 | `fbbdde0c416e72b9884e56c562fd88eaa4da447926e1cb6cc17c3e04aee7da1a` — identical to plan 06-04's baseline |
| `state.pickle` sha256 | `f6a9a1ad7aa553e42e53a8056fa80724785111180a5e2122be4f8732d1e4bc7c` — identical to plan 06-04's baseline |
| Containers started or restarted | 0 — the only container touched is `beets-flask`, already running, entered with `docker exec` for read-only `mediafile` calls |
| Files left in `/mnt/fast/appdata/arrs/beets/config/` by this plan | 0 — the two helper files staged there to cross the container boundary were moved to the fence and the directory re-listed to confirm |
| Writes to `/mnt/tank/media` | structurally impossible: the flask mount is `rw=false` (D-05), and this plan ran no import |
