# Quick Task 260906-eza: Reclaim ~2.8 GB, retire Mattermost, stand up TREK + TeslaMate

**Created:** 2026-09-06
**Status:** Ready for execution

## Why

atlantis sits at ~709 MB available of 29.7 GB, with ZFS ARC crushed below its own `c_min` — the
documented precondition for the `amdgpu_hmm_invalidate_gfx` oops (`infra/variables.tf:262-267`,
~6 h outage 2026-08-31) and the direct cause of the live-TV freeze on 2026-09-05.

Quick task `260906-e6l` bounded the *risk* (caps). This task reclaims *actual* memory, then spends
part of it on two services the user does want.

## Decisions taken (user, 2026-09-06)

| Service | Decision |
|---|---|
| Mattermost | **Full delete — stack and data.** Explicitly confirmed. Not coming back. |
| postiz | Shut down, **keep definition and data** |
| open-archiver | Shut down, **keep definition and data** |
| homarr | Shut down, **keep definition and data** |
| cadvisor | **Keep** — it is broken, not unwanted. Separate fix, see Part C |
| TREK | Stand up — `github.com/liketrek/TREK` |
| TeslaMate | Stand up — `github.com/teslamate-org/teslamate`, unofficial owners-API tokens |

## Measured budget

Freed (measured `docker stats` 2026-09-06):

| Stack | Containers | RAM freed |
|---|---|---|
| open-archiver (+ postgres, meilisearch, valkey, tika) | 5 | 1,221 MB |
| postiz (+ postgres, redis) | 3 | 999 MB |
| homarr | 1 | 452 MB |
| mattermost (+ db) | 2 | 168 MB |
| **Total freed** | **11** | **≈2,840 MB** |

Spent (estimated): TeslaMate ≈ 700 MB (app + postgres + grafana + mosquitto), TREK ≈ 250 MB.
**Net gain ≈ 1.9 GB**, plus ~500 MB of LXC-100 root disk from Mattermost.

## Part A — Teardown (live host, done by the orchestrator, not the executor)

Destructive. Run from LXC 100 at `/mnt/fast/stacks`.

**A1 — Mattermost, full delete.** Confirmed destroys these 7 volumes (~250 MB) permanently:
`mattermost_mattermost_{bleve_indexes,client_plugins,config,data,db_data,logs,plugins}`
plus `/mnt/fast/appdata/mattermost` (250 MB, and note this sits on LXC 100's ext4 **root**, not a
ZFS dataset — see the known `/mnt/fast/appdata` non-mountpoint issue — so it also reclaims root disk).

```bash
docker compose -f stacks/selfhosted/mattermost/compose.yaml down -v
rm -rf /mnt/fast/appdata/mattermost
```

**A2 — postiz, open-archiver, homarr: stop, keep data.** `down` **without** `-v`. Named volumes and
bind mounts survive; `up -d` restores them.

```bash
docker compose -f stacks/selfhosted/postiz/compose.yaml down
docker compose -f stacks/selfhosted/open-archiver/compose.yaml down
docker compose -f stacks/selfhosted/homarr/compose.yaml down
```

Verified no cross-stack dependency: open-archiver is self-contained (own postgres, meilisearch,
valkey, tika); nothing outside its own directory references it except docs.

**Known consequence, accepted:** stopping postiz breaks the `/postiz` skill in `~/.claude/skills/`
and the MCP endpoint at `social.deercrest.info/mcp/<KEY>/sse`. Reversible by `up -d`.

## Part B — Repo changes (executor)

**B1 — Remove Mattermost from the repo.**
Delete `stacks/selfhosted/mattermost/` and `stacks/selfhosted/wrappers/mattermost.app.yaml`.
Update references in `STANDARDS.md` (numbered compose-file list), `MEDIA.md` (§ appdata-on-root
table names mattermost at 250 M), and `RENOVATE-REVIEW.md` if it lists mattermost images.
Do **not** invent doc edits beyond removing/adjusting real references.

**B2 — TREK.** `stacks/selfhosted/trek/` + `wrappers/trek.app.yaml`.

- Image: pin an explicit released tag from `ghcr.io/liketrek/trek` — **do not use `:latest`**
  (this repo has a documented Renovate deploy-drift problem). If no tag can be resolved, STOP and
  report rather than guessing.
- Single service, SQLite. Internal port **3000** — expose via traefik only, **no host port**
  (`cal-web` already publishes `127.0.0.1:3000`).
- Volumes: `/app/data`, `/app/uploads` as named volumes.
- Host: `trek.deercrest.info`, middleware `chain-authelia@file`, network `t3_proxy`.
- TREK needs a WebSocket upgrade on `/ws` — traefik handles this natively; no extra label needed,
  but do not add anything that would break it.
- `ENCRYPTION_KEY` from `.env`; ship `.env.sample` with a placeholder and the
  `openssl rand -hex 32` generation hint. **No real secret in git.**
- `mem_limit: 1g`, `restart: unless-stopped`, `env_file: .env`.

**B3 — TeslaMate.** `stacks/selfhosted/teslamate/` + `wrappers/teslamate.app.yaml`.

Adapt the upstream compose (user supplied it verbatim) to this estate's conventions:

- **Remove both `ports:` blocks.** Upstream publishes 4000 and 3000; 3000 collides with `cal-web`,
  and this estate routes through traefik. Mosquitto stays internal (upstream already comments it out).
- Pin images explicitly — **no `:latest`** on `teslamate/teslamate` or `teslamate/grafana`.
- Keep `postgres:18-trixie` as upstream specifies.
- Keep `cap_drop: all` on the teslamate service.
- Two routers, both `chain-authelia@file` on `t3_proxy`:
  - `teslamate.deercrest.info` → teslamate service, port 4000
  - `teslamate-grafana.deercrest.info` → grafana service, port 3000
  **Authelia is not optional here** — TeslaMate holds the vehicle's full location history, and
  upstream explicitly warns the default setup is home-network-only.
- Secrets to `.env` + `.env.sample`: `TESLAMATE_ENCRYPTION_KEY`, `TESLAMATE_DB_PASS`. The same
  password must reach `DATABASE_PASS` (teslamate, grafana) and `POSTGRES_PASSWORD` (database) —
  drive all three from the one variable.
- **No Tesla credentials anywhere in the repo.** The user is using unofficial owners-API tokens,
  which are entered in the TeslaMate web UI and encrypted at rest with `ENCRYPTION_KEY`.
- `mem_limit`: teslamate `1g`, database `1g`, grafana `512m`, mosquitto `128m`.
- Named volumes: `teslamate-db`, `teslamate-grafana-data`, `mosquitto-conf`, `mosquitto-data`.

## Part C — cadvisor (diagnose only, do not fix in this task)

cadvisor is **unhealthy and has been silently dead for 4+ days**: `docker ps` says
`Up 4 days (health: starting)`, `docker inspect` says `unhealthy` with 5 failures, `docker stats`
reports `0B / 0B`, and Prometheus has it `health: "down"` with
`lookup cadvisor on 127.0.0.11:53: no such host`.

Ruled out: it is **not** a network mismatch — cadvisor and prometheus are both on `t3_proxy`.
This is the same class as the documented `created`-state blind spot: `docker ps` reports healthy-looking
state for a container that is not working. Record it as a follow-up; do not fix it here.

## Out of scope

- The `terraform plan`/`apply` from `260906-e6l` — still the user's to run.
- Redeploying the 12 `mem_limit` caps from `260906-e6l` — inert until each stack is recreated.
- The 32 GB → 64 GB RAM upgrade (DIMM 1 empty). Still the real fix.
- `social/postiz.yaml`, the stale duplicate. Untouched.
- Cloudflare DNS records for the two new hostnames — see Verification.

## Verification

- `docker compose -f <file> config -q` parses clean for both new stacks.
- No `:latest` tag in either new stack; every image pinned.
- No secret, token or password value in the diff — **this repo is public**. `.env` is gitignored
  (`**/.env`); only `.env.sample` with placeholders is committed.
- `grep -rn mattermost` returns no live stack references (docs-history mentions are fine).
- No host `ports:` published by either new stack.
- Both new stacks carry `chain-authelia@file`.

## Deploy steps (after repo changes land)

```bash
ssh root@172.16.1.159 && cd /mnt/fast/stacks && git pull
# generate secrets into each stack's .env (NOT committed), then:
docker compose -f stacks/selfhosted/trek/compose.yaml up -d
docker compose -f stacks/selfhosted/teslamate/compose.yaml up -d
```

**DNS:** traefik obtains certs via the `dns-cloudflare` DNS-01 resolver, but `trek.deercrest.info`,
`teslamate.deercrest.info` and `teslamate-grafana.deercrest.info` still need to resolve for
external access. Confirm whether a wildcard record covers them before assuming they are reachable.

**Then, in the TeslaMate UI:** sign in with the unofficial owners-API tokens. They are encrypted at
rest with `ENCRYPTION_KEY` — if that key is ever lost or changed, the stored tokens become
unreadable and must be re-entered.
