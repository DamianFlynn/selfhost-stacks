# Requirements: Music Library Consolidation

**Defined:** 2026-08-17
**Core Value:** New music downloads land in the library correctly tagged, through exactly one
pipeline that someone owns.

## v1 Requirements

Requirements for the milestone as PROJECT.md scopes it: pipeline fixed, bucket A proven.

### Safety — protect what cannot be recreated

- [x] **SAFE-01**: Destructive beets defaults are off in *every* beets config in the estate —
      `scrub.auto: no`, `lastgenre.auto: no`, `embedart.auto: no`
- [x] **SAFE-02**: A recoverable snapshot exists before any import — ZFS snapshot of the Music
      dataset plus copies of every beets library database, taken together as one fence
- [x] **SAFE-03**: The DJ tag evidence is captured to a file no tagger can overwrite — `ffprobe`
      JSON dump of all 764 `dj-mixes` audio files, including `TKEY` and `EnergyLevel`
- [x] **SAFE-04**: The 54 DJ cover scans are archived outside any tagger-writable path
- [x] **SAFE-05**: Jellyfin stops writing into the library — `SaveLocalMetadata` off for Music,
      scheduled scans paused, database backed up
      *(01-06. Three switches, not two: `SaveLocalMetadata`, `EnableRealtimeMonitor` and
      `SaveLyricsWithMedia` — the last gated independently and wrote 944 of the 1,123 baseline
      sidecars. Scoped to Music only; the global 12-hourly scan task is deliberately left running
      per D-16, so "scheduled scans paused" is met as real-time monitoring off rather than the
      global task disabled. Databases backed up with `sqlite3 .backup`, integrity-checked, in the
      manifest. Proven by a 374-minute quiet watch: 0 sidecars added, removed or content-changed,
      0 library stat deltas, and `zfs diff` clean apart from one ctime bump we caused ourselves.*
      **Known limitation, measured not assumed:** `SaveLocalMetadata=false` gates the automatic
      scan-time save path only. An explicit `MetadataRefreshMode=FullRefresh` — what the Jellyfin
      UI's "Refresh metadata" button issues — still writes `.nfo`. SAFE-05 is true for "Jellyfin
      writes nothing **unprompted**" and false for "Jellyfin cannot write". The only structural
      control would be an `:ro` mount, which D-21 deliberately rejected.)

### Writers — one process owns the tree

- [x] **WRIT-01**: Exactly one process holds a read-write path to `/mnt/tank/media/Music`,
      verified by inspecting the mounts of *running* containers, not by reading compose files
      *(Substantively true as of 01-06: the running-container audit reports `tagger-class writers:
      0`, `unclassified writers: 0`, `consumer-class writers: 1 (jellyfin, documented exception
      D-21)`, and `declared rw reaching Music: 0`. It took **01-05 and 01-06 together** — 01-05
      narrowed or deleted nine mounts, 01-06 flipped the tenth (lidarr) to `:ro`. Left unchecked
      deliberately: 01-09 owns phase closure and closes it with an assert-mode re-run.)*
- [x] **WRIT-02**: wrtag is stopped and its library mount removed from the definition
- [x] **WRIT-03**: Lidarr no longer renames or organises in the library — `renameTracks` off,
      root folder repointed off `/media/Music`
      *(01-06, all read back from Lidarr's API after a container recreate per D-26, never from the
      UI. Root folder now `/downloads/lidarr-import` on the downloads dataset; `renameTracks`
      false; all three metadata consumers off (already were); plus two write paths the requirement
      does not name — `deleteEmptyFolders` (a **delete** path) and `embedCoverArt` — closed under
      D-24's intent. The media mount is `:ro` and proven so by an in-container write attempt.*
      **Load-bearing nuance:** deleting the old root folder did **not** repoint the 22 existing
      artists — an *arr stores an absolute path per artist, so all 22 still target
      `/media/Music/<Artist>`. The `:ro` mount (D-25), not the root-folder move (D-23), is what
      actually closes the library.)
- [x] **WRIT-04**: Library ownership is normalised to one decided `uid:gid` and recorded in the
      repo, replacing today's mix of `apps:nogroup` and `apps:apps`
      (**Normalisation half DONE in 01-08** — all 2,674 entries incl. the library root are
      `568:568` on disk, verified from the Proxmox host and by `zfs diff` against `@pre-chown`.
      Two corrections this surfaced: the mix was never `apps:nogroup`/`apps:apps` — that was the
      *container's* view; on disk it was `0:545`, `3000:545`, `568:545`, `100000:100000`,
      `100911:100911` and `568:568`. And `chown` cannot be run from LXC 100 at all, only from the
      pool host. The **mode** half of the original decision (D-12, `0755`/`0644`) is **scoped out
      and unachievable** — `aclmode=restricted` makes `chmod` EPERM pool-wide, so the tree stays
      0777. Remaining for **01-09**: record the decided value in the repo and correct `beets.md`'s
      `chown -R 568:545` (D-14).)

### Consumers — two, not one

- [x] **CONS-01**: An NFSv4 export serves the Music dataset read-only from the Proxmox host,
      defined in Terraform, restricted to the NUC
- [x] **CONS-02**: Music Assistant reads the library and shows albums under the correct album
      artist
- [ ] **CONS-03**: Music Assistant's view survives a NUC reboot
- [ ] **CONS-04**: A file is only "imported" when verified with `ffprobe` *and* visible in both
      Jellyfin and Music Assistant

### Tagger — decided on evidence, then singular

- [ ] **TAGR-01**: The tagger decision is recorded with numbers — Discogs coverage measured on
      normalised DJ folders, import timing extrapolated against the API rate ceiling
- [ ] **TAGR-02**: The surviving tagger can own the whole tree, including content that will never
      match MusicBrainz
- [ ] **TAGR-03**: The losing tagger definitions are deleted and their Renovate rules released,
      including the wrtag `<0.30.0` pin that enforces the broken state
- [ ] **TAGR-04**: soulbeet is removed (issue #306) and the beets block stripped from `audio.bash`
- [ ] **TAGR-05**: Every remaining beets config declares the `musicbrainz` plugin — the defect that
      silently disabled autotagging since beets 2.4.0
- [ ] **TAGR-06**: Operator ergonomics is a weighted, recorded factor in the tagger decision, not
      an afterthought — including a reviewable-queue front end (e.g. beets-flask) rather than a
      raw terminal prompt. A tool that is painful to use is a tool that stops being used, and that
      is the documented cause of three prior abandonments

### Configuration — the traps closed

- [ ] **CONF-01**: Imports copy rather than move, so a bad run is reversible
- [ ] **CONF-02**: `incremental: yes` with `incremental_skip_later: yes`, so a hard album is
      re-offered rather than permanently marked done
- [ ] **CONF-03**: Path formats put `ALBUMARTIST` at the top level exactly, case included —
      `Various Artists/`, never `Compilations/`
- [ ] **CONF-04**: `;` is the multi-artist delimiter, the one both consumers parse
- [ ] **CONF-05**: Match disambiguation configured — `preferred.countries` using `GB` not `UK`,
      `preferred.original_year`, and `musicbrainz.extra_tags`
- [ ] **CONF-06**: `beet import --pretend` on a sample of each bucket produces the intended tree

### Inbox — a queue with a junk gate

- [ ] **INBX-01**: A staging inbox exists under `tank/downloads` with per-policy folders, never
      under `media/`
- [ ] **INBX-02**: Bucket D is quarantined — `_FAILED_`, `_UNPACK_`, stray `.rar`, and the
      misfiled Harry Potter BluRay rip
- [ ] **INBX-03**: The 45 GB `Now! 1-115` folder is split per volume before it can become one
      un-abortable import

### Quality — better, not worse

The library is not empty and much of it is already tagged. An import that "succeeds" while
dropping fields the file arrived with is a regression, and at scale it is unrecoverable.

- [x] **QUAL-01**: A before-state tag snapshot exists for every file staged for import — not just
      the DJ content — so any change is comparable field by field
- [ ] **QUAL-02**: No import causes net metadata loss. A field-level before/after diff over the
      pilot shows what was gained and what was dropped; any dropped field is either deliberate and
      recorded, or the import is rejected
- [ ] **QUAL-03**: The pilot sample deliberately includes the historically painful cases — at
      least one various-artist compilation and one multi-disc release — not only clean
      single-artist albums, so the proven flow is one that has faced the hard shape
- [ ] **QUAL-04**: A rejected or regressed import can be undone and re-run without hand-repair,
      demonstrated at least once

### Import — a countable win, then scale

- [ ] **IMPT-01**: ~12 bucket-A albums are imported end to end inside a snapshot fence and pass
      CONS-04
- [ ] **IMPT-02**: A post-import detection sweep runs — `.1`-suffix collision search, empty
      `mb_albumid`, track-count vs `tracktotal`
- [ ] **IMPT-03**: The mainstream bucket-A backlog is imported in batches small enough to finish
      in one sitting, with a snapshot and sweep per batch

### Ingest — close the inflow

- [ ] **INGS-01**: SABnzbd's hook does one cheap thing and exits — moves the folder to an inbox,
      no tagging in the post-processing path
- [ ] **INGS-02**: The ingest worker keeps persistent state across runs
- [ ] **INGS-03**: Low-confidence content is routed to review, never silently skipped
- [ ] **INGS-04**: A real new download completes end to end with no `skip`

## v2 Requirements

Deferred. Real work, deliberately outside this milestone so it cannot consume it.

### Duplicates

- **DUPE-01**: The 85 folder names shared between `dj-mixes` and `unsorted` are compared and an
  authoritative side chosen per pair
- **DUPE-02**: Resolution completes before any import of `unsorted`, or the library gets both

### Bucket B — the *Now!* series

- **NOWB-01**: UK vs US releases disambiguated per volume with a manual confirmation budget
- **NOWB-02**: The 115-volume set imported volume by volume

### Acquisition front end

- **LIDR-01**: Evaluate replacing Lidarr as the grabber. Noted as wanted 2026-08-17. Deliberately
  outside this milestone: Phase 1 already stops Lidarr writing to the library (WRIT-03), which
  removes the harm it does here. Swapping the acquisition tool is a separate project with its own
  migration, and folding it in is exactly how this milestone would stop finishing.

### Bucket C — DJ content

- **DJCC-01**: DJ field mapping normalised per release convention, BPM separated from titles,
  `TKEY`/`EnergyLevel` preserved
- **DJCC-02**: Discogs used as the metadata source where a candidate exists
- **DJCC-03**: Tracklists extracted from the 27 folders holding cover scans
- **DJCC-04**: Artwork and tracklists sourced externally for releases with neither
- **DJCC-05**: DJ content lives in a separate library *root*, not a pseudo-artist folder

## Out of Scope

| Feature | Reason |
|---------|--------|
| Clearing the whole 97 GB backlog | The failure mode is abandonment, not slowness. Pipeline + bucket A proven is the milestone; the rest is routine work at your own pace |
| Re-importing the existing 34 GB library | Already correct and Jellyfin reads it. Reconciling separate beets databases means re-importing one side — a known hazard, not a task |
| Lidarr replacement | Out of *this milestone*, not off the table — see LIDR-01 (v2). Lidarr stays as the grabber for now; WRIT-03 stops it writing to the library, which removes the harm it does here. This project is about what happens after files land |
| Music Assistant's Jellyfin provider | MA's own docs advise against it — no dedicated maintainer, "consider sharing your music directly with MA instead". The NFS mount is the supported route |
| AcoustID/chroma fingerprinting | Counterproductive here — beets #360 documents it degrading compilation matching, and bucket B is entirely compilations |
| Zero-touch automatic tagging | The pattern that killed all three prior attempts. Automation produces a decision; a human ratifies later; the decision persists |
| `_`-prefixed folders inside the library | MA silently ignores them, Jellyfin does not — the two consumers would diverge by design |

## Traceability

Populated during roadmap creation (2026-08-17). Every v1 requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-01 | Phase 1 | Complete (01-07) |
| SAFE-02 | Phase 1 | Complete |
| SAFE-03 | Phase 1 | Complete |
| SAFE-04 | Phase 1 | Complete |
| SAFE-05 | Phase 1 | Complete |
| WRIT-01 | Phase 1 | Complete (01-05 + 01-06; asserted 01-09, audit exit 0) |
| WRIT-02 | Phase 1 | Complete |
| WRIT-03 | Phase 1 | Complete |
| WRIT-04 | Phase 1 | Complete (01-08 normalisation, 01-09 repo record; mode half scoped out) |
| QUAL-01 | Phase 1 | Complete |
| CONS-01 | Phase 2 | **COMPLETE (02-05).** All five parts of criterion 1: 1a export correct, 1b re-apply exit 0, 1c served from the host not LXC 100 (02-03); **1d visible from the NUC — `nc` 2049 exit 0 and the mount succeeded (`showmount` is absent there), 1e NFSv4 negotiated — `/proc/self/mountinfo` fstype `nfs4`, `vers=4.2` (`findmnt` is absent there) (02-05)**. **Criterion 2 proven at the EXPORT layer**, not the client: `touch` refused `EROFS` despite an explicit `mount -o rw`, on NFSv3 and NFSv4.2 alike. Residual: M1 (`mountpoint`) remains configured-but-unproven — M2 (`After=zfs-mount.service`) is the proven boot-race guard |
| CONS-02 | Phase 2 | **COMPLETE (02-06).** MA provider `filesystem_local--XJaJWNUS` at `/media/music`, created headlessly (`config/providers/setup` → `config/flows/submit`), `type=music`, `enabled`, `status: loaded`, `last_error: null`. `content_type` read back as `music` (`read_only: true`) and `missing_album_artist_action` read back as `folder_name` against a `various_artists` default — D-28 and D-01 both proven by read-back, not by submission. Instance id pinned into `check-music-consumers.sh` (`e1c4f93`), so both library proof albums match with provider attribution confirmed server-side **and** client-side against `provider_mappings[]`. 20 albums attributed to the local provider. Caveat: MA 2.11 does not expose the provider's `path` via the API — it is proven functionally via `music/browse` and recorded only in `02-06-SUMMARY.md` |
| CONS-03 | Phase 2 | Pending |
| CONS-04 | Phase 7 | Pending |
| TAGR-01 | Phase 3 | Pending |
| TAGR-02 | Phase 3 | Pending |
| TAGR-06 | Phase 3 | Pending |
| TAGR-03 | Phase 4 | Pending |
| TAGR-04 | Phase 4 | Pending |
| TAGR-05 | Phase 4 | Pending |
| INBX-01 | Phase 5 | Pending |
| INBX-02 | Phase 5 | Pending |
| INBX-03 | Phase 5 | Pending |
| CONF-01 | Phase 6 | Pending |
| CONF-02 | Phase 6 | Pending |
| CONF-03 | Phase 6 | Pending |
| CONF-04 | Phase 6 | Pending |
| CONF-05 | Phase 6 | Pending |
| CONF-06 | Phase 6 | Pending |
| IMPT-01 | Phase 7 | Pending |
| IMPT-02 | Phase 7 | Pending |
| QUAL-02 | Phase 7 | Pending |
| QUAL-03 | Phase 7 | Pending |
| QUAL-04 | Phase 7 | Pending |
| INGS-01 | Phase 8 | Pending |
| INGS-02 | Phase 8 | Pending |
| INGS-03 | Phase 8 | Pending |
| INGS-04 | Phase 8 | Pending |
| IMPT-03 | Phase 9 | Pending |

**Coverage:**
- v1 requirements: 39 total
- Mapped to phases: 39 ✓
- Unmapped: 0

**Arithmetic, both ways:**

By category: SAFE 5 + WRIT 4 + CONS 4 + TAGR 6 + CONF 6 + INBX 3 + QUAL 4 + IMPT 3 + INGS 4 = **39**

By phase: 10 + 3 + 3 + 3 + 3 + 6 + 6 + 4 + 1 = **39**

Both totals agree, and every requirement appears in exactly one phase row above.

> **Revision 2026-08-17:** v1 grew from 34 to 39. Five requirements were added on user feedback —
> the QUAL category (QUAL-01…04, closing the "an import can succeed while making the library worse"
> hole) and TAGR-06 (operator ergonomics as a weighted factor in the tagger decision). No existing
> requirement changed phase.
>
> **Earlier count correction:** this document once stated 33 v1 requirements when the true count was
> 34. No requirement was missing — the header total was off by one. That is now superseded by the
> figure of 39 above.

**By phase:**

| Phase | Requirements | Count |
|-------|--------------|-------|
| 1 — Safety Harness and Freeze the Writers | SAFE-01…05, WRIT-01…04, QUAL-01 | 10 |
| 2 — NFS Export and Music Assistant Reachability | CONS-01, CONS-02, CONS-03 | 3 |
| 3 — Tagger Spike | TAGR-01, TAGR-02, TAGR-06 | 3 |
| 4 — Collapse to One Tagger | TAGR-03, TAGR-04, TAGR-05 | 3 |
| 5 — Inbox Structure and the Junk Gate | INBX-01, INBX-02, INBX-03 | 3 |
| 6 — Tagger Configuration and Dry Run | CONF-01…06 | 6 |
| 7 — Pilot — 12 Albums End to End | IMPT-01, IMPT-02, CONS-04, QUAL-02, QUAL-03, QUAL-04 | 6 |
| 8 — Close the Inflow | INGS-01…04 | 4 |
| 9 — Bucket A in Batches | IMPT-03 | 1 |

v2 requirements (DUPE-*, NOWB-*, LIDR-01, DJCC-*) are deliberately unscheduled — see
ROADMAP.md § Beyond This Milestone.

---
*Requirements defined: 2026-08-17*
*Last updated: 2026-08-17 after roadmap revision (QUAL-01…04 and TAGR-06 mapped; v1 total 39)*
