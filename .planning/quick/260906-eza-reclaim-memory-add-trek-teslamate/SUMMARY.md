---
task: 260906-eza
title: Reclaim ~2.8 GB - retire Mattermost, add TREK and TeslaMate
status: complete
part: B (repo changes) only - Part A teardown done by the orchestrator, Part C deferred
date: 2026-09-06
commits:
  - edd2a5e feat(stacks): add TREK travel planner behind authelia
  - c2464cb feat(stacks): add TeslaMate with its own grafana, no published ports
  - 193812d chore(stacks): remove mattermost stack and its doc references
---

# Quick Task 260906-eza - Part B Summary

Repo-side half of the memory reclamation. No host was touched: no ssh, no docker,
no deploy. Part A (destroying Mattermost, stopping postiz/open-archiver/homarr on
LXC 100) was already complete before this ran.

## What changed

### B1 - Mattermost removed
- Deleted `stacks/selfhosted/mattermost/` (3 files) and `wrappers/mattermost.app.yaml`.
- `renovate.json5` - dropped the `stack:mattermost` auto-label rule and the
  `mattermost/mattermost-team-edition` major-update rule (27 lines).
- `scripts/pg-migrate.sh` - dropped `do_mattermost()`, its `run_all` call, its
  dispatch case, and corrected the valid-instance list printed on bad input.
  This was a live code path, not a doc mention.
- `README.md` - the pg-migrate worked example invoked `pg-migrate.sh mattermost`,
  which would now exit 1. Repointed at `n8n`.
- `MEDIA.md` section 8 - "Six other stacks are also on `/`" is now five, and the
  total drops from ~5 G to ~4.7 G with mattermost's 250 M gone.
- `DEPLOYMENT.md` - same six-to-five correction on the appdata-on-root list.
- `RENOVATE-REVIEW.md` - dropped the mattermost postgres bullet and corrected the
  stated instance count from 16 to 15.

**STANDARDS.md was not edited.** The plan and the task brief both expected
mattermost in its numbered compose-file list. It is not there - that list names 18
stacks and mattermost is not among them. No edit was invented.

### B2 - TREK at `stacks/selfhosted/trek/`
`compose.yaml`, `trek.yaml`, `.env.sample`, `wrappers/trek.app.yaml`.

- Image `mauriceboe/trek:4.2.0`. **The plan's `ghcr.io/liketrek/trek` does not exist**
  - see Deviations.
- No host `ports:`. Traefik only, on `t3_proxy`.
- `trek.deercrest.info`, `chain-authelia@file`, `dns-cloudflare` resolver.
- Named volumes `trek_data` (`/app/data`) and `trek_uploads` (`/app/uploads`).
- `ENCRYPTION_KEY` from `.env`; `.env.sample` carries a placeholder plus the
  `openssl rand -hex 32` hint.
- `mem_limit: 1g`, `mem_reservation: 128m`, `restart: unless-stopped`, `env_file: .env`.
- Kept upstream's `read_only: true`, `cap_drop: ALL` + minimal `cap_add`, tmpfs `/tmp`,
  and the `/api/health` healthcheck.
- Nothing added that would break the `/ws` WebSocket upgrade: no compression,
  buffering, retry or circuit-breaker middleware on the router. A comment in
  `trek.yaml` records that constraint so a future edit does not undo it.

### B3 - TeslaMate at `stacks/selfhosted/teslamate/`
`compose.yaml`, `teslamate.yaml`, `teslamate-db.yaml`, `teslamate-grafana.yaml`,
`mosquitto.yaml`, `.env.sample`, `wrappers/teslamate.app.yaml`.

- `teslamate/teslamate:4.2.0`, `teslamate/grafana:4.2.0`, `postgres:18-trixie`
  (upstream's choice, kept), `eclipse-mosquitto:2`.
- **Both upstream `ports:` blocks removed** - 4000 and 3000. 3000 would have
  collided with cal-web.
- Two routers, both `chain-authelia@file` on `t3_proxy`:
  `teslamate.deercrest.info` -> 4000, `teslamate-grafana.deercrest.info` -> 3000.
- `cap_drop: all` kept on teslamate; mosquitto keeps `mosquitto -c /mosquitto-no-auth.conf`.
- One `TESLAMATE_DB_PASS` drives `POSTGRES_PASSWORD` and both `DATABASE_PASS`
  values - verified identical in the rendered config, so they cannot drift.
- `mem_limit`: teslamate 1g, database 1g, grafana 512m, mosquitto 128m.
- Volumes `teslamate-db`, `teslamate-grafana-data`, `mosquitto-conf`, `mosquitto-data`
  as specified, plus `teslamate-import` (see Deviations).
- No Tesla credentials anywhere. Owners-API tokens are entered in the web UI and
  encrypted at rest with `ENCRYPTION_KEY`.
- Internal `teslamate` bridge network: database and mosquitto never join `t3_proxy`.

## Image tags - how they were verified

Every tag was confirmed to actually resolve, not just to look plausible. A
`GET /v2/<repo>/manifests/<tag>` against the registry with an anonymous pull token:

| Image | Result |
|---|---|
| `mauriceboe/trek:4.2.0` | HTTP 200 |
| `teslamate/teslamate:4.2.0` | HTTP 200 |
| `teslamate/grafana:4.2.0` | HTTP 200 |
| `postgres:18-trixie` | HTTP 200 |
| `eclipse-mosquitto:2` | HTTP 200 |
| `liketrek/trek:4.2.0` | HTTP 401 - does not exist |

Corroborated by Docker Hub's tag API (publish timestamps) and the upstream GitHub
releases API. `mauriceboe/trek:4.2.0` was published 2026-09-03T14:28:04Z and the
`liketrek/TREK` release `v4.2.0` was tagged 2026-09-03T14:28:37Z - a 33-second gap,
i.e. the same release pipeline. TeslaMate `4.2.0` on both images matches upstream
release `v4.2.0` (2026-08-23).

## Deviations from the plan

**1. [Rule 1 - Bug] The plan's TREK registry path is wrong.**
The plan and the task brief both specify `ghcr.io/liketrek/trek`. GHCR returns
`DENIED`/404 for that path and the Docker registry returns 401 for `liketrek/trek`.
Upstream's own `docker-compose.yml` and README both use **`mauriceboe/trek`** on
Docker Hub (1.01 M pulls). Used `mauriceboe/trek:4.2.0`. Deploying the planned
reference would have failed to pull.

**2. [Rule 2 - Security] Grafana admin credentials.**
Upstream ships TeslaMate's Grafana on stock `admin`/`admin`, changed by hand after
first login. Behind Authelia that is a single lock on a complete vehicle location
history. Added `TESLAMATE_GRAFANA_USER`/`TESLAMATE_GRAFANA_PASS` to `.env.sample`,
wired to `GF_SECURITY_ADMIN_USER`/`GF_SECURITY_ADMIN_PASSWORD` + `GRAFANA_PASSWD`,
and set `GF_AUTH_ANONYMOUS_ENABLED=false`. This is a third `.env` variable beyond
the two the plan listed.

**3. [Rule 3 - Blocking] `CHECK_ORIGIN` and `VIRTUAL_HOST` on teslamate.**
Not in the plan, but required by upstream's own Traefik guide. Without them the
Phoenix LiveView WebSocket rejects the proxied origin: the UI loads and then never
updates - a failure that looks like an app bug, not a config error.

**4. `./import` bind replaced with a named volume.** The plan allowed this
explicitly. Upstream's `./import:/opt/app/import` is relative, so under this repo's
layout it would resolve inside the git working tree at `/mnt/fast/stacks/...`,
putting runtime data under version control. Used `teslamate-import` instead. To
load a Tesla data export: `docker cp <file> teslamate:/opt/app/import/`.

**5. Plain named volumes, not `/mnt/fast/appdata` binds.** STANDARDS section
"Volume Mounting" prescribes `/mnt/fast/appdata/{stack}/{component}`, and homarr
implements that as a named volume with a bind `driver_opts`. Not followed here:
`/mnt/fast/appdata` is **not a mountpoint** (MEDIA.md section 8), so a bind there
lands on LXC 100's ext4 root exactly as `/var/lib/docker/volumes` does - no dataset,
no quota, no gain - while adding a pre-existing-directory requirement that cannot
be satisfied from the repo. The plan asked for named volumes and named them
explicitly. The reasoning is recorded in both `compose.yaml` headers.

**6. Grafana served from a subdomain, not a subpath.** Upstream's guide uses
`/grafana` with `GF_SERVER_SERVE_FROM_SUB_PATH=true`. The plan specifies a separate
hostname, so that is off and `GF_SERVER_ROOT_URL` is plain.

**7. No new `renovate.json5` per-stack rules.** Every existing stack has an
auto-label rule, so adding two would have matched the pattern - but the plan did not
ask, and the `**/stacks/**` catch-all already labels both new stacks `type:stack`
and tracks their pinned tags. Left alone rather than invented. Cheap to add later.

## Verification - 16/16 passed

Both stacks were rendered in a scratch directory outside the repo, with a `.env`
copied from the committed `.env.sample` (placeholder values only). No `.env` was
created inside the repo and no real secret was generated.

```
PASS  trek      compose config -q
PASS  teslamate compose config -q
PASS  no :latest in new stacks
PASS  no published ports (trek)
PASS  no published ports (teslamate)
PASS  trek has chain-authelia
PASS  teslamate 2x chain-authelia
PASS  no .env tracked in git
PASS  .env is gitignored
PASS  no live mattermost stack refs
PASS  mattermost dir gone
PASS  mattermost wrapper gone
PASS  trek wrapper exists
PASS  teslamate wrapper exists
PASS  pg-migrate.sh syntax (bash -n)
PASS  no secret literals in the diff
```

`renovate.json5` was additionally re-parsed after the mattermost rules were removed
(37 `packageRules` remain, parses clean). `renovate-config-validator` is not
installed on this workstation, so a JSON5 parse was used instead - weaker than the
real validator, and worth re-running before the next Renovate cycle given the
documented "config ERROR silently stops the whole repo run" failure mode.

The two surviving `mattermost` matches outside `.planning/` are the dated
retirement annotations deliberately added to `MEDIA.md` and `RENOVATE-REVIEW.md`.
No live stack reference remains.

## Not done / follow-ups

- **Nothing is deployed.** These stacks exist only in git. Deploy steps are in
  PLAN.md section "Deploy steps".
- **`.env` files must be created on the host** for both stacks before `up -d`.
  Neither will start without them.
- **DNS unconfirmed.** `trek.deercrest.info`, `teslamate.deercrest.info` and
  `teslamate-grafana.deercrest.info` need to resolve. Whether a wildcard covers
  them was not checked - this task did no network work.
- **Authelia access rules** for the three new hostnames were not reviewed. If
  Authelia's config enumerates hosts rather than matching a wildcard, the routers
  will be gated by a policy that does not exist yet.
- **Part C (cadvisor)** untouched, as the plan directs - diagnose only.
- **Post-deploy:** in TeslaMate, set Settings -> URLs to the two hostnames so the
  cross-links between TeslaMate and Grafana resolve.
- **Mosquitto is anonymous-access.** Safe only because it is on the internal
  network with no published port. If Home Assistant is ever pointed at it, publish
  1883 *and* switch to an authenticated config in the same change, not before.
