---
quick_id: 260902-fxf
description: Refresh keeper-sh docs against live state, add keeper-mcp service, relocate misfiled Innofactor docs
date: 2026-09-02
status: in-progress
---

# Quick Task 260902-fxf: Refresh keeper-sh stack documentation

## Context

An audit of `stacks/selfhosted/keeper-sh/` on 2026-09-02 found the README (last touched
2026-06-11, commit `0453502`) materially wrong in six places, and the running stack two
minor versions behind the repo. The host has since been upgraded 2.13 → 2.23 and verified.

All facts below were measured live against LXC 100 (`172.16.1.159`) and the keeper
Postgres database. They are recorded here verbatim so the doc rewrite does not re-derive
them.

## Measured ground truth (2026-09-02)

### Versions
| | README claimed | compose.yaml | Was running | Now running | Upstream latest |
|---|---|---|---|---|---|
| keeper-* | `2.9` | `2.23` | `2.13` | `2.23` | `2.23.3` |
| postgres | `17` | `18` | `18` | `18` | — |

`2.23`, `2.23.3` and `latest` all resolve to `sha256:2d06a7a05d3ba57482218cadd349f49cb8deaa7ca17fd9fb68b29a8d641e52b4`.
The `2.23` pin is a floating 2-part tag — `docker compose pull` moves it, not a tag edit.
Renovate has nothing pending for keeper (checked Dependency Dashboard issue #3 and the
23 open PRs). PRs #324–327 merged the 2.23 bump in August; the host was never re-pulled.

### Accounts (`calendar_accounts`) — 3, not 4
| provider | authType | identity | created |
|---|---|---|---|
| `google` | oauth | `damian.flynn@gmail.com` | 2026-03-18 |
| `outlook` | oauth | `Technology@damianflynn.com` | 2026-03-18 |
| `ics` | **none** | `https://outlook.office365.com/owa/calendar/…/calendar.ics` | 2026-08-11 |

### Calendars (`calendars`) — 7, not 4
| account | name | excludeEventName | customEventName |
|---|---|---|---|
| google | `damian.flynn@gmail.com` | false | `{{event_name}}` |
| google | `Family` | false | `{{event_name}}` |
| google | `Holidays in Ireland` | true | `{{calendar_name}}` |
| ics | `Work (Innofactor)` | **true** | `{{calendar_name}}` |
| outlook | `Birthdays` | true | `{{calendar_name}}` |
| outlook | `MVP` | **false** | `{{event_name}}` |
| outlook | `United Kingdom holidays` | true | `{{calendar_name}}` |

All 7 have `disabled=false`, `includeInIcalFeed=true`, `failureCount=0`.

### Sync rules (`source_destination_mappings`) — 4, not 5
| source | destination | created |
|---|---|---|
| `ics:Work (Innofactor)` | `google:damian.flynn@gmail.com` | 2026-08-11 |
| `ics:Work (Innofactor)` | `google:Family` | 2026-08-11 |
| `outlook:MVP` | `google:damian.flynn@gmail.com` | 2026-03-18 |
| `outlook:MVP` | `google:Family` | 2026-03-18 |

README claimed `Family → Work`, `Personal → Family`, `Personal → Work`. **None exist.**
They are also architecturally impossible: Work is an ICS feed (`authType=none`), which is
read-only and can never be a destination. README omitted `Work → Personal` and `MVP → Personal`.

### Sync status (`sync_status`)
`Family` 282/282, `damian.flynn@gmail.com` 282/282, all others 0/0 except
`United Kingdom holidays` 0 local / 2 remote. 564 `event_mappings`, 1483 `event_states`, 1 user.

### Error rate (cal-worker, 24h before upgrade)
6,618 sync ops, 1,140 `sync-push-failed` (~17%):
- 954 `Application is over its MailboxConcurrency limit.` (Graph throttling)
- 126 `Token refresh already in progress on another instance`
- 60 `Unable to connect. Is the computer able to access the url?` (the ICS fetch)
- 6 `Request timeout after 30000ms`

`cal-cron` fires every 60s across 7 calendars against one Graph app registration.
Upstream `keeper-cron` exposes `PUSH_REDUCED_POLLING`, unset here.

### API surface (verified on 2.23; 401 = exists, needs auth)
`/api/v1/calendars` 401, `/api/v1/accounts` 401, `/api/v1/events` 401,
`/api/v1/events/free-time` 401, `/api/v1/ical` 401, `/api/v1/sync` 405 (POST-only, new in 2.23).
There is **no** `/health` or `/api/v1/health` endpoint — the README's health-check command 404s.

### API tokens
`api_tokens` table exists (columns: id, userId, name, tokenHash, tokenPrefix, lastUsedAt,
expiresAt, createdAt). Currently **0 rows**. Minted via Settings → API Tokens in the web UI,
prefix `kpr_`, value shown once, sent as `Authorization: Bearer kpr_…`.

### MCP
`/mcp` on cal-web returns 307 → `/login` (SPA fallback — no MCP handler).
`/.well-known/oauth-protected-resource` on cal-web returns 200 with, via Traefik:
`{"resource":"https://keeper.deercrest.info/mcp","authorization_servers":["https://keeper.deercrest.info/api/auth"],"scopes_supported":["keeper.read","keeper.sources.read","keeper.destinations.read","keeper.mappings.read","keeper.events.read","keeper.sync-status.read"]}`

MCP needs a sixth image, `ghcr.io/ridafkih/keeper-mcp`, published from **2.19** onward.
Upstream wiring (from keeper.sh README):
- `MCP_PORT` — port the MCP server listens on (3002)
- `MCP_PUBLIC_URL` — public URL of the MCP resource; **enables OAuth on the API** and identifies the server to clients
- `MCP_API_URL` — internal URL to reach the Keeper API for tool calls and signing keys
- `VITE_MCP_URL` — internal URL the **web** server uses to proxy `/mcp` to the MCP service

"The MCP server is proxied through the web service at `/mcp`, the same way the API is
proxied at `/api`." → **no Traefik change needed**; `keeper.deercrest.info` already routes to cal-web.

`oauth_application` table is empty. MCP scopes are read-only.

### Misfiled documents
`business-justification-graph-permissions.md` and `email-draft-graph-permissions.md` are
Innofactor/Elmera correspondence about Microsoft Graph delegated permissions for "the
Concierge". They name individuals and describe employer tenant posture, in a **public** repo.
Destination confirmed: `/Users/damian/Development/damianflynn/neocortex/clients/innofactor/workloads/concierge/docs/`
(sibling to `concierge-requirements.md`, `concierge-newspoke-delegate.md`, etc.).

## User decisions (locked)

1. Host upgrade 2.13 → 2.23 with pg_dump first — **DONE**, backup at
   `/mnt/fast/appdata/automation/keeper/backups/pre-upgrade-2.13-20260902-094819.sql` (1.3 MB, 25 tables).
2. Add the `keeper-mcp` service to compose.
3. Document the Graph throttling as a runbook entry; **do not** set `PUSH_REDUCED_POLLING`.
4. Move the two Graph-permissions docs to the neocortex repo.

## Tasks

### Task 1 — Add `keeper-mcp` service to compose.yaml
**Files:** `stacks/selfhosted/keeper-sh/compose.yaml`
**Action:**
- Add `mcp` service: `container_name: cal-mcp`, `hostname: keeper-mcp`,
  `image: ghcr.io/ridafkih/keeper-mcp:2.23`, `restart: unless-stopped`, `env_file: .env`,
  env `DATABASE_URL`, `BETTER_AUTH_URL`, `BETTER_AUTH_SECRET`, `MCP_PORT: 3002`,
  `MCP_PUBLIC_URL`, `MCP_API_URL: http://cal-api:3001`; `depends_on` postgres healthy;
  `networks: [keeper-network]`. No ports, no Traefik labels.
- Add `MCP_PUBLIC_URL` + `MCP_API_URL` to the `api` service env.
- Add `VITE_MCP_URL: http://cal-mcp:3002` to the `web` service env.
- Keep the existing `${VAR:-default}` style so `.env` can override.
**Verify:** `docker compose -f stacks/selfhosted/keeper-sh/compose.yaml config` parses and
resolves; `cal-mcp` appears with the right image and env.
**Done:** compose is valid and defines seven services.

### Task 2 — Rewrite README.md against measured state
**Files:** `stacks/selfhosted/keeper-sh/README.md`
**Action:** Correct every finding above. Specifically:
- Header: 2.23 / Postgres 18 / Redis 7, dated.
- Replace the calendar topology table with the real 3 accounts / 7 calendars, and make the
  ICS nature of Work explicit as the reason nothing writes back into it.
- Replace the sync-rule table with the real 4 rules; fix the mermaid graph to match.
- Correct the privacy section: per-calendar `excludeEventName`/`customEventName`, and state
  plainly that MVP titles propagate.
- Seven containers, not six; add cal-mcp.
- New section: minting an API token (`kpr_`, bearer), the verified REST surface, and the
  MCP server + OAuth scopes.
- Fix the health-check commands (no `/health`; use `docker compose ps` + `/api/v1/calendars`
  returning 401 as a liveness signal).
- New runbook entry: Graph MailboxConcurrency throttling, with the measured rate, the
  diagnosis command, and `PUSH_REDUCED_POLLING` named as the lever (not applied).
- Upgrade procedure: note the floating 2-part tag and the Renovate deploy-drift trap.
- Backup section: reference the real backups path used today.
**Verify:** Every version, table, endpoint and count in the doc matches the ground-truth
section of this plan.
**Done:** README describes the deployment as it actually is.

### Task 3 — Relocate the two Graph-permissions documents
**Files:** `stacks/selfhosted/keeper-sh/business-justification-graph-permissions.md`,
`stacks/selfhosted/keeper-sh/email-draft-graph-permissions.md`
**Action:** Copy both to
`neocortex/clients/innofactor/workloads/concierge/docs/`, prefixed `concierge-` to match
sibling naming; `git rm` from this repo. Commit in the neocortex repo separately.
**Verify:** Files present in neocortex, absent from selfhost-stacks, both repos' git status clean.
**Done:** Innofactor correspondence no longer lives in the public repo working tree.

## Must-haves

- **Truths:** README contains no version, count, endpoint or sync rule contradicted by the
  measured state above; the phantom `Family → Work` / `Personal → *` rules are gone.
- **Artifacts:** `compose.yaml` defines `cal-mcp`; README has an API-token section; both
  Graph docs live in neocortex.
- **Key links:** `stacks/selfhosted/keeper-sh/compose.yaml`, `stacks/selfhosted/keeper-sh/README.md`.

## Out of scope

- Setting `PUSH_REDUCED_POLLING` (user deferred — behaviour change on a working sync).
- Deploying the `cal-mcp` service to the host (compose definition only; deploy is a
  separate, user-gated action).
- Minting an actual API token (requires interactive web-UI login).
