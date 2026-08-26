# Tailscale — Configuration and Low-Level Design

How the Deer Crest estate is reached from outside the LAN, and how nine services are published
to the tailnet. Companion to [NETWORK.md](NETWORK.md).

**State captured:** 2026-08-26, from live `tailscale status --json`, the gateway's systemd units,
the Home Assistant add-on config, and the compose files in `stacks/`. Every IP, version and path
below was observed, not assumed.

---

## 1. Tailnet identity

| | |
|---|---|
| Tailnet | `pirate-clownfish.ts.net` |
| Owner | the Deer Crest Google account (see `~/.claude/secrets/`) |
| CGNAT range | `100.64.0.0/10` |
| LAN advertised | `172.16.1.0/24` (Deer Crest) |
| Also advertised | `192.168.8.0/24` (Fosse Road, `gl-mt3000`, **offline since Jun 13**) |

MagicDNS is on: nodes resolve by short name (`homeassistant`, `code`, `photos`).

**Two identity classes**, and the difference is operationally significant:

- **Tagged nodes** (`tag:server`, and the console's `tagged-devices` grouping) — owned by an ACL
  tag rather than a user. **Tagged node keys never expire.**
- **User-owned nodes** — keys expire (default ~6 months) and the node silently drops off the
  tailnet. Anything load-bearing must either be tagged or have **expiry disabled** explicitly.

---

## 2. Topology

```
                         Internet
                             │
        ┌────────────────────┴─────────────────────┐
        │                                          │
   Fosse Road (remote)                     Deer Crest 172.16.1.0/24
   SMARTY SIM → gl-mt3000                          │
   ~7–8 Mbps ceiling                    ┌──────────┴───────────┐
        │                               │                      │
   TiviMate / clients            UCG-Max 172.16.1.1      NUC / HAOS 172.16.1.31
        │                        100.78.147.125          100.73.196.51
        │                        ┌──────────────┐        ┌──────────────┐
        └───── tailnet ──────────┤ subnet router│        │ subnet router│
                                 │  PRIMARY     │        │  STANDBY     │
                                 │  exit node   │        │  exit node   │
                                 └──────────────┘        └──────────────┘
                                        │
                                 LXC 100 selfhost 172.16.1.159
                                 ┌──────────────────────────┐
                                 │ tsbridge → 9 tailnet      │
                                 │ nodes (chat, code, …)     │
                                 └──────────────────────────┘
```

Both routers advertise `172.16.1.0/24`. Only one carries traffic at a time — see §5.

---

## 3. The four deployment patterns

Tailscale is installed four different ways here. This is not accidental sprawl; each pattern
solves a problem the others cannot. Knowing which pattern a node uses determines how you fix it.

| # | Pattern | Where | Managed by |
|---|---|---|---|
| 1 | `tailscale-udm` community install | UCG-Max gateway | systemd units in `/data/tailscale/` |
| 2 | HAOS add-on | NUC / Home Assistant | Supervisor add-on config |
| 3 | `tsbridge` OAuth per-service nodes | LXC 100 | compose labels in `stacks/` |
| 4 | Stock clients | Macs, iOS, TVs | the Tailscale app |

### Pattern 1 — Gateway (`tailscale-udm`)

UniFi OS has no native Tailscale, so this is the community installer.

| | |
|---|---|
| Host | `Cloud-Gateway-Max`, UniFi OS 5.1.15, kernel `5.4.213-ui-ipq5322`, aarch64, ~2.9 GB RAM |
| Tailscale | 1.102.3 |
| Root | `/data/tailscale/` — `manage.sh`, `tailscale-env`, `tailscaled.state` |
| Boot hook | `/data/on_boot.d/10-tailscaled.sh` |
| Units | `tailscale-install.service` + `.timer`, symlinked into `/etc/systemd/system/` |
| Role | Subnet router (`172.16.1.0/24`) **+ exit node**, tagged |
| SNAT | **disabled** — see §6 |

**The critical property: `/data` survives a firmware upgrade, the root filesystem does not.**
The `tailscale` apt package is wiped by every firmware update, so `tailscale-install.service`
reinstalls it on each boot. `manage.sh` only ever re-creates the `/etc/systemd/system/` *symlink*
— it never rewrites the unit contents — so local edits to the unit persist across upgrades.

Prefs (exit node, advertised routes) live in `tailscaled.state`, so a reinstall restores the
node's role with **no re-authentication**.

### Pattern 2 — Home Assistant add-on (the NUC)

| | |
|---|---|
| Host | Intel NUC, HAOS, kernel `6.18.37-haos`, `172.16.1.31` |
| Add-on | `a0d7b954_tailscale` 0.29.0 (Community Add-ons repo, already registered) |
| Node | `homeassistant` / `100.73.196.51` |
| Role | Subnet router (**standby**) + exit node |
| Boot | `auto` |

Non-default options, and why each was chosen:

| Option | Value | Rationale |
|---|---|---|
| `advertise_routes` | `["172.16.1.0/24"]` | the second path into the LAN |
| `advertise_exit_node` | `true` | redundancy for the exit node that failed |
| `accept_routes` | `false` | **critical** — the gateway advertises HA's *own* subnet; accepting it risks blackholing HA's LAN traffic |
| `accept_dns` | `false` | keeps MagicDNS out of the appliance's resolver |
| `snat_subnet_routes` | `true` | without it, LAN hosts need their own route back to `100.64.0.0/10` |
| `userspace_networking` | `false` | kernel networking is required for subnet routing |

Key expiry is **disabled** on this node — it is user-owned and untagged, so without that the
backup router would quietly die in ~6 months.

### Pattern 3 — `tsbridge` (per-service nodes on LXC 100)

Defined in [`stacks/selfhosted/traefik/tsproxy.yaml`](stacks/selfhosted/traefik/tsproxy.yaml).

| | |
|---|---|
| Image | `ghcr.io/jtdowney/tsbridge:v0.15.0` |
| Auth | Tailscale **OAuth client** (`TS_OAUTH_CLIENT_ID` / `_SECRET`) |
| Default tags | `tag:server` — must be owned by the OAuth client |
| State | `/mnt/fast/appdata/traefik/tsbridge` |
| Discovery | Docker socket + container labels |

Each labelled container becomes **its own tailnet node** with its own IP — not a port on a shared
host. Opt in with three labels:

```yaml
labels:
  - "tsbridge.enabled=true"
  - "tsbridge.service.name=chat"     # becomes the tailnet hostname
  - "tsbridge.service.port=8080"     # port inside the container
```

Current nodes:

| Node | Stack | Port |
|---|---|---|
| `chat` | `openwebui` | 8080 |
| `search` | `openwebui` | 8080 |
| `ollama` | `openwebui` | 11434 |
| `docling` | `openwebui` | 5001 |
| `mcp` | `openwebui` | 8000 |
| `photos` | `immich` | 2283 |
| `code` | `code-server` | 8443 |
| `mc_vanilla` / `mc_yggdrasil` | `minecraft` | 19132 |

Nine services in total. (`tsproxy.yaml` mentions `tsbridge.enabled=true` in its header comment
as documentation — that is not a service definition, and `whoami` is a stale node, not a current
one.) `mcp` is defined but its node has been offline for ~7 days — worth checking the container.

Because these are tagged (`tag:server`), their keys never expire — which is why `chat`, `code`
and `docling` show "Expiry disabled" in the console while `homeassistant` had to be set manually.

> **Note:** several stale duplicates exist from earlier naming (`mc-vanilla` vs `mc_vanilla`,
> `mc-ygg`, `minecraft`, `whoami` — all long offline). Cleanup is listed in §9.

### Pattern 4 — Stock clients

`DATAs-Mac-mini` (`100.115.47.23`), `Living room TV`, iPads, iPhone, Apple TV, laptops.

One detail that matters: **`DATAs-Mac-mini` runs the standalone (`macsys`) build, not the Mac App
Store build.** Only the standalone build can advertise subnet routes or act as an exit node — the
App Store build is sandboxed and cannot. It is also set never to sleep (`sleep 0`, `standby 0`),
which is why it stays reachable and makes a viable emergency jump host (§7).

**Shared in from another tailnet** (`keith.flynn@`, `bicolor-vibes.ts.net`):
`homeassistant.bicolor-vibes.ts.net`, `posca.bicolor-vibes.ts.net`. These are *not* Deer Crest
machines — do not confuse `homeassistant.bicolor-vibes.ts.net` with the local `homeassistant`.

---

## 4. Exit nodes

Two are offered: `cloud-gateway-max` and `homeassistant`. Exit-node use is opt-in **per client**
(`tailscale set --exit-node=…`); adding a second one does not change any client automatically.

---

## 5. Subnet routing and failover

Both routers advertise `172.16.1.0/24`. Tailscale elects **one primary**; the other stands by.

- The primary carries the route in its `AllowedIPs`; the standby's is empty.
- Failover is automatic. **Measured: ~30 s** (2026-08-25 test — gateway `tailscaled` stopped, HA
  promoted, all five LAN hosts reachable, live SSH session restored).
- **Election is sticky — it does NOT fail back.** After the gateway returns it stays *standby*
  until something displaces HA. Restarting HA's add-on hands primary back (~15 s).
- **The gateway should be primary** in steady state: it is the natural router, and `172.16.1.1`
  is the UniFi console.

Check who holds it:

```bash
tailscale status --json | jq -r '.Peer[] | select(.PrimaryRoutes) | "\(.HostName) \(.PrimaryRoutes)"'
```

### The standby LAN-IP behaviour — expected, not a fault

**Whichever router is currently standby has its own LAN IP unreachable from the tailnet.**

The request reaches it via the primary, but the standby routes the *reply* out `tailscale0`
sourced from its LAN IP — an address not in that peer's `AllowedIPs` — so the client's WireGuard
drops it. Confirm with `ip route get <client-tailnet-ip>` on the standby: it returns
`dev tailscale0 table 52`.

It flips with the roles. While HA was primary, `172.16.1.1` was the unreachable one.

- **It self-heals on promotion** — the moment a standby becomes primary, its LAN IP works again.
- **Workaround: use the node's tailnet address**, which is better anyway — direct peer-to-peer,
  independent of which router is primary, and still working when the gateway is down.
  HA: `100.73.196.51` or MagicDNS `homeassistant`. Gateway: `100.78.147.125`.
- This is **not** Tailscale's anti-spoof netfilter rule. `DATAs-Mac-mini` runs Tailscale on the
  same LAN and stays reachable throughout — only the *advertising standby* is affected.

---

## 6. Known asymmetry: SNAT differs between the two routers

| Router | `snat_subnet_routes` | LAN hosts see traffic from |
|---|---|---|
| UCG-Max | **disabled** | the real tailnet client IP (`100.64.0.0/10`) |
| Home Assistant | **enabled** | `172.16.1.31` |

So **the apparent source IP of tailnet traffic changes depending on which router is primary.**
Anything that filters on source IP must tolerate both. The known case is dispatcharr's `M3U_EPG`
ACL, which lists `100.64.0.0/10` *and* the private ranges, so it survives either — but a
future source-IP rule could easily be written to work only in the common case and fail during
a failover. The gateway also reports a standing health warning
(`snat-subnet-routes is disabled while advertising as an exit node`); it is pre-existing and has
not affected exit-node or LAN access.

---

## 7. Failure modes

### 7.1 Firmware update kills the gateway client (**happened 2026-08-25**)

Firmware wipes the `tailscale` package; `tailscale-install.service` reinstalls at boot and
**failed twice**:

- `03:20:16` — boot run: `E: Unable to locate package tailscale` (repo not configured yet)
- `03:23:54` — timer retry: began installing, then **`Killed`, `status=137`** — OOM killer, on a
  2.9 GB box with every UniFi service starting at once
- Then nothing for **18 hours**, because `tailscale-install.timer` only retries **daily**

**Mitigation applied** (`/data/tailscale/tailscale-install.service`, original kept as `.bak`):

```ini
[Unit]
StartLimitIntervalSec=1h
StartLimitBurst=5

[Service]
Restart=on-failure
RestartSec=120
```

The rate limit is the point. Bare `Restart=on-failure` would retry forever — and where the
install genuinely cannot succeed (a major UniFi OS release needing a new `tailscale-udm` script,
which has happened before) that means endless apt runs spiking memory on a small box. Capped, it
tries 5 times over ~8 min then stops, leaving the same end state as before. The 1 h window is
deliberately shorter than the timer's 24 h cycle so the daily retry is never blocked.

> **Verified, contrary to common belief:** `Restart=on-failure` *is* legal on `Type=oneshot`
> (systemd 247). Only `always` and `on-success` are refused.

Deliberately **not** applied: `OOMScoreAdjust=-500`. It would spare apt only by making some other
process the OOM victim during the boot storm — possibly a UniFi service.

### 7.2 Single subnet router was a SPOF — now mitigated

Until 2026-08-25 the gateway was the **only** advertiser of `172.16.1.0/24`. When its Tailscale
died, the whole LAN route vanished from the tailnet — including the route needed to reach the
gateway and fix it. Remote services stayed up (Traefik/Cloudflare is a separate path), which made
it look like a client-only problem rather than an outage.

HA now provides the second path. **Residual risk:** both routers still sit on the same physical
site and power feed.

### 7.3 Key expiry on untagged nodes

A user-owned node's key expires (~6 months) and it silently leaves the tailnet. For a *backup*
router this is the worst failure: discovered only when the primary dies. `homeassistant` has
expiry disabled; `tag:server` nodes are immune.

### 7.4 Failover disrupts single-stream IPTV

Fosse Road TiviMate streams via dispatcharr on a `max_streams=1` account. A failover blip kills
the stream and dispatcharr can keep a **ghost session** holding the only slot — every retune then
returns **503** (`Profile 7 at max connections: 1/1`). Killing the `ffmpeg` process does **not**
clear it (the count lives in dispatcharr's own accounting); `docker restart dispatcharr` does.

**Do not run failover tests while someone is watching TV.**

---

## 8. Runbook

### Gateway Tailscale is dead / LAN unreachable over tailnet

The gateway may be unreachable at `172.16.1.1` precisely because its Tailscale is down. Get in
via an independent LAN node:

```bash
ssh -J data@datas-mac-mini root@172.16.1.1     # SSH user is 'data'; gateway prompts for password
```

Gateway root password: `UNIFI_USG_SSH_PASS` in `~/.claude/secrets/ha-deercrest.env`.

```bash
systemctl status tailscale-install.service     # look for status=137 (OOM) or apt errors
free -m                                        # needs a few hundred MB free
systemctl reset-failed tailscale-install.service
systemctl start --no-block tailscale-install.service   # --no-block: survives a dropped SSH session
```

`tailscaled.service` is *created by* the install service, so it goes `not-found` → `active` on its
own. Prefs restore from `tailscaled.state` — no re-auth needed. Takes ~60 s.

### Verify after any change

```bash
tailscale status | grep -E 'cloud-gateway-max|homeassistant'
tailscale exit-node list
for h in 172.16.1.1 172.16.1.31 172.16.1.158 172.16.1.159; do ping -c1 -W2000 $h; done
```

Confirm the **exit-node flag and the LAN route separately** — the flag alone does not prove the
subnet route came back.

### Fail back to the gateway after a failover

```bash
ssh <ha> 'bash -lc "ha apps restart a0d7b954_tailscale"'   # ~15 s, gateway reclaims primary
```

### Adding a service to the tailnet

Add the three `tsbridge.*` labels (§3) and `docker compose up -d`. tsbridge creates the node via
OAuth; no manual auth, no console approval. Approval is only needed for **subnet routes and exit
nodes**, which must be ticked separately.

### Onboarding a new subnet router

1. Install Tailscale, advertise `172.16.1.0/24`
2. Approve the route in the console (**and** the exit node, if offered — separate tick)
3. **Disable key expiry**, or tag it
4. Expect the standby LAN-IP behaviour (§5) — use its tailnet address
5. Test failover **when nobody is watching TV** (§7.4)

---

## 9. Open items

- [ ] `gl-mt3000` (Fosse Road, `192.168.8.0/24`) offline since **Jun 13** — its subnet route is
      dead; decide whether to restore or remove the advertisement
- [ ] Stale duplicate nodes: `mc-vanilla`, `mc-ygg`, `minecraft`, `whoami`,
      `p-fr1smtp-host01`, `apple-tv` (last seen 2025) — remove from the console
- [ ] Untested: whether the hardened install unit actually recovers a **real** firmware reboot.
      Only the next UniFi OS update proves it
- [ ] Consider tagging `homeassistant` to match the other infrastructure nodes, rather than
      relying on expiry-disabled
- [ ] Both subnet routers share a site and power feed — an off-site router would cover that
