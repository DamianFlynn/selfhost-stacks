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

# ── Phase 4: Complete OpenClaw setup ────────────────────────────────────────
#
# Fully provisions OpenClaw with:
# - openclaw user with sudo + GPU access + Homebrew
# - Ollama + GPU acceleration + models (qwen2.5:3b + 32K variant)
# - OpenClaw installation + configuration
# - Samba server for workspace sharing
# - systemd user service for OpenClaw gateway
#
# NOTE: This is a long-running provisioner (10-15 min) due to Homebrew,
# model downloads, and OpenClaw installation.

resource "null_resource" "provision_openclaw" {
  depends_on = [null_resource.start_openclaw]

  connection {
    type        = "ssh"
    host        = var.openclaw_ip
    user        = "root"
    private_key = file(var.terraform_ssh_private_key_path)
    timeout     = "30m"
  }

  provisioner "remote-exec" {
    inline = [
      # ── OS baseline ───────────────────────────────────────────────────────
      "echo '==> Updating system packages...'",
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq",
      
      # ── Ensure systemd is installed and configured ───────────────────────
      "echo '==> Installing systemd and base tools...'",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq systemd systemd-sysv dbus sudo",
      
      # Install base tools, GPU drivers, and Samba (zstd needed for Ollama)
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git curl ca-certificates build-essential vainfo libva-dev vulkan-tools mesa-vulkan-drivers clinfo zstd samba samba-common-bin",
      
      # Node.js 22 LTS via NodeSource (includes npm)
      "echo '==> Installing Node.js 22 LTS...'",
      "curl -fsSL https://deb.nodesource.com/setup_22.x | bash -",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs",

      # ── GPU groups ────────────────────────────────────────────────────────
      "echo '==> Configuring GPU groups...'",
      "getent group video  >/dev/null 2>&1 || groupadd -g ${var.video_gid} video",
      "getent group render >/dev/null 2>&1 || groupadd -g ${var.render_gid} render",
      "groupmod -g ${var.render_gid} render 2>/dev/null || true",

      # ── Create openclaw user ──────────────────────────────────────────────
      "echo '==> Creating openclaw user...'",
      "useradd -m -s /bin/bash -G sudo,video,render openclaw",
      "echo 'openclaw ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/openclaw",
      "chmod 440 /etc/sudoers.d/openclaw",

      # ── Install Ollama ────────────────────────────────────────────────────
      "echo '==> Installing Ollama...'",
      "curl -fsSL https://ollama.com/install.sh | sh",
      "sleep 2",
      "usermod -aG video,render ollama",

      # ── Configure Ollama for AMD GPU ──────────────────────────────────────
      "echo '==> Configuring Ollama for AMD GPU...'",
      "mkdir -p /etc/systemd/system/ollama.service.d/",
      "cat > /etc/systemd/system/ollama.service.d/amd-gpu.conf <<'OLLAMA_EOF'\n[Service]\nEnvironment=\"HSA_OVERRIDE_GFX_VERSION=11.0.3\"\nEnvironment=\"OLLAMA_VULKAN=1\"\nUser=ollama\nSupplementaryGroups=video render\nDeviceAllow=/dev/dri/card${var.gpu_card_index} rw\nDeviceAllow=/dev/dri/renderD${var.gpu_render_index} rw\nOLLAMA_EOF",
      
      "systemctl daemon-reload",
      "systemctl enable ollama",
      "systemctl restart ollama",
      "sleep 5",

      # ── Pull Ollama models ────────────────────────────────────────────────
      "echo '==> Pulling Ollama models (this takes several minutes)...'",
      "sudo -u ollama ollama pull qwen2.5:3b",
      
      # Create 32K context variant
      "cat > /tmp/qwen-32k.modelfile <<'MODEL_EOF'\nFROM qwen2.5:3b\nPARAMETER num_ctx 32768\nMODEL_EOF",
      "sudo -u ollama ollama create qwen2.5:3b-32k -f /tmp/qwen-32k.modelfile",
      "rm /tmp/qwen-32k.modelfile",

      # ── Install Homebrew as openclaw user ─────────────────────────────────
      "echo '==> Installing Homebrew for openclaw user (this takes 5-10 minutes)...'",
      "sudo -u openclaw bash -c 'NONINTERACTIVE=1 /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"'",
      
      # Add Homebrew to openclaw's profile
      "sudo -u openclaw bash -c 'echo \"eval \\\"\\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\\\"\" >> /home/openclaw/.bashrc'",
      "sudo -u openclaw bash -c 'echo \"eval \\\"\\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\\\"\" >> /home/openclaw/.profile'",

      # ── Install OpenClaw ──────────────────────────────────────────────────
      "echo '==> Installing OpenClaw...'",
      "sudo -u openclaw bash -c 'eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\" && npm install -g openclaw'",

      # ── Add OpenClaw to PATH ──────────────────────────────────────────────
      "echo '==> Adding OpenClaw to PATH...'",
      "sudo -u openclaw bash -c 'echo \"export PATH=\\\"/home/openclaw/.npm-global/bin:\\$PATH\\\"\" >> /home/openclaw/.bashrc'",
      "sudo -u openclaw bash -c 'echo \"export PATH=\\\"/home/openclaw/.npm-global/bin:\\$PATH\\\"\" >> /home/openclaw/.profile'",
      "echo \"export PATH=\\\"/home/openclaw/.npm-global/bin:\\$PATH\\\"\" >> /root/.bashrc",
      "echo \"export PATH=\\\"/home/openclaw/.npm-global/bin:\\$PATH\\\"\" >> /root/.profile",

      # ── Configure sudoers for service management ──────────────────────────
      "echo '==> Configuring sudoers for OpenClaw service management...'",
      "cat > /etc/sudoers.d/openclaw-service <<'SUDOERS_EOF'\n# Allow openclaw user to manage its own systemd service\nopenclaw ALL=(ALL) NOPASSWD: /bin/systemctl restart openclaw-gateway\nopenclaw ALL=(ALL) NOPASSWD: /bin/systemctl stop openclaw-gateway\nopenclaw ALL=(ALL) NOPASSWD: /bin/systemctl start openclaw-gateway\nopenclaw ALL=(ALL) NOPASSWD: /bin/systemctl status openclaw-gateway\n\n# Allow openclaw user to pkill its own processes\nopenclaw ALL=(ALL) NOPASSWD: /usr/bin/pkill openclaw\nopenclaw ALL=(ALL) NOPASSWD: /usr/bin/killall openclaw\nSUDOERS_EOF",
      "chmod 0440 /etc/sudoers.d/openclaw-service",

      # ── Enable systemd user services (lingering) ──────────────────────────
      "echo '==> Enabling user services for openclaw...'",
      "loginctl enable-linger openclaw",

      # ── Configure Samba for workspace sharing ─────────────────────────────
      "echo '==> Configuring Samba for workspace sharing...'",
      "mkdir -p /home/openclaw/.openclaw/workspace",
      "chown -R openclaw:openclaw /home/openclaw/.openclaw",
      
      # Set Samba password (using same as root for simplicity)
      "(echo '${var.openclaw_root_password}'; echo '${var.openclaw_root_password}') | smbpasswd -a openclaw -s",
      
      # Configure Samba share
      "cat >> /etc/samba/smb.conf <<'SAMBA_EOF'\n\n[openclaw-workspace]\n   path = /home/openclaw/.openclaw/workspace\n   browseable = yes\n   read only = no\n   guest ok = no\n   valid users = openclaw\n   create mask = 0644\n   directory mask = 0755\n   comment = OpenClaw Workspace\nSAMBA_EOF",
      
      "systemctl enable smbd",
      "systemctl restart smbd",

      # ── Smoke tests ───────────────────────────────────────────────────────
      "echo '==> Running smoke tests...'",
      "ls -la /dev/dri/",
      "id openclaw",
      "sudo -u openclaw which openclaw",
      "systemctl status ollama --no-pager",
      "sudo -u ollama ollama list",
      "testparm -s 2>/dev/null | grep -A 5 openclaw-workspace",
      
      "echo '==> OpenClaw LXC provisioned successfully!'",
      "echo '    - Ollama models: qwen2.5:3b, qwen2.5:3b-32k'",
      "echo '    - User: openclaw (with sudo + Homebrew)'",
      "echo '    - Samba share: //172.16.1.160/openclaw-workspace'",
      "echo '    - Next: Run OpenClaw installer as openclaw user'",
    ]
  }
}

# ── Phase 5: OpenClaw initialization ─────────────────────────────────────────
#
# Creates systemd system service for OpenClaw gateway (not user service).
# System service is used because unprivileged LXC containers don't support
# systemd user services reliably.
#
# Service includes health monitoring features:
#  - WatchdogSec=600: Restarts if service becomes unresponsive for 10 minutes
#  - Restart=on-failure: Auto-restart on crashes, timeouts, or watchdog triggers
#  - Timeout protection: StartSec=120s, StopSec=30s
#
# This prevents silent failures (e.g., Telegram polling disconnections) by
# automatically restarting the service if it stops responding.
#
# The OpenClaw configuration will need to be set up manually after first run:
#   1. SSH as openclaw user: ssh openclaw@172.16.1.160
#   2. Run: openclaw gateway --bind lan
#   3. Follow onboarding wizard (or restore config from backup)
#
# NOTE: The systemd service will need to be enabled after OpenClaw configuration exists.
# NOTE: Memory feature is enabled by default in ~/.openclaw/workspace/memory/

resource "null_resource" "configure_openclaw_service" {
  depends_on = [null_resource.provision_openclaw]

  connection {
    type        = "ssh"
    host        = var.openclaw_ip
    user        = "root"
    private_key = file(var.terraform_ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '==> Creating systemd system service for OpenClaw...'",
      
      # Create OpenClaw gateway system service file with health monitoring
      "cat > /etc/systemd/system/openclaw-gateway.service <<'SERVICE_EOF'\n[Unit]\nDescription=OpenClaw Gateway\nDocumentation=https://docs.openclaw.ai/\nAfter=network-online.target ollama.service\nWants=network-online.target\n\n[Service]\nType=simple\nUser=openclaw\nGroup=openclaw\nWorkingDirectory=/home/openclaw\nExecStart=/home/openclaw/.npm-global/bin/openclaw gateway --bind lan\n\n# Restart on failure, watchdog timeout, or abnormal termination\nRestart=on-failure\nRestartSec=10\n\n# Health monitoring - restart if service becomes unresponsive (10 min)\nWatchdogSec=600\n\n# Timeout protection\nTimeoutStartSec=120\nTimeoutStopSec=30\n\nStandardOutput=journal\nStandardError=journal\nEnvironment=\"DEEPSEEK_API_KEY=sk-placeholder\"\n\n[Install]\nWantedBy=multi-user.target\nSERVICE_EOF",
      
      "systemctl daemon-reload",
      
      # Note: Service will be enabled after OpenClaw configuration exists
      "echo '==> OpenClaw system service created (enable after configuration with: systemctl enable openclaw-gateway)'",
      "echo ''",
      "echo '╔════════════════════════════════════════════════════════════════╗'",
      "echo '║  OpenClaw LXC Ready!                                           ║'",
      "echo '╠════════════════════════════════════════════════════════════════╣'",
      "echo '║  IP Address: 172.16.1.160                                      ║'",
      "echo '║  Samba Share: //172.16.1.160/openclaw-workspace                ║'",
      "echo '║               (user: openclaw, password: <root-password>)      ║'",
      "echo '║                                                                ║'",
      "echo '║  Next Steps:                                                   ║'",
      "echo '║  1. Mount Samba share in Obsidian                              ║'",
      "echo '║  2. SSH as openclaw: ssh openclaw@172.16.1.160                 ║'",
      "echo '║  3. Run: openclaw gateway --bind lan                           ║'",
      "echo '║  4. Follow wizard OR restore backup config                     ║'",
      "echo '║  5. Enable service: sudo systemctl enable openclaw-gateway     ║'",
      "echo '║  6. Start service: sudo systemctl start openclaw-gateway       ║'",
      "echo '║                                                                ║'",
      "echo '║  Commands available without full path:                         ║'",
      "echo '║  - openclaw models list                                        ║'",
      "echo '║  - openclaw gateway status                                     ║'",
      "echo '║  - sudo systemctl restart openclaw-gateway                     ║'",
      "echo '╚════════════════════════════════════════════════════════════════╝'",
    ]
  }
}
