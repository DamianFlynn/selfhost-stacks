#!/usr/bin/env bash
# phase05-now-tag-inventory.sh - Regenerate the `Now! 1-115` tag inventory DURABLY, and reconcile
#                                it per volume against the collection's own m3u manifest.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident rather than workstation-resident because `scan` reads 45 GB off `tank` and spawns
#   one process per file; it cannot be expressed as one ssh'd command. Same convention as
#   scripts/snapshot-music-tags.sh, scripts/freeze-music-apply.sh and scripts/setup-mpe.sh.
#
# Usage:
#   bash scripts/phase05-now-tag-inventory.sh scan        # per-file ffprobe inventory + manifest parse
#   bash scripts/phase05-now-tag-inventory.sh reconcile    # derived lists + the per-volume identity
#   bash scripts/phase05-now-tag-inventory.sh --help
#
# Outputs, ALL of them under $OUT_DIR:
#   now-tags.ndjson          one JSON object per mp3: path, basename, size, the whole downcased tag
#                            dict, and the parsed disc/track numbers and totals
#   now-tags.done            completed-paths ledger - the resume mechanism
#   now-tags.failed          path<TAB>stage<TAB>exit-code, retried on the next run
#   now-manifest.ndjson      one JSON object per m3u entry: the line, its path components, the
#                            volume directory as the original rip had it, any CD subdirectory, the leaf
#   now-volume-dirnames.txt  the distinct manifest volume-directory names, one per line, UNPARSED
#   now-album-values.tsv     count<TAB>album, the distinct album strings with their file counts
#   now-reconciliation.txt   the per-volume `files_present == sum of tracktotal` report
#
# WHY THIS EXISTS: the original scan was written to the system temp directory on LXC 100, which is
#   tmpfs backed by host RAM, and it is gone. NOTHING this script writes goes there - a 1.1 GB file
#   staged there once took the whole 28 GB box down and killed ssh on the host AND the container.
#   Every byte lands under /mnt/fast. Note /mnt/fast/safety is NOT on the fast ZFS pool: only the
#   `mp` entries in /etc/pve/lxc/100.conf are real bind mounts, so this output lands on LXC 100's
#   126 G ext4 root. Watch `df -h /`, not the pool. The output is a few MB, so the constraint is
#   real but not binding.
#
# THE KEY (one ffprobe per file, never batched): ffprobe takes ONE input file. A scan built with
#   `xargs -n 50 ffprobe` silently produces nothing and exits clean - it cost a wasted pass during
#   the phase discussion. The loop below invokes ffprobe once per file, with a redirect from
#   /dev/null so it cannot swallow the loop's stdin, and a bare double dash before the path.
#
# RECORDS ARE BUILT BY jq, NEVER BY STRING CONCATENATION. Album values in this collection contain
#   commas, exclamation marks and a DOUBLE SPACE (`...! Vol.36  CD2`), and a TSV of them is one
#   stray tab from silent misalignment. The TSV outputs are generated FROM the NDJSON by `jq @tsv`,
#   which ESCAPES an embedded tab rather than emitting it, so the downstream awk cannot misalign.
#
# DISC AND TRACK ARE NORMALISED EXPLICITLY. The measured distinct disc formats are only three -
#   "1/2", "2/2" and "1/1" - so the "N/M" form is parsed into a number and a total, and the same is
#   done for track. BOTH the raw string and the parsed integers are recorded. Where a total is
#   absent the record carries null, never a guess: a null must never silently become a zero in a
#   later sum, so `reconcile` counts nulls and reports them separately.
#
# RESUMABILITY: the done ledger, not a re-scan of the NDJSON. It is loaded once into an associative
#   array on start and any path already present is skipped. Ordering within a file is: emit the
#   NDJSON line, THEN append to the done ledger. A hard kill in that window re-emits ONE record on
#   the next run; it never loses one. A file whose ffprobe exits non-zero goes to the FAILED ledger
#   and is NOT written to done, so a re-run retries it rather than permanently skipping it.
#   A raising file is NEVER counted as "no change": conflating an exception with a no-op result is
#   precisely how Phase 1 produced six unearned passes (scripts/normalise-dj-tags.py:66-75).
#
# THE MANIFEST IS CP1252, AND THAT IS LOAD-BEARING. The m3u was written by a Windows ripper. Read
#   as raw bytes only 4,646 of its 4,746 distinct leaf names match a file on disk; decoded from
#   CP1252 to UTF-8, 4,744 do. The two that still do not are Hangul and a Greek capital lambda,
#   which the ripper wrote as literal `?` - genuinely lossy and not recoverable by any decoding.
#   `reconcile` therefore joins in two stages and reports the second stage's size explicitly.
#
# THE VOLUME DIRECTORY IS FOUND FROM THE END OF THE PATH, NOT FROM THE START. The m3u carries
#   THREE path shapes: `..\ROOT\VOL\CDn\leaf` (4,706 lines), `..\ROOT\VOL\leaf` (57 lines, the
#   single-CD rare pressings, which have no CD subdirectory at all) and
#   `Z:\Nieuwetorrent2023\ROOT\VOL\CDn\leaf` (7 lines). A fixed field index is therefore wrong on
#   64 lines and would silently name the collection root as a volume. The rule used instead: the
#   LAST component is the leaf; if the one before it matches `^CD[0-9]+$` it is the CD directory
#   and the volume directory is the one before THAT; otherwise the volume directory is the one
#   immediately before the leaf. The m3u uses BACKSLASH separators, so the split is on backslash.
#
# NO VOLUME NUMBER IS DERIVED ANYWHERE IN THIS SCRIPT, from the album string or from anything else.
#   D-03 is a MEASURED trap: volume 1 is tagged `Now That's What I Call Music` with no number at
#   all, volume 2 is `Now, That's What I Call Music II` (a Roman numeral, and a comma), and volume
#   36 is split across three spellings - `...! Vol.36 CD1` on 16 files, `...! Vol.36  CD2` on 20
#   files WITH A DOUBLE SPACE, and `...! 36` on 4 files. `...Vol.36 CD1` ends in 1 and
#   `...Vol.36  CD2` ends in 2, so a trailing-number regex silently misfiles 36 tracks into volumes
#   1 and 2. It exits 0 and it looks right. Grouping here is by the manifest volume directory only.
#   Turning that list into volume NUMBERS is plan 05-06's job, under operator review.
#
# READ-ONLY AGAINST THE COLLECTION. This script does not write, move, rename or delete anything
#   under NOW_ROOT. It contains no chown, chmod, mv or rm against any path under it, and no
#   write-mode redirect targets one. NOW_ROOT is resolved and refused unless it is
#   /mnt/tank/downloads/complete/nzb/unsorted or a descendant.
#
# EXIT-CODE CONVENTION (stated here deliberately, not inherited - the estate has no single one):
#   scan       0  every file produced a record AND the failed ledger is empty
#              1  at least one file failed and is named in the failed ledger
#              2  usage error, or NOW_ROOT / MANIFEST is absent, or NOW_ROOT is outside the fence
#   reconcile  0  the report was produced and every disk file joined to at least one volume
#              1  at least one disk file could not be joined, or a required input is unreadable
#              2  usage error, or the scan outputs do not exist
#
# Idempotent: safe to interrupt at any point and safe to re-run immediately. A re-run with nothing
#   left to do processes 0 files and rewrites nothing but the manifest and the derived reports.

set -euo pipefail

NOW_ROOT="${NOW_ROOT:-/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023}"
REQUIRED_ROOT="${REQUIRED_ROOT:-/mnt/tank/downloads/complete/nzb/unsorted}"
OUT_DIR="${OUT_DIR:-/mnt/fast/safety/phase05}"

NDJSON="${OUT_DIR}/now-tags.ndjson"
DONE_LEDGER="${OUT_DIR}/now-tags.done"
FAILED_LEDGER="${OUT_DIR}/now-tags.failed"
# NOT written as `${MANIFEST_NAME:-...}`: a single quote inside the word part of a `:-` expansion,
# itself inside double quotes, opens a quoted section in bash and swallows the rest of the file.
# The manifest's own name contains an apostrophe, so the two-line form is the correct one here.
MANIFEST_NAME="${MANIFEST_NAME:-}"
[[ -n "$MANIFEST_NAME" ]] || MANIFEST_NAME="00.Now That's What I Call Music! 1-115(2023).m3u"
MANIFEST="${NOW_ROOT}/${MANIFEST_NAME}"
MANIFEST_NDJSON="${OUT_DIR}/now-manifest.ndjson"
VOLUME_DIRNAMES="${OUT_DIR}/now-volume-dirnames.txt"
ALBUM_VALUES="${OUT_DIR}/now-album-values.tsv"
RECONCILIATION="${OUT_DIR}/now-reconciliation.txt"

PROGRESS_EVERY=250
WORK_DIR=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
banner() { echo ""; echo "=================================================="; echo "  $1"; echo "=================================================="; }

usage() {
  echo "usage: bash scripts/phase05-now-tag-inventory.sh {scan|reconcile}" >&2
  echo "       bash scripts/phase05-now-tag-inventory.sh --help" >&2
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
  scan|reconcile) ;;
  *) usage ;;
esac

# ─── the scope fence (T-05-05-01) ─────────────────────────────────────────────
# Refusal, not a fallback, and checked FIRST - before the tool probe - so it is reachable and
# testable anywhere, including on a workstation that has none of this content and none of ffprobe.
# `realpath -m` resolves a path that need not exist, so a typo is refused rather than crashing;
# where realpath is absent the given path is used verbatim, which can only make the fence STRICTER.
# Written INLINE rather than in a function: `exit` inside a command substitution leaves only the
# subshell, and a fence that depends on `set -e` to propagate is a fence one edit from silence.
NOW_ROOT_REAL="$(realpath -m -- "$NOW_ROOT" 2>/dev/null || printf '%s' "$NOW_ROOT")"
REQUIRED_REAL="$(realpath -m -- "$REQUIRED_ROOT" 2>/dev/null || printf '%s' "$REQUIRED_ROOT")"
if [[ "$NOW_ROOT_REAL" != "$REQUIRED_REAL" && "$NOW_ROOT_REAL" != "$REQUIRED_REAL"/* ]]; then
  echo -e "${RED}REFUSING TO RUN: NOW_ROOT is outside the Now! collection's tree.${NC}" >&2
  echo "  given:    $NOW_ROOT" >&2
  echo "  resolved: $NOW_ROOT_REAL" >&2
  echo "  required: $REQUIRED_REAL (or a descendant)" >&2
  echo "  This tool is read-only, but a wrong root would produce an inventory that silently" >&2
  echo "  describes the wrong 45 GB of content. Refusing to guess." >&2
  exit 2
fi
NOW_ROOT="$NOW_ROOT_REAL"
MANIFEST="${NOW_ROOT}/${MANIFEST_NAME}"

# ─── preconditions ────────────────────────────────────────────────────────────
MISSING_TOOLS=()
for t in ffprobe jq awk find stat sort iconv; do
  command -v "$t" >/dev/null 2>&1 || MISSING_TOOLS+=("$t")
done
if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  fail "missing required tool(s): ${MISSING_TOOLS[*]}"
  echo "    This script installs nothing. Install them on LXC 100 and re-run." >&2
  exit 2
fi

mkdir -p -- "$OUT_DIR"

# ─── the record ───────────────────────────────────────────────────────────────
# emit_record PATH BASENAME SIZE MTIME  <  ffprobe JSON on stdin
# jq builds the whole line; the ffprobe output arrives as `.` and every value is embedded by jq,
# never by string concatenation, so unbalanced quotes, newlines and unicode inside a third-party
# tag value cannot corrupt the stream.
#
# `split2` parses the "N/M" form. A missing or unparsable total yields null, NEVER 0 - `reconcile`
# counts nulls on their own line so an absent total cannot be summed as a zero.
emit_record() {
  jq -c \
    --arg path     "$1" \
    --arg basename "$2" \
    --argjson size_bytes  "$3" \
    --argjson mtime_epoch "$4" '
    def split2:
      if . == null then {n: null, t: null}
      else (tostring
            | (capture("^[[:space:]]*(?<n>[0-9]+)[[:space:]]*(?:/[[:space:]]*(?<t>[0-9]+))?[[:space:]]*$") // null)) as $c
        | if $c == null then {n: null, t: null}
          else {n: ($c.n | tonumber),
                t: (if ($c.t // "") == "" then null else ($c.t | tonumber) end)}
          end
      end;
    def num: if . == null or . == "" then null
             else (tostring | (capture("^[[:space:]]*(?<v>[0-9]+)") // null)) as $c
                  | if $c == null then null else ($c.v | tonumber) end
             end;
    . as $probe
    | ((reduce ($probe.streams[]? | .tags // {}) as $t ({}; . + $t)) + ($probe.format.tags // {}))
      | with_entries(.key |= ascii_downcase) as $tags
    | ($tags.disc  // $tags.discnumber  // $tags.part_of_a_set // $tags.tpos) as $disc_raw
    | ($tags.track // $tags.tracknumber // $tags.trck)                       as $track_raw
    | ($disc_raw  | split2) as $d
    | ($track_raw | split2) as $k
    | {path:        $path,
       basename:    $basename,
       size_bytes:  $size_bytes,
       mtime_epoch: $mtime_epoch,
       album:        $tags.album,
       album_artist: $tags.album_artist,
       artist:       $tags.artist,
       title:        $tags.title,
       disc_raw:     (if $disc_raw  == null then null else ($disc_raw  | tostring) end),
       track_raw:    (if $track_raw == null then null else ($track_raw | tostring) end),
       disc_number:  $d.n,
       disc_total:   ($d.t  // (($tags.disctotal  // $tags.totaldiscs)  | num)),
       track_number: $k.n,
       track_total:  ($k.t  // (($tags.tracktotal // $tags.totaltracks) | num)),
       format_name:  $probe.format.format_name,
       duration:     $probe.format.duration,
       tags:         $tags}'
}

# ─── manifest parse ───────────────────────────────────────────────────────────
# Rebuilt on every scan: it is one 1 MB file read, so a resume ledger would cost more than it saves.
# The decode is CP1252 -> UTF-8 (see the header). `raw` carries the DECODED line; the record states
# the decoding rather than pretending the bytes on disk were UTF-8.
parse_manifest() {
  local n
  iconv -f CP1252 -t UTF-8 -- "$MANIFEST" \
    | tr -d '\r' \
    | jq -R -c '
        select(length > 0) | select(startswith("#") | not)
        | . as $raw
        | ($raw | split("\\")) as $c
        | ($c | length) as $n
        | ($c[$n-1]) as $leaf
        | (if $n >= 2 and ($c[$n-2] | test("^CD[0-9]+$")) then $c[$n-2] else null end) as $cd
        | (if $cd == null
           then (if $n >= 2 then $c[$n-2] else null end)
           else (if $n >= 3 then $c[$n-3] else null end) end) as $vol
        | {raw: $raw,
           decoded_from: "CP1252",
           components: $c,
           component_count: $n,
           volume_dir: $vol,
           cd_dir: $cd,
           leaf: $leaf}' > "$MANIFEST_NDJSON"
  n="$(wc -l < "$MANIFEST_NDJSON" | tr -d '[:space:]')"
  printf '%s' "$n"
}

# ══════════════════════════════════════════════════════════════════════════════
do_scan() {
  banner "phase05-now-tag-inventory scan"
  echo "  now root:  $NOW_ROOT"
  echo "  manifest:  $MANIFEST"
  echo "  ndjson:    $NDJSON"
  echo "  done:      $DONE_LEDGER"
  echo "  failed:    $FAILED_LEDGER"
  echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -d "$NOW_ROOT" ]]; then
    fail "NOW_ROOT does not exist: $NOW_ROOT"; exit 2
  fi
  if [[ ! -f "$MANIFEST" ]]; then
    fail "MANIFEST does not exist: $MANIFEST"; exit 2
  fi

  # ── fresh measurement, stated rather than inherited ────────────────────────
  # The tree is live and every count in 05-PREMEASURE.md and 05-CONTEXT.md will have drifted.
  local mp3_count nonmp3_count subdir_count
  mp3_count="$(find "$NOW_ROOT" -maxdepth 1 -type f -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')"
  nonmp3_count="$(find "$NOW_ROOT" -maxdepth 1 -type f ! -iname '*.mp3' -printf '.' | wc -c | tr -d '[:space:]')"
  subdir_count="$(find "$NOW_ROOT" -mindepth 1 -type d -printf '.' | wc -c | tr -d '[:space:]')"
  echo ""
  echo "==> Fresh measurement (a point-in-time snapshot of a live tree)"
  echo "    mp3 files:      $mp3_count      (2026-09-18 value: 4746)"
  echo "    non-mp3 files:  $nonmp3_count      (2026-09-18 value: 14; the 05-04 sweep removed 9, so 5 is expected)"
  echo "    subdirectories: $subdir_count      (2026-09-18 value: 0)"

  mapfile -t FILES < <(find "$NOW_ROOT" -maxdepth 1 -type f -iname '*.mp3' -print | LC_ALL=C sort)
  echo "    file list:      ${#FILES[@]} path(s) to consider"

  # ── resume ledger ──────────────────────────────────────────────────────────
  declare -A DONE_MAP=()
  local loaded=0 p
  if [[ -f "$DONE_LEDGER" ]]; then
    while IFS= read -r p; do
      [[ -z "$p" ]] && continue
      DONE_MAP["$p"]=1
      loaded=$((loaded + 1))
    done < "$DONE_LEDGER"
  fi
  echo "==> Resume ledger: $loaded path(s) already captured"
  [[ -f "$DONE_LEDGER" ]] || : > "$DONE_LEDGER"

  # The failed ledger is rebuilt each run: a file that failed last time is retried, and if it now
  # succeeds it must not stay on the list. Anything still failing is re-appended below.
  : > "$FAILED_LEDGER"

  local seen=0 new=0 skip=0 failed=0 f st size mtime line rc bn
  local start; start=$(date +%s)
  for f in "${FILES[@]}"; do
    seen=$((seen + 1))
    if [[ -n "${DONE_MAP["$f"]:-}" ]]; then
      skip=$((skip + 1))
    else
      st="$(stat -c '%s %Y' -- "$f" 2>/dev/null || echo '')"
      if [[ -z "$st" ]]; then
        printf '%s\tstat\t1\n' "$f" >> "$FAILED_LEDGER"; failed=$((failed + 1)); continue
      fi
      size="${st%% *}"; mtime="${st##* }"
      bn="$(basename -- "$f")"

      # ONE ffprobe, ONE input file. `</dev/null` so it cannot swallow this loop's stdin, and a
      # bare `--` before the path so a name beginning with a dash is a path, not an option.
      line=""; rc=0
      line="$(ffprobe -v quiet -print_format json -show_format -show_streams -- "$f" </dev/null \
              | emit_record "$f" "$bn" "$size" "$mtime")" || rc=$?
      if [[ $rc -ne 0 ]]; then
        printf '%s\tffprobe-or-jq\t%s\n' "$f" "$rc" >> "$FAILED_LEDGER"; failed=$((failed + 1)); continue
      fi
      if [[ -z "$line" ]]; then
        printf '%s\tempty-record\t1\n' "$f" >> "$FAILED_LEDGER"; failed=$((failed + 1)); continue
      fi

      # Flush the record FIRST, then the ledger. A hard kill between the two re-emits one record
      # on resume; it never loses one.
      printf '%s\n' "$line" >> "$NDJSON"
      printf '%s\n' "$f" >> "$DONE_LEDGER"
      DONE_MAP["$f"]=1
      new=$((new + 1))
    fi
    if (( seen % PROGRESS_EVERY == 0 )); then
      printf '    %5d/%-5d  new=%-5d skipped=%-5d failed=%d\n' "$seen" "${#FILES[@]}" "$new" "$skip" "$failed"
    fi
  done
  local secs=$(( $(date +%s) - start )); [[ $secs -eq 0 ]] && secs=1

  echo ""
  echo "==> Parsing the manifest"
  local mentries
  mentries="$(parse_manifest)"
  echo "    manifest entries: $mentries      (2026-09-18 value: 4770)"
  echo "    manifest ndjson:  $MANIFEST_NDJSON"

  echo ""
  echo "📊 scan summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  files seen:      $seen"
  echo "  records written: $new"
  echo "  skipped (done):  $skip"
  echo "  failed:          $failed"
  echo "  wall clock:      ${secs}s"
  echo "  ndjson lines:    $(wc -l < "$NDJSON" | tr -d '[:space:]')"
  echo "  done ledger:     $(wc -l < "$DONE_LEDGER" | tr -d '[:space:]')"

  if [[ $failed -gt 0 ]]; then
    fail "$failed file(s) failed and were NOT written to the done ledger - re-run to retry them"
    echo "    failed ledger: $FAILED_LEDGER" >&2
    return 1
  fi
  pass "scan complete, failed ledger empty"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════════
do_reconcile() {
  banner "phase05-now-tag-inventory reconcile"
  if [[ ! -s "$NDJSON" ]]; then
    fail "$NDJSON is missing or empty - run \`scan\` first"; exit 2
  fi
  if [[ ! -s "$MANIFEST_NDJSON" ]]; then
    fail "$MANIFEST_NDJSON is missing or empty - run \`scan\` first"; exit 2
  fi

  # Scratch lives beside the outputs, inside /mnt/fast - never the system temp directory - and is
  # removed by an EXIT trap. WORK_DIR is deliberately GLOBAL: a `local` would be out of scope by
  # the time the trap fires, and under `set -u` the trap would then fail instead of cleaning up.
  WORK_DIR="${OUT_DIR}/.reconcile.$$"
  local work="$WORK_DIR"
  mkdir -p -- "$work"
  trap '{ test -n "${WORK_DIR:-}" && test -d "$WORK_DIR" && rm -r -- "$WORK_DIR"; } || true' EXIT

  # jq @tsv ESCAPES an embedded tab rather than emitting one, so awk -F'\t' cannot misalign here.
  # awk -F'\t' is used throughout and NEVER `IFS=$'\t' read`: tab is an IFS whitespace character,
  # so `read` collapses runs of tabs and an empty field silently vanishes.
  jq -r '[.basename, (.album // ""), (.disc_number // ""), (.disc_total // ""),
          (.track_number // ""), (.track_total // "")] | @tsv' "$NDJSON" > "$work/tags.tsv"
  jq -r '[.leaf, (.volume_dir // ""), (.cd_dir // "")] | @tsv' "$MANIFEST_NDJSON" > "$work/man.tsv"

  local tag_rows man_rows
  tag_rows="$(wc -l < "$work/tags.tsv" | tr -d '[:space:]')"
  man_rows="$(wc -l < "$work/man.tsv" | tr -d '[:space:]')"

  # Field-count assertion: the 05-03/05-04 harnesses lost real time to separators that did not
  # survive quoting. Assert the shape before trusting a single number derived from it.
  local bad_tag bad_man
  bad_tag="$(awk -F'\t' 'NF!=6' "$work/tags.tsv" | wc -l | tr -d '[:space:]')"
  bad_man="$(awk -F'\t' 'NF!=3' "$work/man.tsv" | wc -l | tr -d '[:space:]')"
  [[ "$bad_tag" == "0" ]] || { fail "tags.tsv: $bad_tag row(s) do not have 6 fields"; return 1; }
  [[ "$bad_man" == "0" ]] || { fail "man.tsv: $bad_man row(s) do not have 3 fields"; return 1; }

  # ── the distinct lists ─────────────────────────────────────────────────────
  awk -F'\t' '{print $2}' "$work/man.tsv" | LC_ALL=C sort -u > "$VOLUME_DIRNAMES"
  awk -F'\t' '{c[$2]++} END {for (a in c) printf "%d\t%s\n", c[a], a}' "$work/tags.tsv" \
    | LC_ALL=C sort -rn > "$ALBUM_VALUES"

  local vol_dirs album_vals
  vol_dirs="$(wc -l < "$VOLUME_DIRNAMES" | tr -d '[:space:]')"
  album_vals="$(wc -l < "$ALBUM_VALUES" | tr -d '[:space:]')"

  # ── the join, in two stages ────────────────────────────────────────────────
  # Stage 1: exact leaf == basename. Stage 2 (residuals only): an alphanumerics-only key, because
  # the ripper wrote Hangul and a Greek lambda as literal `?`. A stage-2 match is accepted ONLY if
  # it is unique on both sides; anything ambiguous is reported unresolved, never guessed.
  awk -F'\t' -v OFS='\t' '
    NR==FNR { leaf[$1]=1; next }
    { if ($1 in leaf) print $1, "exact"; else print $1, "residual" }
  ' "$work/man.tsv" "$work/tags.tsv" > "$work/stage1.tsv"

  awk -F'\t' '$2=="residual" {print $1}' "$work/stage1.tsv" | LC_ALL=C sort -u > "$work/disk_residual.txt"
  awk -F'\t' 'NR==FNR {have[$1]=1; next} !($1 in have) {print $1}' \
      "$work/tags.tsv" "$work/man.tsv" | LC_ALL=C sort -u > "$work/man_residual.txt"

  # alnum key for both residual sets
  awk '{k=$0; gsub(/[^A-Za-z0-9]/,"",k); printf "%s\t%s\n", k, $0}' "$work/disk_residual.txt" > "$work/disk_res_k.tsv"
  awk '{k=$0; gsub(/[^A-Za-z0-9]/,"",k); printf "%s\t%s\n", k, $0}' "$work/man_residual.txt"  > "$work/man_res_k.tsv"

  awk -F'\t' -v OFS='\t' '
    NR==FNR { n[$1]++; v[$1]=$2; next }
    { if (n[$1]==1) print $2, v[$1], "alnum"; else print $2, "", "unresolved" }
  ' "$work/man_res_k.tsv" "$work/disk_res_k.tsv" > "$work/stage2.tsv"

  local n_exact n_alnum n_unresolved
  n_exact="$(awk -F'\t' '$2=="exact"' "$work/stage1.tsv" | wc -l | tr -d '[:space:]')"
  n_alnum="$(awk -F'\t' '$3=="alnum"' "$work/stage2.tsv" | wc -l | tr -d '[:space:]')"
  n_unresolved="$(awk -F'\t' '$3=="unresolved"' "$work/stage2.tsv" | wc -l | tr -d '[:space:]')"

  # basename -> manifest leaf, for every joined disk file
  {
    awk -F'\t' -v OFS='\t' '$2=="exact" {print $1, $1}' "$work/stage1.tsv"
    awk -F'\t' -v OFS='\t' '$3=="alnum" {print $1, $2}' "$work/stage2.tsv"
  } > "$work/basename_to_leaf.tsv"

  # ── per-volume grouping, by the MANIFEST directory only ────────────────────
  # A disk file joins to EVERY volume directory whose manifest entry carries its leaf. Where a leaf
  # appears on more than one manifest line the same physical file is claimed by more than one
  # volume - that is the flatten collision, and it is reported on its own line, never absorbed.
  awk -F'\t' -v OFS='\t' '
    FILENAME==ARGV[1] { vols[$1] = vols[$1] (vols[$1]==""?"":"\x01") $2; next }
    FILENAME==ARGV[2] { b2l[$1]=$2; next }
    FILENAME==ARGV[3] {
      bn=$1; album=$2; dn=$3; dt=$4; tn=$5; tt=$6
      leaf = b2l[bn]
      if (leaf == "") { print bn, "", "", album, dn, dt, tn, tt, "UNJOINED"; next }
      m = split(vols[leaf], vv, "\x01")
      for (i=1; i<=m; i++) print bn, leaf, vv[i], album, dn, dt, tn, tt, (m>1 ? "SHARED" : "SOLE")
    }
  ' "$work/man.tsv" "$work/basename_to_leaf.tsv" "$work/tags.tsv" > "$work/joined.tsv"

  local n_unjoined n_shared_rows n_shared_files
  n_unjoined="$(awk -F'\t' '$9=="UNJOINED"' "$work/joined.tsv" | wc -l | tr -d '[:space:]')"
  n_shared_rows="$(awk -F'\t' '$9=="SHARED"' "$work/joined.tsv" | wc -l | tr -d '[:space:]')"
  n_shared_files="$(awk -F'\t' '$9=="SHARED" {print $1}' "$work/joined.tsv" | LC_ALL=C sort -u | wc -l | tr -d '[:space:]')"

  # manifest lines whose leaf has NO file on disk at all
  local n_manifest_only n_dup_leaf_lines n_dup_leaves
  n_manifest_only="$(awk -F'\t' 'NR==FNR {have[$2]=1; next} !($1 in have)' \
      "$work/basename_to_leaf.tsv" "$work/man.tsv" | wc -l | tr -d '[:space:]')"
  # manifest lines beyond the FIRST for a leaf: the flatten collision, measured directly rather
  # than derived from the difference of two totals.
  n_dup_leaf_lines="$(awk -F'\t' '{c[$1]++} END {n=0; for (k in c) if (c[k]>1) n += c[k]-1; print n}' "$work/man.tsv")"
  n_dup_leaves="$(awk -F'\t' '{c[$1]++} END {n=0; for (k in c) if (c[k]>1) n++; print n}' "$work/man.tsv")"

  # null totals - never summed as zero
  local n_null_tracktotal n_null_album n_null_disc n_null_track
  n_null_tracktotal="$(awk -F'\t' '$6==""' "$work/tags.tsv" | wc -l | tr -d '[:space:]')"
  n_null_album="$(awk -F'\t' '$2==""' "$work/tags.tsv" | wc -l | tr -d '[:space:]')"
  n_null_disc="$(awk -F'\t' '$3==""' "$work/tags.tsv" | wc -l | tr -d '[:space:]')"
  n_null_track="$(awk -F'\t' '$5==""' "$work/tags.tsv" | wc -l | tr -d '[:space:]')"

  # ── the per-volume identity: files_present == sum of tracktotal over that volume's discs ──
  awk -F'\t' -v OFS='\t' '
    {
      vol=$3; dn=$5; tt=$8
      if (vol=="") next
      files[vol]++
      if (tt=="") { nullt[vol]++; next }
      key = vol SUBSEP dn
      if (!(key in seen)) { seen[key]=1; sumtt[vol] += tt; discs[vol]++ }
      else if (ttof[key] != "" && ttof[key] != tt) { conflict[vol]++ }
      ttof[key] = tt
    }
    END {
      for (v in files) printf "%s\t%d\t%d\t%d\t%d\t%d\n", v, files[v], sumtt[v], discs[v], nullt[v]+0, conflict[v]+0
    }
  ' "$work/joined.tsv" | LC_ALL=C sort > "$work/pervol.tsv"

  local n_vol_groups n_balanced n_exceptions
  n_vol_groups="$(wc -l < "$work/pervol.tsv" | tr -d '[:space:]')"
  n_balanced="$(awk -F'\t' '$2==$3' "$work/pervol.tsv" | wc -l | tr -d '[:space:]')"
  n_exceptions="$(awk -F'\t' '$2!=$3' "$work/pervol.tsv" | wc -l | tr -d '[:space:]')"

  # ── the report ─────────────────────────────────────────────────────────────
  {
    echo "phase05-now-tag-inventory reconcile"
    echo "generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "now root:  $NOW_ROOT"
    echo ""
    echo "== inputs =="
    printf '  %-46s %s\n' "now-tags.ndjson records"        "$tag_rows"
    printf '  %-46s %s\n' "now-manifest.ndjson records"    "$man_rows"
    echo ""
    echo "== join (disk basename -> manifest leaf) =="
    printf '  %-46s %s\n' "stage 1, exact"                 "$n_exact"
    printf '  %-46s %s\n' "stage 2, alphanumerics-only key" "$n_alnum"
    printf '  %-46s %s\n' "UNRESOLVED (never guessed)"     "$n_unresolved"
    printf '  %-46s %s\n' "disk files with no manifest entry" "$n_unjoined"
    echo ""
    echo "== the 24-entry gap, reported on its OWN line and never folded into any total =="
    printf '  %-46s %s\n' "manifest-only entries (no file on disk)" "$n_manifest_only"
    printf '  %-46s %s\n' "manifest lines beyond the first per leaf" "$n_dup_leaf_lines"
    printf '  %-46s %s\n' "distinct leaves carried by >1 line"      "$n_dup_leaves"
    printf '  %-46s %s\n' "disk files claimed by >1 volume directory" "$n_shared_files"
    printf '  %-46s %s\n' "join rows from those shared files"        "$n_shared_rows"
    echo ""
    echo "== nulls, counted rather than summed as zero =="
    printf '  %-46s %s\n' "records with a null album"       "$n_null_album"
    printf '  %-46s %s\n' "records with a null disc number" "$n_null_disc"
    printf '  %-46s %s\n' "records with a null track number" "$n_null_track"
    printf '  %-46s %s\n' "records with a null track total"  "$n_null_tracktotal"
    echo ""
    echo "== distinct lists =="
    printf '  %-46s %s\n' "distinct manifest volume directories" "$vol_dirs"
    printf '  %-46s %s\n' "distinct album strings"               "$album_vals"
    echo ""
    echo "== per-volume identity: files_present == sum of tracktotal =="
    printf '  %-46s %s\n' "volume directories grouped" "$n_vol_groups"
    printf '  %-46s %s\n' "balanced"                   "$n_balanced"
    printf '  %-46s %s\n' "EXCEPTIONS"                 "$n_exceptions"
    echo ""
    echo "  volume_dir | files | sum(tracktotal) | delta | discs | null-tt | tt-conflicts"
    awk -F'\t' '$2!=$3 {printf "  EXC  %s | %s | %s | %+d | %s | %s | %s\n", $1, $2, $3, $2-$3, $4, $5, $6}' "$work/pervol.tsv"
    echo ""
    echo "  --- all volume directories, balanced included ---"
    awk -F'\t' '{printf "  %-4s %s | %s | %s | %+d | %s | %s | %s\n", ($2==$3?"ok":"EXC"), $1, $2, $3, $2-$3, $4, $5, $6}' "$work/pervol.tsv"
  } > "$RECONCILIATION"

  cat "$RECONCILIATION"

  echo ""
  info "volume dirnames: $VOLUME_DIRNAMES"
  info "album values:    $ALBUM_VALUES"
  info "reconciliation:  $RECONCILIATION"

  if [[ "$n_unjoined" != "0" || "$n_unresolved" != "0" ]]; then
    fail "$n_unjoined disk file(s) unjoined, $n_unresolved unresolved - not guessed, reported"
    return 1
  fi
  pass "every disk file joined to at least one manifest volume directory"
  return 0
}

case "$ACTION" in
  scan)      do_scan ;;
  reconcile) do_reconcile ;;
esac
