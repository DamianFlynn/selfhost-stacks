---
phase: 04-collapse-to-one-tagger
plan: 12
subsystem: infra
tags: [e2e, sabnzbd, criterion-3, d-12, d-31, evidence, watcher, open-verdict, host-readonly]

# Dependency graph
requires:
  - plan: 04-11
    provides: "the stripped audio.bash live on the host from a :ro mount, library.blb and beets.log deleted, both guards promoted into the routine fatal path"
  - plan: 04-01
    provides: "the D-12 pass contract written before any post-strip job, the storage-column mapping, the extended.conf baseline and the Audio.txt residual-line counts (98/87)"
provides:
  - "04-D12-EVIDENCE.md section 6 filled with exactly one verdict: OPEN, on two real post-strip music jobs"
  - "a measured mechanism for why a destination-tree watcher cannot take a PRE-HOOK snapshot before a SABnzbd post-processing hook, with the two changes that would close it"
  - "the correction that Audio.txt's `Replaygain Tagging: ENABLED` is a hardcoded literal at audio.bash:86 and not a reading of ReplaygainTagging (gate is line 325, case-sensitive `= TRUE`)"
  - "25 of 25 audio files byte-identical across the snapshot pair, 0 MUSICBRAINZ_* and 0 REPLAYGAIN_* keys, recorded as weaker evidence and explicitly not as the pass condition"
affects: [04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "An evidence watcher must be shown to be able to observe the event it is built for, not merely to run: this one ran for 2h24m, produced complete-looking artefacts on both jobs, and still could not satisfy the contract because its earliest possible sample is structurally later than the thing it samples"
    - "When an absence is read from a path, assert the path exists first: `wc -l` on a missing file prints nothing and a `$(...)` capture of it reads as 0, which is 'could not look' wearing 'nothing is there'"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-12-SUMMARY.md
  modified:
    - .planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md
  host-deleted:
    - "(host) /mnt/fast/scratch-04/12 — 29 files, 4 directories, then the empty parent /mnt/fast/scratch-04; file-by-file behind the S5 guard, no `rm -rf`"

key-decisions:
  - "Verdict recorded OPEN, not PASS. Every other pass condition in section 1 held and no condition was violated, but neither job's PRE-HOOK snapshot can be ordered before its `Matching` line, so 'untagged by bytes' is UNPROVEN and section 5 mandates OPEN"
  - "The absence of a regenerated beets database, the absence of MUSICBRAINZ_* keys and the Lidarr non-import were recorded as weaker, separate evidence and explicitly NOT used to upgrade the verdict"
  - "No snapshot was retro-fitted, no timestamp was reinterpreted, and the watcher was not re-armed to manufacture a second attempt inside this plan"

requirements-completed: []  # TAGR-04's behavioural half is NOT satisfied: criterion 3 is OPEN.
requirements-advanced: [TAGR-04]

# Metrics
duration: ~13min (Task 3); window open-to-close 2h24m
completed: 2026-09-13
---

# Phase 4 Plan 12: D-12 Real-Job Evidence Summary

**Two genuine music jobs completed fourteen seconds apart inside the evidence window, and every side-effect condition D-12 pre-declared in 04-01 held: no `library.blb`, no `library.blb*`, no `beets.log`, no new `.bak`, both folders left in `complete/nzb/music/`, both SAB rows the baseline `Exit(1): chmod …`, exactly the two pre-declared residual log lines per job and zero `SUCCESS: Matched with beets`, with `extended.conf` byte-identical open to close. Criterion 3 is nonetheless recorded `Verdict: OPEN` — because the one condition that had to be proven by bytes cannot be, and finding out why is the useful result: a watcher pointed at the completed-downloads tree can never sample a job before the hook, since SABnzbd moves the folder there and then immediately invokes the hook.**

## Performance

- **Duration:** Task 3 ~13 min. The window itself ran 2026-09-13T09:56:48Z → 12:21:30Z (2h24m).
- **Tasks:** 3 of 3 (Tasks 1 and 2 by prior executors / the operator).
- **Files:** 2 in the repo (1 modified by the task commit, plus this summary). On the host: 29 files and 5 directories deleted from scratch, nothing else written.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Arm the window (prior executor) | none — host-only |
| 2 | Operator triggers one music download | none — human checkpoint |
| 3 | Collect the evidence, compare bytes, assert the close, fill the Result | **`293fa35`** |

**Plan metadata:** this SUMMARY's own commit.

## Task 2: the operator's reply, recorded verbatim

> **"job bone 13:17"**

Quoted exactly as received. The evident reading is *"job done 13:17"* — a single-character typo, `bone`
for `done` — and the quote is left uncorrected because the plan asks for the reply verbatim. 13:17
Europe/Dublin is 12:17 UTC, which matches the first SAB row to the minute (12:17:59Z).

The operator also supplied a Lidarr screenshot showing the artist still at 0/10 and 0/15 tracks, i.e.
**Lidarr did not import**. That is context and is treated as context: it is consistent with the
folders being left in `complete/nzb/music/`, but it proves nothing about tagging and was not used in
the verdict.

## Re-derivation before acting

Every orchestrator-supplied figure was re-measured. **One was wrong, and it was the one the whole
verdict was expected to turn on.**

| Fact as handed to me | Re-derived 2026-09-13 | Verdict |
|---|---|---|
| Stamp `2026-09-13T09:56:48Z`, epoch `1789293408`, 0-byte marker | identical; inode 1049970 | confirmed |
| Two `category='music'` rows after the stamp, 12:17:59 and 12:18:13 UTC, both `Completed`, both baseline `Exit(1): chmod …` | identical | confirmed |
| sabnzbd beets state still 0 files | confirmed, with `audio.bash` visible as the positive control | confirmed |
| Watcher PID 765427 alive | alive, `bash watch-d12.sh`, parent `timeout 604800`, elapsed 02:18:33 | confirmed |
| **"`map.tsv` IS 0 LINES … probably NO valid PRE-HOOK snapshot for either job"** | **`watch/map.tsv` is 2 lines / 394 bytes, and BOTH jobs have `pre.sha256` AND `post.sha256`** | **REFUTED** |

**The `map.tsv` reading was an instrument failure read as a measurement.** `map.tsv` lives at
`…/12/watch/map.tsv`; the path `…/12/map.tsv` does not exist. Re-run deliberately to confirm the
mechanism: `wc -l < /mnt/fast/scratch-04/12/map.tsv` prints **nothing** and exits **1**, so a
`$(...)` capture yields the empty string, and anything comparing it numerically or printing it
alongside a label renders it as `0`. This is the estate's documented "silence read as clean" class in
a new costume, and it is exactly why the plan's own step (1) says to capture each producer's status
before reading its output.

**It mattered.** Had I accepted it, I would have recorded OPEN for a reason that is false ("no
snapshot was ever taken") and never found the real one ("the snapshot cannot be early enough"). The
verdict is the same word; the finding underneath it is not.

## The verdict, and how it was reached

`Verdict: OPEN — two music jobs completed in the window and every other pass condition held, but
neither job has a valid PRE-HOOK snapshot: job A's was taken after its `Matching` line and job B's
cannot be ordered against its own, so the "untagged by bytes" condition of § 1 item 4 is UNPROVEN and
§ 5 requires OPEN rather than PASS.`

Condition by condition, against the contract written in 04-01 before any job existed:

| § 1 condition | Held? | Evidence |
|---|---|---|
| 1. SAB row is the F8 baseline shape | **yes** | both rows `Completed`, both `script_line` begins `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2. No beets database or log activity | **yes** | `find …/scripts -newer <stamp>` RC 0 returns exactly one entry — the directory itself, the pre-declared § 2 `beets-match` transient. Name-targeted find for `library.blb*`/`beets.log`/`beets-match` RC 0, empty. `audio.bash` visible as positive control |
| 3. No `.bak` created | **yes** | `-newer` find RC 0, empty; whole-tree find RC 0 returns only `sabnzbd.ini.bak` (2026-08-17), the pre-declared exception, identical to Task 1's open listing |
| 4. **Untagged, proven by bytes** | **UNPROVEN** | 25/25 byte-identical, 0 changed, 0 deleted, 0 completion-only — but both snapshots of each pair were taken at or after the hook ran. See below |
| § 3 window prerequisite | **yes** | `extended.conf` sha256 `54c5433b…`, size 2,955, unchanged open → close; `grep -c '^ReplaygainTagging="false"'` = 1 |
| D-31 residual lines | **yes** | `tracks with Beets` 98→100, `Unable to match …` 87→89, `SUCCESS: Matched with beets` **0** |

**Nothing failed.** No byte changed, no unexpected `.bak` appeared, `extended.conf` did not move. So
this is not FAIL — a FAIL requires a violated condition, and there is none. It is OPEN because one
condition could not be evaluated at all.

### Why it could not be evaluated — the mechanism

SABnzbd moves a finished job into `/downloads/complete/nzb/music/` and **then** invokes the
post-processing hook. The watcher watches that destination tree, so its earliest possible sighting is
the moment the hook is already running. Measured:

| | job A | job B |
|---|---|---|
| hook's first log line (`Configuration:`) | 12:17:58Z | 12:18:10Z |
| watcher's first sighting of the folder | 12:18:00.074Z | 12:18:10.710Z |
| hook's `Matching N tracks with Beets` | **12:17:59Z** | **12:18:12Z** |
| PRE-HOOK snapshot time | **12:18:00.074Z** | **12:18:12.758Z** |
| ordering | snapshot **after** the line → invalid | same one-second bucket → **indeterminate** → invalid |
| SAB row completed | 12:17:59Z | 12:18:13Z |

Two independent reasons, either sufficient:

1. **The watcher cannot see the folder before the hook starts**, because the move into the watched
   tree *is* the hook's trigger.
2. **The contract's own stability rule adds a floor.** § 1 item 4 requires the first *stable*
   snapshot — two consecutive agreeing passes at least 2 s apart — so there is a 2–4 s minimum between
   first sighting and snapshot. Job A's hook ran from first log line to SAB completion in **one
   second**. No 2-second stability floor fits inside that.

`Audio.txt`'s one-second timestamp resolution is a third, smaller obstacle for job B specifically: its
snapshot at 12:18:12.758Z falls inside the same second as its `Matching` line, so even a sub-second
watcher clock cannot order the pair against a log that does not record sub-seconds.

**What would close it** (recorded for 04-13 and whoever carries criterion 3 forward): snapshot in
`/downloads/incomplete/` before the move — bytes are final after unpack, and the hook has not been
invoked — or drop the stability wait and snapshot on first sighting, accepting a possible retake. Both
are watcher changes. **Neither requires touching the estate**, and neither is in this plan's scope.

### What was deliberately NOT used to upgrade the verdict

Per the plan and REVIEWS row 11, absence of a regenerated database is separate, weaker evidence than
the byte proof — not a substitute. The following are recorded as such and none was allowed to move
OPEN to PASS:

- no beets state reappeared anywhere under sabnzbd `/config`;
- `quick-health-check.sh` still reports `beets databases: 1`;
- 0 `MUSICBRAINZ_*` keys across all 25 files;
- Lidarr imported nothing.

No snapshot was retro-fitted, no timestamp reinterpreted, and the watcher was not re-armed to
manufacture a second attempt.

## The byte comparison, in full

| | job A | job B | total |
|---|---|---|---|
| files in both snapshots | 10 | 15 | **25** |
| byte-identical (sha256) | 10 | 15 | **25** |
| changed (would be FAIL) | 0 | 0 | **0** |
| PRE-only, deleted by `clean()` | 0 | 0 | **0** |
| COMPLETION-only | 0 | 0 | **0** |
| of which MOVED (§ 1's flatten clarification) | 0 | 0 | **0** |
| genuinely new at COMPLETION (would be FAIL) | 0 | 0 | **0** |

`clean()` deleted nothing and flattened nothing on either job, so neither pre-declared clarification
from 04-01 had to be exercised. File positions, not names, were used throughout; the mapping never
left host scratch.

ffprobe tag keys at COMPLETION, identical across every file of each job, with **0 `MUSICBRAINZ_*`**
and **0 `REPLAYGAIN_*` / `R128_*`** of 25:

- job A: `ALBUM, ARTIST, DATE, GENRE, ORGANIZATION, TITLE, TRACKTOTAL, album_artist, disc, track`
- job B: `ALBUM, ARTIST, COMMENT, COMPILATION, COPYRIGHT, DATE, DISCTOTAL, ENCODED-BY, PUBLISHER, RELEASECOUNTRY, TITLE, WORK, album_artist, disc, track`

The PRE-HOOK tag-key set is the same set **by construction** — the bytes are identical — and that is
stated rather than a second ffprobe pass being run and presented as independent corroboration.

## The watcher's own state at stop

- **It had not exited on its own.** `kill -0` succeeded; `ps` showed `bash watch-d12.sh` (PID 765427)
  under `timeout 604800 bash watch-d12.sh` (PID 765425), elapsed 02:18:33.
- `watch.log` reads `2026-09-13T12:18:00.514Z BOTH SNAPSHOTS PRESENT — exiting at epoch 1789302180`,
  i.e. it was scheduled to self-exit at **12:23:00Z** after its 5-minute linger. It was stopped ~90 s
  before that.
- `SIGTERM` was sufficient: `kill -0` failed 3 s later and no `watch-d12` process remained
  (`grep` exit 1). No `SIGKILL` was needed.
- **`watch.out` is 0 bytes and `watch/watch.err` is 0 bytes.** Byte counts are quoted because an empty
  error log and an unreadable one look the same; both were `stat`ed, both exist, both are genuinely
  empty. The watcher logged no error in 2h24m.
- The launcher's recorded PID and the script's self-recorded PID agree (765427). The watcher wrote its
  own PID into `$OUT/watch.pid` precisely because `setsid` may fork and the launcher's `$!` is not
  reliably the script — that defence worked.

## Cleanup

`/mnt/fast/scratch-04/12` removed behind the S5 guard: 29 files deleted individually after a
`realpath -e` containment check (0 refused), 4 directories by `rmdir` deepest-first, then the
now-empty parent `/mnt/fast/scratch-04` by `rmdir`. **No `rm -rf` was executed.** Both asserted
absent, with `/mnt/fast/stacks` and `/mnt/fast/appdata` printed as positive controls so the absence is
a reading rather than a failure to look. The job→folder mapping went with it.

## Deviations from Plan

### 1. [Defective assertion — recorded, NOT satisfied] Task 3 step (7)'s `grep -cx`

- **Issue:** the plan's step (7) asserts `grep -cx 'ReplaygainTagging="false"'` = 1. Line 27 of
  `extended.conf` carries a trailing comment on the same line, so `-cx` (whole-line match) returns
  **0 on the correct outcome**. Measured both ways this run: `-cx` → **0**, anchored
  `grep -c '^ReplaygainTagging="false"'` → **1**.
- **Resolution:** the anchored form was used and the plan's form is recorded as defective.
  **`extended.conf` was not edited to satisfy a grep** — its sha256 and mtime had to be unchanged, and
  they are (`54c5433b…`, `2025-10-24T08:41:54Z`, 2,955 B). This was pre-flagged by the Task 1
  executor and is confirmed here rather than re-discovered.

### 2. [Orchestrator fact refuted] `map.tsv` is not empty, and the reason is an instrument failure

- **Issue:** I was told `map.tsv` is 0 lines and that there was probably no valid PRE-HOOK snapshot for
  either job. `watch/map.tsv` is **2 lines**, and both jobs carry `pre.sha256` and `post.sha256`.
- **Mechanism:** the measured path was `…/12/map.tsv`, which does not exist; the file is at
  `…/12/watch/map.tsv`. `wc -l` on the missing path prints nothing and exits 1, which renders as `0`.
- **Recorded rather than quietly corrected**, because the false reading and the true one produce the
  *same verdict word* by different routes, and only one of them is a finding.

### 3. [Measured finding] `Audio.txt` says `Replaygain Tagging: ENABLED` while `extended.conf` says false

- **Issue:** both jobs logged `Replaygain Tagging: ENABLED`, which reads as the § 3 window prerequisite
  failing. It is not.
- **Measured against the live vendored hook:** the string is a **hardcoded literal at `audio.bash:86`,
  inside `if [ "${ConversionFormat}" = FLAC ]`** — it never consults `ReplaygainTagging`. The real gate
  is line **325**, `if [ "${ReplaygainTagging}" = TRUE ]`, a case-sensitive test against the bare word
  `TRUE` which `"false"` cannot satisfy.
- **Corroborated independently**, not by reading the gate alone: ffprobe shows **0 `REPLAYGAIN_*` /
  `R128_*` keys across all 25 files**. `replaygain()` did not run.
- **Why this is recorded prominently:** § 3's entire rationale is that `replaygain()` is the only other
  tag writer in the hook and that `ReplaygainTagging="false"` keeps it off. A future reader meeting
  that log line would reasonably conclude the prerequisite was violated and that PASS was unavailable
  for a second, wrong reason.

### 4. [Instrument limit, recorded] `Audio.txt` has one-second resolution

- The contract requires `pre.time` < the `Matching` line time. `pre.time` is millisecond-resolution;
  `Audio.txt` is second-resolution. For job B the two fall in the same second, so the comparison is
  undecidable *even in principle* with these two instruments. Job A is decided (and fails) on whole
  seconds alone, so this limit is not load-bearing for the verdict — but it would be if the watcher
  were made fast enough to land in the right second.

### 5. [Pre-existing, not mine] Host porcelain is non-empty by design

- `prometheus.yaml.bak` and `monitoring.app.yaml.disabled` remain untracked and untouched. Any
  assertion demanding an empty host porcelain remains defective (04-06 deviation 2, 04-11 deviation 10).
- The host checkout is at `763b851`; the workstation is at `62d71a7` (the orchestrator's wave-6
  tracking commit). No repo script was run host-side by this plan, so no `git pull` was required and
  none was performed. `quick-health-check.sh` ran from the **workstation**; its freeze fold-in runs the
  host's copy, which carries 04-11's promoted guards (`2572b71`, an ancestor of `763b851`).

---

**Total deviations:** 5 — 1 defective plan assertion recorded, 1 refuted orchestrator fact with its
mechanism, 1 measured correction to a contract rationale, 1 instrument limit, 1 pre-existing condition.
**No assertion was weakened, no file was edited to make a check pass, no evidence was fabricated, and
the verdict was not upgraded on inference.**

## Threat Flags

None. This plan added no network endpoint, auth path or trust boundary. Against the plan's register:

- **T-04-12-01 (release names leaking into a public repo)** — mitigated. The evidence file and this
  summary identify jobs by a 12-character sha256 prefix of the folder name. `script_line` is truncated
  at 60 characters, which stops before the release name; `storage` is quoted as the 30-character
  prefix `/downloads/complete/nzb/music/` only. The `Audio.txt` lines quoted are the two pre-declared
  residual lines, which carry no path. The `Verified Track:` lines, which do carry track names, were
  read and deliberately not quoted. The job→folder mapping existed only in host scratch and was
  deleted with it.
- **T-04-12-02 (SAB API key)** — no API was called. History was read via `sqlite3 "file:…?mode=ro"`.
  Nothing was triggered, cancelled or paused in SABnzbd or Lidarr; the jobs were the operator's.
- **T-04-12-03 (a false pass)** — the pass condition was fixed in 04-01 before any job existed and was
  not edited. The verdict is OPEN with the failing clause named.
- **T-04-12-04 (the watcher)** — read-only throughout, writes confined to scratch, 0-byte error log,
  bounded by `timeout 604800`, stopped by `SIGTERM` and removed.

## Known Stubs

None. `04-D12-EVIDENCE.md` § 6 is filled; zero `PENDING — filled by 04-12` markers remain.

## Issues Encountered

- The transcript of this execution necessarily contained two release folder names (the find listing
  and the `ls` of `watch/`). Neither reached the repo, this summary or the evidence file. Subsequent
  reads hashed the names.
- `/mnt/tank/downloads/incomplete`'s 6 stale January orphan directories were not touched.

## Next Phase Readiness

- **04-13 must not treat criterion 3 as passed.** `04-D12-EVIDENCE.md` carries exactly one verdict
  line and it reads `Verdict: OPEN`. Per REVIEWS row 6, 04-13 writes an **interim status** section,
  not a Phase 4 closure, unless and until criterion 3 reads PASS.
- **Criterion 3 is re-runnable cheaply and the blocker is known.** The estate side is ready — the
  stripped hook is live from a `:ro` mount and every side-effect condition held on two real jobs. Only
  the watcher needs changing (watch `incomplete/`, or drop the stability wait). A fresh window needs
  one more organic or operator-triggered music job.
- **Do not re-derive the ReplayGain question.** `audio.bash:86` is a literal; the gate is line 325.
- **Both standing guards remain green** after two real music jobs: routine `quick-health-check.sh`
  exit 0, census counters at target, drift `✅ vendored files match (3)`.

## Self-Check: PASSED

- FOUND `.planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md`; `grep -cE '^Verdict: (PASS|OPEN|FAIL)'` = **1**, `grep -c 'PENDING — filled by 04-12'` = **0**.
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-12-SUMMARY.md`.
- FOUND commit `293fa35`, touching exactly one file: `04-D12-EVIDENCE.md`.
- `/mnt/fast/scratch-04/12` and `/mnt/fast/scratch-04` both absent, with two positive controls visible; no `watch-d12` process remains.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were **NOT** modified by this plan, and no `gsd-sdk query state.*` or `roadmap.*` verb was called.
- No commit deleted any tracked file. Only explicit paths were staged; the working tree's other files were left as found.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-13*
