# Media Stack — Low-Level Design

Jellyfin and the services around it: what runs where, which filesystem every byte lands on, how
Live TV is wired, and the constraints that are deliberate rather than accidental.

Companion to [NETWORK.md](NETWORK.md) (addressing) and [TAILSCALE.md](TAILSCALE.md) (remote access).
Storage conventions live in [STANDARDS.md](STANDARDS.md).

**All figures verified live against `atlantis` (172.16.1.158) and LXC 100 (172.16.1.159) on
2026-09-03.** Where a claim is inherited rather than measured, it says so.

---

## 1. Services

Stack root: `stacks/selfhosted/media/`. `compose.yaml` is an `include:` aggregator — each service
has its own file, and `name: media` is the compose project.

| Service | Image (live) | Hostname | Role |
|---------|--------------|----------|------|
| **jellyfin** | `jellyfin/jellyfin:10.11.11` | `jellyfin.deercrest.info` | Media server — the library |
| **dispatcharr** | `ghcr.io/dispatcharr/dispatcharr:0.29.0` | `dispatcharr.deercrest.info`, `tv.deercrest.info` | IPTV/tuner aggregator — Live TV |
| **jellystat** | `cyfershepard/jellystat:1.1.11` | `jellystats.deercrest.info` | Playback analytics |
| **jellystat-db** | `postgres:18-alpine` | — | Jellystat's database |
| **seerr** | `ghcr.io/seerr-team/seerr:v3.4.1` | `requests.deercrest.info` | Request management |
| **wizarr** | `ghcr.io/wizarrrr/wizarr:v2026.7.1` | `invite.deercrest.info` | User invitations |
| **audiobookshelf** | `ghcr.io/advplyr/audiobookshelf:2.36.0` | `audiobooks.deercrest.info` | Audiobooks + podcasts |

All seven run in the `media` compose project (`docker ps --filter label=com.docker.compose.project=media`),
all `running` as of 2026-09-03. Note the container is named **`seerr`**, not `jellyseerr` — a grep
for the latter finds nothing.

The **arrs** (`stacks/selfhosted/arrs/`) are a separate stack but share the storage layout below:
`sonarr`, `radarr`, `lidarr`, `bazarr`, `prowlarr`, `sabnzbd`, `qbittorrent`, each with an
`exportarr` metrics sidecar.

---

## 2. Networks

Two external networks, both defined outside this stack:

| Network | Purpose |
|---------|---------|
| `t3_proxy` | Traefik reverse proxy — every service with a `*.deercrest.info` hostname |
| `iot_macvlan` | Real LAN addresses. **Only two containers in the entire estate are on it.** |

```
iot_macvlan members (verified):
  jellyfin     172.16.1.76
  dispatcharr  172.16.1.75
```

### ⚠️ macvlan is an exposure, and it is easy to misread

A macvlan container holds a **first-class LAN address**. `172.16.1.76:8096` is reachable from all
of `172.16.1.0/24` and, via the two subnet routers, from the tailnet.

Two consequences that have already caused a documented error:

1. **`ports:` in the compose file is inert under macvlan.** Jellyfin publishes no host port on
   `172.16.1.159`, and `ss -tlnp` there shows nothing on `8096`/`8920`. That is *not* a security
   control — the macvlan address is the exposure, and it bypasses Traefik and Authelia entirely.
2. **The Docker host cannot reach its own macvlan containers.** `curl http://172.16.1.76:8096/health`
   returns **200** from the workstation and from atlantis, and **fails with exit 7 from LXC 100**.
   This is macvlan host isolation and it is normal. It is why
   `scripts/check-jellyfin-transcode.sh` resolves Jellyfin's address via `docker inspect` rather
   than hard-coding one.

> **Historical note, kept because it is the failure to watch for.** Until 2026-09-03 several scripts
> and `.planning/PROJECT.md` claimed Jellyfin was *"reachable only from a host that can route to its
> `t3_proxy` address"*, and used that as the last compensating control for an
> **administrator-equivalent Jellyfin API key**. Measurement showed it false. If that sentence
> reappears, it is a regression, not a rediscovery.

---

## 3. Storage — which filesystem every byte lands on

Three distinct backing stores. Getting these confused is how `/` was emptied once already.

| Path | Backing | Purpose |
|------|---------|---------|
| `/mnt/tank/media` | `tank/media` (9 T) | The library |
| `/mnt/tank/downloads` | `tank/downloads` | Download staging |
| `/mnt/fast/appdata/media` | `fast/appdata/media` | Media app config/state |
| `/mnt/fast/appdata/arrs` | `fast/appdata/arrs` | Arr config/state |
| `/mnt/fast/transcode` | `fast/transcode` — **50 G quota** | Jellyfin transcode scratch |

`/mnt/tank/media` has a **per-library child dataset**: `tank/media/{Books,Movies,Music,Photos,TV}`.

### ⚠️ `/mnt/fast` and `/mnt/fast/appdata` are NOT mountpoints

This is the single most load-bearing storage fact in this document, and it is invisible to `df`.

Inside LXC 100, `/` is **ext4 on `pve-vm--100--disk--0` (126 G)**. `/mnt/fast` and
`/mnt/fast/appdata` are **plain directories on that ext4 root**. Only the *children* are ZFS
datasets, mounted individually.

**A path under `/mnt/fast/appdata/<name>` where `<name>` has no dataset is on `/`.** It looks
identical to one that isn't.

```bash
# The reliable test — df LIES here, reporting /'s figures for non-mountpoints:
mountpoint -q /mnt/fast/appdata/<name> && echo "ZFS dataset" || echo "ON / — unbounded"

findmnt -no TARGET,SOURCE,FSTYPE | grep /mnt/fast   # authoritative
```

`df /mnt/fast/appdata` reports `126G ... 72%` — the root disk's numbers — while `du` reports
**170 G** of content. Both are "right"; the discrepancy is the tell that it is not a mountpoint.

### Jellyfin's mounts (verified)

| Host path | Container | Mode | Notes |
|-----------|-----------|------|-------|
| `/mnt/fast/appdata/media/jellyfin` | `/config` | rw | config, metadata, DB |
| `/mnt/tank/media` | `/media` | **rw** | broad and read-write **on purpose** — D-21 |
| `/mnt/fast/transcode` | `/cache/transcodes` | rw | the quota'd dataset |
| `/mnt/fast/appdata/media/jellyfin/cache` | `/cache` | rw | general cache |
| `/etc/localtime` | `/etc/localtime` | ro | |

**Anonymous volume count must be zero.** `check-jellyfin-transcode.sh` asserts
`volume mounts: 0`. Jellyfin's image declares `VOLUME` paths; any one not explicitly bound gets an
anonymous volume under `/var/lib/docker/volumes` — i.e. on `/`. That is exactly how 19 GB of
transcode cache emptied the root filesystem mid-Phase-3.

### Who can write to the library

Deliberately asymmetric (D-19 narrowing, D-21 carve-out). **Note `lidarr`: broad but read-only —
that reads like a writer at a glance and is not one.**

| Container | Mount | RW |
|-----------|-------|-----|
| `jellyfin` | `/mnt/tank/media` (all) | **true** — sole rw holder on Music (D-21) |
| `lidarr` | `/mnt/tank/media` (all) | **false** |
| `sonarr` | `/mnt/tank/media/TV` | true |
| `radarr` | `/mnt/tank/media/Movies` | true |
| `bazarr` | `Movies` + `TV` | true |

Jellyfin is **consumer-class**, not tagger-class, and is excluded from the WRIT-01 tagger count.
Its writing is disabled at the *application* layer, not the mount: `SaveLocalMetadata`, real-time
monitoring and `SaveLyricsWithMedia` are off for the Music library permanently.

> The freeze gates the **automatic** save path only. An explicit "Refresh metadata" (`FullRefresh`)
> still writes — and did rewrite 83 of 91 `.nfo` when tested. Never stage untagged content under
> `/media/Music`.

`scripts/check-music-freeze.sh` asserts this and reports Jellyfin by name as
`consumer-class writers: 1 (documented exception, D-21)` rather than as a bare count, because a
count of one otherwise reads as a failure.

---

## 4. Transcoding

### Hardware acceleration is OFF, deliberately

```
HardwareAccelerationType : none
EnableHardwareEncoding   : false
```

`/dev/dri` **is** mapped into the container and the Radeon 890M **is** capable — Jellyfin simply
does not use it. Everything transcodes on CPU via `libx264`. **High CPU during a transcode is
correct behaviour, not a fault.**

This is the **D-30 amdgpu mitigation**, applied 2026-08-31 by `scripts/disable-jellyfin-hwaccel.sh`
during recovery from a ~6 hour outage.

**Failure mode if re-enabled:** a kernel oops in the `amdgpu` HMM path triggered by GPU userptr
mappings. The blast radius is counter-intuitive — `dockerd` reads `/proc/*/smaps`, so **Traefik and
every `*.deercrest.info` service die** while direct-macvlan containers keep serving. Diagnose from
`/proc/pressure/io` `full` ≈ 96% with an **idle CPU** and kernel `tainted` bit 7 — *not* from load
average, which lags and false-greens after reboot. Proxmox kernel 7.0.14-8 does not carry a fix.

Ollama is not the only GPU userptr source: orphaned Jellyfin VAAPI `ffmpeg` processes are a second
one, which is why the mitigation is at Jellyfin rather than only at Ollama.

### Retention levers

| Setting | Value | Effect |
|---------|-------|--------|
| `TranscodingTempPath` | `/cache/transcodes` | → `fast/transcode`, the quota'd dataset |
| `EnableSegmentDeletion` | `true` | deletes segments behind the playback head |
| `SegmentKeepSeconds` | `300` | how far behind to keep |
| `EnableThrottling` | `true` | pauses the encoder when far ahead |
| `ThrottleDelaySeconds` | `180` | how far ahead before throttling |

All five are **asserted** by `check-jellyfin-transcode.sh` — drift makes the check exit non-zero.
`TranscodingTempPath` is the load-bearing one: point it elsewhere and the 50 G quota bounds nothing.

> These are asserted **not drifted**, which is not the same as proven to *fire*. A standing check
> cannot prove a setting fires (CONS-04). Firing was proven once, from Jellyfin's own Debug log,
> with advancing deletion ranges and the throttler echoing `target gap 1800000000`.

### How to tell which path a session took

Never from a UI label — from ffmpeg's own command line:

```bash
ssh root@172.16.1.159 "docker top jellyfin | grep ffmpeg || true"
```

| Evidence | Meaning |
|----------|---------|
| `-codec:v:0 copy` + `-readrate 10` | **remux** — container repackaged, video stream copied |
| `libx264` (no `-readrate 10`) | **re-encode** |
| *no output at all* | **direct play** — no transcode happened |

⚠️ **Image-based (PGS) subtitles force burn-in, which forces a re-encode.** Enabling a PGS track
silently converts a remux into a `libx264` encode. If you are testing the remux path, subtitles must
be off — look for `-map -0:s` in the command line.

A seek-back past `SegmentKeepSeconds` costs a transcode **restart**, not a failure: a new ffmpeg
PID with a changed `-ss` offset, a few seconds of spinner. Verified by a human on 2026-09-03 for
both the remux and re-encode paths; `/` moved −4.15 MiB across ~25 minutes of encoding.

---

## 5. Live TV chain

```
HDHomeRun (172.16.1.161)  ─┐
IPTV provider streams     ─┴─→  dispatcharr (172.16.1.75:9191)  ─┬─→ Jellyfin  (HDHR + XMLTV)
                                                                 └─→ TiviMate  (Xtream Codes)
```

**dispatcharr is the single source** — since 2026-08-14 the HDHomeRun is no longer a direct Jellyfin
tuner.

**Use `http://172.16.1.75:9191`** (the macvlan address). Host port `9192` maps to it but is
localhost-only in practice due to macvlan asymmetric routing. Host port **9191 is reserved by
`pulse-agent.service`** — reassigning it silently blocked dispatcharr for ~6 weeks.

**Jellyfin is for the library; TiviMate is the live-TV client.** Jellyfin's Live TV path adds ~7.7 s
per channel change (3 s ffprobe + 3 s HLS segment build + ~1 s tuner connect) and that is inherent,
not tunable. TiviMate plays MPEG-TS natively and switches in the ~1.1 s dispatcharr needs.

See [stacks/selfhosted/media/dispatcharr.md](stacks/selfhosted/media/dispatcharr.md) for the channel
lineup, EPG sources, and the `ChannelOverride` durability rules.

---

## 6. Music library export

`tank/media/Music` is exported read-only over NFS from **atlantis** to the Home Assistant NUC, where
Music Assistant reads it at `/media/music`.

- Export is **read-only**: the tree is `568:568` and world-writable (`0777`), and ZFS
  `acltype=nfsv4` ACLs are **not** exported by knfsd — so mode bits are the only lever NFS clients
  see. Read-only is the compensating control.
- `all_squash,anonuid=568,anongid=568`. Never `no_root_squash`.
- Standing check: `scripts/check-music-consumers.sh`.

`rsync -a` **fails** writing to `tank` (`mkstemp ... Operation not permitted`) due to
`acltype=nfsv4` + `aclmode=restricted`, while printing stats that look like success and exiting 23.
Use `rsync -rlt --no-p --no-o --no-g`.

---

## 7. Health checks

```bash
bash scripts/quick-health-check.sh          # from the workstation; 0 healthy, 1 on violation
```

Folds in `check-music-freeze.sh`, `check-music-consumers.sh`, `check-jellyfin-transcode.sh`.
`REMOTE_TIMEOUT` (default 120 s) bounds every remote command Linux-side. See README § Health Checks
for the design rules.

---

## 8. Known gaps

| Gap | Detail |
|-----|--------|
| **`audiobookshelf` stores on `/`** | Its binds are `/audiobooks` and `/audiobookshelf` — root-level paths on the **LXC ext4 root disk**, not under `/mnt/fast/appdata` and not on any dataset. Currently tiny (4 K + 548 K) so it is latent, not urgent — but loading a real audiobook library into it writes to `/`. Violates the STANDARDS base-path convention. |
| **Six other stacks are also on `/`** | `monitoring` (3.9 G), `agentic-os` (674 M), `mattermost` (250 M), `documents`/paperless (95 M), `open-archiver` (67 M), `rustdesk` (1.2 M) — all under `/mnt/fast/appdata/` with **no backing dataset**. ~5 G total today. `monitoring` is the one to watch: Prometheus TSDB grows continuously. See § 3. |
| **`deinterlace_vaapi` on the Radeon 890M** | ffmpeg exits 251. Moot while hardware acceleration is off. |
| **Live TV latency** | ~7.7 s per channel change in Jellyfin, inherent. Use TiviMate. |

---

*Last updated: 2026-09-03, after Phase 02.1 (transcode relocation and retention). Every figure in
this document was measured against the live estate rather than inherited from a plan.*
