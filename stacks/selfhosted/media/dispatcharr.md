# Dispatcharr: channel lineup and EPG

Companion to [`dispatcharr.yaml`](dispatcharr.yaml) (container/networking) and
[`NETWORK.md`](../../../NETWORK.md) (tuner endpoint — use the macvlan address `172.16.1.75:9191`,
never the `9192` host publish).

This file documents the **lineup and guide data**, which live in Dispatcharr's database rather
than in this repo. Nothing here is applied by `docker compose`; it is the record of how the
lineup is put together and the traps found building it.

State as of 2026-08-16: **138 channels, 317 stream links, ~21,400 programmes.**

---

## Number blocks

| Range | Content | Source |
|---|---|---|
| 1–12 | Irish FTA (RTÉ, Virgin Media, TG4, +1s) | HDHomeRun, acct 2 |
| 18, 21, 23–34 | Bloomberg, TBN, news (Sky, BBC, GB, Al Jazeera, Euronews, France 24, DW, CNBC, TalkTV, CNN Intl, ABC/NBC News) | mixed |
| 101–108 | UK general (BBC One/Two/Three/Four, ITV1, C4, E4) | IPTV |
| 110–122 | Sky entertainment (Showcase, Atlantic, Witness, Comedy, Crime, Documentaries, Nature, Arts, History, Sci-Fi, Replay, Kids, Max) | IPTV |
| 141–149 | Food & lifestyle (Food Network UK/US, Cooking Channel, Tastemade, HGTV UK/US, Really, Magnolia, Travel) | IPTV |
| 301–311 | Sky Cinema (Premiere, Select, Hits, Greats, Drama, Comedy, Action, Thriller, Sci-Fi/Horror, Family, Animation) | IPTV |
| 401–447 | Sport — Sky Sports 401–403, TNT Sports 410–413, ESPN 420–423, US sport 430–447 | IPTV |
| 501–505 | Los Angeles locals (KABC, KCBS, KNBC, KTTV, KTLA) | IPTV |
| 511–513 | US news (CNN, FOX News, MSNBC) | IPTV |
| 520–544 | US cable (USA, Bravo, Syfy, FX, AMC, History, Nat Geo, Comedy Central, TLC, Nickelodeon, CMT, Oxygen, …) | IPTV |
| 600–612 | 24/7 single-show loops (Kardashians, Real Housewives ×6, Vanderpump, Below Deck, …) | IPTV |

All channels sit in the `Favorites` channel group. Streams are stacked HD-first as an ordered
failover chain (`ChannelStream.order`), typically 2–4 deep.

---

## EPG sources

| id | Name | URL | Rows | Role |
|---|---|---|---|---|
| 1 | `iptv-epg-org-gb` | `iptv-epg.org/files/epg-gb.xml` | 934 | UK **and Ireland** — 18 `.ie` ids despite the name |
| 2 | `DigitalIPTV` | provider `xmltv.php` | 4,442 | **Do not use.** Mis-mapped ids |
| 3 | `iptv-epg-org-us` | `iptv-epg.org/files/epg-us.xml.gz` | 12,837 | US primary |
| 4 | `epgshare01-us2` | `epgshare01.online/…/epg_ripper_US2.xml.gz` | 763 | US gap-filler |

**Source 2 is mis-mapped and must not be trusted**: `BBC1.uk` resolves to *CBBC*, `WBZ.us` to
*WSBK*. Auto-matching on its tvg_id silently gives a channel the wrong guide. It is the only
source carrying `SkyMax.uk` — with 0 programmes, so it does not help there either.

**Always use the `.gz` for source 3** — uncompressed it is 897 MB.

Id conventions differ per source and are easy to guess wrong:

- Source 3 US locals: `{NETWORK}{CALLSIGN}.us` (`ABCKABC.us`, `CWKTLA.us`); nationals are bare
  (`CNN.us`, `ESPN.us`). Traps: Fox News is `FoxNewsChannel.us`, ESPNews is `ESPNEWS.us`,
  A&E is `AandENetwork.us`, E! is `EEntertainmentTelevision.us`.
- Source 4: dot-separated with a `.us2` suffix (`MSNBC.HD.us2`, `Big.Ten.Network.HD.us2`).
- epgshare01 publishes `UK1`, `IE1`, `US2`, `US_LOCALS1`, `US_SPORTS1`, `ALL_SOURCES1` —
  there is **no `US1`**.

> **Search by display name, never guess the id.** Several channels were wrongly written off as
> "no EPG available" on a guessed id when they were present all along under a different one.
> `EPGData.objects.filter(name__icontains=…)` first; only then conclude something is missing.

### Channels deliberately without a guide

Sky Max (120) and the 24/7 loops (600–612). No source publishes schedules for single-show loop
channels, and Sky Max exists in no usable guide. These show Dispatcharr's synthetic "Prime Time
Placeholder" programming by design — **do not try to "fix" them.**

---

## Linking a channel to its guide — this is the sharp edge

For a **manually created** channel, set **both** `Channel.tvg_id` and `Channel.epg_data`.
Setting `epg_data` alone appears to work — programmes import within seconds — but the next
source refresh (source 1 runs every 4h) re-matches on `tvg_id` and silently resets `epg_data`
to `None` for any channel whose `tvg_id` is empty. The guide then reverts to the dummy schedule.

For an **auto-created** channel (`auto_created=True` — channels 1–10 come from the HDHomeRun
account), editing `Channel.*` is futile: that account auto-syncs every 24h and rewrites `name`
and `tvg_id` from the provider, nulling `epg_data` as a side effect. Use
`apps.channels.models.ChannelOverride`, a one-to-one with nullable per-field columns
(`name`, `channel_number`, `channel_group`, `logo`, `tvg_id`, `epg_data`, …). Sync never writes
to that table, so overrides survive. Outputs resolve through
`apps.channels.managers.with_effective_values`.

**Set every field you care about on the override, including `logo`.** An override covering
name/tvg_id/epg_data but not `logo` leaves the channel with no logo at all once sync wipes
`Channel.logo` — which happened silently to channels 1–10.

**Audit via effective values**, not the base columns. Reading `Channel.epg_data` directly on an
auto-created channel reports a false failure; reading `Channel.logo` reported a false pass.

After a bulk create, programmes arrive **asynchronously** over ~a minute and the source's
`last_message` can lag reality. Re-check counts before concluding anything broke; only then
re-run `parse_programs_for_tvg_id(<epg_data_id>)`.

---

## Logos

Order of preference:

1. `EPGData.icon_url` for the mapped row (source 3 and 4 rows generally have one).
2. [`tv-logo/tv-logos`](https://github.com/tv-logo/tv-logos) —
   `raw.githubusercontent.com/tv-logo/tv-logos/main/countries/{country}/{slug}.png`.
   Enumerate with the GitHub contents API rather than guessing slugs: it is `tg-4-ie.png`,
   not `tg4-ie.png`.
3. The stream's own `Stream.logo_url` (what the 24/7 channels use).

The provider's `icon-tmdb.com` / `icon-tmdb.me` hosts are **dead**; `photo-tmdb.com` still
resolves. `EPGData.icon_url` is emptied and repopulated across refreshes, so copy it into a
`Logo` row at build time rather than relying on it being readable later.

---

## Provider account (`DigitalIPTV`, acct 7)

Scoped down 2026-08-12 from a wide-open default:

```json
{"enable_vod": false, "auto_enable_new_groups_live": false,
 "auto_enable_new_groups_vod": false, "auto_enable_new_groups_series": false}
```

104 of 263 groups enabled (~5,700 streams, down from 18,562). `cleanup_streams` deletes any
stream whose group is disabled, so disabling a group prunes it on the next refresh — fully
reversible by re-enabling and refreshing. `auto_enable_new_groups_live: false` means new
provider groups arrive disabled, so the lineup only grows deliberately.

`enable_vod: false` does **not** delete VOD already imported — there is no off-transition
handler. That needs `cleanup_orphaned_vod_content(stale_days=0, account_id=7)` explicitly, and
it leaves `VODLogo`/`VODCategory` rows behind to be cleared separately.

Beware group names that look like channels: `US| ESPN+ PPV` (1,602 streams) are per-event
placeholder feeds dated 2098, not ESPN. Real linear ESPN is ~5 streams in `US| SPORT`. Same
pattern for `TENNIS CHANNEL PLUS n`.

### `max_streams: 1`

One concurrent upstream connection for the whole IPTV account (HDHomeRun channels are exempt —
4 tuners). Two viewers on the *same* channel share one upstream, but two different IPTV channels
do not fit.

> **Do not test-pull streams while anyone is watching.** A `curl` against `/proxy/ts/stream/<uuid>`
> takes the only slot and returns
> `503 All active M3U profiles have reached maximum connection limits` — or takes it from a live
> viewer. Subscription expires 2026-12-29.

---

## Operating notes

**`/tmp` inside LXC 100 is a 15 G tmpfs, not disk.** Staging EPG guides there consumes host RAM.
Doing so with ~1.1 GB of XML took the 28 GB host to load average 869 with SSH dead on both the
LXC *and* the Proxmox host while `ping` still answered; `arc_reap` blocked in D state as ZFS ARC
competed for the same memory. Deleting the files recovered it without a reboot. Stage large
downloads under `/mnt/fast/`, pipe rather than writing uncompressed copies, and prefer letting
Dispatcharr parse a guide and querying `EPGData` over grepping XML by hand.

**Write path.** Django ORM via `docker exec dispatcharr python manage.py shell` — model signals
fire, so EPG refresh is triggered; raw SQL would skip it. Scripts with unicode channel names die
on nested SSH quoting, so `scp` + `docker cp` the script in and
`exec(open('/tmp/x.py').read())`.

**Dry-run stream matching before creating channels.** Resolving streams by substring caught 7
bad matches out of 60: `MTV` matches *KMTV Omaha*, `TNT` matches UK *TNT Sports*, `HISTORY`
matches *MILITARY HISTORY*, `HALLMARK` matches *HALLMARK M & M*, `BET` matches *SHOWTIME BET*.

**Watch East vs West feeds.** A `… WEST` stream against an East-coast guide puts the listings
three hours out. Magnolia Network hit this; there is no Pacific guide for it, so the national
feed leads and West is failover.

**Database.** Dispatcharr runs its own embedded Postgres inside the app container — there is no
separate postgres container, and no `POSTGRES_*` env vars, so a naive `pg_dump "$POSTGRES_DB"`
writes a 20-byte file that still passes `gzip -t`. Always check dump size:

```bash
docker exec -e PGPASSWORD=secret dispatcharr \
  pg_dump -h localhost -U dispatch -d dispatcharr \
  | gzip > /mnt/fast/appdata/media/dispatcharr/data/backups/dispatcharr-$(date +%F).sql.gz
```

Snapshots live in `/mnt/fast/appdata/media/dispatcharr/data/backups/`.
