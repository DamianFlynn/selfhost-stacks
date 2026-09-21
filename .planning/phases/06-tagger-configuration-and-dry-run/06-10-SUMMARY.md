---
phase: 06-tagger-configuration-and-dry-run
plan: 10
subsystem: health-harness
tags: [health-check, drift-detection, docker-inspect, beets, fail-closed]
requires:
  - "stacks/selfhosted/arrs/beets/flask.yaml (plan 06-04) — the second tagger definition the census now expects"
  - "stacks/selfhosted/arrs/beets/flask-config.yaml (plan 06-04) — the fourth vendored file"
  - "beets-flask running on LXC 100 (plan 06-04) — the runtime the D-03 mount assertion reads"
provides:
  - "check-music-freeze.sh: a two-definition tagger census asserted by NAME and CLASS, not by count"
  - "quick-health-check.sh: a four-pair vendored-file drift block"
  - "quick-health-check.sh: the D-03 mount assertion (one vendored config into both containers, from docker inspect .Mounts)"
  - "quick-health-check.sh: the D-05 read-only assertion on /mnt/tank/media for BOTH containers, from the runtime"
  - "quick-health-check.sh: the D-04 assertion that no executable beet invocation opens the real library"
  - "DRIFT_REPO_ROOT / D04_REPO_ROOT — force-red overrides that make both new blocks' violation branches driveable"
affects:
  - "scripts/quick-health-check.sh — two new fatal blocks; eighth and ninth block ordinals"
  - "stacks/selfhosted/arrs/beets.md — criterion 1's resolution superseded; two runbook commands flagged DO-NOT-RUN"
tech-stack:
  added: []
  patterns:
    - "a count is not a membership test: the expected SET is compared, so two-with-wrong-members is a red"
    - "answer a mount question with docker inspect .Mounts, never with a hash"
    - "render a dormant service with `docker compose --profile manual config`; without the profile it emits `services: {}`"
    - "record raw, comment-stripped and narrowed counts so the strip is provably doing work"
    - "give a host-path-reading block a force-red repo-root override, or its violation branch can never be driven"
key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-10-harness-run.txt"
    - ".planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md"
  modified:
    - "scripts/check-music-freeze.sh"
    - "scripts/quick-health-check.sh"
    - "stacks/selfhosted/arrs/beets.md"
decisions:
  - "D-11 discharged by revising the expected SET to two named-and-classed definitions; the match pattern was NOT narrowed, because narrowing it is what would have disarmed the guard that just fired"
  - "D-03's mount half asserted from `docker inspect .Mounts` for the running front end and `docker compose --profile manual config` for the dormant arm — two instruments, because the container states differ"
  - "D-04 scopes `*.md` OUT of its assertion (two hits are historic quotations that must not be rewritten) but COUNTS documentation hits against a pinned baseline of 2, so a new copy-pasteable bare invocation is still a red"
  - "Added DRIFT_REPO_ROOT and D04_REPO_ROOT rather than leaving two new red branches undriveable; both force EXIT_CODE=1 so neither can manufacture success"
metrics:
  duration: "~2h"
  completed: "2026-09-21"
  tasks: 3
  commits: 4
---

# Phase 6 Plan 10: Realign the Standing Health Harness Summary

The tagger census now expects **two** definitions asserted by name and class rather than one by count, the vendored-drift block covers **four** files, and D-03/D-04 became assertions read from the runtime and the tracked tree instead of comments — with every new red branch driven to red and back to green.

## What Was Built

**D-11 — the census (`scripts/check-music-freeze.sh`).** The expected set is now the named pair `beets/flask.yaml` (ACTIVE front end, `metasauce/beets-flask:v2.0.0-rc6`, engine beets 2.12.0) and `beets/beets.yaml` (DORMANT agent-driven CLI arm, `lscr.io/linuxserver/beets:2.13.1-ls349`), each printed on its own line with its class. **The match pattern is byte-identical to what Phase 4 wrote** — it was not narrowed to make the count fit, because `beets-flask` was put inside that alternation on purpose so a Phase 5/6 definition would go red rather than arrive unnoticed. It did, and this plan revised the expectation instead of the instrument.

The comparison is of the **sorted member set**, not the count. Proven by control H below: two definitions whose members are wrong is a red, which a bare `-eq 2` would have passed.

All six cross-file label tokens are intact, and the two new class lines **deliberately repeat the `tagger definitions` token** — `quick-health-check.sh`'s fold-in selects the summary with a `grep -E` over ten tokens, so a line without one is dropped from that transcript silently. The `TAGGER_DEFS="UNKNOWN"` sentinel is unchanged.

**D-03 — one config, both containers (`scripts/quick-health-check.sh`).** Two things landed, kept separate because they are different claims measured by different instruments:

- A **fourth `_drift_pair`** for `stacks/selfhosted/arrs/beets/flask-config.yaml` against `/mnt/fast/appdata/arrs/beets/config/beets-flask/config.yaml`. All five load-bearing pieces moved in the same edit: the scope comment (three pairs → four), the hard-coded `DRIFT_LINES -ne 3` → `-ne 4` with its message verbatim, the closed label `case` arm, `DRIFT_EXPECT_FLASK_CONFIG` beside its three siblings, and the green line naming four files.
- A **new mount assertion**, which is the half a hash cannot answer. It reads `docker inspect .Mounts` on the running `beets-flask` and `docker compose --profile manual config` on the dormant arm, and asserts both declare the same source at the same destination `:ro`, and both hold `/mnt/tank/media` read-only. That last one is **D-05 asserted from the runtime rather than read from the file** — the WR-02 lesson.

**D-04 — the throwaway `-l` plus `-c` overlay.** A new block scans the host's HEAD under `scripts/` and `stacks/` and requires every invocation-shaped `beet` line in an executable file to carry both a `-l` outside `/config/library.db` and a `-c` overlay. The block states **why `-l` alone is not enough**: it redirects `library:` but not `statefile:`, so a throwaway import on a throwaway `-l` still writes the shared `state.pickle`. Raw, comment-stripped and invocation-shaped counts are all printed, and the block goes UNKNOWN if the strip removes nothing — because a single number cannot tell "nothing matched" from "the pattern was wrong".

**A tenth EXIT-CODE notice** records both new fatal blocks, with header/raw counts measured before and after (9 → 10 and 12 → 13).

## Key Decisions

**The pattern was not narrowed, and that is the whole point.** Dropping `beets-flask` from the alternation would have made `tagger definitions: 1` true again. Control G shows the widened pattern still catches a registry-namespaced non-beets tagger (`mikenye/picard:latest`) after the revision — the WR-03/WR-04 property survived the change.

**D-03 is a mount question, so it is answered by `docker inspect`.** `quick-health-check.sh:1183` already argued against a fourth `_drift_pair` as the fix for D-03, and it was right about that: a hash cannot tell you *which containers* read the file it hashed. But that argument does not apply to `flask-config.yaml` itself, which is a genuinely new vendored file carrying no credential — so the plan's split (a pair **and** a mount assertion) is the correct reading, and both landed.

**`*.md` is scoped out of the D-04 assertion but counted.** The only two invocation-shaped `beet` lines anywhere in the tree are in `beets.md`, and both are historic: one quotes "the documented flow" as the header comment stated it in Nov 2025, the other is the Aug-2026 triage sketch. Rewriting a quotation to satisfy a grep falsifies a record this repo keeps on purpose. Instead both were flagged **⛔ DO NOT RUN** in place with the D-04 mechanism spelled out, and the documentation count is pinned at 2 so a *new* copy-pasteable bare invocation is its own red.

**Two force-red overrides were added rather than leaving branches unproven.** Both new host-side reads were hard-coded to `/mnt/fast/stacks`, which meant their violation branches could only be driven by committing a deliberate footgun — or a not-yet-present file — to the deployed checkout. `DRIFT_REPO_ROOT` and `D04_REPO_ROOT` follow the `DASH_HOST`/`EXTCONF_HOST` contract exactly: any non-default value forces `EXIT_CODE=1` whatever the block then measures, so neither can launder a red run green. An undriveable branch is an unproven branch.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Three of the plan's automated verify predicates are unsatisfiable as written**

- **Found during:** Tasks 1 and 2, while running the plan's own `<verify><automated>` blocks.
- **Issue:** (a) Task 1 asserts `grep -qE "expected=1|== \"1\""` must NOT match the comment-stripped script — but the **beets-databases** assertion legitimately reads `expected=1 at $SURVIVOR_DB` and `== "1"`, so the predicate can only be satisfied by breaking a correct, unrelated assertion. (b) Task 1 asserts `grep -q "beets-flask|beets|wrtag|soulbeet|picard"` against `beets.md`, but that quote lives in a **markdown table** where the pipes are escaped as `\|`, so the literal substring does not occur — the predicate already failed before this plan. (c) Task 2's `timeout $REMOTE_TIMEOUT.*|` invariant filters with `grep -v pipefail | grep -v "grep -q"`, which leaves three **pre-existing** lines standing (`:889`'s `|| echo`, and `:1194`/`:1195`, whose pipes sit inside a command string already headed by `set -o pipefail`).
- **Fix:** ran the narrowed, correct forms — `tagger definitions: expected=1` for (a), and the real string-level pipefail rule for (c) — and satisfied (b) *properly* by quoting the pattern in a **fenced code block** in the new `beets.md` § *Phase 6 → D-11*, where pipes need no escaping. `grep -c` for the unescaped pattern in `beets.md` now returns 1 where it returned 0 before.
- **Files modified:** `stacks/selfhosted/arrs/beets.md`
- **Commit:** 40e7d7b

**2. [Rule 2 — Missing critical functionality] `docker compose config` silently renders `services: {}` for the dormant arm**

- **Found during:** Task 2, writing the D-03 block.
- **Issue:** `docker compose -f stacks/selfhosted/arrs/beets/beets.yaml config` prints `name: beets` / `services: {}` on this estate, because the service sits behind `profiles: ["manual"]`. A matcher fed that output finds no bad mounts and reports green **on nothing at all** — the row-22 empty-inspect shape in a new costume.
- **Fix:** the block passes `--profile manual` (an overridable, force-red constant) and treats a render with **zero bind mounts** as UNKNOWN, naming the missing profile as the likely cause.
- **Files modified:** `scripts/quick-health-check.sh`
- **Commit:** e9a7a52

**3. [Rule 2 — Missing critical functionality] `read_only:` is emitted only when true**

- **Found during:** Task 2, against the real rendered output.
- **Issue:** the long-form `volumes:` renderer omits `read_only:` entirely for a read-write mount, so a normaliser that looks for `read_only: false` finds nothing and could default a mount to "ro".
- **Fix:** the normaliser defaults every mount to `rw` and only upgrades to `ro` on an explicit `read_only: true` — the fail-closed direction, stated in the comment.
- **Files modified:** `scripts/quick-health-check.sh`
- **Commit:** e9a7a52

**4. [Rule 3 — Blocking] Two new red branches were undriveable**

- **Found during:** Task 3, attempting the plan's required perturbation controls.
- **Issue:** both new host-side reads hard-coded `/mnt/fast/stacks`, so `DRIFT_EXPECT_FLASK_CONFIG` was unreachable (the block short-circuits at exit 4 before the comparison) and D-04's violation branch could only be driven by committing a footgun to the deployed tree.
- **Fix:** added `DRIFT_REPO_ROOT` and `D04_REPO_ROOT` with the force-red contract, then drove five controls through the real script against a scratch checkout.
- **Files modified:** `scripts/quick-health-check.sh`
- **Commit:** cd0f0c6

**5. [Rule 1 — Bug] A literal `|` inside the D-04 remote regex tripped the file's own greppable invariant**

- **Found during:** Task 2, re-running `grep -n 'timeout $REMOTE_TIMEOUT.*|'`.
- **Issue:** the natural pattern `(^|[^A-Za-z0-9_./-])beet[[:space:]]` puts a pipe in the command string, and that invariant matches per **line** — so a pipe inside a regex reads to it exactly like an unguarded shell pipeline, adding a fourth false positive to an invariant only worth having while it is clean.
- **Fix:** switched the remote pattern to `git grep -w beet`, which carries no pipe. Measured equivalent, not assumed: 37 raw hits against the alternation's 30, with an **identical** invocation-shaped set.
- **Files modified:** `scripts/quick-health-check.sh`
- **Commit:** e9a7a52

### Scope notes

- The plan expected the census half to be discharged **by construction** ("not by a firing observation"). It was discharged by **two firing observations** instead — controls G and H, driven through the real script against a scratch checkout, mutating nothing outside it. The plan was right that `SURVIVOR_DB`/`APPDATA_ROOT`-style constants cannot be overridden; it did not anticipate that the *tree* could be varied instead.
- `beets.md` was edited in **both** task 1 and task 2's commits. Task 2's edit (the two ⛔ DO-NOT-RUN notes) is inside the plan's declared file set and is the correct resolution of the D-04 scope question, so it was not deferred.

## Verification

| Check | Result |
|---|---|
| `bash -n` both scripts | pass |
| `shellcheck -S error` both scripts | pass |
| six cross-file label tokens present | all six |
| `TAGGER_DEFS="UNKNOWN"` sentinel retained | yes |
| census pattern byte-identical to Phase 4's | yes (`beets-flask\|beets\|wrtag\|soulbeet\|picard`) |
| `beets.md` quotes the same pattern unescaped | yes, in a fenced block |
| `DRIFT_LINES -ne 4`, old `-ne 3` gone | yes |
| green line names four files | yes |
| live census result | `✅ tagger definitions: expected=2 — found exactly the named pair` |
| D-03 live result | `✅ one config, both containers: … :ro`, `/mnt/tank/media :ro` on both |
| D-04 live result | `✅ 0 executable invocations`, raw=37 / stripped=17 / invocation-shaped=2 |
| `git diff --stat` vs base | 3 source files + 2 planning files |
| working tree vs HEAD after controls | empty — no test debris |

**Perturbation controls, all driven through the real scripts** (full transcripts in `artifacts/06-10-harness-run.txt`):

| # | Control | Result |
|---|---|---|
| A | `DRIFT_REPO_ROOT` → scratch checkout | four comparison lines, no short-answer UNKNOWN |
| B | `DRIFT_EXPECT_FLASK_CONFIG` = wrong hash | exactly one ❌ naming `flask-config.yaml`; other three green; repo hash == host hash |
| C | `D03_BEETS_CONFIG_SOURCE` = unmounted path | both halves ❌, both naming the mount |
| D | `D03_FLASK_CONTAINER` = nonexistent | UNKNOWN, "an empty inspect must never satisfy a zero-test" |
| E | bare `beet import …` in scratch tree | ❌ naming file, line and text |
| F | same line with `-l` and `-c` | no ❌ — discriminates on the flags, not the word |
| G | third definition (`mikenye/picard:latest`) | ❌ `found 3`, pattern still catches a registry-namespaced tagger |
| H | two definitions, `flask.yaml` renamed | ❌ `found 2` — membership, not count |
| I | scratch restored, re-run | census green; sha256 of `check-music-freeze.sh` identical |

Pre/post sha256: `check-music-freeze.sh` and `beets.md` **identical**. `quick-health-check.sh` changed by the intentional commit cd0f0c6 only; `git diff HEAD --stat` is empty.

## Known Reds

**New, correct, and clearable — the vendored-drift block reports UNKNOWN.** The comparison reads its repo half host-side with `git show HEAD:<path>` inside `/mnt/fast/stacks`, which is at `c67d497`: Phase 6 is merged locally and **unpushed**, so `flask-config.yaml` is genuinely absent from the host's HEAD and `git show` exits 4. The block reports UNKNOWN rather than a match — fail-closed, and the block's own doctrine ("the host runs what the host has"). **Clears on push + `git pull --ff-only` on LXC 100.** The file itself is *not* drifted: control B shows repo and host hashes matching at `949bd1f3…`. Named in the tenth EXIT-CODE notice so the next reader meets the reason rather than the symptom.

**Pre-existing, not this phase's.** `interpolated-host-path inventory MOVED: expected=12, found=13` in `check-music-freeze.sh` §2 — the Phase 5 open item, the only failed assertion in the census run, and the reason both scripts' exit codes are non-discriminating. Verified not caused by Phase 6: none of the 13 interpolated lines is under `stacks/selfhosted/arrs/beets/`.

**Measured side-notes.** `tagger-capable containers` moved 2 → 3 (beets-flask joins sabnzbd and lidarr); reported, not asserted, and `rw on Music, tagger-capable` is still 0.

## Deferred

`DEF-06-10-01` — `timeout 120` on the freeze fold-in does not bound the **inner** ssh that `check-music-freeze.sh` opens to atlantis for its zfs queries, so the outer ssh can hang indefinitely. Observed once (control F). Same family as the documented CR-03 "the bound does not bind through a pipe", different mechanism. Recorded in `deferred-items.md`; not fixed, because changing the health entry point's bounding semantics is a separate decision with its own controls.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change. Both new blocks are read-only: `docker inspect`, `docker compose config`, `git grep` and `sha256sum`. Nothing was installed. Every new override can only make a block redder.
