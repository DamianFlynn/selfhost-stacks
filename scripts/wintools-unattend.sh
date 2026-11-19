#!/usr/bin/env bash
# wintools-unattend.sh — runs ON atlantis (as root) from /root/wintools-build/ (mode 700).
# Quick task 261111-woo: unattended Windows 11 Pro install for QEMU VM 103 "wintools".
#
# Subcommands:
#   build     stdin line 1 = admin password; remaining stdin lines (to EOF) = the public keys
#             for C:\ProgramData\ssh\administrators_authorized_keys (saved to
#             /root/wintools-build/authorized_keys). Renders autounattend.xml from
#             wintools-autounattend.xml.tmpl, fetches/proves virtio-win, builds the unattend ISO,
#             attaches ide0 (virtio-win) + sata0 (unattend) with `qm set`, refuses to start below
#             5 GiB MemAvailable, starts the VM and presses Enter for the "boot from CD" prompt.
#             Any non-zero exit runs failexit from the EXIT trap.
#   cleanup   Ejects/deletes ide0 + sata0, shreds the unattend ISO and every rendered XML,
#             then ASSERTS they are gone. Non-zero if any assertion fails.
#   failexit  cleanup (failure recorded, not fatal), then stop VM 103 (shutdown, falling back to
#             qm stop), delete ide0/sata0, and ASSERT `status: stopped`. Idempotent; safe when
#             the VM is already stopped and nothing was rendered. Run it on EVERY abandoned build.
#
# Credentials (CONVENTIONS rule 7): the password arrives on stdin only and is substituted with
# bash parameter expansion. It is never in argv (no sed/envsubst), never echoed, and there is no
# `set -x` anywhere in this file. Terraform never sees it (infra/vm-wintools.tf header (a)).
#
# Destructive targets carry an inline literal-path fence at each call site (CONVENTIONS rule 6);
# each fence has its own REFUSED wording so a refusal names its site.
set -euo pipefail
umask 077

VMID=103
BUILD_DIR=/root/wintools-build
TMPL="$BUILD_DIR/wintools-autounattend.xml.tmpl"
UNATTEND_ISO=/var/lib/vz/template/iso/wintools-unattend.iso
VIRTIO_ISO=/var/lib/vz/template/iso/virtio-win-0.1.302.iso
VIRTIO_URL=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.302-1/virtio-win.iso
MIN_MEMAVAIL_KB=5242880 # 5 GiB
EXIT_LOWMEM=42          # distinct code: "refused: MemAvailable below 5 GiB"

vm_status() { # prints the bare state word (running/stopped/...), non-zero if it could not look
  local s
  s=$(timeout 30 qm status "$VMID") || return 1
  s=${s#status: }
  [ -n "$s" ] || return 1
  printf '%s\n' "$s"
}

present_cd_slots() { # prints the subset of ide0/sata0 present in the VM config
  local cfg
  cfg=$(timeout 30 qm config "$VMID") || return 1
  grep -oE '^(ide0|sata0):' <<<"$cfg" | tr -d ':' || true
}

memavail_kb() { awk '/^MemAvailable:/{print $2}' /proc/meminfo; }

do_cleanup() {
  # Explicit rc tracking throughout: this runs inside `( ) || rc=$?` from failexit, where
  # `set -e` is suspended, so nothing here may rely on errexit.
  local rc=0 st slots d
  if ! st=$(vm_status); then echo "CLEANUP: could not read qm status $VMID"; rc=1; st=unknown; fi
  if ! slots=$(present_cd_slots); then echo "CLEANUP: could not read qm config $VMID"; rc=1; slots=""; fi
  if [ "$st" = running ]; then
    # Live eject: the drive stays configured but empty; failexit/Task 2c delete it once stopped.
    for d in $slots; do
      if timeout 60 qm set "$VMID" "--$d" none,media=cdrom >/dev/null; then echo "CLEANUP: ejected $d (live)"
      else echo "CLEANUP: eject $d FAILED"; rc=1; fi
    done
  elif [ "$st" = stopped ]; then
    if [ -n "$slots" ]; then
      if timeout 60 qm set "$VMID" --delete "$(echo $slots | tr ' ' ',')" >/dev/null; then echo "CLEANUP: deleted $(echo $slots)"
      else echo "CLEANUP: delete of $(echo $slots) FAILED"; rc=1; fi
    fi
  fi

  # Fence (cleanup-iso): exact literal path only.
  if [ "$UNATTEND_ISO" != "/var/lib/vz/template/iso/wintools-unattend.iso" ]; then
    echo "REFUSED(cleanup-iso): unattend ISO path is not the literal /var/lib/vz/template/iso/wintools-unattend.iso"; rc=1
  elif [ -e "$UNATTEND_ISO" ]; then
    if shred -u "$UNATTEND_ISO"; then echo "CLEANUP: shredded $UNATTEND_ISO"; else echo "CLEANUP: shred of unattend ISO FAILED"; rc=1; fi
  fi

  for d in "$BUILD_DIR"/render.*; do
    [ -e "$d" ] || continue
    # Fence (cleanup-render): only mktemp render dirs under the literal build dir.
    if ! [[ "$d" =~ ^/root/wintools-build/render\.[A-Za-z0-9]{6}$ ]]; then
      echo "REFUSED(cleanup-render): '$d' does not match ^/root/wintools-build/render\\.[A-Za-z0-9]{6}\$"; rc=1; continue
    fi
    if [ -f "$d/autounattend.xml" ]; then
      if shred -u "$d/autounattend.xml"; then echo "CLEANUP: shredded $d/autounattend.xml"; else echo "CLEANUP: shred of $d/autounattend.xml FAILED"; rc=1; fi
    fi
    if rm -rf -- "$d"; then echo "CLEANUP: removed $d"; else echo "CLEANUP: rm of $d FAILED"; rc=1; fi
  done

  echo "CLEANUP WARNING: shred is best-effort — on journalled/copy-on-write/thin storage old blocks may survive; the install password is rotated afterwards so any residue is a dead credential."

  # Assertions (fail closed: a check that could not look is a failure).
  if [ -e "$UNATTEND_ISO" ]; then echo "CLEANUP ASSERT FAIL: $UNATTEND_ISO still exists"; rc=1; fi
  local isolist found
  if isolist=$(timeout 30 pvesm list local --content iso); then
    if grep -qF wintools-unattend <<<"$isolist"; then echo "CLEANUP ASSERT FAIL: pvesm still lists wintools-unattend"; rc=1; fi
  else echo "CLEANUP ASSERT FAIL: could not run pvesm list"; rc=1; fi
  if found=$(timeout 120 find /root /tmp /var/lib/vz \( -name 'autounattend.xml*' -o -name 'wintools-unattend.iso' \)); then
    if [ -n "$found" ]; then echo "CLEANUP ASSERT FAIL: answer-file artefacts remain:"; printf '  %s\n' $found; rc=1; fi
  else echo "CLEANUP ASSERT FAIL: find could not complete"; rc=1; fi
  if [ "$rc" -eq 0 ]; then echo "CLEANUP_OK=1"; else echo "CLEANUP_OK=0"; fi
  return "$rc"
}

do_failexit() {
  local crc=0 st final slots mem
  ( do_cleanup ) || crc=$?
  st=$(vm_status) || st=unknown
  if [ "$st" != stopped ]; then
    if ! timeout 180 qm shutdown "$VMID" --timeout 120; then
      timeout 60 qm stop "$VMID" || true
      echo "FAILEXIT_FORCED_STOP=1"
    fi
  fi
  st=$(vm_status) || st=unknown
  if [ "$st" = stopped ]; then
    slots=$(present_cd_slots) || slots=""
    if [ -n "$slots" ]; then timeout 60 qm set "$VMID" --delete "$(echo $slots | tr ' ' ',')" >/dev/null || echo "FAILEXIT: delete of $(echo $slots) failed"; fi
  fi
  final=$(timeout 30 qm status "$VMID") || final="(qm status failed)"
  mem=$(memavail_kb)
  if [ "$final" = "status: stopped" ]; then echo "FAILEXIT_STATUS=stopped"; else echo "FAILEXIT_STATUS=NOT-STOPPED ($final) — OPERATOR MUST ACT ON ATLANTIS NOW"; fi
  echo "FAILEXIT_MEMAVAILABLE_KB=${mem}"
  echo "FAILEXIT_CLEANUP_RC=${crc}"
  [ "$final" = "status: stopped" ] && [ "$crc" -eq 0 ]
}

on_build_exit() {
  local rc=$?
  trap - EXIT
  if [ "$rc" -ne 0 ]; then
    echo "BUILD FAILED (rc=$rc) — running failexit"
    do_failexit || true
  fi
  exit "$rc"
}

do_build() {
  local PW tmpl out st RD L virtio_sha PRESTART_KB i
  mkdir -p -m 700 "$BUILD_DIR"
  if ! IFS= read -r PW; then echo "REFUSED: no password line on stdin"; exit 2; fi
  cat > "$BUILD_DIR/authorized_keys" # remaining stdin: public keys only
  if ! grep -qE '^(ssh-|ecdsa-)' "$BUILD_DIR/authorized_keys"; then echo "REFUSED: no public key lines after the password"; exit 2; fi
  if ! [[ "$PW" =~ ^[A-Za-z0-9]{20,}$ && "$PW" =~ [A-Z] && "$PW" =~ [a-z] && "$PW" =~ [0-9] ]]; then
    echo "REFUSED: password must be >=20 alphanumerics with upper, lower and digit"; exit 2
  fi
  st=$(vm_status) || { echo "REFUSED: could not read qm status $VMID"; exit 2; }
  if [ "$st" != stopped ]; then echo "REFUSED: VM $VMID is '$st', not stopped"; exit 2; fi
  [ -f "$TMPL" ] || { echo "REFUSED: template $TMPL missing"; exit 2; }

  RD=$(mktemp -d "$BUILD_DIR/render.XXXXXX")
  trap on_build_exit EXIT

  tmpl=$(<"$TMPL")
  out=${tmpl//@@ADMIN_PASSWORD@@/$PW}
  printf '%s\n' "$out" > "$RD/autounattend.xml"
  unset PW out tmpl
  if grep -q '@@' "$RD/autounattend.xml"; then echo "BUILD: rendered file still has @@ tokens"; exit 3; fi
  if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$RD/autounattend.xml"
  else
    python3 -I -c 'import sys, xml.dom.minidom as m; m.parse(sys.argv[1])' "$RD/autounattend.xml"
  fi
  echo "BUILD: rendered answer file parses"

  if [ ! -s "$VIRTIO_ISO" ]; then
    timeout 1800 curl -fsSL --retry 3 -o "$VIRTIO_ISO.part" "$VIRTIO_URL"
    mv "$VIRTIO_ISO.part" "$VIRTIO_ISO"
    chmod 644 "$VIRTIO_ISO"
  fi
  virtio_sha=$(sha256sum "$VIRTIO_ISO" | cut -d' ' -f1)
  echo "VIRTIO_SHA256=${virtio_sha}"
  L=$(isoinfo -J -l -i "$VIRTIO_ISO" 2>/dev/null || true)
  [ -n "$L" ] || L=$(isoinfo -R -l -i "$VIRTIO_ISO" 2>/dev/null || true)
  grep -qi 'Directory listing of /vioscsi/w11/amd64' <<<"$L" || { echo "BUILD: virtio-win lacks vioscsi/w11/amd64"; exit 4; }
  grep -qi 'Directory listing of /netkvm/w11/amd64' <<<"$L" || { echo "BUILD: virtio-win lacks netkvm/w11/amd64"; exit 4; }
  grep -qi 'virtio-win-guest-tools.exe' <<<"$L" || { echo "BUILD: virtio-win lacks virtio-win-guest-tools.exe"; exit 4; }
  echo "BUILD: virtio-win driver layout proven (vioscsi, netkvm w11/amd64; guest-tools exe)"

  genisoimage -quiet -J -joliet-long -r -V WINTOOLS_UNATTEND -o "$UNATTEND_ISO" "$RD"
  chmod 600 "$UNATTEND_ISO"
  timeout 60 qm set "$VMID" --ide0 local:iso/virtio-win-0.1.302.iso,media=cdrom --sata0 local:iso/wintools-unattend.iso,media=cdrom >/dev/null
  echo "BUILD: ide0 (virtio-win) and sata0 (unattend) attached"

  PRESTART_KB=$(memavail_kb)
  if [ -z "$PRESTART_KB" ] || [ "$PRESTART_KB" -lt "$MIN_MEMAVAIL_KB" ]; then
    echo "REFUSED: MemAvailable ${PRESTART_KB:-unreadable} kB is below 5 GiB (${MIN_MEMAVAIL_KB} kB)"
    exit "$EXIT_LOWMEM"
  fi

  timeout 120 qm start "$VMID"
  for i in $(seq 1 20); do sleep 1; timeout 10 qm sendkey "$VMID" ret >/dev/null 2>&1 || true; done
  echo "BUILD: VM $VMID started; Enter sent 20x for the CD prompt"
  echo "PRESTART_MEMAVAILABLE_KB=${PRESTART_KB}"
}

case "${1:-}" in
  build) do_build ;;
  cleanup) do_cleanup ;;
  failexit) do_failexit ;;
  *) echo "usage: $0 build|cleanup|failexit" >&2; exit 2 ;;
esac
