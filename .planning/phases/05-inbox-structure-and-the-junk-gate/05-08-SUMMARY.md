---
phase: 05-inbox-structure-and-the-junk-gate
plan: 08
subsystem: now-collection-album-rule
tags: [tag-normalisation, collection-fence, rule-4, dry-run, id3v1-preservation, negative-control, D-03, D-10]
requires:
  - "05-01 — tank/downloads@pre-phase5, the snapshot --apply will refuse to run without at 05-09"
  - "05-05 — 05-NOW-INVENTORY.md § 2, D-03's three album-string traps, measured"
  - "05-07 — the 115 flat `Vol 001`…`Vol 115` folders rule 4 derives from"
  - "04-23 — normalise-dj-tags.py's WAV repair and preserve_id3v1_trailer(), the tool being extended"
provides:
  - "scripts/normalise-dj-tags.py — a `now` collection mode (second NARROWER fence) and rule 4"
  - "host:/mnt/fast/safety/phase05/now-album-dryrun.ndjson — 4,746 per-file proposals, 1.70 MB"
  - "host:/mnt/fast/safety/phase05/now-album-dryrun.ndjson.summary.json — the counts, reconciled"
  - "host:/mnt/fast/safety/phase05/05-08-tree-before.tsv / -after.tsv — the nothing-was-written proof"
  - ".planning/…/artifacts/05-08-dryrun-verification.txt — every refusal and control, driven"
affects: [05-09, 05-10, 05-11, 06, 07]
tech-stack:
  added: []
  patterns:
    - "when a tool's fence is too narrow for a new target, add a SECOND NARROWER named pair — never widen the first"
    - "make competing rules mutually exclusive by a MODE GATE, then assert after the run that the gate held"
    - "propose on every file and mark the already-correct ones `noop`, so the review artefact shows coverage while the write stays minimal"
    - "prove a new self-test case can FAIL, from a mutated COPY kept outside the git checkout and deleted afterwards"
    - "take a path/mtime/size fingerprint before and after a read-only pass; a matching sha256 is a cheaper 'nothing moved' than any log"
key-files:
  created:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-08-dryrun-verification.txt
  modified:
    - scripts/normalise-dj-tags.py
key-decisions:
  - "The Phase 5 fence is a SECOND named (root, snapshot) pair scoped to the one collection folder; SCRATCH_ROOT is byte-identical and no constant in the file equals /mnt/tank/downloads, so SABnzbd's live working tree never enters a tag writer's reach"
  - "Rule 4 proposes on EVERY file in a volume folder, including the 3,995 already carrying the canonical value; those records are marked `noop` and are never written, so the dry run shows total coverage while a second --apply still writes nothing"
  - "Rule 3 is disabled under --collection now by coercing --artist-policy to `keep`, announced on stderr — D-10 is one field, and the coercion is the mechanism rather than a second condition at the rule site"
requirements-completed: []
duration: ~25 min
completed: 2026-09-18
---

# Phase 5 Plan 08: The One Wrong Field, Proposed 4,746 Times and Written Zero Summary

**Rule 4 reads the folder, never the tag — and the dry run shows why that was not pedantry:
volume 36's three album spellings, including the one with a double space that a trailing-number
regex reads as "volume 2", collapse to a single `Now That's What I Call Music! 36` across all 40
files. 4,746 proposals, 115 folders, one value per folder, 115 distinct values forming exactly
1 through 115, `album` the only field touched and rule 4 the only rule that fired. 751 files are
actually wrong; the other 3,995 are already right and are recorded as no-ops rather than rewritten.
Nothing moved: the same 4,751-file fingerprint hashes identically either side, and `zfs diff` shows
zero modified mp3.**

## Performance

- **Duration:** ~25 min (first fence drive 21:30Z; zfs diff complete 21:50Z)
- **Completed:** 2026-09-18
- **Tasks:** 3 (all auto)
- **Commits:** 2 (plus this one)
- **Dry-run wall clock:** 134.39 s for 4,746 files, exit 0

## Tasks 1 and 2 — the fence, and the rule

### The riskiest line-change in the phase was not made

`SCRATCH_ROOT = "/mnt/tank/downloads/spike-03"` fenced this tool to the Phase 3 spike, and the
Phase 5 target is not under it. The one-line fix that suggests itself — relax the constant to
`/mnt/tank/downloads` — would have put SABnzbd's live `incomplete/` working set and the whole
completed tree inside a tag writer's reach. Instead there is a **second named pair**:

| collection | fence root | rollback snapshot |
|---|---|---|
| `djmixes` (default) | `/mnt/tank/downloads/spike-03` | `tank/downloads@spike-03-t0` |
| `now` | `…/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023` | `tank/downloads@pre-phase5` |

Both halves move together, because a run fenced to one collection with another's snapshot as its
rollback has no rollback at all — and that is now a driven refusal, not a comment.

Asserted rather than described: `SCRATCH_ROOT` and `WRITABLE_FIELDS` are byte-identical
(`grep -c` returns 1 for each), and `grep -cE '^[A-Z_]+ *= *"/mnt/tank/downloads"'` returns **0**.
The per-file CR-04 re-assertion (resolved path, symlink refused, non-regular refused, `st_nlink > 1`
refused, run both in the loop and as the first statement of `write_tags`) was threaded to the
selected root and **not relaxed in any way**.

**The refusal that matters most is the one that still fires:** the DEFAULT collection, given the
Now! tree, exits 2 with `required: /mnt/tank/downloads/spike-03`. The fence did not widen; a second
one was added beside it.

### Rule 4 derives from the folder, and the docstring says why in D-03's own words

The input is the folder name — the anchored literal `Vol ` plus exactly three digits, converted to
an integer, required to be 1–115, then put through `sanitise_derived()` exactly as rule 1's output
is. D-03's trap paragraph is in the docstring **verbatim, double space intact**, because the wrong
implementation is the obvious one and exits 0 while looking right.

Five refusals, five different names, so the `.failed` ledger can say which shape was refused:
`volume_number_underpadded` (`Vol 36`), `volume_number_overpadded` (`Vol 0001`),
`bare_number_no_vol_prefix` (`36`), `not_a_volume_folder` (`Disc 1`), `volume_out_of_range`
(`Vol 116`, `Vol 000`).

The canonical form is `Now That's What I Call Music! ` + the unpadded number. Two properties, both
load-bearing and both stated in the docstring: it carries a digit on **every** volume, so
`sanitise_derived`'s no-digit guard accepts all 115 — a bare `Now That's What I Call Music!` for
volume 1 would have been refused outright — and it uses the majority punctuation (`Music!`, 96 of
117 measured values), which keeps the string a usable Discogs query for Phase 6.

### Mutual exclusion is a gate, and the gate is checked afterwards

A proposal is a tuple keyed by **field**, so two rules proposing `album` for one file would collide
on the dict key and let the last writer win silently, with the `rule` number naming the loser. Under
`--collection now` rule 4 owns `album` outright and rules 1 and 2 do not execute; rule 3 is disabled
by coercing `--artist-policy` to `keep`, announced on stderr. After the run, a hit on any rule
outside the collection's allowed set is a **hard exit 1**, not a footnote — the dry run reports
`rules_exclusive: true` beside `rule_hits: {"4": 4746}`.

### The self-test: 5 cases, 0 failed, and both new ones proven able to fail

Run inside `lscr.io/linuxserver/beets:2.13.1-ls349` (asserted resident first, because `--pull never`
turns an absent image into a failure that reads like a different one), `--network none`, scripts
mounted read-only. The two new cases:

- **`rule4-derivation`** — all 115 volumes yield 115 distinct sanitiser-safe values; the five
  refusals are five distinct names; `Vol 001` survives the no-digit guard; the function is
  deterministic and `effective_changes()` on an already-canonical file returns `{}`; and rule 1,
  given `Vol 036`, refuses with `no_label_token` — so even if the gate failed, it could not propose
  a competing album.
- **`rule4-mp3-id3v1-preserved`** — after a rule-4 album write on a synthetic MP3 the ID3v2 frame-ID
  multiset is unchanged, the trailing ID3v1 block is **byte-identical**, and the audio body between
  the two is byte-identical. The case title names the dependency rather than restating the claim:
  D-10's "this write is compatible with Phase 7's diff" is true **only because
  `preserve_id3v1_trailer()` exists**.

**Both were proven discriminating.** From mutated copies kept outside the git checkout (so no
untracked file could block a later `git pull --ff-only`) and deleted afterwards:

| control | mutation | result |
|---|---|---|
| A | `preserve_id3v1_trailer()` neutered | `bad rule4-mp3-id3v1-preserved` — ID3v1 album `'Old Album'` → `"Now That's What I Call Music! "`, exit 1 |
| B | `NOW_ALBUM_PREFIX` moved | `bad rule4-derivation`, three reasons naming Vol 036/001/115, exit 1 |

Control A is the interesting one: it caught `save(v1=UPDATE)` regenerating all 128 bytes **in the
act**. That is the mechanism that moves `audio_md5`, the key QUAL-01's before/after diff joins on.
In each control the other four cases stayed green, so the failure is attributable.

## Task 3 — 4,746 proposals, read rather than summarised

| Measure | Reading |
|---|---:|
| folders seen | 115 |
| files seen | 4,746 |
| NDJSON records | 4,746 (1,700,509 B) |
| fields proposed | `album` only |
| rules fired | rule 4 only — 1, 2, 3 all zero |
| distinct proposed values | **115** |
| values matching `Now That's What I Call Music! [1-9][0-9]{0,2}` | all |
| the number set | exactly 1…115 |
| folders proposing more than one value | **0** |
| files where the proposal equals the current value (no-ops) | 3,995 |
| files that would actually change | **751** |
| refusals | **0** (stated although zero) |
| failures / `.failed` ledger | 0 / 0 bytes |
| `counts_reconciled` / `rules_exclusive` | true / true |

**The case that motivates the whole rule.** `Vol 036` holds 40 files carrying three different album
strings — `…! Vol.36  CD2` ×20 (double space), `…! Vol.36 CD1` ×16, `…! 36` ×4 — reproducing
`05-NOW-INVENTORY.md` § 2's measured 20 / 16 / 4 exactly. All 40 are proposed the single value
`Now That's What I Call Music! 36`. A trailing-number parse of those strings would have filed 20
tracks into volume 2 and 16 into volume 1, exited 0, and looked right.

`Vol 001`'s 30 files carry `Now That's What I Call Music` with no number and are proposed `…! 1`;
`Vol 002`'s 30 carry `Now, That's What I Call Music II` and are proposed `…! 2`.

**Only 22 of the 115 volumes are wrong, and 21 of them are wrong the same way.** The full table is in
`artifacts/05-08-dryrun-verification.txt` § 4. Volumes 1–13, 15–17, 21, 23, 24, 27 and 29 all spell
it `Music` with no exclamation mark; volume 36 is the three-spelling case. The inventory measured
"96 values spell it `Music!` and 21 spell it `Music`" — these are those 21, which is the inventory
and the dry run agreeing from two different directions. Volumes 4, 8 and 9 show 45 / 42 / 44 files,
reproducing § 4's album-tag family counts under the variant-edition merge.

**Nothing was written, by two instruments.** The collection was bind-mounted `:ro` in the container,
so a write was mechanically impossible rather than merely unrequested. A path/mtime/size fingerprint
of all 4,751 files hashes to `1b8b90c2e480…` **before and after**, `cmp` identical, and 0 files carry
an mtime later than the run's start. From atlantis, `zfs diff tank/downloads@pre-phase5
tank/downloads` shows 4,876 lines inside the collection — 4,750 `R` (05-07's renames), 115 `+` (the
volume directories), 10 `-` (the sidecars 05-04 and the split removed) and **1 `M`, the collection
directory itself**, whose child set changed when those directories were created. **Zero `M` lines on
any mp3.**

## Deviations from Plan

### Auto-fixed and structural decisions

**1. [Rule 3 - Blocking] Tasks 1 and 2 landed in ONE commit**
- **Found during:** Task 2
- **Issue:** Both tasks are interleaved edits to a single Python file. Staging only task 1's hunks
  would have committed a dispatch site that references `derive_now_album_from_folder` and
  `effective_changes()` before either exists — a tree that does not parse.
- **Fix:** One commit naming both tasks and what each contributed. Per-task traceability is kept in
  the commit body rather than in two commits, one of which would have been broken.
- **Commit:** `d116447`

**2. [Rule 2 - Missing critical behaviour] A proposal equal to the current value is recorded, not written**
- **Found during:** Task 3 design
- **Issue:** The plan asks for "exactly one album change per file with exactly 115 distinct
  canonical values" *and* for "the count of files where the proposed value EQUALS the current
  value". Emitting a proposal for every file satisfies both — but writing all of them at 05-09 would
  re-serialise the ID3 tag of 3,995 files that are already correct, moving 3,995 mtimes for nothing
  and contradicting the tool's own idempotence contract.
- **Fix:** Rule 4 proposes on every file; `effective_changes()` filters the write to the 751 that
  differ; the rest are recorded with `"noop": true` and counted inside `files_unchanged` (the WR-06
  four-bucket reconciliation stays disjoint) with `files_noop_proposal` reported beside it. Rules 1,
  2 and 3 only ever propose a different value, so the default collection's behaviour is unchanged.
- **Consequence for 05-09:** its apply writes **751 files, not 4,746**, and the dry run still shows
  all 4,746 were covered.
- **Commit:** `d116447`

**3. [Rule 2 - Blast radius] Rule 3 is disabled under `--collection now`**
- **Issue:** D-10 is one field. Rule 3 writes `artist`, and nothing in the plan gated it off.
- **Fix:** `--artist-policy` is coerced to `keep` under `now`, announced on stderr. The coercion is
  the mechanism (the rule already gates on `keep`) and the post-run exclusivity assertion is the
  check that it held. The dry run confirms rule 3 fired 0 times.
- **Commit:** `d116447`

### Two defects in the plan's own text, left failing rather than edited around

**(i) Task 3's `<automated>` verify is non-discriminating.** Run verbatim it returns **0**, and
exits **0**:

```
jq -r '.changes.album.new // empty' now-album-dryrun.ndjson | sort -u | wc -l   ->  0
```

The NDJSON has no `changes` object; `build_record()` has always written a flat
`(field, rule, old, new)` record and the self-test grades that same shape, so `jq` emits nothing and
`wc -l` prints 0 whatever the file contains — including an empty one. **The artefact was not
reshaped to satisfy the assertion.** The same assertion against the real shape returns **115**:

```
jq -r 'select(.field=="album") | .new' now-album-dryrun.ndjson | sort -u | wc -l  ->  115
```

**(ii) There is no spike-03 tree left to prove "behaves exactly as before" against.** Phase 4 retired
it: `/mnt/tank/downloads/spike-03` does not exist on the estate. The default collection's behaviour
is therefore discharged **at the fence and at the constant** — `SCRATCH_ROOT` byte-identical, the
Now! tree still refused under `--collection djmixes`, `/mnt/tank/media/Music` still refused under
both — and **not** by an end-to-end spike run. For the same reason the symmetric snapshot refusal
(`--collection djmixes --apply` with a `pre-phase5` proof) cannot be reached: the target fence
refuses first. Creating a directory under `tank/downloads` to force it would be an estate change
this plan is not entitled to make, and would have appeared in the `zfs diff` above. The direction
that matters — a `now` apply refusing a `djmixes` proof — **is** driven.

## Authentication Gates

None.

## Estate state

- **Nothing on the estate changed.** No tag was written, no file moved, no ownership or mode
  touched. The repo on LXC 100 was fast-forwarded `552cfc0` → `d116447`; the host-side copy of
  `normalise-dj-tags.py` hashes identically to the workstation's
  (`70406a1050…`), asserted rather than assumed (D-26).
- `scripts/quick-health-check.sh` exits **1**, unchanged, for the pre-existing unrelated reason in
  `deferred-items.md` (`interpolated-host-path inventory MOVED: expected=12, found=13`). The blocks
  this phase cares about are green: the `audio.bash` guard block `FAILURES total: 0`, the Jellyfin
  transcode block `FAILURES total: 0`.
- `INBX-01/02/03` remain **unticked**; all ticks belong to 05-11.

## What 05-09 inherits

- `now-album-dryrun.ndjson` is the artefact the operator approves: one record per file, `old` and
  `new` on every line, `noop` on the 3,995 already correct.
- The apply arm needs the collection mounted **read-write** (this pass mounted it `:ro`), plus
  `--collection now --apply --snapshot-proof /mnt/fast/safety/phase05/snapshot-proof.txt` — that
  file already names `tank/downloads@pre-phase5` and was re-verified against atlantis here.
- The pilot volume should be **`Vol 036`**: it is the only volume whose files do not all share one
  current value, so it is the only one where a per-file rather than per-folder write can be
  observed, and it is the case the rule exists for.
- 05-09's field-loss gate diffs against
  `/mnt/fast/safety/music-pre-project/tags/phase05-now-before.ndjson.gz`, which was **not** touched
  or regenerated here. The 751-file write will move `TALB` and nothing else; `audio_md5` is stable
  only because `preserve_id3v1_trailer()` runs, which is now asserted by a self-test case with a
  proven-failing control rather than by a comment.

## Self-Check: PASSED

- `scripts/normalise-dj-tags.py`, `artifacts/05-08-dryrun-verification.txt` and this file all
  present in the working tree.
- Commits `d116447`, `0c12866`, `46bdf63` all present in `git log --all`.
- Host artefacts non-empty: `now-album-dryrun.ndjson`, `…summary.json`, `05-08-tree-before.tsv`,
  `05-08-tree-after.tsv`. The mutated-copy directory `05-08-negcontrol` is confirmed **removed**.
