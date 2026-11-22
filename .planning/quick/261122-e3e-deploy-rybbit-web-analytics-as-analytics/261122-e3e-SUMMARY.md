---
phase: quick-261122-e3e
plan: 01
status: complete
subsystem: stacks/analytics
tags: [rybbit, analytics, traefik, authelia, clickhouse, cloudflare, hugo]
requires: []
provides:
  - "analytics stack (Rybbit v2.9.3, five containers) live on LXC 100 at pulse.deercrest.info"
  - "HUGO.md integration guide for the publishing agent"
affects:
  - "social stack (deleted)"
  - "renovate.json5, scripts/deploy-stacks.sh, scripts/pg-migrate.sh"
tech-stack:
  added: [rybbit-backend v2.9.3, rybbit-client v2.9.3, clickhouse-server 26.3.17.4, postgres 17.4, redis 8.6.4-alpine]
  patterns: [public tracking router on default-headers only, prefixed service names, bind volumes under /mnt/fast/appdata/analytics]
key-files:
  created:
    - stacks/selfhosted/analytics/compose.yaml
    - stacks/selfhosted/analytics/rybbit.yaml
    - stacks/selfhosted/analytics/.env.sample
    - stacks/selfhosted/analytics/clickhouse/config.d/rybbit.xml
    - stacks/selfhosted/analytics/clickhouse/users.d/rybbit.xml
    - stacks/selfhosted/analytics/HUGO.md
    - stacks/selfhosted/wrappers/analytics.app.yaml
  modified: [renovate.json5, scripts/deploy-stacks.sh, scripts/pg-migrate.sh, BACKLOG.md, NETWORK.md, README.md]
  deleted:
    - stacks/selfhosted/social/compose.yaml
    - stacks/selfhosted/social/rybbit.yaml
    - stacks/selfhosted/social/.env.sample
    - stacks/selfhosted/wrappers/social.app.yaml
decisions:
  - "Rybbit was deployed with DISABLE_SIGNUP=true, not false. Authelia's estate-wide *.deercrest.info ^/api/.*$ bypass makes /api/auth/* reachable from the internet, and upstream makes the first user to sign up the instance admin."
  - "D-04's 'non-tracking /api is behind Authelia' does not hold on this estate; /api is protected only by Rybbit's own auth (401/403 measured). The dashboard (/) is behind Authelia."
metrics:
  completed: 2026-11-22
  tasks_done: 2
  tasks_total: 3
---

# Quick 261122-e3e: Deploy Rybbit web analytics as `analytics` Summary

Rybbit v2.9.3 runs as a new five-container `analytics` stack on LXC 100 at
`https://pulse.deercrest.info`. The tracking script and ingest are public with working cross-origin
CORS, and the dashboard is behind Authelia plus Rybbit's own login. ClickHouse is held at a 1 GiB
server cap. The never-startable `social` stack is deleted. **Status: stopped at the T3 operator
checkpoint.** Signup is currently **locked** (see Deviations), so the operator's first signup needs
one decision first.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| T1 | `1c50e85b` | feat(analytics): deploy rybbit web analytics as analytics stack, retire social (#307). It was committed locally as `94f2037a`, then replayed onto origin/main because Renovate had raced main by 13 commits. No stash was used: `reset --keep` + cherry-pick, with no overlapping files. |
| T2 | (host-side only, no repo commit) | push, host pull, .env, DNS, compose up, assertions |

DEPLOY_SHA = `1c50e85b3b0b81400cc4d711ccf54717b5145d5d` = origin/main = the host checkout's HEAD.

## T2 evidence

- **Push gate:** the first push was rejected (non-fast-forward). After the replay, the push succeeded (`34f4df1a..1c50e85b`). Local HEAD == origin/main.
- **Host checkout:** `git status --porcelain` was empty, so no patch was needed. `pull --ff-only` exited 0. The host jumped **67 commits** (1c078649 → 1c50e85b); everything apart from this commit is Renovate bumps, which were checked out but not deployed by this task. `grep -c pulse.deercrest.info rybbit.yaml` = 5. `social/` is gone, and no `social/.env` existed.
- **Pre-flight:** 0 containers with project `social`; none of the rybbit-* names existed. `/` avail 44G. MemAvailable before: 6441 MiB.
- **Authelia:** `default_policy: deny`, and a `*.deercrest.info` one_factor rule covers pulse. Nothing in it would deny the host. However, the earlier `*.deercrest.info` **bypass for `^/api/.*$` / `^/api?.*$`** applies to pulse as well (see Deviations).
- **Appdata:** `/mnt/fast/appdata/analytics/{clickhouse,postgres,redis}` were created. They are **not a mountpoint**: they sit on LXC root `/dev/mapper/pve-vm--100--disk--0`.
- **.env:** created host-side from `.env.sample` with `openssl rand -hex 32` run in the remote shell; mode 600. Each of the 4 secrets matches `^K=[0-9a-f]{64}$` (count 1 each). They are pairwise distinct (4 unique). There are 0 `=CHANGE_ME` values; the one `CHANGE_ME` hit is the header comment. Git ignores the file and `status --porcelain` does not list it. `DISABLE_SIGNUP=true`. No values were printed.
- **DNS:** the GET returned 0 records, then the POST created a proxied CNAME `pulse` → `deercrest.info` (`success: true`). `dig @1.1.1.1` returned 172.67.175.143 and 104.21.83.117 within 5 s.
- **Up:** pull and `up -d` both exited 0. Avail after pull: 42G. Container states:
  - clickhouse, postgres, redis and backend: `running healthy`, restarts=0
  - client: `running` (it has no healthcheck), restarts=0
  - The backend log is clean apart from the benign "Social provider github is missing clientId" and Fastify deprecation warnings.

### Assertions 8a–8g

All probes ran from LXC 100 out through Cloudflare. The workstation cannot reach **any**
`*.deercrest.info` origin through Cloudflare right now: `pocket.` timed out the same way, and a
direct TCP connection to 172.16.1.159:443 also timed out. That fault is on the workstation side,
was already there, and was not caused by this change. The workstation also had pulse's
pre-creation NXDOMAIN cached.

| # | Result | Evidence |
|---|--------|----------|
| 8a | **PASS** | `200 application/javascript; charset=utf-8`, no cookies |
| 8b | **PASS** | `HTTP/2 204`, `access-control-allow-origin: https://example.com`, `access-control-allow-methods: GET, POST, PUT, DELETE, OPTIONS, PATCH`. The backend answered, not Traefik's secure-headers list. |
| 8c | **PASS** | `HTTP/2 404`, `application/json`, ACAO echoed, body `{"success":false,"error":"Site not found","code":"NOT_FOUND",...}`. No 302 and no `location` header. |
| 8d | **PARTIAL FAIL** | `/` → `302 https://auth.deercrest.info/?rd=https%3A%2F%2Fpulse.deercrest.info%2F&rm=GET` (PASS). `/api/sites` → **404** and `/api/health` → **200**, both answered by the backend without Authelia (FAIL against the plan). The cause is the pre-existing Authelia `*.deercrest.info` `^/api/.*$` bypass, not the Traefik labels. Rybbit's own auth does guard the data: `/api/sites/1/overview` → 403 FORBIDDEN and `/api/user/organizations` → 401 AUTHENTICATION_REQUIRED. `/api/version` → 200 `{"version":"2.9.3"}`. |
| 8e | **PASS** | `/api/site/tracking-config/1` → 404 JSON "Site not found" (no 302) |
| 8f | **PASS** | clickhouse `174.4MiB / 1.5GiB`, postgres `22.8MiB / 512MiB`, redis `6.465MiB / 256MiB`, backend `251.6MiB / 1GiB`, client `36.73MiB / 512MiB`. `max_server_memory_usage` = `1073741824`. Logging tables count = `0`. Profile `max_memory_usage`/`max_threads` = `536870912`/`2`. |
| 8g | **PASS** | `/` avail 42G (≥ 20). MemAvailable 6441 → 6097 MiB (−344 MiB). |

Signup lock as deployed: `docker inspect` env shows `DISABLE_SIGNUP=true` count 1 on rybbit-backend and `NEXT_PUBLIC_DISABLE_SIGNUP=true` count 1 on rybbit-client.

### Estate health check

`bash scripts/quick-health-check.sh` → **exit 1**. The single failure:

```
Music consumers audit: ❌ BROKEN (check-music-consumers.sh exit 1)
    ❌ CONF-04 (D-22): '/media/Music/Lady Gaga/ARTPOP (2013)/CD 01-05 Lady Gaga - Jewels n’ Drugs.flac' has 1 artist entities — expected 4 (post-re-probe)
```

This failure was already there and is not caused by this change. It is the music project's
Jellyfin artist-entity check, and this task does not touch Jellyfin or Music. Every other block is
green:
- 95 containers running; no unhealthy or restarting containers.
- `/` headroom 41.15 GiB.
- Image drift: 35, REPORTED and not asserted. Most of this is the 67 Renovate commits now checked out on the host; drift is alert-only.
- Unresolvable: 2, which is the expected value.

## Deviations from Plan

**1. [Rule 2 - Security] Deployed with `DISABLE_SIGNUP=true` instead of `false`**
- **Found during:** T2 step 3 (Authelia read).
- **Issue:** Authelia's `access_control` has a `*.deercrest.info` **bypass** for `^/api/.*$` and `^/api?.*$`, placed above the one_factor rule. Every `/api` request to pulse, including better-auth's `/api/auth/sign-up/email`, therefore passes forward-auth. Upstream `server/src/lib/auth.ts` (v2.9.3, around line 344) makes **the first user to sign up the instance admin**. With signup open, anyone on the internet who found the new hostname (it appears in certificate transparency and DNS) could have claimed the admin account before the operator. Threat T-e3e-03's mitigation assumed Authelia gated `/api/auth/*`, which is false here.
- **Fix:** the host `.env` was generated with `DISABLE_SIGNUP=true`. The repo `.env.sample` and compose default stay `false`, as planned. Authelia was **not** edited: it is shared estate auth config and the plan said not to touch it. T3 now needs a decision from the operator (below).
- **Files:** host-only `/mnt/fast/stacks/stacks/selfhosted/analytics/.env`.

**2. [Rule 3 - Blocking] Replayed the commit onto origin/main without stashing**
- The push was rejected because Renovate had raced main. The working tree carried the user's unrelated changes, which may not be stashed, so `git pull --rebase` was not possible. Fix: `git reset --keep origin/main` + `git cherry-pick`. The incoming commits shared no files with the user's changes. The commit is now `1c50e85b` (it was `94f2037a`).

**3. [Rule 1] pg-migrate comment reworded**
- The removal comment first named `do_rybbit`, which tripped the plan's own verify grep. It now reads "The social-postiz and rybbit migration targets were removed 2026-11-22".

**4. Minor — the ClickHouse password briefly appeared in an argv inside the container**
- For 8f, `clickhouse-client --password "$CLICKHOUSE_PASSWORD"` was expanded by `sh` inside rybbit-clickhouse. The value never reached the workstation or any output. It was visible only in that container's process list for the life of the query, which is root-on-LXC-100 trust: the same level as `.env` and T-e3e-06. Next time, use `CLICKHOUSE_PASSWORD` env pickup or an HTTP header file.

**5. Assertions ran from LXC 100, not the workstation**
- The workstation currently cannot reach any `*.deercrest.info` origin through Cloudflare (this was already the case; `pocket.` is affected the same way). LXC 100 → Cloudflare → Traefik is the same public path.

## T3 — checkpoint resolved (2026-11-22, orchestrator)

- **Operator chose Option A.** `/mnt/fast/appdata/traefik/authelia/configuration.yml` gained a
  `pulse.deercrest.info` `one_factor` rule directly under the TeslaMate rule, above the
  `*.deercrest.info` `/api` bypass. Backup: `configuration.yml.bak-20261122-pulse`. Authelia restarted:
  `running health=healthy restarts=0`. This file is appdata, not git.
- Probes after the change (from LXC 100 via Cloudflare): `/`, `/api/sites`, `/api/user/organizations`,
  `/api/auth/sign-up` → `302` to `auth.deercrest.info`. `/api/script.js` → `200`;
  `/api/site/tracking-config/1` → `404` JSON; `POST /api/track` `{}` → `400` (backend, no redirect).
  **8d now passes fully.**
- Signup opened (`DISABLE_SIGNUP=false`, backend + client recreated) behind Authelia. The operator signed
  up as admin and created site `damianflynn.com`, siteId `82add8b3b627` (a hex id, not numeric).
- Signup re-locked: `.env` has exactly one `DISABLE_SIGNUP=true`; container env shows `DISABLE_SIGNUP=true`
  (backend, healthy, restarts=0) and `NEXT_PUBLIC_DISABLE_SIGNUP=true` (client, restarts=0).
  Re-probe: `/` and `/api/auth/sign-up` → `302`; `/api/script.js` → `200 application/javascript`;
  `/api/site/tracking-config/82add8b3b627` → `200 application/json`; preflight
  `OPTIONS /api/track` with `Origin: https://damianflynn.com` → `204`.
- #307 commented and closed.

## Follow-ups

- `/mnt/fast/appdata/analytics` is on LXC 100's root disk, not its own dataset. It is a candidate for the README § Per-app datasets recipe.
- Rybbit's public-dashboard and embed features are intentionally unavailable. With Option A their endpoints are behind Authelia; under the current bypass they answer only to Rybbit auth.
- The Authelia `*.deercrest.info` `^/api/.*$` / `^/api?.*$` bypass undercuts any "dashboard API behind Authelia" design estate-wide (`^/api?.*$` matches any path starting `/ap`). This was already a known issue. Worth an estate-wide review.
- *Corrected by the orchestrator:* the workstation **can** reach the estate through Cloudflare (`curl --resolve pulse.deercrest.info:443:104.21.83.117` → `302`). The failure was macOS holding a negative DNS cache entry for the new name, looked up before the CNAME existed. Every upstream resolver (1.1.1.1, 8.8.8.8, 100.100.100.100, 172.16.1.1) answered correctly. Fix: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`, or wait for the negative TTL.

## Known Stubs

None. `.env.sample` placeholders are intentional and the host `.env` has real values.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: auth-bypass | /mnt/fast/appdata/traefik/authelia/configuration.yml (pre-existing) | The `*.deercrest.info` `/api` bypass exposes Rybbit's whole backend API (incl. `/api/auth/*`) to the internet, guarded only by Rybbit auth; mitigated for signup by DISABLE_SIGNUP=true |

## Self-Check: PASSED

- All 7 created files exist in the repo at HEAD. The 4 deleted paths are absent.
- Commit `1c50e85b` is on origin/main and on the host checkout.
