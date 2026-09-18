#!/usr/bin/env bash
# Verify the QUAL-01 before-state capture of the split tree. Read-only. Runs on LXC 100.
set -euo pipefail

R=/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023
T=/mnt/fast/safety/music-pre-project/tags
CAP=$T/phase05-now-before.ndjson.gz

echo "== 1. THE CAPTURE EXISTS AND IS NON-EMPTY =="
ls -l "$CAP" "$T/phase05-now-before.done" "$T/phase05-now-before.failed" | sed 's/^/  /'
printf '  %-52s %s\n' "failed ledger lines (expect 0)" "$(wc -l < "$T/phase05-now-before.failed" | tr -d '[:space:]')"

echo ""
echo "== 2. RECORD COUNT == mp3 COUNT IN THE 115 VOLUME FOLDERS =="
n_rec=$(zcat "$CAP" | wc -l | tr -d '[:space:]')
n_tree=$(find "$R" -mindepth 2 -maxdepth 2 -type f -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')
printf '  %-52s %s\n' "records in the capture" "$n_rec"
printf '  %-52s %s\n' "mp3 across the 115 volume folders" "$n_tree"
if [ "$n_rec" = "$n_tree" ]; then echo "  ASSERT OK: the capture is COMPLETE"; else echo "  ASSERT FAIL: short capture - the gate would be vacuous"; fi

echo ""
echo "== 3. EVERY RECORD CARRIES A NON-EMPTY audio_md5 - the join key =="
printf '  %-52s %s\n' "records with a non-empty audio_md5" \
  "$(zcat "$CAP" | jq -r 'select((.audio_md5 // "") != "") | .audio_md5' | wc -l | tr -d '[:space:]')"
printf '  %-52s %s\n' "records with a MISSING or EMPTY audio_md5" \
  "$(zcat "$CAP" | jq -r 'select((.audio_md5 // "") == "") | .source_path' | wc -l | tr -d '[:space:]')"
printf '  %-52s %s\n' "DISTINCT audio_md5 values" \
  "$(zcat "$CAP" | jq -r '.audio_md5' | LC_ALL=C sort -u | wc -l | tr -d '[:space:]')"
echo "  (a duplicate audio_md5 is a legitimate DUPE-01 finding, not a capture defect)"

echo ""
echo "== 4. ZERO-TAG-FIELD COUNT - stated beside the expected value of 0 =="
# Flattened exactly as diff-music-tags.sh defines it: format.tags merged with the tags of every
# AUDIO stream. A near-empty tag set is a legitimate before-state, not a capture failure - but it
# must be COUNTED, so "no fields dropped" later cannot be read as a pass when there was nothing
# there to drop.
zcat "$CAP" | jq -r '
  [ (.ffprobe.format.tags // {} | keys_unsorted[]) ,
    (.ffprobe.streams // [] | map(select(.codec_type == "audio")) | .[] | (.tags // {} | keys_unsorted[]))
  ] | length' > /mnt/fast/safety/phase05/.fieldcounts.$$
printf '  %-52s %s\n' "records with ZERO tag fields (expected: 0)" \
  "$(awk '$1 == 0' /mnt/fast/safety/phase05/.fieldcounts.$$ | wc -l | tr -d '[:space:]')"
# `sed -n '1p'`, never `| head -1`: head exits after one line and SIGPIPEs its writer, which under
# `set -o pipefail` kills the whole script with 141 AFTER every assertion has already printed a
# correct result. That happened on the first run of this very file. sed consumes its whole input.
printf '  %-52s %s\n' "minimum tag fields on any record" "$(LC_ALL=C sort -n /mnt/fast/safety/phase05/.fieldcounts.$$ | sed -n '1p')"
printf '  %-52s %s\n' "maximum tag fields on any record" "$(LC_ALL=C sort -n /mnt/fast/safety/phase05/.fieldcounts.$$ | tail -1)"
printf '  %-52s %s\n' "mean tag fields per record" "$(awk '{s+=$1; n++} END {printf "%.1f", s/n}' /mnt/fast/safety/phase05/.fieldcounts.$$)"
rm -f /mnt/fast/safety/phase05/.fieldcounts.$$

echo ""
echo "  the three fields the split and the 05-09 repair turn on, present on every record?"
for f in album disc track; do
  c=$(zcat "$CAP" | jq -r --arg F "$f" '.ffprobe.format.tags // {} | to_entries | map(select(.key | ascii_downcase == $F)) | length' | awk '$1 > 0' | wc -l | tr -d '[:space:]')
  printf '    %-20s present on %s records\n' "$f" "$c"
done

echo ""
echo "== 5. SCOPE - the capture read the SPLIT TREE, not 140 GB =="
printf '  %-52s %s\n' "distinct scan_root values" "$(zcat "$CAP" | jq -r '.scan_root' | LC_ALL=C sort -u | wc -l | tr -d '[:space:]')"
zcat "$CAP" | jq -r '.scan_root' | LC_ALL=C sort -u | sed 's/^/    /'
printf '  %-52s %s\n' "source_path values NOT under the collection" \
  "$(zcat "$CAP" | jq -r --arg R "$R/" 'select((.source_path | startswith($R)) | not) | .source_path' | wc -l | tr -d '[:space:]')"
printf '  %-52s %s\n' "source_path values NOT under a 'Vol NNN' folder" \
  "$(zcat "$CAP" | jq -r --arg R "$R/Vol " 'select((.source_path | startswith($R)) | not) | .source_path' | wc -l | tr -d '[:space:]')"
printf '  %-52s %s\n' "distinct volume folders represented" \
  "$(zcat "$CAP" | jq -r --arg R "$R/" '.source_path | ltrimstr($R) | split("/")[0]' | LC_ALL=C sort -u | wc -l | tr -d '[:space:]')"

echo ""
echo "== 6. THE PROPERTY THAT MAKES D-10's TAG WRITE AFFORDABLE, DRIVEN =="
echo "  The key is the ENCODED AUDIO BITSTREAM, not the container and not the path. A tag write"
echo "  changes the container; it does not change the bitstream, so the join key survives it."
echo "  Driven rather than asserted - re-hash one file two ways and compare:"
f=$(zcat "$CAP" | jq -r '.source_path' | sed -n '1p')
recorded=$(zcat "$CAP" | jq -r --arg P "$f" 'select(.source_path == $P) | .audio_md5' | sed -n '1p')
audio_only=$(ffmpeg -v error -i "$f" -map 0:a -c copy -f md5 - | sed 's/^MD5=//')
whole_file=$(md5sum "$f" | awk '{print $1}')
echo "    file:                 ${f##*/}"
echo "    recorded audio_md5:   $recorded"
echo "    re-hashed audio only: $audio_only"
echo "    whole-file md5:       $whole_file"
if [ "$recorded" = "$audio_only" ]; then echo "    OK:   the key reproduces from the audio stream alone"
else echo "    FAIL: the key does not reproduce"; fi
if [ "$recorded" = "$whole_file" ]; then echo "    FAIL: the key equals the whole-file hash - it would NOT survive a tag write"
else echo "    OK:   the key is NOT the whole-file hash - a tag write cannot move it"; fi

echo ""
echo "== 7. THE 11 NON-DISTINCT audio_md5 VALUES, NAMED =="
echo "  4,746 records carry 4,735 distinct bitstreams. This is a DUPE-01 observation, NOT a"
echo "  capture defect - diff-music-tags.sh reports it informationally and it never affects the"
echo "  exit code. It is named here because plan 05-09 joins on this key."
zcat "$CAP" | jq -r --arg R "$R/" '[.audio_md5, (.source_path | ltrimstr($R))] | @tsv' \
  | LC_ALL=C sort > /mnt/fast/safety/phase05/.md5s.$$
awk -F'\t' '{c[$1]++; p[$1] = p[$1] (p[$1]=="" ? "" : " | ") $2} END {n=0; for (k in c) if (c[k] > 1) {n++; printf("    x%d  %s\n", c[k], p[k])}; printf("  groups sharing a bitstream: %d\n", n)}' \
  /mnt/fast/safety/phase05/.md5s.$$ | LC_ALL=C sort
rm -f /mnt/fast/safety/phase05/.md5s.$$

echo ""
echo "CAPTURE-VERIFY-6-COMPLETE"
