---
phase: 04-collapse-to-one-tagger
plan: 17
subsystem: infra
tags: [criterion-3, d-12, d-31, nscript, sabnzbd, instrument, self-test, gap-closure, host-readonly]

# Dependency graph
requires:
  - plan: 04-15
    provides: "the measured reason both polling designs are exhausted — under direct_unpack=1 two of three real jobs never exposed a single audio file to a 1-second poll of incomplete/, and the third was still growing when SABnzbd moved it"
  - plan: 04-16
    provides: "the interim-status framing in beets.md that keeps criterion 3 OPEN rather than closed"
provides:
  - "04-D12-EVIDENCE.md sections 1 item 4 and 5 amended in-band and dated, additive, committed BEFORE any window-3 stamp or arming exists"
  - "d12c-nscript.sh — a SABnzbd NOTIFICATION hook that captures the PRE-HOOK snapshot at SABnzbd's own pp event (postproc.py:453) and the COMPLETION snapshot at its complete event (:713), publishes only when its own hash pass did not straddle the move, resolves the COMPLETION destination fail-closed, and records archives_present as the precondition gating the judge's only FAIL clause"
  - "judge-d12c.sh — the redesigned eight-clause ladder: four acquisition UNPROVENs, the archives_present-gated FAIL split, two interpretation UNPROVENs, then BYTES-OK, with MOVED matching before the non-vacuity floor"
  - "a fourteen-control receipt at /mnt/fast/scratch-04/17/selftest-17.txt proving one FAIL path fires, seven distinct UNPROVEN tokens are reachable, PASS is reachable on flattened content, a clean estate cannot be accused, and a destination collision cannot yield a silent pass"
affects: [04-18, 04-19]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hook the producer's own state machine instead of polling its output. Both polling designs sampled a folder SABnzbd was actively draining; SABnzbd's pp notification is a state transition, so the ordering is structural and needs no comparison against a second-resolution log"
    - "A ladder must be rebuilt for the instrument that feeds it, not transplanted. 04-14's completeness property was measured by comparing a snapshot against a LATER observation; a fire-once hook never re-observes, so under it the property is PINNED by the publication condition and every clause depending on it is unreachable — not merely untested"
    - "Gate the accusation, not the pass. SABnzbd's own par2 repair and its unpack stage both rewrite existing files at the same relative path AFTER the hook fires, so an ungated 'same path, different sha256 => FAIL' clause accuses a clean estate on the NORMAL shape. The gate shrinks the FAIL set and leaves the BYTES-OK set identical — the conservative direction for a false-accusation risk"
    - "Never prefer the exact basename when resolving a destination. get_unique_dir produces <name>.N PRECISELY BECAUSE <name> already exists, so exact-match-first hashes the stale folder the job never wrote and can earn BYTES-OK against the wrong tree"
    - "Name a field after what it measures. The poller-era field name is how a pinned discriminator survived; and my own CLEANUP line shipped a boolean under a label that said the opposite, in the one field no gate reads"
    - "An ablation you can execute beats an argument you can write: SC-2 and SC-13 drive the IDENTICAL input shape and differ in exactly one variable, so the gate's effect is measured rather than asserted"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-17-SUMMARY.md
  modified:
    - .planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md
  host-created:
    - "(host) /mnt/fast/scratch-04/17/d12c-nscript.sh — sha256 e0fa001ac241b90c3ef877a6acf5019cb257e66910de23702f9d3fa06d8b0ba4, 317 lines"
    - "(host) /mnt/fast/scratch-04/17/judge-d12c.sh — sha256 7a73f4d6338873e42ac2e62c3031072a5cb4997704a87b4f8b465d50e0b78666, 180 lines"
    - "(host) /mnt/fast/scratch-04/17/selftest-17.txt — 14 SC- lines plus INSTRUMENT, COVERAGE and CLEANUP"
    - "(host) /mnt/fast/scratch-04/17/drive17.sh, verify2.sh, verify3.sh, valuescreen.sh — left deliberately so the receipt is reproducible and 04-18 can re-assert both gates"
  host-deleted:
    - "(host) /mnt/fast/scratch-04/17/fixtures — 132 files, 49 directories, file-by-file behind the S5 fence with realpath -e, directories by rmdir deepest-first, 0 refusals. No `rm -rf` was executed"
    - "(host) /mnt/fast/scratch-04/17/logs and the four driver state files — a further 67 files, same discipline"

key-decisions:
  - "The ladder is REDESIGNED, not transplanted: under a fire-once hook snapshot completeness is not establishable, so the poller-era discriminator is retired by name and completion-only audio is always UNPROVEN with its own token"
  - "The single FAIL clause is gated on archives_present, proven by an executed ablation rather than argued: SC-2 (no archive) returns FAIL bytes-changed and SC-13 (rar + par2 present) returns UNPROVEN unpack-pending on the IDENTICAL input shape"
  - "The non-vacuity floor counts MOVED pairs (files_in_both + moved >= 1), so a multi-disc release whose audio clean() flattens cannot resolve to a spurious empty-intersection — SC-9 drives it at moved=2 files_in_both=0"
  - "The COMPLETION destination is resolved fail-closed on candidate COUNT, never by preferring the exact basename — SC-14 proves a collision publishes nothing and that the stale folder's planted file was never read"
  - "SC-6's deleted files and SC-13's reverted mutation keep the SC-12 arithmetic exact WITHOUT lowering it, closing a genuine inconsistency in the plan's own gates (deviation 1)"
  - "The hook always exits 0 and contains no verb that can dump its process environment; both credential screens are value-based on the measured 32-character key and each carries a planted positive control"

requirements-completed: []  # TAGR-04's behavioural half remains OPEN: this plan builds and proves the instrument. It arms nothing and runs no window.
requirements-advanced: [TAGR-04]

# Metrics
duration: ~40min
completed: 2026-09-15
---

# Phase 4 Plan 17: The Window-3 Contract and Its Instrument Summary

**The contract window 3 will be judged against is in git before window 3 exists — one file, 238 insertions, 0 deletions — and the instrument that will produce its evidence has been driven to every outcome its ladder can return: one FAIL on bytes changed with no archive present, seven distinct UNPROVEN tokens across nine lines, and BYTES-OK reachable both on a flat folder and on one whose audio `clean()` flattened out of a `Disc 1/` subdirectory. The load-bearing result is an executed ablation: two controls drive the identical input shape and differ only in `archives_present`, returning `FAIL reason=bytes-changed` and `UNPROVEN reason=unpack-pending` respectively — so the gate that stops a false accusation against a clean estate is measured, not argued. Nothing was armed: no output tree, no staged script, `nscript_enable` still 0.**

## Performance

- **Duration:** ~40 min.
- **Tasks:** 3 of 3.
- **Files:** 1 modified in the repo (`04-D12-EVIDENCE.md`), plus this summary. On the host: 7 files left in place; 199 files and 50 directories created and removed.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Amend the evidence contract, committed ALONE and before any window exists | **`8646432`** |
| 2 | Build the nscript hook and the redesigned judge in host scratch | none — host-only (the 04-12 / 04-14 precedent) |
| 3 | Drive fourteen synthetic controls and write the receipt | none — host-only |

**Plan metadata:** this SUMMARY's own commit.

## The contract amendment

Committed as `8646432`, **touching exactly one file, 238 lines added and 0 deleted** (`git show --numstat`). Every assertion the plan wrote was executed, not asserted:

| Assertion | Measured |
|---|---|
| `grep -c 'Amended 2026-09-15 by plan 04-17'` | **2** |
| `git show --numstat` deletions | **0** |
| files in the commit | **1**, and it is `04-D12-EVIDENCE.md` |
| every `^Verdict` line vs `git show "$SHA^"` | **byte-identical** (`diff` empty), not a count |
| `grep -cE '^Verdict \(window 3\)'` | **0** — the amendment creates no column-1 decoy |
| count of the literal key-name token file-wide | **0** — the fact is recorded in prose so the screen stays strict |
| 25 required literals | all present, including `structural head start`, `not a mutex`, `not establishable`, `files_in_both + moved`, `archives_present`, `newsunpack.py:553-577`, `Lidarr`, `maximum armed lifetime` |
| `the ladder is unchanged and restated` | **absent** — a redesign is not passed off as a restatement |

**The ordering is the whole point.** The commit exists before any window-3 stamp, before any ini edit and before any output tree, so the verdict it will produce cannot be dismissed as fitted after the fact. That is the failure the file's own opening paragraph exists to prevent, and it is now honoured for the third window running.

### The credential screens, both proven to discriminate

| Screen | Result |
|---|---|
| **Value-based** (the real one): key read into a variable INSIDE the remote process, written to a pattern file, `grep -F -f` over the commit's added lines, pattern file deleted | `apikey_len=32 apikey_hits=0 screen_control=1` — the planted positive control was found, so a screen that cannot detect a leak was not mistaken for a clean result |
| **Heuristic** (second net): after `perl -pe 's/[0-9a-f]{64}//g'`, runs of 40+ characters | **0**; credential patterns **0**; no release or job folder name |
| Heuristic discrimination controls | a 64-hex run is removed (**0** runs left); a 50-character non-hex run is still flagged (**1** run) |

Run **twice** — once before committing and once against the commit's own added lines. The key never appeared on a command line and no process listing was read.

**This SUMMARY was screened too, and its residue is recorded rather than left to be discovered.** The value screen returns `apikey_len=32 apikey_hits=0 screen_control=1` over this whole file, so no key *value* is present. The heuristic leaves **9** runs of 40+ characters and **3** lines matching the credential-pattern set; every one is identified and benign — six are file or planning paths, two are verbatim SABnzbd source quotes, one is the gate's own token, and the three pattern matches are the receipt's field *names* (`apikey_len`, `apikey_hits`), which 04-18's gate greps and which therefore have to be quoted exactly. The literal key-name token was removed from this file in favour of prose, as the amendment does, so the strictest form of the repo's own screen passes on both.

## The instrument

| Script | Lines | sha256 |
|---|---|---|
| `/mnt/fast/scratch-04/17/d12c-nscript.sh` | 317 | `e0fa001ac241b90c3ef877a6acf5019cb257e66910de23702f9d3fa06d8b0ba4` |
| `/mnt/fast/scratch-04/17/judge-d12c.sh` | 180 | `7a73f4d6338873e42ac2e62c3031072a5cb4997704a87b4f8b465d50e0b78666` |

Plan 04-18 must assert these exact hashes against this SUMMARY and against the `INSTRUMENT` line of `selftest-17.txt` before arming, so the instrument that runs is the instrument that was proven. **Neither script is in git.** Both line counts were asserted on the far side *before* either was invoked — a zero-byte script exits 0 and prints nothing (04-15 deviation 1).

**The judge's boundary, in its own header and here:** it decides § 1 item 4's **byte condition only**. It does not decide criterion 3. The §§ 1-3 side-effect checks, the § 3 `extended.conf` prerequisite, the Lidarr-import reading a FAIL needs before it may be attributed to a tagger, and the verdict are 04-18's executor's, exactly as § 5 requires.

### Why the ladder was redesigned rather than transplanted

This is the change most likely to be re-litigated, so it is stated plainly. Plan 04-14's ladder discriminated on a snapshot-completeness property it measured by comparing `pre.inv` against the last inventory observed **before the folder vanished** — a *later* observation, which only a poller can make. **A hook fires once and never re-observes.** Its only completeness test is "did the inventory hold across my own hash pass", which is also its publication condition, so a published snapshot always implies completeness: the property is **pinned, not measured**. Transplanting the ladder unchanged would have produced two specific failures — a self-test control that cannot emit its required status, and a clause-7 guard permanently open, so a partially-extracted album would publish, have its remaining tracks land only at COMPLETION, and be reported **FAIL: a tagger rewrote bytes against a clean estate**. So the field is published as `inv_stable`, the retired tokens are absent from both scripts by construction, and completion-only audio is always UNPROVEN with its own token.

### Source facts re-asserted live before the design was trusted

All re-read on 2026-09-15 against SABnzbd **5.1.0** (Alpine container, GNU findutils 4.10.0, bash 5.3.9):

| Fact | Measured |
|---|---|
| `postproc.py:453` | `notifier.send_notification(T("Post-processing"), nzo.final_name, "pp", nzo.cat)` — exact |
| par-repair stage | guard `if all_ok and flag_repair:` at **:456**, `parring(nzo)` call at **:457** (the plan cited :456; the citation is the stage guard and stands) |
| unpack stage | `Status.EXTRACTING` at **:496**, `unpacker(...)` at **:498** (the plan cited :495-496) |
| `Status.MOVING` / `external_processing` / `complete` notification / `get_unique_dir` | **:513 / :611 / :713 / :786** — all exact |
| `newsunpack.py:553-577` | `while nzo.direct_unpacker.is_alive(): ... join(timeout=2) ...`, `wait_count > 60` abort — exact, so SABnzbd genuinely waits there for a still-writing direct unpacker |
| `notifier.py:205` | `Thread(target=send_nscript, args=(title, msg, notification_type)).start()` — fire-and-forget, cannot block the move |
| argv | `[script_path, notification_type, title, msg]` — `$1` event, `$2` title, `$3` `nzo.final_name` |
| `create_env` | supplies the SABnzbd API key and the api url with no `SAB_*` job fields; **key length 32** |
| live ini | `nscript_enable = 0`, `nscript_prio_pp = 0`, `nscript_prio_complete = 1`, `_startup`/`_failed`/`_disk_full` all `1`, `script_dir = scripts` |

## The fourteen controls

Every `STATUS` and `reason` token below is **the judge's own stdout line, pasted whole** into the receipt after the control id and label. Nothing was transcribed from an expectation.

| Control | Required | Observed (lifted) |
|---|---|---|
| **SC-1** POSITIVE | `BYTES-OK files_in_both=2 moved=0 archives_present=no` | `STATUS=BYTES-OK reason=none files_in_both=2 byte_identical=2 changed=0 moved=0 inv_stable=yes archives_present=no candidates=1` ✅ |
| **SC-2** REQUIRED FAIL | `FAIL reason=bytes-changed changed=1 archives_present=no` | `STATUS=FAIL reason=bytes-changed files_in_both=2 byte_identical=1 changed=1 archives_present=no` ✅ |
| **SC-3** | `UNPROVEN no-pp-trigger` | `STATUS=UNPROVEN reason=no-pp-trigger` ✅ |
| **SC-4** | `UNPROVEN no-complete-trigger` | `STATUS=UNPROVEN reason=no-complete-trigger inv_stable=yes dest=na` ✅ |
| **SC-5** | `UNPROVEN no-attributed-pre hash_span_refused=1`, `post.sha256` **present** | `STATUS=UNPROVEN reason=no-attributed-pre inv_stable=no hash_span_refused=1 post_published=yes` ✅ |
| **SC-6** | `UNPROVEN empty-intersection pre_only=2 completion_only=0` | `STATUS=UNPROVEN reason=empty-intersection files_in_both=0 pre_only=2 completion_only=0` ✅ |
| **SC-7** | `UNPROVEN empty-intersection pre_only=0 completion_only=2` | `STATUS=UNPROVEN reason=empty-intersection files_in_both=0 pre_only=0 completion_only=2` ✅ |
| **SC-8** | `UNPROVEN late-extraction completion_only=1` | `STATUS=UNPROVEN reason=late-extraction files_in_both=2 byte_identical=2 completion_only=1 moved=0` ✅ |
| **SC-9** MOVED | `BYTES-OK moved=2 files_in_both=0` | `STATUS=BYTES-OK reason=none files_in_both=0 pre_only=0 completion_only=0 moved=2` ✅ |
| **SC-10** UNMATCHED PAIR | `UNPROVEN unmatched-pair`, neither FAIL nor BYTES-OK | `STATUS=UNPROVEN reason=unmatched-pair pre_only=1 completion_only=1 moved=1 unmatched_pair=1` ✅ |
| **SC-11** EVENT FILTER | `inert_events=3`, no `pre.*`/`post.*`, no `STATUS` | `inert_events=3 acted_no=3 pre_post_written=0 job_dirs=0 exits_nonzero_here=0` ✅ |
| **SC-12** READ-ONLY + EXIT + SECRET | see below | ✅ |
| **SC-13** UNPACK PENDING | `UNPROVEN unpack-pending archives_present=yes`, **not** FAIL | `STATUS=UNPROVEN reason=unpack-pending files_in_both=2 byte_identical=1 changed=1 archives_present=yes` ✅ |
| **SC-14** DEST COLLISION | `UNPROVEN no-complete-trigger candidates=2`, planted file in no manifest | `STATUS=UNPROVEN reason=no-complete-trigger candidates=2 dest=none planted_hashed=no planted_hits=0` ✅ |

**Aggregate, asserted numerically:** 14 `^SC-` lines with 14 distinct ids; exactly **1** `STATUS=FAIL` line carrying `reason=bytes-changed`; **9** `STATUS=UNPROVEN` lines; **2** `STATUS=BYTES-OK` lines; **7** distinct `reason=` tokens across the UNPROVEN lines; the retired tokens absent; both instrument hashes present; the coverage boundary recorded. Gate returned `SELFTEST-17-PASSED-14-CONTROLS-1-FAIL-7-TOKENS`.

### ⚠ The load-bearing result: SC-2 and SC-13 are an executed ablation, not an argument

They drive the **identical input shape** — two `.flac` at the folder root, `pp`, move to `complete/nzb/music/`, one byte appended to one file **after** the move, `complete` — and differ in **exactly one variable**: SC-13 has a `set.rar` and a `set.par2` beside the audio. Both reach `changed=1 byte_identical=1 files_in_both=2`.

- **SC-2**, `archives_present=no` → `STATUS=FAIL reason=bytes-changed`
- **SC-13**, `archives_present=yes` → `STATUS=UNPROVEN reason=unpack-pending`

So the `archives_present` gate — the thing that stops SABnzbd's own post-`pp` repair and unpack being reported as a tagger rewriting bytes on the **normal** shape under `direct_unpack=1` — is measured by changing one input and observing the outcome flip. This is stronger than editing a status field would have been, and it is the answer to "is the gate actually doing anything".

### SC-12's three previously-unmeasurable readings

```
baseline_count=29 fixtures_missing=0 fixtures_unchanged=27 fixtures_differing=2
outside_writes=0 outside_writes_with_control=1 outside_control=1 fence_refusals=0
hook_invocations=25 nonzero_exits=0 apikey_len=32 apikey_hits=0 screen_control=1
```

- **`fixtures_unchanged=27` is exactly `baseline_count - 2`**, asserted as arithmetic (`test "$FU" = "$(( BC - 2 ))"`) against a non-vacuous `baseline_count=29`, with `fixtures_missing=0`. The two differing files are SC-2's and SC-10's deliberate mutations and nothing else. **Baselined files are re-located by INODE**, not by path: a rename preserves the inode, and every control relocates its folder while SC-9 and SC-10 also flatten a subdirectory out of it — a path-based re-check would have reported spurious missing files.
- **`outside_writes=0` with a proven positive control.** Defined concretely as: files under `fixtures/`, `-type f`, newer than the baseline stamp, **not** under any control's `OUTDIR`, and **not** on a driver-recorded declared-change list appended at the moment of each deliberate mutation. A planted undeclared file under `fixtures/` outside `OUTDIR` was **counted** (`outside_writes_with_control=1`), removed behind the fence, and the recount returned **0**. The driver's own artefacts live outside `fixtures/` entirely, so they cannot self-trip the measurement.
- **`nonzero_exits=0` across 25 hook invocations**, and separately: **37 hook/judge stderr files, maximum size 0 bytes, total 0 bytes** — byte counts quoted because an empty error log and an unreadable one look identical (04-15). All **25** stdout lines match the one expected form `d12c <event> <h12|none> ok`, and the three inert events correctly report `job=none`.
- **`apikey_hits=0 screen_control=1`** over the whole output tree, value-based via a pattern file, key never on a command line, no process listing read.

### The host-side coverage boundary, stated as a boundary and not a footnote

`docker inspect sabnzbd` shows exactly three directory mounts (`/config`, `/custom-cont-init.d`, `/downloads`) plus two single-file `:ro` binds, and **`/mnt/fast/scratch-04` is not among them** — so "invoke the hook inside the container against fixtures in host scratch" is not satisfiable, and the alternative (fixtures under `/downloads`, an output tree under `/config`) would write into the live download tree SABnzbd and the arrs are actively watching. The controls therefore ran **host-side on LXC 100**, with `DL_ROOT` and `OUTDIR` relocated into `fixtures/`, the fixture tree built as `fixtures/incomplete/` and `fixtures/complete/nzb/music/` so the **production subpaths** are the ones exercised, and the hook invoked with exactly the argv SABnzbd builds.

**Three properties are NOT covered here:**

1. execution as **uid 568** inside the container namespace;
2. **container-side path resolution** of `/downloads` and `/config`;
3. **`/config` write permissions** from the identity that matters.

All three are covered instead by plan 04-18's arming gate, which asserts a real `event=startup` line in the real `/config/d12c/trigger.log` written by the real SABnzbd process — a fail-closed in-situ proof that the hook resolves, is executable, runs, and can write where it must. **Neither half is sufficient alone; together they cover the whole path.** `nscript_prio_startup` reads `1` in the live ini and is not being changed, so that line will be produced by an event the arming itself triggers.

## Deviations from Plan

### 1. ⚠ [Plan defect — a 13th blocker] SC-12's arithmetic is inconsistent with the plan's own SC-6 and SC-13

- **The contradiction, in the plan's own words.** It requires "a sha256 baseline of **every fixture file** ... before any control runs", `fixtures_missing=0`, and `fixtures_unchanged` equal to `baseline_count - 2` because "SC-2 and SC-10 each mutate exactly one file by design, **and nothing else may differ**". But **SC-6 deliberately deletes two fixture files** (`fixtures_missing` would be 2, not 0) and **SC-13 deliberately mutates a third** (`fixtures_unchanged` would be `baseline_count - 3`). As written, the three gates cannot all be satisfied by any correct harness.
- **Resolved without lowering a single gate**, in the direction 04-14 deviation 4 set:
  - **SC-6's two audio files are created AFTER the baseline stamp**, so they are not baselined and their deliberate deletion cannot manufacture a missing entry. This is the 04-14 SC-8 precedent verbatim ("SC-8's files were created after the baseline, as the plan explicitly permits, because SC-8 deletes them").
  - **SC-13's mutation is measured by the judge and then reverted** — the original size is recorded, one byte appended, the judge reads `changed=1 archives_present=yes`, then `truncate -s` restores it. An append does not touch existing bytes, so the sha256 is restored exactly. **The control is not weakened: its byte difference is real at the moment the judge reads it**, which is the only moment that matters.
  - Both files are on the declared-change list, so `outside_writes` still sees them as accounted-for rather than as undeclared writes.
- **Recorded as the first deviation because the tempting move was to change `- 2` to `- 3`.** That would have relaxed an assertion to fit a harness, which is exactly what 04-14 deviation 4 refused.

### 2. ⚠ [Plan defect] SC-14's table omits the `pp` leg its own required outcome needs

- SC-14's required outcome is `STATUS=UNPROVEN reason=no-complete-trigger`, which is **clause 2**. The table describes only "create the stale folder, land the output in `<name>.1/`, then `complete`" — with no `pp` invocation. Without one, **clause 1 (`no-pp-trigger`) pre-empts clause 2** and the control measures the wrong clause entirely, exactly the defect the plan itself caught for SC-5 (`post_published=yes` exists because clause 2 pre-empts clause 3).
- **Fix:** a `pp` leg was added, and the sequence made faithful to reality — the stale `complete/nzb/music/<name>/` is created **first** (which is *why* `get_unique_dir` would produce `<name>.1`), then the job folder appears under `incomplete/`, `pp` fires and publishes, the output lands at `<name>.1/`, then `complete`. Result: `candidates=2`, nothing published, `planted_hashed=no planted_hits=0`.

### 3. [Plan gap closed by decision] `outside_writes` needed a concrete definition the plan left underdetermined

- The plan defines it as "files under `fixtures/` newer than the baseline stamp **and** outside `$OUTDIR`" and requires **0** — but SC-2, SC-10 and SC-13 all deliberately write such files by design, so the measurement as literally defined can never be 0.
- **Definition used, recorded so it is auditable:** files under `fixtures/`, `-type f`, newer than the baseline stamp, not under any control's `OUTDIR`, **and not on a list the driver appends to at the moment of each deliberate change**. Every entry on that list is written by the driver as it acts, so anything absent from it is by construction an *undeclared* write. Non-vacuity is proven two independent ways: the planted positive control is counted, and `fixtures_unchanged = baseline_count - 2` independently pins that exactly two baselined files differ.

### 4. [Rule 1 — Bug, my own harness] The CLEANUP line shipped a boolean under a label that says the opposite

- **Issue:** the driver computed `[ -e "$FX" ]` correctly into `FXGONE` and then printed it as `fixtures_present=$FXGONE`. The first receipt therefore read **`fixtures_present=yes`** when the fixture tree was **gone**.
- **Caught by reading the output rather than the exit code** — the driver exited 0 and the plan's gate never looks at that field.
- **Fix:** the boolean was **re-measured live** (`fixtures exists: NO`, confirmed by `ls`) and the line rewritten as `fixtures_removed=yes`, keeping the three counters lifted verbatim from the driver's own record; the driver was corrected and re-transferred so the receipt stays reproducible.
- **Recorded prominently because it is this phase's signature defect class in my own hands**: a field named after the opposite of what it measures. It is exactly why the amended contract insists the hook publish `inv_stable` and not the poller-era name — and it survived here precisely because **no gate reads that field**, which is where this class always survives.

### 5. [Measured correction to the plan's arithmetic] The unscoped token count is 9, not 8

- The plan states the unscoped distinct-token form "would also count SC-2's `reason=bytes-changed` and return 8, failing a perfect instrument". **Measured on this receipt: the scoped form returns 7 (the gate passes) and the unscoped form returns 9** — because this judge also emits `reason=none` on its two `BYTES-OK` lines.
- **The plan's conclusion is confirmed and strengthened, not weakened:** the unscoped gate is unsatisfiable by a correct instrument, and the scoping the plan added is load-bearing. Both counts were measured rather than reasoned about.

### 6. [Measured correction] The plan's argv title for `pp` is not the title SABnzbd sends

- The plan's Task 3 says to invoke with `pp "SABnzbd: Post-processing" "<fixture-name>"`. Measured: `notifier.py:504` builds `"SABnzbd: " + T(NOTIFICATION_TYPES[notification_type])`, and `NOTIFICATION_TYPES["pp"]` is **`"Post-processing started"`**. The controls used the measured titles (`SABnzbd: Post-processing started`, `SABnzbd: Job finished`).
- Nothing depends on it — the hook ignores `$2` by design and reads only `$1` and `$3`. Recorded because the plan's stated aim was "**exactly** the argv SABnzbd uses", and a plan that got argv wrong would have mattered had `$2` been load-bearing.

### 7. [Measured] ±1-2 line drift in the plan's stage table, re-asserted rather than assumed

`parring()` is **called** at `:457` behind the `if all_ok and flag_repair:` guard at `:456`; `Status.EXTRACTING` is at `:496` and `unpacker(...)` at `:498` (the plan's table said 495-496). `:453`, `:513`, `:611`, `:713` and `:786` are exact. The plan's cited `postproc.py:456` is the stage guard and the citation stands; the amendment records both numbers in-band so a future reader meets the measurement rather than the approximation.

### 8. [Recorded implementation choice] The internal timeout is a self re-exec with a `--worker` sentinel

- The plan requires "the body is bounded by an internal `timeout`". A single-file hook cannot bound its own body any other way, so the script re-invokes itself as `timeout 240 /bin/bash "$SELF" --worker "$@"`. The sentinel cannot collide with a real invocation: every event name comes from `notifier.py`'s `NOTIFICATION_TYPES` and none begins with a dash. `timeout` was verified present **both** host-side and in the container, with a direct-invocation fallback if it ever is not.
- `HOOK_TIMEOUT=240` is a **plain constant, not an override**, for the `check-music-freeze.sh` reason: an override on it could be used to make a capture silently not happen.

### 9. [Recorded] The hook never deletes, so a refused manifest is renamed rather than removed

The plan says "It never deletes". On a refused hash span the temporary is therefore `mv`'d to `pre.refused` instead of being unlinked — auditable, and it keeps the script free of any `rm`.

### 10. [Recorded] The judge prints `na`, not `0`, for counts on a clause-1/2/3 line

Nothing was compared on those lines, and a `0` there is "could not look" wearing the clothes of "nothing is wrong". The window-2 `OBS` block used `0`; this is a deliberate departure. No gate reads a count on those lines.

### 11. [Recorded] SC-12 executes last, though its receipt id is 12

It measures the whole run, so it must run after SC-13 and SC-14. The receipt's line order is control id, not execution order — recorded so the two are not conflated.

### 12. [Plan constraint breached, trivially] `direct_unpack` was read once, read-only

The plan says it is "not read, not written and not toggled" here. It was **read once** in the closing assertion sweep, to record that it still reads `1`. It was **not written and not toggled**, and the ini is byte-unchanged (`nscript_enable = 0` still returns exactly 1 match). Recorded rather than quietly done.

### 13. [Plan latitude exercised] Four extra files left in host scratch

The plan says to leave "the two scripts plus `selftest-17.txt`". Also left: `drive17.sh` (corrected), `verify2.sh`, `verify3.sh` and `valuescreen.sh` — so the fourteen-control receipt is **reproducible**, 04-18 can re-assert both gates without re-deriving them, and the value-based credential screen is available to 04-18 and 04-19, which will both write to this public repo.

---

**Total deviations:** 13 — **2 defects found in the plan's own gates** (one of which made three assertions jointly unsatisfiable), 1 underdetermined definition closed by decision, **1 auto-fixed bug in my own harness**, 3 measured corrections to the plan's stated facts, 4 recorded implementation choices, 1 trivial constraint breach, 1 exercise of latitude.

**No assertion was weakened, no gate was lowered to accommodate a control, no receipt line was hand-written, no status token was transcribed rather than lifted from the judge's own stdout, the amendment deleted nothing, and nothing was armed.**

## Nothing was armed — asserted three ways plus one

| Assertion | Measured |
|---|---|
| `/config/d12c` | **absent** |
| `/config/scripts/d12c-nscript.sh` | **absent** |
| `grep -c '^nscript_enable = 0$'` in the live ini | **1** |
| `config/scripts` entry count | **9** — unchanged, which independently confirms the amendment's pre-declared "9 → 10" for the window |
| `fixtures/` | **absent** — 132 files deleted individually behind the S5 fence (`realpath -e` containment, 0 refusals), 49 directories by `rmdir` deepest-first. **No `rm -rf` was executed** |

`bash scripts/quick-health-check.sh` from the workstation: **exit 0**, **0 `❌` and 0 `⚠️`** — the 04-01 ROUTINE BASELINE Traefik `❌` is gone, cleared by quick task 260915-k9p. Census counters all at target: `beets databases: 1`, `tagger databases: 0`, `retired paths present: 0`, `rw on Music, non-tagger: 0`, `rw on Music, tagger-capable: 0`, `FAILURES total: 0`, drift block green (`✅ vendored files match (3)`).

## Threat Flags

None. This plan added no network endpoint, auth path or trust boundary. Against the plan's register:

- **T-04-17-01 (a contract fitted to its evidence)** — mitigated. Committed in its own additive commit before any window, stamp or arming exists; deletions asserted **0**; every `^Verdict` line proven byte-identical by `diff` against `$SHA^`; the commit resolved by `--grep`, never by `HEAD`.
- **T-04-17-02 (a false FAIL against a clean estate)** — mitigated **and measured**. The pinned discriminator is retired; completion-only audio is always UNPROVEN; the single FAIL clause is gated on `archives_present` with a missing field treated as `yes`. SC-8 and SC-10 drive the two shapes that would previously have produced a false FAIL and both return UNPROVEN, and **SC-13 versus SC-2 is a one-variable ablation** proving the gate is what produces the difference.
- **T-04-17-03 (PASS made unreachable by the instrument)** — mitigated. The floor counts MOVED pairs; SC-9 drives it at `moved=2 files_in_both=0`; SC-1 asserts `files_in_both=2` so a relative-versus-absolute path bug cannot masquerade as window 2's real result.
- **T-04-17-04 (the 32-character API key)** — mitigated. Every forbidden disclosure verb asserted absent from the hook as it exists on the host, with an `env`-invocation pattern that ignores comment lines and a bare-builtin check; the shebang forced to `#!/bin/bash` so the screen carries no line-1 exemption. Both screens value-based via a pattern file, each with a planted positive control (`screen_control=1`); the amendment contains **0** occurrences of the literal token.
- **T-04-17-05 (release names into a public repo)** — mitigated. Per-job output subdirectories keyed by a 12-character sha256 prefix; `names.tsv` is the only file carrying a real name and it went with the fixture tree. Every fixture name in this record is synthetic (`sc01-…`), because no estate content was used.
- **T-04-17-06 (fixtures written where the estate can see them)** — mitigated. Controls ran under `/mnt/fast/scratch-04/17/fixtures/`, which `docker inspect` confirms is not mounted into the container; fixtures were random bytes and **no estate audio was copied**; `outside_writes=0` with a planted positive control against a non-vacuous 29-file baseline and `fixtures_missing=0`; removal behind the S5 fence with no `rm -rf`.
- **T-04-17-07 (this plan arming the estate early)** — mitigated and asserted four ways (table above). Arming is 04-18's and only 04-18's.

## Known Stubs

None. Both scripts are complete and driven; the receipt is written; the amendment is committed. `fixtures/` is absent and the instrument, receipt, driver and two transcribed gates survive for 04-18.

## Issues Encountered / carried forward

- **The one thing fourteen host-side controls cannot prove**, flagged for 04-18 and stated in the receipt's `COVERAGE` line: execution as uid 568 inside the container namespace, container-side resolution of `/downloads` and `/config`, and `/config` write permissions. 04-18's `event=startup` arming gate is the other half and is not optional. `/bin/bash`, `sha256sum`, GNU `find` with `-printf`/`-print -quit`, `realpath`, `cut`, `date +%s%N` and `timeout` were each verified present **inside the container** as well as host-side, so the remaining risk is permissions and identity, not tooling.
- **The hook cannot block the move and never will.** `notifier.py:205` is `Thread(...).start()`. Window 3 buys a structural head start, not a mutex, and the amended contract says so in-band. If a real job's PRE-HOOK snapshot still straddles the move, the publication protocol refuses and the job is `no-attributed-pre` — the same honest OPEN window 2 produced, not a false FAIL.
- **A FAIL will need a Lidarr reading before it may be attributed to a tagger.** Lidarr polls the completed folder and can write tags on import, presenting identically to clause 5b. The amendment names it; 04-18's executor must record it.
- **`quick-health-check.sh` still carries no `nscript_*` guard**, so an armed estate is invisible to the standing checks. The amended § 5 answers this with a declared **maximum armed lifetime** rather than a new check, and the restoration is 04-18's terminal act.
- The survivor beets container remains deliberately stopped; nothing in this plan started it. The 6 stale January orphans under `/mnt/tank/downloads/incomplete` were not touched — no control went near the real downloads tree.

## Self-Check: PASSED

- FOUND `.planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md`; `Amended 2026-09-15 by plan 04-17` = **2**, `^Verdict:` = **1**, `^Verdict (window 2):` = **1**, `^Verdict (window 3)` = **0**, the literal key-name token = **0**, all 25 required literals present, the forbidden restatement phrase absent.
- FOUND commit `8646432` (`86464320b06d…`), touching exactly **1** file, **238** insertions / **0** deletions, resolved by `--grep`; every `^Verdict` line `diff`-identical to `$SHA^`.
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-17-SUMMARY.md`.
- Host: `d12c-nscript.sh` (317 lines) and `judge-d12c.sh` (180 lines) present at the recorded sha256; `selftest-17.txt` present with **14** `^SC-` lines; `fixtures/` absent; positive controls `/mnt/fast/appdata` and the sabnzbd container both visible.
- Both host gates re-run against the final tidied state: `INSTRUMENT-BUILT` and `SELFTEST-17-PASSED-14-CONTROLS-1-FAIL-7-TOKENS`.
- Estate untouched: `/config/d12c` absent, `/config/scripts/d12c-nscript.sh` absent, `nscript_enable = 0`, `config/scripts` still 9 entries. `quick-health-check.sh` exit **0**, 0 `❌`, 0 `⚠️`.
- No commit deleted any tracked file. Only one explicit path was staged.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-15*
