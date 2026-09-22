---
phase: 06-tagger-configuration-and-dry-run
reviewed: 2026-09-22T10:45:00Z
scope: gap-closure
depth: deep
diff_base: 7d1092b
diff_head: 57ccdbf
plans_covered: 06-15, 06-16, 06-17, 06-18, 06-19, 06-20, 06-21
files_reviewed_list:
  - scripts/phase06-oracle.sh
  - scripts/quick-health-check.sh
  - scripts/check-beets-config.sh
  - scripts/phase06-incremental-control.sh
  - scripts/check-music-consumers.sh
  - stacks/selfhosted/arrs/beets.md
findings:
  blocker: 1
  warning: 7
  info: 7
  total: 15
status: issues_found
---

# Phase 6 — Gap-Closure Code Review

**Reviewed:** 2026-09-22
**Diff range:** `7d1092b..57ccdbf` (`main`)
**Depth:** deep (static reading + `bash -n` + `shellcheck 0.11.0` + local reproduction of shell
semantics in a scratch directory; **nothing was run against the live estate** — no ssh, no docker,
no `--run`, no `--baseline`, no `--self-test`)
**Finding ID space:** `GC-01 … GC-15`

## Scope statement

**This review covers the gap-closure changes only** — the six source files touched by plans 06-15
through 06-21 in the range `7d1092b..HEAD`. **It does not supersede, replace or amend
`06-REVIEW.md`**, the 2026-09-21 review whose 24 findings (`CR-01`, `WR-01…WR-10`, `IN-01…IN-13`)
these plans were written to close. `06-REVIEW.md` was read as context and left untouched, including
the disposition-wiring section plan 06-21 appended to it. The `GC-NN` IDs below are a deliberately
separate space so the two sets cannot be confused; where a finding bears on a `06-REVIEW.md`
finding, that finding is named in the text.

The six items listed as known-and-deliberate in the review brief (the two instruments' differing
exit-code *numbering*, the D-04 block's UNKNOWN against the pre-Phase-6 host, the intended
non-zero consumers block until E6, `check-music-freeze.sh`'s pre-existing SC2034, the additive
`*_REPO_ROOT` / `CONSUMERS_SCRIPT` knobs, and the two historic quotations in `beets.md`) were
checked and are **not** reported. The additive contract on the new knobs was verified in code and
holds: `D03_REPO_ROOT`, `D04_EXEMPT_BASELINE` and `CONSUMERS_SCRIPT` each set `EXIT_CODE=1` on any
non-default value, and each override arm is placed so it cannot reach a green tick
(`quick-health-check.sh:1456`, `:1723-1727`, `:2238-2247`).

## What was verified as correct

Stated because an adversarial review that only lists faults is not a reading:

- **`remote_sh_c`'s quoting is correct end to end.** Rendered locally against a fixture named
  `Guns N' Roses - $Greatest` and driven through `bash -c`: the apostrophe and the `$` both survive
  intact, the program text carries no path, and the literal `sh` `$0` placeholder is present so the
  first real argument is not eaten. The `-printf` format's real tab and real newline round-trip
  byte-for-byte through `printf '%q'`'s `$'…'` rendering.
- **No path reaches remote *program text* unquoted** in any of the eighteen remote call sites in
  `phase06-oracle.sh`. Two remaining raw interpolations are into bash *word* context, not program
  text — see GC-15.
- **The D-04 widening works on the current tree.** Reproducing the block's whole pipeline locally
  against this repo's `HEAD` yields invocation-shaped 10, executable 8 = asserted 3 + exempt 5,
  documentation 2 — matching the pins. The 26-vs-8 claim about the naive form holds: every line
  the fourth branch rejects (`[[ $BEET_EXEC_RC -eq 0 ]]`, `"$BEETS_DB_COUNT"`,
  `remote_exec … "$BEET" "$PY"`) genuinely runs nothing.
- **`check-music-consumers.sh`'s exit path ordering is right.** `--baseline → 0`, `FAILURES>0 → 1`,
  `PENDING>0 → 3`, green banner last and therefore unreachable while pending is non-zero.
  `FAILURES` is 0 on every exit-3 run by source order, as the header claims. The `📊 6. Summary`
  anchor really does emit `artist rows` lines (`:1625-1629`), so the new fold-in's
  `grep -E 'MA version|artist rows|FAILURES total'` is not a dead pattern.
- **`shift 2` is gone from `phase06-incremental-control.sh`'s dispatch** and the replacement takes a
  value only when one is present; no flag in that `case` can now exit 1 under `set -e`.
- `bash -n` clean on all five scripts. `shellcheck` produces no error- or warning-level findings on
  any of them.

---

## BLOCKER

### GC-01 — `printf | grep -q` under `pipefail` can report a present forbidden substring as ABSENT

**Severity:** BLOCKER
**File:** `scripts/check-beets-config.sh:554` and `scripts/check-beets-config.sh:567`
**Confidence:** mechanism **proven locally**; whether it fires against the live estate **today** is
unconfirmed and is size-dependent — stated as latent, not as currently firing.

```bash
552:  local forb
553:  for forb in "${FORBIDDEN_BUILTIN[@]}"; do
554:    if printf '%s' "$raw" | grep -qF -- "$forb"; then
...
567:      if printf '%s' "$raw" | grep -qF -- "$forb"; then
```

The file runs `set -euo pipefail` (`:111`). `grep -q` exits the moment it matches. When `$raw` is
larger than the pipe buffer, `printf` is still writing, takes `SIGPIPE`, and exits 141; `pipefail`
makes the **pipeline** 141; the `if` therefore evaluates **false** — and the forbidden substring
that *is* present is silently **not reported**.

Measured on this workstation (macOS, BSD grep 2.6.0, multi-line input with the match on line 1):

| input size | pipeline rc |
|---|---|
| 8 / 16 / 32 / 48 / 56 KiB | 0 (reported correctly) |
| **64 / 72 / 128 KiB** | **141 (silently missed)** |

`$raw` is the whole arm-1 server-committed dump (`assert_effective_config "$ARM1_JSON" "$(cat
"$WORKDIR/arm1.dump")"`, `:958`) — a multi-line YAML/JSON config dump that grows with every beets
release and every plugin enabled. The brief records one instance of this shape measured at ~17%
below the 64 KiB ceiling; that is consistent with this being it. It is the only remaining instance
in the gap-closure set whose input is *estate-sized* rather than a one-line command string.

**Why it matters:** `FORBIDDEN_BUILTIN=("Compilations" "/music/imported")` is the guard that proves
no rule in the effective config routes anything into a `Compilations/` tree or the retired import
root. A false negative here is a green tick over a condition that is present — the exact defect
class the whole gap closure existed to remove — and the failure is *position-dependent*: a match
near the **top** of a large dump is missed, one near the **bottom** is reported.

**Fix** (no pipe, therefore no SIGPIPE, therefore no `pipefail` interaction):

```bash
if grep -qF -- "$forb" <<<"$raw"; then
```

or grep the file the dump already lives in:

```bash
if LC_ALL=C grep -qF -- "$forb" "$WORKDIR/arm1.dump"; then
```

Note the self-test path (`run_case`, `:644`) feeds small synthetic dumps, so **the self-test cannot
detect this**. If the fix lands, add a case with a >64 KiB synthetic dump carrying the forbidden
substring on its first line.

---

## WARNINGS

### GC-02 — the two copies of each destructive fence are NOT equivalent; the inner one admits `..`

**Severity:** WARNING (considered BLOCKER; not raised because the strong outer fence runs first on
every mode and nothing is exploitable as shipped — see "why not a blocker" below)
**Files:** `scripts/phase06-oracle.sh:327-340` vs `:2685-2690`; `:342-353` vs `:2406-2410` and
`:2698-2702`
**Confidence:** high — read directly from both fence texts.

The **sending-side** fence restricts the suffix to a character class:

```bash
327: case "$SCRATCH" in
328:   /tmp/p6) : ;;
329:   /tmp/p6-*)
330:     case "${SCRATCH#/tmp/p6-}" in
331:       ''|*[!A-Za-z0-9._-]*) SCRATCH_FENCE_OK=0 ;;
```

and its own comment says why: *"The suffix character class is deliberately narrower than the glob:
`/tmp/p6-*` on its own would still admit `/tmp/p6-x /config`, which is the very shape the fence
exists to refuse."*

The **receiving-side** fence — the one adjacent to the `rm -rf` — is exactly that bare glob:

```bash
2685: CLEANUP_PROG='case "$1" in
2686:   /tmp/p6|/tmp/p6-*) : ;;
...
2689: rm -rf "$1"
```

and the stamp pair is the same shape (`/mnt/fast/safety/phase06/*`, `:2406-2408` and `:2698-2700`).
`[A-Za-z0-9._-]` excludes `/`; the glob does not. So the inner fence accepts
`/tmp/p6-x/../../../home` and `/mnt/fast/safety/phase06/../../../../etc/shadow`, and would run
`rm -rf` / `rm -f` on them.

**Why this is a finding rather than a nit:** the inner fence is documented at three sites as the
layer whose *purpose* is to survive the loss of the outer one — *"the sending layer stops the
common case; this one is the one that cannot be bypassed by a future edit that forgets the first"*
(`:2404-2405`, restated at `:2684`). That claim is **false as written**. The two copies the brief
asked to be checked for drift have already drifted, at birth, in the direction that matters. The
next reader who deletes the outer fence as "duplicated" gets a path-traversal-capable `rm -rf` and
a comment telling them it is covered.

**Why not a BLOCKER:** as shipped, the outer fence runs before the first ssh of any mode
(`--run`, `--baseline`, `--self-test` all pass through `:327`), `remote_sh_c` passes the path as a
positional parameter so nothing can re-split it in transit, and `"$1"` is quoted at the `rm`. No
current invocation reaches the weak fence with a hostile value.

**Fix:** make the inner fence literally the same predicate as the outer one, in dash-compatible
form, at all three sites:

```sh
case "$1" in
  /tmp/p6) : ;;
  /tmp/p6-*)
    case "${1#/tmp/p6-}" in
      ''|*[!A-Za-z0-9._-]*) echo "REFUSED: ..." >&2; exit 3 ;;
    esac
    ;;
  *) echo "REFUSED: ..." >&2; exit 3 ;;
esac
```

and the same nested form for `/mnt/fast/safety/phase06/`. A `--self-test` case driving
`SCRATCH=/tmp/p6-x/../etc` against `CLEANUP_PROG`'s text with the local `sh` would have caught this
and costs four lines.

### GC-03 — the D-04 block can still tick green over an empty asserted set (CR-01, one level down)

**Severity:** WARNING
**File:** `scripts/quick-health-check.sh:1791-1796` (the new vacuity guard) and `:1798-1829`
**Confidence:** high — the `while … <<< "$EMPTY"` behaviour was confirmed locally (0 iterations).

Plan 06-16 added condition **K**, the guard that refuses a zero **executable** count:

```bash
1791: elif [ "$D04_N_EXE" -eq 0 ]; then
```

But the set the block actually **asserts over** is `D04_INVOKE_ASSERT` = executable **minus
exempt**, and nothing guards *that* being zero. Trace it:

- `D04_N_EXE` = 8, `D04_N_EXEMPT` = 5, `D04_N_ASSERT` = 3 today.
- Delete or reshape the three `check-beets-config.sh` invocations and `D04_N_EXE` becomes 5,
  `D04_N_EXEMPT` stays 5, `D04_N_ASSERT` becomes **0**.
- Guard K does not fire (5 ≠ 0). The exempt pin does not fire (5 = 5). The doc pin does not fire.
- `while IFS= read -r d04_line … done <<< "$D04_INVOKE_ASSERT"` over an empty string runs the body
  **zero** times (verified), so `D04_BAD` stays 0.
- `:1824` is therefore satisfied and the block prints
  `✅ no ASSERTED beet invocation opens the real library (0 of 5 invocation-shaped lines outside *.md)`.

A green tick whose own parenthesis says it asserted over nothing — which is, verbatim, the CR-01
defect this plan was written to close, reproduced one nesting level in. Note the same reshaping
could happen silently: the fourth `D04_INV_RE` branch requires the `BEET` variable to sit at content
start or immediately inside an opening quote, so moving an invocation behind `&& ` or `| ` (shapes
the *literal*-`beet` branches do cover) drops it out of the executable set without any counter
moving off its pin.

**Fix:** add the missing arm, in the same vocabulary as K:

```bash
elif [ "$D04_N_ASSERT" -eq 0 ]; then
    echo "  ⚠️  UNKNOWN — every invocation-shaped executable line is EXEMPT ($D04_N_EXEMPT of"
    echo "  $D04_N_EXE). Nothing was asserted over. This is NOT 'no bare beet invocations'."
    EXIT_CODE=1
```

and, belt and braces, add `&& [ "$D04_N_ASSERT" -gt 0 ]` to the green condition at `:1824`.

### GC-04 — three cross-file `file:line` citations introduced by this gap closure are wrong

**Severity:** WARNING
**Files:** `scripts/phase06-oracle.sh:324`, `:2405`, `:2684`;
`scripts/check-beets-config.sh:887`; `stacks/selfhosted/arrs/beets.md:2255`
**Confidence:** high — each target was opened and read.

| citation | cited as | actually at | actual content at the cited line |
|---|---|---|---|
| `phase06-incremental-control.sh:343` and `:473` (oracle `:324`) | the sibling's two literal `case` fences | **`:387`** and **`:520`** | `:343` is a comment; `:473` is `ROOT="$1"; PY="$2"; PROG="$3"` |
| `phase06-incremental-control.sh:473` (oracle `:2405`, `:2684`) | "has the same shape" / "fences its cleanup the same way" | **`:520`** | as above — not a fence |
| `beets/beets.yaml:71-78` (`check-beets-config.sh:887`) | "Phase 1 measured a bare `beet config` running 11 migrations unasked" | **`beets.yaml:22`** | `:71-78` is the EBUSY/EROFS single-file-mount measurement, a different subject |
| `phase06-oracle.sh` lines `2166, 2179, 2313` (`beets.md:2255`) | the three `$SCRATCH_OVERLAY` exempt invocations | **`2478`, `2491`, `2625`** | off by ~310 lines |

These are not decorative. The oracle's fence-duplication argument rests entirely on *"the sibling
already does this, at these lines"*; `beets.md`'s exemption register is the human-readable half of
`D04_EXEMPT_RE` and is what a reader checks the pin against. Two of the four went stale **inside
this gap closure**: plan 06-18 wrote the sibling citations, then plans 06-19/06-20 inserted ~130
lines above them; plan 06-16 wrote the `beets.md` line numbers, then plans 06-18/06-19 added ~450
lines to the oracle.

**Fix:** replace the numbers with greppable anchors, which is the convention this repository already
applies to the `📊 6. Summary` and `KEEP THIS HEADING LITERAL` cross-references — e.g. *"grep
`phase06-incremental-control.sh` for `PREP REFUSED` and `CLEANUP REFUSED`"* and *"grep
`phase06-oracle.sh` for `$SCRATCH_OVERLAY`"*. `beets.yaml:71-78` → `beets.yaml:22`.

### GC-05 — IN-09's vacuity guard returns RED where the phase's other three return COULD-NOT-LOOK

**Severity:** WARNING
**File:** `scripts/phase06-oracle.sh:880-888` (and its pre-existing twin at `:857-862`)
**Confidence:** high.

The four vacuity guards this gap closure added or touched do not agree on what a vacuous assertion
*is*:

| guard | plan | returns | `run_assert` routes it to |
|---|---|---|---|
| empty manifest (`manifest_compare`, `:142-145` of the diff) | WR-02 | **2** | `unknown()` → exit 3 |
| empty/unreadable fields TSV (`report_multi_artist`) | WR-06 | **2** | `unknown()` → exit 3 |
| empty field view (`assert_field_view`) | IN-12 | **2** | `unknown()` → exit 3 |
| **zero expected DJ count (`assert_dj_count:880`)** | **IN-09** | **1** | **`bad()` → REDS++ → exit 1** |

The same phase wrote, at the head of this very file (`:28-42`), that *"a blind instrument wins over
a measured red"* and that *"could not look is never folded into another verdict"*. A sample holding
no S5 files is precisely a could-not-look about the `albumtype:=dj` path rule — the run never
evaluated it. Returning 1 makes the oracle exit **1 (RED)**, which asserts a measured failure of a
rule the run did not exercise, and it makes that verdict **outrank nothing**: the precedence block
immediately below says UNKNOWN outranks RED, so a run that is both vacuous here and blind elsewhere
now reports the blindness and loses the vacuity entirely.

The guard's own message says `VACUOUS, not a pass` — the right words attached to the wrong code.
The justification given ("the guard its immediate neighbour has had from the start … returning the
same code") is accurate, but it propagates the neighbour's misclassification rather than fixing it.

**Fix:** `return 2` from `assert_dj_count`'s zero arm, and change `assert_no_compilations:861` in the
same commit so the pair stays symmetric. If the two are deliberately kept red, say so at both sites
and state why a vacuity here is a measurement while a vacuity three functions up is not — the
current text asserts both readings in one file.

### GC-06 — three `printf | grep -q` instances remain in shipped oracle code; one is an inverted assertion

**Severity:** WARNING
**File:** `scripts/phase06-oracle.sh:1809`, `:1828`, `:1831`
**Confidence:** high on the mechanism (reproduced); low on it firing today (inputs are one-line
command strings, far under the 64 KiB threshold).

Plan 06-19 introduced `st_grep_why` (`:2106-2111`) explicitly to avoid this shape, with a comment
saying *"that shape has produced a false red in three plans of this phase already"*. Plan 06-18's
WR-08 self-test section, 300 lines above it, uses the shape it warns about:

```bash
1809:  printf '%s\n' "$qout" | LC_ALL=C grep -qF "01 It's \$o.mp3" || rc=1
1828:    printf '%s' "$qcmd" | LC_ALL=C grep -qF " sh $(printf '%q' "$qdir")" || rc=1
1831:    if printf '%s' "$qcmd" | LC_ALL=C grep -qF "find $(printf '%q' "$qdir")"; then rc=1; fi
```

`:1809` and `:1828` fail in the safe direction (a 141 would be a false *red*). **`:1831` fails in
the unsafe direction.** It is an inverted assertion — "the old interpolated shape must NOT be
present" — so grep matching is the *failure* case, and a match is exactly when `grep -q` exits early
and can SIGPIPE `printf`. A 141 makes the `if` false, `rc` stays 0, and `st_case 0 0` reports the
assertion **passed** at the precise moment it should have failed. That is an assertion that can
silently not fire, which is this phase's dominant defect class.

**Fix:** use the file-based shape the same file already provides, or a here-string:

```bash
if LC_ALL=C grep -qF "find $(printf '%q' "$qdir")" <<<"$qcmd"; then rc=1; fi
```

### GC-07 — `RUN_TAG="$$"` does not provide the unpredictability its comment claims

**Severity:** WARNING
**File:** `scripts/phase06-oracle.sh:357-370`
**Confidence:** medium — the reasoning is sound; the residual risk is small because of the
dirty-destination precheck, which is why this is not higher.

The IN-06 comment states the threat as *"a pre-placed SYMLINK at a predictable name is followed by
the `>` redirections below"* and the mitigation as *"Suffixing with the run's PID removes the
predictability."* Three problems with that sentence:

1. **PIDs are not unpredictable.** They are small, sequential and exhaustively enumerable
   (`kernel.pid_max` is 32768 by default). Pre-creating one symlink per candidate name inside a
   world-writable `/tmp` is entirely feasible for the attacker the comment posits.
2. **`$$` is the wrong process.** It is the *macOS workstation's* bash PID. It has no relationship
   to anything inside the container whose `/tmp` is the world-writable directory in question, so it
   is a label, not a namespace — and PIDs recycle, so "per-run unique" is not guaranteed either.
3. **It adds little over the guard that already exists.** The step-1 probe refuses any non-empty
   `$SCRATCH`, which already catches a pre-placed symlink at *any* name. What `RUN_TAG` narrows is
   only the TOCTOU window between the step-1 probe and the step-5 `mkdir`.

None of this makes the shipped code wrong. The finding is that a comment in a destructive-path
instrument asserts a security property the code does not have, and the next reader will rely on it.

**Fix:** either downgrade the claim to what is true (*"a per-run suffix narrows the window between
the step-1 probe and the step-5 mkdir; the probe is what actually refuses a pre-placed name"*), or
make it true by having the container mint the name — `SCRATCH_LIB="$(… mktemp "$SCRATCH/lib.XXXXXX")"`
inside the same remote program that does the `mkdir -p`.

### GC-08 — the IN-06 fix was applied to one of two sibling instruments

**Severity:** WARNING
**File:** `scripts/phase06-incremental-control.sh:436`, `:442`, `:444`, `:446`, `:449`, `:474`, `:480`
**Confidence:** high.

The oracle uniquified its scratch filenames because *"the container's /tmp is world-writable and
these names used to be fixed … a pre-placed SYMLINK at a predictable name is followed by the `>`
redirections"*. The sibling instrument, which is in this same diff and runs in the **same
container** as the same user, still writes to fixed, predictable names with exactly those
redirections:

```sh
436: LC_ALL=C find "$SRC" -type f -printf '%p\t%s\t%T@\n' > /tmp/p6-man.meta
442: LC_ALL=C find "$SRC" -type f -print0 > /tmp/p6-man.z
444: LC_ALL=C sort -z < /tmp/p6-man.z > /tmp/p6-man.zs
474: printf '%s\n' "$PROG" > /tmp/p6-taghist.py
```

`/tmp/p6-taghist.py` is the worse one: it is written and then **executed** by `"$PY"` on the next
line. A symlink pre-placed at that name by anything else able to write the container's `/tmp`
redirects the write, and a regular file that the redirect cannot truncate leaves the *previous*
contents to be executed.

Either the IN-06 threat model is real, in which case it applies to both files, or it is not, in
which case the oracle's `RUN_TAG` comment overstates it (GC-07). The two findings are the same
question asked from opposite ends.

**Fix:** `T="$(mktemp /tmp/p6-man.XXXXXX)"` in the remote programs, or state in
`phase06-incremental-control.sh` why the same threat does not apply there.

---

## INFO

### GC-09 — the `EXIT_CODE != 0` tail was not extended when new fatal conditions were added

**Severity:** INFO
**File:** `scripts/quick-health-check.sh:2682-2687`

The tail message enumerates the blocks that can carry a ❌/⚠️, and the file restates **four times**
in the comment above it that the tail must be updated *"in the SAME COMMIT"* as any site that can
newly reach it, because *"a tail that lists every block except the failing one sends the reader to
the green ones"*. Plan 06-16 gave the D-04 block two new fatal conditions (K and L) and made the
D-03 CLI render's `exit 3` reachable; plan 06-17 added the consumers exit-3 arm. The tail was not
touched — and the **D-03 and D-04 blocks are not named in the list at all**, which predates this
phase but is now carrying two more fatal conditions than when it was written.

**Fix:** add "the D-03 vendored-config mount block, the D-04 throwaway-`-l` scan" to the list at
`:2683-2687`, and name the CONF-04-pending state so the reader knows a ⚠️ there is expected until E6.

### GC-10 — `beets.md`'s measured-counts table no longer matches the tree, and says it does

**Severity:** INFO
**File:** `stacks/selfhosted/arrs/beets.md:2238-2244`

Reproducing the D-04 block's pipeline against this repo's `HEAD`:

| count | `beets.md` says | measured now |
|---|---|---|
| raw | 191 | **199** |
| comment-stripped | 90 | **98** |
| invocation-shaped | 10 | 10 ✓ |
| executable / asserted / exempt | 8 / 3 / 5 | 8 / 3 / 5 ✓ |
| documentation | 2 | 2 ✓ |

The note claims *"hand-reproduced from the host and compared against the block's own printed
figures — agreement at every position, both trees"*, which is self-invalidating: the note's own body
quotes `D04_INV_RE` and `BEET[A-Z_]*`, which adds eight `BEET`-matching lines to the raw and
comment-stripped counts. No functional impact — neither count is pinned — but the file's stated
convention for self-referential counts (used correctly by the eleventh and twelfth exit-code
notices, which say *"headers 10 -> 11, raw 13 -> 14"*) was not applied here.

### GC-11 — `remote_sh_c` silently requires a bash-family shell at both remote hops

**Severity:** INFO
**File:** `scripts/phase06-oracle.sh:1293-1301`
**Confidence:** high on the mechanism (reproduced); the dependency is almost certainly satisfied.

`printf '%q'` renders any multi-line string as bash ANSI-C quoting (`$'…\n…'`). All four multi-line
remote programs — `SCRATCH_PROBE_PROG`, `PREFLIGHT_PROG`, `STAMP_WRITE_PROG`, `CLEANUP_PROG`,
`STAMP_RM_PROG` — therefore arrive at LXC 100 as `sh -c $'…' sh <path>`, which requires the **ssh
login shell** (and, for the `dex_cmd` paths, the shell that parses the `docker exec` line) to
understand `$'…'`. Confirmed locally:

```
transport = bash : rc=0, program runs
transport = dash : rc=2, "syntax error near unexpected token `)'"
```

This is **fail-closed** — a non-bash transport produces a loud syntax error and a non-zero `RSH_RC`,
not a mangled `rm`. `rsh()`'s own comment does say *"run by bash on LXC 100"* (`:1227`). But
`remote_sh_c`'s comment justifies `%q` on the grounds that *"the result lands in a bash WORD, which
is the one context `%q` is correct for"* — which is the argument for the **arguments** and is silent
about the **program text**, where `%q` is being used for a different reason and carries a different
dependency.

**Fix:** one sentence in `remote_sh_c`'s comment: *"the program text is `%q`-rendered too, which for
multi-line programs produces bash `$'…'`; this requires root's login shell on `$LXC_HOST` to be
bash — it is, and a non-bash shell fails loudly rather than quietly."*

### GC-12 — self-test bookkeeping: a dead counter reset and a misleading failure banner

**Severity:** INFO
**File:** `scripts/phase06-oracle.sh:2167`, `:2273-2276`

(a) `UNKNOWNS=0` at `:2167`, at the end of `self_test_vacuity`'s WR-06 section, is dead: the
self-test gate at `:2273` consults only `ST_FAIL` and `REDS`, never `UNKNOWNS`. Harmless, but it is
a counter written and never read, in the section whose subject is counters that are never read.

(b) That gate fires on `ST_FAIL != 0` **or** `REDS != 0`, but prints
`'%s of %s case(s) FAILED'` with `ST_FAIL`. A run that fails only because a stray `bad()` moved
`REDS` prints `0 of N case(s) FAILED` and exits 1 — a failure banner asserting nothing failed.

**Fix:** delete `:2167`; make the banner name which counter tripped, or fold `REDS` into `ST_FAIL`.

### GC-13 — `check-beets-config.sh` self-test case 6 can tick green while two things are wrong

**Severity:** INFO
**File:** `scripts/check-beets-config.sh:405-424` with `:679-688`

`assert_beet_invocation_contract` reports through a single counter, `ARM1_FAILS`, and case 6
compares that counter to the single expected total `1`:

- real source violation → `cfg_fail` → `ARM1_FAILS++`
- synthetic negative correctly rejected → `cfg_fail` → `ARM1_FAILS++`
- synthetic negative **not** rejected ("the checker is BLIND") → `echo` only, **no** increment

So "one real violation in the source" + "the checker is blind" sums to `ARM1_FAILS == 1 ==
expect_reds`, and the case reports `✅ case … 1 red, as expected`. Two faults cancel into a pass.
Contrived — it needs both at once — but the shape (two distinct outcomes funnelled into one
comparison) is the same one that produces vacuous assertions elsewhere in this phase.

**Fix:** count the two independently, e.g. a local `synth_rejected=0/1`, and require
`real == 0 && synth_rejected == 1` rather than comparing a sum.

### GC-14 — the `CONSUMERS_SCRIPT` override is invisible on the new exit-3 arm

**Severity:** INFO
**File:** `scripts/quick-health-check.sh:2238-2247` vs `:2252-2293`

`CONSUMERS_OVERRIDDEN` is consulted only inside the `CONSUMERS_RC -eq 0` arm. On the new exit-3 arm
an overridden run prints `⚠️ CONF-04 MEASURED AND OPEN — artist rows at baseline, not at target`
with no hint that the audit that answered was not the deployed one. The additive contract still
holds — the arm sets `EXIT_CODE=1` unconditionally, so no override can produce green — so this is a
**diagnosis** defect, not a verdict defect: the operator is told the estate is off target when what
was actually measured is an arbitrary file. That is precisely the shape of WR-10 and WR-03, which
this same wave fixed elsewhere.

**Fix:** echo the override line (or append "(overridden: ran `$CONSUMERS_SCRIPT`)") in the exit-3
arm and in the generic `else`.

### GC-15 — two overridable paths still reach the remote command string unquoted

**Severity:** INFO
**File:** `scripts/phase06-oracle.sh:2369` and `:2530`

```bash
rsh "$(dex_cmd sha256sum "$REAL_LIB_DB" "$REAL_STATE_PICKLE")"
```

`dex_cmd` renders its arguments with `"$*"` — no `printf '%q'`, no `remote_sh_c`. Both
`REAL_LIB_DB` and `REAL_STATE_PICKLE` are `${VAR:-default}` knobs (`:246-247`), so a value with a
space, a quote or a `$` word-splits or expands on the far side. These are the last two path
interpolations in the file that WR-08's stated rule — *"a path must NEVER be interpolated into the
TEXT of a remote command"* — does not cover, and the fix is the cheapest in the file since this is a
bash **word** context where `%q` is exactly right:

```bash
rsh "$(dex_cmd sha256sum "$(printf '%q' "$REAL_LIB_DB")" "$(printf '%q' "$REAL_STATE_PICKLE")")"
```

The blast radius is limited by the additive contract (a wrong value produces a refusal, not a pass)
and by both defaults being fixed container paths, which is why this is INFO and not a warning.

---

## Not findings, checked and cleared

Recorded so a later reader does not re-spend the time:

- `${NEWER_LIST[@]+"${NEWER_LIST[@]}"}` (`:2570`) is the correct bash-3.2-safe empty-array idiom
  under `set -u`; `NEWER_ARGS` (word context, `%q`) and `NEWER_LIST` (parameter context) really are
  two shapes for two contexts, as the comment claims.
- `[[ -z "$forb" ]] && continue` inside a `for` under `set -e` does not terminate the shell — the
  failing command is a non-final member of an `&&` list.
- `IFS=':' read -r -a forb_arr <<<"$EXTRA_FORBIDDEN_SUBSTRINGS"` (IN-07) does split on `:` and does
  not glob; the here-string supplies the trailing newline so `read` returns 0.
- `$(( (READY_ATTEMPTS - 1) * READY_SLEEP ))` (IN-03) matches the loop, which sleeps only between
  attempts.
- `beet_invocation_violations` really does keep itself out of its own haystack: every pattern is
  assembled from `local d='$'`, and `${d}{BEET_BIN}` contains no `${BEET_BIN}` substring.
- `classify_reoffer`'s widened `Skipped [0-9]+ paths\.` still reaches `indeterminate` on an empty or
  unrecognised transcript, and `arm_verdict`'s 2×2 precedence table is fully driven.
- `phase06-incremental-control.sh:652` interpolates `$root` into remote program text, which is the
  WR-08 shape — but `$root` is one of two literal constants (`/tmp/p6a`, `/tmp/p6b`), it is outside
  the gap-closure diff, and no user-supplied value reaches it.

---

_Reviewed: 2026-09-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Scope: gap-closure only (`7d1092b..HEAD`); does not supersede `06-REVIEW.md`_

---

## Cross-family adjudication — 2026-09-22

*Appended by the execute-phase orchestrator. **Nothing above this line was edited.** The operator
asked for a reviewer from a different model family, on the grounds that an Anthropic model wrote
both this code and the review above, and same-family reviewers share blind spots.*

**Reviewer availability, measured:** `codex` and `gemini` and `opencode` are installed;
`cursor-agent`, `qwen`, `coderabbit` are not, and the `gh copilot` extension is not installed.
**`codex exec` failed: "You have no credits remaining"** (OpenAI API billing) — so the intended
first-choice reviewer did not run. Adjudication below is **`gemini-3.1-pro-preview`**, a single
non-Anthropic reviewer rather than two. Note its output file must be size-checked, not
exit-code-checked: it exits 0 on an empty file.

**Scope limit that is this orchestrator's fault, not the reviewer's:** the prompt carried only
`git diff 7d1092b..HEAD -- scripts/`. `beets.md`, `beets.yaml` and full file bodies were absent,
which is why five findings came back UNVERIFIABLE. Those five are *not* disputed — they were
unreachable from the evidence supplied.

### Verdicts on GC-01..GC-15

| Verdict | Findings |
|---|---|
| CONFIRMED by the cross-family reviewer | GC-02, GC-05, GC-06, GC-07, GC-11, GC-12, GC-13, GC-14 |
| CONFIRMED independently by the orchestrator, with a local reproduction | GC-01, GC-03 |
| UNVERIFIABLE from the supplied diff (evidence not supplied — not disputed) | GC-04, GC-08, GC-09, GC-10, GC-15 |
| FALSE | *none* |

No finding was overturned.

> **CORRECTION 2026-09-22 — this paragraph was wrong when first written.** It originally read:
> *"GC-15 was separately confirmed by the orchestrator while checking GC-17 — the three sites are
> real, at `quick-health-check.sh:1515`, `:1728`, `:2196`."* **Those three sites are GC-17's, not
> GC-15's.** The orchestrator crossed the two findings' labels. Caught by the round-2 planner and
> re-verified by grep:
> - **GC-15** is `scripts/phase06-oracle.sh:2369` and `:2530` — two
>   `rsh "$(dex_cmd sha256sum "$REAL_LIB_DB" "$REAL_STATE_PICKLE")"` calls, where `dex_cmd`
>   renders with `"$*"` and neither knob is quoted. Confirmed present at both lines.
> - **GC-17** is `scripts/quick-health-check.sh:1515`, `:1728`, `:2196` (plus a **fourth site the
>   review missed**, `DRIFT_CMD="set -o pipefail; cd $DRIFT_REPO_ROOT …"`, found by the planner).
>
> Both findings are real, in different files. Kept visible rather than silently repaired, because
> an executor following the crossed citation would have "fixed" the wrong file and reported
> success.

### Two findings the first review missed

**GC-16 — the D-04 variable-expansion branch does not anchor on shell separators or `docker`.**
`scripts/quick-health-check.sh:1765`. The fourth branch of `D04_INV_RE` anchors only on content
start (`^HEAD:…`) or immediately inside an opening quote (`"`). The three *literal* `beet`
branches in the same regex also anchor on `[[:space:]](&&|;)[[:space:]]*` and on
`docker[[:space:]][^`]*[[:space:]]`. So `&& $BEET_BIN config` or
`docker exec -u beetle … $BEET_BIN config` is invocation-shaped and **invisible to the scan**.
This is a latent blind spot in the very detector CR-01 was raised against, one branch across.

*Orchestrator correction, recorded so the plan does not inherit a wrong premise:* the reviewer
graded this **BLOCKER** and justified it by claiming the block comment promises separator
anchoring. **That justification is FALSE** — the comment at `:1762-1764` says "content start, or
immediately inside an opening quote", which is exactly what the code does. There is no
documentation mismatch. The *substantive* gap is real and worth fixing, but it is a latent
blind spot with no current instance in the tree (executable count 8, all found), so it is graded
**WARNING**, not BLOCKER. Verified by reading the regex and the comment.

**GC-17 — three overridable paths reach remote command strings unquoted.**
`scripts/quick-health-check.sh:1515` (`cd $D03_REPO_ROOT`), `:1728` (`D04_CMD="cd $D04_REPO_ROOT`)
and `:2196` (`bash $CONSUMERS_SCRIPT`). An override containing a space word-splits on the remote
shell, so the branch the override exists to drive fails with a shell error instead of being
driven. Severity **WARNING**: all three are additive knobs that cannot produce a green tick, and
the default values contain no spaces. This is `phase06-oracle.sh`'s WR-08 defect, reproduced in
the sibling file that WR-08's plan did not own.

*Orchestrator correction:* the reviewer cited `:1515`, `:1720`, `:2193`. Two of those are an
`echo` and an assignment — its line numbers drifted because it numbered the diff, not the file.
Corrected citations above are grep-verified. The finding itself stands at all three sites.

### Standing note for the next planner

The cross-family reviewer's **claims were sound and its line numbers were not**. Both of its new
findings needed citation repair before they could be used, and one carried a false justification
attached to a true defect. Grep-verify every citation before planning against it — the same rule
that four consecutive plans in this phase already had to learn about stale citations.

_Adjudicated: 2026-09-22. Reviewer: `gemini-3.1-pro-preview`. Codex unavailable (no credits)._
