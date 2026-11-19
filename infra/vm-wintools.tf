# vm-wintools.tf — QEMU VM 103 "wintools": Windows 11 Pro tools VM (quick task 261111-woo)
#
# Purpose: a Windows box for vendor configuration tools — C-Bus Toolkit, ElkRP2,
# VictronConnect, VEConfigure. It is POWERED OFF by default (on_boot = false) and is
# started only for a session, because atlantis has roughly 6 GiB MemAvailable and a
# record of memory-exhaustion freezes; a running 4 GiB guest is itself the hazard.
# Access is RDP through Termix. Operating notes: DEPLOYMENT.md and NETWORK.md (VM 103).
#
# (a) Terraform holds NO credential for this VM. The admin password lives only in
#     ~/.claude/secrets/winvm.env on the workstation and reaches atlantis only on stdin
#     to scripts/wintools-unattend.sh, which renders the answer file and destroys it
#     afterwards. There is deliberately no sensitive variable, no templatefile(), no
#     file provisioner and no null_resource here: tfstate is local, this repo is public,
#     and tfstate has leaked credentials before.
#
# (b) bpg/proxmox 0.95.0 allows only ONE `cdrom` block (MaxItems 1; multi-cdrom PR #2748
#     was never merged). The Windows ISO sits on ide2 here. virtio-win (ide0) and the
#     unattend ISO (sata0) are attached by `qm set` inside scripts/wintools-unattend.sh,
#     outside Terraform's model. `ignore_changes = [cdrom]` covers ejecting ide2 after
#     install; `started` covers the operator's `qm start` / `qm shutdown`.
#
# (c) The machine version is PINNED deliberately (pc-q35-11.1). Upgrading it re-enumerates
#     the NIC inside Windows and can flip the network profile back to Public, which closes
#     RDP. Never change it casually.
#
# (d) Only ever plan and apply this resource with -target, from a saved plan file kept
#     outside the repo:
#       terraform plan -target=proxmox_virtual_environment_vm.wintools -out=<outside-repo>.tfplan
#     A bare plan/apply in infra/ has planned to destroy LXC 100. Rollback is a saved
#     targeted destroy plan that must read "Plan: 0 to add, 0 to change, 1 to destroy."
#     with only this address (see DEPLOYMENT.md § VM 103).

resource "proxmox_virtual_environment_vm" "wintools" {
  node_name   = var.proxmox_node
  vm_id       = 103
  name        = "wintools"
  description = "Windows 11 Pro tools VM (C-Bus Toolkit, ElkRP2, VictronConnect, VEConfigure). Powered off by default; RDP via Termix. Managed by infra/vm-wintools.tf (targeted only)."

  started         = false # never let apply boot it
  on_boot         = false # RAM is tight on atlantis: start only for a session
  stop_on_destroy = true

  machine       = "pc-q35-11.1" # pinned — see header (c)
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single" # one controller per disk, so iothread works

  operating_system {
    type = "win11"
  }

  agent {
    enabled = true # harmless until qemu-ga is installed; started = false means no wait
  }

  cpu {
    cores = 2
    type  = "x86-64-v3"
  }

  memory {
    dedicated = 4096
    floating  = 4096 # balloon device present for stats, never inflated
  }

  efi_disk {
    datastore_id      = "local-lvm"
    type              = "4m"
    pre_enrolled_keys = true # Secure Boot with the Microsoft keys
  }

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0" # creation-only: changing it recreates the VM
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 64
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0" # flat LAN 172.16.1.0/24, DHCP from UniFi (no cloud-init)
    model  = "virtio"
  }

  cdrom {
    file_id   = "local:iso/Win11_x64_en-us.iso"
    interface = "ide2"
  }

  boot_order = ["scsi0", "ide2"]

  lifecycle {
    ignore_changes = [cdrom, started]
  }
}
