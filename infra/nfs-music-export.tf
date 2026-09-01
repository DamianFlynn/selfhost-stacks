# nfs-music-export.tf — Phase 2: read-only NFSv4 export of the tagged music library
#
# CONS-01: /mnt/tank/media/Music is served read-only to the Home Assistant NUC
# and the export is DEFINED IN TERRAFORM. It is served from the Proxmox host
# rather than from LXC 100 because nfsd is privileged-only — an unprivileged
# container cannot run it — and because the host is where the ZFS datasets are
# actually mounted.
#
# Runs over SSH on the Proxmox host to:
#   1. Install nfs-kernel-server if absent (PVE ships only nfs-common, the
#      client half) and ensure /etc/exports.d/ exists
#   2. Write /etc/exports.d/music.exports — the single Terraform-managed export
#      table, leaving /etc/exports untouched for anything else
#   3. Order nfs-server after zfs-mount.service via a systemd drop-in
#   4. Refuse to proceed unless the library dataset is genuinely mounted
#   5. Enable + start nfs-server and converge the kernel export table
#   6. Assert the export is present and that no_root_squash is not
#
# All operations are idempotent — safe to re-run if the resource is tainted.
#
# ── Why this resource has `triggers` when host.tf's does not ────────────────
# A null_resource re-creates only when a triggers value changes. host.tf's
# null_resource.host_setup has no triggers at all, so it never re-runs even
# when its inline script is edited — its provisioners fire once, at create.
# Copying that here would make an edit to the export line silently inert, and
# would make "a re-apply is clean" measure nothing. local.music_export_file is
# a pure function of variables, so keying triggers on it makes this resource
# both stable across repeated plans and responsive to a real change.
#
# ── Security note: transport and authentication ─────────────────────────────
# The export runs sec=sys — the client asserts its own uids and the server
# believes it. Two stronger options were considered and REJECTED:
#
#   * xprtsec= / RPC-with-TLS (RFC 9289): rejected. It requires tlshd running
#     and configured with certificates on BOTH ends, and the client end is a
#     Home Assistant OS appliance. That is a certificate lifecycle to own
#     forever, for one read-only LAN-local music share.
#   * sec=krb5: rejected. It means standing up and operating a KDC for a
#     single read-only share, and HAOS-side krb5 support for a Supervisor
#     mount is unproven.
#
# Accepted residual risk: on a trusted LAN, any device that can spoof the
# NUC's address can read the library read-only. That is bounded by ro +
# all_squash + a single-host specification, and 2049 is not forwarded at the
# perimeter. Recorded here rather than left as a silence.

# ── Export definition ───────────────────────────────────────────────────────
# The option list is deliberate and each absence is as deliberate as each
# presence:
#   ro               the library tree is mode 0777 and knfsd does not export
#                    ZFS NFSv4 ACLs, so mode bits are all a client sees —
#                    server-side ro is the only real write control there is
#   all_squash       maps EVERY client uid, including 0, to anonuid/anongid.
#                    This is what makes the root_squash question moot
#   anonuid/anongid  interpolated from var.apps_uid/var.apps_gid, the same
#                    values Phase 1 normalised the library to. Never write 568
#                    as a literal — the point is that the inheritance is
#                    visible in the code
#   mountpoint       export nothing rather than the empty stub directory if
#                    nfs-server ever starts before the dataset is mounted.
#                    PROVEN 2026-09-01 (plan 02-08) — see the note below.
#   no_subtree_check the default and recommended setting; subtree checking is
#                    unreliable across renames
#   sec=sys          see the security note above
#
# ── `mountpoint` IS ENFORCED. Measured 2026-09-01. Do not remove it. ─────────
# Plans 02-03 and 02-05 both recorded this option as "configured but UNPROVEN"
# and 02-03 raised a threat flag against this file for it. Both were wrong, and
# the reason is worth keeping because it is an instrument error, not a defect:
#
#   `exportfs -v` KEEPS PRINTING THE EXPORT LINE while the dataset is unmounted.
#   That observation was correct. The inference drawn from it — that the option
#   does nothing — was not. The export TABLE is non-discriminating; the SERVED
#   MOUNT is genuinely refused.
#
# The discriminating pair, same command, same client (the HA NUC), minutes apart,
# `sudo mount -t nfs4 -o ro,soft,timeo=50,retrans=2 <server>:<path> /tmp/m1probe`:
#   dataset MOUNTED    -> exit 0,   14 entries visible
#   dataset UNMOUNTED  -> exit 255, "failed: No such file or directory", 0 entries
# (`zfs unmount` without -f, behind a dead-man restore. `exportfs -v` printed the
#  identical line in both states.)
#
# So: never assert export health from `exportfs -v` alone. It will pass against
# an export that refuses every client. The `mountpoint`-quality check is a real
# client mount attempt, or nothing.
#
# M2 (`After=zfs-mount.service`, installed below) remains the boot-race guard;
# `mountpoint` is a proven second layer beneath it rather than an untested hope.
#
# Deliberately ABSENT:
#   fsid=            would relocate the NFSv4 pseudo-root; both consumers
#                    address this share as server:/full/path and would break
#   crossmnt         would implicitly export any child dataset created under
#                    the library later — a silent scope expansion
#   no_root_squash   forbidden outright, and moot under all_squash
locals {
  music_export_path = "/mnt/tank/media/Music"

  # ── Reading `exportfs -v` correctly, once, in one place ────────────────────
  # `exportfs -v` WRAPS: when the path is long the client(options) field lands
  # on its own continuation line. Assertions that grep the raw output can
  # therefore credit a client string to the wrong export entirely.
  # scripts/check-music-consumers.sh:477-482 already carried this join; the
  # apply gates below did not, which is what WR-04 was. Defined as a local so
  # the two gates that need it cannot drift apart from each other.
  exportfs_joined = "exportfs -v | awk '/^[^[:space:]]/ { if (NR>1) printf \"\\n\"; printf \"%s\", $0; next } { printf \" %s\", $1 } END { printf \"\\n\" }'"

  music_export_line = "${local.music_export_path} ${var.ha_nuc_ip}(ro,all_squash,anonuid=${var.apps_uid},anongid=${var.apps_gid},mountpoint,no_subtree_check,sec=sys)"

  music_export_file = <<-EOT
    # Managed by Terraform (infra/nfs-music-export.tf). Do not edit by hand.
    # CONS-01: read-only export of the tagged music library to the HA NUC.
    ${local.music_export_line}
  EOT

  # ── Temporary control export (see the second resource below) ──────────────
  # The scratch path is created as its OWN ZFS dataset rather than as a plain
  # directory. Reason: the option list below keeps `mountpoint`, and a plain
  # directory is not a mount point, so knfsd would refuse to export it. The
  # alternative — dropping `mountpoint` from this line only — would mean two
  # divergent option sets to review instead of one. A dataset under
  # tank/downloads is cheap, so keeping the option sets identical wins.
  music_temp_export_dataset = trimprefix(var.music_temp_export_path, "/mnt/")

  music_temp_export_line = "${var.music_temp_export_path} ${var.ha_nuc_ip}(ro,all_squash,anonuid=${var.apps_uid},anongid=${var.apps_gid},mountpoint,no_subtree_check,sec=sys)"

  music_temp_export_file = <<-EOT
    # Managed by Terraform (infra/nfs-music-export.tf). Do not edit by hand.
    # TEMPORARY: scratch export for the album-artist fallback control.
    # Removed by setting music_temp_export_enabled = false and re-applying.
    ${local.music_temp_export_line}
  EOT
}

# ── The music export, its server, and its boot ordering ─────────────────────
# One resource owns all of it deliberately: a guarded install that lives in the
# same place as the file it exists to serve cannot drift apart from it, and a
# re-apply of the pair is a no-op.
resource "null_resource" "nfs_music_export" {
  depends_on = [null_resource.host_setup]

  triggers = {
    # Re-run whenever the generated export table changes — this is the whole
    # reason triggers exist here (see the file header).
    exports_content = local.music_export_file
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

  # Runs BEFORE the file provisioner below, and must: scp/sftp will not create
  # a missing parent directory, and /etc/exports.d/ does not exist on a stock
  # PVE host — the file write would fail on a first apply without this.
  provisioner "remote-exec" {
    inline = [
      # WR-06: `set -e` FIRST, in every inline list in this file.
      # Terraform concatenates `inline` into one script and reports the
      # provisioner's success as that script's exit status — i.e. the LAST
      # command's. It does not inject `set -e`. Every load-bearing gate here
      # uses an explicit `|| { ...; exit 1; }`, which is why they work, but a
      # command without one that is not last in its list fails silently.
      # The install below is exactly that case: a failed install (no archive
      # reachable, dpkg lock held, disk full) returned non-zero, `mkdir -p`
      # then succeeded, and the provisioner reported success. The failure
      # surfaced two provisioners later as "unit not found" from
      # `systemctl enable --now nfs-server` — a message that does not point at
      # the package that did not install.
      "set -e",

      # PVE ships only nfs-common (the client half); the server comes from the
      # Debian archive, which host.tf has already configured and updated.
      # Guarded so a re-apply is a no-op rather than a package transaction.
      "dpkg -s nfs-kernel-server >/dev/null 2>&1 || (apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nfs-kernel-server)",

      # exports(5) reads /etc/exports.d/*.exports as extra export tables. The
      # directory is not guaranteed to exist even after the package install.
      "mkdir -p /etc/exports.d",
    ]
  }

  # A whole-file write is idempotent by construction; the repo's usual
  # `grep -q … || echo … >>` append-guard is not, and cannot express a removal.
  # This is the first provisioner "file" in infra/ — noted so the departure
  # from the neighbouring remote-exec idiom reads as a choice, not an accident.
  # The destination is a /etc/exports.d/ drop-in and NOT /etc/exports, so the
  # Terraform-managed surface is exactly one file.
  provisioner "file" {
    content     = local.music_export_file
    destination = "/etc/exports.d/music.exports"
  }

  provisioner "remote-exec" {
    inline = [
      # WR-06 — see the note on the first inline list above.
      "set -e",

      # ZFS datasets are not systemd .mount units, so RequiresMountsFor= has
      # nothing to resolve against. After=/Wants= is the only available lever
      # for making nfs-server start after the pools are mounted at boot.
      "mkdir -p /etc/systemd/system/nfs-server.service.d",
      # printf, not a here-doc: the inline list is a list of shell commands and
      # a multi-line here-doc does not survive that shape.
      "printf '[Unit]\\nAfter=zfs-mount.service\\nWants=zfs-mount.service\\n' > /etc/systemd/system/nfs-server.service.d/10-zfs-order.conf",
      # A drop-in that systemd has not re-read is a drop-in that does nothing.
      "systemctl daemon-reload",

      # The mountpoint export option protects the running server; this protects
      # the apply. Exporting the empty stub directory beneath an unmounted
      # dataset is the failure this pair exists to make impossible.
      "mountpoint -q ${local.music_export_path} || { echo 'FATAL: ${local.music_export_path} is not a mount point'; exit 1; }",

      # enable, not merely start — the ordering drop-in above is written for a
      # host reboot, and a unit that is not enabled will not be there to order.
      "systemctl enable --now nfs-server",
      # exportfs -ra re-syncs the kernel table to the files on disk. It
      # converges rather than appending, so running it every apply is safe.
      "exportfs -ra",

      # Gate 1 of 2 (the second is the standing consumers audit): a missing
      # export line means the apply reported success while serving nothing.
      #
      # WR-04: THIS ASSERTS THE PATH AND THE CLIENT ON THE SAME LINE.
      # It used to be `exportfs -v | grep -q '<nuc-ip>'`, which asserted only
      # that the client string appeared SOMEWHERE in the whole kernel export
      # table, never which export line it appeared on. With
      # music_temp_export_enabled = true the temporary export at
      # var.music_temp_export_path names the SAME client — so this gate passed
      # off the temp line even if /mnt/tank/media/Music had failed to export
      # entirely, and the apply would print "--- music export ready ---" while
      # serving only the scratch export.
      # local.exportfs_joined undoes the line wrapping first; without it the
      # path and its client are on different lines and cannot be matched
      # together at all. Same treatment check-music-consumers.sh:477-482
      # already applied, and the same reasoning as the NOTE at the bottom of
      # this file.
      "${local.exportfs_joined} | grep -qE '^${local.music_export_path}[[:space:]]+${var.ha_nuc_ip}\\(' || { echo 'FATAL: ${local.music_export_path} is not exported to ${var.ha_nuc_ip} after exportfs -ra'; exit 1; }",

      # Fail the apply outright if this ever appears. It is forbidden, it is
      # moot under all_squash, and its reappearance would mean someone edited
      # the option list without reading why it is absent.
      #
      # WR-05: SCOPED TO THE DROP-INS TERRAFORM OWNS. This used to scan the
      # whole kernel export table. The design statement at the top of this file
      # is explicit that Terraform owns exactly /etc/exports.d/music.exports
      # "leaving /etc/exports untouched for anything else" — so a whole-table
      # scan meant that the moment somebody added an unrelated no_root_squash
      # backup share to /etc/exports (a common Proxmox pattern), EVERY
      # terraform apply in infra/ would hard-fail with a FATAL about the music
      # export, for a condition the music export did not cause, from the far
      # end of a remote-exec where the message does not point at the real one.
      # If a whole-host no_root_squash guard is wanted, it belongs in its own
      # separately-named check so its failure is attributed correctly.
      # `cat ... | grep`, NOT `grep <file> <file>`: music-temp.exports is
      # ABSENT in steady state, and grep's exit status with an unreadable
      # operand is 2-or-0 depending on the grep. That ambiguity would decide
      # whether this gate fires. cat drops the missing file and grep then sees
      # one unambiguous stream. Measured, not assumed — the two-operand form
      # tested clean against a drop-in that DID contain no_root_squash.
      "cat /etc/exports.d/music.exports /etc/exports.d/music-temp.exports 2>/dev/null | grep -q 'no_root_squash' && { echo 'FATAL: no_root_squash in a Terraform-managed export drop-in'; exit 1; } || true",

      # Leave the evidence in the apply log rather than requiring a follow-up.
      "echo '--- music export ready ---' && exportfs -v",
    ]
  }
}

# ── Temporary control export — OFF by default ───────────────────────────────
# This export exists for exactly one job: proving that Music Assistant's
# missing_album_artist_action fallback actually fires, by scanning a control
# album that deliberately carries no album artist. Configuring that setting
# without observing it fire would leave its first real exercise to be the
# import pilot, at scale.
#
# It points at var.music_temp_export_path, a scratch dataset under
# tank/downloads. It NEVER points inside the tagged library — untagged content
# staged beneath the library root is exactly what the estate's staging rule
# forbids, and the control album is untagged on purpose.
#
# It is Terraform-managed behind an enable flag rather than hand-run, because
# a hand-run `exportfs` would drift the host from infra/ (which this repo
# forbids) and would leave removal as something a person has to remember.
# Teardown is `terraform apply` with music_temp_export_enabled = false: the
# resource is destroyed, the drop-in file is removed and the kernel table is
# re-converged. Provably gone, and visible in a plan diff.
#
# The package install and the systemd ordering drop-in are deliberately NOT
# repeated here — the main resource owns them, and this one depends on it.
resource "null_resource" "nfs_music_temp_export" {
  count = var.music_temp_export_enabled ? 1 : 0

  depends_on = [null_resource.nfs_music_export]

  triggers = {
    exports_content = local.music_temp_export_file
    revision        = "1"
  }

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # WR-06: without this, a failed `chown` below was not surfaced AT ALL —
      # it is not the last command in the list, the next provisioner is the
      # file upload, and the one after that runs exportfs -ra and a presence
      # check that passes. The comment on the chown states the exact
      # consequence ("apps must be able to read the scratch tree or the control
      # scans as an empty provider"), which is a silent pass by construction:
      # the control would report "no albums" and read as a fallback that did
      # not fire, rather than as a permissions failure.
      "set -e",

      # A dataset, not a plain directory — see the locals block for why the
      # option list keeps `mountpoint` and this therefore has to be one.
      "zfs list ${local.music_temp_export_dataset} >/dev/null 2>&1 || zfs create -p ${local.music_temp_export_dataset}",
      # all_squash maps the client to apps:apps, so apps must be able to read
      # the scratch tree or the control scans as an empty provider.
      "chown ${var.apps_uid}:${var.apps_gid} ${var.music_temp_export_path}",
    ]
  }

  # Second drop-in file, same whole-file-write reasoning as the main export.
  # A separate file so that disabling this one cannot disturb the other.
  # NOTE: this destination literal is repeated in the destroy-time provisioner
  # at the bottom of this resource, because a destroy provisioner cannot
  # interpolate anything. Change both together.
  provisioner "file" {
    content     = local.music_temp_export_file
    destination = "/etc/exports.d/music-temp.exports"
  }

  provisioner "remote-exec" {
    inline = [
      # WR-06 — see the note on the first inline list of this resource.
      "set -e",

      # Converge the kernel table onto both drop-ins.
      "exportfs -ra",
      # Same gate as the main export, and WR-04 applies here identically: match
      # the PATH AND THE CLIENT ON THE SAME (joined) LINE, so this cannot be
      # satisfied by the music export's line.
      "${local.exportfs_joined} | grep -qE '^${var.music_temp_export_path}[[:space:]]+${var.ha_nuc_ip}\\(' || { echo 'FATAL: temporary control export for ${var.ha_nuc_ip} not present after exportfs -ra'; exit 1; }",
      # Evidence in the apply log.
      "echo '--- temporary control export ready ---' && exportfs -v",
    ]
  }

}

# ── The teardown half of the temporary export ───────────────────────────────
# WITHOUT THIS RESOURCE, `music_temp_export_enabled = false` IS NOT A TEARDOWN.
#
# Destroying a null_resource only drops it from state. It does not remove the
# drop-in file that resource's `file` provisioner wrote, and it does not
# re-converge the kernel export table. The scratch export would stay LIVE while
# `terraform plan` reported clean and the state file said the resource was gone
# — a silent pass of exactly the shape this phase exists to prevent, and a
# direct falsification of D-15's "provably gone rather than forgotten".
#
# Measured in plan 02-07, which is what caught it, and asserted there on both
# sides afterwards.
#
# ── Why this is a separate resource and not a destroy-time provisioner ──────
# A `provisioner { when = destroy }` on nfs_music_temp_export was written first
# and REJECTED on measurement, for two independent reasons:
#
#   1. `terraform validate` fails it outright: "Destroy-time provisioners and
#      their connection configurations may only reference attributes of the
#      related resource, via 'self', 'count.index', or 'each.key'." The
#      resource-level `connection` block references var.proxmox_host /
#      _ssh_user / _ssh_password, so it cannot be reused at destroy time.
#   2. The only way to give a destroy provisioner those credentials is to carry
#      them in `triggers` — which persists the Proxmox root password to state in
#      plaintext AND renders it into every `terraform plan` diff. This repo is
#      PUBLIC and has already had one six-month credential exposure. Not a
#      trade worth making to save a resource block.
#
# `self.triggers.*` was also rejected on its own merits: at destroy time a
# trigger is read back from STATE, so any key added to the config after the
# resource was created reads null — `rm -f ""`, and far worse `grep -q ""`,
# which matches every line. A teardown has to work against state written before
# the teardown existed, or it is not a teardown.
#
# So the removal lives in a resource that ALWAYS EXISTS (no `count`), keyed on
# the flag, running at apply time with the normal connection block. Flipping
# the flag changes its trigger, which re-runs it. Teardown is still an apply,
# still visible in a plan diff, and still provable — which is all D-15 asked for.
#
# The main nfs_music_export resource was deliberately NOT used for this: adding
# a trigger there would plan a replacement of the LOAD-BEARING Music export
# every time the scratch flag moved, and re-running `systemctl enable --now
# nfs-server` against a live export to clean up a scratch one is the wrong
# blast radius.
#
# ── CR-03: THE ORDERING EDGE. Do not remove either entry from depends_on. ────
# This resource previously declared only `depends_on = [nfs_music_export]`,
# which is the SAME edge nfs_music_temp_export declares — so the two were
# siblings in the graph and Terraform walked them IN PARALLEL (default
# -parallelism=10). Nothing sequenced them at all.
#
# That is only invisible while the flag is steady. On the ENABLE transition
# (false -> true) both change in the same apply: nfs_music_temp_export[0] is
# created, and this resource's trigger flips, replacing it. Its enabled branch
# then asserts the temp export exists. Whichever won the race decided the
# outcome: if the reconciler won, the drop-in had not been written yet and the
# apply hard-failed with a FATAL describing a condition that was never true;
# if it lost, the assertion passed for a reason unconnected to the assertion.
# Both resources also ran `exportfs -ra` concurrently against the same kernel
# export table.
#
# The header above argues at length that this resource must exist so teardown
# is "still an apply, still visible in a plan diff, and still provable". The
# enable half was none of those things while the ordering was undefined.
#
# `depends_on` on a counted resource is valid when the count is 0, so this is
# correct in both directions: on enable the reconciler runs AFTER the export
# exists; on teardown nfs_music_temp_export[0] is destroyed (a state-only
# no-op) BEFORE the reconciler runs, which is the ordering the disabled branch
# already assumed without saying so.
#
# ── IN-07: this is a TRANSITION HOOK, not a reconciler. Known limitation. ────
# `triggers` is keyed on the flag alone, so it re-runs only when the flag
# CHANGES. With the flag steady at false a later `terraform apply` does not
# re-run the `rm -f` or the `exportfs -ra` — so a hand-recreated
# /etc/exports.d/music-temp.exports would persist across applies with a clean
# plan. That is a smaller instance of the drift this resource was created to
# close, and it is accepted rather than fixed: making it always-run needs
# timestamp() in triggers, which puts a permanent "1 to change" in every plan
# of this repo, and a plan that is never clean is a plan nobody reads.
# The standing detector for that drift is scripts/check-music-consumers.sh,
# which reaches atlantis on every health check and now asserts the export's
# full option set. If this limitation ever needs closing, close it there.
resource "null_resource" "nfs_music_temp_export_teardown" {
  depends_on = [
    null_resource.nfs_music_export,
    null_resource.nfs_music_temp_export,
  ]

  triggers = {
    # The flag itself IS the trigger. tostring() because triggers are strings.
    temp_enabled = tostring(var.music_temp_export_enabled)
  }

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # WR-06 — see the note on the first inline list of nfs_music_export.
      "set -e",

      var.music_temp_export_enabled
      ? "echo 'temporary control export is ENABLED — leaving /etc/exports.d/music-temp.exports in place'"
      : "rm -f /etc/exports.d/music-temp.exports",

      # Converge the kernel table onto whatever drop-ins remain on disk.
      # exportfs -ra converges rather than appends, so this is safe every apply.
      "exportfs -ra",

      # Prove the end state rather than trusting the two commands above.
      #
      # WR-05: ASSERT THE TWO KNOWN PATHS, NOT A COUNT OF EVERYTHING UNDER
      # ^/mnt/tank. The `-eq 2` / `-eq 1` counts these replaced were wrong in
      # two ways at once. They evaluated GLOBAL state, so any second
      # /mnt/tank/* export created by any mechanism — by a person, by another
      # config, by a future phase — hard-failed every subsequent
      # `terraform apply` in infra/ with a FATAL about the music export, which
      # is not what caused it. And the magic numbers named nothing: neither 1
      # nor 2 said WHICH exports were meant, so the coupling between them and
      # the two paths this file manages was invisible.
      #
      # Presence/absence of the two named paths is the assertion that was
      # actually intended, it is unaffected by unrelated exports, and its
      # failure message says which export is wrong. local.exportfs_joined
      # handles the line wrapping — the reason the old code counted PATH lines
      # rather than client lines, which is still the right instinct and is now
      # handled properly rather than by avoidance.
      var.music_temp_export_enabled
      ? "${local.exportfs_joined} | grep -qE '^${var.music_temp_export_path}[[:space:]]+${var.ha_nuc_ip}\\(' || { echo 'FATAL: the control is ENABLED but ${var.music_temp_export_path} is not exported to ${var.ha_nuc_ip}'; exit 1; }"
      : "test ! -e /etc/exports.d/music-temp.exports || { echo 'FATAL: temporary drop-in still on disk after rm'; exit 1; }",

      var.music_temp_export_enabled
      ? "true"
      : "${local.exportfs_joined} | grep -qE '^${var.music_temp_export_path}[[:space:]]' && { echo 'FATAL: ${var.music_temp_export_path} is STILL in the kernel export table after teardown'; exit 1; } || true",

      # The load-bearing music export must survive the teardown either way.
      # Nothing asserted this before: the disabled branch counted "exactly 1
      # /mnt/tank export" and would have been satisfied by the WRONG one.
      "${local.exportfs_joined} | grep -qE '^${local.music_export_path}[[:space:]]+${var.ha_nuc_ip}\\(' || { echo 'FATAL: ${local.music_export_path} is not exported to ${var.ha_nuc_ip} after the temp-export reconcile'; exit 1; }",

      "echo '--- export table after temp-export reconcile ---' && exportfs -v",
    ]
  }
}
