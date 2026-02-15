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
lxc_template       = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"  # ⚠️ Verify: pveam available --section system | grep ubuntu-24

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
ssh root@172.16.1.158 'pveam available --section system | grep ubuntu-24.04'

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
2. Download Ubuntu 24.04 LXC template
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

### 3.4 Verify Deployment

```bash
# Test LXC access
ssh root@172.16.1.159

# Inside LXC, verify:
docker info | grep -E 'Storage Driver|Cgroup'   # Should show: overlay2, systemd, v2
ls -la /dev/dri/                                 # Should show: card1, renderD128
id apps                                          # uid=568, groups: 568(apps),44(video),110(render),991(docker)
docker network ls | grep iot_macvlan             # Should exist
ls /mnt/fast/stacks                              # Should show git repo
git -C /mnt/fast/stacks status                   # Should work (SSH keys deployed)

# Test GPU hardware acceleration
docker run --rm --device /dev/dri/card1 --device /dev/dri/renderD128 --group-add video --group-add render \
  debian:13 ls -la /dev/dri/
```

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

# 5. All other stacks
for stack in automation code-server dawarich freshrss homarr karakeep keeper-sh minecraft openwebui podsync postiz teleport termix; do
  docker compose -f $stack/compose.yaml up -d
done
```

```bash
# Check containers are healthy
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort
```

### 4.4 Verify GPU Hardware Acceleration

```bash
# Test Jellyfin GPU access
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

# Test Immich ML (if using GPU)
docker logs immich-machine-learning | grep -i "gpu\|cuda\|device"
```

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
