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
| clean-1 | Taylor Swift — *1989 (Taylor's Version)* | beets-terminal | yes | 30 | 1 | 1 | imported | *(operator wrote outcome `tagged`; reconciled in AMENDMENT B-2. 21/21 files verified on disk)* |
| clean-1 | Taylor Swift — *1989 (Taylor's Version)* | beets-flask | no | not measured | not measured | not measured | imported | 88% preview was already waiting before the operator looked; 21 → 21, nothing dropped |
| clean-2 | Garth Brooks — *Ropin' The Wind* | beets-terminal | no | not run | not run | not run | not run | not run — operator decision (AMENDMENT B-3) |
| clean-2 | Garth Brooks — *Ropin' The Wind* | beets-flask | yes | not measured | not measured | not measured | imported | **full-page `TypeError` crash reproduced on this album**, 2 browsers. Operator, verbatim: *"this is what i see if i move fast"*. 10 → 10 |
| hard-va-compilation | *Now That's What I Call Music 116* | beets-terminal | yes | not run | not run | not run | not run | not run — operator decision (AMENDMENT B-3) |
| hard-va-compilation | *Now That's What I Call Music 116* | beets-flask | no | not measured | not measured | not measured | imported | 86%; 47 → 47, 3 non-audio correctly ignored. The 46-distinct-artist case cost nothing |
| hard-flat-multidisc | Lady Gaga — *Born This Way: The Collection* | beets-terminal | no | not run | not run | not run | not run | not run — operator decision (AMENDMENT B-3) |
| hard-flat-multidisc | Lady Gaga — *Born This Way: The Collection* | beets-flask | yes | not measured | not measured | not measured | imported | **75% accepted → 9 of 31 audio files silently dropped and 4 tracks mis-tagged onto different songs**, while the UI asserted *"All tracks on disk found online"*. Crash also reproduced here. `UNDO IMPORT` verified working |
| dj-no-match | *Mastermix Crate 068–070* (2025) | beets-terminal | yes | not run | not run | not run | not run | not run — operator decision (AMENDMENT B-3) |
| dj-no-match | *Mastermix Crate 068–070* (2025) | beets-flask | no | not measured | not measured | not measured | imported | Picker's best offer was a **44% wrong** match. `bootleg` instead: one `mv`, zero candidate decisions, 3 correct albums, 60/60 covers and 60/60 `TBPM` — but **no `track` tag at all** |

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

## AMENDMENT B — 2026-09-04, after the trial: what was measured and what was not

Added by plan 03-10 Task 3 **close**. **Nothing above this line was altered except the ten rows'
measurement cells.** The definitions, the wall-clock rule, the permitted `outcome` values, the
ordering control, the pre-assigned `went_first` alternation and AMENDMENT A are unchanged and
remain byte-identical to threshold commit `137b6d9e92cb44d9c6a48b3963bb33fe0194622f` for every
line above § *The sheet*. The `TBD` provenance paragraph is again left verbatim.

The operator ran the trial personally on 2026-09-04 and declared it complete. **This section is
written by the executor as scribe, not as instrument.** Where a number was not taken, the cell
reads `not measured` and the reason is below. No timing was synthesised, averaged or proxied.

### B-1. The two counters the trial did not produce, and why that is recorded rather than filled

**`wall_clock_s` and `interventions` were not systematically recorded by the operator**, on any
row except `clean-1`/terminal. The trial became decisive on a *defect* rather than on a stopwatch
— see B-4 — and the operator stopped counting once it did.

Those cells therefore read **`not measured`**, not `0` and not an estimate. This sheet exists
because the phase's whole premise is that this pipeline was built three times on unverified
assumptions; **a fabricated ergonomics figure would be worse than an absent one**, and it would be
undetectable afterwards. The qualitative observations in `stuck_points` stand in their place and
are the raw material the criterion 8 verdict is actually built from.

One timing does exist and is deliberately **not** entered in `wall_clock_s`: the `bootleg` run
self-reported *"Imported 39 seconds ago"* on completion. That is a **tool-reported import
duration**, which is a different quantity from this sheet's wall-clock rule (*"start the clock when
the operator first looks at the album"*). Recording it in that column would have redefined the
measurement to fit the number available. It is recorded here instead.

### B-2. The operator's `clean-1` row is preserved, and its `outcome` value reconciled visibly

The operator's own numbers — **`30` / `1` / `1`** — are preserved exactly and are the only
operator-authored measurements in this sheet.

The operator entered outcome **`tagged`**. That is **not one of the four permitted values** fixed
before the run (`imported` / `as-is` / `skipped` / `abandoned`). The cell now reads **`imported`**,
which is what was verified on disk: 21 of 21 files landed at
`/mnt/fast/spike-03/beets-config/library/Taylor Swift/1989 (Taylor's version)`, the diff being
punctuation and case only (`Taylor's Version` → `Taylor's version`, `To` → `to`).

**The original word is kept rather than silently corrected, because it is itself data.** On an arm
whose entire interaction was pressing `A` on an 87.7% match, an operator describing the result as
*"tagged"* rather than *"imported"* is an ergonomics observation: the terminal arm did not leave
them confident that an import had happened. That reading is offered, not asserted.

### B-3. Four terminal rows read `not run`, and that is an operator decision, not a gap

`clean-2`, `hard-va-compilation`, `hard-flat-multidisc` and `dj-no-match` were **never run through
the terminal arm.** The operator stopped after the flask arm's behaviour made the comparison
decisive.

`not run` is **deliberately outside** the permitted `outcome` set. That is the point: those rows
are not measurements with a missing value, they are rows that never happened, and collapsing them
into `skipped` or `abandoned` would misreport a decision not to measure as a measured outcome.

**What this costs, stated plainly.** The sheet is **1 of 5 albums** on the terminal arm and 5 of 5
on the flask arm. **No paired cross-arm comparison exists on four of the five albums**, so this
sheet does not support any quantitative claim that one front end is faster than the other. It
never will now.

**And what it does to the ordering control.** The alternation was not altered — but it was only
*exercised* on `clean-1`, where terminal ran first and flask second. On the other four albums the
flask arm ran with no prior pass over that album, so it took **no** second-pass familiarity
advantage there. On `clean-1` it did. Read in the flask arm's favour on four rows and against it
on one; either way the control cannot do the job it was designed for with one paired row.

### B-4. What actually decided it — recorded here because it is not a number

Three findings, all verified against LXC 100 on disk rather than read off the UI, and all
re-verified independently at close:

1. **The interactive picker cannot be relied on to import.** An intermittent full-page
   `TypeError` / *"Load failed"* crash, root-caused to a CORS-blocked third-party cover-art fetch
   with **no error boundary** around a cosmetic thumbnail. Reproduced on 2 albums across 2
   browsers. **The backend logged zero errors.** Intermittent is the worse finding: the operator
   cannot tell in advance whether a run is safe.
2. **`hard-flat-multidisc` imported silently and catastrophically wrong.** Accepted at 75%:
   **31 source files → 22 imported, 9 audio files dropped with no warning**, and 4 tracks written
   onto entirely different songs. **Re-verified at close:** `bf-clean/Lady Gaga/Born This Way`
   holds 22 files; the four titles beets wrote — `Born This Way (The Country Road version)`,
   `Judas (DJ White Shadow remix)`, `Marry the Night (Zedd remix)`,
   `Fashion of His Love (Fernando Garibay remix)` — **exist nowhere in the 31-file source folder**,
   and their durations (245 / 238 / 244 / 231 s) match four *different* source tracks
   (`Born This Way (Twin Shadow Remix)`, `Judas (Hurts Remix)`,
   `Marry The Night (The Weekend & Illangelo Remix)`, `You And I (Wild Beasts Remix)`). The last is
   a different song entirely. On that same screen the UI asserted *"All tracks on disk found
   online"* **and** *"All tracks online present on disk"*. Both false.
   **Bounded, not endemic** — re-verified at close: Taylor Swift 21→21, Garth Brooks 10→10,
   Now 116 47→47, **zero dropped**. The failure is specific to the flattened-two-releases shape.
3. **`bootleg` on a well-tagged DJ folder is the best result either arm produced.** Re-verified at
   close: 3 albums × 20 files, **`APIC` 60/60**, **`TBPM` 60/60**, `TALB` 60/60, `TCON` 60/60 —
   on a folder 03-07 measured at **zero** strict Discogs candidates. **`TRCK` 0/60**: no track tag
   at all, so playback order is undefined. And the same button shredded `Crate.071` into twenty
   single-track albums in Task 2 purely because that folder's `album` tag was empty, **with no UI
   signal distinguishing the two cases before the operator commits**.

### B-5. Friction 5 remains NOT EXERCISED — and a good flask showing is not evidence against it

Restated at close because this is exactly the point at which it would be tempting to forget.
**Five albums against a 144-folder backlog cannot test "laggy past some hundred folders."** This
was recorded in Task 1 and in `03-BEETS-FLASK.md` friction 5 **before any score existed**, and it
is preserved unchanged. Nothing in this sheet is evidence either way about the real backlog.

### B-6. Two asymmetries recorded in advance, now scored against

Both were fixed in AMENDMENT A before any number existed, and both bit:

1. **The watchdog pre-tags before the operator's clock starts.** All five albums showed scores
   (88 / 75 / 88 / 44 / 86%) before the operator looked. So any wall-clock advantage the flask arm
   *appears* to have is partly *"it started earlier"*, not *"it is quicker to drive"* — and since
   `wall_clock_s` was not measured, **no wall-clock advantage is claimed here at all.**
2. **The arms ran different beets versions** (2.13.1 terminal / 2.12.0 flask, pinned by rc6,
   OD-2) with an asserted-identical plugin set. Axis two scores interaction, not match quality.
   Note this cuts against reading finding B-4.2 as an indictment of *the front end*: a 22-track
   mis-match is an **engine/candidate** behaviour that the front end then *misdescribed*. The
   front-end failure is the false safety assertion, not the bad match.

### B-7. Estate safety at close — re-verified, and one acceptance criterion that cannot be met

| Assertion | Instrument | Result |
|---|---|---|
| All five trial sources intact | `find` per folder on LXC 100 | **169 audio files / 5 folders** — 60 + 31 + 47 + 21 + 10, matching the pre-trial stamp exactly |
| `copy` not `move` | the above | every source folder still at its original count; `dj-no-match` moved *between inboxes* by design, not consumed |
| Music freeze | `check-music-freeze.sh` **on LXC 100** | exit **0**, `tagger-class writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0`, and `consumer-class writers: 1` (Jellyfin, D-21) — the last confirms it was a *sighted* run, per DEF-03-11 |
| Music tree untouched by the trial | `find /mnt/tank/media/Music -newermt/-newerct '2026-09-04 09:00'` from atlantis | **0 / 0** |
| Real backlog untouched | `find /mnt/tank/downloads/complete/nzb -newermt '2026-09-04 09:00'` | **0 files** |
| `/` headroom (OD-1 floor 8 GiB) | `df -h /` | **34 G free of 126 G (72%)** |

**The plan's `zfs diff tank/media/Music@pre-project` returns clean` criterion is unsatisfiable as
written, and was already unsatisfiable before this trial began.** Run from atlantis it returns
**2,674 lines, all of them `M`** — and `find /mnt/tank/media/Music | wc -l` is **2,674**, i.e. the
diff covers the entire tree. That is the signature of Phase 1 plan 01-08's ownership normalisation
(`CLAUDE.md`: *"`568:568` across all 2,674 entries … verified from the Proxmox host and by
`zfs diff`"*) against a snapshot created **2026-08-18 13:08**, and it has been non-clean ever
since. **Zero `+`, `-` or `R` entries** — nothing created, deleted or renamed. The assertion the
criterion was reaching for holds on a better instrument: 0 files under Music have an mtime or
ctime inside the trial window. Logged as **DEF-03-19**.

---

## Criterion 8 — the week-six verdict

*To be written by the operator, in their own words, after the trial. Record the `stuck_points` that
produced it beside it.* **"It works" is not the finding — "it works and I will still open it" is.**

> **Restored verbatim by the orchestrator, 2026-09-04.** These two lines are the pre-committed
> rubric for this section from the plan-03-02 threshold commit `137b6d9e`. Plan 03-10's Task 3
> replaced them with the verdict below, which restates the same standard in the executor's own
> words. The substance was never lost — but the phase's rule is that pre-committed wording stays
> visible and is amended, never overwritten, so the original is reinstated here above the verdict
> rather than left superseded. The instruction it carries is **still outstanding**: the closing
> paragraph is scribe-assembled and awaits the operator's own words (see T3 in `03-DECISION.md`).

**Provenance of this section, stated first so it is not read as more than it is.** The operator ran
the trial and declared it complete, but recorded exactly **one** contemporaneous verbatim
`stuck_point`. The verdict below is therefore **assembled by the executor from verified
observations**, quoting the operator where the record quotes them. It is written this way rather
than left blank because the observations are strong and were verified on disk; it is labelled this
way because **a verdict in the operator's voice that the operator did not author would be the one
outcome this sheet exists to prevent.** The operator should replace or countersign the closing
paragraph in their own words before plan 03-11 closes axis two. T3 is recorded in
`03-DECISION.md` on exactly that basis.

The operator's one verbatim, on being asked to read the flask arm's diff modal before the page
crashed:

> **"this is what i see if i move fast"**

### The question, and the answer the trial supports

The question is not *"does it work"* — it is *"is this the combination I will still open in week
six"*.

**On the evidence collected, the beets-flask rc6 interactive picker is not that combination, and
the reason is not ergonomics.** It is that the arm produced, on a five-album trial, a **silent
9-file loss with 4 tracks mis-written onto different songs, underneath a UI that explicitly
asserted nothing was missing.** A front end whose job is to let a human review a match, and which
makes a false falsifiable safety claim on the one album where the match was wrong, has failed at
the thing it exists for. Add an intermittent full-page crash on a cosmetic thumbnail fetch that
the backend never logs, and the honest reading is that **rc6 is not yet a tool to point at 144
folders of irreplaceable content.** "Still in RC after eight months" stops being a version number
and becomes the finding.

**What is genuinely better in the flask arm, and should not be lost when rc6 is set aside:**

- **`UNDO IMPORT` works — verified reversal.** This contradicts a standing project constraint
  (`CLAUDE.md`: *"beets has no `undo` command — verified against the live CLI"*) and Phase 1 had to
  pair `library.db` backups with ZFS snapshots to get reversibility at all. **Plan 03-11 must pick
  this up**; it is the single most useful thing the trial found.
- **Per-folder persistent `Tagged`/`Imported` badges** — exactly the resume signal a 144-folder
  bulk run needs, which is the abandoned-halfway failure mode this project exists to prevent.
  The terminal arm needs `importsource` plus a query to answer the same question. **But** the
  Lady Gaga folder was badged `Imported` while 9 files short and 4 tracks wrong, so the badge
  cannot be trusted as a completion signal — and `DELETE IMPORTED FOLDERS` is keyed on it.
- **`copy` only, never `move`** — rc6 *cannot* do the dangerous thing the estate's real beets
  config (`import.move: yes`) currently does.
- **The track-diff modal and the `asis` expanded view** are materially better than the terminal
  arm dumping 21 tracks inline; the expanded view is what revealed `hard-flat-multidisc` as two
  flattened releases at a glance.
- **The UI editorialises match quality** — *"Really? This is what you're going with?"* on the 44%
  DJ match. On a collection where 03-07 measured **1 in 6** strict matches as wrong, that is a real
  safety affordance the terminal arm has no equivalent of.

**And the best single result either arm produced was not the picker at all.** `bootleg` on a
well-tagged DJ folder: one `mv`, zero candidate decisions, three correct albums, 60/60 covers,
60/60 `TBPM`, on content Discogs cannot match. That is the shape of the answer for ~76% of this
backlog. It is also unguarded — the same button destroys a folder whose `album` tag is empty, and
**~40% of sampled Mastermix folders carry the bare, useless `album=Mastermix`**, so the Crate
068–070 success is **not representative**. `bootleg` is a fast path for already-correctly-grouped
content, which is precisely PROJECT.md's *normalise first, then import* sequencing.

### T3 — will the operator sit at the interactive prompt?

**Not answered by this trial, and the sheet says so rather than inferring it.** The terminal arm
ran on **one** album, where the operator pressed `A` on an 87.7% match: 30 s, 1 intervention, 1
context switch, and they described the result as *"tagged"*. **One happy-path album is not a test
of whether someone will sit at a prompt for 144 folders** — D-09 asks for a self-assessment after
a hands-on trial, and the hands-on trial that happened was mostly of the other arm.

What the trial *does* establish is narrower and still useful: **the operator's tolerance was
exhausted by defects, not by the prompt.** They stopped running the terminal arm because the flask
arm had already decided the comparison, not because the prompt was unbearable.

### The one-line verdict, with its confidence stated

**Scribe-assembled, pending the operator's own words:** *axis two does not select beets-flask rc6's
interactive picker — it fails the review job it exists for, silently. It does surface four
affordances worth carrying forward (working undo, per-folder resume state, `copy`-only,
`bootleg`), and it leaves T3 open, because a one-album terminal arm did not test the prompt.*

**Confidence boundaries, so this is not over-read:**

- **Not** a wall-clock or intervention-count finding — neither was measured on 9 of 10 rows.
- **Not** evidence about the 144-folder case (friction 5, `NOT EXERCISED`).
- **Not** a finding about the beets *engine*: the 22-track mis-match is candidate behaviour, and
  the arms ran different beets versions (OD-2). The front-end failure is the false safety claim.
- **Not** a paired comparison: 1 terminal row against 5 flask rows.
