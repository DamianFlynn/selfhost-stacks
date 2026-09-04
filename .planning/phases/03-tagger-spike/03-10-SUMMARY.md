---
phase: 03-tagger-spike
plan: 10
subsystem: axis-two-ergonomics
tags: [beets-flask, rc6, checkpoint, criterion-7, criterion-8, TAGR-06, D-09, D-10, D-11, OD-2, T3]
status: HALTED — blocking checkpoint, Task 1 of 3
requires:
  - "03-02 — the empty ergonomics sheet with its counting definitions and alternation fixed before the trial"
  - "03-07 — T1 FIRED at 27.08%, T2 did not fire, and the loose-fail set the fifth album is drawn from"
  - "03-09 — the D-13 verdict, and the instrument lessons this plan's assertions inherit"
  - "03-01 — the metasauce/beets-flask:v2.0.0-rc6 pull and its recorded digest"
provides:
  - ".planning/phases/03-tagger-spike/03-BEETS-FLASK.md — the release-candidate acknowledgement, complete and awaiting only the operator's decision line"
  - "the axis-two scope statement: it compares a policy architecture (preview/auto/bootleg) as well as a front end"
  - "a host-verified digest assertion and a docker ps -a assertion proving the acknowledgement predates any deployment"
affects:
  - "03-11 — axis two stays PENDING and T3 stays PENDING until this plan resumes and completes"
  - "Phase 9 — the laggy-past-some-hundred-folders limit against the 144-folder backlog, recorded as a handoff the 5-album trial cannot test"
tech-stack:
  added: []
  patterns:
    - "Re-verifying a digest against the live host rather than copying it forward from the plan file that asserted it"
    - "Asserting the ABSENCE of the container being gated (docker ps -a) so the acknowledgement is provably pre-deployment rather than back-filled"
    - "Recording an adverse fact the trial structurally cannot test, before any score exists, so a good score cannot later absorb it"
key-files:
  created:
    - .planning/phases/03-tagger-spike/03-BEETS-FLASK.md
  modified: []
decisions:
  - "Nothing was deployed. Task 1 is a blocking checkpoint:decision and the executor stopped at it rather than self-approving the release-candidate deployment"
metrics:
  tasks_completed: 1
  tasks_total: 3
  commits: 2
---

# Phase 3 Plan 10: Axis Two — The Front End Summary

**Halted at Task 1's blocking checkpoint with the release-candidate acknowledgement written,
host-verified and committed — and with no container deployed.**

## What this plan is for

Axis two — the front end — is the axis that may decide whether this project finishes. The
operator's first-hand experience is that beets has been painful to get working, and a painful tool
is the documented cause of all three prior abandonments. Criterion 6 is explicit that a decision
record answering only axis one has not met TAGR-06.

Plan 03-10 scores it by putting the same five albums through a raw terminal prompt and through a
reviewable queue, timed, with the operator personally at the keyboard.

## Status: 1 of 3 tasks complete, halted at a blocking gate

| Task | Type | Status |
|---|---|---|
| 1 — Operator acknowledges the release-candidate risk | `checkpoint:decision`, blocking | **Prepared and presented — AWAITING OPERATOR** |
| 2 — Deploy the throwaway instance, check the 8 frictions | `auto` | Not started — gated by Task 1 |
| 3 — The operator runs the timed trial personally | `checkpoint:human-action`, blocking | Not started |

Task 1 is the **first** task in the plan, so execution halted almost immediately by design. This is
the intended shape: `03-RESEARCH.md` § *Package Legitimacy Audit* approves the rc6 image **with a
note** and explicitly recommends gating the trial deployment behind an operator acknowledgement.
**Nothing is deployed until that acknowledgement exists.**

## What was produced

`.planning/phases/03-tagger-spike/03-BEETS-FLASK.md`, carrying a complete
`## Release-candidate acknowledgement` section against every acceptance criterion Task 1 names:

- **The RC status** — 2.0 in RC since 2025-12-29; last stable v1.2.1 (28 Dec 2025), eight months
  stale. Recorded as an axis-two durability risk in its own right, not merely as a version number.
- **The absent authentication and the web terminal** — no auth of any kind, plus a tmux-backed web
  terminal with shell access to the container, with the full mitigation table (no Traefik labels at
  all, `127.0.0.1:5002` only, no `/mnt/tank/media` mount at any mode, `no-new-privileges`).
- **The pinned startup pip install** — `beets[discogs]==2.12.0`, with both audit verdicts
  (`beets` `[OK]`, `python3-discogs-client` `[OK]`; 3 OK / 0 SUS / 0 SLOP) and the reason the pin is
  load-bearing rather than stylistic.
- **The axis-two scope statement**, so the operator acknowledges the comparison they are actually
  about to run.
- **The image digest**, and the three options as put to the operator.

## Two assertions worth more than the document text

**The digest was re-verified against the live host, not copied forward.** Task 1's acceptance
criteria require the recorded digest to match `docker images --digests` on LXC 100. Reading it out
of `03-REAP-LIST.md` would have asserted only that this plan can copy. The live read returns
`sha256:9548e78f8bcda864bf557b7bb7490f7dcfb852ce3abf2f4c1501d5bb812ec2cd`, matching the 03-01 record
character for character.

**The absence of the gated container was asserted, not assumed.** `docker ps -a` on LXC 100 shows
no `beets-flask-spike` — only `beets-spike` (`lscr.io/linuxserver/beets:2.13.1-ls349`, up 10 hours),
the terminal arm from earlier plans. This is what makes the acknowledgement provably
**pre**-deployment rather than back-filled around a container that was already running. An
acknowledgement written beside a running container is a record of consent that was never sought.

## What this plan did NOT do, deliberately

**It did not self-approve the deployment.** Task 1 is `gate="blocking"` and the decision is the
operator's. Auto-approving a third-party release candidate with no authentication and a web shell,
onto a host running 103 containers, is exactly the class of decision a checkpoint exists to prevent
an agent from making.

**It did not pre-fill the operator's decision line**, which reads `PENDING` with a `PENDING` date.

**It did not touch `03-ERGONOMICS-SHEET.md` or `03-DECISION.md`.** The sheet was committed empty by
plan 03-02 precisely so its rubric could not be reshaped to fit what a trial observes; T3 stays
`PENDING` in `03-DECISION.md` until the operator's own self-assessment exists to quote. Neither file
appears in this plan's diff.

## One correction carried in, and one limit recorded before it could be inconvenient

**The backlog denominator is 144 folders, not 143.** The plan text says 143 in several places;
plan 03-03's two-instrument survey measured 144 (`nzb/music` is 24 folders / 277 files, not 23 /
275). The acknowledgement uses **144** and says so.

**The scale limit is recorded before any score exists.** beets-flask's own `docs/limitations.md`
says the UI *"will get laggy"* past *"some hundred folder or so"* (#164, #175), against a 144-folder
backlog. **A five-album trial structurally cannot exercise this**, and the acknowledgement says so
explicitly — carried as an axis-two risk and a Phase 9 handoff, not as a measured finding. Recording
it now, before the trial produces a number, is what stops a good five-album score from later being
read as evidence the UI scales to the real backlog.

## Deviations from Plan

None. Task 1 executed as written and halted where the plan says to halt.

## Commits

| Hash | Message |
|---|---|
| `497361c` | `docs(03-10): draft the beets-flask RC acknowledgement, before anything is deployed` |
| *(this)* | `docs(03-10): record the plan-03-10 halt at the release-candidate checkpoint` |

## Resuming

The continuation agent needs the operator's answer to Task 1's decision, then proceeds to Task 2
(deploy) and Task 3 (the operator's own timed trial). **Task 3 cannot be executed by an agent** —
D-09 is explicit that the trial is run by the operator personally, because the measurement is the
operator's wall-clock, intervention count and annoyance.

Nothing needs undoing. No container exists, no host state changed, and the only artefact is a
committed document awaiting one line.

## Self-Check: PASSED

- `.planning/phases/03-tagger-spike/03-BEETS-FLASK.md` — FOUND
- Commit `497361c` — FOUND
- No `beets-flask-spike` container on LXC 100 — CONFIRMED
- `03-ERGONOMICS-SHEET.md` and `03-DECISION.md` unmodified by this plan — CONFIRMED
- No credential-shaped string in this plan's diff — CONFIRMED (only the public image digest)
