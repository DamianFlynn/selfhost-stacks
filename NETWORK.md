# Network Infrastructure Map

**Last Updated:** 2026-06-11  
**Network:** 172.16.1.0/24  
**VLAN:** Default (single VLAN currently)

**See also:** [DEVICE-INVENTORY.md](DEVICE-INVENTORY.md) for complete device tables and naming plan
**See also:** [TAILSCALE.md](TAILSCALE.md) for remote access — tailnet topology, the two subnet
routers and their failover, exit nodes, `tsbridge` service publishing, and the recovery runbook

## Core Infrastructure

### Network Gateway
- **Device:** UniFi Cloud Gateway Max (UCG Max)
- **IP:** 172.16.1.1
- **Role:** Router, DHCP Server, Firewall
- **Version:** UniFi OS 5.1.15, Network 10.4.57
- **Access:** SSH enabled, Web UI
- **Credentials:** `UNIFI_USG_SSH_USER` / `UNIFI_USG_SSH_PASS` in `~/.claude/secrets/ha-deercrest.env` — **never in this repo** (public)
- **WAN:** Westnet Broadband (88.81.97.90)
- **DHCP Range:** 83/249 leases active, 162 available
- **Port Forwarding:**
  - Traefik-Ingress: TCP/UDP 443 → 172.16.1.159:443
  - Rustdesk: TCP/UDP 21115-21119 → 172.16.1.159:21115-21119

### WiFi Networks
- **Deer Crest** (Main): WPA2, 2.4GHz + 5GHz, 49 clients
- **Deer Crest Guests**: Open, Main Building (5 APs)

### Remote Access (Tailscale)
Full design and runbook: **[TAILSCALE.md](TAILSCALE.md)**

- **Tailnet:** `pirate-clownfish.ts.net` — MagicDNS on
- **Subnet routers for `172.16.1.0/24`** (two, since 2026-08-25):
  - UCG Max `172.16.1.1` / `100.78.147.125` — **primary**, also an exit node
  - Home Assistant NUC `172.16.1.31` / `100.73.196.51` — **standby**, also an exit node
- **Failover:** automatic, ~30s measured. **Sticky — it does not fail back on its own.**
- **Gotcha:** whichever router is *standby* has its own LAN IP unreachable from the tailnet.
  Use its tailnet address instead. Expected behaviour, self-heals on promotion — see TAILSCALE.md §5.
- **Service publishing:** `tsbridge` on LXC 100 gives nine services their own tailnet nodes
  (`chat`, `code`, `photos`, `search`, `ollama`, …) via compose labels.
- **Why two routers:** on 2026-08-25 a firmware update wiped the gateway's Tailscale and the
  entire LAN route disappeared from the tailnet for 18h — including the route needed to reach
  the gateway and fix it.

## Compute Infrastructure

### Proxmox Cluster
**Host: atlantis** (Minisforum NS5Pro)
- **IP:** 172.16.1.158
- **Hardware:** Minisforum NS5Pro
- **OS:** Proxmox VE 9.1.6
- **SSH:** root@172.16.1.158
- **Containers:**
  - **LXC 100 "selfhost"** (172.16.1.159)
    - Role: Main Docker host for selfhosted services
    - Containers: 78+ Docker containers
    - Stacks: Traefik, Authelia, *arr stack, media, automation
    - Storage: /mnt/fast/stacks, /mnt/fast/appdata
    - Service Account: apps:apps (568:568)
    - GPU: AMD iGPU passthrough (video:44, render:110)
    
  - **LXC 101 "cerebro"** - REMOVED 2026-06-11
    - Decommissioned - AI/memory workload moved to Oracle vault
    - Memories backed up to agent-os/Archives/Projects/Oracle-Agent-Platform/cerebro-notes/cerebro-memories-20260611/

### Home Automation
**Host: Home Assistant** (Intel NUC)
- **IP:** 172.16.1.31
- **Hostname:** a0d7b954-ssh
- **OS:** Home Assistant OS (Linux 6.12.85-haos)
- **SSH:** sysadmin@172.16.1.31
- **Role:** Home automation hub
- **Notes:** Docker not accessible via sysadmin account (runs HA Supervisor)

### Raspberry Pi Hosts

**zgate** (Z-Wave/Zigbee Gateway)
- **IP:** 172.16.1.135 (Fixed)
- **Hostname:** zwave2mqtt
- **Hardware:** Raspberry Pi
- **SSH:** pi@172.16.1.135
- **Role:** Z-Wave and Zigbee gateway
- **Expected Containers:** 2 (zwave2mqtt, zigbee2mqtt)
- **Integration:** WebSocket and/or MQTT to Home Assistant

**cgate** (C-Bus Gateway)
- **IP:** 172.16.1.128 (Dynamic) / 172.16.1.250 (Fixed alias)
- **Hostname:** iot-gate-cbus
- **Hardware:** Raspberry Pi
- **SSH:** pi@172.16.1.128
- **Role:** C-Bus lighting control gateway
- **Expected Containers:** 3
- **Status:** Recently configured/worked on

## Key Network Devices

### Access Points (UniFi)
Multiple APs broadcasting "Deer Crest" SSID across building locations:
- UAP-Kitchen (28 clients)
- UAP-Laundry (15 clients)
- UAP-Bed2 (9 clients)
- UAP-BBQ (3 clients)
- UAP-Cinema (2 clients)

### IoT Devices by Category

**ESPHome Devices** (should be managed via Home Assistant ESPHome integration):
- Multiple ESP32/ESP8266 devices with naming pattern: `esyminiV2-RHID1`, `espressif`, etc.
- Located in various rooms (Kitchen, Laundry, Cinema, Bed2, BBQ)

**Sonos Audio**
- amp-kitchen (SonosZP) - 172.16.1.143
- amp-outside (SonosZP) - 172.16.1.141
- Multiple Sonos speakers distributed across locations

**Cameras (Hikvision + USW)**
- Multiple IP cameras on 172.16.1.222-234 range
- USW-Cameras, USW-Cinema, USW-Closet, USW-Office, USW-Attic

**Smart Home Devices**
- Philips Hue bridge: 172.16.1.28
- Reolink cameras
- LG washer: 172.16.1.183
- Multiple Amazon Echo/Assist devices
- Apple devices (iPhones, iPads, MacBooks, Apple TV, HomePods)
- Google Chromecast devices (stream-*)

**Network Equipment**
- Multiple UniFi switches and access points
- Texas Instruments devices (FPP-K64D)
- Raspberry Pi devices (Raspbian Pi Foundation)
- SiliconDust HDHomeRun (HDHR-12513C2F) - 172.16.1.161

## Device Naming Standards

From the UniFi data, current naming patterns include:
- **Cameras:** `cam-{location}` (cam-backyard, cam-backdoor, cam-frontgate, etc.)
- **Streaming:** `stream-{location}` (stream-basement, stream-cinema, stream-laundry, stream-living)
- **Rooms/Locations:** kitchen, laundry, cinema, bed2, bbq, office, basement, living, sitting
- **IoT Gateways:** `iot-gate-{protocol}` (iot-gate-cbus)
- **ESPHome:** Various (needs standardization)
- **Sonos:** `amp-{location}`, speaker names
- **Assists:** `assist-{location}` (Amazon devices)

## Network Hygiene Issues (To Address)

1. **IP Address Management:**
   - Mix of fixed and dynamic IPs (37 fixed, 48 dynamic)
   - Some devices have multiple IPs (iot-gate-cbus: 128 + 250)
   - 19 offline devices cluttering the table

2. **Naming Inconsistency:**
   - ESPHome devices using auto-generated names
   - Some devices unnamed or showing MAC addresses
   - Inconsistent location naming (Kitchen vs kitchen)

3. **Single VLAN:**
   - Everything on 172.16.1.0/24
   - No segmentation between IoT, infrastructure, user devices, cameras

4. **Device Organization:**
   - Auto-discovered hardware showing incorrect vendor info
   - ESPHome devices should be managed via Home Assistant
   - Offline devices need cleanup

## Suggested VLAN Segmentation (Future)

1. **Management VLAN (10):** 172.16.10.0/24
   - UniFi gateway, switches, APs
   - Proxmox host
   
2. **Server VLAN (20):** 172.16.20.0/24
   - LXC containers (selfhost, cerebro)
   - Home Assistant
   - Pi gateways (zgate, cgate)
   
3. **IoT VLAN (30):** 172.16.30.0/24
   - ESPHome devices
   - Sonos speakers
   - Smart home devices (Hue, switches, sensors)
   
4. **Camera VLAN (40):** 172.16.40.0/24
   - All IP cameras
   - NVR systems
   
5. **User VLAN (50):** 172.16.50.0/24
   - Phones, tablets, laptops
   - Apple devices
   - Guest WiFi isolated

## Quick Reference

### SSH Access Summary
| Host | IP | User | Purpose |
|------|-------|------|---------|
| atlantis (Proxmox) | 172.16.1.158 | root | Virtualization host |
| selfhost | 172.16.1.159 | root | Docker services |
| cerebro | 172.16.1.160 | root | AI workloads |
| Home Assistant | 172.16.1.31 | sysadmin | Home automation |
| zgate | 172.16.1.135 | pi | Z-Wave/Zigbee |
| cgate | 172.16.1.128 | pi | C-Bus gateway |
| UCG Max | 172.16.1.1 | - | Network gateway |

### Host-level services on LXC 100 (NOT Docker, NOT in `stacks/`)

These run as **systemd services directly on the selfhost LXC**, so they do not appear in any
compose file and `docker ps` will not show them. They still consume host ports — check here before
assigning a new host port, or a container will fail to start.

**Pulse** — Proxmox/Docker monitoring (`/opt/pulse`, v6.2.1, installed 2026-03-10)

| Unit | Listens | Purpose |
|------|---------|---------|
| `pulse.service` | `*:7655` | Pulse server / web UI |
| `pulse.service` | `127.0.0.1:9091` | internal |
| `pulse-agent.service` | **`127.0.0.1:9191`** | agent health/metrics (`-health-addr`, empty disables) |

The agent reports to `http://172.16.1.159:7655` with `--enable-host --enable-docker
--enable-commands`, which is what provides host and container metrics. It self-updates via
`pulse-auto-update.sh` + `pulse-update.timer`, so its version moves independently of this repo.

⚠️ **`pulse-agent` owning 9191 silently blocked dispatcharr for ~6 weeks** (2026-06-30 →
2026-08-11): the container sat in `created` state, never started, failing with `address already in
use`. dispatcharr now publishes on host port **9192**. Do not reassign 9191.

> Note: `docker ps` alone hides this class of failure — a container stuck in `created` is not
> `running`, but is also not `exited`, `dead` or `restarting`. Use
> `docker ps -a --format '{{.State}}' | sort | uniq -c` for a true census.

### Services by Host
- **selfhost (159):** Traefik, Authelia, Sonarr, Radarr, Lidarr, Prowlarr, qBittorrent, Grafana, Dawarich, Open WebUI, Ollama, Immich, FreshRSS, and 60+ others — plus host-level Pulse (above)
- **cerebro (160):** Qdrant, Redis, SearXNG
- **Home Assistant (31):** Home Assistant Core + addons
- **zgate (135):** Z-Wave2MQTT, Zigbee2MQTT
- **cgate (128):** C-Bus integration (3 containers)

### Port Forwards
- **443** → 172.16.1.159:443 (Traefik ingress)
- **21115-21119** → 172.16.1.159:21115-21119 (Rustdesk)

### Notable host ports on 172.16.1.159 (LXC 100)
| Port | Owner | Notes |
|------|-------|-------|
| 7655 | `pulse.service` | Pulse web UI (host service, not Docker) |
| 9091 | `pulse.service` | internal, localhost only |
| **9191** | **`pulse-agent.service`** | **reserved — do not reassign** (see above) |
| 9192 | dispatcharr (Docker) | → container 9191. Localhost only in practice (macvlan asymmetric routing) — **not** the Jellyfin endpoint; use `172.16.1.75:9191` |
| 8084 | sabnzbd (Docker) | |
| 18080 | podsync (Docker) | |

### TV / tuner chain
HDHomeRun (**172.16.1.161**) + IPTV streams → **dispatcharr** → two independent consumers:

| Consumer | Path | Protocol |
|---|---|---|
| Jellyfin (Deer Crest) | `172.16.1.75:9191/hdhr` + `/output/epg` | HDHR tuner + XMLTV |
| TiviMate (Fosse Road TV) | `172.16.1.75:9191` over **Tailscale** | Xtream Codes (`fosse-tv`) |

Jellyfin is for the media library; **TiviMate is the live-TV client**. Jellyfin's Live TV path
adds ~7.7s to every channel change (3s ffprobe + 3s HLS segment build + ~1s tuner connect) and
that is inherent to how it does Live TV — not tunable. TiviMate plays the MPEG-TS natively and
switches in roughly the ~1.1s dispatcharr actually needs. Since 2026-08-14 the physical
HDHomeRun is **no longer a direct Jellyfin tuner** — dispatcharr is the single source.

**Use the macvlan address — `http://172.16.1.75:9191`.** Both dispatcharr and Jellyfin sit on
`iot_macvlan` with real LAN IPs (dispatcharr `172.16.1.75`, Jellyfin `172.16.1.76`), and dispatcharr
advertises that address itself:

```json
{"FriendlyName": "Dispatcharr HDHomeRun", "BaseURL": "http://172.16.1.75:9191/hdhr",
 "LineupURL": "http://172.16.1.75:9191/hdhr/lineup.json"}
```

Verified from inside the Jellyfin container: `172.16.1.75:9191` → 200, and `/hdhr/discover.json`
returns valid HDHomeRun JSON. `http://dispatcharr:9191` also works (shared `t3_proxy`).

#### Off-LAN clients (Fosse Road)

`tv.deercrest.info` is a **second Traefik router with no authelia**, allow-listing only the XC
paths (`/player_api.php`, `/panel_api.php`, `/get.php`, `/xmltv.php`, `/live/`, `/timeshift/`,
`/streaming/`, `/api/channels/logos/`) plus a 30/min rate limit. Everything else on that host
404s. It is the **one grey-cloud record** in the estate — Cloudflare's proxy breaks long-lived
MPEG-TS — so it publishes the origin IP. It exists only as a fallback; the TV normally reaches
dispatcharr over Tailscale and this route can be retired.

dispatcharr's own `network_access` ACLs are the second layer, and they are effective because
`get_client_ip` trusts `X-Forwarded-For` from private-range proxies (Traefik), so the **real**
client IP is evaluated:

| Key | Value | Why |
|---|---|---|
| `M3U_EPG` | private ranges **+ `100.64.0.0/10`** | `/output/*` has no auth of its own. The Tailscale CGNAT range must be listed explicitly or tailnet clients get 403 |
| `XC_API` / `STREAMS` | `0.0.0.0/0` | needed by the off-LAN TV; auth is the XC credential |
| `UI` | `0.0.0.0/0` | do **not** restrict to LAN — it would lock out remote admin via the Traefik route |

Do **not** use:
- `dispatcharr.deercrest.info` — the Traefik route carries `chain-authelia@file` and would bounce a
  tuner client to a login page.
- `172.16.1.159:9192` (the host publish) — it answers on `127.0.0.1` from inside the LXC but **fails
  from other hosts**. dispatcharr's default route goes out its macvlan interface, so replies to the
  docker-proxy path are asymmetric and get dropped. The publish exists only as a legacy of the
  original config; the macvlan address is the real endpoint.

#### RESOLVED: the 2026-08-14 Fosse Road freezes were `stream_limit`, not the aerial

Symptom was 6–10s picture freezes every ~15–40 min on the remote TV, on **both** aerial and IPTV
channels. Root cause was a **conflation of two different limits**:

| Setting | Governs |
|---|---|
| `M3UAccount.max_streams` | concurrent **upstream provider** connections |
| `User.stream_limit` | concurrent **dispatcharr clients** for that user |

`stream_limit: 1` had been set on the `fosse-tv` XC user to "mirror" account 7's `max_streams: 1`.
TiviMate renews its connection every ~15–40 min, and for a fraction of a second the old and new
clients coexist — tripping 1/1 and making dispatcharr force-terminate the **live** client:

```
WARNING proxy [stream limits] User fosse-tv (ID: 2) has reached stream limit (1/1 streams)
INFO    proxy [stream limits] Terminating client ... (connected_at=...)
```

**14 terminations in one evening.** Fixed by raising `stream_limit` to **2**, which permits the
reconnect overlap. This does *not* consume a second provider slot — clients on the same channel
share one upstream connection. Result: 14 → **0**, and a 40+ minute unbroken session, well past the
previous failure interval.

> **`channel_shutdown_delay` must stay `0` here.** It was briefly raised to 5 to stop the resulting
> cold-start race — but that race was *triggered* by the `stream_limit` terminations, not by the
> delay. With the real cause fixed, a non-zero delay prevents nothing and actively breaks channel
> changes: it holds the old channel's upstream open, so switching between two IPTV channels hits
> `max_streams: 1` and returns HTTP 503 (observed BBC One → ITV1, 5.5s to recover). `0` is correct
> for this estate **because** the provider allows only one stream.

##### Residual IPTV channel-switch latency is the SUBSCRIPTION, not config — stop tuning

With `stream_limit: 2` and `channel_shutdown_delay: 0` in place, measured switching between two
DigitalIPTV channels:

```
22:50:10 → 22:50:13.594   2.7s   clean
22:54:20 → 22:54:22.796   2.0s   clean
22:53:46 → 22:53:54.994   8.6s   3 attempts, 2x HTTP 503
```

The slow case is **not** a dispatcharr setting. TiviMate holds the old connection open while it
opens the new one, so for a few seconds two distinct IPTV channels are live — which account 7's
`max_streams: 1` forbids. It 503s until the old connection lets go. Sometimes the old one drops
first (2s), sometimes it doesn't (8.6s).

**Do not go re-tuning `channel_shutdown_delay`, buffer sizes or timeouts to chase this** — that loop
was already run once on 2026-08-14 and it made things worse. The only real fix is a provider plan
with `max_streams >= 2`, which would also allow simultaneous viewing at Deer Crest and Fosse Road
(currently impossible on anything IPTV-sourced). Subscription runs to **2026-12-29**.

Aerial channels 1–10 are unaffected — the HDHomeRun has 4 tuners.

**Diagnostic lesson:** the aerial was initially blamed, on a differential of RTÉ One (aerial)
freezing while France 24 and BBC One (IPTV) were clean. That comparison was **confounded** —
`channel_shutdown_delay` was changed between the two sets of observations, so a config difference
was read as a source difference. BBC One later froze too, disproving it. Never compare observations
taken either side of your own change.

#### Latent: aerial signal is unstable (measured 2026-08-14, no symptom attributed)

Separate, unresolved, and **not currently causing anything**. 90 samples of
`http://172.16.1.161/status.json`, 10s apart, tuned to RTÉ One:

```
signal strength :  100%  on ALL 90 samples — pegged, never varies
signal quality  :  degraded on 48/90 (53%), floor 59%, in ~60–90s bursts
symbol quality  :  100%  on ALL 90 samples — ZERO uncorrected errors
```

Symbol quality never broke, so error correction absorbed every dip — consistent with the aerial
having caused none of the freezes above. Strength pegged at 100% while quality collapses is still
abnormal ("strong but dirty"), and the aerial is a small **powered** antenna in the attic, so
amplifier overdrive of the tuner front-end remains the best explanation. HDHomeRun's sweet spot is
~75–85% strength.

**Do not act on this alone.** If it ever becomes symptomatic, the smoking gun is
`SymbolQualityPercent` **< 100** coincident with an on-screen freeze — poll at 1–2s, not 10s.

**Fix requires attic access — LESS gain, not more.** Add a 6–10 dB inline attenuator or bypass the
amplifier; then check connectors for corrosion and look for impulse noise (switch-mode PSUs, LED
lighting) near the run. Do **not** reposition the aerial or add amplification.

> `status.json` returns only `{"Resource": "tunerN"}` when idle — signal fields appear **only while
> a tuner is locked**, so hold a stream open first or the output looks empty.

---

## Maintenance Tasks

### TV chain — open items (revisit ~2026-08-28, needs physical access)
- [ ] **Aerial — LOW priority, do not act without a symptom.** The freezes turned out to be
      `stream_limit`, not the aerial. The measured instability (strength railed at 100%, quality
      dipping to 59%) is latent and caused nothing observable. If a freeze ever survives on an
      aerial channel *only*, capture it at 1–2s polling first — `SymbolQualityPercent` < 100 is the
      smoking gun — and only then consider a 6–10 dB attenuator (less gain, never more).
- [ ] **Retire `tv.deercrest.info`** — built as a fallback before Tailscale worked; now redundant
      since TiviMate reaches dispatcharr over the tailnet. It is the estate's only grey-cloud
      record, so it publishes the origin IP. Delete the A record, drop the `dispatcharr-tv` router
      labels, and return `XC_API`/`STREAMS` to private ranges **plus `100.64.0.0/10`** (omitting the
      Tailscale range would cut off the TV).
- [ ] **Fix `deinterlace_vaapi` on the Radeon 890M** — ffmpeg exits 251 whenever a Jellyfin client
      forces a re-encode of an interlaced-flagged Live TV stream. Native clients direct-play and are
      unaffected, but **DVR recordings will hit it**.

### Immediate Cleanup
- [ ] Remove 19 offline devices from UniFi
- [ ] Standardize ESPHome device naming
- [ ] Convert dynamic IPs to fixed for infrastructure
- [ ] Verify/correct auto-discovered hardware vendors
- [ ] Consolidate duplicate device entries (e.g., iot-gate-cbus)

### Future Network Improvements
- [ ] Implement VLAN segmentation
- [ ] Create firewall rules between VLANs
- [ ] Set up IoT isolation with Home Assistant allowed access
- [ ] Migrate devices to appropriate VLANs
- [ ] Create guest WiFi on isolated VLAN
- [ ] Document camera VLAN and NVR access patterns
