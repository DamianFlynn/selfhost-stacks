---
phase: quick-261111-rmv
verified: 2026-11-11T20:45:00Z
status: passed
score: 6/6 must-haves verified (Telegram arrival on the phone not observable)
overrides_applied: 0
human_verification:
  - test: "Confirm the Telegram messages for alerttest-crashloop arrived on the phone (restart loop firing ~20:23Z, restarting firing ~20:24Z, resolves ~20:29Z and ~20:34Z)"
    expected: "Separate per-container messages, one per rule, then resolve messages"
    why_human: "Grafana recorded notify attempts with no error, but delivery to the phone cannot be observed from here"
---

# Quick 261111-rmv: Restart-loop alerting Verification Report

**Goal:** a crash-looping container on LXC 100 pages Telegram within about 10 minutes.
**Verified:** 2026-11-11T20:45Z. **Re-verification:** No.

## Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Crash loop gives a per-container Firing alert within ~10 min and a Telegram notify attempt | VERIFIED, with caveat | Rules exist in the repo (group `container-restarts`, three rules, expressions as designed). The live proof exists only in SUMMARY (fired T0+6m50s, notify attempts with no error). I could not re-run it (read-only brief), but the deployed pieces it depends on are confirmed live (below). Arrival on the phone is a human check. |
| 2 | Alert resolves on removal without touching Grafana | VERIFIED (SUMMARY evidence only) | The rules have no manual-reset path. Test container is gone (`docker ps -a --filter name=alerttest` is empty). |
| 3 | Exporter failure leaves the .prom byte-identical and the stale rule fires | VERIFIED | The script has no write on any could-not-look path. Every failure goes through `could_not_look`, which exits 1 before the tmp write. The temp file is `.container-restarts.prom.tmp.$$` (not `*.prom`), then `mv -f`. Stale rule: `time() - max(..last_success_timestamp_seconds) > 360`, noData and execErr both Alerting. The timestamp is written last. |
| 4 | Standing unhealthy/created alert clears | VERIFIED | `check-drift.sh:489` counts only `state == running && health == unhealthy`. Live `image-drift.prom` has `selfhost_containers_unhealthy 0`. |
| 5 | No `can't evaluate field State` template error | VERIFIED | The docker format braces in rules.yaml are escaped (`{{ "{{" }}`). A grep for unescaped `{{` outside `$labels`, `$values` and the escape returns nothing. Live: 0 matches in grafana logs since its restart at 20:15:25Z. |
| 6 | qhc exits 1 on running-unhealthy or restarting, UNKNOWN on could-not-look | VERIFIED | `scripts/quick-health-check.sh` lines ~1405-1453. The unhealthy arm sets `EXIT_CODE=1`. The restarting block has the CR-03 shape: pipefail in the remote string, rc read on the next line, rc 124 split out, an `INSPECTED n>0` requirement, and UNKNOWN sets `EXIT_CODE=1`. `bash -n` passes. |

## Live host checks (read-only, 20:44Z)

- `selfhost-container-restarts.timer` is active; next run 20:46:00, last 20:44:04; the service shows `Result=success`, `ExecMainStatus=0`.
- `container-restarts.prom` is 27 s old and has 91 `restart_count` series against 94 total containers (the rest exited, which is consistent). `restarting 0` and `running_unhealthy 0`.
- Zero UNKNOWN or fail lines in the journal over the last 30 min.
- Grafana is running with RestartCount 0 (started 20:15:25Z). Zero `can't evaluate field` since then.
- Host HEAD is `ccd8aeb6`, equal to the local HEAD and `ls-remote origin`.
- The installed timer carries `0/2`.

## Artifacts and key links

- All eight plan files exist and are committed (`752bfbf4` has 4 files, `ccd8aeb6` has 4 files).
- The service ExecStart path, TimeoutStartSec=60, OnCalendar=`*:0/2`, AccuracySec=5s and the 360 s cross-reference are all present.
- The `group_by` is `[alertname, grafana_folder, name]` with no new route.
- The group has exactly 3 rules with unique uids. `noDataState` and `execErrState` are Alerting on all of them.
- The qhc notice header count is 17, as claimed. The README section `## Restart-loop detection` exists.
- No TBD/FIXME/XXX in the new files.

## Findings

- WARNING (minor, accepted by the executor, documented): the metric `selfhost_container_restart_count` trips promtool's `_count` naming lint. It still parses (`--lint=none`). Not a goal failure.
- Not re-proven by me: the S6/S7 end-to-end timings and the Telegram notify attempts rest on SUMMARY log evidence. Nothing I checked contradicts them.

## Human verification required

1. Confirm that the Telegram messages for alerttest-crashloop arrived on the phone. They should be separate per-container messages, one per rule, followed by resolve messages. Delivery is not observable from here.

No gaps found.

_Verifier: Claude (gsd-verifier)_

## Human check — resolved 2026-11-11

Operator confirmed the four Telegram messages for `alerttest-crashloop` (two firing, two resolved) arrived on the phone. Status upgraded human_needed → passed.
