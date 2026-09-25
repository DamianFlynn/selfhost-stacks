#!/usr/bin/env bash
# check-music-import.sh - Criterion 7's post-import detection sweep over what beets imported.
# Usage: bash scripts/check-music-import.sh [--self-test]
#
# What it is for:
#   Phase 7 criterion 7 / IMPT-02 / D-25. After an import, three classes of damage must be ZERO,
#   and until this file existed nothing in the repository looked for any of them. It is a
#   STANDING script, not a phase-local one, because Phase 9 criterion 2 runs it after every batch
#   — and this estate's record on "promote it later" is that the item acquires no owner.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks. scripts/quick-health-check.sh folds it
#   in over ssh (IMPORT_SWEEP_SCRIPT). `--self-test` needs only bash and jq and runs anywhere.
#
# READ-ONLY BY CONTRACT, AND NOT A D-04 INVOCATION:
#   Classes 2 and 3 are defined on beets' own view of the library, so they are read from beets'
#   own /config/library.db — opened READ-ONLY through Python's sqlite3 with the URI
#   `file:/config/library.db?mode=ro`, inside the beets-flask container, by ONE bounded
#   `docker exec beets-flask /venv/bin/python -c <program> <db path>`. The program crosses as
#   argv to python and the database path as a positional argument; nothing is interpolated into
#   a shell inside the container (its /bin/sh is dash, and there is no pipeline there at all).
#   There is NO `beet` invocation in this file — a `beet ls` against the real library would be a
#   D-04 invocation needing registration (D-27) — and no SQL statement that writes. The sweep's
#   filesystem reads are `os.path.exists` and a one-level `os.scandir` of each directory that
#   holds an item: stat and readdir, nothing else.
#
#   Scope is the ITEMS BEETS IMPORTED, not the 1,244-file legacy tree (most of which no beets ever
#   tagged). File-level tag truth (criterion 3) is a separate instrument (plans 07-10 / 07-17).
#
# The three classes (each a FINDING, each exit 1):
#   Class 1  `.N`-SUFFIX PATH COLLISION. beets appends `.1`, `.2` … before the extension when a
#            destination is already taken. The predicate is phase06-oracle.sh
#            assert_no_collision_suffix's, `\.[0-9]+\.[^./]+$` on the BASENAME, STRENGTHENED by a
#            sibling test: it is a collision only when the suffix-stripped name ALSO EXISTS ON
#            DISK in the same directory. Enumerated over the DB's item rows AND over the
#            filesystem — every audio file in a directory holding a beets item is listed, so an
#            orphaned `Title.1.flac` with no item row beside `Title.flac` is a finding too (G-03).
#            The DB alone never enumerates a file beets has no row for.
#   Class 2  EMPTY mb_albumid on an album item (album_id NOT NULL) whose album is not `dj`.
#   Class 3  TRACK COUNT vs tracktotal, per (album_id, disc) — per disc because the vendored
#            config sets `per_disc_numbering: yes`. If the group's non-zero tracktotal values
#            DISAGREE it is a finding on its own: NEVER first-wins, which is the trap
#            phase05-now-tag-inventory.sh records ("a single intruder's tracktotal sets the
#            expectation"). If they agree and the item count differs, it is a finding.
#
# The named NON-FAILURE lines. Each is COUNTED AND PRINTED, never silent (CONVENTIONS §1) — none
# of them is a skip, because each is a measured property of the library with its own reason:
#   suffix-shaped, no sibling  a `.N.ext` name whose stripped name is NOT on disk — the
#                              characterised near-miss (`Symphony Op.64.flac`, DEF-06-45-04). A
#                              real title can end in `.<digits>`; with no sibling nothing collided.
#                              Printed WITH PATHS so a human can read each one.
#   on-disk, no item row       an audio file beside imported items that beets has no row for.
#                              Printed with its path; a finding only if it is a class-1 collision.
#   DJ as-is exception         D-08: DJ releases may be imported as-is with no MusicBrainz id.
#   singletons                 album_id NULL; singletons have no album and so no album id.
#   uncheckable album-discs    no non-zero tracktotal on any item — class 3 cannot judge it.
#
# EXIT CODES:
#   0  clean AND non-vacuous: every class had rows to check, and none held a finding.
#   1  a finding in any class — or a knob override in effect (see below).
#   2  usage error.
#   3  UNKNOWN: could not look (container down, DB unreadable, dump truncated, directory
#      unreadable, bound exceeded, toolchain missing) OR VACUOUS — an empty library, or ANY class
#      with zero checkable rows. The vacuity guard is PER CLASS (G-03): a library of only
#      singletons has zero checkable rows in classes 2 and 3 and is UNKNOWN, never clean. A zero
#      here means "nothing was checked", not "nothing is wrong".
#   PRECEDENCE: 3 outranks 1. A run that could not look at everything cannot certify anything,
#   and a finding printed beside an UNKNOWN is still printed — it just does not decide the exit.
#   Until the first pilot import the real library holds 0 items, so a live run is exit 3 by
#   design: the vacuity guard working, not a fault.
#
# KNOBS (additive only, CONVENTIONS §4 — an override may only ever make this check redder):
#   IMPORT_SWEEP_CONTAINER  default beets-flask
#   IMPORT_SWEEP_DB         default /config/library.db
#   IMPORT_SWEEP_TIMEOUT    default 120 (seconds, applied Linux-side to the docker exec)
#   Any non-default value prints "override in effect — this run cannot report the sweep green"
#   and forces a non-zero exit. They exist so a red branch can be DRIVEN, never to silence one.
#
# --self-test:
#   Ten fixture cases (ST_PLANNED_CASES, pinned in CONVENTIONS §5), written as NDJSON dumps in
#   exactly the dumper's output shape and judged by the SAME judge function a live run uses —
#   every zero-expecting class is driven red first, and the near-miss is characterised. Plus an
#   UNCOUNTED dumper-level check, run only when a local python3 exists: it builds a tiny sqlite
#   file and a temp directory and runs the real dumper program against them, proving the SQL, the
#   BLOB decode and the orphan enumeration. Its skip is printed, never silent.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SELFTEST_MODE=0
for arg in "$@"; do
  case "$arg" in
    --self-test) SELFTEST_MODE=1 ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: bash scripts/check-music-import.sh [--self-test]" >&2
      exit 2
      ;;
  esac
done

IMPORT_SWEEP_CONTAINER_DEFAULT="beets-flask"
IMPORT_SWEEP_DB_DEFAULT="/config/library.db"
IMPORT_SWEEP_TIMEOUT_DEFAULT="120"
IMPORT_SWEEP_CONTAINER="${IMPORT_SWEEP_CONTAINER:-$IMPORT_SWEEP_CONTAINER_DEFAULT}"
IMPORT_SWEEP_DB="${IMPORT_SWEEP_DB:-$IMPORT_SWEEP_DB_DEFAULT}"
IMPORT_SWEEP_TIMEOUT="${IMPORT_SWEEP_TIMEOUT:-$IMPORT_SWEEP_TIMEOUT_DEFAULT}"
case "$IMPORT_SWEEP_TIMEOUT" in
  ''|*[!0-9]*|0) echo "IMPORT_SWEEP_TIMEOUT must be a positive integer (got '$IMPORT_SWEEP_TIMEOUT')" >&2; exit 2 ;;
esac

rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }

# The counters. UNKNOWN and FINDINGS are separate on purpose — "could not look" is never folded
# into "nothing is wrong", and neither is folded into the other (CONVENTIONS §1).
reset_counters() {
  UNKNOWN=0; UNKNOWN_REASONS=()
  FINDINGS=0; OVERRIDDEN=0
  J_ITEMS=0; J_ORPHANS=0
  J_C1=0; J_C2=0; J_C3=0
  J_DJ=0; J_SGL=0; J_SFXNOSIB=0; J_ONDISK=0; J_UNCHK=0
  J_CHK1=0; J_CHK2=0; J_CHK3=0
  J_SFXNOSIB_PATHS=(); J_ONDISK_PATHS=()
}
unknown() { echo -e "  ${YELLOW}⚠️  UNKNOWN: $*${NC}"; UNKNOWN=$((UNKNOWN + 1)); UNKNOWN_REASONS+=("$*"); }
finding() { echo -e "  ${RED}❌ $*${NC}"; FINDINGS=$((FINDINGS + 1)); }
reset_counters

# ---------------------------------------------------------------------------------------------
# THE DUMPER (remote half). Runs inside the container as `python -c "$DUMPER_PROG" <db>`.
# Output: one JSON object per item row, one per on-disk orphan (`"orphan": true`), one per
# directory it could not read (`"dir_error"`), and EXACTLY ONE trailer `{"end": true, …}` LAST,
# carrying its own item and orphan counts. The judge refuses a dump without that trailer, or
# whose counts disagree with the body, as UNKNOWN — so a killed or truncated dump can never be
# read as a smaller, cleaner library.
# The suffix regex here only decides WHICH names get a sibling stat; the judge re-applies the
# predicate itself and treats a suffix-shaped name with no boolean sibling result as UNKNOWN.
# ---------------------------------------------------------------------------------------------
DUMPER_PROG=$(cat <<'PY'
import json, os, re, sqlite3, sys, urllib.parse

db = sys.argv[1]
AUDIO_EXT = {"mp3", "wav", "flac", "m4a", "aiff", "aif", "wma", "ogg", "opus", "aac", "wv", "ape", "alac"}
SFX = re.compile(r"\.[0-9]+(\.[^./]+)$")

def dec(p):
    if p is None:
        return None
    if isinstance(p, (bytes, bytearray, memoryview)):
        return os.fsdecode(bytes(p))
    return str(p)

def sib(path):
    d, b = os.path.split(path)
    m = SFX.search(b)
    if not m:
        return False, None
    return True, os.path.exists(os.path.join(d, b[:m.start()] + m.group(1)))

def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=True, sort_keys=True) + "\n")

if not os.path.isfile(db):
    sys.stderr.write("database not found: %r\n" % db)
    sys.exit(4)
con = sqlite3.connect("file:" + urllib.parse.quote(db) + "?mode=ro", uri=True)
rows = con.execute(
    "SELECT i.id, i.path, i.album_id, i.mb_albumid, i.track, i.tracktotal, i.disc, i.disctotal,"
    " a.albumtype FROM items i LEFT JOIN albums a ON a.id = i.album_id ORDER BY i.id"
).fetchall()
con.close()

item_paths = set()
dirs = set()
n_items = 0
for (iid, path, album_id, mb, track, tt, disc, dt, albumtype) in rows:
    p = dec(path)
    shaped, exists = sib(p) if p else (False, None)
    out({"id": iid, "path": p, "album_id": album_id, "mb_albumid": mb, "track": track,
         "tracktotal": tt, "disc": disc, "disctotal": dt, "albumtype": albumtype,
         "suffix_shaped": shaped, "sibling_exists": exists, "orphan": False})
    n_items += 1
    if p:
        item_paths.add(p)
        dirs.add(os.path.dirname(p))

n_orphans = 0
for d in sorted(dirs):
    try:
        entries = sorted(os.scandir(d), key=lambda e: e.name)
    except OSError as exc:
        out({"dir_error": d, "error": "%s: %s" % (type(exc).__name__, exc)})
        continue
    for e in entries:
        try:
            if not e.is_file():
                continue
        except OSError as exc:
            out({"dir_error": e.path, "error": "%s: %s" % (type(exc).__name__, exc)})
            continue
        ext = e.name.rsplit(".", 1)[-1].lower() if "." in e.name else ""
        if ext not in AUDIO_EXT or e.path in item_paths:
            continue
        shaped, exists = sib(e.path)
        out({"id": None, "path": e.path, "orphan": True,
             "suffix_shaped": shaped, "sibling_exists": exists})
        n_orphans += 1

out({"end": True, "items": n_items, "orphans": n_orphans, "dirs": len(dirs)})
PY
)

# ---------------------------------------------------------------------------------------------
# THE JUDGE (local half, pure). jq over the whole dump, emitting one TAB-separated tagged line per
# fact. The class-1 predicate is assert_no_collision_suffix's regex, `\.[0-9]+\.[^./]+$`, on the
# basename (its output tag, COLLISION-SUFFIX, is the same too). Control characters in paths are
# replaced by `?` for display only.
# ---------------------------------------------------------------------------------------------
JUDGE_JQ=$(cat <<'JQ'
def disp: tostring | gsub("[\t\n\r]"; "?");
def base: (.path // "") | tostring | split("/") | last;
def shaped: base | test("\\.[0-9]+\\.[^./]+$");
def blank: (. == null) or ((tostring | test("^\\s*$")));
def isdj: ((.albumtype // "") | tostring | ascii_downcase) == "dj";
. as $all
| [ $all[] | select(type == "object" and .end == true) ] as $ends
| [ $all[] | select(type == "object" and .dir_error != null) ] as $direrrs
| [ $all[] | select(type == "object" and .end != true and .dir_error == null and .orphan != true) ] as $items
| [ $all[] | select(type == "object" and .orphan == true) ] as $orphans
| [ $all[] | select(type != "object") ] as $junk
| [ $items[] | select(.album_id != null) ] as $album_items
| ( $album_items | group_by([.album_id, .disc]) ) as $groups
| "ENDS\t\($ends | length)",
  "ENDLAST\t\(if ($all | length) > 0 and ($all[-1] | type) == "object" and $all[-1].end == true then 1 else 0 end)",
  "TRAILER\t\(($ends[0].items // -1))\t\(($ends[0].orphans // -1))",
  "ITEMS\t\($items | length)",
  "ORPHANS\t\($orphans | length)",
  "JUNK\t\($junk | length)",
  ( $direrrs[] | "DIRERR\t\(.dir_error | disp)\t\(.error | disp)" ),
  ( $items[] | select((.path | type) != "string" or .path == "") | "BADPATH\t\(.id | disp)" ),
  ( ($items + $orphans)[] | select((.path | type) == "string") | select(shaped) |
      if .sibling_exists == true then "COLLISION-SUFFIX\t\(.path | disp)\t\(if .orphan == true then "orphan" else "item" end)"
      elif .sibling_exists == false then "SFXNOSIB\t\(.path | disp)"
      else "SFXUNK\t\(.path | disp)" end ),
  ( $orphans[] | "ONDISK\t\(.path | disp)" ),
  ( $album_items[] | select(.mb_albumid | blank) |
      if isdj then "DJ\t\(.path | disp)" else "C2\t\(.path | disp)" end ),
  ( $items[] | select(.album_id == null) | select(.mb_albumid | blank) | "SGL\t\(.path | disp)" ),
  ( $groups[] | . as $g
      | ([ $g[] | .tracktotal | select(type == "number" and . > 0) ] | unique) as $tt
      | if ($tt | length) == 0 then "UNCHK\t\($g[0].album_id | disp)\t\($g[0].disc | disp)\t\($g | length)"
        elif ($tt | length) > 1 then "C3\t\($g[0].album_id | disp)\t\($g[0].disc | disp)\tTRACKTOTAL-DISAGREE\t\($g | length) items carry tracktotal values \($tt | map(tostring) | join(", ")) — never first-wins"
        elif ($g | length) != $tt[0] then "C3\t\($g[0].album_id | disp)\t\($g[0].disc | disp)\tTRACKTOTAL-COUNT\t\($g | length) items against tracktotal \($tt[0])"
        else empty end ),
  "CHK\t\(($items | length) + ($orphans | length))\t\([ $album_items[] | select(isdj | not) ] | length)\t\([ $groups[] | select([ .[] | .tracktotal | select(type == "number" and . > 0) ] | length > 0) ] | length)"
JQ
)

tagcount() { awk -F'\t' -v t="$1" '$1 == t { n++ } END { print n + 0 }' "$2"; }
tagfield() { awk -F'\t' -v t="$1" -v f="$2" '$1 == t { print $f; exit }' "$3"; }

# judge DUMP — sets the J_* counters, FINDINGS and UNKNOWN, and prints sections 2–4.
judge() {
  local dump="$1" tsv="$1.judged" line
  if ! jq -rs "$JUDGE_JQ" "$dump" > "$tsv" 2> "$tsv.err"; then
    unknown "the dump is not parseable NDJSON ($(head -c 200 "$tsv.err" | tr '\n' ' ')) — nothing was judged"
    return
  fi
  local ends endlast t_items t_orph junk badpath
  ends="$(tagfield ENDS 2 "$tsv")"; endlast="$(tagfield ENDLAST 2 "$tsv")"
  t_items="$(tagfield TRAILER 2 "$tsv")"; t_orph="$(tagfield TRAILER 3 "$tsv")"
  J_ITEMS="$(tagfield ITEMS 2 "$tsv")"; J_ORPHANS="$(tagfield ORPHANS 2 "$tsv")"
  junk="$(tagfield JUNK 2 "$tsv")"; badpath="$(tagcount BADPATH "$tsv")"

  echo "📊 1. Dump integrity"
  rule
  if [[ "$ends" != "1" || "$endlast" != "1" ]]; then
    unknown "the dump carries $ends trailer record(s) (want exactly 1, and last) — truncated or malformed, so a smaller library cannot be told from a partial read"
  elif [[ "$t_items" != "$J_ITEMS" || "$t_orph" != "$J_ORPHANS" ]]; then
    unknown "the trailer says $t_items items / $t_orph orphans but the body holds $J_ITEMS / $J_ORPHANS — the dump is incomplete"
  else
    pass "trailer present and consistent: $J_ITEMS item row(s), $J_ORPHANS on-disk orphan(s)"
  fi
  [[ "$junk" != "0" ]] && unknown "$junk dump record(s) are not JSON objects"
  [[ "$badpath" != "0" ]] && unknown "$badpath item row(s) carry no usable path — class 1 cannot judge them"
  while IFS=$'\t' read -r _ d e; do
    unknown "directory could not be enumerated for class 1: $d ($e)"
  done < <(awk -F'\t' '$1 == "DIRERR"' "$tsv")
  echo ""

  echo "📊 2. Class 1 — .N-suffix path collisions (DB rows AND on-disk files)"
  rule
  while IFS=$'\t' read -r _ p kind; do
    finding "COLLISION-SUFFIX ($kind): $p — the un-suffixed name also exists in the same directory"
  done < <(awk -F'\t' '$1 == "COLLISION-SUFFIX"' "$tsv")
  while IFS=$'\t' read -r _ p; do
    unknown "suffix-shaped name with no sibling result from the dumper: $p"
  done < <(awk -F'\t' '$1 == "SFXUNK"' "$tsv")
  J_C1="$(tagcount COLLISION-SUFFIX "$tsv")"
  J_SFXNOSIB="$(tagcount SFXNOSIB "$tsv")"; J_ONDISK="$(tagcount ONDISK "$tsv")"
  mapfile -t J_SFXNOSIB_PATHS < <(awk -F'\t' '$1 == "SFXNOSIB" { print $2 }' "$tsv")
  mapfile -t J_ONDISK_PATHS < <(awk -F'\t' '$1 == "ONDISK" { print $2 }' "$tsv")
  [[ "$J_C1" == "0" ]] && info "no collision-suffix names ($J_SFXNOSIB suffix-shaped with no sibling — listed in the summary)"
  echo ""

  echo "📊 3. Class 2 — empty mb_albumid on non-DJ album items"
  rule
  while IFS=$'\t' read -r _ p; do
    finding "EMPTY-MB-ALBUMID: $p — an album item with no MusicBrainz album id and albumtype not dj"
  done < <(awk -F'\t' '$1 == "C2"' "$tsv")
  J_C2="$(tagcount C2 "$tsv")"; J_DJ="$(tagcount DJ "$tsv")"; J_SGL="$(tagcount SGL "$tsv")"
  [[ "$J_C2" == "0" ]] && info "no empty mb_albumid on a non-DJ album item"
  echo ""

  echo "📊 4. Class 3 — track count vs tracktotal, per (album_id, disc)"
  rule
  while IFS=$'\t' read -r _ a d kind why; do
    finding "$kind: album_id $a disc $d — $why"
  done < <(awk -F'\t' '$1 == "C3"' "$tsv")
  J_C3="$(tagcount C3 "$tsv")"; J_UNCHK="$(tagcount UNCHK "$tsv")"
  [[ "$J_C3" == "0" ]] && info "no album-disc disagrees with its tracktotal"
  echo ""

  J_CHK1="$(tagfield CHK 2 "$tsv")"; J_CHK2="$(tagfield CHK 3 "$tsv")"; J_CHK3="$(tagfield CHK 4 "$tsv")"
  # THE VACUITY GUARD, PER CLASS (G-03). A class with nothing to check has not been checked.
  if [[ "$J_ITEMS" == "0" ]]; then
    unknown "the library holds 0 items — nothing was checked, so 0 findings means nothing (vacuous)"
  else
    [[ "$J_CHK1" == "0" ]] && unknown "class 1 (collision suffix) has 0 checkable rows — vacuous"
    [[ "$J_CHK2" == "0" ]] && unknown "class 2 (empty mb_albumid) has 0 checkable rows — no non-DJ album item exists (vacuous)"
    [[ "$J_CHK3" == "0" ]] && unknown "class 3 (tracktotal) has 0 checkable rows — no album-disc carries a non-zero tracktotal (vacuous)"
  fi
}

# report — section 5 and the exit ladder. Returns the exit code; never prints green above a gate.
report() {
  local p
  # ---------------------------------------------------------------------------------------------
  # 5. Summary
  #    KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT SILENTLY (CONVENTIONS §11). Its reader is
  #    scripts/quick-health-check.sh's "Music import sweep" block, which anchors on it with
  #    `sed -n '/^📊 5\. Summary/,$p'` and reports UNKNOWN if the anchor does not match. The labels
  #    below are chosen not to collide with the consumers fold-in's grep
  #    (`MA version|artist rows|FAILURES total`).
  # ---------------------------------------------------------------------------------------------
  echo "📊 5. Summary"
  rule
  echo "  items read:                  $J_ITEMS"
  echo "  collision findings:          $J_C1"
  echo "  empty mb_albumid findings:   $J_C2"
  echo "  tracktotal findings:         $J_C3"
  echo "  DJ as-is exception:          $J_DJ   (D-08: albumtype dj imported as-is — counted, not a failure)"
  echo "  singletons:                  $J_SGL   (album_id NULL, so no album id to carry — counted, not a failure)"
  echo "  suffix-shaped, no sibling:   $J_SFXNOSIB   (a .N.ext name with no un-suffixed sibling on disk — characterised near-miss, not a failure)"
  for p in "${J_SFXNOSIB_PATHS[@]}"; do echo "      $p"; done
  echo "  on-disk, no item row:        $J_ONDISK   (audio beside imported items that beets has no row for — a finding only as a class-1 collision)"
  for p in "${J_ONDISK_PATHS[@]}"; do echo "      $p"; done
  echo "  uncheckable album-discs:     $J_UNCHK   (no non-zero tracktotal — class 3 cannot judge them)"
  echo "  checkable rows per class:    class1=$J_CHK1 class2=$J_CHK2 class3=$J_CHK3   (any 0 is UNKNOWN, never clean)"
  for p in "${UNKNOWN_REASONS[@]}"; do echo "  UNKNOWN reason:              $p"; done
  echo "  UNKNOWN total:               $UNKNOWN"
  echo "  FINDINGS total:              $FINDINGS"
  echo ""

  # THE EXIT LADDER, IN THIS ORDER, AND THE ORDER IS LOAD-BEARING: UNKNOWN (3) outranks FINDINGS
  # (1), an override is never green (1), and the green line is last — reachable only when all
  # three are zero.
  if [[ $UNKNOWN -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  UNKNOWN: $UNKNOWN reason(s) — the sweep could not look, or found nothing to check. NOT clean. (findings: $FINDINGS)${NC}"
    return 3
  fi
  if [[ $FINDINGS -gt 0 ]]; then
    echo -e "${RED}❌ $FINDINGS criterion-7 finding(s)${NC}"
    return 1
  fi
  if [[ $OVERRIDDEN -eq 1 ]]; then
    echo -e "${RED}❌ override in effect — this run cannot report the sweep green${NC}"
    return 1
  fi
  echo -e "${GREEN}✅ Import sweep clean: $J_ITEMS items, three classes checked, zero findings${NC}"
  return 0
}

# ---------------------------------------------------------------------------------------------
# --self-test
# ---------------------------------------------------------------------------------------------
fx_item() { # file id path album_id mb_albumid tracktotal disc albumtype sibling_exists
  jq -nc --argjson id "$2" --arg path "$3" --argjson album_id "$4" --arg mb "$5" \
    --argjson tt "$6" --argjson disc "$7" --arg at "$8" --argjson sib "$9" \
    '{id: $id, path: $path, album_id: $album_id, mb_albumid: (if $mb == "" then null else $mb end),
      track: $id, tracktotal: $tt, disc: $disc, disctotal: 1,
      albumtype: (if $at == "" then null else $at end),
      suffix_shaped: ($path | split("/") | last | test("\\.[0-9]+\\.[^./]+$")),
      sibling_exists: $sib, orphan: false}' >> "$1"
}
fx_orphan() { # file path sibling_exists
  jq -nc --arg path "$2" --argjson sib "$3" \
    '{id: null, path: $path, orphan: true,
      suffix_shaped: ($path | split("/") | last | test("\\.[0-9]+\\.[^./]+$")), sibling_exists: $sib}' >> "$1"
}
fx_close() { # file — append the trailer the dumper would write
  local items orph
  items="$( { grep -c '"orphan":false' "$1" || true; } )"
  orph="$( { grep -c '"orphan":true' "$1" || true; } )"
  printf '{"dirs":1,"end":true,"items":%s,"orphans":%s}\n' "$items" "$orph" >> "$1"
}
fx_clean() { # file — two albums, tracktotal matching, mb_albumid set
  fx_item "$1" 1 /music/A/Alpha/01.flac 1 mbid-a 3 1 album null
  fx_item "$1" 2 /music/A/Alpha/02.flac 1 mbid-a 3 1 album null
  fx_item "$1" 3 /music/A/Alpha/03.flac 1 mbid-a 3 1 album null
  fx_item "$1" 4 /music/B/Beta/01.flac 2 mbid-b 2 1 album null
  fx_item "$1" 5 /music/B/Beta/02.flac 2 mbid-b 2 1 album null
}

run_self_test() {
  # ST_PLANNED_CASES is the ANNOUNCED count; st_cases is what actually ran. A mismatch is itself a
  # self-test failure (CONVENTIONS §5; check-beets-config.sh run_self_test is the pattern).
  local ST_PLANNED_CASES=10
  echo "🧪 --self-test — $ST_PLANNED_CASES fixture cases through the live judge, plus an uncounted dumper-level check"
  rule
  echo ""
  local st_failures=0 st_cases=0 st_red_cases=0
  local dir f out rc name want needle ok

  dir="$(mktemp -d "${PWD}/.check-music-import-selftest.XXXXXX")" || { echo -e "${RED}❌ --self-test: could not create a fixture directory under ${PWD}${NC}"; return 1; }

  # run_case NAME EXPECTED_EXIT FIXTURE [NEEDLE …] — a needle is `LABEL=>TEXT` (TEXT must appear
  # in the indented list under the LABEL line) or plain TEXT (must appear anywhere, grep -F).
  run_case() {
    name="$1"; want="$2"; f="$3"; shift 3
    out="$f.out"
    ( reset_counters; judge "$f"; report ) > "$out" 2>&1
    rc=$?
    st_cases=$((st_cases + 1))
    [[ $want -ne 0 ]] && st_red_cases=$((st_red_cases + 1))
    ok=1
    if [[ $rc -ne $want ]]; then
      echo -e "  ${RED}❌ case '$name': exit $rc, expected $want${NC}"; ok=0
    fi
    for needle in "$@"; do
      if [[ "$needle" == *'=>'* ]]; then
        if ! awk -v lab="${needle%%=>*}" -v txt="${needle#*=>}" '
              index($0, lab) == 3 { inlist = 1; next }
              inlist && /^      / { if (index($0, txt)) found = 1; next }
              { inlist = 0 }
              END { exit !found }' "$out"; then
          echo -e "  ${RED}❌ case '$name': '${needle#*=>}' not listed under '${needle%%=>*}'${NC}"; ok=0
        fi
      elif ! grep -qF -- "$needle" "$out"; then
        echo -e "  ${RED}❌ case '$name': output lacks '$needle'${NC}"; ok=0
      fi
    done
    if [[ $ok -eq 1 ]]; then
      echo -e "  ${GREEN}✅ case '$name': exit $rc, as expected${NC}"
    else
      st_failures=$((st_failures + 1))
      sed 's/^/        | /' "$out"
    fi
  }

  # 1. Clean: two albums, matching tracktotal, mb_albumid set.
  f="$dir/01.ndjson"; : > "$f"; fx_clean "$f"; fx_close "$f"
  run_case "clean fixture" 0 "$f" "FINDINGS total:              0" "UNKNOWN total:               0"

  # 2. Class 1: Title.1.mp3 beside an existing Title.mp3.
  f="$dir/02.ndjson"; : > "$f"; fx_clean "$f"
  fx_item "$f" 6 /music/C/Gamma/Title.mp3 3 mbid-c 2 1 album null
  fx_item "$f" 7 /music/C/Gamma/Title.1.mp3 3 mbid-c 2 1 album true
  fx_close "$f"
  run_case "Title.1.mp3 beside Title.mp3 (class 1)" 1 "$f" "COLLISION-SUFFIX (item): /music/C/Gamma/Title.1.mp3" "collision findings:          1"

  # 3. The characterised near-miss: Op.64 with no `Symphony Op.flac` sibling — NOT a failure.
  f="$dir/03.ndjson"; : > "$f"; fx_clean "$f"
  fx_item "$f" 6 "/music/D/Delta/Symphony Op.64.flac" 4 mbid-d 1 1 album false
  fx_close "$f"
  run_case "Symphony Op.64.flac, no sibling (near-miss)" 0 "$f" \
    "suffix-shaped, no sibling:=>/music/D/Delta/Symphony Op.64.flac" "collision findings:          0"

  # 4. Class 2: a non-DJ album item with an empty mb_albumid.
  f="$dir/04.ndjson"; : > "$f"; fx_clean "$f"
  fx_item "$f" 6 /music/E/Epsilon/01.flac 5 "" 1 1 album null
  fx_close "$f"
  run_case "non-DJ album item, empty mb_albumid (class 2)" 1 "$f" "EMPTY-MB-ALBUMID: /music/E/Epsilon/01.flac"

  # 5. D-08 DJ as-is exception and a singleton, both with empty mb_albumid — counted, not failed.
  f="$dir/05.ndjson"; : > "$f"; fx_clean "$f"
  fx_item "$f" 6 /music/DJ/Issue/01.mp3 6 "" 1 1 dj null
  fx_item "$f" 7 /music/Singles/Loose.mp3 null "" 0 null "" null
  fx_close "$f"
  run_case "DJ album + singleton, empty mb_albumid (not failures)" 0 "$f" \
    "DJ as-is exception:          1" "singletons:                  1"

  # 6. Class 3, both shapes: 9 items against tracktotal 10, AND an album-disc whose items carry two
  #    different tracktotal values. Exactly two findings, each with its own tag — a case that went
  #    red for one reason only would prove nothing about the other branch.
  f="$dir/06.ndjson"; : > "$f"; fx_clean "$f"
  for n in 1 2 3 4 5 6 7 8 9; do fx_item "$f" $((10 + n)) "/music/F/Phi/0$n.flac" 7 mbid-f 10 1 album null; done
  fx_item "$f" 30 /music/G/Gee/01.flac 8 mbid-g 2 1 album null
  fx_item "$f" 31 /music/G/Gee/02.flac 8 mbid-g 3 1 album null
  fx_close "$f"
  run_case "9 items vs tracktotal 10, and disagreeing totals (class 3)" 1 "$f" \
    "TRACKTOTAL-COUNT: album_id 7 disc 1 — 9 items against tracktotal 10" \
    "TRACKTOTAL-DISAGREE: album_id 8 disc 1" "tracktotal findings:         2"

  # 7. Empty item set — the dumper's shape for an empty library is the trailer alone.
  f="$dir/07.ndjson"; : > "$f"; fx_close "$f"
  run_case "empty library (vacuous)" 3 "$f" "the library holds 0 items" "items read:                  0"

  # 8. Every album-disc has tracktotal 0/NULL — class 3 has nothing to check.
  f="$dir/08.ndjson"; : > "$f"
  fx_item "$f" 1 /music/H/Eta/01.flac 1 mbid-h 0 1 album null
  fx_item "$f" 2 /music/H/Eta/02.flac 1 mbid-h null 1 album null
  fx_close "$f"
  run_case "every tracktotal 0/NULL (class 3 vacuous)" 3 "$f" "class 3 (tracktotal) has 0 checkable rows" "uncheckable album-discs:     1"

  # 9. Only singletons: classes 2 and 3 both have zero checkable rows — UNKNOWN, naming both (G-03).
  f="$dir/09.ndjson"; : > "$f"
  fx_item "$f" 1 /music/Singles/One.mp3 null "" 0 null "" null
  fx_item "$f" 2 /music/Singles/Two.mp3 null "" 0 null "" null
  fx_close "$f"
  run_case "all singletons (classes 2 and 3 vacuous)" 3 "$f" \
    "class 2 (empty mb_albumid) has 0 checkable rows" "class 3 (tracktotal) has 0 checkable rows"

  # 10. On-disk Title.1.flac with NO item row, beside an on-disk Title.flac that IS an item (G-03).
  f="$dir/10.ndjson"; : > "$f"; fx_clean "$f"
  fx_item "$f" 6 /music/I/Iota/Title.flac 9 mbid-i 1 1 album null
  fx_orphan "$f" /music/I/Iota/Title.1.flac true
  fx_close "$f"
  run_case "on-disk Title.1.flac with no item row (class 1, filesystem)" 1 "$f" \
    "COLLISION-SUFFIX (orphan): /music/I/Iota/Title.1.flac" "on-disk, no item row:=>/music/I/Iota/Title.1.flac"

  # UNCOUNTED: the dumper program itself, against a real sqlite file and a real directory. The
  # fixture database is built by CREATE TABLE … AS SELECT over VALUES (path as an X'' BLOB literal,
  # the shape beets stores), so this file contains no row-writing SQL at all. Its hash is taken
  # before and after, proving the dumper's mode=ro open left it untouched.
  echo ""
  if command -v python3 > /dev/null 2>&1; then
    local dd="$dir/dumper" dbf h0 h1 dout
    mkdir -p "$dd/lib" && : > "$dd/lib/Title.flac" && : > "$dd/lib/Title.1.flac"
    dbf="$dd/library.db"
    python3 - "$dbf" "$dd/lib/Title.flac" <<'PY'
import sqlite3, sys
db, p = sys.argv[1], sys.argv[2]
hx = p.encode().hex()
c = sqlite3.connect(db)
c.execute("CREATE TABLE albums AS SELECT 1 AS id, 'album' AS albumtype, 'mbid-x' AS mb_albumid")
c.execute("CREATE TABLE items AS SELECT 1 AS id, X'%s' AS path, 1 AS album_id, 'mbid-x' AS mb_albumid,"
          " 1 AS track, 1 AS tracktotal, 1 AS disc, 1 AS disctotal" % hx)
c.commit(); c.close()
PY
    h0="$(cksum < "$dbf")"
    dout="$dd/dump.ndjson"
    python3 -c "$DUMPER_PROG" "$dbf" > "$dout" 2> "$dout.err"
    rc=$?
    h1="$(cksum < "$dbf")"
    if [[ $rc -eq 0 && "$h0" == "$h1" ]] \
       && [[ "$(jq -s '[.[] | select(.orphan == true and .sibling_exists == true and (.path | endswith("/Title.1.flac")))] | length' "$dout")" == "1" ]] \
       && [[ "$(jq -s '[.[] | select(.orphan == false and (.path | endswith("/Title.flac")))] | length' "$dout")" == "1" ]] \
       && [[ "$(jq -s '[.[] | select(.end == true and .items == 1 and .orphans == 1)] | length' "$dout")" == "1" ]]; then
      echo -e "  ${GREEN}✅ dumper-level check (uncounted): BLOB path decoded, 1 item row, 1 orphan Title.1.flac with its sibling, DB unchanged${NC}"
    else
      echo -e "  ${RED}❌ dumper-level check (uncounted): rc=$rc, db unchanged=$([[ "$h0" == "$h1" ]] && echo yes || echo NO)${NC}"
      sed 's/^/        | /' "$dout" "$dout.err"
      st_failures=$((st_failures + 1))
    fi
  else
    echo -e "  ${YELLOW}⚠️  dumper-level check (uncounted): skipped: no python3 on this host — the judge was tested, the dumper program was not${NC}"
  fi

  # Fixture cleanup. The fence is AT THIS CALL SITE (CONVENTIONS §6): the target must be the
  # directory this function created, by basename pattern, under $PWD — or nothing is removed.
  case "$dir" in
    "${PWD}"/.check-music-import-selftest.??????)
      [[ -d "$dir" ]] && rm -rf -- "$dir" ;;
    *) echo -e "${RED}❌ REFUSED to remove '$dir': not a .check-music-import-selftest.XXXXXX directory under ${PWD}${NC}"; st_failures=$((st_failures + 1)) ;;
  esac

  echo ""
  rule
  if [[ $st_cases -ne $ST_PLANNED_CASES ]]; then
    echo -e "${RED}❌ --self-test: $st_cases cases ran but $ST_PLANNED_CASES were announced — the banner and the body disagree${NC}"
    return 1
  fi
  if [[ $st_failures -gt 0 ]]; then
    echo -e "${RED}❌ --self-test: $st_failures check(s) did not behave as expected${NC}"
    return 1
  fi
  echo -e "${GREEN}✅ --self-test: all $st_cases cases behaved as expected ($st_red_cases of them red by design)${NC}"
  return 0
}

if [[ $SELFTEST_MODE -eq 1 ]]; then
  if ! command -v jq > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  UNKNOWN: --self-test needs jq, which is not installed here${NC}"
    exit 3
  fi
  if run_self_test; then exit 0; else exit 1; fi
fi

# ---------------------------------------------------------------------------------------------
# LIVE RUN
# ---------------------------------------------------------------------------------------------
echo "🔎 Music import sweep — criterion 7 (IMPT-02, D-25) over ${IMPORT_SWEEP_CONTAINER}:${IMPORT_SWEEP_DB}"
rule
if [[ "$IMPORT_SWEEP_CONTAINER" != "$IMPORT_SWEEP_CONTAINER_DEFAULT" || "$IMPORT_SWEEP_DB" != "$IMPORT_SWEEP_DB_DEFAULT" || "$IMPORT_SWEEP_TIMEOUT" != "$IMPORT_SWEEP_TIMEOUT_DEFAULT" ]]; then
  OVERRIDDEN=1
  warn "override in effect — this run cannot report the sweep green (container=$IMPORT_SWEEP_CONTAINER db=$IMPORT_SWEEP_DB timeout=$IMPORT_SWEEP_TIMEOUT)"
fi

TOOLS_OK=1
for t in jq docker timeout; do
  if ! command -v "$t" > /dev/null 2>&1; then unknown "required tool '$t' is not installed here"; TOOLS_OK=0; fi
done

WORK=""
if [[ $TOOLS_OK -eq 1 ]]; then
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/.check-music-import-dump.XXXXXX")" || { unknown "could not create a scratch directory"; WORK=""; }
fi

if [[ -n "$WORK" ]]; then
  DUMP="$WORK/dump.ndjson"
  timeout "$IMPORT_SWEEP_TIMEOUT" docker exec "$IMPORT_SWEEP_CONTAINER" /venv/bin/python -c "$DUMPER_PROG" "$IMPORT_SWEEP_DB" > "$DUMP" 2> "$DUMP.err"
  DUMP_RC=$?
  # House S1 order: empty-not-124, then 124, then any other non-zero, and only then judge.
  if [[ ! -s "$DUMP" && $DUMP_RC -ne 124 ]]; then
    unknown "the dumper returned nothing (exit $DUMP_RC): $(head -c 300 "$DUMP.err" | tr '\n' ' ')"
  elif [[ $DUMP_RC -eq 124 ]]; then
    unknown "the dumper exceeded its ${IMPORT_SWEEP_TIMEOUT}s bound and was killed — most likely a wedged dockerd"
  elif [[ $DUMP_RC -ne 0 ]]; then
    unknown "the dumper failed (exit $DUMP_RC): $(head -c 300 "$DUMP.err" | tr '\n' ' ')"
  else
    judge "$DUMP"
  fi
  # Scratch cleanup, fenced at this call site (CONVENTIONS §6): only the directory created above.
  case "$WORK" in
    "${TMPDIR:-/tmp}"/.check-music-import-dump.??????) [[ -d "$WORK" ]] && rm -rf -- "$WORK" ;;
    *) warn "REFUSED to remove '$WORK': not a .check-music-import-dump.XXXXXX directory" ;;
  esac
fi

report
exit $?
