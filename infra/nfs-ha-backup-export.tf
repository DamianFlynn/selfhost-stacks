# nfs-ha-backup-export.tf — RES-04: read-WRITE NFSv4 export for Home Assistant backups
#
# Requested by the home-assistant-os project, Phase 2 (Observable House),
# requirement RES-04 — "daily automated backups stored off-NUC; a full restore
# tested and documented". Its plans 02-10 (off-NUC target) and 02-13 (timed
# restore drill) are both blocked on this export existing.
#
# Serves /mnt/tank/backups/homeassistant read-write to the Home Assistant NUC
# (var.ha_nuc_ip) and to nothing else, as a Supervisor backup target. Same
# shape as nfs-music-export.tf — an /etc/exports.d/ drop-in written whole,
# never a hand-edit, never a hand-run exportfs.
#
# ── Why a WRITABLE export is defensible here and is not under /mnt/tank/media ─
# nfs-music-export.tf says, correctly, that `ro` is forced rather than preferred:
# the library tree is 0777, knfsd does not export ZFS NFSv4 ACLs, so mode bits
# are the only lever a client sees — and 0777 means server-side `ro` is the only
# real write control there is.
#
# That reasoning is a property of THOSE DATASETS, not of the pool. Measured on
# atlantis 2026-09-01, `zfs get -s source`:
#
#   tank                acltype=posix   aclmode=discard   aclinherit=discard   (local)
#   tank/media/Music    acltype=nfsv4   aclmode=restricted aclinherit=passthrough (local)
#   tank/downloads      acltype=nfsv4   aclmode=restricted aclinherit=passthrough (local)
#   tank/timemachine    acltype=nfsv4   aclmode=restricted aclinherit=passthrough (local)
#
# The nfsv4 acltype is set LOCALLY on the TrueNAS-era datasets. `tank` itself is
# posix. So a NEW child of `tank` inherits posix ACLs, `chmod` works normally on
# it, and its mode bits are genuinely enforceable rather than decorative. That is
# what lets this export be `rw` behind a real 0770 instead of `rw` behind a 0777.
# The properties are set EXPLICITLY below rather than left to inheritance, so a
# later change to `tank` cannot silently take that guarantee away.
#
# CLAUDE.md's "chmod fails EPERM on tank even as real root" constraint is about
# the nfsv4-acltype datasets above. It does not apply to this one, and the mode
# assertion below is what proves that on every apply rather than assuming it.
#
# ── Security note: transport, authentication, and what rw widens ─────────────
# sec=sys, for the reasons nfs-music-export.tf records at length (RPC-with-TLS
# needs a certificate lifecycle on a HAOS appliance; krb5 needs a KDC). Not
# repeated here.
#
# What IS different from the music export: this one is writable, so the residual
# risk is no longer "a spoofed address can read the library" but "a spoofed
# address can write into the backup dataset". Bounded by: a single-host client
# spec, all_squash to an unprivileged uid, mode 0770 on a posix-ACL dataset, a
# refquota so it cannot exhaust the pool, 2049 not forwarded at the perimeter,
# and the blast radius stopping at a backup dataset that holds no live service
# data. Accepted, and recorded here rather than left as a silence.
#
# HA backups are encrypted by default; if that is ever turned off the tarballs
# contain .storage secrets, which is the other reason the mode is 0770 and not
# the 0777 the neighbouring media datasets carry.

# ── Export definition ───────────────────────────────────────────────────────
# Each option is deliberate, and each absence is as deliberate as each presence:
#   rw               the whole point — HA's Supervisor cannot use a read-only
#                    mount as a backup target. `ha mounts add --read-only` is
#                    documented by the CLI itself as "not available for backup
#                    mounts", so this is Supervisor's requirement, not a choice
#   all_squash       maps EVERY client uid, including 0, to anonuid/anongid.
#                    HA's Supervisor writes as root inside its own container;
#                    this is what makes those writes land as apps:apps and makes
#                    the no_root_squash question moot
#   anonuid/anongid  interpolated from var.apps_uid/var.apps_gid — the estate's
#                    service account. Never write 568 as a literal; the point is
#                    that the inheritance is visible in the code
#   mountpoint       export nothing rather than an empty stub directory if
#                    nfs-server ever starts before the dataset is mounted.
#                    Proven enforced by plan 02-08 — see nfs-music-export.tf's
#                    note, which is the measurement, not a hope
#   no_subtree_check the default and recommended setting
#   sec=sys          see the security note above
#
# Deliberately ABSENT:
#   no_root_squash   forbidden outright, moot under all_squash, and asserted
#                    absent below
#   async            a backup target must not acknowledge writes the server has
#                    not committed. `sync` is the default and is left alone
#   fsid=            would relocate the NFSv4 pseudo-root; both this and the
#                    music export are addressed as server:/full/path
#   crossmnt         would implicitly export any child dataset created under the
#                    backup dataset later — a silent scope expansion, and the
#                    reason the parent tank/backups is NOT the exported path
#   insecure         Supervisor mounts as root via systemd, so the source port is
#                    privileged and the default `secure` holds
#
# ── Reading `exportfs -v` correctly ─────────────────────────────────────────
# local.exportfs_joined is defined in nfs-music-export.tf. Locals are
# module-scoped, so it is REUSED rather than copied — its own comment says it
# exists precisely so the gates that need it cannot drift apart from each other.
# Adding a second copy here would recreate the drift it was written to prevent.
locals {
  # tank/backups/homeassistant — its own dataset, not a plain directory, because
  # the option list keeps `mountpoint` and a plain directory is not one. Same
  # reasoning the temporary music export records.
  ha_backup_dataset = trimprefix(var.ha_backup_export_path, "/mnt/")

  # /mnt/tank/backups — created by `zfs create -p` as a side effect, never
  # exported itself. It only has to be TRAVERSABLE: an NFSv4 client walks the
  # pseudo-root down to the export, and every ancestor is permission-checked
  # against the squashed credential. /mnt/tank is already 0755 root:root; this
  # is held to the same mode for the same reason.
  ha_backup_parent_dir = dirname(var.ha_backup_export_path)

  ha_backup_export_line = "${var.ha_backup_export_path} ${var.ha_nuc_ip}(rw,all_squash,anonuid=${var.apps_uid},anongid=${var.apps_gid},mountpoint,no_subtree_check,sec=sys)"

  ha_backup_export_file = <<-EOT
    # Managed by Terraform (infra/nfs-ha-backup-export.tf). Do not edit by hand.
    # RES-04: read-write export of the Home Assistant backup dataset to the HA NUC.
    ${local.ha_backup_export_line}
  EOT
}

# ── The Home Assistant backup export ────────────────────────────────────────
# depends_on the music export purely for ORDERING — both may run a guarded
# `apt-get install nfs-kernel-server`, and two concurrent apt transactions on the
# same host is a dpkg lock fight rather than a race worth having. Terraform's
# default -parallelism=10 would otherwise walk these two as siblings.
#
# The install guard itself IS repeated here rather than inherited, which is a
# deliberate departure from what nfs_music_temp_export does. That resource is a
# throwaway control for the music phase and is genuinely a satellite of the music
# export. This one serves a DIFFERENT project's requirement, and making it fail
# with "unit not found" because someone retired the music export would be a
# failure whose message points at the wrong file. The guard is one idempotent
# line; self-sufficiency is worth more than the duplication costs.
#
# The systemd After=zfs-mount.service drop-in is NOT repeated: it is a property
# of the nfs-server unit, not of any one export, and nfs_music_export owns it.
resource "null_resource" "nfs_ha_backup_export" {
  depends_on = [null_resource.nfs_music_export]

  triggers = {
    # Re-run whenever the generated export table changes — same reasoning as
    # nfs_music_export. Without triggers a null_resource's provisioners fire
    # once at create and an edit to the export line is silently inert.
    exports_content = local.ha_backup_export_file
    # The dataset properties are not in the export file, so a change to the
    # quota alone would not otherwise re-run the provisioners.
    refquota = var.ha_backup_refquota
    # Bump to force a re-run without changing the export itself.
    revision = "1"
  }

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "5m"
  }

  # Runs BEFORE the file provisioner: scp/sftp will not create a missing parent
  # directory, and the dataset has to exist before anything can be exported.
  provisioner "remote-exec" {
    inline = [
      # WR-06: `set -e` FIRST, in every inline list in this file. Terraform
      # concatenates `inline` into one script and reports the provisioner's
      # success as the LAST command's exit status. It does not inject `set -e`.
      # Every load-bearing gate below uses an explicit `|| { ...; exit 1; }`,
      # but a command without one that is not last in its list fails silently —
      # which is exactly how a failed `chown` would have turned into a backup
      # target that mounts fine and rejects every write.
      "set -e",

      # PVE ships only nfs-common (the client half). Guarded, so a re-apply is a
      # no-op rather than a package transaction. See the header for why this is
      # repeated rather than inherited from nfs_music_export.
      "dpkg -s nfs-kernel-server >/dev/null 2>&1 || (apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nfs-kernel-server)",

      # exports(5) reads /etc/exports.d/*.exports as extra export tables.
      "mkdir -p /etc/exports.d",

      # ── The dataset ─────────────────────────────────────────────────────────
      # -p also creates tank/backups, which is deliberate: it gives future
      # off-host backup targets somewhere to live without widening THIS export,
      # because the export names the leaf and `crossmnt` is absent.
      #
      # The ACL properties are set EXPLICITLY rather than inherited. `tank` is
      # acltype=posix today, which is what makes the 0770 below real — but
      # relying on inheritance would mean a later `zfs set acltype=nfsv4 tank`
      # silently converts this dataset's mode bits into decoration on the next
      # dataset created, with a writable export sitting on top of it.
      # recordsize=1M matches tank/timemachine and suits ~440 MB backup tarballs
      # written sequentially.
      "zfs list ${local.ha_backup_dataset} >/dev/null 2>&1 || zfs create -p -o acltype=posix -o aclmode=discard -o aclinherit=discard -o recordsize=1M ${local.ha_backup_dataset}",

      # Unconditional, so a dataset that already existed (hand-made, or made by
      # an earlier revision of this file) CONVERGES rather than being skipped by
      # the create guard above. zfs set is idempotent.
      "zfs set acltype=posix aclmode=discard aclinherit=discard recordsize=1M refquota=${var.ha_backup_refquota} ${local.ha_backup_dataset}",

      # An acltype that is not posix means the chmod below is decoration and the
      # export is effectively 0777. Assert the OBSERVED value rather than trust
      # the `zfs set` above — this is the single property the rw decision rests
      # on, and it is cheap to check.
      "test \"$(zfs get -H -o value acltype ${local.ha_backup_dataset})\" = 'posix' || { echo 'FATAL: ${local.ha_backup_dataset} is not acltype=posix — mode bits would not be enforceable and a rw export would be effectively world-writable'; exit 1; }",

      # ── Ownership and mode ──────────────────────────────────────────────────
      # all_squash maps the client to apps:apps, so the dataset must be owned by
      # it or every write is refused. 0770 and not 0777: this dataset's mode bits
      # are real (see the header), and HA backups can contain .storage secrets.
      "chown ${var.apps_uid}:${var.apps_gid} ${var.ha_backup_export_path}",
      "chmod 0770 ${var.ha_backup_export_path}",

      # The parent is NOT exported and is NOT owned by apps. It only has to be
      # traversable by the squashed uid so the NFSv4 client can walk the
      # pseudo-root down to the export. Same mode as /mnt/tank, which already
      # demonstrates this working for the music export.
      "chmod 0755 ${local.ha_backup_parent_dir}",

      # Assert the RESULT, not the commands. On the nfsv4-acltype datasets in
      # this pool chmod returns EPERM even as real root; `set -e` would catch
      # that, but a mode that was silently clamped by an inherited ACL would not
      # raise anything at all. This is the gate that turns "we ran chmod" into
      # "the mode is 0770", and it is the difference between a backup target that
      # works and one that mounts and then refuses every write.
      "test \"$(stat -c '%u:%g %a' ${var.ha_backup_export_path})\" = '${var.apps_uid}:${var.apps_gid} 770' || { echo \"FATAL: ${var.ha_backup_export_path} is $(stat -c '%u:%g %a' ${var.ha_backup_export_path}), expected ${var.apps_uid}:${var.apps_gid} 770\"; exit 1; }",
    ]
  }

  # A whole-file write is idempotent by construction and can express a removal;
  # the repo's `grep -q … || echo … >>` append-guard is neither. Destination is a
  # /etc/exports.d/ drop-in and NOT /etc/exports, so the Terraform-managed
  # surface stays exactly one file per export.
  provisioner "file" {
    content     = local.ha_backup_export_file
    destination = "/etc/exports.d/ha-backup.exports"
  }

  provisioner "remote-exec" {
    inline = [
      # WR-06 — see the note on the first inline list above.
      "set -e",

      # The mountpoint export option protects the running server; this protects
      # the apply. Exporting an empty stub directory beneath an unmounted dataset
      # is the failure this pair exists to make impossible.
      "mountpoint -q ${var.ha_backup_export_path} || { echo 'FATAL: ${var.ha_backup_export_path} is not a mount point'; exit 1; }",

      # enable, not merely start — nfs_music_export's After=zfs-mount.service
      # drop-in is written for a host reboot, and a unit that is not enabled will
      # not be there to order.
      "systemctl enable --now nfs-server",
      # exportfs -ra converges the kernel table onto the drop-ins rather than
      # appending to it, so running it every apply is safe.
      "exportfs -ra",

      # ── Gate: the export exists, rw, for this client ────────────────────────
      # WR-04: assert the PATH AND THE CLIENT ON THE SAME line. `exportfs -v |
      # grep <ip>` would pass off the MUSIC export's line, because that names the
      # same client — an apply could report this export ready while serving
      # nothing. local.exportfs_joined (defined in nfs-music-export.tf) undoes
      # exportfs's line wrapping first; without it the path and its client are on
      # different lines and cannot be matched together at all.
      "${local.exportfs_joined} | grep -qE '^${var.ha_backup_export_path}[[:space:]]+${var.ha_nuc_ip}\\(' || { echo 'FATAL: ${var.ha_backup_export_path} is not exported to ${var.ha_nuc_ip} after exportfs -ra'; exit 1; }",

      # An export that came up `ro` is a backup target that mounts cleanly and
      # then fails every backup — the exact silent-pass shape this repo keeps
      # finding. exportfs prints the effective options, so this reads what the
      # kernel decided rather than what the drop-in asked for.
      "${local.exportfs_joined} | grep -E '^${var.ha_backup_export_path}[[:space:]]+${var.ha_nuc_ip}\\(' | grep -qE '[(,]rw[,)]' || { echo 'FATAL: ${var.ha_backup_export_path} is exported to ${var.ha_nuc_ip} but NOT rw — HA Supervisor cannot use a read-only backup mount'; exit 1; }",

      # ── Gate: no_root_squash ───────────────────────────────────────────────
      # Fail the apply outright if this ever appears. It is forbidden, it is moot
      # under all_squash, and its reappearance would mean someone edited the
      # option list without reading why it is absent.
      #
      # WR-05: SCOPED TO THIS FILE'S OWN DROP-IN. A whole-table scan would mean
      # an unrelated no_root_squash share added to /etc/exports hard-fails every
      # `terraform apply` in infra/ with a FATAL about the HA backup export, for
      # a condition it did not cause.
      #
      # It also deliberately does NOT read /proc/fs/nfsd/exports: STATE.md
      # records that showing four no_root_squash hits once a client mounts, which
      # are auto-generated v4root pseudo-root traversal entries and not a
      # regression. Asserting there would fail on a healthy system.
      "grep -q 'no_root_squash' /etc/exports.d/ha-backup.exports && { echo 'FATAL: no_root_squash in the Terraform-managed HA backup export drop-in'; exit 1; } || true",

      # Leave the evidence in the apply log rather than requiring a follow-up.
      # NOTE: `exportfs -v` proves the TABLE, never the SERVED MOUNT — plan 02-08
      # measured it printing an intact line for an export that refused every
      # client. The only export-health check that means anything is a real client
      # mount attempt from the NUC; see NETWORK.md for the command.
      "echo '--- HA backup export ready ---' && exportfs -v && zfs list -o name,used,avail,refquota,mountpoint ${local.ha_backup_dataset} && ls -lnd ${var.ha_backup_export_path}",
    ]
  }
}
