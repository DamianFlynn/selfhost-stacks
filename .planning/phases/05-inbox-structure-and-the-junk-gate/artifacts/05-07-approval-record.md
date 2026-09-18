# The operator approval, bound by hash — plan 05-07 Task 1

**This file is the durable record of the decision gate that authorised roughly 4,746 irreversible
renames.** It is written BEFORE any rename. Its purpose is that a later reader can tell exactly
*which mapping content* the yes was given against, rather than having to trust that the file on disk
is still the one that was read.

## The decision

| Field | Value |
|---|---|
| Gate | plan 05-07 Task 1, `checkpoint:decision` |
| Decided | 2026-09-18 |
| Selection | **`approve-as-is`** — apply the mapping exactly as it stands |
| Amendments | **none.** No row edited, no row deleted, no re-derivation requested |
| Scope of the yes | ~4,746 renames inside the `Now!` collection folder, reversible only by rolling back `tank/downloads@pre-phase5` |

The operator read the four artifacts plan 05-06 produced — `now-volume-numbers.tsv` (119 rows, the
rule that fired per row), `now-album-aliases.tsv` (117 rows, all `unique`),
`now-split-map.tsv` (the mapping itself) and `now-split-reconciliation.txt` (the arithmetic) — and
selected option 1 with no amendments.

## What the yes is bound to

| Binding | Value |
|---|---|
| Artifact | `host:/mnt/fast/safety/phase05/now-split-map.tsv` |
| **sha256 at approval** | `9ef5da2b9ed8947529689a107c2bf0d20becbe4a6ec3274878179a4eb181fba9` |
| Rows at approval | **4,751** |

**Re-checked immediately before the first rename** (this plan, Task 2): the file on disk hashed to
`9ef5da2b9ed8947529689a107c2bf0d20becbe4a6ec3274878179a4eb181fba9` and carried 4,751 rows. **Match.**
The approval therefore covers the content that was acted on. A mismatch would have aborted with
nothing moved (T-05-07-02).

## The rollback fence, verified before the first rename

| Check | Reading |
|---|---|
| Snapshot | `tank/downloads@pre-phase5` exists on atlantis |
| Creation | `Fri Sep 18 15:42 2026`, epoch **1789742526** — identical to the 05-01 record |
| Sibling snapshots | `@pre-project`, `@pre-chown` — both a month stale, both correctly NOT what the proof names |
| Proof file | `host:/mnt/fast/safety/phase05/snapshot-proof.txt`, contents `tank/downloads@pre-phase5` |

This snapshot is the **only** undo for the renames (D-01, D-27). `mv` has no undo and neither does
the tool.

## The map re-verified against live disk, independently, before acting

Reproduced rather than inherited — the download tree is written at ~1 music job per 72 s, so the map
is a point-in-time view and the figures it was approved against had to be re-measured:

| Measure | Reading |
|---|---:|
| map rows / rows not carrying 5 fields | **4,751** / **0** |
| map mp3 rows / mp3 files on disk | **4,746** / **4,746** |
| in the map but NOT on disk | **0** |
| on disk but NOT in the map | **0** |
| `AGREE` | 4,742 |
| `TIEBREAK-ALBUMTAG` | 4 |
| `SIDECAR` (moved) | 4 |
| `SIDECAR-IN-PLACE` (the m3u, stays at root) | 1 |
| distinct destination directories | **115** |
| destinations outside `NOW_ROOT/Vol ` | **0** |
| destinations containing a `CD1`/`CD2` component | **0** (D-05, flat) |
| volume coverage | exactly **1..115**, **0** gaps |

## The hazard this gate exists to stop, recorded

`references/checkpoints.md` golden rule 5: when `workflow._auto_chain_active` or
`workflow.auto_advance` is true, a `checkpoint:decision` **auto-selects the first option** — and the
first option here is the one that performs the renames. Both flags are `false` in
`.planning/config.json`, so this was not active, and the decision was taken by a human.

The durable protection is not the checkpoint type. It is D-13's file-based refusal, which is
load-bearing and must not be weakened: `apply` refuses without the approved map on disk, refuses
without a snapshot proof naming `tank/downloads@pre-phase5`, and the hash is re-checked immediately
before it acts. **A branch can be skipped by a flag, an env var or a future edit; a missing file
cannot.**
