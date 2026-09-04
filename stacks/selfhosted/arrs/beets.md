# Beets: library state and the bulk-import backlog

Companion to [`beets/beets.yaml`](beets/beets.yaml) (manual container) and
[`soulbeet.yaml`](soulbeet.yaml) + [`soulbeet/beets_config.yaml`](soulbeet/beets_config.yaml)
(automated Soulseek → beets path).

Nothing here is applied by `docker compose`. This is the record of what the music library
currently looks like, why the tagging pipeline stalled, and how to work the backlog.

State as of 2026-09-04, after the Phase 1 safety harness and the Phase 3 tagger spike (last two
sections).

> **Both beets definitions now mount the library `:ro`, and wrtag's library mount is deleted.**
> Nothing in this document's "how to work the backlog" advice will write to `/mnt/tank/media/Music`
> until Phase 6 grants the surviving tagger `rw` again. That is intentional — see the last section.

> **The tagger is decided.** Phase 3 chose **beets** as the engine and **beets-flask's
> policy-carrying inboxes — not its interactive picker** — as the front end, on measurements taken
> from this library's own content against thresholds committed before the evidence existed. The
> full record, including what happens to Mastermix / DMC / Music Factory content and the three
> threshold outcomes, is
> [`.planning/phases/03-tagger-spike/03-DECISION.md`](../../../.planning/phases/03-tagger-spike/03-DECISION.md).
> See § *Phase 3 — the tagger decision* below for what it changes about the advice on this page.

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
  > (`getent group 568` → `apps:x:568:`), stated independently in `STANDARDS.md`
  > (§ Volume Mounting), `DEPLOYMENT.md` (§ Storage conventions), `README.md` (§ Storage) and
  > `CLAUDE.md`. If you ran the old line, you set a gid that resolves to no group; re-run the new
  > one from atlantis.
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
| owner | **`568:568`** (`apps:apps`) | The estate service account, stated independently in `STANDARDS.md` (§ Volume Mounting), `DEPLOYMENT.md` (§ Storage conventions), `README.md` (§ Storage) and `CLAUDE.md`. `getent group 568` → `apps:x:568:` on atlantis |
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

**Phase 2 inherited both halves, and did — this is DONE, not pending** *(2026-09-01)*. `568:568`
**is** the export's `anonuid`/`anongid`, and because ZFS `acltype=nfsv4` ACLs are not exported by
knfsd, **mode bits are the only lever NFS clients see** — so the export **is** read-only, since the
tree is world-writable. Proven at the export layer, not by configuration politeness: a hand-rolled
`mount -o rw` from the NUC *succeeded* and every write was still refused `EROFS`. See
§ "Phase 2 — the NFS export and Music Assistant" below.

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

---

## Phase 2 — the NFS export and Music Assistant (2026-09-01)

The library had one consumer. It now has two: **Jellyfin on LXC 100 and Music Assistant on the
HA NUC read the same tree**, MA over a read-only NFSv4 export served from the Proxmox host. This
section records **what is true now and how to operate it**; the narrative lives in
`.planning/phases/02-nfs-export-and-music-assistant-reachability/02-0N-SUMMARY.md`.

Music Assistant runs as a **Home Assistant add-on on the NUC**, so it has no stack in this repo
for a document to sit beside. This file is its document-beside-the-stack home, because the library
it reads is the one this file is about.

**Every assertion below was proven at Music Assistant `2.11.0b0`** — a BETA, with `auto_update`
**on**, and stable not installed at all. That version stamp is not decoration: it is the drift
detector. `scripts/check-music-consumers.sh` records the live version on every run, so an MA
release that changes provider behaviour surfaces as a failed assertion beside a changed version,
rather than as a silent pass.

### The export

Source of truth is **`infra/nfs-music-export.tf`**. Terraform writes `/etc/exports.d/music.exports`
on atlantis; never hand-edit it. Live line, from `exportfs -v` on atlantis (continuations joined —
see the traps below):

```
/mnt/tank/media/Music 172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
```

| Option | Value | Why |
|---|---|---|
| client | **`172.16.1.31`**, a bare address | The NUC's LAN IP and nothing else. No wildcard, no CIDR. Measured, not taken from `NETWORK.md`: `ip route get 172.16.1.158` on the NUC returns `src 172.16.1.31` |
| — | *(tailnet `100.73.196.51` deliberately absent)* | NFS never crosses the tailnet in this design; adding it widens the blast radius for nothing. Off-LAN mounting would be a deliberate new export line |
| `ro` | read-only | **Forced, not chosen.** The tree is `0777` (Phase 1, above) and ZFS `acltype=nfsv4` ACLs are not exported by knfsd, so mode bits are the only lever a client sees. A world-writable tree therefore *must* be exported `ro` |
| `all_squash` | every client identity | With `anonuid`/`anongid` below, every access lands as the service account regardless of who the client claims to be |
| `anonuid=568` `anongid=568` | `apps:apps` | Inherits Phase 1's WRIT-04 normalisation directly |
| **`mountpoint`** | — | **The single highest-value option, and it is in NEITHER of `CLAUDE.md`'s two original candidate option sets.** It makes `rpc.mountd` refuse to serve the export when the ZFS dataset is not mounted, so a boot race cannot export an empty directory and make the library look deleted. **Proven** — see the trap about `exportfs -v` below |
| `no_subtree_check` | — | Standard for a whole-dataset export |
| `sec=sys` | — | Accepted residual risk, recorded as a choice in `.planning/PROJECT.md` § Key Decisions. `xprtsec=` (RFC 9289) and `sec=krb5` were both considered and rejected |
| `root_squash`, `secure` | — | `no_root_squash` is forbidden by `CLAUDE.md` and is moot under `all_squash` anyway |

Server side: `nfs-kernel-server 1:2.8.3-1` from `deb.debian.org/debian trixie/main`, on **atlantis**
(the Proxmox host), never on LXC 100 — that container is unprivileged and `nfsd` is privileged-only.
The unit is **enabled**, so it survives a host reboot, and carries an ordering drop-in
`After=zfs-mount.service` (guard M2). **Port 2049 is this phase's only delta.** 111 (rpcbind) was
already open from the pre-existing `nfs-common` — asserting on 111 claims a transition this work
did not cause.

### The client half — the mount and the provider

On the NUC, through HA Supervisor. Route A (Supervisor network storage) beat Route B (MA's own
remote-share provider); the decision and Route B's failure symptom are in `.planning/PROJECT.md`.

```bash
# Supervisor mount. The name must match ^[A-Za-z0-9_]+$ — `tank-music` is rejected opaquely.
# The server is an IP because HAOS has no guaranteed resolver.
ha mounts add music --type nfs --usage media --server 172.16.1.158 \
    --path /mnt/tank/media/Music --read-only --no-progress

ha mounts info --raw-json
# -> {"path":"/mnt/tank/media/Music","server":"172.16.1.158","name":"music","type":"nfs",
#     "usage":"media","read_only":true,"state":"active","user_path":"/media/music"}
```

MA then reads `/media/music` through a **filesystem_local** provider created headlessly. Note the
**second save**: the provider is created first, and `missing_album_artist_action` is set by a
follow-up `config/providers/save`.

```
config/providers/setup  {"provider_domain":"filesystem_local"}                    -> flow_id
config/flows/submit     {values:{content_type:"music", path:"/media/music"}}      -> instance_id
config/providers/save   {values:{missing_album_artist_action:"folder_name"}}      <- the second call
```

**PINNED IDENTITIES — these are identities, not settings. Changing them silently breaks things:**

| | Value |
|---|---|
| MA provider instance | `filesystem_local--XJaJWNUS` |
| MA endpoint (from the LAN) | `http://172.16.1.31:8095/api` |
| MA endpoint (from a tailnet vantage) | `http://100.73.196.51:8095/api` — the NUC's LAN IP is unreachable from the tailnet while it is the *standby* subnet router |
| Supervisor mount name / user path | `music` / `/media/music` |
| MA version every assertion was proven at | **`2.11.0b0`** (BETA, `auto_update` on) |

Credentials are referenced **by variable name only** — this repo is public and has one prior
exposure on record. `/mnt/fast/secrets/ma-deercrest.env` and
`/mnt/fast/secrets/jellyfin-deercrest.env` on LXC 100 (both `0600 root`, the Jellyfin key is named
`music-consumers-audit`); `~/.claude/secrets/music-assistant.env` and
`~/.claude/secrets/ha-deercrest.env` on the workstation; `/config/secrets.yaml` key
`ma_ha_sync_authorization` on the NUC.

### The API assertion shapes

MA 2.11's API has three traps that each produce a *silent pass* — a green result with the mount
broken or absent. Use these shapes, not the obvious ones.

```bash
# Authenticate. There is no API-token screen in MA 2.11's UI (there IS an auth/token/create
# API command). Log in per run rather than caching — a cached JWT expires silently.
POST /api  {"command":"auth/login","args":{"username":"...","password":"..."}}  -> .access_token
#   then: Authorization: Bearer <token>          <- MA rejects a bare token outright
#   Responses are NOT wrapped in .result — auth/login returns {access_token,...},
#   config/providers returns a BARE ARRAY. A `.result[]` filter errors, and under `|| true`
#   that reads as "no providers".

# Trigger a sync rather than waiting out the 12 h default sync_interval.
{"command":"music/sync","args":{"providers":["filesystem_local--XJaJWNUS"],
                                "media_types":["track"]}}
#   Poll tasks/get for status; the concurrency guard logs "Library sync already running"
#   and returns, which otherwise looks like a completed sync.

# Count / list albums. The filter argument here is `provider`, and it takes an instance id.
{"command":"music/albums/library_items","args":{"provider":"filesystem_local--XJaJWNUS"}}
#   ⚠ NEVER use music/albums/count — IT HAS NO PROVIDER PARAMETER. Measured: 87 with and
#     without the arg while the provider-filtered list held 9. It reports green off Spotify's
#     catalogue with no mount at all. Spotify is live on this MA instance.
#   ⚠ NEVER pass the album name as `search`. It is not a substring match: an album's own exact
#     name returned [] while a shorter token returned the same album from the same provider in
#     the same second. Filter on `provider`, pull the list, and compare byte-exact locally.
```

Provider-filtered counts and the two library proof albums, at plan close:

```
music/albums/library_items, provider=filesystem_local--XJaJWNUS   ->  70
Lifelines            / Chris Norman     EXACT on album name AND artists[0].name
The Ultimate Hits    / Garth Brooks     EXACT on album name AND artists[0].name
```

### The album-artist fallback, and its precondition

`missing_album_artist_action` is **`folder_name`**, permanently — not MA's `various_artists`
default, which is a trap for a library heavy on DJ compilations that legitimately *are* Various
Artists. It fired **183 times** across the live library during the criterion-3 sync.

**⚠ IT IS CONDITIONAL, AND THE API CANNOT TELL YOU IT DID NOT FIRE.** It fires only when a file's
`album` **tag** agrees with its album **folder** name (a trailing `(year)` is ignored). On a
mismatch MA silently falls back to `Various Artists` **while `config/providers/get` still reads
back `folder_name`**. Isolated with a four-cell variant matrix, not inferred:

| artist folder | album folder | `album` TAG | track `artist` TAG | MA's own log line | result |
|---|---|---|---|---|---|
| `ZZ Phase2 Fallback Control` | `Untagged Control Album (2026)` | **mismatch** | decoy | `using Various Artists as fallback` | `Various Artists` |
| `QQ Control Bravo` | `Bravo Album (2026)` | **match** | matches | `using foldername QQ Control Bravo as fallback` | `QQ Control Bravo` ✅ |
| `QQ Control Charlie` | `Charlie Album (2026)` | **match** | **decoy** | `using foldername QQ Control Charlie as fallback` | `QQ Control Charlie` ✅ |
| `QQ Control Delta` | `Delta Album (2026)` | **mismatch** | matches | `using Various Artists as fallback` | `Various Artists` |

The track-artist tag is irrelevant. **Reading the setting back is not proof it applies.** Album
identity in MA is `albumartist + os.sep + album`, so a wrong album artist is durable, and clearing
it means removing the provider — which purges every item exclusive to it, favourites and play
counts included.

**A live library defect, recorded and deliberately NOT repaired:**
`/mnt/tank/media/Music/Def Leppard/Def Leppard (2015)/` derives an **empty** album artist and hard-
errors `CD 01-06 Def Leppard - Sea of Love.flac`, because the album folder name equals the artist
folder name — MA appears to match the album tag against the path and take the *parent*, which lands
on the provider root. The remedy is never tag repair (nobody holds `rw` on Music until Phase 6 and
the export is `ro`), and the file itself is fine: `zpool status -v tank` reports no known data
errors, so it is not 2026-07 scrub damage. Handed to Phase 7.

### Reboot evidence

Both transcripts below are **ANSI stripped, otherwise unedited**.

**Positive reboot** — NUC rebooted with atlantis healthy, `boot_id` proven changed
(`b86dada0…` → `3a7906c0…`), **zero manual intervention**: no remount, no `ha mounts reload`, no
add-on restart, no hand sync.

```
mount state          {"state":"active","read_only":true}
ls -1 /media/music   13        (artist folders)
MA albums, provider-filtered   70
proof albums                   2/2 EXACT
M4a fired unprompted at        2026-09-01T12:43:25.944109+00:00   (~120 s after HA start)
check-music-consumers.sh       exit 0, FAILURES 0
```

**Negative control** — `nfs-server` stopped on atlantis *before* the reboot. This is the case the
`mountpoint` option and M4 exist for, and a green positive reboot proves nothing about it.

```
2026-09-01 13:50:58.310 ERROR   [supervisor.mounts.mount] Mounting music did not succeed. Check host logs for errors from mount or systemd unit mnt-data-supervisor-mounts-music.mount for details.
2026-09-01 13:50:58.311 INFO    [supervisor.resolution.module] Create new issue mount_failed - mount / music
2026-09-01 13:50:58.312 WARNING [supervisor.mounts.manager] Mount music failed to mount, mounting read-only fallback for /mnt/data/supervisor/media/music
```

```
2026-09-01 13:54:22.020 ERROR [music_assistant.Filesystem (local disk)] Aborting sync for Filesystem (local disk): scan found no files but 1244 were previously indexed
```

**MA's deletion guard held — the whole point.** Provider-filtered albums: **70 before, 70 during
the degraded window, 70 after recovery.** The library went **stale, not empty**.

**Supervisor recovered UNATTENDED in 432 s (7 m 12 s)** from `nfs-server` returning — NUC untouched
throughout, polled every 60 s. This settles a question community reports dispute. Note the measured
interval is ~7 minutes, **not** the ~900 s the research assumed. `M4b` then fired on its own at
`13:12:06.616219Z` and re-synced MA; nothing was hand-triggered.

**What Supervisor's failure actually looks like — and a check that can never match it:**

```
mount | grep -c -i emergency   ->  0            (there is NO /emergency/ bind mount here)
ls -ld /media/music            ->  dr--r--r--  2 root root
ls -A /media/music | wc -l     ->  0
                        healthy, for contrast:  drwxrwxrwx 15 568 568, 13 artist folders
```

Supervisor makes the media directory **read-only in place and leaves it empty**. So "does
`/media/music` exist" is exactly the check that returns a false green, and
`mount | grep emergency/music` — which several sources suggest — can never match on this version.
**The working proof line is the entry count.**

### The Home Assistant automations (M4 + the mount alerting)

These live at **`/config/packages/music02_ma_nfs_mount.yaml` on the NUC**. This repo contains no HA
configuration at all, so they have no home in git — the record is here and in `02-08-SUMMARY.md`,
which carries the fully-annotated original including the diagnosis comments. The token appears only
as its `!secret` reference and **must never be committed**.

```yaml
rest_command:
  music_assistant_sync_local:
    url: "http://172.16.1.31:8095/api"
    method: post
    content_type: "application/json"
    headers:
      # Holds the COMPLETE header value ("Bearer <token>") — MA rejects a bare token.
      Authorization: !secret ma_ha_sync_authorization
    payload: >-
      {"command": "music/sync",
       "args": {"providers": ["filesystem_local--XJaJWNUS"],
                "media_types": ["track"]}}
    timeout: 30

# `ls -1` deliberately, not `ls -A`: the library root carries a .DS_Store, so `ls -A` reads 14
# where `ls -1` reads 13. Expected value is 13. Runs in the HA Core container, which receives
# the same /media bind. This is the instrument that works — see the empty-directory note above.
command_line:
  - sensor:
      name: "Music library NFS mount"
      unique_id: music02_music_library_nfs_mount
      command: "ls -1 /media/music 2>/dev/null | wc -l"
      unit_of_measurement: "folders"
      scan_interval: 300
      command_timeout: 20

automation:
  # M4a — collapses the post-reboot staleness window from <=12 h to ~2 min.
  - id: music02_ma_sync_after_ha_start
    alias: "Music: re-sync Music Assistant 120 s after Home Assistant starts"
    mode: single
    triggers:
      - trigger: homeassistant
        event: start
    conditions: []
    actions:
      - delay: "00:02:00"
      - action: rest_command.music_assistant_sync_local

  # M4b — the case M4a does NOT cover: mount failed at boot, Supervisor re-mounted it later,
  # MA still holding a stale library. Fired unprompted during the live negative control.
  - id: music02_ma_sync_on_mount_restored
    alias: "Music: re-sync Music Assistant when the NFS library mount returns"
    mode: single
    triggers:
      - trigger: numeric_state
        entity_id: sensor.music_library_nfs_mount
        above: 0
    conditions:
      - condition: template
        value_template: >-
          {{ trigger.from_state is not none
             and (trigger.from_state.state in ['0', 'unknown', 'unavailable']) }}
    actions:
      - action: rest_command.music_assistant_sync_local
      - action: notify.mobile_app_crusader
        data:
          title: "Music library mount recovered"
          message: >-
            /media/music is back ({{ states('sensor.music_library_nfs_mount') }}
            artist folders) and Music Assistant has been told to re-sync.
          data:
            push: { sound: { name: default } }
            interruption-level: active

  # The failure alert. THREE triggers, and `boot` is the load-bearing one — see the trap below.
  - id: music02_nfs_mount_failed_alert
    alias: "Music: NFS library mount failed or is empty"
    mode: single
    triggers:
      - trigger: homeassistant          # fires AT ATTACH TIME — catches a mount that was
        event: start                    # already broken before this automation existed
        id: boot
      - trigger: numeric_state          # the original: the mount failing mid-run
        entity_id: sensor.music_library_nfs_mount
        below: 1
        id: crossing
      - trigger: state                  # the sensor LANDS on a bad value without crossing
        entity_id: sensor.music_library_nfs_mount
        to: ["0", "unknown", "unavailable"]
        id: landed
    conditions: []
    actions:
      # Hold, then RE-READ. This replaces a `for:` that used to sit on the trigger.
      - delay: "00:05:00"
      - condition: template
        value_template: >-
          {{ states('sensor.music_library_nfs_mount')
             in ['0', 'unknown', 'unavailable'] }}
      - action: notify.mobile_app_crusader
        data:
          title: "Music library mount is down"
          message: >-
            /media/music has {{ states('sensor.music_library_nfs_mount') }}
            artist folders (expected 13). Music Assistant will still list the
            albums but none of them will play. Check nfs-server on atlantis
            (172.16.1.158). Supervisor does retry on its own — measured
            2026-09-01, it recovered unattended 7 min after the server returned.
          data:
            push: { sound: { name: default } }
            interruption-level: active

  # ⚠ OPEN ITEM — see "still open" below. Correct, proven by a synthetic event, and BLIND AT
  # BOOT by integration-setup ordering, which is when it is needed.
  - id: music02_supervisor_issue_raised
    alias: "Music: Supervisor raised a system issue"
    mode: queued
    max: 10
    triggers:
      - trigger: event
        event_type: repairs_issue_registry_updated
        event_data:
          action: create
          domain: hassio
    conditions: []
    actions:
      - action: notify.mobile_app_crusader
        data:
          title: "Supervisor raised a system issue"
          message: >-
            Home Assistant Supervisor raised a new repairs issue
            ({{ trigger.event.data.issue_id }}). If the music library is
            involved this is MOUNT_FAILED — check Settings > System > Repairs.
          data:
            push: { sound: { name: default } }
            interruption-level: active
```

`/config/secrets.yaml` gained exactly one key, `ma_ha_sync_authorization`, holding the complete
`Bearer <token>` header value. Minted via MA `auth/token/create`, name
`"HA M4 music sync (phase 02-08)"`, 1-year expiry, no auto-renew, revocable by `token_id` through
`auth/token/revoke`. It is **separate** from the audit-script credential on LXC 100 so either can
be replaced without breaking the other. A NUC rebuild restores everything above from this document
except the token, which must be re-minted.

### How to re-run

`check-music-consumers.sh` is host-resident on LXC 100 and runs from `/mnt/fast/stacks` after a
`git pull` — same as the Phase 1 scripts. It is host-resident for **credentials and reachability**,
not command length: Jellyfin publishes no host port and is reachable only from LXC 100, and both
credentials live at `/mnt/fast/secrets/` there.

| Command | Does |
|---|---|
| `bash scripts/check-music-consumers.sh` | audits all 6 sections — export, MA reachability and provider identity, the three proof albums in MA, the same three in Jellyfin, mount liveness; **exits 1** on any failed assertion, **2** on a bad flag. Read-only by contract: it never calls `music/sync` |
| `bash scripts/check-music-consumers.sh --baseline` | same report, always exits 0 — for recording a before-state |
| `bash scripts/check-music-consumers.sh -h` | usage, exit 0 |
| `MA_TEMP_PROVIDER_INSTANCE=<id> bash scripts/check-music-consumers.sh` | additionally **asserts** the `scope=temp-export` proof album. Unset (the normal state) that row is *reported with its reason inline*, never silently passed and never permanently red |
| `bash scripts/quick-health-check.sh` *(workstation)* | runs the freeze harness **and** the consumers audit over ssh; exits 1 if either fails or is unreachable |

The consumers audit runs on every `quick-health-check.sh` from the workstation, which is the path
already in use — a harness nobody runs is the same failure as no harness. It is also the tool
Phase 7's CONS-04 calls: its pinned album set is the definition-of-done instrument.

Server-side, from atlantis: `exportfs -v`. Client-side, from the NUC: `/proc/self/mountinfo`.
**`showmount` and `findmnt` are both ABSENT on the NUC** — measured. Do not write a runbook step
that asks for them there. `sha256sum` and `nc` *are* present.

### Rollback — a TESTED two-sided teardown

Executed against real state on 2026-09-01 for the *temporary* control export and provider (02-07),
so this is a tested procedure rather than a hoped-for one — **including the step that did not work
as authored**, which is the half a runbook most needs. Run in this order (B-9: client before
server, so nothing holds an open file handle when the export goes away).

**1. Remove the MA provider.**

```
{"command":"config/providers/remove","args":{"instance_id":"filesystem_local--XJaJWNUS"}}
```

Returns `null` and completes. **Know what this costs before running it:** measured on the
disposable instance, it is a *complete purge* of every item exclusive to that provider — albums,
tracks and artists all to 0, with no orphans — and it takes every favourite and play count attached
to them. Albums on other providers are untouched.

**2. Unmount on the NUC.**

```bash
ha mounts remove music
grep -c '/media/music' /proc/self/mountinfo          # -> 0, from the host AND inside the MA container
sudo rmdir /media/music                              # Supervisor leaves an empty stub behind
```

**3. Disable the export in Terraform — through the plan gate, never a bare apply.**

```bash
cd infra
terraform plan -out=/tmp/tf.plan          # then READ it
terraform show -json /tmp/tf.plan | ...   # assert: zero destroys of the LXC, no forces-replacement
terraform apply /tmp/tf.plan              # apply the SAVED plan
```

⚠ **A `null_resource` destroy removes NOTHING from the host.** Setting the flag false and
destroying the resource drops Terraform state only: the drop-in would stay on disk and the export
would stay **live**, while `terraform plan` reported clean. That is why the teardown lives in an
**always-present reconciler resource** that removes the drop-in and re-converges `exportfs` at
*apply* time. A destroy-time provisioner was tried and rejected twice: `terraform validate` refuses
one that reaches the resource `connection` block, and the only workaround persists the **Proxmox
root password** into state in plaintext and into every plan diff — in a public repo.

**Assert afterwards, all four:** `exportfs -v` shows only the expected lines; the removed provider's
`music/albums/library_items` returns `[]`; the provider is absent from `config/providers`; and
`terraform plan -detailed-exitcode` exits **0**.

### Traps that will mislead the next person

1. **`exportfs -v` printing an export line does NOT mean that export will serve.** This one cost
   three plans. `mountpoint` was recorded as configured-but-unproven in 02-03 and 02-05 because the
   export stays listed while the dataset is unmounted. The observation was right and the inference
   wrong: **the export TABLE is non-discriminating; the SERVED MOUNT is genuinely refused.** The
   only `mountpoint`-quality check is a real client mount attempt, control-probe-control:

   ```
   A  dataset mounted    -> mount exit 0,   14 entries
   B  dataset unmounted  -> mount exit 255, "No such file or directory", 0 entries
   C  dataset remounted  -> mount exit 0,   14 entries
   #  sudo mount -t nfs4 -o ro,soft,timeo=50,retrans=2 \
   #       172.16.1.158:/mnt/tank/media/Music /tmp/m1probe
   ```

   Run the control **first**. Without it, a failure cannot be distinguished from incapacity.

2. **A different route needs a different evidence set.** Route A's observables (`ha mounts info`
   state, the `nfs4` line in `/proc/self/mountinfo`, `emergency_count=0`) do not describe Route B at
   all. Running Route A's checks against a Route B installation passes **vacuously**. If the route
   is ever changed, the checks change with it.

3. **Measure the NUC's source address; do not take it from `NETWORK.md`.**
   `ip route get 172.16.1.158` on the NUC. The export is restricted to a single bare address and a
   documented-but-wrong one fails opaquely.

4. **`exportfs -v` wraps.** The `client(options)` field lands on its own continuation line for these
   paths. Join continuations before parsing or a client string can be credited to the wrong export.

5. **A nested `ssh` eats the outer script's stdin** — use `ssh -n` for inline `ssh host 'cmd'`.
   **But `ssh -n` also eats a heredoc**: `ssh -n host 'bash -s' <<EOF` points stdin at `/dev/null`,
   discards the script and exits 0. `-n` for inline commands ONLY.

6. **Never reach Jellyfin by an IP literal or by the bare name from LXC 100.** Its `t3_proxy`
   address moves (`192.168.90.25` today, not the `.31` two earlier plans pinned), and the bare name
   `jellyfin` resolves to **Cloudflare's public edge** because of `search deercrest.info` — a check
   would pass against the public site with the container down. Resolve fresh:
   `docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'`.

7. **Never edit `mount_point` in `infra/lxc-*.tf` expecting it to apply.** `ignore_changes` is set
   on both, so real bind-mount edits plan clean and do nothing.

### The six silent-pass mechanisms found in Phase 2

Collected in one place because the count is the point — six is not bad luck, it is the shape of
this estate's failures. Every one of them produces a **green result from a broken system**.

| # | Mechanism | Found in |
|---|---|---|
| 1 | `music/albums/count` has **no provider parameter** — 87 with and without the arg while the provider-filtered list held 9. It reports green off Spotify's catalogue with no mount at all | 02-04 |
| 2 | MA `POST /api` responses are **not `.result`-wrapped** — a `.result[]` filter errors, and under `\|\| true` that reads as "no providers" | 02-04 |
| 3 | `missing_album_artist_action` **reads back `folder_name` while silently using `Various Artists`** — the API cannot tell you the setting did not apply | 02-07 |
| 4 | **Destroying a `null_resource` removes nothing from the host** — the export stayed live while `terraform plan` reported clean and state said the resource was gone | 02-07 |
| 5 | **Default `ha supervisor logs` depth does not reach back to boot** — a default-depth `grep -i 'read-only fallback'` returns nothing and is indistinguishable from "it did not happen". `-n 2000` was required | 02-08 |
| 6 | **`exportfs -v` showing an export line does not mean that export will serve** — see trap 1 | 02-08 |

Listed apart because it is the *opposite* failure mode: `mount \| grep emergency/music` produces a
false **negative** — it can never match on this Supervisor version, so it argues that a working
guard did not fire.

And one more, from MA 2.11's API rather than this estate: `search` on `library_items` is **not a
substring match**. An album's own exact name returned `[]` while a shorter token returned the same
album from the same provider in the same second — a false *failure* on a gate whose whole value is
being trusted.

### Still open

- **The Supervisor repairs-issue alert (`music02_supervisor_issue_raised`) is BLIND AT BOOT.**
  Diagnosed, not fixed, and deliberately so. The trigger configuration is **correct** — a synthetic
  `repairs_issue_registry_updated` event fired it in 542 ms. It is blind by **ordering, not by
  race**: `hassio` mirrors Supervisor issues into HA's repairs registry **13–18 s before the
  `automation` domain sets up**, consistently across four observed starts. A genuine
  `{action: create, domain: hassio}` event at `12:51:53.032Z` hit a trigger that attached at
  `12:52:21.951Z`. `hassio` is a bootstrap-stage integration and `automation` is not, so this misses
  **every** time rather than sometimes. **The recorded fix:** a state-based check of Supervisor's
  resolution centre at startup — a `command_line` sensor against `http://supervisor/resolution/info`
  using `$SUPERVISOR_TOKEN`, which the SSH add-on's sudoers already `env_keep`s — instead of the
  create event. Rejected *for now* on two grounds: for the only issue type this phase cares about it
  duplicates `music02_nfs_mount_failed_alert`, which has its own boot trigger; and scoped any wider
  it would immediately and repeatedly page for pre-existing issues nobody has chosen to act on.
- **The notify path has never been reached against a genuinely bad mount.** The failure alert's
  *trigger* path is proven by firing (both new triggers, trace-confirmed) and its action gate is
  proven to swallow a transient. Delivery is proven only as "`notify.mobile_app_crusader` is a
  registered service and both message templates render against live state". Closing this needs
  another fault injection.
- **MA's token table holds 100 entries, 99 of them `WebSocket Session - damian`** — one per audit
  run, each on a 30-day sliding expiry, and `auth/tokens` caps its response at 100. The fix is a
  named long-lived token for the audit script too, now that `auth/token/create` is known to exist.
- **Rotate at project close:** the MA audit credential, the Jellyfin `music-consumers-audit` API
  key, the MA HA-sync token, and Discogs. Also `Xonora` — a pre-existing MA long-lived token created
  2026-02-21, expiring **2036**, unused since 2026-03-29, unattributed.
- **Spotify is enabled and `auth_required`** on this MA instance and still returns library items.
  Every assertion in this section is provider-filtered on `filesystem_local--XJaJWNUS`; that filter
  is load-bearing and was never relaxed.

---

## Phase 3 — the tagger decision (2026-09-04)

The estate had four tagging entry points and no measured basis for choosing between them. Phase 3
chose, on numbers from this library's own content, against three overturning thresholds committed
to a pushed commit **before any evidence existed**. The full record — every threshold, its
instrument, what it returned, and the evidence artefact behind each verdict — is
[`.planning/phases/03-tagger-spike/03-DECISION.md`](../../../.planning/phases/03-tagger-spike/03-DECISION.md).

**The one-line outcome: the engine is beets 2.13.1, and the front end is beets-flask's
policy-carrying inbox architecture — explicitly NOT its interactive candidate picker.**

| | Chosen | Because |
|---|---|---|
| Engine | **beets 2.13.1** | wrtag has **no non-MusicBrainz metadata source** and this backlog is not in MusicBrainz. Separately, wrtag was **disqualified on measurement**: this repo's `WRTAG_PATH_FORMAT` renders on **none** of v0.20.0, v0.33.0 or v0.34.0 |
| Front end | **beets-flask policy inboxes** (`preview` / `auto` / `bootleg`) | The operator's own T3 answer rules out sitting at the terminal prompt; the inbox path needs **no interactive prompt at all** and produced the best measured result of either arm |
| **Not** chosen | beets-flask's **interactive picker** | It accepted a 75% match that **silently dropped 9 of 31 files and wrote 4 tracks onto different songs**, while asserting *"All tracks on disk found online"*. Plus an intermittent full-page crash the backend never logs |
| Normalisation | **`scripts/normalise-dj-tags.py`** | Binding regardless of engine. Dry-run by default with a reviewable per-file diff; the alternative wrote a wrong value on 20 of 205 files with no dry run to catch it |

### What this changes about the advice above

- **§ *Two config gaps* is confirmed, not superseded.** Bucket C really does need `-A` after
  normalisation, and the **`1-115` split-per-volume instruction STANDS** — the set exists, 45 G and
  **4,746 audio files**, 61% of the backlog's files. A mid-phase claim that it did not exist was
  retracted on measurement.
- **Discogs is a much weaker answer for bucket C than this page implies.** Measured strict match
  rate over the normalised sample: **27.08%** backlog-weighted, against a 40% threshold — it
  **fired**. The **DMC stratum scored strict 0 of 4**: the catalogue does not reach issues 498,
  499, 233 or 234. And 1 of the 6 strict hits was a **confident wrong release**.
- **Rate limiting is not the obstacle.** Whole-backlog projection **21.8 minutes**, **zero** HTTP
  429. Note that **MusicBrainz throttles with HTTP 503, not 429** — a guard watching only for 429
  will report a clean run while being throttled.
- **A likely better source than either was found and is unproven.** `mastermixdj.com` publishes
  per-track number, artist, title, BPM and duration as plain HTML for the DJ-service content, which
  is **~76% of the backlog**. **One page was verified.** Coverage is unmeasured — Phase 4 research
  owns it, and nothing should be designed around it before then.

### One correction to this page's own § *The recovery fence*

That section states, as a hard constraint, *"beets has **no `undo` command** — that was checked
against the live CLI, not assumed"*. **That remains true of the beets CLI and is narrower than it
reads: beets-flask rc6 has a working `UNDO IMPORT`**, verified by use (destination gone, library
0 entries, source intact at 31 files). The original wording is left standing above because it was
correct against what it measured. **Do not over-read the correction either** — it was exercised on
one import, in a release candidate, and it reverses the import, not the tag writes made into the
files. Phase 4 owns amending the constraint in `CLAUDE.md` and `PROJECT.md`; **Phase 7's "undo
exercised" criterion now has two candidate mechanisms rather than one.**

### Two buttons never to press on this collection

Both are one-click bulk actions in beets-flask, and **neither was pressed or scripted at any point
in Phase 3, deliberately**:

- **`DELETE IMPORTED FOLDERS`** — keyed solely on an `Imported` badge that was set on a folder that
  was 9 audio files short and 4 tracks mis-titled. Pressing it would have destroyed the only intact
  copy of the dropped tracks. Treat the badge as *"an import ran"*, never as *"the import was
  complete and correct"*.
- **`IMPORT BEST`** — a bulk accept of "best" candidates with **no per-album review**, on a
  collection measured at a **1-in-6** wrong-strict-match rate.

### Standing action, carried forward

**Rotate the Discogs personal access token at project close.** It is not a Phase 3 task — the
operator decided the timing — but the reasons have accumulated: it was written to a `644` file by a
logging path nobody expected (`python3-discogs-client` puts the token in the **query string**, not
an `Authorization` header), written to disk a second time by an ad-hoc verification command, and
rendered into an agent transcript that cannot be shredded. Every on-disk copy was removed and
verified gone at Phase 3 close; `/mnt/fast/secrets/discogs.env` remains the single source at
`600 root`. **This repository is public** — credentials go in `/mnt/fast/secrets/` and
`~/.claude/secrets/`, referenced by variable name only.
