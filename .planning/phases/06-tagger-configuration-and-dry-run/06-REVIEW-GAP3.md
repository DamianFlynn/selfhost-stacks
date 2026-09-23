---
phase: 06-tagger-configuration-and-dry-run
round: 4
reviewed: 2026-09-23T00:00:00Z
depth: deep
diff_base: fff070a97cd867c8bd52d10bff2b074e0530ba74
files_reviewed: 4
files_reviewed_list:
  - scripts/check-beets-config.sh
  - scripts/phase06-incremental-control.sh
  - scripts/phase06-oracle.sh
  - scripts/quick-health-check.sh
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 06: Code Review Report — round 4 (over round 3's diff)

**Reviewed:** 2026-09-23
**Depth:** deep
**Scope:** `git diff fff070a..HEAD -- scripts/` (320 insertions, 44 deletions, four files)
**Status:** issues_found — **zero Critical**

## Summary

**No Critical finding. Stated plainly, because it is a real result:** I could not construct a
path from any round-3 change to data loss, to an estate outage, or to a false green on a
destructive-command fence. The two-stage prefix+character-class predicate that R3-10 installed in
`phase06-incremental-control.sh` is sound — I drove it by hand over `""`, the bare prefix,
a `/`-bearing remainder and a real `mktemp` name, and it refuses everything it should while still
accepting the real name. It is applied at both sites that take a variable path; the other five
`rm`/`rmdir` sites in that file (`:424`, `:447`, `:612`, `:1018`, `:1031`) operate on the literal
constants `ARM_A_ROOT=/tmp/p6a` / `ARM_B_ROOT=/tmp/p6b` (`:151-152`), which are **not**
env-overridable, and `:612` re-fences them against a literal allow-list anyway. Both in-container
programs parse clean under `dash -n` after the heredocs are extracted. The four converted awk
consumers in `phase06-oracle.sh` are all four converted — `grep` finds no surviving `$2 == p`.
The `printf '%q'` rendering that R3-01 moved onto `EXTCONF_PATH` is, this time, consumed in the
right context: a word of the *remote* shell's command line, then handed to the inner `sh -c` as a
positional parameter. Several load-bearing claims check out under grep: the `EXIT-CODE BEHAVIOUR
CHANGED` header count really is 13 before and after; the comment-stripped
`assert_beet_invocation_contract` census really is 2; `library.db CHANGED` really does return
exactly one hit; R3-08's refusal of a third conjunct is correctly reasoned (with both conjuncts
true, `ARM1_FAILS` is necessarily 1, so the conjunct would be vacuous).

What I did find is six Warnings, and the two largest are the same defect class this phase keeps
re-manufacturing — **a claim that the adjacent code does not support**, written in the very hunk
that announces the class closed:

- R3-01 asserts that the ⛔-forbidden hand-escaped-`\"` shape "was simply never applied to the
  EXTCONF_PATH site three hundred lines below it" and that closing it retires the instance. There
  are **four more live instances of the identical shape eight to eleven lines *below* the
  prohibition paragraph itself** (`:1535-1538`), interpolating the overridable
  `DRIFT_APPDATA_ROOT`. The round's headline lesson — "a documented-forbidden shape survived a
  round inside the file that documents it" — is still true of the file after the fix.
- R3-02's new `ST_PLANNED_CASES=134` gate is not invariant over the self-test's *own* documented
  environment-conditional skips. I drove it: with `python3` absent the oracle self-test now exits
  1 announcing "**A SECTION DID NOT RUN**" when every section ran. As root it would be 129.

Everything below states whether it was verified by grep/read/execution or reasoned statically.

---

## Critical Issues

None.

---

## Warnings

### WR-01: the ⛔-forbidden `\"$KNOB\"` shape is still live four times, eleven lines below its own prohibition — and R3-01's new text says it is closed

**File:** `scripts/quick-health-check.sh:1535-1538` (prohibition at `:1518-1527`)
**Verified by:** read + grep. Not executed.

The ⛔ paragraph, unchanged and re-endorsed by R3-01 in this diff, says:

> DO NOT "fix" a future site of this shape by hand-escaping quotes inside the command string
> instead. A `\"` wrapper survives a space but not a quote and not a `$` …

and R3-01 appends, in the same hunk:

> THIS PARAGRAPH WAS RIGHT WHEN IT WAS WRITTEN AND IS UNCHANGED — it was simply never applied
> to the EXTCONF_PATH site three hundred lines below it … (R3-01, closed 2026-09-23 by plan 06-30)

Eight lines further down, inside the very `DRIFT_CMD` string the prohibition is embedded in:

```bash
_drift_pair audio.bash stacks/selfhosted/arrs/sabnzbd/audio.bash \"$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/audio.bash\"
_drift_pair sabnzbd-beets-config.yaml stacks/selfhosted/arrs/sabnzbd/beets-config.yaml \"$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/beets-config.yaml\"
_drift_pair survivor-config.yaml stacks/selfhosted/arrs/beets/config.yaml \"$DRIFT_APPDATA_ROOT/arrs/beets/config/config.yaml\"
_drift_pair flask-config.yaml stacks/selfhosted/arrs/beets/flask-config.yaml \"$DRIFT_APPDATA_ROOT/arrs/beets/config/beets-flask/config.yaml\"
```

`DRIFT_APPDATA_ROOT` is an env-overridable knob (`:842`). Local bash expands it and emits a
literal `"` on each side — the hand-escaped-`\"` wrapper, exactly and by name. A value containing
`"` terminates the quoting on the remote shell; a value containing `$` or `` ` `` is expanded or
executed by the remote shell as `root@172.16.1.159`.

**Bound, so the finding is not overstated:** this cannot produce a green tick. Any non-default
`DRIFT_APPDATA_ROOT` already forces `EXIT_CODE=1` at `:1465`, and a broken remote command lands in
the could-not-look arm at `:1542-1554`. There is no privilege crossing — the operator who sets the
variable already has root on the LXC. **The defect is the claim, not the exploit:** the round's
stated closure of this class is false, and the next reader of `:1521-1527` will conclude the sweep
was done.

**Fix:** render once beside the definition, like the other nine, and interpolate only the rendered
form — the `_drift_pair` body already quotes `"$3"`, so no quotes are needed at the call sites:

```bash
DRIFT_APPDATA_ROOT_Q=$(printf '%q' "$DRIFT_APPDATA_ROOT")
# …
_drift_pair audio.bash stacks/selfhosted/arrs/sabnzbd/audio.bash $DRIFT_APPDATA_ROOT_Q/arrs/sabnzbd/config/scripts/audio.bash
```

(Note `%q` renders the whole word, so the suffix must be appended to the *rendered* value or
rendered with it; prefer `DRIFT_AUDIO_Q=$(printf '%q' "$DRIFT_APPDATA_ROOT/arrs/sabnzbd/config/scripts/audio.bash")`
per pair.) Then correct the R3-01 sentence: the class was not closed by 06-30.

---

### WR-02: `ST_PLANNED_CASES=134` is not invariant over the self-test's own documented skips — it turns two reported skips into a hard failure with a false diagnosis

**File:** `scripts/phase06-oracle.sh:2597` (pin), `:2612-2619` (gate)
**Verified by:** execution (estate-free `--self-test` only, per the safety constraints).

`ST_RUN` is incremented once per `st_case` (`:1765`). Three case groups are
**environment-conditional and deliberately so**, each printing a `warn` that says the skip is
"reported, never silently counted as a pass":

| Site | Condition | Cases skipped |
|---|---|---|
| `:1930` | running as root (mode-000 fixture unconstructible) | 1 |
| `:2242` | `python3` absent on the workstation | 2 |
| `:2396` | running as root (present-but-unreadable fixture) | 4 |

So `ST_RUN` is 134 only on a non-root machine that has `python3`. Driven:

```
$ PATH=<no python3> bash scripts/phase06-oracle.sh --self-test   # (estate-free)
  ✗ self-test: 132 case(s) ran but 134 were announced - A SECTION DID NOT RUN
```

Every section ran. The banner asserts a specific cause that is false, and exit 1 replaces what was
previously a green run with two warn lines. As root the figure is 129, same false message.

The in-band remediation instruction makes it worse: "Re-measure only after confirming every
section still runs" (`:2617`) plus "it MUST BE RE-MEASURED whenever a section or a case is added"
(`:2594`). An operator hitting this on a python3-less box re-pins to 132, and the pin then fails
on every box that *has* python3. The pin is self-destabilising across environments.

This is a **false red with a wrong stated cause**, not a false green, which is why it is a Warning
and not a Blocker. But note the asymmetry it creates: the gate now fires most readily on the
machines least likely to be the operator's, so the first real use is likely to be a misdiagnosis.

**Fix:** count the announcement instead of typing it, or make the pin conditional in the same
shape as the skips. Minimal form — have each skip arm declare its own shortfall:

```sh
ST_PLANNED_CASES=134
# …
if [ "$(id -u)" = "0" ]; then
  warn "SKIPPED as root: …"
  ST_PLANNED_CASES=$((ST_PLANNED_CASES - 1))     # and -4 at :2396, -2 at :2242
fi
```

so that a *deliberate* skip adjusts the announcement at the same site that prints the warn, while
a dropped section — which adjusts nothing — still fires the gate. Whatever form is chosen, the
gate's message must stop asserting "A SECTION DID NOT RUN" as the only possible cause.

---

### WR-03: the new `INT TERM HUP` trap handlers do not exit, so a delivered signal is swallowed — the scratch path is deleted and the program runs on

**File:** `scripts/phase06-incremental-control.sh:503-505` and `:563-565`
**Verified by:** execution, locally, with `dash` — the same interpreter family these programs run
under in the container. No estate contact.

```sh
$ cat trapt.sh
D=$(mktemp -d /tmp/p6-mf.XXXXXXXX)
trap 'case "${D:-}" in
        /tmp/p6-mf.*) case "${D#/tmp/p6-mf.}" in ""|*[!A-Za-z0-9._-]*) : ;; *) rm -rf "$D" ;; esac ;;
      esac' EXIT INT TERM HUP
echo "started $D"; sleep 5
echo "STILL RUNNING AFTER SIGNAL; dir exists? …"; sleep 2; echo "second phase done"

$ dash trapt.sh & sleep 1; kill -TERM $!; wait
started /tmp/p6-mf.iv9jeL2O
STILL RUNNING AFTER SIGNAL; dir exists? NO
second phase done
exit=0
```

POSIX: a trapped signal runs its action and then **resumes** the shell. The handler is a bare
`case` with no `exit` and no re-raise, so adding `TERM` converts "terminate" into "delete the
scratch directory, keep going, and exit 0". Before this diff a SIGTERM killed the program; now it
does not.

The in-band claim (`:496-497`) describes only one residual:

> THE RESIDUAL, stated rather than claimed away: SIGKILL cannot be trapped, so a hard kill still
> leaves the directory. Widening the list SHRINKS the window; it does not close it.

That is a window-of-leakage framing. It does not describe, and 06-32's artifact does not consider,
that the widened list also **suppresses termination**. The "window" is not narrowed; the signal is
absorbed.

Most downstream paths do degrade closed — `sort "$MANDIR/meta"` (`:509`), `find … > "$MANDIR/z"`
(`:513`) and `sort -z < "$MANDIR/zs"` (`:515`) all fail once `MANDIR` is gone and route to
`MANIFEST BLIND … exit 2`. But not all: a signal delivered after `:517` lets the program print
`MANIFEST OK` and exit 0, and in `write_prog_taghistory` a signal delivered between `:566` and
`:567` removes the program file, makes `"$PY" "$THPROG"` fail, and the shell still reaches
`:571` and exits 0 — a normal-looking transcript over an interrupted run.

**Fix:** make the handlers terminal, and keep `EXIT` separate so the cleanup is not run twice:

```sh
_p6_clean() { case "${MANDIR:-}" in
  /tmp/p6-mf.*) case "${MANDIR#/tmp/p6-mf.}" in ""|*[!A-Za-z0-9._-]*) : ;; *) rm -rf "$MANDIR" ;; esac ;;
esac; }
trap '_p6_clean' EXIT
trap '_p6_clean; trap - INT;  kill -INT  $$' INT
trap '_p6_clean; trap - TERM; kill -TERM $$' TERM
trap '_p6_clean; trap - HUP;  kill -HUP  $$' HUP
```

so the program still dies from the signal it was sent, and the caller's rc still says so.

---

### WR-04: R3-09's stated mechanism — `timeout` delivering SIGTERM to the in-container shell — is not established, and the signal that most likely *does* arrive is not in the new list

**File:** `scripts/phase06-incremental-control.sh:489-495` (and the cross-reference at `:555-558`)
**Reasoned statically.** Not executed; deliberately, per the no-estate-contact constraint.

The comment states the widening as a fix for a *routine* outcome:

> This program is delivered as `sh -s` through `timeout $REMOTE_TIMEOUT docker exec` … so a bound
> expiry is a ROUTINE outcome … and on the narrow list that expiry left behind exactly the minted
> leftover …

The transport is `ssh … "timeout $REMOTE_TIMEOUT docker exec -i -u beetle $CONTAINER sh -s…"`
(`:396`). `timeout` sends SIGTERM to the **`docker exec` client process on LXC 100**, not to the
`sh -s` running inside the container. `docker exec` has no signal-forwarding path to the exec'd
process (this is long-standing Docker behaviour: killing the client leaves the exec'd process
running; the daemon tears down the attached streams instead). If that holds here, the added
`TERM` never fires for this program and R3-09 is inert with respect to the scenario it names.

What *does* happen when the client dies is that the exec's stdout stream closes. The in-container
`sh` then takes `EPIPE`/`SIGPIPE` on its next write (`:509` and `:517` both write to stdout), and
a shell killed by an untrapped `SIGPIPE` runs **no** trap — `PIPE` is not in the new list.

06-32 § 1 is candid that the signal behaviour is "STATIC REASONING ABOUT POSIX sh, NOT EXECUTED
AGAINST THE CONTAINER" and records a driving condition. That honesty is right, and this finding is
not that the reasoning was unverified — it is that the reasoning **omits the forwarding question
entirely**, so the recorded driving condition ("confirm that no p6-mf or p6-taghist name survives
after a deliberately short REMOTE_TIMEOUT") is now the only thing standing between the comment and
a false account of why the leak was closed.

**Fix:** either (a) qualify the comment to say the SIGTERM path is unconfirmed and that
`docker exec` is not known to forward signals, and add `PIPE` to the list with WR-03's terminal
handlers; or (b) leave the code and demote the paragraph to "widened defensively; the mechanism
that actually terminates this program on a bound expiry has not been identified". Do not leave a
comment that names one mechanism as routine when the transport probably does not deliver it.

---

### WR-05: the hunk that corrects a self-referential grep count states a raw count that its own text falsified

**File:** `scripts/check-beets-config.sh:433-436`
**Verified by:** grep.

```
# R3-07's own evidence line
# printed that code-only figure as though it were a raw grep count (raw is 4, and rises with prose
# like this); that is the same self-referential measurement error this round is closing, so it is
# corrected here rather than inherited.
```

Measured:

```
$ /usr/bin/grep -c 'assert_beet_invocation_contract' scripts/check-beets-config.sh
5
$ git show fff070a:scripts/check-beets-config.sh | /usr/bin/grep -c 'assert_beet_invocation_contract'
4
```

Raw was 4 at the diff base; the recipe line this same hunk added (`:431`) made it 5. The sentence
is present-tense ("raw is 4") in a file where the answer is 5, inside the paragraph whose subject
is precisely that a number written into a file that greps itself moves that number. The hedge
"and rises with prose like this" is not a fix — the hunk that wrote the hedge is what rose it.

The **comment-stripped** census in the same block is correct: I ran the recipe and got 2, the
definition and the single call in `run_self_test`. Only the parenthetical raw figure is wrong.

**Fix:** drop the number, exactly as `quick-health-check.sh`'s R3-05 block did in this same round
("THE TWO NUMBERS AND THE CONSTANT DELTA … ARE WITHDRAWN"). Two sibling files, one round, one
lesson — but only one of them applied it:

```
# printed that code-only figure as though it were a raw grep count. The raw count is NOT pinned
# here, for the reason R3-05 gives in scripts/quick-health-check.sh: a number written into a file
# that greps itself is moved by the sentence that states it. If you need it, run the recipe.
```

---

### WR-06: the new sha256sum line parser guards the layer-3 `-l` assertion and has no case in the 134-case set R3-02 pinned in the same round

**File:** `scripts/phase06-oracle.sh:2754-2755`, `:2915-2916`
**Verified by:** grep over `self_test_core` / `self_test_classes` / `self_test_vacuity` /
`self_test_fences` — no case drives `sub(/^[0-9a-f]+  /…)` or either `*_SHA_*` assignment.

R3-03 replaced `$2 == p` with a whitespace-tolerant parser at all four sites (correctly — I
checked, no `$2 == p` survives). Its own account of why the old form was wrong is the file's
house rule:

> An undriveable branch is an unproven branch, which is this file's own stated reason for having
> the knob at all.

The new parser is then driven only in `artifacts/06-31-oracle-pin-and-layer3.txt § 1` — a one-off
transcript, not a case. Meanwhile R3-02 added `ST_PLANNED_CASES` in the *same round* on the
premise that an unpinned set lets a guard silently stop being exercised. The parser now stands in
front of "the one assertion whose whole job is to prove `-l` kept the real library.db closed"
(R3-04's own words, `:2923`), and nothing in the pinned set touches it. A future edit to the
regex, the two-space separator, or the `print $1` field index goes green.

**Fix:** add a `st_case` group over a fixture file in `self_test_vacuity` — cheap, estate-free, and
it re-pins `ST_PLANNED_CASES` at the same time, which is the maintenance the pin advertises:

```sh
printf '%s\n' "aa$(printf 'b%.0s' $(seq 1 62))  /config/my library.db" > "$d/l3.txt"
got=$(LC_ALL=C awk -v p='/config/my library.db' '{ rest=$0; if (sub(/^[0-9a-f]+  /,"",rest) && rest==p) print $1 }' "$d/l3.txt")
st_case 1 "$([ -n "$got" ] && echo 1 || echo 0)" "a path containing a SPACE is matched exactly — the R3-03 consumer."
# plus the negatives: a GNU backslash-escaped line, a suffix-only near-miss, and a truncated line.
```

---

## Info

### IN-01: `DASH_RESOLVE_IP` still reaches a remote command string raw, and the new census does not mention it

**File:** `scripts/quick-health-check.sh:1354`
**Verified by:** grep.

```bash
DASH_OUT=$(ssh -n $SSH_OPTS "$DASH_HOST" "timeout $REMOTE_TIMEOUT curl … --resolve traefik.deercrest.info:443:$DASH_RESOLVE_IP https://…")
```

The R3-01 census recipe sets the criterion as "for each knob that reaches a remote command string,
check that only its `_Q` form is interpolated" — broader than "path", and `DASH_RESOLVE_IP` (`:968`)
meets it and is raw. Harmless today: it is override-guarded at `:1349`, and a split word makes
`curl` fail loudly. Listed only because the census recipe is now the file's stated way of finding
these, and running it as written surfaces this site as an un-rendered one that no plan owns.

### IN-02: the census recipe's second grep misses two remote call sites

**File:** `scripts/quick-health-check.sh:1490-1491`
**Verified by:** grep.

The recipe is `/usr/bin/grep -n 'ssh -n \$SSH_OPTS'`. Two remote calls do not match it:
`:1070` and `:1092` use `bounded_ssh "$PROBE_TIMEOUT" ssh $SSH_OPTS root@… ` — no `-n`. Neither
interpolates a knob today, so nothing is wrong now; but a recipe offered as the durable
replacement for a wrong number under-counts the haystack by two. Widen to
`/usr/bin/grep -nE 'ssh (-n )?\$SSH_OPTS'`.

### IN-03: `awk -v p="$REAL_LIB_DB"` applies awk escape processing to an overridable knob

**File:** `scripts/phase06-oracle.sh:2754-2755`, `:2915-2916`
**Reasoned statically.**

`REAL_LIB_DB` / `REAL_STATE_PICKLE` are env knobs (`:255-256`). `awk -v var=value` expands escape
sequences in *value*, so a knob containing a backslash is mangled before the `rest == p`
comparison. It fails closed (empty → `unknown` → exit 3), and R3-03 already documents the adjacent
GNU-escaped-output case as a deliberate refusal, so this is a residual rather than a contradiction.
If it is worth removing, pass the path through `ENVIRON` instead: `p="$REAL_LIB_DB" awk '… ENVIRON["p"] …'`.

### IN-04: R3-04's two new `exit 3` arms leave the container scratch and the LXC stamp behind

**File:** `scripts/phase06-oracle.sh:2927-2928`
**Verified by:** read; no `trap` exists anywhere in `phase06-oracle.sh` (grep returns nothing).

Step 12's `rm -rf` (container scratch) and `rm -f` (LXC stamp) never run when the new guards fire.
This is a **pre-existing class**, not a new one — `capture_manifests after … || exit 3` (`:2907`)
and `rsh_classify … || exit 3` (`:2913`) already do this two lines above, and leaving state behind
on a could-not-look is arguably the right call for a forensic instrument. Recorded because R3-04
increased the count of such exits and the clean-up gap is nowhere stated in band.

---

## What I checked and found clean

Recorded so a future round does not re-spend the budget, and because "verified TRUE" is the other
half of the load-bearing distinction:

- **R3-10's predicate, both sites.** `""`, `/tmp/p6-mf.`, `/tmp/p6-mf.a/../../../home` and a real
  `mktemp` name all behave as the artifact claims. The class `[A-Za-z0-9._-]` excludes `/`;
  the empty remainder is caught by the first `case` arm. Driven locally, no `rm` executed.
- **Every other destructive site in `phase06-incremental-control.sh`.** `:424`, `:447`, `:612`,
  `:1018`, `:1031` act on `ARM_A_ROOT`/`ARM_B_ROOT`, which are plain constants at `:151-152`, not
  `${VAR:-default}` knobs. `:612` additionally re-fences against a literal allow-list.
- **Heredoc bodies.** Extracted `write_prog_manifest` (`:456-521`) and `write_prog_taghistory`
  (`:541-572`) and ran both under `/bin/sh -n` and `dash -n`. Clean.
- **The five new `_Q` consumption sites.** `D03_FLASK_CONTAINER_Q` (`:1652`),
  `D03_CLI_PROFILE_Q` + `D03_CLI_COMPOSE_Q` (`:1702`), `MUSIC_UNDERSCORE_ROOT_Q` (`:2671`, `:2699`)
  are all words of the *remote* shell's command line — the one context `%q` is correct for.
  `EXTCONF_PATH_Q` (`:2220`) is a remote word that then becomes `$1` of the inner `sh -c 'cat "$1"'`,
  with the literal `sh` supplied as `$0`; the program text names no path. That is the right shape.
- **No new pipeline was introduced** in any of the four files by this diff. `grep -qF` in
  `check-beets-config.sh` still reads from here-strings at `:618` and `:632` (GC-01 intact).
- **`ST_PLANNED_CASES=7` in `check-beets-config.sh`** is unconditional: six `run_case` calls plus
  the manual case 6. `--self-test` exits 0. Case 7's `bytes7 > 65536` precondition still holds.
- **R3-08's refusal of a third conjunct is correct.** With `ARM1_REAL_VIOLATIONS -eq 0` the
  `cfg_pass` arm ran (no increment) and with `ARM1_SYNTH_REJECTED -eq 1` the `cfg_fail` arm ran
  (one increment), so `ARM1_FAILS == 1` necessarily. The conjunct could never independently fail.
- **R3-06's narrowed sentence is accurate.** Three cases at `:2543-2548` each test
  `case "$X" in *"rm "*)`, and nothing below tests for `touch` or for redirection. The comment now
  matches the cases.
- **Claims verified TRUE by grep:** `EXIT-CODE BEHAVIOUR CHANGE[D]` header count is 13 at both
  `fff070a` and `HEAD`; the bracketed recipe lines are genuinely not self-matching;
  `library.db CHANGED` returns exactly 1 hit; the comment-stripped
  `assert_beet_invocation_contract` census returns 2; all four layer-3 awk consumers were
  converted with no `$2 == p` surviving; all nine `_Q`-rendered knobs have an override guard that
  forces `EXIT_CODE=1`.
- **`phase06-oracle.sh --self-test`** exits 0 with 134 cases in this environment (non-root,
  python3 present), confirming the pin is right *here* — which is the whole of WR-02.

---

_Reviewed: 2026-09-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep — round 4, scoped to `fff070a..HEAD`_
_No source file was modified. No estate contact: no ssh, no docker, no `--run`, no `--arm`.
`quick-health-check.sh` was not executed at all._
