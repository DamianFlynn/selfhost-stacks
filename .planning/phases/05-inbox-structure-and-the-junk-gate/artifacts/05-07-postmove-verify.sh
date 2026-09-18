#!/usr/bin/env bash
# Post-move verification of the Now! split, computed from the RESULTING TREE, not from the map.
# Read-only. Runs on LXC 100.
set -euo pipefail

R=/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023
OUT=/mnt/fast/safety/phase05
MAP=$OUT/now-split-map.tsv
TAGS=$OUT/now-tags.ndjson
MAN=$OUT/now-manifest.ndjson
SAMPLE=$OUT/now-split-inode-sample.tsv
W="$OUT/.postmove.$$"
mkdir -p "$W"
trap 'rm -rf "$W"' EXIT

echo "== 1. DESTINATION SHAPE =="
find "$R" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | LC_ALL=C sort > "$W/dirs1.txt"
printf '  %-46s %s\n' "directories at depth 1" "$(wc -l < "$W/dirs1.txt" | tr -d '[:space:]')"
printf '  %-46s %s\n' "directories at depth 2" "$(find "$R" -mindepth 2 -maxdepth 2 -type d -printf '.' | wc -c | tr -d '[:space:]')"
printf '  %-46s %s\n' "depth-1 dirs NOT matching 'Vol NNN'" "$(grep -cv '^Vol [0-9][0-9][0-9]$' "$W/dirs1.txt" || true)"
# no gaps: exactly Vol 001..Vol 115
seq -f 'Vol %03g' 1 115 > "$W/expect_dirs.txt"
printf '  %-46s %s\n' "expected-but-absent volume folders" "$(LC_ALL=C comm -23 "$W/expect_dirs.txt" "$W/dirs1.txt" | wc -l | tr -d '[:space:]')"
printf '  %-46s %s\n' "present-but-unexpected volume folders" "$(LC_ALL=C comm -13 "$W/expect_dirs.txt" "$W/dirs1.txt" | wc -l | tr -d '[:space:]')"
LC_ALL=C comm -3 "$W/expect_dirs.txt" "$W/dirs1.txt" | sed 's/^/    MISMATCH: /'

echo ""
echo "== 2. FILE PLACEMENT =="
printf '  %-46s %s\n' "mp3 still directly at the collection root" "$(find "$R" -mindepth 1 -maxdepth 1 -type f -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')"
printf '  %-46s %s\n' "non-mp3 still at the collection root" "$(find "$R" -mindepth 1 -maxdepth 1 -type f ! -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')"
find "$R" -mindepth 1 -maxdepth 1 -type f -printf '    ROOT: %f\n' | LC_ALL=C sort
printf '  %-46s %s\n' "mp3 inside volume folders (depth 2)" "$(find "$R" -mindepth 2 -maxdepth 2 -type f -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')"
printf '  %-46s %s\n' "non-mp3 inside volume folders" "$(find "$R" -mindepth 2 -maxdepth 2 -type f ! -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')"
printf '  %-46s %s\n' "files anywhere below depth 2" "$(find "$R" -mindepth 3 -type f -printf '.' | wc -c | tr -d '[:space:]')"

echo ""
echo "== 3. THE FOUR VALUE-BEARING SIDECARS (D-06) =="
for f in back.bmp cd1.bmp cd2.bmp; do
  if [ -f "$R/Vol 077/$f" ]; then echo "  OK   $f is inside 'Vol 077'"; else echo "  FAIL $f is NOT inside 'Vol 077'"; fi
done
n_cue=$(find "$R/Vol 115" -maxdepth 1 -type f -iname '*.cue' -printf '.' | wc -c | tr -d '[:space:]')
echo "  .cue files inside 'Vol 115': $n_cue (expect 1)"
find "$R/Vol 115" -maxdepth 1 -type f -iname '*.cue' -printf '    %f\n'
n_m3u=$(find "$R" -maxdepth 1 -type f -iname '*.m3u' -printf '.' | wc -c | tr -d '[:space:]')
echo "  .m3u files at the collection ROOT: $n_m3u (expect 1)"

echo ""
echo "== 4. HEADLINE TOTAL, SUMMED PER VOLUME FOLDER FROM THE TREE =="
for d in "$R"/Vol\ *; do
  v="${d##*/Vol }"
  c=$(find "$d" -maxdepth 1 -type f -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')
  printf '%d\t%s\n' "$((10#$v))" "$c"
done | LC_ALL=C sort -n > "$W/pervol_files.tsv"
printf '  %-46s %s\n' "volume folders counted" "$(wc -l < "$W/pervol_files.tsv" | tr -d '[:space:]')"
printf '  %-46s %s\n' "SUM of per-volume mp3 counts" "$(awk -F'\t' '{s+=$2} END {print s+0}' "$W/pervol_files.tsv")"
printf '  %-46s %s\n' "freshly measured collection total (05-05)" "4746"

echo ""
echo "== 5. PER-VOLUME IDENTITY files == sum(modal tracktotal), FROM THE TREE =="
# The tree gives volume -> basename. now-tags.ndjson gives basename -> disc/tracktotal.
# Basenames are unique across the collection (4,746 distinct leaves, measured in 05-05), so the
# join is by basename and NOT by path: every path changed in this plan.
find "$R" -mindepth 2 -maxdepth 2 -type f -iname '*.mp3' -printf '%h\t%f\n' \
  | sed "s|^${R}/Vol ||" > "$W/tree.tsv"
jq -r '[.basename, (.disc_number // ""), (.track_total // "")] | @tsv' "$TAGS" > "$W/tagsbn.tsv"
printf '  %-46s %s\n' "tree rows (volume, basename)" "$(wc -l < "$W/tree.tsv" | tr -d '[:space:]')"
printf '  %-46s %s\n' "distinct basenames in the tree" "$(awk -F'\t' '{print $2}' "$W/tree.tsv" | LC_ALL=C sort -u | wc -l | tr -d '[:space:]')"

awk -F'\t' -v OFS='\t' '
  FILENAME==ARGV[1] { disc[$1]=$2; tt[$1]=$3; next }
  {
    v = $1 + 0; bn = $2
    if (!(bn in disc)) { unjoined++; next }
    files[v]++
    d = disc[bn]; t = tt[bn]
    if (t != "") { votes[v SUBSEP d SUBSEP t]++; if (!((v SUBSEP d) in seen)) { seen[v SUBSEP d]=1; keys[++nk]=v SUBSEP d } }
  }
  END {
    for (kt in votes) { split(kt, p3, SUBSEP); k = p3[1] SUBSEP p3[2]
      if (votes[kt] > best[k]) { best[k]=votes[kt]; modal[k]=p3[3] } }
    for (i=1; i<=nk; i++) { k=keys[i]; split(k, p2, SUBSEP); v=p2[1]+0; sumtt[v] += modal[k]+0 }
    for (v in files) printf("%d\t%d\t%d\n", v, files[v], sumtt[v]+0)
    printf("UNJOINED\t%d\n", unjoined+0) > "/dev/stderr"
  }
' "$W/tagsbn.tsv" "$W/tree.tsv" 2> "$W/join.err" | LC_ALL=C sort -n > "$W/identity.tsv"
cat "$W/join.err" | sed 's/^/  /'
printf '  %-46s %s\n' "volumes measured" "$(wc -l < "$W/identity.tsv" | tr -d '[:space:]')"
printf '  %-46s %s\n' "BALANCED" "$(awk -F'\t' '$2==$3' "$W/identity.tsv" | wc -l | tr -d '[:space:]')"
printf '  %-46s %s\n' "EXCEPTIONS" "$(awk -F'\t' '$2!=$3' "$W/identity.tsv" | wc -l | tr -d '[:space:]')"
echo ""
echo "  computed exception set (volume | files | sum(tracktotal) | delta):"
awk -F'\t' '$2!=$3 {printf "    EXC  Vol %03d | %3d | %3d | %+d\n", $1, $2, $3, $2-$3}' "$W/identity.tsv"

echo ""
echo "  --- diff against the PRE-DECLARED list (05-NOW-INVENTORY.md AMENDMENT + 05-06-SUMMARY) ---"
cat > "$W/expected_exc.tsv" <<'EOF'
3	26	28
4	45	32
8	42	33
9	44	31
15	31	32
18	31	32
39	40	41
52	41	42
70	42	43
83	42	43
98	45	46
EOF
awk -F'\t' '$2!=$3 {print $1 "\t" $2 "\t" $3}' "$W/identity.tsv" | LC_ALL=C sort -n > "$W/actual_exc.tsv"
LC_ALL=C sort -n "$W/expected_exc.tsv" > "$W/expected_exc.s.tsv"
if LC_ALL=C diff -u "$W/expected_exc.s.tsv" "$W/actual_exc.tsv" > "$W/exc.diff"; then
  echo "    EXCEPTION SET MATCHES THE PRE-DECLARED LIST EXACTLY (11 rows)"
else
  echo "    EXCEPTION SET DIFFERS FROM THE PRE-DECLARED LIST:"
  sed 's/^/      /' "$W/exc.diff"
fi

echo ""
echo "== 6. MANIFEST-ONLY ENTRIES - THEIR OWN LINE, FOLDED INTO NO TOTAL =="
jq -r '.leaf' "$MAN" | LC_ALL=C sort -u > "$W/man_leaves.txt"
awk -F'\t' '{print $2}' "$W/tree.tsv" | LC_ALL=C sort -u > "$W/tree_bn.txt"
printf '  %-46s %s\n' "m3u manifest lines" "$(wc -l < "$MAN" | tr -d '[:space:]')"
printf '  %-46s %s\n' "distinct manifest leaves" "$(wc -l < "$W/man_leaves.txt" | tr -d '[:space:]')"
printf '  %-46s %s\n' "MANIFEST-ONLY (no file on disk)" "$(LC_ALL=C comm -23 "$W/man_leaves.txt" "$W/tree_bn.txt" | wc -l | tr -d '[:space:]')"
LC_ALL=C comm -23 "$W/man_leaves.txt" "$W/tree_bn.txt" | head -30 | sed 's/^/    MANIFEST-ONLY: /'

echo ""
echo "== 7. INODE SAMPLE: (devid, inode) PAIR BEFORE AND AFTER =="
# The pair, never the inode alone: this estate has a known inode COLLISION - /mnt/tank/downloads
# and /mnt/tank/media/Music both report inode 34 - so an inode-only assertion can agree by accident.
ok=0; bad=0; gone=0
while IFS=$'\t' read -r s t st; do
  [ -z "${t:-}" ] && continue
  if [ ! -f "$t" ]; then echo "    GONE: $t"; gone=$((gone+1)); continue; fi
  now=$(stat -c '%d %i' -- "$t")
  if [ "$now" = "$st" ]; then ok=$((ok+1)); else echo "    CHANGED: $t  before='$st'  after='$now'"; bad=$((bad+1)); fi
done < "$SAMPLE"
printf '  %-46s %s\n' "sample size" "$(wc -l < "$SAMPLE" | tr -d '[:space:]')"
printf '  %-46s %s\n' "(devid,inode) IDENTICAL after the move" "$ok"
printf '  %-46s %s\n' "(devid,inode) CHANGED" "$bad"
printf '  %-46s %s\n' "destination missing" "$gone"
echo "  negative control - the instrument can distinguish:"
echo "    a DIFFERENT dataset reports a different devid:"
printf '      %-38s %s\n' "collection root (tank/downloads)" "$(stat -c '%d' -- "$R")"
printf '      %-38s %s\n' "library root (tank/media/Music)"  "$(stat -c '%d' -- /mnt/tank/media/Music)"

echo ""
echo "== 8. EVERY MAP ROW ACCOUNTED FOR =="
moved=0; inplace=0; missing=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  s=$(printf '%s' "$line" | awk -F'\t' '{print $1}')
  t=$(printf '%s' "$line" | awk -F'\t' '{print $2}')
  if [ "$s" = "$t" ]; then
    if [ -f "$t" ]; then inplace=$((inplace+1)); else echo "    IN-PLACE ROW MISSING: $t"; missing=$((missing+1)); fi
  else
    if [ -f "$t" ] && [ ! -e "$s" ]; then moved=$((moved+1))
    else echo "    UNACCOUNTED ROW: src='$s' dst='$t'"; missing=$((missing+1)); fi
  fi
done < "$MAP"
printf '  %-46s %s\n' "map rows" "$(wc -l < "$MAP" | tr -d '[:space:]')"
printf '  %-46s %s\n' "moved (dst exists, src gone)" "$moved"
printf '  %-46s %s\n' "in place (dst == src, present)" "$inplace"
printf '  %-46s %s\n' "UNACCOUNTED" "$missing"

echo ""
echo "== 9. OWNERSHIP AND MODE - NOTHING WAS CHOWNED OR CHMODDED =="
echo "  ownership of the new volume directories (D-26: staging carries mixed ownership by design):"
find "$R" -mindepth 1 -maxdepth 1 -type d -printf '%u:%g\n' | LC_ALL=C sort | uniq -c | sed 's/^/    /'
echo "  ownership of the moved files (a rename preserves it):"
find "$R" -mindepth 2 -maxdepth 2 -type f -printf '%u:%g\n' | LC_ALL=C sort | uniq -c | sed 's/^/    /'
echo "  modes:"
find "$R" -mindepth 1 -maxdepth 1 -type d -printf '%m\n' | LC_ALL=C sort | uniq -c | sed 's/^/    dir  /'

echo ""
echo "POSTMOVE-VERIFY-COMPLETE"
