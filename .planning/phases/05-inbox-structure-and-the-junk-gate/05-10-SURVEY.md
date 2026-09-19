---
phase: 05-inbox-structure-and-the-junk-gate
plan: 10
type: reference
measured: 2026-09-19T09:22Z
measured_from: atlantis (172.16.1.158), as real root
for: the D-24 operator decision — read this before approving the chown
---

# The download tree's ownership, as measured

**Read-only. Nothing was chowned, nothing was chmodded, and no snapshot was taken to produce
any number on this page.** This is the survey half of plan 05-10; the chown half is gated on the
operator reading it.

Every figure was read **from atlantis**, never from inside LXC 100. That is not a formality: LXC
100 is unprivileged with a sparse idmap (`u 0 100000 568`, `u 568 568 1`, `u 569 100569 64967`),
so unmapped on-disk ids surface as `65534` and several distinct owners collapse into one value.
Phase 1 lost time to exactly this.

Method: one `find /mnt/tank/downloads -xdev -printf '%U\t%G\t%y\t%p\n'` pass, aggregated on
atlantis. `-xdev` is a second fence on top of the path fence — the walk cannot leave the
`tank/downloads` dataset, and **zero** of the 233,824 rows it returned were under `/mnt/tank/media`.

---

## 1. The headline

| | entries |
|---|---:|
| total under `/mnt/tank/downloads` | **233,824** |
| already `568:568` | 11,448 |
| **NOT `568:568`** | **222,376** |
| symlinks anywhere in the tree | **0** |
| entries outside the fenced root | 0 |

### The denominator is not the one D-24 was written against

D-24 says *"all 209,039 entries"* with *"197,776 … currently uid 3000"*.

- **The uid-3000 figure reproduces exactly.** `3000:568` (197,733) plus `3000:545` (43) is
  **197,776**, to the entry, a day later. That population has not moved at all.
- **The total has not.** 233,824 against 209,039 is **+24,785**, and it is *not* download inflow —
  if it were, the uid-3000 count would have moved with it. `mac-music-archive/` alone is 23,874
  entries, and this phase's own 115 new volume directories plus 599 entries under `unsorted/`
  account for most of the rest.

Whatever the cause, **the number the decision is actually taken against is 233,824, not 209,039.**

---

## 2. By owner:group

| owner:group | dirs | files | total | what it is |
|---|---:|---:|---:|---|
| `3000:568` | 41,274 | 156,459 | **197,733** | orphan uid — see §5. Almost all of it is `dropbox/` |
| `0:0` | 5,702 | 18,172 | **23,874** | real root on disk. Almost all of it is `mac-music-archive/` |
| `100911:100911` | 14 | 585 | **599** | container uid **911** through the idmap — the LinuxServer.io `abc` default, i.e. a container that ran *without* `PUID` set |
| `100000:100000` | 116 | 0 | **116** | container uid **0** — the 115 `Vol NNN` directories this phase created, plus `mac-music-archive/` itself |
| `3000:545` | 1 | 42 | **43** | the **orphan gid 545**, the signature of the pre-2026-08-18 state |
| `0:568` | 5 | 6 | **11** | four `.covers` dirs with their scans, and one disk image |
| **not 568:568** | **47,112** | **175,264** | **222,376** | |

`getent group 545` returns nothing on atlantis. `getent passwd 3000` returns nothing either.
**Both are orphans.**

---

## 3. By top-level subtree

| top-level | entries | not 568:568 | share | last written |
|---|---:|---:|---:|---|
| `dropbox/` | 196,327 | 196,327 | **100%** | 2026-01-03 |
| `mac-music-archive/` | 23,874 | 23,874 | **100%** | 2024-10-27 |
| `complete/` | 11,914 | 728 | 6% | live (2026-09-18 23:42) |
| `media/` | 1,403 | 1,403 | **100%** | 2025-11-11 |
| `google takeout/` | 42 | 42 | **100%** | 2026-03-05 — **but see §6, it is open right now** |
| `incomplete/` | 260 | **0** | **0%** | live (2026-09-18 23:42) |
| `icloud/` | 1 | 1 | 100% | 2026-03-06 (empty) |
| `pickup/` | 1 | 0 | 0% | 2025-10-24 (empty) |
| `/.DS_Store` | 1 | 1 | 100% | — |
| the root directory entry itself | 1 | 0 | 0% | — |

**84% of everything this chown would touch is `dropbox/`.** A further 11% is
`mac-music-archive/`. The music download tree — the thing this project exists for — is
**728 entries, 0.3%**.

---

## 4. `incomplete/` needs nothing, and that inverts D-24's own framing

D-24 goes out of its way to say the scope is *"all 209,039 entries, `incomplete/` included"*, and
D-15 rules `incomplete/` out of every other operation in the phase because it is SABnzbd's live
working directory.

**`incomplete/` is 260 entries and every one of them is already `568:568`.** The one subtree the
decision singled out as the risky inclusion turns out to contain no work at all.

---

## 5. The download client does not write as uid 3000, and cannot

D-24 preserves a counter-argument it was taken *against*: *"`tank/downloads` is not exported, is
0777, and uid 3000 is the download client legitimately owning what it wrote."*

**The second clause does not survive measurement.** Four independent readings:

1. Host uid 3000 is **outside every range** of LXC 100's idmap. No process in that container can
   produce a file owned 3000 on disk, and host uid 3000 surfaces as `65534` inside it.
2. `getent passwd 3000` on atlantis returns nothing — there is no such user.
3. SABnzbd's live working directory, `incomplete/`, is **260 entries, 100% `568:568`**. The six
   `_inbox` directories and their 593 entries are `568:568` too.
4. The 3000-owned mass is `dropbox/` (196,327), `media/` (1,403), the takeout zips (42) and four
   `.DS_Store` files. **None of it is download-client output.**

uid 3000 is an orphan carried in from somewhere else — the same shape as the orphan gid 545 — and
it sits on archives, not on downloads. This does not decide anything on its own, but the reasoning
recorded in D-24 should not be relied on as written.

---

## 6. UNEXPECTED — `google takeout/` is held open by a running service, right now

While this survey was being taken, `takeout-import.service` on LXC 100 was **active**:

```
Description=Google Takeout import into Immich (immich-go, 41 zips)
WorkingDirectory=/mnt/tank/downloads/google takeout
Restart=on-failure   RestartSec=60   StartLimitBurst=5   StartLimitIntervalSec=2h
Active: active (running) since Sat 2026-09-19 09:22:13 UTC
```

`immich-go` holds open file descriptors on **all 41 takeout zips** under
`/mnt/tank/downloads/google takeout` — which is one of this survey's rows, at the orphan
`3000:545`. The pool is at roughly **48% `full` I/O pressure** because of it.

Three consequences, all of them the operator's to weigh:

- **It is the reason the tool's own `enumerate` could not finish.** A whole-tree metadata walk
  behind a live 405 GB import was returning ~32 entries/second and would not have completed inside
  its one-hour budget. That run was **stopped deliberately** rather than left to time out; it was
  read-only, it chowned nothing, and its scratch file was removed (§9).
- **A chown of those zips mid-import is not obviously harmless.** The already-open descriptors do
  not care, and the tree is 0777 — but changing ownership of the input set of a live import that
  has already died once unexplained (2026-09-18 22:37, recorded in the unit file itself) is a
  change nobody needs to make today.
- The unit passes an **Immich API key on the `immich-go` command line**, so it is visible in `ps`
  to anything on the host. The value is deliberately not recorded here — this repo is public.

---

## 7. UNEXPECTED — two large subtrees that are not downloads at all

### `dropbox/` — 196,327 entries, 84% of the whole operation

`code/` 130,348 · `Archive/` 52,074 · `Documents/` 7,006 · `Projects/` 3,706 · `Shared/` 3,169,
plus about a dozen loose files. Uniformly `3000:568`. Its own directory mtime is **2026-01-03**,
and `code/` and `Archive/` both carry an mtime of `2000-01-01 00:00:00` — the sentinel an archive
extraction leaves when it does not preserve timestamps.

Nothing in this repo mounts it by name, and nothing has written to it in eight months. It is
nonetheless inside the `rw` bind of **nine** containers, because all of them mount
`/mnt/tank/downloads:/downloads:rw` wholesale (sabnzbd, sonarr, radarr, lidarr, readarr, bazarr,
prowlarr, qbittorrent, beets).

### `mac-music-archive/` — 23,874 entries at `0:0`

`Compilations/` 13,925 · `iTunes/` 6,322 · `NEW/` 1,154 · `2024-03/` 700 · `Various Artists/` 663 ·
`Library/` 521 · `MoreCompilations/` 447 · `2024-10/` 99 · `HitSquad/` 28 · `Shamrock/` 13.
Last written **2024-10-27**.

Its top directory is `100000:100000` (created from inside LXC 100) while everything beneath it is
`0:0` (written by real root on the host). **This is a music archive of about 24,000 entries that
no phase of this project has counted, measured or triaged**, sitting in the same dataset as the
backlog. It is not in scope for plan 05-10 beyond its ownership — but it should not pass without
being named.

---

## 8. `root:root` in the prior record and `0:0` here are NOT the same set

Plan 05-09's summary records *"The 115 volume directories remain `root:root`"*. That was the
container-side view. **On disk they are `100000:100000`** — container root through the idmap.

Real `0:0` in this tree means something else entirely: `mac-music-archive/` and `icloud/`. Anyone
reading the two records together needs this, or they will conclude the 115 directories are
hypervisor-root-owned and they are not.

Measured on all 115: **every `Vol NNN` folder has exactly one entry that is not `568:568` — the
directory itself.** The 4,746 mp3s inside them are `568:568`, because a rename preserves ownership.
That is why they are `self` rows below and not `recursive` ones.

---

## 9. What `apply` would do — the proposed row list

The tool rolls 222,376 foreign entries into **143 reviewable rows** by emitting the *shallowest*
subtree that is entirely foreign, and a single-entry row for anything else. The counts close
exactly — 143 rows covering **222,376** entries, which is every entry that is not `568:568`.

| # rows | mode | path | entries |
|---:|---|---|---:|
| 1 | recursive | `dropbox/` | 196,327 |
| 1 | recursive | `mac-music-archive/` | 23,874 |
| 1 | recursive | `media/` | 1,403 |
| 1 | recursive | `google takeout/` | 42 |
| 1 | recursive | `icloud/` | 1 |
| 1 | self (file) | `/.DS_Store` | 1 |
| 19 | recursive | the entirely-foreign folders under `complete/` (below) | 610 |
| 115 | self (dir) | the `Vol NNN` directories | 115 |
| 3 | self (file) | `.DS_Store` in `complete/`, `complete/nzb/`, `complete/nzb/unsorted/` | 3 |
| **143** | | | **222,376** |

### The 19 entirely-foreign folders under `complete/`, named

Thirteen Mastermix / DMC release folders at `100911:100911`, 27–53 entries each, every one
**100% foreign**:
`VA-DMC-Essential.Hits.233/234/235-WEB-2024-MST`,
`VA_-_Mastermix_-_Essential_Hits_2024_Pt.1` and `Pt.2`,
`…Essential_Hits_2025_Vol.1`, `…Essential_Hits_.Indie_Rock`, `…Essential_Hits_Summer`,
`…Essential_Hits_Hi-NRG`, `…Essential_Hits_(Pop_Soul)`, `…Essential.Hits.[Pop.Soul]`,
`VA-Mastermix.Essential.Hits.Pop.4.2005-2009-2025`,
`Various.Artists-70s.Essential.Hits-2024-Mp3.320kbps-PMEDIA-⭐️-xpost` (41).

Four `.covers` directories at `0:568`, each a directory plus one cover JPEG — **Mastermix issues
439, 441, 443 and 444**. PROJECT.md records cover scans as *more reliable than any autotagger*,
and 441/443/444 are precisely the issues it records MusicBrainz as lacking. They are 2 entries
each and the chown does not touch their content, but they are named here rather than folded into
a number.

One `BGD Super Clean PC` disk-image folder at `0:568` (3 entries), and one empty
`complete/nzb/tv/Tracker.2024.S03E11…` directory at `100911:100911`.

### What the chown itself is

`chown -Rh 568:568` for a `recursive` row, `chown -h 568:568` for a `self` row, run as **real root
on atlantis** by a detached runner, after every row has been re-validated against fresh state.
**No mode bit is touched** — impossible on this pool, everything is 0777 and stays that way.

---

## 10. State left behind by this survey

Nothing was chowned. Nothing was chmodded. Asserted, not assumed:

| check | result |
|---|---|
| any `chown` process on atlantis | none |
| `/var/lib/phase05-chown/rows.tsv` (the shipped row list) | never existed |
| `/var/lib/phase05-chown/runner.sh` | never existed |
| `/var/lib/phase05-chown/sentinel` | never existed |
| `tank/downloads@pre-phase5` (D-01's fence) | **present**, `Fri Sep 18 15:42 2026` |
| survey scratch on atlantis | removed |
| `/mnt/tank/media` read or written | **no** — 0 of 233,824 rows were under it |

One deviation is recorded in full in the plan's summary and repeated here because it left a
trace: a negative-control run of `apply` on the workstation had a **live** route to atlantis and
created the two zero-byte `@pre-phase5-chown` snapshots before refusing at a later guard. Both
were destroyed (dry-run first, exact names, never `-r`), `@pre-phase5` was confirmed intact, and
the tool was changed so that a **pre-existing** fresh baseline is now a refusal rather than a
silent reuse of a stale one. No chown ran at any point.

---

## 11. Open, for the operator

1. **Is `dropbox/` in scope?** It is 84% of the operation, it is not downloads, and nothing has
   written to it since January.
2. **Is `mac-music-archive/` in scope, and is it a music backlog nobody has triaged?** 23,874
   entries, and no phase of this project has looked at it.
3. **Should `google takeout/` wait for the import to finish?** It is open right now.
4. The binding row list is produced by `enumerate`, and it must be **fresh** when `apply` runs —
   so it is generated at apply time, against a quiet pool, not carried forward from this document.
