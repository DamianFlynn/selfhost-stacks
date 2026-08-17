# Beets: library state and the bulk-import backlog

Companion to [`beets/beets.yaml`](beets/beets.yaml) (manual container) and
[`soulbeet.yaml`](soulbeet.yaml) + [`soulbeet/beets_config.yaml`](soulbeet/beets_config.yaml)
(automated Soulseek → beets path).

Nothing here is applied by `docker compose`. This is the record of what the music library
currently looks like, why the tagging pipeline stalled, and how to work the backlog.

State as of 2026-08-17.

---

## Two beets, one library

There are **two** beets entry points writing to the same destination. This is the first thing
to understand before running anything.

| | `beets` (manual) | `soulbeet` (automated) |
|---|---|---|
| Defined in | `arrs/beets/beets.yaml` | `arrs/soulbeet.yaml` |
| Runs | `restart: "no"`, `profiles: ["manual"]` — only when invoked | `restart: unless-stopped` |
| Config | `/mnt/fast/appdata/arrs/beets/config/` | `/mnt/fast/appdata/arrs/soulbeet/beets_config.yaml` |
| Library db | `config/library.db` | `/data/beets_library.db` |
| Destination | `/media` → `/mnt/tank/media` | `/music` → `/mnt/tank/media/Music` |
| URL | `beets.deercrest.info` | `soulbeet.deercrest.info` |

**They keep separate `library.db` files but write to the same tree.** Anything imported by one
is invisible to the other's database. Treat that as a known hazard, not a thing to fix casually —
reconciling them means re-importing one side.

> The file at `/mnt/fast/appdata/arrs/beets/config/config.yaml` on the host is **not** a beets
> config — it is a copy of the compose service definition. The real tunables live in
> `soulbeet/beets_config.yaml`.

---

## Current numbers

Audio-file census across `tank` (mp3/flac/m4a/wav/aac/ogg/wma):

| Location | Files | Size | Tagged? |
|---|---|---|---|
| `downloads/complete/nzb/unsorted` | 7,451 | 97 G | no |
| `downloads/complete/nzb/dj-mixes` | 794 | 25 G | no |
| `downloads/complete/nzb/music` | 275 | 18 G | no — Lidarr inbox, has `_FAILED_`/`_UNPACK_`/`.rar` |
| `media/Music` — 13 artist folders | 1,244 | 34 G | yes |

**The untagged backlog is roughly 6× the tagged library by file count.**

`media/Music` is the Jellyfin source: its library `options.xml` has `<Path>/media/Music</Path>`
and `SaveLocalMetadata: true` — which is why `album.nfo`, `folder.jpg` and `.lrc` files appear
in any folder dropped there, within minutes. Music Assistant is not connected yet but should
point at the same tree.

---

## Why it stalled

`beet.log` has exactly three entries, all on **18 Nov 2025**, and `library.db` has not been
written since. The pipeline was built, run three times, and left. That is the whole reason
97 G sits untagged.

The documented flow (from the header comment in the manual service definition):

```bash
docker compose -f arrs/beets.yaml --profile manual up beets
docker exec -it beets beet import "/downloads/complete/nzb/unsorted/<album folder>"
```

---

## Two config gaps that will bite a bulk run

`soulbeet/beets_config.yaml` is otherwise sane — sensible `paths`, `scrub`, `fetchart`,
strict-ish `strong_rec_thresh: 0.04`. Two things are missing, and they map exactly onto the
two known problem classes.

### 1. No release-country preference → "Now That's What I Call Music" mismatches

The UK and US *Now!* series share album titles but are **completely different track listings**.
There is no `match.preferred.countries`, so beets has nothing to break the tie and will happily
pick the wrong side.

```yaml
match:
  preferred:
    countries: ['GB', 'US']   # first match wins; GB first for the UK series
```

This biases but does not guarantee. For the *Now!* folders specifically, import with
`beet import -t` (timid — confirm every match) and check the track listing before accepting.
Where beets still guesses wrong, press `I` at the prompt and paste the correct MusicBrainz
release ID.

The 45 G `VA-Now_That.s_What_I_Call_Music__1-115_2023` set is the extreme case — 115 albums
in one folder. Do not point a single import at it; it needs splitting per volume first.

### 2. No `fromfilename`, no `edit` → DJ service releases fail hard

**Mastermix, DMC, Music Factory, Crate, Toolkit and Essential Hits are not in MusicBrainz** as
catalogued releases. Autotagging cannot succeed; beets will either reject them or attach a
wildly wrong match. This is expected, not a misconfiguration.

```yaml
plugins:
  - fromfilename   # infer track/title from filename when tags are absent
  - edit           # fix metadata inline during import
```

Import these with autotagging **off** so existing tags and filenames are preserved:

```bash
beet import -A --flat "/downloads/complete/nzb/dj-mixes/<folder>"
```

`-A` = no autotag. Without it these become unusable.

Consider giving DJ content its **own path format** so it does not land in `Compilations/`
alongside genuine various-artist albums:

```yaml
paths:
  albumtype:dj: DJ-Mixes/$album/$track $title
```

---

## Suggested triage

Work the backlog in buckets, easiest first, so confidence is built on the cases that autotag
cleanly before touching the hard ones.

| Bucket | What | Approach |
|---|---|---|
| **A** | Mainstream artist albums (Lady Gaga, Def Leppard, Pink, Garth Brooks, Katy Perry, Taylor Swift FLAC rips in `nzb/music`) | Autotag normally. High MusicBrainz confidence. Start here. |
| **B** | *Now That's What I Call Music* | `preferred.countries` + `beet import -t`. Split the 1-115 set per volume first. |
| **C** | DJ service releases — Mastermix, DMC, Music Factory, Crate, Toolkit, Essential Hits (all of `dj-mixes`, most of `unsorted`) | `beet import -A`, separate path format. Never going to autotag. |
| **D** | Junk — `_FAILED_`, `_UNPACK_`, unextracted `.rar` parts, `incomplete/` | Triage and delete or re-extract before importing anything. |

### Before any bulk run

- **`import.move: yes` is set.** A bulk run will *move* files out of the source, not copy them.
  For a first pass over 97 G of known-problematic content, switch to `copy` until the results
  are trusted — `tank` has 9 T free, so the duplication is affordable and reversible.
- Back up both `library.db` files first. They are small.
- Expect near-duplicate folders: `dj-mixes` and `unsorted` share **all 85** folder names, with
  sizes differing by hundreds of bytes to ~400 KB (artwork/tag variants, differences running in
  both directions). Decide which side wins *before* importing, or the library gets both.

---

## Gotchas found the hard way

- **`rsync -a` fails writing to `tank`** with `mkstemp ... Operation not permitted` on every
  file — while printing a stats block that looks like success (it reports bytes *sent*, not
  written; zero files land, exit code 23). Cause: `acltype=nfsv4` + `aclmode=restricted` reject
  rsync replicating source mode/ownership. Use `rsync -rlt --no-p --no-o --no-g`, then
  `chown -R 568:545` to match the Music library convention.
- **ZFS frees space asynchronously.** After a large delete, `zfs list` can take ~20 s to reflect it.
- Jellyfin writes `.nfo`/`.jpg`/`.lrc` into any folder placed under `/media/Music` because
  `SaveLocalMetadata: true`. Staging untagged content there pollutes it — stage in
  `downloads/complete/nzb/` instead.
