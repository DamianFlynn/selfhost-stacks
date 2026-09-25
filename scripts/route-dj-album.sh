#!/usr/bin/env bash
# route-dj-album.sh - D-08: route ONE imported album into the DJ/ tree of the real library.
# Usage: bash scripts/route-dj-album.sh --album-id N [--apply]
#
# What it is for:
#   Phase 7 E1 / D-08. The vendored beets config routes DJ content to a top-level `DJ/` sibling of
#   the artist tree through two `paths:` rules keyed on `albumtype:=dj` (rule 2 for
#   `disctotal:2..`, rule 3 otherwise; stacks/selfhosted/arrs/beets/config.yaml). Nothing in the
#   repository ever SET `albumtype=dj` on a real import: Phase 6 supplied it by hand in a scratch
#   overlay, and a hand-supplied field is not evidence the mechanism exists. This file is the
#   mechanism. Phase 9 routes DJ content in volume, so it lives in scripts/, where the D-04 scan in
#   scripts/quick-health-check.sh sees every beets call it makes.
#
# Why a POST-IMPORT modify + move, and not something at import time (one line each):
#   * global `import.set_fields: {albumtype: dj}` - rejected: it stamps EVERY import, bucket A too.
#   * per-inbox `set_fields` in flask-config.yaml - the "UNOWNED GAP" that file records; no owner.
#   * a beets hook / custom plugin - rejected: new Python in a pre-release app, in the very phase
#     that first grants the library `rw`.
#   The accepted consequence: BETWEEN THE IMPORT AND STEP (e) BELOW THE ALBUM SITS IN THE ARTIST
#   TREE. Callers must not trigger a Jellyfin library scan inside that window.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks. Every beets call is a bounded
#   `timeout 120 docker exec -u beetle beets-flask "$BEET_REALLIB" ...` with argv passed straight
#   to the binary - there is NO shell inside the container (its /bin/sh is dash, no pipefail) and
#   no pipeline there. The query is its own argv element.
#
# D-04 - WHICH beets MAY OPEN THE REAL LIBRARY:
#   Only beets-flask's own beets 2.12.0 opens the real /config/library.db. The 2.13.1 `beets`
#   container is NEVER used for this. So ROUTE_CONTAINER is a constant and NOT an env knob - a
#   wrong container is itself the D-04 violation - and every run first reads `--version` inside
#   the container and refuses (exit 3) anything that is not exactly 2.12.0.
#   BEET_REALLIB is /venv/bin/beet, not the bare name: measured 2026-09-26, `beet` is NOT on
#   PATH for user `beetle` in beets-flask (`command -v beet` prints nothing); /venv/bin/beet is
#   the path phase06-oracle.sh uses and reports `beets version 2.12.0`.
#
# D-27 - REGISTERED, NOT COMPLIANT:
#   A call that routes a real album cannot carry a throwaway `-l` + `-c` overlay; it must open the
#   real library. So every invocation line in this file carries the token `$BEET_REALLIB`, and
#   `D04_EXEMPT_RE` in quick-health-check.sh keys on this file's path AND that token. The reason
#   is recorded in full in that file's register comment (reason 4), and D04_EXEMPT_BASELINE
#   counts these lines. A beets call added here WITHOUT the token is asserted, and goes red.
#   Keep ONE invocation per line, and do not add new ones without moving that pin with a reason.
#
# MODES:
#   default (no --apply)  READ-ONLY. (1) version guard, (2) `ls -a` of the one album, (3) print
#                         which paths: rule it will reach once albumtype=dj is set. Writes nothing.
#   --apply               (a) repeat (1)+(2); (b) read `modify -h` and require `-M/--nomove` and
#                         `-y/--yes`; (c) album-level `modify -a -M -y id:N albumtype=dj` (every
#                         item inherits; `import.write: yes` means the field is written to the
#                         files too); (d) `move -a -p` and print every ` -> ` line; (e) `move -a`;
#                         (f) item-level `ls album_id:N` and assert every item reads albumtype dj
#                         and sits under /media/Music/DJ/. Stops at the first non-zero status.
#   Its first --apply is plan 07-13's, behind that plan's `autonomous: false` gate.
#
# QUERY KEYS: album-level calls (`-a`) query `id:N` - on an album the id field is `id`; `album_id`
#   is an ITEM field. The item-level read-back in (f) queries `album_id:N`.
#
# EXIT CODES (CONVENTIONS §1 - "could not look" is never "nothing is wrong"):
#   0  success (default: the album was read and its rule printed; --apply: routed and verified)
#   1  --apply: a writing step failed, or the post-condition in (f) failed
#   2  usage error
#   3  could not look, or refused: missing tool, timeout, non-zero read, wrong beets version,
#      not exactly one album, `modify -h` lacking a required flag
#
# No credential is used. No top-level `set -e`: every status is read and printed explicitly.

ROUTE_CONTAINER=beets-flask
readonly ROUTE_CONTAINER
ROUTE_USER=beetle
readonly ROUTE_USER
BEET_REALLIB=/venv/bin/beet
readonly BEET_REALLIB
ROUTE_TIMEOUT=120
readonly ROUTE_TIMEOUT
ROUTE_VERSION=2.12.0
readonly ROUTE_VERSION
LIB_DJ_PREFIX=/media/Music/DJ/
readonly LIB_DJ_PREFIX

usage() {
  echo "usage: route-dj-album.sh --album-id N [--apply]   (N: digits only)" >&2
  exit 2
}

ALBUM_ID=""
APPLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --album-id)
      [ "$#" -ge 2 ] || usage
      ALBUM_ID="$2"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    *)
      usage
      ;;
  esac
done
[[ "$ALBUM_ID" =~ ^[0-9]+$ ]] || usage

refuse() { # $1 = message; could-not-look / refusal
  echo "  ⚠️  UNKNOWN/REFUSED — $1" >&2
  exit 3
}

fail() { # $1 = message; a writing step or the post-condition failed
  echo "  ❌ $1" >&2
  exit 1
}

# House S1 order over a captured read: 124 first, then any non-zero, then empty.
OUT=""
RC=0
classify() { # $1 = what was being read
  echo "  rc=$RC  ($1)"
  if [ "$RC" -eq 124 ]; then
    refuse "$1 exceeded its ${ROUTE_TIMEOUT}s bound and was killed (most likely a wedged dockerd)."
  fi
  if [ "$RC" -ne 0 ]; then
    refuse "$1 failed (exit $RC)."
  fi
  if [ -z "$OUT" ]; then
    refuse "$1 came back empty. Nothing was read."
  fi
}

for tool in timeout docker; do
  command -v "$tool" > /dev/null 2>&1 || refuse "required tool '$tool' is not on PATH (this runs ON LXC 100)."
done

echo "route-dj-album: album id $ALBUM_ID, container $ROUTE_CONTAINER, mode $([ "$APPLY" -eq 1 ] && echo APPLY || echo read-only)"

# (1) Version guard - D-04: only flask's own 2.12.0 opens the real library.
RC=0
OUT="$(timeout "$ROUTE_TIMEOUT" docker exec -u "$ROUTE_USER" "$ROUTE_CONTAINER" "$BEET_REALLIB" --version)" || RC=$?
classify "the beets version inside $ROUTE_CONTAINER"
printf '%s\n' "$OUT" | sed 's/^/    /'
if ! printf '%s\n' "$OUT" | grep -qxF "beets version $ROUTE_VERSION"; then
  refuse "$ROUTE_CONTAINER does not report beets version $ROUTE_VERSION. D-04: no other beets may open the real library."
fi

# (2) The one album. `$id|$disctotal|$albumtype` come FIRST so a `|` inside an artist or album
#     name cannot shift the fields this script parses.
RC=0
# shellcheck disable=SC2016  # the \$fields are beets format tokens, deliberately unexpanded
OUT="$(timeout "$ROUTE_TIMEOUT" docker exec -u "$ROUTE_USER" "$ROUTE_CONTAINER" "$BEET_REALLIB" ls -a -f '$id|$disctotal|$albumtype|$albumartist|$album|$path' "id:$ALBUM_ID")" || RC=$?
classify "the album row for id:$ALBUM_ID"
N_LINES=$(printf '%s\n' "$OUT" | grep -c .)
if [ "$N_LINES" -ne 1 ]; then
  printf '%s\n' "$OUT" | sed 's/^/    /'
  refuse "expected exactly ONE album for id:$ALBUM_ID, read $N_LINES."
fi
echo "  album: $OUT"
IFS='|' read -r F_ID F_DISCTOTAL F_ALBUMTYPE _rest <<< "$OUT"
[ "$F_ID" = "$ALBUM_ID" ] || refuse "the row read back carries id '$F_ID', not $ALBUM_ID."

# (3) Which rule the album reaches once albumtype=dj is set.
if [[ "$F_DISCTOTAL" =~ ^[0-9]+$ ]] && [ "$F_DISCTOTAL" -ge 2 ]; then
  echo "  rule: paths: rule 2  'albumtype:=dj disctotal:2..' -> DJ/\$albumartist/\$album%aunique{}/\$disc-\$track \$title  (disctotal=$F_DISCTOTAL)"
else
  echo "  rule: paths: rule 3  'albumtype:=dj' -> DJ/\$albumartist/\$album%aunique{}/\$track \$title  (disctotal='$F_DISCTOTAL')"
fi
echo "  current albumtype: '$F_ALBUMTYPE'"

if [ "$APPLY" -ne 1 ]; then
  echo "  read-only: nothing written. Re-run with --apply to route (plan 07-13's gate)."
  exit 0
fi

# ------------------------------- --apply: every step below WRITES -------------------------------
echo "  APPLY: routing album $ALBUM_ID. The album is in the artist tree until step (e) completes -"
echo "  do NOT trigger a Jellyfin library scan until this script exits 0."

# (b) The flags this script relies on must exist in THIS beets, read rather than assumed.
RC=0
OUT="$(timeout "$ROUTE_TIMEOUT" docker exec -u "$ROUTE_USER" "$ROUTE_CONTAINER" "$BEET_REALLIB" modify -h)" || RC=$?
classify "the modify help text"
MISSING=""
printf '%s\n' "$OUT" | grep -qE -e '-M, --nomove' || MISSING="$MISSING -M/--nomove"
printf '%s\n' "$OUT" | grep -qE -e '-y, --yes' || MISSING="$MISSING -y/--yes"
[ -z "$MISSING" ] || refuse "modify -h in $ROUTE_CONTAINER does not offer:$MISSING. Nothing written."

# (c) Album-level field, move suppressed. Items inherit (no -I).
RC=0
timeout "$ROUTE_TIMEOUT" docker exec -u "$ROUTE_USER" "$ROUTE_CONTAINER" "$BEET_REALLIB" modify -a -M -y "id:$ALBUM_ID" albumtype=dj || RC=$?
echo "  rc=$RC  (step c: modify albumtype=dj, no move)"
[ "$RC" -eq 0 ] || fail "step (c) modify failed (exit $RC). The album may be PARTIALLY modified; nothing was moved."

# (d) Pretend move - show every planned rename.
RC=0
OUT="$(timeout "$ROUTE_TIMEOUT" docker exec -u "$ROUTE_USER" "$ROUTE_CONTAINER" "$BEET_REALLIB" move -a -p "id:$ALBUM_ID")" || RC=$?
echo "  rc=$RC  (step d: pretend move)"
[ "$RC" -eq 0 ] || fail "step (d) pretend move failed (exit $RC). albumtype=dj IS SET; the files are still in the artist tree."
N_ARROWS=$(printf '%s\n' "$OUT" | grep -cF ' -> ')
printf '%s\n' "$OUT" | grep -F ' -> ' | sed 's/^/    /'
echo "  planned renames: $N_ARROWS"

# (e) The move.
RC=0
timeout "$ROUTE_TIMEOUT" docker exec -u "$ROUTE_USER" "$ROUTE_CONTAINER" "$BEET_REALLIB" move -a "id:$ALBUM_ID" || RC=$?
echo "  rc=$RC  (step e: move)"
[ "$RC" -eq 0 ] || fail "step (e) move failed (exit $RC). albumtype=dj IS SET; some files may already have moved."

# (f) Post-condition, over ITEMS: every item dj, every path under the DJ/ tree.
RC=0
# shellcheck disable=SC2016  # the \$fields are beets format tokens, deliberately unexpanded
OUT="$(timeout "$ROUTE_TIMEOUT" docker exec -u "$ROUTE_USER" "$ROUTE_CONTAINER" "$BEET_REALLIB" ls -f '$albumtype|$path' "album_id:$ALBUM_ID")" || RC=$?
echo "  rc=$RC  (step f: item read-back)"
if [ "$RC" -eq 124 ]; then
  refuse "the item read-back exceeded its ${ROUTE_TIMEOUT}s bound AFTER the writes - the routing is UNVERIFIED."
fi
if [ "$RC" -ne 0 ]; then
  refuse "the item read-back failed (exit $RC) AFTER the writes - the routing is UNVERIFIED."
fi
N_ITEMS=$(printf '%s\n' "$OUT" | grep -c .)
# Anchored: the albumtype field must be exactly `dj` and the path must START with the DJ/ tree.
N_GOOD=$(printf '%s\n' "$OUT" | grep -c "^dj|$LIB_DJ_PREFIX")
N_BAD_PREFIX=$(printf '%s\n' "$OUT" | grep . | grep -vc "^dj|$LIB_DJ_PREFIX")
printf '%s\n' "$OUT" | sed 's/^/    /'
echo "  items: $N_ITEMS, routed: $N_GOOD, not routed: $N_BAD_PREFIX"
if [ "$N_ITEMS" -eq 0 ]; then
  fail "album_id:$ALBUM_ID has ZERO items after the move."
fi
if [ "$N_BAD_PREFIX" -ne 0 ] || [ "$N_GOOD" -ne "$N_ITEMS" ]; then
  fail "$N_BAD_PREFIX of $N_ITEMS items do not read albumtype dj under $LIB_DJ_PREFIX."
fi
echo "  ✅ album $ALBUM_ID routed: $N_ITEMS of $N_ITEMS items albumtype=dj under $LIB_DJ_PREFIX"
exit 0
