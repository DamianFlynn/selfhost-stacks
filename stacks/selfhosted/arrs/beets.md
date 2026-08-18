# Beets: library state and the bulk-import backlog

Companion to [`beets/beets.yaml`](beets/beets.yaml) (manual container) and
[`soulbeet.yaml`](soulbeet.yaml) + [`soulbeet/beets_config.yaml`](soulbeet/beets_config.yaml)
(automated Soulseek → beets path).

Nothing here is applied by `docker compose`. This is the record of what the music library
currently looks like, why the tagging pipeline stalled, and how to work the backlog.

State as of 2026-08-18, after the Phase 1 safety harness (last section).

> **Both beets definitions now mount the library `:ro`, and wrtag's library mount is deleted.**
> Nothing in this document's "how to work the backlog" advice will write to `/mnt/tank/media/Music`
> until Phase 6 grants the surviving tagger `rw` again. That is intentional — see the last section.

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
| `downloads/complete/nzb/dj-mixes` | 764 | 25 G | no |
| `downloads/complete/nzb/music` | 275 | 18 G | no — Lidarr inbox, has `_FAILED_`/`_UNPACK_`/`.rar` |
| `media/Music` — 13 artist folders | 1,244 | 34 G | yes |

**The untagged backlog is roughly 6× the tagged library by file count.**

**764**, not 794: the older figure counted the 30 JPEG cover scans as tracks and missed the 24
BMP scans entirely (900 files − 60 `.nfo` − 24 `.bmp` − 20 `.lrc` − 1 `.rtf` − 1 `.DS_Store` = 794,
of which only 630 `.mp3` + 134 `.wav` are audio). Retire "794 dj-mixes files" wherever it appears.

`media/Music` is the Jellyfin source: its library `options.xml` has `<Path>/media/Music</Path>`,
and it used to carry `SaveLocalMetadata: true` — which is why `album.nfo`, `folder.jpg` and `.lrc`
files appear in any folder dropped there. **That is now off for the Music library and permanently
so** (see below). Music Assistant is not connected yet but should point at the same tree.

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
  `chown -R 568:568` — and run that **on the Proxmox host, not on LXC 100** (see
  [Phase 1 safety harness](#phase-1-safety-harness-2026-08-18) below).

  > **This line used to instruct gid 545 (`568:545`); it was corrected on 2026-08-18.** That value
  > was not invented — **545 was the real on-disk gid on 1,171 entries here**, and Music was
  > not alone on it (`/mnt/tank/media/TV` carries 114,218 entries on the same gid). It was
  > corrected because **545 is an orphan gid**: `getent group 545` returns nothing on
  > atlantis, and 545 is unmapped in LXC 100's idmap — which is exactly why the container ever
  > reported `nogroup`/`65534`, and why `chown` fails `EPERM` from inside it. `568` is `apps`
  > (`getent group 568` → `apps:x:568:`), stated independently in `STANDARDS.md:141`,
  > `DEPLOYMENT.md:31`, `README.md:29` and `CLAUDE.md`. If you ran the old line, you set a gid
  > that resolves to no group; re-run the new one from atlantis.
- **ZFS frees space asynchronously.** After a large delete, `zfs list` can take ~20 s to reflect it.
- Jellyfin used to write `.nfo`/`.jpg`/`.lrc` into any folder placed under `/media/Music` within
  minutes, because the Music library had `SaveLocalMetadata: true`. **That is off as of 2026-08-18
  and stays off** — see the Jellyfin exception below. Movies and TV keep their sidecars, so the
  hazard is unchanged for those trees. Stage untagged content in `downloads/complete/nzb/` anyway:
  `SaveLocalMetadata: false` gates the *automatic* save path only, and an explicit "Refresh
  metadata" in the UI still writes.

---

## Phase 1 safety harness (2026-08-18)

The library was writable by ten containers, four tagging entry points and Lidarr's renamer, with
no before-state of the tags anywhere. Phase 1 closed that. This section records **what is true
now and why**; the narrative lives in
`.planning/phases/01-safety-harness-and-freeze-the-writers/01-0N-SUMMARY.md`.

### Ownership and modes

| | Value | Why |
|---|---|---|
| owner | **`568:568`** (`apps:apps`) | The estate service account, stated independently in `STANDARDS.md:141`, `DEPLOYMENT.md:31`, `README.md:29` and `CLAUDE.md`. `getent group 568` → `apps:x:568:` on atlantis |
| directories | **`0755`** *(target — not achieved, see below)* | CLAUDE.md's "Option A" export model: world-readable, owner-writable. Correct here specifically because WRIT-01 leaves exactly one writer, so nothing needs group write |
| files | **`0644`** *(target — not achieved, see below)* | as above |

All **2,674** entries under `/mnt/tank/media/Music`, the library root included, are `568:568` —
verified from the Proxmox host (`root@172.16.1.158`) and cross-checked with `zfs diff` against
`tank/media/Music@pre-chown`.

**The mode half was not achieved and is scoped out.** Every entry is `0777` (88 directories,
2,586 files). `chmod` fails `EPERM` on `tank` even as real root on the hypervisor, including
against a brand-new scratch file, because `aclmode=restricted` plus `aclinherit=passthrough`
gives even freshly created files a non-trivial NFSv4 ACL that `chmod` may not rewrite. The fix
would be `zfs set aclmode=passthrough`, which under passthrough makes a `chmod` rewrite the ACL
on all 2,674 entries — a larger change than the problem. Modes stay `0777`.

**Phase 2 inherits both halves.** `568:568` becomes the export's `anonuid`/`anongid`, and because
ZFS `acltype=nfsv4` ACLs are not exported by knfsd, **mode bits are the only lever NFS clients
see** — so the export must remain read-only, since the tree is world-writable.

### One writer on the library

From `bash scripts/check-music-freeze.sh` on LXC 100, 2026-08-18T22:27:09Z, ANSI stripped,
otherwise unedited. Sections 1 and 2 are two different questions and both are needed: section 1
sees only *running* containers, section 2 sees what the YAML *declares* — and `beets/beets.yaml`
and `soulbeet.yaml` are commented out of `arrs/compose.yaml`, so section 1 structurally cannot
see them while their volume lines still point at the library.

```
🐳 1. Running-container rw holders on the library (WRIT-01, D-26)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  102 running containers, 164 mounts enumerated

  tagger-class writers: 0
  consumer-class writers: 1 (documented exception, D-21)
      jellyfin (/mnt/tank/media:/media:rw)
  unclassified writers: 0

  Note: a bare total is deliberately NOT asserted. Jellyfin is expected to remain the
  sole rw holder (D-21), so 'total == 1' would read as a pass for the wrong reason.
  ✅ no tagger-class container holds rw on the library
  ✅ no unclassified rw holders

📄 2. Declared rw mounts across stack YAML (false-pass guard)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  12 declared /mnt/tank/media volume lines

  FILE                                           LINE  SUFFIX     MAPPING
  stacks/selfhosted/media/jellyfin.yaml          141   rw         /mnt/tank/media:/media:rw
  stacks/selfhosted/media/seerr.yaml             42    ro         /mnt/tank/media:/data:ro
  stacks/selfhosted/arrs/beets/beets.yaml        25    ro         /mnt/tank/media:/media:ro
  stacks/selfhosted/arrs/lidarr.yaml             71    ro         /mnt/tank/media:/media:ro
  stacks/selfhosted/arrs/sonarr.yaml             48    rw         /mnt/tank/media/TV:/media/TV:rw
  stacks/selfhosted/arrs/bazarr.yaml             47    rw         /mnt/tank/media/Movies:/media/Movies:rw
  stacks/selfhosted/arrs/bazarr.yaml             48    rw         /mnt/tank/media/TV:/media/TV:rw
  stacks/selfhosted/arrs/janitorr.yaml           51    rw         /mnt/tank/media/Movies:/data/Movies:rw
  stacks/selfhosted/arrs/janitorr.yaml           52    rw         /mnt/tank/media/TV:/data/TV:rw
  stacks/selfhosted/arrs/soulbeet.yaml           48    ro         /mnt/tank/media/Music:/music:ro
  stacks/selfhosted/arrs/radarr.yaml             46    rw         /mnt/tank/media/Movies:/media/Movies:rw
  stacks/selfhosted/arrs/readarr.yaml            46    rw         /mnt/tank/media/Books:/media/Books:rw

  NO-SUFFIX means neither :ro nor :rw was written, and docker defaults that to rw.
  ✅ no file other than media/jellyfin.yaml declares a rw or unsuffixed host path reaching the library
```

The rows still marked `rw` are narrowed to `Movies/`, `TV/` or `Books/` — none of them reaches
Music. That narrowing is the point: eleven containers held `/mnt/tank/media` whole, and giving
each one its own subtree makes WRIT-01 **structurally** true rather than true by good behaviour.
Prowlarr's mount was deleted outright; wrtag's library mount was deleted, not suffixed.

### The Jellyfin exception — deliberate, and permanent

Jellyfin keeps `/mnt/tank/media:/media` **rw** and is therefore the sole rw holder on Music.
This is a carve-out, not a leak:

- It is **consumer-class**, not a tagger. The audit counts it in its own class and never in the
  tagger-class total, which is why the audit refuses to assert "exactly one rw holder" — a bare
  count of one would read as a pass for the wrong reason.
- It is **frozen at the application layer** for the Music library: `SaveLocalMetadata` off,
  real-time monitoring off, and `SaveLyricsWithMedia` off. That third switch is not named in any
  plan and wrote **944 of the 1,123 baseline sidecars** — the `.lrc` files.
- **It is not `:ro` on purpose.** Going read-only risks Jellyfin's extracted-subtitle and
  trickplay behaviour across Movies and TV, for no gain while the application-layer freeze holds.
  Worth revisiting once one tagger owns the tree.
- **The freeze is permanent.** There is nothing here to remember to undo — once one tagger owns
  the tree, Jellyfin writing metadata into it is a second writer by another name.

Measured limit, stated because it is easy to over-read the freeze: **`SaveLocalMetadata: false`
does not stop an explicit `FullRefresh`.** Pressing "Refresh metadata" in the Jellyfin UI rewrote
83 of the library's 91 `.nfo` in place, 66 with changed content. "Jellyfin writes nothing into
Music" is true **unprompted** and false as an absolute. The 66 rewritten `.nfo` were left as they
are: they are Jellyfin's own current metadata, both snapshots hold the originals, and restoring
them means writing into a library that was just sealed.

### The recovery fence

`/mnt/fast/safety/music-pre-project/` — on `fast`, a different physical device from `tank`, and
proven (not asserted) to be mounted by **no** running container:

| Path | Holds |
|---|---|
| `library-db/` | 18 files — every beets/arr database found in the estate, each `.backup`-copied and passed through `PRAGMA integrity_check` |
| `dj-mixes-ffprobe/` | 764 full `ffprobe` JSON, one per `dj-mixes` audio file, carrying `TKEY` (148 files) and `EnergyLevel` (45) |
| `cover-scans/` | all 54 DJ cover scans — 30 JPEG and **24 BMP**; a jpg/png-only extension list archives 30 of 54 |
| `tags/pre-project.ndjson.gz` | the QUAL-01 before-state: **9,736 records** over 182.67 GB, keyed on `audio_md5` (the encoded bitstream), plus `.done` and a zero-byte `.failed` |
| `audit/` | the baseline and after-state harness runs, the Lidarr/Jellyfin API read-backs, the SAFE-05 watch evidence, and the recorded exit-0 self-diff |

Two ZFS snapshots, both taken before this phase wrote anything:

| Snapshot | Is the undo for |
|---|---|
| `tank/media/Music@pre-project` | every library mutation in this phase and every import after it |
| `tank/downloads@pre-project` | Phase 5's `mv`-based triage and the `Now! 1-115` split, which have no other undo |

Plus `tank/media/Music@pre-chown` and `tank/downloads@pre-chown` from the ownership run, and
`tank/media/Music@safe05-watch-t0` from the Jellyfin watch. The 54 cover scans and all 18
database copies are also **off-box** on the Mac Mini
(`data@datas-mac-mini.pirate-clownfish.ts.net:~/archive/music-pre-project`) — those are the two
genuinely irreplaceable classes.

**Neither half of the fence substitutes for the other.** beets has **no `undo` command** — that
was checked against the live CLI, not assumed — so a database copy alone cannot reverse an
import; and a ZFS rollback alone leaves beets' `incremental` state still claiming the work is
done, which makes the release invisible to a retry. Roll back the tree and the database together
or neither.

### Two traps that will mislead the next person

1. **The ownership normalisation cannot be re-run from LXC 100.** `chown` there returns
   `Operation not permitted` on every entry, even as container root. The container is
   unprivileged with a sparse idmap, and unmapped ids are not chownable from inside a user
   namespace. This is the **same errno as the `rsync`/ACL problem above from a completely
   different cause** — anyone repeating it will reasonably but wrongly blame
   `aclmode=restricted`. Run it on the Proxmox host.

2. **Any `uid:gid` in this document must say which view it came from.** LXC 100 and the
   hypervisor disagree, and this whole phase reasoned from the mapped view until the very last
   plan exposed it. The idmap collapses on-disk owners like this:

   | on disk (atlantis) | as seen inside LXC 100 |
   |---|---|
   | `0:545` | `65534:65534` |
   | `3000:545` | `65534:65534` — a *different* uid, hidden |
   | `568:545` | `568:65534` |
   | `100000:100000` | `0:0` (root *inside* the container) |

   Ground truth is one command:
   `ssh root@172.16.1.158 'find /mnt/tank/media/Music -printf "%U:%G\n" | sort | uniq -c'`

**And one pattern worth naming.** Six times in this phase a check reported a pass it had not
earned: a declared-YAML audit that could not see two commented-out stacks; a verification harness
that failed closed on a missing `PATH` entry and reported false corruption; a sidecar path-set
diff returning 0/0 while 83 files were rewritten in place; `find -xdev` silently skipping every
one of the 39 separate appdata datasets; an ownership assertion whose `-mindepth 1` excluded the
one directory the requirement names; and twice a justification for the `chown` value asserted
from a census that had not finished running. **Partial data stated as settled** is the failure
mode of this estate. Verify with a second, independent instrument before you write it down.

### How to re-run

Both scripts are host-resident and run from `/mnt/fast/stacks` on LXC 100 after a `git pull`.

| Command | Does |
|---|---|
| `bash scripts/check-music-freeze.sh` | audits all 8 sections; **exits 1** on any failed assertion. Read-only by contract |
| `bash scripts/check-music-freeze.sh --baseline` | same report, always exits 0 — for recording a before-state |
| `bash scripts/check-music-freeze.sh --sidecars` | emits the sidecar path list on stdout, report to stderr |
| `bash scripts/freeze-music-apply.sh fence` | builds the fence; idempotent, skips what exists, never rolls back or destroys a snapshot |
| `bash scripts/freeze-music-apply.sh ownership` | normalises `uid:gid`; delegates the `chown` to atlantis; refuses to run without the Music snapshot |
| `bash scripts/snapshot-music-tags.sh` / `diff-music-tags.sh` | the QUAL-01 capture and its field-level comparator |

The audit also runs on every `scripts/quick-health-check.sh` from the workstation, which is the
path already in use — a harness nobody runs is the same failure as no harness.

### Recorded, not actioned: `/mnt/tank/media/TV`

Full census, run from atlantis on 2026-08-18 —
`find /mnt/tank/media/<subtree> -printf '%U:%G\n' | sort | uniq -c`:

| Subtree | Dominant owners | On gid 545? |
|---|---|---|
| Photos | 368,826 `0:568`, 9,522 `100000:100000` | no |
| **TV** | **64,546 `0:545`, 49,672 `568:545`**, 2,466 `100000:100000`, 1,448 `568:568` | **yes — 114,218** |
| Movies | 22,903 `568:568`, 12,533 `0:568`, 635 `100000:100000` | no |
| Music | 2,674 `568:568` (all of it, post-normalisation) | no — was 2,357 |
| Books | 42 `568:0`, 5 `568:568` | no |

408,391 of 535,298 media entries (**76%**) carry gid `568`, which is what "estate convention"
means concretely. `/mnt/tank/media/TV` carries **114,218 entries on the same orphan gid 545** —
64,546 `0:545` plus 49,672 `568:545`, against Music's 2,357 before normalisation. Music was never
the outlier;
Music and TV almost certainly arrived together from a system where 545 was meaningful (the
Windows/SMB `Users` RID, the TrueNAS `builtin_users` gid). Music is now normalised and TV is not,
which leaves the two divergent.

**This is deliberately left alone.** No requirement in this milestone covers TV, and this
project's documented failure mode is scope growth followed by abandonment. The working method,
recorded so nobody has to rediscover it:

```bash
# On the Proxmox host — NOT on LXC 100, where this fails EPERM on every entry
ssh root@172.16.1.158
zfs snapshot tank/media/TV@pre-chown
chown -R 568:568 /mnt/tank/media/TV
```

Also unowned and recorded here rather than fixed: **uid 3000 owns 197,776 of `tank/downloads`'
209,039 entries (94.6%)** and also wrote the library's `.DS_Store`. Something writes as uid 3000;
nothing in this repo declares it.
