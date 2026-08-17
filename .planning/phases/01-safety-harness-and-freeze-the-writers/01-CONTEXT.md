# Phase 1: Safety Harness and Freeze the Writers - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Reduce `/mnt/tank/media/Music` to a state where no tagger-class process can write it, copy every
irreplaceable asset to a path no tagger mounts, and capture the before-state of existing tags —
all before a tagger is chosen (Phase 3) and before any file is staged (Phase 5).

Delivers: SAFE-01, SAFE-02, SAFE-03, SAFE-04, SAFE-05, WRIT-01, WRIT-02, WRIT-03, WRIT-04, QUAL-01.

**Not in this phase:** choosing a tagger (Phase 3), deleting losing tagger definitions (Phase 4 —
deliberately independently shippable), building the `_inbox` structure (Phase 5), the NFS export
(Phase 2, runs in parallel and inherits this phase's decided `uid:gid`).

</domain>

<decisions>
## Implementation Decisions

### QUAL-01 before-state snapshot

- **D-01:** The snapshot's primary key is an **audio-stream hash**, produced with
  `ffmpeg -i FILE -map 0:a -c copy -f md5 -`. This hashes the encoded audio bitstream only,
  ignoring the container's tag blocks, so the key survives both retagging and renaming. Path is
  recorded as an *attribute*, never as the key. Rationale: Phase 5 moves release folders into
  `_inbox` and Phase 7's import writes a new `ALBUMARTIST/Album/NN Title` path — a path-keyed
  snapshot would have zero matching rows by the time the Phase 7 diff runs.
- **D-02:** Scope is **backlog + existing library**: all 8,520 backlog files
  (`unsorted` 7,451 + `dj-mixes` 794 + `music` 275) plus the 1,244 already-tagged library files.
  ~9,764 files, ~140 GB, one full read. The library files are included despite re-importing them
  being Out of Scope, because an import writing to a colliding destination path can degrade them
  and they have no other recovery path.
- **D-03:** Storage is **gzipped NDJSON** — one full `ffprobe` JSON object per line, keyed by the
  audio hash. Streams as written so an interrupted run is salvageable. One file, placed inside the
  fence.
- **D-04:** **Both the snapshot script and the diff script ship in this phase**, committed under
  `scripts/`. The success criterion is a trial diff of the snapshot against itself returning zero
  differences — that gate is unmeetable unless the diff tool exists now. Phase 7 consumes the same
  diff script unchanged.
- **D-05:** Capture the full `ffprobe` output per file (format tags + per-stream tags), not a
  selected field list. `TKEY` and `EnergyLevel` (SAFE-03) fall out of this automatically.

### Recovery fence

- **D-06:** Fence artifacts live under **`/mnt/fast`, outside `appdata` and outside `stacks`** —
  e.g. `/mnt/fast/safety/music-pre-project/`. Different physical device from `tank`, and no
  container mounts that path. Total payload is well under 1 GB.
- **D-07:** The **54 cover scans and every `library.db` copy also go off-box to the Mac Mini**
  (the agentic-os host). These are the genuinely irreplaceable items. The NDJSON and the dj-mixes
  `ffprobe` dump stay on-host.
- **D-08:** "No tagger can write here" is **proven, not asserted**: enumerate the mounts of every
  *running* container and assert none resolves to the fence path. This is the same audit WRIT-01
  needs for the library, so it is one check covering both.
- **D-09:** ZFS snapshots cover **`tank/media/Music` *and* `tank/downloads`**, taken in the same
  step. The roadmap names only `tank/media/Music@pre-project`; `tank/downloads` is added because
  Phase 5 performs real destructive filesystem work (`mv` between policy folders, splitting the
  45 GB `Now! 1-115` set) with no other undo. Snapshots are near-free; only divergence costs space.
- **D-10:** The fence is one step: ZFS snapshots + `library.db` copies + dj-mixes `ffprobe` dump +
  cover scans + QUAL-01 NDJSON, with spot-checks confirming copies match source.

### Ownership (WRIT-04)

- **D-11:** The decided value is **`568:568` (`apps:apps`)**. This is already the estate convention
  in four places — `STANDARDS.md:141`, `DEPLOYMENT.md:31`, `README.md:29`, `CLAUDE.md:52` — and the
  single artist folder already at `568:568` is the correct one. The twelve at `568:65534` are drift:
  `65534` is `nogroup`, i.e. something wrote with an unmapped gid. `568:545` (what `beets.md`
  instructs) is a Windows/SMB-era convention with no basis on this host and matches no folder.
- **D-12:** Mode bits are **`0755` for directories, `0644` for files** — world-readable,
  owner-writable. This is `CLAUDE.md`'s "Option A" for the Phase 2 export: `root_squash` squashes
  harmlessly because everything is world-readable anyway. Correct specifically because WRIT-01
  leaves one writer, so nothing needs group write. Note ZFS `acltype=nfsv4` ACLs are not exported
  by knfsd, so mode bits are the only lever NFS clients see.
- **D-13:** **Normalise now** — `chown`/`chmod` across all 13 artist folders and 1,244 files in this
  phase, not deferred. WRIT-04's wording is "normalised", the success criterion is that `stat`
  returns one value, and Phase 2's export inherits it.
- **D-14:** `beets.md`'s `chown -R 568:545` instruction is **wrong under this decision and must be
  corrected** as part of this phase.

### Jellyfin freeze (SAFE-05)

- **D-15:** `SaveLocalMetadata` off for the **Music library only**. Movies and TV keep their
  sidecars — unrelated to this project, and this is a Jellyfin instance actively serving the house.
- **D-16:** **Real-time file monitoring off for the Music library**; the global scheduled scan task
  is left alone so other libraries keep updating. This is the second layer, not the first — with
  `SaveLocalMetadata` off a scan cannot write sidecars anyway.
- **D-17:** The freeze is **permanent**, recorded as a Key Decision in PROJECT.md. Once one tagger
  owns the tree, Jellyfin writing metadata into it is a second writer by another name. Nothing to
  remember to undo.
- **D-18:** Existing `.nfo`/`.jpg`/`.lrc` in the 13 artist folders are **inventoried and left in
  place**. The inventory is required regardless — it is the baseline the one-hour watched-folder
  test measures against. Deleting them risks losing artwork that exists nowhere else.

### Writer freeze (WRIT-01, WRIT-02, WRIT-03)

- **D-19:** **Narrow every `/mnt/tank/media` mount to its own subtree.** Eleven containers hold rw
  paths to Music today, not the two the roadmap names (see `<code_context>`). Radarr →
  `/mnt/tank/media/Movies:/media/Movies`, Sonarr → TV, Readarr → Books, and so on: container-internal
  paths stay identical so no arr needs reconfiguring. **Prowlarr's mount is deleted outright** — an
  indexer manager needs no media access. This is the only option that makes WRIT-01 structurally
  true rather than true by good behaviour.
- **D-20:** **Nobody holds rw on Music during Phases 1–3.** The winner is granted rw in Phase 6.
  Phase 3's spike needs no library writes: it measures Discogs match rates with `beet import -t`
  and a `wrtag move -dry-run`, and its normalisation work happens in `downloads`, not the library.
- **D-21:** **Jellyfin is an explicit documented exception.** It keeps `/mnt/tank/media:/media` rw
  and therefore ends up as the *sole* rw holder on Music. It is named in the repo as a deliberate
  carve-out: a consumer-class writer, disabled at the application layer (D-15/D-16), excluded from
  the WRIT-01 tagger-class count. The audit must report this explicitly — "tagger-class writers: 0;
  consumer-class writers: Jellyfin (documented exception)" — so Phase 7 knows what it is reading.
  Rationale for not going `:ro`: avoids risk to extracted-subtitle and trickplay behaviour.
- **D-22:** **wrtag** — delete the `/mnt/tank/media/Music:/music/library` mount as WRIT-02 requires
  (the mount, not just the restart policy), set `restart: "no"` and add a `profiles` gate so it
  never runs unattended. The `/music/source` mount stays. Phase 3 mounts a throwaway scratch
  directory at `/music/library` for its dry-run, so the disqualifier test is measured against a
  target that cannot be the real library. wrtag is **not deleted here** — Phase 4 owns retirement
  and is deliberately independently shippable.
- **D-23:** **Lidarr root folder** moves to a new path under `tank/downloads` (e.g.
  `/mnt/tank/downloads/lidarr-import/`) — outside the library, on the downloads dataset where
  staging belongs, and absorbable into Phase 5's `_inbox` structure later. Lidarr continues as the
  grabber (LIDR-01 is explicitly v2).
- **D-24:** **Both Lidarr write paths close**: `renameTracks` off *and* metadata consumers off.
  Lidarr's Metadata section writes `.nfo` and image files into the library independently of
  `renameTracks` — the same class of pollution SAFE-05 closes on Jellyfin, from a source the
  roadmap does not count.
- **D-25:** **Lidarr keeps a `tank/media` mount but `:ro`**, so it retains library visibility for
  existing-library matching and duplicate awareness without being able to write.
- **D-26:** All WRIT-01 verification is from **running-container mount inspection**, and WRIT-03
  verification is from **Lidarr's API**, not its UI — per the roadmap's success criteria.

### Durability and evidence

- **D-27:** Host-side changes are made durable by an **idempotent apply script and a separate
  verify script** under `scripts/`, matching the existing `setup-*.sh` / `check-*.sh` convention.
  Apply is re-runnable so a rebuilt container gets re-frozen. Verify is the WRIT-01 mount audit,
  the `stat` ownership check, the fence spot-check and the sidecar watch, in executable form.
  Terraform cannot express Jellyfin or Lidarr application settings — there is no provider — so a
  script is the honest mechanism.
- **D-28:** The SABnzbd-side `/config/scripts/beets-config.yaml` is **vendored into the repo and
  bind-mounted**, then edited to carry `scrub.auto: no`, `lastgenre.auto: no`, `embedart.auto: no`.
  This follows the proven pattern in this estate: the SABnzbd post-processing guard only survives
  container rebuilds because `scripts_init.bash` is vendored. Version-controlling this file pays
  off again in Phase 4, since its `plugins: embedart` line is the confirmed cause of the 1 Aug and
  8 Aug ingest skips.
- **D-29:** The verify script is **folded into `scripts/quick-health-check.sh`** so harness drift is
  caught on a path already in use. Precedent: the docker `created`-state blind spot left two
  containers down for six weeks while checks reported a clean estate.
- **D-30:** Phase 1's durable evidence is recorded by **extending
  `stacks/selfhosted/arrs/beets.md`** — the decided `uid:gid`, fence paths, the Jellyfin exception,
  the mount audit output, and the corrected `chown` instruction (D-14). PROJECT.md gets the
  Jellyfin-permanence Key Decision (D-17) and the ownership decision.

### Claude's Discretion

- **Jellyfin database backup method**: `sqlite3 .backup` against the live file — consistent
  snapshot, no container downtime, no torn WAL. Not a plain `cp` (can tear) and not a stop-copy-start
  (needless downtime on a serving instance). User was told and did not object.
- Exact fence directory naming under `/mnt/fast`, script filenames, and NDJSON field layout.
- Whether the `~140 GB` hash run is chunked or checkpointed for resumability — raised as a possible
  further gray area, not discussed. Planner should make it resumable; NDJSON's append-per-line
  format (D-03) already supports this.
- Ordering of the snapshot relative to the `chown`/`chmod` — raised, not discussed. Note it changes
  what the fence captures; planner should sequence deliberately and state the choice.
- Whether soulbeet is frozen here or left entirely to Phase 4 — raised, not discussed. Its image is
  gone from GHCR so it cannot run, meaning WRIT-01's running-container audit passes either way; its
  `/mnt/tank/media/Music:/music` mount is still declared in `arrs/soulbeet.yaml`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/ROADMAP.md` § "Phase 1: Safety Harness and Freeze the Writers" — the six success
  criteria this phase must make true, and why phase ordering is load-bearing
- `.planning/REQUIREMENTS.md` § Safety / Writers / Quality — SAFE-01…05, WRIT-01…04, QUAL-01
- `.planning/PROJECT.md` § Constraints — `rsync` failure mode, separate-datasets copy-then-unlink,
  no `beet undo`, ZFS async free, ownership-is-undecided
- `.planning/PROJECT.md` § Context — the five writers table, the backlog census, the DJ field-mapping
  samples

### Prior art and estate conventions
- `stacks/selfhosted/arrs/beets.md` — library state, A–D bucket triage, the two config gaps, and
  the hard-won gotchas. **This phase extends it (D-30) and corrects its `chown -R 568:545`
  instruction (D-14).**
- `STANDARDS.md` §"Volume Mounting" line 141 — `568:568` (`apps:apps`) as the estate service account
- `DEPLOYMENT.md` line 31, `README.md` line 29 — same convention, independently stated
- `CLAUDE.md` § "Storage and Permissions" — service account, GPU groups, repo/appdata paths
- `CLAUDE.md` § "Music Assistant on HAOS" — the `0755`/`0644` + `root_squash` "Option A" vs
  `all_squash` "Option B" export models that D-12 selects between

### Stack definitions this phase modifies
- `stacks/selfhosted/music/wrtag.yaml` — line 40, the `/mnt/tank/media/Music:/music/library` rw
  mount that WRIT-02 deletes (D-22)
- `stacks/selfhosted/arrs/lidarr.yaml` — the `/mnt/tank/media:/media:rw` mount (D-25) and
  `UMASK_SET: 002`
- `stacks/selfhosted/media/jellyfin.yaml` — line 93, `/mnt/tank/media:/media` with **no `:ro`**
  (D-21 keeps this as the documented exception)
- `stacks/selfhosted/arrs/radarr.yaml`, `sonarr.yaml`, `bazarr.yaml`, `readarr.yaml`,
  `janitorr.yaml`, `prowlarr.yaml` — the other broad `/mnt/tank/media` rw mounts narrowed by D-19
- `stacks/selfhosted/arrs/beets/beets.yaml` — `/mnt/tank/media:/media:rw`, `restart: "no"`,
  `profiles: ["manual"]`
- `stacks/selfhosted/arrs/soulbeet.yaml` — line 37, `/mnt/tank/media/Music:/music`

### Host-side (not in git today)
- `/config/scripts/beets-config.yaml` on LXC 100 — vendored into the repo by D-28
- `scripts/quick-health-check.sh` — the verify script folds in here (D-29)
- `scripts/` `setup-*.sh` / `check-*.sh` — the naming convention D-27 follows

</canonical_refs>

<code_context>
## Existing Code Insights

### The rw-mount inventory (found during scout — larger than the roadmap states)

The roadmap names wrtag and Lidarr. Eleven containers actually hold a read-write path that
contains `/mnt/tank/media/Music`:

| File | Mount | Note |
|---|---|---|
| `arrs/bazarr.yaml` | `/mnt/tank/media:/media:rw` | subtitle placement |
| `arrs/beets/beets.yaml` | `/mnt/tank/media:/media:rw` | `restart: "no"`, `profiles: ["manual"]` |
| `arrs/janitorr.yaml` | `/mnt/tank/media:/data:rw` | its job is deleting |
| `media/jellyfin.yaml` | `/mnt/tank/media:/media` | **no `:ro`** — rw by default |
| `arrs/lidarr.yaml` | `/mnt/tank/media:/media:rw` | the uncounted fifth writer |
| `arrs/prowlarr.yaml` | `/mnt/tank/media:/media:rw` | indexer manager — needs no media at all |
| `arrs/radarr.yaml` | `/mnt/tank/media:/media:rw` | movies |
| `arrs/readarr.yaml` | `/mnt/tank/media:/media:rw` | books |
| `arrs/sonarr.yaml` | `/mnt/tank/media:/media:rw` | TV |
| `music/wrtag.yaml` | `/mnt/tank/media/Music:/music/library` | direct, rw |
| `arrs/soulbeet.yaml` | `/mnt/tank/media/Music:/music` | image gone from GHCR, cannot run |

`media/seerr.yaml` is the only one already correct: `/mnt/tank/media:/data:ro`.

### Reusable assets
- `scripts/quick-health-check.sh` and `scripts/check-server-health.sh` — existing health-check
  entry points; D-29 extends the former rather than adding a new habit
- `scripts/setup-*.sh` — the idempotent-setup-script convention D-27 follows
- `backups/` at repo root exists and is **empty** — considered and rejected as the fence location
  (D-06); ~200 MB of cover scans in git history is a permanent cost
- The SABnzbd `scripts_init.bash` vendoring pattern — the proven mechanism D-28 reuses

### Established patterns
- A `.md` beside the stack it documents (`arrs/beets.md`, `media/dispatcharr.md`) — D-30 extends
  `beets.md` rather than creating a new file
- Stack service files carry a header comment block (`STANDARDS.md` § "Service File Structure")
- Terraform is authoritative for host/LXC/VM resources only; application settings inside containers
  have no provider — hence D-27

### Integration points
- **Phase 2 inherits D-11/D-12**: `568:568` becomes `anonuid`/`anongid` and `0755`/`0644` governs
  what NFS clients can read (NFSv4 ACLs are not exported by knfsd)
- **Phase 3 depends on D-22**: wrtag must still be invokable for the `wrtag move -dry-run`
  disqualifier test, against a scratch target
- **Phase 4 inherits D-22/D-28**: deletion of losing definitions, and a vendored SAB beets config
  that is already under version control when its beets block is stripped
- **Phase 5 depends on D-09**: the `tank/downloads` snapshot is the only undo for its `mv`-based
  triage and the `Now! 1-115` split; and on D-23, whose `lidarr-import/` path it absorbs
- **Phase 6 grants rw** to the surviving tagger — the first time anything holds it again (D-20)
- **Phase 7 depends on D-01…D-04**: the diff script and the hash-keyed snapshot are what QUAL-02
  compares against. Without the audio-stream key, the diff has no matching rows.

</code_context>

<specifics>
## Specific Ideas

- The audio-stream hash must be computed with `-c copy`, not a decode — the point is to hash the
  encoded bitstream so tag rewrites do not perturb it.
- The WRIT-01 audit output must distinguish **tagger-class** from **consumer-class** writers. A bare
  count of one would be misleading, because that one is Jellyfin (D-21).
- The one-hour watched-folder test for SAFE-05 needs the D-18 sidecar inventory as its baseline, or
  a pre-existing `.nfo` is indistinguishable from a new one.
- The trial self-diff (roadmap criterion 6) must exercise the **diff script**, not merely re-run the
  snapshot and compare hashes — re-running proves determinism, which is a weaker claim.

</specifics>

<deferred>
## Deferred Ideas

- **Narrowing the non-music arr mounts is estate hygiene beyond this project's mandate.** D-19
  takes it on anyway because it is the only way WRIT-01 is structurally true. If it proves larger
  than expected during planning, the music-adjacent containers are the required subset and the rest
  can be split out — but say so explicitly rather than silently narrowing scope.
- **Replacing Lidarr as the grabber** — LIDR-01, already recorded in REQUIREMENTS.md v2 and
  ROADMAP.md § Beyond This Milestone. D-23/D-24/D-25 remove the harm Lidarr does to *this* project;
  dissatisfaction with it as a grabber stays out of the milestone.
- **Making Jellyfin's Music mount genuinely `:ro`** — considered (verify extracted subtitles and
  trickplay target `/config`, then flip). Rejected here in favour of the documented exception. Worth
  revisiting once the tagger owns the tree.
- **Clearing the existing `.nfo`/`.jpg`/`.lrc` sidecars** — considered and deferred (D-18). Revisit
  if they cause path collisions during Phase 6/7.

</deferred>

---

*Phase: 1-safety-harness-and-freeze-the-writers*
*Context gathered: 2026-08-17*
