# vm-cerebro.tf — Ubuntu 24.04 LTS VM for Cerebro AI assistant
#
# Migration from LXC to VM provides:
#   • Full systemd support (including user services)
#   • Better AMD GPU passthrough (PCIe, not cgroup device mapping)
#   • Stable Ubuntu 24.04 LTS (vs Debian Trixie testing)
#   • Easier snapshots and live migration
#   • More RAM (8GB vs 4GB)
#
# Phase ordering:
#   1. proxmox_virtual_environment_vm.cerebro     [VM creation with Ubuntu ISO]
#   2. null_resource.cerebro_wait_install         [Wait for manual installation]
#   3. null_resource.cerebro_provision            [Provision Node.js, Ollama, Cerebro]
#   4. null_resource.cerebro_restore_config       [Restore from backup]
#
# After creation:
#   1. Start VM (VMID 102) from Proxmox UI
#   2. Complete Ubuntu 24.04 installation via console
#   3. Configure static IP: 172.16.1.160/24
#   4. Run: terraform apply -target=null_resource.cerebro_provision
#   5. Restore config: scp backups/cerebro-config-backup-*.tar.gz root@172.16.1.160:/tmp/

# Cerebro VM - Ubuntu 24.04 LTS
resource "proxmox_virtual_environment_vm" "cerebro" {
  depends_on = [null_resource.host_setup]

  node_name = var.proxmox_node
  vm_id     = var.cerebro_vmid
  name      = var.cerebro_hostname
  
  description = <<-EOT
    Cerebro AI Gateway - Ubuntu 24.04 LTS
    GPU: AMD Radeon 890M (card1, renderD128)
    RAM: ${var.cerebro_memory_mb}MB | CPU: ${var.cerebro_cores} cores
    IP: ${var.cerebro_ip}

    Authoritative Terraform-managed Cerebro VM
  EOT

  started = true
  on_boot = true

  # BIOS and machine type
  bios = "ovmf"
  machine = "q35"

  # CPU configuration
  cpu {
    cores = var.cerebro_cores
    type  = "host"
  }

  # Memory configuration (8GB)
  memory {
    dedicated = var.cerebro_memory_mb
  }

  # Network configuration
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Boot disk
  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi0"
    size         = var.cerebro_disk_gb
    ssd          = true
    discard      = "on"
    iothread     = true
  }

  dynamic "hostpci" {
    for_each = trimspace(var.cerebro_gpu_pci_id) != "" ? [1] : []
    content {
      device = "hostpci0"
      id     = var.cerebro_gpu_pci_id
      pcie   = true
    }
  }

  dynamic "hostpci" {
    for_each = trimspace(var.cerebro_gpu_mapping) != "" ? [1] : []
    content {
      device  = "hostpci0"
      mapping = var.cerebro_gpu_mapping
      pcie    = true
    }
  }

  # CDROM with Ubuntu ISO
  cdrom {
    file_id   = "local:iso/ubuntu-24.04.4-live-server-amd64.iso"
    interface = "ide2"
  }

  # EFI disk
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  # SCSI hardware
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
    trim    = true
  }

  operating_system {
    type = "l26"  # Linux kernel 2.6+
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.cerebro_ip}/24"
        gateway = var.lxc_gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }

    user_account {
      username = "cerebro"
      password = var.cerebro_root_password
      keys     = var.cerebro_ssh_public_keys
    }
  }

  lifecycle {
    ignore_changes = [
      description,
      cdrom,
      initialization,
    ]

    precondition {
      condition     = trimspace(var.cerebro_gpu_pci_id) != "" || trimspace(var.cerebro_gpu_mapping) != ""
      error_message = "Set either cerebro_gpu_pci_id or cerebro_gpu_mapping to enable GPU passthrough for Cerebro VM."
    }

    precondition {
      condition     = !(trimspace(var.cerebro_gpu_pci_id) != "" && trimspace(var.cerebro_gpu_mapping) != "")
      error_message = "Set only one of cerebro_gpu_pci_id or cerebro_gpu_mapping, not both."
    }
  }
}

resource "null_resource" "cerebro_passthrough_tune" {
  depends_on = [proxmox_virtual_environment_vm.cerebro]

  triggers = {
    vm_id      = tostring(var.cerebro_vmid)
    gpu_pci_id = trimspace(var.cerebro_gpu_pci_id)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=accept-new ${var.proxmox_ssh_user}@${var.proxmox_host} "qm set ${var.cerebro_vmid} --vga none --hostpci0 '${var.cerebro_gpu_pci_id},pcie=1,rombar=0,x-vga=0'"
    EOT
  }
}

# ── Phase 2: Wait for Ubuntu installation ──────────────────────────────────
#
# After VM creation, manually:
#   1. Start VM from Proxmox UI
#   2. Open console and complete Ubuntu installation
#   3. Set hostname: cerebro
#   4. Username: cerebro, damian
#   5. Install OpenSSH server
#   6. Configure network: 172.16.1.160/24, gateway 172.16.1.1
#   7. Wait for installation to complete and reboot
#   8. Test SSH: ssh cerebro@172.16.1.160

resource "null_resource" "cerebro_wait_install" {
  depends_on = [null_resource.cerebro_passthrough_tune]

  # This resource is a placeholder for manual installation
  # Comment this out and run terraform apply after Ubuntu is installed

  provisioner "local-exec" {
    command = <<-EOT
      echo "╔══════════════════════════════════════════════════════════════╗"
      echo "║  Cerebro VM created (VMID ${var.cerebro_vmid})                        ║"
      echo "║                                                              ║"
      echo "║  Next steps:                                                 ║"
      echo "║  1. Start VM from Proxmox UI                                 ║"
      echo "║  2. Open console and install Ubuntu 24.04                    ║"
      echo "║  3. Configure:                                               ║"
      echo "║     - Hostname: Cerebro                                     ║"
      echo "║     - Users: cerebro, damian                                ║"
      echo "║     - IP: 172.16.1.160/24, GW: 172.16.1.1                    ║"
      echo "║     - Install OpenSSH server                                 ║"
      echo "║  4. After install, test SSH: ssh cerebro@172.16.1.160       ║"
      echo "║  5. Then run provisioning:                                   ║"
      echo "║     terraform apply -target=null_resource.cerebro_provision ║"
      echo "╚══════════════════════════════════════════════════════════════╝"
    EOT
  }
}

# ── Phase 3: Provision Cerebro after Ubuntu installation ──────────────────
#
# Install Node.js, Ollama, Cerebro, and configure services
# Run after Ubuntu installation: terraform apply -target=null_resource.cerebro_provision

resource "null_resource" "cerebro_provision" {
  triggers = {
    vm_id              = tostring(var.cerebro_vmid)
    provisioner_schema = "2"
  }

  connection {
    type     = "ssh"
    host     = var.cerebro_ip
    user     = "cerebro"
    password = var.cerebro_root_password
  }

  # Bootstrap SSH keys and non-interactive sudo access
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '==> Bootstrapping SSH keys and sudo policy'",
      "install -d -m 700 ~/.ssh",
      "touch ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys",
      "cat <<'EOF' >> ~/.ssh/authorized_keys",
      "${join("\n", var.cerebro_ssh_public_keys)}",
      "EOF",
      "sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys",
      "echo '${var.cerebro_root_password}' | sudo -S sh -c 'printf \"%s\\n\" \"cerebro ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/99-cerebro'",
      "echo '${var.cerebro_root_password}' | sudo -S chmod 440 /etc/sudoers.d/99-cerebro",
      "echo '${var.cerebro_root_password}' | sudo -S visudo -cf /etc/sudoers.d/99-cerebro",
    ]
  }

  # Install Docker CE
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '==> Installing QEMU guest agent'",
      "sudo -n apt-get update -y",
      "sudo -n apt-get install -y qemu-guest-agent",
      "sudo -n systemctl enable --now qemu-guest-agent",
      "systemctl is-active qemu-guest-agent",
      "",
      "echo '==> Installing Docker CE'",
      "sudo -n apt-get install -y ca-certificates curl gnupg",
      "sudo -n install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo -n gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg",
      "sudo -n chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable\" | sudo -n tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo -n apt-get update -y",
      "sudo -n apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo -n systemctl enable --now docker",
      "sudo -n usermod -aG docker cerebro",
      "sudo -n usermod -aG video,render cerebro || true",
      "docker --version",
    ]
  }

  # Install Node.js 24.x via NodeSource
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '==> Installing Node.js 24.x'",
      "curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -n -E bash -",
      "sudo -n apt-get install -y nodejs",
      "node --version",
      "npm --version",
    ]
  }

  # Install Ollama
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '==> Installing AMD user-space stack (VAAPI/Vulkan tools)'",
      "sudo -n apt-get install -y mesa-va-drivers mesa-vulkan-drivers vainfo vulkan-tools || true",
      "echo '==> Installing Ollama'",
      "curl -fsSL https://ollama.com/install.sh | sudo -n sh >/tmp/ollama-install.log 2>&1 || { sudo -n tail -n 200 /tmp/ollama-install.log; exit 1; }",
      "sudo -n systemctl enable ollama",
      "sudo -n systemctl start ollama",
      "sleep 5",
      "ollama --version",
    ]
  }

  # Pull Ollama models
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '==> Pulling Ollama models'",
      "ollama pull qwen2.5:3b",
      "ollama pull llama3.2:latest",
      "ollama list",
    ]
  }

  # Install the Apps: tmux
  # SWAP Disk - i need to add this to the VM also for better utilization
  
  # Create systemd service - not used at the moment
  #provisioner "remote-exec" {
  #  inline = [
  #    "set -e",
  #    "echo '==> Creating Cerebro systemd service'",
  #    "sudo -n tee /etc/systemd/system/cerebro-gateway.service > /dev/null <<'EOF'",
  #    "[Unit]",
  #    "Description=Cerebro AI Gateway",
  #    "After=network.target ollama.service",
  #    "Wants=ollama.service",
  #    "",
  #    "[Service]",
  #    "Type=simple",
  #    "User=cerebro",
  #    "Group=cerebro",
  #    "WorkingDirectory=/home/cerebro",
  #    "ExecStart=/usr/bin/cerebro gateway --bind lan",
  #    "Restart=on-failure",
  #    "RestartSec=10",
  #    "WatchdogSec=600",
  #    "TimeoutStartSec=120",
  #    "TimeoutStopSec=30",
  #    "StandardOutput=journal",
  #    "StandardError=journal",
  #    "",
  #    "[Install]",
  #    "WantedBy=multi-user.target",
  #    "EOF",
  #    "",
  #    "sudo -n systemctl daemon-reload",
  #    "sudo -n systemctl enable cerebro-gateway",
  #  ]
  #}

  provisioner "local-exec" {
    command = <<-EOT
      echo "╔══════════════════════════════════════════════════════════════╗"
      echo "║  Cerebro provisioning complete!                             ║"
      echo "║                                                              ║"
      echo "║  Next: Restore configuration from backup                     ║"
      echo "║  scp backups/cerebro-config-backup-*.tar.gz \\               ║"
      echo "║      cerebro@172.16.1.160:/tmp/                             ║"
      echo "║                                                              ║"
      echo "║  ssh cerebro@172.16.1.160                                   ║"
      echo "║  cd ~ && tar -xzf /tmp/cerebro-config-backup-*.tar.gz       ║"
      echo "║  sudo systemctl start cerebro-gateway                       ║"
      echo "╚══════════════════════════════════════════════════════════════╝"
    EOT
  }
}

# ── Outputs ──────────────────────────────────────────────────────────────────

output "cerebro_vm_id" {
  value       = proxmox_virtual_environment_vm.cerebro.vm_id
  description = "Cerebro VM ID"
}

output "cerebro_vm_ip" {
  value       = var.cerebro_ip
  description = "Cerebro VM IP address"
}

output "cerebro_vm_name" {
  value       = proxmox_virtual_environment_vm.cerebro.name
  description = "Cerebro VM name"
}
