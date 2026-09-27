---
phase: 07-pilot-12-albums-end-to-end
reviewed: 2026-09-27T12:00:00Z
depth: standard
diff_base: 114586e
id_namespace: CR7 / WR7 / IN7 (checked unused before writing: /usr/bin/grep -rlE '\bCR7-[0-9]' scripts stacks .planning -> 0 files, the same for WR7 and IN7; CONVENTIONS §13)
files_reviewed: 11
files_reviewed_list:
  - scripts/check-beets-config.sh
  - scripts/check-music-consumers.sh
  - scripts/check-music-freeze.sh
  - scripts/check-music-import.sh
  - scripts/diff-music-tags.sh
  - scripts/quick-health-check.sh
  - scripts/route-dj-album.sh
  - stacks/selfhosted/arrs/beets/beets.yaml
  - stacks/selfhosted/arrs/beets/config.yaml
  - stacks/selfhosted/arrs/beets/flask-config.yaml
  - stacks/selfhosted/arrs/beets/flask.yaml
findings:
  critical: 1
  warning: 7
  info: 4
  total: 12
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-09-27
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

I reviewed the phase-07 diff (`git diff 114586e..HEAD`) of the eleven files, judged against CONVENTIONS.md's
14 rules. Both self-tests were run on the workstation. `diff-music-tags.sh --self-test` passed 5/5 and
`check-music-import.sh --self-test` passed 13/13, with the uncounted dumper check also green. I also ran
the jq album-mapping predicate from section 4d against a three-album control, and it matched only the
right album.

The instruments are mostly sound. Their fail-closed ladders are in S1 order, UNKNOWN is kept apart from
findings, and credentials stay out of argv. The main problem is the D-22 grant itself. The config comments
say that de-registering `01-auto` means no unattended importer can reach the now-`rw` library. That is not
true: `03-asis` is still registered with `autotag: bootleg`, which is also an unattended importer. The
grant also opens all of `/mnt/tank/media`, not just the Music dataset that the snapshot fence covers.

Among the scripts, the most serious problem is in `route-dj-album.sh`. Its "bounded" writing steps kill
only the docker client, so the beets write keeps running inside the container after the script reports a
failure. `quick-health-check.sh` also has two runtime-text problems: it tells the operator an RW=false red
is "expected", and it mislabels the D-24 census exit 3 as CONF-04.

I did not re-report the known deferrals (DEF-07-13-01, DEF-07-10-03, DEF-07-15-01's 4e message and limit,
DEF-07-12-09, DEF-07-11-06).

## Critical Issues

### CR7-01: `03-asis` (`autotag: bootleg`) is a second unattended importer into the now-rw library, and the in-band control claim says there is none

**File:** `stacks/selfhosted/arrs/beets/flask-config.yaml:111-114`, `stacks/selfhosted/arrs/beets/config.yaml:347-353`, `stacks/selfhosted/arrs/beets/flask.yaml:184`

**Issue:** D-22 makes `/mnt/tank/media` `:rw` on beets-flask, and `import.write: yes` stays on. The only
thing config.yaml names as bounding that combination is this:

> "01-auto is de-registered in ./flask-config.yaml in the same commit, so no unattended importer reads
> this key any more; every import that does is confirmed per album in 02-review (D-20)."

That statement is false. `03-asis` stays registered with `autotag: bootleg`, which is also an
unattended importer. Its own comment says it "imports as-is using the files' own metadata" with no
confirmation step. So any folder that lands in `/downloads/complete/nzb/_inbox/03-asis` is imported into
`/media/Music` with tags written, without going through D-20's per-album confirmation. That could be a
mis-sorted staging move, or a future SABnzbd category change.

The argument that removed `01-auto` applies word for word to `03-asis`: *"'Nobody has put a file there'
is not a control; de-registration makes the hazard a STRUCTURAL ABSENCE."* The phase also decided
`03-asis` stays unused (D-26, 07-SAMPLE.md, 07-13). Nothing asserts it stays empty either: the only
recount was 07-09's one-off at deploy time, and `/usr/bin/grep -rn 03-asis scripts/*.sh` finds only
phase05-junk-sweep and a comment.

Bootleg is also the one mode that CLAUDE.md and the inbox's own comment say must never run before tag
normalisation. So the only unattended write path left open is the one whose input is known to be bad.

**Fix:** Close it structurally for the rest of Phase 7, the same way 01-auto was closed. Either
de-register `03-asis` or register it with `autotag: preview` / `off`:

```yaml
      # 03-asis NOT REGISTERED for Phase 7 (D-26: unused; bootleg is unattended and D-22 made /media rw).
      # Re-registered in Phase 8 with the inflow design, when bucket C normalisation exists.
      "03-asis":
        name: "03-asis"
        path: /downloads/complete/nzb/_inbox/03-asis
        autotag: "off"
```

Then correct config.yaml:350-353 so it names what actually bounds `write: yes`. Also add a standing
assertion that the watchdog registration lists no auto/bootleg inbox; see WR7-05.

## Warnings

### WR7-01: The rw grant covers all of `/mnt/tank/media` (TV, Movies), but the D-16 snapshot fence covers only `tank/media/Music`

**File:** `stacks/selfhosted/arrs/beets/flask.yaml:184`; mirrored as literals in `scripts/check-music-freeze.sh` (`PHASE7_RW_TAGGER_SRC` / `_DST`) and `scripts/quick-health-check.sh:1874`

**Issue:** The grant mounts `/mnt/tank/media:/media:rw`. beets' `directory` is `/media/Music`, and the
fence the grant's own comment names as "the primary control from here" is
`tank/media/Music@pre-07-pilot` plus `fast/appdata/arrs@pre-07-pilot`. `/mnt/tank/media/TV` (114,218
entries per CLAUDE.md) and Movies sit on the parent `tank/media` dataset. They are writable by
beets-flask and are covered by no snapshot.

Anything that writes there has no rollback. That includes a library-browser DELETE (the `readonly`
flag is a UI guard the file itself calls weaker), a mis-rendered path, or a future `beet move` with a
bad `directory`. The freeze census and D-23 then certify this wider grant as "deliberate", because both
are keyed on the literal `/mnt/tank/media` → `/media` mapping.

**Fix:** Narrow the grant to the fenced dataset and keep the parent read-only:

```yaml
      - /mnt/tank/media:/media:ro
      - /mnt/tank/media/Music:/media/Music:rw   # D-22: rw only where the D-16 fence reaches
```

Then move `PHASE7_RW_TAGGER_SRC/DST` in check-music-freeze.sh and D-23's `D03_MEDIA_SOURCE`
expectation in quick-health-check.sh to the Music mapping in the same commit. D-23 should also assert
that the parent mapping stays `RW=false`.

### WR7-02: route-dj-album's `timeout 120 docker exec …` kills the docker CLIENT, not the beets write; a 124 on step (c) or (e) is reported as failed while the write is still running

**File:** `scripts/route-dj-album.sh:213, 219, 228` (and the header claim at lines 22-26)

**Issue:** CONVENTIONS §2's KNOWN LIMIT for `bounded_ssh` applies here unchanged. `timeout` signals the
`docker` CLI process, and `docker exec` does not forward that signal to the process it started. When
step (e) `move -a` exceeds 120 s, the script prints `❌ step (e) move failed (exit 124) … some files may
already have moved` and exits 1. Meanwhile `/venv/bin/beet move` keeps renaming files and updating
`library.db` inside beets-flask.

An operator acting on that message could snapshot, roll back, re-run the route, or start a Jellyfin
scan while a writer is still live. That is exactly the "writer-quiescence" hazard G-04 closed for
07-11. The same applies to step (c) `modify`. Step (d) is read-only, so it is harmless there. The
header says every beets call is "bounded", which is only true of the client. A killed `docker exec`
is also not distinguished from a genuine beets failure: rc 124 goes through the same
`fail "... failed (exit $RC)"` line.

**Fix:** Do not treat 124 on a writing step as a terminal state. Report it as "WRITER MAY STILL BE
RUNNING" and check for the process before exiting:

```bash
if [ "$RC" -eq 124 ]; then
  echo "  ⚠️  step (e) exceeded ${ROUTE_TIMEOUT}s — the docker CLIENT was killed; beets may STILL be moving files." >&2
  timeout 20 docker exec "$ROUTE_CONTAINER" pgrep -af '/venv/bin/beet move' >&2 || true
  refuse "step (e) UNVERIFIED: do not roll back, re-run or scan until no 'beet move' remains in $ROUTE_CONTAINER."
fi
```

Alternatively, run the write under an in-container bound (`docker exec … timeout 120 /venv/bin/beet …`),
provided coreutils `timeout` exists in the image. That keeps the bound on the Linux side of the exec,
which is what §2 asks for. Correct the header to match.

### WR7-03: quick-health-check labels the consumers audit's D-24-census exit 3 as "CONF-04 … artist rows at baseline", and the D-24 change never reaches its output

**File:** `scripts/quick-health-check.sh:2744-2822` (the `CONSUMERS_RC -eq 3` arm, 2804 in particular); `scripts/check-music-consumers.sh` (the D-24 exit-3 block ahead of the CONF-04 block)

**Issue:** Plan 07-07 routed a measured D-24 census change into exit 3, the same code as CONF-04
pending. The fold-in's exit-3 arm was not updated:

- It prints `⚠️ CONF-04 MEASURED AND OPEN — artist rows at baseline, not at target (exit 3)` whatever
  the cause.
- It extracts the audit's words with `sed -n '/CONF-04 IS NOT CLOSED/,/Discharges on ROADMAP/p'`. On a
  D-24-only exit 3 no such line exists, so the arm prints nothing.
- Its `SUMMARY` grep (`MA version|artist rows|FAILURES total`) does not match the new
  `D-24 census (Artists, no ArtistItems): …` summary line.

When CONF-04 rows are also pending, which is the live state, the D-24 change is invisible at the single
entry point. The run is still non-zero, so this is not fail-open, but it states a cause the run did not
establish (CONVENTIONS §1). The adjudicate-and-re-pin remedy that §5 prescribes for this pin cannot be
discovered from the check the operator actually runs.

**Fix:** Add the D-24 lines to the arm's greps and print the D-24 block separately. Choose the header by
cause:

```bash
SUMMARY=$(echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' \
          | grep -E 'MA version|artist rows|D-24 census|D-28 aunique|FAILURES total')
...
echo "$CONSUMERS_OUT" | sed -n '/D-24 CENSUS CHANGED/,/NOT green/p' | sed -n '1,4p' | sed 's/^ */    /'
```

Also use a label that does not assert CONF-04, for example "consumers audit exit 3 — measured, not at
target (CONF-04 pending and/or D-24 census changed)".

### WR7-04: The health-check failure tail still says RW=false on beets-flask "is expected until plan 07-09 deploys the grant"

**File:** `scripts/quick-health-check.sh:3378-3380`

**Issue:** 07-09 has deployed, so D-23's RW=true is now the standing state. Every failing run still
prints runtime text telling the operator that `RW=false on beets-flask is the red now — it is expected
until plan 07-09 deploys the grant`. That wording pre-excuses the regression D-23 exists to catch,
such as a container recreated from an older compose file. It is the "trained to ignore a red" trap
CONVENTIONS §4 argues against. Header notice T (lines ~84-88) carries the same text, but that is a
dated comment. This is output.

**Fix:** Replace it with a statement that holds now: `"RW=false on beets-flask is a REGRESSION of the
D-22 grant (container recreated from an older compose?) — not expected."` Drop the "until the first
pilot import" sentence at 3381-3383 as well; see IN7-03.

### WR7-05: The "fails closed on FEWER THAN TWO, and a line naming 01-auto is a red" registration gate is documented but not implemented

**File:** `stacks/selfhosted/arrs/beets/flask-config.yaml:76-79`, `stacks/selfhosted/arrs/beets/flask.yaml:252-255`; the only implementation is `scripts/check-beets-config.sh:936` (`READY_LINE="Registering watchdog with debounce"`)

**Issue:** Both vendored files say the readiness gate "fails closed on FEWER THAN TWO — and a
registration line that still names 01-auto is also a red while D-21 holds". No script does either:

- `check-beets-config.sh` greps the whole `docker logs` history for the fixed `READY_LINE` string. It
  counts no inboxes and never looks for `01-auto`.
- Because it reads all history, a registration line from before a restart (one that did name
  `01-auto`) satisfies the gate.
- quick-health-check has no registration assertion. The D-21 de-registration was verified once, by hand,
  in 07-09.

The vendored-file drift block would catch an appdata edit that re-registers 01-auto, because its sha
would no longer match HEAD. It would not catch a HEAD that does so, or a watchdog that failed to reload.
This is a control described as present that is absent ("docs describe intent, not reality").

**Fix:** Either implement the gate or retract the claim. Implementing it means reading only the newest
registration line after the container's `StartedAt`, parsing the inbox names, and asserting the exact
set, with `01-auto` absent and no `auto`/`bootleg` inbox (ties to CR7-01). Make it a standing
quick-health-check block, not only a first-start check.

### WR7-06: `IMPORT_SWEEP_TIMEOUT` cannot be raised without the run going red, so the fold-in's printed remedy (`REMOTE_TIMEOUT=300`) cannot rescue a slow sweep

**File:** `scripts/check-music-import.sh:122, 749-751, 766`; `scripts/quick-health-check.sh:2865-2883`

**Issue:** The fold-in wraps the sweep in `timeout $REMOTE_TIMEOUT` (default 120). The sweep bounds its
own `docker exec` at `IMPORT_SWEEP_TIMEOUT` (default 120), and any non-default value is an
additive-only override that forces exit 1.

On the 124 arm, the fold-in tells the operator to `Re-run with a larger budget …
REMOTE_TIMEOUT=300`. At 300 the inner 120 s bound becomes the binding one, and the sweep exits 3 with
"the dumper exceeded its 120s bound". The only knob that would help is one that can never be green.

Phase 9 runs this sweep after every batch over a growing library. The dumper stats and scandirs every
item directory, and the orphan pass visits every directory that holds an item. Once that exceeds 120 s
on a loaded dockerd, the sweep is permanently UNKNOWN with no sanctioned way out. It fails closed, but
the gate becomes unusable exactly when it matters.

**Fix:** Derive the inner bound from the outer rather than pinning it. For example, have the fold-in
pass `IMPORT_SWEEP_TIMEOUT=$((REMOTE_TIMEOUT - 10))` and have the sweep treat "≤ the caller's
REMOTE_TIMEOUT" as non-overriding. Alternatively, make the default generous (e.g. 600) and let the
outer REMOTE_TIMEOUT be the knob. Either way, make the printed remedy one that actually works.

### WR7-07: Section 4d's "two MA albums map the same directory" detection only runs on the rows it received; truncation is checked only when zero hits come back

**File:** `scripts/check-music-consumers.sh:1598-1627`

**Issue:** The outcomes table promises `ma_fail` when "two do" (two MA albums map the directory). The
album list is fetched once with `limit: 2000`, and the at-limit guard runs only in the `AU_N -eq 0`
branch. If the list is truncated, `AU_N == 1` can pass while a duplicate mapping of the same directory
sits past the limit. The project memory records that MA's `music/albums/count` silently ignores its
`provider` arg, so the provider filter cannot be assumed to keep the list small. That makes the
duplicate detection a claim the code cannot make once `AU_RETURNED >= MA_LIBRARY_SCAN_LIMIT`.

**Fix:** Run the at-limit check before the per-row loop, and fail UNKNOWN for every row when the list
is truncated:

```bash
if [[ "$AU_RETURNED" -ge "$MA_LIBRARY_SCAN_LIMIT" ]]; then
  ma_fail "D-28: album list came back AT the limit ($MA_LIBRARY_SCAN_LIMIT) — identity (0, 1 or 2 mappings) cannot be established; UNKNOWN"
else
  for row in "${AUNIQUE_ROWS[@]}"; do …
```

## Info

### IN7-01: The route-dj-album exemption key `.*\$BEET_REALLIB` exempts any line that merely mentions the token

**File:** `scripts/quick-health-check.sh:2186`

**Issue:** The key is `^HEAD:scripts/route-dj-album\.sh:[0-9]*:.*\$BEET_REALLIB`, so the token can
appear anywhere on the line. A line like `docker exec beets beet modify … "$BEET_REALLIB"`, or one with
a trailing `# $BEET_REALLIB` if comments survive `D04_KEPT`, would be exempted. It would invoke a
different beets while keeping the count at 12, so a one-for-one swap passes the `D04_EXEMPT_BASELINE`
pin.

**Fix:** Anchor the token to the invoked-binary position, e.g.
`…route-dj-album\.sh:[0-9]*:.*docker exec -u "\$ROUTE_USER" "\$ROUTE_CONTAINER" "\$BEET_REALLIB" `.

### IN7-02: `ambiguous` compares flattened tag objects that include the original key case, so a case-only difference reads as ambiguity

**File:** `scripts/diff-music-tags.sh:295`

**Issue:** `.t` maps each lower-cased key to `{n: <original key>, v: …}`. Two records with identical
values whose raw keys differ only in case (`TITLE` vs `title`) are counted as distinct variants and
push the whole run to exit 3. This fails closed (a false UNKNOWN), but one such pair anywhere in a
~9,700-record capture blocks the QUAL-02 gate for every diff.

**Fix:** Compare on values only: `(map(.t | map_values(.v)) | unique | length) > 1`.

### IN7-03: Stale runtime and in-band text: "the real library holds 0 items" / "UNKNOWN BY DESIGN until the first pilot import"

**File:** `scripts/quick-health-check.sh:2850-2852, 3357, 3381-3383`

**Issue:** The pilot has imported, so the block comment and the failure-tail echo now describe a past
state. The echo still tells the reader a ⚠️ from the sweep may be "by design". Under CONVENTIONS §12
this round-history belongs in the phase directory.

**Fix:** Keep the durable rule ("an empty library or a class with 0 checkable rows is exit 3, never
green") and delete the dated "until the first pilot import" framing from the echo.

### IN7-04: The sweep's dumper runs as root inside beets-flask, unlike every other exec against that container

**File:** `scripts/check-music-import.sh:766`

**Issue:** `docker exec "$IMPORT_SWEEP_CONTAINER" /venv/bin/python …` has no `-u`. check-beets-config.sh
and route-dj-album.sh both use `-u beetle` and call that load-bearing. Running as root makes the
`dir_error` "directory unreadable" UNKNOWN arm effectively unreachable, because it measures root's view
rather than the importer's. It also means beets' config loader, including confuse's BEETSDIR mkdir, runs
as root. The effect is small because the program is read-only, but it is inconsistent with the stated
contract.

**Fix:** Add `-u beetle`, so the sweep sees the library as the importer does.

---

_Reviewed: 2026-09-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
