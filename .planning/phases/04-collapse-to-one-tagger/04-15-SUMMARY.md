---
phase: 04-collapse-to-one-tagger
plan: 15
subsystem: infra
tags: [e2e, sabnzbd, criterion-3, d-12, d-31, evidence, watcher, open-verdict, host-readonly, gap-closure]

# THE WINDOW-2 VERDICT WORD, for plan 04-16 which selects beets.md's heading from it
window2_verdict: OPEN

# Dependency graph
requires:
  - plan: 04-14
    provides: "watch-d12b.sh and judge-d12b.sh at the sha256 values this plan asserted before arming, the eight-control self-test record, and the D-12 contract amended and committed BEFORE this window's stamp"
  - plan: 04-12
    provides: "window 1's measured mechanism, the six deviations re-read as traps, and the Audio.txt closing totals (100/89/0) this window's delta was cross-checked against"
provides:
  - "04-D12-EVIDENCE.md section 7 — the window-2 record, one `Verdict (window 2): OPEN` line and the machine-readable OBS block that supports it, committed BEFORE host scratch was deleted"
  - "the measured reason the incomplete-tree design still cannot see a real job: under direct_unpack=1 the extracted audio is either never visible to a 1-second poll of incomplete/ (2 of 3 jobs) or still growing when SABnzbd moves it (1 of 3)"
  - "a third independent clean side-effect set on three more real post-strip music jobs — 0 library.blb, 0 .bak, 0 beets.log, 0 SUCCESS: Matched with beets, extended.conf never written"
  - "the exclusion, with five measurements, of a BYTES-OK the judge returned on a history row that no longer exists and whose hook never ran"
affects: [04-16]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "An empty script exits 0 and prints nothing. A transfer that silently produced a 0-byte script therefore reads as a successful cleanup — assert the transferred artefact's size before executing it, never its exit code afterwards"
    - "BSD sed on macOS silently ignores `\\b`, so a screening filter written with word boundaries does not run and its output looks like a finding. Prove a screen discriminates with a positive AND a negative control before believing its number"
    - "A judge that decides one clause is not a verdict. judge-d12b.sh returned BYTES-OK on a row whose history entry no longer exists and whose hook never ran; excluding it was the executor's job, exactly as the judge's own header says"
    - "`find -newer <stamp>` cannot locate files a downloader moved: SABnzbd preserves posted file times, so freshly-landed audio is older than the window that landed it"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-15-SUMMARY.md
  modified:
    - .planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md
  host-deleted:
    - "(host) /mnt/fast/scratch-04/15 — 101 files, 13 directories, file-by-file behind the S5 fence with realpath -e, directories by rmdir deepest-first"
    - "(host) /mnt/fast/scratch-04/watch-d12b.sh, judge-d12b.sh, selftest-14.txt, then the empty parent. No `rm -rf` was executed"

key-decisions:
  - "Verdict recorded OPEN, not PASS and not FAIL. All three post-stamp music jobs are STATUS=UNPROVEN reason=no-attributed-pre with a zero-file intersection, and section 5's amended window rule resolves OPEN on the first UNPROVEN"
  - "The judge's one BYTES-OK was EXCLUDED from the job set on five measurements. Counting it would not have changed the verdict, but it would have put an unearned BYTES-OK in a public record"
  - "READ 1 was re-run WINDOW-BOUNDED (completed > open AND completed <= close) after the first read exposed a 4-vs-3 discrepancy, so the job set is reproducible against a live estate that kept completing jobs"
  - "The clean side-effect evidence was recorded separately and was explicitly NOT allowed to upgrade the verdict, for the third window running"

requirements-completed: []  # TAGR-04's behavioural half is NOT satisfied: criterion 3 remains OPEN.
requirements-advanced: [TAGR-04]

# Metrics
duration: ~50min (Task 3); window open-to-close 22m50s
completed: 2026-09-13
---

# Phase 4 Plan 15: D-12 Window 2 Summary

**Three real music jobs completed inside the second observation window and every side-effect condition D-12 pre-declared held for the third window running — no `library.blb`, no `library.blb*`, no `beets.log`, no new `.bak`, exactly the two pre-declared residual log lines per job and zero `SUCCESS: Matched with beets`, with `extended.conf` provably never written. Criterion 3 is nonetheless recorded `Verdict (window 2): OPEN`, because none of the three published a PRE-HOOK snapshot: under `direct_unpack=1` two of them never exposed a single audio file to a 1-second poll of the incomplete tree, and the third was still growing when SABnzbd moved it, its one hash attempt refused mid-pass by the instrument's own protocol. That is plan 04-14's explicitly carried-forward HIGH residual risk firing on real jobs, and it failed safe exactly as designed — UNPROVEN, never FAIL.**

## Performance

- **Duration:** Task 3 ~50 min. The window itself ran 2026-09-13T22:04:18Z → 22:27:08Z (22m50s).
- **Tasks:** 3 of 3 (Task 1 by a prior executor, Task 2 the operator's act).
- **Files:** 2 in the repo (1 modified by the task commit, plus this summary). On the host: 101 files and 13 directories deleted from scratch, plus 3 parent-level files and the parent itself.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Arm window 2 behind a single fail-closed gate (prior executor) | none — host-only, no repo file modified (04-12 Task 1 / 04-14 Tasks 1-2 precedent) |
| 2 | Operator triggers one music download | none — human checkpoint |
| 3 | Query history first, judge the bytes, write § 7, then clean up | **`4a4543f`** |

**Plan metadata:** this SUMMARY's own commit.

## Task 2: the operator's reply

Recorded verbatim except for **one** redaction, applied on orchestrator instruction because this
repository is public and 04-16's own `must_have` bars release names from entering it:

> **"job done 23:20 [artist name redacted — public repo] 2 different albums"**

That redaction is the **only** alteration. The operator's timing and phrasing are otherwise
uncorrected, keeping the precedent 04-12 set when it recorded *"job bone 13:17"* exactly as received.

**The timezone conversion, stated separately rather than silently applied:** the operator gave a
local time and said so. `23:20` is Europe/Dublin, which is on IST (UTC+1) on 2026-09-13, so it
converts to **2026-09-13T22:20Z** — about 16 minutes after the stamp. The three measured rows
completed at 22:17:48Z, 22:21:07Z and 22:21:54Z, bracketing it.

**The reply was treated as a signal to collect, never as evidence about what arrived.** It reports
*two* albums; READ 1 measured **three** `category='music'` rows. The record follows the measurement.

## The verdict, and how it was reached

`Verdict (window 2): OPEN — three music jobs completed in the window and every side-effect condition
and both ends of the § 3 prerequisite held, but none of the three published a PRE-HOOK snapshot …`

Condition by condition, against the contract as amended by 04-14 and committed at `0022e91`
— committer epoch `1789336341`, **717 seconds earlier than the stamp**, and an ancestor of HEAD:

| § 1 condition | Held? | Evidence |
|---|---|---|
| 1. SAB row is the F8 baseline shape | **yes** | all three `Completed`, all three `script_line` begins `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2. No beets database or log activity | **yes** | `find …/scripts -newer <stamp>` RC 0 returns exactly one entry — the directory itself, the pre-declared § 2 `beets-match` transient. Name-targeted find across all of `/config` RC 0, empty. `audio.bash` visible as positive control |
| 3. No `.bak` created | **yes** | `-newer` find RC 0, empty; whole-tree find RC 0 returns only `sabnzbd.ini.bak` (9,837 B, 2026-08-17), the pre-declared exception |
| 4. **Untagged, proven by bytes** | **UNPROVEN ×3** | no job published a PRE-HOOK snapshot; `files_in_both=0` on all three. See below |
| § 3 window prerequisite | **yes** | `grep -c '^ReplaygainTagging="false"'` = 1; sha256 and size equal to the 04-01 baseline; and `find … -newer <stamp>` returned nothing, so the file was **never written during the window at all** — a stronger proof than comparing two reads |
| D-31 residual lines | **yes** | `tracks with Beets` **+3**, `Unable to match …` **+3**, `SUCCESS: Matched with beets` **0**. Deltas equal `jobs`, derived two independent ways that agree |

**Nothing failed.** No byte changed, no unexpected `.bak` appeared, `extended.conf` did not move. So
this is not FAIL — a FAIL requires a violated condition and there is none. It is OPEN because the one
condition that had to be proven by bytes could not be evaluated on any of the three jobs.

## Why no PRE-HOOK snapshot exists — measured per poll, not inferred

04-14 flagged this precisely: *"whether a real job's inventory actually holds still for
`STABLE_PASSES` consecutive polls under `incomplete/`"* — a known limit, not an assumed capability.
The window was armed at `POLL_FS=1`, half the default, specifically to attack it. Reconstructed from
each job's own poll trail (entry counts and audio-file counts per poll; names never read):

| | job 209cc6020f24 | job b5a3ff6815c4 | job 227d31189be6 | *(excluded row)* |
|---|---|---|---|---|
| polls under `incomplete/` | 4 | 41 | 67 | 63 |
| lifetime there | 3.1 s | 44 s | 80 s | 66 s |
| longest run of identical inventories | 1 | 5 | 19 | **57** |
| **audio files at any poll** | **0** | **0** | 4 → 35 | 15 |
| longest stable run **with audio present** | **0** | **0** | **2** | **57** |
| outcome | never stable | no audio ever visible | attempted once, **refused** | published, `pre_complete=yes` |

Two distinct mechanisms, both structural:

1. **Two of three never showed a single audio file under `incomplete/`.** For job `b5a3ff6815c4` the
   destination folder was first seen **5.2 s before** the incomplete folder disappeared, and that
   folder's final observed inventory was **empty**. Job `209cc6020f24` existed under `incomplete/`
   for **3.1 seconds in total**, with `postproc_time=0`. The gate requiring a non-empty audio list
   can never open.
2. **The one job that did show audio was still growing when it was moved.** Its count climbed 4 → 35
   then fell to 0 over its last 9 polls. It reached two agreeing passes once and the hash pass was
   **refused by the watcher's own protocol** — inventory 62 → 19 across the pass, 45 files vanished
   underneath it (`hash.err` 3,063 B / 45 lines, every one `sha256sum: … No such file or directory`,
   44 on a `.flac`). That is 04-14's SC-7 control firing on a real job: no snapshot, rather than a
   snapshot that had straddled the move.

**The excluded row is the positive control this window would otherwise have lacked:** when a folder
genuinely rests under `incomplete/` — 57 consecutive identical inventories, 15 audio files present —
the instrument publishes, and publishes complete. **The watcher works as specified.** What is
unproven is the estate's behaviour, not the instrument's.

## ⚠ The judge returned BYTES-OK, and it was excluded — with five measurements

The watcher attributed **four** history rows (`rows_seen=4`) and `judge-d12b.sh` returned
**`STATUS=BYTES-OK`**, 15 of 15 byte-identical, `pre_complete=yes`, on one of them. It is not one of
the three jobs, and this is recorded prominently rather than quietly dropped, because a BYTES-OK
sitting in host scratch is exactly what a later reader would use to argue the window passed:

1. READ 1, re-run window-bounded against the live database, returns **3** rows. A query for that
   row's exact `completed` value across **every** category returns **0**; a query for its recorded
   `storage` string returns **0**. **The row no longer exists in SABnzbd's history.**
2. Its `storage` parent is `/mnt/tank/downloads/incomplete` — **not** `complete/nzb/music/`. Both its
   snapshots were taken from the same incomplete folder 1.26 s apart, with no move and no hook
   between them, so byte-identical is structurally guaranteed and evidentially void.
3. `Audio.txt` carries **no hook lines at all** in that minute. `audio.bash` never ran for it.
4. The `category='music'` census after the stamp is `music → 3`; the total moved 121 → 124.
5. Its `pp` and `status` cannot be re-read, because the row is gone.

**This is not a defect in the judge** — its own header states it decides § 1 item 4's byte condition
and explicitly *not* criterion 3, leaving the verdict to the executor, which is where this exclusion
was made. Counting it as a fourth job would not have changed the verdict, since § 5 resolves OPEN on
the first UNPROVEN either way.

## Re-derivation before acting, and the discrepancy it caught

READ 1 ran **unconditionally and before any branch**, as the plan requires. Its first form
(`completed > stamp`, unbounded above) returned **3** rows while the watcher's `map.tsv` held **4** —
a discrepancy that had to be resolved before anything was written, and that produced the exclusion
above. It was then **re-run window-bounded** (`> open AND <= close`) so the job set is reproducible:
by 22:50:52Z a further **25** `category='music'` rows had completed *after* the close (music rows
124 → 149). The estate was actively downloading throughout. The side-effect reads were taken while
`MAX(completed)` was still the last in-window row, so none of them can have swept in a post-window
job — that provenance is stated in § 7 rather than assumed.

## What was deliberately NOT used to upgrade the verdict

Recorded as separate, weaker evidence per the plan and REVIEWS row 11. None of it moved OPEN to PASS:

- no beets state reappeared anywhere under sabnzbd `/config`, and `quick-health-check.sh` still
  reports `beets databases: 1`;
- all three jobs produced the two pre-declared residual lines and **zero** success lines;
- the one job whose folder could still be read carries **0** `MUSICBRAINZ_*` and **0**
  `REPLAYGAIN_*` / `R128_*` keys across all 10 files;
- the vendored `audio.bash` on the host is byte-identical to the repo copy with **0** `beet`
  invocations.

No snapshot was retro-fitted, no timestamp reinterpreted, nothing was tuned or retried to reach a
PASS, and the watcher was not re-armed to manufacture a third attempt inside this plan.

## Job folders left in place

At its COMPLETION snapshot **every one of the three was present at its destination under
`complete/nzb/music/` and was hashed there** (10, 16 and 20 files) — the measurement that speaks to
what `audio.bash` did: it left all three in place. At window close + ~8 min, **1 of 3** was still
there; the other two had been removed by something downstream, after the window, and were not found
anywhere in the downloads tree. **Nothing that existed at window open was removed**
(`pre_existing_folders_now_missing=0`), and `/mnt/tank/downloads/incomplete` still holds exactly its
6 stale January orphans, untouched. The removal is recorded as **unattributed rather than guessed
at** — Lidarr's only root folder was checked and the folders are not under it.

## The watcher's own state at stop

- **It had not exited on its own.** `kill -0` succeeded; `SIGTERM` was sufficient and it was gone
  within 1 s, logging `EXIT reason=SIGTERM rows_seen=4`. It was launched with an explicit
  `LINGER=604800` and had 7 days left.
- **`watch.out` is 0 bytes, and there is no separate `watch.err`** — the production launch merges
  both streams with `2>&1`, so its absence is by design, not a failed read. Byte counts are quoted
  because an empty error log and an unreadable one look identical.
- `watch/hash.err` is **3,063 bytes / 45 lines** and that is *expected*, not a fault: it is the
  refused hash pass described above.

## Cleanup

`/mnt/fast/scratch-04/15` removed behind the S5 fence: **101 files** deleted individually after a
`realpath -e` containment check (**0 refused**), **13 directories** by `rmdir` deepest-first, then
the three allow-listed parent-level files (`watch-d12b.sh`, `judge-d12b.sh`, `selftest-14.txt`) and
the now-empty parent. **No `rm -rf` was executed.** Both asserted absent with `/mnt/fast/stacks` and
`/mnt/fast/appdata` printed as positive controls. The job→folder mapping in `names.tsv` went with it.

**No watcher process remains**, proven by an executed match in a **second, separate** ssh invocation
carrying neither the watcher's name nor its path: **0** matches over a `ps` snapshot of **733**
processes, with **3** `sshd` on the same snapshot as the positive control. The plan's own verify
re-ran the same proof independently and returned `CLEANED-NO-WATCHER-5-sshd`.

**The OBS block was committed before any of this ran** (`4a4543f`), so the material supporting the
verdict outlived the instrument that produced it — and the plan's verdict-versus-observation gate
returned `VERDICT-SUPPORTED(OPEN,jobs=3)` afterwards, against evidence that no longer exists on the
host.

## Deviations from Plan

### 1. [Rule 1 — Bug, my own instrument] My cleanup script was transferred **empty**, and an empty script exits 0

- **Issue:** the transfer command was `ssh host "cat > /tmp/nope 2>/dev/null; cat > …/cleanup15.sh"`.
  The first `cat` consumed the **entire heredoc**, so the script file was written 0 bytes. `bash` on
  a 0-byte file **exits 0 and prints nothing**, and the trailing `rm -f` then removed the evidence.
- **Caught because output was expected and none arrived** — not by the exit code, which was 0.
  **Nothing had been deleted.** Had I read RC 0 as success I would have reported a cleanup that never
  happened, and left a watcher's scratch on the host.
- **Fix:** re-transferred with a single `cat >`, and the run is now **fail-closed on the artefact**:
  the remote line count is asserted `>= 40` before `bash` is invoked at all.
- **This is the estate's documented class in a new costume**, and STATE.md already records the
  general form from 02.1-10: *a zero-byte script exits 0*, so `[ -z "$OUT" ]` must be tested before
  the return code. Same shape, my own hands.

### 2. [Rule 1 — Bug, my own instrument] My secret screen used `\b` with BSD `sed`, so the filter never ran

- **Issue:** the added-line screen filters 64-character hex digests out before looking for runs of
  40+ characters. I wrote it as `sed -E 's/\b[0-9a-f]{64}\b//g'`. **macOS ships BSD `sed`, which does
  not support `\b`** — it matched nothing, the digests survived, and the screen reported **3** long
  runs, two of which were the very digests the carve-out exists to permit.
- **Fix:** re-screened with `perl -pe 's/[0-9a-f]{64}//g'` and **proved the filter discriminates with
  both controls** — a 64-hex run is removed (0 runs left), a 50-character non-hex run is still
  flagged (1 run). Result: **1** run of 40+ characters and it is a filesystem path
  (`…/sabnzbd/config/scripts`), **0** credential-pattern matches, **0** release or job folder names.
- **Recorded because the failure direction is the dangerous one.** A screen whose filter silently
  does nothing produces *false alarms* here, but the same defect in a screen that filters *out*
  matches would produce a **false all-clear** on a public repo.

### 3. [Rule 1 — Bug in my own text] The mtime-provenance disclaimer was line-wrapped past its own gate

- **Issue:** the plan's verify requires every case-insensitive `mtime` line inside § 7 to also carry
  `extended.conf` or `never used as provenance`. My disclaimer wrapped as *"**File mtimes are never
  used as**"* / *"**provenance.**"*, so the gate saw `mtime` without its exemption and returned 1.
- **Fix:** the phrase now sits on a single line. **The gate was not relaxed and the disclaimer was
  not deleted** — the text was made to satisfy the assertion the plan wrote, which is the right
  direction. Caught by running the plan's own gate *before* committing rather than after.

### 4. [Plan latitude exercised at arming, carried forward] `POLL_FS=1`

- Recorded by the Task 1 executor: the window was armed at `POLL_FS=1` rather than the default 2,
  deliberately targeting 04-14's carried-forward HIGH residual risk. `STABLE_PASSES` stayed at 2.
- **It did not save the window** — and that is the useful result. Doubling the sampling rate cannot
  help against a job that never exposes an audio file to the incomplete tree at all, which is what
  two of the three did.

### 5. [Plan assertion deliberately NOT re-run] Task 1's `<verify>`

- Task 1's verify asserts `ls -1 /mnt/tank/downloads/incomplete | wc -l` **equals** `START_INCOMPLETE`.
  That is an **arming-time-only** assertion: a real job legitimately changes the live count, so
  re-running it at close would print a spurious failure on a perfectly healthy window.
- It was not re-run. The underlying fact was measured separately instead and **holds**: the
  incomplete tree is back to exactly its 6 stale January orphans.

### 6. [Instrument limit, recorded] `find -newer <stamp>` cannot locate audio a downloader moved

- I measured `audio files newer than the stamp` under `/mnt/tank/downloads` as **0** while ten such
  files were demonstrably sitting in a destination folder at that moment.
- **Mechanism:** SABnzbd preserves the posted file times, so freshly-landed audio is *older* than the
  window that landed it. Recorded because reading that 0 as "the files are gone" is exactly the
  silence-read-as-clean error, and I nearly did.

### 7. [Pre-existing, recorded] The transcript necessarily contained release folder names

- The watcher's `trail.log` lines are inventory records (`path|size|time|inode`), not timestamped
  events, so a redaction built for event tokens did not strip them. **Nothing reached the repo**:
  every subsequent read was rewritten to emit hashes, counts, dirnames or booleans only, and the
  added lines were screened (deviation 2). Same condition 04-12 recorded.

### 8. [Recorded] An unbounded `find /mnt/tank -maxdepth 6` timed out

- Used once to trace where the removed folders went; it exceeded its timeout (RC 124) on a multi-TB
  pool. Replaced with targeted probes against Lidarr's declared root and the downloads tree. The
  question it was asked is downstream of the window and is recorded **unresolved** rather than
  guessed at.

---

**Total deviations:** 8 — **3 auto-fixed bugs, all three in my own instruments**, 1 arming-time
latitude carried forward, 1 plan assertion correctly not re-run, 1 instrument limit, 1 pre-existing
condition, 1 bounded-resource failure.
**No assertion was weakened, no gate was relaxed, no status token was transcribed rather than lifted
from the judge's own stdout, no file was edited to make a check pass, and the verdict was not
upgraded on inference.**

## Threat Flags

None. This plan added no network endpoint, auth path or trust boundary. Against the plan's register:

- **T-04-15-01 (release names into a public repo)** — mitigated. Jobs are keyed by a 12-character
  sha256 prefix in § 7 and in every `OBS window2 job=` line; `script_line` truncated at 60
  characters; `storage` quoted as its parent only; ffprobe **keys**, never values; `Verified Track:`
  lines never quoted; `names.tsv` deleted with scratch. Added lines screened with a filter proven to
  discriminate: 0 credential matches, 1 run of 40+ characters and it is a filesystem path.
- **T-04-15-02 (SABnzbd API key)** — no API was called. History read via `sqlite3 "file:…?mode=ro"`.
  Nothing was triggered, cancelled or paused; the jobs were the operator's.
- **T-04-15-03 (tampering with the watched trees)** — mitigated. Read-only verbs only, all writes
  confined to `/mnt/fast/scratch-04/15`. The running instrument's sha256 values were asserted present
  in `04-14-SUMMARY.md` at arming, and the production launch carried **no** `HASH_DELAY`
  (`launch.cmd` re-read verbatim before deletion confirms it).
- **T-04-15-04 (a verdict fitted to its outcome)** — mitigated. The contract was committed 717 s
  before the stamp and is an ancestor of HEAD; § 5's pre-declared rules decided; § 6's window-1
  record is byte-identical, proven by `diff` against `git show HEAD~1`.
- **T-04-15-05 (watcher or scratch left behind)** — mitigated and **executed**: 0 matches over 733
  processes with a 3-`sshd` positive control, re-proven independently by the plan's own verify; all
  scratch removed behind the S5 fence with no `rm -rf`.
- **T-04-15-06 (a verdict its evidence does not support)** — mitigated. The OBS block was committed
  **before** cleanup and the gate returned `VERDICT-SUPPORTED(OPEN,jobs=3)` after the host evidence
  was gone.
- **T-04-15-07 (the operator's reply standing in for a measurement)** — mitigated and **it mattered**:
  the reply said two albums, the measurement found three rows, and the record follows the
  measurement.

## Known Stubs

None. `04-D12-EVIDENCE.md` § 7 is filled, carries exactly one window-2 verdict line and a complete
OBS block, and § 6 is untouched.

## Issues Encountered / carried forward

- **Criterion 3's behavioural half is still OPEN after two windows and five real jobs.** The estate
  side is now measured clean three times over; only the byte capture is unproven, and both obstacles
  are named and measured rather than suspected. A third window with this instrument would most
  likely produce the same result.
- The estate was busy throughout: 25 further music rows completed after the close, outside the
  window.
- The survivor beets container remains deliberately stopped; nothing in this plan started it.

## Next Phase Readiness

- **04-16 must not treat criterion 3 as passed.** `04-D12-EVIDENCE.md` carries exactly one
  `^Verdict: ` line (window 1, OPEN, unchanged) and exactly one
  `^Verdict (window 2): OPEN — ` line. This SUMMARY's frontmatter carries `window2_verdict: OPEN`.
- **The choice 04-16 inherits is a decision, not a measurement:** either accept that criterion 3 is
  discharged on threefold unanimous side-effect evidence, or keep it OPEN. Nothing further can be
  measured with the current instrument without changing where the capture happens.
- **Do not re-derive the ReplayGain question** (`audio.bash:86` is a literal; the gate is line 325),
  and do not read `Audio.txt`'s residual lines as evidence beets ran.
- **Both standing guards remain green** after three more real music jobs: `quick-health-check.sh`
  exit 0, census counters at target, drift `✅ vendored files match (3)`.

## Self-Check: PASSED

- FOUND `.planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md`;
  `grep -cE '^Verdict: (PASS|OPEN|FAIL)'` = **1** and byte-identical to the pre-edit version;
  `grep -cE '^Verdict \(window 2\): (PASS|OPEN|FAIL) — '` = **1**; `## 7. Result — window 2` = **1**;
  OBS meta/prereq/sideeffects/producers = 1 each; `OBS window2 job=` lines = **3** = the `jobs=` field.
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-15-SUMMARY.md`.
- FOUND commit `4a4543f`, touching exactly one file (`04-D12-EVIDENCE.md`), **0** deletions.
- The plan's own verify returned `VERDICT-SUPPORTED(OPEN,jobs=3)` and `CLEANED-NO-WATCHER-5-sshd`.
- Host: `/mnt/fast/scratch-04/15`, `watch-d12b.sh`, `judge-d12b.sh`, `selftest-14.txt` and the parent
  directory all absent, with `/mnt/fast/stacks` and `/mnt/fast/appdata` visible as positive controls.
- No commit deleted any tracked file. Only explicit paths were staged.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-13*
