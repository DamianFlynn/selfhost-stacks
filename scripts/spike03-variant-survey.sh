#!/usr/bin/env bash
# spike03-variant-survey.sh - Classify every audio-bearing backlog folder into exactly one tag
#                             variant stratum (V1..V6), and emit the per-stratum backlog weights
#                             that plan 03-07's weighted roll-up multiplies its rates by.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident rather than workstation-resident because it walks 8,500+ fenced JSON records
#   and enumerates three directory trees on `tank`; neither can be expressed as one ssh'd command.
#   Same convention as snapshot-music-tags.sh:5-9 and check-music-freeze.sh:5-12.
#
# Usage:
#   bash scripts/spike03-variant-survey.sh [--live] [--out FILE] [-h|--help]
#
#     --live       classify `unsorted` and `music` by spawning ffprobe over their audio files
#                  instead of reading Phase 1's QUAL-01 capture. Slower, same answer. See ROUTES.
#     --out FILE   override the NDJSON destination (default: $OUT below)
#
# Workflow:
#   ssh root@172.16.1.159
#   cd /mnt/fast/stacks && git pull --ff-only
#   bash scripts/spike03-variant-survey.sh
#   jq -s '[.[]|select(.tree=="dj-mixes")]|length' \
#     /mnt/fast/safety/music-pre-project/spike-03-variant-survey.ndjson
#
# Outputs (two files; the primary carries two clearly-marked record types):
#   $OUT           NDJSON. `record_type:"folder"` - one per audio-bearing folder, carrying its
#                  stratum, counts, artist histogram, format histogram and scan-bearing flag.
#                  `record_type:"stratum_weight"` - one per stratum, carrying `backlog_folders`
#                  and `backlog_weight` across the deduplicated backlog denominator.
#   ${OUT%.ndjson}-files.ndjson
#                  the per-FILE intermediate the folder records are aggregated from. Kept rather
#                  than deleted: it is the audit trail behind every count above, and keeping it
#                  is what lets this script hold a `rm`-free, `mv`-free body (see below).
#   Both are written to the FENCE, deliberately NOT into the repo: this repository has zero
#   committed non-Markdown data artefacts (03-PATTERNS.md sec. Blocking Findings 3), and the
#   machine-readable output belongs beside Phase 1's other captures. The committed artefact is
#   .planning/phases/03-tagger-spike/03-SAMPLE.md, written by hand from this output.
#
# NO REMOVE, NO RENAME, ANYWHERE IN THE BODY. There is no `mktemp`-plus-trap scratch dance and no
#   write-to-.tmp-then-rename, even though diff-music-tags.sh:103-112 establishes both as house
#   style. The reason is that the read-only contract on this script is asserted by a
#   comment-stripped grep for those four verbs, and a scratch-cleanup `rm` is indistinguishable
#   from a destructive one to that grep. Rather than weaken the assertion to accommodate a
#   convenience, the intermediate is promoted to a named output that is simply overwritten on
#   each run. A re-run is therefore idempotent and an interrupted run leaves both files readable
#   and obviously short rather than leaving a hidden dotfile behind.
#
# READ-ONLY BY CONTRACT (T-03-10). This script classifies; it never writes, moves, chowns, chmods
#   or snapshots anything under any scan root. It contains no `mv`, `rm`, `chown` or `chmod`
#   against `tank` or against the fence. The ONLY path it creates is its own $OUT file.
#   In the default route it performs NO new I/O against `tank` at all: every byte it reads comes
#   from Phase 1's captures under /mnt/fast/safety/music-pre-project/. `--live` is the exception
#   and is opt-in; even then ffprobe is read-only by construction.
#
# ROUTES, and why the default is not the one 03-03-PLAN.md specifies (recorded in place, not
#   silently changed - 03-PATTERNS.md sec. The script header block, habit 2):
#   The plan says `unsorted` "has no ffprobe fence, so for those folders run ffprobe read-only
#   over the audio files directly". That premise is wrong, and cheaply so. Phase 1's QUAL-01
#   capture at $QUAL01 holds the COMPLETE `-show_format -show_streams` output for all 9,736 files
#   across all four D-02 roots - `unsorted` (7,451) and `music` (277) included. It is the same
#   instrument, already fenced, already sha256'd in the fence MANIFEST, and reading it costs zero
#   new reads against `tank` where the live route costs 7,728 ffprobe spawns.
#   Both routes are implemented. The default is QUAL-01; `--live` forces ffprobe. Every folder
#   record carries `route` so a reader knows which machine-readable source produced it, which is
#   what the plan's "report which route produced each record" requirement is actually for.
#
# THE DENOMINATOR IS 144, NOT 143 (correction recorded in place, see 03-SAMPLE.md):
#   03-DECISION.md sec. Denominators commits "`music` 23 folders (275 files)" and a 143-folder
#   backlog. Two independent instruments disagree: a live audio-extension `find` on LXC 100 and
#   Phase 1's QUAL-01 NDJSON both return **24** audio-bearing folders and **277** files under
#   nzb/music. The backlog is therefore `unsorted` 120 + `music` 24 = **144** folders
#   (7,451 + 277 = 7,728 files). This script computes BACKLOG_DENOM from the data rather than
#   hard-coding it, and prints both the derived value and the superseded 143 so the correction
#   cannot pass unnoticed. The T1 threshold value (40%) is untouched by this; only a measured
#   fact is corrected, by a better instrument, before any rate exists.
#
# WHY `dj-mixes` IS EXCLUDED FROM THE WEIGHT DENOMINATOR:
#   `dj-mixes` is a byte-for-byte duplicate copy of a subset of `unsorted` - separate inodes,
#   link count 1 (03-RESEARCH.md finding 5). Counting it would double-weight the same audio and
#   silently inflate whichever strata the DJ content falls into. It is surveyed (it is where the
#   sample is drawn from) but it contributes 0 to `backlog_folders`.
#
# NO `find -xdev` ANYWHERE (03-RESEARCH.md Pitfall 3): /mnt/fast/appdata/* are 39 separate ZFS
#   datasets and a `-xdev` sweep from /mnt/fast silently skips them and exits 0. Every tree here
#   is enumerated by explicit path.
#
# EXIT-CODE CONVENTION (stated, not inherited - check-music-freeze.sh:31-38):
#   0  every audio-bearing folder classified into exactly one stratum
#   1  at least one folder classified into NO stratum - the rules do not cover the data and the
#      survey is not trustworthy. This is a hard failure, not a warning.
#   2  usage error, or a missing/unreadable fence or capture
#
# NOTHING is written to the system temp directory. On LXC 100 that directory is tmpfs backed by
#   host RAM and a 1.1 GB spill there previously took the whole 28 GB box down and killed sshd on
#   both the host and the container (T-03-12). Every byte this script writes lands beside $OUT,
#   which defaults into the fence under /mnt/fast.

set -euo pipefail

FENCE="${FENCE:-/mnt/fast/safety/music-pre-project/dj-mixes-ffprobe}"
QUAL01="${QUAL01:-/mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz}"
COVER_SCANS="${COVER_SCANS:-/mnt/fast/safety/music-pre-project/cover-scans}"
NZB="${NZB:-/mnt/tank/downloads/complete/nzb}"
OUT="${OUT:-/mnt/fast/safety/music-pre-project/spike-03-variant-survey.ndjson}"

# The two trees that form the deduplicated backlog denominator. `dj-mixes` is surveyed but
# deliberately absent from this list - see the header.
BACKLOG_TREES=(unsorted music)

# The superseded figure, kept so the correction is visible in the output rather than only in a
# planning document (03-PATTERNS.md sec. The script header block, habit 2).
SUPERSEDED_DENOM=143

# Identical to snapshot-music-tags.sh:94 deliberately: the survey and the capture must agree on
# what counts as audio or they cover different populations.
AUDIO_EXT=(mp3 wav flac m4a aiff aif wma ogg opus aac wv ape alac)

# Colors (check-music-freeze.sh:83-88)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LIVE=0

usage() {
  cat >&2 <<'EOF'
usage: bash scripts/spike03-variant-survey.sh [--live] [--out FILE]

  --live       classify unsorted/music with live ffprobe instead of the QUAL-01 capture
  --out FILE   NDJSON destination (default /mnt/fast/safety/music-pre-project/spike-03-variant-survey.ndjson)

exit 0 = every folder classified, 1 = an unclassified folder, 2 = usage or missing input
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --live)    LIVE=1; shift ;;
    --out)     [[ $# -ge 2 ]] || usage; OUT="$2"; shift 2 ;;
    -h|--help) grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         echo "unknown option: $1" >&2; usage ;;
  esac
done

fail() { echo -e "  ${RED}FAIL: $*${NC}" >&2; }
pass() { echo -e "  ${GREEN}$*${NC}"; }
warn() { echo -e "  ${YELLOW}WARN: $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "------------------------------------------------------------"; }

# --- preconditions (snapshot-music-tags.sh:146-155 guard shape) ---------------
MISSING_TOOLS=()
for t in jq gzip find sort awk; do
  command -v "$t" >/dev/null 2>&1 || MISSING_TOOLS+=("$t")
done
if [[ $LIVE -eq 1 ]]; then
  command -v ffprobe >/dev/null 2>&1 || MISSING_TOOLS+=("ffprobe")
fi
if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  fail "missing required tool(s): ${MISSING_TOOLS[*]}"
  echo "    This script installs nothing. Install them on LXC 100 and re-run." >&2
  exit 2
fi

if [[ ! -d "$FENCE" ]]; then
  fail "$FENCE does not exist"
  echo "    That is Phase 1's SAFE-03 capture, built by \`freeze-music-apply.sh fence\`." >&2
  echo "    Its absence means the dj-mixes half of this survey has no input. Refusing to" >&2
  echo "    report a partial census as a census." >&2
  exit 2
fi

if [[ $LIVE -eq 0 && ! -f "$QUAL01" ]]; then
  fail "$QUAL01 does not exist"
  echo "    That is Phase 1's QUAL-01 capture and the default route for unsorted/music." >&2
  echo "    Re-run with --live to classify those trees with ffprobe instead." >&2
  exit 2
fi

OUT_DIR="$(dirname "$OUT")"
[[ -d "$OUT_DIR" ]] || { fail "$OUT_DIR does not exist"; exit 2; }
[[ -w "$OUT_DIR" ]] || { fail "$OUT_DIR is not writable"; exit 2; }

# The per-file intermediate, beside the output, never in the system temp dir. A named output
# rather than a mktemp scratch: see the NO REMOVE, NO RENAME note in the header.
FLAT="${OUT%.ndjson}-files.ndjson"

echo "Phase 3 variant survey - folder to stratum, and the backlog weights"
rule
echo "  fence:       $FENCE"
echo "  qual01:      $QUAL01"
echo "  cover-scans: $COVER_SCANS"
echo "  nzb:         $NZB"
echo "  out:         $OUT"
echo "  route:       $([[ $LIVE -eq 1 ]] && echo 'live ffprobe (unsorted/music)' || echo 'QUAL-01 capture (unsorted/music)')"
echo "  host:        $(hostname)"
echo "  date:        $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- scan-bearing set (D-06 excludes these from the draw) ---------------------
# Two independent sources, unioned:
#   1. Phase 1's cover-scans fence - a directory per folder that had scans at fence time.
#   2. A live `.covers` subdirectory under the folder itself.
# Source 2 is a directory-listing probe only: no file content is read, nothing is written.
SCAN_FOLDERS="$(
  { [[ -d "$COVER_SCANS" ]] && find "$COVER_SCANS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' || true
    for t in dj-mixes "${BACKLOG_TREES[@]}"; do
      [[ -d "$NZB/$t" ]] || continue
      find "$NZB/$t" -mindepth 2 -maxdepth 2 -type d -name '.covers' -printf '%h\n' 2>/dev/null \
        | while IFS= read -r p; do basename "$p"; done
    done
  } | LC_ALL=C sort -u
)"
SCAN_COUNT="$(printf '%s' "$SCAN_FOLDERS" | grep -c . || true)"
info "scan-bearing folders (cover-scans fence union live .covers): $SCAN_COUNT"

SCAN_JSON="$(printf '%s\n' "$SCAN_FOLDERS" | jq -R -s 'split("\n") | map(select(length>0))')"

# --- stage 1: one flat record per audio file ---------------------------------
# {tree, folder, ext, album, artist, disc, tkey, energy, route}
# Keys are lower-cased before lookup: ffprobe emits `album`/`artist`/`disc`/`tkey`/`energylevel`
# for ID3 but container formats differ in casing, and a case-sensitive lookup would silently
# under-count FLAC/Vorbis sidecars.
FLATTEN_JQ='
  def norm_tags:
    ( ((.format.tags // {}) | to_entries
        | map({ key: (.key | ascii_downcase), value: (.value | tostring) }) )
      +
      ( [ .streams[]? | select(.codec_type == "audio") ]
        | map((.tags // {}) | to_entries
              | map({ key: (.key | ascii_downcase), value: (.value | tostring) }))
        | add // [] )
    ) | from_entries;
  def firstof($ks): . as $t | ($ks | map($t[.] // "") | map(select(. != "")) | .[0] // "");
  . as $probe
  | ($probe | norm_tags) as $t
  | ($probe.format.filename // "") as $fn
  | {
      path:   $fn,
      ext:    ( $fn | ascii_downcase | split(".") | if length > 1 then .[-1] else "" end ),
      album:  ( $t | firstof(["album"]) | gsub("^\\s+|\\s+$";"") ),
      artist: ( $t | firstof(["artist","album_artist","albumartist"]) | gsub("^\\s+|\\s+$";"") ),
      disc:   ( $t | firstof(["disc","discnumber","part"]) ),
      tkey:   ( $t | firstof(["tkey","initialkey","initial_key"]) ),
      energy: ( $t | firstof(["energylevel","energy_level","energy"]) )
    }
'

echo "==> stage 1: flattening the dj-mixes fence (route: fence)"
FENCE_JSON_COUNT="$(find "$FENCE" -type f -name '*.json' | wc -l | tr -d ' ')"
echo "    $FENCE_JSON_COUNT fenced ffprobe records"

# xargs batches the jq invocations rather than one process per file. `input_filename` is the
# fallback path source for any record whose format.filename is absent.
find "$FENCE" -type f -name '*.json' -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 -r jq -c --arg tree "dj-mixes" --arg fencedir "$FENCE" --arg route "fence" "
      ${FLATTEN_JQ}
      | . + { tree: \$tree, route: \$route,
              folder: ( if (.path | length) > 0
                        then (.path | split(\"/\") | .[-2])
                        else (input_filename | ltrimstr(\$fencedir + \"/\") | split(\"/\") | .[0])
                        end ) }
    " > "$FLAT"

FENCE_RECS="$(wc -l < "$FLAT" | tr -d ' ')"
pass "dj-mixes: $FENCE_RECS file records"

echo "==> stage 1: flattening $(printf '%s ' "${BACKLOG_TREES[@]}")(route: $([[ $LIVE -eq 1 ]] && echo live || echo qual01))"
if [[ $LIVE -eq 1 ]]; then
  # Live route. ffprobe is read-only by construction: no output file path is ever supplied.
  FIND_EXPR=( '(' )
  first=1
  for e in "${AUDIO_EXT[@]}"; do
    [[ $first -eq 0 ]] && FIND_EXPR+=( '-o' )
    FIND_EXPR+=( '-iname' "*.${e}" ); first=0
  done
  FIND_EXPR+=( ')' )
  for t in "${BACKLOG_TREES[@]}"; do
    [[ -d "$NZB/$t" ]] || { warn "$NZB/$t not present - skipping"; continue; }
    n=0
    while IFS= read -r f; do
      rel="${f#"$NZB/$t/"}"
      fld="${rel%%/*}"
      ffprobe -v quiet -print_format json -show_format -show_streams -- "$f" </dev/null \
        | jq -c --arg tree "$t" --arg folder "$fld" --arg route "live-ffprobe" \
            "${FLATTEN_JQ} | . + { tree: \$tree, folder: \$folder, route: \$route }" \
        >> "$FLAT" || { warn "ffprobe/jq failed on $f"; continue; }
      n=$((n+1))
    done < <(find "$NZB/$t" -type f "${FIND_EXPR[@]}" -print 2>/dev/null | LC_ALL=C sort)
    pass "$t: $n file records (live)"
  done
else
  # QUAL-01 route. The capture wraps each full ffprobe object under `.ffprobe`, with the original
  # path on `.source_path` and the scan root on `.scan_root` (snapshot-music-tags.sh:195-208).
  ROOTS_JSON="$(printf '%s\n' "${BACKLOG_TREES[@]}" \
    | while IFS= read -r t; do printf '%s/%s\n' "$NZB" "$t"; done \
    | jq -R -s 'split("\n") | map(select(length>0))')"
  BEFORE="$(wc -l < "$FLAT" | tr -d ' ')"
  gzip -cd -- "$QUAL01" \
    | jq -c --argjson roots "$ROOTS_JSON" --arg route "qual01" "
        select(.scan_root as \$r | \$roots | index(\$r))
        | { scan_root: .scan_root, source_path: .source_path } as \$meta
        | (.ffprobe | ${FLATTEN_JQ})
        | . + { path: (\$meta.source_path),
                ext: (\$meta.source_path | ascii_downcase | split(\".\") | if length > 1 then .[-1] else \"\" end),
                tree: (\$meta.scan_root | split(\"/\") | .[-1]),
                folder: (\$meta.source_path | ltrimstr(\$meta.scan_root + \"/\") | split(\"/\") | .[0]),
                route: \$route }
      " >> "$FLAT"
  AFTER="$(wc -l < "$FLAT" | tr -d ' ')"
  pass "unsorted+music: $((AFTER - BEFORE)) file records (QUAL-01)"
fi

TOTAL_RECS="$(wc -l < "$FLAT" | tr -d ' ')"
echo "    $TOTAL_RECS flat file records in total"
echo ""

# --- stage 2: aggregate per folder and classify ------------------------------
# The six strata, applied IN ORDER, first match wins (03-03-PLAN.md, 03-RESEARCH.md finding 4):
#   V3  album missing/empty in the MAJORITY of the folder's files. The only stratum whose
#       un-normalised Discogs rate is provably 0%: beets issues no query when artist and album
#       are both empty (beetsplug/discogs docs, quoted in 03-DECISION.md sec. OD-4).
#   V4  artist missing/empty in the majority (album present) - va_likely=true via
#       `not consensus["artist"]`.
#   V2  artist is VA / Various / Various Artists (case-insensitive) - flips va_likely via beets'
#       VA_ARTISTS tuple, making the query `"VA <album>"` rather than `<album>`.
#   V5  album present but NOISY - " WEB", " - Disc ", "Vol.", leading "Mastermix - ", a trailing
#       space, an underscore - OR DEGENERATE.
#       ** The DEGENERATE half is an addition, recorded here rather than applied silently. **
#       Degenerate means the folder's dominant `album` equals its dominant `artist` case-folded:
#       album "Mastermix" under artist "Mastermix". Measured live, 24 folders in `unsorted` are
#       in exactly that state - one sixth of the whole backlog. The narrow rule sorted every one
#       of them into V1, "the best case", because the value is present and carries none of the
#       six noise markers. It is the WORST case dressed as the best: a Discogs query for
#       `Mastermix` resolves the LABEL, not the release, so the folder returns a confident wrong
#       match rather than no match - the single outcome CLAUDE.md sec. Autotagging ceiling names as
#       worse than absence. The remedy is the same one V5 exists for and the same one D-08/OD-4
#       rule 1 specifies: derive `Mastermix Issue NNN` from the folder name. It is therefore a
#       V5, and moving it there shifts 24 folders of weight out of V1 - which is the number T1's
#       headline is most sensitive to.
#       The test is `album == artist`, not "album has no digits": most legitimate mainstream
#       album titles carry no digits, and that rule would have swallowed the entire bucket-A
#       population.
#   V1  ONE consistent non-placeholder artist across the folder, with a clean album.
#       ** WIDENED, deliberately, and recorded here rather than applied silently. **
#       03-03-PLAN.md defines V1 as `artist` exactly "Mastermix". That definition was derived
#       from dj-mixes, which is Mastermix-only, and it does not survive contact with the rest of
#       the backlog: a single-artist mainstream album (artist "Taylor Swift", clean album) then
#       matches NO stratum, and the plan requires an unclassified folder to be a hard failure.
#       03-DECISION.md's own V1 row states the functional definition - "va_likely=false, query =
#       album alone" - and a single consistent real artist is exactly that. On dj-mixes the
#       widened rule selects precisely the folders the narrow one did.
#   V6  real per-track artists: more than one distinct non-placeholder artist in the folder.
#       Also va_likely=false, but a different shape.
CLASSIFY_JQ='
  def isva($a): ($a | ascii_downcase) as $l
    | ($l == "va" or $l == "various" or $l == "various artists" or $l == "unknown");
  def noisy($s):
       ($s | test(" WEB"))
    or ($s | test(" - Disc "))
    or ($s | test("Vol\\."))
    or ($s | test("^Mastermix - "))
    or ($s | test(" $"))
    or ($s | test("_"));

  group_by([.tree, .folder])
  | map(
      . as $files
      | ($files | length) as $n
      | ($files[0].tree)   as $tree
      | ($files[0].folder) as $folder
      | ($files | map(select(.album  != "")) | length) as $has_album
      | ($files | map(select(.artist != "")) | length) as $has_artist
      | ($files | map(select(.disc   != "")) | length) as $has_disc
      | ($files | map(select(.tkey   != "")) | length) as $tkeyc
      | ($files | map(select(.energy != "")) | length) as $energyc
      | ($files | map(.artist) | map(select(. != "")) ) as $artists
      | ($artists | map(select(isva(.) | not)) | unique) as $real_artists
      | ($files | map(.album) | map(select(. != "")) ) as $albums
      | ( $artists | group_by(.) | map({key: .[0], value: length}) | from_entries ) as $artist_hist
      | ( $files | map(.ext) | group_by(.) | map({key: .[0], value: length}) | from_entries ) as $fmt_hist
      | ( $artists | group_by(.) | max_by(length) | (.[0] // "") ) as $dominant_artist
      | ( $albums  | group_by(.) | max_by(length) | (.[0] // "") ) as $dominant_album
      | ( $albums | map(select(noisy(.))) | length ) as $noisy_albums
      | ( ($dominant_album | length) > 0
          and ($dominant_album | ascii_downcase) == ($dominant_artist | ascii_downcase) )
        as $degenerate_album
      | {
          record_type: "folder",
          tree: $tree,
          folder: $folder,
          route: ($files[0].route),
          n_files: $n,
          has_album_count: $has_album,
          has_artist_count: $has_artist,
          has_disc_tag_count: $has_disc,
          tkey_count: $tkeyc,
          energylevel_count: $energyc,
          artist_values: $artist_hist,
          album_sample: $dominant_album,
          dominant_artist: $dominant_artist,
          distinct_real_artists: ($real_artists | length),
          fmt_histogram: $fmt_hist,
          scan_bearing: (($scan | index($folder)) != null),
          degenerate_album: $degenerate_album,
          stratum:
            ( if   ($has_album * 2) <= $n                       then "V3"
              elif ($has_artist * 2) <= $n                      then "V4"
              elif ($dominant_artist | length) > 0 and isva($dominant_artist) then "V2"
              elif (($noisy_albums * 2) > $n) or $degenerate_album then "V5"
              elif ($real_artists | length) == 1                then "V1"
              elif ($real_artists | length) > 1                 then "V6"
              else "UNCLASSIFIED" end )
        } )
  | sort_by(.tree, .folder)
'

echo "==> stage 2: aggregating and classifying"
jq -s --argjson scan "$SCAN_JSON" "$CLASSIFY_JQ" "$FLAT" | jq -c '.[]' > "$OUT"

FOLDER_COUNT="$(wc -l < "$OUT" | tr -d ' ')"
pass "$FOLDER_COUNT folder records classified"

# --- stage 3: per-stratum backlog weights ------------------------------------
# `dj-mixes` contributes 0 - it duplicates `unsorted` byte-for-byte and counting it would
# double-weight the same audio. The denominator is DERIVED from the classified data, never
# hard-coded, so a change in the backlog cannot leave a stale constant behind.
BACKLOG_DENOM="$(jq -s --argjson trees "$(printf '%s\n' "${BACKLOG_TREES[@]}" | jq -R -s 'split("\n")|map(select(length>0))')" \
  '[ .[] | select(.record_type=="folder") | select(.tree as $t | $trees | index($t)) ] | length' \
  "$OUT")"

if [[ "$BACKLOG_DENOM" -eq 0 ]]; then
  fail "backlog denominator is 0 - no folder classified in ${BACKLOG_TREES[*]}"
  echo "    $OUT holds the folder records that were classified; inspect it before re-running." >&2
  exit 1
fi

# Computed into a variable and only then appended. A `jq ... "$OUT" | ... >> "$OUT"` pipeline
# would have the shell open the append handle before jq had finished reading, which is a race
# against the very file being read.
WEIGHT_RECORDS="$(jq -s \
  --argjson trees "$(printf '%s\n' "${BACKLOG_TREES[@]}" | jq -R -s 'split("\n")|map(select(length>0))')" \
  --argjson denom "$BACKLOG_DENOM" \
  --argjson superseded "$SUPERSEDED_DENOM" '
    [ .[] | select(.record_type=="folder") ] as $all
    | [ $all[] | select(.tree as $t | $trees | index($t)) ] as $backlog
    | ($all | map(.stratum) | unique) as $strata
    | $strata
    | map( . as $s
      | { record_type: "stratum_weight",
          stratum: $s,
          backlog_folders: ( [ $backlog[] | select(.stratum == $s) ] | length ),
          backlog_weight:  ( ( [ $backlog[] | select(.stratum == $s) ] | length ) / $denom
                             * 10000 | round / 10000 ),
          backlog_denominator: $denom,
          superseded_denominator: $superseded,
          excluded_from_denominator: "dj-mixes (byte-for-byte duplicate subset of unsorted)",
          surveyed_folders: ( [ $all[] | select(.stratum == $s) ] | length ) } )
    | .[]
  ' "$OUT" | jq -c .)"
printf '%s\n' "$WEIGHT_RECORDS" >> "$OUT"

# --- summary ------------------------------------------------------------------
echo ""
echo "Summary"
rule
UNCLASSIFIED="$(jq -s '[.[]|select(.record_type=="folder")|select(.stratum=="UNCLASSIFIED")]|length' "$OUT")"

# Columns: `folders`/`files`/`wav` are over ALL surveyed trees; `backlog`/`weight` are over the
# deduplicated denominator only; `dj_elig` is the dj-mixes folders that are NOT scan-bearing, i.e.
# the population the draw in 03-SAMPLE.md is actually taken from.
printf '  %-6s %-9s %-9s %-9s %-9s %-9s %-9s %-9s\n' \
  stratum folders files wav backlog weight dj_all dj_elig
jq -sr '
  [.[]|select(.record_type=="folder")] as $f
  | [.[]|select(.record_type=="stratum_weight")] as $w
  | ($f | group_by(.stratum) | map({s:.[0].stratum, n:length,
        files:(map(.n_files)|add),
        wav:(map(.fmt_histogram.wav // 0)|add),
        dj_all:(map(select(.tree=="dj-mixes"))|length),
        dj_elig:(map(select(.tree=="dj-mixes" and (.scan_bearing|not)))|length)}))
    as $g
  | $g[] as $row
  | ($w[] | select(.stratum == $row.s)) as $ww
  | [$row.s, $row.n, $row.files, $row.wav, $ww.backlog_folders, $ww.backlog_weight,
     $row.dj_all, $row.dj_elig]
  | @tsv' "$OUT" \
| while IFS=$'\t' read -r s n files wav bf bw dja dje; do
    printf '  %-6s %-9s %-9s %-9s %-9s %-9s %-9s %-9s\n' \
      "$s" "$n" "$files" "$wav" "$bf" "$bw" "$dja" "$dje"
  done

echo "  --------------------------------------------------------"
jq -sr '
  [.[]|select(.record_type=="folder")] as $f
  | [.[]|select(.record_type=="stratum_weight")] as $w
  | "  folders surveyed:      \($f|length)",
    "  dj-mixes folders:      \([$f[]|select(.tree=="dj-mixes")]|length)   files: \([$f[]|select(.tree=="dj-mixes")|.n_files]|add)",
    "  unsorted folders:      \([$f[]|select(.tree=="unsorted")]|length)   files: \([$f[]|select(.tree=="unsorted")|.n_files]|add)",
    "  music folders:         \([$f[]|select(.tree=="music")]|length)   files: \([$f[]|select(.tree=="music")|.n_files]|add)",
    "  WAV files (all trees): \([$f[]|.fmt_histogram.wav // 0]|add)",
    "  WAV files (dj-mixes):  \([$f[]|select(.tree=="dj-mixes")|.fmt_histogram.wav // 0]|add)",
    "  scan-bearing records:  \([$f[]|select(.scan_bearing)]|length)  (dj-mixes \([$f[]|select(.scan_bearing and .tree=="dj-mixes")]|length), unsorted \([$f[]|select(.scan_bearing and .tree=="unsorted")]|length))",
    "  dj-mixes ELIGIBLE:     \([$f[]|select(.tree=="dj-mixes" and (.scan_bearing|not))]|length)  (the population the 20-folder draw comes from)",
    "  degenerate album=artist: \([$f[]|select(.degenerate_album)]|length) folder(s) - see the V5 note in this script",
    "  backlog denominator:   \($w[0].backlog_denominator)",
    "  sum(backlog_folders):  \([$w[]|.backlog_folders]|add)",
    "  sum(backlog_weight):   \([$w[]|.backlog_weight]|add)"
  ' "$OUT"

echo ""
DERIVED_DENOM="$BACKLOG_DENOM"
if [[ "$DERIVED_DENOM" -ne "$SUPERSEDED_DENOM" ]]; then
  warn "backlog denominator is $DERIVED_DENOM, superseding the $SUPERSEDED_DENOM committed in"
  echo "        03-DECISION.md sec. Denominators. Two independent instruments agree on the new" >&2
  echo "        figure (a live audio-extension find, and Phase 1's QUAL-01 capture). The T1" >&2
  echo "        threshold VALUE (40%) is unaffected - only a measured fact is corrected, and it" >&2
  echo "        is corrected before any rate exists. Record the retraction in 03-SAMPLE.md." >&2
fi

echo ""
echo "  ndjson: $OUT"
echo "  cost:   this run issued ZERO Discogs requests, added ZERO folders to the draw, and"
echo "          wrote nothing under any scan root. The weighted estimator is arithmetic over"
echo "          data the phase already had to collect."
echo ""

if [[ "$UNCLASSIFIED" -gt 0 ]]; then
  fail "$UNCLASSIFIED folder(s) matched NO stratum - the classifier does not cover the data"
  jq -sr '.[]|select(.record_type=="folder")|select(.stratum=="UNCLASSIFIED")|"    \(.tree)/\(.folder)"' "$OUT" >&2
  exit 1
fi

pass "every audio-bearing folder carries exactly one stratum"
exit 0
