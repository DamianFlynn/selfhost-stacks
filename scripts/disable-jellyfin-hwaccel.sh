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

  # WR-08: THIS BLOCK IS THE REFUSAL, SO IT HAS TO ACTUALLY REFUSE.
  #
  # The contract stated four lines above is "refuse before touching anything". The previous code
  # did not. Two separate ways through:
  #
  #   1. An empty probe emitted `warn` and left fail=0, so preconditions returned 0 and do_disable
  #      went on to rewrite encoding.xml and restart the container. The single state that most
  #      strongly indicates a wedged host - atlantis not answering ssh - produced the WEAKEST
  #      response in the function whose whole job is to detect a wedged host.
  #   2. `awk "BEGIN{exit !(${io_full} > 50)}"` interpolated the value into the awk PROGRAM, not
  #      into data. Any non-numeric value (a partial line from cut, a locale-formatted number, an
  #      ssh banner fragment surviving the pipeline) is an awk SYNTAX ERROR, awk exits 2, the elif
  #      is therefore false, and control fell through to `ok "host io pressure full=..."` - an
  #      unparseable reading reported as HEALTHY.
  #
  # `awk -v` passes the value as data. That fixes the false-healthy path and removes the code
  # injection surface in the same move.
  if [ -z "$io_full" ]; then
    bad "could not read io pressure from ${PROXMOX_HOST} - UNKNOWN, not healthy."
    bad "An unreachable atlantis is itself a symptom of the fault this script exists for."
    bad "Refusing to mutate. Verify the host by hand, then re-run."; fail=1
  elif ! printf '%s' "$io_full" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
    bad "io pressure value '${io_full}' is not a number - UNKNOWN, not healthy. Refusing."; fail=1
  elif awk -v v="$io_full" 'BEGIN{exit !(v > 50)}'; then
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
#
# CR-02: "NOTHING HELD" AND "COULD NOT LOOK" ARE DIFFERENT ANSWERS AND MUST NOT SHARE A VERDICT.
#
# The previous version returned bare stdout and report_drm() treated empty output as proof of
# absence, printing "no processes hold amdgpu DRM handles". Every one of these produces empty
# output: ssh refused, ssh timed out on `timeout 20`, the BatchMode key not accepted, debugfs not
# mounted on atlantis so the glob matches nothing, the clients files unreadable, and the outer
# 2>/dev/null discarding whatever ssh had to say about any of it. The exit status was thrown away
# entirely - `clients=$(drm_clients)` was never tested.
#
# That sat in the worst possible place. do_disable() calls report_drm as its POST-CHANGE
# VERIFICATION, after the config edit and the container restart. An operator remediating the
# amdgpu wedge would read a green DRM table and conclude the orphaned ffmpeg was gone - when the
# more likely truth is that atlantis did not answer, BECAUSE A WEDGED HOST IS WHY THEY ARE
# RUNNING THIS SCRIPT AT ALL.
#
# So the probe now: distinguishes "the table is unreadable" (exit 3) from "the table is readable
# and empty" (exit 0, no output), does NOT swallow ssh's own stderr into the void, and returns its
# status to the caller. report_drm returns non-zero on an unknown, and do_disable propagates it.
drm_clients() {
  timeout 20 ssh -o ConnectTimeout=8 -o BatchMode=yes "root@${PROXMOX_HOST}" '
    ls /sys/kernel/debug/dri/*/clients >/dev/null 2>&1 || exit 3
    cat /sys/kernel/debug/dri/*/clients 2>/dev/null \
      | awk "NR>1 && \$1 != \"command\" {print \$1, \$2}" | sort -u
  '
}

report_drm() {
  local clients rc
  clients=$(drm_clients); rc=$?
  if [ "$rc" -ne 0 ]; then
    bad "UNKNOWN - could not read the DRM client table on ${PROXMOX_HOST} (probe rc=$rc)."
    bad "This is NOT 'no handles held'. rc=3 means debugfs/dri was unreadable there; 124 means the"
    bad "probe timed out; 255 means ssh failed - and an unreachable atlantis is itself a symptom."
    bad "Check the host by hand before trusting anything else this run printed."
    return 1
  fi
  if [ -z "$clients" ]; then
    ok "no processes hold amdgpu DRM handles (table read successfully and was empty)"
  else
    warn "processes still holding amdgpu DRM handles:"
    printf '      %s\n' "$clients"
  fi
  return 0
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
  # IN-04: do_check does not call preconditions() and current_hwaccel runs under 2>/dev/null, so
  # a missing python3 or an unparseable encoding.xml yields an EMPTY state - which used to fall
  # through to the `*)` arm and print "VAAPI is ON ()", a determinate claim about something that
  # was never measured. The direction was safe (it never falsely said OFF) but "ON ()" with a
  # blank HardwareAccelType two lines above is a diagnosis, not an observation.
  case "${state%%|*}" in
    none|absent)   ok   "VAAPI is OFF - the orphaned-transcode trigger cannot fire" ;;
    ""|UNREADABLE*)
      warn "UNKNOWN - could not read $JELLYFIN_CONFIG (python3 missing, or the file is not"
      warn "parseable XML). This is NOT 'VAAPI is off' and NOT 'VAAPI is on'. Read the file by"
      warn "hand, or run 'disable' - it calls preconditions() and will refuse with a reason." ;;
    *)             warn "VAAPI is ON (${state%%|*}) - run 'disable' to remove the trigger" ;;
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
  # CR-02: an unreadable DRM table FAILS this action. The config edit itself may well have
  # succeeded, but "VAAPI is off" is only half of what do_disable claims to have verified - the
  # other half is that nothing is still holding a handle, and that half is genuinely unknown.
  # Returning 0 here would tell an operator mid-incident that the GPU is clear when nobody looked.
  local drm_rc=0
  report_drm || drm_rc=1

  local after; after=$(current_hwaccel)
  if [ "${after%%|*}" != "none" ]; then
    bad "verify failed: ${after%%|*}"
    return 1
  fi
  ok "verified: VAAPI off"

  if [ "$drm_rc" -ne 0 ]; then
    bad "VAAPI is off, but the DRM client table could not be read - the GPU state is UNKNOWN."
    bad "Exiting non-zero deliberately: do not close an amdgpu incident on this run."
    return 1
  fi
  return 0
}

do_enable() {
  preconditions || { bad "preconditions failed - refusing to mutate"; return 1; }

  # WR-07: SORT BY THE TIMESTAMP IN THE NAME, NOT BY mtime.
  #
  # `ls -1t` sorts by mtime, and mtime is the wrong key here BECAUSE OF THIS SCRIPT'S OWN
  # `cp -p`: -p preserves timestamps, so <config>.bak.20260901T120000Z carries encoding.xml's
  # mtime rather than the moment the backup was taken. Concretely: disable -> backup A (mtime M1);
  # enable restores A with cp -p, so encoding.xml's mtime becomes M1 again; a second disable with
  # no UI change in between -> backup B, also mtime M1. Two backups, identical mtime, and `ls -t`'s
  # tie-break is unspecified. The filename already carries the true creation time in sortable ISO
  # form and it was being ignored.
  #
  # The consequence was silent: do_enable restores the WHOLE FILE, so a stale backup reverts
  # everything else the operator changed in Jellyfin's Playback settings too, and nothing reported
  # it (see the post-restore verification added below).
  local backup; backup=$(ls -1 "${JELLYFIN_CONFIG}".bak.* 2>/dev/null | sort | tail -1)
  if [ -z "$backup" ]; then
    bad "no backup found next to $JELLYFIN_CONFIG - refusing to guess a previous value"
    bad "set it in the Jellyfin UI instead: Dashboard > Playback > Transcoding"
    return 1
  fi

  # Show what is about to be restored, and from when, so the operator can refuse it. The whole
  # file is restored, not just the accel type - say so.
  local from_ts; from_ts="${backup##*.bak.}"
  local will; will=$(python3 - "$backup" <<'PY' 2>/dev/null
import sys, xml.etree.ElementTree as ET
try:
    r = ET.parse(sys.argv[1]).getroot()
except Exception as e:
    print(f"UNREADABLE ({e})"); sys.exit(0)
t = r.find("HardwareAccelerationType")
print((t.text or "none").strip() if t is not None else "absent")
PY
  )
  say "  restoring from    : $backup"
  say "  backup taken at   : ${from_ts:-unknown} (from the FILENAME; mtime is unreliable, see WR-07)"
  say "  HardwareAccelType : ${will:-UNKNOWN} (the ENTIRE encoding.xml is restored, not just this)"
  local others; others=$(ls -1 "${JELLYFIN_CONFIG}".bak.* 2>/dev/null | wc -l | tr -d ' ')
  [ "${others:-0}" -gt 1 ] && say "  ($others backups present; this is the newest by filename timestamp)"

  cp -p "$backup" "$JELLYFIN_CONFIG" || { bad "restore failed"; return 1; }
  ok "restored from $backup"
  timeout 120 docker restart "$JELLYFIN_CONTAINER" >/dev/null 2>&1 && ok "restarted" || { bad "restart failed"; return 1; }

  # IN-06: mirror do_disable's post-change verification. do_enable used to restore, restart and
  # warn without ever re-reading what it had restored - so combined with WR-07's wrong-backup
  # selection, restoring a stale or unreadable config was completely silent.
  sleep 5
  say ""
  say "== post-restore verification =="
  local after; after=$(current_hwaccel)
  case "${after%%|*}" in
    "" |UNREADABLE*)
      bad "restored config is not readable back (${after%%|*}) - UNKNOWN state. Check by hand."
      bad "the backup is still at $backup"
      return 1 ;;
    none|absent)
      bad "restored config reads HardwareAccelerationType=${after%%|*} - the restore did NOT"
      bad "re-enable VAAPI. The selected backup was taken while VAAPI was already off."
      bad "Pick another: ls -1 ${JELLYFIN_CONFIG}.bak.*"
      return 1 ;;
    *)
      ok "verified: HardwareAccelerationType=${after%%|*}, EnableHardwareEncoding=${after##*|}" ;;
  esac
  warn "VAAPI is back ON - the orphaned-transcode trigger is re-armed"
  return 0
}

case "$ACTION" in
  check)   do_check ;;
  disable) do_disable ;;
  enable)  do_enable ;;
  *)       usage ;;
esac
