# Stack Research

**Domain:** Self-hosted music library tagging, normalisation and organisation (subsequent milestone on an existing Docker/Proxmox media estate)
**Researched:** 2026-08-17
**Confidence:** HIGH on tagger comparison and version data (verified against upstream source and live APIs); MEDIUM on OCR and HAOS storage (verified against official docs + source, but not tested on this hardware)

---

## Headline: three findings that change the plan

Before the stack table, three things surfaced during research that contradict what the
project's own documents currently assert. Each is verified against primary sources.

### 1. The wrtag version pin is inverted — v0.20.0 is the *broken* one, not v0.30.0

`stacks/selfhosted/music/wrtag.yaml` pins `sentriz/wrtag:v0.20.0` with the comment
*"v0.30.0 changed path-format fields — pinned to last compatible version"*. Verified against
upstream source, the opposite is true: the `WRTAG_PATH_FORMAT` currently in that file is a
**v0.30+ template running on a v0.2x binary**.

In `pathformat/pathformat.go` at tag `v0.20.0`, `Format.Execute` contains:

```go
// make sure these are not used
d.Track.Number = ""
d.Track.Position = -1
```

The config's `{{ pad0 2 .Track.Position }}` therefore renders **`-1` for every track**, so
every file in a release gets an identical destination name. The config also references the
top-level `{{ .Media.Position }}`, which does not exist in the v0.20.0 `pathformat.Data`
struct at all (that struct has `Release`, `ReleaseDisambiguation`, `Ext`, `Track`, `Tracks`,
`TrackNum`, `IsCompilation` — no `Media`).

Startup validation does not catch either problem: v0.20.0's `validate()` builds only
single-medium example releases, so the `{{ if gt (len .Release.Media) 1 }}` branch is never
exercised, and the two example tracks differ by title so the ambiguity check passes anyway.
The container starts clean and fails at runtime. (`wrtag.db` untouched since 23 Jan 2026 is
consistent with this — nothing has been successfully imported.)

**What v0.30.0 actually broke** (from the upstream release notes' BREAKING CHANGES table):

| v0.2x | v0.30.0 | Notes |
|---|---|---|
| `.TrackNum` | `.Track.Position` | Now uses MusicBrainz's real per-disc position |
| `len .Tracks` | `.Media.TrackCount` | Track count is per-medium, not total |
| `.Tracks` | *(removed)* | |
| — | `.Media` | *(new)* current medium |
| — | `.Media.Position` | *(new)* disc number |

The existing config uses **none** of the removed fields. `.Release`, `.Release.Media`,
`.Release.Date.Year`, `.Track.Position`, `.Ext` and the `artistsString` helper are unchanged
across v0.20.0 → v0.33.0 (the `musicbrainz.Release`/`Track`/`Media` structs are byte-identical
between the two tags apart from an added `Aliases` field). `.IsCompilation` and
`.ReleaseDisambiguation` were dropped from `Data` in v0.30.0 but are **still injected** by
`withLegacyFields()` in v0.33.0, so they keep working.

**Migration for this repo is therefore: change the image tag, change nothing else.**
`sentriz/wrtag:v0.20.0` → `sentriz/wrtag:v0.33.0`, drop the Renovate pin. The existing
`WRTAG_PATH_FORMAT` string is already correct for v0.33.0. Optional modernisation:
`{{ if .IsCompilation }}` → `{{ if isCompilation .Release.ReleaseGroup }}`.

Confidence: **HIGH** — read directly from tagged upstream source.

### 2. MusicBrainz *does* carry these DJ services — partially, and that is worse than absence

`PROJECT.md` and `beets.md` both state that Mastermix, DMC and Music Factory "are not in
MusicBrainz". Live queries against the MusicBrainz WS/2 API say otherwise, but with a sharp
cutoff:

| Query (exact-title, score ≥ 95) | Result |
|---|---|
| `Mastermix Issue 300` | Hit — 7 tracks, 2011-06 |
| `Mastermix Issue 366` | Hit ×2 — 5 tracks (2016) and 10 tracks (2016-12) |
| `Mastermix Issue 380 / 400 / 420 / 430 / 433 / 444` | **No exact hit** |
| `DMC Commercial Collection 289` | Hit — 9 tracks |
| `DMC Commercial Collection 350 / 400` | **No exact hit** |
| `Mastermix: Pro Disc 101` | Hit — 21 tracks |
| `Music Factory Mastermix Issue 003` | Hit — 15 tracks |

Two consequences:

- The **coverage stops around 2016** and the collection's issues (430, 433, 444) are past it.
  The original constraint is directionally right for *this* content.
- Where entries exist they are frequently **stubs**: 5–10 tracks against real issues that run
  15–20. A stub is more dangerous than a gap, because an autotagger can match an 18-track
  folder against a 7-track release and produce a confident, wrong result. `beet import -t`
  (timid) on any DJ folder is not optional.

### 3. Discogs has the exact releases MusicBrainz lacks

Same issues, queried against the Discogs API:

| Query | Discogs result |
|---|---|
| `Mastermix Issue 433` | `Various – Issue 433` (2022), label **Music Factory Mastermix Issue**, File/WAV and File/MP3 editions |
| `Mastermix Issue 430` | `Various – Mastermix Issue 430` (2022), label Music Factory Mastermix Issue |
| `DMC Commercial Collection 350` | `Various – Commercial Collection 350` (2012), label DMC |
| label `Mastermix` | 4+ label entities incl. `Mastermix Productions`, `Mastermix Productions Ltd` |

This is the decisive axis of the whole comparison. **wrtag has no Discogs support and no
plans for one** — its tagline is literally "based on MusicBrainz", and the word "discogs"
appears zero times in the v0.33.0 README (it appears only as a user-supplied
`WRTAG_RESEARCH_LINK`, i.e. a hyperlink for a human, not a metadata source). beets ships a
first-class `discogs` metadata-source plugin.

**Caveat that the spike must test:** Discogs titles these as `Issue 433`, not
`Mastermix Issue 433`, and credits the artist as `Various`. beets builds its Discogs query
from the existing `artist` + `album` tags — which on this content are scrambled (`artist="R'n'b
Hits 1990-1999 Pt.1 108"`, `album="VA"`). **Tag normalisation must happen before Discogs
matching can work at all**, which fixes the phase ordering: normalise → then match.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **beets** | **2.13.1** (27–29 Jul 2026) | Primary and only tagger | Only option with a **Discogs** source, which is where this collection's DJ releases actually live. Also the only one with tools for *repairing* tags (`-A` as-is import, `edit`, `modify`, `zero`, flexible attributes, a query language) rather than only fetching fresh ones. Python library + CLI, so scriptable. Active: 5 minor releases in 2026 alone. |
| **beets `musicbrainz` plugin** | bundled with 2.13.1 | Primary metadata source for bucket A/B | **Must be listed explicitly.** Since beets 2.4.0 (Sept 2025) MusicBrainz is a plugin; a customised `plugins:` list that omits it silently disables autotagging entirely. |
| **beets `discogs` plugin** | bundled; `pip install "beets[discogs]"` | Metadata source for bucket C (DJ services) | The only route to Mastermix/DMC/Music Factory metadata. Needs a Discogs personal access token (`discogs.user_token`) — the OAuth flow is unworkable in a container. |
| **mutagen** | **1.48.1** | Scripted tag remap and BPM-strip on bucket C | The standard Python tag library, and what beets itself uses underneath. Deterministic, dry-runnable, diffable — the right shape for "apply this field mapping to 794 files and let me review it first". |
| **wrtag** | 0.33.0 (11 Jul 2026) | **Retire** | Genuinely good software — fast Go, `sync` for bulk re-tag, safe concurrency, path-format ambiguity validation — but MusicBrainz-only and metadata-fetch-only. Neither matches this project's two dominant problems. |

### Supporting Libraries and Tools

| Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `beets` plugin `fromfilename` | bundled | Infer track/title from filename when tags absent | Bucket C folders with no usable tags. Note: it only fires when `title` is **missing**, so it will not help the 7-of-8 dj-mixes files that *are* tagged (wrongly). |
| `beets` plugin `edit` | bundled | Inline YAML edit during import | Bucket B and C. 2.13.0 added album-level fields as a YAML header when editing an album import — materially better for compilations. |
| `beets` plugin `zero` | bundled | Null out junk fields conditionally (regex-matched) | Stripping the `album="VA"` garbage and rip-tool comments. Set `update_database: yes` — by default it only touches files, not the beets DB. |
| `beets` plugin `albumtypes` / flexible attrs | bundled | Route DJ content to its own path | `beet import --set albumtype=dj` + a `paths: albumtype:dj:` rule keeps DJ releases out of `Compilations/`. |
| `beets` plugin `importsource` | bundled | Records `source_path` on every imported item | **Use this from day one.** Makes an interrupted 7,451-file import resumable: `beet ls source_path:$PWD` tells you what already landed. Directly mitigates the "abandoned halfway" failure mode this project exists to prevent. |
| `beets` plugin `duplicates` | bundled | Reconcile the 85 shared folder names | 2.14 (unreleased) adds a `duplicate_action: upgrade` that keeps the higher-bitrate copy. Not in 2.13.1 — don't plan on it. |
| **kid3-cli** | **3.10.1** | Headless bulk tag surgery | Fallback / cross-check for the mutagen script. Runs on the LXC, no GUI, scriptable. Reach for it if writing Python feels heavier than the job. |
| **Mp3tag (Mac)** | current | Interactive regex actions on a sample | Damian's workstation is macOS. Good for *designing* the field-mapping rules on 20 files by eye before encoding them into the mutagen script. Not for the bulk run. |
| **Anthropic / Google vision API** | Claude Opus 4.6 or Gemini 3 Flash | Read tracklistings off the 54 cover scans | See "Cover scan extraction" below. |

### What is already in place and stays

Jellyfin, Lidarr, SABnzbd, Proxmox LXC 100, ZFS on `tank`. Music Assistant on the NUC
(HAOS) is the new consumer — see the storage section.

---

## The beets vs wrtag head-to-head

Both are alive and well maintained. This is not a maintenance-risk decision.

| | **beets** | **wrtag** |
|---|---|---|
| Current version | 2.13.1 (29 Jul 2026) | v0.33.0 (11 Jul 2026) |
| Release cadence 2026 | 2.6 → 2.13, 8 releases | v0.20 → v0.33, 5 releases |
| Repo activity | Very high, large contributor base | Active, single primary maintainer (`sentriz`), 410 stars |
| Language / shape | Python; CLI + importable library | Go; static binary + web queue |
| Container | `lscr.io/linuxserver/beets:2.13.1` | `sentriz/wrtag:v0.33.0` |
| **Metadata sources** | **MusicBrainz, Discogs, Spotify, Deezer, Tidal, Beatport, Bandcamp (beetcamp)** | **MusicBrainz only** |
| **Non-MusicBrainz DJ releases** | Discogs plugin resolves Mastermix Issue 430/433, DMC 350 — verified | **Cannot.** No non-MB source exists or is planned |
| **Repairing existing wrong tags** | `import -A` (as-is), `edit`, `modify` (with `+=`/`-=` since 2.13.0), `zero`, `write`, query language over a persistent DB | **No facility.** wrtag writes what MusicBrainz returns. No "keep these files, fix this field" mode |
| **Bulk import of thousands** | Works, but interactive by nature; `-q` quiet mode exists; `importsource` makes it resumable | Excellent — `wrtag sync -num-workers 16`, tree-style locking, fast |
| **Bulk *re*-tag of an organised library** | `beet mbsync`, `beet move` | `wrtag sync` — genuinely better, this is wrtag's standout feature |
| Scriptability | Full: CLI + Python plugin API + hooks | Subprocess addons, HTTP API (`/op/{operation}` with optional `mbid`/`confirm`) |
| Web UI | `web` plugin is a **library browser**, not an importer | Real import queue with notify + confirm — genuinely better |
| Path-format safety | Path templates, no ambiguity validation | Validates the format can't collide two tracks/releases at startup |
| State | `library.db` (must be reconciled; this repo has **two**) | `wrtag.db` is only the web job queue; tags in files are the truth |

### Recommendation

**Use beets 2.13.1. Retire wrtag.** Confidence: **HIGH**.

The reasoning is not "beets is better software". wrtag is faster, has a better import UI, and
`wrtag sync` is a capability beets does not match. The reasoning is that this project has two
dominant problems and wrtag can address neither:

1. **~110 of ~170 backlog folders are DJ service releases not in MusicBrainz.** wrtag is
   MusicBrainz-only, by design, permanently.
2. **The DJ content is already tagged, just wrongly mapped.** wrtag has no concept of
   "preserve these tags and fix this field". beets does (`-A`, `edit`, `modify`, `zero`).

Beyond that, "one tagger someone owns" is the stated core value. beets is the one already
holding library state (two `library.db` files), already referenced by `audio.bash`, and
already documented in `beets.md`. Consolidating onto beets removes three entry points;
consolidating onto wrtag would require rebuilding all of it.

### Evidence that would overturn this — test these in the spike

The project plans to decide via a spike on real content. These are the specific results that
should flip the recommendation:

| Overturning evidence | Why it flips the decision | How to test |
|---|---|---|
| **Discogs matches < ~40% of `dj-mixes` folders** even after tag normalisation | beets' only structural advantage evaporates; DJ metadata comes from scans/manual either way, and wrtag's speed + import UI win on buckets A/B | Normalise tags on 20 folders, then `beet import -t` with `discogs` enabled; count folders where a Discogs candidate appears at all |
| **Discogs rate limiting makes bulk import impractical** (60 req/min authenticated) | 7,451 files across ~1,000 folders is hours of wall-clock even before think time | Time 20 folder imports with `discogs` enabled; extrapolate |
| **Damian will not sit at an interactive prompt** | beets bucket B/C work is inherently interactive; wrtag's notify-and-confirm queue is a better fit for "do it later, from a phone" | Honest self-assessment, not a measurement. If the answer is no, the plan needs wrtag for A/B and manual/scan work for C — two tools, which contradicts the core value |
| **wrtag v0.33.0 clears bucket A materially faster with equal accuracy** | If A is 80% of the *files*, throughput on A might outweigh source coverage on C | Run both over the same 30 mainstream albums; compare wall-clock and count wrong matches |

**Non-evidence — do not let these decide it:** wrtag's version number (0.x is the author's
choice, not immaturity — the project is 3 years old with a stable release cadence), and the
current wrtag container's brokenness (that's the inverted pin, fixable in one line).

---

## Tag normalisation for the DJ collection

The problem, from `PROJECT.md`:

```
artist="R'n'b Hits 1990-1999 Pt.1 108"  album="VA"                  title="Mastermix_Issue_444 WEB"
artist="Various"                        album="Mastermix Issue 433"  title="Yacht Soul 1 100"
artist="Mastermix Issue 430"            album="Pop Hits 2 119"       title="Mastermix"
```

Three different field permutations of the same four facts, plus BPM appended to titles.

### Recommendation: a Python + mutagen script, run per-folder, with a dry-run mode

**Confidence: HIGH.** Rationale:

- The rules are **per-folder**, not per-value. Folder 1 needs `artist → album`,
  `title → series`; folder 2 is already right; folder 3 needs `artist ↔ album` swapped.
  Every config-driven remapper below assumes rules keyed on *values*, not on *which
  permutation this folder uses*. A script can classify the permutation first, then apply.
- It must be **reviewable before it writes**. 794 files, irreversible in-place edits.
- `mutagen 1.48.1` is the library beets itself uses, so tags written are guaranteed to be
  read back identically by beets.

Shape: detect permutation → emit a proposed diff to CSV → human eyeballs the CSV → apply.
The BPM strip is a separate, simpler pass: `re.sub(r'\s+\d{2,3}$', '', title)` — but guard it,
because a legitimate title *can* end in a number (`"Summer of '69"`, `"1999"`, `"Take Five 5"`).
Restrict to values in a plausible BPM range (60–200) and log every strip.

### What NOT to use for this, and why

| Tool | Why it does not fit |
|---|---|
| **beets `rewrite` plugin** | Canonicalises *values* (`artist "The Jimi Hendrix Experience" → "Jimi Hendrix"`). It cannot move a value from one field to another, and it cannot express "in this folder, artist and album are swapped". Also modifies metadata — a footgun at this scale. |
| **beets `advancedrewrite`** | Query-matched replacements with fixed literal values. Same structural limitation: you'd need one rule per folder, hand-written, with the correct literal — which is just doing the work manually with extra YAML. |
| **beets `substitute` plugin** | Explicitly **does not modify metadata** — it only affects path templates. Wrong layer entirely. |
| **beets `fromfilename`** | Fires only when `title` is *missing*. 7 of 8 sampled dj-mixes files have a title. Still worth enabling for the minority that don't. |
| **beets `-A` (as-is) alone** | As `PROJECT.md` already notes — faithfully preserves the wrong mapping. `-A` is correct *after* normalisation, not instead of it. |
| **MusicBrainz Picard** | Stable is **2.13.3 (Feb 2025)**; 3.0 has been in beta since April 2026 (currently `3.0.0b9`). Picard's `$rreplace`/`$swapprefix` tagger script *can* do field surgery, and it has a "Convert Unicode punctuation" style batch model — but it's a GUI drag-and-drop workflow over 794 files on a network share, with no dry-run and no diff. Wrong ergonomics for a headless LXC. |
| **eyeD3 0.9.9** | MP3/ID3 only. The collection includes FLAC. mutagen covers both. |
| **Mp3tag / puddletag 2.5.0** | Genuinely excellent regex "actions", and Mp3tag has a Mac build. But GUI-driven over a mounted share, no version control, no dry-run artefact. **Use to prototype the rules on 20 files; don't use for the bulk run.** |
| **kid3-cli 3.10.1** | Legitimate headless alternative if the mutagen script feels like overkill. Scriptable, runs on the LXC, handles FLAC and MP3. Slightly awkward for conditional per-folder logic. Keep as plan B. |

### Sequencing this matters

Normalisation **must precede** Discogs matching, because beets builds its Discogs query from
`artist` + `album`. With `album="VA"` the query is useless. Roadmap ordering:

```
strip BPM → repair field mapping → set albumtype=dj → beet import -t with discogs → review
```

---

## Cover scan extraction (54 images across 27 folders)

**Recommendation: a cloud vision API with structured JSON output. Do not stand up a local
model.** Confidence: **MEDIUM** (general OCR benchmarks are solid; nobody benchmarks CD
inserts specifically — run a 5-image eval first).

Rationale:

- **Volume is 54 images, once.** Break-even for self-hosting OCR against cloud APIs sits at
  roughly 50,000–100,000 pages/month. At 54 images total, cloud is cheaper by orders of
  magnitude even before counting the hours spent standing up a GPU pipeline. The Proxmox host
  has an iGPU with a documented `amdgpu_hmm_invalidate_gfx` kernel-oops history — pointing a
  VLM at it for a one-off 54-image job is a poor risk trade.
- **CD inserts are the hard case for classical OCR.** Small stylised type over artwork, low
  contrast, multi-column, often skewed. Traditional engines (Tesseract) drop below ~60%
  accuracy on text over noisy backgrounds; VLMs hold ~85–92% and reach 98%+ on clean printed
  inserts. Tesseract is not a serious candidate here.
- Current leaders for structured extraction from complex documents are **Gemini 3 Flash**
  (cheapest at volume, tops the OCR Arena leaderboard early 2026) and **Claude Opus 4.6**
  (leads on complex *structured* extraction — which is what a tracklist is: ordered
  number/title/artist/duration tuples, not free text). Either is fine at this volume.

**The two traps, both of which apply directly:**

1. **Hallucination, not misrecognition.** A VLM that recognises the album may emit a
   canonical tracklist it "knows" rather than the one printed on the scan. This is
   qualitatively worse than OCR noise because the output is plausible. Mitigation: ask for
   verbatim transcription plus a confidence flag, and **cross-check every extracted tracklist
   against the Discogs release** for that issue. The scans and Discogs agreeing is the signal;
   either alone is not.
2. **Confusables in track numbers and times** — `l↔1`, `O↔0`, `rn↔m`. Track *numbers* are the
   highest-consequence field (they drive file ordering) and the easiest to sanity-check:
   assert the extracted numbers form a contiguous 1..N sequence.

Preprocess before sending: deskew, contrast-normalise, upscale. Cheap, and measurably improves
accuracy on jewel-case scans.

Output target: JSON per folder (`{track, title, artist, bpm, duration}`), stored beside the
audio, then fed into `beet import --set` / the `edit` plugin. Do not let the model write tags
directly.

**Deferred, not rejected:** if this becomes a recurring workflow (hundreds of scans a month),
revisit **PaddleOCR-VL** or **GLM-OCR** locally — both beat frontier models on raw OCR
benchmarks and are open-weight. Not for 54 images.

---

## Music Assistant on HAOS: mounting the library

Verified against `home-assistant/supervisor` source, the HAOS docs, the Music Assistant
filesystem-provider docs, and the MA add-on `config.yaml`.

### Recommendation: NFS export from Proxmox → HAOS **Settings → System → Storage** (usage: **Media**, read-only) → MA **Local Directory** provider at `/media/<name>`

Confidence: **HIGH** on mechanism, **MEDIUM** on the permissions specifics (untested against
this ZFS dataset).

**Why this path and not the alternatives:**

- The MA add-on (`music_assistant` v2.9.13; server 2.10.0rc1 in prerelease) declares
  `map: [media:rw, ssl:ro]`, so anything HAOS mounts under `/media` is directly visible to
  Music Assistant. No add-on-side configuration needed.
- **NFS over SMB/CIFS**, for two reasons specific to this estate:
  - **Case sensitivity.** The library is written by beets/Jellyfin on Linux, mixed case, on
    ZFS with default `casesensitivity=sensitive`. NFS preserves that; CIFS case-folds and can
    collide or mis-resolve paths.
  - MA's own docs state that **emoji and other special characters in file/folder names are
    not supported on SMB/CIFS shares**. Music filenames hit this.
- **HAOS network storage over MA's own remote provider.** MA's add-on does carry
  `privileged: [SYS_ADMIN, DAC_READ_SEARCH]` and MA does ship native NFS/SMB/WebDAV providers,
  so mounting inside MA would work. But it duplicates the mount, and both MA's docs and
  general container practice prefer host-level mount + bind. Keep MA's remote provider as the
  fallback if the HAOS mount misbehaves.

### The gotchas that will actually bite

**1. HAOS gives you no mount options.** From `supervisor/mounts/mount.py`, the NFS mount
options are hardcoded:

```python
class NFSMount(NetworkMount):
    @property
    def options(self) -> list[str]:
        return super().options + ["softerr", "timeo=100", "retrans=2"]
```

where `super().options` is `["ro"] if self.read_only else []`, plus `port=` if set. **There is
no `uid=`, no `gid=`, no `vers=`, no `nfsvers=`.** Consequences:

- **All uid/gid mapping must be solved server-side on the Proxmox host.** Unlike CIFS (where
  `uid=`/`file_mode=` at mount time paper over ownership mismatches), NFS has no client-side
  override available here.
- NFS version is whatever the kernel negotiates. If the export must be pinned to a version,
  pin it in `/etc/exports` on the Proxmox side.

**2. `root_squash` + restrictive modes = a mount that succeeds and then lists nothing.**
HAOS mounts as root. A default Linux export applies `root_squash`, mapping that to `nobody`.
Two workable configurations, given the `apps:apps` (568:568) service account:

```
# Option A — keep world-read, let root_squash squash harmlessly. Simplest.
/mnt/tank/media/Music  <haos-ip>(ro,sync,no_subtree_check,root_squash)
# requires: dirs 0755, files 0644, owner 568:568
```

```
# Option B — force every client identity to the service account. Most explicit.
/mnt/tank/media/Music  <haos-ip>(ro,sync,no_subtree_check,all_squash,anonuid=568,anongid=568)
```

Prefer **A** if the tree is already world-readable (it is, if `chown -R 568:545` +
default modes were applied per the repo's rsync gotcha). Prefer **B** if modes are tightened
later. Avoid `no_root_squash` — it grants the HAOS box root on the dataset for no benefit,
since the mount is read-only.

**3. `acltype=nfsv4` on ZFS does not export NFSv4 ACLs.** The Linux in-kernel NFS server does
not translate ZFS NFSv4 ACLs onto the wire; the client sees POSIX mode bits only. So the ACLs
that break `rsync -a` (documented in `beets.md`) are **not** what governs MA's access — the
mode bits are. This is good news: it means the fix is ordinary `chmod`, not ACL surgery.

**4. Export read-only, deliberately.** MA needs write access only to create/edit playlists.
Read-only removes any path by which MA can modify the library Jellyfin also reads, and removes
a second writer from a tree that already has Jellyfin writing `.nfo`/`.jpg`/`.lrc` into it
(`SaveLocalMetadata: true`). Put MA playlists elsewhere.

**5. Use the IP, not the hostname**, in the HAOS storage form — HAOS has no guaranteed
resolver for a Proxmox hostname, and a DNS failure presents as a silently dead mount.

**6. MA requires `albumartist`.** Music Assistant's filesystem provider catalogues on the
Album Artist tag; files without it need explicit MA configuration to appear correctly. Any
tagging pipeline output must set `albumartist` — beets does by default, but the `-A` as-is
imports for bucket C will not unless the source tags carry it. **Add this to the phase
verification: not "files landed on disk" but "MA shows the album under the right artist".**

**7. Prerequisite: HAOS ≥ 10.2** for the network-storage feature. Current HAOS is 18.2
(30 Jul 2026), so this is satisfied.

---

## Installation

```bash
# --- beets on LXC 100 (compose), replacing the two existing definitions ---
# image: lscr.io/linuxserver/beets:2.13.1     (published 2026-08-14)
# NOT :latest — LSIO also publishes a :nightly stream against beets master

# Inside the container / venv, for the Discogs source:
pip install "beets[discogs]"

# --- normalisation tooling on the LXC ---
pip install mutagen==1.48.1
apt-get install -y kid3-cli    # 3.10.1, optional plan B

# --- wrtag: EITHER fix the pin, OR remove the stack entirely ---
# If keeping temporarily for a comparison spike:
#   image: sentriz/wrtag:v0.33.0     <-- existing WRTAG_PATH_FORMAT works unchanged
#   and drop the Renovate rule pinning <0.30.0
```

Minimum viable `plugins:` list for this project's beets config:

```yaml
plugins:
  - musicbrainz     # REQUIRED since 2.4.0 — omitting it silently disables autotagging
  - discogs         # the DJ-service source
  - fromfilename
  - edit
  - zero
  - fetchart
  - embedart
  - scrub
  - importsource    # makes a 7,451-file import resumable
  - duplicates
  - albumtypes

discogs:
  user_token: "<personal access token>"   # OAuth flow is unworkable in a container
  extra_tags: [catalognum, label, year]   # sharpens matching on DJ-service catalogue numbers
  search_limit: 10                        # default 5 is thin for VA compilations

match:
  preferred:
    countries: ['GB', 'US']               # the Now! series fix from beets.md
```

**Also fix, per the finding above:** `stacks/selfhosted/arrs/soulbeet/beets_config.yaml`
currently declares a custom `plugins:` list of `[fetchart, embedart, lastgenre, scrub,
replaygain, missing, duplicates]` with **no `musicbrainz`**. On beets ≥ 2.4.0 that config has
no metadata source at all — autotagging cannot succeed. This is a plausible contributor to the
`audio.bash` "skip" outcomes and should be verified as part of resolving that requirement.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| beets 2.13.1 | **wrtag 0.33.0** | If the spike shows Discogs coverage of `dj-mixes` is poor (< ~40%), *and* the interactive prompt proves to be the blocker. wrtag's notify/confirm web queue and `wrtag sync` are genuinely better for a hands-off, MusicBrainz-only library. Cost: DJ content becomes 100% manual. |
| beets `discogs` plugin | **beetcamp 0.24.3** (Bandcamp) | Not relevant to this collection — DJ service releases aren't on Bandcamp. Worth knowing it exists if the library grows toward electronic/indie. |
| mutagen script | **kid3-cli 3.10.1** | If per-folder conditional logic turns out simpler than expected and a shell loop suffices. |
| mutagen script | **Mp3tag (Mac) actions** | For *prototyping* the field-mapping rules interactively on ~20 files before encoding them. Not for the 794-file run. |
| Cloud vision API | **PaddleOCR-VL / GLM-OCR local** | If scan extraction becomes recurring at thousands of images. At 54 images, no. |
| NFS to HAOS | **SMB/CIFS to HAOS** | If the Proxmox NFS export can't be made to work. Accept case-folding and no-emoji limitations; SMB 3.0+ only (HAOS requires CIFS ≥ 2.1). |
| HAOS network storage | **MA's own NFS/SMB provider** | If the HAOS `/media` mount misbehaves. The add-on has `SYS_ADMIN` + `DAC_READ_SEARCH` so it can mount internally. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `sentriz/wrtag:v0.20.0` (current pin) | v0.20.0 hard-sets `Track.Position = -1`, so the repo's path format names every file `-1 - Title.ext`. Also references `.Media`, absent from v0.20's `Data` struct → runtime error on any multi-disc release. Startup validation does not catch either | `v0.33.0` — the existing path format is already correct for it |
| Renovate rule pinning wrtag `<0.30.0` | It is enforcing the broken state. It was added on a misdiagnosis (2026-06-24, "v0.30.0 broke path-format") | Remove the rule; or remove wrtag entirely |
| beets config with a custom `plugins:` list omitting `musicbrainz` | Since 2.4.0 this silently disables all MusicBrainz autotagging. Symptom looks like "no match found", not like a config error | Always list `musicbrainz` explicitly |
| `lscr.io/linuxserver/beets:latest` or `:nightly` | LSIO publishes a `nightly` stream tracking beets **master**, updated daily. A floating tag on a tool that writes to 34 GB of library is not a risk worth taking — and this repo already has a documented Renovate deploy-drift problem | `lscr.io/linuxserver/beets:2.13.1` |
| Tesseract for the cover scans | Accuracy falls below ~60% on text over artwork backgrounds; CD inserts are the worst case for classical OCR | A VLM (Gemini 3 Flash / Claude Opus 4.6) |
| beets `substitute` plugin for tag repair | Explicitly does not modify metadata — path templates only | `beet modify` / `zero` / the mutagen script |
| beets `rewrite` / `advancedrewrite` for the DJ field remap | Rewrites values within a field; cannot move a value between fields, cannot express per-folder permutations | The mutagen script |
| MusicBrainz Picard 3.0.0bX | Still beta as of Aug 2026 (b9, 11 Aug). Stable is 2.13.3 from Feb 2025 | Not needed at all — beets covers this |
| Trusting a MusicBrainz match on any Mastermix/DMC folder without checking track count | MB entries for these labels exist but are frequently 5–10-track stubs against 15–20-track releases. A confident wrong match is the worst outcome | `beet import -t` (timid) on every bucket C folder, verify track count |
| `no_root_squash` on the NFS export | Grants HAOS root on the dataset for zero benefit on a read-only mount | `root_squash` + world-read, or `all_squash,anonuid=568,anongid=568` |
| Staging anything under `/media/Music` before it's tagged | Jellyfin's `SaveLocalMetadata: true` writes `.nfo`/`.jpg`/`.lrc` within minutes, permanently polluting the folder | Stage in `downloads/complete/nzb/` (already documented in `beets.md`) |

---

## Stack Patterns by Variant

**Bucket A — mainstream albums (autotags cleanly):**
- beets + `musicbrainz`, standard `beet import`, `import.copy` not `move` on first pass
- `importsource` enabled so an interrupted run is resumable
- This is the proof-of-pipeline phase; do not enable `discogs` here (extra API calls, extra
  candidates, more prompts, no benefit)

**Bucket B — *Now That's What I Call Music*:**
- `match.preferred.countries: ['GB','US']`, `beet import -t`
- Split the 45 GB `1-115` set per volume before pointing beets at anything
- Verify track listing against the UK/US split before accepting each

**Bucket C — DJ service releases:**
- Normalise tags first (mutagen script), then `beet import -t` with `discogs` enabled
- `--set albumtype=dj` + `paths: albumtype:dj:` to keep them out of `Compilations/`
- For the 27 folders with scans, extract the tracklist via VLM and cross-check against Discogs
- For folders with neither Discogs entry nor scan: `beet import -A` after normalisation is the
  floor — correct-but-minimal beats untagged

**If the spike overturns the recommendation (wrtag wins):**
- `sentriz/wrtag:v0.33.0`, existing path format unchanged, Renovate pin removed
- Buckets A/B via `wrtagweb` queue; bucket C entirely manual/scan-driven
- Accept that this leaves two workflows, which conflicts with the stated core value — so the
  bar for overturning should be high

---

## Version Compatibility

| Package | Compatible With | Notes |
|-----------|-----------------|-------|
| beets 2.13.1 | Python `>=3.10,<3.15` | Verified on PyPI. The LSIO image handles this |
| beets 2.13.1 | mutagen (bundled dep) | Standalone mutagen 1.48.1 writes tags beets reads identically |
| beets ≥ 2.4.0 | `plugins:` lists | **Breaking for this repo:** `musicbrainz` must be listed explicitly in any customised list |
| beets 2.13.0 | `beet modify` `+=` / `-=` | New in 2.13.0 — multi-valued field edits without replacing the whole field |
| wrtag v0.30.0+ | path formats using `.TrackNum` / `len .Tracks` / `.Tracks` | Breaking. **Not used by this repo's format** |
| wrtag v0.33.0 | `.IsCompilation`, `.ReleaseDisambiguation` | Still supplied via `withLegacyFields()`. Deprecated in favour of `isCompilation` / `disambiguation` helpers |
| wrtag v0.20.0 | this repo's `WRTAG_PATH_FORMAT` | **Incompatible** — see headline finding 1 |
| HAOS 18.2 | Network storage (NFS + CIFS ≥ 2.1) | Requires HAOS ≥ 10.2; satisfied |
| MA add-on 2.9.13 | `/media/*` from HAOS network storage | `map: [media:rw]` in add-on config |
| ZFS `acltype=nfsv4` | Linux knfsd export | NFSv4 ACLs are not exported; clients see mode bits only |

**Unverified edge case worth a 5-minute check during the spike:** `{{ .Release.Date.Year }}`
on a release with no date. `Release.Date` is `AnyTime{time.Time}`; the zero `time.Time` has
`Year() == 1`, so undated releases would render `(1)` in the path. DJ service releases are
frequently undated in MusicBrainz. Only relevant if wrtag survives the spike.

---

## Sources

- `github.com/sentriz/wrtag` tagged source at `v0.20.0` and `v0.33.0` — `pathformat/pathformat.go`,
  `musicbrainz/musicbrainz.go`, `README.md`; GitHub Releases API for the v0.30.0 BREAKING CHANGES
  table and the v0.20.0…v0.30.0 commit range — **HIGH**
- MusicBrainz WS/2 API, live exact-title release queries for Mastermix / DMC / Music Factory /
  Pro Disc across issue numbers 300–444 — **HIGH**
- Discogs API `database/search`, live queries for the same issue numbers — **HIGH**
- `github.com/beetbox/beets` — `docs/changelog.rst` (2.0.0 → unreleased), `docs/plugins/*.rst`
  (discogs, rewrite, advancedrewrite, substitute, zero, edit, fromfilename, importsource),
  `beetsplug/` directory listing; PyPI + GitHub Releases for 2.13.1 — **HIGH**
- `github.com/home-assistant/supervisor` — `supervisor/mounts/mount.py` (`NFSMount.options`,
  `CIFSMount`, `NetworkMount.read_only`) — **HIGH**
- `github.com/music-assistant/home-assistant-addon` — `music_assistant/config.yaml`
  (`map: media:rw`, `privileged: SYS_ADMIN, DAC_READ_SEARCH`, v2.9.13) — **HIGH**
- Docker Hub tag APIs for `sentriz/wrtag` and `linuxserver/beets`; PyPI for mutagen/eyeD3/beetcamp;
  GitHub Releases for KDE/kid3, puddletag, metabrainz/picard, home-assistant/operating-system — **HIGH**
- https://www.home-assistant.io/common-tasks/os/ — network storage protocols, usage types,
  HAOS ≥ 10.2 requirement — **HIGH**
- https://www.music-assistant.io/music-providers/filesystem/ — Local/SMB/NFS/WebDAV providers,
  UTF-8 and emoji limitation on CIFS, Album Artist requirement — **HIGH**
- Web search synthesis on 2026 OCR/VLM landscape (OCR Arena leaderboard positions, PaddleOCR-VL
  and GLM-OCR OmniDocBench scores, VLM-vs-traditional accuracy on noisy backgrounds, self-host
  break-even volumes) — **MEDIUM**; no source benchmarks album artwork specifically
- HAOS/NFS permission behaviour (root_squash symptoms, absence of client-side uid mapping on
  NFSv4) — **MEDIUM**; mechanism confirmed from Supervisor source, symptoms from community reports

---
*Stack research for: self-hosted music library tagging and organisation*
*Researched: 2026-08-17*
