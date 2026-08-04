# Podsync

Turns YouTube playlists into podcast RSS feeds, so they can be subscribed to in Apple Podcasts and
**downloaded for offline listening** (the primary use case here — playback where YouTube isn't
available).

- Web/RSS: <https://podsync.deercrest.info>
- Feeds are served as `https://podsync.deercrest.info/<FEED_ID>.xml`
- Config: `/mnt/fast/appdata/hoarder/podsync/config.toml` (**not** in this repo — contains the
  YouTube API key)
- Media: `/mnt/fast/appdata/hoarder/podsync/downloads/<FEED_ID>/`

## Feeds

| ID | Title | Notes |
|----|-------|-------|
| `ID1` | Youtube Feeds | general |
| `ID2` | Youtube Solar | |
| `ID3` | Youtube AI | main feed; mixed AI + other content |
| `ID4` | Youtube Notion | |

Each keeps the last 199 episodes (`clean = { keep_last = 199 }`) and prunes the oldest when new
ones arrive — that is why episodes disappear over time. Feeds are `private_feed = true` so they
are not indexed by podcast directories.

Playlists are **unlisted**, not private. That matters: podsync authenticates with a plain YouTube
Data API key, which can read unlisted playlists but *cannot* read genuinely private ones (those
need OAuth or cookies, which podsync does not support).

---

## yt-dlp is managed by us — read this before touching it

**podsync's `self_update` does not work here and is set to `false`.** Do not turn it back on.

It must write into `/usr/local/bin`, which is not writable by uid 568. It failed **silently** for
about 13 months — not a single log line. Meanwhile YouTube's SABR rollout blocked the stale
bundled yt-dlp, and every single download failed:

```
ERROR: [youtube] <id>: The following content is not available on this app.
```

792 such errors in a 6-hour window, 0 successful downloads. The feeds looked healthy the whole
time — podsync polled them and found new items, then failed only at the download step.

Pulling a newer podsync image does **not** fix this either: podsync releases rarely (v2.8.0 was
the latest release for over a year while the repo kept receiving commits), so the bundled yt-dlp
stays old regardless.

So the binary is bind-mounted from appdata and refreshed by us:

```
/mnt/fast/appdata/hoarder/podsync/bin/yt-dlp  ->  /usr/local/bin/youtube-dl (ro)
```

### Use the zipapp asset, not `yt-dlp_linux`

The podsync image is **Alpine/musl with Python 3.12**. The `yt-dlp_linux` release asset is a
glibc PyInstaller binary and **cannot execute there** — podsync crash-loops with:

```
could not find youtube-dl: failed to execute youtube-dl: exit status 255
```

Always use the plain `yt-dlp` zipapp asset (~3 MB, starts with `#!`). The updater script enforces
this.

### `HOME=/app/db`

The image sets `HOME=/`, which uid 568 cannot write, so yt-dlp could not cache the YouTube player
JS:

```
PermissionError: [Errno 13] Permission denied: '/.cache'
```

That degraded nsig extraction. `HOME` is set to `/app/db` (an existing writable mount) in
`compose.yaml`.

---

## Scheduled update (systemd timer)

YouTube breaks old yt-dlp regularly, so the refresh is automated. **This is the thing that keeps
podsync working** — without it, downloads silently stop again.

| Unit | Purpose |
|------|---------|
| `podsync-ytdlp-update.timer` | fires **Sundays 04:00** (+ up to 30m jitter), `Persistent=true` so a missed run catches up after downtime |
| `podsync-ytdlp-update.service` | oneshot, runs `update-ytdlp.sh` |

Both live in `/etc/systemd/system/` on LXC 100 (`172.16.1.159`) and call the script **from this
repo** at `/mnt/fast/stacks/stacks/selfhosted/podsync/update-ytdlp.sh`, so the script is
version-controlled here.

`update-ytdlp.sh` is idempotent: it downloads the current yt-dlp and **only** installs and
restarts podsync if the version actually changed. It refuses to install anything that isn't a
`#!` zipapp or is implausibly small, so a truncated download or an HTML error page cannot brick
the container.

### Operating it

```bash
# status / when it next runs
systemctl list-timers podsync-ytdlp-update.timer

# run it now
systemctl start podsync-ytdlp-update.service

# logs (the script logs to stdout, captured by journald)
journalctl -u podsync-ytdlp-update.service -n 50

# disable temporarily
systemctl disable --now podsync-ytdlp-update.timer
```

### Manual refresh (if the timer is off)

```bash
/mnt/fast/stacks/stacks/selfhosted/podsync/update-ytdlp.sh
```

### Reinstalling the units

The unit files are not deployed by compose. If LXC 100 is rebuilt, recreate them — see
`update-ytdlp.sh` header for context, and use `OnCalendar=Sun 04:00`, `Persistent=true`,
`ExecStart` pointing at the repo path above.

---

## Troubleshooting

**"Nothing new is downloading"** — check the download step, not the feed. Podsync will happily
report a healthy feed cycle while every download fails:

```bash
docker logs podsync 2>&1 | grep -c "not available on this app"   # stale yt-dlp / YouTube block
docker logs podsync 2>&1 | grep -c "Permission denied"           # cache not writable
docker exec podsync /usr/local/bin/youtube-dl --version          # should be recent
```

If the count is high and the version is old, run the updater.

**"This video is not available."** — different error, and usually genuine: the video was deleted,
made private, or is region-blocked. Verify with a current yt-dlp before assuming a config fault.

**JS runtime warning** — modern yt-dlp emits `No supported JavaScript runtime could be found`
(deno). It is a deprecation warning, not a blocker; downloads still succeed. If YouTube tightens
this, the image would need deno added.

---

## Filtering a mixed playlist

`ID3` mixes AI and non-AI content. podsync supports per-feed regex filters, e.g.:

```toml
filters = { title = "(?i)(AI|LLM|GPT|Claude|agent)" }
```

`not_title` inverts it, so pointing a second feed at the same playlist with opposite filters
splits one playlist into two podcasts. Duration and `max_age` filters are also available.

## Alternatives considered (2026-08)

Kept podsync — it is purpose-built for podcast feeds and the offline-archive requirement rules out
streaming-only options.

| Tool | Verdict |
|------|---------|
| **Pinchflat** | Bundles deno + supports cookies, but **~8 months without a release/commit**. For a yt-dlp-dependent tool that is the same staleness risk we just hit. |
| **ytdl-sub** | Best-maintained (releases every few weeks). Real candidate if podsync stalls, but YAML/CLI config and podcast feeds are less first-class. |
| **Vod2Pod-RSS** | Zero storage, transcodes on demand — **rejected**: no offline playback. |
| **Tube Archivist / TubeSync** | Archive/media-server shaped, not podcast-feed shaped. |
