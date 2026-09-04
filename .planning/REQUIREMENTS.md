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
- [ ] **TAGR-03**: The losing tagger definitions are deleted and their Renovate rules released,
      including the wrtag `<0.30.0` pin that enforces the broken state
- [ ] **TAGR-04**: soulbeet is removed (issue #306) and the beets block stripped from `audio.bash`
- [ ] **TAGR-05**: Every remaining beets config declares the `musicbrainz` plugin — the defect that
      silently disabled autotagging since beets 2.4.0
- [x] **TAGR-06**: Operator ergonomics is a weighted, recorded factor in the tagger decision, not
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
