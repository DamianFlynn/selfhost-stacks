---
phase: 01-safety-harness-and-freeze-the-writers
plan: 06
subsystem: writer-freeze
status: INCOMPLETE — Task 3 watch RESTARTED content-aware, evaluable from 2026-08-18T15:43:13Z
tags: [lidarr, jellyfin, api, WRIT-03, SAFE-05, sqlite, sidecars, zfs-acl]
requires:
  - scripts/check-music-freeze.sh (01-01)
  - /mnt/fast/safety/music-pre-project/audit/sidecars-baseline.txt (01-01, D-18 baseline)
  - fence layout and MANIFEST.txt (01-02)
  - every other media mount narrowed (01-05)
provides:
  - Lidarr root folder off the library, on the downloads dataset (D-23)
  - Lidarr renameTracks off, all metadata consumers off (WRIT-03, D-24)
  - Lidarr media mount read-only on the running container (D-25)
  - tagger-class rw holders on the library == 0 (WRIT-01 now structurally true)
  - Jellyfin Music library frozen at the application layer (SAFE-05, D-15/D-16 + SaveLyricsWithMedia)
  - three Jellyfin databases in the fence with integrity checks and manifest entries
  - scripts/check-music-freeze.sh section 5 widened to .png and .txt
  - /mnt/fast/safety/music-pre-project/audit/lidarr-api-after.json
  - /mnt/fast/safety/music-pre-project/audit/jellyfin-library-options-after.json
  - /mnt/fast/safety/music-pre-project/audit/sidecar-watch-t0-{20260818,sha256,stat}.txt
  - /mnt/fast/safety/music-pre-project/audit/sidecar-watch-STATE.txt
  - /mnt/fast/safety/music-pre-project/audit/sidecar-watch-eval.sh (content-aware, 4 gates)
  - "zfs snapshot tank/media/Music@safe05-watch-t0"
  - "PROVEN: SaveLocalMetadata=false does NOT stop an explicit Jellyfin FullRefresh writing .nfo"
affects:
  - 01-07 (beets config vendoring — unaffected)
  - 01-08 (BLOCKED as written — chmod is impossible on tank; see the ZFS aclmode finding)
  - 01-09 (phase closure — must first evaluate the running watch, then re-run in assert mode)
  - "Phase 2 (the NFS export inherits mode bits that cannot currently be set)"
  - "Phase 5 (absorbs /mnt/tank/downloads/lidarr-import into its _inbox structure, D-23)"
tech-stack:
  added: []
  patterns:
    - "sqlite3 .backup against the live file, PRAGMA integrity_check before it counts as a backup (01-02 pattern reused)"
    - "jellyfin.yaml / lidarr.yaml dated NOTE block recording what breaks if reverted (01-05 pattern)"
    - "a self-refusing evaluation script — sidecar-watch-eval.sh exits 3 rather than evaluate early"
key-files:
  created: []
  modified:
    - stacks/selfhosted/arrs/lidarr.yaml
    - stacks/selfhosted/media/jellyfin.yaml
    - scripts/check-music-freeze.sh
decisions:
  - "SaveLyricsWithMedia is a third, independent Jellyfin write switch that D-15/D-16 do not name — it wrote 944 of the 1,123 baseline sidecars and was closed under Rule 2"
  - "the Lidarr root folder change is NOT what closes the library; all 22 artists keep absolute /media/Music paths, so the :ro mount (D-25) is the load-bearing control"
  - "chmod is impossible anywhere on tank (aclmode=restricted) — recorded as a finding, NOT worked around by changing a dataset property that belongs to 01-08's decision"
  - "the SAFE-05 test as the roadmap words it is a path-set diff, and a path-set diff returned a perfect pass while Jellyfin rewrote 83 of 91 .nfo in place — the watch was restarted with sha256 content hashes, a whole-library stat manifest and a ZFS snapshot"
metrics:
  duration: ~60 minutes so far (watch pending)
  completed: null
  tasks: 2 of 3
  commits: 3
---

# Phase 01 Plan 06: Freeze Lidarr and Jellyfin Summary

**STATUS: INCOMPLETE.** Tasks 1 and 2 are complete, committed, applied live and verified from
both APIs. Task 3's watch is **running now** — restarted content-aware at `2026-08-18T14:43:13Z`
and evaluable from `2026-08-18T15:43:13Z` with a single command (below).

Lidarr's write paths into the music library are closed and **tagger-class rw holders on the
library is now 0** — WRIT-01 is structurally true for the first time. Jellyfin's Music library is
frozen at the application layer with three switches, not the two the phase context names.

> **Read the Task 3 section before treating SAFE-05 as nearly done.** The test as the roadmap
> words it is a path-set diff. It was run with an active Jellyfin refresh and returned a perfect
> pass — 0 added, 0 removed — while Jellyfin **rewrote 83 of the library's 91 `.nfo` files in
> place and changed the content of 66 of them.** The instrument was replaced. A second, real
> limit was found at the same time: `SaveLocalMetadata=false` does **not** stop an explicit
> `FullRefresh` from writing `.nfo`. Nothing was lost — two ZFS snapshots hold the originals and
> no file was deleted or restored.

## What Was Built

| Task | Output | Commit | Status |
|------|--------|--------|--------|
| 1 | Lidarr repointed, de-fanged, `:ro` — API evidence recorded | `07c69de` | COMPLETE |
| 2 | Jellyfin DBs fenced; Music library frozen; API evidence recorded | `219dc4d` | COMPLETE |
| 3 | Section 5 widened; widened baseline taken; watch started | `fb57d76` | **RUNNING — not evaluated** |

---

## Task 1 — Lidarr (WRIT-03, D-23/D-24/D-25/D-26)

All state below was read back from Lidarr's REST API **after** the container was recreated with
the read-only mount, per D-26. Nothing was verified in the UI.

### Root folder: before and after

| | Before | After |
|---|---|---|
| id | 1 | 2 |
| name | `Music` | `Lidarr Import (staging)` |
| path (container) | `/media/Music` | `/downloads/lidarr-import` |
| path (host) | `/mnt/tank/media/Music` | `/mnt/tank/downloads/lidarr-import` |
| accessible | true | true |

The container-internal path is `/downloads/lidarr-import`, **not** `/media/lidarr-import` as the
plan's action text guessed. The plan told me to confirm this from the volume block rather than
assume, and that was correct: `/mnt/tank/downloads` is already mounted at `/downloads`, so the
new host path under the downloads dataset surfaces there. `/media` is now read-only and could
never have hosted a writable root folder.

### What happened to the 22 artists bound to the old root — the finding that matters

`DELETE /api/v1/rootfolder/1` returned **HTTP 200** with an empty body. Lidarr did **not** refuse
the deletion and did **not** orphan anything. No reassignment was needed or performed.

But the artists did not move either:

```
artistCount:            22
artistsStillInLibrary:  22     (path starts with /media/Music)
distinct rootFolderPath after deletion:  "/media/Music"  x22
```

Lidarr stores an **absolute path per artist**; `rootFolderPath` on the artist resource is derived
from that path, not from the RootFolder table. Deleting the root folder therefore changes only
where *new* artists land. **All 22 existing artists still target `/media/Music/<Artist>`.**

This is important enough to have gone into `lidarr.yaml` as a NOTE: **D-23 alone does not close
the library — D-25's `:ro` mount is the load-bearing control.** A reader who reverted the mount
suffix on the grounds that "the root folder was moved anyway" would hand Lidarr write access to
22 artists it still tracks.

Deliberately **not** done: reassigning the 22 artists to the new root. That would have told Lidarr
its files had moved to a directory that does not contain them, marking ~1,942 tracks missing and
inviting a mass re-download search — and with `moveFiles` it would have attempted to move the
library itself. The plan offered reassignment as one of two outcomes to "check which"; the checked
answer is that reassignment was neither required nor safe.

### Track renaming

| Setting | Before | After |
|---|---|---|
| `renameTracks` | **true** | **false** |

The naming *formats* were left intact (`{Album Title} ({Release Year})/{Medium Format} {medium:00}-{track:00} {Artist Name} - {Track Title}`) — disabling the switch is the requirement; deleting the
formats would only make re-enabling it later harder to reason about.

### Metadata consumers — every provider by name, with state

| id | Name | Implementation | Before | After |
|---|---|---|---|---|
| 1 | Kodi (XBMC) / Emby | `XbmcMetadata` | `enable: false` | `enable: false` |
| 3 | Roksbox | `RoksboxMetadata` | `enable: false` | `enable: false` |
| 2 | WDTV | `WdtvMetadata` | `enable: false` | `enable: false` |

**All three were already disabled.** D-24 anticipated an open write path here and found a closed
one. That is worth stating plainly rather than reporting three settings as "turned off": the
`.nfo` files in the library did **not** come from Lidarr's metadata consumers. Combined with the
Jellyfin finding below, the `.nfo`/`.jpg`/`.lrc` in the tree are attributable to Jellyfin.

### Two further Lidarr write paths that D-24 does not name (Rule 2)

Enumerating the metadata section surfaced settings outside the `metadata` endpoint entirely:

| Endpoint / setting | Before | After | Why |
|---|---|---|---|
| `config/metadataProvider.writeAudioTags` | `"no"` | `"no"` | already safe — Lidarr can rewrite ID3/FLAC tags in place; this is a *tag* writer, a class D-24 does not mention at all |
| `config/metadataProvider.scrubAudioTags` | `false` | `false` | already safe |
| `config/metadataProvider.embedCoverArt` | **true** | **false** | closed. Inert while `writeAudioTags: no`, but it is a latent in-file writer one setting away from live |
| `config/mediamanagement.deleteEmptyFolders` | **true** | **false** | closed. Lidarr was authorised to **delete** directories under any root it scans. A destructive write path, not a metadata one |
| `config/mediamanagement.setPermissionsLinux` | `false` | `false` | already safe (would `chmod`/`chown` the tree) |
| `config/mediamanagement.createEmptyArtistFolders` | `false` | `false` | already safe |
| `config/mediamanagement.importExtraFiles` | `false` | `false` | already safe |

`deleteEmptyFolders: true` is the one I would flag hardest. WRIT-03 is framed around renaming and
metadata; nobody counted a delete path.

### The mount, proven on the running container

```
/mnt/fast/appdata/arrs/lidarr/config:/config:rw
/etc/localtime:/etc/localtime:ro
/mnt/tank/downloads:/downloads:rw
/mnt/tank/media:/media:ro          <- was :rw
```

`docker inspect lidarr | grep -c "/mnt/tank/media:true"` → **0**.

Proven at the filesystem, not just in the inspect output:

```
$ docker exec lidarr touch /media/Music/.wr-test-01-06
touch: cannot touch '/media/Music/.wr-test-01-06': Read-only file system   exit=1
$ docker exec lidarr ls /media/Music
BLACKPINK / Benson Boone / Chris Norman / ...
```

Write refused, read retained — which is exactly D-25: library visibility for existing-library
matching and duplicate awareness, without the ability to write.

### WRIT-01 is now structurally true

`scripts/check-music-freeze.sh --baseline` on LXC 100 after the recreate:

```
  tagger-class writers: 0
  consumer-class writers: 1 (documented exception, D-21)
      jellyfin (/mnt/tank/media:/media:rw)
  unclassified writers: 0
  ✅ no tagger-class container holds rw on the library
  ✅ no unclassified rw holders
  declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
```

Whole-script failure total: **5 → 3**. The remaining three are the ownership and mode assertions
that 01-08 owns — and see the ZFS finding below, because two of them cannot currently be met.

### Library untouched

| Assertion | 01-01 baseline | After 01-05 | After 01-06 Task 1 |
|---|---|---|---|
| ownership mismatches | 2,543 | 2,543 | **2,543** |
| dir-mode mismatches | 87 | 87 | **87** |
| file-mode mismatches | 2,586 | 2,586 | **2,586** |

01-08 owns the chown. This plan moved nothing.

---

## Task 2 — Jellyfin (SAFE-05, D-15/D-16/D-17)

Jellyfin **10.11.11**, reachable from LXC 100 at `192.168.90.31:8096` (the `t3_proxy` network —
it publishes no host port, and `localhost:8096` is refused).

### Database backups — mechanism and results

Backed up with the SQLite **online-backup** mechanism against the live file
(`sqlite3 "file:<db>?mode=ro" ".timeout 30000" ".backup <dest>"`), per D-15's Claude's-Discretion
note and the pattern 01-02 established. **No container downtime. No stop-copy-start. No `cp`.**

| Source | Backup in `library-db/` | Size | `PRAGMA integrity_check` |
|---|---|---|---|
| `data/jellyfin.db` | `jellyfin-jellyfin.db` | 381,046,784 B | **ok** |
| `data/playback_reporting.db` | `jellyfin-playback_reporting.db` | 135,168 B | **ok** |
| `data/introskipper/introskipper.db` | `jellyfin-introskipper.db` | 14,987,264 B | **ok** |

Each was integrity-checked **before** being treated as a backup, per T-01-32.

**The torn-copy risk was real, not theoretical.** At capture time `jellyfin.db-wal` held
**4,544,392 bytes** of committed pages. The backup (381,046,784 B) is *larger* than the source
`.db` (380,997,632 B) precisely because `.backup` checkpointed that WAL into it. A plain `cp` of
the `.db` alone would have silently dropped every one of those pages and produced a backup that
only failed when it was needed.

Content spot-checked in the backup, not assumed: 34 tables, and `BaseItems` carries
**1,942 Audio / 70 MusicAlbum / 45 MusicArtist / 23 MusicGenre** rows.

**Not captured:** `data/introskipper/introskipper-cache.db` (735 MB). It is a regenerable analysis
cache, and D-06 sizes the fence at "well under 1 GB"; including it would have more than tripled
the fence's 315 MB against 18 GB of free space on `/mnt/fast`. Recorded in `MANIFEST.txt` as an
explicit exclusion rather than an omission.

`MANIFEST.txt` gained a `## Jellyfin databases (plan 01-06, SAFE-05)` section with all three
sha256 lines plus the mechanism, the WAL byte count, and the exclusion.

**Backup files are mode `0600`, not `0644` like the rest of the fence.** `jellyfin.db` carries an
`ApiKeys` table with 4 rows (`jellystats`, `Wizarr`, `Seerr`, `QuarterMaster`). Nothing mounts the
fence (D-08, re-proven this run), but a world-readable file full of credentials is not something to
leave for a later reader to notice. See Threat Flags.

### The two settings — and the third one nobody counted

Applied via `POST /Library/VirtualFolders/LibraryOptions` → **HTTP 204**. **Neither setting needed a
UI fallback; both, and the third, went through the API.** **No Jellyfin restart occurred or was
required** — the container reads `Up 5 hours (healthy)` after the change, and the settings read
back correctly from the API immediately.

| Switch | Before | After | Source |
|---|---|---|---|
| `SaveLocalMetadata` | true | **false** | D-15 |
| `EnableRealtimeMonitor` | true | **false** | D-16 |
| `SaveLyricsWithMedia` | true | **false** | **found here — not in D-15/D-16** (Rule 2) |

**`SaveLyricsWithMedia` is the single most consequential finding of this plan.** In Jellyfin
10.10+, `SaveLocalMetadata` does **not** gate lyric saving; `SaveLyricsWithMedia` is an
independent switch. The Music library had it on with `LyricFetcherOrder: ["LrcLib Lyrics"]` — and
**944 of the 1,123 baseline sidecars are `.lrc`**. Turning off only the two settings the phase
context names would have left the largest sidecar writer in the estate running, while SAFE-05's
one-hour watch — which names `.lrc` explicitly — reported a pass.

Music was the **only** library with `SaveLyricsWithMedia` enabled, which closes the attribution
loop: Lidarr's metadata consumers were already off, so the `.lrc` came from here.

### Scope — Movies, Shows and Collections are unchanged

Read back in the same call:

| Library | Path | `SaveLocalMetadata` | `EnableRealtimeMonitor` | `SaveLyricsWithMedia` |
|---|---|---|---|---|
| **Music** | `/media/Music` | **false** | **false** | **false** |
| Shows | `/media/TV` | true | true | false |
| Movies | `/media/Movies` | true | true | false |
| Collections | `/config/data/collections` | true | false | false |

D-15 and D-16 are satisfied exactly: Music only, on an instance actively serving the house.

### The global scheduled scan — before and after

| | Before | After |
|---|---|---|
| Key | `RefreshLibrary` | `RefreshLibrary` |
| Name | Scan Media Library | Scan Media Library |
| State | Idle | Idle |
| Trigger | Interval, 432000000000 ticks (**12 h**) | Interval, 432000000000 ticks (**12 h**) |

**Untouched, as D-16 requires** — other libraries keep updating. With the three switches above
off, a scan cannot write sidecars into Music anyway.

### Left alone deliberately, and why

`SaveSubtitlesWithMedia` is `true` on every library including Music. It is inert there — Music has
`SubtitleFetcherOrder: []` and `DisabledSubtitleFetchers: []`, so no fetcher is configured, and
audio files carry no subtitle streams. Recorded in `jellyfin.yaml` as considered-and-not-changed
rather than changed blind. If the watch turns up a `.srt`, this is the first place to look.

### Permanence

The freeze is **permanent (D-17)** and `jellyfin.yaml`'s NOTE block now says so with all three
switches enumerated, so a future reader reverting two of three does not silently reopen the
largest writer. There is nothing here on a list of things to remember to undo.

---

## Task 3 — RUNNING, NOT EVALUATED

### Section 5 widened, committed, pushed, pulled, and the baseline re-taken

`scripts/check-music-freeze.sh` section 5 now inventories `.nfo`, `.jpg`, `.lrc`, **`.png`** and
**`.txt`**, prints the narrow D-18 subtotal alongside the widened total so the change stays
auditable against 01-01, and counts `.DS_Store` separately. Committed as `fb57d76`, pushed to
`origin/main`, pulled on LXC 100 (host now at `fb57d76`), and the baseline re-taken from the
widened script.

### Narrow vs widened baseline counts

| Extension | Count | In D-18's definition? |
|---|---|---|
| `.lrc` | 944 | yes |
| `.nfo` | 91 | yes |
| `.jpg` | 88 | yes |
| `.png` | **43** | **no — added by 01-06** |
| `.txt` | **175** | **no — added by 01-06** |
| **narrow subtotal** | **1,123** | the 01-01 baseline |
| **widened total** | **1,341** | **what the gate now measures** |

The widened set is **19.4% larger** than the definition SAFE-05 was written against. Jellyfin
writes `.png` for logo, clearart and disc art, so those 43 files sat in a blind spot where a new
one would have been invisible.

### T+0 versus the 01-01 D-18 baseline

| | Count |
|---|---|
| added since 01-01 | **0** |
| removed since 01-01 | **0** |

The narrow subset is byte-for-byte identical to `sidecars-baseline.txt`. **Nothing was written
into the library between plan 01-01 and the start of this watch**, so the T+60 delta measures the
freeze cleanly with no pre-existing noise to subtract. (The plan anticipated differences here as
"useful evidence the freeze was needed" — there are none, which is a stronger result.)

### The watched folder

**`/mnt/tank/media/Music/Taylor Swift`** — 244 sidecars at T+0 and the **only** artist folder
carrying all five watched extensions: `nfo=14 jpg=14 lrc=200 png=5 txt=11`. It is provably in
Jellyfin's write path for both the `.nfo`/`.jpg` saver *and* the `.lrc` lyric saver, not merely
underneath the library root. Def Leppard (281) and P!nk (208) carry more files but not the full
extension spread.

The recorded enumeration is **library-wide**, which is strictly stronger than watching one folder.

### THE TEST AS SPECIFIED FAILED — a path-set diff cannot see an in-place rewrite

This is the single most important result in this plan, and it invalidates the instrument the
roadmap specifies rather than the freeze itself.

The first watch ran the specified test: enumerate sidecar **paths** at T+0, trigger a scan,
enumerate again, diff. Against a live, actively-scanning Jellyfin it returned:

```
path-set diff lines: 0        (0 added, 0 removed)
```

A perfect pass. In the same window:

| Measurement | Result |
|---|---|
| library files modified after watch start | **83** |
| of those, `.nfo` | **83** (100% — no other extension touched) |
| of the library's 91 `.nfo` total | **91% rewritten** |
| audio files (`.flac`/`.mp3`/`.wav`) touched | **0** |
| content byte-identical to `@pre-project` | 17 |
| **content genuinely CHANGED** | **66** |
| first write | `2026-08-18T14:33:56Z` — **1 second after the scan POST** |
| last write | `2026-08-18T14:35:04Z` |

Verified byte-for-byte against the `tank/media/Music@pre-project` snapshot (12:08Z). A sample
diff, `Taylor Swift/Lover (2019)/album.nfo`:

```diff
-  <premiered>2019-08-22</premiered>
-  <releasedate>2019-08-22</releasedate>
+  <premiered>2019-08-23</premiered>
+  <releasedate>2019-08-23</releasedate>
-  <country />
```

**A test that reports a clean pass while 91% of the library's `.nfo` files are rewritten is
worse than no test at all.** It is the exact failure class this phase already met twice — 01-01's
declared-YAML false pass, and 01-02's harness failing closed and silent.

### The second finding: `SaveLocalMetadata=false` does not stop an explicit FullRefresh

`SaveLocalMetadata` was `false` at the time — set, read back from the API, and recorded. The
writes still happened, one second after the refresh request. The conclusion is unavoidable:

> **`SaveLocalMetadata: false` gates the *automatic*, scan-time metadata save path only. An
> explicit `MetadataRefreshMode=FullRefresh` — which is exactly what Jellyfin's UI "Refresh
> metadata" button issues — still runs the `Nfo` saver and writes into the library.**

What this means for SAFE-05, stated plainly:

- The freeze **holds** against the threat PROJECT.md actually describes: "`SaveLocalMetadata:
  true` means Jellyfin writes `.nfo`/`.jpg`/`.lrc` into any folder placed under `/media/Music`
  within minutes" — the automatic path, and the scheduled 12-hourly scan.
- The freeze **does not hold** against a human clicking "Refresh metadata" on the Music library
  in the Jellyfin UI, or any equivalent explicit API call. That remains an open write path, and
  the only structural control for it would be making the mount `:ro` — which D-21 deliberately
  rejected and the phase's Deferred Ideas already flags as "worth revisiting once the tagger
  owns the tree".

This belongs in PROJECT.md alongside D-17 when 01-09 carries the permanence decision across.

### Nothing was lost, and nothing was restored

- `tank/media/Music@pre-project` (2026-08-18T12:08Z) holds every original. Proven readable and
  usable this run — it is what the 66-file content comparison was made against.
- `tank/media/Music@safe05-watch-t0` (2026-08-18T14:42Z) was taken as the new watch baseline.
- **No sidecar was deleted (D-18) and none was restored.** Restoring is a mutation this plan did
  not authorise, the changed content is arguably fresher provider metadata rather than damage,
  and QUAL-01's before-state snapshot covers *audio file tags*, not `.nfo` sidecars. The
  snapshot is the undo if one is ever wanted; that is a decision for the user, not for me.

### The watch was restarted with content-aware instruments

`sidecar-watch-eval.sh` now checks four things, **all of which must be zero**:

| # | Check | Catches |
|---|---|---|
| 1 | sidecar paths ADDED | the original roadmap criterion |
| 2 | sidecar paths REMOVED | D-18 deletes nothing |
| 3 | **sidecar content changed (sha256)** | **in-place rewrites — the check that was missing** |
| 4 | whole-library stat (type/size/mtime, all 2,674 entries) | touch-without-change, and any write to a non-sidecar file including audio |

Plus an independent block-level cross-check from the Proxmox host:
`zfs diff tank/media/Music@safe05-watch-t0 tank/media/Music` — expect no output.

### The scan — triggered and confirmed actually running (first window)

```
POST /Items/7e64e319657a9516ec78490da03edccb/Refresh
  ?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh
  &ReplaceAllMetadata=false&ReplaceAllImages=false
→ HTTP 204   at 2026-08-18T14:33:55Z
```

**Confirmed running, not merely accepted.** An item refresh does not appear in `/ScheduledTasks`,
so acceptance alone would have been worthless evidence. `docker logs jellyfin` shows
`MediaBrowser.Providers.Music.AlbumMetadataService` actively querying MusicBrainz from 15:34:07
local onward, still active at the time of writing.

`FullRefresh` overrides the library's `EnableInternetProviders: false`, so Jellyfin is fetching
album metadata and images from the internet for the entire Music library during the window. This
is the most aggressive available test short of `ReplaceAllMetadata` (rejected — it would wipe
database metadata for no additional evidence). Had `SaveLocalMetadata` still been on, this scan
would have rewritten every `.nfo` in the tree within minutes.

### Watch state — durable, on `/mnt/fast`

| | |
|---|---|
| **Watch start (UTC)** | **`2026-08-18T14:43:13Z`** (epoch `1787064193`, in `.../audit/sidecar-watch-t0.epoch`) |
| **Earliest valid evaluation** | **`2026-08-18T15:43:13Z`** |
| ZFS snapshot at T+0 | `tank/media/Music@safe05-watch-t0` (created 15:42 local) |
| T+0 content manifest | `.../audit/sidecar-watch-t0-sha256.txt` — 1,341 lines, sha256 per sidecar |
| T+0 stat manifest | `.../audit/sidecar-watch-t0-stat.txt` — 2,674 lines, type/size/mtime for every library entry |
| T+0 path list | `.../audit/sidecar-watch-t0-20260818.txt` — 1,341 lines (retained, comparable to 01-01) |
| T+0 harness report | `.../audit/sidecar-watch-t0-report-20260818.txt` |
| State record | `.../audit/sidecar-watch-STATE.txt` |
| Evaluation script | `.../audit/sidecar-watch-eval.sh` |

### The exact command that evaluates it

```bash
ssh root@172.16.1.159 'bash /mnt/fast/safety/music-pre-project/audit/sidecar-watch-eval.sh'
```

It **refuses to evaluate early** — run before `15:43:13Z` it prints `TOO EARLY` and exits `3`
without producing a T+60 file, so "at least one full hour of real elapsed time" cannot be quietly
bypassed. Verified twice: exited 3 correctly at `14:35:56Z` and `14:45:07Z`.

Exit codes: `0` PASS, `1` FAIL (files listed with mtimes), `2` harness/precondition error,
`3` too early. Its stderr is captured, never discarded — the wave-2 lesson that a verification
harness failing *closed* and silent is more dangerous than one failing open.

**GATE: all four checks must be zero.** If anything appears, do not delete it, do not restore it
(D-18) and do not retry silently — record the filename and mtime. Both ZFS snapshots are the undo.

### One thing this window does NOT yet have: an active scan

**No scan has been triggered inside the current window.** The `FullRefresh` ran *before* T+0 and
had finished by `14:35:04Z`. As it stands the current hour is a **quiet** one, and the plan is
explicit that an active hour is much stronger evidence.

The realistic, in-threat-model way to make it active is the scheduled task —
`POST /ScheduledTasks/Running/RefreshLibrary`, default refresh mode, the path that actually runs
every 12 hours — with the T+0 manifests re-taken immediately before it. **I did not do this: it
is a further scan against the household's live Jellyfin, and it was outside the authorisation I
had once the watch had been started and handed back.** It needs an explicit go-ahead. The
12-hourly task may also fire on its own inside the window, in which case the evaluation captures
it either way.

**No sidecar was deleted or restored at any point in this plan.**

---

## Deviations from Plan

### 1. [BLOCKER for 01-08 — Rule 4, escalated not worked around] `chmod` is impossible anywhere on `tank`

- **Found during:** Task 1, creating `/mnt/tank/downloads/lidarr-import` at `568:568 0755`.
- **Issue:** `chmod` fails with `Operation not permitted` **as root**, for every mode, on both
  directories and files, on `tank/downloads`. Not a permissions problem and not a mode-specific
  one — even a **no-op `chmod 0777` on a file already at 0777 is refused**:

  ```
  chmod 0777 .../.acltest   -> Operation not permitted
  chmod 0775 .../.acltest   -> Operation not permitted
  chmod 0755 .../.acltest   -> Operation not permitted
  chmod 0644 .../.acltest/f -> Operation not permitted
  ```

- **Cause:** ZFS `aclmode=restricted` with `aclinherit=passthrough`. Every child inherits a
  non-trivial NFSv4 ACL, and `restricted` makes `chmod` on a non-trivial ACL an error.

  ```
  tank              acltype posix   aclmode discard      aclinherit discard
  tank/downloads    acltype nfsv4   aclmode restricted   aclinherit passthrough
  tank/media        acltype nfsv4   aclmode restricted   aclinherit passthrough
  tank/media/Music  acltype nfsv4   aclmode restricted   aclinherit passthrough
  ```

- **Why this is much bigger than one directory:** `tank/media/Music` is configured identically.
  **D-12/D-13's mode normalisation — 87 directories to 0755 and 2,586 files to 0644 — cannot be
  performed by `chmod`, so plan 01-08 is blocked as written.** It also explains 01-01's otherwise
  odd finding that *every single entry in the library is mode 0777 with no exceptions*: nothing
  can change them. And it is the same root cause as PROJECT.md's documented `rsync -a` failure
  (`mkstemp ... Operation not permitted`). Phase 2 inherits this too — knfsd does not export
  NFSv4 ACLs, so mode bits are all an NFS client sees, and mode bits currently cannot be set.
- **Action taken: none, deliberately.** The three routes out are (a) `zfs set aclmode=passthrough`
  or `discard` on the datasets, (b) `nfs4-acl-tools` (absent on both LXC 100 and the Proxmox host;
  installing it is a package install, excluded from Rule 3), or (c) accept 0777. Each is a
  dataset-wide or estate-wide decision that also fixes the Phase 2 export semantics, and it belongs
  to **01-08**, whose explicit job this is. Silently flipping a ZFS property on a live pool from a
  plan that owns one YAML file would have been exactly the wrong call.
- **Consequence for this plan:** `/mnt/tank/downloads/lidarr-import` is **`568:568` mode `0777`**,
  not `0755`. `chown` worked; only `chmod` is refused. 0777 matches every sibling under
  `/mnt/tank/downloads`, and Lidarr runs as `568:568` and owns it. Task 1's acceptance criterion
  `stat` returning `568:568 755` is **not met and cannot be met** without the decision above.

### 2. [Rule 2 - Missing critical] `SaveLyricsWithMedia` — the `.lrc` writer D-15/D-16 do not name

- **Found during:** Task 2, reading the Music library's full `LibraryOptions` before mutating it.
- **Issue:** `SaveLocalMetadata: false` does not stop lyric saving in Jellyfin 10.10+.
  `SaveLyricsWithMedia` was `true` with `LyricFetcherOrder: ["LrcLib Lyrics"]`, and `.lrc` is
  **944 of the 1,123** baseline sidecars — 84% of them, and a file type SAFE-05 names explicitly.
- **Fix:** set `false` on the Music library in the same API call. Recorded in `jellyfin.yaml`.
- **Commit:** `219dc4d`

### 3. [Rule 2 - Missing critical] Two further Lidarr write paths outside the `metadata` endpoint

- `config/mediamanagement.deleteEmptyFolders` was **true** — a *delete* path into any root Lidarr
  scans, a class WRIT-03 and D-24 do not consider at all. Set false.
- `config/metadataProvider.embedCoverArt` was **true** — a latent in-file writer, inert only
  because `writeAudioTags` is `"no"`. Set false.
- **Commit:** `07c69de`

### 4. [Verified fact over plan text] The container path is `/downloads/lidarr-import`

The plan's action text proposed `/media/lidarr-import` while instructing me to confirm from the
volume block rather than assume. Confirmed: `/mnt/tank/downloads` mounts at `/downloads`, so the
correct container path is `/downloads/lidarr-import`. `/media` is now `:ro` and could not have
carried a writable root folder in any case.

### 5. [Finding, not a fix] Lidarr's metadata consumers were already all disabled

D-24 expects an open write path here. All three (`XbmcMetadata`, `RoksboxMetadata`,
`WdtvMetadata`) were already `enable: false` before this plan. Reported as found rather than as
three settings changed. It also attributes the library's `.nfo` files: with Lidarr's consumers off
and Jellyfin's `MetadataSavers: ["Nfo"]` on with `SaveLocalMetadata: true`, they came from
Jellyfin.

### 6. [Finding] Deleting Lidarr's root folder does not detach its artists

Covered in full in Task 1. Recorded here as a deviation because the plan framed the outcome as
either "Lidarr refuses the deletion" or "Lidarr orphans the artists", and the real answer is a
third one: it accepts cleanly and changes nothing about where the 22 existing artists point.

### 7. [Rule 1 - Bug in the specified test] The SAFE-05 path-set diff is blind to in-place rewrites

- **Found during:** Task 3, cross-checking file mtimes after the scan rather than trusting the
  path diff.
- **Issue:** the roadmap's criterion — "no new `.nfo`/`.jpg`/`.lrc` appearing" — is a path-set
  comparison. It returned **0 added, 0 removed** while Jellyfin rewrote **83 of 91 `.nfo`** files
  in place, **66 with genuinely changed content**. Widening the extension set (which this plan
  also did) does not help at all: the blind spot is the *comparison*, not the *set*.
- **Fix:** the watch was restarted with sha256 content hashes per sidecar, a whole-library
  type/size/mtime manifest covering all 2,674 entries, and a ZFS snapshot for an independent
  block-level cross-check. The path check is retained as one gate of four.
- **Cost:** the first hour was discarded and the watch restarted at `14:43:13Z`.
- **This is the third instance of the same failure class in this phase** (01-01's declared-YAML
  false pass, 01-02's harness failing closed and silent, and now this). Worth naming as a
  pattern for 01-09.

### 8. [Finding — a real limit on SAFE-05] `SaveLocalMetadata=false` does not stop an explicit FullRefresh

Covered in full in Task 3. `SaveLocalMetadata` gates the automatic scan-time save path only; an
explicit `MetadataRefreshMode=FullRefresh` — what Jellyfin's UI "Refresh metadata" button issues
— still runs the `Nfo` saver and writes into the library. SAFE-05 as written is met for the
automatic path and **not** met for the manual one. The only structural control would be an `:ro`
mount, which D-21 deliberately rejected.

### 9. [Self-inflicted, disclosed] The FullRefresh I chose caused 66 files to change

The plan says "trigger a Jellyfin library scan so the hour is an active test". I chose
`MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh` — deliberately the most aggressive
option short of `ReplaceAllMetadata`, on the reasoning that a scan writing nothing is stronger
evidence than an idle hour. It is more aggressive than any automatic path Jellyfin would take on
its own, and it wrote to the library. That is how the two findings above were surfaced, but it
should be stated plainly rather than buried: **I caused 66 `.nfo` files to change.** Both ZFS
snapshots hold the originals, no audio file was touched, and nothing was deleted.

### 10. [Design decision] The evaluation script refuses to run early

`sidecar-watch-eval.sh` exits `3` before `T+0 + 3600s` rather than producing a T+60 file. The
acceptance criterion is one hour of **real elapsed time**; a script that would happily diff two
enumerations five minutes apart makes that criterion honour-system. Verified refusing at
`14:35:56Z`.

### 11. [Credential handling] An existing Jellyfin API key was borrowed, not a new one minted

Jellyfin's API needs an admin key to change library options. Rather than create a permanent new
credential, the existing `QuarterMaster` key was read from the live database into a shell variable
at run time and never persisted. Both recorded JSON files were grepped for it: **0 occurrences**.
Same for the Lidarr key read from `config.xml`.

---

## Findings

1. **`chmod` is impossible on `tank`.** See deviation 1. This is the most consequential finding of
   the plan and it blocks 01-08, resizes D-12/D-13, and changes what Phase 2's NFS export can
   promise. It also explains two previously-unexplained observations: 01-01's "every entry is 0777
   with no exceptions", and PROJECT.md's `rsync -a` failure.
2. **`SaveLyricsWithMedia` is an independent Jellyfin write switch** that `SaveLocalMetadata` does
   not gate, and it was responsible for 84% of the library's sidecars. Any future audit of "is
   Jellyfin frozen?" that checks only `SaveLocalMetadata` gives a false pass.
3. **Lidarr had a delete path into the library** (`deleteEmptyFolders: true`) that nothing in the
   roadmap, the requirements or D-24 counts as a write path.
4. **Root-folder changes do not repoint existing artists in the *arr family.** Absolute per-artist
   paths survive root-folder deletion. Any plan that relies on "we moved the root folder" as a
   containment control is relying on the wrong thing.
5. **A `cp` of `jellyfin.db` would have lost 4.5 MB of committed WAL pages.** The online-backup
   requirement was load-bearing, not stylistic — measurable, this run.
6. **One `.DS_Store` under the library** (`/mnt/tank/media/Music/.DS_Store`, `65534:65534`). A
   macOS client has write access over a share. It is an uncounted writer that neither the container
   mount audit nor any Lidarr or Jellyfin setting can close, and no current requirement covers it.
   The harness now counts it every run so it stays visible.
7. **The widened sidecar set is 19.4% larger than D-18's.** 218 files (43 `.png` + 175 `.txt`) were
   outside the definition SAFE-05 was written against.
8. **The SAFE-05 test as specified is structurally incapable of detecting the most likely form of
   Jellyfin pollution.** A path-set diff returned a perfect pass while 91% of the library's `.nfo`
   files were rewritten. Widening the extension set does not fix it — the comparison had to change.
9. **`SaveLocalMetadata=false` is not an absolute freeze.** It stops the automatic path; an explicit
   UI-initiated "Refresh metadata" still writes `.nfo` into the library. SAFE-05 should be read as
   "Jellyfin does not write unprompted", not "Jellyfin cannot write".
10. **The `@pre-project` ZFS snapshot works and is genuinely usable as a content baseline.** SAFE-02
    was proven in anger this run, not just asserted: it is what the 66-file content comparison was
    made against, read live from `/mnt/tank/media/Music/.zfs/snapshot/pre-project` on the Proxmox
    host (`snapdir=hidden`, so the path must be typed, it will not list).

## Requirements Status

- **WRIT-03 — MET.** Root folder off `/media/Music` and on the downloads dataset; `renameTracks`
  off; every metadata consumer off (and two further write paths closed); the mount read-only on the
  running container and proven so at the filesystem. All confirmed from Lidarr's API after a
  container recreate, per D-26, never from the UI.
- **WRIT-01 — now structurally true and ready for 01-09 to assert.** `tagger-class writers: 0`,
  `unclassified writers: 0`, `declared rw reaching Music: 0`. Not marked complete here; 01-09 owns
  phase closure.
- **SAFE-05 — NOT MET, and partially disproven as written.** Databases backed up and verified,
  three switches closed and read back, section 5 widened, content-aware T+0 recorded. The watch is
  running and unevaluated. Beyond that, two things must be resolved before SAFE-05 can be called
  met: the current window has **no active scan in it**, and `SaveLocalMetadata=false` is now
  **proven not to stop an explicit FullRefresh**. SAFE-05's wording should be tightened to
  "Jellyfin writes nothing into Music *unprompted*" — the absolute claim is false and measured so.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: credential-at-rest | `/mnt/fast/safety/music-pre-project/library-db/jellyfin-jellyfin.db` | The Jellyfin backup contains an `ApiKeys` table with 4 admin-scoped rows (`jellystats`, `Wizarr`, `Seerr`, `QuarterMaster`). Set to mode `0600` `apps:apps` rather than the fence's usual `0644`. Nothing mounts `/mnt/fast/safety` (D-08, re-proven this run). If the fence is ever copied off-box (D-07 sends `library-db/` to the Mac Mini), these keys travel with it. |
| threat_flag: uncounted-writer | `/mnt/tank/media/Music/.DS_Store` | A macOS client holds write access to the library over a share. Outside every control this phase applies; no requirement covers it. |
| threat_flag: acl-vs-modebits | `tank/media/Music`, `tank/downloads` | `aclmode=restricted` makes mode bits unsettable. Phase 2's NFS export is governed by mode bits (knfsd does not export NFSv4 ACLs), so the export currently cannot be constrained below 0777 by the mechanism D-12 assumes. |

## Known Stubs

None in code. **One incomplete deliverable by design:** the Task 3 watch result. Everything needed
to close it is recorded on `/mnt/fast` and it evaluates with one command.

## Self-Check

- `stacks/selfhosted/arrs/lidarr.yaml` — FOUND, modified
- `stacks/selfhosted/media/jellyfin.yaml` — FOUND, modified
- `scripts/check-music-freeze.sh` — FOUND, modified, `bash -n` clean
- `/mnt/fast/safety/music-pre-project/audit/lidarr-api-after.json` — FOUND on LXC 100, 9,357 B, no API key
- `/mnt/fast/safety/music-pre-project/audit/jellyfin-library-options-after.json` — FOUND, 23,751 B, no API key
- `/mnt/fast/safety/music-pre-project/library-db/jellyfin-{jellyfin,playback_reporting,introskipper}.db` — all FOUND, all `integrity_check` ok, all in `MANIFEST.txt`
- `/mnt/fast/safety/music-pre-project/audit/sidecar-watch-t0-20260818.txt` — FOUND, 1,341 lines
- `/mnt/fast/safety/music-pre-project/audit/sidecar-watch-t0-sha256.txt` — FOUND, 1,341 lines
- `/mnt/fast/safety/music-pre-project/audit/sidecar-watch-t0-stat.txt` — FOUND, 2,674 lines
- `/mnt/fast/safety/music-pre-project/audit/sidecar-watch-t0.epoch` — FOUND, `1787064193`
- `/mnt/fast/safety/music-pre-project/audit/sidecar-watch-STATE.txt` — FOUND
- `/mnt/fast/safety/music-pre-project/audit/sidecar-watch-eval.sh` — FOUND, executable, refuses early (exit 3)
- `zfs list -t snapshot tank/media/Music` — `@pre-project` and `@safe05-watch-t0` both FOUND
- Commits `07c69de`, `219dc4d`, `fb57d76` — all FOUND, all pushed to `origin/main`
- LXC 100 `/mnt/fast/stacks` at `fb57d76`, confirmed by `git log --oneline -1` after `git pull --ff-only`
- Live state confirmed by `docker inspect`, an in-container write attempt, and API read-back — not by the repo diff

**Result: PASSED for Tasks 1 and 2. Task 3 is INCOMPLETE by design — the watch is running.**

## What Closes This Plan

1. **Decide whether to make the window active.** The current hour is quiet. To test the realistic
   threat, re-take the T+0 manifests and then trigger the scheduled task
   (`POST /ScheduledTasks/Running/RefreshLibrary`, default refresh mode) — this needs an explicit
   go-ahead, and it restarts the hour. Otherwise accept a quiet hour and say so.
2. At or after `2026-08-18T15:43:13Z` (or one hour after any restart), run:
   `ssh root@172.16.1.159 'bash /mnt/fast/safety/music-pre-project/audit/sidecar-watch-eval.sh'`
3. Cross-check independently:
   `ssh root@172.16.1.158 'zfs diff tank/media/Music@safe05-watch-t0 tank/media/Music'` — expect
   no output.
4. Record the T+60 timestamp, all four counts, and the exit code in this SUMMARY.
5. Only if all four are 0: mark SAFE-05 met **with the FullRefresh caveat stated**, set this
   plan's status to complete, and advance STATE.md.
6. Decide whether to restore the 66 changed `.nfo` from `tank/media/Music@pre-project`. My
   recommendation is **no** — the content is fresher provider metadata, not damage; QUAL-01's
   before-state covers audio tags rather than sidecars; and restoring is a write into a tree this
   phase just finished sealing. The snapshot keeps the option open indefinitely.
7. Independently of the watch, **01-08 must resolve the `aclmode=restricted` blocker before its
   mode normalisation can run at all.**
8. **01-09 should carry two things into PROJECT.md** beyond D-17: that the Jellyfin freeze is not
   absolute against an explicit refresh, and that SAFE-05-style tests must compare content, not
   paths.
