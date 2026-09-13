---
phase: 04-collapse-to-one-tagger
plan: 14
subsystem: infra
tags: [criterion-3, d-12, d-31, watcher, instrument, self-test, gap-closure, host-readonly]

# Dependency graph
requires:
  - plan: 04-12
    provides: "the measured mechanism — SABnzbd moves the job into complete/nzb/music/ and only then invokes the hook — and the two candidate fixes, one of which this plan chooses on measurement"
  - plan: 04-13
    provides: "the interim-status framing that keeps criterion 3 open rather than closed"
provides:
  - "watch-d12b.sh — an incomplete-tree watcher that takes a PRE-HOOK snapshot at a point STRUCTURALLY earlier than the hook, publishes it only when its hash pass did not straddle the move, and publishes its completeness (pre.inv vs last.inv) as a testable property"
  - "judge-d12b.sh — an ordered status ladder with every UNPROVEN clause above every FAIL clause, emitting BYTES-OK / FAIL / UNPROVEN in a fixed STATUS=<token> field"
  - "an eight-control self-test record at /mnt/fast/scratch-04/selftest-14.txt proving the instrument can pass, can FAIL, refuses to guess in four distinct ways, stays alive on an empty window, and leaves the bytes it watches untouched"
  - "04-D12-EVIDENCE.md sections 1 and 5 amended in-band and dated, committed BEFORE the second window exists"
affects: [04-15, 04-16]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Structural ordering beats timestamp comparison: a snapshot taken while the folder still exists under incomplete/ is earlier than the move, and the move is earlier than the hook — no sub-second comparison against a second-resolution log is needed, and none is possible"
    - "Where two causes are indistinguishable from the evidence, the ladder must resolve to UNPROVEN, not FAIL. Under direct_unpack=1 a COMPLETION-only file is equally consistent with late extraction and with a hook rewrite; calling that FAIL is a false accusation against a clean estate"
    - "A publication protocol must re-measure AFTER the expensive step, not infer from two timestamps: an already-open file descriptor survives a rename, so a hash pass can straddle the move and still produce a snapshot whose recorded time precedes the next absence poll"
    - "Write the commit point LAST: hashing into a temporary and mv-ing the manifest into place after its status file means a reader can never catch a manifest whose rc has not been written yet and read that absence as 'rc unavailable'"
    - "An error log is only evidence about the instrument if the harness is not writing to it. 66 bytes of 'watcher error' were `timeout`'s own 'Terminated' on a shared stderr — proven by one control that stopped the watcher differently and logged 0 bytes from identical code"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-14-SUMMARY.md
  modified:
    - .planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md
  host-created:
    - "(host) /mnt/fast/scratch-04/watch-d12b.sh — sha256 59f067bdc5dc236096fbd3281534ac5db992a83d8800328dc5d57dd87e92e759"
    - "(host) /mnt/fast/scratch-04/judge-d12b.sh — sha256 7ab24c9e96b0464f1632bf8f4a05967ceb778e5b38485462ab18ff56808837e2"
    - "(host) /mnt/fast/scratch-04/selftest-14.txt — 12 lines, the eight-control record plus the COLS line"
  host-deleted:
    - "(host) /mnt/fast/scratch-04/14 — 209 files, 50 directories, file-by-file behind the S5 fence with realpath -e, directories by rmdir deepest-first. No `rm -rf` was executed"

key-decisions:
  - "Design (a) chosen over design (b) on measurement, not taste: job A's earliest possible destination-tree sighting (12:18:00.074Z) was already later than its own `Matching` line (12:17:59Z), so a zero-wait destination snapshot still races the hook and can never be PROVEN earlier"
  - "The PRE-HOOK snapshot is the LAST stable snapshot, not the first — 04-12's first-stable rule inherited a 2-4 s floor against hooks that run in 1 s"
  - "Snapshot completeness is a published, testable property (pre.inv vs last.inv) rather than an assumption, and a stale baseline yields UNPROVEN rather than FAIL"
  - "SC-4's watch_err_bytes=0 bar was NOT lowered to accommodate the 66-byte reading. The harness was fixed so the measurement measures the instrument"
  - "STABLE_PASSES=4 for SC-6 only, to drive the late-extraction control deterministically instead of racing a ~2 s window"

requirements-completed: []  # TAGR-04's behavioural half remains OPEN: this plan builds and proves the instrument, it does not run a window.
requirements-advanced: [TAGR-04]

# Metrics
duration: ~16min
completed: 2026-09-13
---

# Phase 4 Plan 14: Fix the Instrument, and Prove It Can Fail Summary

**The instrument that blocked criterion 3 is replaced, and every one of its outcomes has been driven on synthetic data before a scarce real music job is spent on it: it returned BYTES-OK on a clean control, FAIL on bytes deliberately changed after the move, UNPROVEN for four distinct reasons, stayed alive 45 s on an empty window with `LINGER=10`, and left 9 of 10 baselined fixture files byte-identical with the tenth mutated by the control itself. The contract it will be judged against was amended in-band, dated, and committed before the second window exists.**

## Performance

- **Duration:** ~16 min.
- **Tasks:** 3 of 3.
- **Files:** 1 modified in the repo (`04-D12-EVIDENCE.md`), plus this summary. On the host: 3 files created and left in place, 209 files / 50 directories created and removed.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Build the incomplete-tree watcher and the byte judge | none — host-only (04-12 Task 1 precedent) |
| 2 | Drive eight synthetic controls | none — host-only |
| 3 | Amend the evidence contract in-band and dated | **`0022e91`** |

**Plan metadata:** this SUMMARY's own commit.

## The design decision, recorded before either script was written

| Design | What it does | Verdict |
|---|---|---|
| **(a) Snapshot under `/mnt/tank/downloads/incomplete` before the move** | SABnzbd cannot invoke the hook until it has moved the folder out of the incomplete tree, so a snapshot taken while the folder still existed there is earlier than the move, which is earlier than the hook | **CHOSEN.** The ordering is *structural* and needs no comparison against `Audio.txt` at all |
| **(b) Key the snapshot on first sighting of the destination folder, no stability wait** | Drops the 2 s stability floor and samples the moment the folder appears in `complete/nzb/music/` | **REJECTED on measurement.** Job A's first possible sighting was **12:18:00.074Z** while its `Matching` line was already at **12:17:59Z**; job A's whole hook ran in 1 second; and `Audio.txt` resolves only to the second, so job B was indeterminate even at a millisecond clock. Design (b) races the hook and can never be *proven* earlier |

**The assumption design (a) rests on, stated so a later reader meets it rather than discovers it: SABnzbd's move preserves bytes** — the hook is the only thing in the pipeline that would rewrite them. The byte comparison is exactly what tests that assumption.

## The three completeness measurements, re-derived on the host

Each was re-measured on 2026-09-13 rather than copied from the plan. **All three matched the plan's figures exactly; there is nothing to correct.**

| Measurement | Observed | Why it matters |
|---|---|---|
| `direct_unpack` in `sabnzbd.ini` | `direct_unpack = 1` (also `direct_unpack_tested = 1`, `direct_unpack_threads = 3`) | Audio extracts **during** the download, so the audio set grows over the life of the job and a snapshot can be a proper subset |
| `stat -c %d` on `incomplete` and `complete` | **68** and **68** — the same ZFS dataset | The move is an instant rename with no observable window |
| `postproc_time` over `category='music'` | **121** rows total, **35** at `>= 4` s; last 10 jobs: `3 1 8 2 1 1 2 2 1 2` | The hook is 1–3 s on recent jobs, so a mid-download lull can leave a subset stable and hashed |

Together these are why the snapshot needs a **completeness property** and not just a timestamp — and why a COMPLETION-only file must resolve to UNPROVEN, not FAIL.

## The instrument

| Script | sha256 |
|---|---|
| `/mnt/fast/scratch-04/watch-d12b.sh` | `59f067bdc5dc236096fbd3281534ac5db992a83d8800328dc5d57dd87e92e759` |
| `/mnt/fast/scratch-04/judge-d12b.sh` | `7ab24c9e96b0464f1632bf8f4a05967ceb778e5b38485462ab18ff56808837e2` |

Plan 04-15 asserts these exact hashes against this SUMMARY before arming, so the instrument that was proven is the instrument that runs. **Neither script is in git** — `git ls-files | grep -E 'watch-d12b|judge-d12b|selftest-14'` returns 0, and the working tree stayed clean throughout.

**The judge's boundary, stated in its own header and here:** it decides the byte condition of § 1 item 4 **only**. It does not decide criterion 3. The § 1 items 1–3 side-effect checks, the § 3 `extended.conf` prerequisite and the final verdict are the executor's in plan 04-15, exactly as § 5 requires.

## The eight controls

Every `STATUS` for the six judge-driven controls was lifted from the judge's own stdout by field extraction, never transcribed from the plan's expectation.

| Control | What was done | Expected | Observed | Verdict |
|---|---|---|---|---|
| **SC-1** POSITIVE | two `.flac` stabilise under `fx-incomplete`, snapshot publishes, folder moves, row inserted | `BYTES-OK` | `STATUS=BYTES-OK files_in_both=2 byte_identical=2 changed=0 pre_complete=yes` | ✅ |
| **SC-2** MUTATION | as SC-1, then one byte appended to one file **after** the move | `FAIL` | `STATUS=FAIL reason=bytes-changed files_in_both=2 byte_identical=1 changed=1` | ✅ |
| **SC-3** LATE START | folder created directly in `fx-music`, never seen under `fx-incomplete` | `UNPROVEN no-attributed-pre` | `STATUS=UNPROVEN reason=no-attributed-pre attrib=none pre_sha256=absent completion_only=2` | ✅ |
| **SC-4** READ-ONLY | re-read the baseline taken before any control started | `READONLY-OK` | `fixtures_checked=10 fixtures_unchanged=9 fixtures_mutated_by_control=1 fixtures_missing=0 outside_14_writes=0 watch_err_bytes=0` | ✅ |
| **SC-5** EMPTY WINDOW | empty history, empty `fx-incomplete`, `LINGER=10`, slept 45 s | still alive | `STATUS=ALIVE-OK map_rows=0 alive_after_s=45 linger=10 exit_after_sigterm=yes` | ✅ |
| **SC-6** LATE EXTRACTION | third `.flac` added **after** the snapshot published, then moved | `UNPROVEN baseline-stale`, **not** FAIL | `STATUS=UNPROVEN reason=baseline-stale completion_only=1 pre_complete=no byte_identical=2` | ✅ |
| **SC-7** MOVE-DURING-HASH | `HASH_DELAY=6`, folder moved inside the hash window | nothing published | `STATUS=UNPROVEN pre_published=no hash_span_refused=1 pre_sha256=absent` | ✅ |
| **SC-8** EMPTY COMPLETION | valid PRE snapshot against a COMPLETION folder with its audio removed | `UNPROVEN empty-intersection` | `STATUS=UNPROVEN reason=empty-intersection files_in_both=0 pre_only=2 pre_complete=yes` | ✅ |

**The instrument is therefore capable of returning FAIL on a real job** — SC-2 drove it there on bytes changed after the move, which is precisely the condition criterion 3 tests. Equally, **SC-6 is the load-bearing line**: it fed the judge an input that satisfies clause 7's condition outright (`completion_only=1`, a file matching no PRE-HOOK file) and got UNPROVEN rather than FAIL, which is the whole of the round-2 row-2 fix.

`COLS live=30 fixture=30` — the fixture `history` table was generated from the live `PRAGMA table_info(history)` rather than a transcribed column list, and both counts are **30**, confirming round 2 row 14's correction of the earlier "29".

**No watcher process remains**, proven by an executed match rather than a captured-and-discarded snapshot: a second, separate ssh invocation carrying neither the watcher's name nor its path matched a pattern file with `grep -F -f` over a `ps` snapshot → **0 matches**, with **5** `sshd` on the same snapshot as the positive control. Both probe files were deleted.

## Deviations from Plan

### 1. [Rule 1 — Bug, my own instrument] The driver's `stop_watch` referenced a stale variable

- **Found during:** Task 2, first run.
- **Issue:** `local outd="$ROOT/out-$tag"` survived a rename of the parameter to `$1`; under `set -u` this aborted the driver at the first control.
- **Fix:** declare `local outd` then assign from `$1`.
- **Why it is recorded rather than quietly fixed:** the run it killed had *already* produced SC-5's measurement (watcher alive 45.2 s, 0 rows, 0-byte error log), so the abort was in the harness, not the instrument — and reading it as an instrument failure would have been the wrong lesson.

### 2. [Rule 1 — Bug] `wait_lines` produced the two-line string `0\n0`

- **Issue:** `n="$(grep -c . "$f" || echo 0)"` — `grep -c` prints `0` **and** exits 1 on an empty file, so the `|| echo 0` appended a *second* zero, and every later `-ge` test errored with "integer expression expected".
- **Fix:** assert the file exists, then take the count with no `|| echo` fallback.
- **This is the 04-12 deviation-2 class in a new costume:** a producer's non-zero status turning a reading into nonsense.

### 3. [Rule 1 — Bug, in the watcher itself] `post.sha256` was published before `post.rc` existed

- **Found during:** Task 2, first run — **observed, not theorised.** SC-7's `dst/` directory held `post.sha256` with **no `post.rc` and no `post.time` beside it**, and the judge duly reported `post_rc=na`.
- **Mechanism:** the watcher wrote the manifest first and its status second, so anything reading the manifest could catch the gap. SC-7 survived only because clause 1 fired before clause 4 ever consulted `post.rc`.
- **Fix:** hash into `.post.tmp`, write `post.time` and `post.rc`, then `mv` the manifest into place. **`post.sha256` is now the commit point**, mirroring the PRE-HOOK protocol. Re-run confirms SC-7 now reports `post_rc=0`.
- **Why this mattered:** a missing `post.rc` reads as "acquisition status unavailable" — "could not look" manufactured by the instrument's own write order.

### 4. [Measured finding — a gate was NOT lowered] The 66 "watcher error" bytes were not the watcher's

- **Issue:** SC-4 first returned `READONLY-FAIL` on `watch_err_bytes=66`.
- **Measured:** six files of **exactly 11 bytes each**, every one reading `Terminated` — `timeout`'s own message on the stderr it *shares* with the watcher, emitted because `stop_watch` signalled the `timeout` parent first. **SC-5's log was 0 bytes from identical watcher code**, because SC-5 signals the watcher's own PID and lets its SIGTERM trap exit cleanly. All six `hash.err` files were 0 bytes.
- **Fix:** `stop_watch` now SIGTERMs the watcher's recorded PID first and polls for its exit — which is also exactly how 04-12 stopped the real watcher and how 04-15 will. Re-run: `watch_err_bytes=0`.
- **Recorded prominently because the tempting move was the wrong one.** The `watch_err_bytes=0` bar was never relaxed and no control was accommodated; the harness was corrected so the measurement measures the instrument. Had the bar been lowered to 66 instead, a genuinely noisy watcher would have passed silently for the rest of the phase.

### 5. [Plan latitude exercised] SC-6 ran with `STABLE_PASSES=4`

- The plan fixes `LINGER=10` "except where a control says otherwise"; SC-7 already overrides `HASH_DELAY`. SC-6 additionally overrides `STABLE_PASSES` to 4.
- **Reason:** at the default 2, the gap between "the watcher has *seen* the third file" and "the watcher would *republish* a complete 3-file snapshot" is about 2 seconds. Republishing would have made `pre_complete=yes` and returned `BYTES-OK`, so the control would have been raced rather than driven. At 4 the margin is ~6 s and the outcome is deterministic.
- **This does not weaken the control** — it makes the stale-baseline condition it exists to test reliably reachable. The production default remains 2 and is unmodified.

### 6. [Plan latitude exercised] Fixtures are staged in `prep/`, and SC-8's are created after the baseline

- The plan requires both "pre-create every fixture audio file before any control runs" *and* "each control's fixture folder is created only after that control's watcher has written `START_INCOMPLETE`". Creating them directly under `fx-incomplete` cannot satisfy both.
- **Resolution:** files are created in `fixtures/prep/<job>/`, the baseline is taken there, and each control `mv`s its prepared folder in at the right moment — a rename, so the baselined bytes and inodes are the same ones the watcher observes. SC-4 re-locates each baseline entry by its job-relative path under `fx-music`, `fx-incomplete` or `prep`.
- **SC-8's files were created after the baseline**, as the plan explicitly permits, because SC-8 deletes them; `fixtures_missing=0` confirms nothing baselined went missing.

### 7. [Recorded] The driver uses `set -uo pipefail`, not `set -euo pipefail`

- The two instrument scripts follow the `check-music-freeze.sh` convention with `set -euo pipefail`. The **driver** deliberately does not use `-e`: a driver that aborts at control 3 leaves no record at all, and **the record is the gate**. Failures are captured into the record instead, where the `<verify>` sees them.

### 8. [Recorded] Self-test watchers launched without `setsid`/`nohup`

- Each control's watcher runs under `timeout 120` only, so the driver can deterministically signal it and prove it stopped. Production arming in 04-15 keeps `setsid`, and the watcher's self-recorded `$OUT/watch.pid` defence (which 04-12 recorded working) is unchanged and still present.

---

**Total deviations:** 8 — 3 auto-fixed bugs (one of them in the watcher itself, found by a control), 1 measured finding where a gate was deliberately *not* lowered, 2 exercises of latitude the plan grants, 2 recorded implementation choices.
**No assertion was weakened, no gate was relaxed to accommodate a control, no expected status was transcribed into the record, and the amendment deleted nothing.**

## The contract amendment

Committed as `0022e91`, touching exactly one file, **116 lines added and 0 deleted**. `grep -c 'Amended 2026-09-13 by plan 04-14'` = **2**; `grep -cE '^Verdict: (PASS|OPEN|FAIL)'` = **1** and that line is byte-identical to the one 04-12 wrote (proven by `diff` against `git show HEAD~1`); `grep -cE '^Verdict \(window 2\): …'` = **0**, because § 7 belongs to 04-15.

Added lines screened: after deleting every 64-character lowercase hex run, **0** runs of 40+ characters; **0** matches for `user_token|discogs\.env|/secrets/|token=|apikey|api_key`; no release or job folder name.

**The ordering is the point.** The contract is amended and committed *before* the window opens and before any second job exists, so it cannot be fitted to the evidence it will judge — which is the failure the file's own opening paragraph exists to prevent.

## Issues Encountered / carried forward

- **The one thing eight synthetic controls cannot prove**, flagged for 04-15: whether a *real* job's inventory actually holds still for `STABLE_PASSES` consecutive polls under `incomplete/`. This was Gemini's graded HIGH in round 2, and it is a genuine residual risk — SC-1 stabilises because the driver pauses before moving. The design fails *safe* (no stable snapshot → no `pre.sha256` → `UNPROVEN`, never a false FAIL), and `STABLE_PASSES` and `POLL_FS` are both overridable at arming, so 04-15 can tune them without touching the instrument. This is recorded as a known limit, not an assumed capability.
- `/mnt/tank/downloads/incomplete` carries **6** stale January orphan directories (re-measured today, unchanged from 04-12). They are excluded from tracking by `START_INCOMPLETE` and were not touched.
- The survivor beets container remains deliberately stopped; nothing in this plan started it.

## Threat Flags

None. This plan added no network endpoint, auth path or trust boundary. Against the plan's register:

- **T-04-14-01 (release names into a public repo)** — mitigated. Folders are keyed by a 12-character sha256 prefix; `names.tsv` never left host scratch and went with `/14`. The amendment's added lines were screened with the hex-filtered form, which permits the two sha256 values item 7 mandates while still forbidding long opaque strings.
- **T-04-14-02 (tampering with the watched trees)** — mitigated and measured. Read-only verbs only; all writes confined to `$OUT`, which the watcher creates itself. SC-4: `fixtures_checked=10`, non-vacuous and asserted numerically, with exactly one file mutated by the control itself.
- **T-04-14-03 (mutation controls writing outside their root)** — mitigated. S5 fence with `realpath -m` plus a `..`-component refusal on every write; `outside_14_writes=0`. Fixtures were random bytes; no estate audio was copied.
- **T-04-14-04 (a contract fitted to its evidence)** — mitigated. Committed before the window, additive-only proven by `--numstat` deletions = 0, window-1 verdict proven unchanged by `diff`.
- **T-04-14-05 (a watcher left running)** — mitigated and **executed**: 0 matches over a `ps` snapshot with a 5-`sshd` positive control, from an invocation that cannot match itself.
- **T-04-14-06 (`HASH_DELAY` weakening production)** — mitigated. Defaults to 0, documented under the `check-jellyfin-transcode.sh:121-133` doctrine as able only to make the watcher **refuse** to publish. SC-7 exercised it; 04-15 asserts the production launch carries none.
- **T-04-14-07 (a self-test gate that passes a failing instrument)** — mitigated. The gate read SC-1's `BYTES-OK` and SC-4's `READONLY-OK`, not only the negative controls, extracted and numerically compared SC-4's counts and SC-5's liveness, and asserted none of the four UNPROVEN controls rendered as `BYTES-OK` or `STATUS=FAIL`. **It fired for real**: SC-4's first run returned `READONLY-FAIL` and the gate refused the run.

## Known Stubs

None. Both scripts are complete and driven; the record is written; the amendment is committed. `/mnt/fast/scratch-04/14` is absent, and the two scripts plus `selftest-14.txt` survive for 04-15.

## Next Phase Readiness

- **04-15 may arm the window.** It should assert the two sha256 above, re-read `selftest-14.txt`, confirm commit `0022e91` is an ancestor of HEAD with a committer date before its stamp, and launch with `setsid` and **no** `HASH_DELAY`.
- **Criterion 3 is still OPEN.** This plan builds and proves the instrument; it does not run a window and it wrote no verdict. `TAGR-04`'s behavioural half remains unsatisfied.
- **Consider `STABLE_PASSES` and `POLL_FS` at arming** in light of the residual risk above; both are overridable and the default is 2 / 2 s.

## Self-Check: PASSED

- FOUND `.planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md`; `Amended 2026-09-13 by plan 04-14` = **2**, `^Verdict:` = **1**, `^Verdict (window 2):` = **0**, all eight required literals present.
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-14-SUMMARY.md`.
- FOUND commit `0022e91`, touching exactly one file, 116 insertions / 0 deletions.
- Host: both scripts present at the recorded sha256, `selftest-14.txt` present at 12 lines, `/mnt/fast/scratch-04/14` absent, positive controls `/mnt/fast/stacks` and `/mnt/fast/appdata` both visible.
- No watcher process remains — 0 matches, 5 `sshd` positive control, from a self-match-proof instrument.
- No commit deleted any tracked file. Only explicit paths were staged.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-13*
