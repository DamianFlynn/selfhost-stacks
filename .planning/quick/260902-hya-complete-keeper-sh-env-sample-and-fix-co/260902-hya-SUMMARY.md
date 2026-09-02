---
quick_id: 260902-hya
description: Complete the keeper-sh .env.sample and correct the compose description comment
date: 2026-09-02
status: complete
---

# Quick Task 260902-hya — Summary

Swept every keeper reference in the repo after the README rewrite (260902-fxf) and the reminder
documentation (260902-gln). The stack README was current; two of keeper's own files were not.

## Gap 1 — `.env.sample` documented 1 of 14 required variables (fixed)

The tracked template carried only `POSTGRES_PASSWORD`. `compose.yaml` interpolates fourteen
variables. A clean rebuild from this repo would have produced a broken stack with no indication
of what was missing.

Rewritten to cover all fourteen plus the conventional `PUID`/`PGID`/`TZ`, grouped as service
account, core secrets, OAuth providers, URLs/origins, and optional MCP. Verified
programmatically — every `${VAR}` in compose.yaml now appears in the template, and a regex sweep
confirms no real secret values leaked into it (the repo is public).

Two things made explicit that were previously invisible:
- **`ENCRYPTION_KEY` is the critical value.** Lose it and every stored OAuth connection becomes
  permanently unreadable; a Postgres restore without the matching key yields an unusable
  credential store.
- **The three MCP variables are genuinely optional.** They have working `${VAR:-default}`
  fallbacks, so omitting them disables MCP rather than breaking the stack. Commented out with
  the reasoning, including that setting `MCP_PUBLIC_URL` on cal-api is what *enables* the OAuth
  authorisation server.

## Gap 2 — compose description comment was wrong and misleading (fixed)

Line 2 read `# Self-hosted Cal.com alternative for appointment booking`. Keeper is a calendar
**sync** engine and does no booking — and this repo contains a genuine cal.com deployment at
`stacks/selfhosted/saas/calcom.yaml` (`calcom/cal.com:v6.2.0`), so the line invited confusion
between two real, different services.

Replaced with an accurate description that also points at where the real Cal.com lives. Line 1
left untouched because `STANDARDS.md:83` records it verbatim. Compose re-validated: parses, 7
services.

Every other reference in the repo already had this right — `renovate.json5:317` says
"Keeper.sh (Calendar Sync)", `stacks/mpe/README.md:43` warns "not in Keeper (that's a
calendar…)". The compose header was the sole outlier.

## Checked, no action needed

- `.env` and `.env.backup` are both correctly gitignored (`**/.env`, `*.env.backup`) — no exposure
- `renovate.json5` has `stack:keeper-sh` and labels it correctly
- `scripts/pg-migrate.sh` handles keeper correctly via `do_keeper`
- `stacks/selfhosted/wrappers/keeper-sh.app.yaml` is a correct include wrapper
- `STANDARDS.md:83` matches compose line 1

## Deliberately out of scope

`RENOVATE-REVIEW.md` is a dated snapshot ("Renovate Review - 2026-06-11") and **both of its
keeper items are now stale-but-resolved**: `postgres:17 → 18` is deployed and running, and the
`stack:keeper-sh` label it lists as missing exists — as do all seven it flagged. Rewriting a
historical review document is a separate decision for the user, not a keeper-docs fix.
