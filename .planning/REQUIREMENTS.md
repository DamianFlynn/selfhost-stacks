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
- [x] **CONS-03**: Music Assistant's view survives a NUC reboot
- [ ] **CONS-04**: A file is only "imported" when verified with `ffprobe` *and* visible in both
      Jellyfin and Music Assistant

### Transcode retention — the cache cannot fill the Docker host's root filesystem (phase insertion 02.1)

Inserted 2026-09-02 for **Phase 02.1**, after a 19 GB Jellyfin transcode cache in an *anonymous*
Docker volume took LXC 100's root filesystem to zero mid-Phase-3. These nine are a **phase
insertion**, not a change to the v1 milestone scope — see the revision note under § Traceability
for why the v1 denominator of 39 is deliberately preserved.

- [x] **TRAN-01**: Every Jellyfin cache write, transcodes included, lands on `/mnt/fast`, not on
      LXC 100's root filesystem — by declared bind mount, not by an anonymous Docker volume
      *(discharges D-01, D-02, D-03, D-08, D-09, D-10)*
- [x] **TRAN-02**: Jellyfin holds **zero** `Type: volume` mounts, and the anonymous volume
      `d98b2ff9…` no longer exists. The invariant is asserted, not the id — a *new* anonymous volume
      must fail this too *(discharges D-08, D-10, D-18)*
- [x] **TRAN-03**: Transcode growth is bounded by a ZFS property that survives a container recreate
      and a UI edit, and the bound is proven to **fire** rather than proven to be set
      *(discharges D-12, D-13, D-15)*
- [x] **TRAN-04**: Jellyfin's own retention levers are on, their values are chosen rather than
      defaulted, and each is proven **firing** from Jellyfin's own logs — not read back from the API
      *(discharges D-14, D-15, D-21)*
- [ ] **TRAN-05**: A standing, fail-closed check covers `/` headroom, the absent anonymous volume,
      the transcode quota and the three encoding values, runs standalone, and is folded into
      `quick-health-check.sh` *(discharges D-16, D-17, D-18, D-19, D-20, D-22)*
- [ ] **TRAN-06**: A `jellyfin/jellyfin` Renovate rule makes a minor release manual-review while
      preserving patch automerge, and `scripts/check-renovate.sh` can actually validate the config it
      is pointed at *(discharges D-23, D-24, D-25)*
- [x] **TRAN-07**: `fast/transcode` and its properties are declared in `infra/` Terraform, and the
      apply that lands them is provably scoped to that one resource with **zero destroys**
      *(discharges D-05, D-06, D-07)*
- [ ] **TRAN-08**: The unreferenced Docker images are reclaimed through
      `scripts/spike03-image-headroom.sh`'s existing two-process approval gate, with
      `docker image prune -a` / `docker system prune` prohibited by name and the prohibition asserted
      *(discharges D-28)*
- [x] **TRAN-09**: The estate's existing amdgpu recovery script cannot silently revert this phase's
      retention controls — `scripts/disable-jellyfin-hwaccel.sh enable` restores the **whole**
      `encoding.xml` from a `.bak` predating this phase, so it is a one-command silent revert of
      everything 02.1 installs *(discharges D-29, D-30. **Origin note:** unlike TRAN-01…08 this one
      did not come from a CONTEXT decision — it is a research finding, `02.1-RESEARCH.md` § Pitfall 1,
      recorded there as Assumptions-Log entry A1 and explicitly needing operator confirmation before
      becoming scope. The operator ruled it **in scope on 2026-09-02 as D-29**, and D-30 was ruled
      alongside it.)*

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
| CONS-01 | Phase 2 | **COMPLETE (02-05).** All five parts of criterion 1: 1a export correct, 1b re-apply exit 0, 1c served from the host not LXC 100 (02-03); **1d visible from the NUC — `nc` 2049 exit 0 and the mount succeeded (`showmount` is absent there), 1e NFSv4 negotiated — `/proc/self/mountinfo` fstype `nfs4`, `vers=4.2` (`findmnt` is absent there) (02-05)**. **Criterion 2 proven at the EXPORT layer**, not the client: `touch` refused `EROFS` despite an explicit `mount -o rw`, on NFSv3 and NFSv4.2 alike. **M1 IS NOW PROVEN (02-08), superseding 02-03 and 02-05.** A discriminating client-mount pair from the NUC, same command minutes apart: dataset mounted → exit 0 / 14 entries; dataset unmounted → exit 255 / `No such file or directory` / 0 entries. The `mountpoint` option genuinely makes `rpc.mountd` refuse. ⚠ The earlier "unproven" readings were an **instrument error, not a defect**: `exportfs -v` keeps printing the export line while the dataset is unmounted, so the export *table* is non-discriminating while the *served mount* is refused. Never assert export health from `exportfs -v` alone. M2 (`After=zfs-mount.service`) remains the boot-race guard; M1 is a proven second layer beneath it, and 02-03's `threat_flag: control-not-enforced` on `infra/nfs-music-export.tf` is retired |
| CONS-02 | Phase 2 | **COMPLETE (02-06).** MA provider `filesystem_local--XJaJWNUS` at `/media/music`, created headlessly (`config/providers/setup` → `config/flows/submit`), `type=music`, `enabled`, `status: loaded`, `last_error: null`. `content_type` read back as `music` (`read_only: true`) and `missing_album_artist_action` read back as `folder_name` against a `various_artists` default — D-28 and D-01 both proven by read-back, not by submission. Instance id pinned into `check-music-consumers.sh` (`e1c4f93`), so both library proof albums match with provider attribution confirmed server-side **and** client-side against `provider_mappings[]`. 20 albums attributed to the local provider. Caveat: MA 2.11 does not expose the provider's `path` via the API — it is proven functionally via `music/browse` and recorded only in `02-06-SUMMARY.md`. **CRITERION 3 CLOSED BY 02-07**: all three proof albums exact-matched on album name **and** `artists[0].name` inside one deliberate 177 s `music/sync`, the third served through the temporary export. **⚠ But `missing_album_artist_action: folder_name` is CONDITIONAL** — measured in 02-07, it fires only when a file's `album` TAG agrees with its album FOLDER name, and otherwise silently yields `Various Artists` while the API still reads back `folder_name`. "Shows albums under the correct album artist" is therefore true for this library's proof set and NOT guaranteed for arbitrary content; Phase 7 must check the precondition |
| CONS-03 | Phase 2 | **COMPLETE (02-08).** The reboot half — the only thing 02-07 was missing — was done twice on 2026-09-01. **Criterion 4a:** NUC rebooted with atlantis healthy, boot_id changed `b86dada0…`→`3a7906c0…`, **zero manual intervention**, mount `active`/`read_only`, 70 albums provider-filtered, both proof albums EXACT, `check-music-consumers.sh` exit 0, and M4a re-synced unprompted at 12:43:25Z. Recorded as **necessary but not sufficient** — atlantis was healthy so the race was never exercised. **Criterion 4b:** `nfs-server` stopped, NUC rebooted (boot_id `3a7906c0…`→`a2869d72…`), the failure reproduced in full — Supervisor's `mounting read-only fallback`, `/media/music` empty and `dr--r--r--`, MA's `Aborting sync … scan found no files but 1244 were previously indexed` — and **MA's view survived it: 70 albums before, 70 during, 70 after. No purge.** Then **unattended recovery in 432 s** with the NUC untouched, M4b re-syncing on its own at 13:12:06Z. **⚠ Two instrument corrections came out of it:** `mount \| grep emergency/music` can never match on this Supervisor version (it makes the media dir read-only in place, no `/emergency/` bind), and the default `ha supervisor logs` depth does not reach back to boot. **A real defect was found and fixed:** D-54a's alerting was structurally unable to fire on a boot into a failed mount; it now carries a `homeassistant start` trigger (the load-bearing one) and both new trigger paths are fired and trace-confirmed. D-54b remains blind at boot by integration-setup ordering — diagnosed, recorded open, not part of CONS-03's text |
| TRAN-01 | Phase 02.1 | Complete |
| TRAN-02 | Phase 02.1 | Complete |
| TRAN-03 | Phase 02.1 | Complete |
| TRAN-04 | Phase 02.1 | Complete |
| TRAN-05 | Phase 02.1 | Pending |
| TRAN-06 | Phase 02.1 | Pending |
| TRAN-07 | Phase 02.1 | Complete |
| TRAN-08 | Phase 02.1 | Pending |
| TRAN-09 | Phase 02.1 | **COMPLETE (02.1-07).** `do_enable` captures the five transcode-retention values from the live config BEFORE the whole-file `.bak` restore, re-asserts them into the restored file, and verifies them on BOTH sides of the container restart — naming any moved field with its before and after values and exiting non-zero. Discharged on a **firing** observation, not a read-back: `check` → `disable` → simulated phase write → `enable` was EXECUTED against a throwaway `encoding.xml` and a disposable container (exit 0, all five preserved, `HardwareAccelerationType` restored to `vaapi`). **The verification was then proven able to FAIL, twice** — the review's HIGH finding was that the reviewed control could not fail, because the verification lives inside `do_enable` which re-captures live values before restoring. (a) the standalone read-only `verify-retention` sub-action, taking its expectations from `$TRAN09_EXPECT`, exited 1 on a perturbed config naming the field with expected-vs-found, and 0 once restored; (b) `TRAN09_FAULT=1 … enable` exited 1 naming four of five fields with both values, while `ThrottleDelaySeconds` correctly PASSED at 180 either side — proving the comparison is genuinely per-field. The live `encoding.xml` sha256 and `.bak` inventory are identical either side and `check-jellyfin-transcode.sh` still exits 0. The D-30 amdgpu mitigation (`none` / `false`) is unchanged |
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
- Phase insertions (not part of the v1 denominator): TRAN-01…09 = 9
- Total tracked: 48

**Arithmetic, both ways:**

By category: SAFE 5 + WRIT 4 + CONS 4 + TAGR 6 + CONF 6 + INBX 3 + QUAL 4 + IMPT 3 + INGS 4 = **39**

By phase: 10 + 3 + 3 + 3 + 3 + 6 + 6 + 4 + 1 = **39**

Phase insertion 02.1: TRAN 9 — tracked separately, so both v1 totals above are unchanged and still
agree. Total tracked = 39 + 9 = **48**.

Both totals agree, and every requirement appears in exactly one phase row above.

> **Revision 2026-09-02 (phase insertion 02.1, NOT a milestone scope change):** TRAN-01…TRAN-09 were
> added for the inserted Phase 02.1 (Jellyfin transcode retention), taking the tracked total from 39
> to 48. **The v1 denominator is deliberately left at 39.** Phase 1-9 milestone progress is measured
> against it, and incrementing it would silently move the goalposts of a milestone that is already
> part-executed — every prior "N of 39" statement would become incomparable with the ones after it.
> The insertion is therefore subtotalled separately in the Coverage block, given its own arithmetic
> line, and marked *(inserted)* with a footnote in the By-phase table. Both v1 arithmetic lines above
> are byte-identical to their pre-insertion form and are still true. TRAN-09 differs from its eight
> siblings in origin: it was a **research finding** (`02.1-RESEARCH.md` § Pitfall 1, Assumptions Log
> A1), not a CONTEXT decision, and was ruled in scope by the operator on 2026-09-02 as D-29. No
> existing requirement was renumbered, reworded, re-mapped or changed phase.
>
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
| 02.1 — Jellyfin Transcode Retention *(inserted)* | TRAN-01…09 | 9 |
| 3 — Tagger Spike | TAGR-01, TAGR-02, TAGR-06 | 3 |
| 4 — Collapse to One Tagger | TAGR-03, TAGR-04, TAGR-05 | 3 |
| 5 — Inbox Structure and the Junk Gate | INBX-01, INBX-02, INBX-03 | 3 |
| 6 — Tagger Configuration and Dry Run | CONF-01…06 | 6 |
| 7 — Pilot — 12 Albums End to End | IMPT-01, IMPT-02, CONS-04, QUAL-02, QUAL-03, QUAL-04 | 6 |
| 8 — Close the Inflow | INGS-01…04 | 4 |
| 9 — Bucket A in Batches | IMPT-03 | 1 |

> **Footnote — the `02.1` row is an INSERTION and is EXCLUDED from the v1 total of 39.** The nine
> integer-phase rows still sum to 39 on their own, which is what the `By phase:` arithmetic line
> above states. Adding the 02.1 row's 9 gives the tracked total of 48. Do not read the table's rows
> as summing to the v1 figure without first removing this one.

v2 requirements (DUPE-*, NOWB-*, LIDR-01, DJCC-*) are deliberately unscheduled — see
ROADMAP.md § Beyond This Milestone.

---
*Requirements defined: 2026-08-17*
*Last updated: 2026-08-17 after roadmap revision (QUAL-01…04 and TAGR-06 mapped; v1 total 39)*
