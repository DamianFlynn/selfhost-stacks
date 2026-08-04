#!/usr/bin/env bash
#
# Keep podsync's yt-dlp current.
#
# WHY THIS EXISTS
#   podsync bundles yt-dlp in its image and offers `self_update`, but neither works here:
#
#     * self_update must write into /usr/local/bin, which is not writable by uid 568.
#       It failed SILENTLY for ~13 months -- not one log line.
#     * podsync releases rarely (v2.8.0 was the latest release for over a year while the
#       repo kept getting commits), so pulling a newer image does not refresh yt-dlp either.
#
#   The result: yt-dlp went stale, YouTube's SABR rollout blocked it, and every download
#   failed with "The following content is not available on this app." -- 792 errors in 6h,
#   0 downloads. YouTube breaks old yt-dlp regularly, so this WILL recur without automation.
#
# WHAT IT DOES
#   Downloads the current yt-dlp, and only if the version actually changed, installs it and
#   restarts podsync. Safe to run repeatedly; a no-op when already current.
#
# IMPORTANT: must fetch the plain zipapp asset, NOT yt-dlp_linux.
#   The podsync image is Alpine/musl with Python 3.12. The `yt-dlp_linux` standalone is a
#   glibc PyInstaller binary and cannot execute there -- podsync crash-loops with
#   "could not find youtube-dl: exit status 255".
#
set -euo pipefail

BIN=/mnt/fast/appdata/hoarder/podsync/bin/yt-dlp
URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp   # zipapp, ~3MB
CONTAINER=podsync
OWNER=568:568

log() { echo "$(date '+%F %T') :: update-ytdlp :: $*"; }

tmp=$(mktemp /tmp/yt-dlp.XXXXXX)
trap 'rm -f "$tmp"' EXIT

current="none"
[ -x "$BIN" ] && current=$("$BIN" --version 2>/dev/null | tail -1 || echo "unreadable")

log "current version: $current"

if ! curl -fsSL --max-time 120 -o "$tmp" "$URL"; then
  log "ERROR: download failed; leaving existing binary untouched"
  exit 1
fi

# Guard against a truncated download or an HTML error page being installed.
if [ "$(head -c 2 "$tmp")" != '#!' ]; then
  log "ERROR: downloaded file is not a '#!' zipapp (wrong asset or error page); aborting"
  exit 1
fi
if [ "$(stat -c%s "$tmp")" -lt 1000000 ]; then
  log "ERROR: downloaded file is implausibly small; aborting"
  exit 1
fi

chmod 755 "$tmp"
latest=$("$tmp" --version 2>/dev/null | tail -1 || echo "")
if [ -z "$latest" ]; then
  log "ERROR: downloaded binary does not report a version; aborting"
  exit 1
fi
log "latest version:  $latest"

if [ "$current" = "$latest" ]; then
  log "already current -- no action"
  exit 0
fi

install -o "${OWNER%:*}" -g "${OWNER#*:}" -m 755 "$tmp" "$BIN"
log "installed $latest (was $current)"

if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  docker restart "$CONTAINER" >/dev/null
  sleep 10
  if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    log "restarted $CONTAINER -- running"
  else
    log "WARNING: $CONTAINER did not come back after restart; check 'docker logs $CONTAINER'"
    exit 1
  fi
else
  log "note: $CONTAINER not running; binary updated, nothing to restart"
fi

log "done"
