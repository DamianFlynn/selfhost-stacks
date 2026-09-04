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
