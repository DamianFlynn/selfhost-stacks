#!/usr/bin/env bash
# fixture-05-04.sh - drive plan 05-04's change to scripts/phase05-junk-sweep.sh, and the operator's
# two amendments to the candidate list, on a SYNTHETIC fixture with DOWNLOADS relocated, BEFORE the
# sweep is pointed at the estate. Same method as 05-03's gate-fixture proof: the whole scope fence
# moves with DOWNLOADS, so the machinery is exercised with the estate unreachable.
#
# What is driven:
#   RUN 1  positive control - the amendment procedure end to end. `enumerate` writes a list, the
#          SAME awk amendment that will be applied to the real list drops the .covers row and adds
#          a 99-quarantine destination to the R1 row, then `sweep` runs. Expect: the R1 row MOVED
#          and NOT removed with its audio intact and its inode unchanged; the R8 row moved to
#          02-review; the two destination-less rows moved AND removed; the batch left empty; the
#          .covers directory untouched on disk.
#   RUN 2  negative control - an R8 PROPOSAL row with NO destination must fail closed and be left
#          in place, never fall through to the removal path. This is the regression the change
#          could have introduced.
#   RUN 3  negative control - the whole-sweep TOCTOU abort still fires after the change. A row is
#          approved and then grows by 10 bytes. Expect exit 1, nothing moved, nothing removed.
#
# Exit 0 only if every expectation holds.

set -uo pipefail

SCRIPT=/mnt/fast/stacks/scripts/phase05-junk-sweep.sh
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BASE="/mnt/fast/safety/phase05/fixture-05-04-$STAMP"
FAILS=0

ok()   { echo "  PASS  $*"; }
bad()  { echo "  FAIL  $*"; FAILS=$((FAILS + 1)); }
head2() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

# assert_eq LABEL EXPECTED ACTUAL
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1: $3"; else bad "$1: expected '$2', got '$3'"; fi
}
assert_exists()  { if [ -e "$1" ]; then ok "exists: $1"; else bad "MISSING: $1"; fi; }
assert_absent()  { if [ ! -e "$1" ]; then ok "absent: $1"; else bad "STILL PRESENT: $1"; fi; }

build_fixture() {
  local fx="$1"
  mkdir -p "$fx/complete/nzb/music/_FAILED_KeepMe"
  mkdir -p "$fx/complete/nzb/music/_UNPACK_Junk"
  mkdir -p "$fx/complete/nzb/dj-mixes/EmptyShell"
  mkdir -p "$fx/complete/nzb/dj-mixes/Release-With-Art/.covers"
  mkdir -p "$fx/complete/nzb/unsorted"
  mkdir -p "$fx/complete/nzb/_inbox/01-auto" "$fx/complete/nzb/_inbox/02-review" \
           "$fx/complete/nzb/_inbox/03-asis" "$fx/complete/nzb/_inbox/04-hold" \
           "$fx/complete/nzb/_inbox/99-quarantine" "$fx/complete/nzb/_inbox/_done"
  mkdir -p "$fx/lidarr-import/ArtistX"
  mkdir -p "$fx/incomplete"
  printf 'AAAAAAAAAA' > "$fx/complete/nzb/music/_FAILED_KeepMe/a.flac"
  printf 'BBBBB'      > "$fx/complete/nzb/music/_UNPACK_Junk/x.rar"
  printf 'CCCCCCC'    > "$fx/complete/nzb/dj-mixes/Release-With-Art/t1.mp3"
  printf 'DDD'        > "$fx/complete/nzb/dj-mixes/Release-With-Art/.covers/c.jpg"
  printf 'EEEE'       > "$fx/lidarr-import/ArtistX/s.mp3"
}

# THE AMENDMENT, written once here and applied verbatim to the live list later. Amendment 1 drops
# every .covers row; amendment 2 converts every R1 row into a move-only row bound for 99-quarantine.
amend() {
  awk -F'\t' 'BEGIN{OFS="\t"}
    $2 ~ /\/\.covers$/ { next }
    $1 == "R1"         { $7 = "99-quarantine"; print; next }
                       { print }' "$1"
}

# ---------------------------------------------------------------------------------------------
head2 "RUN 1 - positive control: the amendment procedure, end to end"
FX="$BASE/run1"; OUT="$BASE/run1-out"
mkdir -p "$OUT"
build_fixture "$FX"
echo "tank/downloads@pre-phase5" > "$OUT/snapshot-proof.txt"

DOWNLOADS="$FX" OUT_DIR="$OUT" bash "$SCRIPT" enumerate > "$OUT/enumerate.log" 2>&1
assert_eq "enumerate exit" "0" "$?"
assert_eq "enumerate rows" "5" "$(wc -l < "$OUT/junk-candidates.tsv" | tr -dc '0-9')"
echo "  --- as enumerated ---"; cut -f1,2 "$OUT/junk-candidates.tsv" | sed 's|^|    |'

cp "$OUT/junk-candidates.tsv" "$OUT/junk-candidates-as-enumerated.tsv"
amend "$OUT/junk-candidates-as-enumerated.tsv" > "$OUT/junk-candidates.tsv.building"
mv "$OUT/junk-candidates.tsv.building" "$OUT/junk-candidates.tsv"
assert_eq "amended rows" "4" "$(wc -l < "$OUT/junk-candidates.tsv" | tr -dc '0-9')"
assert_eq "covers rows surviving" "0" "$(awk -F'\t' '$2 ~ /\/\.covers$/' "$OUT/junk-candidates.tsv" | wc -l | tr -dc '0-9')"
assert_eq "R1 rows with 99-quarantine dest" "1" "$(awk -F'\t' '$1=="R1" && $7=="99-quarantine"' "$OUT/junk-candidates.tsv" | wc -l | tr -dc '0-9')"
echo "  --- as amended ---"; cut -f1,2,7 "$OUT/junk-candidates.tsv" | sed 's|^|    |'

# inode + devid of the file inside the move-only row, BEFORE
BEFORE_DI="$(stat -c '%d %i' "$FX/complete/nzb/music/_FAILED_KeepMe/a.flac")"

DOWNLOADS="$FX" OUT_DIR="$OUT" bash "$SCRIPT" sweep > "$OUT/sweep.log" 2>&1
RC=$?
assert_eq "sweep exit" "0" "$RC"
sed 's|^|    |' "$OUT/sweep.log"

Q="$FX/complete/nzb/_inbox/99-quarantine"
R="$FX/complete/nzb/_inbox/02-review"
assert_exists "$Q/_FAILED_KeepMe"
assert_exists "$Q/_FAILED_KeepMe/a.flac"
assert_absent "$FX/complete/nzb/music/_FAILED_KeepMe"
assert_eq "move-only row audio survived (bytes)" "10" "$(stat -c %s "$Q/_FAILED_KeepMe/a.flac" 2>/dev/null)"
AFTER_DI="$(stat -c '%d %i' "$Q/_FAILED_KeepMe/a.flac" 2>/dev/null)"
assert_eq "(devid,inode) pair unchanged across the move" "$BEFORE_DI" "$AFTER_DI"

assert_exists "$R/ArtistX"
assert_absent "$FX/lidarr-import/ArtistX"

assert_absent "$FX/complete/nzb/music/_UNPACK_Junk"
assert_absent "$FX/complete/nzb/dj-mixes/EmptyShell"

# the excluded .covers row must be untouched on disk
assert_exists "$FX/complete/nzb/dj-mixes/Release-With-Art/.covers/c.jpg"
assert_eq "excluded .covers file bytes" "3" "$(stat -c %s "$FX/complete/nzb/dj-mixes/Release-With-Art/.covers/c.jpg" 2>/dev/null)"

# The TIMESTAMPED BATCH directory must be empty. 99-quarantine itself must NOT be, because the
# move-only row deliberately lives there - which is exactly the real run's shape, and is why this
# assertion has to name the batch rather than the quarantine root. The first version of it did the
# latter and failed on a correct outcome: it counted the move-only row's own audio file.
BATCHDIR="$(awk -F': +' '/^  quarantine batch:/{print $2}' "$OUT/sweep.log")"
assert_eq "batch directory was parsed from the run" "1" "$([ -n "$BATCHDIR" ] && echo 1 || echo 0)"
assert_eq "entries left inside the timestamped batch" "0" "$(find "$BATCHDIR" -mindepth 1 2>/dev/null | wc -l | tr -dc '0-9')"
assert_eq "99-quarantine deliberately holds the move-only row" "1" "$(find "$Q" -mindepth 1 -maxdepth 1 -name '_FAILED_*' 2>/dev/null | wc -l | tr -dc '0-9')"

# ---------------------------------------------------------------------------------------------
head2 "RUN 2 - negative control: an R8 PROPOSAL row with NO destination must fail closed"
FX2="$BASE/run2"; OUT2="$BASE/run2-out"
mkdir -p "$OUT2"
build_fixture "$FX2"
echo "tank/downloads@pre-phase5" > "$OUT2/snapshot-proof.txt"
DOWNLOADS="$FX2" OUT_DIR="$OUT2" bash "$SCRIPT" enumerate > "$OUT2/enumerate.log" 2>&1
# strip the seventh field from the R8 row, keep only that row
awk -F'\t' 'BEGIN{OFS="\t"} $1=="R8"{ print $1,$2,$3,$4,$5,$6 }' "$OUT2/junk-candidates.tsv" > "$OUT2/j.building"
mv "$OUT2/j.building" "$OUT2/junk-candidates.tsv"
assert_eq "run2 row count" "1" "$(wc -l < "$OUT2/junk-candidates.tsv" | tr -dc '0-9')"
assert_eq "run2 field count" "6" "$(awk -F'\t' 'NR==1{print NF}' "$OUT2/junk-candidates.tsv")"
DOWNLOADS="$FX2" OUT_DIR="$OUT2" bash "$SCRIPT" sweep > "$OUT2/sweep.log" 2>&1
RC2=$?
assert_eq "run2 sweep exit" "1" "$RC2"
grep -q 'carries no destination' "$OUT2/sweep.log" && ok "run2 refusal names the missing destination" || bad "run2 refusal message absent"
assert_exists "$FX2/lidarr-import/ArtistX/s.mp3"
# Read the VALUE the run reported, not whether a line saying zero is PRESENT. The first version of
# this assertion counted the presence of the literal "removed: 0" line and compared that count to 0,
# so it failed precisely when the script behaved correctly - the estate's recorded trap of a
# mechanical check satisfied by prose about the thing rather than by the thing.
assert_eq "run2 removed count"       "0" "$(awk -F': +' '/^  removed:/{print $2}'          "$OUT2/sweep.log" | tr -dc '0-9')"
assert_eq "run2 moved count"         "0" "$(awk -F': +' '/^  moved:/{print $2}'            "$OUT2/sweep.log" | tr -dc '0-9')"
assert_eq "run2 move failure count"  "1" "$(awk -F': +' '/^  move failures:/{print $2}'    "$OUT2/sweep.log" | awk '{print $1}' | tr -dc '0-9')"

# ---------------------------------------------------------------------------------------------
head2 "RUN 3 - negative control: the whole-sweep TOCTOU abort still fires after the change"
FX3="$BASE/run3"; OUT3="$BASE/run3-out"
mkdir -p "$OUT3"
build_fixture "$FX3"
echo "tank/downloads@pre-phase5" > "$OUT3/snapshot-proof.txt"
DOWNLOADS="$FX3" OUT_DIR="$OUT3" bash "$SCRIPT" enumerate > "$OUT3/enumerate.log" 2>&1
amend "$OUT3/junk-candidates.tsv" > "$OUT3/j.building"
mv "$OUT3/j.building" "$OUT3/junk-candidates.tsv"
# the tree moves under the approved list: the move-only R1 row grows by 10 bytes
printf 'ZZZZZZZZZZ' >> "$FX3/complete/nzb/music/_FAILED_KeepMe/a.flac"
DOWNLOADS="$FX3" OUT_DIR="$OUT3" bash "$SCRIPT" sweep > "$OUT3/sweep.log" 2>&1
RC3=$?
assert_eq "run3 sweep exit" "1" "$RC3"
grep -q 'size moved' "$OUT3/sweep.log" && ok "run3 abort names the size change" || bad "run3 abort message absent"
grep -q 'NOTHING MOVED, NOTHING REMOVED' "$OUT3/sweep.log" && ok "run3 states nothing moved" || bad "run3 abort banner absent"
assert_exists "$FX3/complete/nzb/music/_FAILED_KeepMe/a.flac"
assert_exists "$FX3/complete/nzb/music/_UNPACK_Junk/x.rar"
assert_exists "$FX3/complete/nzb/dj-mixes/EmptyShell"
assert_eq "run3 quarantine entries" "0" "$(find "$FX3/complete/nzb/_inbox/99-quarantine" -mindepth 1 | wc -l | tr -dc '0-9')"

head2 "RESULT"
echo "  fixture base: $BASE"
echo "  failures:     $FAILS"
if [ "$FAILS" -eq 0 ]; then echo "  ALL FIXTURE EXPECTATIONS HELD"; exit 0; fi
echo "  FIXTURE FAILED"; exit 1
