---
phase: 03-tagger-spike
plan: 11
subsystem: music-tagging
tags: [decision-record, teardown, thresholds, ergonomics, credential-hygiene]
status: COMPLETE — all three tasks done; the operator gate returned "decision stands" and Phase 3 is closed
requires:
  - 03-07-SUMMARY.md (T1, T2, criteria 1 and 2)
  - 03-08-SUMMARY.md (criterion 3, wrtag disqualified)
  - 03-09-SUMMARY.md (D-13, the normalisation bake-off)
  - 03-10-SUMMARY.md (criteria 7 and 8, the ergonomics trial)
provides:
  - The completed two-axis decision record with T1/T2/T3 all resolved
  - Criterion 4 answered with a five-step named mechanism for DJ-service content
  - A torn-down estate — no spike container, no scratch tree, no credential copy
  - The operator's verbatim confirmation, closing Phase 3
  - A four-cause standing rotation action with a reaffirmed project-close timing
  - Handoffs to Phases 4, 5, 6, 7 and 9
affects:
  - Phase 4 (deletes the loser; owns the four falsified claims and the WAV defect)
  - Phase 5 (inherits the confirmed one-library.db-across-N-inboxes structure)
  - Phase 6 (configures the winner; owns proving the albumtype:dj path routing)
  - Phase 7 (undo now has two candidate mechanisms; DUPE-01 needs a decision first)
  - Phase 9 (inherits the untested 144-folder lag risk)
tech-stack:
  added: []
  patterns:
    - "Pass a secret to a sweep via `grep -f <(printf '%s' \"$TOK\")` — printf is a bash builtin, so the value never enters any process argv"
    - "Bound an unviable full-content sweep by containment (what the process could reach) rather than by scanning"
    - "Answer an unsatisfiable closing assertion with a substitute instrument that measures its intent, and log the defect"
key-files:
  created:
    - .planning/phases/03-tagger-spike/03-11-SUMMARY.md
  modified:
    - .planning/phases/03-tagger-spike/03-DECISION.md
    - .planning/phases/03-tagger-spike/deferred-items.md
    - .planning/phases/03-tagger-spike/03-spike-beets.yaml
    - .planning/phases/03-tagger-spike/03-spike-beets-config.yaml
    - .planning/phases/03-tagger-spike/03-spike-beets-flask.yaml
    - stacks/selfhosted/arrs/beets.md
decisions:
  - "Axis one: the engine is beets 2.13.1, decided by wrtag having no non-MusicBrainz metadata source"
  - "Axis two: the front end is beets-flask's policy-carrying inboxes, explicitly NOT its interactive picker"
  - "T3 FIRED on the operator's own written self-assessment, obtained 2026-09-04"
  - "144 is the authoritative backlog denominator, quoted with its date, because it is T1's frozen estimator basis"
  - "Images: retain both winners' images, prune the two wrtag tags this phase pulled, leave v0.20.0 for Phase 4"
  - "Snapshots @spike-03-t0 and @spike-03-t2-wav destroyed; Phase 1's fence untouched"
  - "Operator confirmed the decision verbatim at the blocking gate; Phase 3 is CLOSED"
  - "Discogs rotation stays at project close — re-raised with four causes and four verified workstation copies, and REAFFIRMED"
metrics:
  duration: ~4h30m
  completed: 2026-09-04
  tasks: 3
---

# Phase 3 Plan 11: Close the Spike — Two-Axis Decision, Teardown and Closure Summary

**The spike is decided, the estate is torn down, and the operator has confirmed it: beets as the
engine and beets-flask's policy-carrying inboxes — not its picker — as the front end, with all
three pre-committed thresholds resolved and none moved.** All three tasks are complete and
committed. **Task 3's blocking gate returned "Decision stands — close phase 03" and Phase 3 is
CLOSED.** `STATE.md` and `ROADMAP.md` remain deliberately untouched — the orchestrator owns those
writes and closes the phase.

---

## What was done

### Task 1 — the two-axis decision record (commits `f1503ff`, `386672b`, `004ff27`, `6d79a6a`)

**T3 was resolved and it FIRED.** Plan 03-10 recorded it `NOT ANSWERED` and was right to: T3's
named instrument is an explicit written self-assessment in the operator's own words, and no such
sentence existed. The orchestrator obtained it directly. It is quoted **verbatim** in both the
threshold table and § *Criterion 8*, and the 03-10 reading is preserved **in full** inside the same
cell, marked superseded **by the arrival of the missing instrument, not by re-interpretation**.

**Axis one — beets 2.13.1**, decided by the single fact that wrtag has no non-MusicBrainz metadata
source and this backlog is not in MusicBrainz. Stated plainly rather than dressed up: the spike's
job was to produce a number, and a number that confirms the direction is still a number. Three
things the phase added that were not known when the direction was set: T1 **fired** at 27.08%, so
beets wins while its headline advantage is under half of what would make it decisive alone; the DMC
stratum scored **strict 0 of 4**; and wrtag was **disqualified on measurement** at three tags, not
merely out-argued.

**Axis two — beets-flask's policy-carrying inboxes, and explicitly NOT its interactive picker.**
Scored on the sheet's own figures **including where they are empty**: 9 of 10 measurement rows read
`not measured` or `not run`, so **no quantitative ergonomics claim is made in either direction**.
The verdict is **not derived from axis one's** — it turns on T3 firing, on the picker's measured
safety failures, and on the inbox path being the one option that satisfies both.

**Criterion 4 answered with a five-step named mechanism** for Mastermix / DMC / Music Factory
content: normalise first with the committed mutagen script, import as-is through a `bootleg` inbox
(measured: 3 correct albums, `APIC` 60/60, `TBPM` 60/60 on a folder Discogs scored at zero), do not
attempt autotagging on it, route it clear of `Compilations/`, and resolve track order from the
publisher's own page. The phrase *"lives outside the tool"* appears **only** as the named failure
mode — which is what wrtag's `WRTAG_RESEARCH_LINK` answer is.

**Criterion 5** records all three thresholds tested and returned, **none indeterminate**, with the
weighted (27.08%) and unweighted (25.00%) figures side by side and which one T1 was tested against.
**Criterion 7** carries all eight researched frictions plus a ninth this deployment found, the
`bootleg` boundary measured twice with opposite outcomes, and the architecture confirmation.
**Criterion 8** is the operator's own words with the `stuck_points` beside them.

### Task 2 — teardown (commits `a47241c`, `537bf06`, `8e36762`)

All three spike containers removed and confirmed absent with **no status filter**; both scratch
trees deleted by exact path; both spike snapshots destroyed from atlantis; per-image retain/prune
decisions with a reason each; the three spike YAMLs archived with their `THROWAWAY` banner and a
new block recording that they are inert.

### Task 3 — the operator gate (commit `aabdcfb`)

**The gate returned, and the decision stands.** Task 3 is a `checkpoint:human-action` marked
`gate="blocking"`, and it is deliberately not satisfiable by an agent agreeing with the record —
this project's documented failure mode is a tool abandoned because nobody believed in it, and an
agent-ratified decision would reproduce exactly that.

The operator was shown the decision **and the case against it**: both axis verdicts, T1 **FIRED**
at 27.08% against 40%, T2 **NOT FIRED**, T3 **FIRED** on their own words, wrtag's disqualification
on measurement, the teardown evidence, and the unsmoothed tension that beets-flask rc6 is both
their stated preference and the arm with the worst measured safety record in the phase. They were
**explicitly invited to reject it** on the three grounds the record is most vulnerable on —
criterion 4's concreteness, whether axis two stands on its own evidence, and whether their
week-six verdict still reads true now the trial is over. A "no" was a real and available outcome.

> **"Decision stands — close phase 03"** — the operator, 2026-09-04

**The record was neither amended nor softened to obtain that answer.** It responds to the document
exactly as it stood. Recorded verbatim and dated in `03-DECISION.md` § *OPERATOR CONFIRMATION —
2026-09-04*.

**The rotation timing was re-raised at the same gate and REAFFIRMED.** See the section below — it
is an informed decision, not an oversight.

---

## The genuine tension, resolved without discounting either side

This is the part of the record most likely to be read as fudged, so it is stated plainly here too.

- **beets terminal arm** — ruled out by T3, in the operator's own words.
- **wrtag** — ruled out by 03-08, on measurement, at both ends of its version pin.
- **beets-flask rc6** — the operator's stated preference **and** the arm with the worst measured
  safety record in the phase.

**The resolution is that "beets-flask" is not one thing.** The trial measured a **policy
architecture** and a **candidate picker** bolted to it, and they scored oppositely: the
architecture produced the best result of either arm (one `mv`, zero decisions, three correct
albums), the picker produced a silent 9-file loss with 4 tracks mis-written onto different songs
under a UI asserting nothing was missing. Selecting the first while refusing the second is a real
distinction with a real mechanism — an inbox's `autotag` policy is a config key, and
`preview`/`auto`/`bootleg` never present the picker's candidate page.

**What that costs is recorded, not minimised:** `bootleg` is unguarded (it shreds a folder whose
`album` is empty, with no UI signal, and ~40% of sampled Mastermix folders are in that state); it
writes no `TRCK` at all; two one-click bulk destructive buttons must never be used on this
collection; rc6 has been a release candidate for eight months; and **the 144-folder case is
untested** — friction 5 stays `NOT EXERCISED`.

**And the operator's answer is read for what it says.** *"I understand what's happening"* is said
of the web interface **after** the trial in which it silently lost files. It endorses rc6's
**legibility**, not its **correctness**, and the record says so. Equally, *"It's fine for a bot to
drive us, but for me, as a human, no"* rejects the CLI as a **human interface**, not as a
mechanism — a scripted `beet` invocation remains acceptable.

---

## Provenance discipline

| Assertion | Instrument | Result |
|---|---|---|
| Threshold **definitions** unchanged | `cut -d'\|' -f2,3,4,5` on the T1/T2/T3 rows at `137b6d9e` vs now, `diff`ed | **byte-identical**, zero lines |
| Estimator section unchanged | `awk` range extract on both revisions, `diff`ed | differs **only** in its `PENDING` weight/rate cells |
| Threshold commit is a commit | `git cat-file -t 137b6d9e…` | `commit` |
| …reachable from `origin/main` | `git branch -r --contains` | `origin/main` |
| …an ancestor of `origin/main` | `git merge-base --is-ancestor` | exit **0** |
| Deletions in `03-DECISION.md` | `git show <sha> \| grep '^-'` per commit | **only** `PENDING` result cells (commit 1); **zero** deletions in commits 2–4 |
| Frozen files untouched (D-03) | `git diff --name-only HEAD` filtered | `wrtag.yaml`, `beets/beets.yaml`, `renovate.json5` **absent** |

**The threshold-commit custody item 03-02 left open is now CLOSED**: the orchestrator merged the
waves, and because this repository merges rather than squashes, the SHA survived unchanged — as
that section predicted, now verified rather than assumed.

---

## Deviations from Plan

### Auto-fixed and instrument substitutions

**1. [Rule 3 — blocking] The flask arm's `compose down` silently did nothing**
- **Found during:** Task 2, step 1
- **Issue:** The service carries `profiles: ["manual"]`. `docker compose down` without
  `--profile manual` **exited 0, printed nothing at all, and left the container running.**
- **Fix:** Re-ran with `--profile manual`; asserted the container's absence afterwards rather than
  trusting the exit code. Written into the file's own banner so it is not rediscovered.
- **Why it matters:** a teardown that greps the command output for "Removed" would have recorded a
  clean pass on a running container — the estate's signature failure mode.

**2. [Rule 3 — blocking] The plan named one credential file; three existed, and the named one did not**
- **Found during:** Task 2, step 2
- **Issue:** The plan directs deleting `/mnt/fast/spike-03/beets-config/spike-runtime.yaml`. **That
  path does not exist.** A value sweep found three token-bearing files under different names.
- **Fix:** Deleted the whole `/mnt/fast/spike-03/` tree and verified by value, not by filename.
- **Why it matters:** delete-by-name alone would have left **all three** copies on disk.

**3. [Rule 3 — blocking] The `/mnt/tank/downloads` full-content sweep is not viable**
- **Issue:** That dataset is **2.05 TB** (it holds a large `dropbox`, `google takeout` and `icloud`
  archive alongside the backlog). A byte-by-byte grep ran 45+ minutes without completing.
- **Substitute, and it is stronger than a scan:** **containment.** Every `/mnt/tank/**` mount on
  **either** arm points inside `/mnt/tank/downloads/spike-03/` — asserted mechanically from the
  archived compose files — so the scratch tree is the **complete** candidate set. That tree was
  grepped **in full before deletion** and held **zero** token-bearing files.
- Recorded in `03-DECISION.md` § *Teardown* § 2 with the reasoning, not silently swapped.

**4. [Rule 1 — bug, self-inflicted] A vacuous pass was caught and re-run**
- A `find -newermt` was mis-quoted inside a nested shell and returned `0` because the **date
  argument failed to parse**, not because nothing matched. It was re-run correctly, **and paired
  with a control** proving the instrument could see a recent file at all (it returned 1).
- Recorded because "could not look" reported as "nothing is wrong" is this estate's documented
  failure mode, and this plan nearly committed it.

### Newly logged deferred items

| ID | What |
|---|---|
| **DEF-03-20** | `grep -c PENDING` on `03-DECISION.md` **cannot** return 0 without deleting pre-committed prose from the threshold commit. Answered with a shape-matching instrument that returned **6 → 0** |
| **DEF-03-21** | **A secret passed as a command-line argument is world-readable via `/proc`, and `pgrep -af` prints it.** Caused by this plan. See below |

**DEF-03-18 CLOSED** by re-measurement; **DEF-03-19's substitute instruments ADOPTED** rather than
its unsatisfiable assertion being waved through.

---

## ⚠ Credential exposure caused by this plan — requires an operator decision

**The live Discogs token was exposed three ways during this teardown, by my own verification
command.** This is recorded prominently rather than buried, because it is the **third** exposure of
the same credential in this phase and the first caused by the command written to *verify* the
credential was gone.

**What happened.** The first sweeps passed the token as a **command-line argument**. A process's
argv is world-readable through `/proc`, so for ~45 minutes **any local user on LXC 100 could read
the live token from `ps`.** Then, confirming the scans had stopped, `pgrep -af` **rendered that
argv** — printing the token into the agent transcript **and** into a persisted tool-output file on
the workstation at
`~/.claude/projects/-Users-damian-Development-damianflynn-selfhost-stacks/<session>/tool-results/bla6jts0m.txt`.
**Deleting that file was refused by policy from inside this session, so it is still on disk.**

**Note that DEF-03-04's rule was followed exactly and it still leaked.** Every sweep printed **only
counts**; the value was never echoed. **The leak channel was the argv of the counting command** —
which that rule does not name.

| | Status |
|---|---|
| Token-bearing processes | **Terminated.** `pgrep -c -x grep` → **0** |
| Technique | Switched to `grep -f <(printf '%s' "$TOK")` — `printf` is a bash builtin, so no argv |
| Committed artefacts | **None affected.** Nothing token-bearing reached this repository |
| On-disk copies on LXC 100 | **Zero**, besides `/mnt/fast/secrets/discogs.env` at `600 root` |
| **Agent transcript** | **NOT recoverable** |
| **Persisted workstation file** | **NOT recoverable from this session — still on disk** |

**This makes FOUR independent causes behind the standing action to rotate the Discogs token, two of
them permanently unrecoverable.** **The operator decided rotation happens at project close, and
this plan did NOT rotate and did NOT block on it.** But cause 4 is **new information the operator
did not have when they set that timing**, and it is surfaced at the checkpoint for them to
re-weigh. The decision is theirs.

### RESOLVED at the gate — re-raised with worse facts, and the timing REAFFIRMED

**The paragraph above was written before the checkpoint. It is now closed, and it closed against
the plan's own reporting.** Two things were put to the operator that this plan had not established:

- **The count of workstation copies is four, not one.** The orchestrator checked rather than
  trusting this plan's report and found **four** plaintext copies — including
  `0b75bb5a-…jsonl`, **a different session's transcript entirely**, outside this phase's own
  session tree. I confirmed all four **present on disk** at close by an existence-and-size check
  that did **not** read their contents; `bla6jts0m.txt` measured **131,433 bytes**, matching the
  reported 131 KB.
- **The unrecoverable count was put to them as three, not the two this summary states above.**
  Both are right about different things, and the reconciliation is recorded rather than one figure
  silently replacing the other: *two* counts causes unrecoverable **in whole** (1 and 4); *three*
  counts every cause that left an unrecoverable **agent-transcript** residue (1, 2 and 4 — adding
  cause 2, whose `644` file was shredded but whose transcript half was not). Cause 3 left no
  persisting artefact, but its window cannot be un-opened.

> **"Keep project close"** — the operator, 2026-09-04, given all of the above

**This is an informed, reaffirmed decision — not an oversight, and not an open risk for a later
plan to re-litigate.** What is and is not exposed:

| | Status |
|---|---|
| The four workstation copies | **LOCAL and UNPUBLISHED** — session artefacts on the operator's own machine. None is in any repository; none was pushed |
| **This repository** | **PROVABLY CLEAN** — every commit screened by the token's **value** *and* its **8-character prefix**, **0 hits**, verified **independently by the orchestrator** rather than self-reported |
| The estate | `/mnt/fast/secrets/discogs.env` remains the **single** estate copy, `600 root` |
| Scrubbability | **Three of the four are append-only session transcripts** that cannot be reliably scrubbed; the fourth's deletion was refused by policy from inside the session |

**Why the operator's position is the stronger one:** because the residue cannot be reliably
deleted, **rotation — not deletion — is the effective remedy.** Rotating makes every copy inert
however many exist; deleting three of four would lower the count while leaving the credential live.
**The action goes to project close carrying all four causes**, updated in `03-DECISION.md` § 9 and
DEF-03-21 so whoever executes it does not act on the one-cause problem DEF-03-04 opened.

---

## Teardown evidence

| Check | Result |
|---|---|
| `beets-spike` / `beets-spike-rw` / `beets-flask-spike` in `docker ps -a` (**no status filter**) | **0 / 0 / 0**; no name containing `spike` |
| `/mnt/tank/downloads/spike-03` | **gone** (45 G, all ten children) |
| `/mnt/fast/spike-03` | **gone** (215 M) |
| Token hits under `/mnt/fast/` | **4 → 1** — only `/mnt/fast/secrets/discogs.env`, still `600 root` |
| Token hits under `/mnt/tank/downloads/` | scratch tree **0 before deletion**, tree now gone; containment proves it was the complete candidate set |
| Token hits in shell history | **0.** Only one history file exists (`/root/.bash_history`, mtime **2026-08-15**, before the phase) |
| `tank/downloads@spike-03-t0`, `@spike-03-t2-wav` | **destroyed** from atlantis |
| `tank/downloads@pre-project`, `tank/media/Music@pre-project` | **both present** |
| Images | retain `beets:2.13.1-ls349` + `beets-flask:v2.0.0-rc6`; **pruned** `wrtag:v0.33.0`, `v0.34.0`; **left** `v0.20.0` for Phase 4 |
| `df -BG --output=avail /` | **35 G** (floor 8 G; 03-01 `## After` was 36 GiB) |
| `docker ps -a` count | **104** vs the 103 baseline — the +1 is a **non-spike** container created 2026-09-02, stated as unattributed rather than explained away |
| Three `03-spike-*.yaml` tracked, `head -1` each | **`# THROWAWAY — DO NOT DEPLOY`** ×3 |
| `grep -rl '03-spike-' stacks/` | **nothing** — the archive is inert |

**Measured confirmation that a stale snapshot is not free:** `@spike-03-t2-wav` held **236 M** while
the tree existed and **31.6 G** the moment it was deleted. Kept, it would have made a "deleted" 45 G
tree cost more than before.

**And why only ~50 G came back from a 45 G tree:** it was **reflinked** from the real backlog, so
most blocks are still referenced by `complete/nzb`. Reflinked clones free space only when the last
reference goes.

---

## Library and estate integrity at close

| Assertion | Instrument | Result |
|---|---|---|
| Music freeze | `check-music-freeze.sh` **on LXC 100** | **exit 0**; `tagger-class writers: 0`, `unclassified: 0`, `consumer-class: 1` (Jellyfin, D-21 — confirms a **sighted** run per DEF-03-11), `declared rw reaching Music: 0`, `ownership mismatches: 0`, `FAILURES total: 0` |
| Library byte-identical | `zfs diff tank/media/Music@pre-project`, **by change type** | **2,674 `M`, zero `+`, zero `-`, zero `R`** against a tree of exactly 2,674 entries — nothing created, deleted or renamed |
| …cross-checked | mtime/ctime window over the plan | **0 and 0** |
| Phase 1 ownership | `find -printf '%U:%G'` from **atlantis** | **2,674 × `568:568`** — unchanged from the baseline |
| Real backlog untouched | file count before/after teardown | **8,934 → 8,934**; **0** files written during the plan, with a **sighted** control (1) |
| Workstation health | `scripts/quick-health-check.sh` | **exit 0.** Freeze, consumers and transcode all `FAILURES total: 0` |

**One pre-existing report, not caused by this phase and not a gate failure:** `quick-health-check.sh`
prints `Traefik dashboard: ❌ Not accessible` while exiting 0. Recorded rather than passed over.

**`zfs diff … returns clean` is NOT claimed**, because it is unsatisfiable and has been since
2026-08-18 (DEF-03-19). The substitute instruments above are used instead.

---

## Eight ROADMAP criteria, with the artefact satisfying each

| # | Criterion | Artefact |
|---|---|---|
| 1 | Discogs match rate over ~20 normalised DJ folders, un-normalised beside it | `03-DISCOGS-EVIDENCE.md` — normalised weighted strict **27.08%**, un-normalised **27.08%**, loose 51.39% / 40.16% |
| 2 | 20 folder imports timed and extrapolated against the 60 req/min ceiling | `03-DISCOGS-EVIDENCE.md` — **21.8 min** projected, M = 3.125 req/folder, **0** HTTP 429 |
| 3 | wrtag disqualifier run, outcome recorded either way | `03-WRTAG-EVIDENCE.md` — three tags, both disc classes; format renders on **none** |
| 4 | One tagger named, concrete answer for Mastermix / DMC / Music Factory | `03-DECISION.md` § *Criterion 4* — five named steps, each with its measured number |
| 5 | Thresholds pre-committed; which tested and what each returned | `03-DECISION.md` § *Criterion 5* + threshold commit `137b6d9e`, proven an ancestor of `origin/main` |
| 6 | Two axes, scored independently | `03-DECISION.md` §§ *Axis one*, *Axis two* — different evidence, opposite directions, both recorded |
| 7 | beets-flask evaluated **by name** with its frictions | `03-BEETS-FLASK.md` + `03-DECISION.md` § *Criterion 7* — 8 researched frictions + a 9th found |
| 8 | Honest ergonomics verdict in the operator's own terms | `03-DECISION.md` § *Criterion 8* — the operator's verbatim answer |

**Criterion 8's confirmation, and therefore the phase's closure, was the operator's to give — and
they gave it** at Task 3, verbatim, on 2026-09-04: *"Decision stands — close phase 03"*. All eight
criteria are satisfied.

---

## Known Stubs

**None.** No file created or modified by this plan contains a placeholder, a hardcoded empty value,
or a TODO. Every `PENDING` remaining in `03-DECISION.md` is pre-committed prose or a strikethrough
provenance marker, enumerated and justified in DEF-03-20.

---

## Threat Flags

**None.** This plan created no network endpoint, no auth path and no schema change. It **removed**
attack surface (three containers, two credential copies, two images). The one security-relevant
event is a **credential exposure caused by this plan's own verification command** — recorded above
and as DEF-03-21, and it is a mitigation failure against the existing T-03-65 / T-03-69b register
entries rather than new surface.

---

## What is NOT done, and what stays open after close

**Phase 3 IS closed.** These are the things closing it does **not** settle, kept visible here rather
than buried, because a closing record that reads cleaner than the evidence is the failure this
phase spent eleven plans avoiding.

- **`.planning/STATE.md` and `.planning/ROADMAP.md` — deliberately untouched by this executor.**
  The orchestrator owns those writes and closes the phase.
- **The Discogs token is not rotated** — the operator's reaffirmed timing, honoured.
- **DEF-03-17 rests on ONE verified product page.** `mastermixdj.com` being canonical for ~76% of
  the backlog is a hypothesis with a single confirming instance; **coverage across the 99 Mastermix
  folders is UNPROVEN.** It reframes what T1's 27.08% *means* and changes **nothing** about T1's
  value, threshold, definition, estimator or denominator. Phase 4 must measure coverage before
  anything is designed around it. Its **~76% / 115-of-151** figure is quoted against **151**, not
  the authoritative **144**, and must never be paired with 144-based weights.
- **Criterion 8's verdict in `03-ERGONOMICS-SHEET.md` is scribe-assembled and stays labelled so.**
  The operator's T3 verbatim is their own words on the same question; **the analytical paragraphs
  remain the executor's.** The sheet's outstanding "replace or countersign" instruction is
  discharged — their words now exist — but they did **not** countersign the analysis, and the
  section is not rewritten to imply they did.
- **The measurements that were not taken.** `wall_clock_s` and `interventions` read `not measured`
  on **9 of 10** sheet rows; **4 of 5** terminal rows read `not run`. **The trial was decided by a
  defect, not by a stopwatch**, and no quantitative ergonomics claim is made in either direction.
- **DEF-03-19 carried forward unfixed.** `zfs diff tank/media/Music@pre-project` has been non-clean
  since **2026-08-18** — 2,674 `M` lines from Phase 1 plan 01-08's chown — and **three plans assert
  otherwise**. The substitute instruments are used instead.
- **The 144 / 151 denominator is SETTLED, not left circulating.** 144 is authoritative *for this
  phase* because it is T1's frozen estimator basis and must be quoted with its date; 151 is a
  different measurement, not a wrong one. Anyone re-counting must record the **path set, the audio
  test and the timestamp** — sabnzbd is still writing into the tree, and a folder landed 41 minutes
  after the census was committed.
- **Friction 5 / the 144-folder case is NOT EXERCISED.** beets-flask's *"laggy past some hundred
  folders"* limitation was never tested against this backlog. Phase 9 inherits it.

**The teardown was not re-run at this gate and is not re-asserted here.** Its evidence stands from
Task 2 as recorded above; re-running it would have been a fresh mutation of a torn-down estate for
no new information.

---

## Self-Check: PASSED

Files asserted present:

```
FOUND: .planning/phases/03-tagger-spike/03-DECISION.md
FOUND: .planning/phases/03-tagger-spike/deferred-items.md
FOUND: .planning/phases/03-tagger-spike/03-spike-beets.yaml
FOUND: .planning/phases/03-tagger-spike/03-spike-beets-config.yaml
FOUND: .planning/phases/03-tagger-spike/03-spike-beets-flask.yaml
FOUND: stacks/selfhosted/arrs/beets.md
```

Commits asserted present in `git log`:

```
FOUND: f1503ff  docs(03-11): resolve T3, score both axes independently, answer criterion 4
FOUND: 386672b  docs(03-11): record criteria 5, 7 and 8 with the operator's verdict verbatim
FOUND: 004ff27  docs(03-11): record the 03-11 amendment, the Phase 4-9 handoffs, beets.md pointer
FOUND: 6d79a6a  docs(03-11): close DEF-03-18, adopt DEF-03-19's instrument, log DEF-03-20
FOUND: a47241c  chore(03-11): mark the three archived spike YAMLs inert at Phase 3 close
FOUND: 537bf06  chore(03-11): tear down the spike and record every step with its instrument
FOUND: 8e36762  docs(03-11): log DEF-03-21 — a secret in argv is world-readable
FOUND: aabdcfb  docs(03-11): record the operator gate — the decision stands and Phase 3 closes
```

Provenance discipline on the closing commit, asserted mechanically rather than claimed:

```
git diff --stat   ->  3 files changed, 219 insertions(+), 0 deletions
git diff -U0 | grep '^-' | grep -v '^---'   ->  (empty)
git diff --diff-filter=D --name-only HEAD~1 HEAD   ->  (empty)
```

**Zero deletions across all three amended files.** No threshold, estimator, denominator or rubric
text was altered; T1/T2/T3's `Threshold`, `Falsifiable form` and `Instrument` columns are untouched,
which the zero-deletion result establishes directly. `.planning/STATE.md` and `.planning/ROADMAP.md`
are absent from the diff.

The four workstation credential copies were confirmed present by existence-and-size only — their
**contents were not read**, and the token was not handled by this executor at any point:

```
PRESENT    2583363  0b75bb5a-63a3-4199-866d-ba8e3aad77d9.jsonl   (a different session's transcript)
PRESENT    1939674  agent-a7f083d3ca24630c9.jsonl   (plan 03-11)
PRESENT    1592052  agent-a2f9378b36744194d.jsonl   (plan 03-06)
PRESENT     131433  bla6jts0m.txt                   (deletion refused by policy)
```
