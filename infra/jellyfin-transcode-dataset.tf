# ── fast/transcode: the Jellyfin transcode dataset and its bound ─────────────
#
# Phase 02.1 (TRAN-03, TRAN-07). This file DECLARES a dataset that already
# exists. Read that sentence twice, because the safety argument rests on it:
#
#   * fast/transcode is already present on atlantis, already mounted, already
#     empty, and already bind-mounted into LXC 100 as mp18 — declared at
#     infra/lxc-selfhost.tf:248-251. DO NOT TOUCH THAT MOUNT. It is the single
#     luckiest fact in this phase.
#   * It has nevertheless never been DECLARED. infra/host.tf:63 only `mkdir -p`s
#     the path as one entry in a list of bind-mount source directories; nothing
#     in infra/ has ever owned the dataset or a single one of its properties.
#   * Adding a `mount_point` to lxc-selfhost.tf would have been the obvious
#     move and is NOT NEEDED and would NOT WORK: that resource carries
#     `ignore_changes = [mount_point]` (lxc-selfhost.tf:322-341), so a bind-mount
#     edit there plans clean and does nothing.
#
# WHY THIS IS SAFE AGAINST THE DESTROY LANDMINE. A bare `terraform apply` in
# this directory was measured on 2026-08-31 to plan `1 to destroy` on
# `proxmox_virtual_environment_container.selfhost` — LXC 100 and its ~103
# containers. A `null_resource` adds NO ATTRIBUTE to that resource and does not
# appear in its dependency graph, so nothing here can move it. The landmine is
# untouched, not defused; every apply in this directory still goes through a
# saved plan file with a mechanical zero-destroys assertion, never a bare apply.
#
# WHICH PRECEDENT THIS COPIES. `infra/nfs-music-export.tf:139-186`, NOT
# `infra/lxc-mpe.tf:48-69`. This SUPERSEDES D-07's cited line reference
# (lxc-mpe.tf:48-50) while honouring D-07's intent — both 02.1-RESEARCH.md and
# 02.1-PATTERNS.md independently concluded the newer file is the correct source.
# The mpe resource has two defects that are fatal to THIS file's purpose: it has
# no `triggers` (so after the first apply it is inert and a later `quota=` edit
# plans clean and does nothing — which would defeat the entire point of putting
# these properties in code), and no `set -e` (so a failed `zfs set` is invisible).
#
# ── Property rationale (D-05) ────────────────────────────────────────────────
#
#   compression=off  Transcode segments are already-compressed H.264/HEVC. lz4
#                    would burn CPU on a host running 103 containers to save
#                    approximately nothing.
#   sync=disabled    The data is disposable by definition — it is a cache that
#                    the cutover chain deletes wholesale. WARNING: this must NOT
#                    be copied to any dataset holding non-disposable data. On an
#                    unclean shutdown it trades the last few seconds of writes
#                    for throughput, which is only acceptable because losing
#                    them costs a re-transcode and nothing else.
#   recordsize=1M    Large sequential segment writes. This is correct ONLY
#                    because the dataset is EMPTY today: recordsize applies to
#                    newly written blocks, never retroactively, so setting it
#                    after the cache has filled would do half a job.
#   atime=off        Nothing reads the access times of a transcode cache, and
#                    leaving them on turns every read into a write.
#
# ── quota, NOT refquota (D-15 / CONS-04) ─────────────────────────────────────
#
# Two independent reasons, both load-bearing:
#
#   1. refquota does not count descendants. A future child dataset or a snapshot
#      would escape the bound entirely — and the whole reason this bound exists
#      is that it must still hold when everything else has failed.
#   2. The errno differs. refquota returns EDQUOT ("Disk quota exceeded");
#      quota returns ENOSPC ("No space left on device"). ENOSPC is the errno the
#      incident's 764 zero-byte files already signature, and it is the string
#      every log grep in this estate is built on. Do not set refquota here.
#
# The quota is threaded through var.jellyfin_transcode_quota and is deliberately
# NOT inlined as a literal, matching how var.apps_uid, var.apps_gid and
# var.music_temp_export_path are handled elsewhere in infra/.

resource "null_resource" "jellyfin_transcode_dataset" {
  depends_on = [null_resource.host_setup]

  # WHY THIS BLOCK EXISTS AT ALL: without `triggers` a null_resource is INERT
  # after its first apply — Terraform has nothing to compare, so a later edit to
  # any property below plans clean and does nothing. That is precisely the
  # lxc-mpe.tf defect this file was written to avoid, and it would silently
  # convert "the properties are code" into "the properties were code once".
  #
  # EVERY VALUE THE PROVISIONER INTERPOLATES MUST APPEAR HERE. The reviewed
  # version of this plan had the uid/gid pair in `inline` only, reproducing the
  # same defect for two of them: an apps_uid change would have planned clean.
  triggers = {
    properties = join(",", [
      "quota=${var.jellyfin_transcode_quota}",
      "compression=off",
      "sync=disabled",
      "recordsize=1M",
      "atime=off",
    ])
    owner    = "${var.apps_uid}:${var.apps_gid}"
    revision = "1"
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
      # WR-06: `set -e` FIRST. Terraform concatenates `inline` into a single
      # script and reports the provisioner's success as that script's exit
      # status — i.e. the LAST command's. It does not inject `set -e`. Without
      # this line a failed `zfs set quota=` is invisible: the read-back below
      # still runs, still exits 0, and the apply reports success while the
      # bound this entire phase exists to install is simply absent.
      "set -e",

      # Guarded create. The dataset exists today, so this is a no-op in
      # practice; it is here so the declaration is true on a rebuilt host
      # rather than depending on host.tf having run `mkdir -p` first.
      "zfs list fast/transcode >/dev/null 2>&1 || zfs create -p fast/transcode",

      # Idempotent by construction: setting a ZFS property to its current value
      # is a no-op, so a re-apply costs five cheap ioctls and changes nothing.
      "zfs set quota=${var.jellyfin_transcode_quota} fast/transcode",
      "zfs set compression=off fast/transcode",
      "zfs set sync=disabled fast/transcode",
      "zfs set recordsize=1M fast/transcode",
      "zfs set atime=off fast/transcode",

      # CONDITIONAL chown, not an unconditional one. The mountpoint is
      # drwxrwsr-x and the setgid bit is what gives newly created transcode
      # files the apps group; running chown on every trigger change is at best
      # pointless churn and at worst a way to lose it.
      "[ \"$(stat -c %u:%g /mnt/fast/transcode)\" = \"${var.apps_uid}:${var.apps_gid}\" ] || chown ${var.apps_uid}:${var.apps_gid} /mnt/fast/transcode",

      # Re-assert the mode immediately after, UNCONDITIONALLY, so the setgid bit
      # is a stated invariant rather than a hope. chmod is idempotent, and doing
      # it this way removes the question entirely instead of reasoning about
      # whether Linux's chown strips SGID from a directory.
      "chmod 2775 /mnt/fast/transcode",

      # Echo the applied ownership and mode into the run log.
      "stat -c '%a %U:%G %n' /mnt/fast/transcode",

      # Echo the applied ZFS state, INCLUDING `mounted`. A green quota on an
      # UNMOUNTED dataset is a false pass of exactly the shape this phase exists
      # to stop being fooled by: the bind still works, the container still
      # writes, the quota does not apply, and the property still reads back
      # 53687091200.
      #
      # The -p is MANDATORY. In its parsable form recordsize prints 1048576; in
      # the human form it prints 1M, and every assertion downstream is written
      # against the byte integer.
      "zfs get -Hp -o property,value quota,compression,sync,recordsize,atime,mounted fast/transcode",
    ]
  }
}
