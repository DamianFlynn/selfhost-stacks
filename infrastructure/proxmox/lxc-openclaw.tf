# lxc-openclaw.tf — Debian 13 LXC for OpenClaw AI assistant
#
# OpenClaw is an AI assistant service.
# This LXC has AMD GPU passthrough for hardware-accelerated inference.
# The actual OpenClaw install is left to the user after provisioning.
#
# Phase ordering mirrors lxc-selfhost.tf:
#   1. proxmox_virtual_environment_container.openclaw  [started=false]
#   2. null_resource.patch_openclaw_config             [GPU idmap + cgroup + mount]
#   3. null_resource.start_openclaw                    [pct start + wait for SSH]
#   4. null_resource.provision_openclaw                [OS baseline + Node.js/pnpm]

# ── Computed idmap ranges for OpenClaw ───────────────────────────────────────
#
# Simpler than selfhost: no apps(568) uid/gid passthrough is needed because
# this LXC has no bind mounts from the fast pool.
# Only video(44) and render(110) GIDs pass through 1:1 for /dev/dri access.
#
#   u 0  100000  65536             (all UIDs → high namespace)
#   g 0  100000  video_gid         (0 … video_gid-1)
#   g video_gid  video_gid  1      (video passthrough)
#   g video_gid+1  100000+v+1  render_gid-video_gid-1  (gap)
#   g render_gid render_gid  1     (render passthrough)
#   g render_gid+1  100000+r+1  65536-render_gid-1      (remainder)

locals {
  oc_conf = "/etc/pve/lxc/${var.openclaw_vmid}.conf"

  # GID ranges
  oc_g_r1_count = var.video_gid                      # 44
  oc_g_r3_host  = 100000 + var.video_gid + 1         # 100045
  oc_g_r3_count = var.render_gid - var.video_gid - 1 # 58
  oc_g_r5_host  = 100000 + var.render_gid + 1        # 100104
  oc_g_r5_count = 65536 - var.render_gid - 1         # 65432

  # GPU device mappings (shared with lxc-selfhost.tf)
  gpu_card         = "card${var.gpu_card_index}"
  gpu_render       = "renderD${var.gpu_render_index}"
  gpu_card_minor   = var.gpu_card_index
  gpu_render_minor = var.gpu_render_index
}

# ── Phase 1: OpenClaw LXC (started=false) ───────────────────────────────────

resource "proxmox_virtual_environment_container" "openclaw" {
  depends_on = [null_resource.host_setup]

  node_name   = var.proxmox_node
  vm_id       = var.openclaw_vmid
  description = "OpenClaw AI assistant LXC"

  started      = false
  unprivileged = true

  features {
    nesting = true
    fuse    = true
  }

  initialization {
    hostname = var.openclaw_hostname

    dns {
      servers = [var.nameserver]
    }

    ip_config {
      ipv4 {
        address = "${var.openclaw_ip}/24"
        gateway = var.lxc_gateway
      }
    }

    user_account {
      password = var.openclaw_root_password
      keys     = var.openclaw_ssh_public_keys
    }
  }

  cpu {
    cores = var.openclaw_cores
  }

  memory {
    dedicated = var.openclaw_memory_mb
    swap      = 0
  }

  operating_system {
    template_file_id = "${var.template_storage}:vztmpl/${var.lxc_template}"
    type             = "debian"
  }

  disk {
    datastore_id = var.lxc_storage
    size         = var.openclaw_disk_gb
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  # No ZFS bind mounts — OpenClaw stores its data inside the container.

  lifecycle {
    ignore_changes = [
      started,
      initialization[0].user_account[0].password,
    ]
  }
}

# ── Phase 2: Patch /etc/pve/lxc/<vmid>.conf ─────────────────────────────────
#
# Adds GPU passthrough (idmap + cgroup2 + mount entries) before first boot.
# Unlike selfhost, the UID map is a simple full-range remapping (no apps uid).

resource "null_resource" "patch_openclaw_config" {
  depends_on = [proxmox_virtual_environment_container.openclaw]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      # Idempotent cleanup
      "sed -i '/^lxc\\.idmap:/d;/^lxc\\.cgroup2\\.devices\\.allow:.*226/d;/^lxc\\.mount\\.entry:.*dri/d' ${local.oc_conf}",

      # UID: map all container UIDs to the high namespace (no passthrough needed)
      "echo 'lxc.idmap: u 0 100000 65536' >> ${local.oc_conf}",

      # GID: video(44) and render(110) pass through 1:1; gaps go to high namespace
      "echo 'lxc.idmap: g 0 100000 ${local.oc_g_r1_count}'                        >> ${local.oc_conf}",
      "echo 'lxc.idmap: g ${var.video_gid} ${var.video_gid} 1'                    >> ${local.oc_conf}",
      "echo 'lxc.idmap: g ${var.video_gid + 1} ${local.oc_g_r3_host} ${local.oc_g_r3_count}' >> ${local.oc_conf}",
      "echo 'lxc.idmap: g ${var.render_gid} ${var.render_gid} 1'                  >> ${local.oc_conf}",
      "echo 'lxc.idmap: g ${var.render_gid + 1} ${local.oc_g_r5_host} ${local.oc_g_r5_count}' >> ${local.oc_conf}",

      # AMD GPU cgroup2 allow — uses same gpu_card_index local as lxc-selfhost.tf
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.gpu_card_minor} rwm'   >> ${local.oc_conf}",
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.gpu_render_minor} rwm' >> ${local.oc_conf}",

      # AMD GPU mount entries
      "echo 'lxc.mount.entry: /dev/dri/${local.gpu_card} dev/dri/${local.gpu_card} none bind,optional,create=file'     >> ${local.oc_conf}",
      "echo 'lxc.mount.entry: /dev/dri/${local.gpu_render} dev/dri/${local.gpu_render} none bind,optional,create=file' >> ${local.oc_conf}",

      "echo '--- OpenClaw LXC config patch applied ---' && grep -E 'lxc\\.(idmap|cgroup2|mount)' ${local.oc_conf}",
    ]
  }
}

# ── Phase 3: Start the OpenClaw LXC ─────────────────────────────────────────

resource "null_resource" "start_openclaw" {
  depends_on = [null_resource.patch_openclaw_config]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "pct start ${var.openclaw_vmid}",
      "timeout 90 bash -c 'until bash -c \"echo >/dev/tcp/${var.openclaw_ip}/22\" 2>/dev/null; do sleep 3; done' && echo 'OpenClaw LXC SSH ready' || echo 'WARNING: timed out waiting for SSH'",
      # Same Debian 13 sshd fix as selfhost — enable root password login for Terraform.
      "pct exec ${var.openclaw_vmid} -- sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "pct exec ${var.openclaw_vmid} -- sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "pct exec ${var.openclaw_vmid} -- systemctl restart ssh",
    ]
  }
}

# ── Phase 4: OS baseline inside the OpenClaw LXC ────────────────────────────
#
# Installs Node.js LTS + pnpm and VA-API tools for GPU-accelerated inference.
# OpenClaw (https://openclaw.ai) is Node.js-based; actual install via:
#   curl -fsSL https://openclaw.ai/install.sh | bash

resource "null_resource" "provision_openclaw" {
  depends_on = [null_resource.start_openclaw]

  connection {
    type        = "ssh"
    host        = var.openclaw_ip
    user        = "root"
    private_key = file(var.terraform_ssh_private_key_path)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      # ── OS baseline ───────────────────────────────────────────────────────
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq",
      # Node.js LTS via NodeSource + pnpm + Vulkan/VA-API tools for GPU inference
      "curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs git curl ca-certificates build-essential vainfo libva-dev vulkan-tools mesa-vulkan-drivers",
      "npm install -g pnpm",

      # ── GPU groups ────────────────────────────────────────────────────────
      # idmap passes gid 44 (video) and 110 (render) through 1:1.
      "getent group video  >/dev/null 2>&1 || groupadd -g ${var.video_gid} video",
      "getent group render >/dev/null 2>&1 || groupadd -g ${var.render_gid} render",
      # Force render group to correct GID if it exists with wrong GID
      "groupmod -g ${var.render_gid} render 2>/dev/null || true",

      # ── Configure Ollama for AMD GPU (Vulkan) ────────────────────────────
      "mkdir -p /etc/systemd/system/ollama.service.d/",
      "cat > /etc/systemd/system/ollama.service.d/amd-gpu.conf <<'OLLAMA_EOF'\n[Service]\n# AMD GPU configuration for Radeon 890M (RDNA 3.5/Strix)\nEnvironment=\"HSA_OVERRIDE_GFX_VERSION=11.0.3\"\nEnvironment=\"OLLAMA_DEBUG=1\"\nEnvironment=\"OLLAMA_VULKAN=1\"\n\n# Run as ollama user with GPU group access\nUser=ollama\nSupplementaryGroups=video render\n\n# Ensure GPU devices are accessible\nDeviceAllow=/dev/dri/card${var.gpu_card_index} rw\nDeviceAllow=/dev/dri/renderD${var.gpu_render_index} rw\nOLLAMA_EOF",
      "systemctl daemon-reload",
      "systemctl restart ollama 2>/dev/null || echo 'NOTE: Ollama not installed yet'",

      # ── Smoke tests ───────────────────────────────────────────────────────
      "ls -la /dev/dri/ 2>/dev/null || echo 'NOTE: /dev/dri not present — check GPU passthrough'",
      "vainfo --display drm --device /dev/dri/${local.gpu_render} 2>/dev/null | head -5 || echo 'NOTE: vainfo check skipped'",
    ]
  }
}
