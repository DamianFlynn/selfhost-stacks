---
phase: 04-collapse-to-one-tagger
plan: 01
subsystem: infra
tags: [fence, baseline, sqlite, host-readonly, beets, wrtag, sabnzbd, d-12]

# Dependency graph
requires:
  - phase: 01-freeze-and-fence
    provides: "the /mnt/fast/safety/music-pre-project fence, its MANIFEST.txt and the 15 library-db copies"
provides:
  - "wrtag.db fenced for the first time (D-35): library-db/media_wrtag_data_wrtag.db, integrity ok, MANIFEST line 882"
  - "sabnzbd beets.log (Pitfall 13) and the survivor's config.yaml + config.yaml.old fenced into audit/ with MANIFEST lines 884/886/888"
  - "4-row re-confirmation of the Phase 1 survivor + sabnzbd DB copies (all sha y, integrity y)"
  - "24-row coverage preview for plan 04-11's deletion ledger (all 'not covered')"
  - "35-path sha256 baseline of every file Phase 4 touches, and the pre-phase ROUTINE BASELINE of both health checks"
  - "04-D12-EVIDENCE.md: the criterion-3 pass contract, written before any post-strip job"
affects: [04-07, 04-09, 04-11, 04-12, 04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fence additions are appended to the fence-ROOT MANIFEST.txt as a dated '## Phase 04 …' section; sha lines stay in sha256sum format and the source/mechanism/time/note go in the comment line above each"
    - "Live-source SQLite reads open file:…?mode=ro; fence-copy integrity checks open file:…?immutable=1, with the copy re-hashed before and after to prove the check wrote nothing"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md
    - .planning/phases/04-collapse-to-one-tagger/04-01-SUMMARY.md
  modified: []

key-decisions:
  - "MANIFEST.txt lives at the fence root (/mnt/fast/safety/music-pre-project/MANIFEST.txt), not library-db/ as the plan says; appended there rather than forking a second manifest"
  - "D-12 gains two pre-declared, non-loosening clarifications: sabnzbd.ini.bak is SABnzbd's own settings backup, and a clean() flatten is a MOVE (same sha256, new path), not a new file"
  - "beets.log skip evidence is counted per 'import started' session (the log carries no ISO dates), not by the plan's literal date grep"

patterns-established:
  - "Fence-write guard: refuse if the destination exists, .backup to a dot-partial, integrity_check ok, mv -n, then the MANIFEST line; prove append-only by re-hashing the pre-append prefix"

requirements-completed: []  # Deliberately empty: plan frontmatter lists [TAGR-03, TAGR-04], but 04-01 is a precondition plan and completes neither. Both are advanced, not satisfied, here.
requirements-advanced: [TAGR-03, TAGR-04]

# Metrics
duration: 13min
completed: 2026-09-11
---

# Phase 4 Plan 01: Fence, Baseline and D-12 Checklist Summary

**This plan fenced `wrtag.db` for the first time (`sqlite3 .backup` from a `mode=ro` source, `integrity_check` ok, MANIFEST line 882), and fenced `beets.log` plus both survivor configs into `audit/`. It re-confirmed all four Phase 1 DB copies and recorded a 35-path sha256 baseline, and both routine checks were green before any Phase 4 change. The criterion-3 pass contract was committed before any job ran.**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-09-11T17:52:50Z
- **Completed:** 2026-09-11 (~18:06Z)
- **Tasks:** 3 of 3
- **Files modified:** 2 in the repo (1 created by a task commit, plus this summary). On the host: 4 fence files and 13 lines appended to the fence `MANIFEST.txt`.

## Accomplishments

- D-04's precondition now holds for `wrtag.db`. Before this plan it failed as written (F2, D-35).
- `beets.log` is now fenced. It is the only record of the 1 Aug, 8 Aug and 6 Sep skips. It was copied off the public repo and into `audit/`, byte-identical to its source.
- Every file Phase 4 deletes has a measured before-value. Nothing under `/mnt/fast/appdata` changed: all 35 paths re-hash identically after the fence writes.
- The routine health checks were **green before the phase**: freeze RC 0, quick-health-check RC 0. Every wave boundary compares against that.
- D-29's probe album is present, with 12 FLAC files on a single disc.

## Task Commits

1. **Task 1: Measure the baseline, read-only.** No commit: host reads only, and the values are in this SUMMARY.
2. **Task 2: Fence wrtag.db, beets.log and the survivor configs; re-confirm the Phase 1 copies; preview coverage.** No commit: host-only writes to `/mnt/fast/safety`, recorded below.
3. **Task 3: D-12 evidence checklist.** `92557fb` (docs).

**Plan metadata:** this SUMMARY's own commit.

## Files Created/Modified

- `.planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md`: the criterion-3 contract. Sections 1–5 are fixed now; the section 6 Result is `PENDING — filled by 04-12`.
- Host `/mnt/fast/safety/music-pre-project/library-db/media_wrtag_data_wrtag.db` (new).
- Host `/mnt/fast/safety/music-pre-project/audit/sabnzbd-beets.log.20260911T180026Z` (new).
- Host `/mnt/fast/safety/music-pre-project/audit/arrs-beets-config.yaml.20260911T180026Z` (new).
- Host `/mnt/fast/safety/music-pre-project/audit/arrs-beets-config.yaml.old.20260911T180026Z` (new).
- Host `/mnt/fast/safety/music-pre-project/MANIFEST.txt`: lines 876–888 appended.

---

## Task 1: Measured baseline (2026-09-11, read-only)

### (a) Host checkout

| Item | Value |
|---|---|
| `git -C /mnt/fast/stacks rev-parse --short HEAD` | **`3327dcf`**. That is behind the workstation `main` (`2553acf`) and origin; the host needs a `git pull` before any plan runs a repo script there |
| `git status --porcelain \| wc -l` on the host | **2** (not inspected; left as found) |

### (b) Containers: unfiltered `docker ps -a`

| Item | Value |
|---|---|
| `docker ps -a` RC | 0 (non-empty output) |
| Total containers | **97** |
| Lines matching `wrtag\|soulbeet\|^beets$` | **0** |
| Positive control: `sabnzbd` present | 1 |

### (c) Resident images

| Image | Image ID | Size | Created |
|---|---|---|---|
| `sentriz/wrtag:v0.20.0` | `sha256:c435c4870104ef4cab4fb5f3d89dc61c84e80dcdcf221bd8d1a44f1d8f421cde` | 172 MB | 2026-01-17 |
| `lscr.io/linuxserver/beets:2.13.1-ls349` | `sha256:159e62e4d611cb61d5de0e14dcea41f2b77a3d6170fdf079edee6b80c40f2088` | 638 MB | 2026-08-29 |
| `metasauce/beets-flask:v2.0.0-rc6` | `sha256:2d817f8db5d7e1b64f7eaf668764d5967f0b2f25c4e721b1792f973b30558114` | 1.12 GB | 2026-08-30 |
| `ghcr.io/linuxserver/sabnzbd:5.1.0` | `sha256:64c505440b7814039438bdc60aa32fec8739425a7baa849a55912d48254aad0a` | 181 MB | 2026-08-16 |

The running `sabnzbd` container uses `ghcr.io/linuxserver/sabnzbd:5.1.0`, with the same image ID. **5.1.3, which PR #310 moves to, is not resident** (Pitfall 8 for the 04-11 recreate).

### (d) Files: absolute path, size, mtime (UTC), sha256

| Path | Size (B) | mtime (UTC) | sha256 |
|---|---|---|---|
| `/mnt/fast/appdata/media/wrtag/data/wrtag.db` | 315392 | 2026-01-23T00:03:02Z | `10414308d51ef59715ee144cee912e36626af153cab7a465e113e152003726de` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb` | 53248 | 2026-09-11T01:22:10Z | `b0eb3807939a0c33e599c9c07e7d671a0f37eb63b50aec4cf44366886a0a76ce` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-albums-multi_genre_field.bak` | 53248 | 2026-09-11T01:22:10Z | `6384628d99af84614adb9981c738d5f458813e3709ac89711c1ac7a2cb5e7152` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-albums-relative_path.bak` | 53248 | 2026-09-11T01:22:10Z | `f0db3d02f594eaa25f85c9f6f11c9fafdab5f92672a1e22393d5835bb04c984c` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-instrumental_lyrics_in_flex_field.bak` | 53248 | 2026-09-11T01:22:10Z | `4043771424ab57deaa719569d75cb1f3d237333fe8351a87416f3c32944b9f67` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-lyrics_metadata_in_flex_fields.bak` | 53248 | 2026-09-11T01:22:10Z | `623f81f4d325985f97e00b41bb0d38027980aab55292797874fca812f28a33d2` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-multi_arranger_field.bak` | 53248 | 2026-09-11T01:22:10Z | `ab4d35f7a8aeface57342807dc725aa6524b9b1a7c7a0bfdd0da21aec56dba14` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-multi_composer_field.bak` | 53248 | 2026-09-11T01:22:10Z | `568addcb1ad22ae542b037d271a896fd76aa91d67650dd553b85fe0a2d3ae31c` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-multi_genre_field.bak` | 53248 | 2026-09-11T01:22:10Z | `44a232614b49e4a54f470bf3969cb83ae9ced5b184bfe66b2f89ec391b78abc2` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-multi_lyricist_field.bak` | 53248 | 2026-09-11T01:22:10Z | `d90b372e8a8b0bdbce7ea2e1b0f121db0d60113a484d5da8fe4ef1108004f404` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-multi_remixer_field.bak` | 53248 | 2026-09-11T01:22:10Z | `ee744b7d9ff1597e1f21d9710d3e3f05679cb339d5bca853f0606274a61dd165` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-relative_path.bak` | 53248 | 2026-09-11T01:22:10Z | `8e74178fda124ce88b697570497810edef94e1228c983bbaa87c3e6981e93d5d` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb-before-items-remove_inherited_artpath.bak` | 53248 | 2026-09-11T01:22:10Z | `d0f26f5ed698d4428b1d1e0419ff449357582e4c35c936d5a58bfd9ca0f94411` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log` | 12046 | 2026-09-11T01:22:10Z | `7d95c924d442d77e35f12d574e37b7a4072ac2ed6a31ea5c3821829d41e056b2` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db` | 57344 | 2026-08-18T21:12:23Z | `00635fb3bc35beee44c08b29dce31d827ea5ba17c881e574e29398442861ff81` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-albums-multi_genre_field.bak` | 57344 | 2026-08-18T21:12:23Z | `f6e3444c39dc99ce930825ed4a08a64fe4f489d27e0deb3be57e6125ec7d6b8c` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-albums-relative_path.bak` | 57344 | 2026-08-18T21:12:23Z | `dad8c395e9a64f925e85d3c9e25014d3370a2fb0508c5cf6663052b96a395909` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-instrumental_lyrics_in_flex_field.bak` | 57344 | 2026-08-18T21:12:23Z | `d74fe7c0f36a1825100ac6834064e92b4aa8d4b0e3dafa0013c5d90b6dbb6610` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-lyrics_metadata_in_flex_fields.bak` | 57344 | 2026-08-18T21:12:23Z | `ffd3f14b1316e1f001b10d539073e59575e879eb65cb4162d9e2119a90263d71` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-multi_arranger_field.bak` | 57344 | 2026-08-18T21:12:23Z | `2f4ae43b15e3c807b19da827f0a436230ed021c1f49b11084d423fa928f83884` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-multi_composer_field.bak` | 57344 | 2026-08-18T21:12:23Z | `4b8923340d9237c53eae2b5455626874000a7bf3c0e0825d057c8d729ac216ae` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-multi_genre_field.bak` | 57344 | 2026-08-18T21:12:23Z | `86d6519bb022b7f0fb4c2e10dcaff50e373b05d82d6da4380f62baedbc73c497` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-multi_lyricist_field.bak` | 57344 | 2026-08-18T21:12:23Z | `56dd34c217e64d1314b1551c2d65acd7110c9d525dada528d49ee3124057bb4b` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-multi_remixer_field.bak` | 57344 | 2026-08-18T21:12:23Z | `d3245dbdad905cb4a83911eaa2b959368f75bc35d8f8781a2b53d206cbbe0b22` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-relative_path.bak` | 57344 | 2026-08-18T21:12:23Z | `d69ae2d2a5892df7d1caa13ff3ae4380c14fbb3ad0a9a6ca56984b1355dc8e1b` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db-before-items-remove_inherited_artpath.bak` | 57344 | 2026-08-18T21:12:23Z | `c99dec76c4d02ce1ac45b167c5237977c74614b3e261da921d8057a1eb7f7c2c` |
| `/mnt/fast/appdata/arrs/beets/config/library.db` | 53248 | 2025-11-18T13:50:21Z | `54440dd12c07799df5c5cbadcac3a35c32042938b21566f77109faab122314c6` |
| `/mnt/fast/appdata/arrs/beets/config/musiclibrary.blb` | 36864 | 2025-10-27T23:44:04Z | `98f9f13b94396375d065772c75fd1efa95a9b9810fcbac598dee7bd1f3ec1d10` |
| `/mnt/fast/appdata/arrs/beets/config/config.yaml` | 3293 | 2026-08-18T21:18:41Z | `8b09078d4779b44cf145fbbb886ea19bcf9e6048b1f3f8c0389b6b575037f1ae` |
| `/mnt/fast/appdata/arrs/beets/config/config.yaml.old` | 1419 | 2026-08-18T21:18:41Z | `0559906f6d89ea71c24285f9c7d512f53d9c03866ef1a4af63fa33788e30b184` |
| `/mnt/fast/appdata/arrs/beets/config/state.pickle` | 47 | 2025-11-18T13:50:21Z | `f6a9a1ad7aa553e42e53a8056fa80724785111180a5e2122be4f8732d1e4bc7c` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/audio.bash` | 10230 | 2026-07-31T07:27:58Z | `fdcddca234b282e4cb396764fa125fcacdbce350c21a94dd3f4ac024f87077ca` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml` | 6407 | 2026-08-18T21:18:41Z | `7a059a407d3ca18c9d7902c96267f75fa17ae134daf21d64f8bcbf7c073ee6ea` |
| `/mnt/fast/appdata/arrs/sabnzbd/config/extended.conf` | 2955 | 2025-10-24T08:41:54Z | `54c5433bba38c61e372425c34cc0c8aad2001922ca1fb6bd55e98dc1ada1b49d` |
| `/mnt/fast/appdata/arrs/soulbeet/beets_config.yaml` | 3084 | 2026-08-18T21:18:41Z | `83028925559bc8416a6da6a238bb6d1b20dbaed43f306a08e4395496cbbd3576` |

Notes on (d):
- The `library.blb*` siblings are exactly **11** `.bak` files, all named `library.blb-before-<table>-<migration>.bak`. The `.config/beets/` tree holds 12 regular files (the DB plus the same 11 migration names) and nothing else. No path was ABSENT or UNKNOWN.
- `audio.bash`: sha256 prefix `fdcddca234b2`, **339 lines**, as expected. The plan's Task 1 `<verify>` printed `BASELINE-AUDIO-OK`.
- `beets-config.yaml` on the host is `7a059a40…`, **equal** to `sha256sum stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` in the repo.
- `extended.conf` holds `ReplaygainTagging="false"` (line 27, followed by a trailing comment), `BeetsTagging="TRUE"` (line 28) and `requireBeetsMatch="false"` (line 29).
- `/mnt/fast/appdata/arrs/soulbeet/` contains `beets_config.yaml` (3,084 B) and an **empty** `data/`, and nothing else. Its `beets_config.yaml` (`83028925…`) is **equal** to the repo copy.

### (e) D-29 probe album

**`PRESENT 12 FLAC single-disc /downloads/complete/nzb/music/Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost (derived from beets.yaml line 18)`**

- Host path: `/mnt/tank/downloads/complete/nzb/music/Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost`. `find -maxdepth 5` returned exactly 1 match, with find RC 0.
- The folder holds 12 `*.flac` files at top level and 12 recursively. It has 0 subdirectories, so 0 subdirectories contain audio, and 12 files in total. Directory mtime: 2026-09-06T22:24:01Z.
- The volume line used is `stacks/selfhosted/arrs/beets/beets.yaml:18`, `- /mnt/tank/downloads:/downloads:rw`. The host prefix `/mnt/tank/downloads` maps to the container prefix `/downloads` as declared.
- No D-29 blocker. The tree is live, so 04-09 must still re-assert this before `up`.

### (f) SAB history baseline (F8)

Read with `sqlite3 "file:/mnt/fast/appdata/arrs/sabnzbd/config/admin/history1.db?mode=ro"`. These are the last 8 `category='music'` rows; `completed` is UTC.

| datetime(completed) | status | substr(script_line,1,60) |
|---|---|---|
| 2026-09-11 01:22:11 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-06 22:24:04 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-05 22:52:57 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-03 21:17:20 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-03 20:31:00 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-08-08 14:24:01 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-08-01 15:26:49 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-08-01 00:16:39 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |

- The whole history holds 119 `music` rows (the earliest at 2025-10-26 18:44:12 UTC). **87** of them are `Exit(1): chmod: changing permissions of '/downloads/complete/nzb/music/…`.
- The `PRAGMA table_info(history)` columns are: `id completed name nzb_name category pp script report url status nzo_id storage path script_log script_line download_time postproc_time stage_log downloaded completeness fail_message url_info bytes meta series md5sum password duplicate_key archive time_added`.
- **The final-path column is `storage`.** For all 119 music rows it starts `/downloads/complete/nzb/music/`, while `path` starts `/downloads/incomplete/` for all 119. These were measured as counts. That is the row-to-folder mapping 04-12 needs.

### (g) beets.log skip evidence

- beets.log is 178 lines: 89 `import started <ctime>` headers and 89 `skip <path>` lines. **No line carries an ISO date**, so the plan's literal `grep -c` of lines dated 2026-08-01, 2026-08-08 and 2026-09-06 containing `skip` returns **0 / 0 / 0** (see Deviations).
- Counted per session header instead:

| Date (Europe/Dublin) | Skip lines | Sessions (local) | Matching SAB row (UTC) |
|---|---|---|---|
| 2026-08-01 | **2** | 01:16:38, 16:26:49 | 00:16:39, 15:26:49 |
| 2026-08-08 | **1** | 15:24:01 | 14:24:01 |
| 2026-09-06 | **1** | 23:24:04 | 22:24:04 |

- The Scarecrow line, the only line quoted here: `176:skip /downloads/complete/nzb/music/Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost`. It sits under the header `import started Sun Sep  6 23:24:04 2026`.

### (h) GitHub

| Item | Value |
|---|---|
| PR #310 | **OPEN**. `chore(deps): update ghcr.io/linuxserver/sabnzbd docker tag to v5.1.3`. Labels: `renovate`, `automerge`, `safe`, `update:patch`, `type:stack`, `stack:arrs` |
| Issue #306 | **OPEN** |

### (i) ROUTINE BASELINE: the pre-phase state every wave boundary is compared against

Both checks ran before any fence write and before any Phase 4 change.

| Check | Where | Exit code | Elapsed | Ran against | `❌` lines | `⚠️` lines |
|---|---|---|---|---|---|---|
| `scripts/check-music-freeze.sh` | LXC 100, `cd /mnt/fast/stacks`, `timeout 150` | **0** | **17 s** | host HEAD `3327dcf` | none | `directory mode: 88 differ from 755 — REPORTED not asserted (D-12 scoped out, chmod impossible on tank)` and `file mode: 2586 differ from 644 — REPORTED not asserted (D-12 scoped out, chmod impossible on tank)` |
| `scripts/quick-health-check.sh` | workstation | **0** | 10 s | workstation `2553acf`. Its freeze fold-in runs the **host's** script at `3327dcf` | `Traefik dashboard: ❌ Not accessible` (report-only; the script still exits 0) | none |

- The freeze summary counters are: tagger-class writers 0, consumer-class writers 1 (Jellyfin, D-21), unclassified 0, declared rw reaching Music 0, ownership mismatches 0, fence assertions failed 0, FAILURES total 0.
- In quick-health-check, the fold-in's positive control is `Music freeze harness: ✅ Intact`, and `Jellyfin transcode retention: ✅ Transcode retention intact`.
- **Wave-boundary rule this sets:** both exit 0. The only `❌` is the Traefik dashboard line, and the only `⚠️` lines are the two permanent mode reports. Anything beyond that set is a regression until 04-11 promotes the candidate checks.

---

## Task 2: Fence writes and re-confirmation

- **Step 1:** `MANIFEST.txt` header line 1 is `# music-pre-project recovery fence - MANIFEST`. It has 875 lines before the append, and a pre-append sha256 of `d658859317b30afd936d915c9d4e426f639f7a2d23dee6fbf75684f786d3c10e`. Sha lines use `<sha256>  <absolute fence path>`, and appended sections carry a `## heading` with `# appended:` comments.
  - `audit/` **already existed**: `apps:apps 755`, created on 2026-08-18. `library-db/` is `apps:apps 755`. Nothing was created.
- **Step 2 (D-35):** the source header byte 18 is `1` (rollback journal, not WAL), and the source's `data/` holds `wrtag.db` only.
  - `sqlite3 "file:…/wrtag.db?mode=ro" ".backup …"` went to a dot-partial, then `integrity_check` returned **`ok`**, then `mv -n`.
  - The copy is `/mnt/fast/safety/music-pre-project/library-db/media_wrtag_data_wrtag.db`: 315,392 B, `root:root 0644`, sha256 `56861d39062c24dd685a5a9af27a45775937f55b21b86b176be3f5bc13440beb`.
  - The source sha256 was identical before and after. The copy recorded the note `phase 04 D-35`, and it is MANIFEST line **882**.
- **Step 3 (Pitfall 13):** `cp -p` produced `audit/sabnzbd-beets.log.20260911T180026Z`: 12,046 B, `apps:apps 0777` (preserved by `-p`), sha256 `7d95c924…` **equal to the source**. MANIFEST line **884**.
- **Step 4:**
  - `audit/arrs-beets-config.yaml.20260911T180026Z`: 3,293 B, sha256 `8b09078d…` equal to the source. MANIFEST line **886**.
  - `audit/arrs-beets-config.yaml.old.20260911T180026Z`: 1,419 B, sha256 `0559906f…` equal to the source. MANIFEST line **888**.
  - Both are `apps:apps 0770`.
- **Append-only proof:** MANIFEST went from 875 to **888** lines, and the first 875 lines still hash to `d6588593…` (`prefix_unchanged=y`). No `-wal`, `-shm` or `-journal` file was left in `library-db/`, and no `.partial` remains.

### Step 5: re-confirmation of the Phase 1 copies (D-04 / D-28 / D-32)

The source-to-fence mapping comes from `audit/library-db-sources.tsv`. Every Phase 1 row there reads `pre-existing`.

| Source | Fence file | MANIFEST line | MANIFEST sha matches | integrity ok |
|---|---|---|---|---|
| `/mnt/fast/appdata/arrs/beets/config/library.db` | `library-db/arrs_beets_config_library.db` | 846 | **y** | **y** |
| `/mnt/fast/appdata/arrs/beets/config/musiclibrary.blb` | `library-db/arrs_beets_config_musiclibrary.blb` | 847 | **y** | **y** |
| `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb` | `library-db/arrs_sabnzbd_config_scripts_library.blb` | 849 | **y** | **y** |
| `/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db` | `library-db/arrs_sabnzbd_config_.config_beets_library.db` | 848 | **y** | **y** |

- None of the four has an `n`, so there are no blockers.
- Each fence copy was re-hashed after its `integrity_check` (opened `immutable=1`), and all four were unchanged.
- **For 04-07 / 04-11:** no live source is byte-equal to its fence copy. That is expected: Phase 1 used `sqlite3 .backup`, which rewrites the page layout (the `freeze-music-apply.sh` 6b rationale), and sabnzbd's `library.blb` is regenerated on every music job. The survivor pair is unchanged since before the fence (mtimes 2025-11-18 and 2025-10-27). Their live sha256s in the (d) table are the "04-01 value" that 04-07 compares against.
- **Watch:** MANIFEST lines 847 and 848 carry the **same** sha256 (`b75527ea…`). Two different sources produced byte-identical 36,864 B `.backup` outputs, which means empty schema DBs. A sha-keyed ledger must match on the fence *path* too, or one line will appear to cover both sources.

### Step 6: coverage preview for 04-11's deletion ledger

Every one of the 24 files is **not covered**. That is the expected outcome of `.backup` copies and per-job regeneration. 04-11 fences each file at deletion time.

| # | Live file | Live sha256 (prefix) | MANIFEST coverage |
|---|---|---|---|
| 1 | `…/sabnzbd/config/scripts/library.blb` | `b0eb3807939a` | not covered |
| 2 | `…/scripts/library.blb-before-albums-multi_genre_field.bak` | `6384628d99af` | not covered |
| 3 | `…/scripts/library.blb-before-albums-relative_path.bak` | `f0db3d02f594` | not covered |
| 4 | `…/scripts/library.blb-before-items-instrumental_lyrics_in_flex_field.bak` | `4043771424ab` | not covered |
| 5 | `…/scripts/library.blb-before-items-lyrics_metadata_in_flex_fields.bak` | `623f81f4d325` | not covered |
| 6 | `…/scripts/library.blb-before-items-multi_arranger_field.bak` | `ab4d35f7a8ae` | not covered |
| 7 | `…/scripts/library.blb-before-items-multi_composer_field.bak` | `568addcb1ad2` | not covered |
| 8 | `…/scripts/library.blb-before-items-multi_genre_field.bak` | `44a232614b49` | not covered |
| 9 | `…/scripts/library.blb-before-items-multi_lyricist_field.bak` | `d90b372e8a8b` | not covered |
| 10 | `…/scripts/library.blb-before-items-multi_remixer_field.bak` | `ee744b7d9ff1` | not covered |
| 11 | `…/scripts/library.blb-before-items-relative_path.bak` | `8e74178fda12` | not covered |
| 12 | `…/scripts/library.blb-before-items-remove_inherited_artpath.bak` | `d0f26f5ed698` | not covered |
| 13 | `…/sabnzbd/config/.config/beets/library.db` | `00635fb3bc35` | not covered |
| 14 | `…/.config/beets/library.db-before-albums-multi_genre_field.bak` | `f6e3444c39dc` | not covered |
| 15 | `…/.config/beets/library.db-before-albums-relative_path.bak` | `dad8c395e9a6` | not covered |
| 16 | `…/.config/beets/library.db-before-items-instrumental_lyrics_in_flex_field.bak` | `d74fe7c0f36a` | not covered |
| 17 | `…/.config/beets/library.db-before-items-lyrics_metadata_in_flex_fields.bak` | `ffd3f14b1316` | not covered |
| 18 | `…/.config/beets/library.db-before-items-multi_arranger_field.bak` | `2f4ae43b15e3` | not covered |
| 19 | `…/.config/beets/library.db-before-items-multi_composer_field.bak` | `4b8923340d92` | not covered |
| 20 | `…/.config/beets/library.db-before-items-multi_genre_field.bak` | `86d6519bb022` | not covered |
| 21 | `…/.config/beets/library.db-before-items-multi_lyricist_field.bak` | `56dd34c217e6` | not covered |
| 22 | `…/.config/beets/library.db-before-items-multi_remixer_field.bak` | `d3245dbdad90` | not covered |
| 23 | `…/.config/beets/library.db-before-items-relative_path.bak` | `d69ae2d2a589` | not covered |
| 24 | `…/.config/beets/library.db-before-items-remove_inherited_artpath.bak` | `c99dec76c4d0` | not covered |

The row count is 24, which equals Task 1's 12 `library.blb*` files plus 12 `.config/beets/*` files. The full hashes are in the (d) table.

### Step 7: fence section after the writes

`check-music-freeze.sh` re-ran with **RC 0** in 5 s, with fence assertions failed 0 and FAILURES total 0. Its section 6 printed:
- `✅ fence exists: /mnt/fast/safety/music-pre-project (568:568 755)`
- `✅ snapshot present` for `tank/media/Music@pre-project` and for `tank/downloads@pre-project`
- `✅ fence subdirectory non-empty: library-db/ (19 files)`; it was 18 before `wrtag.db`
- `dj-mixes-ffprobe/` 764 files, `cover-scans/` 54 files, `tags/` 21 files
- `✅ no running container mounts any path under /mnt/fast/safety (D-08, proven not asserted)`

### Nothing under `/mnt/fast/appdata` changed

All 35 Task 1 (d) paths were re-hashed after the fence writes. A mechanical `diff` of the before and after `path<TAB>sha256` lists, 35 lines each, printed `ALL-UNCHANGED`. No SAB music job ran during the window.

---

## Decisions Made

- **The fence-root MANIFEST is the manifest.** Phase 4's entries live there as a dated section, and each sha line stays `sha256sum`-parseable.
- **Read modes:** live sources open `mode=ro` and fence copies open `immutable=1`. Both are stricter than the plain opens in the plan's text (T-04-01-04), and each check is proven non-mutating by re-hashing.
- **Two pre-declared clarifications in D-12** (see Deviations 5). Neither widens the byte-identity test.

## Deviations from Plan

### Auto-fixed issues and defective assertions

**1. [Rule 3 - Blocking] The MANIFEST path in the plan does not exist**
- **Found during:** Task 2 step 1.
- **Issue:** the plan's key_link, step 1, `<verify>` and acceptance criteria all name `/mnt/fast/safety/music-pre-project/library-db/MANIFEST.txt`. The real manifest is `/mnt/fast/safety/music-pre-project/MANIFEST.txt`, which is where `freeze-music-apply.sh` writes `$FENCE/MANIFEST.txt`.
- **Fix:** appended to the real manifest. Creating a second manifest under `library-db/` would have forked the record.
- **Verification:** the plan's Task 2 `<verify>` as written **fails with RC 2** (`grep: …/library-db/MANIFEST.txt: No such file or directory`) on a correct outcome. That is a **defective assertion**, recorded rather than satisfied by creating the file. The same check against the fence-root path passes: `integrity=ok`, 1 matching line, and the MANIFEST sha equals the file's sha (`SHA-MATCH`).
- **Downstream (must fix before those plans run):** **04-11 Task 2 `<verify>`** greps `/mnt/fast/safety/music-pre-project/library-db/MANIFEST.txt` for `phase 04 D-32 ledger`, and will fail the same way. 04-11's `read_first` and 04-07's MANIFEST references need the same correction.

**2. Defective assertion: the audit-copy glob overlaps**
- **Found during:** Task 2 acceptance.
- **Issue:** "exactly one `arrs-beets-config.yaml.*`" also matches `arrs-beets-config.yaml.old.*`, so it counts **2** on a correct outcome.
- **Resolution:** with disjoint patterns the counts are `sabnzbd-beets.log.*` = 1, `arrs-beets-config.yaml.2*` = 1 and `arrs-beets-config.yaml.old.*` = 1. No file was renamed to satisfy the glob.

**3. Defective instrument: the beets.log date grep**
- **Found during:** Task 1 (g).
- **Issue:** beets.log lines carry no ISO date, so a literal `grep -c` for `2026-08-01`, `2026-08-08` or `2026-09-06` returns 0, 0 and 0.
- **Resolution:** skip lines were counted per `import started` session header (2 / 1 / 1), and each session was paired with its SAB row across the UTC+1 offset.

**4. An off-by-one in the plan's `audio.bash` line numbers**
- **Found during:** Task 3, re-reading the live file before publishing any line number.
- **Issue:** the `beets-match` removal block is at lines **298–301**, not 297–300. Every other cited number matched: 27–35, 64–65, 271, 272–275, 276, 281, 285, 289, 322–324, 326 and 334–335.
- **Resolution:** `04-D12-EVIDENCE.md` uses the live numbers.

**5. [Rule 2 - Missing critical] Two D-12 clarifications that prevent a spurious FAIL**
- **Found during:** Task 3.
- **Issue:**
  - (a) `/mnt/fast/appdata/arrs/sabnzbd/config/sabnzbd.ini.bak` (9,837 B, 2026-08-17) is SABnzbd's own settings backup. A settings save during the window would trip the "no `.bak` anywhere under `/config`" rule.
  - (b) `clean()` flattens subdirectories. A byte-identical file moved to a new path would read as "an audio file that appears only at COMPLETION", which counts as a FAIL.
- **Fix:**
  - (a) is pre-declared by name. Any other new `.bak` still fails.
  - (b) is pre-declared as `MOVED`, which applies only when the sha256 equals that of a PRE-HOOK-only file. A COMPLETION-only file matching no PRE-HOOK hash still fails.
- **Files modified:** `04-D12-EVIDENCE.md`. **Committed in:** `92557fb`.

**6. Hardening: read modes**
- `wrtag.db` was opened `file:…?mode=ro` for the `.backup`, and fence copies were opened `immutable=1` for `integrity_check`. The plan text shows plain opens. The effect was verified: the source sha was unchanged, and each fence copy's sha was unchanged by its check.

---

**Total deviations:** 6. That is 1 blocking-path fix, 3 defective assertions or instruments recorded, 1 missing-critical clarification and 1 hardening.
**Impact on plan:** none of them changes what was fenced or measured. Deviation 1 is the one that matters downstream.

## Issues Encountered

- **Release-name leak, transcript only.** A read-only `substr(path,1,30)` preview, run to tell `storage` from `path`, printed three truncated release-name prefixes into the executor's transcript. None was written to the repo, this SUMMARY or the evidence file. The column semantics were then established with counts only.
- **The host checkout is stale and dirty:** `3327dcf`, with 2 porcelain lines. They were left untouched, as this plan is read-only on the estate. Any later plan that runs a repo script on the host must `git pull` first, and the 2 dirty lines should be looked at before that pull.
- **The plan's conventions say the working tree carries unrelated changes** (`03-ERGONOMICS-SHEET.md`, `body.txt`). They were absent: the tree was clean at start. Only explicit paths were staged regardless.

## Known Stubs

- `04-D12-EVIDENCE.md` § 6 Result is `PENDING — filled by 04-12` in every field. This is intentional and required by the plan: 04-12 fills it after a real music job.

## User Setup Required

None.

## Next Phase Readiness

- **04-07** (wrtag/soulbeet deletion) has what it needs: the wrtag fence copy, the survivor DB baselines and the `config.yaml.old` audit copy. **Correct its MANIFEST path first** (Deviation 1).
- **04-09**: D-29 is present with 12 FLAC on a single disc, and still has to be re-asserted before `up`. The live broken-config sha `7a059a40…` is recorded in (d).
- **04-11** has the 24-row coverage list above, and knows none of it is covered. **Its `<verify>` MANIFEST path is wrong** (Deviation 1). sabnzbd 5.1.3 (PR #310) is not resident.
- **04-12** has the D-12 contract, the `storage` column mapping, the `extended.conf` baseline, and the Audio.txt residual-line baseline counts (98 / 87).
- **Every wave boundary:** compare against the ROUTINE BASELINE above.

## Self-Check: PASSED

- Task 3's commit `92557fb` exists (`git log -1 --name-only` lists only `04-D12-EVIDENCE.md`).
- `04-D12-EVIDENCE.md` exists and carries every acceptance token. `mtimes are NOT used` appears exactly once and `PENDING — filled by 04-12` is present.
- On the host, `media_wrtag_data_wrtag.db` passes `integrity_check` (`ok`), and its sha equals MANIFEST line 882. Exactly one each of the three `audit/` copies exists, and each one's sha equals its MANIFEST line.
- The 35/35 appdata hashes are unchanged, and there are no BLOCKERs.
- STATE.md and ROADMAP.md are untouched, and no `gsd-sdk` state or roadmap verb was called.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-11*
