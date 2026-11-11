---
phase: quick-261111-swk
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - stacks/selfhosted/openwebui/compose.yaml
  - stacks/selfhosted/openwebui/README.md
autonomous: true
requirements: [SWK-01, SWK-02, SWK-03]
must_haves:
  truths:
    - "ai-ollama's startup log carries `inference compute` with `library=Vulkan` and the Radeon 890M, and no `dropping integrated GPU` line"
    - "`ollama run --verbose qwen2.5:3b` generates well above 1 tok/s (expect ~18), and `ollama ps` shows 100% GPU"
    - "Open WebUI still reaches Ollama at its configured base URL (`/api/tags` returns 200 and the model list)"
    - "atlantis `amdgpu_hmm_invalidate_gfx` dmesg count and /proc/sys/kernel/tainted are unchanged by the deploy"
    - "Nothing in the openwebui compose comment or README claims ROCm; GPU checks shown are ones that work under Vulkan"
  artifacts:
    - path: "stacks/selfhosted/openwebui/compose.yaml"
      provides: "ai-ollama with OLLAMA_IGPU_ENABLE=1 and a dated comment explaining why"
      contains: "OLLAMA_IGPU_ENABLE=1"
    - path: "stacks/selfhosted/openwebui/README.md"
      provides: "Vulkan-accurate GPU prerequisites and checks"
      contains: "inference compute"
  key_links:
    - from: "stacks/selfhosted/openwebui/compose.yaml (ai-ollama environment)"
      to: "Ollama GPU discovery"
      via: "OLLAMA_IGPU_ENABLE=1 + OLLAMA_VULKAN=true + /dev/dri + group_add 44/110"
      pattern: "OLLAMA_IGPU_ENABLE=1"
    - from: "openwebui service OLLAMA_BASE_URLS"
      to: "http://ai-ollama:11434"
      via: "openwebui docker network"
      pattern: "OLLAMA_BASE_URLS=http://ai-ollama:11434"
---

<objective>
Move Ollama (compose service key `ai-ollama`, container_name `ai-ollama`) off the CPU and onto the
Radeon 890M via Vulkan by adding `OLLAMA_IGPU_ENABLE=1`. Correct the stale ROCm wording, deploy only
that service, and prove the change on the live host.

Purpose: on CPU, ai-ollama runs at 0.26 tok/s while using ~770% CPU. The iGPU was gated off partly to
avoid amdgpu userptr exposure, and kernel 7.0.14-28 removes that reason because it carries the
amdgpu_hmm_invalidate_gfx fix (#7905). A throwaway container with this variable measured 18.4 tok/s,
with 37/37 layers offloaded and 0 oops lines.

Output: one pushed commit (compose + README) and the redeployed ai-ollama. The SUMMARY records each
proof step as PROVEN or NOT PROVEN.

Requirement IDs, all local to this quick task:
- SWK-01: the env var, its dated comment, and the ROCm wording fix in compose
- SWK-02: README ROCm to Vulkan correction
- SWK-03: deploy and prove, with a rollback path
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@./CONVENTIONS.md
@stacks/selfhosted/openwebui/compose.yaml
@stacks/selfhosted/openwebui/README.md

Facts the planner measured on 2026-11-11. Do not re-derive them:
- In compose.yaml the service key is `ai-ollama` (around line 66). Its comment block starts around
  line 61 and reads `# Ollama AI model server with AMD GPU (ROCm) acceleration`. The env list runs
  from about line 72 to 81, alphabetical, in the `- KEY=value` style, ending at
  `OLLAMA_VULKAN=true`. It also holds `OLLAMA_NUM_THREAD=0`. Leave that line alone: the task does
  not change it, and the comment only explains that the env var is inert.
- The open-webui service sets `OLLAMA_BASE_URLS=http://ai-ollama:11434` (around line 453) and
  `RAG_OLLAMA_BASE_URL=http://ai-ollama:11434`. Find its container name with
  `docker ps --format '{{.Names}}' | grep -i webui` on LXC 100. Do not guess the name.
- The repo image is now `ollama/ollama:0.40.16` after Renovate #679 (`958abe0a`). The live container
  and the throwaway test ran 0.40.15. `pull_policy: always` means the recreate will also apply
  0.40.16. That is expected. Record the running image in the SUMMARY, and judge the proof against
  the 0.40.15 measurements.
- README lines that mention ROCm (line numbers are approximate; re-grep before editing):
  - 3 and 10: generic "AMD GPU acceleration". These are fine; at most add "(Vulkan)".
  - 53: "AMD Radeon with ROCm support".
  - 67: "AMD GPU drivers and ROCm support".
  - 292: `watch -n 1 'rocm-smi'`.
  - 328-334: the "AMD GPU Not Detected" block, with `rocm-smi` and `ls -la /dev/kfd /dev/dri`.
  - 378-381: "GPU Optimization", with `HSA_OVERRIDE_GFX_VERSION` and `rocm-smi`. Under Vulkan these
    are ROCm-only knobs.
- `infra/variables.tf` mentions amdgpu_hmm_invalidate_gfx only inside the `mpe_memory_mb` description
  (around lines 277-281). It describes memory pressure arming the bug and does not mention
  ollama/GPU. **Decision: do not touch infra/.** The compose comment is enough. Any Terraform-file
  edit, even a comment-only one, falls outside this task's files.
- Restart exporter: scripts/export-container-restarts.sh writes
  `/mnt/fast/appdata/monitoring/node-exporter-textfile/container-restarts.prom` on LXC 100, driven
  by `selfhost-container-restarts.timer` (OnCalendar=*:0/2).
- Throwaway-test numbers to cite: 18.4 tok/s generation, 252 tok/s prompt, 37/37 layers offloaded,
  `description="AMD Radeon 890M Graphics (RADV GFX1150)" total="16.5 GiB"`. CPU baseline: 0.26 tok/s
  at ~770% CPU with n_threads=12. llama.cpp reads 24 host threads inside the 8-core LXC.
  `OLLAMA_NUM_THREAD` is ignored by 0.40.x (tested at 8 and 6, both still 12); only the per-model or
  per-request `num_thread` option works.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add OLLAMA_IGPU_ENABLE=1, fix ROCm wording, commit and push</name>
  <files>stacks/selfhosted/openwebui/compose.yaml, stacks/selfhosted/openwebui/README.md</files>
  <action>
compose.yaml, ai-ollama service only:

(a) Insert `- OLLAMA_IGPU_ENABLE=1` into the environment list at its alphabetical position, between
`OLLAMA_HOST` and `OLLAMA_LOAD_TIMOUT`. Use the same indentation and `- KEY=value` style. Directly
above it, add a short dated comment (3-5 lines, `# 2026-11-11 (quick 261111-swk):`) that says:
- Ollama 0.40.x drops the integrated GPU unless this is set. Its log says
  `dropping integrated GPU; to enable, set OLLAMA_IGPU_ENABLE=1`.
- The iGPU stayed off partly to avoid amdgpu userptr exposure. Kernel 7.0.14-28 carries the
  amdgpu_hmm_invalidate_gfx fix (#7905), so that reason is gone.
- Measured: 0.26 tok/s at ~770% CPU on CPU, against 18.4 tok/s with 37/37 layers on Vulkan
  (qwen2.5:3b).
- `OLLAMA_NUM_THREAD` in env is ignored by 0.40.x (llama.cpp still spawns 12 threads). Only a
  per-model or per-request `num_thread` option works, so do not "fix" CPU load with that env var.

Keep the comment to what a future reader needs; the narrative goes in the SUMMARY (CONVENTIONS rule
12).

(b) Change the line `# Ollama AI model server with AMD GPU (ROCm) acceleration` to
`# Ollama AI model server with AMD iGPU (Vulkan) acceleration`. Add one short line noting why ROCm
is not viable: /dev/kfd is not passed into LXC 100, and the image is the non-`-rocm` build.

(c) Change NOTHING else. That includes the image tag, OLLAMA_VULKAN, OLLAMA_MLOCK, OLLAMA_NUM_GPU,
OLLAMA_NUM_THREAD, devices, group_add, ports, labels, healthcheck and every other service.

README.md:
- Line ~53: reword to "AMD Radeon iGPU via Vulkan (tested on Radeon 890M / gfx1150; Ollama needs
  `OLLAMA_IGPU_ENABLE=1`)".
- Line ~67: reword to "/dev/dri passed into the container (render 110 / video 44 groups). ROCm and
  /dev/kfd are NOT used".
- Line ~292: replace `rocm-smi` with the checks that work under Vulkan:
  - `docker logs ai-ollama 2>&1 | grep "inference compute"`, which should show `library=Vulkan`.
  - `docker exec ai-ollama ollama ps`, where the PROCESSOR column should read `100% GPU`.
- "AMD GPU Not Detected" block: replace `rocm-smi` and `/dev/kfd` with:
  - `ls -la /dev/dri`
  - the `inference compute` grep above
  - `docker logs ai-ollama 2>&1 | grep "dropping integrated GPU"`, which means
    `OLLAMA_IGPU_ENABLE=1` is missing.
- "GPU Optimization" block: drop `HSA_OVERRIDE_GFX_VERSION` and the `rocm-smi` VRAM line, because
  they are ROCm-only. Replace them with a bullet that `ollama ps` shows GPU/CPU split and size.
  Keep the `OLLAMA_NUM_GPU=1` bullet.
- Leave lines 3 and 10 alone, or append "(Vulkan)" at most.
- After editing, run `/usr/bin/grep -n -i -E 'rocm|kfd|HSA_OVERRIDE'` on the README. Any surviving
  hit must be an explicit "not used" statement.

Validate the compose file with
`docker compose -f stacks/selfhosted/openwebui/compose.yaml config -q`. If docker is absent on the
workstation, or absolute env_file/secret paths block local validation, record that validation
happens on LXC 100 in Task 2 before `up`. Do not try to fake the missing paths.

Commit:
- Stage explicit paths only: `git add stacks/selfhosted/openwebui/compose.yaml stacks/selfhosted/openwebui/README.md`.
- NEVER stage .planning/phases/07-*/07-UAT.md, .planning/trips/ or projects/. Check with
  `git diff --cached --name-only`, which must list exactly those 2 files.
- Message: `feat(ollama): run on Radeon 890M via Vulkan (OLLAMA_IGPU_ENABLE=1); drop stale ROCm wording`.
  The body must name quick 261111-swk and the measured numbers, and end with the line
  `Claude-Session: https://claude.ai/code/session_01U6L4aqFUkCSrsCfTUHx8AQ`.

Push with `git push origin main`. Then gate on the push (memory: a rejected push followed by a host
pull deploys origin without your commit). `git ls-remote origin refs/heads/main | cut -f1` must
equal `git rev-parse HEAD`. If they differ, STOP and do not start Task 2.
  </action>
  <verify>
    <automated>cd /Users/damian/Development/damianflynn/selfhost-stacks && /usr/bin/grep -c 'OLLAMA_IGPU_ENABLE=1' stacks/selfhosted/openwebui/compose.yaml && ! /usr/bin/grep -n 'GPU (ROCm) acceleration' stacks/selfhosted/openwebui/compose.yaml && /usr/bin/grep -c 'inference compute' stacks/selfhosted/openwebui/README.md && ! /usr/bin/grep -n "rocm-smi" stacks/selfhosted/openwebui/README.md && test "$(git ls-remote origin refs/heads/main | cut -f1)" = "$(git rev-parse HEAD)" && git show --name-only --format= HEAD | sort</automated>
  </verify>
  <done>
- compose has exactly one `OLLAMA_IGPU_ENABLE=1`, under a dated comment.
- `git diff HEAD~1 -- stacks/selfhosted/openwebui/compose.yaml` shows only that addition and the
  header-comment change.
- The README has no `rocm-smi`, and its GPU checks use `inference compute` and `ollama ps`.
- HEAD touches exactly the 2 files, and origin/main equals HEAD.
  </done>
</task>

<task type="auto">
  <name>Task 2: Deploy ai-ollama only on LXC 100 and prove Vulkan offload (operator-authorised)</name>
  <files>(none: host-side deploy; evidence goes to the SUMMARY)</files>
  <action>
All remote commands run over ssh. Bound each one Linux-side, for example
`ssh root@HOST 'set -o pipefail; timeout 120 ...'`. The workstation has no GNU timeout, and its grep
is ugrep, so use `/usr/bin/grep` or `grep -F` locally. Read the ssh RC on every call
(CONVENTIONS 1-3). Record every step below as PROVEN or NOT PROVEN, with the raw output line.

1. **Baseline on atlantis.** Run
   `ssh root@172.16.1.158 'dmesg | grep -c amdgpu_hmm_invalidate_gfx; cat /proc/sys/kernel/tainted; uname -r'`.
   Note: `grep -c` exits 1 on 0 matches, so take the printed number and not the RC. Expect 0, 4097
   and 7.0.14-28. Record the image/state of the old container with
   `ssh root@172.16.1.159 'docker inspect -f "{{.Config.Image}} {{.RestartCount}} {{.State.StartedAt}}" ai-ollama'`.
   Record the current `selfhost_container_restart_count{name="ai-ollama"}` line with
   `grep -F 'name="ai-ollama"' /mnt/fast/appdata/monitoring/node-exporter-textfile/container-restarts.prom`.

2. **Host tree check on LXC 100.** Run
   `cd /mnt/fast/stacks && git status --short`. If ANY line touches
   `stacks/selfhosted/openwebui/`, STOP, report it and do not pull (memory: the host is ahead of
   git). Unrelated dirty paths: record them and continue.

3. **Pull and validate.** Run `git pull --ff-only`, then confirm the host's `git rev-parse HEAD`
   equals the Task 1 commit. Then run
   `docker compose -f stacks/selfhosted/openwebui/compose.yaml config -q`, which must exit 0.
   Confirm the rendered env with
   `docker compose -f stacks/selfhosted/openwebui/compose.yaml config | grep -F OLLAMA_IGPU_ENABLE`.

4. **Recreate only ai-ollama.** Run
   `docker compose -f stacks/selfhosted/openwebui/compose.yaml up -d --no-deps ai-ollama`, bounded at
   `timeout 300` because the pull happens here. Never run `up` without the service name, and never
   touch another container.

5. **Discovery proof.** Wait for startup (poll `docker logs ai-ollama` up to ~60 s, Linux-side).
   Then:
   - `docker logs ai-ollama 2>&1 | grep -F "inference compute"` must include `library=Vulkan` and
     `Radeon 890M`.
   - `docker logs ai-ollama 2>&1 | grep -c -F "dropping integrated GPU"` must print 0.
   - Record the running image (expected 0.40.16).

6. **Throughput proof.** Run
   `timeout 300 docker exec ai-ollama ollama run --verbose qwen2.5:3b "Reply with one short sentence: what is the capital of Ireland?"`.
   Record `eval rate` and `prompt eval rate`. Pass means eval rate above 5 tok/s (the expectation is
   about 18; anything near 0.26 means it is still on CPU). While the model is loaded, run
   `docker exec ai-ollama ollama ps`; PROCESSOR must read `100% GPU`. Also grep the logs for
   `offloaded` and record the `offloaded N/N layers` line. Afterwards run
   `docker exec ai-ollama ollama stop qwen2.5:3b`.

7. **Open WebUI reachability.** Find the open-webui container name with
   `docker ps --format '{{.Names}}' | grep -i webui`. From inside that container, request
   `http://ai-ollama:11434/api/tags` (the configured OLLAMA_BASE_URLS), using `curl -s -o ... -w '%{http_code}'`.
   If the image has no curl, use
   `python3 -c 'import urllib.request,json;r=urllib.request.urlopen("http://ai-ollama:11434/api/tags",timeout=10);print(r.status,[m["name"] for m in json.load(r)["models"]])'`.
   Expect 200 and the 3 models; record their names.

8. **Stability.**
   - `docker inspect -f '{{.RestartCount}} {{.State.Status}} {{.State.Health.Status}}' ai-ollama`
     must give RestartCount 0, running and healthy.
   - Read the `name="ai-ollama"` line of container-restarts.prom twice, at least one timer period
     apart. Check the file mtime advanced between reads, or wait at least 4.5 min and confirm it
     changed. The count must not climb between the two reads. A reset relative to step 1 is
     expected, since this is a new container.
   - If the mtime does not advance, record NOT PROVEN with "could not look", and do not record it as
     a pass.

9. **Kernel after.** Repeat the step 1 atlantis command. The amdgpu_hmm_invalidate_gfx count must
   equal the baseline (0), and tainted must equal the baseline (4097).

**Rollback.** Trigger it if step 5 or 6 shows no Vulkan offload, step 8 shows a restart loop, or
step 9 shows the count or taint rising:
1. On the workstation, `git revert --no-edit HEAD` (the message must still end with the
   Claude-Session line), then push and check ls-remote equals HEAD.
2. On LXC 100, `git pull --ff-only` and the same `up -d --no-deps ai-ollama`.
3. Confirm the `dropping integrated GPU` line is back.
4. Record the rollback in the SUMMARY. If the oops count rose, flag it prominently: it would mean
   the D-30 mitigation premise has failed.
  </action>
  <verify>
    <automated>ssh root@172.16.1.159 'set -o pipefail; timeout 30 docker logs ai-ollama 2>&1 | grep -F "inference compute" | grep -F "library=Vulkan" && test "$(timeout 30 docker logs ai-ollama 2>&1 | grep -c -F "dropping integrated GPU")" = 0 && timeout 10 docker inspect -f "{{.RestartCount}}" ai-ollama | grep -qx 0' && ssh root@172.16.1.158 'dmesg | grep -c amdgpu_hmm_invalidate_gfx; cat /proc/sys/kernel/tainted'</automated>
  </verify>
  <done>
- Steps 1-9 are each recorded PROVEN or NOT PROVEN, with raw evidence.
- Vulkan discovery is logged, with no dropping-iGPU line, and eval rate is above 5 tok/s (about 18
  expected) with `100% GPU`.
- Open WebUI gets 200 from /api/tags.
- RestartCount is 0 and the exporter count is stable.
- The atlantis oops count and taint are unchanged.
- Alternatively, the rollback was executed and recorded.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| container to host kernel | /dev/dri plus the Vulkan userptr path reaches the amdgpu driver on atlantis |
| LAN/tailnet to Ollama API | Unauthenticated API on 11434; this change does not alter its exposure |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-swk-01 | Denial of service | atlantis amdgpu (amdgpu_hmm_invalidate_gfx oops, the 2026-08-31 estate wedge) | mitigate | Baseline and post-deploy dmesg count plus taint on atlantis (steps 1 and 9). Defined rollback (revert, pull, recreate) if either rises. Kernel 7.0.14-28 carries fix #7905. |
| T-swk-02 | Denial of service | ai-ollama restart loop after recreate | mitigate | RestartCount check plus two exporter readings across timer runs (step 8). Rollback on a loop. |
| T-swk-03 | Tampering | deploying an un-pushed or diverged tree | mitigate | ls-remote equals HEAD gate before any host step. `git pull --ff-only`. Stop if the host has dirty openwebui paths. |
| T-swk-04 | Elevation of privilege | /dev/dri and group_add 44/110 | accept | Already granted before this change. No new devices or groups are added, and /dev/kfd stays absent. |
| T-swk-05 | Information disclosure | Ollama API exposure | accept | Unchanged. The Traefik ipallowlist and tsbridge labels are untouched. |
</threat_model>

<verification>
- Task 1 automated check passes: the env var is present, no ROCm header or rocm-smi remains, and
  origin equals HEAD.
- Task 2 automated check passes: Vulkan is in the log, there are 0 dropping-iGPU lines,
  RestartCount is 0, and the atlantis count/taint match the baseline.
- The SUMMARY lists each of the 9 proof steps as PROVEN or NOT PROVEN.
</verification>

<success_criteria>
- ai-ollama serves qwen2.5:3b from the Radeon 890M via Vulkan at roughly 18 tok/s, up from
  0.26 tok/s.
- No other container was recreated, and no unrelated working-tree file was committed.
- The amdgpu oops count stays 0 and taint stays 4097.
- The repo docs no longer claim ROCm.
</success_criteria>

<output>
Create `.planning/quick/261111-swk-ollama-vulkan-igpu/261111-swk-SUMMARY.md` when done.
</output>
