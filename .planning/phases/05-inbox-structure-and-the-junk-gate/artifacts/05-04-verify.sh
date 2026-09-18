#!/usr/bin/env bash
# verify-05-04.sh - assertions for plan 05-04, host-resident so the awk programs are not subject to
# three levels of shell quoting. An earlier attempt ran these inline through ssh and the tab field
# separator did not survive: NF==6 and NF==7 both returned 0 and "malformed" returned 44 on a file
# that was demonstrably correct. A mangled instrument reporting a clean-looking number is exactly
# the failure this estate keeps paying for, so the assertions live in a file.
#
#   bash verify-05-04.sh list    - assert the shape of the AMENDED approved list
#   bash verify-05-04.sh estate  - assert the post-sweep state of the estate
#
# Exit 0 only if every assertion holds.

set -uo pipefail

P=/mnt/fast/safety/phase05
LIST="$P/junk-candidates.tsv"
ASREAD="$P/junk-candidates-as-read-52row.tsv"
NZB=/mnt/tank/downloads/complete/nzb
INBOX="$NZB/_inbox"
Q="$INBOX/99-quarantine"
REVIEW="$INBOX/02-review"
NOW="$NZB/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023"

FAILS=0
ok()  { echo "  PASS  $*"; }
bad() { echo "  FAIL  $*"; FAILS=$((FAILS + 1)); }
eq()  { if [ "$2" = "$3" ]; then ok "$1 = $3"; else bad "$1: expected '$2', got '$3'"; fi; }

COVERS=(
  "$NZB/dj-mixes/VA - Mastermix Issue 441-WEB-2023-MST/.covers"
  "$NZB/dj-mixes/VA-Mastermix.Issue.439-WEB-2022-MS/.covers"
  "$NZB/dj-mixes/VA-Mastermix.Issue.443-WEB-2023-MST/.covers"
  "$NZB/dj-mixes/VA-Mastermix.Issue.444-WEB-2023-MST/.covers"
  "$NZB/unsorted/VA - Mastermix Issue 441-WEB-2023-MST/.covers"
  "$NZB/unsorted/VA-Mastermix.Issue.439-WEB-2022-MS/.covers"
  "$NZB/unsorted/VA-Mastermix.Issue.443-WEB-2023-MST/.covers"
  "$NZB/unsorted/VA-Mastermix.Issue.444-WEB-2023-MST/.covers"
)

GARTH=(
  "_FAILED_Garth.Brooks-Ropin.The.Wind-CDP.7.06330-2-CD-FLAC-1991-EMG"
  "_FAILED_Garth.Brooks-The.Ultimate.Hits-2CD-FLAC-2007-WRS"
)

do_list() {
  echo "== amended approved list: $LIST"
  echo "   sha256: $(sha256sum "$LIST" | awk '{print $1}')"
  echo "   as-read sha256: $(sha256sum "$ASREAD" | awk '{print $1}')"
  echo ""
  eq "total rows"                     "44" "$(wc -l < "$LIST" | tr -dc '0-9')"
  eq "as-read rows"                   "52" "$(wc -l < "$ASREAD" | tr -dc '0-9')"
  eq "rows with NO destination (remove)" "40" "$(awk -F'\t' 'NF==6' "$LIST" | wc -l | tr -dc '0-9')"
  eq "rows WITH a destination (move)"  "4" "$(awk -F'\t' 'NF==7' "$LIST" | wc -l | tr -dc '0-9')"
  eq "malformed rows"                  "0" "$(awk -F'\t' 'NF<6||NF>7{b++;next}{for(i=1;i<=NF;i++) if($i==""){b++;next}} END{print b+0}' "$LIST")"
  eq ".covers rows surviving"          "0" "$(awk -F'\t' '$2 ~ /\/\.covers$/' "$LIST" | wc -l | tr -dc '0-9')"
  eq ".covers rows in the as-read list" "8" "$(awk -F'\t' '$2 ~ /\/\.covers$/' "$ASREAD" | wc -l | tr -dc '0-9')"
  eq "R1 rows bound for 99-quarantine"  "2" "$(awk -F'\t' '$1=="R1" && $7=="99-quarantine"' "$LIST" | wc -l | tr -dc '0-9')"
  eq "R8 rows bound for _inbox/02-review" "2" "$(awk -F'\t' '$1=="R8" && $7=="_inbox/02-review"' "$LIST" | wc -l | tr -dc '0-9')"
  eq "R1 rows"  "2" "$(awk -F'\t' '$1=="R1"' "$LIST" | wc -l | tr -dc '0-9')"
  eq "R2 rows"  "2" "$(awk -F'\t' '$1=="R2"' "$LIST" | wc -l | tr -dc '0-9')"
  eq "R4 rows" "29" "$(awk -F'\t' '$1=="R4"' "$LIST" | wc -l | tr -dc '0-9')"
  eq "R6 rows"  "9" "$(awk -F'\t' '$1=="R6"' "$LIST" | wc -l | tr -dc '0-9')"
  eq "R8 rows"  "2" "$(awk -F'\t' '$1=="R8"' "$LIST" | wc -l | tr -dc '0-9')"
  eq "rows under incomplete/"     "0" "$(awk -F'\t' '$2 ~ /^\/mnt\/tank\/downloads\/incomplete/' "$LIST" | wc -l | tr -dc '0-9')"
  eq "rows under /mnt/tank/media" "0" "$(awk -F'\t' '$2 ~ /^\/mnt\/tank\/media/' "$LIST" | wc -l | tr -dc '0-9')"
  eq "rows outside the five scope roots" "0" "$(awk -F'\t' '$2 !~ /^\/mnt\/tank\/downloads\/complete\/nzb\/(music|unsorted|dj-mixes|_inbox)\// && $2 !~ /^\/mnt\/tank\/downloads\/lidarr-import\//' "$LIST" | wc -l | tr -dc '0-9')"
  # every surviving row must be a line that existed VERBATIM in the as-read file, modulo the two
  # R1 rows that gained a destination. Nothing may be invented, retyped or widened.
  eq "surviving rows absent from the as-read list" "2" \
     "$(comm -23 <(sort "$LIST") <(sort "$ASREAD") | wc -l | tr -dc '0-9')"
  eq "  ... and both of those are the two R1 rows" "2" \
     "$(comm -23 <(sort "$LIST") <(sort "$ASREAD") | awk -F'\t' '$1=="R1" && $7=="99-quarantine"' | wc -l | tr -dc '0-9')"
  echo ""
  echo "== the 4 move-only rows =="
  awk -F'\t' 'NF==7 {print "   " $1 "  " $2 "  ->  " $7}' "$LIST"
}

do_estate() {
  echo "== ROADMAP criterion 2 as amended, across the five music paths =="
  local roots=( "$NZB/music" "$NZB/unsorted" "$NZB/dj-mixes" "$INBOX/01-auto" "$INBOX/02-review" "$INBOX/03-asis" "$INBOX/04-hold" "$INBOX/_done" )
  [ -d /mnt/tank/downloads/lidarr-import ] && roots+=( /mnt/tank/downloads/lidarr-import )
  eq "_FAILED_ / _UNPACK_ directories outside 99-quarantine" "0" \
     "$(find -P "${roots[@]}" -type d \( -name '_FAILED_*' -o -name '_UNPACK_*' \) -print 2>/dev/null | wc -l | tr -dc '0-9')"
  eq "stray archive FILES outside 99-quarantine" "0" \
     "$(find -P "${roots[@]}" -type f \( -iname '*.rar' -o -iname '*.r[0-9][0-9]' -o -iname '*.part[0-9]*.rar' \) -print 2>/dev/null | wc -l | tr -dc '0-9')"

  echo ""
  echo "== named items the criterion calls out =="
  [ ! -e "$NZB/unsorted/Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE" ] \
    && ok "the Potter directory is gone from unsorted/" || bad "the Potter directory is STILL PRESENT"
  [ ! -e "$NZB/dj-mixes/VA-Now_That.s_What_I_Call_Music__1-115_2023" ] \
    && ok "the empty dj-mixes decoy is gone" || bad "the dj-mixes decoy is STILL PRESENT"

  echo ""
  echo "== every REMOVE row (no destination) must be absent =="
  local gone=0 still=0 p
  while IFS=$'\t' read -r r p rest; do
    if [ -e "$p" ]; then bad "remove row still present: $p"; still=$((still + 1)); else gone=$((gone + 1)); fi
  done < <(awk -F'\t' 'NF==6 {print}' "$LIST")
  eq "remove rows absent" "40" "$gone"
  eq "remove rows still present" "0" "$still"

  echo ""
  echo "== every MOVE row must be absent from its origin and present at its destination =="
  local g
  for g in "${GARTH[@]}"; do
    [ ! -e "$NZB/music/$g" ] && ok "origin gone: music/$g" || bad "origin STILL PRESENT: music/$g"
    [ -d "$Q/$g" ] && ok "landed: 99-quarantine/$g" || bad "NOT at 99-quarantine: $g"
  done
  eq "Garth Ropin audio files at 99-quarantine" "10" "$(find -P "$Q/${GARTH[0]}" -type f -iname '*.flac' 2>/dev/null | wc -l | tr -dc '0-9')"
  eq "Garth Ultimate Hits audio files at 99-quarantine" "34" "$(find -P "$Q/${GARTH[1]}" -type f -iname '*.flac' 2>/dev/null | wc -l | tr -dc '0-9')"
  [ ! -e /mnt/tank/downloads/lidarr-import/Madonna ] && ok "origin gone: lidarr-import/Madonna" || bad "lidarr-import/Madonna STILL PRESENT"
  [ ! -e "/mnt/tank/downloads/lidarr-import/Michael Jackson" ] && ok "origin gone: lidarr-import/Michael Jackson" || bad "lidarr-import/Michael Jackson STILL PRESENT"
  [ -d "$REVIEW/Madonna" ] && ok "landed: 02-review/Madonna" || bad "NOT at 02-review: Madonna"
  [ -d "$REVIEW/Michael Jackson" ] && ok "landed: 02-review/Michael Jackson" || bad "NOT at 02-review: Michael Jackson"
  eq "Madonna audio files at 02-review" "60" "$(find -P "$REVIEW/Madonna" -type f \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.wav' \) 2>/dev/null | wc -l | tr -dc '0-9')"
  eq "Michael Jackson audio files at 02-review" "473" "$(find -P "$REVIEW/Michael Jackson" -type f \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.wav' \) 2>/dev/null | wc -l | tr -dc '0-9')"

  echo ""
  echo "== the 8 EXCLUDED .covers directories must all still exist, with their contents =="
  local c present=0
  for c in "${COVERS[@]}"; do
    if [ -d "$c" ] && [ "$(find -P "$c" -type f | wc -l | tr -dc '0-9')" -ge 1 ]; then
      present=$((present + 1))
    else
      bad "EXCLUDED .covers row was affected: $c"
    fi
  done
  eq "excluded .covers directories intact" "8" "$present"

  echo ""
  echo "== the five value-bearing KEEP sidecars, by (devid,inode) =="
  # Captured immediately before the sweep - 05-03 did not persist these values, so the baseline is
  # this plan's own pre-sweep read, recorded in the summary.
  local want="68 1351 00.Now That's What I Call Music! 1-115(2023).m3u
68 18768 back.bmp
68 18769 cd1.bmp
68 18770 cd2.bmp
68 19960 NOW That’s What I Call Music! 115.cue"
  local got
  got="$(find -P "$NOW" -maxdepth 1 -type f \( -name "00.Now*1-115(2023).m3u" -o -name 'back.bmp' -o -name 'cd1.bmp' -o -name 'cd2.bmp' -o -name '*115.cue' \) -printf '%D %i %f\n' 2>/dev/null | sort -n -k2)"
  if [ "$(printf '%s' "$want" | sort -n -k2)" = "$got" ]; then
    ok "all five sidecars present with unchanged (devid,inode)"
  else
    bad "sidecar (devid,inode) set changed"
    echo "    want:"; printf '%s\n' "$want" | sed 's/^/      /'
    echo "    got:";  printf '%s\n' "$got"  | sed 's/^/      /'
  fi

  echo ""
  echo "== D-15: nothing the sweep acted on resolves under incomplete/ or /mnt/tank/media =="
  # Counted with awk, not `grep -c`. `grep -c` prints the count AND exits 1 when the count is zero,
  # so the obvious `$(grep -c ... || echo 0)` emits TWO lines ("0\n0") on the healthy outcome and
  # the assertion fails precisely when the estate is correct. That defect was live in this file and
  # fired on the real run; it is recorded here rather than silently corrected.
  eq "result-file lines naming incomplete/"     "0" "$(awk '/\/mnt\/tank\/downloads\/incomplete/{c++} END{print c+0}' "$P/junk-sweep-result.txt" 2>/dev/null)"
  eq "result-file lines naming /mnt/tank/media" "0" "$(awk '/\/mnt\/tank\/media/{c++} END{print c+0}' "$P/junk-sweep-result.txt" 2>/dev/null)"
  eq "sweep exit line present"                  "1" "$(awk '/sweep complete - every approved row acted on/{c++} END{print c+0}' "$P/junk-sweep-result.txt" 2>/dev/null)"
  eq "move failures reported by the sweep"      "0" "$(awk -F': +' '/^  move failures:/{print $2}' "$P/junk-sweep-result.txt" | awk '{print $1}' | tr -dc '0-9')"
  eq "removal failures reported by the sweep"   "0" "$(awk -F': +' '/^  removal failures:/{print $2}' "$P/junk-sweep-result.txt" | awk '{print $1}' | tr -dc '0-9')"
  eq "rows moved reported by the sweep"        "44" "$(awk -F': +' '/^  moved:/{print $2}' "$P/junk-sweep-result.txt" | tr -dc '0-9')"
  eq "rows removed reported by the sweep"      "40" "$(awk -F': +' '/^  removed:/{print $2}' "$P/junk-sweep-result.txt" | tr -dc '0-9')"

  echo ""
  echo "== FAILURES: $FAILS"
}

case "${1:-}" in
  list)   do_list ;;
  estate) do_estate ;;
  *) echo "usage: bash verify-05-04.sh {list|estate}" >&2; exit 2 ;;
esac

[ "$FAILS" -eq 0 ] && { echo "ALL ASSERTIONS HELD"; exit 0; }
echo "$FAILS ASSERTION(S) FAILED"; exit 1
