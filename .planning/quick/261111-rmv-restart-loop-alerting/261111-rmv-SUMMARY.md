---
phase: quick-261111-rmv
plan: 01
status: complete
subsystem: monitoring
tags: [grafana, alerting, node-exporter, docker, restart-loop, quick-health-check]
requires: [node-exporter textfile collector, Grafana unified alerting -> telegram-estate]
provides: [container-restarts.prom every 2 min, container-restarts rule group, qhc restarting check]
affects: [scripts/check-drift.sh unhealthy tally, notification grouping for every rule]
tech-stack:
  added: []
  patterns: [fail-closed oneshot textfile exporter + timer, per-container alert instances grouped by name]
key-files:
  created:
    - scripts/export-container-restarts.sh
    - scripts/systemd/selfhost-container-restarts.service
    - scripts/systemd/selfhost-container-restarts.timer
  modified:
    - scripts/check-drift.sh
    - stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml
    - stacks/selfhosted/monitoring/grafana/provisioning/alerting/notification-policies.yaml
    - scripts/quick-health-check.sh
    - stacks/selfhosted/monitoring/README.md
decisions:
  - "Unhealthy means RUNNING and unhealthy, in check-drift, the exporter and qhc alike (DD-1)"
  - "Root notification group_by gains `name`; no second route (DD-2)"
  - "Kept the plan's metric name selfhost_container_restart_count despite promtool's `_count` naming lint; parse validity is proven with --lint=none --extended"
metrics:
  duration: ~29 min (20:09-20:38 UTC)
  completed: 2026-11-11
  tasks: 3
  files: 8
---

# Quick 261111-rmv: Restart-loop alerting Summary

A crash-looping container on LXC 100 now pages Telegram. A fail-closed 2-minute exporter
(`export-container-restarts.sh` plus a timer) feeds three new Grafana rules. The standing
`Containers unhealthy or stuck created` red is cleared, its template error is fixed, and
quick-health-check now fails on restarting and running-unhealthy containers. The whole path was
proven live with `alerttest-crashloop`: the first alert fired 6 min 50 s after the loop started,
and it resolved without anyone touching Grafana.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | `752bfbf4` | feat(monitoring): add 2-minute container restart exporter; count unhealthy among running containers only |
| 2 | `ccd8aeb6` | feat(monitoring): page on container restart loops; fix unhealthy-rule template; qhc restarting check |
| 3 | — | deploy and proof only (no repo files); pushed `ccd8aeb6` |

## STEP 0 pre-flight (LXC 100, 2026-11-11T20:09Z, read-only)

One `docker ps -aq` + `docker inspect` pass over 92 containers. The output lists every container that is unhealthy, `created`, `restarting`, or has RestartCount > 0:

```
/silo|exited|unhealthy|1
/teslamateapi|running|none|1
/silo-db|exited|unhealthy|0
/tsbridge|running|none|1
TOTAL 92
```

- Unhealthy: **2, both Exited** (`silo`, `silo-db`, Silo dormant since 2026-10-22). **0 running-unhealthy.**
- `created`: 0. `restarting`: 0.
- image-drift.prom before the change: `selfhost_containers_unhealthy 2`, `selfhost_containers_created 0`.
- `selfhost-deploy.service` has no apply drop-in (`/etc/systemd/system/selfhost-deploy.service.d` does not exist), so it is still DRY-RUN.
- Host checkout was clean (`git status --porcelain` empty) at `2bb596ba`.

Conclusion: nothing genuine was holding the old rule red, so it was expected to clear (and it did).

## Task 1 driven evidence (LXC 100, scratch `/mnt/fast/rmv-scratch-261111`, since removed)

- `bash -n` passed on both scripts. `shellcheck` was clean on the new script, and `shellcheck -S warning` was clean on check-drift.sh.
- **(a) healthy:** rc=0, `series=90 restarting=0 running_unhealthy=0`. 90 restart_count series = 90 running+restarting containers. `promtool check metrics --lint=none --extended` parse rc=0. A negative control (an unterminated label value) gave parse rc=1, so the instrument can fail. Plain `promtool check metrics` (rc=3) reports exactly one lint finding: `selfhost_container_restart_count ... should not have "_count" suffix`. See Deviations.
- **(b) docker stub exits 1:** rc=1, message `UNKNOWN: 'docker ps -aq' exited non-zero — NOT writing ...`. sha256 before and after were both `10e52609…f9772c`, so the file is IDENTICAL.
- **(c) `docker ps -aq` stub prints nothing:** rc=1. sha256 before and after were both `10e52609…f9772c`, so the file is IDENTICAL.
- **check-drift (edited copy, report mode):** `unhealthy: 0`, matching STEP 0's running-unhealthy count of 0. `created: 0`.

## Task 2 evidence

- PyYAML structural asserts passed: groups are `[image-drift, deploy, container-restarts]`, uids are unique, and all 3 new rules have noDataState/execErrState `Alerting`. `name` is in the root `group_by`.
- The `{{ .State` count is 0. A per-occurrence regex over rules.yaml finds 0 `{{` that are not `$values`, `$labels` or the `"{{"` escape.
- Every pre-existing `expr:` is `max(...)` or `time() - max(...)`, so none carries a `name` label (DD-2 holds).
- qhc: `bash -n` and `shellcheck -S error` were clean. The restarting block was extracted and driven against the real host:
  `✅ No container in state restarting (inspected 92)`, EXIT_CODE=0. With `REMOTE_TIMEOUT=0.001` it printed `⚠️ UNKNOWN — the restarting-container query exceeded its 0.001s bound`, EXIT_CODE=1.
- Condition letters measured: W was the last letter in use; the new letters are X and Y. Block ordinal is unchanged at ten.
- **Notice header count, measured after writing:** `/usr/bin/grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]' scripts/quick-health-check.sh` = **17** (it was 16 before).

## Task 3 evidence (UTC)

- **S1 push:** origin/main was `d0035d75` (unmoved) and the push went `d0035d75..ccd8aeb6`. `git ls-remote origin refs/heads/main` = local HEAD = `ccd8aeb6b73aa8dd128a10119078022e99d54068`.
- **S2 host pull:** `git status --porcelain` was empty. After `git pull --ff-only`, host HEAD = `ccd8aeb6…`, which matches.
- **S3 install (20:15:15):** cp, daemon-reload, `enable --now` (the symlink was created), then `start` with rc=0. `is-active` = `active`. `Result=success ExecMainStatus=0`. `list-timers` showed the next run at 20:16:00 (44 s away). The journal shows `wrote …container-restarts.prom: series=90 restarting=0 running_unhealthy=0`. Parse rc=0, and the lint output was the same single `_count` line. The image-drift refresh had rc=0 and wrote `selfhost_containers_unhealthy 0` and `selfhost_containers_created 0`. That 0 equals STEP 0's running-unhealthy count.
- **S4 Grafana restart (RESTART_AT 2026-11-11T20:15:25Z):** before and after, the container was running with RestartCount 0. `/api/health` returned 200 after 5 s. The log shows `starting to provision alerting` and then `finished to provision alerting`, with no provisioning error (`level=error` count since the restart = 0).
- **S5a (20:15:38):** `count(selfhost_container_restart_count)` = 90, which equals running+restarting = 90. `selfhost_containers_restarting` = 0 and `selfhost_containers_running_unhealthy` = 0. The timestamp was 24 s old (< 360). The old rule's expression was 0.
- **S5b:** the Grafana API worked (HTTP 200; no 401 fallback was needed). Group `container-restarts` has 3 rules, all `health=ok state=inactive`. `Containers unhealthy or stuck created` was still `firing` at 20:15:38 and **inactive at 20:20:18**. Its resolution was sent at 20:19:20 (`Sending alerts to local notifier` for `selfhost-containers-unhealthy-or-created`), and `telegram-estate` logged a notify attempt at 20:19:20.042, 179 ms, with no error.
- **S5c:** the control before the restart was **913** `can't evaluate field` lines since the previous container start, the last at 20:14:20 (`Error in expanding template`, rule_uid=selfhost-containers-unhealthy-or-created). Since 20:15:25 the count is **0** `can't evaluate field`, 0 `Error in expanding template` and 0 `level=error`, over at least two 5-minute evaluations of that rule (20:19:20 and 20:24:20, plus 20:29:20 and 20:34:20 later).
- **S6 crash loop:** T0 = **20:16:00Z** (outside the drift timer's :00–:12 window). `docker run -d --restart=always --name alerttest-crashloop alpine:3.20 sh -c 'exit 1'`. Three seconds later it was `restarting rc=5`.
  - Prometheus: `selfhost_container_restarting{name="alerttest-crashloop"}` = 1 from 20:18:17. `increase(...[10m])` went 0 → 2.25 → 2.17 → **4.27 (20:22:19)**.
  - `Container restart loop` **fired 20:22:50 (T0 + 6 min 50 s)**, with labels `alertname="Container restart loop", name="alerttest-crashloop", severity=critical, grafana_folder=Estate`. Summary: `alerttest-crashloop restarted 4.207… times in 10 minutes.`
  - `Container restarting` was pending from about 20:19 and **fired 20:23:50 (T0 + 7 min 50 s)**, labelled `name="alerttest-crashloop"`. Summary: `alerttest-crashloop has been in state restarting for 5+ minutes.`
  - Telegram: `telegram-estate` `lastNotifyAttempt` = **20:23:20.072Z** (restart loop firing + 30 s group_wait), 170 ms, no error. Then **20:24:23.359Z** (Container restarting firing + 30 s), 176 ms, no `lastNotifyAttemptError`. The two separate attempts, each 30 s after its own rule fired, are consistent with per-`name` grouping (DD-2).
  - qhc from the workstation during the loop (20:16:20), restarting block:
    ```
    ❌ Containers in state restarting: 1
      alerttest-crashloop restarts=8
    ```
    Overall qhc rc=1. The run's only other red was pre-existing: `Music consumers audit: ❌ BROKEN … CONF-04 (D-22)` (the Lady Gaga ARTPOP artist entities). It is unrelated to this block.
- **S7 remove and resolve:** T1 = **20:24:55Z**. The container was `restarting rc=18` before `docker rm -f alerttest-crashloop` (rc=0). Its lines in container-restarts.prom went 2 → **0 by 20:26:05**. `Container restarting` resolved by **20:28:05**, and a notify attempt followed at **20:29:23.359Z** with no error. `Container restart loop` resolved by **20:33:07** (the 10m increase window draining), and a notify attempt followed at **20:34:53.349Z**, 158 ms, with no error. No alert with `name="alerttest-crashloop"` was active at 20:33:07. `docker ps -a --filter name=alerttest-crashloop -q` is empty. `alpine:3.20` had no other containers (`ancestor` filter empty) and was removed.
- **Final state (20:37):** the timer is active. 10 successful runs were logged in the last 20 minutes, with 0 UNKNOWN or failed. The file is 72 s old. grafana is running with rc=0. Jellyfin was never touched (running, StartedAt 19:23:58, rc=0). Host HEAD and local HEAD are both `ccd8aeb6`. Workstation `git status` shows only the pre-existing 07-UAT.md, `.planning/trips/` and `projects/`, plus this quick dir.

## Proof gate

| Step | Verdict |
|------|---------|
| S1 push confirmed by ls-remote | PROVEN |
| S2 host pull to pushed sha | PROVEN |
| S3 timer installed, run succeeded, file parse-valid | PROVEN |
| S4 Grafana reloaded without a provisioning error | PROVEN |
| Gauges present (S5a) | PROVEN |
| Old rule cleared (S5b) | PROVEN (it fired 20:15:38 and was inactive at 20:20:18; its value is 0) |
| No template errors (S5c) | PROVEN (913 before, 0 after) |
| Alert fired (S6) | PROVEN (restart loop at T0 + 6 min 50 s, restarting at T0 + 7 min 50 s, both `name=alerttest-crashloop`) |
| Telegram send recorded (S6) | PROVEN as a notify attempt to the Telegram API with no error (20:23:20, 20:24:23). Arrival on the phone is not observable from here; the operator can confirm the messages. |
| Alert resolved (S7) | PROVEN (both inactive by 20:33:07; notify attempts after T1 at 20:29:23 and 20:34:53 with no error. These are matched to the resolutions by timing; the receiver API is per-integration, not per-group.) |
| qhc red driven (S6) | PROVEN |
| alerttest-crashloop removed | PROVEN (`docker ps -a` filter empty) |

## Deviations from Plan

1. **[Rule 1 - Bug] Metric families written contiguously.** The plan said to write all HELP/TYPE lines first and then all series. Emitting `restarting{name}` and `restart_count{name}` per container in one loop would have interleaved two families, and the exposition format requires a family's samples to be grouped. Each family is now HELP, TYPE, then its samples, and the timestamp is still written last. Commit `752bfbf4`.
2. **promtool `_count` lint.** `promtool check metrics` exits 3 on one naming lint for `selfhost_container_restart_count`, a gauge with a `_count` suffix. I kept the plan's metric name because the rules, README and must_haves all name it. Parse validity is proven with `--lint=none --extended` (rc=0), with a negative control that fails (rc=1). The README notes this. If you want a lint-clean name, it means renaming the metric in the exporter, rules.yaml and README in one commit.
3. **Small wording additions beyond the plan, for consistency:** check-drift.sh's cadvisor note and inline tally comment now say the unhealthy tally is running-only. README § Image drift → "What will fire first" gains one paragraph saying Exited containers no longer count.

## Known Stubs

None.

## Self-Check: PASSED

- All 8 plan files exist in the repo at `ccd8aeb6`. The SUMMARY exists.
- Commits `752bfbf4` and `ccd8aeb6` are present locally and on origin/main.
