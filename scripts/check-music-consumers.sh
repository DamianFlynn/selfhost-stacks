#!/usr/bin/env bash
# check-music-consumers.sh - Read-only audit of the music consumers: the NFS export,
# Music Assistant, and Jellyfin.
# Usage: bash scripts/check-music-consumers.sh [--baseline]
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   Unlike check-music-freeze.sh this script has no "the query cannot be one ssh'd command"
#   forcing constraint - every check here IS a single remote call. It is host-resident because
#   of CREDENTIALS AND REACHABILITY, and that split is worth stating rather than leaving implicit:
#
#     - Jellyfin is on the `t3_proxy` docker network and publishes NO host port. `localhost:8096`
#       is refused. It is reachable ONLY from LXC 100, which is close to decisive on its own.
#     - D-39 puts the Music Assistant credential at /mnt/fast/secrets/ on LXC 100.
#     - D-40 puts the purpose-named Jellyfin API key at /mnt/fast/secrets/ on LXC 100.
#     - atlantis (the Proxmox host, 172.16.1.158) is reachable from LXC 100 for `exportfs -v`,
#       exactly as check-music-freeze.sh:129 already reaches it for `zfs`.
#
#   The ONE pull in the other direction is the HAOS NUC SSH key, which today exists only on the
#   workstation as HA_SSH_KEY/HA_SSH_PORT/HA_SSH_USER in ~/.claude/secrets/ha-deercrest.env.
#   That is resolved with an HA_ROUTE variable following the ZFS_ROUTE precedent
#   (check-music-freeze.sh:123-131): if HA_SSH_KEY is set and usable the `ha mounts info`
#   assertion runs; otherwise HA_ROUTE=skipped, a warn() is emitted, and section 5 relies on the
#   MA-side equivalents, WHICH ALWAYS RUN.
#
#   DO NOT "fix" that by copying the NUC SSH key onto LXC 100. That is credential sprawl for an
#   enrichment check, and the hard assertions do not need it. It is also not a weakening: the
#   MA-side assertions are STRONGER evidence than mount state. If Supervisor's emergency bind is
#   in place, /media/music is empty, MA's scan finds zero files, and both the provider-scoped
#   album count and the three exact-match assertions fail. Mount state tells you about a mount;
#   the album assertions tell you about the thing the mount exists to deliver.
#
# READ-ONLY BY CONTRACT. This script inspects; it never writes, moves, chowns, chmods, mounts,
# unmounts or snapshots. It calls no MA command that mutates state - notably NOT `music/sync`.
# Every mutation in phase 2 belongs to infra/ (the export) and to plan 02-05/02-06 (the mount and
# the provider). Same stance as scripts/check-music-freeze.sh.
#
# What it covers:
#   0. Toolchain preconditions             harness precondition (never a caller's problem)
#   1. The NFS export on atlantis          CONS-01, D-12, D-13, D-51 gate 2, T-02-06, T-02-07
#   2. MA reachability + provider identity CONS-02, D-30, T-02-16
#   3. The three proof albums in MA        CONS-02, D-06, D-07, D-09, D-10
#   4. The three proof albums in Jellyfin  CONS-04 groundwork, D-42
#   5. Mount liveness                      CONS-03, D-11 adjacent
#   6. Summary
#
# EXIT-CODE CONVENTION (inherited verbatim from scripts/check-music-freeze.sh:31-42, which is
# where the estate's convention was established; there was none before it):
#   default mode  - every red finding increments FAILURES and the script ends non-zero.
#   --baseline    - every finding is printed and the script always ends zero, so the before-state
#                   can be recorded while the mount and the provider do not yet exist.
#   usage error   - exit 2, distinct from exit 1 for a failed assertion.
#   Why this is stated rather than inherited: check-renovate.sh exits zero on every finding except
#   a missing renovate.json, and quick-health-check.sh used to never exit non-zero at all.
#   Inheriting that silence is what let the docker `created`-state blind spot hide two down
#   containers for six weeks under a green check.
#
#   --baseline exits 0 AFTER printing the summary, not before. The counts are still emitted.
#   `exit $(( FAILURES > 0 ? 1 : 0 ))` is deliberately NOT used - it cannot express --baseline.
#
# MUSIC ASSISTANT VERSION (D-21 as amended 2026-08-31, and D-56):
#   Every assertion in this file was proven against Music Assistant **2.11.0b0 (BETA)**.
#   Stable is NOT installed in this estate and installing it was rejected - it is a migration on a
#   component the house uses daily, and the beta may hold config that stable will not read.
#   The add-on's `auto_update` stays ON by operator choice, which makes THE RECORDED VERSION THE
#   DRIFT DETECTOR: a later MA release that changes provider behaviour shows up here as a version
#   mismatch warning rather than as a silent pass. The run banner prints the live version next to
#   MA_VERSION_PROVEN on every run, so a committed transcript is self-describing.
#
# API SHAPE NOTES - measured against 2.11.0b0 on 2026-08-31. Each of these contradicts the
# research skeleton this script was planned from, and each would have produced a false pass:
#
#   1. POST /api responses are NOT wrapped in `.result`. `auth/login` returns
#      {access_token, success, user}; `config/providers` returns a BARE ARRAY. A `.result[]` jq
#      filter errors out, and under `|| true` that reads as "no providers", i.e. a silent pass.
#
#   2. MA 2.11 has NO API-token UI. There is no such card in the Settings grid. Auth is
#      username+password exchanged for a JWT via `auth/login`. The JWT's life is 90 days
#      (measured: iat 2026-08-31, exp 2026-11-29), which satisfies D-39's "long-lived token".
#      THIS SCRIPT LOGS IN PER RUN RATHER THAN CACHING THE TOKEN. A cached token expires silently
#      in 90 days, and this script is meant to run unattended for months folded into
#      quick-health-check.sh - a silently-expiring credential inside the estate's only regression
#      detector is precisely the failure mode this project exists to prevent.
#
#      ⚠ THAT NOTE IS ABOUT THE **UI** AND IT IS NOT A JUSTIFICATION FOR THE **API** CHOICE.
#        Correction recorded 2026-09-01 (WR-11), because the two were being read as one thing.
#        `auth/token/create` EXISTS and WORKS on this same server: stacks/selfhosted/arrs/beets.md
#        records a 1-year, named, token_id-revocable token minted through it for the HA sync
#        integration ("HA M4 music sync (phase 02-08)"). So a scoped, revocable, individually
#        auditable credential was available and demonstrably usable, and this script stores the
#        full ACCOUNT PASSWORD instead. The password is strictly more powerful than the token it
#        replaces - among other things it can mint further tokens - and it cannot be revoked
#        without changing the account, which would also break the HA sync integration and every
#        browser session.
#
#      ACCEPTED RISK, recorded here the way the sec=sys risk is recorded in
#      infra/nfs-music-export.tf:30-45, rather than left as a silence:
#        * MA_URL is http://172.16.1.31:8095 - PLAINTEXT HTTP, no TLS. `auth/login` therefore
#          puts the MA account password on the wire on EVERY RUN, which since 02-09 means every
#          quick-health-check.sh. Anyone with LAN or tailnet visibility of traffic to that
#          address can capture it. This is a DIFFERENT exposure from the accepted sec=sys NFS
#          risk and was not previously recorded as a considered choice anywhere.
#        * Bounded by: LAN/tailnet only, 8095 is not forwarded at the perimeter, and CR-01's fix
#          means the value is no longer also in the process table.
#        * THE FIX IS NOT DONE. It is: mint a second named token via `auth/token/create`
#          ("music consumers audit"), store MA_TOKEN in /mnt/fast/secrets/ma-deercrest.env in
#          place of MA_PASSWORD, drop ma_login in favour of the stored bearer, and record the
#          token_id next to the rotation list in 02-09-SUMMARY.md. Keep the per-run version
#          banner - with no login round-trip it becomes the only expiry-drift detector.
#          That is an operator action against the live MA server (it mints and stores a
#          credential); it is deliberately NOT done as a code change here.
#
#   3. `music/albums/count` HAS NO PROVIDER PARAMETER. Verified twice: against
#      /api-docs/commands.json (parameters are favorite_only and album_types, and nothing else)
#      and empirically - `music/albums/count` returned 87 both with and without a `provider` arg
#      while the provider-filtered album list held 9 items. Section 5 therefore counts
#      PROVIDER-FILTERED `music/albums/library_items` and never `music/albums/count`. Using
#      `count` as the liveness gate would have reported GREEN off Spotify's catalogue with the
#      NFS mount broken or entirely absent.
#
#   4. On `music/albums/library_items` the filter argument is named `provider` and takes a
#      provider INSTANCE ID (a string or a list). Confirmed working: a real instance id narrows
#      the list, and an instance id that does not exist returns [] rather than everything. That
#      last property is what makes the unpinned state fail loudly instead of passing by default.
#
# ⚠ THE SPOTIFY FALSE-PASS - the single most important thing in this file (D-30, T-02-16).
#   A live Spotify music provider (instance `spotify--g2SQC45P`) is enabled in MA and its albums
#   are already in the MA library. An UNFILTERED `music/albums/library_items` can therefore return
#   a match for a proof album and this script would report GREEN with the NFS mount broken or
#   never created. Two independent layers defend against that:
#     Layer 1 - every MA assertion filters on the LOCAL provider's INSTANCE ID, never on the
#               display name, which is user-editable in the GUI.
#     Layer 2 - the proof albums were chosen to be ABSENT from what Spotify has supplied. This is
#               not belt-and-braces theatre: MA's library already holds "NOW That's What I Call
#               Music! 116" and "98" credited to Various Artists FROM SPOTIFY, so the obvious VA
#               proof album would have collided with a Spotify entry head-on.
#   The project has recorded six separate occasions of a check reporting a pass it had not earned.
#   Do not add a seventh by relaxing either layer.
#
# JELLYFIN ADDRESSING - three wrong ways and one right way, all measured 2026-08-31:
#   ✗ 192.168.90.31        - the address earlier plans pinned. WRONG. Jellyfin is 192.168.90.25
#                            today, and docker IPAM can move it again. Never pin the literal.
#   ✗ the bare name `jellyfin` from LXC 100 - resolv.conf carries `search deercrest.info`, so it
#                            resolves to CLOUDFLARE'S PUBLIC EDGE (2606:4700:...). A health check
#                            would return 200 from the public website with the container down.
#   ✗ 172.16.1.76          - unreachable from LXC 100 under macvlan host isolation.
#   ✓ docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'
#     resolved fresh on every run. That is what JELLYFIN_ROUTE below reports.
#
# SECRETS (D-39, D-40). Both are read at runtime from /mnt/fast/secrets/ on LXC 100, mode 0600,
# root-owned, and were written there via stdin so the WRITE never entered the process list.
# NO TOKEN, PASSWORD OR KEY APPEARS IN THIS FILE OR ANYWHERE ELSE IN THIS REPOSITORY. The repo is
# public and has one prior credential exposure still recoverable via `git log -S`; a value
# committed here stays recoverable forever even after redaction.
#
# ⚠ CORRECTED 2026-09-01 (CR-01). The sentence above used to continue "...so neither value ever
#   entered the process list on a host running 100+ containers", asserting a property of THIS
#   SCRIPT that this script did not have. It was true of how the files were written and false of
#   how they were read: `jq --arg p "$MA_PASSWORD"` put the MA account password in jq's argv, and
#   `-H "Authorization: Bearer ..."` put both bearer credentials in curl's argv, on every run —
#   continuously, since plan 02-09 folded this script into quick-health-check.sh.
#   /proc/<pid>/cmdline is world-readable here; hidepid is not set on LXC 100.
#
#   What is true NOW, and the only reason it is true, is stated at each site rather than only
#   here — see ma_login(), ma_api() and jf_api():
#     * jq reads MA_USERNAME/MA_PASSWORD from its own environment via $ENV.NAME, placed there by
#       a `VAR=... jq` command prefix (environment, not argv, and not inherited by anything else).
#     * curl reads both Authorization headers from a file with `-H @file`, where the file is a
#       process substitution — argv carries a /dev/fd path and nothing else.
#     * the secrets files are sourced WITHOUT `set -a`, so the values are not exported into the
#       environment of the ssh/docker/jq/curl children this script spawns either.
#   If any of those three is ever changed back, change this paragraph in the same commit.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LIBRARY="/mnt/tank/media/Music"          # the exported dataset; also Jellyfin's Music library
NFS_HOST="172.16.1.158"                  # Proxmox host "atlantis" - the only place exportfs exists
NUC_ADDR="172.16.1.31"                   # HA NUC's LAN source address on the route to atlantis (D-20).
                                         # The tailnet address 100.73.196.51 is deliberately NOT in
                                         # the export line (D-13) and must never be added here.
MA_SECRETS="/mnt/fast/secrets/ma-deercrest.env"
JELLYFIN_SECRETS="/mnt/fast/secrets/jellyfin-deercrest.env"

MA_VERSION_PROVEN="2.11.0b0"             # D-21 as amended / D-56. See the header block.

# Pinned by plan 02-06 when the filesystem provider is created. While it is empty section 2 FAILS
# LOUDLY - it must never pass by default, because an unpinned filter is exactly how a Spotify
# match gets credited to an NFS export.
#
# PINNED 2026-09-01 by plan 02-06 (MA 2.11.0b0). Value taken verbatim from
#   config/providers/get -> .instance_id   for the filesystem_local provider at /media/music.
#
# THIS IS AN INSTANCE ID, NOT A DISPLAY NAME, AND THAT IS DELIBERATE (D-30). MA's provider
# display name is user-editable in the GUI - this instance's `name` is currently null and it
# renders as its default_name "Filesystem (local disk)". A rename in the GUI would silently
# change what this script measures while every assertion still reported green. The instance id
# is generated once at setup and never changes for the life of the instance.
#
# IF MUSIC ASSISTANT IS REBUILT, RESTORED, OR THE PROVIDER IS REMOVED AND RE-ADDED, this value
# MUST be RE-PINNED from `config/providers/get` on the live server. Do not guess it and do not
# reuse the value below - the `--XXXXXXXX` suffix is generated per instance. The provider config
# lives only in MA's settings store on the NUC, never in git; 02-06's SUMMARY carries the full
# read-back so the provider can be recreated identically.
MA_LOCAL_PROVIDER_INSTANCE="filesystem_local--XJaJWNUS"

# The SECOND, TEMPORARY provider — the one that serves the scratch export in tank/downloads
# (D-04/D-15). It is DELIBERATELY EMPTY in steady state, and that is the whole point: the
# temporary export and its provider are torn down by `terraform apply` with
# music_temp_export_enabled = false, so in steady state there is nothing for a `scope=temp-export`
# row to be asserted against.
#
# Empty therefore means REPORTED, not asserted, for those rows — never a silent pass, and never a
# permanently-red assertion either. A check that can never be green is a check readers learn to
# ignore, which is exactly the failure 01-09 recorded when it scoped the library-mode assertion
# down to a report. `scope=library` rows are NEVER affected by this and are always asserted.
#
# Set it (to the instance id from `config/flows/submit` -> .result.instance_id) only while that
# control is actually standing, and clear it again at teardown.
MA_TEMP_PROVIDER_INSTANCE="${MA_TEMP_PROVIDER_INSTANCE:-}"

# How many provider-filtered albums section 3 pulls before matching locally. It is NOT a tuning
# knob for speed: the exact match is done here rather than by MA's `search`, because MA 2.11's
# `search` returned [] for an album's own exact name (measured 02-07 — see section 3). Section 5
# already used 2000 for the same reason of "enough to be a real count".
MA_LIBRARY_SCAN_LIMIT=2000

# Jellyfin's Music library ItemId, measured 2026-08-31 via /Library/VirtualFolders. Scoping the
# album search to it stops a same-named item in Movies/Shows/Collections answering for Music.
JELLYFIN_MUSIC_LIBRARY_ID="7e64e319657a9516ec78490da03edccb"

SSH_OPTS=(-n -o BatchMode=yes -o ConnectTimeout=5)   # -n so a nested ssh cannot eat this
                                                     # script's stdin (measured: it does)

# THE THREE PROOF ALBUMS (D-06, D-07, D-09) - pinned here, in the script, with NO external
# fixture file. Phase 1 committed zero non-.md artifacts under .planning/, and one canonical
# machine-checkable set that travels with the assertions is the point of D-09.
#
# Fields: shape | absolute path | expected album | expected albumartist | audio_md5 | tracks | scope
#
#   audio_md5 is Phase 1's QUAL-01 join key (ffmpeg -map 0:a -c copy -f md5) for ONE representative
#   track. It is what identifies WHICH file a later checksum proves arrived; source_path is an
#   attribute, never the key.
#
#   scope=library      - inside /mnt/tank/media/Music. Visible to Jellyfin now, and to MA once the
#                        NFS mount (02-05) and the provider (02-06) exist.
#   scope=temp-export  - served from tank/downloads via the SECOND, TEMPORARY export (D-04/D-15,
#                        authored in 02-02, enabled in 02-07). Jellyfin bind-mounts only
#                        /mnt/tank/media, so it STRUCTURALLY cannot see this one - section 4 warns
#                        rather than fails for it, and says why inline.
#
# Every one of these was PRE-VERIFIED from the QUAL-01 snapshot BEFORE being used as a gate (D-07):
# albumartist non-empty and identical across all tracks, album identical across all tracks, and -
# for the two library albums - the top-level folder name BYTE-IDENTICAL to the albumartist tag.
# That last check matters because plan 02-06 sets missing_album_artist_action: folder_name;
# agreement now is what makes a later disagreement diagnostic instead of ambiguous.
PROOF_ALBUMS=(
  # 1. SINGLE-ARTIST. 15 tracks, one disc, 1 distinct albumartist, 1 distinct album.
  #    Folder "Chris Norman" == albumartist "Chris Norman" (hex 4368726973204e6f726d616e).
  #    Chosen partly for obscurity: absent from the Spotify-supplied MA library (Layer 2).
  "single-artist|${LIBRARY}/Chris Norman/Lifelines (2026)|Lifelines|Chris Norman|39da9daf74c3a4e2dcc0f35a7612d122|15|library"

  # 2. MULTI-DISC, and the hard shape on purpose. 36 tracks across 2 discs in a FLAT folder with
  #    no CD1/CD2 subdirectories - and only 19 DISTINCT TRACK NUMBERS, so track numbers collide
  #    across the two discs and nothing but the `disc` tag disambiguates them. That is exactly the
  #    shape Phase 1 flagged. Folder "Garth Brooks" == albumartist "Garth Brooks".
  "multi-disc|${LIBRARY}/Garth Brooks/The Ultimate Hits (2007)|The Ultimate Hits|Garth Brooks|48556eceed2f2cc16709269ee93aa18f|36|library"

  # 3. VARIOUS ARTISTS - a D-08 SUBSTITUTE. The 13-folder library contains NO Various Artists
  #    compilation at all (measured: 13 top-level folders, every one a single named artist), so
  #    the shape is substituted from the backlog rather than silently skipped. 50 tracks, all 50
  #    carrying albumartist "Various Artists" and one identical album string, across 40 DISTINCT
  #    track artists - a genuine compilation, not a mislabelled single-artist release.
  #    Never stage it under /mnt/tank/media/Music: CLAUDE.md forbids staging unmanaged content
  #    there and Phase 1 sealed that tree.
  #    Spotify defence (Layer 2): a Mastermix DJ-service compilation is not on Spotify. A "NOW
  #    That's What I Call Music" release would have collided with MA's existing Spotify entries.
  "various-artists|/mnt/tank/downloads/complete/nzb/unsorted/VA-Mastermix.Essential.Hits.Pop.4.2005-2009-2025|Mastermix Essential Hits - Pop 4 - 2005-2009|Various Artists|097b998f01a67d2f738d3cf415c9d7f2|50|temp-export"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASELINE_MODE=0
for arg in "$@"; do
  case "$arg" in
    --baseline) BASELINE_MODE=1 ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: bash scripts/check-music-consumers.sh [--baseline]" >&2
      exit 2
      ;;
  esac
done

FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

# Scoped sub-counters, so the summary says WHICH consumer failed rather than only that something
# did. Same idiom as check-music-freeze.sh:473-474.
EXPORT_FAILURES=0
MA_FAILURES=0
JELLYFIN_FAILURES=0
export_fail()   { fail "$*"; EXPORT_FAILURES=$((EXPORT_FAILURES + 1)); }
ma_fail()       { fail "$*"; MA_FAILURES=$((MA_FAILURES + 1)); }
jellyfin_fail() { fail "$*"; JELLYFIN_FAILURES=$((JELLYFIN_FAILURES + 1)); }

# ---------------------------------------------------------------------------------------------
# Routes. Each records WHICH path answered and prints it in section 0 - "which route answered" is
# exactly the ambiguity D-20 exists to remove, and it is the ZFS_ROUTE precedent
# (check-music-freeze.sh:123-131) applied to three different remotes.
# ---------------------------------------------------------------------------------------------
EXPORT_ROUTE="unavailable"
MA_ROUTE="unavailable"
JELLYFIN_ROUTE="unavailable"
HA_ROUTE="skipped"

exportfs_query() { ssh "${SSH_OPTS[@]}" "root@${NFS_HOST}" "$@"; }

# --- Music Assistant --------------------------------------------------------------------------
MA_URL=""
MA_TOKEN=""
MA_VERSION_LIVE="unknown"

# WR-01: EVERY variable that arrives from an external file or from the caller's environment is
# defaulted HERE, before any code path can read it. This script runs under `set -u` (:128), and
# `set -u` turns "the credential file was renamed upstream" into `unbound variable` — the run dies
# mid-section, sections 5 and 6 never execute, and the caller gets a failed exit code with an
# EMPTY summary block. That is strictly worse than a failed assertion: a failed assertion says
# which consumer is broken, an abort says nothing at all.
#
# Defaulting is only half the fix. A variable that is empty because the file was unreadable must
# still turn into a RED assertion, never a skipped one — that is done at the route blocks below,
# which set the corresponding *_ROUTE to "unavailable" so the existing "UNKNOWN, not green"
# branches fire. Do not add a default here without also adding its gate there.
MA_USERNAME="${MA_USERNAME:-}"
MA_PASSWORD="${MA_PASSWORD:-}"
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"
HA_SSH_KEY="${HA_SSH_KEY:-}"
HA_SSH_HOST="${HA_SSH_HOST:-}"
HA_SSH_PORT="${HA_SSH_PORT:-22}"
HA_SSH_USER="${HA_SSH_USER:-root}"

ma_login() {
  # Logs in fresh. See API SHAPE NOTE 2 for why the JWT is deliberately not cached.
  #
  # CREDENTIALS AND argv (CR-01, fixed 2026-09-01). The previous version of this comment claimed
  # the password "never entered argv" while the line beneath it passed the plaintext password to
  # `jq --arg p "$MA_PASSWORD"`, i.e. as jq's argv[4]. /proc/<pid>/cmdline is world-readable on
  # LXC 100 (no hidepid), so anything sampling the process table captured it. A comment asserting
  # a control that is not implemented is worse than no comment: it stops the next reader looking.
  #
  # What the code below actually does, and why each half is needed:
  #   * jq reads the two values from ITS OWN ENVIRONMENT via $ENV.NAME. The `VAR=... jq ...`
  #     command-prefix form puts them in jq's environment ONLY — it is not an argv word, and it
  #     does not export them to the rest of this script's children (see the secrets block, which
  #     no longer uses `set -a` for the same reason).
  #   * the request body reaches curl on stdin (--data-binary @-), unchanged and already correct.
  # Neither MA_USERNAME nor MA_PASSWORD appears in any process's argv on this host.
  local body resp
  body="$(MA_USERNAME="$MA_USERNAME" MA_PASSWORD="$MA_PASSWORD" jq -nc \
          '{command:"auth/login",args:{username:$ENV.MA_USERNAME,password:$ENV.MA_PASSWORD}}')"
  resp="$(printf '%s' "$body" | curl -s --max-time 20 -X POST "${MA_URL}/api" \
          -H 'Content-Type: application/json' --data-binary @- || true)"
  # NOT .result.access_token - see API SHAPE NOTE 1.
  MA_TOKEN="$(printf '%s' "$resp" | jq -r '.access_token // empty' 2>/dev/null || true)"
  [[ -n "$MA_TOKEN" ]]
}

ma_api() {
  # $1 = command, $2 = args object as JSON (default {}). Returns the raw body on stdout.
  #
  # CR-01: the bearer JWT is NOT passed as `-H "Authorization: Bearer $MA_TOKEN"`. curl's
  # `-H @file` form (>= 7.55.0; LXC 100 runs 8.14.1) reads the header text FROM A FILE, so argv
  # carries only the path. The file is a process substitution, so the token never touches disk
  # either, and `printf` is a bash builtin so it has no argv of its own.
  # The body still goes on stdin, which is why a config file (-K) is not used here: -K would need
  # stdin as well, and only one of the two can have it.
  local cmd="$1" args="${2:-}" body
  [[ -z "$args" ]] && args='{}'
  body="$(jq -nc --arg c "$cmd" --argjson a "$args" '{command:$c,args:$a}')"
  printf '%s' "$body" | curl -s --max-time 30 -X POST "${MA_URL}/api" \
    -H 'Content-Type: application/json' \
    -H @<(printf 'Authorization: Bearer %s\n' "$MA_TOKEN") --data-binary @- || true
}

# The provider filter, as its own function so the intent is greppable and impossible to drop by
# accident. The JSON argument is named `provider` and takes a provider INSTANCE ID; the display
# name is user-editable in the GUI and is never used here (D-30).
provider_filter() {
  # $1 = extra args object (default {}), $2 = instance id to filter on (default: the pinned local
  # provider). The second argument exists ONLY so a scope=temp-export row can be asserted against
  # the temporary provider that serves it; it never widens the filter and it is never empty when
  # used, because an empty `provider` would silently drop the filter and let Spotify answer.
  local extra="${1:-}" inst="${2:-$MA_LOCAL_PROVIDER_INSTANCE}"
  [[ -z "$extra" ]] && extra='{}'
  [[ -z "$inst" ]] && { echo '{}'; return 1; }
  jq -nc --arg p "$inst" --argjson extra "$extra" \
    '$extra + {provider: $p}'
}

# --- Jellyfin ---------------------------------------------------------------------------------
JELLYFIN_ADDR=""

jf_api() {
  # $1 = path, remaining args are passed to curl (use --data-urlencode for query params).
  # CR-01: same `-H @file` treatment as ma_api — the API key reaches curl through a process
  # substitution, never through argv. See ma_api's comment for the mechanism.
  local path="$1"; shift
  curl -s --max-time 20 -G \
    -H @<(printf 'Authorization: MediaBrowser Token="%s"\n' "$JELLYFIN_API_KEY") \
    "http://${JELLYFIN_ADDR}${path}" "$@" || true
}

# =============================================================================================
echo "🎧 Music Consumers Audit (export + Music Assistant + Jellyfin)"
rule
echo "  library:      $LIBRARY"
echo "  export host:  $NFS_HOST (atlantis)"
echo "  NFS client:   $NUC_ADDR (HA NUC, LAN source address - NOT the tailnet address, D-13)"
echo "  host:         $(hostname)"
echo "  date:         $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "  MA proven at: $MA_VERSION_PROVEN   (D-21 amended / D-56 — auto_update is ON, so this"
echo "                          recorded version IS the drift detector)"
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "  mode:         ${YELLOW}--baseline (report only, always exits 0)${NC}"
else
  echo "  mode:         assert (exits non-zero on any failed check)"
fi
echo ""

# ---------------------------------------------------------------------------------------------
# 0. Toolchain preconditions
# ---------------------------------------------------------------------------------------------
echo "🧰 0. Toolchain preconditions"
rule
TOOLS_MISSING=0
for t in curl jq ssh sha256sum docker; do
  if command -v "$t" >/dev/null 2>&1; then
    ver="$("$t" --version 2>/dev/null | head -1 || true)"
    [[ -z "$ver" ]] && ver="$("$t" -V 2>&1 | head -1 || true)"
    pass "$t $(command -v "$t") — ${ver:-version unknown}"
  else
    # Same stance as check-music-freeze.sh:168 - the harness owns its own dependencies.
    fail "$t NOT FOUND — a missing binary here is a harness failure, not a caller's local problem"
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  fi
done
# sha256sum is listed because D-11 chose it (present on both atlantis and the NUC) as the tool
# for proving BYTES ARRIVE through the mount. That proof is plan 02-07's, taken on the NUC; it is
# named here so the dependency is visible from the harness that will later carry it.

echo ""
# --- secrets ---
#
# WR-13: THE PERMISSION ASSERTION IS A GATE, NOT A REMARK. The previous version recorded the
# `fail` and then sourced the file anyway. `.` executes arbitrary shell, not just assignments —
# so the exact state the assertion detects (the file is writable by, or owned by, somebody other
# than root) was the state in which this script handed that somebody root code execution on
# LXC 100, on every quick-health-check run. Refuse instead.
#
# `set -a` is also gone, deliberately. It marked EVERY key in both files for export, putting the
# MA password and the Jellyfin API key into the environment of every child this script spawns —
# ssh to atlantis, ssh to the NUC, docker inspect, every jq and curl — i.e. into
# /proc/<pid>/environ for a large process tree. Nothing here needs them in a child's environment:
# `.` sets ordinary shell variables, and the one place a child genuinely needs them (jq, for
# CR-01's $ENV.NAME) exports exactly those two, for exactly that one command, via a command prefix.
if [[ -r "$MA_SECRETS" ]]; then
  MA_MODE="$(stat -c '%a %U' "$MA_SECRETS" 2>/dev/null || echo '? ?')"
  if [[ "$MA_MODE" == "600 root" ]]; then
    pass "MA credential $MA_SECRETS ($MA_MODE)"
    # shellcheck disable=SC1090
    . "$MA_SECRETS"          # no `set -a`: in-process only
  else
    fail "MA credential $MA_SECRETS has mode/owner '$MA_MODE', want '600 root' (D-39) — REFUSING"
    echo "         to source it. A file this script cannot vouch for is shell code it will not run"
    echo "         as root. Fix the mode/owner, then re-run. Sections 2, 3 and 5 are UNKNOWN below."
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  fi
  MA_URL="${MA_URL:-}"
else
  fail "MA credential $MA_SECRETS missing or unreadable — sections 2, 3 and 5 cannot run (D-39)"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

if [[ -r "$JELLYFIN_SECRETS" ]]; then
  JF_MODE="$(stat -c '%a %U' "$JELLYFIN_SECRETS" 2>/dev/null || echo '? ?')"
  if [[ "$JF_MODE" == "600 root" ]]; then
    pass "Jellyfin credential $JELLYFIN_SECRETS ($JF_MODE)"
    # shellcheck disable=SC1090
    . "$JELLYFIN_SECRETS"    # no `set -a`: in-process only
  else
    fail "Jellyfin credential $JELLYFIN_SECRETS has mode/owner '$JF_MODE', want '600 root' (D-40) — REFUSING"
    echo "         to source it. See the WR-13 note above. Section 4 is UNKNOWN below."
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  fi
else
  fail "Jellyfin credential $JELLYFIN_SECRETS missing or unreadable — section 4 cannot run (D-40)"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

# Re-default after sourcing. The files may legitimately not define every key (or may have been
# refused above), and `set -u` must not be able to abort a run mid-section — see the WR-01 note
# at the top. Empty is turned into a RED route below, never into a skip.
MA_USERNAME="${MA_USERNAME:-}"
MA_PASSWORD="${MA_PASSWORD:-}"
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"

echo ""
# --- routes ---
if exportfs_query true >/dev/null 2>&1; then
  EXPORT_ROUTE="ssh:${NFS_HOST}"
  pass "export queries delegated to root@${NFS_HOST} (exportfs does not exist on LXC 100)"
else
  fail "root@${NFS_HOST} unreachable over ssh — section 1 cannot be asserted"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

# WR-01: credentials are a PRECONDITION of the route, not a thing discovered halfway through
# section 2. Missing MA_USERNAME/MA_PASSWORD used to reach ma_login and abort the whole run on
# `set -u`; now it fails the route, and every downstream section takes its existing
# "MA unreachable — ... UNKNOWN, not green" branch.
if [[ -z "$MA_URL" || -z "$MA_USERNAME" || -z "$MA_PASSWORD" ]]; then
  fail "MA credentials incomplete (url=${MA_URL:+set}${MA_URL:-unset} user=${MA_USERNAME:+set}${MA_USERNAME:-unset} pass=${MA_PASSWORD:+set}${MA_PASSWORD:-unset})"
  echo "         — sections 2, 3 and 5 are UNKNOWN, not green. Check $MA_SECRETS (D-39)."
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
elif ma_login; then
  MA_ROUTE="$MA_URL"
  MA_VERSION_LIVE="$(curl -s --max-time 15 "${MA_URL}/info" | jq -r '.server_version // "unknown"' 2>/dev/null || echo unknown)"
  # IN-01: when curl fails, jq gets empty input, prints nothing and exits 0 — so `|| echo unknown`
  # never fires and this lands as the EMPTY STRING, which the drift guard below reads as "not
  # unknown" and prints `MA version drift: running , ...`. The version stamp is described in the
  # header as THE drift detector; it must not be able to read blank.
  [[ -z "$MA_VERSION_LIVE" ]] && MA_VERSION_LIVE="unknown"
  pass "Music Assistant reachable at $MA_URL, auth/login OK (fresh JWT, not cached)"
else
  fail "Music Assistant login failed at '${MA_URL:-unset}' — sections 2, 3 and 5 cannot be asserted"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

# WR-01: the API key gates the route too. Without it, `docker inspect` would still resolve an
# address, JELLYFIN_ROUTE would be set, and the first jf_api call would abort the run on `set -u`.
if [[ -z "$JELLYFIN_API_KEY" ]]; then
  fail "Jellyfin API key unavailable (see $JELLYFIN_SECRETS, D-40) — section 4 is UNKNOWN, not green"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
elif command -v docker >/dev/null 2>&1; then
  JELLYFIN_ADDR="$(docker inspect jellyfin \
    --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}' 2>/dev/null || true):8096"
  if [[ "$JELLYFIN_ADDR" == ":8096" ]]; then
    JELLYFIN_ADDR=""
    fail "could not resolve jellyfin's t3_proxy address from docker — section 4 cannot run"
    TOOLS_MISSING=$((TOOLS_MISSING + 1))
  else
    JELLYFIN_ROUTE="docker-inspect:${JELLYFIN_ADDR}"
    pass "Jellyfin resolved to $JELLYFIN_ADDR via docker inspect (never a pinned literal, never the bare name)"
  fi
fi

# HA_ROUTE - the one credential that lives on the workstation, not here. See the header.
# WR-01: HA_SSH_HOST is required, not optional. Section 5 builds `user@${HA_SSH_HOST}` with no
# default, so setting HA_SSH_KEY alone — the exact combination the old `${HA_SSH_HOST:-nuc}`
# here anticipated — used to abort the run on `set -u` instead of skipping the enrichment.
if [[ -n "$HA_SSH_KEY" && -r "$HA_SSH_KEY" && -n "$HA_SSH_HOST" ]]; then
  HA_ROUTE="ssh:${HA_SSH_HOST}"
  pass "HAOS SSH key available — section 5's mount-state enrichment will run"
elif [[ -n "$HA_SSH_KEY" && -r "$HA_SSH_KEY" && -z "$HA_SSH_HOST" ]]; then
  HA_ROUTE="skipped"
  warn "HA_SSH_KEY is set and readable but HA_SSH_HOST is EMPTY — section 5's enrichment is SKIPPED."
  echo "      This is a configuration gap, not the by-design skip below: set HA_SSH_HOST to the"
  echo "      NUC's address alongside the key. The MA-side assertions still run and still assert."
else
  HA_ROUTE="skipped"
  warn "HA_SSH_KEY not set/readable on this host — section 5's 'ha mounts info' enrichment is SKIPPED."
  echo "      This is by design, not a gap: the NUC SSH key lives on the workstation and copying it"
  echo "      here would be credential sprawl for an enrichment check. The MA-side assertions in"
  echo "      sections 3 and 5 always run and are stronger evidence — an emergency bind leaves"
  echo "      /media/music empty, so MA's provider-scoped album count and the three exact-match"
  echo "      assertions all fail. Do not 'fix' this by adding the key."
fi

echo ""
info "routes: export=$EXPORT_ROUTE  ma=$MA_ROUTE  jellyfin=$JELLYFIN_ROUTE  ha=$HA_ROUTE"
info "MA version: live=$MA_VERSION_LIVE  proven-at=$MA_VERSION_PROVEN"
if [[ "$MA_VERSION_LIVE" != "unknown" && "$MA_VERSION_LIVE" != "$MA_VERSION_PROVEN" ]]; then
  # REPORTED, not asserted - same report-not-assert stance as check-music-freeze.sh:405-416. The
  # add-on auto-updates by operator choice (D-56), so a mismatch is expected eventually and a
  # permanent red would train the reader to ignore the whole script. What it must never do is be
  # INVISIBLE: an MA release changing provider behaviour is the thing this line exists to surface.
  warn "MA version drift: running $MA_VERSION_LIVE, assertions were proven at $MA_VERSION_PROVEN."
  echo "      Re-prove the provider assertions against the new version and update MA_VERSION_PROVEN."
fi
echo ""

# ---------------------------------------------------------------------------------------------
# 1. The NFS export on atlantis (CONS-01)
# ---------------------------------------------------------------------------------------------
echo "📤 1. The NFS export on atlantis (CONS-01, D-12/D-13, T-02-06/T-02-07)"
rule
EXPORT_LINE=""
if [[ "$EXPORT_ROUTE" != "unavailable" ]]; then
  EXPORTFS_RAW="$(exportfs_query 'exportfs -v' 2>/dev/null || true)"
  # `exportfs -v` wraps: when the path is long the client(options) field lands on its own
  # continuation line. Join continuations back onto their path before parsing, otherwise a client
  # string can be credited to the wrong export entirely.
  EXPORT_TABLE="$(printf '%s\n' "$EXPORTFS_RAW" \
    | awk '/^[^[:space:]]/ { if (NR>1) printf "\n"; printf "%s", $0; next }
           { printf " %s", $1 }
           END { printf "\n" }')"
  # IN-02: select the export line by EXACT PATH, not by substring.
  #
  # `grep -F "$LIBRARY "` selected any line CONTAINING "/mnt/tank/media/Music " — so a sibling
  # export at "/mnt/tank/media/Music Videos" (an entirely plausible path in this estate) was
  # selected too, and a two-line EXPORT_LINE makes the client and option parsing below produce
  # multi-line values.
  #
  # An anchored regex is NOT sufficient either, and that is worth stating because it is the
  # obvious fix and it does not work: `^/mnt/tank/media/Music[[:space:]]` still matches
  # "/mnt/tank/media/Music Videos ...", because the space in "Music Videos" IS the [[:space:]].
  # Measured, not reasoned about.
  #
  # So: an exact literal prefix (index(...)==1, no regex over the path at all), plus a shape check
  # that what follows the path is a CLIENT FIELD — one unspaced token ending in `(` — which is
  # what the joined `exportfs -v` line always looks like and which "Videos " is not.
  EXPORT_LINE="$(printf '%s\n' "$EXPORT_TABLE" \
    | awk -v p="$LIBRARY" 'index($0, p " ") == 1 {
        rest = substr($0, length(p) + 2)
        if (rest ~ /^[^ ]*\(/) print
      }' || true)"
  EXPORT_LINE_COUNT="$(printf '%s' "$EXPORT_LINE" | grep -c . || true)"

  if [[ "${EXPORT_LINE_COUNT:-0}" -gt 1 ]]; then
    export_fail "CONS-01: $LIBRARY matched $EXPORT_LINE_COUNT export lines — the table is AMBIGUOUS,"
    echo "         so no option or client assertion below can be attributed to one export. UNKNOWN,"
    echo "         not green. The matching lines were:"
    printf '%s\n' "$EXPORT_LINE" | sed 's/^/      /'
  elif [[ -z "$EXPORT_LINE" ]]; then
    export_fail "CONS-01: $LIBRARY is not exported at all"
    echo "$EXPORT_TABLE" | sed 's/^/      /'
  else
    info "export line: $EXPORT_LINE"
    CLIENT_FIELD="$(printf '%s' "$EXPORT_LINE" | sed "s#^${LIBRARY}[[:space:]]*##" | sed 's/(.*//')"
    OPTS="$(printf '%s' "$EXPORT_LINE" | sed -n 's/.*(\(.*\)).*/\1/p')"

    # Exact client string. A substring match would accept 172.16.1.310 or a widened netmask.
    if [[ "$CLIENT_FIELD" == "$NUC_ADDR" ]]; then
      pass "CONS-01: client is exactly $NUC_ADDR"
    else
      export_fail "CONS-01: client field is '$CLIENT_FIELD', want exactly '$NUC_ADDR'"
    fi

    # T-02-07: a future edit widening the export to everyone, or to a whole subnet.
    if [[ "$CLIENT_FIELD" == "*" || "$CLIENT_FIELD" == *"/"* ]]; then
      export_fail "CONS-01: client field '$CLIENT_FIELD' is a wildcard or CIDR — the export has been WIDENED (T-02-07)"
    else
      pass "CONS-01: client field is neither '*' nor a CIDR"
    fi

    # REQUIRED options.
    #
    # IN-03: `anonuid=568` / `anongid=568` are LITERALS HERE while infra/nfs-music-export.tf:55-58
    # forbids the literal on its side and interpolates var.apps_uid/var.apps_gid, precisely so the
    # inheritance from Phase 1's normalisation stays visible in the code. That coupling is real and
    # it is one-directional: changing var.apps_uid would apply cleanly on atlantis and then fail
    # HERE, with a message that reads like an export defect rather than like a deliberate change.
    # It is left as a literal rather than plumbed through, because this script runs on LXC 100 and
    # has no access to Terraform's variables — but if you are here because this line went red after
    # a var.apps_uid change, that is the reason, and both places must move together.
    # 568 is `apps`, stated independently in CLAUDE.md, STANDARDS.md:141, DEPLOYMENT.md:31 and
    # README.md:29.
    #
    # WR-12: sec=sys is asserted. It is named in the Terraform's security note as a considered
    # choice with two rejected alternatives; without a detector, a change of security flavour
    # (which would change who can read this share) would pass every gate silently.
    for opt in ro all_squash anonuid=568 anongid=568 mountpoint no_subtree_check sec=sys; do
      # grep -F: 'anonuid=568' is a literal, and ugrep-family greps parse {...} style
      # metacharacters in ways a plain -q does not survive. -F removes the whole question.
      if printf '%s' ",$OPTS," | grep -qF ",$opt,"; then
        pass "CONS-01: option present — $opt"
      else
        export_fail "CONS-01: option MISSING — $opt (options were: $OPTS)"
      fi
    done

    # FORBIDDEN options (WR-12). D-51 gate 2 covered no_root_squash and nothing else. Gate 1 is
    # the Terraform apply assertion; this loop is the standing detector a one-off apply-time check
    # would miss, and it now mirrors the full "Deliberately ABSENT" list at
    # infra/nfs-music-export.tf:90-95 rather than one third of it.
    #
    # `crossmnt` is the one that motivated this. The Terraform calls it "a silent scope expansion"
    # — it would implicitly export any child dataset created under the library later — and it is
    # also the natural-looking fix somebody reaches for when a child dataset "isn't visible". It
    # had no detector anywhere. Adding it would have widened the export's scope with every gate
    # in this estate still green.
    for opt in no_root_squash crossmnt rw insecure no_all_squash; do
      if printf '%s' ",$OPTS," | grep -qF ",$opt,"; then
        export_fail "CONS-01: FORBIDDEN option PRESENT — $opt (see infra/nfs-music-export.tf:90-95)"
      else
        pass "CONS-01: forbidden option absent — $opt"
      fi
    done

    # fsid= takes a value, so it needs a prefix match rather than an exact-token match. It would
    # relocate the NFSv4 pseudo-root; both consumers address this share as server:/full/path and
    # would break.
    if printf '%s' ",$OPTS," | grep -qE '(^|,)fsid='; then
      export_fail "CONS-01: FORBIDDEN option PRESENT — fsid= relocates the NFSv4 pseudo-root (nfs-music-export.tf:91-93)"
    else
      pass "CONS-01: forbidden option absent — fsid="
    fi
  fi

  NFS_ON_ATLANTIS="$(exportfs_query 'systemctl is-active nfs-server' 2>/dev/null || true)"
  if [[ "$NFS_ON_ATLANTIS" == "active" ]]; then
    pass "CONS-01: nfs-server is active on atlantis"
  else
    export_fail "CONS-01: nfs-server on atlantis is '$NFS_ON_ATLANTIS', want 'active'"
  fi
else
  export_fail "CONS-01: no route to atlantis — the export is UNKNOWN, not green"
fi

# The server must live on atlantis and nowhere else. An nfs-server on LXC 100 would mean a second
# export table for the same tree, and `exportfs -v` on one host cannot tell you which one a client
# is actually being served by.
LOCAL_NFS="$(systemctl is-active nfs-server 2>/dev/null || true)"
if [[ "$LOCAL_NFS" == "active" ]]; then
  export_fail "CONS-01: nfs-server is ACTIVE on LXC 100 — the export belongs on atlantis only"
else
  pass "CONS-01: nfs-server is not active on LXC 100 (state: ${LOCAL_NFS:-absent})"
fi
echo ""

# ---------------------------------------------------------------------------------------------
# 2. Music Assistant reachability and provider identity (CONS-02)
# ---------------------------------------------------------------------------------------------
echo "🎛  2. Music Assistant reachability and provider identity (CONS-02, D-30)"
rule
PROVIDERS_JSON=""
if [[ "$MA_ROUTE" == "unavailable" ]]; then
  ma_fail "CONS-02: MA unreachable — provider identity is UNKNOWN, not green"
else
  # BARE ARRAY, not .result - API SHAPE NOTE 1.
  PROVIDERS_JSON="$(ma_api config/providers '{}')"
  if ! printf '%s' "$PROVIDERS_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
    ma_fail "CONS-02: config/providers did not return an array — MA API shape changed at $MA_VERSION_LIVE"
  else
    MUSIC_PROVIDERS="$(printf '%s' "$PROVIDERS_JSON" \
      | jq -r '.[] | select(.type=="music") | [.instance_id, .domain, (.enabled|tostring), (.name // "(null)")] | @tsv')"
    info "music providers configured in MA:"
    printf '%s\n' "$MUSIC_PROVIDERS" | sed 's/^/      /'

    # Absence-is-not-health (quick-health-check.sh:74-80): an empty provider list and a healthy
    # one must never look the same.
    if [[ -z "$MUSIC_PROVIDERS" ]]; then
      ma_fail "CONS-02: MA reported ZERO music providers — that is UNKNOWN, not green"
    fi

    if [[ -z "$MA_LOCAL_PROVIDER_INSTANCE" ]]; then
      # NEVER a pass-by-default. With no instance id, every provider-scoped assertion below is
      # unanchored, and an unanchored album match is exactly the Spotify false pass.
      # 02-06 pinned this constant on 2026-09-01. Reaching this branch now means the value was
      # LOST (edited out, or the file was restored from before 02-06) - not that it is pending.
      ma_fail "CONS-02: MA_LOCAL_PROVIDER_INSTANCE is EMPTY. It was pinned by plan 02-06; re-pin it"
      echo "         from 'config/providers/get' on the live MA server (see the constant's comment)."
      echo "         Until then no album assertion can be credited to the NFS export rather than"
      echo "         to Spotify."
    else
      PROV_ROW="$(printf '%s' "$PROVIDERS_JSON" \
        | jq -c --arg i "$MA_LOCAL_PROVIDER_INSTANCE" '.[] | select(.instance_id == $i)')"
      if [[ -z "$PROV_ROW" ]]; then
        ma_fail "CONS-02: pinned provider instance '$MA_LOCAL_PROVIDER_INSTANCE' does not exist in MA"
      else
        P_ENABLED="$(printf '%s' "$PROV_ROW" | jq -r '.enabled')"
        P_STATUS="$(printf '%s' "$PROV_ROW"  | jq -r '.status // "unknown"')"
        P_ERROR="$(printf '%s' "$PROV_ROW"   | jq -r 'if (.last_error // null) == null then "" else (.last_error | tostring) end')"
        P_TYPE="$(printf '%s' "$PROV_ROW"    | jq -r '.type')"

        [[ "$P_ENABLED" == "true" ]] \
          && pass "CONS-02: provider $MA_LOCAL_PROVIDER_INSTANCE is enabled" \
          || ma_fail "CONS-02: provider $MA_LOCAL_PROVIDER_INSTANCE is NOT enabled"
        # D-28: the provider must be content_type music or missing_album_artist_action never applies.
        [[ "$P_TYPE" == "music" ]] \
          && pass "CONS-02: provider type is 'music'" \
          || ma_fail "CONS-02: provider type is '$P_TYPE', want 'music' (D-28)"
        [[ "$P_STATUS" == "loaded" ]] \
          && pass "CONS-02: provider status is 'loaded'" \
          || ma_fail "CONS-02: provider status is '$P_STATUS', want 'loaded'"
        [[ -z "$P_ERROR" ]] \
          && pass "CONS-02: provider last_error is empty" \
          || ma_fail "CONS-02: provider last_error is set — $P_ERROR"
      fi
    fi

    # Standing note on the false-pass risk, printed every run so it cannot be forgotten.
    SPOTIFY_ROWS="$(printf '%s' "$PROVIDERS_JSON" \
      | jq -r '.[] | select(.type=="music" and .domain=="spotify" and .enabled) | .instance_id')"
    if [[ -n "$SPOTIFY_ROWS" ]]; then
      info "note: a Spotify music provider is ENABLED ($(printf '%s' "$SPOTIFY_ROWS" | tr '\n' ' '))."
      echo "      Every album assertion below is filtered on the LOCAL provider instance id for"
      echo "      exactly this reason. An unfiltered query can match Spotify and report a pass"
      echo "      about an NFS export it never touched (D-30, T-02-16)."
    fi
  fi
fi
echo ""

# ---------------------------------------------------------------------------------------------
# 3. The three proof albums in Music Assistant (CONS-02)
# ---------------------------------------------------------------------------------------------
echo "💿 3. The three proof albums in Music Assistant (CONS-02, D-06/D-07/D-09/D-10)"
rule
MA_ALBUMS_FOUND=0
MA_OUT_OF_SCOPE=0
for row in "${PROOF_ALBUMS[@]}"; do
  IFS='|' read -r SHAPE APATH AALBUM AARTIST AMD5 ATRACKS ASCOPE <<< "$row"
  echo ""
  info "[$SHAPE] $AALBUM — $AARTIST"
  echo "      path:       $APATH"
  echo "      tracks:     $ATRACKS   scope: $ASCOPE"
  echo "      audio_md5:  $AMD5   (QUAL-01 join key, one representative track)"

  if [[ ! -d "$APATH" ]]; then
    ma_fail "CONS-02: source directory does not exist on disk — $APATH"
    continue
  fi
  pass "source directory exists on disk"

  if [[ "$MA_ROUTE" == "unavailable" ]]; then
    ma_fail "CONS-02: MA unreachable — '$AALBUM' is UNKNOWN, not green"
    continue
  fi
  if [[ -z "$MA_LOCAL_PROVIDER_INSTANCE" ]]; then
    ma_fail "CONS-02: cannot assert '$AALBUM' — no provider instance pinned (see section 2)"
    continue
  fi

  # Which provider instance can answer for THIS row. scope=library rows are always answered by the
  # pinned local provider and are always ASSERTED. A scope=temp-export row lives on the second,
  # temporary export and can only be answered by the temporary provider that serves it — which is
  # torn down by design (D-15), so in steady state there is nothing to assert against and the row
  # is REPORTED with its reason stated inline. Same idiom as section 4's out-of-scope warning.
  ROW_INSTANCE="$MA_LOCAL_PROVIDER_INSTANCE"
  if [[ "$ASCOPE" == "temp-export" ]]; then
    if [[ -z "$MA_TEMP_PROVIDER_INSTANCE" ]]; then
      warn "[$SHAPE] scope=temp-export and MA_TEMP_PROVIDER_INSTANCE is unset — REPORTED, not"
      echo "         asserted. This album is served by the SECOND, TEMPORARY export, which is"
      echo "         torn down by 'terraform apply' with music_temp_export_enabled=false (D-15)."
      echo "         It was asserted for real in plan 02-07 while that control was standing:"
      echo "         exact match on album AND albumartist, filtered to the temporary provider."
      echo "         Set MA_TEMP_PROVIDER_INSTANCE to re-assert it when the control is next up."
      MA_OUT_OF_SCOPE=$((MA_OUT_OF_SCOPE + 1))
      continue
    fi
    ROW_INSTANCE="$MA_TEMP_PROVIDER_INSTANCE"
  fi

  # provider_filter() injects {"provider": <instance id>}. See API SHAPE NOTE 4.
  #
  # ⚠ DO NOT PUT THE EXPECTED ALBUM NAME IN `search`. MEASURED 2026-09-01 (plan 02-07): MA 2.11's
  # `search` argument is NOT a substring match, and searching an album's OWN EXACT NAME can return
  # an EMPTY array. `search: "Mastermix Essential Hits - Pop 4 - 2005-2009"` returned [] while
  # `search: "Mastermix"` returned that very album, from the same provider, in the same second.
  # Short names ("Lifelines", "The Ultimate Hits") happen to work, which is what makes this so
  # dangerous — it looks fine until an album with punctuation and digits fails, and then it reports
  # `no exact match ... candidates were: <none>`, which is INDISTINGUISHABLE from the album being
  # genuinely absent. That is a false FAILURE on a gate whose whole job is to be trusted.
  #
  # So: filter on `provider` ONLY — the provenance filter is the load-bearing one and it stays —
  # and do the exact comparison locally in jq, where the semantics are ours and are byte-exact.
  ARGS="$(provider_filter "$(jq -nc --argjson l "$MA_LIBRARY_SCAN_LIMIT" '{limit:$l}')" "$ROW_INSTANCE")"
  RESULT="$(ma_api music/albums/library_items "$ARGS")"

  if ! printf '%s' "$RESULT" | jq -e 'type == "array"' >/dev/null 2>&1; then
    ma_fail "CONS-02: music/albums/library_items did not return an array for '$AALBUM'"
    continue
  fi

  # A list that came back exactly at the limit may be truncated, and a truncated list can hide the
  # album we are looking for. Say so loudly rather than reporting a clean miss.
  RETURNED="$(printf '%s' "$RESULT" | jq -r 'length')"
  if [[ "$RETURNED" -ge "$MA_LIBRARY_SCAN_LIMIT" ]]; then
    warn "provider-filtered album list came back at the limit ($MA_LIBRARY_SCAN_LIMIT) and may be"
    echo "         truncated — raise MA_LIBRARY_SCAN_LIMIT before trusting a miss below."
  fi

  # D-10: EXACT match on both name and artists[0].name. "An album appeared" is the files-are-
  # visible gate the roadmap explicitly rejects, and it would pass on a folder_name or
  # various_artists fallback entry.
  MATCH="$(printf '%s' "$RESULT" \
    | jq -c --arg n "$AALBUM" --arg a "$AARTIST" \
        '[.[] | select(.name == $n and ((.artists[0].name // "") == $a))] | .[0] // empty')"

  if [[ -n "$MATCH" ]]; then
    # Layer 1 confirmed a second time, client-side: the returned item's provider mappings must
    # actually include the pinned instance. Cheap, and it closes the gap if a future MA release
    # ever loosens what the `provider` argument means.
    MAPPED="$(printf '%s' "$MATCH" \
      | jq -r --arg i "$ROW_INSTANCE" \
          'if [.provider_mappings[]?.provider_instance] | index($i) then "yes" else "no" end')"
    if [[ "$MAPPED" == "yes" ]]; then
      pass "CONS-02: exact match in MA, provider-attributed to $ROW_INSTANCE"
      MA_ALBUMS_FOUND=$((MA_ALBUMS_FOUND + 1))
    else
      ma_fail "CONS-02: '$AALBUM' matched but is NOT mapped to $ROW_INSTANCE — "
      echo "         provider mappings were: $(printf '%s' "$MATCH" | jq -r '[.provider_mappings[]?.provider_instance] | join(",")')"
      echo "         This is the Spotify false pass caught in the act. Do not relax the filter."
    fi
  else
    # Near-miss candidates first (case-insensitive on the album name), because "same album, wrong
    # album artist" is the diagnostic that names WHICH fallback fired, and it would be lost in a
    # dump of every album the provider holds. Falls back to the first few if nothing is close.
    GOT="$(printf '%s' "$RESULT" | jq -r --arg n "$AALBUM" \
      '[.[] | select((.name|ascii_downcase) == ($n|ascii_downcase))
            | "\(.name) — \(.artists[0].name // "?")"] | join(" ; ")')"
    if [[ -z "$GOT" ]]; then
      GOT="$(printf '%s' "$RESULT" | jq -r '[limit(10; .[] | "\(.name) — \(.artists[0].name // "?")")] | join(" ; ")')"
      [[ -n "$GOT" ]] && GOT="$GOT   (first 10 of $RETURNED; no name matched even case-insensitively)"
    fi
    ma_fail "CONS-02: no exact match for album='$AALBUM' albumartist='$AARTIST'"
    echo "         provider-filtered candidates were: ${GOT:-<none>}"
  fi
done
echo ""

# ---------------------------------------------------------------------------------------------
# 4. The three proof albums in Jellyfin (CONS-04 groundwork, D-42)
# ---------------------------------------------------------------------------------------------
echo "🎬 4. The three proof albums in Jellyfin (CONS-04 groundwork, D-42)"
rule
echo "  Asserting the SAME pinned albums against the second consumer is what gives Phase 7's"
echo "  CONS-04 one script that answers the whole question, and gives this phase's blast-radius"
echo "  check a real assertion rather than 'Jellyfin looks fine'."
echo ""
JELLYFIN_ALBUMS_FOUND=0
JELLYFIN_OUT_OF_SCOPE=0
if [[ "$JELLYFIN_ROUTE" == "unavailable" ]]; then
  jellyfin_fail "CONS-04: Jellyfin unreachable — album visibility is UNKNOWN, not green"
else
  for row in "${PROOF_ALBUMS[@]}"; do
    IFS='|' read -r SHAPE APATH AALBUM AARTIST AMD5 ATRACKS ASCOPE <<< "$row"

    if [[ "$ASCOPE" != "library" ]]; then
      # Jellyfin bind-mounts /mnt/tank/media only. It has no mount reaching /mnt/tank/downloads,
      # so the D-08 substitute is STRUCTURALLY invisible to it. Failing here would be a permanent
      # red for a reason that is not a defect — and check-music-freeze.sh's MODE SCOPE records
      # what a permanent red does to a reader. Reported, not asserted.
      warn "[$SHAPE] '$AALBUM' is scope=$ASCOPE — out of Jellyfin's reach by design (it mounts"
      echo "      /mnt/tank/media only, never /mnt/tank/downloads). REPORTED, not asserted."
      JELLYFIN_OUT_OF_SCOPE=$((JELLYFIN_OUT_OF_SCOPE + 1))
      continue
    fi

    JF="$(jf_api /Items \
      --data-urlencode "IncludeItemTypes=MusicAlbum" \
      --data-urlencode "Recursive=true" \
      --data-urlencode "ParentId=${JELLYFIN_MUSIC_LIBRARY_ID}" \
      --data-urlencode "SearchTerm=${AALBUM}" \
      --data-urlencode "Fields=AlbumArtist,Path")"

    if ! printf '%s' "$JF" | jq -e 'has("Items")' >/dev/null 2>&1; then
      jellyfin_fail "CONS-04: Jellyfin returned no Items envelope for '$AALBUM' — UNKNOWN, not green"
      continue
    fi

    JF_MATCH="$(printf '%s' "$JF" \
      | jq -c --arg n "$AALBUM" --arg a "$AARTIST" \
          '[.Items[] | select(.Name == $n and ((.AlbumArtist // "") == $a))] | .[0] // empty')"
    if [[ -n "$JF_MATCH" ]]; then
      pass "[$SHAPE] CONS-04: '$AALBUM' — '$AARTIST' present in Jellyfin's Music library (exact match)"
      JELLYFIN_ALBUMS_FOUND=$((JELLYFIN_ALBUMS_FOUND + 1))
    else
      GOTJ="$(printf '%s' "$JF" | jq -r '[.Items[] | "\(.Name) — \(.AlbumArtist // "?")"] | join(" ; ")')"
      jellyfin_fail "CONS-04: no exact match in Jellyfin for album='$AALBUM' albumartist='$AARTIST'"
      echo "         candidates were: ${GOTJ:-<none>}"
    fi
  done
fi
echo ""

# ---------------------------------------------------------------------------------------------
# 5. Mount liveness (CONS-03)
# ---------------------------------------------------------------------------------------------
echo "🔌 5. Mount liveness (CONS-03)"
rule
echo "  The documented stale state is precisely 'entries exist, playback of any of them fails'."
echo "  An MA entry can be a survivor from before the mount broke, so presence alone proves"
echo "  nothing — provenance and count both have to be scoped to the local provider."
echo ""
MA_PROVIDER_ALBUM_COUNT="unknown"
if [[ "$MA_ROUTE" == "unavailable" ]]; then
  ma_fail "CONS-03: MA unreachable — mount liveness is UNKNOWN, not green"
elif [[ -z "$MA_LOCAL_PROVIDER_INSTANCE" ]]; then
  ma_fail "CONS-03: no provider instance pinned — a library count cannot be attributed (see section 2)"
else
  # DELIBERATELY NOT music/albums/count. That command has no provider parameter at all (verified
  # against /api-docs/commands.json AND empirically: it returned 87 with and without a provider
  # arg, while the provider-filtered list held 9). Using it here would report GREEN off Spotify's
  # catalogue with the NFS mount broken or absent. See API SHAPE NOTE 3.
  #
  # WR-03: the limit comes from MA_LIBRARY_SCAN_LIMIT, NOT from a repeated `2000` literal. Two
  # things were wrong with the literal. It silently diverged from section 3's query, so the remedy
  # section 3 PRINTS on a truncated result — "raise MA_LIBRARY_SCAN_LIMIT before trusting a miss" —
  # had no effect on this one. And the number below is published in the committed transcript that
  # 02-09 treats as the drift record, where a ceiling that looks like a measurement is exactly the
  # kind of number a later reader compares against.
  CNT_JSON="$(ma_api music/albums/library_items \
              "$(provider_filter "$(jq -nc --argjson l "$MA_LIBRARY_SCAN_LIMIT" '{limit:$l}')")")"
  if printf '%s' "$CNT_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
    MA_PROVIDER_ALBUM_COUNT="$(printf '%s' "$CNT_JSON" | jq -r 'length')"
    info "albums attributed to $MA_LOCAL_PROVIDER_INSTANCE: $MA_PROVIDER_ALBUM_COUNT"
    # A list that came back exactly at the limit is a FLOOR, not a count — same guard section 3
    # already carries. The `>= 3` gate below cannot produce a false pass from it today (70 albums
    # against a 2000 limit), but the number is transcribed into the drift record either way.
    if [[ "$MA_PROVIDER_ALBUM_COUNT" -ge "$MA_LIBRARY_SCAN_LIMIT" ]]; then
      warn "CONS-03: the album count came back AT the query limit ($MA_LIBRARY_SCAN_LIMIT) — this is a"
      echo "         FLOOR, not a count. Raise MA_LIBRARY_SCAN_LIMIT before recording it anywhere."
    fi
    if [[ "$MA_PROVIDER_ALBUM_COUNT" -ge 3 ]]; then
      pass "CONS-03: at least 3 albums are attributed to the local provider"
    else
      ma_fail "CONS-03: only $MA_PROVIDER_ALBUM_COUNT albums attributed to the local provider (want >= 3)."
      echo "         Zero here is the emergency-bind signature: /media/music empty, scan finds no files."
    fi
  else
    ma_fail "CONS-03: provider-filtered album query returned no array — UNKNOWN, not green"
  fi
fi

if [[ "$HA_ROUTE" == "skipped" ]]; then
  warn "CONS-03: 'ha mounts info' enrichment skipped (HA_ROUTE=$HA_ROUTE). The MA-side assertion"
  echo "      above is the load-bearing one and it ran. See the header for why the key is not here."
else
  HA_SSH=(ssh -n -o BatchMode=yes -o ConnectTimeout=5 -i "$HA_SSH_KEY" -p "${HA_SSH_PORT:-22}" \
          "${HA_SSH_USER:-root}@${HA_SSH_HOST}")
  MOUNT_STATE="$("${HA_SSH[@]}" "bash -lc 'ha mounts info --raw-json'" 2>/dev/null \
    | jq -r '.data.mounts[]? | select(.name=="music") | .state' || true)"
  if [[ -z "$MOUNT_STATE" ]]; then
    ma_fail "CONS-03: no 'music' mount reported by the Supervisor — UNKNOWN, not green"
  elif [[ "$MOUNT_STATE" == "active" ]]; then
    pass "CONS-03: Supervisor reports mount 'music' state=active"
  else
    ma_fail "CONS-03: Supervisor reports mount 'music' state='$MOUNT_STATE', want 'active'"
  fi
  # WR-02: THE DEGRADED-MOUNT SIGNATURE, measured rather than assumed.
  #
  # What used to be here was `mount | grep -qF 'emergency/music'`, and it could only ever pass,
  # for two independent reasons:
  #   1. On any ssh failure the pipeline produced nothing, grep found nothing, and the script
  #      printed a GREEN "no emergency bind for music". Unreachable and healthy were
  #      indistinguishable — the one thing this file's header refuses to accept anywhere else.
  #   2. The instrument was already known dead. Plan 02-08 measured that THIS Supervisor version
  #      does NOT bind-mount an /emergency/ path for a failed mount; it makes /media/music
  #      READ-ONLY IN PLACE. `mount | grep emergency/music` matched 0 and CAN NEVER MATCH here.
  #      02-09-SUMMARY.md retired it as a false-negative instrument and it was left wired up
  #      anyway, as an assertion whose only possible outcome was `pass`.
  #
  # The signature 02-08 actually established is the STATE OF /media/music itself: on a failed
  # mount it is present, a directory, root-owned, mode dr--r--r-- (0444) and EMPTY. So that is
  # what is asserted, and the ssh exit status is captured so an unreachable NUC is UNKNOWN.
  #
  # Note the direction: the load-bearing half is "0 entries is a failure". Mode and owner are
  # REPORTED alongside it, not asserted, because a future Supervisor could plausibly change them
  # while the emptiness — the thing that actually breaks the library — stayed the tell.
  NUC_MEDIA="$("${HA_SSH[@]}" \
    'if [ -d /media/music ]; then printf "%s|%s|%s\n" "$(stat -c %a /media/music 2>/dev/null)" "$(stat -c %U /media/music 2>/dev/null)" "$(ls -A /media/music 2>/dev/null | wc -l)"; else echo ABSENT; fi' \
    2>/dev/null)" && NUC_MEDIA_RC=0 || NUC_MEDIA_RC=$?

  if [[ $NUC_MEDIA_RC -ne 0 || -z "$NUC_MEDIA" ]]; then
    ma_fail "CONS-03: could not read /media/music on ${HA_SSH_HOST} (rc=$NUC_MEDIA_RC) — UNKNOWN, not green."
    echo "         This is NOT 'the mount is fine'. Check the NUC by hand before trusting this run."
  elif [[ "$NUC_MEDIA" == "ABSENT" ]]; then
    ma_fail "CONS-03: /media/music does not exist as a directory on ${HA_SSH_HOST} — the mount is not in place"
  else
    IFS='|' read -r NUC_MODE NUC_OWNER NUC_ENTRIES <<< "$NUC_MEDIA"
    if [[ ! "$NUC_ENTRIES" =~ ^[0-9]+$ ]]; then
      ma_fail "CONS-03: unparseable /media/music entry count '$NUC_ENTRIES' — UNKNOWN, not green"
    elif [[ "$NUC_ENTRIES" -eq 0 ]]; then
      ma_fail "CONS-03: /media/music is EMPTY (mode ${NUC_MODE:-?}, owner ${NUC_OWNER:-?}) — this is the"
      echo "         degraded-mount signature plan 02-08 measured: the Supervisor makes the path"
      echo "         read-only in place rather than binding an /emergency/ path, so an empty"
      echo "         /media/music IS the failed mount. MA then scans zero files."
    else
      pass "CONS-03: /media/music holds $NUC_ENTRIES entries (mode ${NUC_MODE:-?}, owner ${NUC_OWNER:-?}) — not the"
      echo "         empty read-only-in-place signature of a failed Supervisor mount (02-08)"
    fi
  fi
fi
echo ""

# ---------------------------------------------------------------------------------------------
# 6. Summary
#    KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT SILENTLY. Plan 02-09's fold-in anchors on it
#    with `sed -n '/^📊 6\. Summary/,$p'`, exactly as quick-health-check.sh:83 anchors on
#    check-music-freeze.sh's section 7.
# ---------------------------------------------------------------------------------------------
echo "📊 6. Summary"
rule
echo "  MA version (live):           $MA_VERSION_LIVE   (assertions proven at $MA_VERSION_PROVEN)"
echo "  export route:                $EXPORT_ROUTE"
echo "  ma route:                    $MA_ROUTE"
echo "  jellyfin route:              $JELLYFIN_ROUTE"
echo "  ha route:                    $HA_ROUTE   (skipped is expected on LXC 100 — see header)"
echo "  pinned provider instance:    ${MA_LOCAL_PROVIDER_INSTANCE:-<EMPTY — pinned by 02-06; re-pin from config/providers/get>}"
echo "  temp provider instance:      ${MA_TEMP_PROVIDER_INSTANCE:-<unset — scope=temp-export rows reported, not asserted (D-15)>}"
echo "  proof albums pinned:         ${#PROOF_ALBUMS[@]}   (target 3: single-artist, multi-disc, various-artists)"
echo "  albums matched in MA:        $MA_ALBUMS_FOUND   (target $(( ${#PROOF_ALBUMS[@]} - MA_OUT_OF_SCOPE )), exact name+albumartist, provider-attributed)"
echo "  MA out-of-scope:             $MA_OUT_OF_SCOPE   (scope=temp-export with no temp provider pinned — reported, not asserted)"
echo "  albums matched in Jellyfin:  $JELLYFIN_ALBUMS_FOUND   (target $(( ${#PROOF_ALBUMS[@]} - JELLYFIN_OUT_OF_SCOPE )), exact name+albumartist)"
echo "  jellyfin out-of-scope:       $JELLYFIN_OUT_OF_SCOPE   (scope!=library — reported, not asserted)"
echo "  MA albums, local provider:   $MA_PROVIDER_ALBUM_COUNT   (target >= 3)"
echo "  toolchain missing:           $TOOLS_MISSING"
echo "  export assertions failed:    $EXPORT_FAILURES"
echo "  MA assertions failed:        $MA_FAILURES"
echo "  Jellyfin assertions failed:  $JELLYFIN_FAILURES"
echo "  FAILURES total:              $FAILURES"
echo ""

if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "${YELLOW}--baseline: $FAILURES findings recorded, exiting 0. This is the before-state.${NC}"
  exit 0
fi

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}❌ $FAILURES failed checks${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Both music consumers see the pinned albums through the NFS export${NC}"
