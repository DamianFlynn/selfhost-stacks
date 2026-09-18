---
phase: 05-inbox-structure-and-the-junk-gate
plan: 05
measured: 2026-09-18
type: inventory
status: closed
---

# The `Now! 1-115` Inventory — measured 2026-09-18, after the 05-04 sweep

Input to plans 05-06 and 05-07. Every figure was **re-derived on 2026-09-18 between 17:08Z and
17:27Z**; none is inherited from `05-PREMEASURE.md` or `05-CONTEXT.md`. The tree is live (~1 music
job per 72 s), so these are point-in-time reads.
Root: `/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023`.

## 1. Fresh counts, beside the 2026-09-18 values they replace

| Measure | Measured now | 2026-09-18 | Note |
|---|---:|---:|---|
| mp3 files | **4,746** | 4,746 | unchanged — **4,746 is the denominator for everything downstream** |
| non-mp3 sidecars | **5** | 14 | plan 05-04 removed 9 (7 EAC `.log`, `play.m3u`, `00. play.m3u`) |
| subdirectories | **0** | 0 | still flat |
| surviving sidecars | the map, `NOW…! 115.cue`, `back.bmp`, `cd1.bmp`, `cd2.bmp` | | |
| m3u manifest entries | **4,770** | 4,770 | the file is 9,541 lines |
| ffprobe records written | **4,746** | — | failed ledger **empty**; 0 null `album`, `disc`, `track` or `tracktotal` |

## 2. D-03's trap, verbatim — no trailing-number parse anywhere

**Do NOT parse a trailing number off the `album` tag.** The 117 distinct values include:
- Volume 1 tagged `Now That's What I Call Music` — **no number at all**
- Volume 2 tagged `Now, That's What I Call Music II` — **Roman numeral, and a comma**
- Volume 36 split across **three** spellings: `…! Vol.36 CD1` (16 files), `…! Vol.36  CD2`
  (20 files, **note the double space**), `…! 36` (4 files)

`…Vol.36 CD1` ends in `1` and `…Vol.36  CD2` ends in `2`, so a trailing-number regex **silently
misfiles 36 tracks into volumes 1 and 2**. It exits 0 and looks right. Punctuation varies too:
**96 values spell it `Music!` and 21 spell it `Music`** (measured; `05-CONTEXT.md` said 19). All
three spellings are still present and were re-counted at 20 / 16 / 4. **Grouping is by the m3u
manifest's volume directory only.** Deriving volume NUMBERS from that list is plan 05-06's job,
under operator review; nothing in this plan did it.

## 3. The pre-declared exception table, and what was actually measured

D-04's list grouped on the **album tag**; this plan groups on the **manifest volume directory**, a
different and stronger instrument. Both are recorded.

| Pre-declared (D-04, album tag) | Volumes | Measured by manifest directory |
|---|---|---|
| Short by 1 | 15, 18, 39, 52, 70, 83, 98 | **18, 52, 70, 83, 98 confirmed. 15 and 39 BALANCE** |
| Short by 2 | 3 | **volume 3 BALANCES** (28 / 28) |
| Surplus | 4 (+13), 8 (+9), 9 (+14) | **no surplus anywhere** — see § 4 |
| Split-tag mess | `! 36` 4 files/expected 20; `Vol.36 CD1` 16/expected 20 | **volume 36 BALANCES** (40 / 40): one directory, three album spellings |

Measured exceptions — **7, every one a SHORTFALL, 11 files in total**; 112 of 119 balance exactly:

| Volume directory | files | Σ tracktotal | delta |
|---|---:|---:|---:|
| `1984. Now That's What I Call Music! 4 [Genuine UK 1CD-Extremely Rare Estimated 500 copies Pressed]` | 11 | 15 | −4 |
| `1984. Now That's What I Call Music! 4 [Original 1CD Extremely Rare Estimated 500 copies Pressed]` | 13 | 15 | −2 |
| `1990. Now That's What I Call Music! 18` | 31 | 32 | −1 |
| `2002. Now That's What I Call Music! 52` | 41 | 42 | −1 |
| `2008. Now That's What I Call Music! 70` | 42 | 43 | −1 |
| `2012. Now That's What I Call Music! 83` | 42 | 43 | −1 |
| `2017. Now That's What I Call Music! 98` | 45 | 46 | −1 |

**The differences from the pre-declared list are the finding, not a discrepancy**: volumes 3, 8, 9,
15, 36 and 39 balance under the directory grouping because the album tag cannot separate editions
that share one album string.

⚠ **Volume-level balance is not per-DISC balance.** `1986. …! 8 [2021 Reissue]` balances 32/32 as a
**cancellation**: disc 1 holds 20 files against a stated 16, disc 2 holds 12 against 16. Recorded so
nobody reads its `ok` row as a clean volume.

## 4. D-04's open question — ANSWERED: the surplus is a grouping artefact

The album strings are `Now That's What I Call Music 4` / `8` / `9` — **without the exclamation
mark**, one string per family — and the reproduction is exact:

| Family | album-tag files | Σ tracktotal over its discs | D-04's surplus | reproduced |
|---|---:|---:|---:|---|
| 4 | 45 | 32 (16+16) | +13 | **+13** ✓ |
| 8 | 42 | 33 (17+16) | +9 | **+9** ✓ |
| 9 | 44 | 30 (15+15) | +14 | **+14** ✓ |

**The two instruments AGREE exactly** on which files belong to each family — 45 / 42 / 44 distinct
physical files under both the album tag and the manifest directories. D-04's case 4 does **not**
apply, and **no file from another volume is mis-tagged into these**. Per volume:

- **Volume 4 — grouping artefact.** The manifest names **three** directories: `[2019 Reissue]`
  (32 files, **balanced 32/32, zero leaf collisions, all (disc,track) pairs distinct**),
  `[Genuine UK 1CD…]` (11) and `[Original 1CD…]` (13). Neither case 2 nor case 3 fires — max track
  never exceeds the stated tracktotal on any disc. The two 1CD pressings are real, separate 1984
  editions the album tag cannot name.
- **Volume 8 — case 2 fires.** `[2021 Reissue]` shows **4 repeated (disc,track) pairs** on disc 1
  (tracks 9, 10, 11, 12); every duplicate is a leaf-collided file whose other manifest home is
  `1986. …! 8 [Original 1CD Rare]` (17 files, balanced 17/17), named in full in
  `artifacts/05-05-d04-answer.txt`. **Not intruders from a different volume** — the same volume's
  other edition, one physical file serving two manifest lines.
- **Volume 9 — case 2 does not fire.** All pairs distinct, balanced 30/30. 2 claims are shared with
  `1987. …! 9 [Original 1CD Rare]` (16 files, balanced 16/16); those two carry `tracktotal=16` from
  the 1CD edition against the reissue's 15 — a **tag disagreement, not a grouping defect**.

**Fixing any `tracktotal` is out of scope** (D-10 declined it); repair is Phase 6's.

## 5. The 24-entry gap — its own line, never folded into any total

**manifest-only entries (m3u lines with no file on disk): 0.**

The gap is **collision, not absence**, which confirms D-04's guess about the flatten:
- 4,770 manifest lines carry **4,746 distinct leaf names**, exactly the number of files on disk;
- **24 lines beyond the first** share a leaf, across **23 distinct leaves** — one
  (`01. Duran Duran - The Reflex.mp3`) is carried by **three** lines;
- so **23 physical files are claimed by more than one volume directory**, producing 47 join rows.

⚠ **This is plan 05-06's hardest problem, named here before the split runs.** A file cannot be moved
into two folders. All 23 are listed with every claiming directory in
`artifacts/05-05-collided-files.tsv`. The split needs an explicit rule; it must not pick silently.
Separately, Σ tracktotal across all 119 directories exceeds the 4,770 manifest lines by **11**
(§ 3) — those tracks were never in the rip.

## 6. The join needed two stages, because the m3u is CP1252

Read as raw bytes only 4,646 of 4,746 leaves match a file; decoded from CP1252, **4,744** match
exactly. The remaining **2** (Hangul in `01. Psy - Gangnam Style`, a Greek capital lambda in
`10. Axwell Λ Ingrosso`) were written by the ripper as literal `?` and are unrecoverable by any
decoding; they join on an alphanumerics-only key required to be unique on both sides.
**0 unresolved, 0 disk files without a manifest entry.**

## 7. Distinct lists, and D-09

| List | Measured | Expected | Note |
|---|---:|---:|---|
| manifest volume directories | **119** | 116 | the earlier count named the collection root as a directory and missed the four variant-edition directories (4 ×2, 8, 9) |
| album strings | **117** | 117 | as expected |

**D-09 stands: all 115 volumes are split, incomplete ones included.** Every volume gets its folder;
the short ones are split anyway and flagged, because an incomplete `Now!` volume is still
importable — it is a **compilation, not a broken album**. Routing them to `04-hold` was **rejected**:
that folder is scoped for content needing artwork or tracklist sourcing, not missing audio.

## 8. Where the data lives

Host paths under `/mnt/fast/safety/phase05/`. Not committed, because of size: `now-tags.ndjson`
(**the inventory**, 4,746 records, 6.9 MB), `now-tags.done` / `now-tags.failed` (resume and failure
ledgers) and `now-manifest.ndjson` (4,770 records). Committed under `artifacts/`:
`now-volume-dirnames.txt` → `05-05-volume-dirnames.txt` (119 lines, UNPARSED);
`now-album-values.tsv` → `05-05-album-values.tsv` (117 rows); `now-reconciliation.txt`,
`now-collided-files.tsv`, `now-tracktotal-conflicts.tsv` and `now-d04-answer.txt` → the matching
`05-05-*` names. Tools: `scripts/phase05-now-tag-inventory.sh` (`scan`, `reconcile`) and
`artifacts/05-05-d04-analysis.sh`, both read-only against the collection.
