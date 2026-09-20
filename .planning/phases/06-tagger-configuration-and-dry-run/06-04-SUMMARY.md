---
phase: 06-tagger-configuration-and-dry-run
plan: 04
subsystem: infra
tags: [beets, beets-flask, docker-compose, traefik, authelia, zfs, music-tagging]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-01's full Phase 6 beets configuration in stacks/selfhosted/arrs/beets/config.yaml — the file this plan deploys and stands a runtime up against"
  - phase: 05-inbox-structure-and-the-junk-gate
    provides: "the _inbox tree (01-auto, 02-review, 03-asis, 04-hold, 99-quarantine, _done) whose three registered folders this plan wires to the watchdog"
  - phase: 04-retire-the-dead-taggers
    provides: "exactly one surviving beets library.db (D-28) and the vendored-config discipline (D-27)"
  - phase: 03-tagger-spike
    provides: "the beets-flask v2.0.0-rc6 choice, its verified image digest, and the nine measured frictions — friction 9 in particular"
provides:
  - "beets-flask v2.0.0-rc6 running as the ACTIVE tagger runtime, Traefik-fronted behind chain-authelia@file with no host port"
  - "stacks/selfhosted/arrs/beets/flask.yaml — the service definition, with BEETSDIR=/config making one vendored config serve both containers"
  - "stacks/selfhosted/arrs/beets/flask-config.yaml — the beets-flask config: three inboxes, terminal off, library read-only"
  - "the D-29 layer 3 baseline: library.db and state.pickle sha256 after first start"
  - "an empty 02-review, with its former contents intact under the unregistered 04-hold"
  - "the runtime proof that rc6 executes beets 2.12.0 and did not install its own example config"
affects: [06-05, 06-06, 06-07, 06-09, 06-10, phase-07, phase-09]

# Tech tracking
tech-stack:
  added: ["metasauce/beets-flask:v2.0.0-rc6 (ships beets 2.12.0)"]
  patterns:
    - "Gate a container on a log line that proves the work started, never on .State.Status == running"
    - "Deploy a vendored config and hash-match it BEFORE the container that would otherwise write its own exists"
    - "Assert a runtime version from the interpreter that runs the server, not from the image tag"
    - "Prove a mount flag from docker inspect, not from the compose file"

key-files:
  created:
    - stacks/selfhosted/arrs/beets/flask.yaml
    - stacks/selfhosted/arrs/beets/flask-config.yaml
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-04-inbox-before-after.txt
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-04-first-start.txt
  modified:
    - stacks/selfhosted/arrs/beets/beets.yaml
    - stacks/selfhosted/arrs/compose.yaml

key-decisions:
  - "D-35 executed: 02-review emptied into the deliberately-unregistered 04-hold BEFORE registration, proven by sha256 and unchanged inodes"
  - "D-07 executed: the dormant survivor's traefik labels DELETED, not commented out; one hostname, one router; port corrected 8337 -> 5001"
  - "D-05 correction landed in place and dated, with the superseded sentence kept visible: /media stays :ro for all of Phase 6; rw is Phase 7's first act"
  - "flask.yaml uses LITERAL TZ/PUID/PGID because the sibling-.env assumption was measured false for this directory"
  - "No /config/requirements.txt is created, so rc6's unpinned install hook is a provable no-op"

patterns-established:
  - "Paraphrase a detector string in any artifact that asserts its absence, so a mechanical grep over the artifact cannot read as the failure"
  - "When an instrument returns a surprising FAIL, record the instrument's own defect rather than silently re-running it"

requirements-completed: [CONF-01, CONF-02, CONF-03, CONF-05]

# Metrics
duration: 35min
completed: 2026-09-20
---

# Phase 6 Plan 04: beets-flask rc6 stood up on the Phase 6 config Summary

**beets-flask v2.0.0-rc6 is running as the one tagger runtime — three inboxes registered and no more, beets 2.12.0 proven at runtime, rc6's destructive example config provably never installed, and `/mnt/tank/media` read-only on both containers.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-20T22:08Z (approx, first host measurement 22:25Z)
- **Completed:** 2026-09-20T22:42Z
- **Tasks:** 3 of 3
- **Files modified:** 6 (2 compose files created, 2 modified, 2 artifacts created)

## Accomplishments

- **Ended a defer chain that ran Phase 4 → 5 → 6 (D-01).** Phase 6 now has both the configuration and the thing that executes it, proven together. A config validated against a runtime that will never run it proves the wrong thing.
- **`02-review` is empty, and reversibly so.** Its `Madonna/` and `Michael Jackson/` content — 533 files — moved to `04-hold` with an identical sha256 set and unchanged inodes, so registration could not enqueue two real preview tasks inside a phase whose premise is that it writes nothing.
- **rc6's destructive-default landmine never fired,** proven on two independent instruments rather than one.
- **One hostname now has exactly one router.** Verified three ways: the committed `beets.yaml` renders zero traefik labels, a sweep of every running container returns exactly one claimant, and Traefik answers 302 to Authelia rather than 200.

## Task Commits

1. **Task 1: D-35 — empty 02-review into 04-hold** — `9803100` (feat)
2. **Task 2: author flask.yaml and flask-config.yaml; correct beets.yaml** — `f1848e2` (feat)
3. **Task 3: deploy and first-start, with the four assertions** — `2676d5f` (feat)

## Files Created/Modified

- `stacks/selfhosted/arrs/beets/flask.yaml` — the active runtime. rc6 pinned with Phase 3's verified digest recorded; `BEETSDIR: /config`; both vendored configs `:ro`; `/media:ro`; `/logs` bound out of the writable layer; `t3_proxy` with no `ports:` key; traefik labels on port 5001.
- `stacks/selfhosted/arrs/beets/flask-config.yaml` — three inboxes and only three, `debounce_before_autotag: 30`, `gui.library.readonly: true`, `gui.terminal.enabled: false`, plus the D-08 read-only answer for Phase 9.
- `stacks/selfhosted/arrs/beets/beets.yaml` — three edits: D-12 purpose header, the dated D-05 correction, the D-07 label deletion.
- `stacks/selfhosted/arrs/compose.yaml` — `beets/flask.yaml` added to the include list; `beets/beets.yaml` stays commented out.
- `.planning/.../artifacts/06-04-inbox-before-after.txt` — manifests, counts, inode pairs, sha256 comparison, and the D-17/D-08 amendment note.
- `.planning/.../artifacts/06-04-first-start.txt` — the four assertions with their evidence and the complete, unexcerpted first-start log.

## Decisions Made

- **The D-05 correction was written as a dated retraction with the wrong sentence kept visible**, per this repo's standing style, rather than deleted. The reason is recorded with it: a comment promising `rw` in the current phase is an invitation to flip the flag one plan early and lose the only structural control that cannot fail open.
- **`flask.yaml` uses literal `TZ`/`PUID`/`PGID`.** See deviation 3 — the plan's sibling-`.env` premise is false for this directory, and the measurement is recorded in the file itself so nobody "fixes" it back to `$VAR`.
- **The host checkout was NOT brought up to date by `git pull`.** `origin/main` is still at `c67d497`; the whole of wave 1 is merged locally but unpushed. Pulling would have delivered nothing this plan needed, so the files were staged from committed blobs instead. Named follow-up below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `git pull --ff-only` cannot deliver files that were never pushed**
- **Found during:** Task 3, step 1
- **Issue:** The plan's deploy step reads the vendored configs out of `/mnt/fast/stacks` after a pull, and compares appdata against `git show HEAD:<path>` computed host-side. `git fetch` succeeded and showed `origin/main` still at `c67d497` — plan 06-01's config, and both of this plan's new files, exist only in local merges and in this worktree. The host's git can see neither.
- **Fix:** Extracted each file with `git show <commit>:<path>` — the committed blob, never the working-tree file — hashed it in the worktree, scp'd it to a host staging directory, re-hashed host-side, installed into appdata as `568:568`, then hashed the appdata copy and compared to the blob hash. The plan's actual intent survives: both sides of the comparison are a git blob hash, so the workstation's working tree is irrelevant. All four hashes matched.
- **Files modified:** none in the repo; `/mnt/fast/appdata/arrs/beets/config/config.yaml`, `.../beets-flask/config.yaml`, `/mnt/fast/stacks/stacks/selfhosted/arrs/beets/flask.yaml` on the host
- **Verification:** recorded hash-for-hash in `06-04-first-start.txt` § DEVIATION 1
- **Committed in:** `2676d5f`

**2. [Rule 3 - Blocking] LXC 100's python3 has no PyYAML**
- **Found during:** Task 3, step 1
- **Issue:** The host-side structural parse of the deployed config raised `ModuleNotFoundError: No module named 'yaml'` on python 3.13.5, aborting the deploy script mid-way (the configs were already in place and hash-matched at that point).
- **Fix:** Replaced the host-side parse with line-anchored greps over the known keys plus a size check against the 6,175 B stub it replaced. Nothing was installed on the host: the parse that matters is the one done by the interpreter that actually reads the file, and that runs inside the container as assertion 1's second instrument (`len(plugins) == 1`, value `['musicbrainz']`) — strictly better evidence.
- **Files modified:** none
- **Verification:** `06-04-first-start.txt` § STEP 1b and § DEVIATION 2
- **Committed in:** `2676d5f`

**3. [Rule 1 - Bug] The plan's sibling-`.env` premise is false for `beets/`**
- **Found during:** Task 2
- **Issue:** The plan directed `flask.yaml` to use `$TZ`/`$PUID`/`$PGID` "resolved from the gitignored sibling `.env` exactly as `beets.yaml:12-15` does". There is no `.env` in `stacks/selfhosted/arrs/beets/` — it lives one directory up — and compose resolves `.env` from the compose file's own directory. Reproduced twice against `beets.yaml` itself, from two different working directories: `The "TZ" variable is not set. Defaulting to a blank string.` for all three variables. A `flask.yaml` written as planned would have run with a blank TZ and blank PUID/PGID.
- **Fix:** literals, with the falsification written into the file so it is not re-broken. Confirmed by the rendered compose config and by `docker exec ... id` returning `uid=568(beetle) gid=568(beetle)`.
- **Files modified:** `stacks/selfhosted/arrs/beets/flask.yaml`
- **Verification:** rendered config captured in the artifact; runtime `id` captured in assertion 3
- **Committed in:** `f1848e2`

**4. [Rule 1 - Bug] My own assertion-4 instrument asked the wrong question**
- **Found during:** Task 3, step 2
- **Issue:** The dormant survivor was rendered with `docker compose config` and no `--profile manual`. It carries `profiles: ["manual"]`, so compose emitted `services: {}` and the `read_only` grep found nothing — reported as a FAIL when the true state was "could not look".
- **Fix:** re-ran with the profile, and additionally rendered the **committed** 06-04 `beets.yaml` alongside the host's current copy, so D-05 and D-07 are both evidenced against the version this plan actually produced. The first run is left in the artifact with its FAIL visible and the cause named.
- **Files modified:** none
- **Verification:** `06-04-first-start.txt` § STEP 2b — `read_only: true` in both renders, zero `beets.deercrest.info` in the 06-04 render
- **Committed in:** `2676d5f`

---

**Total deviations:** 4 auto-fixed (2 × Rule 3 blocking, 2 × Rule 1 bug)
**Impact on plan:** No scope change. Two were environmental facts the plan could not have known (unpushed main, missing PyYAML); one was a factual error in the plan that would have shipped a misconfigured container; one was my own instrument defect. Every assertion the plan asked for was still made, on the instrument the plan named or a strictly stronger one.

## Issues Encountered

- **A research expectation did not hold, in the safe direction.** 06-RESEARCH.md predicted that rc6's `run_migrations()` + `_open_library()` would move `library.db` and `state.pickle` on first start, and nominated the post-start pair as the D-29 layer 3 baseline. Measured: both files are byte-identical before and after, same inode, same mtime. The migrations rc6 logged were against its own sqlite job database under `/config/beets-flask/`, not beets' library. The post-start pair is still the baseline to quote — it now simply equals the pre-start pair.
- **rc6 created four new files in appdata on first start** (`beets-flask.db`, a timestamped sqlite backup, and two logs on the bound-out `/logs`). Recorded in the artifact so a future drift check does not read them as tampering.

## Known Stubs

None. Nothing in this plan renders placeholder data or leaves an unwired path.

## Threat Flags

None. The surfaces this plan introduces — the `beets.deercrest.info` router and the container's `/downloads:rw` mount — are both already in the plan's threat register (T-06-14, T-06-19) and both are mitigated as written there.

## Next Phase Readiness

**Ready for 06-05 onward.** The runtime exists, executes the Phase 6 config, and is reachable behind authentication. Specifically:

- **D-09 part 2 (inbox liveness by firing, not just registration)** is now runnable — `02-review` is empty, so the throwaway folder will be the only thing that ever transits it this phase. Wait longer than the 30 s debounce.
- **D-30 / D-29** have their instruments: the container is up, `/venv/bin/python` is the interpreter to use, and the library/state baseline pair is recorded.
- **06-06 is where rc6's eyconf schema validation first becomes observable** — and it already has: the watchdog registered all three inboxes, which is the direct evidence that `plugins: [musicbrainz]` in list form (D-10) was accepted.

Two things are explicitly NOT done and are somebody's next step:

1. **⚠ FOLLOW-UP — the host checkout must be repaired before its next `git pull`.** `/mnt/fast/stacks/stacks/selfhosted/arrs/beets/flask.yaml` is an UNTRACKED file there, byte-identical to blob `2f5df7cd…`. When Phase 6 is pushed and someone pulls, git will refuse with "untracked working tree file would be overwritten". Delete that one file first, then pull. The host also still carries the pre-06-04 `beets.yaml` and `compose.yaml`; that is inert today (the survivor is dormant, `flask.yaml` is started by its own `-f`) and the same pull fixes it.
2. **The Cloudflare CNAME for `beets.` is not proven.** The 302 was measured with `curl --resolve` against the host. No wildcard exists for `deercrest.info`, and a Traefik certificate is not evidence that DNS resolves. D-07's external half is outstanding.

**Expected red, not a regression:** `scripts/check-music-freeze.sh` expects `tagger definitions: 1` and there are now two. Plan 06-10 revises it to expect exactly two, named and classed. The red is recorded rather than pre-emptively silenced here.

## Self-Check: PASSED

All seven claimed files exist on disk, and all four claimed commits are present in this branch's
history (`9803100`, `f1848e2`, `2676d5f`, `4f64159`).

**Git delivery note:** this plan ran as a parallel executor in a worktree. STATE.md, ROADMAP.md and
REQUIREMENTS.md were deliberately NOT touched — the orchestrator owns those writes after the wave
merges. The four commits above live on `worktree-agent-acfb6c03d07531133` until then.

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-20*
