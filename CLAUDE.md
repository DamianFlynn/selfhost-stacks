# CLAUDE.md

Repository guidance for code agents and maintainers.

## Documentation

- **[NETWORK.md](NETWORK.md)**: Complete network infrastructure map, all hosts, IPs, access methods, and cleanup tasks
- **[TAILSCALE.md](TAILSCALE.md)**: Tailscale low-level design — tailnet topology, the four
  deployment patterns (UCG-Max `tailscale-udm`, HAOS add-on, `tsbridge`, stock clients), dual
  subnet routers and failover, failure modes, and the recovery runbook

## Scope Split

- `infra/`: Terraform for Proxmox host setup + workload provisioning
- `stacks/`: Docker Compose stack definitions deployed to LXC `100` (`selfhost`)

## Platform

- Hardware: Minisforum NS5Pro
- Proxmox host "atlantis": `172.16.1.158` (Proxmox VE 9.1)
- LXC `100` (`selfhost`): `172.16.1.159` (main Docker host - 103 containers as of 2026-09-03)

## Infrastructure Warnings

- **`terraform apply` in `infra/` can destroy LXC 100.** A bare apply has planned `1 to destroy` on
  the Docker host and its ~100 containers. Guarded by `prevent_destroy` + `ignore_changes` — which
  also means genuine bind-mount edits plan clean and do nothing. Always read the plan.
- **Jellyfin hardware transcoding is OFF deliberately** (`HardwareAccelerationType: none`). This is
  the D-30 amdgpu mitigation after the 2026-08-31 outage (~6 h). Do not re-enable it. High CPU
  during a Jellyfin transcode is correct. See README § GPU Hardware Acceleration.
- **Jellyfin is exposed LAN-wide at `172.16.1.76:8096`** via `iot_macvlan`, and is *not* reachable
  from LXC 100 itself. It publishes no host port, but that is not a security control — see
  NETWORK.md § Notable host ports.

## Infrastructure Rules

- Terraform is authoritative for host/LXC/VM resources.
- Do not manually drift critical Proxmox config Terraform manages.
- Keep provisioning logic in `infra/` only.

## Stack Rules

- Keep selfhosted compose stacks under `stacks/selfhosted/<stack>/`.
- `stacks/selfhosted/traefik/compose.yaml` defines shared proxy network(s).
- Stack ops run from repo root at `/mnt/fast/stacks`.
- Cerebro VM stacks archived to agent-os/Archives (no longer managed here).

## Common Commands

```bash
# Terraform
cd infra
terraform plan
terraform apply

# Compose
ssh root@172.16.1.159
cd /mnt/fast/stacks
docker compose -f stacks/selfhosted/traefik/compose.yaml up -d
docker compose -f stacks/selfhosted/arrs/compose.yaml up -d
```

## Storage and Permissions

- Repo path on host/LXC: `/mnt/fast/stacks`
- Appdata path: `/mnt/fast/appdata`
- Transcode cache: `/mnt/fast/transcode` — its own ZFS dataset `fast/transcode`, **50 G `quota`**
  (not `refquota` — `quota` counts descendants and returns `ENOSPC`, the errno this estate's log
  greps key on). Declared in `infra/jellyfin-transcode-dataset.tf`; bound into Jellyfin at
  `/cache/transcodes`. Exists because an anonymous Docker volume put 19 GB of transcode cache on
  `/` and emptied it.
- Service account: `apps:apps` (`568:568`)
- GPU groups: `video:44`, `render:110`

## Health Checks

`scripts/quick-health-check.sh` from the workstation is the single entry point; it folds in
`check-music-freeze.sh`, `check-music-consumers.sh` and `check-jellyfin-transcode.sh`. Exits 0
healthy, 1 on any violation. `REMOTE_TIMEOUT` (default 120s) bounds every remote command.

When adding a check, follow the three rules in README § Health Checks: fail closed with "could not
look" kept distinct from "nothing is wrong"; bound remote commands **Linux-side** (macOS has no GNU
`timeout`); and assert rather than report. Note `timeout N cmd | wc -l` silently exits 0 — the
remote string needs `set -o pipefail` and the ssh RC must be read.

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Music Library Consolidation**

The music tagging pipeline for the Deer Crest selfhost estate. Four tagging entry points were
built over time and three are dead; meanwhile 97 GB of downloaded music sits untagged in
`downloads/complete/nzb/`, against a 34 GB tagged library at `/mnt/tank/media/Music` that
Jellyfin reads. This project picks one tagger, retires the rest, and starts working the backlog
down — beginning with the content that autotags cleanly.

Tracked in GitHub issue #305. Related: #306 (soulbeet), #307 (rybbit).

**Core Value:** **New music downloads land in the library correctly tagged, through exactly one pipeline that
someone owns.** Everything else — the historic backlog, the DJ collection, the duplicate
reconciliation — is worth doing but secondary. The reason this project exists is that the
pipeline was built three times and abandoned three times; a fourth half-built path is the one
outcome that must not happen.

### Constraints

- **Storage semantics**: `import.move: yes` is currently set — a bulk run *moves* files out of
  the source rather than copying. First passes must switch to `copy`; `tank` has 9 T free, so
  the duplication is affordable and reversible.
- **Filesystem**: `rsync -a` fails writing to `tank` (`mkstemp ... Operation not permitted`) due
  to `acltype=nfsv4` + `aclmode=restricted` (confirmed on both `tank/media` and `tank/downloads`),
  while printing stats that look like success and exiting 23. Use `rsync -rlt --no-p --no-o --no-g`.
- **Ownership is DECIDED and normalised** *(resolved 2026-08-18 by Phase 1 plan 01-08; supersedes
  the 2026-08-17 "undecided" reading)*: the library is **`568:568` (`apps:apps`)** across all 2,674
  entries, library root included, verified from the Proxmox host and by `zfs diff`. Chosen because
  `568` is `apps` — stated independently in `STANDARDS.md:141`, `DEPLOYMENT.md:31`, `README.md:29`
  and this file — while the gid it replaced, **545, is an orphan**: `getent group 545` returns
  nothing on atlantis. **Modes are the unresolved half: everything is `0777` and stays that way.**
  `chmod` fails `EPERM` on `tank` even as real root, because `aclmode=restricted` +
  `aclinherit=passthrough` gives even new files a non-trivial NFSv4 ACL; the target of `0755`/`0644`
  is recorded but not achieved, and forcing it means `zfs set aclmode=passthrough`, which rewrites
  the ACL on every entry. Phase 2's export inherits `568:568` as `anonuid`/`anongid`, and since ZFS
  `acltype=nfsv4` ACLs are not exported by knfsd, **mode bits are the only lever NFS clients see** —
  so with the tree world-writable the export must be read-only.
  *How the drift happened, kept because it is the signal to watch for:* the earlier reading of
  `apps:nogroup` (`568:65534`) was **LXC 100's view, not the disk**. The container is unprivileged
  with a sparse idmap, so unmapped on-disk ids surface as `65534` — `0:545` and `568:545` both
  collapsed. If `65534` reappears in a container-side listing, check from atlantis before believing
  it. `/mnt/tank/media/TV` still carries 114,218 entries on gid 545 and is deliberately untouched.
- **Jellyfin side effects** *(updated 2026-08-18 by plan 01-06)*: `SaveLocalMetadata`, real-time
  monitoring and `SaveLyricsWithMedia` are now **off for the Music library and permanently so**;
  Movies and TV keep theirs. Still never stage untagged content under `/media/Music`: the freeze
  gates the *automatic* save path only — an explicit "Refresh metadata" (`FullRefresh`) still
  writes, and did rewrite 83 of the library's 91 `.nfo` when tested.
- **Autotagging ceiling** *(corrected 2026-08-17 after research)*: MusicBrainz coverage of these
  labels stops around 2016 (~46 entries: 18 `Mastermix Issue`, 19 `DMC Commercial Collection`,
  9 `Music Factory Mastermix`; `Crate` and `Toolkit` are genuinely zero) and **excludes this
  backlog** — issues 430/433/441/444 all return nothing. Worse, surviving entries are often 5–10
  track *stubs* against 15–20 track releases, so a confident wrong match is more likely than no
  match. **Discogs carries 430, 433 and DMC 350 outright** and is the correct source for this
  content. Never accept a match without a track-count check.
- **Storage layout**: `/mnt/tank/downloads` and `/mnt/tank/media/Music` are **separate ZFS
  datasets**. Every library "move" is copy-then-unlink, not an atomic rename — interruptible, needs
  transient double space, and `cp --reflink` fails `EXDEV` across them despite
  `feature@block_cloning` being active on the pool. Reflink only helps *within* `tank/downloads`,
  which is why staging belongs there.
- **Reversibility**: **beets has no `undo` command** — verified against the live CLI. Backing up the
  `library.db` files is necessary but insufficient: take a `zfs snapshot` of `tank/media/Music` in
  the *same step*, because rolling back only the tree leaves `incremental` state claiming the work
  is done. Add the `ffprobe` tag-dump of `dj-mixes` and the cover-scan archive to the same fence.
- **ZFS**: frees space asynchronously; `zfs list` can lag a large delete by ~20 s.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Headline: three findings that change the plan
### 1. The wrtag version pin is inverted — v0.20.0 is the *broken* one, not v0.30.0
| v0.2x | v0.30.0 | Notes |
|---|---|---|
| `.TrackNum` | `.Track.Position` | Now uses MusicBrainz's real per-disc position |
| `len .Tracks` | `.Media.TrackCount` | Track count is per-medium, not total |
| `.Tracks` | *(removed)* | |
| — | `.Media` | *(new)* current medium |
| — | `.Media.Position` | *(new)* disc number |
### 2. MusicBrainz *does* carry these DJ services — partially, and that is worse than absence
| Query (exact-title, score ≥ 95) | Result |
|---|---|
| `Mastermix Issue 300` | Hit — 7 tracks, 2011-06 |
| `Mastermix Issue 366` | Hit ×2 — 5 tracks (2016) and 10 tracks (2016-12) |
| `Mastermix Issue 380 / 400 / 420 / 430 / 433 / 444` | **No exact hit** |
| `DMC Commercial Collection 289` | Hit — 9 tracks |
| `DMC Commercial Collection 350 / 400` | **No exact hit** |
| `Mastermix: Pro Disc 101` | Hit — 21 tracks |
| `Music Factory Mastermix Issue 003` | Hit — 15 tracks |
- The **coverage stops around 2016** and the collection's issues (430, 433, 444) are past it.
- Where entries exist they are frequently **stubs**: 5–10 tracks against real issues that run
### 3. Discogs has the exact releases MusicBrainz lacks
| Query | Discogs result |
|---|---|
| `Mastermix Issue 433` | `Various – Issue 433` (2022), label **Music Factory Mastermix Issue**, File/WAV and File/MP3 editions |
| `Mastermix Issue 430` | `Various – Mastermix Issue 430` (2022), label Music Factory Mastermix Issue |
| `DMC Commercial Collection 350` | `Various – Commercial Collection 350` (2012), label DMC |
| label `Mastermix` | 4+ label entities incl. `Mastermix Productions`, `Mastermix Productions Ltd` |
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
## The beets vs wrtag head-to-head
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
### Evidence that would overturn this — test these in the spike
| Overturning evidence | Why it flips the decision | How to test |
|---|---|---|
| **Discogs matches < ~40% of `dj-mixes` folders** even after tag normalisation | beets' only structural advantage evaporates; DJ metadata comes from scans/manual either way, and wrtag's speed + import UI win on buckets A/B | Normalise tags on 20 folders, then `beet import -t` with `discogs` enabled; count folders where a Discogs candidate appears at all |
| **Discogs rate limiting makes bulk import impractical** (60 req/min authenticated) | 7,451 files across ~1,000 folders is hours of wall-clock even before think time | Time 20 folder imports with `discogs` enabled; extrapolate |
| **Damian will not sit at an interactive prompt** | beets bucket B/C work is inherently interactive; wrtag's notify-and-confirm queue is a better fit for "do it later, from a phone" | Honest self-assessment, not a measurement. If the answer is no, the plan needs wrtag for A/B and manual/scan work for C — two tools, which contradicts the core value |
| **wrtag v0.33.0 clears bucket A materially faster with equal accuracy** | If A is 80% of the *files*, throughput on A might outweigh source coverage on C | Run both over the same 30 mainstream albums; compare wall-clock and count wrong matches |
## Tag normalisation for the DJ collection
### Recommendation: a Python + mutagen script, run per-folder, with a dry-run mode
- The rules are **per-folder**, not per-value. Folder 1 needs `artist → album`,
- It must be **reviewable before it writes**. 794 files, irreversible in-place edits.
- `mutagen 1.48.1` is the library beets itself uses, so tags written are guaranteed to be
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
## Cover scan extraction (54 images across 27 folders)
- **Volume is 54 images, once.** Break-even for self-hosting OCR against cloud APIs sits at
- **CD inserts are the hard case for classical OCR.** Small stylised type over artwork, low
- Current leaders for structured extraction from complex documents are **Gemini 3 Flash**
## Music Assistant on HAOS: mounting the library
### Recommendation: NFS export from Proxmox → HAOS **Settings → System → Storage** (usage: **Media**, read-only) → MA **Local Directory** provider at `/media/<name>`
- The MA add-on (`music_assistant` v2.9.13; server 2.10.0rc1 in prerelease) declares
- **NFS over SMB/CIFS**, for two reasons specific to this estate:
- **HAOS network storage over MA's own remote provider.** MA's add-on does carry
### The gotchas that will actually bite
- **All uid/gid mapping must be solved server-side on the Proxmox host.** Unlike CIFS (where
- NFS version is whatever the kernel negotiates. If the export must be pinned to a version,
# Option A — keep world-read, let root_squash squash harmlessly. Simplest.
# requires: dirs 0755, files 0644, owner 568:568
# Option B — force every client identity to the service account. Most explicit.
## Installation
# --- beets on LXC 100 (compose), replacing the two existing definitions ---
# image: lscr.io/linuxserver/beets:2.13.1     (published 2026-08-14)
# NOT :latest — LSIO also publishes a :nightly stream against beets master
# Inside the container / venv, for the Discogs source:
# --- normalisation tooling on the LXC ---
# --- wrtag: EITHER fix the pin, OR remove the stack entirely ---
# If keeping temporarily for a comparison spike:
#   image: sentriz/wrtag:v0.33.0     <-- existing WRTAG_PATH_FORMAT works unchanged
#   and drop the Renovate rule pinning <0.30.0
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
## Stack Patterns by Variant
- beets + `musicbrainz`, standard `beet import`, `import.copy` not `move` on first pass
- `importsource` enabled so an interrupted run is resumable
- This is the proof-of-pipeline phase; do not enable `discogs` here (extra API calls, extra
- `match.preferred.countries: ['GB','US']`, `beet import -t`
- Split the 45 GB `1-115` set per volume before pointing beets at anything
- Verify track listing against the UK/US split before accepting each
- Normalise tags first (mutagen script), then `beet import -t` with `discogs` enabled
- `--set albumtype=dj` + `paths: albumtype:dj:` to keep them out of `Compilations/`
- For the 27 folders with scans, extract the tracklist via VLM and cross-check against Discogs
- For folders with neither Discogs entry nor scan: `beet import -A` after normalisation is the
- `sentriz/wrtag:v0.33.0`, existing path format unchanged, Renovate pin removed
- Buckets A/B via `wrtagweb` queue; bucket C entirely manual/scan-driven
- Accept that this leaves two workflows, which conflicts with the stated core value — so the
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
## Sources
- `github.com/sentriz/wrtag` tagged source at `v0.20.0` and `v0.33.0` — `pathformat/pathformat.go`,
- MusicBrainz WS/2 API, live exact-title release queries for Mastermix / DMC / Music Factory /
- Discogs API `database/search`, live queries for the same issue numbers — **HIGH**
- `github.com/beetbox/beets` — `docs/changelog.rst` (2.0.0 → unreleased), `docs/plugins/*.rst`
- `github.com/home-assistant/supervisor` — `supervisor/mounts/mount.py` (`NFSMount.options`,
- `github.com/music-assistant/home-assistant-addon` — `music_assistant/config.yaml`
- Docker Hub tag APIs for `sentriz/wrtag` and `linuxserver/beets`; PyPI for mutagen/eyeD3/beetcamp;
- https://www.home-assistant.io/common-tasks/os/ — network storage protocols, usage types,
- https://www.music-assistant.io/music-providers/filesystem/ — Local/SMB/NFS/WebDAV providers,
- Web search synthesis on 2026 OCR/VLM landscape (OCR Arena leaderboard positions, PaddleOCR-VL
- HAOS/NFS permission behaviour (root_squash symptoms, absence of client-side uid mapping on
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
