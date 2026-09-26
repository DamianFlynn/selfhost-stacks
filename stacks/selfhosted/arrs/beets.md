# Beets: library state and the bulk-import backlog

Companion to [`beets/beets.yaml`](beets/beets.yaml) — the one surviving tagger definition.

`soulbeet.yaml`, `soulbeet/beets_config.yaml` and `../music/wrtag.yaml` were **deleted from this
repo on 2026-09-11** by plan 04-03 (D-01, D-05), which is why they are no longer linked here. The
last commit that contains them is `5d0af70`; recover any one of them with
`git show 5d0af70:stacks/selfhosted/arrs/soulbeet.yaml` or the equivalent path.

Nothing here is applied by `docker compose`. This is the record of what the music library
currently looks like, why the tagging pipeline stalled, and how to work the backlog.

State as of 2026-09-04, after the Phase 1 safety harness and the Phase 3 tagger spike (last two
sections).

> **Current state — read this first.** This file is a **running log, appended phase by phase**. The
> newest section is the live picture; claims above it may have been superseded in place, or kept
> deliberately as retractions. Do not read an early section as current.
>
> The authoritative current state is the section headed
> *Phase 6 closed 2026-09-21 — four criteria TRUE, one OPEN on a named half, all five RE-MEASURED at close*.
> Its verdict table is the sub-section headed *The five criteria* **under that heading** — the same
> sub-heading text also appears in the Phase 5 closure above it, so disambiguate by the parent — and
> what remains open is the sub-section headed *Still open at Phase 6 close*.
>
> **Cited by heading text, never by line number:** line citations in this repository go stale the
> moment anything is inserted above them, and this file only ever grows by append. (`06-REVIEW.md`
> § IN-02 suggests a line number; citing the heading text instead is a deliberate improvement on
> that advice, not an oversight. Search for the heading text.)
>
> **Phase 6's disposition — CLOSED WITH ONE OPEN REQUIREMENT: CONF-04, on its Jellyfin half only.**
> That half is carried to Phase 7 entry criterion **E6** under the operator's recorded
> `negative-carry-e6` override (2026-09-24), and `.planning/REQUIREMENTS.md`'s CONF-04 checkbox is
> deliberately still **unticked**, because an override is an auditable carry of an open requirement
> and not a close. The **Music Assistant half IS discharged**. The two verdicts are **never summed**
> into a single CONF-04 answer.
>
> **The go-forward rule, as a rule and not a hope:** every future phase-closure section appended to
> this file **must update this pointer in the same commit**. A closure section whose pointer was not
> updated is the defect — not the pointer.

> **Amended 2026-09-11 (plan 04-05).** The wrtag and soulbeet **definitions are deleted from this
> repository** (plan 04-03, D-01/D-05), so what they used to mount is now moot rather than
> reassuring. The one surviving definition, `beets/beets.yaml`, mounts the library `:ro`.
> **Host runtime retirement has not happened yet:** the images, the appdata trees and the
> `wrtag.deercrest.info` DNS record were all still present when this line was written, and plans
> 04-07 and 04-11 of this phase own removing them.
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

## One beets, one library

*Rewritten 2026-09-13 by plan 04-13. This section used to be headed "Two beets, one library" and
described `beets` and `soulbeet` as two entry points writing to the same tree with separate
databases. Phase 4 retired soulbeet — definition deleted from the repo on 2026-09-11, host runtime
and appdata removed on 2026-09-13 — so that hazard no longer exists and the old table is not
preserved here; `git show 5d0af70:stacks/selfhosted/arrs/soulbeet.yaml` still has it.*

There is now **one** beets definition, and it is deliberately dormant. There is also one **defused**
beets config under sabnzbd that nothing invokes. Both are listed because the second one exists on
disk and will otherwise be mistaken for a second entry point.

| | the survivor | the defused sabnzbd guard |
|---|---|---|
| Defined in | `arrs/beets/beets.yaml` | `arrs/sabnzbd.yaml` (config only — sabnzbd is not a tagger) |
| Image | `lscr.io/linuxserver/beets:2.13.1-ls349` | n/a |
| Runs | **never unattended** — `restart: "no"`, `profiles: ["manual"]`, and its `include:` line in `arrs/compose.yaml` is commented out (`#  - beets/beets.yaml`) | n/a — **nothing invokes beets on this path** since `audio.bash`'s line-285 `beet … import` was stripped (plan 04-10) |
| Config | `arrs/beets/config.yaml`, **vendored in this repo** and bind-mounted `:ro` over `/config/config.yaml` | `arrs/sabnzbd/beets-config.yaml`, **vendored** and bind-mounted `:ro` |
| `plugins:` | `musicbrainz` | `embedart musicbrainz` |
| Library db | **one** `library.db`, at the explicit `library: /config/library.db` — created fresh by the survivor itself at `2.13.1-ls349` on 2026-09-11 (D-28) | **none.** `scripts/library.blb` and `.config/beets/` were fenced and deleted on 2026-09-13 (plan 04-11) |
| Destination | `/media` → `/mnt/tank/media`, **`:ro`** | n/a |

**Why the sabnzbd config is kept rather than deleted (D-11).** Restoring stock `setup.bash`
re-downloads a beets config with `scrub.auto`, `lastgenre.auto` and `embedart.auto` all defaulting
to **yes**, against a 34 GB library with no `undo`. A vendored, `:ro`, defused config is cheaper
than trusting that nobody ever reverts. `audio.bash` is vendored `:ro` for the same reason — it is
the file upstream re-downloads, and re-downloading it silently restores the beets invocation.

> The file at `/mnt/fast/appdata/arrs/beets/config/config.yaml` **used to be** a copy of the compose
> service definition rather than a beets config — no `plugins:`, no `library:`, no `directory:` key
> anywhere in it. It was replaced on 2026-09-11 (D-27) by the vendored file above, which declares
> `plugins: musicbrainz` explicitly. Since beets 2.4.0 MusicBrainz is itself a plugin, and a
> customised `plugins:` list that omits it silently disables all autotagging — see § *Phase 4* for
> the measurement that turned that from inference into a number.

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

> **⛔ DO NOT RUN THAT SECOND LINE. Historic quotation, kept verbatim as the Nov-2025 record
> (note added 2026-09-21, Phase 6 D-04).** It is what the header comment said then, which is why
> it is not rewritten. It is also now forbidden: one `library.db` is mounted into two beets
> versions (D-03) — the CLI arm is 2.13.1, beets-flask executes 2.12.0 — so a bare `beet` here
> opens that database and **migrates its schema under 2.12.0's feet**. Every CLI-arm invocation
> must carry **both** a throwaway `-l` and a `-c` overlay, because `-l` alone does not redirect
> `statefile:`. The human import path is beets-flask's UI. Asserted by
> `scripts/quick-health-check.sh` § *D-04*, which scopes `*.md` out of its assertion for exactly
> this reason and counts documentation hits against a pinned baseline instead.

---

## Two config gaps that will bite a bulk run

> **Corrected 2026-09-13 (plan 04-13, D-07).** The config this section was written against —
> `soulbeet/beets_config.yaml` — was **deleted** with the soulbeet definition on 2026-09-11. It is
> named below only as the thing that was measured. **The two gaps themselves still stand**, and
> they are now advice for whoever configures the survivor: the vendored `arrs/beets/config.yaml`
> is deliberately minimal (D-27 — `plugins: musicbrainz`, an explicit `library:`, and the three
> SAFE-01 `auto: no` keys, nothing else), so neither gap is closed there either. **Phase 6 owns
> closing them.** Do not read the code blocks below as describing a file that exists today.

The deleted `soulbeet/beets_config.yaml` was otherwise sane — sensible `paths`, `scrub`,
`fetchart`, strict-ish `strong_rec_thresh: 0.04`. Two things were missing, and they map exactly
onto the two known problem classes.

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

> **⛔ As written, that command is forbidden from Phase 6 onward** (note added 2026-09-21, Phase 6
> D-04). It is the 2026-08-17 triage sketch and is kept verbatim for the `-A --flat` reasoning,
> which still stands. What does not stand is running it bare: add a throwaway `-l` **and** a `-c`
> overlay naming `library`, `statefile` and `directory`, or drive the import from beets-flask's UI.
> Same mechanism as the note above.

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

### Correction: the wrtag pin's stated cause was reversed (2026-09-11, Phase 4 D-14)

This page's advice was written while the repo pinned wrtag below v0.30.0 behind a Renovate rule.
**That rule's stated evidence was wrong, and wrong in a way that reversed cause and effect.** It
blamed three path-format fields for a v0.30.0 break; **two of them — `.Release.Date.Year` and
`.Release.Media` — are present at v0.20.0** and render without complaint. The rule is paraphrased
here deliberately and never quoted, so its reversed wording cannot be reproduced in a new place.

**The two real defects, both at v0.20.0:**

1. It **forces `d.Track.Position = -1`** (`pathformat/pathformat.go:113-115`), so every single-disc
   track renders `-1 - `. `grep -c "Track.Position = -1"` returns 1 at v0.20.0 and 0 at both
   v0.33.0 and v0.34.0.
2. **`.Media` is absent from v0.20.0's `Data` struct**, so `.Media.Position` is a template execute
   error — but only on multi-disc releases, because Go evaluates `{{ if }}` bodies lazily. That is
   also why startup validation never caught it: v0.20.0's `validate()` constructs single-medium
   synthetic releases only.

**The finding, verbatim from Phase 3:**

> *this repository's `WRTAG_PATH_FORMAT` works on none of v0.20.0, v0.33.0 or v0.34.0 — it renders
> `-1 - ` on every single-disc track and hard-errors on multi-disc at v0.20.0, and is refused at
> startup by both current tags — and the sole cause of the startup refusal is the `Disc N/`
> **subdirectory**, proven by an ablation that changes nothing else and validates at both current
> tags.*

**Unpinning buys nothing.** The obvious reading — "the pin was inverted, so lift it" — is a trap,
and the answer was measured rather than argued:

| Question | Answer, measured (three image tags, plan 03-08) |
|---|---|
| Would this repo deploy wrtag at any version? | **No.** wrtag lost the Phase 3 engine decision and Phase 4 deletes it. There is no version to deploy |
| Does unpinning to v0.33.0 fix the path format? | **No.** v0.33.0 **refuses the format at startup**, exit 2, `ambiguous format: multiple directories created for the same release`, before a file is read |
| Does v0.34.0 differ from v0.33.0 on this? | **No — it is a path-format no-op**, on three instruments: byte-identical refusal text, byte-identical rendered path sets under the ablation, and a changelog whose only breaking change is a Go version bump |

The full measurement, including both `Data` struct listings and the field-by-field table against
what the rule claimed, is
[`03-WRTAG-EVIDENCE.md`](../../../.planning/phases/03-tagger-spike/03-WRTAG-EVIDENCE.md)
§ *The corrected pin-inversion proof*. The rule itself was deleted by plan 04-03; nothing in this
repo now instructs anyone to keep, fix or unpin wrtag.

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

> **Dismissed by the operator 2026-09-06, Phase 4 D-24.** The rotation described below is **not**
> going to happen, and that is a decision rather than a lapse. The operator's words, verbatim:
> *"Discogs token rotation is not important at all, there is nothing there that has any value, i
> am not concerned"*.
>
> This is recorded as **a choice, not an oversight or a silence**, so that a future security review
> meets a reasoned answer rather than an open action nobody ever closed. **No rotation step is
> taken by Phase 4, and no plan in it spends a step on the token.** The original text is left
> standing below in full: the four causes it records were correct against what they measured, and
> they remain the right briefing for anyone who revisits the decision. The dismissal is recorded in
> its estate-wide form in `.planning/PROJECT.md` § *Key Decisions*, and the full record stays at
> `.planning/phases/03-tagger-spike/deferred-items.md` `DEF-03-21`.

**Rotate the Discogs personal access token at project close.** It is not a Phase 3 task — the
operator decided the timing, was shown the full picture at the closing gate on 2026-09-04 and
reaffirmed it — but the reasons have accumulated to **four independent causes**, and the action
goes forward carrying all four so that whoever executes it is not acting on the one-cause problem
`DEF-03-04` opened:

1. It was written to a `644` file by a logging path nobody expected —
   `python3-discogs-client` puts the token in the **query string**, not an `Authorization`
   header, so anything that logs request lines is a credential sink.
2. It was written to disk a second time by an ad-hoc verification command.
3. It was **passed as a command-line argument**, and so was world-readable via
   `/proc/<pid>/cmdline` for ~45 minutes on a host running 100+ containers — then rendered a
   second time by a `pgrep -af` that printed the argv back. *Never pass a secret as a command-line
   argument, on any host, even to a command that prints only a count.*
4. It was rendered into agent transcripts that cannot be shredded.

**What is and is not clean, stated precisely** (see `.planning/phases/03-tagger-spike/deferred-items.md`
`DEF-03-21` for the full record):

- **The estate is clean.** Every copy **on the estate** — `/mnt/fast/spike-03` and the generated
  runtime beets config — was removed and verified gone at Phase 3 close.
  `/mnt/fast/secrets/discogs.env` is the **single remaining estate copy**, at `600 root`.
- **This repository is provably clean.** Every commit was screened by the token's **value** *and*
  by its **8-character prefix**: **0 hits**, verified independently.
- **Four plaintext copies survive on the operator's workstation.** They are local and
  unpublished — agent session artefacts on his own machine, none in any repository and none
  pushed — but **three of the four are append-only session transcripts that cannot be reliably
  scrubbed**, and the fourth (a 131,433-byte tool-results cache) had its deletion refused by
  policy from inside the session.

**Rotation, not deletion, is therefore the effective remedy.** Rotating makes every surviving copy
inert regardless of how many there are; deleting what *can* be deleted lowers the count while
leaving the credential live. **This repository is public** — credentials go in `/mnt/fast/secrets/`
and `~/.claude/secrets/`, referenced by variable name only, and never in a process argument.

---

## Phase 4 — closed 2026-09-18: criterion 3 discharged by a signed override, not by a byte proof

**Phase 4 is NOT closed, and this section is deliberately not headed as a closure.** Four of the
phase's five success criteria are measured and hold. The fifth — criterion 3, *"a real music job
completes with no tagger"* — is recorded **OPEN after two observation windows**. Quoted from
`.planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md`, which carries exactly one verdict
line per window — § 6 for window 1, § 7 for window 2. The current verdict is window 2's:

> *Verdict (window 2): OPEN — three music jobs completed in the window and every side-effect
> condition and both ends of the § 3 prerequisite held, but none of the three published a PRE-HOOK
> snapshot, so all three are STATUS=UNPROVEN reason=no-attributed-pre with a zero-file intersection:
> under direct_unpack two of them never exposed a single audio file to a 1-second poll of the
> incomplete tree and the third was still growing when SABnzbd moved it, its one hash attempt
> refused mid-pass, so the "untagged by bytes" condition of § 1 item 4 is UNPROVEN and § 5 requires
> OPEN rather than PASS.*

Window 1's verdict stands beside it, unrevised in the light of anything window 2 produced. It is
kept because it is the record of *why* the first attempt could not close the criterion, which is the
more durable half of that window:

> *Verdict: OPEN — two music jobs completed in the window and every other pass condition held, but
> neither job has a valid PRE-HOOK snapshot: job A's was taken after its `Matching` line and job B's
> cannot be ordered against its own, so the "untagged by bytes" condition of § 1 item 4 is UNPROVEN
> and § 5 requires OPEN rather than PASS.*

**Nothing failed.** OPEN is not FAIL: a FAIL needs a violated condition and there is none. The
condition could not be *evaluated*, for a reason that is a defect in the instrument and not in the
estate. SABnzbd moves a finished job into `/downloads/complete/nzb/music/` and **then** invokes the
post-processing hook, so a watcher pointed at that destination tree can never sample a job before
the hook has started — its earliest possible sighting is after the fact. Measured on the two real
jobs of 2026-09-13: the hook's first log line preceded the watcher's first sighting of the folder in
both cases, and one job ran hook-start to completion in **one second**, against an evidence contract
that requires a *stable* snapshot (two agreeing passes ≥ 2 s apart).

**What has happened since, recorded in band and dated 2026-09-14.** The first of the two fixes that
paragraph named was built. Plan **04-14** moved the PRE-HOOK snapshot into `/downloads/incomplete/`,
which is structurally before SABnzbd's move and therefore before the hook — so the ordering no longer
depends on comparing a millisecond watcher clock against a second-resolution log — and self-tested it
against **eight** synthetic controls before it was allowed near a real job. Plan **04-15** then ran a
**second** observation window, 2026-09-13T22:04:18Z → 22:27:08Z, over **three** real music jobs. Its
verdict is the one quoted at the top of this section: **still OPEN, and for a new reason.** None of
the three published a PRE-HOOK snapshot at all. Under SABnzbd's `direct_unpack`, two of them never
exposed a single audio file to a one-second poll of the incomplete tree, and the third was still
growing when SABnzbd moved it, so the watcher **refused** its one hash pass mid-pass rather than
publish a snapshot that had straddled the move. That is the instrument failing **safe**, exactly as
designed: UNPROVEN, never a false FAIL.

**OPEN means the instrument could not look. It does not mean the estate is dirty.** The estate side
is now measured clean for the third window running, across five real music jobs in total: no
`library.blb`, no `library.blb*` backup, no `beets.log`, no new `.bak`, **zero** `SUCCESS: Matched
with beets` lines, and `extended.conf` provably never written during the window. Window 2 also
recorded the **positive control** the question needed — when a folder genuinely rests under
`incomplete/`, the watcher publishes, and publishes complete. What is unproven is the estate's
behaviour at the one moment the criterion asks about; the watcher works as specified.

**What is still needed**, named so a later reader meets a decision rather than a silence: a capture
point that survives `direct_unpack`. The bytes must be sampled somewhere a job cannot skip past in
three seconds, which rules out both the destination tree (window 1's dead end) and a poll of the
incomplete tree (window 2's). **The estate still needs nothing changed** — every remaining obstacle
is in the measuring instrument, and nothing further can be measured with the current one. Until then
criterion 3 keeps its static half verified (`grep -cE '^[[:space:]]*beet ' audio.bash` → **0**, with
the vendored-drift guard green) and its behavioural half **OPEN**.

The narrative — every plan, its measurements and its deviations — is in
`.planning/phases/04-collapse-to-one-tagger/`.

> **Closed 2026-09-18 (quick task 260918-byj).** Everything above stays as the record of what was
> known on 2026-09-14. It is **not retracted** — every word of it about windows 1 and 2 still holds,
> and the instrument really could not look. What has changed is the *disposition*, not the evidence.
>
> Criterion 3 is now **closed by a signed override, not by a byte proof.** The operator signed it in
> `.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md`'s frontmatter on 2026-09-18,
> accepting the threefold unanimous side-effect evidence — 5 real music jobs across 2 observation
> windows, 0 `library.blb`, 0 `beets.log`, 0 new `.bak`, 0 `SUCCESS: Matched with beets`, and
> `extended.conf` provably never written — in place of the PRE-HOOK/COMPLETION byte comparison the
> criterion's own evidence contract asks for.
>
> A **third** capture design was built after the section above was written: SABnzbd's own `pp`
> notification hook, built and self-tested in plan **04-17** with **all 14 synthetic controls
> passing** — and **never armed**. The paragraph above asking for "a capture point that survives
> `direct_unpack`" was answered in design and then deliberately left unused.
>
> **Window 3 was abandoned, not lost.** External review of plan 04-18 — the plan that would have
> armed the hook — by **four independent AI model families** found roughly **30 defects** in it,
> including an **unverified judge that self-reported every PASS condition**, an OPEN branch that
> could swallow a FAIL, and a restore contract that was count-checked rather than diffed (and so
> could have left the estate re-armed). A PASS from that instrument would not have been
> trustworthy, which is the entire reason for running it, so the window was closed **unrun** rather
> than run for the appearance of measurement. The reviews are preserved verbatim at
> `.planning/phases/04-collapse-to-one-tagger/04-18-EXTERNAL-REVIEWS.md`.
>
> **The residual risk, in one sentence:** "no evidence of tagging" is not identical to
> "proven absence of tagging at the byte level".
>
> **The estate was never changed by any of this** — `nscript_enable` stayed 0 and `direct_unpack`
> stayed 1 throughout.

### The census, executed

From `bash scripts/check-music-freeze.sh` on LXC 100, 2026-09-13T12:37:32Z, ANSI stripped,
otherwise unedited. A **routine** run: no environment variables were set, because plan 04-11
promoted the census out of its candidate gate into the standing check, so these lines must appear
unprompted. The run exited **0** with zero `❌`, against host HEAD `90581f3`.

```
📊 7. Summary
  tagger definitions:          1   (target 1)
  beets databases:             1   (target 1 = SURVIVOR_DB)
  tagger databases:            0   (target 0 — wrtag.db*/soulbeet.db*)
  retired paths present:       0   (target 0)
  rw on Music, non-tagger:     0   (target 0, excluding the D-21 consumer exception)
  rw on Music, tagger-capable: 0   (target 0 — Phase 1 D-20, any container state)
  rw on Music, Jellyfin D-21:  1   (documented consumer exception, printed separately)
  tagger-capable containers:   2   (mounts a beets/wrtag/soulbeet config or DB; reported)
  FAILURES total:              0
```

**`tagger-capable containers: 2` is the expected value, not a defect.** The two are `sabnzbd`
(it mounts the defused `beets-config.yaml`, and holds **no** `/mnt/tank/media` mount at any mode)
and `lidarr` (matched by the renamer clause, holding `/mnt/tank/media:ro`). Neither holds `rw` on
Music and neither fails anything — that is what the `rw on Music, tagger-capable: 0` line above
asserts. Jellyfin is printed on its own line because it is the documented D-21 consumer exception;
counting it into a bare total would make "exactly one rw holder" read as a pass for the wrong
reason.

### The five criteria

| Criterion | Evidence | Where |
|---|---|---|
| **1 — one tagger definition** | `git ls-files stacks \| xargs grep -lE "^[[:space:]]*image:[[:space:]]*[\"']?([a-z0-9._-]+/)*(beets-flask\|beets\|wrtag\|soulbeet\|picard)([:@\"'[:space:]]\|$)"` resolved to exactly `stacks/selfhosted/arrs/beets/beets.yaml` — **the same pattern `scripts/check-music-freeze.sh:824` asserts on** (`:793` when this row was written), quoted verbatim so the two cannot drift; the census counted `tagger definitions: 1` from the repo itself. Issue **#306 closed** with the D-26 evidence. ⚠️ **The RESOLUTION is superseded — the PATTERN is not.** See § *Phase 6 → D-11* below | 04-03, 04-07, re-quoted 2026-09-14, resolution superseded 2026-09-21 |
| **2 — Renovate config valid** | `renovate-config-validator --strict --no-global renovate.json5` → exit **0** (re-run 2026-09-13 at the pinned 44.80.0); negative control, a copy with `"automerg": false`, → exit **1** naming the misspelled key | 04-03, re-run 04-13 |
| **3 — a real music job completes with no tagger** | **`window 2: OPEN`** — quoted verbatim above. Three real jobs ran in the second window and none published a PRE-HOOK snapshot under `direct_unpack`, so the byte proof is UNPROVEN rather than violated; window 1's two jobs likewise ran clean with the byte proof untakeable | 04-12, 04-14, 04-15, `04-D12-EVIDENCE.md` |
| **4 — every beets config declares `musicbrainz`** | Same album, same throwaway `-l`, two configs differing by exactly one line: live broken `plugins: embedart` → **0** MusicBrainz candidates; fixed → **1** (12 of 12 tracks, distance 0.048), cross-read by hand at **95.2%**. Both live configs now declare `musicbrainz` | 04-09, 04-11 |
| **5 — one database, no idle `rw` holder** | The executed census above | 04-11, this section |

> **Closed 2026-09-18 — row 3's disposition, superseded.** Row 3's verdict token above is left
> deliberately standing, and is deliberately the only place in this file that carries it: it
> remains the accurate record of the **byte** evidence, and nothing has been measured since that
> would change it. What changed is the disposition — criterion 3 is now
> **closed by the signed override** in
> `.planning/phases/04-collapse-to-one-tagger/04-VERIFICATION.md`, not by a byte proof. The third
> capture design (plan 04-17's `pp` notification hook, all 14 synthetic controls passing) was
> **never armed**, and window 3 was closed unrun — see
> `.planning/phases/04-collapse-to-one-tagger/04-18-EXTERNAL-REVIEWS.md`.

### What keeps these true

Two standing guards, both promoted by plan 04-11 into the **fatal** routine path in the same commit
as the runs that turned them green, then each driven red through that routine path to prove it can
still fail:

- **`scripts/check-music-freeze.sh` § 6b** (`TAGGER_CENSUS_PROMOTED=1`) — asserts every counter
  above. A resurrected tagger, a reappearing retired database, or any container in **any** state
  taking `rw` on Music fails it.
- **`scripts/quick-health-check.sh`'s vendored-file drift block** (`VENDORED_DRIFT_PROMOTED=1`) —
  asserts the three vendored files (`audio.bash`, sabnzbd `beets-config.yaml`, survivor
  `config.yaml`) are byte-identical on the host and in the repo. Upstream `setup.bash` re-downloads
  two of them on every sabnzbd boot; this is what notices.

`scripts/quick-health-check.sh` folds in the first and runs the second. Routine run 2026-09-13T12:39:12Z:
**exit 0**, zero `⚠️`, and one `❌` — `Traefik dashboard: Not accessible`.

> **Superseded 2026-09-14 (code review WR-09).** That `❌` was report-only when this was written,
> and *that was the defect*: the Traefik, Authelia and dashboard probes each printed a red glyph
> without touching `EXIT_CODE`, so the estate's single health-check entry point reported **exit 0**
> with a failure sitting in its own transcript. All three now set `EXIT_CODE=1`, and each
> distinguishes "not running" from "could not look". **A run in this state now exits 1, not 0** —
> so the figures quoted above are a record of the old behaviour, not a target to reproduce. The
> underlying dashboard `❌` itself still pre-dates this phase and is still unfixed; it is now
> visible in the exit code instead of only in the transcript.

> **Corrected 2026-09-15 (quick task 260915-k9p).** That `❌` was **never an estate fault**, so the
> block above is wrong to call it unfixed — it was the *probe* that was broken. The probe asked for
> `/dashboard/` over plain HTTP on port 8080 of LXC 100's loopback, and `traefik.yaml` has never
> published that port on the host (`docker port traefik` returns exactly 80, 443, 3023 and 3024).
> `curl` exit 7 was therefore the **correct answer to a question the configuration never made** —
> a permanent red that WR-09 promoted into a permanent exit 1 on a healthy estate. The `:8080`
> entrypoint is nonetheless load-bearing for `--metrics.prometheus.entrypoint=traefik`
> container-internally and was left alone; **nothing about the estate was changed.** The probe now
> asserts the real serving chain — `https://traefik.deercrest.info/dashboard/` on the `websecure`
> entrypoint, pinned to loopback with `--resolve`, expecting the `chain-authelia@file` redirect —
> and an unauthenticated `200` is now its own violation, which the old probe could never detect.
> **A healthy routine run has no `❌` at all.** Measured 2026-09-15T13:50:24Z: **exit 0**, zero
> `❌`, zero `⚠️`, 96 containers running, dashboard line
> `✅ Protected (HTTP 302 → Authelia)`. Those are the current figures; the 2026-09-13 ones above
> are a record of the old probe, not a target to reproduce.

### Recorded, not fixed

Real, out of Phase 4's scope, and written down rather than silently carried:

- **The estate-wide `-lsNNN` Renovate silence (F9).** Every other LinuxServer image in the estate
  has the same versioning gap D-30 fixed for the survivor. Deferred by the D-30 ruling.
- **`pip install -U beets` on every sabnzbd boot.** `scripts_init.bash` still does it, and it ran
  during the 04-11 recreate. Nothing invokes beets after the strip. Phase 8 (INGS-01) owns the
  hook's eventual shape.
- **The baseline `Exit(1): chmod …` on every music job (D-31).** `audio.bash:334` runs
  `chmod 777 "$1"`, which fails `EPERM` on `tank`, and the hook's global `set -e` ends it at 1. Every
  music job has recorded this since at least 2026-08-01. **Baseline, not regression.** Not fixed here.
- **`Music/__`** — ~1.4 GB accidentally imported into beets' default `directory` on 2025-11-18,
  deliberately untouched. Phase 6.
- **The census's `tagger definitions: 1` expectation must be revised when beets-flask lands.**
  Phase 5 stands it up; a second legitimate definition will fail this counter until the target is
  changed with it.
  > **Discharged 2026-09-21 (Phase 6, plan 06-10, D-11).** The pre-flag is kept visible rather than
  > deleted, because it is the record of a guard that did its job: plan 06-04 landed
  > `stacks/selfhosted/arrs/beets/flask.yaml` on 2026-09-20, the counter went red on the next run,
  > and nobody had to notice it by eye. The expectation is now **two definitions, asserted by name
  > and by class**, and the pattern was **not** narrowed to make the count fit. Full record in
  > § *Phase 6 → D-11* below.
- **The "beets has no `undo` command" constraint is narrower than it reads, and two files still
  state it unqualified.** It remains true of the beets **CLI**, but beets-flask rc6 has a working
  `UNDO IMPORT`, verified by use (see § *One correction to this page's own § The recovery fence*).
  `CLAUDE.md` and `.planning/PROJECT.md` both still carry the bare claim — grep either for
  ``beets has no `undo` command``, one hit each. *(This pair was cited by line number until plan
  06-28 replaced it with the anchor under GC-04. One of the two had already rotted and the other
  had not, which is exactly why spot-checking one of a pair does not clear the pair; see
  `artifacts/06-28-citations-and-counts.txt`.)* Phase 4 was
  expected to amend them and **no plan in it did**; neither file is in this plan's mandate. Deferred
  in writing as **DEF-04-01**, in
  `.planning/phases/04-collapse-to-one-tagger/deferred-items.md`, to **Phase 7**, which owns the
  "undo exercised" criterion and now has two candidate mechanisms rather than one.

### `Replaygain Tagging: ENABLED` in `Audio.txt` is not what it looks like

Recorded here because it will mislead the next reader of a job log. That string is a **hardcoded
literal at `audio.bash:86`**, inside `if [ "${ConversionFormat}" = FLAC ]` — it never consults
`ReplaygainTagging`. The real gate is line **325**, `if [ "${ReplaygainTagging}" = TRUE ]`, a
case-sensitive test against the bare word `TRUE` that `"false"` cannot satisfy. Corroborated
independently on the 2026-09-13 jobs: **0 `REPLAYGAIN_*` / `R128_*` keys across all 25 files**.
`replaygain()` did not run.

## Phase 5 — closed 2026-09-19: all four criteria TRUE, re-measured at close rather than restated

There is now a staging tree outside the library where the routing decision **is** a directory name,
the junk that would have corrupted every later measurement is gone rather than parked, and the 45 GB
`Now!` monolith is 115 independently abortable volumes. The narrative — every plan, its measurements
and its deviations — is in `.planning/phases/05-inbox-structure-and-the-junk-gate/`.

**Every verdict below was measured again at phase close**, after the sweep, the split, the tag write
and the chown, into
`host:/mnt/fast/safety/phase05/phase05-final-assertions.txt` (committed copy:
`.planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-11-final-assertions.txt`). A
closure written from plan summaries records what was *intended*; these are quoted from that artifact,
not paraphrased from the plans. **OPEN is not FAIL — a FAIL needs a violated condition, and there is
none.**

### The four criteria

| # | Criterion | Verdict at close | Made true by |
|---|---|---|---|
| 1 | `_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}` under `tank/downloads`, nothing equivalent under `media/`, and a move between two of them is an atomic same-dataset rename verified by unchanged inode | **TRUE** | 05-01 |
| 2 | Zero `_FAILED_` / `_UNPACK_` / stray `.rar` outside `99-quarantine`, across the **five music paths** — *as amended 2026-09-18 by plan 05-02 under D-12/D-14/D-15* | **TRUE against the amendment** | 05-03, 05-04 |
| 3 | The `Now!` monolith split per volume, each independently importable and abortable, counts reconciling — *as amended 2026-09-18 by plan 05-02 under D-02/D-05/D-08, and as decided by the operator on 115-folders-merged and short-volumes-split-anyway* | **TRUE against the amendment** | 05-05, 05-06, 05-07, 05-09 |
| 4 | No `_`-prefixed folder anywhere under `/mnt/tank/media/Music` | **TRUE, and now ASSERTED rather than claimed** | 05-02 |

**Criterion 1**, quoted from the assertions file:

> `POSITIVE-BEFORE (70, 295296)` … `POSITIVE-AFTER  (70, 295296)` … `NEGATIVE-BEFORE (70, 295296)`
> … `NEGATIVE-AFTER  (43, 128)`

Six directories present; `_inbox` on devid 70 with `unsorted/` and `dj-mixes/`; zero ZFS datasets
named `_inbox`; zero equivalents under `/mnt/tank/media` to depth 3. The inode proof was **driven
again at close**, after the chown, with both controls — the property is unchanged by ownership
normalisation, and the instrument has again been seen both holding and breaking.

**Criterion 2.** `0` `_FAILED_`/`_UNPACK_` directories and `0` `.rar`-form files across
`complete/nzb/{music,unsorted,dj-mixes,_inbox}` outside `99-quarantine`. The exclusion is not
vacuous: the same `find` without it returns the two quarantined Garth Brooks directories, so the
instrument is demonstrably able to see this shape. `/mnt/tank/downloads/lidarr-import` is **absent** —
Phase 1's D-23 closed here rather than being handed to Phase 8. The named Harry Potter rip is absent.
The sweep itself: **52 candidates enumerated, 44 approved with two operator amendments — 40 removed,
4 moved, 8 `.covers` directories struck from the list untouched** — with every removed and renamed
path on the dataset attributed to an approved row by `zfs diff`, zero unexplained.

**Criterion 3**, quoted from the assertions file:

> `depth-1 directories: 115` · `names are exactly Vol 001 .. Vol 115: True` ·
> `depth-2 directories: 0` · `mp3 inside the volume folders: 4,746` ·
> `mp3 left at the collection root: 0` · `ffprobe failures: 0` ·
> `volumes NOT carrying exactly one album value: 0` ·
> `MANIFEST-ONLY ENTRIES (manifest leaves with no file on disk): 0`

The `files == sum over discs of the modal tracktotal` exception set measured **11 rows** and matched
the pre-declared post-merge list — volumes 3, 4, 8, 9, 15, 18, 39, 52, 70, 83, 98 — **11 for 11,
zero differences to name.** The `+13 / +9 / +13` on volumes 4, 8 and 9 are **merged folders whose
expectation is not meaningful**, never "extra files appeared"; see *Recorded, not fixed* below.

**Criterion 4 was already green before Phase 5 started.** What Phase 5 changed is what kind of thing
it is: an unasserted green *claim* became an *asserted* one, in
`scripts/quick-health-check.sh`, with "could not look" kept distinct from "there are none". Its own
verdict line at close:

> `Library underscore-dir guard: ✅ No '_'-prefixed directories under /mnt/tank/media/Music`

D-22 requires the assertion **before and after** this phase's moves. The before half ran in plan
05-02 on **2026-09-18**, together with the **driven negative control** that makes the green
credible: a `_probe` directory created inside the library from atlantis as real root, the check
observed red with it and green without it, the probe independently tripping
`check-music-freeze.sh`'s ownership assertion as a second instrument sharing no code with the
first, and an `EXIT` trap confirming the probe gone. The control is deliberately **not** re-driven
here — creating a probe inside the library at phase close would be gratuitous.

> ⚠ **Read criterion 4 from the BLOCK's verdict line, never from the script's exit code.**
> `bash scripts/quick-health-check.sh` exits **1** today for a pre-existing reason unrelated to this
> phase: `check-music-freeze.sh`'s `interpolated-host-path inventory MOVED: expected=12, found=13`,
> a deliberate human-review gate on a compose change Phase 5 did not make. It is the only red line
> in the run. **The whole-script exit code is therefore non-discriminating for criterion 4.**

### What keeps these true

The standing mechanisms, as distinct from the one-off actions that produced today's state:

- **The criterion-4 assertion in `scripts/quick-health-check.sh`** — the seventh fatal block, added
  by plan 05-02 and driven red on real library state before it was trusted. An underscore-prefixed
  directory appearing under `/mnt/tank/media/Music` now fails the estate's single health-check entry
  point instead of being discovered when Music Assistant and Jellyfin quietly disagree about the
  library's contents.
- **The two approval-gated scripts**, which leave the rules written down for Phase 8's new inflow
  rather than in somebody's head: `scripts/phase05-junk-sweep.sh` defines what "junk" means for this
  estate in eight greppable rules, and `scripts/phase05-downloads-chown.sh` defines the ownership
  normalisation. Both refuse to act without an operator-approved file on disk and a snapshot proof —
  two processes joined by a file, because a branch can be skipped and a missing file cannot.
- **D-18's prohibition on `_inbox` ever becoming its own ZFS dataset.** This is what keeps criterion
  1's atomic-rename property alive, and it is written down precisely because it looks like an
  obstacle to an improvement. See the traps below.
- **D-25's prohibition**, in the other direction: **no `tank/downloads` ownership assertion is added
  to the health check.** Confirmed held at close —
  `grep -v '^[[:space:]]*#' scripts/quick-health-check.sh | grep -c 'tank/downloads.*568'` returns
  **0**. The download client keeps writing as uid 3000 at roughly one job per 72 s, so such a check
  would go red on the next download and train everyone to ignore it. D-24's sweep is a one-time,
  `zfs diff`-verified measurement; **its date is the deliverable, not a standing check.**

### Traps that will mislead the next person

**1. Do NOT parse a trailing number off the `album` tag on the `Now!` collection (D-03).** Volume 36
is split across three spellings, and two of them end in a digit that is not its volume number:

```
Now That's What I Call Music! Vol.36 CD1     16 files
Now That's What I Call Music! Vol.36  CD2    20 files   <- NOTE THE DOUBLE SPACE
Now That's What I Call Music! 36              4 files
```

`…Vol.36 CD1` ends in `1` and `…Vol.36  CD2` ends in `2`, so a trailing-number regex **exits 0,
looks right, and silently misfiles 36 tracks into volumes 1 and 2.** Volume 1 is tagged
`Now That's What I Call Music` with **no number at all**, and volume 2 is
`Now, That's What I Call Music II` — a **Roman numeral, and a comma**. Grouping is by the m3u
manifest's volume directory, cross-checked against the `album` tag through an explicit alias table;
**96 values spell it `Music!` and 21 spell it `Music`**.

**2. `_inbox` must never become a ZFS dataset (D-18), and that will look like a tidy improvement.**
A dataset gets you a quota and independent snapshots — exactly what `fast/transcode` got in Phase
02.1. It would also put `_inbox` on a different devid from `unsorted/` and `dj-mixes/`, turning
every move into staging from `rename(2)` into copy-then-unlink: slow, interruptible, needing
transient double space, and **destroying criterion 1's property outright.** Note that
`tank/downloads` is no longer a single-dataset subtree — `tank/downloads/icloud-export` exists — so
the check is "no dataset named `_inbox`", not "no child datasets".

**3. Never read ownership from LXC 100.** It is unprivileged with a sparse idmap, so an unmapped
on-disk id surfaces as `65534` or `root`, and several distinct on-disk ids collapse to one
container-side reading. Plan 05-09's summary recorded the 115 `Vol NNN` directories as `root:root`;
on disk they were `100000:100000`. **Verify from atlantis.** (At close they are `568:568`, and
`find <collection> ! -uid 568 -o ! -gid 568` returns 0 — LXC 100 agrees here only because 568 *is*
inside its idmap, which is a coincidence of the value, not a reason to trust the view.) This is the
same defect class as Phase 1's `apps:nogroup` reading.

**4. A `stat` manifest keyed on path/size/mtime CANNOT SEE A CHOWN.** `chown` moves `ctime`, not
`mtime`, so an "untouched" verdict from such a manifest is vacuous against exactly the operation
plan 05-10 performed. 05-10 used `zfs diff` against a fresh baseline instead, which returned
`M 26005` with zero `+`, `-` or `R` lines.

**5. `zfs diff` collapses renamed-and-modified into a single `R` line.** A "nothing was modified"
check expressed as *zero `M` lines* over files that were **renamed** is therefore **vacuous** — it
returns the same answer whether 751 files were written or none. This invalidated one of plan 05-08's
evidence lines and one of the closure's own spot-checks, and 05-09 replaced the instrument rather
than editing around it.

**6. `ffprobe` takes ONE input file.** A batched call — several paths on one command line — exits
clean and produces nothing for all but the first. A loop that collects no records and reports no
failures looks exactly like a clean tree.

**7. ZFS devids are NOT stable, and there is a three-way inode collision on this estate.**
`tank/downloads` / `tank/media/Music` read **68/76** on 2026-09-18, **70/75** earlier on 2026-09-19
and **70/81** at close. The *property* (staging shares a devid with the content that moves into it;
the library does not) holds; the *numbers* do not — **never write an assertion on `devid == 68`.**
And `/mnt/tank/downloads`, `/mnt/tank/media/Music` and `/mnt/fast` **all report inode 34**: inode
numbers are unique only within a filesystem, so **always assert the pair `(devid, inode)`, never the
inode alone.**

**8. Run ONE whole-tree pass over `tank` at a time.** Atlantis **rebooted under memory pressure**
during plan 05-09 when two ran concurrently. Check load, free memory and whether an import is
running before starting a second.

**9. Content moved into `_inbox` is NOT chowned per move (D-26).** A rename preserves ownership, and
adding a privileged `chown` to every move would contradict the atomic-rename property the whole
design rests on. **Staging carries mixed ownership by design.** Never write an "everything under
`_inbox` is `568:568`" assertion — D-25 guarantees it would drift. The six directories *themselves*
are `568:568`; their contents are not.

**10. `-iname '*potter*'` is no longer a valid test for the misfiled BluRay rip.** Found during this
closure: the 05-07 split moved
`Vol 066/21. The Proclaimers Featuring Brian Potter (2) & Andy Pipkin - I'm Gonna Be (500 Miles)…mp3`
into a depth-2 folder where a depth-3 sweep now reaches it, so the obvious re-run returns **1 hit
that is a legitimate song**. **Assert the named path.** Separately,
`incomplete/Harry.Potter…hallowed` still exists and is **out of scope by D-15** — `incomplete/` is
SABnzbd's live working directory and moving anything under it can break an active download.

### Recorded, not fixed

- **Volumes 4, 8 and 9's `tracktotal` surplus is a GROUPING ARTEFACT, and the diagnosis is the
  deliverable — the repair is Phase 6's (D-10 declined it).** It was settled three independent ways
  and then a fourth. (a) Grouping on the **manifest directory** instead of the album tag makes the
  `+13/+9/+14` vanish entirely: the album string cannot tell three separate 1984–1987 *editions*
  apart. (b) The surplus **reproduces exactly** under the old grouping before vanishing under the
  new one — 45 / 42 / 44 files under both instruments, zero disagreement about which file belongs to
  which family. (c) The operator's decision to **merge** the variant editions into one folder per
  volume re-creates the surplus arithmetically, which is why `Vol 004` reports `+13` at close: the
  folder holds the union of three editions while the modal expectation can carry only one edition's
  `tracktotal`. (d) The **encoded bitstream** settles it: 4,735 distinct `audio_md5` across 4,746
  records, and **9 of the 11 duplicate groups sit entirely inside `Vol 004`** — the same recording
  under two track numbers, which is what a three-edition merge looks like from underneath.
- **The missing tracks are located, named track by track, and not chased.** 13 tracks across 10
  (volume, disc) groups, in `artifacts/05-06-missing-tracks.tsv`. **Only 5 are missing audio** from
  the source rip (volumes 18, 52, 70, 83, 98); 4 are one physical file being placed once rather than
  twice by the cross-volume tie-break, and 4 are volume 8's per-disc imbalance. **Re-acquisition is
  not scoped by this project.** None of these volumes went to `04-hold` (D-09): an incomplete `Now!`
  volume is a compilation, not a broken album, and is still importable.
- **Every track in this collection carries a per-file `LOCATION=https://www.discogs.com/…/release/NNNNNN`
  tag — a direct Discogs release id.** Discogs is the source Phase 3 chose. This is potentially a
  large shortcut for **Phase 6's CONF-05 disambiguation** and is **recorded, not acted on**: D-10
  scoped the tag write to `album` alone.
- **The rest of the `Now!` tag surface** — `artist`, `title`, the BPM-in-title convention, and the
  `comment=YearmixFreak 2023` / `encoded_by=djdezzie` rip artefacts. Phase 6.
- **`dropbox/` is 84% of the download dataset and is not downloads** — 196,327 entries of personal
  code and documents, inside the `rw` bind of **nine** containers, excluded from the chown by
  operator decision. Whoever next revises `stacks/selfhosted/arrs/` owns narrowing those binds.
- **`takeout-import.service` on LXC 100 passes an Immich API key on the command line**, so it is
  readable in `ps` host-wide. The value is deliberately not recorded — **this repo is public.**
  Rotate the key and move it out of `ExecStart` in the same change.

### Still open

- **`_done/` pruning mechanics at backlog scale (D-19).** The policy is fixed — `_done/` holds the
  **whole source folder**, not a receipt, it costs no extra space because reaching it is a rename,
  and it is pruned **deliberately, per release, only after CONS-04 passes in both consumers and
  never on a timer**. What is unbuilt is the *mechanics* at volume, and **Phase 9's batch cadence
  makes that operationally real.**
- **`dj-mixes`'s 84 inconsistent top-level names** — `Mastermix_Issue_410` beside
  `Mastermix_Issue_410.1`, `Mastermix.Issue.420.2021` in a different separator style, eight ending in
  a truncated bare `_-`, and `Now!` compilations (`__118__`, `__119__`) inside a folder named for
  Mastermix. Carried to Phase 6's matching work.
- **`mac-music-archive/` — 23,874 music entries nobody has counted.** Last written 2024-10-27.
  **Its ownership was normalised; its content was deliberately not characterised** — not its formats,
  not whether it duplicates the 34 GB library or the `unsorted/` backlog, not whether it is tagged.
  It is **not** in `PROJECT.md`'s 144-folder backlog denominator, and if it is in scope that
  denominator is wrong. A **next-milestone scoping question**, not an execution one.
- **`check-music-freeze.sh`'s `interpolated-host-path inventory MOVED: expected=12, found=13`.**
  Pre-existing, unrelated to Phase 5, and the reason `quick-health-check.sh` exits 1 today. The
  remedy is the one the failure text states: **read the new line by hand and move
  `DECLARED_INTERP_EXPECTED` in the same commit** — not bump the number.
- **The `_inbox` tree is no longer empty**, so `05-INBOX-PATHS.md`'s "all six exist, are empty" line
  describes the day it was written, not today. At close: `02-review` holds **533 audio files**
  (`Madonna`, `Michael Jackson`), `99-quarantine` holds **44 FLAC** in the two spared Garth Brooks
  `_FAILED_` directories (1.92 GB), and the other four are empty.

### How to re-run

Delivery is **git**: a commit must reach `origin` before LXC 100 can `git pull --ff-only` in
`/mnt/fast/stacks`. Nothing else copies these scripts to the host.

```bash
ssh root@172.16.1.159
cd /mnt/fast/stacks && git pull --ff-only

# The junk gate — two processes joined by a file on disk.
bash scripts/phase05-junk-sweep.sh enumerate   # READ-ONLY. Writes the candidate list. Always exits 0.
#   <<< OPERATOR READS THE LIST AND DELETES THE ROWS THEY DO NOT APPROVE >>>
#   A SEVENTH tab field on a row names a destination and means MOVE, not REMOVE.
bash scripts/phase05-junk-sweep.sh sweep       # MUTATES. Acts on exactly what survived.

# The Now! split — the same shape.
bash scripts/phase05-now-split.sh plan         # READ-ONLY. Emits the src->dst mapping. Moves nothing.
bash scripts/phase05-now-split.sh apply        # Acts from the APPROVED mapping. Refuses without it.

# Ownership normalisation.
bash scripts/phase05-downloads-chown.sh enumerate   # READ-ONLY survey -> the row list.
bash scripts/phase05-downloads-chown.sh apply       # MUTATES. Runs the chown from atlantis.

# The read-only inventory behind criterion 3, and the closure's independent re-scan.
bash scripts/phase05-now-tag-inventory.sh scan
bash scripts/phase05-now-tag-inventory.sh reconcile
```

**Both destructive subcommands refuse to start without (a) an operator-approved file on disk and
(b) a proof that `tank/downloads@pre-phase5` exists.** Those refusals are the first statements in
each acting subcommand, so they are reachable from a workstation with no access to `tank` at all.
`chown` runs **from atlantis**, never from LXC 100, where it fails `EPERM` on every entry. Never
`chmod` on `tank`: it fails `EPERM` even as real root under `aclmode=restricted` +
`aclinherit=passthrough`.

### Rollback

The fence is **`tank/downloads@pre-phase5`**, taken 2026-09-18 15:42, verified still present at
close. **It is the only undo for 05-07's 4,750 renames, 05-09's 751 in-place tag writes and 05-10's
26,005 chowns** — beets has no `undo`, and none of those three operations kept a copy. **Do not
destroy it before Phase 6 has signed off.** Plan 05-10's own baselines,
`tank/downloads@pre-phase5-chown` and `tank/media/Music@pre-phase5-chown` (both 2026-09-19), are
retained beside it as that plan's evidence.

**It is not a clean undo, and must not be described as one.** A `zfs rollback` to it discards
**everything** written to `tank/downloads` since it was taken, indiscriminately:

- the junk sweep — the 40 removed items come **back**, including a 1080p BluRay rip in a music
  folder, and `lidarr-import` returns with them;
- the split — the 115 `Vol NNN` folders vanish and the collection is a 4,746-file flat monolith
  again;
- the album write — all 751 files revert to their pre-canonical `album` strings, including volume
  36's three spellings;
- the chown — 26,005 entries go back to `0:0`, `3000:545`, `100000:100000` and the rest;
- **and every byte downloaded into `tank/downloads` since 2026-09-18 15:42, by every service that
  writes there.** That is unrelated content belonging to other people's workflows: roughly a day and
  a half of it at the moment of writing, and a month's worth by the time anyone is likely to reach
  for this.

A rollback is therefore an **estate-wide** decision, not a music-project one. If only part of Phase
5 needs reverting, mount the snapshot read-only and copy back the specific paths —
`/mnt/tank/downloads/.zfs/snapshot/pre-phase5/…` — rather than rolling the dataset.

## Phase 6 — tagger configuration and dry run (2026-09-20)

### D-34: `PreferNonstandardArtistsTag` was ENABLED on Jellyfin's Music library

**This is live-service state that git does not hold.** It lives in Jellyfin's own configuration
database on LXC 100, nowhere in this repository, and it is one UI click from reverting with every
gate in this estate still green. That is why it is written here and **asserted** in
`scripts/check-music-consumers.sh` § 4 — see "the assertion" below.

| | |
|---|---|
| **What** | Jellyfin library option `PreferNonstandardArtistsTag` |
| **Which library** | **Music** only — `ItemId 7e64e319657a9516ec78490da03edccb`, `Locations ["/media/Music"]`. Movies and TV are untouched. |
| **Before** | `false` |
| **After** | `true` |
| **When** | 2026-09-20, plan 06-03 task 2, `POST /Library/VirtualFolders/LibraryOptions` -> HTTP 204 |
| **Jellyfin** | 10.11.11 |

**Why.** beets writes multi-artist information as a **multi-valued `ARTISTS` tag** (`TXXX:ARTISTS`
on MP3, `ARTISTS` on Vorbis) — and it **cannot be configured to emit `;` inside `ARTIST`**: there
is no write-delimiter or join key anywhere in `config_default.yaml` at 2.12.0 or 2.13.1, and
`item.artist` is MusicBrainz's own join phrases verbatim. Music Assistant already **prefers** the
`ARTISTS` tag and splits it on `;` (`TAG_SPLITTER = ";"`). With `PreferNonstandardArtistsTag`
false, Jellyfin **ignored** the one tag the pipeline actually produces. Enabling it makes the two
consumers agree **by construction rather than by coincidence**, which is what CONF-04 is really
asking for.

**`UseCustomTagDelimiters` was deliberately NOT enabled, and must not be.** `;` is already present
in `CustomTagDelimiters` — the switch is off, not the delimiter — but `/`, `|` and `\` are in that
same list and `DelimiterWhitelist` is empty, so switching it on splits on all four across 1,244
files. **`AC/DC` is the canonical casualty.** Narrowing the list and populating the whitelist first
would be the only safe route, and it buys nothing the `ARTISTS` tag does not already give.

### The finding that matters more than the change

**Enabling this option does NOT retroactively re-parse the existing library, and the only
mechanism that would is forbidden here.**

`PreferNonstandardArtistsTag` is a **probe-time** option: it changes what `AudioFileProber` does
the next time it runs on a file. A targeted `POST /Library/Media/Updated` produces a **Default**-mode
refresh, and a Default-mode refresh does not re-run the prober on a file whose mtime has not
changed. Measured twice on 2026-09-20 — once with the three album directories in the update body,
once with the three individual track files — with the `LibraryMonitor` confirming by name in the
log that it refreshed all six items. **Zero of 1,244 census rows changed: not a count, not a name,
not an Id.**

The refresh mode that *would* re-probe is the aggressive per-item one Phase 1 measured rewriting
**83 of 91 `.nfo` files with `SaveLocalMetadata` already off**. It is forbidden in this estate and
was not issued. So the evidence for CONF-04's Jellyfin half arrives when a file is **written or
newly imported** — i.e. Phase 7 — which is also the case the project's core value is about.
Before/after transcripts:
`.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-03-jellyfin-artist-{before,after}.txt`.

**The Phase 1 freeze survived the write, asserted field by field after it, by name:**
`SaveLocalMetadata=false`, `EnableRealtimeMonitor=false`, `SaveLyricsWithMedia=false`,
`MetadataSavers=["Nfo"]` (still armed behind the gate). The write was a read-modify-write over the
complete options object and **exactly one field differed** — that endpoint is a full-object
replace, the same hazard this estate already paid for once on `/System/Configuration/encoding`.

### The sequel to that finding: mechanism (b) was DRIVEN on 2026-09-24, and it does not work

*Gap-closure round 5, plans 06-40 … 06-45. The section above is the dated record of what was true
on 2026-09-20 and is deliberately NOT rewritten; this is the correction beside it, which is the
convention this page uses throughout.*

The section above names two ways the evidence for CONF-04's Jellyfin half could arrive, and says it
arrives "when a file is **written or newly imported** — i.e. Phase 7". One of those mechanisms —
**(b) the file's mtime changing** — needs no write of content at all. On 2026-09-24 the operator
chose to pull exactly that lever, inside Phase 6, rather than argue about it for another phase.

**It did not work. That is the result, and it is a measurement rather than an unknown.**

#### The mechanism, in enough detail to repeat

1. **Three files**, and only three — the pinned rows of `ARTIST_PROOF_ROWS` in
   `scripts/check-music-consumers.sh`, with the touch list **derived from that script by prefix
   substitution and never retyped**, against a copy whose sha256 was asserted before parsing:
   - `Lady Gaga/ARTPOP (2013)/CD 01-05 Lady Gaga - Jewels n’ Drugs.flac`
   - `Katy Perry/Teenage Dream (2010)/CD 01-03 Katy Perry - California Gurls.flac`
   - `P!nk/The Truth About Love (2012)/CD 01-04 P!nk - Just Give Me a Reason.flac`
2. **A ZFS snapshot taken in the SAME remote step as the mutation**, so the fence and the change
   could not come apart: `zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe`, listed back and
   asserted equal **before any file was touched**.
3. **`touch` from atlantis as real root** — never from LXC 100, whose sparse idmap distorts
   ownership. The permission was probed first with its own no-op form (`touch -r f f`, the same
   `utimensat` with no change) on all three, so an `EPERM` would have been a recorded negative and
   a stop, rather than a discovery mid-mutation.
4. **The same targeted Default-mode `POST /Library/Media/Updated` at file scope**, body built by
   `jq` from the derived list so nothing was hand-escaped. HTTP **204**. This was the **only write
   verb issued by the entire round**.
5. **A settle well past the floor**: ≥120 s required, **19,597 s** actually elapsed, computed as a
   subtraction between two recorded epochs rather than asserted in a sentence.

#### The controls that prove nothing was written into the library

- **`zfs diff` against the fence** — the round's strongest control, and it is one instrument
  carrying both halves of the safety claim: **three `M` entries, zero non-`M`, exactly three
  distinct paths and all three pinned, zero `.nfo`/`.lrc`/`.jpg` sidecar entries**. Re-taken after
  the refresh it is **byte-identical** to the post-touch capture (`cmp -s`, sha256 equal both
  sides), so across the POST, the `LibraryMonitor` firing and five and a half hours of live estate,
  ZFS records not one additional change under `tank/media/Music`.
- **A `.nfo` hash manifest**: all **91** files differ on **0** lines in sha256 *and* mtime, and all
  three sidecar set fingerprints (91 `.nfo` / 944 `.lrc` / 88 `.jpg`) are identical to the
  before-state. The dataset is `atime=off` / `relatime=on`, so a read cannot contaminate the diff.
- **Content hashes**: all three pinned files' sha256 values are unchanged at unchanged sizes. Three
  mtimes moved; not one byte of audio did.
- **The six `P!nk/TRUSTFALL (2023)` DO-NOT-RESCAN rows were EXCLUDED from the touch list and
  verified unchanged** in count and entity-Id set — the negative control held, and the touch list's
  `TRUSTFALL` substring count was asserted **0** before the mutation, twice.

#### The numbers, per row

| Row | Target | Baseline (2026-09-20) | Measured (2026-09-24) | `;` in any entity name | Verdict |
|---|---|---|---|---|---|
| `Jewels n’ Drugs` | 4 | 0 | **0** | 0 | AT-BASELINE |
| `California Gurls` | 2 | 1 | **1** | 0 | AT-BASELINE |
| `Just Give Me a Reason` | 2 | 1 | **1** | 0 | AT-BASELINE |

**Zero of three rows moved**, and the 1,244-row census delta is **empty**.

#### Why this is a measurement and not a "could not look"

Jellyfin's own `LibraryMonitor` named **all three Audio items by full internal path**, U+2019
included, 60 s after the POST returned — matching `LibraryMonitorDelay = 60` exactly. So "the
refresh never started" is ruled out. And `PreferNonstandardArtistsTag` re-read **`true`**
afterwards, so the option did not revert. The refresh ran, reached the items, and **the prober did
not re-read the `ARTISTS` tag**. Mechanism (b) is **disproven for this estate at Jellyfin 10.11.11**.

⛔ **Nothing was escalated, and the fence above is untouched.** No second refresh was issued, no
wider refresh mode was used, no further file was touched, and no `zfs rollback` was executed. The
aggressive per-item refresh mode — the one Phase 1 measured rewriting 83 of 91 `.nfo` with
`SaveLocalMetadata` already off — **remains forbidden, was not issued, and was unreachable from
every branch of the round**. If you are reading this at 3 a.m. because a row is still at baseline:
the answer is not a bigger refresh.

#### What is still held

**`tank/media/Music@pre-06-41-conf04-reprobe` is STILL HELD and has not been released.** It is the
only undo for the round's three mtime writes, its release is a **separate operator decision**, and
nothing schedules its destruction. It costs essentially nothing — the round changed 0 bytes of
content and `tank` has ~9 T free. Separately, `tank/downloads@pre-phase5` is also still held as
Phase 5's only undo.

#### And the rule that survives all of it

**The Jellyfin and the Music Assistant verdicts are separate and must never be summed into one
CONF-04 answer.** The MA half stays discharged; the Jellyfin half stays OPEN, now carried to Phase 7
entry criterion **E6** under the operator's explicit `negative-carry-e6` override — an auditable
carry of an open requirement, **not a close**. `scripts/check-music-consumers.sh` **still exits 3**,
and that is correct: `MA_ARTIST_PENDING` is 1 because MA returns three artists against row 1's
four-value `ARTISTS` tag, a *reported measured discrepancy* owned by E6's **second** measurement.
The audit would have exited 3 on a fully successful Jellyfin re-probe too — **so an exit code, and
any "N of M pending" figure, is never a CONF-04 completion signal.**

Transcripts:
`.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-4{0,1,2,3}-*.txt`.

### The assertion

`scripts/check-music-consumers.sh` § 4 now reads `GET /Library/VirtualFolders` — nothing else in
this repository did — and asserts four fields on the Music library by name, each its own red:
`PreferNonstandardArtistsTag == true`, `UseCustomTagDelimiters == false`,
`SaveLocalMetadata == false`, `EnableRealtimeMonitor == false`. It also carries the D-22
artist-entity check: per pinned row it asserts the browseable **`ArtistItems` entity list** (not
the flat `Artists` string list, which reads green on rows that have no entities at all), requires
the Ids to be distinct, and goes **red immediately if any entity Name contains a `;`** — one
artist literally called `A;B` is the precise failure D-22 exists to distinguish from success.

### D-11: the tagger census expects TWO definitions, named and classed (2026-09-21, plan 06-10)

**The guard fired, and that is the headline.** Phase 4 wrote the `tagger definitions: 1`
expectation with `beets-flask` deliberately already inside the match pattern, so that a Phase 5/6
definition would go **red** rather than arrive unnoticed. Plan 06-04 landed
`stacks/selfhosted/arrs/beets/flask.yaml` on 2026-09-20 and the counter failed on the next run.
Nothing was discovered by eye.

**The pattern is unchanged, byte for byte.** Narrowing it — dropping `beets-flask` from the
alternation — would have made `tagger definitions: 1` true again and disarmed the exact mechanism
that just worked. It is quoted here in a fenced block rather than a table cell so the pipes need no
escaping and a mechanical `grep` can prove this page and `scripts/check-music-freeze.sh:824` have
not drifted:

```
^[[:space:]]*image:[[:space:]]*["']?([a-z0-9._-]+/)*(beets-flask|beets|wrtag|soulbeet|picard)([:@"'[:space:]]|$)
```

**What changed is the expected SET, not the count.** The census asserts membership, so a count of
two whose members are different files is a **red**, and a third unnamed definition still fails:

| Definition | Class | Image |
|---|---|---|
| `stacks/selfhosted/arrs/beets/flask.yaml` | **ACTIVE front end** — the human arm, the inbox watchdog, the thing that executes `config.yaml` | `metasauce/beets-flask:v2.0.0-rc6`, engine **beets 2.12.0** |
| `stacks/selfhosted/arrs/beets/beets.yaml` | **DORMANT agent-driven CLI arm** — `restart: "no"`, `profiles: ["manual"]`, out of `compose.yaml`'s include list | `lscr.io/linuxserver/beets:2.13.1-ls349` |

**Evidence — a runnable command, and what it must print.** This is the criteria-table evidence cell
for criterion 1 from Phase 6 onward; the Phase 4 row above records what it printed then:

```bash
ssh root@172.16.1.159 'cd /mnt/fast/stacks && bash scripts/check-music-freeze.sh' \
  | grep 'tagger definitions'
```

```
  ✅ tagger definitions: expected=2 — found exactly the named pair:
         stacks/selfhosted/arrs/beets/flask.yaml — ACTIVE front end — metasauce/beets-flask:v2.0.0-rc6, engine beets 2.12.0
         stacks/selfhosted/arrs/beets/beets.yaml — DORMANT agent-driven CLI arm — lscr.io/linuxserver/beets:2.13.1-ls349
  tagger definitions:          2   (target 2 — the NAMED pair, not a count; D-11)
  tagger definitions, active:  stacks/selfhosted/arrs/beets/flask.yaml   (ACTIVE front end — metasauce/beets-flask:v2.0.0-rc6, engine beets 2.12.0)
  tagger definitions, dormant: stacks/selfhosted/arrs/beets/beets.yaml   (DORMANT agent-driven CLI arm — lscr.io/linuxserver/beets:2.13.1-ls349)
```

**Both class lines repeat the `tagger definitions` token on purpose.**
`scripts/quick-health-check.sh`'s fold-in selects the harness summary with a `grep -E` over ten
label tokens, and a line without one of them is dropped from that transcript **silently**. The
label token `tagger definitions` is therefore unchanged and the new lines carry it — renaming it
would break a consumer in a different file, which is the coupling that has broken once already
(WR-09).

### CONF-04 — the verdict, as TWO verdicts that must never be summed (2026-09-21, plan 06-13)

D-22 asks for "N distinct browseable artist entities in **each** consumer, checked separately".
The two consumers are at **different points**, and averaging them into one tick would hide the
half that is not done. So the row carries both, and the overall verdict is the *weaker* of them.

| | **Jellyfin 10.11.11** | **Music Assistant 2.11.0b2** |
|---|---|---|
| Field read | `ARTISTS` (via `PreferNonstandardArtistsTag=true`) | `ARTISTS` (native preference, `TAG_SPLITTER=";"`) |
| `California Gurls` (target 2) | **0 of 2** — not re-probed | ✅ **2 of 2** — `Katy Perry \| Snoop Dogg`, item_ids 73, 244 |
| `Just Give Me a Reason` (target 2) | **1 of 2** — not re-probed | ✅ **2 of 2** — `P!nk \| Nate Ruess`, item_ids 63, 201 |
| `Jewels n' Drugs` (target 4) | **0 of 4** — not re-probed | ⚠ **3 of 4** — `T.I. \| Lady GaGa \| Too $hort`, item_ids 159, 209, 217 |
| Verdict | **OPEN** — probe-time option, 0 of 1,244 rows moved | **Parsing PROVEN; one row a measured discrepancy** |
| Discharges when | Phase 7 first writes or imports a multi-artist release | — (already read fresh through the export) |

**What is actually proven, stated plainly.** Both consumers now read the **same field** — `ARTISTS`
— **by construction rather than by coincidence**: beets cannot be configured to emit `;` inside
`ARTIST` (no write-delimiter key exists at 2.12.0 or 2.13.1), MA prefers `ARTISTS` natively, and
D-34 pointed Jellyfin at the same tag. The `;` in the requirement text is a property of **this
library's twelve existing files**, not of anything the pipeline will produce.

**MA's parsing is proven, not inferred, and the proof does not rest on arity.** Every artist MA
returns is a distinct library entity with its own `item_id` and a browseable `library://artist/N`
uri, and **no artist name anywhere contains a `;`** — one artist called `A;B` being the precise
failure D-22 exists to distinguish from success. A1 and A2 were both resolved first:

- **A2 — CONFIRMED** against `GET /api-docs/commands.json` on the live server, which is the
  script's own stated authority. `music/tracks/library_items` exists among the 311 declared
  commands, returns `Array of Track` (a bare array — **not** `.result`-wrapped), the `Track`
  schema declares an `artists` property, and it accepts `provider` by instance id. A call that
  merely succeeded was **not** accepted as the resolution.
- **A2's side effect, worth more than A2 itself:** `music/albums/count` declares **only**
  `favorite_only` and `album_types`. It has **no `provider` parameter at all** — so the argument
  is not "silently ignored" by a filter that declines to apply, it is a parameter that does not
  exist, and the integer it returns counts the whole library **including Spotify**. Never cite it.
- **A1 — CONFIRMED** on the running 2.11.0b2, behaviourally rather than from source (there is no
  SSH route from this estate to the add-on's installed `tags.py`). Rows 2 and 3 each carry a
  **single-name `Artist` tag** and a two-name `ARTISTS` tag, and MA returns both names as distinct
  entities — the second name exists in no other tag on the file, so `ARTISTS` was read and split
  on `;`. `MA_VERSION_PROVEN` moved `2.11.0b0` -> `2.11.0b2` in the same commit as that proof.
- **The `mb_id_count == 1` caveat was measured, not waved.** Row 1 carries **four**
  `MUSICBRAINZ_ARTISTID` values, rows 2 and 3 **two** each. **Not one row carries a single id**, so
  the short-circuit cannot fire on any of them and all three are valid tests of the splitter.
- **A trap the plan did not anticipate, checked and cleared.** `library_items` takes a `summary`
  parameter defaulting to **true** ("slim summary items containing only the fields needed for a
  list view"). Read at both settings, the artists arrays are identical in length, names, item_ids
  and uris — the slim shape does **not** truncate `artists[]`, so the check is not reading a stub.

**Row 1 is characterised, not dropped.** `Jewels n' Drugs` tags `ARTISTS = "Lady Gaga;T.I.;Too
$hort;Twista"` and MA returns three. Two candidate causes are **ruled out by measurement**: the
`;` delimiter (rows 2 and 3 prove the splitter works on this exact build) and the `mb_id_count`
short-circuit (four ids — it would have returned **1**, not 3). The loss is located at MA's
**artist-entity stage**: `Twista` exists nowhere among MA's 66 library artists under any
`/wista/i` spelling, and `Lady GaGa` is a **pre-existing entity** whose display name came from the
`ARTIST` tag, which is why the spelling differs from `ARTISTS`. **Left open honestly:** MA's
artists-per-track distribution is 1,220 at 1, 22 at 2, 2 at 3 and **none above 3**, and this file
is the library's **only** 4-value tag — so "MA caps the list at 3" and "Twista specifically failed
to map" are both consistent with the evidence and **cannot be told apart from a sample of one**.
Phase 7's first >=4-artist track is the measurement that discriminates.

**Nothing was written to get any of this.** `LC_ALL=C find` manifests over the three proof albums
(88 entries; path, size and mtime) are **identical before and after**, and the comparison was
proved able to see a planted difference. D-21's fenced `rw` grant never fired and **MA holds no
phantom** — which matters precisely because MA never purges stale entries (D-25).

**Evidence — runnable:**

```bash
ssh root@172.16.1.159 'cd /mnt/fast/stacks && bash scripts/check-music-consumers.sh' \
  | grep 'CONF-04'
```

Full transcript:
`.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-13-ma-artist-entities.txt`.

### Two standing risks this criterion leaves behind

- **Every `%aunique{}` firing is a known MA risk to verify in Phase 7.** MA's
  `missing_album_artist_action: folder_name` fires only when the album **folder** and the album
  **tag** agree, and **silently falls back to `Various Artists` when they do not** — while
  `config/providers/get` still reads back `folder_name`, so the setting looks correct either way.
  An `%aunique{}` firing makes folder and tag differ **by construction**, so each one on plan
  06-11's list is a candidate for that silent fallback. Dropping the disambiguator is not the
  answer: Phase 1 measured 828 duplicate groups / 19.4% duplication, so removing it trades a
  *detectable* MA fallback for *silent* path collisions.
- **The D-34 library option is live-service state that git does not capture.** It lives in
  Jellyfin's configuration database on LXC 100 and nowhere in this repository. Its **only**
  protection is the by-name assertion in `scripts/check-music-consumers.sh` § 4
  (`PreferNonstandardArtistsTag == true`). If that assertion is ever removed or narrowed, a single
  UI click reverts the option with every gate in this estate still green — and CONF-04's Jellyfin
  half would then be resting on a setting nobody is checking. **Name that dependency before
  touching § 4.**

### Still open

- **CONF-04 is OPEN overall, on its Jellyfin half, and is a NAMED PHASE 7 ENTRY BLOCKER.** The
  option is set; the three pinned `ARTISTS` proof rows still read their pre-change entity counts
  (0, 1, 1 against a target of 4, 2, 2) because nothing has re-probed them. It is neither "could
  not look" nor "nothing is wrong" — **do not record it as green.** It discharges when Phase 7
  writes or imports a multi-artist release, which is also the first moment the project's core
  value is exercised. *(Re-confirmed 2026-09-21 by plan 06-13: the MA half is done and the
  Jellyfin half is unchanged. The two halves are recorded separately in the CONF-04 verdict above
  and **must not be summed** — an averaged tick would hide exactly the half that is not done.)*
- **Two things Phase 7 must measure the first time it writes a multi-artist release**, both
  carried from the CONF-04 verdict above rather than left as notes: whether Jellyfin's re-probe
  produces 4/2/2 entities, and whether a **second >=4-artist track** gets four artists in MA or
  three — the measurement that finally separates "MA caps at 3" from "Twista specifically failed
  to map".
- **An operator decision was left untaken, deliberately.** Obtaining that proof *today* would mean
  a one-off aggressive refresh on three albums, whose cost is their `.nfo` rewritten inside a phase
  whose premise is that it writes nothing. The default is not to, and that is what plan 06-03 did.
- **Music Assistant came back up mid-plan, and its half is mostly GREEN.** Research recorded MA
  and Home Assistant on `172.16.1.31` as both down for maintenance; by the time 06-03 ran the
  assertion, MA answered. Two of the three pinned rows read **exactly at target**:
  `California Gurls` -> `Katy Perry | Snoop Dogg`, `Just Give Me a Reason` -> `P!nk | Nate Ruess`.
  MA prefers the `ARTISTS` tag and splits it on `;` natively, exactly as the source read said.
  > **Closed 2026-09-21 by plan 06-13**, which re-probed first (ICMP 3/3, `:8095` and `:8123` both
  > open, MA `/info` serving `2.11.0b2`) and ran the read-back under the D-36 operator gate. The MA
  > half is recorded in the CONF-04 verdict above. **CONF-04 as a whole stays OPEN on its Jellyfin
  > half** — the two are not summed.
- **One MA row is a measured discrepancy, and it is not the same thing as the Jellyfin pending
  rows.** `Jewels n' Drugs` carries `ARTISTS = "Lady Gaga;T.I.;Too $hort;Twista"` — four values —
  and MA returns **three**: `T.I. | Lady GaGa | Too $hort`. `Twista` is absent, and the spelling
  returned is `Lady GaGa` (capital G), which is the **`ARTIST`** tag's spelling, not the `ARTISTS`
  tag's. MA read this file fresh through the export, so "not yet re-probed" does not explain it.
  Two leads before blaming the delimiter: MA's `mb_id_count == 1` short-circuit, and whether the
  names are being taken from `ARTIST` rather than `ARTISTS`. The check reports it every run
  against a pinned baseline rather than either passing it or going permanently red.
  > **Both leads were closed on 2026-09-21 by plan 06-13, and neither was the cause.** The
  > `mb_id_count` lead is dead: the file carries **four** MusicBrainz artist ids, and the
  > short-circuit fires only at exactly one — it would have returned 1 artist, not 3. The
  > `ARTIST`-instead-of-`ARTISTS` lead is dead as a *parsing* explanation: rows 2 and 3 prove MA
  > reads and splits `ARTISTS` on this build. What survives is narrower and is recorded in the
  > CONF-04 verdict above — `Twista` is absent from MA's **artist-entity** table entirely, and
  > `Lady GaGa` is a pre-existing entity named from the `ARTIST` tag, which explains the spelling
  > but not the missing fourth. Cap-at-3 vs Twista-specifically is **undecidable on one sample**
  > and is carried into Phase 7.
- **MA normalises artist ORDER.** The tag reads `Nate Ruess;P!nk`; MA returns `P!nk | Nate Ruess`.
  Only the SET is meaningful on the MA side. The order **is** still a meaningful tell in Jellyfin.
- ~~**Research assumption A2 is empirically confirmed but still not confirmed against the
  authority.**~~ **CLOSED 2026-09-21 by plan 06-13 — A2 CONFIRMED** against
  `GET /api-docs/commands.json`. See the CONF-04 verdict above: the command exists, returns
  `Array of Track`, the `Track` schema declares `artists`, and `provider` is a declared parameter.
  The same read upgraded the `music/albums/count` warning from anecdote to schema fact — that
  command declares **no `provider` parameter at all**.
- ~~**MA version drift: live `2.11.0b2`, `MA_VERSION_PROVEN` is `2.11.0b0`.**~~ **CLOSED
  2026-09-21 by plan 06-13.** The constant moved to `2.11.0b2` **in the same commit** as the
  re-proof of A1 and A2 against that build, which is what the instruction asked for — the number
  was not bumped on its own. `auto_update` remains ON by operator choice (D-56), so this banner
  will warn again on the next build and the same discipline applies: re-prove, then move.
- **30 of the 1,244 library items have zero `ArtistItems`** while still carrying a non-empty
  `Artists` string list — all of `Lady Gaga/ARTPOP (2013)` (15), all of `Lady Gaga/Joanne (2016)`
  (14), and one Def Leppard track. Their `Artists` reads `["Lady GaGa"]`, with a capital G that
  matches no artist entity. Unexplained; left alone; it is why the pinned Lady Gaga row's baseline
  is 0 and not 1.
- **Six `ARTIST`-delimited `P!nk/TRUSTFALL (2023)` tracks are marked DO NOT RESCAN** (OQ-1). They
  already read as 2/2/2/3/2/2 distinct entities with distinct Ids despite `UseCustomTagDelimiters`
  being false — almost certainly stale DB state from a pre-10.10 prober, and the only live evidence
  in this estate of Jellyfin presenting multiple browseable artists for one track. They were
  excluded from every scan body and are unchanged. The finding above also explains why they were
  never at risk: nothing re-probes them either.

## Phase 6 closed 2026-09-21 — four criteria TRUE, one OPEN on a named half, all five RE-MEASURED at close

The configuration that will import is asserted against the object that will actually do the
importing, the intended tree is a committed fact rather than an intention, and **not one byte was
written to the library or to the backlog in the whole phase**. The narrative — every plan, its
measurements and its deviations — is in
`.planning/phases/06-tagger-configuration-and-dry-run/`.

**Every verdict below was measured AGAIN at close, from live state, on 2026-09-21 between 22:04Z
and 22:07Z.** A closure written from plan summaries records what was true on the day each plan ran;
this one quotes instruments run at sign-off. Where a verdict rests on a driven experiment that
cannot be re-driven cheaply — the oracle's 174-file import, the two-arm incremental control, the
country-preference overlays — the *instrument* was re-exercised at close (`--self-test`, exit 0)
and the *result* is cited to its committed artifact by name. **OPEN is not FAIL.** A FAIL needs a
violated condition; there is none in this phase.

### The five criteria

| # | Criterion (ROADMAP text, abbreviated) | Verdict at close | Evidence — runnable, quoted verbatim | Plan |
|---|---|---|---|---|
| 1 | Effective config shows imports **copying**, not moving | **TRUE** | `bash scripts/check-beets-config.sh` → exit 0, `FAILURES total: 0`; `✅ CONF-01 import.copy = true` and `✅ CONF-01 import.move = false`, both read from `CONFIG_ROUTE=server-committed` — arm 1, the object that will actually import | 06-01, 06-07 |
| 2 | `incremental: yes` **with** `incremental_skip_later: yes` | **TRUE, and proven to FIRE** | `bash scripts/check-beets-config.sh` → `✅ CONF-02 import.incremental = true` / `✅ CONF-02 import.incremental_skip_later = true` (arm 1); and `bash scripts/phase06-incremental-control.sh --arm a` vs `--arm b`, two overlays **one key apart**, opposite outcomes | 06-07, 06-08 |
| 3 | A run on a bucket-A sample prints top levels equal to `ALBUMARTIST` exactly, case included; `Various Artists/` appears and `Compilations/` does not | **TRUE** | `bash scripts/phase06-oracle.sh --run` → exit 0, **zero lines of difference** against `06-EXPECTED-TREE.txt` over 174 destinations; class assertion § 7.1 CONF-03 **0 mismatches, 0 could-not-compare**, § 7.2 **0** `Compilations` path components against a 44-row `Various Artists` positive control | 06-05, 06-09, 06-11 |
| 4 | A multi-artist track shows its artists parsed correctly in **both** Jellyfin and Music Assistant | **TWO VERDICTS, NEVER SUMMED.** Jellyfin **OPEN**; Music Assistant **PROVEN, one row a measured discrepancy** | `bash scripts/check-music-consumers.sh` (on LXC 100) → § 4's four by-name library-option assertions and the D-22 per-row `ArtistItems` entity check. Re-measured directly at close through the same two APIs — see the table below | 06-02, 06-03, 06-13 |
| 5 | Match disambiguation **demonstrated**, not merely set, with the run confirmed to have written nothing | **TRUE** | `bash scripts/check-beets-config.sh` → `✅ CONF-05 match.preferred.countries contains GB — ["GB","US"]`, `carries no UK entry`, `original_year = true`, `musicbrainz.extra_tags … 5 entries`; driven by overlays **K/L one key apart** choosing a *different* rank-0 release; wrote-nothing by the three-layer D-29 proof in `bash scripts/phase06-oracle.sh --run` | 06-01, 06-07, 06-11, 06-12 |

Requirement ids, so the table and `REQUIREMENTS.md` cannot drift: criterion 1 is **CONF-01**,
criterion 2 is **CONF-02**, criterion 3 is **CONF-03** (its instrument is **CONF-06**), criterion 4
is **CONF-04**, criterion 5 is **CONF-05**.

#### What was re-run at close, and what it printed

`bash scripts/check-beets-config.sh`, 2026-09-21T22:04Z from the workstation, **exit 0**:

```
  arm 1 blind:                 0   (1 = nothing below section 4 was measured)
  arm-1 assertion failures:    0
  FAILURES total:              0
  D-29 before:                 fbbdde0c… /config/library.db  f6a9a1ad… /config/state.pickle
  D-29 after:                  fbbdde0c… /config/library.db  f6a9a1ad… /config/state.pickle
```

Twenty-three assertions green, including the positive control that proves the dump really is the
server-committed object (`gui.num_preview_workers=4`, `gui.terminal.start_path=/repo` — rc6 schema
keys the CLI view cannot see). `arm 1 blind: 0` is the line that makes the rest meaningful: a run
that could not read arm 1 would have printed `1` and asserted nothing.

`bash scripts/phase06-oracle.sh --self-test` and
`bash scripts/phase06-incremental-control.sh --self-test`, both re-run at close, both **exit 0** —
every fail-closed branch, every refusal and every could-not-look case behaved as expected. The
judges still judge; they were not re-run against live content because doing so would import, and
this phase's premise is that it does not.

`06-EXPECTED-TREE.txt` is still at **commit `cb9f49a`** — the commit that landed it *before* the
run it judges (D-27) — sha256 `37b2083eef14b936081495dcc6e80123528054fadbc4187d060e0d8d5a8430f0`,
351 lines. A fixture edited after the run it judges proves nothing, so its provenance is asserted
rather than assumed.

#### Criterion 4, re-measured at close — the two halves, side by side

Both consumers were read directly at close, read-only, through their own APIs. **The two rows are
never averaged into one verdict**: the overall verdict is the weaker of them.

| Pinned row (target N) | Jellyfin 10.11.11, 22:06:03Z | Music Assistant 2.11.0b2, 22:06:38Z |
|---|---|---|
| `Jewels n' Drugs` (4) | **0 of 4** — `ArtistItems` empty; `Artists` string list reads `Lady GaGa` | **3 of 4** — `T.I. \| Lady GaGa \| Too $hort`, item_ids 159, 209, 217 |
| `California Gurls` (2) | **1 of 2** — `Katy Perry` | **2 of 2** — `Katy Perry \| Snoop Dogg`, item_ids 73, 244 |
| `Just Give Me a Reason` (2) | **1 of 2** — `P!nk` | **2 of 2** — `P!nk \| Nate Ruess`, item_ids 63, 201 |
| Verdict | **OPEN** — every row still at its pre-change baseline (0, 1, 1) | **Parsing PROVEN**; row 1 a measured discrepancy, not a pending state |

The Jellyfin library option itself is **still set**, read from `GET /Library/VirtualFolders` at
close: `PreferNonstandardArtistsTag=true`, `UseCustomTagDelimiters=false`, `SaveLocalMetadata=false`,
`EnableRealtimeMonitor=false`. So the OPEN is not drift — it is the probe-time property recorded
above: the option changes what the prober does *next time it runs*, and nothing has re-probed these
files. **Zero of 1,244 census rows moved.**

MA's side was read with its own controls in band: 1,244 tracks returned from the pinned local
provider, artists-per-track distribution **1,220 at one / 22 at two / 2 at three / none above
three**, no artist name anywhere containing a `;`, and a planted non-existent title returning **0**
matches — so the selector is demonstrably able to miss, which is what makes the three hits a result
rather than a tautology.

#### Instrument corrections — dated notes, with the criterion text left standing

> **Criterion 3's instrument is `beet move -p`, NOT `--pretend` (D-33, 2026-09-20, plan 06-02).**
> The ROADMAP criterion says "a `--pretend` run" and **is deliberately not rewritten**; the
> correction lives beside it, the way TAGR-05's did. `--pretend`'s pipeline in beets 2.12.0 is
> exactly `read_tasks → log_files` (`beets/importer/session.py@v2.12.0:201-240`), so
> `lookup_candidates` never runs, **no destination path is ever computed**, and every line it
> prints is a SOURCE path. It prints one line per file and exits 0, which is precisely why it reads
> as a pass. The mechanical discriminator: a `--pretend` transcript contains **no ` -> ` and no
> `/mnt/tank/media/Music/` substring at all**. The oracle that does evaluate the full `paths:`
> stanza — `%aunique{}`, `replace:`, `asciify_paths`, `legalize_path`, `max_filename_length` — is
> `beet move -p`, via `item.destination()`. `--pretend` is **kept** for what it genuinely proves:
> which folders are offered as tasks, i.e. `incremental`, `ignore`, `ignore_hidden`, `clutter`,
> `singletons` and album grouping. That is why it still serves criterion 2. Full addendum against
> CONF-06 in `.planning/REQUIREMENTS.md`.

> **Criterion 5's "source and library file counts unchanged" is WEAKER than what was done
> (D-29, 2026-09-21, plan 06-11).** The criterion text stands. A count would pass while content
> changed underneath — **Phase 1 measured exactly that happening**, a path-set comparison passing
> while file contents moved. What was actually produced is a three-layer proof, and it is what the
> verdict rests on:
> **layer 1, structural** — `docker inspect` says the mount whose Destination is `/media` carries
> `RW=false`; **layer 2, source** — `meta` *and* `sha256` manifests over all 190 files of the ten
> sampled folders (174 audio + 16 sidecars, deliberately the whole folder), identical before and
> after and re-verified outside the script with `cmp`; **layer 3, beets state** — `/config/library.db`
> `fbbdde0c…` and `/config/state.pickle` `f6a9a1ad…` byte-identical, **with mtimes recorded as well
> as hashes**, because an empty-state pickle rewritten with identical content moves the mtime and
> leaves the hash alone. Re-confirmed at close: the same two hashes appear either side of the
> `check-beets-config.sh` run above.

> **Criterion 4's write side is the `ARTISTS` tag, not `;` inside `ARTIST` (D-34, 2026-09-20,
> plan 06-02).** The criterion says "separated with `;`" and is not rewritten. beets builds
> `item.artist` by concatenating MusicBrainz artist-credit join phrases, and **no write-delimiter,
> separator or join key exists anywhere in `config_default.yaml` at 2.12.0 or 2.13.1** — measured,
> not assumed. beets therefore *cannot be configured* to emit `;` inside `ARTIST`. The `;` named in
> the criterion is a property of **this library's existing twelve files**, not of anything the
> pipeline will produce. What makes the two consumers agree is that both now read the same field:
> MA prefers `ARTISTS` natively and splits on `;`, and D-34 pointed Jellyfin at the same tag.

#### C-7 — "six criteria" versus five. Cosmetic, recorded so nobody hunts for a missing one

`06-CONTEXT.md` refers three times to "six criteria"; the ROADMAP's Phase 6 entry lists **five**,
numbered 1–5, and this closure answers those five. The discrepancy is a **numbering artefact** —
six *requirements* (CONF-01…CONF-06) against five *criteria*, because CONF-03 and CONF-06 are
discharged by the same oracle run. **There is no sixth criterion, and none was invented.** Recorded
here because an unexplained 6-versus-5 reads exactly like a criterion somebody forgot to answer.

#### D-32 — `tank/downloads@pre-phase5` is NOT released at Phase 6 sign-off. Standing instruction

**Do not destroy `tank/downloads@pre-phase5`.** Phase 5's rollback section says "do not destroy it
before Phase 6 has signed off" — and that sentence, read on its own, would authorise destroying it
today. It must not be read that way.

**Phase 6 wrote nothing, so it produced no evidence that Phase 5's changes were correct.** A phase
whose entire deliverable is that the library and the backlog are byte-identical before and after
cannot vindicate a set of writes it never exercised. The first run that does exercise them is
**Phase 7's pilot import**. The snapshot is the only undo for Phase 5's **4,750 renames, 751 in-place
tag writes and 26,005 chowns** — beets has no CLI `undo` and none of those three operations kept a
copy — and it is **not a clean undo**: a `zfs rollback` discards everything written to
`tank/downloads` since 2026-09-18 15:42 by every service that writes there, so it is an estate-wide
decision, not a music-project one. Release it only when Phase 7's pilot has passed. This is also
written into Phase 7's entry criteria in the ROADMAP, because a standing instruction that lives
only in a phase-close document is one nobody reads at the moment it matters.

#### D-08 — answered as a READ, not a measurement, and carried to Phase 9

The risk was beets-flask's inbox view going "laggy past some hundred folders". **rc6's schema
exposes no pagination, no page-size and no inbox-item-limit knob at all** — the only levers on it
are `gui.inbox.ignore` and batch cadence. That is a settled read of the schema, not a measurement
of the lag, and it is recorded as such: Phase 3's **friction 5 stays `NOT EXERCISED`**. Nothing in
Phase 6 put a hundred folders in front of the UI, so nothing in Phase 6 can claim the risk is
retired. Carried to **Phase 9**, which is the phase whose batch cadence makes it operationally
real.

### Still open at Phase 6 close

Phase 6's own:

- **CONF-04's Jellyfin half — the one open requirement, and a NAMED PHASE 7 ENTRY BLOCKER.** The
  option is set and asserted; the three pinned rows still read 0, 1, 1 against targets 4, 2, 2
  because a Default-mode refresh does not re-probe an unchanged file, and the refresh mode that
  would is forbidden in this estate. Neither "could not look" nor "nothing is wrong" — **do not
  record it as green, and do not sum it with the MA half.** It discharges on Phase 7's first write
  or import of a multi-artist release.
- **Path rule 2 (`albumtype:=dj disctotal:2..`) was never evaluated by any Phase 6 instrument**
  (DEF-06-12-01). Both drawn S5 folders resolved through rule 3 because neither carries
  `disctotal`. Seven `dj-mixes` folders in the population do carry it. Deferred to **Phase 7 by
  explicit operator decision**, alongside OQ-2 — reaching outside the drawn sample for a folder
  chosen *because* it carries the attribute under test is the hand-picking D-26 exists to prevent.
- **`Various Artists/` and `Various/` will both exist in the grown library** (DEF-06-11-01, 44 and
  30 files in the dry run). CONF-03 passes on both — each top level *does* equal its own
  `ALBUMARTIST` byte-exactly — but two spellings of one idea is two artist pages in Jellyfin and in
  MA, which is the defect CONF-03 exists to prevent, arriving through the **tags** rather than the
  paths. **No path rule can fix it.** Phase 7 decision.
- **`musicbrainz.search_limit` is 5** (DEF-06-12-02), so at the committed value whole classes of
  candidate are never offered: on the S4 `Vol 001` row, 5 candidates offered **zero** US pressings
  where 25 offered seven. **This is not a recommendation to raise it** — a longer list also means
  more round-trips and more chances to pick the wrong one. It is a recommendation to *measure* it
  during Phase 7's pilot: per folder, was the accepted candidate in the first 5?
- **`import.write: yes` is live, `/downloads` is `:rw`, and `01-auto` autotags — and NONE of the
  three controls the config names reaches that path** *(added 2026-09-22 by plan 06-21, carrying
  code-review finding WR-09; `06-REVIEW.md` § WR-09, `06-DISPOSITIONS.md`, `DEF-06-21-01`,
  ROADMAP Phase 7 entry criterion **E11**)*. **Read this before you drop a folder into an inbox.**
  `config.yaml` sets `write: yes` and names three independent controls — the `-c` **overlay**, the
  **`:ro` mount** (D-05) and the **statefile sha256** (D-29). The first two protect `/media`, the
  third protects beets' own state. **`/downloads` is protected by none of them**, and `/downloads`
  is where all three registered inboxes live: it is mounted **`:rw`** (`beets/flask.yaml:146`),
  the beets-flask watchdog is the **active** runtime (`restart: unless-stopped`), and **`01-auto`
  is registered with `autotag: auto`** (`beets/flask-config.yaml:80-83`). So **anything that
  appears under `/downloads/complete/nzb/_inbox/01-auto` is imported with no prompt**, by a config
  whose `import.write` is `yes`. The overlay does not save you here: it applies only to invocations
  *the Phase 6 scripts* make, and the watchdog reads the vendored config directly.
  **What actually keeps this safe today is two things, and neither is a control:** nothing
  automatic stages into `_inbox/` (SABnzbd lands in `complete/nzb/music/`, and plan 06-04 moved the
  two real folders to the **unregistered** `04-hold`), and **`tank/downloads@pre-phase5` is
  un-released** (D-32 / E4), so there is still an undo. **"Nobody has put a file there" is not one
  of the three controls the file claims.** Not changed in Phase 6 on purpose: editing `config.yaml`
  changes its sha256, which is the exact object every CONF-01 / CONF-02 / CONF-05 proof was
  measured against and the one the vendored-drift block compares repo-side to appdata-side.
  **Phase 7 decides `import.write` deliberately, in the same commit as the `rw` grant (E3).**
- **The D-34 Jellyfin library option is live-service state that git does not capture.** It lives in
  Jellyfin's configuration database on LXC 100 and nowhere in this repository. Its **only**
  protection is the by-name assertion in `scripts/check-music-consumers.sh` § 4. Narrow or remove
  that assertion and a single UI click reverts the option with every gate in this estate still
  green. **Name that dependency before touching § 4.**
- **The repo is ahead of the host, and the estate is NOT in sync.** At close LXC 100's checkout of
  `/mnt/fast/stacks` is at **`c67d497`** — all of Phase 6 is merged locally and **unpushed**, so
  the host carries none of the three Phase 6 scripts, an older `check-music-consumers.sh` with no
  § 4 at all, and an older `check-music-freeze.sh` still on the pre-D-11 `tagger definitions: 1`
  expectation. **Every consequence below was measured at close, not inferred:**
  `quick-health-check.sh`'s vendored-drift block reports **`UNKNOWN — could not look`** with
  `ssh exit 4`, and the cause names itself in the transcript —
  `fatal: path 'stacks/selfhosted/arrs/beets/flask-config.yaml' does not exist in 'HEAD'`, i.e.
  `git show HEAD:<path>` failed because that file was added by plan 06-04 and the host's HEAD
  predates it. **Nothing was compared. That is NOT "the vendored files match".** In the same run
  the host-side census printed `tagger definitions: 1 (target 1)` — which looks green and **is the
  old instrument reading the old checkout**; the untracked host-side `flask.yaml` is invisible to
  `git ls-files`, so the D-11 named-pair expectation never ran at all. It clears on `git push` plus
  `git pull --ff-only` on LXC 100 **and on nothing else** — and that pull will refuse until the
  untracked `/mnt/fast/stacks/stacks/selfhosted/arrs/beets/flask.yaml` is removed host-side.
  **The push is the operator's call and has not been made.**

### The routine health-check run at close

`bash scripts/quick-health-check.sh` from the workstation, 2026-09-21, **exit 1 — and the exit code
is non-discriminating, so these are the BLOCK verdicts**:

| Block | Verdict at close |
|---|---|
| Traefik / Authelia / dashboard | ✅ running; dashboard `✅ Protected (HTTP 302 → Authelia)` |
| Containers | ✅ 97 running, no unhealthy, none in `created` |
| Vendored-file drift | ⚠️ **UNKNOWN — could not look** (`ssh exit 4`), cause quoted above. Not a green |
| D-03 one vendored config into both containers | ✅ one config, both containers, `config :ro`, `/mnt/tank/media :ro` |
| D-04 throwaway `-l` on every `beet` invocation | ✅ 0 executable invocations open the real library (documentation hits at the pinned baseline of 2) — **✳ SUPERSEDED, see the dated note below the table** |
| `extended.conf` destructive switches | ✅ disarmed — `requireBeetsMatch=false`, `ConversionFormat` in `{FLAC,OPUS}` |
| Music freeze harness | ❌ **exit 1 on the Phase 5 `interpolated-host-path` gate alone** (`expected=12, found=13`). Every music counter inside it is at target: tagger-class writers 0, unclassified writers 0, declared `rw` reaching Music 0, ownership mismatches 0, retired paths 0, `rw` on Music tagger-capable 0, fence assertions failed 0 |
| Music consumers audit | ✅ both consumers see the library; 2 of 2 albums matched in each, `FAILURES total: 0` |
| Library underscore-dir guard | ✅ no `_`-prefixed directories under `/mnt/tank/media/Music` |
| Jellyfin transcode retention | ✅ intact — 5 encoding values asserted, 0 drifted; `/` headroom 24.33 GiB; quota 50 G; `volume mounts: 0` |
| Container image drift | ✅ measured — 10 drifted, **reported not asserted** (v1 is alert-only, D-01); unresolvable 2 as expected; could-not-look 0 |

> **✳ THE D-04 ROW ABOVE IS SUPERSEDED. That green tick meant nothing** *(note added 2026-09-22,
> plan 06-16, CR-01; the row is kept verbatim rather than deleted, because what the instrument
> reported on 2026-09-21 is the record)*. The block asserted over an **empty set** for the whole of
> Phase 6. Its own green line says so out loud — *"0 invocation-shaped lines outside `*.md`"* — and
> it called that a pass. Reproduced live on the deployed tree on 2026-09-22: raw 46,
> comment-stripped 26, invocation-shaped 2, **executable 0**.
>
> **The cause, so it is not repeated.** `git grep -w -E 'beet'` is **case sensitive**, and *every*
> `beet` call this repo makes from a script is assembled from a variable — `"$BEET"`,
> `"$BEET_BIN"`, `"${BEET_BIN}"` — never from the literal token `beet`. The scan could not see a
> single one of them. Widening only the local shape test would not have helped: the lines were
> never returned by the remote grep in the first place.
>
> **What the block runs now** — quoted from `scripts/quick-health-check.sh` byte for byte, so this
> page cannot drift from the instrument. The remote scan:
>
> ```
> timeout $REMOTE_TIMEOUT git grep -n -I -w -E -e 'beet' -e 'BEET[A-Z_]*' HEAD -- scripts stacks
> ```
>
> A **second `-e`** rather than an alternation, because an alternation puts a literal `|` in the
> command string and this file's greppable `timeout $REMOTE_TIMEOUT.*|` invariant matches on the
> line. The local shape test:
>
> ```
> D04_INV_RE='^HEAD:[^:]*:[0-9]*:[[:space:]]*(sudo[[:space:]]+)?beet[[:space:]]|[[:space:]](&&|;)[[:space:]]*beet[[:space:]]|docker[[:space:]][^`]*[[:space:]]beet[[:space:]]|(^HEAD:[^:]*:[0-9]*:[[:space:]]*(sudo[[:space:]]+)?|")\$\{?BEET[A-Z_]*\}?"?[[:space:]]+(-|[a-z])'
> ```
>
> The fourth branch is the new one: a `BEET`-prefixed variable **in command position** (content
> start, or immediately inside an opening quote) **followed by a flag or a subcommand word**. Both
> halves are load-bearing and both were measured — the naive "preceded by whitespace or a quote"
> form matched **26** lines of which **18 run nothing** (`[[ $BEET_EXEC_RC -eq 0 ]]`,
> `"$BEETS_DB_COUNT"`, and `remote_exec … "$BEET" "$PY"` argument passing). It deliberately admits
> a **bare** invocation — the binary variable followed by a `config` subcommand and no flags at
> all — so it cannot be accused of only matching invocations that were already compliant.
>
> *(That sentence originally spelled the bare invocation out literally. It is written this way
> because the literal form **is** an invocation shape, so it landed in the documentation set and
> took `D04_N_DOC` to 3 against the pinned baseline of 2 — a red, correctly. The pin was **not**
> raised to accommodate it: a new copy-pasteable bare invocation in the runbook is exactly the
> footgun the pin exists to catch, and the two historic quotations above are kept verbatim only
> because they are the Nov-2025 record, not because quoting is free.)*
>
> **Measured counts.** Re-measured 2026-09-22 by plan 06-28 (**GC-10**) at commit `ab5ff32`, on
> this repository's tree, by reproducing the D-04 block's own pipeline with `D04_INV_RE` and
> `D04_EXEMPT_RE` **extracted from `scripts/quick-health-check.sh` rather than retyped** — plan
> 06-23 widened `D04_INV_RE` in the same round, so any transcribed copy is already old. Commands
> and full transcript in `artifacts/06-28-citations-and-counts.txt`.
>
> | count | value | pinned by |
> |---|---|---|
> | invocation-shaped | 10 | — (the input to the two pins) |
> | **executable** | **8** = asserted **3** + exempt **5** | — |
> | exempt | 5 | `D04_EXEMPT_BASELINE` |
> | documentation | 2 | `D04_DOC_BASELINE` |
>
> **The `raw` and `comment-stripped` counts are deliberately NOT recorded here.** Neither is
> pinned and nothing asserts on either: they count every `beet`/`BEET*` mention across `scripts`
> and `stacks`, so they move with **every commit to either tree — including the commit that writes
> them down**, and this page is itself inside the scan scope. That is not hypothetical. This table
> previously carried two such figures together with the claim that they had been *"compared against
> the block's own printed figures — agreement at every position"*; that claim asserted a
> verification its own presence invalidated, because the surrounding note quotes `D04_INV_RE` and
> `BEET[A-Z_]*` and so adds matching lines to the very counts it claimed agreement on. Both figures
> were false within a day of being written, and were still wrong by nine and nine when GC-10 found
> them. The four rows above are pinned or derived from pinned ones and do not move when prose is
> added anywhere in the repo.
>
> *(Where a self-referential count genuinely must be stated, this repo's convention is to state it
> as a **transition measured before and after** the edit that changes it — as the eleventh and
> twelfth `EXIT-CODE BEHAVIOUR CHANGED` notices in `quick-health-check.sh` do with `headers 10 -> 11`.
> That convention existed when this table was written and was not applied to it.)*
>
> **THE EXEMPTION REGISTER — `D04_EXEMPT_RE` and `D04_EXEMPT_BASELINE` (pinned at 5).** Five
> invocation-shaped executable lines are **named, counted and pinned** rather than asserted. The
> register is keyed on the file path **and** the distinguishing overlay variable, so a *different*
> invocation added to either file does **not** inherit the exemption; a move off the pin is a red
> that prints every exempt line. A green D-04 now always **states how many lines it did not assert
> over**, so 3 asserted can never be mistaken for 8.
>
> | file | how many | how to find them — grep for the key, do **not** trust a line number |
> |---|---|---|
> | `scripts/phase06-oracle.sh` | 3 | `$SCRATCH_OVERLAY` — the `-c` overlay argument on each |
> | `scripts/phase06-incremental-control.sh` | 2 | `$ROOT/overlay.yaml` — the `-c` overlay argument on each |
>
> *(Both rows carried **line numbers** until 2026-09-22, when plan 06-28 replaced them with the
> keys under **GC-04**. Both had rotted — the oracle's row by roughly six hundred lines, the
> sibling's by forty — and the per-row before/after positions are recorded in
> `artifacts/06-28-citations-and-counts.txt` rather than reproduced here, because a stale number
> quoted in the page that replaced it is still a stale number a reader can copy. The keys above are
> not a second description of the exemption — they are **literally the two alternations of
> `D04_EXEMPT_RE`**, so the register and the regex cannot drift apart, and the grep that finds the
> lines is the same test the check applies. A count is given instead of positions because the
> count is what `D04_EXEMPT_BASELINE` pins; the positions never were.)*
>
> **Why — all three reasons hold, and an unexplained exemption would be worse than none.**
> 1. Each passes a `-c` overlay redirecting `library`, `statefile` **and** `directory` together
>    into a throwaway root. That is the **stronger** half of D-04's rule and the half `-l` cannot
>    achieve — `-l` redirects `library` and nothing else. These are not a weaker compliance.
> 2. Adding a `-l` would make them **worse**: naming a different path than the overlay's `library:`
>    splits the throwaway state across two files; naming the same path is a second source of truth
>    for one value, and the two drift on the first edit.
> 3. Both are **closed instruments** whose proof runs are already committed and cannot be re-driven
>    inside this phase — `artifacts/06-11-oracle-run.txt`, `artifacts/06-11-wrote-nothing.txt` and
>    `artifacts/06-20-incremental-driven.txt`. Changing their flags would invalidate that evidence.
>
> **The block can now fail, and was made to.** Five branches driven live and recorded with
> before/after `sha256` in `artifacts/06-16-d04-driven.txt`: a real variable-built violation going
> **red** and removed; the new vacuity guard firing **UNKNOWN** on a zero executable count; the
> exemption pin firing under `D04_EXEMPT_BASELINE=4` and proven unable to pass; the **124**
> bound-expiry branch driven (WR-10 — a `timeout` kill used to report as *"'git grep' failed"*,
> because `124 > 1`); and the D-03 render `exit 3` driven via the new `D03_REPO_ROOT` (IN-13).
>
> **⚠️ What the block reports on the deployed estate today is `UNKNOWN`, not `✅`** — the host's
> `/mnt/fast/stacks` is still at `c67d497`, pre-Phase-6, so the executable count there is genuinely
> 0 and the vacuity guard correctly refuses to call that a pass. It clears on the same
> `git push` + `git pull --ff-only` the drift block is waiting on, **and on nothing else**.

**Two reds, neither caused by Phase 6.** The freeze harness fails on a Phase 5 human-review gate —
**verified**, not assumed: none of the 13 interpolated-host-path lines is under
`stacks/selfhosted/arrs/beets/`. The drift block's UNKNOWN is the unpushed-host state above. The
`tagger-capable containers: 3` line is the expected 2 → 3 move as `beets-flask` joined; it is
reported, and the assertion that matters — `rw on Music, tagger-capable: 0` — is green.
- **`tagger-capable containers` moved 2 → 3** — `beets-flask` joins `sabnzbd` and `lidarr`.
  Reported, not asserted (none of the three holds `rw` on Music, which *is* asserted). § *Phase 4 →
  The census, executed* above states 2 as "the expected value"; **that sentence is now dated** and
  is left standing as the record of what was true then.

Carried in from Phase 5 and untouched by Phase 6, because they are still open and a closure that
omits them reads as if they were fixed:

- **`check-music-freeze.sh`'s `interpolated-host-path inventory MOVED: expected=12, found=13`.**
  Pre-existing, unrelated to Phase 6 — **verified**: not one of the 13 lines is under
  `stacks/selfhosted/arrs/beets/`. Every music block in that harness is green; this single
  human-review gate is why the script exits 1 on LXC 100 and why **`quick-health-check.sh`'s exit
  code is non-discriminating for every criterion above — read the block verdicts.** The remedy is
  the one the failure text states: read the new line by hand and move `DECLARED_INTERP_EXPECTED` in
  the same commit, never bump the number.
- **`takeout-import.service` on LXC 100 passes an Immich API key on the command line**, readable in
  `ps` host-wide. Rotate the key and move it out of `ExecStart` in the same change. The value is
  deliberately not recorded here — **this repo is public.**
- **`dropbox/` is 84 % of the download dataset and is not downloads** — 196,327 entries inside the
  `rw` bind of **nine** containers. Whoever next revises `stacks/selfhosted/arrs/` owns narrowing
  those binds.
- **`dj-mixes`'s 84 inconsistent top-level names** and **`mac-music-archive/`'s 23,874
  uncharacterised music entries** both remain as Phase 5 left them.

### How to re-run the Phase 6 evidence

Everything below is **read-only**. The first three run **from the repo root on the workstation**
(they ssh-delegate and `docker exec`); the fourth must run **on LXC 100**, which is why it needs a
`git pull` first.

```bash
# Criteria 1, 2 (read-back) and 5 (config half) — the server-committed config.
bash scripts/check-beets-config.sh

# Criterion 2's negative control — two overlays ONE key apart, opposite outcomes.
bash scripts/phase06-incremental-control.sh --self-test   # judge the judge; no ssh, no docker
bash scripts/phase06-incremental-control.sh --arm a       # incremental_skip_later: no  -> trap FIRES
bash scripts/phase06-incremental-control.sh --arm b       # incremental_skip_later: yes -> trap DEFEATED
bash scripts/phase06-incremental-control.sh --cleanup

# Criteria 3 and 5 (wrote-nothing) — the destination-path oracle.
bash scripts/phase06-oracle.sh --self-test                # judge the judge
bash scripts/phase06-oracle.sh --run                      # zero-diff against 06-EXPECTED-TREE.txt

# Criterion 4 — both consumers, from LXC 100.
ssh root@172.16.1.159 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-music-consumers.sh'
```

⚠ **`bash scripts/phase06-oracle.sh` with no arguments prints usage and exits 2, deliberately.** A
script whose default action drives an import into a container that mounts the real library is a
footgun. Its exit codes are four, not two: `0` zero-diff and every assertion green, `1` RED (the
diff was non-empty, an assertion failed, **or the dry run wrote something**), `2` usage or a
precheck refusal, `3` **UNKNOWN, not green** — the positive control failed, so the diff was never
evaluated. Three of the four are not "the tree is wrong".

## Vendored config digest register (from Phase 7, D-22)

**This is a register, not a phase-closure section.** It does not change the *Current state*
pointer at the head of this file. It exists so every proof taken against a vendored config stays
attributable to the exact object it measured, now that the Phase 7 D-22 commit has moved both
digests. Rows are appended; a row is never edited except to fill in a commit hash that did not
exist when the row was written.

**Why the old digests are kept (D-22).** Every CONF-01, CONF-02 and CONF-05 proof was measured
against one specific `config.yaml` object, and the vendored-drift block in
`scripts/quick-health-check.sh` compares the appdata copy with that same object
(`DEF-06-21-01`). Re-baselining without keeping the previous digest would orphan those proofs.
**C10:** the PREVIOUS digests below were measured, not copied — `git show <base>:<path>` through
two hashers (`shasum -a 256`, `openssl dgst -sha256`), plus the appdata copy on LXC 100 and the
file inside the running beets-flask container. Base commit `003a7b23fa3e67c91490749c5831fcad5b755586`.
The raw readings are in
`.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-08-d22-measure.txt`.

| file | object | sha256 | commit | measured by |
|------|--------|--------|--------|-------------|
| `beets/config.yaml` | at the 06-04 first-start proof (context only; not the previous digest) | `96a7c622779f95a13cd858c09b34072bcfc01405fecccd00b361ecdb5cb3e1f7` | recorded by plan 06-04 | `06-04-first-start.txt` (repo, appdata and in-container all matched then) |
| `beets/config.yaml` | PREVIOUS — what CONF-01/02/05 in their final Phase 6 form were measured against | `661c729738a12be61d94dcf0cf0bfb6b0cdaa9c996d2ed9fffb9bc494394668f` | `1a6428608b8e6c42bc80ecad1187616eaace1a29` (2026-09-21) | 07-08 task 1: two hashers at the base commit; appdata and container equal |
| `beets/config.yaml` | NEW — carries the D-22 edits (comments only; no key changed) | `7d7264546e7aafe791c3b2c28dc1b39cdf818ff3105f02f5834eb4208103fdab` | the D-22 commit | 07-08 task 2: sha256 of the staged file |
| `beets/flask-config.yaml` | at the 06-04 first-start proof (context only) | `949bd1f3b13501d448865ce2d19195db209050279f8a0022e97cd7e54d835db8` | recorded by plan 06-04 | `06-04-first-start.txt` |
| `beets/flask-config.yaml` | PREVIOUS — unchanged since 06-04 | `949bd1f3b13501d448865ce2d19195db209050279f8a0022e97cd7e54d835db8` | `f1848e204621c9de54784f58b05b7c2660fdff46` (2026-09-20) | 07-08 task 1: two hashers at the base commit; appdata and container equal |
| `beets/flask-config.yaml` | NEW — `01-auto` de-registered (D-21), dated notes | `875fcf7ef5246fbfaef373824653381c7e43d3801c099a94e4046fcae63813c8` | the D-22 commit | 07-08 task 2: sha256 of the staged file |

**What the NEW `config.yaml` changes, stated so nobody reads a digest move as a behaviour move.**
Only comments changed. The import keys (`copy: yes`, `move: no`, `write: yes`) are byte-for-byte
what they were. D-22 item 2 ("`import.move` → `copy`") turned out to be a **verification**:
the repo copy, the appdata copy and the running server all read copy / no-move before the edit
(C1). `write: yes` is **forced, not chosen** (criterion 3 needs the new tags on the file), and D-21
is what bounds it. The new comments record that, correct the stale "`tank` has 9 T free" figure to
the measured 5.26 T, and retract the `:ro` mount from the list of controls.

**Until plan 07-09 installs both files to `/mnt/fast/appdata/arrs/beets/config/`, the drift
block reads them as drifted (C9).** It compares the host checkout's HEAD with appdata, so the red
starts when the host pulls the D-22 commit and ends at the install. That is the block working.

**Every CONF-01/02/05 proof stays attributable to the PREVIOUS object**, `661c7297…` for
`config.yaml` and `949bd1f3…` for `flask-config.yaml`. A re-run of any of them against the NEW
object is a new measurement, and gets a new row here if it is recorded as evidence.

**C7/C8: two Phase 6 instruments are retired from use once the grant deploys. The code does not
change.** After the D-22 grant `scripts/phase06-oracle.sh --run` goes red on layer 1 (its
read-only-media assertion) and on its fixture library sha pin. `scripts/phase06-incremental-control.sh`
goes red on its baseline library sha pin. Both are **red by design**: they are Phase 6 dry-run
instruments, they fail closed, and they assert a state (`/media` read-only, an unimported
`library.db`) that Phase 7 ends on purpose. Plan 07-05 ran the oracle's one real run before the
grant.
A red from a post-grant `--run` of either is expected. It is not evidence of damage.
