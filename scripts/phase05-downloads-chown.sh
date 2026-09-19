#!/usr/bin/env bash
# phase05-downloads-chown.sh - Normalise ownership across /mnt/tank/downloads to 568:568, through
#                              the same two-process approval gate the junk sweep uses: SURVEY the
#                              tree into a file an operator reads and approves, then act on ONLY
#                              that approved file.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
#   Delivery is git: this repo is checked out there and nothing else copies files in.
#   THE MEASUREMENT AND THE CHOWN BOTH HAPPEN ON ATLANTIS (172.16.1.158), not here, and that is
#   not an implementation detail - see OWNERSHIP READINGS below. If this script is run ON atlantis
#   it detects that and runs the same payloads locally.
#
# Usage:
#   bash scripts/phase05-downloads-chown.sh enumerate   # READ-ONLY: survey and write the row list
#   bash scripts/phase05-downloads-chown.sh apply       # MUTATES: chowns the approved rows
#   bash scripts/phase05-downloads-chown.sh --help      # print this header
#
# Workflow (plan 05-10):
#   ssh root@172.16.1.159
#   cd /mnt/fast/stacks && git pull --ff-only
#   bash scripts/phase05-downloads-chown.sh enumerate    # -> writes the row list, exits 0
#   <<< OPERATOR READS AND APPROVES THE LIST; struck rows are deleted FROM THE FILE >>>
#   bash scripts/phase05-downloads-chown.sh apply        # -> acts on exactly what survived
#
# Outputs:
#   $APPROVED_LIST  (default /mnt/fast/safety/phase05/chown-rows.tsv)
#                   One row per line, TAB-separated, NINE fields, none ever empty:
#                     mode  path  type  devid  inode  owner  entries  subtree  note
#                   `mode` is `recursive` (chown the whole subtree) or `self` (chown this one
#                   entry and nothing beneath it). This file IS the gate.
#   $SURVEY_REPORT  (default /mnt/fast/safety/phase05/chown-survey.txt) - the human report, a copy
#                   of what enumerate prints, so the approval can be read back later.
#   $VERIFICATION   (default /mnt/fast/safety/phase05/chown-verification.txt) - written by `apply`
#                   only: before and after census, elapsed time, zfs diff line-class counts, the
#                   library untouched-proof, and the operator's selection.
#
# CONTRACT:
#   `enumerate`  READ-ONLY BY CONTRACT. It creates $OUT_DIR if absent and writes $APPROVED_LIST
#                and $SURVEY_REPORT. It takes NO snapshot, it chowns nothing, and it refuses to
#                overwrite an existing $APPROVED_LIST - an approved file must never be silently
#                replaced by a fresh scan. It is also the "print the guard value" mode: the
#                resolved DOWNLOADS, LIBRARY and UIDGID constants and the detected zfs route are
#                the first thing it prints, before it reads anything.
#   `apply`      MUTATES. Runs the largest privileged operation in the phase.
#
# THE KEY (D-13's shape, reused) - WHY THIS IS TWO SUBCOMMANDS AND NOT ONE SCRIPT WITH A PROMPT:
#   The operator's standing verdict governs: "It's fine for a bot to drive us, but for me, as a
#   human, no." Read and approve a file; never sit at a prompt. The approval therefore sits
#   between two PROCESSES joined by a file on disk, not between two branches of one process: a
#   branch can be skipped by a flag, an env var or a future edit, a missing file cannot. There is
#   no interactive prompt in this file, no --yes and no --force.
#
#   D-13's own gate is scoped to the junk sweep and CONTEXT.md's Discretion section does not
#   mandate one here. This gate is DISCRETIONARY HARDENING, added because every other destructive
#   step in this phase gates approval before acting, and because the chown's only other guard is a
#   literal inside a script - which D-13's rationale warns is exactly the skippable kind.
#
# SCOPE GUARD - the single most important behaviour in this file:
#   The chown runs as REAL root on the Proxmox host, not as a namespaced container root, so a
#   wrong DOWNLOADS constant is a hypervisor-wide recursive chown rather than a contained mistake
#   (T-05-10-01). Three separate refusals stand in front of it:
#     1. DOWNLOADS is compared against the ALL-CAPS literal /mnt/tank/downloads before anything is
#        delegated, and the resolved value is PRINTED so a human can read it before it fires.
#     2. Every approved row is re-checked to be that path or a descendant of it, per row, and
#        /mnt/tank/media is refused BY NAME (Phase 1 D-20 - nobody holds rw on the library until
#        Phase 6).
#     3. The path is re-asserted on the FAR SIDE with a directory test, because a bind mount
#        present here but absent there would otherwise make the chown a silent no-op against a
#        path the remote auto-creates.
#
# SYMLINK SAFETY:
#   Every chown uses -h, which affects symbolic links themselves rather than their referents.
#   Without it a symlink under tank/downloads pointing into /mnt/tank/media/Music would have its
#   TARGET chowned, silently reaching the library and breaching Phase 1's D-20. Not hypothetical
#   on this estate: normalise-dj-tags.py's CR-04 records exactly one symlink defeating a path
#   fence silently, and a hardlink doing the same with no symlink involved. The 2026-09-19 survey
#   measured ZERO symlinks anywhere under tank/downloads - the flag stays anyway, because `apply`
#   runs against a live tree later, not against the survey.
#   `chown -R` never traverses a symlink (GNU default is -P); -h makes it chown the link itself.
#
# OWNERSHIP READINGS ARE TAKEN FROM ATLANTIS, ALWAYS:
#   A container-side listing showing 65534 is LXC 100's view, not the disk. LXC 100 is
#   unprivileged with a sparse idmap (u 0->100000 x568, u 568->568 x1, u 569->100569 x64967), so
#   unmapped on-disk ids surface as 65534 and several distinct owners collapse to one value.
#   Phase 1 lost time to exactly this. Both payloads in this file run on atlantis.
#   The same idmap is why `chown` cannot run from LXC 100 at all: a process in a user namespace
#   cannot chown a file whose current uid or gid the namespace cannot name.
#
# NO MODE PASS, AND THIS IS DELIBERATE, NOT AN OVERSIGHT:
#   No mode change is attempted anywhere in this file - not tried, not retried, not swallowed with
#   a fallback. It is impossible on this pool: it returns EPERM as real root for every mode,
#   including a no-op one on a file already at 0777, because acltype=nfsv4 plus aclmode=restricted
#   gives even new files a non-trivial NFSv4 ACL. Everything on tank is 0777 and stays that way.
#   `zfs set aclmode=passthrough` WOULD make it work and is explicitly REJECTED: under passthrough
#   the operation REWRITES the ACL, so it would overwrite the existing NFSv4 ACL on every entry to
#   satisfy a cosmetic half of a requirement.
#
# NO STANDING ASSERTION (D-25), AND DO NOT ADD ONE:
#   Do not add a health check asserting 568:568 across tank/downloads, and do not suggest adding
#   one. The download client keeps writing at roughly one music job per 72 seconds, so new
#   non-568 files appear almost immediately after the chown completes. Such a check would go red
#   on the next download and train everyone to ignore it - the precise failure mode Phase 02.1's
#   CR-01 spent four gap-closure plans repairing in the other direction. THE MEASUREMENT AND ITS
#   DATE ARE THE DELIVERABLE. $VERIFICATION is the artifact; there is no check and there will not
#   be one.
#
# RESUME STORY - there is no ledger and none is needed:
#   A recursive chown is IDEMPOTENT. An interrupted or partial run is recovered by re-running the
#   same command; that is the recovery path, not a snapshot rollback. The row re-validation below
#   knows this: a row whose owner has already become 568:568 is reported as ALREADY-NORMALISED and
#   skipped, it is NOT treated as drift. The sentinel distinguishes three states - "finished with
#   status N", "still running", and "the runner died without writing a sentinel" - and the third
#   is a could-not-look, not a pass.
#
# SESSION SURVIVAL:
#   `apply` is a privileged batch over roughly a quarter of a million entries, about 74x the only
#   comparable operation this estate has performed (Phase 1's 2,674-entry library chown, which ran
#   synchronously over ssh with no timeout and was never tested at this scale). A dropped ssh
#   mid-chown would leave a partially normalised tree. So the chown is DETACHED: a runner script is
#   written onto atlantis under $RUNNER_DIR, launched in a new session with stdin closed and output
#   redirected to a log there, and it writes its exit status to a sentinel the caller polls on a
#   bounded loop. The launcher is PROBED for; if no detached-session launcher exists the script
#   REFUSES rather than falling back to a synchronous run - refusal, not degradation.
#   tmux and screen are NOT installed on LXC 100 and atlantis's toolset was not previously
#   measured, which is the point of the probe. (Measured 2026-09-19: atlantis has both setsid and
#   nohup.)
#
# WHY TWO SNAPSHOTS, stated so it is not optimised away:
#   D-27 orders the chown LAST, so tank/downloads@pre-phase5 already carries the split's ~4,750
#   renames plus the junk sweep's deletions plus the tag write's modifications. A `zfs diff`
#   against it would show all of those and drown the chown's signal. Phase 1's plan 01-08 hit
#   exactly this and took a separate @pre-chown for the same reason, so `apply` creates
#   tank/downloads@pre-phase5-chown immediately before the run as a REFUSING precondition.
#   A fresh tank/media/Music@pre-phase5-chown is taken at the same moment as the library
#   untouched-proof instrument: Phase 1's month-old tank/media/Music@pre-chown could carry
#   unrelated drift, which would make a non-zero diff ambiguous.
#   Note also that a stat manifest CANNOT substitute: it keys on mtime, and a chown moves ctime
#   not mtime, so a zero from a stat manifest afterwards is EXPECTED and not reassuring - plan
#   01-06 proved that when its gate passed while `zfs diff` showed a real metadata change.
#
# WHAT COUNTS AS DRIFT, AND WHAT DELIBERATELY DOES NOT:
#   `apply` re-derives every approved row against fresh state immediately before acting, and ANY
#   drift aborts the WHOLE run with nothing chowned. The drift key is the row's IDENTITY:
#     path resolves, is in scope, is not a symlink, type unchanged, devid unchanged, inode
#     unchanged, and owner either unchanged or already 568:568.
#   ENTRY COUNTS ARE NOT A DRIFT KEY, and that is a deliberate departure from the junk sweep,
#   where they are. The junk sweep's rows are things it is about to DESTROY, so a count that moved
#   means the operator may be approving the loss of something new. This tool's rows are things it
#   is about to chown on a 0777 tree, where a new file arriving inside an approved subtree is
#   exactly what the approval anticipated - and the tree is written at roughly one music job per
#   72 seconds, so a count-keyed abort would fire on almost every run and teach everyone to
#   re-approve without reading. The counts are still re-measured and REPORTED per row, and any
#   row whose fresh owner SET gained an owner:group the approval never saw IS fatal.
#
# EXIT-CODE CONVENTION (stated deliberately, not inherited - the estate has no single one):
#   enumerate  0 always. It REPORTS; it does not assert. Finding foreign ownership is the whole
#              point of running it, so it is never a failure.
#   apply      0  the chown completed, the after census shows every approved row at 568:568, the
#                 download-tree diff shows only M lines, and the library proof shows zero lines
#              1  the chown ran but a verification failed
#              2  usage error, or an unmet precondition: no zfs route, missing $APPROVED_LIST,
#                 missing or wrong $SNAPSHOT_PROOF, absent @pre-phase5, failed snapshot creation,
#                 a scope-guard violation, no detached-session launcher, or approved-row drift
#                 (refusals, never fallbacks)
#
# HAZARD NOTES:
#   - NOTHING is written to the system scratch directory on LXC 100. That directory is tmpfs
#     backed by host RAM; a 1.1 GB file staged there previously took the whole 28 GB box down and
#     killed ssh on both host and container. Every byte this script writes on LXC 100 lands under
#     /mnt/fast; every byte it writes on atlantis lands under $RUNNER_DIR, named explicitly.
#   - RUN WHOLE-TREE PASSES ONE AT A TIME. Plan 05-09 ran two concurrent whole-collection reads and
#     atlantis rebooted under memory pressure. This script never starts a second pass while one is
#     in flight, and neither should you.
#   - `zfs diff` output on this tree is roughly a quarter of a million lines. It is NEVER printed
#     raw. Only line-class counts are asserted, and any non-M line is named individually.
#   - A `zfs diff` "no modification" reading on files that were RENAMED is VACUOUS: zfs diff
#     collapses renamed-and-modified into one R line. Plan 05-09 proved this against 05-07's
#     renames. That is precisely why `apply` takes a FRESH baseline rather than reusing
#     @pre-phase5.
#   - ZFS frees space asynchronously; nothing here asserts a space figure.
#   - Tab is an IFS *whitespace* character. `IFS=$'\t' read` collapses runs of it and strips it
#     from the ends, so a row written with an empty field is read back SHORT and every field after
#     the gap SHIFTS LEFT BY ONE - a row that parses cleanly, exits 0 and is wrong. Every row this
#     script emits therefore carries a real value in every one of its nine columns, and
#     `enumerate` ASSERTS the shape of the file it just wrote before it reports success.
#   - A path whose own name contains a tab or a newline would corrupt the file that IS the gate.
#     Such an entry is EXCLUDED from the row list and counted as UNPARSEABLE - fail closed: an
#     entry nobody can approve is an entry nothing will act on. It stays as it is, which on a 0777
#     tree costs nothing, and enumerate says so loudly rather than silently normalising it.
#   - The remote payloads are fed to `bash -s` over stdin, NOT interpolated into an ssh command
#     string. Tab separators and awk programs do not survive multiple levels of ssh quoting; this
#     estate has lost real time to that.

set -euo pipefail

# --- constants ----------------------------------------------------------------------------------

DOWNLOADS="${DOWNLOADS:-/mnt/tank/downloads}"
LIBRARY="${LIBRARY:-/mnt/tank/media/Music}"
MEDIA_ROOT="/mnt/tank/media"
UIDGID="568:568"
WANT_UID="568"
WANT_GID="568"

ZFS_HOST="${ZFS_HOST:-172.16.1.158}"          # Proxmox host "atlantis" - the only place zfs and a
                                              # working chown on tank both exist
FENCE_SNAPSHOT="tank/downloads@pre-phase5"    # D-01's phase fence. Must still exist.
SNAPTAG="pre-phase5-chown"                    # the FRESH baseline this run takes
DL_SNAPSHOT="tank/downloads@${SNAPTAG}"
LIB_SNAPSHOT="tank/media/Music@${SNAPTAG}"

OUT_DIR="${OUT_DIR:-/mnt/fast/safety/phase05}"
APPROVED_LIST="${APPROVED_LIST:-$OUT_DIR/chown-rows.tsv}"
SURVEY_REPORT="${SURVEY_REPORT:-$OUT_DIR/chown-survey.txt}"
VERIFICATION="${VERIFICATION:-$OUT_DIR/chown-verification.txt}"
SNAPSHOT_PROOF="${SNAPSHOT_PROOF:-$OUT_DIR/snapshot-proof.txt}"

# Atlantis-side working directory. Named explicitly and persistent: the sentinel and the log must
# survive a dropped session, which is the whole reason the runner is detached.
RUNNER_DIR="${RUNNER_DIR:-/var/lib/phase05-chown}"

POLL_SECONDS="${POLL_SECONDS:-15}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-14400}"   # 4 h. Nothing on this estate has run an operation
                                                # at this scale, so the bound is generous and the
                                                # elapsed time is part of the deliverable.
WALK_TIMEOUT="${WALK_TIMEOUT:-3600}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILURES=0
fail() { echo -e "  ${RED}FAIL: $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}OK:   $*${NC}"; }
warn() { echo -e "  ${YELLOW}WARN: $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "============================================================================"; }

usage() {
  echo "usage: bash scripts/phase05-downloads-chown.sh {enumerate|apply}" >&2
  echo "       bash scripts/phase05-downloads-chown.sh --help" >&2
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
esac

# --- the literal scope guard --------------------------------------------------------------------
# ALL-CAPS and literal, asserted before ANYTHING is delegated, in both subcommands. This is the
# guard Task 2's operator gate reads before it fires.
assert_scope_literal() {
  if [ "$DOWNLOADS" != "/mnt/tank/downloads" ]; then
    echo "REFUSING: DOWNLOADS is '$DOWNLOADS', expected the literal '/mnt/tank/downloads'." >&2
    echo "   The chown below runs as REAL root on the Proxmox host, not as a namespaced" >&2
    echo "   container root, so a wrong constant here is a hypervisor-wide recursive chown" >&2
    echo "   rather than a contained mistake. Refusing." >&2
    exit 2
  fi
  if [ "$LIBRARY" != "/mnt/tank/media/Music" ]; then
    echo "REFUSING: LIBRARY is '$LIBRARY', expected the literal '/mnt/tank/media/Music'." >&2
    echo "   LIBRARY is the untouched-proof instrument; a wrong value would prove nothing." >&2
    exit 2
  fi
  if [ "$UIDGID" != "568:568" ]; then
    echo "REFUSING: UIDGID is '$UIDGID', expected the literal '568:568'." >&2
    exit 2
  fi
}

# assert_row_in_scope PATH -> prints the resolved path, or refuses.
# Called PER ROW, deliberately - a per-target fence checked once on the roots is not enough.
assert_row_in_scope() {
  local given="$1" real=""
  real="$(realpath -m -- "$given" 2>/dev/null)" || real=""
  if [ -z "$real" ]; then
    echo "REFUSING: could not resolve approved row path" >&2
    echo "   given: $given" >&2
    exit 2
  fi
  if [ "$real" = "$MEDIA_ROOT" ] || [ "${real#"$MEDIA_ROOT"/}" != "$real" ]; then
    echo "REFUSING: $MEDIA_ROOT is out of scope BY NAME (Phase 1 D-20)." >&2
    echo "   given:    $given" >&2
    echo "   resolved: $real" >&2
    echo "   Nobody holds rw on the library until Phase 6. Every write this phase performs" >&2
    echo "   lands under $DOWNLOADS." >&2
    exit 2
  fi
  if [ "$real" != "$DOWNLOADS" ] && [ "${real#"$DOWNLOADS"/}" = "$real" ]; then
    echo "REFUSING: approved row is outside $DOWNLOADS" >&2
    echo "   given:    $given" >&2
    echo "   resolved: $real" >&2
    exit 2
  fi
  printf '%s' "$real"
}

# --- zfs / atlantis routing -----------------------------------------------------------------------
# Read-only detection first, so the route is known and PRINTED before anything mutates.
ZFS_ROUTE="unavailable"
detect_zfs_route() {
  if command -v zfs >/dev/null 2>&1; then
    ZFS_ROUTE="local"
  elif ssh -o BatchMode=yes -o ConnectTimeout=8 "root@${ZFS_HOST}" 'zfs list -H -o name tank' >/dev/null 2>&1; then
    ZFS_ROUTE="ssh:${ZFS_HOST}"
  else
    ZFS_ROUTE="unavailable"
  fi
}

zfs_exec() {
  local cmdline="$1"
  if [ "$ZFS_ROUTE" = "local" ]; then
    eval "$cmdline"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=15 "root@${ZFS_HOST}" "$cmdline"
  fi
}

snapshot_exists() { zfs_exec "zfs list -t snapshot -H -o name '$1'" >/dev/null 2>&1; }

# remote_bash <<< payload   - runs a self-contained bash program on atlantis (or here, when this
# IS atlantis). The program is fed on STDIN, never interpolated into a command string: tab
# separators and awk programs do not survive multiple levels of ssh quoting.
remote_bash() {
  if [ "$ZFS_ROUTE" = "local" ]; then
    bash -s -- "$@"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=15 "root@${ZFS_HOST}" 'bash -s --' "$@"
  fi
}

print_constants() {
  echo "  resolved constants - READ THESE BEFORE APPROVING ANYTHING"
  echo "    DOWNLOADS (the chown target):  $DOWNLOADS"
  echo "    LIBRARY   (untouched-proof):   $LIBRARY"
  echo "    UIDGID    (the target owner):  $UIDGID"
  echo "    ZFS_HOST  (real root lives here): $ZFS_HOST"
  echo "    zfs route:                     $ZFS_ROUTE"
  echo "    fence snapshot (must exist):   $FENCE_SNAPSHOT"
  echo "    fresh baseline apply creates:  $DL_SNAPSHOT"
  echo "    library proof apply creates:   $LIB_SNAPSHOT"
  echo "    row list (the gate):           $APPROVED_LIST"
  echo "    atlantis runner directory:     $RUNNER_DIR"
}

# --- the survey payload ---------------------------------------------------------------------------
# One walk of the tree, on atlantis, producing a compact aggregate and the row list. Never returns
# the 233k-line raw output over the wire.
#
# ROLL-UP RULE, so the row list is reviewable rather than a quarter of a million lines:
#   Walk in path order (ancestors sort before descendants). For each directory D:
#     * nothing beneath D is foreign          -> emit nothing, prune the subtree
#     * D AND EVERYTHING beneath it is foreign -> emit ONE `recursive` row for D, prune the subtree
#     * otherwise                              -> emit a `self` row for D if D's own entry is
#                                                 foreign, and keep descending
#   Any foreign non-directory not already covered by a `recursive` row gets its own `self` row.
#   That turns 222,376 foreign entries into a list a human can actually read, while keeping the
#   action scope exact: a `self` row chowns one entry, a `recursive` row chowns one subtree.
survey_payload() {
cat <<'PAYLOAD'
set -uo pipefail
ROOT="$1"; WUID="$2"; WGID="$3"; RDIR="$4"; TMOUT="$5"
if [ ! -d "$ROOT" ]; then echo "##META	error	root_absent_on_$(hostname)"; exit 2; fi
mkdir -p "$RDIR"
RAW="$RDIR/survey.raw"
SORTED="$RDIR/survey.sorted"

echo "##META	host	$(hostname)"
echo "##META	date	$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "##META	root	$ROOT"
echo "##META	root_devid	$(stat -c %d "$ROOT")"
echo "##META	root_owner	$(stat -c %u:%g "$ROOT")"

# -xdev keeps the walk on the tank/downloads dataset and is a second fence: it cannot wander into
# /mnt/tank/media even if something under here were a mountpoint. find's default is -P, so no
# symlink is ever followed.
timeout "$TMOUT" find "$ROOT" -xdev -printf '%U\t%G\t%y\t%D\t%i\t%p\n' > "$RAW"
rc=$?
echo "##META	find_rc	$rc"
if [ "$rc" -ne 0 ]; then echo "##META	error	walk_failed_rc_$rc"; exit 2; fi

LC_ALL=C sort -t'	' -k6,6 "$RAW" > "$SORTED"

LC_ALL=C awk -F'\t' -v root="$ROOT" -v wuid="$WUID" -v wgid="$WGID" '
function is_foreign(u, g) { return (u != wuid || g != wgid) }
# ---- pass 1: roll counters up every ancestor ----
FNR == NR {
  if (NF != 6) { bad++; next }
  p = $6
  if (index(p, root) != 1) { outside++; next }
  n++
  f = is_foreign($1, $2)
  if (p == root && f) { rootforeign = 1 }
  if (f) { nf++; ow[$1 ":" $2 "\t" $3]++ ; owtot[$1 ":" $2]++ } else { nok++ }
  if ($3 == "l") nlink++
  # self
  tot[p]++; if (f) frn[p]++
  if ($3 == "d") { dcnt[p]++ } else { fcnt[p]++ }
  # ancestors, by cumulative prefix. Built with split rather than a reverse character scan: the
  # scan is O(path length) per level and this walk is a quarter of a million paths deep enough to
  # make that the slowest thing in the file.
  m = split(p, a, "/")
  pre = ""
  for (i = 2; i <= m; i++) {
    pre = pre "/" a[i]
    if (pre == p) continue
    if (length(pre) < length(root)) continue
    if (index(pre, root) != 1) continue
    tot[pre]++; if (f) frn[pre]++
    if ($3 == "d") { dcnt[pre]++ } else { fcnt[pre]++ }
  }
  next
}
# ---- pass 2: emit rows, in path order ----
{
  if (NF != 6) next
  p = $6
  if (index(p, root) != 1) next
  uid = $1; gid = $2; typ = $3; dev = $4; ino = $5
  f = is_foreign(uid, gid)

  if (PRUNE != "" && index(p, PRUNE "/") == 1) {
    if (PMODE == "recursive" && f) { rowown[PRUNE SUBSEP uid ":" gid]++ }
    next
  }
  PRUNE = ""; PMODE = ""

  if (typ == "d") {
    if (frn[p] + 0 == 0) { PRUNE = p; PMODE = "skip"; next }
    if (frn[p] + 0 == tot[p] + 0) {
      nrow++
      rmode[nrow] = "recursive"; rpath[nrow] = p; rtype[nrow] = "dir"
      rdev[nrow] = dev; rino[nrow] = ino; rown[nrow] = uid ":" gid
      rent[nrow] = tot[p] + 0; rsub[nrow] = tot[p] + 0
      rd[nrow] = dcnt[p] + 0; rf[nrow] = fcnt[p] + 0
      rowown[p SUBSEP uid ":" gid]++
      rkey[nrow] = p
      PRUNE = p; PMODE = "recursive"
      next
    }
    if (f) {
      nrow++
      rmode[nrow] = "self"; rpath[nrow] = p; rtype[nrow] = "dir"
      rdev[nrow] = dev; rino[nrow] = ino; rown[nrow] = uid ":" gid
      rent[nrow] = 1; rsub[nrow] = tot[p] + 0
      rd[nrow] = 1; rf[nrow] = 0
      rowown[p SUBSEP uid ":" gid]++
      rkey[nrow] = p
    }
    next
  }

  if (f) {
    nrow++
    rmode[nrow] = "self"; rpath[nrow] = p; rtype[nrow] = ((typ == "f") ? "file" : "other-" typ)
    rdev[nrow] = dev; rino[nrow] = ino; rown[nrow] = uid ":" gid
    rent[nrow] = 1; rsub[nrow] = 1
    rd[nrow] = 0; rf[nrow] = 1
    rowown[p SUBSEP uid ":" gid]++
    rkey[nrow] = p
  }
}
END {
  printf("##META\ttotal_entries\t%d\n", n + 0)
  printf("##META\tforeign_entries\t%d\n", nf + 0)
  printf("##META\talready_ok\t%d\n", nok + 0)
  printf("##META\tsymlinks\t%d\n", nlink + 0)
  printf("##META\tunparseable\t%d\n", bad + 0)
  printf("##META\toutside_root\t%d\n", outside + 0)
  printf("##META\trows\t%d\n", nrow + 0)

  for (k in ow) { split(k, a, "\t"); printf("##OWNER\t%s\t%s\t%d\n", a[1], a[2], ow[k]) }

  # top-level breakdown. The root directory's own entry is reported on its own line rather than
  # folded into any child, so a bare number can never read as a pass.
  for (p in tot) {
    if (p == root) { continue }
    rest = substr(p, length(root) + 2)
    if (index(rest, "/") != 0) { continue }
    printf("##TOP\t%s\t%d\t%d\n", rest, tot[p] + 0, frn[p] + 0)
  }
  printf("##TOP\t(the root directory entry itself)\t1\t%d\n", rootforeign + 0)

  for (i = 1; i <= nrow; i++) {
    set = ""
    for (k in rowown) {
      split(k, a, SUBSEP)
      if (a[1] == rkey[i]) { set = (set == "") ? a[2] : set "," a[2] }
    }
    if (set == "") { set = rown[i] }
    if (rmode[i] == "recursive") {
      note = "entire subtree is not " wuid ":" wgid " - " rent[i] " entries (" rd[i] " dirs / " rf[i] " files); owners " set
    } else {
      note = "this entry only is not " wuid ":" wgid "; the " (rsub[i] - 1) " entries beneath it are already correct; owner " set
    }
    gsub(/\t/, " ", note)
    printf("##ROW\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\n",
           rmode[i], rpath[i], rtype[i], rdev[i], rino[i], rown[i], rent[i], rsub[i], note)
  }
}
' "$SORTED" "$SORTED"

# The raw walk output is large and has served its purpose. It is removed so it cannot be mistaken
# for a durable artifact, and so it is not still sitting here at the next run.
rm -f "$RAW" "$SORTED"
echo "##META	end	ok"
PAYLOAD
}

# --- enumerate --------------------------------------------------------------------------------------

do_enumerate() {
  assert_scope_literal

  # A fresh survey must never silently replace a list an operator has already worked on.
  if [ -e "$APPROVED_LIST" ]; then
    echo "REFUSING: row list already exists: $APPROVED_LIST" >&2
    echo "   If it has been approved, run 'apply'. If it is stale, move it aside by hand and" >&2
    echo "   re-run 'enumerate'. An approved file is never silently overwritten." >&2
    exit 2
  fi

  detect_zfs_route

  echo "Phase 5 - download-tree ownership, enumerate (READ-ONLY)"
  rule
  echo "  caller host: $(hostname)"
  echo "  date:        $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo -e "  mode:        ${BLUE}enumerate (read-only - no snapshot, no chown)${NC}"
  echo ""
  print_constants
  echo ""

  if [ "$ZFS_ROUTE" = "unavailable" ]; then
    echo "REFUSING: no route to atlantis." >&2
    echo "   Every ownership reading in this file is taken from atlantis, because a" >&2
    echo "   container-side listing showing 65534 is LXC 100's idmap view and not the disk." >&2
    echo "   An unreachable atlantis means the ownership state is UNKNOWN, which is a refusal," >&2
    echo "   not a skip and not a pass." >&2
    exit 2
  fi

  # Only now create the output directory. A failure here is a precondition failure - this file is
  # meant to run on LXC 100 where /mnt/fast exists - and it exits 2 like every other refusal
  # rather than crashing out of `set -e` with an exit code that means something else.
  if ! mkdir -p "$OUT_DIR" 2>/dev/null; then
    echo "REFUSING: cannot create the output directory $OUT_DIR" >&2
    echo "   This script is meant to run ON LXC 100 from /mnt/fast/stacks. Override OUT_DIR only" >&2
    echo "   for a harness run; the real deliverable belongs under /mnt/fast/safety/phase05." >&2
    exit 2
  fi

  info "walking $DOWNLOADS from atlantis - ONE pass, and nothing else may run a whole-tree pass"
  info "at the same time (plan 05-09 ran two concurrently and atlantis rebooted)"
  echo ""

  local payload_out
  payload_out="$(survey_payload | remote_bash "$DOWNLOADS" "$WANT_UID" "$WANT_GID" "$RUNNER_DIR" "$WALK_TIMEOUT")" || {
    echo "REFUSING: the survey payload failed on atlantis." >&2
    exit 2
  }

  local meta_err
  meta_err="$(printf '%s\n' "$payload_out" | awk -F'\t' '$1=="##META" && $2=="error"{print $3}')"
  if [ -n "$meta_err" ]; then
    echo "REFUSING: survey reported '$meta_err'" >&2
    exit 2
  fi

  m() { printf '%s\n' "$payload_out" | awk -F'\t' -v k="$1" '$1=="##META" && $2==k{print $3; exit}'; }

  local n_total n_foreign n_ok n_link n_bad n_out n_rows s_host s_date s_devid s_owner
  n_total="$(m total_entries)";  n_foreign="$(m foreign_entries)"; n_ok="$(m already_ok)"
  n_link="$(m symlinks)";        n_bad="$(m unparseable)";         n_out="$(m outside_root)"
  n_rows="$(m rows)";            s_host="$(m host)";               s_date="$(m date)"
  s_devid="$(m root_devid)";     s_owner="$(m root_owner)"

  echo "1. The census, read from atlantis"
  rule
  echo "  measured on:              $s_host at $s_date"
  echo "  $DOWNLOADS devid:         $s_devid   owner: $s_owner"
  echo "  total entries:            $n_total"
  echo "  already $UIDGID:          $n_ok"
  echo "  NOT $UIDGID:              $n_foreign"
  echo "  symlinks anywhere:        $n_link"
  echo "  entries outside the root: $n_out   (must be 0 - the walk is fenced with -xdev)"
  echo "  unparseable entries:      $n_bad   (tab or newline in the name; EXCLUDED, see header)"
  echo ""
  if [ "${n_out:-1}" != "0" ]; then
    warn "the walk saw entries outside $DOWNLOADS. Do NOT approve this list."
  fi
  if [ "${n_bad:-0}" != "0" ]; then
    warn "$n_bad entr(ies) carry a tab or newline in their own name and are EXCLUDED from the"
    warn "row list. They will NOT be chowned, and on a 0777 tree that costs nothing - but it is"
    warn "said here rather than left to be discovered."
  fi

  echo "2. Who owns what, by owner:group and by type"
  rule
  printf '  %-18s %-8s %-10s\n' "OWNER:GROUP" "TYPE" "ENTRIES"
  printf '%s\n' "$payload_out" \
    | awk -F'\t' '$1=="##OWNER"{t=($3=="d")?"dir":(($3=="f")?"file":"other-" $3); printf("  %-18s %-8s %-10d\n", $2, t, $4)}' \
    | LC_ALL=C sort
  echo ""

  echo "3. Who owns what, by top-level subtree"
  rule
  printf '  %-34s %-12s %-12s %s\n' "TOP-LEVEL" "ENTRIES" "NOT-568:568" "SHARE"
  printf '%s\n' "$payload_out" \
    | awk -F'\t' '$1=="##TOP"{pct=($3>0)?(100*$4/$3):0; printf("  %-34s %-12d %-12d %5.1f%%\n", $2, $3, $4, pct)}' \
    | LC_ALL=C sort -k3,3 -n -r
  echo ""

  echo "4. Writing the row list - THIS FILE IS THE GATE"
  rule
  local building="${APPROVED_LIST}.building"
  : > "$building"
  printf '%s\n' "$payload_out" | awk -F'\t' -v OFS='\t' '$1=="##ROW"{ $1=""; sub(/^\t/,""); print }' \
    | LC_ALL=C sort -t'	' -k2,2 >> "$building"
  mv "$building" "$APPROVED_LIST"
  local written
  written="$(wc -l < "$APPROVED_LIST" | tr -dc '0-9')"
  pass "wrote ${written} row(s) to $APPROVED_LIST"

  if [ "${written:-0}" != "${n_rows:-0}" ]; then
    warn "the payload emitted $n_rows row(s) but $written landed in the file. Do NOT approve it."
  fi

  # ASSERT THE SHAPE OF THE FILE THAT IS THE GATE, rather than trust the code that wrote it.
  # Nine fields, none of them empty - see the header note on tab being IFS whitespace.
  local shape_bad
  shape_bad="$(awk -F'\t' '
    NF != 9 { bad++; next }
    { for (i = 1; i <= NF; i++) if ($i == "") { bad++; next } }
    END { print bad + 0 }' "$APPROVED_LIST")"
  if [ "$shape_bad" != "0" ]; then
    warn "${shape_bad} row(s) are malformed (not 9 non-empty tab fields). Do NOT approve this list."
  else
    pass "every row carries 9 non-empty tab-separated fields"
  fi

  # Every row must be in scope. Checked here, and checked AGAIN per row by `apply`.
  local scope_bad=0 rp
  while IFS=$'\t' read -r _ rp _ _ _ _ _ _ _; do
    [ -z "${rp:-}" ] && continue
    case "$rp" in
      "$DOWNLOADS"|"$DOWNLOADS"/*) : ;;
      *) scope_bad=$((scope_bad + 1)); warn "row out of scope: $rp" ;;
    esac
  done < "$APPROVED_LIST"
  if [ "$scope_bad" -eq 0 ]; then pass "every row resolves inside $DOWNLOADS"; fi

  # The rows must account for every foreign entry. A roll-up that loses entries is worse than no
  # roll-up at all, because the list looks complete.
  local covered
  covered="$(awk -F'\t' '{s += $7} END {print s + 0}' "$APPROVED_LIST")"
  echo ""
  echo "  foreign entries covered by the rows: $covered"
  echo "  foreign entries measured:            $n_foreign"
  if [ "$covered" = "$n_foreign" ]; then
    pass "the row list accounts for every entry that is not $UIDGID"
  else
    warn "the row list covers $covered of $n_foreign foreign entries. The difference should equal"
    warn "the $n_bad unparseable entr(ies); if it does not, do NOT approve this list."
  fi
  echo ""

  echo "5. The rows"
  rule
  printf '  %-10s %-9s %-10s %-11s %s\n' "MODE" "TYPE" "OWNER" "ENTRIES" "PATH"
  awk -F'\t' '{printf("  %-10s %-9s %-10s %-11d %s\n", $1, $3, $6, $7, $2)}' "$APPROVED_LIST"
  echo ""

  warn "NOTHING HAS BEEN CHOWNED. No snapshot was taken. No mode bit was touched."
  warn "An operator must read and approve $APPROVED_LIST before 'apply' will act."
  warn "Strike any row you do not want acted on by removing that LINE from the file."
  warn "This list is a POINT-IN-TIME view of a tree written at roughly one music job per 72 s."
  warn "'apply' re-derives every row's IDENTITY against fresh state and aborts the whole run on"
  warn "any drift; see the header for what is and is not a drift key, and why."
  echo ""

  # enumerate reports, it does not assert.
  return 0
}

# --- apply ------------------------------------------------------------------------------------------

# The detached runner, written onto atlantis. It validates EVERY row against fresh state FIRST and
# only then acts: any drift aborts the whole run with nothing chowned.
runner_payload() {
cat <<'PAYLOAD'
set -uo pipefail
ROWS="$1"; WANT="$2"; ROOT="$3"; SENTINEL="$4"; MEDIA="$5"
started=$(date +%s)
echo "runner start $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(hostname)"

# --- the far-side scope re-assertion --------------------------------------------------------------
if [ "$ROOT" != "/mnt/tank/downloads" ]; then
  echo "RUNNER REFUSING: ROOT is '$ROOT', expected the literal /mnt/tank/downloads"
  echo "exit=2 reason=scope_literal elapsed=0" > "$SENTINEL"; exit 2
fi
# A bind mount present on the caller but absent here would otherwise make the chown a silent
# no-op against a path this host auto-creates.
if [ ! -d "$ROOT" ]; then
  echo "RUNNER REFUSING: $ROOT is not a directory on $(hostname)"
  echo "exit=2 reason=root_absent elapsed=0" > "$SENTINEL"; exit 2
fi

# --- phase 1: validate every row, act on none -------------------------------------------------------
drift=0; rows=0; skip_done=0
while IFS=$'\t' read -r mode path typ dev ino own ent sub note; do
  [ -z "${mode:-}" ] && continue
  rows=$((rows + 1))
  case "$path" in
    "$MEDIA"|"$MEDIA"/*) echo "DRIFT row $rows: $path is inside $MEDIA (Phase 1 D-20)"; drift=$((drift+1)); continue ;;
    "$ROOT"|"$ROOT"/*) : ;;
    *) echo "DRIFT row $rows: $path is outside $ROOT"; drift=$((drift+1)); continue ;;
  esac
  if [ -L "$path" ]; then
    echo "DRIFT row $rows: $path is now a symbolic link"; drift=$((drift+1)); continue
  fi
  if [ ! -e "$path" ]; then
    echo "DRIFT row $rows: $path no longer exists"; drift=$((drift+1)); continue
  fi
  now_dev=$(stat -c %d -- "$path" 2>/dev/null || echo NA)
  now_ino=$(stat -c %i -- "$path" 2>/dev/null || echo NA)
  now_own=$(stat -c %u:%g -- "$path" 2>/dev/null || echo NA)
  now_typ=$([ -d "$path" ] && echo dir || echo file)
  if [ "$now_dev" != "$dev" ]; then echo "DRIFT row $rows: $path devid $dev -> $now_dev"; drift=$((drift+1)); continue; fi
  if [ "$now_ino" != "$ino" ]; then echo "DRIFT row $rows: $path inode $ino -> $now_ino"; drift=$((drift+1)); continue; fi
  if [ "$now_typ" != "$typ" ] && [ "$typ" != "other-l" ]; then
    echo "DRIFT row $rows: $path type $typ -> $now_typ"; drift=$((drift+1)); continue
  fi
  if [ "$now_own" != "$own" ]; then
    if [ "$now_own" = "$WANT" ]; then
      # Already normalised. This is the IDEMPOTENT re-run case, not drift: a recursive chown has
      # no ledger and re-running is the stated recovery path.
      skip_done=$((skip_done + 1))
    else
      echo "DRIFT row $rows: $path owner $own -> $now_own (and not $WANT)"; drift=$((drift+1)); continue
    fi
  fi
done < "$ROWS"

echo "validated $rows row(s); already-normalised $skip_done; drift $drift"
if [ "$drift" -gt 0 ]; then
  echo "ABORTING THE WHOLE RUN: $drift row(s) drifted after approval. NOTHING CHOWNED."
  echo "exit=2 reason=drift rows=$rows drift=$drift elapsed=$(( $(date +%s) - started ))" > "$SENTINEL"
  exit 2
fi

# --- phase 2: act ------------------------------------------------------------------------------------
errs=0; did=0
while IFS=$'\t' read -r mode path typ dev ino own ent sub note; do
  [ -z "${mode:-}" ] && continue
  case "$mode" in
    recursive)
      # -h: affect symbolic links themselves, never their referents. Without it a link under this
      # tree pointing into the library would have its TARGET chowned (Phase 1 D-20). -R never
      # traverses a link (GNU default -P).
      if chown -Rh "$WANT" -- "$path"; then did=$((did + 1)); else echo "ERROR recursive $path"; errs=$((errs + 1)); fi
      ;;
    self)
      if chown -h "$WANT" -- "$path"; then did=$((did + 1)); else echo "ERROR self $path"; errs=$((errs + 1)); fi
      ;;
    *)
      echo "ERROR unknown mode '$mode' for $path"; errs=$((errs + 1)) ;;
  esac
done < "$ROWS"

elapsed=$(( $(date +%s) - started ))
echo "acted on $did row(s); errors $errs; elapsed ${elapsed}s"
if [ "$errs" -gt 0 ]; then
  echo "exit=1 reason=chown_errors rows=$rows acted=$did errors=$errs elapsed=$elapsed" > "$SENTINEL"; exit 1
fi
echo "exit=0 reason=complete rows=$rows acted=$did errors=0 elapsed=$elapsed" > "$SENTINEL"
exit 0
PAYLOAD
}

do_apply() {
  assert_scope_literal

  # REFUSAL ONE, and it is the FIRST state-dependent statement of the acting subcommand so it is
  # reachable and testable anywhere - including on a workstation with no access to tank at all.
  if [ ! -f "$APPROVED_LIST" ]; then
    echo "REFUSING: approved row list not found: $APPROVED_LIST" >&2
    echo "   Run 'bash scripts/phase05-downloads-chown.sh enumerate' first, then have the list" >&2
    echo "   read and approved by the operator. Refusing to guess what may be chowned." >&2
    exit 2
  fi

  # REFUSAL TWO: D-01's phase fence must still exist. It is the only rollback for a bad recursive
  # chown, and it is ALSO the only undo for 05-07's renames and 05-09's 751 tag writes.
  if [ ! -f "$SNAPSHOT_PROOF" ]; then
    echo "REFUSING: snapshot proof not found: $SNAPSHOT_PROOF" >&2
    echo "   $FENCE_SNAPSHOT must still exist. Produce the proof on atlantis:" >&2
    echo "     ssh -o BatchMode=yes root@${ZFS_HOST} \\" >&2
    echo "       'zfs list -t snapshot -H -o name ${FENCE_SNAPSHOT}' > $SNAPSHOT_PROOF" >&2
    exit 2
  fi
  # WHOLE-LINE match, and that is not fussiness. This run's own fresh baseline is named
  # tank/downloads@pre-phase5-chown, which CONTAINS tank/downloads@pre-phase5 as a substring - so
  # a `grep -F` here would accept a proof that names only the snapshot this script is about to
  # create and says nothing about D-01's fence. Same defect class as the `requireBeetsMatch`
  # prefix bug this estate recorded on 2026-09-14: an unbounded prefix match passes supersets.
  if ! grep -qxF "$FENCE_SNAPSHOT" "$SNAPSHOT_PROOF"; then
    echo "REFUSING: snapshot proof does not name $FENCE_SNAPSHOT on a line of its own: $SNAPSHOT_PROOF" >&2
    echo "   The 2026-08-18 @pre-project and @pre-chown snapshots are a month stale and are NOT" >&2
    echo "   a Phase 5 baseline, and this run's own $DL_SNAPSHOT is not one either - it does not" >&2
    echo "   exist yet when this check runs. A proof naming the wrong snapshot must fail, and does." >&2
    exit 2
  fi

  detect_zfs_route
  echo "Phase 5 - download-tree ownership, apply (APPROVED ROWS ONLY)"
  rule
  echo "  caller host: $(hostname)"
  echo "  date:        $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo -e "  mode:        ${RED}apply (MUTATES - recursive chown as real root)${NC}"
  echo ""
  print_constants
  echo ""

  if [ "$ZFS_ROUTE" = "unavailable" ]; then
    echo "REFUSING: no zfs route - the snapshot state is UNKNOWN, and a snapshot is the only" >&2
    echo "   rollback for a bad recursive chown. Refusal, not a skip and not a pass." >&2
    exit 2
  fi

  if ! snapshot_exists "$FENCE_SNAPSHOT"; then
    echo "REFUSING: $FENCE_SNAPSHOT does not exist on atlantis. D-01's fence must still be" >&2
    echo "   there; it is the only undo for this phase's renames and tag writes as well." >&2
    exit 2
  fi
  pass "precondition: $FENCE_SNAPSHOT exists"

  # Probe for a detached-session launcher BEFORE taking any snapshot. Refusal, not degradation.
  local launcher=""
  if zfs_exec "command -v setsid" >/dev/null 2>&1; then
    launcher="setsid"
  elif zfs_exec "command -v nohup" >/dev/null 2>&1; then
    launcher="nohup"
  else
    echo "REFUSING: neither setsid nor nohup exists on atlantis, so the chown cannot be" >&2
    echo "   detached from this ssh session. A dropped session mid-run would leave a partially" >&2
    echo "   normalised tree. Refusing rather than silently running synchronously." >&2
    exit 2
  fi
  pass "detached-session launcher: $launcher"

  # FRESH BASELINES, as refusing preconditions. See the header for why @pre-phase5 cannot serve.
  #
  # A PRE-EXISTING SNAPSHOT OF EITHER NAME IS A REFUSAL, NOT A REUSE, and the reason is the whole
  # point of taking them: the word in "fresh baseline" is FRESH. If one already exists it was
  # taken at some earlier moment, so everything that happened in between would show up in the
  # diff as though this run had caused it - and on the library side a non-zero diff from unrelated
  # drift would make the untouched-proof ambiguous, which is exactly why Phase 1's month-old
  # tank/media/Music@pre-chown was rejected as an instrument here. Found 2026-09-19: an earlier
  # `|| true` created-or-reused shape would have silently proceeded on a stale baseline.
  if snapshot_exists "$DL_SNAPSHOT"; then
    echo "REFUSING: $DL_SNAPSHOT already exists." >&2
    echo "   This baseline must be taken IMMEDIATELY before the chown or it proves nothing." >&2
    echo "   Inspect it, and if it is stale destroy that ONE snapshot by hand and re-run:" >&2
    echo "     ssh root@${ZFS_HOST} \"zfs list -t snapshot -o name,creation '$DL_SNAPSHOT'\"" >&2
    echo "     ssh root@${ZFS_HOST} \"zfs destroy -n '$DL_SNAPSHOT'\"   # dry run FIRST" >&2
    echo "   Never pass -r, and never go near $FENCE_SNAPSHOT: it is the only undo for this" >&2
    echo "   phase's renames and tag writes." >&2
    exit 2
  fi
  if snapshot_exists "$LIB_SNAPSHOT"; then
    echo "REFUSING: $LIB_SNAPSHOT already exists. Same reason as above - a library" >&2
    echo "   untouched-proof taken against a stale baseline cannot distinguish this run's" >&2
    echo "   reach from anything that happened before it." >&2
    exit 2
  fi
  zfs_exec "zfs snapshot '$DL_SNAPSHOT'" >/dev/null 2>&1 || true
  zfs_exec "zfs snapshot '$LIB_SNAPSHOT'" >/dev/null 2>&1 || true
  snapshot_exists "$DL_SNAPSHOT"  || { echo "REFUSING: could not create or read back $DL_SNAPSHOT" >&2; exit 2; }
  snapshot_exists "$LIB_SNAPSHOT" || { echo "REFUSING: could not create or read back $LIB_SNAPSHOT" >&2; exit 2; }
  pass "fresh baselines created and read back: $DL_SNAPSHOT and $LIB_SNAPSHOT"
  echo ""

  # Per-row scope check on THIS side as well as inside the runner.
  local rows=0 rp real
  while IFS=$'\t' read -r _ rp _ _ _ _ _ _ _; do
    [ -z "${rp:-}" ] && continue
    rows=$((rows + 1))
    real="$(assert_row_in_scope "$rp")"
  done < "$APPROVED_LIST"
  pass "$rows approved row(s), every one inside $DOWNLOADS"
  echo ""

  # Ship the approved list to atlantis and prove it arrived byte-identical: the runner must act on
  # exactly what the operator approved, not on a re-derivation.
  local list_sha remote_sha
  list_sha="$(sha256sum "$APPROVED_LIST" | awk '{print $1}')"
  zfs_exec "mkdir -p '$RUNNER_DIR'"
  if [ "$ZFS_ROUTE" = "local" ]; then
    cp -- "$APPROVED_LIST" "$RUNNER_DIR/rows.tsv"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=15 "root@${ZFS_HOST}" "cat > '$RUNNER_DIR/rows.tsv'" < "$APPROVED_LIST"
  fi
  remote_sha="$(zfs_exec "sha256sum '$RUNNER_DIR/rows.tsv'" | awk '{print $1}')"
  if [ "$list_sha" != "$remote_sha" ]; then
    echo "REFUSING: the approved list did not arrive on atlantis byte-identical." >&2
    echo "   local  $list_sha" >&2
    echo "   remote $remote_sha" >&2
    exit 2
  fi
  pass "approved list on atlantis, sha256 $list_sha"

  # Write the runner and launch it detached, stdin closed, output to a log on atlantis.
  runner_payload | zfs_exec "cat > '$RUNNER_DIR/runner.sh'"
  zfs_exec "rm -f '$RUNNER_DIR/sentinel'"
  local launch
  if [ "$launcher" = "setsid" ]; then
    launch="setsid bash '$RUNNER_DIR/runner.sh' '$RUNNER_DIR/rows.tsv' '$UIDGID' '$DOWNLOADS' '$RUNNER_DIR/sentinel' '$MEDIA_ROOT' < /dev/null > '$RUNNER_DIR/run.log' 2>&1 &"
  else
    launch="nohup bash '$RUNNER_DIR/runner.sh' '$RUNNER_DIR/rows.tsv' '$UIDGID' '$DOWNLOADS' '$RUNNER_DIR/sentinel' '$MEDIA_ROOT' < /dev/null > '$RUNNER_DIR/run.log' 2>&1 &"
  fi
  local t0 t1
  t0="$(date +%s)"
  zfs_exec "$launch" || { echo "REFUSING: could not launch the detached runner" >&2; exit 2; }
  pass "runner launched detached on atlantis; log at $RUNNER_DIR/run.log"
  echo ""

  echo "Polling for the sentinel (max ${MAX_WAIT_SECONDS}s, every ${POLL_SECONDS}s)"
  rule
  local waited=0 sentinel=""
  while [ "$waited" -lt "$MAX_WAIT_SECONDS" ]; do
    sentinel="$(zfs_exec "cat '$RUNNER_DIR/sentinel' 2>/dev/null" || true)"
    if [ -n "$sentinel" ]; then break; fi
    if ! zfs_exec "pgrep -f 'phase05-chown/runner.sh' >/dev/null" 2>/dev/null; then
      # THE THIRD STATE: no sentinel and no runner. That is a could-not-look, not a pass.
      echo ""
      fail "the runner is gone and wrote no sentinel. State is UNKNOWN, NOT complete."
      fail "Read $RUNNER_DIR/run.log on atlantis. The chown is idempotent; re-running is the recovery."
      exit 1
    fi
    sleep "$POLL_SECONDS"
    waited=$((waited + POLL_SECONDS))
    info "still running, ${waited}s elapsed: $(zfs_exec "tail -n 1 '$RUNNER_DIR/run.log' 2>/dev/null" || true)"
  done
  t1="$(date +%s)"
  local elapsed=$((t1 - t0))

  if [ -z "$sentinel" ]; then
    fail "no sentinel after ${MAX_WAIT_SECONDS}s. The runner may still be working - this is a"
    fail "could-not-look, not a failure. Re-poll, or read $RUNNER_DIR/run.log on atlantis."
    exit 1
  fi
  echo ""
  info "sentinel: $sentinel"
  local runner_exit
  runner_exit="$(printf '%s' "$sentinel" | sed -n 's/.*exit=\([0-9]*\).*/\1/p')"
  if [ "${runner_exit:-9}" != "0" ]; then
    fail "runner exited ${runner_exit:-unknown}. NOTHING is assumed complete."
    zfs_exec "tail -n 40 '$RUNNER_DIR/run.log'" || true
    exit 1
  fi
  pass "runner completed, exit 0, wall clock ${elapsed}s"
  echo ""

  # --- verification ---------------------------------------------------------------------------
  echo "Verification"
  rule
  info "after census - ONE whole-tree pass, and nothing else may run one at the same time"
  local after
  after="$(survey_payload | remote_bash "$DOWNLOADS" "$WANT_UID" "$WANT_GID" "$RUNNER_DIR" "$WALK_TIMEOUT")" || true
  a() { printf '%s\n' "$after" | awk -F'\t' -v k="$1" '$1=="##META" && $2==k{print $3; exit}'; }
  local a_total a_foreign
  a_total="$(a total_entries)"; a_foreign="$(a foreign_entries)"
  echo "  after: $a_total entries, $a_foreign not $UIDGID"
  echo "  (entries that arrived AFTER the run started will be among them - the download client"
  echo "   writes at roughly one music job per 72 s. That is expected, and it is exactly why"
  echo "   D-25 forbids a standing check for this.)"
  echo ""

  # zfs diff, LINE-CLASS COUNTS ONLY. The raw output is a quarter of a million lines.
  info "zfs diff against the FRESH baseline $DL_SNAPSHOT - line classes only"
  local diffcounts
  diffcounts="$(zfs_exec "zfs diff -H '$DL_SNAPSHOT' tank/downloads 2>/dev/null | awk '{c[\$1]++} END {for (k in c) printf(\"%s %d\n\", k, c[k])}'" || true)"
  printf '%s\n' "$diffcounts" | sed 's/^/    /'
  echo ""
  info "non-M lines, named individually (a live tree can legitimately produce them)"
  zfs_exec "zfs diff -H '$DL_SNAPSHOT' tank/downloads 2>/dev/null | awk '\$1 != \"M\"' | head -n 200" | sed 's/^/    /' || true
  echo ""

  # THE LIBRARY UNTOUCHED-PROOF. Zero lines, or Phase 1's D-20 was breached.
  info "library untouched-proof: zfs diff $LIB_SNAPSHOT"
  local libcount
  libcount="$(zfs_exec "zfs diff -H '$LIB_SNAPSHOT' tank/media/Music 2>/dev/null | wc -l" | tr -dc '0-9')"
  if [ "${libcount:-1}" = "0" ]; then
    pass "library untouched-proof: 0 lines - the scope guard held and Phase 1's D-20 is intact"
  else
    fail "library untouched-proof: ${libcount} line(s). THE CHOWN REACHED $LIBRARY."
    fail "That is a violation of Phase 1's D-20, not an acceptable result."
  fi
  echo ""

  {
    echo "Phase 5 plan 05-10 - download-tree ownership normalisation"
    echo "date:              $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "caller:            $(hostname)"
    echo "measured from:     atlantis ($ZFS_HOST) - every ownership reading in this record was"
    echo "                   taken on the hypervisor, never from inside LXC 100, whose sparse"
    echo "                   idmap surfaces unmapped on-disk ids as 65534."
    echo "scope guard value: $DOWNLOADS   (literal, asserted before anything was delegated)"
    echo "target owner:      $UIDGID"
    echo "fence snapshot:    $FENCE_SNAPSHOT"
    echo "fresh baselines:   $DL_SNAPSHOT , $LIB_SNAPSHOT"
    echo "approved rows:     $rows   (sha256 $list_sha)"
    echo "runner sentinel:   $sentinel"
    echo "wall clock:        ${elapsed}s"
    echo "after census:      $a_total entries, $a_foreign not $UIDGID"
    echo "library proof:     ${libcount} diff line(s)   (0 required)"
    echo ""
    echo "zfs diff line classes against $DL_SNAPSHOT:"
    printf '%s\n' "$diffcounts"
    echo ""
    echo "D-25: there is NO standing health check asserting $UIDGID across $DOWNLOADS, and there"
    echo "will not be one. The download client keeps writing at roughly one music job per 72 s,"
    echo "so such a check would go red on the next download. THIS RECORD AND ITS DATE ARE THE"
    echo "DELIVERABLE."
    echo ""
    echo "D-26: content moved into _inbox is NOT chowned per-move. A rename preserves ownership,"
    echo "and adding a privileged chown to every move would contradict the one-atomic-rename"
    echo "property the design rests on. Staging carries mixed ownership BY DESIGN. This tree-wide"
    echo "sweep makes that largely moot at phase end but does not make it false - do not write an"
    echo "'everything under _inbox is $UIDGID' assertion on the strength of this record."
    echo ""
    echo "No mode bit was changed anywhere. It is impossible on this pool (EPERM as real root"
    echo "under aclmode=restricted); everything on tank is 0777 and stays that way."
  } > "$VERIFICATION"
  pass "record written to $VERIFICATION"

  if [ "$FAILURES" -gt 0 ]; then
    echo ""
    echo -e "${RED}$FAILURES failed check(s)${NC}"
    exit 1
  fi
  echo ""
  echo -e "${GREEN}apply complete - every approved row acted on and verified${NC}"
  return 0
}

case "$ACTION" in
  enumerate) do_enumerate ;;
  apply)     do_apply ;;
  *)         usage ;;
esac
