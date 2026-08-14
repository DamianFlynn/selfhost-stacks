# Buzz — self-hosted relay

> **Stack:** Buzz relay (pinned `sha-df9e773`) · Postgres 17-alpine · Redis 7 · MinIO · pairing sidecar
> **Host:** LXC `100` (`selfhost`) at `172.16.1.159`
> **Public:** `buzz.deercrest.info` + `pair.deercrest.info` via a dedicated Cloudflare Tunnel
> **Upstream:** [block/buzz](https://github.com/block/buzz) (Apache-2.0)

[Buzz](https://github.com/block/buzz) is Block's Nostr-based community chat, where humans and AI
agents share a channel as first-class members. This deployment serves the Deer Crest family plus one
resident agent, **DATA**, running headless on the Mac Mini.

Full deployment brief and design record live in the neocortex vault at
`clients/deer-crest/buzz_ai/`.

---

## Why this differs from upstream's compose

Upstream ships `deploy/compose/compose.yml`. This is vendored from it with four deliberate changes.

**Bind mounts, not named volumes.** Named Docker volumes land in `/var/lib/docker` on the LXC's
128 G root disk. The ZFS datasets do not:

| Path | Dataset | Holds |
|---|---|---|
| `/mnt/fast/appdata/buzz/{postgres,redis,git}` | `fast/appdata/buzz` | app data — 1.29 T avail |
| `/mnt/tank/buzz/minio` | `tank/buzz` | chat media — 9.07 T avail |

Media goes on `tank` because it is the growth-prone, irreplaceable part (family photos and video).
Directory ownership is per-service and **not** uniform — see the table below.

**No published host port.** Ports 3000–3002 are already in use here, and upstream's
`"${BUZZ_HTTP_PORT:-3000}:3000"` binds `0.0.0.0`, exposing the relay to the whole LAN. `cloudflared`
joins `buzz-net` and addresses `relay:3000` directly. Only a loopback debug port is published.

**A pairing sidecar that upstream omits.** The relay advertises NIP-43, so desktop clients expect a
pairing endpoint. Upstream's compose has no `buzz-pair-relay` service, so pairing fails and **no phone
can be onboarded at all** — reported three times upstream (#2734, #3291, #3842).
It must use `entrypoint:`; Compose's `command:` silently runs the relay binary instead.

The sidecar gets its **own hostname** rather than a `/pair` path on the relay host:

| Hostname | Target |
|---|---|
| `buzz.deercrest.info` | `relay:3000` |
| `pair.deercrest.info` | `pairing-relay:5000` |

Upstream's Caddy example proxies `/pair` with `handle_path`, which **strips the prefix**. Cloudflare
Tunnel ingress cannot strip paths, so a same-host `/pair` route would forward the prefix and break
pairing. Upstream's own Helm test uses a separate host too (`pairingRelay.url: wss://pairing.buzz.xyz`).

`BUZZ_PAIRING_RELAY_URL` **must** be `ws://` or `wss://` — the relay validates the scheme at startup
and refuses to boot on `https://`. It is advertised as `pairing_relay_url` in the NIP-11 document.

**A pinned image.** There is no stable semver relay image — GHCR carries `main`, `latest`, `0.1.0`,
`0.3.20-rc.win.2` and ~95 `sha-<7>` tags. The `desktop-v0.5.x` GitHub releases are the *desktop app*,
not the relay. `sha-df9e773` was chosen by matching the `main` tag's digest.

---

## Directory ownership

Each service runs as a different uid. Getting this wrong shows up as a container that restart-loops
on first boot.

| Path | Owner | Why |
|---|---|---|
| `/mnt/fast/appdata/buzz/postgres` | `70:70` | `postgres:17-**alpine**` runs as uid 70 — **not** 999 like the Debian image other stacks use |
| `/mnt/fast/appdata/buzz/redis` | `999:1000` | `redis:7-alpine` |
| `/mnt/fast/appdata/buzz/git` | `1000:1000` | relay runs as `buzz:buzz` |
| `/mnt/tank/buzz/minio` | `0:0` | the MinIO image declares no user |

---

## Operating

```bash
cd /mnt/fast/stacks/stacks/selfhosted/buzz

docker compose up -d --wait          # start
docker compose ps                    # status
docker compose logs -f relay         # logs
curl -fsS http://127.0.0.1:3080/_liveness

# membership (buzz-admin lives in the relay image)
docker compose exec relay /usr/local/bin/buzz-admin list-members
docker compose exec relay /usr/local/bin/buzz-admin add-member --pubkey <npub-or-hex> --role member
```

> **Adding several members: `sleep 1` between each.** The roster is a single replaceable
> **kind:13534** event, so two adds landing in the same second silently drop a member. Never
> parallelise (no `xargs -P`), and assert the final count with `list-members`.

Roles are `owner | admin | member`. `owner` comes solely from `RELAY_OWNER_PUBKEY` and outranks
admin; `buzz-admin` refuses `--role owner`. Only the owner can change roles (kind 9032).

---

## Backups

The relay private key and the Postgres database **must be backed up and restored together**. A
restored database paired with a fresh relay key is a different relay, and every previously signed
event stops verifying.

Back up: `BUZZ_RELAY_PRIVATE_KEY`, Postgres, the MinIO bucket, `/mnt/fast/appdata/buzz/git`, and the
owner key. `docker compose exec relay /usr/local/bin/buzz-admin --help` and upstream's
`run.sh backup-hint` enumerate the same five.

---

## Known upstream issues affecting this deployment

| # | Issue |
|---|---|
| #2734 / #3291 / #3842 | No pairing sidecar in compose → `/pair` 404s (mitigated here) |
| #2935 | Imported nsec may not become the active identity against a self-hosted relay |
| #5197 | Desktop WebSocket ignores the OS trust store; fails silently behind a private CA |
| #3471 | GUI installs a `buzz` wrapper that shadows the real CLI — sends return exit 0 and do nothing |
| #5484 / #3776 | Agent `kind:10100` discoverability quirks; the `buzz` CLI cannot publish that kind |

**iOS has no push notifications** — no APNs entitlement, badge-only authorization, and the NIP-PL
client half is unwritten. Messages arrive only when the app is opened. This is a property of the
software, not of this deployment.
