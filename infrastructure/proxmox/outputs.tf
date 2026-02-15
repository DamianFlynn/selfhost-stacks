# outputs.tf — Post-apply reference information

output "proxmox_ui_url" {
  description = "Proxmox web UI"
  value       = "https://${var.proxmox_host}:8006"
}

output "lxc_vmid" {
  description = "VM ID of the Docker LXC"
  value       = var.lxc_vmid
}

output "lxc_ip" {
  description = "IP address of the Docker LXC (same as old TrueNAS)"
  value       = var.lxc_ip
}

output "lxc_ssh" {
  description = "SSH command to access the Docker LXC"
  value       = "ssh root@${var.lxc_ip}"
}

output "pct_shell" {
  description = "Proxmox console access (when SSH is not available)"
  value       = "ssh root@${var.proxmox_host} pct enter ${var.lxc_vmid}"
}

output "verify_commands" {
  description = "Quick verification commands to run after apply"
  value       = <<-EOT
    # On Proxmox host:
    ssh root@${var.proxmox_host} "zfs list | grep -E 'fast|tank'"
    ssh root@${var.proxmox_host} "pct list"
    ssh root@${var.proxmox_host} "grep -E 'idmap|cgroup2|mount.entry' /etc/pve/lxc/${var.lxc_vmid}.conf"

    # Inside LXC:
    ssh root@${var.lxc_ip} "docker info | grep 'Storage Driver'"
    ssh root@${var.lxc_ip} "ls /mnt/fast/stacks"
    ssh root@${var.lxc_ip} "ls -la /dev/dri/"
    ssh root@${var.lxc_ip} "id apps"
    ssh root@${var.lxc_ip} "ls -la /mnt/fast/appdata/traefik | head"
  EOT
}
