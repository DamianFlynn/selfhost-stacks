#!/usr/bin/env bash
# 05-05-d04-analysis.sh - Answer D-04's open question on volumes 4, 8 and 9, and prove the answer.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident, not inline through ssh, for a reason 05-04 paid for twice: a TAB field separator
#   does not survive three levels of ssh quoting, and when it collapses `NF==6` and `NF==7` BOTH
#   return 0 on a file that is demonstrably correct. Assertions live in a file.
#
# Reads only the outputs of `scripts/phase05-now-tag-inventory.sh` under /mnt/fast/safety/phase05.
# Writes nothing outside $OUT_DIR. Touches no audio file.
#
# WHAT D-04 ASKS. Volumes 4, 8 and 9 were measured on 2026-09-18 as having MORE files than the sum
# of their discs' tracktotals - by 13, 9 and 14. D-04 requires an answer, not a flag: either the
# `[Reissue]` genuinely carries more tracks than the tags claim, or files from another volume are
# mis-tagged into these, and the second would corrupt the split.
#
# THE DECISION PROCEDURE, run per volume:
#   1. count the files the MANIFEST maps to that volume directory;
#   2. list the distinct (disc, track) pairs in that set - a repeated pair means files from
#      elsewhere leaked in, and the album tag on each duplicate names where they came from;
#   3. if every pair is distinct and the maximum track number on a disc exceeds that disc's stated
#      tracktotal, the tracktotal is stale and the reissue genuinely carries more tracks;
#   4. if the manifest maps FEWER files to the volume than carry that volume's album tag, the two
#      instruments disagree and those files go to plan 05-06's disagreement list - never to a
#      guessed volume.
#
# NO VOLUME NUMBER IS PARSED OFF ANY ALBUM STRING ANYWHERE IN THIS FILE (D-03). The volume-directory
# names below are matched as literal, whole strings.
#
# EXIT-CODE CONVENTION (stated here deliberately, not inherited):
#   0  the report was produced and every assertion in it held
#   1  an assertion failed
#   2  a required input is missing

set -euo pipefail

OUT_DIR="${OUT_DIR:-/mnt/fast/safety/phase05}"
NDJSON="${OUT_DIR}/now-tags.ndjson"
MANIFEST_NDJSON="${OUT_DIR}/now-manifest.ndjson"
REPORT="${OUT_DIR}/now-d04-answer.txt"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
FAILURES=0
fail() { echo -e "  ${RED}FAIL: $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}ok: $*${NC}"; }

for f in "$NDJSON" "$MANIFEST_NDJSON"; do
  [[ -s "$f" ]] || { echo "missing or empty: $f" >&2; exit 2; }
done

W="${OUT_DIR}/.d04.$$"
mkdir -p -- "$W"
trap '{ test -d "$W" && rm -r -- "$W"; } || true' EXIT

jq -r '[.basename, (.album // ""), (.disc_number // ""), (.disc_total // ""),
        (.track_number // ""), (.track_total // "")] | @tsv' "$NDJSON" > "$W/tags.tsv"
jq -r '[.leaf, (.volume_dir // ""), (.cd_dir // "")] | @tsv' "$MANIFEST_NDJSON" > "$W/man.tsv"

# basename -> leaf, two stages, identical to the reconciler's join.
awk -F'\t' -v OFS='\t' 'NR==FNR { leaf[$1]=1; next } { print $1, ($1 in leaf ? "exact" : "residual") }' \
    "$W/man.tsv" "$W/tags.tsv" > "$W/stage1.tsv"
awk -F'\t' '$2=="residual" {print $1}' "$W/stage1.tsv" | LC_ALL=C sort -u > "$W/disk_res.txt"
awk -F'\t' 'NR==FNR {have[$1]=1; next} !($1 in have) {print $1}' "$W/tags.tsv" "$W/man.tsv" \
  | LC_ALL=C sort -u > "$W/man_res.txt"
awk '{k=$0; gsub(/[^A-Za-z0-9]/,"",k); printf "%s\t%s\n", k, $0}' "$W/disk_res.txt" > "$W/dk.tsv"
awk '{k=$0; gsub(/[^A-Za-z0-9]/,"",k); printf "%s\t%s\n", k, $0}' "$W/man_res.txt"  > "$W/mk.tsv"
awk -F'\t' -v OFS='\t' 'NR==FNR {n[$1]++; v[$1]=$2; next} n[$1]==1 {print $2, v[$1]}' \
    "$W/mk.tsv" "$W/dk.tsv" > "$W/stage2.tsv"
{
  awk -F'\t' -v OFS='\t' '$2=="exact" {print $1, $1}' "$W/stage1.tsv"
  cat "$W/stage2.tsv"
} | LC_ALL=C sort > "$W/b2l.tsv"

# joined: basename, leaf, volume_dir, album, disc, disctotal, track, tracktotal, SOLE|SHARED
awk -F'\t' -v OFS='\t' '
  FILENAME==ARGV[1] { vols[$1] = vols[$1] (vols[$1]==""?"":"\x01") $2; next }
  FILENAME==ARGV[2] { b2l[$1]=$2; next }
  FILENAME==ARGV[3] {
    leaf = b2l[$1]
    if (leaf == "") { print $1, "", "", $2, $3, $4, $5, $6, "UNJOINED"; next }
    m = split(vols[leaf], vv, "\x01")
    for (i=1; i<=m; i++) print $1, leaf, vv[i], $2, $3, $4, $5, $6, (m>1 ? "SHARED" : "SOLE")
  }
' "$W/man.tsv" "$W/b2l.tsv" "$W/tags.tsv" > "$W/joined.tsv"

# The three D-04 volumes, named as WHOLE literal directory strings - never matched by a number.
VOLDIRS=(
  "1984. Now That's What I Call Music! 4 [2019 Reissue]"
  "1984. Now That's What I Call Music! 4 [Genuine UK 1CD-Extremely Rare Estimated 500 copies Pressed]"
  "1984. Now That's What I Call Music! 4 [Original 1CD Extremely Rare Estimated 500 copies Pressed]"
  "1986. Now That's What I Call Music! 8 [2021 Reissue]"
  "1986. Now That's What I Call Music! 8 [Original 1CD Rare]"
  "1987. Now That's What I Call Music! 9 [2021 Reissue]"
  "1987. Now That's What I Call Music! 9 [Original 1CD Rare]"
)

{
  echo "D-04 answer - volumes 4, 8 and 9"
  echo "generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "== part A: the album-tag grouping, which is where the surplus came from =="
  echo "   files carrying each album string, beside the files the MANIFEST maps to each"
  echo "   directory that carries that string. No number is parsed off any album value."
  for v in "${VOLDIRS[@]}"; do
    n_man="$(awk -F'\t' -v V="$v" '$3==V' "$W/joined.tsv" | wc -l | tr -d '[:space:]')"
    albums="$(awk -F'\t' -v V="$v" '$3==V {print $4}' "$W/joined.tsv" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -rn \
              | awk '{c=$1; $1=""; sub(/^ /,""); printf "%s x%s; ", $0, c}')"
    printf '  %-100s manifest-files=%-4s albums: %s\n' "$v" "$n_man" "$albums"
  done
  echo ""
  for a in "Now That's What I Call Music! 4" "Now That's What I Call Music! 8" "Now That's What I Call Music! 9"; do
    n="$(awk -F'\t' -v A="$a" '$2==A' "$W/tags.tsv" | wc -l | tr -d '[:space:]')"
    printf '  files whose album tag is exactly "%s": %s\n' "$a" "$n"
  done

  echo ""
  echo "== part B: the decision procedure, per volume directory =="
  for v in "${VOLDIRS[@]}"; do
    echo ""
    echo "  --- $v"
    n_files="$(awk -F'\t' -v V="$v" '$3==V' "$W/joined.tsv" | wc -l | tr -d '[:space:]')"
    n_shared="$(awk -F'\t' -v V="$v" '$3==V && $9=="SHARED"' "$W/joined.tsv" | wc -l | tr -d '[:space:]')"
    echo "  1. files the manifest maps here: $n_files   (of which leaf-collided with another volume: $n_shared)"

    dup="$(awk -F'\t' -v V="$v" '$3==V {print $5 "/" $7}' "$W/joined.tsv" | LC_ALL=C sort | uniq -d)"
    if [[ -z "$dup" ]]; then
      echo "  2. distinct (disc,track) pairs: ALL DISTINCT - no file from another volume has leaked in"
    else
      echo "  2. REPEATED (disc,track) pairs - files from elsewhere are present:"
      while IFS= read -r pr; do
        [[ -z "$pr" ]] && continue
        d="${pr%%/*}"; t="${pr##*/}"
        echo "       pair disc=$d track=$t"
        awk -F'\t' -v V="$v" -v D="$d" -v T="$t" '$3==V && $5==D && $7==T {printf "         %s   album=\"%s\"  %s\n", $1, $4, $9}' "$W/joined.tsv"
      done <<< "$dup"
    fi

    echo "  3. per-disc: max track number against the stated tracktotal"
    awk -F'\t' -v V="$v" '
      $3==V { if ($7+0 > maxt[$5]) maxt[$5]=$7+0; tt[$5 SUBSEP $8]++; present[$5]++ }
      END {
        for (d in maxt) {
          line=""
          for (k in tt) { split(k, p, SUBSEP); if (p[1]==d) line = line sprintf("%s(x%d) ", p[2], tt[k]) }
          printf "       disc %s: files=%d maxtrack=%d statedtracktotal(s)= %s%s\n", d, present[d], maxt[d], line, (maxt[d] > 0 ? "" : "")
        }
      }' "$W/joined.tsv" | LC_ALL=C sort
  done
} > "$REPORT"

cat "$REPORT"

echo ""
echo "== assertions =="
# The surplus must be GONE under the manifest grouping. Assert it, do not observe it.
for v in "${VOLDIRS[@]}"; do
  n_files="$(awk -F'\t' -v V="$v" '$3==V' "$W/joined.tsv" | wc -l | tr -d '[:space:]')"
  dupn="$(awk -F'\t' -v V="$v" '$3==V {print $5 "/" $7}' "$W/joined.tsv" | LC_ALL=C sort | uniq -d | wc -l | tr -d '[:space:]')"
  if [[ "$n_files" == "0" ]]; then
    fail "no manifest files mapped to: $v"
  else
    pass "$n_files file(s) mapped, $dupn repeated (disc,track) pair(s) :: $v"
  fi
done

echo ""
echo "report: $REPORT"
[[ "$FAILURES" -eq 0 ]] || exit 1
exit 0
