---
phase: 05-inbox-structure-and-the-junk-gate
plan: 01
subsystem: storage-staging
tags: [zfs, snapshot, inbox, inode, filesystem-as-queue, atlantis]
requires: []
provides:
  - "tank/downloads@pre-phase5 — the D-01 reversibility fence every later Phase 5 plan consumes"
  - "/mnt/tank/downloads/complete/nzb/_inbox with its six policy directories, empty and 568:568"
  - "host:/mnt/fast/safety/phase05/snapshot-proof.txt — the proof file later mutating tools refuse without"
  - "host:/mnt/fast/safety/phase05/snapshot-creation.txt — epoch 1789742526, the D-27 ordering instrument"
  - "host:/mnt/fast/safety/phase05/inode-proof.txt — D-21 driven, both controls"
  - ".planning/phases/05-inbox-structure-and-the-junk-gate/05-INBOX-PATHS.md — measured paths for Phase 6"
affects: [05-02, 05-03, 05-04, 05-05, 05-06, 05-07, 05-08, 05-09, 05-10, 05-11, "Phase 6 CONF-01..06"]
tech-stack:
  added: []
  patterns:
    - "privileged delegation to atlantis over ssh (freeze-music-apply.sh detect_zfs_route/zfs_exec shape)"
    - "proof file DERIVED from the readback, never typed"
    - "driven negative control — prove the instrument can fail (D-21, quick-health-check.sh VENDORED_DRIFT)"
key-files:
  created:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/05-INBOX-PATHS.md
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-01-fence-and-tree-proof.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-01-inode-proof.txt
  modified: []
decisions:
  - "D-21's negative control targets LXC 100's ext4 root, not the library — Phase 1 D-20 untouched"
  - "The library MOUNT PATH is kept out of Task 2's commands AND its prose, so the criterion stays mechanically checkable"
  - "Task evidence committed as repo artifacts because all three deliverables are otherwise off-repo"
metrics:
  duration: ~12 min
  completed: 2026-09-18
  tasks: 3
  commits: 3
---

# Phase 5 Plan 01: Inbox Structure — the Fence, the Tree and the Inode Proof — Summary

The D-01 reversibility fence is in place as `tank/downloads@pre-phase5`, the six-directory staging
tree exists empty and `568:568` on the same devid as the content that will move into it, and
criterion 1's atomic-rename claim is backed by an instrument observed both holding and breaking.

## What was done

**Task 1 — the fence and the tree.** Re-verified `05-PREMEASURE.md` § 1 *before* acting, because its
own Limits section flags it as the claim most deserving a re-check and the whole phase rests on it.
It holds: `/mnt/tank/downloads`, `complete/nzb`, `unsorted` and `dj-mixes` all report devid **68**;
`/mnt/tank/media/Music` reports **76**. The STOP gate did not fire. Took
`tank/downloads@pre-phase5` (creation epoch **1789742526**) before creating anything, then built
`_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}` with seven literal `mkdir -p` and
seven literal `chown 568:568`, no variable interpolation and no recursive flag anywhere.

**Task 2 — the D-21 inode proof.** Positive control: a fixture moved `01-auto` → `02-review` kept
the pair `(68, 247882)` exactly. Negative control: the *same* fixture moved to LXC 100's ext4 root
went `(68, 247882)` → `(64519, 1050087)`. Both driven, both value pairs printed.

**Task 3 — `05-INBOX-PATHS.md`.** 100 lines carrying the six measured paths with their bucket
policies, the devid table, D-18 as a prohibition with its reason, D-19's `_done` policy, D-26's
no-chown-per-move statement, and both inode controls.

## Evidence

| Check | Result |
|---|---|
| `zfs list -t snapshot -H -o name tank/downloads@pre-phase5` | `tank/downloads@pre-phase5`, rc 0 |
| snapshot `creation` epoch | `1789742526` |
| `ls -1 _inbox \| sort` | exactly the six, no more |
| entries below depth 1 / non-dirs at depth 1 | 0 / 0 — created empty (D-17) |
| ownership of all seven, **read from atlantis** | `568:568` on every one |
| dirs under `_inbox` not `568:568` | 0 |
| `zfs list -t filesystem -r tank/downloads` | one line, `tank/downloads` — no `_inbox` dataset |
| devid: `_inbox` / `unsorted` / `dj-mixes` / `media/Music` | 68 / 68 / 68 / **76** |
| staging-shaped dirs under `/mnt/tank/media` to depth 3 | 0 |
| `grep -c 'INODE UNCHANGED'` / `'INODE CHANGED'` | 1 / 1 |
| `find _inbox -mindepth 1 -maxdepth 2 \| wc -l` after cleanup | 6 |
| `test -e .../inode-negative` | false |
| `05-INBOX-PATHS.md` line count | 100 (limit 100) |

No `chmod` was attempted anywhere. Mode is `0777` inherited, and stays that way.

## Findings worth carrying forward

**The inode collision is real, and it showed up in the very first measurement.**
`/mnt/tank/downloads` and `/mnt/tank/media/Music` **both report inode 34**. Inode numbers are
unique only within a filesystem, so an instrument comparing `%i` alone would have called two
distinct objects identical. This is why D-21's assertion is on the pair `(%d, %i)` — and it is no
longer a theoretical caution, it is the first row of this plan's first measurement. Recorded in
both artifacts and in `05-INBOX-PATHS.md`.

**The `65534` hazard did not fire here, and the reason matters.** LXC 100 reads the six directories
as `568:568 68`, agreeing with atlantis. That is because `568` is *inside* the container's sparse
idmap; the collapse to `65534` happens on ids the namespace cannot name (`545`, `0`). A
container-side reading agreeing with the disk is luck of the uid, not a reason to stop checking
from atlantis. All ownership readings in this plan were taken from atlantis regardless.

**`/mnt/tank/downloads` and its top-level children are already `568:568`.** D-24's sweep is about
the ~197,776 uid-3000 entries *below* them, not the roots. Noted so plan 05-10 sizes its expectation
against the right population.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 2 — missing critical functionality] Task 1's and Task 2's evidence existed only off-repo**

- **Found during:** Task 1, before its commit
- **Issue:** All three of Task 1's deliverables are off-repo — a ZFS snapshot, six directories on
  `tank`, and two proof files on LXC 100's ext4 root. The plan's `files_modified` lists them with a
  `host:` prefix. That left Task 1 and Task 2 with nothing committable, and left the measurements
  that Task 3 and every later plan depend on living only on hosts nobody snapshots.
- **Fix:** Captured each task's real command output as a repo artifact under
  `.planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/`, following the house
  convention already used by Phase 02.1 (`artifacts/02.1-06-transcode-proof.txt`). These are
  transcripts, not restatements.
- **Files created:** `artifacts/05-01-fence-and-tree-proof.txt`, `artifacts/05-01-inode-proof.txt`
- **Commits:** `1a14d38`, `c98bbd2`

**2. [Rule 1 — bug] The snapshot proof file was initially TYPED rather than derived**

- **Found during:** Task 1, STEP 2
- **Issue:** The first write of `snapshot-proof.txt` used a `printf` of the literal string. That is
  the one failure mode the proof file exists to prevent — a typed proof can name a snapshot that
  does not exist, and every later Phase 5 plan refuses to act on the strength of this file.
- **Fix:** Rewrote both proof files by piping the live `zfs list` / `zfs get` output from atlantis
  straight into the file on LXC 100, so the content is derived from the query. Verified with
  `cat -A` (no trailing whitespace, bare integer epoch).
- **Commit:** `1a14d38`

**3. [Rule 1 — bug] `05-INBOX-PATHS.md` failed two of its own acceptance criteria on first write**

- **Found during:** Task 3 verification
- **Issue:** (a) 102 lines against a 100-line limit. (b) `grep -ci 'verified in both Jellyfin and
  Music Assistant'` returned **0** — the required phrase was split across a line wrap. This is the
  estate's recurring "a mechanical check defeated by how the prose is laid out" shape, caught by
  running the criteria rather than assuming them.
- **Fix:** Reflowed the D-19 paragraph so the phrase sits on one line, and trimmed three lines.
  Final: 100 lines, all greps 1.
- **Commit:** `84d7241`

### Judgement calls, recorded rather than silent

**D-21's negative control target.** `05-CONTEXT.md` leaves this to the planner and the plan chose
LXC 100's ext4 root (`/mnt/fast/safety/...`), which is a different filesystem entirely and needs no
`zfs` and no `chown`. Phase 1's D-20 is therefore untouched and atlantis was not involved in Task 2
at all.

**The library path is absent from Task 2's prose as well as its commands.** The acceptance criterion
is "`/mnt/tank/media/Music` appears in none of the commands run by this task". The plan also asks
that the choice be *recorded in the evidence file*. Writing the path into that file would have put
it into a command. Resolved by naming the **dataset** (`tank/media/Music`) in the explanation and
keeping the **mount path** out of everything — verified mechanically: `grep -c '/mnt/tank/media/Music'`
returns **0** against both `inode-proof.sh` and `inode-proof.txt`. Called out because this estate has
been bitten repeatedly by checks satisfied or defeated by prose about the thing rather than the thing.

## Authentication gates

None. Both hosts answered on existing key-based `BatchMode=yes` ssh.

## Known stubs

None. Nothing in this plan is placeholder or pending wiring.

## Threat flags

None. No new network endpoint, auth path or schema was introduced. The plan's own register
(T-05-01-01…06) was honoured: literal absolute paths with no interpolation, no recursive flag, the
fixture dot-prefixed and trap-removed, the negative control off the library, the snapshot read back
into a derived proof file, and every byte written under `/mnt/fast/safety/phase05` — nothing to
`/tmp`, which is tmpfs on LXC 100.

## Left on the host, deliberately

`/mnt/fast/safety/phase05/inode-proof.sh` — the Task 2 driver, kept beside its output so the proof
is re-runnable. It is under `/mnt/fast/safety/`, **not** `/mnt/fast/stacks/scripts`, so it cannot
block a later `git pull --ff-only` on LXC 100.

## Scope statement

Nothing was moved, deleted or tag-written. Nothing outside the seven new directories was chowned —
D-24's tree-wide sweep is plan 05-10 and runs last (D-27), so it will also re-normalise these six.
`99-quarantine` is empty; D-11's sweep is a later plan.
