---
phase: 06-tagger-configuration-and-dry-run
plan: 07
subsystem: tooling
tags: [beets, beets-flask, assertion-script, effective-config, confuse, eyconf, health-check]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-04's running beets-flask rc6 container — the process whose effective config this plan asserts"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "plan 06-01's vendored config.yaml, which pins the four rc6 schema-default landmines this plan measures"
  - phase: 05-inbox-structure-and-the-junk-gate
    provides: "the three registered _inbox folders whose watchdog registration line is this script's readiness gate"
provides:
  - "scripts/check-beets-config.sh — the standing assertion over the SERVER-COMMITTED effective beets config, with a --self-test"
  - "the D-30 record: both arms measured, named by route, and their 26 disagreements tabled"
  - "A3, A4 and A5 each carrying an explicit CONFIRMED/FALSIFIED verdict"
  - "the finding that max_filename_length: 0 is a real 200-character limit, not 'no truncation'"
  - "the finding that a -c overlay never meets rc6's eyconf validation, which unblocks 06-08's D-31 control"
affects: [06-08, 06-09, 06-10, 06-12, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "When two routes read what looks like one object, name both routes and prove they are two objects rather than letting one stand for the other"
    - "A comparison that reports few differences must be driven to report one, or 'few' and 'the predicate is dead' are the same output"
    - "Lift a helper out of the script under test rather than reimplementing it for the control — a second copy can agree with the first while both are wrong"
    - "jq `leaf_paths` / `paths(scalars)` silently drops every `false` leaf; enumerate paths and filter on type instead"

key-files:
  created:
    - scripts/check-beets-config.sh
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-07-effective-config.txt
  modified: []

key-decisions:
  - "Every assertion is read from arm 1 (server-committed) and from no other arm; arm 2 is recorded and compared but never asserted from"
  - "The script has exactly one env override, and it is additive — everything else is a plain constant because an override on it could manufacture a pass"
  - "import.write is REPORTED, not asserted: asserting `no` here would be asserting something false about the file and true only about an invocation"
  - "The max_filename_length finding is recorded as a follow-up against plan 06-01's file, NOT fixed here — editing a config until a check goes green is the shape this project exists to avoid"

requirements-completed: [CONF-01, CONF-02, CONF-05]

# Metrics
duration: 55min
completed: 2026-09-21
---

# Phase 6 Plan 07: The effective config of the process that actually imports Summary

**CONF-01, CONF-02 and CONF-05 are now asserted against the object rc6's `commit_to_beets()`
builds — not against the file, and not against the CLI's view of the file — and all four of rc6's
schema-default landmines read the vendored value, including the one that is a silent delete.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 2 of 2
- **Files created:** 2 (1 script, 1 artifact)
- **Commits:** 3 (one is an in-band fix to my own instrument)

## Accomplishments

- **The ambiguity that deletes files is now measured rather than reasoned about.** `beet config -d`
  and the server-committed dump are two routes to two different objects. The script names both
  (`CONFIG_ROUTE=server-committed`, `CONFIG_ROUTE_CLI=confuse`), asserts only from the first, and
  prints both names in its summary.
- **`import.duplicate_action` reads `ask` in the object that will actually import.** This is the
  only place that value is visible: rc6's injection happens inside the server process, so a CLI
  reading would have reported `ask` whether or not the server was about to delete duplicates with
  no prompt. T-06-31 mitigated by measurement.
- **All three research assumptions resolved with explicit verdicts**, including one falsification
  that is load-bearing rather than pedantic (A4).
- **The `--self-test` drives five synthetic dumps, four of them red**, including the empty-dump
  blind case at 22 reds and the CONF-02 trap at exactly one.
- **Two positive controls were driven on the instruments themselves** after the inter-arm
  comparison returned a suspiciously small answer — which is how a genuine defect in my own
  extractor was found.

## Task Commits

1. **Task 1: write `scripts/check-beets-config.sh` with a `--self-test`** — `20dc933` (feat)
2. **In-band fix: quote-aware flow-sequence split in the extractor** — `ce4f6d7` (fix)
3. **Task 2: run both arms live and record the disagreements** — `0b385b5` (docs)

## Files Created/Modified

- `scripts/check-beets-config.sh` (915 lines) — S1–S5 throughout: the header is the `--help`
  output, the exit-code convention is stated rather than inherited, section 0 treats a missing
  binary as a harness failure, `beet_exec()` is a named route-recording wrapper styled on
  `zfs_query()`, and every UNKNOWN sentinel is initialised before anything runs. Readiness is
  gated on the watchdog registration line. Absolute `/venv/bin` paths and a literal `-u beetle`,
  both load-bearing. No credential is ever passed with `-e` on an exec.
- `.planning/.../artifacts/06-07-effective-config.txt` (813 lines) — both full dumps, the
  `config -p -d` source list, the 26-row disagreement table, the A3/A4/A5 verdicts, the redaction
  no-op, the D-29 fence either side, two instrument controls, and four recorded findings.

## Decisions Made

- **The script has no knob that can manufacture a pass.** `LXC_HOST`, `CONTAINER`, `BEET_BIN`,
  `PY_BIN`, the exec identity and both timeouts are plain constants, for the reason
  `check-music-freeze.sh:85-89` gives about `SURVIVOR_DB`. The single override,
  `EXTRA_FORBIDDEN_SUBSTRINGS`, appends to a built-in list and can only add reds.
- **D-29 layer 3 was folded into this script even though the plan did not ask for it.** `beet`
  opens the library for every subcommand, so `config -d` is a real opportunity for `library.db`
  or `state.pickle` to move. Both are hashed either side and asserted unchanged; both match
  06-06's recorded baselines exactly (`fbbdde0c…`, `f6a9a1ad…`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] My own dump extractor split a quoted comma in half**
- **Found during:** Task 2, the wider inter-arm sweep
- **Issue:** The flow-sequence splitter used a plain `split(',')`. confuse dumps
  `gui.library.artist_separators` as `[',', ;, '&']` — whose first element is a *quoted comma* —
  so one element became two half-quotes and the list read as 4 separators where the config
  declares 3. No key the script asserts carries a quoted comma today, which is exactly why it
  would have sat unnoticed until one did.
- **Fix:** a quote-aware scanner, with the reason recorded in the docstring so it is not
  simplified back. Post-fix reading: `[",",";","&"]`.
- **Files modified:** `scripts/check-beets-config.sh`
- **Commit:** `ce4f6d7`

**2. [Rule 2 - Missing critical functionality] The comparator had never been shown able to report a value difference**
- **Found during:** Task 2
- **Issue:** The live comparison returned 2 differing rows, and *both* were "present in arm 1,
  absent in arm 2". A comparator proven able to report an absence has not been proven able to
  report a *different value*, and "no value differences" is indistinguishable from "the value
  comparison never fires" — the exact shape 06-06 warned about.
- **Fix:** drove a known value difference through it (arm 1 vs an arm 2 perturbed by the A3
  overlay), using the extractor **lifted verbatim out of the script** rather than reimplemented.
  `.import.copy true vs false` fired. Recorded as Control A in the artifact.
- **Files modified:** none (control run, recorded in the artifact)
- **Commit:** `0b385b5`

**Total deviations:** 2 auto-fixed (1 × Rule 1, 1 × Rule 2). No scope change.

## Issues Encountered

**⚠ The three assumption verdicts, and why A4's falsification matters.**

- **A5 CONFIRMED.** The call shape 06-RESEARCH.md:564-568 recorded as "NOT VERIFIED by execution"
  works exactly as written. No fallback route was needed and arm 2 was never substituted for arm 1.
- **A3 CONFIRMED, with a stronger mechanism than "escapes".** A `-c` overlay is accepted, wins,
  and produces empty stderr — because `/venv/bin/beet` is a four-line entry point whose whole body
  is `from beets.ui import main`. It imports no beets-flask module, so eyconf is never constructed
  and there is nothing to refuse. **Plan 06-08's D-31 control may use a `-c` overlay.** Carry-
  forward: an overlay setting `copy: no` leaves `move: no` alone — that is beets' import-in-place
  mode, not a move. Set what you mean.
- **A4 FALSIFIED as written.** The research says "`docker exec` inherits the image ENV, so
  `BEETSDIR=/config/beets` applies". Measured: `BEETSDIR=/config`. An exec inherits the
  **container's resolved environment** — image ENV overlaid with compose's `environment:` — and
  `flask.yaml` sets `BEETSDIR: /config` deliberately. This is not pedantry: had the image ENV
  applied, `$BEETSDIR/config.yaml` would be `/config/beets/config.yaml`, which is **not** the
  vendored file, and arm 2 would have been an honest reading of the wrong config. The consequence
  the research drew from A4 survives, and is independently confirmed by `config -p -d` listing
  `/config/config.yaml`.

**⚠ The first version of my inter-arm sweep produced a clean, plausible, completely false table.**
The predicate was `paths(scalars==true or type=="array")`. `scalars` *emits* the value when it is
a scalar, so `scalars==true` asks whether that value **equals** true — not whether it **is** a
scalar. It saw 16 leaf keys out of 186 and reported exactly one disagreement. The obvious
replacement, `leaf_paths`, is no better: it is `paths(scalars)`, and `paths(f)` keeps a path only
when `f` is *truthy*, so every `false` leaf is silently dropped — in this config that is
`import.move`, `asciify_paths` and all three SAFE-01 switches, i.e. the five keys a music-library
safety check most needs to see. Hence Control B in the artifact, which asserts those five survive
the flatten before the table is believed.

**⚠ The four landmine keys do NOT appear in the disagreement table, and that is the result rather
than an omission.** The arms agree on `duplicate_action`, `medium_rec_thresh`, `directory` and
`statefile` because plan 06-01 pinned all four. rc6's `to_dict()` serialises the schema dataclass
*as populated from the user's config*, so a key the user set carries the user's value in both
arms; only a **silent** key carries rc6's default. Had 06-01 left any of the four silent, its row
would be in the table with rc6's value in the arm-1 column — which is precisely what this check
exists to catch.

**⚠ This plan's own task-2 `<verify>` contains a guard that can never fire.** It reads
`if grep -qE "\bUK\b" "$f" | grep -qi "countries"`. `grep -q` writes nothing to stdout, so the
second grep always reads an empty stream, always exits 1, and the `if` is unreachable. Same class
as 06-06's poll predicate and as my own first sweep. Left as written rather than edited: the
assertion it was reaching for **is** made, from arm 1, by the standing script, and is driven red
by self-test case 4.

## Findings recorded, deliberately NOT fixed in this plan

**`max_filename_length: 0` is not "no truncation" — it is a real 200-character limit.**
`config.yaml:263` says "No truncation … a silent mid-name truncation would make the expected-tree
diff (D-27) report a path difference that is really a length limit." Measured against beets
2.12.0's own source inside the container: the config value is `0`, the **effective** limit is
**200**. `util.get_max_filename_length()` returns the config value *only if truthy*, then falls
through to `min(statvfs NAME_MAX, 200)`. So the stated intent is not achieved by this value, and
the number that would achieve it is a large explicit one.

This is a follow-up commit against plan 06-01's file, not this plan's work — quietly editing a
config until a check goes green is the shape this project exists to avoid. **It is material to
plans 06-08/06-09:** any component of `$albumartist/$album%aunique{}/$disc-$track $title` longer
than 200 characters will be truncated, and `06-EXPECTED-TREE.txt` was written without that
constraint in view.

## Known Stubs

None. Every assertion reads live state; nothing renders placeholder data or leaves an unwired path.

## Threat Flags

None. This plan introduces no new network endpoint, auth path or schema change. Its one new file
access pattern — `docker exec` into a running container — is already in the plan's threat register
(T-06-34) and is mitigated as written there: the readiness gate is the watchdog log line, and the
task-1 verify fails the script if the container-liveness field appears in executable lines.

## Next Phase Readiness

**Ready for 06-08 onward.**

- **06-08's D-31 control is unblocked.** A3 is confirmed: a `-c` overlay is accepted by `beet`,
  wins over the vendored config, and never meets eyconf. The `copy: yes` into-a-`/tmp`-tree
  fallback is not needed.
- **06-09's expected-tree diff has a new constraint to honour** — the 200-character per-component
  limit under Finding 1.
- **The script is ready to be folded into `quick-health-check.sh`** by whichever plan owns that,
  in the same one-line `ssh` shape the other checks use. It is NOT folded in here; that is not
  this plan's scope.

Two things explicitly not done:

1. **`config.yaml`'s `max_filename_length` comment is still wrong.** Recorded above, owned by a
   follow-up against plan 06-01's file.
2. **The script is not scheduled and not folded into the routine check.** It is manual-only today,
   the same status `check-music-freeze.sh` carried before its promotion.

## Self-Check: PASSED

Both claimed files exist on disk:
- `scripts/check-beets-config.sh` — FOUND (executable)
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-07-effective-config.txt` — FOUND

All three claimed commits are present in this branch's history: `20dc933`, `ce4f6d7`, `0b385b5`.

Both verification commands pass: task 1's (`bash -n`, `shellcheck -S error`, `--self-test`, `-h`,
the nine required strings in comment-stripped executable lines, no container-liveness gate, no
skip/force sentinel) and task 2's (the six keys present in the artifact, A3/A4/A5 each with a
verdict, no silent-delete duplicate action, and `scripts/check-beets-config.sh` exiting 0 against
the live container). The phase-level greppable rule also holds: `grep -n 'timeout \$REMOTE_TIMEOUT.*|'`
returns **no** lines, because every bounded remote command redirects to a file and ssh's status is
read with no local pipe in front of it.

**Git delivery note:** this plan ran as a parallel executor in a worktree. STATE.md, ROADMAP.md and
REQUIREMENTS.md were deliberately NOT touched — the orchestrator owns those writes after the wave
merges. The three commits above live on `worktree-agent-a2224c6efefc801c2` until then.

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-21*
