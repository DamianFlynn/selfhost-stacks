# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Docker Compose stacks for a self-hosted media/productivity server running **Proxmox VE 9.1** on a Minisforum N5 Pro (AMD iGPU). All services run inside a single **unprivileged Debian 13 LXC** (VMID 100, `172.16.1.159`) managed by Docker Compose.

- Host storage: `/mnt/fast/...` (NVMe mirror, Samsung 990 EVO) for app config/databases; `/mnt/tank/...` (HDD raidz1) for media — both ZFS pools bind-mounted into the LXC at identical paths
- Reverse proxy: **Traefik v3** with **Authelia** SSO, Cloudflare DNS-01 SSL
- GitOps: **Renovate** keeps images fresh with pinned digests for security-critical components
- Infrastructure-as-code: **Terraform** (`infrastructure/proxmox/`) automates the Proxmox host + LXC provisioning

## Platform

| Node | Role | IP |
|------|------|----|
| Proxmox VE 9.1 host (`pve`) | Hypervisor | `172.16.1.158` |
| LXC 100 `selfhost` | Docker — all compose stacks | `172.16.1.159` |
| LXC 101 `openclaw` | OpenClaw game engine | `172.16.1.160` |

The Docker LXC is **unprivileged** with a custom `lxc.idmap` that passes through UID/GID 568 (apps), GID 44 (video), and GID 110 (render) 1:1 so bind-mounted ZFS files retain correct ownership and AMD GPU devices work.

## Architecture

### Modular Compose Pattern

Every stack follows a two-level structure:

1. **`<stack>/compose.yaml`** — declares the stack `name`, networks, secrets, named volumes, and `include:`s service files
2. **`<stack>/<service>.yaml`** — one service (and optionally its Prometheus exporter) per file

The stack compose never has a `services:` block directly — all services come from `include:`.

### Networks

| Network | Subnet | Purpose |
|---------|--------|---------|
| `t3_proxy` | `192.168.90.0/24` | All services reachable via Traefik; defined in `traefik/compose.yaml`, used as `external: true` elsewhere |
| `socket_proxy` | `192.168.91.0/24` | Traefik → socket-proxy only; never expose Docker socket directly |

All services that need HTTP routing must join `t3_proxy`.

### Traefik Label Conventions

Every service uses this pattern (see `arrs/radarr.yaml` for full example):

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.<svc>-rtr.entrypoints=web,websecure
  - traefik.http.routers.<svc>-rtr.rule=Host(`<svc>.deercrest.info`)
  - traefik.http.routers.<svc>-rtr.middlewares=chain-authelia@file  # or chain-no-auth@file
  - traefik.http.routers.<svc>-rtr.tls=true
  - traefik.http.routers.<svc>-rtr.tls.certresolver=dns-cloudflare
  - traefik.http.routers.<svc>-rtr.service=<svc>-svc
  - traefik.http.services.<svc>-svc.loadbalancer.server.port=<PORT>
```

**Auth bypass router** (for mobile apps like LunaSea/nzb360): add a second router `<svc>-bypass` with `priority=100` and `Header('auth-bypass-key', '$<SVC>_AUTH_BYPASS_KEY')` using `chain-no-auth@file`.

Middleware chains are defined in Traefik's dynamic file provider at `/mnt/fast/appdata/traefik/rules/`.

### Permissions Model

- **Service account**: `apps:apps` (UID/GID `568`) owns `/mnt/fast/stacks` and `/mnt/fast/appdata`
- **Working user**: `damian` is a member of `apps` group
- Set `PUID=568` / `PGID=568` in `.env` for LinuxServer images
- **Exception**: Postgres data dirs must be `postgres:postgres` / `700`
- GPU devices (`/dev/dri/card0`, `/dev/dri/renderD128`) are owned by `video:44` / `render:110` — the LXC idmap passes these GIDs through 1:1

## Infrastructure — Terraform

The `infrastructure/proxmox/` directory contains Terraform (bpg/proxmox ~> 0.95) that provisions the entire Proxmox setup:

```
infrastructure/proxmox/
├── providers.tf           # bpg/proxmox + hashicorp/null
├── variables.tf           # all inputs with defaults
├── terraform.tfvars.example  # copy → terraform.tfvars and fill secrets
├── host.tf                # ZFS pool import, apps user, subuid/subgid, template download
├── lxc-selfhost.tf        # Docker LXC: container + idmap patch + Docker provisioning
├── lxc-openclaw.tf        # OpenClaw LXC: container + idmap patch + SDL2 deps
└── outputs.tf
```

```bash
cd infrastructure/proxmox
cp terraform.tfvars.example terraform.tfvars   # fill in passwords + SSH key
terraform init
terraform plan
terraform apply
```

**Phase ordering** (enforced by `depends_on`):
1. `host_setup` — ZFS import, apps user, subuid/subgid, template download
2. Container resources (both LXCs, `started=false`)
3. `patch_lxc_config` / `patch_openclaw_config` — writes idmap + GPU entries to conf **before first boot**
4. `start_lxc` / `start_openclaw` — `pct start` + SSH wait
5. `provision_lxc` / `provision_openclaw` — Docker CE (selfhost) / SDL2 deps (openclaw)

## Secrets & Environment Files

- `.env` — local secrets; **never committed**; loaded automatically by Docker Compose
- `.env.sample` — committed template with placeholder values
- Docker secrets (for Traefik/Authelia) live under `/mnt/fast/appdata/traefik/secrets/` as plain files
- Terraform secrets live in `infrastructure/proxmox/terraform.tfvars` — **never committed** (gitignored)

## Service File Header Format

Every service YAML must have this header:

```yaml
# Service Name - Brief Description
#
# Purpose:
#   What this service does and why it exists
#
# Key Features:
#   - Feature 1
#
# Workflow:
#   Data flow description
#
# Access:
#   URL: https://<svc>.deercrest.info
#   Middleware: chain-authelia (or chain-no-auth)
#
```

## Adding a New Stack

1. Create `<stack>/compose.yaml` with name, networks (`t3_proxy` as external), includes, and named volumes using `driver_opts.device: /mnt/fast/appdata/<stack>/<component>`
2. Create `<stack>/<service>.yaml` with the full header and Traefik labels
3. Create `<stack>/.env` (local) and `<stack>/.env.sample` (committed)
4. If Renovate should track this stack's images, add a `managerFilePatterns` entry in `renovate.json`

> The `wrappers/` directory contains legacy TrueNAS App wrappers — no longer used on Proxmox.

## Renovate Image Update Policy

Configured in `renovate.json`:

| Component | Auto-merge | Digest pinned |
|-----------|-----------|---------------|
| patch/digest (all) | ✅ after 1h | — |
| minor (all) | ✅ after 3h | — |
| major (all) | ❌ manual | — |
| `traefik`, `authelia/authelia` | ❌ manual | ✅ yes |
| Immich server/ML | ❌ manual | — |
| Postgres/Valkey in Immich | 🔒 disabled | 🔒 pinned |

Renovate only scans files matching `managerFilePatterns`. When adding a stack with non-standard filenames (service files not named `compose.yaml`), add a pattern to `renovate.json` — see the existing `traefik/*.yaml` patterns as examples.

## Common Operations

```bash
# ── Docker (run inside LXC: ssh root@172.16.1.159) ───────────────────────────

# Validate a compose file
docker compose -f <stack>/compose.yaml config

# Check running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort

# View logs
docker logs <container_name>
docker logs -f <container_name>

# Inspect the t3_proxy network
docker network inspect t3_proxy

# Fix Postgres data directory permissions
docker run --rm -v /mnt/fast/appdata/immich/postgres:/var/lib/postgresql/data \
  ghcr.io/immich-app/postgres:16 bash -lc \
  'chown -R postgres:postgres /var/lib/postgresql/data; chmod 700 /var/lib/postgresql/data'

# ── LXC management (run on Proxmox host: ssh root@172.16.1.158) ──────────────

pct list                     # show all containers
pct start/stop/restart 100   # manage selfhost LXC
pct enter 100                # root shell inside selfhost (without SSH)
pct start/stop/restart 101   # manage openclaw LXC

# ── ZFS (on Proxmox host) ─────────────────────────────────────────────────────

zfs list                     # list all datasets
zpool status                 # pool health
zpool scrub fast && zpool scrub tank   # manual scrub

# ── Terraform ─────────────────────────────────────────────────────────────────

cd infrastructure/proxmox
terraform plan               # preview changes
terraform apply              # apply changes
terraform apply -target=null_resource.provision_lxc   # re-run provisioner only

# Validate Renovate config
./scripts/check-renovate.sh
```

## Key File Locations

| Path | Where | Purpose |
|------|-------|---------|
| `/mnt/fast/stacks/` | LXC + host (bind mount) | This git repo |
| `/mnt/fast/appdata/traefik/rules/` | LXC | Traefik dynamic config (middleware chains, TLS options) |
| `/mnt/fast/appdata/traefik/acme/acme.json` | LXC | Let's Encrypt certificates (chmod 600) |
| `/mnt/fast/appdata/traefik/secrets/` | LXC | Docker secrets files |
| `/mnt/tank/media/` | LXC + host (bind mount) | Media library (movies, TV, music, photos) |
| `/mnt/tank/downloads/` | LXC + host (bind mount) | Download client output |
| `/etc/pve/lxc/100.conf` | Proxmox host | selfhost LXC config (idmap + GPU entries) |
| `/etc/pve/lxc/101.conf` | Proxmox host | openclaw LXC config (idmap + GPU entries) |
| `infrastructure/proxmox/` | Dev machine | Terraform for Proxmox provisioning |
