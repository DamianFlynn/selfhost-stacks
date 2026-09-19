# Phase 5 — deferred items

Out-of-scope discoveries logged rather than fixed, per the executor scope boundary: only issues
DIRECTLY caused by this phase's own changes are auto-fixed.

---

## 1. `check-music-freeze.sh` §2 interpolated-host-path inventory has MOVED (found 2026-09-18, plan 05-02)

**What:** Every run of `scripts/quick-health-check.sh` is currently RED before Phase 5 touches
anything. The music freeze harness fails with:

```
❌ interpolated-host-path inventory MOVED: expected=12, found=13. These lines are invisible to
   §2's driving grep and cannot be resolved statically, so §2 is UNKNOWN until each new one is
   read by hand and DECLARED_INTERP_EXPECTED is moved in the same commit
```

**Not caused by plan 05-02, and that was checked rather than assumed.** The assertion counts
*compose volume lines* that interpolate a variable into the HOST side of a bind, and it runs from
the host-side copy of the repo at `/mnt/fast/stacks` (measured at `b27255b`, where
`grep -c MUSIC_UNDERSCORE_ROOT scripts/quick-health-check.sh` returns **0**). Plan 05-02's edits are
workstation-local and in a different file entirely, so they are not reachable by that count.

**Why it is not fixed here:** `check-music-freeze.sh:492` pins `DECLARED_INTERP_EXPECTED=12` and its
own failure text states the remedy — *each new line must be READ BY HAND and the constant moved in
the same commit*. That is a deliberate human-review gate on a compose change this phase did not
make; satisfying it by bumping the number is exactly the "edit the assertion to make it pass" move
this estate has repeatedly recorded as the defect rather than the fix.

**Consequence for this phase, stated so a verifier is not misled:** `bash scripts/quick-health-check.sh`
exits **1** today for a reason unrelated to Phase 5. A whole-script exit code is therefore
**non-discriminating** for Phase 5's criterion-4 assertion — the block's own verdict line must be
read. Plan 05-02's negative control was driven on the block's line and on the diff of the run's
red/amber line set, not on the script's exit code alone.

**Who should fix it:** whoever added the thirteenth interpolated volume line, by reading it and
moving `DECLARED_INTERP_EXPECTED` in the same commit.

---

## 2. `mac-music-archive/` is ~24,000 untriaged music entries nobody has counted (found 2026-09-19, plan 05-10)

**What:** `/mnt/tank/downloads/mac-music-archive/` holds **23,874 entries** — `Compilations/`
13,925, `iTunes/` 6,322, `NEW/` 1,154, `2024-03/` 700, `Various Artists/` 663, `Library/` 521,
`MoreCompilations/` 447, `2024-10/` 99, `HitSquad/` 28, `Shamrock/` 13. Last written 2024-10-27.
Owned `0:0` throughout, with its own top directory at `100000:100000`.

**Why it matters:** this is a music archive, in the same dataset as the backlog this project
exists to work down, and **no phase has measured, triaged or even mentioned it.** PROJECT.md's
backlog denominator is 144 folders across `unsorted/` and `nzb/music`; this tree is not in that
count. It may be a duplicate of content already held, it may be net-new, and nobody knows which.

**Why it is not handled here:** plan 05-10 is an ownership sweep. Triaging 24,000 entries of
music is Phase 6/7 work and would need its own decision on whether it is in scope for the
milestone at all. Ownership is the only thing 05-10 touches.

**Its ownership WAS normalised** — all 23,874 entries are now `568:568` as of 2026-09-19, under
the operator's approved scope. **Its content was not looked at, deliberately.** Operator decision
the same day: *"`mac-music-archive/` is logged, not investigated … do not characterise its
formats, overlap or duplication now — that is a planning question, not an execution one."* So
this entry deliberately carries **no** claim about what is in there: not its formats, not whether
it duplicates the 34 GB library or the `unsorted/` backlog, not whether it is tagged. Those are
open questions, and answering them by guess would be worse than leaving them open.

**Who should pick it up:** the **next milestone's scoping**, as a first-class question — is this
content in the project or not? PROJECT.md's backlog denominator is 144 folders
(`unsorted/` 120 + `nzb/music` 24); this tree is not in that count, and if it is in scope the
denominator is wrong.

---

## 3. `dropbox/` is 84% of the download dataset and is not downloads (found 2026-09-19, plan 05-10)

**What:** `/mnt/tank/downloads/dropbox/` holds **196,327 entries** (`code/` 130,348, `Archive/`
52,074, `Documents/` 7,006, `Projects/` 3,706, `Shared/` 3,169). Uniformly `3000:568`, last
written 2026-01-03, with `code/` and `Archive/` carrying the `2000-01-01` mtime sentinel of a
timestamp-less archive extraction.

**Why it matters:** it is inside the `rw` bind of **nine** containers, because every arr and the
beets container mounts `/mnt/tank/downloads:/downloads:rw` wholesale. Nothing references it by
name and nothing has written to it in eight months, yet a personal document and source archive is
mounted read-write into nine network-facing services.

**Why it is not handled here:** narrowing nine bind mounts is a stack change with its own blast
radius, and 05-10 is an ownership sweep. Recorded rather than fixed.

**Who should pick it up:** whoever next revises `stacks/selfhosted/arrs/`.

---

## 4. `takeout-import.service` passes an Immich API key on the command line (found 2026-09-19, plan 05-10)

**What:** `/etc/systemd/system/takeout-import.service` on LXC 100 invokes `immich-go` with
`--api-key=<value>` as a command-line argument, so the key is readable in `ps` by anything on the
host and appears in the host's process table, not just the container's.

**Why it is not fixed here:** it is not this phase's unit and the fix (an `EnvironmentFile` with
restrictive mode, or `--api-key-file` if the binary supports it) is a change to a live import that
was mid-run when this was found. **The value is deliberately not recorded in this repo, which is
public.**

**Who should pick it up:** whoever owns the takeout import — rotate the key and move it out of
`ExecStart` in the same change.
