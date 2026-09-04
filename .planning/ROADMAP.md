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
- [ ] **Phase 3: Tagger Spike** - One tagger *and* one front end chosen on numbers from this library's own content, against thresholds committed in advance
- [ ] **Phase 4: Collapse to One Tagger** - One tagger, one database, no idle container holding a rw mount — independently shippable
- [ ] **Phase 5: Inbox Structure and the Junk Gate** - A staging queue outside the library, with the junk already out of it
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

- [ ] 03-10-PLAN.md — beets-flask v2.0.0-rc6 evaluated by name, and the operator's timed five-album ergonomics trial (wave 7, blocking checkpoints)

**Wave 8** *(blocked on Wave 7)*

- [ ] 03-11-PLAN.md — The two-axis decision record, criterion 4's concrete answer, teardown and closure (wave 8, blocking checkpoint)

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

  5. Taken alone, this phase leaves the estate strictly better: one tagger, one `library.db`, zero
     read-write library mounts on non-tagger containers — checked and stated as an outcome, not
     assumed from the diff.
**Plans**: TBD
**Research**: not needed — retirement is deletion plus documented config changes.

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

  2. Searching the download tree returns zero `_FAILED_`, `_UNPACK_` or stray `.rar` items outside
     `99-quarantine`, and the Harry Potter BluRay rip is out of `dj-mixes`.

  3. The 45 GB `Now! 1-115` folder is split into per-volume folders, each independently importable
     and abortable, with the per-volume file counts summing back to the original count.

  4. No `_`-prefixed folder exists anywhere under `/mnt/tank/media/Music` — underscore names are
     fine in the staging tree because it is outside the library, and never inside it, because
     Music Assistant silently ignores them and Jellyfin does not.
**Plans**: TBD
**Research**: not needed — filesystem triage with documented traps.

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

  4. A multi-artist track separated with `;` shows its artists parsed correctly in **both** Jellyfin
     and Music Assistant — the one delimiter both consumers handle.

  5. Match disambiguation is demonstrated, not merely set: `preferred.countries` carrying `GB` (the
     code MusicBrainz actually stores; `UK` alone silently matches nothing, and entries are
     regexes), `preferred.original_year`, and `musicbrainz.extra_tags` — shown by a *Now!* volume
     preferring the UK release over the US one under `--pretend`, with the run confirmed to have
     written nothing (source and library file counts unchanged).
**Plans**: TBD
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
**Plans**: TBD
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
**Plans**: TBD
**Research**: not needed — batch import is extensively documented and the traps are already captured.

## Beyond This Milestone

Real work, deliberately unscheduled so that "worth doing" cannot become "in scope". Not part of this
roadmap and not counted in coverage.

| Requirement | Area | Note |
|-------------|------|------|
| DUPE-01, DUPE-02 | Duplicate reconciliation | Must precede any import of `unsorted` — all 85 `dj-mixes` folder names collide with it and sizes differ in *both* directions, so neither side is authoritative. Quarantine, never `--delete`. |
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
| 3. Tagger Spike | 9/11 | In Progress|  |
| 4. Collapse to One Tagger | 0/TBD | Not started | - |
| 5. Inbox Structure and the Junk Gate | 0/TBD | Not started | - |
| 6. Tagger Configuration and Dry Run | 0/TBD | Not started | - |
| 7. Pilot — 12 Albums End to End | 0/TBD | Not started | - |
| 8. Close the Inflow | 0/TBD | Not started | - |
| 9. Bucket A in Batches | 0/TBD | Not started | - |

---
*Roadmap created: 2026-08-17*
*Revised: 2026-08-17 — QUAL-01…04 and TAGR-06 mapped (v1 now 39); Phase 3 gains the ergonomics axis
and beets-flask by name; Phase 7 rewritten around trust; LIDR-01 recorded under Beyond This
Milestone. No phases renumbered, no criteria removed.*
