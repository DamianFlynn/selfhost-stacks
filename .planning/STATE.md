---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-09-01T10:01:18.885Z"
last_activity: 2026-09-01 -- Completed 02-06 (MA filesystem provider live, instance id pinned)
progress:
  total_phases: 9
  completed_phases: 1
  total_plans: 18
  completed_plans: 15
  percent: 83
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-17)

**Core value:** New music downloads land in the library correctly tagged, through exactly one
pipeline that someone owns.
**Current focus:** Phase 02 — nfs-export-and-music-assistant-reachability

**Definition of done (CONS-04):** a file is imported only when verified with `ffprobe` on the file
*and* visible in both Jellyfin and Music Assistant. Never "tool configured".

## Current Position

Phase: 02 (nfs-export-and-music-assistant-reachability) — EXECUTING
Plan: 7 of 9
Status: Ready to execute
Last activity: 2026-09-01 -- Completed 02-06 (MA filesystem provider live, instance id pinned)
Phase 1 complete: SAFE-01…05, WRIT-01…04, QUAL-01

Progress: [████████░░] 83%

Plans 02-01 through 02-06 are complete. Next is **02-07**, the deliberate `music/sync` and the
temporary export that serves the Various Artists proof album.

**The mount is LIVE and proven** (02-05). Route A won on measurement: a HAOS Supervisor NFS mount
named `music`, `state: active`, `read_only: true`, `user_path: /media/music`, fstype `nfs4` at
`vers=4.2` — and `/media/music` is readable **inside the running Music Assistant container**,
propagated `rslave` into a container that started two days before the mount existed. Music
Assistant's own documentation says that is impossible; it means *local bind* mounts.
**CONS-01 is COMPLETE** and **criterion 2 is proven at the export layer**: a hand-rolled
`mount -o rw` succeeded and every write was still refused `EROFS`, on NFSv3 *and* NFSv4.2.

**CONS-02 is COMPLETE (02-06). The provider exists and is pinned:**

```
instance_id                  filesystem_local--XJaJWNUS      <-- pinned in check-music-consumers.sh
domain                       filesystem_local   (Route A)
path                         /media/music       <-- NOT readable via the API; see below
content_type                 music              (read_only after setup — D-28)
missing_album_artist_action  folder_name        (default is various_artists — D-01, PERMANENT per D-02)
enabled / status / error     true / loaded / null
```

Created **entirely headlessly** (D-31): `config/providers/setup` → `config/flows/submit` →
`config/providers/save`. The GUI was never opened. `providers/manifests` is the command that lists
addable domains — `providers/available` does not exist.

**⚠ MA 2.11 does NOT expose the provider's `path`.** `config/providers/get` omits it entirely and
`config/providers/get_value {"key":"path"}` returns `Internal server error`. The path is proven
**functionally** via `music/browse "filesystem_local--XJaJWNUS://"`, which lists the 13 exported
artist directories. `02-06-SUMMARY.md` is the **only** record that the value is `/media/music`; a
rebuild must re-run the setup flow with it set explicitly, because the form's default is `/media`.

**MA's `check_write_access()` created nothing** across provider load, reload and a full initial
sync of 2,674 entries — T-02-19 closed on the real code path, not a synthetic probe.

**02-07 inherits exactly one red.** `check-music-consumers.sh` now exits **1** on a single failure:
the Various Artists proof album, `scope: temp-export`, which lives under `tank/downloads` and is
structurally outside this export. Everything else is green — sections 0, 1, 2, 4 and 5, with **20
albums attributed to `filesystem_local--XJaJWNUS`** and both library proof albums matched with
provider attribution confirmed server-side and client-side. Stage the VA album as
`Various Artists/Mastermix Essential Hits - Pop 4 - 2005-2009/` under the temporary export.

**Still not on LXC 100:** the script must be `scp`'d for every run — `git pull` there cannot land it
(commits `16a9fb2`/`6d4f8de`/`e1c4f93` are local-only; this tree is ahead 34 / behind 9 of origin).
**02-09 must resolve the push/pull.** Do not push 34 unreviewed commits to this public repo casually.

Before any Terraform work, read the CORRECTION entries under Blockers/Concerns — a bare
`terraform apply` was measured to be one command away from destroying LXC 100, and port 111 was
already open so only 2049 is this phase's delta.

## Performance Metrics

**Velocity:**

- Total plans completed: 9
- Average duration: ~42m (excluding 01-06's 374-minute observation window)
- Total execution time: ~375m of work

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 9 | ~375m | ~42m |

**Per Plan:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| 01-01 | 20m | 3 tasks | 1 file |
| 01-02 | 25m | 3 tasks | 1 file |
| 01-03 | 45m | 3 tasks | 2 files |

**Recent Trend:**

- Last 5 plans: 01-01 (20m), 01-02 (25m), 01-03 (45m)
- Trend: rising — 01-03 carried a 9,736-file measurement run, not just script authoring

*Updated after each plan completion*
| Phase 01 P04 | 55m | 2 tasks | 1 files |
| Phase 01 P05 | 35 minutes | 3 tasks | 10 files |
| Phase 01 P06 | 65m + 374m watch | 3 tasks | 3 files |
| Phase 01 P07 | ~40 minutes | 2 tasks | 3 files |
| Phase 01 P08 | ~35 minutes | 3 tasks | 2 files |
| Phase 01 P09 | ~55 minutes | 4 tasks | 5 files |
| Phase 02 P02 | 28min | 3 tasks | 3 files |
| Phase 02 P01 | 75m | 4 tasks | 3 files |
| Phase 02 P03 | 25min | 3 tasks | 2 files |
| Phase 02 P04 | 78min | 3 tasks | 1 files |
| Phase 02 P05 | 13min | 3 tasks | 1 files |
| Phase 02 P06 | 6min | 2 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: Harness before spike — every harness item is tagger-independent and several protect
  assets that cannot be recreated.

- [Roadmap]: Phase 2 (NFS/MA) runs in parallel from the start and must complete before Phase 7 —
  Music Assistant never purges stale entries, so it is proven before content flows, not after.

- [Roadmap]: Phase 4 (retirement) is independently shippable — a fourth stall must still leave the
  estate with one tagger, one database, no idle container holding a rw mount.

- [Revision 2026-08-17]: **The library is not empty, so "it imported" is not the bar — "it did not
  get worse" is.** QUAL-01 puts a re-runnable before-state tag snapshot in Phase 1, before anything
  is staged; QUAL-02 gates the pilot on a field-level before/after diff with no net metadata loss.
  A file can pass CONS-04 in full while having lost fields it arrived with.

- [01-09 / Phase 1 closure]: **Library ownership is `568:568`; modes stay `0777`.** `568` is `apps`
  (four independent repo references, 76% of 535,298 media entries); the gid it replaced, **545, is
  an orphan** — `getent group 545` returns nothing on atlantis. The `0755`/`0644` target is recorded
  but **not achieved**: `chmod` fails `EPERM` on `tank` even as real root. Phase 2's export must be
  read-only as a result.

- [01-09 / Phase 1 closure]: **Jellyfin's Music metadata freeze is permanent, and Jellyfin stays the
  documented sole `rw` holder rather than going `:ro`** — consumer-class, frozen at the application
  layer, counted in its own audit class. Measured limit: `SaveLocalMetadata: false` does not stop an
  explicit `FullRefresh`.

- [01-09 / Phase 1 closure]: **`quick-health-check.sh` can now exit non-zero**, and the freeze
  harness runs on it. The library **mode** assertion was scoped to a report inside
  `check-music-freeze.sh` — a permanently-red check trains the reader to ignore it, which is the
  failure the fold-in exists to prevent. Ownership stays a hard assertion.

- [01-09 / Phase 1 closure]: **`/mnt/tank/media/TV` — 114,218 entries on orphan gid 545 — is
  recorded, not actioned.** No requirement covers it, and scope growth followed by abandonment is
  this project's documented failure mode. Working method recorded in `beets.md` (run `chown` from
  the Proxmox host, never LXC 100).

- [01-09 / Phase 1 closure]: **Six times this phase a check reported a pass it had not earned**, all
  from the same root: partial data stated as settled. The rule now written into `beets.md` — verify
  with a second independent instrument before writing it down.

- [Revision 2026-08-17]: **Ergonomics is a scored axis in the Phase 3 spike, not a footnote**
  (TAGR-06). Two separate questions: which engine (beets vs wrtag) and how the human meets it (raw
  CLI vs a reviewable queue). beets-flask is evaluated by name on the second. The operator's
  first-hand experience is that beets has been painful to get working, and a painful tool is the
  documented cause of all three prior abandonments — so the second axis may decide whether this
  finishes more than the first does.

- [Revision 2026-08-17]: **The pilot must meet the hard shapes** (QUAL-03) — at least one
  various-artist compilation and one multi-disc release, both historically painful here. Twelve
  clean single-artist albums would prove a flow that has never faced the real case, and would leave
  CONF-03 / CONF-05 asserted rather than exercised.

- [Revision 2026-08-17]: **Undo is a pilot gate** (QUAL-04), not a nice-to-have. At Phase 9 scale,
  "I cannot cleanly back this out" is indistinguishable from abandonment.

- [Revision 2026-08-17]: Replacing Lidarr is wanted and recorded as LIDR-01 in v2, deliberately not
  in this milestone. WRIT-03 already stops it writing to the library, which removes the harm; the
  rest is a separate project with its own migration.

- [01-01]: zfs is not resolvable inside LXC 100 (unprivileged); harness zfs queries are delegated over ssh to the Proxmox host 172.16.1.158
- [01-01]: audit scripts exit 1 on any failed assertion, exit 0 only in --baseline mode; the estate had no such convention and its silence hid a six-week outage
- [01-01]: WRIT-04 is ~2x its assumed size — 2,543 of 2,673 library entries have the wrong owner and every file and directory is mode 0777, so D-13's chmod pass touches 100% of the tree
- [Phase ?]: [01-03]: audio_md5 (ffmpeg -map 0:a -c copy -f md5) is the QUAL-01/QUAL-02 join key; proven by a flat 2CD set where all 21 track numbers collide and neither path nor filename disambiguates the disc
- [Phase ?]: [01-03]: D-02 scope is 9,736 audio files and 170.12 GiB, not 9,764 and ~140 GB; plan 01-04 projects to ~36 min, CPU-bound on md5 hashing and single-threaded, so it can run attended
- [Phase ?]: [01-03]: the unsorted and dj-mixes copies of Now! 120 are the SAME rip - 20/20 audio_md5 shared, 0 unique to either side; first hard DUPE-01 measurement, covering 1 of the 85 shared folder names
- [Phase ?]: [01-02]: fence copies made with sqlite3 .backup are verified with PRAGMA integrity_check, not sha256 equality — the plan mandated both and they are mutually unsatisfiable; cover scans still held to strict sha256
- [Phase ?]: [01-02]: the Mac Mini's non-interactive ssh PATH lacks head/basename/sqlite3 — verification over ssh must use absolute tool paths and keep stderr, or it fails closed and reports false corruption (cost two false 'all 15 databases bad' results)
- [Phase ?]: [01-02]: '794 dj-mixes files' is wrong — there are 764 audio files; the 794 figure was 764 audio + 30 jpg and missed the 24 BMP cover scans entirely
- [Phase ?]: 01-05: Photos gets no mount in any narrowed container — only Jellyfin retains it via its D-21 carve-out; containers able to reach it went 8 -> 1
- [Phase ?]: 01-05: wrtag frozen via 'compose --profile manual down'; a plain 'compose up -d' on the music stack now returns 'no service selected' — the gate is proven, not asserted
- [Phase ?]: 01-05: lidarr deliberately untouched (01-06 owns WRIT-03), so it is the single remaining rw holder in BOTH audit classes — expected, not a regression
- 01-06: WRIT-03 met — lidarr root folder off the library, renameTracks off, all metadata consumers off (already were), media mount :ro proven by an in-container write attempt; tagger-class rw holders on the library is now 0
- 01-06: deleting an *arr root folder does NOT repoint its artists — all 22 lidarr artists keep absolute /media/Music paths, so D-25's :ro mount is the load-bearing control, not D-23's root-folder move
- 01-06: SaveLyricsWithMedia is a THIRD Jellyfin write switch that SaveLocalMetadata does not gate; it wrote 944 of the 1,123 baseline sidecars. Any "is Jellyfin frozen?" check that reads only SaveLocalMetadata gives a false pass
- 01-06: lidarr had a DELETE path into the library (mediamanagement.deleteEmptyFolders: true) that WRIT-03 and D-24 do not count as a write path; now false
- 01-06: the SAFE-05 sidecar set is widened to .nfo/.jpg/.lrc/.png/.txt — 1,341 files, 19.4% more than D-18's 1,123; the narrow subtotal is still printed for comparability with the 01-01 baseline
- 01-06: **the SAFE-05 test as the roadmap words it is a path-set diff, and a path-set diff is structurally blind to the most likely form of Jellyfin pollution.** Measured: it returned 0 added / 0 removed while Jellyfin rewrote 83 of the library's 91 .nfo in place, 66 with genuinely changed content. Widening the extension set does NOT fix this — the comparison had to change. The watch now checks sha256 content, a whole-library size/mtime manifest, and a ZFS snapshot cross-check
- 01-06: **SaveLocalMetadata=false does NOT stop an explicit Jellyfin FullRefresh writing .nfo.** It gates the automatic scan-time save path only. The first .nfo was rewritten 1 second after the refresh POST, with the setting already false and read back from the API. SAFE-05 is true for "Jellyfin writes nothing unprompted" and FALSE for "Jellyfin cannot write" — a UI "Refresh metadata" click still writes. The only structural control would be an :ro mount, which D-21 deliberately rejected
- 01-06: the @pre-project ZFS snapshot was used in anger and works — SAFE-02 proven, not asserted. `snapdir=hidden`, so `/mnt/tank/media/Music/.zfs/snapshot/pre-project` must be typed; it will not list
- [Phase ?]: There are five beets configs in the estate, not three — beets' scrub/lastgenre/embedart/fetchart auto keys all DEFAULT to on, so an absent key was an armed key
- [Phase ?]: appdata/arrs/beets/config/config.yaml is a docker-compose file saved into BEETSDIR — beets ran on pure defaults and imported 47 tracks into /config/Music/__/
- [Phase ?]: find -xdev is unsafe for estate sweeps: /mnt/fast/appdata/* are separate ZFS datasets, so a sweep from /mnt/fast silently skips appdata and exits 0
- [Phase ?]: 01-08: the WRIT-04 chown must run on the Proxmox host - LXC 100 is unprivileged and physically cannot chown the library's unmapped uids/gids (EPERM, a different mechanism from aclmode=restricted with the same errno)
- [Phase ?]: 01-08: the 01-01 ownership census recorded the CONTAINER's view, not the disk - six on-disk owners collapse to five, and its writer attributions are wrong
- [Phase ?]: 01-08: D-11's 568:568 confirmed on evidence - Music was the only media subtree on gid 545 while Movies was already 568:568, so beets.md's 568:545 describes drift and D-14 stands
- [Phase ?]: 01-08: mode pass skipped with a printed explanation rather than run or swallowed; no zfs set of any property was executed
- [Phase ?]: 01-08 CORRECTION: gid 545 is NOT Music-specific - TV carries 114,218 entries on the same orphan gid (48x Music). The estate is split: Music+TV on 545, Photos+Movies+Books on 568. D-11's 568:568 still stands, but because 545 is an orphan gid (no group entry, unmapped in the LXC idmap) and 568 is the documented convention - not because Music was uniquely wrong
- [Phase ?]: 01-08: uid 3000 owns 197,776 of tank/downloads' 209,039 entries (94.6%) - the download client's identity, and the same uid as the library's .DS_Store; resolve before Phase 5 stages _inbox there
- [Phase ?]: 02-02: NFS music export defined in Terraform (infra/nfs-music-export.tf) - ro,all_squash,anonuid/anongid interpolated from var.apps_uid/gid, mountpoint, no_subtree_check, sec=sys, to 172.16.1.31 only; fsid=, crossmnt and no_root_squash absent with recorded reasons
- [Phase ?]: 02-02: xprtsec= (RFC 9289) and sec=krb5 considered and rejected in the file header; sec=sys on a trusted LAN recorded as an accepted residual risk
- [Phase ?]: 02-02: temporary control export is count-gated on music_temp_export_enabled (default false) - teardown is a terraform apply, not a memory
- [Phase ?]: 02-03: NFS export APPLIED and live — ro,all_squash,anonuid=568,anongid=568,mountpoint to 172.16.1.31 only; re-apply exit 0; served from atlantis, LXC 100 proven unable (unprivileged)
- [Phase ?]: 02-03: M1 (mountpoint export option) is NOT enforced at exportfs time on nfs-utils 1:2.8.3-1 — exportfs -au + -a silently re-creates the line while the dataset is unmounted. Configured-but-UNPROVEN; M2 (After=zfs-mount.service) is the proven guard; 02-05 must settle it client-side
- [Phase ?]: 02-03: CONS-01 deliberately NOT ticked — criterion 1 parts 1d/1e need a client and belong to 02-05; traceability row records the interim state
- [Phase 2]: 02-04: MA 2.11 has no API-token UI — check-music-consumers.sh logs in per run rather than caching the 90-day JWT, so the credential cannot expire silently inside an unattended check (D-39 intent, not its literal 365-day wording)
- [Phase 2]: 02-04: music/albums/count has NO provider parameter (returned 87 with and without one) — mount liveness uses provider-filtered music/albums/library_items instead; count would report green off Spotify's catalogue with the NFS mount absent
- [Phase 2]: 02-04: D-08 fired — the library has no Various Artists compilation (all 13 folders are single named artists), so the VA shape is substituted by VA-Mastermix.Essential.Hits.Pop.4 from the backlog, staged by 02-07 under the temporary export
- [Phase 2]: 02-05: ROUTE A WINS on measurement — /media/music is readable INSIDE the running Music Assistant container (rslave, master:1105, container up 2 days before the mount existed). MA's own docs say this is impossible; they mean local bind mounts. Route B's failure symptom: it exposes no client-side ro option at all
- [Phase 2]: 02-05: CRITERION 2 PROVEN AT THE EXPORT LAYER — a hand-rolled mount -o rw succeeded and every write was still refused EROFS. Re-run over NFSv4.2 because the plain mount -o rw negotiated vers=3, which is NOT the version MA reads through. Read-only holds on both
- [Phase 2]: 02-05: CONS-01 is COMPLETE — 1d proven by nc 2049 exit 0 plus a successful mount (showmount is absent on the NUC), 1e by /proc/self/mountinfo fstype nfs4 vers=4.2 (findmnt is absent too)
- [Phase 2]: 02-05: ssh -n EATS A HEREDOC — -n points stdin at /dev/null so 'ssh -n host bash -s <<EOF' discards the whole script and exits 0. Use -n for inline 'ssh host cmd' ONLY; never when feeding a script over stdin
- [Phase 2]: 02-05: the NFSv4 pseudo-root entries in /proc/fs/nfsd/exports carry no_root_squash (/, /mnt, /mnt/tank, /mnt/tank/media — all v4root and ro). Not a T-02-06 regression, but a grep of that table returns 4. Assert on exportfs -v, which check-music-consumers.sh already does
- [Phase 2]: 02-06: missing_album_artist_action=folder_name on the MA filesystem_local provider is PERMANENT (D-02), not a pilot setting
- [Phase 2]: 02-06: the MA provider was created entirely HEADLESSLY via config/providers/setup + config/flows/submit + config/providers/save (D-31); the GUI was never opened
- [Phase 2]: 02-06: MA 2.11 does NOT expose the filesystem provider's path via config/providers/get; /media/music is proven functionally via music/browse and recorded only in 02-06-SUMMARY.md

### Pending Todos

- ~~01-06 Task 3 — the SAFE-05 watch~~ **PASSED 2026-08-18T20:54:49Z**, 374 minutes elapsed. All
  four content-aware gates zero: sidecars added 0, removed 0, content-changed 0, whole-library stat
  delta 0. `zfs diff` returned exactly one line — a permission probe from the `aclmode`
  investigation whose `ctime` moved while sha256, size, mtime, owner and mode stayed identical
  across live, `@safe05-watch-t0` and `@pre-project`. Independently re-run and reproduced.

- ~~01-06 open question: restore the 66 changed `.nfo`?~~ **DECIDED: no.** They are Jellyfin's own
  current metadata rather than damage, both ZFS snapshots hold the originals indefinitely, no audio
  file was touched, and restoring would mean writing into a library this phase just finished
  sealing in order to undo a write.

- **Decision recorded: the SAFE-05 window was kept QUIET on purpose.** `RefreshLibrary` was
  deliberately not triggered. Since an explicit `FullRefresh` is now *known* to write, an "active"
  window would be provoking the failure rather than testing the claim. The quiet result proves what
  SAFE-05 can honestly support — nothing writes unprompted — and the explicit-refresh hole is
  recorded beside the pass, not behind it.

### Blockers/Concerns

- **v1 is now 39 requirements** (was 34; earlier the header wrongly said 33). Arithmetic checks
  both ways: by category SAFE 5 + WRIT 4 + CONS 4 + TAGR 6 + CONF 6 + INBX 3 + QUAL 4 + IMPT 3 +
  INGS 4 = 39; by phase 10 + 3 + 3 + 3 + 3 + 6 + 6 + 4 + 1 = 39. No requirement is unmapped and
  appears twice.

- **Ordering hazard: QUAL-01 must complete before Phase 5 stages anything.** Once content is moved
  into the inbox or imported, the before-state can no longer be recovered and Phase 7's diff has
  nothing to compare against. This is now an explicit dependency on Phase 5.

- **Phase 2 route unresolved:** HAOS `/media` mount vs Music Assistant's own remote-share provider.
  Primary sources contradict each other. Both routes need the same NFSv4 export, so the export is
  built first and the empirical test discriminates afterwards. Route B must be pre-specified in the
  plan so a FAIL does not stall the phase.

- **Phase 3 drift risk:** the spike must carry pre-committed overturning thresholds and a
  ~20-folder normalisation pre-step, or the Discogs number is invalid and the phase becomes tool
  advocacy.

- **Abandonment is the dominant risk, 3-for-3 historically.** Leading indicator: more than ~10 days
  since the last import ran. All three prior deaths look identical at day 10. The revision attacks
  this directly on two fronts: TAGR-06 makes "will I actually still open this in week six" a
  recorded spike output, and QUAL-04 makes a clean undo something proven at pilot scale rather than
  hoped for at backlog scale.

- ~~SAFE-05 blind spot (found in the 01-01 baseline): the library holds 43 .png and 175 .txt files outside D-18's .nfo/.jpg/.lrc sidecar definition.~~ **RESOLVED 2026-08-18 by 01-06** — `check-music-freeze.sh` section 5 now inventories `.nfo/.jpg/.lrc/.png/.txt` (1,341 files) and prints the narrow D-18 subtotal (1,123) alongside it so the widening stays auditable against the 01-01 baseline. `.DS_Store` is counted separately.

- ~~**BLOCKER for 01-08**~~ **RESOLVED by scoping (`b02dfb7`): D-12 is out; 01-08 delivers the
  ownership half of WRIT-04 only, its Task 2 is a confirmation rather than a mode-change pilot, and
  `zfs set aclmode=passthrough` is explicitly rejected. The finding itself stands and still governs
  Phase 2.** — `chmod` is impossible anywhere on `tank`. `tank/media`, `tank/media/Music`
  and `tank/downloads` all carry `acltype=nfsv4` + `aclmode=restricted` + `aclinherit=passthrough`.
  Every child inherits a non-trivial NFSv4 ACL, and `restricted` makes `chmod` on a non-trivial ACL
  return `EPERM` — **as root, for every mode, including a no-op `chmod 0777` on a file already at
  0777.** Measured directly during 01-06. Consequences:

  - **D-12/D-13's mode normalisation (87 dirs → 0755, 2,586 files → 0644) cannot be done with
    `chmod`.** `chown` is unaffected and still works, which is why 01-08 keeps the ownership half.

  - It explains 01-01's "every entry is mode 0777 with no exceptions" — nothing can change them.
  - It is the same root cause as PROJECT.md's documented `rsync -a` failure
    (`mkstemp ... Operation not permitted`).

  - Phase 2 inherits it: knfsd does not export NFSv4 ACLs, so mode bits are all an NFS client sees,
    and mode bits currently cannot be set below 0777.

  - Routes considered: (a) `zfs set aclmode=passthrough|discard` on the datasets, (b) install
    `nfs4-acl-tools` (absent on LXC 100 and on the Proxmox host), or (c) accept 0777 and drop D-12.
    **(c) was chosen** — 01-06 deliberately changed nothing and escalated; the user reproduced the
    result independently and scoped D-12 out in `b02dfb7`, explicitly rejecting (a).

- 01-06: a `.DS_Store` owned `65534:65534` sits in the library root — a macOS client has write access
  over a share. It is an uncounted writer that no container mount audit and no Lidarr or Jellyfin
  setting can close, and no current requirement covers it. The harness now counts it every run.

- 01-06: the fenced `jellyfin-jellyfin.db` carries an `ApiKeys` table with 4 admin-scoped rows. It is
  mode `0600` rather than the fence's usual `0644`. If `library-db/` is copied off-box again under
  D-07, those credentials travel with it.

- ~~01-02 task 3 blocked at checkpoint: off-box copy to the Mac Mini (D-07)~~ **RESOLVED 2026-08-18** — operator copied library-db/ (15) and cover-scans/ (54) to `data@datas-mac-mini:~/archive/music-pre-project`, verified 54/54 sha256 + 15/15 integrity_check. Left in place as a hazard note: that host's non-interactive ssh PATH lacks `head`/`basename`/`sqlite3`, which produced two false "all 15 databases corrupt" results before absolute tool paths were used.
- 01-03: a duplicated audio_md5 makes the diff join last-wins, so in Phase 7 (BEFORE holds both backlog copies, AFTER holds one import) tag differences between duplicate sources are invisible. DUPE-01 should be resolved before QUAL-02 is treated as complete. The diff always lists such pairs in its informational section.
- 01-03: unsorted WAV content is NOT tag-free - all 40 sampled Now! 120 WAV records carry 6 format tags (title/artist/album/track/date/comment) plus an embedded cover-art stream. Plan 01-04 and Phase 7 must not assume an empty before-state for unsorted's 134 WAV files.
- 01-07: the manual beets container is NOT inert — its BEETSDIR config.yaml is a docker-compose file, so beets ran on defaults and left 47 items / 1.4 GB of WAV in /config/Music/__/. Phase 4 must account for it, plus a fifth latent entry point at beets/config/beets.sh.
- OPEN/UNOWNED: /mnt/tank/media/TV is 114,218 entries on orphan gid 545, the same gid 01-08 normalised Music away from. Out of scope, no requirement covers it, and it will hit the identical chown-from-LXC-100 EPERM. Leaving Music and TV divergent may be worse than leaving both wrong.
- ~~BLOCKING 2026-08-31 (02-01 Stage 0): atlantis is mid-incident on the documented amdgpu_hmm_invalidate_gfx NULL deref~~ **RESOLVED 2026-08-31 18:48:08** — rebooted via sysrq s+b; io pressure full avg300 96.22 -> 0.59, zero amdgpu_hmm_invalidate_gfx events this boot, taint 4225 (P+D+O) -> 4097 (P+O), both zpools ONLINE, 102 containers running, LXC 100 sshd normal. Root cause was NOT compaction: a Jellyfin VAAPI transcode started 07:56:56 and the kernel oopsed at 07:56:58. VAAPI disabled (encoding.xml HardwareAccelerationType=none, backup encoding.xml.bak.20260831T182741Z, scripts/disable-jellyfin-hwaccel.sh, commit b1ad9c1). **The correction that survives:** the July 2026 mitigation (THP=never + vm.compaction_proactiveness=0) was fully applied and did NOT prevent the recurrence, so the project-memory entry reading as "resolved" is wrong and should be corrected to name VAAPI as the trigger.
- BLOCKING for 02-06/02-07 (02-01 Task 3): the estate runs **Music Assistant (BETA) 2.11.0b0**, slug `d5369777_music_assistant_beta`, `auto_update: true`. The **stable add-on is not installed at all**. D-21 requires the phase be proven against stable — that cannot be satisfied as written. Operator must choose: install stable alongside, migrate off the BETA, or accept the BETA and stamp every criterion `2.11.0b0`. Auto-update on a beta channel means the stamped version can move before Phase 7. Does NOT block 02-03 (server-side only).
- BLOCKING for 02-06 (02-01 Task 3 measurement 5): D-30's provider enumeration is **unmeasured**. MA has an admin account (`onboard_done: true`; `auth/login` returns "Invalid username or password") but **no credential for it is recorded anywhere** — not `~/.claude/secrets/`, not `/mnt/fast/secrets/` on LXC 100. MA 2.11 gates `config/providers` behind scope `config.providers.read` and exposes only five unauthenticated commands. Three off-ramps measured closed: no `/addon_configs` entry for MA, no docker socket in the SSH add-on, `homeassistant` login provider `requires_redirect: true`. Obtain the credential and mint the D-39 token BEFORE adding any provider, so the baseline is taken against an untouched library.
- CORRECTION for 02-03 (02-01 Task 2): **never run a bare `terraform apply`.** The D-17 gate returned exit 2 with `Plan: 2 to add, 1 to change, 1 to destroy` and `proxmox_virtual_environment_container.selfhost must be replaced` — that is LXC 100, the Docker host with ~102 containers. Cause was a bpg/proxmox 0.95.0 artefact (33 mount_point blocks diffing `mount_options = [] -> null`, each forces-replacement) plus one real drift (`mpe_memory_mb` 20480 vs a host running 8192). Remediated in 1588f19 + 3051695; bare plan is now 1 add / 0 change / 0 destroy with zero forces-replacement. 02-03 must `terraform plan -out=`, read it, assert exactly `null_resource.nfs_music_export` and zero destroys, then apply the saved plan.
- CORRECTION for 02-04 (02-01 Task 3 measurement 6): **Jellyfin's t3_proxy address is 192.168.90.25, not the 192.168.90.31 pinned in 02-01 and 02-04** — the pin is wrong today, not merely fragile. Two further traps: the bare Docker DNS name `jellyfin` resolves to **Cloudflare's public edge** from the LXC 100 host because of `search deercrest.info` in /etc/resolv.conf (a health check would silently pass against the public site while the container was down), and `172.16.1.76` is unreachable from LXC 100 by macvlan host-to-container isolation despite working from the LAN. Use runtime resolution: `docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'` — verified 200, no IP literal.
- CORRECTION for 02-03/02-05 (02-01 Task 3 measurement 7): **`showmount` and `findmnt` are both ABSENT on the NUC.** `nfs-music-export.tf`'s `verify_commands` output suggests `showmount -e 172.16.1.158` "from the HA NUC" — that line will not run; use `exportfs -v` on atlantis. Criterion 1e's `findmnt` proof of NFSv4 negotiation needs `/proc/self/mountinfo` instead (verified readable from the SSH add-on; its fstype column is where `nfs4` will appear). `sha256sum` and `nc` ARE present, so D-11's read-through hash is sha256.
- LATENT, suppressed not fixed (02-01 Task 2): `bpg/proxmox 0.95.0` plans a replacement for any container carrying `mount_point` blocks. `ignore_changes = [mount_point]` now silences it on both LXC resources, which means **real bind-mount edits to lxc-selfhost.tf / lxc-mpe.tf will plan clean and do nothing**. Bind-mount changes are a deliberate manual act (`pct set` / edit `/etc/pve/lxc/<vmid>.conf`, then reconcile) until the provider is upgraded. Trade-off documented in both files.
- 02-05 MUST re-test M1 from the client side: the mountpoint export option did not refuse an unmounted dataset at exportfs time on nfs-utils 1:2.8.3-1 (02-03 finding)
- 02-05: M1 (the mountpoint export option) is STILL UNPROVEN. The client-side re-test was attempted — the dataset was unmounted with a dead-man restore, 02-03's finding reproduced (exportfs -v keeps the line), and the estate was fully restored — but the definitive fresh-mount probe was blocked by the sandbox permission classifier and was NOT worked around. NEW instrument for the next attempt: /proc/fs/nfsd/exports DOES populate once a client has mounted (02-03 recorded it as non-discriminating because no client existed) and it emptied when the dataset went away. M2 (After=zfs-mount.service) remains the proven guard; 02-03's threat_flag on infra/nfs-music-export.tf stands.
- 02-05: check-music-consumers.sh is STILL not on LXC 100 and a git pull there CANNOT land it — commits 16a9fb2 and 6d4f8de are local-only on the workstation, not pushed to origin. This working tree is 'ahead 33, behind 9' of origin/main. The script was scp'd in for the wave gate and removed again. 02-06/02-09 must push before relying on a pull.
- 02-05: ACCEPTED CONSEQUENCE (D-27/T-02-21) — Route A's usage:media also surfaces the music library in Home Assistant's own Media browser to anyone with HA access. Measured: HA Core reads the same 13 artist directories. Accepted: usage:media is what makes Route A work, the mount is ro on both client and export, and the audience already has HA access. Belongs in PROJECT.md per D-47.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Duplicates | DUPE-01, DUPE-02 | v2 — before any `unsorted` import | 2026-08-17 |
| Bucket B | NOWB-01, NOWB-02 | v2 — manual confirmation budget | 2026-08-17 |
| Acquisition | LIDR-01 — replace Lidarr as grabber | v2 — wanted; WRIT-03 removes the harm now | 2026-08-17 |
| Bucket C | DJCC-01 – DJCC-05 | v2 — lowest-confidence research area | 2026-08-17 |

## Quick Tasks Completed

| ID | Task | Date | Status |
|----|------|------|--------|
| 260826-0u0 | Document Tailscale configuration and low-level design across all systems | 2026-08-26 | complete ✓ |

## Session Continuity

Last session: 2026-09-01T10:00:58.988Z
Stopped at: Completed 02-06-PLAN.md
Resume file: None

**02-05 is complete and CONS-01 is ticked.** The Supervisor mount is live, Route A won on
measurement with Route B's failure symptom recorded (it exposes no client-side `ro` option at all),
and criterion 2 is proven at the export layer rather than by configuration politeness. Nothing was
written into `/mnt/tank/media/Music`: 2,674 entries, 33.9 G, zero files newer than the task start.
Both wave gates pass — `check-music-consumers.sh --baseline` exit 0 with section 1 green 10/10, and
`check-music-freeze.sh` exit 0 with FAILURES 0.

**The PARTIAL naming convention is still the rule for halted plans.** `phase-plan-index` treats any
`*-SUMMARY.md` as plan-complete on file existence alone, regardless of its `status:` frontmatter — so
a halted plan's record must be `-PARTIAL.md` and only becomes `-SUMMARY.md` when the plan genuinely
finishes.

Next in phase 2: **02-06** (the Music Assistant local filesystem provider). Read 02-05's blockers
first — `MA_LOCAL_PROVIDER_INSTANCE` is still unpinned by design, the audit script must be **pushed**
before LXC 100 can pull it, and MA is still BETA `2.11.0b0` with `auto_update: true`, so stamp the
version on every assertion.

**Two hazards carried from 02-05 for anyone touching the export.** `ssh -n` points stdin at
`/dev/null`, so `ssh -n host 'bash -s' <<EOF` silently discards the entire script and exits 0 — use
`-n` for inline `ssh host 'cmd'` only. And `/proc/fs/nfsd/exports` shows four `no_root_squash` hits
once a client mounts; they are auto-generated `v4root` traversal entries, not a T-02-06 regression.
Assert on `exportfs -v`.

Plans 01-02, 01-04, 01-06, 01-07, 01-08 and 01-09 are `autonomous: false` — they carry blocking
human checkpoints (the fence run, the ~140 GB capture, the Lidarr/Jellyfin freeze and its one-hour
watch, the beets config vendoring, the recursive chown, and the phase-closure verdict).

Next: `/gsd-plan-phase 2 --research-phase`
