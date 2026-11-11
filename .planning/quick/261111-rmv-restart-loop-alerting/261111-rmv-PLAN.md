---
phase: quick-261111-rmv
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - scripts/export-container-restarts.sh
  - scripts/systemd/selfhost-container-restarts.service
  - scripts/systemd/selfhost-container-restarts.timer
  - scripts/check-drift.sh
  - stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml
  - stacks/selfhosted/monitoring/grafana/provisioning/alerting/notification-policies.yaml
  - scripts/quick-health-check.sh
  - stacks/selfhosted/monitoring/README.md
autonomous: true
requirements: [RMV-A, RMV-B, RMV-C, RMV-D, RMV-E]

must_haves:
  truths:
    - "A crash-looping container on LXC 100 produces a Firing Grafana alert labelled with that container's name within about 10 minutes, and Grafana records a Telegram notification attempt with no error"
    - "When the crash-looping container is removed, its alert resolves without anyone touching Grafana"
    - "If the restart exporter cannot read docker, its .prom file is left byte-identical (never rewritten with zeros) and the `Restart exporter is stale` rule fires"
    - "The standing `Containers unhealthy or stuck created` alert stops firing because Exited containers with a stale health status no longer count; it fires only for RUNNING containers that are unhealthy or containers stuck in `created`"
    - "Grafana evaluates every provisioned rule without a template error (no `can't evaluate field State` in its log)"
    - "scripts/quick-health-check.sh exits 1 when any running container is unhealthy or any container is in state `restarting`, and prints UNKNOWN (also exit 1) when it could not look"
  artifacts:
    - path: "scripts/export-container-restarts.sh"
      provides: "Oneshot node-exporter textfile writer for restart state"
      contains: "selfhost_container_restart_count"
    - path: "scripts/systemd/selfhost-container-restarts.timer"
      provides: "Every-2-minute schedule"
      contains: "OnCalendar=*:0/2"
    - path: "scripts/systemd/selfhost-container-restarts.service"
      provides: "Oneshot unit running the exporter"
      contains: "TimeoutStartSec=60"
    - path: "stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml"
      provides: "container-restarts rule group (restarting, restart loop, stale) + escaped template"
      contains: "name: container-restarts"
    - path: "stacks/selfhosted/monitoring/grafana/provisioning/alerting/notification-policies.yaml"
      provides: "group_by includes `name` so per-container instances notify separately"
      contains: "- name"
    - path: "scripts/quick-health-check.sh"
      provides: "fatal unhealthy branch + fatal restarting block"
      contains: "restarting"
    - path: "stacks/selfhosted/monitoring/README.md"
      provides: "Restart-loop detection section"
      contains: "Restart-loop detection"
  key_links:
    - from: "scripts/systemd/selfhost-container-restarts.service"
      to: "scripts/export-container-restarts.sh"
      via: "ExecStart absolute path under /mnt/fast/stacks"
      pattern: "ExecStart=/mnt/fast/stacks/scripts/export-container-restarts.sh"
    - from: "scripts/export-container-restarts.sh"
      to: "/mnt/fast/appdata/monitoring/node-exporter-textfile/container-restarts.prom"
      via: "tmp file whose name does not end in .prom, then mv -f"
      pattern: "container-restarts.prom"
    - from: "rules.yaml container-restarts group"
      to: "selfhost_container_restart_count / selfhost_container_restarting / selfhost_container_restarts_last_success_timestamp_seconds"
      via: "PromQL against datasource uid PBFA97CFB590B2093"
      pattern: "selfhost_container_restart"
    - from: "rules.yaml stale threshold 360"
      to: "selfhost-container-restarts.timer + .service TimeoutStartSec"
      via: "one decision across three files (cross-reference comment in all three)"
      pattern: "360"
---

<objective>
Make a crash-looping container on LXC 100 page Telegram within ~10 minutes, and prove it end to end.

Trigger: Jellyfin crash-looped ~21 h (2026-11-10 22:02 → 2026-11-11 19:12 UTC, RestartCount 1,229) and nothing alerted. Root causes, to be re-verified rather than trusted (citations go stale): check-drift.sh emits no restart signal and runs only hourly; its unhealthy tally counts Exited containers with a stale health status, so the only container rule has been Alerting since 2026-10-22 and cannot signal anything new; that rule's annotation errors on every evaluation; quick-health-check.sh never looks at restart state, and its unhealthy branch never sets EXIT_CODE.

Purpose: the estate's alert path must catch the failure that just went unseen for 21 hours.
Output: a 2-minute restart exporter and timer, three new Grafana rules, a cleared standing red, a fatal qhc check, docs, and a deployed, live-proven alert path.

Requirement IDs (this quick task's own): RMV-A measurement exporter, RMV-B Grafana rules/policy/template fix, RMV-C quick-health-check, RMV-D docs, RMV-E deploy and end-to-end proof.

DESIGN DECISIONS (made here; the executor implements them as stated):

DD-1 — what "unhealthy" means. Change check-drift.sh's tally to count RUNNING containers only, and do NOT re-point the existing rule. Why: (1) it is a one-condition change at the tally site; (2) all three readers then share one definition — qhc's `docker ps --filter health=unhealthy` is already running-only (no `-a`), check-drift becomes running-only, and the new exporter publishes the same running-only number; (3) the existing rule's no-data argument (the comment above its expr: "both series are written by the same atomic write, so partial absence means the write did not happen") stays true. Re-pointing its unhealthy term at the new exporter would make one sum span two writers and break that invariant. The rule's expression stays as it is, and it clears on the next check-drift run. The new exporter publishes `selfhost_containers_running_unhealthy` at 2-minute resolution for inspection; no rule reads it. The README says so, so nobody "fixes" the duplication by deleting one half.

DD-2 — notification grouping. The root policy groups by `[alertname, grafana_folder]`, so every per-container instance of one rule falls into ONE notification group. The result is one message listing all containers; a second container joining an already-firing group appears only after group_interval (5m), inside the same message; and one container's resolution is buried in the group. Fix: add `name` to the root `group_by`. Rules whose instances carry no `name` label group exactly as before, because a missing label groups as one empty value. Every existing rule uses `max(...)`; verify that with grep. This keeps the file's stated "one route, no routing tree" principle: no child route is added.

DD-3 — per-container signal shapes. The exporter emits `selfhost_container_restarting{name}` as 0/1 and `selfhost_container_restart_count{name}` for EVERY running or restarting container, not only the restarting ones. Both per-container queries therefore always return data on a healthy estate, so `noDataState: Alerting` cannot page on a quiet day. `selfhost_containers_restarting` (a count) is emitted too.

DD-4 — the timer period and the staleness threshold are ONE decision. Timer `OnCalendar=*:0/2` + `AccuracySec=5s`; service `TimeoutStartSec=60`; stale threshold 360 s = 125 s worst start gap + 60 s runtime cap + 120 s for one missed run + 15 s scrape ≈ 320 s, rounded up to 360. All three files carry the cross-reference, mirroring selfhost-image-drift.timer's ⚠️ block.

DD-5 — rule shapes. "Container restarting": instant `max by (name) (selfhost_container_restarting)` > 0 with `for: 5m`, evaluated every 1m. It is per-instance and resets if a sample shows the container running. That is correct for "restarting for ≥ 5 min", and flapping is covered by the next rule. "Container restart loop": `max by (name) (increase(selfhost_container_restart_count[10m]))` > 3 with no `for` (the 10m window is the debounce). It catches a container that runs more than 10 s between crashes — the Jellyfin shape, mostly `running` when sampled. `increase` treats the drop to 0 on a recreate as a counter reset, which is the wanted behaviour. "Restart exporter is stale": `time() - max(selfhost_container_restarts_last_success_timestamp_seconds)` > 360, no `for`. All three use noDataState Alerting and execErrState Alerting. Expected time to page for a Jellyfin-like loop: ≤ 2 min exporter + scrape 15 s + 10m-window crossing 3 (≈ 4–6 min) + 1 min evaluation + 30 s group_wait — about 10 minutes.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@./CONVENTIONS.md
@scripts/check-drift.sh
@scripts/systemd/selfhost-image-drift.service
@scripts/systemd/selfhost-image-drift.timer
@stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml
@stacks/selfhosted/monitoring/grafana/provisioning/alerting/notification-policies.yaml
@stacks/selfhosted/monitoring/README.md
@stacks/selfhosted/monitoring/node-exporter.yaml
@stacks/selfhosted/monitoring/grafana.yaml

Facts the planner measured on 2026-11-11. Re-verify them; line numbers are omitted on purpose, per CONVENTIONS, so locate each by symbol:
- check-drift.sh: the textfile dir constant is `DRIFT_PROM_DIR_DEFAULT="/mnt/fast/appdata/monitoring/node-exporter-textfile"`. The tally lines (`[[ "$health" == "unhealthy" ]] && UNHEALTHY_COUNT=...` and the `created` one) sit in the single inspect pass after `MEASURED=1`. The inspect format string is `FMT=`. The atomic-write idiom and `prom_escape()` are in section `# 5. --prom: the node-exporter textfile`. Section `# 3. Container state` prints the unhealthy pass/warn lines. Step 1 of the header paragraph "HOW THE PIN IS RESOLVED" says the unhealthy tally needs the whole set; correct that sentence. Its `📊 Summary` heading and `unhealthy:` label are a cross-file contract with qhc: DO NOT rename either.
- node-exporter mounts that dir `:ro` at `/var/lib/node_exporter/textfile_collector` and globs `*.prom`. Files on the host now: `deploy.prom`, `image-drift.prom`.
- Units installed on LXC 100: `/etc/systemd/system/selfhost-{deploy,image-drift}.{service,timer}`, installed by `cp` (README § Image drift detection, step G3). The deploy agent runs DRY-RUN with no apply drop-in; confirm with `systemctl cat selfhost-deploy.service`.
- Grafana is 13.3.1, container `grafana`. Alerting provisioning is a DIRECTORY bind mount: a `git pull` is visible inside, and a restart re-reads provisioning. The Grafana container has `curl`. The prometheus container has `promtool` but no wget. LXC 100 has curl, jq and python3 (no PyYAML). The workstation has python3 + PyYAML 6, shellcheck and yq.
- Grafana admin creds are the container env `GF_SECURITY_ADMIN_USER` / `GF_SECURITY_ADMIN_PASSWORD`. They may have been changed in the UI, so a 401 is possible; see the Task 3 fallback.
- rules.yaml has groups `image-drift` (interval 5m) and `deploy`, and the datasource uid literal is `PBFA97CFB590B2093`. Every rule is refId A (prometheus, instant) + refId C (`__expr__` threshold on A). The only literal docker template is in the `selfhost-containers-unhealthy-or-created` description: `--format '{{ .State.Status }} {{ .State.ExitCode }}'`.
- qhc: the unhealthy block is the `UNHEALTHY=$(ssh -n $SSH_OPTS root@172.16.1.159 ...)` assignment, and its `elif [ "$UNHEALTHY" -gt 0 ]` arm only prints. The RUNNING block above it carries the CR-03 two-part note (pipefail in the remote string + read the ssh rc with no local pipe); copy that shape. Notice-header census: 16 headers today (`/usr/bin/grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]' scripts/quick-health-check.sh`). The last condition letter in use is W (re-measure with `/usr/bin/grep -nE '^#[[:space:]]+[A-Z]\.[[:space:]]' scripts/quick-health-check.sh`).
- Hazards from project memory: a rejected push followed by a host pull deploys origin without your commit, so gate every host step on the push having landed. The host checkout can carry uncommitted edits, so check `git status --porcelain` on the host before pulling. LXC 100 `/tmp` is tmpfs, so put scratch under `/mnt/fast/`. Workstation `grep` is ugrep, so use `/usr/bin/grep`. Read container state with `docker inspect`, not `docker ps`.
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Restart exporter script + systemd units + check-drift running-only unhealthy (RMV-A)</name>
  <files>scripts/export-container-restarts.sh, scripts/systemd/selfhost-container-restarts.service, scripts/systemd/selfhost-container-restarts.timer, scripts/check-drift.sh</files>
  <behavior>
    - Healthy docker: writes container-restarts.prom containing selfhost_containers_restarting, selfhost_containers_running_unhealthy, one selfhost_container_restarting{name} 0/1 and one selfhost_container_restart_count{name} per running/restarting container, and selfhost_container_restarts_last_success_timestamp_seconds; exits 0 whatever the counts.
    - docker ps fails or returns nothing, or docker inspect fails twice: exits 1, writes nothing, and the existing .prom stays byte-identical (sha256 before == after).
    - An unparseable inspect line (empty state, or RestartCount not numeric): exits 1 and writes nothing.
    - promtool check metrics accepts the written file.
    - check-drift.sh on the real host reports `unhealthy:` equal to the count of RUNNING containers whose health is unhealthy (the Exited silo/silo-db no longer count).
  </behavior>
  <action>
STEP 0 — read-only pre-flight on LXC 100. Record the output in the SUMMARY: it decides whether the standing red can clear. Over ssh, list every container's name, State.Status, health status and RestartCount in one `docker ps -aq` + `docker inspect --format` pass, bounded with `timeout`. Record: containers whose health is unhealthy, split by state; containers in `created`; containers in `restarting`; the unhealthy/created lines of the current image-drift.prom; and whether selfhost-deploy.service has the apply drop-in. If any RUNNING container is unhealthy, or any container is in `created`, that is a genuine finding: the old rule will rightly stay red after this change. Record which containers, do NOT touch them, and in Task 3 the "old rule clears" proof becomes "the rule's value equals this measured genuine count".

STEP 1 — create scripts/export-container-restarts.sh (mode 0755, `#!/usr/bin/env bash`).

The header comment states:
- what it measures, and why, as a one-line citation of quick 261111-rmv (the Jellyfin 21 h crash loop); the history stays in the quick dir, per CONVENTIONS rule 12;
- that it runs ON LXC 100 only, and is read-only by contract apart from its one textfile;
- the exit codes: 0 = measurement written, whatever the counts (the gauge is the signal — the same argument as check-drift's --prom exit-code block); 1 = could-not-look, nothing written; 2 = usage;
- the fail-closed contract: never write 0 on a failed read; a stale file is what makes `Restart exporter is stale` fire;
- the 360 s ONE-DECISION note (DD-4), naming the timer, the service's TimeoutStartSec and rules.yaml.

Implementation:
- `set -uo pipefail`. No `-e`: check every failure explicitly.
- Constants: `RESTARTS_PROM_DIR="${RESTARTS_PROM_DIR:-/mnt/fast/appdata/monitoring/node-exporter-textfile}"` and `RESTARTS_PROM_FILE=container-restarts.prom`. Comment on the override: it exists only so the fail-closed branch can be driven against a scratch dir, and using it leaves the real file to go stale, i.e. redder (CONVENTIONS rule 4).
- If the dir does not exist or is not writable, it is could-not-look: exit 1.
- Enumerate with `timeout 30 docker ps -aq`. A non-zero rc → exit 1. Empty output → exit 1, with a message that an empty estate is a broken daemon, not "nothing wrong" (check-drift uses the same idea).
- Inspect all ids in one `timeout 60 docker inspect --format` call. Use a `|:|`-style separator and the fields `.Name`, `.State.Status`, `.RestartCount` and health (`{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}`). If the call exits non-zero, re-enumerate and retry ONCE: a container removed between ps and inspect during a deploy is the expected cause. If the retry also fails, exit 1 without writing.
- Parse each line and strip the leading `/` from the name. If the state is empty, or RestartCount does not match `^[0-9]+$`, exit 1 without writing.
- Tally the restarting count (state == restarting) and the running-unhealthy count (state == running AND health == unhealthy).
- For each container whose state is running or restarting, emit one `selfhost_container_restarting{name="..."}` (1 if restarting, else 0) and one `selfhost_container_restart_count{name="..."}` holding RestartCount (DD-3). Escape label values with a copy of check-drift's `prom_escape` (backslash and double-quote).
- Output order: `# HELP` and `# TYPE ... gauge` lines for all five metric names, then all series, then `selfhost_container_restarts_last_success_timestamp_seconds $(date +%s)` LAST.
- Write it to `$RESTARTS_PROM_DIR/.container-restarts.prom.tmp.$$`. The temp name must NOT end in .prom, because node-exporter globs *.prom. Then `chmod 0644` and `mv -f` into place.
- Print a short human summary to stdout for the journal: the counts and the names of any restarting containers.

STEP 2 — the two systemd units.

scripts/systemd/selfhost-container-restarts.service copies selfhost-image-drift.service's shape: the header comment, `[Unit]` with Description, Documentation, After=docker.service and Requires=docker.service, and `[Service] Type=oneshot` with `ExecStart=/mnt/fast/stacks/scripts/export-container-restarts.sh`. Add `TimeoutStartSec=60` with a comment that it is one term of the 360 s threshold (DD-4). The header says the unit IS installed by this quick task's Task 3 (not "NOT INSTALLED": this change deploys it) and points to the install commands in README § Restart-loop detection.

scripts/systemd/selfhost-container-restarts.timer copies selfhost-image-drift.timer's shape, with:
- `OnCalendar=*:0/2`;
- `AccuracySec=5s`, with a comment that systemd's default 1-minute accuracy would add up to a minute of jitter to a 2-minute period;
- `Persistent=true`;
- `[Install] WantedBy=timers.target`;
- the ⚠️ ONE DECISION block, spelling out 125 s + 60 s + 120 s + 15 s ≈ 320 s → 360 s, and "change any term and you MUST change 360 in rules.yaml in the same commit".

STEP 3 — scripts/check-drift.sh (DD-1). Change the unhealthy tally to count only when the state is `running` AND the health is `unhealthy`; the `created` tally stays on the whole set. In the same edit, update:
- step 1 of the header paragraph "HOW THE PIN IS RESOLVED": the unhealthy tally is now running-only, and `created` still needs `-a`;
- the section 3 pass/warn wording, to say "running container(s)";
- the `# HELP selfhost_containers_unhealthy` text, to "RUNNING containers reporting docker health status 'unhealthy'".

Add a short comment at the tally that says WHY: an Exited container keeps its last health status forever; that held the Grafana rule red from 2026-10-22, so it could not signal anything new (261111-rmv). Do NOT rename the `📊 Summary` heading or the `unhealthy:` summary label: they are a cross-file contract with qhc (CONVENTIONS rule 11). The metric name stays the same.

STEP 4 — drive it (CONVENTIONS rule 3: prove it can fail).
- Locally: run `bash -n` and `shellcheck` on the new script and on check-drift.sh.
- On LXC 100, BEFORE committing: copy the new script into a scratch dir under /mnt/fast (NOT /tmp, which is tmpfs), make a scratch prom dir under /mnt/fast, then run three cases:
  (a) Healthy run with RESTARTS_PROM_DIR=scratch → exit 0 and the file is present. `docker exec -i prometheus promtool check metrics < file` passes. The number of restart_count series equals the number of running+restarting containers.
  (b) Fail-closed: record the file's sha256, then run with PATH prefixed by a scratch stub dir whose `docker` exits 1 → exit 1, sha256 unchanged.
  (c) A stub whose `docker ps -aq` prints nothing → exit 1, sha256 unchanged.
- Run the edited check-drift.sh from a scratch copy in report mode (not --prom) and confirm its `unhealthy:` line equals STEP 0's running-unhealthy count.
- Remove the scratch dirs afterwards, using `rm -rf` only on the exact scratch paths you created.

Commit the four files by explicit path (never `git add -A` or `.` — the tree holds unrelated changes) with the message `feat(monitoring): add 2-minute container restart exporter; count unhealthy among running containers only`. The body names 261111-rmv and the last line is `Claude-Session: https://claude.ai/code/session_01U6L4aqFUkCSrsCfTUHx8AQ`. Do NOT push; Task 3 pushes.
  </action>
  <verify>
    <automated>cd /Users/damian/Development/damianflynn/selfhost-stacks && bash -n scripts/export-container-restarts.sh && bash -n scripts/check-drift.sh && shellcheck -S warning scripts/export-container-restarts.sh && /usr/bin/grep -c 'OnCalendar=\*:0/2' scripts/systemd/selfhost-container-restarts.timer && /usr/bin/grep -c 'TimeoutStartSec=60' scripts/systemd/selfhost-container-restarts.service && /usr/bin/grep -c 'ExecStart=/mnt/fast/stacks/scripts/export-container-restarts.sh' scripts/systemd/selfhost-container-restarts.service && git log -1 --format=%B | /usr/bin/grep -cF 'Claude-Session: https://claude.ai/code/session_01U6L4aqFUkCSrsCfTUHx8AQ'</automated>
  </verify>
  <done>Four files committed locally (not pushed). STEP 4's three driven cases are recorded with their exit codes and sha256 values: the healthy case wrote a promtool-valid file; both fail cases exited 1 with the file byte-identical. check-drift's report-mode `unhealthy:` equals the measured running-unhealthy count. The STEP 0 pre-flight is recorded.</done>
</task>

<task type="auto">
  <name>Task 2: Grafana rules + policy grouping + template fix, qhc fatal checks, README (RMV-B, RMV-C, RMV-D)</name>
  <files>stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml, stacks/selfhosted/monitoring/grafana/provisioning/alerting/notification-policies.yaml, scripts/quick-health-check.sh, stacks/selfhosted/monitoring/README.md</files>
  <action>
PART A — rules.yaml.

(1) Template fix. In the `selfhost-containers-unhealthy-or-created` description, Grafana's Go template engine is evaluating the literal docker `--format` string, which raises "can't evaluate field State in type template.Data" on every evaluation. Escape the opening braces so the text renders literally: replace each `{{` of the docker format with `{{ "{{" }}`. The rendered text must read `--format '{{ .State.Status }} {{ .State.ExitCode }}'` (the closing `}}` outside an action is literal and needs no escape). Add a one-line YAML comment above it explaining the escape. Then grep the whole file for any other `{{` not followed by ` $values`, ` $labels` or ` "{{"`; there must be none.

(2) Update that rule's summary/description to say "RUNNING container(s) unhealthy" (DD-1). Leave its expr, `for` and noDataState unchanged. Update the file-top comment block to name the new group and the 360 s ONE-DECISION across three files, in the style of the existing 7200/7500 paragraphs.

(3) Append a third group: `- orgId: 1`, `name: container-restarts`, `folder: Estate`, `interval: 1m`, with a group comment carrying DD-3/DD-5's reasoning in brief. It holds three rules. Each copies the existing rule shape exactly: refId A is the prometheus instant query on datasourceUid `PBFA97CFB590B2093` (relativeTimeRange 600/0, instant true, range false); refId C is the `__expr__` threshold on A with reducer last. Each has noDataState Alerting, execErrState Alerting, isPaused false, and labels severity critical and area estate.
- uid `selfhost-container-restarting`, title `Container restarting`, `for: 5m`, expr `max by (name) (selfhost_container_restarting)`, threshold gt 0. Summary: `{{ $labels.name }} has been in state restarting for 5+ minutes.` The description gives the inspect command, with any docker template braces escaped as in (1), and points to README § Restart-loop detection.
- uid `selfhost-container-restart-loop`, title `Container restart loop`, no `for` (comment: the 10m window is the debounce), expr `max by (name) (increase(selfhost_container_restart_count[10m]))`, threshold gt 3. Summary: `{{ $labels.name }} restarted {{ $values.A.Value }} times in 10 minutes.` The description says a container that runs more than 10 s between crashes is mostly `running` when sampled, which is why this rule exists beside the restarting one, and names the commands `docker logs --tail 100 <name>` and `docker inspect <name>`.
- uid `selfhost-container-restarts-stale`, title `Restart exporter is stale`, no `for`, expr `time() - max(selfhost_container_restarts_last_success_timestamp_seconds)`, threshold gt 360. The params comment says this number and the timer/service are ONE decision (DD-4). The description gives `systemctl list-timers selfhost-container-restarts.timer; journalctl -u selfhost-container-restarts.service -n 50`, and says that a stale file after a failed run is correct.

The per-container rules must NOT be wrapped in `or vector(0)`, because that would invent a series with no `name`.

PART B — notification-policies.yaml (DD-2). Add `- name` to the root `group_by` after `grafana_folder`. Rewrite the header's group_by paragraph to explain: per-container instances of one rule would otherwise collapse into one group/message; with `name` added, each container fires and resolves as its own notification; rules without a `name` label (verify every existing rule — `/usr/bin/grep -n 'expr:' rules.yaml`, all `max(...)` or `time() - max(...)`) group exactly as before; no second route is added, so the one-route principle holds. Leave repeat_interval at 12h; it is a separate decision, and a crash loop pages on firing, not on repeat.

PART C — scripts/quick-health-check.sh (RMV-C).

(1) In the unhealthy block's `elif [ "$UNHEALTHY" -gt 0 ]` arm, add `EXIT_CODE=1` and change the icon/wording to a fatal `❌ Unhealthy running containers: N`. Bound the listing ssh that follows it the same way (it already has `timeout $REMOTE_TIMEOUT`).

(2) Immediately after the unhealthy block, add a restarting block in the same three-branch CR-03 shape. The remote string is: `set -o pipefail;` then enumerate with `ids=$(timeout $REMOTE_TIMEOUT docker ps -aq) || exit $?`; then `[ -n "$ids" ] || exit 5`; then `timeout $REMOTE_TIMEOUT docker inspect --format '{{.Name}} {{.State.Status}} {{.RestartCount}}' $ids | awk` printing `RESTARTING <name> restarts=<n>` for each container whose state is restarting, and at END `INSPECTED <NR>`. Escape `$` for awk fields and `$ids` inside the local double-quoted string so they expand REMOTELY; confirm by running it. Capture with `ssh -n $SSH_OPTS root@172.16.1.159 "..."` into a variable, then read `$?` on the NEXT line with no local pipe (the CR-03 note explains why). Branches:
- rc 124 → `⚠️  UNKNOWN — the restarting-container query exceeded its bound ... This is NOT 'no restarting containers'.` EXIT_CODE=1.
- rc ≠ 0, OR no `INSPECTED <n>` line with n > 0 → `⚠️  UNKNOWN — could not look ...`. EXIT_CODE=1. This keeps "could not look" distinct from "nothing wrong" (CONVENTIONS rule 1); exit 5 (empty `docker ps -aq`) lands here.
- Any RESTARTING lines → `❌ Containers in state restarting: N`, list them, EXIT_CODE=1.
- Otherwise `✅ No container in state restarting (inspected N)`.
Add a comment above the block giving the reason in brief: Jellyfin crash-looped 21 h unseen, 261111-rmv; `docker ps -aq` because `docker ps` hides non-running states; inspect over ps.

(3) Add ONE new notice in the series: header line `# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — ...` (the real word, unbracketed; it IS an occurrence), placed after the last existing notice and before the `KNOWN LIMIT` notice. Name the new condition letters by measuring the last letter in use first (expected X and Y): X = a RUNNING container is unhealthy (previously printed only); Y = any container is in state restarting, or the restarting query could not look. State that the block ordinal does not change if the unhealthy/running checks are outside the numbered blocks (verify this by reading the BLOCK-ordinal sentences of the neighbouring notices; if the convention counts this as a new fatal block, say so and give the new ordinal). Keep it brief, per rule 12. Measure the header count AFTER writing it, with `/usr/bin/grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]' scripts/quick-health-check.sh` (expected 17), and record the number in the SUMMARY, NOT in band (rule 8.2). Do not add, rename or renumber any `📊 N. Summary` heading (rule 11). Also edit the KNOWN LIMIT notice minimally: add one sentence that restart loops are now also covered unattended by the Grafana `container-restarts` group (README § Restart-loop detection). Do not otherwise rewrite it.

PART D — stacks/selfhosted/monitoring/README.md (RMV-D).
- Add `## Restart-loop detection` between § Image drift detection and § Deploy agent. Cover: the question it answers; the trigger (Jellyfin, 21 h, RestartCount 1,229, nothing alerted); the instrument (`scripts/export-container-restarts.sh`, the units, every 2 min); a metrics table with all five metrics; the three rule titles and why there are two per-container rules (DD-5); the 360 s ONE-DECISION; the grouping change (DD-2); the DD-1 note that `selfhost_containers_running_unhealthy` duplicates check-drift's `selfhost_containers_unhealthy` at finer resolution ON PURPOSE, with no rule on it; and the install steps written as the exact commands Task 3 runs (cp units, daemon-reload, enable --now, one immediate start, `docker restart grafana`), marked as executed by 261111-rmv rather than "NOT EXECUTED".
- In § Image drift detection → The metrics, change the `selfhost_containers_unhealthy` row to "RUNNING containers with docker health status `unhealthy` (Exited containers keep a stale status and are excluded since 261111-rmv)".
- In § Alerting, correct the `rules.yaml` table row so it names all three groups (image-drift, deploy, container-restarts) instead of "the three rules below", and add the `name` grouping to the notification-policies row.

VALIDATE LOCALLY BEFORE COMMITTING. A bad provisioning file crash-loops Grafana, which takes its whole HTTP server down:
- Parse both YAML files with python3 + PyYAML.
- Assert the group names are exactly `image-drift`, `deploy`, `container-restarts`.
- Assert every rule uid is unique.
- Assert every new rule has noDataState and execErrState `Alerting`.
- Run `bash -n` and `shellcheck -S error` on qhc.
- Drive the new qhc restarting block once in isolation against the real host (extract the block, or run the whole script and read the block's lines); it must print the ✅ line with inspected N > 0.

Commit the four files by explicit path: `feat(monitoring): page on container restart loops; fix unhealthy-rule template; qhc restarting check`, body naming 261111-rmv, ending with the Claude-Session line. Do not push.
  </action>
  <verify>
    <automated>cd /Users/damian/Development/damianflynn/selfhost-stacks && python3 -c "import yaml,collections;d=yaml.safe_load(open('stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml'));g=[x['name'] for x in d['groups']];assert g==['image-drift','deploy','container-restarts'],g;u=[r['uid'] for x in d['groups'] for r in x['rules']];assert len(u)==len(set(u));n=[r for x in d['groups'] if x['name']=='container-restarts' for r in x['rules']];assert len(n)==3 and all(r['noDataState']=='Alerting' and r['execErrState']=='Alerting' for r in n);p=yaml.safe_load(open('stacks/selfhosted/monitoring/grafana/provisioning/alerting/notification-policies.yaml'));assert 'name' in p['policies'][0]['group_by'];print('ok')" && /usr/bin/grep -c '{{ \.State' stacks/selfhosted/monitoring/grafana/provisioning/alerting/rules.yaml | /usr/bin/grep -qx 0 && bash -n scripts/quick-health-check.sh && /usr/bin/grep -c '^## Restart-loop detection' stacks/selfhosted/monitoring/README.md && /usr/bin/grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]' scripts/quick-health-check.sh</automated>
  </verify>
  <done>The YAML parses and the structural assertions pass. No unescaped docker template remains (the `{{ .State` count is 0; the escaped form renders it). qhc parses, the new block printed a ✅ with inspected N > 0 against the real host, the unhealthy arm sets EXIT_CODE=1, the notice header count is measured after writing (expected 17) and recorded in the SUMMARY. The README section exists. The four files are committed locally, not pushed.</done>
</task>

<task type="auto">
  <name>Task 3: Deploy to LXC 100 and prove the alert path end to end (RMV-E)</name>
  <files>(no repo files; host state on LXC 100 and evidence recorded in .planning/quick/261111-rmv-restart-loop-alerting/261111-rmv-SUMMARY.md)</files>
  <action>
The operator authorised this deployment and the test container in this session. Hard rule: never touch jellyfin or any production container. The only containers this task may create or remove are `alerttest-crashloop` and `grafana`, and grafana is restarted, never removed. Each step's evidence (command + output) goes into the SUMMARY. If a step fails, STOP at that step, roll back as below where stated, and have the SUMMARY name exactly which step failed. Never claim an unproven step.

Credentials (CONVENTIONS rule 7): every Grafana API call runs as `docker exec -i grafana sh -c '...'`. Inside, the creds are fed to curl as a config on stdin: printf (a shell builtin) of `user = "<user>:<pass>"` built from `$GF_SECURITY_ADMIN_USER` / `$GF_SECURITY_ADMIN_PASSWORD`, piped to `curl -sS -K - http://localhost:3000/...`. The creds never appear in any argv. If that returns 401 (the password was changed in the UI), do NOT reset it: record Grafana-API proof as COULD NOT LOOK and use the fallbacks named in each step. Prometheus is queried from inside the grafana container with `curl -sS 'http://prometheus:9090/api/v1/query' --data-urlencode 'query=...'`. If the name does not resolve, use the prometheus container's IP from `docker inspect`.

S1 — push. `git status -sb`, then `git fetch`. If origin/main has moved, `git rebase origin/main` (stop on conflict). `git push origin main`. Then assert that `git ls-remote origin refs/heads/main` equals local `git rev-parse HEAD`. If they differ, STOP: no host step runs on an unconfirmed push (memory: a rejected push followed by a host pull deploys origin without your commit).

S2 — pull on the host. `ssh root@172.16.1.159 'cd /mnt/fast/stacks && git status --porcelain'`. If that lists any of this plan's eight files, STOP and report; other dirty files are pre-existing, so record them and leave them alone. Then `git pull --ff-only`, and assert that the host's `git rev-parse HEAD` equals the pushed sha.

S3 — install the timer exactly as G3/D1 do: `cp /mnt/fast/stacks/scripts/systemd/selfhost-container-restarts.{service,timer} /etc/systemd/system/`, `systemctl daemon-reload`, `systemctl enable --now selfhost-container-restarts.timer`, `systemctl start selfhost-container-restarts.service`. Then:
- `systemctl is-active selfhost-container-restarts.timer` is `active`;
- `systemctl show -p Result selfhost-container-restarts.service` is `success`;
- `systemctl list-timers selfhost-container-restarts.timer` shows the next run within 2 min;
- `container-restarts.prom` exists in the textfile dir, and `promtool check metrics` passes on it (stdin into the prometheus container).
Also refresh the old gauge: `systemctl start selfhost-image-drift.service`, then show image-drift.prom's `selfhost_containers_unhealthy` line equals Task 1 STEP 0's running-unhealthy count.

S4 — reload Grafana. Provisioning is a directory bind mount, and the pulled files are already visible inside, so `docker restart grafana` re-reads it (`compose up -d` would NOT recreate a container whose config did not change). Wait up to 90 s. Assert `docker inspect grafana --format '{{.State.Status}} {{.RestartCount}}'` is running with an unchanged RestartCount, and that `docker logs --since <restart time> grafana 2>&1` holds no provisioning error. ROLLBACK if Grafana crash-loops or the logs show a provisioning failure: `git revert --no-edit` the Task 2 commit, push (S1 gate), pull on the host (S2), `docker restart grafana`, confirm it is healthy, then STOP and report.

S5 — prove the steady state:
(a) Prometheus has the new series: `count(selfhost_container_restart_count)` > 0 and equals the number of running+restarting containers; `selfhost_containers_restarting`, `selfhost_containers_running_unhealthy` and `selfhost_container_restarts_last_success_timestamp_seconds` are present; `time() - selfhost_container_restarts_last_success_timestamp_seconds` < 360.
(b) The rules are loaded and the old rule has cleared. `GET /api/prometheus/grafana/api/v1/rules` lists the group `container-restarts` with three rules, all health `ok` and a non-firing state. Within ≤ 10 min of S3's drift run (interval 5m), `Containers unhealthy or stuck created` is no longer `firing`. If STEP 0 recorded genuine running-unhealthy or created containers, show instead that its value equals that count, and say so plainly. Fallback if the API is not reachable (401): the Prometheus queries prove the gauges, and the Grafana logs serve as the evaluation evidence.
(c) No template errors: after at least two evaluation cycles following the restart, `docker logs --since <restart time> grafana 2>&1 | /usr/bin/grep -c "can't evaluate field"` is 0. Do this on the host (LXC 100's grep is GNU). Record the count from before the restart too, as the control, to show the instrument can see the error (rule 8.3).

S6 — controlled crash loop. Avoid the drift timer's :00–:12 window if practical: during that window check-drift could briefly see the unlabelled test container running. That is harmless but noisy; record it if it happens. Record T0 (UTC), then on LXC 100 run `docker run -d --restart=always --name alerttest-crashloop alpine:3.20 sh -c 'exit 1'`. Poll every 60 s for up to 15 min:
- Prometheus: `selfhost_container_restarting{name="alerttest-crashloop"}` and `increase(selfhost_container_restart_count{name="alerttest-crashloop"}[10m])`.
- Grafana: `GET /api/alertmanager/grafana/api/v2/alerts` filtered on `name="alerttest-crashloop"`, until at least one of `Container restart loop` / `Container restarting` is active, with a `name` label equal to alerttest-crashloop. Record the time each one fires, relative to T0.
- Then prove a send. `GET /api/alertmanager/grafana/config/api/v1/receivers` → for `telegram-estate`, the integration's `lastNotifyAttempt` is later than T0 and `lastNotifyAttemptError` is empty. Fallback if the API is not reachable: the Grafana logs since T0 grepped for notify/telegram lines. If neither proves a send, the SUMMARY states "Telegram delivery NOT PROVEN" and asks the operator to confirm the message on the phone.
- While the loop is live, run `bash scripts/quick-health-check.sh` from the workstation and capture the restarting block's lines. They must show `❌ Containers in state restarting` naming alerttest-crashloop. If the container happened to be sampled `running`, re-run just that block. This is the driven red for rule 3. The overall rc will also reflect pre-existing reds; record it, don't interpret it as this block.

S7 — remove and resolve. `docker rm -f alerttest-crashloop` and record T1. Wait for the next exporter run, then show the series for that name is gone from the .prom file. Poll for up to 20 min. The `increase()` window holds for up to ~10 min after removal, and Grafana resolves missing series after two evaluations. Wait until no alert with `name="alerttest-crashloop"` is active in `/api/alertmanager/grafana/api/v2/alerts`, and the receivers' `lastNotifyAttempt` has advanced past T1 (the resolve message). Record the resolution times. Confirm `docker ps -a --filter name=alerttest-crashloop -q` is empty. Removing the pulled alpine:3.20 image is optional (`docker image rm alpine:3.20` only if no other container uses it; check with `docker ps -a --filter ancestor=alpine:3.20 -q` first).

Final: `git status --short` on the workstation shows the plan's files clean, and the unrelated pre-existing changes (07-UAT.md, .planning/trips/, projects/) are still unstaged and untouched.
  </action>
  <verify>
    <automated>ssh -o BatchMode=yes root@172.16.1.159 'systemctl is-active selfhost-container-restarts.timer && test -s /mnt/fast/appdata/monitoring/node-exporter-textfile/container-restarts.prom && grep -c "^selfhost_container_restart_count{" /mnt/fast/appdata/monitoring/node-exporter-textfile/container-restarts.prom && docker inspect grafana --format "{{.State.Status}}" && test -z "$(docker ps -aq --filter name=alerttest-crashloop)" && cd /mnt/fast/stacks && git rev-parse HEAD' && git -C /Users/damian/Development/damianflynn/selfhost-stacks rev-parse HEAD</automated>
  </verify>
  <done>Host HEAD equals the pushed HEAD; the timer is active and its file is fresh and promtool-valid; Grafana is running with the container-restarts group loaded and health ok; the old rule is not firing (or equals the recorded genuine count); the template-error count since the restart is 0, with the pre-restart control recorded; the test loop fired a per-container alert labelled name=alerttest-crashloop within about 10 min of T0, and the telegram-estate lastNotifyAttempt advanced with no error; qhc showed the restarting red during the loop; the test container is gone and its alert resolved. Any step that could not be proven is named as such in the SUMMARY.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| docker daemon → exporter | container names (operator-controlled, but arbitrary strings) become Prometheus label values |
| workstation → LXC 100 (ssh as root) | deployment and the proof run as root on the Docker host |
| Grafana API (admin basic auth) | admin credentials are used for read-only API calls during the proof |
| public git repo | everything committed is world-readable |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-rmv-01 | Tampering | export-container-restarts.sh label output | mitigate | escape `\` and `"` in names via a prom_escape copy; promtool check metrics on the written file (Task 1 STEP 4, Task 3 S3) |
| T-rmv-02 | Denial of Service | node-exporter textfile parse | mitigate | the temp file name does not end in .prom, then an atomic `mv -f`, so a half-written file is never globbed |
| T-rmv-03 | Repudiation / false green | exporter on a docker failure | mitigate | no write on any could-not-look path; a stale timestamp fires `Restart exporter is stale`; both failure branches driven with sha256 before == after |
| T-rmv-04 | Information Disclosure | Grafana admin creds during the proof | mitigate | creds stay inside the grafana container's env and reach curl via `-K -` on stdin; never argv, never echoed into the SUMMARY (CONVENTIONS rule 7) |
| T-rmv-05 | Denial of Service | Grafana provisioning | mitigate | PyYAML structural validation before commit; post-restart RestartCount and log check; scripted git-revert rollback in S4 |
| T-rmv-06 | Tampering | production containers during the test | mitigate | only `alerttest-crashloop` is created or removed (by exact name); grafana is restarted, never removed; jellyfin is never touched |
| T-rmv-07 | Tampering | host checkout / deploy ordering | mitigate | push confirmed with ls-remote before any host step; host `git status --porcelain` checked before `pull --ff-only` |
| T-rmv-08 | Information Disclosure | public repo | accept | no secret is introduced; the Telegram token stays as `$__env{}` in the gitignored .env, unchanged |
| T-rmv-SC | Tampering | image pull alpine:3.20 | accept | the official Docker Library image, used only as the throwaway test container and removed afterwards; no npm/pip/cargo installs in this plan |
</threat_model>

<verification>
- Task 1: the exporter's healthy and fail-closed behaviour driven on the real host, with sha256 evidence; check-drift's unhealthy is running-only.
- Task 2: YAML structure asserted; no unescaped docker template; the qhc restarting block run against the real host; notice header count measured after writing.
- Task 3: the live chain — gauges in Prometheus, rules loaded and healthy, old red cleared (or equal to a genuine count), zero template errors, test crash loop → per-container Firing → Telegram notify attempt recorded → removal → resolved.
</verification>

<success_criteria>
- A crash loop on LXC 100 produces a per-container Grafana alert and a recorded Telegram notification attempt within about 10 minutes of the loop starting, proven with alerttest-crashloop.
- The exporter cannot publish zeros on a failed read, and its staleness has its own rule.
- `Containers unhealthy or stuck created` no longer fires for Exited containers, and its annotation renders without error.
- quick-health-check.sh fails on a running-unhealthy or restarting container and reports UNKNOWN when it cannot look.
- The README and the unit headers document the exporter, the rules, the 360 s decision and the grouping change.
- The SUMMARY names any step that could not be proven.
</success_criteria>

<output>
Create `.planning/quick/261111-rmv-restart-loop-alerting/261111-rmv-SUMMARY.md` when done. Include: the STEP 0 pre-flight, the driven-test evidence, the notice header count measured after the edit, the S1–S7 evidence with UTC times, and an explicit PROVEN / NOT PROVEN line for each of: gauges present, old rule cleared, no template errors, alert fired, Telegram send recorded, alert resolved, qhc red driven.
</output>
