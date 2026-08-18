---
phase: 01-safety-harness-and-freeze-the-writers
plan: 08
subsystem: ownership-normalisation
status: COMPLETE — WRIT-04 ownership half MET (2,674/2,674 at 568:568); mode half scoped out
tags: [WRIT-04, chown, zfs, nfsv4-acl, lxc-idmap, unprivileged-container, ownership]
requires:
  - scripts/check-music-freeze.sh (01-01)
  - scripts/freeze-music-apply.sh ownership subcommand (01-02)
  - tank/media/Music@pre-project (01-02, the rollback)
  - QUAL-01 tag capture, 9,736 records (01-04)
  - tagger-class rw holders == 0 (01-05 + 01-06)
provides:
  - "/mnt/tank/media/Music normalised to 568:568 across all 2,674 entries, library root included"
  - "zfs snapshot tank/media/Music@pre-chown (this plan's verification baseline)"
  - "zfs snapshot tank/downloads@pre-chown (untouched-proof instrument)"
  - /mnt/fast/safety/music-pre-project/audit/ownership-after-20260818.txt
  - /mnt/fast/safety/music-pre-project/audit/preflight-01-08.txt
  - /mnt/fast/safety/music-pre-project/audit/postflight-01-08.txt
  - "PROVEN: chown is impossible from LXC 100 — the normalisation must run on the Proxmox host"
  - "PROVEN: the 01-01 ownership census recorded the CONTAINER's view, not the disk"
  - "EVIDENCE for D-11: Music was the only media subtree on gid 545; Movies was already 568:568"
affects:
  - "01-09 (phase closure — must not fold a permanently-red mode assertion into quick-health-check.sh)"
  - "01-09 (beets.md record — D-14's 568:568 correction now has positive evidence, not just convention)"
  - "Phase 2 (NFS export inherits a 0777 tree; anonuid/anongid = 568:568 is now true on disk)"
tech-stack:
  added: []
  patterns:
    - "delegate the privileged filesystem operation to the pool host over the route detect_zfs_route() already establishes"
    - "scope guard asserting the LIBRARY literal before a recursive chown as real root"
    - "skip-with-explanation instead of `|| true` for a deliberately-unrunnable pass"
key-files:
  created:
    - .planning/phases/01-safety-harness-and-freeze-the-writers/01-08-SUMMARY.md
  modified:
    - scripts/freeze-music-apply.sh
    - scripts/check-music-freeze.sh
decisions:
  - "the chown runs on the Proxmox host — LXC 100 is unprivileged and physically cannot chown the library's unmapped uids/gids; this is a DIFFERENT mechanism from aclmode=restricted with the same errno"
  - "the mode pass is skipped with a printed explanation rather than run, removed, or swallowed with || true — it would have aborted the run under set -euo pipefail, possibly midway"
  - "both censuses widened to include the library root; it was excluded by -mindepth 1 and is itself mis-owned, so the assertion could have read 0 while the mounted directory was wrong"
  - "the .DS_Store was chowned along with everything else, not deleted"
  - "zfs set aclmode=passthrough rejected — under passthrough a chmod rewrites the ACL on all 2,674 entries"
metrics:
  duration: ~35 minutes
  completed: 2026-08-18
  tasks: 3
  commits: 2
  files_modified: 2
  host_artifacts: 5
---

# Phase 01 Plan 08: WRIT-04 Ownership Normalisation Summary

**STATUS: COMPLETE.** All 2,674 library entries — the root included — are now `568:568` on disk,
verified from the Proxmox host and cross-checked with `zfs diff`. The mode half of WRIT-04 remains
impossible and is recorded as such.

> **The plan could not have worked as written, and not for the reason anyone expected.**
>
> The briefing, the plan, `01-CONTEXT.md` and `01-06-SUMMARY.md` all state that `chown` works
> normally and only `chmod` is blocked. **`chown` failed on all 37 entries of the pilot folder**,
> as root, on LXC 100. The cause is not `aclmode=restricted`. It is that **LXC 100 is an
> unprivileged container and the library's real owners are outside its idmap** — a different
> mechanism producing the same `Operation not permitted`, which is precisely why it was
> mistaken for one.
>
> That finding cascaded: **the 01-01 ownership census — the measured before-state that D-11,
> D-13 and D-14 all rest on — recorded the container's distorted view, not what is on disk.**

---

## Task 1 — Pre-flight audit: the gate PASSED

`scripts/check-music-freeze.sh` in **default asserting mode**, exit **1**, **3 failures, all in
section 4** — exactly the required precondition.

| Section | Result |
|---|---|
| 0 Toolchain | **PASS** — ffprobe/ffmpeg 7.1.5, jq, gzip, sha256sum; zfs via `ssh:172.16.1.158` |
| 1 Running rw holders | **PASS** — tagger-class **0**, unclassified **0**, consumer-class **1** (jellyfin, D-21) |
| 2 Declared YAML rw | **PASS** — declared rw reaching Music **0**; `wrtag.yaml` and `soulbeet.yaml` now `:ro` or gone |
| 3 media layout | **PASS** — Books, Movies, Music, Photos, TV |
| **4 Ownership census** | **FAIL ×3** — the work of this plan |
| 5 Sidecars | informational — 1,341 widened / 1,123 narrow |
| 6 Fence | **PASS** — both snapshots present, all four subdirectories non-empty |

`zfs list -t snapshot tank/media/Music@pre-project` confirmed **separately and by eye**: exit 0,
created `Tue Aug 18 13:08 2026`.

### The section 4 before-census, verbatim (container view)

Library root: `568:65534 777 /mnt/tank/media/Music` — **not one of the 13 artist folders.**

| uid:gid | mode | Folder |
|---|---|---|
| `65534:65534` | 777 | `.DS_Store` — stray top-level file |
| `568:65534` | 777 | BLACKPINK, Benson Boone, Def Leppard, Ed Sheeran, Garth Brooks, Hawthorne Heights, Katy Perry, Lady Gaga, P!nk, Sabrina Carpenter, Taylor Swift, Vengaboys |
| `568:568` | 777 | Chris Norman |

| Mismatch | Before |
|---|---|
| ownership ≠ `568:568` | **2,543** of 2,673 (`-mindepth 1`) — **2,544** of 2,674 including the root |
| directories ≠ `755` | **87** of 87 (**88** of 88 with the root) |
| files ≠ `644` | **2,586** of 2,586 |

**Divergence from the 01-01 census: none.** Twelve folders at `568:65534`, one (`Chris Norman`) at
`568:568`, 2,673 sub-entries, 2,543 ownership mismatches, all modes 0777 — identical to 01-01 and
to the post-01-05/01-06 re-measure. Nothing wrote to the library during the phase.

**No setgid directory exists.** The mode census returns exactly two classes, `777 d` and `777 f`,
so the `2755`-counted-as-mismatch surprise the plan asked about does not arise here.

---

## Task 2 — The pilot, run twice, because the first run disproved the plan's premise

Folder: **`Benson Boone`** — smallest of the twelve at `568:65534` (37 entries: 2 dirs, 35 files),
deliberately not `Chris Norman`, which would have exercised only the no-op path.

### Run 1, on LXC 100 as the plan specifies — TOTAL FAILURE

```
chown: changing ownership of '/mnt/tank/media/Music/Benson Boone/folder.jpg': Operation not permitted
chown: changing ownership of '.../Fireworks & Rollerblades (2024)': Operation not permitted
                                                            ... × 37, chown exit=1
chmod: changing permissions of '/mnt/tank/media/Music/Benson Boone': Operation not permitted
```

| Measure | Result |
|---|---|
| entries now `568:568` | **0 / 37** |
| directories at `755` | **0 / 2** |
| files at `644` | **0 / 35** |
| `chmod` invocations returning non-zero | **37 / 37** |
| **`chown` invocations returning non-zero** | **37 / 37** ← *not in anyone's model* |

`zfs diff` against `@pre-chown` after this run: **0 lines.** The failure was total and clean —
nothing was half-changed.

### Why — and it is not `aclmode`

The Proxmox host and LXC 100 report **different ownership for the same files**:

| Path | LXC 100 sees | Actually on disk |
|---|---|---|
| `/mnt/tank/media/Music` | `568:65534` | `568:545` |
| `Benson Boone` | `568:65534` | `568:545` |
| `Benson Boone/folder.jpg` | `65534:65534` | `0:545` |

`/etc/pve/lxc/100.conf` is `unprivileged: 1` with a **sparse idmap**: `u 0 100000 568`,
`u 568 568 1`, `g 111 100111 457`, `g 568 568 1`, … Host gid **545** and host uid **0** and **3000**
fall in no mapped output range, so they surface as **65534**. A process in a user namespace cannot
`chown` a file whose current uid or gid it cannot name — `CAP_CHOWN` in a nested namespace does not
reach unmapped ids. Hence `EPERM` on every entry.

The reconciliation is exact — the container view collapses six real owners into five:

| On disk (Proxmox host) | Count | LXC 100 reports |
|---|---|---|
| `0:545` | 1,186 | `65534:65534` |
| `3000:545` | 1 | `65534:65534` ← **a different uid, hidden by the collapse** |
| `568:545` | 1,171 | `568:65534` |
| `100000:100000` | 155 | `0:0` (root *inside* the container) |
| `100911:100911` | 31 | `911:911` |
| `568:568` | 130 | `568:568` |
| **2,674** | | |

1,186 + 1 = the 1,187 the container reported as `65534:65534`. Every figure ties out.

**This means the 01-01 census — the basis for D-11, D-13 and D-14 — measured the container's view.**
It undercounts distinct owners, and `01-01-SUMMARY.md`'s attribution of `65534:65534` to "an
SMB/AFP client" and `0:0` to "a root-run process" are both wrong: those are `0:545` (root on the
*host*) and container-root respectively.

### Capability probe on the Proxmox host — scratch dir on `tank/media`, outside the Music dataset

```
chown 568:568 -> OK      chown 0:545 -> OK
chmod 644     -> chmod: changing permissions of '...': Operation not permitted
```

So on the pool host **`chown` works and `chmod` still does not.** D-12's scope-out is confirmed a
third time, independently, and now on the host rather than only inside the container.

### Run 2, the same folder from the Proxmox host — CONVERGED

| Measure | Result |
|---|---|
| entries now `568:568` | **37 / 37** (`chown` exit 0, no errors) |
| directories at `755` | **0 / 2** |
| files at `644` | **0 / 35** |
| `chmod` invocations returning non-zero | **37 / 37**, first error verbatim: `chmod: changing permissions of '/mnt/tank/media/Music/Benson Boone': Operation not permitted` |

`zfs diff` against `@pre-chown`: **exactly 37 `M` lines**, all inside `Benson Boone`, no `+`, `-` or
`R`. And LXC 100 now reads the folder as `568:568` with 0 mismatches — because gid/uid 568 is the
one identity mapping in the idmap, **normalising to `568:568` makes the container and host views
agree**, which they did not before.

**Answer to the plan's yes/no question — `aclmode=restricted` blocks mode normalisation on this
dataset: YES.** And a second, unasked one — the unprivileged idmap blocks *ownership* normalisation
from LXC 100: **also YES.**

---

## Task 3 — The sweep

### What I changed in the ownership subcommand before running it (commit `cecf212`)

The briefing required the scoped-out mode pass be handled deliberately, because
`freeze-music-apply.sh` runs under `set -euo pipefail` and the `chmod` pass would have aborted the
run, possibly midway. Three changes:

1. **The mode pass is skipped with a printed explanation** — not deleted, not `|| true`. It prints
   `SKIPPED BY DECISION` plus two `WARN` lines, and carries a comment block naming the cause
   (`acltype=nfsv4` + `aclmode=restricted`), the three independent reproductions, the Phase 2
   consequence, and an explicit **do not "fix" this** on `zfs set aclmode=passthrough`. The success
   test now asserts `a_own` only — asserting on the mode counts would make the subcommand
   permanently red for a reason already decided.
2. **The chown delegates to the pool host**, reusing the route `detect_zfs_route()` already
   establishes, so running the script *on* the host executes locally and nothing is ssh'd. The
   remote command is `test -d '<lib>' && chown -R …` so a bind mount present here but absent there
   cannot make it a silent no-op.
3. **A scope guard on `LIBRARY`** (T-01-46). The chown now runs as *real* root on the hypervisor
   rather than a namespaced container root, so a wrong constant is no longer a contained mistake.
   It refuses unless `LIBRARY` is exactly `/mnt/tank/media/Music`.

Plus, in **both** scripts, the census now **includes the library root** — see Deviation 3.

### The run

Snapshot guard **reported present, not skipped**: `precondition met: tank/media/Music@pre-project
exists`. Route `ssh:172.16.1.158`. Exit **0**.

| Measure | Before | After |
|---|---|---|
| entries | 2,674 | 2,674 |
| not `568:568` | **2,507** | **0** |
| dirs not `755` | 88 | **88** *(mode pass scoped out)* |
| files not `644` | 2,586 | **2,586** *(mode pass scoped out)* |

*2,507 rather than 2,544 because the Task 2 pilot had already converted `Benson Boone`'s 37.*

### Verification — `zfs diff`, the only instrument that can see this

`tank/media/Music@pre-chown` was taken at **epoch 1787088578 = 2026-08-18T21:29:38Z**, and
deliberately **before the pilot** rather than only before the sweep, so one diff covers the whole
normalisation. It read **0 lines** at creation, confirming the instrument was zeroed.

```
zfs diff tank/media/Music@pre-chown tank/media/Music
  total lines: 2674
  by type:     2674 M      (0 added, 0 removed, 0 renamed)
```

**2,674 `M` lines against 2,674 entries** — every entry's metadata changed, and nothing was
created, deleted or renamed. As 01-06 predicted, the mtime-keyed stat manifest is blind to this;
a zero there would have been expected, not corroboration, and is not offered as any.

### Ownership, read from both sides

| | Proxmox host (ground truth) | LXC 100 |
|---|---|---|
| distinct owners | **1 — `568:568` ×2,674** | artist folders: **1** distinct, `568:568` |
| `find ! -user 568 -o ! -group 568 \| wc -l` | **0** | **0** |
| library root | `568:568` | `568:568 777` |
| `.DS_Store` | `568:568` | `568:568 777` |
| modes | 88 dirs 0777, 2,586 files 0777 | unchanged |

### Fence and downloads — untouched

| Check | Result |
|---|---|
| `/mnt/fast/safety` — all fenced artifacts vs `MANIFEST.txt` sha256 | **839 records checked, 0 mismatched** |
| fence entry count | 968 → **969**, delta is **exactly** `audit/ownership-after-20260818.txt`, this plan's required artifact |
| `zfs diff tank/downloads@pre-chown tank/downloads` | **0 lines** |
| section 6 fence assertions in the post-run audit | **0 failed** |

A `tank/downloads@pre-chown` snapshot was taken before the sweep specifically so "untouched" could
be *measured* rather than asserted from a shallow census.

### Jellyfin read-back

| Check | Result |
|---|---|
| container | `Up 13 hours (healthy)` |
| logs since the sweep, grepped for `denied\|unauthoriz\|permission\|EACCES\|IOException` | **none** (6 log lines total in window) |
| `ls /media/Music` from inside the container | **13 folders** visible |
| reads actual audio bytes through the mount | **`f L a C`** — FLAC magic, readable |
| API `Items?IncludeItemTypes=Audio` | **1,942** |
| API `MusicAlbum` / `MusicArtist` | **70** / **45** |
| Music library location | `/media/Music` |

1,942 / 70 / 45 are **identical to the counts 01-06 recorded** from the database backup. Nothing
was lost.

**Why the intended-end-state concern did not materialise:** Jellyfin keeps full access because
**the mode stays 0777**. Since `chmod` is impossible, a chown cannot remove anyone's access — every
entry is world-rwx regardless of owner. Worth stating plainly: on this pool the chown is
functionally inert and its value is *coherence* (one owner, matching the estate and Phase 2's
`anonuid`/`anongid`), not access control.

### Final audit

`scripts/check-music-freeze.sh`, default asserting mode: **EXIT 1**, **2 failures**.

```
ownership mismatches:        0      (target 0, want 568:568)   ✅
dir-mode mismatches:         88     (target 0, want 755)       ❌ permanent
file-mode mismatches:        2586   (target 0, want 644)       ❌ permanent
sidecars found (widened):    1341   (nfo 91 / jpg 88 / lrc 944 / png 43 / txt 175)
fence assertions failed:     0
FAILURES total:              2
```

**The non-zero exit is entirely the two mode assertions, and it is permanent by decision.**
Sidecar count is **1,341, identical to the Task 1 run** across every extension — a chown creates
and deletes nothing, and it demonstrably did not.

**Instruction for 01-09:** do **not** fold this assertion as-is into `quick-health-check.sh`. It
would report a permanent red. The mode assertion must be scoped to what the dataset can enforce, or
dropped with the cause recorded.

---

## Deviations from Plan

### 1. [Rule 3 — Blocking] The chown had to run on the Proxmox host, not LXC 100

- **Found during:** Task 2, run 1.
- **Issue:** `chown -R` fails `EPERM` on every entry from LXC 100 even as root. The plan,
  `01-CONTEXT.md`, `01-06-SUMMARY.md` and the execution briefing all assert `chown` "works
  normally" — an inference from 01-06 succeeding on `/mnt/tank/downloads/lidarr-import`, a
  directory the container had itself just created and therefore owned within its idmap. It does not
  generalise to files owned by unmapped ids.
- **Fix:** the subcommand delegates the chown to the pool host over the route
  `detect_zfs_route()` already establishes, guarded by a remote `test -d` and a `LIBRARY` literal
  assertion. Treated as Rule 3 rather than Rule 4 because the target value, scope, rollback and
  intent are all unchanged — only *where root runs*, and the script already ssh'd to that host to
  take snapshots, so no new trust boundary was crossed.
- **Commit:** `cecf212`

### 2. [Finding — invalidates a recorded before-state] The 01-01 ownership census is the container's view

- **Issue:** the census every ownership decision rests on was taken inside an unprivileged
  container with a sparse idmap. Real on-disk owners `0:545`, `3000:545` and `568:545` surface as
  `65534:65534` / `568:65534`, and `100000:100000` surfaces as `0:0`. Two distinct on-disk uids
  (`0` and `3000`) **collapse into one** reported value, so the "five distinct owners" figure is an
  undercount — there are **six**.
- **Consequence:** `01-01-SUMMARY.md`'s attributions are wrong. `65534:65534` is not "an SMB/AFP
  client" — it is root on the Proxmox host. `0:0` is not "a root-run process" on the host — it is
  root *inside LXC 100*. `911:911` is `100911:100911`, still the LinuxServer.io `abc` user, so that
  one holds.
- **Fix:** `check-music-freeze.sh` now carries a comment block giving the full mapping table, the
  reason `chown` cannot run from the container, and the one-line ground-truth command. Not silently
  corrected — the container view is still what the script prints, because that is what it can see.

### 3. [Rule 2 — Missing critical] Both censuses excluded the library root

- **Issue:** `census_counts()` and section 4 both used `find … -mindepth 1`, excluding
  `/mnt/tank/media/Music` itself. The root **was** mis-owned (`568:545` on disk). The `chown -R`
  would have fixed it, but **neither instrument could see it either way** — so the assertion could
  have reported "0 entries differ" while the directory every NFS client mounts was still wrong.
  That is the phase's recurring false-pass class, in the one place criterion 5 depends on.
- **Fix:** both now include the root. Totals move 2,673 → 2,674 and mismatches 2,543 → 2,544; the
  `-mindepth 1` subtotal is still printed so the 01-01 baseline stays directly comparable. **The
  tree did not change — the instrument did**, and the output says so.
- **Commit:** `cecf212`

### 4. [Deviation from the plan's sequencing, deliberate] `@pre-chown` taken before the pilot

The plan says "immediately before the sweep". Taken before the **pilot** instead, so a single
`zfs diff` covers the entire normalisation rather than leaving the pilot's 37 entries invisible to
it. Strictly more complete evidence, and it gave the pilot a fresh rollback point. Verified reading
**0** at creation before anything was mutated.

### 5. [Deviation — mode pass] D-12 handled as instructed

The `chmod` pass is **skipped with a printed explanation**, not run, not removed, not `|| true`.
Confirmed by measurement rather than inherited: 37/37 invocations `EPERM` on LXC 100, 37/37 on the
Proxmox host, and a scratch-file probe on `tank/media`. **No `zfs set` of any property on `tank`,
`tank/media` or `tank/media/Music` was executed at any point.**

### 6. [Finding] `.DS_Store` is `3000:545`, and uid 3000 is a recurring estate writer

On disk the stray was **`3000:545`**, not the `65534:65534` the container reported. uid 3000 also
owns **124 entries under `tank/downloads`** (43 at `3000:545`, 81 at `3000:568` in a shallow
census), so it is a real, recurring writer in this estate rather than one macOS drive-by.
**It was chowned to `568:568` along with everything else and was NOT deleted**, per the briefing.

### 7. [Finding — evidence that confirms D-11 and D-14] gid 545 was the anomaly

The moment the real gid turned out to be **545** — exactly what `beets.md`'s
`chown -R 568:545` instructs, and what D-14 calls wrong — D-11's target needed re-justifying rather
than assuming. Per-subtree census on the host settles it:

| Subtree | Dominant owners |
|---|---|
| Movies | **22,903 `568:568`**, 12,533 `0:568`, 635 `100000:100000` |
| Books | 42 `568:0`, 5 `568:568` |
| **Music** | **1,186 `0:545`, 1,171 `568:545`** ← the only subtree on gid 545 |

**Music was the only media subtree carrying gid 545; Movies — by far the largest — was already
predominantly `568:568`.** So `568:568` aligns Music with the estate's own de facto standard,
`beets.md`'s `568:545` describes the drift rather than the convention, and **D-11 and D-14 both
stand — now on positive evidence rather than on four documents agreeing with each other.**

---

## Requirements Status

**WRIT-04 — ownership half MET, and deliberately NOT marked complete.**

- `stat` over all 13 artist folders returns exactly **one** value, `568:568`. Roadmap criterion 5's
  first half is true, and true on disk, not merely in the container's view.
- The mode half is **not achievable on this pool** and is recorded with its cause rather than
  retried or quietly dropped.
- The **"and that decided value is recorded in the repo"** half is **plan 01-09**, together with
  correcting `beets.md`'s `chown -R 568:545` (D-14). WRIT-04 closes there, not here.

The normalisation ran after the writer freeze (01-05/01-06, tagger-class rw holders 0) and after
the QUAL-01 capture (01-04, 9,736 records), so it is durable and the field-level before-state
predates every mutation in the phase.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: privileged-delegation | `scripts/freeze-music-apply.sh` | The `ownership` subcommand now runs `chown -R` as **real root on the Proxmox hypervisor** over ssh, not as a namespaced container root. Mitigated by a `LIBRARY` literal scope guard and a remote `test -d`, but the blast radius of a future edit to that constant is now the hypervisor. The ssh channel itself is pre-existing (01-01 established it; the `fence` subcommand already runs `zfs snapshot` over it). |
| threat_flag: instrument-distortion | `scripts/check-music-freeze.sh` | Section 4's uid:gid figures are the **container's** view and collapse distinct on-disk uids. Any future ownership decision taken from this output alone will be taken on distorted data. Documented in-script with the mapping table and the ground-truth command. |
| threat_flag: uncounted-writer | `/mnt/tank/media/Music/.DS_Store` | Now known to be uid **3000**, which also owns 124 entries under `tank/downloads`. A recurring estate writer, not a one-off. No requirement covers it. |
| threat_flag: acl-vs-modebits | `tank/media/Music` | Unchanged and now confirmed from the host: the tree is permanently 0777. Phase 2's export is governed by mode bits (knfsd does not export NFSv4 ACLs), so it **must stay read-only**. |

## Known Stubs

None. Every task ran against live state and every claim above is backed by a recorded command.

## Self-Check: PASSED

- `scripts/freeze-music-apply.sh` — FOUND, modified, `bash -n` clean
- `scripts/check-music-freeze.sh` — FOUND, modified, `bash -n` clean
- `/mnt/fast/safety/music-pre-project/audit/ownership-after-20260818.txt` — FOUND on LXC 100, 94 lines, 4,452 B, `568:568`; `ls … | grep -c '^ownership-after-'` returns **1**
- `/mnt/fast/safety/music-pre-project/audit/preflight-01-08.txt` — FOUND, 9,408 B
- `/mnt/fast/safety/music-pre-project/audit/postflight-01-08.txt` — FOUND
- `zfs list -t snapshot tank/media/Music@pre-chown` — FOUND, epoch 1787088578
- `zfs list -t snapshot tank/downloads@pre-chown` — FOUND
- `find /mnt/tank/media/Music ! -user 568 -o ! -group 568 | wc -l` — **0** on both hosts
- `stat -c "%u:%g" /mnt/tank/media/Music/*/ | sort -u | wc -l` — **1**, value `568:568`
- `zfs diff tank/media/Music@pre-chown` — 2,674 lines, all `M`
- Commit `cecf212` — FOUND, pushed to `origin/main`; LXC 100 at `/mnt/fast/stacks` confirmed at `cecf212`

## What This Hands Forward

1. **01-09 — three things, one of them a trap.**
   - Do **not** fold section 4's mode assertion into `quick-health-check.sh` as-is; it is a
     permanent red. Scope it to ownership, or to what the dataset can enforce.
   - The `beets.md` D-14 record should now say **`568:568`, and why**: Music was the only media
     subtree on gid 545 while Movies was already `568:568`. It should also name the
     `aclmode=restricted` constraint and correct 01-01's writer attributions.
   - `beets.md` should record that **the normalisation cannot be re-run from LXC 100** — anyone
     repeating it will hit `EPERM` and reasonably but wrongly blame the ACLs.
2. **Phase 2** — `anonuid`/`anongid` `568:568` is now true on disk, so "Option B"
   (`all_squash,anonuid=568,anongid=568`) is available and coherent. The tree stays **0777**, so
   the export **must remain read-only**.
3. **Anyone reading 01-01's census** — it is the container's view. Six on-disk owners, not five,
   and the writer attributions in it are wrong. The ground truth command is in
   `check-music-freeze.sh`'s section 4 comment block.
4. **The phase's recurring pattern, now at five.** A false-pass YAML audit, a harness failing
   closed on a missing PATH entry, a path-set diff reading 0/0 while 83 files were rewritten,
   `find -xdev` skipping every appdata dataset — and now **a census that measured the wrong
   filesystem view entirely, and an assertion that could not see the one directory criterion 5
   names.** Every instrument in this phase has needed a second, independent instrument before it
   could be trusted. Here that second instrument was `zfs diff` from the Proxmox host.
