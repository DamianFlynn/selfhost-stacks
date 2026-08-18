#!/usr/bin/env bash
# diff-music-tags.sh - Field-level comparison of two tag snapshots, keyed on the audio-stream hash
# Usage: ./scripts/diff-music-tags.sh BEFORE.ndjson.gz AFTER.ndjson.gz [--summary-only] [--full] [--json]
#
# Consumes the NDJSON emitted by scripts/snapshot-music-tags.sh and answers the one question
# QUAL-02 gates on: did any file, or any tag field, get LOST between the two captures?
#
# Why the join key is `audio_md5` and not the path (D-01): the BEFORE row was captured at
#   /mnt/tank/downloads/complete/nzb/unsorted/<folder>/<file>
# and the AFTER row will be at
#   /mnt/tank/media/Music/<ALBUMARTIST>/<Album>/NN Title.<ext>
# Only a key computed over the encoded audio bitstream matches across that move and rename. A
# path-keyed diff would report every file as both MISSING_AFTER and NEW_AFTER and prove nothing.
#
# Categories reported:
#   1. MATCHED         audio_md5 present on both sides
#   2. MISSING_AFTER   in BEFORE, absent from AFTER - the file-level loss case
#   3. NEW_AFTER       in AFTER, absent from BEFORE
#   4. FIELDS_DROPPED  per matched file, tag keys in BEFORE and absent in AFTER - the QUAL-02 gate
#   5. FIELDS_GAINED   per matched file, tag keys added
#   6. FIELDS_CHANGED  per matched file, keys on both sides whose value differs
#   plus, informational only: audio_md5 values seen under more than one path on either side.
#      That is a legitimate DUPE-01 finding (`dj-mixes` and `unsorted` share all 85 folder names),
#      not an error, so it never affects the exit code.
#
# EXIT CODES (the contract Phase 7 gates on):
#   0  no net metadata loss - MISSING_AFTER is 0 AND FIELDS_DROPPED is 0
#   1  loss detected        - either is non-zero
#   2  usage or input error
# This makes the roadmap's "trial diff of the snapshot against itself returns zero differences" a
# literal exit-0 assertion, and makes Phase 7's QUAL-02 gate a script invocation rather than a
# judgement call.
#
# TAG FLATTENING. Each side's tags are flattened to a comparable key=value map before comparing:
#   - `format.tags` merged with the tags of every audio stream
#   - stream tags prefixed `stream<N>.` so a format tag and a stream tag of the same name cannot
#     silently collapse into one another
#   - keys normalised to lower case FOR COMPARISON, with the original casing reported, because
#     container formats differ in how they case the same logical field (ID3 `TITLE` vs Vorbis
#     `title` is not a change)
#   - values compared as strings
#
# A near-empty tag set is a legitimate BEFORE state, not a capture failure - much of `unsorted` is
# WAV and carries no format tags at all. The summary therefore reports how many matched files had
# ZERO tag fields on the BEFORE side, so "no fields dropped" cannot be read as a pass when it is
# really "there was nothing there to drop".
#
# Nothing is written to the system temp directory. Two scratch files are needed for the join and
# they are created beside the BEFORE input - inside the fence - and removed by an EXIT trap. On
# LXC 100 the system temp directory is tmpfs backed by host RAM and a large spill there has
# previously taken the whole 28 GB box down (T-01-15).

set -euo pipefail

TRUNC_WIDTH=60          # value truncation for terminal output; --full disables it

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
  cat >&2 <<'EOF'
usage: ./scripts/diff-music-tags.sh BEFORE AFTER [--summary-only] [--full] [--json]

  BEFORE, AFTER   gzipped (or plain) NDJSON produced by scripts/snapshot-music-tags.sh
  --summary-only  print only the counts block
  --full          do not truncate tag values in the per-file rows
  --json          emit the whole result as one JSON object, for programmatic gating

exit 0 = no net metadata loss, 1 = loss detected, 2 = usage or input error
EOF
  exit 2
}

BEFORE=""; AFTER=""
SUMMARY_ONLY=0; FULL=0; AS_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary-only) SUMMARY_ONLY=1; shift ;;
    --full)         FULL=1; shift ;;
    --json)         AS_JSON=1; shift ;;
    -h|--help)      usage ;;
    -*)             echo "unknown option: $1" >&2; usage ;;
    *)              if   [[ -z "$BEFORE" ]]; then BEFORE="$1"
                    elif [[ -z "$AFTER"  ]]; then AFTER="$1"
                    else echo "too many positional arguments: $1" >&2; usage
                    fi; shift ;;
  esac
done

[[ -n "$BEFORE" && -n "$AFTER" ]] || usage

command -v jq >/dev/null 2>&1 || { echo "jq is required and was not found" >&2; exit 2; }

for f in "$BEFORE" "$AFTER"; do
  [[ -f "$f" ]] || { echo -e "${RED}input not found: $f${NC}" >&2; exit 2; }
  [[ -s "$f" ]] || { echo -e "${RED}input is empty: $f${NC}" >&2; exit 2; }
done

# ─── scratch, beside the inputs, never in the system temp dir ─────────────────
SCRATCH_DIR="$(cd "$(dirname "$BEFORE")" && pwd)"
[[ -w "$SCRATCH_DIR" ]] || {
  echo -e "${RED}cannot write scratch beside $BEFORE ($SCRATCH_DIR is not writable)${NC}" >&2
  exit 2
}
FLAT_B="$(mktemp "${SCRATCH_DIR}/.diff-music-tags.before.XXXXXX")"
FLAT_A="$(mktemp "${SCRATCH_DIR}/.diff-music-tags.after.XXXXXX")"
cleanup() { rm -f "$FLAT_B" "$FLAT_A"; }
trap cleanup EXIT

read_ndjson() {  # decompress if gzipped, pass through if not
  case "$1" in
    *.gz) gzip -cd -- "$1" ;;
    *)    cat -- "$1" ;;
  esac
}

# ─── stage 1: flatten each side, streaming ────────────────────────────────────
# Reduces each record from a full ffprobe object to {k: hash, p: path, t: {normkey: {n,v}}}.
# Done as a streaming pass rather than slurping the raw NDJSON because the full capture is ~9,700
# records of complete ffprobe output; the flattened form is a fraction of that and is what the
# join in stage 2 holds in memory.
FLATTEN_JQ='
  def flat:
    ( ((.ffprobe.format.tags // {}) | to_entries
        | map({ key: (.key | ascii_downcase),
                value: { n: .key, v: (.value | tostring) } }) )
      +
      ( [ .ffprobe.streams[]? | select(.codec_type == "audio") ]
        | to_entries
        | map( (.key | tostring) as $i
               | ((.value.tags // {}) | to_entries
                  | map({ key:   ("stream" + $i + "." + (.key | ascii_downcase)),
                          value: { n: ("stream" + $i + "." + .key),
                                   v: (.value | tostring) } }) ) )
        | add // [] )
    ) | from_entries;
  { k: (.audio_md5 // ""), p: (.source_path // ""), t: flat }
'

flatten_side() {  # $1 = input, $2 = output
  if ! read_ndjson "$1" | jq -c "$FLATTEN_JQ" > "$2" 2>/dev/null; then
    echo -e "${RED}failed to parse $1 - is it NDJSON from snapshot-music-tags.sh?${NC}" >&2
    exit 2
  fi
}

flatten_side "$BEFORE" "$FLAT_B"
flatten_side "$AFTER"  "$FLAT_A"

# ─── stage 2: join on audio_md5 and classify ──────────────────────────────────
JOIN_JQ='
  def index: reduce .[] as $r ({}; .[$r.k] = $r);
  def dupgroups: group_by(.k) | map(select(length > 1))
                 | map({ audio_md5: .[0].k, paths: (map(.p) | unique) })
                 | map(select(.paths | length > 1));

  ($B | index) as $bi | ($A | index) as $ai |
  ($bi | keys)  as $bk | ($ai | keys) as $ak |
  ([ $bk[] | select($ai[.] != null) ]) as $matched |
  ([ $bk[] | select($ai[.] == null) ]) as $only_b |
  ([ $ak[] | select($bi[.] == null) ]) as $only_a |

  ([ $matched[] as $k
     | $bi[$k] as $b | $ai[$k] as $a
     | ($b.t | keys_unsorted)[] as $f
     | select($a.t[$f] == null)
     | { audio_md5: $k, source_path: $b.p, field: $b.t[$f].n,
         before: $b.t[$f].v, after: null } ]) as $dropped |

  ([ $matched[] as $k
     | $bi[$k] as $b | $ai[$k] as $a
     | ($a.t | keys_unsorted)[] as $f
     | select($b.t[$f] == null)
     | { audio_md5: $k, source_path: $b.p, field: $a.t[$f].n,
         before: null, after: $a.t[$f].v } ]) as $gained |

  ([ $matched[] as $k
     | $bi[$k] as $b | $ai[$k] as $a
     | ($b.t | keys_unsorted)[] as $f
     | select($a.t[$f] != null and $a.t[$f].v != $b.t[$f].v)
     | { audio_md5: $k, source_path: $b.p, field: $b.t[$f].n,
         before: $b.t[$f].v, after: $a.t[$f].v } ]) as $changed |

  {
    counts: {
      before_records:   ($B | length),
      after_records:    ($A | length),
      before_keys:      ($bk | length),
      after_keys:       ($ak | length),
      matched:          ($matched | length),
      missing_after:    ($only_b  | length),
      new_after:        ($only_a  | length),
      fields_dropped:   ($dropped | length),
      fields_gained:    ($gained  | length),
      fields_changed:   ($changed | length),
      matched_with_no_before_fields:
        ([ $matched[] | select(($bi[.].t | length) == 0) ] | length),
      duplicate_keys_before: (($B | dupgroups) | length),
      duplicate_keys_after:  (($A | dupgroups) | length)
    },
    missing_after:  [ $only_b[] | { audio_md5: ., source_path: $bi[.].p } ],
    new_after:      [ $only_a[] | { audio_md5: ., source_path: $ai[.].p } ],
    fields_dropped: $dropped,
    fields_gained:  $gained,
    fields_changed: $changed,
    duplicates_before: ($B | dupgroups),
    duplicates_after:  ($A | dupgroups)
  }
'

RESULT="$(jq -n --slurpfile B "$FLAT_B" --slurpfile A "$FLAT_A" "$JOIN_JQ")"

if [[ $AS_JSON -eq 1 ]]; then
  printf '%s\n' "$RESULT"
  MISSING="$(jq -r '.counts.missing_after'  <<< "$RESULT")"
  DROPPED="$(jq -r '.counts.fields_dropped' <<< "$RESULT")"
  [[ "$MISSING" -eq 0 && "$DROPPED" -eq 0 ]] && exit 0 || exit 1
fi

c() { jq -r ".counts.$1" <<< "$RESULT"; }

MATCHED="$(c matched)"; MISSING="$(c missing_after)"; NEWA="$(c new_after)"
DROPPED="$(c fields_dropped)"; GAINED="$(c fields_gained)"; CHANGED="$(c fields_changed)"
NOFIELDS="$(c matched_with_no_before_fields)"
DUPB="$(c duplicate_keys_before)"; DUPA="$(c duplicate_keys_after)"

echo "🔍 Music tag snapshot diff"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}BEFORE:${NC} $BEFORE  ($(c before_records) records, $(c before_keys) distinct audio_md5)"
echo -e "${BLUE}AFTER :${NC} $AFTER  ($(c after_records) records, $(c after_keys) distinct audio_md5)"
echo ""

# Renders one category. $1=jq path, $2=heading, $3=count, $4=1 if the rows carry field/value cols
render() {
  local path="$1" heading="$2" count="$3" wide="$4"
  echo "$heading  ($count)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ "$count" -eq 0 ]]; then
    echo -e "  ${GREEN}✅ none${NC}"
  else
    if [[ "$wide" -eq 1 ]]; then
      jq -r ".${path}[] | [.audio_md5, .source_path, .field, (.before // \"\"), (.after // \"\")] | @tsv" <<< "$RESULT"
    else
      jq -r ".${path}[] | [.audio_md5, .source_path] | @tsv" <<< "$RESULT"
    fi | if [[ $FULL -eq 1 ]]; then sed 's/^/  /'
         else awk -F'\t' -v w="$TRUNC_WIDTH" 'BEGIN{OFS="\t"}
                { for (i = 1; i <= NF; i++)
                    if (length($i) > w) $i = substr($i, 1, w - 1) "…"
                  print "  " $0 }'
         fi
  fi
  echo ""
}

if [[ $SUMMARY_ONLY -eq 0 ]]; then
  render "missing_after"  "2️⃣  MISSING_AFTER — present in BEFORE, absent from AFTER" "$MISSING" 0
  render "new_after"      "3️⃣  NEW_AFTER — present in AFTER, absent from BEFORE"     "$NEWA"    0
  render "fields_dropped" "4️⃣  FIELDS_DROPPED — tag keys lost on a matched file"     "$DROPPED" 1
  render "fields_gained"  "5️⃣  FIELDS_GAINED — tag keys added on a matched file"     "$GAINED"  1
  render "fields_changed" "6️⃣  FIELDS_CHANGED — tag values differing on a matched file" "$CHANGED" 1
fi

if [[ $SUMMARY_ONLY -eq 0 && ( "$DUPB" -gt 0 || "$DUPA" -gt 0 ) ]]; then
  echo "ℹ️  Duplicate audio_md5 under more than one path  (BEFORE: $DUPB, AFTER: $DUPA)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "   Informational: identical audio in two roots is exactly what the audio-stream key is"
  echo "   designed to expose (DUPE-01), not an error. This does not affect the exit code."
  jq -r '(.duplicates_before[] | [.audio_md5, "BEFORE", (.paths | join(" | "))] | @tsv),
         (.duplicates_after[]  | [.audio_md5, "AFTER",  (.paths | join(" | "))] | @tsv)' <<< "$RESULT" \
    | sed 's/^/  /'
  echo ""
fi

echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MATCHED:            $MATCHED"
echo "  MISSING_AFTER:      $MISSING"
echo "  NEW_AFTER:          $NEWA"
echo "  FIELDS_DROPPED:     $DROPPED"
echo "  FIELDS_GAINED:      $GAINED"
echo "  FIELDS_CHANGED:     $CHANGED"
echo ""
echo "  Matched files whose BEFORE tag set was empty: $NOFIELDS"
if [[ "$MATCHED" -gt 0 && "$NOFIELDS" -eq "$MATCHED" ]]; then
  echo -e "  ${YELLOW}⚠️  EVERY matched file had zero tag fields on the BEFORE side. \"No fields${NC}"
  echo -e "  ${YELLOW}    dropped\" is vacuously true here and proves nothing about metadata${NC}"
  echo -e "  ${YELLOW}    preservation. Read this result as untested, not as passed.${NC}"
fi
echo ""

if [[ "$MISSING" -eq 0 && "$DROPPED" -eq 0 ]]; then
  echo -e "${GREEN}✅ No net metadata loss (exit 0)${NC}"
  exit 0
fi
echo -e "${RED}❌ Net metadata loss detected: $MISSING file(s) missing, $DROPPED field(s) dropped (exit 1)${NC}"
exit 1
