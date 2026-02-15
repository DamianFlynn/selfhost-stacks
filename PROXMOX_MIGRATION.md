# Migration: TrueNAS SCALE 25.10 → Proxmox VE 9.1

## Quick Start (Automated with Terraform)

This migration is **fully automated** using Terraform. After installing Proxmox, simply run:

```bash
cd infrastructure/proxmox
cp terraform.tfvars.example terraform.tfvars   # fill in passwords + SSH keys
terraform init && terraform apply
```

Terraform automates:
- ✅ ZFS pool import and mountpoint configuration
- ✅ User/group creation (apps:568, video:44, render:110)
- ✅ GPU passthrough configuration (/dev/dri/* device ownership)
- ✅ LXC creation with unprivileged idmap for GPU + bind mounts
- ✅ Docker CE installation and configuration
- ✅ Docker macvlan network creation (for Jellyfin/Dispatcharr direct LAN IPs)
- ✅ GitHub SSH key deployment from Proxmox host to LXC
- ✅ All subuid/subgid delegation for idmap passthrough

---

## Prerequisites

### 1. Hardware Requirements

| Drive | Device | Size | Role |
|-------|--------|------|------|
| Kingston SNV3S500G | `nvme0n1` | 465 GB | TrueNAS boot-pool → **Proxmox OS target** |
| Samsung 990 EVO Plus × 2 | `nvme1n1`, `nvme2n1` | 1.8 TB each | `fast` pool (mirror) — **untouched** |
| Seagate ST26000NM × 3 | `sda`, `sdb`, `sdc` | 23.6 TB each | `tank` pool (raidz1) — **untouched** |

**Data Safety**: `fast` and `tank` pools are on separate drives. Installing Proxmox to `nvme0n1` **only destroys the TrueNAS boot-pool**.

### 2. Pre-Migration Backups (on TrueNAS while running)

```bash
# 1. Commit and push git repo
git -C /mnt/fast/stacks status && git -C /mnt/fast/stacks push

# 2. Back up .env files (belt-and-suspenders)
find /mnt/fast/stacks -name '.env' | while read f; do
  echo "=== $f ==="; cat "$f"; echo
done > ~/env-backup-$(date +%Y%m%d).txt
# Copy this file off-box

# 3. Verify Traefik ACME certificate exists
wc -c /mnt/fast/appdata/traefik/acme/acme.json  # should be >1KB

# 4. Export ZFS pool GUIDs (for verification later)
zpool get guid fast tank boot-pool > ~/zpool-guids.txt

# 5. Note current user/group IDs
id apps                          # uid=568(apps) gid=568(apps)
getent group render video        # render:x:107  video:x:44

# 6. Back up personal settings to fast pool
ssh root@<truenas-ip> 'bash -s' < scripts/backup-truenas-settings.sh
ssh root@<truenas-ip> "ls -lh /mnt/fast/home/backup-truenas-*.tar.gz"

# 7. FINAL STEP: Stop services and cleanly export pools
docker stop $(docker ps -q) 2>/dev/null || true
zpool export fast
zpool export tank
shutdown -h now
```

---

## Phase 1: Install Proxmox VE 9.1

### 1.1 Boot from USB

Create Proxmox VE 9.1 USB installer (Rufus/Balena Etcher, ISO mode).

### 1.2 Disk Selection — CRITICAL STEP

```
Target disk: /dev/nvme0n1   (Kingston SNV3S500G, 465.8 GB)
Filesystem:  ZFS (RAID0)
```

**DO NOT select nvme1n1, nvme2n1, sda, sdb, or sdc** — these contain your data pools.

### 1.3 Network Configuration

| Field | Value |
|-------|-------|
| Management interface | `eno1` |
| Hostname (FQDN) | `atlantis.deercrest.info` |
| IP Address | `172.16.1.158/24` |
| Gateway | `172.16.1.1` |
| DNS Server | `172.16.1.1` |

The LXC will use `172.16.1.159` (same as TrueNAS), preserving firewall/DNS rules.

---

## Phase 2: First Boot — Prepare Proxmox Host

SSH into Proxmox: `ssh root@172.16.1.158`

### 2.1 Remove Enterprise Repo (No Subscription)

```bash
# Disable enterprise repos
echo "# pve-enterprise disabled" > /etc/apt/sources.list.d/pve-enterprise.list
echo "# ceph-enterprise disabled" > /etc/apt/sources.list.d/ceph.list
mv /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/sources.list.d/pve-enterprise.sources.disabled
mv /etc/apt/sources.list.d/ceph.sources /etc/apt/sources.list.d/ceph.sources.disabled

# Add no-subscription repo (Debian trixie for PVE 9.x)
echo "deb http://download.proxmox.com/debian/pve trixie pve-no-subscription" \
  > /etc/apt/sources.list.d/pve-no-subscription.list

apt-get update && apt-get full-upgrade -y
```

### 2.2 Import ZFS Pools

```bash
# Clean import (if pools were exported before shutdown)
zpool import fast
zpool import tank

# Force import (if you skipped export — shows hostid mismatch)
# zpool import -f fast
# zpool import -f tank

# Fix TrueNAS altroot mountpoint quirk
zfs set mountpoint=/mnt/fast fast
zfs set mountpoint=/mnt/tank tank

# Verify
ls /mnt/               # should show: fast  tank
zfs get mountpoint fast tank

# Enable auto-import on boot
zpool set cachefile=/etc/zfs/zpool.cache fast
zpool set cachefile=/etc/zfs/zpool.cache tank
systemctl enable zfs-import-cache.service zfs-mount.service
```

### 2.3 Copy SSH Keys to Proxmox Host

**Required for Terraform to deploy keys to LXC:**

```bash
# From your dev machine
scp ~/.ssh/id_ed25519* root@172.16.1.158:/root/.ssh/
ssh root@172.16.1.158 'chmod 600 /root/.ssh/id_ed25519*'
```

Terraform will copy these from Proxmox → LXC automatically during provisioning.

---

## Phase 3: Run Terraform (Full Automation)

### 3.1 Prepare terraform.tfvars

```bash
cd infrastructure/proxmox
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and configure:

```hcl
# Proxmox Connection
proxmox_host     = "172.16.1.158"
proxmox_node     = "atlantis"           # ⚠️ MUST match: ssh root@172.16.1.158 'hostname'
proxmox_password = "your-proxmox-root-password"

# LXC Configuration
lxc_hostname       = "selfhost"
lxc_ip             = "172.16.1.159"
lxc_gateway        = "172.16.1.1"
lxc_vmid           = 100
lxc_root_password  = "your-lxc-root-password"
lxc_template       = "debian-13-standard_13.1-2_amd64.tar.zst"  # ⚠️ Verify: pveam available --section system | grep debian-13

# SSH Keys (for LXC root user)
lxc_ssh_public_keys           = ["ssh-ed25519 AAAAC3NzaC... your-key-here"]
terraform_ssh_private_key_path = "/Users/damian/.ssh/id_ed25519"  # ⚠️ Must be in SSH agent

# GPU & UID/GID Configuration (usually no changes needed)
apps_uid    = 568
apps_gid    = 568
video_gid   = 44   # Standard Debian video group
render_gid  = 110  # Avoiding tcpdump(103) and postdrop(105)
gpu_card_index   = 1    # Verify: ls /dev/dri/  (this machine: card1)
gpu_render_index = 128  # Verify: ls /dev/dri/  (renderD128)
```

### 3.2 Verify Prerequisites

```bash
# 1. Hostname must match
ssh root@172.16.1.158 'hostname'  # Should return: atlantis

# 2. Template must be available
ssh root@172.16.1.158 'pveam available --section system | grep debian-13'

# 3. SSH key must be in agent
ssh-add -l  # Check if loaded
ssh-add --apple-use-keychain ~/.ssh/id_ed25519  # Add if missing

# 4. ZFS pools must be imported
ssh root@172.16.1.158 'zfs list | grep -E "fast|tank"'
```

### 3.3 Run Terraform

```bash
terraform init
terraform plan   # Review changes
terraform apply  # Creates full infrastructure
```

Terraform will:
1. Configure Proxmox host (groups, subuid/subgid, GPU ownership, vmbr0 promiscuous mode)
2. Download Debian 13 LXC template
3. Create unprivileged LXC with GPU passthrough and bind mounts
4. Patch LXC config with custom idmap and GPU devices
5. Start LXC and wait for SSH
6. Install Docker CE, create users/groups, configure daemon
7. Create iot_macvlan network for Jellyfin/Dispatcharr
8. Copy SSH keys from Proxmox host to LXC for GitHub access
9. Run smoke tests

Expected output includes:
```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:
lxc_ip = "172.16.1.159"
lxc_ssh = "ssh root@172.16.1.159"
```

> **⚠️ Important: Reprovisioning After Failed Runs**
> 
> Terraform `null_resource` provisioners only run when the resource is **created**, not on subsequent applies.
> If the initial `terraform apply` fails partway through (network timeout, SSH issues, etc.), you must
> explicitly force terraform to re-run the provisioners:
> 
> ```bash
> terraform apply \
>   -replace=null_resource.patch_lxc_config \
>   -replace=null_resource.start_lxc \
>   -replace=null_resource.provision_lxc \
>   -replace=null_resource.copy_ssh_keys
> ```
> 
> This recreates the entire dependency chain: patch LXC config → start LXC → provision Docker/users → copy SSH keys.
> 
> **After first successful apply**, if you only need to re-run specific steps (e.g., SSH keys changed),
> you can replace just that resource: `terraform apply -replace=null_resource.copy_ssh_keys`

### 3.4 Verify Deployment

```bash
# Test LXC access
ssh root@172.16.1.159

# Inside LXC, verify:
docker info | grep -E 'Storage Driver|Cgroup'   # Should show: overlay2, systemd, v2
ls -la /dev/dri/                                 # Should show: card1, renderD128
getent group render video                        # render:x:110  video:x:44
id apps                                          # uid=568, groups: 568(apps),44(video),110(render),991(docker)
docker network ls | grep iot_macvlan             # Should exist
ls /mnt/fast/stacks                              # Should show git repo
git -C /mnt/fast/stacks status                   # Should work (SSH keys deployed)

# Test GPU hardware acceleration
docker run --rm --device /dev/dri/card1 --device /dev/dri/renderD128 --group-add video --group-add render \
  debian:13 ls -la /dev/dri/
```

> **⚠️ Critical: Render Group GID Check**
> 
> Debian 13 creates the `render` group with a **dynamic GID** (typically 992) instead of the expected
> static GID 110. If `getent group render` shows the wrong GID, the GPU devices will appear as `nobody:110`
> and hardware acceleration will fail.
> 
> **Fix immediately if needed:**
> ```bash
> ssh root@172.16.1.159 'groupmod -g 110 render && usermod -aG render apps'
> ```
> 
> After fixing, verify: `ls -la /dev/dri/` should show `renderD128` owned by `nobody:render` (not `nobody:110`).

---

## Phase 4: Deploy Docker Stacks

### 4.1 Pull Latest Git Changes

```bash
ssh root@172.16.1.159
cd /mnt/fast/stacks
git pull  # SSH key was copied by terraform
```

### 4.2 Start Stacks in Dependency Order

```bash
cd /mnt/fast/stacks

# 1. Infrastructure (creates t3_proxy network)
docker compose -f traefik/compose.yaml up -d

# Verify networks
docker network ls | grep -E 't3_proxy|socket_proxy|iot_macvlan'

# 2. Media acquisition
docker compose -f arrs/compose.yaml up -d

# 3. Media serving (uses iot_macvlan for direct LAN IPs)
docker compose -f media/compose.yaml up -d

# 4. Photo library
docker compose -f immich/compose.yaml up -d

# 5. AI workloads (OpenWebUI + Ollama with Vulkan GPU)
docker compose -f openwebui/compose.yaml up -d

# 6. All other stacks
for stack in automation code-server dawarich freshrss homarr karakeep keeper-sh minecraft podsync postiz teleport termix; do
  docker compose -f $stack/compose.yaml up -d
done
```

### 4.3 Deployed Container Versions (Verified with GPU)

| Container | Version | GPU API | Status |
|-----------|---------|---------|--------|
| jellyfin | latest | VA-API | ✅ Hardware transcoding verified |
| dispatcharr | v0.19.0 | VA-API | ✅ Live TV transcoding verified |
| immich-server | v2.5.6 | VA-API | ✅ Video transcoding configured |
| immich-machine-learning | v2.5.6 | CPU-only | ✅ Face recognition (CPU mode) |
| ai-ollama | 0.15.6 | Vulkan | ✅ LLM GPU offloading verified |

**Key Updates:**
- **Dispatcharr v0.19.0**: 50% reduction in XtreamCodes API calls, system notifications, auto-update checking
- **Immich v2.5.6**: Fixed thumbnail generation bug, iOS performance, Android free-up space
- **Ollama Vulkan**: Switched from ROCm (requires /dev/kfd) to Vulkan (works in unprivileged LXC)

```bash
# Check containers are healthy
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort
```

### 4.4 Verify GPU Hardware Acceleration

All media and AI containers require `group_add: ["44", "110"]` for GPU access in unprivileged LXC:
- `44` = video group (for /dev/dri/card1)
- `110` = render group (for /dev/dri/renderD128)

**Critical**: Use numeric GIDs, not group names. Docker resolves names *inside* the container where GIDs may differ.

#### 4.4.1 Test Jellyfin (VA-API Hardware Transcoding)

```bash
# Verify GPU device access
docker exec jellyfin ls -la /dev/dri/
docker exec jellyfin id  # Should show: groups=44(video),110

# Test VA-API
docker exec jellyfin vainfo --display drm --device /dev/dri/renderD128

# Expected output (AMD Radeon 890M):
# VAProfileH264ConstrainedBaseline: Decode, Encode
# VAProfileH264Main: Decode, Encode
# VAProfileH264High: Decode, Encode
# VAProfileHEVCMain: Decode, Encode
# VAProfileHEVCMain10: Decode, Encode
# VAProfileVP9Profile0: Decode
# VAProfileVP9Profile2: Decode
# VAProfileAV1Profile0: Decode, Encode
```

#### 4.4.2 Test Dispatcharr (VA-API Live TV Transcoding)

```bash
# Verify GPU access
docker exec dispatcharr id  # Should show: groups=44(video),110
docker logs dispatcharr | grep -i "VAAPI\|GPU"

# Expected output:
# VAAPI: AVAILABLE
# GPU: Advanced Micro Devices, Inc. [AMD/ATI] (RADV GFX1150)
# Driver: radeonsi (recommended for AMD GPUs)
```

#### 4.4.3 Test Immich (VA-API Video Transcoding)

```bash
# Verify GPU access
docker exec immich_server id  # Should show: groups=44(video),110
docker exec immich_server ls -la /dev/dri/
docker exec immich_server ffmpeg -hide_banner -hwaccels | grep vaapi

# Hardware transcoding activates automatically when playing videos
# Check Server Settings → Video Transcoding in web UI:
#   - Hardware Acceleration: VA-API
#   - Device: /dev/dri/renderD128
```

#### 4.4.4 Test Ollama (Vulkan GPU Inference)

```bash
# Verify GPU access (OpenWebUI stack)
docker exec ai-ollama id  # Should show: groups=44(video),110
docker logs ai-ollama | grep -i "inference compute"

# Expected output:
# inference compute Vulkan0 "AMD Radeon 890M (RADV GFX1150)" 
#   type=iGPU total="16.5 GiB" available="16.3 GiB"

# Note: Ollama uses Vulkan (not ROCm) in unprivileged LXC
# OLLAMA_VULKAN=true, no /dev/kfd required
```

**Configuration Summary**:

| Container | API | Environment | Purpose |
|-----------|-----|-------------|---------|
| jellyfin | VA-API | - | H.264/HEVC/VP9/AV1 transcoding |
| dispatcharr | VA-API | - | Live TV transcoding |
| immich-server | VA-API | IMMICH_FFMPEG_HWACCEL=vaapi | Video thumbnail generation |
| immich-machine-learning | CPU | IMMICH_ML_FORCE_CPU=true | Face recognition (CPU-only) |
| ai-ollama | Vulkan | OLLAMA_VULKAN=true | LLM inference offloading |

---

## Phase 4.5: Configure OpenClaw LXC with Ollama + AMD GPU

The `openclaw` LXC (172.16.1.160) is designed for AI workloads with GPU acceleration via Vulkan. After Terraform provisioning:

**Important:** The LXC idmap must have render GID 110 passthrough (not 105). Terraform handles this automatically, but if upgrading from an older config, manually fix the idmap and restart the LXC.

### 4.5.1 Verify GPU Passthrough

```bash
# Check GPU devices inside LXC
ssh root@172.16.1.160 "ls -la /dev/dri/"

# Expected output:
#   crw-rw---- 1 nobody video  226,   1 card1
#   crw-rw---- 1 nobody render 226, 128 renderD128

# If renderD128 shows "nogroup" instead of "render", fix the idmap:
# On Proxmox host:
ssh root@172.16.1.158 "pct stop 101 && \
  sed -i 's/^lxc\\.idmap: g 105 105 1$/lxc.idmap: g 110 110 1/' /etc/pve/lxc/101.conf && \
  sed -i 's/^lxc\\.idmap: g 106 100106 65430$/lxc.idmap: g 111 100111 65425/' /etc/pve/lxc/101.conf && \
  pct start 101"
```

### 4.5.2 Install and Test Ollama

Terraform pre-configures Ollama with Vulkan GPU support. Verify it's working:

```bash
ssh root@172.16.1.160

# Check Ollama service configuration
systemctl cat ollama.service | grep -A10 '\[Service\]'

# Expected to see:
#   Environment="OLLAMA_VULKAN=1"
#   SupplementaryGroups=video render
#   DeviceAllow=/dev/dri/renderD128 rw

# Pull a model (Llama 3.2 3B)
ollama pull llama3.2

# Test inference
time ollama run llama3.2 "Explain quantum physics in 10 words"

# Expected response time: 1-2 seconds (cached) or 5-10 seconds (first run)
```

### 4.5.3 Verify GPU Acceleration

Check if Ollama is using the AMD Radeon 890M GPU:

```bash
# View Ollama logs for GPU detection
journalctl -u ollama -n 100 --no-pager | grep -i "vulkan\|gpu\|offload"

# Expected output (GPU working):
#   deviceName = AMD Radeon Graphics (RADV GFX1150)
#   load_tensors: offloaded 29/29 layers to GPU
#   load_tensors: Vulkan0 model buffer size = 1918.35 MiB
#   runner.vram="2.6 GiB"

# Check Vulkan devices
su - ollama -s /bin/bash -c "vulkaninfo 2>&1 | grep -i deviceName"

# Expected:
#   deviceName = AMD Radeon Graphics (RADV GFX1150)
#   deviceName = llvmpipe (LLVM 19.1.7, 256 bits)  ← CPU fallback

# Monitor GPU usage during inference
# Terminal 1:
watch -n 0.5 'cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null'

# Terminal 2:
time ollama run llama3.2 "Write a detailed explanation of relativity in 100 words"

# GPU usage should spike to 70-98% during inference
```

### 4.5.4 Troubleshooting GPU Issues

If GPU is **not** detected by Ollama:

**1. Check render group GID mismatch:**
```bash
# Inside LXC
getent group render
# Should show: render:x:110:ollama

# If it shows render:x:992 or any other GID != 110:
groupmod -g 110 render

# Then restart LXC from Proxmox host:
ssh root@172.16.1.158 "pct restart 101"
```

**2. Verify Ollama service configuration:**
```bash
# Check systemd override
cat /etc/systemd/system/ollama.service.d/amd-gpu.conf

# Should contain:
#   Environment="OLLAMA_VULKAN=1"
#   Environment="HSA_OVERRIDE_GFX_VERSION=11.0.3"
#   SupplementaryGroups=video render
#   DeviceAllow=/dev/dri/renderD128 rw

# If missing or incorrect, recreate:
cat > /etc/systemd/system/ollama.service.d/amd-gpu.conf <<'EOF'
[Service]
Environment="HSA_OVERRIDE_GFX_VERSION=11.0.3"
Environment="OLLAMA_DEBUG=1"
Environment="OLLAMA_VULKAN=1"
User=ollama
SupplementaryGroups=video render
DeviceAllow=/dev/dri/card1 rw
DeviceAllow=/dev/dri/renderD128 rw
EOF

systemctl daemon-reload
systemctl restart ollama
```

**3. Test Vulkan access:**
```bash
# As ollama user
su - ollama -s /bin/bash -c "vulkaninfo --summary"

# Should show AMD Radeon Graphics (RADV GFX1150) as GPU 0
# If Permission denied, check device ownership and groups
```

**4. Check logs for errors:**
```bash
journalctl -u ollama -f

# Run a query in another terminal and watch for errors
# Look for: "initial_count=0" (bad) vs "offloaded 29/29 layers" (good)
```

### 4.5.5 Performance Expectations

| Model | Size | CPU (Ryzen AI 9 HX 370) | GPU (Radeon 890M Vulkan) |
|-------|------|-------------------------|--------------------------|
| Llama 3.2 3B | 3.2GB | ~40-50 seconds | ~7-10 seconds |
| Llama 3.1 8B | 8.5GB | ~120+ seconds | ~15-25 seconds |

GPU performance with Vulkan/Mesa RADV:
- ✅ All model layers offloaded to GPU VRAM
- ✅ GPU usage spikes to 70-98% during inference
- ✅ VRAM usage: ~2.6 GB for Llama 3.2 3B
- ⚠️ Integrated GPU shares system RAM (slower than discrete GPU)
- ⚠️ Vulkan/Mesa slightly slower than native ROCm (ROCm not practical in LXC)

**Why Vulkan instead of ROCm:**
- ROCm repositories don't support Debian 13 (designed for Ubuntu)
- ROCm primarily targets datacenter GPUs (MI series), limited consumer GPU support
- Vulkan via Mesa RADV works out-of-the-box with Debian's built-in drivers
- Lighter weight and more reliable in LXC environments
- Performance difference is minimal (10-20%) for consumer GPUs

### 4.5.6 Recommended Models for AMD Radeon 890M

The AMD Radeon 890M has ~2.6-4GB effective VRAM capacity (shared with system RAM). These models are tested and perform well:

**Best for Coding Tasks:**
```bash
# Qwen2.5-Coder 3B (RECOMMENDED - excellent balance)
ollama pull qwen2.5-coder:3b

# Test it:
ollama run qwen2.5-coder:3b "Write a Python function to reverse a linked list"
```

**Other Recommended Models:**
```bash
# General purpose - fast
ollama pull llama3.2:3b          # Multi-purpose, fast
ollama pull qwen2.5-coder:1.5b   # Coding, even faster

# Larger models (requires 8-16GB LXC RAM)
ollama pull llama3.1:8b          # Better quality, slower
ollama pull qwen2.5-coder:7b     # Advanced coding, slower
```

**Model Size Guidelines:**

| Model | VRAM | Full GPU Offload | LXC RAM | Performance |
|-------|------|------------------|---------|-------------|
| qwen2.5-coder:1.5b | ~1.5GB | ✅ Yes | 4GB OK | ⚡⚡⚡ Excellent |
| **qwen2.5-coder:3b** | **~2.5GB** | **✅ Yes** | **4GB OK** | **⚡⚡ Great** |
| llama3.2:3b | ~2.6GB | ✅ Yes | 4GB OK | ⚡⚡ Great |
| qwen2.5-coder:7b | ~4-5GB | ⚠️ Partial | 8-16GB | ⚡ Good |
| llama3.1:8b | ~5-6GB | ⚠️ Partial | 8-16GB | ⚡ Good |

**Note:** Models >4GB will partially offload to GPU and use system RAM for overflow, which is slower but still functional.

---

## Phase 5: Post-Migration Cleanup & Validation

### 5.1 Verify ACME Certificates

Traefik's `acme.json` should have survived intact on the `fast` pool. Check logs to confirm Traefik reused existing certificates (not requesting new ones):

```bash
docker logs traefik 2>&1 | grep -i "certificate\|acme" | head -20
```

Look for: `"Using existing ACME account"` or similar messages indicating cert reuse.

### 5.2 Test External Access

```bash
# Test Traefik routing
curl -I https://jellyfin.deercrest.info    # Should return 200 OK
curl -I https://immich.deercrest.info      # Should return 200 OK
curl -I https://homarr.deercrest.info      # Should return 200 OK
```

### 5.3 Remove Old TrueNAS Datasets (Optional)

**⚠️ Only after confirming everything works for 24+ hours:**

```bash
# TrueNAS Apps storage (ix-apps) — no longer needed
zfs list | grep ix-apps                    # Verify what will be destroyed
# zfs destroy -r fast/ix-apps              # Frees ~238GB

# TrueNAS system datasets
# zfs destroy -r fast/.system              # Frees ~2GB
```

Wait at least a week before destroying these — they contain no essential data but serve as a rollback safety net.

### 5.4 Git Configuration (if needed)

If git complains about safe directory:

```bash
git config --global --add safe.directory /mnt/fast/stacks
```

---

## Phase 6: Ongoing Proxmox Operations

### 6.1 ZFS Maintenance

Replace TrueNAS's automatic scrubs with Proxmox cron jobs:

```bash
# On Proxmox host (not LXC)
cat <<'EOF' >> /etc/cron.d/zfs-scrub
# ZFS scrubs: fast pool Sunday 3am, tank pool Sunday 4am
0 3 * * 0 root /sbin/zpool scrub fast
0 4 * * 0 root /sbin/zpool scrub tank
EOF
```

Optional: Install `sanoid` for automated ZFS snapshots:

```bash
apt install -y sanoid
# Configure /etc/sanoid/sanoid.conf per documentation
```

### 6.2 LXC Management Commands

```bash
# List all containers
pct list

# Container control
pct start 100
pct stop 100
pct restart 100

# Shell access
pct enter 100

# View logs
journalctl -u pve-container@100

# Backup/restore
vzdump 100 --dumpdir /mnt/tank/backups --mode snapshot
pct restore 100 /mnt/tank/backups/vzdump-lxc-100-*.tar.zst
```

### 6.3 Proxmox Web UI

Access at: `https://172.16.1.158:8006`

Default credentials: `root@pam` + password set during install

---

## Troubleshooting

### Issue: GPU Devices Show `nobody:nogroup` in LXC

**Symptom:** `ls -la /dev/dri/` inside LXC shows `nobody:nogroup` for `renderD128`

**Cause:** Host GID doesn't match idmap passthrough or `/etc/subgid` is missing delegation

**Fix:**

```bash
# On Proxmox host
getent group render           # Verify GID is 110
cat /etc/subgid | grep 110    # Should show: root:110:1

# If missing, add it:
echo 'root:110:1' >> /etc/subgid
pct stop 100 && pct start 100

# Force device ownership
chgrp render /dev/dri/renderD*
udevadm trigger /dev/dri/renderD*
```

### Issue: `iot_macvlan` Network Missing

**Symptom:** Jellyfin/Dispatcharr containers fail to start with "network not found"

**Cause:** Network wasn't created by terraform or was deleted

**Fix:**

```bash
# Inside LXC
docker network create -d macvlan \
  --subnet=172.16.1.0/24 \
  --gateway=172.16.1.1 \
  --ip-range=172.16.1.64/26 \
  -o parent=eth0 \
  iot_macvlan
```

### Issue: Git Operations Fail with "Permission denied (publickey)"

**Symptom:** `git pull` fails, SSH keys not found

**Cause:** SSH keys weren't copied from Proxmox host during terraform provisioning

**Fix:**

```bash
# On Proxmox host — verify keys exist
ls -la /root/.ssh/id_ed25519*

# If missing, copy from dev machine
# scp ~/.ssh/id_ed25519* root@172.16.1.158:/root/.ssh/

# Re-run terraform to deploy keys
cd infrastructure/proxmox
terraform apply -replace=null_resource.copy_ssh_keys

# Or manually copy into LXC
pct push 100 /root/.ssh/id_ed25519 /root/.ssh/id_ed25519
pct push 100 /root/.ssh/id_ed25519.pub /root/.ssh/id_ed25519.pub
pct exec 100 -- chmod 600 /root/.ssh/id_ed25519
```

### Issue: ZFS Child Datasets Not Visible in LXC

**Symptom:** `/mnt/fast/appdata/<service>` directories exist but are empty inside LXC

**Cause:** Proxmox bind mounts only show parent dataset, not children (each ZFS dataset has independent mount)

**Fix:** Terraform handles this automatically via `patch_lxc_config`. If manual fix needed:

```bash
# On Proxmox host
pct stop 100
zfs list -r -H -o name fast/appdata fast/home | while read ds; do
  case "$ds" in fast/appdata|fast/home) continue ;; esac
  mp="/mnt/$ds"
  grep -q "$mp" /etc/pve/lxc/100.conf || \
    echo "lxc.mount.entry: $mp ${mp#/} none bind,create=dir 0 0" >> /etc/pve/lxc/100.conf
done
pct start 100
```

### Issue: Terraform Provisioners Didn't Run / LXC Not Configured

**Symptom:** After `terraform apply`, LXC exists but:
- `/dev/dri/` doesn't exist inside LXC
- Docker is not installed
- `apps` user doesn't exist
- Networks not created

**Cause:** Terraform `null_resource` provisioners only run when the resource is **created**. If you ran
`terraform apply` after the LXC already existed (from a previous run), terraform sees the resources in
state and skips the provisioners.

**Fix:**

Force terraform to recreate the provisioner resources (this does NOT destroy the LXC itself):

```bash
cd infrastructure/proxmox
terraform apply \
  -replace=null_resource.patch_lxc_config \
  -replace=null_resource.start_lxc \
  -replace=null_resource.provision_lxc \
  -replace=null_resource.copy_ssh_keys
```

This re-runs the entire dependency chain:
1. **patch_lxc_config** — Adds GPU devices and idmap to `/etc/pve/lxc/100.conf`
2. **start_lxc** — Starts the LXC and enables SSH password auth
3. **provision_lxc** — Installs Docker, creates users/groups, configures networks
4. **copy_ssh_keys** — Deploys SSH keys from Proxmox host to LXC

**Important:** After the first successful deployment, if you need to modify terraform code or re-run
provisioners, you must use `-replace` for the specific resources you want to recreate. Plain `terraform apply`
will do nothing because terraform considers them already complete.

### Issue: Render Group Has Wrong GID Inside LXC

**Symptom:** 
- `ls -la /dev/dri/` shows `renderD128` as `nobody:110` (not `nobody:render`)
- `getent group render` shows `render:x:992` (or other number != 110)
- Jellyfin/Immich logs show "Permission denied" accessing `/dev/dri/renderD128`

**Cause:** Debian 13 creates the `render` group with a dynamic GID (typically 992) on first boot,
but the LXC idmap is configured to pass through host GID 110. The mismatch means the device appears
ownership belongs to a GID that has no matching group name.

**Fix:**

```bash
# Inside LXC
ssh root@172.16.1.159 'groupmod -g 110 render'

# Verify the fix
ssh root@172.16.1.159 'getent group render && ls -la /dev/dri/'
# Should show: render:x:110  and  renderD128 owned by nobody:render

# Add apps user to render group (if not already)
ssh root@172.16.1.159 'usermod -aG render apps && id apps'
```

**Why this happens:** The terraform provisioner creates groups in this order:
```bash
groupadd -g 44 video
groupadd -g 110 render    # ← Should work, but sometimes Debian creates it during boot first
groupadd -g 568 apps
```

If the LXC template already has a `render` group (with dynamic GID), `groupadd` silently fails and
the group keeps its original GID. The `groupmod` command forces the GID to change.

**Note:** This issue is now automatically fixed by terraform (commit 12fa0ac). The provisioner includes
`groupmod -g 110 render || true` to force the correct GID even if the group already exists.

### Issue: Terraform `HTTP 500 hostname lookup failed`

**Symptom:** `terraform apply` fails with "hostname lookup 'pve' failed - server offline?"

**Cause:** `proxmox_node` in `terraform.tfvars` doesn't match actual hostname

**Fix:**

```bash
# Check actual hostname
ssh root@172.16.1.158 'hostname'    # Returns: atlantis (or your choice)

# Update terraform.tfvars
proxmox_node = "atlantis"  # Must match exactly
```

### Issue: Containers Can't Access GPU

**Symptom:** Jellyfin/Immich logs show "Cannot open /dev/dri/renderD128: Permission denied"

**Cause:** Container user not in `render` group, or group_add incorrect

**Fix:**

```bash
# Verify compose file has correct GID
grep -A5 group_add media/jellyfin.yaml
# Should show: group_add: ["44", "110"]

# Recreate container (restart is not enough)
docker compose -f media/compose.yaml up -d --force-recreate jellyfin

# Verify inside container
docker exec jellyfin ls -la /dev/dri/
docker exec jellyfin id jellyfin
# User should be member of groups: 44(video), 110(render)
```

### Issue: n8n Container Restarts with "EACCES: permission denied, mkdir '/home/node/.n8n'"

**Symptom:** n8n container continuously restarts with permission errors:
```
Error: EACCES: permission denied, mkdir '/home/node/.n8n'
Error: EACCES: permission denied, open '/home/node/.n8n/config'
```

**Cause:** When running n8n with `user: "568:568"` override, the container's `/home/node` directory is owned by root (from the base image where user `node` is UID 1000). User 568 cannot write to `/home/node` to create the `.n8n` subdirectory, even though the volume mount for `/home/node/.n8n` exists.

**Root Issue:** Docker volume mounts can only override specific paths, not their parent directories. The mount for `/home/node/.n8n` doesn't help if the user can't traverse `/home/node` itself.

**Fix:** Mount `/home/node` as a separate volume owned by user 568:

```bash
# Create home directory on host
ssh root@172.16.1.159 "mkdir -p /mnt/fast/appdata/automation/n8n-home && chown 568:568 /mnt/fast/appdata/automation/n8n-home"

# Update automation/n8n.yaml volumes section:
volumes:
  # Mount /home/node to give user 568 ownership of home directory
  - /mnt/fast/appdata/automation/n8n-home:/home/node
  - /mnt/fast/appdata/automation/n8n:/home/node/.n8n
  - /mnt/fast/appdata/automation/n8n/cache:/home/node/.cache
  # ... other mounts

# Recreate container
cd /mnt/fast/stacks/automation
docker compose down n8n
docker compose up -d n8n
```

**Verification:**
```bash
# Check container is running (not restarting)
docker ps --filter name=n8n
# Should show: Up X seconds (not "Restarting")

# Check n8n logs for successful startup
docker logs n8n 2>&1 | tail -20
# Should see workflow activation messages, not EACCES errors
```

**Note:** This pattern applies to any container where:
1. You override the user with `user: "UID:GID"` different from the image default
2. The application needs to write to its home directory
3. The home directory's parent path is owned by a different user in the base image

---

## Rollback & Safety

### Data Safety Guarantees

- **ZFS pools (`fast`, `tank`)** are on physically separate drives (`nvme1n1`, `nvme2n1`, `sda-c`) from the Proxmox OS (`nvme0n1`)
- Installing Proxmox **only touches `nvme0n1`** (destroys TrueNAS boot-pool)
- If Proxmox install fails, pools remain intact and can be imported on any Debian/Ubuntu live USB

### Emergency Rollback

If critical issues arise within first 48 hours:

1. **Boot TrueNAS SCALE USB installer again**
2. **Reinstall to `nvme0n1`** (overwrites Proxmox)
3. **Import pools:** `zpool import fast && zpool import tank`
4. **Fix mountpoints:** `zfs set mountpoint=/mnt/fast fast && zfs set mountpoint=/mnt/tank tank`
5. **Restore settings:** Extract from `/mnt/fast/home/backup-truenas-*.tar.gz`
6. **Start Docker stacks** (all `.env` files and appdata survived)

### Backup Before Destroying Old Datasets

Before running `zfs destroy -r fast/ix-apps`, take one final backup:

```bash
zfs snapshot fast/ix-apps@pre-delete
# If you need to roll back: zfs rollback fast/ix-apps@pre-delete
# Delete snapshot later: zfs destroy fast/ix-apps@pre-delete
```

---

## Validation Checklist

After completing all phases, verify these items:

- [ ] Proxmox host has correct groups: `getent group apps video render`
- [ ] ZFS pools mount at boot: `systemctl status zfs-import-cache zfs-mount`
- [ ] LXC starts automatically: `pct config 100 | grep onboot`
- [ ] GPU devices visible in LXC: `ssh root@172.16.1.159 'ls -la /dev/dri/'`
- [ ] Docker daemon running: `ssh root@172.16.1.159 'docker info'`
- [ ] Networks exist: `ssh root@172.16.1.159 'docker network ls | grep -E "t3_proxy|iot_macvlan"'`
- [ ] Git repo accessible: `ssh root@172.16.1.159 'git -C /mnt/fast/stacks status'`
- [ ] SSH keys deployed: `ssh root@172.16.1.159 'ssh -T git@github.com'`
- [ ] All containers running: `ssh root@172.16.1.159 'docker ps -a | grep -v Up'` (should return nothing)
- [ ] GPU acceleration working: `ssh root@172.16.1.159 'docker exec jellyfin vainfo --display drm --device /dev/dri/renderD128'`
- [ ] Traefik certificates valid: `curl -I https://jellyfin.deercrest.info`
- [ ] External services accessible via HTTPS
- [ ] ZFS scrubs scheduled: `cat /etc/cron.d/zfs-scrub`

---

## Summary: What Changed

| Component | TrueNAS SCALE | Proxmox VE 9.1 | Notes |
|-----------|---------------|----------------|-------|
| OS | TrueNAS SCALE 25.10 (Debian 12) | Proxmox VE 9.1 (Debian 13) | Debian upgrade changes default group GIDs |
| Container Runtime | Docker CE in privileged jail | Docker CE in unprivileged LXC | Safer isolation, requires idmap |
| GPU Access | Direct passthrough | LXC idmap passthrough (video:44, render:110) | render group moved from 105→110 to avoid tcpdump/postdrop conflicts |
| Management | TrueNAS Web UI | Proxmox Web UI + Terraform IaC | Infrastructure as Code for reproducibility |
| Networking | macvlan on host | macvlan inside LXC (iot_macvlan) | Same IP scheme, compatible with existing firewall rules |
| ZFS Management | TrueNAS GUI | CLI + Proxmox GUI | More control, same ZFS features |
| SSH Keys | Manually managed | Terraform-deployed via pct push | Automated deployment from Proxmox→LXC |
| Docker Networks | Manually created | Terraform provisioner creates | Fully automated setup |

**Key Benefit:** Entire infrastructure is now defined in Terraform — can recreate from scratch in <10 minutes with `terraform apply`.
