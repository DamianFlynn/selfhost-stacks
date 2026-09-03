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
#   bash scripts/disable-jellyfin-hwaccel.sh enable    # restore the most recent backup EXCEPT the
#                                                      # five transcode-retention values, which are
#                                                      # preserved from the live config and verified
#   bash scripts/disable-jellyfin-hwaccel.sh verify-retention
#                                                      # read-only: compare $JELLYFIN_CONFIG's five
#                                                      # transcode-retention values against
#                                                      # $TRAN09_EXPECT; non-zero on any mismatch
#
# ⚠️  `disable` and `enable` MUTATE live state: they rewrite encoding.xml and restart a
#     container that is serving the house. `check` and `verify-retention` never write anything.
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
#   returned.
#
#   02-04 HAS SINCE LANDED - the key exists at /mnt/fast/secrets/jellyfin-deercrest.env - and
#   converting this script to the API is nonetheless DELIBERATELY DEFERRED (plan 02.1-07,
#   2026-09-03). Reason: this script's entire value is that it works when Jellyfin is DOWN,
#   which is precisely the condition an amdgpu incident creates. The REST route requires a
#   RUNNING server, so it cannot serve the case this runbook exists for. The file-based route
#   stays primary; an API route, if ever added, would be a fallback for the healthy case only.
#   Do not re-open this as "02-04 landed, so switch" - the conversion is deferred, not overlooked,
#   and the reason is that the REST route needs a running server this script cannot assume.
#
# Idempotent:
#   `disable` re-run reports "already disabled" and changes nothing - no backup is taken and
#            the container is NOT restarted, because a needless restart of a service the house
#            is watching is a real cost.
#   `enable`  restores the most recent .bak EXCEPT the five transcode-retention values
#            (TranscodingTempPath, EnableSegmentDeletion, SegmentKeepSeconds, EnableThrottling,
#            ThrottleDelaySeconds), which are captured from the LIVE config before the restore,
#            re-asserted into the restored file, and verified afterwards - a mismatch names the
#            field with its before and after values and exits non-zero (TRAN-09 / D-29). With no
#            backup present it refuses rather than guessing a previous value.
#   `check`   never writes.
#   `verify-retention`  never writes. Read-only comparison of $JELLYFIN_CONFIG's five
#            transcode-retention values against $TRAN09_EXPECT.
#
# TEST-ONLY HOOK - TRAN09_FAULT
#   TRAN09_FAULT=1 makes `enable` SKIP the post-restore re-assert while still capturing the
#   pre-restore values and still verifying them - so the comparison genuinely finds the restored
#   pre-phase values, names the fields, and exits non-zero. It exists ONLY so that plan 02.1-07
#   can discharge VALIDATION.md row 35's negative half by EXECUTING a failure rather than
#   asserting one. Default is unset.
#   ⚠️  SETTING THIS IN PRODUCTION CONVERTS `enable` BACK INTO THE SILENT REVERT THAT THE
#       HARDENING ABOVE REMOVES. It is never correct outside a test. Whenever it is active the
#       script prints a loud warning, so it cannot be on without appearing in the transcript.
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
  say "Usage: bash scripts/disable-jellyfin-hwaccel.sh {check|disable|enable|verify-retention}"
  say ""
  say "  check             read-only: report current hwaccel state and the DRM client table"
  say "  disable           turn VAAPI off, restart, verify"
  say "  enable            restore the most recent .bak EXCEPT the five transcode-retention"
  say "                    values, which are preserved from the live config and re-verified"
  say "  verify-retention  read-only: compare \$JELLYFIN_CONFIG's five transcode-retention"
  say "                    values against \$TRAN09_EXPECT; exits non-zero on any mismatch"
  say ""
  say "  env: JELLYFIN_CONFIG, JELLYFIN_CONTAINER, PROXMOX_HOST, TRAN09_EXPECT"
  say "       TRAN09_FAULT=1 is a TEST-ONLY hook - see the header. Never set it in production."
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

# --- TRAN-09: the five transcode-retention values -----------------------------------------
#
# TRAN-09 (2026-09-03, phase 02.1, D-29). These five are what phase 02.1 installed into
# encoding.xml, and they are what do_enable's whole-file restore silently reverted. The order of
# this list is the wire order of the `|`-separated form that current_retention emits, set_retention
# consumes and $TRAN09_EXPECT is written in. Do not reorder it without changing all four.
RETENTION_FIELDS="TranscodingTempPath EnableSegmentDeletion SegmentKeepSeconds EnableThrottling ThrottleDelaySeconds"

# Read-back helper, deliberately shaped like current_hwaccel: it returns an explicit
# `UNREADABLE (...)` sentinel rather than an empty string, because IN-04 (lines below, do_check)
# records what an empty state cost - an unmeasured value that reads as a determinate answer. A
# missing element returns the literal `absent`, matching current_hwaccel's convention, so
# "the element is not there" and "the element is there and empty" stay distinguishable.
#
# $1 = config path (optional; defaults to $JELLYFIN_CONFIG) - verify-retention needs to point this
#      at an arbitrary file, which is the whole reason it takes an argument.
current_retention() {
  local cfg="${1:-$JELLYFIN_CONFIG}" out
  out=$(python3 - "$cfg" <<'PY' 2>/dev/null
import sys, xml.etree.ElementTree as ET
NAMES = ["TranscodingTempPath", "EnableSegmentDeletion", "SegmentKeepSeconds",
         "EnableThrottling", "ThrottleDelaySeconds"]
try:
    r = ET.parse(sys.argv[1]).getroot()
except Exception as e:
    print(f"UNREADABLE ({e})"); sys.exit(0)
out = []
for n in NAMES:
    el = r.find(n)
    out.append("absent" if el is None else (el.text or "").strip())
print("|".join(out))
PY
  )
  # A missing python3, or any path where the heredoc produced nothing at all, must NOT collapse to
  # an empty string that a caller could read as "all five are empty". Same lesson as IN-04.
  if [ -z "$out" ]; then
    printf 'UNREADABLE (no output - python3 missing, or %s could not be opened)\n' "$cfg"
    return 0
  fi
  printf '%s\n' "$out"
}

# Pick field $2 (1-based) out of the `|`-separated line $1. awk -v passes the index as DATA, never
# interpolated into the awk program - the same rule the io-pressure probe above had to learn.
retention_field() {
  printf '%s' "$1" | awk -F'|' -v i="$2" '{print $i}'
}

# Re-assert a captured `|`-separated retention line into $JELLYFIN_CONFIG. Reuses set_hwaccel's
# setel() shape, which already creates a missing element, so this is purely additive. A field
# captured as the literal `absent` is SKIPPED: a value that was genuinely not there before the
# restore stays not there afterwards.
set_retention() {
  python3 - "$JELLYFIN_CONFIG" "$1" <<'PY'
import sys, xml.etree.ElementTree as ET
NAMES = ["TranscodingTempPath", "EnableSegmentDeletion", "SegmentKeepSeconds",
         "EnableThrottling", "ThrottleDelaySeconds"]
path, packed = sys.argv[1], sys.argv[2]
vals = packed.split("|")
if len(vals) != len(NAMES):
    sys.stderr.write(f"set_retention: expected {len(NAMES)} fields, got {len(vals)}\n")
    sys.exit(1)
tree = ET.parse(path); root = tree.getroot()
def setel(name, text):
    el = root.find(name)
    if el is None:
        el = ET.SubElement(root, name)
    el.text = text
for n, v in zip(NAMES, vals):
    if v == "absent":
        continue
    setel(n, v)
tree.write(path, encoding="utf-8", xml_declaration=True)
PY
}

# Compare two `|`-separated retention lines field by field, printing one line per field.
#   $1 expected   $2 found   $3 label   $4 word for $1   $5 word for $2
# An UNREADABLE or empty value on EITHER side is a failure, never a pass - "could not look" and
# "they match" are different answers (CR-02's rule, applied to a different instrument).
compare_retention() {
  local expect="$1" found="$2" label="$3" ew="${4:-before}" fw="${5:-after}"
  local i=1 name e f rc=0
  case "$expect" in
    ""|UNREADABLE*)
      bad "${label}: the ${ew} values are ${expect:-<empty>} - UNKNOWN, not a pass."; return 1 ;;
  esac
  case "$found" in
    ""|UNREADABLE*)
      bad "${label}: the ${fw} values are ${found:-<empty>} - UNKNOWN, not a pass."; return 1 ;;
  esac
  for name in $RETENTION_FIELDS; do
    e=$(retention_field "$expect" "$i")
    f=$(retention_field "$found" "$i")
    if [ "$e" = "$f" ]; then
      ok "${label} ${name}: PASS (${f})"
    else
      bad "${label} ${name}: FAIL - MISMATCH ${ew}='${e}' ${fw}='${f}'"
      rc=1
    fi
    i=$((i + 1))
  done
  return $rc
}

# --- verify-retention: fault-injection path (a) -------------------------------------------
#
# WHY THIS SUB-ACTION EXISTS AT ALL.
#   The cross-AI review of plan 02.1-04 raised it as a HIGH finding: the retention verification
#   lives INSIDE do_enable, and do_enable RE-CAPTURES the live values before restoring. So the
#   obvious negative control - perturb a value, re-run `enable`, expect non-zero - cannot fail. It
#   would capture the perturbed values, carry them faithfully across the restore, and PASS. There
#   was no separately-invocable verification entry point and therefore no way to prove the
#   verification could fail at all. A proof that cannot fail produces a transcript that LOOKS like
#   evidence, which is the exact failure class this phase exists to close.
#
#   verify-retention is that entry point. It takes its expectations from the CALLER
#   ($TRAN09_EXPECT) rather than re-deriving them from the file it is checking, which is precisely
#   what makes it able to fail.
#
# STRICTLY READ-ONLY: it writes nothing, restarts nothing, touches no .bak, and does not call
# preconditions() - it must work against an arbitrary throwaway config with no container in sight.
do_verify_retention() {
  say "== verify-retention (read-only) =="
  say "  encoding.xml      : $JELLYFIN_CONFIG"
  if [ -z "${TRAN09_EXPECT:-}" ]; then
    bad "TRAN09_EXPECT is not set - there is nothing to compare against."
    say "  Set it to a '|'-separated line in this field order:"
    say "    $RETENTION_FIELDS"
    say "  e.g. TRAN09_EXPECT='/cache/transcodes|true|300|true|180'"
    return 2
  fi
  local found; found=$(current_retention "$JELLYFIN_CONFIG")
  say "  expected          : $TRAN09_EXPECT"
  say "  found             : $found"
  say ""
  if compare_retention "$TRAN09_EXPECT" "$found" "verify-retention" "expected" "found"; then
    ok "all five transcode-retention values match TRAN09_EXPECT"
    return 0
  fi
  bad "verify-retention FAILED - see the per-field lines above"
  return 1
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
  # TRAN-09 (2026-09-03, phase 02.1, D-29). THE WHOLE-FILE RESTORE BELOW WAS A ONE-COMMAND SILENT
  # REVERT OF PHASE 02.1.
  #
  # do_enable restores the ENTIRE encoding.xml from the newest .bak, and the only .bak on disk -
  # encoding.xml.bak.20260831T182741Z - was taken BEFORE phase 02.1's settings existed. Running
  # `enable` after that phase landed therefore turned all five of
  #   TranscodingTempPath, EnableSegmentDeletion, SegmentKeepSeconds,
  #   EnableThrottling, ThrottleDelaySeconds
  # back to their pre-phase values AND REPORTED SUCCESS, because the IN-06 verification below
  # checked HardwareAccelerationType and nothing else.
  #
  # This is now handled by: capture the five from the LIVE config before the cp, re-assert them
  # into the restored file, and verify them twice - once before the container restart (so a lost
  # value never gets restarted onto) and once after it (so a Jellyfin that rewrites the file on
  # startup is caught too). Any mismatch names the field with its BEFORE and AFTER values and
  # returns non-zero.
  #
  # Proof transcript, including both executed negative controls:
  #   .planning/phases/02.1-jellyfin-transcode-retention-relocate-the-anonymous-transcod/
  #     artifacts/02.1-07-tran09-proof.txt
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

  # TRAN-09 STEP 1 OF 3: CAPTURE, BEFORE THE cp.
  # This must happen before the restore, not after it - after the cp the live values are gone and
  # there is nothing left to carry across.
  local pre_ret; pre_ret=$(current_retention "$JELLYFIN_CONFIG")
  case "$pre_ret" in
    ""|UNREADABLE*)
      bad "could not read the transcode-retention values out of $JELLYFIN_CONFIG (${pre_ret:-<empty>})."
      bad "Restoring a whole file OVER a config you could not read IS the silent-revert shape this"
      bad "hardening exists to remove - there would be nothing to carry across and no way to tell."
      bad "Refusing to restore. Read $JELLYFIN_CONFIG by hand, then re-run."
      return 1 ;;
  esac
  say "  preserving across the restore (TRAN-09):"
  local _rf_i=1 _rf_n
  for _rf_n in $RETENTION_FIELDS; do
    say "      ${_rf_n} = $(retention_field "$pre_ret" "$_rf_i")"
    _rf_i=$((_rf_i + 1))
  done

  cp -p "$backup" "$JELLYFIN_CONFIG" || { bad "restore failed"; return 1; }
  ok "restored from $backup"

  # TRAN-09 STEP 2 OF 3: RE-ASSERT, after the cp and before the restart.
  if [ "${TRAN09_FAULT:-}" = "1" ]; then
    warn "TRAN09_FAULT=1 IS ACTIVE - THE RETENTION RE-ASSERT IS BEING SKIPPED ON PURPOSE."
    warn "This is a TEST-ONLY hook (plan 02.1-07, VALIDATION.md row 35, negative control 2)."
    warn "In production it turns 'enable' back into the silent revert this hardening removes."
    warn "The verification below is NOT skipped, so this run will fail loudly and non-zero."
  else
    if ! set_retention "$pre_ret"; then
      bad "re-asserting the transcode-retention values into the restored config FAILED."
      bad "the restored file is now the PRE-PHASE config; the values that were live are printed"
      bad "above. Restore them by hand, or re-run 'enable' once the cause is understood."
      return 1
    fi
    ok "re-asserted the five transcode-retention values into the restored config"
  fi

  # TRAN-09 STEP 3 OF 3a: VERIFY BEFORE THE RESTART.
  # Deliberately before `docker restart`: restarting a service the house is watching onto a config
  # that has silently lost this phase's settings is strictly worse than not restarting at all.
  say ""
  say "== pre-restart retention verification =="
  local mid_ret; mid_ret=$(current_retention "$JELLYFIN_CONFIG")
  if ! compare_retention "$pre_ret" "$mid_ret" "pre-restart" "before" "after"; then
    bad "the whole-file restore MOVED transcode-retention values - this is exactly the silent"
    bad "revert TRAN-09 closes, and it is being REPORTED rather than hidden."
    bad "NOT restarting $JELLYFIN_CONTAINER. The restored backup was $backup."
    bad "The pre-restore values are printed above; re-apply them before restarting."
    return 1
  fi
  ok "all five transcode-retention values survived the restore"

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

  # TRAN-09 STEP 3 OF 3b: VERIFY AGAIN AFTER THE RESTART.
  # Not redundant with the pre-restart check: Jellyfin can rewrite encoding.xml on startup, so the
  # only way to know the five values are live is to read them back from a config the server has
  # already seen. Same rule as do_disable at the CR-02 block above - a HALF-verified success
  # returns non-zero, because "VAAPI is back on" is only half of what this action now claims.
  local post_ret; post_ret=$(current_retention "$JELLYFIN_CONFIG")
  if ! compare_retention "$pre_ret" "$post_ret" "post-restart" "before" "after"; then
    bad "the transcode-retention values did NOT survive the restore and restart."
    bad "Exiting non-zero deliberately: 'enable' must never report success while having reverted"
    bad "phase 02.1's transcode retention. The restored backup was $backup."
    return 1
  fi
  ok "verified: the five transcode-retention values survived the whole-file restore"

  warn "VAAPI is back ON - the orphaned-transcode trigger is re-armed"
  return 0
}

case "$ACTION" in
  check)            do_check ;;
  disable)          do_disable ;;
  enable)           do_enable ;;
  verify-retention) do_verify_retention ;;
  *)                usage ;;
esac
