---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 07
subsystem: infra
status: complete
tags: [music-assistant, criterion-3, folder-name-fallback, missing-album-artist-action, temporary-export, teardown, cons-02, cons-03, d-03, d-04, d-08, d-10, d-15, d-38, d-45, d-46]

requires:
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-06's filesystem_local--XJaJWNUS provider with content_type=music and missing_album_artist_action=folder_name; 02-05's live Supervisor NFS mount at /media/music; 02-04's three pinned proof albums and check-music-consumers.sh; 02-02's flag-gated temporary export"
  - phase: 01-safety-harness-and-freeze-the-writers
    provides: "check-music-freeze.sh (the B-8 regression detector run as this plan's wave gate) and the library normalised to 568:568"

provides:
  - "CRITERION 3 PROVEN — all three proof albums exact-matched on album name AND artists[0].name, provider-attributed, within one deliberately-triggered sync (177 s, not 12 hours)"
  - "The folder_name fallback PROVEN TO FIRE, twice over: 183 times against the real library during the criterion-3 sync, and against two deliberate untagged controls on the temporary export"
  - "THE FALLBACK'S PRECONDITION, MEASURED: folder_name only fires when the `album` TAG agrees with the album FOLDER name. When it does not, MA silently falls back to Various Artists — isolated with a 4-cell variant matrix"
  - "A REAL LIBRARY DEFECT SURFACED: Def Leppard/Def Leppard (2015)/ derives an EMPTY album artist (album folder name == artist folder name) and hard-errors one file. Recorded, NOT repaired — the export is ro and nobody holds rw until Phase 6 (D-05)"
  - "The D-08 Various Artists substitute staged and asserted through the temporary export, then removed"
  - "MA's config/providers/remove behaviour OBSERVED on something disposable: a complete purge of every item exclusive to that instance (84 -> 79 albums, exactly -5), no orphans"
  - "The temporary export and second provider provably gone on BOTH sides, via terraform apply (D-15/D-46) — the same four assertions D-45's rollback runbook will document, now executed against real state"
  - "TWO INSTRUMENT DEFECTS FIXED: MA 2.11's `search` returns [] for an album's own exact name (false FAILURE), and music_temp_export_enabled=false was not actually a teardown (silent PASS)"

affects:
  - "02-08 — the folder_name precondition and the empty-album-artist case are the failure modes its automation must surface"
  - "02-09 — D-45's rollback runbook can now document a TESTED procedure; the folder_name precondition and D-02's permanence both belong in PROJECT.md"
  - "phase-07-pilot — folder_name is NOT an unconditional 'use the parent folder'. Any file whose album tag disagrees with its album folder gets Various Artists, and album identity is albumartist+os.sep+album, so that entry is durable"

tech-stack:
  added: []
  patterns:
    - "When a control fails, isolate the variable with a matrix rather than theorising — three extra 4-second mp3s answered in one sync what source-reading would not have"
    - "Read the provider's own sync log (tasks/log), not just the resulting library rows: the log names WHICH branch fired, the rows only show the outcome"
    - "A destroy-time provisioner that needs credentials is a security regression, not a convenience — put the teardown in a resource that always exists"

key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-07-SUMMARY.md"
  modified:
    - "scripts/check-music-consumers.sh"
    - "infra/nfs-music-export.tf"

key-decisions:
  - "missing_album_artist_action=folder_name is CONDITIONAL, not unconditional. Measured: it fires only when the album TAG matches the album FOLDER name (year suffix ignored); otherwise MA falls back to Various Artists regardless of the setting. The track artist tag is irrelevant — proven by a decoy artist that still produced the folder name"
  - "Def Leppard/Def Leppard (2015)/ produces an EMPTY album artist and one hard sync error, because the album folder name equals the artist folder name. Recorded as a finding, NOT repaired: D-05 forbids tag repair, the export is ro, and nobody holds rw on Music until Phase 6"
  - "The audit script's scope=temp-export row is now assert-when-pinned, report-otherwise. The temporary export is torn down by design, so a permanently-red row would be a check readers learn to ignore — the 01-09 failure mode. scope=library rows are untouched and always asserted"
  - "The temporary export's teardown moved OUT of a destroy-time provisioner and into an always-present reconciler resource. terraform validate refuses a destroy provisioner that reaches the connection block, and the only workaround puts the Proxmox root password in plaintext state and in every plan diff"
  - "The scratch dataset was DESTROYED rather than left in place (the plan allowed either). Terraform recreates it on the next enable, so removal is free and reversible; leaving a 417 MB dataset named _phase2-albumartist-control behind is the forgotten-artefact shape this plan exists to close"

patterns-established:
  - "A configured setting is not a firing setting. 02-06 read folder_name back from the API and it was still not what the scanner used on 3 of 5 control albums"
  - "MA's own log line is the ground truth for which fallback fired; the library row cannot distinguish a correct Various Artists compilation from a fallback"

requirements-completed: [CONS-02]
requirements-carried: [CONS-03]

metrics:
  duration: "~27 min"
  completed: 2026-09-01
  tasks_completed: 3
  tasks_total: 3
---

# Phase 02 Plan 07: Criterion 3 and the Album-Artist Fallback Summary

**Criterion 3 passes — three albums, exact on both halves, in seconds rather than twelve hours. And
the control did the job it was written to do: it FAILED first, and the failure is the most valuable
thing this plan produced.**

`missing_album_artist_action: folder_name` is not "use the parent folder's name". It fires only when
the file's `album` **tag** agrees with its album **folder** name. When it does not, Music Assistant
silently falls back to `Various Artists` — with the setting read back as `folder_name` from the API
the whole time. That was isolated with a four-cell variant matrix, not inferred. Had this shipped on
02-06's read-back alone, its first real exercise would have been the Phase 7 pilot, at scale,
against a library where album identity is `albumartist + os.sep + album` and a wrong album artist is
therefore durable.

The same sync also surfaced a live defect in the real library: `Def Leppard/Def Leppard (2015)/`
derives an **empty** album artist and hard-errors one file, because the album folder name equals the
artist folder name. It is recorded and **not repaired** — D-05 forbids tag repair, the export is
`ro`, and nobody holds `rw` on Music until Phase 6.

## Status

| Task | Disposition |
|------|-------------|
| Task 1 — deliberate `music/sync`, criterion 3 | **Complete, PASS.** 3/3 exact matches, provider-attributed. Trigger to settled: **177 s**. |
| Task 2 — prove `folder_name` fires, on a control | **Complete, PASS — after the first control FAILED.** The failure is the finding; the variant matrix isolated the cause and two later controls fired the fallback. D-08 substitute asserted. |
| Task 3 — teardown, both sides | **Complete.** All four D-46 assertions green. The teardown mechanism itself had to be built — it did not work as authored. |

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | *(none — `<files>none in-repo</files>`)* | MA library state on the NUC. Same precedent as 02-05 Tasks 1/2/3 and 02-06 Task 1. Stated so the absence is not read as skipped work. |
| 2 | `ed1d367` | `fix(02-07): stop MA's search argument reporting a false miss, and scope temp-export rows` |
| 3 | `d7430ee` | `fix(02-07): make music_temp_export_enabled=false an actual teardown` |

---

## TASK 1 — CRITERION 3, PROVEN (D-10)

### The sync was triggered, not waited out (D-38)

```
music/sync {"providers":["filesystem_local--XJaJWNUS"],"media_types":["track"]}

trigger        2026-09-01T10:05:43Z
started_at     2026-09-01T10:05:43.805042+00:00
finished_at    2026-09-01T10:08:40.323491+00:00
ELAPSED        177 s   (settled album count observed at 183 s by polling)
progress_text  "Processed 875/875 files"
status         partial_success   <- 1 failure, diagnosed below
```

`sync_interval` was **not** touched and remains at its 12-hour default — the task's own schedule
block reads `{"type":"hourly","every":12}` after the run. D-38 holds: shortening it is blunt, and
02-08's automation collapses the window for the case that actually matters.

Provider-filtered album count over the run: **20 → 70**. Polled every 8–10 s against
`music/albums/library_items` with `provider` set, and against `tasks/get` for the task status, so
the assertion could not read a half-populated library (MA's concurrency guard logs "Library sync
already running" and returns, which would otherwise look like a completed sync).

### The three albums — expected vs got, verbatim

Exact, byte-for-byte, on **both** halves. No substring, no case folding.

| Shape | Expected `album` | Got `album` | Expected `albumartist` | Got `artists[0].name` | `provider_mappings` |
|---|---|---|---|---|---|
| single-artist | `Lifelines` | `Lifelines` ✅ | `Chris Norman` | `Chris Norman` ✅ | contains `filesystem_local--XJaJWNUS` ✅ |
| multi-disc | `The Ultimate Hits` | `The Ultimate Hits` ✅ | `Garth Brooks` | `Garth Brooks` ✅ | contains `filesystem_local--XJaJWNUS` ✅ |
| various-artists (D-08 substitute) | `Mastermix Essential Hits - Pop 4 - 2005-2009` | `Mastermix Essential Hits - Pop 4 - 2005-2009` ✅ | `Various Artists` | `Various Artists` ✅ | contains `filesystem_local--f5gkrCpU` ✅ (temporary provider — Task 2) |

Artist-side cross-check, `music/artists/library_items` filtered to the same instance, exact name:

```
Chris Norman  -> 1 exact hit
Garth Brooks  -> 1 exact hit
```

`music/albums/library_items` filtered to `filesystem_local--XJaJWNUS`: **70** (target ≥ 3).
`music/albums/count` was **not** used — it has no provider parameter and reports off Spotify's
catalogue (02-04's finding, unchanged).

**Spotify remains live and `auth_required`**, still returning library items. Every assertion above
is provider-filtered server-side *and* re-checked against `provider_mappings[].provider_instance`
client-side. The filter was not relaxed.

**MA version: `2.11.0b0`**, recorded live alongside every assertion, as the amended D-21/D-56 require.

### `check-music-consumers.sh`

- With the temporary control standing and `MA_TEMP_PROVIDER_INSTANCE` pinned: **exit 0**, `albums
  matched in MA: 3`, `FAILURES total: 0`. Full section output under Task 2.
- After teardown, no temp pin: **exit 0**, `albums matched in MA: 2 (target 2)`, `MA out-of-scope: 1`.
- `--baseline` → 0, `--bogus` → 2, `bash -n` → 0. Contract intact.

Getting there required a real bug fix in the instrument — see deviation 1.

### Nothing was written to the library

```
find /mnt/tank/media/Music -newermt '2026-09-01 10:04:00 UTC' | wc -l   ->  0
find /mnt/tank/media/Music | wc -l                                      ->  2674
find /mnt/tank/media/Music -maxdepth 1 -type f -name '*.txt' | wc -l    ->  0
zfs list -o used tank/media/Music                                       ->  33.9G
```

Checked after Task 1, after Task 2, and again at plan close. All zero, all three times.

### The one failure in the sync — diagnosed, NOT repaired (D-05)

`partial_success`, `failure_count: 1`:

```
Failed to process Def Leppard/Def Leppard (2015)/CD 01-06 Def Leppard - Sea of Love.flac:
```

The provider's own log says why:

```
WARNING  Def Leppard/Def Leppard (2015)/CD 01-06 ... .flac is missing ID3 tag [albumartist],
         using foldername  as fallback                      <-- EMPTY foldername
ERROR    Error processing Def Leppard/Def Leppard (2015)/CD 01-06 Def Leppard - Sea of Love.flac -
```

Two files in that folder hit it; one errored hard. The file is fine — 33 MB, readable, `zpool status
-v tank` reports `errors: No known data errors` and the last scrub repaired 0 B. **The album folder
name equals the artist folder name**, and MA's folder-name derivation returns an empty string for
that shape.

**No remedy was attempted, and none was available.** D-05 states the remedy is never tag repair;
Phase 1's D-20 gives nobody `rw` on Music until Phase 6; and the export is `ro` at the export layer
(02-05 proved a hand-rolled `mount -o rw` still gets `EROFS`). This is recorded for Phase 7, which
will meet it at scale.

**This does not affect criterion 3.** Neither `Chris Norman/Lifelines (2026)` nor
`Garth Brooks/The Ultimate Hits (2007)` has an album folder matching its artist folder.

---

## TASK 2 — THE FALLBACK FIRES, AND THE CONDITION UNDER WHICH IT DOES NOT

### The temporary export

`terraform plan -out=`, read as JSON, then `terraform apply <plan file>` — never a bare apply.

```
creates=1            null_resource.nfs_music_temp_export[0]
destroys=0
updates=0
replacements=0
selfhost_non_noop=0  <-- proxmox_virtual_environment_container.selfhost : no-op
```

`exportfs -v` on atlantis, continuation lines joined before parsing (the `client(options)` field
wraps onto its own line for these paths):

```
/mnt/tank/downloads/_phase2-albumartist-control 172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
/mnt/tank/media/Music                           172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
```

| Assertion | Result |
|---|---|
| `exportfs -v \| grep -cE '^/mnt/tank'` | **2** |
| both lines `ro` | 2/2 ✅ |
| both lines `all_squash` | 2/2 ✅ |
| both `anonuid=568` / `anongid=568` | 2/2 ✅ |
| client is exactly `172.16.1.31` | 2/2 ✅ |
| `no_root_squash` present | **0** ✅ |
| wildcard or CIDR client | **0** ✅ |
| `grep -c 'media/Music' <<< "$music_temp_export_path"` | **0** ✅ (T-02-28) |

Scratch dataset `tank/downloads/_phase2-albumartist-control`, its own ZFS dataset (so the export's
`mountpoint` option holds), `apps:apps`.

### The client half

`ha mounts add music_temp_control --type nfs --usage media --server 172.16.1.158 --path
/mnt/tank/downloads/_phase2-albumartist-control --read-only` → `state: active`, `read_only: true`,
`user_path: /media/music_temp_control`. Visible **inside the running MA container**:

```
2199 2373 0:335 / /media/music_temp_control ro,relatime master:1124 - nfs4
  172.16.1.158:/mnt/tank/downloads/_phase2-albumartist-control ro,vers=4.2,...,sec=sys,
  clientaddr=172.16.1.31,addr=172.16.1.158
```

`master:1124` — propagated `rslave` into a long-running container, the same mechanism 02-05 proved.

### The second provider, headless, WITH its second save

```
config/providers/setup {"provider_domain":"filesystem_local"}      -> flow_id
config/flows/submit    {values:{content_type:"music",
                                path:"/media/music_temp_control"}} -> result.instance_id
config/providers/save  {values:{missing_album_artist_action:"folder_name"}}   <-- THE SECOND CALL
```

**THE SECOND PROVIDER INSTANCE ID: `filesystem_local--f5gkrCpU`**

Read back via `config/providers/get`, after the save:

```json
{"instance_id":"filesystem_local--f5gkrCpU","domain":"filesystem_local","type":"music",
 "enabled":true,"name":null,"status":"loaded","last_error":null,
 "content_type":"music","content_type_read_only":true,
 "missing_album_artist_action":"folder_name","default_value":"various_artists"}
```

Path proven **functionally** (MA 2.11 does not expose `path`, 02-06's finding, reconfirmed):
`music/browse "filesystem_local--f5gkrCpU://"` listed exactly the two staged top-level folders.

### THE CONTROL FAILED FIRST. That is the finding.

Control V1 — folder `ZZ Phase2 Fallback Control`, album folder `Untagged Control Album (2026)`,
album tag `Phase2 Fallback Control Album`, track artist `Control Track Artist Decoy`, **no
`albumartist` tag** (confirmed by `ffprobe` before the sync: `albumartist_tag_count=0` on both
files):

```
WARNING  ZZ Phase2 Fallback Control/Untagged Control Album (2026)/01 Control Track One.mp3
         is missing ID3 tag [albumartist], using Various Artists as fallback
```

`artists[0].name` came back as `Various Artists`. **With `missing_album_artist_action` reading back
as `folder_name` from the API at that exact moment.**

An explicit `config/providers/reload` (setting re-read as `folder_name`, `status: loaded`) plus a
`touch` to force a re-scan changed nothing — the same `using Various Artists as fallback` line. So
it is not a staleness or ordering problem.

### The variant matrix — one sync, and the variable is isolated

Three more one-track control albums, staged and synced together:

| # | artist folder | album folder | `album` TAG | track `artist` TAG | MA's own log line | `artists[0].name` |
|---|---|---|---|---|---|---|
| V1 | `ZZ Phase2 Fallback Control` | `Untagged Control Album (2026)` | `Phase2 Fallback Control Album` — **mismatch** | decoy | `using Various Artists as fallback` | `Various Artists` |
| V2 | `QQ Control Bravo` | `Bravo Album (2026)` | `Bravo Album` — **match** | matches folder | `using foldername QQ Control Bravo as fallback` | **`QQ Control Bravo`** ✅ |
| V3 | `QQ Control Charlie` | `Charlie Album (2026)` | `Charlie Album` — **match** | **decoy** (`Charlie Decoy Artist`) | `using foldername QQ Control Charlie as fallback` | **`QQ Control Charlie`** ✅ |
| V4 | `QQ Control Delta` | `Delta Album (2026)` | `Phase2 Mismatch Album` — **mismatch** | matches folder | `using Various Artists as fallback` | `Various Artists` |

**The determinant is the `album` TAG vs the album FOLDER name.** V3 proves the track artist is
irrelevant — a decoy artist matching nothing still produced the folder name. V4 proves an agreeing
track artist does not rescue a mismatched album tag.

This also explains the `Def Leppard (2015)` empty case: MA appears to locate the album directory by
matching the album tag against the path, then take its **parent** as the album artist. When the album
tag is `Def Leppard` and the path is `Def Leppard/Def Leppard (2015)/…`, the match lands on the
top-level `Def Leppard` directory, whose parent is the provider root — hence an empty album artist.

### D-03 SATISFIED — the fallback is proven to fire, not merely configured

The acceptance criterion asks for a control album returning `artists[0].name` equal to its folder
name, and for that name to be **neither** `Various Artists` **nor** any track artist present in the
files. **V3 satisfies all three explicitly:**

```
album      = "Charlie Album"
artists[0] = "QQ Control Charlie"      == the containing artist folder name, byte-identical
             != "Various Artists"      (checked)
             != "Charlie Decoy Artist" (the only track artist in the file — checked)
provider_mappings = ["filesystem_local--f5gkrCpU"]   (the SECOND instance, never the first)
```

And independently, at real scale: the criterion-3 sync fired `folder_name` **183 times** across the
live library —

```
57  using foldername Def Leppard as fallback
36  using foldername Taylor Swift as fallback
28  using foldername Ed Sheeran as fallback
27  using foldername Katy Perry as fallback
17  using foldername Hawthorne Heights as fallback
16  using foldername Sabrina Carpenter as fallback
 2  using foldername  as fallback          <-- the Def Leppard (2015) empty case
```

The setting is not merely configured. It is working, at scale, and its precondition is now known.

### The D-08 substitution, exercised rather than skipped

02-04 recorded D-08 firing: the 13-folder library has no Various Artists compilation at all. The
substitute was staged as required, through this same temporary export:

```
/mnt/tank/downloads/_phase2-albumartist-control/Various Artists/Mastermix Essential Hits - Pop 4 - 2005-2009/
  50 mp3 files, tags untouched   (album_artist=Various Artists, album=Mastermix Essential Hits - Pop 4 - 2005-2009)
```

Asserted exactly as Task 1 asserted the other two: album name and `artists[0].name` both
byte-identical to the pin, provider-attributed to `filesystem_local--f5gkrCpU`. **The shape it
covers is the various-artists compilation** — the one QUAL-03 calls historically painful here, and
the one the library could not supply.

Copied with plain `cp`, never `rsync -a`: `-a` fails `mkstemp ... Operation not permitted` on `tank`
while printing stats that look like success and exiting 23.

### `check-music-consumers.sh` with the control standing — exit 0

```
💿 3. The three proof albums in Music Assistant
  [single-artist]   ✅ exact match in MA, provider-attributed to filesystem_local--XJaJWNUS
  [multi-disc]      ✅ exact match in MA, provider-attributed to filesystem_local--XJaJWNUS
  [various-artists] ✅ exact match in MA, provider-attributed to filesystem_local--f5gkrCpU

📊 6. Summary
  MA version (live):           2.11.0b0   (assertions proven at 2.11.0b0)
  pinned provider instance:    filesystem_local--XJaJWNUS
  temp provider instance:      filesystem_local--f5gkrCpU
  albums matched in MA:        3   (target 3, exact name+albumartist, provider-attributed)
  albums matched in Jellyfin:  2   (target 2, exact name+albumartist)
  jellyfin out-of-scope:       1   (scope!=library — reported, not asserted)
  MA albums, local provider:   70   (target >= 3)
  export assertions failed:    0
  MA assertions failed:        0
  Jellyfin assertions failed:  0
  FAILURES total:              0
✅ Both music consumers see the pinned albums through the NFS export      EXIT=0
```

The second provider did not disturb the criterion-3 result: sections 1, 4 and 5 are unchanged, and
the two library albums are still credited to the **first** instance id.

---

## TASK 3 — TEARDOWN, BOTH SIDES (D-46), IN B-9 ORDER

### 1. Remove the second MA provider — and what MA actually did

`config/providers/remove {"instance_id":"filesystem_local--f5gkrCpU"}` returns `null` (no body) and
completes. **Observed, not assumed:**

| Instrument | Before | After |
|---|---|---|
| albums attributed to the temp instance | 5 | **0** |
| tracks attributed to the temp instance | 55 | **0** |
| artists attributed to the temp instance | 47 | **0** |
| TOTAL albums in the MA library, all providers | 84 | **79** (exactly −5) |
| `Charlie Album` anywhere in the library | 1 | **0** |
| `Phase2 Fallback Control Album` anywhere | 1 | **0** |
| `Mastermix Essential Hits - Pop 4 - 2005-2009` anywhere | 1 | **0** |
| albums on the MAIN provider | 70 | **70** — untouched |

**It is a complete purge of everything exclusive to that instance, with no orphans left behind.**
That is the good news and the warning in one: it is the same code path Phase 7 would have to use to
clear a wrong-album-artist entry, and the cost is every favourite and play count attached to those
items. Which is exactly why the three-album gate runs before content flows.

### 2. Unmount on the NUC

`ha mounts remove music_temp_control` → `Command completed successfully`, exit 0. Residual client
mounts: `grep -c music_temp_control /proc/self/mountinfo` → **0**, from the host and from inside the
MA container. Supervisor left an empty `/media/music_temp_control` stub behind; it was `rmdir`'d
(needs `sudo`), so `/media` reads `frigate music` again — its pre-plan state, from the host and from
inside MA.

Client before server, per B-9: nothing held an open file handle when the export went away.

### 3. Disable the export in Terraform — through the gate

```
creates=1              null_resource.nfs_music_temp_export_teardown
destroys=1
destroy_addresses      null_resource.nfs_music_temp_export[0]     <-- the ONLY destroy
selfhost_non_noop=0    proxmox_virtual_environment_container.selfhost : no-op
main_export_non_noop=0 null_resource.nfs_music_export             : no-op
```

Applied from the saved plan file. The reconciler's own output, from the apply log:

```
--- export table after temp-export reconcile ---
/mnt/tank/media/Music
		172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
```

**This step did not work as authored and had to be built.** See deviation 2 — a `null_resource`
destroy removes nothing from the host.

### THE FOUR D-46 ASSERTIONS

| # | Assertion | Result |
|---|---|---|
| 1 | `exportfs -v` shows only the Music line | ✅ `grep -cE '^/mnt/tank'` → **1**; the remaining line is **byte-identical** to 02-03's and 02-05's record; `/etc/exports.d/` holds `music.exports` alone, `music-temp.exports` gone |
| 2 | `music/albums/library_items` for the second instance returns nothing | ✅ raw body `[]`, length **0** |
| 3 | the second provider is absent from `config/providers` | ✅ matches for `filesystem_local--f5gkrCpU` → **0**; `filesystem*` providers → **1**, and it is `filesystem_local--XJaJWNUS`, the **first** one, the one pinned in the audit script |
| 4 | `terraform plan -detailed-exitcode` exits 0 | ✅ **0** — *"no differences, so no changes are needed"* |

**These four are D-45's rollback test. They have now been executed once against real state**, so
02-09's rollback runbook documents a tested procedure rather than a hoped-for one — including the
part that did not work, which is the half a runbook most needs.

### The scratch dataset — removed, and why

The plan allowed either. **Removed:** `zfs destroy -r tank/downloads/_phase2-albumartist-control`
(417 MB, 1 dataset, 0 snapshots, confirmed no longer exported first). `tank/downloads` avail back to
9.01 T after the ~25 s ZFS async free lag. Terraform recreates it on the next enable
(`zfs list … || zfs create -p`), so removal is free and reversible — while leaving a 417 MB dataset
named `_phase2-albumartist-control` lying around is precisely the forgotten-artefact shape this plan
exists to close. `terraform plan -detailed-exitcode` re-run afterwards: still **0**.

The first provider and the main export were not touched at any point.

---

## Deviations from Plan

### 1. [Rule 1 — Bug] MA 2.11's `search` returns `[]` for an album's own exact name

- **Found during:** Task 2, when the VA album asserted green by hand but red through the script.
- **Issue:** `check-music-consumers.sh` passed the expected album name as MA's `search` argument.
  `search` is **not** a substring match. Measured, from the same provider in the same second:

  ```
  search "Mastermix Essential Hits - Pop 4 - 2005-2009"  ->  []          (its own exact name)
  search "Mastermix"                                     ->  the album
  no search                                              ->  the album
  ```

  The script then reported `no exact match … candidates were: <none>` — **indistinguishable from the
  album being genuinely absent.** Short names (`Lifelines`, `The Ultimate Hits`) happen to work,
  which is what makes it dangerous: it looks fine until an album with punctuation and digits fails.
  This is a false FAILURE on a gate whose entire value is being trusted, and it would have reported
  this plan's genuine success as a failure.
- **Fix:** section 3 now filters on `provider` **only** — the provenance filter is load-bearing and
  is untouched — and does the byte-exact comparison locally in `jq`, where the semantics are ours.
  Added `MA_LIBRARY_SCAN_LIMIT=2000` with a truncation warning, so a capped list can never
  masquerade as a clean miss. Near-miss diagnostics now lead with case-insensitive name matches, so
  "same album, wrong album artist" — the line that names *which* fallback fired — is not lost in a
  dump of every album the provider holds.
- **Files modified:** `scripts/check-music-consumers.sh`. **Commit:** `ed1d367`.

### 2. [Rule 1 — Bug] `music_temp_export_enabled = false` was NOT a teardown

- **Found during:** Task 3, before running it.
- **Issue:** `infra/nfs-music-export.tf`'s own header states *"the resource is destroyed, the drop-in
  file is removed and the kernel table is re-converged"*. The first clause was true and the other two
  were not: `null_resource` has **no destroy-time provisioner anywhere in `infra/`** (`grep -c 'when
  = destroy'` → 0). Destroying it drops state only. `/etc/exports.d/music-temp.exports` would have
  stayed on disk and the export would have stayed **live**, while `terraform plan` reported clean and
  state said the resource was gone. That falsifies D-15's *"provably gone rather than forgotten"*
  outright and would have failed Task 3's own acceptance criterion.
- **Fix:** `null_resource.nfs_music_temp_export_teardown` — always present, no `count`, triggered on
  the flag itself, removing the drop-in and re-converging `exportfs` at **apply** time. It asserts
  the end state both ways: two `/mnt/tank` export lines while enabled, exactly one after teardown.
- **Two routes tried and rejected first, both recorded because the rejection is the lesson:**
  - A `provisioner { when = destroy }` on the temp resource. `terraform validate` **refuses** it:
    *"Destroy-time provisioners and their connection configurations may only reference attributes of
    the related resource, via 'self', 'count.index', or 'each.key'"* — the resource-level
    `connection` block reads `var.proxmox_host` / `_ssh_user` / `_ssh_password`. The only workaround
    is carrying those in `triggers`, which persists the **Proxmox root password** to state in
    plaintext **and renders it into every `terraform plan` diff**, in a **public** repo that has
    already had one six-month credential exposure. Not a trade worth making to save a resource block.
  - `self.triggers.*` for the paths. Rejected on its own merits: at destroy time a trigger is read
    from **state**, so a key added to the config *after* the resource was created reads back `null`
    — `rm -f ""` and, far worse, `grep -q ""`, which matches every line. A teardown has to work
    against state written before the teardown existed, or it is not a teardown.
  - The main `nfs_music_export` resource was deliberately **not** given the trigger: that would plan
    a replacement of the load-bearing Music export every time the scratch flag moved, and re-running
    `systemctl enable --now nfs-server` against a live export to clean up a scratch one is the wrong
    blast radius.
- **Files modified:** `infra/nfs-music-export.tf`. **Commit:** `d7430ee`.

### 3. [Rule 2 — Missing critical functionality] `scope=temp-export` rows could never be green

- **Issue:** the audit script filtered every proof album on `MA_LOCAL_PROVIDER_INSTANCE`. The VA
  album is served by the **temporary** provider, which D-15 requires be torn down. So that row could
  be green only while a temporary control was standing, and permanently red the rest of the time —
  the exact failure 01-09 recorded when it scoped the library-mode assertion down to a report,
  because *"a permanently-red check trains the reader to ignore it"*.
- **Fix:** `MA_TEMP_PROVIDER_INSTANCE`, empty by default. `scope=temp-export` rows are **fully
  asserted** when it is set and **reported with the reason inline** when it is not — never a silent
  pass, never a permanent red. `scope=library` rows are untouched and always asserted. The summary
  gained a `MA out-of-scope` counter and the "albums matched in MA" target adjusts, matching
  section 4's existing out-of-scope idiom exactly.
- **Both states exercised in this plan:** exit 0 with the pin set and 3/3 asserted; exit 0 after
  teardown with the pin cleared and the row reported.

### 4. [Rule 2 — Recorded, not concealed] The first control FAILED and three more were staged

The plan asks for *"a deliberate control album"*, singular. The first one returned `Various Artists`.
Rather than adjusting it until it passed, three variants were staged to isolate the variable, and
the matrix is reported above **including the two cells that still fail**. The negative result is the
plan's most valuable output and it is stated as a finding, not smoothed away.

### 5. [Rule 2 — Recorded] A live library defect was found and deliberately not fixed

`Def Leppard/Def Leppard (2015)/` derives an empty album artist and hard-errors one file. D-05 makes
tag repair the wrong remedy on principle, and the `ro` export makes it unavailable in fact. Recorded
for Phase 7. `zpool status -v tank` was checked to rule out the 2026-07 scrub damage: `errors: No
known data errors`.

### 6. [Rule 2 — Recorded] `requirements.mark-complete` ticked CONS-03; the tick was reverted

`gsd-sdk query requirements.mark-complete CONS-02 CONS-03` marked CONS-03 done. **Reverted by hand.**
CONS-03 reads *"Music Assistant's view survives a **NUC reboot**"* and **no reboot was performed in
this plan** — the plan's own frontmatter lists `requirements: [CONS-02]` only. The two halves 02-06
carried forward (the deliberate sync, the VA album through the temporary export) are both done and
are recorded as such in the traceability row; the reboot itself is not. Six times in Phase 1 a check
reported a pass it had not earned, all from the same root — partial data stated as settled — and this
would have been the seventh.

### Not fixed — logged, out of scope

- **Spotify is still `auth_required`.** Pre-existing, not caused here, not fixed. Still enabled and
  still returning library items, so the provider filter stays exactly as strict as it was.
- **`git pull` on LXC 100 still cannot land the audit script.** This tree is now ahead 36 / behind 9
  of `origin/main`. The script was `scp`'d in for every run and **removed again** afterwards
  (verified absent), following 02-04/02-05/02-06 practice. Pushing unreviewed commits to a public
  repo is outside this plan's scope. **02-09 must resolve the push/pull.**
- Two pre-existing untracked files on LXC 100 (`prometheus.yaml.bak`,
  `monitoring.app.yaml.disabled`), unchanged since 02-04.
- The untracked `body.txt` at repo root, left alone as in 02-03 through 02-06.
- **`gsd-sdk`'s `state.*` verbs corrupted STATE.md again, repaired by hand and diffed before
  committing.** Three specific corruptions, the same family both prior plans hit: frontmatter
  `percent` written as **11** while the progress bar line said **89%**; `last_activity` truncated to
  a bare date in **both** places, losing the description; and every decision tagged `[Phase ?]`
  rather than `[Phase 2]`. Also `state.add-decision` and `state.record-metric` take **named** flags
  (`--summary`, `--phase/--plan/--duration`), not positionals — passed positionally they return
  `{"error": ...}` and, if the output is discarded, write nothing while looking like success. A
  `git diff .planning/STATE.md` against a pre-write copy is the only reliable check.
- **M1 (the `mountpoint` export option) is still unproven client-side.** Not in this plan's scope and
  not attempted here; 02-05's record and instrument stand.

## Authentication gates

None. `/mnt/fast/secrets/ma-deercrest.env` (0600 root) authenticated on every call, with a **fresh
JWT minted per invocation** and never cached; the password reached `curl` only through a `jq`-built
body on `--data-binary @-`, never argv. The NUC was reached over the tailnet address
`100.73.196.51` — its LAN IP `172.16.1.31` is unreachable from a tailnet vantage while it is the
standby subnet router (02-05's deviation 1, unchanged).

---

## Wave gate

Run before closing, so a Phase 1 regression cannot hide behind a Phase 2 pass.

### `check-music-consumers.sh` → exit **0** (assert mode, no `--baseline`)

Post-teardown steady state, full summary block reproduced under Task 3. `FAILURES total: 0`.

Exit-code contract re-verified after the edits: default **0**, `--baseline` **0**, `--bogus` **2**,
`bash -n` **0**.

### `check-music-freeze.sh` → exit **0**

```
  tagger-class writers:        0   (target 0)
  consumer-class writers:      1   (Jellyfin, documented exception D-21)
  unclassified writers:        0   (target 0)
  declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
  artist folders:              13
  ownership mismatches:        0   (target 0, want 568:568)
  sidecars found (widened):    1341   (nfo 91 / jpg 88 / lrc 944 / png 43 / txt 175)
  sidecars found (narrow D-18):1123
  fence assertions failed:     0
  FAILURES total:              0
✅ Music freeze harness intact
```

**Byte-identical to 01-09's closure and to 02-03's, 02-05's and 02-06's after-states.** A full
875-file re-sync of the library plus a second provider, a second export and a second mount changed
no inode, no owner and no sidecar count.

### Host health, after the plan

```
uptime -s                                    2026-08-31 18:48:08   (unmoved — no crash)
/proc/pressure/io  full avg300               0.19                  (the 2026-08-31 halt was 96.22)
dmesg -T | grep -c amdgpu_hmm_invalidate_gfx 0
```

---

## Requirements

| Req | State after this plan | Owner |
|---|---|---|
| CONS-01 | Complete (02-03 + 02-05). Section 1 still 10/10 green. | closed |
| **CONS-02** | **COMPLETE.** Criterion 3 proven: 3/3 albums, exact on album name AND album artist, provider-attributed, in Music Assistant. | 02-06 + **02-07** |
| CONS-03 | **Pending — deliberately NOT ticked.** Its mount-liveness half is green (177 s `music/sync`, 70 albums attributed, the VA shape served and asserted). But the requirement reads *"survives a **NUC reboot**"* and **no reboot was performed here**. The two halves 02-06 carried forward — the deliberate sync and the VA album — are both done; the reboot is what remains. `gsd-sdk query requirements.mark-complete` ticked it and the tick was **reverted by hand**: ticking a reboot that never happened is exactly the unearned pass this phase has recorded six times. | carried |

## Threat Register Status

| Threat ID | Disposition | Status after this plan |
|-----------|-------------|------------------------|
| T-02-12 | mitigate | **CLOSED.** Both export lines carried `ro`, `all_squash`, `anonuid=568`, `anongid=568` and the single client `172.16.1.31`; neither carried `no_root_squash` or a wildcard. Counts recorded above. The temporary line is now gone. |
| T-02-28 | mitigate | **CLOSED.** The control lived under `tank/downloads`, a separate dataset; `grep -c 'media/Music'` on the staging root → 0; `find /mnt/tank/media/Music -newermt '<plan start>'` → **0** after every task and at close. Entry count 2,674 and `zfs used` 33.9 G unchanged throughout. |
| T-02-16 | mitigate | **CLOSED.** Every assertion filtered by instance id, server-side and re-checked against `provider_mappings` client-side. The temp instance id was recorded separately and the control asserted **only** through it. The full consumers check ran with the control up and again after teardown; the criterion-3 result is identical in both. |
| T-02-29 | mitigate | **CLOSED — and the mitigation had a hole, now fixed.** The flag defaulting to `false` was necessary but NOT sufficient: the destroy removed nothing from the host. Teardown is now a real reconcile; `exportfs -v \| grep -cE '^/mnt/tank'` → **1** and `terraform plan -detailed-exitcode` → **0**. |
| T-02-30 | mitigate | **CLOSED.** Teardown ran via `terraform apply` on a read saved plan. No `exportfs -u` was ever hand-run; the clean-plan assertion afterwards would have caught out-of-band change. |
| T-02-31 | mitigate | **CLOSED.** B-9 order followed exactly: MA provider removed, then the NUC mount, then the server-side export. Residual client mounts: 0, from the host and from inside the MA container. Nothing could block a future `zfs rollback`. |
| T-02-03 | mitigate | **Held.** The export stayed `ro`; nothing in this plan attempted a write to the library and the zero `find -newermt` count was asserted three times. |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: control-not-enforced | `MA provider config` (settings store on the NUC, no repo file) | `missing_album_artist_action: folder_name` reads back correctly from `config/providers/get` **and still does not fire** when a file's `album` tag disagrees with its album folder name — MA silently uses `Various Artists` instead. The configured value is therefore **not** a reliable predictor of behaviour, and album identity is `albumartist + os.sep + album`, so the resulting entry is durable. Phase 7 must treat album-tag/album-folder agreement as a precondition it checks, not one it assumes. |
| threat_flag: state-not-in-git | `MA provider config` (settings store on the NUC, no repo file) | Unchanged from 02-06 and re-confirmed on the second provider: MA 2.11 does not expose a filesystem provider's `path` through the API at all. It is recoverable only from a SUMMARY. |

## Known Stubs

None. Both temporary artefacts are removed and asserted removed on both sides. The one intentionally
unresolved item is the `Def Leppard (2015)` empty-album-artist defect, which is a **finding handed to
Phase 7**, not a stub: the remedy is forbidden here by D-05 and physically unavailable through a
read-only export.

## Self-Check

Files claimed created/modified:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-07-SUMMARY.md` — FOUND
- `scripts/check-music-consumers.sh` — FOUND, modified, `bash -n` exit 0
- `infra/nfs-music-export.tf` — FOUND, modified, `terraform validate` → Success

Commits:

- `ed1d367` — FOUND (`fix(02-07): stop MA's search argument reporting a false miss, and scope temp-export rows`)
- `d7430ee` — FOUND (`fix(02-07): make music_temp_export_enabled=false an actual teardown`)
- Task 1 produced no commit by design (`<files>none in-repo</files>`) — stated so the absence is not
  read as skipped work

Live state re-verified at close:

- `exportfs -v` on atlantis → **one** `/mnt/tank` line, byte-identical to 02-03's record — FOUND
- `/etc/exports.d/` → `music.exports` only; `music-temp.exports` absent — FOUND
- `config/providers` → exactly **1** `filesystem*` provider, `filesystem_local--XJaJWNUS` — FOUND
- `music/albums/library_items` for `filesystem_local--f5gkrCpU` → `[]` — FOUND
- `terraform plan -detailed-exitcode` → **0**, re-run after the dataset destroy — FOUND
- `ha mounts info` → the `music` mount alone, `state: active`, `read_only: true` — FOUND
- `/media` on the NUC and inside the MA container → `frigate music` — no stub left
- `zfs list tank/downloads/_phase2-albumartist-control` → `dataset does not exist` — FOUND
- `find /mnt/tank/media/Music -newermt '2026-09-01 10:04:00 UTC'` → **0**; 2,674 entries; 33.9 G
- `bash scripts/check-music-consumers.sh` → **0**; `--baseline` → 0; `--bogus` → 2
- `bash scripts/check-music-freeze.sh` → **0**, FAILURES 0
- `scripts/check-music-consumers.sh` on LXC 100 → removed after the wave gate (verified absent)
- MA version live at every assertion → **2.11.0b0**

## Self-Check: PASSED
