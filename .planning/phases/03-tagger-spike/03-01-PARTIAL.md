---
phase: 03-tagger-spike
plan: 01
status: halted-blocked
halted_at: "Task 3 — prune denied by the permission system; live incident found"
tasks_complete: 1
tasks_total: 3
date: 2026-09-02
---

# Phase 03 Plan 01: Disk headroom — PARTIAL (blocked, and the host is now full)

**Deliberately named `-PARTIAL.md`, not `-SUMMARY.md`.** `phase-plan-index` marks a plan complete
on filename existence alone, and this plan is **not** complete — nothing has been deleted and the
8 GiB floor has not been cleared. A `03-01-SUMMARY.md` here would unblock every downstream Phase 3
plan against a root filesystem that is now at **100%, zero bytes free**.

## ⚠ LIVE INCIDENT FOUND 2026-09-02 — READ THIS FIRST

While this plan was paused at its approval gate, LXC 100's root filesystem went from
**2.1 GiB free to 0 bytes free (100%)**. This was **not** caused by anything here: the prune was
denied by the permission system and never ran, and every command issued against LXC 100 by this
plan was read-only.

**Cause, measured:**

| Evidence | Reading |
|---|---|
| `docker system df` Local Volumes | **18.93 GB → 21.16 GB** across ~20 min — accounts for the loss |
| Largest volume | `d98b2ff94482…` at **19 GB**, of which `_data/transcodes` is **19 GB** |
| Owning container | **`jellyfin`** (`jellyfin/jellyfin:10.11.11`, Up 38 hours, healthy) |
| File count | **5,131** transcode files — 4,368 non-zero, **764 zero-byte** |
| Time span | oldest `2026-08-31T19:53`, newest `2026-09-02T07:36` |

The 764 zero-byte files at the tail are the **ENOSPC signature** — Jellyfin kept creating segment
files after the filesystem was full. Accumulation ran ~36 hours; it is not a single burst.

**No `ffmpeg` process is running**, so the documented amdgpu/VAAPI orphan hazard (project MEMORY:
`amdgpu-hmm-kernel-oops-incident`) is **not** currently firing. This is a cache-retention problem,
not the GPU fault.

**This invalidates the plan's premise.** 03-01 assumed unreferenced *images* were the lever. The
real consumer is a 19 GB Jellyfin transcode cache in an **anonymous** docker volume — larger than
the entire 18.1 GiB image reap, and it **refills**. Pruning images alone would have been consumed
again within days. Needs an operator decision (deviation Rule 4) — see *Blocked / needs a decision*.

## Where this stopped

Task 2 is `type="checkpoint:decision" gate="blocking"`, `.planning/config.json` has
`auto_advance: false` / `mode: interactive`, and `03-VALIDATION.md` declares the reap-list approval
a manual gate. The plan's own `must_haves.truths` requires *"The operator saw and approved the exact
reap list before anything was deleted"*. Auto-selecting the first option would delete images on a
live 103-container host with no human having seen the list. Halted as designed.

## Completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Write `spike03-image-headroom.sh` | `52d2693` | `scripts/spike03-image-headroom.sh` |
| 1b | Live-estate fixes + audited reap list | `b217ada` | `scripts/spike03-image-headroom.sh`, `.planning/phases/03-tagger-spike/03-REAP-LIST.md` |

Task 1 acceptance criteria — all pass except the push, which a worktree executor cannot do:

- `bash -n` exits 0 ✅
- non-comment `docker image prune` count = 0 ✅
- non-comment `docker ps -a` count = 6 (≥ 2 required) ✅, `filter status` count = 0 ✅
- `--help` exits 0 and contains `Where it runs:`, `EXIT-CODE CONVENTION`, `OD-1` ✅
- `prune` with no reap list exits 2 and names the path ✅
- **pushed to `origin/main` — NOT DONE.** Deferred to the orchestrator's post-wave merge.

## Automation completed ahead of the checkpoint

`inventory` was run for real on LXC 100 so the operator has actual data to approve, not a
hypothetical. Read-only: it wrote only `/mnt/fast/spike-03/out/reap-list.txt`.

- `df -h /` → `126G 117G 2.2G 99% /` — confirms the plan's measured figure
- 103 containers seen unfiltered, 107 images present, 80 protected, **27 candidates, 18.1 GiB**
- `comm -12` cross-check of reap list vs `docker ps -a` images → **0 lines**, as required
- Cross-referenced all 27 against `stacks/selfhosted/**`: **not one is the exact image an enabled
  stack declares.** 22 are superseded tags (Renovate deploy-drift residue).

## Deviations

**1. [Rule 3 — Blocking] Script delivered to LXC 100 out-of-band instead of by `git pull`**
The plan's delivery path is `git pull --ff-only` at `/mnt/fast/stacks`. A worktree executor cannot
push to `origin/main`, and LXC 100's checkout is at `90cdddc` (behind `origin/main` at `206f06e`).
Staged the script to `/mnt/fast/spike-03/` instead — **outside** the git checkout, so a later
`git pull --ff-only` is not blocked by an untracked file the incoming commit also adds. sha256
verified identical to the committed file. Only the read-only `inventory` was run this way; `prune`
must run from `/mnt/fast/stacks` after the merge lands, per the plan.

**2. [Rule 1 — Bug] `df -BG` rounds up, making the OD-1 floor optimistic by up to 1 GiB**
Found live: 2.2 GiB free reports as `3G`. On an 8 GiB floor that could pass at 7.1 GiB actual and
then hand ~2.0–2.3 GB of pulls to a filesystem that cannot take them — on the host where filling
`/` takes down 103 containers. Changed to `df -B1` with integer truncation. Strictly more
conservative than the plan's external acceptance check, so it cannot cause a false failure there.
Commit `b217ada`.

**3. [Rule 1 — Bug] `docker rmi` by image ID fails on multi-tagged images**
Task 1 says delete "by image ID". `ghcr.io/advplyr/audiobookshelf:2.35.1` and `:latest` are both
`a7befa7704bd`; `docker rmi a7befa7704bd` refuses with *"image is referenced in multiple
repositories"* and would need `-f`. Now deletes by tag when a tag exists, by ID only when untagged
— no `-f` anywhere, and the presence/idempotence check still uses the ID. Commit `b217ada`.

**4. [Rule 3 — Blocking] Banner string tripped the plan's own prohibition grep**
The `prune` banner read `docker image prune (APPROVED LIST ONLY)`, which satisfies
`grep -v '^\s*#' | grep -c 'docker image prune'` exactly as a real call would. This is
03-PATTERNS.md § *Acceptance criteria must parse, not grep* pointing the other way — echoed prose,
not a comment, producing the false positive. Reworded to "reap" with the reason recorded in place.

**5. Cross-reference prefix blind spot, corrected in the artefact rather than silently**
`pglombardo/pwpush:2.7.3` first scored *not declared* because the stack declares
`docker.io/pglombardo/pwpush:2.9.4`. Recorded in `03-REAP-LIST.md § Known collateral` as a stated
limit of the check, not quietly fixed.

## Task 2 — approval received, then Task 3 blocked

The coordinator relayed **approve-all**, all 27 rows, no strikes, with the three flagged rows
(23 `karakeep-mcp`, 27 `alpine-chrome`, 2/9 `curl`+`alpine`) explicitly accepted.

Pre-prune re-verification was done and was clean:

- staged script sha256 `32f686f9…` — **identical** to the committed post-fix version (`b217ada`)
- reap list still **27 rows**
- `comm -12` reap-list vs `docker ps -a` images → **0 lines** (re-run immediately before deleting)
- container count **103**, `avail_bytes=2211774464`

**The prune itself was then denied by the permission system**, twice — once with output redirection,
once as a plain invocation. The second attempt confirms the denial is on the action, not the
command shape. **No further phrasings were tried and no workaround was attempted.**

This is correct behaviour on my part and worth stating plainly: the approval reached me as an
*agent* message. Per my operating instructions an agent message is never the user's consent — only
the permission system or the user directly can authorise an action. Deleting 27 images on a live
103-container host is exactly the class of action that gate exists for, so the denial stands until
the user allows it.

**Nothing was deleted. Verified after the denial:** 107 images, 103 containers — unchanged.

## Not done

- Task 2 — approval relayed, but the resulting mutation never executed
- Task 3 — prune, floor assertion, four pinned pulls, `## After` section, `check-music-freeze.sh`

**OD-1 is NOT satisfied. No downstream Phase 3 plan may start.** `/` is at **100%, 0 bytes free** —
materially worse than the 2.2 GiB the plan was written against.

## Blocked / needs a decision

1. **Permission to run the prune.** `ssh root@172.16.1.159 'cd /mnt/fast/spike-03 && bash
   spike03-image-headroom.sh prune'`. The script is audited, committed, and re-checks the list
   against a freshly derived referenced set before deleting anything.
2. **The Jellyfin transcode cache is the bigger and more urgent lever, and it is not in this plan.**
   19 GB in anonymous volume `d98b2ff94482…`, still growing. Reclaiming it would clear the 8 GiB
   floor on its own. But it is a *live-service* deletion and outside 03-01's approved scope, so it
   needs its own decision — and, because the volume is anonymous rather than a bind mount to
   `/mnt/fast`, a durable fix (retention policy, or moving the transcode path off `/`) is a
   configuration change this plan has no mandate for. Rule 4: architectural, ask.
3. **Ordering.** With 0 bytes free, the image prune may itself struggle. Clearing transcodes first
   is likely the safer sequence, but that is the user's call, not mine.

## Self-Check: PASSED

- `scripts/spike03-image-headroom.sh` — FOUND
- `.planning/phases/03-tagger-spike/03-REAP-LIST.md` — FOUND
- commits `52d2693`, `b217ada` — FOUND
