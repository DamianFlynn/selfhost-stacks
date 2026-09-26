# Roadmap: Music Library Consolidation

## Overview

Four tagging entry points were built over three years, every one of them pointed at
`/mnt/tank/media/Music` with its own private database, and a fifth writer (Lidarr, renaming in
place) was never counted. This roadmap fixes the write-ownership problem first, then decides the
tagger on measured evidence, then retires the losers, then proves the pipeline on twelve albums
before scaling it. The ordering is load-bearing rather than cosmetic: the safety harness runs
before the spike because every harness item is tagger-independent and several protect assets that
cannot be recreated; the NFS export and Music Assistant proof run in parallel from the start
because Music Assistant never purges stale entries, so it must be proven *before* content flows,
not after; the junk gate precedes every import phase because junk in the sample corrupts the
evidence; and the retirement phase is built to be independently shippable, because this project
has been abandoned three times and a fourth stall must still leave the estate strictly better than
it started.

The project's definition of done is **CONS-04**: a file is imported only when verified with
`ffprobe` on the file itself *and* visible in both Jellyfin and Music Assistant. No phase that
touches content exits on "tool configured".

Two constraints run underneath the whole roadmap and are called out because both have already
caused failures here:

**The library is not empty.** Much of it is already tagged. A file can pass every check in CONS-04
— it lands, `ffprobe` reads it, both consumers show it — while having *lost* fields it arrived
with. That is a regression that looks like a success, and at scale it is unrecoverable. The QUAL
requirements close it: a before-state snapshot is taken in Phase 1, before anything is staged, and
a field-level before/after diff gates the pilot in Phase 7.

**A painful tool is a tool that stops being used**, and that is the documented cause of three prior
abandonments. So the Phase 3 spike weighs ergonomics as a scored factor, not a footnote, and treats
"which engine" and "how the human meets it" as two separate questions — the second may matter more
to whether this project finishes than the first.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

**Execution:** plans within a phase run one at a time (`parallelization: false`). Most phases touch
the same filesystem paths and the same beets state.

- [x] **Phase 1: Safety Harness and Freeze the Writers** - One writer on the library, everything irreplaceable copied somewhere no tagger can reach, and a before-state tag snapshot taken while the library is still untouched
- [x] **Phase 2: NFS Export and Music Assistant Reachability** - The second consumer proven on three albums, before any content flows (completed 2026-09-01; D-55 approved after the operator played tracks)
- [x] **Phase 02.1: Jellyfin transcode retention** *(INSERTED)* - Relocate the anonymous transcode volume off `/` and set a retention policy, so the 19 GB cache that emptied `/` mid-Phase-3 cannot refill there (all 10 plans executed 2026-09-03; `/` free 20.18 GiB -> 34.48 GiB, margin over the D-17 floor 185 MiB -> 14.48 GiB, `check-jellyfin-transcode.sh` FAILURES 0 and folded into `quick-health-check.sh`. **VERIFIED 2026-09-03: `gaps_found`, 8/10 must-haves** -- the structural relocation is real and re-verified live, but two gaps block completion, both confirmed independently: (CR-01) `TranscodingTempPath` is REPORTED not asserted, so drift off the quota'd dataset leaves the standing check green -- which undercuts the goal's own "a standing fail-closed check would have caught the incident"; and (CR-02) the "Jellyfin publishes NO host port" claim is FALSE -- `curl http://172.16.1.76:8096/health` returns 200 from the LAN -- and it is the last compensating control for the admin-equivalent API key this phase widened from read to write. Close with `/gsd-plan-phase 02.1 --gaps`) (completed 2026-09-03)
- [x] **Phase 3: Tagger Spike** - One tagger *and* one front end chosen on numbers from this library's own content, against thresholds committed in advance (completed 2026-09-04)
- [x] **Phase 4: Collapse to One Tagger** - One tagger, one database, no idle container holding a rw mount — independently shippable (closed 2026-09-18 at 5/5: criteria 1, 2, 4 and 5 verified by live measurement; **criterion 3 discharged by a signed override, not by a byte proof** — the operator accepted the threefold unanimous side-effect evidence (5 real music jobs, 2 observation windows, 0 tagger artefacts of any kind) in place of the PRE-HOOK/COMPLETION byte comparison the criterion's own evidence contract asks for, after three capture designs were built and exhausted and the third was deliberately never armed. Signed record: `.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md`)
- [x] **Phase 5: Inbox Structure and the Junk Gate** - A staging queue outside the library, with the junk already out of it (closed 2026-09-19 at **4/4 criteria TRUE, 0 FAIL** — each one **re-measured from live state at close** by plan 05-11 after the sweep, the split, the album write and the chown, rather than carried forward from the plan summaries: `artifacts/05-11-final-assertions.txt`. Criteria 2 and 3 are TRUE against their dated 2026-09-18 in-band amendments, not against their original wording. Criterion 4 was already green before the phase began and is now **asserted** by the standing health check, with its negative control driven once on 2026-09-18. Four items are recorded **OPEN**, none of them a violated condition: the pre-existing `interpolated-host-path` gate that makes `quick-health-check.sh` exit 1, `mac-music-archive/`'s 23,874 uncharacterised music entries, an Immich API key on a systemd command line, and `dropbox/` inside nine `rw` binds. Durable record: `stacks/selfhosted/arrs/beets.md` § *Phase 5*)
- [ ] **Phase 6: Tagger Configuration and Dry Run** - The intended tree proven on paper before it is produced on disk
- [ ] **Phase 7: Pilot — 12 Albums End to End** - A flow the operator believes: twelve albums including the painful shapes, no net metadata loss, undo exercised
- [ ] **Phase 8: Close the Inflow** - A new download lands, gets tagged, and never silently skips
- [ ] **Phase 9: Bucket A in Batches** - The mainstream backlog imported at a rate that finishes

## Phase Details

### Phase 1: Safety Harness and Freeze the Writers

**Goal**: The library tree has exactly one process able to write it, every irreplaceable asset has
a copy on a path no tagger can reach, and the before-state of the existing tags is captured — all
established before any tool is chosen and before any file is staged or imported.
**Depends on**: Nothing (first phase)
**Requirements**: SAFE-01, SAFE-02, SAFE-03, SAFE-04, SAFE-05, WRIT-01, WRIT-02, WRIT-03, WRIT-04, QUAL-01
**Success Criteria** (what must be TRUE):

  1. Inspecting the mounts of every *running* container returns exactly one with a read-write path
     to `/mnt/tank/media/Music`. wrtag is stopped and its library mount is deleted from
     `wrtag.yaml` — the mount, not just the restart policy.
     **✅ TRUE as of 01-06** (01-05 + 01-06 together): `tagger-class writers: 0`, `unclassified: 0`,
     `consumer-class: 1` (jellyfin, D-21), `declared rw reaching Music: 0`. 01-09 asserts it.

  2. Lidarr no longer touches the library tree: root folder repointed off `/media/Music` and
     `renameTracks` off, confirmed from Lidarr's API rather than the UI.
     **✅ TRUE as of 01-06.** Note the nuance: deleting the root folder did *not* repoint the 22
     existing artists, which keep absolute `/media/Music/<Artist>` paths. The `:ro` mount (D-25),
     not the root-folder move, is what actually closes the library.

  3. Destructive defaults are off in *every* beets config in the estate — the repo ones and the
     on-host `/config/scripts/beets-config.yaml` — with `scrub.auto: no`, `lastgenre.auto: no`,
     `embedart.auto: no` present in each; and Jellyfin writes nothing into Music: `SaveLocalMetadata`
     off, scheduled scans paused, database backed up, and no new `.nfo`/`.jpg`/`.lrc` appearing in a
     watched folder over an hour.
     **Jellyfin half ✅ TRUE as of 01-06**; the beets-config half (SAFE-01) is 01-07 and still open.
     Two corrections this criterion needs, both measured rather than assumed:
     (a) the watch must compare sidecar **content**, not the set of paths — a path-set diff returned
     a perfect pass while Jellyfin rewrote 83 of the library's 91 `.nfo` in place, 66 with changed
     content. The watch that passed used sha256 hashes, a whole-library size/mtime manifest and a
     `zfs diff` cross-check, over a widened `.nfo/.jpg/.lrc/.png/.txt` set (1,341 files, not 1,123).
     (b) `SaveLocalMetadata: false` gates the *automatic* save path only — an explicit
     `FullRefresh` (the UI's "Refresh metadata" button) still writes. "Jellyfin writes nothing into
     Music" is true **unprompted** and false as an absolute.

  4. The recovery fence exists and is readable: `tank/media/Music@pre-project` snapshot plus copies
     of every beets `library.db` taken in the same step, an `ffprobe` JSON dump of all 764
     `dj-mixes` files including `TKEY` and `EnergyLevel`, and the 54 DJ cover scans — all on paths
     no tagger container mounts read-write, with spot-checks confirming the copies match source.
     **✅ TRUE as of 01-02**, re-verified in 01-09: 18 `library.db` copies (each integrity-checked),
     764 `ffprobe` JSON with `TKEY` in 148 and `EnergyLevel` in 45, 54 scans (**30 jpg + 24 bmp** —
     a jpg/png-only extension list archives 30 of 54), both `@pre-project` snapshots, and **no
     running container mounting any path under `/mnt/fast/safety`**, proven from the same
     enumeration WRIT-01 uses. Note the figure: this criterion originally said "794 `dj-mixes`
     files"; **764 is the audio count** — 794 was 764 audio + the 30 JPEG scans counted as tracks.

  5. `stat` over all 13 artist folders returns one decided `uid:gid` (today: 12 are `568:65534`,
     1 is `568:568`, matching neither `beets.md` nor `CLAUDE.md`), and that decided value is
     recorded in the repo — it also sets `anonuid`/`anongid` on the Phase 2 export.
     **✅ TRUE as of 01-09** (01-08 + 01-09). Both halves: **2,674 of 2,674** entries are `568:568`
     on disk — library root included — verified from the Proxmox host and by `zfs diff`; and the
     value is recorded in `beets.md`, `PROJECT.md` and `CLAUDE.md`. Three corrections this criterion
     needs: (a) the `568:65534` census it quotes was **LXC 100's view, not the disk** — on disk it
     was `0:545`, `3000:545`, `568:545`, `100000:100000`, `100911:100911` and `568:568`;
     (b) "13 artist folders" understates the work by two orders of magnitude — 2,674 entries needed
     it; (c) **`chown` cannot be run from LXC 100 at all**, only from the Proxmox host.
     **Not met and not part of this criterion:** D-12's `0755`/`0644`. Every entry is `0777` and
     stays so — `chmod` fails `EPERM` on `tank` even as real root under `aclmode=restricted` +
     `aclinherit=passthrough`. Phase 2's export must therefore be **read-only**.

  6. A **re-runnable** before-state tag snapshot exists covering every file that is a candidate for
     import — not just the DJ content that SAFE-03 covers. It records the full tag set per file
     keyed by a stable identifier, is stored where no tagger can write it, and a trial diff of the
     snapshot against itself returns zero differences, proving the comparison mechanism works before
     it is trusted to prove anything. This is QUAL-01, and it must exist *now*: once content has
     been staged or imported, the before-state can no longer be recovered, and Phase 7's diff has
     nothing to compare against.
     **✅ TRUE as of 01-04** (01-03 tooling + 01-04 capture): 9,736 records over 182.67 GB, zero
     failures, keyed on `audio_md5` (the encoded bitstream, so a rename cannot break the join);
     recorded self-diff exits 0 across 8,672 matched keys with all five difference categories at
     zero, paired with 01-03's mutated-copy negative control which exits 1 with exactly the right
     rows.
**Plans**: 9 (01-01 … 01-09), sequential — audit script, fence, snapshot tooling, the QUAL-01
capture, mount narrowing, Lidarr + Jellyfin freeze, beets config vendoring, ownership normalisation,
and the repo record + phase closure
**Research**: not needed — every item is a documented config change or a standard ZFS/rsync/ffprobe
operation.

### Phase 2: NFS Export and Music Assistant Reachability

**Goal**: Music Assistant reads the same tagged tree as Jellyfin, over a read-only export, and its
view survives a NUC reboot — proven on three already-correct albums before any content flows,
because Music Assistant never purges stale entries and re-doing this after a bulk import ends at a
full library database reset.
**Depends on**: Nothing to start — the Terraform export has no dependencies and runs in parallel
with Phase 1. The export's `anonuid`/`anongid` take the ownership value decided in Phase 1
(WRIT-04). Must complete before Phase 7.
**Requirements**: CONS-01, CONS-02, CONS-03
**Success Criteria** (what must be TRUE):

  1. An NFSv4 export of the Music dataset is served from the Proxmox host (not from LXC 100 —
     unprivileged, nfsd is privileged-only), defined in `infra/` Terraform, and a re-apply is clean.
     From the NUC the export is visible; on the host it shows `ro` and restricted to the NUC's IP.

  2. A write attempt from the NUC against the mounted path fails — read-only is enforced at the
     export layer, not by configuration politeness.

  3. Three already-correct albums appear in Music Assistant **under the correct album artist**
     within one sync cycle. "Files are visible" is not the gate; MA hard-requires `albumartist`.

  4. After a NUC reboot with no manual intervention, those three albums are still present — the
     mount-timing race does not show up on a first sync, only on a restart.

  5. The winning mount route is recorded as a Key Decision in PROJECT.md, with the losing route's
     failure symptom noted, and PROJECT.md's current assertion (that HA's storage configuration is
     the route) corrected either way.**Plans**: 9 plans in 8 waves
**Wave 1**

- [x] 02-01-PLAN.md — Stage 0 preconditions: atlantis probes, the Terraform drift gate, and the NUC/MA measurements (wave 1, blocking checkpoint)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-02-PLAN.md — Author `infra/nfs-music-export.tf`: the export line, guarded server install, M1 `mountpoint` and M2 ordering drop-in (wave 2)
- [x] 02-04-PLAN.md — Credentials, the three pre-verified proof albums, and `scripts/check-music-consumers.sh` (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 02-03-PLAN.md — Apply, prove criterion 1a/1b/1c, prove M1 by simulated unmount, and measure the blast radius (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 02-05-PLAN.md — Mount on the NUC, decide Route A vs B, prove criterion 2 at the export layer, prove bytes arrive (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 02-06-PLAN.md — Create the MA provider with `content_type: music` and `folder_name`; pin its instance id (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 02-07-PLAN.md — Criterion 3's exact-match assertion, prove the `folder_name` fallback fires, tear down the control (wave 6)

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 02-08-PLAN.md — M4 + `MOUNT_FAILED` alert, criterion 4a positive reboot, criterion 4b negative control (wave 7, blocking checkpoints)

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 02-09-PLAN.md — Fold into `quick-health-check.sh`, record criterion 5 in PROJECT.md/beets.md/NETWORK.md, closure verdict (wave 8, blocking checkpoint)

**Research**: `--research-phase` — the HAOS `/media` mount versus MA's own remote-share provider is
genuinely unresolved between primary sources (Supervisor source says one thing, MA's own docs say
verbatim that a folder cannot be mounted from HA into `/media`), and the mount-timing race is
documented only in a community discussion. The plan needs the empirical protocol written in, with
route B pre-specified so a FAIL does not stall the phase, and the server given as an IP
(`172.16.1.158`) because HAOS has no guaranteed resolver.

### Phase 02.1: Jellyfin transcode retention — relocate the anonymous transcode volume off / and set a retention policy (INSERTED)

**Goal**: LXC 100's root filesystem is structurally unable to be filled by Jellyfin again. Every
cache byte Jellyfin writes lands on a *declared* bind mount to `/mnt/fast`, growth is capped by a ZFS
property that no UI edit and no container recreate can raise, Jellyfin's own retention levers are on
and proven to *fire* rather than proven to be set, and a standing fail-closed check would have caught
the incident before `/` reached zero. The unreferenced Docker images are reclaimed through the
existing approval gate in the same pass, and the estate's own amdgpu recovery script is hardened so
it cannot silently undo any of it.
**Depends on**: Phase 2 (nothing technical — this is an insertion ordered after the last completed
phase). Phase 3 is halted behind it.
**Requirements**: TRAN-01, TRAN-02, TRAN-03, TRAN-04, TRAN-05, TRAN-06, TRAN-07, TRAN-08, TRAN-09
**Success Criteria** (what must be TRUE):

  1. `docker inspect jellyfin` returns **zero** mounts of `Type: volume`, `/cache` is a bind to
     `/mnt/fast/appdata/media/jellyfin/cache`, `/cache/transcodes` is a bind to
     `/mnt/fast/transcode`, and the `/dev/shm:/data/transcode` mount is gone from both the file and
     the running container. The invariant is asserted, not the id — a *new* anonymous volume must
     fail this too (D-18).

  2. The 392 MB of image and xmltv cache arrived intact — file count and byte total match the
     pre-copy census — and the anonymous volume `d98b2ff9…` no longer exists, deleted **after**
     Jellyfin was proven running on the new path, never before.

  3. `fast/transcode` carries `quota=50G`, `compression=off`, `sync=disabled`, `recordsize=1M`,
     declared in `infra/` Terraform, applied from a **saved plan** that was mechanically asserted to
     contain exactly one change and **zero destroys**, with a clean `terraform plan
     -detailed-exitcode` both before and after.

  4. **The bound is proven to fire, not proven to be set.** A real transcode writes segments under
     `/mnt/fast/transcode` while **nothing** appears in the old volume; the segment set is observed
     to stop growing and then shrink rather than growing monotonically; and a deliberate write past
     the quota is refused with `ENOSPC` while `/`'s free space does not move. Reading the settings
     back from the API is explicitly **not** evidence for any of these (CONS-04).

  5. `EnableSegmentDeletion`, `EnableThrottling` and `TranscodingTempPath` are set via the REST API
     and explained in `jellyfin.yaml`'s comment block — and the same write is proven **not** to have
     disturbed `HardwareAccelerationType: none` / `EnableHardwareEncoding: false`, the amdgpu
     mitigation applied 2026-08-31. A full `jq -S` diff of the encoding object before and after shows
     exactly the intended lines and nothing else.

  6. A new standalone `scripts/check-jellyfin-transcode.sh` asserts `/` headroom against a 20 GiB
     floor, zero `Type: volume` mounts, the transcode quota, and that **the five encoding values
     have not DRIFTED** from the expectations recorded in the script — each compared against a
     named `EXPECT_*` constant, each incrementing `FAILURES` on mismatch, and each **proven able to
     fail per-field** by an executed control that drove it red while the other four stayed green.
     Not-drifted is explicitly **not** a claim that a setting FIRES: a standing check cannot start
     a transcode, and **criterion 4 above is the sole firing proof** (CONS-04). The check **fails
     closed** on an unreachable LXC 100, an unreachable atlantis or a stopped Jellyfin — proven by
     executed negative controls, not asserted — and it is folded into `quick-health-check.sh` with a
     third in-band "EXIT-CODE BEHAVIOUR CHANGED" notice, with the transcode target and the
     assertion tally legible on the **green** path. That the check stays **manual** is recorded
     as a known limit, not an assumed capability.

     > **Amended 2026-09-03 by plan 02.1-11 (gap closure, CR-01).** This criterion previously read
     > "…the transcode quota and the five encoding values", which was false as implemented: the five
     > values were printed through `info()`, so `FAILURES` never incremented on drift and the check
     > printed its green tick regardless, while `quick-health-check.sh`'s selector omitted them
     > entirely. The **substance is kept, not reduced** — all five are now genuinely asserted rather
     > than two, and the verification report's alternative (assert two, reword "five" down to "two")
     > was **rejected**: comparing `SegmentKeepSeconds` to `300` is the same class of operation as
     > comparing `TranscodingTempPath` to `/cache/transcodes`, and `SegmentKeepSeconds` drifting to
     > `86400` is a plausible UI edit that silently deletes this phase's retention policy. What
     > changed in the wording is the ambiguity the verifier flagged: **drift detection is now stated
     > as drift detection**, and criterion 4 is named as the firing proof it always was.

  7. `renovate.json5` carries a `jellyfin/jellyfin` rule making minor updates manual-review while
     preserving patch automerge, placed after `packageRules[2]` so it wins; no `allowedVersions`
     ceiling; and `scripts/check-renovate.sh` runs to completion against `renovate.json5` instead of
     exiting 1 at line 22.

  8. `/` free space is measured before and after, and the image reclaim ran through
     `scripts/spike03-image-headroom.sh`'s two-process gate with `FLOOR_GB=20` — the list written,
     read by the operator, and pruned by ID from the file. `docker image prune -a` and
     `docker system prune` appear nowhere, asserted by a comment-stripped grep. Success is
     **whatever the auditable diff yields**, not a headline GB figure: 03-01 removed 27 images for a
     real 18 GiB while `docker system df` reclaimable *rose*, so a short approved list reads as the
     method working, not as a shortfall.

  9. `scripts/disable-jellyfin-hwaccel.sh enable` can no longer silently revert `TranscodingTempPath`,
     `EnableSegmentDeletion` or `EnableThrottling` — its `do_enable` restores the **whole**
     `encoding.xml` from a `.bak` predating this phase, which is a one-command undo of everything
     this phase installs. Proven **both** positively — a `check` → `disable` → `enable` round trip
     against a throwaway `encoding.xml` leaves all three retention values intact — **and**
     negatively, by a fault-injected run that genuinely fails, so the guard is shown to be capable of
     failing rather than merely observed passing (TRAN-09, ruled in scope as D-29/D-30).
**Plans**: 14 plans in 12 waves (10 original, plus 4 gap-closure plans added 2026-09-03 after `/gsd-verify-work` returned `gaps_found`)

*Wave order set by **D-31** (operator ruling, 2026-09-02, after cross-AI plan review). The cutover is
the critical path: `/` is structurally protected at the end of **wave 6** rather than sitting behind a
blocking human gate for the whole phase. **D-28 (the image reclaim) and D-29 (the hwaccel hardening)
are unchanged in scope — only their position moved.** Two ordering constraints are resolved
explicitly: the TRAN-01…09 requirement IDs are landed by 02.1-01 before any plan cites them, and
02.1-09 depends on 02.1-07 so the reap cannot delete the utility image that plan's sandboxed proof
needs.*

*Renumbered 8 waves → 9 in **cross-AI review round 2** (Codex, 2026-09-02), when `02.1-02`'s real
dependency on `02.1-01` was encoded as a `depends_on` edge and every later wave cascaded +1. D-31's
substance is unchanged — the cutover is still the critical path; only the descriptive wave **number**
moved, because the number is a consequence of that decision rather than the decision itself.*

**Wave 1** *(no dependencies)*

- [x] 02.1-01-PLAN.md — Land TRAN-01…09 in REQUIREMENTS/ROADMAP, capture the anonymous volume id, open the D-32 passive `/` watch (wave 1)

**Wave 2** *(blocked on 02.1-01 — it appends to the D-32 watch artifact 02.1-01 creates)*

- [x] 02.1-02-PLAN.md — Write `scripts/check-jellyfin-transcode.sh`, push to the host, record the `--baseline` before-state (wave 2)

**Wave 3** *(blocked on 02.1-02)*

- [x] 02.1-03-PLAN.md — Declare `fast/transcode` in Terraform and set `quota=50G`, applied from a saved plan asserted to have zero destroys (wave 3)

**Wave 4** *(blocked on 02.1-03)*

- [x] 02.1-04-PLAN.md — Copy the 392 MB cache, edit `jellyfin.yaml`, deliver to the host (wave 4)

**Wave 5** *(blocked on 02.1-04)*

- [x] 02.1-05-PLAN.md — Recreate the container, prove the mount shape, apply the five encoding settings by read-modify-write (wave 5)

**Wave 6** *(blocked on 02.1-05)* — **`/` is structurally protected from the end of this wave**

- [x] 02.1-06-PLAN.md — Prove the bounds fire with a driven HLS client, delete the anonymous volume, prove ENOSPC via a temporary quota shrink (wave 6)

**Wave 7** *(blocked on 02.1-06)*

- [x] 02.1-07-PLAN.md — Harden `disable-jellyfin-hwaccel.sh` so `enable` cannot silently revert the retention settings, with two real fault-injection paths (wave 7)
- [x] 02.1-08-PLAN.md — Add the `jellyfin/jellyfin` Renovate rule and repair `check-renovate.sh`, running its 148 never-executed lines for the first time (wave 7)

**Wave 8** *(blocked on 02.1-07, so the reap cannot delete the image 02.1-07's proof needs)*

- [x] 02.1-09-PLAN.md — Reclaim unreferenced Docker images through the existing approval gate (wave 8, **blocking human gate — operator approved all 4 rows unchanged; 1.45 GiB reclaimed**)

**Wave 9** *(blocked on 02.1-06 and 02.1-09)*

- [x] 02.1-10-PLAN.md — Execute the fail-closed negative controls, fold into `quick-health-check.sh`, record the known limits (wave 9, **TRAN-05; six proofs executed, every restore hash-verified, both UNKNOWN branches DRIVEN**)

---

**GAP CLOSURE — plans 02.1-11 … 02.1-14, added 2026-09-03.**

`.planning/phases/02.1-.../02.1-VERIFICATION.md` returned **`gaps_found`, 8/10 must-haves**. Two gaps,
both raised by the phase's own code review (`02.1-REVIEW.md`) and then independently re-confirmed live
by the verifier — both in the **observability layer**, neither touching the mount/quota mechanism,
which was re-verified sound in every particular:

- **Gap 1 (CR-01)** — Success Criterion 6 below is false as implemented. The standing check *reports*
  the five encoding values through `info()`; `FAILURES` never increments on drift, and
  `quick-health-check.sh`'s selector does not display them on the green path. `TranscodingTempPath`
  could drift to Jellyfin's own default `/config/transcodes`, moving the cache off the quota'd
  dataset, while every instrument stayed green.

- **Gap 2 (CR-02)** — the claim *"Jellyfin publishes NO host port … reachable only from a host that
  can route to its t3_proxy address"*, carried by both check scripts and used as the last
  compensating control in `PROJECT.md`'s residual-risk acceptance for the administrator-equivalent
  API key this phase widened to **write**, is false: the container holds the LAN macvlan address
  `172.16.1.76` and answers on `:8096` from the whole `172.16.1.0/24`.

One human-verification item is also carried forward: `02.1-VALIDATION.md`'s manual playback row was
**not** closed — the single recorded session direct-played (zero segments, zero ffmpeg).

*Plans 11 → 12 → 13 are strictly sequential because they modify the same two scripts; 14 is
independent and can run alongside 11.*

**Wave 10** *(no dependencies — 02.1-11 and 02.1-14 touch disjoint files)*

- [x] 02.1-11-PLAN.md — **Gap 1:** assert all five encoding values fail-closed with env-overridable expectations, drive five per-field negative controls, surface the drift on `quick-health-check.sh`'s green path, and align ROADMAP SC6 / REQUIREMENTS TRAN-05 with the code (wave 10, TRAN-05)
- [x] 02.1-14-PLAN.md — Close the outstanding manual playback row: one remuxed and one re-encoded title watched through the new binds, each pinned to its codec path by a live ffmpeg capture, with a seek-back past 300 s (wave 10, **blocking human gate**, TRAN-01/TRAN-04)

**Wave 11** *(blocked on 02.1-11 — same two scripts)*

- [x] 02.1-12-PLAN.md — **Gap 2:** measure the true reachability from three vantage points, correct the false claim in both scripts with the right mechanism (macvlan, not docker-proxy), and re-derive `PROJECT.md`'s residual-risk acceptance (wave 11, TRAN-05)

**Wave 12** *(blocked on 02.1-12 — same script)*

- [x] 02.1-13-PLAN.md — Bound every remote command in `quick-health-check.sh` with a Linux-side `timeout` and drive the bound against a real hang, so the gap-1 assertion cannot be defeated by a check that never returns (wave 12, TRAN-05)

*Excluded from this closure set, with the reason on the record:* `scripts/check-renovate.sh`'s five
`grep -v '^$'` `pipefail` aborts (lines 90, 100, 115, 138, 157 — **157 is inverted: it aborts when
ZERO Renovate PRs are pending, i.e. exactly when the estate is healthy**). It is not one of the two
verified gaps, TRAN-06 was verified SATISFIED on a live exit-0 run, and folding an unrelated repair
into a `--gaps-only` execution is how a closure pass becomes a second phase. Recorded in `STATE.md`
and `artifacts/02.1-10-negative-controls.txt`; close it with `/gsd-quick`, or carry it into Phase 4
alongside the wrtag Renovate pin.

---

**Research**: `--research-phase` — done. `02.1-RESEARCH.md` carries the Jellyfin 10.11.11 retention
internals read from source at the running tag (the segment cleaner's 20 s tick and `max(keep,20)`
clamp, the throttler's `max(delay,60)` clamp and its `IsPkeyPauseSupported` gate, the `-readrate 10`
side effect of segment deletion on stream-copy, and `DeleteTranscodeFileTask`'s ≤48 h orphan window),
the verified full-object semantics of `POST /System/Configuration/encoding` and the two live values a
partial POST would clobber, moby's destination-depth mount sort, the `quota`/`refquota` errno split
(`ENOSPC` vs `EDQUOT`) read from OpenZFS source, and the measured 17.93 Mbit/s that sizes the two
discretion values. Then **cross-AI reviewed in two rounds** (`02.1-REVIEWS.md`); round 2 was the
first genuinely non-Anthropic review and raised four HIGH findings, three verified real.

### Phase 3: Tagger Spike

**Goal**: One tagger *and* the interface the operator will actually meet it through are chosen from
measurements taken on this library's own content, against overturning thresholds committed to
before the evidence is collected — the spike produces a number, it does not relitigate a direction
that four independent lines of evidence already agree on.
**Depends on**: Phase 1 (the harness protects the sample files the spike probes and normalises)
**Requirements**: TAGR-01, TAGR-02, TAGR-06
**Success Criteria** (what must be TRUE):

  1. A Discogs match rate is recorded over ~20 DJ folders that were **normalised first**, with the
     un-normalised number recorded beside it. beets builds its Discogs query from existing
     `artist` + `album` tags; with `album="VA"` that query is useless, so a rate measured on raw
     tags under-reports and could wrongly disqualify the winner.

  2. Twenty folder imports are timed with `discogs` enabled and extrapolated against the 60 req/min
     authenticated ceiling into a stated hours-for-the-backlog figure.

  3. The wrtag disqualifier is run and its outcome recorded either way — container logs plus one
     `wrtag move -dry-run` on a throwaway album, showing whether the path format renders at all.
     The tool's 0.x version number and the current container's brokenness are explicitly
     non-evidence; the pin is inverted and fixable in one line.

  4. The recorded decision names one tagger and states concretely what happens to Mastermix / DMC /
     Music Factory content under it. A tagger whose answer is "that content lives outside the tool"
     has failed the requirement that matters most here — the single writer must be able to own the
     whole tree.

  5. The pre-committed overturning thresholds are written into the plan before evidence collection
     (Discogs matching under ~40% of `dj-mixes` after normalisation; rate limiting making bulk
     impractical; an honest self-assessment that the interactive prompt will not be sat at), and
     the decision record states which were tested and what each returned.

  6. **The decision is recorded along two separate axes, scored independently.** Axis one is the
     *engine* — beets versus wrtag. Axis two is the *front end* — a raw terminal prompt versus a
     reviewable queue with persisted decisions. These are not the same question, and the second may
     matter more to whether this project finishes than the first: the operator's first-hand
     experience is that beets has been painful to get working, and a painful tool is the documented
     cause of three prior abandonments. A decision record that answers only axis one has not met
     TAGR-06.

  7. **beets-flask is evaluated by name on axis two**, not dismissed and not assumed. It is the
     candidate the research already identifies as implementing the architecture this roadmap needs
     — one shared `library.db` across N policy-carrying inbox folders, which is exactly the Phase 5
     structure — with a web UI where automation proposes a candidate and the human ratifies it
     later, which is the direct counter to the abandonment mode. Known frictions are recorded as
     part of the evaluation rather than discovered in Phase 7: 1.0 removed the interactive terminal
     import in favour of UI candidate selection (pasting a MusicBrainz release ID by hand happens in
     the built-in web terminal), inbox entries must be directories and loose files never trigger,
     and music paths must match inside and outside the container.

  8. The record includes an honest ergonomics verdict in the operator's own terms — whether the
     chosen combination is one that will still be used in week six. "It works" is not the finding;
     "it works and I will still open it" is.
**Plans**: 11 plans in 8 waves

**Wave 1**

- [x] 03-01-PLAN.md — Disk-headroom gate on LXC 100: inventory, operator-approved prune, ≥ 8 GB floor, four pinned image pulls (wave 1, blocking checkpoint; OD-1 gates the whole phase)
- [x] 03-02-PLAN.md — Commit T1/T2/T3, the backlog-weighted estimator, the corrected 143-folder denominator, the OD-2 version split and the OD-3 widening, plus the empty ergonomics scoring sheet — all before any evidence exists, then **pushed to `origin`** so criterion 5's custody is a remote commit rather than local history (wave 1, no dependencies — writes only Markdown)

**Wave 2** *(blocked on Wave 1)*

- [x] 03-03-PLAN.md — Variant survey over the Phase 1 ffprobe fence extended to the whole 143-folder backlog for per-stratum prevalence, the deterministic widened de-duplicated 24-folder draw across `dj-mixes` ∪ `unsorted`, and the reflinked scratch tree behind `@spike-03-t0` (wave 2 — depends on 03-02, so the sample can never be drawn before the thresholds that govern it)

**Wave 3** *(blocked on Wave 2)*

- [x] 03-04-PLAN.md — Throwaway beets 2.13.1 spike container, spike config with `musicbrainz` explicit, both plugins proven loaded, Music unreachable (wave 3)
- [x] 03-08-PLAN.md — Criterion 3: wrtag at v0.20.0 / v0.33.0 / v0.34.0 on single-disc and multi-disc, with the corrected pin-inversion proof (wave 3)

**Wave 4** *(blocked on Wave 3)*

- [x] 03-05-PLAN.md — `scripts/normalise-dj-tags.py`, dry-run by default, the three measured rules (OD-4), applied on copies with a field-loss gate (wave 4)
- [x] 03-06-PLAN.md — `scripts/spike03-discogs-probe.py`, the `tag_album()` NDJSON emitter, and its A1 smoke gate on a known-good album (wave 4)

**Wave 5** *(blocked on Wave 4)*

- [x] 03-07-PLAN.md — Criteria 1 and 2: the four-cell probe matrix at both `index_tracks` settings, timing and requests, T1 and T2 resolved (wave 5)

**Wave 6** *(blocked on Wave 5)*

- [x] 03-09-PLAN.md — D-13: wrtag `metadata` versus the mutagen script, same folders, same before-state, same scoring instrument (wave 6)

**Wave 7** *(blocked on Wave 6)*

- [x] 03-10-PLAN.md — beets-flask v2.0.0-rc6 evaluated by name, and the operator's timed five-album ergonomics trial (wave 7, blocking checkpoints)

**Wave 8** *(blocked on Wave 7)*

- [x] 03-11-PLAN.md — The two-axis decision record, criterion 4's concrete answer, teardown and closure (wave 8, blocking checkpoint)

**Research**: `--research-phase` — the spike is itself research, and without a defined evidence
protocol with pre-committed thresholds it drifts into tool advocacy. The normalisation pre-step is
easy to omit and omitting it invalidates the result. The ergonomics axis needs a defined way to be
scored rather than asserted, or it collapses back into a footnote.

### Phase 4: Collapse to One Tagger

**Goal**: The estate ends up with one tagger, one database, and no idle container holding a
read-write mount on the library. **This phase must be independently shippable.** This project has
been abandoned three times; if attempt four stalls here, the estate must still be strictly better
than it started, so attempt five does not inherit attempt four's wreckage.
**Depends on**: Phase 3 (cannot retire the survivor)
**Requirements**: TAGR-03, TAGR-04, TAGR-05
**Success Criteria** (what must be TRUE):

  1. Exactly one tagger definition exists in the repo. The losing definitions are deleted, not
     commented out, and soulbeet is gone with issue #306 closed.

  2. Renovate no longer pins a retired tagger — including the wrtag `<0.30.0` rule that is
     enforcing the broken state and was added on a misdiagnosis — and
     `renovate-config-validator` passes, since a config error silently stops the whole repo run.

  3. The beets block is stripped from `audio.bash`, and a SABnzbd music job completes without
     invoking any tagger at all.

  4. Every remaining beets config declares `musicbrainz` in its `plugins:` list, and a `--pretend`
     run on one known-good album returns a MusicBrainz candidate instead of skipping. This is the
     confirmed cause of the 1 Aug and 8 Aug ingest skips: since beets 2.4.0 MusicBrainz is a
     plugin, and `/config/scripts/beets-config.yaml` declares `embedart` and nothing else.

     > **Amended 2026-09-11 by plan 04-04 (D-20).** The second clause reads "…a `--pretend` run on
     > one known-good album returns a MusicBrainz candidate instead of skipping", and it is
     > **unsatisfiable as written**. In beets v2.13.1, `beets/importer/session.py`
     > `ImportSession.run()` appends only `stagefuncs.log_files` to the pipeline when `pretend` is
     > set; `stagefuncs.lookup_candidates` is appended only on the non-pretend branch. Under
     > `--pretend` it is therefore never called, no metadata-source request is issued, and zero
     > candidates are returned **by construction**, whatever the config declares (excerpt:
     > `03-DECISION.md` § *Handoff to Phase 4*). The substitute instrument is a **pair**, and both
     > runs pass an explicit throwaway `-l <db>` because `beet` is not read-only (D-16). (1) The
     > `tag_album()` probe, `scripts/spike03-discogs-probe.py --mb-only`, runs **inside the survivor
     > container** on its `manual` profile (D-19). The `--mb-only` mode is added by plan 04-08 and
     > never loads the dismissed Discogs credential (D-24). The album is
     > `Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost` (D-29), which replaces D-18's album because
     > that album is gone from the downloads tree; Scarecrow's presence is re-asserted at execution.
     > The probe runs first against the **live** `plugins: embedart` config, where it must return
     > **zero** MusicBrainz candidates (the D-17 negative control). It then runs against the fixed
     > config, with the same album, the same throwaway `-l` and only the `plugins:` line differing,
     > where it must return **≥ 1**. (2) One agent-driven `beet import -t -W -C` runs on the same
     > album, is read by hand, and is aborted at the candidate prompt, as the cross-check. The
     > **substance is kept, not reduced**. The probe asserts exactly what the original clause wanted:
     > a MusicBrainz candidate where the broken config produced none. The negative control also
     > turns the stated cause of the 1 Aug and 8 Aug skips from an inference into a measurement,
     > which the original clause never demanded. The first clause ("every remaining beets config
     > declares `musicbrainz`") is unchanged; REQUIREMENTS TAGR-05's addendum clarifies its scope.

  5. Taken alone, this phase leaves the estate strictly better: one tagger, one `library.db`, zero
     read-write library mounts on non-tagger containers — checked and stated as an outcome, not
     assumed from the diff.

     > **Amended 2026-09-11 by plan 04-04 (F10).** The rw counter above is stated, and will be
     > reported, as "0 excluding the documented D-21 consumer exception". That exception is
     > Phase 1's D-21: Jellyfin keeps `/mnt/tank/media → /media:rw` as the consumer-class holder,
     > frozen at the application layer. `docker inspect` across every container in every state (97)
     > on 2026-09-11 found Jellyfin to be the **only** read-write holder over the library. It is
     > printed on its **own line**, beside the counter and never folded into it. This is the WRIT-01
     > shape: a bare "0" cannot read as a pass, and Jellyfin's presence is not a gap. The
     > criterion's substance is unchanged.
**Plans**: 19 plans in 14 waves — 13 executed, then 3 gap-closure plans added 2026-09-13 and 3 more
added 2026-09-15, all to close criterion 3 / TAGR-04's behavioural half, which `04-VERIFICATION.md`
recorded OPEN at 4/5 criteria across **two** observation windows and **five** real music jobs.
Criteria 1, 2, 4 and 5 are verified and are **not** re-planned; the estate is not re-planned either.
The gap is in the measuring instrument (`04-D12-EVIDENCE.md` § 6, lines 186-207; § 7's closing
section records both previously-tried capture points as measured exhausted). Plans 04-17/18/19 are
the **third capture design** — SABnzbd's own `pp` notification hook (`postproc.py:453`, structurally
before repair, unpack, the move and `audio.bash`), category-filtered to music, with `direct_unpack`
untouched at 1 — split so that **restoring the estate is the terminal act of 04-18** rather than a
step behind a human checkpoint: `quick-health-check.sh` carries no `nscript_*` guard, so an armed
estate is invisible to the standing checks and an unanswered prompt must not be able to strand it.
The set carries a pre-committed exit: on a non-PASS, 04-19 prepares — explicitly unsigned, with
unfilled `accepted_by`/`accepted_at` placeholders — the criterion-3 override that
`04-VERIFICATION.md` already drafts, and puts the decision to the operator.
Plans:
**Wave 1**

- [x] 04-01-PLAN.md — Fence gaps (wrtag.db D-35, beets.log) + measured baseline incl. the routine health-check state + D-12 evidence checklist (pre-hook byte test)
- [x] 04-02-PLAN.md — normalise-dj-tags.py WAV write path + three-case --self-test (D-23)
- [x] 04-03-PLAN.md — Delete wrtag/soulbeet definitions, survivor to 2.13.1-ls349, two-rule beets Renovate policy, check-renovate.sh repairs (validator-gated; legitimacy checkpoint)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 04-04-PLAN.md — D-20 criterion 4/5 + TAGR-05 amendments, D-24 dismissal, CLAUDE.md/STACK.md corrections
- [x] 04-05-PLAN.md — beets.md D-14 verbatim correction + D-24 amendment, .gitignore, spike03-wrtag-arms.sh keep note, interim sweep
- [x] 04-06-PLAN.md — Behaviour-based tagger census in check-music-freeze.sh as a CANDIDATE check (red-first on real state + fixtures; routine path unchanged until 04-11 promotes it)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 04-07-PLAN.md — Fence-gated host teardown (wrtag, soulbeet, old survivor DBs), image + reap exemption, wrtag DNS record, close #306
- [x] 04-08-PLAN.md — Probe --mb-only mode (discogs refusal driven) + vendored survivor config (D-27) and :ro mount

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 04-09-PLAN.md — Survivor stand-up in one trap-guarded lifecycle: fresh library.db (D-28), criterion-4 probe with D-17 negative control, guaranteed return to dormant

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 04-10-PLAN.md — Vendor audio.bash (strip line 285), :ro mounts, beets-config declares musicbrainz, vendored-file drift block as a CANDIDATE check

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 04-11-PLAN.md — Install + sabnzbd recreate with boot proof, ledger-gated delete of sabnzbd beets state, promote census + drift into the routine check (all guards green)

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 04-12-PLAN.md — D-12 real music job end to end with a pre-hook byte comparison (human checkpoint; OPEN if no job)

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 04-13-PLAN.md — D-25 closure (PASS) or interim status (OPEN/FAIL) in beets.md from an executed census, final sweep, Renovate observation

**Wave 9** *(gap closure, added 2026-09-13 — criterion 3 / TAGR-04 behavioural half)*

- [x] 04-14-PLAN.md — Rebuild the D-12 watcher to snapshot under `downloads/incomplete` (structurally pre-hook), drive it to PASS/FAIL/UNPROVEN on synthetic fixtures, amend the evidence contract before the window opens

**Wave 10** *(blocked on Wave 9 completion)*

- [ ] 04-15-PLAN.md — Observation window 2: one real music job with a valid PRE-HOOK byte comparison; section 7 verdict PASS, FAIL or OPEN (human checkpoint; OPEN if no job arrives)

**Wave 11** *(blocked on Wave 10 completion)*

- [ ] 04-16-PLAN.md — Record the window-2 verdict in beets.md, heading selected by the verdict line: closure only on PASS

**Wave 12** *(gap closure, added 2026-09-15 — criterion 3 / TAGR-04 behavioural half, third capture design)*

- [ ] 04-17-PLAN.md — Contract + instrument, arming nothing: amend the D-12 contract for the nscript capture design and **redesign the ladder for a hook rather than transplanting the poller's** (`pre_complete` is pinned once the observer fires only once, so a same-relative-path sha256 change becomes the only FAIL path, completion-only audio is always UNPROVEN, and the non-vacuity floor counts MOVED pairs); build the hook and judge; drive **12 synthetic controls — 1 required FAIL and 6 distinct UNPROVEN tokens** — with the estate provably untouched

**Wave 13** *(blocked on Wave 12 completion)*

- [ ] 04-18-PLAN.md — Observation window 3 end to end: write and drive the named idempotent restore FIRST, arm behind a fail-closed gate with the wiring proven in situ by SABnzbd's own startup invocation, wait (human checkpoint, **self-closing at a 90-minute deadline via a detached watchdog**), judge the bytes, write § 8 with its OBS block and one line-anchored verdict, commit — then **restore the estate as the terminal act on every branch**

  **PLANNED BUT DELIBERATELY NOT EXECUTED (2026-09-16)** — window 3 was never armed: external review by four independent AI model families found roughly 30 defects in this plan, including a judge binary that self-reports every PASS condition, so a PASS from it would not have been trustworthy. Record: `04-18-EXTERNAL-REVIEWS.md`.

**Wave 14** *(blocked on Wave 13 completion)*

- [ ] 04-19-PLAN.md — Criterion 3's disposition: on PASS or FAIL write nothing; on OPEN prepare the override **UNSIGNED** in `04-VERIFICATION.md`'s frontmatter (every gate frontmatter-scoped, because the § Gaps Summary prose draft already matches `^overrides:` at column 1) and put the decision to the operator (blocking)

  **PLANNED BUT DELIBERATELY NOT EXECUTED (2026-09-16)** — superseded: its disposition step was performed directly by quick task 260916-062, which prepared the unsigned override without running window 3. Record: `04-18-EXTERNAL-REVIEWS.md`.

**Research**: done 2026-09-11 (`04-RESEARCH.md`). *Originally "not needed — retirement is deletion
plus documented config changes"; the operator chose to measure the live estate anyway, and it found
fifteen facts the decisions relied on that the estate does not support (F1–F15), ruled on as
D-27–D-35.*

### Phase 5: Inbox Structure and the Junk Gate

**Goal**: Content waits in a staging tree outside the library where the routing decision *is* a
directory name — inspectable with `ls`, revertible with `mv`, surviving a container restart with no
database — and the junk that would corrupt every later measurement is already out of the way.
**Depends on**: Phase 1 (Jellyfin's metadata savers must be off before anything is staged, and the
QUAL-01 before-state snapshot must already be taken — staging first destroys the baseline)
**Requirements**: INBX-01, INBX-02, INBX-03
**Success Criteria** (what must be TRUE):

  1. `_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}` exists under
     `tank/downloads` and nothing equivalent exists under `media/`. Moving a release folder between
     two of them is an atomic same-dataset rename, verified by unchanged inode rather than by
     watching it look fast.
     **✅ TRUE as of 05-01**, re-asserted from live state at close by **05-11**: six directories
     present; `_inbox` on the same devid as `unsorted/` and `dj-mixes/` with the library on a
     different one; **zero** ZFS datasets named `_inbox` (D-18); **zero** equivalents under
     `/mnt/tank/media` to depth 3; and the inode proof **driven again after the chown**, both
     controls — same-dataset `(70, 295296)` → `(70, 295296)`, cross-dataset → `(43, 128)`.
     Two corrections this criterion needs: (a) **ZFS devids are not stable** — the same two paths
     read 68/76, then 70/75, then 70/81 across three days, so the *property* is the assertion and
     the *number* never is; (b) `/mnt/tank/downloads`, `/mnt/tank/media/Music` and `/mnt/fast` all
     report **inode 34**, so the proof must compare the pair `(devid, inode)`, never the inode alone.

  2. Searching the download tree returns zero `_FAILED_`, `_UNPACK_` or stray `.rar` items outside
     `99-quarantine`, and the Harry Potter BluRay rip is out of `dj-mixes`.
     **✅ TRUE as of 05-04** *(against the amendment below, not the wording above)*, re-asserted at
     close by **05-11**: zero `_FAILED_`/`_UNPACK_` directories and zero `.rar`-form files across
     the five music paths outside `99-quarantine`, with the same `find` **without** the exclusion
     returning the two quarantined directories, so the instrument is not vacuous;
     `/mnt/tank/downloads/lidarr-import` **absent** — Phase 1's D-23 closed here rather than handed
     to Phase 8; the named Potter rip absent. The sweep was 52 candidates enumerated, **44 approved
     with two operator amendments — 40 removed, 4 moved to `99-quarantine`, 8 `.covers` directories
     struck untouched** — every removed and renamed path attributed to an approved row by `zfs diff`.
     ⚠ A re-run must assert the **named** rip path: `-iname '*potter*'` now matches a legitimate
     song moved into `Vol 066` by the 05-07 split.

     > **Amended 2026-09-18 by plan 05-02 (D-12, D-14).** This criterion previously read
     > "Searching the download tree returns zero `_FAILED_`, `_UNPACK_` or stray `.rar` items
     > outside `99-quarantine`, and the Harry Potter BluRay rip is out of `dj-mixes`" — and as
     > phrased it sweeps the **whole** download tree, which pulls two other services into a
     > music project. Measured (`05-PREMEASURE.md` § 5): ten `_FAILED_`/`_UNPACK_` directories
     > exist under `complete/nzb/`, of which only **four** are music — `_UNPACK_Ed Sheeran…`,
     > `_UNPACK_Katy Perry - Prism (2013) FLAC`, `_FAILED_Garth.Brooks-Ropin.The.Wind…` and
     > `_FAILED_Garth.Brooks-The.Ultimate.Hits…`. The other **six are TV and movies**:
     > `Chicago.PD.S13E02`, two `Goldie.and.Bear.S02E26E27` variants, two `Prep.and.Landing.2009`
     > variants, and `Disclosure.Day.2026`. **The change:** the sweep's scope narrows to the music
     > paths — `complete/nzb/music/`, `complete/nzb/unsorted/`, `complete/nzb/dj-mixes/`,
     > `/mnt/tank/downloads/lidarr-import/` and the new `complete/nzb/_inbox/`. `incomplete/` is
     > out of scope entirely (D-15): it is SABnzbd's live working directory, drained at roughly one
     > music job per 72 seconds, and moving or deleting anything under it can break an active
     > download. **The substance is kept, not reduced** — the six TV/movie items are **not lost**;
     > they are named above and in `05-PREMEASURE.md` § 5, and they belong to Sonarr's and Radarr's
     > own failure handling. The alternative was **rejected**: quarantining another service's failed
     > jobs into a music-project folder takes content this project does not own, and it would go red
     > again the moment those services fail anything — a permanently-red assertion being the one
     > outcome that trains a reader to ignore the whole check.
     > **D-14's factual correction is folded in here as a note rather than given an amendment of its
     > own:** the Potter clause **names the wrong tree** — a `find` over `dj-mixes` to depth 3 for
     > `*potter*` returns **zero** (`05-PREMEASURE.md` § 4) — and the rip that exists is
     > `complete/nzb/unsorted/Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE`,
     > which is ordinary junk (a video in a music folder) taken through D-13's approval gate with
     > everything else and deleted; refiling it to the movies tree was rejected because this phase
     > does not hand content to another service's import path uninvited, and the second rip,
     > `incomplete/Harry.Potter…hallowed` with its `__ADMIN__` directory, is SABnzbd's to resolve.

  3. The 45 GB `Now! 1-115` folder is split into per-volume folders, each independently importable
     and abortable, with the per-volume file counts summing back to the original count.
     **✅ TRUE as of 05-07** *(against the amendment below)*, with the tag deliverable that makes the
     split coherent landed by **05-09** and the whole re-asserted at close by **05-11** using an
     independent read-only `ffprobe` walk — neither the tool that split nor the tool that wrote the
     tags: **115** depth-1 directories named exactly `Vol 001`…`Vol 115`, **0** at depth 2, **4,746**
     mp3 summing to the freshly measured collection total, **0** mp3 left at the collection root,
     **0** ffprobe failures, and **0** volumes carrying anything other than exactly one `album`
     value (115 distinct strings across 115 folders). **Manifest-only entries: 0**, on its own line
     and never folded into any total (D-08) — the m3u's 24-line excess is *collision, not absence*.
     The `files == Σ modal tracktotal` exception set measured **11 rows** and matched the
     pre-declared post-merge list — volumes 3, 4, 8, 9, 15, 18, 39, 52, 70, 83, 98 — **11 for 11**.
     Read volumes 4/8/9's `+13/+9/+13` as *"a merged folder, expectation not meaningful"*: D-04's
     surplus is a **grouping artefact**, settled by the album tag, the manifest directories and the
     encoded bitstream (4,735 distinct `audio_md5` across 4,746 records, 9 of 11 duplicate groups
     inside `Vol 004`). Two figures the criterion's own wording understates: the split was **4,750
     renames**, and the album write touched **751 files across 22 volumes** — the other 3,995 were
     already canonical and were deliberately not rewritten.

     > **Amended 2026-09-18 by plan 05-02 (D-02, D-05, D-08).** This criterion previously read
     > "The 45 GB `Now! 1-115` folder is split into per-volume folders, each independently
     > importable and abortable, with the per-volume file counts summing back to the original
     > count", and two of its words describe a shape the folder does not have. Measured
     > (`05-PREMEASURE.md` § 3): the real folder
     > `complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023` holds **4,760 files and
     > ZERO subdirectories**, so the split cannot *move* existing subfolders — there are none, and
     > volume boundaries must be **derived**. The 4,760 resolves as **4,746 mp3 plus 14 sidecars**.
     > **The changes are all clarifications.** (1) The per-volume folders are **created, not moved**,
     > and are created **inside** the existing folder as atomic same-dataset renames (D-07). (2)
     > "the original count" is **4,746 mp3**; sidecars are accounted separately, and the 24
     > manifest-only entries in the m3u are reported **on their own line** and never folded into the
     > total (D-08). (3) The headline total is backed by the strictly stronger per-volume identity
     > **`files_present == sum of tracktotal` across that volume's discs**, because a bare total of
     > 4,746 would pass even if every file landed in the wrong folder. (4) **All discs of a volume
     > live in ONE folder** — the CD1/CD2 split is not restored, because beets treats one directory
     > as one album candidate and handing it two risks matching one volume as two albums (D-05).
     > **The substance is kept, not reduced** — the split is still the deliverable and the
     > reconciliation is *strengthened* rather than relaxed. Reconciling against the m3u manifest's
     > **4,770** entries was **rejected**: it would fail by 24 on every run and train everyone to
     > ignore it.

  4. No `_`-prefixed folder exists anywhere under `/mnt/tank/media/Music` — underscore names are
     fine in the staging tree because it is outside the library, and never inside it, because
     Music Assistant silently ignores them and Jellyfin does not.
     **✅ TRUE as of 05-02** — already green before the phase began; what 05-02 made true is that it
     is now **asserted** rather than claimed, as a fatal block in `scripts/quick-health-check.sh`
     with "could not look" kept distinct from "there are none". D-22's **before** half ran
     2026-09-18 with a **driven negative control** (a `_probe` created inside the library from
     atlantis as real root: check red with it, green without it, the probe independently tripping
     `check-music-freeze.sh`'s ownership assertion as a second instrument, `EXIT` trap confirming
     removal). The **after** half ran at close in **05-11**, verbatim from the block:
     `Library underscore-dir guard: ✅ No '_'-prefixed directories under /mnt/tank/media/Music`.
     ⚠ **Read the block's verdict line, never the script's exit code.** `quick-health-check.sh`
     exits **1** on a pre-existing, unrelated gate — `check-music-freeze.sh`'s
     `interpolated-host-path inventory MOVED: expected=12, found=13` — which is the only red line
     in the run, so the whole-script exit code is **non-discriminating** for this criterion.

     > **Amended 2026-09-18 by plan 05-02 (D-22, D-25).** The wording above **stands unchanged** and
     > is quoted here in full: "No `_`-prefixed folder exists anywhere under `/mnt/tank/media/Music`
     > — underscore names are fine in the staging tree because it is outside the library, and never
     > inside it, because Music Assistant silently ignores them and Jellyfin does not." Measured
     > (`05-PREMEASURE.md` § 6): **zero** underscore-prefixed directories exist anywhere under
     > `/mnt/tank/media/Music`. **The change is what kind of thing this criterion is:** it is a
     > **guard to maintain, not work to perform**. It becomes a standing assertion in
     > `scripts/quick-health-check.sh`, run before and after this phase's moves, and it is proven
     > **capable of failing** by a driven probe rather than merely observed passing — the README
     > § *Health Checks* rule, and the reason D-21's inode proof carries a negative control too.
     > **The substance is kept, not reduced** — nothing is dropped; an unasserted green *claim*
     > becomes an *asserted* one, with "could not look" kept distinct from "there are none".
     > **The adjacent temptation is named here because it is where the next reader will go (D-25):
     > no `tank/downloads` ownership assertion is added to the health check.** The download client
     > keeps writing as uid 3000 at roughly one job per 72 seconds, so such a check would go red on
     > the next download and train everyone to ignore it — the exact failure mode Phase 02.1's CR-01
     > spent four gap-closure plans repairing in the other direction. D-24's `568:568` sweep is a
     > one-time, `zfs diff`-verified measurement; its date is the deliverable, not a standing check.
**Plans**: 11 plans, **all 11 executed** (05-01 … 05-11), one wave at a time — every plan in this
phase touches the same filesystem paths. Executed list, each with the objective it delivered:

| Plan | Objective delivered |
|---|---|
| 05-01 | The `tank/downloads@pre-phase5` fence, the six `_inbox` directories, and the D-21 inode proof with its cross-dataset negative control |
| 05-02 | The dated in-band amendments to criteria 2, 3 and 4 plus the INBX addenda, and criterion 4 folded into `quick-health-check.sh` and driven red |
| 05-03 | `scripts/phase05-junk-sweep.sh` and the 52-row approvable candidate file |
| 05-04 | The sweep executed on the operator's 44 approved rows — 40 removed, 4 moved, 8 untouched — and `lidarr-import` retired |
| 05-05 | The durable `Now!` tag inventory under `/mnt/fast`, the per-volume reconciliation, and D-04's surplus answered |
| 05-06 | `scripts/phase05-now-split.sh` and the reviewable src→dst mapping with total-coverage assertions |
| 05-07 | The split applied: 4,750 renames into 115 flat `Vol NNN` folders, plus the QUAL-01 before-state capture |
| 05-08 | The narrow Phase 5 collection mode and rule 4 in `normalise-dj-tags.py`, self-tested and dry-run |
| 05-09 | The album write piloted on `Vol 036` and then applied — 751 files across 22 volumes, gated on the field-level diff |
| 05-10 | Fresh chown baselines and the operator-scoped 26,005-entry `chown` to `568:568`, `zfs diff`-verified |
| 05-11 | All four criteria re-asserted from live state, and the Phase 5 closure written into `stacks/selfhosted/arrs/beets.md` |

Plans:
**Wave 1**

- [x] 05-01-PLAN.md — snapshot fence `tank/downloads@pre-phase5`, create the six `_inbox` directories, drive the D-21 inode proof with its cross-dataset negative control
- [x] 05-02-PLAN.md — dated in-band amendments to criteria 2, 3 and 4 plus INBX addenda; fold the criterion-4 assertion into `quick-health-check.sh` and drive it red

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 05-03-PLAN.md — write `phase05-junk-sweep.sh` (enumerate + sweep) and produce the approvable candidate file

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 05-04-PLAN.md — operator approves; sweep moves to `99-quarantine` then deletes; retire `lidarr-import`

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 05-05-PLAN.md — regenerate the `Now!` tag inventory durably under `/mnt/fast`, reconcile per volume, answer D-04's surplus question

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 05-06-PLAN.md — write `phase05-now-split.sh` and produce the reviewable src-to-dst mapping with total-coverage assertions

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 05-07-PLAN.md — operator approves; apply the split into 115 flat `Vol NNN` folders; capture the QUAL-01 before-state

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 05-08-PLAN.md — add a narrow Phase 5 collection mode and rule 4 to `normalise-dj-tags.py`; self-test; dry run

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 05-09-PLAN.md — pilot the album write, gate on the field-level diff, then write the rest *(executed 2026-09-19 against an operator amendment: the pilot was `Vol 036`, not `Vol 077` — `Vol 077` has zero proposed changes, so its gate would have passed vacuously. 751 files in 22 volumes were written, not 4,746 across 115; the other 3,995 were already canonical and were deliberately not rewritten)*

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 05-10-PLAN.md — fresh chown baseline snapshots, tree-wide `chown` to `568:568` via a detached atlantis runner, `zfs diff` verification plus the library untouched-proof *(⚠ **"tree-wide" is what was planned, not what ran.** The operator narrowed D-24 on 2026-09-19 against the 05-10 survey: **26,005 entries** normalised, **196,371 excluded** — `dropbox/` 196,327 is a personal code and document archive rather than downloads, and `google takeout/` was being read by an active import. 26,005 + 196,371 = 222,376, the full measured foreign count, so nothing was quietly dropped. See the in-band amendment to D-24 in `05-CONTEXT.md` and `05-10-SUMMARY.md`.)*

**Wave 10** *(blocked on Wave 9 completion)*

- [x] 05-11-PLAN.md — re-assert all four criteria from live state and write the Phase 5 closure into `stacks/selfhosted/arrs/beets.md` *(executed 2026-09-19: all four criteria re-measured at close and all four TRUE, 0 FAIL; evidence `host:/mnt/fast/safety/phase05/phase05-final-assertions.txt`, committed copy `artifacts/05-11-final-assertions.txt`; closure written at `stacks/selfhosted/arrs/beets.md` § Phase 5)*

**Research**: not needed — filesystem triage with documented traps. `05-CONTEXT.md` (27 locked
decisions), `05-PREMEASURE.md` (measurements from atlantis, 2026-09-18) and `05-PATTERNS.md` (analog
map) carry what a RESEARCH.md would have. Nyquist dimension 8 is thin by accepted, recorded choice.
*Confirmed 2026-09-18 by plan 05-02: research was **deliberately skipped**, not overlooked. The
measurements the three amended criteria above rest on come from `05-PREMEASURE.md` (read-only, taken
from atlantis before the phase was discussed) and the rulings on them from `05-CONTEXT.md`; each
amendment cites its `05-PREMEASURE.md` section by number so the chain from criterion to measurement
is followable without a RESEARCH.md.*

### Phase 6: Tagger Configuration and Dry Run

**Goal**: The surviving tagger's configuration is shown to produce the intended tree on paper, at
the last cheap moment before a path-format error can be applied at scale.
**Depends on**: Phase 4 (config belongs to the survivor), Phase 5 (a clean sample to dry-run against)
**Requirements**: CONF-01, CONF-02, CONF-03, CONF-04, CONF-05, CONF-06
**Success Criteria** (what must be TRUE):

  1. Effective config shows imports copying rather than moving — there is no `beet undo`, and a bad
     bulk run over 97 GB with `move` set would consume its own source.

  2. Effective config shows `incremental: yes` **with** `incremental_skip_later: yes`. The first
     without the second is the sharpest trap in the set: the default records *skipped* directories
     as done, so one quiet pass permanently marks every hard album complete and the backlog becomes
     invisible rather than imported.

  3. A `--pretend` run on a bucket-A sample prints top-level folders equal to `ALBUMARTIST` exactly,
     case included — `Various Artists/` appears and `Compilations/` does not, because a
     capitalisation-only mismatch renders a duplicate artist page in Jellyfin.
     *Instrument corrected 2026-09-20 by plan 06-02 (D-33); the criterion text above is deliberately
     NOT rewritten. `beet import --pretend` CANNOT produce the intended tree — its pipeline is
     `read_tasks → log_files`, `lookup_candidates` never runs and no destination path is ever
     computed, so every line it prints is a SOURCE path and it exits 0 anyway. The destination-path
     oracle is **`beet move -p`**, which evaluates the full `paths:` stanza through
     `item.destination()`. `--pretend` is kept for what it genuinely proves — which folders are
     offered as tasks — which is why it still serves criterion 2. Measured TRUE 2026-09-21 by plan
     06-11: exit 0, zero-diff over 174 destinations against a fixture committed before the run.*

  4. A multi-artist track separated with `;` shows its artists parsed correctly in **both** Jellyfin
     and Music Assistant — the one delimiter both consumers handle.
     *Amended 2026-09-20 by plan 06-02 (D-34); the criterion text above is deliberately NOT
     rewritten. The WRITE side is the multi-valued **`ARTISTS`** tag, not `;` inside `ARTIST` —
     beets has no write-delimiter or join key at 2.12.0 or 2.13.1 and so cannot be configured to
     emit one; the `;` named above is a property of the existing twelve library files. Both
     consumers now read `ARTISTS` by construction. **OPEN at Phase 6 close on its JELLYFIN half
     only**, and recorded as two verdicts that are never summed: MA discharged 2026-09-21 (3/4,
     2/2, 2/2 on 2.11.0b2), Jellyfin still at baseline (0/4, 1/2, 1/2) because the option is
     probe-time and 0 of 1,244 rows have been re-probed. It discharges on Phase 7's first write.*
     *Amended again 2026-09-23/24 by gap-closure round 5 (plans **06-40 … 06-43**); the criterion
     text above and the 2026-09-20 D-34 amendment are both deliberately NOT rewritten. **The
     sentence "It discharges on Phase 7's first write" is SUPERSEDED** — named as superseded rather
     than deleted, because it was true when written and the decision that overtook it is what a
     reader needs to see. The operator chose neither of `06-VERIFICATION.md`'s two offered paths
     and instead drove the Jellyfin re-probe **inside Phase 6**: three file mtimes touched from
     atlantis as real root inside the ZFS snapshot fence
     `tank/media/Music@pre-06-41-conf04-reprobe` (plan **06-41**), then the same targeted
     Default-mode `POST /Library/Media/Updated` at file scope — one write verb for the whole round,
     HTTP 204 — and the measurement taken after a 19,597 s settle (plan **06-42**). **IT DID NOT
     WORK, and that is the recorded result.** All three pinned rows read AT-BASELINE:
     `Jewels n' Drugs` measured **0** against a target of **4** (2026-09-20 baseline 0);
     `California Gurls` measured **1** against a target of **2** (baseline 1);
     `Just Give Me a Reason` measured **1** against a target of **2** (baseline 1) — zero rows
     moved, `;`-in-entity-name count 0 on every row, and the 1,244-row census delta EMPTY. The
     computed branch is **`BRANCH: B` — the mtime hypothesis is DISPROVEN** for this estate at
     Jellyfin 10.11.11 (plan 06-43, `artifacts/06-43-conf04-verdict.txt`). It is a MEASUREMENT and
     not an UNKNOWN: the `LibraryMonitor` named all three Audio items, so the refresh ran and
     reached them, and `PreferNonstandardArtistsTag` re-read `true` afterwards. The operator's
     recorded decision `negative-carry-e6` (2026-09-24T14:30:37Z) **carries CONF-04's Jellyfin half
     to Phase 7 entry criterion E6 under an explicit override** — an auditable carry of an OPEN
     requirement, **not a close**. `REQUIREMENTS.md`'s box stays unticked. The two verdicts are
     still never summed.*

  5. Match disambiguation is demonstrated, not merely set: `preferred.countries` carrying `GB` (the
     code MusicBrainz actually stores; `UK` alone silently matches nothing, and entries are
     regexes), `preferred.original_year`, and `musicbrainz.extra_tags` — shown by a *Now!* volume
     preferring the UK release over the US one under `--pretend`, with the run confirmed to have
     written nothing (source and library file counts unchanged).
     *Two corrections 2026-09-21 (plans 06-11 and 06-12); the criterion text above is deliberately
     NOT rewritten. (a) **"Source and library file counts unchanged" is WEAKER than what was done**
     — a count passes while content changes underneath, which Phase 1 measured happening — so
     "wrote nothing" is discharged by the three-layer D-29 proof: `/media` at `RW=false` from
     `docker inspect`, `meta` AND `sha256` manifests over all 190 sampled files identical either
     side and re-verified with `cmp`, and `library.db` / `state.pickle` byte-identical with mtimes
     recorded as well as hashes. (b) **The *Now!* volume could not demonstrate the preference** —
     its GB release beats its rival by 0.53 while the whole country term is worth ≤0.0075, so the
     A/B/C controls came out identical and a second *Now!* row was identical too. The plan's escape
     clause fired and the demonstration was relocated to a genuine one-key rank-0 flip on another
     drawn row (`Benson Boone / American Heart`: `['XW','US']` → XW, `['US','XW']` → US, both
     10 tracks, distance 0.0). `GB`-works-and-`UK`-is-silently-inert was proven separately.*
**Plans**: 52 plans in 28 waves *(14 executed 2026-09-20/21; plans 06-15 … 06-21 added 2026-09-22 as GAP CLOSURE after `06-VERIFICATION.md` scored 5/6 — the D-04 "no bare `beet` invocation" assertion was vacuous (CR-01) — and to disposition all 24 findings in `06-REVIEW.md`, which the same verification marked NOT WIRED. Plans 06-22 … 06-29 added 2026-09-22 as **GAP CLOSURE ROUND 2**, planned against `06-REVIEW-GAP.md` — a code review of round 1's own changes that found 1 BLOCKER and 7 Warnings in the new code, plus two further findings from a cross-family adjudication. GC-03 is CR-01 reproduced one nesting level in, so the phase must not close on "CR-01 fixed" until round 2 lands. Plans 06-30 … 06-34 added 2026-09-23 as **GAP CLOSURE ROUND 3**, planned against `06-REVIEW-GAP2.md` — a code review of **round 2's own** changes, which found **0 Critical, 5 Warning, 5 Info**. Round 3 is deliberately five plans against round 2's eight: half its findings are Info and several are comment corrections, and the goal is to stop the recursion rather than feed it. Plans 06-35 … 06-39 added 2026-09-23 as **GAP CLOSURE ROUND 4**, planned against `06-REVIEW-GAP3.md` — a deep code review of **round 3's own** 320-insertion diff across the same four scripts, which found **0 Critical, 6 Warning, 4 Info**. ⚠ That report reuses round 1's `WR-*`/`IN-*` ID namespace, which is already cited in band in all four scripts, so round 4's findings are written in band as `R4-01 … R4-10` and the mapping table lives in `06-DISPOSITIONS-GAP3.md`. Plans **06-40 … 06-45** added 2026-09-23 as **GAP CLOSURE ROUND 5**, planned against `06-VERIFICATION.md`'s re-verification (**5/6**, CONF-04 the single failing truth). Round 5 is not another code review: it is the **operator's decision to drive CONF-04's Jellyfin re-probe inside Phase 6** instead of taking either of the two paths that report offered. Six plans, strictly sequential, two of them `autonomous: false`, closing on a measurement that may honestly fail — the negative branch is a planned outcome, not a fallback.)*

| Plan | Objective |
|------|-----------|
| 06-01 | The whole Phase 6 tagger configuration in the one vendored `config.yaml` — `plugins:` as a list, the `paths:` stanza, and every rc6 schema-default landmine pinned explicitly |
| 06-02 | The D-33 and D-34 traceability addenda in `REQUIREMENTS.md` and D-32's snapshot-release correction in `PROJECT.md` |
| 06-03 | Criterion 4's Jellyfin half: `PreferNonstandardArtistsTag` enabled, targeted scan, N distinct artist entities, and the standing assertion |
| 06-04 | `02-review` emptied (D-35), `flask.yaml` and `flask-config.yaml` authored, `beets.yaml` corrected, and beets-flask's first start with its three assertions |
| 06-05 | The stratified seeded draw (`06-SAMPLE.md`) and the committed pre-run oracle (`06-EXPECTED-TREE.txt`) |
| 06-06 | D-09 part 2 — an inbox proven to FIRE — and D-07's exposure shape asserted from the runtime |
| 06-07 | `scripts/check-beets-config.sh`: CONF-01/02/05 asserted from the SERVER-COMMITTED config, with D-30's two arms recorded as two objects |
| 06-08 | `scripts/phase06-incremental-control.sh`: D-31's two-arm negative control, one key apart, opposite outcomes |
| 06-09 | `scripts/phase06-oracle.sh`: `beet move -p`, the three-layer wrote-nothing proof, and nine class assertions, all self-tested |
| 06-10 | Harness revisions: D-11's two-definition named census, D-03's drift/mount widening, D-04's throwaway-`-l` assertion |
| 06-11 | The oracle RUN: zero-diff against the committed tree, the `%aunique{}`/singleton/DJ-field reports, and D-29 across all three layers |
| 06-12 | CONF-05 driven — a *Now!* volume prefers the `GB` release with a track-count check and a negative control — plus D-30 arm 2 and the OQ-4 resolution |
| 06-13 | The Music Assistant arm, gated on operator confirmation (D-36); CONF-04 stays OPEN if MA never returns |
| 06-14 | All five criteria re-measured from live state, the Phase 6 closure in `beets.md`, and the Phase 7/9 carry-forward register |
| 06-15 | CR-01's violation half: the three `beet config` calls in `check-beets-config.sh` made D-04 compliant, the no-op overlay proven empty, and four same-file hygiene findings |
| 06-16 | CR-01's detector half: the D-04 pattern widened to variable-built invocations, the missing vacuity guard added, and a NAMED exemption register pinned |
| 06-17 | WR-03: `check-music-consumers.sh` gains a documented `exit 3` (measured-but-not-at-target) so CONF-04's open state has a machine-readable signal |
| 06-18 | The oracle's remote-command construction: literal allow-list fences on the two destructive knobs, positional-parameter paths, unique temp names |
| 06-19 | The oracle's fail-closed assertions: no green tick over a could-not-look, an empty-manifest guard, and a DJ-stratum vacuity guard |
| 06-20 | The incremental control aligned with its sibling: a loud `exit 3` on a usage error, an unpinned path count, and the stated RED-vs-UNKNOWN convention |
| 06-21 | The 24-finding disposition register, `06-REVIEW.md` wired, and CR-01's residue plus WR-09 carried into Phase 7's entry criteria |
| 06-22 | GC-01, the round-2 BLOCKER: the forbidden-substring scan's `printf \| grep -q` pipeline removed, a >64 KiB self-test case added to catch its return, and case 6's two outcomes counted independently (GC-13) |
| 06-23 | GC-03 — CR-01 one nesting level in: a guard refusing a vacuous ASSERTED set, a green condition that cannot contradict its own count, and the D-04 regex branch given its siblings' anchors (GC-16) |
| 06-24 | The oracle's receiving-side fences made the same predicate as the sending-side ones (GC-02), and the three `printf \| grep -q` pipelines removed including the inverted one (GC-06) |
| 06-25 | The incremental control's fixed container temp names minted per run, fail-closed, and the IN-06 threat-model question answered once for both siblings (GC-08) |
| 06-26 | Four overridable paths quoted before they reach a remote command string (GC-17), the `CONSUMERS_SCRIPT` override made visible on every arm (GC-14), and the failing-block tail completed (GC-09) |
| 06-27 | The oracle's vacuity verdicts made symmetric (GC-05), the last two path interpolations quoted (GC-15), the self-test banner made honest (GC-12), and two overstated comments corrected (GC-07, GC-11) |
| 06-28 | Every stale cross-file citation replaced by a proven anchor (GC-04) and `beets.md`'s counts table re-measured (GC-10) — run last, after the line numbers stop moving |
| 06-29 | The 17-row round-2 disposition register, `06-REVIEW-GAP.md` wired to it, `DEF-06-29-*` entries, and the roadmap and state files told the truth |

Plans:
**Wave 1**

- [x] 06-01-PLAN.md — write the full Phase 6 tagger configuration into the vendored `config.yaml`, offline-validated and credential-screened
- [x] 06-02-PLAN.md — CONF-06's D-33 addendum (`beet move -p` is the oracle), CONF-04's D-34 addendum (`ARTISTS`, not `;` in `ARTIST`), and PROJECT.md's D-32 correction
- [x] 06-03-PLAN.md — enable `PreferNonstandardArtistsTag`, targeted-scan via `/Library/Media/Updated`, prove N distinct artist entities, extend `check-music-consumers.sh` *(amended in band: the option is **probe-time**, so the targeted Default-mode refresh — driven twice, at album scope and at file scope — moved **0 of 1,244** census rows. The aggressive per-item refresh that would re-probe is forbidden in this estate and was not issued, so the option is set and asserted while criterion 4's Jellyfin half stays OPEN.)*

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 06-04-PLAN.md — empty `02-review` into `04-hold`, author `flask.yaml`/`flask-config.yaml`, correct `beets.yaml`, first-start beets-flask with three assertions
- [x] 06-05-PLAN.md — the deterministic seeded draw and the expected tree, both committed before any run

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 06-06-PLAN.md — drive a throwaway folder through `02-review` past the 30 s debounce, and assert D-07's exposure from `docker inspect`, DNS and HTTP
- [x] 06-07-PLAN.md — `scripts/check-beets-config.sh` with a `--self-test`, then both D-30 arms run and their disagreements named
- [x] 06-08-PLAN.md — `scripts/phase06-incremental-control.sh` with a `--self-test`, then both arms run to opposite outcomes
- [x] 06-09-PLAN.md — `scripts/phase06-oracle.sh`: the oracle core plus nine class assertions, every red branch driven by `--self-test`
- [x] 06-10-PLAN.md — revise the tagger census to two named-and-classed definitions, widen the drift block to four pairs, add the D-03 mount and D-04 throwaway assertions *(amended in band: `tagger-capable containers` moved 2 → 3 as `beets-flask` joined `sabnzbd` and `lidarr` — reported, not asserted, and none of the three holds `rw` on Music. `beets.md` § Phase 4 still states 2 as "the expected value"; that sentence is now dated and left standing. One deferral: DEF-06-10-01, the freeze fold-in's `timeout 120` does not bound the INNER ssh to atlantis.)*

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 06-11-PLAN.md — run the oracle: zero-diff, the class-assertion reports, and the three-layer wrote-nothing proof *(amended in band: the zero-diff tree grows BOTH `Various Artists/` (44 files) and `Various/` (30 files) — CONF-03 passes on each, because each equals its own `ALBUMARTIST` byte-exactly, but two spellings of one idea is two artist pages in both consumers, arriving through the TAGS. No path rule fixes it; deferred as DEF-06-11-01 to Phase 7.)*
- [x] 06-12-PLAN.md — the driven country-preference proof with its negative control, and D-30 arm 2's preview cross-check *(amended in band: the plan's own A/B/C controls on the *Now!* row came out **IDENTICAL** — the GB release wins by 0.53 where the whole country term is worth ≤0.0075 — so the escape clause fired and the proof was relocated to a genuine one-key rank-0 flip on another drawn row. Two deferrals: DEF-06-12-01 (path rule 2 unexercised) and DEF-06-12-02 (`musicbrainz.search_limit` is 5).)*
- [x] 06-13-PLAN.md — **`autonomous: false`** — operator gate on Music Assistant being back online, then the MA artist-entity read-back or an explicit CONF-04 OPEN *(amended in band: the D-36 gate was answered **"run the check"**, MA answered on 2.11.0b2, and CONF-04's MA half CLOSED — A1 and A2 both resolved against the running build first, `MA_VERSION_PROVEN` moved in the same commit as the re-proof. CONF-04 as a whole stays OPEN on its Jellyfin half; the two halves are never summed.)*

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 06-14-PLAN.md — re-measure all five criteria from live state, write the Phase 6 closure, and hand the carried-forward items to Phases 7 and 9 *(amended in band: re-measurement at close on 2026-09-21 22:04–22:07Z re-ran `check-beets-config.sh` (exit 0, `FAILURES total: 0`) and both `--self-test`s (exit 0), and re-read both consumers directly through their own APIs; the oracle and the two-arm incremental control were NOT re-driven live, because doing so would import, and their results are cited to their committed artifacts instead.)*

**Wave 6 — GAP CLOSURE** *(added 2026-09-22; blocked on Wave 5 completion. `06-VERIFICATION.md`
scored 5/6: the D-04 assertion plan 06-10 shipped matched the literal token `beet`, but every beet
invocation this phase's own scripts make is built from a variable, so it asserted over an EMPTY set
and printed a green tick — with a real violation of that same rule sitting uncaught in
`check-beets-config.sh`. These three plans own different files and run in parallel.)*

- [x] 06-15-PLAN.md — add a throwaway `-l` to the three `check-beets-config.sh` invocations, truncate-and-assert the no-op overlay, and close WR-04/WR-05/IN-01/IN-03/IN-04/IN-07
- [x] 06-18-PLAN.md — fence `SCRATCH` and `STAMP_REMOTE` to literal allow-lists at both layers, pass remote paths as positional parameters, and close WR-07/WR-08/IN-06/IN-11
- [x] 06-20-PLAN.md — a loud `exit 3` on a usage error, a path count that is not pinned to 1, and the RED-vs-UNKNOWN convention stated; closes IN-02/IN-05/IN-10 and IN-08's incremental half

**Wave 7 — GAP CLOSURE** *(blocked on Wave 6 completion)*

- [x] 06-16-PLAN.md — widen the D-04 pattern to variable-built invocations, add the missing vacuity guard in its own siblings' shape, pin a NAMED exemption register, and close WR-10/IN-13
- [x] 06-19-PLAN.md — route every could-not-look to UNKNOWN in `phase06-oracle.sh`, guard the empty manifest and the unexercised DJ stratum; closes WR-01/WR-02/WR-06/IN-09/IN-12 and IN-08's oracle half

**Wave 8 — GAP CLOSURE** *(blocked on Wave 7 completion — shares `quick-health-check.sh` with 06-16)*

- [x] 06-17-PLAN.md — gate the green banner below a documented `exit 3`, and teach the health entry point that 3 means CONF-04 pending rather than BROKEN

**Wave 9 — GAP CLOSURE** *(blocked on Waves 6–8 completion)*

- [x] 06-21-PLAN.md — the 24-row disposition register, `06-REVIEW.md` wired to it, `DEF-06-21-*` entries, and two new Phase 7 entry criteria carrying CR-01's residue and WR-09

**Wave 10 — GAP CLOSURE — ROUND 2** *(added 2026-09-22; planned against `06-REVIEW-GAP.md`, a code
review of round 1's own gap-closure changes. These four plans own four different files and run in
parallel. GC-01 and GC-03 are sequenced here deliberately: GC-01 is a live latent BLOCKER in the
script that gates config correctness, and GC-03 means the phase's headline "CR-01 closed" is not
yet true.)*

- [x] 06-22-PLAN.md — remove the `printf | grep -q` pipeline from both forbidden-substring tests, add the >64 KiB self-test case that would have caught it, and count case 6's two outcomes independently; closes GC-01 and GC-13
- [x] 06-23-PLAN.md — refuse a vacuous ASSERTED set in the D-04 ladder, require a non-zero asserted count in the green condition, and give the BEET-variable regex branch its siblings' anchors; closes GC-03 and GC-16
- [x] 06-24-PLAN.md — make the oracle's three receiving-side fences the sending side's predicate and remove the three self-test pipelines including the inverted assertion; closes GC-02 and GC-06
- [x] 06-25-PLAN.md — mint the incremental control's container temp names per run with a fail-closed branch, and answer the IN-06 threat-model question once for both siblings; closes GC-08

**Wave 11 — GAP CLOSURE — ROUND 2** *(blocked on Wave 10 — 06-26 shares `quick-health-check.sh`
with 06-23, and 06-27 shares `phase06-oracle.sh` with 06-24 and inherits 06-25's decision)*

- [x] 06-26-PLAN.md — quote all four overridable paths that reach a remote command string, make the `CONSUMERS_SCRIPT` override visible on every arm, and complete the failing-block tail; closes GC-17, GC-14 and GC-09
- [x] 06-27-PLAN.md — make the oracle's vacuity verdicts symmetric, quote the last two path interpolations, make the self-test banner name its counter, and correct two overstated comments; closes GC-05, GC-15, GC-12, GC-07 and GC-11

**Wave 12 — GAP CLOSURE — ROUND 2** *(blocked on Waves 10-11 — a citation repaired before its
target stops moving is a citation that is stale again by the time the round closes)*

- [x] 06-28-PLAN.md — replace every stale cross-file citation with a proven anchor and re-measure `beets.md`'s counts table; closes GC-04 and GC-10

**Wave 13 — GAP CLOSURE — ROUND 2** *(blocked on Waves 10-12)*

- [x] 06-29-PLAN.md — the 17-row round-2 disposition register, `06-REVIEW-GAP.md` wired to it, `DEF-06-29-*` entries, and the roadmap and state files told the truth

**Wave 14 — GAP CLOSURE — ROUND 3** *(added 2026-09-23; planned against `06-REVIEW-GAP2.md`, a code
review of round **2's** own gap-closure changes. It found **0 Critical, 5 Warning, 5 Info** — no
BLOCKER and no reproducible false green — and its central charge is that round 2 closed several
defect classes PARTIALLY and then wrote in-band comments claiming they were closed COMPLETELY. So
several of these fixes are deliberately claim corrections rather than code widenings, and each
plan states which it is doing per finding. These four plans own four different files and run in
parallel.)*

- [x] 06-30-PLAN.md — finish GC-17's census: quote the five surviving overridable knobs, pass the sabnzbd `extended.conf` path positionally instead of in a hand-escaped wrapper the same comment forbids, and retract the thirteenth exit-code notice's stale delta; closes R3-01 and R3-05
- [x] 06-31-PLAN.md — pin and drive the oracle's self-test case count so a dropped section cannot pass under a green banner, make the layer-3 hashes measurable for a space-bearing path, give the AFTER side the BEFORE side's emptiness guards, and narrow the fence claim; closes R3-02, R3-03, R3-04 and R3-06
- [x] 06-32-PLAN.md — widen both in-container traps to the signals a bounded remote kill delivers and give both fences GC-02's character-class predicate instead of a bare glob that matches `/`; closes R3-09 and R3-10
- [x] 06-33-PLAN.md — make case 6 announce the gate it actually has rather than a red count nothing compares, and correct the GC-13 justification whose stated reason does not apply; closes R3-07 and R3-08

**Wave 15 — GAP CLOSURE — ROUND 3** *(blocked on Wave 14)*

- [x] 06-34-PLAN.md — the 10-row round-3 disposition register, `06-REVIEW-GAP2.md` wired to it, `DEF-06-34-*` entries carrying the residue **and the round's deliberate refusals** — three of them, across the two plans that made them — and the roadmap and state files told the truth by hand

**Wave 16 — GAP CLOSURE — ROUND 4** *(added 2026-09-23; planned against `06-REVIEW-GAP3.md`, a
deep code review of round **3's** own gap-closure diff. It found **0 Critical, 6 Warning, 4 Info**
— no BLOCKER and no reproducible false green — and its two largest findings are the same defect
class this phase keeps re-manufacturing: a claim the adjacent code does not support, written in the
very hunk announcing the class closed. So several of these fixes are deliberately claim corrections
rather than code widenings, and each plan states which it is doing per finding. ⚠ Round 4's report
reuses round 1's `WR-*`/`IN-*` ID namespace, so these plans cite the findings in band as `R4-*`;
the mapping is in `06-DISPOSITIONS-GAP3.md`. These four plans own four different files and run in
parallel.)*

- [x] 06-35-PLAN.md — render the four `_drift_pair` paths and the dashboard resolve address, and withdraw both the sentence claiming the forbidden-shape class was closed and the census count this edit moves; closes R4-01 (WR-01), R4-07 (IN-01) and R4-08 (IN-02)
- [x] 06-36-PLAN.md — make the announced case count adjust where each deliberate skip is decided so a python3-less or root machine stops reporting a false "A SECTION DID NOT RUN", give the layer-3 sha256 parser cases in the pinned set, take the requested paths through `ENVIRON`, and state the could-not-look cleanup gap; closes R4-02 (WR-02), R4-06 (WR-06), R4-09 (IN-03) and R4-10 (IN-04)
- [x] 06-37-PLAN.md — make both in-container signal handlers terminal so a delivered signal kills the program instead of being swallowed, add `PIPE`, and stop the paragraph naming an unconfirmed `docker exec` SIGTERM path as routine; closes R4-03 (WR-03) and R4-04 (WR-04)
- [x] 06-38-PLAN.md — withdraw the raw grep count the correcting hunk falsified rather than re-pinning it, and audit every other in-band count claim in the same file; closes R4-05 (WR-05)

**Wave 17 — GAP CLOSURE — ROUND 4** *(blocked on Wave 16)*

- [x] 06-39-PLAN.md — the 10-row round-4 disposition register with the `WR-*`/`IN-*` → `R4-*` mapping table, `06-REVIEW-GAP3.md` wired to it, `DEF-06-39-*` entries carrying the residue **and the round's refusals**, and the roadmap and state files told the truth by hand — including that `06-VERIFICATION.md` is stale

**Waves 18–23 — GAP CLOSURE — ROUND 5: CONF-04's Jellyfin half, DRIVEN** *(added 2026-09-23; planned
against `06-VERIFICATION.md`'s re-verification, which scored **5/6** with CONF-04 the single failing
truth. That report offered the operator two paths — (a) an explicit override carrying the Jellyfin
half to Phase 7 entry criterion **E6**, or (b) hold Phase 6 open until Phase 7's first write — and
**the operator chose neither. They chose to drive the re-probe now and close CONF-04 inside Phase
6.** Criterion 4's own sentence "It discharges on Phase 7's first write" is deliberately overtaken by
that decision.*

*The lever is the one plan 06-03's own artifact named and never pulled. 06-03 measured — twice, at
album scope and at file scope, with `LibraryMonitor` confirming by name — that a targeted
Default-mode refresh does **not** re-run the prober on a file whose mtime has not changed, and listed
`(b) the file's mtime changing` as a mechanism that would. Round 5 drives exactly (b) on **exactly
three files**, inside a ZFS snapshot fence taken in the same remote step, followed by the same
targeted `POST /Library/Media/Updated` 06-03 already proved safe.*

*⛔ **The aggressive per-item "replace all metadata" refresh mode is FORBIDDEN and is not reachable
from any branch of this round.** Phase 1 measured it rewriting 83 of 91 `.nfo` with
`SaveLocalMetadata` already off (D-24, T-06-11). If the mtime route does not move the rows, the
outcome is a **recorded negative result** handed back to the operator with the two original options —
not a wider hammer. **The hypothesis is unproven and the plan set is written so it can honestly
fail.** These six plans run strictly sequentially; each depends on the one before it.*

*Revised 2026-09-23 after plan review. The review confirmed the safety machinery but found the
numbers → verdict → permanent-record chain had **no mechanical self-check at its two most
consequential steps**, and that its one independent corroboration ran AFTER the operator's binding
decision. Four changes, no re-architecture: (1) 06-42 emits a parseable per-row verdict block and
**recomputes every verdict from its own numbers** in its verify; (2) 06-43 **recomputes the BRANCH
value** from four recorded inputs and fails on disagreement, with 06-42's block `diff`-checked
byte-for-byte; (3) the instrument re-run **moved from 06-44 task 1 into 06-42 task 3**, so the
corroboration exists before the operator decides — and it is now BINDING, gating `BRANCH: A` in
06-43 and gating the `REQUIREMENTS.md` tick again in 06-45; (4) the 120 s settle window became a
subtraction of two recorded epoch timestamps. Wave numbers are unchanged: the fix was relocating one
task, not re-sequencing the round.*

- [x] 06-40-PLAN.md — the read-only before-state: the 1,244-row `ArtistItems` census, the three pinned rows, the four D-34 options, a full `.nfo`/`.lrc`/`.jpg` hash manifest, and the touch list resolved and proved to exclude the six OQ-1 `TRUSTFALL` DO-NOT-RESCAN rows
- [x] 06-41-PLAN.md — **`autonomous: false`** — the operator gate, then `zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe` and the mtime touch in the same remote step, proved by `zfs diff` to name exactly three files and no `.nfo`, then one file-scope targeted Default-mode refresh with `LibraryMonitor` as the witness
- [x] 06-42-PLAN.md — the after-state read-back, the four-way safety re-assert, **and the independent corroboration**: per-row verdicts emitted in a parseable `ROW|…|verdict=` block whose every verdict is recomputed from its own numbers by the plan's own verify, a census delta enumerating every moved row by name, a post-refresh `zfs diff`, a full hash-manifest comparison, a single machine-readable `SAFETY:` line, and a run of the **deployed, unmodified** `check-music-consumers.sh` recorded as `INSTRUMENT RUN:` / `JF_AT_TARGET:` / `JF_PENDING:` — taken here, in this wave, so both measurements exist before anything is decided
- [x] 06-43-PLAN.md — **`autonomous: false`** — the branch (`BRANCH: A` closed / `B` disproven / `PARTIAL`) computed by a five-step rule from four recorded inputs and **independently recomputed by its own verify block**, with 06-42's row-verdict block copied byte-for-byte and `diff`-checked; `BRANCH: A` is unreachable without a corroborating instrument run. The exit code and the MA counters are deliberately NOT inputs — the script exits 3 on A and on B alike. Then the round-wide forbidden-mode audit and the operator's decision, recorded before any document moves
- [x] 06-44-PLAN.md — the instrument's in-band prose and `quick-health-check.sh`'s exit-3 arm corrected, downstream of a verdict it earned on untouched code in wave 20 — with a mechanical diff proof that no target, baseline, threshold, branch, counter or exit code moved *(executed 2026-09-24 on `BRANCH: B`: five sites corrected, the Jellyfin half written as CARRIED to E6 under the recorded override and never as closed; the changed-line audit reports **0** non-comment, non-message lines and **0** added `if`/`elif`/`case`/`EXIT_CODE=` lines across both files; exit 3 and `EXIT_CODE=1` both deliberately untuned; the 8-line banner driven through `quick-health-check.sh`'s exact `1,8p` window)*
- [ ] 06-45-PLAN.md — the record, behind a **tick gate** that re-reads 06-42's corroboration itself and refuses to tick `REQUIREMENTS.md` on an uncorroborated `BRANCH: A`: CONF-04, ROADMAP's Phase 6 criterion 4 and status row, Phase 7 **E6** split into its two measurements (the second — the ≥4-artist MA discrimination — stays with Phase 7 on every branch), `06-VERIFICATION.md`'s gap record, `DEF-06-45-*`, and `beets.md`
- [x] 06-46-PLAN.md — R6-01/R6-03(a): the sole `shellcheck -S warning` finding across the six instrument scripts, and self-describing remediation output on both pinned-count failures in `check-music-freeze.sh`
- [x] 06-47-PLAN.md — R6-05: a heading-text (never line-number) pointer at the head of `beets.md` naming the authoritative current state, plus the three-way Phase 6 disposition consistency audit *(executed 2026-09-24: the pointer is 26 insertions / 0 deletions at line 16, cited by heading text and proven byte-identical mechanically — `grep -cF` **2** over the file, **1** restricted to `#`-lines; IN-02's own line-number fix deliberately NOT taken, with the reason stated in band; `### The five criteria` disclosed as occurring TWICE and disambiguated by parent. The four-record audit found **0 DISAGREE** — `deferred-items.md` is SILENT on two checks and is verdicted COULD NOT LOOK with NO owner named, because silence is not contradiction; the `REQUIREMENTS.md` ABORT branch did not fire. `REQUIREMENTS.md`, `ROADMAP.md` and `deferred-items.md` byte-unchanged under `git diff --exit-code HEAD --`. Four zero-expecting recipes each driven against a control first. The artifact records explicitly that this row's `In Progress` is CORRECT and must not be flipped)*
- [x] 06-48-PLAN.md — R6-06/R6-07: `DEF-06-45-04`'s non-detecting detector corrected and DRIVEN against a control string, and the bracketing convention's scope decided — stays `artifacts/`, not widened to ROADMAP prose, not dropped *(executed 2026-09-24: control matrix `-cE` → 1 / `-cF` → 0, counts re-derived 0 across seven files, `06-43-conf04-verdict.txt` proven byte-identical to base commit `ce35877` by sha256, `DEF-06-48-01`/`-02` filed, scope DECIDED as stays-`artifacts/` and no ROADMAP edit required by it)*
- [x] 06-49-PLAN.md — R6-04: `CONVENTIONS.md` created as the authoritative conventions index with a canonical example per rule, and `CLAUDE.md`'s GSD-managed conventions block synchronised to it *(executed 2026-09-24: 319 lines / 13 sections / 20 `scripts/` citations, 0 line-number citations driven against a control; convention 4 cites the `_Q` override guards that force `EXIT_CODE=1` and names `DECLARED_INTERP_EXPECTED` as the one exception with policy-is-weaker-than-mechanism stated; WR-03's fix (b) delivered as the pinned-count entry naming all four pins; `DEF-06-48-02`'s decided scope and the `-cE`-never-`-cF` rule written down; mirror proven by ORDERED name-for-name correspondence `|A|=|B|=13` with the comparator driven red first; `ARCHITECTURE.md` deliberately NOT created and `scripts/` byte-unchanged)*
- [x] 06-50-PLAN.md — the round-6 register `06-DISPOSITIONS-GAP4.md`: the fresh `R6-*` namespace and its mapping table, all five findings dispositioned, WR-02 stated ACCEPTED with a measured self-binding claim, and the round's five refusals
- [x] 06-51-PLAN.md — **`autonomous: false`** — R6-08: `git push` then `git pull --ff-only` on LXC 100 at `/mnt/fast/stacks`, behind a measured pre-flight, proven per-file by sha256 and proven not to have redeployed any of ~103 containers
- [x] 06-52-PLAN.md — **`autonomous: false`** — R6-09: the `tank/media/Music@pre-06-41-conf04-reprobe` go/no-go, measured from `zfs list` with the dependency question answered on evidence (Phase 7's pilot fence is committed under its **Success Criteria item 1**, not in the E1-E12 block); `hold` is a first-class outcome. As the round's last plan it also closes `06-DISPOSITIONS-GAP4.md`'s `ROUND CLOSE`, folding R6-08's and R6-09's actual outcomes into the round's primary record — the plan count stays with 06-50 deliberately, so a legitimate halt leaves the record incomplete rather than wrong

**Phase 6 disposition:** **CLOSED WITH ONE OPEN REQUIREMENT — CONF-04**, named, on its Jellyfin half
only. Criteria 1, 2, 3 and 5 are TRUE and were re-measured from live state at close. Criterion 4
carries two verdicts that must never be summed. `tank/downloads@pre-phase5` is **NOT** released —
see Phase 7's entry criteria.
**Amended 2026-09-22 by plan 06-29 — a second gap-closure round, `ROUND 2`, ran against
`06-REVIEW-GAP.md`.** That review read round 1's *own* gap-closure changes and found **1 BLOCKER
and 7 Warnings inside them**; a cross-family adjudication (`gemini-3.1-pro-preview`; `codex` was
first choice and failed on billing) added two more, for **GC-01 … GC-17**. Plans **06-22 through
06-28** closed all seventeen — every one `FIXED`, every one with a commit and a driven artifact —
and plan **06-29** dispositioned them in
`.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP.md` (**17 FIXED, 0 FIXED
(undriven), 0 ACCEPTED, 0 CARRIED — 17 total**, reconciling three ways), wiring `06-REVIEW-GAP.md`
to it. The two that mattered most: **GC-01**, a latent BLOCKER in the script that gates config
correctness, where `printf | grep -q` under `pipefail` reported a *present* forbidden substring as
absent above 64 KiB; and **GC-03**, which is **CR-01 reproduced one nesting level in** — the D-04
vacuity guard tested the count the block *prints* while the block iterated a different set, so a
green tick over an empty **asserted** set survived the plan written to abolish exactly that. Both
are closed and driven in both directions. Round 2's residue is carried by name as `DEF-06-29-01`
… `DEF-06-29-11`, and the part that closes only on the live pilot is owned by Phase 7 entry
criterion **E12**.
**This is a record, not a re-close, and no re-verification was performed.** Plan 06-29 did not run
`/gsd-verify` and claims no verification result. **CONF-04 is not closed** — `REQUIREMENTS.md` is
untouched, `- [ ] **CONF-04**` stands, its Jellyfin half is still OPEN and entry criterion **E6**
still owns the discharge. No requirement checkbox moved and **the phase is not declared complete**:
that is the verifier's call, on a re-verification this plan does not perform. **Recommended before
the phase closes:** `/gsd-verify 06`, and a fresh code review of **round 2's own changes** — round
2 exists because round 1 was not re-reviewed until after it was declared closed.
**Amended 2026-09-23 by plan 06-34 — a third gap-closure round, `ROUND 3`, ran against
`06-REVIEW-GAP2.md`.** That review read round **2's** own gap-closure changes across the four
instrument scripts and found **0 Critical, 5 Warning, 5 Info** — **no BLOCKER and no reproducible
false green**, which the reviewer stated explicitly rather than manufacturing one. Plans **06-30
through 06-33** closed all ten, and plan **06-34** dispositioned them in
`.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP2.md` (**9 FIXED, 1 FIXED
(undriven), 0 ACCEPTED, 0 CARRIED — 10 total**, reconciling three ways: 0+5+5, 9+1+0+0, and the fix
kinds 4 CODE + 3 CLAIM CORRECTION + 3 BOTH), wiring `06-REVIEW-GAP2.md` to it. **There was no
cross-family adjudication in round 3** — round 2 had one; this round did not, and the register says
so, because an absent adjudication that is not mentioned reads like a lost one.
**The round's character, which is the reason it is only five plans against round 2's eight: the
dominant defect class was a claim broader than its code.** Six of the ten findings are a comment
promising more than the code beside it delivers, and **for several the honest fix was to narrow the
sentence rather than widen the code** — every register row carries a `CODE` / `CLAIM CORRECTION` /
`BOTH` column saying which, because ten undifferentiated `FIXED`s would reproduce, one level up, the
exact over-claim the review is about. What was **not** driven is recorded per finding: the whole
layer-3 block (R3-03, R3-04) is reachable only from a live `--run` and is proven offline; the
`SIGTERM` behaviour behind R3-09 is static reasoning about POSIX `sh`; and `quick-health-check.sh`
was not executed at all, by the review or by the fix.
**Three refusals are recorded as loudly as the fixes**, because a refusal nobody wrote down reads as
an oversight and gets re-opened: plan 06-32 refused the best-effort `/tmp/p6-mf.*` sweep R3-09
floats (a prefix-gated `rm -rf` over names the run did not mint is a wider destructive reach than an
INFO litter finding justifies, on a container `/tmp` at mode 1777 shared by six processes on the
same uid); and plan 06-33 refused both R3-08's third-conjunct gate (implied by the other two
conjuncts, therefore vacuous — the class CR-01, GC-03 and GC-05 each removed) and wiring
`assert_beet_invocation_contract` into the live path, recording the arm-polarity precondition at the
site instead. Round 3's residue is carried by name as `DEF-06-34-01` … `DEF-06-34-06`; the part that
closes only on the live pilot attaches to the **existing** entry criterion **E12**, and no new
criterion is added. One correction to the review is recorded in band: **R3-07's census sentence is
wrong and its finding is not** — `assert_beet_invocation_contract` gives 4 raw hits at the reviewed
tree and 5 now, not "exactly two"; exactly two are *code*, so the conclusion stands.
**This is a record, not a re-close, and no re-verification was performed.** Plan 06-34 ran no
`/gsd-verify` and claims no verification result. **CONF-04 is not closed** — `REQUIREMENTS.md` is
untouched, `- [ ] **CONF-04**` stands, its Jellyfin half is still OPEN and entry criterion **E6**
still owns the discharge. No requirement checkbox moved and **the phase is not declared complete**:
that is the verifier's call. **Recommended next:** `/gsd-verify 06`. Whether a *fourth* review — of
round 3's own diff — is warranted is the operator's call and should be a deliberate decision rather
than an omission: it is the same discipline that caught both previous rounds, and round 3's own
numbers (zero Critical, most fixes claim corrections) are the argument that the marginal return has
fallen.
**Amended 2026-09-23 by plan 06-39 — a fourth gap-closure round, `ROUND 4`, ran against
`06-REVIEW-GAP3.md`.** That review read round **3's** own 320-insertion gap-closure diff across the
same four instrument scripts, at depth `deep`, and found **0 Critical, 6 Warning, 4 Info** — **no
BLOCKER and no reproducible false green**, stated plainly as a real result rather than manufactured.
Plans **06-35 through 06-38** closed all ten, and plan **06-39** dispositioned them in
`.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP3.md` (**9 FIXED, 1 FIXED
(undriven), 0 ACCEPTED, 0 CARRIED — 10 total**, reconciling three ways: the review's frontmatter
0+6+4, the dispositions 9+1+0+0, and the fix kinds **3 CODE + 3 CLAIM CORRECTION + 4 BOTH**), wiring
`06-REVIEW-GAP3.md` to it. Ownership: 06-35 R4-01/R4-07/R4-08, 06-36 R4-02/R4-06/R4-09/R4-10,
06-37 R4-03/R4-04, 06-38 R4-05. **There was no cross-family adjudication in round 4** — round 2 had
one, rounds 3 and 4 did not, and the register says so, because an absent adjudication that is not
mentioned reads like a lost one.
**The round's character, and it is uncomfortable: round 3's own centrepiece fix was round 4's
largest finding.** `ST_PLANNED_CASES=134` — the pin round 3 added so a dropped section could not pass
under a green banner — is a fixed constant compared with `-ne` against a self-test carrying three
*documented* environment-conditional skips, so it prints **"A SECTION DID NOT RUN" when every section
ran**, on a `python3`-less box or as root. **A false red with a wrong stated cause**, and its in-band
remediation instruction would have made it worse. The general form is now recorded: *a pin over a set
with environment-conditional members must adjust where the condition is decided, or it is a constant
pretending to be an invariant.* The base is re-measured at **140** and its reference environment is
named in band. And **a documented prohibition survived a second consecutive round inside the file
documenting it** — the four surviving instances of the ⛔-forbidden hand-escaped-`\"` shape sat
**eight to eleven lines below the prohibition paragraph itself**, inside the very command string it
is embedded in, under a sentence added in the same hunk declaring the class closed. The lesson is not
"write better prohibitions": a class is not closed until the sweep is **mechanical**, which is why
that file's census is now a recipe rather than a count.
**⚠ The ID alias, which a future reader cannot do without:** round 4's report reuses round 1's
`WR-*`/`IN-*` namespace, and round 1's IDs are already cited in band in all four scripts — 72
pre-existing citations across them at the review's own diff base — so the fixes are written in band as
**`R4-01` … `R4-10`** and the mapping table lives in `06-DISPOSITIONS-GAP3.md`. Round 4's `WR-02` is
`R4-02`, and is **not** round 1's `WR-02`.
**The refusals, by name, recorded as loudly as the fixes:** plan 06-36 **added no cleanup `trap` to
`phase06-oracle.sh`** under R4-10 — the file has none anywhere by design, and one would fire on the
forensic `exit 3` arms too, destroying the evidence they exist to preserve — and closed the finding
as a claim correction instead; plan 06-38 **excluded `ST_PLANNED_CASES=7` in `check-beets-config.sh`
from its count audit by name**, because it is a gated pin over an unconditionally executed set and
"fixing" it would have broken a working guard; and the four live layer-3 `awk` copies were
deliberately **not** hoisted, per `DEF-06-29-03`. **What is NOT driven is recorded per finding:**
`quick-health-check.sh` was executed **zero** times in round 4 either, by the review or by the fix;
the oracle's layer-3 block is still reachable only from a live `--run`, so R4-06's new cases prove the
*parser*, not the block; and the container-side signal behaviour is **unobserved inside `beets-flask`
on both paths** — the SIGTERM path graded NOT ESTABLISHED, the new SIGPIPE path BELIEVED at the same
static grade and explicitly not an upgrade. That residue attaches to the **existing** entry criterion
**E12** and adds **no new criterion**. Round 4's residue is carried by name as `DEF-06-39-01` …
`DEF-06-39-06`. **Three corrections to the source material are recorded in band:** `ST_PLANNED_CASES`
was already stale at 134 before round 4 touched it and the re-measured base is **140** (the finding's
conclusion is unaffected — only the number moved); the ID namespace collision, which is a defect in
the review's form and not in its findings; and **two self-referential-measurement instances that
fired during round 4's own execution**, in the plans closing that very class, both caught by measuring
after the edit landed and neither by an assertion — the fourth consecutive round for that hazard, and
the first in which it also turned up **inside the `<automated>` verify blocks** rather than the code
(`DEF-06-39-06`).
**This is a record, not a re-close, and no re-verification was performed.** Plan 06-39 ran no
`/gsd-verify` and claims no verification result. **CONF-04 is not closed** — `REQUIREMENTS.md` is
untouched, `- [ ] **CONF-04**` stands, its Jellyfin half is still OPEN and entry criterion **E6**
still owns the discharge. No requirement checkbox moved and **the phase is not declared complete**:
that is the verifier's call. **⚠ `06-VERIFICATION.md` is STALE and was deliberately not touched** —
it records round **1's** closure, dated 2026-09-22, with `status: passed` and `gaps_remaining: []`,
written before rounds 2, 3 and 4 existed; **`/gsd-verify 06` has not been run since round 2**. A
passing verification sitting beside four gap-closure rounds is exactly the artifact a future reader
closes a phase on. **Recommended next:** `/gsd-verify 06`. Whether a *fifth* review — of round 4's own
diff — is warranted is the operator's call: round 4 found zero Critical and no reproducible false
green, which is closer to round 3's stated exit condition (findings Info-only, fixes claim
corrections) than round 3 itself was and is not yet there; against that, round 4 found four live
instances of a forbidden shape that three previous rounds had walked past.
**Amended 2026-09-24 by plan 06-50 — a sixth gap-closure round, `ROUND 6`, ran against
`06-REVIEW.md`.** That review is a standard-depth pass over the phase's twelve changed files — the
six instrument scripts plus the beets / beets-flask configuration and compose definitions they assert
against — and found **0 Critical, 3 Warning, 2 Info**, status `issues_found`. Round 6 also carries
`06-VERIFICATION.md`'s residue (the non-detecting recipe it re-drove independently, and the
bracketing-scope observation it recorded "for a future round") and the two **operator actions** that
report named as outstanding. Plans **06-46 through 06-49** closed the round's fixable findings and
plan **06-50** dispositioned all five in
`.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP4.md` (**4 FIXED, 0 FIXED
(undriven), 1 ACCEPTED, 0 CARRIED — 5 total**, reconciling three ways: 0+3+2, 4+0+1+0, and the fix
kinds 1 CODE + 3 CLAIM CORRECTION + 1 BOTH), wiring `06-REVIEW.md` to it by **append**, without
editing a byte above the append point. **There was no cross-family adjudication in round 6** — round
2 had one; rounds 3, 4, 5 and 6 did not, and the register says so.
**⚠ THE ID ALIAS, FIRST BECAUSE EVERY CITATION DEPENDS ON IT.** `06-REVIEW.md` reuses round 1's
`WR-*`/`IN-*` namespace, which is already cited in band across all six scripts — **39** pre-existing
citations of the five reused IDs, **94** across the whole namespace, measured at `3085da1` and
identical at the pre-round tree `75c7989`. Round 6's in-band and register IDs are therefore
**`R6-01 … R6-09`**, chosen **up front in the fix plans** rather than aliased afterwards
(`DEF-06-39-01`), and the mapping table lives in `06-DISPOSITIONS-GAP4.md` immediately after its
Source table. Every round-6 reference in this paragraph is written in the paired form for the same
reason.
**What round 6 closed:** `R6-01 (WR-01)` — the only `shellcheck -S warning` finding across the six
scripts, so the set is now clean on all six where it was clean on five; `R6-03 (WR-03)` — both of the
review's own fix options, the failure arms of `check-music-freeze.sh` now naming the literal edit and
the prohibited shortcut, and `CONVENTIONS.md` naming all four live pins by symbol; `R6-04 (IN-01)` —
a new authoritative root-level `CONVENTIONS.md` (319 lines, 13 sections) with `CLAUDE.md`'s generated
block proven a name-for-name mirror by a comparator **driven red first**; `R6-05 (IN-02)` — a
heading-text pointer at the head of `beets.md`, deliberately **not** the line-number form the finding
itself suggested; plus the two non-review items `R6-06` (the `DEF-06-45-04` non-detecting detector,
corrected and driven against a control) and `R6-07` (the bracketing convention's scope, decided).
**`R6-02 (WR-02)` is ACCEPTED, with reasoning, and the round binds itself so the cost does not
grow.** Its proposed fix is a bulk relocation of round-by-round narrative out of the six most heavily
reviewed files in the repository, at the end of a recursion in which every round's own diff became the
next round's findings; the review itself calls that narrative "a genuine asset for provenance". The
durable half is taken as a **forward rule** in `CONVENTIONS.md` convention 12 and the existing
narrative is **not stripped** — and the self-restraint is **measured, not asserted**: round 6 changed
**one** file under `scripts/`, **+6 / -1** lines, of which 3 are single-line citations and 2 are
emitted failure output, with **0** lines of new in-band historical narrative and **0** new
`WR-*`/`IN-*` citations.
**The bracketing convention's scope was DECIDED and deliberately NOT widened to ROADMAP prose**
(`DEF-06-48-02`): scoped by **function, not directory name** — any file whose content is counted by a
published recipe must bracket the counted token — so no `ROADMAP.md` token edit was made or is
required, and nobody should "finish the job" later. **`ST_PLANNED_CASES=7` was not touched**
(`DEF-06-39-02` excluded it by name: a gated pin over an unconditionally executed set), and **no
`ARCHITECTURE.md` was created** — `R6-04 (IN-01)`'s architecture half is ACCEPTED, because this estate
is already mapped by `NETWORK.md`, `MEDIA.md`, `DEPLOYMENT.md` and `TAILSCALE.md`.
**⛔ Two of the round's items had NOT executed when this amendment was written at wave 3, and are
recorded PENDING with no outcome stated:** `R6-08`, the host `git pull --ff-only` sync of LXC 100
(plan `06-51`, wave 4, **`autonomous: false`**), and `R6-09`, the
`tank/media/Music@pre-06-41-conf04-reprobe` release go/no-go (plan `06-52`, wave 5,
**`autonomous: false`**). Both plans carry legitimate halt/hold branches; their outcomes land in
`DEF-06-51-01` and `DEF-06-52-01`, and **`06-52` task 3** folds them into the register's `ROUND CLOSE`
section, extends the register's count reconciliation, and closes this table's Phase 6 plan count to
`52/52` and the `**Plans**: … waves` header — neither of which is plan 06-50's to move, per the
operator's decision **`D-R6-M4`** (2026-09-24) that `Plans Complete` means **executed**, not authored.
**This is a record, not a re-close, and no re-verification was performed.** Plan 06-50 ran no
`/gsd-verify` and claims no verification result. **No CONF-04 work of any kind was performed by round
6 and no requirement checkbox moved** — `REQUIREMENTS.md` is byte-untouched, `- [ ] **CONF-04**`
stands, its Jellyfin half is still OPEN and entry criterion **E6** still owns the discharge, with E6's
second measurement staying with Phase 7 on every branch. `06-VERIFICATION.md` stands at `gaps_found`,
**5/6**, and was not re-scored; its own conclusion is that "no further action inside Phase 6 is
warranted or safe". **Recommended next:** `/gsd-verify 06`, after `06-51` and `06-52` have run.
**✅ ROUND CLOSE, appended 2026-09-24 by plan `06-52` task 3 at wave 5 — both operator plans have now
run and neither halted.** `R6-08` **FIXED**: LXC 100's `/mnt/fast/stacks` moved `ee82fb2` →
`b9c09b5` on a `proceed` answer taken against a **CLEARED** pre-flight, not an override (STOP
condition S4 — three stash entries on the production checkout — fired, the operator disposed of them
and the gate re-read 5 CLEAR / 0 STOP); **6 of 6** instrument scripts now sha256-MATCH per file where
the pre-flight read 3 MATCH / 3 DIFFERS, and nothing was redeployed, proven on all three of
name/image/status with the set difference empty both ways at 99 = 99 containers — closing
`DEF-06-45-05` item 2 and `DEF-06-29-11`, while `DEF-06-39-05` is **unblocked but NOT closed**
(`quick-health-check.sh` has still been run **zero** times across rounds 3-6). `R6-09` **CARRIED**:
the operator answered **`hold`**, overruling the executor's `release` recommendation on the
executor's own self-raised counter-argument that Phase 7's fence is *planned, not taken* — **nothing
was destroyed, rolled back or released**, the only `zfs` verb issued on any branch was `list`, and
`DEF-06-45-01` stays OPEN with its release condition rewritten from a judgement call into one
mechanical trigger (release when **Phase 7 Success Criterion 1 is satisfied** — a new snapshot taken
on the Music dataset **and** rollback exercised — not when Phase 7 is merely planned).
`tank/downloads@pre-phase5` was listed and not touched: different fence, different owner, entry
criterion **E4**. Full detail in `DEF-06-51-01` and `DEF-06-52-01`; the round's register closes in
`06-DISPOSITIONS-GAP4.md` § *ROUND CLOSE*, whose Counts reconciliation is extended there from the
five review findings to all nine round items. Two further `06-52` outcomes, both independent of the
snapshot disposition: the stale *"`tank` has ~9 T free"* figure in `DEF-06-45-01` and `CLAUDE.md`
§ *Constraints* corrected to the measured **5.26 T** (stale by ~3.7 T, in the direction the
`import.copy` reversibility argument leans on), and `DEF-06-52-02` recording as a **process defect**
that a criteria-only read of Phase 7's entry-criteria block would have answered "the pilot fence is
not planned" **by omission** — promoted to `CONVENTIONS.md` convention 14. **Status word unchanged:
`In Progress`.** No requirement checkbox moved, `REQUIREMENTS.md` untouched, and `06-VERIFICATION.md`
not re-scored by either plan — `/gsd-verify 06` remains the next step and the verifier's call.

**Research**: not needed — the specific traps are already captured with citations in the research.

### Phase 7: Pilot — 12 Albums End to End

**Goal**: Produce a flow the operator **believes**. Twelve albums are in the library, correctly
tagged and visible in both consumers — but the deliverable of this phase is trust, not a count.
Twelve clean single-artist albums would prove a flow that has never met the hard case, so the
sample deliberately includes a various-artist compilation and a multi-disc release, both
historically painful on this system. And because much of this library already carries tags, the
gate is not only "the file landed" but "the file is *better*": a field-level before/after diff
showing no net metadata loss. Every prior attempt shipped a tool and never shipped an album; this
phase exercises the project's definition of done once, on a batch small enough to finish in one
evening, including its reverse.
**Depends on**: Phase 2 (Music Assistant must be proven before content flows), Phase 6. Requires
the Phase 1 QUAL-01 before-state snapshot — without it there is nothing to diff against and this
phase cannot meet its own gate.
**Requirements**: IMPT-01, IMPT-02, CONS-04, QUAL-02, QUAL-03, QUAL-04
**Success Criteria** (what must be TRUE):

  1. Twelve bucket-A albums are imported inside a snapshot fence — ZFS snapshot of the Music dataset
     and a copy of `library.db` taken together — with rollback exercised at least once, because
     rolling back only the tree leaves the tagger's `incremental` state claiming those releases are
     done.

  2. **The sample includes the shapes that have historically hurt**: at least one various-artist
     compilation and at least one multi-disc release, named in the plan before the run. This is
     QUAL-03, and it is what makes CONF-03 and CONF-05 *exercised* rather than asserted —
     `Various Artists/` at the top level and the `preferred.countries` disambiguation were dry-run
     on paper in Phase 6; here they meet real content. A pilot of twelve clean single-artist albums
     is a failed pilot even if all twelve import perfectly.

  3. Every imported file passes `ffprobe` showing the *new* tags on the file itself, and ownership
     matches the decided `uid:gid`. `beet ls` is not acceptable evidence: beets logs a tag-write
     `EPERM` as a warning and continues, so the database can read perfectly while the file on disk
     keeps its old tags.

  4. **A field-level before/after diff is produced for every file in the pilot**, comparing the
     QUAL-01 snapshot against the post-import `ffprobe` output, and it shows **no net metadata
     loss**. Fields gained are listed. Any field dropped is either deliberate and recorded with its
     reason, or the import is rejected and re-run — not accepted with a shrug. This is QUAL-02, and
     it is the check that CONS-04 alone cannot make: a file can land, probe cleanly and appear in
     both consumers while being poorer than it arrived.

  5. **Undo is demonstrated, not assumed.** At least one album is deliberately rejected or treated
     as regressed, backed out, and re-run to a good state with no hand-repair of files or database —
     covering both the tree and the tagger's `incremental` state, since rolling back one without the
     other leaves the release invisible to a retry. This is QUAL-04. The reason it is a pilot gate
     rather than a nice-to-have: at bucket-A scale in Phase 9, "I cannot cleanly undo this" is
     indistinguishable from abandonment.

  6. All twelve albums appear in Jellyfin with the new metadata and in Music Assistant under the
     correct album artist — including the compilation, under `Various Artists`, as one album rather
     than twelve one-track artists, and the multi-disc release as one album with its disc numbering
     intact. This is CONS-04, exercised for the first time.

  7. The post-import detection sweep runs and either reports nothing or its findings are resolved:
     `.1`-suffix path collisions, empty `mb_albumid`, and track count versus `tracktotal`.

  8. The source folders still exist afterwards — the run copied rather than moved, so it was
     reversible the whole time.

**Entry criteria inherited from Phase 6** *(added 2026-09-21 by plan 06-14 — each of these is a
named item Phase 7 must handle before or during its pilot, not a note. They are written here rather
than only in a Phase 6 artifact because an item recorded where the next phase does not read is an
item nobody owns.)*:

  E1. **The DJ-routing MECHANISM does not exist (OQ-2 / C-6).** Phase 6 proved the DJ *path rule* —
      `DJ/$albumartist/$album%aunique{}/…`, 20 destinations, rule 3 — but it supplied `albumtype=dj`
      **by hand from a shell**, and that may not be cited as evidence for the mechanism.
      `--set albumtype=dj` is a `beet import` CLI flag backed by `import.set_fields`; beets-flask
      rc6's `InboxFolderSchema` carries only `path`, `name`, `auto_threshold` and `autotag`, so
      **there is no per-inbox field-setting mechanism at all**. Three candidate routes, named so
      Phase 7 does not restart from zero: (a) a **global `import.set_fields`** — wrong, it hits
      every import including bucket A; (b) a **post-import `beet modify albumtype=dj` followed by
      `beet move`** — two steps, works today, and `beet move` is already the proven instrument;
      (c) a **hook plugin** keyed on the source path. Pick one and prove it before routing DJ
      content through flask.
      **Attached to the same item: path rule 2 (`albumtype:=dj disctotal:2..`) has been evaluated by
      NO instrument** (DEF-06-12-01). It is the only rule in the committed `paths:` stanza in that
      state. Seven `dj-mixes` folders carry `disctotal = 2`. A rule that has never been evaluated
      is exactly where a `-1 - ` / `00-01` rendering defect hides — Phase 3 found one of those in
      the tagger this project retired. Deferred here **by explicit operator decision**, because
      reaching outside the drawn sample for a folder chosen *because* it carries the attribute
      under test is the hand-picking D-26 exists to prevent.

  E2. **Never route a folder to `bootleg` without first asserting `album` is populated and distinct
      across the intended groups.** The same button produced Phase 3's best and worst results purely
      on that condition, **with no UI signal either way**. `03-asis` is registered as an inbox but
      nothing was staged into it in Phase 6 (measured empty), so this gate is **untested** and its
      first real exercise is Phase 7's.

  E3. **The `rw` grant on the library is Phase 7's FIRST act (D-05)**, done deliberately and with
      the snapshot fence already in place — not discovered halfway through an import. Phase 6 held
      `/media` at `RW=false` for its entire duration and D-21's fenced write never fired.

  E4. **`tank/downloads@pre-phase5` is NOT released until Phase 7's pilot passes (D-32).** Phase 6
      wrote nothing, so it produced **no evidence that Phase 5's changes were correct**; only a real
      import exercises them. It is the only undo for Phase 5's 4,750 renames, 751 in-place tag
      writes and 26,005 chowns, and it is **not a clean undo** — a rollback discards everything
      every service has written to `tank/downloads` since 2026-09-18 15:42, which makes it an
      estate-wide decision rather than a music-project one.

  E5. **Repair `Def Leppard/Def Leppard (2015)/` (D-19a)**, plus any album directory plan 06-11
      reported in that shape. Related and separate: 30 of Jellyfin's 1,244 items carry a non-empty
      `Artists` string list and **zero** `ArtistItems` entities (all of `Lady Gaga/ARTPOP (2013)`,
      all of `Lady Gaga/Joanne (2016)`, and one Def Leppard track).

  E6. **CONF-04's Jellyfin half is OPEN and discharges here.** The option is set and asserted; the
      three pinned rows read 0/4, 1/2, 1/2 because `PreferNonstandardArtistsTag` is probe-time and
      nothing has re-probed them. Phase 7's first write or import of a multi-artist release is the
      discharge. **Two measurements to take at that moment**, both named rather than left as notes:
      whether Jellyfin's re-probe produces 4/2/2 entities, and whether a **second ≥4-artist track**
      yields four artists in Music Assistant or three — the only measurement that separates "MA caps
      the list at 3" from "`Twista` specifically failed to map", which a sample of one cannot.

      *Dispositioned separately 2026-09-24 by gap-closure round 5 (plans 06-40 … 06-45). The text
      above is deliberately NOT rewritten — it is the record of why this criterion exists. E6 names
      TWO measurements and **exactly one of them was driven**, so each now carries its own
      disposition and they must not be read as one:*

      **E6's FIRST measurement — whether Jellyfin's re-probe produces 4/2/2 entities — is STILL
      OPEN, and is now open on a DRIVEN NEGATIVE rather than on an untried mechanism.** Round 5
      pulled the lever 06-03 named and never pulled, inside Phase 6: three file mtimes touched from
      atlantis as real root inside the ZFS snapshot fence
      `tank/media/Music@pre-06-41-conf04-reprobe` (plan **06-41**), then the same targeted
      Default-mode `POST /Library/Media/Updated` at file scope — one write verb, HTTP 204 — and the
      measurement taken after a 19,597 s settle (plan **06-42**;
      `artifacts/06-42-conf04-reprobe-after.txt`, `artifacts/06-43-conf04-verdict.txt`). **ZERO of
      the three rows moved**: 0 against a target of 4, 1 against 2, 1 against 2, all AT-BASELINE,
      `;`-in-entity-name count 0, and an EMPTY 1,244-row census delta. It is a MEASUREMENT, not an
      UNKNOWN — the `LibraryMonitor` named all three Audio items, so the refresh ran and reached
      them, and `PreferNonstandardArtistsTag` re-read `true` afterwards. **Phase 7 should therefore
      NOT spend its first hour re-trying the mtime route: it is measured false for this estate at
      Jellyfin 10.11.11 (`DEF-06-45-02`).** The remaining untried mechanism is a genuine write or
      new import of a multi-artist release — Phase 7's own work. CONF-04's Jellyfin half is carried
      here under the operator's explicit `negative-carry-e6` override (2026-09-24T14:30:37Z), which
      is an **auditable carry of an OPEN requirement and not a close**; `REQUIREMENTS.md`'s box
      stays unticked.

      **E6's SECOND measurement — whether a second ≥4-artist track yields four artists in Music
      Assistant or three — is NOT CLOSED BY ROUND 5 AND REMAINS WITH PHASE 7, on every branch.**
      Round 5 never had it in scope, took no step toward it, and produced **no evidence bearing on
      it whatsoever**. It is the only measurement that separates "MA caps the list at 3" from
      "`Twista` specifically failed to map", and a sample of one cannot settle it. ⚠ **It did not
      go with the first measurement and must not be read as having done so** — that is the single
      easiest thing for a future reader to assume, which is why it is stated here in its own
      paragraph. The MA half's surviving `MA_REPORTED: 1` is a *reported measured discrepancy*
      owned by this measurement, which is why `scripts/check-music-consumers.sh` still exits 3 and
      why that exit code is **not** a CONF-04 completion signal. The two verdicts are never summed,
      and this second measurement is Phase 7's to take, unchanged and undischarged by round 5.

  E7. **DUPE-01 / DUPE-02 need a roadmap decision BEFORE this phase runs.** Phase 1 measured 828
      duplicate groups / 19.4 % duplication; Phase 3 re-confirmed `dj-mixes` is a byte-for-byte
      duplicate subset of `unsorted`, which makes Phase 7's diff join **last-wins** — a silent
      behaviour rather than a chosen one. It is not Phase 6's to fix, and it is the nearest unowned
      blocker to this phase, which is why it is named here.

  E8. **Every `%aunique{}` firing on plan 06-11's list is a known MA risk to verify (D-16).** MA's
      `missing_album_artist_action: folder_name` fires only when the album **folder** and the album
      **tag** agree and **silently falls back to `Various Artists`** when they do not — while
      `config/providers/get` still reads back `folder_name`, so the setting looks correct either
      way. An `%aunique{}` firing makes folder and tag differ **by construction**. Dropping the
      disambiguator is not the answer: that trades a *detectable* MA fallback for *silent* path
      collisions across 828 duplicate groups.

  E9. **Match-check ORDER, measured in plan 06-12: gate on `recommendation` → then track count →
      then per-track distance.** A track count matching exactly is **not** sufficient — `Vol 002`'s
      top candidate is a Finnish release with 30 tracks against 30 files and beets still refuses it
      at `recommendation: none`. Related: the library will grow both `Various Artists/` and
      `Various/` from the tags themselves (DEF-06-11-01), and `musicbrainz.search_limit` is the
      default **5** (DEF-06-12-02) — measure, per folder, whether the accepted candidate was in the
      first five, rather than raising it on one row's evidence.

  E10. **The D-04 exemption register is a PINNED BASELINE Phase 7 must revisit, not inherit**
      *(added 2026-09-22 by plan 06-21, carrying CR-01's residue)*. For the whole of Phase 6 the
      D-04 "no bare `beet` invocation" assertion **asserted over an empty set** and printed a green
      tick saying so — every invocation in this repo is built from a variable (`$BEET` /
      `$BEET_BIN`), so the literal-token pattern matched none of them, and the remote `git grep` was
      case-sensitive besides. Repaired by gap-closure plans **06-15** (the three real violations in
      `check-beets-config.sh` made compliant) and **06-16** (the pattern widened, executable count
      **0 → 8**, a vacuity guard so a zero count is UNKNOWN and fatal rather than a pass, and a
      **named** exemption register `D04_EXEMPT_RE` pinned at `D04_EXEMPT_BASELINE=5` covering the
      oracle's and the incremental control's overlay-only invocations). **What Phase 7 must do:**
      any new `beet` invocation it adds is either compliant (`-l` outside `/config/library.db`
      **and** `-c` overlay) or is added to the exemption register **deliberately, with its reason**.
      The pinned count moving is a **red by design** — do not raise the pin to make a run green;
      `D04_DOC_BASELINE` is at 2 and earned it, and 06-16 rephrased its own runbook prose rather
      than raise it. Two further residues ride with this: the block's **✅ green line is asserted by
      construction and has never been observed** (06-16 N-1), and the **overlay-key half** of the
      exemption regex is the register's weakest link and is undriven (06-16 N-4, `DEF-06-21-06`).
      Note also that the block reports **UNKNOWN on the live estate** until the operator pushes and
      the host pulls — correct, not a defect. The full finding set and what happened to each of the
      24 findings are in
      `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW.md` and
      `.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS.md`.

  E11. **Decide `import.write` deliberately, in the same commit as the `rw` grant (E3)**
      *(added 2026-09-22 by plan 06-21, carrying review finding WR-09)*. `import.write: yes` is
      live in the vendored `config.yaml` while `/downloads` is mounted **`:rw`** and the `01-auto`
      inbox is registered with **`autotag: auto`** under the beets-flask watchdog, which runs
      `restart: unless-stopped`. So any folder appearing under
      `/downloads/complete/nzb/_inbox/01-auto` is imported **without a prompt** by a config whose
      `import.write` is `yes`. The config names three controls — the `-c` overlay, the `:ro` mount
      (D-05) and the statefile sha256 (D-29) — and **none of the three protects `/downloads`**: the
      first two protect `/media`, the third protects beets' own state, and the overlay reaches only
      invocations *this phase's scripts* make, never the watchdog, which reads the vendored config
      directly. **What actually bounds it today** is that nothing automatic stages into `_inbox/`
      (SABnzbd lands in `complete/nzb/music/`, and plan 06-04 moved the two real folders to the
      unregistered `04-hold`) and that **`tank/downloads@pre-phase5` is un-released (E4)** —
      **"nobody has put a file there" is not a control.** Not fixed in Phase 6 because editing
      `config.yaml` changes the sha256 of the exact object every CONF-01 / CONF-02 / CONF-05 proof
      was measured against, plus the appdata copy the vendored-drift block compares — a dependency
      conflict with committed evidence, recorded in full as `DEF-06-21-01`. E3 is where every other
      Phase-7 behaviour flag is already scheduled to move; move this one with them.

  E12. **Four round-2 hardenings are FIXED but have never run for real, and the pilot is the first
      thing that exercises them** *(added 2026-09-22 by plan 06-29, carrying gap-closure round 2's
      residue; recorded in full as `DEF-06-29-05`)*. Round 2 closed all seventeen `GC-NN` findings
      in `06-REVIEW-GAP.md` — every one with a commit and a driven transcript — but four of those
      drives are over **synthetic fixtures or local shells**, because the only thing that would
      drive them for real is a `phase06-oracle.sh --run`, and a run **imports**. (a) The oracle's
      three destructive programs were **never executed, deliberately** — the fence *text* was
      driven 23 ways with a bare-glob mutant going red on 11 of 134 cases, and each program is
      asserted to begin with that exact text, but no `rm` has been observed declining to run. The
      reason not to drive it is the finding itself: if the fence regressed, the case would become
      `rm -rf /tmp/p6-x/../../../home`. (b) The fence predicate has **never run under the
      container's `dash`** — every case used the macOS `/bin/sh`. (c) GC-15's two `dex_cmd
      sha256sum` sites were driven **as constructed**, by capturing the command string and the argv
      a bash far side builds; the container never saw them, and a space-bearing `REAL_LIB_DB` is
      **predicted** (UNKNOWN + exit 3, because `awk`'s `$2` cannot key a whitespace path) rather
      than measured. (d) GC-05's verdict change — a vacuous D-15 or D-13 now exits **3 UNKNOWN**
      instead of **1 RED** — was driven through `run_assert` over synthetic fixtures; no real
      DJ-less or compilation-less sample has been through a live run. **What Phase 7 must do:** on
      the pilot's first `--run`, confirm both `layer3.before`/`layer3.after` parse and both `awk`
      keys match, that the fence refuses end to end under the container's dash, and that no
      `/tmp/p6-mf.*` or `/tmp/p6-taghist.*` survives. **All four fail CLOSED** — a wrong
      construction refuses a run that would otherwise proceed, never passes one that should fail —
      which is why they are residue rather than blockers. **Also riding here:** the live arm-1
      config dump has never been sized (`DEF-06-29-04`), so record `wc -c` of
      `$WORKDIR/arm1.dump` on the next live `check-beets-config.sh`; that number is the margin GC-01
      was measured against and it has never been written down. The full finding set and what
      happened to each of the seventeen are in
      `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP.md` and
      `.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP.md`.

**Plans**: 17 plans in 13 waves (planned 2026-09-25; revised the same day against cross-AI review round 1 — `07-REVIEWS.md`, all 15 CONFIRMED + 7 PLAUSIBLE findings — and again against round 2, all 16 CONFIRMED + operator-promoted P7R2-10 + PLAUSIBLE P7R2-18…20; 0/17 executed)

Plans:
- [x] 07-01-PLAN.md — evidence map registered before the run (D-31) + argued D-13 amendment of the `unsorted` rule
- [x] 07-02-PLAN.md — `diff-music-tags.sh` fails closed on an ambiguous join, both sides, driven on fixtures and real data (D-11, D-12)
- [x] 07-03-PLAN.md — `check-music-import.sh`, the criterion-7 sweep, fail-closed, folded into quick-health-check (D-25)
- [x] 07-04-PLAN.md — `route-dj-album.sh` (D-08) and its D-04 exemption-register entry, overlay-key half driven (D-27)
- [x] 07-05-PLAN.md — first real oracle `--run` before the grant (D-30), arm1.dump sized, DJ rule 2 asserted read-only (D-09)
- [x] 07-06-PLAN.md — the twelve named before the run: declared, seeded draw, frozen + appended expected tree (D-04..D-07, D-26)
- [x] 07-07-PLAN.md — per-album BEFORE capture, source manifests, D-24 census and consumer baselines
- [x] 07-08-PLAN.md — the ONE D-22 commit: rw for beets-flask + every flag and check that moves with it (D-21..D-23, C1..C10)
- [ ] 07-09-PLAN.md — GATED: two-dataset fence then the grant, first end-to-end quick-health-check (D-16, E3)
- [ ] 07-10-PLAN.md — GATED: P01 (Michael Jackson – The Essential) imported through 02-review and verified (D-10, D-20, D-29)
- [ ] 07-11-PLAN.md — GATED: P01 backed out with UNDO IMPORT on tree/DB/state.pickle, re-run equal; D-17 mechanical release (D-14, D-15, D-17)
- [ ] 07-12-PLAN.md — GATED: remaining bucket-A albums imported per album and verified
- [ ] 07-13-PLAN.md — GATED: the DJ pair imported and routed to DJ/ by D-08, DJ fields verified
- [ ] 07-14-PLAN.md — GATED: E5 Def Leppard repair as a named operation (D-24)
- [ ] 07-15-PLAN.md — GATED: Jellyfin first, one Music Assistant sync last; D-28, E6 second measurement (D-05), D-24 after
- [ ] 07-16-PLAN.md — GATED: project snapshot register + one-gate mechanical prune (D-19)
- [ ] 07-17-PLAN.md — GATED: evidence assembled for /gsd-verify 07 (no verdict), beets.md closure, operator trust verdict (D-31)
**Research**: not needed — the diff is a comparison over two `ffprobe` datasets, and the undo path
is ZFS rollback plus a documented `incremental` state reset. The compilation and multi-disc cases
are already covered by the Phase 6 config work; this phase runs them, it does not investigate them.

### Phase 8: Close the Inflow

**Goal**: A new download lands in an inbox and is tagged by the one worker that owns the library, so
working the backlog stops being a race against Lidarr — the thing that makes a backlog *feel*
unwinnable, which is what actually stops people.
**Depends on**: Phase 5 (the inbox must exist to move into), Phase 7 (never point new inflow at an
unproven pipeline)
**Requirements**: INGS-01, INGS-02, INGS-03, INGS-04
**Success Criteria** (what must be TRUE):

  1. SABnzbd's hook moves the finished folder into an inbox and exits, in seconds, with no tagging
     in the post-processing path. SAB post-processing is serial with no script timeout, so one
     wedged release stalls every job behind it and the failure presents as "the queue looks slow".

  2. The ingest worker's state survives a container restart and a host reboot, and re-presenting the
     same content is recognised as already seen — unlike today's `audio.bash`, which deletes its own
     database every run and so has no incremental import, no duplicate detection and no audit trail.

  3. A deliberately low-confidence release is routed to the review folder and is visible sitting
     there, named in a readable log. It is never silently skipped, and `quiet_fallback: asis` is not
     used to make the symptom disappear.

  4. A real new download requested through Lidarr completes end to end with no `skip` in the log and
     passes CONS-04: `ffprobe` on the file, visible in Jellyfin, visible in Music Assistant.
**Plans**: TBD
**Research**: `--research-phase` — SABnzbd hook semantics (serial queue, no script timeout,
detaching loses the exit code) and the notify/route design need working through. The naive version
is exactly what is failing today.

### Phase 9: Bucket A in Batches

**Goal**: The mainstream backlog moves into the library at a rate that finishes, in batches small
enough that stopping between them never leaves a half-imported state. Never scale an unproven
pipeline; this is the only phase that is purely throughput.
**Depends on**: Phase 7 (the pipeline proven), Phase 8 (the inflow closed)
**Requirements**: IMPT-03
**Success Criteria** (what must be TRUE):

  1. Each batch runs inside its own snapshot fence and is sized to finish in one sitting; no batch
     is left partly imported at the end of a session.

  2. The detection sweep runs after every batch and its findings are resolved before the next batch
     begins.

  3. A running album count is recorded per batch, and CONS-04 is spot-checked per batch rather than
     assumed to hold because it held in the pilot.

  4. A standing leak check shows no bucket-A content sitting in the library that the tagger's
     database does not know about.

**Entry criteria inherited from Phase 6** *(added 2026-09-21 by plan 06-14)*:

  E1. **beets-flask's inbox view is expected to go laggy past roughly a hundred folders, and batch
      cadence is the only mitigation (D-08).** Answered in Phase 6 as a **read, not a measurement**:
      rc6's schema exposes **no pagination, no page-size and no inbox-item-limit knob at all**, so
      the only levers are `gui.inbox.ignore` and how many folders are staged at once. **Phase 3's
      friction 5 therefore stays `NOT EXERCISED`** — nothing in Phase 6 put a hundred folders in
      front of the UI, so nothing in Phase 6 retired the risk. This phase's batch cadence is the
      first thing that makes it operationally real; size batches against it rather than discovering
      it mid-run.

  E2. **Every track in the *Now!* collection carries a per-file
      `LOCATION=https://www.discogs.com/…/release/NNNNNN` tag — a direct Discogs release id
      (D-28).** Discogs is the source Phase 3 chose. It is a potentially large disambiguation
      shortcut at batch scale and is **recorded, not acted on**: Phase 5's D-10 scoped its tag write
      to `album` alone, and Phase 6 neither used nor validated it. Validate it on a batch before
      trusting it.

**Plans**: TBD
**Research**: not needed — batch import is extensively documented and the traps are already captured.

## Beyond This Milestone

Real work, deliberately unscheduled so that "worth doing" cannot become "in scope". Not part of this
roadmap and not counted in coverage.

| Requirement | Area | Note |
|-------------|------|------|
| DUPE-01, DUPE-02 | Duplicate reconciliation | Must precede any import of `unsorted` — all 85 `dj-mixes` folder names collide with it and sizes differ in *both* directions, so neither side is authoritative. Quarantine, never `--delete`. **Amended 2026-09-25 (Phase 7, D-13):** the sentence above is kept visible rather than deleted; it now reads **"Must precede any BULK import of `unsorted`"**. The Phase 7 pilot's bounded draw — at most four folders from `music/` ∪ `unsorted/` (D-05/D-06), drawn by plan 07-06 — is the **named exception, and the only one**. *Why narrowing is safe here and nowhere else:* (a) the rule's risk model is Phase 9's wholesale 7,451-file import, where one bad duplicate call is unrecoverable at scale; (b) the pilot imports with `import.copy` inside a two-dataset snapshot fence (D-16), so its sources are untouched (criterion 8) and every landed album is individually reversible (D-14); (c) the control that replaces "reconcile first" for the pilot is **D-11**: `scripts/diff-music-tags.sh` classifies a matched `audio_md5` whose duplicate records carry differing tag maps as AMBIGUOUS and exits 3 UNKNOWN, on the BEFORE and AFTER sides, so a bad duplicate call cannot pass QUAL-02 silently; (d) **the exception is conditional** — it holds only while that AMBIGUOUS arm is present in the committed script (plan 07-02); if it is removed or regressed, the original rule applies to the pilot too. *What this does NOT change:* Phase 9's bulk import still requires the reconciliation first, and D-03 moves DUPE-01/02 into the archive phase inserted between Phase 8 and Phase 9 — that move is `/gsd-phase` work and is deliberately not made by this edit. |
| NOWB-01, NOWB-02 | Bucket B — the *Now!* series | A manual confirmation budget, not a config fix. `preferred.countries` is a distance weight, not a filter, and cannot beat a candidate that matches better on content. |
| LIDR-01 | Acquisition front end — replace Lidarr | Wanted, and captured here so it is not lost. Kept out of the milestone because Phase 1's WRIT-03 already removes the harm Lidarr does to *this* project: root folder off `/media/Music` and `renameTracks` off means it stops being a fifth writer, which is the only reason it appears in this roadmap at all. What remains is dissatisfaction with it as a grabber — a separate project with its own migration and its own indexer/import-list state. Folding it in is precisely how this milestone would stop finishing. |
| DJCC-01 – DJCC-05 | Bucket C — DJ content | Normalise field mapping, then Discogs, then cover scans; separate library root. The most interesting problem here, which is exactly why it is most likely to consume the project. Lowest-confidence area in the research — will need `--research-phase` when scheduled. |

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9.
Phase 2 has no dependency on Phase 1 and may be started alongside it; it must complete before
Phase 7. Plans within a phase run sequentially.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Safety Harness and Freeze the Writers | 9/9 | Complete | 2026-08-18 |
| 2. NFS Export and Music Assistant Reachability | 9/9 | Complete    | 2026-09-01 |
| 02.1. Jellyfin Transcode Retention *(inserted)* | 15/15 | Complete   | 2026-09-03 |
| 3. Tagger Spike | 11/11 | Complete    | 2026-09-04 |
| 4. Collapse to One Tagger | 16/16 | In Progress| All 16 plans executed (gap-closure 04-14/15/16 included); phase-level verification pending. Criterion 3 remains OPEN: across windows 1 and 2, five real music jobs all returned UNPROVEN `no-attributed-pre` — no PRE-HOOK snapshot is publishable while `direct_unpack` drains the tree — while every side-effect condition held for the third window running. 04-16 recorded `window 2: OPEN` under an interim-status heading in `beets.md`. Closing criterion 3 is now a decision, not a measurement |
| 5. Inbox Structure and the Junk Gate | 11/11 | Complete    | 2026-09-19 |
| 6. Tagger Configuration and Dry Run | 52/52 | In Progress| Original 14/14 closed 2026-09-21 with **1 open requirement: CONF-04 is OPEN on its Jellyfin half**, a named Phase 7 entry criterion (E6). Criteria 1, 2, 3 and 5 are TRUE and were all re-measured from live state at close, not carried forward from plan summaries. Criterion 4 carries two verdicts — Music Assistant discharged, Jellyfin pending a re-probe — which are recorded separately and **must never be summed**. `tank/downloads@pre-phase5` is NOT released (D-32, Phase 7 entry criterion E4). Closure: `stacks/selfhosted/arrs/beets.md` § *Phase 6 closed 2026-09-21*. **Gap closure 06-15..06-21 in flight since 2026-09-22** for verification gap CR-01; waves 6, 7 and 8 merged (06-15/06-18/06-20, 06-16/06-19, 06-17). **Two deferred operator consequences, both intended:** the D-04 block reports UNKNOWN on the live estate, and once this phase is pushed and the host pulls, `quick-health-check.sh` exits non-zero on the consumers block until E6 discharges CONF-04. Both clear on the same `git push` + host `git pull --ff-only` the vendored-drift block is already waiting on — operator's call; see 06-16-SUMMARY.md and 06-17-SUMMARY.md. **Gap closure dispositioned 2026-09-22 (plan 06-21):** `06-VERIFICATION.md` scored **5/6 must-haves**, the one failure being D-04's vacuous "no bare `beet` invocation" assertion; plans **06-15 through 06-21** closed it, and **all 24 findings** in `06-REVIEW.md` now carry an explicit disposition in `06-DISPOSITIONS.md` (**19 FIXED, 4 FIXED (undriven), 0 ACCEPTED, 1 CARRIED**). CR-01's residue and WR-09 are carried into Phase 7 entry criteria **E10** and **E11**. **This is a record, not a re-close:** no CONF-04 verdict, no requirement checkbox and no status wording changed — CONF-04's Jellyfin half is still OPEN and **E6** still owns the discharge **Gap closure ROUND 2 in flight since 2026-09-22** against `06-REVIEW-GAP.md` (GC-01..GC-17): waves 1-3 merged — 06-22 GC-01/GC-13, 06-23 GC-03/GC-16, 06-24 GC-02/GC-06, 06-25 GC-08, 06-26 GC-17/GC-14/GC-09, 06-27 GC-05/GC-15/GC-12/GC-07/GC-11, 06-28 GC-04/GC-10. GC-01 (the BLOCKER) and GC-03 are both closed and driven in both directions. **Round 2 COMPLETE 2026-09-22 (plan 06-29):** all four waves merged and **all 17 findings GC-01..GC-17 carry an explicit disposition** in `06-DISPOSITIONS-GAP.md` (**17 FIXED, 0 FIXED (undriven), 0 ACCEPTED, 0 CARRIED**, reconciling three ways to 17), with `06-REVIEW-GAP.md` wired to it, residue carried as `DEF-06-29-01`..`DEF-06-29-11`, and the undriven-until-the-pilot part owned by new Phase 7 entry criterion **E12**. Three corrections recorded rather than absorbed: the adjudication crossed **GC-15's label with GC-17's** (a reader following its summary line looks in the wrong file); **GC-16's BLOCKER justification was FALSE over a TRUE defect** (regraded WARNING); and the five UNVERIFIABLE rows are **not FALSE** — the evidence was never supplied to the reviewer, all five were later verified, and three proved *wider* than described. **Still a record, not a re-close:** 06-29 ran no `/gsd-verify` and claims no verification result; no requirement checkbox moved; CONF-04's Jellyfin half is still OPEN with **E6** owning it; phase remains NOT complete pending re-verification. **Round 3 COMPLETE 2026-09-23 (plan 06-34):** `06-REVIEW-GAP2.md` read round **2's** own changes across the four instrument scripts and found **0 Critical, 5 Warning, 5 Info** — no BLOCKER and no reproducible false green, stated explicitly rather than manufactured. Waves 14 and 15 merged — 06-30 R3-01/R3-05, 06-31 R3-02/R3-03/R3-04/R3-06, 06-32 R3-09/R3-10, 06-33 R3-07/R3-08 — and **all ten findings R3-01..R3-10 carry an explicit disposition** in `06-DISPOSITIONS-GAP2.md` (**9 FIXED, 1 FIXED (undriven), 0 ACCEPTED, 0 CARRIED**, reconciling three ways to 10: 0+5+5, 9+1+0+0, and 4 CODE + 3 CLAIM CORRECTION + 3 BOTH), with `06-REVIEW-GAP2.md` wired to it and residue carried as `DEF-06-34-01`..`DEF-06-34-06`. **No cross-family adjudication ran this round** — round 2 had one; the absence is stated so it does not read as a lost one. **The round's character: the dominant defect class was a claim broader than its code**, so each row carries a fix-kind and for several findings the honest fix was to narrow the sentence rather than widen the code. **Three refusals are recorded as loudly as the fixes:** the `/tmp/p6-mf.*` sweep (06-32), R3-08's third conjunct (implied by the other two, therefore vacuous) and wiring `assert_beet_invocation_contract` live (both 06-33). **What is NOT driven is recorded per finding** — the whole layer-3 block, the `SIGTERM` behaviour, and `quick-health-check.sh`, which was not executed at all; that residue attaches to the **existing** criterion **E12** and adds no new one. One correction in band: **R3-07's census figure was wrong and its finding is not.** **Still a record, not a re-close:** 06-34 ran no `/gsd-verify` and claims no verification result; no requirement checkbox moved; CONF-04's Jellyfin half is still OPEN with **E6** owning it; phase remains NOT complete pending re-verification, which is the verifier's call. **Round 4 COMPLETE 2026-09-23 (plan 06-39):** `06-REVIEW-GAP3.md` read round **3's** own 320-insertion diff at depth `deep` and found **0 Critical, 6 Warning, 4 Info** — again no BLOCKER and no reproducible false green. Waves 16 and 17 merged — 06-35 R4-01/R4-07/R4-08, 06-36 R4-02/R4-06/R4-09/R4-10, 06-37 R4-03/R4-04, 06-38 R4-05 — and **all ten findings carry an explicit disposition** in `06-DISPOSITIONS-GAP3.md` (**9 FIXED, 1 FIXED (undriven), 0 ACCEPTED, 0 CARRIED**, reconciling three ways to 10: 0+6+4, 9+1+0+0, and 3 CODE + 3 CLAIM CORRECTION + 4 BOTH), with `06-REVIEW-GAP3.md` wired to it and residue carried as `DEF-06-39-01`..`DEF-06-39-06`. **No cross-family adjudication ran this round either.** **The round's character: round 3's own centrepiece fix was round 4's largest finding** — `ST_PLANNED_CASES=134` is a constant pretending to be an invariant, printing "A SECTION DID NOT RUN" when every section ran on a `python3`-less or root box; re-measured to **140** with the reference environment named in band. And **a documented prohibition survived a second consecutive round inside the file documenting it**, the four survivors sitting eight to eleven lines *below* the prohibition itself. **⚠ ID ALIAS:** round 4's report reuses round 1's `WR-*`/`IN-*` namespace, already cited in band 72 times across the four scripts, so the fixes are cited as **`R4-01`..`R4-10`** and the mapping table is in the register — round 4's `WR-02` is `R4-02`, not round 1's. **Three refusals recorded as loudly as the fixes:** no cleanup `trap` added to `phase06-oracle.sh` (it has none by design and one would fire on the forensic `exit 3` arms), `ST_PLANNED_CASES=7` excluded from the count audit by name, and the four layer-3 copies not hoisted (`DEF-06-29-03`). **What is NOT driven is recorded per finding:** `quick-health-check.sh` executed **zero** times again, the layer-3 block still live-run-only, and the container-side signal behaviour **unobserved on both the SIGTERM and the new SIGPIPE path** — attached to the **existing** **E12**, no new criterion. Three corrections in band: 134 was already stale, the namespace collision, and **two self-referential-count instances that fired during round 4's own execution** — the fourth consecutive round for that hazard and the first to find it **inside the verify blocks** (`DEF-06-39-06`). **Still a record, not a re-close:** 06-39 ran no `/gsd-verify` and claims no verification result; no requirement checkbox moved; CONF-04's Jellyfin half is still OPEN with **E6** owning it; the phase is **not** declared complete. **⚠ `06-VERIFICATION.md` is STALE** — `status: passed`, `gaps_remaining: []`, dated 2026-09-22 against round 1, written before rounds 2, 3 and 4 existed — and was deliberately not touched; **`/gsd-verify 06` has not been run since round 2**. **Round 5 PLANNED 2026-09-23 (plans 06-40 … 06-45, waves 18–23, none executed yet):** `/gsd-verify 06` WAS re-run and scored **5/6** with CONF-04 the single failing truth; it offered two paths and **the operator chose a third — drive the Jellyfin re-probe now and close CONF-04 inside Phase 6.** The lever is the one 06-03's own artifact named and never pulled: change the mtime of **exactly three files** inside a ZFS snapshot fence, then issue the same targeted Default-mode `POST /Library/Media/Updated` 06-03 proved safe. ⛔ The aggressive per-item refresh mode stays FORBIDDEN and is unreachable from every branch; if the mtime route does not move the rows the planned outcome is a **recorded negative** and the two original options back to the operator. Criterion 4's own "It discharges on Phase 7's first write" is deliberately superseded by that decision. E6's **second** measurement — the ≥4-artist Music Assistant discrimination between "MA caps at 3" and "`Twista` specifically failed to map" — is **NOT** in round 5's scope and stays with Phase 7 on every branch. **Round 5 wave 18 EXECUTED 2026-09-24 (plan 06-40, the read-only half):** the complete before-state is committed as `artifacts/06-40-conf04-reprobe-before.txt` (1,810 lines, sections 0–9), and **every number the re-probe could move is now a recorded measurement rather than an impression**. Jellyfin 10.11.11; the Music `ItemId` read back **equals** the pinned constant; `PreferNonstandardArtistsTag` reads **`true`** and the three freeze fields **`false`**, so **round 5's premise is live**; the three pinned rows read **0, 1, 1** — the 2026-09-20 baselines, unmoved, so nothing needed escalating; the census is **1,244** with `TotalRecordCount` equal to the returned array length; the six OQ-1 `TRUSTFALL` DO-NOT-RESCAN rows are listed by name with their entity Ids. On disk, read from **atlantis as real root** (never LXC 100, whose sparse idmap distorts ownership): the three pinned files exist at `568:568` / `0777` with mtimes recorded to the second in UTC **and as epochs**, all **91** `.nfo` are hashed (Phase 1's number, unmoved) beside 944 `.lrc` and 88 `.jpg` counts and fingerprints, `tank/media/Music@pre-06-41-conf04-reprobe` is asserted **ABSENT** with `grep -qxF`, and `tank/downloads@pre-phase5` — the D-32 fence — is **PRESENT**. The touch list is **derived from `ARTIST_PROOF_ROWS` by prefix substitution, never retyped**, against a copy of `check-music-consumers.sh` whose sha256 was asserted byte-identical before parsing, and all six assertions plus an independent seventh (`grep -qF` against the script, sharing no code with the `awk` extractor) **PASS** — including `TRUSTFALL` substring count **0**. ⚠ **One measured correction to the plan's own text is recorded in band:** 06-40-PLAN.md asserts the Jellyfin container "is at 192.168.90.25 today" and that 06-03's `192.168.90.17` is stale; `docker inspect` returned **192.168.90.17** at run time. The *rule* — resolve fresh, never pin — is unaffected and is why the number is recorded as measured. `zfs get atime tank/media/Music` is **`off`** (relatime `on`), recorded so an atime-driven surprise in 06-42's `zfs diff` is anticipated rather than mysterious. **Nothing was written:** GET only, no snapshot taken, no permission changed, the snapshot set re-read twice and byte-identical each time, and all four scratch files deleted and verified absent. **Round 5 wave 19 EXECUTED 2026-09-24 (plan 06-41, the MUTATING half) — the lever 06-03 named and never pulled has been pulled.** The operator gate (`checkpoint:decision`) was presented with all six required items read out of the 06-40 artifact, its own verify measured the snapshot count at **0** immediately before presenting, and the answer was **`proceed`**. Then, in **ONE remote step on atlantis so the fence and the mutation could not come apart**: `zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe` returned 0 and was **listed back** and asserted equal before any file was touched; the touch list was **re-derived and all seven assertions re-run** (06-40 proved it against a tree that had since been snapshotted) from a copy of `check-music-consumers.sh` shipped over ssh STDIN from a quoted heredoc and sha256-asserted `1ed695cf…` **before** parsing — `TRUSTFALL` substring count **0**; the permission was **probed with its own no-op form** (`touch -r f f`, the same `utimensat` with no change) on all three before the real touch, so an `EPERM` would have been a recorded negative and a stop rather than a discovery mid-mutation; then **three mtimes moved and not one byte of audio did** — each mtime strictly newer than 06-40 Section 5's, each content sha256 **identical** to Section 9 (f), sizes unchanged. **`zfs diff` against the fence is the round's strongest control and came back clean: three `M` entries, zero non-`M`, exactly three distinct paths and all three pinned, zero metadata/lyric/image sidecars, zero DO-NOT-RESCAN rows** — both halves of the safety claim from one source, on a 33.9 GB dataset shared by Jellyfin, Music Assistant and the operator. Then **one write verb in the entire plan**: a file-scope `POST /Library/Media/Updated` with three `{Path, UpdateType:"Modified"}` entries built by `jq` from the derived list (nothing hand-escaped), returning **204** — and **Jellyfin's `LibraryMonitor` named all three Audio items by full internal path**, U+2019 included, **60 s later, matching `LibraryMonitorDelay = 60` exactly**. ⏱ The settle is a **subtraction, not a sentence**: `POST_UTC: 1790237579` was written immediately after the POST returned and the read-back began 1790237714, **135 s** later; 06-42 recomputes it from that epoch independently. **Zero** metadata-save, image-save or sidecar lines in the log window, recorded as the literal word `no`, and the four D-34 options plus `SaveLyricsWithMedia` were **re-read AFTER the refresh** with `has($k)` and all held (`PreferNonstandardArtistsTag` `true`, the other four `false`). The endpoint audit shows **exactly one line beginning with `POST`**; both prohibited scan endpoints are named descriptively only and `FullRefresh` counts **0** over the whole artifact. ⚠ **Two defects in this plan's OWN instruments are recorded rather than smoothed, and neither touched the estate:** the `zfs diff` path decoder ran a `sed` before `printf %b`, turning zfs's `\0040` into `\40` and eating a digit (`CD 01-03` → `CD 1-03`), which failed assertions (6b)/(6c)/(6d) over a block that was **correct from the first capture** — the three FAIL verdicts are **left standing and annotated in band**, with the corrected verdicts recomputed against a re-read proved byte-identical by `cmp -s`, so the repair is a read and not a second mutation; and that same overflow emitted **three NUL bytes** into the report, caught only because `file` said `data` rather than `text`. ⚠ **`grep` is shadowed by a shell function on the workstation and silently matched nothing** — every screen was re-run with `/usr/bin/grep`; and `grep -c $'\000'` / `awk index($0,"\000")` are **vacuous NUL tests** (the needle reduces to the empty string, matching every line), replaced by a byte-count across `tr -d '\000'`. ⚠ **The Jellyfin address in 06-41's own context is wrong again** — it says 192.168.90.25; `docker inspect` returned **192.168.90.17**, 06-40's measurement. Neither literal is transcribed as a constant; the route is resolved fresh every call. **⚠ `tank/media/Music@pre-06-41-conf04-reprobe` is now STANDING and is the only undo for this round — it must not be destroyed before 06-43 records its branch.** **What this does NOT establish, stated because 06-42 depends on it:** the refresh **started** and reached the three Audio items — the thing whose absence would make a null result uninterpretable — but nothing here shows the prober re-read the `ARTISTS` tag or that any `ArtistItems` row moved. That is 06-42's measurement, and a null result there is a **legitimate recorded negative**, not an argument for a wider refresh. **Round 5 wave 20 EXECUTED 2026-09-24 (plan 06-42, the MEASUREMENT) — the lever was pulled and IT DID NOT WORK, and that is the recorded result.** Two artifacts, 1,006 lines, three commits. **All three pinned rows read AT-BASELINE**: row 1 at **0** entities against a target of 4, rows 2 and 3 at **1** each against a target of 2 — the 2026-09-20 baselines, unmoved, with a `;`-in-entity-name count of **0** on every row. The verdicts are emitted twice, once as prose and once as a fixed eight-field `ROW` line ending in `verdict=`, and **every one survived independent recomputation** from its own `target`/`baseline`/`measured`/`uniqids`/`semis` by `check-music-consumers.sh` § 4b's own five-step order, so a misclassification would have failed a script rather than resting on the agent that wrote it. ⏱ The settle is arithmetic across two files as designed: `READBACK_UTC: 1790257176` minus 06-41's `POST_UTC: 1790237579` = **19,597 s** against a floor of 120, recomputed by the verify rather than read from the prose line. **The result is a MEASUREMENT and not UNKNOWN**, and that distinction is the round's whole value: 06-41's `LibraryMonitor` lines named all three Audio items, so "the refresh never started" is ruled out and "the refresh started and changed nothing" is what happened. `PreferNonstandardArtistsTag` still reads **`true`**, so the option did not revert — the prober simply did not re-read the tag. ⛔ **Nothing was escalated.** The aggressive per-item refresh mode was not issued, not widened to and not reachable; no second refresh, no additional file touched, no `zfs rollback` executed. **The four-way safety re-assert is clean and ends `SAFETY: PASS`:** the post-refresh `zfs diff` is **byte-identical to 06-41's block** (sha256 `a33ada4a…` on both sides, `cmp -s`) — three `M` entries, zero non-`M`, zero sidecars, zero DO-NOT-RESCAN rows, meaning that across the POST, the LibraryMonitor firing, the three refreshes and five and a half hours of live estate **ZFS records not one additional change under `tank/media/Music`**; the `.nfo` manifest differs on **0 of 91** lines in sha256 and mtime; all three sidecar counts and fingerprints are identical (**91 / 944 / 88**); the four D-34 options and `SaveLyricsWithMedia` all hold, read with `has($k)`; `library.db` and `state.pickle` are byte-identical and `tank/downloads@pre-phase5` is **PRESENT**. **The 1,244-row census delta is EMPTY — 0 changed rows, 0 differing lines over all five fields, no path on one side only** — and the six OQ-1 `TRUSTFALL` rows are unchanged in count and Id set, so the negative control held. That one block carries two facts and neither is softened into the other: nothing outside the three moved, **and the three themselves did not move**. **The independent corroboration was taken HERE, before any branch is computed** (relocated out of 06-44 by the round's own revision): the **deployed, unmodified** `check-music-consumers.sh` ran from `/mnt/fast/stacks` and reported `INSTRUMENT RUN: MEASURED`, `HOST CHECKOUT: MATCH`, `JF_AT_TARGET: 0`, `JF_PENDING: 3` (summing to the 3 pinned rows), `MA_AT_TARGET: 2`, `MA_REPORTED: 1`, ending on **3** with `FAILURES total: 0` — the pending gate, not the failure gate, exactly as the EXIT-CODE CONVENTION predicts, and **no line of any script was changed to make it end on 0**. Two instruments by two routes, one answer. ⚠ **Three deviations recorded rather than smoothed:** 06-40 records the `.lrc`/`.jpg` **fingerprint values but not the command**, so the recipe was **recovered against 06-40's own `.nfo` hash as an oracle** (four candidates computed, exactly one reproduced `e99b1992…`) — otherwise the comparison would have measured two constructions instead of the estate; **the host checkout went stale mid-plan by this plan's own two commits**, and the plan's own named remedy was applied (push, `git pull --ff-only`, re-run) rather than relaxing the test or writing `MEASURED` over a `STALE`; and **06-41's claim that the host's script copy is pre-Phase-6 (`c67d497`) with no `ARTIST_PROOF_ROWS` is measured FALSE** — the host copy is byte-identical to the repo copy, corrected in band so a later reader does not invent the forbidden copy step. **Still not a close:** no requirement checkbox moved, `06-VERIFICATION.md` was not touched and is **still stale**, and CONF-04's Jellyfin half is still OPEN. **06-43 owns what the negative means**, behind the operator gate, and `tank/media/Music@pre-06-41-conf04-reprobe` is still STANDING as the undo. **Round 5 wave 21 EXECUTED 2026-09-24 (plan 06-43, the VERDICT) — the round's outcome is now one machine-readable line, and the operator has chosen what it means.** One artifact, `artifacts/06-43-conf04-verdict.txt` (443 lines, SECTIONS L–P), two commits (`88857e3` the branch and the audit, `7775a3d` the operator decision). **The line is `BRANCH: B` — the mtime hypothesis is recorded DISPROVEN** — and it was **COMPUTED, NOT CLAIMED**: the plan's five-step rule was evaluated strictly in order against four recorded inputs, and the plan's own `<automated>` verify block **independently recomputed the same value from the same lines** and would have failed the task on disagreement. Rule 1 did not fire (`SAFETY: PASS`), rule 2 did not fire (`INSTRUMENT RUN: MEASURED`), rule 3 failed on **all three** conjuncts (AT-TARGET count 0 not 3, `JF_AT_TARGET` 0 not 3, `JF_PENDING` 3 not 0), and **rule 4 fired on all three**. SECTION L's `ROW` verdict block was **extracted by `sed` and spliced by `awk` over a placeholder rather than retyped**, then `diff`ed against 06-42's in the verify — so a transcription slip between the measurement and the verdict could not survive, U+2019 included. **⚠ THE EXIT CODE AND BOTH MA COUNTERS ARE RECORDED AND ARE EXPLICITLY NOT INPUTS**, and the artifact says so in the rule itself: `check-music-consumers.sh` exits **3 on branch A and branch B alike** because `MA_ARTIST_PENDING` stays 1 either way, and an exit code that cannot distinguish A from B cannot decide between them; a surviving `MA_REPORTED: 1` does not disqualify branch A, and a green MA half may never offset a pending Jellyfin one — the script's own point (c), applied at the one step where it would be easiest to break. **THE OPERATOR SELECTED `negative-carry-e6`** (recorded verbatim in SECTION P at **2026-09-24T14:30:37Z UTC**): option **(a)** of `06-VERIFICATION.md` § Recommended path — record the negative and **carry CONF-04's Jellyfin half to Phase 7 entry criterion E6 under an explicit override**, so this roadmap's existing argument becomes **auditable rather than implicit**. The branch-A acceptance option was neither offered nor selected on a `BRANCH: B`, so **no refusal is recorded, because none occurred**. **WHAT THE DECISION DOES NOT AUTHORISE, named so it is not inferred:** ticking CONF-04 (**the box at `REQUIREMENTS.md:152` STAYS UNTICKED** — an override is a recorded, argued carry of an OPEN requirement and must never be written as a close); re-scoring `06-VERIFICATION.md` to 6/6 (**`/gsd-verify 06`'s call**, which 06-45 *recommends* rather than performs — this plan set does **not** self-declare a pass); any further refresh, any wider refresh mode, or the aggressive per-item mode (**the hard fence is untouched by this decision and unreachable from it**); releasing either snapshot; or closing E6. **THE ROUND-WIDE AUDIT, mechanical and delimited:** 0 occurrences of the forbidden mode's literal token across **all five** round-5 artifacts, 0 occurrences of the forbidden UI button's phrase, **1 write verb for the entire round** (06-41's single file-scope `POST` → 204), **0 files changed content**, **3 files changed mtime**, and **both snapshots PRESENT** — `tank/downloads@pre-phase5` (D-32, E4) and `tank/media/Music@pre-06-41-conf04-reprobe`, the latter recorded as **STILL HELD, NOT RELEASED**, because its release is a **separate operator decision** deliberately not bundled into this gate. Each count carries the instrument that produced it. ⚠ **ONE DEFECT IN THIS PLAN'S OWN ARTIFACT, CAUGHT BY MEASURING AFTER THE EDIT LANDED AND RECORDED IN BAND:** the file **matched the detector it publishes** — SECTION O declared the forbidden UI button's phrase bracketed and published a count of 0, while the prose carried it **plainly twice** (in the hard-fence paragraph forbidding it, and in SECTION P's does-not-authorise list), so `grep -ciE` over the file returned **2** against a published **0**. The count over the four *source* artifacts was never wrong; what was wrong is that the file was itself an occurrence of its own detector. Both were rewritten to the bracketed form, an `in this artifact` audit row was added so the number is **asserted rather than assumed**, and the top paragraph now states why it brackets the phrase *even while forbidding it*. **Sixth consecutive round for the self-referential-measurement class (`DEF-06-39-06`)**, and the second consecutive round in which it was caught by a post-edit measurement rather than by a prior assertion. **⚠ E6's SECOND measurement is NOT closed by this round and stays with Phase 7** — whether a second ≥4-artist track yields four artists in Music Assistant or three, the only thing separating "MA caps at 3" from "`Twista` specifically failed to map"; round 5 never had it in scope and produced no evidence bearing on it. E5 is also named in the artifact: row 1 of `ARTIST_PROOF_ROWS` is one of the 30 items carrying a populated `Artists` list with **zero** linked entities, which is why a per-file refresh performing no artist-entity creation was always the weakest lever on that row. **Still not a close:** no requirement checkbox moved, `06-VERIFICATION.md` was not touched and is **still stale**, `stacks/selfhosted/arrs/beets.md` is untouched, and CONF-04's Jellyfin half is still OPEN — now with an **explicit, operator-signed override** carrying it to **E6**, which 06-44 and 06-45 write. **Round 5 wave 22 EXECUTED 2026-09-24 (plan 06-44, the INSTRUMENT'S PROSE) — the file now tells the truth about a verdict it earned on untouched code, and nothing else changed.** Two prose-corrected scripts, two commits (`646583a` `scripts/check-music-consumers.sh`, `8cac538` `scripts/quick-health-check.sh`), **no artifact and no estate contact** — no HTTP, no ssh, no write outside the repository. Five sites in the standing CONF-04 drift detector named **Phase 7 as the sole owner** of the Jellyfin half's discharge; each now states the round-5 truth — the mtime lever those very sentences named was **DRIVEN on 2026-09-24 inside a ZFS snapshot fence and measured NOT to discharge it** (ZERO of three rows moved, census delta empty, `PreferNonstandardArtistsTag` re-read `true`, so the refresh ran, reached the items, and the prober still did not re-read `ARTISTS`) — and the Jellyfin half is written as **CARRIED to E6 under the recorded override, never as closed**. **The verdict itself was NOT re-run here:** the instrument reached it in **06-42 task 3**, in wave 20, on untouched code and before the operator decided anything; the planning order was corrected for exactly that reason and this plan runs strictly downstream of the gate. **The mechanical proof that no logic moved, which is the whole point:** the changed-line audit over both diffs reports **0 lines that are neither a comment nor a printed message**, and **0 added `if`/`elif`/`case`/`EXIT_CODE=` lines**; all three `ARTIST_PROOF_ROWS` definitions survive verbatim with **both numeric columns**; the exit ladder is intact and in order (`--baseline` < `FAILURES` < pending < green banner, at lines 1699 < 1704 < 1732 < 1746); `EXIT_CODE=1` stays on the exit-3 arm; the `📊 6. Summary` anchor and the **7** `CONSUMERS_OVERRIDDEN` notices are unmoved; `shellcheck -S warning` is byte-identical to the pre-edit run on both files and `bash -n` is clean on both. **⚠ The exit code was deliberately NOT tuned** — the audit still exits **3** because `MA_ARTIST_PENDING` stays **1**, a reported measured discrepancy owned by **E6's SECOND measurement**, and it would have exited 3 on a fully successful re-probe too. **⚠ The baseline column is recorded in band as deliberately RETAINED**, so it is not tidied away once the target is met: after E6 discharges the Jellyfin half, a row back at its 2026-09-20 baseline is a **REGRESSION** (most likely `PreferNonstandardArtistsTag` reverting, which section 4a asserts independently), not a wait. **The cross-file contract was exercised, not assumed:** the rewritten exit-3 banner is 8 lines against `quick-health-check.sh`'s `sed -n '1,8p'` cap, so it was rendered locally with stub counters and pushed through that exact pipeline — all 8 lines survive, the `Discharges on ROADMAP` end anchor is still last, and **both halves are named inside the window a reader actually sees**; both files' accounts of the exit-3 contract were corrected in the same round, which is what stops the `GC-04` stale-citation class recurring. **`DEF-06-39-06`, seventh consecutive round, and CLEAN — measured AFTER the edits landed:** the forbidden mode's literal token and the forbidden UI button's phrase both count **0** in both scripts and **0** in this plan's SUMMARY, which writes both in bracketed form for that reason. Both scripts credential-screened before each commit (the repo is PUBLIC) with a NUL delta of **0 bytes** measured as `raw − tr -d '\000'`. **Still not a close, and this plan moved nothing:** `REQUIREMENTS.md:152` still carries an **unticked CONF-04**, `requirements mark-complete` was **not** run, `06-VERIFICATION.md` is untouched and still stale, `stacks/selfhosted/arrs/beets.md` is untouched, and both snapshots stay held with no `zfs rollback` executed. **06-45 owns the record edits, behind its own gate.** **Round 5 COMPLETE 2026-09-24 (plan 06-45, wave 23, the RECORD) — every document that carries a CONF-04 state now says the same thing, and that thing is the measurement.** Five documents edited, no code: `REQUIREMENTS.md`'s checkbox and its traceability row, this roadmap's Phase 6 criterion 4 and Phase 7 entry criterion **E6**, `06-VERIFICATION.md`'s gap record, `deferred-items.md`, and `stacks/selfhosted/arrs/beets.md`. **⛔ THE TICK GATE HELD AND THE BOX STAYS UNTICKED.** The gate was evaluated before any edit against three lines read independently — 06-43's `BRANCH: B`, and 06-42's `INSTRUMENT RUN: MEASURED` with `JF_AT_TARGET: 0` / `JF_PENDING: 3` — and a tick requires the conjunction `BRANCH: A` + `MEASURED` + `3` + `0`, which did not hold and was never close to holding. `REQUIREMENTS.md:152` still reads `- [ ] **CONF-04**`, `requirements mark-complete` was not run, and **the operator's `negative-carry-e6` override is written at every site as an auditable CARRY of an OPEN requirement and never as a close** — the one inference two upstream plans each flagged as the easiest for a downstream reader to make wrongly. **E6 now carries its two measurements separately and explicitly**, because exactly one of them was driven: its **first** measurement (whether Jellyfin's re-probe produces 4/2/2) is marked STILL OPEN with the driven negative recorded beneath it, so Phase 7 does not spend its first hour re-trying the mtime route; its **second** (whether a second ≥4-artist track yields four artists in Music Assistant or three — "MA caps at 3" versus "`Twista` specifically failed to map") is **NOT closed by round 5 on any branch and stays with Phase 7**, stated in words that cannot be skimmed past. **⚠ NO VERIFICATION VERDICT WAS SELF-DECLARED.** `06-VERIFICATION.md` keeps `status: gaps_found` and `score: 5/6` byte-for-byte; a dated `round_5:` sub-record and a `superseded_note:` were added stating in the frontmatter and again in the body that re-scoring is **`/gsd-verify 06`**'s call, that this plan performed no verification and claims no verification result, and that **`/gsd-verify 06` is the recommended next step** — the same discipline rounds 1-4 each held to, applied in the round that had the most reason to break it. This Status cell therefore stays **In Progress**: the plan counter reaches 45/45 and the phase's completion remains the verifier's call, not this plan's. **The round's residue is carried by name as `DEF-06-45-01` … `DEF-06-45-05`**, taking the register past 36 unique entries with nothing existing rewritten: the held snapshot `tank/media/Music@pre-06-41-conf04-reprobe` and the condition for releasing it; the disproven mtime lever recorded so the next attempt does not repeat it; the E5 hypothesis for why row 1 was always the weakest row (a populated `Artists` list with zero linked entities means "the prober re-ran" and "browseable artist entities exist" are two different facts); **a real defect in 06-43 SECTION O's published recipe `(O-a)` — `grep -cF "Full[R]efresh"` makes the brackets LITERAL, so it searches for the mitigation form and can never match the real token**, driven both ways against a control file (`-cE` → 1, `-cF` → 0) and left corrected-in-the-register rather than rewritten in the committed artifact; and the round's could-not-looks named as could-not-looks. **`DEF-06-39-06`, eighth consecutive round:** both forbidden tokens are written bracketed in all five edited documents and the counts were re-taken **after** each edit landed. Both snapshots stay held, no `zfs rollback` was executed, and no estate contact was made. **ROUND 6 (plans 06-46 … 06-52), 2026-09-24:** the full `06-REVIEW.md` round — 0 Critical, 3 Warning, 2 Info — dispositioned in `06-DISPOSITIONS-GAP4.md` as **4 FIXED, 0 FIXED (undriven), 1 ACCEPTED, 0 CARRIED**, reconciling three ways, under the fresh `R6-*` namespace minted up front because the review reuses round 1's `WR-*`/`IN-*` IDs (39 pre-existing in-band citations of the five reused IDs; 94 across the namespace). `R6-02 (WR-02)` — the comment-to-code ratio — is **ACCEPTED with reasoning and a measured self-binding claim** (one script file changed, +6/-1 lines, 0 lines of new in-band narrative), not fixed by a bulk strip of the provenance narrative on instruments that run against ~103 containers. `shellcheck -S warning` is now clean on **all six** scripts. **The status word stays `In Progress` and the plan count is the MEASURED executed count over 52, never 52/52**: `06-VERIFICATION.md` scores this phase `gaps_found` 5/6 and `REQUIREMENTS.md`'s CONF-04 box is unticked, so a `Complete` beside them is the false close this phase has spent six rounds refusing — do not "tidy" it. Per the operator's decision **`D-R6-M4`** this column means **executed**, not authored (the Phase 4 row is the precedent: it reads `16/16` with its status cell still `In Progress`, noted "All 16 plans executed"), so `06-52` task 3 at wave 5 closes the count and the `**Plans**: … waves` header as the round's last act. ⛔ `R6-08` (the host `git pull --ff-only`, plan `06-51`) and `R6-09` (the snapshot release go/no-go, plan `06-52`) had **not executed** when this clause was written at wave 3 and are recorded **PENDING with no outcome stated**; both plans are `autonomous: false` with legitimate halt/hold branches, and their outcomes land in `DEF-06-51-01` / `DEF-06-52-01` and the register's `ROUND CLOSE`. Round 6 performed **no CONF-04 work of any kind**, moved no checkbox, touched `REQUIREMENTS.md` not at all, and re-scored nothing.  **✅ ROUND CLOSE (plan `06-52`, task 3, wave 5, 2026-09-24):** both `autonomous: false` operator plans have now run and neither halted. `R6-08` **FIXED** — LXC 100 moved `ee82fb2` → `b9c09b5` on a `proceed` answer against a **CLEARED** pre-flight (S4, three stash entries, fired and was disposed of by the operator; **override = NO**), **6 of 6** instrument scripts sha256-MATCH per file where the pre-flight read 3 MATCH / 3 DIFFERS, nothing redeployed on all three of name/image/status (set difference empty both ways, 99 = 99); `DEF-06-45-05` item 2 and `DEF-06-29-11` **CLOSED**, `DEF-06-39-05` **unblocked but NOT closed** — `quick-health-check.sh` still run **zero** times across rounds 3-6. `R6-09` **CARRIED** — the operator answered **`hold`**, overruling the executor's `release` recommendation on the executor's own counter-argument that Phase 7's fence is *planned, not taken*; **nothing destroyed, rolled back or released**, the only `zfs` verb issued on any branch was `list`, `tank/downloads@pre-phase5` (E4) listed and untouched, and `DEF-06-45-01` stays OPEN with its release condition rewritten into one mechanical trigger — release when **Phase 7 Success Criterion 1 is satisfied**, a new snapshot taken on the Music dataset and rollback exercised, not when Phase 7 is planned. Also from `06-52`, independent of that decision: the stale *"`tank` has ~9 T free"* figure corrected to the measured **5.26 T** in both `DEF-06-45-01` and `CLAUDE.md` § Constraints, and `DEF-06-52-02` filed as a **process defect** — a criteria-only read of Phase 7's entry-criteria block would have answered "the pilot fence is not planned" **by omission** — promoted to `CONVENTIONS.md` convention 14. ⚠ **The `52/52` numerator was closed by `06-52` at wave 5 as its own last act**, so it counts this plan while this plan is still writing its completion; the one-plan overlap is stated rather than left silent. Detail in `DEF-06-51-01`, `DEF-06-52-01`, `DEF-06-52-02` and `06-DISPOSITIONS-GAP4.md` § ROUND CLOSE, whose Counts reconciliation is extended there from the five review findings to all nine round items. **Status word unchanged: `In Progress`** — `06-VERIFICATION.md` stands at `gaps_found`, 5/6, un-rescored; no requirement checkbox moved; `/gsd-verify 06` is the next step and the verifier's call, not a plan's. |
| 7. Pilot — 12 Albums End to End | 0/17 | Planned | - |
| 8. Close the Inflow | 0/TBD | Not started | - |
| 9. Bucket A in Batches | 0/TBD | Not started | - |

---
*Roadmap created: 2026-08-17*
*Revised: 2026-08-17 — QUAL-01…04 and TAGR-06 mapped (v1 now 39); Phase 3 gains the ergonomics axis
and beets-flask by name; Phase 7 rewritten around trust; LIDR-01 recorded under Beyond This
Milestone. No phases renumbered, no criteria removed.*
