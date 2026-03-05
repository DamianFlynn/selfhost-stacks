# Selfhost Stacks

Production-ready self-hosted infrastructure running on Proxmox, managed with Infrastructure as Code (Terraform) and GitOps workflows. Currently hosting 70+ containerized services across media streaming, home automation, development tools, and AI workloads.

## 🏗️ Architecture

This repository is split into two clean domains:

- **`infra/`** — Terraform IaC for Proxmox host configuration and LXC/VM provisioning
- **`stacks/`** — Docker Compose stacks deployed to LXC containers

### Platform

| Resource | IP | Purpose | Specs |
|----------|------------|---------|-------|
| **Proxmox Host** | `172.16.1.158` | Type-1 hypervisor | AMD Ryzen AI 9 HX PRO 370, 64GB RAM, ZFS pool |
| **LXC 100** (`selfhost`) | `172.16.1.159` | Primary Docker runtime | Unprivileged LXC, GPU passthrough (AMD Radeon 890M) |
| **VM 102** (`Cerebro`) | `172.16.1.160` | AI/ML workloads | Ubuntu 24.04, GPU passthrough, Ollama, OpenClaw |

### Storage

- **ZFS Pool:** `/mnt/fast` - High-performance NVMe storage (host)
- **Mount into LXC/VM:** `/mnt/fast/stacks` (repo), `/mnt/fast/appdata` (persistent data)
- **Service Account:** `apps:apps` (UID/GID `568:568`) for container ownership

## 📁 Repository Structure

```
selfhost-stacks/
├── infra/                      # Terraform infrastructure as code
│   ├── host.tf                # Proxmox host configuration
│   ├── lxc-selfhost.tf        # LXC 100 provisioning (Docker runtime)
│   ├── lxc-cerebro.tf         # VM 102 provisioning (AI workloads)
│   ├── providers.tf           # Terraform provider configuration
│   └── variables.tf           # Input variables and defaults
├── stacks/
│   ├── selfhosted/            # Services for LXC 100
│   │   ├── traefik/          # Reverse proxy + SSL (core dependency)
│   │   ├── arrs/             # Media automation (Sonarr, Radarr, Prowlarr, etc.)
│   │   ├── media/            # Streaming (Jellyfin, Jellyseerr)
│   │   ├── automation/       # Home automation (n8n, Oxidized, PWPush)
│   │   ├── openwebui/        # AI chat interface
│   │   ├── immich/           # Photo management
│   │   ├── code-server/      # Web-based VS Code
│   │   └── ...               # 15+ additional stacks
│   └── cerebro/              # Services for VM 102
│       └── borg/             # OpenClaw AI gateway
├── scripts/                   # Operational utilities
│   ├── setup-teleport.sh     # Teleport agent bootstrap
│   └── check-renovate.sh     # Renovate dependency validation
└── .github/
    └── workflows/
        └── compose-validate.yaml  # CI: Validate compose files on PRs

```

## 🚀 Quick Start

### Prerequisites

- Proxmox VE 8.x+ installed on host
- Terraform 1.10+ on your local machine
- SSH access to Proxmox host (`root@172.16.1.158`)

### 1️⃣ Infrastructure Deployment

Deploy Proxmox host configuration and provision LXC containers:

```bash
cd infra
terraform init
terraform plan
terraform apply
```

**What this does:**
- Configures ZFS storage pool on Proxmox host
- Creates unprivileged LXC `100` (`selfhost`) with Docker, GPU passthrough, and mounts
- Provisions VM `102` (`Cerebro`) with Ubuntu 24.04, GPU passthrough, Ollama, and OpenClaw
- Sets up service account (`apps:apps`) and permissions
- Maps AMD Radeon 890M GPU devices (`video:44`, `render:110`)

### 2️⃣ Stack Deployment

SSH into the LXC and deploy stacks from the repository:

```bash
# On your local machine - sync repository to server
ssh root@172.16.1.159
cd /mnt/fast/stacks
git pull origin main

# Deploy foundational stack (Traefik reverse proxy)
docker compose -f stacks/selfhosted/traefik/compose.yaml up -d

# Deploy application stacks
docker compose -f stacks/selfhosted/arrs/compose.yaml up -d
docker compose -f stacks/selfhosted/media/compose.yaml up -d
docker compose -f stacks/selfhosted/automation/compose.yaml up -d
docker compose -f stacks/selfhosted/openwebui/compose.yaml up -d
```

**Compose files reference:**
- Each stack is modular and can be deployed independently
- Stacks share the `t3_proxy` network managed by Traefik
- Environment variables stored in `.env` files (use `.env.sample` templates)

## 🔄 Automated Updates with Renovate

This repository uses [Renovate](https://github.com/renovatebot/renovate) for automated dependency updates:

- ✅ **Auto-merge patch updates** (1.2.3 → 1.2.4) after 1-hour stability period
- ✅ **Auto-merge minor updates** (1.2.0 → 1.3.0) after 3-hour stability period
- ⚠️ **Manual review for major updates** (1.x → 2.x) to prevent breaking changes
- 🔒 **Security updates** merge immediately regardless of stability period

**Configuration:** See [renovate.json](renovate.json)

**Dashboard:** [Dependency Dashboard Issue #3](../../issues/3) - View all pending updates

### Container Version Pinning Strategy

- **Pinned versions** (e.g., `jellyfin:10.11.6`) are tracked by Renovate and auto-updated
- **`:latest` tags** are ignored by Renovate (manual updates required)
- **Branch tags** (`:develop`, `:stable`) are ignored by Renovate

**Best Practice:** Pin to specific semver tags to enable automatic updates while maintaining stability.

## 🧪 CI/CD

GitHub Actions automatically validate compose files on every pull request:

- ✅ Syntax validation with `docker compose config`
- ✅ Image availability checks
- ✅ Environment variable reference validation
- ✅ Prevents broken configurations from merging

**Workflow:** [.github/workflows/compose-validate.yaml](.github/workflows/compose-validate.yaml)

## 🎯 Common Workflows

### Deploy a New Stack

1. Create compose file in `stacks/selfhosted/<stack-name>/compose.yaml`
2. Pin container versions (avoid `:latest`)
3. Create `.env.sample` template for required variables
4. Document service in compose file comments
5. Commit and push to GitHub
6. SSH to LXC and deploy: `docker compose -f stacks/selfhosted/<stack-name>/compose.yaml up -d`

### Update Existing Stack

```bash
ssh root@172.16.1.159
cd /mnt/fast/stacks
git pull origin main
docker compose -f stacks/selfhosted/<stack-name>/compose.yaml pull
docker compose -f stacks/selfhosted/<stack-name>/compose.yaml up -d
```

### View Running Containers

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

### Check Stack Logs

```bash
docker compose -f stacks/selfhosted/<stack-name>/compose.yaml logs -f
```

### Rebuild Infrastructure

```bash
cd infra
terraform plan
terraform apply
```

## 🔐 Security & Access

### Traefik Reverse Proxy

- **SSL/TLS:** Automatic certificate management with Let's Encrypt
- **Authentication:** Authelia integration for protected services
- **Middleware:** Rate limiting, IP whitelisting, basic auth available

### Service Access Patterns

- **Public:** No authentication (e.g., Jellyfin for family, PWPush for sharing)
- **Protected:** Authelia SSO (admin dashboards, management interfaces)
- **Internal Only:** No Traefik route, LXC network only (databases, caches)

### Environment Variables

Sensitive data stored in `.env` files (gitignored):
- Database passwords
- API keys
- Secret keys
- JWT tokens

**Template files:** `.env.sample` committed to repository as documentation

## 🎮 GPU Hardware Acceleration

AMD Radeon 890M GPU is passed through to LXC `100` for hardware transcoding:

**Supported Services:**
- **Jellyfin:** VA-API transcoding for H.264, HEVC, VP9
- **Immich:** Hardware-accelerated photo/video processing

**Device Mapping:**
- `/dev/dri/renderD128` (group `render:110`)
- `/dev/dri/card1` (group `video:44`)

**Configuration:** See `infra/lxc-selfhost.tf` for LXC device mapping

## 📊 Current Stacks

### Media & Streaming
- **Jellyfin** - Media server (movies, TV, music)
- **Jellyseerr** - Content request management
- **Jellystat** - Analytics and statistics
- **Wizarr** - User invitation system

### Media Automation (Arrs)
- **Sonarr** - TV show management
- **Radarr** - Movie management
- **Lidarr** - Music management
- **Bazarr** - Subtitle management
- **Prowlarr** - Indexer manager
- **Autobrr** - IRC announce grabber

### Development
- **Code Server** - Web-based VS Code
- **OpenWebUI** - AI chat interface (Ollama frontend)

### Automation
- **n8n** - Workflow automation
- **Oxidized** - Network device backup
- **Teleport** - Access control proxy

### Photo Management
- **Immich** - Google Photos alternative

### Infrastructure
- **Traefik** - Reverse proxy and SSL termination
- **Authelia** - SSO authentication
- **Docker Socket Proxy** - Secure Docker API access

*See full inventory: 70+ containers across 20+ stacks*

## 📚 Documentation

- **[CLAUDE.md](CLAUDE.md)** - AI Agent guidance for repository operations
- **[DEPLOY.md](DEPLOY.md)** - Detailed deployment procedures
- **[STANDARDS.md](STANDARDS.md)** - Coding and configuration standards

## 🔧 Troubleshooting

### Container fails to start

```bash
docker compose -f stacks/selfhosted/<stack>/compose.yaml logs
```

### Permission issues

Ensure files are owned by `apps:apps` (568:568):
```bash
chown -R 568:568 /mnt/fast/appdata/<stack>
```

### GPU not accessible

Verify device mapping in LXC:
```bash
ls -l /dev/dri/
groups apps  # Should include 'video' and 'render'
```

### Traefik routing issues

Check Traefik dashboard: `https://traefik.deercrest.info`

### Renovate not creating PRs

Check [Dependency Dashboard](../../issues/3) for ignored or blocked updates

## 🤝 Contributing

1. Pin container versions (avoid `:latest`)
2. Include `.env.sample` for new stacks
3. Document service purpose in compose file comments
4. Test compose validation locally: `docker compose config`
5. Create descriptive commit messages

## 📜 License

Private repository - All rights reserved

---

**Maintained by:** Damian Flynn  
**Last Updated:** March 2026  
**Repository:** [github.com/DamianFlynn/selfhost-stacks](https://github.com/DamianFlynn/selfhost-stacks)
