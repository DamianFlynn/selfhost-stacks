# Migration: TrueNAS SCALE 25.10 → Proxmox VE 9.1

> **Phases 2–4 below are now automated by Terraform.**
> After completing Phase 1 (Proxmox install), run:
>
> ```bash
> cd infrastructure/proxmox
> cp terraform.tfvars.example terraform.tfvars   # fill in passwords + SSH key
> terraform init && terraform apply
> ```
>
> Terraform handles: ZFS pool import, apps user/groups, subuid/subgid, LXC creation,
> idmap + GPU passthrough config patch, Docker CE install, and SDL2 deps for OpenClaw.
> The manual steps in Phases 2–4 are kept below as reference / fallback only.

### Terraform `terraform.tfvars` — known gotchas

Before running `terraform apply`, verify three things in your `terraform.tfvars`:

**1. `proxmox_node` must match the actual Proxmox hostname**

The node name is whatever hostname you set during the Proxmox installer — NOT always `pve`.
Verify with:

```bash
ssh root@172.16.1.158 'hostname'    # or: pvecm nodename
```

If it returns `atlantis` (or anything other than `pve`), set:

```hcl
proxmox_node = "atlantis"
```

Symptom if wrong: `HTTP 500 - hostname lookup 'pve' failed`.

**2. `lxc_template` must exactly match what `pveam` knows about**

The template filename changes with each Debian release. Check what's currently available:

```bash
ssh root@172.16.1.158 'pveam update && pveam available --section system | grep debian-13'
```

Use the exact filename returned (e.g. `debian-13-standard_13.1-2_amd64.tar.zst`).

Symptom if wrong: `400 Parameter verification failed. template: no such template`.

**3. Your SSH private key must be in the macOS SSH agent**

Terraform provisioners use the SSH agent, not key files directly. Before running apply:

```bash
ssh-add -l                                          # check what's loaded
ssh-add --apple-use-keychain ~/.ssh/id_ed25519      # add if missing
```

The public key in `lxc_ssh_public_keys` / `terraform_ssh_private_key_path` must match.

Symptom if missing: provisioner loops on "Connecting to remote host via SSH..." or gets
`SSH authentication failed: attempted methods [none password publickey], no supported methods remain`.

**4. `render` group GID on Debian 13 is dynamic (~993), not the static 110**

Debian 13 assigns the `render` group a dynamic GID (e.g. `993`) instead of a static value.
Additionally, GID 103 is taken by `tcpdump` and GID 105 is taken by `postdrop` on Proxmox/Debian.
The idmap in `lxc-selfhost.tf` requires `video(44) < render < apps(568)`,
so `render_gid = 993` is **not** usable — it would break the idmap math.

Fix the host before running `terraform apply`:

```bash
getent group 110           # confirm 110 is not already taken
groupmod -g 110 render     # reassign render to the expected static GID
udevadm trigger /dev/dri/renderD128
ls -lan /dev/dri/          # verify renderD128 now shows GID 110
```

Symptom if skipped: `renderD128` inside the LXC appears owned by `nobody:nogroup`
and GPU-accelerated containers (Jellyfin, Immich ML) can't open the device.

**5. ZFS child datasets require individual bind mounts**

Proxmox's `mp<N>` bind mount for `/mnt/fast/appdata` covers only the parent ZFS dataset.
Every `fast/appdata/<service>` is a *separate* ZFS child dataset with its own mount — they
are invisible to the LXC through a plain bind mount (the directories exist but appear empty).

Terraform's `patch_lxc_config` handles this automatically by iterating `zfs list` and
writing an `lxc.mount.entry` for each child.  If you ever need to fix this manually:

```bash
pct stop 100
zfs list -r -H -o name fast/appdata fast/home | while read ds; do
  case "$ds" in fast/appdata|fast/home) continue ;; esac
  mp="/mnt/$ds"
  echo "lxc.mount.entry: $mp ${mp#/} none bind,create=dir 0 0" >> /etc/pve/lxc/100.conf
done
pct start 100
```

---

## Hardware Context

| Drive | Device | Size | Role |
|-------|--------|------|------|
| Kingston SNV3S500G | `nvme0n1` | 465 GB | TrueNAS boot-pool → **Proxmox OS target** |
| Samsung 990 EVO Plus × 2 | `nvme1n1`, `nvme2n1` | 1.8 TB each | `fast` pool (mirror) — **untouched** |
| Seagate ST26000NM × 3 | `sda`, `sdb`, `sdc` | 23.6 TB each | `tank` pool (raidz1) — **untouched** |

**Data is 100% safe**: the `fast` and `tank` pools live on different drives from the OS. Installing Proxmox to `nvme0n1` only destroys the TrueNAS boot-pool.

---

## Pre-Migration Checklist (on TrueNAS while running)

### 1. Verify git repo is fully committed

```bash
# On your dev machine
git -C /path/to/selfhost-stacks status
git -C /path/to/selfhost-stacks push
```

### 2. Back up all `.env` files to a safe location

`.env` files live on `fast/stacks` (which survives), but take an extra copy:

```bash
# On TrueNAS
find /mnt/fast/stacks -name '.env' | while read f; do
  echo "=== $f ==="; cat "$f"; echo
done > ~/env-backup-$(date +%Y%m%d).txt
```

Copy that file off-box (to your dev machine or another server) — it contains all secrets.

### 3. Record the Traefik ACME certificate info

The `acme.json` at `/mnt/fast/appdata/traefik/acme/acme.json` is on the `fast` pool and will survive. Just confirm the file exists and is non-empty:

```bash
wc -c /mnt/fast/appdata/traefik/acme/acme.json  # should be >1KB
```

### 4. Export current ZFS pool GUIDs (for safe import later)

```bash
zpool get guid fast tank boot-pool
```

NAME       PROPERTY  VALUE                 SOURCE
boot-pool  guid      9529240032720272052   -
fast       guid      12508074045973134637  -
tank       guid      6438135609734591747   -


Save that output — if you ever need `-f` (force) on import, these confirm you have the right pools.

### 5. Note the `apps` user/group IDs

```bash
id apps       # expect: uid=568(apps) gid=568(apps)
getent group render video   # render:x:110  video:x:44
```
❯ id apps
uid=568(apps) gid=568(apps) groups=568(apps)

damian in 🌐 truenas in ~ 
❯ getent group render video 
render:x:107:
video:x:44:

### 6. Back up personal dotfiles, SSH keys, and shell settings


Everything on the TrueNAS **boot pool** (`nvme0n1`) will be wiped — this includes `/root/`,
`/home/damian/`, crontabs, and SSH host keys. Run the backup script to capture them to the
`fast` pool before the wipe:

```bash
# From your dev machine — no need to copy anything to TrueNAS first
ssh root@<truenas-ip> 'bash -s' < scripts/backup-truenas-settings.sh
```

This saves two copies to `/mnt/fast/home/` (which survives the Proxmox install):

- **Directory**: `/mnt/fast/home/.backup-truenas-YYYYMMDD-HHMM/`
- **Tarball**: `/mnt/fast/home/backup-truenas-YYYYMMDD-HHMM.tar.gz`

What gets captured:

| Category | Paths |
|----------|-------|
| SSH keys | `~/.ssh/` for root + damian |
| SSH host keys | `/etc/ssh/ssh_host_*` (optional restore — keeps server fingerprint) |
| Shell configs | `.bashrc` `.zshrc` `.profile` `.bash_history` etc. |
| Git | `.gitconfig` `.gitconfig.local` `.gitignore_global` |
| GPG | `.gnupg/` |
| App config | `.config/` |
| Editor | `.vimrc` `.vim/` `.tmux.conf` `.nanorc` |
| Crontabs | `crontab -l` for root + damian; `/etc/cron.d/` |
| `.env` files | All stack `.env` files (belt-and-suspenders copy alongside fast pool originals) |

After the script finishes, confirm the backup exists:

```bash
ssh root@<truenas-ip> "ls -lh /mnt/fast/home/backup-truenas-*.tar.gz"
```

### 7. Stop all services and cleanly export ZFS pools — LAST STEP BEFORE SHUTDOWN

A clean `zpool export` flushes all pending writes and marks the pools as unmounted.
This means Proxmox can import them with a plain `zpool import` — **no `-f` force flag needed**,
no hostid mismatch warnings.

**Do this immediately before shutting TrueNAS down. Nothing else uses the pools after this point.**

```bash
# On TrueNAS — stop all Docker workloads first
# (TrueNAS Apps UI: stop every app, or run this to stop all containers)
docker stop $(docker ps -q) 2>/dev/null || true

# Confirm nothing has the pools open
lsof /mnt/fast /mnt/tank 2>/dev/null | grep -v COMMAND || echo "pools are idle"

# Export both pools
zpool export fast
zpool export tank

# Confirm export succeeded (both should now show as EXPORTED or not listed)
zpool status fast 2>&1
zpool status tank 2>&1
# Expected: "cannot open 'fast': no such pool" — that means clean export

# Now power off
shutdown -h now
```

> If `zpool export` refuses because something still has the pool open, check `lsof /mnt/fast`
> and stop the offending process, then retry. As a last resort you can `zpool export -f fast`
> (force-export) which is still cleaner than a cold shutdown with no export at all.

---

## Phase 1: Install Proxmox VE 9.1

### 1.1 Boot from USB

Create a Proxmox VE 9.1 USB (Rufus/Balena Etcher → ISO mode, not DD).

### 1.2 Disk selection — the critical step

When the installer shows the disk selector, choose:

```
Target disk: /dev/nvme0n1   (Kingston SNV3S500G, 465.8 GB)
```

**Do NOT select `nvme1n1`, `nvme2n1`, `sda`, `sdb`, or `sdc`.**

Use the default filesystem (ext4 or ZFS — either works; Proxmox will create its own ZFS pool named `rpool` on `nvme0n1` if you choose ZFS, or use LVM otherwise).

Recommended: choose **ZFS (RAID0)** on just `nvme0n1` for the Proxmox OS. This gives you full ZFS features on the boot drive without touching your data drives.

### 1.3 Network configuration during install

| Field | Value |
|-------|-------|
| Management interface | `eno1` |
| Hostname | `pve.deercrest.info` (or your choice) |
| IP Address | `172.16.1.158/24` ← Proxmox management, new IP |
| Gateway | `172.16.1.1` |
| DNS | `172.16.1.1` (or your DNS) |

The Docker LXC will get `172.16.1.159` (same IP as TrueNAS had), so existing firewall rules and DNS entries continue to work.

---

## Phase 2: First Boot — ZFS Pools & Basic Proxmox Config *(automated by Terraform `host.tf`)*

SSH into Proxmox: `ssh root@172.16.1.158`

### 2.1 Configure package repos (remove enterprise subscription nag)

PVE 9.x ships **two sets** of enterprise source files: legacy `.list` format and the newer
DEB822 `.sources` format. Both must be disabled or `apt-get update` returns 401 errors.

```bash
# Overwrite the legacy .list files with a comment
echo "# pve-enterprise disabled" > /etc/apt/sources.list.d/pve-enterprise.list
echo "# ceph-enterprise disabled" > /etc/apt/sources.list.d/ceph.list

# Rename (disable) the DEB822 .sources files — these are what PVE 9.x actually reads
mv /etc/apt/sources.list.d/pve-enterprise.sources \
   /etc/apt/sources.list.d/pve-enterprise.sources.disabled
mv /etc/apt/sources.list.d/ceph.sources \
   /etc/apt/sources.list.d/ceph.sources.disabled

# Add no-subscription repo — PVE 9.x is based on Debian trixie, NOT bookworm (that was PVE 8.x)
echo "deb http://download.proxmox.com/debian/pve trixie pve-no-subscription" \
  > /etc/apt/sources.list.d/pve-no-subscription.list

apt-get update && apt-get full-upgrade -y
```

### 2.2 Import the ZFS data pools

If you ran `zpool export` in pre-migration step 7, the pools import cleanly with no flags:

```bash
zpool import fast
zpool import tank
```

If you see a **hostid mismatch** error (pools were not cleanly exported before shutdown):

```bash
zpool import -f fast
zpool import -f tank
```

> **TrueNAS altroot quirk** — TrueNAS SCALE imports pools with an implicit altroot of `/mnt`,
> which means the pool's stored mountpoint is `/<pool>` but it physically appeared at
> `/mnt/<pool>`. On Proxmox there is no altroot, so the pools mount at `/fast` and `/tank`
> instead of `/mnt/fast` and `/mnt/tank`. Fix this immediately after import:

```bash
zfs set mountpoint=/mnt/fast fast
zfs set mountpoint=/mnt/tank tank
```

This permanently changes the mountpoint stored in the pool and atomically remounts the root
dataset and all child datasets that inherit their mountpoint (e.g. `fast/appdata`,
`fast/stacks`, etc.) in one step. No reboot needed.

Verify both pools are now mounted at the correct paths:

```bash
ls /mnt/               # should show: fast  tank
zfs get mountpoint fast tank
# Expected:
#   fast  mountpoint  /mnt/fast  local
#   tank  mountpoint  /mnt/tank  local

df -h | grep mnt       # should show /mnt/fast and /mnt/tank and all child datasets
```

### 2.3 Register pools with Proxmox so they import at boot

```bash
zpool set cachefile=/etc/zfs/zpool.cache fast
zpool set cachefile=/etc/zfs/zpool.cache tank

# Enable the ZFS import service
systemctl enable zfs-import-cache.service
systemctl enable zfs-mount.service
```

### 2.4 Create the `apps` group and user on the Proxmox host

This must match the UIDs in the ZFS datasets. Privileged LXC uses 1:1 UID mapping.

```bash
groupadd -g 568 apps
# -r (system account) is required — Proxmox/Debian rejects UIDs below UID_MIN (1000)
# without it, even when the UID is explicitly specified.
useradd -r -u 568 -g 568 -M -s /usr/sbin/nologin apps

# GPU groups (must match device ownership in /dev/dri)
# Check actual device names on this machine first — the card may be card1, not card0:
ls -la /dev/dri/
# This machine: card1 (root:video, gid 44) and renderD128 (root:render, gid 110)
# If those groups/GIDs don't exist on Proxmox host, create them:
getent group video  || groupadd -g 44 video
getent group render || groupadd -g 110 render
```

### 2.5 Restore correct permissions on appdata

TrueNAS should have had these correct already, but confirm:

```bash
# appdata and stacks: apps:apps, group-writable
chown -R apps:apps /mnt/fast/appdata /mnt/fast/stacks
find /mnt/fast/appdata /mnt/fast/stacks -type d -exec chmod 2775 {} \;
find /mnt/fast/appdata /mnt/fast/stacks -type f -exec chmod 0664 {} \;

# Postgres data dir is the exception: must be postgres:postgres 700
# Do NOT chown the postgres dir above — skip it or fix it after:
chown -R 999:999 /mnt/fast/appdata/immich/postgres
chmod 700 /mnt/fast/appdata/immich/postgres
```

---

## Phase 3: Create the Docker LXC *(automated by Terraform `lxc-selfhost.tf`)*

### 3.1 Download Ubuntu 24.04 LTS template

```bash
pveam update
pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst
# Verify download:
pveam list local
```

### 3.2 Create a privileged LXC

Privileged is required for:
- Docker (no nested namespace issues)
- GPU passthrough (direct device binding with correct GIDs)
- 1:1 UID mapping (files owned by apps/568 work without remapping)

```bash
pct create 100 local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst \
  --hostname selfhost \
  --arch amd64 \
  --ostype ubuntu \
  --cores 8 \
  --memory 16384 \
  --swap 0 \
  --rootfs local-lvm:64 \
  --net0 name=eth0,bridge=vmbr0,ip=172.16.1.159/24,gw=172.16.1.1 \
  --nameserver 172.16.1.1 \
  --unprivileged 0 \
  --features nesting=1 \
  --start 0
```

Adjust `--cores`, `--memory`, and the rootfs size (`64` = 64 GB) for your needs. The N5 Pro has sufficient RAM/CPU to give the LXC nearly everything.

### 3.3 Add GPU passthrough and ZFS bind mounts to the LXC config

Edit `/etc/pve/lxc/100.conf` and append:

```
# AMD GPU passthrough (VAAPI for Jellyfin/Immich)
# This machine: card1 (226:1) + renderD128 (226:128)
# NOTE: card and render indices are INDEPENDENT — renderD is NOT always renderD(128+card_index).
# Always verify with: ls -la /dev/dri/
lxc.cgroup2.devices.allow: c 226:1 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/card1 dev/dri/card1 none bind,optional,create=file
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file

# ZFS dataset bind mounts
lxc.mount.entry: /mnt/fast/stacks mnt/fast/stacks none bind,create=dir
lxc.mount.entry: /mnt/fast/appdata mnt/fast/appdata none bind,create=dir
lxc.mount.entry: /mnt/fast/home mnt/fast/home none bind,create=dir
lxc.mount.entry: /mnt/fast/transcode mnt/fast/transcode none bind,create=dir
lxc.mount.entry: /mnt/fast/tools mnt/fast/tools none bind,create=dir
lxc.mount.entry: /mnt/tank mnt/tank none bind,create=dir
```

These paths must exist on the Proxmox host before starting the LXC.

### 3.4 Start the LXC

```bash
pct start 100
pct enter 100   # opens a shell inside the container
```

---

## Phase 4: Inside the LXC — Users, Docker, GPU *(automated by Terraform `lxc-selfhost.tf`)*

All commands in this section run **inside** the LXC (`pct enter 100`).

### 4.1 OS baseline

```bash
apt update && apt upgrade -y
apt install -y curl git ca-certificates gnupg lsb-release \
  libva-utils vainfo intel-gpu-tools   # vainfo/vaapi tools for testing GPU
```

### 4.2 Create `apps` user and GPU groups

```bash
# Must match host GIDs (568 for apps, 44 for video, 110 for render)
groupadd -g 568 apps
# -r required: Debian rejects UIDs below UID_MIN 1000 without system-account flag
useradd -r -u 568 -g 568 -M -s /usr/sbin/nologin apps

getent group video  || groupadd -g 44  video
getent group render || groupadd -g 110 render

# Verify /dev/dri devices are visible and have correct ownership
ls -la /dev/dri/
# This machine: card1 (root:video) and renderD129 (root:render)
```

### 4.3 Install Docker CE

```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add apps user to docker, video, render groups
usermod -aG docker,video,render apps

systemctl enable docker
systemctl start docker
```

### 4.4 Configure Docker daemon for IPv6 and performance

Create `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "userland-proxy": false
}
```

```bash
systemctl restart docker
```

### 4.5 Test GPU access

```bash
# As root inside LXC — this machine: card1 + renderD128
vainfo --display drm --device /dev/dri/renderD128
# Should show AMD VAAPI profiles (H264, HEVC, AV1, etc.)

# Test Docker can access GPU
docker run --rm --device /dev/dri/card1 --device /dev/dri/renderD128 \
  debian:13 ls -la /dev/dri/
```

### 4.6 Restore personal settings from the TrueNAS backup

The backup created in Pre-Migration step 6 is available via the `/mnt/fast/home` bind mount.
Run the restore script inside the LXC:

```bash
# From your dev machine
ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/restore-settings-to-lxc.sh'
```

The script:
- Auto-detects the most recent backup under `/mnt/fast/home/.backup-truenas-*/`
- Restores `/root/.ssh/`, shell configs, `.gitconfig`, `.gnupg/`, `.config/` for root
- Creates the `damian` user (home at `/mnt/fast/home/damian` — persists across LXC rebuilds)
- Restores all of the above for damian with correct permissions
- **Prompts** before restoring SSH host keys (say yes to keep the old server fingerprint) and crontabs

Verify after restore:

```bash
ssh root@172.16.1.159 "ls -la /root/.ssh && git -C /mnt/fast/stacks status"
```

### 4.7 Create Traefik Docker network (prerequisite for stacks)

The `t3_proxy` network is defined in `traefik/compose.yaml` but all other stacks declare it as `external: true`, so it must exist before other stacks start:

```bash
# Start traefik stack first — it creates t3_proxy and socket_proxy
cd /mnt/fast/stacks/traefik
docker compose up -d
```

Verify: `docker network ls | grep -E 't3_proxy|socket_proxy'`

---

## Phase 5: Bring Up the Stacks

All stacks live at `/mnt/fast/stacks/` — already on the `fast` pool, already in git, `.env` files already there from TrueNAS.

```bash
# Start stacks in dependency order
cd /mnt/fast/stacks

# 1. Infrastructure first (Traefik/Authelia creates t3_proxy)
docker compose -f traefik/compose.yaml up -d

# 2. Media acquisition
docker compose -f arrs/compose.yaml up -d

# 3. Media serving
docker compose -f media/compose.yaml up -d

# 4. Photo library
docker compose -f immich/compose.yaml up -d

# 5. Everything else
for stack in automation code-server freshrss karakeep keeper-sh openwebui; do
  docker compose -f $stack/compose.yaml up -d
done
```

Check all containers are healthy:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort
```

---

## Post-Migration Cleanup

### Remove TrueNAS-specific ZFS datasets (optional, when confident)

These are no longer needed after migration but contain no important data:

```bash
# TrueNAS Apps internal storage (ix-apps)
# WARNING: verify Proxmox is fully running before destroying anything
# zfs destroy -r fast/ix-apps     # ~238GB of old TrueNAS Docker data
# zfs destroy -r fast/.system     # ~2GB TrueNAS system datasets
```

Do this only **after** you've confirmed all stacks are healthy on Proxmox.

### ACME certificate validation

Traefik's `acme.json` survived intact on `fast/appdata/traefik`. Verify Traefik started without requesting new certs (check logs for "Using existing certificate"):

```bash
docker logs traefik 2>&1 | grep -i "acme\|certif\|tls" | head -20
```

### Update CLAUDE.md repo reference

The git repo is now accessed at:
- Host path: `/mnt/fast/stacks` (via bind mount)
- LXC path: `/mnt/fast/stacks` (same path)

`git config --global --add safe.directory /mnt/fast/stacks`

---

## Ongoing: Proxmox-Specific Operations

### ZFS scrubs (replace TrueNAS scheduled scrubs)

```bash
# Add to Proxmox crontab (runs on Proxmox host, not LXC)
echo "0 3 * * 0 root zpool scrub fast" >> /etc/cron.d/zfs-scrub
echo "0 4 * * 0 root zpool scrub tank" >> /etc/cron.d/zfs-scrub
```

### ZFS snapshots (replace TrueNAS periodic snapshots)

Proxmox has a built-in ZFS snapshot tool, or use `sanoid`:

```bash
apt install -y sanoid
# Configure /etc/sanoid/sanoid.conf per sanoid docs
```

### LXC management

```bash
pct list                    # show all containers
pct start/stop/restart 100  # manage the Docker LXC
pct enter 100               # shell into LXC
```

### Proxmox web UI

Access at: `https://172.16.1.158:8006`

---

## Rollback Plan

If anything goes wrong before you destroy TrueNAS data:

1. **Proxmox ZFS pool import failed**: Boot a live Linux USB, run `zpool import -f fast` to verify pools are intact before proceeding
2. **LXC won't start**: Check Proxmox host for bind mount path issues (`pct start 100 2>&1`)
3. **Docker stacks broken**: The `.env` files and appdata are all on `fast` pool — re-installing TrueNAS to `nvme0n1` and re-importing the pools restores everything to the previous state

The data pools are on completely separate physical drives from the OS install target. There is no scenario where installing Proxmox to `nvme0n1` destroys any data.
