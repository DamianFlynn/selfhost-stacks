---
phase: 04-collapse-to-one-tagger
plan: 08
subsystem: tagger-config
tags: [beets, probe, vendoring, survivor, mb-only, d-27, f14, tagr-05]

# Dependency graph
requires:
  - plan: 04-03
    provides: "the survivor definition at 2.13.1-ls349, with restart/profiles/:ro settled, as the file this plan inserts a mount into"
  - plan: 04-06
    provides: "the recorded ROUTINE freeze value (`declared rw reaching Music: 0`) this plan's section-2 comparison is made against"
provides:
  - "scripts/spike03-discogs-probe.py --mb-only: 8 guarded Discogs sites, incl. the INVERSE refusal (1b) that refuses when `discogs` IS loaded"
  - "stacks/selfhosted/arrs/beets/config.yaml: the vendored survivor beets config (plugins: musicbrainz, library: /config/library.db, 3x SAFE-01 auto: no)"
  - "beets.yaml: the appdata config.yaml bind-mounted :ro over /config/config.yaml, as a pure insertion"
  - "driven MB-only refusal transcripts, recorded both firing and not firing, with the control proven non-vacuous"
affects: [04-09, 04-10, 04-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mode-narrowing by parameterisation, never by weakening: the narrowed gate must be stated on the command line and the refusal TEXT narrows with it, so an MB-only transcript never names the dismissed credential"
    - "An inverse refusal placed immediately after the authoritative plugin reading and before any network call, so a mislabelled measurement is stopped before it can issue one request"
    - "A non-vacuous plugin control needs a fixed non-credential literal: without a user_token the discogs plugin raises during setup and does not load, which would make a refuse-if-loaded control pass for the wrong reason"

key-files:
  created:
    - stacks/selfhosted/arrs/beets/config.yaml
    - .planning/phases/04-collapse-to-one-tagger/04-08-SUMMARY.md
  modified:
    - scripts/spike03-discogs-probe.py
    - stacks/selfhosted/arrs/beets/beets.yaml

key-decisions:
  - "The SAFE-01 block is carried over near-verbatim but its embedart trailing parenthetical ('This was already `no` on the host') is DROPPED: it is a true statement about the sabnzbd host original and a false one about this authored file"
  - "The compose gate ran host-side after the push rather than before the commit, because the workstation Docker daemon is not running (macOS). Recorded as an ordering deviation, not skipped"
  - "The MB-only summary gained an annotation beyond the plan's list: LOOSE/STRICT score Discogs only and are 0 BY CONSTRUCTION in this mode, so a reader cannot take that zero for a MusicBrainz result"

requirements-completed: []  # TAGR-05 is ADVANCED, not satisfied: the survivor's config declares musicbrainz in git, but it is not installed on the host (04-09) and sabnzbd's config is still deliberately `plugins: embedart` until 04-11, because D-17's negative control must run against the LIVE broken config first.
requirements-advanced: [TAGR-05]

# Metrics
duration: ~25min
completed: 2026-09-11
---

# Phase 4 Plan 08: MB-only Probe Mode and the Vendored Survivor Config Summary

**The criterion-4 probe can now prove MusicBrainz behaviour without ever reading the dismissed Discogs credential, and its new refuse-if-discogs-is-loaded branch was driven on the real image — refusing with exit 2 while naming `discogs` as genuinely loaded, and paired with a run that did not refuse. The survivor's beets config now declares `musicbrainz` in git and is bind-mounted `:ro`, inserted without moving a byte of D-02 or D-20.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-09-11 (~22:45Z)
- **Tasks:** 2 of 2
- **Files:** 1 created, 2 modified (plus this summary)

## Accomplishments

- **F14 is closed in the instrument.** The probe hard-required `DISCOGS_USER_TOKEN` and called the
  Discogs identity endpoint unconditionally. All eight sites named in `04-PATTERNS.md` are now
  guarded, and the default path is provably unchanged.
- **The new branch was seen to fire, on the real image.** REVIEWS row 13 flagged that 04-08's smoke
  only exercised the missing-env path. The refusal was driven with a config that genuinely loads
  `discogs`, and the transcript proves the control was not vacuous (`actually loaded: discogs,
  musicbrainz`).
- **The credential was never involved.** No Discogs token exists in the repo, in any config, in any
  probe default, or in any transcript. The control used a fixed non-credential literal under
  `--network none`.
- **TAGR-05 is now checkable in git for the survivor.** Before this plan the survivor had no beets
  config to check: the live host file is a pasted compose service definition with no `plugins:`,
  `library:` or `directory:` key at all (F4).
- **No estate change and no lane crossing.** No host appdata was written, no DNS, no image, no
  GitHub issue. The only host contact was `git pull --ff-only`, read-only checks, and container
  runs that were `--rm --pull never --network none`.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | `--mb-only` mode, every Discogs site guarded (F14) | `9e3b84d` |
| 2 | Vendored survivor config (D-27) + its `:ro` bind mount | `2f19e29` |

**Plan metadata:** this SUMMARY's own commit.

## Delivery

| Item | Value |
|---|---|
| Pushed | `38cccc8..2f19e29  main -> main` |
| origin `refs/heads/main` | `2f19e299522841755b48133ae5fb728c10a54d67` |
| Host `/mnt/fast/stacks` HEAD before | `38cccc8` |
| Host HEAD after `git pull --ff-only` | **`2f19e29`** (Fast-forward, `pull_rc=0`) |
| Host untracked files | the same 2 pre-existing (`prometheus.yaml.bak`, `monitoring.app.yaml.disabled`), before and after — not mine, untouched |

The pull carried wave 2's docs commits and `04-06-SUMMARY.md` alongside this plan's two commits.

---

## Task 1: `--mb-only`

### The eight guarded sites

| Site | Guard |
|---|---|
| `REQUIRED_ENV` (:273) | `required_env(mb_only)` returns `REQUIRED_ENV_MB_ONLY = ("SPIKE_CONFIG", "SPIKE_DB")` |
| `require_env()` (:461-483) | takes `mb_only`; no token lookup, nothing appended to `SECRETS` |
| refusal-3 message text | branched — an MB-only refusal never names the dismissed credential |
| `config["discogs"]["user_token"]` (:505) | inside `if not mb_only:` |
| refusal 1 (:521) | gains **1b**, the inverse, immediately after `loaded = sorted(...)` |
| identity probe (:895) | `if args.mb_only:` → `identity = None`, no request issued |
| `discogs.index_tracks` / `search_limit` (:897-898) | guarded; both emit `null` in every record |
| banner (:938-940) + summary (:1072) + epilog (:816-820) | print `MB-only: no identity probe` and state the mode's requirements |

### Mechanical checks

| Check | Result |
|---|---|
| `python3 -m py_compile` | exit **0** |
| `grep -c -- '--mb-only'` | **12** |
| `grep -v '^\s*#' … \| grep -c 'mb_only'` | **15** (acceptance ≥ 7) |
| `git diff --numstat` | 154 insertions, 30 deletions |

**Default path unchanged, verified by reading the diff, not asserted:** every functional edit is
inside `if mb_only` / `if not mb_only` / `if args.mb_only`+`else`, or is a signature whose default
(`mb_only=False`) preserves prior behaviour. The two `else` branches reproduce the original banner
and summary lines exactly, in the same order and spacing.

### Driven control, both ways — workstation, before the push

`require_env()` runs before any beets import, so this is measurable off-host.

```
--mb-only, no SPIKE_* env            -> rc=2
REFUSING TO RUN: required environment variable(s) not set: SPIKE_CONFIG, SPIKE_DB
  MB-only mode: SPIKE_CONFIG and SPIKE_DB are the ONLY required variables, and
  they must name the THROWAWAY spike paths, never the image defaults (Pitfall 1).
  No Discogs credential is required, read or sent in this mode.
  ASSERT ok: names SPIKE_CONFIG      ASSERT ok: does NOT name DISCOGS_USER_TOKEN

default mode, no SPIKE_* env         -> rc=2   (the pair that must still name it)
REFUSING TO RUN: required environment variable(s) not set: SPIKE_CONFIG, SPIKE_DB, DISCOGS_USER_TOKEN
  ASSERT ok: default path unchanged, still names DISCOGS_USER_TOKEN
```

No ledger file was created by either run (`/tmp/x.done`, `/tmp/x.failed` both absent) — the
refusal precedes the ledger open, as designed.

### (s) In-image smoke — `lscr.io/linuxserver/beets:2.13.1-ls349`, `--network none`

Image residency asserted first: `sha256:159e62e4d611…` (`--pull never` used regardless).

```
REFUSING TO RUN: required environment variable(s) not set: SPIKE_CONFIG, SPIKE_DB
  MB-only mode: SPIKE_CONFIG and SPIKE_DB are the ONLY required variables, …
  No Discogs credential is required, read or sent in this mode.
smoke_rc=2
ASSERT ok: names SPIKE_CONFIG
ASSERT ok: does NOT name DISCOGS_USER_TOKEN
```

---

## Task 2: the vendored survivor config

### (r) The MB-only refusal control — REVIEWS row 13, driven both ways

Fixtures in `/mnt/fast/scratch-04/08/`, never in the repo and never under appdata. The
`user_token` is the fixed non-credential literal the plan specifies, and it is **load-bearing**:
without a token the discogs plugin raises during setup and does not load, which would make the
control pass for the wrong reason.

**FIRING** — `--mb-only --require-plugin musicbrainz`, `SPIKE_CONFIG=/s/discogs-loaded.yaml`:

```
REFUSING TO RUN: --mb-only was requested but the `discogs` plugin IS loaded.
  requested by config: musicbrainz, discogs
  actually loaded:     discogs, musicbrainz
  config: /s/discogs-loaded.yaml
  MB-only exists so this phase's criterion-4 probe measures MusicBrainz WITHOUT
  the dismissed Discogs credential (D-24). With `discogs` built, candidates from
  Discogs would be counted inside a run labelled MusicBrainz-only.
  Remove `discogs` from the config's `plugins:` line, or drop --mb-only. Do NOT
  weaken this branch: it is the only thing making the mode's name true.
---- CONTROL-R(firing) RC=2 ----
ASSERT ok: exit 2
ASSERT ok: names discogs
ASSERT ok: discogs IS among loaded plugins (control is not vacuous)
ASSERT ok: does NOT name DISCOGS_USER_TOKEN
-- ledger records (expect none) --  led.done / led.failed: No such file or directory
```

**NOT FIRING** — the paired positive, identical but `plugins: musicbrainz` and no `discogs:`
mapping:

```
  plugins loaded:    musicbrainz
  plugins REQUIRED:  musicbrainz  <-- NARROWED from discogs + musicbrainz
  MB-only:           no identity probe, no Discogs request, no token read (F14 / D-24)
ERROR spike03-probe probe failed /s: ValueError
  folders failed (.failed):     1
  MB-only:                      no identity probe, no `discogs` config key read
  discogs HTTP responses seen:  0  (expected 0 in MB-only)
  discogs new connections:      0  (expected 0 in MB-only)
---- CONTROL-R(paired positive) RC=1 ----
ASSERT ok: NOT refused for discogs
```

Exit 1 with `ValueError` is the expected later stop: `/s` holds the two yaml fixtures and no audio,
and the probe refuses a zero-audio folder to the failed ledger rather than scoring it zero. **Zero
Discogs responses and zero connections in the mode's own counters** — the run reached the folder
loop without contacting Discogs.

**Teardown:** S5 guard (`realpath` equals `/mnt/fast/scratch-04/08` exactly, `..` refused), removed,
asserted gone, with `/mnt/fast/stacks` still visible as the positive control that we could still look.

### (y) In-image YAML key list

```
['embedart', 'lastgenre', 'library', 'plugins', 'scrub']
```

Exactly the five expected keys — nothing else leaked in. Values: `plugins = 'musicbrainz'`,
`library = '/config/library.db'`, all three `auto` keys parse to `False`.

### Static acceptance

| Check | Result |
|---|---|
| `grep -cx 'plugins: musicbrainz'` | **1** |
| `grep -cx 'library: /config/library.db'` | **1** |
| `grep -c 'auto: no'` | **3** |
| non-comment `/mnt/tank/media` in config.yaml | **0** (and 0 including comments — the string does not appear at all) |
| `grep -cE '^\s*image:'` in config.yaml | **0** |
| new mount line in beets.yaml | **1** |
| `/mnt/tank/media:/media:ro` · `restart: "no"` · `profiles: ["manual"]` | **1 · 1 · 1**, byte-unchanged |
| `git check-ignore` | empty (rc 1) |
| `docker compose … --profile manual config --quiet` (host) | exit **0** |

**beets.yaml is a pure insertion:** `git diff --numstat` = `31 0`, and removed non-context lines = **0**.

### (c) Routine freeze run — within the 04-01 ROUTINE BASELINE

`bash scripts/check-music-freeze.sh`, no env, stdin closed, bounded Linux-side at 150 s.

```
freeze_rc=0
  declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
counts: ❌=0   ⚠️=2
  ⚠️  directory mode: 88 differ from 755 — REPORTED not asserted (D-12 scoped out, chmod impossible on tank)
  ⚠️  file mode: 2586 differ from 644 — REPORTED not asserted (D-12 scoped out, chmod impossible on tank)
  6b. Tagger census: CANDIDATE — not in the routine check until plan 04-11 promotes it (run with CENSUS_CANDIDATE=1)
retired_path_lines=0
  tagger-class writers: 0 · consumer-class writers: 1 (Jellyfin, D-21) · unclassified: 0
  FAILURES total: 0
✅ Music freeze harness intact
```

`declared rw reaching Music` = **0**, equal to 04-06's recorded routine value. The new yaml adds no
library mount, as intended. Exit code and the `❌`/`⚠️` set are exactly the 04-01 baseline: no `❌`,
and only the two permanent mode reports. 6b stayed dormant and leaked no census rows.

---

## Deviations from Plan

### 1. [Ordering] The compose gate ran host-side after the push, not before the commit

- **Found during:** Task 2, at the gate step.
- **Issue:** the plan gates on `docker compose … config --quiet` before committing. The workstation
  is macOS and its Docker daemon is not running (`dial unix …/docker.sock: no such file or
  directory`), so the gate is not runnable locally at all.
- **Resolution:** run on LXC 100 after the pull, where the daemon is live. It returned **0**. Had it
  failed, the fix and a re-commit would have preceded every run that follows it — nothing was
  executed against the definition before the gate passed.
- **Downstream:** any plan gating on `docker compose` must expect to run it host-side.

### 2. [Harness correction] `bash -s` over ssh: `check-music-freeze.sh` consumes the rest of the script

- **Found during:** Task 2 (c), first attempt.
- **Issue:** the first routine run printed its header and then **nothing** — no `freeze_rc`, no
  summary. The check contains `while IFS='|' read` loops, and with the remote script arriving on
  **stdin** via `bash -s`, the check read the remainder of that script as its own input. The tail of
  the harness was eaten rather than executed. The check itself is read-only, so nothing on the
  estate was mutated; what was lost was the measurement.
- **Resolution:** re-ran with `</dev/null` on the check invocation. This is the `ssh -n` hazard in a
  different shape — `-n` cannot be used when the script is itself delivered on stdin.
- **Recorded rather than worked around:** the first run's silence was NOT read as "nothing is
  wrong". It was treated as "could not look" until a clean run produced the numbers.
- **Downstream:** 04-09/04-11 run host scripts the same way. Either redirect the inner command's
  stdin, or `scp` the script and run it by path.

### 3. [Faithful adaptation] One sentence of the SAFE-01 block was dropped

- The sabnzbd original ends its `embedart` comment with *"(This was already `no` on the host — the
  only one of the three that was.)"*. That is a true statement about **that** host file and a false
  one about this **authored** file, which had no host original to inherit from. Dropped rather than
  copied. The block header also attributes the 2026-08-18 measurement to plan 01-07 and says it is
  carried over. The three keys and their explanatory comments are otherwise verbatim; `auto: no`
  count is 3.

### 4. [Addition, Rule 2] The MB-only summary states what its zeros mean

- `score_folder()` filters on `source == "Discogs"`, so `LOOSE`/`STRICT` are **0 by construction** in
  MB-only mode. A transcript showing `LOOSE 0` could be misread as "no candidates found". The
  summary now says so explicitly and points the reader at the NDJSON `source` field, which is what
  04-09 counts. Beyond the plan's literal site list, and the exact class of silently-wrong zero this
  instrument exists to prevent.

### 5. [Minor] `git rev-parse origin/main` exited 128 after a successful push

- The push itself reported `38cccc8..2f19e29  main -> main`. The follow-up `rev-parse` failed with
  `Needed a single revision`. Delivery was confirmed independently with
  `git ls-remote origin refs/heads/main` → `2f19e29…`, and by the host's fast-forward pull. A
  reporting artifact, not a delivery failure.

**On the plan's own `<verify>`:** its `grep -v '^\s*#'` form is GNU-flavoured, but BSD grep on this
workstation handled `\s` correctly — both that form and `[[:space:]]` returned 0. Not defective here;
noted because it is environment-dependent.

**Total deviations:** 5 — 1 ordering, 1 harness correction, 1 faithful adaptation, 1 Rule-2
addition, 1 reporting artifact. None weakens an assertion, and no control was made to pass by
editing prose or the estate.

## Threat Flags

None — no new network endpoint, auth path or trust boundary.

The register's four entries were each mitigated and measured:

- **T-04-08-01 (Discogs token disclosure):** MB-only never reads the variable, never appends to
  `SECRETS`, and refuses if the plugin is loaded. The control ran with `--network none` and a fixed
  non-credential literal. `grep` for a token-shaped assignment across the changed files: clean. The
  literal `phase04-fake-not-a-credential` appears in the repo **only** in `04-08-PLAN.md`, where the
  planner put it; this plan wrote it to host scratch, which was then deleted.
- **T-04-08-02 (survivor config tampering):** the three SAFE-01 keys are present and `no`; the mount
  is `:ro`; the `/mnt/tank/media` string does not appear in the file at all.
- **T-04-08-03 (privilege via beets.yaml):** pure insertion, 0 lines removed; `restart: "no"`,
  `profiles: ["manual"]` and `/mnt/tank/media:/media:ro` byte-unchanged. Nothing grants rw on Music.
- **T-04-08-04 (compose render leaking `.env`):** every compose invocation used `--quiet`.

## Known Stubs

None. Two things are deliberately *named forward* rather than stubbed, and both say so in the files
themselves:

- The **vendored-file drift check** referenced in `config.yaml`'s header does not exist yet. The
  header states that plainly — 04-10 builds it as a candidate, 04-11 promotes it — rather than
  implying a guarantee already in force.
- The **`:ro` boot behaviour is unmeasured.** LinuxServer's `lsiown -R abc:abc /config` may log
  EROFS against a single-file mount. The `beets.yaml` NOTE says UNMEASURED and assigns it to 04-09.

## Issues Encountered

- No release names, credentials or `.env` contents were printed at any point.
- The host checkout's two pre-existing untracked files were left exactly as found; a host
  `git status --porcelain` is therefore non-empty by design, and any assertion demanding an empty
  porcelain would be defective (04-06 deviation 2).

## Next Phase Readiness

- **04-09** has everything it needs: `--mb-only` exists and its gate control is proven; the repo
  `config.yaml` is ready to `cp` onto the host at `/mnt/fast/appdata/arrs/beets/config/config.yaml`;
  the `:ro` mount is declared. Two notes for it:
  - its Task 2 (f)(2) gate control expects a refusal naming **musicbrainz** (broken.yaml has
    `plugins: embedart`, so `discogs` is absent and **1b does not fire** — refusal 1 does). Verified
    compatible: 1b fires only when `discogs` is loaded.
  - `-c` overlays merge over `/config/config.yaml`, and that base now has a `plugins:` key where
    research assumed none. The overlay's `plugins:` line overrides it, so broken/fixed still differ
    by exactly one line — but 04-09 should record which base config was mounted during each run, as
    `04-PATTERNS.md` § No Analog Found already requires.
- **04-10** can now write the drift block against three real vendored files; `config.yaml` is the
  third.
- **04-11** installs sabnzbd's fixed config. Until then, sabnzbd's `beets-config.yaml` is still
  `plugins: embedart` **on purpose** — D-17's negative control must run against the live broken
  config first, so C4-a is not satisfiable before 04-11.

## Self-Check: PASSED

- FOUND commit `9e3b84d`; FOUND commit `2f19e29`; both on `origin/main` (`2f19e299522841…`) and on
  the host at `2f19e29`.
- FOUND `scripts/spike03-discogs-probe.py`, `stacks/selfhosted/arrs/beets/config.yaml`,
  `stacks/selfhosted/arrs/beets/beets.yaml`.
- `py_compile` 0; in-image YAML key list exactly `['embedart','lastgenre','library','plugins','scrub']`;
  compose `config --quiet` 0; `git check-ignore` empty.
- Both new controls recorded firing and not firing; the firing one proven non-vacuous.
- Routine freeze run RC 0 with `declared rw reaching Music: 0`, equal to 04-06's value, and exactly
  the 04-01 baseline finding set.
- No host appdata, DNS, image or GitHub-issue change was made; host scratch removed and asserted gone.
- `git diff 1a9ceea HEAD -- .planning/STATE.md .planning/ROADMAP.md` is **empty**; no `gsd-sdk
  state.*` or `roadmap.*` verb was called.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-11*
