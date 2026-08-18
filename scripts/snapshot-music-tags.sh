#!/usr/bin/env bash
# snapshot-music-tags.sh - Capture the pre-project tag before-state of every audio file in the
#                          backlog and the existing library, keyed on the encoded audio bitstream.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   Host-resident rather than workstation-resident because this reads ~140 GB off `tank` and
#   spawns two processes per file; it cannot be expressed as one ssh'd command. Same convention
#   as scripts/setup-mpe.sh, scripts/pg-migrate.sh and scripts/freeze-music-apply.sh.
#
# Usage:
#   bash scripts/snapshot-music-tags.sh [BASENAME] [--roots DIR[,DIR...]] [--limit N]
#
#     BASENAME     output basename inside the fence's tags/ dir. Default: pre-project
#     --roots      comma-separated scan-root override, for a bounded trial on a small subtree.
#                  Default is the four D-02 roots below.
#     --limit N    process at most N files PER ROOT. A global limit would let the first root
#                  consume the whole budget and silently reduce a multi-shape trial to one shape.
#
# Workflow:
#   ssh root@172.16.1.159
#   cd /mnt/fast/stacks && git pull --ff-only
#   bash scripts/snapshot-music-tags.sh                       # the full D-02 capture (plan 01-04)
#   bash scripts/diff-music-tags.sh <a>.ndjson.gz <b>.ndjson.gz
#
# Outputs, all three inside the recovery fence built by `freeze-music-apply.sh fence` (D-03):
#   <OUTDIR>/<BASENAME>.ndjson.gz   one full-ffprobe JSON object per line, gzip-appended per file
#   <OUTDIR>/<BASENAME>.done        completed-paths ledger - the resume mechanism
#   <OUTDIR>/<BASENAME>.failed      path<TAB>stage<TAB>exit-code, retried on the next run
#
# READ-ONLY against content (T-01-13). ffmpeg is invoked with `-f md5 -` writing to STDOUT and is
# never given an output file path; ffprobe is read-only by construction. This script contains no
# chown, chmod, mv or rm against any scan root - the only rm here targets its own output files.
#
# THE KEY (D-01): `ffmpeg -map 0:a -c copy -f md5 -` hashes the ENCODED audio bitstream only.
#   `-c copy` is load-bearing: a decode would produce a different digest per ffmpeg build, and
#   hashing the whole container would move the key every time a tag is rewritten. The point is a
#   key that survives Phase 5's folder moves AND Phase 7's ALBUMARTIST/Album/NN-Title rename.
#   `source_path` is recorded as an ATTRIBUTE, never as the key - a path-keyed snapshot would have
#   zero matching rows by the time the Phase 7 diff runs.
#
# THE RECORD (D-05): the `ffprobe` member is the COMPLETE `-show_format -show_streams` output, not
#   a selected field list, so TKEY, EnergyLevel and every other tag fall out automatically with no
#   whitelist to maintain. The line is assembled BY jq, with the ffprobe JSON piped in as `.`, so
#   unbalanced quotes, newlines and unicode inside third-party tag values cannot corrupt the
#   stream (T-01-14). Nothing here concatenates strings into JSON.
#
# STORAGE (D-03): gzip supports concatenated members and zcat reads them transparently, so each
#   record is gzipped and appended individually. An interrupted run therefore leaves a SALVAGEABLE
#   file rather than a truncated one. The cost is one gzip spawn per file; that is the trade the
#   decision asks for.
#
# RESUMABILITY (D-02): the ledger, not a re-scan of the NDJSON. `<BASENAME>.done` is loaded once
#   into an associative array on start and any path already present is skipped. Deciding
#   skip-or-not by decompressing and parsing the NDJSON would mean reading the whole file on every
#   restart, and the cost would grow with progress - exactly backwards.
#
#   Ordering within a file is: emit the NDJSON line, THEN append to `.done`. A hard kill in that
#   window re-emits one record on the next run; it never loses one. SIGINT and SIGTERM are trapped
#   and stop at a clean file boundary, so an orderly interrupt is exact.
#
#   A file whose ffmpeg or ffprobe exits non-zero goes to `.failed` and is NOT written to `.done`,
#   so a re-run retries it rather than permanently skipping it.
#
# Idempotent: safe to interrupt with Ctrl-C or a dropped ssh session at ANY point, and safe to
#   re-run immediately. A re-run with nothing left to do processes 0 files and rewrites nothing.
#
# NOTHING is written to the system temp directory. On LXC 100 that directory is tmpfs backed by
# host RAM; a 1.1 GB file staged there previously took the whole 28 GB box down and killed ssh on
# both the host and the container. Every byte this script writes lands under /mnt/fast. The
# absence of that path is asserted at the acceptance level, which is why it is not spelled out
# literally anywhere in this file (T-01-15).

set -euo pipefail

FENCE="/mnt/fast/safety/music-pre-project"
OUTDIR="${FENCE}/tags"

# The four D-02 scan roots: ~9,736 audio files, ~140 GB, one full read. The library files are
# included despite re-importing them being out of scope, because a Phase 7 import writing to a
# colliding destination path can degrade them and they have no other recovery path.
DEFAULT_ROOTS=(
  "/mnt/tank/downloads/complete/nzb/unsorted"
  "/mnt/tank/downloads/complete/nzb/dj-mixes"
  "/mnt/tank/downloads/complete/nzb/music"
  "/mnt/tank/media/Music"
)

# Audio extensions. Identical to freeze-music-apply.sh's AUDIO_EXT deliberately - the two tools
# must agree on what counts as audio or the fence and the snapshot cover different populations.
# This list is also the non-audio FILTER: .lrc, .txt, .nfo, .jpg, .bmp, .cue, .m3u, .sfv and the
# video containers under sibling trees are excluded here rather than reaching `-map 0:a` and
# filling .failed with noise.
AUDIO_EXT=(mp3 wav flac m4a aiff aif wma ogg opus aac wv ape alac)

PROGRESS_EVERY=100

BASENAME="pre-project"
LIMIT=0                                       # 0 = no limit
ROOTS=()

usage() {
  cat >&2 <<'EOF'
usage: bash scripts/snapshot-music-tags.sh [BASENAME] [--roots DIR[,DIR...]] [--limit N]

  BASENAME       output basename under /mnt/fast/safety/music-pre-project/tags/
                 (default: pre-project)
  --roots LIST   comma-separated scan roots, overriding the four D-02 defaults
  --limit N      process at most N files PER ROOT (default: no limit)

Writes <BASENAME>.ndjson.gz, <BASENAME>.done and <BASENAME>.failed into the fence.
Read-only against every scan root. Resumable: re-run after any interrupt.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --roots)  [[ $# -ge 2 ]] || usage; IFS=',' read -r -a ROOTS <<< "$2"; shift 2 ;;
    --limit)  [[ $# -ge 2 ]] || usage
              [[ "$2" =~ ^[0-9]+$ ]] || { echo "--limit needs a non-negative integer" >&2; usage; }
              LIMIT="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*)       echo "unknown option: $1" >&2; usage ;;
    *)        BASENAME="$1"; shift ;;
  esac
done

[[ ${#ROOTS[@]} -gt 0 ]] || ROOTS=("${DEFAULT_ROOTS[@]}")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "    ${GREEN}$*${NC}"; }
warn() { echo -e "    ${YELLOW}WARN: $*${NC}"; }
err()  { echo -e "    ${RED}FAIL: $*${NC}"; }
banner() {
  echo ""
  echo "=================================================="
  echo "  $1"
  echo "=================================================="
}

# ─── preconditions (pg-migrate.sh guard-then-SKIP shape) ──────────────────────
MISSING_TOOLS=()
for t in ffmpeg ffprobe jq gzip stat find sort; do
  command -v "$t" >/dev/null 2>&1 || MISSING_TOOLS+=("$t")
done
if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  err "missing required tool(s): ${MISSING_TOOLS[*]}"
  echo "    This script installs nothing. Install them on LXC 100 and re-run." >&2
  exit 1
fi

if [[ ! -d "$OUTDIR" ]]; then
  err "$OUTDIR does not exist"
  echo "    That directory is created by \`bash scripts/freeze-music-apply.sh fence\`." >&2
  echo "    Its absence means the recovery fence has not been built, which means this capture" >&2
  echo "    would have nowhere protected to land. Build the fence first." >&2
  exit 1
fi

OUT="${OUTDIR}/${BASENAME}.ndjson.gz"
DONE_LEDGER="${OUTDIR}/${BASENAME}.done"
FAILED_LIST="${OUTDIR}/${BASENAME}.failed"

# ─── clean-boundary interrupt ─────────────────────────────────────────────────
# Set a flag rather than dying mid-file, so an orderly Ctrl-C or SIGTERM stops between files and
# the ledger and the NDJSON stay exactly in step. A hard kill (-9) is still safe: it can only
# re-emit the single in-flight record on the next run, never lose one.
STOP=0
on_signal() { STOP=1; echo ""; echo "  [signal received - stopping at the next file boundary]"; }
trap on_signal INT TERM

# ─── find predicate builder ───────────────────────────────────────────────────
# Built as an ARRAY passed to find unexpanded, never a string through eval: the patterns contain
# `*` and eval would glob-expand them against the caller's working directory before find saw them.
FIND_EXPR=()
build_iname_expr() {
  FIND_EXPR=( '(' )
  local first=1
  for e in "$@"; do
    [[ $first -eq 0 ]] && FIND_EXPR+=( '-o' )
    FIND_EXPR+=( '-iname' "*.${e}" )
    first=0
  done
  FIND_EXPR+=( ')' )
}

# ─── the record ───────────────────────────────────────────────────────────────
# emit_record AUDIO_MD5 PATH ROOT SIZE MTIME  <  ffprobe JSON on stdin
# jq builds the whole line; the ffprobe output arrives as `.` and is embedded verbatim.
emit_record() {
  jq -c \
    --arg audio_md5   "$1" \
    --arg source_path "$2" \
    --arg scan_root   "$3" \
    --argjson size_bytes  "$4" \
    --argjson mtime_epoch "$5" \
    '{audio_md5:   $audio_md5,
      source_path: $source_path,
      scan_root:   $scan_root,
      size_bytes:  $size_bytes,
      mtime_epoch: $mtime_epoch,
      ffprobe:     .}'
}

banner "snapshot-music-tags - capturing the pre-project tag before-state"
echo "  basename:  $BASENAME"
echo "  ndjson:    $OUT"
echo "  ledger:    $DONE_LEDGER"
echo "  failed:    $FAILED_LIST"
echo "  limit:     $([[ $LIMIT -eq 0 ]] && echo 'none' || echo "$LIMIT per root")"
echo "  roots:     ${#ROOTS[@]}"
for r in "${ROOTS[@]}"; do echo "               $r"; done
echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ─── load the resume ledger ───────────────────────────────────────────────────
declare -A DONE_MAP=()
DONE_LOADED=0
if [[ -f "$DONE_LEDGER" ]]; then
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    DONE_MAP["$p"]=1
    DONE_LOADED=$((DONE_LOADED + 1))
  done < "$DONE_LEDGER"
fi
echo ""
echo "==> Resume ledger: $DONE_LOADED path(s) already captured"

# The failed list is rebuilt each run: a file that failed last time is retried, and if it now
# succeeds it must not stay on the list. Anything still failing is re-appended below.
: > "$FAILED_LIST"

build_iname_expr "${AUDIO_EXT[@]}"

TOT_SEEN=0 TOT_NEW=0 TOT_SKIP=0 TOT_FAIL=0 TOT_BYTES=0
RUN_START=$(date +%s)
declare -a ROOT_REPORT=()

for ROOT in "${ROOTS[@]}"; do
  banner "root: $ROOT"
  if [[ ! -d "$ROOT" ]]; then
    err "not present on this host - skipping"
    ROOT_REPORT+=("$(printf '%s\t%s\t%s\t%s\t%s' "$ROOT" "0" "0" "0" "MISSING")")
    continue
  fi

  # Deterministic, filename-ordered walk. LC_ALL=C so the order does not shift with locale.
  # This is what makes a --limit sample comparable between two copies of the same release: if the
  # two roots were walked in different orders the samples would cover different tracks and an
  # empty hash overlap would prove nothing.
  mapfile -t FILES < <(find "$ROOT" -type f "${FIND_EXPR[@]}" -print 2>/dev/null | LC_ALL=C sort)

  R_TOTAL=${#FILES[@]}
  if [[ $LIMIT -gt 0 && $R_TOTAL -gt $LIMIT ]]; then
    FILES=("${FILES[@]:0:$LIMIT}")
    echo "  $R_TOTAL audio files found; --limit takes the first $LIMIT in filename order"
  else
    echo "  $R_TOTAL audio files found"
  fi

  R_START=$(date +%s)
  R_NEW=0 R_SKIP=0 R_FAIL=0 R_BYTES=0 R_SEEN=0

  for f in "${FILES[@]}"; do
    [[ $STOP -eq 1 ]] && break
    R_SEEN=$((R_SEEN + 1)); TOT_SEEN=$((TOT_SEEN + 1))

    if [[ -n "${DONE_MAP["$f"]:-}" ]]; then
      R_SKIP=$((R_SKIP + 1)); TOT_SKIP=$((TOT_SKIP + 1))
    else
      st="$(stat -c '%s %Y' -- "$f" 2>/dev/null || echo '')"
      if [[ -z "$st" ]]; then
        printf '%s\tstat\t1\n' "$f" >> "$FAILED_LIST"
        R_FAIL=$((R_FAIL + 1)); TOT_FAIL=$((TOT_FAIL + 1))
        continue
      fi
      size="${st%% *}"; mtime="${st##* }"

      # D-01. -nostdin so ffmpeg cannot swallow this loop's stdin. Output is "MD5=<32 hex>" on
      # stdout; no output file path is ever given, which is what keeps this read-only (T-01-13).
      raw=""; rc=0
      raw="$(ffmpeg -nostdin -v error -i "$f" -map 0:a -c copy -f md5 - 2>/dev/null)" || rc=$?
      if [[ $rc -ne 0 ]]; then
        printf '%s\tffmpeg\t%s\n' "$f" "$rc" >> "$FAILED_LIST"
        R_FAIL=$((R_FAIL + 1)); TOT_FAIL=$((TOT_FAIL + 1))
        continue
      fi
      md5="${raw#MD5=}"; md5="${md5//[$'\r\n']/}"
      if [[ ! "$md5" =~ ^[0-9a-f]{32}$ ]]; then
        printf '%s\tmd5-shape\t1\n' "$f" >> "$FAILED_LIST"
        R_FAIL=$((R_FAIL + 1)); TOT_FAIL=$((TOT_FAIL + 1))
        continue
      fi

      # D-05. Full output: -show_format carries the container tag block (TKEY/EnergyLevel live
      # there for ID3), -show_streams the per-stream tag block. Never a selected field list.
      line=""; rc=0
      line="$(ffprobe -v quiet -print_format json -show_format -show_streams -- "$f" </dev/null \
              | emit_record "$md5" "$f" "$ROOT" "$size" "$mtime")" || rc=$?
      if [[ $rc -ne 0 ]]; then
        printf '%s\tffprobe-or-jq\t%s\n' "$f" "$rc" >> "$FAILED_LIST"
        R_FAIL=$((R_FAIL + 1)); TOT_FAIL=$((TOT_FAIL + 1))
        continue
      fi
      if [[ -z "$line" ]]; then
        printf '%s\tempty-record\t1\n' "$f" >> "$FAILED_LIST"
        R_FAIL=$((R_FAIL + 1)); TOT_FAIL=$((TOT_FAIL + 1))
        continue
      fi

      # Flush the record FIRST, then the ledger. A hard kill between the two re-emits one record
      # on resume; it never loses one. -n keeps the gzip member header free of a timestamp.
      printf '%s\n' "$line" | gzip -cn >> "$OUT"
      printf '%s\n' "$f" >> "$DONE_LEDGER"
      DONE_MAP["$f"]=1

      R_NEW=$((R_NEW + 1));   TOT_NEW=$((TOT_NEW + 1))
      R_BYTES=$((R_BYTES + size)); TOT_BYTES=$((TOT_BYTES + size))
    fi

    if (( R_SEEN % PROGRESS_EVERY == 0 )); then
      printf '    %6d/%-6d  processed=%-6d skipped=%-6d failed=%-4d remaining=%d\n' \
        "$R_SEEN" "${#FILES[@]}" "$R_NEW" "$R_SKIP" "$R_FAIL" "$(( ${#FILES[@]} - R_SEEN ))"
    fi
  done

  R_END=$(date +%s); R_SECS=$(( R_END - R_START )); [[ $R_SECS -eq 0 ]] && R_SECS=1
  echo "    seen=$R_SEEN processed=$R_NEW skipped=$R_SKIP failed=$R_FAIL"
  printf '    %ds  %s bytes  %.3f s/file  %.2f MB/s\n' \
    "$R_SECS" "$R_BYTES" \
    "$(awk -v s="$R_SECS" -v n="$R_NEW" 'BEGIN{print (n>0)? s/n : 0}')" \
    "$(awk -v b="$R_BYTES" -v s="$R_SECS" 'BEGIN{print b/1048576/s}')"
  ROOT_REPORT+=("$(printf '%s\t%s\t%s\t%s\t%s' "$ROOT" "$R_NEW" "$R_BYTES" "$R_SECS" "$R_FAIL")")

  [[ $STOP -eq 1 ]] && break
done

RUN_END=$(date +%s); RUN_SECS=$(( RUN_END - RUN_START )); [[ $RUN_SECS -eq 0 ]] && RUN_SECS=1

echo ""
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf '  %-42s %s\n' "root" "files  bytes  secs  failed"
for r in "${ROOT_REPORT[@]}"; do
  IFS=$'\t' read -r rp rn rb rs rf <<< "$r"
  printf '  %-42s %-6s %-14s %-5s %s\n' "$(basename "$rp")" "$rn" "$rb" "$rs" "$rf"
done
echo "  ────────────────────────────────────────────────────────"
echo "  Files seen:         $TOT_SEEN"
echo "  Records written:    $TOT_NEW"
echo "  Skipped (in .done): $TOT_SKIP"
echo "  Failed:             $TOT_FAIL"
echo "  Bytes read:         $TOT_BYTES"
echo "  Wall clock:         ${RUN_SECS}s"
printf '  Throughput:         %.3f s/file, %.2f MB/s\n' \
  "$(awk -v s="$RUN_SECS" -v n="$TOT_NEW" 'BEGIN{print (n>0)? s/n : 0}')" \
  "$(awk -v b="$TOT_BYTES" -v s="$RUN_SECS" 'BEGIN{print b/1048576/s}')"
echo "  ndjson:             $OUT"
echo "  ledger:             $DONE_LEDGER ($(wc -l < "$DONE_LEDGER" 2>/dev/null | tr -d ' ') lines)"
echo ""

if [[ $TOT_FAIL -gt 0 ]]; then
  warn "$TOT_FAIL file(s) failed and were NOT written to the ledger - re-run to retry them"
  echo "    failed list: $FAILED_LIST"
fi

if [[ $STOP -eq 1 ]]; then
  echo -e "${YELLOW}snapshot: interrupted at a clean file boundary - re-run to continue${NC}"
  exit 130
fi

if [[ $TOT_FAIL -gt 0 ]]; then
  echo -e "${RED}snapshot: complete with $TOT_FAIL failure(s)${NC}"
  exit 1
fi
echo -e "${GREEN}snapshot: complete${NC}"
