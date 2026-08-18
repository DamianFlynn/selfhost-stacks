---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-08-18T14:08:41.915Z"
last_activity: 2026-08-18
progress:
  total_phases: 9
  completed_phases: 0
  total_plans: 9
  completed_plans: 5
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-17)

**Core value:** New music downloads land in the library correctly tagged, through exactly one
pipeline that someone owns.
**Current focus:** Phase 01 — safety-harness-and-freeze-the-writers

**Definition of done (CONS-04):** a file is imported only when verified with `ffprobe` on the file
*and* visible in both Jellyfin and Music Assistant. Never "tool configured".

## Current Position

Phase: 01 (safety-harness-and-freeze-the-writers) — EXECUTING
Plan: 6 of 9
Status: **01-06 PAUSED — SAFE-05 one-hour watch RUNNING, not yet evaluated**
Last activity: 2026-08-18
phase requirements, run sequentially in waves 1–9

Progress: [██████░░░░] 56%

## Performance Metrics

**Velocity:**

- Total plans completed: 3
- Average duration: 30m
- Total execution time: 90m

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | 90m | 30m |

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

### Pending Todos

- **01-06 Task 3 — the SAFE-05 watch is RUNNING and unevaluated.** Restarted content-aware after the
  first attempt proved the specified test cannot detect what actually happens.
  - Watch start (UTC): `2026-08-18T14:43:13Z` — earliest valid evaluation `2026-08-18T15:43:13Z`
  - ZFS snapshot at watch start: `tank/media/Music@safe05-watch-t0`
  - Evaluate with: `ssh root@172.16.1.159 'bash /mnt/fast/safety/music-pre-project/audit/sidecar-watch-eval.sh'`
  - Cross-check: `ssh root@172.16.1.158 'zfs diff tank/media/Music@safe05-watch-t0 tank/media/Music'`
    — expect no output.
  - The script refuses to run before the hour elapses (exit 3). 0 = PASS, 1 = FAIL with filenames
    and mtimes, 2 = harness error. Four gates, all must be zero: sidecars added, sidecars removed,
    sidecar content changed (sha256), whole-library stat delta.
  - **The current window is QUIET — no scan has been triggered inside it.** To make it active,
    re-take the T+0 manifests then `POST /ScheduledTasks/Running/RefreshLibrary` (default refresh
    mode, the realistic 12-hourly path) — this needs an explicit go-ahead and restarts the hour.
  - Until it returns clean, **SAFE-05 is not met and 01-06 is not complete.**
  - Full context: `/mnt/fast/safety/music-pre-project/audit/sidecar-watch-STATE.txt` on LXC 100.

- **01-06 open question for the user: restore the 66 changed `.nfo` or not?** They are recoverable
  from `tank/media/Music@pre-project`. Recommendation is **no** — the new content is fresher
  provider metadata rather than damage, QUAL-01's before-state covers audio tags not sidecars, and
  restoring is a write into a tree this phase just finished sealing.

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

- **BLOCKER for 01-08 — `chmod` is impossible anywhere on `tank`.** `tank/media`, `tank/media/Music`
  and `tank/downloads` all carry `acltype=nfsv4` + `aclmode=restricted` + `aclinherit=passthrough`.
  Every child inherits a non-trivial NFSv4 ACL, and `restricted` makes `chmod` on a non-trivial ACL
  return `EPERM` — **as root, for every mode, including a no-op `chmod 0777` on a file already at
  0777.** Measured directly during 01-06. Consequences:
  - **D-12/D-13's mode normalisation (87 dirs → 0755, 2,586 files → 0644) cannot be done with
    `chmod`, so 01-08 is blocked as written.** `chown` is unaffected and still works.
  - It explains 01-01's "every entry is mode 0777 with no exceptions" — nothing can change them.
  - It is the same root cause as PROJECT.md's documented `rsync -a` failure
    (`mkstemp ... Operation not permitted`).
  - Phase 2 inherits it: knfsd does not export NFSv4 ACLs, so mode bits are all an NFS client sees,
    and mode bits currently cannot be set below 0777.
  - Routes out, all belonging to 01-08's decision: (a) `zfs set aclmode=passthrough|discard` on the
    datasets, (b) install `nfs4-acl-tools` (absent on LXC 100 and on the Proxmox host), or
    (c) accept 0777 and adjust D-12. 01-06 deliberately changed nothing.

- 01-06: a `.DS_Store` owned `65534:65534` sits in the library root — a macOS client has write access
  over a share. It is an uncounted writer that no container mount audit and no Lidarr or Jellyfin
  setting can close, and no current requirement covers it. The harness now counts it every run.

- 01-06: the fenced `jellyfin-jellyfin.db` carries an `ApiKeys` table with 4 admin-scoped rows. It is
  mode `0600` rather than the fence's usual `0644`. If `library-db/` is copied off-box again under
  D-07, those credentials travel with it.
- ~~01-02 task 3 blocked at checkpoint: off-box copy to the Mac Mini (D-07)~~ **RESOLVED 2026-08-18** — operator copied library-db/ (15) and cover-scans/ (54) to `data@datas-mac-mini:~/archive/music-pre-project`, verified 54/54 sha256 + 15/15 integrity_check. Left in place as a hazard note: that host's non-interactive ssh PATH lacks `head`/`basename`/`sqlite3`, which produced two false "all 15 databases corrupt" results before absolute tool paths were used.
- 01-03: a duplicated audio_md5 makes the diff join last-wins, so in Phase 7 (BEFORE holds both backlog copies, AFTER holds one import) tag differences between duplicate sources are invisible. DUPE-01 should be resolved before QUAL-02 is treated as complete. The diff always lists such pairs in its informational section.
- 01-03: unsorted WAV content is NOT tag-free - all 40 sampled Now! 120 WAV records carry 6 format tags (title/artist/album/track/date/comment) plus an embedded cover-art stream. Plan 01-04 and Phase 7 must not assume an empty before-state for unsorted's 134 WAV files.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Duplicates | DUPE-01, DUPE-02 | v2 — before any `unsorted` import | 2026-08-17 |
| Bucket B | NOWB-01, NOWB-02 | v2 — manual confirmation budget | 2026-08-17 |
| Acquisition | LIDR-01 — replace Lidarr as grabber | v2 — wanted; WRIT-03 removes the harm now | 2026-08-17 |
| Bucket C | DJCC-01 – DJCC-05 | v2 — lowest-confidence research area | 2026-08-17 |

## Session Continuity

Last session: 2026-08-18T14:40:00Z
Stopped at: 01-06 tasks 1-2 complete and committed; task 3 watch STARTED at 2026-08-18T14:33:14Z and left running
Resume file: /mnt/fast/safety/music-pre-project/audit/sidecar-watch-STATE.txt (on LXC 100)

Plans 01-02, 01-04, 01-06, 01-07, 01-08 and 01-09 are `autonomous: false` — they carry blocking
human checkpoints (the fence run, the ~140 GB capture, the Lidarr/Jellyfin freeze and its one-hour
watch, the beets config vendoring, the recursive chown, and the phase-closure verdict).

Next: `/gsd-execute-phase 1`
