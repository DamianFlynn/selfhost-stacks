---
quick_id: 260902-hya
description: Complete the keeper-sh .env.sample and correct the compose description comment
date: 2026-09-02
status: in-progress
---

# Quick Task 260902-hya: Close the remaining keeper-sh doc gaps

## Context

After 260902-fxf (README rewrite) and 260902-gln (reminder behaviour), a sweep of every keeper
reference in the repo found the stack README current but two of keeper's own files still wrong.

## Gap 1 — `.env.sample` documents 1 of 14 required variables

The tracked template contains only `POSTGRES_PASSWORD`. `compose.yaml` interpolates **fourteen**:

```
BETTER_AUTH_SECRET  BETTER_AUTH_URL  DOMAINNAME  ENCRYPTION_KEY
GOOGLE_CLIENT_ID  GOOGLE_CLIENT_SECRET  MCP_API_URL  MCP_PUBLIC_URL
MICROSOFT_CLIENT_ID  MICROSOFT_CLIENT_SECRET  POSTGRES_PASSWORD
TRUSTED_ORIGINS  VITE_MCP_URL  WEBSOCKET_URL
```

Anyone rebuilding this stack from the repo gets a broken deployment with no indication of what
is missing. The live `.env` on the host also carries `PUID`, `PGID` and `TZ`, which the compose
file does not interpolate but which are conventional across this repo's stacks.

Three of the fourteen (`MCP_PUBLIC_URL`, `MCP_API_URL`, `VITE_MCP_URL`) have working
`${VAR:-default}` fallbacks and are genuinely optional — omitting them disables MCP rather than
breaking the stack. That distinction must be visible in the template, not buried.

## Gap 2 — the compose description comment is wrong and actively misleading

`stacks/selfhosted/keeper-sh/compose.yaml` line 2 reads:

```
# Self-hosted Cal.com alternative for appointment booking
```

Keeper is a **calendar synchronisation engine**. It does not do appointment booking. Worse, this
repo contains a genuine cal.com deployment at `stacks/selfhosted/saas/calcom.yaml`
(`calcom/cal.com:v6.2.0`), so the line invites confusion between two real, different services.

Every other reference in the repo already gets this right — `renovate.json5:317` says
"Keeper.sh (Calendar Sync)" and `stacks/mpe/README.md:43` warns "not in Keeper (that's a
calendar…)". The compose header is the outlier.

Line 1 (`# Keeper.sh Stack - Calendar and scheduling service`) is recorded verbatim in
`STANDARDS.md:83`, so it must not change — only line 2.

## Verified NOT gaps (checked, no action)

- `.env` and `.env.backup` are both correctly gitignored (`**/.env`, `*.env.backup`); no secret exposure
- `renovate.json5` has `stack:keeper-sh` and correctly labels it Calendar Sync
- `scripts/pg-migrate.sh` handles keeper correctly (`do_keeper`)
- `stacks/selfhosted/wrappers/keeper-sh.app.yaml` is a correct include wrapper
- `STANDARDS.md:83` matches compose line 1

## Out of scope

`RENOVATE-REVIEW.md` is a dated point-in-time snapshot ("Renovate Review - 2026-06-11"). Both of
its keeper items are now resolved — `postgres:17 → 18` is deployed, and the `stack:keeper-sh`
label it lists as missing exists (as do all seven it flagged). Rewriting a historical review
document is a separate decision for the user, not a keeper-docs fix.

## Tasks

### Task 1 — Rewrite `.env.sample` to cover every variable
**Files:** `stacks/selfhosted/keeper-sh/.env.sample`
**Action:** Document all fourteen interpolated variables plus the conventional `PUID`/`PGID`/`TZ`,
grouped as: service account, core secrets, OAuth providers, URLs/origins, optional MCP. Mark the
optional ones explicitly. Include how to generate the secrets and the `ENCRYPTION_KEY` warning.
No real values — placeholders only; this repo is public.
**Verify:** Every `${VAR}` in compose.yaml appears in `.env.sample`; no real secret present.
**Done:** A clean rebuild from the repo has a complete template.

### Task 2 — Correct the compose description comment
**Files:** `stacks/selfhosted/keeper-sh/compose.yaml`
**Action:** Replace line 2 only. Keep line 1 (STANDARDS.md records it).
**Verify:** `docker compose config` still parses; line 1 unchanged.
**Done:** The header describes what keeper actually is and does not collide with the real cal.com stack.

## Must-haves

- **Truths:** `.env.sample` covers all 14 compose variables; the compose header no longer calls
  keeper an appointment-booking tool.
- **Artifacts:** rewritten `.env.sample`, corrected compose header.
- **Key links:** `stacks/selfhosted/keeper-sh/.env.sample`, `stacks/selfhosted/keeper-sh/compose.yaml`.
