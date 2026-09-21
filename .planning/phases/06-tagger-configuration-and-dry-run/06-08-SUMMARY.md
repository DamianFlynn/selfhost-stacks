---
phase: 06-tagger-configuration-and-dry-run
plan: 08
subsystem: tooling
tags: [beets, beets-flask, incremental, negative-control, d-31, conf-02, docker-exec]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-04's running beets-flask rc6 runtime (beets 2.12.0) and the D-29 layer 3 baseline pair this plan asserts against"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-07's A3 verdict — a `-c` overlay is honoured and is NOT run through rc6's eyconf validation — which is what licences the in-place `copy: no, move: no` arms"
provides:
  - "scripts/phase06-incremental-control.sh — the two-arm negative control for the incremental_skip_later trap, with a --self-test that drives every refusal and every blind branch"
  - "a firing observation for D-31 / CONF-02: the trap FIRES with the key absent and is DEFEATED with it set, from a one-key difference"
  - "a reusable, deterministic, OFFLINE beets import harness (`plugins: []` makes the recommendation never `strong`, so quiet_fallback always fires)"
  - "the measured correction that the container's /tmp is the docker overlay, not LXC 100's tmpfs"
  - "the measured fact that the real /config/state.pickle is an EMPTY-state pickle — the real library has never recorded incremental history"
affects: [06-09, 06-10, 06-12, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Make a control's two arms one key apart by CANONICALISING the incidental difference away and requiring byte-identity, not by counting diff lines — a line count passes a stray whitespace edit"
    - "Read runtime state out of the store itself, and keep ABSENT, EMPTY and UNREADABLE as three distinct outcomes"
    - "Pre-seed a store symmetrically in both arms when the negative arm would otherwise leave no file at all, so 'nothing recorded' cannot read as 'could not look'"
    - "Ship remote programs on stdin with their arguments as positional parameters, never interpolated — the container's /bin/sh is dash and has no pipefail"
    - "Use a store's own sha256 as a second witness, so the verdict does not depend on interpreting its contents"

key-files:
  created:
    - scripts/phase06-incremental-control.sh
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-08-incremental-control.txt
  modified: []

key-decisions:
  - "Both arms PRE-SEED an identical empty state pickle, because with incremental_skip_later: yes beets never creates the file at all and 'empty' would otherwise be indistinguishable from 'could not look'"
  - "The skip is forced by `plugins: []` rather than by a weak MusicBrainz match, so the control's outcome cannot move with a third party's database"
  - "The one-key assertion is made by canonicalising arm B's root onto arm A's and requiring byte-identity, which is strictly stronger than a diff-line count"
  - "T-06-39 re-scoped on measurement: the container's /tmp is the docker overlay, not tmpfs, so the hazard is 25 G of free disk on LXC 100's root, not host RAM"

patterns-established:
  - "Establish a mechanism in a throwaway probe FIRST, then write the committed control against what was measured — so the control is not retuned after seeing its own result"
  - "Record an instrument defect in the plan's own verification line rather than quietly satisfying it"

requirements-completed: [CONF-02, CONF-06]

# Metrics
duration: 40min
completed: 2026-09-21
---

# Phase 6 Plan 08: The D-31 negative control Summary

**The sharpest trap in the criterion set was made to fire and made not to fire from a one-key
difference: with `incremental_skip_later` absent a skipped folder is permanently marked done and
never re-offered; with it set the same folder comes back — proven by reading `taghistory` out of
the pickle, on the first run of the committed script, with the real `library.db` and
`state.pickle` unmoved throughout.**

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-09-21T02:30Z
- **Tasks:** 2 of 2
- **Files created:** 2 (1 script, 1 artifact)

## Accomplishments

- **CONF-02 is discharged by a firing observation, not a read-back.** This project's standing rule
  — stated separately in Phases 2, 02.1 and 4 — is that reading a setting back is not proof it
  applies. Arm A's `taghistory` came back `{(b'/tmp/p6a/src',)}` after a *skip*, and the re-run
  answered `Skipped 1 paths.` with nothing offered. Arm B's came back empty and the same folder was
  re-offered by name. One key apart; opposite outcomes.
- **A second witness that needs no interpretation of the pickle at all.** The statefile's own
  sha256 moves off the seed in arm A (`f6a9a1ad…` → `c68dde1f…`) and stays on it in arm B. If
  someone later distrusts the python probe, the hashes alone carry the finding.
- **The control is deterministic and offline.** `plugins: []` means no metadata source, so the
  recommendation can never be `strong` and `quiet_fallback` always fires
  [`beets/ui/commands/import_/session.py@2.12.0:328-360`]. A control whose outcome moves with what
  MusicBrainz happens to return today is not a control — and MusicBrainz coverage of this backlog
  is exactly the thing this project already knows to be patchy.
- **Every refusal and every blind branch is driven by `--self-test`,** with no ssh and no docker,
  including the case a diff-line count would have passed: two overlays one key apart *plus* a stray
  trailing-space edit.
- **D-29 layer 3 held across seven readings.** Real `library.db` and `state.pickle` identical to
  plan 06-04's named post-first-start baseline at every sample point, with `state.pickle`'s mtime
  still at 2025-11-18 — the exact warning sign 06-RESEARCH.md Pitfall 4 names.

## Task Commits

1. **Task 1: the two-arm control script** — `5494a3c` (feat) — `scripts/phase06-incremental-control.sh`
2. **Task 2: both arms run and recorded** — `34ddb39` (feat) — `artifacts/06-08-incremental-control.txt`

## Files Created

- `scripts/phase06-incremental-control.sh` — one script, two invocations. Generates both overlays
  itself (so they cannot drift from the arms that use them), asserts they are exactly one key
  apart, refuses a dirty destination, copies the fixture (never moves it), seeds an empty state
  file, runs the real in-place import that skips, reads `taghistory` out of the pickle, re-runs
  with `--pretend` for the offered/not-offered question only, and asserts the source tree and the
  real beets state are both untouched. `--self-test`, `--baseline` and `--cleanup` modes.
- `.planning/.../artifacts/06-08-incremental-control.txt` — both overlays verbatim, the
  canonicalised one-key diff, both import transcripts, both `taghistory` readings, both re-run
  verdicts, the source manifests, the D-29 readings at all sample points, the cleanup proof and
  the `--self-test` inventory.

## Decisions Made

- **Both arms pre-seed an identical empty state pickle.** Measured before writing the script: with
  `incremental_skip_later: yes` beets never *creates* the statefile — nothing is recorded, so
  `_save()` is never called. Left alone, arm B's expected result would have been an *absent* file,
  which makes "taghistory is empty" and "I could not look at taghistory" the same observation. That
  is the exact collapse this repo forbids, inside the assertion the plan exists to make. The seed
  is the identical structure beets' own `_save()` writes, applied by the same code in both arms, so
  it cannot flatter either one.
- **The skip is forced structurally, not by a weak match.** `plugins: []` rather than "point it at
  something MusicBrainz won't recognise".
- **The one-key assertion is canonicalise-then-compare**, not a diff-line count. The three path
  keys must differ (separate throwaway trees), so a naive count of two changed lines would also
  accept two overlays that differ in the key *and* in whitespace. The self-test drives that case.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] The negative arm leaves no statefile, collapsing "empty" into "could not look"**
- **Found during:** Task 1 design, from a throwaway probe run before the script was written
- **Issue:** The plan says "arm B must show `taghistory` empty". Measured: with
  `incremental_skip_later: yes` beets does not create `state.pickle` at all. An absent file would
  have been reported by any honest fail-closed instrument as UNKNOWN, not as empty — so arm B could
  never have produced the plan's stated expected outcome, and a less careful instrument would have
  reported "empty" for a file it never opened.
- **Fix:** both arms write a readable `{"tagprogress": {}, "taghistory": set()}` pickle before their
  import, by the same code, so the difference between the arms remains exactly one config key. Arm B
  then gives a positive reading (readable, zero entries).
- **Files modified:** `scripts/phase06-incremental-control.sh`
- **Verification:** arm B's `TAGHISTORY EMPTY 0` with `PROBE-RC 0`, and its statefile sha256 equal to
  the seed; the `--self-test` keeps `absent` and `empty` as distinct classifications
- **Committed in:** `5494a3c`

**2. [Rule 1 - Bug] The plan's tmpfs premise is false**
- **Found during:** Task 1, environment probe
- **Issue:** The plan and threat T-06-39 state that the container's `/tmp` is tmpfs on LXC 100 and
  that trees left there consume host RAM. Measured: `df /tmp` inside the container reports
  `overlay 126G 95G 25G 80% /` and `mount` shows no tmpfs at `/tmp`. LXC 100's *own* `/tmp` is
  tmpfs — that is the 1.1 GB EPG incident — but a `docker exec` never touches it.
- **Fix:** the hazard is re-scoped in the script's own header and in the artifact to what it
  actually is: 25 G of free space on LXC 100's 126 G ext4 root, the same filesystem six stacks
  already write to silently. Cleanup is still mandatory and was still performed and asserted.
- **Files modified:** `scripts/phase06-incremental-control.sh` (header), artifact § 10(a)
- **Verification:** `df`/`mount` output quoted in the artifact; `/tmp/p6a` and `/tmp/p6b` confirmed
  gone from a separate ssh session
- **Committed in:** `5494a3c`, `34ddb39`

**3. [Rule 3 - Blocking] The container's `/bin/sh` is dash, which has no `pipefail`**
- **Found during:** Task 1, environment probe
- **Issue:** The house rule is `set -o pipefail` inside every remote string. `/bin/sh -> dash` in
  this image, and dash rejects `set -o pipefail`. A remote program written to the house rule would
  have run with the option silently unset.
- **Fix:** the remote programs contain no pipeline whose failure could be swallowed; every
  instrument's exit status is read into a variable on the following line. They are also shipped on
  stdin with their arguments as *positional parameters* rather than interpolated, so a folder name
  containing spaces and brackets cannot break out of a command line.
- **Files modified:** `scripts/phase06-incremental-control.sh`
- **Verification:** `shellcheck -S error` clean; both arms ran against a source folder whose name
  contains spaces, parentheses and square brackets
- **Committed in:** `5494a3c`

### Recorded, not fixed

**The plan's own verification line is loose.** `grep -n 'timeout \$REMOTE_TIMEOUT.*|' …` returns two
lines — but only because `.*|` also matches the `||` in `|| RE_RC=$?`. Neither line contains a pipe;
both redirect to files and read the exit status explicitly. The check's *intent* is satisfied. This
is written into the artifact (§ 10(d)) rather than worked around, because a future reader will run
the same grep and should not spend time on it.

---

**Total deviations:** 3 auto-fixed (1 × Rule 2, 1 × Rule 1, 1 × Rule 3), 1 recorded
**Impact on plan:** No scope change. Every assertion the plan asked for was made, on the instrument
the plan named or a strictly stronger one. Deviation 1 is the only one that changes what was run,
and it does so symmetrically in both arms, so the one-key invariant is intact.

## Issues Encountered

- **The seed hash collides with the real state file, and that is a finding.** The empty-state pickle
  both arms write hashes to `f6a9a1ad…`, which is byte-identical to the real
  `/config/state.pickle` (47 B, mtime 2025-11-18). The real library has never recorded any
  incremental history. Useful for Phase 7: the first real `incremental` run starts from a genuinely
  clean slate, and any future non-`f6a9a1ad…` value on that file is evidence that a run happened.
- **A sibling's temp file is visible in the container's `/tmp`.** `phase06-check-beets-config-noop.yaml`
  belongs to plan 06-06, not to this plan; recorded in the artifact so a future drift check does not
  read it as this plan's litter.

## Known Stubs

None. Nothing here renders placeholder data or leaves an unwired path. Both arms ran against real
files in the real container and produced measured outcomes.

## Threat Flags

None new. The surfaces this plan touches — the `rw` downloads mount and the real beets state files —
are both already in the plan's threat register (T-06-36, T-06-37) and both were mitigated as written
there. One register entry is re-scoped on measurement rather than added:

| Flag | File | Description |
|------|------|-------------|
| threat_flag: rescope | scripts/phase06-incremental-control.sh | T-06-39 ("/tmp trees consume LXC 100 RAM") is wrong as written: the container's /tmp is the docker overlay, not tmpfs. The mitigation (remove both trees, assert absence) is unchanged and was performed; only the stated consequence moves from host RAM to 25 G of free disk on LXC 100's root. |

## Next Phase Readiness

**Ready.** The trap is proven to fire and proven to be defeated, so Phase 6's `incremental` +
`incremental_skip_later` pairing is now evidence-backed rather than configured-and-hoped.

Carry-forward for later plans:

1. **`scripts/phase06-incremental-control.sh` is a reusable offline beets harness.** The overlay
   shape (`library` + `statefile` + `directory` + `plugins: []`) plus the `sh -s` positional-argument
   transport is the pattern any further throwaway import should copy. It is the only shape that
   cannot poison the real `state.pickle`.
2. **`-l` alone remains the live footgun.** Anything in Phase 7 that reaches for a throwaway library
   must set `statefile:` too, or it writes the shared pickle.
3. **The real `state.pickle` is empty.** If it ever stops hashing to `f6a9a1ad…`, a real import has
   run. That is a cheap, precise drift signal worth adding to a consumer check.

## Self-Check: PASSED

- `scripts/phase06-incremental-control.sh` — FOUND (955 lines, mode 755)
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-08-incremental-control.txt` — FOUND
- commit `5494a3c` — FOUND in this branch's history
- commit `34ddb39` — FOUND in this branch's history

**Git delivery note:** this plan ran as a parallel executor in a worktree. `STATE.md`, `ROADMAP.md`
and `REQUIREMENTS.md` were deliberately NOT touched — the orchestrator owns those writes after the
wave merges. The commits above live on `worktree-agent-ac7bccfda57719c66` until then.

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-21*
