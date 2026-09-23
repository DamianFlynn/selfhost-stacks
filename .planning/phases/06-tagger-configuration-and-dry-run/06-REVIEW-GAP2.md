---
phase: 06-tagger-configuration-and-dry-run
reviewed: 2026-09-22T00:00:00Z
depth: standard
round: 3
files_reviewed: 4
files_reviewed_list:
  - scripts/check-beets-config.sh
  - scripts/quick-health-check.sh
  - scripts/phase06-oracle.sh
  - scripts/phase06-incremental-control.sh
diff_base: bf509f46ba12c8536ec98b5c05cb17bb61c30df2
findings:
  critical: 0
  warning: 5
  info: 5
  total: 10
status: issues_found
---

# Phase 06, Round 3: Code Review Report (GAP2)

**Reviewed:** 2026-09-22
**Depth:** standard, scoped to what round 2 (plans 06-22..06-29) CHANGED
**Files reviewed:** 4
**Status:** issues_found
**Finding ID namespace:** `R3-*` (distinct from round 1's `CR-*`/`WR-*`/`IN-*` and round 2's `GC-*`)

## Summary

Round 2's substantive fixes hold up under inspection. The GC-01 here-string conversion in
`check-beets-config.sh` is correct and its >64 KiB regression case (case 7) is genuinely
position-anchored at the top of the dump, which is the only placement that would have failed
against the broken form. The GC-13 counter split is correct and uses a `-1` UNKNOWN sentinel so a
gate reached without the producer having run fails rather than passing on a zero. The GC-02
receiving-side fences are a real narrowing (the bare glob admitted `/`; the character class does
not) and `self_test_fences` drives them without ever executing a destructive program. The GC-03
condition-P arm closes a genuine nested vacuity and `D04_N_ASSERT` is computed with
`grep -c '^HEAD:'`, which correctly yields 0 on the empty string rather than the classic
`printf | wc -l` off-by-one.

**I did not find a reproducible false green on the live estate**, and I am saying so explicitly
rather than manufacturing a BLOCKER. What I did find is that this round closed several defect
classes *partially* and then wrote in-band claims that they were closed *completely* — which is
the same shape as the drift the round exists to prevent, and is how the real fence eventually gets
deleted as "duplicated".

Three findings are of that class and are individually verifiable by grep:

- **R3-01** — GC-17 claims "FOUR such sites in this file"; there are at least five more
  overridable knobs still interpolated raw into remote command strings, one of them using the
  exact hand-escape shape the same comment block explicitly forbids.
- **R3-02** — `phase06-oracle.sh`'s self-test prints "every fail-closed branch behaved exactly as
  expected" with **no pin on the case count**, while `check-beets-config.sh` added exactly that pin
  (`ST_PLANNED_CASES`) in the same round. The oracle is the file where the unpinned harness guards
  `rm -rf`.
- **R3-05** — the thirteenth exit-code notice's own measured counts were invalidated later in the
  same round by plan 06-26.

Measurement note: every grep below was run as `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD) by absolute
path, not the operator's zsh `grep` → ugrep alias. No script was executed against the estate; no
`--run`, `--arm` or `quick-health-check.sh` invocation was made. The self-tests were not re-run
(already verified by the orchestrator).

---

## Warnings

### R3-01: GC-17's site census is incomplete, and one surviving site uses the shape GC-17 forbids

**Severity:** WARNING
**File:** `scripts/quick-health-check.sh`
**Anchors:**
- claim — `EVERY OVERRIDABLE PATH THAT CROSSES INTO A REMOTE COMMAND STRING IS RENDERED ONCE WITH`
- claim — `There are FOUR such sites in this`
- prohibition — `DO NOT "fix" a future site of this shape by hand-escaping quotes inside the command string`
- surviving sites — `docker compose --profile $D03_CLI_PROFILE -f $D03_CLI_COMPOSE config`,
  `find $MUSIC_UNDERSCORE_ROOT -type d -name '_*'` (two hits),
  `docker exec sabnzbd sh -c 'cat \"$EXTCONF_PATH\"'`,
  `docker inspect $D03_FLASK_CONTAINER --format`

**Verified:** by grep (`/usr/bin/grep -nE '^[A-Z0-9_]+="\$\{[A-Z0-9_]+:-'` cross-referenced against
`/usr/bin/grep -n 'ssh -n \$SSH_OPTS'`). The injection consequence in the last paragraph is static
reasoning, **not executed**.

**Issue.** GC-17 states as a measured fact that there are four raw-interpolation sites and that all
four are now rendered through `printf '%q'`. Grep says otherwise. These overridable knobs are still
interpolated raw into a string that a remote shell parses:

| knob | default (line) | remote site |
|---|---|---|
| `D03_CLI_COMPOSE` | `stacks/selfhosted/arrs/beets/beets.yaml` (841) | `docker compose … -f $D03_CLI_COMPOSE` (1623) — **a path** |
| `D03_CLI_PROFILE` | `manual` (842) | `--profile $D03_CLI_PROFILE` (1623) |
| `D03_FLASK_CONTAINER` | `beets-flask` (837) | `docker inspect $D03_FLASK_CONTAINER` (1573) |
| `MUSIC_UNDERSCORE_ROOT` | `/mnt/tank/media/Music` (2553) | `find $MUSIC_UNDERSCORE_ROOT …` (2563 **and** 2591) — **a path** |
| `EXTCONF_PATH` | `/config/extended.conf` (901) | `cat \"$EXTCONF_PATH\"` (2118) — **a path** |

The last row is the sharp one. Line 2118 is inside `EXTCONF_CMD`, and the value is wrapped in
hand-escaped double quotes (`\"$EXTCONF_PATH\"`) inside a single-quoted remote `sh -c`. That is
verbatim the construction the new GC-17 comment forbids sixty lines earlier: *"A `\"` wrapper
survives a space but not a quote and not a `$`, and a half-measure that LOOKS like a fix is worse
here than the raw interpolation it replaces."* A value such as
`/config/x";cat /some/other/file;#` breaks out of the wrapper and injects into a remote
`docker exec sabnzbd sh -c`, and the block it feeds is the `requireBeetsMatch` guard — the one
standing between `audio.bash` and `rm -rf "$1"/*`. The consumer would then be parsing attacker-
chosen text as if it were `extended.conf`, which is a path to a green tick over a condition that was
never measured.

I am **not** grading this Critical: `EXTCONF_PATH` is an operator-set environment knob, not
attacker-controlled input, and the default value is safe. What makes it a finding is that round 2
declared the class closed inside this file while a documented-forbidden instance of it remained
three hundred lines below, unmentioned.

The other four rows fail closed on a space (`find` exits non-zero → `pipefail` → the existing
could-not-look arm at `[ "$UNDERSCORE_RC" -ne 0 ]`), so they degrade a knob from "drives the branch"
to "cannot be driven" rather than producing a wrong answer — except in the case where both split
words happen to name real directories, where `find` exits 0 and the count silently becomes a union.

**Fix.**
```bash
# beside each remaining knob, same shape as DRIFT_REPO_ROOT_Q / D03_REPO_ROOT_Q
D03_CLI_COMPOSE_Q=$(printf '%q' "$D03_CLI_COMPOSE")
MUSIC_UNDERSCORE_ROOT_Q=$(printf '%q' "$MUSIC_UNDERSCORE_ROOT")
EXTCONF_PATH_Q=$(printf '%q' "$EXTCONF_PATH")
```
and for 2118, pass the path as `sh -c`'s **positional parameter** rather than interpolating it at
all — the shape `phase06-oracle.sh`'s `remote_sh_c` already uses:
```bash
_ec=\$(timeout $REMOTE_TIMEOUT docker exec sabnzbd sh -c 'cat "\$1"' sh $EXTCONF_PATH_Q 2>/dev/null)
```
Then correct the "FOUR such sites" sentence to the measured number, or restate it as "the four
sites plan 06-26 owned", which is what it actually means.

---

### R3-02: the oracle's self-test claims a universal over an unenumerated set — no case-count pin

**Severity:** WARNING
**File:** `scripts/phase06-oracle.sh`
**Anchors:** `ok "self-test: $ST_RUN case(s), every fail-closed branch behaved exactly as expected"`;
the dispatcher block containing `self_test_core`, `self_test_classes`, `self_test_vacuity`,
`self_test_fences`.
**Verified:** by grep — `/usr/bin/grep -n 'ST_RUN\|ST_PLANNED\|ST_FAIL=' scripts/phase06-oracle.sh`
returns six hits and **none** of them is a comparison of `ST_RUN` against an expected constant.

**Issue.** The self-test gate is:

```sh
if [ "$ST_FAIL" -ne 0 ] || [ "$REDS" -ne 0 ]; then … exit 1; fi
ok "self-test: $ST_RUN case(s), every fail-closed branch behaved exactly as expected"
```

`ST_RUN` is *reported*, never *asserted*. The banner makes a universal claim ("every fail-closed
branch") over a set whose size nothing pins. Concrete failure scenario: a future edit drops
`self_test_fences` from the dispatcher (or an early `return` inside it fires, or a rebase loses the
one line that calls it). `ST_FAIL` stays 0, `REDS` stays 0, the script exits 0, and the banner
reads `self-test: 113 case(s), every fail-closed branch behaved exactly as expected` — a green over
a set that no longer contains the *only* executed test of the `rm -rf` / `rm -f` receiving-side
fences. That is the whole GC-02 closure becoming unguarded without a single case going red.

This is not hypothetical drift risk invented by a reviewer: **`check-beets-config.sh` added exactly
this guard in the same round**, with the reasoning written out in band —

> `ST_PLANNED_CASES` is the ANNOUNCED count; `st_cases` is what actually ran, and the two are
> compared at the end. A banner that says one number while another number of cases ran is the
> self-invalidating-prose defect this phase has already hit twice.

The oracle is the file where the unpinned harness certifies the destructive fences, and it is the
file that did not get the guard.

**Fix.** Mirror the sibling:
```sh
ST_PLANNED_CASES=134   # measured, not guessed; re-measure when a section is added
…
if [ "$ST_RUN" -ne "$ST_PLANNED_CASES" ]; then
  printf '  \342\234\227 self-test: %s cases ran but %s were announced — a section did not run\n' \
    "$ST_RUN" "$ST_PLANNED_CASES"
  exit 1
fi
```
A weaker but zero-maintenance alternative is a per-section pin (each `self_test_*` asserts its own
section ran at least one case, recorded by a sentinel the dispatcher checks) — that survives adding
cases without re-pinning a global total.

---

### R3-03: GC-15 fixed the sending side only — a space-bearing `REAL_LIB_DB` still cannot be measured

**Severity:** WARNING
**File:** `scripts/phase06-oracle.sh`
**Anchors:** `GC-15. \`dex_cmd\` renders its arguments with "$*"` (the claim);
`rsh "$(dex_cmd sha256sum "$(printf '%q' "$REAL_LIB_DB")"` (both sites);
`LIB_SHA_BEFORE="$(LC_ALL=C awk -v p="$REAL_LIB_DB" '$2 == p {print $1}'`
**Verified:** static reasoning over `sha256sum`'s documented output format. **Not executed** — the
site contacts the estate.

**Issue.** The GC-15 comment says, of the local consumers:

> The consuming `awk -v p=…` keys below stay RAW on purpose: the remote shell REMOVES the `%q`
> quoting before `sha256sum` is exec'd, so `sha256sum` receives, and prints, the unquoted value.

Both halves of that sentence are true and the conclusion still does not follow. `sha256sum` prints
`<hash><SP><SP><path>` and does **not** quote or escape a space in the filename. `awk`'s default
field splitting then puts `/config/my` in `$2` and `library.db` in `$3`, so `$2 == p` never matches
for exactly the input GC-15 was written to support. Result:

- `LIB_SHA_BEFORE` is empty → the guard two lines down
  (`[ -n "$LIB_SHA_BEFORE" ] || { unknown …; exit 3; }`) fires and the run exits 3 UNKNOWN, always.

So the fix makes the remote command correct and the run *still* cannot measure a space-bearing
path. It fails closed, which is why this is a WARNING and not a Critical — but the knob remains
undriveable, and "an undriveable branch is an unproven branch" is this file's own stated reason for
having the knob at all.

**Fix.** Key on the suffix rather than on field 2, so the path may contain spaces:
```awk
LC_ALL=C awk -v p="$REAL_LIB_DB" '{ sub(/^[0-9a-f]+  /, "", $0); if ($0 == p) { … } }'
```
or more simply capture the hash by position:
```bash
LIB_SHA_BEFORE="$(LC_ALL=C awk -v p="  $REAL_LIB_DB" \
  'index($0, p) == length($0) - length(p) + 1 { print substr($0, 1, 64) }' "$OUT/layer3.before")"
```
Whichever is chosen, amend the comment: the current one asserts the consumer is fine, and it is
not.

---

### R3-04: the layer-3 AFTER hashes have no emptiness guard, so a could-not-look reports as a measured change

**Severity:** WARNING
**File:** `scripts/phase06-oracle.sh`
**Anchors:** `LIB_SHA_AFTER="$(LC_ALL=C awk -v p="$REAL_LIB_DB"`;
`bad "layer 3: the real library.db CHANGED`;
compare with the BEFORE side's `[ -n "$LIB_SHA_BEFORE" ] || { unknown "no sha256 line for`
**Verified:** static, by reading both blocks. **Not executed.**

**Issue.** The BEFORE block guards both hashes for emptiness and routes an empty one to
`unknown(); exit 3`. The AFTER block does not. If the second `sha256sum` line is absent,
unparseable, or lost to a partial `RSH_OUT`, `LIB_SHA_AFTER` is empty, the comparison
`[ "$LIB_SHA_AFTER" = "$LIB_SHA_BEFORE" ]` is false, and the script emits:

```
❌ layer 3: the real library.db CHANGED (<64-hex> -> )
```

That is a **measured failure asserted over a could-not-look** — the arrow points at an empty
string. It is the inverse of GC-05, which this same round spent two guards and two self-test cases
correcting in the opposite direction ("a rule the run never exercised cannot have measurably
failed"). The file's own EXIT CODES block says a could-not-look is never folded into another
verdict; here it is folded into RED, and because UNKNOWN outranks RED in this file's precedence,
the misclassification also demotes the verdict.

It is a false red, not a false green, so the estate is not at risk — but it sends the operator
hunting a library mutation that did not happen, on the one assertion whose whole job is to prove
`-l` kept the real `library.db` closed.

**Fix.** Symmetry with the BEFORE block:
```bash
[ -n "$LIB_SHA_AFTER" ]   || { unknown "no sha256 line for $REAL_LIB_DB after the run";       exit 3; }
[ -n "$STATE_SHA_AFTER" ] || { unknown "no sha256 line for $REAL_STATE_PICKLE after the run"; exit 3; }
```

---

### R3-05: the thirteenth exit-code notice's measured counts were invalidated later in the same round

**Severity:** WARNING
**File:** `scripts/quick-health-check.sh`
**Anchors:** `The raw count therefore still runs THREE ahead of the header count, unchanged by this edit.`
(the claim, in the 06-23 notice) and
`NOT ADDED HERE, deliberately: a new \`EXIT-CODE BEHAVIOUR CHANGED\` notice.` (the 06-26 line that
broke it).
**Verified:** by execution — `/usr/bin/grep -c 'EXIT-CODE BEHAVIOUR CHANGED' scripts/quick-health-check.sh`
returns **17**. Enumerated, the notice *headers* (lines beginning `# ⚠️  EXIT-CODE BEHAVIOUR
CHANGED`) number **13**.

**Issue.** The thirteenth notice states, as a measurement taken across its own edit:

```
headers   12 -> 13
raw       15 -> 16
The raw count therefore still runs THREE ahead of the header count, unchanged by this edit.
```

Measured now: headers 13, raw **17**, delta **four**. The extra raw occurrence is at the tail, added
by plan 06-26's GC-09 repair — the line that says a new notice was deliberately *not* added, which
in saying so added a raw match. Two plans in the same round, one stating an invariant and the next
breaking it without touching the statement.

This matters more than a typo because the eighth notice institutionalised these two counts as the
file's own drift detector for exactly this problem (it records the historic case where
`grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` returned 1 while the file held two notices). A detector
whose stated baseline is wrong sends the fourteenth notice's author to a false starting number.

Separately verified and **correct**, so noted here to close it: the notice's other measured claim —
that the next free condition letter is `P` because `M`, `N` and `O` are taken out of alphabetical
order — holds. `/usr/bin/grep -nE '^#[[:space:]]+[A-Z]\.[[:space:]]'` returns A–L at ascending
lines, then `O` at 545, `M` at 561, `N` at 569, `P` at 600. The warning against counting forward
from the last notice's highest letter is well founded.

**Fix.** Re-measure and correct the two numbers in the thirteenth notice (`raw 15 -> 17`, delta
four), or — better, given this is the third time these counts have drifted — stop asserting a
constant delta and state only the grep to run.

---

## Info

### R3-06: `self_test_fences`'s in-band safety claim is broader than the cases that back it

**Severity:** INFO
**File:** `scripts/phase06-oracle.sh`
**Anchor:** `it contains NO \`rm\`, NO \`touch\` and NO redirection into a path, and three cases below assert exactly that`
**Verified:** by reading the three cases (`case "$SCRATCH_FENCE_SH" in *"rm "*`, and its two twins).

The comment names three properties and says three cases assert "exactly that". The three cases
assert **one** property — absence of the two-character token `rm ` — for three different fence
strings. `touch` is not asserted at all. "No redirection into a path" is not merely unasserted but
false as stated: every fence text contains `>&2`. The claim is load-bearing, because it is the
stated reason a reader may trust that these cases cannot delete anything, and the brief for this
section explicitly says the claim "has to be checkable by the next reader without running it".

Also note the token test is `*"rm "*`, which a tab-separated or newline-terminated `rm` would slip
past. Given the fence texts are three short literals under version control this is not a live risk,
but the assertion is weaker than its wording.

**Fix.** Either widen the cases (`*rm*`, `*touch*`, `*">"*` with the `>&2` occurrences accounted
for) or narrow the prose to what is executed: "no case below executes a destructive program, and
three cases assert that no fence text contains the token `rm `."

### R3-07: the D-04 source contract is enforced only under `--self-test`, and its BLIND arm feeds no counter

**Severity:** INFO
**File:** `scripts/check-beets-config.sh`
**Anchors:** `assert_beet_invocation_contract() {`; `the checker is BLIND`;
`ARM1_FAILS keeps exactly the value it always had, because the live arm-1 summary line is a second consumer of it`
**Verified:** by grep — `assert_beet_invocation_contract` has exactly two hits, the definition and
one call site inside `run_self_test`.

Two observations, neither active today:

1. The GC-13 comment justifies preserving `ARM1_FAILS`'s value on the grounds that "the live arm-1
   summary line is a second consumer of it". `ARM1_FAILS` does have a live consumer
   (`echo "  arm-1 assertion failures:    $ARM1_FAILS"`), but **this function never runs live**, so
   the stated reason does not apply to the change it justifies. The preserved value is correct; the
   reason given for preserving it is not.
2. Inside the function, the *correct* outcome (synthetic rejected) calls `cfg_fail`, while the
   *defective* outcome (checker BLIND) is a bare `echo -e`. Under `--self-test` that is fine —
   `cfg_fail` routes to a per-case counter and the new `ARM1_SYNTH_REJECTED` gate catches the blind
   arm. But the polarity is inverted with respect to `FAILURES`, so the moment anyone wires this
   function into the live path (an obvious next step, since a live run currently never checks the
   `-l`+`-c` source contract at all) a *correct* run increments `FAILURES` and a *blind* checker
   increments nothing.

**Fix.** Correct the GC-13 sentence, and if the function is ever called live, route the BLIND arm
through `cfg_fail` and the correctly-rejected-synthetic arm through a self-test-only echo.

### R3-08: case 6's `expect_reds` is announced but no longer gated

**Severity:** INFO
**File:** `scripts/check-beets-config.sh`
**Anchor:** `case_name="the -l + -c contract over this script's own source"; expect_reds=1`

After GC-13 the gate reads `ARM1_REAL_VIOLATIONS` and `ARM1_SYNTH_REJECTED`; `expect_reds` survives
only to print `(expect 1 red)` in the banner, and the success line still prints
`$ARM1_FAILS red, as expected` — a number nothing compares. This is a smaller instance of precisely
the announced-vs-actual drift that `ST_PLANNED_CASES` was added twenty lines below to prevent: the
banner can say "expect 1 red" while the gate passes on a run that produced 0 or 2.

**Fix.** Either drop `expect_reds` from this case and print the two gated values instead
(`real violations $ARM1_REAL_VIOLATIONS, synthetic rejected $ARM1_SYNTH_REJECTED`), or keep it and
add `[[ $ARM1_FAILS -eq $expect_reds ]]` as a third conjunct so the banner and the gate cannot
disagree.

### R3-09: the minted scratch names are cleaned on `EXIT` only, and the remote programs run under `timeout`

**Severity:** INFO
**File:** `scripts/phase06-incremental-control.sh`
**Anchors:** `trap 'case "${MANDIR:-}" in /tmp/p6-mf.*) rm -rf "$MANDIR" ;; esac' EXIT`;
`trap 'case "${THPROG:-}" in /tmp/p6-taghist.*) rm -f "$THPROG" ;; esac' EXIT`;
the transport at `timeout $REMOTE_TIMEOUT docker exec -i -u beetle $CONTAINER sh -s`
**Verified:** grep-confirmed that both remote programs are delivered through the `timeout`-wrapped
`docker exec` at line 396. The signal behaviour below is static reasoning about POSIX `sh`, **not
executed** against the container.

The GC-08 comment argues, correctly, that a trap beats the old trailing `rm -f` because every BLIND
arm exits early. But a POSIX shell runs an `EXIT` trap on normal termination and on `exit`, not on
an uncaught `SIGTERM`/`SIGKILL`. These programs are `sh -s` under `timeout $REMOTE_TIMEOUT docker
exec`, so a bound expiry — which is a routine, expected outcome for a manifest over a large tree —
can terminate the in-container shell without the trap running. The residue is then exactly what the
comment names as the worse case: *"a MINTED leftover is worse litter than a fixed one, because
nobody knows its name."* The fixed names at least self-limited to three; minted ones accumulate one
directory per timed-out run, in a `/tmp` the same header describes as mode 1777.

**Fix.** Widen both traps, which is one token each:
```sh
trap 'case "${MANDIR:-}" in /tmp/p6-mf.*) rm -rf "$MANDIR" ;; esac' EXIT INT TERM HUP
```
and consider a best-effort sweep of `/tmp/p6-mf.*` older than a day in the same program, gated on
the same prefix.

### R3-10: the new in-container fences are bare globs — the property GC-02 just removed from the sibling file

**Severity:** INFO
**File:** `scripts/phase06-incremental-control.sh`
**Anchors:** `case "${MANDIR:-}" in /tmp/p6-mf.*) rm -rf "$MANDIR" ;; esac`;
`The trap re-checks the name against the template prefix so it can never remove anything else.`
**Verified:** static, by the same argument GC-02 makes in `phase06-oracle.sh`.

GC-02's whole content, in the sibling file, is that a shell glob `*` matches `/` while the
character class `[A-Za-z0-9._-]` does not, so `/tmp/p6-x/../../../home` passed a bare-glob fence
and would have reached `rm -rf`. In the *same round*, this file introduces two fresh fences of
exactly the bare-glob shape, both adjacent to `rm -rf` / `rm -f`, and the comment beside one of them
claims it "can never remove anything else" — the same category of claim GC-02 records as having
been false at birth.

`/tmp/p6-mf.a/../../../home` matches `/tmp/p6-mf.*`. This is **not currently reachable**: `MANDIR`
and `THPROG` are only ever `mktemp` output, and `mktemp` will not emit a traversal. So the defect is
latent, and the finding is the *inconsistency plus the overstated claim*, not an exploit. But the
lesson round 2 drew was explicitly that a fence with a stronger comment than code is how the real
fence eventually gets deleted as duplicated, and this is a new instance of that shipped in the
commit that drew the lesson.

**Fix.** Use the GC-02 predicate the sibling now carries, so the two files state the same rule:
```sh
trap 'case "${MANDIR:-}" in
        /tmp/p6-mf.*) case "${MANDIR#/tmp/p6-mf.}" in ""|*[!A-Za-z0-9._-]*) : ;; *) rm -rf "$MANDIR" ;; esac ;;
      esac' EXIT INT TERM HUP
```
or, at minimum, soften the comment to "re-checks the prefix" rather than "can never remove anything
else".

---

## Verified-and-clean (recorded so round 4 does not re-litigate)

These were checked adversarially and are correct as written. Each is a place a reviewer would
expect a defect given this codebase's history.

- **GC-01 here-strings** (`check-beets-config.sh`): `grep -qF -- "$forb" <<<"$raw"` on both the
  built-in and the `EXTRA_FORBIDDEN_SUBSTRINGS` loops. No `| grep -q` remains in the file outside
  comments (`/usr/bin/grep -n '| *grep -q'` → two hits, both inside explanatory prose).
- **Case 7 is genuinely a regression case**, not decoration. `FORBIDDEN_BUILTIN` is
  `("Compilations" "/music/imported")`; the pad is `"Compilations" + 70000 × 'x'` placed at the
  **top**, which is the only position that would have been missed by the broken form; the pad
  contains neither `/music/imported` nor a `"` that could terminate the YAML scalar, so the
  expected red count is exactly 1.
- **`D04_N_ASSERT` is computed correctly for the empty set.** `D04_N_ASSERT=$(printf '%s\n' "$D04_INVOKE_ASSERT" | grep -c '^HEAD:')`
  yields 0 on the empty string — this is *not* the `printf | wc -l` off-by-one, and condition P's
  arm therefore actually fires.
- **The `-1` UNKNOWN sentinels** on `ARM1_REAL_VIOLATIONS` / `ARM1_SYNTH_REJECTED` do what they
  claim: a case-6 gate reached without the producer having run fails, rather than passing on a zero.
  `run_assert`'s `case` routes `0 → ok`, `1 → bad`, `*) → unknown`, so GC-05's `return 2` lands in
  `unknown()` as documented.
- **`self_test_fences` cannot delete anything.** Every behavioural case drives a `*_FENCE_SH`
  string, never a `*_PROG`; the three prefix cases carry the fence-to-program link structurally; the
  byte-identity case between the two stamp fences is a real executed drift check. The refusal
  wordings genuinely differ between the scratch and stamp fences.
- **GC-07's correction is sound**, and the honesty is worth recording: the comment now says the
  `$$` run tag buys nothing (it is the macOS workstation's PID, unrelated to the container
  namespace) and credits `SCRATCH_PROBE_PROG` instead. Grep confirms the probe runs at step 1 of the
  real path (`rsh "$(dex_cmd "$(remote_sh_c "$SCRATCH_PROBE_PROG" "$SCRATCH")")"`) before anything
  is written into `$SCRATCH`.
- **GC-12(a)'s deletion of `UNKNOWNS=0` is safe** — the self-test gate reads `ST_FAIL` and `REDS`
  only, confirmed at the dispatcher.
- **GC-14's override notices are pure `echo`s** on every arm and touch no counter, so the additive
  contract ("an override may drive any arm and can never produce the tick") is preserved.
- **GC-16's regex widening** adds `[[:space:]](&&|;)[[:space:]]*` and `docker[[:space:]][^\`]*[[:space:]]`
  to the fourth branch's anchor alternation while leaving the `(-|[a-z])` follower test intact,
  which is what keeps the executable count at 8 rather than 26.

---

_Reviewed: 2026-09-22_
_Reviewer: Claude (gsd-code-reviewer), round 3_
_Depth: standard_
_Scope: `git diff bf509f4..HEAD` over four scripts; no estate contact, no self-test re-runs_

---

## Dispositioned 2026-09-23 — this file is now WIRED

*Appended by plan 06-34. **Nothing above this line was edited.** Every finding's text, every anchor,
the `findings:` frontmatter counts and the Verified-and-clean section are the record of what was
found on 2026-09-22, and that record stands — including where a later measurement refined it.*

**All ten findings carry an explicit disposition**, recorded in:

> **`.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP2.md`**

with one row per finding ID (`R3-01` … `R3-10`) in ID order, each citing the plan, the commit and
the artifact holding the driven transcript, each carrying a **provenance clause** naming who
confirmed the finding and how, and each carrying a **fix-kind** — `CODE`, `CLAIM CORRECTION` or
`BOTH`.

Summary: **9 FIXED, 1 FIXED (undriven), 0 ACCEPTED, 0 CARRIED — 10 total.** The counts reconcile
three ways: this file's frontmatter 0 + 5 + 5 = **10**; the dispositions 9 + 1 + 0 + 0 = **10**; the
fix kinds 4 CODE + 3 CLAIM CORRECTION + 3 BOTH = **10**.

**The fix-kind column is the point of this round.** The central charge above is that round 2 closed
several classes partially and then claimed they were closed completely. A register of ten
undifferentiated `FIXED` rows would reproduce that ambiguity one level up, so the register
distinguishes a widened fence from a narrowed sentence, and records **per finding** what was not
driven — the whole layer-3 block (R3-03, R3-04), the `SIGTERM` behaviour behind R3-09, and
`quick-health-check.sh`, which was not executed at all by the review or by the fix.

The fixes were made by gap-closure plans **06-30, 06-31, 06-32 and 06-33**; plan **06-34** wrote the
register and wired it. Round 3's residue — **including the round's two deliberate refusals** — is
carried by name as `DEF-06-34-01` … `DEF-06-34-06` in `deferred-items.md`. **There was no
cross-family adjudication in round 3**, so nothing is appended below the review's own ten; the
register says so explicitly, because an absent adjudication that is not mentioned reads like a lost
one.

**One correction, in band: R3-07's census sentence is wrong, and the finding is not.** Its
**Verified** line reads *"`assert_beet_invocation_contract` has exactly two hits"*. Raw
`/usr/bin/grep -cF` gives **4** at the tree under review and **5** after plan 06-33 — definition,
one call, and comment mentions the round under review added. It gives 2 only at this review's own
`diff_base` `bf509f4`. **The finding's conclusion is correct and entirely unaffected**: exactly two
occurrences are *code*, the code call is inside `run_self_test`, and the function does not run live.
Only the census is wrong. It is recorded here the way round 2 recorded the GC-15/GC-17 label
crossing — **as a correction in band, not a silent fix and not a downgrade of the finding** — and
the durable figure is the comment-stripped **2**, which is what the script and 06-33's verify now
pin. Caught during round-3 planning, because a verification that pinned the review's number would
have failed on arrival.

**The Verified-and-clean section above is closed against round 4.** Its nine items are reproduced in
the register under a heading saying so; a round-4 finding that merely restates one of them is not a
new finding. Two were touched by round 3 and remain clean: the `-1` sentinels are unchanged, and
R3-06 narrowed the prose beside the three `rm ` cases while deliberately **not** widening the cases
themselves.

**This is a record, not a re-close.** No `/gsd-verify` was run by plan 06-34 and no verification
result is claimed. **CONF-04 is not closed**, `REQUIREMENTS.md` is untouched, and ROADMAP entry
criterion **E6** still owns the Jellyfin half. No requirement checkbox moved and the phase is **not**
declared complete.

_Dispositioned: 2026-09-23 by plan 06-34_
