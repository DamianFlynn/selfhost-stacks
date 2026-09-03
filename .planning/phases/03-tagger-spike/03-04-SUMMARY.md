---
phase: 03-tagger-spike
plan: 04
subsystem: spike-infrastructure
tags: [beets, discogs, throwaway-compose, mount-layer-safety, TAGR-01, TAGR-02, TAGR-05, D-02, D-03, D-20]
requires:
  - "03-01 — the OD-1 disk-headroom gate and the image pulls (2.13.1-ls349 was already local)"
  - "03-03 — the scratch tree at /mnt/tank/downloads/spike-03 that this container mounts"
  - "03-02 — D-04's /mnt/fast/secrets/discogs.env, live at 600 root"
provides:
  - ".planning/phases/03-tagger-spike/03-spike-beets.yaml — the throwaway axis-one compose, two services"
  - ".planning/phases/03-tagger-spike/03-spike-beets-config.yaml — the token-free spike beets config"
  - "beets-spike — a running beets 2.13.1 container with all four plugins provably loaded"
  - "the measured Discogs rate ceiling: x-discogs-ratelimit = 60 (A6 confirmed)"
  - "the corrected plugin-load proof method: `beet ... version`, not `beet config -d`"
  - ".planning/phases/03-tagger-spike/deferred-items.md — DEF-03-01, DEF-03-02"
affects:
  - "03-05 — brings up beets-spike-rw for its --apply step and takes it down after; its dry run runs on beets-spike"
  - "03-06 — the probe runs here; must assert plugin loading on `beet version`, not on a config -d block"
  - "03-07 — the four-cell run and the `beet import -t` cross-check run here; criterion 2 uses ratelimit 60"
  - "03-10 — the terminal ergonomics arm runs here, importing from bf-inbox/ :ro"
  - "03-11 — archives this compose in place with its banner; teardown must be `down -v`"
tech-stack:
  added:
    - "lscr.io/linuxserver/beets:2.13.1-ls349 (throwaway, phase-directory compose)"
  patterns:
    - "A compose file whose two services are kept identical-but-one-mount by a YAML anchor, so the claim cannot rot into two drifting copies"
    - "Mount-layer prevention over post-hoc detection: a plan that only reads gets no write handle on what it reads"
    - "Binding tank paths at identical paths inside and outside the container, so a recorded path means the same thing on both sides"
    - "Generating a credential-bearing runtime config INSIDE the container from os.environ, so the value never reaches an argv or the process table"
key-files:
  created:
    - .planning/phases/03-tagger-spike/03-spike-beets.yaml
    - .planning/phases/03-tagger-spike/03-spike-beets-config.yaml
    - .planning/phases/03-tagger-spike/deferred-items.md
  modified: []
decisions:
  - "`beet config -d` block presence is NOT proof a plugin loaded — the discogs plugin printed a full defaults block while failing to load. Every later plan asserts on `beet ... version`'s plugins line instead"
  - "The discogs plugin cannot load without a user_token; the committed config stays token-free and a runtime BEETSDIR config supplies it, generated in-container with umask 077 and never committed"
  - "`docker compose config` resolves env_file into the rendered environment and prints the token; all rendering passes --no-env-resolution"
  - "The two services differ by exactly one mount, enforced by a YAML anchor rather than by two hand-maintained copies"
  - "raw/, smoke/ and bf-inbox/ are :ro on BOTH services, not only on the measurement arm — no plan in this phase writes them"
metrics:
  duration: "~1h"
  completed: 2026-09-03
---

# Phase 3 Plan 04: Beets Spike Container Summary

Stood up the throwaway beets 2.13.1 measurement host for axis one with Music unreachable at the
mount layer rather than by policy — and found that the plan's own plugin-load proof was unsound:
the Discogs plugin **failed to load** while `beet config -d` printed a full `discogs:` block, so
the container would have measured a 0% Discogs match rate and reported it as evidence.

## What was built

**`.planning/phases/03-tagger-spike/03-spike-beets.yaml`** — the throwaway compose, in the phase
directory rather than under `stacks/` (D-03), carrying `THROWAWAY — DO NOT DEPLOY` as its first
line. Two services on `lscr.io/linuxserver/beets:2.13.1-ls349` (D-02), `restart: "no"`,
`profiles: ["manual"]`, `no-new-privileges`, no ports, no Traefik labels, no networks.

The load-bearing design choice is that **the two services are one YAML anchor plus one differing
mount**. The plan requires `beets-spike` and `beets-spike-rw` to be identical but for
`normalised/`'s mode. Written as two copies that claim would rot the first time somebody edited
one; written as `<<: *spike-common` with a per-mount anchor list it is structurally true and a
`diff` of the rendered JSON proves it.

The second choice is **mount-layer prevention over detection**. `raw/`, `smoke/` and `bf-inbox/`
are `:ro` on *both* services and `normalised/` is `:ro` on the measurement arm, so plan 03-05's
dry run cannot write even if its `--dry-run` flag is wrong, and no read-only measurement plan
holds a handle on the sample it measures. `/mnt/tank/media` is not mounted at any mode — the
`wrtag.yaml:39-58` deleted-not-commented pattern, with D-20 recorded in place.

**`.planning/phases/03-tagger-spike/03-spike-beets-config.yaml`** — the spike beets config, with
`musicbrainz` listed explicitly (TAGR-05), `import.move: no` / `copy: yes` against the estate's
`move: yes` (Pitfall 5), both `discogs.index_tracks` and `search_limit` stated rather than
defaulted, and five `auto:` keys disarmed in advance. It carries no credential.

## Results

| Assertion | Result |
|---|---|
| `docker compose … config --quiet` | **exit 0**, stderr empty, `variable is not set` warnings **0** |
| Rendered image, both services | **`lscr.io/linuxserver/beets:2.13.1-ls349`**, one line from `sort -u` |
| Rendered service count / names | **2** — `beets-spike`, `beets-spike-rw` |
| Volume sources under `/mnt/tank/media`, both services | **0** |
| `beets-spike`: spike-03 mounts not `read_only` | **0** |
| `beets-spike-rw`: writable spike-03 mounts | **1**, `/mnt/tank/downloads/spike-03/normalised` |
| `/mnt/tank/downloads/spike-03` mounted as one tree | **0** |
| `normalised-metadata`, `wrtag-src`, `/mnt/fast/spike-03` wholesale | **0** each |
| `env_file` on both services | `/mnt/fast/secrets/discogs.env` |
| `TOKEN`/`SECRET` keys in rendered `environment` | **0** (with `--no-env-resolution`; see deviation 2) |
| `TZ` / `PUID` / `PGID` / `BEETSDIR` | `Europe/Dublin` / `568` / `568` / `/spike-config` — no empty strings |
| Banner on line 1 | `THROWAWAY — DO NOT DEPLOY` |
| Frozen files in this plan's diff | **none** — `beets.yaml`, `wrtag.yaml`, `renovate.json5` all untouched (D-03) |
| `beet --version` | **2.13.1** (Python 3.12.14) |
| **Loaded plugins** | **`discogs, fromfilename, importsource, musicbrainz`** — all four |
| `config -d \| grep -cE '^(discogs\|musicbrainz):'` | **2** |
| `discogs.search_limit` / `index_tracks` in effect | `5` / `no` — explicit settings took, not defaults |
| `import.copy` / `move` / `write` / `incremental` / `resume` | `yes` / `no` / `no` / `no` / `no` |
| Discogs `GET /oauth/identity` | **HTTP 200**, username `damian.flynn` |
| **`x-discogs-ratelimit`** | **60** (used 2, remaining 58) — **A6 confirmed, not assumed** |
| Secrets gate before anything sourced | `stat -c '%a %U'` = **`600 root`**; no `set -a` in the transcript |
| Running container: mounts under `/mnt/tank/media` | **0** |
| Running container: writable mounts under `spike-03` | **0** |
| `Privileged` / `CapAdd` / `RestartPolicy` | `false` / `[]` / `no` |
| `beets-spike-rw` in `docker ps -a` | **absent** — not started by this plan |
| `bash scripts/check-music-freeze.sh` | **exit 0**, `tagger-class writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` |
| Beets databases under `/mnt/fast/appdata` modified after container creation | **0 of 4** |
| `.bak` files under `/mnt/fast/appdata` created after container creation | **0** |
| `/tmp` entries matching `spike` | **0** |
| `df -h /` | 35 G free, unchanged across the plan |

## The findings that outlive this plan

**1. `beet config -d` printing a plugin's block does NOT prove the plugin loaded.** This is the
headline, because the plan and 03-RESEARCH.md both rest on it and both are half wrong. With no
`user_token`, `beetsplug/discogs/__init__.py:145` falls through to the OAuth branch, fails to open
`discogs_token.json`, calls `authenticate()`, blocks on stdin and raises:

```
** error loading plugin discogs
beets.exceptions.UserError: stdin stream ended while input required
plugins: fromfilename, importsource, musicbrainz          <- discogs ABSENT
```

…and `beet config -d` **still emitted a complete `discogs:` block** carrying our own
`index_tracks: no` / `search_limit: 5`, because `DiscogsPlugin.__init__` registers its defaults via
`self.config.add(...)` *before* it calls `self.setup()` on line 105. The research rule survives in
one direction only: **absence of the block is a loading failure; presence of the block is not proof
of loading.** The authoritative instrument is `beet -c … -l … version`, whose `plugins:` line lists
only successfully constructed plugins.

This matters far beyond one acceptance criterion. Had it gone unnoticed, criterion 1 would have run
with MusicBrainz alone, returned **zero Discogs candidates on every folder**, and the phase would
have concluded that Discogs does not carry this collection — falsifying T1 in the direction of
"beets' only structural advantage evaporates", on an artefact. That is the same shape as the
TAGR-05 defect this phase exists to close: **a silent source disablement that presents as "no match
found" rather than as an error.** TAGR-05's known instance is an omitted `musicbrainz` entry in
`plugins:`; this is a second instance, with a different cause and the same symptom.

**2. `docker compose config` prints the Discogs token.** Compose v5.0.2 resolves `env_file` into the
rendered `environment` map and drops the `env_file` key (it renders `null`). So the plan's own
acceptance criterion — *"neither rendered `environment` map contains a key matching TOKEN or
SECRET"* — **cannot pass as written**, and worse, running it produces a credential-bearing artefact.
`--no-env-resolution` restores both properties: `env_file` renders as a path reference and the
criterion returns 0. `--profile manual` is also required on `config`, or compose omits both
services and reports zero.

**3. The sabnzbd beets post-processing path is live, and the freeze harness cannot see it.** Eleven
`.bak` files appeared under `/mnt/fast/appdata` during this plan's window. They are **not ours** —
full attribution below — but finding them required a wider glob than the plan specifies, and they
expose a real gap. `check-music-freeze.sh:80` classifies taggers by name
(`TAGGER_PATTERN='beets|soulbeet|wrtag|lidarr'`); `sabnzbd` does not match, yet sabnzbd runs beets
on every completed music download against its own `library.blb`. D-20 is **not** violated — sabnzbd
holds no `/mnt/tank/media` mount at any mode — but `tagger-class writers: 0` is, for this one
tagger, *silence* rather than a clean reading. Logged as **DEF-03-01**; not fixed here, because
widening a shared harness mid-wave changes the pass/fail behaviour of every other plan in it.

**4. This estate has four beets databases and two of them are named `.blb`.** The plan's
before/after instrument globs `library.db`, which finds two of the four. The one that changed —
`/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb` — is invisible to it. Four is
consistent with Phase 1 plan 01-02's count, so no new database has appeared, but the criterion as
written would have passed while a real beets database was being migrated. Logged as **DEF-03-02**
with the corrected instrument for plans 03-05 onward.

**5. Pitfall 1 fired — entirely inside the throwaway directory, which is the proof the containment
works.** `/mnt/fast/spike-03/beets-config/` now holds `library.db` + **11 `.bak` files** (created by
the LSIO `beet web` service, which runs without `-l`) and `spike-probe.blb` + **11 `.bak` files**
(created by our explicit `-l`). Eleven is the exact count Phase 1 recorded when this happened to the
*real* database — the migration count is a property of beets 2.13.1's schema, not of the database.
So the identical damage occurred, in the throwaway tree, while all four real databases stayed
byte- and mtime-identical. That is a stronger result than "we avoided it".

## Attribution of the 11 `.bak` files under `/mnt/fast/appdata`

Recorded in full because "pre-existing" is a claim that has to be earned, and this project has a
standing rule against comparing observations taken either side of one's own change.

| Fact | Value |
|---|---|
| `library.blb` and its 11 `.bak` files | `2026-09-03 20:30:59 UTC` |
| `beets.log` entry at that time | `import started Thu Sep 3 21:30:59 2026` → `skip /downloads/complete/nzb/music/Garth Brooks - Fun (2020) FLAC` (container TZ) |
| My first write of any kind to LXC 100 | `20:53:46` — the staged compose file |
| `beets-spike` `.Created` / `.StartedAt` | `20:56:46` — **26 minutes after** |
| `beets-spike` mounts under `/mnt/fast/appdata` | **0** — structurally unable to reach that path |
| Only running container mounting that directory | `sabnzbd`, `/mnt/fast/appdata/arrs/sabnzbd/config:/config:rw` |
| Beets databases modified after `20:56:46` | **0 of 4** |
| `.bak` files under appdata created after `20:56:46` | **0** |

The decisive argument is the mount table, not the clock: `beets-spike` holds no handle on
`/mnt/fast/appdata` at all, so it could not have written there whatever the timestamps said. This is
the same "absence beats detection" property the Music mount design is built on, paying off on a
question it was not designed to answer.

Note also that the folders in `beets.log`'s `skip` list — `Garth_Brooks-Ropin_The_Wind`,
`Def.Leppard-CD.Collection`, `Ed.Sheeran-Play.Extended.Edition` — are the same folders plan 03-03
named as D-10 album candidates. This live pipeline operates on the exact population Phase 3 samples.

## Deviations from Plan

### 1. [Rule 1 — Bug] The Discogs plugin did not load, and the plan's proof could not detect it

- **Found during:** Task 2, on the first `beet config -d`.
- **Issue:** finding 1 above. The plan's acceptance criterion (`grep -cE '^(discogs|musicbrainz):'`
  returns 2) **passed while the plugin was not loaded**.
- **Fix:** applied the mechanism the plan already specifies for plans 03-06/03-07 — a runtime
  config supplying only `discogs.user_token`, generated **inside the container** from
  `os.environ` with `os.umask(0o077)` and `O_CREAT` mode `0600`, written to
  `/mnt/fast/spike-03/beets-config/config.yaml`. That path is outside the git checkout, so it
  cannot be committed; the token never touches an argv, a shell variable on the host, or the
  process table. `BEETSDIR=/spike-config` makes beets read it as a lower-priority source that
  confuse merges deeply under the `-c` file — verified: `search_limit`/`index_tracks` from the
  committed file and `user_token` from the runtime file all take effect together, and
  `beet config -d` renders the token as `REDACTED`.
- **Also fixed the instrument, not just the symptom:** both artefacts now record that presence of a
  `config -d` block proves nothing, and name `beet … version` as the assertion later plans should
  use. Fixing only the token would have left the next plan with the same undetectable failure.
- **Commit:** `0969dfa`

### 2. [Rule 2 — Missing security requirement] `docker compose config` emits the token

- **Found during:** Task 1 verification.
- **Issue:** finding 2 above. The acceptance criterion returned **2** TOKEN-matching keys, and the
  render I had written to `/tmp/spike-cfg.json` on LXC 100 contained the credential in cleartext —
  on a host whose `/tmp` is tmpfs.
- **Fix:** `shred -u` on the render immediately; every subsequent render passes
  `--no-env-resolution` and is written under `/mnt/fast/spike-03/out/`, never `/tmp`. The
  requirement is recorded in the compose file's own header so a future reproduction inherits it.
  With the flag the criterion returns **0** and `env_file` renders as a path.
- **Commit:** `0969dfa`

### 3. [Rule 3 — Blocking] `/mnt/tank/downloads/spike-03/smoke` did not exist

- **Found during:** Task 2, before container start.
- **Issue:** the plan mounts `smoke/` for plan 03-06, but plan 03-03 created only `raw`,
  `normalised`, `normalised-metadata`, `bf-inbox`, `bf-clean` and `wrtag-src`. Docker auto-creates
  a missing bind source **as `root:root`**, which would have contradicted the `568:568` convention
  plan 03-03 established across the whole scratch tree.
- **Fix:** created on **atlantis**, not LXC 100 — the same delegation plan 03-03 used, and for the
  same reason: `chown` is refused inside the unprivileged container. `mkdir` + `chown 568:568`;
  `chmod` not attempted (mode is `0777` by ACL inheritance, as documented).
- **Commit:** operational; no repo change.

### 4. [Rule 1 — Bug, self-inflicted] My first Discogs identity request read the headers case-sensitively

- **Found during:** Task 2.
- **Issue:** I flattened `urllib`'s case-insensitive `HTTPMessage` into a plain `dict`, then looked
  up `X-Discogs-Ratelimit`. Discogs returns the header lowercase, so all three rate-limit values
  came back `null` — which would have been recorded as "the endpoint does not carry rate-limit
  headers" and left A6 unverified.
- **Fix:** used `HTTPMessage.get()` directly. `x-discogs-ratelimit: 60`, used 2, remaining 58.
  **Worth carrying forward:** the headers are lowercase on the wire; any later plan parsing them
  must not assume canonical casing. Cost: one extra request, out of 60/min.
- **Commit:** operational; no repo change.

### 5. [Scope] Two out-of-scope findings logged rather than fixed

- **DEF-03-01** (freeze-harness blind spot over `sabnzbd`) and **DEF-03-02** (the `*.blb` glob) are
  recorded in `deferred-items.md`. Neither was caused by this plan. Fixing DEF-03-01 means editing
  `scripts/check-music-freeze.sh`, a shared harness folded into `quick-health-check.sh` and run by
  every other plan in this wave — changing a shared assertion mid-wave, from a plan that did not
  cause the finding, makes later results unattributable.
- DEF-03-02's corrected instrument **was** applied within this plan, because the criterion it fixes
  is one of this plan's own.

### 6. [Deferred to the orchestrator] Delivery to LXC 100 was out-of-band

- The plan's delivery path is `git pull --ff-only` at `/mnt/fast/stacks`. A worktree executor cannot
  push, and `/mnt/fast/stacks` sits at `c88c268`. Both artefacts were staged to `/mnt/fast/spike-03/`
  — deliberately outside the git checkout, so a later `git pull --ff-only` is not blocked by an
  untracked file the incoming commit also adds — and **sha256-verified identical to the committed
  blobs** (`6aa9502b…`, `a901eb07…`, confirmed against `git show HEAD:<path>`). Same deviation and
  same handling as plans 03-01 and 03-03.

## Recorded honestly: I briefly wrote the token to a 0644 file

While composing a verification command I mis-constructed a redirection and wrote
`$DISCOGS_USER_TOKEN` to `/mnt/fast/spike-03/.tok`, mode `644 root:root`, on LXC 100's root
filesystem. It existed for roughly 30 seconds, was `shred -u -n 3`ed as soon as I saw it, and a
full re-sweep (`grep -rl -F "$TOKEN" /mnt/fast/spike-03`) now returns **exactly one** file:
`/mnt/fast/spike-03/beets-config/config.yaml` at `600 apps:apps`, the intended runtime file.

It never entered the git repository, was never committed, and both committed artefacts are
sha256-identical to files proven token-free. But it was on disk, world-readable, on a host running
103 containers — so it is recorded rather than quietly cleaned up. **The lesson is the one this
plan already learned twice: the token must never be materialised on the host side at all.** Every
deliberate handling in this plan did it correctly — in-container, from `os.environ`, `umask 077`.
The one exposure came from an ad-hoc verification command, which is precisely where the discipline
tends to lapse.

## Known Stubs

None in the artefacts. Two intentional not-yet-populated states, both required by the plan:

- `/mnt/tank/downloads/spike-03/smoke` is **empty**. Plan 03-06 stages its known-good album there.
  The mount exists now so 03-06 does not have to create it root-owned at container start.
- `beets-spike-rw` is **defined but not started**, by design. Plan 03-05 brings it up for its
  `--apply` step and takes it down immediately after.

## Threat Flags

No new security surface. Every disposition in the plan's register was exercised:

| Threat | Outcome |
|---|---|
| T-03-16 (token in the process table) | Held — `env_file` only, no `-e`, no argv. **One 30-second lapse recorded above.** |
| T-03-17 (token committed to a public repo) | Held — both committed artefacts proven token-free by `grep -F` against the live value; the runtime token file lives outside the checkout at `600` |
| T-03-18 (`/mnt/tank/media` tampering) | Held — 0 mounts on the running container; `check-music-freeze.sh` exit 0 |
| T-03-19 (real beets databases) | Held — 0 of **4** databases modified after container creation, 0 new `.bak` under appdata. **Instrument corrected**: the plan's `library.db` glob saw only 2 of 4 |
| T-03-20b (the measured sample) | Held — 0 writable `spike-03` mounts on the running container |
| T-03-20 (the real backlog) | Held — `import.move: no`, `copy: yes`; `complete/` not mounted |
| T-03-21 (privilege) | Held — `Privileged=false`, `CapAdd=[]`, `no-new-privileges`, `RestartPolicy=no`, no ports |
| T-03-22 (frozen stacks) | Held — this plan's diff touches only `.planning/phases/03-tagger-spike/` |
| T-03-SC (package installs) | Held — **zero** installs; `python3-discogs-client` is baked into the image |

One threat-adjacent note that is not a flag: LSIO declares `/config` a `VOLUME` and this file
deliberately does not bind it, so docker created an **anonymous volume** under `/var/lib/docker/`
— on LXC 100's ext4 root. It stays empty because `BEETSDIR` is repointed, but this estate has
already lost `/` to an anonymous volume once. Teardown must be `down -v`, recorded in the compose
header for plan 03-11.

## Self-Check: PASSED

- `.planning/phases/03-tagger-spike/03-spike-beets.yaml` — FOUND
- `.planning/phases/03-tagger-spike/03-spike-beets-config.yaml` — FOUND
- `.planning/phases/03-tagger-spike/deferred-items.md` — FOUND
- Commit `2341a54` (`feat(03-04)`) — FOUND
- Commit `0969dfa` (`fix(03-04)`) — FOUND
- Committed blob sha256 == token-swept staged file sha256, both artefacts — VERIFIED
