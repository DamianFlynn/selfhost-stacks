# Music Library Consolidation

## What This Is

The music tagging pipeline for the Deer Crest selfhost estate. Four tagging entry points were
built over time and three are dead; meanwhile 97 GB of downloaded music sits untagged in
`downloads/complete/nzb/`, against a 34 GB tagged library at `/mnt/tank/media/Music` that
Jellyfin reads. This project picks one tagger, retires the rest, and starts working the backlog
down — beginning with the content that autotags cleanly.

Tracked in GitHub issue #305. Related: #306 (soulbeet), #307 (rybbit).

## Core Value

**New music downloads land in the library correctly tagged, through exactly one pipeline that
someone owns.** Everything else — the historic backlog, the DJ collection, the duplicate
reconciliation — is worth doing but secondary. The reason this project exists is that the
pipeline was built three times and abandoned three times; a fourth half-built path is the one
outcome that must not happen.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] One tagger chosen on evidence from a real sample of this library's content
- [ ] The other taggers retired — definitions removed, Renovate pins released, docs corrected
- [ ] `audio.bash` beets tagging resolved — fixed or turned off, not left silently skipping
- [ ] Known config gaps closed: `match.preferred.countries` for the *Now!* series, `fromfilename`
      and `edit` plugins for DJ content
- [ ] Bucket A (mainstream albums) imported end-to-end and visible in Jellyfin — proof the
      pipeline works before scaling it
- [ ] Bucket D triaged — junk, `_FAILED_`/`_UNPACK_`, stray `.rar`, and misfiled non-music
      (a Harry Potter BluRay rip is currently in `dj-mixes`)
- [ ] The 85 duplicate folder names between `dj-mixes` and `unsorted` investigated and resolved
- [ ] DJ content on its own library path, not mixed into `Compilations/`
- [ ] DJ metadata normalised — field mapping repaired across releases
- [ ] DJ artwork/tracklists sourced for releases that have neither tags nor local scans
- [ ] **Music Assistant reads the same library** — the store mounted from the NUC (HAOS) so the
      tagged tree is playable there, not just in Jellyfin. Phase verification must confirm
      Music Assistant sees the content, not only that files landed on disk.

### Out of Scope

- **Clearing the entire 97 GB backlog** — the goal is a working pipeline plus bucket A proven.
  Buckets B and C become routine work at Damian's own pace, not a project deliverable.
- **Re-importing the existing 34 GB tagged library** — it is already correct and Jellyfin reads
  it. Reconciling the separate beets `library.db` files would mean re-importing one side; treat
  as a known hazard, not a task.
- **Lidarr replacement** — Lidarr stays as the acquisition front end. This project is about what
  happens to files after they land.

## Context

**The four entry points, and why three are dead** (all verified on the host 2026-08-17):

| Entry point | Defined in | State |
|---|---|---|
| `beets` (manual) | `arrs/beets/beets.yaml` | Last import **18 Nov 2025**. `library.db` untouched since. Profile-gated, runs only when invoked. |
| `soulbeet` | `arrs/soulbeet.yaml` | Image `ghcr.io/terry90/soulbeet` **gone from GHCR**. Never deployed. Issue #306. |
| `wrtag` | `music/wrtag.yaml` | Container up, `wrtag.db` unchanged since **23 Jan 2026**. Pinned `<0.30.0` by a Renovate rule blocking a `WRTAG_PATH_FORMAT` rewrite. |
| `audio.bash` beets | sabnzbd post-proc, `music` category | Runs per download, but `rm`s its own `library.blb` each run (stateless by design) and imports `-q` in place. Last two jobs (1 Aug, 8 Aug) both logged `skip`. **Cause now known:** `/config/scripts/beets-config.yaml` declares `plugins: embedart` and nothing else — since beets 2.4.0 MusicBrainz is a plugin, so that config has *no metadata source at all* and every album must skip. Do not "fix" this with `quiet_fallback: asis`. |
| **Lidarr** *(added 2026-08-17)* | `arrs/lidarr.yaml` | **The fifth writer, never counted.** Root folder is `/media/Music` with `renameTracks: True` — it has been actively renaming files inside the shared library tree. |

**The backlog:**

| Location | Files | Size | Tagged? |
|---|---|---|---|
| `downloads/complete/nzb/unsorted` | 7,451 | 97 G | no |
| `downloads/complete/nzb/dj-mixes` | 794 | 25 G | partially — see below |
| `downloads/complete/nzb/music` | 275 | 18 G | no — Lidarr inbox, has `_FAILED_`/`_UNPACK_`/`.rar` |
| `media/Music` (13 artist folders) | 1,244 | 34 G | yes — the Jellyfin source |

**The DJ content is a normalisation problem, not an acquisition problem.** Sampling 8 tracks
across `dj-mixes` found 7 tagged — but with the field convention differing between releases in
the same series:

```
artist="R'n'b Hits 1990-1999 Pt.1 108"  album="VA"                  title="Mastermix_Issue_444 WEB"
artist="Various"                        album="Mastermix Issue 433"  title="Yacht Soul 1 100"
artist="Mastermix Issue 430"            album="Pop Hits 2 119"       title="Mastermix"
```

Trailing numbers are BPM baked into titles, DJ convention. This matters because `beet import -A`
— the approach `beets.md` prescribes for DJ content — preserves existing tags, which would
faithfully preserve the wrong mapping.

**Cover scans exist, but for a minority.** 27 of 85 `dj-mixes` folders contain any image
(54 files total). Where present they carry full tracklistings and are more reliable than any
autotagger. Where absent, artwork and tracklists can be sourced externally — Internet Archive,
or the Mastermix / Music Factory services directly.

**Two consumers, not one.** `/mnt/tank/media/Music` is currently the Jellyfin source only.
Music Assistant — running on the NUC under Home Assistant OS, a separate box from the Proxmox
host — must read the same store. That makes "tagged correctly" insufficient as a success test:
a phase is only done when the content is visible in **both** Jellyfin and Music Assistant.

**The mount route is an OPEN QUESTION** *(corrected 2026-08-17 — previously asserted as fact)*.
HAOS is a locked-down appliance OS so fstab is out, but the two candidate routes conflict between
primary sources: HA Supervisor's own source supports Settings → System → Storage with usage Media
(and the MA add-on maps `media:rw`), while Music Assistant's documentation states verbatim that a
folder cannot be mounted from HA into `/media` and points to its "Filesystem (remote share)"
provider instead. Phase 2 settles this empirically on three albums, with route B pre-specified so
a failure does not stall the phase. Both routes need the same NFS export, so that work is not
blocked by the answer.

**Prior art:** `stacks/selfhosted/arrs/beets.md` already documents the library state, the A–D
bucket triage, the two config gaps, and the hard-won gotchas. This project executes and extends
that plan rather than restating it.

## Constraints

- **Storage semantics**: `import.move: yes` is currently set — a bulk run *moves* files out of
  the source rather than copying. First passes must switch to `copy`; `tank` has 9 T free, so
  the duplication is affordable and reversible.
- **Filesystem**: `rsync -a` fails writing to `tank` (`mkstemp ... Operation not permitted`) due
  to `acltype=nfsv4` + `aclmode=restricted` (confirmed on both `tank/media` and `tank/downloads`),
  while printing stats that look like success and exiting 23. Use `rsync -rlt --no-p --no-o --no-g`.
- **Ownership is undecided, not merely inconsistent** *(corrected 2026-08-17)*: 12 of 13 artist
  folders are `apps:nogroup` (**568:65534**), one is `apps:apps` (**568:568**) — matching neither
  `beets.md`'s `568:545` nor `CLAUDE.md`'s `568:568`. Something has been writing with an unmapped
  gid. The value must be *decided* and normalised, not assumed, because it also sets `anonuid`/
  `anongid` on the NFS export. Note ZFS `acltype=nfsv4` ACLs are not exported by knfsd, so mode
  bits govern access over NFS — the lever is `chmod`, not ACL surgery.
- **Jellyfin side effects**: `SaveLocalMetadata: true` means Jellyfin writes `.nfo`/`.jpg`/`.lrc`
  into any folder placed under `/media/Music` within minutes. Never stage untagged content there.
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

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Tagger choice deferred to a spike phase | beets and wrtag both plausible; decide on evidence from a real sample rather than argument | — Pending |
| Done = pipeline fixed + bucket A imported | The failure mode here is abandonment, not slowness. A provable win beats an open-ended import marathon | — Pending |
| DJ content gets its own library path | Keeps `Compilations/` clean for genuine various-artist albums | — Pending |
| DJ metadata: normalise tags *and* extract scans, as separate phases | Tags cover all 85 folders but are misaligned; scans cover 27 folders but are authoritative | — Pending |
| External sourcing for releases with neither | Internet Archive / Music Factory direct, rather than leaving them untagged | — Pending |
| Duplicates investigated before deduping | Sizes differ in both directions across the 85 shared names — neither side is automatically authoritative | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-08-17 after initialization*
