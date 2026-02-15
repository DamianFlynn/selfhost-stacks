# host.tf — Phase 1: Proxmox host baseline
#
# Runs once via SSH on the Proxmox host to:
#   1. Remove enterprise subscription nags and update packages
#   2. Import fast + tank ZFS pools and register them for boot persistence
#   3. Create apps(568) user/group and GPU groups matching /dev/dri ownership
#   4. Configure /etc/subuid and /etc/subgid for the unprivileged LXC idmap
#   5. Download the Ubuntu 24.04 LXC template
#
# All operations are idempotent — safe to re-run if the resource is tainted.

resource "null_resource" "host_setup" {
  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # ── Proxmox hostname resolution ───────────────────────────────────────
      # Proxmox API routes container create/start requests by resolving the node
      # name internally. If 'pve' isn't in /etc/hosts the API returns HTTP 500.
      "grep -qE '\\b${var.proxmox_node}\\b' /etc/hosts || echo '${var.proxmox_host} ${var.proxmox_node}' >> /etc/hosts",

      # ── Package repos ─────────────────────────────────────────────────────
      # PVE 9.x ships BOTH legacy .list files AND DEB822 .sources files for the
      # enterprise repos. Both must be disabled or apt-get update returns 401.
      # Overwrite .list files with a comment (survives package updates better than rm).
      "echo '# pve-enterprise disabled' > /etc/apt/sources.list.d/pve-enterprise.list",
      "echo '# ceph-enterprise disabled' > /etc/apt/sources.list.d/ceph.list",
      # Rename .sources files to .disabled (|| true = harmless if already done).
      "mv /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/sources.list.d/pve-enterprise.sources.disabled 2>/dev/null || true",
      "mv /etc/apt/sources.list.d/ceph.sources /etc/apt/sources.list.d/ceph.sources.disabled 2>/dev/null || true",
      # PVE 9.x (Debian trixie) — use 'trixie', NOT 'bookworm' (that was PVE 8.x).
      "echo 'deb http://download.proxmox.com/debian/pve trixie pve-no-subscription' > /etc/apt/sources.list.d/pve-no-subscription.list",
      "apt-get update -qq",

      # ── ZFS pool import ───────────────────────────────────────────────────
      # The fast and tank pools live on separate drives from nvme0n1 (Proxmox OS).
      # Import with -f (force) to handle hostid mismatch after OS reinstall.
      "zpool import fast 2>/dev/null || zpool import -f fast 2>/dev/null || echo 'INFO: fast pool already imported or not available'",
      "zpool import tank 2>/dev/null || zpool import -f tank 2>/dev/null || echo 'INFO: tank pool already imported or not available'",

      # TrueNAS stores pool mountpoints as /fast and /tank (relative to its altroot /mnt).
      # Proxmox has no altroot so pools land at /fast and /tank after import.
      # Permanently fix the stored mountpoint so they mount at /mnt/fast and /mnt/tank.
      # ZFS atomically remounts the root dataset + all inheriting children.
      "zfs set mountpoint=/mnt/fast fast 2>/dev/null || true",
      "zfs set mountpoint=/mnt/tank tank 2>/dev/null || true",
      "zfs mount -a 2>/dev/null || true",

      # Register pools so they import automatically at every boot.
      "zpool set cachefile=/etc/zfs/zpool.cache fast 2>/dev/null || true",
      "zpool set cachefile=/etc/zfs/zpool.cache tank 2>/dev/null || true",
      "systemctl enable zfs-import-cache.service zfs-mount.service",

      # ── Bind-mount source dirs ────────────────────────────────────────────
      # These paths must exist on the host before the LXC container starts,
      # otherwise pct start will fail with "mount: special device not found".
      "mkdir -p /mnt/fast/stacks /mnt/fast/appdata /mnt/fast/home /mnt/fast/transcode /mnt/fast/tools /mnt/tank",

      # ── apps user/group ───────────────────────────────────────────────────
      # Must match the ownership of files already on the fast pool (uid/gid 568).
      "getent group apps >/dev/null 2>&1 || groupadd -g ${var.apps_gid} apps",
      # -r (system account) is required on Proxmox/Debian — without it useradd
      # rejects UIDs below UID_MIN (1000) even when the UID is explicitly specified.
      "id apps >/dev/null 2>&1 || useradd -r -u ${var.apps_uid} -g ${var.apps_gid} -M -s /usr/sbin/nologin apps",

      # ── GPU groups ────────────────────────────────────────────────────────
      # /dev/dri/card0      is owned by root:video  (gid 44 on Proxmox/Debian)
      # /dev/dri/renderD128 is owned by root:render
      # NOTE: Debian 13 assigns render a dynamic GID (~993). GID 103 is taken by tcpdump,
      # and GID 105 is taken by postdrop. We force it to render_gid (110) so the LXC
      # idmap passthrough works. The idmap math requires video(44) < render < apps(568).
      "getent group video  >/dev/null 2>&1 || groupadd -g ${var.video_gid} video",
      "getent group render >/dev/null 2>&1 || groupadd -g ${var.render_gid} render",
      "getent group render | grep -q ':${var.render_gid}:' || groupmod -g ${var.render_gid} render",
      # Re-trigger udev so /dev/dri/renderD128 picks up the corrected GID immediately.
      "udevadm trigger /dev/dri/ 2>/dev/null || true",

      # ── /etc/subuid — UID passthrough for unprivileged LXC idmap ─────────
      # root needs delegation rights for: apps uid (568) + standard range (100000+).
      "grep -q 'root:${var.apps_uid}:1' /etc/subuid || echo 'root:${var.apps_uid}:1' >> /etc/subuid",
      "grep -q 'root:100000:65536' /etc/subuid || echo 'root:100000:65536' >> /etc/subuid",

      # ── /etc/subgid — GID passthrough for unprivileged LXC idmap ─────────
      # root needs delegation rights for: video(44), render(110), apps(568) + standard range.
      "grep -q 'root:${var.video_gid}:1' /etc/subgid  || echo 'root:${var.video_gid}:1'  >> /etc/subgid",
      "grep -q 'root:${var.render_gid}:1' /etc/subgid || echo 'root:${var.render_gid}:1' >> /etc/subgid",
      "grep -q 'root:${var.apps_gid}:1' /etc/subgid   || echo 'root:${var.apps_gid}:1'   >> /etc/subgid",
      "grep -q 'root:100000:65536' /etc/subgid || echo 'root:100000:65536' >> /etc/subgid",

      # ── vmbr0 promiscuous mode — required for Docker macvlan inside LXC ─────
      # Docker macvlan containers get their own MAC addresses.  vmbr0 must forward
      # frames for those MACs or the containers (e.g. Jellyfin at 172.16.1.76) are
      # unreachable from the LAN.  'bridge-promisc yes' in /etc/network/interfaces
      # ensures this persists across reboots; ip link set applies it immediately.
      "grep -q 'promisc on' /etc/network/interfaces || sed -i '/^iface vmbr0/a \\\\tpost-up ip link set vmbr0 promisc on' /etc/network/interfaces",
      "ip link set vmbr0 promisc on 2>/dev/null || true",

      # ── appdata / stacks ownership ────────────────────────────────────────
      # Restore apps:apps ownership if chown was ever run as root during migration.
      "chown -R ${var.apps_uid}:${var.apps_gid} /mnt/fast/appdata /mnt/fast/stacks 2>/dev/null || true",

      # ── Ubuntu 24.04 LXC template ─────────────────────────────────────────
      "pveam update",
      "pveam list ${var.template_storage} | grep -q '${var.lxc_template}' || pveam download ${var.template_storage} ${var.lxc_template}",
    ]
  }
}
