---
phase: 05-inbox-structure-and-the-junk-gate
reviewed: 2026-09-19T21:32:01Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - scripts/phase05-junk-sweep.sh
  - scripts/phase05-now-split.sh
  - scripts/phase05-now-tag-inventory.sh
  - scripts/phase05-downloads-chown.sh
  - scripts/normalise-dj-tags.py
  - scripts/quick-health-check.sh
findings:
  critical: 2
  warning: 12
  info: 0
  total: 14
critical_fixed: 2
critical_open: 0
warnings_fixed: 0
warnings_open: 12
fixed_at: 2026-09-19T23:05:00Z
fix_commits:
  - hash: fe65845
    finding: CR-01
    files:
      - scripts/phase05-junk-sweep.sh
      - scripts/phase05-now-split.sh
      - scripts/normalise-dj-tags.py
  - hash: fc10dc7
    finding: CR-02
    files:
      - scripts/phase05-downloads-chown.sh
status: blockers_fixed_warnings_open
---

# Phase 5: Code Review Report

**Reviewed:** 2026-09-19T21:32:01Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** blockers_fixed_warnings_open — both BLOCKERs fixed and driven; all 12 WARNINGs still open

## Fix status, 2026-09-19

Only the two BLOCKERs were approved for fixing. **The twelve WARNINGs below are UNTOUCHED and
remain OPEN** — no code named in WR-01 … WR-12 was changed, deliberately, so the blocker diff
stays reviewable.

| Finding | Status | Commit | Driven in both directions |
|---|---|---|---|
| CR-01 | **FIXED** | `fe65845` | Yes — refuses a superset-only proof, still accepts the exact line |
| CR-02 | **FIXED** | `fc10dc7` | Yes — refuses a diff that never ran, still passes zero-lines and still catches a breach |
| WR-01 … WR-12 | **OPEN** | — | — |

Neither fix touched the estate: no ZFS snapshot was created, destroyed or read, and no tool was
run in apply/sweep mode against a real path. Both were driven against local fixtures, with the
CR-02 block **extracted from the shipping file** (and from `HEAD~1` for the before-column) rather
than retyped. `bash -n` and `python3 -m py_compile` are clean on all four changed files, with the
exit status read directly rather than through a pipe. The full evidence tables are in the two
commit bodies.

`scripts/phase05-downloads-chown.sh:925` — the one site that was already correct — was left alone.

## Summary

Six files, four of them new and three of those destructive against a live estate with no undo but
a ZFS snapshot. The gate design (enumerate → operator approves a file → act from that file) is
implemented consistently and the per-row scope fences are real. Most of the twelve named estate
defect classes are demonstrably handled, several with the fix commented in place.

Two findings are BLOCKERs, and both are guards that **fail open**:

1. The snapshot-proof fence — the check that stands in front of every destructive act in this
   phase — is a **substring** match in three of the four places it appears. Only
   `phase05-downloads-chown.sh` was repaired to `grep -qxF`. The other three still accept a proof
   that names `tank/downloads@pre-phase5-chown`, a snapshot **this phase created on 2026-09-19 and
   did not destroy**, as proof that `tank/downloads@pre-phase5` exists. `now-split.sh`'s header
   even argues the substring form is correct ("the substring check gives that for free"). This is
   the exact class the prompt asked to confirm was fixed everywhere; it was fixed in one place.

2. The library untouched-proof in the chown tool — the single instrument that would report a D-20
   breach — is `zfs diff … | wc -l` run over ssh **without `set -o pipefail` inside the remote
   string**, with the ssh status discarded by a local pipe, and with `zfs diff`'s stderr sent to
   `/dev/null`. A `zfs diff` that cannot run prints nothing, `wc -l` prints `0`, and the block
   reports `library untouched-proof: 0 lines - the scope guard held`. Defect class 1 verbatim,
   landing on the most important assertion in the file.

Everything below is stated for **the next run, or for whoever reuses these scripts** — the phase's
own runs are complete and verified by other instruments.

## Critical Issues

### CR-01: The snapshot-proof fence is a substring match in three of four places, and the superset it now admits exists on the pool

**Status: FIXED in `fe65845` (2026-09-19).** All three sites now match whole lines — `grep -qxF --`
in the two shell scripts, membership in the set of stripped lines in the Python. The
"the substring check gives that for free" comment at `phase05-now-split.sh:149-151` was replaced in
the same commit with the real reasoning, and that reasoning was added at both other sites.
Driven in both directions: a proof containing only `tank/downloads@pre-phase5-chown` was ACCEPTED
by all three pre-fix (now-split printed the literal line `OK: rollback proven:
tank/downloads@pre-phase5`) and is REFUSED with exit 2 by all three post-fix, while a proof
containing the exact line `tank/downloads@pre-phase5` is still accepted by all three.

**File:** `scripts/phase05-junk-sweep.sh:772`, `scripts/phase05-now-split.sh:965`,
`scripts/normalise-dj-tags.py:1141`
**Issue:**
All three check membership by substring:

```bash
# phase05-junk-sweep.sh:772
if ! grep -qF "$SNAPSHOT_NAME" "$SNAPSHOT_PROOF"; then
# phase05-now-split.sh:965
if ! grep -qF -- "$SNAPSHOT_NAME" "$SNAPSHOT_PROOF"; then
```
```python
# normalise-dj-tags.py:1141
if snapshot_name not in body:
```

`SNAPSHOT_NAME` / `NOW_SNAPSHOT_NAME` is `tank/downloads@pre-phase5`.
`phase05-downloads-chown.sh:246` defines `SNAPTAG="pre-phase5-chown"` and line 1016 **creates**
`tank/downloads@pre-phase5-chown`, which contains `tank/downloads@pre-phase5` as a prefix. That
snapshot now exists on the pool and nothing destroys it. A proof file produced by any recursive
form — `zfs list -t snapshot -H -o name -r tank/downloads` is the obvious variant of the command
the error messages print — therefore satisfies all three checks **even after `@pre-phase5` has
been destroyed**. The tools would then run their 4,750 renames, their `rm -rf` and their 751
in-place tag writes with no rollback at all, reporting `rollback proven: tank/downloads@pre-phase5`.

`phase05-downloads-chown.sh:920-924` states this defect and its fix in full, and is the only file
that applies it. `phase05-now-split.sh:149-151` states the opposite: *"a proof naming the wrong
snapshot MUST fail; the substring check gives that for free."* That comment is false and will
defend the bug against the next reader.

This is the estate's recorded `requireBeetsMatch` / `FLAC` vs `FLACX` class, and the prompt records
it having already bitten once in this phase.

**Fix:**
```bash
# phase05-junk-sweep.sh:772 and phase05-now-split.sh:965 — whole-line, fixed-string
if ! grep -qxF -- "$SNAPSHOT_NAME" "$SNAPSHOT_PROOF"; then
```
```python
# normalise-dj-tags.py:1141 — compare whole lines, not the file body
if snapshot_name not in [ln.strip() for ln in body.splitlines()]:
```
and delete the "the substring check gives that for free" sentence at `phase05-now-split.sh:150-151`
in the same commit, replacing it with the reasoning already written at
`phase05-downloads-chown.sh:920-924`.

### CR-02: The library untouched-proof cannot distinguish "zero diff lines" from "the diff never ran"

**Status: FIXED in `fc10dc7` (2026-09-19).** Three verdicts, never two. `set -o pipefail` now sits
inside the remote string, stderr is captured and reported instead of discarded, the status is taken
with no local pipe in front of it (`… && lib_rc=0 || lib_rc=$?`, because the file runs under
`set -e`), and any non-zero status or non-numeric answer is a REFUSAL. The written record line says
`UNKNOWN - the diff did not run` rather than printing a count nobody took. Driven with the block
extracted from the shipping file: a `zfs diff` that exits 1 without running produced
*"OK: library untouched-proof: 0 lines - the scope guard held and Phase 1's D-20 is intact"*
pre-fix and now produces a FAIL naming the captured stderr; over real ssh to an unreachable
`ZFS_HOST=192.0.2.1` it now reports `UNKNOWN … (exit 255)` instead of accusing the run of a breach
with an empty count. The zero-lines pass and the three-line breach both still behave correctly.

**File:** `scripts/phase05-downloads-chown.sh:1133`
**Issue:**

```bash
libcount="$(zfs_exec "zfs diff -H '$LIB_SNAPSHOT' tank/media/Music 2>/dev/null | wc -l" | tr -dc '0-9')"
if [ "${libcount:-1}" = "0" ]; then
  pass "library untouched-proof: 0 lines - the scope guard held and Phase 1's D-20 is intact"
```

Three separate ways this reads green when nothing was measured:

* the remote string contains a pipe and carries **no `set -o pipefail`**, so a failed or killed
  `zfs diff` leaves `wc -l` printing `0` and exiting `0` (defect class 1, and the file's own header
  at line 191-193 claims the remote-payload discipline that this line does not follow);
* `2>/dev/null` discards the reason — `zfs diff` fails routinely on an unmounted dataset, a
  destroyed snapshot, or while another `zfs diff` holds the dataset;
* the ssh exit status is consumed by the local `| tr -dc '0-9'`, so even a `255` (atlantis
  unreachable) yields `libcount=0`.

`${libcount:-1}` only defends against an *empty* result; `wc -l` never returns empty. The false
green is reported as *"the scope guard held and Phase 1's D-20 is intact"* — the strongest
statement in the file, on the weakest instrument in it. Every other remote read in this phase
(`quick-health-check.sh:1618-1620`) gets this right, which is what makes it a defect rather than a
house style.

**Fix:**
```bash
libcount_raw="$(zfs_exec "set -o pipefail; zfs diff -H '$LIB_SNAPSHOT' tank/media/Music | wc -l")"
lib_rc=$?          # no local pipe in front of this line
libcount="$(printf '%s' "$libcount_raw" | tr -dc '0-9')"
if [ "$lib_rc" -ne 0 ] || ! printf '%s' "$libcount" | grep -qE '^[0-9]+$'; then
  fail "library untouched-proof UNKNOWN (rc $lib_rc, output '$libcount_raw'). NOTHING WAS COUNTED."
  fail "This is NOT 'the chown stayed out of the library'."
elif [ "$libcount" = "0" ]; then
  pass "library untouched-proof: 0 lines"
else
  fail "library untouched-proof: $libcount line(s). THE CHOWN REACHED $LIBRARY."
fi
```
Three verdicts, never two — the same shape this phase already wrote at
`quick-health-check.sh:1621-1637`.

## Warnings

**ALL TWELVE ARE OPEN.** None was approved for fixing and none was touched by `fe65845` or
`fc10dc7`. Every line reference below is still live against the current tree.

### WR-01: The detached runner's "third state" check can never fire, and fires falsely on an ssh blip

**File:** `scripts/phase05-downloads-chown.sh:1068`
**Issue:** `if ! zfs_exec "pgrep -f 'phase05-chown/runner.sh' >/dev/null" 2>/dev/null; then` is
supposed to detect "the runner died without writing a sentinel". Over ssh, `zfs_exec` runs
`ssh host "pgrep -f 'phase05-chown/runner.sh' >/dev/null"`, so sshd spawns a shell whose own
command line **contains the pattern**. `pgrep -f` excludes only itself, not its parent, so it
matches that shell and returns 0 on every poll whether or not a runner exists. The header at
lines 108-114 sells this as the instrument that keeps the third state distinct from a pass; it
cannot distinguish anything. Conversely, a transient ssh failure makes the negation true and the
caller abandons a *live* four-hour chown with "the runner is gone. State is UNKNOWN". The pattern
is also hardcoded while `RUNNER_DIR` (line 258) is overridable, so any override breaks it a second
way.
**Fix:** signal on the sentinel and a PID file rather than on a command-line grep:
have the runner write `$RUNNER_DIR/runner.pid` at start, and poll
`zfs_exec "kill -0 \$(cat '$RUNNER_DIR/runner.pid')"`; treat a non-zero *ssh* status (255)
separately from a non-zero *probe* status so a network blip is a retry rather than a verdict.

### WR-02: `apply`'s stated exit-0 contract includes a diff assertion that is never made

**File:** `scripts/phase05-downloads-chown.sh:159-161, 1120-1128`
**Issue:** The exit-code convention says `apply 0` means, among other things, *"the download-tree
diff shows only M lines"*. The code captures `diffcounts` with `|| true`, prints it, prints up to
200 non-M lines, and asserts nothing. A run that renamed or deleted content under the approved
roots between the fresh baseline and the census prints `R 12` / `- 3` and still exits 0. The header
at line 176 promises *"any non-M line is named individually"*, which it is — but naming is not
asserting, and `README § Health Checks` requires the assertion.
**Fix:** derive the non-M total from `diffcounts` and `fail` on it, e.g.
`nonm="$(printf '%s\n' "$diffcounts" | awk '$1!="M"{s+=$2} END{print s+0}')"`, then
`[ "$nonm" = "0" ] || fail "…"`; and make an empty `diffcounts` its own UNKNOWN verdict rather
than an implicit pass (same `|| true` problem as CR-02).

### WR-03: The literal scope guard fences three constants and not the one that chooses the machine

**File:** `scripts/phase05-downloads-chown.sh:243, 258, 298-315`
**Issue:** `assert_scope_literal()` refuses unless `DOWNLOADS`, `LIBRARY` and `UIDGID` equal their
ALL-CAPS literals, because "a wrong constant here is a hypervisor-wide recursive chown". But
`ZFS_HOST="${ZFS_HOST:-172.16.1.158}"` — the host that receives that recursive chown as **real
root** — is environment-overridable and is not asserted anywhere; nor is `RUNNER_DIR`. The far-side
re-assertion (line 806) only re-checks the *path*, so pointing the tool at any other host that has
a `/mnt/tank/downloads` directory passes all three refusals. `quick-health-check.sh:1607-1615`
already establishes the convention this needs (an override is permitted but forces a non-green run).
**Fix:** add `ZFS_HOST` and `RUNNER_DIR` to `assert_scope_literal()` — either refuse a non-default
value outright, or accept it and set a flag that forbids a `pass` verdict for the run.

### WR-04: `remote_bash` passes its arguments unquoted through ssh

**File:** `scripts/phase05-downloads-chown.sh:399-405`
**Issue:** `ssh … 'bash -s --' "$@"` hands the arguments to the **remote** shell for a second round
of word splitting. The header (lines 191-193) presents the stdin-payload design as the thing that
makes quoting safe, and lines 1044-1048 show the authors know the hazard — `EXCLUDED_ROOTS`
contains `/mnt/tank/downloads/google takeout` and is explicitly single-quoted for the launch path.
`remote_bash` gets no such treatment. Today `SURVEY_ROOTS` and `RUNNER_DIR` contain no spaces, so
nothing breaks; add one survey root with a space, or override `RUNNER_DIR`, and the payload's
`$1..$5` silently shift — `ROOT` becomes a fragment, the `case "$r" in "$ROOT"/*)` fence at
lines 450-453 compares against the wrong prefix, and the survey walks or refuses the wrong tree.
**Fix:** quote each argument into the remote command:
`ssh … "bash -s -- $(printf "%q " "$@")"`, or pass the values as a NUL-delimited here-doc prologue
consumed by the payload rather than as positional parameters.

### WR-05: Both gates *warn* about a malformed gate file and still exit 0 calling it success

**File:** `scripts/phase05-junk-sweep.sh:696-711`, `scripts/phase05-downloads-chown.sh:726-737`
**Issue:** Both headers state that `enumerate` *"ASSERTS the shape of the file it just wrote … before
it reports success"*. Neither does. Both compute `shape_bad` and, when it is non-zero, call `warn`
— leaving the malformed file in place, printing the earlier `pass "wrote N row(s)"`, and exiting 0.
The file that is the gate is then on disk, looking approved-ready, with the only objection three
screens up in yellow. The same applies to the coverage check at `phase05-downloads-chown.sh:763-768`
and to `written != n_rows` at 722-724.
**Fix:** on a non-zero `shape_bad`, remove the file and `exit 2` — exactly the treatment the
out-of-scope row already gets at `phase05-downloads-chown.sh:748-752` ("a violation here is a DEFECT
rather than a finding, so it is fatal and the list is removed"). The shape violation is the same
class of defect and deserves the same handling.

### WR-06: A move-only row whose destination already exists is nested inside it and reported as moved

**File:** `scripts/phase05-junk-sweep.sh:876-899`
**Issue:**
```bash
"_inbox/02-review") target="$REVIEW/$(basename -- "$real")" ;;
"99-quarantine")    target="$QUARANTINE/$(basename -- "$real")" ;;
…
if mv -- "$real" "$target" 2>/dev/null; then
  if [ -e "$target" ] && [ ! -e "$real" ]; then pass "moved $real -> $target"
```
`mv src dst` where `dst` is an existing **directory** moves `src` *inside* it, producing
`02-review/Madonna/Madonna`. The post-move check then passes — `$target` exists, `$real` does not —
and the row is reported as a clean move. Two R8 rows with the same basename (the D-20 `lidarr-import`
triage is exactly two artist folders, and `dj-mixes/` and `unsorted/` are known to share 85 folder
names) nest the second inside the first. Nothing later in the phase looks at `02-review`, so this
would surface as missing content in Phase 6.
**Fix:** refuse a colliding destination before moving, and use `mv -n`/`mv -T`:
```bash
if [ -e "$target" ]; then
  fail "$rrule destination already exists, left in place: $target"; move_errors=$((move_errors+1)); continue
fi
mv -n -T -- "$real" "$target"
```
(`-T` makes "move into the existing directory" impossible rather than merely unlikely.)

### WR-07: `path_bytes` returns 0 for "could not measure", and R7 deletes on size 0

**File:** `scripts/phase05-junk-sweep.sh:399-409, 518-522`
**Issue:** `path_bytes()` returns the literal `0` whenever `du`/`stat` fails, and `file_rule()`
proposes removal when `[ "$sz" = "0" ]` with the reason `zero-byte regular file`. A file that could
not be stat'd is therefore offered to the operator for deletion under a reason that asserts a
measurement nobody took. The same conflation feeds the `bytes` column of every row and the
per-rule byte totals printed at lines 729-735. `count_matching()` and `count_entries()` (376-397)
get this right — they return the literal `UNKNOWN`, and the header at 376-378 says why — so the
discipline exists in the file and is not applied to size.
**Fix:** have `path_bytes` return `UNKNOWN` on failure; make `file_rule` fire R7 only on a numeric
`0`; and print `UNKNOWN` in the bytes column rather than a zero that sums silently into the totals.

### WR-08: The TSV safety check rejects tabs but not newlines

**File:** `scripts/phase05-junk-sweep.sh:336-345`
**Issue:** `tsv_safe()` excludes a path whose name contains a tab, on the stated grounds that it
"would corrupt the TSV that IS the gate" — but a newline in a name corrupts it identically and
more destructively, splitting one row into two partial lines. The shape assertion would then
count them as malformed and (per WR-05) only warn. `phase05-downloads-chown.sh:187-190` names
**both** characters and its payload excludes both, so the two gates disagree about what is
unparseable.
**Fix:**
```bash
case "$1" in
  *$'\t'*|*$'\n'*) TSV_UNSAFE=$((TSV_UNSAFE + 1)); return 1 ;;
esac
```

### WR-09: `mv -n` succeeds silently on a collision, and the only thing that catches it blames the wrong cause

**File:** `scripts/phase05-now-split.sh:1041-1051`
**Issue:** `mv -n` exits 0 when it declines to overwrite. The row is then judged by
`inode_before != inode_after` — where `inode_after` is the **pre-existing** file's inode — so the
run fails with *"inode changed across the move … someone made a dataset boundary appear where D-18
says one must never be"*. The real cause is a destination collision, and the source is still sitting
in the collection root. The pre-validation at line 1007 checks `-e "$dst"`, but the whole point of
re-validating is that the tree is live at ~1 job/72 s, so the window is real.
**Fix:** distinguish the two after a failed inode comparison:
```bash
if [ -z "$inode_before" ] || [ "$inode_before" != "$inode_after" ]; then
  if [ -e "$src" ]; then
    fail "destination already existed and mv -n declined; source left in place: $src -> $dst"
  else
    fail "inode changed across the move ($inode_before -> $inode_after) — a dataset boundary appeared (D-18): $dst"
  fi
```

### WR-10: The inventory's fence admits the whole `unsorted/` backlog, and its output file is append-only

**File:** `scripts/phase05-now-tag-inventory.sh:107, 164, 348`
**Issue:** `REQUIRED_ROOT` is `/mnt/tank/downloads/complete/nzb/unsorted` — the **parent** — and the
fence accepts `NOW_ROOT` equal to it *or any descendant* (line 164). Every other tool in the phase
fences the exact collection folder (`phase05-now-split.sh:249` requires equality;
`normalise-dj-tags.py:267-271` uses the folder itself). So `NOW_ROOT=/…/unsorted` passes, as does
any one of the 120 other backlog folders. Combined with line 348 — `now-tags.ndjson` is **appended**
on every scan and never truncated, with the done-ledger keyed on absolute path — a single mis-rooted
run permanently merges foreign records into the inventory that `phase05-now-split.sh plan` builds a
4,751-row rename map from. `plan`'s bucket equation still balances (foreign paths become
`fence-refusal` rows), so nothing reports it.
**Fix:** set `REQUIRED_ROOT` to the collection folder and require exact equality, matching the other
two tools; and have `scan` refuse to append to an existing `$NDJSON` whose first record's path is
not under the current `NOW_ROOT`.

### WR-11: `scan` is `-maxdepth 1` and now measures the split collection as empty, exiting 0

**File:** `scripts/phase05-now-tag-inventory.sh:291-301, 377-383`
**Issue:** The scan enumerates `find "$NOW_ROOT" -maxdepth 1 -type f -iname '*.mp3'`. Plan 05-07
moved all 4,746 mp3 into `Vol NNN/` at depth 2. A re-run today finds zero files, prints
`mp3 files: 0 (2026-09-18 value: 4746)` and `subdirectories: 115 (2026-09-18 value: 0)` as
informational lines, processes nothing, and reports `✅ scan complete, failed ledger empty` with
exit 0. `reconcile` then silently reuses whatever is still in the append-only NDJSON. The annotated
expectations are printed but never asserted — "assert rather than report", the third rule in
`README § Health Checks`.
**Fix:** assert the measurement rather than annotating it — `fail` when `subdir_count` is non-zero
while `-maxdepth 1` is in force, or drop `-maxdepth 1` and key the fence on the collection root; and
make `files_seen == 0` a failure, not a pass.

### WR-12: The hard-KEEP sidecar assertion is vacuous after the split it runs beside

**File:** `scripts/phase05-junk-sweep.sh:499-504, 641-644, 658`
**Issue:** Both the hard-KEEP test and the R6 test require `dirname "$path" == "$NOW_FOLDER"`. After
05-07, `back.bmp`, `cd1.bmp`, `cd2.bmp` live in `Vol 077/` and the cue in `Vol 115/`, so the KEEP
branch can no longer fire and `kept_hits` prints `0   (target 5)` with nothing raised. The four files
are not currently at risk (no file rule matches a non-empty `.bmp`/`.cue`), but the line that exists
to prove they were protected now proves nothing, and the printed target is unreachable.
**Fix:** match the KEEP basenames anywhere under `$NOW_FOLDER` (`case "$f_real" in "$NOW_FOLDER"/*)`)
rather than only at its root, and either assert `kept_hits == 5` or delete the target from the
message.

---

## Verified clean — the twelve named defect classes, checked specifically

| # | Class | Verdict |
|---|---|---|
| 1 | `timeout N cmd \| wc -l` exits 0 | Handled in `quick-health-check.sh:1618-1620` (pipefail **inside** the remote string, `$?` on the very next line, no local pipe) and in the local `count_matching`/`count_entries` helpers, which return `UNKNOWN`. **Was NOT handled at `phase05-downloads-chown.sh:1133` — CR-02, fixed in `fc10dc7`; that line now carries pipefail inside the remote string and reads the status with no local pipe.** |
| 2 | Prefix/substring match where a whole value is meant | `phase05-downloads-chown.sh:925` uses `grep -qxF` and documents why. **Three other sites used substring — CR-01, fixed in `fe65845`; all four now match whole lines.** |
| 3 | `$(grep -c … \|\| echo 0)` emitting `0\n0` | Not present. `phase05-now-split.sh:697-698` uses `|| true`, which is correct. |
| 4 | `awk 'printf …, (ternary) > FILE'` parsing as a comparison | Handled and commented at `phase05-now-tag-inventory.sh:542-544`; every other redirecting `printf` is parenthesised (`now-split.sh:441, 655, 662, 801`). |
| 5 | awk array keys comparing as strings | Handled with explicit `+ 0` coercion and a driven note at `phase05-now-split.sh:437-441`; `phase05-downloads-chown.sh:523` uses `+ 0` on both sides. |
| 6 | Tab is IFS whitespace, empty fields vanish | Handled by contract: every row carries a non-empty value in every column, `awk -F'\t'` is used in preference to `read`, and the shape is checked (advisory only — WR-05). |
| 7 | Tab separators lost through ssh quoting | Handled: remote payloads are fed to `bash -s` on **stdin** (`phase05-downloads-chown.sh:396-405`). The *arguments* are not quoted — WR-04. |
| 8 | `\| head -1` returning 141 after a loop | `phase05-junk-sweep.sh:628` has the shape but sits in argument position, where bash does not propagate the substitution's status; harmless today. |
| 9 | `\| tail -N` masking a Python SyntaxError | Not present in this change set. |
| 10 | `zfs diff` collapsing rename+modify into `R` | Handled explicitly: `phase05-downloads-chown.sh:129-140, 991-1020` takes a **fresh** baseline immediately before the chown and refuses to reuse an existing one. |
| 11 | A fence placed after route/connectivity detection | Handled and documented: the row-scope refusal sits **before** `detect_zfs_route` (`phase05-downloads-chown.sh:933-946`), with the note that the earlier placement made every negative control exit on "no zfs route" instead. |
| 12 | `.rar` is a name, not a type | Handled: `has_rar_shape` is reached only through a `-type f` walk, with both live counter-examples (`…part001.rar` directory holding FLAC, `…-1080p.R75` TV directories) named at `phase05-junk-sweep.sh:411-430`. |

Also checked and clean: no credential, token or API key reaches any of the six files (the only
secret-shaped finding in the phase, the `takeout-import.service` Immich key, is correctly recorded
in `deferred-items.md` §4 *by name only*); no `eval` reaches measured data (`zfs_exec`'s `eval` at
`phase05-downloads-chown.sh:388` only ever receives script-constructed strings); every `rm`/`mv`/
`chown` argument is quoted and `--`-guarded; the only removal call in `phase05-junk-sweep.sh`
(line 920) can reach nothing outside the timestamped quarantine batch it created; and
`normalise-dj-tags.py`'s per-file fence (`assert_inside_scratch`, lines 563-620) still refuses
symlinks, non-regular files and `st_nlink != 1` under the new `now` collection, with
`COLLECTIONS`/`COLLECTION_ROOTS` adding a *narrower* second root rather than widening `SCRATCH_ROOT`.

---

_Reviewed: 2026-09-19T21:32:01Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
_BLOCKERs fixed: 2026-09-19, commits `fe65845` (CR-01) and `fc10dc7` (CR-02), by Claude (gsd-code-fixer). The 12 WARNINGs remain OPEN._
