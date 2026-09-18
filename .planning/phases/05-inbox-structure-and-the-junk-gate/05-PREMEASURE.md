---
phase: 05-inbox-structure-and-the-junk-gate
measured: 2026-09-18
type: premeasure
status: informational
---

# Phase 5: Inbox Structure and the Junk Gate — Pre-Measurements

These are **read-only measurements taken from the Proxmox host `atlantis` (172.16.1.158) on
2026-09-18, before Phase 5 was discussed or planned.** Nothing was modified: no directory was
created, no file moved, no snapshot taken, no dataset property changed. They are recorded here
because three of Phase 5's four success criteria are **materially changed** by them — criterion 1's
central assumption is confirmed, criterion 2 appears mis-specified in one clause and over-scoped in
another, and criterion 3's target turns out to be a different shape than its wording implies — while
the fourth, criterion 4, is confirmed **already satisfied**. They exist as a file rather than as
conversation because a measurement that lives only in a transcript cannot be planned against.

---

## 1. Criterion 1 is satisfiable — the same-dataset assumption HOLDS

`/mnt/tank/downloads`, `/mnt/tank/downloads/complete`, `/mnt/tank/downloads/complete/nzb` and
`/mnt/tank/downloads/incomplete` all report **`devid=68`**, dataset **`tank/downloads`**.
`/mnt/tank/media/Music` reports **`devid=76`**, dataset **`tank/media/Music`**.

Consequence: an `_inbox` created under `tank/downloads` is on the **same dataset** as the content
that will move into it, so moves between `_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}`
are **atomic renames with unchanged inode** — exactly the property criterion 1 demands be verified by
inode rather than by watching it look fast. Criterion 1 is therefore satisfiable as written.

Library moves remain **copy-then-unlink** across the `tank/downloads` → `tank/media/Music` dataset
boundary, consistent with the existing record in `CLAUDE.md` § Constraints. Nothing here changes that.

**Why this was checked at all:** Phase 4's criterion 3 failed on an **unverified capture
assumption** — a byte-capture design that could never have worked given SABnzbd's hook ordering,
believed sound until it was measured. Checking the devid before planning is the direct lesson from
that failure.

## 2. The reversibility fence covers `tank/downloads` but is a month stale

Snapshots present:

| Dataset | Snapshots | Date | Approx. size |
|---|---|---|---|
| `tank/downloads` | `@pre-project`, `@pre-chown` | 2026-08-18 | ~458K each |
| `tank/media/Music` | `@pre-project`, `@safe05-watch-t0`, `@pre-chown` | 2026-08-18 | — |

So the fence **does** cover the dataset Phase 5 will restructure — but it was taken a month ago, and
a month of downloads has landed in `tank/downloads` since. These are **not** a pre-Phase-5 baseline;
rolling back to them would discard a month of unrelated content.

Space is not a constraint: `tank/downloads` is **2.08T used, 8.50T available**, so a fresh snapshot
is cheap.

**Recommendation, NOT yet done:** take `tank/downloads@pre-phase5` **before anything moves**. beets
has no `undo` command, and neither does `mv`.

## 3. Criterion 3's target is ONE folder, not two, and it is FLAT

`VA-Now_That.s_What_I_Call_Music__1-115_2023` exists at two paths:

| Location | Size | Files | Subdirectories | Inode |
|---|---|---|---|---|
| under `dj-mixes/` | 512 B | **0** | 0 | 243398 |
| under `unsorted/` | **45 G** | **4760** | **0** | 15900 |

The `dj-mixes/` copy is **empty** — it is itself junk, and is a candidate for criterion 2's sweep
rather than criterion 3's split. The `unsorted/` copy is the real one.

The consequential finding is that the real folder has **ZERO subdirectories**: 4760 files flat. The
per-volume split therefore **cannot move existing subfolders, because there are none.** Volume
boundaries must be **derived from filenames**, which is materially harder than criterion 3's wording
("is split into per-volume folders") implies, and needs its own plan step with its own verification.

The file-count reconciliation target criterion 3 asks for — "per-volume file counts summing back to
the original count" — is **4760**.

## 4. Criterion 2's Harry Potter clause appears mis-specified

Criterion 2 requires "the Harry Potter BluRay rip is out of `dj-mixes`". A `find` over `dj-mixes` to
depth 3 for `*potter*` returns **zero**.

The rips that do exist are:

- `complete/nzb/unsorted/Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE`
- `incomplete/Harry.Potter.and.the.Deathly.Hallows.Part.1.2010.BluRay.1080p.DDP.5.1.x264-hallowed`
  — this one contains an `__ADMIN__` directory, which suggests a stalled job.

Either the clause is **already satisfied** (nothing Potter-shaped is in `dj-mixes`), or it was
**written against the wrong location** and means one of the two paths above. Which of those it is, is
a **Phase 5 decision for discuss-phase — not something to silently reinterpret** while writing plans.

## 5. Criterion 2 as phrased pulls the arrs into scope

Ten `_FAILED_` / `_UNPACK_` directories exist under `complete/nzb/`. Only **four** are music:

- `_UNPACK_Ed Sheeran…`
- `_UNPACK_Katy Perry - Prism (2013) FLAC`
- `_FAILED_Garth.Brooks-Ropin.The.Wind…`
- `_FAILED_Garth.Brooks-The.Ultimate.Hits…`

The other **six** are TV and movies: `Chicago.PD.S13E02`, two `Goldie.and.Bear.S02E26E27` variants,
two `Prep.and.Landing.2009` variants, and `Disclosure.Day.2026`.

Criterion 2 is written over **the whole download tree** ("searching the download tree returns
zero…"), so **as stated it quarantines Sonarr's and Radarr's failures too** — moving another
service's failed jobs into a music-project quarantine folder. That is a **scope decision for
discuss-phase**, not an implementation detail.

Also present and in scope for the same criterion: **6 stray `.rar` files** (depth ≤ 6).

## 6. Criterion 4 is ALREADY GREEN

**Zero** `_`-prefixed directories exist anywhere under `/mnt/tank/media/Music`.

Criterion 4 is therefore a **guard to maintain, not work to perform.** The plan should **assert** it
(before and after the phase's moves, so that a stray staging-style name cannot leak into the library)
rather than budget effort for achieving it.

## 7. `_inbox` does not yet exist

There is no `_inbox` under `/mnt/tank/downloads`. Criterion 1's tree is entirely to be created; none
of it is partially present from an earlier attempt.

## 8. Carried forward for Phases 6–7, not Phase 5

`dj-mixes` holds **84 top-level entries** with badly inconsistent naming:

- `Mastermix_Issue_410` sits beside `Mastermix_Issue_410.1`
- `Mastermix.Issue.420.2021` uses a different separator style entirely
- several end in a bare `_-` that looks truncated: `Mastermix_Issue_423_-`, `_424_-`, `_425_-`,
  `_431_-`, `_432_-`, `_436_-`, `_437_-`, `_438_-`
- it also contains Now! compilations (`__118__`, `__119__`), so **the folder is not purely
  Mastermix** despite its name

This bears on **later matching** — folder names are an input to tagger candidate selection and to the
Discogs lookups Phase 3 decided on — **not on inbox structure.** Recorded here so it is not
rediscovered in Phase 6.

---

## Limits

- **Point-in-time reads on a moving tree.** `/mnt/tank/downloads` is written to by an active
  downloader, previously measured at roughly **one music job per 72 seconds**. Every count above —
  4760, 84, 10, 6, 2.08T — **will drift**, and the `_FAILED_`/`_UNPACK_`/`.rar` counts are the ones
  most likely to have changed by the time a plan runs. Re-measure before reconciling against any of
  them.
- **Nothing here was re-verified after measurement.** These are single reads, not driven assertions
  with negative controls. The devid finding (§ 1) is the one that most deserves a re-check at plan
  time, because the largest single claim in this file rests on it.
- **No recommendation in this file has been executed.** In particular `tank/downloads@pre-phase5`
  (§ 2) **has not been taken**, and no junk has been moved, quarantined or deleted.
- **Two criteria carry open questions, not findings.** § 4 (Harry Potter clause) and § 5 (arrs in
  scope) are for the operator to rule on in discuss-phase. This file deliberately does not choose.
