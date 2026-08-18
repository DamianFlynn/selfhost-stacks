---
phase: 01-safety-harness-and-freeze-the-writers
plan: 02
subsystem: recovery-fence
tags: [zfs, snapshot, sqlite, ffprobe, shell, safety, backup]
requires:
  - scripts/check-music-freeze.sh (01-01 — section 6 is this plan's verification)
  - ffmpeg/ffprobe toolchain on LXC 100 (01-01)
  - LXC 100 -> Proxmox host ssh trust (01-01)
provides:
  - scripts/freeze-music-apply.sh
  - tank/media/Music@pre-project
  - tank/downloads@pre-project
  - /mnt/fast/safety/music-pre-project/library-db/ (15 beets databases)
  - /mnt/fast/safety/music-pre-project/dj-mixes-ffprobe/ (764 full ffprobe JSON)
  - /mnt/fast/safety/music-pre-project/cover-scans/ (54 scans)
  - /mnt/fast/safety/music-pre-project/MANIFEST.txt
affects:
  - 01-03 (QUAL-01 NDJSON lands in the fence's tags/ — the only still-empty class)
  - 01-05 (mount narrowing — unblocked, the fence now exists)
  - 01-06 (Jellyfin/Lidarr freeze — unblocked)
  - 01-08 (runs the `ownership` subcommand shipped here)
  - Phase 5 (tank/downloads@pre-project is the only undo for its mv-based triage)
tech-stack:
  added: []
  patterns:
    - setup-mpe.sh apply-script convention (ALL-CAPS constants, ==> progress lines, check-report-skip)
    - pg-migrate.sh positional-subcommand contract with guard-then-SKIP
    - check-music-freeze.sh ZFS_HOST / ssh-delegation pattern, extended from read-only to snapshot
key-files:
  created:
    - scripts/freeze-music-apply.sh
  modified: []
decisions:
  - "sqlite3 .backup copies are verified with PRAGMA integrity_check, not sha256 equality — the plan required both and they are mutually unsatisfiable"
  - "cover-scan extension set includes bmp; 24 of the 54 live scans are BMP and the plan's jpg/jpeg/png/webp list would have archived 30 of 54"
  - "library-db discovery widened to *library* so the eleven arr-scripts .bak database states are fenced"
  - "dj-mixes-ffprobe mirrors the source tree rather than using a flattened slug — release folder plus track filename exceeds ext4's 255-byte filename limit here"
  - "the Mac Mini's non-interactive ssh PATH lacks head/basename/sqlite3; verification harnesses against it must use absolute tool paths and keep stderr, or they fail closed and report false corruption"
off_box:
  destination: "data@datas-mac-mini.pirate-clownfish.ts.net:~/archive/music-pre-project"
  cover_scans: 54
  library_db: 15
  verified: "54/54 sha256 + 15/15 integrity_check"
metrics:
  duration: ~25 minutes
  completed: 2026-08-18
  tasks: 3
  commits: 3
  files_created: 1
  host_artifacts: 833 files + 2 ZFS snapshots
---

# Phase 01 Plan 02: Recovery Fence Summary

The pre-project recovery fence is built, proven and replicated off-box: two ZFS snapshots taken
before anything in this phase writes, 15 beets databases, a 764-file full-`ffprobe` dump carrying
`TKEY` and `EnergyLevel`, and all 54 DJ cover scans — 303 MB on a path no running container mounts,
with the two irreplaceable classes now also on a second physical machine.

## What Was Built

| Task | Output | Commit |
|------|--------|--------|
| 1 | `scripts/freeze-music-apply.sh` — `fence` / `ownership` / `all`, mode 0755 | `8bf47c6`, widened in `025175c` |
| 2 | The fence populated on LXC 100, D-08 proven | host state, not tracked |
| 3 | Off-box copy to the Mac Mini (D-07), operator-executed at the blocking checkpoint | host state, not tracked |

## Snapshots (D-09) — both taken, route recorded

| Snapshot | Creation | USED | REFER |
|----------|----------|------|-------|
| `tank/media/Music@pre-project` | `2026-08-18 13:08` local / `12:08:01Z` | 0B | 33.9G |
| `tank/downloads@pre-project` | `2026-08-18 13:08` local / `12:08:02Z` | 0B | 2.00T |

**Route: `ssh:172.16.1.158`** — delegated to the Proxmox host `atlantis`. Confirmed at run time, not
assumed: `detect_zfs_route()` probes for a local `zfs` first and only then falls back. There is no
local `zfs` on LXC 100 and there cannot be (unprivileged container; the pool lives on the host).
This is the same `ZFS_HOST` pattern 01-01 established, extended from read-only `zfs list` to
`zfs snapshot`.

Both were created by this run — 01-01 correctly recorded that neither existed. `USED 0B` on both is
expected: a snapshot only consumes space as the live dataset diverges from it.

## Per-class fenced counts and bytes

| Class | Files | Bytes |
|-------|------:|------:|
| `library-db/` | 15 | 765,952 |
| `dj-mixes-ffprobe/` | 764 | 2,387,501 |
| `cover-scans/` | 54 | 311,564,108 |
| `tags/` | 0 | 0 |
| `audit/` (from 01-01, plus the db source map) | 3 | 121,254 |
| **Total** | **836** | **~303 MB** |

`tags/` is empty by design — it is where plan 01-03's QUAL-01 gzipped NDJSON lands. It is the one
remaining section-6 failure and is the correct state at the end of this plan.

Fence is `apps:apps 755`, all files 644, all directories 755. `/mnt/fast` has 20 GB free; D-06's
"well under 1 GB" holds at 303 MB.

## `TKEY` and `EnergyLevel` (SAFE-03) — present, but on a minority of files

| Key | Files carrying it | Of |
|-----|------------------:|---:|
| `TKEY` | **148** | 764 |
| `EnergyLevel` | **45** | 764 |

Both non-zero, so the dump is genuinely full `ffprobe` output and D-05 is satisfied — a reduced
field set would have returned zero for both. **But the honest reading is that only 19% of the
dj-mixes files carry a musical key and 6% carry an energy level.** SAFE-03 is framed as though these
tags are pervasive across the DJ collection; they are not. Whoever plans the DJ-content work in
Phase 5 should size it against 148 files, not 794.

## ffprobe failures

**Zero.** 764 of 764 audio files probed successfully on the first pass, 0 non-zero exits, 0 empty
outputs. No shortfall to explain.

## Section 6 (D-08) — verbatim

```
🧱 6. Fence presence and spot-check (SAFE-02/03/04, D-06/D-08/D-10)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ fence exists: /mnt/fast/safety/music-pre-project (568:568 755)
  ✅ snapshot present: tank/media/Music@pre-project (via ssh:172.16.1.158)
  ✅ snapshot present: tank/downloads@pre-project (via ssh:172.16.1.158)
  ✅ fence subdirectory non-empty: library-db/ (15 files)
  ✅ fence subdirectory non-empty: dj-mixes-ffprobe/ (764 files)
  ✅ fence subdirectory non-empty: cover-scans/ (54 files)
  ❌ fence subdirectory missing or empty: tags/
  ✅ no running container mounts any path under /mnt/fast/safety (D-08, proven not asserted)
```

**D-08 is proven, not asserted** — from the same 103-container / 165-mount enumeration WRIT-01 uses.

Harness `FAILURES total` dropped **12 → 7**. The five turned green are exactly the five this plan
owns. The library itself is untouched: ownership mismatches are still 2,543, dir-mode 87, file-mode
2,586, identical to the 01-01 baseline — confirming `fence` read `/mnt/tank/media/Music` and did not
write it.

## Spot-check (D-10)

**69 / 69 copies verified.** 54 cover scans by strict sha256 equality against source; 15 library
databases by `PRAGMA integrity_check` (see deviation 1). Zero mismatches. `/tmp` on LXC 100 holds
only pre-existing systemd/X11 sockets — nothing this task created.

## Off-box copy (D-07, task 3) — operator-executed at the blocking checkpoint

**Destination:** `data@datas-mac-mini.pirate-clownfish.ts.net:~/archive/music-pre-project`
Host confirmed by the user: `hostname` = `DATAs-Mac-mini.local`, `hw.model` = `Mac16,11`, 380 GiB
free. A second physical machine, as D-07 requires — not the Proxmox box, and not the MacBook Pro
workstation.

**Method.** `rsync` is absent on LXC 100 (deviation 6), and the Mac Mini and LXC 100 cannot reach
each other directly, so the copy was a `tar` stream over ssh piped through the workstation — the
only machine that can reach both ends. Nothing was staged on the workstation, and no `rsync -a`
appears anywhere:

```bash
ssh root@172.16.1.159 'tar -C /mnt/fast/safety/music-pre-project -cf - library-db cover-scans MANIFEST.txt' \
  | ssh data@<mini> 'mkdir -p ~/archive/music-pre-project && tar -C ~/archive/music-pre-project -xf -'
```

**Verified on the Mac Mini:**

| Class | Files | Check | Result |
|-------|------:|-------|--------|
| `cover-scans/` | 54 | sha256 against `MANIFEST.txt` | **pass=54 fail=0** |
| `library-db/` | 15 | `PRAGMA integrity_check` | **ok=15 bad=0** |

Total 312,330,060 bytes; 24 bmp + 30 jpg, matching the on-host formats exactly. Both counts equal
the on-host counts. `dj-mixes-ffprobe/` and `tags/` were deliberately **not** copied, per D-07 scope.

### The trap this cost two false results on — record it

**The Mac Mini's non-interactive shell has a restricted `PATH`.** `head`, `basename` and `sqlite3`
all resolve in an interactive shell but **not** over plain `ssh`. The first two verification passes
reported `library-db ok=0 bad=15` — which was the *harness* failing, not the databases. `sqlite3`
was silently not found and its stderr was discarded, so "command not found" was indistinguishable
from "integrity check failed". Only the third pass, using absolute `/usr/bin/...` tool paths, was
trustworthy.

This matters beyond this plan. **A verification harness that fails *closed* — reporting corruption
when the real fault is a missing tool — is arguably worse than one that fails open, because it
invites a destructive re-copy over data that was fine.** Anything later in this project that scripts
against the Mac Mini over ssh must use absolute tool paths and must not discard stderr from the tool
it is testing with. The same hazard applies to the `ssh root@172.16.1.158` zfs delegation in
`freeze-music-apply.sh`, which is why `detect_zfs_route()` probes and reports the route explicitly
rather than assuming a binary resolves.

## Idempotency proof (D-27)

`fence` was run four times. Runs 3 and 4 produce a **byte-identical** fence: `diff` over
`find -printf '%p %s'` across every file is empty, and every stage reports "exists - leaving
untouched". The only thing that changes between consecutive runs is derived state — `MANIFEST.txt`
(documented as rewritten) and `audit/library-db-sources.tsv`, whose per-file mechanism column flips
from `sqlite3-backup` to `pre-existing` once a copy is in place.

## Deviations from Plan

### 1. [Rule 1 - Bug] The plan's two integrity requirements are mutually unsatisfiable

- **Found during:** Task 1, writing section 6.
- **Issue:** Step 3 mandates `sqlite3 <src> ".backup <dst>"` for the databases. Step 6 mandates that
  "for **every** fenced artifact" the sha256 of source and copy be equal, exiting non-zero on any
  mismatch. `sqlite3 .backup` rewrites page layout; a byte-identical result is not guaranteed. Taken
  literally the script would have failed on every correctly-backed-up database — and the tempting
  "fix" is to drop back to `cp`, which reintroduces the torn-WAL risk T-01-08 exists to close.
- **Fix:** Per artifact, the applicable test is used and named in the output. Cover scans (plain byte
  copies) are held to strict sha256 equality. Databases are held to sha256 equality **first**, and
  fall back to `PRAGMA integrity_check` on the copy only when the digests differ — which is reported
  inline rather than silently. Both digests are written to `MANIFEST.txt`. All 15 databases took the
  `integrity_check` path; all returned `ok`.
- **Files modified:** `scripts/freeze-music-apply.sh`
- **Commit:** `8bf47c6`

### 2. [Rule 2 - Missing critical functionality] 24 of the 54 cover scans are BMP

- **Found during:** Task 1, pre-flight probe of `dj-mixes`.
- **Issue:** The plan specifies finding scans "by the extensions jpg, jpeg, png and webp". The live
  tree holds **30 `.jpg` and 24 `.bmp`** — and zero png/webp. That list archives 30 of 54 while the
  script reports success, and SAFE-04 would have been silently 56% complete.
- **Fix:** `IMAGE_EXT` covers jpg, jpeg, png, webp, **bmp, gif, tif, tiff**. Live count is now
  exactly 54, matching the census, and the script asserts against that number.
- **Files modified:** `scripts/freeze-music-apply.sh`
- **Commit:** `8bf47c6`

### 3. [Rule 2 - Missing critical functionality] Eleven beets database states were being dropped

- **Found during:** Task 2, reading the first run's output ("4 databases fenced").
- **Issue:** `sabnzbd/config/scripts/` holds eleven `library.blb-before-<migration>.bak` files left
  by arr-scripts — real pre-project beets database state, sitting on `/mnt/fast` with **no ZFS
  snapshot behind it**. An extension-anchored find dropped all eleven. SAFE-02's wording is "every
  beets `library.db`".
- **Fix:** Discovery widened to `-iname '*library*' -o -iname '*.blb'`. Verified before changing
  that this matches 15 files, 766 KB, all beets, nothing unrelated. Count went 4 → 15.
- **Files modified:** `scripts/freeze-music-apply.sh`
- **Commit:** `025175c`

### 4. [Rule 1 - Bug] `eval`-built find predicates would glob against the working directory

- **Found during:** Task 1, self-review before the first run.
- **Issue:** The first draft built the extension alternation as a string and ran it through `eval`.
  The patterns contain `*`, so `eval` expands them against the caller's cwd (`/mnt/fast/stacks`)
  before `find` ever sees them. On a host where the repo happened to contain a matching file this
  silently probes the wrong tree; more commonly it just matches nothing.
- **Fix:** `build_iname_expr()` populates a bash array passed to `find` unexpanded.
- **Commit:** `8bf47c6`

### 5. [Rule 1 - Bug] Slug reversal was lossy and would have weakened the spot-check

- **Found during:** Task 1, self-review.
- **Issue:** Copies are named by replacing `/` with `_` in the relative path. Section 6 originally
  reversed that with `tr '_' '/'` to find the source — but several of these paths already contain
  underscores (`library.blb-before-items-relative_path.bak`). Reversal produces a path that does not
  exist, the source-comparison branch is skipped, and the check silently degrades to
  `integrity_check` only. It would still have printed "verified 69/69".
- **Fix:** Section 3 writes an explicit source→copy→mechanism map to
  `audit/library-db-sources.tsv`; section 6 reads it. No reconstruction.
- **Commit:** `8bf47c6`

### 6. [Rule 3 - Blocking] `rsync` is not installed on LXC 100

- **Found during:** Task 1, pre-flight probe.
- **Issue:** The plan's threat register T-01-SC states "`zfs`, `sqlite3`, `sha256sum` and `rsync` are
  present on the estate". `rsync` is **absent** on LXC 100 — verified. This is the second factual
  error found in that register (01-01 found the `ffprobe`/`zfs` claims wrong).
- **Fix:** `fence_copy()` uses `rsync` with `RSYNC_FLAGS` when present and `cp --preserve=timestamps`
  otherwise. Every copy in this plan lands on `/mnt/fast` (ext4, the LXC's own disk), never on
  `tank`, so `cp` is correct and sufficient. `RSYNC_FLAGS="-rlt --no-p --no-o --no-g"` is defined and
  wired in anyway so a later edit redirecting the fence onto `tank` cannot silently land zero files.
- **Note:** no package was installed. Installing rsync would have been a package-manager action, out
  of scope for auto-fix.
- **Commit:** `8bf47c6`

## Findings That Contradict Phase Assumptions

1. **There are 764 audio files in `dj-mixes`, not 794** — 630 `.mp3` + 134 `.wav`. The 794 figure in
   PROJECT.md and repeated throughout this plan is `764 audio + 30 jpg`, i.e. **it counted the JPEG
   scans as if they were tracks and missed the 24 BMP scans entirely.** The arithmetic is exact
   (900 files total, minus 60 `.nfo`, 24 `.bmp`, 20 `.lrc`, 1 `.rtf`, 1 `.DS_Store` = 794). This is
   the root cause of deviation 2 and it means "794 dj-mixes files" should be retired as a figure.
2. **`dj-mixes` spans 84 release folders and 33 of them carry scans**, not the 27 the plan states.
   The 54-image total is correct; only the folder count was wrong.
3. **The soulbeet database does not exist.** `/mnt/fast/appdata/arrs/soulbeet/data/` is empty. The
   plan's acceptance criterion names "the manual beets database and the soulbeet database" as the
   expected two; the real set is four live databases — `arrs/beets/config/library.db`,
   `arrs/beets/config/musiclibrary.blb`, `arrs/sabnzbd/config/.config/beets/library.db` and
   `arrs/sabnzbd/config/scripts/library.blb`. **The two under `sabnzbd/` are a fourth tagging entry
   point nobody counted** — PROJECT.md says "this repo has two `library.db`". SABnzbd's
   post-processing beets has its own library, actively written (`library.blb` is dated 8 Aug 2026,
   the most recent of the four). Phase 4's retirement work should account for it.
4. **`TKEY` covers only 148 files and `EnergyLevel` only 45** — see above.
5. **A second `.DS_Store`**, plus a stray `.rtf`, sit in `dj-mixes`. 01-01 found one in the library
   root. A Mac has had write access to both trees.
6. **The Mac Mini's non-interactive ssh `PATH` does not carry `head`, `basename` or `sqlite3`** —
   see the off-box section. This produced two false "15 databases corrupt" results before being
   caught. Any later automation in this project that reaches that host over ssh must use absolute
   tool paths and keep the tool's stderr.

## Requirements Status

**SAFE-02, SAFE-03 and SAFE-04 are all satisfied.** SAFE-02 needed the off-box leg (D-07) and now
has it: both irreplaceable classes exist on `DATAs-Mac-mini`, verified. They are marked complete in
REQUIREMENTS.md here; 01-09's assert-mode re-run is the standing regression check, not the thing
that first closes them.

The one artifact class still outstanding inside the fence is `tags/`, filled by plan 01-03's
QUAL-01 NDJSON — a different requirement, not a gap in these three.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: trust-boundary | `scripts/freeze-music-apply.sh` | Extends the LXC 100 → Proxmox root ssh channel established in 01-01 from read-only `zfs list` to **`zfs snapshot`**, i.e. from observation to mutation of the pool. Bounded deliberately: the script issues only `zfs list`, `zfs get` and `zfs snapshot`, and contains no destroy or rollback subcommand — asserted by `grep -cE 'zfs (destroy\|rollback)'` returning 0. Undoing a snapshot stays a deliberate human command. |
| threat_flag: trust-boundary | off-box copy (host state) | A new machine boundary is now load-bearing: `data@datas-mac-mini.pirate-clownfish.ts.net` holds copies of every beets database and all 54 cover scans, reached over Tailscale. T-01-11 dispositioned this **accept** — the payload is music metadata and local file paths, no credentials — and the destination is the operator's own machine, recorded here as Phase 7 evidence. |

## Known Stubs

None. Every code path in `freeze-music-apply.sh` is implemented. The `ownership` subcommand is
complete and syntax-checked but **deliberately not executed** — plan 01-08 runs it, after the
writers are frozen, because a recursive `chown` while Lidarr still holds a rw mount with
`UMASK_SET: 002` simply re-drifts. Its precondition guard was exercised indirectly: the snapshot it
requires now exists.

## Self-Check: PASSED

- `scripts/freeze-music-apply.sh` — FOUND, mode 100755 in the index
- Commit `8bf47c6` — FOUND
- Commit `025175c` — FOUND, both pushed to `origin/main`; LXC 100 `/mnt/fast/stacks` is at `025175c`
- `tank/media/Music@pre-project` — FOUND via `root@172.16.1.158`
- `tank/downloads@pre-project` — FOUND via `root@172.16.1.158`
- `/mnt/fast/safety/music-pre-project/MANIFEST.txt` — FOUND, non-empty, 854 lines
- `library-db/` 15 files, `dj-mixes-ffprobe/` 764 files, `cover-scans/` 54 files — all FOUND
- Off-box `~/archive/music-pre-project` on `DATAs-Mac-mini` — FOUND, 54 + 15 files, 54/54 sha256
  and 15/15 `integrity_check` verified by the operator (third pass, absolute tool paths)
