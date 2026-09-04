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
| clean-1 | Taylor Swift — *1989 (Taylor's Version)* | beets-terminal | yes | 30 | 1 | 1 | tagged | |
| clean-1 | Taylor Swift — *1989 (Taylor's Version)* | beets-flask | no | | | | | |
| clean-2 | Garth Brooks — *Ropin' The Wind* | beets-terminal | no | | | | | |
| clean-2 | Garth Brooks — *Ropin' The Wind* | beets-flask | yes | | | | | |
| hard-va-compilation | *Now That's What I Call Music 116* | beets-terminal | yes | | | | | |
| hard-va-compilation | *Now That's What I Call Music 116* | beets-flask | no | | | | | |
| hard-flat-multidisc | Lady Gaga — *Born This Way: The Collection* | beets-terminal | no | | | | | |
| hard-flat-multidisc | Lady Gaga — *Born This Way: The Collection* | beets-flask | yes | | | | | |
| dj-no-match | *Mastermix Crate 068–070* (2025) | beets-terminal | yes | | | | | |
| dj-no-match | *Mastermix Crate 068–070* (2025) | beets-flask | no | | | | | |

**The five slots, per D-10:** 2 clean mainstream (`clean-1`, `clean-2`), 2 hard shapes — one
various-artist compilation (`hard-va-compilation`) and one flat multi-disc set
(`hard-flat-multidisc`) — and 1 DJ folder Discogs will not match (`dj-no-match`). Ergonomic pain
appears on **ambiguous** matches, not on the happy path: a front end can feel effortless on clean
matches and become unbearable on the fraction that need a decision. The no-match case measures what
happens when the tool **cannot** help, which is where a front end either saves the operator or
loses them.

---

## AMENDMENT 2026-09-04 — the `album` column filled, and the trial staged

Added by plan 03-10 Task 3 staging. **Nothing above this line was altered except the ten `album`
cells**, which the plan's Task 3 action directs to be written *before the trial starts*. The
definitions, the wall-clock rule, the permitted `outcome` values, the ordering control and the
pre-assigned `went_first` alternation are **unchanged since the plan-03-02 commit** and must stay
that way. Every measurement cell is still empty. The paragraph above describing the cells as
reading `TBD` is left verbatim rather than rewritten, because it is the provenance record of what
the sheet looked like before the albums were chosen.

### The five albums, and where each came from

Four were named in `03-SAMPLE.md` § *The bucket-A and hard-shape candidates* — themselves
replacements after all three of `03-RESEARCH.md`'s original candidates were measured empty or
single-track. The fifth was chosen **after** criterion 1 ran, as D-10 requires, so the trial's
difficulty was measured rather than selected.

| Slot | Album | Source folder | Files | Provenance |
|---|---|---|---|---|
| `clean-1` | Taylor Swift — *1989 (Taylor's Version)* | `nzb/music/Taylor.Swift-1989..Taylors.Version.-WEB-2023-MyMo` | 21 mp3 | `03-SAMPLE.md`, V1, flat, single artist |
| `clean-2` | Garth Brooks — *Ropin' The Wind* | `nzb/music/_FAILED_Garth.Brooks-Ropin.The.Wind-CDP.7.06330-2-CD-FLAC-1991-EMG` | 10 flac | `03-SAMPLE.md`, V1. The `_FAILED_` prefix is a SABnzbd unpack marker on the **folder name**; the ten FLAC are present and probe clean |
| `hard-va-compilation` | *Now That's What I Call Music 116* | `nzb/unsorted/VA-Now_That.s_What_I_Call_Music__116__2023` | 47 mp3 | `03-SAMPLE.md`, V6, **46 distinct per-track artists** |
| `hard-flat-multidisc` | Lady Gaga — *Born This Way: The Collection* | `nzb/music/Lady Gaga-Born This Way-The Collection [2011] FLAC` | 31 flac | `03-SAMPLE.md`, V1. Genuinely multi-disc-in-one-folder: two different `01.` tracks sit at the top level |
| `dj-no-match` | *Mastermix Crate 068–070* (2025) | `spike-03/normalised/VA-Mastermix.Crate.068-070-2025` | 60 mp3 | **`03-DISCOGS-EVIDENCE.md` case C** — scored **loose-fail / zero Discogs candidates** by the probe **and** independently by a hand-transcribed `beet import -t`, agreeing on all ten properties |

All five file counts were re-verified on disk at staging time and match `03-SAMPLE.md` exactly.
All five are flat (`find -mindepth 2 -type d` = 0).

### How they are staged

Reflinked (`cp -r --reflink=always --preserve=timestamps`, run **from atlantis** — the `FICLONE`
ioctl is refused to the unprivileged container) into
`/mnt/tank/downloads/spike-03/bf-inbox/preview/`, **each in its own directory**. One directory per
release is mandatory, not tidiness: loose files never trigger in beets-flask — a documented wontfix,
and re-confirmed by direct probe in `03-BEETS-FLASK.md` friction 2.

Both arms were asserted to see the same tree, host-side and **from inside each container**, because
the bind mount pins the directory inode and a stale mount makes commands exit 0 reporting 0 files:

| Reading | Folders | Audio files |
|---|---|---|
| Host | 5 | 169 |
| Inside `beets-flask-spike` | 5 | 169 |
| Inside `beets-spike` (terminal arm) | 5 | — |

**A stamp was taken before the trial** at `/mnt/tank/downloads/spike-03/bf-inbox/.trial-stamp-t0.txt`
(the five directory paths plus a `sha256sum` over the sorted file list), so *"the runs copied rather
than moved"* can be asserted afterwards rather than assumed.

The beets-flask library and `bf-clean` were **reset to empty** after the Task 2 bootleg observation
and before this staging, so the operator begins against an empty library: `bf-clean` 0 files,
`spike-flask.blb` absent.

### Two asymmetries to hold in mind while scoring — neither is a defect

Recorded now, before any number exists, so they cannot be argued into or out of the result later.

1. **The flask arm does its metadata lookup before the clock starts.** Its watchdog picks up an
   inbox directory after a 30-second debounce and generates the preview *unprompted*. The terminal
   arm cannot: `beet import -t` does its lookup while the operator waits. So some of the flask arm's
   `wall_clock_s` advantage is **real and is the product difference** — a queue exists precisely so
   the work happens before you look at it — but it is **not** a measure of the interface being
   quicker to drive. Score what you experience; just do not let the verdict read as "the UI is
   faster" when part of it is "the UI started earlier".
2. **The arms run different beets versions** — 2.13.1 terminal, 2.12.0 flask, hard-pinned by rc6
   (OD-2). Axis two is scored on **interaction, not match quality**, and both arms were asserted to
   load the identical plugin set (`discogs, fromfilename, importsource, musicbrainz`) via
   `beet version`. If a candidate list differs noticeably between arms, note it in `stuck_points`
   rather than treating it as an ergonomics signal.

### Running it — one command per arm

**Terminal arm** (beets 2.13.1). One album at a time; `$ALBUM` is a folder name from the table
above:

```bash
ssh root@172.16.1.159
ALBUM='Taylor.Swift-1989..Taylors.Version.-WEB-2023-MyMo'
docker exec -it beets-spike beet -c /spike-config/spike.yaml -l /spike-config/spike-trial.blb \
  import -t "/mnt/tank/downloads/spike-03/bf-inbox/preview/$ALBUM"
```

**Flask arm** (beets 2.12.0). Open the tunnel, then browse:

```bash
ssh -L 5002:127.0.0.1:5002 root@172.16.1.159
# then open http://127.0.0.1:5002 in a browser on this machine
```

The tunnel was **tested end-to-end and returns HTTP 200**. The service is bound to `127.0.0.1`
only — `http://172.16.1.159:5002` is refused, by design: beets-flask has no authentication and
ships a web shell.

**To exercise `bootleg` on the DJ album** (step 5 of the plan's how-to-verify), move it between
inboxes — this is the affordance the terminal arm has no equivalent of:

```bash
ssh root@172.16.1.159 'mv /mnt/tank/downloads/spike-03/bf-inbox/preview/VA-Mastermix.Crate.068-070-2025 \
                          /mnt/tank/downloads/spike-03/bf-inbox/bootleg/'
```

Note what `bootleg` already did to a *different* zero-candidate DJ folder in
`03-BEETS-FLASK.md` § *The bootleg inbox* — it turned one 20-track release into twenty
single-track albums — and judge whether the UI gave you any warning that that was about to happen.

### Housekeeping while you run

- The terminal arm's import destination is `/mnt/fast/spike-03/beets-config/library`, which is on
  **LXC 100's ext4 root, not the `fast` pool**. The staged set is **2.6 G** against **35 G free**;
  OD-1's floor is 8 GiB, so there is ample headroom, but `df -h /` is the thing to watch, not
  `zfs list`.
- Both arms `copy`, never `move`. beets-flask supports only `copy`; the terminal arm's spike config
  sets `import.copy: yes` / `import.move: no` explicitly against the estate's `import.move: yes`
  default. Neither container mounts `/mnt/tank/media` at any mode.

---

## Criterion 8 — the week-six verdict

*To be written by the operator, in their own words, after the trial. Record the `stuck_points` that
produced it beside it.* **"It works" is not the finding — "it works and I will still open it" is.**
