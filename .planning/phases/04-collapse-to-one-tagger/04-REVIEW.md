---
phase: 04-collapse-to-one-tagger
reviewed: 2026-09-14T09:00:00Z
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
  warning: 12
  info: 10
  total: 23
status: issues_found
---

# Phase 4: Code Review Report (re-review)

**Reviewed:** 2026-09-14
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

> Severity key: `Critical` = BLOCKER (must fix before this ships). `Warning` = should fix.
> `Info` = suggestion. `CR-` ids are Critical-tier, `WR-` Warning-tier, `IN-` Info-tier.
> This is a **re-review** of the same 14 files against the prior report at `f39e417`. Ids are
> preserved across reviews: a still-open finding keeps its id, a closed one is listed under
> *Already Closed Since Previous Review* and is never re-issued, and new ids continue the
> existing sequence (`CR-02`, `WR-11`+, `IN-08`+).

## Summary

Only **one** of the fourteen reviewed files changed since the previous review — verified
mechanically (`git diff --name-only f39e417..HEAD -- scripts/ stacks/selfhosted/arrs/` returns
`scripts/quick-health-check.sh` and nothing else). The other two commits (`220dcf4`, `e19c178`)
touch `.planning/` only. So every prior finding outside `quick-health-check.sh` is, by
construction, untouched — and I re-verified each one against the file on disk rather than carrying
it forward on faith.

**CR-01 and WR-01 are genuinely closed at the guard layer.** The fifth fatal block at
`scripts/quick-health-check.sh:805-934` reads `/config/extended.conf` out of the sabnzbd container
over `docker exec`, matches remote-side, returns two label lines, and sets `EXIT_CODE=1` on a wrong
value, an absent key, an unreadable file, an empty read, a bound expiry, a short answer or an
unrecognised label. The negative controls were driven, not asserted, and the transcript records the
per-switch independence proof correctly. The block is reachable on the routine path (it sits between
the drift block and the freeze fold-in, after both early-exit probes), the key names are right (the
green run at `260914-a2y-negative-controls.txt:160` proves both greps matched the real file), and
`bash -n` passes. That is real work and it is not padding.

**But the guard has a demonstrated false-green mode, and it is on the one destructive path it
exists to watch.** Both value patterns are start-anchored *and unbounded at the right*, and both
assertions are `grep -q` over the whole file — "does any line match" — while `audio.bash` gets its
values from `source`, where the **last** assignment wins. I drove both cases locally:
`ConversionFormat="FLACX"` is reported `ok`; a file containing `ConversionFormat="FLAC"` followed by
`ConversionFormat="MP3"` is reported `ok` while `source` yields `MP3`; and a file containing
`requireBeetsMatch="false"` followed by `requireBeetsMatch="true"` is reported `ok` while `source`
yields `true` — which is precisely the value that arms `rm -rf "$1"/*` at `audio.bash:290`. The
`found=` text makes it worse rather than better: it is taken with `sed -n '1p'`, the **first**
match, so even a red verdict quotes a line that may not be the effective one. That is `CR-02`.

The 220dcf4 "defective Task 3 gate" is real and is honestly recorded, but it is a defect in the
plan's own acceptance grep (`grep -c 'extended.conf'`, unescaped `.` matching the task's own
`…-extended-conf-…` directory name), **not** in the shipped script. I confirmed the underlying
property independently: no file named `extended.conf` exists in this repo or in commit `c0b04c3`.
The "key-name grep finding" in the same commit is about that same regex-wildcard family — the two
switch key names (`requireBeetsMatch`, `ConversionFormat`) are correct and do match the live file.
So the specific worry that prompted this re-review is **not** where the defect landed; `CR-02` is.

One half of CR-01's prescribed fix was not done and is not mentioned anywhere as a decision: the
D-10 side-effect inventory in `sabnzbd.yaml:121-133` still enumerates the surviving behaviours of
`beets()` and still omits the `rm -rf` branch (`grep -n 'rm -rf' sabnzbd.yaml` returns one hit, and
it is about `verify()`, not `beets()`). That is `WR-11`.

Everything else in the prior report is **still open, verbatim**, at line numbers that shifted only
in `quick-health-check.sh` (+259 lines). WR-09 in particular is no longer theoretical: the quick
task's own summary records `Traefik dashboard: ❌ Not accessible` printing on the green run that
exited 0 — a red glyph in the transcript of a check that reported success.

Three new defects outside the changed file surfaced on this pass, all of the same family this
estate names in its own doctrine — a documented claim that the code does not support: `beets.md`'s
criterion-1 evidence command resolves to **zero** files when run (`WR-12`), `spike03-discogs-probe.py`
sets the **root** logger to DEBUG under `--verbose` inside the very function whose docstring says it
does not (`WR-13`), and `beets.md`'s "Two standing guards" closing section never learned about the
third (`IN-09`).

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-02: The extended.conf destructive-switch guard reports green on values that arm `rm -rf` — unbounded prefix match, and "any line" where bash takes the last

**File:** `scripts/quick-health-check.sh:834`, `:841` (the two assertion patterns), `:832`, `:839`
(the `found=` display)

**Issue:**

The block asserts the only two values standing between every completed music download and an
`rm -rf "$1"/*`. Both assertions are wrong in the same two ways.

**(a) The value patterns have no right-hand boundary.** Driven locally:

```
$ printf 'ConversionFormat="FLACX"\n' | grep -qE '^[[:space:]]*ConversionFormat="?(FLAC|OPUS)"?' && echo OK
OK
$ printf 'ConversionFormat=FLACTEST\n' | grep -qE '^[[:space:]]*ConversionFormat="?(FLAC|OPUS)"?' && echo OK
OK
```

`audio.bash:220` tests `[ "${ConversionFormat}" = FLAC ]` and `:226` tests `= OPUS`, both exact. So
any value that merely *begins* `FLAC` or `OPUS` — `FLACX`, `FLAC ` with a stray trailing space
inside the quotes, `OPUS2` — is reported `✅ extended.conf switches disarmed (2)` while
`conversion()` falls straight through to the `rm -rf "$1"/*` at `audio.bash:237`. One stray
character in a hand-edited config produces a confident green on a data-destruction guard.

The in-band comment at `:785-788` forbids a `$` anchor and `grep -x`, and that reasoning is
correct — plan 04-12 measured an end-anchored pattern false-redding a value with a trailing
comment. But "no end anchor" is not the same requirement as "no boundary", and the block took the
first as licence for the second.

**(b) Both assertions ask "does any line match", while `audio.bash` gets its values from
`source /config/extended.conf:41`, where the last assignment wins.** Driven end-to-end:

```
$ printf 'requireBeetsMatch="false"\nrequireBeetsMatch="true"\n' > /tmp/ecdemo2.conf
$ ( . /tmp/ecdemo2.conf; echo "effective=$requireBeetsMatch" )
effective=true
$ grep -qE '^[[:space:]]*requireBeetsMatch="?false"?' /tmp/ecdemo2.conf && echo "GUARD SAYS OK"
GUARD SAYS OK
```

Same for `ConversionFormat="FLAC"` followed by `ConversionFormat="MP3"` — guard `ok`, effective
value `MP3`, `rm -rf`. Appending a line rather than editing one in place is the normal way an
operator or a restored upstream block modifies a sourced bash config, and the safe direction
(appending `false` under a `true`) is exactly as likely as the unsafe one — but only the unsafe one
is undetected.

**(c) The `found=` diagnostic compounds it.** `:832` and `:839` take `sed -n '1p'` — the **first**
matching line — while `source` takes the last. On a duplicated key the operator is shown a line
that is not the one in force, on the branch whose entire job is to tell them what is wrong.

This does not reopen CR-01: the block exists, it runs on every invocation, and it fails closed on
every "could not look" branch. It is filed Critical because it is a **demonstrated false green on
the sole standing detector for an unconditional `rm -rf`** of content this project describes as
irreplaceable, and the trigger is a single stray character or a duplicated line.

**Fix:** Assert the **effective** value, not the presence of a matching line, and bound the value.
Keep the matching remote-side and keep returning labels only, per (c) at `:766-772`. Replace both
`grep -q` tests with a last-match extraction:

```sh
# inside EXTCONF_CMD, replacing the two if/grep -q pairs:
_ec_val() {  # $1 = key name -> prints the LAST assignment's bare value, comment and quotes stripped
  printf '%s\n' "$_ec" \
    | grep -E "^[[:space:]]*$1=" \
    | tail -n 1 \
    | sed -e "s/^[[:space:]]*$1=//" -e 's/[[:space:]]*#.*$//' -e 's/^"//' -e 's/"$//' \
          -e "s/^'//" -e "s/'$//" -e 's/[[:space:]]*$//'
}
_rbm=$(_ec_val requireBeetsMatch); [ -n "$_rbm" ] || _rbm='(absent)'
[ "$_rbm" = "false" ] && echo 'requireBeetsMatch=ok' || echo "requireBeetsMatch=BAD found=$_rbm"
_cf=$(_ec_val ConversionFormat);  [ -n "$_cf" ] || _cf='(absent)'
case "$_cf" in FLAC|OPUS) echo 'ConversionFormat=ok' ;; *) echo "ConversionFormat=BAD found=$_cf" ;; esac
```

`tail -n 1` matches `source` semantics; the `sed` strips the trailing comment (preserving the
04-12 tolerance the current comment is right to insist on) and then compares the **whole** value,
which closes (a) without adding an end anchor to a regex. Add a driven control for each: a fixture
with a duplicated key in the unsafe order, and one with `ConversionFormat="FLAC "`. Both must go
red; today both go green.

### Warnings

#### WR-02: `beets.yaml` publishes port 8337 LAN-wide while its Authelia labels cannot possibly apply

**Status:** STILL OPEN. Unchanged since `f39e417`.
**File:** `stacks/selfhosted/arrs/beets/beets.yaml:70-86` (networks commented at `:70-71`, host
port at `:72-73`, `chain-authelia@file` at `:79`)
**Issue:** The `networks:` key is still commented out while `traefik.enable=true` and a full
`chain-authelia@file` router are declared, so Compose attaches the service to the implicit project
`default` network and the Traefik router can never reach it — the Authelia protection is
illusory. `ports: - 8337:8337` is the one path that does work and has no authentication.
Re-verified as an outlier, not a convention: of the 16 files under `stacks/selfhosted/arrs/`,
`beets/beets.yaml` is the **only** one with `traefik.enable=true` and `networks=0`; every sibling
declares one or two. Still not exploitable today (`config.yaml:60` declares `plugins: musicbrainz`
only, so the `web` plugin never loads and nothing listens on 8337; the service is `restart: "no"`,
`profiles: ["manual"]`, and commented out of `compose.yaml:39`). It becomes a live unauthenticated
LAN exposure the moment Phase 5/6 enables `web`, on a container holding `/downloads:rw`.
**Fix:** unchanged from the prior review —
```yaml
    networks:
      - t3_proxy
    # drop the host port; reach it through Traefik + Authelia
    # ports:
    #   - 8337:8337
```
or bind to loopback: `- "127.0.0.1:8337:8337"`.

#### WR-03: The §2 "false-pass guard" parses volume lines as strings and silently drops three mount shapes

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/check-music-freeze.sh:411-457` (the parse at `:420-421`, the filter at `:443-449`)
**Issue:** `host_side="${mapping%%:*}"` with no quote-stripping and no `realpath`. Quoted mappings
(`- "/mnt/tank/media:/media:rw"`) yield a leading `"` and fall out of `DECLARED_MUSIC_RW` silently;
variable-interpolated host paths never match the driving grep at `:429` at all; long-form
`type: bind` is invisible to a one-line parser.
**New evidence strengthening this:** I re-ran all three probes. No quoted `/mnt/tank` mapping
exists, and the only `type: bind` is commented (`automation/pwpush.yaml:88`) — but
**variable-interpolated volume lines now number ten in the tree** (`immich/compose.yaml:33,117`,
`arrs/listenarr.yaml:17-19`, `automation/n8n-postgres.yaml:28`, `monitoring/prometheus.yaml:13`,
`monitoring/grafana.yaml:14`, `media/audiobookshelf.yaml:15-16`), one of them
`${MEDIA}/audiobooks` inside `arrs/`. None resolves into the library today, but the guard cannot
prove that and its summary line at `:453` reads as though it can.
**Fix:** unchanged — strip surrounding quotes before splitting, and add loud refusals rather than
silent misses:
```bash
mapping="$(printf '%s' "$mapping" | sed 's/^["'"'"']//; s/["'"'"']$//')"
...
if grep -rqE '^[[:space:]]*(-[[:space:]]*)?type:[[:space:]]*bind' "$STACKS" --include='*.yaml'; then
  fail "long-form 'type: bind' mounts exist; this parser cannot see them — §2 is UNKNOWN, not clean"
fi
if grep -rqE '^[[:space:]]*-[[:space:]]*\$\{?[A-Za-z_]+[^:]*:/' "$STACKS" --include='*.yaml'; then
  fail "a volume line interpolates a variable; its host path cannot be resolved statically — UNKNOWN"
fi
```

#### WR-04: The tagger-definition census matches four literal image prefixes, not "a tagger"

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/check-music-freeze.sh:711` (the pattern), `:714` (the assertion)
**Issue:** The pattern is four full image references. A registry-qualified form
(`docker.io/sentriz/wrtag`), a quoted form (`image: "sentriz/wrtag:v0.33.0"`) or any other tagger
(`ghcr.io/beetbox/beets`, `mikenye/picard`) reads as `tagger definitions: 1`.
**Re-verified, no live hole:** `git ls-files stacks | xargs grep -nE '^[[:space:]]*image:.*(beets|wrtag|soulbeet|picard)'`
returns exactly one line, `beets/beets.yaml:6`.
**Fix:** unchanged — allow an optional registry prefix and optional quoting, matching the image
*name* rather than the full reference:
```bash
| { xargs -r -d '\n' grep -lE '^[[:space:]]*image:[[:space:]]*["'"'"']?([a-z0-9.-]+/)*(beets|beets-flask|wrtag|soulbeet|picard)\b' 2>/dev/null || true; } \
```

#### WR-05: Three in-band comments state the opposite of what the code does, and one instructs a future editor to treat live selector tokens as dead

**Status:** STILL OPEN. Line numbers shifted in `quick-health-check.sh` (+253) by `c0b04c3`; the
text is byte-unchanged.
**File:** `scripts/quick-health-check.sh:19-27` (was 19-27), `scripts/quick-health-check.sh:1007-1010`
(was 754-758), `stacks/selfhosted/arrs/beets/config.yaml:14-18`
**Issue:** All three were true before plan 04-11 and are false now, confirmed by grep:
- `quick-health-check.sh:23` still reads "6b is a CANDIDATE: it runs only when the caller sets
  `CENSUS_CANDIDATE=1` … Nothing this script exits with changes until 04-11 promotes it." The
  constant is `TAGGER_CENSUS_PROMOTED=1` (`check-music-freeze.sh:144`); 6b always runs and is
  fatal. The sixth notice at `:156` says so, directly contradicting this one, in the same file.
- `quick-health-check.sh:1008` still reads "Section 6b is a CANDIDATE and prints no counters on a
  routine run, so until plan 04-11 promotes it these tokens match nothing." This is the dangerous
  one: it tells a future editor that six tokens in the **live** `grep -E` selector at `:1012` are
  inert. Removing them produces no visible failure — `SUMMARY` stays non-empty because the four
  original tokens still match, so the branch still prints `✅ Intact` while silently dropping every
  census counter. That is precisely the WR-09-class silent coupling break the surrounding comment
  block exists to prevent.
- `beets/config.yaml:16` still reads "**IT DOES NOT EXIST AT THIS COMMIT.** Until 04-10 lands,
  nothing detects divergence between this file and the host." The drift block exists at
  `quick-health-check.sh:630-743`, is promoted (`VENDORED_DRIFT_PROMOTED=1` at `:357`), and hashes
  this exact file at `:689`.
**Fix:** rewrite all three to the present tense in one commit, following the file's own withdrawal
convention (paraphrase the withdrawn claim so a mechanical grep for it keeps returning zero). For
`:1007-1010`:
```bash
    # The six Phase 4 tokens on the last two lines select section 6b's census counters. 6b is
    # PROMOTED (TAGGER_CENSUS_PROMOTED=1) and prints those counters on every routine run, so these
    # tokens are LIVE. Removing one does not fail this block — SUMMARY stays non-empty and the tick
    # still prints — it silently drops a counter from the output. Change both files together.
```

#### WR-06: `normalise-dj-tags.py` double-counts skipped files, so the summary does not reconcile

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/normalise-dj-tags.py:1161`, `:1188`, `:1206`
**Issue:** `counts["skipped"] += 1; continue` at `:1161-1163` leaves the *rule* loop only; the emit
loop at `:1203` then iterates `loaded` again, finds no proposal, and adds `counts["unchanged"] += 1`
at `:1206`. The same file lands in both buckets. Rule 3 is worse: `:1188` charges
`len(loaded)` to `skipped` for the whole folder, on top of any per-file rule-1 skips, and every one
of those files is *also* counted unchanged or changed. `files_seen` (`:1105`) therefore never equals
`changed + unchanged + skipped + failed` in either mode, and the dry run **is** the D-08 review
artefact whose `.summary.json` (`:1264-1279`) a later reader will quote.
**Fix:** unchanged — track skip state per path, make the buckets disjoint, and assert the invariant
before writing the summary:
```python
skipped_paths: set[str] = set()
# :1160  if derived is None:  skipped_paths.add(path); log.warning(...); continue
# :1187  if not chosen:       skipped_paths.update(p for p, _h, _v in loaded); log.warning(...)
# :1205  if not fields:       counts["skipped" if path in skipped_paths else "unchanged"] += 1; continue
assert counts["files_seen"] == counts["changed"] + counts["unchanged"] + counts["skipped"] + counts["failed"]
```

#### WR-07: `check-renovate.sh` reports `1` for three empty sets — the exact defect it fixed elsewhere

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/check-renovate.sh:84`, `:97`, `:112`; consumed at `:200-202`
**Issue:** `$(echo "$X" | wc -l | tr -d ' ')` counts the newline `echo` emits for an empty string.
Re-verified: `echo "" | wc -l` → `1`. So zero compose files, zero image-bearing YAMLs and zero
unique images each report `1`. The file already knows this pattern is wrong — `POSTGRES_COUNT`
(`:123`), `REDIS_COUNT` (`:146`) and `RENOVATE_COUNT` (`:168`) were deliberately converted to
`awk 'NF{n++} END{print n+0}'` for exactly this reason, with the rationale written at `:121-122`
and `:165-167`. Three call sites were missed.
**Fix:** unchanged — apply the form the file already standardised on:
```bash
COMPOSE_COUNT=$(printf '%s\n' "$COMPOSE_FILES"       | awk 'NF{n++} END{print n+0}')
IMAGE_FILE_COUNT=$(printf '%s\n' "$YAML_WITH_IMAGES" | awk 'NF{n++} END{print n+0}')
IMAGE_COUNT=$(printf '%s\n' "$IMAGES"                | awk 'NF{n++} END{print n+0}')
```

#### WR-08: `avail_gb()`'s documented "could not read df" branch is unreachable under `set -e`

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/spike03-image-headroom.sh:171-176`; consumed at `:249`, `:265-266`, `:335`,
`:365`, `:451`, `:470-475`
**Issue:** `set -euo pipefail` at `:100`. `b="$(df -B1 --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')"`
at `:173` is a standalone assignment, so `pipefail` propagates a `df` failure to the assignment and
`set -e` terminates the script before the `[ -z "$b" ]` guard at `:174` is reached. The
`could not read available GiB from df - UNKNOWN, not healthy` branch at `:266`, and the
`the floor is UNKNOWN, not met` failure at `:471` — the two sites that uphold "could not look ≠
healthy" for the OD-1 floor — cannot fire. A `df` failure exits with a bare non-zero status and no
explanation instead. (Note the split declaration matters: `local b="$(...)"` would mask the status;
`local b` then a separate assignment does not.)
**Fix:** unchanged — make the failure explicit inside the function so the guard is reachable:
```bash
avail_gb() {
  local b=""
  b="$(df -B1 --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')" || b=""
  [ -z "$b" ] && return 0
  printf '%s' "$(( b / 1073741824 ))"
}
```

#### WR-09: A down Traefik still exits `quick-health-check.sh` with 0 — and this now has a live transcript

**Status:** STILL OPEN. Line numbers shifted; behaviour unchanged.
**File:** `scripts/quick-health-check.sh:524-532`, `:535-540`, `:623-628` (was 463-471, 474-479,
562-567)
**Issue:** All three blocks print `❌ Not running` / `❌ Not accessible` without touching
`EXIT_CODE`. The estate's single health-check entry point therefore exits 0 — "healthy" to any
caller reading the status rather than the transcript — with Traefik down, which takes every
`*.deercrest.info` service with it. The file documents this at `:513-523` and explicitly declines to
fix it.
**New evidence promoting this from theoretical to observed:** the quick task's own summary records
that on the green routine run, `Traefik dashboard: ❌ Not accessible` printed while the script
exited 0 (`260914-a2y-SUMMARY.md:175-177`, `…-negative-controls.txt:154-164`). A red glyph is
currently sitting in the transcript of a check that reports success, on every run.
**Fix:** unchanged — capture the status and branch, the shape the container-count sites at
`:575-588` already use:
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

#### WR-10: `bounded_ssh` recreates a deleted `mktemp` path, reintroducing the race `mktemp` exists to close

**Status:** STILL OPEN. Line numbers shifted (was 378-392).
**File:** `scripts/quick-health-check.sh:439-453` (the `rm -f` at `:444`, the write-back at `:446`,
the guessable fallback at `:443`)
**Issue:** The sentinel is created safely with `mktemp -t qhc-bound`, immediately `rm -f`'d, then
written back by the watchdog (`: > "$sentinel"`). Between the `rm` and the write the path is
predictable and unowned, so anything able to create a file there can pre-place a symlink and
redirect the truncating write. The fallback is worse —
`"${TMPDIR:-/tmp}/qhc-bound.$$.$RANDOM"` is guessable and used unguarded whenever `mktemp` is
unavailable. Impact is low in practice (macOS gives each user a private `TMPDIR`; the script is run
interactively by its owner), but it is a needless reintroduction of a closed hole in a file that
otherwise reasons carefully.
**Fix:** unchanged — keep the file and use its *content* as the sentinel rather than its existence:
```bash
sentinel=$(mktemp -t qhc-bound) || { echo "cannot create sentinel"; return 1; }
"$@" </dev/null & cmd_pid=$!
{ sleep "$secs"; printf 'timeout' > "$sentinel"; kill -TERM "$cmd_pid" 2>/dev/null; } & watch_pid=$!
wait "$cmd_pid" 2>/dev/null; rc=$?
kill -TERM "$watch_pid" 2>/dev/null; wait "$watch_pid" 2>/dev/null
[ -s "$sentinel" ] && BOUNDED_SSH_TIMED_OUT=1
rm -f "$sentinel"
```

#### WR-11: The D-10 side-effect inventory still omits the `rm -rf` branch — CR-01's documentation half was not done

**File:** `stacks/selfhosted/arrs/sabnzbd.yaml:121-133`
**Issue:** CR-01's fix had two halves: the standing assertion (delivered, `quick-health-check.sh:805-934`)
and "amend the `sabnzbd.yaml:121-133` D-10 inventory to name the `rm -rf` branch explicitly, since
that block is the document a future reader will trust." The second half was not done and is not
recorded anywhere as a declined decision — the quick task's `decisions:` list
(`260914-a2y-SUMMARY.md:23-27`) does not mention it.

The block still reads, at `:127-129`, that "the `beets()` body still logs 'Matching N tracks with
Beets' and then 'ERROR: Unable to match…' (both are EXPECTED after the strip …) and still removes
`library.blb` behind an existence guard" — an inventory of that function's surviving behaviour that
enumerates two log lines and a `library.blb` unlink while omitting the `rm -rf "$1"/*` sitting three
lines below them in the same `else`. `grep -n 'rm -rf' stacks/selfhosted/arrs/sabnzbd.yaml` returns
exactly one hit, `:125`, and it is about `verify()`, not `beets()`. A reader reconstructing the
post-strip behaviour from the authoritative in-repo note comes away believing the branch only logs.
**Fix:** extend `:127-129` in place (do **not** touch `audio.bash`, whose byte-identity is asserted
by the drift block):
```yaml
      # ... and the beets() body still logs "Matching N tracks with Beets" and then
      # "ERROR: Unable to match…". BOTH ARE NOW UNCONDITIONAL: the strip removed the only
      # writer that could make a file newer than the /config/scripts/beets-match sentinel, so
      # the SUCCESS branch at audio.bash:286 is structurally unreachable and the else at :287
      # is taken on every music job. THAT else CONTAINS `rm -rf "$1"/*` AT :290, gated solely
      # by requireBeetsMatch in the container's /config/extended.conf — a file this repo does
      # NOT vendor (it carries five *ArrApiKey fields and this repo is public). The value is
      # asserted instead, on every run, by the "extended.conf destructive switches" block in
      # scripts/quick-health-check.sh. conversion() has the same shape (WR-01) at :237.
```

#### WR-12: `beets.md`'s criterion-1 evidence command resolves to nothing when run

**File:** `stacks/selfhosted/arrs/beets.md:1224`
**Issue:** The closing acceptance table cites, as the evidence for criterion 1, the command
`git ls-files stacks | grep -lE '^\s*image:\s*(beets|wrtag|soulbeet|beets-flask)'` and states it
"resolves to exactly `stacks/selfhosted/arrs/beets/beets.yaml`". Run verbatim, it resolves to
**nothing** — exit 1, no output — because the repo's only tagger line is
`image: lscr.io/linuxserver/beets:2.13.1-ls349` (`beets/beets.yaml:6`), which does not begin with
`beets`. The census in `check-music-freeze.sh:711` gets the right answer because it uses a
*different*, registry-qualified pattern that the doc does not quote.

The stated outcome is correct and the criterion genuinely holds; the *instrument* recorded beside
it does not reproduce it. That is the failure mode this estate's own doctrine names — a claim that
looks twice-confirmed because a command is printed next to it, where re-running the command gives
zero and a reader would reasonably conclude the census is broken rather than the doc.
**Fix:** quote what the census actually runs, so the two cannot drift:
```markdown
| **1 — one tagger definition** | `git ls-files stacks \| xargs grep -lE '^[[:space:]]*image:[[:space:]]*(lscr\.io/linuxserver/beets\|sentriz/wrtag\|ghcr\.io/terry90/soulbeet\|metasauce/beets-flask)'` resolves to exactly `stacks/selfhosted/arrs/beets/beets.yaml` — the same pattern `check-music-freeze.sh:711` asserts on; the census counts `tagger definitions: 1` … |
```
(Verified: that form returns the single expected path.) Note this row's pattern is also subject to
WR-04 — fix both in the same commit so the doc keeps quoting the live pattern.

#### WR-13: `spike03-discogs-probe.py --verbose` sets the **root** logger to DEBUG, inside the function whose docstring says it does not

**File:** `scripts/spike03-discogs-probe.py:480`, claimed otherwise at `:463-471` and `:228-231`,
exposed at `:952`, `:963`
**Issue:** `configure_logging()`'s own docstring at `:465-466` states: "A root-level DEBUG would
enable DEBUG for every library in the process. This turns DEBUG on for exactly one logger." Four
lines later, `:480` reads `root.setLevel(logging.DEBUG if verbose else logging.INFO)` — which is a
root-level DEBUG for every library in the process whenever `--verbose` is passed, and `--verbose`'s
own help string at `:952` advertises exactly that ("DEBUG on the root logger too"). The SECURITY
section at `:228-231` rests the same argument on `logging.basicConfig`, which is narrowly true (the
file never calls it) while the stated *reason* — process-wide DEBUG — is defeated by `:480`.

The redaction is on the handler (`:477`) rather than only the logger, so tokens in *rendered
messages* stay redacted through this path, and `http.client.HTTPConnection.debuglevel` is genuinely
never set — so this is not a live credential leak today. It is Warning rather than Info because the
file's own SECURITY block is what a future reader will use to decide whether a new library's DEBUG
output is safe here, and that block currently asserts a property the code does not have. This is
the same defect class as WR-05.
**Fix:** either drop the root-level escalation and keep the claim, or correct the claim and say what
still holds:
```python
    # `--verbose` raises the ROOT logger to DEBUG, which DOES enable DEBUG for every library in
    # the process — the one thing this docstring used to say it never did. It is kept because the
    # redaction choke point is the HANDLER (below), so any record reaching stderr is scrubbed
    # whatever logger emitted it. What is NOT enabled, ever, is
    # http.client.HTTPConnection.debuglevel, which would log request HEADERS and is not covered by
    # the query-string net. Do not set it.
    root.setLevel(logging.DEBUG if verbose else logging.INFO)
```

### Info

#### IN-01: `sqlite3` is load-bearing in §6b but absent from the §0 toolchain preconditions

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/check-music-freeze.sh:296` (the tool list), `:768` (the dependency)
**Issue:** §6b classifies every candidate database with `sqlite3 "file:${p}?mode=ro" '.tables'` at
`:768`. §0 asserts `ffprobe ffmpeg jq gzip sha256sum` and not `sqlite3`. If `sqlite3` is missing,
every candidate falls into `UNCLASSIFIED_DBS` as "SQLite header but unreadable" (`:770`) and the run
fails red — correct direction, wrong answer: the reader is told the databases are unreadable rather
than that the tool is absent.
**Fix:** add `sqlite3` to the `for t in …` list at `:296`.

#### IN-02: `check-renovate.sh` omits `--strict`, and computes a version it never uses

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/check-renovate.sh:66`, `:129`
**Issue:** (a) the standing check runs `renovate-config-validator --no-global` while the recorded
acceptance evidence for criterion 2 (`beets.md:1225`) was taken with `--strict --no-global` — the
guard is weaker than the criterion it keeps true. (b) `VERSION=$(echo "$img" | grep -oE ':[0-9]+' | …)`
at `:129` is assigned and never referenced.
**Fix:** add `--strict` to `:66`; delete the `:129` assignment or print it in the row below.

#### IN-03: Operator-supplied env vars are interpolated unvalidated into a remote root shell string

**Status:** STILL OPEN, and now with two more variables (see IN-08).
**File:** `scripts/quick-health-check.sh:368` / `:687-689` (`DRIFT_APPDATA_ROOT`), `:331` / `:525`
etc. (`REMOTE_TIMEOUT`)
**Issue:** `DRIFT_APPDATA_ROOT` is pasted into a double-quoted command string executed as root over
ssh; a value containing `"` and `;` becomes remote command injection. Self-injection by the operator
on their own workstation, and the override already forces `EXIT_CODE=1` so it cannot manufacture a
green — hence Info. `REMOTE_TIMEOUT` is the same shape.
**Fix:**
```bash
case "$DRIFT_APPDATA_ROOT" in ""|*[!a-zA-Z0-9/_.-]*) echo "refusing unsafe DRIFT_APPDATA_ROOT"; exit 2 ;; esac
case "$REMOTE_TIMEOUT" in ''|*[!0-9]*) echo "refusing non-numeric REMOTE_TIMEOUT"; exit 2 ;; esac
```

#### IN-04: The §2 Jellyfin exemption is file-scoped, not path-scoped

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/check-music-freeze.sh:447`
**Issue:** `[[ "$f" == "stacks/selfhosted/media/jellyfin.yaml" ]] && continue` exempts *every* rw row
in that file, so a second, narrower Music-reaching mount added to `jellyfin.yaml` is invisible.
**Fix:** exempt the mapping, not the file:
`[[ "$f" == "stacks/selfhosted/media/jellyfin.yaml" && "$mapping" == "/mnt/tank/media:/media:rw" ]] && continue`

#### IN-05: A failed write still prints a change line to the review artefact

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/normalise-dj-tags.py:1208-1234`
**Issue:** The `path :: field: old -> new` lines are written to stdout at `:1210-1212` before
`write_tags()` is attempted at `:1216`. Under `--apply`, a file whose write raises is correctly
routed to `.failed` and excluded from the NDJSON, but its change line has already been emitted. A
reader diffing stdout against the tree sees a change that never happened.
**Fix:** buffer the stdout lines in apply mode and emit them after the write succeeds, or append a
`(FAILED)` marker on the error path at `:1220`.

#### IN-06: Two upstream nits in the vendored hook, recorded not fixed

**Status:** STILL OPEN. Unchanged, and correctly so — `audio.bash` must stay byte-identical.
**File:** `stacks/selfhosted/arrs/sabnzbd/audio.bash:276-279`, `:289`
**Issue:** `:276` tests `/config/scripts/beets/beets.log` but `:277` removes
`/config/scripts/beets.log` — the guard can never fire for the path it deletes. `:289` uses an
unquoted `[ $requireBeetsMatch = true ]`; an unset variable makes `[` error rc 2, which an `if`
reads as false, so it lands safe **by accident**. Both are upstream; neither should be edited in
place while the drift block asserts byte-identity.
**Fix:** carry both in the TO UPDATE notes at `:23-24` so they are re-applied if upstream is ever
re-vendored. (The new guard at `quick-health-check.sh:790-793` already refuses to rely on the
accidental safety, which is the right treatment for `:289`.)

#### IN-07: `--sidecars` emits a blank line when the sidecar set is empty

**Status:** STILL OPEN. Unchanged.
**File:** `scripts/check-music-freeze.sh:620`
**Issue:** `printf '%s\n' "$SIDECARS" >&3` writes a single newline when `SIDECARS` is empty, so a
redirected list file holds one blank line rather than being zero-byte. A consumer counting lines
reads 1 where the truth is 0 — the same family as WR-07.
**Fix:** `[[ -n "$SIDECARS" ]] && printf '%s\n' "$SIDECARS" >&3`

#### IN-08: The two new `EXTCONF_*` overrides extend the IN-03 injection surface, one of them into `ssh`'s own argv

**File:** `scripts/quick-health-check.sh:384-385`, consumed at `:827` and `:847`
**Issue:** Two shapes, both operator self-injection and both already forcing `EXIT_CODE=1`
(`:807-816`), so neither can launder a red into a green — hence Info, consistent with IN-03.
(a) `EXTCONF_PATH` is interpolated into a single-quoted remote string at `:827`
(`sh -c 'cat "$EXTCONF_PATH"'`); a value containing `'` closes the quote and runs arbitrary
commands as root on LXC 100. (b) `EXTCONF_HOST` is passed as ssh's first positional at `:847`, so a
value beginning `-o` is parsed as an ssh **option** — `EXTCONF_HOST='-oProxyCommand=...'` executes
on the workstation, before any remote connection.
**Fix:** validate both at definition, alongside the IN-03 checks:
```bash
case "$EXTCONF_PATH" in /*) : ;; *) echo "EXTCONF_PATH must be an absolute container path"; exit 2 ;; esac
case "$EXTCONF_PATH" in *[!a-zA-Z0-9/_.-]*) echo "refusing unsafe EXTCONF_PATH"; exit 2 ;; esac
case "$EXTCONF_HOST" in -*|*[!a-zA-Z0-9@._-]*) echo "refusing unsafe EXTCONF_HOST"; exit 2 ;; esac
```

#### IN-09: `beets.md`'s "What keeps these true" still names two standing guards; there are now three

**File:** `stacks/selfhosted/arrs/beets.md:1230-1245`
**Issue:** The phase's closing record enumerates the standing guards that keep the five criteria
true — `check-music-freeze.sh` §6b and the vendored-file drift block — and says "Two standing
guards". Since `c0b04c3` there is a third promoted fatal block, the extended.conf destructive-switch
assertion, and it is the only thing standing between a config edit and an `rm -rf` of every
completed music download. `grep -n 'destructive switch\|fifth fatal\|EXTCONF\|260914-a2y' beets.md`
returns nothing. The quoted routine run at `:1244` is also the pre-fix one (2026-09-13T12:39:12Z,
before the block existed).
**Fix:** add a third bullet naming `scripts/quick-health-check.sh`'s
`extended.conf destructive switches` block, what it asserts (`requireBeetsMatch=false`,
`ConversionFormat ∈ {FLAC, OPUS}`), and why (`audio.bash:290` and `:237`), and re-quote the routine
run from the 2026-09-14 green transcript.

#### IN-10: Unused loop variable in `spike03-image-headroom.sh`

**File:** `scripts/spike03-image-headroom.sh:296`
**Issue:** `local line name id size bytes` — `line` is declared and never referenced anywhere in
`do_inventory()`. Dead declaration; harmless, but it invites a reader to look for a `$line` that
does not exist.
**Fix:** `local name id size bytes`

## Already Closed Since Previous Review

Verified against the code on disk, not against the commit messages. Do **not** re-apply these.

| Id | Status | Closed by | Evidence |
|---|---|---|---|
| **CR-01** — stripping the `beet` call made `audio.bash`'s destructive failure branch unconditional, guarded only by an unversioned host file | **CLOSED** at the guard layer | `c0b04c3` | `scripts/quick-health-check.sh:805-934` — the "extended.conf destructive switches" block. Overrides at `:384-385`; both force `EXIT_CODE=1` when non-default (`:807-816`). Remote read with distinct exit codes at `:822-846` (3 = container absent, 4 = unreadable, 6 = empty, 124 = bound). Fail-closed branches at `:849-895` (empty-first-deferring-to-124, then 124, then any non-zero, then short-answer). Per-switch verdicts at `:902-928`, each setting `EXIT_CODE=1`. Announced by the sixth notice at `:196-241`; tail enumeration updated in the same commit at `:1214-1221`. Reachability confirmed: the block sits after both early-exit probes (`:457-495`) and executes on every routine run. Notice arithmetic re-verified — 6 notice headers (lines 4, 29, 55, 135, 156, 196), `grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` = 7, exactly as `:199-211` claims. `bash -n` passes. Negative controls driven under a trap, live config sha256 identical at open and close (`260914-a2y-negative-controls.txt:13`, `:100`). **Residue:** the documentation half of the prescribed fix is not done — see `WR-11`; and the guard has a false-green mode — see `CR-02`. **Caveat worth carrying:** detection is manual-only, per this file's own KNOWN LIMIT at `:243-265`; nothing schedules it. |
| **WR-01** — `conversion()` deletes the download folder for every non-`OPUS` format; the `ffmpeg` block is unreachable | **CLOSED** by the same block | `c0b04c3` | `scripts/quick-health-check.sh:841` asserts `ConversionFormat ∈ {FLAC, OPUS}` and `:915-921` names `audio.bash:237` and the dead `:242-255` explicitly. The widening from the review's `FLAC`-only snippet to `{FLAC, OPUS}` is correct and I verified it against the source: `audio.bash:220` short-circuits FLAC before the loop and `:226-234` handles OPUS via `opusenc` without reaching the `rm -rf` at `:237`. A `FLAC`-only assertion would have false-redded a correct OPUS estate. Rationale recorded at `:780-783`. Driven by control 2 (`…-negative-controls.txt:53-64`). **Subject to the same `CR-02` false green.** |
| *(non-finding, recorded for the fixer)* | `ReplaygainTagging` deliberately **not** asserted | — | Declined as a scoped decision, not an oversight, at `scripts/quick-health-check.sh:774-778`: it gates a tag writer (`audio.bash:266`), not an `rm -rf`. `beets.md:1272-1281` independently corroborates that `replaygain()` did not run (0 `REPLAYGAIN_*`/`R128_*` keys across 25 files). Do not treat its absence from the guard as an unfixed part of CR-01. |
| *(non-finding, recorded for the fixer)* | The "defective Task 3 gate" and the "key-name grep finding" from `220dcf4` | — | Both are defects in the **plan's own acceptance greps**, not in shipped source. The Task 3 gate is `grep -c 'extended.conf'` with an unescaped `.` matching the task's own `…-assert-extended-conf-…` directory name (`…-negative-controls.txt:167-190`). I confirmed the underlying property holds independently: no file named `extended.conf` exists in this repo or in `c0b04c3`. The two switch **key names** used by the shipped guard (`requireBeetsMatch`, `ConversionFormat`) are correct and match the live file — proven by the green routine run at `…-negative-controls.txt:160`. No source fix is required for either. |

---

_Reviewed: 2026-09-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
_Prior review: `git show f39e417:.planning/phases/04-collapse-to-one-tagger/04-REVIEW.md` (1 critical, 10 warning, 7 info)_
