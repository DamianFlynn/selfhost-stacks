# Architecture Research

**Domain:** Self-hosted music tagging pipeline — download → tag → library → multiple playback consumers
**Researched:** 2026-08-17
**Confidence:** MEDIUM-HIGH (component semantics verified against official docs; host-specific facts flagged for verification)

---

## The Governing Principle

Everything below follows from one rule:

> **The library tree is an output, not a workspace. Exactly one process writes it. Everything else reads it.**

The estate's documented failure mode — three beets instances with separate `library.db` files, plus a
running `wrtag` container, plus a per-download `audio.bash` beets that deletes its own `library.blb`
every run, all pointed at `/mnt/tank/media/Music` — is not "too many taggers". It is **multiple
writers with private, divergent state over a shared destination**.

Each writer's database claims to describe the tree. None of them does. There is no reconciliation
path because the tree cannot tell you which writer produced any given file. That is why the pipeline
was rebuilt three times: every rebuild started by re-deriving state that was never authoritative.

The architecture that prevents this is not "choose a better tagger". It is:

**One writer. One state store. Route at the input, never at the writer.**

Any design where two processes can rename, move, or re-tag the same path reintroduces the bug,
regardless of which tools are chosen.

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│  ACQUISITION                          (LXC 100 · unprivileged · Docker)   │
├──────────────────────────────────────────────────────────────────────────┤
│  ┌───────────┐   ┌──────────┐   ┌────────────┐                           │
│  │  Lidarr   │──▶│ SABnzbd  │   │  manual    │                           │
│  │ (search)  │   │(download)│   │  NZB drop  │                           │
│  └───────────┘   └────┬─────┘   └─────┬──────┘                           │
│                       │               │                                   │
│              writes only to ──────────┘                                   │
└───────────────────────┼──────────────────────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  STAGING — dataset: tank/downloads          (never under media/)          │
├──────────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐      │
│  │ 01-auto  │ │02-review │ │ 03-asis  │ │ 04-hold  │ │99-quarantine│     │
│  │ bucket A │ │ bucket B │ │ bucket C │ │ needs    │ │  bucket D   │     │
│  │          │ │  (Now!)  │ │   (DJ)   │ │ sourcing │ │ _FAILED_/rar│     │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────────┘ └────────────┘      │
└───────┼────────────┼────────────┼────────────────────────────────────────┘
        │            │            │
        └────────────┴────────────┘   routing happens HERE
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  TAGGER — ONE process · ONE library.db · SOLE WRITER of the library       │
├──────────────────────────────────────────────────────────────────────────┤
│    inbox policy: auto / preview(human) / bootleg(as-is)                   │
│    path-format rules split the DESTINATION, not the pipeline              │
│    semantics: COPY (never move) · incremental · per-release unit of work  │
└──────────────────────────┬───────────────────────────────────────────────┘
                           │  copy, cross-dataset
                           ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  LIBRARY — dataset: tank/media/Music        READ-ONLY to everyone else    │
├──────────────────────────────────────────────────────────────────────────┤
│   <AlbumArtist>/<Album>/…        Compilations/<Album>/…                   │
│   DJ-Mixes/<Series>/<Issue>/…                                             │
│   art + tags supplied BY THE TAGGER — no consumer writes here             │
└───────┬──────────────────────────────────────────┬───────────────────────┘
        │ bind mount :ro                           │ NFSv4 export :ro
        │ (same host)                              │ from Proxmox HOST .158
        ▼                                          ▼
┌────────────────────┐                  ┌──────────────────────────────────┐
│ Jellyfin           │                  │ Home Assistant OS · NUC .31      │
│ 172.16.1.159       │                  │  HA network storage (type=Media) │
│ metadata savers    │                  │        ↓ /media/<name>           │
│ OFF                │                  │  Music Assistant                 │
│ (no .nfo/.jpg/.lrc)│                  │  Filesystem (local disk) provider│
└────────────────────┘                  └──────────────────────────────────┘
```

### Component Responsibilities

| Component | Owns | Explicitly does NOT own | Notes |
|-----------|------|-------------------------|-------|
| **Lidarr** | Deciding *what* to acquire; talking to indexers; grab history | Filenames, folder layout, tags, the library tree | Root folder must **not** be `/mnt/tank/media/Music` under this design — see Boundary Decision below |
| **SABnzbd** | Fetching bytes, par2 repair, unpack, dropping a finished folder in staging | Any tagging, any move into the library | Post-processing must stay thin — see Pattern 5 |
| **Staging tree** | Holding untagged/undecided content; encoding the *routing decision* as a directory | Metadata correctness | Lives under `tank/downloads`, never under `media/` |
| **Tagger** (single instance) | Tags, artwork, path layout, the library tree, the state store | Acquisition, playback, transcode | Sole writer. Sole holder of import state |
| **Library dataset** | Being the durable, canonical artifact | Nothing — it is inert | Every non-tagger mount is `:ro` |
| **Jellyfin** | Playback + its own metadata cache in `/config` | Writing into `/media/Music` | `SaveLocalMetadata` and NFO savers **off** |
| **Music Assistant** | Playback/streaming to HA media players; its own playlists | Writing into the share | Read-only mount; playlists go to MA's builtin provider |
| **NFS export** | Serving the library to the NUC | Anything else on `tank` | Export the Music dataset only, `ro`, host-restricted |

---

## Boundary Decision: Where Tagging Belongs

Three candidate placements, judged on failure isolation.

| Placement | How it fails | Verdict |
|-----------|--------------|---------|
| **In SABnzbd post-processing** (`audio.bash`, current) | SABnzbd's post-processing queue is **serial** — one slow or hung script stalls every job behind it, and there is no built-in script timeout. Failures are invisible: the current script logged `skip` on its last two jobs (1 Aug, 8 Aug) and nothing noticed. Tagging state is per-job, so there is no library-wide view. Fixing it means detaching the child process, which throws away the exit code SAB would have surfaced — you lose the only signal you had. | **Reject.** This is where the current pipeline is already failing silently. |
| **Watch-folder / inbox service** | Runs on its own clock, so a hung release blocks nothing upstream. Holds one persistent state store. Can apply *different policy per inbox*. Risk: an unattended `auto` mode over unreviewed content writes wrong matches into the library — mitigated by per-inbox policy (`preview` for anything uncertain) plus a snapshot fence. | **Recommended.** Isolation is structural, not procedural. |
| **Purely manual / batch** (current `beets` profile) | Maximum control, zero throughput. This is the state the estate is already in: last import 18 Nov 2025, 97 GB backlog. The failure mode of manual-only is *abandonment*, which PROJECT.md names as the one outcome that must not happen. | **Reject as the only path.** Keep as an escape hatch (web terminal) for individual awkward releases. |

**Decision: a watch-folder/inbox service, with per-inbox policy, and a manual escape hatch inside the
same process.** Not a separate manual tool — the same binary and the same state store, invoked
differently. The moment "manual" means "a second container with its own database", the original bug
is back.

---

## Recommended Structure

```
/mnt/tank/downloads/                          ← ZFS dataset: tank/downloads
└── complete/nzb/
    ├── music/                                ← SABnzbd `music` category; Lidarr's grab target
    ├── unsorted/                             ← existing 97 GB backlog (source of truth, untouched)
    ├── dj-mixes/                             ← existing 25 GB backlog (untouched)
    └── _inbox/                               ← NEW. The routing layer. Folders are MOVED here.
        ├── 01-auto/                          ← bucket A. autotag, import if score passes
        ├── 02-review/                        ← bucket B. tag, present candidates, wait for a human
        ├── 03-asis/                          ← bucket C. import from existing tags, no autotag
        ├── 04-hold/                          ← needs external artwork/tracklist sourcing first
        ├── 99-quarantine/                    ← bucket D. _FAILED_, _UNPACK_, stray .rar, non-music
        └── _done/                            ← post-import receipts; safe to prune later

/mnt/tank/media/Music/                        ← ZFS dataset: tank/media/Music — TAGGER WRITES ONLY
├── <AlbumArtist>/<Album>/NN Title.ext
├── Compilations/<Album> (Year)/NN Artist - Title.ext
└── DJ-Mixes/<Series>/<Issue>/NN Title.ext    ← separate path-format rule, same tagger

/mnt/fast/appdata/arrs/<tagger>/config/       ← the ONE state store
├── config.yaml
└── library.db                                ← snapshot before every batch
```

### Structure Rationale

- **`_inbox/` sits under `tank/downloads`, not under `media/`.** Jellyfin's library root is
  `/media/Music` with `SaveLocalMetadata: true`; anything staged there acquires `.nfo`/`folder.jpg`/`.lrc`
  within minutes. Jellyfin's `.ignore` mechanism is *not* a safe workaround: 10.11.x changed non-empty
  `.ignore` files to gitignore-pattern semantics, and there is an open report of empty `.ignore`
  folders still being scanned (jellyfin#14502). Do not stage inside the library and rely on exclusion.
- **Routing is a directory, not a config branch.** Moving a folder into `02-review/` *is* the decision.
  It is inspectable with `ls`, revertible with `mv`, and survives a container restart with no database.
- **`unsorted/` and `dj-mixes/` are never imported from directly.** They are the immutable source. Work
  is pulled from them into `_inbox/` in batches. This is what makes "97 GB backlog" a series of small,
  abortable jobs rather than one 7,451-file run that cannot be resumed or reasoned about.
- **DJ content gets a path-format rule, not a pipeline.** `DJ-Mixes/` vs `Compilations/` is a
  destination difference. It must not become a *tagger* difference.

---

## Architectural Patterns

### Pattern 1: Single-Writer Library

**What:** Exactly one process holds a read-write mount of `/mnt/tank/media/Music`. Every other
container mounts it `:ro`. The NFS export is `ro`.

**Why it is the whole point:** With one writer, the tree is reproducible from the writer's state, and
the writer's state is checkable against the tree. With two, neither statement holds and there is no
recovery procedure — only re-import.

**Concretely, in this estate, before anything else:**

| Writer | Current state | Action |
|--------|---------------|--------|
| `beets` (manual) | `profiles: ["manual"]`, `/mnt/tank/media:rw` | Candidate to become **the** writer, or removed |
| `wrtag` | **container up, `restart: unless-stopped`, `/mnt/tank/media/Music:rw`** | Live second writer. Stop and remove, or make it the writer |
| `soulbeet` | image gone from GHCR, never deployed | Remove definition + Renovate rule |
| `audio.bash` beets | runs per SAB job, `rm`s its own `library.blb`, imports in place | Remove the beets block from the script |

**Trade-off:** Lidarr loses its ability to organise files (see Pattern 6). That is the price, and it is
worth paying.

### Pattern 2: Input-Side Routing — Many Inboxes, One Tagger

**What:** The tagger watches several directories. Each directory carries a *policy*. All of them feed
one import engine and one state store.

**This is the direct answer to "automated and manual content without two competing pipelines."**
beets-flask implements exactly this model, and its `library.db` is explicitly one per installation,
shared across all inboxes ([docs](https://beets-flask.readthedocs.io/latest/configuration.html)):

```yaml
gui:
  inbox:
    folders:
      Auto:
        name: "Bucket A — mainstream"
        path: "/mnt/tank/downloads/complete/nzb/_inbox/01-auto"
        autotag: "auto"          # import only if match beats auto_threshold
        auto_threshold: null     # falls back to beets match.strong_rec_thresh
      Review:
        name: "Bucket B — Now! series"
        path: "/mnt/tank/downloads/complete/nzb/_inbox/02-review"
        autotag: "preview"       # tag, show candidates, do NOT import
      Bootleg:
        name: "Bucket C — DJ services"
        path: "/mnt/tank/downloads/complete/nzb/_inbox/03-asis"
        autotag: "bootleg"       # import using the files' own metadata; also --group-albums
```

**Why `bootleg`/`-A` is structurally necessary, not a preference:** Mastermix, DMC, Music Factory,
Crate, Toolkit and Essential Hits are not catalogued in MusicBrainz. No MusicBrainz-backed matcher can
ever match them. A pipeline with only an autotag path has no destination for the majority of this
backlog, and the historical response to that gap was to stand up *another* tagger. The `bootleg`
inbox is what removes the motive for a fourth instance.

**Trade-offs:**
- `preview` requires a human, so bucket B throughput is bounded by attention. Correct: the Now! UK/US
  series share titles with different track listings, and an unattended match will be wrong.
- beets-flask 1.0 removed the interactive terminal import in favour of candidate selection in the UI.
  Where a MusicBrainz release ID must be pasted by hand, use the built-in web terminal — same
  container, same `library.db`.
- Folders, not files: content dropped loose in an inbox root will not trigger an import. Every inbox
  entry must be a directory.

### Pattern 3: Snapshot Fence Around Every Batch

**What:** Take a ZFS snapshot of the library dataset immediately before each import batch. Roll back
if the batch is wrong.

```bash
# before a batch (on the Proxmox host)
zfs snapshot tank/media/Music@pre-import-$(date +%Y%m%dT%H%M)
cp /mnt/fast/appdata/arrs/<tagger>/config/library.db{,.pre-import}

# if the batch went wrong
zfs rollback tank/media/Music@pre-import-20260817T1400
cp /mnt/fast/appdata/arrs/<tagger>/config/library.db{.pre-import,}
```

**Why this and not "be careful":** This is the only mechanism that makes a bad run *non-destructive*
at library scale. Undo-in-the-tagger only undoes what the tagger knows it did; a snapshot undoes
everything, including partial writes from an interrupted run and any `.nfo` a consumer slipped in.
It is near-instant and near-free on ZFS.

**Two things must be rolled back together** — the tree and the state store. Rolling back only the tree
leaves the tagger's `incremental` state claiming those releases are already imported, so a re-run
skips them. This coupling is itself an argument for keeping the state store small and snapshotting it
in the same step.

**Caveat (verify on host):** ZFS frees space asynchronously; `zfs list` can lag a large delete by ~20 s.
Snapshots also pin space — prune them after a batch is accepted.

### Pattern 4: Copy In, Never Move In (first passes)

**What:** Import with copy semantics (`import.copy: yes`, `import.move: no`) until results are trusted.

**Current state is the opposite:** `soulbeet/beets_config.yaml` has `move: yes`. A bulk run against
97 GB of known-problematic content would *consume its own source*. There is then no second attempt.

**A ZFS detail that matters here:** `/mnt/tank/downloads` and `/mnt/tank/media/Music` are **separate
ZFS datasets** (each has its own `mount_point` block in `infra/lxc-selfhost.tf`). Consequences:

- A "move" across them is **not** an atomic `rename(2)`. It is copy-then-unlink, which is interruptible
  mid-file and can leave a truncated file at the destination.
- `cp --reflink=always` / `FICLONE` fails with `EXDEV` across datasets on Linux even within one pool
  (openzfs#15345, still current in 2.3.4 per openzfs#18005). So `reflink: yes` is **not** a reliable
  free-copy shortcut on this path — do not plan around it.
- Moves *within* a dataset are atomic and instant. This is why the `_inbox/` → `_done/` queue in
  Pattern 5 works, and why the routing directories must all live inside `tank/downloads`.

**Space:** 97 GB duplicated against 9 T free is affordable and reversible. Take the duplication.

### Pattern 5: Filesystem-as-Queue (resumability)

**What:** The unit of work is a **release directory**, never "the backlog". Progress is encoded as the
folder's location, and every state transition is an atomic same-dataset `rename(2)`.

```
unsorted/<release>   --(batch pull, mv)-->  _inbox/01-auto/<release>
_inbox/01-auto/<release> --(tagger copies to library)-->  _inbox/_done/<release>
                          --(no match / low score)-->     _inbox/02-review/<release>
                          --(unmatched, not in MB)-->     _inbox/03-asis/<release>
```

**Why this is resumable across thousands of files:** a crash at any instant leaves the tree in a state
that is unambiguous by inspection — the folder is either in an inbox (not done) or in `_done/`
(done). There is no partially-updated index to reconcile. Restart is `ls`.

**Layer the tagger's own resumption on top of it, not instead of it:**

| Setting | Effect |
|---------|--------|
| `import.incremental: yes` | Records imported directories; skips them on re-run |
| `import.incremental_skip_later: yes` | *Skipped* directories are not recorded, so they get retried later rather than being silently swallowed |
| `import.resume: yes` | Resumes an interrupted import rather than prompting |
| `import.log: <path>` | The only durable record of what was skipped and why |

Note the coupling: `incremental` state lives inside `library.db`. It is exactly the state that
fragmented across three instances. With one instance it is a genuine resumability guarantee; with
several it is worse than nothing, because each instance confidently skips work another did not do.

**Never point a single import at a mega-folder.** The 45 GB `VA-Now_That.s_What_I_Call_Music__1-115_2023`
set is 115 albums in one directory. Split per volume before it enters an inbox, or it becomes one
un-abortable, un-resumable job.

### Pattern 6: Lidarr as Grabber, Not Organiser

**What:** Lidarr's root folder points at staging, not at the library. Lidarr never renames anything in
`/mnt/tank/media/Music`.

**Why:** The Servarr wiki documents two coherent Lidarr+beets arrangements, and is explicit that
mixing them — letting both rename — is the failure mode:

| Arrangement | Who writes files | Who writes tags | Fits here? |
|---|---|---|---|
| **A. Lidarr organises, tagger enriches in place** (`move: no, copy: no, write: yes`, Lidarr *Write Tags = Never*) | Lidarr | Tagger | **No.** Lidarr is MusicBrainz-backed and cannot represent DJ-service releases at all, so it can never own the whole tree. Splitting the tree between Lidarr-owned and tagger-owned regions is two writers again |
| **B. Lidarr grabs to staging, tagger owns the library** | Tagger | Tagger | **Yes.** Matches PROJECT.md: "Lidarr stays as the acquisition front end. This project is about what happens to files after they land" |

**The cost, stated plainly:** with the tagger moving/copying content out of Lidarr's root, Lidarr's
own view of "what I have" degrades — albums show as missing. Lidarr becomes a search-and-grab tool
with a monitoring list, not a collection manager. Two ways to live with it:

1. **Unmonitor after grab** (recommended). Accept that Lidarr does not know the library. Simplest, one
   writer, no duplicate storage.
2. **Copy rather than move out of Lidarr's root.** Lidarr keeps its view; you keep two copies of
   Lidarr-acquired content. Tolerable only because Lidarr accounts for 275 files / 18 GB, not the
   backlog.

If Lidarr's collection view turns out to matter more than expected, that is a signal to revisit — but
revisit it as an explicit decision, not by quietly re-pointing its root folder at the library.

### Pattern 7: Read-Only Fan-Out to Consumers

**What:** Both consumers get read-only access, enforced at the mount/export layer, not by configuration
politeness.

```
Jellyfin (LXC 100)     :  - /mnt/tank/media/Music:/media/Music:ro
Music Assistant (NUC)  :  NFSv4 export, ro, restricted to 172.16.1.31
```

**Why enforcement, not configuration:** Jellyfin's `SaveLocalMetadata: true` writes `.nfo`, `folder.jpg`
and `.lrc` into any folder it sees. That is not merely untidy here — Music Assistant's filesystem
provider **reads** `.nfo` files and `folder.jpg`/`cover.jpg`/`artist.jpg`. So one consumer's metadata
opinions become the other consumer's inputs, through a channel neither of them declares. The tagger,
meanwhile, sees files it did not create and cannot account for.

**The fix is two-sided:**
1. Turn off Jellyfin's *Save artwork into media folders* and the NFO metadata savers. Jellyfin keeps
   everything in `/config/metadata`, which it does perfectly well.
2. **Make the tagger supply the artwork** (`fetchart` + a single folder-level image; avoid embedding art
   in every track — MA's docs call per-track embedding suboptimal for both disk and scan performance).
   Then both consumers read the same art, from the one writer.

Without step 2 you have just removed everyone's artwork. Both halves ship together.

**Trade-off, accepted explicitly:** MA needs write access to the share only to store playlists on it.
Read-only means MA's playlists live in its builtin provider instead. That is the correct trade — a
consumer that can write to the library is a second writer.

---

## Data Flow

### Normal path (bucket A)

```
Lidarr decides ──▶ SABnzbd downloads ──▶ downloads/complete/nzb/music/<release>
                                                  │
                                          (mv — same dataset, atomic)
                                                  ▼
                                    _inbox/01-auto/<release>
                                                  │
                                    tagger: match ▸ score ≥ threshold
                                                  │  COPY  (cross-dataset, non-atomic)
                                                  ▼
                                    media/Music/<AlbumArtist>/<Album>/…
                                                  │
                              (mv source — same dataset, atomic)
                                                  ▼
                                    _inbox/_done/<release>
                                                  │
                     ┌────────────────────────────┴───────────────────────┐
                     ▼ bind :ro                                   NFSv4 ro ▼
                Jellyfin scan                                  HA /media/<name>
                                                                       │
                                                                       ▼
                                                              MA filesystem sync
```

### Failure paths

```
score below threshold      ──▶ _inbox/02-review/   (human picks a candidate; nothing written to library)
not in MusicBrainz at all  ──▶ _inbox/03-asis/     (imported from own tags via bootleg policy)
no tags AND no artwork     ──▶ _inbox/04-hold/     (external sourcing: Internet Archive / Mastermix direct)
junk / _FAILED_ / .rar     ──▶ _inbox/99-quarantine/ (never enters the tagger)
batch produced bad output  ──▶ zfs rollback tank/media/Music@pre-import-…  +  restore library.db
```

**Copy/move semantics, summarised:**

| Transition | Operation | Atomic? | Why |
|---|---|---|---|
| SAB output → `_inbox/*` | `mv` | Yes | Same dataset (`tank/downloads`) |
| `unsorted/` → `_inbox/*` | `mv` | Yes | Same dataset. Source folder disappears — that *is* the progress record |
| `_inbox/*` → `media/Music` | **copy** | No | Cross-dataset. Never `move` on first passes. Blast radius bounded by per-release granularity |
| `_inbox/*` → `_done/` | `mv` | Yes | Same dataset |
| library → consumers | read | n/a | `:ro` bind + `ro` NFS export |

---

## Multi-Consumer Access

### Where the export comes from

**Export from the Proxmox host (`atlantis`, 172.16.1.158), not from LXC 100.** LXC 100 is
`unprivileged = true` (`infra/lxc-selfhost.tf:107`). The Linux NFS server is kernel-side and shared;
Proxmox's `NFS` container feature is privileged-only, and running `nfs-kernel-server` in an
unprivileged container additionally requires disabling AppArmor confinement — which Proxmox staff
advise against. There is nothing to gain: `tank` is a host pool and the host can export it directly.

This puts the export in `infra/` under Terraform, consistent with the repo's rule that Terraform is
authoritative for host resources. **That is a real build-order dependency:** the export is an infra
change requiring `terraform apply`, not a compose change.

### Protocol choice

| | NFSv4 | SMB/CIFS |
|---|---|---|
| Read-only enforcement | `ro` in exports — server-side, absolute | share-level `read only = yes` |
| Auth on trusted LAN | host-restricted by IP, no credential store | needs a user DB to maintain |
| Fit with `tank` | `acltype=nfsv4` is already set on this pool | ACL translation layer |
| HA network storage | supported | supported (CIFS 2.1+) |
| MA filesystem provider | supported (IP + absolute export path) | supported (SMB 3.0+, cache mode *Loose* recommended for music) |

**Recommend NFSv4**, `ro`, restricted to `172.16.1.31`, with squashing to the library's own uid/gid so
there is no identity negotiation at all:

```
/mnt/tank/media/Music  172.16.1.31(ro,sync,no_subtree_check,all_squash,anonuid=568,anongid=545)
```

Export **only** the Music dataset — not `/mnt/tank`, not `/mnt/tank/media`. The NUC has no business
seeing Movies, TV, Photos or `timemachine`. (Confirm `568:545` against the host; `beets.md` documents
that ownership for the Music library while `CLAUDE.md` states `apps:apps` = `568:568` generally.)

**Fall back to SMB only if** HAOS mounting proves awkward; MA's own docs note most home setups use CIFS.

### Mount path on the NUC

**Recommended:** Home Assistant → Settings → System → Storage → *Add network storage*, usage type
**Media**, protocol NFS, server `172.16.1.158`, share `/mnt/tank/media/Music`. This creates
`/media/<name>`. Then add MA's **Filesystem (local disk)** provider pointed at that path.

**Why not MA's own "Filesystem (remote share)" NFS provider:** it also works, but the HA-managed mount
is the documented HAOS path, its lifecycle is managed by Supervisor across restarts and add-on
reinstalls, and it is visible/repairable in the HA UI rather than buried in add-on config. Keep the
MA-native remote share as the fallback.

**Why not MA's Jellyfin provider:** MA's own documentation states the Jellyfin source has no dedicated
developer, is maintained best-effort, and suggests sharing music with MA directly instead. It would
also make Jellyfin a dependency of MA's library — an availability coupling between two consumers that
should be independent.

### Isolation properties this buys

| Risk | Mitigation |
|---|---|
| Jellyfin writes `.nfo`/`.jpg`/`.lrc` into the tree | `SaveLocalMetadata` off **and** `:ro` bind mount |
| MA writes playlists into the tree | `ro` export — physically impossible; playlists go to MA's builtin provider |
| Jellyfin's metadata becomes MA's input | Eliminated once Jellyfin stops writing; tagger supplies art |
| One consumer down takes the other with it | No shared service — two independent read paths to one dataset |
| Consumer scan storms the tagger's import | Read-only readers cannot block a writer on ZFS; schedule scans off-peak if the box is loaded |

**Phase gate:** "content landed on disk" is not done. Done is **visible in Jellyfin AND visible in
Music Assistant.**

---

## Anti-Patterns

### Anti-Pattern 1: One Tagger Per Source

**What people do:** a tagger for Soulseek, a tagger for NZB, a tagger for DJ content — each with its own
config and database, all writing to `media/Music`. This estate did it four times.

**Why it's wrong:** N databases each claim to describe one tree. None does. Content imported by one is
invisible to the others, so `incremental` lies, duplicate detection fails, and the tree cannot be
regenerated from any single state store. Recovery requires re-importing a whole side.

**Do this instead:** one tagger, N *inboxes*, and destination differences expressed as path-format
rules. Sources differ at the input; they must converge before the writer.

### Anti-Pattern 2: Staging Inside the Library

**What people do:** drop untagged content under `/media/Music` and rely on Jellyfin exclusions.

**Why it's wrong:** Jellyfin has already written `.nfo`/`folder.jpg`/`.lrc` into it within minutes. The
`.ignore` mechanism changed semantics in 10.11.x (non-empty files are now gitignore patterns) and has
open bugs where empty `.ignore` folders are scanned anyway. Meanwhile MA will read those `.nfo` files
as truth.

**Do this instead:** stage under `tank/downloads`. Only imported output ever appears under `media/Music`.

### Anti-Pattern 3: Tagging in the Download Client's Hook

**What people do:** call the tagger from SABnzbd's post-processing script.

**Why it's wrong:** SAB post-processing is serial with no timeout, so one wedged release stalls the
whole queue; the tagger's failure surfaces as a queue that "looks slow"; and per-job state means the
tagger never sees the library. `audio.bash` logged `skip` on 1 Aug and 8 Aug and nothing noticed.

**Do this instead:** SAB writes to a directory and stops. Optionally have the hook do one cheap thing —
`mv` the folder into the right inbox — and exit. Thin hook, thick worker.

### Anti-Pattern 4: `move` on a First Pass

**What people do:** leave `import.move: yes` (current `soulbeet` config) and run the backlog.

**Why it's wrong:** the source is consumed as it goes, across a dataset boundary so not atomically. A
wrong path-format or a bad match is then unrecoverable — there is no source left to re-import.

**Do this instead:** `copy` until the output is trusted, plus a ZFS snapshot fence per batch. Switch to
`move` later, if ever.

### Anti-Pattern 5: Running a Consistency-Enforcing Sync Over a Foreign Tree

**What people do:** point a stateless organiser's bulk-sync at an existing library that a different tool
built.

**Why it's wrong:** wrtag's own docs warn that `sync` is non-interactive and "can be destructive… Only
use `sync` on a library whose contents have been populated by `copy` or `move`." The 34 GB library was
built by beets. It also recurses every leaf directory, so unmatched folders (all of the DJ content)
get churned on every run.

**Do this instead:** whichever tagger wins, the existing library either stays out of its bulk-sync
scope or is deliberately re-imported once, as a decided action with a snapshot behind it. PROJECT.md
currently marks re-importing the 34 GB library out of scope — so bulk-sync must be scoped away from it.

---

## Constraint Feeding the Tagger Spike

The tagger choice is deferred to a spike phase, correctly. But the architecture imposes one hard
requirement that should shape it:

> **The single writer must be able to own the whole tree, including content that will never match
> MusicBrainz.**

wrtag is MusicBrainz-only by design, with no fallback provider, and its `sync` churns unmatched
folders. It cannot own bucket C. If wrtag takes the mainstream content and something else takes the DJ
content, that is two writers — the original bug, wearing new names.

beets can own both (`import -A` / a `bootleg` inbox, plus `fromfilename` and `edit`). This does not
settle the spike — wrtag's stateless, filesystem-as-truth model is genuinely attractive and is
*immune* to the divergent-database problem by construction — but the spike must answer **"what happens
to Mastermix?"** before it answers anything else. If the answer is "it lives outside the tool", the
tool has failed the requirement that matters most here.

*(Confidence: HIGH on wrtag being MusicBrainz-only and on the `sync` warning — both from official docs.
MEDIUM on beets-flask specifics, verified from its published docs but not run here.)*

---

## Build Order

```
 ┌──────────────────────────────────────────────────────────────┐
 │ 0. Tagger spike — decide on evidence                          │
 │    gate: "what happens to Mastermix?" answered                │
 └───────────────────────────┬──────────────────────────────────┘
                             ▼
 ┌──────────────────────────────────────────────────────────────┐   ┌────────────────────────────┐
 │ 1. Collapse to one writer                                     │   │ 1b. NFS export (infra/,     │
 │    · remove wrtag container (LIVE rw on the library today)    │   │     terraform apply)        │
 │    · remove soulbeet defn + Renovate pin                      │   │ 2b. HA network storage      │
 │    · strip beets block from audio.bash                        │   │     (type=Media, NFS)       │
 │    · Jellyfin :ro bind mount                                  │   │ 3b. MA filesystem provider  │
 │    gate: exactly one rw mount of media/Music                  │   │ gate: MA sees the 34 GB     │
 └───────────────────────────┬──────────────────────────────────┘   │       library TODAY         │
                             ▼                                       └─────────────┬──────────────┘
 ┌──────────────────────────────────────────────────────────────┐                  │
 │ 2. Jellyfin stops writing + tagger starts supplying art       │                  │
 │    · SaveLocalMetadata off, NFO savers off                    │                  │
 │    · fetchart configured, folder-level image                  │                  │
 └───────────────────────────┬──────────────────────────────────┘                  │
                             ▼                                                      │
 ┌──────────────────────────────────────────────────────────────┐                  │
 │ 3. Inbox structure + bucket D triage                          │                  │
 │    · create _inbox/{01..04,99,_done}                          │                  │
 │    · quarantine _FAILED_/_UNPACK_/.rar/non-music              │                  │
 │    · split the Now! 1-115 mega-folder per volume              │                  │
 └───────────────────────────┬──────────────────────────────────┘                  │
                             ▼                                                      │
 ┌──────────────────────────────────────────────────────────────┐                  │
 │ 4. Tagger config: copy-not-move, incremental, path formats    │                  │
 │    (incl. DJ-Mixes/), preferred.countries, fromfilename, edit │                  │
 │    gate: DRY RUN output matches the intended tree             │                  │
 └───────────────────────────┬──────────────────────────────────┘                  │
                             ▼                                                      │
 ┌──────────────────────────────────────────────────────────────┐                  │
 │ 5. Snapshot fence + pilot: ~5 bucket-A releases               │◀─────────────────┘
 │    gate: visible in Jellyfin AND in Music Assistant           │
 └───────────────────────────┬──────────────────────────────────┘
                             ▼
 ┌──────────────────────────────────────────────────────────────┐
 │ 6. Bucket A in batches (snapshot per batch)                   │
 └───────────────────────────┬──────────────────────────────────┘
                             ▼
 ┌──────────────────────────────────────────────────────────────┐
 │ 7. Bucket B (review inbox) · 8. dedupe dj-mixes↔unsorted      │
 │ 9. Bucket C (bootleg inbox) · 10. DJ scans + external sourcing│
 └──────────────────────────────────────────────────────────────┘
```

### Explicit dependencies

| Step | Depends on | Why |
|------|-----------|-----|
| 1 | 0 | Cannot retire taggers before knowing which one survives |
| 2 | 1 | Turning off Jellyfin's savers without the tagger supplying art removes all artwork |
| 1b | *nothing* | The library dataset already exists — start this early, in parallel |
| 3b | 1b, 2b | MA cannot see a share that is not mounted |
| 4 | 1 | Config belongs to the surviving tagger |
| 5 | 3, 4, 3b | The gate requires both consumers, so the MA path must be live first |
| 6 | 5 | Never scale an unproven pipeline |
| 8 | 3 | The 85 shared folder names must be resolved before either side is imported, or the library gets both |

### Preconditions before any bulk import starts

- [ ] Exactly **one** process has a read-write path to `/mnt/tank/media/Music` — verified with
      `docker ps` + inspecting mounts, not by reading compose files. (`docker ps` alone has already
      hidden a `created`-state container in this estate for six weeks.)
- [ ] All retired tagger definitions removed from compose **and** their Renovate rules released, so
      nothing resurrects them.
- [ ] `import.move` is `no`, `import.copy` is `yes`.
- [ ] `incremental`, `incremental_skip_later`, `resume` and `log` set.
- [ ] A ZFS snapshot of `tank/media/Music` and a copy of `library.db` exist, taken together.
- [ ] Dry-run output for a sample of each bucket inspected and matches the intended tree.
- [ ] Bucket D quarantined out of every inbox — no `_FAILED_`, `_UNPACK_`, loose `.rar`, no BluRay rips.
- [ ] No mega-folder in any inbox; every inbox entry is one release.
- [ ] The `dj-mixes` ↔ `unsorted` duplicate question decided **before** either side is queued.
- [ ] Jellyfin's metadata savers off and the tagger supplying folder art.
- [ ] NFS export live, HA mount present, MA syncing the *existing* library.
- [ ] Free space on `tank` ≥ 2× the batch size (copy semantics + snapshot retention).

---

## Scale Considerations

Framed by library size, not users — there are two consumers and they are not the constraint.

| Library size | Adjustments |
|---|---|
| ~1.2k files (today) | Everything above is fine. Full re-scans are cheap in both consumers |
| ~9k files (backlog imported) | Batch imports; keep per-track embedded art off — MA's docs flag per-track embedding as costly for scan time and disk. Prune snapshots after each accepted batch |
| >50k files | MA library sync becomes the slow step; prefer NFS/SMB over WebDAV (HTTP request per file operation). Consider staggering Jellyfin and MA scan schedules |

**What breaks first:** not throughput — **attention**. The `preview` inbox is the bottleneck by
design, and an unattended `preview` queue is exactly how this pipeline died three times. Keep that
queue visible (dashboard tile, or a notification on inbox depth) and keep batches small enough that a
batch finishes in one sitting.

---

## To Verify on the Host

These shape the design but were not confirmable from the repo:

1. `zfs list -o name,used,avail tank/media/Music tank/downloads` — confirm they are distinct datasets
   (inferred from the separate `mount_point` blocks) and check free space.
2. OpenZFS version and `zfs_bclone_enabled` — only relevant if a same-dataset reflink strategy is ever
   wanted; irrelevant for the cross-dataset library copy.
3. Actual ownership of `/mnt/tank/media/Music` — `568:545` (per `beets.md`) vs `568:568` (per
   `CLAUDE.md`). This sets `anonuid`/`anongid` on the export.
4. Whether `wrtag` currently holds files or has written anything under `Compilations/` — its
   `WRTAG_PATH_FORMAT` targets `/music/library/Compilations/…` and the container is `unless-stopped`.
5. Lidarr's configured root folder — whether it already points at `media/Music`.
6. Jellyfin library `options.xml` — confirm the exact saver settings to disable.
7. Whether `nfs-kernel-server` is already running on the Proxmox host for anything else.

---

## Sources

**Official documentation (HIGH confidence)**
- [wrtag README](https://github.com/sentriz/wrtag) — copy/move/reflink, `sync` semantics and its destructive warning, wrtagweb HTTP API (`POST /op/<copy|move|reflink>`), `WRTAG_PATH_FORMAT`, `WRTAG_ADDON`, MusicBrainz-only design, stateless/idempotent model
- [beets configuration reference](https://beets.readthedocs.io/en/stable/reference/config.html) — `incremental`, `incremental_skip_later`, `resume`, `copy`/`move`/`link`/`hardlink`/`reflink`, `timid`, `quiet_fallback`, `log`, `duplicate_action`
- [Music Assistant — File System source](https://www.music-assistant.io/music-providers/filesystem/) — local/SMB/NFS/WebDAV support, write access needed only for playlists, `.nfo` and `folder.jpg` consumption, embedded-art performance note, tags-over-paths priority
- [Music Assistant — Jellyfin source](https://www.music-assistant.io/music-providers/jellyfin/) — no dedicated maintainer, best-effort, suggests sharing music with MA directly
- [Home Assistant OS common tasks — network storage](https://www.home-assistant.io/common-tasks/os/) — Settings → System → Storage, usage type Media → `/media/<name>`, NFS and CIFS 2.1+
- [Jellyfin — Excluding files and directories](https://jellyfin.org/docs/general/server/media/excluding-directory/) — `.ignore` semantics
- [Servarr wiki — Lidarr and beets integration](https://wiki.servarr.com/lidarr/beets-integration) — `move: no, copy: no, write: yes`, Lidarr *Write Tags = Never*, `beet update` after Lidarr renames

**Project documentation (MEDIUM-HIGH)**
- [beets-flask configuration](https://beets-flask.readthedocs.io/latest/configuration.html) and [inboxes](https://beets-flask.readthedocs.io/v1.0.0/inboxes.html) — `gui.inbox.folders`, `autotag: no|preview|auto|bootleg`, `auto_threshold`, folders-not-files requirement
- [beets-flask README](https://github.com/pSpitzner/beets-flask) — single `library.db` at `/config/beets/library.db`, container layout, web terminal, requirement that music paths match inside and outside the container
- [beets-flask changelog](https://github.com/pSpitzner/beets-flask/blob/main/CHANGELOG.md) — 1.0 inbox types reduced to preview/auto/bootleg; interactive imports removed

**Community / issue trackers (MEDIUM — corroborated across sources)**
- [jellyfin#11815](https://github.com/jellyfin/jellyfin/issues/11815), [#5642](https://github.com/jellyfin/jellyfin/issues/5642) — music `folder.jpg` written to `/config/metadata` rather than the media folder; long-standing
- [jellyfin#14502](https://github.com/jellyfin/jellyfin/issues/14502) — empty `.ignore` folders still added to the library on 10.11.x
- [openzfs#15345](https://github.com/openzfs/zfs/issues/15345), [openzfs#18005](https://github.com/openzfs/zfs/issues/18005) — `cp --reflink=always` fails `EXDEV` across datasets in one pool; still present in 2.3.4
- [SABnzbd forums — post-processing is serial](https://forums.sabnzbd.org/viewtopic.php?t=24186), [queue held up](https://forums.sabnzbd.org/viewtopic.php?p=65123) — no built-in script timeout; detaching loses the return code
- [Proxmox forum — NFS server in unprivileged LXC](https://forum.proxmox.com/threads/nfs-server-in-unprivileged-lxc-possible.164864/) — NFS feature is privileged-only; nfsd additionally needs AppArmor unconfined

**Repository evidence (HIGH — read directly)**
- `infra/lxc-selfhost.tf` — `unprivileged = true` (L107); separate `mount_point` blocks for `/mnt/tank/downloads` and `/mnt/tank/media/Music` (L262, L282)
- `stacks/selfhosted/music/wrtag.yaml` — `restart: unless-stopped`, `/mnt/tank/media/Music:/music/library` rw, `WRTAG_PATH_FORMAT` targeting `Compilations/`
- `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` — `move: yes`, no `match.preferred.countries`, no `fromfilename`/`edit`
- `stacks/selfhosted/arrs/lidarr.yaml` — `/mnt/tank/media:rw`
- `stacks/selfhosted/media/jellyfin.yaml` — `/mnt/tank/media` mounted **rw** (no `:ro`)
- `stacks/selfhosted/arrs/beets.md`, `.planning/PROJECT.md` — library census, bucket triage, rsync/ACL and ZFS gotchas
- `NETWORK.md` — Home Assistant NUC at 172.16.1.31; Proxmox host at 172.16.1.158; LXC 100 at 172.16.1.159

---
*Architecture research for: self-hosted music tagging pipeline with multi-consumer library*
*Researched: 2026-08-17*
