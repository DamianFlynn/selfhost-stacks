# Phase 6: Tagger Configuration and Dry Run - Pattern Map

**Mapped:** 2026-09-20
**Files analysed:** 12 (6 new, 6 modified)
**Analogs found:** 11 / 12 (one file has *no* analog — see § *No Analog Found*)

> **Reading rule.** Every excerpt below is quoted from a real file in this repository, with its
> path and line range. Where a pattern the planner asked for does **not** exist, that is stated
> plainly rather than approximated. Nothing here is invented.

---

## File Classification

| New/Modified file | Role | Data flow | Closest analog | Match quality |
|---|---|---|---|---|
| `scripts/check-beets-config.sh` *(new)* | test / assertion script | request-response (`ssh` → `docker exec` → read-back) | `scripts/check-music-freeze.sh` | **exact** (role + flow) |
| `scripts/phase06-oracle.sh` *(new)* | driven phase script | batch + file-I/O (docker run → manifests → diff) | `scripts/spike03-wrtag-arms.sh` | **exact** |
| `scripts/phase06-incremental-control.sh` *(new)* | driven negative control | batch (two arms differing in one key) | `scripts/spike03-wrtag-arms.sh` (arms) + `check-music-freeze.sh` env-override controls | **exact** |
| `stacks/selfhosted/arrs/beets/flask.yaml` *(new)* | config (compose service) | request-response (web, Traefik-fronted) | `stacks/selfhosted/arrs/beets/beets.yaml` (exposure) + `.planning/phases/03-tagger-spike/03-spike-beets-flask.yaml` (rc6 internals) | **exact, split across two** |
| `06-SAMPLE.md` *(new)* | doc / pre-committed fixture | batch | `.planning/phases/03-tagger-spike/03-SAMPLE.md` | **exact** |
| `06-EXPECTED-TREE.txt` *(new)* | committed oracle fixture | batch | **none for "committed *before* the run"**; nearest is `.planning/phases/05-…/artifacts/*.tsv` | **partial — see § No Analog Found** |
| `stacks/selfhosted/arrs/beets/config.yaml` *(mod)* | config (vendored) | batch | itself — its own 47-line header is the house style | **in-place** |
| `stacks/selfhosted/arrs/beets/beets.yaml` *(mod)* | config (compose service) | request-response | itself | **in-place** |
| `scripts/check-music-freeze.sh` *(mod)* | test / assertion script | batch (host-resident) | itself, § 6b at :740-930 | **in-place** |
| `scripts/quick-health-check.sh` *(mod)* | test / assertion script | request-response (`ssh`-delegating) | itself, drift block at :1046-1159 | **in-place** |
| `scripts/check-music-consumers.sh` *(mod)* | test / assertion script | request-response (REST) | itself, `jf_api` at :432-440 | **in-place** |
| `stacks/selfhosted/arrs/beets.md` *(mod)* | doc (durable operational record) | — | itself | **in-place** |

---

## Shared Patterns

These are cross-cutting. **All three new scripts must carry all five.**

### S1 — The assertion-script skeleton

**Source:** `scripts/check-music-freeze.sh:114-189`, replicated verbatim at
`scripts/check-music-consumers.sh:296-333`.
**Apply to:** `check-beets-config.sh`, `phase06-oracle.sh`, `phase06-incremental-control.sh`.

```bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

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
      echo "usage: bash scripts/check-music-freeze.sh [--baseline] [--sidecars]" >&2
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
```

Note the `-h` handler: **the header comment block IS the help text**, printed by
`grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'`. Every script in `scripts/` does this, so
the header is written to be readable as `--help` output.

### S2 — Exit-code composition

**Source:** `scripts/check-music-freeze.sh:1059-1069` (identical shape at
`check-music-consumers.sh:1154-1165`).
**Apply to:** all three new scripts.

```bash
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "${YELLOW}--baseline: $FAILURES findings recorded, exiting 0. This is the before-state.${NC}"
  exit 0
fi

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}❌ $FAILURES failed checks${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Music freeze harness intact${NC}"
```

The convention is **stated in the header, not inherited** — `check-music-freeze.sh:35-42`:

```
# EXIT-CODE CONVENTION (established here deliberately; the estate has none):
#   default mode  - every red finding increments FAILURES and the script ends non-zero.
#   --baseline    - every finding is printed and the script always ends zero, so the
#                   before-state can be recorded while the harness does not yet exist.
#   Why this is stated rather than inherited: check-renovate.sh exits zero on every finding
#   except a missing renovate.json, and quick-health-check.sh never exits non-zero at all.
```

Sub-counters when a script has more than one subject (`check-music-consumers.sh:326-333`) —
this is what D-11's "named and classed" census wants:

```bash
EXPORT_FAILURES=0
MA_FAILURES=0
JELLYFIN_FAILURES=0
export_fail()   { fail "$*"; EXPORT_FAILURES=$((EXPORT_FAILURES + 1)); }
ma_fail()       { fail "$*"; MA_FAILURES=$((MA_FAILURES + 1)); }
jellyfin_fail() { fail "$*"; JELLYFIN_FAILURES=$((JELLYFIN_FAILURES + 1)); }
```

### S3 — Fail closed: "could not look" ≠ "nothing is wrong"

Three concrete mechanisms, all in use today. **Copy all three.**

**(a) UNKNOWN sentinels, initialised before anything runs** —
`scripts/check-music-freeze.sh:740-748`:

```bash
CENSUS_RAN=0
TAGGER_DEFS="UNKNOWN"
BEETS_DB_COUNT="UNKNOWN"
TAGGER_DB_COUNT="UNKNOWN"
RETIRED_PRESENT=0
RW_NONTAGGER="UNKNOWN"
```

…and at `:1042-1043` the reason, in the file itself:

```
# Each counter prints UNKNOWN rather than a number when its input was not observed. "0" on a
# census that could not look is the exact false green this file exists to refuse.
```

**(b) Read the instrument's exit status and branch on it** —
`scripts/check-music-freeze.sh:817-829`:

```bash
CENSUS_BLIND=0
FIND_RC=0
CANDIDATES="$(timeout "$CENSUS_FIND_TIMEOUT" find "$APPDATA_ROOT" -type f \
    \( -name 'library.db*' -o -name '*.blb*' ... \) \
    -print 2>/dev/null)" || FIND_RC=$?
if [[ $FIND_RC -eq 124 ]]; then
  fail "database census: UNKNOWN — census blind: find exceeded its ${CENSUS_FIND_TIMEOUT}s bound (rc=124). Nothing was counted."
  CENSUS_BLIND=1
elif [[ $FIND_RC -ne 0 ]] && [[ $FIND_RC -ne 1 ]]; then
  fail "database census: UNKNOWN — census blind: find exited $FIND_RC (only 0 and 1 are accepted; 1 = unreadable subpaths)."
  CENSUS_BLIND=1
fi
```

**(c) A positive control inside the measurement** — `check-music-freeze.sh:869-874`.
This is the single most transferable idea for `phase06-oracle.sh`:

```bash
    # Positive control. A census that cannot see a database it is KNOWN to contain has not
    # measured zero - it has failed to look, and those are different answers.
    if [[ $CONTROL_FOUND -eq 0 ]]; then
      fail "database census: UNKNOWN — census blind: the Jellyfin positive-control database ($JELLYFIN_CONTROL_DB, fenced by plan 01-06, MANIFEST § 'Jellyfin databases') was NOT in the result set. Zero beets databases would be unreadable from this run."
      CENSUS_BLIND=1
    fi
```

The oracle's analogue is named by `06-RESEARCH.md` Pitfall 1 and A7: assert that every
`beet move -p` line contains ` -> `, that the count equals the sampled file count, and **read the
`(N already in place)` line** — a silent 0-row output is the failure mode.

**(d) The "UNKNOWN, not green" phrasing** is a literal house string; grep for it.
`scripts/check-music-consumers.sh:1021-1024, 1056`:

```bash
if [[ "$MA_ROUTE" == "unavailable" ]]; then
  ma_fail "CONS-03: MA unreachable — mount liveness is UNKNOWN, not green"
...
  ma_fail "CONS-03: provider-filtered album query returned no array — UNKNOWN, not green"
```

**This is exactly the string D-36's MA gate must use.**

### S4 — Remote-command bounding, Linux-side

**Source:** `scripts/quick-health-check.sh:840-884`. The file carries the full two-part rule as a
comment; quote it into any new remote call.

```
#   1. `set -o pipefail` IN THE REMOTE COMMAND STRING. `timeout T docker ps -q | wc -l` signals
#      only the FIRST stage. `wc -l` then reads the empty stream, prints `0` and exits 0, and
#      without pipefail the remote pipeline's status IS `wc`'s — so ssh returned 0 and a killed
#      command was indistinguishable from a healthy answer. Driven on LXC 100:
#        timeout 2 sleep 20 | wc -l                    -> stdout 0, rc 0    (the bug)
#        set -o pipefail; timeout 2 sleep 20 | wc -l   -> stdout 0, rc 124  (the fix)
#
#   2. CAPTURE ssh's STATUS, AND BRANCH ON 124. pipefail alone is NOT enough, because `wc -l`
#      still PRINTS `0` on the killed path
#
# THE STATUS MUST BE READ WITH NO LOCAL PIPE IN FRONT OF IT. `VAR=$(ssh ... | tr -d ' ')` makes
# `$?` the TR's status, and `${PIPESTATUS[0]}` DOES NOT RESCUE IT
```

**The correct form** (`quick-health-check.sh:871-884`):

```bash
RUNNING=$(ssh -n $SSH_OPTS root@172.16.1.159 "set -o pipefail; timeout $REMOTE_TIMEOUT docker ps -q | wc -l")
RUNNING_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
RUNNING=$(printf '%s' "$RUNNING" | tr -d '[:space:]')
if [ "$RUNNING_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — 'docker ps' exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  Nothing was counted. This is NOT 'zero containers running'."
    EXIT_CODE=1
elif [ "$RUNNING_RC" -ne 0 ] || ! echo "$RUNNING" | grep -qE '^[0-9]+$'; then
    echo "⚠️  UNKNOWN — could not count running containers (ssh exit $RUNNING_RC, output '$RUNNING')."
    echo "  dockerd may be blocked. This is NOT 'zero containers running'."
    EXIT_CODE=1
else
    echo "Containers running: $RUNNING"
fi
```

`REMOTE_TIMEOUT` is declared once at `quick-health-check.sh:506`:
`REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-120}"`.

**The counter-example the planner asked for exists, and it is documented in the same file**
(`quick-health-check.sh:306-310`) — three sites where `grep -q` is the LAST pipeline stage:

```
#     change. With `set -o pipefail` and `grep -q` as the LAST stage, a bound expiry does NOT
#     surface: `timeout` exits 124, `grep -q` exits 1 on the empty stream, and pipefail returns
#     the RIGHTMOST non-zero status
#     Adding `pipefail` to these three would therefore have looked like a fix and fixed nothing.
```

…and the file states its own greppable invariant at `:494-497`:

```
#      the greppable rule: `grep -n 'timeout \$REMOTE_TIMEOUT.*|' ` over this file should return
#      only lines whose command string also contains `pipefail`, or lines whose final stage is a
```

**Run that grep after editing `quick-health-check.sh` for D-03/D-04.**

### S5 — Additive env overrides that can only make a check *redder*

**Source:** `scripts/check-music-freeze.sh:72-89` and `scripts/quick-health-check.sh:563-575`.
**Apply to:** every knob on the three new scripts, and to D-31's two overlays.

```
# ENV OVERRIDES for the drift block, all ${VAR:-default} so a grep can prove they exist. Every one
# of them can only make the block REDDER. There is deliberately no success-producing override:
#   DRIFT_APPDATA_ROOT   ... it exists ONLY to drive the could-not-look branch, so ANY non-default
#                        value forces EXIT_CODE=1 regardless of what the comparison finds.
#   DRIFT_EXPECT_*       ADDITIVE expectations. When set, the host hash must equal the repo hash
#                        AND the override. Setting one can only turn a green file red
```

and from `check-music-freeze.sh:85-89`:

```
#   SURVIVOR_DB and APPDATA_ROOT are deliberately PLAIN CONSTANTS, not overrides. An override on
#   either could produce a PASS ... and REVIEWS row 1 forbids any override that can manufacture
#   success. Changing either is a one-line edit here, in the commit that changes the policy.
```

**There is no sentinel that skips a check anywhere in this repo. Do not add one.**

---

## Pattern Assignments

### `scripts/check-beets-config.sh` (assertion script, request-response)

**Analog:** `scripts/check-music-freeze.sh` — same role, same flow, and it is the file this one
sits beside in the fold-in chain.

Beyond S1–S5, two things are specific:

**Route recording** (`check-music-freeze.sh:191-199`, generalised at
`check-music-consumers.sh:335-345`) — say *which* path answered, so "could not look" names itself:

```bash
# Delegate zfs to the Proxmox host when it is not resolvable locally. Read-only queries only.
ZFS_ROUTE="unavailable"
zfs_query() {
  if command -v zfs >/dev/null 2>&1; then
    zfs "$@"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${ZFS_HOST}" zfs "$@"
  fi
}
```

D-30's two arms (`beet config -d` vs the server-committed dump) are **two routes to two different
objects** — 06-RESEARCH.md § *D-30's two arms measure two different objects*. Record both route
names and print them in the summary, exactly as `EXPORT_ROUTE`/`MA_ROUTE`/`JELLYFIN_ROUTE` are
printed at `check-music-consumers.sh:1135-1138`.

**Toolchain preconditions as a section 0** (`check-music-consumers.sh:462-475`):

```bash
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
```

⚠ **No analog exists for gating a `docker exec` on container readiness.** `grep -rn "docker exec -u" scripts/`
returns **nothing** — no script in this repo currently `docker exec`s at all. The only recorded
statement of the gate is prose, in `stacks/selfhosted/arrs/beets/beets.yaml:54-60`:

```
      # What DID bite, recorded so nobody rediscovers it: `.State.Status` reports `running`
      # IMMEDIATELY, before s6 has remapped `abc` to PUID. A `docker exec` issued in that
      # window runs as the image-default uid and takes EACCES on this 0770 apps-owned file
      # ("configuration error: /config/config.yaml could not be read: [Errno 13] Permission
      # denied") — and in the same window `docker logs` is still EMPTY, so an EROFS grep
      # taken there reads a false "(none)". Gate on
      # `docker exec -u abc … test -r /config/config.yaml`, never on `running` alone.
```

⚠ **That gate does not transfer verbatim to rc6.** 06-RESEARCH.md § *The beets-flask container*
measured from source that `entrypoint_fix_permissions.sh` chowns only `/home/beetle /logs /repo`
and **does not touch `/config`**, so there is no `lsiown` race. The rc6 gate is the watchdog line
in the log (`06-RESEARCH.md:521-526`), which is also D-09 part 1's assertion target. The planner
must write a *new* gate, styled on the quoted prose, not copied from it.

---

### `scripts/phase06-oracle.sh` (driven phase script, batch + file-I/O)

**Analog:** `scripts/spike03-wrtag-arms.sh` — the only prior script that drives a containerised
dry run and then *proves* it wrote nothing. This is D-29's shape already implemented.

**Header contract** (`spike03-wrtag-arms.sh:1-30`) — note "where it runs", "usage", and the
one-script-N-invocations rule:

```bash
#!/usr/bin/env bash
# spike03-wrtag-arms.sh - Phase 3 criterion 3: run wrtag's path-format disqualifier at ONE image
#                         tag, on ONE album, and prove the dry run wrote nothing.
#
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull --ff-only`.
...
#   The three tags are three invocations of ONE script, not three scripts. That is the point:
#   if the arms differed in any other way the comparison would be measuring the difference
#   rather than the version.
```

**D-29 layer 2 — the before/after manifest** (`spike03-wrtag-arms.sh:633-647`). This *is* the
"checksum manifest, not a count" D-29 asks for, already written:

```bash
# --- Whole-subtree manifests, BEFORE -------------------------------------------------------
# %p %s %T@ catches path, size and mtime; the sha catches content. Together they catch
# additions and deletions too, because a vanished or new path changes both listings.
manifest() { # $1 = subtree  $2 = label  $3 = when
  LC_ALL=C find "$1" -type f -printf '%p\t%s\t%T@\n' \
    | LC_ALL=C sort > "$MANIFESTS/${ARM}.$2.$3.meta"
  LC_ALL=C find "$1" -type f -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 -r sha256sum > "$MANIFESTS/${ARM}.$2.$3.sha"
}

manifest "$SRC" src before
manifest "$LIB" lib before
```

Note `LC_ALL=C` on both the `find` ordering and the `sort` — the same locale discipline the
seeded draw uses (§ *Seeded draw*). **D-29 layer 3 adds two files to this set:** `library.db`
*and* `state.pickle` (06-RESEARCH.md Pitfall 4 — `-l` does not redirect `statefile:`).

**The stamp, taken outside the mounts** (`spike03-wrtag-arms.sh:649-653`):

```bash
# The stamp is created OUTSIDE both mounts, so taking it cannot itself perturb what it measures.
rm -f "$STAMP"
touch "$STAMP"
sleep 1   # 1s so a same-second write cannot slip under -newer's granularity
```

**Instrument 1, with its could-not-look preflight** (`spike03-wrtag-arms.sh:696-749`) — the
comment is the rationale the planner should reuse wholesale:

```bash
# CR-02. "COULD NOT LOOK" IS NOT "NOTHING CHANGED", AND IT IS NOT A PASS.
#
# This used to be `find ... 2>/dev/null || true` feeding a count. `2>/dev/null` discarded the
# error and `|| true` discarded the exit code, so EVERY failure mode of find ... produced an
# empty result, a zero count and a green tick claiming the dry run wrote nothing.
INSTR1_BLIND=""
for probe_dir in "$SRC" "$LIB"; do
  if [ ! -d "$probe_dir" ]; then
    INSTR1_BLIND="'$probe_dir' is not a directory (vanished, or a stale bind mount)"
    break
  fi
  if [ ! -r "$probe_dir" ] || [ ! -x "$probe_dir" ]; then
    INSTR1_BLIND="'$probe_dir' is not readable and searchable"
    break
  fi
done
if [ -z "$INSTR1_BLIND" ] && [ ! -f "$STAMP" ]; then
  INSTR1_BLIND="the stamp '$STAMP' is gone, so -newer has no reference"
fi
...
  NEWER_RC=0
  NEWER="$(find "$SRC" "$LIB" -newer "$STAMP" -type f 2>"$NEWER_ERR")" || NEWER_RC=$?
  if [ "$NEWER_RC" -ne 0 ] || [ -s "$NEWER_ERR" ]; then
    bad "instrument 1 COULD NOT LOOK (find rc=$NEWER_RC) - this is NOT a pass:"
```

**Instrument 2's three-outcome vocabulary** (`spike03-wrtag-arms.sh:755-773`) — 0 identical,
1 differs, ≥2 could-not-compare — is the exact shape D-27's zero-diff assertion needs:

```bash
# WR-13. The comparison itself is manifest_compare(), defined beside the fence near the top of
# this file so `--self-test` can drive all three of its outcomes without docker. This is only
# the reporting half: 0 identical, 1 differs, >=2 COULD NOT COMPARE.
diff_manifest() { # $1 = label  $2 = kind (meta|sha)
  local b="$MANIFESTS/${ARM}.$1.before.$2" a="$MANIFESTS/${ARM}.$1.after.$2" rc=0
  manifest_compare "$b" "$a" || rc=$?
  case "$rc" in
    0) ok  "instrument 2 (${1}.${2} manifest): identical before and after" ; return 0 ;;
    1) bad "instrument 2 (${1}.${2} manifest): CHANGED - the dry run was not dry:" ...
```

**A refusal to run against a dirty destination** (`spike03-wrtag-arms.sh:625-631`) — directly
applicable to the throwaway library:

```bash
LIB_ENTRIES="$(find "$LIB" -mindepth 1 | wc -l | tr -d ' ')"
if [ "$LIB_ENTRIES" -ne 0 ]; then
  bad "\$LIB is not empty at the start of this arm ($LIB_ENTRIES entries) - refusing to run,"
  bad "because a wrote-nothing assertion against a dirty destination proves nothing."
  exit 1
fi
```

**`--self-test`** (`spike03-wrtag-arms.sh:23-27`) is the repo's substitute for a unit-test
framework. Both `phase06-oracle.sh` and `phase06-incremental-control.sh` should carry one; it is
how the fail-closed branches are proven to fire without docker.

**Secondary analog — `scripts/phase05-junk-sweep.sh:1-52`** if the oracle needs an
operator-approval gate between "produce the expected tree" and "assert against it":

```bash
# THE KEY (D-13) - WHY THIS IS TWO SUBCOMMANDS AND NOT ONE SCRIPT WITH A PROMPT:
#   D-13 makes the approval gate the review itself, and the operator's standing verdict governs its
#   shape: "It's fine for a bot to drive us, but for me, as a human, no." Read and approve a file;
#   never sit at a prompt.
#
#   The approval therefore has to sit between two PROCESSES joined by a file on disk, not between
#   two branches of one process: a branch can be skipped by a flag, an env var or a future edit, a
#   missing file cannot. ... That is the whole design, and it is why this file has no interactive
#   prompt, no --yes flag and no --force.
```

This matters for D-26/D-27: the sample and the expected tree are **committed to git before the
run**, which is the same "gate is a file, not a branch" argument at a different layer.

---

### `scripts/phase06-incremental-control.sh` (driven negative control, batch)

**Analog:** `scripts/spike03-wrtag-arms.sh` again, for the arms structure — *one* script, two
invocations differing in **exactly one key**, plus `check-music-freeze.sh:72-89`'s "every
override can only make it redder" contract for the overlay paths.

The discriminating-control rationale is already written at `spike03-wrtag-arms.sh:36-46`:

```bash
#   So the disc class of an arm IS NOT A PROPERTY OF THE FOLDER. It is a property of whichever
#   release MusicBrainz happened to return ...
#   --mbid pins the release, so the ONLY difference between the three tags of a class is the
#   image, and the ONLY difference between the two classes is len(.Release.Media). That is the
#   variable criterion 3 is about. It does not flatter any version: the same MBID is given to
#   all three tags.
```

D-31's analogue: the **only** difference between overlay A and overlay B is
`incremental_skip_later`, and the two produce opposite observable outcomes. 06-RESEARCH.md
§ *P5a* gives the five steps and the exact `taghistory` inspection; 06-RESEARCH.md A3 flags the
one unverified assumption (whether a `beet -c` overlay escapes rc6's eyconf validation) —
**assert it, don't assume it**, per `spike03-beets-flask.yaml:246-254`'s precedent:

```
    # ... That is research assumption A4. If the container fails to start for want of redis, A4 is
    # FALSIFIED — `redis:7-alpine` is already on this host, so add it as a service and RECORD the
    # falsification rather than silently working around it.
```

---

### `stacks/selfhosted/arrs/beets/flask.yaml` (compose service, request-response)

**Analog (exposure shape):** `stacks/selfhosted/arrs/beets/beets.yaml` — its own corrected WR-02
block is the stated precedent for D-07.

**The WR-02 rationale, to be carried into the new file** (`beets.yaml:70-93`):

```yaml
    # WR-02: THE networks: KEY AND THE HOST PORT ARE THE SAME DEFECT, SEEN FROM TWO SIDES.
    # Until 2026-09-14 this key was COMMENTED OUT while `traefik.enable=true` and a full
    # `chain-authelia@file` router sat in the labels below. Compose therefore attached this
    # service to the implicit project `default` network, where the Traefik container cannot
    # reach it — so the Authelia protection was ILLUSORY, and the one path that did work,
    # `ports: - 8337:8337`, published the container LAN-WIDE WITH NO AUTHENTICATION.
    #
    # It was an outlier, not a convention: of the 16 files under stacks/selfhosted/arrs/, this
    # was the ONLY one with traefik.enable=true and no network. Every sibling declares one.
    networks:
      - t3_proxy
    # THE HOST PORT IS DELIBERATELY GONE. Reach beets through Traefik + Authelia at
    # beets.deercrest.info, which is what the labels below have always claimed. If a host port is
    # ever genuinely needed for local debugging, bind it to LOOPBACK — `- "127.0.0.1:8337:8337"` —
    # never to all interfaces. Do not restore the bare form.
    # ports:
    #   - 8337:8337
```

**The labels block, verbatim** (`beets.yaml:94-105`) — D-07 moves these to the flask service and
**deletes them from `beets.yaml`**:

```yaml
    labels:
      - traefik.enable=true

      - traefik.http.routers.beets.entrypoints=web,websecure
      - traefik.http.routers.beets.rule=Host(`beets.deercrest.info`)
      - traefik.http.routers.beets.middlewares=chain-authelia@file
      - traefik.http.routers.beets.tls=true
      - traefik.http.routers.beets.tls.certresolver=dns-cloudflare
      - traefik.http.routers.beets.priority=99
      - traefik.http.routers.beets.service=beets-svc

      - traefik.http.services.beets-svc.loadbalancer.server.port=8337
```

⚠ The service port for rc6 is **5001**, not 8337 (06-RESEARCH.md § *image internals*: the image
declares **no** `ExposedPorts`; the only authority is `launch_server.py`).

**The network declaration, in the service's own file** (`beets.yaml:107-115`) — exactly what the
planner asked for, including why:

```yaml
# WR-02: t3_proxy declared here as well as in ../compose.yaml, because this file has to stand on
# its own. It is commented out of that file's include list (../compose.yaml:39), so when it is
# brought up directly on its `manual` profile there is no parent to inherit the network from.
# Same shape as blockbusterr.yaml — which IS included, and declares t3_proxy itself anyway, so an
# identical repeated external declaration is proven to merge cleanly rather than conflict.
networks:
  t3_proxy:
    external: true
```

`stacks/selfhosted/arrs/compose.yaml:22-39` confirms the include list, with
`#  - beets/beets.yaml` as its last (commented) entry — the planner must decide whether
`flask.yaml` joins that list or stays out of it.

**The s6/`lsiown` boot-race gate** lives at `beets.yaml:45-60` and is quoted in full under
`check-beets-config.sh` above. **Re-read the ⚠ there: it is an LSIO-image fact and does NOT apply
to the rc6 image.** Reproducing it in `flask.yaml` would record a hazard that image does not have.

**Analog (rc6 internals):** `.planning/phases/03-tagger-spike/03-spike-beets-flask.yaml` — 254
lines, the measured deployment shape, banner-marked `THROWAWAY — DO NOT DEPLOY`. Reuse from it:

- `security_opt: [no-new-privileges:true]`, `image: metasauce/beets-flask:v2.0.0-rc6` with the
  **verified digest recorded in a comment** (`:111-113`).
- The env block and *why each value is a literal* (`:146-163`) — including the `.env` trap at
  `:66-74`: compose resolves `.env` from the compose file's own directory, so `$TZ`/`$PUID`
  expand to empty with only a stderr warning when there is no sibling `.env`. **The real
  `stacks/selfhosted/arrs/` files DO have a gitignored sibling `.env`** and use `$TZ`/`$PUID`/`$PGID`
  (`beets.yaml:12-15`) — so `flask.yaml`, living under `stacks/`, follows `beets.yaml`, not the
  spike.
- `USER_ID: 568` / `GROUP_ID: 568` and why (`:149-155`); rc6 honours `PUID`/`PGID` too
  (06-RESEARCH.md § *image internals*).
- `REDIS_URL` deliberately unset, with the falsification instruction (`:160-163`, `:246-254`).
- The `env_file` / `docker compose config` credential note (`:40-52`) — **not needed here**, since
  this phase introduces no credential (06-RESEARCH.md § *Security Domain*, V6). Keep the note as a
  guard if an `env_file` is ever added: render with `--no-env-resolution`.
- The **"DELETED rather than commented out"** block (`:212-254`) — the wrtag.yaml:39-58 pattern,
  where absent things are documented *in place* with the reason. D-05 and D-12 both want this
  register.

**The register D-12's header note must match** — `beets.yaml:63-69`, quoted in CONTEXT § Specific
Ideas as the model:

```yaml
    # NOTE (2026-08-18): :ro is deliberate (D-20). Nobody holds read-write on
    # /mnt/tank/media/Music during Phases 1-3, including this container. Phase 3 chooses
    # the one tagger and Phase 6 grants it rw — that is the first time anything holds it
    # again. Until then beets can read the library for match context but cannot write it.
    # If you flip this back to :rw to "just run one import", you have re-created the exact
    # failure this project exists to prevent: a fourth half-built tagging path.
    - /mnt/tank/media:/media:ro  # Existing library — READ-ONLY until Phase 6 (see above)
```

**D-05 corrects the third sentence of that comment** ("Phase 6 grants it rw" → Phase 7's first
act). The correction must be made **in place, dated, with the superseded reading kept visible** —
that is this repo's standing style for a retracted claim; see `beets.md:70-77` ("Stated as
retractions, not quiet replacements") and `quick-health-check.sh:920-923` ("the old target URL is
paraphrased rather than written out, per this file's convention for a withdrawn claim, so a
mechanical grep for it keeps returning zero").

---

### `stacks/selfhosted/arrs/beets/config.yaml` (vendored config, batch)

**Analog:** itself. The 47-line header at `:1-47` is the template for every addition D-10/D-18
makes. Four moves it establishes:

1. **A "Consumed by" block naming container, state and trigger** (`:3-9`).
2. **The vendored/authoritative split, named** (`:11-18`):

```yaml
# VENDORED 2026-09-11 (plan 04-08, TAGR-05 / D-27). The repo copy is for review and history;
# the compose mount in ./beets.yaml points at the appdata copy
# /mnt/fast/appdata/arrs/beets/config/config.yaml, which is AUTHORITATIVE at runtime.
# Those two copies are compared byte-for-byte by the vendored-file drift block in
# scripts/quick-health-check.sh
```

3. **A credential screen, re-run before every commit** (`:41-47`):

```yaml
# Credential screen: NO credential of any kind is present. There is no Discogs user token here and
# there must never be one — Phase 4 D-24 dismissed that credential ...
# Screened for a Discogs user credential, for any field named after a credential class, for URLs
# carrying embedded credentials, for e-mail addresses and for high-entropy strings. All checks
# returned clean, so nothing is redacted and there is no placeholder to substitute. THIS
# REPOSITORY IS PUBLIC. Re-screen before committing any future change to this file.
```

4. **Every key carries *why*, and "an absent key is the on switch"** (`:66-96`) — the exact
   argument D-15 ("override, do not delete") and 06-RESEARCH.md Pitfall 3 both rest on:

```yaml
# So an ABSENT key is not an off switch — it is the on switch, waiting for someone to add the
# plugin name to the `plugins:` line above. None of these three plugins is enabled here today;
# the keys are set anyway, precisely so that enabling a plugin later cannot silently re-arm
# automatic tag destruction.

scrub:
    auto: no   # scrub STRIPS all existing tags from a file on import. Off: this pipeline
               # ingests content whose existing tags are the only metadata it has.
```

⚠ **The header's own scope statement must be rewritten, not silently outgrown** (`:36-39`):

```yaml
# EVERYTHING ELSE ABOUT THIS TAGGER'S CONFIGURATION BELONGS TO PHASE 6. This file is the minimal
# slice TAGR-05 forces ... Do not add path formats, match thresholds or import behaviour
# here; Phase 6 owns them and a half-configured survivor is this project's known failure mode.
```

Phase 6 *is* that phase. The line `plugins: musicbrainz` at `:60` becomes a YAML list (D-10),
and `library: /config/library.db` at `:64` is the precedent for pinning `directory:`,
`statefile:`, `import.duplicate_action:` and `match.medium_rec_thresh:` explicitly
(06-RESEARCH.md § *D-30's two arms*).

⚠ **Changing this file changes a hash the health check asserts.** See the next section.

---

### `scripts/quick-health-check.sh` — the vendored-file drift block (D-03)

**Analog:** itself, `:1046-1159`. The block's **scope assumption is exactly one repo file to
exactly one appdata file, three times.** Quoted in full because D-03 changes the cardinality:

```bash
# Vendored-file drift (D-13). THREE files in this repo are vendored copies of files that a
# container reads at runtime from /mnt/fast/appdata, and for all three the APPDATA COPY IS
# AUTHORITATIVE while the repo copy exists for review, history and exactly this comparison:
#
#   stacks/selfhosted/arrs/sabnzbd/audio.bash          -> .../arrs/sabnzbd/config/scripts/audio.bash
#   stacks/selfhosted/arrs/sabnzbd/beets-config.yaml   -> .../arrs/sabnzbd/config/scripts/beets-config.yaml
#   stacks/selfhosted/arrs/beets/config.yaml           -> .../arrs/beets/config/config.yaml
#
# The comparison runs HOST-SIDE, both halves: `git show HEAD:<path>` inside /mnt/fast/stacks and
# sha256sum of the appdata copy. So the workstation's own working tree is irrelevant — a dirty or
# stale checkout here cannot produce a false green or a false red
#
# FAIL-CLOSED, and never info(). "Could not look" and "the files match" are different answers and
# must not share a verdict ... The branch ORDER is the house S1 order and matters: empty output
# first ..., deferring to 124 so a killed command is not reported as an unreachable host; then 124;
# then any other non-zero; and only then is anything asserted.
```

```bash
    DRIFT_CMD="set -o pipefail; cd /mnt/fast/stacks || exit 3
_drift_pair() {
  r=\$(timeout $REMOTE_TIMEOUT git show \"HEAD:\$2\" | sha256sum | cut -d' ' -f1) || exit 4
  h=\$(timeout $REMOTE_TIMEOUT sha256sum \"\$3\" | cut -d' ' -f1) || exit 5
  echo \"\$1 repo=\$r host=\$h\"
}
_drift_pair audio.bash stacks/selfhosted/arrs/sabnzbd/audio.bash \"$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/audio.bash\"
_drift_pair sabnzbd-beets-config.yaml stacks/selfhosted/arrs/sabnzbd/beets-config.yaml \"$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/beets-config.yaml\"
_drift_pair survivor-config.yaml stacks/selfhosted/arrs/beets/config.yaml \"$DRIFT_APPDATA_ROOT/arrs/beets/config/config.yaml\""
    DRIFT_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "$DRIFT_CMD")
    DRIFT_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
```

**Precisely what the block's scope assumes** — three load-bearing facts the planner must not break:

1. **The count is hard-coded and asserted** (`:1122-1126`). A short answer is *could not look*:

```bash
        DRIFT_LINES=$(printf '%s\n' "$DRIFT_OUT" | grep -c 'repo=')
        if [ "$DRIFT_LINES" -ne 3 ]; then
            echo "  ⚠️  UNKNOWN — expected 3 comparison lines, got $DRIFT_LINES. Nothing is asserted."
            echo "  A short answer is 'could not look', NOT 'the files that did report are fine'."
            EXIT_CODE=1
        fi
```

2. **The label set is closed** (`:1133-1143`) — an unrecognised label is an UNKNOWN, not a skip.
   A new label needs a `case` arm **and** a `DRIFT_EXPECT_*` variable at `:572-575`.
3. **The green line names all three files** (`:1155`):
   `echo "  ✅ vendored files match (3): audio.bash, sabnzbd beets-config.yaml, survivor config.yaml"`

⚠ **D-03's real shape is not a fourth `_drift_pair`.** D-03 puts *two containers* behind *one*
vendored file — the repo→appdata comparison is unchanged; what is new is asserting that **both**
containers mount that same path. The instrument for the second half is `docker inspect .Mounts`,
not a hash. The file itself already argues against reflexively adding a pair (`:1183`: *"first
suggested fix was a fourth `_drift_pair` over a vendored copy. It is deliberately NOT …"*) — read
`:1161-1260` before choosing.

⚠ The block is followed at `:1161+` by the `extended.conf` block, whose own override contract
(`:577-589`) is the template for any new knob. D-04's throwaway-`-l` assertion lands between them.

---

### `scripts/check-music-freeze.sh` — the tagger census (D-11)

**Analog:** itself, `:786-802`. The exact lines D-11 revises:

```bash
  GIT_LS=""
  GIT_RC=0
  GIT_LS="$(git ls-files stacks 2>/dev/null)" || GIT_RC=$?
  if [[ $GIT_RC -ne 0 ]] || [[ -z "$GIT_LS" ]]; then
    fail "tagger definition census: UNKNOWN — 'git ls-files stacks' exited $GIT_RC or listed nothing. Nothing was counted; this is NOT 'one definition'."
  else
    DEF_FILES="$(printf '%s\n' "$GIT_LS" \
      | { xargs -r -d '\n' grep -lE "^[[:space:]]*image:[[:space:]]*[\"']?([a-z0-9._-]+/)*(beets-flask|beets|wrtag|soulbeet|picard)([:@\"'[:space:]]|\$)" 2>/dev/null || true; } \
      | sort)"
    TAGGER_DEFS="$(count_lines "$DEF_FILES")"
    if [[ "$TAGGER_DEFS" == "1" ]] && [[ "$DEF_FILES" == "stacks/selfhosted/arrs/beets/beets.yaml" ]]; then
      pass "tagger definitions: expected=1 at stacks/selfhosted/arrs/beets/beets.yaml — found exactly that"
    else
      fail "tagger definitions: expected=1 at stacks/selfhosted/arrs/beets/beets.yaml — found $TAGGER_DEFS:"
      printf '%s\n' "$DEF_FILES" | sed 's/^/         /'
    fi
  fi
```

Three constraints on the revision, all stated in the file at `:760-785`:

- The pattern **already matches `beets-flask`, on purpose**: *"Phase 5 introduces
  metasauce/beets-flask; when it lands, THIS ASSERTION MUST BE REVISED in the same commit — it is
  listed in the pattern below on purpose so a Phase 5 definition goes red here rather than
  arriving unnoticed."* **Do not narrow the pattern to make the count fit.**
- `beets-flask` is listed before `beets` deliberately (`:781-783`).
- **The pattern is quoted verbatim in `stacks/selfhosted/arrs/beets.md:1255`** (criterion 1's
  evidence row) — *"the two must not drift"*. Both files change in one commit.

**The "name the exception on its own line" shape D-11 asks for** already exists two lines below
the summary block, at `:1049-1052`:

```bash
  echo "  rw on Music, non-tagger:     $RW_NONTAGGER   (target 0, excluding the D-21 consumer exception)"
  echo "  rw on Music, tagger-capable: $RW_TAGGER   (target 0 — Phase 1 D-20, any container state)"
  echo "  rw on Music, Jellyfin D-21:  $RW_JELLYFIN   (documented consumer exception, printed separately)"
```

⚠ **Renaming a summary label breaks `quick-health-check.sh` silently.** `:1035-1040`:

```bash
# CROSS-FILE CONTRACT: scripts/quick-health-check.sh selects on these label tokens with `grep -E`
# in its freeze fold-in. The tokens it greps for are `tagger definitions`, `beets databases`,
# `tagger databases`, `retired paths present`, `rw on Music` and `tagger-capable` ...
# Renaming a label here breaks a consumer in a different file and breaks it SILENTLY. Change both
# files in the same commit.
```

---

### `scripts/check-music-consumers.sh` — API key handling (D-22, D-34)

**Analog:** itself. **This is the pattern the planner asked to be quoted verbatim.** The repo is
public and LXC 100 has a world-readable process table, so both halves are load-bearing.

**The mode-600 gate — a gate, not a remark** (`:483-527`):

```bash
# WR-13: THE PERMISSION ASSERTION IS A GATE, NOT A REMARK. The previous version recorded the
# `fail` and then sourced the file anyway. `.` executes arbitrary shell, not just assignments —
# so the exact state the assertion detects (the file is writable by, or owned by, somebody other
# than root) was the state in which this script handed that somebody root code execution on
# LXC 100, on every quick-health-check run. Refuse instead.
#
# `set -a` is also gone, deliberately. It marked EVERY key in both files for export, putting the
# MA password and the Jellyfin API key into the environment of every child this script spawns ...
# i.e. into /proc/<pid>/environ for a large process tree.
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
```

**`jf_api` — the key never enters argv** (`:432-440`):

```bash
jf_api() {
  # $1 = path, remaining args are passed to curl (use --data-urlencode for query params).
  # CR-01: same `-H @file` treatment as ma_api — the API key reaches curl through a process
  # substitution, never through argv. See ma_api's comment for the mechanism.
  local path="$1"; shift
  curl -s --max-time 20 -G \
    -H @<(printf 'Authorization: MediaBrowser Token="%s"\n' "$JELLYFIN_API_KEY") \
    "http://${JELLYFIN_ADDR}${path}" "$@" || true
}
```

**`ma_api` — the same mechanism, plus the reasoning** (`:397-412`):

```bash
ma_api() {
  # CR-01: the bearer JWT is NOT passed as `-H "Authorization: Bearer $MA_TOKEN"`. curl's
  # `-H @file` form (>= 7.55.0; LXC 100 runs 8.14.1) reads the header text FROM A FILE, so argv
  # carries only the path. The file is a process substitution, so the token never touches disk
  # either, and `printf` is a bash builtin so it has no argv of its own.
  local cmd="$1" args="${2:-}" body
  [[ -z "$args" ]] && args='{}'
  body="$(jq -nc --arg c "$cmd" --argjson a "$args" '{command:$c,args:$a}')"
  printf '%s' "$body" | curl -s --max-time 30 -X POST "${MA_URL}/api" \
    -H 'Content-Type: application/json' \
    -H @<(printf 'Authorization: Bearer %s\n' "$MA_TOKEN") --data-binary @- || true
}
```

**`ma_login` — the corrected argv defect, kept as a warning** (`:371-395`):

```bash
  # CREDENTIALS AND argv (CR-01, fixed 2026-09-01). The previous version of this comment claimed
  # the password "never entered argv" while the line beneath it passed the plaintext password to
  # `jq --arg p "$MA_PASSWORD"`, i.e. as jq's argv[4]. /proc/<pid>/cmdline is world-readable on
  # LXC 100 (no hidepid) ... A comment asserting a control that is not implemented is worse than
  # no comment: it stops the next reader looking.
  body="$(MA_USERNAME="$MA_USERNAME" MA_PASSWORD="$MA_PASSWORD" jq -nc \
          '{command:"auth/login",args:{username:$ENV.MA_USERNAME,password:$ENV.MA_PASSWORD}}')"
```

**`set -u` defaulting, before any code path reads a variable** (`:352-369`):

```bash
# WR-01: EVERY variable that arrives from an external file or from the caller's environment is
# defaulted HERE, before any code path can read it. This script runs under `set -u` (:128), and
# `set -u` turns "the credential file was renamed upstream" into `unbound variable` — the run dies
# mid-section, sections 5 and 6 never execute, and the caller gets a failed exit code with an
# EMPTY summary block. That is strictly worse than a failed assertion.
#
# Defaulting is only half the fix. A variable that is empty because the file was unreadable must
# still turn into a RED assertion, never a skipped one
MA_USERNAME="${MA_USERNAME:-}"
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"
```

**Where the D-22 artist-entity check goes** — section 4's loop, `:967-1008`. The call shape to
extend:

```bash
if [[ "$JELLYFIN_ROUTE" == "unavailable" ]]; then
  jellyfin_fail "CONS-04: Jellyfin unreachable — album visibility is UNKNOWN, not green"
else
  for row in "${PROOF_ALBUMS[@]}"; do
    ...
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
```

**The pinned-row table idiom** (`:245-294`) is where D-22's candidate tracks belong: one
pipe-delimited row per proof subject, each with a comment stating *why that row and not another*,
and a `scope` field that routes an out-of-scope row to **reported, not asserted**
(`:973-982`) — which is the shape D-36's MA gate needs:

```bash
    if [[ "$ASCOPE" != "library" ]]; then
      # ... Failing here would be a permanent red for a reason that is not a defect — and
      # check-music-freeze.sh's MODE SCOPE records what a permanent red does to a reader.
      # Reported, not asserted.
      warn "[$SHAPE] '$AALBUM' is scope=$ASCOPE — out of Jellyfin's reach by design ..."
      JELLYFIN_OUT_OF_SCOPE=$((JELLYFIN_OUT_OF_SCOPE + 1))
      continue
    fi
```

⚠ **D-36 is the opposite case and must not reuse `warn`.** MA being down is *could not look*, and
06-VALIDATION.md requires CONF-04 to stay `OPEN`. The correct precedent is `:1021-1022`'s
`ma_fail "... UNKNOWN, not green"`, not the `warn` above.

**D-34's flag assertion** has no existing analog — nothing in this repo reads
`GET /Library/VirtualFolders`. The nearest is the pinned library-id constant at `:245`
(`JELLYFIN_MUSIC_LIBRARY_ID`, `7e64e319657a9516ec78490da03edccb`, re-measured in 06-RESEARCH.md).
The endpoint shape is in 06-RESEARCH.md § *Jellyfin's Music library options*; write it with
`jf_api` and the S3(a) UNKNOWN sentinel.

---

### `06-SAMPLE.md` — the seeded draw (D-26)

**Analog:** `.planning/phases/03-tagger-spike/03-SAMPLE.md` — **exact**, and the mechanism is
simpler than "seeded" suggests. **There is no RNG and no `shuf`.** Determinism comes from a stated
sort key plus `head -n N`, run twice and diffed.

`03-SAMPLE.md:190-220`:

```markdown
## The draw

**Sort key, stated so the 24 folders can be re-derived without re-running anything:** within each
stratum, the eligible folders are sorted by their **full folder path**, byte-ordered with
**`LC_ALL=C`** (locale-independent - a locale-dependent collation is not reproducible across
hosts), and the first N are taken. The documented tie-breaker, unused here because no two full
paths collided, is the `audio_md5` of the folder's first `LC_ALL=C`-sorted file.

Verbatim, against the survey NDJSON:
```

```bash
O=/mnt/fast/safety/music-pre-project/spike-03-variant-survey.ndjson
NZB=/mnt/tank/downloads/complete/nzb

elig() {
  jq -sr --arg nzb "$NZB" '
    .[] | select(.record_type=="folder") | select(.scan_bearing | not)
    | [ ($nzb + "/" + .tree + "/" + .folder), .tree, .stratum ] | @tsv' "$O"
}

for pair in V1:6 V2:7 V3:2 V5:4 V6:1; do
  s="${pair%%:*}"; n="${pair##*:}"
  elig | awk -F'\t' -v s="$s" '$2=="dj-mixes" && $3==s {print}' \
       | LC_ALL=C sort -t$'\t' -k1,1 | head -n "$n"
done
```

> Run twice and `diff`'d: **identical, zero lines of difference**, 24 rows both times.

Four further properties of that document the planner should reproduce:

1. **The population is declared before any evidence is collected** (`:13-18`), with the commit
   hash of the decision that widened it. D-26's "must include the shapes that hurt" is a
   *stratification*, and each stratum's target must be stated up front.
2. **Reallocation is explained when a stratum cannot fill its target** (`:222-237`) — a table
   with a *"Reason for the difference"* column.
3. **Every drawn row is tabulated with the attributes it was drawn on** (`:241-266`).
4. **Retractions are stated, not quietly replaced** (`:70-96`): *"Stated as retractions, not quiet
   replacements, in the `beets.md:55-58` house style. Each was measured by two independent
   instruments before being written down."*

Also inherit `03-SAMPLE.md:29-32`'s note on **where machine-readable output lives** — the survey
NDJSON stayed at the fence, not in the repo. That is directly relevant to `06-EXPECTED-TREE.txt`;
see below.

---

### `scripts/normalise-dj-tags.py` — dry-run-by-default + NDJSON (D-18, D-27)

**Analog:** itself. It is the only Python tool in `scripts/` with this shape and it binds
regardless of engine (CONTEXT § Reusable Assets).

**The inverted flag convention, stated as a deliberate deviation** (`:167-169` and `:1025-1035`):

```
#    default. Here it is the other way round: `--dry-run` IS THE DEFAULT and writing requires an
#    explicit `--apply`. An irreversible in-place tag write over reflinked copies earns a stricter
```

```python
    mode = p.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="THE DEFAULT: report every proposed change and write nothing",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="WRITE TAGS IN PLACE. Requires --snapshot-proof; not the default",
    )
```

**The write gate runs before any byte moves, and is checked twice on purpose** (`:907-915`):

```python
def write_tags(
    handle, path: str, changes: dict[str, str], *, fence_root: str = SCRATCH_ROOT
) -> None:
    """Write ONLY the fields in WRITABLE_FIELDS, and ONLY inside the scratch root.

    Both are asserted, not assumed, and the fence is FIRST - before any byte can move. It is
    also checked in the per-file loop so the dry run reports it, but this call is the one that
    cannot be bypassed by a future caller (CR-04).
    """
```

…and the loop-side half (`:1316-1339`), which is the rule D-18's reporter must follow —
**a refusal is a record, never a skip**:

```python
            # CR-04: the D-07 fence, on the RESOLVED path, in BOTH modes. Runs here as well as
            # inside write_tags() so the DRY RUN reports the refusal - the dry run is the D-08
            # review artefact, and a preview that silently omits a file the apply would refuse
            # is not a preview. A refusal is a .failed record, never a skip and never an
            # "unchanged".
            try:
                assert_inside_scratch(path, fence_root=fence_root)
            except Exception as exc:  # noqa: BLE001 - routed to the ledger, never swallowed
                counts["failed"] += 1
                log.error("fence refused %s: %s", path, exc)
                if failed_fh:
                    failed_fh.write(
                        json.dumps({"path": path, "stage": "fence",
                                    "exception": type(exc).__name__,
                                    "detail": str(exc)[:400]}) + "\n")
                    failed_fh.flush()
                continue
```

**The NDJSON emit — one record per (file, field) change** (`:1177-1212`). This is the structure
D-27's "set of changed triples equals the set the tool proposed" assertion joins on:

```python
    """One NDJSON record per (file, field) change: the shape --out has always written.

    Factored out of main() so --self-test checks the record the real run emits, not a copy of it.
    ...
    D-10: a record whose `new` already equals its `old` carries `noop: true`. Rule 4 proposes the
    canonical album for EVERY file in a volume folder - so the dry run shows the whole collection
    was covered rather than only its wrong half
    """
    record = {
        "mode": mode,
        "folder": folder,
        "path": path,
        "field": field,
        "rule": rule,
        "old": old,
        "new": new,
        "written": written,
        "artist_policy": artist_policy,
    }
    if old == new:
        record["noop"] = True
```

Three side-files, opened together (`:1300-1303`), with the contract stated at `:55-56, 90`:

```python
    out_fh = failed_fh = None
    if args.out:
        out_fh = open(args.out, "w", encoding="utf-8")
        failed_fh = open(args.out + ".failed", "w", encoding="utf-8")
```

> `--out FILE` → `FILE`, `FILE.failed`, `FILE.summary.json`. Flushed per record so an
> interrupted run still yields a usable ledger (`:216`).

**The raw frame-set backstop D-18's `EnergyLevel` branch needs** (`:866-883`) —
06-RESEARCH.md § P1 is explicit that `TXXX:EnergyLevel` is **not** a beets field, so a beets
query for it returns nothing and reads as clean. The correct instrument already exists:

```python
def assert_frame_set_unchanged(path, before, changes: dict[str, str], *, offset: int = 0) -> None:
    """After the write, the on-disk ID3v2 frame-ID multiset must be what it was, plus the two.

    `offset` is where the ID3 tag starts: 0 for MP3, the `id3 ` chunk for a WAV. Without it this
    read `RIFF` at offset 0 for every WAV and returned silently, a vacuous pass.
    ...
    "Assert rather than report" - README § Health Checks. Frame ENCODINGS and SIZES are allowed to
    move ...; frame IDENTITY is not.
    """
```

**The mode banner** (`:1275-1298`) — colour-coded, printed before anything happens, naming mode,
fence root, writable fields and the snapshot proof. D-27's report should open the same way.

---

### `stacks/selfhosted/arrs/beets.md` (durable operational record)

**Analog:** itself. Four established devices:

1. **Phase-stamped `##` sections** (`## Phase 1 safety harness (2026-08-18)` at `:228`,
   `## Phase 2 — …(2026-09-01)` at `:453`, `## Phase 3 — the tagger decision (2026-09-04)` at
   `:974`). Phase 6 adds its own; it does not edit earlier ones in place.
2. **A criteria table with an evidence column and a plan-number column** (`:1252-1260`), where
   the evidence is a **runnable command**, quoted verbatim so it cannot drift from the script.
3. **Dispositions superseded by a dated block-quote, with the original left standing**
   (`:1262-1272`): *"row 3's verdict token above is left deliberately standing, and is
   deliberately the only place in this file that carries it"*.
4. **A `### Still open` / standing-action list** (`:942`, `:1074`) — where D-11's pre-flag lives
   today (`:1327`) and where D-34's live-service Jellyfin change must be recorded, since git does
   not capture it.

---

## No Analog Found

| File | Role | Data flow | Reason |
|---|---|---|---|
| `06-EXPECTED-TREE.txt` | committed oracle fixture | batch | **No precedent for a fixture committed *before* the run it judges.** All 42 committed `.txt` and 11 `.tsv` files under `.planning/**/artifacts/` are *outputs* recorded afterwards (`05-03-junk-candidates.tsv`, `02.1-10-negative-controls.txt`). The only pre-committed fixture in the project is `03-SAMPLE.md`, which is **Markdown**, and `03-SAMPLE.md:29-32` states the convention it was honouring: *"this repository has zero committed non-Markdown data artefacts and that convention is kept"* — a claim that was true of `stacks/` and of Phase 3, and that Phases 02.1 and 05 have since departed from via `artifacts/`. |

**What the planner must decide, explicitly:**

- **Location.** Every committed data artefact lives at
  `.planning/phases/<phase>/artifacts/<NN-PP>-<name>.<ext>`. 06-VALIDATION.md places
  `06-EXPECTED-TREE.txt` at the **phase root**. Either move it under `artifacts/` (follows the
  only convention there is) or state in the file why it sits at the root (it is an *input* to the
  run, not an output of it — a real distinction, worth writing down).
- **Format.** A plain `.txt` path list is the most diffable form and `diff <(beet move -p …)`
  in 06-VALIDATION.md assumes it. The Markdown alternative (a fenced block inside `06-SAMPLE.md`)
  keeps Phase 3's convention but makes the diff a two-step extraction.
- **The `%aunique{}` landmine** (06-RESEARCH.md § *`%aunique{}`*, item 5): when no disambiguator
  separates an ambiguous set, beets appends the **numeric database id**, which is not reproducible
  across libraries. *"Any committed expected tree containing ` [123]` is a landmine."* Whichever
  format is chosen, the file needs a guard against that value ever being written into it.

**Two smaller gaps, stated rather than approximated:**

- **No script in this repo runs `docker exec`.** `grep -rn "docker exec -u" scripts/` → no hits.
  The invocation shape for D-30 has no in-repo precedent; 06-RESEARCH.md § *The `docker exec`
  forms* is the only source, and Pitfall 9 (absolute `/venv/bin/beet`, `-u beetle`) is the
  correctness constraint. Style the wrapper on `zfs_query()` (`check-music-freeze.sh:193-199`):
  a named function, a recorded route, read-only by contract.
- **No script reads `GET /Library/VirtualFolders`.** D-34's flag assertion is new surface on
  `check-music-consumers.sh`; only the transport (`jf_api`) and the fail-closed vocabulary carry
  over.

---

## Metadata

**Analog search scope:** `scripts/` (29 files), `stacks/selfhosted/arrs/` (18 files),
`.planning/phases/03-tagger-spike/`, `.planning/phases/05-inbox-structure-and-the-junk-gate/`,
`git ls-files .planning` (326 files, by extension).
**Files read in full or in targeted ranges:** 11.
**Pattern extraction date:** 2026-09-20
