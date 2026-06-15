# lxc-mpe.tf — Docker LXC 102 "mpe": dedicated, isolated stack for MPE Renewables
#
# Cloned in spirit from lxc-selfhost.tf but deliberately SIMPLER:
#   - NO GPU passthrough (no local LLM here — only ERPNext / n8n / WordPress)
#   - Minimal bind mounts: the shared stacks repo + a single dedicated appdata
#     dataset (/mnt/fast/appdata/mpe). Nothing from the personal stack is mounted.
#   - Own IP, own backups/snapshots. Personal LXC 100 "selfhost" is untouched.
#
# Phase ordering (mirrors lxc-selfhost.tf, minus the GPU patch):
#   1. null_resource.mpe_dataset        — ensure ZFS dataset fast/appdata/mpe exists
#   2. proxmox_..._container.mpe         — declare container (started=false)
#   3. null_resource.patch_lxc_config_mpe — write apps-only idmap into the LXC conf
#   4. null_resource.start_lxc_mpe       — pct start + wait for SSH
#   5. null_resource.provision_lxc_mpe   — install Docker CE, apps user, mpe_proxy net
#
# Apply nothing until reviewed. `terraform plan` shows these as NET-NEW resources
# alongside the existing LXC 100 — it does not modify the personal stack.

# ── apps-only idmap ranges (no GPU GIDs needed) ─────────────────────────────
locals {
  mpe_u_r1_start = 0
  mpe_u_r1_host  = 100000
  mpe_u_r1_count = var.apps_uid # 568

  mpe_u_r2_start = var.apps_uid
  mpe_u_r2_host  = var.apps_uid
  mpe_u_r2_count = 1

  mpe_u_r3_start = var.apps_uid + 1
  mpe_u_r3_host  = 100000 + var.apps_uid + 1 # 100569
  mpe_u_r3_count = 65536 - var.apps_uid - 1  # 64967

  mpe_g_r1_start = 0
  mpe_g_r1_host  = 100000
  mpe_g_r1_count = var.apps_gid # 568

  mpe_g_r2_start = var.apps_gid
  mpe_g_r2_host  = var.apps_gid
  mpe_g_r2_count = 1

  mpe_g_r3_start = var.apps_gid + 1
  mpe_g_r3_host  = 100000 + var.apps_gid + 1 # 100569
  mpe_g_r3_count = 65536 - var.apps_gid - 1  # 64967

  mpe_conf = "/etc/pve/lxc/${var.mpe_vmid}.conf"
}

# ── Phase 1: ensure the dedicated ZFS dataset exists on the host ─────────────
# The mount_point below binds /mnt/fast/appdata/mpe, which must be a real ZFS
# dataset (raw bind of a non-dataset path fails EINVAL on an unprivileged LXC).
resource "null_resource" "mpe_dataset" {
  depends_on = [null_resource.host_setup]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "zfs list fast/appdata/mpe >/dev/null 2>&1 || zfs create -p fast/appdata/mpe",
      "chown ${var.apps_uid}:${var.apps_gid} /mnt/fast/appdata/mpe",
      "echo '--- MPE dataset ready ---' && zfs list fast/appdata/mpe",
    ]
  }
}

# ── Phase 2: LXC 102 container (started=false) ──────────────────────────────
resource "proxmox_virtual_environment_container" "mpe" {
  depends_on = [null_resource.mpe_dataset]

  node_name   = var.proxmox_node
  vm_id       = var.mpe_vmid
  description = "MPE Renewables — dedicated isolated stack (ERPNext, n8n, WP/Woo, edge)"

  started      = false
  unprivileged = true

  features {
    nesting = true # required for Docker-in-LXC on PVE 9.1
    fuse    = true # required for overlay2 storage driver
  }

  initialization {
    hostname = var.mpe_hostname

    dns {
      servers = [var.nameserver]
    }

    ip_config {
      ipv4 {
        address = "${var.mpe_ip}/24"
        gateway = var.lxc_gateway
      }
    }

    user_account {
      password = var.mpe_root_password
      keys     = var.lxc_ssh_public_keys
    }
  }

  cpu {
    cores = var.mpe_cores
  }

  memory {
    dedicated = var.mpe_memory_mb
    swap      = 0
  }

  operating_system {
    template_file_id = "${var.template_storage}:vztmpl/${var.lxc_template}"
    type             = "debian"
  }

  disk {
    datastore_id = var.lxc_storage
    size         = var.mpe_disk_gb
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  # ── Bind mounts — only what MPE needs ─────────────────────────────────────
  # Shared compose repo (read MPE's own stacks/mpe/* files from here).
  mount_point {
    volume = "/mnt/fast/stacks"
    path   = "/mnt/fast/stacks"
  }
  # Dedicated appdata dataset — all MPE persistent data lives under here.
  mount_point {
    volume = "/mnt/fast/appdata/mpe"
    path   = "/mnt/fast/appdata/mpe"
  }

  lifecycle {
    ignore_changes = [
      started,
      initialization[0].user_account[0].password,
    ]
  }
}

# ── Phase 3: Patch /etc/pve/lxc/<vmid>.conf — apps-only idmap ────────────────
resource "null_resource" "patch_lxc_config_mpe" {
  depends_on = [proxmox_virtual_environment_container.mpe]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      # Idempotent cleanup so re-runs don't duplicate idmap lines.
      "sed -i '/^lxc\\.idmap:/d' ${local.mpe_conf}",

      # UID idmap — apps (568) passthrough 1:1, rest mapped high.
      "echo 'lxc.idmap: u ${local.mpe_u_r1_start} ${local.mpe_u_r1_host} ${local.mpe_u_r1_count}' >> ${local.mpe_conf}",
      "echo 'lxc.idmap: u ${local.mpe_u_r2_start} ${local.mpe_u_r2_host} ${local.mpe_u_r2_count}' >> ${local.mpe_conf}",
      "echo 'lxc.idmap: u ${local.mpe_u_r3_start} ${local.mpe_u_r3_host} ${local.mpe_u_r3_count}' >> ${local.mpe_conf}",

      # GID idmap — apps (568) passthrough 1:1, rest mapped high.
      "echo 'lxc.idmap: g ${local.mpe_g_r1_start} ${local.mpe_g_r1_host} ${local.mpe_g_r1_count}' >> ${local.mpe_conf}",
      "echo 'lxc.idmap: g ${local.mpe_g_r2_start} ${local.mpe_g_r2_host} ${local.mpe_g_r2_count}' >> ${local.mpe_conf}",
      "echo 'lxc.idmap: g ${local.mpe_g_r3_start} ${local.mpe_g_r3_host} ${local.mpe_g_r3_count}' >> ${local.mpe_conf}",

      "echo '--- MPE LXC idmap applied ---' && grep -E 'lxc\\.idmap' ${local.mpe_conf}",
    ]
  }
}

# ── Phase 4: Start the LXC ──────────────────────────────────────────────────
resource "null_resource" "start_lxc_mpe" {
  depends_on = [null_resource.patch_lxc_config_mpe]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "pct start ${var.mpe_vmid}",
      "timeout 90 bash -c 'until bash -c \"echo >/dev/tcp/${var.mpe_ip}/22\" 2>/dev/null; do sleep 3; done' && echo 'LXC SSH ready' || echo 'WARNING: timed out waiting for LXC SSH'",
      # Debian 13 disables root password SSH by default — enable for the provisioner.
      "pct exec ${var.mpe_vmid} -- sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "pct exec ${var.mpe_vmid} -- sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "pct exec ${var.mpe_vmid} -- systemctl restart ssh",
    ]
  }
}

# ── Phase 5: Provision Docker inside the LXC ────────────────────────────────
resource "null_resource" "provision_lxc_mpe" {
  depends_on = [null_resource.start_lxc_mpe]

  connection {
    type        = "ssh"
    host        = var.mpe_ip
    user        = "root"
    private_key = file(var.terraform_ssh_private_key_path)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      # OS baseline
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl gnupg",

      # Docker CE
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc",
      "chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian trixie stable\" > /etc/apt/sources.list.d/docker.list",
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",

      # Docker daemon config — overlay2 + log rotation.
      "echo '{\"storage-driver\":\"overlay2\",\"log-driver\":\"json-file\",\"log-opts\":{\"max-size\":\"10m\",\"max-file\":\"3\"}}' > /etc/docker/daemon.json",

      # apps user/group — match host uid/gid 568 for bind-mount ownership.
      "groupadd -g ${var.apps_gid} apps 2>/dev/null || true",
      "useradd -r -u ${var.apps_uid} -g ${var.apps_gid} -M -s /usr/sbin/nologin apps 2>/dev/null || true",
      "usermod -aG docker apps",

      "systemctl enable --now docker",

      # NOTE: the mpe_proxy / mpe_socket_proxy Docker networks are created by the
      # edge compose stack (stacks/mpe/edge/compose.yaml) on first `up`, with
      # fixed subnets. They are intentionally NOT pre-created here.

      # Git safe directory (stacks repo is bind-mounted from the host).
      "git config --global --add safe.directory /mnt/fast/stacks",
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh",
      "ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || true",

      # Smoke tests
      "docker info | grep -E 'Storage Driver|Cgroup'",
      "ls /mnt/fast/stacks/stacks/mpe 2>/dev/null || echo 'NOTE: stacks/mpe not yet present on host'",
      "ls -la /mnt/fast/appdata/mpe",
      "id apps",
    ]
  }
}
