#!/usr/bin/env bash
# phase05-now-split.sh - Derive the per-volume split of the FLATTENED `Now! 1-115` collection, emit
#                        it as ONE reviewable mapping file, and act on that mapping only after an
#                        operator has approved it and a rollback snapshot has been PROVEN to exist.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Host-resident rather than workstation-resident because it reads two multi-MB NDJSON inputs and
#   in `apply` issues ~4,751 rename(2) calls; it cannot be expressed as one ssh'd command. Same
#   convention as scripts/phase05-now-tag-inventory.sh, scripts/snapshot-music-tags.sh and
#   scripts/freeze-music-apply.sh.
#   The `plan` half and BOTH `apply` refusals are reachable on a workstation with no access to
#   tank at all - that is deliberate, and it is what makes the refusals testable.
#
# Usage:
#   bash scripts/phase05-now-split.sh plan     # READ-ONLY. Derives and emits the mapping. Moves nothing.
#   bash scripts/phase05-now-split.sh apply    # Acts from the APPROVED mapping. Refuses without it.
#   bash scripts/phase05-now-split.sh --help
#
# Outputs, ALL of them under $OUT_DIR:
#   now-split-map.tsv            THE MAPPING. One row per file:
#                                  src_abs_path <TAB> dst_abs_path <TAB> volume <TAB>
#                                  source_instrument <TAB> agreement
#                                Exactly five tab-separated fields on every row, no header line.
#   now-volume-numbers.tsv       manifest directory <TAB> derived volume <TAB> rule applied <TAB>
#                                variant edition annotation. ONE ROW PER DISTINCT DIRECTORY NAME.
#                                The number assignment is THE risk in this tool, so it is a file a
#                                human can read rather than a regex buried in code.
#   now-album-aliases.tsv        album string <TAB> volume <TAB> files <TAB> status.
#                                The INDEPENDENT cross-check (D-02), as an explicit lookup table.
#   now-cross-volume-collisions.tsv  basename <TAB> claimed volumes <TAB> winner <TAB> rejected <TAB>
#                                album tag <TAB> verdict. The files the flatten collapsed whose
#                                claims cross a REAL volume boundary.
#   now-missing-tracks.tsv       volume <TAB> disc <TAB> expected <TAB> present <TAB> missing track
#                                numbers. The shortfall, named track by track (operator decision 2).
#   now-reconciliation.txt       The disjoint-bucket equation, the per-volume identity, and the
#                                manifest-only entries on their own line.
#
# Inputs, produced by plan 05-05 (scripts/phase05-now-tag-inventory.sh scan):
#   $OUT_DIR/now-tags.ndjson      4,746 records, one per mp3, with album/disc/track/tracktotal
#   $OUT_DIR/now-manifest.ndjson  4,770 records, one per m3u line, with its volume directory
#
# THE KEY (D-02 + D-13) - WHY THE MAPPING IS A FILE AND NOT A FUNCTION CALL:
#   The volume a file belongs to is DERIVED, not read off the filesystem: the real 45 GB folder has
#   4,746 files and ZERO subdirectories, so the split cannot move existing subfolders because there
#   are none. A wrong derivation is silent, exits 0, and looks right - and it would land as 4,751
#   irreversible renames. So the derivation is reduced to files a human can read BEFORE anything
#   moves, and `apply` acts from the approved file BY NAME. The approval sits between two
#   PROCESSES joined by a file on disk, not between two branches of one process: a branch can be
#   skipped by a flag, an env var or a future edit; a missing file cannot.
#   D-02 supplies the method: the m3u manifest IS the map, the album tag is an INDEPENDENT
#   cross-check, and on disagreement the file goes to quarantine rather than to a guessed volume.
#
# DO NOT PARSE A TRAILING NUMBER OFF THE `album` TAG. D-03 is a MEASURED trap and it is recorded
#   here verbatim rather than paraphrased, because a trailing-number regex is the obvious first
#   implementation. The 117 distinct album values include:
#     - volume 1 tagged `Now That's What I Call Music` - NO NUMBER AT ALL
#     - volume 2 tagged `Now, That's What I Call Music II` - a Roman numeral, and a comma
#     - volume 36 split across THREE spellings: `...! Vol.36 CD1` on 16 files,
#       `...! Vol.36  CD2` on 20 files WITH A DOUBLE SPACE, and `...! 36` on 4 files
#   `...Vol.36 CD1` ends in 1 and `...Vol.36  CD2` ends in 2, so a trailing-number regex silently
#   misfiles 36 tracks into volumes 1 and 2. IT EXITS 0 AND IT LOOKS RIGHT. Punctuation varies too:
#   96 values spell it `Music!` and 21 spell it `Music`.
#   This script therefore applies NO regex to any album value. The album-to-volume relation is a
#   LOOKUP in now-album-aliases.tsv, seeded from the manifest association and emitted for review.
#
# VOLUME NUMBERS COME FROM THE MANIFEST DIRECTORY COMPONENT, AND ONLY FROM IT. The directory names
#   are uniform (`1993. Now That's What I Call Music! 25`), unlike the album tag. The derivation is
#   a stated rule chain, one rule at a time, with the rule that fired recorded per row:
#     1. strip a leading four-digit year followed by a period and whitespace
#     2. strip any trailing bracketed annotation `[...]`, repeatedly - the VARIANT EDITION
#     3. strip any trailing parenthesised annotation `(...)`, repeatedly
#     4. the number that remains at the end IS the volume number
#     5. a residual with no trailing number at all is volume 1 - asserted UNIQUE, never assumed
#   Then TOTAL COVERAGE is asserted: the derived numbers must be exactly the integers 1 through 115,
#   each appearing at least once, with nothing outside the range and no directory left unparsed.
#   Any gap, any duplicate outside the declared variant-edition merge, any out-of-range number or
#   any unparseable name is a HARD FAILURE that stops the tool. Never a skip and never a guess.
#
# OPERATOR DECISION 1 (2026-09-18) - THE SPLIT IS 115 FOLDERS, VARIANT EDITIONS MERGED.
#   Plan 05-05 measured 119 distinct manifest volume directories, not the 116 previously documented:
#   four of them are VARIANT EDITIONS of volumes 4 (x2), 8 and 9 -
#     `[Genuine UK 1CD-Extremely Rare...]`, `[Original 1CD Extremely Rare...]`,
#     `[Original 1CD Rare]` on 8 and on 9.
#   Each variant edition folds into its VOLUME NUMBER. `Vol 004` holds the union of its three
#   editions' tracks. The variant edition names are RECORDED in now-volume-numbers.tsv and in
#   05-NOW-INVENTORY.md; they do NOT appear as directories on disk. Target: 115 flat folders.
#
# OPERATOR DECISION 2 (2026-09-18) - SHORT VOLUMES ARE SPLIT ANYWAY, WITH THE SHORTFALL RECORDED.
#   11 files are missing across 7 measured directory shortfalls. The gap is in the SOURCE RIP; the
#   split cannot fix it, and holding 7 volumes back would block 112 good ones. Those folders are
#   created with what exists and the missing track numbers are named in now-missing-tracks.tsv.
#   They are NOT routed to 04-hold: that folder is scoped for content needing artwork or tracklist
#   sourcing, not missing audio (D-09).
#
# CROSS-VOLUME COLLISIONS - THE CONSEQUENCE OF THE FLATTEN, AND THE ONE PLACE A GUESS IS POSSIBLE.
#   4,770 manifest lines carry only 4,746 distinct leaf names: 23 physical files are claimed by more
#   than one manifest directory, one of them by three. Merging variant editions dissolves most of
#   those, because the competing claims are usually different EDITIONS of the same volume number.
#   Where a collision still crosses a REAL volume boundary after the merge, a physical file can only
#   be moved once, and the rule is stated rather than silent:
#     1. break the tie using the FILE'S OWN EMBEDDED album TAG, resolved through the alias table.
#        The tag is the file's own claim about where it belongs and is a better instrument than
#        manifest line order, which carries no information at all.
#     2. record BOTH the winning assignment and the rejected claim(s), in the map row itself and in
#        now-cross-volume-collisions.tsv.
#     3. if the album tag does NOT disambiguate, DO NOT GUESS. The row is emitted FLAGGED FOR
#        OPERATOR REVIEW with every competing claim named, and is decided at the 05-07 gate.
#
# FILES ROUTED TO 99-quarantine/now-volume-disagreement/ ARE NOT JUNK AND MUST NOT BE DELETED.
#   That path is where D-02 sends a file whose two instruments disagree, or whose album string is
#   absent from the alias table, or whose claims cross a volume boundary the album tag cannot
#   settle. The junk sweep completed in plan 05-04, BEFORE this runs, so nothing will act on them.
#   They are the "content the operator deliberately kept" case D-11 allows, and they are handed to
#   Phase 6. Anyone reading `99-quarantine` as a delete queue must read this line first.
#
# DESTINATION LAYOUT IS FLAT - THE CD1/CD2 SPLIT IS NOT RESTORED (D-05). Volume folders are created
#   INSIDE NOW_ROOT and named `Vol NNN`, three-digit zero-padded, so they sort lexically in volume
#   order. All discs of a volume live in ONE folder. Every file already carries a disc value with
#   zero omissions and the maximum disc count is 2, so the TAGS carry the disc structure; beets
#   treats one directory as one album candidate, so handing it two directories risks matching one
#   volume as two albums - the multi-disc shape QUAL-03 reserves for Phase 7 to exercise
#   deliberately. Whether the LIBRARY path format splits discs is Phase 6's call (CONF-03), made at
#   the path-format layer where it belongs. No CD subdirectory is constructed anywhere below.
#
# THE FOUR KEPT SIDECARS GET DESTINATIONS TOO, per D-06's by-value triage, which was reached by
#   OPENING the files rather than by extension: `back.bmp`, `cd1.bmp` and `cd2.bmp` are NOW 77 case
#   scans carrying both tracklists, a barcode and catalogue number UK:CDNOW77, so they follow
#   volume 77 - and plan 05-03 closed D-06's one open verdict by opening `cd2.bmp`: it IS NOW 77
#   disc 2. The volume-115 cue sheet follows volume 115. The 9,541-line m3u map STAYS at NOW_ROOT,
#   beside the collection it maps; its row carries dst == src and is a no-op for `apply`.
#
# EXIT-CODE CONVENTION (stated here deliberately, not inherited - the estate has no single one):
#   plan   0  the mapping and its supporting artifacts were emitted. It REPORTS; it does not assert
#             the content is correct - that is what the operator review is for.
#          1  a derivation invariant failed (coverage, join, or the disjoint-bucket equation).
#             Nothing usable was produced.
#          2  usage error; NOW_ROOT outside the fence; a required input missing; or $SPLIT_MAP
#             already exists (refusing to overwrite an artifact an operator may already have read)
#   apply  0  every row moved AND the post-move reconciliation, re-run from the RESULTING TREE,
#             balances
#          1  at least one row failed, or the post-move reconciliation does not balance
#          2  usage error, a missing map, or a missing/wrong snapshot proof (refusal, never a skip)
#
# HAZARD NOTES:
#   * `mv` HAS NO UNDO and neither does this tool. tank/downloads@pre-phase5 is `apply`'s ONLY
#     rollback. `zfs` cannot resolve on LXC 100 (unprivileged), so the check is DELEGATED to a
#     proof file produced on atlantis. An unreachable atlantis means the snapshot state is UNKNOWN,
#     which is a REFUSAL - not a skip and not a pass. The existing @pre-project and @pre-chown
#     snapshots are a month stale, so a proof naming the wrong snapshot MUST fail; the substring
#     check gives that for free.
#   * NOTHING is written to the system temp directory. On LXC 100 that directory is tmpfs backed by
#     host RAM; a 1.1 GB file staged there once took the whole 28 GB box down and killed ssh on the
#     host AND the container. Every byte this script writes lands under $OUT_DIR on /mnt/fast.
#   * THE SCOPE FENCE IS RE-ASSERTED PER ROW, NOT ONLY ON THE ROOT. normalise-dj-tags.py's CR-04
#     recorded that fencing the target alone was not enough: a single symlink under the tree
#     defeated the fence silently, with a normal-looking change count. A source that is a symlink,
#     is not a regular file, or carries a link count above one is REFUSED, by name.
#   * /mnt/tank/media IS REFUSED BY NAME. Phase 1's D-20: nobody holds rw on the library until
#     Phase 6, and one wrong constant is all that stands between this tool and 34 GB of library.
#   * `chmod` fails EPERM on tank even as real root, and `chown` cannot run from LXC 100 at all
#     (sparse idmap). This tool changes neither. A rename preserves ownership, and D-26 says
#     staging carries mixed ownership by design; D-27's tree-wide chown runs last, separately.
#   * _inbox, unsorted and dj-mixes are all one dataset (devid 68; tank/media/Music is devid 76),
#     so every move here is an INODE-PRESERVING rename(2) - instant and free. `apply` asserts the
#     inode is unchanged after each rename, which is the instrument that would catch a
#     copy-then-unlink caused by someone making _inbox its own dataset (D-18 forbids exactly that).
#   * The download tree is LIVE, written at roughly one music job per 72 s. The mapping is a
#     point-in-time view; `apply` re-validates every row against fresh state before acting.
#
# Idempotent: `plan` refuses to overwrite an existing map, so re-running it is a refusal rather
#   than a silent rewrite - delete the map deliberately to regenerate it. `apply` skips a row whose
#   source is already at its destination, so an interrupted run resumes.

set -euo pipefail

NOW_ROOT="${NOW_ROOT:-/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023}"
REQUIRED_ROOT="${REQUIRED_ROOT:-/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023}"
FORBIDDEN_ROOT="${FORBIDDEN_ROOT:-/mnt/tank/media}"
OUT_DIR="${OUT_DIR:-/mnt/fast/safety/phase05}"

QUARANTINE="${QUARANTINE:-/mnt/tank/downloads/complete/nzb/_inbox/99-quarantine/now-volume-disagreement}"

SPLIT_MAP="${SPLIT_MAP:-$OUT_DIR/now-split-map.tsv}"
VOLUME_NUMBERS="${VOLUME_NUMBERS:-$OUT_DIR/now-volume-numbers.tsv}"
ALBUM_ALIASES="${ALBUM_ALIASES:-$OUT_DIR/now-album-aliases.tsv}"
COLLISIONS="${COLLISIONS:-$OUT_DIR/now-cross-volume-collisions.tsv}"
MISSING_TRACKS="${MISSING_TRACKS:-$OUT_DIR/now-missing-tracks.tsv}"
RECONCILIATION="${RECONCILIATION:-$OUT_DIR/now-split-reconciliation.txt}"

SNAPSHOT_NAME="${SNAPSHOT_NAME:-tank/downloads@pre-phase5}"
SNAPSHOT_PROOF="${SNAPSHOT_PROOF:-$OUT_DIR/snapshot-proof.txt}"

TAGS_NDJSON="${TAGS_NDJSON:-$OUT_DIR/now-tags.ndjson}"
MANIFEST_NDJSON="${MANIFEST_NDJSON:-$OUT_DIR/now-manifest.ndjson}"

VOL_MIN=1
VOL_MAX=115

WORK_DIR=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
banner() { echo ""; echo "=================================================="; echo "  $1"; echo "=================================================="; }

usage() {
  echo "usage: bash scripts/phase05-now-split.sh {plan|apply}" >&2
  echo "       bash scripts/phase05-now-split.sh --help" >&2
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
  plan|apply) ;;
  *) usage ;;
esac

# ─── the scope fence (T-05-06-04) ─────────────────────────────────────────────
# Written INLINE and checked FIRST, before any tool probe and before any input is required, so it
# is reachable and testable on a workstation with no access to tank at all. `exit` inside a command
# substitution leaves only the subshell, so a fence expressed as a function that returns a value is
# a fence one edit from silence.
NOW_ROOT_REAL="$(realpath -m -- "$NOW_ROOT" 2>/dev/null || printf '%s' "$NOW_ROOT")"
REQUIRED_REAL="$(realpath -m -- "$REQUIRED_ROOT" 2>/dev/null || printf '%s' "$REQUIRED_ROOT")"
FORBIDDEN_REAL="$(realpath -m -- "$FORBIDDEN_ROOT" 2>/dev/null || printf '%s' "$FORBIDDEN_ROOT")"

# The library is refused BY NAME, with its own message, before the equality test - so the operator
# reads the reason rather than a generic mismatch.
if [[ "$NOW_ROOT_REAL" == "$FORBIDDEN_REAL" || "$NOW_ROOT_REAL" == "$FORBIDDEN_REAL"/* ]]; then
  echo -e "${RED}REFUSING TO RUN: the target is inside the LIBRARY, which this phase may not touch.${NC}" >&2
  echo "  given:     $NOW_ROOT" >&2
  echo "  resolved:  $NOW_ROOT_REAL" >&2
  echo "  forbidden: $FORBIDDEN_REAL (and every descendant)" >&2
  echo "  required:  $REQUIRED_REAL" >&2
  echo "  Phase 1 D-20: nobody holds rw on the library until Phase 6. Every write Phase 5" >&2
  echo "  performs lands under tank/downloads. Refusing." >&2
  exit 2
fi
if [[ "$NOW_ROOT_REAL" != "$REQUIRED_REAL" ]]; then
  echo -e "${RED}REFUSING TO RUN: NOW_ROOT is not the Now! collection folder.${NC}" >&2
  echo "  given:    $NOW_ROOT" >&2
  echo "  resolved: $NOW_ROOT_REAL" >&2
  echo "  required: $REQUIRED_REAL (exactly - not a parent and not a descendant)" >&2
  echo "  A wrong root would map 4,751 renames over the wrong content. Refusing to guess." >&2
  exit 2
fi
NOW_ROOT="$NOW_ROOT_REAL"

# ─── shared row-level fence ───────────────────────────────────────────────────
# Every source path must sit DIRECTLY inside NOW_ROOT (the collection is flat) and every
# destination must sit inside either NOW_ROOT or the quarantine directory. Re-asserted per row.
dst_in_scope() {
  local d="$1"
  [[ "$d" == "$NOW_ROOT"/* || "$d" == "$QUARANTINE"/* ]]
}

src_in_scope() {
  local s="$1"
  [[ "$s" == "$NOW_ROOT"/* ]] && [[ "${s#$NOW_ROOT/}" != */* ]]
}

# ══════════════════════════════════════════════════════════════════════════════
do_plan() {
  banner "phase05-now-split plan  (READ-ONLY - nothing is moved)"
  echo "  now root:   $NOW_ROOT"
  echo "  out dir:    $OUT_DIR"
  echo "  split map:  $SPLIT_MAP"
  echo "  quarantine: $QUARANTINE"
  echo "  date:       $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local t missing=()
  for t in jq awk sort find stat realpath; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    fail "missing required tool(s): ${missing[*]}"
    echo "    This script installs nothing." >&2
    exit 2
  fi

  # Refusing to overwrite an artifact an operator may already have read is a refusal, not a
  # fallback: a silent rewrite would change what "approved" refers to without anyone noticing.
  if [[ -e "$SPLIT_MAP" ]]; then
    fail "$SPLIT_MAP already exists"
    echo "    Refusing to overwrite a mapping an operator may already have read and approved." >&2
    echo "    Delete it deliberately to regenerate." >&2
    exit 2
  fi
  [[ -s "$TAGS_NDJSON" ]]     || { fail "missing input: $TAGS_NDJSON (run phase05-now-tag-inventory.sh scan)"; exit 2; }
  [[ -s "$MANIFEST_NDJSON" ]] || { fail "missing input: $MANIFEST_NDJSON (run phase05-now-tag-inventory.sh scan)"; exit 2; }
  [[ -d "$NOW_ROOT" ]]        || { fail "NOW_ROOT does not exist: $NOW_ROOT"; exit 2; }

  mkdir -p -- "$OUT_DIR"

  # Scratch lives beside the outputs, inside /mnt/fast, and is removed by an EXIT trap. WORK_DIR is
  # deliberately GLOBAL: a `local` would be out of scope by the time the trap fires and, under
  # `set -u`, the trap would then fail instead of cleaning up.
  WORK_DIR="${OUT_DIR}/.split.$$"
  local work="$WORK_DIR"
  mkdir -p -- "$work"
  trap '{ test -n "${WORK_DIR:-}" && test -d "$WORK_DIR" && rm -r -- "$WORK_DIR"; } || true' EXIT

  # ── inputs, flattened to TSV by jq ────────────────────────────────────────
  # jq @tsv ESCAPES an embedded tab rather than emitting one, so awk -F'\t' cannot misalign here.
  # awk -F'\t' is used throughout and NEVER `IFS=$'\t' read`: tab is an IFS whitespace character,
  # so `read` collapses runs of tabs and an empty field silently vanishes.
  jq -r '[.path, .basename, (.album // ""), (.disc_number // ""), (.track_number // ""),
          (.track_total // "")] | @tsv' "$TAGS_NDJSON" > "$work/tags.tsv"
  jq -r '[.leaf, (.volume_dir // "")] | @tsv' "$MANIFEST_NDJSON" > "$work/man.tsv"

  local bad
  bad="$(awk -F'\t' 'NF!=6' "$work/tags.tsv" | wc -l | tr -d '[:space:]')"
  [[ "$bad" == "0" ]] || { fail "tags.tsv: $bad row(s) do not carry 6 fields"; return 1; }
  bad="$(awk -F'\t' 'NF!=2' "$work/man.tsv" | wc -l | tr -d '[:space:]')"
  [[ "$bad" == "0" ]] || { fail "man.tsv: $bad row(s) do not carry 2 fields"; return 1; }

  local tag_rows man_rows
  tag_rows="$(wc -l < "$work/tags.tsv" | tr -d '[:space:]')"
  man_rows="$(wc -l < "$work/man.tsv" | tr -d '[:space:]')"
  echo ""
  echo "==> Inputs"
  printf '    %-42s %s\n' "now-tags.ndjson records"     "$tag_rows"
  printf '    %-42s %s\n' "now-manifest.ndjson records" "$man_rows"

  # ══ VOLUME NUMBER DERIVATION ═══════════════════════════════════════════════
  # The rule chain is index-based rather than regex-based for the bracket and paren stripping: a
  # bracket expression containing `]` is a portability trap across awk implementations, and the
  # annotation text is wanted verbatim for the record, not merely discarded.
  awk -F'\t' '{print $2}' "$work/man.tsv" | LC_ALL=C sort -u > "$work/dirnames.txt"

  awk -v OFS='\t' '
    function rstrip(s) { sub(/[ \t]+$/, "", s); return s }
    {
      d = $0
      if (d == "") next
      s = d; rule = ""; variant = ""

      # 1. leading four-digit year, a period, then whitespace. Written out character by character
      #    rather than with an interval regex, which is not portable across awk implementations.
      if (s ~ /^[0-9][0-9][0-9][0-9]\./) {
        s = substr(s, 6)
        sub(/^[ \t]+/, "", s)
        rule = "year-prefix"
      }

      # 2. trailing bracketed annotations, repeatedly. THIS IS THE VARIANT EDITION (decision 1).
      while (substr(s, length(s), 1) == "]") {
        p = 0
        for (i = length(s); i >= 1; i--) if (substr(s, i, 1) == "[") { p = i; break }
        if (p == 0) break
        ann = substr(s, p)
        s = rstrip(substr(s, 1, p - 1))
        variant = (variant == "" ? ann : ann " " variant)
        rule = (rule == "" ? "bracket" : rule "+bracket")
      }

      # 3. trailing parenthesised annotations, repeatedly (e.g. `(Last audio cassette release)`).
      while (substr(s, length(s), 1) == ")") {
        p = 0
        for (i = length(s); i >= 1; i--) if (substr(s, i, 1) == "(") { p = i; break }
        if (p == 0) break
        ann = substr(s, p)
        s = rstrip(substr(s, 1, p - 1))
        variant = (variant == "" ? ann : ann " " variant)
        rule = (rule == "" ? "paren" : rule "+paren")
      }

      s = rstrip(s)

      # 4. the number that REMAINS at the end is the volume number.
      n = ""
      for (i = length(s); i >= 1; i--) {
        c = substr(s, i, 1)
        if (c >= "0" && c <= "9") n = c n; else break
      }
      if (n != "") {
        vol = n + 0
        rule = (rule == "" ? "trailing-number" : rule "+trailing-number")
      } else {
        # 5. D-03: volume 1 carries no number anywhere. Declared explicitly and asserted UNIQUE by
        #    the caller - never inferred, and never applied to a second directory.
        vol = 1
        rule = (rule == "" ? "no-number-is-volume-1" : rule "+no-number-is-volume-1")
      }
      print d, vol, rule, variant
    }
  ' "$work/dirnames.txt" | LC_ALL=C sort -t$'\t' -k2,2n -k1,1 > "$VOLUME_NUMBERS"

  local dirname_rows numbered_rows
  dirname_rows="$(wc -l < "$work/dirnames.txt" | tr -d '[:space:]')"
  numbered_rows="$(awk -F'\t' '$2 ~ /^[0-9]+$/' "$VOLUME_NUMBERS" | wc -l | tr -d '[:space:]')"

  echo ""
  echo "==> Volume number derivation"
  printf '    %-42s %s\n' "distinct manifest volume directories" "$dirname_rows"
  printf '    %-42s %s\n' "rows that yielded a volume number"    "$numbered_rows"
  printf '    %-42s %s\n' "emitted to"                           "$VOLUME_NUMBERS"

  # ── TOTAL COVERAGE ASSERTION ───────────────────────────────────────────────
  # This is what makes a derived mapping trustworthy. Any gap, any out-of-range number, any
  # unparsed directory is a HARD FAILURE. The variant-edition merge is the ONLY sanctioned source
  # of duplicate numbers, and it is asserted against the declared count rather than waved through.
  if [[ "$numbered_rows" != "$dirname_rows" ]]; then
    fail "$((dirname_rows - numbered_rows)) directory name(s) yielded no volume number"
    awk -F'\t' '$2 !~ /^[0-9]+$/ {print "      unparsed: " $1}' "$VOLUME_NUMBERS" >&2
    return 1
  fi

  local no_number_rows
  no_number_rows="$(awk -F'\t' '$3 ~ /no-number-is-volume-1/' "$VOLUME_NUMBERS" | wc -l | tr -d '[:space:]')"
  if [[ "$no_number_rows" != "1" ]]; then
    fail "the no-number-is-volume-1 rule fired on $no_number_rows directories, expected exactly 1"
    awk -F'\t' '$3 ~ /no-number-is-volume-1/ {print "      " $1}' "$VOLUME_NUMBERS" >&2
    return 1
  fi
  pass "the numberless directory rule fired exactly once (volume 1 carries no number - D-03)"

  # The comparison is done in awk, NOT with `comm`: `comm` compares LEXICALLY, so a numerically
  # sorted list puts 10 before 9 and the diff is nonsense. This is the same class of trap as the
  # tab-in-IFS one and it produces a clean-looking, wrong answer.
  awk -F'\t' '{print $2}' "$VOLUME_NUMBERS" | LC_ALL=C sort -n -u > "$work/vols_seen.txt"
  awk -v a="$VOL_MIN" -v b="$VOL_MAX" '
    NR==FNR { seen[$1 + 0] = 1; next }
    END {
      miss = 0; extra = 0; n = 0
      lo = a + 0; hi = b + 0
      # `for (v in seen)` yields v as a STRING - always, regardless of how the key was stored. A
      # bare `v < a` is therefore a STRING comparison, and "94" > "115" is true, so every volume
      # above 11 reads as out of range. Coerce with `+ 0` before comparing. Driven: the first run
      # of this assertion reported 96 of 115 volumes "out of range" on a correct list.
      for (v in seen) { n++; vv = v + 0; if (vv < lo || vv > hi) { printf("      unexpected volume: %d\n", vv) > "/dev/stderr"; extra++ } }
      for (v = lo; v <= hi; v++) if (!((v "") in seen)) { printf("      missing volume: %d\n", v) > "/dev/stderr"; miss++ }
      printf("%d\t%d\t%d\n", n, miss, extra)
    }
  ' "$work/vols_seen.txt" /dev/null > "$work/coverage.tsv" 2> "$work/coverage.err"

  local n_seen n_missing n_extra
  n_seen="$(awk -F'\t' '{print $1}' "$work/coverage.tsv")"
  n_missing="$(awk -F'\t' '{print $2}' "$work/coverage.tsv")"
  n_extra="$(awk -F'\t' '{print $3}' "$work/coverage.tsv")"
  if [[ "$n_missing" != "0" || "$n_extra" != "0" || "$n_seen" != "$((VOL_MAX - VOL_MIN + 1))" ]]; then
    fail "coverage: expected exactly ${VOL_MIN}..${VOL_MAX}; got $n_seen distinct, $n_missing missing, $n_extra out of range"
    cat "$work/coverage.err" >&2
    return 1
  fi
  pass "total coverage: exactly ${VOL_MIN} through ${VOL_MAX}, no gaps, nothing out of range"

  # The variant-edition merge: every duplicate number must carry a recorded variant annotation, or
  # the merge is folding two things that are not editions of one another.
  awk -F'\t' '{c[$2]++} END {for (v in c) if (c[v] > 1) print v "\t" c[v]}' "$VOLUME_NUMBERS" \
    | LC_ALL=C sort -n > "$work/merged_vols.tsv"
  # FILENAME==ARGV[1], never NR==FNR: an EMPTY first file makes NR==FNR true for the first line of
  # the SECOND file too, which silently mis-classifies one row.
  local n_merged merged_dirs bad_merge
  n_merged="$(wc -l < "$work/merged_vols.tsv" | tr -d '[:space:]')"
  merged_dirs="$(awk -F'\t' 'FILENAME==ARGV[1] {m[$1]=1; next} ($2 in m)' "$work/merged_vols.tsv" "$VOLUME_NUMBERS" | wc -l | tr -d '[:space:]')"
  bad_merge="$(awk -F'\t' 'FILENAME==ARGV[1] {m[$1]=1; next} ($2 in m) && $4 == ""' "$work/merged_vols.tsv" "$VOLUME_NUMBERS" | wc -l | tr -d '[:space:]')"
  echo ""
  echo "==> Variant-edition merge (operator decision 1)"
  printf '    %-42s %s\n' "volume numbers with >1 directory" "$n_merged"
  printf '    %-42s %s\n' "directories folded by the merge"  "$merged_dirs"
  awk -F'\t' 'FILENAME==ARGV[1] {m[$1]=1; next} ($2 in m) {printf "      Vol %03d  <-  %s   %s\n", $2, $1, ($4 == "" ? "(NO VARIANT ANNOTATION)" : $4)}' \
    "$work/merged_vols.tsv" "$VOLUME_NUMBERS"
  if [[ "$bad_merge" != "0" ]]; then
    fail "$bad_merge directory(ies) share a volume number without carrying a variant-edition annotation"
    echo "    A merge with no recorded edition name is a collision, not an edition. Refusing." >&2
    return 1
  fi
  pass "every merged directory carries a recorded variant-edition annotation"

  # ══ CLAIMS: leaf -> the set of VOLUME NUMBERS claiming it ══════════════════
  # Merging happens HERE, which is why most of the 23 flatten collisions dissolve: two editions of
  # volume 4 claiming one leaf collapse to a single claim on volume 4.
  awk -F'\t' -v OFS='\t' '
    FILENAME==ARGV[1] { vnum[$1] = $2; next }
    {
      leaf = $1; d = $2
      if (!(d in vnum)) { print "NO_VOLUME_NUMBER_FOR_DIRECTORY\t" d > "/dev/stderr"; bad = 1; next }
      v = vnum[d]
      k = leaf SUBSEP v
      if (!(k in seen)) { seen[k] = 1; cl[leaf] = cl[leaf] (cl[leaf] == "" ? "" : ",") v; n[leaf]++ }
    }
    END {
      if (bad) exit 3
      for (l in cl) {
        # numeric insertion sort so the claim list is deterministic in the record
        m = split(cl[l], a, ",")
        for (i = 2; i <= m; i++) { x = a[i] + 0; j = i - 1; while (j >= 1 && (a[j] + 0) > x) { a[j+1] = a[j]; j-- } a[j+1] = x }
        out = a[1]
        for (i = 2; i <= m; i++) out = out "," a[i]
        print l, out, m
      }
    }
  ' "$VOLUME_NUMBERS" "$work/man.tsv" > "$work/claims.tsv" \
    || { fail "a manifest directory has no derived volume number - see the line(s) above"; return 1; }

  # ══ JOIN: disk basename -> manifest leaf, in two stages ════════════════════
  # Stage 1 is an exact match. Stage 2 (residuals only) uses an alphanumerics-only key, because the
  # ripper wrote Hangul and a Greek capital lambda as literal `?` and no decoding recovers them. A
  # stage-2 match is accepted ONLY if it is unique on BOTH sides; anything ambiguous is reported
  # unresolved and routed to quarantine, never guessed.
  awk -F'\t' -v OFS='\t' '
    NR==FNR { leaf[$1] = 1; next }
    { if ($2 in leaf) print $2, "exact"; else print $2, "residual" }
  ' "$work/man.tsv" "$work/tags.tsv" > "$work/stage1.tsv"

  awk -F'\t' '$2=="residual" {print $1}' "$work/stage1.tsv" | LC_ALL=C sort -u > "$work/disk_res.txt"
  awk -F'\t' 'NR==FNR {have[$2]=1; next} !($1 in have) {print $1}' \
      "$work/tags.tsv" "$work/man.tsv" | LC_ALL=C sort -u > "$work/man_res.txt"
  awk '{k=$0; gsub(/[^A-Za-z0-9]/, "", k); printf "%s\t%s\n", k, $0}' "$work/disk_res.txt" > "$work/disk_res_k.tsv"
  awk '{k=$0; gsub(/[^A-Za-z0-9]/, "", k); printf "%s\t%s\n", k, $0}' "$work/man_res.txt"  > "$work/man_res_k.tsv"
  awk -F'\t' -v OFS='\t' '
    NR==FNR { n[$1]++; v[$1] = $2; next }
    { if (n[$1] == 1) print $2, v[$1], "alnum"; else print $2, "", "unresolved" }
  ' "$work/man_res_k.tsv" "$work/disk_res_k.tsv" > "$work/stage2.tsv"

  {
    awk -F'\t' -v OFS='\t' '$2=="exact" {print $1, $1}' "$work/stage1.tsv"
    awk -F'\t' -v OFS='\t' '$3=="alnum" {print $1, $2}' "$work/stage2.tsv"
  } > "$work/b2l.tsv"

  local n_exact n_alnum n_unresolved
  n_exact="$(awk -F'\t' '$2=="exact"' "$work/stage1.tsv" | wc -l | tr -d '[:space:]')"
  n_alnum="$(awk -F'\t' '$3=="alnum"' "$work/stage2.tsv" | wc -l | tr -d '[:space:]')"
  n_unresolved="$(awk -F'\t' '$3=="unresolved"' "$work/stage2.tsv" | wc -l | tr -d '[:space:]')"
  echo ""
  echo "==> Join (disk basename -> manifest leaf)"
  printf '    %-42s %s\n' "stage 1, exact"                  "$n_exact"
  printf '    %-42s %s\n' "stage 2, alphanumerics-only key" "$n_alnum"
  printf '    %-42s %s\n' "UNRESOLVED (never guessed)"      "$n_unresolved"

  # ══ THE ALBUM ALIAS TABLE - the INDEPENDENT cross-check (D-02) ═════════════
  # Seeded ONLY from files whose leaf is claimed by exactly ONE volume. That is not a convenience:
  # seeding from collided files would make the alias table depend on the very tie-break that reads
  # it, and a circular instrument cross-checks nothing.
  awk -F'\t' -v OFS='\t' '
    FILENAME==ARGV[1] { b2l[$1] = $2; next }
    FILENAME==ARGV[2] { cl[$1] = $2; nc[$1] = $3; next }
    {
      bn = $2; album = $3
      leaf = b2l[bn]
      if (leaf == "") next
      if (nc[leaf] != 1) next
      if (album == "") next
      cnt[album, cl[leaf]]++
      tot[album]++
      if (!((album, cl[leaf]) in seenav)) { seenav[album, cl[leaf]] = 1; vols[album] = vols[album] (vols[album] == "" ? "" : ",") cl[leaf]; nv[album]++ }
    }
    END {
      for (a in tot) {
        best = -1; modal = ""; tie = 0
        m = split(vols[a], av, ",")
        for (i = 1; i <= m; i++) {
          c = cnt[a, av[i]]
          if (c > best) { best = c; modal = av[i]; tie = 0 }
          else if (c == best && av[i] != modal) { tie = 1 }
        }
        if (nv[a] == 1)      status = "unique"
        else if (tie)        status = "AMBIGUOUS-TIE:" vols[a]
        else                 status = "MODAL-of:" vols[a]
        print a, modal, tot[a], status
      }
    }
  ' "$work/b2l.tsv" "$work/claims.tsv" "$work/tags.tsv" \
    | LC_ALL=C sort -t$'\t' -k2,2n -k1,1 > "$ALBUM_ALIASES"

  local n_alias n_alias_unique n_alias_multi n_alias_tie
  n_alias="$(wc -l < "$ALBUM_ALIASES" | tr -d '[:space:]')"
  n_alias_unique="$(awk -F'\t' '$4=="unique"' "$ALBUM_ALIASES" | wc -l | tr -d '[:space:]')"
  n_alias_multi="$(awk -F'\t' '$4 ~ /^MODAL-of:/' "$ALBUM_ALIASES" | wc -l | tr -d '[:space:]')"
  n_alias_tie="$(awk -F'\t' '$4 ~ /^AMBIGUOUS-TIE:/' "$ALBUM_ALIASES" | wc -l | tr -d '[:space:]')"
  echo ""
  echo "==> Album alias table (the independent cross-check - a LOOKUP, never a regex)"
  printf '    %-42s %s\n' "distinct album strings"       "$n_alias"
  printf '    %-42s %s\n' "mapping to exactly one volume" "$n_alias_unique"
  printf '    %-42s %s\n' "FLAGGED, modal used"           "$n_alias_multi"
  printf '    %-42s %s\n' "FLAGGED, tied and unresolved"  "$n_alias_tie"
  printf '    %-42s %s\n' "emitted to"                    "$ALBUM_ALIASES"

  # ══ FILESYSTEM METADATA - the per-row fence input ══════════════════════════
  # One `find` pass rather than 4,751 `stat` calls. A symlink, a non-regular file or a link count
  # above one is REFUSED by name: normalise-dj-tags.py's CR-04 recorded that fencing the target
  # alone was not enough, because a single symlink under the tree defeated the fence silently.
  find "$NOW_ROOT" -maxdepth 1 -mindepth 1 -printf '%p\t%y\t%n\n' | LC_ALL=C sort > "$work/fsmeta.tsv"

  # ══ THE DECISION ENGINE ════════════════════════════════════════════════════
  awk -F'\t' -v OFS='\t' \
      -v NOW_ROOT="$NOW_ROOT" -v QUAR="$QUARANTINE" \
      -v COLLOUT="$work/collisions.tsv" '
    function volpath(v) { return sprintf("%s/Vol %03d", NOW_ROOT, v) }

    FILENAME==ARGV[1] { b2l[$1] = $2; next }
    FILENAME==ARGV[2] { cl[$1] = $2; nc[$1] = $3; next }
    FILENAME==ARGV[3] { avol[$1] = $2; astat[$1] = $4; next }
    FILENAME==ARGV[4] { ftype[$1] = $2; flink[$1] = $3; next }
    {
      path = $1; bn = $2; album = $3; disc = $4; track = $5; tt = $6

      # ---- the per-row fence -------------------------------------------------
      if (ftype[path] != "f" || flink[path] + 0 != 1) {
        reason = (path in ftype) ? ("type=" ftype[path] " nlink=" flink[path]) : "not found in the live tree"
        print path, "", "", "fence-refusal(" reason ")", "REFUSED"
        refused++
        next
      }

      leaf = b2l[bn]
      if (leaf == "" || !(leaf in cl)) {
        print path, QUAR "/" bn, "", "manifest(unjoined)", "UNJOINED"
        disagree++; unjoined++
        next
      }

      claims = cl[leaf]; m = nc[leaf]
      alias_v = (album in avol) ? avol[album] : ""

      if (m == 1) {
        mv = claims + 0
        if (alias_v == "") {
          print path, QUAR "/" bn, mv, "manifest(alias-absent)", "ALIAS-ABSENT"
          disagree++; aliasabsent++
          next
        }
        if (alias_v + 0 != mv) {
          print path, QUAR "/" bn, mv, "manifest(alias-says-" alias_v ")", "DISAGREE"
          disagree++; aliasdisagree++
          next
        }
        print path, volpath(mv) "/" bn, mv, "manifest", "AGREE"
        mapped++
        next
      }

      # ---- a CROSS-VOLUME collision: a physical file claimed by >1 volume ----
      split(claims, cv, ",")
      inset = 0
      for (i = 1; i <= m; i++) if (alias_v != "" && cv[i] + 0 == alias_v + 0) inset = 1

      if (inset && astat[album] !~ /^AMBIGUOUS-TIE:/) {
        rej = ""
        for (i = 1; i <= m; i++) if (cv[i] + 0 != alias_v + 0) rej = rej (rej == "" ? "" : ",") cv[i]
        print path, volpath(alias_v + 0) "/" bn, alias_v + 0, \
              "manifest+albumtag(won=" alias_v ";rejected=" rej ")", "TIEBREAK-ALBUMTAG"
        mapped++; tiebroken++
        printf("%s\t%s\t%s\t%s\t%s\t%s\n", bn, claims, alias_v, rej, album, "RESOLVED-BY-ALBUM-TAG") > COLLOUT
        next
      }

      # The album tag does NOT disambiguate. DO NOT GUESS.
      print path, QUAR "/" bn, "", "manifest+albumtag(FLAGGED;claims=" claims ")", "FLAGGED-CROSS-VOLUME"
      disagree++; flagged++
      printf("%s\t%s\t%s\t%s\t%s\t%s\n", bn, claims, "", claims, album, "FLAGGED-FOR-OPERATOR-REVIEW") > COLLOUT
    }
    END {
      printf("__STATS__\tmapped=%d\tdisagree=%d\trefused=%d\tunjoined=%d\taliasabsent=%d\taliasdisagree=%d\tflagged=%d\ttiebroken=%d\n",
             mapped + 0, disagree + 0, refused + 0, unjoined + 0, aliasabsent + 0, aliasdisagree + 0, flagged + 0, tiebroken + 0) > "/dev/stderr"
    }
  ' "$work/b2l.tsv" "$work/claims.tsv" "$ALBUM_ALIASES" "$work/fsmeta.tsv" "$work/tags.tsv" \
    > "$work/map.mp3.tsv" 2> "$work/engine.stats"

  local stats
  stats="$(grep '^__STATS__' "$work/engine.stats" || true)"
  grep -v '^__STATS__' "$work/engine.stats" >&2 || true
  [[ -n "$stats" ]] || { fail "the decision engine produced no statistics line"; return 1; }

  # A counter read back as an empty string would make every downstream arithmetic comparison lie,
  # so each one is defaulted to 0 explicitly rather than inheriting whatever the parse produced.
  local mapped disagree refused unjoined aliasabsent aliasdisagree flagged tiebroken k
  for k in mapped disagree refused unjoined aliasabsent aliasdisagree flagged tiebroken; do
    printf -v "$k" '%s' "$(printf '%s' "$stats" | tr '\t' '\n' | awk -F= -v K="$k" '$1==K {print $2+0}')"
    [[ -n "${!k}" ]] || printf -v "$k" '%s' 0
  done

  if [[ -s "$work/collisions.tsv" ]]; then
    LC_ALL=C sort "$work/collisions.tsv" > "$COLLISIONS"
  else
    : > "$COLLISIONS"
  fi

  # ══ THE KEPT SIDECARS (D-06, by-value triage reached by OPENING the files) ══
  # Matched by an explicit rule per file, with the sidecar set asserted first. The volume-115 cue's
  # own filename carries a typographic apostrophe the ripper wrote; it is matched by extension with
  # a uniqueness assertion rather than by embedding that character in this file.
  find "$NOW_ROOT" -maxdepth 1 -type f ! -iname '*.mp3' -printf '%p\n' | LC_ALL=C sort > "$work/sidecars.txt"
  local n_side n_cue n_m3u
  n_side="$(wc -l < "$work/sidecars.txt" | tr -d '[:space:]')"
  n_cue="$(grep -c -i '\.cue$' "$work/sidecars.txt" || true)"
  n_m3u="$(grep -c -i '\.m3u$' "$work/sidecars.txt" || true)"
  echo ""
  echo "==> Kept sidecars (D-06)"
  printf '    %-42s %s\n' "non-mp3 files at the collection root" "$n_side"
  printf '    %-42s %s\n' ".cue files (expect exactly 1)"        "$n_cue"
  printf '    %-42s %s\n' ".m3u files (expect exactly 1)"        "$n_m3u"
  if [[ "$n_cue" != "1" || "$n_m3u" != "1" ]]; then
    fail "the sidecar set is not the shape D-06 triaged: cue=$n_cue m3u=$n_m3u"
    echo "    D-06's verdicts were reached by OPENING the files. A changed set must be re-triaged," >&2
    echo "    not routed by extension. Refusing." >&2
    return 1
  fi

  local sidecar_rows=0 sidecar_unmatched=0 s bnm dstp
  : > "$work/map.side.tsv"
  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    bnm="${s##*/}"
    case "$bnm" in
      back.bmp|cd1.bmp|cd2.bmp)
        dstp="$(printf '%s/Vol %03d/%s' "$NOW_ROOT" 77 "$bnm")"
        printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$dstp" "77" "sidecar-d06(NOW-77-case-scan)" "SIDECAR" >> "$work/map.side.tsv"
        sidecar_rows=$((sidecar_rows + 1)) ;;
      *.cue|*.CUE)
        dstp="$(printf '%s/Vol %03d/%s' "$NOW_ROOT" 115 "$bnm")"
        printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$dstp" "115" "sidecar-d06(EAC-cue-vol-115)" "SIDECAR" >> "$work/map.side.tsv"
        sidecar_rows=$((sidecar_rows + 1)) ;;
      *.m3u|*.M3U)
        # The map STAYS at the collection root, beside the collection it maps. dst == src, so this
        # row is an explicit no-op for `apply` rather than an omission a reader has to infer.
        printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$s" "" "sidecar-d06(the-map;stays-at-root)" "SIDECAR-IN-PLACE" >> "$work/map.side.tsv"
        sidecar_rows=$((sidecar_rows + 1)) ;;
      *)
        fail "unrecognised sidecar, not in D-06's triage: $bnm"
        sidecar_unmatched=$((sidecar_unmatched + 1)) ;;
    esac
  done < "$work/sidecars.txt"
  if [[ "$sidecar_unmatched" != "0" ]]; then
    fail "$sidecar_unmatched sidecar(s) matched no D-06 rule - refusing to route a file nobody opened"
    return 1
  fi

  # ══ EMIT THE MAP ═══════════════════════════════════════════════════════════
  cat "$work/map.mp3.tsv" "$work/map.side.tsv" | LC_ALL=C sort > "$work/map.all.tsv"

  # Shape and fence assertions over the emitted rows, BEFORE the file is published.
  local badfields
  badfields="$(awk -F'\t' 'NF!=5' "$work/map.all.tsv" | wc -l | tr -d '[:space:]')"
  [[ "$badfields" == "0" ]] || { fail "$badfields map row(s) do not carry exactly 5 fields"; return 1; }

  local out_of_scope cd_components dup_src dup_dst
  out_of_scope="$(awk -F'\t' -v R="$NOW_ROOT" -v Q="$QUARANTINE" '
      $5 == "REFUSED" { next }
      index($1, R "/") != 1 { print; next }
      index($2, R "/") != 1 && index($2, Q "/") != 1 { print }
    ' "$work/map.all.tsv" | wc -l | tr -d '[:space:]')"
  [[ "$out_of_scope" == "0" ]] || { fail "$out_of_scope map row(s) name a path outside the fence"; return 1; }

  cd_components="$(awk -F'\t' '$2 ~ /\/CD[0-9]+\//' "$work/map.all.tsv" | wc -l | tr -d '[:space:]')"
  [[ "$cd_components" == "0" ]] || { fail "$cd_components destination(s) contain a CD subdirectory - D-05 says the split is FLAT"; return 1; }

  dup_src="$(awk -F'\t' '{c[$1]++} END {n=0; for (k in c) if (c[k] > 1) n++; print n+0}' "$work/map.all.tsv")"
  [[ "$dup_src" == "0" ]] || { fail "$dup_src source path(s) appear more than once - a file can only be moved once"; return 1; }
  dup_dst="$(awk -F'\t' '$5 != "REFUSED" {c[$2]++} END {n=0; for (k in c) if (c[k] > 1) n++; print n+0}' "$work/map.all.tsv")"
  [[ "$dup_dst" == "0" ]] || { fail "$dup_dst destination path(s) are claimed by more than one source"; return 1; }

  cp -- "$work/map.all.tsv" "$SPLIT_MAP"

  # ══ PER-VOLUME IDENTITY AND THE NAMED SHORTFALL ════════════════════════════
  # The (volume,disc) tracktotal expectation is the MODAL value, never the first one seen: plan
  # 05-05 measured that first-wins let one leaf-collided intruder set a whole disc's expectation and
  # produced three FALSE exceptions. The missing track NUMBERS are then named (operator decision 2)
  # rather than reported as a count, because a count cannot be checked against the source rip.
  awk -F'\t' -v OFS='\t' -v MISS="$work/missing.tsv" '
    FILENAME==ARGV[1] {
      if ($5 == "AGREE" || $5 == "TIEBREAK-ALBUMTAG") { vol[$1] = $3 }
      next
    }
    {
      p = $1
      if (!(p in vol)) next
      v = vol[p] + 0; d = $4; t = $5; tt = $6
      files[v]++
      if (tt == "") { nulltt[v]++ }
      else { votes[v SUBSEP d SUBSEP tt]++; if (!((v SUBSEP d) in seen)) { seen[v SUBSEP d] = 1; keys[++nk] = v SUBSEP d } }
      if (t != "") present[v SUBSEP d SUBSEP (t + 0)] = 1
    }
    END {
      for (kt in votes) {
        split(kt, p3, SUBSEP); k = p3[1] SUBSEP p3[2]
        if (votes[kt] > best[k]) { best[k] = votes[kt]; modal[k] = p3[3] }
      }
      for (i = 1; i <= nk; i++) {
        k = keys[i]; split(k, p2, SUBSEP); v = p2[1] + 0; d = p2[2]
        # NOT named `exp`: that is an awk BUILT-IN FUNCTION, and using it as a variable is a
        # syntax error in some implementations and a silent shadow in others.
        want = modal[k] + 0
        sumtt[v] += want
        miss = ""; nmiss = 0; npres = 0
        for (t = 1; t <= want; t++) {
          if ((v SUBSEP d SUBSEP t) in present) npres++
          else { miss = miss (miss == "" ? "" : ",") t; nmiss++ }
        }
        if (nmiss > 0) printf("%d\t%s\t%d\t%d\t%s\n", v, d, want, npres, miss) > MISS
      }
      for (v in files) printf("%d\t%d\t%d\n", v, files[v], sumtt[v] + 0)
    }
  ' "$work/map.all.tsv" "$work/tags.tsv" | LC_ALL=C sort -n > "$work/pervol.tsv"

  if [[ -s "$work/missing.tsv" ]]; then
    LC_ALL=C sort -n "$work/missing.tsv" > "$MISSING_TRACKS"
  else
    : > "$MISSING_TRACKS"
  fi

  local n_volfolders n_balanced n_exceptions sum_pervol n_missing_rows n_missing_tracks
  n_volfolders="$(wc -l < "$work/pervol.tsv" | tr -d '[:space:]')"
  n_balanced="$(awk -F'\t' '$2==$3' "$work/pervol.tsv" | wc -l | tr -d '[:space:]')"
  n_exceptions="$(awk -F'\t' '$2!=$3' "$work/pervol.tsv" | wc -l | tr -d '[:space:]')"
  sum_pervol="$(awk -F'\t' '{s+=$2} END {print s+0}' "$work/pervol.tsv")"
  n_missing_rows="$(wc -l < "$MISSING_TRACKS" | tr -d '[:space:]')"
  n_missing_tracks="$(awk -F'\t' '{n = split($5, a, ","); s += n} END {print s+0}' "$MISSING_TRACKS")"

  # ══ MANIFEST-ONLY ENTRIES - their OWN line, folded into nothing ════════════
  local n_manifest_only n_dup_leaf_lines n_dup_leaves n_crossvol
  n_manifest_only="$(awk -F'\t' 'NR==FNR {have[$2]=1; next} !($1 in have)' \
      "$work/b2l.tsv" "$work/man.tsv" | wc -l | tr -d '[:space:]')"
  n_dup_leaf_lines="$(awk -F'\t' '{c[$1]++} END {n=0; for (k in c) if (c[k] > 1) n += c[k] - 1; print n+0}' "$work/man.tsv")"
  n_dup_leaves="$(awk -F'\t' '{c[$1]++} END {n=0; for (k in c) if (c[k] > 1) n++; print n+0}' "$work/man.tsv")"
  n_crossvol="$(awk -F'\t' '$3 > 1' "$work/claims.tsv" | wc -l | tr -d '[:space:]')"

  # ══ THE RECONCILIATION, ASSERTED RATHER THAN HOPED FOR ═════════════════════
  # The four buckets are meant to be DISJOINT and to account for every file counted into
  # files_seen. Every path takes exactly one route. normalise-dj-tags.py's WR-06 records a live
  # defect where one file landed in two buckets and the total never balanced, which is why this is
  # stated as an equation and asserted rather than printed and eyeballed.
  local files_seen bucket_sum map_rows kept_sidecars
  files_seen=$((tag_rows + n_side))
  kept_sidecars="$sidecar_rows"
  bucket_sum=$((mapped + disagree + kept_sidecars + refused))
  map_rows="$(wc -l < "$SPLIT_MAP" | tr -d '[:space:]')"

  {
    echo "phase05-now-split plan"
    echo "generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "now root:  $NOW_ROOT"
    echo "map:       $SPLIT_MAP"
    echo ""
    echo "== THE DISJOINT-BUCKET EQUATION =="
    echo "  files_seen = mapped-to-a-volume + routed-to-disagreement + kept-sidecar + refused-by-fence"
    printf '  %-46s %s\n' "mp3 records (now-tags.ndjson)"   "$tag_rows"
    printf '  %-46s %s\n' "non-mp3 sidecars at the root"    "$n_side"
    printf '  %-46s %s\n' "files_seen"                      "$files_seen"
    printf '  %-46s %s\n' "  mapped to a volume"            "$mapped"
    printf '  %-46s %s\n' "  routed to disagreement"        "$disagree"
    printf '  %-46s %s\n' "  kept sidecar"                  "$kept_sidecars"
    printf '  %-46s %s\n' "  refused by fence"              "$refused"
    printf '  %-46s %s\n' "bucket sum"                      "$bucket_sum"
    printf '  %-46s %s\n' "map rows emitted"                "$map_rows"
    echo ""
    echo "  routed-to-disagreement, broken out (these are NOT junk and must not be deleted):"
    printf '    %-44s %s\n' "album tag disagrees with the manifest" "$aliasdisagree"
    printf '    %-44s %s\n' "album string absent from the alias table" "$aliasabsent"
    printf '    %-44s %s\n' "cross-volume collision, FLAGGED"         "$flagged"
    printf '    %-44s %s\n' "no manifest entry at all"                "$unjoined"
    echo ""
    echo "== VOLUME NUMBER DERIVATION =="
    printf '  %-46s %s\n' "distinct manifest volume directories" "$dirname_rows"
    printf '  %-46s %s\n' "distinct volume numbers derived"      "$n_seen"
    printf '  %-46s %s\n' "volume numbers with >1 directory"     "$n_merged"
    printf '  %-46s %s\n' "directories folded by the merge"      "$merged_dirs"
    printf '  %-46s %s\n' "volume folders in the map"            "$n_volfolders"
    echo ""
    echo "== THE FLATTEN COLLISION, AFTER THE VARIANT-EDITION MERGE =="
    printf '  %-46s %s\n' "manifest lines beyond the first per leaf"   "$n_dup_leaf_lines"
    printf '  %-46s %s\n' "distinct leaves carried by >1 line"         "$n_dup_leaves"
    printf '  %-46s %s\n' "leaves still claimed by >1 VOLUME NUMBER"   "$n_crossvol"
    printf '  %-46s %s\n' "  resolved by the album tag"                "$tiebroken"
    printf '  %-46s %s\n' "  FLAGGED for operator review"              "$flagged"
    printf '  %-46s %s\n' "named in"                                   "$COLLISIONS"
    echo ""
    echo "== MANIFEST-ONLY ENTRIES - their own line, folded into nothing =="
    printf '  %-46s %s\n' "m3u lines with no file on disk"  "$n_manifest_only"
    echo ""
    echo "== JOIN =="
    printf '  %-46s %s\n' "stage 1, exact"                  "$n_exact"
    printf '  %-46s %s\n' "stage 2, alphanumerics-only key" "$n_alnum"
    printf '  %-46s %s\n' "UNRESOLVED (never guessed)"      "$n_unresolved"
    echo ""
    echo "== PER-VOLUME IDENTITY: files_present == sum of (modal) tracktotal =="
    printf '  %-46s %s\n' "volume folders"          "$n_volfolders"
    printf '  %-46s %s\n' "balanced"                "$n_balanced"
    printf '  %-46s %s\n' "EXCEPTIONS"              "$n_exceptions"
    printf '  %-46s %s\n' "sum of per-volume files" "$sum_pervol"
    echo ""
    echo "  volume | files | sum(tracktotal) | delta"
    awk -F'\t' '$2!=$3 {printf "  EXC  Vol %03d | %s | %s | %+d\n", $1, $2, $3, $2-$3}' "$work/pervol.tsv"
    echo ""
    echo "== THE SHORTFALL, NAMED TRACK BY TRACK (operator decision 2) =="
    printf '  %-46s %s\n' "(volume,disc) groups short"  "$n_missing_rows"
    printf '  %-46s %s\n' "missing tracks in total"     "$n_missing_tracks"
    printf '  %-46s %s\n' "named in"                    "$MISSING_TRACKS"
    echo ""
    awk -F'\t' '{printf "  Vol %03d disc %s: expected %s, present %s, MISSING track(s) %s\n", $1, $2, $3, $4, $5}' "$MISSING_TRACKS"
    echo ""
    echo "  --- all volume folders ---"
    awk -F'\t' '{printf "  %-4s Vol %03d | %s | %s | %+d\n", ($2==$3?"ok":"EXC"), $1, $2, $3, $2-$3}' "$work/pervol.tsv"
  } > "$RECONCILIATION"

  cat "$RECONCILIATION"

  echo ""
  info "split map:        $SPLIT_MAP"
  info "volume numbers:   $VOLUME_NUMBERS"
  info "album aliases:    $ALBUM_ALIASES"
  info "cross-vol coll.:  $COLLISIONS"
  info "missing tracks:   $MISSING_TRACKS"
  info "reconciliation:   $RECONCILIATION"

  echo ""
  if [[ "$bucket_sum" != "$files_seen" ]]; then
    fail "the buckets do not sum to files_seen: $bucket_sum != $files_seen"
    return 1
  fi
  pass "the four buckets are disjoint and sum to files_seen ($files_seen)"
  if [[ "$map_rows" != "$files_seen" ]]; then
    fail "map rows ($map_rows) != files_seen ($files_seen)"
    return 1
  fi
  pass "every file appears in the map exactly once ($map_rows rows)"

  echo ""
  warn "NOTHING HAS BEEN MOVED. No directory was created inside the collection."
  warn "An operator must read and approve $SPLIT_MAP before 'apply' will act."
  # plan REPORTS; it does not assert the mapping is correct. That is what the review is for.
  return 0
}

# ══════════════════════════════════════════════════════════════════════════════
do_apply() {
  banner "phase05-now-split apply"

  # ── REFUSAL 1: the approved mapping ────────────────────────────────────────
  # Checked FIRST, before anything else is required, so it is reachable and testable anywhere -
  # including on a workstation with no access to tank at all.
  if [[ ! -f "$SPLIT_MAP" ]]; then
    echo -e "${RED}❌ split map not found: $SPLIT_MAP${NC}" >&2
    echo "   Run 'bash scripts/phase05-now-split.sh plan' first, then have the mapping approved" >&2
    echo "   by the operator. Refusing to guess where 4,751 files belong." >&2
    exit 2
  fi

  # ── REFUSAL 2: the rollback snapshot, proven ───────────────────────────────
  if [[ ! -f "$SPLIT_MAP" || ! -r "$SPLIT_MAP" ]]; then
    echo -e "${RED}❌ split map is not readable: $SPLIT_MAP${NC}" >&2
    exit 2
  fi
  if [[ ! -f "$SNAPSHOT_PROOF" || ! -r "$SNAPSHOT_PROOF" ]]; then
    echo -e "${RED}❌ snapshot proof not found or unreadable: $SNAPSHOT_PROOF${NC}" >&2
    echo "   ${SNAPSHOT_NAME} is this subcommand's ONLY rollback, and zfs cannot resolve on" >&2
    echo "   LXC 100. Produce the proof on atlantis and place it at that path:" >&2
    echo "     ssh -o BatchMode=yes -o ConnectTimeout=5 root@172.16.1.158 \\" >&2
    echo "       'zfs list -t snapshot -H -o name ${SNAPSHOT_NAME}' > ${SNAPSHOT_PROOF}" >&2
    echo "   An unreachable atlantis means the snapshot state is UNKNOWN, which is a refusal," >&2
    echo "   not a skip and not a pass." >&2
    exit 2
  fi
  if ! grep -qF -- "$SNAPSHOT_NAME" "$SNAPSHOT_PROOF"; then
    echo -e "${RED}❌ snapshot proof does not name ${SNAPSHOT_NAME}${NC}" >&2
    echo "   proof file: $SNAPSHOT_PROOF" >&2
    echo "   contents:   $(head -c 200 "$SNAPSHOT_PROOF" | tr '\n' ' ')" >&2
    echo "   The existing @pre-project and @pre-chown snapshots are a month stale: rolling back to" >&2
    echo "   one of them would discard a month of unrelated downloads. A proof naming the wrong" >&2
    echo "   snapshot MUST fail. Refusing." >&2
    exit 2
  fi
  pass "rollback proven: $SNAPSHOT_NAME"
  pass "mapping present: $SPLIT_MAP"

  [[ -d "$NOW_ROOT" ]] || { fail "NOW_ROOT does not exist: $NOW_ROOT"; exit 2; }

  # ── RE-VALIDATE EVERY ROW AGAINST LIVE STATE BEFORE ACTING ─────────────────
  # The approval says which moves the operator is willing to make, not that the tree still looks
  # the way it did when the map was written. The download tree is live at ~1 job / 72 s, so the
  # whole run aborts on conflict rather than skipping a row.
  echo ""
  echo "==> Re-validating the map against live state"
  local conflicts=0 rows=0 src dst vol inst agr
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    rows=$((rows + 1))
    src="$(printf '%s' "$line" | awk -F'\t' '{print $1}')"
    dst="$(printf '%s' "$line" | awk -F'\t' '{print $2}')"
    agr="$(printf '%s' "$line" | awk -F'\t' '{print $5}')"
    [[ "$agr" == "REFUSED" ]] && continue
    [[ "$src" == "$dst" ]] && continue
    if ! src_in_scope "$src"; then
      fail "row $rows: source is outside the fence: $src"; conflicts=$((conflicts + 1)); continue
    fi
    if ! dst_in_scope "$dst"; then
      fail "row $rows: destination is outside the fence: $dst"; conflicts=$((conflicts + 1)); continue
    fi
    if [[ -L "$src" ]]; then
      fail "row $rows: source is a symlink: $src"; conflicts=$((conflicts + 1)); continue
    fi
    if [[ ! -f "$src" ]]; then
      if [[ -f "$dst" ]]; then continue; fi
      fail "row $rows: source is gone and destination does not exist: $src"; conflicts=$((conflicts + 1)); continue
    fi
    if [[ -e "$dst" ]]; then
      fail "row $rows: destination already exists: $dst"; conflicts=$((conflicts + 1)); continue
    fi
  done < "$SPLIT_MAP"

  if [[ "$conflicts" -gt 0 ]]; then
    fail "aborting: $conflicts row(s) conflict with live state. NOTHING MOVED."
    exit 1
  fi
  pass "$rows row(s) re-validated against live state"

  # ── CREATE THE VOLUME DIRECTORIES ──────────────────────────────────────────
  local dirs
  dirs="$(awk -F'\t' '$5 != "REFUSED" && $1 != $2 {d = $2; sub(/\/[^/]*$/, "", d); print d}' "$SPLIT_MAP" | LC_ALL=C sort -u)"
  local d
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    dst_in_scope "$d/x" || { fail "refusing to create a directory outside the fence: $d"; exit 1; }
    mkdir -p -- "$d"
  done <<< "$dirs"
  pass "volume directories present"

  # ── RENAME, ONE ROW AT A TIME, BY NAME FROM THE MAP ────────────────────────
  # Failures are COLLECTED rather than aborted on: one stuck file must not strand the rest.
  local moved=0 already=0 errors=0 inode_before inode_after
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    src="$(printf '%s' "$line" | awk -F'\t' '{print $1}')"
    dst="$(printf '%s' "$line" | awk -F'\t' '{print $2}')"
    agr="$(printf '%s' "$line" | awk -F'\t' '{print $5}')"
    [[ "$agr" == "REFUSED" ]] && continue
    if [[ "$src" == "$dst" ]]; then already=$((already + 1)); continue; fi
    if [[ ! -f "$src" && -f "$dst" ]]; then already=$((already + 1)); continue; fi
    inode_before="$(stat -c '%i' -- "$src" 2>/dev/null || echo '')"
    if mv -n -- "$src" "$dst" 2>/dev/null; then
      inode_after="$(stat -c '%i' -- "$dst" 2>/dev/null || echo '')"
      if [[ -z "$inode_before" || "$inode_before" != "$inode_after" ]]; then
        # _inbox, unsorted and dj-mixes are one dataset, so every move here MUST be an
        # inode-preserving rename(2). A changed inode means it was a copy-then-unlink, which means
        # someone made a dataset boundary appear where D-18 says one must never be.
        fail "inode changed across the move ($inode_before -> $inode_after): $dst"
        errors=$((errors + 1))
      else
        moved=$((moved + 1))
      fi
    else
      fail "mv failed, left in place: $src"
      errors=$((errors + 1))
    fi
  done < "$SPLIT_MAP"

  echo ""
  echo "📊 apply summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  moved:       $moved"
  echo "  no-op:       $already"
  echo "  errors:      $errors"

  # ── RE-RUN THE RECONCILIATION FROM THE RESULTING TREE, NOT FROM THE MAP ────
  local tree_files map_expect
  tree_files="$(find "$NOW_ROOT" -mindepth 2 -maxdepth 2 -type f -printf '.' | wc -c | tr -d '[:space:]')"
  map_expect="$(awk -F'\t' -v R="$NOW_ROOT" '$5 != "REFUSED" && index($2, R "/Vol ") == 1' "$SPLIT_MAP" | wc -l | tr -d '[:space:]')"
  echo "  files now inside volume folders: $tree_files"
  echo "  the map expects:                 $map_expect"
  if [[ "$tree_files" != "$map_expect" ]]; then
    fail "post-move reconciliation does not balance: tree=$tree_files map=$map_expect"
    return 1
  fi
  pass "post-move reconciliation balances, measured from the resulting tree"

  if [[ "$errors" -gt 0 ]]; then
    fail "$errors row(s) failed"
    return 1
  fi
  return 0
}

case "$ACTION" in
  plan)  do_plan ;;
  apply) do_apply ;;
esac
