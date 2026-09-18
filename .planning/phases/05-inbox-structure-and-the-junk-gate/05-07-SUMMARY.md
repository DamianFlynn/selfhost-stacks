---
phase: 05-inbox-structure-and-the-junk-gate
plan: 07
subsystem: now-collection-split-applied
tags: [irreversible-renames, approval-gate, inode-preservation, zfs-diff-reconciliation, qual-01-before-state, D-05, D-06, D-07, D-08, D-09, D-26, D-27]
requires:
  - "05-01 — tank/downloads@pre-phase5, the ONLY undo for this plan; verified on atlantis before the first rename"
  - "05-04 — the junk sweep, which reduced the sidecar set to the 5 this plan routes"
  - "05-05 — now-tags.ndjson (4,746) and now-manifest.ndjson (4,770), the reconciliation inputs"
  - "05-06 — scripts/phase05-now-split.sh and the approved now-split-map.tsv (sha256 9ef5da2b…1fba9)"
provides:
  - "host:the Now! collection as 115 flat `Vol 001`…`Vol 115` folders holding 4,746 mp3 and 4 sidecars"
  - "host:/mnt/fast/safety/phase05/now-split-result.txt — the apply record"
  - "host:/mnt/fast/safety/music-pre-project/tags/phase05-now-before.ndjson.gz — the QUAL-01 before-state, 4,746 records"
  - "host:/mnt/fast/safety/phase05/now-split-inode-sample.tsv — the 31-file (devid,inode) sample, before-side"
  - ".planning/…/artifacts/05-07-* — the approval record, the apply output, and three driven verification harnesses"
affects: [05-08, 05-09, 05-10, 05-11, 06, 07]
tech-stack:
  added: []
  patterns:
    - "bind an operator's yes to a CONTENT HASH, re-check it immediately before acting, and record both readings"
    - "reconcile a destructive batch against `zfs diff` and require the affected set to match the authorising file EXACTLY — an off-map path is a failure, not a footnote"
    - "assert the (devid, inode) PAIR across a rename, never the inode alone, on an estate with a known inode collision"
    - "compute the post-move identity from the RESULTING TREE and join by basename, because every path the map named has changed"
    - "state the zero-tag-field count beside a 'nothing was lost' verdict, so the verdict cannot be vacuous"
key-files:
  created:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-approval-record.md
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-split-result.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-postmove-verification.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-postmove-verify.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-zfs-reconciliation.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-zfs-reconcile.py
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-inode-sample.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-capture-verification.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-capture-verify.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-07-capture-run.log
  modified: []
key-decisions:
  - "The operator's approval was bound to the map's sha256 and that hash was re-read from disk immediately before the first rename AND again after the last one — unchanged both times, so the tool provably acted on, and did not mutate, the approved content"
  - "The renamed set was reconciled against the approved map through `zfs diff` rather than through the tool's own counters, because a tool reporting on itself cannot detect a path it affected but never recorded"
  - "The 11 duplicate-bitstream groups were named rather than counted; 9 of them sit INSIDE `Vol 004`, which converts the '+13 is a merge artefact' claim from an argument into a measurement"
requirements-completed: []
duration: ~30 min
completed: 2026-09-18
---

# Phase 5 Plan 07: The 45 GB Monolith Is 115 Abortable Volumes Summary

**4,750 irreversible renames executed against a hash-bound approval, and every single affected path
on disk reconciled back to that approval by `zfs diff` — 4,750 `R` lines, zero off-map, zero
unrenamed, zero deletions attributable to this plan. The per-volume identity computed from the
resulting tree landed on the pre-declared exception set exactly, eleven rows, not one surprise; and
the duplicate-bitstream scan turned up the finding that settles `Vol 004` for good — nine of its
thirteen surplus files are byte-identical audio already in the folder, which is what a three-edition
merge looks like from underneath.**

## Performance

- **Duration:** ~30 min (first probe 2026-09-18T20:52Z; QUAL-01 capture complete 21:15:41Z)
- **Completed:** 2026-09-18
- **Tasks:** 3 (one decision gate, two auto)
- **Commits:** 3 (plus this one)
- **Apply wall clock:** the result file landed 20:58:44Z; 4,751 rows re-validated then 4,750 renamed
- **QUAL-01 capture:** 723 s, 48,030,482,391 bytes, 0.152 s/file, 63.35 MB/s

## Task 1 — the gate, and what the yes was bound to

The operator selected **`approve-as-is`, no amendments**. Before the first rename the map on disk
hashed to `9ef5da2b9ed8947529689a107c2bf0d20becbe4a6ec3274878179a4eb181fba9` and carried **4,751
rows** — the value recorded at approval. **Match**, so the approval covers what was acted on.

Re-read **after** the last rename: **still `9ef5da2b…`**. That second reading is not ceremony. It is
the evidence that the tool acted *from* the approved artifact rather than rewriting it, which a
before-only check cannot distinguish.

The fence was verified independently on atlantis rather than inherited from the proof file:
`tank/downloads@pre-phase5` exists, created `Fri Sep 18 15:42 2026`, epoch **1789742526** — identical
to 05-01's record. Its two siblings `@pre-project` and `@pre-chown` are a month stale and are
correctly not what the proof names. **This snapshot is the only undo for this plan.**

Full record, including the hazard that auto-mode would auto-select the option that performs the
renames: `artifacts/05-07-approval-record.md`.

## The map re-verified against live disk before acting — reproduced, not inherited

The tree is written at ~1 music job per 72 s, so the figures the approval was given against had to be
re-measured. Every one reproduced:

| Measure | Reading |
|---|---:|
| map rows / rows not carrying 5 fields | **4,751** / **0** |
| map mp3 rows / mp3 on disk | **4,746** / **4,746** |
| in the map but NOT on disk / on disk but NOT in the map | **0** / **0** |
| `AGREE` / `TIEBREAK-ALBUMTAG` / `SIDECAR` / `SIDECAR-IN-PLACE` | 4,742 / 4 / 4 / 1 |
| distinct destination directories | **115** |
| destinations outside the fence / containing a `CD1`/`CD2` component | **0** / **0** |
| volume coverage | exactly **1..115**, **0** gaps |

## Task 2 — the split, and the shape that resulted

`apply` satisfied both refusals, re-validated all 4,751 rows against live state, then acted:
**4,750 moved, 1 no-op, 0 errors.**

| Assertion | Required | Measured |
|---|---|---:|
| directories at depth 1 | 115, named `Vol 001`…`Vol 115` | **115**, 0 not matching, 0 absent, 0 unexpected |
| directories at depth 2 | 0 — the split is FLAT (D-05) | **0** |
| mp3 still at the collection root | 0 | **0** |
| mp3 inside volume folders | 4,746 | **4,746** |
| files anywhere below depth 2 | 0 | **0** |
| sum of per-volume mp3 counts | 4,746 (05-05's fresh total) | **4,746** |

**Both assertions were run, and the reason is the point.** The headline total would balance even if
every file landed in the wrong folder — which is exactly why D-08 calls the per-volume identity the
real instrument and the total merely the headline.

### The per-volume identity, computed from the tree

Not from the map. Joined by **basename**, because every path the map named has changed — 4,746 tree
rows, 4,746 distinct basenames, **0 unjoined**. 104 volumes balance; 11 are exceptions:

```
EXC  Vol 003 |  26 |  28 | -2      EXC  Vol 039 |  40 |  41 | -1
EXC  Vol 004 |  45 |  32 | +13     EXC  Vol 052 |  41 |  42 | -1
EXC  Vol 008 |  42 |  33 |  +9     EXC  Vol 070 |  42 |  43 | -1
EXC  Vol 009 |  44 |  31 | +13     EXC  Vol 083 |  42 |  43 | -1
EXC  Vol 015 |  31 |  32 | -1      EXC  Vol 098 |  45 |  46 | -1
EXC  Vol 018 |  31 |  32 | -1
```

**Diffed row by row against the pre-declared list in 05-NOW-INVENTORY.md § AMENDMENT: an exact
match, all eleven rows.** A verifier meets a known list, not a discrepancy — Phase 4's D-31 pattern.

The +13 / +9 / +13 rows are D-04's surplus reappearing as the **known grouping artefact**: a merged
folder holds the union of several editions while the modal `tracktotal` can carry only one edition's
value. They mean *"merged folder, expectation not meaningful"*. They must never be read as *"extra
files appeared"* — and this plan now has direct evidence for that reading (below).

### The 13 missing tracks, and what they are

Unchanged and pre-existing: **5 are genuinely absent from the source rip** (volumes 18, 52, 70, 83,
98), **4 are the album-tag tie-breaks** placing one physical file once rather than twice (volumes 3
×2, 15, 39), and **4 are volume 8's disc-2 imbalance**. None was caused here. All 115 volumes were
split including the 13 incomplete ones; **none went to `04-hold`** (D-09) — an incomplete `Now!`
volume is a compilation, not a broken album.

### The manifest-only entries, on their own line, folded into no total

**0.** Reported separately and never added to anything; reconciling against the manifest's 4,770
was rejected in D-08 precisely because it would fail by 24 on every run and train everyone to ignore
it.

**Stated honestly, because my own instrument disagreed first:** my post-move harness joins manifest
leaves to disk basenames by **exact match** and reported **2** manifest-only entries. Both are
05-05 § 6's known mojibake pair — `01. Psy - Gangnam Style (강남스타일).mp3` and
`10. Axwell Λ Ingrosso - More Than You Know.mp3`, whose Hangul and Greek capital lambda the CP1252
ripper wrote into the m3u as literal `?`. Re-run under the alphanumerics-only key the tool itself
uses, **manifest-only is 0**, and both files are present on disk (`Vol 083` and `Vol 098`). **The 2
was my simpler join's artefact, not a finding** — recorded rather than quietly replaced with the
number I wanted.

### Inode preservation, asserted on the PAIR

31 named files — one from every fifth volume, plus all 4 tie-broken files and all 4 moved sidecars —
had `stat -c '%d %i'` read before the run and again at their new paths. **31 identical, 0 changed,
0 missing.** The tool independently asserts the same property per row, and its 0 errors covers all
4,750.

**The pair, never the inode alone.** This estate has a known inode collision — `/mnt/tank/downloads`
and `/mnt/tank/media/Music` both report inode 34 — so an inode-only assertion can agree by accident.
Driven negative control, proving the instrument can distinguish: the collection root reports devid
**68**, the library root reports devid **76**.

That D-07's claim holds is what makes this plan's cost model true: these were `rename(2)` calls
inside one dataset — instant, free, no copy, no transient double space.

### The reconciliation that actually proves it: `zfs diff`

The tool's own counters cannot detect a path it affected but never recorded, so the affected set was
taken from ZFS and matched against the authorising file:

| `zfs diff tank/downloads@pre-phase5` → live, scoped to the collection | Count |
|---|---:|
| `R` renames | **4,750** |
| `+` created, all directories | **115** |
| `+` created, non-directory | **0** |
| `-` deleted | **9** |
| `M` modified | **1** (the collection parent) |

| Against the approved map | Count |
|---|---:|
| approved moves (`src != dst`) | 4,750 |
| **renamed but NOT on the map** | **0** |
| **on the map but NOT renamed** | **0** |
| created dirs not expected / expected dirs not created | **0** / **0** |
| **unattributed changes under the collection** | **0** |

The **9 deletions are all pre-existing** — captured in a baseline `zfs diff` taken *before* apply ran
and attributable to plan 05-04's junk sweep (7 EAC `.log`, `play.m3u`, `00. play.m3u`). The two decoy
directories that complete 05-06's count of 12 sit under `dj-mixes/`, outside this scope. **This plan
deleted nothing.** The m3u map was confirmed absent from the rename set and is still at the root.

**The assertion was driven to failure rather than merely observed passing.** Re-run against a map
with `Vol 042`'s 40 rows deleted, it reported 40 off-map renames plus 1 uncreated directory,
41 unattributed, verdict **FAIL**, exit 1.

### The four value-bearing sidecars (D-06)

`back.bmp`, `cd1.bmp`, `cd2.bmp` → **inside `Vol 077`**, following plan 05-03's confirmation that
`cd2.bmp` really is NOW 77 disc 2. `NOW That's What I Call Music! 115.cue` → **inside `Vol 115`**.
The 9,541-line m3u map → **still directly at the collection root**, beside the collection it maps.
4 non-mp3 inside volume folders, 1 non-mp3 at the root. Exactly D-06's by-value triage, which was
reached by opening the files rather than by extension.

## Task 3 — the QUAL-01 before-state

`phase05-now-before.ndjson.gz`, **4,746 records, 0 failed, 0 skipped**, captured with `--roots`
scoped to the collection — **1 scan root, 0 source paths outside it, 0 outside a `Vol NNN` folder,
115 volume folders represented**. It did not re-read 140 GB.

| Gate property | Required | Measured |
|---|---|---:|
| record count == mp3 in the 115 folders | equal, asserted | **4,746 == 4,746** |
| records with a missing or empty `audio_md5` | 0 — a record without one cannot join | **0** |
| **records with ZERO tag fields** | expected 0 | **0** (min 15, mean 20.7, max 30) |
| `album` / `disc` / `track` present | all | 4,746 / 4,746 / 4,746 |
| failed ledger | empty | **0 lines** |

**A short capture is a capture failure, not a small collection**, and the zero-tag-field count is
stated beside its expected value for the reason `diff-music-tags.sh` builds it in: without it, a
later "no fields dropped" verdict cannot be distinguished from "there was nothing there to drop".

### The property that makes D-10's tag write affordable, driven rather than asserted

The key is the **encoded audio bitstream**, not the container and not the path. Re-hashed one file
two ways:

```
recorded audio_md5:   cc97fb70afb6d06f81f64406a0ec7118
re-hashed audio only: cc97fb70afb6d06f81f64406a0ec7118   <- reproduces
whole-file md5:       b9421e949d79d377129a6170cf1da26c   <- DIFFERENT
```

The key reproduces from the audio stream alone and is **not** the whole-file hash, so writing a tag
cannot move it. That is the whole reason Phase 5 is allowed to write `album` at all — a path-keyed or
file-keyed snapshot would have zero matching rows by the time 05-09 and Phase 7 run.

## The finding worth carrying forward: `Vol 004`'s surplus, measured from underneath

4,746 records carry **4,735 distinct bitstreams** — 11 groups share one. This is a DUPE-01
observation, which `diff-music-tags.sh` reports informationally and never counts against its exit
code. Named rather than counted, because the distribution is the finding:

**9 of the 11 pairs are entirely INSIDE `Vol 004`** — Ghostbusters, Status Quo, Bronski Beat,
Culture Club, John Waite, UB40, Style Council, Julian Lennon, Thompson Twins, each appearing twice in
one folder under two different track numbers. The other two cross into `Vol 004` from `Vol 002`
(Queen) and `Vol 003` (O.M.D.).

`Vol 004` reads **+13** against its modal `tracktotal`. **Nine of those thirteen surplus files are
byte-identical audio already in the folder** — which is precisely what a folder holding the union of
three 1984 editions looks like from underneath. 05-05 § 4 argued the surplus was a grouping artefact
and not intruders from another volume; this is the same conclusion reached independently, from the
encoded bitstream rather than from tags or manifest lines. Both instruments now agree, and they share
no input.

## Deviations from Plan

The shipped tool needed no repair — `phase05-now-split.sh` ran as written, first time, with zero
errors. Both defects below were in **my own verification harness**, and both are recorded because
each is a repeat of a trap this estate has already paid for.

### Auto-fixed issues

**1. [Rule 1 — Bug] `| head -1` under `set -o pipefail` killed a verification run with 141**
- **Found during:** Task 3, the first run of the capture verification
- **Issue:** section 6 ended `zcat … | jq … | head -1`. `head` exits after one line and SIGPIPEs its
  writer, so ssh returned **141 after every assertion had already printed a correct result**. It is
  the same family as the `timeout N cmd | wc -l` trap the house rules name, and 05-06 recorded the
  identical failure one plan ago. Sections 1–5 had all passed; the exit code was mine, not the
  estate's.
- **Fix:** `sed -n '1p'`, which consumes its whole input and cannot SIGPIPE the writer. The reason is
  written in band in the committed script so nobody "simplifies" it back.
- **Files modified:** `artifacts/05-07-capture-verify.sh`
- **Commit:** `c3184a6`

**2. [Rule 1 — Bug] An edit broke the reconciliation script's docstring, and the pipeline hid it**
- **Found during:** Task 2, parameterising `05-07-zfs-reconcile.py` for commit
- **Issue:** adding usage prose after the closing `"""` produced a `SyntaxError`. It was nearly
  missed because the check was `python3 … | tail -6`, which reported **RC=0** — the pipeline's status
  is not the status of the thing you care about. The same trap, twice in one plan, in two languages.
- **Fix:** prose moved inside the docstring; the script re-driven with the status read with nothing
  downstream of it, and given a negative control — with no inputs staged it exits **1**, it does not
  silently pass.
- **Files modified:** `artifacts/05-07-zfs-reconcile.py`
- **Commit:** `4d21985`

### Recorded, not deviations

- **The new volume directories are `root:root`, not `568:568`.** This is D-26 working as designed:
  a rename preserves ownership, so the **4,750 moved files are all `apps:apps`**, while the 115
  directories were created by the tool running as root. D-27 puts the tree-wide `568:568` sweep
  **last**, in plan 05-10, precisely so it normalises these directories. **No `chown` and no `chmod`
  was attempted here** — `chown` cannot run from LXC 100 at all (sparse idmap) and `chmod` fails
  `EPERM` on `tank` even as real root. Directory modes are `0777`, inherited.
- **My harness's 2 "manifest-only" entries.** Detailed above. The tool's own alnum-key join says 0,
  both files are on disk, and the discrepancy is my simpler instrument's, not the estate's.

### Deliberately not fixed

- **`scripts/quick-health-check.sh` still exits 1**, for the pre-existing, unrelated
  `interpolated-host-path inventory MOVED: expected=12, found=13` red that plan 05-02 logged in
  `deferred-items.md`. Confirmed still the *only* failing assertion, unchanged in shape. Not
  attributable to this plan and not touched — bumping the constant is the move this estate has
  repeatedly recorded as the defect rather than the fix.
- **The 13 missing tracks and the merged-volume `tracktotal` disagreement.** Named, pre-declared,
  out of scope; repair is Phase 6's.
- **The 11 duplicate bitstreams.** A DUPE-01 finding, surfaced and named. DUPE-01/DUPE-02 still need
  a roadmap decision before Phase 7.

---

**Total deviations:** 2 auto-fixed, both bugs, both in the verification harness rather than in the
shipped tool. **Impact:** neither reached the estate. Both were caught because the assertions were
driven and their exit statuses read with nothing downstream — and both are the same lesson the
previous plan wrote down, which is the honest reading of it.

## Evidence

| Check | Result |
|---|---|
| map sha256 before the first rename / after the last | **9ef5da2b… / 9ef5da2b…** |
| snapshot `tank/downloads@pre-phase5` on atlantis | present, epoch **1789742526** |
| `apply` exit code | **0** |
| moved / no-op / errors | **4,750 / 1 / 0** |
| plan's Task 2 verify: depth-1 dirs, depth-2 dirs | **115 / 0** |
| plan's Task 3 verify: capture record count | **4,746** |
| depth-1 names not matching `Vol NNN` | **0** |
| volume folders absent / unexpected vs `Vol 001`…`Vol 115` | **0 / 0** |
| mp3 at the collection root | **0** |
| sum of per-volume mp3 counts | **4,746** |
| per-volume identity: balanced / exceptions | **104 / 11** |
| exception set vs the pre-declared list | **exact match, 11 rows** |
| manifest-only (alnum key, as the tool joins) | **0** |
| inode sample: identical / changed / missing | **31 / 0 / 0** |
| devid negative control (downloads vs library) | **68 vs 76** — the instrument can distinguish |
| `zfs diff` renames / off-map / unrenamed | **4,750 / 0 / 0** |
| `zfs diff` `+` dirs / `+` non-dirs / unattributed | **115 / 0 / 0** |
| deletions attributable to this plan | **0** (9 pre-existing, from 05-04) |
| reconciliation driven to FAIL on a mutated map | **exit 1, 41 unattributed** |
| capture: records / failed / zero-`audio_md5` / zero-tag-field | **4,746 / 0 / 0 / 0** |
| `audio_md5` reproduces from the audio stream / equals the whole-file hash | **yes / no** |
| criterion 4: `_`-prefixed dirs under `/mnt/tank/media/Music` | **0** (asserted after the moves, D-22) |
| `Vol *` leaked into `/mnt/tank/media/Music` | **0** |
| `chown` / `chmod` attempted | **none** |
| credential screen over the 10 committed artifacts | **0 matches** |

## Known Stubs

None. Every deliverable is a completed operation against real state, with each assertion computed
from the resulting tree rather than from the plan that predicted it, and the two strongest assertions
— the `zfs diff` reconciliation and the capture-completeness gate — each driven to failure at least
once.

## Still open, deliberately

- **INBX-03 stays UNTICKED.** All requirement ticks belong to plan 05-11.
- **The 115 volume directories are `root:root`.** By design (D-26). Plan **05-10** normalises the
  whole of `tank/downloads` to `568:568` in one verified sweep and picks these up; do not chown them
  piecemeal in the meantime.
- **Nothing has been staged into `_inbox` yet.** D-07 is explicit that whole volumes are pulled into
  `_inbox/` in batches **later**, not in this phase; `unsorted/` stays the immutable source
  ARCHITECTURE Pattern 5 describes.
- **The `album` tag is still wrong on volume 36 and inconsistent across the collection.** D-10's
  repair is plan **05-09**, which runs after this by D-27 because the split produces the grouping the
  repair applies to. Its before-side join is the capture this plan just took.
- **`tank/downloads@pre-phase5` remains the only undo for these 4,750 renames**, and rolling it back
  would also discard everything downloaded since 2026-09-18T15:42. Do not take that lightly and do
  not delete the snapshot before Phase 6 signs off.
- **DUPE-01 / DUPE-02** still need a roadmap decision before Phase 7. This plan added 11 named
  duplicate-bitstream groups to the evidence.

## Threat Flags

None. This plan added no network endpoint, no auth path and no schema change. Every write landed
under `tank/downloads`; Phase 1's D-20 bar on `/mnt/tank/media/Music` was asserted intact after the
moves. It installed no package from any package manager and holds no credential.

## Self-Check: PASSED

All 10 created files exist on disk under
`.planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/`. All three commits — `f78a1a1`,
`4d21985`, `c3184a6` — are present in `git log`. The off-repo deliverables on LXC 100 exist with the
stated counts: `now-split-result.txt` (apply exit 0, 4,750/1/0), `phase05-now-before.ndjson.gz`
(4,746 records, 6.7 MB), `phase05-now-before.done` (4,746 lines), `phase05-now-before.failed`
(0 lines), `now-split-inode-sample.tsv` (31 rows), and the 115 `Vol NNN` directories holding 4,746
mp3 and 4 sidecars.

---
*Phase: 05-inbox-structure-and-the-junk-gate*
*Completed: 2026-09-18*
