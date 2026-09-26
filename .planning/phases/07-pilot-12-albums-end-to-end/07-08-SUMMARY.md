---
phase: 07-pilot-12-albums-end-to-end
plan: 08
subsystem: music-pipeline / the rw grant (built, not deployed)
tags: [impt-01, qual-04, d-21, d-22, d-23, e3, e11, c1, c3, c4, c5, c6, c7, c8, c9, c10]
requires:
  - 07-03 (quick-health-check notice series at 14; tenth fatal block)
  - 07-04 (scripts/route-dj-album.sh — closes flask-config.yaml's UNOWNED GAP paragraph)
  - 07-05 (pre-grant oracle run; pre-grant import keys copy=true / move=false / write=true)
provides:
  - "D-22 commit 926f1ff: beets-flask /mnt/tank/media:/media:rw plus every flag and check that moves with it, in 7 files"
  - "standing assertion D-23 in quick-health-check.sh (the D-03 flask arm, inverted to RW=true)"
  - "PHASE7_RW_TAGGER literal exception in check-music-freeze.sh sections 1, 2 and 6b"
  - "beets.md § Vendored config digest register (from Phase 7, D-22)"
  - "artifacts/07-08-d22-measure.txt — C1/C3/C10/tank/01-auto measurements and the exception drive"
affects: [07-09, 07-10, 07-11, 07-13, phase-08]
tech-stack:
  added: []
  patterns:
    - "measure every value a decision leans on before editing (C1 turned an 'edit' into a verification)"
    - "decide a UI flag by reading what the image's own source gates, not by its name (C3)"
    - "a named exception is a literal name AND one literal mapping, counted on its own line, >1 is red"
    - "grant and every coupled check land in ONE commit, asserted by git show --stat"
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-08-d22-measure.txt
  modified:
    - stacks/selfhosted/arrs/beets/flask.yaml
    - stacks/selfhosted/arrs/beets/beets.yaml
    - stacks/selfhosted/arrs/beets/flask-config.yaml
    - stacks/selfhosted/arrs/beets/config.yaml
    - scripts/quick-health-check.sh
    - scripts/check-music-freeze.sh
    - stacks/selfhosted/arrs/beets.md
decisions:
  - "D-22 item 2 is a VERIFICATION. The repo, the appdata copy and the running server all read copy yes / move no before the edit, so no key changed and nothing claims a move to copy."
  - "gui.library.readonly stays true (C3). In rc6 it gates only delete_entities and update_entities in routes/library/resources.py, which are the library browser's DELETE and PATCH. Import, candidate confirm and UNDO IMPORT (UndoSession -> delete_from_beets) never reach it. With /media rw it is the only thing stopping a browser click from editing or deleting library files."
  - "rw goes to beets-flask ONLY. beets.yaml stays :ro and qhc's CLI arm still asserts ro, relabelled D-04/D-22. 07-09's grant-both override is still available."
  - "The freeze exception covers sections 1, 2 and 6b, not only the 6b census loop, and it matches the literal mapping /mnt/tank/media:/media as well as the name. Any other rw mount beets-flask gains still fails."
  - "The previous digests are config.yaml 661c7297… (commit 1a64286) and flask-config.yaml 949bd1f3… (commit f1848e2), measured at base 003a7b2 with two hashers. Repo, appdata and container are equal. The new digests are 7d726454… and 875fcf7e…"
metrics:
  duration: "~10 min wall-clock across the three commits (00:57 → 01:06 local)"
  completed: 2026-09-26
  tasks: 3
  files: 8
---

# Phase 7 Plan 08: the ONE D-22 commit (built, not deployed) Summary

**Commit `926f1ff` is the D-22 commit.** It grants beets-flask `/mnt/tank/media:/media:rw` and
changes everything that has to change with the grant, in 7 files: `01-auto` is de-registered,
`write: yes` is recorded as forced and bounded by D-21, the readiness text goes from three inboxes
to two, qhc's D-03 flask arm is inverted to assert RW=true as standing assertion D-23, and
check-music-freeze.sh gets a literal `beets-flask` exception. The config digest register keeps the
previous digests beside the new ones. Nothing was deployed.

## Commits

| Task | Commit | What |
|------|--------|------|
| 1 | `7d1aa8b` | Measurements taken before any edit: C10 digests, C1 import keys, C3 readonly guard, tank free, 01-auto |
| 2+3 | **`926f1ff`** | **The D-22 commit.** Exactly 7 files, asserted with `git show --stat` |
| 3 | `8c6c50e` | Writes the D-22 hash into beets.md's NEW rows and the artifact. Both config digests are unchanged by it |

## What was measured (task 1)

- **C10:** `config.yaml` at base `003a7b2` = `661c7297…` from `shasum -a 256` and `openssl dgst -sha256`, which agree. Producing commit `1a64286`. The appdata copy and `/config/config.yaml` in the container are the same. `flask-config.yaml` = `949bd1f3…` (commit `f1848e2`), unchanged since 06-04.
- **C1:** copy yes / move no / write yes in the repo, in the appdata copy (awk; the container's `/venv/bin/python` yaml parse, because LXC 100's python3 has no yaml), and in the server's effective config (07-05). So D-22 item 2 is a verification, not an edit.
- **C3:** see the decisions above. The rule was applied and the flag is kept `true`.
- **tank:** 41.9T used / **5.26T** avail, measured on atlantis as root. `01-auto` exists with 0 entries.

## Checks

- qhc notice headers: **15**. The recipe was checked against a one-line control first, which read 1. The raw count is 19. The new conditions are T and U.
- D-04: documentation count is still **2**. raw/stripped/invocation/exe/exempt = 220/111/17/15/12, the same before and after. The plan's own whole-repo `*.md` scan reads 67 before and after. That scan is not the pinned set.
- check-music-freeze.sh was run on the workstation against a synthetic `docker` with six scenarios: control, grant, grant plus a second rw mount, CLI arm rw, a near-miss name, and a duplicate row. Every one gave the expected outcome, and §2 was run against a scratch tree. `DECLARED_INTERP_EXPECTED` (13) and `TAGGER_DEF_EXPECTED` (2) did not move. The script has no self-test.
- `bash -n` passes on both scripts. All four YAML files parse. The task-2 verify found 0 changed `paths:` rule lines. `823fe04` is still an ancestor of HEAD.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Freeze exception also applied to sections 1 and 2**
- **Found during:** Task 3
- **Issue:** The plan put the named exception only in the 6b census loop. Section 1 (running rw holders, "WRIT-01 requires 0") and section 2 (declared rw in stack YAML) would also fail on the deliberate `flask.yaml :rw`, so the freeze harness and qhc would stay red after 07-09 deploys the grant.
- **Fix:** Section 1 and section 2 use the same literal constants. Each counts the exception on its own summary line (`tagger-class D-22 exception`, `declared rw, D-22 exception`), and more than one match is a red. Both labels reuse existing fold-in tokens, so qhc's selector did not need to change.
- **Files:** scripts/check-music-freeze.sh (inside the D-22 commit, `926f1ff`)

**2. [Rule 2] The exception matches the literal mapping, not the name alone**
- `PHASE7_RW_TAGGER_SRC=/mnt/tank/media`, `_DST=/media` and `_DECL=flask.yaml`. This is stricter than the plan's name-only arm: another rw mount on beets-flask that reaches the library still fails. That was tested (scenario B).

**3. [Accuracy] C9 comment wording**
- The plan says the drift block is red "between the D-22 commit and 07-09's install". The block compares the host checkout's HEAD with appdata, so the red actually starts when the host pulls. The comment and beets.md state it that way.

## What the operator must know

- **Nothing was deployed.** The host checkout stays at `0c95427`. No `docker compose`, no container was recreated, nothing was written under `/mnt/fast/appdata`, and nothing touched the library or the beets DBs. Every remote command was a read.
- **Until 07-09 deploys the grant, `quick-health-check.sh` is red by design.** The D-23 arm reads beets-flask at RW=false. Once the host pulls, the vendored-drift block also reads both beets configs as drifted until 07-09 installs them. The C7/C8 instruments (`phase06-oracle.sh --run`, `phase06-incremental-control.sh`) go red once the grant deploys. They are retired from use, with no code change.
- `CLAUDE.md` § Constraints still says "`import.move: yes` is currently set". That is stale: all three copies read `move: no`. It was not edited here because the file is outside `files_modified`.
- flask-config.yaml's header still says the drift block does not cover this file. It has covered it since phase 6. This is pre-existing and out of scope.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the rw grant itself (T-07-08-01…06), and it is not live until 07-09.

## Self-Check: PASSED

- FOUND: artifacts/07-08-d22-measure.txt, and every one of the 7 files carries its edit (task verifies re-run: VERIFY2-OK, VERIFY3-OK)
- FOUND commits: 7d1aa8b, 926f1ff, 8c6c50e
