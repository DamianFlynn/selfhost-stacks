---
phase: 03-tagger-spike
plan: 10
subsystem: axis-two-ergonomics
tags: [beets-flask, rc6, checkpoint, criterion-7, criterion-8, TAGR-06, D-09, D-10, D-11, OD-2, T3, A4]
status: COMPLETE — 3 of 3 tasks; the operator ran the trial and criteria 7/8 are recorded, T3 left open by design
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
  - ".planning/phases/03-tagger-spike/03-ERGONOMICS-SHEET.md — ten rows recorded from the operator's trial, the criterion 8 verdict, and AMENDMENT B stating exactly which cells were never measured"
  - "03-DECISION.md criteria 7/8 result cells filled; criterion 4's beets-flask row CONFIRMED AND BOUNDED; T3 recorded PARTIAL / NOT ANSWERED"
  - "DEF-03-11 through DEF-03-19"
affects:
  - "03-11 — axis two can now be closed against measured evidence, but T3 must first be obtained from the operator in their own words; teardown must never pass --remove-orphans"
  - "03-11 — must settle the 151-vs-144 denominator (DEF-03-18) and stop asserting `zfs diff` returns clean (DEF-03-19)"
  - "CLAUDE.md / PROJECT.md — the standing constraint 'beets has no undo command' is narrower than it reads: beets-flask rc6 has a working, verified UNDO IMPORT. 03-11 should pick this up"
  - "Phase 6/7 — an import gate must assert source audio count == imported item count (DEF-03-14); no loss-detecting gate can see a correct-shaped wrong value"
  - "Phase 9 — the laggy-past-some-hundred-folders limit against the 144-folder backlog, still NOT EXERCISED after the trial"
  - "criterion 4 — the bootleg row now says what bootleg does to untagged content, measured twice with opposite outcomes"
  - "Phase 4 research — mastermixdj.com is canonical for ~76% of the backlog in plain HTML (DEF-03-17), which may displace both the Discogs path and the planned VLM cover-scan extraction for Mastermix content"
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
  - "wall_clock_s and interventions recorded as `not measured` on 9 of 10 rows rather than estimated. A fabricated ergonomics figure is undetectable afterwards and would defeat the sheet's purpose"
  - "The bootleg run's tool-reported 39 s was deliberately NOT entered in wall_clock_s — it is an import duration, a different quantity from the sheet's operator-wall-clock rule"
  - "The four unrun terminal rows read `not run`, deliberately outside the permitted outcome set, because they are rows that never happened rather than measurements with a missing value"
  - "The operator's out-of-set outcome value `tagged` was reconciled to `imported` VISIBLY, keeping the original word because it is itself an ergonomics observation"
  - "The criterion 8 verdict is labelled scribe-assembled and carries four confidence boundaries; T3 is recorded NOT ANSWERED rather than written in the operator's voice"
  - "Nothing was torn down and no source folder was deleted; DELETE IMPORTED FOLDERS was never pressed or scripted"
metrics:
  tasks_completed: 3
  tasks_total: 3
  commits: 9
---

# Phase 3 Plan 10: Axis Two — The Front End Summary

**beets-flask rc6 deployed, evaluated by name against all eight known frictions plus a ninth found
here, the `bootleg` inbox exercised and bounded — and the timed trial staged to a one-command start
and handed to the operator, because D-09 says the measurement is theirs.**

## Status: 3 of 3 tasks complete

| Task | Type | Status |
|---|---|---|
| 1 — Operator acknowledges the release-candidate risk | `checkpoint:decision`, blocking | **COMPLETE** — answered `deploy-rc6`, recorded verbatim and dated, provably pre-deployment |
| 2 — Deploy the throwaway instance, check the 8 frictions | `auto` | **COMPLETE** |
| 3 — The operator runs the timed trial personally | `checkpoint:human-action`, blocking | **COMPLETE** — the operator ran it and declared it complete; the executor recorded it as scribe |

Task 3 was not agent-executable and was **not simulated**. The measurement *is* the operator's
wall-clock, intervention count and annoyance; an agent driving the front ends would produce numbers
that answer a different question, in a phase whose entire purpose is that this pipeline was built
three times on unverified assumptions. **The executor's role on close was scribe, not instrument**
— and where the operator did not take a number, the cell says so.

## Task 3: what the trial returned

**The trial was decided by a defect, not by a stopwatch.** That shapes everything below.

### The counters the sheet was built for were largely not collected

| Cell | Rows filled | Recorded as |
|---|---|---|
| `wall_clock_s` | **1 of 10** (`clean-1`/terminal, **30 s**) | `not measured` elsewhere, with the reason |
| `interventions` | **1 of 10** (`clean-1`/terminal, **1**) | `not measured` elsewhere |
| `context_switches` | **1 of 10** (`clean-1`/terminal, **1**) | `not measured` elsewhere |
| `outcome` | **10 of 10** | 6 × `imported`, 4 × `not run` |
| `stuck_points` | **10 of 10** | 1 operator verbatim; 9 verified observations, labelled as such |

**Four of the five terminal rows read `not run`** — an operator decision taken once the flask arm's
behaviour made the comparison decisive. `not run` is deliberately **outside** the permitted
`outcome` set: those rows are not measurements with a missing value, they are rows that never
happened, and collapsing them into `skipped` or `abandoned` would misreport a decision not to
measure as a measured outcome.

**What that costs, stated plainly:** the sheet is 1 of 5 albums on the terminal arm and 5 of 5 on
the flask arm, so **no paired cross-arm comparison exists on four of five albums** and **no
wall-clock or intervention-count claim is available at all.** The ordering control was only
*exercised* on `clean-1`; on the other four the flask arm ran with no prior pass, so it took no
second-pass advantage there.

The one timing that does exist — the `bootleg` run's self-reported *"Imported 39 seconds ago"* —
was deliberately **not** entered in `wall_clock_s`. It is a tool-reported import duration, a
different quantity from the sheet's rule (*"start the clock when the operator first looks at the
album"*), and entering it would have redefined the measurement to fit the number available.

### Three findings decided axis two, each re-verified on disk at close

**1. The interactive picker cannot be relied on to import — DEF-03-13.**
Intermittent full-page `TypeError` / *"Load failed"*, reproduced on **2 albums across 2 browsers**.
**The backend logged zero errors** across the container's whole lifetime. Root-caused, not inferred:
rc6 does not proxy cover-art bytes — it redirects the browser out to `coverartarchive.org`, which
the page at `127.0.0.1:5002` then `fetch()`es and is **CORS-blocked**. Confirmed by asymmetry: the
same endpoint called *inside* the container returns HTTP 200 / 3516 bytes. **There is no error
boundary around a cosmetic thumbnail**, so it takes down the entire import page. Intermittent is
the worse finding — the operator cannot tell in advance whether a run is safe. Their one verbatim:

> **"this is what i see if i move fast"**

**2. A 75% match imported silently and catastrophically wrong — DEF-03-14.**
`hard-flat-multidisc`: **31 source files → 22 imported, 9 audio files silently dropped**, and
**4 tracks written onto entirely different songs.** Re-verified independently at close: the four
titles beets wrote exist **nowhere** in the source folder, and their durations (245 / 238 / 244 /
231 s) identify four *different* source tracks — the last, `Fashion of His Love (Fernando Garibay
remix)`, is really `You And I (Wild Beasts Remix)`, a different song. The wrong names are in the
files' `title` tags, not just the paths.

**On that same screen the UI asserted *"All tracks on disk found online"* AND *"All tracks online
present on disk"*. Both false.** An interface that makes a falsifiable safety claim and gets it
wrong is worse than one that says nothing.

**Bounded, not endemic** — re-verified: Taylor Swift 21→21, Garth Brooks 10→10, Now 116 47→47,
**zero dropped**. The cause is the folder shape (two releases flattened into one directory), which
is exactly why `hard-flat-multidisc` was in the D-10 draw. **This is DEF-03-08's confident wrong
match one level down, and worse: 17 of 22 tracks are perfect, so nothing looks amiss.**

**3. `bootleg` on a well-tagged DJ folder is the best result either arm produced — DEF-03-16.**
On `Crate.068-070`, which 03-07 measured at **zero** strict Discogs candidates: one `mv`, zero
candidate decisions, **3 correct albums × 20 files**. Re-verified at close via mutagen in-container:
`APIC` **60/60**, `TBPM` **60/60**, `TALB` **60/60**, `TCON` **60/60** correct per crate, source
intact at 60 (`COPY`). **But `TRCK` 0/60** — no track tag at all, so playback order is undefined.

**And the same button shredded `Crate.071` into twenty single-track albums** in Task 2, purely
because that folder's `album` tag was empty — **with no UI signal distinguishing the cases before
the operator commits.** Since **~40% of sampled Mastermix folders carry the bare, useless
`album=Mastermix`**, the Crate 068–070 success is **not representative** of the backlog.

### Two capabilities worth carrying forward

- **`UNDO IMPORT` works** — verified reversal (destination gone, flask library 0 entries, source
  intact at 31 files). This **contradicts a standing project constraint**: `CLAUDE.md` and
  `PROJECT.md` both record *"beets has no `undo` command — verified against the live CLI"*, which is
  why Phase 1 had to pair `library.db` backups with ZFS snapshots. The constraint stays true of the
  **beets CLI** it was measured against, so it is **narrower than it reads**, not falsified. Left
  for 03-11 rather than edited into shared docs (D-03). **The most useful thing the trial found.**
- **Per-folder persistent `Tagged`/`Imported` badges** — exactly the resume signal a 144-folder bulk
  run needs, the abandoned-halfway mode this project exists to prevent. **But** Lady Gaga was badged
  `Imported` while 9 files short and 4 tracks wrong, and **`DELETE IMPORTED FOLDERS` is keyed on
  that badge** (DEF-03-15). It was never pressed.

### A reframing of T1 — and explicitly not a change to it

The operator identified that **`mastermixdj.com` is canonical for the publisher-branded majority of
the backlog**: a plain HTML table with per-track number, artist, title, version, **BPM** and
duration, where every BPM matches the embedded `TBPM` and every duration matches disk within ~1 s,
and the stated running time (1:09:43) sits **one second** from what beets-flask computed off the
files. **115 of 151 backlog folders (~76%) are DJ-service branded.**

**T1 fired at 27.08% measuring the *Discogs* strict match rate against that population.** T1's
threshold value, definition, estimator and 144-folder denominator are **unaltered**; what changes
is only the reading — **Discogs was substantially the wrong instrument for the majority of the
backlog.** Recorded as a dated amendment and as DEF-03-17. Not over-claimed: **one** page was
checked, coverage is unproven, it is a commercial site, and the likely join key is the folder name,
which none of the three taggers parses.

### Criterion 8, and why T3 is left open

The criterion 8 verdict is written and **explicitly labelled scribe-assembled from verified
observations**, quoting the operator's one contemporaneous verbatim. It carries four stated
confidence boundaries: not a wall-clock finding; **not evidence about the 144-folder case** —
friction 5 stays `NOT EXERCISED`, as recorded before any score existed; not a finding about the
beets *engine* (different versions per OD-2, and the mis-match is candidate behaviour the front end
then *misdescribed*); and not a paired comparison.

**T3 is recorded `PARTIAL` / `NOT ANSWERED`, not inferred.** T3's named instrument is *an explicit
written self-assessment in the operator's own words*. The terminal arm ran on **one** happy-path
album and no such sentence exists. Writing one in the operator's voice would fabricate the exact
instrument the threshold specifies. What the trial does establish is narrower: **the operator's
tolerance was exhausted by defects, not by the prompt.** **03-11 must obtain the sentence.**

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

**Staging (before the trial): only the ten `TBD` `album` cells were filled**, which Task 3's action
directs to happen before the trial starts.

**Close (after the trial): only the ten rows' measurement cells and the criterion 8 placeholder.**
`git diff` on the close commit shows **12 deletions** and every one is accounted for: the 10 table
rows (each replaced in place) and the 2-line verdict placeholder. **The rubric was not reshaped.**

Asserted rather than claimed:

| Assertion | Result |
|---|---|
| Everything above § *The sheet* vs threshold commit `137b6d9e` | **BYTE-IDENTICAL, 74 lines** |
| `went_first` alternation and slot/arm ordering vs `137b6d9e` | **identical, all ten rows** |
| Permitted-`outcome` line, wall-clock rule, ordering-control line | present **verbatim** |
| AMENDMENT A and the `TBD` provenance paragraph | left **verbatim**, not rewritten |
| `03-DECISION.md` T1/T2/T3 threshold, falsifiable-form and instrument cells vs `137b6d9e` | **BYTE-IDENTICAL** |
| `03-DECISION.md` deletions this session | **8 lines, all `PENDING` result cells or the T3 row replaced in place** |
| `deferred-items.md` deletions | **zero** — pure 293-line append |

Everything new went into clearly-marked, dated sections: `## AMENDMENT B — 2026-09-04` in the sheet
and `## AMENDMENT — 2026-09-04, plan 03-10` in the decision record.

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

## Estate safety at close — re-verified, not assumed

| Assertion | Instrument | Result |
|---|---|---|
| All five trial sources intact | `find` per folder on LXC 100 | **169 audio files / 5 folders** — 60 + 31 + 47 + 21 + 10, matching the pre-trial stamp exactly |
| The runs copied, did not move | the above | every source at its original count; `dj-no-match` moved *between inboxes* by design, not consumed |
| Music freeze | `check-music-freeze.sh` **on LXC 100** | exit **0**, `tagger-class writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` — and `consumer-class writers: 1` (Jellyfin, D-21), which is what confirms it was a **sighted** run rather than DEF-03-11's blind green |
| Music tree untouched by the trial | `find … -newermt/-newerct '2026-09-04 09:00'` from atlantis | **0 / 0** |
| Real backlog untouched | `find /mnt/tank/downloads/complete/nzb -newermt …` | **0 files** |
| `/` headroom (OD-1 floor 8 GiB) | `df -h /` | **34 G free of 126 G (72%)** |
| Nothing torn down | — | `beets-spike`, `beets-flask-spike`, `bf-clean`, `bf-inbox`, spike trees and snapshots all left in place for 03-11 |

**One acceptance criterion could not be met, and the reason is not this trial.** The plan requires
*"`zfs diff tank/media/Music@pre-project` returns clean"*. It returns **2,674 lines, all `M`, zero
`+`/`-`/`R`** — against a tree of exactly **2,674** entries, i.e. the whole tree. That is Phase 1
plan 01-08's chown signature against a 2026-08-18 snapshot, and **it has been non-clean since
then**. The assertion it was reaching for holds on a better instrument (the mtime/ctime rows above).
Logged as **DEF-03-19** with a suggested rewording, rather than quietly reported as a pass.

## Deferred

Pre-existing from tasks 1–2:

- **DEF-03-11** — `check-music-freeze.sh` prints a green § 7 summary when run somewhere it cannot
  see the estate. **Used at close:** the LXC 100 run's `consumer-class writers: 1` is what proves
  the run was sighted.
- **DEF-03-12** — the two spike compose files shared a project; fixed for the flask file, and
  plan 03-11 must never pass `--remove-orphans` to either.

New from task 3:

- **DEF-03-13** — rc6's import page has **no error boundary** around a CORS-blocked third-party
  cover-art fetch. Intermittent full-page crash; backend logs nothing. **Blocks reliance on the
  picker.**
- **DEF-03-14** — a 75% match **dropped 9 of 31 files and mis-tagged 4 tracks onto different
  songs** while the UI asserted nothing was missing. Needs a `source count == imported count` gate
  in Phase 6/7.
- **DEF-03-15** — `DELETE IMPORTED FOLDERS` is keyed on a badge that read `Imported` on that same
  folder; `IMPORT BEST` is the same shape against a 1-in-6 wrong-match rate.
- **DEF-03-16** — `bootleg`'s outcome turns entirely on whether `album` is populated, with **no UI
  signal**; ~40% of sampled Mastermix folders carry the bare `album=Mastermix`.
- **DEF-03-17** — `mastermixdj.com` is canonical for **~76%** of the backlog, in plain HTML, with
  BPM and durations matching disk to ~1 s. Reframes what T1's number means without changing it.
- **DEF-03-18** — two denominators now circulate, **151** and **144**. 03-11 should settle it.
- **DEF-03-19** — `zfs diff` on the Music snapshot **cannot** return clean; three plans assert it
  does.

## Known Stubs

**None.** `03-ERGONOMICS-SHEET.md`'s measurement cells were Task 3's output and are now recorded —
either with the operator's number or with an explicit `not measured` / `not run` and its reason.
`not measured` is **not a stub to be wired**: it is the honest record of a measurement that was not
taken, and filling those cells with anything an agent produced would have been the single worst
outcome available to this plan.

Two values are deliberately left open and are **not** stubs either:

- **T3** — `NOT ANSWERED`, because its named instrument is the operator's own written sentence.
  **03-11 must obtain it.**
- **The criterion 8 closing paragraph** — written, but labelled scribe-assembled and awaiting the
  operator's countersignature or replacement.

## Handoff to plan 03-11

1. **Obtain T3 from the operator in their own words** before closing axis two. Everything else in
   axis two is now measured; this is the one gap.
2. **Countersign or replace** the criterion 8 closing paragraph.
3. **Settle the denominator** — 151 or 144, with the path set and dedup rule stated (DEF-03-18).
4. **Stop asserting `zfs diff` returns clean** (DEF-03-19); use zero `+`/`-`/`R`, or the
   mtime/ctime window.
5. **Pick up the `UNDO IMPORT` finding** — `CLAUDE.md`'s *"beets has no `undo` command"* is
   narrower than it reads.
6. **Teardown:** never pass `--remove-orphans` to either spike compose file (DEF-03-12). Nothing
   was torn down here; `beets-spike`, `beets-flask-spike`, `bf-clean`, `bf-inbox`, the spike trees
   and the snapshots are all still in place. **One album's only intact copy of 9 dropped tracks
   lives in the trial sources** — do not delete them without reading DEF-03-14 first.
7. **Standing action, carried not closed:** the Discogs token rotation is deferred to project close
   by explicit operator decision. This phase leaked it to disk twice; it did not happen a third
   time here.

## Commits

| Hash | Message |
|---|---|
| `497361c` | `docs(03-10): draft the beets-flask RC acknowledgement, before anything is deployed` |
| `49f530e` | `docs(03-10): record the operator's verbatim RC approval, asserted pre-deployment` |
| `28a33c0` | `feat(03-10): adopt the throwaway beets-flask rc6 compose, loopback-bound and Music-free` |
| `503041c` | `feat(03-10): deploy beets-flask rc6 and check all eight frictions against observation` |
| `aa95a32` | `feat(03-10): stage the axis-two trial to a one-command operator start` |
| `8053275` | `docs(03-10): record the halt at the operator's timed ergonomics trial` |
| `6d960f5` | `test(03-10): record the operator's clean-1 terminal-arm measurement` |
| `bea925e` | `test(03-10): record the operator's ergonomics trial and the criterion 8 verdict` |
| `8aa7032` | `docs(03-10): log DEF-03-13..19 from the operator's ergonomics trial` |
| `27ae548` | `docs(03-10): fill criteria 7/8 result cells and leave T3 honestly open` |
| *(this)* | `docs(03-10): close the axis-two plan with the operator's trial recorded` |

## Self-Check: PASSED

Files:
- `03-spike-beets-flask.yaml` — FOUND, line 1 is `# THROWAWAY — DO NOT DEPLOY`
- `03-BEETS-FLASK.md` — FOUND; `## What axis two compares` present, `## The bootleg inbox`
  present, frictions table carries **9** rows with **9** verdicts (7 observed, 2 not exercised)
- `03-ERGONOMICS-SHEET.md` — FOUND; ten rows, **zero blank cells**, every `stuck_points`
  non-empty, `## Criterion 8 — the week-six verdict` filled, `## AMENDMENT B` present
- `03-DECISION.md` — FOUND; criteria 7/8 result cells filled, T3 `PARTIAL` / `NOT ANSWERED`,
  `## AMENDMENT — 2026-09-04, plan 03-10` present
- `deferred-items.md` — FOUND, DEF-03-01 … DEF-03-19 all present
- `03-10-SUMMARY.md` — FOUND

Commits: `497361c`, `49f530e`, `28a33c0`, `503041c`, `aa95a32`, `8053275`, `6d960f5`, `bea925e`,
`8aa7032`, `27ae548` — all FOUND.

Provenance assertions:
- Sheet above § *The sheet* vs `137b6d9e` — **byte-identical, 74 lines**
- `went_first` alternation vs `137b6d9e` — **identical, all ten rows**
- T1/T2/T3 threshold, falsifiable-form and instrument cells vs `137b6d9e` — **byte-identical**
- Sheet deletions at close — **12**, all accounted for (10 rows replaced in place + the 2-line
  verdict placeholder)
- `03-DECISION.md` deletions — **8**, all `PENDING` result cells or the T3 row replaced in place
- `deferred-items.md` deletions — **zero**

Constraints:
- `STATE.md` and `ROADMAP.md` — **not modified** (orchestrator owns them)
- Frozen stack files and `renovate.json5` — **not modified**
- No teardown performed; **no source folder deleted**; `DELETE IMPORTED FOLDERS` never pressed or
  scripted; `--remove-orphans` never passed
- Discogs token — screened by value across every commit and the working tree: **absent**, not even
  its 8-character prefix. Rotation remains deferred to project close by operator decision
- `complete/nzb` — **0 files modified** across the entire session
- **No measurement simulated, estimated, averaged or proxied.** The only operator-authored numbers
  in the sheet are `30` / `1` / `1` on `clean-1`, preserved exactly
