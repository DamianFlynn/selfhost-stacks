---
phase: 06-tagger-configuration-and-dry-run
plan: 18
subsystem: testing
tags: [bash, shellcheck, ssh, docker-exec, quoting, beets, phase06-oracle]

# Dependency graph
requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "scripts/phase06-oracle.sh and the committed 06-11 CONF-03/CONF-06 artifacts that plan 06-14 and the 06-REVIEW findings are written against"
provides:
  - "A literal allow-list fence on the oracle's two destructive knobs (SCRATCH, STAMP_REMOTE), evaluated before the first ssh of every mode and duplicated inside the remote programs adjacent to the rm"
  - "remote_sh_c: the helper that puts every remote path across the quoting boundary as a positional parameter rather than as program text"
  - "Per-run-unique in-container temp names beneath SCRATCH"
  - "A --self-test block over an apostrophe-and-$ fixture, with a driven red that shows the old construction failing"
  - "artifacts/06-18-oracle-fence-driven.txt: the four fence drives, the poisoned-ssh-stub proof, and an explicit NOT-DRIVEN register"
affects: [06-19, 06-21, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sending-side fence plus receiving-side fence: a literal case allow-list on the workstation AND inside the remote program, deliberately duplicated"
    - "remote_sh_c: sh -c '<prog>' sh <%q args> - paths are parameters, never program text"
    - "Poisoned-PATH-stub proof for 'this happens before any remote call'"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-18-oracle-fence-driven.txt
  modified:
    - scripts/phase06-oracle.sh

key-decisions:
  - "The SCRATCH allow-list constrains the SUFFIX to [A-Za-z0-9._-], not just the /tmp/p6-* glob: the bare glob still admits '/tmp/p6-x /config', the exact word-splitting shape the fence exists to refuse"
  - "SCRATCH's own default stays /tmp/p6 and only the files beneath it carry the run tag, because the precheck, the cleanup assertion, the fence's allow-list and the committed 06-11 artifacts all quote /tmp/p6 by name"
  - "The fence is placed after the argument dispatch, not before it, so --help still works when a knob is hostile while --run / --baseline / --self-test all still pass through it"
  - "The -printf format is preserved as real TAB and real LF (spelled $'\\t' / $'\\n'), not as the two-character escapes, because that is what the pre-change printf actually emitted - proven byte-identical by a find-argv stub"
  - "WR-01 (the in-container pipeline at the dirty-destination precheck) was deliberately NOT fixed: it belongs to plan 06-19"
  - "No oracle --run and no estate --baseline was performed; every change is proven by bash -n, shellcheck, --self-test and pre-ssh fence refusals"

patterns-established:
  - "Duplicated fence: the sending layer stops the common case, the receiving layer is the one adjacent to the destructive command and the one a future edit cannot quietly strip"
  - "Driven red inside the self-test: a case that proves the NEW shape works is paired with one that proves the OLD shape failed"
  - "Mutation testing of the self-test itself: revert the fix in a copy of the script, require the new cases to go red"

requirements-completed: [CONF-03, CONF-06]

# Metrics
duration: 42min
completed: 2026-09-22
---

# Phase 6 Plan 18: Oracle Destructive-Knob Fence Summary

**`scripts/phase06-oracle.sh`'s two destructive knobs are now fenced to literal allow-lists at both the sending and the receiving layer, every remote path crosses the ssh → docker exec → dash boundary as a positional parameter instead of as `%q`-quoted program text, and the header's "every knob can only make the verdict redder" claim is true as written for the first time.**

## Performance

- **Duration:** ~42 min
- **Completed:** 2026-09-22
- **Tasks:** 3 of 3
- **Files modified:** 1 modified, 1 created

## Accomplishments

- **WR-07 closed.** `SCRATCH` and `STAMP_REMOTE` are validated against literal allow-lists before the script's first ssh in every mode, and the same `case` fence is repeated inside the two remote programs that run `rm -rf` / `rm -f`. `SCRATCH='/tmp/p6 /config'` — which used to word-split inside the container into `rm -rf /tmp/p6 /config`, deleting the real `library.db`, `state.pickle` and the vendored config — now refuses with exit 2 and zero ssh invocations.
- **WR-08 closed.** All three `sh -c 'find <%q path>'` sites pass the path as `$1` instead. A folder named `Guns N' Roses - …` no longer produces `unexpected EOF while looking for matching '` on the far side. The `find` argv is proven **byte-identical** to the pre-change value, `-printf` format included, so the committed 174-destination artifact stays comparable.
- **IN-06 closed.** The in-container temp files beneath `$SCRATCH` carry the run's PID; `$SCRATCH` itself is unchanged so every path the fence, the precheck and the committed artifacts name stays true.
- **IN-11 closed.** The dirty-destination refusal now prints the exact cleanup command and states that `--baseline` always leaves the host stamp by design.
- **"Before any ssh" is measured, not asserted.** `ssh` was replaced on PATH by a poisoned stub that records and never connects; the log is empty across all four fence refusals including under `--baseline`, and the counter is itself controlled by an allowed value that does reach ssh (1 invocation, to TEST-NET-1).
- **The new self-test cases are proven able to fail.** Reverting `remote_sh_c` to the old shape in a copy of the script turns six of the seven red and takes `--self-test` to exit 1. The seventh is the DRIVEN RED itself, which correctly stays green because it exercises the old construction directly rather than through `remote_sh_c`.

## Task Commits

1. **Task 1: Fence the two destructive knobs, and quote every use** — `7c2e349` (fix)
2. **Task 2: Positional parameters, unique temp paths, apostrophe proof** — `89a349b` (fix)
3. **Task 3: Drive the fences, record what was NOT driven** — `219153e` (docs)

## Files Created/Modified

- `scripts/phase06-oracle.sh` — the fence, `remote_sh_c`, the seven re-quoted/re-parameterised remote-command sites, the run-tagged scratch names, the amended override-contract paragraph, the IN-11 refusal text, and seven new `--self-test` cases (73 → 80, all green).
- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-18-oracle-fence-driven.txt` — four fence drives, the poisoned-stub "before any ssh" proof, the byte-identity proof for `-printf`, the mutation proof for the new self-test cases, the shellcheck note triage, an explicit NOT-DRIVEN register, and the full 121-line clean self-test transcript.

## Decisions Made

- **Fence placement after the argument dispatch.** The plan asked for "where all modes reach it". Placing it immediately after `[ -n "$MODE" ] || usage` covers `--run`, `--baseline` and `--self-test` while leaving `--help` usable when a knob is hostile — which matters, because `--help` prints the contract the refusal refers to.
- **The suffix character class.** A bare `case "$SCRATCH" in /tmp/p6-*)` still admits `/tmp/p6-x /config`. The allow-list therefore constrains the suffix to `[A-Za-z0-9._-]` as well. The same for `STAMP_REMOTE` under `/mnt/fast/safety/phase06/`.
- **`$'\t'` / `$'\n'` rather than the escape sequences** in the manifest `-printf` format. Counter-intuitive but correct: the pre-change `printf` resolved `\\t`/`\\n` while building the string, so the remote program has always carried a real tab and a real newline. Byte-identity was proven with a stub `find` that prints its own argv, not argued.
- **Two shapes for the `-newer` sweep's folder list.** `NEWER_ARGS` (a `%q`-quoted string) still feeds the bare-word `find`, where `%q` is correct; a new `NEWER_LIST` array feeds the preflight, where the paths must be parameters. Two contexts, two tools — and `:2053`'s bare-word site is verified untouched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Every structural check in the plan's `<verify>` blocks could never pass**

- **Found during:** Task 1 (first run of the plan's own verify command)
- **Issue:** Both task 1's and task 2's verify blocks were written as `bash -c 'set -o pipefail; …; printf "%s\n" "$s" | grep -qE "…" || { echo "no … fence"; exit 1; }'`. `grep -q` exits on its FIRST match and closes the pipe; `printf` then takes SIGPIPE; `pipefail` propagates 141. So each assertion fired its **failure** branch precisely when the file was **correct**. Measured directly: identical pattern, identical input, `rc=0` without `pipefail` and `rc=141` with it. This is the same defect family the cross-plan warning flagged from sibling plan 06-15 — a verify that does not measure what it claims — but inverted: rather than passing vacuously it fails unconditionally, which would have driven an executor to "fix" correct code.
- **Fix:** The comment-stripped text is materialised into a temp file and grep reads the file, so there is no pipe. Nothing asserted was weakened; three extra assertions were added (the duplicated in-remote fence, its explanatory comment, and the IN-11 refusal text), because the plan's acceptance criteria named them but its verify did not check them.
- **Files modified:** none in the repo — the correction is to the verification method, recorded here and in the artifact.
- **Verification:** corrected verify runs green on the finished file and red on a file missing the fence.
- **Committed in:** n/a (verification method, not repo content)

**2. [Rule 1 — Bug] Task 2's verify contained an unbalanced quote and a vacuous alternative**

- **Found during:** Task 2
- **Issue:** `grep -qiE "apostroph|Guns N|'"` was written inside a `bash -c '…'` body. The bare `'` **closes that body**, so the command as written is not the command that would run. And as a regex alternative a lone `'` matches almost any line of an 121-line transcript containing contractions — vacuous even if it parsed.
- **Fix:** Dropped the `'` alternative; kept `apostroph|Guns N`, which discriminates. Added a second assertion requiring the literal string `DRIVEN RED` in the transcript, so the old-shape negative is checked rather than assumed.
- **Files modified:** none in the repo.
- **Verification:** the corrected check passes on the real transcript and fails on one with the WR-08 block removed.
- **Committed in:** n/a

**3. [Rule 2 — Missing critical functionality] A fourth unquoted `$SCRATCH` inside a remote `sh -c`**

- **Found during:** Task 1
- **Issue:** The plan's Edit 2 listed five `$SCRATCH` sites. A sixth existed that it did not name — the overlay placement, `docker exec -i … sh -c 'cat > $SCRATCH/overlay.yaml'` — with the knob interpolated unquoted inside a single-quoted remote program, i.e. the same WR-07/WR-08 defect at a site that **writes**.
- **Fix:** Routed through `remote_sh_c` like the others.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** `bash -n`, `shellcheck -S warning`, and the comment-stripped scan for surviving interpolated-knob-inside-`sh -c` sites returns zero.
- **Committed in:** `7c2e349`

**4. [Rule 2 — Missing critical functionality] `%q` added at the four bash-word `$SCRATCH/...` sites**

- **Found during:** Task 2
- **Issue:** `dex_cmd "$BEET_BIN" -c "$SCRATCH/overlay.yaml" …` and the ledger's `… $PY_BIN - $SCRATCH/lib.db $LIB_ROOT` place the path in a bash word unquoted. The fence makes word-splitting impossible now, but that is a fence-depends-on-fence argument at four sites that are trivially quotable.
- **Fix:** `printf '%q'` at each — the correct tool for a bash-word context, and the same treatment `$CPATH` already had.
- **Files modified:** `scripts/phase06-oracle.sh`
- **Verification:** `bash -n`, `shellcheck -S warning`, `--self-test` exit 0.
- **Committed in:** `89a349b`

---

**Total deviations:** 4 auto-fixed (2 × Rule 1, 2 × Rule 2)
**Impact on plan:** No scope creep. Two are corrections to the plan's own verification (which could not have passed as written); two extend the plan's stated fix to sites of the same defect family that the plan's site list missed. Every acceptance criterion in the plan is met, and `:2053`'s deliberately-untouched site is verified unchanged.

## Issues Encountered

- **The plan's verify blocks were unrunnable as written** (deviations 1 and 2). Resolved by rewriting the verification method and recording the measurement that proves the original could not pass. Worth carrying forward: `set -o pipefail` plus `printf | grep -q` is a false-red generator, and it is the mirror image of the false-green shapes 06-15 found.
- **No other problems.** `shellcheck -S warning` was clean before the change and is clean after; `--self-test` went 73 → 80 cases with no regressions (measured by re-running the task-1 commit's copy of the script, not counted by eye).

## NOT-DRIVEN register (for plan 06-21)

Four items are **asserted by construction** — `bash -n`, `shellcheck` and review-by-reading — and not by a firing observation. Each is recorded in `artifacts/06-18-oracle-fence-driven.txt` § 10 with the condition that would drive it:

| ID | Item | Condition that would drive it |
|----|------|-------------------------------|
| WR-07 (a) | The duplicated fence **inside** the two remote programs | A remote call whose path passes the sending fence and fails the receiving one — reachable only if the two allow-lists drift apart, which is the drift the duplication exists to survive |
| IN-11 | The dirty-destination refusal's new cleanup text | A dirty `$SCRATCH` inside the live container, i.e. a run aborted between step 5 and step 12 |
| WR-08 (b) | The positional-parameter construction against the **live** GNU `find` | The next real `--run`, whose layer-2 manifests exercise all three sites |
| IN-06 | The run-tagged names `lib.$$.db` / `overlay.$$.yaml` / `state.$$.pickle` | The next real `--run`; `--self-test` never reaches step 5 |

## User Setup Required

None.

## Next Phase Readiness

- **WR-01 remains open and is plan 06-19's.** The in-container `ls -A "$1" | head -n 1` pipeline at the dirty-destination precheck still runs under the container's `pipefail`-less dash. It was deliberately not fixed here; the only change at that site is that the path is now a positional parameter, which does not affect 06-19's fix.
- **CONF-03 / CONF-06 evidence is untouched.** `artifacts/06-11-oracle-run.txt` and `06-11-wrote-nothing.txt` stand as the phase's proof. The one change that could have affected their comparability — the `-printf` format — is proven byte-identical.
- **No estate contact.** No `--run`, and the only `--baseline` invocations went to a poisoned `ssh` stub and to TEST-NET-1 (192.0.2.1). LXC 100 was not touched by this plan.

## Self-Check: PASSED

Every claim above re-measured after the fact, not restated:

| Claim | Check | Result |
|-------|-------|--------|
| `scripts/phase06-oracle.sh` modified | `[ -f … ]` | FOUND |
| `artifacts/06-18-oracle-fence-driven.txt` created | `[ -f … ]` | FOUND |
| `06-18-SUMMARY.md` created | `[ -f … ]` | FOUND |
| Commits `7c2e349`, `89a349b`, `219153e`, `546bc55` | `git log --oneline --all` | all FOUND |
| `--self-test` exits 0, 80 green / 0 red | re-run | rc=0, 80 / 0 |
| `bash -n` clean | re-run | rc=0 |
| `shellcheck -S warning` clean | re-run | rc=0 |
| `:2053`'s bare-word `find $NEWER_ARGS` untouched | `git diff 3c155b5 HEAD` over the file | no diff line touches it |
| 73 → 80 cases | re-ran the task-1 commit's copy of the script | 73 before, 80 after |

One claim was **corrected by this check rather than confirmed**: the first draft of
this summary said "six new cases, 74 → 80". The real figures are seven new cases and
73 → 80 — six of the seven go red under the mutant, and the seventh is the DRIVEN RED,
which correctly stays green. Both numbers had been counted by eye off the transcript
instead of measured; they are now measured.

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-22*
