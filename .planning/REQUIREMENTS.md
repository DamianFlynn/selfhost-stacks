# Requirements: Music Library Consolidation

**Defined:** 2026-08-17
**Core Value:** New music downloads land in the library correctly tagged, through exactly one
pipeline that someone owns.

## v1 Requirements

Requirements for the milestone as PROJECT.md scopes it: pipeline fixed, bucket A proven.

### Safety — protect what cannot be recreated

- [ ] **SAFE-01**: Destructive beets defaults are off in *every* beets config in the estate —
      `scrub.auto: no`, `lastgenre.auto: no`, `embedart.auto: no`
- [ ] **SAFE-02**: A recoverable snapshot exists before any import — ZFS snapshot of the Music
      dataset plus copies of every beets library database, taken together as one fence
- [ ] **SAFE-03**: The DJ tag evidence is captured to a file no tagger can overwrite — `ffprobe`
      JSON dump of all 794 `dj-mixes` files, including `TKEY` and `EnergyLevel`
- [ ] **SAFE-04**: The 54 DJ cover scans are archived outside any tagger-writable path
- [ ] **SAFE-05**: Jellyfin stops writing into the library — `SaveLocalMetadata` off for Music,
      scheduled scans paused, database backed up

### Writers — one process owns the tree

- [ ] **WRIT-01**: Exactly one process holds a read-write path to `/mnt/tank/media/Music`,
      verified by inspecting the mounts of *running* containers, not by reading compose files
- [ ] **WRIT-02**: wrtag is stopped and its library mount removed from the definition
- [ ] **WRIT-03**: Lidarr no longer renames or organises in the library — `renameTracks` off,
      root folder repointed off `/media/Music`
- [ ] **WRIT-04**: Library ownership is normalised to one decided `uid:gid` and recorded in the
      repo, replacing today's mix of `apps:nogroup` and `apps:apps`

### Consumers — two, not one

- [ ] **CONS-01**: An NFSv4 export serves the Music dataset read-only from the Proxmox host,
      defined in Terraform, restricted to the NUC
- [ ] **CONS-02**: Music Assistant reads the library and shows albums under the correct album
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
| Lidarr replacement | Lidarr stays as the grabber. This project is about what happens after files land |
| Music Assistant's Jellyfin provider | MA's own docs advise against it — no dedicated maintainer, "consider sharing your music directly with MA instead". The NFS mount is the supported route |
| AcoustID/chroma fingerprinting | Counterproductive here — beets #360 documents it degrading compilation matching, and bucket B is entirely compilations |
| Zero-touch automatic tagging | The pattern that killed all three prior attempts. Automation produces a decision; a human ratifies later; the decision persists |
| `_`-prefixed folders inside the library | MA silently ignores them, Jellyfin does not — the two consumers would diverge by design |

## Traceability

Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (pending roadmap) | — | Pending |

**Coverage:**
- v1 requirements: 33 total
- Mapped to phases: 0 (roadmap not yet created)
- Unmapped: 33 ⚠️

---
*Requirements defined: 2026-08-17*
*Last updated: 2026-08-17 after initial definition*
