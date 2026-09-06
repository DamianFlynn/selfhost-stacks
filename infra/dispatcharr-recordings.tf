# DVR storage is independent of appdata. A full quota stops recording; it does
# not delete recordings or fill the SSD used by application databases.
resource "null_resource" "dispatcharr_recordings" {
  triggers = {
    quota = "250000000000"
    path  = "/mnt/tank/media/Recordings"
    mount = "mp31"
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
      "set -eu",
      "zfs list tank/media/Recordings >/dev/null 2>&1 || zfs create -o acltype=posixacl -o aclmode=discard -o aclinherit=restricted -o quota=${self.triggers.quota} -o recordsize=1M -o atime=off tank/media/Recordings",
      "zfs set quota=${self.triggers.quota} tank/media/Recordings",
      "mountpoint -q ${self.triggers.path}",
      "chown ${var.apps_uid}:${var.apps_gid} ${self.triggers.path}",
      "chmod 2775 ${self.triggers.path}",
      # mount_point is ignored by the provider to prevent LXC replacement.
      # Reconcile this one mount explicitly; never overwrite an occupied slot.
      "existing=$(pct config 100 | sed -n 's/^mp31: //p'); if [ -z \"$existing\" ]; then pct set 100 -mp31 ${self.triggers.path},mp=${self.triggers.path}; elif [ \"$existing\" != '${self.triggers.path},mp=${self.triggers.path}' ]; then echo 'mp31 is occupied by another mount' >&2; exit 1; fi",
      "zfs get -Hp -o property,value quota,mounted tank/media/Recordings",
    ]
  }
}
