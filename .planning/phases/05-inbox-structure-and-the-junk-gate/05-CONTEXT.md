# Phase 5: Inbox Structure and the Junk Gate - Context

**Gathered:** 2026-09-18
**Status:** Ready for planning
**Revised:** 2026-09-18, same session — operator corrections on the Potter item, sidecar triage and
tag correctness. See `05-DISCUSSION-LOG.md` § *Operator corrections* for what changed and why.

<domain>
## Phase Boundary

**Filesystem triage, plus one narrow tag repair.** Content waits in a staging tree under
`tank/downloads` where the routing decision *is* a directory name — inspectable with `ls`, revertible
with `mv`, surviving a container restart with no database — and the junk that would corrupt every
later measurement is reviewed and gone.

Three of the four ROADMAP criteria and all three requirements (INBX-01…03) are pure filesystem. **One
deliberate exception:** D-10 writes the `album` tag on the `Now!` collection, because the split
produces folders that are only coherent if each one carries a single album string. This is scoped to
**one field, on one collection**, and is the operator's explicit instruction that *"the tags should be
correct if at all possible"*. Every other tag decision stays in Phase 6.

**Why the tag write is safe to do here:** QUAL-01's before-state snapshot is keyed on `audio_md5` —
the encoded bitstream, not the container — so writing a tag **does not break the snapshot's join
key**. Phase 7's field-level diff can still compare these files against their before-state. This is
the property that makes the exception affordable; if the snapshot were keyed on a file hash it would
not be.

**In scope:** creating `_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}` under
`tank/downloads`; reviewing and deleting bucket D on the music paths; splitting the 45 GB
`Now! 1-115` folder per volume; canonicalising that collection's `album` tag; asserting no
`_`-prefixed folder exists under `/mnt/tank/media/Music`; absorbing
`/mnt/tank/downloads/lidarr-import` (Phase 1 D-23); and one normalising `chown` pass over
`tank/downloads`.

**Explicitly NOT in scope:** standing up beets-flask (D-16 moves it to Phase 6); configuring the
tagger (Phase 6, CONF-01…06); importing any content (Phase 7); any tag field other than `album`, on
any collection other than `Now!`; the SABnzbd hook's eventual shape (Phase 8); granting anything `rw`
on `/mnt/tank/media/Music` — **Phase 1's D-20 still holds and nothing here touches it.** Every write
this phase performs lands under `tank/downloads`.

</domain>

<decisions>
## Implementation Decisions

### The reversibility fence

- **D-01: `tank/downloads@pre-phase5` is taken before anything moves, and it is the first act of the
  phase.** The existing `@pre-project` and `@pre-chown` snapshots are dated 2026-08-18 — a month
  stale, with a month of unrelated downloads landed since, so rolling back to them would discard
  content this project never touched. Space is not a constraint: `tank/downloads` is 2.08 T used
  against 8.50 T available. `mv` has no undo, `chown` has no undo, and **as of D-10 this phase also
  writes tags** — which raises the snapshot from prudent to required.

### What was measured about the `Now!` collection

All figures below are from a full scan of every file on 2026-09-18, not a sample. They are the
evidence the next five decisions rest on.

| Measurement | Value |
|---|---|
| Real folder | `complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023`, 45 G |
| Shape | **4,760 files, ZERO subdirectories** — 4,746 mp3 + 14 sidecars |
| Files missing a `disc` tag | **0 of 4,746** |
| Files missing a `track` tag | **0 of 4,746** |
| Distinct `disc` formats | only three — `1/2` (2,361), `2/2` (2,339), `1/1` (46) |
| Distinct `album` values | **117**, for 115 volumes |
| m3u manifest entries | **4,770** — 24 more than exist on disk |
| Volume directories named in the m3u | 116 (115 volumes + the collection root) |
| Volumes failing `files == sum(tracktotal)` | **13** |

A second folder of the same name under `dj-mixes/` is 512 B and empty. It is a decoy and it is junk.

- **D-02: The m3u is the map; the `album` tag is the independent cross-check.** The 9,541-line
  `00.Now That's What I Call Music! 1-115(2023).m3u` carries each track's **original path** —
  `1993. Now That's What I Call Music! 25\CD2\01. 2 Unlimited - Tribal Dance.mp3` — giving both the
  volume number and the CD1/CD2 attribution the flatten destroyed. Build the tree from it, then
  assert each file's `album` tag agrees. **On disagreement the file goes to `99-quarantine`, never to
  a guessed volume.** Two independent sources: the paired-instrument method that caught three
  defective instruments in 03-07.

- **D-03: Do NOT parse a trailing number off the `album` tag. It is a measured trap, and it must be
  recorded verbatim rather than paraphrased.** The 117 values include:
  - Volume 1 tagged `Now That's What I Call Music` — **no number at all**
  - Volume 2 tagged `Now, That's What I Call Music II` — **Roman numeral, and a comma**
  - Volume 36 split across **three** spellings: `…! Vol.36 CD1` (16 files), `…! Vol.36  CD2`
    (20 files, **note the double space**), `…! 36` (4 files)

  `…Vol.36 CD1` ends in `1` and `…Vol.36  CD2` ends in `2`, so a trailing-number regex **silently
  misfiles 36 tracks into volumes 1 and 2**. It exits 0 and looks right. Punctuation varies too: 96
  values spell it `Music!`, 19 spell it `Music`. A trailing-number parse is the obvious first
  implementation, which is exactly why the prohibition is written down.

- **D-04: The 24-file gap is pre-declared — and it is now LOCATABLE, not merely counted.** Because
  every file carries a coherent `disc` and `track`, the per-volume identity
  **`files_present == Σ tracktotal across that volume's discs`** resolves the gap to named volumes:

  | Shape | Volumes |
  |---|---|
  | Short by 1 | 15, 18, 39, 52, 70, 83, 98 |
  | Short by 2 | 3 |
  | **Surplus** (more files than tracktotals) | 4 (+13), 8 (+9), 9 (+14) |
  | Split-tag mess | `! 36` 4 files/expected 20; `Vol.36 CD1` 16/expected 20 |

  Name these in the plan **before the run**, per Phase 4's D-31 pattern, so a verifier meets a known
  list rather than a discrepancy. The cause of the shortfalls is almost certainly filename collision
  during the flatten; it is **not investigated and not a blocker**.

  ⚠ **The three surplus volumes are a different animal and the plan must not conflate them.** 4, 8
  and 9 are all `[2019 Reissue]` volumes. More files than tracktotals means either the reissue
  genuinely carries more tracks than the tags claim, or files from another volume are mis-tagged into
  these. The second possibility would corrupt the split. **Resolve before or during the split, and
  record which it was** — do not carry it forward as "flagged" without an answer.

- **D-05: Flat per-volume folders; the CD1/CD2 split is NOT restored — and the tags support this
  directly.** Every file already carries `disc=1/2`-style values with zero omissions, and the maximum
  disc count is 2. beets treats one directory as one album candidate, so handing it `Vol 79/CD1/` and
  `Vol 79/CD2/` risks matching them as two separate albums — the multi-disc shape QUAL-03 reserves
  for Phase 7 to exercise deliberately. **This is the operator's instruction directly:** all discs of
  a volume live in one folder, and the tags carry the disc structure. Whether the *library* path
  format splits discs is Phase 6's call (CONF-03), made at the path-format layer where it belongs.

- **D-06: Sidecars are triaged BY VALUE, individually, not kept or discarded by file type.**
  *(Operator correction — supersedes the earlier "all 14 stay at root untouched".)* Most sidecars are
  junk, but some carry real context: a scan of the CD case with track listings, an `.nfo` or `.m3u`
  with context. **If it has value it is kept; otherwise it is queued to `99-quarantine` for review and
  deletion** under D-13. The verdicts below were reached **by opening the files**, which is the point
  — file type alone does not tell you:

  | Sidecar | What it actually is | Verdict |
  |---|---|---|
  | `00.Now…1-115.m3u` (9,541 lines) | **The map D-02 depends on** — original path per track | **Keep**, at the collection root |
  | `back.bmp` (6.4 MB) | **NOW 77 back cover** — full tracklists for both discs, barcode, cat. no. `UK:CDNOW77` | **Keep** → volume 77 |
  | `cd1.bmp` (4.3 MB) | **NOW 77 disc 1** face — artwork, same catalogue number | Keep → volume 77 |
  | `cd2.bmp` (4.3 MB) | Presumed NOW 77 disc 2 — **NOT individually opened; verify at execution** | Keep → volume 77 (pending that check) |
  | `NOW…115.cue` | EAC cue sheet for vol 115 — per-track `TITLE` and `PERFORMER` | **Keep** → volume 115 |
  | 7 × `.log` (19–23 KB each) | EAC rip-verification logs (vols 110 ×2, 111 ×2, 113, 114, 115) | → `99`, review & delete |
  | `play.m3u` (97 lines), `00. play.m3u` (51 lines) | Small playlists, `CD1\` relative paths, no volume identity | → `99`, review & delete |

  **The decisive finding is that the scans belong to volume 77, not 115** — the `.cue`/`.log` are
  110–115 and the `.bmp` are 77, so the sidecars are scattered leftovers from *different* volumes,
  whatever happened to survive the flatten. Value-bearing sidecars therefore **follow the volume they
  actually belong to**, which can only be determined by reading them. The map is the one exception
  and stays at the root, beside the collection it maps.

  **`back.bmp` earned its keep twice over:** it independently corroborates the tags. It states 44
  tracks, CD1 1–22 and CD2 1–22; the tags for volume 77 read 44 files, disc 1 `tracktotal=22`,
  disc 2 `tracktotal=22`. Scan, tags and file count agree three ways. It also carries a barcode and
  catalogue number, which is a precise release identifier for the Discogs/MusicBrainz lookup Phase 6
  will need for exactly this series (CONF-05's UK/US disambiguation).

- **D-07: The split moves in place under `unsorted/`, as atomic renames.** `_inbox/` and `unsorted/`
  are the same dataset (`devid=68`; `tank/media/Music` is `devid=76`), so each move is an
  inode-preserving `rename(2)` — instant and free. The 115 volume directories are created **inside**
  the existing `VA-Now_That.s…` folder; `unsorted/` stays the immutable source ARCHITECTURE Pattern 5
  describes, and whole volumes are pulled into `_inbox/` in batches **later**, not in this phase.
  Reversibility comes from D-01. The empty 512 B `dj-mixes/VA-Now_That.s…` decoy is junk and goes to
  `99-quarantine` under D-11.

- **D-08: Reconciliation is per-volume, not a single total.** The headline assertion is that the sum
  of per-volume mp3 counts equals **4,746** — what provably exists and what the split actually moves.
  But the **real instrument is D-04's per-volume identity**, `files == Σ tracktotal`, which is
  strictly stronger: a bare total of 4,746 would pass even if every file landed in the wrong folder.
  Assert both. The 24 manifest-only entries are reported **on their own line and never folded into
  the total**, so a bare number cannot read as a pass — the WRIT-01 / criterion-5 shape Phase 4 used
  for the Jellyfin `rw` exception. Reconciling against the manifest's 4,770 was rejected: it would
  fail by 24 on every run and train everyone to ignore it.

- **D-09: The 13 incomplete volumes are split anyway and flagged in the record.** Every volume gets
  its folder. The 13 are named with their shortfall or surplus in the phase record so Phase 7 and
  Phase 9 meet a known list. An incomplete `Now!` volume is still importable — it is a compilation,
  not a broken album — and routing them to `04-hold` was rejected because that folder is scoped for
  content needing *artwork or tracklist* sourcing, not missing audio. D-04's ⚠ still applies to
  volumes 4, 8 and 9: flagging is not a substitute for answering what their surplus means.

- **D-10: Phase 5 canonicalises the `album` tag on this collection — that field only, nothing else.**
  *(Operator instruction: "the tags should be correct if at all possible.")* The measurement splits
  cleanly: `disc` and `track` are **already correct** — zero omissions across 4,746 files and the
  per-volume arithmetic lands exactly on the volumes that are complete. **`album` is the one field
  that is wrong**, and it is wrong in a way that breaks the deliverable: volume 36's folder would
  otherwise contain three different album strings, and beets would not see one album.
  - Scope is **one field, one collection**. Not `artist`, not `title`, not the BPM-in-title problem —
    those are Phase 6 and the DJ work.
  - Run it **after** the split, per volume folder: the folder is already the grouping, so the repair
    is "set every file in this folder to this one canonical string".
  - Reuse `scripts/normalise-dj-tags.py`, which is **already dry-run-by-default with a field-loss
    gate** and was repaired for the WAV path in Phase 4 (D-23). Do not write a second tool.
  - The QUAL-01 snapshot is keyed on `audio_md5`, so this write **does not break Phase 7's diff join**
    (see `<domain>`). State that in the plan — it is the reason this is affordable.
  - Fixing volumes 4/8/9's `tracktotal` disagreement was explicitly **declined for this phase**: it
    needs D-04's investigation first, and guessing a tracktotal is worse than leaving it flagged.

### The junk gate (criterion 2, INBX-02)

Measured: 10 `_FAILED_`/`_UNPACK_` under `complete/nzb/` — only **4 are music** (`_UNPACK_Ed
Sheeran…`, `_UNPACK_Katy Perry - Prism (2013) FLAC`, `_FAILED_Garth.Brooks-Ropin.The.Wind…`,
`_FAILED_Garth.Brooks-The.Ultimate.Hits…`). The other **6 are TV and movies**. Plus 6 stray `.rar`,
3 of them inside those `_UNPACK_` directories and one a genuine stray
(`Def_Leppard-Slang-2LP-24BIT-FLAC-1995-REETKEVER.part001.rar`) in `music/`.

- **D-11: `99-quarantine` is a REVIEW-AND-DELETE queue, not an archive.** *(Operator correction —
  supersedes the earlier "move to 99-quarantine, delete nothing".)* Junk moves to `99-quarantine`,
  the operator reviews the list, and **approved items are deleted inside this phase**. Deletion is
  the expected terminal state for junk, not a deferred maybe. The earlier "delete nothing" position
  was rejected for a concrete reason that still holds in the new shape: nothing in this estate is
  scheduled — `quick-health-check.sh` is manual-only by decision (D-22, Phase 02.1) — so a
  dwell-then-purge policy would never fire. The fix is to **do the review now**, not to keep the
  content forever. The phase ends with `99-quarantine` empty, or holding only what the operator
  deliberately kept.

- **D-12: The sweep covers music paths only — `music/`, `unsorted/`, `dj-mixes/`, `lidarr-import/`
  and the new `_inbox/`.** The 6 TV/movie `_FAILED_` belong to Sonarr and Radarr, whose failure
  handling owns them; quarantining another service's failed jobs into a music-project folder would
  also go red again the moment those services fail anything. They are **not lost by this narrowing**
  — all six are named in `05-PREMEASURE.md` § 5. Criterion 2 is written over "the download tree", so
  this narrowing needs a **dated in-band amendment** in the 02.1-11 / D-20 shape: quote the original
  wording, state the measurement, name the narrowing. Substance preserved, never reduced.

- **D-13: The sweep runs through the existing two-process approval gate, and that gate IS the
  review.** A script enumerates candidates by rule and writes them to a file; the operator reads and
  approves that file; the tool then acts **from the approved file, by name** — moving to
  `99-quarantine` and then deleting what was approved. This is the pattern
  `scripts/spike03-image-headroom.sh` established and 02.1-09 ran successfully (4 rows approved
  unchanged, 1.45 GiB reclaimed). It catches rule-shaped junk mechanically — `_FAILED_`, `_UNPACK_`,
  stray `.rar`, zero-audio directories, non-audio in a music path — while the decoy folder, the
  low-value sidecars and the video rip get an explicit human yes. It also leaves the rules written
  down, which Phase 8's new inflow needs regardless. **The gate is a read-and-approve-a-file step,
  never a sit-at-a-prompt step** — the operator's Phase 3 verdict governs: *"It's fine for a bot to
  drive us, but for me, as a human, no."*

- **D-14: The Harry Potter rip is ordinary junk and gets no special handling.** *(Operator
  correction — supersedes the earlier treatment of this as a criterion-blocking question.)* It is a
  video in a music folder; it goes through D-13's gate with everything else and is deleted. The item
  is `complete/nzb/unsorted/Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE`.
  Criterion 2's clause says "out of `dj-mixes`" and `dj-mixes` contains no video at all (630 mp3 +
  134 wav + sidecars, `find` for `*potter*` returns zero), so **the criterion names the wrong tree**.
  Correct that as a one-line factual note inside D-12's amendment — **it does not need an amendment
  of its own and it is not a blocker.** Refiling it to the movies tree was rejected: this phase does
  not hand content to another service's import path uninvited.

- **D-15: `/mnt/tank/downloads/incomplete` is entirely out of scope.** It is SABnzbd's live working
  directory, where `direct_unpack` drains jobs in flight at roughly one music job per 72 seconds.
  Moving or deleting anything under it can break an active download. The second Potter rip
  (`incomplete/Harry.Potter…hallowed`, carrying an `__ADMIN__` directory suggesting a stalled job) is
  **SABnzbd's to resolve, through SABnzbd** — not this phase's.

### The inbox tree (criterion 1, INBX-01)

- **D-16: beets-flask moves to Phase 6. Phase 5 fixes the paths it will consume.** This **amends
  Phase 4's D-01**, which deferred it *to* Phase 5 on the reasoning that *"Phase 5 is literally
  'Inbox Structure'"*. Two reasons it moves again, the first being the stronger:
  - Phase 5's criteria and all three INBX requirements are filesystem work. Standing up a container
    here is scope the phase's own success criteria do not contain.
  - D-01's own objection only half-dissolves. It rejected shipping it *"inert, at beets 2.12.0 (rc6's
    hard pin, below the 2.13.1 the engine was scored at), against inboxes that do not exist."* The
    inboxes now exist — **the version pin does not move**, and Phase 3's friction 9 stands: a
    `plugins:` string rejected by rc6's stricter schema kills the watchdog **while the server still
    serves a page**, so the inboxes go inert behind a UI that looks alive.

  Phase 5's deliverable toward it is the **exact inbox paths, recorded**, so Phase 6 configures
  against measured directories rather than intended ones.

- **D-17: The tree is created empty. Only `99-quarantine` receives content**, transiently, from
  D-13's sweep. Criterion 1 asks that the tree exist and that a move between two of its folders be
  atomic — nothing more. Phase 6's dry run is a `--pretend` run that can read directly from
  `unsorted/` without anything being staged, so seeding is not a prerequisite it actually has.

- **D-18: `_inbox` is a plain directory and must NEVER become its own ZFS dataset — and the reason is
  recorded where the next person will find it.** A dataset would place `_inbox` on a different
  `devid` from `unsorted/` and `dj-mixes/`, turning every move into copy-then-unlink and **destroying
  criterion 1's atomic-rename property outright**. It looks like a tidy improvement (quota,
  independent snapshots — exactly what `fast/transcode` got in Phase 02.1), which is precisely why
  the prohibition needs writing down rather than assuming.

- **D-19: `_done/` holds the whole source folder, pruned per release only after CONS-04 passes.** The
  release migrates `unsorted/` → `01-auto/` → `_done/` as atomic renames, so reaching `_done/` costs
  no extra space. Phase 6 sets `import.copy: yes` (CONF-01), so the library holds a *copy* and
  `_done/` holds the original — **that original is the undo path**, and it matters because beets has
  no `undo` command. Pruned deliberately per release once verified in **both** Jellyfin and Music
  Assistant; never on a timer. A receipt-only `_done/` was rejected: it deletes the untouched copy at
  exactly the moment QUAL-02's before/after diff might reject the import.

- **D-20: `/mnt/tank/downloads/lidarr-import` is triaged and retired**, closing Phase 1's D-23 rather
  than passing it to Phase 8. It holds 2 artist folders (`Madonna`, `Michael Jackson`). Route both by
  the same rules as everything else — inbox or quarantine — then remove the directory, so the estate
  does not carry a fourth staging location nobody owns.

- **D-21: Criterion 1's inode proof is a synthetic fixture PLUS a cross-dataset negative control.**
  Move a throwaway fixture between two `_inbox` directories and assert the inode is **unchanged**;
  then move the same fixture across a dataset boundary and assert the inode **does change**. The
  second half is the point — an inode that has only ever been observed staying the same is an
  instrument nobody has shown can distinguish anything. README § Health Checks: prove an assertion
  **capable of failing**, never merely observed passing.
  ⚠ The obvious target for the negative control is `/mnt/tank/media/Music`, but Phase 1's D-20 says
  nobody holds `rw` there until Phase 6. **Run it from the Proxmox host and clean up after itself, or
  target a different dataset entirely** — the property under test is "a different `devid` changes the
  inode", not "Music specifically". The planner owns that choice.

### Criterion 4 — a guard, not work

- **D-22: Criterion 4 is already green and becomes an assertion.** **Zero** `_`-prefixed directories
  exist anywhere under `/mnt/tank/media/Music`. Budget no effort for achieving it. Assert it **before
  and after** the phase's moves, so a staging-style name cannot leak into the library — MA silently
  ignores underscore-prefixed folders and Jellyfin does not, so the two consumers would diverge by
  design and neither would report an error.

### Ownership

Constraint that shapes all of this: everything on `tank` is mode **0777** and stays that way —
`chmod` fails `EPERM` even as real root under `aclmode=restricted` + `aclinherit=passthrough`. So in
the staging tree ownership governs **consistency and what later `stat` assertions can say**, not who
can write. `chown` cannot run from LXC 100 at all (sparse idmap); only from atlantis.

- **D-23: The six `_inbox` directories are created `568:568`, from atlantis.** Matches the library
  convention stated independently in `STANDARDS.md` (§ Volume Mounting), `DEPLOYMENT.md` (§ Storage
  conventions), `README.md` (§ Storage) and `PROJECT.md`, and matches what Phase 7's `stat` checks
  will expect.

- **D-24: All of `tank/downloads` is normalised to `568:568` in one verified sweep — operator
  decision, against the recommendation, and the reasoning is recorded so it is not re-litigated.**
  Scope is **all 209,039 entries**, `incomplete/` included. Verify with `zfs diff` the way Phase 1's
  01-08 did for the library. Note the scale: 197,776 of those entries are currently uid **3000**, and
  this is **~74× the Phase 1 library operation** (2,674 entries), so it needs its own plan step and
  its own timing expectation.

  *The recommendation this overrides, kept because it is the counter-argument a reviewer will
  reconstruct:* Phase 1 normalised the **library** because it is exported over NFS, where ZFS
  `acltype=nfsv4` ACLs are not exported and mode bits are the only lever a client sees.
  `tank/downloads` is **not exported**, is 0777, and uid 3000 is the download client legitimately
  owning what it wrote.

- **D-25: One-time sweep, verified, with NO standing assertion — this is what "normalised" means at
  phase end.** The download client keeps writing as uid 3000 at roughly one job per 72 seconds, so
  new 3000-owned files appear almost immediately after the chown completes. **Do not add a health
  check asserting `568:568` across `tank/downloads`**: it would go red on the next download and train
  everyone to ignore it — the precise failure mode Phase 02.1's CR-01 spent four gap-closure plans
  repairing in the other direction. The measurement and its date are the deliverable. Changing
  SABnzbd's runtime identity to 568 was considered and rejected here: it reaches every category
  (tv, movies, software, readarr) and services this project does not own.

- **D-26: Content moved into `_inbox` is NOT chowned per-move; staging carries mixed ownership by
  design and the plan says so explicitly.** A rename preserves ownership, and adding a privileged
  chown to every move would contradict the one-atomic-rename property the design rests on. Under D-24
  the tree-wide sweep makes this largely moot at phase end, but the **statement still matters**: it
  stops someone later writing an "everything under `_inbox` is `568:568`" assertion that D-25
  guarantees will drift.

### Ordering

- **D-27: Snapshot → create `_inbox` → junk sweep (review + delete) → `Now!` split → album-tag repair
  → chown last.** Snapshot first so everything after it is reversible (D-01). The **tag repair runs
  after the split**, because the split produces the per-volume folder that defines the grouping the
  repair applies to. Chown **last**, as a single pass, so it also normalises the 115 volume
  directories and the six `_inbox` directories this phase just created, and so the D-25 drift window
  is as short as possible. **Each step is independently resumable**: an interrupted split leaves each
  volume either moved or not, readable with `ls`, which is the entire point of filesystem-as-queue and
  the direct answer to a project that has been abandoned three times.

### Claude's Discretion

- Plan decomposition within the D-27 ordering, subject to three fixed constraints: **D-01's snapshot
  is the first act**; **D-13's approval gate blocks both the move and the delete** (the script may
  enumerate before approval, it may not act before approval); and **D-10's tag repair runs after the
  split**, never before.
- Exact wording of D-12's in-band ROADMAP/REQUIREMENTS amendment, including D-14's one-line factual
  correction, following the 02.1-11 shape.
- How D-21's negative control is squared against Phase 1's D-20 (host-side, or an alternative dataset).
- The exact rule list D-13's enumerator implements beyond the four patterns criterion 2 names.
- The canonical `album` string format D-10 writes (e.g. whether volume 1 becomes
  `Now That's What I Call Music! 1`), provided it is one consistent form across all 115.
- Whether D-04's per-volume shortfall list lives inline in the plan or in a referenced artifact — it
  must be named before the run either way.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Measurements this phase is built on — read FIRST
- `.planning/phases/05-inbox-structure-and-the-junk-gate/05-PREMEASURE.md` — read-only measurements
  from atlantis, 2026-09-18. § 1 the `devid=68` vs `devid=76` finding that makes criterion 1
  satisfiable; § 2 the stale fence (D-01); § 3 the flat 4,760-file shape; § 4 the Potter
  mis-specification (D-14); § 5 the arrs scope question (D-12); § 6 criterion 4 already green (D-22);
  § 8 `dj-mixes`'s 84 inconsistent top-level names, carried to Phase 6.
  **Read its § Limits** — every count is a point-in-time read on a tree written to at ~1 job per
  72 s, and must be re-measured at plan time.
- **The `Now!` tag inventory is NOT persisted.** The full `album`/`disc`/`track` scan behind D-03,
  D-04, D-08 and D-10 was written to `/tmp/now_tags.tsv` on LXC 100 and `/tmp` there is **tmpfs** —
  it is gone on reboot and it eats host RAM. The plan must **regenerate it** as its own step and
  write it somewhere durable under `/mnt/fast/`, never `/tmp`.

### Phase scope and requirements
- `.planning/ROADMAP.md` § *Phase 5* — the four success criteria. Criterion 2 is amended by D-12
  (scope) with D-14's factual correction folded in; criterion 3's wording is corrected by D-02/D-05;
  criterion 4 is already satisfied per D-22.
- `.planning/REQUIREMENTS.md` — INBX-01 (lines 159–160), INBX-02 (161–162), INBX-03 (163–164).
- `.planning/PROJECT.md` § *Constraints* — the `0777`/`aclmode=restricted` chmod bar, the
  separate-datasets / `EXDEV` fact, the `rsync -a` failure mode and its working invocation, and the
  `568:568` ownership decision.
- `.planning/PROJECT.md` § *Context* — "Cover scans exist, but for a minority … where present they
  carry full tracklistings and are more reliable than any autotagger." This is the standing
  justification for D-06's keep verdicts.

### The design this phase implements
- `.planning/research/ARCHITECTURE.md` § *Recommended Structure* — the `_inbox` tree, and why it
  sits under `tank/downloads` not `media/`, including why Jellyfin's `.ignore` is not a safe
  workaround (jellyfin#14502).
- `.planning/research/ARCHITECTURE.md` § *Pattern 5: Filesystem-as-Queue* — the resumability model
  D-27 rests on, and the `unsorted/` → `_inbox/` → `_done/` transitions.
- `.planning/research/ARCHITECTURE.md` § *Pattern 4: Copy In, Never Move In* — the `EXDEV` /
  block-cloning detail behind D-07 and D-18.
- `.planning/research/SUMMARY.md` § *Phase 5* — the underscore-naming note behind D-22.

### Decisions this phase amends or inherits
- `.planning/phases/04-collapse-to-one-tagger/04-CONTEXT.md` § D-01 — deferred beets-flask to
  Phase 5; **amended by D-16**, which moves it to Phase 6. Read D-01's objection before disagreeing.
- `.planning/phases/04-collapse-to-one-tagger/04-CONTEXT.md` § D-31 — the pre-declaration pattern
  D-04 follows.
- `.planning/phases/04-collapse-to-one-tagger/04-CONTEXT.md` § D-23 — the `normalise-dj-tags.py` WAV
  repair and its three-case self-test. D-10 reuses that tool; its dry-run and field-loss gate are
  what make the tag write safe.
- `.planning/phases/03-tagger-spike/03-DECISION.md` § *Axis two* — beets-flask's policy-carrying
  inbox architecture is the chosen front end; friction 9 is cited by D-16.
- Phase 1 D-20 — nobody holds `rw` on `/mnt/tank/media/Music` until Phase 6. Constrains D-21.
- Phase 1 D-23 — Phase 5 absorbs `lidarr-import`. Closed by D-20.
- QUAL-01 (`.planning/REQUIREMENTS.md:171`) — the before-state snapshot, **keyed on `audio_md5`**.
  This is what makes D-10's tag write compatible with Phase 7's diff.
- `.planning/STATE.md:1115` — the uid-3000 carry-in. Answered by D-24/D-25.

### The durable estate record and house rules
- `stacks/selfhosted/arrs/beets.md` — the durable record beside the stack; this phase's closure
  section lands here, as Phases 1, 2, 02.1 and 4 each did.
- `README.md` § *Health Checks* — the three rules any assertion this phase adds must follow: fail
  closed with "could not look" kept distinct from "nothing is wrong"; bound remote commands
  **Linux-side**; assert rather than report. Note `timeout N cmd | wc -l` silently exits 0.
- `scripts/spike03-image-headroom.sh` — the two-process approval gate D-13 reuses.
- `scripts/normalise-dj-tags.py` — the tag-write tool D-10 reuses.
- `CLAUDE.md` § *Storage and Permissions* — service account `568:568`, repo path `/mnt/fast/stacks`.
- `DEPLOYMENT.md` — git is the delivery path; a commit must reach `origin` before LXC 100 can pull.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`scripts/normalise-dj-tags.py`** — dry-run by default, three measured rules, applied on copies
  with a field-loss gate; WAV write path repaired in Phase 4 (D-23) with a three-case self-test.
  D-10 extends it with a canonical-`album` rule rather than writing a new tool.
- **`scripts/spike03-image-headroom.sh`** — the enumerate → operator-approves-file → act-from-file
  gate. D-13 reuses its shape; 02.1-09 proved it on a real reclaim (4 rows, 1.45 GiB).
- **Phase 1's `zfs diff` verification method (01-08)** — D-24 reuses it, at ~74× the entry count.
- **`scripts/snapshot-music-tags.sh` / `scripts/diff-music-tags.sh`** — QUAL-01's capture and diff
  tooling, keyed on `audio_md5`. The instrument that proves D-10's write lost nothing.
- **`/mnt/fast/safety`** — Phase 1's fence, on a path no tagger container mounts. The durable home
  for the regenerated tag inventory and for any sidecar worth archiving.
- **`scripts/quick-health-check.sh`** — the standing-check entry point. D-22's criterion-4 assertion
  is a natural fold-in; **D-25 explicitly forbids** a `tank/downloads` ownership assertion there.
- **The in-band dated amendment shape (02.1-11, Phase 4's D-20)** — quote the original, state the
  measurement, name the change, preserve substance. D-12 needs it once, with D-14 folded in.

### Established Patterns
- Host-resident scripts under `scripts/`, `#!/usr/bin/env bash`, `set -euo pipefail`, ALL-CAPS
  constants, run from `/mnt/fast/stacks` after a `git pull`.
- A `.md` beside the stack it documents. Operational detail lives beside the thing it describes.
- Prove an assertion **capable of failing** with a driven negative control (D-21).
- Pre-declare expected-but-odd observations so a verifier cannot read them as failure (D-04).
- Two-process approval for anything destructive (D-13).

### Integration Points and Hazards
- **`/tmp` on LXC 100 is tmpfs.** Writing a large inventory there consumes host RAM — 1.1 GB of EPG
  XML once took the whole 28 GB box down. Stage under `/mnt/fast/`.
- **`zfs` cannot exist on LXC 100** (unprivileged) — snapshot and `chown` go via
  `ssh root@172.16.1.158`. `rsync`, `tmux` and `screen` are **not installed** on LXC 100.
- **`chmod` fails `EPERM` everywhere on `tank`**, even as real root. Do not plan a mode change.
- **`chown` fails from LXC 100** for a different reason (sparse idmap) — atlantis only.
- **`rsync -a` fails writing to `tank`** (`mkstemp … Operation not permitted`) while printing stats
  that look like success and exiting 23. Use `rsync -rlt --no-p --no-o --no-g` if any copy is needed.
- **A container-side listing showing `65534` is LXC 100's view, not the disk.** Phase 1 lost time to
  this. Check from atlantis before believing any ownership reading.
- **ZFS frees space asynchronously** — `zfs list` can lag a large delete by ~20 s. D-11 deletes, so
  expect this.
- **The download tree is live**, written at roughly one music job per 72 s. Every count in
  `05-PREMEASURE.md` and in this file will drift; re-measure at plan time. Also why D-15 rules
  `incomplete/` out.
- **`ffprobe` takes one input file.** A scan built with `xargs -n 50 ffprobe` silently produces
  nothing and exits clean — it cost a wasted pass during this discussion. Use `-n 1` / `-I {}`.
- **Jellyfin's freeze gates the automatic save path only.** An explicit `FullRefresh` still writes
  `.nfo`, a second reason nothing is staged under `/media/Music`, reinforcing D-22.

</code_context>

<specifics>
## Specific Ideas

- **D-03's volume-number trap belongs in the plan verbatim, not paraphrased.** A trailing-number
  regex is the obvious first implementation, it exits 0, and it misfiles 36 tracks. Name
  `Vol.36 CD1` / `Vol.36  CD2` explicitly, **double space included**.
- **D-06's verdicts were reached by opening the files, and that is the transferable lesson.** File
  type predicted nothing: three `.bmp` that looked like generic artwork turned out to be volume 77's
  case scans carrying a full tracklist and a barcode, while seven `.log` of similar size are rip
  logs worth nothing. The same "look before deciding" rule applies to the `dj-mixes` scans in
  Phase 6 — 27 folders, 54 images, already flagged in PROJECT.md as more reliable than any
  autotagger.
- **`back.bmp` is a three-way corroboration and worth calling out as evidence, not just an asset.**
  Scan says 44 tracks / 22 + 22; tags say 44 files / tracktotal 22 + 22; file count says 44. When
  Phase 6 needs to trust the tags on this series, this is the precedent that they can be trusted
  where they are complete.
- **D-21's negative control is the more interesting half**, exactly as Phase 4's D-17 negative
  control was. An inode that stayed the same proves nothing until the instrument has been seen to
  change.
- **D-24 was taken against the stated recommendation.** The counter-argument is preserved inside the
  decision so a future reviewer meets reasoning rather than silence — the style PROJECT.md uses for
  its `sec=sys` and Discogs-rotation rows.
- The operator's Phase 3 verdict governs how D-13's gate is built: *"It's fine for a bot to drive us,
  but for me, as a human, no."* Read and approve a file; never sit at a prompt.

</specifics>

<deferred>
## Deferred Ideas

- **Volumes 4, 8 and 9's tracktotal surplus** — D-04 requires an answer during the phase, but if it
  turns out to need real investigation (reissue track counts vs mis-tagged files), the *repair*
  is Phase 6. Only the diagnosis belongs here.
- **beets-flask stack definition and configuration** — Phase 6 (D-16), carrying Phase 3's friction 9.
  **Open research question:** whether it has shipped past `2.0.0-rc6` since 2026-09-04, which would
  change the version-pin half of D-16's reasoning.
- **Every other `Now!` tag field** — `artist`, `title`, the BPM-in-title convention, and the
  `comment=YearmixFreak 2023` / `encoded_by=djdezzie` rip artefacts visible in the scan. D-10 is
  scoped to `album` alone; the rest is Phase 6.
- **The per-file `LOCATION=https://www.discogs.com/…/release/NNNNNN` tag** present on this
  collection — a direct Discogs release id on every track, which is exactly the source Phase 3 chose.
  Potentially a large shortcut for Phase 6's CONF-05 disambiguation. **Recorded, not acted on.**
- **`dj-mixes`'s 84 inconsistent top-level names** — `Mastermix_Issue_410` beside
  `Mastermix_Issue_410.1`, `Mastermix.Issue.420.2021` in a different separator style, eight ending in
  a truncated bare `_-`, and Now! compilations (`__118__`, `__119__`) inside a folder named for
  Mastermix. Phase 6 matching work (`05-PREMEASURE.md` § 8).
- **The 6 TV/movie `_FAILED_` directories** — out of scope by D-12, named in `05-PREMEASURE.md` § 5.
- **The stalled `incomplete/Harry.Potter…hallowed` job** with its `__ADMIN__` directory — SABnzbd's
  to clear (D-15). Worth mentioning to Phase 8, which owns the hook.
- **Investigating why the 24 Now! tracks vanished in the flatten** — pre-declared and located per
  volume (D-04), but not chased. Re-acquisition is not scoped by this project.
- **Changing SABnzbd's runtime identity to uid 568** — considered and rejected under D-25.
- **`_done/` pruning mechanics at backlog scale** — D-19 fixes the policy; Phase 9's batch cadence
  makes it operationally real.
- **DUPE-01 / DUPE-02** — still needs a roadmap decision before Phase 7. Phase 1 measured 828
  duplicate groups / 19.4% duplication and Phase 3 re-confirmed `dj-mixes` is a byte-for-byte
  duplicate subset of `unsorted`, making Phase 7's diff join **last-wins** — a silent behaviour
  rather than a chosen one.
- **`/mnt/tank/media/TV` on the orphan gid 545** — 114,218 entries, outside this milestone.

</deferred>

---

*Phase: 5-inbox-structure-and-the-junk-gate*
*Context gathered: 2026-09-18 — revised same day after operator corrections*
