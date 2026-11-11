---
phase: quick-261111-swk
plan: 01
status: complete
subsystem: openwebui / ai-ollama
tags: [ollama, vulkan, amdgpu, igpu, radeon-890m]
requirements: [SWK-01, SWK-02, SWK-03]
key-files:
  modified:
    - stacks/selfhosted/openwebui/compose.yaml
    - stacks/selfhosted/openwebui/README.md
decisions:
  - "ai-ollama runs on the Radeon 890M via Vulkan with OLLAMA_IGPU_ENABLE=1; ROCm is not used (/dev/kfd not in LXC 100)"
metrics:
  completed: 2026-11-11
  tasks: 2
  files: 2
---

# Quick 261111-swk: Ollama on Radeon 890M via Vulkan — Summary

ai-ollama now serves qwen2.5:3b from the Radeon 890M via Vulkan at **21.15 tok/s** (100% GPU,
37/37 layers), up from 0.26 tok/s on CPU, with the atlantis amdgpu oops count and taint unchanged.

## Commit

- `84ce8ffe` feat(ollama): run on Radeon 890M via Vulkan (OLLAMA_IGPU_ENABLE=1); drop stale ROCm wording
  — touches exactly `stacks/selfhosted/openwebui/compose.yaml` and `README.md`. Pushed; `git ls-remote
  origin refs/heads/main` = `git rev-parse HEAD` = `84ce8ffeb97181779d37c32b387d0168445b6b87`.
  (Push printed the usual "Bypassed rule violations ... Required status check validate" notice.)
- Local `docker compose ... config -q` exited 0 (only warnings for unset POSTGRES_PASSWORD /
  WEBUI_SECRET_KEY, which live in the host env).
- README `rocm|kfd|HSA_OVERRIDE` grep: one surviving hit, line 67, the explicit "ROCm and `/dev/kfd`
  are NOT used" statement.

## Task 2 proof steps

| # | Step | Result | Evidence |
|---|------|--------|----------|
| 1 | Baseline | PROVEN | atlantis: `0` / `4097` / `7.0.14-28-pve`. Old container: `ollama/ollama:0.40.15 0 2026-11-11T19:23:57Z`. Exporter: `selfhost_container_restart_count{name="ai-ollama"} 0` |
| 2 | Host tree check | PROVEN | `git status --short` in `/mnt/fast/stacks` printed nothing (clean); host HEAD was `ccd8aeb6` |
| 3 | Pull + validate | PROVEN | `git pull --ff-only` → host HEAD `84ce8ffeb971…` (= Task 1 commit); `config -q` → CONFIG_OK; rendered `OLLAMA_IGPU_ENABLE: "1"` |
| 4 | Recreate ai-ollama only | PROVEN | `up -d --no-deps ai-ollama`: `Image ollama/ollama:0.40.16 Pulled` / `Container ai-ollama Recreated` / `Started`. Afterwards only `ai-ollama` showed a "minutes ago" creation time in `docker ps -a` |
| 5 | Discovery | PROVEN | `msg="inference compute" ... library=Vulkan ... description="AMD Radeon 890M Graphics (RADV GFX1150)" ... type=iGPU total="16.5 GiB" available="16.3 GiB"`; `dropping integrated GPU` count `0`; running image `ollama/ollama:0.40.16` |
| 6 | Throughput | PROVEN | `eval rate: 21.15 tokens/s`, `prompt eval rate: 177.99 tokens/s` (load 3.15 s cold); `ollama ps`: `qwen2.5:3b 2.4 GB 100% GPU 8192 llamacpp`; log `load_tensors: offloaded 37/37 layers to GPU`. `ollama stop qwen2.5:3b` run, `ollama ps` then empty |
| 7 | Open WebUI reachability | PROVEN | container `ai-openwebui` (`OLLAMA_BASE_URLS=http://ai-ollama:11434`): `200 ['nomic-embed-text:latest', 'qwen2.5:3b-32k', 'qwen2.5:3b']` |
| 8 | Stability | PROVEN | `docker inspect`: `0 running healthy` (both reads). Exporter read at mtime 20:54:01 → `restart_count 0`; read again after mtime advanced to 20:56:04 → `restart_count 0`, `restarting 0` |
| 9 | Kernel after | PROVEN | atlantis: `0` / `4097` / `7.0.14-28-pve` — identical to baseline |

Generation (21.15 tok/s) matches the 0.40.15 throwaway measurement (18.4 tok/s) and is now on
0.40.16. Prompt rate is lower than the throwaway's 252 tok/s, but this was a 42-token prompt on a
cold load, so the two are not comparable. The plan's automated Task 2 verify exited 0.

Rollback: not triggered.

## Deviations from Plan

None. The plan was executed as written.

## Self-Check: PASSED

- compose.yaml / README.md modified and in commit `84ce8ffe` (found in `git log`).
- origin/main = HEAD = host HEAD.
