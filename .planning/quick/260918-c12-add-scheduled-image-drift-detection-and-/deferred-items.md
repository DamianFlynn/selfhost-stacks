# Deferred items — quick task 260918-c12

Out-of-scope discoveries made while executing this task. **None of these were fixed here**; each is
outside the boundary of "add scheduled image-drift detection and alerting", and fixing an unrelated
condition inside this change would make the diff unreviewable.

## 1. `docker ps` reports cadvisor running; `docker inspect` says it exited 16 days ago

Measured 2026-09-18T07:57Z on LXC 100, same container id `fe8526f66630`:

```
docker ps  -a --filter name=cadvisor --format '{{.State}} {{.Status}}'
  -> running   Up 2 weeks (health: starting)

docker inspect fe8526f66630 --format '{{.State.Status}} {{.State.ExitCode}} {{.State.FinishedAt}} {{.State.Health.Status}}'
  -> exited 137 2026-09-02T07:17:44Z unhealthy
```

`RestartPolicy=unless-stopped`, exit code 137 (SIGKILL — OOM is the usual cause on this box, and
`/mnt/fast/appdata` not being a mountpoint plus the known memory-pressure signature both live in
this estate's history).

**Why it matters beyond cadvisor:** this is a *second* `docker ps` blind spot, distinct from the
documented `created`-state one. A container dead for sixteen days presents as `Up 2 weeks` to the
tool most people reach for first. `scripts/check-drift.sh` is unaffected — it reads `docker inspect`
throughout, which is why it counted cadvisor once under `unhealthy` and excluded it from the drift
classification — but any *other* check in this repo that keys on `docker ps` state inherits the
fault.

**Not fixed here** because restarting cadvisor is an estate change and this task's hard boundary is
that nothing may touch the estate. Worth its own quick task: restart it, find why it was OOM-killed,
and audit the repo for checks that trust `docker ps` state.

## 2. Three untracked files have sat in the live checkout since March 2026

`git -C /mnt/fast/stacks status --porcelain` is not empty:

```
?? stacks/selfhosted/karakeep/.env.pre-pocket                 (5 Mar 2026)
?? stacks/selfhosted/monitoring/prometheus.yaml.bak           (9 Mar 2026, owner nobody)
?? stacks/selfhosted/wrappers/monitoring.app.yaml.disabled    (9 Mar 2026)
```

All three predate this task by six months and none was created by it — recorded so that a future
reader running the T-c12-02 "host checkout must be clean" assertion knows what they are looking at
and does not attribute them to this change. `.env.pre-pocket` is a credential backup sitting beside
a stack in a directory that is otherwise git-managed; worth deciding whether it should be there at
all.

## 3. The brief's drift fixture of 12 was measured by a superseded method

Not a defect to fix, but it is a correction and it belongs on the record. See the MEASURED FIXTURE
block in `scripts/check-drift.sh` for the evidence: `n8n` and `socket-proxy` are genuine drift that
a repo-wide image-reference search hides, because both of their running tags also appear under
`stacks/mpe/`. The corrected count is 14.
