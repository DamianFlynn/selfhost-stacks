---
phase: 01-safety-harness-and-freeze-the-writers
plan: 01
subsystem: safety-harness
tags: [audit, shell, docker, zfs, ownership, sidecars, read-only]
requires: []
provides:
  - scripts/check-music-freeze.sh
  - /mnt/fast/safety/music-pre-project/audit/baseline-20260818.txt
  - /mnt/fast/safety/music-pre-project/audit/sidecars-baseline.txt
  - ffmpeg/ffprobe toolchain on LXC 100
  - verified /mnt/tank/media subtree names (D-19 precondition)
affects:
  - 01-02 (fence run — its verification is section 6 of this script)
  - 01-03 (snapshot tool — depends on the ffmpeg toolchain proven here)
  - 01-05 (mount narrowing — hard-codes sources from section 3 only)
  - 01-06 (SAFE-05 one-hour test — diffs against sidecars-baseline.txt)
  - 01-08 (chown/chmod run — sized by section 4)
  - 01-09 (phase closure — re-runs this script in assert mode)
tech-stack:
  added:
    - ffmpeg 7.1.5-0+deb13u1 (LXC 100, Debian 13 trixie, apt)
  patterns:
    - check-renovate.sh audit skeleton (colours, numbered sections, summary block)
    - setup-mpe.sh host-resident script convention (ALL-CAPS constants, strict mode)
    - fd-3 output split so a machine-readable list and a human report can share one script
key-files:
  created:
    - scripts/check-music-freeze.sh
  modified: []
decisions:
  - "exit 1 on any failed assertion; --baseline always exits 0 — the estate had no convention and its silence hid a six-week outage"
  - "zfs queries delegated over ssh to the Proxmox host; LXC 100 is unprivileged and cannot have zfs"
  - "WRIT-04 normalisation is ~2x larger than D-13 assumed: 2,543 of 2,673 entries, and every mode is 0777"
metrics:
  duration: ~20 minutes
  completed: 2026-08-18
  tasks: 3
  commits: 2
  files_created: 1
  host_artifacts: 2
---

# Phase 01 Plan 01: Safety Harness Audit Summary

Read-only harness audit (`scripts/check-music-freeze.sh`, 8 sections, tagger/consumer writer
classification plus a declared-YAML false-pass guard) built and run once against LXC 100, recording
a 12-failure before-state — and surfacing that the WRIT-04 normalisation is roughly twice the size
the phase context assumed.

## What Was Built

| Task | Output | Commit |
|------|--------|--------|
| 1 | `ffmpeg` + `ffprobe` installed on LXC 100; both D-01 mechanisms proven against a real file | host state, not tracked |
| 2 | `scripts/check-music-freeze.sh` — 8 sections, mode 0755, read-only by contract | `33fe301`, fix `e230d90` |
| 3 | `baseline-20260818.txt` + `sidecars-baseline.txt` under the fence | host state, not tracked |

Tasks 1 and 3 produce host state only (`<files>` in the plan is explicitly "not tracked in git"),
so they carry no code commit. Task 2's two commits are the only repo changes in this plan.

## Task 1 — Toolchain

`ffprobe` and `ffmpeg` were confirmed **absent** on LXC 100 before this plan, exactly as the plan
stated and contrary to plan 01-02's threat register T-01-SC. Installed via
`apt-get install -y ffmpeg` on Debian 13 (trixie). Nothing else was installed.

| Tool | Version | Path |
|------|---------|------|
| ffmpeg | `7.1.5-0+deb13u1` | `/usr/bin/ffmpeg` |
| ffprobe | `7.1.5-0+deb13u1` | `/usr/bin/ffprobe` |
| jq | `jq-1.7` (pre-existing) | `/usr/bin/jq` |
| gzip | `1.13` (pre-existing) | `/usr/bin/gzip` |
| sha256sum | `9.7` (GNU coreutils, pre-existing) | `/usr/bin/sha256sum` |

Both mechanisms proven against a real library file
(`/mnt/tank/media/Music/Garth Brooks/The Ultimate Hits (2007)/CD 02-06 Garth Brooks - Beer Run.flac`):

- `ffprobe -v quiet -print_format json -show_format -show_streams` → validated with `jq -e .`, exit 0.
- `ffmpeg -i FILE -map 0:a -c copy -f md5 -` → `5745e98248dfdf76dcc1c94209e44156`, 32 hex chars.

**No Python was installed.** `grep -c python /var/log/apt/history.log` returns 0 across the whole
apt history; `pip3` is still absent. The transaction pulled only ffmpeg's media/graphics deps
(mesa, libav*, libsdl2, gtk3).

## Section 3 — `/mnt/tank/media` entry names (verbatim, D-19 precondition)

```
Books
Movies
Music
Photos
TV
```

All five are directories, and all five are **separate ZFS datasets** (`tank/media/Books`,
`.../Movies`, `.../Music`, `.../Photos`, `.../TV`), each mounted `casesensitive` while the parent
`tank/media` is `caseinsensitive`.

D-19's assumed names `Movies`, `TV`, `Books` are all **correct** — no typo risk realised. Plan 01-05
must draw narrowed mount sources from this list and nothing else.

## Section 4 — Ownership census (WRIT-04 before-state, verbatim)

Library root itself: `568:65534 777 /mnt/tank/media/Music` — **it is not one of the 13 folders and
must be included in the normalisation.**

| uid:gid | mode | Folder |
|---------|------|--------|
| `65534:65534` | 777 | `.DS_Store` — **stray top-level file, not an artist folder** |
| `568:65534` | 777 | `BLACKPINK` |
| `568:65534` | 777 | `Benson Boone` |
| `568:568` | 777 | `Chris Norman` |
| `568:65534` | 777 | `Def Leppard` |
| `568:65534` | 777 | `Ed Sheeran` |
| `568:65534` | 777 | `Garth Brooks` |
| `568:65534` | 777 | `Hawthorne Heights` |
| `568:65534` | 777 | `Katy Perry` |
| `568:65534` | 777 | `Lady Gaga` |
| `568:65534` | 777 | `P!nk` |
| `568:65534` | 777 | `Sabrina Carpenter` |
| `568:65534` | 777 | `Taylor Swift` |
| `568:65534` | 777 | `Vengaboys` |

PROJECT.md's claim — 12 of 13 at `568:65534`, one at `568:568` — is **confirmed exactly**, and
`Chris Norman` is the correct one.

### But the tree beneath is materially worse than PROJECT.md records

2,673 entries under the library, five distinct owners:

| uid:gid | Count | Likely writer |
|---------|-------|---------------|
| `65534:65534` (nobody:nogroup) | 1,187 | unmapped-gid writer, and an SMB/AFP client |
| `568:65534` | 1,170 | the drift PROJECT.md describes |
| `0:0` (root) | 155 | root-run process |
| `568:568` (apps:apps, the target) | 130 | correct |
| `911:911` | 31 | LinuxServer.io `abc` user inside an arr/Jellyfin container — **no such account exists on the host** |

**Every single file and directory is mode 0777** — 87 directories and 2,586 files, no exceptions.
Nothing in the library currently matches D-12's `0755`/`0644`.

| Assertion | Mismatches | Target |
|-----------|-----------|--------|
| ownership `568:568` | **2,543** of 2,673 | 0 |
| directory mode `755` | **87** of 87 | 0 |
| file mode `644` | **2,586** of 2,586 | 0 |

**This resizes D-13.** The context says "chown/chmod across all 13 artist folders and 1,244 files".
The real job is 2,673 entries, of which 2,543 are wrong, plus a `chmod` pass touching 100% of the
tree. PROJECT.md's 1,244 figure is correct **for audio files only** (912 `.flac` + 332 `.mp3`,
34 GB confirmed); the tree carries a further 1,342 non-audio files.

## Section 5 — Sidecar inventory (SAFE-05 / D-18 baseline)

| Extension | Count |
|-----------|-------|
| `.lrc` | 944 |
| `.nfo` | 91 |
| `.jpg` | 88 |
| **Total** | **1,123** |

Recorded as 1,123 sorted paths in `sidecars-baseline.txt` (108 KB, verified free of report
contamination). This is the exact file plan 01-06's one-hour watched-folder test diffs against.

**Gap flagged for plan 01-06:** the library also holds **43 `.png`** and **175 `.txt`** files that
D-18's `.nfo`/`.jpg`/`.lrc` definition does not cover. Jellyfin writes `.png` for logo/clearart/disc
artwork, so a new `.png` during the one-hour test would be **invisible** to this baseline. 01-06
should either widen the extension set or state explicitly why `.png` is excluded.

## Section 1 — Running-container rw holders (WRIT-01 before-state)

103 running containers, 165 mounts enumerated.

| Class | Count | Containers |
|-------|-------|------------|
| **tagger-class** | 2 | `wrtag` (`/mnt/tank/media/Music:/music/library:rw`), `lidarr` (`/mnt/tank/media:/media:rw`) |
| **consumer-class** | 1 | `jellyfin` (`/mnt/tank/media:/media:rw`) — documented exception, D-21 |
| **unclassified** | 6 | `sonarr`, `radarr`, `readarr`, `prowlarr`, `bazarr` (all `/mnt/tank/media:/media:rw`), `janitorr` (`/mnt/tank/media:/data:rw`) |

**wrtag is running right now** and holds a direct rw mount on the library — it is not idle.

## Section 2 — Declared rw mounts in stack YAML (the false-pass class)

12 declared `/mnt/tank/media` volume lines; **10 reach the library rw or unsuffixed** outside
`media/jellyfin.yaml`:

| File:line | Mapping | Suffix |
|-----------|---------|--------|
| `music/wrtag.yaml:40` | `/mnt/tank/media/Music:/music/library` | **NO-SUFFIX** |
| `arrs/beets/beets.yaml:19` | `/mnt/tank/media:/media:rw` | rw |
| `arrs/soulbeet.yaml:37` | `/mnt/tank/media/Music:/music` | **NO-SUFFIX** |
| `arrs/lidarr.yaml:43` | `/mnt/tank/media:/media:rw` | rw |
| `arrs/sonarr.yaml:44` | `/mnt/tank/media:/media:rw` | rw |
| `arrs/prowlarr.yaml:42` | `/mnt/tank/media:/media:rw` | rw |
| `arrs/bazarr.yaml:39` | `/mnt/tank/media:/media:rw` | rw |
| `arrs/janitorr.yaml:43` | `/mnt/tank/media:/data:rw` | rw |
| `arrs/radarr.yaml:43` | `/mnt/tank/media:/media:rw` | rw |
| `arrs/readarr.yaml:43` | `/mnt/tank/media:/media:rw` | rw |

Excluded by design: `media/jellyfin.yaml:93` (`NO-SUFFIX`, D-21 carve-out) and `media/seerr.yaml:42`
(the only already-correct `:ro`).

### The false pass the plan predicted — confirmed

CONTEXT.md's eleven-container table minus section 1's nine = **`beets` and `soulbeet`**, exactly as
predicted. Both are commented out of `arrs/compose.yaml` (lines 39 and 36 — confirmed by eye), so no
running container exists for either, while `beets/beets.yaml:19` still declares `:rw` and
`soulbeet.yaml:37` declares an unsuffixed (therefore rw) path straight at `/mnt/tank/media/Music`.
**A running-container-only audit would have scored these two green.** Section 2 exists for exactly
this and catches both.

Also worth noting: `wrtag.yaml:40` and `soulbeet.yaml:37` carry **no `:ro`/`:rw` suffix at all** —
the same latent defect as `jellyfin.yaml:93`, which CONTEXT.md flags as "rw by accident".

## Section 6 — Fence before-state

| Check | Result |
|-------|--------|
| `$FENCE` exists | ✅ created this plan, `568:568 755` |
| `tank/media/Music@pre-project` | ❌ missing (plan 01-02 creates it) |
| `tank/downloads@pre-project` | ❌ missing (plan 01-02 creates it) |
| `library-db/`, `dj-mixes-ffprobe/`, `cover-scans/`, `tags/` | ❌ all missing (plan 01-02) |
| No running container mounts `/mnt/fast/safety` | ✅ proven from section 1's enumeration (D-08) |

## Baseline totals

`FAILURES total: 12` in `--baseline` mode, exit 0. The same script without `--baseline` exits **1**,
confirming the assertion mode works. Every one of the 12 is a red line a later plan turns green.

## Deviations from Plan

### 1. [Rule 3 - Blocking] `zfs` does not exist on LXC 100 and cannot

- **Found during:** Task 2 (pre-flight probe before writing the script)
- **Issue:** The plan's section 0 says to assert `zfs` is resolvable on LXC 100, and its threat
  register T-01-SC asserts `zfs` "is already present on LXC 100". Both are false. LXC 100 is an
  **unprivileged container** — the tank datasets are bind-mounted into it (visible in `/proc/mounts`
  as `zfs` filesystems) but the `zfs` command is not installed and could not manage the pool if it
  were. The pool lives on the Proxmox host `atlantis` (172.16.1.158). Left unhandled, section 6's
  SAFE-02/SAFE-04 snapshot assertions would be permanently unverifiable and plan 01-02 would have no
  way to prove its snapshots exist.
- **Fix:** Added a `ZFS_HOST="172.16.1.158"` constant and a `zfs_query()` helper that uses local
  `zfs` when present and otherwise delegates over ssh. Section 0 reports which route was taken
  (`local` / `ssh:172.16.1.158` / `unavailable`) so this can never silently degrade. Queries are
  read-only (`zfs list`); the script still contains no `zfs snapshot`/`rollback`/`destroy`.
- **Secondary fix:** LXC 100 could not ssh to atlantis — the key was already authorised but
  atlantis's host key was not in `known_hosts`. Rather than trust-on-first-use, atlantis's own
  `/etc/ssh/ssh_host_{ed25519,rsa}_key.pub` fingerprints were read directly and compared to what
  `ssh-keyscan` saw from LXC 100. Both matched exactly
  (`SHA256:2vX1Pzn4GZED1c79GfvpXMNWsjINkcepgJ8OfVGTGZY`,
  `SHA256:tR5sZGPpcy4xU8avXywzn5ucsRjPiK275tranAq9XUM`) before the entry was written. The
  keyscan staging file was written to `/mnt/fast`, never `/tmp`, and unlinked afterwards.
- **Files modified:** `scripts/check-music-freeze.sh`; `/root/.ssh/known_hosts` on LXC 100
- **Commit:** `33fe301`

### 2. [Rule 1 - Bug] Census mislabelled a stray file as an artist folder

- **Found during:** Task 3 (reading the first baseline output)
- **Issue:** Section 4 enumerated the immediate children of the library and reported "14 artist
  folders". 13 are directories; the 14th is a stray `.DS_Store` owned `65534:65534` — a Mac wrote
  into the library over a share. Reporting it as an artist folder would have put a wrong count into
  the durable WRIT-04 before-state and made 01-08's chown scope look larger than it is.
- **Fix:** Directories and stray top-level files are now counted and labelled separately, and the
  stray is annotated inline in the listing.
- **Files modified:** `scripts/check-music-freeze.sh`
- **Commit:** `e230d90` — both artifacts were then regenerated from the corrected script

### 3. [Design decision] `--sidecars` routes the report to stderr

The plan requires the sorted sidecar list to be redirectable "without the surrounding report".
Implemented by `exec 3>&1 1>&2` under `--sidecars`: the path list goes to fd 3 (the caller's
stdout), the human report to stderr. Verified — `sidecars-baseline.txt` is exactly 1,123 lines with
zero report contamination.

## Findings That Contradict Phase Assumptions

1. **WRIT-04 is ~2x its assumed size**, and mode normalisation is 100% of the tree (all 0777), not
   the partial fix D-12 implies. Plan 01-08 should be re-sized.
2. **Five distinct owners exist below the top level**, including 155 root-owned and 31 `911:911`
   entries. `911` is the LinuxServer.io container user and has no host account — worth naming in
   `beets.md` under D-30 alongside the `568:545` correction, because it identifies *which* container
   was writing.
3. **A `.DS_Store` in the library root** proves a Mac has had write access over a share. Not covered
   by any current requirement.
4. **43 `.png` + 175 `.txt` sit outside D-18's sidecar definition** — a real blind spot for the
   SAFE-05 one-hour test.
5. **`wrtag` is actively running**, not dormant. WRIT-02 is more urgent than "delete the mount".

## Requirements Status

`WRIT-01`, `WRIT-04` and `SAFE-05` are **deliberately NOT marked complete.** This plan builds the
instrument that measures them and records the before-state; the baseline shows all three currently
failing (2 tagger-class writers, 2,543 ownership mismatches, 1,123 uninventoried-until-now sidecars
with Jellyfin still writing). They are satisfied by plans 01-05, 01-06 and 01-08 and closed by
01-09's assert-mode re-run.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: trust-boundary | `/root/.ssh/known_hosts` on LXC 100 | LXC 100 → Proxmox host root ssh is now usable non-interactively. The key was already authorised; only the host key was missing. Fingerprints were verified against atlantis's own public keys before writing. Scope of use in this repo is read-only `zfs list`. Worth recording in `beets.md` (D-30) so a future reader knows the audit depends on it. |

## Known Stubs

None. Every section of the script is implemented and produced real output against the live host.

## Self-Check: PASSED

- `scripts/check-music-freeze.sh` — FOUND (mode 100755 in the index)
- `/mnt/fast/safety/music-pre-project/audit/baseline-20260818.txt` — FOUND on LXC 100 (10,025 bytes)
- `/mnt/fast/safety/music-pre-project/audit/sidecars-baseline.txt` — FOUND on LXC 100 (108,044 bytes, 1,123 lines)
- Commit `33fe301` — FOUND
- Commit `e230d90` — FOUND
- Both commits pushed to `origin/main`; LXC 100 at `/mnt/fast/stacks` is at `e230d90`
