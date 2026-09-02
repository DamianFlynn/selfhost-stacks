---
quick_id: 260902-fxf
description: Refresh keeper-sh docs against live state, add keeper-mcp service, relocate misfiled Innofactor docs
date: 2026-09-02
status: complete
commits:
  - 1851bc2 feat(keeper-sh) add keeper-mcp service
  - 2c54313 docs(keeper-sh) rewrite README against measured live state
  - 3a65fdf chore drop ignore rules for relocated Innofactor Graph docs
  - 8f6cf91f (neocortex) docs(innofactor) add Concierge Graph correspondence
---

# Quick Task 260902-fxf — Summary

## What was done

### Host upgrade (pre-task, user-approved)
LXC 100 keeper stack upgraded **2.13 → 2.23**, clearing ~3 months of Renovate deploy drift
(PRs #324–327 merged in August; the host was never re-pulled).

- Pre-upgrade dump: `/mnt/fast/appdata/automation/keeper/backups/pre-upgrade-2.13-20260902-094819.sql`
  (1.3 MB, 25 tables)
- All six services recreated on 2.23; no migration errors in `cal-api`, no worker errors,
  8 consecutive `"outcome":"in-sync"` results post-restart
- Sync parity moved 282/282 → 467/467 on both Google calendars — 2.23 ingests a wider window
- `/api/v1/sync` appeared (405 on GET, POST-only); it did not exist on 2.13

### Task 1 — `keeper-mcp` service added to compose (`1851bc2`)
Seventh service `cal-mcp` (`ghcr.io/ridafkih/keeper-mcp:2.23`), plus the three env vars that
make `/mcp` work: `MCP_PUBLIC_URL`/`MCP_API_URL` on `api`, `VITE_MCP_URL` on `web`.
No ports and no Traefik labels — upstream proxies `/mcp` through `cal-web` the same way it
proxies `/api`. Validated with `docker compose config` against the host's `.env`; all vars
resolve correctly.

**Not deployed.** The definition is committed; `docker compose up -d` on the host is a
separate user-gated action.

### Task 2 — README rewritten against measured state (`2c54313`)
Six substantive corrections, all verified live before writing:

| Claim | Was | Is |
|---|---|---|
| Versions | 2.9 / postgres:17 | 2.23 / postgres:18 |
| Accounts + calendars | 4 calendars, 4 accounts | 7 calendars, 3 accounts |
| Sync rules | 5 rules | 4 rules; 3 of the 5 documented did not exist |
| Work calendar | "Microsoft 365" | ICS feed, `authType=none`, read-only |
| Privacy | "busy blocks only, no subjects" | per-calendar; MVP propagates real titles |
| Health check | `curl /health` | no health endpoint exists; use the 401 |

The three phantom rules (`Family → Work`, `Personal → Family`, `Personal → Work`) were not
just absent but architecturally impossible — an ICS subscription has no write protocol, so
Work can never be a destination. Two real rules (`Work → Personal`, `MVP → Personal`) were
missing from the doc entirely.

New sections added:
- **Connecting from other systems** — minting a `kpr_` API token (Settings → API Tokens,
  shown once, bearer auth), the verified `/api/v1` surface, and MCP OAuth 2.1 wiring
  including the two quiet failure modes (`VITE_MCP_URL` unset → 307 to `/login`;
  `MCP_PUBLIC_URL` unset on the API → consent flow cannot complete)
- **Graph MailboxConcurrency throttling runbook** — measured at ~17% of sync ops
  (1,140 failures of 6,618 in 24h, 954 of them throttling), cause identified as the 60s cron
  fan-out across 7 calendars on one app registration, `PUSH_REDUCED_POLLING` named as the
  lever and deliberately not pulled
- Deploy-drift warning and the floating 2-part tag trap on the upgrade procedure
- Upgrade history table

Every SQL snippet in the doc was executed against the live database before commit.

### Task 3 — Innofactor documents relocated (`3a65fdf`, neocortex `8f6cf91f`)
`business-justification-graph-permissions.md` and `email-draft-graph-permissions.md` moved to
`neocortex/clients/innofactor/workloads/concierge/docs/`, renamed to match sibling naming.
Verified byte-identical before deleting the originals. The two now-dead `.gitignore` rules
were removed.

**Correction on the risk assessment:** these files were **never committed** — `.gitignore`
lines 30–31 excluded them explicitly and `git log --all` shows no history. There was no
public exposure; someone had deliberately kept them local-only.

## Deviations from plan

None material. One numeric refresh: the plan recorded 282/282 parity and 564/1,483
mappings/states from the pre-upgrade reading; the doc was written with the post-upgrade
figures (467/467, 934/1,676) and marked as point-in-time.

## Follow-ups left open

1. **Deploy `cal-mcp`** — compose defines it; the host still runs six services. Requires
   getting the commit onto `/mnt/fast/stacks` and `docker compose up -d`.
2. **Mint an API token** — `api_tokens` is still empty. Needs an interactive web-UI login.
3. **`PUSH_REDUCED_POLLING`** — the ~17% Graph failure rate is documented but unmitigated by
   explicit decision. Deserves its own change with before/after measurement.
4. **`United Kingdom holidays` 0 local / 2 remote** — a standing parity mismatch, noted in the
   doc, never investigated.
5. **`.env.backup`** sits alongside `.env` in the stack directory. Untracked, but worth
   confirming it belongs there.
