# lxc-cerebro.tf — Docker LXC for Cerebro/Ollama workloads

locals {
  cerebro_conf = "/etc/pve/lxc/${var.cerebro_vmid}.conf"

  cerebro_u_r1_start = 0
  cerebro_u_r1_host  = 100000
  cerebro_u_r1_count = var.apps_uid

  cerebro_u_r2_start = var.apps_uid
  cerebro_u_r2_host  = var.apps_uid
  cerebro_u_r2_count = 1

  cerebro_u_r3_start = var.apps_uid + 1
  cerebro_u_r3_host  = 100000 + var.apps_uid + 1
  cerebro_u_r3_count = 65536 - var.apps_uid - 1

  cerebro_g_r1_start = 0
  cerebro_g_r1_host  = 100000
  cerebro_g_r1_count = var.video_gid

  cerebro_g_r2_start = var.video_gid
  cerebro_g_r2_host  = var.video_gid
  cerebro_g_r2_count = 1

  cerebro_g_r3_start = var.video_gid + 1
  cerebro_g_r3_host  = 100000 + var.video_gid + 1
  cerebro_g_r3_count = var.render_gid - var.video_gid - 1

  cerebro_g_r4_start = var.render_gid
  cerebro_g_r4_host  = var.render_gid
  cerebro_g_r4_count = 1

  cerebro_g_r5_start = var.render_gid + 1
  cerebro_g_r5_host  = 100000 + var.render_gid + 1
  cerebro_g_r5_count = var.apps_gid - var.render_gid - 1

  cerebro_g_r6_start = var.apps_gid
  cerebro_g_r6_host  = var.apps_gid
  cerebro_g_r6_count = 1

  cerebro_g_r7_start = var.apps_gid + 1
  cerebro_g_r7_host  = 100000 + var.apps_gid + 1
  cerebro_g_r7_count = 65536 - var.apps_gid - 1

  cerebro_gpu_card         = "card${var.gpu_card_index}"
  cerebro_gpu_render       = "renderD${var.gpu_render_index}"
  cerebro_gpu_card_minor   = var.gpu_card_index
  cerebro_gpu_render_minor = var.gpu_render_index
}

resource "proxmox_virtual_environment_container" "cerebro" {
  depends_on = [null_resource.host_setup]

  node_name   = var.proxmox_node
  vm_id       = var.cerebro_vmid
  description = "Cerebro Docker LXC"

  started      = false
  unprivileged = true

  features {
    nesting = true
    fuse    = true
  }

  initialization {
    hostname = lower(var.cerebro_hostname)

    dns {
      servers = [var.nameserver]
    }

    ip_config {
      ipv4 {
        address = "${var.cerebro_ip}/24"
        gateway = var.lxc_gateway
      }
    }

    user_account {
      password = var.cerebro_root_password
      keys     = var.cerebro_ssh_public_keys
    }
  }

  cpu {
    cores = var.cerebro_cores
  }

  memory {
    dedicated = var.cerebro_memory_mb
    swap      = var.cerebro_swap_mb
  }

  operating_system {
    template_file_id = "${var.template_storage}:vztmpl/${var.lxc_template}"
    type             = "debian"
  }

  disk {
    datastore_id = var.lxc_storage
    size         = var.cerebro_disk_gb
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      started,
      initialization[0].user_account[0].password,
    ]
  }
}

resource "null_resource" "patch_cerebro_lxc_config" {
  depends_on = [proxmox_virtual_environment_container.cerebro]

  triggers = {
    config_revision = "2026-02-21-cerebro-single-tank-mount-v6-perms"
  }

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i '/^lxc\\.idmap:/d;/^lxc\\.cgroup2\\.devices\\.allow:.*226/d;/^lxc\\.mount\\.entry:.*dri/d;/^lxc\\.mount\\.entry:.*fast\\/stacks/d;/^lxc\\.mount\\.entry:.*fast\\/appdata/d;/^lxc\\.mount\\.entry:.*tank\\/cerebro/d;/^mp[0-9]\\+: .*mp=\\/mnt\\/fast\\/stacks\\/borg/d;/^mp[0-9]\\+: .*mp=\\/mnt\\/fast\\/appdata\\/ollama/d;/^mp[0-9]\\+: .*mp=\\/mnt\\/tank\\/cerebro/d' ${local.cerebro_conf}",
      "echo 'lxc.idmap: u ${local.cerebro_u_r1_start} ${local.cerebro_u_r1_host} ${local.cerebro_u_r1_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: u ${local.cerebro_u_r2_start} ${local.cerebro_u_r2_host} ${local.cerebro_u_r2_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: u ${local.cerebro_u_r3_start} ${local.cerebro_u_r3_host} ${local.cerebro_u_r3_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: g ${local.cerebro_g_r1_start} ${local.cerebro_g_r1_host} ${local.cerebro_g_r1_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: g ${local.cerebro_g_r2_start} ${local.cerebro_g_r2_host} ${local.cerebro_g_r2_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: g ${local.cerebro_g_r3_start} ${local.cerebro_g_r3_host} ${local.cerebro_g_r3_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: g ${local.cerebro_g_r4_start} ${local.cerebro_g_r4_host} ${local.cerebro_g_r4_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: g ${local.cerebro_g_r5_start} ${local.cerebro_g_r5_host} ${local.cerebro_g_r5_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: g ${local.cerebro_g_r6_start} ${local.cerebro_g_r6_host} ${local.cerebro_g_r6_count}' >> ${local.cerebro_conf}",
      "echo 'lxc.idmap: g ${local.cerebro_g_r7_start} ${local.cerebro_g_r7_host} ${local.cerebro_g_r7_count}' >> ${local.cerebro_conf}",
      "echo 'mp20: /mnt/fast/stacks/cerebro/borg,mp=/mnt/fast/stacks/borg' >> ${local.cerebro_conf}",
      "echo 'mp21: /mnt/fast/appdata/llm-ai/ollama,mp=/mnt/fast/appdata/ollama' >> ${local.cerebro_conf}",
      "echo 'mp22: /mnt/tank/cerebro,mp=/mnt/tank/cerebro' >> ${local.cerebro_conf}",
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.cerebro_gpu_card_minor} rwm' >> ${local.cerebro_conf}",
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.cerebro_gpu_render_minor} rwm' >> ${local.cerebro_conf}",
      "echo 'lxc.mount.entry: /dev/dri/${local.cerebro_gpu_card} dev/dri/${local.cerebro_gpu_card} none bind,optional,create=file' >> ${local.cerebro_conf}",
      "echo 'lxc.mount.entry: /dev/dri/${local.cerebro_gpu_render} dev/dri/${local.cerebro_gpu_render} none bind,optional,create=file' >> ${local.cerebro_conf}",
      "install -d -m 0775 -o ${var.apps_uid} -g ${var.apps_gid} /mnt/tank/cerebro /mnt/tank/cerebro/.openclaw /mnt/tank/cerebro/.openclaw/workspace",
      "echo '--- Cerebro LXC patch applied ---' && grep -E '^(mp[0-9]+:|lxc\\.(cgroup2|mount))' ${local.cerebro_conf}",
    ]
  }
}

resource "null_resource" "start_cerebro_lxc" {
  depends_on = [null_resource.patch_cerebro_lxc_config]

  triggers = {
    patch_resource_id = null_resource.patch_cerebro_lxc_config.id
  }

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "pct status ${var.cerebro_vmid} | grep -q 'status: running' && pct reboot ${var.cerebro_vmid} || pct start ${var.cerebro_vmid}",
      "timeout 90 bash -c 'until bash -c \"echo >/dev/tcp/${var.cerebro_ip}/22\" 2>/dev/null; do sleep 3; done' && echo 'Cerebro LXC SSH ready'",
      "pct exec ${var.cerebro_vmid} -- sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "pct exec ${var.cerebro_vmid} -- sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "pct exec ${var.cerebro_vmid} -- systemctl restart ssh",
    ]
  }
}

resource "null_resource" "provision_cerebro_lxc" {
  depends_on = [null_resource.start_cerebro_lxc]

  triggers = {
    provision_revision = "2026-02-21-cerebro-native-ollama-vulkan-v5-node24-and-mount"
  }

  connection {
    type        = "ssh"
    host        = var.cerebro_ip
    user        = "root"
    private_key = file(var.terraform_ssh_private_key_path)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl gnupg zstd mesa-vulkan-drivers vulkan-tools pciutils git",
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main' > /etc/apt/sources.list.d/nodesource.list",
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs",
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc",
      "chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian trixie stable\" > /etc/apt/sources.list.d/docker.list",
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "echo '{\"storage-driver\":\"overlay2\",\"log-driver\":\"json-file\",\"log-opts\":{\"max-size\":\"10m\",\"max-file\":\"3\"}}' > /etc/docker/daemon.json",
      "getent group video  >/dev/null 2>&1 || groupadd -g ${var.video_gid} video",
      "getent group render >/dev/null 2>&1 || groupadd -g ${var.render_gid} render",
      "groupmod -g ${var.video_gid} video   2>/dev/null || true",
      "groupmod -g ${var.render_gid} render 2>/dev/null || true",
      "groupadd -g ${var.apps_gid} apps 2>/dev/null || true",
      "useradd -r -u ${var.apps_uid} -g ${var.apps_gid} -M -s /usr/sbin/nologin apps 2>/dev/null || true",
      "usermod -aG docker,video,render root",
      "usermod -aG docker,video,render apps",
      "systemctl enable --now docker",
      "docker info | grep -E 'Storage Driver|Cgroup'",
      "ls -la /dev/dri/",
      "id root",
      "docker ps -a --format '{{.ID}} {{.Image}} {{.Names}}' | awk 'tolower($0) ~ /ollama/ {print $1}' | xargs -r docker rm -f",
      "command -v ollama >/dev/null 2>&1 || (curl -fsSL https://ollama.com/install.sh | sh)",
      "mkdir -p /mnt/fast/appdata/ollama/models /etc/systemd/system/ollama.service.d",
      "id ollama >/dev/null 2>&1 && usermod -aG video,render ollama || true",
      "id ollama >/dev/null 2>&1 && chown -R ollama:ollama /mnt/fast/appdata/ollama || true",
      "cat > /etc/systemd/system/ollama.service.d/override.conf <<'EOF'\n[Service]\nEnvironment=\"OLLAMA_HOST=0.0.0.0:11434\"\nEnvironment=\"OLLAMA_MODELS=/mnt/fast/appdata/ollama/models\"\nEnvironment=\"OLLAMA_VULKAN=1\"\nEnvironment=\"OLLAMA_LLM_LIBRARY=vulkan\"\nSupplementaryGroups=video render\nEOF",
      "systemctl daemon-reload",
      "systemctl enable --now ollama",
      "systemctl restart ollama",
      "systemctl is-active ollama",
      "timeout 90 bash -c 'until curl -fsS http://127.0.0.1:11434/api/tags >/dev/null; do sleep 2; done'",
      "install -d -m 0775 -o ${var.apps_uid} -g ${var.apps_gid} /mnt/tank/cerebro/.openclaw /mnt/tank/cerebro/.openclaw/workspace",
      "cat > /etc/systemd/system/cerebro.service <<'EOF'\n[Unit]\nDescription=Cerebro (OpenClaw) Native Service\nAfter=network-online.target ollama.service\nWants=network-online.target\n\n[Service]\nType=simple\nUser=root\nGroup=root\nWorkingDirectory=/root\nEnvironment=HOME=/root\nEnvironment=NODE_ENV=production\nExecStart=/usr/bin/openclaw gateway --allow-unconfigured --bind lan --port 80\nRestart=always\nRestartSec=5\nAmbientCapabilities=CAP_NET_BIND_SERVICE\nCapabilityBoundingSet=CAP_NET_BIND_SERVICE\n\n[Install]\nWantedBy=multi-user.target\nEOF",
      "systemctl daemon-reload",
      "systemctl enable --now cerebro",
      "systemctl is-active cerebro",
    ]
  }
}

output "cerebro_lxc_vmid" {
  value       = var.cerebro_vmid
  description = "Cerebro LXC VMID"
}

output "cerebro_lxc_ip" {
  value       = var.cerebro_ip
  description = "Cerebro LXC IP"
}

output "cerebro_lxc_ssh" {
  value       = "ssh root@${var.cerebro_ip}"
  description = "SSH command for Cerebro LXC"
}
