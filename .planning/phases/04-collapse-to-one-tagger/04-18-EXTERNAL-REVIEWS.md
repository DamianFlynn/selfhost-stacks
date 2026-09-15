# Phase 4 — external model reviews of plan 04-18

**What this file is.** Four external-model outputs, reproduced **verbatim** for the record. All
four reviewed `.planning/phases/04-collapse-to-one-tagger/04-18-PLAN.md` on 2026-09-15. The
session scratchpad they were produced in does not survive the session; this file is the only
durable copy.

**They are model output, not verified fact.** Not one finding below has been independently
confirmed against the text of `04-18-PLAN.md` by this repo's own process. Treat every line as a
claim to be checked, not a defect on the record. That caution is earned: on this project a
same-family reviewer has already been confidently wrong at least once, and this repo's standing
note on cross-model review is that same-family reviewers share blind spots while *reading* as
consensus.

**The count, stated precisely.** These are four external outputs spanning **three** non-Anthropic
model families — Google Gemini (review 1), GPT-5.5 (reviews 2 and 4, the same family reached
through two different tools) and Kimi-K3 (review 3). Adding the in-session Claude review, which is
**not** reproduced here, gives **four model families in total**. "Four external families" would be
the wrong number.

**Why they matter.** These reviews are the stated reason observation window 3 was closed unrun.
Plan 04-17 built the third capture design and all 14 of its synthetic controls passed, but between
them these reviewers found roughly 30 defects in 04-18, the plan that would have armed it —
including a judge binary that self-reports every PASS condition, an OPEN branch that can swallow a
FAIL, and a restore contract that is count-checked rather than diffed. A PASS from that instrument
would not have been trustworthy, which is the entire reason for running it. The unsigned
criterion-3 override in `.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md` cites this
file.

## Review 1 — pi, Google Gemini

Findings:

- **ARMED with no reliable watchdog / cancellation broken**
  - **L232-239 vs L339-344: duplicate watchdog designs conflict.** Step 0b correctly starts watchdog before estate writes and has the shell write `watchdog.pid`; later Step 1 says “Arm the watchdog” again after stamp, with a command that does **not** write its own pid, then says record PID. This can overwrite the good pid, leave two watchdogs, or cancel/assert the wrong one.
  - **L339-344 violates the plan’s own “before first estate write” invariant.** If executor follows the later instruction, the watchdog is after hook staging, output-tree creation, ini edit, restart.
  - **L669-674 after L664-666 is impossible.** Step 8 deletes `/mnt/fast/scratch-04/18` before reading `watchdog.pid`. The pid and script are gone before cancellation. A sleeping watchdog may remain, and verify may catch `restore-18`; if not caught, deadline runs a missing script.
  - **L188-195 + L212-220 + L283-286: predrive restore depends on `nscript.preedit` before it exists.** Restore is specified to restore from `/mnt/fast/scratch-04/18/nscript.preedit`, but predrive happens before P6 writes it. Either predrive fails, or restore must silently special-case missing contract, weakening the property.
  - **L241-250 / L376: arming trap is only grep-verified.** `grep -qE '^[[:space:]]*trap '` proves a trap line exists, not that it is installed before the first estate write, traps ERR+EXIT correctly, or clears only after success.
  - **L454-459: resume checks deadline, not watchdog liveness.** If watchdog dies early and human has not answered yet, estate remains armed; quick-health-check has no `nscript_*` guard.
  - **L652-659: if screen/commit fails, no Task 3 trap restores immediately.** The only defence is watchdog. If watchdog died, estate remains armed until discovered.
  - **L726 says restore was driven once**, contradicting L212-220/L379 twice. Not directly dangerous, but this is exactly the safety property.

- **Missed / weak gates**
  - **Receipt arithmetic inconsistent.** L16 says 12 controls / 6 distinct UNPROVEN; L265-272 says 14 / 7; L386 repeats stale 12 / 7 UNPROVEN / 6 distinct; L392 says 14 / 9 / 7. Verify uses 14/9/7, but acceptance text is internally contradictory.
  - **Value-based API-key screen is prose-only.** L652-657 requires reading the 32-char key and planted-control screening. The automated verify at L680 only greps labels/long runs. A raw 32-char key can be committed and pass if it does not include `api_key`, `apikey`, etc. Public repo risk remains.
  - **API key tracked-file path:** SABnzbd `create_env()` gives the hook the key (L715). If §8 accidentally quotes raw hook env/trigger output, the current automated gate misses the 32-char value (L680). The summary file is also created (L761-768) but not included in the commit/screen invariant.
  - **`nonmusic_pp=0` can be vacuous.** L533-537 counts pp lines “whose job maps to a non-music job”; unmapped movie/TV hook lines can escape as not counted. This does not prove no non-music invocation.
  - **“Hook fires only for pp and complete” is false as written.** Startup is intentionally used (L318-327), failed/disk_full priorities remain 1 (L111), and inert events are counted (L533-535). The real property is “acted only for music pp/complete,” not “fires only.”
  - **Section-scope mostly fixed, but not everywhere.** L680 scopes overclaim checks to `sed -n '/^## 8/,$p'`, which is okay only while §8 is last; future appended sections can satisfy/break the gate. Should bound to next `^## ` or EOF.
  - **`snapshot_files>=1` is too weak.** L493-501/L693 rejects 0, but a partial copy with only `trigger.log` and no job manifests can still satisfy. For jobs ≥1 it should require the expected per-job artefacts, not any one file.
  - **`watchdog_fired` can race.** L503-509 records from restore.log before later steps; watchdog may fire after that and before terminal restore, leaving committed `watchdog_fired=no`.

- **Clean estate still accused?**
  - **Yes, possible.** `archives_present=no` is not sufficient by itself.
  - **L573-575 records Lidarr import but verdict ignores it.** OBS has `lidarr_imported=<yes|no|unknown>` (L615), but PASS/FAIL/OPEN rules L623-634 and verify L680 do not require `lidarr_imported=no` for FAIL. A Lidarr tag write can still be accused as estate/tagger byte mutation.
  - **`repair_or_unpack_after_pp=unknown` does not block FAIL.** L569-572 says contradiction avoids FAIL only when read is `yes`; verify only asserts `RUP != yes` (L680). Unknown log parse/rotation/timestamp ambiguity can still allow FAIL.
  - **Repair/unpack corroboration is global, not per-job.** L615 has one `repair_or_unpack_after_pp` for all jobs. Multi-job windows can mix clean/dirty causes without per-job gating.
  - **Direct-unpack can rewrite same-path audio after pp even when archives are not visible to the manifest.** L121-126 names this normal shape. If archive detection misses because archives were already removed, not in the compared set, or the log parser misses the unpack wait, `archives_present=no` can be a false precondition.
  - Safer rule: byte FAIL requires **per-job** `archives_present=no`, `repair_or_unpack_after_pp=no`, `lidarr_imported=no`, successful producer RCs for those corroborations, and no unknowns; otherwise OPEN.

## Review 2 — pi, github-copilot gpt-5.5

- L260-263 / L376 / L552: P2 promises both hook and `judge-d12c.sh` hashes are in the receipt, but the automated arming gate only checks the staged hook hash. A tampered judge can still be run.

- L533-537 / L615 / L623-627: category-leak proof only counts non-music **pp** lines. A non-music `complete` invocation is not represented or gated, yet PASS only requires `nonmusic_pp=0`.

- L538-542 / L616 / L623-627: `find …/config/scripts -newer <stamp>` hits have no OBS counter. The PASS gate only sees `find_scripts_rc=0`, so “command succeeded and found a post-stamp script write” can silently pass.

- L588 / L614 / L623-627 / L680: close-side ReplayGain check regresses to `grep -c '^ReplaygainTagging="false"'`; OBS has `replaygain_last`, but PASS/verify never require `replaygain_last=ok`. A last-assignment `TRUE` can pass if `replaygain_line=1`.

- L560-565 / L612-615 / L623-627: `resolution_matched_storage` is per-job in prose but a single aggregate OBS field. Multi-job evidence can’t prove every COMPLETION manifest matched its own SAB history row.

- L566-572 / L612-615 / L680: `repair_or_unpack_after_pp` is described per-job but recorded/gated as one aggregate. The FAIL guard cannot prove the failing job specifically had no post-pp repair/unpack.

- L615 / L623-627 / L680: `hook_sha256_matched=<yes|no>` is recorded but never required for PASS. Mid-window hook tampering can be documented as `no` and still pass if the job lines say `BYTES-OK`.

- L545-549 / L147-150: §8 is told to quote `Audio.txt` residual lines verbatim, but those lines can contain real release/folder names; this bypasses the public-repo h12-only naming rule.

## Review 3 — pi, ollama-cloud kimi-k3

Findings not on the prior list, by question:

**1. Other orderings with no live defence**

- **L454-459 (Task 2, deadline-passed branch):** on expiry the plan *assumes* "the watchdog has already restored the estate" and proceeds to a history-only close. No ini assertion, and no instruction to invoke `restore-18.sh` if the expected `restore.log` line is absent. The watchdog is a plain host process (LXC reboot/OOM kills it permanently; nothing re-launches it, and liveness is asserted only once at arm time, L376). If it died silently: estate stays armed, plan believes it disarmed, and only Task 3's Step 8 would ever fix it — a session death on this branch leaves it armed forever.
- **L461-463 (extend) + L234/L341:** re-arming never cancels the first window's watchdog. The new watchdog overwrites `watchdog.pid` (`echo $$`), orphaning the old one, which then fires *mid-second-window* (its deadline is earlier) and silently restores the estate — hook deleted, ini reverted — while the plan believes itself armed. Jobs after that firing are never captured but believed captured.
- **L241-242 (abort path) vs L503-506/L669-674:** a P-gate failure "stops the plan and invokes restore-18.sh trap" — nothing cancels the watchdog armed at 0b. The plan ends leaving an orphaned privileged process that fires up to 90 min later and docker-stop/starts the live container outside any window. Every cancel instruction is scoped to Task 3's success path.
- **"arm epoch" is never recorded.** L490's read_first and L494's deadline math consume an "arm epoch" no task creates (L346-368's pre-state list omits it; L232 records only `MAX_ARMED_S`). If the stamp epoch is used instead, the true deadline (watchdog launch at L234, *before* arming) is earlier than computed by the whole arming duration — against a 5-minute margin in L494.

**2. Gates that pass without proving**

- **P2 is half-implemented (L261 vs L376):** prose requires `d12c-nscript.sh` *and* `judge-d12c.sh` hashes grepped from the receipt; the gate greps only the staged hook's hash. Judge-d12c.sh — which produces every `STATUS`/count token § 8 publishes (run at L552) — is hash-asserted **nowhere**, in Task 1 or Task 3. Distinct from the "pinned nowhere" item: even the receipt-grep the plan itself specifies skips the judge.
- **L376 `test $(grep -c . $P) = 4`:** the `nscript.preedit` restore contract is count-checked only — never diffed against the fence copy `$B` or the live ini. Preedit containing the *window-3* values passes arming; every in-window trap/watchdog restore then writes the armed state believing it restored. Only the terminal literals (L680) catch it, after preedit is deleted (L664-666) so no diagnosis remains. Distinct from the ordering item at L212/L283.
- **`replaygain_last` parsed by no rule (spec L614; gate L680 extracts only `replaygain_line=`):** a close-side `="TRUE"` last assignment with exactly one assignment line gives `replaygain_line=1` and the PASS branch (L624-626, L680) is fully satisfiable. § 3's "changed → PASS unavailable" is unenforced (`extended_conf_changed` via `-newer` misses an mtime-preserved rewrite).
- **`hook_sha256_matched` parsed by no rule (spec L615; PASS branch in L680 omits it):** a mid-window hook swap records `no` and PASS still passes.
- **OPEN branch satisfiable alongside a FAIL condition (L680):** `OPEN) test J=0 -o UNP>=1 -o ...` — no clause requires `BAD=0` or zero side-effect counters, so a window carrying `STATUS=FAIL` or `success_lines=1` *plus* any UNPROVEN/non-zero rc/`RMS=no` can be committed as OPEN and pass. The FAIL-over-UNPROVEN precedence (L636) exists only as a prose sentence.
- **RUP/RMS/lidarr are window-level singletons for per-job measurements (L560, L566, L573 vs L615):** a two-job window with one `unpack-pending` and one `bytes-changed` cannot be represented — `RUP=yes` blocks a legitimate FAIL via `test "$RUP" != yes` (L680); `RUP=no` misrecords the other job. Distinct from the `unknown`-not-blocking item.
- **Append-only `restore.log` breaks the predrive gate on re-arm (L202-210, L376 PD/PDT):** on an `extend`, `PD >= 2` and `PDT < stamp` are satisfiable by the *first* arming's predrive lines alone — zero drives on the current contract pass. Same class: stale `arm.rc` from the first arming survives in the undeleted scratch dir and satisfies `test $(cat arm.rc) = 0`.

**3. Clean-estate FAIL / tampered-estate silent PASS**

- **Clean FAIL via the plan's own watchdog (L493-495 → L543-544 → L628-630, L680 FAIL branch):** the deadline is checked once at Step 1 and never re-checked before Step 4's reads. The watchdog can fire any time before Step 8; its restore docker-stops SABnzbd (L191-193), the shutdown re-save writes a fresh `sabnzbd.ini.bak` newer than the stamp, and the `.bak -newer` find attributes it to the window as `bak_new=1` → FAIL on an estate the plan itself dirtied. No gate excludes a FAIL when `watchdog_fired=yes`, and the arm-epoch defect above moves the true deadline earlier than the executor's margin.
- **Silent PASS via instrument substitution:** the unhashed judge (P2 item) plus the two in-no-rule fields (`hook_sha256_matched=no`, `replaygain_last=bad`) are all tamper states that reach PASS through the L680 branch. A swapped judge alone suffices: every PASS condition is self-reported by it.
- **Silent downgrade:** the OPEN-branch hole above lets a real violation (side-effect counter or `STATUS=FAIL`) be committed as OPEN and pass verification — not a PASS, but it buries a dirty estate in the record 04-19 will consume.
- **Public-repo name leak into § 8 (L548 + L604-605):** "quote the residual lines verbatim" — the `Audio.txt` `ERROR: Unable to match …` lines embed the release/folder path. Verbatim quoting contradicts T-04-18-04's own doctrine (`Verified Track:` lines never quoted — these carry the same names), and neither screen (L652-657 value screen, L680 label/40-run heuristics) can see a release name.

## Review 4 — GitHub Copilot CLI, gpt-5.5

**Trimmed at both ends, and nothing else.** Dropped from the head: a tool-call transcript of
`Read` and grep-search calls, which is noise. Dropped from the tail: a four-line telemetry footer
whose keys are `Changes`, `AI Credits`, `Tokens` and `Resume`, because the last of those carries a
Copilot CLI session identifier that has no place in a public repo; that identifier is not
reproduced here or anywhere else in this file. Everything between — the eight numbered findings —
is verbatim and complete.

1. L455-L458, L507-L509: expired watchdog is treated as “already restored” from a log line only; no `RESTORE-OK` or restored-state assertion before Task 3 continues. If watchdog restore failed, estate is still armed and the watchdog is dead.

2. L335-L341, L376, L379: “watchdog before first estate write” is asserted by `watchdog.pid` mtime `<= d12c.stamp`, but the stamp is created after staging/edit/restart. A watchdog launched after all estate writes but before the stamp still passes.

3. L290 vs L379: arming prerequisite P7 requires restore driven **once**, while the property being relied on is idempotence proven by **two** predrives. The gate can arm without proving the stated property.

4. L26, L535-L536, L604, L615, L625, L689: category leakage is reduced to `nonmusic_pp=0`. Non-music `complete`, `failed`, `disk_full`, or startup invocations can exist and still satisfy the PASS gate.

5. L585-L587, L614, L625, L680: close-side ReplayGain reverts to the old false-line count, and PASS never checks `replaygain_last=ok`. An OBS line with `replaygain_last=bad` can still support PASS.

6. L511-L516, L612: `rows_after_stamp=<J>` is named as after-stamp count, but `J` is computed from a query bounded by both stamp and close. Rows after stamp but after close are excluded.

7. L455-L458, L507-L509, L538-L542, L630-L633: if the watchdog fires on a clean timed-out window and its restore creates/updates `sabnzbd.ini.bak` after the stamp, `bak_new` forces FAIL even when `jobs=0` should be OPEN.

8. L680, L700: final “no restore-18 process” gate contradicts its own rule: the remote verification command itself contains `restore-18`, so `ps | grep restore-18` can match the verifier and fail a clean estate.
