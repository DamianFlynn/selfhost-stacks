#!/usr/bin/env bash
# freeze-music-apply.sh - Build the pre-project recovery fence, and normalise library ownership.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   Host-resident rather than workstation-resident because ZFS snapshots, a 764-file ffprobe
#   sweep and a recursive chown/chmod over /mnt/tank cannot each be expressed as one ssh'd
#   command. Same convention as scripts/setup-mpe.sh and scripts/pg-migrate.sh.
#
# Usage:
#   bash scripts/freeze-music-apply.sh fence       # build the recovery fence (plan 01-02)
#   bash scripts/freeze-music-apply.sh ownership   # normalise library uid:gid and modes (plan 01-08)
#   bash scripts/freeze-music-apply.sh all         # fence, then ownership
#
# Workflow:
#   ssh root@172.16.1.159
#   cd /mnt/fast/stacks && git pull --ff-only
#   bash scripts/freeze-music-apply.sh fence
#   bash scripts/check-music-freeze.sh --baseline    # section 6 verifies what fence built
#
# ⚠️  This script MUTATES live state. Review, then run deliberately.
#     `fence`      creates two ZFS snapshots on the `tank` pool and writes ~350 MB under
#                  /mnt/fast/safety. It reads /mnt/tank; it never writes there.
#     `ownership`  recursively rewrites uid:gid across the ENTIRE Music dataset, library root
#                  included (2,674 entries as of 2026-08-18). It refuses to run unless the Music
#                  snapshot exists, because that snapshot is its only rollback.
#                  It does NOT touch mode bits - chmod is impossible on this pool and D-12 is
#                  scoped out by user decision. See the long comment in do_ownership().
#                  The chown itself executes on the Proxmox host: LXC 100 is unprivileged and
#                  physically cannot chown the library's unmapped uids/gids.
#
# Idempotent:
#   `fence`      re-run reports every stage as already present and changes nothing. An existing
#                snapshot is reported and skipped - the script never issues a rollback or a
#                destroy subcommand, because undoing a snapshot is a deliberate human act, not a
#                re-run side effect. An existing non-empty ffprobe JSON or cover scan is skipped.
#                MANIFEST.txt is the one exception: it is derived state and is rewritten.
#   `ownership`  chown/chmod are naturally convergent; a re-run reports 0 mismatches before and
#                after and touches nothing that is already correct.
#
# STORAGE SHAPE (D-05, stated as the plan requires):
#   dj-mixes-ffprobe/ MIRRORS the source tree - one JSON file per source audio file at
#   <relative dir>/<filename>.json. The relative path IS the slug. A flattened slug was rejected
#   because release folder + track filename here routinely exceeds ext4's 255-byte filename
#   limit. Each JSON is the FULL ffprobe output (-show_format -show_streams), never a selected
#   field list, so TKEY and EnergyLevel fall out automatically (SAFE-03).
#   cover-scans/ mirrors the same way, so a scan traces back to its release.
#
# ZFS NOTE (2026-08-18, carried over from scripts/check-music-freeze.sh):
#   LXC 100 is an unprivileged container. The tank datasets are bind-mounted into it, but the
#   `zfs` command is NOT installed here and cannot be - the pool lives on the Proxmox host
#   "atlantis" (172.16.1.158). Every zfs invocation below is routed through zfs_exec(), which
#   uses a local `zfs` when one exists and otherwise delegates over ssh, and the route taken is
#   printed. Nothing here is hard-coded to either assumption.
#
# RSYNC NOTE (2026-08-18): rsync is NOT installed on LXC 100 - verified. The fence lives on
#   /mnt/fast (the LXC's own ext4 disk), so cp is the correct and sufficient tool and no copy in
#   this script targets `tank`. RSYNC_FLAGS is defined and used anyway by fence_copy(), so that a
#   later edit which redirects the fence onto `tank` cannot silently land zero files: `rsync -a`
#   fails there with `mkstemp ... Operation not permitted` on every file - acltype=nfsv4 plus
#   aclmode=restricted reject rsync replicating source mode and ownership - while printing a
#   stats block that reports bytes *sent* rather than written and exiting 23.
#
# NOTHING is written to /tmp. /tmp on LXC 100 is tmpfs backed by host RAM; a 1.1 GB file there
# previously took the whole 28 GB box down and killed ssh on both host and container.

set -euo pipefail

LIBRARY="/mnt/tank/media/Music"
DOWNLOADS="/mnt/tank/downloads"
DJMIXES="/mnt/tank/downloads/complete/nzb/dj-mixes"
APPDATA="/mnt/fast/appdata"
FENCE="/mnt/fast/safety/music-pre-project"
SNAPTAG="pre-project"
UIDGID="568:568"
DIR_MODE="755"
FILE_MODE="644"
ZFS_HOST="172.16.1.158"                       # Proxmox host "atlantis" - the only place zfs exists
RSYNC_FLAGS="-rlt --no-p --no-o --no-g"       # never -a on tank; see RSYNC NOTE above

# Audio extensions swept by ffprobe. dj-mixes is mp3 + wav today (630 + 134); the rest are
# listed so a later drop-in of a flac or m4a release is not silently skipped.
AUDIO_EXT=(mp3 wav flac m4a aiff aif wma ogg opus aac wv ape alac)
# Image extensions archived as cover scans. bmp and gif are NOT in the plan's list (jpg/jpeg/
# png/webp) - and 24 of the 54 live scans are BMP, so that list would have archived 30 of 54.
IMAGE_EXT=(jpg jpeg png webp bmp gif tif tiff)

usage() {
  cat >&2 <<'EOF'
usage: bash scripts/freeze-music-apply.sh <fence|ownership|all>

  fence      Build the recovery fence: two ZFS snapshots, every beets library database,
             a full ffprobe JSON dump of the dj-mixes tree, the DJ cover scans, checksums
             and a manifest. Reads /mnt/tank; writes only under /mnt/fast/safety.
  ownership  Normalise /mnt/tank/media/Music (root included) to 568:568. Mode bits are NOT
             touched - chmod is impossible on this pool (aclmode=restricted), D-12 scoped out.
             The chown runs on the Proxmox host; it cannot work from inside LXC 100.
             REFUSES to run unless tank/media/Music@pre-project exists.
  all        fence, then ownership.
EOF
  exit 2
}

[[ $# -eq 1 ]] || usage
case "$1" in
  fence|ownership|all) SUBCOMMAND="$1" ;;
  -h|--help) usage ;;
  *) echo "unknown subcommand: $1" >&2; usage ;;
esac

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "    ${GREEN}$*${NC}"; }
warn() { echo -e "    ${YELLOW}WARN: $*${NC}"; }
err()  { echo -e "    ${RED}FAIL: $*${NC}"; }
banner() {
  echo ""
  echo "=================================================="
  echo "  $1"
  echo "=================================================="
}

# ─── zfs routing ──────────────────────────────────────────────────────────────
# Read-only detection first, so the route is known and printed before anything mutates.
ZFS_ROUTE="unavailable"
detect_zfs_route() {
  if command -v zfs >/dev/null 2>&1; then
    ZFS_ROUTE="local"
  elif ssh -o BatchMode=yes -o ConnectTimeout=8 "root@${ZFS_HOST}" 'zfs list -H -o name tank' >/dev/null 2>&1; then
    ZFS_ROUTE="ssh:${ZFS_HOST}"
  else
    ZFS_ROUTE="unavailable"
  fi
}

# zfs_exec "<full zfs command line>" - runs locally or on the Proxmox host, per the detected route.
zfs_exec() {
  local cmdline="$1"
  if [[ "$ZFS_ROUTE" == "local" ]]; then
    # shellcheck disable=SC2086
    eval "$cmdline"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=15 "root@${ZFS_HOST}" "$cmdline"
  fi
}

snapshot_exists() { zfs_exec "zfs list -t snapshot -H -o name '$1'" >/dev/null 2>&1; }
snapshot_creation() { zfs_exec "zfs get -H -p -o value creation '$1'" 2>/dev/null || echo "unknown"; }

# ─── copy helper ──────────────────────────────────────────────────────────────
# fence_copy SRC DST - byte-faithful copy into the fence. Uses rsync with RSYNC_FLAGS when rsync
# exists (so a fence relocated onto tank still works), otherwise cp preserving timestamps only.
fence_copy() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if command -v rsync >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    rsync $RSYNC_FLAGS -- "$src" "$dst"
  else
    cp --preserve=timestamps -- "$src" "$dst"
  fi
}

sha() { sha256sum -- "$1" | awk '{print $1}'; }

# find predicate builder. Populates the global array FIND_EXPR with a parenthesised -iname
# alternation. Built as an ARRAY, not a string passed through eval: the patterns contain `*`,
# and eval would glob-expand them against the caller's working directory before find ever saw
# them - silently matching nothing, or worse, matching the repo.
FIND_EXPR=()
build_iname_expr() {
  FIND_EXPR=( '(' )
  local first=1
  for e in "$@"; do
    [[ $first -eq 0 ]] && FIND_EXPR+=( '-o' )
    FIND_EXPR+=( '-iname' "*.${e}" )
    first=0
  done
  FIND_EXPR+=( ')' )
}

# ══════════════════════════════════════════════════════════════════════════════
#  fence
# ══════════════════════════════════════════════════════════════════════════════
FENCE_ERRORS=0
do_fence() {
  banner "fence - building the pre-project recovery fence"
  echo "  fence:     $FENCE"
  echo "  library:   $LIBRARY"
  echo "  downloads: $DOWNLOADS"
  echo "  dj-mixes:  $DJMIXES"
  echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # ── 1. fence subtree ────────────────────────────────────────────────────────
  echo ""
  echo "==> 1. Creating the fence subtree..."
  for sub in library-db dj-mixes-ffprobe cover-scans tags audit; do
    if [[ -d "$FENCE/$sub" ]]; then
      echo "    $FENCE/$sub exists - leaving untouched"
    else
      mkdir -p "$FENCE/$sub"
      ok "created $FENCE/$sub"
    fi
  done

  local avail_kb
  avail_kb="$(df -Pk "$FENCE" | awk 'NR==2 {print $4}')"
  echo "    free on $(df -Ph "$FENCE" | awk 'NR==2 {print $1}'): $(df -Ph "$FENCE" | awk 'NR==2 {print $4}')"
  if [[ "${avail_kb:-0}" -lt 1048576 ]]; then
    warn "under 1 GiB free where the fence lives - the cover scans alone are ~300 MB"
  fi

  # ── 2. ZFS snapshots (D-09) - FIRST, before any copy ────────────────────────
  echo ""
  echo "==> 2. ZFS snapshots (D-09) - taken before anything else in this phase writes..."
  detect_zfs_route
  case "$ZFS_ROUTE" in
    local)       ok "zfs route: local" ;;
    unavailable) err "zfs unreachable locally and at root@${ZFS_HOST} - cannot snapshot"
                 FENCE_ERRORS=$((FENCE_ERRORS + 1)) ;;
    *)           ok "zfs route: ${ZFS_ROUTE} (LXC 100 is unprivileged; the pool lives on the Proxmox host)" ;;
  esac

  if [[ "$ZFS_ROUTE" != "unavailable" ]]; then
    # Two explicit invocations rather than a loop: these are the only mutations this subcommand
    # makes to the pool, and both dataset names should be readable without following a variable.
    if snapshot_exists "tank/media/Music@${SNAPTAG}"; then
      echo "    tank/media/Music@${SNAPTAG} exists - leaving untouched"
    else
      zfs_exec "zfs snapshot tank/media/Music@${SNAPTAG}"
      ok "created tank/media/Music@${SNAPTAG}"
    fi

    if snapshot_exists "tank/downloads@${SNAPTAG}"; then
      echo "    tank/downloads@${SNAPTAG} exists - leaving untouched"
    else
      zfs_exec "zfs snapshot tank/downloads@${SNAPTAG}"
      ok "created tank/downloads@${SNAPTAG}"
    fi

    for snap in "tank/media/Music@${SNAPTAG}" "tank/downloads@${SNAPTAG}"; do
      local c
      c="$(snapshot_creation "$snap")"
      if [[ "$c" =~ ^[0-9]+$ ]]; then
        echo "    $snap  created $(date -u -d "@$c" +%Y-%m-%dT%H:%M:%SZ)"
      else
        echo "    $snap  created $c"
      fi
    done
  fi

  # ── 3. beets library databases (SAFE-02) ────────────────────────────────────
  # Discovered, never hard-coded. Names collide across stacks (two library.db, two library.blb),
  # so each copy is prefixed with a slug derived from its path under appdata.
  echo ""
  echo "==> 3. Copying every beets library database (SAFE-02)..."
  local db_list db_count=0 db_live=0 db_bak=0
  local db_map="$FENCE/audit/library-db-sources.tsv"
  # `*library*` rather than an extension list, deliberately. arr-scripts leaves eleven
  # library.blb-before-<migration>.bak copies under sabnzbd/config/scripts - real pre-project
  # beets database state, on /mnt/fast, with no snapshot behind it. An extension-anchored
  # pattern silently drops all eleven. Verified 2026-08-18: this pattern matches 15 files,
  # 766 KB, all of them beets, and nothing unrelated.
  db_list="$(find "$APPDATA" -maxdepth 6 -type f \
               \( -iname '*library*' -o -iname '*.blb' \) 2>/dev/null | sort -u || true)"

  if [[ -z "$db_list" ]]; then
    err "no beets library database found under $APPDATA - SAFE-02 cannot be satisfied"
    FENCE_ERRORS=$((FENCE_ERRORS + 1))
  fi

  # The source->copy map is written to disk rather than reconstructed from the slug in section 6.
  # Slugs are built by replacing / with _, and several of these paths already contain _
  # (library.blb-before-items-relative_path.bak), so reversing the slug is lossy and would
  # silently downgrade a strict sha256 check into a weaker one.
  : > "$db_map"

  while IFS= read -r src; do
    [[ -z "$src" ]] && continue
    local rel slug dst mech
    rel="${src#"$APPDATA"/}"
    slug="$(printf '%s' "$rel" | tr '/' '_')"
    dst="$FENCE/library-db/$slug"
    db_count=$((db_count + 1))
    case "$src" in *.bak) db_bak=$((db_bak + 1)) ;; *) db_live=$((db_live + 1)) ;; esac

    if [[ -s "$dst" ]]; then
      echo "    $slug exists - leaving untouched"
      printf '%s\t%s\tpre-existing\n' "$src" "$dst" >> "$db_map"
      continue
    fi
    # These are live files. A plain copy can tear a WAL, so prefer the SQLite online-backup
    # mechanism and record which one was actually used per file.
    if command -v sqlite3 >/dev/null 2>&1 && sqlite3 "$src" ".backup '$dst'" 2>/dev/null; then
      mech="sqlite3-backup"
    else
      fence_copy "$src" "$dst"
      mech="plain-copy"
    fi
    printf '%s\t%s\t%s\n' "$src" "$dst" "$mech" >> "$db_map"
    ok "$slug  <- $src  [$mech]"
  done <<< "$db_list"
  echo "    $db_count databases fenced ($db_live live, $db_bak .bak)"

  # ── 4. ffprobe dump of the dj-mixes tree (SAFE-03, D-05) ────────────────────
  echo ""
  echo "==> 4. ffprobe JSON dump of the dj-mixes tree (SAFE-03, D-05)..."
  local probe_total=0 probe_new=0 probe_skip=0 probe_fail=0
  if ! command -v ffprobe >/dev/null 2>&1; then
    err "ffprobe not found - SAFE-03 cannot be satisfied (plan 01-01 installs it; this script does not install packages)"
    FENCE_ERRORS=$((FENCE_ERRORS + 1))
  elif [[ ! -d "$DJMIXES" ]]; then
    err "$DJMIXES not present"
    FENCE_ERRORS=$((FENCE_ERRORS + 1))
  else
    build_iname_expr "${AUDIO_EXT[@]}"
    while IFS= read -r src; do
      [[ -z "$src" ]] && continue
      probe_total=$((probe_total + 1))
      local rel dst
      rel="${src#"$DJMIXES"/}"
      dst="$FENCE/dj-mixes-ffprobe/${rel}.json"
      if [[ -s "$dst" ]]; then
        probe_skip=$((probe_skip + 1))
        continue
      fi
      mkdir -p "$(dirname "$dst")"
      # FULL output. -show_format carries the container tag block (where TKEY and EnergyLevel
      # live for ID3), -show_streams the per-stream tag block. Never a selected field list.
      if ffprobe -v quiet -print_format json -show_format -show_streams -- "$src" > "$dst" 2>/dev/null \
         && [[ -s "$dst" ]]; then
        probe_new=$((probe_new + 1))
      else
        probe_fail=$((probe_fail + 1))
        rm -f "$dst"
        warn "ffprobe non-zero or empty output: $src"
      fi
    done <<< "$(find "$DJMIXES" -type f "${FIND_EXPR[@]}" | sort)"
    echo "    $probe_total audio files, $probe_new probed now, $probe_skip already present, $probe_fail failed"
    if [[ $probe_fail -gt 0 ]]; then
      err "$probe_fail ffprobe failures - SAFE-03 coverage is incomplete"
      FENCE_ERRORS=$((FENCE_ERRORS + 1))
    fi
    # Report what SAFE-03 actually exists for, rather than assuming full output implies presence.
    local tkey_hits energy_hits
    tkey_hits="$(grep -rl 'TKEY' "$FENCE/dj-mixes-ffprobe" 2>/dev/null | wc -l | tr -d ' ')"
    energy_hits="$(grep -ril 'EnergyLevel' "$FENCE/dj-mixes-ffprobe" 2>/dev/null | wc -l | tr -d ' ')"
    echo "    TKEY present in $tkey_hits files, EnergyLevel present in $energy_hits files"
    if [[ "$tkey_hits" -eq 0 && "$energy_hits" -eq 0 ]]; then
      warn "neither TKEY nor EnergyLevel appears anywhere in the dump - verify the dump is full ffprobe output, not a reduced field set (D-05)"
    fi
  fi

  # ── 5. DJ cover scans (SAFE-04) ─────────────────────────────────────────────
  echo ""
  echo "==> 5. Archiving the DJ cover scans (SAFE-04)..."
  local scan_total=0 scan_new=0 scan_skip=0 scan_folders=0
  if [[ -d "$DJMIXES" ]]; then
    build_iname_expr "${IMAGE_EXT[@]}"
    while IFS= read -r src; do
      [[ -z "$src" ]] && continue
      scan_total=$((scan_total + 1))
      local rel dst
      rel="${src#"$DJMIXES"/}"
      dst="$FENCE/cover-scans/$rel"
      if [[ -s "$dst" ]]; then
        scan_skip=$((scan_skip + 1))
        continue
      fi
      fence_copy "$src" "$dst"
      scan_new=$((scan_new + 1))
    done <<< "$(find "$DJMIXES" -type f "${FIND_EXPR[@]}" | sort)"
    scan_folders="$(find "$DJMIXES" -type f "${FIND_EXPR[@]}" -printf '%h\n' | sort -u | wc -l | tr -d ' ')"
    echo "    $scan_total scans across $scan_folders folders ($scan_new copied now, $scan_skip already present)"
    # The 54-across-27 census dates from 2026-08-17. A difference is a warning, not a failure.
    if [[ "$scan_total" -ne 54 ]]; then
      warn "expected 54 cover scans (census 2026-08-17); found $scan_total"
    else
      ok "cover-scan count matches the expected 54"
    fi
  else
    err "$DJMIXES not present - SAFE-04 cannot be satisfied"
    FENCE_ERRORS=$((FENCE_ERRORS + 1))
  fi

  # ── 6. Spot-check every copy against its source (D-10) ──────────────────────
  echo ""
  echo "==> 6. Spot-check: sha256 of every copy against its source (D-10)..."
  local chk_total=0 chk_ok=0 chk_bad=0 chk_int=0
  # 6a. cover scans - plain byte copies, so sha256 equality is the right test and is strict.
  while IFS= read -r dst; do
    [[ -z "$dst" ]] && continue
    local rel src
    rel="${dst#"$FENCE"/cover-scans/}"
    src="$DJMIXES/$rel"
    chk_total=$((chk_total + 1))
    if [[ -f "$src" ]] && [[ "$(sha "$src")" == "$(sha "$dst")" ]]; then
      chk_ok=$((chk_ok + 1))
    else
      chk_bad=$((chk_bad + 1))
      err "sha256 mismatch: $dst"
    fi
  done <<< "$(find "$FENCE/cover-scans" -type f 2>/dev/null | sort || true)"

  # 6b. library databases, walked from the source->copy map written in section 3 so the source
  # path is exact. sqlite3 .backup rewrites page layout, so a byte-identical result is NOT
  # guaranteed and a strict sha256 equality test would fail a perfectly good backup. The
  # applicable integrity test for those is `PRAGMA integrity_check` on the copy; sha256 equality
  # is still asserted, and preferred, wherever it holds.
  while IFS=$'\t' read -r src dst mech; do
    [[ -z "${dst:-}" ]] && continue
    chk_total=$((chk_total + 1))
    if [[ -f "$src" ]] && [[ "$(sha "$src")" == "$(sha "$dst")" ]]; then
      chk_ok=$((chk_ok + 1))
    elif command -v sqlite3 >/dev/null 2>&1 \
         && [[ "$(sqlite3 "$dst" 'PRAGMA integrity_check;' 2>/dev/null | head -1)" == "ok" ]]; then
      chk_ok=$((chk_ok + 1))
      chk_int=$((chk_int + 1))
      echo "    integrity_check ok (sha256 differs from source, expected for $mech): $(basename "$dst")"
    else
      chk_bad=$((chk_bad + 1))
      err "neither sha256-equal to source nor integrity_check ok: $dst"
    fi
  done < "$db_map"

  echo "    verified $chk_ok / $chk_total copies ($chk_int of them by sqlite3 integrity_check rather than sha256 equality, by design)"
  if [[ $chk_bad -gt 0 ]]; then
    err "$chk_bad copies failed verification"
    FENCE_ERRORS=$((FENCE_ERRORS + 1))
  fi

  # ── 7. Manifest ─────────────────────────────────────────────────────────────
  echo ""
  echo "==> 7. Writing $FENCE/MANIFEST.txt..."
  local man="$FENCE/MANIFEST.txt"
  local snap_found nd recs keys base donec failc
  {
    echo "# music-pre-project recovery fence - MANIFEST"
    echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)  host: $(hostname)"
    echo "# generator: scripts/freeze-music-apply.sh fence"
    echo "# zfs route: $ZFS_ROUTE"
    echo ""
    echo "## snapshots"
    for snap in "tank/media/Music@${SNAPTAG}" "tank/downloads@${SNAPTAG}"; do
      if [[ "$ZFS_ROUTE" != "unavailable" ]] && snapshot_exists "$snap"; then
        c="$(snapshot_creation "$snap")"
        if [[ "$c" =~ ^[0-9]+$ ]]; then c="$(date -u -d "@$c" +%Y-%m-%dT%H:%M:%SZ)"; fi
        echo "present  $snap  created=$c"
      else
        echo "MISSING  $snap"
      fi
    done
    echo ""
    echo "## per-class counts and bytes"
    for sub in library-db dj-mixes-ffprobe cover-scans tags; do
      n="$(find "$FENCE/$sub" -type f 2>/dev/null | wc -l | tr -d ' ')"
      b="$(find "$FENCE/$sub" -type f -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {print s+0}')"
      printf '%-18s files=%-8s bytes=%s\n' "$sub" "$n" "$b"
    done
    echo ""
    # QUAL-01 snapshots are the one fenced class whose integrity is not fully described by a
    # byte count and a digest: the thing that matters downstream is how many RECORDS it holds
    # and how many distinct audio_md5 join keys those collapse to, because Phase 7's diff joins
    # on the key and a short capture is indistinguishable from a complete one by size alone.
    # Emitted here, by the generator, rather than appended by hand after a capture run - section
    # 7 rewrites this file wholesale, so a hand-appended line survives exactly until the next
    # `fence` invocation and then silently disappears.
    echo "## QUAL-01 tag snapshots"
    snap_found=0
    while IFS= read -r nd; do
      [[ -n "$nd" ]] || continue
      snap_found=1
      recs="?"; keys="?"
      if command -v gzip >/dev/null 2>&1; then
        recs="$(gzip -cd -- "$nd" 2>/dev/null | wc -l | tr -d ' ')"
        if command -v jq >/dev/null 2>&1; then
          keys="$(gzip -cd -- "$nd" 2>/dev/null | jq -r '.audio_md5 // empty' 2>/dev/null \
                  | sort -u | wc -l | tr -d ' ')"
        fi
      fi
      base="${nd%.ndjson.gz}"
      donec="$( [[ -f "${base}.done"   ]] && wc -l < "${base}.done"   | tr -d ' ' || echo '-' )"
      failc="$( [[ -f "${base}.failed" ]] && wc -l < "${base}.failed" | tr -d ' ' || echo '-' )"
      printf '%s  records=%s  distinct_audio_md5=%s  done=%s  failed=%s  bytes=%s\n' \
        "$(basename "$nd")" "$recs" "$keys" "$donec" "$failc" "$(stat -c %s "$nd" 2>/dev/null || echo '?')"
      printf '  sha256=%s\n' "$(sha "$nd")"
    done < <(find "$FENCE/tags" -type f -name '*.ndjson.gz' 2>/dev/null | sort)
    [[ $snap_found -eq 1 ]] || echo "(none - QUAL-01 capture has not been run; see plan 01-04)"

    echo ""
    echo "## sha256 of every fenced artifact"
    echo "# library-db copies made with sqlite3 .backup are NOT byte-identical to their source"
    echo "# by design; they are verified with PRAGMA integrity_check instead. See section 6."
    find "$FENCE" -type f ! -name 'MANIFEST.txt' -print0 2>/dev/null \
      | sort -z | xargs -0 -r sha256sum
  } > "$man"
  ok "manifest written ($(wc -l < "$man" | tr -d ' ') lines)"

  # ── 8. Fence ownership and modes ────────────────────────────────────────────
  # The FENCE only. The library is the `ownership` subcommand's job, and plan 01-08 runs it.
  echo ""
  echo "==> 8. Setting fence ownership ${UIDGID}, dirs ${DIR_MODE}, files ${FILE_MODE}..."
  chown -R "${UIDGID}" "$FENCE"
  find "$FENCE" -type d -exec chmod "$DIR_MODE" {} +
  find "$FENCE" -type f -exec chmod "$FILE_MODE" {} +
  ok "$(find "$FENCE" -type d | wc -l | tr -d ' ') directories, $(find "$FENCE" -type f | wc -l | tr -d ' ') files"

  echo ""
  if [[ $FENCE_ERRORS -gt 0 ]]; then
    echo -e "${RED}fence: $FENCE_ERRORS error(s) - the fence is NOT complete${NC}"
    return 1
  fi
  echo -e "${GREEN}fence: complete${NC}"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════════
#  ownership  (WRIT-04, D-11/D-12) - shipped here, RUN BY PLAN 01-08
# ══════════════════════════════════════════════════════════════════════════════
census_counts() { # prints "own dirmode filemode total"
  # Includes the library ROOT (no -mindepth 1). The root is itself mis-owned and is not one of
  # the 13 artist folders, so excluding it would let this report "0 mismatches" while the
  # directory every NFS client mounts was still wrong. Totals are therefore 2674, not 2673.
  local census own dm fm tot
  census="$(find "$LIBRARY" -printf '%U:%G %m %y\n' 2>/dev/null || true)"
  own="$(printf '%s\n' "$census" | awk -v w="$UIDGID" 'NF && $1 != w' | grep -c . || true)"
  dm="$(printf '%s\n' "$census" | awk -v w="$DIR_MODE" '$3 == "d" && $2 != w' | grep -c . || true)"
  fm="$(printf '%s\n' "$census" | awk -v w="$FILE_MODE" '$3 == "f" && $2 != w' | grep -c . || true)"
  tot="$(printf '%s\n' "$census" | grep -c . || true)"
  echo "$own $dm $fm $tot"
}

do_ownership() {
  banner "ownership - normalising $LIBRARY to ${UIDGID} (mode pass scoped out, D-12)"

  # Precondition guard (pg-migrate.sh guard-then-SKIP shape). The snapshot is the only rollback
  # for a bad recursive chown across 2,673 entries. Without it this must not execute.
  detect_zfs_route
  echo "    zfs route: $ZFS_ROUTE"
  if [[ "$ZFS_ROUTE" == "unavailable" ]]; then
    err "SKIP: no zfs route - cannot confirm tank/media/Music@${SNAPTAG} exists, and that snapshot is this subcommand's only rollback"
    return 1
  fi
  if ! snapshot_exists "tank/media/Music@${SNAPTAG}"; then
    err "SKIP: tank/media/Music@${SNAPTAG} does not exist. Run \`$0 fence\` first - the snapshot is the only rollback for a bad recursive chown."
    return 1
  fi
  ok "precondition met: tank/media/Music@${SNAPTAG} exists"

  if [[ ! -d "$LIBRARY" ]]; then
    err "$LIBRARY not present on this host"
    return 1
  fi

  # SCOPE GUARD (T-01-46). The chown below runs as REAL root on the Proxmox host, not as a
  # namespaced container root, so a wrong LIBRARY constant here is a hypervisor-wide recursive
  # chown rather than a contained mistake. Assert the literal before delegating anything.
  if [[ "$LIBRARY" != "/mnt/tank/media/Music" ]]; then
    err "SKIP: LIBRARY is '$LIBRARY', expected '/mnt/tank/media/Music'. Refusing to run a recursive chown as real root against an unexpected path."
    return 1
  fi

  read -r b_own b_dm b_fm b_tot <<< "$(census_counts)"
  echo ""
  echo "    BEFORE: $b_tot entries"
  echo "      not ${UIDGID}:        $b_own"
  echo "      dirs not ${DIR_MODE}:      $b_dm"
  echo "      files not ${FILE_MODE}:     $b_fm"

  # ── the chown runs on the POOL HOST, not here ───────────────────────────────
  # Discovered 2026-08-18 (plan 01-08) by piloting one artist folder: `chown -R` fails with
  # `Operation not permitted` on EVERY entry when run from LXC 100, even as container root.
  #
  # Cause: LXC 100 is unprivileged with a sparse idmap. The library's real on-disk owners are
  # 0:545, 3000:545, 568:545, 100000:100000 and 100911:100911; of those, uid 0/3000 and gid 545
  # are OUTSIDE the container's map and surface as 65534. A process in a user namespace cannot
  # chown a file whose current uid or gid is unmapped - CAP_CHOWN in a nested namespace does not
  # reach ids the namespace cannot name. This is NOT the aclmode=restricted problem; it is a
  # different mechanism with the same errno, which is exactly why it was mistaken for one.
  #
  # Verified on the Proxmox host: chown succeeds, chmod still does not (see the mode pass below).
  # Delegation reuses the route detect_zfs_route() already established, so running this script
  # ON the pool host executes locally and nothing is ssh'd.
  echo ""
  echo "==> Setting ownership ${UIDGID} (route: ${ZFS_ROUTE})..."
  if [[ "$ZFS_ROUTE" == "local" ]]; then
    chown -R "${UIDGID}" "${LIBRARY}"
  else
    # Re-assert the path on the far side: a bind mount present here but absent there would
    # otherwise make `chown -R` a silent no-op against a path the remote auto-creates.
    ssh -o BatchMode=yes -o ConnectTimeout=15 "root@${ZFS_HOST}" \
      "test -d '${LIBRARY}' && chown -R '${UIDGID}' '${LIBRARY}'" \
      || { err "remote chown failed or ${LIBRARY} is absent on root@${ZFS_HOST}"; return 1; }
  fi
  ok "chown complete"

  # ── the mode pass is DELIBERATELY NOT RUN (D-12 scoped out, user decision 2026-08-18) ───────
  # Not skipped by accident, not swallowed with `|| true`, and not retried. `chmod` is IMPOSSIBLE
  # on this pool: it returns EPERM as real root for every mode, including a no-op `chmod 0777` on
  # a file already at 0777. Cause is `acltype=nfsv4` + `aclmode=restricted` on tank/media,
  # tank/media/Music and tank/downloads - `restricted` makes a chmod that would alter a
  # non-trivial NFSv4 ACL an error rather than a silent partial apply. Reproduced independently
  # three times: plan 01-06 on tank/downloads, the user on tank/media/Music, and plan 01-08's
  # pilot (37/37 invocations failed). It is also the root cause of PROJECT.md's `rsync -a`
  # failure, and it explains why every entry in the library reads 0777 - the mode is a projection
  # of the ACL, not a value anyone set.
  #
  # `zfs set aclmode=passthrough` WOULD make chmod work and is explicitly REJECTED: it is a
  # persistent property change on a live pool, and under passthrough a chmod REWRITES the ACL -
  # so it would overwrite the existing NFSv4 ACLs on all 2,674 entries to satisfy a cosmetic
  # half of a requirement. Do not "fix" this.
  #
  # Phase 2 inherits the consequence: knfsd does not export NFSv4 ACLs, so NFS clients see mode
  # bits only, and those will read 0777. That is tolerable ONLY while the export stays read-only.
  echo ""
  echo "==> Directory mode ${DIR_MODE} / file mode ${FILE_MODE}: SKIPPED BY DECISION"
  warn "D-12 is scoped out - chmod cannot succeed on this pool (acltype=nfsv4 + aclmode=restricted)."
  warn "The tree stays 0777. This is a recorded outcome, not a failure. See the comment above."

  read -r a_own a_dm a_fm a_tot <<< "$(census_counts)"
  echo ""
  echo "    AFTER:  $a_tot entries"
  echo "      not ${UIDGID}:        $a_own"
  echo "      dirs not ${DIR_MODE}:      $a_dm   (expected non-zero - mode pass scoped out)"
  echo "      files not ${FILE_MODE}:     $a_fm   (expected non-zero - mode pass scoped out)"

  echo ""
  # Success is the OWNERSHIP half only. Asserting on a_dm/a_fm here would make this subcommand
  # permanently red for a reason the user has already decided to accept.
  if [[ "$a_own" -eq 0 ]]; then
    echo -e "${GREEN}ownership: normalised (WRIT-04 ownership half; mode half scoped out per D-12)${NC}"
    return 0
  fi
  echo -e "${RED}ownership: $a_own residual mismatches remain${NC}"
  return 1
}

# ══════════════════════════════════════════════════════════════════════════════
case "$SUBCOMMAND" in
  fence)     do_fence ;;
  ownership) do_ownership ;;
  all)       do_fence && do_ownership ;;
esac
