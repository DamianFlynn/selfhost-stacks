# Phase 5: Inbox Structure and the Junk Gate - Context

**Gathered:** 2026-09-18
**Status:** Ready for planning

<domain>
## Phase Boundary

**Filesystem triage, not tooling.** Content waits in a staging tree under `tank/downloads` where the
routing decision *is* a directory name — inspectable with `ls`, revertible with `mv`, surviving a
container restart with no database — and the junk that would corrupt every later measurement is
already out of the way.

All four ROADMAP criteria and all three requirements (INBX-01, INBX-02, INBX-03) are **pure
filesystem**. Not one of them names a container, a config file or a tagger.

**In scope:** creating `_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}` under
`tank/downloads`; quarantining bucket D on the music paths; splitting the 45 GB `Now! 1-115` folder
per volume; asserting no `_`-prefixed folder exists under `/mnt/tank/media/Music`; absorbing
`/mnt/tank/downloads/lidarr-import` (Phase 1 D-23); and one normalising `chown` pass over
`tank/downloads`.

**Explicitly NOT in scope:** standing up beets-flask (D-11 below moves it to Phase 6); configuring
the tagger (Phase 6, CONF-01…06); importing any content (Phase 7); the SABnzbd hook's eventual shape
(Phase 8); granting anything `rw` on `/mnt/tank/media/Music` — **Phase 1's D-20 still holds and
nothing here touches it.** This phase writes only under `tank/downloads`.

</domain>

<decisions>
## Implementation Decisions

### The reversibility fence

- **D-01: `tank/downloads@pre-phase5` is taken before anything moves, and it is the first act of the
  phase.** The existing `tank/downloads@pre-project` and `@pre-chown` snapshots are dated 2026-08-18
  — a month stale, with a month of unrelated downloads landed since, so rolling back to them would
  discard content this project never touched. Space is not a constraint: `tank/downloads` is 2.08 T
  used against 8.50 T available. `mv` has no undo and neither does `chown`.

### The `Now! 1-115` split (criterion 3, INBX-03)

Measured before the discussion: the real folder is
`complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023`, 45 G, **4,760 files, ZERO
subdirectories** — 4,746 mp3 plus 14 sidecars. A second folder of the same name under `dj-mixes/` is
512 B and empty; it is a decoy and is junk (D-07).

- **D-02: The m3u is the map; the `album` tag is the independent cross-check.** The 9,541-line
  `00.Now That's What I Call Music! 1-115(2023).m3u` carries each track's **original path** —
  `1993. Now That's What I Call Music! 25\CD2\01. 2 Unlimited - Tribal Dance.mp3` — giving both the
  volume number and the CD1/CD2 disc attribution the flatten destroyed. It names **116** distinct
  volume directories (115 volumes plus the collection root). Build the tree from it, then assert each
  file's `album` tag agrees. **On disagreement the file goes to `99-quarantine`, never to a guessed
  volume.** Two independent sources, which is the paired-instrument method that caught three
  defective instruments in 03-07.

- **D-03: Do NOT parse a trailing number off the `album` tag. It is a measured trap.** A full scan of
  all 4,746 mp3 returns **117 distinct album values for 115 volumes**, every file tagged, none empty.
  The excess and the trap:
  - Volume 1 is tagged `Now That's What I Call Music` — **no number at all**
  - Volume 2 is tagged `Now, That's What I Call Music II` — **Roman numeral, and a comma**
  - Volume 36 is split across **three** spellings: `…! Vol.36 CD1` (16 files),
    `…! Vol.36  CD2` (20 files, note the double space), `…! 36` (4 files)

  `…Vol.36 CD1` ends in `1` and `…Vol.36  CD2` ends in `2`, so a trailing-number regex **silently
  misfiles 36 tracks into volumes 1 and 2**. It exits 0 and looks right. This is the "confident wrong
  match" shape PROJECT.md § *Autotagging ceiling* warns about, arriving from a new direction.
  Punctuation also varies: 96 values spell it `Music!`, 19 spell it `Music`.

- **D-04: The 24-file gap is pre-declared, not chased.** The m3u lists **4,770** track entries; only
  **4,746** mp3 exist. All 24 are named **by path in the plan, before the run**, so a verifier meets a
  known figure rather than a discrepancy. This follows Phase 4's D-31 exactly, which pre-declared the
  residual `Audio.txt` lines so they could not be read as failure. The cause is almost certainly
  filename collision during the flatten; it is **not investigated** and **not treated as a blocker**.

- **D-05: Flat per-volume folders; the CD1/CD2 split is NOT restored.** Every file already carries
  `disc=1/2` and `track=01/22`. beets treats one directory as one album candidate, so handing it
  `Vol 79/CD1/` and `Vol 79/CD2/` risks matching them as two separate albums — the exact multi-disc
  shape QUAL-03 reserves for Phase 7 to exercise deliberately. Whether the **library** path format
  splits discs is Phase 6's decision (CONF-03), made at the path-format layer where it belongs.

- **D-06: The 115 volume folders are created INSIDE the existing `VA-Now_That.s…` folder, and the
  split moves `.mp3` only.** All **14 sidecars stay at that folder's root, untouched**: 3 `.m3u`,
  7 EAC `.log`, 1 `.cue`, 3 `.bmp`. The decisive reason — **one of those sidecars is the map D-02
  depends on.** Moving or scattering it would destroy the evidence trail the split is verified
  against. Keeping the rule to a single file type also keeps the reconciliation exact and
  exception-free. The `.log`/`.cue` do name specific volumes (110 ×2, 111 ×2, 113, 114, 115) and the
  `.bmp` (`cd1`, `cd2`, `back`) name none; **this is known and deliberately not acted on.**

- **D-07: The split moves in place under `unsorted/`, as atomic renames.** `_inbox/` and `unsorted/`
  are the same dataset (`devid=68`), so each move is an inode-preserving `rename(2)` — instant and
  free. `unsorted/` stays the immutable source ARCHITECTURE Pattern 5 describes; whole volumes are
  pulled into `_inbox/` in batches **later**, not in this phase. Reversibility comes from D-01, which
  is what makes a move safe rather than a copy necessary. The empty 512 B `dj-mixes/VA-Now_That.s…`
  decoy is junk and goes to `99-quarantine` under D-09.

- **D-08: Criterion 3's reconciliation target is 4,746 — the mp3 that provably exist.** Assert the sum
  of per-volume mp3 counts equals 4,746. The 24 manifest-only entries are reported **on their own
  line and never folded into the total**, so a bare number cannot read as a pass. This is the WRIT-01
  / criterion-5 shape Phase 4 used for the Jellyfin `rw` exception. Reconciling against the
  manifest's 4,770 was rejected: it would fail by 24 on every run and train everyone to ignore it.

### The junk gate (criterion 2, INBX-02)

Measured: 10 `_FAILED_`/`_UNPACK_` under `complete/nzb/` — only **4 are music** (`_UNPACK_Ed
Sheeran…`, `_UNPACK_Katy Perry - Prism (2013) FLAC`, `_FAILED_Garth.Brooks-Ropin.The.Wind…`,
`_FAILED_Garth.Brooks-The.Ultimate.Hits…`). The other **6 are TV and movies**. Plus 6 stray `.rar`,
3 of them inside those `_UNPACK_` directories and one a genuine stray
(`Def_Leppard-Slang-2LP-24BIT-FLAC-1995-REETKEVER.part001.rar`) in `music/`.

- **D-09: The sweep covers music paths only — `music/`, `unsorted/`, `dj-mixes/`, `lidarr-import/`
  and the new `_inbox/`.** The 6 TV/movie `_FAILED_` are Sonarr's and Radarr's, and their failure
  handling owns them; quarantining another service's failed jobs into a music-project folder would
  also go red again the moment those services fail anything. They are **not lost by this narrowing**
  — all six are named in `05-PREMEASURE.md` § 5.

- **D-10: Criterion 2 needs a dated in-band amendment, in the 02.1-11 / D-20 shape.** It is currently
  false in two separate ways, and **substance is preserved, never reduced**:
  1. **Scope.** It is written over "the download tree" and D-09 narrows it to the music paths. Quote
     the original wording, state the measurement (6 of 10 belong to other services), name the
     narrowing.
  2. **The Harry Potter clause.** It requires "the Harry Potter BluRay rip is out of `dj-mixes`", and
     a `find` over `dj-mixes` for `*potter*` returns **zero** — `dj-mixes` holds 630 mp3 + 134 wav +
     sidecars and no video at all. The clause was **written against the wrong tree**. The real item is
     `complete/nzb/unsorted/Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE`.
     Correct the criterion to name `unsorted/` and quarantine that folder — it is non-music sitting in
     the music backlog, which is precisely the harm the clause describes.

- **D-11: Everything moves to `99-quarantine`. Nothing is deleted.** Same-dataset rename, so it is
  atomic, instant and reversible with `mv`. This matches the standing posture DUPE-01 already states
  for the duplicate work ("quarantine, never `--delete`"). A dwell-then-purge policy was rejected for
  a concrete reason: **nothing in this estate is scheduled** — `quick-health-check.sh` is manual-only
  by decision (D-22, Phase 02.1) — so the purge would never fire and the folder would grow silently
  while appearing managed.

- **D-12: `/mnt/tank/downloads/incomplete` is entirely out of scope.** It is SABnzbd's live working
  directory, where `direct_unpack` drains jobs in flight at roughly one music job per 72 seconds.
  Moving anything out from under it can break an active download. The second Potter rip
  (`incomplete/Harry.Potter…hallowed`, carrying an `__ADMIN__` directory that suggests a stalled job)
  is **SABnzbd's to resolve, through SABnzbd** — not this phase's.

- **D-13: The sweep runs through the existing two-process approval gate.** A script enumerates
  candidates by rule and writes them to a file; the operator reads and approves that file; the move
  then acts **from the approved file, by name**. This is the pattern
  `scripts/spike03-image-headroom.sh` established and 02.1-09 ran successfully (4 rows approved
  unchanged, 1.45 GiB reclaimed). It catches the rule-shaped junk mechanically — `_FAILED_`,
  `_UNPACK_`, stray `.rar`, zero-audio directories, non-audio in a music path — while the decoy
  folder and the Potter rip get an explicit human yes. It also leaves the rules written down, which
  Phase 8's new inflow will need regardless.

### The inbox tree (criterion 1, INBX-01)

- **D-14: The tree is created empty. Only `99-quarantine` receives content**, from D-09's sweep.
  Criterion 1 asks that the tree exist and that a move between two of its folders be atomic — nothing
  more. Phase 6's dry run is a `--pretend` run that can read directly from `unsorted/` without
  anything being staged, so seeding is not a prerequisite it actually has.

- **D-15: beets-flask moves to Phase 6. Phase 5 fixes the paths it will consume.** This **amends
  Phase 4's D-01**, which deferred it *to* Phase 5 on the reasoning that *"Phase 5 is literally 'Inbox
  Structure'"*. Two reasons it moves again, and the first is the stronger:
  - Phase 5's four criteria and all three INBX requirements are pure filesystem. Standing up a
    container here is scope the phase's own success criteria do not contain.
  - D-01's own objection only half-dissolves. It rejected shipping it *"inert, at beets 2.12.0 (rc6's
    hard pin, below the 2.13.1 the engine was scored at), against inboxes that do not exist."* The
    inboxes now exist — **the version pin does not move**, and Phase 3's friction 9 stands: a
    `plugins:` string rejected by rc6's stricter schema kills the watchdog **while the server still
    serves a page**, so the inboxes go inert behind a UI that looks alive.

  Phase 5's deliverable toward it is the **exact inbox paths, recorded**, so Phase 6 configures
  against measured directories rather than intended ones.

- **D-16: `_inbox` is a plain directory and must NEVER become its own ZFS dataset — and the reason is
  recorded where the next person will find it.** A dataset would place `_inbox` on a different
  `devid` from `unsorted/` and `dj-mixes/`, turning every move into copy-then-unlink and **destroying
  criterion 1's atomic-rename property outright**. It looks like a tidy improvement (quota,
  independent snapshots — exactly what `fast/transcode` got in Phase 02.1), which is precisely why
  the prohibition needs writing down rather than assuming.

- **D-17: `_done/` holds the whole source folder, pruned per release only after CONS-04 passes.** The
  release migrates `unsorted/` → `01-auto/` → `_done/` as atomic renames, so reaching `_done/` costs
  no extra space. Phase 6 sets `import.copy: yes` (CONF-01), so the library holds a *copy* and
  `_done/` holds the original — **that original is the undo path**, and it matters because beets has
  no `undo` command. Pruned deliberately per release once verified in **both** Jellyfin and Music
  Assistant; **never on a timer** (same reason as D-11). A receipt-only `_done/` was rejected: it
  deletes the untouched copy at exactly the moment QUAL-02's before/after diff might reject the
  import.

- **D-18: `/mnt/tank/downloads/lidarr-import` is triaged and retired**, closing Phase 1's D-23 rather
  than passing it to Phase 8. It holds 2 artist folders (`Madonna`, `Michael Jackson`). Route both by
  the same rules as everything else — inbox or quarantine — then remove the directory, so the estate
  does not carry a fourth staging location nobody owns.

- **D-19: Criterion 1's inode proof is a synthetic fixture PLUS a cross-dataset negative control.**
  Move a throwaway fixture between two `_inbox` directories and assert the inode is **unchanged**;
  then move the same fixture across to `tank/media/Music` and assert the inode **does change**. The
  second half is the point — an inode that has only ever been observed staying the same is an
  instrument nobody has shown can distinguish anything. This is the estate's house rule from
  README § Health Checks: prove an assertion **capable of failing**, never merely observed passing.
  ⚠ The negative control writes into `/mnt/tank/media/Music`. Phase 1's D-20 says nobody holds `rw`
  there until Phase 6, so **this control must run from the Proxmox host, not from a container**, and
  must clean up after itself; the planner owns squaring that, and if it cannot be squared cleanly the
  control targets another dataset on a different `devid` instead — the property under test is
  "different devid changes the inode", not "Music specifically".

### Criterion 4 — a guard, not work

- **D-20: Criterion 4 is already green and becomes an assertion.** **Zero** `_`-prefixed directories
  exist anywhere under `/mnt/tank/media/Music`. Budget no effort for achieving it. Assert it **before
  and after** the phase's moves, so a staging-style name cannot leak into the library — MA silently
  ignores underscore-prefixed folders and Jellyfin does not, so the two consumers would diverge by
  design and neither would report an error.

### Ownership

Constraint that shapes all of this: everything on `tank` is mode **0777** and stays that way —
`chmod` fails `EPERM` even as real root under `aclmode=restricted` + `aclinherit=passthrough`. So in
the staging tree ownership governs **consistency and what later `stat` assertions can say**, not who
can write. `chown` cannot run from LXC 100 at all (sparse idmap); only from atlantis.

- **D-21: The six `_inbox` directories are created `568:568`, from atlantis.** Matches the library
  convention stated independently in `STANDARDS.md` (§ Volume Mounting), `DEPLOYMENT.md` (§ Storage
  conventions), `README.md` (§ Storage) and `PROJECT.md`, and matches what Phase 7's `stat` checks
  will expect.

- **D-22: All of `tank/downloads` is normalised to `568:568` in one verified sweep — operator
  decision, against the recommendation, and the reasoning is recorded so it is not re-litigated.**
  Scope is **all 209,039 entries**, `incomplete/` included. Verify with `zfs diff` the way Phase 1's
  01-08 did for the library. Note the scale: 197,776 of those entries are currently uid **3000** and
  this is **~74× the Phase 1 library operation** (2,674 entries), so it needs its own plan step and
  its own timing expectation.

  *The recommendation this overrides, kept because it is the counter-argument a reviewer will
  reconstruct:* Phase 1 normalised the **library** because it is exported over NFS, where ZFS
  `acltype=nfsv4` ACLs are not exported and mode bits are the only lever a client sees.
  `tank/downloads` is **not exported**, is 0777, and uid 3000 is the download client legitimately
  owning what it wrote.

- **D-23: One-time sweep, verified, with NO standing assertion — this is what "normalised" means at
  phase end.** The download client keeps writing as uid 3000 at roughly one job per 72 seconds, so
  new 3000-owned files appear almost immediately after the chown completes. **Do not add a health
  check asserting `568:568` across `tank/downloads`**: it would go red on the next download and train
  everyone to ignore it — the precise failure mode Phase 02.1's CR-01 spent four gap-closure plans
  repairing in the other direction. The measurement and its date are the deliverable. Changing
  SABnzbd's runtime identity to 568 was considered and rejected here: it reaches every category
  (tv, movies, software, readarr) and services this project does not own.

- **D-24: Content moved into `_inbox` is NOT chowned per-move; staging carries mixed ownership by
  design and the plan says so explicitly.** A rename preserves ownership, and adding a privileged
  chown to every move would contradict the one-atomic-rename property the whole design rests on.
  Under D-22 the tree-wide sweep makes this largely moot at phase end, but the **statement still
  matters**: it stops someone later writing an "everything under `_inbox` is `568:568`" assertion
  that D-23 guarantees will drift. The library-side guarantee is real and separate — the tagger
  writes fresh copies there, which is Phase 6/7's business.

### Ordering

- **D-25: Snapshot → create `_inbox` → junk sweep → `Now!` split → chown last.** Snapshot first so
  everything after it is reversible (D-01). Chown **last**, as a single pass, so it also normalises
  the 115 volume directories and the six `_inbox` directories this phase just created, and so the
  drift window under D-23 is as short as possible before the phase closes. **Each step is
  independently resumable**: an interrupted split leaves each volume either moved or not, readable
  with `ls`, which is the entire point of filesystem-as-queue and the direct answer to a project
  that has been abandoned three times.

### Claude's Discretion

- Plan decomposition within the D-25 ordering, subject to two fixed constraints: **D-01's snapshot is
  the first act**, and **D-13's approval gate blocks the junk move** — the script may enumerate
  before approval, it may not move before approval.
- Exact wording of D-10's in-band ROADMAP/REQUIREMENTS amendments, following the 02.1-11 shape:
  quote the original, state the measurement, name the change, preserve substance.
- How D-19's negative control is squared against Phase 1's D-20 (host-side, or an alternative dataset
  on a different `devid`).
- The exact rule list D-13's enumerator implements, beyond the four patterns criterion 2 names.
- Whether the 24 files in D-04 are listed inline in the plan or in a referenced artifact — they must
  be named by path *somewhere* before the run either way.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Measurements this phase is built on — read FIRST
- `.planning/phases/05-inbox-structure-and-the-junk-gate/05-PREMEASURE.md` — read-only measurements
  from atlantis, 2026-09-18. § 1 the `devid=68` vs `devid=76` finding that makes criterion 1
  satisfiable; § 2 the stale fence (D-01); § 3 the flat 4,760-file shape; § 4 the Harry Potter
  mis-specification (D-10); § 5 the arrs scope question (D-09); § 6 criterion 4 already green (D-20);
  § 8 `dj-mixes`'s 84 inconsistent top-level names, carried to Phase 6 not actioned here.
  **Read its § Limits** — every count is a point-in-time read on a tree written to at ~1 job per
  72 s, and must be re-measured at plan time.

### Phase scope and requirements
- `.planning/ROADMAP.md` § *Phase 5: Inbox Structure and the Junk Gate* — the four success criteria.
  Criterion 2 is amended by D-10; criterion 3's wording is corrected by D-02/D-05; criterion 4 is
  already satisfied per D-20.
- `.planning/REQUIREMENTS.md` — INBX-01 (lines 159–160), INBX-02 (161–162), INBX-03 (163–164).
- `.planning/PROJECT.md` § *Constraints* — the `0777`/`aclmode=restricted` chmod bar, the separate-
  datasets / `EXDEV` fact, the `rsync -a` failure mode and its working invocation, and the
  `568:568` ownership decision.

### The design this phase implements
- `.planning/research/ARCHITECTURE.md` § *Recommended Structure* — the `_inbox` tree, and the
  "`_inbox/` sits under `tank/downloads`, not under `media/`" rationale including why Jellyfin's
  `.ignore` is not a safe workaround (jellyfin#14502).
- `.planning/research/ARCHITECTURE.md` § *Pattern 5: Filesystem-as-Queue* — the resumability model
  D-25 rests on, and the `unsorted/` → `_inbox/` → `_done/` transitions.
- `.planning/research/ARCHITECTURE.md` § *Pattern 4: Copy In, Never Move In* — the `EXDEV` /
  block-cloning detail behind D-07 and D-16.
- `.planning/research/SUMMARY.md` § *Phase 5* — the underscore-naming note behind D-20.

### Decisions this phase amends or inherits
- `.planning/phases/04-collapse-to-one-tagger/04-CONTEXT.md` § D-01 — deferred beets-flask to
  Phase 5; **amended by D-15**, which moves it to Phase 6. Read D-01's stated objection before
  disagreeing.
- `.planning/phases/04-collapse-to-one-tagger/04-CONTEXT.md` § D-31 — the pre-declaration pattern
  D-04 follows.
- `.planning/phases/03-tagger-spike/03-DECISION.md` § *Axis two* — beets-flask's policy-carrying
  inbox architecture is the chosen front end; friction 9 (rc6 schema rejection killing the watchdog
  behind a live-looking page) is cited by D-15.
- Phase 1 D-20 — nobody holds `rw` on `/mnt/tank/media/Music` until Phase 6. Constrains D-19.
- Phase 1 D-23 — Phase 5 absorbs `lidarr-import`. Closed by D-18.
- `.planning/STATE.md:1115` — the uid-3000 carry-in ("resolve before Phase 5 stages `_inbox` there").
  Answered by D-22/D-23.

### The durable estate record and house rules
- `stacks/selfhosted/arrs/beets.md` — the durable record beside the stack; this phase's closure
  section lands here, as Phases 1, 2, 02.1 and 4 each did.
- `README.md` § *Health Checks* — the three rules any assertion this phase adds must follow: fail
  closed with "could not look" kept distinct from "nothing is wrong"; bound remote commands
  **Linux-side**; assert rather than report. Note `timeout N cmd | wc -l` silently exits 0.
- `scripts/spike03-image-headroom.sh` — the two-process approval gate D-13 reuses.
- `CLAUDE.md` § *Storage and Permissions* — service account `568:568`, repo path `/mnt/fast/stacks`.
- `DEPLOYMENT.md` — git is the delivery path; a commit must reach `origin` before LXC 100 can pull.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`scripts/spike03-image-headroom.sh`** — the enumerate → operator-approves-file → act-from-file
  gate. D-13 reuses its shape directly; 02.1-09 proved it works on a real destructive-ish operation.
- **Phase 1's `zfs diff` verification method (01-08)** — D-22 reuses it to verify the chown, at ~74×
  the entry count.
- **`/mnt/fast/safety`** — Phase 1's fence, on a path no tagger container mounts. Available if any
  sidecar or manifest needs archiving.
- **`scripts/quick-health-check.sh`** — the standing-check entry point. D-20's criterion-4 assertion
  is a natural fold-in; **D-23 explicitly forbids** a `tank/downloads` ownership assertion there.
- **The in-band dated amendment shape (02.1-11, and Phase 4's D-20)** — quote the original, state the
  measurement, name the change, preserve substance. D-10 needs it twice.

### Established Patterns
- Host-resident scripts under `scripts/`, `#!/usr/bin/env bash`, `set -euo pipefail`, ALL-CAPS
  constants, run from `/mnt/fast/stacks` after a `git pull`.
- A `.md` beside the stack it documents. Operational detail lives beside the thing it describes.
- Prove an assertion **capable of failing** with a driven negative control (D-19).
- Pre-declare expected-but-odd observations so a verifier cannot read them as failure (D-04).

### Integration Points and Hazards
- **`zfs` cannot exist on LXC 100** (unprivileged) — snapshot and `chown` go via
  `ssh root@172.16.1.158`. `rsync`, `tmux` and `screen` are **not installed** on LXC 100.
- **`chmod` fails `EPERM` everywhere on `tank`**, even as real root. Do not plan a mode change.
- **`chown` fails from LXC 100** for a different reason (sparse idmap) — atlantis only.
- **`rsync -a` fails writing to `tank`** (`mkstemp … Operation not permitted`) while printing stats
  that look like success and exiting 23. Use `rsync -rlt --no-p --no-o --no-g` if any copy is needed.
- **A container-side listing showing `65534` is LXC 100's view, not the disk.** Phase 1 lost time to
  this. Check from atlantis before believing any ownership reading.
- **ZFS frees space asynchronously** — `zfs list` can lag a large delete by ~20 s.
- **The download tree is live**, written at roughly one music job per 72 s. Every count in
  `05-PREMEASURE.md` and in this file will drift; re-measure at plan time. This is also why D-12
  rules `incomplete/` out.
- **`docker ps` filters on `status=restarting/dead/exited` MISS `created`** — a documented estate
  blind spot; any container assertion must use no status filter.
- **Jellyfin's freeze gates the automatic save path only.** An explicit `FullRefresh` still writes
  `.nfo` — which is a second reason nothing gets staged under `/media/Music`, reinforcing D-20.

</code_context>

<specifics>
## Specific Ideas

- **The volume-number trap in D-03 is worth landing verbatim in the plan, not paraphrased.** A
  trailing-number regex over the `album` tag is the obvious first implementation, it exits 0, and it
  misfiles 36 tracks into volumes 1 and 2. A paraphrase risks the next reader re-deriving the obvious
  approach. Name `Vol.36 CD1` / `Vol.36  CD2` explicitly, double space included.
- **D-06's real reason is evidentiary, not tidiness.** The map and the content it verifies stay
  together. If the plan reorders anything here, that is the constraint to preserve.
- **D-19's negative control is the more interesting half**, exactly as Phase 4's D-17 negative control
  was. An inode that stayed the same proves nothing until the instrument has been seen to change.
- The operator's Phase 3 verdict still governs how evidence is presented: *"It's fine for a bot to
  drive us, but for me, as a human, no."* Agent-driven operations are fine; D-13's gate is a **read
  and approve a file**, not a sit-at-a-prompt.
- D-22 was taken **against the stated recommendation**. The counter-argument is preserved in the
  decision itself so a future reviewer meets reasoning rather than silence — the same style
  PROJECT.md uses for its `sec=sys` and Discogs-rotation rows.

</specifics>

<deferred>
## Deferred Ideas

- **beets-flask stack definition and configuration** — Phase 6 (D-15). Carry Phase 3's friction 9 with
  it: rc6 hard-pins beets 2.12.0 (below the measured 2.13.1), and a `plugins:` string its stricter
  schema rejects kills the watchdog while the server still serves a page. **Also unresolved and worth
  a research step:** whether beets-flask has shipped past `2.0.0-rc6` since 2026-09-04, which would
  change the version-pin half of D-15's reasoning.
- **`dj-mixes`'s 84 inconsistent top-level names** — `Mastermix_Issue_410` beside
  `Mastermix_Issue_410.1`, `Mastermix.Issue.420.2021` in a different separator style, eight ending in
  a truncated-looking bare `_-`, and Now! compilations (`__118__`, `__119__`) inside a folder named
  for Mastermix. Folder names feed tagger candidate selection and the Discogs lookups, so this is
  **Phase 6 matching work, not inbox structure** (`05-PREMEASURE.md` § 8).
- **The 6 TV/movie `_FAILED_` directories** — out of scope by D-09, named in `05-PREMEASURE.md` § 5
  for whoever owns those stacks.
- **The stalled `incomplete/Harry.Potter…hallowed` job** with its `__ADMIN__` directory — SABnzbd's to
  clear through SABnzbd (D-12). Worth mentioning to Phase 8, which owns the hook.
- **Investigating why the 24 Now! tracks vanished in the flatten** — pre-declared, not chased (D-04).
  Re-acquisition is not scoped by this project.
- **Changing SABnzbd's runtime identity to uid 568** — considered and rejected under D-23; it reaches
  every download category and services this project does not own.
- **`_done/` pruning mechanics at backlog scale** — D-17 fixes the policy (per release, after CONS-04)
  but Phase 9's batch cadence is what makes it operationally real.
- **DUPE-01 / DUPE-02** — still needs a roadmap decision before Phase 7. Phase 1 measured 828
  duplicate groups / 19.4% duplication and Phase 3 re-confirmed `dj-mixes` is a byte-for-byte
  duplicate subset of `unsorted`, which makes Phase 7's diff join **last-wins** — a silent behaviour
  rather than a chosen one. Unchanged by this phase; carried forward so it is not lost.
- **`/mnt/tank/media/TV` on the orphan gid 545** — 114,218 entries, outside this milestone.

</deferred>

---

*Phase: 5-inbox-structure-and-the-junk-gate*
*Context gathered: 2026-09-18*
