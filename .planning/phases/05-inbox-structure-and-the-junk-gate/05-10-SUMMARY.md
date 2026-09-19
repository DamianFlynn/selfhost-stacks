---
phase: 05-inbox-structure-and-the-junk-gate
plan: 10
subsystem: download-tree-ownership
tags: [chown, D-24, D-25, D-26, D-27, scope-narrowing, idmap, detached-runner, zfs-diff, two-process-gate, orphan-uid]
requires:
  - "05-01 — tank/downloads@pre-phase5, asserted present before the run and still the only undo for 05-07's renames and 05-09's 751 tag writes"
  - "05-07 — the 115 Vol NNN directories this run normalises"
  - "05-09 — the album write, after which D-27 puts this chown last"
provides:
  - "host:the project's own staging tree uniformly 568:568 — mac-music-archive/, media/ and complete/, 37,191 entries, zero foreign, read from atlantis"
  - "scripts/phase05-downloads-chown.sh — enumerate/apply gate, 1,174 lines, 15 refusals driven"
  - "host:/mnt/fast/safety/phase05/chown-verification.txt — the D-25 deliverable: the measurement and its date"
  - "host:/mnt/fast/safety/phase05/chown-rows.tsv — the 139-row gate file the operator approved"
  - ".planning/…/05-10-SURVEY.md — the ownership survey the narrowing was decided on"
  - ".planning/…/artifacts/05-10-* — verification record, row list, runner log"
affects: [05-11, 06, 07]
tech-stack:
  added: []
  patterns:
    - "roll a quarter of a million foreign entries into a reviewable row list by emitting the SHALLOWEST entirely-foreign subtree, and assert the rows account for every entry — a roll-up that loses entries is worse than none, because the list looks complete"
    - "make the drift key a row's IDENTITY (path, type, devid, inode, owner) and never its entry COUNT, when the tree under it is live — a count-keyed abort fires on every run and teaches everyone to re-approve without reading"
    - "put every fence that needs no remote access AHEAD of the remote access, or its negative controls all pass on 'no route' and prove nothing"
    - "prove an untouched-claim with an instrument driven to FAIL on the same shape of change elsewhere; 'identical' from an instrument never seen to differ is not evidence"
    - "prefer a whole-DATASET instrument (zfs diff) over a whole-ROOTS one for a negative claim: it can see a reach into a tree the positive instrument never walks"
key-files:
  created:
    - scripts/phase05-downloads-chown.sh
    - .planning/phases/05-inbox-structure-and-the-junk-gate/05-10-SURVEY.md
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-10-chown-verification.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-10-chown-rows.tsv
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-10-runner-log.txt
  modified:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/05-CONTEXT.md
    - .planning/phases/05-inbox-structure-and-the-junk-gate/deferred-items.md
key-decisions:
  - "The operator narrowed D-24 from 222,376 entries to 26,005 on the survey: dropbox/ (196,327) is a personal code and document archive and not downloads, and google takeout/ (42) was being read by an active import throughout. 26,005 + 196,371 excluded = 222,376, so the arithmetic closes and nothing was quietly dropped"
  - "D-24's preserved counter-argument — 'uid 3000 is the download client legitimately owning what it wrote' — was refuted by measurement and amended in band rather than left standing: host uid 3000 is outside every LXC 100 idmap range, has no passwd entry, and SABnzbd's own output is 568:568"
  - "Entry counts were deliberately NOT made a drift key, departing from the junk sweep which keys on them: its rows are things it destroys, these are chowns on a 0777 tree under a downloader writing a job every 72 s, so a count-keyed abort would fire on nearly every run"
  - "mac-music-archive/ had its ownership normalised and its CONTENT deliberately not examined — a next-milestone scoping question, not an execution one"
requirements-completed: []
duration: ~3 h 20 min across two dispatches
completed: 2026-09-19
---

# Phase 5 Plan 10: 26,005 Entries, 7 Seconds, and a Scope That Had to Be Measured Before It Could Be Decided Summary

**The chown ran, and it is not the chown the plan described. D-24 asked for all 209,039 entries of
`tank/downloads`; the survey found 233,824, of which 222,376 were not `568:568` — and 84% of that
was a personal Dropbox mirror, 11% a music archive no phase had ever counted, and one subtree was
being read by a live Immich import at that moment. The operator narrowed the run to 26,005 entries
on those measurements. 139 rows, 7 seconds of chown, and `zfs diff` against a fresh baseline
returned exactly `M 26005` with zero `+`, `-` or `R` lines — the instrument saw the approved scope
to the entry and nothing else. The library proof was 0 lines. `dropbox/` and `google takeout/` are
provably untouched by three independent instruments, one of which was driven to fail first. Fifteen
refusals were driven, including the runner's drift abort end-to-end, which proved it validates all
139 rows before acting on any: a corrupt row at position 70 left rows 1–69 carrying their original
owners.**

## Performance

- **Duration:** ~3 h 20 min across two dispatches (survey, then apply)
- **Completed:** 2026-09-19
- **Tasks:** 4 — tool, operator decision gate, the run, post-hoc review
- **Commits:** 5
- **The chown itself:** **7 s** for 26,005 entries. The scoped survey: **10.4 s**. The whole-tree
  survey that preceded the narrowing: **could not finish in an hour.**

## The number that mattered most

```
zfs diff tank/downloads@pre-phase5-chown tank/downloads   ->   M 26005
                                                               (no +, no -, no R)
```

26,005 is the approved scope, to the entry. The diff is **whole-dataset**, so a chown that had
reached `dropbox/` would have appeared in it. It did not.

## What was decided, and on what

D-24 was written before anyone had looked. The survey (`05-10-SURVEY.md`) is the looking, and it
changed the decision three ways:

| D-24 as written | As measured |
|---|---|
| "all **209,039** entries" | **233,824** entries, **222,376** not `568:568` |
| "197,776 … currently uid **3000**" | **197,776**, reproduced *exactly*, a day later |
| "`incomplete/` included" — the risky inclusion | `incomplete/` is 260 entries and was **already 100% correct**. No work in it at all |
| "uid 3000 is the download client legitimately owning what it wrote" | **False.** See below |

The denominator moved by +24,785 while the uid-3000 population did not move at all, so the growth
is not download inflow. `mac-music-archive/` alone is 23,874 of it.

**The approved scope, and the arithmetic that shows nothing was dropped:**

| | entries | rows | |
|---|---:|---:|---|
| `mac-music-archive/` | 23,874 | 1 | recursive |
| `media/` | 1,403 | 1 | recursive |
| 19 entirely-foreign folders under `complete/` | 610 | 19 | recursive |
| the 115 `Vol NNN` directories | 115 | 115 | self |
| 3 `.DS_Store` under `complete/` | 3 | 3 | self |
| **normalised** | **26,005** | **139** | |
| `dropbox/` | 196,327 | — | **excluded** — `code/`, `Archive/`, `Documents/`, `Projects/`; not downloads |
| `google takeout/` | 42 | — | **excluded** — an import was reading all 41 zips |
| `icloud/` · `/.DS_Store` | 2 | — | **excluded** |
| **excluded** | **196,371** | | |

**26,005 + 196,371 = 222,376**, the full measured foreign count. Re-derived independently before
acting rather than taken from the brief.

### uid 3000 is an orphan, not the download client

Four readings, any one of which is sufficient:

1. Host uid 3000 is **outside every range** of LXC 100's idmap (`u 0 100000 568` / `u 568 568 1` /
   `u 569 100569 64967`). No process in that container can create a file owned 3000 on disk.
2. `getent passwd 3000` on atlantis returns nothing — as `getent group 545` returns nothing.
3. SABnzbd's live working directory, `incomplete/`, was **260 entries, 100% `568:568`**.
4. The 3000-owned mass was `dropbox/`, `media/` and the takeout zips. None of it is download output.

Amended in band in `05-CONTEXT.md` in the 02.1-11 / 04-04 shape: original text intact, the
amendment quotes it, states the measurement, names the narrowing, and shows the substance is
preserved.

## The result, read from atlantis

| root | entries | not `568:568` |
|---|---:|---:|
| `/mnt/tank/downloads/mac-music-archive` | 23,874 | **0** |
| `/mnt/tank/downloads/media` | 1,403 | **0** |
| `/mnt/tank/downloads/complete` | 11,914 | **0** |

A `find` across all three for any entry not `568:568` returned **nothing**. Read on the
hypervisor, never from inside LXC 100 — a container-side `65534` is the idmap view, not the disk.

## `dropbox/` and `google takeout/` are untouched, by three instruments

1. **An owner + ctime fingerprint, 330 lines** — the five excluded paths, every depth-1 entry of
   `dropbox/` and of `google takeout/`, and all 260 entries of `incomplete/`. sha256
   `c518cb10…f0b972` **identical** before and after. A chown moves ctime.
2. **The same instrument driven to FAIL.** On a throwaway pair outside `tank`, `chown -h 568:568`
   on one moved its fingerprint line while its untouched sibling stayed put. *"Identical" from an
   instrument never seen to differ is not evidence* — 05-09 paid for that lesson with the `zfs diff`
   criterion, and this is the same defect avoided in advance rather than discovered afterwards.
3. **`zfs diff` is whole-dataset.** It reports on `tank/downloads`, not on the three roots that
   were walked, so it is capable of seeing a reach into a tree the positive instrument never
   touches. Exactly `M 26005`, and not one line under any excluded path. Recorded alongside:
   `atime=off` on the dataset, so immich-go reading all 41 zips throughout contributed no lines.

The import was **still running** when the run finished, and `google takeout` was still `3000:545`.

## The guards, and which were driven

Fifteen refusals, each observed to fire **on its own merits**:

| guard | result |
|---|---|
| `DOWNLOADS` not the literal `/mnt/tank/downloads` | exit 2 |
| `LIBRARY` not the literal `/mnt/tank/media/Music` | exit 2 |
| `UIDGID` not `568:568` | exit 2 |
| no approved row list | exit 2 |
| no snapshot proof | exit 2 |
| proof naming `@pre-chown` | exit 2 |
| **proof naming only `@pre-phase5-chown`** (the superset trap) | exit 2 |
| no zfs route | exit 2 |
| **no detached-session launcher** | exit 2, **before any snapshot was created** |
| **a pre-existing `@pre-phase5-chown`** | exit 2 — refusal, not silent reuse |
| a row inside `dropbox/` / `google takeout/` / `icloud/` / `incomplete/` | exit 2, by name |
| a row inside `/mnt/tank/media` | exit 2, Phase 1 D-20 |
| a relative path, or one containing `..` | exit 2 |
| an **in-scope** row (positive control) | passed the fence |
| enumerate over an existing list | exit 2 |

**The runner's drift abort, driven end to end.** A copy of the row list with **one** inode
corrupted, at **position 70 of 139**, launched detached on atlantis:

```
DRIFT row 70: …/Vol 056 inode 260336999 -> 260336
validated 139 row(s); already-normalised 0; drift 1
ABORTING THE WHOLE RUN: 1 row(s) drifted after approval. NOTHING CHOWNED.
sentinel: exit=2 reason=drift rows=139 drift=1
```

Rows 1–69 were then checked on disk and **every one still carried its original foreign owner**.
That is the property the design rests on — validate all, then act — and it is now measured rather
than asserted.

**Sentinel states driven:** `exit=0` (the real run), `exit=2` (the drift run), and **"still
running"** (the real run's poll loop reported at 15 s). **Not driven:** *"the runner died without
writing a sentinel"* — reaching it requires killing the runner inside a sub-second window. It is
the third branch of the poll loop and it is a could-not-look, not a pass.

## Deviations from Plan

### The plan's scope was overtaken by its own survey

**1. [Rule 4 — architectural, escalated and decided] The chown is 26,005 entries, not 222,376**

- **Found during:** Task 2's survey
- **Issue:** D-24's scope was set without a breakdown. The breakdown showed 84% of it was a
  personal code archive, 11% an uncounted music archive, and one subtree in active use.
- **Resolution:** escalated as a checkpoint; the operator narrowed it. Not auto-fixed — this is
  precisely the Rule 4 shape.
- **Commit:** `048375b`

### Auto-fixed, all mine, none reaching content

**2. [Rule 1 — Bug] A negative-control run of `apply` created two snapshots**

- **Found during:** Task 1's refusal battery
- **Issue:** the battery ran on the workstation, which had a **live** ssh route to atlantis, so
  the "correct proof" case reached the baseline step and created `tank/downloads@pre-phase5-chown`
  and `tank/media/Music@pre-phase5-chown` (both 0 B). **No chown ran** — `/var/lib/phase05-chown/`
  never existed, so the runner was never written, the list never shipped, the runner never launched.
- **Fix:** both destroyed (`zfs destroy -n` dry run first, exact names, never `-r`), `@pre-phase5`
  confirmed intact, and the battery re-driven with `ZFS_HOST=192.0.2.1` so the harness cannot mutate.
- **Commit:** `4526d1e`

**3. [Rule 2 — Missing guard, found by deviation 2] A pre-existing baseline was silently reused**

- **Issue:** the code was create-or-reuse. A stale `@pre-phase5-chown` would have been accepted as
  "fresh", and the library untouched-proof taken against it could not have distinguished this run's
  reach from anything earlier. The word in "fresh baseline" is *fresh*.
- **Fix:** a refusal. Driven by planting a snapshot and observing exit 2.
- **Commit:** `4526d1e`

**4. [Rule 2 — Missing guard] The snapshot proof matched a substring**

- **Issue:** `tank/downloads@pre-phase5-chown` **contains** `tank/downloads@pre-phase5`, so a proof
  naming only this run's own new snapshot would have passed `grep -F`. Same defect class as the
  `requireBeetsMatch` prefix bug recorded on 2026-09-14: an unbounded prefix passes supersets.
- **Fix:** `grep -qxF`, whole line. Driven: exit 2.
- **Commit:** `4526d1e`

**5. [Rule 1 — Non-discriminating controls] Every excluded-tree control passed for the wrong reason**

- **Found during:** driving the new fences
- **Issue:** the per-row fence sat **after** route detection, so all five excluded-tree controls
  exited 2 on `no zfs route`. Five green results proving nothing — the exact shape this estate keeps
  recording.
- **Fix:** the fence moved to the front of `apply`, before anything reaches atlantis, plus a
  `realpath -m` fallback so it is not defeated off-Linux. Re-driven: each fires by name, with an
  in-scope **positive control** to show the fence is not simply refusing everything.
- **Commit:** `048375b`

**6. [Rule 1 — Bug] An apostrophe in an awk comment closed the quoted program**

- **Issue:** `directory's` inside the single-quoted awk survey program terminated the quote; bash
  parsed the rest of the awk as shell. The message — `awk: line 92: missing } near end of file`
  followed by a bash syntax error on a line of awk — points nowhere near the cause.
- **Fix:** reworded, with the rule noted at the site, and an apostrophe check added to the
  pre-commit battery. The refusal fired correctly and nothing was read or written; one run wasted.
- **Commit:** `dfa0adc`

**7. [Rule 1 — Bug] The verification record printed an empty entry count**

- **Issue:** `apply` read the meta key `total_entries` while the payload emits `walked_entries`,
  so the record said `after census:  entries, 0 not 568:568`. **An empty number beside a correct
  one is the worst shape a record can take**, because the correct half makes the line look read.
- **Fix:** the key corrected and a `could-not-look` failure added if it is ever empty again. The
  record on disk carries an **addendum** with the true figures rather than a rewrite — the
  original is evidence.
- **Commit:** `f9c6a9c`

### Recorded, not deviations

- **The 115 `Vol NNN` directories were never `root:root`.** 05-09's summary says so; that was the
  container view. On disk they were `100000:100000` — container root through the idmap. Real `0:0`
  meant `mac-music-archive/` and `icloud/`. Noted in `05-10-SURVEY.md` §8 and in the verification
  record rather than by editing 05-09's summary.
- **ZFS device numbers have already moved.** `05-INBOX-PATHS.md` records `tank/downloads` at devid
  68 and the library at 76 on 2026-09-18; read a day later they are **70 and 75**. A devid is a
  mount-time assignment. The property that record proves still holds; the numbers do not. Do not
  write an assertion on `devid == 68`.
- **The whole-tree survey was abandoned deliberately, not abandoned.** Behind the live import it
  ran at ~32 entries/s. Scoped to the approved roots it takes **10.4 s**.

### Deliberately not fixed

- **`scripts/quick-health-check.sh` still exits 1** for the pre-existing, unrelated
  `interpolated-host-path inventory MOVED: expected=12, found=13` in `deferred-items.md`.
- **`mac-music-archive/`'s content** — ownership normalised, content deliberately not examined.
  Operator decision: a planning question, not an execution one.
- **`dropbox/` mounted `rw` into nine containers** — logged, not fixed; narrowing nine bind mounts
  is a stack change with its own blast radius.
- **An Immich API key in a systemd `ExecStart`** — logged, value not recorded, this repo is public.

## Authentication Gates

None.

## Evidence

| Check | Result |
|---|---|
| scope arithmetic re-derived before acting | 26,005 + 196,371 = **222,376** ✓ |
| row list | **139** rows covering **26,005** entries, sha256 `3d71b276…` |
| rows touching any excluded tree | **0** |
| `Vol NNN` rows with entry count ≠ 1 | **0** of 115 |
| runner sentinel | `exit=0 reason=complete rows=139 acted=139 errors=0 elapsed=7` |
| list sha on atlantis == list sha on LXC 100 | **identical** |
| approved roots after, from atlantis | 37,191 entries, **0** not `568:568` |
| `zfs diff` vs `@pre-phase5-chown` | **M 26005**, `+` 0, `-` 0, `R` 0 |
| `zfs diff` lines under any excluded path | **0** |
| library proof vs `tank/media/Music@pre-phase5-chown` | **0 lines** |
| excluded-tree owner+ctime fingerprint, 330 lines | **sha256 identical** before/after |
| that fingerprint driven to FAIL | detected a `chown -h` on a throwaway file ✓ |
| `atime` on `tank/downloads` | **off** — reads cannot pollute the diff |
| takeout import at end of run | **still running**, `google takeout` still `3000:545` |
| drift abort: rows before the corrupt row | **all 69 still foreign** — validate-all-then-act holds |
| `tank/downloads@pre-phase5` | **present**, `Fri Sep 18 15:42 2026` |
| stray `@pre-phase5-chown` snapshots from harness runs | created 3×, **destroyed 3×**, dry run first |
| `chmod` attempted | **none** — comment-stripped grep returns 0 |
| refusals driven | **15**, each on its own merits, with a positive control |
| credential screen over committed artifacts | clean (two sha256 values, no secrets) |

## Known Stubs

None. Every deliverable is a completed operation against real state, verified from the hypervisor
by instruments shown capable of failing.

## Still open, deliberately

- **INBX-01 / 02 / 03 stay UNTICKED.** All requirement ticks belong to plan 05-11.
- **`tank/downloads@pre-phase5` must not be deleted** before Phase 6 signs off. It is the only undo
  for 05-07's 4,750 renames and 05-09's 751 tag writes as well as for this chown.
- **`tank/downloads@pre-phase5-chown` and `tank/media/Music@pre-phase5-chown` remain**, deliberately
  — they are this run's evidence baselines.
- **`dropbox/`, `google takeout/`, `icloud/` and the root `.DS_Store`** carry non-`568:568`
  ownership by decision, not by omission. 196,371 entries.
- **D-25 holds: there is no standing check and there will not be one.** New non-568 files will
  appear the moment the download client writes again. The record and its date are the deliverable.
- **D-26 holds:** staging carries mixed ownership by design. Do not write an "everything under
  `_inbox` is `568:568`" assertion on the strength of this run.
- **`mac-music-archive/`** — 23,874 entries, ownership normalised, content unexamined. A
  next-milestone scoping question.

## Threat Flags

None. No network endpoint, no auth path, no schema change, no package installed from any package
manager. The one credential encountered — an Immich API key in a systemd unit on LXC 100 — was
deliberately not recorded and is logged as a deferred item for rotation.

## Self-Check: PASSED

All five created files exist. Commits `4526d1e`, `d6f11a7`, `048375b`, `dfa0adc`, `f9c6a9c` are
present in `git log`. The off-repo deliverables on LXC 100 exist with the stated contents:
`chown-rows.tsv` (139 rows, sha256 `3d71b276…`, matching the copy the runner acted on) and
`chown-verification.txt` (114 lines including the addendum).

---
*Phase: 05-inbox-structure-and-the-junk-gate*
*Completed: 2026-09-19*
