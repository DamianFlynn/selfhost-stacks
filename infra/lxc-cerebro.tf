# lxc-cerebro.tf — Docker LXC for Cerebro/Ollama workloads

locals {
  cerebro_conf = "/etc/pve/lxc/${var.cerebro_vmid}.conf"

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
    swap      = 0
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

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i '/^lxc\\.cgroup2\\.devices\\.allow:.*226/d;/^lxc\\.mount\\.entry:.*dri/d' ${local.cerebro_conf}",
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.cerebro_gpu_card_minor} rwm' >> ${local.cerebro_conf}",
      "echo 'lxc.cgroup2.devices.allow: c 226:${local.cerebro_gpu_render_minor} rwm' >> ${local.cerebro_conf}",
      "echo 'lxc.mount.entry: /dev/dri/${local.cerebro_gpu_card} dev/dri/${local.cerebro_gpu_card} none bind,optional,create=file' >> ${local.cerebro_conf}",
      "echo 'lxc.mount.entry: /dev/dri/${local.cerebro_gpu_render} dev/dri/${local.cerebro_gpu_render} none bind,optional,create=file' >> ${local.cerebro_conf}",
      "echo '--- Cerebro LXC GPU patch applied ---' && grep -E 'lxc\\.(cgroup2|mount)' ${local.cerebro_conf}",
    ]
  }
}

resource "null_resource" "start_cerebro_lxc" {
  depends_on = [null_resource.patch_cerebro_lxc_config]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "pct start ${var.cerebro_vmid}",
      "timeout 90 bash -c 'until bash -c \"echo >/dev/tcp/${var.cerebro_ip}/22\" 2>/dev/null; do sleep 3; done' && echo 'Cerebro LXC SSH ready'",
      "pct exec ${var.cerebro_vmid} -- sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "pct exec ${var.cerebro_vmid} -- sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "pct exec ${var.cerebro_vmid} -- systemctl restart ssh",
    ]
  }
}

resource "null_resource" "provision_cerebro_lxc" {
  depends_on = [null_resource.start_cerebro_lxc]

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
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl gnupg",
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
