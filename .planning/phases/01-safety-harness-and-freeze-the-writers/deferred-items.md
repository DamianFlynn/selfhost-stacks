# Phase 01 — Deferred Items

Out-of-scope discoveries found during execution. Not fixed, deliberately. Recorded so they are
not re-discovered as "new" later.

## From plan 01-05 (mount narrowing)

### 1. Janitorr has never been able to write its own log file

- **Found:** post-restart log check, plan 01-05 task 3
- **Symptom:** `openFile(/logs/janitorr.log,true) call failed. java.io.FileNotFoundException:
  /logs/janitorr.log (Permission denied)` on every container start.
- **Cause:** `/mnt/fast/appdata/media/janitorr/logs/janitorr.log` is owned `root:root` mode `0770`;
  Janitorr runs as `568:568`. Last successful write was **9 March 2026** — five months ago.
- **Why deferred:** pre-existing, unrelated to the media mount narrowing, and unrelated to the
  music library. The `logs` bind mount was not touched by 01-05. Janitorr reports `healthy` and
  falls back to console logging, so nothing is broken today — but its file log has been silently
  dead since March.
- **Fix when picked up:** `chown 568:568 /mnt/fast/appdata/media/janitorr/logs/janitorr.log`.

### 2. Sonarr has stale queue items pointing at deleted download folders

- **Found:** same log check
- **Symptom:** repeated `DownloadedEpisodesImportService: Import failed, path does not exist or is
  not accessible by Sonarr: /downloads/complete/nzb/tv/<release>`.
- **Cause:** the referenced folders genuinely do not exist on the host. Sonarr's `/downloads` mount
  is intact and was not modified by 01-05; only its `/media` mount changed, and its `/media/TV`
  root folder reads back `accessible: true` from the API after the restart.
- **Why deferred:** download-queue hygiene, nothing to do with this project.

### 3. Janitorr's `leaving-soon-dir` resolves to a path that has never existed

- **Found:** config read during 01-05 task 1
- **Detail:** `application.yml` sets `leaving-soon-dir: "/data/media/leaving-soon"`. Under the old
  broad mount (`/mnt/tank/media:/data`) that resolved to `/mnt/tank/media/media/leaving-soon`,
  which does not exist on the host — the double `media` looks like a copy/paste error from an
  installation where `/data` was the pool root rather than the media dataset.
- **Impact of the 01-05 narrowing:** strictly safer. `/data` is no longer a bind mount, so if
  Janitorr ever does create that path it lands in the container's ephemeral writable layer instead
  of inside the media dataset.
- **Why deferred:** Janitorr's Radarr, Sonarr, Jellyseerr and media-server integrations are all
  currently disabled and `dry-run: true` is set, so the feature is inert. Fixing the path is
  Janitorr configuration, not music-pipeline work.

### 4. A `.DS_Store` sits in the music library root

Already recorded in 01-01. Repeated here because 01-05's post-apply listing shows it again at
`/mnt/tank/media/.DS_Store` (note: the *media* root, not the Music root — there is one at each).
Owned `65534:65534`. Proves a Mac has had write access over a share. No requirement covers it.
