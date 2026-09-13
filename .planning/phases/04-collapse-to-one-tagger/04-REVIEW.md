---
phase: 04-collapse-to-one-tagger
reviewed: 2026-09-14T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - scripts/check-music-freeze.sh
  - scripts/check-renovate.sh
  - scripts/normalise-dj-tags.py
  - scripts/quick-health-check.sh
  - scripts/spike03-discogs-probe.py
  - scripts/spike03-image-headroom.sh
  - scripts/spike03-wrtag-arms.sh
  - stacks/selfhosted/arrs/beets.md
  - stacks/selfhosted/arrs/beets/beets.yaml
  - stacks/selfhosted/arrs/beets/config.yaml
  - stacks/selfhosted/arrs/compose.yaml
  - stacks/selfhosted/arrs/sabnzbd.yaml
  - stacks/selfhosted/arrs/sabnzbd/audio.bash
  - stacks/selfhosted/arrs/sabnzbd/beets-config.yaml
findings:
  critical: 1
  warning: 10
  info: 7
  total: 18
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-09-14
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

> Severity key: `Critical` = BLOCKER (must fix before this ships). `Warning` = should fix.
> `Info` = suggestion. `CR-` ids are Critical-tier, `WR-` Warning-tier, `IN-` Info-tier.

## Summary

The phase does what it claims: one tagger definition survives (`git ls-files stacks | grep -lE
'image:…'` resolves to exactly `stacks/selfhosted/arrs/beets/beets.yaml`, verified), both vendored
beets configs declare `musicbrainz`, and the `beet` invocation is gone from `audio.bash`
(`grep -cE '^[[:space:]]*beet ' → 0`, and the git history shows one line removed, none added). No
credential, token, API key or password appears in any reviewed file — the two vendored configs
carry explicit screening notes and both are clean. The fail-closed discipline in the check scripts
is genuinely good: "could not look" is kept distinct from "nothing is wrong" at almost every site,
positive controls are used, and the census refuses to report `0` for a census that never ran.

The defects are concentrated in two places.

First, the one that matters: **stripping the `beet` call converted `audio.bash`'s beets() failure
branch from occasional to unconditional, and the only thing standing between that branch and
`rm -rf "$1"/*` on every completed music download is a single line in an untracked host file**
(`/config/extended.conf`) that no guard in this repo asserts, vendors, or hashes. The phase built
a byte-exact drift guard for three files and left the one file that arms a destructive path
outside it. The D-10 side-effect inventory in `sabnzbd.yaml` enumerates the surviving behaviours
of beets() and omits this branch entirely.

Second, several of the phase's own standing guards are narrower than the claims made for them: the
"false-pass guard" in `check-music-freeze.sh` §2 parses volume lines as strings and silently drops
quoted, variable-interpolated and long-form binds; the tagger-definition census matches four
literal image prefixes rather than "a tagger". Neither has a live hole today — I verified no
quoted or long-form mount exists and no second tagger image is present — but both are guards whose
stated purpose is catching exactly the thing they cannot see.

Separately, three in-band comments now assert the opposite of what the code does (they still
describe the census and drift blocks as unpromoted candidates), and one of them instructs a future
editor to treat live selector tokens as dead. In a codebase whose own doctrine is that "a false
claim left in-band verbatim is one that gets re-copied", that is a defect and not a nit.

## Critical Issues

### CR-01: Stripping the `beet` call made `audio.bash`'s destructive failure branch unconditional, guarded only by an unversioned host file

**File:** `stacks/selfhosted/arrs/sabnzbd/audio.bash:284-295` (the `rm -rf` at `:290`)
**Also:** `stacks/selfhosted/arrs/sabnzbd.yaml:121-133` (the D-10 inventory that omits it)

**Issue:**

`beets()` decides success by touching a sentinel and then looking for audio files newer than it:

```bash
touch "/config/scripts/beets-match"
...
if [ $(find "$1" ... -newer "/config/scripts/beets-match" | wc -l) -gt 0 ]; then
    log "SUCCESS: Matched with beets!"
else
    log "ERROR: Unable to match using beets to a musicbrainz release"
    if [ $requireBeetsMatch = true ]; then
        rm -rf "$1"/*
        log "ERROR: Marking download as failed..."
        exit 1
    fi
fi
```

The removed line was the only thing in that window that could ever make a file newer than the
sentinel. Before the strip, a successful `beet … import` took the SUCCESS branch. After the strip
**nothing can**, so the `else` branch now executes on every music job, unconditionally and forever.

`sabnzbd.yaml:127-129` pre-declares the two log lines as expected. It does not mention that the
same branch contains an `rm -rf` of the completed download. The gate is `requireBeetsMatch`, which
lives in `/config/extended.conf` — a host file that is **not in this repo, not vendored, not in the
`Vendored-file drift (D-13)` block's three-file set, and not asserted by
`check-music-freeze.sh`**. It is recorded as `"false"` only inside `.planning/` research notes
(`04-RESEARCH.md:315`, `04-D12-EVIDENCE.md:184`). One edit to that untracked file — or any restore
of an upstream-shipped `extended.conf` — deletes every completed music download and marks the job
failed, against content the project describes as irreplaceable and with no `beet undo`.

This is the same class the phase's own vendoring exists to prevent (upstream `setup.bash`
re-downloading files), applied to a file the vendoring does not cover. Note also
`[ $requireBeetsMatch = true ]` is unquoted: if the variable is unset the test errors with rc 2
rather than evaluating false. It lands in the safe direction here only because a failing `[` inside
an `if` condition is treated as false — safety by accident, not by design.

**Fix:** Do not edit `audio.bash` — byte-identity against the host copy is the asserted property.
Close it at the guard layer instead. Add `extended.conf` to the drift set:

```bash
# scripts/quick-health-check.sh, inside DRIFT_CMD (needs a repo-side vendored copy to compare):
_drift_pair extended.conf stacks/selfhosted/arrs/sabnzbd/extended.conf \
  "$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/extended.conf"
# ...and DRIFT_LINES -ne 3  ->  -ne 4
```

If vendoring the whole file is undesirable (it may hold site values), assert the three switches
directly instead — this is the minimum, and it fails closed on "could not look":

```bash
# scripts/check-music-freeze.sh, new section: the extended.conf switch census
EC=/mnt/fast/appdata/arrs/sabnzbd/config/extended.conf
if [[ ! -r "$EC" ]]; then
  fail "extended.conf unreadable — the audio.bash destructive switches are UNKNOWN, not safe"
else
  grep -qE '^[[:space:]]*requireBeetsMatch="?false"?'  "$EC" \
    || fail "requireBeetsMatch is not false — audio.bash beets() will rm -rf every music job"
  grep -qE '^[[:space:]]*ConversionFormat="?FLAC"?'    "$EC" \
    || fail "ConversionFormat is not FLAC — conversion() will rm -rf every job carrying a FLAC (WR-01)"
  grep -qE '^[[:space:]]*ReplaygainTagging="?false"?'  "$EC" \
    || fail "ReplaygainTagging is not false — a tag writer is active after the strip"
fi
```

And amend the `sabnzbd.yaml:121-133` D-10 inventory to name the `rm -rf` branch explicitly, since
that block is the document a future reader will trust.

## Warnings

### WR-01: `conversion()` deletes the download folder for every non-OPUS format; the `ffmpeg` block below it is unreachable

**File:** `stacks/selfhosted/arrs/sabnzbd/audio.bash:226-255`
**Issue:** Inside the `for fname in "$1"/*.flac` loop, the `if/else` on `ConversionFormat = OPUS`
has no fallthrough — the `else` runs `rm -rf "$1"/*; exit 1` for **every** other format. The
`if ffmpeg …` block at `:242-255`, which is the actual conversion path for MP3/AAC/ALAC, is
unreachable dead code. Only `ConversionFormat=FLAC` escapes, because `:220` short-circuits it
before the loop. So any value other than `FLAC` or `OPUS` destroys a download that contains FLACs.

This is inherited upstream code and was not changed by this phase — which is why it is Warning and
not Critical — but it is now vendored into this repo and shipped, and it depends on the same
unguarded `extended.conf` value as CR-01. It is closed by the same fix.
**Fix:** The `ConversionFormat=FLAC` assertion in the CR-01 snippet covers it. Do not patch
`audio.bash` in place (drift guard); if upstream is ever re-vendored, carry the fix as a documented
local change alongside the `SAB_PP_STATUS` guard.

### WR-02: `beets.yaml` publishes port 8337 LAN-wide while its Authelia labels cannot possibly apply

**File:** `stacks/selfhosted/arrs/beets/beets.yaml:70-85`
**Issue:** The service declares a full Traefik router chained through `chain-authelia@file`, but
its `networks:` block is commented out at `:70-71`. With no `networks:` key, Compose attaches it to
the implicit project `default` network, not the external `t3_proxy` that Traefik uses — so the
router can never reach it and the Authelia protection is illusory. Meanwhile `ports: - 8337:8337`
binds the host interface directly, which is the one path that *does* work and it has no
authentication in front of it.

This is an outlier, not a house convention: of the 15 service files under `stacks/selfhosted/arrs/`,
`beets.yaml` is the **only** one with `traefik.enable=true` and zero `networks:` declarations —
every sibling declares one or two.

Not rated Critical because it is not currently exploitable: the vendored `config.yaml` declares
`plugins: musicbrainz` only, so the `web` plugin never loads and nothing listens on 8337; and the
container is `restart: "no"` + `profiles: ["manual"]` + commented out of the include list. It
becomes a live LAN-wide unauthenticated exposure the moment the `web` plugin is enabled — which is
exactly what Phase 5/6 will want — on a container that holds `/downloads:rw` and, from Phase 6, rw
on the library.
**Fix:**
```yaml
    networks:
      - t3_proxy
    # drop the host port entirely; reach it through Traefik + Authelia
    # ports:
    #   - 8337:8337
```
If a host port is genuinely wanted for local use, bind it to loopback: `- "127.0.0.1:8337:8337"`.

### WR-03: The §2 "false-pass guard" parses volume lines as strings and silently drops three mount shapes

**File:** `scripts/check-music-freeze.sh:411-457`
**Issue:** The guard exists specifically to catch library-reaching `rw` mounts that section 1
cannot see. Its input is `grep -rn '/mnt/tank/media'` and its parsing is pure string slicing
(`host_side="${mapping%%:*}"`), with `touches_library()` doing literal prefix matching and no
`realpath`. Three real shapes escape it:

1. **Quoted mappings.** `- "/mnt/tank/media:/media:rw"` yields `host_side='"/mnt/tank/media'` with a
   leading quote, so `touches_library` returns false and the row is printed in the table but
   silently excluded from `DECLARED_MUSIC_RW`. A false pass in the guard named for false passes.
2. **Variable interpolation.** `- ${TANK}/media/Music:/music:rw` never matches the grep at all. This
   repo already interpolates `$TZ`/`$PUID`/`${SABNZBD_API_KEY}`, so the shape is plausible.
3. **Long-form binds.** `type: bind` / `source:` / `target:` is invisible to a one-line parser.
   (Only a commented example exists today, in `automation/pwpush.yaml:88`.)

I verified none of these is present in the tree right now, so there is no live hole — but the guard
cannot prove that, and its own summary line reads as though it can.
**Fix:** Strip surrounding quotes before splitting, and add a detector that refuses rather than
guesses when it meets a shape it cannot parse:

```bash
mapping="$(printf '%s' "$mapping" | sed 's/^["'"'"']//; s/["'"'"']$//')"
...
# elsewhere, a loud refusal rather than a silent miss:
if grep -rqE '^[[:space:]]*(-[[:space:]]*)?type:[[:space:]]*bind' "$STACKS" --include='*.yaml'; then
  fail "long-form 'type: bind' mounts exist; this parser cannot see them — §2 is UNKNOWN, not clean"
fi
if grep -rn '^\s*-\s*.*\$\{\?[A-Z_]\+.*:/' "$STACKS" --include='*.yaml' | grep -q .; then
  fail "a volume line interpolates a variable; its host path cannot be resolved statically — UNKNOWN"
fi
```

### WR-04: The tagger-definition census matches four literal image prefixes, not "a tagger"

**File:** `scripts/check-music-freeze.sh:710-719`
**Issue:** The census that backs criterion 1 greps for
`^[[:space:]]*image:[[:space:]]*(lscr\.io/linuxserver/beets|sentriz/wrtag|ghcr\.io/terry90/soulbeet|metasauce/beets-flask)`.
That detects *resurrection of three known retired images*. It does not detect a tagger, and several
plausible spellings read as green (`tagger definitions: 1`):

- a registry-qualified form — `image: docker.io/sentriz/wrtag`;
- a quoted form — `image: "sentriz/wrtag:v0.33.0"`;
- any other tagger entirely — `ghcr.io/beetbox/beets`, `mikenye/picard`, `ghcr.io/…/musicbrainz-picard`.

The anchor also makes the assertion brittle in the other direction: the comment at `:714` already
flags that Phase 5's `beets-flask` will fail this counter, which is deliberate.
**Fix:** Allow an optional registry prefix and optional quoting, and treat the image *name* rather
than the full reference as the token:

```bash
| { xargs -r -d '\n' grep -lE '^[[:space:]]*image:[[:space:]]*["'"'"']?([a-z0-9.-]+/)*(beets|beets-flask|wrtag|soulbeet|picard)\b' 2>/dev/null || true; }
```
Then assert the *set* of files, not just the count, which the code already does correctly at `:714`.

### WR-05: Three in-band comments now state the opposite of what the code does, and one of them will cause the WR-09 selector to be broken

**File:** `scripts/quick-health-check.sh:19-27`, `scripts/quick-health-check.sh:754-758`,
`stacks/selfhosted/arrs/beets/config.yaml:14-18`
**Issue:** All three were true before plan 04-11 and are false now:

- `quick-health-check.sh:23-25` — "6b is a CANDIDATE: it runs only when the caller sets
  `CENSUS_CANDIDATE=1` … Nothing this script exits with changes until 04-11 promotes it." The
  constant is `TAGGER_CENSUS_PROMOTED=1`; 6b always runs and is fatal. The sixth notice at `:156`
  says so, directly contradicting this one.
- `quick-health-check.sh:756-758` — "Section 6b is a CANDIDATE and prints no counters on a routine
  run, so until plan 04-11 promotes it these tokens match nothing and this block's output is
  byte-for-byte what it was before." This is the dangerous one. It tells a future editor that six
  tokens in the live `grep -E` selector are inert. Removing them as dead weight would not produce a
  visible failure: `SUMMARY` stays non-empty (the four original tokens still match), so the branch
  still prints `✅ Intact` — while silently dropping every census counter from the displayed
  output. That is precisely the WR-09 class of silent coupling break the surrounding comment block
  exists to prevent.
- `beets/config.yaml:14-18` — "a block that plan 04-10 BUILDS as a candidate and plan 04-11
  PROMOTES … **IT DOES NOT EXIST AT THIS COMMIT.** Until 04-10 lands, nothing detects divergence
  between this file and the host." The block exists, is promoted, and hashes this exact file.

**Fix:** Rewrite all three to the present tense in one commit, following the file's own withdrawal
convention (paraphrase the withdrawn claim rather than quoting it, so a grep for it keeps returning
zero). For `:756-758` specifically:

```bash
    # The six Phase 4 tokens on the last two lines select section 6b's census counters. 6b is
    # PROMOTED (TAGGER_CENSUS_PROMOTED=1) and prints those counters on every routine run, so these
    # tokens are LIVE. Removing one does not fail this block — SUMMARY stays non-empty and the tick
    # still prints — it silently drops a counter from the output. Change both files together.
```

### WR-06: `normalise-dj-tags.py` double-counts skipped files, so the summary does not reconcile

**File:** `scripts/normalise-dj-tags.py:1161-1163`, `:1188`, `:1204-1207`
**Issue:** When rule 1 cannot derive an album it does `counts["skipped"] += 1; continue`, which
skips only the *rule* loop. The emit loop then iterates `loaded` again, finds no proposal for that
path, and does `counts["unchanged"] += 1`. The same file is counted in both buckets. Rule 3 is
worse: `counts["skipped"] += len(loaded)` charges the entire folder as skipped, on top of any
per-file rule-1 skips, and every one of those files is *also* counted unchanged (or changed, if
rule 1 or 2 proposed something for it).

`files_seen` therefore never equals `changed + unchanged + skipped + failed`, in either mode. Since
the dry run *is* the D-08 review artefact and `.summary.json` is what a later reader will quote,
the headline counts are not trustworthy.
**Fix:** Track skip state per path and make the buckets disjoint:

```python
skipped_paths: set[str] = set()
# rule 1:
            if derived is None:
                skipped_paths.add(path)
                log.warning("rule 1 skipped %s: %s", path, reason)
                continue
# rule 3:
                if not chosen:
                    skipped_paths.update(p for p, _h, _v in loaded)
                    log.warning("rule 3 skipped folder %s: no label token in its albums", folder_name)
# emit loop:
            if not fields:
                counts["skipped" if path in skipped_paths else "unchanged"] += 1
                continue
```
Then assert the invariant before writing the summary, so a future regression is loud:
`assert counts["files_seen"] == counts["changed"] + counts["unchanged"] + counts["skipped"] + counts["failed"]`.

### WR-07: `check-renovate.sh` reports `1` for three empty sets — the exact defect it fixed elsewhere

**File:** `scripts/check-renovate.sh:83-84`, `:96-97`, `:106-112`
**Issue:** `COMPOSE_COUNT=$(echo "$COMPOSE_FILES" | wc -l)` counts the single newline `echo` emits
for an empty string, so zero compose files reports as `1`. Verified: `echo "" | wc -l` → `1`. The
same bug is in `IMAGE_FILE_COUNT` and `IMAGE_COUNT`. The script already knows this pattern is wrong
— `POSTGRES_COUNT`, `REDIS_COUNT` and `RENOVATE_COUNT` were deliberately converted to
`awk 'NF{n++} END{print n+0}'` for exactly this reason, with the fix documented at `:121-122` and
`:165-167`. Three call sites were missed. The summary block at `:200-202` then reports fabricated
counts, and "1 compose file" on a repo where the find returned nothing reads as healthy.
**Fix:** Apply the same awk form the file already standardised on:
```bash
COMPOSE_COUNT=$(printf '%s\n' "$COMPOSE_FILES"   | awk 'NF{n++} END{print n+0}')
IMAGE_FILE_COUNT=$(printf '%s\n' "$YAML_WITH_IMAGES" | awk 'NF{n++} END{print n+0}')
IMAGE_COUNT=$(printf '%s\n' "$IMAGES"            | awk 'NF{n++} END{print n+0}')
```

### WR-08: `avail_gb()`'s documented "could not read df" branch is unreachable under `set -e`

**File:** `scripts/spike03-image-headroom.sh:171-176`, consumed at `:249`, `:265-266`, `:365`, `:451`
**Issue:** The function is written to return an empty string so callers can report
`could not read available GiB from df - UNKNOWN, not healthy`. But the script sets
`set -euo pipefail` at `:100`, and `b="$(df -B1 --output=avail / … | tail -1 | tr -dc '0-9')"` is a
standalone assignment: if `df` fails, `pipefail` propagates it, the assignment fails, and `set -e`
terminates the script before the `[ -z "$b" ]` guard is ever reached. The caller
`before_avail="$(avail_gb)"` inherits the same fate. So the UNKNOWN branch — the one that upholds
"could not look ≠ healthy" for the OD-1 floor — cannot fire, and a df failure exits with a bare
non-zero status and no explanation instead.
**Fix:** Make the failure explicit inside the function so the guard is reachable:
```bash
avail_gb() {
  local b=""
  b="$(df -B1 --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')" || b=""
  [ -z "$b" ] && return 0
  printf '%s' "$(( b / 1073741824 ))"
}
```

### WR-09: A down Traefik still exits `quick-health-check.sh` with 0

**File:** `scripts/quick-health-check.sh:463-471`, `:474-479`, `:562-567`
**Issue:** The three legacy blocks print `❌ Not running` / `❌ Not accessible` without touching
`EXIT_CODE`. The estate's single health-check entry point therefore exits 0 — "healthy" to any
caller reading the status rather than the transcript — with Traefik down, which takes every
`*.deercrest.info` service with it. The file documents this as WR-02 at `:452-462` and explicitly
declines to fix it, and the reasoning given (these are wrong-diagnosis, not false-green) is sound
as far as the transcript goes. It is still a check that cannot fail on the estate's highest-blast-
radius outage. Pre-existing, not introduced by this phase.
**Fix:** Capture the status and branch, the same shape the container-count sites already use:
```bash
ssh -n $SSH_OPTS root@172.16.1.159 \
    "set -o pipefail; timeout $REMOTE_TIMEOUT docker ps --format '{{.Names}}' | grep -q '^traefik$'"
TRAEFIK_RC=$?
case "$TRAEFIK_RC" in
  0)   echo "✅ Running" ;;
  1)   echo "❌ Not running"; EXIT_CODE=1 ;;
  124) echo "⚠️  UNKNOWN — bound expired; this is NOT 'not running'"; EXIT_CODE=1 ;;
  *)   echo "⚠️  UNKNOWN — ssh exit $TRAEFIK_RC"; EXIT_CODE=1 ;;
esac
```

### WR-10: `bounded_ssh` recreates a deleted `mktemp` path, reintroducing the race `mktemp` exists to close

**File:** `scripts/quick-health-check.sh:378-392`
**Issue:** The sentinel is created safely with `mktemp`, immediately `rm -f`'d at `:383`, and then
written back at `:385` by the watchdog (`: > "$sentinel"`). Between the `rm` and the write the path
is predictable and unowned, so anything able to create a file there can pre-place a symlink and
redirect the truncating write. The fallback path is worse — `"${TMPDIR:-/tmp}/qhc-bound.$$.$RANDOM"`
is guessable and is used unguarded whenever `mktemp` is unavailable. Impact is low in practice
(macOS gives each user a private `TMPDIR`, and the script is run interactively by its owner), but
this is a needless reintroduction of a closed hole in a file that otherwise reasons carefully.
**Fix:** Keep the file and use its content as the sentinel rather than its existence:
```bash
sentinel=$(mktemp -t qhc-bound) || { echo "cannot create sentinel"; return 1; }
"$@" </dev/null & cmd_pid=$!
{ sleep "$secs"; printf 'timeout' > "$sentinel"; kill -TERM "$cmd_pid" 2>/dev/null; } & watch_pid=$!
wait "$cmd_pid" 2>/dev/null; rc=$?
kill -TERM "$watch_pid" 2>/dev/null; wait "$watch_pid" 2>/dev/null
[ -s "$sentinel" ] && BOUNDED_SSH_TIMED_OUT=1
rm -f "$sentinel"
```

## Info

### IN-01: `sqlite3` is load-bearing in §6b but absent from the §0 toolchain preconditions

**File:** `scripts/check-music-freeze.sh:296` (the tool list), `:768` (the dependency)
**Issue:** Section 6b classifies every candidate database with `sqlite3 "file:${p}?mode=ro" '.tables'`.
Section 0 asserts `ffprobe ffmpeg jq gzip sha256sum` and not `sqlite3`. If `sqlite3` is missing,
every candidate falls into `UNCLASSIFIED_DBS` as "SQLite header but unreadable" and the run fails
red — correct direction, but the reader is told the databases are unreadable rather than that the
tool is absent, which are different answers by this file's own doctrine.
**Fix:** Add `sqlite3` to the `for t in …` list at `:296`.

### IN-02: `check-renovate.sh` omits `--strict`, and computes a version it never uses

**File:** `scripts/check-renovate.sh:66`, `:129`
**Issue:** Two small things. (a) The standing check runs `renovate-config-validator --no-global`,
while the recorded acceptance evidence for criterion 2 (`beets.md:1225`) was taken with
`--strict --no-global`; the guard is weaker than the criterion it keeps true. (b) `VERSION=$(echo
"$img" | grep -oE ':[0-9]+' | …)` is assigned and never referenced — dead code.
**Fix:** Add `--strict` to the invocation; delete the `VERSION` assignment or print it in the row
below it.

### IN-03: Operator-supplied env vars are interpolated unvalidated into a remote root shell string

**File:** `scripts/quick-health-check.sh:321` / `:620-628` (`DRIFT_APPDATA_ROOT`), `:284` (`REMOTE_TIMEOUT`)
**Issue:** `DRIFT_APPDATA_ROOT` is pasted into a double-quoted command string executed as root over
ssh; a value containing `"` and `;` becomes remote command injection. This is self-injection by the
operator on their own workstation, not a privilege-boundary crossing, and the override already
forces `EXIT_CODE=1` so it cannot manufacture a green — hence Info. `REMOTE_TIMEOUT` is the same
shape.
**Fix:** Validate before use: `case "$DRIFT_APPDATA_ROOT" in /*[!a-zA-Z0-9/_.-]*|"") echo "refusing
unsafe DRIFT_APPDATA_ROOT"; exit 2 ;; esac` and
`case "$REMOTE_TIMEOUT" in ''|*[!0-9]*) exit 2 ;; esac`.

### IN-04: The §2 Jellyfin exemption is file-scoped, not path-scoped

**File:** `scripts/check-music-freeze.sh:447`
**Issue:** `[[ "$f" == "stacks/selfhosted/media/jellyfin.yaml" ]] && continue` exempts *every* rw
row in that file, so a second, narrower Music-reaching mount added to `jellyfin.yaml` would be
invisible. Low impact — Jellyfin already holds the whole tree rw by D-21 — but the exemption is
broader than the decision it encodes.
**Fix:** Exempt the specific mapping instead of the file:
`[[ "$f" == "stacks/selfhosted/media/jellyfin.yaml" && "$mapping" == "/mnt/tank/media:/media:rw" ]] && continue`.

### IN-05: A failed write still prints a change line to the review artefact

**File:** `scripts/normalise-dj-tags.py:1208-1234`
**Issue:** The `path :: field: old -> new` lines are written to stdout before `write_tags()` is
attempted. Under `--apply`, a file whose write raises is correctly routed to `.failed` and excluded
from the NDJSON, but its change line has already been emitted on stdout. A reader diffing stdout
against the tree will see a change that never happened.
**Fix:** In apply mode, buffer the stdout lines and emit them after the write succeeds; or append a
`(FAILED)` marker on the error path.

### IN-06: Two upstream nits in the vendored hook, recorded not fixed

**File:** `stacks/selfhosted/arrs/sabnzbd/audio.bash:276-279`, `:289`
**Issue:** `:276` tests `/config/scripts/beets/beets.log` but removes `/config/scripts/beets.log` —
the guard can never fire for the path it deletes (already noted in `04-RESEARCH.md:576`). `:289`
uses an unquoted `[ $requireBeetsMatch = true ]` (see CR-01). Both are upstream; neither should be
edited in place while the drift guard asserts byte-identity.
**Fix:** Carry both in the TO UPDATE notes at `:23-24` so they are re-applied if upstream is ever
re-vendored.

### IN-07: `--sidecars` emits a blank line when the sidecar set is empty

**File:** `scripts/check-music-freeze.sh:620`
**Issue:** `printf '%s\n' "$SIDECARS" >&3` writes a single newline when `SIDECARS` is empty, so a
redirected list file contains one blank line rather than being zero-byte. A consumer counting lines
reads 1 where the truth is 0 — the same family as WR-07.
**Fix:** `[[ -n "$SIDECARS" ]] && printf '%s\n' "$SIDECARS" >&3`

---

_Reviewed: 2026-09-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
