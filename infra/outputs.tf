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

output "mpe_lxc_ssh" {
  description = "SSH command to access the MPE LXC (102)"
  value       = "ssh root@${var.mpe_ip}"
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

    # NFS music export, on Proxmox host (see nfs-music-export.tf):
    ssh root@${var.proxmox_host} "exportfs -v"
    ssh root@${var.proxmox_host} "cat /etc/exports.d/music.exports"
    ssh root@${var.proxmox_host} "systemctl is-active nfs-server; systemctl is-enabled nfs-server"
    ssh root@${var.proxmox_host} "systemctl show nfs-server -p After | tr ' ' '\n' | grep zfs-mount"
    # 2049 is this phase's only port delta — 111 (rpcbind) was already open
    # from the pre-existing nfs-common client packages.
    ssh root@${var.proxmox_host} "ss -lntp | grep -E ':(111|2049)'"

    # From the HA NUC (LAN, not tailnet — the export names ${var.ha_nuc_ip} only).
    # NOT showmount / findmnt: BOTH are absent from the HA SSH add-on's userland
    # (measured, plan 02-01 Task 3 measurement 7). Server-side enumeration is the
    # exportfs -v line above; client-side proof reads the fstype column of
    # /proc/self/mountinfo, which is verified readable from the add-on.
    nc -z -w 5 ${var.proxmox_host} 2049 && echo "2049 reachable"
    grep -E 'nfs|/media/music' /proc/self/mountinfo
  EOT
}
