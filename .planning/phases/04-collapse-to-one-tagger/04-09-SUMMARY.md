---
phase: 04-collapse-to-one-tagger
plan: 09
subsystem: tagger-config
tags: [beets, probe, musicbrainz, criterion-4, survivor, lifecycle, trap, d-16, d-17, d-19, d-27, d-28]

# Dependency graph
requires:
  - plan: 04-07
    provides: "a survivor config/ holding NO database at all, so D-28's fresh library.db had an unobstructed path"
  - plan: 04-08
    provides: "the vendored survivor config.yaml, its :ro bind mount, and the probe's --mb-only mode with its proven gate control"
  - plan: 04-01
    provides: "the junk config sha, the live broken sabnzbd config sha, the D-29 album measurement and the ROUTINE BASELINE"
provides:
  - "criterion 4 (amended) MEASURED on the container this phase ships: broken config -> 0 MusicBrainz candidates, fixed config -> 1, same album, same throwaway -l, configs differing by exactly one line"
  - "the single fresh survivor library.db (D-28) at /config/library.db: integrity ok, 0 items, 0 albums, sha fbbdde0c..., created by svc-beets at 2.13.1-ls349"
  - "D-27 installed: the vendored config.yaml is byte-identical on the host and is the base config every probe run read"
  - "D-09 ANSWERED: the :ro single-file config mount logs ZERO EROFS at boot; :ro stays, no flip"
  - "the survivor's return to dormancy proven on BOTH the success path (rc 0) and the signal path (driven SIGTERM, rc 143)"
  - "MEASURED: beets 2.13.1 writes 11 migration .bak on the FIRST open of ANY database, fresh ones included - so 'one library.db' is 12 files, not 1"
affects: [04-11, 04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Container readiness is gated on the capability actually needed (`docker exec -u abc ... test -r <file>`), never on `.State.Status == running`, which is true before s6 has remapped the runtime user"
    - "A trap-guarded single-process lifecycle: EXIT trap runs `compose down`, INT/TERM/HUP each `exit` so the EXIT trap fires, and every slow step runs `timeout N cmd & wait $!` so signals land immediately instead of after the child"
    - "An empty producer output is proof of nothing: the container log's BYTE COUNT is printed beside every grep taken over it, so a `(none)` from an empty log cannot read as a clean result"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-09-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets/beets.yaml
  host-created:
    - "/mnt/fast/appdata/arrs/beets/config/library.db (+ its 11 migration .bak) - D-28's single fresh database"
    - "/mnt/fast/appdata/arrs/beets/config/config.yaml - REPLACED in place (same inode) by the D-27 vendored file"

key-decisions:
  - "The 11 migration .bak beside the fresh library.db were NOT deleted. They are inherent to beets 2.13.1 opening any new database, deletion is 04-11's lane, and removing files to satisfy an assertion is the failure mode this phase exists to avoid"
  - "beets.yaml's `:ro` NOTE was corrected even though the plan only mandated an edit if the flip were REQUIRED: the block claimed the boot behaviour was UNMEASURED and named this plan as the measurer, so leaving it was leaving a false claim"
  - "The fresh library.db created during the FIRST (aborted) run was kept rather than deleted and re-made: it was created by the survivor at the declared path at 2.13.1-ls349, which is exactly what D-28 specifies"

requirements-completed: []  # TAGR-05 is ADVANCED, not satisfied. The survivor's config declares musicbrainz AND is now installed and proven loaded on the host, but sabnzbd's config is still `plugins: embedart` ON PURPOSE until 04-11 - D-17's negative control had to run against the LIVE broken config first, which is what this plan did.
requirements-advanced: [TAGR-05]

# Metrics
duration: ~34min
completed: 2026-09-11
---

# Phase 4 Plan 09: Survivor Stand-Up and the Criterion-4 Probe Summary

**The missing `musicbrainz` plugin is no longer an inference. Against the LIVE broken sabnzbd config the probe returned zero MusicBrainz candidates in 0.4 s; against a copy differing by exactly one line it returned a 12-of-12-track `Scarecrow` at distance 0.048, and a hand-read `beet import -t` showed the same release at 95.2% before aborting. The survivor created its one fresh `library.db` and was returned to dormancy by a trap that was seen to fire on the success path, on a driven SIGTERM, and on a real unplanned failure.**

## Performance

- **Duration:** ~34 min
- **Started:** 2026-09-11 ~23:31Z
- **Completed:** 2026-09-12 ~00:05Z
- **Tasks:** 3 of 3
- **Files:** 1 repo file modified (1 commit), plus this summary. On the host: 1 database created, 1 config replaced, all scratch removed.

## Accomplishments

- **Criterion 4 is a measurement.** The same album, the same throwaway `-l`, two configs differing by
  one line: `plugins: embedart` → **0** MusicBrainz records; `plugins: embedart musicbrainz` → **1**.
  The `beet version` plugin lines differ exactly as predicted, and the gate control refused.
- **D-28 has its one database**, created by the survivor itself at 2.13.1-ls349 at the path D-27
  declares — `integrity ok`, 0 items, 0 albums, and byte-identical across every probe arm and both
  further container starts.
- **D-09 is answered, not deferred.** ZERO EROFS lines across 175 container log lines. `:ro` stays.
- **The trap was proven three times**, once by accident: the success path (rc 0), the driven SIGTERM
  (rc 143), and a genuine unplanned HALT (rc 21). Every one ended `CLEANUP: dormant`.
- **Two false-green classes were caught before they could produce evidence** — a `(none)` EROFS grep
  taken over an empty log, and a readiness test that passed before the container could do the thing
  being tested.
- **Both routine checks are exactly at the 04-01 ROUTINE BASELINE**, and the candidate census is red
  in precisely the four expected places and nowhere else.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Tag decision, HALT preconditions, config install, overlays, lifecycle script | **none** — host-only, no repo file changed (the 04-01 / 04-07 precedent). Evidence below |
| 2 | The trap-guarded lifecycle, the criterion-4 pair, the hand-read, the TERM control | **`fc6d35f`** (docs: the measured `:ro` boot result) |
| 3 | Independent dormancy proof, cleanup, census and routine checks | **none** — host-only |

**Plan metadata:** this SUMMARY's own commit.

## Delivery

| Item | Value |
|---|---|
| Pushed | `9267272..fc6d35f  main -> main` (and `02e5aa0..9267272` carrying wave 3's docs commits) |
| Host `/mnt/fast/stacks` HEAD | `fc6d35f` (fast-forward) |
| Host `beets.yaml` sha == workstation | `957463769fd8641733124c448bd5e64229e8dfb7a842c9ac6ae76efbeba4a529` — equal |
| Host porcelain | the same 2 pre-existing untracked files, untouched |

---

## Task 1: everything before `up`

### Tag decision (D-30 / REVIEWS row 15)

**This was NOT D-30's deliberate redeploy.** The image tag at HEAD is still
`lscr.io/linuxserver/beets:2.13.1-ls349` — Renovate has not moved the repo past it, so the
redeploy branch never opened and `ls349` was used as-is.

| Item | Value |
|---|---|
| Tag at HEAD | `lscr.io/linuxserver/beets:2.13.1-ls349` |
| Image ID | `sha256:159e62e4d611cb61d5de0e14dcea41f2b77a3d6170fdf079edee6b80c40f2088` |
| RepoDigest | `lscr.io/linuxserver/beets@sha256:7bf852f33b0d59c41e74843b430ca9bf75a449c26ddf03cc6d2c508737c783a2` |
| Residency | already resident; **nothing was pulled** |
| `df -h /` | `126G 86G 34G 72%` |

Version asserted **before any `up`**, in a `--rm --pull never --network none` container with an
explicit throwaway `-l`:

```
$ docker run --rm --pull never --network none --entrypoint beet \
    lscr.io/linuxserver/beets:2.13.1-ls349 -l /tmp/version-04.blb version
beets version 2.13.1          <-- required value
Python version 3.12.14
plugins: musicbrainz
```

### HALT preconditions — all checked with nothing running

| Precondition | Required | Measured |
|---|---|---|
| `/config/library.db` absent | yes | **absent** |
| `/config/musiclibrary.blb` absent | yes | **absent** |
| `/config/config.yaml.old` absent | yes | **absent** |
| survivor `config.yaml` sha = 04-01 junk sha | `8b09078d…` | **`8b09078d…`** (re-asserted *before* the install overwrote it) |
| live sabnzbd `beets-config.yaml` sha = 04-01 | `7a059a40…` | **`7a059a40…`** |
| D-29 album present, 12 FLAC, single disc | 12 / 0 subdirs | **12 top-level FLAC, 12 recursive, 0 subdirectories, 0 audio below top level** |
| positive control (`config.yaml` visible) | yes | yes |

All three HALT conditions were **re-asserted a second time inside the lifecycle**, before `up`, on
each of the three runs.

### D-27 install and the overlays

- `cp` onto the existing file — **same inode `34432`**, 3293 B → 6175 B, never `mv`.
- Installed sha `a2f94cb6d5ce511faea092cb473b8c4cccc80bfd4635628f999493974ae3c9e9`, `cmp` against the
  repo copy returns **byte-identical**.
- Uniqueness checked before any `sed`: `^plugins: embedart$` ×1, `^    write: yes$` ×1,
  `^    log: /config/scripts/beets.log$` ×1, and **0** top-level `library:`/`directory:`/`statefile:`/`log:`
  keys — so nothing outside `probe-04` needed redirecting.
- `broken.yaml` = the live sabnzbd config verbatim plus probe-only keys: `write: no` (was `yes`),
  `copy: no` and `move: no` (already), `log: /config/probe-04/import.log`, and a top-level
  `statefile: /config/probe-04/state.pickle`.
- `fixed.yaml` differs by **one line**:

```
$ diff broken.yaml fixed.yaml
35c35
< plugins: embedart
---
> plugins: embedart musicbrainz
changed-line count: 2      <-- required value
```

### PRE-UP listing

`.bash_history` 602 · `.cache/` · `Music/` · `beet.log` 120 · `beets.sh` 674 · `config.yaml` 6175 ·
`probe-04/` · `state.pickle` 47. `state.pickle` sha `f6a9a1ad…`, `du -s Music` **1455677**,
`library.db` **absent**.

Task 1 `<verify>` → **`PRE-UP-OK`**.

---

## Task 2: the trap-guarded lifecycle

### Which base config was mounted (04-08's carry-forward, 04-PATTERNS § No Analog Found)

**Every `beet` invocation below read the same base config**: the D-27 vendored file at
`/mnt/fast/appdata/arrs/beets/config/config.yaml` → `/config/config.yaml` `:ro`, sha
`a2f94cb6…`, whose own `plugins:` line is `musicbrainz`. The `-c` overlays therefore override a
**present** `plugins:` key, not an absent one — and the transcripts below show the override winning
cleanly in both directions, which is the thing 04-08 asked this plan to record.

### (b) Start, and the mounts

| Item | Value |
|---|---|
| `compose config --quiet` | rc **0** |
| `up -d --pull never beets` | rc **0**, container reached `running` |
| `docker logs` size | **5759 B** (printed beside the grep, so `(none)` below is a real reading) |
| `/mnt/tank/media -> /media` | **RW=false** |
| `/mnt/fast/appdata/arrs/beets/config/config.yaml -> /config/config.yaml` | **RW=false** |
| `/mnt/tank/downloads -> /downloads` | RW=true (declared) |
| `/mnt/fast/appdata/arrs/beets/config -> /config` | RW=true (declared) |

**D-09 / Pitfall 7 result — the `:ro` boot question, answered:**

| Pattern searched across all 175 log lines | Count |
|---|---|
| `Read-only file system` | **0** |
| `Permission denied` | **0** |
| `lsiown` | **0** |
| `chmod` | **0** |

The image reported `User UID: 568` / `User GID: 568`, `[custom-init] No custom files found,
skipping...` and `[migrations] no migrations found`. **No EROFS line had to be tolerated under the
D-09 rule, and nothing justified flipping the mount to `:rw`.** This is now recorded in
`beets.yaml` itself (commit `fc6d35f`), replacing the block that claimed it was UNMEASURED.

**A3 confirmed:** `svc-beets` runs `beet web`, the `web` plugin is not loaded, and the log carries
20 × `error: unknown command 'web'` as s6 restarts it. Container `RestartCount=0` throughout — the
crash loop is internal to s6, not a container restart.

### (c) The fresh library.db (D-28)

| Fact | Value |
|---|---|
| Path | `/mnt/fast/appdata/arrs/beets/config/library.db` |
| Creator | **`svc-beets`** — created at `23:42:52`, one second after the container's `StartedAt` |
| `PRAGMA integrity_check` | **ok** |
| `SELECT count(*) FROM items` | **0** |
| `SELECT count(*) FROM albums` | **0** |
| Size / sha256 | 53248 B / **`fbbdde0c416e72b9884e56c562fd88eaa4da447926e1cb6cc17c3e04aee7da1a`** |
| Unexpected `library.db*` siblings | **0** |
| Migration `.bak` siblings | **11** (see Deviation 2) |

**Honest note on the creator.** The database was created during this plan's **first** lifecycle run
— the one that HALTed at exit 21 (Deviation 1). It was created by the survivor, at the path D-27
declares, at 2.13.1-ls349, which is exactly what D-28 specifies, so it was kept rather than deleted
and re-made. It cannot have been created by the failed `beet -l /config/library.db stats`: that
command aborted during config load, before beets opens any library, and its pre-init uid could not
write into the 755 `apps`-owned `/config` at all. On the successful run `library.db existed before
up: yes` is recorded rather than papered over.

### (d) POST-UP baseline (REVIEWS row 16)

Taken **after** `up` and after the fresh DB, as row 16 requires.

`state.pickle` POST-UP sha256: **`f6a9a1ad7aa553e42e53a8056fa80724785111180a5e2122be4f8732d1e4bc7c`**
— identical to its PRE-UP value.

**PRE-UP → POST-UP differences:** exactly one — `library.db` and its 11 `.bak` appeared. Nothing
else changed: `state.pickle` did not move, `Music/` did not move, no file was added or removed by
the LSIO/s6 passes.

**REVIEWS row 16 is now MEASURED rather than PLAUSIBLE:** the crash-looping `beet web` ran for the
whole of three separate up-intervals and **never wrote `state.pickle`**. The hazard the row
anticipated does not exist for this image at this version.

### (e) The authoritative plugin reading, inside the survivor

```
$ docker exec -u abc beets beet -l /config/probe-04/version.blb version      # no -c
beets version 2.13.1
Python version 3.12.14
plugins: musicbrainz          <-- C4-a, live, in the container this phase ships
```

### (f) The criterion-4 instrument

**(1) Overlay plugin lines — the two arms differ exactly as intended**

```
$ beet -c /config/probe-04/broken.yaml -l /config/probe-04/version.blb version
plugins: embedart                      <-- musicbrainz absent

$ beet -c /config/probe-04/fixed.yaml  -l /config/probe-04/version.blb version
plugins: embedart, musicbrainz         <-- the one-line difference, as loaded
```

**(2) Gate control — refused, rc 2**

```
REFUSING TO RUN: required beets plugin(s) did not load: musicbrainz
  requested by config: embedart
  actually loaded:     embedart
  config: /config/probe-04/broken.yaml
```

Neither `--require-plugin` nor the live sabnzbd file was touched to make this pass.

**(3) NEGATIVE arm (D-17) — the live broken config, rc 0, elapsed 0.4 s**

```
plugins loaded:    embedart
[1/1] Garth Brooks-Scarecrow-...: 1 record(s), loose=False strict=False (0.4s)
folders failed (.failed): 0
```
```json
{"n_files": 12, "plugins_enabled": ["embedart"], "record_type": "no_candidates",
 "candidates": 0, "source": null, "album": null, "n_tracks": null,
 "distance": null, "recommendation": "none"}
```

**MusicBrainz records: 0.** This is a real zero, not a refusal and not a failure: the folder was
probed, 12 audio items were read, and the run completed with an explicit `no_candidates` record.

**(4) POSITIVE arm — the fixed config, same album, same `-l`, rc 0, elapsed 6 s**

```
plugins loaded:    embedart, musicbrainz
DEBUG urllib3 https://musicbrainz.org:443 "GET /ws/2/release?...garth+brooks..." 503 None
DEBUG urllib3 Retry: ...
DEBUG urllib3 https://musicbrainz.org:443 "GET /ws/2/release?...garth+brooks..." 503 None
DEBUG urllib3 Retry: ...
DEBUG urllib3 https://musicbrainz.org:443 "GET /ws/2/release?...garth+brooks..." 200 1650
[1/1] Garth Brooks-Scarecrow-...: 1 record(s) (5.9s)
```

**MusicBrainz records: 1.** Top (only) candidate:

| Field | Value |
|---|---|
| album | `Scarecrow` |
| n_tracks vs n_files | **12 vs 12** |
| distance | **0.04833601097178683** |
| recommendation | **strong** |
| source | `MusicBrainz` |
| plugins_enabled | `["embedart", "musicbrainz"]` |

**The 503 rule (DEF-03-07) did not have to fire at the plan's level, and is recorded because it very
nearly did.** MusicBrainz returned **503 twice** before answering 200. `musicbrainzngs`' own
`urllib3` retry absorbed both, so the arm returned 1 on its first attempt. Had the retry not
absorbed them the arm would have returned zero *with a 503 in its log* — the exact reading D-17
forbids treating as zero — and the built-in 60 s re-run (max 3) would have handled it.

**(5) Hand-read cross-check — agent-driven, aborted at the prompt**

```
/downloads/complete/nzb/music/Garth Brooks-Scarecrow-... (12 items)

  Match (95.2%):
  Garth Brooks - Scarecrow
  ≠ media, tracks
  MusicBrainz, HDCD, 2001, US, Capitol Records, 7243-5-31330-2-3
  https://musicbrainz.org/release/0b4f6fcb-be89-47b2-8921-a1223598be08
  * Artist: Garth Brooks
  * Album: Scarecrow
     ≠ (#1) Why Ain't I Running -> (#1) Why Ain’t I Running
     ...
➜ [A]pply, More candidates, Skip, Use as-is, as Tracks, Group albums,
  Enter search, enter Id, aBort?
```

`b` was sent; `beet` exited 0; **nothing was imported**.

### (g) Post-arm assertions — all held

| Assertion | Required | Measured |
|---|---|---|
| `probe.blb` items | 0 | **0** |
| survivor `library.db` sha unchanged since (c) | `fbbdde0c…` | **`fbbdde0c…`** |
| `state.pickle` sha = POST-UP baseline | `f6a9a1ad…` | **`f6a9a1ad…`** |

Lifecycle exit **0**, final line `CLEANUP: dormant`.
Task 2 `<verify>` → **`LIFECYCLE-OK`**.

### The driven failure-path control (REVIEWS row 3)

`library.db` sha recorded **before** the control: `fbbdde0c…`.

```
$ LIFECYCLE_FORCE=term-after-up timeout -k 120 600 bash lifecycle.sh
### LIFECYCLE_FORCE=term-after-up — container is running; sending myself SIGTERM in 3s
### CLEANUP (exit path rc=143)
  compose down rc=0
CLEANUP: dormant
FORCE_RC=143            <-- required value
```

After it: `integrity_check` **ok**, items **0**, sha **`fbbdde0c…` — unmoved**, 11 `.bak`. The
database did **not** move while `svc-beets` had it open.

**The trap therefore has three independent firings on record:** rc 0 (success), rc 143 (driven
signal) and rc 21 (a real, unplanned HALT — Deviation 1). All three printed `CLEANUP: dormant`.

---

## Task 3: independent dormancy proof, cleanup and the wave boundary

### Dormancy — producer status captured FIRST

| Step | Result |
|---|---|
| `docker ps -a` | rc **0**, **97** containers |
| positive control `sabnzbd` | **listed** |
| container named `beets`, any state | **0** — no status filter used |
| `docker network ls` | rc 0; `beets_default` **0** |

**Driven error branch**, the same check with `DOCKER_HOST=unix:///nonexistent-04.sock`:

```
failed to connect to the docker API at unix:///nonexistent-04.sock ... no such file or directory
UNKNOWN docker ps rc=1
ERROR_BRANCH_RC=3          <-- UNKNOWN and exit 3, never DORMANT
```

Task 3 `<verify>` on the live daemon → **`DORMANT`**, rc 0.

### Cleanup (S5 guard)

Each target: `..` refused → `realpath -e` → resolved path must equal the literal target → entry
count printed → `rm -rf` → `test ! -e`.

```
target /mnt/fast/appdata/arrs/beets/config/probe-04 resolves to itself; entries=33
GONE /mnt/fast/appdata/arrs/beets/config/probe-04
target /mnt/fast/scratch-04/09 resolves to itself; entries=43
GONE /mnt/fast/scratch-04/09
removed now-empty /mnt/fast/scratch-04
positive control: config.yaml still visible (we can still look)
```

### Survivor tree vs the POST-UP baseline

`LISTING-MATCHES` — the **only** difference from the POST-UP listing is `probe-04` being gone.

| Item | POST-UP / Task 1 | Now |
|---|---|---|
| `state.pickle` sha | `f6a9a1ad…` | **`f6a9a1ad…`** |
| `du -s Music` | 1455677 | **1455677** |
| `library.db` sha | `fbbdde0c…` | **`fbbdde0c…`** |

### CANDIDATE census — RC **1** in 6 s, exactly the expected-red set

```
✅ tagger definitions: expected=1 at stacks/selfhosted/arrs/beets/beets.yaml — found exactly that
❌ beets databases: expected=1 ... — found 36
❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb
❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log
❌ retired path PRESENT: /mnt/fast/appdata/arrs/sabnzbd/config/.config/beets
   rw on Music, D-21 consumer exception: jellyfin [running]
```

| Counter | 04-07 | **Now** | Target |
|---|---|---|---|
| tagger definitions | 1 | **1** | 1 |
| beets databases | 24 | **36** | 1 (see Deviation 3) |
| tagger databases | 0 | **0** | 0 |
| retired paths present | 3 | **3** | 0 (04-11) |
| rw on Music, non-tagger | 0 | **0** | 0 |
| rw on Music, tagger-capable | 0 | **0** | 0 |
| rw on Music, Jellyfin D-21 | 1 | **1** | documented exception |
| tagger-capable containers | 2 | **2** | reported |
| FAILURES total | 4 | **4** | — |

**The 36 is exactly 12 + 12 + 12**: the survivor's `library.db` + 11 `.bak`, sabnzbd's
`.config/beets/library.db` + 11 `.bak`, and sabnzbd's `scripts/library.blb` + 11 `.bak`.
`jellyfin.db` is **not** among them — it is printed separately under *"other SQLite files matched by
the candidate names (REPORTED, not failed — another app's database, and the Jellyfin positive
control)"*, which also proves the census was not blind.

**Nothing outside the expected set appeared, and the classifier was NOT narrowed.** `*.blb` and
`.bak` were not excluded and sabnzbd was not special-cased — doing so would recreate DEF-03-01's
blindness (REVIEWS rows 1 and 9).

### ROUTINE runs — within the 04-01 ROUTINE BASELINE

| Check | Where | 04-01 baseline | This plan |
|---|---|---|---|
| `check-music-freeze.sh` (no env) | LXC 100 | RC **0**, no ❌, 2 permanent mode ⚠️, FAILURES 0 | RC **0**, **0** ❌, the same 2 ⚠️, FAILURES 0 |
| `quick-health-check.sh` (no env) | workstation | RC **0**, sole ❌ Traefik dashboard, no ⚠️ | RC **0**, sole ❌ Traefik dashboard, **0** ⚠️ |

The routine host run leaked **0** `retired path PRESENT` lines and printed the candidate gate line,
so 6b is still dormant. Fold-in positive controls both answered: `Music freeze harness: ✅ Intact`,
`Jellyfin transcode retention: ✅ Transcode retention intact`. **The finding set is identical to the
baseline, not merely a subset.**

---

## Decisions Made

- **`:ro` stays** on the survivor's config mount. Measured, not assumed — zero EROFS lines.
- **The 11 migration `.bak` were left in place.** See Deviation 2/3.
- **`beets.yaml`'s NOTE was corrected** even though no flip was required, because it asserted the
  measurement did not exist and named this plan as its owner.

## Deviations from Plan

### 1. [Rule 3 — Blocking] The LSIO init race: a false EACCES *and* a false-green EROFS grep

- **Found during:** Task 2, first lifecycle run, which HALTed at **exit 21**.
- **Issue:** the script waited for `.State.Status == running` before `docker exec`. That status is
  true **immediately**, long before s6 has remapped `abc` to PUID 568 and finished init. The `beet`
  call therefore ran as the image-default uid and died with
  `configuration error: /config/config.yaml could not be read: [Errno 13] Permission denied`.
  **Worse than the failure itself:** in the same window `docker logs` was still **empty (0 bytes)**,
  so the plan's required EROFS grep printed `(none)` — a "no EROFS" reading taken from a log that
  did not yet exist. That would have been published as the D-09 answer.
- **Fix:** gate on the capability actually needed, not on a status word — wait for
  `docker exec -u abc beets test -r /config/config.yaml`, and print the container log's **byte
  count** next to every grep taken over it so an empty producer can never read as a clean result.
- **Verification:** re-run reported `abc uid inside container: 568`,
  `/config/config.yaml readable by abc: yes`, `docker logs byte count: 5759`, and the EROFS grep
  then returned a meaningful `(none)` over 175 real lines.
- **Not a permission change:** nothing was loosened on the host to make this pass. The file is
  `apps:apps`, `abc` **is** 568, and post-init it reads fine.
- **Bonus evidence:** this HALT is a genuine, unplanned exercise of the failure path — it ended
  `CLEANUP: dormant` with the container removed, before the planned TERM control ever ran.

### 2. [Defective assertion — recorded, NOT satisfied] "no migration `.bak`" fails on a correct outcome

- **Found during:** Task 1, in a throwaway `--rm` container, **before** anything started.
- **Issue:** the plan's step (c) requires "no `library.db*` sibling other than the DB itself (no
  migration `.bak`)". Measured: **beets 2.13.1 writes exactly 11 `.bak` on the FIRST open of ANY
  database, fresh and empty ones included**, and **none** on subsequent opens (11 → 11 → 11), with
  `integrity ok` and `items 0` throughout. The assertion is therefore unsatisfiable by a correct
  D-28 outcome.
- **Resolution:** recorded as defective and the gate replaced with the intent that survives
  measurement — *no **unexpected** sibling beyond the DB and those 11 known migration names*, which
  measured **0**. **No file was deleted to make an assertion pass.** The note is printed verbatim in
  the run transcript, not only here.

### 3. [Finding — blocks 04-11's target as written] "one `library.db`" is 12 files, not 1

- **Found during:** Task 3 census.
- **Issue:** as a direct and unavoidable consequence of Deviation 2, the survivor now contributes
  **12** entries to the census (`library.db` + 11 `.bak`), not 1. `beets databases` therefore reads
  **36**, and after 04-11 deletes sabnzbd's 24 it will read **12**, never **1**. Criterion 5's
  counter as currently specified cannot reach its target.
- **Not fixed here.** Deletion is 04-11's lane and this plan had no mandate to remove them.
- **Recommendation for 04-11 (choose deliberately, do not narrow the classifier):** the 11 `.bak`
  are backups of an **empty** database taken during its own creation — they carry nothing. Deleting
  them by exact name, fenced like every other deletion, makes `beets databases: 1` true. The
  alternative — teaching the census to ignore `.bak` — would re-create DEF-03-01's blindness and
  should be refused.

### 4. [Rule 2 — Missing critical, documentation accuracy] `beets.yaml` claimed its own result was UNMEASURED

- **Found during:** Task 2, after the D-09 result was in hand.
- **Issue:** the plan authorises touching `beets.yaml` "only if the measured `:ro` flip is
  required". It was not required. But the file asserted *"That is UNMEASURED at this commit: plan
  04-09 starts the container … and records whatever it logs"* — a claim this plan had just
  falsified, sitting in the file a future reader consults first.
- **Fix:** in-band dated amendment recording the measurement (0 EROFS / 0 Permission denied /
  0 lsiown / 0 chmod over 175 lines, `RW=false` on both mounts, `:ro` stays) and the init race from
  Deviation 1. **Comment-only: 0 non-comment changed lines**; `/mnt/tank/media:/media:ro`,
  `restart: "no"`, `profiles: ["manual"]` and the config mount line all byte-unchanged; host
  `compose config --quiet` rc 0 after the pull.
- **Committed in:** `fc6d35f`.

### 5. [Instrument limitation — recorded, not worked around] the probe has no MusicBrainz HTTP counter

- The plan asks the negative arm to show "no MusicBrainz HTTP request". The probe counts **Discogs**
  responses and connections only; there is no MusicBrainz equivalent to read.
- **What is actually evidenced:** `plugins_enabled: ["embedart"]` (the authoritative reading),
  a `record_type: no_candidates` with `source: null`, and **0.4 s** elapsed — against the positive
  arm's **6 s** with `musicbrainz.org` requests visible in its transcript. That is strong
  corroboration, but it is inference from absence, not a packet-level count, and is written down as
  such rather than claimed as a direct measurement.

### 6. [Note] the `ls.io-init done` marker never appears in this image

Both good runs recorded `LSIO init reported done: no` while `abc uid = 568` and the config was
readable. This image prints `[custom-init] No custom files found, skipping...` and
`[migrations] no migrations found`, not the marker the wait loop greps for. The marker is therefore
**not** a valid readiness signal here; the readability probe is, and it is what actually gated.
Recorded so a later plan does not treat the `no` as a fault.

### 7. [Minor] `chmod 660` on the installed config produced mode `760`

Recorded as measured rather than retried into agreement. Harmless: `abc` is uid 568 and owns the
file, so the owner bits apply and the file reads. Consistent with this estate's documented
chmod-vs-ACL behaviour.

---

**Total deviations:** 7 — 1 blocking fix, 1 defective assertion recorded, 1 downstream-blocking
finding, 1 missing-critical doc correction, 1 instrument limitation, 2 notes. **None weakens an
assertion, and no control was made to pass by editing prose, deleting a file, or changing the
estate.**

## Threat Flags

None. No new network endpoint, auth path or trust boundary. The register's seven entries were each
mitigated and measured:

- **T-04-09-01 (tampering via `import`)** — `-W -C`, overlay `write/copy/move: no`, aborted at the
  prompt, `probe.blb` items asserted **0**.
- **T-04-09-02 (survivor library.db)** — every probe/version run used a throwaway `-l` under
  `probe-04`; **no bare `beet` was ever issued**; the survivor DB's sha is unchanged across all
  three container starts.
- **T-04-09-03 (library mount)** — `/media RW=false` asserted by `docker inspect`; nothing flipped it.
- **T-04-09-04 (supply chain)** — `up --pull never`; nothing pulled; tag/digest/image ID recorded;
  `beets version 2.13.1` asserted in a `--rm` container before `up`.
- **T-04-09-05 (Discogs token)** — `--mb-only` throughout; `discogs HTTP responses seen: 0`,
  `discogs new connections: 0`; the credential was never read and appears nowhere.
- **T-04-09-06 (`rm -rf`)** — S5 guard: `..` refusal, `realpath` equality, entry count before,
  `test ! -e` after, `config.yaml` as the positive control.
- **T-04-09-07 (survivor left running)** — preconditions before `up`; EXIT/INT/TERM/HUP trap;
  `cmd & wait $!`; Linux-side `timeout -k`; the trap observed firing on **three** distinct exit
  paths; independent producer-status-first dormancy check with its error branch driven.

## Known Stubs

None.

## Issues Encountered

- **No credential, `.env` value or release name other than the D-29 album was printed**, in keeping
  with the plan's conventions. Every compose invocation used `--quiet`.
- The two pre-existing untracked host files were left exactly as found; a host `git status
  --porcelain` is non-empty **by design**, so any assertion demanding an empty porcelain remains
  defective (04-06 deviation 2).
- One harness error of my own: a poll command with an oversized `sleep` exceeded its own bound and
  was killed. The lifecycle was unaffected — it ran detached on the host under its own
  `timeout -k 120 2700` — and the poll was read-only.

## Next Phase Readiness

- **04-11** inherits a green path for everything except the counter in Deviation 3. Before it can
  claim criterion 5 it must decide, deliberately, what to do about the survivor's **11 `.bak`**;
  deleting them by exact name (fenced) is the recommendation, narrowing the classifier is not.
  Expect `beets databases: 36` → `12` after its sabnzbd deletions, `retired paths present: 3` → `0`,
  and `tagger-capable containers: 2` (lidarr + sabnzbd), not 1.
- **04-11** also now has the D-09 answer it needs for the sabnzbd `:ro` recreate: on this estate a
  `:ro` single-file mount into an LSIO `/config` produced **no** EROFS at boot. sabnzbd additionally
  runs `scripts_init.bash`'s `chmod 777 -R /config/scripts`, so its result may still differ — but
  the survivor's clean boot is the relevant prior, and the init-race lesson applies verbatim: wait
  for readability, never for `running`.
- **04-13** can quote criterion 4 as **measured**: 0 vs 1 MusicBrainz candidates on the same album
  with configs differing by one line, plus the 95.2% hand-read. TAGR-05's proving instrument has
  produced its evidence.
- **D-17's ordering is now spent.** The negative control has been run against the live broken
  sabnzbd config, so 04-11 is free to install the fixed one.

## Self-Check: PASSED

- FOUND commit `fc6d35f`; it is on `origin/main` and on the host at `fc6d35f`; host and workstation
  `beets.yaml` sha256 are equal (`957463769fd8…`).
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-09-SUMMARY.md`.
- Task 1 `<verify>` → `PRE-UP-OK`; Task 2 `<verify>` → `LIFECYCLE-OK`; Task 3 `<verify>` → `DORMANT`
  (rc 0), and its driven error branch → `UNKNOWN`, **exit 3**.
- Survivor `library.db`: `integrity_check ok`, items 0, sha `fbbdde0c…`, 0 unexpected siblings.
- Lifecycle rc 0 and force-TERM rc 143, each with exactly one `CLEANUP: dormant`.
- `probe-04` and `/mnt/fast/scratch-04` absent, with `config.yaml` visible as the positive control.
- Census RC 1 with exactly 4 failures and nothing outside the expected-red set; routine freeze RC 0
  and workstation quick-health-check RC 0, both at the 04-01 baseline finding set.
- **`.planning/STATE.md` and `.planning/ROADMAP.md` were not touched, and no `gsd-sdk query state.*`
  or `roadmap.*` verb was called.** No commit deleted any tracked file.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-11*
