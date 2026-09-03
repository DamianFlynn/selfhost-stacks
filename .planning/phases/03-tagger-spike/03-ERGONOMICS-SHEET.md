# Phase 3 ergonomics scoring sheet (criteria 6 and 8)

Companion to [`03-DECISION.md`](03-DECISION.md) § *Axis two* and to
[`stacks/selfhosted/arrs/beets.md`](../../../stacks/selfhosted/arrs/beets.md).

Nothing here is applied by `docker compose`. This is the sheet the operator fills **during** the
timed hands-on trial in plan 03-10 — not afterwards from memory.

State as of 2026-09-03 — **committed empty, before the trial.** Every measurement cell below is
blank by design.

> **This sheet is committed before the trial deliberately.** VALIDATION Wave 0 requires the template
> to predate the evidence, and **a committed empty template is the only way that is provable
> afterwards.** A sheet whose columns or definitions were settled after the run is not a
> measurement — it is a reconstruction. The definitions below are therefore fixed **now**, and the
> git commit that introduces this file is what a later `git log -p` is diffed against.

---

## Definitions, fixed before the run

These are not decoration. **The definition is the measurement**, and a definition invented after the
run is not a measurement. Both counting rules are stated here so they can be held constant across
all ten rows and audited afterwards.

**What counts as one intervention.** One intervention is **one discrete decision or keystroke
sequence the operator has to author in order to advance the import** — accepting a candidate,
rejecting one, choosing among candidates, typing or pasting a release ID, editing a field, or
choosing as-is or skip. **Pressing Enter to accept a default counts.** Scrolling, reading and
waiting do **not**.

**What counts as one context switch.** One context switch is **every time the operator has to leave
the tool**: open a browser, grep a path, read documentation, or open a second terminal.

**The wall-clock rule.** Start the clock when the operator **first looks at the album**. Stop it when
the album is **imported or abandoned**. `wall_clock_s` is recorded in whole seconds.

**Permitted `outcome` values.** Exactly one of: `imported`, `as-is`, `skipped`, `abandoned`. No other
value may be entered.

**`stuck_points` is verbatim and contemporaneous.** Record where the operator got stuck or annoyed
**in their own words, at the moment it happened**, not reconstructed at the end of the run. This is
the raw material for the criterion 8 verdict.

---

## The ordering control

The **same album goes through both arms**, but **which arm goes first alternates across the five
albums**. A second pass is always faster because the operator already knows the answer, so a fixed
order would silently reward whichever tool went second.

The alternation is **pre-assigned below and must not be changed during the run** — that is what the
`went_first` column exists to make auditable rather than merely claimed. `went_first` reads `yes` on
the arm that ran first for that album and `no` on the arm that ran second.

---

## Version note (OD-2)

The two arms **cannot** share a beets version: beets-flask `v2.0.0-rc6` hard-pins `beets==2.12.0` —
an exact pin, not a floor. Both arms appear as the two `front_end` values in the table below.

| Arm | beets version | Container |
|---|---|---|
| Terminal arm | **2.13.1** | `lscr.io/linuxserver/beets:2.13.1-ls349` |
| Flask arm | **2.12.0** (hard-pinned by rc6) | `metasauce/beets-flask:v2.0.0-rc6` |

**This does not contaminate axis two**, because axis two is scored on **interaction, not match
quality**, and `importsource` — the one 2.x feature later phases depend on — landed in 2.6.0 and is
present in both. Nothing in 2.13.0's changelog affects Discogs candidate generation.

---

## The sheet

Ten rows: five albums × two front ends. **`album_slot`, `album`, `front_end` and `went_first` are
pre-filled. Every measurement cell is empty and stays empty until the trial runs.**

The `album` cell reads `TBD — plan 03-10 Task 1` for the four non-DJ slots. For `dj-no-match` it
reads `TBD — a loose-fail folder from plan 03-07`, because D-10 requires that folder to be chosen
**after** criterion 1 runs, not before — picking it in advance would let the trial's difficulty be
selected rather than measured.

| album_slot | album | front_end | went_first | wall_clock_s | interventions | context_switches | outcome | stuck_points |
|---|---|---|---|---|---|---|---|---|
| clean-1 | TBD — plan 03-10 Task 1 | beets-terminal | yes | | | | | |
| clean-1 | TBD — plan 03-10 Task 1 | beets-flask | no | | | | | |
| clean-2 | TBD — plan 03-10 Task 1 | beets-terminal | no | | | | | |
| clean-2 | TBD — plan 03-10 Task 1 | beets-flask | yes | | | | | |
| hard-va-compilation | TBD — plan 03-10 Task 1 | beets-terminal | yes | | | | | |
| hard-va-compilation | TBD — plan 03-10 Task 1 | beets-flask | no | | | | | |
| hard-flat-multidisc | TBD — plan 03-10 Task 1 | beets-terminal | no | | | | | |
| hard-flat-multidisc | TBD — plan 03-10 Task 1 | beets-flask | yes | | | | | |
| dj-no-match | TBD — a loose-fail folder from plan 03-07 | beets-terminal | yes | | | | | |
| dj-no-match | TBD — a loose-fail folder from plan 03-07 | beets-flask | no | | | | | |

**The five slots, per D-10:** 2 clean mainstream (`clean-1`, `clean-2`), 2 hard shapes — one
various-artist compilation (`hard-va-compilation`) and one flat multi-disc set
(`hard-flat-multidisc`) — and 1 DJ folder Discogs will not match (`dj-no-match`). Ergonomic pain
appears on **ambiguous** matches, not on the happy path: a front end can feel effortless on clean
matches and become unbearable on the fraction that need a decision. The no-match case measures what
happens when the tool **cannot** help, which is where a front end either saves the operator or
loses them.

---

## Criterion 8 — the week-six verdict

*To be written by the operator, in their own words, after the trial. Record the `stuck_points` that
produced it beside it.* **"It works" is not the finding — "it works and I will still open it" is.**
