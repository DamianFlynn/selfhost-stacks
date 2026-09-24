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
- [x] **TRAN-05**: A standing, fail-closed check covers `/` headroom, the absent anonymous volume,
      the transcode quota and the five encoding values — asserted as **not drifted** from named
      expectations, which is explicitly not a claim they fire (CONS-04) — runs standalone, and is
      folded into `quick-health-check.sh` *(discharges D-16, D-17, D-18, D-19, D-20, D-21, D-22)*
- [x] **TRAN-06**: A `jellyfin/jellyfin` Renovate rule makes a minor release manual-review while
      preserving patch automerge, and `scripts/check-renovate.sh` can actually validate the config it
      is pointed at *(discharges D-23, D-24, D-25)*
- [x] **TRAN-07**: `fast/transcode` and its properties are declared in `infra/` Terraform, and the
      apply that lands them is provably scoped to that one resource with **zero destroys**
      *(discharges D-05, D-06, D-07)*
- [x] **TRAN-08**: The unreferenced Docker images are reclaimed through
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

- [x] **TAGR-01**: The tagger decision is recorded with numbers — Discogs coverage measured on
      normalised DJ folders, import timing extrapolated against the API rate ceiling
- [x] **TAGR-02**: The surviving tagger can own the whole tree, including content that will never
      match MusicBrainz
- [x] **TAGR-03**: The losing tagger definitions are deleted and their Renovate rules released,
      including the wrtag `<0.30.0` pin that enforces the broken state
- [x] **TAGR-04**: soulbeet is removed (issue #306) and the beets block stripped from `audio.bash`
      *(**NOTE 2026-09-18** — this requirement's **own text** is fully measured, and both halves are
      static: issue #306 is closed, and
      `grep -cE '^[[:space:]]*beet ' stacks/selfhosted/arrs/sabnzbd/audio.bash` returns **0**. The
      tick is honest on that basis. Separately, the phase records repeatedly speak of "TAGR-04's
      behavioural half" — a job completing without invoking any tagger at all. That reading comes
      from ROADMAP Phase 4 criterion 3's wording, not from the text above, and it was discharged by
      the **operator-signed override** in `04-VERIFICATION.md` (signed 2026-09-18), which accepted
      threefold unanimous side-effect evidence in place of the criterion's own
      PRE-HOOK/COMPLETION byte comparison. **That byte proof was never obtained.**)*
- [x] **TAGR-05**: Every remaining beets config declares the `musicbrainz` plugin — the defect that
      silently disabled autotagging since beets 2.4.0
- [x] **TAGR-06**: Operator ergonomics is a weighted, recorded factor in the tagger decision, not
      an afterthought — including a reviewable-queue front end (e.g. beets-flask) rather than a
      raw terminal prompt. A tool that is painful to use is a tool that stops being used, and that
      is the documented cause of three prior abandonments

### Configuration — the traps closed

- [x] **CONF-01**: Imports copy rather than move, so a bad run is reversible
- [x] **CONF-02**: `incremental: yes` with `incremental_skip_later: yes`, so a hard album is
      re-offered rather than permanently marked done
- [x] **CONF-03**: Path formats put `ALBUMARTIST` at the top level exactly, case included —
      `Various Artists/`, never `Compilations/`
- [ ] **CONF-04**: `;` is the multi-artist delimiter, the one both consumers parse
      *(STILL OPEN at the end of gap-closure round 5 — and now open on a MEASURED NEGATIVE rather
      than on an untried mechanism. The Music Assistant half is discharged (plans 06-13/06-14,
      re-measured 2026-09-21). The Jellyfin half was DRIVEN inside Phase 6 on 2026-09-24: three
      file mtimes touched from atlantis as real root inside the ZFS snapshot fence
      `tank/media/Music@pre-06-41-conf04-reprobe`, then the same targeted Default-mode
      `POST /Library/Media/Updated` at file scope (plans 06-41, 06-42) — and **ZERO of the three
      pinned rows moved**: row 1 measured 0 against a target of 4, rows 2 and 3 measured 1 each
      against a target of 2, all three AT-BASELINE, with a `;`-in-entity-name count of 0 on every
      row and an EMPTY 1,244-row census delta. This is a measurement and not an UNKNOWN — 06-41's
      `LibraryMonitor` named all three Audio items, so the refresh ran and reached them, and
      `PreferNonstandardArtistsTag` re-read `true` afterwards, so the option did not revert. The
      prober simply did not re-read the `ARTISTS` tag; the mtime mechanism is **disproven** for
      this estate at Jellyfin 10.11.11. The operator's recorded decision — `negative-carry-e6`,
      2026-09-24T14:30:37Z, `artifacts/06-43-conf04-verdict.txt` SECTION P — **CARRIES** the
      Jellyfin half to Phase 7 entry criterion **E6** under an explicit, auditable override.
      **An override is a recorded carry of an OPEN requirement; it is not a close, which is exactly
      why this box stays unticked.** The two halves are **never summed**:
      `scripts/check-music-consumers.sh` still exits 3, and it does so because the MA half reports
      one measured discrepancy owned by E6's SECOND measurement — an exit code is not a CONF-04
      completion signal and would have read 3 on a fully successful re-probe too. See the
      traceability row.)*
- [x] **CONF-05**: Match disambiguation configured — `preferred.countries` using `GB` not `UK`,
      `preferred.original_year`, and `musicbrainz.extra_tags`
- [x] **CONF-06**: `beet import --pretend` on a sample of each bucket produces the intended tree
      *(text deliberately not rewritten — the instrument is `beet move -p`, per the D-33 addendum.)*

### Inbox — a queue with a junk gate

- [x] **INBX-01**: A staging inbox exists under `tank/downloads` with per-policy folders, never
      under `media/`
- [x] **INBX-02**: Bucket D is quarantined — `_FAILED_`, `_UNPACK_`, stray `.rar`, and the
      misfiled Harry Potter BluRay rip
- [x] **INBX-03**: The 45 GB `Now! 1-115` folder is split per volume before it can become one
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
| TRAN-02 | Phase 02.1 | Complete (02.1-06). **Extended to STANDING coverage by 02.1-10:** the zero-`Type: volume` invariant is now asserted on every `scripts/quick-health-check.sh` run, and the guard that keeps it meaningful was proven by negative control — a non-existent container yields an **empty** `docker inspect`, which would otherwise satisfy the `result == ""` test; measured, the check reports the container **ABSENT**, prints `volume mounts: UNKNOWN` rather than `0`, and exits non-zero |
| TRAN-03 | Phase 02.1 | Complete |
| TRAN-04 | Phase 02.1 | Complete |
| TRAN-05 | Phase 02.1 | **COMPLETE (02.1-10), and discharged on DRIVEN branches rather than read ones.** `scripts/check-jellyfin-transcode.sh` runs standalone on LXC 100 and is now folded into `scripts/quick-health-check.sh` as its **third** fatal block, anchored on the literal `📊 6. Summary` with **both** UNKNOWN branches present and each setting `EXIT_CODE=1`. The block is a copy of the D-41 fold-in: inline `ssh -n`, `RC=$?` on the very next line, `$'\033'` ANSI stripping (not `\x1b`, a GNU sed extension — this script runs on macOS), and no second reachability probe (it inherits the WR-10 gate). **All six proofs were EXECUTED, not asserted.** Row 21 — `ZFS_HOST=192.0.2.1` (RFC 5737): exit 1, quota and mounted each their own distinct red, summary `UNKNOWN` for both, and never a `!= 53687091200` mismatch a reader would parse as drift; the container-side device-id instrument **kept answering**, which is why row 36 specifies two. Row 22 — a non-existent container: exit 1, absence **reported**, summary `volume mounts: UNKNOWN` not `0` — an empty `docker inspect` did **not** satisfy the zero-`Type: volume` test it would otherwise have made meaningless, so no defect to fix. A third control pointed `JELLYFIN_SECRETS` at a **non-existent path** (executable only because 02.1-02 made it overridable — the alternative was chmod'ing a file whose `600 root` is an invariant `check-music-consumers.sh` asserts): exit 1, section 5 UNREACHABLE with no values printed, real file still `600 root` before and after. A fourth: `--nonsense` exits exactly **2**, distinct from a failed assertion's 1. Row 23 — proven **without editing `quick-health-check.sh`**, by moving the host-side script aside: exit **1**. Row 24 — the anchor renumbered `6.`→`7.` **while the underlying check still exited 0**, asserted separately: the UNKNOWN branch printed and exit was 1, not the tick the WR-09 defect would have produced. **Every test that broke something recorded a pre-test sha256, restored, asserted the hash matched (`d33356c5…` both times) and re-ran green**; both repos' `scripts/` are empty at the end. **⚠ Two plan defects recorded rather than made to pass.** (1) Row 23's stated MECHANISM is wrong — `ssh host "cmd 2>&1"` puts the redirection inside the remote command string, so bash's own `No such file or directory` **is** captured, output is non-empty and RC is 127, firing the BROKEN branch. The empty-output UNKNOWN branch was then driven properly with a **zero-byte** script, which exposed the branch's key property: a zero-byte script **exits 0**, and `[ -z "$OUT" ]` is tested **before** the return code, so a silently-truncated check cannot report green. (2) Two of the task's acceptance greps are non-discriminating — they match the notices that **explain** the prohibitions — and were already failing at the parent commit (raw 1 and 2); they carry comment-stripped substitutes returning **0** against raw 1 and 3, the same device row 34 uses. D-16, D-17, D-18, D-19, D-20 and **D-22** are all discharged, D-22 by recording the limit in-band: the script is **manual-only**, scheduling deliberately deferred because Phase 2 closed with a notification never proven to deliver. **ADDENDUM 2026-09-03 (02.1-11) — TRAN-05 was RE-OPENED by `/gsd-verify-work` and is now re-closed.** The text above is an accurate record of what was true on 02.1-10 and is deliberately not rewritten. What verification found (CR-01, independently re-confirmed live): the **five encoding values were REPORTED, never ASSERTED** — `check-jellyfin-transcode.sh` printed all five through `info()`, so `FAILURES` never incremented on drift; and `quick-health-check.sh`'s fold-in selector **omitted both tokens**, so on the branch that prints a tick they were neither asserted nor displayed. The consequence was specific: `TranscodingTempPath` set to Jellyfin's own default `/config/transcodes` moves the transcode cache onto `fast/appdata`, **off the quota'd dataset**, while the binds, both mount instruments and the `/` floor all stay green and the script prints `✅ Jellyfin transcode retention intact` — the cheapest route straight back to the incident this phase exists to prevent. What closed it: an `EXPECT_*` block of five `${VAR:-default}` expectations (the values 02.1-05 applied and 02.1-06 proved firing), an `assert_enc()` that calls `fail()` with `expected=`/`found=`, a `transcode target:` summary line, and the selector widened to `transcode target|encoding values|toolchain missing` — the latter two had been named in the check's own cross-file contract comment and **never selected**. **Proven per-field, not per-block:** five separate controls each drove ONE expectation to a wrong-but-plausible value and produced exactly `1` red and `4` green (`FAILURES total: 1`, exit 1) — run 1 used `/config/transcodes`, the exact CR-01 drift, and run 3 used `SegmentKeepSeconds=86400`, the plausible UI edit that silently deletes the retention policy under any two-value scheme. Green driven back afterwards (exit 0, `5 asserted, 0 drifted`). **No file was mutated to run a control** — the overrides perturb the expectation, never the value, deliberately: `/System/Configuration/encoding` is a full-object replace and a partial POST re-arms the D-30 amdgpu hazard. Script sha256 identical before and after; `/mnt/fast/stacks` clean. Also reconciled here: this row's statement said **three** encoding values while ROADMAP SC6 said **five**; five is correct, and **D-20's CONTEXT.md text still says three and was deliberately NOT edited** (it is the locked 2026-09-02 decision record) — a one-line forward-pointer was appended after it instead. **D-21 is now genuinely discharged**: its "applied by REST API, documented in `jellyfin.yaml`, ASSERTED IN THE CHECK" clause had an unimplemented third limb until this plan. ⚠ **Known limitation, stated rather than implied:** the fold-in's RED path was **not** driven end-to-end — `quick-health-check.sh` hard-codes its remote command so an `EXPECT_*` override cannot reach it; the coupling was proven by asserting every selector token appears verbatim in the check's emitted summary, and the red path was driven at the check level in task 2. See `artifacts/02.1-11-encoding-assertion-controls.txt` |
| TRAN-06 | Phase 02.1 | **COMPLETE (02.1-08), with two caveats stated rather than hidden.** `renovate.json5` gains a `jellyfin/jellyfin` rule at index **38**, after `packageRules[2]` at index 2 so it wins on `automerge`: `automerge: false` on `minor` **and** `major`, `patch` deliberately NOT matched so patch automerge survives (D-23), no `allowedVersions` (D-24), no `platformAutomerge` (inert when automerge is false). Jellyfin has been on 10.x since 2019, so 10.9/10.10/10.11 all presented as MINOR and merged unattended through `[2]`; `[5]` catches only major, which for Jellyfin means never. The diff is purely additive (19 insertions, 0 deletions) and all 38 pre-existing rules plus the top-level keys are asserted identical **by parse**, not by eye — `packageRules[1]` still reads `automerge: true` / `["patch","digest"]`. The rule's `description` states the threat ACCURATELY, correcting the reviewed version: an image upgrade does **not** overwrite the settings (they live in `encoding.xml` under `/mnt/fast/appdata`); the two real mechanisms are **semantic change across releases** and the **documented Renovate deploy drift**. `scripts/check-renovate.sh` line 22 tested a hard-coded `renovate.json` this repo does not have, so lines 26-173 had **NEVER EXECUTED** — they ran for the first time here, **exit 0, clean**, 151 lines, transcript committed. All **four** stale literals removed (the plan said two; asserting rather than assuming found 22, 23, 27, 81) and the candidate names are COMPOSED from basename × extension so **zero** hard-coded config filenames remain in executable code. A guarded `VALIDATOR_ROUTE` was added — `grep -c renovate-config-validator` was **0**, i.e. the script called `check-renovate.sh` had never validated the Renovate config at all — and all three of its routes were exercised, the two `local` ones via a PATH stub with nothing installed (pass → exit 0 + green; **FAIL → exit 1 + red, aborting before the inventory**; absent → exit 0 + yellow `UNVALIDATED`, no green tick). **⚠ CAVEAT 1: `renovate.json5` itself is UNVALIDATED.** `renovate-config-validator` is not installed and installing it is out of scope (T-021-SC); node parsed the file and asserted the rule's shape, which proves SYNTAX and SHAPE, **not** semantic validity — an unknown or misspelled key would parse cleanly and still silently stop the whole repo run. **⚠ CAVEAT 2: the rule has never been observed refusing to automerge anything.** There is no `renovate/jellyfin-*` branch among the 27 open ones, so this half is discharged **by construction, not by a firing observation** (CONS-04) — that observation is only available when upstream next ships a Jellyfin minor and cannot be manufactured. D-23, D-24 and D-25 are all discharged |
| TRAN-07 | Phase 02.1 | Complete |
| TRAN-08 | Phase 02.1 | **COMPLETE (02.1-09).** Four unreferenced images reclaimed through the two-process gate, on a **firing** observation rather than a configured one. The gate held in both halves: `inventory` (read-only) wrote `/mnt/fast/spike-03/out/reap-list.txt`, the operator read `02.1-REAP-LIST.md` and ruled **"approved unchanged"** — the explicit phrase the document asked for, so the record distinguishes a deliberate no-edit from an untouched file — and only then did `prune` run. The list was **re-validated by sha256 immediately before the prune** (`1eaa2049…`, 4 lines); a mismatch would have stopped the run. The script's own re-derivation of the referenced set from `docker ps -a` (**no status filter**, covering the estate's documented `created`-state blind spot) ran six hours after the list was built and found **0 conflicts**. `FLOOR_GB=20 … prune` exited 0 — **removed 4, already reclaimed 0, rmi failures 0**, `FLOOR_GB` an environment override throughout and the script byte-identical to `b217ada` (`32f686f9…`). **The prohibition is asserted, not assumed, and the control discriminates:** comment-stripped `grep -cE 'docker (image prune\|system prune)'` returns **0** while the raw count returns **4**, so the strip is demonstrably doing work — a check returning 0 both ways would prove nothing. Evidence: `/` 35555835904 → 37039017984 bytes, attributable delta **1558175744 B (1.45 GiB)**, margin over the D-17 floor 13.11 → 14.49 GiB; per-tag diff of 4 lines gone and **0 added**, with all five image measures moving by exactly 4 and dangling unchanged at 9 → 9 (the three untagged digests deliberately excluded). **⚠ The `df` delta exceeded the ≈1.09 GB forecast by 42%, and that was investigated rather than banked** — `docker system df` Images SIZE moved exactly 1.09 GB, so the forecast was right; the gap is that Docker reports *apparent* bytes and `df` reports *allocated blocks*, measured at 1.342× on the 107,030-file `keeper-web:2.23` sibling. **⚠ Exit 0 is recorded as near-vacuous** on its own, since `/` already cleared the floor by 13.11 GiB. Estate unharmed: no container changed state, the internet-facing `cal-*` stack up 20–21 h unrestarted with cal-web serving `307 → /login → 200`, `check-jellyfin-transcode.sh` exit 0. D-28 discharged |
| TRAN-09 | Phase 02.1 | **COMPLETE (02.1-07).** `do_enable` captures the five transcode-retention values from the live config BEFORE the whole-file `.bak` restore, re-asserts them into the restored file, and verifies them on BOTH sides of the container restart — naming any moved field with its before and after values and exiting non-zero. Discharged on a **firing** observation, not a read-back: `check` → `disable` → simulated phase write → `enable` was EXECUTED against a throwaway `encoding.xml` and a disposable container (exit 0, all five preserved, `HardwareAccelerationType` restored to `vaapi`). **The verification was then proven able to FAIL, twice** — the review's HIGH finding was that the reviewed control could not fail, because the verification lives inside `do_enable` which re-captures live values before restoring. (a) the standalone read-only `verify-retention` sub-action, taking its expectations from `$TRAN09_EXPECT`, exited 1 on a perturbed config naming the field with expected-vs-found, and 0 once restored; (b) `TRAN09_FAULT=1 … enable` exited 1 naming four of five fields with both values, while `ThrottleDelaySeconds` correctly PASSED at 180 either side — proving the comparison is genuinely per-field. The live `encoding.xml` sha256 and `.bak` inventory are identical either side and `check-jellyfin-transcode.sh` still exits 0. The D-30 amdgpu mitigation (`none` / `false`) is unchanged |
| CONS-04 | Phase 7 | Pending |
| TAGR-01 | Phase 3 | Complete |
| TAGR-02 | Phase 3 | Complete |
| TAGR-06 | Phase 3 | Complete |
| TAGR-03 | Phase 4 | Complete (Phase 4) |
| TAGR-04 | Phase 4 | Complete (Phase 4) |
| TAGR-05 | Phase 4 | Complete (Phase 4). **ADDENDUM 2026-09-11 (04-04, D-20/D-27)** — two clarifications to the requirement text, neither of which reduces it. (1) **Scope:** "every remaining beets config" includes the survivor's **newly vendored** `stacks/selfhosted/arrs/beets/config.yaml` (D-27), alongside `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml`. Vendoring makes the requirement checkable in git for both. The vendored file is created by plan 04-08 and does not exist at this addendum's commit. The survivor's live host config is a pasted compose service definition with no `plugins:` key at all (04-RESEARCH F4), which is why it is replaced by a vendored file rather than edited in place. (2) **Instrument:** the proving instrument is the probe pair named in ROADMAP Phase 4 criterion 4's amendment: the MB-only `tag_album()` probe with its D-17 negative control, plus a hand-read `beet import -t`. It is **not `--pretend`**, which in beets v2.13.1 never calls `lookup_candidates` and so returns zero candidates by construction. The text above is deliberately not rewritten. |
| INBX-01 | Phase 5 | Complete (Phase 5, plan 05-01; re-asserted from live state at close by 05-11 — six directories present, `_inbox` sharing a devid with `unsorted/` and `dj-mixes/`, zero `_inbox` datasets, zero equivalents under `media/` to depth 3, and the inode proof driven again after the chown with both controls). **ADDENDUM 2026-09-18 (05-02, D-17/D-18/D-21/D-23)** — three clarifications to the requirement text, none of which reduce it. (1) **The measured path** is `/mnt/tank/downloads/complete/nzb/_inbox`, holding exactly six per-policy folders — `01-auto`, `02-review`, `03-asis`, `04-hold`, `99-quarantine`, `_done` — created empty and `568:568` from atlantis by plan 05-01 (D-17, D-23). Recording the *measured* path is itself a deliverable: Phase 6 configures beets-flask against directories that exist rather than intended ones (D-16). (2) **`_inbox` is a plain directory and must NEVER become its own ZFS dataset (D-18).** A dataset would place it on a different `devid` from `unsorted/` and `dj-mixes/` (measured: both `devid=68`, against `tank/media/Music` at `devid=76`), turning every move into copy-then-unlink and destroying the atomic-rename property this requirement's criterion is verified by. It looks like a tidy improvement — quota, independent snapshots, exactly what `fast/transcode` got in Phase 02.1 — which is why the prohibition is written down rather than assumed. (3) **The atomic-rename proof carries a cross-dataset negative control (D-21)**, driven by plan 05-01: an inode that has only ever been observed staying the same is an instrument nobody has shown can distinguish anything. ⚠ That proof must compare the pair `(devid, inode)`, never the inode alone — `/mnt/tank/downloads` and `/mnt/tank/media/Music` were both measured at inode 34. The text above is deliberately not rewritten. |
| INBX-02 | Phase 5 | Complete (Phase 5, plans 05-03 and 05-04; re-asserted from live state at close by 05-11 — zero `_FAILED_`/`_UNPACK_` directories and zero `.rar`-form files across the five music paths outside `99-quarantine`, `lidarr-import` absent, the named Potter rip absent). **ADDENDUM 2026-09-18 (05-02, D-12/D-14/D-15)** — two clarifications to the requirement text, neither of which reduces it. (1) **Scope:** the quarantine sweep covers the **music paths only** — `complete/nzb/music/`, `complete/nzb/unsorted/`, `complete/nzb/dj-mixes/`, `/mnt/tank/downloads/lidarr-import/` and the new `complete/nzb/_inbox/` — not the whole download tree (D-12). Measured (`05-PREMEASURE.md` § 5): of ten `_FAILED_`/`_UNPACK_` directories under `complete/nzb/`, only four are music; the other six are Sonarr's and Radarr's and are named in that section rather than lost. `incomplete/` is out of scope entirely (D-15): it is SABnzbd's live working directory and moving anything under it can break an active download. (2) **The Harry Potter clause names the wrong tree (D-14).** A `find` over `dj-mixes` to depth 3 for `*potter*` returns **zero** (`05-PREMEASURE.md` § 4); the rip that exists is `complete/nzb/unsorted/Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE` and it is **ordinary junk** — a video in a music folder, taken through D-13's approval gate with everything else and deleted, not a specially-handled item and not a criterion blocker. `99-quarantine` is a review-and-delete queue, not an archive (D-11). The text above is deliberately not rewritten. |
| INBX-03 | Phase 5 | Complete (Phase 5, plans 05-05 → 05-07 and 05-09; re-asserted from live state at close by 05-11 — 115 depth-1 `Vol 001`…`Vol 115` folders, zero depth-2 directories, 4,746 mp3 summing to the live collection total, zero at the collection root, each folder carrying exactly one album value, the 11-row exception set matching the pre-declared post-merge list 11 for 11, and 0 manifest-only entries on their own line). **ADDENDUM 2026-09-18 (05-02, D-02/D-05/D-08)** — three clarifications to the requirement text, none of which reduce it. (1) **The target is FLAT.** Measured (`05-PREMEASURE.md` § 3): `complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023` holds 4,760 files and **zero subdirectories**, so the per-volume folders are **created, not moved**, inside the existing folder as atomic same-dataset renames (D-07), and volume boundaries must be derived from the m3u map with the `album` tag as an independent cross-check (D-02). The 512 B same-named folder under `dj-mixes/` is empty and is junk for INBX-02's sweep, not a second split target. (2) **The denominator is 4,746 mp3**, not 4,760: the 4,760 resolves as 4,746 mp3 plus 14 sidecars, which are accounted separately, and the m3u's 4,770 entries are 24 more than exist on disk — those 24 are reported on their own line and never folded into the total (D-08). (3) **The instrument is per-volume, not a single total:** `files_present == sum of tracktotal` across that volume's discs, because a bare total of 4,746 would pass even if every file landed in the wrong folder. All discs of a volume live in one folder; the CD1/CD2 split is not restored (D-05). The text above is deliberately not rewritten. |
| CONF-01 | Phase 6 | **Complete (Phase 6; plan 06-01 wrote the config, plan 06-07 built the instrument that asserts it; re-asserted from live state at close by 06-14).** `bash scripts/check-beets-config.sh` re-run 2026-09-21T22:04Z: exit 0, `FAILURES total: 0`, `✅ CONF-01 import.copy = true` and `✅ CONF-01 import.move = false`. **The arm matters more than the values.** Both are read from `CONFIG_ROUTE=server-committed` — arm 1, the object beets-flask's own `commit_to_beets()` builds and the one that will actually import — never from `beet config -d`, which cannot see rc6's schema injection at all. The run's positive control (`gui.num_preview_workers=4`, `gui.terminal.start_path=/repo`, rc6 keys the CLI view does not carry) proves the dump IS that object, and `arm 1 blind: 0` proves the assertions were made rather than skipped. ⚠ **`import.write = true` in that same config is REPORTED, not asserted** — that is Phase 7 behaviour, and every Phase 6 invocation overrode it to `no` through its own `-c` overlay |
| CONF-02 | Phase 6 | **Complete (Phase 6; plans 06-01, 06-07 and 06-08; re-asserted from live state at close by 06-14).** Read-back, 2026-09-21T22:04Z, arm 1: `✅ CONF-02 import.incremental = true` and `✅ CONF-02 import.incremental_skip_later = true`. **A read-back is NOT the evidence this requirement needs, and that is the whole point of the row:** the trap is that `incremental` without `incremental_skip_later` records SKIPPED directories as done, so one quiet pass permanently marks every hard album complete. Plan 06-08's `scripts/phase06-incremental-control.sh` is a **two-arm negative control**, two overlays **exactly one key apart** (proven byte-identical otherwise, `diff` returning exactly two lines both naming `incremental_skip_later`), driven to **opposite observable outcomes on the first run with no retuning**: arm A (`no`) → `taghistory` **POPULATED**, folder **NOT re-offered** — the trap FIRES; arm B (`yes`) → `taghistory` **EMPTY**, folder **RE-OFFERED** — the trap is DEFEATED. Both arms pre-seed an empty state pickle deliberately, so that "taghistory is empty" and "I could not look at taghistory" stay distinguishable. `--self-test` re-run at close: exit 0, every fail-closed branch and every refusal behaved as expected |
| CONF-03 | Phase 6 | **Complete (Phase 6; plans 06-05, 06-09 and 06-11; re-verified at close by 06-14).** `bash scripts/phase06-oracle.sh --run` → **exit 0 and ZERO LINES OF DIFFERENCE** over 174 destinations against `06-EXPECTED-TREE.txt`, a fixture committed **before** the run it judges (D-27) and still at its original commit `cb9f49a`, sha256 `37b2083e…`, 351 lines — re-checked at close, because a fixture edited after the run it judges proves nothing. Class assertion § 7.1: **0 mismatches, 0 rows the comparison could not be made for**, case NOT folded, across all three path shapes (album artist is the FIRST component under rules 4/5/6, the SECOND under rules 3/2 and under rule 1's `Singles/`). § 7.2: **0** path components named `Compilations`, paired with a **44-destination `Various Artists/` positive control** — a zero-Compilations result is meaningless unless the `comp` rule was demonstrably reached. Five preconditions were evaluated BEFORE the diff was permitted to run; any failure would have been exit 3 `UNKNOWN, not green` with the diff never evaluated. ⚠ **D-14's literal `2-05` renders as `02-05`**: `disc` and `track` are both `types.PaddedInt(2)`, so `$disc-$track` cannot produce a single-digit disc. **Phase 6 chose `02-05`** — it sorts correctly where the alternative `%right{$disc,1}-$track` breaks at disc 10 — and wrote the expected tree to it; 31 destinations carry the prefix and 0 `Disc N/` subdirectories exist. ⚠ **The existing library uses a THIRD convention, `CD 02-01 Artist - Title.ext`, and Phase 6 deliberately did NOT reconcile the two** — the S6 rows show source and destination conventions side by side. ⚠ **CONF-03 passes while still admitting two "various artists" tops** (DEF-06-11-01): the tree grows both `Various Artists/` (44 files, compilation-flagged, `va_name`) and `Various/` (30 files, literal tag) — each DOES equal its own `ALBUMARTIST` byte-exactly, so the requirement holds, but two spellings of one idea is two artist pages in Jellyfin and MA. **No path rule can fix it; it is a Phase 7 tag decision.** ⚠ **Path rule 2 (`albumtype:=dj disctotal:2..`) was evaluated by NO Phase 6 instrument** (DEF-06-12-01) — both drawn S5 folders resolved through rule 3 — and is deferred to Phase 7 by explicit operator decision |
| CONF-04 | Phase 6 | **OPEN (Phase 6 closed with this requirement half-discharged, and it is a NAMED PHASE 7 ENTRY BLOCKER).** Two consumers, **two separate verdicts that are never summed** — an averaged tick would hide exactly the half that is not done. **Music Assistant half: DISCHARGED (plan 06-13, re-measured at close by 06-14 on 2026-09-21T22:06:38Z against the running 2.11.0b2).** The three pinned `ARTISTS` rows read `Jewels n' Drugs` **3 of 4**, `California Gurls` **2 of 2** (`Katy Perry \| Snoop Dogg`, item_ids 73, 244), `Just Give Me a Reason` **2 of 2** (`P!nk \| Nate Ruess`, item_ids 63, 201); every artist is a distinct library entity with its own `library://artist/N` uri, **no artist name anywhere contains a `;`**, and a planted non-existent title returns 0 matches so the selector is demonstrably able to miss. Research assumptions A1 and A2 were both **resolved first** — A2 against `GET /api-docs/commands.json` on the live server, which also established that `music/albums/count` declares **no `provider` parameter at all** and must never be cited — and the `summary`-defaults-to-true truncation trap was checked and cleared. Row 1 is a **measured discrepancy, not a pending state**: `Twista` exists nowhere in MA's artist-entity table, and "MA caps at 3" versus "Twista specifically failed to map" **cannot be separated from a sample of one** (distribution: 1,220 tracks at 1, 22 at 2, 2 at 3, none above 3). **Jellyfin half: COULD NOT LOOK — OPEN by measurement, not by omission.** Re-measured at close, 2026-09-21T22:06:03Z: the library option is set and asserted (`PreferNonstandardArtistsTag=true`, `UseCustomTagDelimiters=false`, `SaveLocalMetadata=false`, `EnableRealtimeMonitor=false` from `GET /Library/VirtualFolders`), and the same three rows still read **0 of 4, 1 of 2, 1 of 2** — their pre-change baselines. **Reason:** `PreferNonstandardArtistsTag` is a **probe-time** option and a Default-mode refresh does not re-run the prober on a file whose mtime has not changed; measured twice at album scope and file scope, **0 of 1,244 census rows moved**. The only refresh mode that would re-probe is the aggressive per-item one Phase 1 measured rewriting 83 of 91 `.nfo` with `SaveLocalMetadata` already off — **forbidden in this estate and deliberately not issued**. **The exact remaining step:** Phase 7's first write or import of a multi-artist release, then re-run `bash scripts/check-music-consumers.sh` on LXC 100 and assert the three rows reach 4/2/2. Do **not** record this row as "Complete (Jellyfin)". **ADDENDUM 2026-09-20 (06-02, D-34)** — two corrections to how this requirement is discharged, amending D-23. Neither reduces the requirement. (1) **The WRITE side is the `ARTISTS` tag (ID3 `TXXX:ARTISTS`, Vorbis `ARTISTS`) — NOT `;` inside `ARTIST`.** beets builds `item.artist` by concatenating MusicBrainz artist-credit `joinphrase` values (`"".join(artist_parts)`, `beetsplug/musicbrainz.py@v2.12.0:341-367`), and **no delimiter, separator or join key exists anywhere in `config_default.yaml` at 2.12.0 or 2.13.1** — measured 2026-09-20 by grep over both files. beets therefore **cannot be configured** to emit `;` in `ARTIST`; asking it to is asking for a setting that does not exist. The `;` named in the requirement text is a property of the **existing** library's 12 files, not of anything this pipeline will produce. (2) **The READ side becomes a decision rather than an observation.** The Jellyfin Music library measures `UseCustomTagDelimiters=False` and `PreferNonstandardArtistsTag=False` (`GET /Library/VirtualFolders`, 2026-09-20), and 10.11.11's prober splits on custom delimiters only when the former is true (`MediaBrowser.Providers/MediaInfo/AudioFileProber.cs@v10.11.11:227-246`) — so today's multi-artist reading is almost certainly stale DB state from a pre-10.10 probe. D-34 **enables `PreferNonstandardArtistsTag`** so Jellyfin reads the tag beets actually writes and agrees with Music Assistant (`TAG_SPLITTER=";"`, `ARTISTS` preferred) **by construction rather than by coincidence**. `UseCustomTagDelimiters` is deliberately **NOT** enabled: `/`, `\|` and `\` come along with `;` across 1,244 files unless `CustomTagDelimiters` is narrowed and `DelimiterWhitelist` populated, and `AC/DC` is the canonical casualty. ⚠ **This is a live-service config change that git does not capture.** It is written into `stacks/selfhosted/arrs/beets.md` and **asserted** by `scripts/check-music-consumers.sh` (plan 06-12); without that assertion it is one UI click from silently reverting, and the revert leaves no trace in any repo. Also recorded here: **D-20's exhaustive delimiter search was answered offline** against Phase 1's `pre-project.ndjson.gz` over all 1,244 library files — 6 carry `;` in `ARTIST` (all in `P!nk/TRUSTFALL (2023)`, including a three-artist track) and 6 carry `;` in `ARTISTS` (P!nk, Lady Gaga ×2 with a four-artist case, Katy Perry). **D-21's fenced write with the scoped `rw` grant is therefore NOT required and must not fire** — the `:ro` invariant stays unbroken for the whole phase. The text above is deliberately not rewritten. **ADDENDUM 2026-09-24 (gap-closure round 5, plans 06-40 … 06-43) — the Jellyfin half's discharge mechanism was DRIVEN and MEASURED NOT TO WORK, and the requirement is CARRIED, not closed.** This row's own "exact remaining step" named Phase 7's first write; the operator instead chose to pull the lever 06-03 named and never pulled, inside Phase 6. Mechanism: three file mtimes touched from atlantis as real root inside the ZFS snapshot fence `tank/media/Music@pre-06-41-conf04-reprobe`, then the same targeted Default-mode `POST /Library/Media/Updated` at **file** scope — **one write verb for the entire round**, returning 204 — and a ≥120 s settle (measured 19,597 s). Result, recorded as a **REPRODUCIBLE NEGATIVE**: **all three pinned rows read AT-BASELINE** — `Jewels n' Drugs` **0 of 4**, `California Gurls` **1 of 2**, `Just Give Me a Reason` **1 of 2** — with 0 `;` in any entity name, and the 1,244-row census delta **EMPTY**. It is a measurement and not an UNKNOWN: 06-41's `LibraryMonitor` named all three Audio items by full internal path 60 s after the POST, so the refresh ran and reached them, and `PreferNonstandardArtistsTag` re-read **`true`** afterwards, so the option did not revert — the prober did not re-read the `ARTISTS` tag. **06-03's mechanism (b), "the file's mtime changing", is therefore DISPROVEN for this estate at Jellyfin 10.11.11.** Safety was asserted four ways and ends `SAFETY: PASS`: `zfs diff` byte-identical to the post-touch block (three `M` entries, zero non-`M`, zero sidecars), **0 of 91** `.nfo` differing in sha256 or mtime, all three pinned files' content sha256 unchanged, and the six `P!nk/TRUSTFALL (2023)` DO-NOT-RESCAN rows excluded and verified unchanged. ⛔ Nothing was escalated: no second refresh, no wider refresh mode, and the aggressive per-item mode stays **forbidden** and was unreachable from every branch. **The operator's recorded decision is `negative-carry-e6` (2026-09-24T14:30:37Z, `artifacts/06-43-conf04-verdict.txt` SECTION P)** — option (a) of `06-VERIFICATION.md` § Recommended path: carry the Jellyfin half to **Phase 7 entry criterion E6** under an explicit override so the roadmap's argument becomes auditable rather than implicit. **That override is NOT a close.** The checkbox stays unticked, `requirements mark-complete` was not run, and `06-VERIFICATION.md` was not re-scored — that is `/gsd-verify 06`'s call. E6's **SECOND** measurement — whether a second ≥4-artist track yields four artists in Music Assistant or three, the only thing separating "MA caps at 3" from "`Twista` specifically failed to map" — was never in round 5's scope and stays with Phase 7 regardless. Related and not absorbed: row 1 is one of the 30 items Phase 7 entry criterion **E5** owns, carrying a populated `Artists` string list with **zero** linked `ArtistItems`, which is why a per-file refresh that creates no artist entity was always the weakest lever on that row. `tank/media/Music@pre-06-41-conf04-reprobe` is **still held**; its release is a separate operator decision. |
| CONF-05 | Phase 6 | **Complete (Phase 6; plans 06-01, 06-07, 06-11 and 06-12; re-asserted from live state at close by 06-14).** Set, re-read 2026-09-21T22:04Z from arm 1: `match.preferred.countries` = `["GB","US"]` containing `GB` and **carrying no `UK` entry**, `match.preferred.original_year = true`, `musicbrainz.extra_tags` a non-empty 5-entry list `["year","catalognum","country","media","label"]`. **Demonstrated, which is what the criterion actually asks:** plan 06-12 drove ten `beet import -t` overlays through a real MusicBrainz lookup with a **track-count check on every match**. ⚠ **Honest detail, recorded rather than smoothed:** the plan's own A/B/C negative controls on the S4 *Now!* row came out with an **IDENTICAL** chosen candidate — every distance moved in the predicted direction and by the predicted magnitude, but the GB release beats its nearest rival by **0.53** while the whole country term is worth at most **0.0075**, so no ordering of two country codes can close that gap. The plan's escape clause fired: a second S4 row (`Vol 002`) was tried and was also identical, and **the demonstration proper was relocated to a genuine one-key rank-0 FLIP on a different drawn row** — the S1 `Benson Boone / American Heart` release, which MusicBrainz holds as three US and two XW entries with identical 10-track listings so `country` is the only separating term: overlay K `['XW','US']` → rank 0 **XW** `b3a1e018…`, overlay L `['US','XW']` → rank 0 **US** `e4fdb1dc…`, both distance 0.0. **`GB` works and `UK` silently does not, measured:** under `['GB']` the GB release carries no country penalty; under `['UK']` **every** candidate carries a uniform full penalty that cancels out of the ordering — the setting is inert with no warning, no log line and no non-zero exit. ⚠ And the source data itself says `UK` (`TXXX:COUNTRY = UK`), so somebody matching the config to the files would write it. ⚠ Entries are **regexes** compiled `re.I`, so a stray `.` or `\|` widens the match rather than failing. **"The run wrote nothing" is discharged by the three-layer D-29 proof, NOT by a file count** — see CONF-06. ⚠ `musicbrainz.search_limit` is the default **5** (DEF-06-12-02): on `Vol 001` that pool offered **zero** US candidates where 25 offered seven. Recorded as a Phase 7 measurement, **not** as a recommendation to raise it |
| CONF-06 | Phase 6 | **Complete (Phase 6; plans 06-02, 06-09 and 06-11; re-verified at close by 06-14), and the D-33 addendum below STANDS.** The instrument is **`beet move -p`**, never `beet import --pretend`: `--pretend`'s pipeline is exactly `read_tasks → log_files`, `lookup_candidates` is never in it, **no destination path is ever computed**, and it prints one SOURCE line per file and exits 0 — which is exactly why it reads as a pass. `beet move -p` prints `Source … -> Destination` through `item.destination()`, the same code path a real import uses, so it evaluates the full `paths:` stanza, `%aunique{}`, `replace:`, `asciify_paths`, `legalize_path` and `max_filename_length`. Both are read-only. Executed: **exit 0, zero-diff over 174 destinations**, `Moving 174 items.` cross-checked against 174 pairs parsed and against `06-SAMPLE.md`'s own Files column, with `%aunique{}` firing **exactly once** and reconciled in both directions. **"Written nothing" is proven on three layers, because a count would pass while content changed underneath — Phase 1 measured exactly that:** layer 1 `docker inspect` shows the `/media` mount at **`RW=false`**; layer 2 `meta` **and** `sha256` manifests over all **190** files of the ten sampled folders identical before and after, re-verified outside the script with `cmp`; layer 3 `/config/library.db` `fbbdde0c…` and `/config/state.pickle` `f6a9a1ad…` **byte-identical with mtimes recorded as well as hashes** — an empty-state pickle rewritten with identical content would move the mtime and leave the hash alone. The same two hashes were observed unchanged either side of the close-time `check-beets-config.sh` run. The comparison refuses to read `diff`'s empty stdout on an error as "identical": exit status ≥ 2 is **COULD NOT COMPARE**, never a pass. See CONF-03 for the `02-05` rendering caveat. **ADDENDUM 2026-09-20 (06-02, D-33)** — the instrument named in the requirement text cannot measure what the requirement asks for. The text stands; the correct instrument is named here. (1) **`beet import --pretend` CANNOT produce the intended tree.** In beets 2.12.0 the pretend pipeline is exactly two stages, `read_tasks → log_files` (`beets/importer/session.py@v2.12.0:201-240`); `log_files` prints `Album: <source dir>` followed by one `  <source file>` line per item (`beets/importer/stages.py@v2.12.0:266-274`). `lookup_candidates` is **not in the pipeline**, so no MusicBrainz query runs, no match exists, and **no destination path is ever computed**. (2) **This is not a new finding.** The same fact is recorded against TAGR-05 in the row above, dated 2026-09-11 in Phase 4 — and CONF-06 was written after it. That is stated explicitly because a fact that was already written down and then not used is a different failure from a fact nobody knew, and it calls for a different fix. (3) **The destination-path oracle is `beet move -p`.** It prints `Source … -> Destination` pairs via `item.destination()` (`beets/ui/commands/move.py@v2.12.0`) — the same code path a real import uses, so it evaluates the full `paths:` stanza, `%aunique{}`, `replace:`, `asciify_paths`, `legalize_path` and `max_filename_length`. Both instruments are read-only. (4) **`--pretend` is KEPT**, for what it genuinely proves: which folders are offered as tasks — i.e. `incremental`, `ignore`, `ignore_hidden`, `clutter`, `singletons` and album grouping — and it proves that without reaching `finalize`, the only place `save_history()`/`save_progress()` are called (`beets/importer/tasks.py@v2.12.0:310-320`). That is why it still serves D-31. (5) ⚠ **The trap to watch:** `--pretend` prints one line per file and exits 0, so a reader takes it as "the tree is right". The discriminator is mechanical — a `--pretend` transcript contains **no ` -> ` and no `/mnt/tank/media/Music/` substring at all**. If a CONF-06 artefact has neither, it is a source-file listing, not a tree. The text above is deliberately not rewritten. |
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
