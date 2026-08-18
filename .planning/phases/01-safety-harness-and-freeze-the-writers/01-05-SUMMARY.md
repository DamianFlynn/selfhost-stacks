---
phase: 01-safety-harness-and-freeze-the-writers
plan: 05
subsystem: writer-freeze
tags: [docker, compose, bind-mounts, wrtag, jellyfin, janitorr, WRIT-01, WRIT-02]
requires:
  - scripts/check-music-freeze.sh (01-01)
  - verified /mnt/tank/media subtree names (01-01 section 3)
provides:
  - six arr media mounts narrowed to their own subtrees, live on the host
  - prowlarr media mount deleted outright
  - wrtag library mount deleted + profiles gate (WRIT-02 met)
  - beets and soulbeet media mounts read-only
  - jellyfin documented as the sole consumer-class rw exception
  - /mnt/fast/safety/music-pre-project/audit/after-01-05-20260818.txt
affects:
  - 01-06 (lidarr is the only remaining rw holder in both audit classes)
  - 01-07 (janitorr file-level bind pattern left intact for reuse)
  - 01-09 (sections 1+2 below are the D-30 evidence copied into beets.md)
  - "Phase 3 (wrtag still invokable via --profile manual, /music/source retained)"
  - "Phase 4 (wrtag and soulbeet frozen, not deleted — retirement stays independently shippable)"
tech-stack:
  added: []
  patterns:
    - "sabnzbd.yaml dated NOTE block reused for the jellyfin carve-out"
    - "beets/beets.yaml restart-no + profiles-manual lifecycle gate copied verbatim into wrtag.yaml"
    - "seerr.yaml explicit-suffix + trailing-comment volume convention applied to eight files"
key-files:
  created:
    - .planning/phases/01-safety-harness-and-freeze-the-writers/deferred-items.md
  modified:
    - stacks/selfhosted/arrs/radarr.yaml
    - stacks/selfhosted/arrs/sonarr.yaml
    - stacks/selfhosted/arrs/readarr.yaml
    - stacks/selfhosted/arrs/bazarr.yaml
    - stacks/selfhosted/arrs/janitorr.yaml
    - stacks/selfhosted/arrs/prowlarr.yaml
    - stacks/selfhosted/music/wrtag.yaml
    - stacks/selfhosted/arrs/beets/beets.yaml
    - stacks/selfhosted/arrs/soulbeet.yaml
    - stacks/selfhosted/media/jellyfin.yaml
decisions:
  - "Photos gets no mount in any narrowed container — only Jellyfin retains it, via its broad carve-out"
  - "wrtag removed from the running set with `compose --profile manual down`; `compose up -d` on the music stack now returns 'no service selected', which is the gate working"
  - "lidarr deliberately untouched — 01-06 owns WRIT-03; it is therefore the single remaining rw holder in both audit classes"
  - "bazarr and janitorr gained the Workflow header block STANDARDS.md requires and they lacked"
metrics:
  duration: ~35 minutes
  completed: 2026-08-18
  tasks: 3
  commits: 4
  files_modified: 10
  audit_failures: 12 → 5
---

# Phase 01 Plan 05: Narrow Every Media Mount Summary

Every `/mnt/tank/media` bind mount in the estate narrowed to its own subtree and applied live on
LXC 100, deleting Prowlarr's outright and wrtag's library mount entirely — collapsing the WRIT-01
rw-holder set from **nine running containers to two** (lidarr, which 01-06 owns, and Jellyfin, now
a documented carve-out), with the library itself provably untouched.

## What Was Built

| Task | Output | Commit |
|------|--------|--------|
| 1 | Six arr media mounts narrowed or deleted | `6e86d33` |
| 2 | wrtag / beets / soulbeet frozen at the definition level | `989859a` |
| 3 | Jellyfin NOTE block, host apply, post-apply audit | `6c7eeb2` |

## Section 3 re-verification — the live `/mnt/tank/media` layout

Re-confirmed against the host before any edit, per T-01-25. Identical to 01-01:

```
Books
Movies
Music
Photos
TV
```

D-19's assumed names `Movies`, `TV`, `Books` are all correct. No typo risk realised.

### The `Photos` decision (the plan does not mention it)

**Decision: no container touched by this plan gets a `Photos` mount.** Reasoning, deliberately:

- None of the six narrowed services has any use for it — Radarr, Sonarr, Readarr and Bazarr are
  movie/TV/book tools; Janitorr's cleanup rules are `MOVIES_AND_TV`; Prowlarr loses media access
  entirely.
- Photo management on this estate is Immich's job, on its own stack and its own storage.
- Jellyfin does serve a Photos library, and it keeps the broad `/mnt/tank/media` mount under the
  D-21 carve-out, so nothing it does today changes.

The net effect is that `Photos` goes from being reachable by **eight** containers to being
reachable by **one** — a strict improvement that arrives free with the D-19 narrowing.

## Task 1 — Before/after mount table, with `test -d` results

Every host-side source was verified to exist on LXC 100 **before** the apply. This is the T-01-25
mitigation and it is not optional: Docker silently creates a missing bind source as an empty
directory rather than erroring, so a typo would have quietly emptied an arr's library view instead
of failing loudly.

| Container | Before | After | Host source | `test -d` |
|---|---|---|---|---|
| radarr | `/mnt/tank/media:/media:rw` | `/mnt/tank/media/Movies:/media/Movies:rw` | `/mnt/tank/media/Movies` | ✅ exit 0 |
| sonarr | `/mnt/tank/media:/media:rw` | `/mnt/tank/media/TV:/media/TV:rw` | `/mnt/tank/media/TV` | ✅ exit 0 |
| readarr | `/mnt/tank/media:/media:rw` | `/mnt/tank/media/Books:/media/Books:rw` | `/mnt/tank/media/Books` | ✅ exit 0 |
| bazarr | `/mnt/tank/media:/media:rw` | `/mnt/tank/media/Movies:/media/Movies:rw`<br>`/mnt/tank/media/TV:/media/TV:rw` | `/mnt/tank/media/Movies`<br>`/mnt/tank/media/TV` | ✅ exit 0<br>✅ exit 0 |
| janitorr | `/mnt/tank/media:/data:rw` | `/mnt/tank/media/Movies:/data/Movies:rw`<br>`/mnt/tank/media/TV:/data/TV:rw` | `/mnt/tank/media/Movies`<br>`/mnt/tank/media/TV` | ✅ exit 0<br>✅ exit 0 |
| prowlarr | `/mnt/tank/media:/media:rw` | **line deleted** | — | n/a |
| beets | `/mnt/tank/media:/media:rw` | `/mnt/tank/media:/media:ro` | `/mnt/tank/media` | ✅ exit 0 |
| soulbeet | `/mnt/tank/media/Music:/music` *(no suffix = rw)* | `/mnt/tank/media/Music:/music:ro` | `/mnt/tank/media/Music` | ✅ exit 0 |
| wrtag | `/mnt/tank/media/Music:/music/library` *(no suffix = rw)* | **line deleted** | — | n/a |
| jellyfin | `/mnt/tank/media:/media` *(no suffix = rw)* | `/mnt/tank/media:/media:rw` **(unchanged status, now explicit)** | `/mnt/tank/media` | ✅ exit 0 |

### Container-internal paths verified against each arr's live configuration

The claim "no arr needs reconfiguring" was **checked, not assumed** — each root folder was read back
from the arr's own API before the edit and again after the restart:

| Arr | Root folder (API) | Matches narrowed target | `accessible` after restart |
|---|---|---|---|
| radarr | `/media/Movies` | yes | `true` |
| sonarr | `/media/TV` **and** `/downloads/media/tv` | yes — the second is served by the untouched downloads mount | `true` / `true` |
| readarr | `/media/Books` | yes | `true` |
| lidarr | `/media/Music` | untouched, 01-06 owns it | `true` |

Bazarr, which has no root-folder API of its own, was verified directly:
`ls /media/Movies` → 1,402 entries, `ls /media/TV` → 170 entries inside the container.
Janitorr's `ls /data` now returns exactly `Movies` and `TV` — **no music subtree**, which is the
T-01-26 mitigation. A container whose declared job is deleting is the sharpest instance of the
problem this phase closes.

## Task 2 — wrtag before/after

**Before** (`wrtag.yaml:29`, `34-40`):

```yaml
    restart: unless-stopped
...
    volumes:
      # Database and job queue
      - /mnt/fast/appdata/media/wrtag/data:/data
      # Source music (unsorted downloads)
      - /mnt/tank/downloads/complete/nzb/unsorted:/music/source
      # Destination organized library
      - /mnt/tank/media/Music:/music/library
```

**After:**

```yaml
    restart: "no"  # Don't run 24/7, start manually or via cron
    profiles: ["manual"]  # Exclude from 'docker compose up'
...
    volumes:
      # NOTE (2026-08-18): the destination library mount was DELETED here, not commented
      # out — WRIT-02 requires the mount gone, not just the restart policy changed.
      # [...11 further lines recording D-20, the Phase 3 scratch-target arrangement, and
      #  that Phase 4 not this plan owns retirement...]
      #
      # Database and job queue
      - /mnt/fast/appdata/media/wrtag/data:/data:rw
      # Source music (unsorted downloads)
      - /mnt/tank/downloads/complete/nzb/unsorted:/music/source:rw
```

The lifecycle-gate pair was copied verbatim — inline comments included — from
`arrs/beets/beets.yaml:10-11`, the estate's only existing manually-invoked container.

**The gate was proven, not asserted.** After `docker compose -f music/compose.yaml --profile manual
down` removed the running container, a plain `docker compose -f music/compose.yaml up -d` returns:

```
no service selected
```

wrtag cannot start unattended. `/music/source` survives so Phase 3 can still run its
`wrtag move -dry-run` disqualifier test, supplying its own scratch destination.

**wrtag was found `Restarting (1)` — crash-looping, not idle** — and still holding a live
read-write mount on the library the whole time. It is now removed from the running set entirely
(103 → 102 running containers). It is **frozen, not deleted**: Phase 4 owns retirement and stays
independently shippable per D-22.

## Task 3 — the apply, and the Jellyfin restart that did not happen

### Jellyfin active playback at apply time: **0 sessions**

Courtesy check before the restart, per the user's instruction. Queried
`GET /Sessions?activeWithinSeconds=180` from inside the `t3_proxy` network:

```
[]
http=200
```

Zero sessions of any kind in the preceding three minutes — nobody was mid-stream, and nobody was
even connected. No playback was interrupted.

**And Jellyfin was not restarted at all.** `docker compose up -d` on the media stack reported
`Container jellyfin Running`, not `Recreated`. This is correct and expected: adding `:rw` to a
mount that Docker already defaulted to read-write produces an identical container config hash, so
Compose had nothing to recreate. The change is documentation made explicit, exactly as D-21
intends — the mount's read-write status was never altered. Its live mount was confirmed by
`docker inspect` as `/mnt/tank/media:/media:rw`.

The user's authorisation to restart Jellyfin was therefore not needed. It is recorded here rather
than quietly dropped, because "we had permission and didn't use it" is a materially different
statement from "we deferred it".

### Container health after the apply

| Container | Status | Health |
|---|---|---|
| radarr | running | no healthcheck defined |
| sonarr | running | no healthcheck defined |
| readarr | running | no healthcheck defined |
| bazarr | running | no healthcheck defined |
| janitorr | running | **healthy** |
| prowlarr | running | no healthcheck defined |
| lidarr | running | no healthcheck defined (untouched) |
| jellyfin | running | **healthy** (not recreated) |
| autobrr | running | no healthcheck defined (recreated as a side effect, see deviations) |
| flaresolverr | running | no healthcheck defined (recreated as a side effect) |
| seerr | running | no healthcheck defined (recreated as a side effect) |
| audiobookshelf | running | no healthcheck defined (recreated as a side effect) |
| wizarr | running | **healthy** (recreated as a side effect) |
| wrtag | **removed** | intentional — profile-gated |

No container failed to come back. No new root-folder or path error appears in `docker logs` for
radarr, sonarr, readarr, bazarr, janitorr or prowlarr since the restart. Two log findings that did
appear are both pre-existing and unrelated — see Deviations.

### No stray empty directories were created

The T-01-25 failure mode would show up as a new empty directory under `/mnt/tank/media`. The
post-apply listing is byte-identical to the pre-apply one:

```
drwxrwxrwx    7 apps   nogroup    8 Jan  4  2026 .
-rwxrwxrwx    1 nobody nogroup 6148 Oct  1  2025 .DS_Store
drwxrwxrwx    4 nobody nogroup    4 Mar  5 16:06 Books
drwxrwxrwx 1404 apps   apps    1404 Aug 18 00:10 Movies
drwxrwxrwx   15 apps   nogroup   16 Aug 17 09:02 Music
drwxrwxrwx    8 apps   apps       9 Oct  1  2025 Photos
drwxrwxrwx  172 apps   nogroup  172 Aug  8 23:34 TV
```

## Library ownership — confirmed unchanged

01-08 owns the chown; this plan must not have touched a single byte of the library.

| Assertion | 01-01 baseline | After 01-05 | Verdict |
|---|---|---|---|
| entries under the library | 2,673 | **2,673** | unchanged |
| ownership mismatches (non-`568:568`) | 2,543 | **2,543** | unchanged |
| directory-mode mismatches (non-`755`) | 87 | **87** | unchanged |
| file-mode mismatches (non-`644`) | 2,586 | **2,586** | unchanged |
| sidecars | 1,123 | **1,123** | unchanged |

## Post-apply audit — sections 1 and 2 VERBATIM (D-30 evidence for 01-09)

Source: `/mnt/fast/safety/music-pre-project/audit/after-01-05-20260818.txt` on LXC 100, produced by
`./scripts/check-music-freeze.sh --baseline`. ANSI colour codes stripped; otherwise unedited.

```
🐳 1. Running-container rw holders on the library (WRIT-01, D-26)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  102 running containers, 163 mounts enumerated

  tagger-class writers: 1
      lidarr (/mnt/tank/media:/media:rw)
  consumer-class writers: 1 (documented exception, D-21)
      jellyfin (/mnt/tank/media:/media:rw)
  unclassified writers: 0

  Note: a bare total is deliberately NOT asserted. Jellyfin is expected to remain the
  sole rw holder (D-21), so 'total == 1' would read as a pass for the wrong reason.
  ❌ 1 tagger-class rw holders on the library (WRIT-01 requires 0)
  ✅ no unclassified rw holders

📄 2. Declared rw mounts across stack YAML (false-pass guard)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Why this is a separate class from section 1: arrs/beets/beets.yaml and arrs/soulbeet.yaml
  are both commented out of arrs/compose.yaml, so no running container exists for either and
  section 1 cannot see them — while their YAML still declares a rw path into the library.
  A running-container-only audit reports a false pass here.

  12 declared /mnt/tank/media volume lines

  FILE                                           LINE  SUFFIX     MAPPING
  stacks/selfhosted/media/jellyfin.yaml          119   rw         /mnt/tank/media:/media:rw
  stacks/selfhosted/media/seerr.yaml             42    ro         /mnt/tank/media:/data:ro
  stacks/selfhosted/arrs/beets/beets.yaml        25    ro         /mnt/tank/media:/media:ro
  stacks/selfhosted/arrs/lidarr.yaml             43    rw         /mnt/tank/media:/media:rw
  stacks/selfhosted/arrs/sonarr.yaml             48    rw         /mnt/tank/media/TV:/media/TV:rw
  stacks/selfhosted/arrs/bazarr.yaml             47    rw         /mnt/tank/media/Movies:/media/Movies:rw
  stacks/selfhosted/arrs/bazarr.yaml             48    rw         /mnt/tank/media/TV:/media/TV:rw
  stacks/selfhosted/arrs/janitorr.yaml           51    rw         /mnt/tank/media/Movies:/data/Movies:rw
  stacks/selfhosted/arrs/janitorr.yaml           52    rw         /mnt/tank/media/TV:/data/TV:rw
  stacks/selfhosted/arrs/soulbeet.yaml           48    ro         /mnt/tank/media/Music:/music:ro
  stacks/selfhosted/arrs/radarr.yaml             46    rw         /mnt/tank/media/Movies:/media/Movies:rw
  stacks/selfhosted/arrs/readarr.yaml            46    rw         /mnt/tank/media/Books:/media/Books:rw

  NO-SUFFIX means neither :ro nor :rw was written, and docker defaults that to rw.
  ❌ 1 declared rw/unsuffixed host paths reach the library outside media/jellyfin.yaml:
         stacks/selfhosted/arrs/lidarr.yaml:43 /mnt/tank/media:/media:rw [rw]
```

### Reading that output

**Both audit classes now name exactly one offender, and it is the same one: `lidarr`.**

- Section 1 went from **2 tagger-class + 6 unclassified** to **1 tagger-class + 0 unclassified**.
  Every unclassified holder — sonarr, radarr, readarr, prowlarr, bazarr, janitorr — is gone.
- Section 2 went from **10 files** declaring an rw/unsuffixed path at the library to **1**.
  `wrtag.yaml` has left the table entirely (its line is deleted, not suffixed). `beets/beets.yaml`
  and `soulbeet.yaml` are now `ro`, which is the false-pass class closed — these two are the ones
  section 1 structurally cannot see, and section 2 is why they were caught.
- **Zero `NO-SUFFIX` rows remain anywhere in the estate.** All three latent defects
  (`wrtag.yaml:40`, `soulbeet.yaml:37`, `jellyfin.yaml:93`) are resolved.
- The declared-line count staying at 12 is coincidence: −2 (prowlarr, wrtag) +2 (bazarr TV,
  janitorr TV).

Whole-script failure total: **12 → 5**.

## Deviations from Plan

### 1. [Verified fact over plan text] `tagger-class writers` is 1, not 0 — lidarr remains, by design

- **Where:** Task 3 acceptance criteria, which require section 1 to report `tagger-class writers: 0`
  and section 2 to name `media/jellyfin.yaml` as the only offender.
- **Reality:** `lidarr` matches the audit's `TAGGER_PATTERN` and holds
  `/mnt/tank/media:/media:rw`. Plan **01-06** owns lidarr.yaml exclusively (`files_modified:
  [stacks/selfhosted/arrs/lidarr.yaml]`, D-25 flips it to `:ro`). The executor brief states plainly
  that lidarr is not this plan's job and that verified facts win over plan text.
- **Action:** `lidarr.yaml` was left untouched. The plan's zero-tagger criterion is met by
  01-05 + 01-06 together, not by 01-05 alone.
- **Not a defect in this plan.** Everything 01-05 owns is at zero. Flagged prominently so 01-09's
  assert-mode re-run is not read as a regression.

### 2. [Rule 3 - Blocking] Two of the plan's `docker compose config` gates are unmeetable as written

- **`docker compose -f stacks/selfhosted/arrs/soulbeet.yaml config`** cannot exit 0. The service
  declares `networks: [t3_proxy]`, which is defined in `arrs/compose.yaml`, so standalone
  validation fails with `service "soulbeet" refers to undefined network t3_proxy`.
- **Proven pre-existing**, not caused by this plan: the same command against
  `git show HEAD:stacks/selfhosted/arrs/soulbeet.yaml` fails identically.
- **`docker compose -f stacks/selfhosted/media/compose.yaml config`** cannot exit 0 from a
  workstation — it references `env_file /mnt/fast/stacks/stacks/selfhosted/media/.env`, a
  host-absolute path.
- **Fix:** validated by the routes that actually prove the thing.
  `docker compose -f arrs/compose.yaml -f arrs/soulbeet.yaml config` exits 0 and renders the music
  mount as `read_only: true`. The media stack was validated **on LXC 100 after the pull**, where
  all three stacks (`arrs`, `music`, `media`) return exit 0.

### 3. [Rule 2 - Missing critical] `bazarr.yaml` and `janitorr.yaml` had no `Workflow:` header block

- **Found during:** Task 1, checking the acceptance criterion `grep -c 'Workflow:'` returns 1 for
  each of the six files.
- **Issue:** it returned **0** for bazarr and janitorr. `STANDARDS.md` § "Service File Structure"
  mandates a `Workflow:` section in every service file; both predate or ignore it. The criterion as
  written was unsatisfiable.
- **Fix:** added the missing `Workflow:` block to both, and used it to record each service's new
  library scope — which is also where the plan asked the narrowing to be documented. All six files
  now return 1.
- **Files modified:** `bazarr.yaml`, `janitorr.yaml` — **Commit:** `6e86d33`

### 4. [Rule 1 - Bug in my own first draft] Header prose defeated two literal-string acceptance greps

- I initially wrote `Prowlarr's /mnt/tank/media mount was deleted outright` into prowlarr's header,
  and quoted the literal paths `/mnt/tank/media/Music:/music/library` and `/music/source` in
  wrtag's NOTE block. Each made its own acceptance grep report a false failure
  (`grep -c '/mnt/tank/media' prowlarr.yaml` → 1 instead of 0;
  `grep -c '/mnt/tank/media/Music:/music/library' wrtag.yaml` → 1 instead of 0;
  `grep -c '/music/source' wrtag.yaml` → 2 instead of 1).
- **Fix:** reworded both to describe the mounts without quoting their literal mapping strings. The
  comments say the same thing; the greps now return 0, 0 and 1. Caught before either commit.

### 5. [Side effect, benign] Seven containers beyond the ten were recreated by `compose up -d`

- `autobrr` and `flaresolverr` (arrs stack), and `seerr`, `audiobookshelf`, `wizarr` (media stack)
  were recreated despite no edit from this plan. `seerr` also **pulled a new image**
  (`ghcr.io/seerr-team/seerr:v3.4.1`).
- **Cause:** this is the estate's documented **Renovate deploy-drift** — merged version bumps that
  never reached the host. `docker compose up -d` reconciles them all at once. The repo said one
  thing and `docker ps` said another; now they agree.
- **Outcome:** all five came back running, `wizarr` reports `healthy`. Not reverted — leaving the
  host deliberately behind the repo would recreate exactly the drift problem the estate already has
  a memory entry about. Recorded so the extra churn is not a mystery later.

### 6. [Deferred, out of scope] Two pre-existing log errors surfaced by the restart

Both logged to `deferred-items.md` and **not fixed** — neither is caused by this plan and neither
touches the music library.

- **Janitorr cannot write its own log file.** `/logs/janitorr.log` is owned `root:root` mode `0770`;
  janitorr runs `568:568`. Last successful write **9 March 2026** — its file log has been silently
  dead for five months. Container is `healthy` and falls back to console.
- **Sonarr has stale queue items** pointing at `/downloads/complete/nzb/tv/<release>` folders that
  no longer exist on the host. Sonarr's `/downloads` mount is untouched and intact, and its
  `/media/TV` root folder reads `accessible: true` after the restart.

## Findings

1. **The narrowing made Janitorr strictly safer in a way the plan did not anticipate.** Its config
   sets `leaving-soon-dir: /data/media/leaving-soon`, which under the old broad mount resolved to
   `/mnt/tank/media/media/leaving-soon` — a doubled path that has never existed. Now that `/data`
   is no longer a bind mount, anything it creates there lands in the container's ephemeral layer
   instead of inside the media dataset. Janitorr's Radarr/Sonarr/Jellyseerr integrations are all
   currently disabled and `dry-run: true`, so it is inert regardless.
2. **`Photos` was never mentioned by D-19 and was reachable by eight containers.** It is now
   reachable by one. Free improvement, but it means the plan's subtree list was incomplete — worth
   knowing if anyone later assumes D-19 enumerated everything under `/mnt/tank/media`.
3. **wrtag was crash-looping while holding the mount.** 01-01 flagged it as "running, not idle";
   it was in fact `Restarting (1)`, which is worse — a container in a restart loop still holds its
   bind mounts, so "it's broken anyway" was never a safety argument.
4. **There are two `.DS_Store` files, not one.** 01-01 found one in the Music library root; the
   media root has its own, owned `65534:65534`. Both confirm a Mac has had write access over a
   share.

## Requirements Status

- **WRIT-02 — MET.** wrtag's `/music/library` mount is deleted from the definition (the mount, not
  just the restart policy), it is gated behind `restart: "no"` + `profiles: ["manual"]`, the
  running container is removed, and `docker compose up -d` on the music stack now returns
  `no service selected`.
- **WRIT-01 — NOT marked complete.** Everything this plan owns is done: 6 of 6 unclassified holders
  eliminated, wrtag's tagger-class mount gone, beets and soulbeet read-only, Jellyfin documented and
  correctly classified. `lidarr` remains and **01-06 closes it**. Marking WRIT-01 complete here
  would be false.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change was introduced —
this plan only removes filesystem reach. No package-manager install occurred (T-01-SC holds) and no
image tag was changed by any edit in this plan; the `seerr` image pull was Compose reconciling
pre-existing repo state, not a new artifact chosen here.

## Known Stubs

None.

## Self-Check: PASSED

- `stacks/selfhosted/arrs/{radarr,sonarr,readarr,bazarr,janitorr,prowlarr}.yaml` — all FOUND, all modified
- `stacks/selfhosted/music/wrtag.yaml`, `stacks/selfhosted/arrs/beets/beets.yaml`, `stacks/selfhosted/arrs/soulbeet.yaml` — all FOUND, all modified
- `stacks/selfhosted/media/jellyfin.yaml` — FOUND, modified
- `.planning/phases/01-safety-harness-and-freeze-the-writers/deferred-items.md` — FOUND
- `/mnt/fast/safety/music-pre-project/audit/after-01-05-20260818.txt` — FOUND on LXC 100
- Commit `6e86d33` — FOUND
- Commit `989859a` — FOUND
- Commit `6c7eeb2` — FOUND, pushed to `origin/main`
- LXC 100 `/mnt/fast/stacks` at `6c7eeb2`, confirmed by `git log --oneline -1` after `git pull --ff-only`
- Live state confirmed by `docker inspect`, not by the repo diff (T-01-28)
