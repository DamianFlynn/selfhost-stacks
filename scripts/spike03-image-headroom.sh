#!/usr/bin/env bash
# spike03-image-headroom.sh - Inventory reapable docker images on LXC 100, then delete ONLY the
#                             list an operator approved, and assert a root-filesystem floor.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident because it enumerates 110 images and 103 container objects and diffs them; that
#   is not expressible as one ssh'd command, and the estate convention (check-music-freeze.sh:6-12)
#   is that such work lives on the host and is reached by a single ssh from the workstation.
#   Delivery is git: this repo is checked out at /mnt/fast/stacks and nothing else copies files in.
#
# Usage:
#   bash scripts/spike03-image-headroom.sh inventory   # READ-ONLY: measure and write the reap list
#   bash scripts/spike03-image-headroom.sh prune       # ⚠ MUTATES: delete the approved reap list
#   bash scripts/spike03-image-headroom.sh --help      # print this header
#
# Workflow (plan 03-01, tasks 2 and 3):
#   ssh root@172.16.1.159
#   cd /mnt/fast/stacks && git pull --ff-only
#   mkdir -p /mnt/fast/spike-03/out
#   bash scripts/spike03-image-headroom.sh inventory     # -> writes the reap list, exits 0
#   <<< OPERATOR READS AND APPROVES THE LIST; struck rows are deleted from the file >>>
#   bash scripts/spike03-image-headroom.sh prune         # -> deletes exactly what survived
#
# Outputs:
#   $REAP_LIST  (default /mnt/fast/spike-03/out/reap-list.txt)
#               One reap candidate per line, TAB-separated: REPOSITORY:TAG<TAB>ID<TAB>SIZE.
#               Written by `inventory`. Read by `prune`. This file IS the approval gate.
#   stdout      The human report. Nothing else is written anywhere.
#
# CONTRACT:
#   `inventory` is READ-ONLY BY CONTRACT. It contains no `docker rmi`, no `docker image prune`,
#               no `docker system prune`, and no `rm` against anything but its own previous
#               output at $REAP_LIST, which it overwrites in place.
#   `prune`     ⚠ MUTATES LIVE STATE. It deletes docker images on a host running 103 containers.
#
# THE KEY (OD-1) - WHY THIS IS TWO SUBCOMMANDS AND NOT ONE SCRIPT WITH A PROMPT:
#   OD-1 makes this the gate for the whole of phase 3. LXC 100's root filesystem was measured at
#   99% on 2026-09-01 - 2.2 GB free of 126 GB - and it holds /var/lib/docker for 103 containers.
#   The four spike images need ~2.0-2.3 GB on disk. Filling `/` here takes the Docker host down for
#   the entire estate, so the floor is >= 8 GiB free, not "enough to fit".
#
#   Reclaiming that space is a delete on a live shared host. The approval therefore has to sit
#   between two PROCESSES joined by a file on disk, not between two branches of one process: a
#   branch can be skipped by a flag, an env var or a future edit, a missing file cannot. `inventory`
#   writes $REAP_LIST and stops. `prune` reads $REAP_LIST or refuses. That is the whole design.
#
#   And it is why `docker image prune -a` and `docker system prune` are PROHIBITED here, not merely
#   unused. Both decide for themselves what is unreferenced, at the moment they run, with no list a
#   human ever saw. This script deletes by explicit image ID, one at a time, from a file.
#
# THE KEY (T-03-01) - WHY THE REFERENCED SET COMES FROM `docker ps -a` WITH NO STATUS FILTER:
#   This estate has a documented `created`-state blind spot: dispatcharr and teleport sat in
#   `created` for six weeks - existing, never having run - behind a check that filtered on
#   status=restarting/dead/exited and therefore never saw them (project MEMORY; and
#   check-music-freeze.sh:31-38 states the same trap as its reason for having an exit convention
#   at all). A container in `created` has never run, so any status-filtered query misses it and its
#   image looks orphaned. Reaping that image silently breaks a container that already looks broken.
#   Every referenced-set derivation in this file is unfiltered, in both subcommands, deliberately.
#
# KNOWN COLLATERAL (T-03-01b, accepted not mitigated):
#   `docker ps -a` protects an image only if some container OBJECT references it - running, exited,
#   dead, restarting or created. It does NOT protect the image of a stack that is currently
#   `docker compose down`'d, because `down` removes the container objects. Such an image will be
#   listed as a reap candidate, will be reaped, and bringing that stack back up will need a fresh
#   `docker pull`. That is accepted at 2.2 GB free of 126 GB: a pull costs minutes, a full root
#   filesystem costs the whole estate. The partial mitigation is a cross-reference of every
#   candidate against the `image:` lines in stacks/selfhosted/**, done in 03-REAP-LIST.md so the
#   operator sees which rows are in that class BEFORE approving. The residual - one-off
#   `docker run` recipes and undocumented rollback images - cannot be detected by any automated
#   check, and is exactly what the human gate exists for.
#
# Idempotent:
#   `inventory` never writes anything but $REAP_LIST and can be run any number of times. Re-running
#              it AFTER a prune produces a shorter list, because the reaped images are gone.
#   `prune`    a second run finds every listed image already absent, reports `already reclaimed`,
#              deletes nothing, and STILL asserts the floor - so a repeat run is a valid way to
#              re-check headroom without re-deriving the list.
#   `--help`   never writes.
#
# EXIT-CODE CONVENTION (stated here deliberately, not inherited - the estate has no single one;
# see check-music-freeze.sh:31-38 for why that silence is itself a hazard):
#   inventory  0 always. It REPORTS; it does not assert. A floor breach is printed, not fatal,
#              because the whole point of running it is to find out how bad things are.
#   prune      0  every approved image is gone AND avail >= FLOOR_GB
#              1  pruned but still below the floor, or at least one `docker rmi` failed, or a
#                 listed image became referenced between approval and prune
#              2  usage error, or $REAP_LIST does not exist (refusal, never a fallback)
#
# HAZARD NOTES:
#   - NOTHING is written to /tmp. /tmp on LXC 100 is a tmpfs and large files there consume host
#     RAM (project MEMORY: 1.1 GB of EPG XML there took the whole 28 GB box down). All output goes
#     to $OUT_DIR under /mnt/fast.
#   - The reclaimable total is a SUM OF PER-IMAGE SIZES. Docker shares layers between images, so a
#     shared layer is counted once per image that uses it. Treat the figure as an UPPER BOUND on
#     what will actually be freed, and trust the measured `df` delta afterwards instead.
#   - `df` is read against `/` specifically, because that is where /var/lib/docker lives on this
#     host. Do not generalise it to /mnt/fast, which is a different pool entirely.

set -euo pipefail

FLOOR_GB="${FLOOR_GB:-8}"
OUT_DIR="${OUT_DIR:-/mnt/fast/spike-03/out}"
REAP_LIST="${REAP_LIST:-$OUT_DIR/reap-list.txt}"

# Allow-list. Anything whose REPOSITORY:TAG contains one of these substrings is never a candidate,
# even with no container referencing it. The three spike images are here so that a re-run of
# `inventory` after task 3's pulls cannot list the images the phase just fetched; `redis` is here
# because A4 (03-RESEARCH.md) may need redis:7-alpine as a beets-flask sidecar and it is already
# on the host. Substring match, deliberately generous - erring toward keeping.
KEEP_PATTERNS=(
  "sentriz/wrtag"
  "lscr.io/linuxserver/beets"
  "linuxserver/beets"
  "metasauce/beets-flask"
  "redis"
)

# Colors (check-music-freeze.sh:83-88)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

usage() {
  echo "usage: bash scripts/spike03-image-headroom.sh {inventory|prune}" >&2
  echo "       bash scripts/spike03-image-headroom.sh --help" >&2
  exit 2
}

ACTION="${1:-}"
case "$ACTION" in
  -h|--help)
    # Self-documenting help (check-music-freeze.sh:96-99): the header block IS the help text, so
    # the two can never drift apart.
    grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

# --- Measurement helpers ------------------------------------------------------------------------

# Available GiB on the filesystem holding /var/lib/docker. Digits only, so an empty or non-numeric
# reading is visibly empty rather than silently coerced to a plausible number.
#
# ⚠ MEASURED IN BYTES AND TRUNCATED, NOT `df -BG`. GNU `df -BG` ROUNDS UP: on this very host,
#   2.2 GiB actually free reports as `3G`. On an 8 GiB floor that is up to 1 GiB of optimism in
#   exactly the direction that hurts - it would pass the OD-1 gate at 7.1 GiB actual and then hand
#   ~2.0-2.3 GB of image pulls to a filesystem that cannot take them, on a host where filling `/`
#   takes down 103 containers. Reading -B1 and doing the division here truncates instead, so the
#   number printed is never larger than the truth.
#
#   03-01's acceptance criterion checks the floor externally with `df -BG ... -ge 8`. This measure
#   is strictly more conservative, so anything that satisfies this one also satisfies that one.
avail_gb() {
  local b
  b="$(df -B1 --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')"
  [ -z "$b" ] && return 0
  printf '%s' "$(( b / 1073741824 ))"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker not found - this script runs ON LXC 100 (root@172.16.1.159), not the workstation" >&2
    exit 2
  fi
}

# The referenced-image set: every token by which a container - IN ANY STATE - names its image.
#
# NO STATUS FILTER. See "THE KEY (T-03-01)" in the header: a `created` container has never run and
# a status-filtered query does not see it, but its image is still load-bearing.
#
# Two sources, unioned, because they answer different questions:
#   1. The Image COLUMN is the string the container was created with. It may be a repo:tag whose
#      tag has since been re-pointed at a different image, or a bare short id, or a repo@sha256.
#   2. `docker inspect` resolves to the image ID actually in use. That catches the case where a tag
#      moved after the container was created - the column says `foo:1.2`, the container is really
#      running an untagged image that now shows as <none>:<none> and would otherwise be a candidate.
# Both are emitted, plus a 12-char normalisation of any sha, so membership can be tested against
# either the REPOSITORY:TAG or the short ID that `docker images` reports.
referenced_set() {
  {
    docker ps -a --format '{{.Image}}' 2>/dev/null || true

    local cid img
    while read -r cid; do
      [ -z "$cid" ] && continue
      img="$(docker inspect --format '{{.Image}}' "$cid" 2>/dev/null || true)"
      [ -z "$img" ] && continue
      printf '%s\n' "$img"
      printf '%s\n' "${img#sha256:}" | cut -c1-12

      # Walk the parent chain. A dangling <none>:<none> image that is an ancestor of a referenced
      # image must never be reaped - removing it would break the child. On a content-addressable
      # store .Parent is usually empty, so this is normally a no-op; it is here because when it is
      # NOT empty the cost of being wrong is a broken container.
      local parent="$img" depth=0
      while [ "$depth" -lt 20 ]; do
        parent="$(docker image inspect --format '{{.Parent}}' "$parent" 2>/dev/null || true)"
        [ -z "$parent" ] && break
        printf '%s\n' "$parent"
        printf '%s\n' "${parent#sha256:}" | cut -c1-12
        depth=$((depth + 1))
      done
    done < <(docker ps -a --format '{{.ID}}' 2>/dev/null || true)
  } | sed 's/^sha256://' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' | sort -u
}

# True when $1 (a REPOSITORY:TAG) matches the allow-list.
is_kept() {
  local name="$1" pat
  for pat in "${KEEP_PATTERNS[@]}"; do
    case "$name" in
      *"$pat"*) return 0 ;;
    esac
  done
  return 1
}

# Bytes for one image id, or 0 if it cannot be read.
image_bytes() {
  local b
  b="$(docker image inspect --format '{{.Size}}' "$1" 2>/dev/null || echo 0)"
  printf '%s' "${b:-0}" | tr -dc '0-9'
}

# --- inventory ----------------------------------------------------------------------------------

do_inventory() {
  require_docker

  local before_avail; before_avail="$(avail_gb)"

  echo "🧮 Spike 03 - docker image headroom inventory"
  rule
  echo "  host:      $(hostname)"
  echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "  floor:     ${FLOOR_GB} GiB free on / (OD-1)"
  echo "  out dir:   $OUT_DIR"
  echo "  reap list: $REAP_LIST"
  echo -e "  mode:      ${BLUE}inventory (read-only)${NC}"
  echo ""

  echo "💾 1. Root filesystem (holds /var/lib/docker)"
  rule
  df -h / | sed 's/^/  /'
  echo ""
  if [ -z "$before_avail" ]; then
    warn "could not read available GiB from df - UNKNOWN, not healthy"
  elif [ "$before_avail" -lt "$FLOOR_GB" ]; then
    warn "${before_avail} GiB free is BELOW the ${FLOOR_GB} GiB floor - this is what the phase is gated on"
  else
    pass "${before_avail} GiB free is at or above the ${FLOOR_GB} GiB floor"
  fi
  echo ""

  echo "🐳 2. docker system df (verbatim)"
  rule
  docker system df 2>&1 | sed 's/^/  /' || true
  echo ""

  echo "🔒 3. Referenced-image set (docker ps -a, UNFILTERED - see T-03-01)"
  rule
  local refs; refs="$(referenced_set)"
  local container_count; container_count="$(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -c . || true)"
  local ref_count; ref_count="$(printf '%s\n' "$refs" | grep -c . || true)"
  info "containers seen (any state, including 'created'): ${container_count}"
  info "distinct protected tokens (tags + resolved ids + parents): ${ref_count}"
  echo ""

  echo "📦 4. Present images vs referenced set"
  rule
  mkdir -p "$OUT_DIR"

  local present_count=0 candidate_count=0 kept_count=0 total_bytes=0
  local tmp_list="${REAP_LIST}.building"
  : > "$tmp_list"

  local line name id size bytes
  while IFS=$'\t' read -r name id size; do
    [ -z "${name:-}" ] && continue
    present_count=$((present_count + 1))

    # Protected if the container-facing name matches, or the short id matches, or it is allow-listed.
    if printf '%s\n' "$refs" | grep -qxF "$name" \
       || printf '%s\n' "$refs" | grep -qxF "$id" \
       || is_kept "$name"; then
      kept_count=$((kept_count + 1))
      continue
    fi

    bytes="$(image_bytes "$id")"
    total_bytes=$((total_bytes + ${bytes:-0}))
    candidate_count=$((candidate_count + 1))
    printf '%s\t%s\t%s\n' "$name" "$id" "$size" >> "$tmp_list"
  done < <(docker images --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}' 2>/dev/null || true)

  mv "$tmp_list" "$REAP_LIST"

  if [ "$candidate_count" -eq 0 ]; then
    info "no reap candidates - every present image is referenced or allow-listed"
  else
    echo "  REPOSITORY:TAG                                        ID             SIZE"
    while IFS=$'\t' read -r name id size; do
      [ -z "${name:-}" ] && continue
      printf '  %-52s %-14s %s\n' "$name" "$id" "$size"
    done < "$REAP_LIST"
  fi
  echo ""

  local reclaim_gb="0"
  if [ "$total_bytes" -gt 0 ]; then
    reclaim_gb="$(awk -v b="$total_bytes" 'BEGIN{printf "%.1f", b/1073741824}')"
  fi

  echo "📊 5. Summary"
  rule
  echo "  root filesystem avail:                 ${before_avail:-unknown} GiB   (floor ${FLOOR_GB} GiB)"
  echo "  containers seen (docker ps -a, unfiltered): ${container_count}"
  echo "  images present:                        ${present_count}"
  echo "  images protected (referenced or allow-listed): ${kept_count}"
  echo "  reap candidates:                       ${candidate_count}"
  echo "  reclaimable:                           ${reclaim_gb} GiB   (UPPER BOUND - shared layers counted per image)"
  echo "  reap list written to:                  ${REAP_LIST}"
  echo ""
  warn "NOTHING HAS BEEN DELETED. An operator must approve $REAP_LIST before 'prune' will act."
  warn "Images for a stack currently 'compose down'd are NOT protected by docker ps -a and WILL be"
  warn "listed above - see KNOWN COLLATERAL in --help. Cross-check against stacks/selfhosted/**."
  echo ""
  # inventory reports, it does not assert.
  return 0
}

# --- prune --------------------------------------------------------------------------------------

do_prune() {
  # Refusal, not a fallback. Checked FIRST, before docker is even required, so the refusal is
  # reachable and testable anywhere - including on a workstation with no docker at all.
  if [ ! -f "$REAP_LIST" ]; then
    echo "❌ reap list not found: $REAP_LIST" >&2
    echo "   Run 'bash scripts/spike03-image-headroom.sh inventory' first, then have the list" >&2
    echo "   approved by the operator. Refusing to guess what may be deleted." >&2
    exit 2
  fi

  require_docker

  local before_avail; before_avail="$(avail_gb)"

  # The banner deliberately says "reap", not the p-word. The acceptance check for this script is
  # `grep -v '^\s*#' ... | grep -c 'docker image prune'` returning 0, and a BANNER STRING would
  # satisfy that grep just as well as a real call would. That is Pitfall 7 (03-PATTERNS.md
  # § "Acceptance criteria must parse, not grep") pointing the other way: here the risk is not a
  # comment producing a false positive, it is echoed prose producing one. Keep it out of the code.
  echo "🧨 Spike 03 - docker image reap (APPROVED LIST ONLY)"
  rule
  echo "  host:      $(hostname)"
  echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "  floor:     ${FLOOR_GB} GiB free on / (OD-1)"
  echo "  reap list: $REAP_LIST"
  echo -e "  mode:      ${RED}prune (MUTATES LIVE STATE)${NC}"
  echo ""
  echo "  avail before: ${before_avail:-unknown} GiB"
  echo ""

  echo "🔒 1. Re-deriving the referenced set and re-checking every listed row"
  rule
  # A container may have been created between approval and now. The list is re-validated against a
  # FRESHLY derived referenced set immediately before anything is deleted - the approval says which
  # images the operator is willing to lose, not that they are still unreferenced.
  local refs; refs="$(referenced_set)"
  local conflicts=0 listed=0
  local name id size
  while IFS=$'\t' read -r name id size; do
    [ -z "${name:-}" ] && continue
    listed=$((listed + 1))
    if printf '%s\n' "$refs" | grep -qxF "$name" || printf '%s\n' "$refs" | grep -qxF "$id"; then
      fail "$name ($id) is NOW referenced by a container - it was not when the list was made"
      conflicts=$((conflicts + 1))
    fi
  done < "$REAP_LIST"

  if [ "$conflicts" -gt 0 ]; then
    echo ""
    fail "aborting: ${conflicts} listed image(s) became referenced after approval. Nothing deleted."
    fail "Re-run 'inventory' to regenerate the list and have it re-approved."
    exit 1
  fi
  pass "all ${listed} listed image(s) are still unreferenced"
  echo ""

  echo "🗑  2. Deleting by image ID, one at a time"
  rule
  local removed=0 already=0 errors=0
  while IFS=$'\t' read -r name id size; do
    [ -z "${name:-}" ] && continue
    if ! docker image inspect "$id" >/dev/null 2>&1; then
      info "already reclaimed: $name ($id)"
      already=$((already + 1))
      continue
    fi
    # DELETE BY TAG WHEN THERE IS A TAG, BY ID ONLY WHEN THERE IS NOT.
    #
    # 03-01 task 1 says "docker rmi each approved line by image ID". Taken literally that is broken
    # for multi-tagged images, and this estate has one in the candidate list: the live inventory on
    # 2026-09-01 listed BOTH ghcr.io/advplyr/audiobookshelf:2.35.1 AND :latest, and they are the
    # same image a7befa7704bd. `docker rmi a7befa7704bd` refuses with "image is referenced in
    # multiple repositories" and would have to be forced. Removing by TAG untags cleanly, and the
    # image itself is deleted when its last tag goes - so the two approved rows do exactly the
    # right thing in sequence, with no -f anywhere.
    #
    # The safety property is unchanged: the target still comes from the approved file and nothing
    # else, and the presence/idempotence check above is still done by ID.
    local target="$id"
    case "$name" in
      ""|"<none>:<none>"|*"<none>"*) target="$id" ;;
      *)                             target="$name" ;;
    esac

    if docker rmi "$target" >/dev/null 2>&1; then
      pass "removed $name ($id, $size)"
      removed=$((removed + 1))
    else
      # Collect rather than abort: one image held by something unexpected must not strand the rest.
      fail "docker rmi failed for $name ($id) - left in place"
      errors=$((errors + 1))
    fi
  done < "$REAP_LIST"
  echo ""

  echo "💾 3. Root filesystem after"
  rule
  df -h / | sed 's/^/  /'
  local after_avail; after_avail="$(avail_gb)"
  echo ""

  local delta="unknown"
  if [ -n "$before_avail" ] && [ -n "$after_avail" ]; then
    delta="$((after_avail - before_avail))"
  fi

  echo "📊 4. Summary"
  rule
  echo "  listed for reap:      ${listed}"
  echo "  removed this run:     ${removed}"
  echo "  already reclaimed:    ${already}"
  echo "  rmi failures:         ${errors}   (target 0)"
  echo "  avail before:         ${before_avail:-unknown} GiB"
  echo "  avail after:          ${after_avail:-unknown} GiB   (floor ${FLOOR_GB} GiB)"
  echo "  delta:                ${delta} GiB"
  echo ""

  if [ -z "$after_avail" ]; then
    fail "could not read available GiB after prune - the floor is UNKNOWN, not met"
  elif [ "$after_avail" -lt "$FLOOR_GB" ]; then
    fail "${after_avail} GiB free is BELOW the ${FLOOR_GB} GiB floor (OD-1) - do NOT pull; the phase stops here"
  else
    pass "${after_avail} GiB free meets the ${FLOOR_GB} GiB floor (OD-1)"
  fi

  if [ "$FAILURES" -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ $FAILURES failed check(s)${NC}"
    exit 1
  fi
  echo ""
  echo -e "${GREEN}✅ headroom cleared - ${after_avail} GiB free, floor ${FLOOR_GB} GiB${NC}"
  return 0
}

case "$ACTION" in
  inventory) do_inventory ;;
  prune)     do_prune ;;
  *)         usage ;;
esac
