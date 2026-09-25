# Phase 7: Pilot — 12 Albums End to End - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Run the one pipeline **for real**, once, on twelve named albums — inside a snapshot fence, with a
field-level before/after diff proving no net metadata loss, and an undo **exercised rather than
assumed**. The roadmap's own framing governs everything below: *the deliverable of this phase is
trust, not a count.* Every prior attempt shipped a tool and never shipped an album.

**This phase writes to the library for the first time.** Granting `/mnt/tank/media` `rw` is its
first act (E3), done deliberately with the fence already in place — Phase 6 held it `:ro` for its
entire duration and D-21's pre-authorised fenced write never fired.

**In scope, beyond the ROADMAP's eight criteria:** the E1 DJ-routing mechanism (which does not
exist); building criterion 7's detection sweep (which does not exist); the E5 `Def Leppard` repair;
hardening `scripts/diff-music-tags.sh` against its silent last-wins join; and a snapshot register
for the estate's nine unowned project snapshots.

**Out of scope:**
- `tank/downloads/mybook-music-archive` — the 1.30 T newly discovered archive (D-01, D-02)
- The DUPE-01/DUPE-02 reconciliation itself (D-03)
- Bucket B — the *Now!* series (S4 dropped from the sample, D-04)
- Any **bulk** import; Phase 9 owns throughput
- Re-trying E6's mtime re-probe route — measured dead for this estate (`DEF-06-45-02`)

</domain>

<decisions>
## Implementation Decisions

### Scope — the newly discovered 1.3 T archive

- **D-01: `tank/downloads/mybook-music-archive` is NOT in Phase 7's scope, and the reason is
  mechanical rather than a preference.** It has **no QUAL-01 before-state**:
  `scripts/snapshot-music-tags.sh` pins four capture roots by name — `unsorted`, `dj-mixes`,
  `complete/nzb/music`, `media/Music` — and this archive is none of them, nor is
  `mac-music-archive`. Criterion 4's field-level diff is therefore **uncomputable** for any album
  drawn from it, so drawing from it would not merely be risky, it would make the phase unable to
  meet its own gate.
  *Measured state, recorded so the next phase does not re-derive it:* **1.30 T** on its own
  case-sensitive child dataset (`casesensitivity=sensitive`, set at creation and immutable), with
  its origin fence `@copied-from-mybook-20260922` intact and a second copy on the `backup` pool.
  Inventory complete 2026-09-22: **175,050 files / 165,467 audio / 231 playlists**, **21,923
  duplicate groups**, 32,631 redundant files, **211.8 GiB reclaimable**, and **450 distinct DJ
  releases** — against `CLAUDE.md`'s working baseline of ~46. 75 % of it is `unclassified`, i.e.
  ordinary albums, not DJ service releases.

- **D-02: It gets its own INSERTED phase between Phase 8 and Phase 9**, following the `02.1`
  precedent. That phase owns the QUAL-01 capture over the archive **and** the dedupe, so Phase 9's
  batches draw from the whole backlog rather than doing the work twice. *Rejected:* a Phase 10
  after 9, and *Beyond This Milestone* — both were on the table and the operator placed it before
  the throughput phase deliberately.
  ⚠ The capture is **not a task-sized item**: 165,467 audio files against Phase 1's ~9,736, at two
  processes per file. Size it as a multi-day run when that phase is planned.

- **D-03: DUPE-01 / DUPE-02 fold into that same inserted phase** and move out of *Beyond This
  Milestone*. One reconciliation for the whole estate — the archive's 21,923 groups and the
  existing 828 groups against one inventory. Deduping the archive without `unsorted` at the same
  time means doing it twice, and the biggest single win already identified
  (`hitsquad/DJ/todoTunes` vs `tunes/music/DJ/todoTunes`, the same library in two places) spans
  both.
  **Sequencing constraint carried into that phase:** read the `.musiclibrary` playlists **before**
  any dedupe pass. A playlist is only meaningful while the files it points at still exist at the
  paths it records.

### The sample

- **D-04: The twelve are 6 reused bucket-A rows + the 2 DJ folders + 4 fresh seeded draws.**
  Reused from `06-SAMPLE.md`: the three S1 rows (which include the **Benson Boone duplicate pair** —
  the same album as FLAC and as MP3, the predicted `%aunique{}` firing and the pair
  `import.duplicate_action: skip` silently dropped ten files from in run 1), **S2** the multi-disc
  release, **S3** the various-artist compilation, **S7** the singleton folder. Plus both **S5**
  `dj-mixes` folders.
  **Two of Phase 6's ten are dropped, for different reasons:**
  - **S6 (`/mnt/tank/media/Music/Katy Perry/Teenage Dream (2010)`) is a LIBRARY folder**, drawn
    read-only under D-05's `:ro`. It is already imported and is **not an import candidate at all**.
    This is the easiest thing for a downstream reader to miss.
  - **S4 (a `Vol NNN` *Now!* volume) is bucket B**, and criterion 1 says twelve **bucket-A** albums.
  *Accepted consequence:* keeping the S5 pair means the pilot imports bucket C content into a
  bucket-A phase, which is what forces D-08.

- **D-05: One of the four fresh slots is a declared ≥4-artist stratum, target 1**, drawn randomly
  within its eligible set by the same `LC_ALL=C` folder-path key the Phase 6 draw used. This is
  **E6's second measurement** — the only thing separating *"MA caps the artist list at 3"* from
  *"`Twista` specifically failed to map"*, which a sample of one cannot settle. It has survived
  rounds 5 and 6 untouched; reserving a slot is what stops it drifting again.
  ⚠ The stratum target is declared **before** the eligible set is known, per D-26. If the eligible
  set proves empty the slot reallocates and the measurement is recorded as **not taken** — never
  quietly satisfied by a 3-artist row.

- **D-06: The three unreserved fresh slots draw from `music/` and `unsorted/` combined**, excluding
  the *Now!* set — 162 folders / 3,236 audio files. `unsorted/` is the population Phase 9 actually
  has to process; a pilot drawn only from `music/` would prove the flow on the newest, cleanest
  downloads and say nothing about the backlog.

- **D-07: The oracle is FROZEN for the six reused rows and appended for the six new ones.** The six
  reused path lines are carried **byte-identical out of Phase 6's commit** —
  `git show <commit>:06-EXPECTED-TREE.txt`, the commit-anchored identity CONVENTIONS.md convention
  10 requires, never the index. New lines are derived for the six new albums and appended.
  *Re-deriving all twelve was rejected:* an oracle derived from the same config it judges makes a
  zero-diff prove the run matched the prediction, not that the prediction was right. The six frozen
  rows are a prediction registered **before anyone knew the answer**, and that is the whole of
  their value.
  ⚠ If a frozen row now fails, that is a **finding to adjudicate** — it names a config change since
  2026-09-21 — and must never be silently updated to match.

- **D-08: E1's DJ-routing mechanism is post-import `beet modify albumtype=dj` followed by
  `beet move`.** Works today with no new code, and `beet move` is already this project's proven
  instrument — D-33 made it the destination-path oracle precisely because `import --pretend`
  computes no destination.
  ⚠ **It must run INSIDE the flask container via `docker exec`** on flask's own beets 2.12.0. D-04
  forbids the dormant 2.13.1 arm from ever opening the real `library.db`, and a CLI `beet modify`
  against it would violate that. This is the D-30 shape.
  *Rejected:* a global `import.set_fields` (it would stamp `albumtype=dj` on every import including
  the ten bucket-A albums — the roadmap names and rejects this); a hook plugin keyed on source path
  (new Python inside a pre-release web app, written during the phase that first grants `rw`).
  *Accepted consequence:* the files land in the artist tree first and are moved second, so there is
  a window where the tree is briefly wrong.

- **D-09: DJ path rule 2 gets a named read-only class assertion, and no import.** `albumtype:=dj
  disctotal:2..` has been **evaluated by no instrument in any phase** (`DEF-06-12-01`) and is the
  only rule in the committed `paths:` stanza in that state. Neither drawn S5 folder carries
  `disctotal`; seven `dj-mixes` folders do — `Mastermix_Issue_403`, `_404`, `_413`,
  `_418_April_2021`, `VA-Mastermix.Issue.422-2021`, `.427.2CD-2021`, `.429-2022`. Run `beet move -p`
  over one of them with `albumtype=dj` set and assert the rendered path. **This is what plan 06-11
  was told to do and did not.**
  Read-only, so it is **not** hand-picking a pilot member — the drawn sample is untouched. This is
  exactly where a `-1 - ` or `00-01` rendering defect hides; Phase 3 found one of those in the
  tagger this project retired.

- **D-10: The run is gated — one album, then eleven — and the first album is `Michael Jackson – The
  Essential` (S2).** 32 FLAC files, `disctotal = 2`, `disc` values `{1,2}`, four distinct artists.
  It exercises D-14's flat disc-prefixed naming and criterion 6's *"one album with disc numbering
  intact"* in both consumers, and carries enough tag surface that the QUAL-02 diff **cannot come
  back empty**.
  *This is plan 05-09's lesson applied:* the operator amended that plan because its proposed pilot
  (`Vol 077`) had zero proposed changes and **would have passed its gate vacuously**. A clean
  single-artist S1 album would have repeated that.

### QUAL-02 and the DUPE-01 join

- **D-11: `scripts/diff-music-tags.sh` fails closed on an ambiguous join, on BOTH sides.** The
  defect, measured: `diff-music-tags.sh:156` reads
  `def index: reduce .[] as $r ({}; .[$r.k] = $r);` — a plain reduce assigning `.[$r.k] = $r`, so
  for a duplicated `audio_md5` **the last record in stream order wins and every earlier one is
  silently discarded from the comparison**. `dupgroups` is computed separately over the full array,
  so the count is *reported* while the join has already thrown those rows away. If the `dj-mixes`
  copy carries `TKEY` and the `unsorted` copy does not, **whether QUAL-02 fires depends on
  file-walk order**. This is E7's *"last-wins — a silent behaviour rather than a chosen one"*,
  visible in one line.
  **The fix:** a matched `audio_md5` with more than one record whose flattened tag maps **differ**
  is classified **AMBIGUOUS** and exits **3 UNKNOWN** — the estate's three-state convention, keeping
  *"could not look"* distinct from *"nothing is wrong"* (CONVENTIONS.md convention 1). Identical
  duplicates collapse harmlessly and never fire.
  **Symmetric — the same rule applies to `$ai`.** An AFTER-side duplicate is worse than a BEFORE-side
  one: it means the import produced two library files with identical audio, i.e. a `.1`-suffix
  collision or a `duplicate_action` miss — exactly what criterion 7's sweep exists to find.
  Comparing against whichever landed last would hide it.
  *Rejected:* unioning the BEFORE duplicates (it silently picks a policy about what "before" means);
  excluding twinned folders from the draw (leaves the instrument broken for Phase 9, where every
  batch hits it).

- **D-12: The AMBIGUOUS arm is driven BOTH WAYS before the pilot trusts it, on fixtures AND on real
  data.** Two synthetic fixtures added to the script's self-test so the case is permanent — an
  **identical** duplicate pair that must **NOT** fire, a **divergent** pair that **MUST** — plus a
  run of the changed diff over the real QUAL-01 snapshot, which already contains the
  `dj-mixes`/`unsorted` duplicates on disk and costs nothing to read.
  *Fixtures alone were rejected:* that is precisely the shape **E12** names as residue — four
  round-2 hardenings driven on synthetic material with the pilot as their first real exercise.
  Repeating it here would be repeating the finding.

- **D-13: The `unsorted` prohibition is AMENDED IN BAND to bulk import, with the pilot named as the
  exception.** `ROADMAP.md`'s *Beyond This Milestone* row for DUPE-01/02 reads **"Must precede any
  import of `unsorted`"** — and D-06 draws from `unsorted`. A direct conflict, surfaced here rather
  than discovered at plan time.
  The rule was written against Phase 9's wholesale import of 7,451 files, where a bad duplicate
  call is unrecoverable at scale. A **bounded three-folder draw inside a snapshot fence, with the
  diff now failing closed on AMBIGUOUS**, is a different risk. The row is amended to *"any **BULK**
  import of `unsorted`"* with the pilot named as the exception and D-11 named as the control —
  the same amend-rather-than-contradict discipline D-09 and D-33 used in Phase 6.
  ⚠ **This must be argued in the amendment, not merely edited.** Narrowing a safety rule to fit the
  plan is how safety rules die.

### Undo and the fence

- **D-14: The per-album undo is beets-flask rc6's `UNDO IMPORT`, with `state.pickle` coverage
  proven.** `beets.md:1331` flags it specifically because *"beets has no undo"* is true of the
  **CLI** but not of the front end. This is the mechanism the operator will actually reach for — on
  their own T3 words, *"It's fine for a bot to drive us, but for me, as a human, no"* — so proving
  it proves the real workflow.
  ⚠ **It must be shown to cover `state.pickle`, not just the tree and the database.** That is the
  half the roadmap warns about: rolling back one without the other leaves the release invisible to
  a retry, and criterion 5 requires *no hand-repair*.

- **D-15: The gated first album is backed out immediately after it passes, then re-run.** Undo is
  proven at the cheapest possible moment — **one album at risk instead of twelve** — and *"re-run to
  a good state"* is verifiable rather than aspirational, because the good state is exactly what just
  cleared the gate.
  *Rejected:* waiting for an album that fails (if all twelve import cleanly there is no reject case,
  and criterion 5 then gets satisfied by backing out a good album anyway — this option, later and
  with more at stake); deliberately regressing an album (writing knowingly-bad tags to a 34 GB
  library during the phase that first grants `rw`, to manufacture a case the corpus may hand you
  free).

- **D-16: The fence is BOTH datasets, taken in ONE remote step, with `zfs rollback` on the arrs
  dataset PROHIBITED.** `tank/media/Music@pre-07-pilot` **and** `fast/appdata/arrs@pre-07-pilot`,
  both listed back and asserted equal **before any file is written** — the 06-41 pattern, so the
  fence and the mutation cannot come apart.
  *Measured on atlantis, not assumed:* `fast/appdata/arrs` **is** a real dataset mounted at
  `/mnt/fast/appdata/arrs`, so `library.db` and `state.pickle` are genuinely snapshottable.
  (The memory note claiming `/mnt/fast/appdata` is not a mountpoint is **LXC 100's view, not the
  disk's** — the same class of error CLAUDE.md corrects for ownership. Read it from atlantis.)
  ⛔ **`zfs rollback` on `fast/appdata/arrs` is forbidden on every branch** — that dataset carries
  Sonarr, Radarr and Lidarr state too. Database recovery is **a file restore out of the snapshot,
  only**. This goes in the plan as a hard fence, duplicated at each call site per CONVENTIONS.md
  convention 6.

- **D-17: The two held snapshots release on different terms — one mechanical, one gated.**
  - `tank/media/Music@pre-06-41-conf04-reprobe` (`DEF-06-45-01`) is destroyed **mechanically**, in
    the same step that records **criterion 1 satisfied** (new snapshot taken **and** rollback
    exercised). The operator rewrote that condition into a mechanical trigger for exactly this
    reason — *"That's an event someone already has to produce evidence for, so the item closes on a
    commit rather than on remembering… no judgement left in it."* Adding a gate back would
    re-insert the judgement that rewrite removed.
  - `tank/downloads@pre-phase5` (E4 / D-32) stays **operator-gated**. E4 frames its release as an
    **estate-wide** decision, not a music-project one: it is the only undo for 4,750 renames, 751
    in-place tag writes and 26,005 chowns, and a rollback would discard everything every service
    has written to `tank/downloads` since 2026-09-18 15:42.

- **D-18: On abandonment the fence HOLDS, the run is resumable, and nothing auto-rolls.** Snapshots
  stay, the run resumes from `importsource` / `incremental` state, and the plan records a **written
  STOP state naming which albums landed** so a later session reads it rather than re-deriving it.
  *Rejected:* auto-rollback on abandonment (it destroys work on a timer, and a half-imported state
  that is recorded and fenced is not dangerous — criterion 8 keeps the sources intact either way);
  complete-or-roll-back (twelve albums plus a gate, an undo demonstration and both consumers is a
  lot to bind to one sitting, and the pressure to finish is how corners get cut).
  *Rationale:* this project exists because the pipeline was abandoned three times. An auto-rollback
  turns a pause into a loss, and the snapshot costs nothing on 5.26 T free.

- **D-19: A snapshot register is produced, and pruning requires a NAMED successor plus an operator
  gate per snapshot.** Nine project snapshots stand on `tank` with no owner and no release
  condition — `@pre-project`, `@pre-chown`, `@pre-phase5`, `@pre-phase5-chown` on `tank/downloads`;
  `@pre-project`, `@safe05-watch-t0`, `@pre-chown`, `@pre-phase5-chown`,
  `@pre-06-41-conf04-reprobe` on `tank/media/Music`; plus the `mybook-music-archive` set.
  The register lists each with its owner, what it is the undo for, and its release condition — or
  **"none recorded"** stated as a *could-not-look* rather than left blank (`DEF-06-52-02`: silence
  reads as absence).
  **Eligibility for pruning is mechanical:** a snapshot qualifies only when another snapshot on the
  **same dataset** is strictly newer **and** the register **names it** as covering the same undo,
  with the covered change identified. Every destruction then goes through **one `autonomous: false`
  gate** presenting the full list, its reasons and the `zfs list` evidence — the 06-52 shape.
  ⛔ **No snapshot is destroyed on a plan's own judgement.**
  *Rejected:* an age-plus-newer-sibling rule — age does not track what a snapshot is the undo *for*,
  and `@pre-phase5` is the oldest and most load-bearing thing in the set.

### Execution and the `rw` grant

- **D-20: The twelve import through `02-review`, confirmed per album.** This is the front end Phase
  3 chose on axis two, it is the workflow the operator will own, and per-album confirmation is what
  D-10's gated run and criterion 2's *"named in the plan before the run"* both assume. It pairs
  naturally with D-14's `UNDO IMPORT`, since both live in the same UI.
  *Rejected:* scripted `docker exec beet import` (it bypasses the chosen front end, so the pilot
  would prove a path the operator will not use — and the core value is a flow the **operator**
  believes); `01-auto` unattended (the E11 hazard itself).

- **D-21: `01-auto` is DE-REGISTERED for the duration of this phase and re-registered in Phase 8.**
  The inbox **directory stays**; only the registration goes.
  *The hazard this closes (E11):* `01-auto` is registered `autotag: auto` under a
  `restart: unless-stopped` watchdog that reads the **vendored config directly**, where
  `import.write` is `yes` and `/downloads` is mounted `:rw`. The config names three controls — the
  `-c` overlay, the `:ro` mount, the statefile sha256 — and **none of the three reaches the
  watchdog**. What bounds it today is only that nobody has staged a file there, and **"nobody has
  put a file there" is not a control.**
  De-registration turns that argument into a **structural absence** — the same reasoning D-05 used
  for the `:ro` mount: *a control that cannot fail open beats one that is currently not firing.*
  Phase 8 re-registers it deliberately, when the inflow design is actually decided.

- **D-22: ONE commit carries the `rw` grant and every behaviour flag that moves with it, and it
  re-baselines the config digest without orphaning Phase 6's proofs.** The commit contains:
  1. `/mnt/tank/media` `:ro` → `:rw`
  2. `import.move` → **`copy`** (criterion 8 — the source folders must still exist afterwards)
  3. `import.write: yes` **recorded with its bound named** (D-21)
  4. `01-auto` de-registered
  5. the config **sha256 re-baselined, with the PREVIOUS digest and the commit that produced it
     preserved beside it**
  **`import.write` is FORCED, not chosen** — criterion 3 requires `ffprobe` showing the *new* tags
  **on the file itself**, which is impossible with `write: no`. So E11's decision is *"keep `yes`,
  and name what bounds it"*, and D-21 is now that bound. State this explicitly; a reader who sees
  `yes` survive E11 will otherwise assume it was overlooked.
  **Why the old digest is preserved:** editing `config.yaml` moves the sha256 of the exact object
  every CONF-01 / CONF-02 / CONF-05 proof was measured against, plus the appdata copy the
  vendored-drift block compares (`DEF-06-21-01`). Keeping the prior digest and its commit means
  those proofs stay attributable to the object they were actually taken against.
  *One commit, not four,* because E3 makes the grant a deliberate first act and four commits is
  four chances to land in a half-granted state.

- **D-23: `/media` STAYS `rw` after the phase, with a standing assertion.** Phase 8 and Phase 9 both
  need it, so revoking at phase end means re-granting immediately. Instead, add an assertion to
  `scripts/quick-health-check.sh` recording that `/media` is **deliberately** `rw` from Phase 7
  onward, **with the owning phase named**, so it can never read as accidental drift.
  ⚠ *Accepted consequence, stated rather than glossed:* the library's strongest structural
  protection is gone for good. D-05's entire argument was that `:ro` **cannot fail open**, and a
  standing assertion is a weaker control than a mount flag — a rule enforced by policy rather than
  by mechanism (CONVENTIONS.md convention 4). From here the snapshot fence is the primary control.

### Inherited entry criteria

- **D-24: E5 — repair `Def Leppard/Def Leppard (2015)/`, and MEASURE the 30-item entity gap.** The
  repair happens in the same `rw` window as a **named operation distinct from the twelve** (D-19a
  scheduled it here rather than leaving it as permanent MA noise). Alongside it, take a
  before/after reading on the **30 of Jellyfin's 1,244 items that carry a non-empty `Artists`
  string list and ZERO `ArtistItems` entities** — all of `Lady Gaga/ARTPOP (2013)`, all of
  `Lady Gaga/Joanne (2016)`, one Def Leppard track.
  *Why the reading matters:* `DEF-06-45-03` hypothesises that row 1 of `ARTIST_PROOF_ROWS` never
  moved because it is an **E5 problem** — a populated `Artists` list with zero linked entities —
  **not an E6 one**. The pilot's real writes are the only event in the roadmap that can test that,
  and reading it costs one API call.

- **D-25: Criterion 7's detection sweep DOES NOT EXIST and is built as a standing script.**
  Verified: the only repository hits for `mb_albumid` / `tracktotal` are three Phase 5 scripts,
  none of them a post-import sweep.
  Build `scripts/check-music-import.sh` asserting the three named classes — **`.1`-suffix path
  collisions, empty `mb_albumid`, track count versus `tracktotal`** — **fail-closed with a vacuity
  guard** so a zero count is `UNKNOWN` and fatal rather than a pass (the CR-01 / GC-03 class), and
  **driven against a control first** (`DEF-06-45-04`: a recipe that has never matched anything is
  not evidence of absence). Fold it into `quick-health-check.sh` as its own block.
  *Standing rather than phase-local,* because **Phase 9 criterion 2 runs this after every batch** —
  building it standing now means Phase 9 inherits an instrument instead of writing one, and this
  estate's record on *"promote it later"* is that the item acquires no owner.

- **D-26: E2 — `03-asis` / `bootleg` stays unused, AND the album-populated predicate is asserted
  read-only.** Both halves, deliberately:
  - The pilot routes everything through `02-review` (D-20), so **nothing reaches the `bootleg`
    path**. E2's gate is recorded as **still untested by import**, with its first real exercise
    carried forward — rather than manufacturing a staging purely to fire it.
  - **But** the precondition the gate depends on — that `album` is **populated and distinct across
    the intended groups** — **is asserted read-only** on a candidate folder. The same button
    produced Phase 3's best and worst results purely on that condition, **with no UI signal either
    way**. This turns an untested gate into at least a tested predicate.

- **D-27: E10 — every new `beet` invocation is compliant or registered, and the undriven overlay-key
  half gets driven.** The pilot adds invocations (`modify`, `move`, `remove`, the sweep). Each is
  either compliant — `-l` outside `/config/library.db` **and** a `-c` overlay — or is added to
  `D04_EXEMPT_RE` **deliberately, with its reason**.
  ⛔ **The pinned count moving is a red by design. Do not raise the pin to make a run green**;
  `D04_DOC_BASELINE` is at 2 and earned it, and 06-16 rephrased its own runbook prose rather than
  raise it.
  Additionally, **drive the overlay-key half of the exemption regex both ways** — 06-16 N-4 /
  `DEF-06-21-06` records it as the register's weakest link and **undriven**, and the pilot supplies
  natural material for the first time.

- **D-28: E8 — every `%aunique{}` firing is verified DIRECTLY in Music Assistant, never inferred.**
  MA's `missing_album_artist_action: folder_name` fires **only when the album folder and the album
  tag agree** and **silently falls back to `Various Artists` when they do not** — while
  `config/providers/get` still reads back `folder_name`, so the setting looks correct either way.
  An `%aunique{}` firing makes folder and tag differ **by construction**. The Benson Boone pair is a
  **predicted** firing, so this fires in the pilot.
  *Dropping the disambiguator is not the answer* (D-16): it trades a *detectable* MA fallback for
  *silent* path collisions across 828 duplicate groups.

- **D-29: E9 — assert match-check ORDER, and record the `search_limit` rank per folder.** Gate on
  **`recommendation` → then track count → then per-track distance**, in that order. **A track count
  matching exactly is not sufficient**: `Vol 002`'s top candidate is a Finnish release with 30
  tracks against 30 files and beets still refuses it at `recommendation: none`.
  Separately, **record per folder whether the accepted candidate was inside
  `musicbrainz.search_limit`'s default 5** (`DEF-06-12-02`) — measure it, rather than raising the
  limit on one row's evidence.
  Related and expected: the library will grow both `Various Artists/` **and** `Various/` from the
  tags themselves (`DEF-06-11-01`) — the S4 row's `albumartist` is literally `Various`.

- **D-30: E12 — confirm the four hardenings on the first real `--run`, and size `arm1.dump`.** On
  the pilot's first `--run`: confirm both `layer3.before` / `layer3.after` parse and both `awk` keys
  match; that the destructive fence **refuses end to end under the container's `dash`** (every case
  so far used the macOS `/bin/sh`); and that no `/tmp/p6-mf.*` or `/tmp/p6-taghist.*` survives.
  All four **fail closed** — a wrong construction refuses a run that would otherwise proceed, never
  passes one that should fail — which is why they are residue rather than blockers.
  **Rider (`DEF-06-29-04`):** record `wc -c` of `$WORKDIR/arm1.dump` on the next live
  `check-beets-config.sh`. That number is the margin GC-01's `pipefail`-141 defect was measured
  against, **and it has never been written down.**

### Closure

- **D-31: An evidence map is committed BEFORE the run; `/gsd-verify 07` scores once; the operator
  records a separate trust verdict.**
  1. **Before anything is imported**, commit a map naming **one artifact and one instrument per
     success criterion** — so *"what would close this"* is answered while it is still cheap to
     answer honestly.
  2. **`/gsd-verify 07` scores the eight criteria once**, at the end of the phase's rounds. A plan
     never self-declares a verification result.
  3. **A separately recorded operator trust verdict** on the question the criteria cannot score:
     *do you believe this flow?* The roadmap says the deliverable is trust, not a count — making
     that a written artifact rather than an implication is the whole difference.
  ⚠ **Phase 6's six-round model is explicitly NOT adopted.** It demonstrably surfaces real defects —
  round 2 found a BLOCKER in round 1's own code — but Phase 6 took 52 plans and six rounds and has
  still not closed. Applying that recursion to a phase that writes to a 34 GB library risks the
  pilot never shipping an album, which is the exact failure this project exists to prevent.
  *The lesson that is kept:* round 2 existed **because round 1 was declared closed and verified
  6/6 before anyone read its own diff.* Verification asks whether the must-haves were met; review
  asks whether the code that meets them is correct. Budget for one review of this phase's own
  changes — not for six.

### Carried, NOT re-decided

- ⛔ **Do NOT retry E6's mtime re-probe route.** Round 5 pulled the lever 06-03 named and never
  pulled — three file mtimes touched inside a ZFS fence, then a targeted Default-mode
  `POST /Library/Media/Updated` at file scope, HTTP 204, measured after a 19,597 s settle. **ZERO of
  the three rows moved** (0 against a target of 4, 1 against 2, 1 against 2), the 1,244-row census
  delta was **empty**, and `PreferNonstandardArtistsTag` re-read `true` afterwards. It is a
  **MEASUREMENT, not an UNKNOWN** — the `LibraryMonitor` named all three Audio items, so the refresh
  ran and reached them and the prober still did not re-read `ARTISTS`. **Measured false for this
  estate at Jellyfin 10.11.11** (`DEF-06-45-02`). The remaining untried mechanism is a genuine write
  or new import — Phase 7's own work. **Do not spend the first hour on the mtime route.**
- ⛔ **`FullRefresh` / per-item aggressive refresh stays FORBIDDEN** (D-24, Phase 6). Phase 1
  measured "Refresh metadata" rewriting **83 of 91** `.nfo` even with `SaveLocalMetadata` off. The
  two buttons sit next to each other and only one is safe.
- **Jellyfin is proven FIRST, Music Assistant LAST** (D-25, Phase 6) — **MA never purges stale
  entries**, and the ZFS fence does not cover MA's `library.db`.
- **Path formats are locked** (D-13 … D-19b, Phase 6): `DJ/` top-level sibling; multi-disc **flat
  and disc-prefixed** (`2-05 Title.ext`, one directory per album — `Disc N/` subdirectories are the
  shape that hard-failed the retired tagger); `comp:` overridden to resolve to `$albumartist`, never
  deleted; `%aunique{}` kept; singletons on their own rule.
- **`check-music-consumers.sh` exits 3, and that is NOT a CONF-04 completion signal.** The surviving
  `MA_REPORTED: 1` is a reported measured discrepancy owned by **E6's second measurement** (D-05).
  The script exits 3 on branch A and branch B alike.
- **`import.copy`, never `move`** — criterion 8 and `CLAUDE.md` § Constraints. `tank` has
  **5.26 T avail** (re-measured 2026-09-24; the 9 T figure was stale by ~3.7 T). **Re-measure before
  leaning on it again.**

### Claude's Discretion

- The seed and the exact derivation script for the four fresh draws, following `06-SAMPLE.md`'s
  `LC_ALL=C` mechanism.
- The precise `jq` shape of D-11's AMBIGUOUS classification, and where the new exit state sits in
  `diff-music-tags.sh`'s existing 0/1/2 contract.
- Which Jellyfin and Music Assistant API endpoints serve the D-24 (E5) and D-28 (E8) readings.
- The exact `docker exec` invocation shape for D-08 and D-09, and flask's appdata path layout.
- Whether the D-19 snapshot register lives in `artifacts/` or as a committed top-level record.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The phase's own definition
- `.planning/ROADMAP.md` § *Phase 7: Pilot — 12 Albums End to End* — the eight success criteria and
  the twelve inherited entry criteria **E1 … E12**. Read all of it; several criteria carry dated
  in-band corrections that supersede their own original text (E6 especially).
- `.planning/REQUIREMENTS.md` — IMPT-01, IMPT-02, CONS-04, QUAL-02, QUAL-03, QUAL-04.
  **`REQUIREMENTS.md:152` carries an UNTICKED `- [ ] CONF-04`** and it stays that way until E6
  discharges; the `negative-carry-e6` override is an auditable carry of an OPEN requirement, never
  a close.
- `.planning/PROJECT.md` § *Constraints* and § *Key Decisions* — no `beet undo`; `tank/downloads`
  and `tank/media/Music` are separate datasets so every move is copy-then-unlink; ownership
  `568:568` with modes at `0777`; the `missing_album_artist_action: folder_name` conditional-firing
  row (D-28); the `Def Leppard/Def Leppard (2015)/` live defect (D-24).

### What Phase 6 decided and measured
- `.planning/phases/06-tagger-configuration-and-dry-run/06-CONTEXT.md` — **D-01 … D-36**. The path
  formats, the consumer decisions, the `:ro` invariant this phase lifts, and D-04's rule that only
  flask's 2.12.0 ever opens the real `library.db` (which constrains D-08).
- `.planning/phases/06-tagger-configuration-and-dry-run/06-SAMPLE.md` — the strata S1 … S7, the
  population table, the `LC_ALL=C` draw mechanism, the ten drawn folders with their measured
  attributes, and § *What this sample does NOT cover* (rule 2 unexercised; no `TKEY`/`EnergyLevel`;
  **zero WAV**). **D-04 and D-09 are unreadable without this file.**
- `.planning/phases/06-tagger-configuration-and-dry-run/06-EXPECTED-TREE.txt` — 174 pre-committed
  path lines. D-07 freezes six of its rows **by commit**, not by re-derivation.
- `.planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md` — `DEF-06-45-01` (the
  held snapshot and its rewritten mechanical trigger), `DEF-06-45-02` (**the disproven mtime
  lever**), `DEF-06-45-03` (the E5-not-E6 hypothesis), `DEF-06-45-04` (drive every zero-expecting
  recipe against a control), `DEF-06-29-04` (`arm1.dump` unsized), `DEF-06-29-05` (E12's four
  hardenings), `DEF-06-21-01` (the config-sha256 dependency conflict D-22 resolves),
  `DEF-06-21-06` (the undriven overlay-key half), `DEF-06-52-01`/`-02`.
- `.planning/phases/06-tagger-configuration-and-dry-run/06-VERIFICATION.md` — `status: gaps_found`,
  **5/6**, un-rescored. CONF-04 is the single failing truth.
- `.planning/phases/03-tagger-spike/03-DECISION.md` — the two-axis decision: engine = beets, front
  end = beets-flask's **policy inboxes**, explicitly **not** its picker (disqualified on measured
  safety). D-20 depends on that distinction.

### The instruments this phase uses and changes
- `scripts/snapshot-music-tags.sh` — the QUAL-01 capture. **Its four pinned roots are the whole of
  D-01's argument.** `audio_md5` is the key because it survives the move and the rename.
- `scripts/diff-music-tags.sh` — the QUAL-02 gate, exit-0/1 contract. **Line 156's `reduce` is the
  defect D-11 fixes.**
- `scripts/check-music-consumers.sh` — the standing CONF-04 drift detector; home for the D-24 and
  D-28 readings; already holds the Jellyfin API-key pattern (mode-600 check, process substitution
  so the key never enters argv).
- `scripts/quick-health-check.sh` — where D-23's standing `rw` assertion and D-25's sweep block
  land. ⚠ It has been executed **zero** times across rounds 3-6 (`DEF-06-39-05`).
- `scripts/phase06-oracle.sh` — the expected-tree differ and the destructive-program fences D-30
  exercises for the first time.
- `scripts/normalise-dj-tags.py` — dry-run-by-default, per-file NDJSON diff before writing.

### The files this phase edits
- `stacks/selfhosted/arrs/beets/config.yaml` — D-22's `import.move → copy` and the `import.write`
  record. **Editing it moves the sha256 every CONF-01/02/05 proof was measured against.**
- `stacks/selfhosted/arrs/beets/beets.yaml` and `stacks/selfhosted/arrs/beets/flask.yaml` — D-22's `:ro → :rw`; D-21's `01-auto`
  de-registration. `beets.yaml` lines 45-60 record the s6/`lsiown` boot race: gate on
  `docker exec -u abc … test -r /config/config.yaml`, **never on `.State.Status` alone**.
- `stacks/selfhosted/arrs/beets.md` — the durable operational record. Its head carries a pointer to
  the authoritative current state **by heading text, never line number**; any closure section this
  phase adds must update that pointer **in the same commit**.

### Conventions that bind this phase
- `CONVENTIONS.md` — **1** (fail closed; "could not look" ≠ "nothing is wrong") binds D-11/D-25;
  **4** (overrides may only ever make a check redder) binds D-23; **5** (pinned counts) binds D-27;
  **6** (the two-layer destructive fence duplicated at each call site) binds D-16; **8**/**9**
  (bracketed counted tokens, grep hygiene) bind every published count; **10** (byte-identity
  anchored to a commit, never the index) binds D-07; **14** (a section-scoped read is never
  sufficient evidence of absence) is why D-01 was found at all.
- `CLAUDE.md` § *Constraints* — `rsync -rlt --no-p --no-o --no-g` on `tank`; **never accept a match
  without a track-count check**; the corrected **5.26 T** free figure.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`scripts/snapshot-music-tags.sh` + `scripts/diff-music-tags.sh` are the QUAL-02 pair, already
  built.** Criterion 4 is a **script invocation with an exit-code contract**, not a judgement call —
  which is the single biggest piece of leverage this phase has. The join is on `audio_md5`
  (`ffmpeg -map 0:a -c copy -f md5 -`, encoded bitstream only) precisely so the key survives the
  move from `downloads/` to `media/Music/` and the `ALBUMARTIST/Album/NN Title` rename. A
  path-keyed diff would report every file as both `MISSING_AFTER` and `NEW_AFTER`.
  The snapshot records the **complete** `-show_format -show_streams` output, so `TKEY`,
  `EnergyLevel` and every other DJ field fall out with no whitelist to maintain. It is resumable
  via a `.done` ledger, gzip-appended per record so an interrupted run leaves a salvageable file.
  ⚠ It also already reports **how many matched files had ZERO tag fields on the BEFORE side**, so
  *"no fields dropped"* cannot be read as a pass when it is really *"there was nothing to drop"* —
  that counter must be read, not just the exit code.
- **`scripts/check-music-consumers.sh`** — the standing both-consumer assertion, with
  `ARTIST_PROOF_ROWS` and the Jellyfin API-key handling pattern already in place. Natural home for
  D-24's 30-item reading and D-28's `%aunique{}` verification.
- **`scripts/phase06-oracle.sh`** — 3,274 lines, `--self-test` at 140 cases, carrying the
  destructive-program fences D-30 confirms under the container's `dash` for the first time.
- **`06-EXPECTED-TREE.txt`** — a prediction committed in git before the dry run. D-07's freeze turns
  the pilot into a test of that prediction rather than a fresh derivation.

### Established Patterns

- **Fail closed, and keep "could not look" distinct from "nothing is wrong."** Binds D-11, D-12,
  D-25. Phase 1 measured a path-set comparison returning a perfect pass while Jellyfin rewrote 83 of
  91 `.nfo`.
- **Prove capable of failing, not merely observed passing.** Binds D-12 and D-25 directly — a
  zero-expecting count is driven against a control **first**, or the zero is the zero of an
  instrument that could never match (`DEF-06-45-04`; `grep -cF` over a bracketed needle).
- **Measure AFTER the edit lands, not by an assertion written beforehand.** Eight consecutive rounds
  of the self-referential-count hazard (`DEF-06-39-06`) were caught this way and none other.
- **Anchor byte-identity to a commit, never the index.** `git diff --exit-code HEAD -- <path>` — the
  `HEAD --` is load-bearing; a bare `git diff --exit-code <path>` compares against the **index** and
  is blind to a staged edit.
- **Bound remote commands Linux-side.** macOS has no GNU `timeout`, and `timeout N cmd | wc -l`
  exits 0 silently — the remote string needs `set -o pipefail` and the ssh RC must be read.
- **Read ownership and paths from atlantis as real root, never from LXC 100.** The container is
  unprivileged with a sparse idmap, so unmapped on-disk ids surface as `65534`. This is how the
  `apps:nogroup` reading was wrong, and it is why D-16's `fast/appdata/arrs` finding had to be
  measured on the host.
- **Never assert on a ZFS devid** — they moved twice inside Phase 5 (68/76 → 70/75 → 70/81).
- **`zfs diff` is NOT a valid scope instrument where files were renamed** — it collapses
  renamed-and-modified into a single `R`. Plan 05-09 discovered its `zfs diff` evidence was vacuous
  for exactly this reason.

### Integration Points

- **beets-flask via `docker exec` on its own 2.12.0** is the **only** route to the real
  `library.db` (D-04). The dormant 2.13.1 survivor always takes a throwaway `-l`. This constrains
  D-08, D-09 and any `beet` the sweep adds.
- **Jellyfin REST** for the targeted scan — `POST /Library/Media/Updated` at **file scope**, Default
  mode, the one write verb round 5 used. Key at `/mnt/fast/secrets/jellyfin-deercrest.env`.
  ⚠ **Resolve the container address fresh every call** — it was recorded wrong in two consecutive
  plans (`192.168.90.25` in the prose, `192.168.90.17` from `docker inspect`). Never pin the literal.
  `LibraryMonitorDelay = 60`, so log lines appear ~60 s after the POST.
- **Music Assistant API** — 2.11 beta has no token UI: username+password → 90-day JWT, log in per
  run. Responses are **not** `.result`-wrapped, and `music/albums/count` **silently ignores its
  `provider` argument**.
- **ZFS on atlantis** — `tank/media/Music` (33.9 GB) and `fast/appdata/arrs` are both real datasets
  and both snapshottable. `zfs get atime tank/media/Music` is **`off`** (relatime `on`), so an
  atime-driven surprise in a `zfs diff` is anticipated rather than mysterious. ZFS frees space
  asynchronously — `zfs list` can lag a large delete by ~20 s.

</code_context>

<specifics>
## Specific Ideas

- **The operator overruled the recommended option twice in this discussion**, both times toward the
  stronger or wider action: bucket composition (took *Bucket A + the DJ pair* over *Bucket A only*,
  which forces E1 to be solved rather than deferred a fourth time) and the snapshot register (took
  *inventory **and prune*** over *inventory, destroy none*). This matches Phase 6's recorded pattern
  — *"the operator chose the strongest option over the recommended one twice."*
  **Downstream agents must not quietly simplify back toward the cheaper option.**

- **The operator's standard for a release condition is MECHANICAL, and it is a stated principle
  rather than a one-off.** Their words on rewriting `DEF-06-45-01`: *"planning is a document, not a
  fence, and the item drifts again. Make the release condition mechanical and already-scheduled…
  That's an event someone already has to produce evidence for, so the item closes on a commit
  rather than on remembering… one named trigger, no judgement left in it."*
  D-17 honours that by **not** re-adding a gate, and D-19's prune rule was made mechanical for the
  same reason. Where this context leaves a trigger, it names the event that fires it.

- **The operator raised the 1.3 T archive unprompted, as an import-scope question.** That instinct
  was right and it is why D-01 exists: the archive would have reached the sample draw eventually,
  and the QUAL-01 gap would then have been discovered *after* folders were chosen. Their framing —
  *"when and how that gets added to the import scope"* — is preserved as two decisions (D-02 the
  when, D-03 the what-goes-with-it) rather than one vague intention.

- **The DJ collection is working material, not an archive to be hidden** (D-17, Phase 6). The
  operator DJs with Traktor, Algoriddim djay and Rekordbox and **cannot play or build crates from
  untagged tracks**. This is why the S5 pair stayed in the sample and why D-08 exists at all — and
  why the protected DJ-field list (`bpm`, `initialkey`/`TKEY`, `EnergyLevel`, `genre`, `comment`)
  must survive the pilot's writes. MusicBrainz carries **none** of them, so a MusicBrainz-driven
  import is the specific thing that strips exactly what makes a track playable.

</specifics>

<deferred>
## Deferred Ideas

- **The 1.3 T `mybook-music-archive` phase** — inserted between Phase 8 and Phase 9 (D-02),
  covering the QUAL-01 capture over 165,467 audio files and the dedupe of 21,923 groups /
  211.8 GiB. **Enacting this in `ROADMAP.md` is `/gsd-phase` work and is deliberately not done by
  this context commit.** Sequencing constraint: read the `.musiclibrary` playlists **before** any
  dedupe pass.
- **DUPE-01 / DUPE-02** — folded into that same phase (D-03). Phase 7's exposure is controlled by
  D-11's fail-closed gate, not by the reconciliation.
- **`CLAUDE.md`'s stale figures.** It carries the **144-folder** backlog denominator **twice**, and
  a *"~46 MusicBrainz entries"* DJ baseline. Measured 2026-09-22: **450 distinct DJ releases** in
  the archive alone, plus `mac-music-archive`'s 23,874 uncharacterised entries. Both numbers are
  stale in the direction that matters. Correct them where a plan already touches that file —
  restating an unverified number launders it.
- **Bucket B — the *Now!* series.** S4 dropped from the sample (D-04). NOWB-01/02 remain *Beyond
  This Milestone*: a manual confirmation budget, not a config fix, since `preferred.countries` is a
  distance weight and cannot beat a candidate that matches better on content.
- **E2's first real `bootleg` exercise** (D-26). The gate stays untested-by-import; only its
  predicate is asserted here.
- **DJ path rule 2 exercised by a real import** (D-09 asserts it read-only). Phase 9, where DJ
  content arrives in volume.
- **BPM / key / energy generation for the ~616 `dj-mixes` files that carry none.** Only 148 of 764
  carry `TKEY`, 45 carry `EnergyLevel`. Those beets plugins **rewrite audio files** — the operation
  this project has most carefully kept off. Own phase, own fence. Directly valuable to the
  operator's DJ workflow, so a real backlog item.
- **`mac-music-archive/`'s 23,874 uncharacterised music entries** — in scope for the project by
  operator decision 2026-09-19, and also lacking a QUAL-01 before-state. A natural companion to
  D-02's phase.
- **The per-file `LOCATION=…/release/NNNNNN` Discogs id** as a bulk disambiguation shortcut
  (D-28, Phase 6 / E2 of Phase 9). Validate on a batch before trusting it.
- **beets-flask's folder-count lag** past ~100 folders (D-08, Phase 6). Phase 9, where batch cadence
  is the mitigation. rc6 exposes **no** pagination or inbox-limit knob at all.
- **Three LIVE un-rotated secrets on LXC 100** (`DEF-06-29-09`) — `MEILI_MASTER_KEY`,
  `NEXTAUTH_SECRET`, `OPENAI_API_KEY` in `stacks/selfhosted/karakeep/.env.pre-pocket`. The repo-side
  hole is closed; **the keys are not rotated.** Not this phase's, and must not be lost.
- **23 lines / 24 pipelines of the `| grep -q`-under-`pipefail` shape remain estate-wide, five
  inverted** (`DEF-06-29-01`). Anyone adding `set -euo pipefail` to `quick-health-check.sh` arms six
  more at once — relevant to D-23 and D-25, which both touch that file.

</deferred>

---

*Phase: 7-pilot-12-albums-end-to-end*
*Context gathered: 2026-09-25*
