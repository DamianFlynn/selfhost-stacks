# Phase 3 D-13 bake-off: wrtag `metadata` against the mutagen script

Companion to [`03-DECISION.md`](03-DECISION.md) (where the prediction below was committed **before**
this run), to [`03-NORMALISATION.md`](03-NORMALISATION.md) (the mutagen arm's own record), to
[`03-WRTAG-EVIDENCE.md`](03-WRTAG-EVIDENCE.md) (criterion 3, a different binary in the same image)
and to [`scripts/normalise-dj-tags.py`](../../../scripts/normalise-dj-tags.py).

Nothing here is applied by `docker compose`. This is the record of one normalisation job run twice,
by two tools, from the identical before-state, scored by the identical instrument.

State as of 2026-09-04 — **both arms run on MP3 and on WAV; `raw/` and the mutagen arm's tree
proven untouched; no Discogs or MusicBrainz request issued.**

> **The prediction, quoted verbatim from [`03-DECISION.md`](03-DECISION.md) § *D-13 — the stated
> prediction, recorded before the bake-off*, whose text is byte-identical to threshold commit
> `137b6d9e92cb44d9c6a48b3963bb33fe0194622f` and has not been touched since:**
>
> > wrtag's `metadata` tool applies **one literal key→value map to every path** in the invocation,
> > has **no dry-run and no diff**, and offers **no field-to-field move primitive**. **The
> > reviewability requirement in D-08 is therefore not met by it without a wrapper.** On this
> > project's own standing rule — *verify with a second independent instrument before you write it
> > down* — that is close to decisive.
> >
> > **Prediction:** the mutagen script wins on reviewability; `metadata` may win on WAV.
>
> **Measured outcome, in one line: the prediction held on reviewability and was OVERTURNED on
> WAV — but not in the direction it anticipated.** `metadata` did not merely handle WAV better; it
> is the only one of the two that can write a WAV tag **at all** (130 of 134 files, against the
> mutagen script's **0 of 134** — `TypeError: [...] not a Frame instance` on every single file).
> And the reviewability half was not won on argument: the `metadata` arm's driver silently wrote
> the **artist value into the album field on 20 of 205 files** on its first run, and the phase's own
> field-loss gate scored that run `FIELDS_DROPPED = 0`.

---

## What ran, where, and on which trees

Three MP3 trees under `/mnt/tank/downloads/spike-03`, all reflinked from the same 24-folder draw,
plus three WAV trees added by this plan:

| Tree | Contents | Written by | Mount mode in this plan |
|---|---|---|---|
| `raw/` | 24 folders, 364 files, **335 mp3** — the un-normalised twin | nothing, ever | not mounted at all |
| `normalised/` | the **mutagen arm**, written by plan 03-05 | `normalise-dj-tags.py` | not mounted at all |
| **`normalised-metadata/`** | the **`metadata` arm**, created by this plan | `metadata write` | `rw`, the only writable mount |
| `wav-raw/` | 3 folders, 161 files, **134 wav** — the WAV twin | nothing | not mounted after staging |
| `wav-mutagen/` | the WAV mutagen arm | `normalise-dj-tags.py`'s WAV path | `rw` for one 1 s run |
| `wav-metadata/` | the WAV `metadata` arm | `metadata write` | `rw` for one 3 s run |

**`normalised-metadata/` was materialised on atlantis**, by the `cp -r --reflink=always
--preserve=timestamps` + `chown 568:568` route plan 03-03 documented (`FICLONE` is `EPERM` inside
the unprivileged container), and asserted **byte-identical to `raw/`** before each run by comparing
its whole-subtree `sha256sum` manifest against `raw/`'s with the path prefix rewritten. Per-folder
mp3 counts reproduce [`03-SAMPLE.md`](03-SAMPLE.md)'s draw table exactly on all 24 folders
(10·10·10·10·10·10·10·10·10·9·8·24·24·10·10·10·10·10·60·20·10·10·10·20 = **335**).

`metadata` was exercised **inside `sentriz/wrtag:v0.34.0`** — the image plan 03-01 already pulled
and 03-08 already audited — never installed on the host. The image ships four binaries at
`/usr/local/bin`: `metadata`, `wrtag`, `wrtagweb`, `streaming_extractor_music`. **`metadata` is a
different binary from the path-format renderer 03-08 measured**, so 03-08's finding that this
repo's `WRTAG_PATH_FORMAT` renders at no tag says nothing about it, and it was measured rather than
inferred.

```
docker run --rm --security-opt no-new-privileges:true --network none \
  --name spike03-metadata-arm \
  -e EXPECT_BOTH=87 -e EXPECT_ALBUM=98 -e EXPECT_ARTIST=20 \
  -v /mnt/tank/downloads/spike-03/normalised-metadata:/mnt/tank/downloads/spike-03/normalised-metadata \
  -v /mnt/fast/spike-03/out/bakeoff-in:/spike-in:ro \
  -v /mnt/fast/spike-03/out/bakeoff-run:/spike-out \
  --entrypoint /bin/sh sentriz/wrtag:v0.34.0 /spike-in/metadata-driver.sh
```

Identical path inside and outside; `--network none` (the job needs no network, unlike 03-08's arms);
`--rm`; `no-new-privileges`; **nothing under `/mnt/tank/media` mounted at any mode**.

### The mandatory preflight, and why it is inside the container

Plan 03-05 found that a docker bind mount pins the directory **inode**, not the path: a tree
re-materialised on the host leaves a running container bound to the deleted inode, where every
command reports **0 files and exits 0** — a vacuous pass. This plan re-materialises
`normalised-metadata/` twice, so the driver asserts the counts **from inside the container** before
it writes anything and refuses otherwise. Both recorded runs printed:

```
preflight(in-container): folders=24 files=335
```

cross-checked against the host's own `find` on the same tree (24 / 335) and against the draw table.
`--rm` makes the stale-inode case structurally impossible here — each run is a fresh container — but
the assertion is kept because "the mount cannot be stale" is an argument and the count is a
measurement.

---

## The driver, verbatim, and what it costs

`metadata` has **no field-to-field move primitive** and its `write` takes a **literal** key→value
map, so a canonicalise-in-place job needs one `read` and one `write` per file, in a loop, with a
branch per field combination. That loop is the honest cost of the `metadata` arm and it is recorded
in full rather than summarised.

**One handicap is removed, and it is removed in `metadata`'s favour.** The three normalisation
*rules* are not re-implemented in the driver: it is handed the mutagen script's own computed
`(path, album, artist)` proposal set — the 292 records of
`/mnt/fast/spike-03/out/normalise-apply.ndjson`, whose sha256 03-05 proved identical to its dry
run — as a TSV. **`metadata` therefore competes without paying for the rule logic at all**, and its
lines-of-driver figure is a lower bound on a `metadata`-only solution.

```sh
#!/bin/sh
# metadata-driver.sh - the wrtag `metadata` arm of plan 03-09's D-13 bake-off.
#
# Runs INSIDE sentriz/wrtag:v0.34.0 (busybox sh; no bash, no jq). It performs the SAME
# transformation plan 03-05's scripts/normalise-dj-tags.py performed on the mutagen arm, on a
# separate reflinked tree, so the comparison is of TOOLS rather than of transformations.
#
# HANDICAP REMOVED, STATED OUT LOUD: the three normalisation RULES are not re-implemented here.
# The driver is handed the mutagen script's own computed (path, album, artist) proposal set as a
# TSV. `metadata` therefore competes without paying for the rule logic at all. Its lines-of-driver
# figure below is consequently a LOWER BOUND on what a metadata-only solution would cost.
#
# WHY A READ PASS EXISTS AT ALL: `metadata write` takes a LITERAL key->value map and applies it to
# every path in the invocation. It has no field-to-field move primitive and no way to derive a
# value from the file's current tag, so any canonicalise-in-place job must read first. That is the
# shape being measured, and it is why the expected invocation count is two per changed file.
#
# THERE IS NO DRY RUN. `metadata write -h` lists exactly one option, `-log-level`. That absence is
# recorded as the measurement; it is deliberately NOT worked around with a wrapper, because a
# wrapper would measure the wrapper.
set -u

MD=/usr/local/bin/metadata
TREE=/mnt/tank/downloads/spike-03/normalised-metadata
TSV=/spike-in/bakeoff-targets.tsv
OUT=/spike-out

EXPECT_FOLDERS=24
EXPECT_FILES=335

# --- MANDATORY PREFLIGHT ---------------------------------------------------------------------
# A docker bind mount pins the directory INODE, not the path (plan 03-05). A tree re-materialised
# on the host leaves an already-running container bound to the deleted inode, where every command
# reports 0 files and EXITS 0 - a vacuous pass. Assert the counts from INSIDE the container before
# anything is written, and refuse rather than measure an empty tree.
folders=$(find "$TREE" -mindepth 1 -maxdepth 1 -type d | wc -l)
files=$(find "$TREE" -type f -name '*.mp3' | wc -l)
printf 'preflight(in-container): folders=%s files=%s\n' "$folders" "$files"
if [ "$folders" -ne "$EXPECT_FOLDERS" ] || [ "$files" -ne "$EXPECT_FILES" ]; then
  printf 'REFUSAL: expected %s folders / %s mp3, saw %s / %s\n' \
    "$EXPECT_FOLDERS" "$EXPECT_FILES" "$folders" "$files" >&2
  exit 3
fi
[ -s "$TSV" ] || { echo 'REFUSAL: target TSV is empty or missing' >&2; exit 3; }

mkdir -p "$OUT"
: > "$OUT/driver-reads.tsv"
: > "$OUT/driver-writes.log"
: > "$OUT/driver-failed.txt"

start=$(date +%s)
reads=0; read_fail=0
writes=0; write_fail=0
n_both=0; n_album=0; n_artist=0

# --- PASS 1: read every file ------------------------------------------------------------------
find "$TREE" -type f -name '*.mp3' | LC_ALL=C sort > "$OUT/driver-files.txt"
while IFS= read -r f; do
  if "$MD" read album artist -- "$f" >> "$OUT/driver-reads.tsv" 2>>"$OUT/driver-failed.txt"; then
    reads=$((reads + 1))
  else
    read_fail=$((read_fail + 1))
    printf 'READ_FAIL\t%s\n' "$f" >> "$OUT/driver-failed.txt"
  fi
done < "$OUT/driver-files.txt"

# --- PASS 2: write the proposals --------------------------------------------------------------
# Three branches, because the literal map differs per file and `metadata write` cannot be told
# "leave this key alone" other than by omitting it from the map.
#
# THE FIELDS ARE SPLIT BY PARAMETER EXPANSION, NOT BY `IFS=<tab> read`. This is not a style
# preference; the obvious form is WRONG and its wrongness is silent. TAB is an IFS WHITESPACE
# character, so `IFS=$TAB read -r p album artist` COLLAPSES a run of tabs and drops empty fields:
# the row `path<TAB><TAB>Mastermix` (an artist-only proposal) is read as album="Mastermix",
# artist="", and the driver then writes the ARTIST value INTO THE ALBUM FIELD. Measured on run 1
# of this very driver: 20 of 205 files, both `Mastermix.Issue.421.2021` and `Mastermix_Issue_415`,
# ended up with album="Mastermix" and their placeholder artist untouched - and because a
# correct-shaped wrong value drops no field, `diff-music-tags.sh` scored that run
# FIELDS_DROPPED = 0 and could not see it. `metadata write` has no dry run to have caught it in.
TAB=$(printf '\t')

# PASS 2a - parse only, write nothing, and REFUSE if this shell's split of the TSV disagrees with
# the count the generator made with `awk -F'\t'` (awk does not collapse empty fields). This checks
# THE DRIVER'S OWN PARSE. It is deliberately NOT a dry run for `metadata`: the tool still writes
# blind, exactly as it does in production, because a wrapper would measure the wrapper.
while IFS= read -r line; do
  [ -n "$line" ] || continue
  rest=${line#*"$TAB"}
  album=${rest%%"$TAB"*}
  artist=${rest#*"$TAB"}
  if [ -n "$album" ] && [ -n "$artist" ]; then n_both=$((n_both + 1))
  elif [ -n "$album" ];                   then n_album=$((n_album + 1))
  else                                          n_artist=$((n_artist + 1)); fi
done < "$TSV"
: "${EXPECT_BOTH:=0}" "${EXPECT_ALBUM:=0}" "${EXPECT_ARTIST:=0}"
if [ "$n_both" -ne "$EXPECT_BOTH" ] || [ "$n_album" -ne "$EXPECT_ALBUM" ] \
   || [ "$n_artist" -ne "$EXPECT_ARTIST" ]; then
  printf 'REFUSAL: branch split %s/%s/%s != expected %s/%s/%s (both/album-only/artist-only)\n' \
    "$n_both" "$n_album" "$n_artist" "$EXPECT_BOTH" "$EXPECT_ALBUM" "$EXPECT_ARTIST" >&2
  exit 4
fi

# PASS 2b - the writes.
while IFS= read -r line; do
  [ -n "$line" ] || continue
  p=${line%%"$TAB"*}
  rest=${line#*"$TAB"}
  album=${rest%%"$TAB"*}
  artist=${rest#*"$TAB"}
  [ -n "$p" ] || continue
  if [ -n "$album" ] && [ -n "$artist" ]; then
    "$MD" write album "$album" , artist "$artist" -- "$p" >> "$OUT/driver-writes.log" 2>&1
    rc=$?
  elif [ -n "$album" ]; then
    "$MD" write album "$album" -- "$p" >> "$OUT/driver-writes.log" 2>&1
    rc=$?
  else
    "$MD" write artist "$artist" -- "$p" >> "$OUT/driver-writes.log" 2>&1
    rc=$?
  fi
  if [ "$rc" -eq 0 ]; then
    writes=$((writes + 1))
  else
    write_fail=$((write_fail + 1))
    printf 'WRITE_FAIL\t%s\n' "$p" >> "$OUT/driver-failed.txt"
  fi
done < "$TSV"

end=$(date +%s)
printf 'reads_ok=%s read_fail=%s writes_ok=%s write_fail=%s invocations=%s elapsed_s=%s branches=%s/%s/%s\n' \
  "$reads" "$read_fail" "$writes" "$write_fail" \
  "$((reads + read_fail + writes + write_fail))" "$((end - start))" \
  "$n_both" "$n_album" "$n_artist" | tee "$OUT/driver-summary.txt"
[ "$read_fail" -eq 0 ] && [ "$write_fail" -eq 0 ]
```

| Property | Value |
|---|---|
| Driver, as run | `metadata-driver.sh`, sha256 `7fbb395212aa0eecbf45c36eb629d4a7a66b4fe240688eb392338542a22cd426` |
| **Lines of driver** | **134 total / 80 non-comment, non-blank** — and that is *before* any rule logic |
| WAV sibling | `metadata-driver-wav.sh`, identical but for four constants made env-overridable (`TREE`, `TSV`, `EXPECT_FOLDERS`/`EXPECT_FILES`, and `*.mp3` → `*.$EXT`); `diff` is 4 hunks, 0 logic changes |
| `metadata` invocations, MP3 arm | **540** — 335 `read` + 205 `write`, exactly two per changed file as predicted |
| `metadata` invocations, WAV arm | **268** — 134 `read` + 134 `write` |
| Branch split asserted, not reported | `87` both-fields / `98` album-only / `20` artist-only, matching the generator's `awk -F'\t'` count |

**One correction to the driver's own header comment, stated rather than silently edited.** Line 18
says *"`metadata write -h` lists exactly one option, `-log-level`"*. `metadata write -h` in fact
errors — `stat -h: no such file or directory` — because `write` treats `-h` as a path. The option
list comes from the **top-level** `metadata -h`, which is where `-log-level` (global), `-properties`
(a `read` flag) and `-index`/`-type`/`-desc`/`-mime-type` (image flags) are enumerated. The
*substance* of the comment is correct and independently confirmed: **there is no dry-run flag on
`write`, and no flag of any kind on `write`.** The comment is left as it was run rather than
rewritten after the fact.

---

## Run 1: the driver wrote the wrong value into the wrong field, and the gate could not see it

The `metadata` arm was run twice. **Run 1 is kept and reported because it is the single most
informative result in this bake-off**, and deleting it would have turned a measurement into an
argument.

Run 1 completed cleanly on every instrument the plan asks for: 540 invocations, **0** tool
failures, 205 files written, `find -newer` clean on both other trees, whole-subtree manifest diffs
empty, `diff-music-tags.sh` `FIELDS_DROPPED = 0`. It was wrong anyway. Comparing the two arms'
outputs directly showed **40 differing (file, field) pairs across 20 files**:

| | mutagen arm | `metadata` arm, run 1 |
|---|---|---|
| `Mastermix.Issue.421.2021` ×10 | album `Mastermix Issue 421`, artist `Mastermix` | album **`Mastermix`**, artist **`Various Artists`** (untouched) |
| `Mastermix_Issue_415` ×10 | album `Mastermix Issue 415 (Januar 2021)`, artist `Mastermix` | album **`Mastermix`**, artist **`Various Artists`** (untouched) |

Those 20 files are **exactly** the 20 artist-only rows in the target TSV. The cause is a POSIX
shell subtlety, demonstrated in isolation inside the same image:

```
$ printf 'P\t\tVALUE\n' > /t.tsv
IFS-split   a=[P] b=[VALUE] c=[]          # IFS=<tab> read -r a b c
expansion   a=[P] b=[] c=[VALUE]          # ${l%%"$TAB"*} / ${r#*"$TAB"}
```

**TAB is an IFS *whitespace* character**, so `IFS=$TAB read -r p album artist` collapses the run of
tabs and drops the empty field; the artist value landed in `$album` and the driver took the
album-only branch. Fixed by splitting with parameter expansion and backstopped by the PASS-2a
branch-count assertion, which now refuses before any write if the shell's split disagrees with the
generator's `awk -F'\t'` count.

**What makes this a finding rather than an anecdote:**

1. **`metadata write` has no dry run, so there was no reviewable step in which to catch it.** The
   mutagen arm's equivalent bug would have been visible in its 292-line dry-run diff before a byte
   was written — and 03-05 proved that diff is an exact prediction of the apply (identical sha256
   over the sorted proposal set).
2. **The phase's own field-loss gate is structurally blind to it.** A *correct-shaped wrong value*
   drops no field. `diff-music-tags.sh` scored run 1 `FIELDS_DROPPED = 0`, exactly as it scored the
   correct run 2. Only a direct arm-to-arm comparison exposed it.
3. It is the same defect class as 03-05's finding 1 row 3 (`TYER`→`TDRC` invisible to `ffprobe`) and
   03-08's finding 5 (`logTagChanges` cannot log a tag it is about to wipe): **the instrument
   answers a narrower question than the one being asked.**

`normalised-metadata/` was then **re-materialised from `raw/` on atlantis** and re-asserted
byte-identical before run 2, so **every number below comes from one clean invocation of the fixed
driver**, not from a patched-up tree. Run 1's artefacts are retained under
`/mnt/fast/spike-03/out/bakeoff-run1/` and `spike03-after-metadata-run1.ndjson.gz`.

---

## The MP3 run

| Quantity | mutagen arm (03-05) | `metadata` arm (this plan, run 2) |
|---|---|---|
| Tree | `spike-03/normalised` | `spike-03/normalised-metadata` |
| Reviewable dry run before writing | **yes** — 292 records, sha256-identical to the apply | **none exists** |
| Files seen / written | 335 / **205** | 335 / **205** |
| Tool invocations | 1 (one Python process) | **540** |
| Failure ledger | **0 lines** | **0 lines** |
| Elapsed, in-container | **13.99 s** | **13 s** (docker wall-clock 14 s) |
| Exit code | 0 | 0 |
| Containers left in `docker ps -a` | none | **none** — `--rm` |

### Blast radius: two instruments over the whole subtree, per the 03-05 standard

`find -newer` plus a handful of spot hashes is the weakest evidence in this phase; the five-file
spot check is retired phase-wide. Both instruments were captured before staging and after the run,
over **every** file in each subtree (364 per MP3 tree — the 335 audio files plus 29 non-audio
entries a rules-only check would never look at).

| Instrument | `raw/` | `normalised/` | `normalised-metadata/` |
|---|---|---|---|
| 1 — `find <subtree> -newer bakeoff-t0.stamp -type f` | **0 lines** | **0 lines** | 205 lines (expected) |
| 2 — `diff` of before/after `%p\t%s\t%T@` manifest (`.meta`) | **empty** | **empty** | 205 changed |
| 2 — `diff` of before/after `sha256sum` manifest (`.sha`) | **empty** | **empty** | 205 changed |

**Exactly 205 files changed in the `metadata` arm and not one more** — the 130 files with no
proposal were not touched at all. Neither the un-normalised arm nor the mutagen arm was disturbed,
on either instrument, across both runs.

### Scoring

Both arms were captured with the same tool and scored against **the same** plan-03-03 before
snapshot:

| Side | Path | Records |
|---|---|---|
| BEFORE (both arms) | `/mnt/fast/spike-03/out/spike03-before.ndjson.gz` | 335 |
| AFTER, mutagen | `/mnt/fast/spike-03/out/spike03-after.ndjson.gz` | 335 |
| AFTER, `metadata` | `/mnt/fast/spike-03/out/spike03-after-metadata.ndjson.gz` | 335, `.failed` **0 lines** |

The `metadata` after-capture is `bash scripts/snapshot-music-tags.sh spike03-after-metadata --roots
/mnt/tank/downloads/spike-03/normalised-metadata` — 335 files seen, 335 records written, 0 failed —
copied from the fence into `out/` exactly as plan 03-03 did.

---

## Capability matrix, filled from observation

Every cell is annotated **`observed`** (measured in this run) or **`source`** (read from code and
not exhibited at runtime). Two rows — the flag-`0` merge and the deferred `os.Exit(1)` — were
previously **source reads only**; both are now `observed`.

| # | Axis | mutagen script (`scripts/normalise-dj-tags.py`) | wrtag `metadata` (v0.34.0) |
|---|---|---|---|
| 1 | **Dry-run** | **Yes, and it is the default.** `--dry-run` runs unless `--apply` is given, and `--apply` additionally refuses without `--snapshot-proof` — exercised on the WAV arm, which ran dry first — **`observed`** | **No.** `write` accepts no flags at all: `metadata write -h` errors `stat -h: no such file or directory`, treating `-h` as a path, and the top-level usage block gives `write` no options. Every invocation in this plan wrote blind — **`observed`** |
| 2 | **Reviewable diff before writing** | **Yes, per file and per field.** 292 NDJSON records on the MP3 arm, 134 on the WAV arm, each carrying `old`/`new`; 03-05 proved the dry run's sorted proposal set is sha256-identical to the apply's — **`observed`** | **No, and none can be synthesised from its output.** `metadata write` emits **nothing at all** on success: the arm's `driver-writes.log` is **0 lines** across 205 successful writes — **`observed`** |
| 3 | **Per-file distinct values in one invocation** | **Yes.** One process handled all 335 files with 205 distinct value pairs — **`observed`** | **No.** One literal map per invocation, so 205 changed files needed 205 `write` invocations plus 335 `read` invocations = **540** — **`observed`** |
| 4 | **Field-to-field / derive-from-current move** | **Yes.** Rule 2 canonicalises the album it just read; 155 files changed that way — **`observed`** | **No primitive.** The value must be computed outside the tool and handed back as a literal; the read pass exists solely to make that possible — **`observed`** |
| 5 | **Preserves unlisted tags** | **Yes, inside AND outside ID3v2.** `FIELDS_DROPPED = 0`; the on-disk ID3v2 frame-ID multiset differs from the untouched twin on exactly **40 of 335** files and the difference is exactly the 40 frames the rules created; ID3v1 and APEv2 byte-unchanged on all 335 — **`observed`** | **Yes inside ID3v2** — `FIELDS_DROPPED = 0`, `TKEY` 40→40, `EnergyLevel` 20→20, `TBPM` 110→110, values identical. **A3 confirmed.** **But not outside it:** ID3v2.3→2.4 on 205 files, `TYER`→`TDRC` on 155, ID3v1 rewritten on 175 and **created on 30 files that had none**, APEv2 re-serialised on 14 — **`observed`** (was `source`) |
| 6 | **Formats handled** | MP3 **yes** (335/335). **WAV: 0 of 134** — the committed non-MP3 path raises `TypeError: [...] not a Frame instance` on every file. FLAC unexercised: the estate's backlog holds 147 FLAC but none in either sample — **`observed`** | MP3 **yes** (335/335, including 3 files with non-ASCII paths). WAV **130 of 134**; the 4 failures throw inside taglib's WASM runtime. FLAC unexercised — **`observed`** |
| 7 | **Exit code on failure** | Non-zero, and failures are itemised into a `.failed` ledger rather than swallowed: the WAV arm returned **1** with 134 error records — **`observed`** | **Correct.** `metadata write album X -- /nope.mp3` returns **1**; the 4 WAV failures each returned non-zero and were counted by the driver. Confirms `wrtaglog.Setup()`'s deferred `os.Exit(1)` — **`observed`** (was `source`) |
| 8 | **Committed, versioned, auditable** | **Yes**, and it is the whole artefact: `scripts/normalise-dj-tags.py`, 948 lines, sha256 `73149e79…`, verified identical to the committed blob before every run — **`observed`** | **The tool is a third-party binary inside an image; the driver is the thing that would be committed.** This plan's driver is **134 lines / 80 code lines of bespoke `sh`**, and that is *before* re-implementing any rule logic — **`observed`** |

---

## Field loss, both arms

Scored with `scripts/diff-music-tags.sh` against **the same** before-snapshot, on both joins.

### `audio_md5` join — the tool's own contract

| Category | mutagen arm | `metadata` arm |
|---|---|---|
| MATCHED | **306** | **269** |
| MISSING_AFTER | **0** | **37** |
| NEW_AFTER | **0** | **37** |
| **FIELDS_DROPPED** | **0** | **0** |
| FIELDS_GAINED | 35 | 35 |
| FIELDS_CHANGED | 237 | 179 |
| Matched files whose BEFORE tag set was empty | **0** | **0** |
| **exit code** | **0** | **1** |

**The `metadata` arm's exit 1 is DEF-03-03, not data loss, and that was proven rather than
assumed.** `snapshot-music-tags.sh`'s key is `ffmpeg -map 0:a -c copy -f md5`, which for some MP3
emits the trailing 128-byte ID3v1 block as part of the copied stream. `metadata` rewrites that
block; the mutagen script restores it byte-for-byte (03-05 deviation 3). Measured against the
untouched `raw/` twin, with the ID3v2 header, any APEv2 tag and any ID3v1 trailer excluded:

| Assertion | mutagen arm | `metadata` arm |
|---|---|---|
| Files whose **audio region** is byte-identical to the twin | **335 of 335** | **335 of 335** |
| ID3v1 block rewritten | **0** | **175** |
| ID3v1 block created where none existed | **0** | **30** |
| ID3v1 block removed | 0 | 0 |
| APEv2 tag re-serialised | **0** | **14 of 14** |
| APEv2 **item key set** changed | 0 | **0** |
| APEv2 **item values** changed | 0 | **0** |

**No audio byte moved on either arm, and no APEv2 item was lost or altered on either arm.** The
`metadata` arm's APEv2 rewrite is a re-serialisation — items are reordered and the block is padded
differently — with an identical key set and identical values. The 14 APE-bearing files are
`Mastermix_Issue_413` ×10, `VA-DMC-Essential.Hits.233` ×3, `VA-DMC-Essential.Hits.234` ×1.

### Path-keyed join — valid here because this plan renames and moves nothing

`audio_md5` collapses the draw's 29 deliberate near-duplicates *and* is not tag-invariant, so the
verdict was recomputed on `source_path`, using `diff-music-tags.sh`'s **own** `FLATTEN_JQ` extracted
from the frozen script at run time so only the join key differs:

| Quantity | mutagen arm | `metadata` arm |
|---|---|---|
| Matched | **335 of 335** | **335 of 335** |
| MISSING_AFTER / NEW_AFTER | 0 / 0 | 0 / 0 |
| **FIELDS_DROPPED** | **0** | **0** |
| Dropped field names | **none** | **none** |
| Gained field names | `album` 30, `artist` 10 — and nothing else | `album` 30, `artist` 10 — and nothing else |
| Changed field names | `album` 155, `artist` 97 — and nothing else | `album` 155, `artist` 97 — and nothing else |

**And the decisive comparison: the two arms' after-states, diffed directly against each other,
path-keyed — 335 matched, 0 fields dropped, 0 gained, 0 changed.** As scored by the phase's own
instrument, on the MP3 stratum, **the two tools produced identical output**. Every difference
between them lives in a container or an encoding that `ffprobe` does not surface.

Neither arm's vacuous-pass guard fired on MP3: 0 matched files had an empty BEFORE tag set, and the
sample carries 295 `GEOB`, 285 `TCON`, 245 `COMM`, 230 `APIC`, 130 `TPOS`, 110 `TXXX`, 110 `TBPM`
and 40 `TKEY` frames on the BEFORE side. There was a great deal there to drop.

---

## What neither `diff-music-tags.sh` nor `ffprobe` could see

The ID3v2 frame-ID multiset of every file, parsed off disk **without mutagen and without taglib**,
against its untouched `raw/` twin:

| Assertion | mutagen arm | `metadata` arm |
|---|---|---|
| ID3v2 major version, `raw/` → arm | **(3, 3) on all 335** | **(3, 3) on 130; (3, 4) on 205** |
| Files whose frame-ID multiset moved | **40** | **175** |
| The complete list of the differences | `TALB` 0→1 ×30 · `TPE1` 0→1 ×10 | `TALB` 0→1 ×30 · `TPE1` 0→1 ×10 · **`TYER` 1→0 ×155** · **`TDRC` 0→1 ×155** |

**`metadata` promotes every file it writes from ID3v2.3 to ID3v2.4, unconditionally, with no flag to
prevent it — and in doing so converts `TYER` to `TDRC` on 155 files.** This is the **exact defect
class** 03-05 found in mutagen's `v2_version` default (deviation 4) and eliminated by reading the
major version out of the file's own 10-byte header before loading. There, it was a bug that could
be fixed; here it is the tool's behaviour and there is no knob.

**`ffprobe` maps both `TYER` and `TDRC` to `date`, so `diff-music-tags.sh` reported nothing** — the
`date` field appears in neither arm's changed, gained or dropped set. 03-05 recorded that blindness
as a finding about the instrument; this plan is the second time it has hidden a real write, and the
first time it has hidden one that cannot be turned off.

Whether v2.4 is *worse* than v2.3 is a separate question and this document does not claim it is. It
is a change to 205 files that was **not requested, not reported by the tool, not visible to the
gate, and not preventable** — which is what rule 4 ("touch nothing else") exists to exclude.

---

## Tag preservation

The plan's A3 question: does `metadata write`'s `tags.WriteTags(path, t, 0)` — flag `0`, not
`tags.Clear` — genuinely merge rather than replace, at the **taglib** layer? Read from source in
03-RESEARCH.md's Assumptions Log and explicitly flagged as unconfirmed there.

Sample-specific denominators first, because the `148 TKEY / 45 EnergyLevel` figures D-08 and
03-DECISION.md quote are across Phase 1's whole **764-file `dj-mixes` ffprobe fence**, not across
this 335-file draw. This draw's own share, measured on the BEFORE side:

| Field | In the 764-file fence | **In this 335-file sample** |
|---|---|---|
| `TKEY` | 148 | **40** |
| `EnergyLevel` (inside `TXXX`) | 45 | **20** |
| `TBPM` | — | 110 |

| Assertion | mutagen arm | `metadata` arm |
|---|---|---|
| `TKEY` — snapshot tooling, before → after | **40 → 40**, lost 0 | **40 → 40**, lost 0 |
| `EnergyLevel` — snapshot tooling | **20 → 20**, lost 0 | **20 → 20**, lost 0 |
| `TBPM` — snapshot tooling | **110 → 110**, lost 0 | **110 → 110**, lost 0 |
| `TKEY` — **live `ffprobe`**, present on | **40 of 40** | **40 of 40** |
| `EnergyLevel` — **live `ffprobe`**, present on | **20 of 20** | **20 of 20** |
| `TKEY` **values** vs the untouched `raw/` twin | **0 mismatches of 40** | **0 mismatches of 40** |
| `EnergyLevel` **values** vs the twin | **0 mismatches of 20** | **0 mismatches of 20** |
| Control: `TKEY` present on the 40 `raw/` twins | **40 of 40** | — |

**The two instruments agree on every cell, so the numbers are recorded.**

> **A3 is CONFIRMED — with a boundary that must travel with it.**
>
> **Confirmed:** `metadata write` merges within the ID3v2 tag. It did not drop a single one of the
> 40 `TKEY`, 20 `EnergyLevel` or 110 `TBPM` frames, nor change one of their values, and
> `FIELDS_DROPPED` is 0 on both joins. D-12 row 3b's *"`metadata write` merges; it will not silently
> drop `TKEY`/`EnergyLevel`"* is **true and now measured**, not inferred.
>
> **The boundary:** the merge guarantee holds **only inside the ID3v2 container**. Outside it the
> same `save()` rewrote the ID3v1 block on 175 files, **created one on 30 files that had none**,
> re-serialised the APEv2 tag on 14, and promoted the ID3v2 tag itself from v2.3 to v2.4 on 205.
> None of those is a *loss* — audio identical on 335/335, no APE item lost, no frame removed — and
> none of them is visible to `diff-music-tags.sh` either.
>
> This is a materially narrower guarantee than 03-DECISION.md's row 3b implies, and it is the
> opposite failure mode from row 3c: a real `wrtag move`/`copy` calls `WriteTags(..., tags.Clear)`
> and **wipes** unlisted tags (03-08, source-only). `metadata write` **adds**.

---

## The WAV question

Research Open Question 5 and the second of the plan's two named reasons for running the bake-off at
all: *"`metadata`'s `go.senan.xyz/taglib` backend may handle the 134 WAV files better than mutagen
does — which would be a genuine, unanticipated reason to prefer it for one stratum."*

**The 03-03 draw contains zero WAV** — `03-SAMPLE.md` says so explicitly and says this plan
"cannot use this sample and needs WAV folders named separately". It does. **A WAV-free sample must
not be allowed to read as a WAV pass**, so the stratum was staged, named and measured on its own.

### The population, named

All 134 WAV files in `dj-mixes`, in three folders, reflinked into three fresh trees on atlantis.
134 reproduces `beets.md`'s and `03-SAMPLE.md`'s corrected figure exactly. All three folders are
**scan-bearing**, which is why the 03-03 draw excluded them — an exclusion made for the Discogs
rate measurement and irrelevant to a tag-write comparison.

| Folder | Files | 03-SAMPLE stratum | Tag state on the BEFORE side |
|---|---|---|---|
| `Now_That_s_What_I_Call_Music__118__2Cd__2024___OP_VERZOEK` | 47 | V3 | **no tag chunk at all** — `fmt `, `data`, nothing else |
| `Now_That_s_What_I_Call_Music__119__2Cd__2024` | 44 | V6 | `id3 ` **ID3v2.3** (UTF-16) + `LIST`/`INFO`, embedded cover art |
| `Now_That_s_What_I_Call_Music__120__2Cd__2025` | 43 | V6 | same |

Split by content rather than by folder: **47** with no tags, **83** with ASCII-only ID3 text frames,
**4** whose `TPE1` carries non-ASCII (`Michael Bublé`, `ROSÉ & Bruno Mars`, `Tiësto Ft Oaks`,
`The Marías`).

### The job, and why it is not "the same normalisation"

**Running the committed rules on WAV would have measured nothing, and that is a measurement, not an
excuse.** `normalise-dj-tags.py --dry-run` over all 134 files reports **`files that would change:
0`**: rules 1 and 3 require a label token (Mastermix / DMC) derivable from the folder name and
`Now_That_s_What_I_Call_Music__120__2Cd__2025` has none, while rule 2 fires only on DJ-service album
noise. **The estate's only WAV is Now-compilation content, and D-08's DJ-service rules are a no-op
on all of it.**

Both arms were therefore given the same minimal one-field job: **set `album` to a folder-derived
canonical string on all 134 files** (`Now That's What I Call Music 118/119/120`). It exercises tag
**creation** on the 47 untagged files and tag **update** on the 87 tagged ones, and keeps the
expected change set to exactly one field, so anything else that moves is out of contract.

The mutagen arm does **not** re-implement the write: it imports `read_tags` and `write_tags` out of
the committed module, so the bytes that reach the file are produced by the same code including its
`WRITABLE_FIELDS` assertion. 03-05's Known Stubs recorded that path as *"implemented and untested
against real files — plan 03-09's D-13 bake-off is the first thing that will exercise it"*.

### Result

| Quantity | mutagen arm | `metadata` arm |
|---|---|---|
| Files attempted | 134 | 134 |
| **Files written** | **0** | **130** |
| **Failures** | **134** | **4** |
| Failure mode | `TypeError: ['Now That's What I Call Music 118'] not a Frame instance`, on every file | `taglib_file_tags` / `taglib_file_write_tags`: `__cxa_allocate_exception (recovered by wazero)` |
| Elapsed | 0.27 s (all failures) | 3 s |
| Invocations | 1 process | 268 |
| `diff-music-tags.sh` `FIELDS_DROPPED` | 0 | **0** |
| `diff-music-tags.sh` gained / changed | **0 / 0** | **`album` 47 gained, `album` 83 changed — and nothing else** |
| `diff-music-tags.sh` exit code | **0** | **0** |
| audio_md5 matched | 134 of 134 | 134 of 134 — **the PCM stream did not move** |
| Embedded cover art (`mjpeg` attached_pic) | n/a | **survived** |
| `LIST`/`INFO` chunk | n/a | preserved and **updated in step with the ID3 tag** |

> **The mutagen arm's exit 0 is a VACUOUS PASS and is recorded as UNTESTED, NOT PASSED.**
> `FIELDS_DROPPED = 0` because **nothing was written**: 0 files changed on disk, confirmed by an
> empty whole-subtree `.sha` manifest diff. `diff-music-tags.sh` also reported *"Matched files whose
> BEFORE tag set was empty: 47"* — its own vacuous-pass counter, firing on the untagged folder. A
> field-loss gate cannot distinguish "lost nothing" from "did nothing", and here it did nothing.

### Why each arm failed, established rather than assumed

**mutagen — a defect in *our* script, not a limitation of the library.** `mutagen.File(path,
easy=True)` on a WAVE does **not** yield an EasyID3-style mapping: `handle.tags` is a raw `ID3`
object keyed by **frame id**, so the committed line `handle.tags[field] = [new]` assigns a list
where a `Frame` is required. Confirmed by writing the same value through mutagen's correct WAVE API
on three probe copies — one untagged, one ASCII-tagged, one non-ASCII-tagged:

| Probe file | committed code path | `WAVE()` + `TALB(encoding=3)` |
|---|---|---|
| untagged (folder 118) | `TypeError: … not a Frame instance` | **OK**, reads back; `id3 ` chunk created |
| tagged, ASCII (folder 119) | `TypeError` | **OK**; `APIC`, `TDRC`, `TIT2`, `TPE1`, `TRCK` all intact |
| tagged, **non-ASCII** (folder 120, `Tiësto`) | `TypeError` | **OK**; `artist` `Tiësto Ft Oaks` preserved verbatim |

**mutagen can write these WAV files, including the one `metadata` cannot open at all.** The bug is
ours and it is a few lines deep. One caveat found in the same probe and recorded rather than
glossed: mutagen's WAVE write leaves the `LIST`/`INFO` chunk **byte-identical**, so its `IPRD`
(product/album) still carries the *old* album while the ID3 tag carries the new one — a divergence
between two containers in the same file. `metadata` updates both (136 → 144 bytes). Whoever fixes
the WAV path owns that question too.

**`metadata` — the 4 failures are content, not path.** All four filenames contain non-ASCII, which
made a path-encoding bug the obvious hypothesis. **It is falsified:** a copy of the failing
`ROSÉ & Bruno Mars` file renamed to a pure-ASCII path fails identically, and all 3 of the 335 MP3
files with non-ASCII paths succeeded. The correlation is with the **tag content**: of the three
content classes, `no tags` (47) → 0 failures, `ASCII ID3 text` (83) → 0 failures, **`non-ASCII ID3
text` (4) → 4 failures**. `metadata` can neither read nor write those files; it throws inside
TagLib compiled to WASM and running under wazero.

### What `metadata` did to the 130 it wrote

| Chunk state | BEFORE (`wav-raw`) | AFTER (`wav-metadata`) |
|---|---|---|
| no ID3 chunk | 47 | 0 |
| `id3 ` (lower case), ID3v2.**3**, UTF-16 | 83 | 0 |
| `id3 ` (lower case), ID3v2.**3**, non-ASCII | 4 | **4** (untouched — the failures) |
| **`ID3 ` (UPPER case), ID3v2.4** | 0 | **130** |

Two more out-of-contract effects, both invisible to the gate and both the WAV analogue of what it
did to MP3: the **chunk id is rewritten `id3 ` → `ID3 `** (RIFF chunk ids are case-sensitive by spec
and lower-case `id3 ` is the de-facto standard for WAV; `ffmpeg` reads both, so this is a spec
deviation rather than a loss), and the tag is **promoted to ID3v2.4**, with new frames written UTF-8
beside the pre-existing UTF-16 ones.

*(An earlier reading of this census reported one file as having gained non-ASCII text. That was a
false positive in the census script, not in the data: ID3v2.4 frame sizes are syncsafe and the
parser was reading them as plain big-endian, desynchronising into the `APIC` payload. Corrected and
re-run; the file's `title` bytes are identical before and after. Recorded because an uncorrected
instrument defect is exactly what this phase keeps finding.)*

### Answer to Open Question 5

**`metadata` handles WAV; the committed mutagen script does not — 130 written against 0.** That
overturns the prediction's *"may win on WAV"* by a wider margin than it anticipated. But it is
**not** a reason to adopt `metadata` for the WAV stratum, for three measured reasons: the mutagen
failure is a defect in our own script that mutagen's own API resolves on the first try, including on
the exact file `metadata` cannot open; `metadata` hard-fails on **3.0%** of the stratum (4 of 134)
and there is no reason to think non-ASCII artists are rarer in the rest of the estate than in a Now
compilation; and its WAV write carries the same unrequested v2.3→v2.4 promotion, plus a chunk-id
case change, that it applies to MP3.

---

## Wall-clock and lines of driver

| Measure | mutagen arm | `metadata` arm |
|---|---|---|
| MP3: elapsed, in-container | **13.99 s** (03-05 apply) | **13 s** (docker wall-clock 14 s) |
| MP3: dry run, elapsed | 7.7 s | **no dry run exists** |
| MP3: tool invocations | 1 | **540** |
| WAV: elapsed | 0.27 s (0 written) | 3 s (130 written) |
| WAV: tool invocations | 1 | **268** |
| **Lines of driver** | **0.** The committed 948-line (783 code) script *is* the tool; there is nothing else to write or maintain | **134 total / 80 code lines of bespoke `sh`**, plus a second 134-line variant for WAV, plus — in any real deployment — the whole rule layer, which this bake-off handed it for free |

**Wall-clock is a dead heat and should not be read as one of the deciding axes.** 13 s against
13.99 s on 335 files is within the noise of a single run on a shared host, and 540 process
executions cost less than expected because `metadata` is a static Go binary. Throughput is not what
separates these tools.

**Lines of driver is the axis that separates them, and the figure above understates it.** The
mutagen arm's driver is the artefact itself: committed under `scripts/`, reviewed, sha-verified
against the committed blob before every run, carrying its own `--dry-run` default, its own
`SCRATCH_ROOT` refusal, its own snapshot-proof refusal and its own post-write frame-set assertion.
The `metadata` arm's 80 lines are **additional** shell that would also have to be committed,
reviewed and maintained — and this run proved they need it, because 20 files were written wrong by
line 81 of that shell on the first attempt.

---

## Verdict (D-13)

> **The normalisation tool is the committed mutagen script, `scripts/normalise-dj-tags.py`. This
> verdict holds regardless of which engine wins the main decision — if wrtag wins axis one, the
> mutagen script is still the normaliser; if beets wins, likewise.** The verdict is **not** split by
> stratum.

**On the MP3 stratum the two tools are a dead heat on every axis the phase's own instrument can
measure** — identical field-loss result, identical after-state, indistinguishable wall-clock. The
decision therefore turns on the axes the instrument cannot see, and on all of them the mutagen
script wins:

1. **Reviewability, demonstrated rather than argued.** `metadata write` has no dry run and prints
   nothing on success. This plan's own `metadata` driver wrote the artist value into the album field
   on 20 of 205 files, and `diff-music-tags.sh` scored that run `FIELDS_DROPPED = 0` — a clean pass
   on a wrong result. The mutagen arm's equivalent error would have appeared in a 292-line reviewed
   diff before a byte was written, and 03-05 proved that diff is an exact prediction of the apply.
2. **Blast radius, measured.** The mutagen script's on-disk footprint is exactly the 40 frames its
   rules created; ID3v1 and APEv2 byte-unchanged, ID3v2 version unchanged. `metadata` additionally
   promoted 205 files to ID3v2.4, converted 155 `TYER` to `TDRC`, rewrote 175 ID3v1 blocks and
   created 30 — **none of it requested, none of it reported, none of it preventable, and none of it
   visible to the gate.**
3. **Ownership.** 0 lines of bespoke driver against 80, on a project whose stated core value is
   *exactly one pipeline that someone owns*.

**The WAV stratum does not split the verdict, and the reasoning is stated so it can be argued
with.** `metadata` wrote 130 WAV files and the committed script wrote 0, which on the raw numbers is
the strongest single result against the prediction anywhere in this bake-off. It is nonetheless not
enough, because the mutagen failure is a **defect in our own script** — three lines in its non-MP3
path — and mutagen's correct WAVE API writes all three probe classes on the first attempt, including
the file `metadata` cannot open at all. Adopting `metadata` for one stratum would buy a working WAV
path that fails on 3.0% of it, at the cost of two tools, two drivers and two review surfaces for one
job. Fixing three lines buys a working WAV path with no such cost.

**What this verdict costs, stated plainly.** It leaves `scripts/normalise-dj-tags.py` with a
**broken WAV path today** — 0 of 134, failing loudly rather than silently, but failing. That is a
real, currently-unfixed gap and it is carried as such rather than dissolved into the verdict. It is
scoped: 268 of the estate's 8,492 audio files are WAV (**3.2%**), all of it Now-compilation content
in six folders across two trees, and none of it is DJ-service content the three committed rules
would fire on anyway.

**What would overturn this verdict:** a WAV fix that cannot be made to work through mutagen's WAVE
API (falsified here on three probe files, so it would take new evidence); or a corpus where the
`TYER`→`TDRC`/v2.4 promotion is desirable rather than merely unrequested; or a normalisation job
with no per-file distinct values, where `metadata`'s one-literal-map-per-invocation shape stops
being a cost.

---

## Health of the estate around the run

| Assertion | Result |
|---|---|
| `bash scripts/check-music-freeze.sh` | **exit 0** — `tagger-class writers: 0`, `unclassified writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` |
| Beets databases under `/mnt/fast/appdata` (`*.blb` **and** `library.db`, per DEF-03-02) modified during this plan | **0 of 4** — `diff` of the before/after mtime listing is empty |
| `.bak` files created under `/mnt/fast/appdata/arrs` | **0** |
| `/tmp` entries matching `spike` on LXC 100 | **0** |
| wrtag or spike containers left in `docker ps -a` | **0** — every arm used `--rm` |
| `df -h /` on LXC 100 | **35 G free**, unchanged across the plan |
| `/mnt/fast/spike-03/out` footprint | **12 M** — the 03-03 finding-4 constraint watched, not assumed |
| Reflink SOURCE of the WAV trees, in the live backlog | `.meta` manifest diff **empty** — the three `complete/nzb/dj-mixes` folders are untouched |
| MP3 arms `raw/` and `normalised/` after every run | `find -newer` **0 lines**, `.meta` and `.sha` diffs **empty** |
| `wav-raw/` and `wav-mutagen/` after every run | `.meta` and `.sha` diffs **empty** (the mutagen WAV arm wrote nothing) |

`tagger-class writers: 0` carries the standing **DEF-03-01** caveat for the fourth time in this
phase: `check-music-freeze.sh`'s `TAGGER_PATTERN` cannot match `sabnzbd`, which runs beets as a live
post-processing path over the same backlog trees the WAV arm reflinked from. The decisive
attribution here is the mount table, not the clock: **no container in this plan mounted
`/mnt/fast/appdata` or `/mnt/tank/downloads/complete` at any mode**, and the source folders' manifest
is byte-identical before and after.

The throwaway `wav-probe2` tree (3 files, 117 M reflinked) was removed after the WAV feasibility
probe. Plan 03-11's teardown must remove `spike-03/normalised-metadata`, `spike-03/wav-raw`,
`spike-03/wav-mutagen` and `spike-03/wav-metadata`, none of which existed when 03-03 created the
scratch root.
