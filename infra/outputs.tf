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

    # NFS Home Assistant backup export (see nfs-ha-backup-export.tf):
    ssh root@${var.proxmox_host} "cat /etc/exports.d/ha-backup.exports"
    # Must show rw, all_squash and NO no_root_squash. Scope the no_root_squash
    # check to the drop-ins Terraform owns — /proc/fs/nfsd/exports shows four
    # auto-generated v4root traversal hits once a client mounts, which are not
    # a regression.
    ssh root@${var.proxmox_host} "grep -c no_root_squash /etc/exports.d/ha-backup.exports"
    # Dataset must be acltype=posix (mode bits are only enforceable there — the
    # whole basis for this export being rw) and 568:568 0770.
    ssh root@${var.proxmox_host} "zfs get -H -o value acltype ${trimprefix(var.ha_backup_export_path, "/mnt/")}"
    ssh root@${var.proxmox_host} "stat -c '%u:%g %a' ${var.ha_backup_export_path}"
    ssh root@${var.proxmox_host} "zfs list -o name,used,refquota ${trimprefix(var.ha_backup_export_path, "/mnt/")}"

    # From the HA NUC (LAN, not tailnet — the exports name ${var.ha_nuc_ip} only).
    # NOT showmount / findmnt: BOTH are absent from the HA SSH add-on's userland
    # (measured, plan 02-01 Task 3 measurement 7). Server-side enumeration is the
    # exportfs -v line above; client-side proof reads the fstype column of
    # /proc/self/mountinfo, which is verified readable from the add-on.
    nc -z -w 5 ${var.proxmox_host} 2049 && echo "2049 reachable"
    grep -E 'nfs|/media/music' /proc/self/mountinfo

    # THE ONLY CHECK THAT PROVES EXPORT HEALTH is a real client mount: plan 02-08
    # measured `exportfs -v` printing an intact line for an export that refused
    # every client. For the writable export the mount alone is not enough either —
    # a read-only regression mounts perfectly and fails on the first write — so
    # the round-trip is the assertion. Run from the NUC:
    sudo mkdir -p /tmp/habackupprobe
    sudo mount -t nfs4 -o softerr,timeo=100,retrans=2 ${var.proxmox_host}:${var.ha_backup_export_path} /tmp/habackupprobe
    sudo dd if=/dev/urandom of=/tmp/habackupprobe/rw-probe.bin bs=1M count=8
    # then on ${var.proxmox_host}: ls -ln ${var.ha_backup_export_path}  -> 8388608, owned ${var.apps_uid}:${var.apps_gid}
    sudo rm -f /tmp/habackupprobe/rw-probe.bin && sudo umount /tmp/habackupprobe && sudo rmdir /tmp/habackupprobe
  EOT
}
