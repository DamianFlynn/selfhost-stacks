#!/usr/bin/env bash
# disable-jellyfin-hwaccel.sh - Turn Jellyfin's VAAPI transcoding off (and back on).
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   Host-resident because it edits Jellyfin's config under /mnt/fast/appdata and restarts the
#   container. The ONE thing it cannot see from here is the GPU's DRM client table: /dev/dri is
#   passed INTO this container, but /sys/kernel/debug/dri lives on the Proxmox host. That check
#   is delegated over ssh to 172.16.1.158, the same convention check-music-freeze.sh uses for
#   its zfs queries.
#
# Usage:
#   bash scripts/disable-jellyfin-hwaccel.sh check     # read-only: report current state
#   bash scripts/disable-jellyfin-hwaccel.sh disable   # turn VAAPI off, restart, verify
#   bash scripts/disable-jellyfin-hwaccel.sh enable    # restore the most recent backup
#
# ⚠️  `disable` and `enable` MUTATE live state: they rewrite encoding.xml and restart a
#     container that is serving the house. `check` never writes anything.
#
# WHY THIS EXISTS (2026-08-31)
#   atlantis wedged for ~6 hours and took every *.deercrest.info service down with it. The
#   causal chain, measured rather than assumed:
#
#     1. At 07:56:56 Jellyfin started a VAAPI transcode of a 1080p H264 film, burning in DVDSUB
#        picture subtitles. PROOF, not inference - the transcode log survives the reboot at
#        /mnt/fast/appdata/media/jellyfin/log/FFmpeg.Transcode-2026-08-31_07-56-56_*.log, and
#        the container id under /proc/<pid>/cgroup resolves via `docker inspect` to /jellyfin.
#        The pipeline opens THREE DRM handles (-init_hw_device drm=dr / vaapi=va@dr /
#        vulkan=vk@dr) and the log itself warns:
#          "amdgpu: os_same_file_description couldn't determine if two DRM fds reference the
#           same file description. If they do, bad things may happen!"
#     2. 07:56:58 - the oops, two seconds later. The transcode died at frame=150,
#        time=00:00:03.92, flooding `SIVPE ERROR ... si_vpe_construct_blt Failed` from Mesa
#        radeonsi. ffmpeg was left orphaned in `anon_pipe_write` - still S-state, still holding
#        two DRM handles and 232 MB VRAM, GPU busy 0%, for the next six hours.
#
#     NOTE ON WHO WAS WATCHING: nobody needed to be. This was one playback that failed four
#     seconds in. "Jellyfin has been fine, nobody was using it" is compatible with the evidence -
#     the damage is done by an ffmpeg that STARTS and dies, not by sustained viewing.
#     3. Those mappings are userptr, registered with an MMU notifier. kcompactd0 tried to
#        migrate the pages at 07:56 and `amdgpu_hmm_invalidate_gfx+0x42/0xd0` NULL-dereferenced.
#     4. The oopsing task died HOLDING its mmap_lock. Four oopses followed (07:56, 10:43,
#        12:00, 12:15), kernel tainted [D]=DIE.
#     5. Everything that reads /proc/<pid>/smaps - cadvisor, prometheus, dockerd's stats
#        collector - blocked on that dead lock forever. Traefik depends on dockerd, so every
#        proxied service died. Dispatcharr survived only because it answers HTTP and never
#        touches /proc.
#
#   The signature to recognise it by: io pressure `full` ~96% with ZERO in-flight block I/O and
#   an IDLE CPU. That is not disk and not load - it is a lock held by a dead task, and no
#   amount of freeing memory or restarting containers touches it. Only a reboot clears it.
#
#   NOT FIXED BY THE JULY 2026 MITIGATION. transparent_hugepage=never and
#   vm.compaction_proactiveness=0 were both fully applied and present on the cmdline/sysctl at
#   the time of this incident. proactiveness=0 suppresses only PROACTIVE compaction; reactive
#   compaction still runs under memory pressure, and kcompactd0 was oops victim #1. Anyone
#   reading the older memory entry as "resolved" is reading it wrong.
#
#   Related and already logged: NETWORK.md "Fix deinterlace_vaapi on the Radeon 890M - ffmpeg
#   exits 251 whenever a Jellyfin client...". Same GPU, same ffmpeg, same VAAPI path. An ffmpeg
#   that exits badly is exactly how one gets orphaned holding GPU memory.
#
# WHY encoding.xml AND NOT THE COMPOSE `devices:` LINE
#   Removing `- /dev/dri:/dev/dri` from stacks/selfhosted/media/jellyfin.yaml would also stop
#   this, and more absolutely. It was rejected as the DEFAULT because Jellyfin would still be
#   CONFIGURED for VAAPI and would fail playback outright rather than fall back to software -
#   trading a rare outage for a constant one. Disabling it in encoding.xml makes Jellyfin
#   choose software transcoding cleanly.
#   If this recurs even with hwaccel off, THEN pull the device line as belt-and-braces; the
#   GPU cannot be held by a container that cannot see it.
#
# WHY NOT THE REST API
#   Plan 01-06 configured Jellyfin over the REST API and that is the better pattern, but it
#   needs an API key and none exists yet - minting the first purpose-named key is plan 02-04's
#   job. Editing the file needs no auth, and this had to be runnable the moment the host
#   returned. Once 02-04 lands, prefer the API.
#
# Idempotent:
#   `disable` re-run reports "already disabled" and changes nothing - no backup is taken and
#            the container is NOT restarted, because a needless restart of a service the house
#            is watching is a real cost.
#   `enable`  restores the most recent .bak; with no backup present it refuses rather than
#            guessing a previous value.
#   `check`   never writes.
#
# EXIT-CODE CONVENTION (inherited from scripts/check-music-freeze.sh):
#   0  the requested action succeeded, or `check` completed (check never fails on findings)
#   1  a red finding in a mutating action, or a failed precondition
#   2  usage error
set -uo pipefail

JELLYFIN_CONFIG="${JELLYFIN_CONFIG:-/mnt/fast/appdata/media/jellyfin/config/encoding.xml}"
JELLYFIN_CONTAINER="${JELLYFIN_CONTAINER:-jellyfin}"
PROXMOX_HOST="${PROXMOX_HOST:-172.16.1.158}"
ACTION="${1:-}"

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
bad()  { printf '  ✗ %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*"; }

usage() {
  say "Usage: bash scripts/disable-jellyfin-hwaccel.sh {check|disable|enable}"
  exit 2
}

# --- Preconditions ----------------------------------------------------------------------
# Deliberately NOT gated on load average. Load is the SYMPTOM of this failure and it lags: a
# freshly rebooted host reads near 0 for several minutes whether or not the fault is fixed,
# which gives a false green exactly when a true one matters. io pressure and a same-boot oops
# count are the direct instruments.
preconditions() {
  local fail=0

  if ! command -v docker >/dev/null 2>&1; then
    bad "docker not found - this script runs ON LXC 100, not the workstation"; fail=1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    bad "python3 not found - required to edit XML safely (no sed on XML)"; fail=1
  fi
  if [ ! -f "$JELLYFIN_CONFIG" ]; then
    bad "encoding.xml not found at $JELLYFIN_CONFIG"; fail=1
  fi
  if ! docker inspect "$JELLYFIN_CONTAINER" >/dev/null 2>&1; then
    bad "container '$JELLYFIN_CONTAINER' not found"; fail=1
  fi

  # Host health. If the host is still wedged, dockerd is blocked behind the dead mmap_lock and
  # `docker restart` will hang rather than fail - so refuse before touching anything.
  local io_full oops
  io_full=$(timeout 15 ssh -o ConnectTimeout=8 -o BatchMode=yes "root@${PROXMOX_HOST}" \
              "awk '/full/{print \$2}' /proc/pressure/io" 2>/dev/null | cut -d= -f2)
  oops=$(timeout 15 ssh -o ConnectTimeout=8 -o BatchMode=yes "root@${PROXMOX_HOST}" \
              "dmesg -T 2>/dev/null | grep -c amdgpu_hmm_invalidate_gfx" 2>/dev/null)

  if [ -z "$io_full" ]; then
    warn "could not read io pressure from ${PROXMOX_HOST} - verify the host by hand"
  elif awk "BEGIN{exit !(${io_full:-0} > 50)}"; then
    bad "host io pressure full=${io_full} - still wedged; docker will hang. Reboot first."; fail=1
  else
    ok "host io pressure full=${io_full}"
  fi

  if [ -n "${oops:-}" ] && [ "${oops:-0}" -gt 0 ]; then
    warn "amdgpu_hmm oops lines present this boot: ${oops} - the fault has already fired since reboot"
  fi

  return $fail
}

# --- DRM client table (must run on the Proxmox host; debugfs is not in the container) -----
drm_clients() {
  timeout 20 ssh -o ConnectTimeout=8 -o BatchMode=yes "root@${PROXMOX_HOST}" '
    for f in /sys/kernel/debug/dri/*/clients; do
      [ -r "$f" ] && cat "$f"
    done 2>/dev/null | awk "NR>1 && \$1 != \"command\" {print \$1, \$2}" | sort -u
  ' 2>/dev/null
}

report_drm() {
  local clients; clients=$(drm_clients)
  if [ -z "$clients" ]; then
    ok "no processes hold amdgpu DRM handles"
  else
    warn "processes still holding amdgpu DRM handles:"
    printf '      %s\n' "$clients"
  fi
}

current_hwaccel() {
  python3 - "$JELLYFIN_CONFIG" <<'PY' 2>/dev/null
import sys, xml.etree.ElementTree as ET
try:
    r = ET.parse(sys.argv[1]).getroot()
except Exception as e:
    print(f"UNREADABLE ({e})"); sys.exit(0)
t = r.find("HardwareAccelerationType")
e = r.find("EnableHardwareEncoding")
print(f"{(t.text or 'none').strip() if t is not None else 'absent'}|"
      f"{(e.text or '').strip() if e is not None else 'absent'}")
PY
}

set_hwaccel() {
  # $1 = "none" to disable, or the value to restore
  python3 - "$JELLYFIN_CONFIG" "$1" <<'PY'
import sys, xml.etree.ElementTree as ET
path, value = sys.argv[1], sys.argv[2]
tree = ET.parse(path); root = tree.getroot()
def setel(name, text):
    el = root.find(name)
    if el is None:
        el = ET.SubElement(root, name)
    el.text = text
setel("HardwareAccelerationType", value)
setel("EnableHardwareEncoding", "false" if value == "none" else "true")
tree.write(path, encoding="utf-8", xml_declaration=True)
PY
}

do_check() {
  say "== Jellyfin hardware-acceleration state =="
  local state; state=$(current_hwaccel)
  say "  encoding.xml      : $JELLYFIN_CONFIG"
  say "  HardwareAccelType : ${state%%|*}"
  say "  HardwareEncoding  : ${state##*|}"
  say "  container state   : $(docker inspect -f '{{.State.Status}}' "$JELLYFIN_CONTAINER" 2>/dev/null || echo unknown)"
  say ""
  say "== amdgpu DRM clients (via ${PROXMOX_HOST}) =="
  report_drm
  say ""
  case "${state%%|*}" in
    none|absent) ok  "VAAPI is OFF - the orphaned-transcode trigger cannot fire" ;;
    *)           warn "VAAPI is ON (${state%%|*}) - run 'disable' to remove the trigger" ;;
  esac
  return 0
}

do_disable() {
  preconditions || { bad "preconditions failed - refusing to mutate"; return 1; }

  local state; state=$(current_hwaccel)
  if [ "${state%%|*}" = "none" ] || [ "${state%%|*}" = "absent" ]; then
    ok "already disabled (HardwareAccelerationType=${state%%|*}) - no backup, no restart"
    return 0
  fi

  local backup="${JELLYFIN_CONFIG}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp -p "$JELLYFIN_CONFIG" "$backup" || { bad "backup failed - refusing to edit"; return 1; }
  ok "backed up to $backup (was: ${state%%|*})"

  set_hwaccel none || { bad "edit failed; restore with: cp -p '$backup' '$JELLYFIN_CONFIG'"; return 1; }
  ok "HardwareAccelerationType -> none, EnableHardwareEncoding -> false"

  say "  restarting $JELLYFIN_CONTAINER ..."
  if ! timeout 120 docker restart "$JELLYFIN_CONTAINER" >/dev/null 2>&1; then
    bad "docker restart failed or hung - host may still be wedged"
    bad "restore with: cp -p '$backup' '$JELLYFIN_CONFIG'"
    return 1
  fi
  ok "restarted"

  sleep 5
  say ""
  say "== post-change verification =="
  report_drm
  local after; after=$(current_hwaccel)
  if [ "${after%%|*}" = "none" ]; then ok "verified: VAAPI off"; else bad "verify failed: ${after%%|*}"; return 1; fi
  return 0
}

do_enable() {
  preconditions || { bad "preconditions failed - refusing to mutate"; return 1; }

  local backup; backup=$(ls -1t "${JELLYFIN_CONFIG}".bak.* 2>/dev/null | head -1)
  if [ -z "$backup" ]; then
    bad "no backup found next to $JELLYFIN_CONFIG - refusing to guess a previous value"
    bad "set it in the Jellyfin UI instead: Dashboard > Playback > Transcoding"
    return 1
  fi
  cp -p "$backup" "$JELLYFIN_CONFIG" || { bad "restore failed"; return 1; }
  ok "restored from $backup"
  timeout 120 docker restart "$JELLYFIN_CONTAINER" >/dev/null 2>&1 && ok "restarted" || { bad "restart failed"; return 1; }
  warn "VAAPI is back ON - the orphaned-transcode trigger is re-armed"
  return 0
}

case "$ACTION" in
  check)   do_check ;;
  disable) do_disable ;;
  enable)  do_enable ;;
  *)       usage ;;
esac
