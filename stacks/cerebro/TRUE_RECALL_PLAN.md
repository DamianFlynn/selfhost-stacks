# TrueRecall Deployment Plan (Saved)

Date: 2026-02-26
Host: cerebro (172.16.1.160)

## Goal
Deploy full TrueRecall stack: watcher + curator + gem injection.

## Current Findings
- `/root/true-recall` clone is incomplete for full deployment.
- Missing key artifacts referenced by README:
  - `skills/qdrant-memory/scripts/realtime_qdrant_watcher.py`
  - `skills/qdrant-memory/mem-qdrant-watcher.service`
  - plugin wiring artifacts expected for full injection path
- Present artifacts include:
  - `install.py`
  - `tr-continuous/curator_timer.py`
  - `tr-continuous/curator_config.json`
- Existing memory stack (Jarvis) is active with cron jobs.

## Existing Jarvis Cron (currently active)
- `*/5 * * * *` cron capture
- `0 3 * * *` Redis -> Qdrant flush
- `30 3 * * *` sliding backup

## Coexistence Rule
Avoid duplicate ingestion pipelines.
When TrueRecall watcher is enabled, disable overlapping Jarvis capture/flush jobs.

## Model/Provider Strategy
- Embeddings: local Ollama works (`snowflake-arctic-embed2` confirmed).
- Curator LLM in current timer script is Ollama-local and hardcoded to qwen3 30b variant.
- For limited local hardware, likely use hosted curator model (Moonshot/Kimi) after script adaptation.

## Required Work Before Deploy
1. Obtain missing watcher/service/plugin files from correct upstream package/branch.
2. Decide deployment mode and overlap cutover strategy from Jarvis.
3. Patch curator to use config-driven model/provider (not hardcoded local Ollama only).
4. If using hosted model, add provider endpoint + auth handling.
5. Validate collections and runtime:
   - source: `memories_tr`
   - target: `gems_tr`
   - watcher service active
   - curator cron active

## Preflight Checklist (next session)
- Verify artifact completeness in `/root/true-recall`.
- Verify model availability (local or hosted).
- Verify Qdrant collections and point flow.
- Verify no duplicate cron/service ingestion.

## Notes
- We intentionally paused before install/deploy.
- Resume from this document in next TrueRecall session.
- Remote copy: `/root/.openclaw/workspace/TRUE_RECALL_PLAN.md`.

## Update (2026-02-26, later)
- Verified upstream repo at commit `abc5498` (main) after fetch/pull.
- `tr-continuous/` currently contains only:
  - `curator_config.json`
  - `curator_timer.py`
- Root contains `README.md`, `checklist.md`, `install.py`, and `tr-continuous/`.
- Previously missing watcher artifacts are still not present in repo:
  - `skills/qdrant-memory/scripts/realtime_qdrant_watcher.py`
  - `skills/qdrant-memory/mem-qdrant-watcher.service`
  - `skills/qdrant-memory/SKILL.md`
- Implication: treat current upstream as curator-only package unless watcher components are provided from another source/repo.
