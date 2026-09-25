---
phase: 07-pilot-12-albums-end-to-end
plan: 04
subsystem: music-pipeline / DJ routing + D-04 register
tags: [d-08, d-27, e1, def-06-21-06, impt-01, d-04, exemption-register, health-check]
requires:
  - 07-03 (quick-health-check.sh at 317c1a4, the D-04 block this plan extends)
  - beets-flask container, /venv/bin/beet = beets 2.12.0, user beetle, BEETSDIR=/config
provides:
  - scripts/route-dj-album.sh — the D-08 DJ-routing operation (read-only default, --apply gated); first --apply is 07-13's
  - quick-health-check.sh D04_EXEMPT_RE alternation for route-dj-album.sh + $BEET_REALLIB, register reason 4, D04_EXEMPT_BASELINE 5 -> 12
  - artifacts/07-04-d27-register-drive.txt — before/after counts and the four-mutant two-way drive
affects: [07-13, phase-09]
tech-stack:
  added: []
  patterns:
    - "one beets call per line, each carrying the registered token, so the D-04 scan counts it and the register keys on file + token"
    - "measure-in-scratch: the 'task-1 commit' exists only in a scratch clone so the real repo gets the script and the pin move in ONE commit"
key-files:
  created:
    - scripts/route-dj-album.sh
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-04-d27-register-drive.txt
  modified:
    - scripts/quick-health-check.sh
decisions:
  - "BEET_REALLIB=/venv/bin/beet, not the bare name: measured, `beet` is not on PATH for user beetle in beets-flask."
  - "Album-level calls (-a) query id:N; only the item read-back queries album_id:N — on an album the id field is `id`."
  - "The ls format puts $id|$disctotal|$albumtype first so a `|` in an artist or album name cannot shift the parsed fields."
  - "D04_EXEMPT_BASELINE moved 5 -> 12 (N = 7 measured) in the same commit as the script, with register reason 4; D04_DOC_BASELINE stays 2; no env override used."
metrics:
  duration: "~45 min"
  completed: 2026-09-26
  tasks: 2
  files: 3
---

# Phase 7 Plan 04: D-08 DJ Routing Script and D-27 Registration Summary

`scripts/route-dj-album.sh` is the E1 mechanism. It sets `albumtype=dj` on one imported album
after import, with the move suppressed. It then shows the pretend move, runs the move, and checks
that every item now reads `dj` under `/media/Music/DJ/`. It runs only inside beets-flask on beets
2.12.0 and writes nothing without `--apply`. Its seven beets calls are registered in the D-04
exemption register with a reason, and the pin moved from 5 to 12 in the same commit. The register's
overlay-key half was driven both ways on both files.

## Commits

| Task | Commit | What |
|---|---|---|
| 1 + 2 | `40cc63d` | The route script, the register extension (reason 4, `D04_EXEMPT_RE`, pin and guard 5 → 12) and the drive artifact. One commit by design: the acceptance criteria require the pin to move in the same commit as the script. |

## Results

- **Static checks:** `bash -n` passed and `shellcheck` is clean. The two SC2016 infos are disabled in place, because the `$fields` are beets format tokens. `--album-id x`, no arguments and an unknown flag each exit 2.
- **Bare `beet ` check:** a comment-stripped search finds 0 bare `beet ` tokens in the script. The same search returns 1 on the control line `docker exec x beet ls`.
- **No filesystem writes:** a comment-stripped word search finds 0 `rm`/`mv`/`cp`/`chown`/`chmod`.
- **Where the calls sit:** the default mode issues only `--version` (`:140`) and `ls -a` (`:151`), then exits at `:170–173`. `modify -h` (`:181`) is read-only, but it sits in the `--apply` branch with the calls that write: `modify` (`:190`), `move -p` (`:196`) and `move` (`:205`). The item read-back is at `:212`.
- **Guards:** the version guard needs the exact line `beets version 2.12.0`. `modify -h` must offer `-M, --nomove` and `-y, --yes`, and the error names whichever is missing.
- **D-04 counts** (full output in the artifact; GNU grep gave the same numbers):

  | Tree | executable | asserted | exempt | doc |
  |---|---|---|---|---|
  | Pre-plan | 8 | 3 | 5 | 2 |
  | Before the register edit | 15 | 10 | 5 | 2 |
  | After the register edit | 15 | 3 | 12 | 2 |

  Before the edit, all seven route-script lines were in the asserted set: **`D04 ROUTE-SCRIPT LINES IN ASSERT SET: N = 7`**. That equals the script's own count of `"$BEET_REALLIB"` lines. After the edit, all seven are in the exempt set.
- **Two-way drive (DEF-06-21-06):**
  - `phase06-oracle.sh`: the mutant without `$SCRATCH_OVERLAY` landed in ASSERT, and the one with it landed in EXEMPT.
  - `route-dj-album.sh`: the mutant using `$BEET_OTHER` landed in ASSERT, and the one with `$BEET_REALLIB` landed in EXEMPT.
  - The mutant tree would be red twice: two asserted lines have no `-l`, and the exempt count is 14 against a pin of 12.
- **Mutants stayed in scratch:** the scratch clone was deleted behind an exact-prefix fence. `git log --all -S'mutant-a.txt'` returns 0 commits. `-S'BEET_OTHER'` returns only `114586e`, which is the plan text that names the variable.
- **Nothing written to the estate:** the only live contact was three read-only probes inside beets-flask: `command -v beet`, `--version`, and `modify -h`/`move -h`. The script was never run against the live container in either mode.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `BEET_REALLIB=beet` would not resolve in the container**
- **Found during:** Task 1
- **Issue:** `docker exec -u beetle beets-flask sh -c 'command -v beet'` prints nothing, because `beet` is not on PATH for `beetle`. Every call would have failed. The guard would have refused at exit 3, so this was safe, but 07-13 could not have run.
- **Fix:** `BEET_REALLIB=/venv/bin/beet`, the path `phase06-oracle.sh` uses. Measured to report `beets version 2.12.0`. The token name is unchanged, so the register keys the same way.
- **Commit:** `40cc63d`

**2. [Rule 1 - Bug] Album-level query key**
- **Issue:** the plan queries `album_id:N` everywhere. On an album (`-a`) the id field is `id`, and `album_id` is an item field.
- **Fix:** the album-level calls (`ls -a`, `modify -a`, `move -a -p`, `move -a`) use `id:N`. The item read-back in step (f) uses `album_id:N`. The query is still its own argv element.

**3. Field order in the `ls -a` format**
- The format is `$id|$disctotal|$albumtype|$albumartist|$album|$path`: the plan's fields, reordered so the parsed ones come before any free text.

**4. One commit instead of two**
- The plan measures "at the task-1 commit" but also requires the pin to move "in the same commit as the script". The task-1 commit was made in the scratch clone only, and the real repo got a single commit.

**5. Measurement input**
- The plan text says `git grep -n -I -i beet`. The block's real remote command is `git grep -n -I -w -E -e 'beet' -e 'BEET[A-Z_]*'`, and that is what ran, so the measurement uses the block's own input as well as its own regexes.
- The optional whole-block run on LXC 100 with `D04_REPO_ROOT` was not done. The scratch lived on the workstation, and LXC 100's root filesystem is 85% full.

## Operator Notes

- **The routine health check's D-04 block goes red until the host checkout is pulled.** The workstation `quick-health-check.sh` now pins exempt = 12. The host's `/mnt/fast/stacks` (HEAD `0c95427`, not pulled) has no route script, so it holds 5. After a `git pull` it reads 12 and the block is green again. This is the same deploy lag 07-03 recorded.
- **Behaviour 07-13 inherits:**
  - `--apply` stops at the first failed step.
  - If `modify` succeeds and a move fails, the album is left tagged `dj` but still in the artist tree. The script says so and exits 1.
  - No Jellyfin scan may run between the import and a 0 exit.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: scripts/route-dj-album.sh
- FOUND: scripts/quick-health-check.sh (route-dj-album alternation, baseline 12, guard 12, DOC baseline 2)
- FOUND: .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-04-d27-register-drive.txt
- FOUND: commit 40cc63d
- Both plan `<verify>` commands printed PASS.
