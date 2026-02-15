# lxc-selfhost.tf — Docker LXC: creation, idmap patch, Docker provisioning
#
# Phase ordering (critical — idmap must be in place before first boot):
#
#   1. proxmox_virtual_environment_container.selfhost  [started=false]
#      Declares the container with bind mounts. GPU device_passthrough is NOT
#      set here because of a bpg/proxmox bug where that block is silently
#      ignored on initial create. It is patched in step 2 instead.
#
#   2. null_resource.patch_lxc_config  [depends_on: container]
#      SSH to Proxmox host; patches /etc/pve/lxc/<vmid>.conf with:
#        - lxc.idmap lines (uid/gid passthrough for apps + GPU groups)
#        - lxc.cgroup2.devices.allow for AMD DRI devices (226:0, 226:128)
#        - lxc.mount.entry for card0 and renderD128
#
#   3. null_resource.start_lxc  [depends_on: patch]
#      SSH to Proxmox host; runs pct start and waits for LXC SSH to open.
#
#   4. null_resource.provision_lxc  [depends_on: start_lxc]
#      SSH directly to the LXC; installs Docker CE, creates apps user/groups,
#      writes daemon.json, enables docker, and marks git safe.directory.

# ── Computed idmap ranges ────────────────────────────────────────────────────
#
# The three special GIDs to pass through are: video < render < apps
# (44 < 110 < 568 with the defaults). The locals below compute the
# contiguous range boundaries so the idmap lines adapt if variables change.
#
# UID mapping (only apps uid is special):
#   u 0       100000            apps_uid           (0 … apps_uid-1  → container-mapped)
#   u apps_uid apps_uid         1                  (apps passthrough)
#   u apps_uid+1 100000+apps_uid+1  65536-apps_uid-1  (remainder)
#
# GID mapping (video, render, apps are all special):
#   g 0          100000           video_gid                (0 … video_gid-1)
#   g video_gid  video_gid        1                        (video passthrough)
#   g video_gid+1 100000+v+1      render_gid-video_gid-1   (video+1 … render-1)
#   g render_gid render_gid       1                        (render passthrough)
#   g render_gid+1 100000+r+1     apps_gid-render_gid-1    (render+1 … apps-1)
#   g apps_gid  apps_gid          1                        (apps passthrough)
#   g apps_gid+1 100000+a+1       65536-apps_gid-1         (remainder)

locals {
  # UID ranges
  u_r1_start = 0
  u_r1_host  = 100000
  u_r1_count = var.apps_uid # 568

  u_r2_start = var.apps_uid
  u_r2_host  = var.apps_uid
  u_r2_count = 1

  u_r3_start = var.apps_uid + 1
  u_r3_host  = 100000 + var.apps_uid + 1 # 100569
  u_r3_count = 65536 - var.apps_uid - 1  # 64967

  # GID ranges
  g_r1_start = 0
  g_r1_host  = 100000
  g_r1_count = var.video_gid # 44

  g_r2_start = var.video_gid
  g_r2_host  = var.video_gid
  g_r2_count = 1

  g_r3_start = var.video_gid + 1
  g_r3_host  = 100000 + var.video_gid + 1         # 100045
  g_r3_count = var.render_gid - var.video_gid - 1 # 58

  g_r4_start = var.render_gid
  g_r4_host  = var.render_gid
  g_r4_count = 1

  g_r5_start = var.render_gid + 1
  g_r5_host  = 100000 + var.render_gid + 1       # 100104
  g_r5_count = var.apps_gid - var.render_gid - 1 # 464

  g_r6_start = var.apps_gid
  g_r6_host  = var.apps_gid
  g_r6_count = 1

  g_r7_start = var.apps_gid + 1
  g_r7_host  = 100000 + var.apps_gid + 1 # 100569
  g_r7_count = 65536 - var.apps_gid - 1  # 64967

  conf = "/etc/pve/lxc/${var.lxc_vmid}.conf"

  # GPU device names and cgroup2 minor numbers.
  # card and render indices are INDEPENDENT — do not assume renderD = renderD(128+card).
  # Verify on the Proxmox host: ls -la /dev/dri/
  # This machine: card1 (226:1) + renderD128 (226:128)
  gpu_card         = "card${var.gpu_card_index}"
  gpu_render       = "renderD${var.gpu_render_index}"
  gpu_card_minor   = var.gpu_card_index
  gpu_render_minor = var.gpu_render_index
}

# ── Phase 1: LXC container (started=false) ───────────────────────────────────

resource "proxmox_virtual_environment_container" "selfhost" {
  depends_on = [null_resource.host_setup]

  node_name   = var.proxmox_node
  vm_id       = var.lxc_vmid
  description = "Docker selfhost — all compose stacks"

  # Container starts stopped; null_resource.start_lxc boots it after the
  # config patch (idmap + GPU) has been written to disk.
  started      = false
  unprivileged = true

  features {
    nesting = true # required for Docker-in-LXC on PVE 9.1
    fuse    = true # required for overlay2 storage driver (Linux 6.12+)
  }

  initialization {
    hostname = var.lxc_hostname

    dns {
      servers = [var.nameserver]
    }

    ip_config {
      ipv4 {
        address = "${var.lxc_ip}/24"
        gateway = var.lxc_gateway
      }
    }

    user_account {
      password = var.lxc_root_password
      keys     = var.lxc_ssh_public_keys
    }
  }

  cpu {
    cores = var.lxc_cores
  }

  memory {
    dedicated = var.lxc_memory_mb
    swap      = 0
  }

  operating_system {
    template_file_id = "${var.template_storage}:vztmpl/${var.lxc_template}"
    type             = "debian"
  }

  disk {
    datastore_id = var.lxc_storage
    size         = var.lxc_disk_gb
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  # ── Bind mounts — identical paths to TrueNAS ──────────────────────────────
  # All compose files reference /mnt/fast/... and /mnt/tank/... directly.
  # Using the same paths here means zero changes to any stack after migration.

  # ── ZFS bind mounts ──────────────────────────────────────────────────────
  # IMPORTANT: Each fast/appdata/* and fast/home/* is a SEPARATE ZFS child dataset.
  # Proxmox's mp<N> bind mounts use uid/gid shifting for unprivileged containers;
  # raw lxc.mount.entry bind mounts do NOT — they fail with EINVAL on ZFS mount
  # points inside an unprivileged LXC.  Every child dataset must be listed here
  # explicitly.  When a new appdata ZFS dataset is created on the host, add a
  # mount_point block here and run terraform apply (container restart required).

  mount_point {
    volume = "/mnt/fast/stacks"
    path   = "/mnt/fast/stacks"
  }

  # fast/appdata child datasets — one mount_point per ZFS dataset
  mount_point {
    volume = "/mnt/fast/appdata/arrs"
    path   = "/mnt/fast/appdata/arrs"
  }
  mount_point {
    volume = "/mnt/fast/appdata/automation"
    path   = "/mnt/fast/appdata/automation"
  }
  mount_point {
    volume = "/mnt/fast/appdata/code-server"
    path   = "/mnt/fast/appdata/code-server"
  }
  mount_point {
    volume = "/mnt/fast/appdata/dawarich"
    path   = "/mnt/fast/appdata/dawarich"
  }
  mount_point {
    volume = "/mnt/fast/appdata/hoarder"
    path   = "/mnt/fast/appdata/hoarder"
  }
  mount_point {
    volume = "/mnt/fast/appdata/homarr"
    path   = "/mnt/fast/appdata/homarr"
  }
  mount_point {
    volume = "/mnt/fast/appdata/immich"
    path   = "/mnt/fast/appdata/immich"
  }
  # immich/postgres is a nested child dataset — must appear AFTER immich above
  mount_point {
    volume = "/mnt/fast/appdata/immich/postgres"
    path   = "/mnt/fast/appdata/immich/postgres"
  }
  mount_point {
    volume = "/mnt/fast/appdata/llm-ai"
    path   = "/mnt/fast/appdata/llm-ai"
  }
  mount_point {
    volume = "/mnt/fast/appdata/media"
    path   = "/mnt/fast/appdata/media"
  }
  mount_point {
    volume = "/mnt/fast/appdata/minecraft"
    path   = "/mnt/fast/appdata/minecraft"
  }
  mount_point {
    volume = "/mnt/fast/appdata/postiz"
    path   = "/mnt/fast/appdata/postiz"
  }
  mount_point {
    volume = "/mnt/fast/appdata/teleport"
    path   = "/mnt/fast/appdata/teleport"
  }
  mount_point {
    volume = "/mnt/fast/appdata/termix"
    path   = "/mnt/fast/appdata/termix"
  }
  mount_point {
    volume = "/mnt/fast/appdata/traefik"
    path   = "/mnt/fast/appdata/traefik"
  }

  # fast/home child datasets
  mount_point {
    volume = "/mnt/fast/home/breege"
    path   = "/mnt/fast/home/breege"
  }
  mount_point {
    volume = "/mnt/fast/home/damian"
    path   = "/mnt/fast/home/damian"
  }

  mount_point {
    volume = "/mnt/fast/transcode"
    path   = "/mnt/fast/transcode"
  }

  mount_point {
    volume = "/mnt/fast/tools"
    path   = "/mnt/fast/tools"
  }

  # tank child datasets — one mount_point per ZFS dataset
  # tank/media has nested child datasets (Books/Movies/Music/Photos/TV) which
  # must each be listed after their parent for correct overlay ordering.
  mount_point {
    volume = "/mnt/tank/downloads"
    path   = "/mnt/tank/downloads"
  }
  mount_point {
    volume = "/mnt/tank/isos"
    path   = "/mnt/tank/isos"
  }
  mount_point {
    volume = "/mnt/tank/media"
    path   = "/mnt/tank/media"
  }
  mount_point {
    volume = "/mnt/tank/media/Books"
    path   = "/mnt/tank/media/Books"
  }
  mount_point {
    volume = "/mnt/tank/media/Movies"
    path   = "/mnt/tank/media/Movies"
  }
  mount_point {
    volume = "/mnt/tank/media/Music"
    path   = "/mnt/tank/media/Music"
  }
  mount_point {
    volume = "/mnt/tank/media/Photos"
    path   = "/mnt/tank/media/Photos"
  }
  mount_point {
    volume = "/mnt/tank/media/TV"
    path   = "/mnt/tank/media/TV"
  }
  mount_point {
    volume = "/mnt/tank/timemachine"
    path   = "/mnt/tank/timemachine"
  }

  lifecycle {
    ignore_changes = [
      # started is managed externally by null_resource.start_lxc after the
      # config patch. Tracking it here would cause a perpetual drift.
      started,
      # Password is set once; rotating it does not need a container replace.
      initialization[0].user_account[0].password,
    ]
  }
}

# ── Phase 2: Patch /etc/pve/lxc/<vmid>.conf ─────────────────────────────────
#
# Writes idmap lines + GPU cgroup/mount entries into the Proxmox LXC config.
# This MUST happen before pct start because:
#   - lxc.idmap determines the UID/GID namespace at container creation time
#   - Without it the bind-mounted files appear owned by nobody:nogroup inside
#   - GPU entries need to be present before the container's cgroup is set up

resource "null_resource" "patch_lxc_config" {
  depends_on = [proxmox_virtual_environment_container.selfhost]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      # ── Idempotent cleanup ───────────────────────────────────────────────
      # Remove any pre-existing idmap/GPU lines so re-runs don't duplicate.
      # Also strip any raw lxc.mount.entry lines for fast/appdata or fast/home
      # that may have been added manually — child ZFS datasets are now handled
      # exclusively via Proxmox mp<N> entries in the container resource.
      "sed -i '/^lxc\\.idmap:/d;/^lxc\\.cgroup2\\.devices\\.allow:.*226/d;/^lxc\\.mount\\.entry:.*dri/d;/^lxc\\.mount\\.entry:.*fast\\/appdata/d;/^lxc\\.mount\\.entry:.*fast\\/home/d' ${local.conf}",

      # ── UID idmap lines ──────────────────────────────────────────────────
      # Maps container UIDs to host UIDs.  The apps uid (568) is passed
      # through 1:1 so files on the fast pool appear with the correct owner.
      "echo 'lxc.idmap: u ${local.u_r1_start} ${local.u_r1_host} ${local.u_r1_count}' >> ${local.conf}",
      "echo 'lxc.idmap: u ${local.u_r2_start} ${local.u_r2_host} ${local.u_r2_count}' >> ${local.conf}",
      "echo 'lxc.idmap: u ${local.u_r3_start} ${local.u_r3_host} ${local.u_r3_count}' >> ${local.conf}",

      # ── GID idmap lines ──────────────────────────────────────────────────
      # video(44), render(105), and apps(568) all pass through 1:1.
      # The gaps between them are remapped to the high container namespace.
      "echo 'lxc.idmap: g ${local.g_r1_start} ${local.g_r1_host} ${local.g_r1_count}' >> ${local.conf}",
      "echo 'lxc.idmap: g ${local.g_r2_start} ${local.g_r2_host} ${local.g_r2_count}' >> ${local.conf}",
      "echo 'lxc.idmap: g ${local.g_r3_start} ${local.g_r3_host} ${local.g_r3_count}' >> ${local.conf}",
      "echo 'lxc.idmap: g ${local.g_r4_start} ${local.g_r4_host} ${local.g_r4_count}' >> ${local.conf}",
      "echo 'lxc.idmap: g ${local.g_r5_start} ${local.g_r5_host} ${local.g_r5_count}' >> ${local.conf}",
      "echo 'lxc.idmap: g ${local.g_r6_start} ${local.g_r6_host} ${local.g_r6_count}' >> ${local.conf}",
      "echo 'lxc.idmap: g ${local.g_r7_start} ${local.g_r7_host} ${local.g_r7_count}' >> ${local.conf}",

      # ── AMD GPU cgroup2 allow ────────────────────────────────────────────
      # 226:<card_minor>  = /dev/dri/${gpu_card}   (VAAPI — Jellyfin, Immich)
      # 226:<render_minor> = /dev/dri/${gpu_render} (compute/render)
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.gpu_card_minor} rwm'   >> ${local.conf}",
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.gpu_render_minor} rwm' >> ${local.conf}",

      # ── AMD GPU mount entries ────────────────────────────────────────────
      # Bind-mount the DRI devices into the container.
      # 'optional' prevents boot failure if the host has no GPU at re-run time.
      "echo 'lxc.mount.entry: /dev/dri/${local.gpu_card} dev/dri/${local.gpu_card} none bind,optional,create=file'     >> ${local.conf}",
      "echo 'lxc.mount.entry: /dev/dri/${local.gpu_render} dev/dri/${local.gpu_render} none bind,optional,create=file' >> ${local.conf}",

      # Confirm the patch was written
      "echo '--- LXC config patch applied ---' && grep -E 'lxc\\.(idmap|cgroup2|mount)' ${local.conf}",
    ]
  }
}

# ── Phase 3: Start the LXC ───────────────────────────────────────────────────

resource "null_resource" "start_lxc" {
  depends_on = [null_resource.patch_lxc_config]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "pct start ${var.lxc_vmid}",
      # Wait up to 90 s for the LXC's SSH daemon to open port 22.
      "timeout 90 bash -c 'until bash -c \"echo >/dev/tcp/${var.lxc_ip}/22\" 2>/dev/null; do sleep 3; done' && echo 'LXC SSH ready' || echo 'WARNING: timed out waiting for LXC SSH — provision step may retry'",
      # Debian 13 disables root password SSH login by default (PermitRootLogin prohibit-password).
      # Patch the main sshd_config directly via pct exec so the Terraform provisioner can
      # authenticate with the root password. sed '#?' handles both commented and live lines.
      "pct exec ${var.lxc_vmid} -- sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "pct exec ${var.lxc_vmid} -- sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "pct exec ${var.lxc_vmid} -- systemctl restart ssh",
    ]
  }
}

# ── Phase 4: Provision Docker inside the LXC ────────────────────────────────

resource "null_resource" "provision_lxc" {
  depends_on = [null_resource.start_lxc]

  connection {
    type        = "ssh"
    host        = var.lxc_ip
    user        = "root"
    private_key = file(var.terraform_ssh_private_key_path)
    # Generous timeout: LXC may still be finishing its first-boot init.
    timeout = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      # ── OS baseline ───────────────────────────────────────────────────────
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl gnupg",

      # ── Docker CE ─────────────────────────────────────────────────────────
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc",
      "chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian trixie stable\" > /etc/apt/sources.list.d/docker.list",
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",

      # ── Docker daemon config ──────────────────────────────────────────────
      # overlay2: works natively in PVE 9.1 (Linux 6.12+) with fuse=true.
      # json-file logging with rotation prevents disk exhaustion.
      "echo '{\"storage-driver\":\"overlay2\",\"log-driver\":\"json-file\",\"log-opts\":{\"max-size\":\"10m\",\"max-file\":\"3\"}}' > /etc/docker/daemon.json",

      # ── apps user/group ───────────────────────────────────────────────────
      # Must match host uid/gid 568 so bind-mounted files appear with correct ownership.
      "groupadd -g ${var.apps_gid} apps  2>/dev/null || true",
      "useradd -r -u ${var.apps_uid} -g ${var.apps_gid} -M -s /usr/sbin/nologin apps 2>/dev/null || true",

      # ── GPU groups inside LXC ─────────────────────────────────────────────
      # The idmap passes gid 44 and 105 through 1:1, so the in-container GIDs
      # must match exactly so /dev/dri devices have the right group ownership.
      "getent group video  >/dev/null 2>&1 || groupadd -g ${var.video_gid} video",
      "getent group render >/dev/null 2>&1 || groupadd -g ${var.render_gid} render",

      # apps user needs docker, video, render group membership.
      "usermod -aG docker,video,render apps",

      # ── Enable Docker ─────────────────────────────────────────────────────
      "systemctl enable --now docker",

      # ── Docker macvlan network for direct LAN IPs ─────────────────────────
      # Required by jellyfin.yaml and dispatcharr.yaml for fixed IPs on the LAN.
      # Subnet: 172.16.1.0/24, IP pool: 172.16.1.64-127 (172.16.1.64/26).
      # Parent interface: eth0 (LXC's network interface on vmbr0).
      "docker network create -d macvlan --subnet=172.16.1.0/24 --gateway=172.16.1.1 --ip-range=172.16.1.64/26 -o parent=eth0 iot_macvlan 2>/dev/null || echo 'iot_macvlan network already exists'",

      # ── Git safe directory ────────────────────────────────────────────────
      # The stacks repo is bind-mounted from the host; git refuses to operate
      # in directories owned by a different user without this setting.
      "git config --global --add safe.directory /mnt/fast/stacks",

      # ── GitHub SSH key ────────────────────────────────────────────────────
      # Add github.com to known_hosts for git operations over SSH.
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh",
      "ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || true",

      # ── Smoke tests ──────────────────────────────────────────────────────
      "docker info | grep -E 'Storage Driver|Cgroup'",
      "ls /mnt/fast/stacks | head -5",
      "ls -la /dev/dri/ 2>/dev/null || echo 'NOTE: /dev/dri not found — check GPU passthrough'",
      "id apps",
    ]
  }
}
