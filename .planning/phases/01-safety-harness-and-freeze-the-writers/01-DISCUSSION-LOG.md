# Phase 1: Safety Harness and Freeze the Writers - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-17
**Phase:** 1-safety-harness-and-freeze-the-writers
**Areas discussed:** QUAL-01 snapshot design, Recovery fence location, Ownership value (WRIT-04),
Jellyfin freeze scope (SAFE-05), Who holds rw in Phases 1–3, Lidarr repoint target (WRIT-03),
Host vs repo durability, Evidence recording

All eight offered gray areas were selected for discussion.

---

## QUAL-01 snapshot design

### Identity key

| Option | Description | Selected |
|--------|-------------|----------|
| Audio-stream hash | `ffmpeg -map 0:a -c copy -f md5` over the encoded bitstream only; survives retag and rename. One full read of ~140 GB | ✓ |
| Path relative to root | Cheap and obvious; broken by Phase 5's `mv` and Phase 7's rename | |
| Path + size + duration | No full read needed, but retagging changes file size so the key mutates in exactly the case being measured | |
| MusicBrainz/AcoustID ids | Most of the backlog has no `mb_trackid`; AcoustID is explicitly Out of Scope (beets #360, compilation matching) | |

**User's choice:** Audio-stream hash

### Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Backlog + existing library | 8,520 backlog + 1,244 library = ~9,764 files, ~140 GB | ✓ |
| Backlog only | Matches the roadmap's literal wording; leaves the good 34 GB with no baseline | |
| Backlog + library + bucket-D exclusion | Saves time; requires Phase 1 to know Phase 5's junk criteria | |

**User's choice:** Backlog + existing library

### Format

| Option | Description | Selected |
|--------|-------------|----------|
| Gzipped NDJSON | One ffprobe object per line, streams as written, ~10–30 MB | ✓ |
| SQLite | Diff becomes SQL; adds another database to a project whose problem is too many | |
| Per-file JSON mirroring the tree | 9,764 files; reintroduces path instability through the back door | |

**User's choice:** Gzipped NDJSON

### Tooling scope

| Option | Description | Selected |
|--------|-------------|----------|
| Both snapshot and diff scripts, committed | The self-diff gate is unmeetable without the diff tool | ✓ |
| Snapshot now, diff at Phase 7 | Weaker gate — proves determinism, not comparison | |
| Both, but ad-hoc documented commands | Risks the Phase 7 operator retyping it differently | |

**User's choice:** Both, committed to the repo

---

## Recovery fence location

### Artifact location

| Option | Description | Selected |
|--------|-------------|----------|
| `/mnt/fast`, outside appdata | Different physical device from `tank`; no container mounts it | ✓ |
| New `tank` dataset outside media/downloads | Beside the snapshot, gets `tank` redundancy — shares `tank`'s failure domain | |
| Both — tank primary, fast mirror | Two failure domains; adds a spot-check obligation | |
| Repo `backups/` (git) | Free off-box via GitHub; ~200 MB of scans in git history is permanent | |

**User's choice:** `/mnt/fast`, outside appdata
**Notes:** Annotated with the JMB585 DMA corruption (2,869 files damaged, Jul 2026) as evidence that
`tank` pool loss is not hypothetical.

### Off-box copies

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — scans and databases only | The genuinely irreplaceable items, and tiny | ✓ |
| Yes — everything including the NDJSON | Simplest rule to follow | |
| No — on-host is sufficient | Accepts that host-level disaster takes the fence | |

**User's choice:** Yes — scans and databases only

### Off-box destination

| Option | Description | Selected |
|--------|-------------|----------|
| Cloud object storage via rclone | True off-site; adds a credential and a remote to configure | |
| The Mac Mini (agentic-os box) | Always-on second machine on the LAN; rsync over SSH, no new credentials | ✓ |
| This workstation | Simplest; manual and unscheduled | |
| Existing estate backup, if one exists | Offered because none was found in the repo | |

**User's choice:** The Mac Mini
**Notes:** No existing off-host backup target was discoverable in the repo — this was flagged as a
genuine open choice rather than a recommendation.

### Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Path choice + verified mount audit | Same audit WRIT-01 already needs; catches a future broad mount | ✓ |
| ZFS `readonly=on` after writing | Strong, but must be toggled off per re-run, and stays off | |
| Restrictive mode bits / ownership | Cheap; ignored by root-running containers | |

**User's choice:** Path choice + a verified mount audit

### Snapshot coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Music and downloads both | Phase 5's `mv` triage and the `Now!` split have no other undo | ✓ |
| Music only, as the roadmap states | Minimal; leaves Phase 5's triage unrecoverable | |
| Music now, downloads at Phase 5 | Each phase owns its risk; relies on Phase 5 remembering | |

**User's choice:** Music and downloads both

---

## Ownership value (WRIT-04)

### uid:gid

| Option | Description | Selected |
|--------|-------------|----------|
| `568:568` (`apps:apps`) | Already the estate convention in four documents; `65534` is `nogroup`, i.e. an unmapped gid | ✓ |
| `568:65534` (`apps:nogroup`) | What 12 of 13 folders are today; zero chown work, enshrines the drift | |
| `568:545` | What `beets.md` instructs; a Windows/SMB-era convention matching no folder on this host | |

**User's choice:** `568:568`
**Notes:** Grep of the repo before asking found `568:568` stated independently in `STANDARDS.md:141`,
`DEPLOYMENT.md:31`, `README.md:29` and `CLAUDE.md:52` — so this was narrower than the roadmap implied.

### Mode bits

| Option | Description | Selected |
|--------|-------------|----------|
| `0755` dirs / `0644` files | `CLAUDE.md`'s "Option A"; `root_squash` squashes harmlessly | ✓ |
| `0775` / `0664` | What Lidarr's `UMASK_SET: 002` produces; contradicts the single-writer goal | |
| `0750` / `0640` with `all_squash` | Tightest ("Option B"); couples Phase 1's chmod to a Phase 2 export option | |

**User's choice:** `0755` / `0644`

### Normalise now or later

| Option | Description | Selected |
|--------|-------------|----------|
| Normalise now | WRIT-04 says "normalised"; Phase 2's export inherits it | ✓ |
| Decide and record only | Less disruption; leaves criterion 5 unmet and the 34 GB wrong forever | |
| Normalise now plus a drift check | As chosen, with a re-runnable assertion for later phases | |

**User's choice:** Normalise now
**Notes:** The drift-check idea was effectively absorbed into the D-27 verify script.

---

## Jellyfin freeze scope (SAFE-05)

### SaveLocalMetadata breadth

| Option | Description | Selected |
|--------|-------------|----------|
| Music library only | Narrowest change meeting SAFE-05; smallest blast radius | ✓ |
| Every library | One global setting; changes Movies/TV behaviour this project has no mandate over | |
| Music only, plus remove and re-add the library | Absolute; also stops you listening and loses play counts | |

**User's choice:** Music library only

### Scanning

| Option | Description | Selected |
|--------|-------------|----------|
| Real-time monitoring off for Music | Targeted second layer; other libraries keep updating | ✓ |
| Global scheduled scan task disabled too | Belt and braces; stops new Movies/TV appearing for others | |
| Leave scanning alone | Argues `SaveLocalMetadata` is the real lever; no second layer | |

**User's choice:** Real-time monitoring off for Music

### Duration

| Option | Description | Selected |
|--------|-------------|----------|
| Permanent, recorded as a decision | Jellyfin writing into a tagger-owned tree is a second writer by another name | ✓ |
| Temporary, with an explicit unfreeze step | Leaves a re-arm step this project's history says gets forgotten | |
| Permanent for writes, revisit scanning at Phase 9 | Splits the two so the permanent one really is | |

**User's choice:** Permanent, recorded as a decision

### Existing sidecars

| Option | Description | Selected |
|--------|-------------|----------|
| Inventory now, leave in place | Inventory needed regardless as the watch-test baseline; deleting risks losing unique artwork | ✓ |
| Inventory, archive into the fence, then remove | Cleaner end state; makes the watch test unambiguous | |
| Leave them, do not inventory | Weakens the criterion 3 evidence | |

**User's choice:** Inventory now, leave in place

---

## Who holds rw in Phases 1–3

Scout finding presented before the questions: eleven containers hold rw paths containing Music, not
the two the roadmap names. Only `seerr.yaml` was already `:ro`.

### Freeze breadth

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow every media mount to its subtree | Container-internal paths unchanged so no arr reconfiguration; Prowlarr's deleted outright | ✓ |
| Music-adjacent containers only | Smaller change; nine containers could still write Music, as accepted risk | |
| Narrow the writers, `:ro` the rest | Breaks Radarr/Sonarr imports unless their paths move too | |
| Narrow music-adjacent now, rest as its own phase | Keeps Phase 1 finishable; criterion partially met | |

**User's choice:** Narrow every media mount to its subtree

### Jellyfin's mount

| Option | Description | Selected |
|--------|-------------|----------|
| `:ro` on the whole media mount | Structural guarantee; risks extracted-subtitle and trickplay behaviour | |
| `:ro` on Music only, rw elsewhere | Docker honours the more specific mount; fiddlier to read | |
| Leave rw, rely on `SaveLocalMetadata` off | Minimal change, no transcoding risk; makes the freeze a settings promise | ✓ |

**User's choice:** Leave rw, rely on SaveLocalMetadata off

### Interim rw holder

| Option | Description | Selected |
|--------|-------------|----------|
| Nobody | Phase 3's spike needs no library writes; cleanest end state for a freeze phase | ✓ |
| beets-manual keeps rw | Profile-gated so the audit passes anyway; leaves an escape hatch | |
| Nobody, plus a documented break-glass | Clean state plus realism; an escape hatch gets used | |

**User's choice:** Nobody

### wrtag freeze mechanics

| Option | Description | Selected |
|--------|-------------|----------|
| Delete the library mount, keep it invokable | WRIT-02 satisfied; Phase 3 dry-runs against a scratch target | ✓ |
| Delete the mount and the stack entry now | Phase 4 owns retirement; Phase 3 needs wrtag to exist | |
| Change the library mount to `:ro` | Contradicts the roadmap's explicit "the mount, not just the restart policy" | |

**User's choice:** Delete the library mount, keep it invokable

---

## Conflict resolution — Jellyfin vs WRIT-01

Raised explicitly rather than resolved silently: "narrow every mount" + "nobody holds rw" +
"leave Jellyfin rw" together make Jellyfin the *sole* rw holder on Music, so WRIT-01's audit would
pass with a count of one that is not a tagger.

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit documented exception | Consumer-class writer, disabled at the app layer, excluded from the tagger count | ✓ |
| `:ro`, gated on a subtitle/trickplay check | Verify then flip, fall back to the exception if the check fails | |
| Split: Music `:ro`, other libraries rw | Two mounts; Docker honours the more specific one | |

**User's choice:** Explicit documented exception

---

## Lidarr repoint target (WRIT-03)

### Root folder destination

| Option | Description | Selected |
|--------|-------------|----------|
| New path under `tank/downloads` | Outside the library, on the staging dataset; absorbable by Phase 5 | ✓ |
| The Phase 5 inbox path, created early | End state reached immediately; pulls Phase 5's decision forward | |
| Remove the root folder entirely | Strongest guarantee; Lidarr errors without one, and Phase 8 needs it back | |

**User's choice:** New path under `tank/downloads`

### Settings breadth

| Option | Description | Selected |
|--------|-------------|----------|
| `renameTracks` off + metadata consumers off | Closes a second `.nfo` write path the roadmap does not count | ✓ |
| `renameTracks` off only | Exactly WRIT-03; relies on the mount and root-folder changes holding | |
| Everything off, also unmonitor all artists | Maximum safety; stops new music arriving and is manual to undo | |

**User's choice:** renameTracks off + metadata consumers off
**Notes:** The Lidarr Metadata-consumer write path was surfaced during the discussion — it is not
mentioned in ROADMAP.md or REQUIREMENTS.md.

### Media mount

| Option | Description | Selected |
|--------|-------------|----------|
| No — remove it entirely | Root folder moves to downloads, so the mount is pure exposure | |
| Yes, but `:ro` | Retains existing-library matching and duplicate awareness without write | ✓ |
| Yes, narrowed to Music `:ro` | Narrowest; unclear Lidarr does anything useful with it | |

**User's choice:** Yes, but `:ro`

---

## Host vs repo durability

This batch was initially rejected mid-answer and re-asked in full at the user's request
("sorry, bad option there - lets resume"). The durability answer was unchanged on the re-ask.

### Durability mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Idempotent apply + verify scripts | Matches existing `setup-*.sh` / `check-*.sh`; Terraform has no provider for Jellyfin/Lidarr settings | ✓ |
| Scripts plus Terraform for the ZFS parts | Correct division; two mechanisms, and a `terraform apply` on a state file carrying stray backups | |
| Documented runbook only | Lowest ceremony; this estate already has a documented deploy-drift problem | |

**User's choice:** Idempotent apply + verify scripts

### SAB beets config

| Option | Description | Selected |
|--------|-------------|----------|
| Vendor into the repo and bind-mount | Same pattern that keeps `scripts_init.bash` alive through rebuilds | ✓ |
| Edit in place, document it | Fastest; bets on Phase 4 happening in a project that has stalled three times | |
| Leave it — Phase 4 deletes it | `scrub.auto`/`embedart.auto` still fire on what it does process | |

**User's choice:** Vendor into the repo and bind-mount

### Verify cadence

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into the existing health check | Drift caught on a path already in use; docker `created`-state blind spot as precedent | ✓ |
| On demand, called by later phases | Tied to dependent work; nothing catches drift between phases | |
| Both — health check plus phase preconditions | Most thorough; one more green line to read past | |

**User's choice:** Fold into the existing health check

---

## Evidence recording

| Option | Description | Selected |
|--------|-------------|----------|
| New runbook in the music stack | `stacks/selfhosted/music/safety-harness.md`, beside the code | |
| Extend `beets.md` | Already the documented prior art PROJECT.md points at; one file to read | ✓ |
| Phase artifacts only | Keeps the repo free of scaffolding; poor fit for a durable estate fact like the uid:gid | |

**User's choice:** Extend beets.md
**Notes:** Consequence surfaced during the discussion — `beets.md` currently instructs
`chown -R 568:545`, which is wrong under the decided value and gets corrected as part of this phase.

---

## Claude's Discretion

- **Jellyfin database backup method** — stated as a decision rather than asked: `sqlite3 .backup`
  against the live file (consistent, no downtime, no torn WAL), rather than a plain `cp` or a
  stop-copy-start. The user was told and did not object.
- Fence directory naming under `/mnt/fast`, script filenames, NDJSON field layout.

## Deferred Ideas

- **Resumability of the ~140 GB hash run** — offered as a further gray area, not discussed. NDJSON's
  append-per-line format already supports it; planner to make it explicit.
- **Ordering of the snapshot relative to the chown/chmod** — offered, not discussed. It changes what
  the fence captures.
- **Whether soulbeet is frozen here or left to Phase 4** — offered, not discussed. Its image is gone
  from GHCR so it cannot run; its Music mount is still declared in `arrs/soulbeet.yaml`.
- **Making Jellyfin's Music mount genuinely `:ro`** — considered and rejected in favour of the
  documented exception. Worth revisiting once a tagger owns the tree.
- **Clearing existing `.nfo`/`.jpg`/`.lrc` sidecars** — considered and deferred; revisit if they
  cause path collisions in Phase 6/7.
- **Narrowing the non-music arr mounts** — in scope via D-19, but flagged as estate hygiene that can
  be split out if it proves larger than expected during planning.
- **Replacing Lidarr as the grabber** — LIDR-01, already recorded as v2 / Beyond This Milestone.
