---
phase: 03-tagger-spike
plan: 10
subsystem: axis-two-ergonomics
tags: [beets-flask, rc6, checkpoint, criterion-7, criterion-8, TAGR-06, D-09, D-10, D-11, OD-2, T3, A4]
status: HALTED — blocking checkpoint:human-action, Task 3 of 3 (operator must run the trial)
requires:
  - "03-02 — the empty ergonomics sheet with its counting definitions and alternation fixed before the trial"
  - "03-07 — T1 FIRED at 27.08%, T2 did not fire, and the loose-fail set the fifth album is drawn from"
  - "03-09 — the D-13 verdict, and the instrument lessons this plan's assertions inherit"
  - "03-01 — the metasauce/beets-flask:v2.0.0-rc6 pull and its recorded digest"
provides:
  - ".planning/phases/03-tagger-spike/03-spike-beets-flask.yaml — the throwaway rc6 compose, loopback-bound, Music-free, project-name-isolated"
  - ".planning/phases/03-tagger-spike/03-BEETS-FLASK.md — criterion 7 complete: RC acknowledgement, all eight frictions checked against observation plus a ninth found here, the bootleg finding, the axis-two scope statement, and the trial staging record"
  - "the axis-two scope statement: it compares a policy architecture (preview/auto/bootleg) as well as a front end"
  - "a staged, asserted, one-command-to-start ergonomics trial with the five albums named and reflinked"
  - "DEF-03-11 and DEF-03-12"
affects:
  - "03-11 — axis two and T3 stay PENDING until the operator runs the trial; teardown must never pass --remove-orphans"
  - "Phase 9 — the laggy-past-some-hundred-folders limit against the 144-folder backlog, recorded as a handoff the 5-album trial cannot test"
  - "criterion 4 — the bootleg row must now say what bootleg actually does to untagged content"
tech-stack:
  added:
    - "metasauce/beets-flask:v2.0.0-rc6 (throwaway spike container, loopback-bound, reaped by 03-11)"
    - "beets 2.12.0 + python3-discogs-client 2.9 inside that container, pinned via requirements.txt"
  patterns:
    - "Rendering a credential into a config from the container's own os.environ with umask 077, so it never reaches an argv, a transcript or the repo"
    - "Asserting a bind mount's freshness from INSIDE the container and cross-checking host-side, because the bind pins the inode and a stale mount exits 0 reporting 0 files"
    - "Proving a loopback binding by curling the LAN IP and requiring it to FAIL, not by reading the port map"
    - "Exercising a feature on a substitute folder from the same evidence class, so the operator's own trial is not contaminated into a second pass"
    - "Explicit compose `name:` to stop one spike's teardown reaching another spike's container"
key-files:
  created:
    - .planning/phases/03-tagger-spike/03-spike-beets-flask.yaml
  modified:
    - .planning/phases/03-tagger-spike/03-BEETS-FLASK.md
    - .planning/phases/03-tagger-spike/03-ERGONOMICS-SHEET.md
    - .planning/phases/03-tagger-spike/deferred-items.md
decisions:
  - "beets-flask rc6 rejects beets' canonical space-separated `plugins:` string; written as a YAML list instead. The plugin set is unchanged and was asserted loaded on both arms"
  - "The bootleg inbox was exercised on VA-Mastermix.Crate.071 rather than on the trial's dj-no-match album, so the operator's Task 3 run is not a second pass"
  - "All five trial albums staged into the `preview` inbox, so both arms put the same decision in front of the operator; auto/bootleg reachable by moving a folder"
  - "The trial was NOT run by the agent. D-09 is explicit that the measurement is the operator's own"
metrics:
  tasks_completed: 2
  tasks_total: 3
  commits: 5
---

# Phase 3 Plan 10: Axis Two — The Front End Summary

**beets-flask rc6 deployed, evaluated by name against all eight known frictions plus a ninth found
here, the `bootleg` inbox exercised and bounded — and the timed trial staged to a one-command start
and handed to the operator, because D-09 says the measurement is theirs.**

## Status: 2 of 3 tasks complete, halted at a blocking human-action gate

| Task | Type | Status |
|---|---|---|
| 1 — Operator acknowledges the release-candidate risk | `checkpoint:decision`, blocking | **COMPLETE** — answered `deploy-rc6`, recorded verbatim and dated, provably pre-deployment |
| 2 — Deploy the throwaway instance, check the 8 frictions | `auto` | **COMPLETE** |
| 3 — The operator runs the timed trial personally | `checkpoint:human-action`, blocking | **PREPARED AND HANDED OVER — awaiting the operator** |

Task 3 is not agent-executable and was not simulated. The measurement *is* the operator's
wall-clock, intervention count and annoyance; an agent driving the front ends would produce numbers
that answer a different question, in a phase whose entire purpose is that this pipeline was built
three times on unverified assumptions.

## What was deployed, and what was asserted about it

`metasauce/beets-flask:v2.0.0-rc6`, digest re-verified on the host, running as a throwaway
`profiles: ["manual"]` container that publishes nothing.

| Assertion | Instrument | Result |
|---|---|---|
| OD-2 version split | `beets.__version__` at runtime | **`2.12.0`** — the `requirements.txt` pin held; the startup install touched only the extras |
| Plugins **loaded** | `beet version` → `plugins:` line | `discogs, fromfilename, importsource, musicbrainz` |
| D-20: no rw on Music | `docker inspect .Mounts` | **no `/mnt/tank/media` at any mode** |
| T-03-57: not published | `curl` both ways + `ss -ltn` | `127.0.0.1:5002` → **200**; `172.16.1.159:5002` → **refused**; listener is loopback-only |
| No auth chain needed | `docker inspect .Config.Labels` | **zero** `traefik.*` keys |
| Music freeze, **after** creation | `check-music-freeze.sh` **on LXC 100** | exit **0**, `FAILURES total: 0` |
| A4 — bundled Redis | `redis-cli PING` in-container | **`PONG`** — A4 **confirmed**, no sidecar added |
| T-03-60 — token containment | in-container compare vs live env | token value in **none** of `/api_v1/config`, `/openapi.json` |

**The plugin assertion is `beet version`, never a config dump.** 03-04 measured that `beet config -d`
prints a full `discogs:` block even when the plugin failed to load. That lesson was applied here
rather than restated.

## Two findings the research did not have

### 1. rc6 validates the beets config more strictly than beets does — and degrades quietly

beets' canonical space-separated `plugins:` string is **rejected** by rc6's `eyconf` JSON schema.
The danger is not the error, it is what survived it: **the server still started and served a page**
while `launch_watchdog_worker.py` died — and the watchdog is what makes the inbox folders react.
The three policy-carrying inboxes would have been **inert**, and the trial would have scored a
beets-flask whose central architecture was not running, behind a UI that looked alive.

Same defect class as TAGR-05 and 03-04: **a configuration failure that presents as "nothing is
happening" rather than as a configuration error.** Fixed by writing `plugins:` as a YAML list.

### 2. `bootleg` is real, first-class — and on this content it did the wrong thing

The research called `autotag: "bootleg"` *the single strongest pro-beets-flask finding*. It is
confirmed present in rc6 from primary source (`schema.py:110`), and note that the **shipped example
config never mentions it** — the example alone would have hidden the feature.

Run on a zero-Discogs-candidate DJ folder, with no prompt and no error:

**One 20-track release went in. Twenty single-track albums came out** — `album` empty on all of
them, `albumartist` set to each *track's* artist, `track` `00`, destination
`bf-clean/<track artist>/00 <title>.mp3` with no album directory level at all.

Because `--group-albums` groups on the metadata that is *there*, and that folder has **no album tag
on any file** and twenty distinct artists. This **bounds** rather than retires the finding:
`bootleg` is still an affordance the terminal arm has no equivalent of, but it is **not** a solution
to untagged DJ content — it is a fast path for content already grouped correctly. On V5 (43 of the
144 backlog folders, where `album == artist`) it would group everything under the placeholder: a
different wrong answer, not a right one. Run before normalisation it produces a confidently wrong
library shape silently, which CLAUDE.md § *Autotagging ceiling* names as worse than no match.

PROJECT.md's sequencing — normalise first (the mutagen script, which won D-13 independently), then
import — is what this vindicates.

## What the trial is, and what it deliberately is not

**Axis two is not "terminal versus queue UI".** The flask arm carries a policy architecture —
`preview` / `auto` / `bootleg` over one shared `library.db` — and that was **exercised, not read**:
rc6's watchdog registered all three inboxes at startup. The terminal arm has no equivalent. The
scope statement is now its own `## What axis two compares` section so plan 03-11's verdict cannot be
read more narrowly than the trial supports.

**Two asymmetries were recorded before any number exists**, so they cannot be argued into or out of
the result afterwards:

1. **The flask arm does its lookup before the clock starts** — the watchdog previews on arrival.
   That is a genuine product difference (a queue exists so the work happens before you look), but
   part of any wall-clock advantage will be "it started earlier", not "it is quicker to drive".
2. **The arms run different beets versions** (2.13.1 / 2.12.0, OD-2). Both were asserted to load
   the identical plugin set.

**Friction 5 is recorded `NOT EXERCISED`.** beets-flask's own docs say the UI gets laggy past "some
hundred folders"; the backlog is **144**. A five-album trial structurally cannot test that, and the
record says so — as it already did *before* any score existed. A good five-album score is not
evidence the UI scales.

## The trial, staged and asserted

Five albums, each in its own directory (loose files never trigger — a wontfix, re-confirmed here by
direct probe), reflinked from atlantis into the `preview` inbox:

| Slot | Album | Files |
|---|---|---|
| `clean-1` | Taylor Swift — *1989 (Taylor's Version)* | 21 mp3 |
| `clean-2` | Garth Brooks — *Ropin' The Wind* | 10 flac |
| `hard-va-compilation` | *Now That's What I Call Music 116* | 47 mp3 |
| `hard-flat-multidisc` | Lady Gaga — *Born This Way: The Collection* | 31 flac |
| `dj-no-match` | *Mastermix Crate 068–070* (2025) | 60 mp3 |

The fifth is `03-DISCOGS-EVIDENCE.md` **case C** — zero Discogs candidates on the probe **and** on
an independent hand-transcribed `beet import -t`, agreeing on all ten properties. Chosen **after**
criterion 1 ran, per D-10, so the trial's difficulty was measured rather than selected.

**Mount freshness was cross-checked host-side and from inside both containers** — 5 folders / 169
audio files on every reading — because the bind pins the directory inode and a stale mount makes
every command exit 0 reporting 0 files. An ergonomics trial over an empty tree would look like a
fast, clean run.

A stamp file was taken so *"the runs copied rather than moved"* is assertable afterwards. The SSH
tunnel was tested end-to-end (HTTP 200). Both arms were confirmed to see the same five albums.

## The sheet: what was and was not touched

**Only the ten `TBD` `album` cells were filled**, which Task 3's action directs to happen before the
trial starts. `git diff` shows ten deletions and every one is a `TBD` placeholder.

Unchanged since the 03-02 commit: the intervention and context-switch definitions, the wall-clock
rule, the permitted `outcome` values, the ordering control and the pre-assigned `went_first`
alternation. Every measurement cell is still empty. The paragraph describing the cells as reading
`TBD` was **left verbatim rather than rewritten**, because it is the provenance record of what the
sheet looked like before the albums were chosen. Everything new went into a clearly-marked
`## AMENDMENT 2026-09-04` below the table.

`03-DECISION.md` was **not modified**. T3 stays `PENDING` until the operator's own self-assessment
exists to quote.

## Deviations from Plan

### Auto-fixed

**1. [Rule 1 — Bug] `plugins:` as a space-separated string breaks rc6 at startup**
- **Found during:** Task 2, first container start
- **Issue:** `eyconf` rejected beets' canonical form; `launch_watchdog_worker.py` died while the
  server kept serving, leaving the three inboxes inert behind a live-looking UI
- **Fix:** written as a YAML list; plugin set unchanged and asserted loaded
- **Commit:** `503041c`

**2. [Rule 2 — Missing safety] Explicit compose project name**
- **Found during:** Task 2, first `up`
- **Issue:** Both spike compose files run from `/mnt/fast/spike-03` and shared the project
  `spike-03`. Compose warned about orphan container `beets-spike` — **the terminal arm** — and
  offered `--remove-orphans`, a flag that would have deleted half the experiment
- **Fix:** `name: spike-03-beets-flask`; verified the warning is gone and `beets-spike` survived
- **Commit:** `503041c`. Hazard logged as **DEF-03-12**

**3. [Rule 2 — Missing safety] `gui.terminal.start_path` overridden**
- **Issue:** The shipped default is `/music/inbox`, which does not exist here. Rather than mount a
  `/music` to satisfy a default, the config points it at the bf-inbox path — otherwise a web
  terminal opening on a missing directory would have been recorded as a beets-flask friction when
  it is a config defaulting artefact

### Deliberate departures, recorded rather than silent

**4. The `bootleg` observation used a substitute folder.** Task 2 asks what `bootleg` did "on the DJ
folder"; running it on the trial's `dj-no-match` album would have made the operator's Task 3 run a
**second pass** over an album already in the library — defeating the ordering control before they
sat down. `VA-Mastermix.Crate.071` was used instead: same evidence class (both are zero-candidate
folders, cases B and C in `03-DISCOGS-EVIDENCE.md`). The library was reset to empty afterwards.

**5. The Discogs token is rendered, not templated.** The committed artefact is a **token-free
template**; the live `/config/beets/config.yaml` is written at mode 0600 by a script that reads
`os.environ` inside the container and prints only a redacted confirmation. This phase has written
the token to disk twice already; it did not happen a third time. The plan's diff was screened
against the live token value — **absent**.

**6. `check-music-freeze.sh` was re-run on LXC 100** after the workstation run reported green
counters while blind. See **DEF-03-11**.

## Deferred

- **DEF-03-11** — `check-music-freeze.sh` prints a green § 7 summary when run somewhere it cannot
  see the estate. It fails closed on the fence, but the summary block a future plan would copy
  carries no "could not look" signal.
- **DEF-03-12** — the two spike compose files shared a project; fixed for the flask file, and
  plan 03-11 must never pass `--remove-orphans` to either.

## Known Stubs

`03-ERGONOMICS-SHEET.md`'s ten measurement rows and its criterion 8 verdict are **intentionally
empty** and are Task 3's output. They are not stubs to be wired — they are the operator's
measurement, and filling them with anything an agent produced would be the single worst outcome
available to this plan.

## Resuming

The operator runs the trial (instructions are in the sheet's amendment; both arms are live and one
command each). On return, the remaining executor work is small and mechanical: verify the sheet has
no blanks and every `stuck_points` is non-empty, confirm `went_first` still matches the 03-02
commit, copy the T3 self-assessment into `03-DECISION.md`'s T3 row, and run the closing assertions
(`check-music-freeze.sh` exit 0, the five source folders still present against
`.trial-stamp-t0.txt`, `zfs diff` on Music from atlantis).

Nothing needs undoing. The container is throwaway and reaped by 03-11; the trial sources are
reflinked copies; `complete/nzb` had **0 files modified** across the entire session.

## Commits

| Hash | Message |
|---|---|
| `497361c` | `docs(03-10): draft the beets-flask RC acknowledgement, before anything is deployed` |
| `49f530e` | `docs(03-10): record the operator's verbatim RC approval, asserted pre-deployment` |
| `28a33c0` | `feat(03-10): adopt the throwaway beets-flask rc6 compose, loopback-bound and Music-free` |
| `503041c` | `feat(03-10): deploy beets-flask rc6 and check all eight frictions against observation` |
| `aa95a32` | `feat(03-10): stage the axis-two trial to a one-command operator start` |
| *(this)* | `docs(03-10): record the halt at the operator's timed ergonomics trial` |

## Self-Check: PASSED

Files:
- `03-spike-beets-flask.yaml` — FOUND, line 1 is `# THROWAWAY — DO NOT DEPLOY`
- `03-BEETS-FLASK.md` — FOUND; `## What axis two compares` present, `## The bootleg inbox`
  present, frictions table carries **9** rows with **9** verdicts (7 observed, 2 not exercised)
- `03-ERGONOMICS-SHEET.md` — FOUND; ten rows present, all measurement cells still empty
- `deferred-items.md` — FOUND, DEF-03-11 and DEF-03-12 appended
- `03-10-SUMMARY.md` — FOUND

Commits: `497361c`, `49f530e`, `28a33c0`, `503041c`, `aa95a32` — all FOUND.

Constraints:
- `STATE.md` and `ROADMAP.md` — **not modified** by this plan (orchestrator owns them)
- `03-DECISION.md` — **not modified**; T3 stays `PENDING`
- Frozen stack files and `renovate.json5` — **not modified**
- Discogs token — screened against the live value across all five commits and the working tree:
  **absent**, and not even its 8-character prefix appears
- `complete/nzb` — **0 files modified** across the entire session
