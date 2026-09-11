---
phase: 04-collapse-to-one-tagger
plan: 06
subsystem: health-check
tags: [health-check, census, negative-control, candidate, d-21, d-25, def-03-01]

# Dependency graph
requires:
  - plan: 04-03
    provides: "the repo-side retirement, so `tagger definitions` is already 1 in git"
  - plan: 04-01
    provides: "the ROUTINE BASELINE both checks are compared against, and the fence MANIFEST that names the Jellyfin positive-control database"
provides:
  - "check-music-freeze.sh section 6b: an all-states tagger census gated as a CANDIDATE (TAGGER_CENSUS_PROMOTED=0 / CENSUS_CANDIDATE=1)"
  - "is_tagger_mount(): behaviour-based tagger classification replacing the name-based TAGGER_PATTERN (DEF-03-01)"
  - "eight new summary counters, each printing UNKNOWN rather than 0 when its input was unobservable"
  - "quick-health-check.sh selector pre-widened to those counters, inert until 04-11 promotes 6b"
  - "six driven controls, each recorded firing and not firing"
affects: [04-07, 04-09, 04-11, 04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Candidate health check: a new assertion lands with an in-script PROMOTED=0 constant and runs only under an opt-in env var, so the routine result stays at its pre-phase baseline until the wave that makes the assertion true"
    - "Census positive control: a database known to exist under the search root is added to the candidate names for CONTROL ONLY, and its absence makes the whole census UNKNOWN rather than zero"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-06-SUMMARY.md
  modified:
    - scripts/check-music-freeze.sh
    - scripts/quick-health-check.sh

key-decisions:
  - "The prune list for the appdata walk is EMPTY, and that is a measurement: the full unpruned find returned RC 0 in 1 s across all of /mnt/fast/appdata including the 143 G hoarder tree. Every prune is a chance to drop the positive control, so none was added"
  - "Control (d) builds its scratch repo with `cp -a` + `chown`, not `git clone`: git honours safe.directory only from protected configuration, so the clone could not be authorised transiently and the alternative was mutating the host's global git config"
  - "lidarr appears in the tagger-capable inventory by RENAMER_PATTERN, exactly as the plan's own classifier clause specifies; the plan's parenthetical expectation of sabnzbd alone overlooked that clause"

requirements-completed: []  # TAGR-03/TAGR-04 are ADVANCED here, not satisfied: the census exists and is proven, but it is a candidate and the estate it guards is not yet retired.
requirements-advanced: [TAGR-03, TAGR-04]

# Metrics
duration: 38min
completed: 2026-09-11
---

# Phase 4 Plan 06: Behaviour-Based Tagger Census (Candidate) Summary

**`check-music-freeze.sh` can now see tagging state by what containers MOUNT rather than what they
are NAMED, across every container state — and it was driven red on the real estate before any
deletion, exiting exactly 1 in 6 s while naming all seven retired paths, all 26 beets databases and
`wrtag.db`. It does this as a CANDIDATE: the routine result of both health checks is byte-identical
to the 04-01 pre-phase baseline, measured before and after the fixture run.**

## Performance

- **Duration:** ~38 min
- **Started:** 2026-09-11T22:10Z (approx)
- **Completed:** 2026-09-11T22:35Z (approx)
- **Tasks:** 3 of 3
- **Files modified:** 2 repo scripts, plus this summary.

## Accomplishments

- **DEF-03-01 is closed in the instrument.** `TAGGER_PATTERN='beets|soulbeet|wrtag|lidarr'` could not
  see beets running inside `sabnzbd`; it reported `tagger-class writers: 0` while structurally blind.
  `is_tagger_mount()` now classifies by mount, and sabnzbd is correctly and permanently
  tagger-capable (Pitfall 15) while holding no `/mnt/tank/media` mount at any mode.
- **The `created`-state blind spot is closed for this assertion.** 6b enumerates `docker ps -aq`.
  A `created` fixture and an `exited` fixture were each caught holding rw.
- **Classification never authorises a write.** Every container in any state holding rw reaching
  Music fails, tagger-capable included (REVIEWS row 7); Jellyfin is the sole D-21 exception and is
  counted on its own line, so no total can read as a pass for the wrong reason.
- **It fails closed.** Blind docker, `find` RC outside {0,1}, timeout, or a missing Jellyfin
  positive-control DB each print `UNKNOWN` and increment `FAILURES`. Control (c) proved all four
  mount counters print `UNKNOWN` and never a bare `0`.
- **No red window.** REVIEWS row 1 is answered by the candidate gate rather than by accepting a
  five-wave red. Both routine checks exited 0 with exactly the baseline finding set, twice.

## Task Commits

1. **Task 1: section 6b, mount-based classifier, additive overrides.** `4b223fc`
2. **Task 2: pre-widen the quick-health-check selector.** `38cccc8`
3. **Task 3: fixture controls.** No commit — host-only fixtures, created and destroyed; transcripts below.

**Plan metadata:** this SUMMARY's own commit.

## Delivery

| Item | Value |
|---|---|
| Pushed | `d08842c..38cccc8  main -> main` |
| Host `/mnt/fast/stacks` HEAD before | `d08842c` |
| Host HEAD after `git pull --ff-only` | **`38cccc8`** (fast-forward, rc=0) |
| Host untracked files | the same 2 pre-existing (`prometheus.yaml.bak`, `monitoring.app.yaml.disabled`) before and after — not mine, left untouched |

The push carried all of wave 2's docs commits, as the orchestrator anticipated.

---

## Control (a) — CANDIDATE FIRST RUN on the un-retired estate (the driven negative control)

`cd /mnt/fast/stacks && CENSUS_CANDIDATE=1 bash scripts/check-music-freeze.sh`, 2026-09-11T22:23:15Z.

**RC = 1 exactly. ELAPSED = 6 s** (budget 60 s; REVIEWS row 17). **Prune list: empty** — the full
unpruned walk of `/mnt/fast/appdata` measured RC 0 in 1 s, so nothing needed pruning and the
positive control was never at risk. No `-xdev` (Pitfall 12).

Section 6b, ANSI stripped, otherwise unedited (the 26-path list abridged to its shape; the full list
is in the run and matches the 04-01 (d) table exactly):

```
🧮 6b. Tagger census (D-21, D-25)
  ✅ tagger definitions: expected=1 at stacks/selfhosted/arrs/beets/beets.yaml — found exactly that
  ❌ beets databases: expected=1 at /mnt/fast/appdata/arrs/beets/config/library.db — found 26:
         /mnt/fast/appdata/arrs/beets/config/library.db
         /mnt/fast/appdata/arrs/beets/config/musiclibrary.blb
         /mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db
         …11 × .config/beets/library.db-before-*.bak…
         …11 × scripts/library.blb-before-*.bak…
         /mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb
  ❌ tagger database PRESENT: /mnt/fast/appdata/media/wrtag/data/wrtag.db (target 0 …)
  other SQLite files matched by the candidate names (REPORTED, not failed …):
         /mnt/fast/appdata/media/jellyfin/data/jellyfin.db
  ❌ retired path PRESENT: /mnt/fast/appdata/media/wrtag
  ❌ retired path PRESENT: /mnt/fast/appdata/arrs/soulbeet
  ❌ retired path PRESENT: /mnt/fast/appdata/arrs/beets/config/musiclibrary.blb
  ❌ retired path PRESENT: /mnt/fast/appdata/arrs/beets/config/config.yaml.old
  ❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb
  ❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log
  ❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/.config/beets
  rw on Music, D-21 consumer exception: jellyfin [running] /mnt/tank/media:/media
  ✅ no container in any state holds rw reaching Music, apart from the D-21 consumer exception

  Tagger-capable inventory (mounts a beets/wrtag/soulbeet config or database — REPORTED):
      lidarr [running] — mode on Music: ro
      sabnzbd [running] — mode on Music: none
```

Summary counters from the same run:

```
  tagger definitions:          1   (target 1)
  beets databases:             26   (target 1 = SURVIVOR_DB)
  tagger databases:            1   (target 0 — wrtag.db*/soulbeet.db*)
  retired paths present:       7   (target 0)
  rw on Music, non-tagger:     0   (target 0, excluding the D-21 consumer exception)
  rw on Music, tagger-capable: 0   (target 0 — Phase 1 D-20, any container state)
  rw on Music, Jellyfin D-21:  1   (documented consumer exception, printed separately)
  tagger-capable containers:   2   (mounts a beets/wrtag/soulbeet config or DB; reported)
  FAILURES total:              9
```

Every retired path 04-01 recorded as present is named. The 26 beets databases are exactly 04-01's
two survivor DBs + 12 under `.config/beets/` + 12 under `scripts/`. `sabnzbd.ini.bak` and
`qBittorrent.conf.bak` were matched by the `*.bak` glob and correctly **excluded** — they are not
SQLite, which is why the header check exists. The Jellyfin positive control was found.

**This redness is the plan's own driven negative control against real state. It is expected, and it
was NOT "fixed" by touching the estate.** 04-07 and 04-11 do the deletions that turn it green.

## Control table — every control recorded both firing and not firing

| Control | Drives | Firing (red) | Not firing (green/baseline) |
|---|---|---|---|
| (a) real un-retired estate | the whole census | **RC 1**, 7 retired paths + 26 beets DBs + wrtag.db named, 6 s | (f) routine run, RC 0, no census output |
| (b) additive `RETIRED_DB_PATHS` | the override is additive, never replacing | **RC 1**, **8** retired-path fails = 7 built-in **+** `/mnt/fast/scratch-04/06/exists` named | (a) same run without the override: 7 fails, built-ins only |
| (c) blind docker (PATH stub, exit 1) | fail-closed on "could not look" | **RC 1**, `mount census: UNKNOWN — 'docker ps -aq' exited 1`; all 4 mount counters `UNKNOWN`, **0** bare zeros | (a) docker healthy: the same 4 counters print real numbers |
| (d) scratch-repo definition fixture | `tagger definitions = 1` (REVIEWS row 12) | **RC 1**, `tagger definitions: 2`, names `stacks/selfhosted/zz-fixture-04/fixture.yaml` | (a) real repo: `✅ … found exactly that`, count 1 |
| (e) `created` tagger fixture | rw-on-Music fails regardless of class/state (rows 7, 14) | **RC 1**, `❌ rw on Music: census-fixture-04 [created] … (tagger-capable)`, `rw on Music, tagger-capable: 1` | after removal, (f) post-fixture: counter absent, 0 residue |
| (e) `exited` tagger fixture | same, in a second non-running state | **RC 1**, identical fail line with `[exited]` | as above |

### Control (b) — additive override

```
  ❌ retired path PRESENT: /mnt/fast/appdata/media/wrtag
  …the six other built-ins…
  ❌ retired path PRESENT: /mnt/fast/scratch-04/06/exists
  retired paths present:       8   (target 0)
---- CONTROL-B RC=1 ----
```

The built-in list is intact and the scratch path is **added**, proving the override cannot shorten
or replace the census. No override in this plan can produce a pass.

### Control (c) — blind docker

```
  ❌ mount census: UNKNOWN — 'docker ps -aq' exited 1. No container was enumerated. This is NOT 'no container holds rw on Music'.
  rw on Music, non-tagger:     UNKNOWN
  rw on Music, tagger-capable: UNKNOWN
  rw on Music, Jellyfin D-21:  UNKNOWN
  tagger-capable containers:   UNKNOWN
---- CONTROL-C RC=1 ----
```

Four counters `UNKNOWN`, zero bare `0`s. "Could not look" stays distinct from "nothing is wrong".

### Control (d) — `tagger definitions` driven red

```
  ❌ tagger definitions: expected=1 at stacks/selfhosted/arrs/beets/beets.yaml — found 2:
         stacks/selfhosted/arrs/beets/beets.yaml
         stacks/selfhosted/zz-fixture-04/fixture.yaml
  tagger definitions:          2   (target 1)
---- CONTROL-D RC=1 ----
```

Host checkout porcelain byte-identical before and after. Nothing was committed or pushed from the
scratch repo.

### Control (e) — created, then exited, tagger-class fixture

```
fixture state: created
  ❌ rw on Music: census-fixture-04 [created] /mnt/fast/scratch-04/06/fakemusic:/media (tagger-capable)
      census-fixture-04 [created] — mode on Music: rw
  rw on Music, tagger-capable: 1   (target 0 — Phase 1 D-20, any container state)
---- CONTROL-E(created) RC=1 ----
fixture state now: exited
  ❌ rw on Music: census-fixture-04 [exited] /mnt/fast/scratch-04/06/fakemusic:/media (tagger-capable)
      census-fixture-04 [exited] — mode on Music: rw
  rw on Music, tagger-capable: 1   (target 0 — Phase 1 D-20, any container state)
---- CONTROL-E(exited) RC=1 ----
```

Safety properties held: image `lscr.io/linuxserver/beets:2.13.1-ls349` asserted **resident** before
`docker create --pull never` (nothing pulled), `--network none`, `--entrypoint true`, the **real
library was never mounted** — the fixture mounted a scratch directory declared as reaching Music
only through `CENSUS_EXTRA_LIBRARY_ROOTS` — and an `EXIT` trap guaranteed removal. Classification
came via the **underscore** `beets_config.yaml`, which is the soulbeet spelling REVIEWS row 14
flagged.

Teardown asserted producer-status-first: `docker ps -a` rc=0, positive control `sabnzbd` present,
`census-fixture-04` absent. Scratch removed behind an S5 realpath guard and asserted gone.

## ROUTINE PATH UNCHANGED (REVIEWS row 1) — the criterion this plan exists to protect

Measured twice: after the push, and again after the fixture run.

| Check | Where | 04-01 baseline | This plan, pre-fixture | This plan, post-fixture |
|---|---|---|---|---|
| `check-music-freeze.sh` (no env) | LXC 100 | RC **0**, no `❌`, 2 permanent mode `⚠️` | RC **0**, no `❌`, same 2 `⚠️`, `FAILURES total: 0` | RC **0**, no `❌`, same 2 `⚠️`, `FAILURES total: 0` |
| `quick-health-check.sh` (no env) | workstation | RC **0**, sole `❌` Traefik dashboard, no `⚠️` | RC **0**, sole `❌` Traefik dashboard, no `⚠️` | RC **0**, sole `❌` Traefik dashboard, no `⚠️` |

The routine host run prints `6b. Tagger census: CANDIDATE — not in the routine check until plan
04-11 promotes it (run with CENSUS_CANDIDATE=1)`, and leaks **zero** `retired path PRESENT` lines
and **zero** census counters. The fold-in still prints `✅ Intact` with exactly its four original
counters. **The finding set is identical to the baseline — not merely a subset.** No new red.

Section 1 is unchanged in behaviour despite the reclassification: `tagger-class writers: 0`,
`consumer-class writers: 1`, `unclassified writers: 0`, as at baseline. Jellyfin is not
tagger-capable, so it still classifies as the consumer.

## Deviations from Plan

### 1. [Rule 3 - Blocking] `git clone` of the host checkout is refused by git's `safe.directory`

- **Found during:** Task 3 control (d).
- **Issue:** the plan specifies `git clone --quiet --no-hardlinks /mnt/fast/stacks …`. It fails:
  `fatal: detected dubious ownership in repository at '/mnt/fast/stacks/.git'`. `/mnt/fast/stacks`
  is `apps:apps` and the census runs as root. The host's global config already lists
  `safe.directory=/mnt/fast/stacks` (twice) but **not** `/mnt/fast/stacks/.git`, which is the path
  the clone-as-remote `upload-pack` checks. `git -C … status` and `git pull` are unaffected, which
  is why nothing earlier in this phase hit it.
- **Fix:** built the scratch repo with `cp -a` + `chown -R root:root` **on the copy only**. It is a
  real repo at the same HEAD (`38cccc8`), so `git ls-files stacks` behaves identically and the
  control proves exactly what it was written to prove.
- **Rejected alternative:** `git -c safe.directory=…` and `GIT_CONFIG_COUNT=…` were both tried and
  both correctly ignored — git honours `safe.directory` only from *protected* configuration
  (system/global), specifically so it cannot be bypassed from the command line or environment.
  The remaining option was writing to the host's global git config, which is estate drift on a
  shared box for the benefit of one control; it was not done.
- **Downstream:** any later plan that wants a scratch clone of `/mnt/fast/stacks` on LXC 100 will
  hit this. Use the `cp -a` + `chown` shape, or add `/mnt/fast/stacks/.git` to the host's global
  `safe.directory` as a deliberate, separate change.

### 2. Defective assertion: Task 3's `<verify>` requires an empty host porcelain

- **Found during:** Task 3 acceptance.
- **Issue:** the `<verify>` runs `test -z "$(git -C /mnt/fast/stacks status --porcelain)"`. The host
  checkout carries **two pre-existing untracked files** (`prometheus.yaml.bak`,
  `monitoring.app.yaml.disabled`) that the orchestrator explicitly flagged as not mine. The literal
  test therefore **fails on a correct outcome** — executed and recorded: `test -z FAILED on a
  correct outcome (2 pre-existing untracked files)`.
- **Resolution:** recorded as defective rather than satisfied. The files were **not** deleted,
  staged, stashed or committed to make a grep pass. The correct assertion is *unchanged*, not
  *empty*, and it passes: `PORCELAIN-UNCHANGED (2 pre-existing untracked, not mine)` →
  `FIXTURES-CLEAN`, exit 0. Same class as 04-01's deviation 1.
- **Downstream:** 04-07, 04-11 and 04-13 should assert host porcelain is *unchanged from a recorded
  before-value*, never empty, until those two files are dealt with separately.

### 3. The plan's expected tagger-capable inventory omits its own `RENAMER_PATTERN` clause

- **Found during:** Task 2 control (a).
- **Issue:** Task 2 expects "sabnzbd listed as tagger-capable … (expected: sabnzbd, running, none)".
  The run reports **2**: `lidarr [running] — mode on Music: ro` and `sabnzbd [running] — mode on
  Music: none`. This is correct per Task 1's own specification — *"A container is tagger-capable if
  any of its mounts satisfies `is_tagger_mount` **OR its name matches RENAMER_PATTERN**"* — and
  `RENAMER_PATTERN='lidarr'`. The parenthetical simply overlooked the second clause.
- **Resolution:** no code change. sabnzbd **is** listed, which is what the acceptance criterion
  requires. lidarr holds `ro` on Music, so it fails nothing; the counter is REPORTED, not asserted.
- **Downstream:** 04-11 and 04-13 should expect `tagger-capable containers: 2`, not 1, unless
  lidarr's mount or the renamer clause changes.

### 4. [Rule 2 - Missing critical] The candidate gate needed a positive-control DB name

- **Found during:** Task 1.
- **Issue:** the plan mandates a Jellyfin positive control but names it only as "the path recorded
  in the Phase 1 fence MANIFEST". The MANIFEST records fence *copies*
  (`library-db/jellyfin-jellyfin.db`), which live under `/mnt/fast/safety` and are therefore
  outside `APPDATA_ROOT` and can never appear in this census.
- **Fix:** added `JELLYFIN_CONTROL_DB="jellyfin.db"` as a named constant and verified the **live**
  source exists inside the search root at `/mnt/fast/appdata/media/jellyfin/data/jellyfin.db`. It is
  control-only: it classifies as other-sqlite and is never counted as a beets or tagger database.
  Its absence sets `CENSUS_BLIND` and makes every DB counter `UNKNOWN`.

**Total deviations:** 4 — 1 blocking-path fix, 2 defective-assertion/imprecision records, 1
missing-critical addition. None weakens an assertion, and no control was made to pass by editing
prose or the estate.

## Threat Flags

None. No new network endpoint, auth path or trust boundary. The census reads SQLite strictly through
`file:…?mode=ro` URIs and the script remains read-only by contract.

## Issues Encountered

- **No release names or credentials were printed.** The census prints database *paths* under
  appdata only; it never reads a library table or a release folder name.
- The `find` walked the 143 G `hoarder` tree without pruning in 1 s (warm cache). If a future run
  is slow, prune only after re-measuring, and never at the cost of the positive control.

## Known Stubs

None. Section 6b is fully implemented; it is *gated*, which is a deliberate lifecycle state with a
named owner (04-11), not a stub.

## User Setup Required

None.

## Next Phase Readiness

- **04-07** (wrtag/soulbeet deletion): after it, expect `retired paths present` to drop from 7 to 3
  and `tagger databases` to 0. `beets databases` will **not** be 1 — it will still be ~24, because
  sabnzbd's `library.blb*` and `.config/beets/*` are genuine beets DBs until 04-11. This is REVIEWS
  row 9; do not "fix" the classifier to match a prose expectation.
- **04-11** owns the promotion: set `TAGGER_CENSUS_PROMOTED=1` in the commit where the candidate run
  is first green. `CENSUS_CANDIDATE` is then ignored and can never disable 6b. The
  `quick-health-check.sh` selector is **already widened**, so promotion is a one-file change.
  Runtime is 6 s against a 120 s `REMOTE_TIMEOUT`, so **no `REMOTE_TIMEOUT` change is needed**
  (REVIEWS row 17 closed).
- **04-13** can quote the D-25 counters from an executed run; control (a) above is that run's
  pre-retirement form.

## Self-Check: PASSED

- Both commits exist: `4b223fc` (check-music-freeze.sh) and `38cccc8` (quick-health-check.sh), and
  `38cccc8` is on `origin/main` and on the host.
- `bash -n` clean on `check-music-freeze.sh`; `/bin/bash -n` (3.2) clean on `quick-health-check.sh`.
- Acceptance greps: `TAGGER_PATTERN` non-comment 0; `docker ps -aq` non-comment 3; `-xdev` in 6b 0;
  `^echo "📊 7\. Summary"` 1; `TAGGER_CENSUS_PROMOTED=0` exactly 1; each of the three overrides in
  `${VAR:-}` form exactly 1; `SURVIVOR_DB`/`APPDATA_ROOT` override-form 0; all eight summary labels
  exactly once each in a non-comment `echo`.
- All six controls executed with exit codes captured; each recorded firing and not firing.
- Routine path RC 0 on host and workstation, before and after the fixture, with the baseline
  finding set exactly.
- Fixture container absent (producer-status-first, `sabnzbd` control present);
  `/mnt/fast/scratch-04` gone; host porcelain unchanged.
- STATE.md and ROADMAP.md untouched; no `gsd-sdk state.*` or `roadmap.*` verb was called.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-11*
