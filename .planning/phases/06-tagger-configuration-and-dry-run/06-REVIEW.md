---
phase: 06-tagger-configuration-and-dry-run
reviewed: 2026-09-21T22:33:04Z
depth: standard
diff_base: db281a2
files_reviewed: 11
files_reviewed_list:
  - scripts/phase06-oracle.sh
  - scripts/phase06-incremental-control.sh
  - scripts/check-beets-config.sh
  - scripts/check-music-consumers.sh
  - scripts/quick-health-check.sh
  - scripts/check-music-freeze.sh
  - stacks/selfhosted/arrs/beets/config.yaml
  - stacks/selfhosted/arrs/beets/flask.yaml
  - stacks/selfhosted/arrs/beets/flask-config.yaml
  - stacks/selfhosted/arrs/beets/beets.yaml
  - stacks/selfhosted/arrs/compose.yaml
findings:
  critical: 1
  warning: 10
  info: 13
  total: 24
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-09-21T22:33:04Z
**Depth:** standard (per-file analysis, language-specific shell checks, cross-file where the assertions couple)
**Files Reviewed:** 11 (6 shell, 5 YAML)
**Status:** issues_found

## Summary

~5,000 new lines of assertion shell plus a rewritten beets config. The craft level is high:
`shellcheck -S warning` is clean on all three new scripts, `bash -n` passes on all six, every
YAML parses, both `--self-test` harnesses run green locally, the three-outcome
identical/CHANGED/COULD-NOT-COMPARE vocabulary is used consistently, secrets never reach argv
(`-H @<(printf …)`, `$ENV.` in jq, no `set -a`), and the house "UNKNOWN, not green" string is
used correctly on essentially every remote-status branch.

The defects are concentrated in exactly the place the phase said to look: **predicates that
cannot fire.** One of them is a check that asserts over an empty set and has a live violation
sitting in the repo that it cannot see. Three more are vacuity gaps of the same family that the
sibling script in the same phase already guards against, which is what makes them provable
rather than stylistic.

Verified rather than asserted:

- `git grep -n -I -w -E 'beet' HEAD -- scripts stacks` reproduced locally: **91 raw / 35
  comment-stripped / 2 invocation-shaped, both `.md`**. The executable set D-04 asserts over is
  **empty**.
- `/bin/sh -c 'ls -A /nonexistent | head -n 1; echo rc=$?'` → `rc=0`, confirming CR/WR-01.
- `bash scripts/check-beets-config.sh --self-test` → exit 0, 5/5 cases.
- `bash scripts/phase06-oracle.sh --self-test` → exit 0, every branch as expected.
- All five YAML files `yaml.safe_load` cleanly; `paths:` key order is
  `singleton, albumtype:=dj disctotal:2.., albumtype:=dj, disctotal:2.., comp, default` — i.e.
  the order the config's own comment claims is load-bearing is actually the order on disk.

The five `DEF-06-*` items in `deferred-items.md` and the documented repo-wide SC2034/SC2155
baseline are **not** re-reported below.

---

## Critical Issues

### CR-01: The D-04 "no bare `beet` invocation" assertion asserts over an empty set, and a live violation sits in the repo that it structurally cannot see

**File:** `scripts/quick-health-check.sh:1449-1594` (the pattern at `:1551`, the count at `:1557`, the green line at `:1590`)
**Also:** `scripts/check-beets-config.sh:769`, `:785`, `:796`

**Issue:**

The block's stated contract is: *"No invocation-shaped `beet` line in an executable file tracked
under `scripts/` or `stacks/` may run without BOTH a `-l` outside `/config/library.db` AND a `-c`
overlay."* It implements that by text-matching the literal token `beet` :

```
D04_INV_RE='^HEAD:[^:]*:[0-9]*:[[:space:]]*(sudo[[:space:]]+)?beet[[:space:]]|[[:space:]](&&|;)[[:space:]]*beet[[:space:]]|docker[[:space:]][^`]*[[:space:]]beet[[:space:]]'
```

I reran the exact remote scan against `HEAD` on this workstation:

```
raw = 91   comment-stripped = 35   invocation-shaped = 2
  HEAD:stacks/selfhosted/arrs/beets.md:106:docker exec -it beets beet import "..."
  HEAD:stacks/selfhosted/arrs/beets.md:170:beet import -A --flat "..."
```

Both hits are `.md`. `D04_N_EXE` is **0**. The per-line loop at `:1559-1571` iterates over an
empty string, `D04_BAD` stays 0, and `:1590` prints
`✅ no executable beet invocation opens the real library (0 invocation-shaped lines outside *.md)`.
There is no branch anywhere in the block that treats `D04_N_EXE == 0` as suspicious — even
though the block **does** apply exactly that reasoning one screen earlier to the raw count
(`:1542`: *"a zero here means the pattern is wrong, not that the tree is clean"*) and to the
comment strip (`:1547`). The one count that matters got no such guard.

It is empty because every `beet` invocation this phase added is assembled from a variable, so the
literal token never appears on the line:

- `scripts/phase06-oracle.sh:1970` — `rsh "$(dex_cmd "$BEET_BIN" -c … import -A -q …)"`
- `scripts/phase06-oracle.sh:1983` — `… "$BEET_BIN" -c … move -p`
- `scripts/phase06-oracle.sh:2102` — `… "$BEET_BIN" -c … ls -f …`
- `scripts/phase06-incremental-control.sh:419`, `:421` — `"$BEET" -c "$ROOT/overlay.yaml" import …`
- `scripts/check-beets-config.sh:769`, `:785`, `:796` — `beet_exec "${BEET_BIN} -c ${OVERLAY} config …"`

And the last three are a **real violation of the rule the block exists to enforce**:
`check-beets-config.sh` runs `${BEET_BIN} -c ${OVERLAY} config -d` (and `config -p -d`, and
`config -d -c`) with **no `-l` at all**, against the real `/config/library.db`. beets opens the
library for `config` — that is the very measurement the rule is built on (`beets.yaml:71-78`:
*"Phase 1 measured a bare `beet config` running 11 migrations unasked"*). The estate is not
currently harmed, because that `beet` is the flask container's 2.12.0 — the same engine that
wrote the database — and the script hashes `library.db` before and after (D-29 layer 3). But the
detector reports a clean tree while the tree is not clean by its own definition, and the day
someone adds a variable-built invocation in the 2.13.1 CLI arm it will report clean again.

Per the block's own standard (`:1542`), a scan whose asserted set is empty "means the pattern is
wrong, not that the tree is clean".

**Fix:** three parts, all cheap.

1. Add the missing vacuity guard, in the same shape as the two that already exist:

```sh
elif [ "$D04_N_EXE" -eq 0 ]; then
    echo "  ⚠️  UNKNOWN — the invocation pattern matched ZERO executable lines. Every beet"
    echo "  invocation in this repo is built from a variable (\$BEET_BIN / \$BEET), so a zero"
    echo "  here means the pattern cannot see them, not that none exist. Nothing is asserted."
    EXIT_CODE=1
```

2. Widen the pattern to the variable form as well, e.g. add the alternation branch
   `[[:space:]]"?\$\{?BEET[A-Z_]*\}?"?[[:space:]]` (it carries no `|` problem the existing
   alternation does not already carry).

3. Either add `-l /tmp/p6-throwaway.blb` to the three `beet_exec` calls in
   `check-beets-config.sh`, or record an explicit, named exemption for them in the block —
   silence is the one option that should not survive.

---

## Warnings

### WR-01: An in-container pipeline makes an unreadable scratch directory read as "absent or empty"

**File:** `scripts/phase06-oracle.sh:1843`

**Issue:** The file's own house-rules block (`:185-186`) states:

> THE CONTAINER'S /bin/sh IS dash AND HAS NO `pipefail`. So no command sent INTO the container
> carries a pipeline at all; each exit status is read explicitly on the LXC side instead.

Line 1843 is the one line in the file that breaks that rule, and it breaks it in the precheck
whose entire job is to refuse:

```sh
rsh "$(dex_cmd sh -c "'[ ! -e $SCRATCH ] && echo absent || ls -A $SCRATCH | head -n 1'")"
```

Confirmed with `/bin/sh -c 'ls -A /nonexistent | head -n 1; echo rc=$?'` → `rc=0`. If `$SCRATCH`
exists but is not readable by `beetle` (e.g. left root-owned 0700 by an aborted run), `ls` fails,
`head` exits 0, the pipeline exits 0, `RSH_OUT` is empty, the `RSH_RC -ne 0` guard at `:1844`
does not fire, the `[ -n "$RSH_OUT" ]` guard at `:1847` does not fire, and the script prints
`✓ container scratch '/tmp/p6' is absent or empty`. A "could not look" has been reported as the
green answer — the exact thing the header forbids.

Blast radius is limited (the `cp` at `:1920` fails closed afterwards, and `ls`'s stderr is
visible on the operator's terminal), which is why this is a Warning rather than a Critical.

**Fix:** split it, the way every other remote read in the file is split:

```sh
rsh "$(dex_cmd sh -c "'if [ ! -e $SCRATCH ]; then echo absent; exit 0; fi; ls -A $SCRATCH > /tmp/p6.ls'")"
# then read /tmp/p6.ls in a second bounded call, or use `find $SCRATCH -mindepth 1` with its rc read
```

### WR-02: The oracle's `manifest_compare` has no empty-file guard — two empty manifests report "identical before and after"

**File:** `scripts/phase06-oracle.sh:288-328` (contrast `scripts/phase06-incremental-control.sh:186`)

**Issue:** The oracle's `manifest_compare` validates `-e`, `-f`, `-r` and then diffs. The sibling
script written in the same phase validates one more thing, and says why in band:

```sh
if [ ! -s "$f" ]; then DIFF_WHY="manifest '$f' is EMPTY - an empty listing compares equal to any
other empty listing, which would pass vacuously"; return 2; fi
```

The oracle has no such line. `capture_manifests` (`:1102-1125`) builds each manifest with
`: > file` followed by appends, and `remote_manifest_meta` is
`find <dir> -type f -printf …` — which on an existing but empty directory returns **rc 0 and no
output**. So `RSH_RC` is 0, the file is legitimately empty, and `diff_manifest src meta` prints
`✓ layer 2 (src.meta manifest): identical before and after`. Layer 2 of the three-layer
wrote-nothing proof would be satisfied by having measured nothing.

In a full `--run` the positive control at `:2004` would separately fire (zero pairs), so this is
masked today — but `--baseline` exits at `:1913` before any of that, and the masking is
incidental rather than designed.

**Fix:** copy the sibling's guard verbatim into `manifest_compare` at `scripts/phase06-oracle.sh:305`.

### WR-03: The D-22 artist-entity rows cannot fail the run — `check-music-consumers.sh` exits 0 and prints the green banner while CONF-04 is measurably open

**File:** `scripts/check-music-consumers.sh:1304` and `:1408` (the `warn` branches), `:1587-1601` (the exit path)

**Issue:** `warn()` (`:479`) prints and returns; it does not touch `FAILURES`. The Jellyfin
baseline branch (`JELLYFIN_ARTIST_PENDING`) and the MA baseline branch (`MA_ARTIST_PENDING`) both
use `warn`, and neither counter is consulted by the exit logic. With every row at its recorded
baseline — which is the state `06-14-SUMMARY.md` records today (JF 0/4, 1/2, 1/2) — the script
prints a yellow "CONF-04 IS NOT CLOSED" line and then:

```
✅ Both music consumers see the pinned albums through the NFS export
```

…and exits **0**.

The intent (a three-state drift detector, pending ≠ red) is defensible and well argued in band.
The defect is that the state is invisible to the only machine-readable output the script has.
`quick-health-check.sh` folds this script in and propagates its exit status; a run in which
`PreferNonstandardArtistsTag` reverts to `false` *after* Phase 7 has discharged it will land the
rows back on their baseline and exit 0 again — the regression detector will be reporting the
regression in yellow text nobody's tooling reads. (Note the D-34 option read at `:1221`/`:1225`
does it right: `jellyfin_fail`.)

**Fix:** introduce a third exit code rather than folding pending into green, e.g.:

```sh
if [[ $FAILURES -gt 0 ]]; then ... exit 1; fi
if [[ $(( JELLYFIN_ARTIST_PENDING + MA_ARTIST_PENDING )) -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  CONF-04 IS NOT CLOSED ...${NC}"
  exit 3          # documented: measured-but-not-at-target; never green
fi
```

…and move the green banner below that gate so it can no longer print over a non-zero pending count.

### WR-04: `touch` does not truncate — arm 2's "no-op overlay" is only no-op if nothing else wrote to it

**File:** `scripts/check-beets-config.sh:765`

**Issue:**

```sh
beet_exec "touch ${OVERLAY}"     # OVERLAY=/tmp/phase06-check-beets-config-noop.yaml
```

with the comment three lines above stating *"empty is the only value that leaves arm 2 an honest
reading"*. `touch` guarantees existence, not emptiness. `/tmp` inside the container is
world-writable and the path is fixed and predictable; a file left there by an earlier aborted
run, or written by anything else in the container, sits **above** the vendored config in
confuse's priority order and silently rewrites arm 2's answer. The script reports arm 2 rather
than asserting from it, so this is not a false green on any assertion — but the whole value of
the D-30 two-arm comparison is that arm 2 is an honest reading of what the container assembles.

Secondary: the header at `:8-14` says *"READ-ONLY BY CONTRACT. Every remote invocation is a read
… nothing is written."* This line writes a file into the container, and nothing removes it.

**Fix:** `beet_exec "sh -c ': > ${OVERLAY}'"` (or `truncate -s 0`), verify size 0 in the same
call, and amend the header's "nothing is written" claim to name the one exception.

### WR-05: `check-beets-config.sh` opens the real `library.db` three times per run with no `-l`

**File:** `scripts/check-beets-config.sh:769`, `:785`, `:796`

**Issue:** Each of these is `${BEET_BIN} -c ${OVERLAY} config …` with no `-l`, so the effective
`library:` is the vendored `/config/library.db` — the real one. `beet` opens the library for
every subcommand including `config`; that is precisely the measurement D-04 is built on
(`stacks/selfhosted/arrs/beets/beets.yaml:71-78`). The rule as written in three separate places
in this repo is "BOTH `-l` and `-c`, always".

Mitigations that are real and should be stated alongside the finding: the binary is the flask
container's beets **2.12.0**, i.e. the same engine that owns the schema, so no migration occurs;
and the script hashes `library.db` and `state.pickle` either side of the run and fails on any
change (`:709-711`, `:811-820`). So this is a rule violation with a working compensating control,
not an active data-integrity incident. It is listed separately from CR-01 because CR-01 is about
the detector and this is about the violation — and because the detector cannot see it.

**Fix:** add `-l /tmp/p6-cbc-throwaway.blb` to all three invocations (the hashes then prove the
real DB was never opened rather than merely never changed), or record a named exemption in the
D-04 block so it is a decision rather than an omission.

### WR-06: `report_multi_artist` returns 0 on an unreadable input, so `run_assert` prints a green tick over a could-not-look

**File:** `scripts/phase06-oracle.sh:990-996`, consumed at `:2146`

**Issue:**

```sh
if [ ! -r "$fields" ]; then
  ASSERT_WHY="the fields TSV is missing or unreadable, so the write side could not be shown"
  return 0            # <-- 0, not 2
fi
```

`run_assert` (`:1017-1033`) maps rc 0 to `ok "$label: $ASSERT_WHY"`, so the console reads:

```
✓ CONF-04 write side: the fields TSV is missing or unreadable, so the write side could not be shown
```

A green tick whose text says the instrument did not look. Every other assertion in this file
returns 2 for that condition and routes to `unknown()`, which increments `UNKNOWNS` and forces
exit 3. The earlier block at `:2103-2113` does report the same condition as `unknown`, so the run
verdict is still correct — but the tick is exactly the shape CLAUDE.md § Health Checks exists to
outlaw.

**Fix:** `return 2` and let `run_assert`'s `*)` arm call `unknown`. If the intent is that a
*report* may never block the run, keep `return 0` only when the file is readable and empty, and
say so in the message.

### WR-07: Env-overridable paths are interpolated unquoted into `rm -rf` / `rm -f` on the remote side, contradicting the file's own override contract

**File:** `scripts/phase06-oracle.sh:213` (`SCRATCH`), `:219` (`STAMP_REMOTE`); used at `:1843`, `:1904`, `:1920`, `:2154`, `:2160`

**Issue:** The header (`:64-66`) states: *"Every knob below is `${VAR:-default}` and every one of
them can only make the verdict REDDER: a wrong host, a wrong container or a wrong output
directory produces a refusal or an UNKNOWN, never a pass."* Two of the knobs are not knobs on
the verdict, they are arguments to destructive commands built by string interpolation into a
remote shell:

```sh
rsh "$(dex_cmd sh -c "'rm -rf $SCRATCH; [ -e $SCRATCH ] && echo present || echo gone'")"   # :2154
rsh "timeout $REMOTE_TIMEOUT rm -f $STAMP_REMOTE"                                          # :2160
rsh "timeout $REMOTE_TIMEOUT sh -c 'mkdir -p ... && rm -f $STAMP_REMOTE && touch ...'"     # :1904
```

`$SCRATCH` is unquoted in all four uses, so `SCRATCH='/tmp/p6 /config'` word-splits in the
container shell into `rm -rf /tmp/p6 /config` — deleting the real `library.db`, `state.pickle`
and the vendored config. The dirty-destination precheck at `:1843` does not stop it: with two
words `[ ! -e /tmp/p6 /config ]` is a `test` argument error, not a refusal. Glob characters
expand too.

This requires a deliberately hostile environment variable, so it is a hardening finding rather
than an exploitable one — but the header's claim that no knob can do worse than make the run
redder is false as written, and the contrast with `phase06-incremental-control.sh` is instructive:
that script hard-fences its two roots with `case "$ROOT" in /tmp/p6a|/tmp/p6b)` **inside the
remote program** (`:344`, `:477`) and is not vulnerable.

**Fix:** adopt the sibling's fence. Quote every use (`rm -rf "$SCRATCH"` via `shq`/`printf '%q'`),
and add a literal allow-list at the top of the script:

```sh
case "$SCRATCH"      in /tmp/p6|/tmp/p6-*) : ;; *) precheck_fail "SCRATCH must be under /tmp/p6" ;; esac
case "$STAMP_REMOTE" in /mnt/fast/safety/phase06/*) : ;; *) precheck_fail "STAMP_REMOTE is fenced to /mnt/fast/safety/phase06/" ;; esac
```

### WR-08: `printf '%q'`-quoted paths are embedded inside single-quoted remote `sh -c '…'` strings — an apostrophe in a folder name breaks the command

**File:** `scripts/phase06-oracle.sh:1094`, `:1098`, `:2047`

**Issue:** All three build a remote command of the shape
`sh -c 'find <%q-quoted path> …'`. `printf '%q'` emits bash-style escapes (`\'`, `\$`, `\ `),
which are correct when the result lands in a bash word — line `:2053`'s bare
`find $NEWER_ARGS -newer …` is fine — but **wrong** inside a single-quoted `sh -c '…'`, where
`\'` terminates the quote and `\$` stays literal. A sampled folder named e.g.
`Guns N' Roses - …` (an entirely ordinary shape for this corpus) produces a remote syntax error;
a folder with `$` produces a wrong path.

Both failure modes are fail-closed (`rc != 0` → `unknown …; exit 3`, or `BLIND:…` → `bad`), so
this cannot manufacture a pass. It does mean the oracle cannot be pointed at a large class of
real backlog folders, and the failure will look like an infrastructure problem rather than a
quoting bug.

**Fix:** pass the path as a positional parameter instead of interpolating it, which is the shape
`phase06-incremental-control.sh` already uses:

```sh
printf "set -o pipefail; timeout %s sh -c 'LC_ALL=C find \"\$1\" -type f -printf \"%%p\\t%%s\\t%%T@\\n\"' sh %s | LC_ALL=C sort" \
  "$REMOTE_TIMEOUT" "$(printf '%q' "$1")"
```

### WR-09: `import.write: yes` is live in the vendored config while an `autotag: auto` inbox is registered on a `:rw` mount, and none of the three named controls covers that mount

**File:** `stacks/selfhosted/arrs/beets/config.yaml:333-339`; `stacks/selfhosted/arrs/beets/flask-config.yaml:80-83`; `stacks/selfhosted/arrs/beets/flask.yaml:146`

**Issue:** `config.yaml` sets `write: yes` and names three independent controls that make it safe
during Phase 6:

> the overlay, the `:ro` mount (D-05) and the statefile sha256 (D-29) are three independent
> expressions of that

All three protect `/media` (`:ro`) or beets' own state. None of them protects `/downloads`, which
is mounted `:rw` (`flask.yaml:146`) and is where all three registered inboxes live. The
beets-flask watchdog is the **active** runtime (`flask.yaml:56`, `restart: unless-stopped`) and
`01-auto` is registered with `autotag: auto` (`flask-config.yaml:80-83`), so any folder that
appears under `/downloads/complete/nzb/_inbox/01-auto` is imported without a prompt, by a config
whose `import.write` is `yes`.

The `-c` overlay control only applies to invocations *this phase's scripts* make; it does not
reach the watchdog, which reads the vendored config directly. Today nothing automatic stages into
`_inbox/` (SABnzbd lands in `complete/nzb/music/`, and plan 06-04 moved the two real folders to
the unregistered `04-hold`), so this is latent rather than active — but "nobody has put a file
there" is not one of the three controls the file claims.

**Fix:** either state the gap honestly beside the `write: yes` key (a fourth line naming
`/downloads:rw` + `01-auto` as the uncovered path and what keeps it empty), or set
`import.write: no` in the vendored config for the remainder of Phase 6 and flip it in Phase 7's
first commit alongside the `rw` grant — which is where every other Phase-7 behaviour flag is
already scheduled to move.

### WR-10: The D-04 remote scan converts a timeout into exit 4, making the block's dedicated `124` branch unreachable and its reported cause wrong

**File:** `scripts/quick-health-check.sh:1518-1532`

**Issue:**

```sh
D04_CMD="cd $D04_REPO_ROOT || exit 3
echo D04-BEGIN
timeout $REMOTE_TIMEOUT git grep -n -I -w -E 'beet' HEAD -- scripts stacks
D04_RC=\$?
if [ \$D04_RC -gt 1 ]; then exit 4; fi
exit 0"
```

`timeout` exits 124 on a kill; `124 > 1`, so the remote program exits **4**. The `elif [ "$D04_RC"
-eq 124 ]` branch at `:1532` can therefore never fire for this block, and the message the operator
actually gets says `4 = 'git grep' failed` — attributing a wedged host to a broken grep.

The run is still reported UNKNOWN with `EXIT_CODE=1`, so this is not a false green. It matters
because this file treats the distinction between "the bound expired" and "the tool failed" as
load-bearing in nine separate places, and the header's block I explicitly enumerates both as
distinct conditions.

**Fix:** preserve the status:

```sh
D04_RC=\$?
if [ \$D04_RC -eq 124 ]; then exit 124; fi
if [ \$D04_RC -gt 1 ]; then exit 4; fi
```

---

## Info

### IN-01: `expect_ne()` is defined and never called

**File:** `scripts/check-beets-config.sh:350-359`
**Issue:** Dead code; `grep -c '\bexpect_ne\b'` returns 1 (the definition). Its intended consumer
— the `UK` check — was hand-rolled inline at `:406-410` instead.
**Fix:** delete it, or use it for the `UK` and `duplicate_action` cases so the two helpers stay
symmetric.

### IN-02: `remote_is_blind()` is defined and never called

**File:** `scripts/phase06-incremental-control.sh:335-337`
**Issue:** Dead code. Every caller instead tests `[ "$RE_RC" -ne 0 ]`, which is *wider* than the
function (it also catches rc 1, 125, 126, 127), so behaviour is fail-closed — but the named
classification the function encodes is unused, and a reader will assume it is in force.
**Fix:** delete it, or route the callers through it and add an explicit non-blind non-zero arm.

### IN-03: The readiness-gate failure message overstates how long it waited

**File:** `scripts/check-beets-config.sh:673`
**Issue:** `$((READY_ATTEMPTS * READY_SLEEP))` renders 30s, but the loop sleeps only between
attempts — 5 sleeps × 5s = 25s of actual waiting.
**Fix:** `$(( (READY_ATTEMPTS - 1) * READY_SLEEP ))`.

### IN-04: The header names a constant that does not exist

**File:** `scripts/check-beets-config.sh:73` vs `:107`
**Issue:** The override contract lists `EXEC_USER`; the variable is `EXEC_USER_FLAG`. A grep for
the documented name returns nothing, which is the failure mode the same header spends a paragraph
warning about.
**Fix:** rename one to match the other.

### IN-05: `--arm` with no value exits 1 silently, which the exit-code table reserves for a measured failure

**File:** `scripts/phase06-incremental-control.sh:924`
**Issue:** `--arm) MODE="arm"; ARM="${2:-}"; shift 2 ;;` — with only one argument left, `shift 2`
returns non-zero and `set -e` (`:101`) terminates the script with status 1 and no output. The
documented meaning of 1 is *"the arm produced the OPPOSITE outcome"*; usage errors are documented
as 3.
**Fix:** `--arm) MODE="arm"; ARM="${2:-}"; shift; [ $# -gt 0 ] && shift; [ -n "$ARM" ] || { printf 'error: --arm needs a|b\n' >&2; exit 3; } ;;`

### IN-06: Predictable, non-unique temp paths inside the container

**Files:** `scripts/phase06-incremental-control.sh:393`, `:399`, `:401`, `:431`;
`scripts/phase06-oracle.sh:213`; `scripts/check-beets-config.sh:112`
**Issue:** `/tmp/p6-man.meta`, `/tmp/p6-man.z`, `/tmp/p6-man.zs`, `/tmp/p6-taghist.py`, `/tmp/p6`,
`/tmp/phase06-check-beets-config-noop.yaml` are all fixed names in a world-writable directory.
Two arms run back-to-back share them; a stale root-owned leftover turns a read into a BLIND; and
a pre-placed symlink would be followed by the `>` redirections. Single-tenant container, so this
is hygiene rather than exposure.
**Fix:** `mktemp` inside the container, or suffix with `$$`.

### IN-07: `EXTRA_FORBIDDEN_SUBSTRINGS` is expanded unquoted, so it globs as well as splits

**File:** `scripts/check-beets-config.sh:486-487`
**Issue:** `local IFS=':'; for forb in $EXTRA_FORBIDDEN_SUBSTRINGS` — field splitting is intended,
pathname expansion is not. A value containing `*` or `?` expands against the cwd (the repo root).
Additive-only, so it can only add spurious failures.
**Fix:** `set -f` around the loop, or read into an array with `IFS=':' read -r -a forb_arr <<< "$…"`.

### IN-08: The two sibling scripts disagree on whether RED or UNKNOWN wins

**Files:** `scripts/phase06-oracle.sh:2164-2171` vs `scripts/phase06-incremental-control.sh:719-721`
**Issue:** The oracle checks `UNKNOWNS` first (a blind instrument beats a measured red); the
incremental control checks `failed` first (a measured red beats a blind instrument). Both are
defensible; having both in one phase means a reader cannot infer the convention.
**Fix:** pick one, state it in both headers' EXIT CODES blocks.

### IN-09: `assert_dj_count` has no vacuity guard, unlike its neighbour

**File:** `scripts/phase06-oracle.sh:761-779`
**Issue:** `assert_no_compilations` (`:732-755`) deliberately refuses to pass when the
compilation stratum was never exercised (`nva -eq 0` → red, with the reason "VACUOUS"). The DJ
equality has no equivalent: a sample whose S5 rows sum to 0 compares `0 -ne 0` and passes. The
cross-check at `:2128` only fires when the sample and the fixture *disagree*; both being zero is
silent.
**Fix:** `if [ "$want" -eq 0 ]; then ASSERT_WHY="the sample holds no S5 files, so the albumtype rule was never exercised — VACUOUS"; return 1; fi`

### IN-10: The re-offer classifier hard-codes a path count of 1

**File:** `scripts/phase06-incremental-control.sh:658`
**Issue:** `grep -q 'Skipped 1 paths\.'`. A source folder that yields two albums prints
`Skipped 2 paths.` and the classifier falls to `indeterminate` → BLIND. Fail-closed, but the
control silently stops working for any `SRC_FOLDER` that is not single-album, which is exactly
what the `SRC_FOLDER` override invites.
**Fix:** `grep -qE 'Skipped [0-9]+ paths\.'`.

### IN-11: No cleanup trap — an aborted run leaves a copy of the real `library.db` in the container and a stamp on the host

**File:** `scripts/phase06-oracle.sh:1909-1913` (`--baseline` exits before cleanup), `:2152-2160`
**Issue:** Every `exit 3` path between step 5 and step 12 leaves `/tmp/p6/lib.db` (a byte copy of
the real library) inside the container and `/mnt/fast/safety/phase06/oracle.stamp` on LXC 100.
The next run's dirty-destination precheck then refuses, which is correct but presents as an
unexplained refusal. `--baseline` always leaves the stamp.
**Fix:** `trap` a best-effort remote cleanup on EXIT, or name the manual cleanup command in the
refusal message at `:1848`.

### IN-12: An empty field view is reported as a pass

**File:** `scripts/phase06-oracle.sh:2106-2112`
**Issue:** `awk -F'\t' 'NF != 6 {n++} END {print n + 0}'` over an empty `fields.tsv` yields 0, so
the script prints `✓ field view read: 0 items, six columns each`. `assert_top_level` catches it
downstream (every pair becomes `NO-LIBRARY-ROW` → rc 2 → `unknown`), so the verdict is right — but
the tick is not.
**Fix:** add `[ -s "$OUT/fields.tsv" ]` to the guard and route an empty file to `unknown`.

### IN-13: The D-03 CLI-render branch hard-codes the checkout path its sibling just made overridable

**File:** `scripts/quick-health-check.sh:1386`
**Issue:** `cd /mnt/fast/stacks || exit 3` is literal, while the drift block immediately above
grew `DRIFT_REPO_ROOT` in this same commit for the explicitly stated reason that *"an undriveable
branch is an unproven branch"* (`:100-109`). The D-03 render's `exit 3` branch is therefore the
one path in the two new blocks that cannot be driven to red from a scratch checkout.
**Fix:** reuse `$DRIFT_REPO_ROOT` (it already forces `EXIT_CODE=1` when non-default) or add a
`D03_REPO_ROOT` with the same additive contract.

---

## Notes on things checked and found sound

Recorded so a later reader knows these were exercised rather than skipped:

- **Credential handling is clean.** `-H @<(printf …)` for both Authorization headers, `$ENV.NAME`
  in jq for MA's username/password, secrets files sourced without `set -a`, no key or password in
  any argv or any printed line. The `${VAR:+set}${VAR:-unset}` idiom at
  `check-music-consumers.sh:713` reports presence without value. No hardcoded secret in any of
  the five YAML files; `config.yaml`'s single 64-hex string is a published digest of a fenced
  host file, correctly classified.
- **No destructive path reaches `/mnt/tank/media` or `/mnt/tank/downloads`.** The only `rm -rf`
  in the phase targets `/tmp/p6*` inside a container, twice fenced by a literal `case` allow-list
  in `phase06-incremental-control.sh`; `/media` is `:ro` on both containers in both compose files
  and is asserted so from `docker inspect` in two independent places. The only `mv` is
  `phase06-oracle.sh:1663`, over a self-test fixture under `$OUT`.
- **`config.yaml` comment-vs-effect** was checked key by key. The one place the file previously
  got this wrong (`max_filename_length: 0` meaning "no truncation") carries its dated correction
  in place and states the real 200-char limit. `paths:` order on disk matches the order the
  comments claim is load-bearing. `duplicate_action: ask` is present, so rc6's silent-delete
  default cannot apply.
- **Remote bounding.** Every `ssh` in the six scripts is bounded Linux-side with
  `timeout $REMOTE_TIMEOUT`, the status is read on the next line, and where a pipe exists in the
  remote string it is headed by `set -o pipefail`. `grep -n 'timeout \$REMOTE_TIMEOUT.*|'` over
  `quick-health-check.sh` returns only lines that also carry `pipefail` or are Go-template pipes.
  The single in-container pipeline is WR-01.
- **`shellcheck -S warning`** is clean on all three new scripts. The SC2329 "never invoked"
  notices on `phase06-oracle.sh:690-945` are false positives (indirect dispatch through
  `run_assert "$@"`), verified by the self-test exercising every one of them.

---

_Reviewed: 2026-09-21T22:33:04Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---

## Dispositioned 2026-09-22 — this file is now WIRED

*Appended by plan 06-21. **Nothing above this line was edited.** Every finding's text, every
file:line reference and the `findings:` frontmatter counts are the record of what was found on
2026-09-21, and that record stands — including where a later measurement refined it.*

`06-VERIFICATION.md` § Required Artifacts marked this file **NOT WIRED** — *"The Critical finding
(CR-01) and all 10 Warnings remain unaddressed; no fix commit, no override, no carry-forward
reference."* That gap is now closed.

**All 24 findings carry an explicit disposition**, recorded in:

> **`.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS.md`**

with one row per finding ID (CR-01, WR-01…WR-10, IN-01…IN-13) in this file's own order, each
citing the plan, the commit and the artifact holding the driven transcript. Summary: **19 FIXED,
4 FIXED (undriven), 0 ACCEPTED, 1 CARRIED — 24 total.**

The fixes were made by gap-closure plans **06-15, 06-16, 06-17, 06-18, 06-19 and 06-20**; plan
**06-21** wrote the register and wired it. The register is reachable from ROADMAP Phase 7 entry
criteria **E10** (CR-01's residue — the D-04 exemption register and its pinned baseline) and
**E11** (WR-09), so the finding set is carried into the next phase rather than left here.

**The one finding not fixed is WR-09**, dispositioned CARRIED: setting `import.write: no` would
change the sha256 of the very `config.yaml` every CONF-01 / CONF-02 / CONF-05 proof in this phase
was measured against. It is owned by `DEF-06-21-01` and ROADMAP entry criterion **E11**, and is
stated in the runbook at `stacks/selfhosted/arrs/beets.md`.

_Dispositioned: 2026-09-22 by plan 06-21_
