---
phase: 03-tagger-spike
plan: 01
subsystem: infrastructure
tags: [docker, disk-headroom, lxc-100, gated-mutation, OD-1]
requires: []
provides:
  - "LXC 100 root filesystem headroom >= 8 GiB (OD-1 gate cleared)"
  - "Four pinned spike images present on LXC 100"
  - "scripts/spike03-image-headroom.sh — reusable inventory/prune helper"
affects:
  - "Every Phase 3 plan (03-02 .. 03-11) — all were gated on this"
tech-stack:
  added: []
  patterns:
    - "Audit/mutate subcommand split joined by a file on disk, so the approval gate cannot be branch-skipped"
    - "Referenced-image set from `docker ps -a` with no status filter (created-state blind spot)"
key-files:
  created:
    - scripts/spike03-image-headroom.sh
    - .planning/phases/03-tagger-spike/03-REAP-LIST.md
  modified: []
decisions:
  - "Floor measured with `df -B1` and truncated, never `df -BG` — the latter rounds up and made the OD-1 floor optimistic by up to 1 GiB"
  - "Delete by tag when a tag exists, by ID only when untagged — `docker rmi <id>` fails on multi-tagged images"
  - "The plan's stated lever was wrong: a refilling 19 GB Jellyfin transcode cache, not the image set, was the real consumer — durable fix deferred to inserted phase 2.1"
metrics:
  duration: "~1h including a blocking approval gate and a live incident"
  completed: 2026-09-02
---

# Phase 3 Plan 01: Disk Headroom Gate Summary

Cleared OD-1 — LXC 100's root filesystem went from **2.2 GiB free (99%) to 34 GiB free (71%)** via
an inventoried, operator-approved 27-image prune plus the reclamation of a 19 GB Jellyfin transcode
cache that turned out to be the actual cause, and the four pinned spike images are now on the host.

## What was built

`scripts/spike03-image-headroom.sh` — a two-subcommand helper for reclaiming docker image space on
a live 103-container host.

The load-bearing design decision is that `inventory` and `prune` are **separate processes joined by
a file on disk**, not two branches of one process. `inventory` is read-only and writes
`/mnt/fast/spike-03/out/reap-list.txt`; `prune` reads that file or refuses with exit 2. A branch can
be skipped by a flag, an env var or a future edit — a missing file cannot. `docker image prune -a`
and `docker system prune` are prohibited outright and the prohibition is asserted by a
comment-stripped grep.

The referenced-image set is built from `docker ps -a` with **no status filter**, in both
subcommands. This estate has a documented `created`-state blind spot (dispatcharr and teleport sat
in `created` for six weeks behind a status-filtered check), and a `created` container's image looks
orphaned to any filtered query. Three sources are unioned: the `Image` column, the `docker inspect`
resolution (catching tags that moved after container creation), and the `.Parent` chain (so a
dangling ancestor of a live image is never reaped).

## Results

| Assertion | Result |
|---|---|
| `df -B1` avail, truncated | **34 GiB** (floor 8 GiB) ✅ |
| `df -BG --output=avail /` `-ge 8` | `35G` ✅ |
| Images | 107 → **80** — exactly 27 removed, 0 `rmi` failures ✅ |
| Reap-list survivors (`comm -12`) | **0** ✅ |
| Containers (`docker ps -a`) | **103**, unchanged — none lost ✅ |
| Five spike images present | ✅ (digests recorded in `03-REAP-LIST.md`) |
| `:latest` / `:nightly` among spike repos | **0** ✅ |
| `bash scripts/check-music-freeze.sh` | **exit 0**, `FAILURES total: 0` ✅ |

Full before/after figures, the 27-row table with per-row `stacks/selfhosted/**` cross-reference, and
the five digests are in `.planning/phases/03-tagger-spike/03-REAP-LIST.md`.

## The finding that outlives this plan

**03-01's stated lever was wrong, and the plan would not have held if it had simply succeeded.**

The plan assumed unreferenced images were what stood between the phase and headroom. While it sat
at its approval gate, `/` fell from 2.2 GiB free to **0 bytes**. The cause was measured: docker
local volumes grew 18.93 → 21.16 GB in ~20 minutes, and anonymous volume `d98b2ff94482…` held
**19 GB of Jellyfin transcodes** — 5,131 files, 764 of them zero-byte (the ENOSPC signature),
accumulated over ~36 hours. No `ffmpeg` was running, so the estate's documented amdgpu/VAAPI orphan
hazard was *not* the cause; this is cache retention.

A 19 GB cache is larger than the entire 18.1 GiB image reap, and **unlike images it refills**. Had
the prune run on schedule, the space would have been consumed again within days and the 8 GiB floor
would not have held. The durable fix — a retention policy, or moving the transcode path off `/` onto
`/mnt/fast` — is **inserted phase 2.1**, which runs before Phase 3 continues. The volume being
*anonymous* rather than a declared bind mount is the root of it.

`docker system df` separately reported 61.87 GB (77%) reclaimable across images, so the audited 27
were always the conservative subset — the constraint was never how much *could* be reclaimed from
images.

## Deviations from plan

**1. [Rule 1 — Bug] `df -BG` rounds up, making the OD-1 floor optimistic by up to 1 GiB**
Found live: 2.2 GiB free reports as `3G`. On an 8 GiB floor that could pass at 7.1 GiB actual and
then hand ~2.0–2.3 GB of pulls to a filesystem that could not take them — on the host where filling
`/` takes down 103 containers. Changed to `df -B1` with integer truncation, which is strictly more
conservative than the plan's own external acceptance check. Commit `b217ada`.

**2. [Rule 1 — Bug] `docker rmi` by image ID fails on multi-tagged images**
Task 1 specified deleting "by image ID". `ghcr.io/advplyr/audiobookshelf:2.35.1` and `:latest` are
both `a7befa7704bd`; `docker rmi a7befa7704bd` refuses with *"image is referenced in multiple
repositories"* and would need `-f`. Now deletes by tag when one exists, by ID only when untagged.
**This was load-bearing, not hypothetical** — both tags were removed cleanly at execution while the
live `2.36.0` survived. Commit `b217ada`.

**3. [Rule 3 — Blocking] The `prune` banner tripped the plan's own prohibition grep**
The banner read `docker image prune (APPROVED LIST ONLY)`, which satisfies
`grep -v '^\s*#' | grep -c 'docker image prune'` exactly as a real call would. This is
03-PATTERNS.md § *Acceptance criteria must parse, not grep* pointing the other way — echoed prose,
not a comment, producing the false positive. Reworded to "reap", reason recorded in place.

**4. [Rule 3 — Blocking] Script delivered out-of-band for the read-only inventory**
The plan's delivery path is `git pull --ff-only` at `/mnt/fast/stacks`. A worktree executor cannot
push, and LXC 100's checkout was behind. Staged to `/mnt/fast/spike-03/` — deliberately **outside**
the git checkout, so a later `git pull --ff-only` is not blocked by an untracked file the incoming
commit also adds. sha256-verified identical to the committed file before every use.

**5. Cross-reference prefix blind spot, corrected in the artefact rather than silently**
`pglombardo/pwpush:2.7.3` first scored *not declared* because the stack declares
`docker.io/pglombardo/pwpush:2.9.4`. Recorded in `03-REAP-LIST.md § Known collateral` as a stated
limit of the check.

## Execution notes

**The prune was denied to me twice by the permission system and I did not work around it.** The
approval had reached me as an *agent* message, and an agent message is never user consent. The
mutations — clearing the transcode cache, then the 27-image prune — were performed by the
orchestrator under direct operator authorisation. I verified the outcome independently by read-only
measurement rather than recording it on assertion: image count 107 → 80, zero reap-list survivors,
container count unchanged at 103, `wrtag:v0.20.0` intact.

Before execution the approved list was re-validated by re-running `inventory` and diffing against
the approved file — **identical 27-row set**, only `keeper-worker:2.9` moved one row. `prune`'s own
pre-flight then re-derived the referenced set and re-confirmed all 27 unreferenced immediately
before deleting; the `comm -12` cross-check returned zero lines.

The four pulls I ran myself, one at a time with `df -h /` after each. Total **2.13 GB on disk**
against research estimate A2 of 2.0–2.3 GB — **A2 holds**. The 18.1 GiB reclaim estimate also proved
exact rather than an over-estimate; the "shared layers counted per image" caveat did not bite on
this image set, though it was still the right thing to state in advance.

**Task 1's "pushed to `origin/main`" criterion is deferred to the orchestrator**, not failed —
worktree executors do not push; the merge and push happen post-wave. `prune` therefore ran from the
staged `/mnt/fast/spike-03/` copy rather than from `/mnt/fast/stacks`.

## Known collateral, accepted knowingly

`docker ps -a` cannot protect the image of a stack that is currently `compose down`'d, because
`down` removes the container objects. **This did not materialise here** — not one of the 27 was the
exact image an *enabled* stack declares; 22 were plainly superseded tags (Renovate deploy-drift
residue). The two rows that warranted a deliberate answer (`karakeep-mcp:0.31.0`, declared at its
exact tag but in a commented-out block; and `gcr.io/zenika-hub/alpine-chrome:124`, whose registry is
retired) were accepted by name, as were `curlimages/curl:latest` and `alpine:3`.

## Self-Check: PASSED

- `scripts/spike03-image-headroom.sh` — FOUND
- `.planning/phases/03-tagger-spike/03-REAP-LIST.md` — FOUND
- commits `52d2693`, `b217ada`, `608d7d7`, `79ef2fa` — FOUND
