---
phase: 05-inbox-structure-and-the-junk-gate
plan: 01
type: reference
measured: 2026-09-18
for: Phase 6 CONF-01..CONF-06
---

# The inbox paths, as measured

**D-16's deliverable toward Phase 6.** Phase 6 must configure beets-flask against *measured*
directories, not intended ones. Every value below was read back after creation, from atlantis —
not from LXC 100, whose sparse idmap makes a container-side ownership reading inadmissible.
beets-flask itself is **out of scope here**: D-16 amends Phase 4's D-01, which deferred it *to*
Phase 5.

## The six paths

All six exist, are empty (D-17), and are `568:568` on disk (D-23).

| Path | Policy |
|---|---|
| `/mnt/tank/downloads/complete/nzb/_inbox/01-auto` | Bucket A — autotag, and import if the match score passes. |
| `/mnt/tank/downloads/complete/nzb/_inbox/02-review` | Bucket B — tag, present candidates, then wait for a human. |
| `/mnt/tank/downloads/complete/nzb/_inbox/03-asis` | Bucket C — import from existing tags, no autotag. |
| `/mnt/tank/downloads/complete/nzb/_inbox/04-hold` | Needs external artwork or tracklist sourcing before it can be tagged. |
| `/mnt/tank/downloads/complete/nzb/_inbox/99-quarantine` | Bucket D — junk, transiently, on its way to deletion (D-11). |
| `/mnt/tank/downloads/complete/nzb/_inbox/_done` | Post-import receipts: the whole source folder, held as the undo path. |

## Why `complete/nzb/_inbox` and not `/mnt/tank/downloads/_inbox`

`ARCHITECTURE.md` § *Recommended Structure* places `_inbox/` beside `music/`, `unsorted/` and
`dj-mixes/`, and D-12 lists it in exactly that company when it scopes the junk sweep. It is still
"under `tank/downloads`" as ROADMAP criterion 1 requires, because **`tank/downloads` is the
dataset** — `complete/nzb/` is just directories inside it. Recorded so nobody re-litigates the
location from the criterion's wording.

## D-18 — `_inbox` must NEVER become its own ZFS dataset

Measured 2026-09-18 from atlantis, `stat -c %d`:

| Path | devid |
|---|---|
| `/mnt/tank/downloads` | 68 |
| `/mnt/tank/downloads/complete/nzb` | 68 |
| `/mnt/tank/downloads/complete/nzb/unsorted` | 68 |
| `/mnt/tank/downloads/complete/nzb/dj-mixes` | 68 |
| `/mnt/tank/downloads/complete/nzb/_inbox` | **68** |
| `/mnt/tank/media/Music` | 76 |

`zfs list -H -o name -t filesystem -r tank/downloads` returns exactly one line, `tank/downloads`.
There is no `_inbox` dataset and there must never be one.

**The reason, because the prohibition looks like an obstacle to an improvement:** a dataset would
put `_inbox` on a different devid from `unsorted/` and `dj-mixes/`. Every move into staging would
become copy-then-unlink instead of `rename(2)` — slow, interruptible, needing transient double
space, and **destroying criterion 1's atomic-rename property outright**. Making it a dataset looks
tidy: you get a quota and independent snapshots, exactly what `fast/transcode` got in Phase 02.1.
That is precisely why this is written down rather than assumed.

## D-19 — the `_done/` policy

`_done/` holds **the whole source folder**, not a receipt. A release migrates `unsorted/` →
`01-auto/` → `_done/` as atomic renames, so reaching `_done/` **costs no extra space**.

Phase 6 sets `import.copy: yes` (CONF-01), so the library holds a *copy* while `_done/` holds the
original — **that original is the undo path**, and it matters because beets has no `undo` command.

Prune deliberately, per release, only after CONS-04 passes:
**verified in both Jellyfin and Music Assistant, and never on a timer.**
A receipt-only `_done/` was rejected — it deletes the untouched copy at exactly the moment
QUAL-02's before/after diff might reject the import.

## D-26 — content moved into `_inbox` is NOT chowned per-move

A rename preserves ownership, and adding a privileged `chown` to every move would contradict the
one-atomic-rename property this whole design rests on. **Staging therefore carries mixed ownership
by design.**

Stated explicitly so nobody later writes an "everything under `_inbox` is `568:568`" assertion.
D-25 guarantees it would drift: the download client keeps writing as uid 3000 at roughly one job
per 72 s. The six directories *themselves* are `568:568` (D-23); their contents are not.

## D-21 — the inode evidence, both controls driven

Driven on LXC 100, 2026-09-18T14:45:50Z. Full transcript: `artifacts/05-01-inode-proof.txt`.
Both value pairs were observed, not inferred from the devid table.

| Control | Move | Before `(%d, %i)` | After `(%d, %i)` | Verdict |
|---|---|---|---|---|
| Positive | `_inbox/01-auto` → `_inbox/02-review` | `(68, 247882)` | `(68, 247882)` | `INODE UNCHANGED` |
| Negative | `_inbox/02-review` → LXC 100 ext4 root | `(68, 247882)` | `(64519, 1050087)` | `INODE CHANGED` |

The negative control is the half that matters: an inode only ever observed staying the same is an
instrument nobody has shown can distinguish anything. It targets `/mnt/fast/safety/...` — a
different filesystem entirely — rather than the library, because Phase 1's D-20 bars `rw` there
until Phase 6, and the property under test is "a different devid changes the inode".

⚠ **Assert the pair `(%d, %i)`, never `%i` alone.** `/mnt/tank/downloads` and the library root
*both* report inode `34`. Inode numbers are unique only within a filesystem.
