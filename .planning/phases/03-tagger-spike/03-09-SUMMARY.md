---
phase: 03-tagger-spike
plan: 09
subsystem: d13-normaliser-bakeoff
tags: [metadata, taglib, mutagen, wav, id3v1, id3v2.4, apev2, manifest-diff, vacuous-pass, TAGR-02, D-13, A3, OQ5]
requires:
  - "03-05 — the mutagen arm, its 292-record proposal set, and the write-broadening defaults it fixed"
  - "03-07 — the T1/T2 verdicts and the instrument corrections this plan inherits"
  - "03-08 — tags.Clear, the unloggable wipe, and the sentriz/wrtag:v0.34.0 image already pulled and audited"
  - "03-03 — the 24-folder draw, the atlantis reflink route, and the 335-record BEFORE capture both arms are scored against"
provides:
  - ".planning/phases/03-tagger-spike/03-NORMALISER-BAKEOFF.md — D-13's head-to-head: capability matrix from observation, field loss on two joins, tag preservation, the WAV stratum, wall-clock, lines of driver, and the verdict"
  - "the D-13 verdict in 03-DECISION.md: the normalisation tool is scripts/normalise-dj-tags.py, regardless of which engine wins axis one"
  - "A3 settled empirically — metadata write merges INSIDE ID3v2 and not outside it"
  - "Open Question 5 answered on its own staged 134-file WAV stratum rather than on a WAV-free sample"
  - "DEF-03-09 — normalise-dj-tags.py cannot write WAV, 0 of 134, and it is our defect not mutagen's"
  - "DEF-03-10 — the field-loss gate has now scored FIELDS_DROPPED = 0 on three writes nobody asked for"
  - "/mnt/tank/downloads/spike-03/normalised-metadata and the three wav-* trees, plus 12 subtree manifests"
affects:
  - "03-11 — the axis-one and criterion-6 record reads the D-13 verdict from here; teardown must also remove normalised-metadata, wav-raw, wav-mutagen and wav-metadata"
  - "Phase 4 TAGR-04 — owns DEF-03-09, the WAV write path, and the LIST/INFO-versus-ID3 divergence question it raises"
  - "Phase 7 QUAL-02 — DEF-03-10: the gate detects loss, not wrongness, and is blind to ID3v1, APEv2 and the TYER/TDRC translation"
tech-stack:
  added: []
  patterns:
    - "Handing the challenger the incumbent's own computed proposal set, so the bake-off measures the WRITING TOOL rather than two different transformations — and saying out loud that this makes its lines-of-driver a lower bound"
    - "Keeping and reporting a defective first run because it is the strongest evidence in the comparison, rather than re-running quietly from a clean tree"
    - "Diffing the two arms' AFTER-states directly against each other, which is the only instrument that could see a correct-shaped wrong value"
    - "Splitting an MP3 into its four containers (ID3v2 | audio | APEv2 | ID3v1) and comparing each against an untouched twin, because the phase's gate sees only one of them"
    - "Falsifying the obvious hypothesis before recording it — the non-ASCII WAV failures correlate with filenames, and an ASCII rename proved it is the tag content"
    - "Answering an open question on a stratum the sample structurally cannot cover, by staging that stratum separately rather than letting a silent absence read as a pass"
key-files:
  created:
    - .planning/phases/03-tagger-spike/03-NORMALISER-BAKEOFF.md
  modified:
    - .planning/phases/03-tagger-spike/03-DECISION.md
    - .planning/phases/03-tagger-spike/deferred-items.md
decisions:
  - "D-13: the normalisation tool is scripts/normalise-dj-tags.py, and it holds regardless of which engine wins the main decision. Not split by stratum"
  - "The WAV overturn is recorded and then argued down rather than suppressed: metadata wrote 130 of 134 against the committed script's 0, but the mutagen failure is a three-line defect in OUR script that mutagen's own WAVE API resolves, and metadata hard-fails on 3.0% of the stratum"
  - "A3 is CONFIRMED with a boundary: metadata write merges inside the ID3v2 container and nowhere else — it promotes v2.3 to v2.4 on every file it writes, with no flag to prevent it"
  - "Run 1's defect is kept in the record because a tool with no dry run producing a clean FIELDS_DROPPED = 0 on a wrong result IS the reviewability finding"
  - "The WAV job is a one-field album write, not the three committed rules, because a dry run proved those rules change 0 of 134 WAV files"
  - "TAGR-02 is NOT marked complete: this plan settles D-13, it does not establish that the surviving tagger can own the whole tree"
metrics:
  duration: "~1h"
  completed: 2026-09-04
---

# Phase 3 Plan 09: The D-13 Normaliser Bake-Off Summary

Ran wrtag's `metadata` against the mutagen script on one normalisation job, two arms, the same
before-state, the same instrument — and found the two **indistinguishable on MP3 as the phase's own
gate sees them** (identical after-states, 0 fields dropped, 13 s versus 13.99 s), so the verdict
turns entirely on what the gate cannot see. It saw none of `metadata` promoting 205 files to
ID3v2.4, and none of this plan's own driver writing the **artist value into the album field on 20 of
205 files**.

## What was built and run

**Three arms, three trees, all reflinked from the same source on atlantis** (`FICLONE` is `EPERM`
inside the unprivileged container, the 03-03 route):

- **`spike-03/normalised-metadata`** — the `metadata` arm, 24 folders / 364 files / 335 mp3,
  asserted byte-identical to `raw/` before each run by comparing whole-subtree `sha256sum` manifests
  with the path prefix rewritten.
- **`spike-03/wav-raw` / `wav-mutagen` / `wav-metadata`** — the WAV stratum, 3 folders / 161 files /
  **134 wav** each, staged by this plan because `03-SAMPLE.md` records that the draw contains
  **zero WAV** and that this plan "cannot use this sample and needs WAV folders named separately".

**`metadata-driver.sh`** (134 lines / 80 code) — busybox `sh` inside `sentriz/wrtag:v0.34.0`, one
`metadata read` plus one `metadata write` per file. Three design points carry the weight:

1. **The handicap is removed in `metadata`'s favour, and said out loud.** The driver does not
   re-implement the three normalisation rules; it is handed the mutagen script's own 292-record
   proposal set as a TSV. `metadata` competes without paying for the rule logic, so its
   lines-of-driver figure is a **lower bound**.
2. **The mandatory preflight runs inside the container** and refuses on a folder/file count
   mismatch — the 03-05 stale-inode vacuous pass. Both runs printed `folders=24 files=335`,
   cross-checked against the host and the draw table.
3. **A PASS-2a branch-count assertion refuses before any write** if the shell's split of the TSV
   disagrees with the generator's `awk -F'\t'` count. That checks the *driver's own parse*; it is
   deliberately **not** a dry run for `metadata`, because a wrapper would measure the wrapper.

**`.planning/phases/03-tagger-spike/03-NORMALISER-BAKEOFF.md`** — the prediction quoted verbatim
from a commit that predates the run, the driver recorded in full, run 1's defect, both scorings, the
container-level comparison, the WAV stratum, and the verdict.

## Results

| Assertion | Result |
|---|---|
| `normalised-metadata` byte-identical to `raw/` at staging (twice) | **yes**, both times |
| Per-folder mp3 counts vs the `03-SAMPLE.md` draw table | **0 mismatches** across 24 folders, 335 files |
| In-container preflight | `folders=24 files=335`, both runs |
| **MP3 arm — invocations / elapsed / failures** | **540** (335 read + 205 write) / **13 s** (docker 14 s) / **0** |
| Branch split, asserted not reported | **87 / 98 / 20**, matching the generator's `awk` count |
| `metadata write` output on 205 successful writes | **0 lines** — it prints nothing |
| Files changed in the metadata arm | **exactly 205**; the other 130 untouched |
| Blast radius — `find -newer`, `raw/` and `normalised/` | **0 lines** each |
| Blast radius — whole-subtree `.meta` and `.sha` manifest diffs, both trees | **empty**, all four |
| **`diff-music-tags.sh`, audio_md5 join — mutagen** | MATCHED 306, MISSING 0, **DROPPED 0**, gained 35, changed 237, **exit 0** |
| **`diff-music-tags.sh`, audio_md5 join — `metadata`** | MATCHED 269, **MISSING 37**, **DROPPED 0**, gained 35, changed 179, **exit 1** |
| The 37 attributed, not assumed | **audio region byte-identical on 335 of 335**; it is DEF-03-03 — `metadata` rewrites the ID3v1 block, the mutagen script restores it byte-for-byte |
| **Path-keyed join — both arms** | 335 matched, 0 missing, **0 dropped**, gained `album` 30 + `artist` 10, changed `album` 155 + `artist` 97 — **identical** |
| **AFTER(mutagen) vs AFTER(`metadata`), path-keyed** | **0 dropped, 0 gained, 0 changed** on all 335 files |
| `TKEY` / `EnergyLevel` / `TBPM`, snapshot tooling, both arms | **40→40 / 20→20 / 110→110**, 0 lost |
| Live `ffprobe` cross-check, both arms | `TKEY` **40 of 40**, `EnergyLevel` **20 of 20**; **values 0 mismatches** vs the untouched twin |
| ID3v2 major version, `raw/` → arm | mutagen **(3,3) on all 335**; `metadata` **(3,4) on 205** |
| ID3v2 frame-ID multiset moved | mutagen **40** files (= the 40 frames its rules created); `metadata` **175** (`TYER` 1→0 ×155, `TDRC` 0→1 ×155) |
| ID3v1 rewritten / created / removed | mutagen **0 / 0 / 0**; `metadata` **175 / 30 / 0** |
| APEv2 re-serialised / item keys changed / item values changed | mutagen **0 / 0 / 0**; `metadata` **14 of 14 / 0 / 0** |
| **WAV — files written** | mutagen **0 of 134**; `metadata` **130 of 134** |
| WAV — failures | mutagen **134** (`TypeError: … not a Frame instance`); `metadata` **4** (taglib-on-WASM throw) |
| WAV — `diff-music-tags.sh` | mutagen 0/0/0, **exit 0 — a vacuous pass**; `metadata` `album` 47 gained + 83 changed, **0 dropped**, exit 0 |
| WAV — audio_md5 matched, both arms | **134 of 134** — the PCM stream did not move |
| WAV — embedded cover art after the `metadata` write | **survived** |
| `bash scripts/check-music-freeze.sh` | **exit 0**, `FAILURES total: 0` |
| Beets databases (`*.blb` **and** `library.db`, DEF-03-02) modified | **0 of 4** |
| wrtag / spike containers in `docker ps -a` afterwards | **0** — every arm `--rm` |
| `df -h /` | **35 G free**, unchanged |

## The findings that outlive this plan

**1. On MP3 the two tools produced identical output, so the decision is about what the instrument
cannot see.** Diffing the two arms' after-states directly, path-keyed: **0 dropped, 0 gained, 0
changed** on all 335 files, and wall-clock 13 s against 13.99 s. Every real difference lives in a
container `ffprobe` does not surface. Any comparison of these tools that stops at
`diff-music-tags.sh` will report a tie.

**2. A tool with no dry run wrote the wrong value into the wrong field, and the gate passed it.**
The driver's first run used `IFS=$TAB read -r p album artist`. **TAB is an IFS *whitespace*
character**, so the empty album column collapsed and the artist value landed in `$album`: 20 of 205
files got `album="Mastermix"` with their placeholder artist untouched. `diff-music-tags.sh` scored
that run `FIELDS_DROPPED = 0` — identical to the correct run — because **a correct-shaped wrong
value drops no field**. The mutagen arm's equivalent error would have appeared in a 292-line
reviewed diff before a byte was written, and 03-05 proved that diff is a sha256-exact prediction of
the apply. This is the reviewability argument, demonstrated instead of asserted.

**3. A3 is confirmed, and its boundary is narrower than the source read implied.** `metadata write`'s
flag-`0` `WriteTags` **does** merge inside ID3v2: `FIELDS_DROPPED` 0 on both joins, `TKEY` 40→40,
`EnergyLevel` 20→20, `TBPM` 110→110, values byte-identical, `ffprobe` agreeing on every cell. But the
same `save()` **promotes ID3v2.3 to v2.4 on every file it writes** (205 of 335, `TYER`→`TDRC` on
155), rewrites the ID3v1 block on 175, **creates one on 30 files that had none**, and re-serialises
any APEv2 tag (14 of 14, key set and values unchanged). Nothing is lost — audio byte-identical on
335 of 335 — but nothing about it was requested, reported, preventable or visible to the gate. This
is the **same defect class** 03-05 found in mutagen's `v2_version` default and fixed; here there is
no knob.

**4. `metadata` cannot open a file whose tags carry non-ASCII, and the obvious explanation is
wrong.** 4 of 134 WAV files threw `__cxa_allocate_exception (recovered by wazero)` inside TagLib
compiled to WASM, on both `read` and `write`. All four filenames contain non-ASCII, which made a
path-encoding bug the obvious hypothesis — **falsified**: an ASCII-renamed copy of a failing file
fails identically, and all 3 of the 335 MP3 files with non-ASCII paths succeeded. The correlation is
with **ID3 text-frame content**: no tags 47 → 0 failures, ASCII ID3 text 83 → 0 failures, **non-ASCII
ID3 text 4 → 4 failures**.

**5. The committed normaliser cannot write WAV at all, and it is our bug (DEF-03-09).** 0 of 134,
`TypeError: [...] not a Frame instance` on every file, because `mutagen.File(path, easy=True)` on a
WAVE returns a raw frame-id-keyed `ID3` rather than an EasyID3 map. `diff-music-tags.sh` scored that
`exit 0` with `FIELDS_DROPPED = 0` — **a vacuous pass bought by writing nothing**, recorded as
**untested, not passed**. mutagen's correct `WAVE()` API wrote all three probe classes on the first
attempt, **including the exact non-ASCII file `metadata` cannot open**, preserving `APIC`, `TDRC`,
`TIT2`, `TPE1` and `TRCK`.

**6. The DJ normalisation rules are a no-op on 100% of the estate's WAV.** A dry run of the
committed script over all 134 files reports `files that would change: 0`: rules 1 and 3 need a
Mastermix/DMC label token in the folder name and the only WAV in the estate is `Now That's What I
Call Music` 118/119/120. Running "the same normalisation" on WAV would have measured nothing, which
is why both arms were given a one-field album write instead — and why DEF-03-09, while real, does
not block this phase's actual backlog.

## Deviations from Plan

### 1. [Rule 1 - Bug] The driver split its own input wrong and wrote 20 files incorrectly

- **Found during:** Task 1, by diffing the two arms' after-states — not by any gate.
- **Issue:** finding 2 above. `IFS=$TAB read -r p album artist` collapses the empty album column
  because TAB is IFS whitespace; the 20 artist-only proposals were written into `album`.
- **Fix:** fields are split by parameter expansion (`${line%%"$TAB"*}` / `${rest#*"$TAB"}`), and a
  PASS-2a branch-count assertion now refuses **before any write** if the shell's split disagrees
  with the generator's `awk -F'\t'` count. The mechanism was demonstrated in isolation inside the
  same image before the fix was accepted.
- **`normalised-metadata/` was re-materialised from `raw/` on atlantis and re-asserted
  byte-identical**, so every recorded number comes from one clean invocation of the fixed driver.
  Run 1's artefacts are retained under `/mnt/fast/spike-03/out/bakeoff-run1/`.
- **Reported, not buried:** run 1 is the strongest evidence in the bake-off and has its own section
  in the artefact.
- **Commit:** `7c82cd0`

### 2. [Rule 2 - Missing correctness requirement] The WAV question needed a stratum the sample cannot contain

- **Found during:** Task 1, before staging.
- **Issue:** the plan asks for the WAV result to be "broken out by dominant file format" from the
  same run. **The 03-03 draw contains zero WAV** — `03-SAMPLE.md` states this and states that this
  plan needs WAV folders named separately. Reporting a per-format split of a WAV-free sample would
  have let a silent absence read as a WAV pass.
- **Fix:** the WAV stratum was staged, named and measured on its own — all 134 `dj-mixes` WAV in
  three reflinked trees, with its own before-snapshot, its own scoring and its own section. The MP3
  per-format breakdown is still reported (`mp3` 335, and it is the whole sample).
- **Second, discovered while doing it:** the three committed rules change **0 of 134** WAV files, so
  "the same normalisation" is unmeasurable on WAV. Both arms were given the same minimal one-field
  album write instead, which exercises creation on the 47 untagged files and update on the 87 tagged
  ones. Stated in the artefact rather than presented as if the rules had run.
- **Commit:** `46aac6e`

### 3. [Rule 2 - Missing correctness requirement] The mutagen WAV arm needed a driver the plan does not describe

- **Found during:** Task 1. Since the committed rules do not fire on WAV, `normalise-dj-tags.py`
  could not be invoked directly for the mutagen arm.
- **Fix:** a 79-line driver that **imports** `read_tags` and `write_tags` out of the committed
  module rather than re-implementing them, so the bytes reaching the file are produced by the same
  code including its `WRITABLE_FIELDS` assertion — and keeps `--dry-run` as the default, mirroring
  the committed flag convention. This is the first time 03-05's non-MP3 path has ever been
  exercised, exactly as 03-05's Known Stubs predicted.
- **Commit:** `46aac6e`

### 4. [Method] A three-file feasibility probe was added to keep the verdict honest

- The verdict argues the WAV overturn down on the grounds that the mutagen failure is *our* defect.
  That claim would have been an assertion, so it was measured: three probe copies (untagged,
  ASCII-tagged, non-ASCII-tagged) written through mutagen's correct `WAVE()` API, all three
  succeeding with every other frame intact. The probe tree was removed afterwards.
- It also surfaced a caveat the fix must own and which is recorded in DEF-03-09: mutagen's WAVE
  write leaves the RIFF `LIST`/`INFO` chunk byte-identical, so its `IPRD` keeps the old album while
  the ID3 tag carries the new one. `metadata` updates both.
- **Commit:** `46aac6e`

### 5. [Method] A pre-write snapshot was taken for the WAV arms, beside the proof the script demands

`normalise-dj-tags.py` hard-codes `tank/downloads@spike-03-t0` as the only proof it accepts, and
that snapshot predates the WAV trees. `tank/downloads@spike-03-t2-wav` was taken on atlantis
**before** the WAV writes as the honest rollback, and the proof file names **both**. The real safety
is stronger than either: the WAV trees are reflinked copies and the source folders in
`complete/nzb/dj-mixes` were proven byte-identical before and after by a `%p\t%s\t%T@` manifest.

### 6. [Scope] Two instrument defects of my own, found and corrected before anything was recorded

- The WAV chunk census matched the ID3 chunk id as literal `b"id3 "` and reported the tag as
  **removed** on 130 files. `metadata` had rewritten the id as `ID3 ` (upper case). Corrected to
  match case-insensitively and to report which case was seen; nothing was removed.
- The same census then reported one file as having **gained** non-ASCII text. False positive:
  ID3v2.4 frame sizes are syncsafe and the parser was reading them as plain big-endian,
  desynchronising into the `APIC` payload. Corrected and re-run; the file's `title` bytes are
  identical before and after. Both are recorded in the artefact rather than silently fixed, because
  an uncorrected instrument defect is what this phase keeps finding in other people's tools.

### 7. [Deferred to the orchestrator] Delivery to LXC 100 was out-of-band, and no branch was pushed

A worktree executor cannot push, and `/mnt/fast/stacks` sits at `c88c268`. The drivers and analysis
scripts were staged to `/mnt/fast/spike-03/out/` — deliberately **outside** the git checkout — and
`normalise-dj-tags.py`, the one file both arms depend on, was **sha256-verified identical to the
committed blob** (`73149e79f905076c50906bf07c594731b29a69fbbc81b29fa19ecf073b79ad87`) before every
run. Same deviation and same handling as plans 03-01, 03-03, 03-04, 03-05 and 03-08.

## Verification that could not be satisfied as written

**`03-DECISION.md`'s `## D-13` section still contains the string `PENDING`, deliberately.** The
acceptance criterion says it should "no longer read `PENDING`". The one remaining occurrence is
`~~PENDING — filled by plan 03-09~~ →`, struck through and immediately followed by the verdict —
the same form plan 03-08 used for the TAGR-02 confirmation line, and the form the orchestrator's
standing instruction requires ("add DATED AMENDMENT sections that leave the original wording
visible"). Destroying the superseded wording would satisfy the grep and break the audit trail. Every
other `PENDING` in that section — all seven result cells — is replaced.

**`git diff` on `03-DECISION.md` removes 10 lines**, and every one is accounted for: 7 `PENDING`
result cells, the `PENDING — filled by plan 03-09` line (retained struck-through), and claim-audit
rows **3a** and **3b**, whose original wording is preserved **verbatim** inside their replacements
with the measured verdict appended. **Zero threshold, estimator or denominator lines were touched**,
and the D-13 prediction prose is asserted **byte-identical** to threshold commit
`137b6d9e92cb44d9c6a48b3963bb33fe0194622f` by diffing the section from `## D-13` to the table header.

**`tagger-class writers: 0` is silence, not a clean reading, for one tagger** — **DEF-03-01**, in the
open for the fifth time in this phase. `check-music-freeze.sh`'s `TAGGER_PATTERN` cannot match
`sabnzbd`, which runs beets live over the same `complete/nzb/dj-mixes` tree the WAV arms reflinked
from. The decisive attribution is the mount table, not the clock: **no container in this plan mounted
`/mnt/fast/appdata` or `/mnt/tank/downloads/complete` at any mode**, and the three source folders'
manifest is byte-identical before and after.

## Requirements

**TAGR-02 is deliberately NOT marked complete.** This plan settles D-13 — which tool performs
normalisation — and confirms A3. It does not establish that the surviving tagger can own the whole
tree, which is the requirement's actual claim and 03-11's job.

## Known Stubs

None introduced. Two states worth naming:

- **`scripts/normalise-dj-tags.py`'s WAV write path is broken** — 0 of 134, logged as **DEF-03-09**
  with the measured fix and its open question. Deliberately not fixed here: editing the tool
  mid-comparison would have made the WAV measurement unattributable, and the failure is loud (134
  `.failed` records, exit 1) rather than silent.
- **FLAC is unexercised on both arms.** Neither sample contains any; the estate's backlog holds 147
  FLAC files. Recorded in the capability matrix as `unexercised`, not as a pass — the same handling
  the WAV question forced.

Teardown debt for plan 03-11: `spike-03/normalised-metadata`, `spike-03/wav-raw`,
`spike-03/wav-mutagen` and `spike-03/wav-metadata` did not exist when 03-03 created the scratch
root; the WAV trees are 4.6 G apparent each (reflinked). `/mnt/fast/spike-03/out` is now **12 M** on
LXC 100's ext4 **root** — the 03-03 finding-4 constraint, watched not assumed: `/` unchanged at 35 G
free. The snapshot `tank/downloads@spike-03-t2-wav` was added on atlantis and must be destroyed with
`@spike-03-t0`.

## Threat Flags

No new security surface. Every disposition in the plan's register was exercised:

| Threat | Outcome |
|---|---|
| T-03-51 (tampering with the mutagen arm or the un-normalised arm) | Held — the `metadata` arm ran on its own reflinked tree; `find -newer` **0 lines** on `raw/` and `normalised/` and **empty** whole-subtree `.meta` and `.sha` manifest diffs on both, across both runs. Exactly **205** files changed and not one more. The five-file spot check was not used |
| T-03-52 (loss of `TKEY` / `EnergyLevel`) | Held and **measured**, not assumed — `TKEY` 40→40, `EnergyLevel` 20→20, `TBPM` 110→110, **0 value mismatches** against the untouched twin, on two instruments. A3 confirmed. All writes were on reflinked copies behind `tank/downloads@spike-03-t0` |
| T-03-53 (tampering with `/mnt/tank/media/Music`) | Held — **no path under `/mnt/tank/media` mounted in any container at any mode**; `check-music-freeze.sh` **exit 0**, `declared rw reaching Music: 0` |
| T-03-54 (a staged bake-off) | Held — the prediction is quoted verbatim from a commit that predates the run and asserted byte-identical to `137b6d9e…`; the stratum-scoped overturn on WAV is reported in the headline, in the verdict and in the decision record, and **argued down rather than suppressed** |
| T-03-55 (a source read presented as an observation) | Held — every capability-matrix cell is annotated `observed` or `source`, and both previously source-only claims are re-derived: the flag-`0` merge from `FIELDS_DROPPED`/`TKEY`/`EnergyLevel`, and the deferred `os.Exit(1)` from `metadata write album X -- /nope.mp3` returning **1** |
| T-03-56 (third-party container privilege) | Held — `--rm`, `--security-opt no-new-privileges:true`, **`--network none`**, no published port, no Traefik label, identical-path mounts confined to `spike-03`, **0** containers left behind |
| T-03-SC (package installs) | Held — **zero** installs. `metadata` ships inside the already-pulled `sentriz/wrtag:v0.34.0`; mutagen 1.48.1 is already in the LSIO beets image |

One threat-adjacent note that is not a flag: no credential was handled by this plan at all. No
Discogs or MusicBrainz request was issued — `--network none` on every `metadata` arm — so
DEF-03-04's `?token=` query-parameter sink was never in the path.

## Self-Check: PASSED

- `.planning/phases/03-tagger-spike/03-NORMALISER-BAKEOFF.md` — FOUND (contains `EnergyLevel`,
  `FIELDS_DROPPED`, `normalised-metadata`; 12 `## ` sections including all six the plan names)
- `.planning/phases/03-tagger-spike/03-DECISION.md` — FOUND (modified; 10 lines removed, all
  accounted for above; D-13 prediction prose byte-identical to `137b6d9e…`)
- `.planning/phases/03-tagger-spike/deferred-items.md` — FOUND (modified; DEF-03-09 and DEF-03-10)
- Commit `7c82cd0` (`feat(03-09)`) — FOUND
- Commit `46aac6e` (`docs(03-09)`) — FOUND
- Commit `d56d98b` (`docs(03-09)`) — FOUND
- `/mnt/fast/spike-03/out/spike03-after-metadata.ndjson.gz` — FOUND, 335 records, `.failed` 0 lines
- Committed `normalise-dj-tags.py` sha256 == the sha256 of the file both mutagen arms ran
  (`73149e79…`) — VERIFIED
