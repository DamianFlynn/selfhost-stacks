# Phase 3 criterion 7: beets-flask evaluated by name

Companion to [`03-DECISION.md`](03-DECISION.md) § *Axis two* and to
[`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md) (the sheet the operator fills during the timed
trial).

Nothing here is applied by `docker compose`. This is the record of what beets-flask actually is,
what it was acknowledged to be **before** it was deployed, and what its eight known frictions turned
out to look like against observation rather than against documentation.

State as of 2026-09-04 — **acknowledgement ANSWERED (`deploy-rc6`), instance deployed, frictions
checked against observation.** See § *Operator decision* for the verbatim answer and the
pre-deployment assertion that dates it.

---

## Release-candidate acknowledgement

D-11 and ROADMAP criterion 7 require beets-flask to be evaluated **by name** — not dismissed, and
not assumed. `03-RESEARCH.md` § *Package Legitimacy Audit* approves the image **with a note**, and
explicitly recommends gating the trial deployment behind an operator acknowledgement. This section
is that gate. **Nothing is deployed until the decision line at the bottom is filled in.**

### The image, and the digest already on record

| Property | Value |
|---|---|
| Image | `metasauce/beets-flask:v2.0.0-rc6` |
| Digest | `sha256:9548e78f8bcda864bf557b7bb7490f7dcfb852ce3abf2f4c1501d5bb812ec2cd` |
| On-disk size | 1.12 GB |
| Pulled by | plan 03-01, recorded in [`03-REAP-LIST.md`](03-REAP-LIST.md) § *The five spike image digests* |
| Provenance | Repo moved `pSpitzner/beets-flask` (437★) → `metasauce/` in Aug 2026 per the rc6 release notes; rc6 published **2026-08-30** to both Docker Hub and GHCR. The old Docker Hub repo stops at rc5 |
| Verdict | Approved **with a note** (`03-RESEARCH.md` § *Container images*) |

**Digest re-verified against the live host on 2026-09-04**, not taken from the plan file:

```
$ ssh root@172.16.1.159 "docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}} {{.Size}}' | grep beets-flask"
metasauce/beets-flask:v2.0.0-rc6 sha256:9548e78f8bcda864bf557b7bb7490f7dcfb852ce3abf2f4c1501d5bb812ec2cd 1.12GB
```

It matches `03-REAP-LIST.md` character for character. **And `docker ps -a` on LXC 100 shows no
`beets-flask-spike` container** — only `beets-spike` (`lscr.io/linuxserver/beets:2.13.1-ls349`, up
10 hours), which is the terminal arm from the earlier plans in this phase. The acknowledgement
therefore genuinely predates the deployment rather than being back-filled around a running
container.

### The note has three parts

**1. It is a release candidate, and it has been one for eight months.**

2.0 has been in RC since **2025-12-29**. The last stable release is **v1.2.1, 28 Dec 2025** — now
eight months stale. The research recommends trialling rc6 anyway, and the reasoning is worth stating
rather than assuming: **rc6 is what a real deployment would use, and it is where the frictions
actually live.** v1.2.1 would measure a tool nobody would deploy — and worse, **1.0 removed the
interactive terminal import** in favour of UI candidate selection, which is precisely the workflow
criterion 7 exists to evaluate. A trial on v1.2.1 would not exercise the thing being decided.

"Still in RC after eight months" is itself recorded as an **axis-two risk in its own right** — a
durability question about a tool this project would depend on, not merely a version number.

**2. It has no built-in authentication, and it ships a web terminal with shell access.**

beets-flask has **no authentication of any kind** (`03-RESEARCH.md` § *Security Domain*, V2), and it
ships a **tmux-backed web terminal with shell access to the container** (`libtmux` in
`pyproject.toml`, `gui.terminal.start_path` in the config). On a host running 103 containers,
publishing that would be an elevation of privilege.

The mitigation, and it is a deliberate one:

| Control | Value |
|---|---|
| Traefik labels | **None at all** — not `chain-authelia@file`, not anything |
| Port binding | `127.0.0.1:5002:5001` — loopback only, never `0.0.0.0` |
| Reached via | SSH tunnel (`ssh -L 5002:127.0.0.1:5002 root@172.16.1.159`) or Tailscale |
| Mount of `/mnt/tank/media` | **None, at any mode** — D-20: nobody holds rw on Music during Phases 1–3, and absence is stronger than `:ro` |
| Hardening | `security_opt: [no-new-privileges:true]`, `restart: "no"`, `profiles: ["manual"]` |

The frozen `beets.yaml` and `wrtag.yaml` carry `chain-authelia@file` because they publish something.
**The spike carries no auth chain because it publishes nothing.** That is the correct reading — it
is not an omission.

**3. It pip-installs from a `requirements.txt` at startup, and that install is pinned.**

The container runs any `/config/startup.sh` and then pip-installs `/config/requirements.txt` at
start. Both packages that resolves to were legitimacy-audited on 2026-09-01
(`slopcheck install beets mutagen python3-discogs-client` → **3 OK, 0 SUS, 0 SLOP**):

| Package | Registry evidence | slopcheck | Disposition |
|---|---|---|---|
| `beets` | PyPI since **2013-01-29**, 75 releases | `[OK]` | Approved |
| `python3-discogs-client` | PyPI since **2020-06-27**, 22 releases; maintained `joalla` fork of the abandoned official client | `[OK]` — flagged *"name ends with `-client`, classic LLM naming pattern… but package is established"* | Approved |

No `[SUS]` or `[SLOP]` package is involved anywhere in this deployment.

**The requirement is written pinned, as `beets[discogs]==2.12.0`, never as bare `beets[discogs]`.**
This is load-bearing and not a stylistic preference. rc6's `backend/pyproject.toml` carries
`beets==2.12.0` as an **exact pin, not a floor**. An unpinned startup install lets pip resolve
something newer over that pin at container start — which would silently move the beets version axis
two is measured at, **before the trial begins**. That is exactly what OD-2 exists to fix in place.

The runtime assertion that `beets.__version__ == 2.12.0` stays as the **second** instrument, not as
a substitute: a runtime check catches drift only *after* the environment has already moved, which is
detection where OD-2 asked for prevention. **A pin without verification and a verification without a
pin are each half a control.** Both are used, and if the runtime assertion fails the trial does not
run.

### What axis two actually compares — read this before acknowledging

Stated here, up front, so the operator is acknowledging the comparison they are **actually** about
to run rather than a narrower one.

**Axis two is not "raw terminal versus queue UI".** The beets-flask arm carries a **policy
architecture** — three policy-carrying inboxes with per-inbox `autotag` policies of **`preview`**,
**`auto`** and **`bootleg`**, over **one shared `library.db`** (D-12 claim-audit row 16, confirmed
from primary source; this is precisely the Phase 5 structure). The terminal arm has **no
equivalent**: every decision there is made per-album, at the prompt, by hand.

**So axis two scores an interactive flow against a policy-carrying workflow system, and its verdict
is a verdict on that broader thing.** That may well be the right product question to be asking — but
the record must say which question it answered, so the verdict plan 03-11 writes cannot later be
read as a narrower claim than the trial supports.

### One adverse fact that the trial structurally cannot test

Recorded here rather than discovered in Phase 7, and recorded **before** any score exists so it
cannot be read as an excuse constructed afterwards.

beets-flask's own `docs/limitations.md` states the UI *"will get laggy"* once you hit *"some hundred
folder or so"* (#164, #175). **The backlog is 144 folders** (corrected from 143 by plan 03-03's
two-instrument survey) — just under that stated pain threshold.

**A five-album trial cannot exercise this.** Five albums is not "some hundred folders", and no score
this trial produces is evidence either way about the 144-folder case. It is carried as an **axis-two
risk and a Phase 9 handoff**, explicitly **not** as a measured finding (research Open Question 6).
A good five-album score must not be read as evidence that the UI scales to the real backlog.

### The three options, as put to the operator

| Option | What it means | Cost |
|---|---|---|
| **`deploy-rc6`** | Deploy rc6, loopback-bound, and record "still in RC after 8 months" as an axis-two risk | A release candidate can change under the phase; the RC status is itself a durability question for a tool this project would depend on |
| `deploy-v1.2.1` | Deploy the last stable, `pspitzner/beets-flask:v1.2.1` | Eight months stale, from the superseded repository, and **1.0 removed the interactive terminal import** — so it does not exhibit the UI candidate-selection workflow criterion 7 is about. The trial would measure a tool nobody would deploy |
| `skip-flask` | Do not deploy beets-flask; score axis two on the terminal arm alone | **Fails criterion 7 outright** — beets-flask is required to be evaluated by name, not dismissed. Leaves TAGR-06 unmet and axis two unanswered |

### Operator decision

**Status: ANSWERED — `deploy-rc6` selected.**

> _Decision (verbatim):_ **approved — deploy rc6**
>
> _Date:_ **2026-09-04**

The operator approved deploying `metasauce/beets-flask:v2.0.0-rc6` for the axis-two trial,
loopback-bound, having acknowledged all three recorded risks: the RC status (in RC since
2025-12-29 against a v1.2.1 stable now eight months stale), the absent authentication plus the
tmux-backed web terminal with shell access to the container, and the startup pip install pinned to
`beets[discogs]==2.12.0`.

**The acknowledgement is provably pre-deployment, and that was re-asserted at the moment of
answering rather than inferred.** Two independent readings on LXC 100 at `2026-09-04T08:59:45Z`,
immediately before Task 2 created anything:

```
$ ssh root@172.16.1.159 'docker ps -a --format "{{.Names}}" | grep -cx "beets-flask-spike"'
0
$ ssh root@172.16.1.159 "docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}} {{.Size}}' | grep beets-flask"
metasauce/beets-flask:v2.0.0-rc6 sha256:9548e78f8bcda864bf557b7bb7490f7dcfb852ce3abf2f4c1501d5bb812ec2cd 1.12GB
```

Zero containers named `beets-flask-spike` existed when the decision was given, and the digest the
operator acknowledged is character-for-character the digest that was then deployed. **An
acknowledgement written beside an already-running container is a record of consent that was never
sought**; this one is not that.

Recorded here verbatim, with a date, before any container was created. Task 2 of plan 03-10 was
gated on this line and began only after it was filled.

---

## What axis two compares

Stated as its own section, plainly and up front, so the verdict plan 03-11 records cannot later be
read as a narrower claim than the trial supports.

**Axis two is not "raw terminal versus queue UI".**

The beets-flask arm carries a **policy architecture**: three inboxes, each with its own `autotag`
policy — **`preview`** (tag, never import), **`auto`** (import when the match clears
`match.strong_rec_thresh`) and **`bootleg`** (import as-is, group by metadata) — over **one shared
`library.db`**. That architecture is not read from the docs here; it is **exercised and observed**.
rc6's own watchdog registered all three at startup:

```
[INFO] beets-flask.wdog: Registering watchdog with debounce of 30 seconds for inboxes:
  ['/mnt/tank/downloads/spike-03/bf-inbox/preview',
   '/mnt/tank/downloads/spike-03/bf-inbox/auto',
   '/mnt/tank/downloads/spike-03/bf-inbox/bootleg']
```

**The terminal arm has no equivalent of any of it.** There, every decision is made per album, at
the prompt, by hand — there is no place to express "content of this shape is handled this way"
other than in the operator's head.

**So axis two scores an interactive flow against a policy-carrying workflow system, and its verdict
is a verdict on that broader thing.** That may well be the right product question to be asking. But
the record must say which question it answered.

A second, narrower scope statement belongs beside it: **the two arms differ in beets version**
(2.13.1 terminal, 2.12.0 flask, hard-pinned by rc6 — OD-2), and the flask arm's `plugins:` list had
to be written in a **different syntax** to be accepted at all (see friction 9 below). The plugin
*set* is identical and was asserted loaded on both arms, so the comparison is still a comparison of
front ends.

---

## Frictions, checked against observation

All eight research frictions reproduced from `03-RESEARCH.md` § *Criterion 7*, each with a verdict.
A ninth row is appended for a friction this deployment discovered that the research did not have.

**"Not exercised" is used honestly and is not a synonym for "fine".** Two rows carry it, and in both
cases the reason is that a five-album trial structurally cannot reach the condition.

| # | Friction (as researched) | Verdict | What was actually seen |
|---|---|---|---|
| 1 | 1.0 removed interactive terminal import in favour of UI candidate selection; a tmux-backed web terminal exists for pasting a release ID | **OBSERVED** | Confirmed present and enabled. The shipped example defaults `gui.terminal.start_path` to `/music/inbox`, which does not exist in this deployment — the spike overrides it to the bf-inbox path rather than mounting a `/music` to satisfy a default. **Whether pasting an MBID into it is workable is for the operator to judge in Task 3**, and is deliberately left to them: it is an ergonomics question, and an agent's answer to it would measure the wrong thing. What *is* recorded here is that the terminal grants a shell inside a container that mounts `tank` — which is why the service is loopback-bound with no Traefik labels |
| 2 | Inbox entries must be directories; loose files never trigger — a documented wontfix | **OBSERVED — confirmed by direct probe** | A single loose `LOOSE-FILE-PROBE.mp3` was placed directly in the `preview` inbox. It was **never imported**: it is still sitting there, and `bf-clean` received nothing from it. The watchdog's reaction is more subtle than "nothing happens" — it enqueued **the inbox root directory itself** as a preview task (`Enqueuing …/bf-inbox/preview as preview`), and the inbox API then reported `tagged_via_gui: 1, imported_via_gui: 0` for that inbox. So a loose file does not silently vanish; it produces a **task against the wrong unit of work**. The workaround is exactly the documented one — one directory per release — and Task 3 stages all five albums that way |
| 3 | Music paths must match inside and outside the container | **OBSERVED — and the identical-path mounts were sufficient** | Both `bf-inbox` and `bf-clean` are bound at paths identical inside and outside. `beet ls` inside the container returns paths that resolve on the host, and the import wrote to the host path the config names. No path bookkeeping problem appeared. Cross-checked for mount freshness: `find … -type f -name '*.mp3'` returns **21** host-side and **21** container-side, and the Crate.071 folder returns **20 mp3** on both — matching `03-SAMPLE.md`'s `n_files` for that folder |
| 4 | Only `copy` is supported, never `move` | **OBSERVED — and favourable** | After the bootleg import, the source folder still holds all **20** mp3 and `bf-clean` holds **20** copies. Nothing was relocated. This is **favourable here**: PROJECT.md's storage constraint already requires first passes to use `copy`, so beets-flask enforces what this project wants anyway. It is recorded as a friction only because it is a *limitation* — a later phase that genuinely wants `move` cannot have it |
| 5 | UI gets laggy past "some hundred" folders (#164, #175) | **NOT EXERCISED — and cannot be by this trial** | The backlog is **144 folders**. This trial ran **one** folder through `bootleg` and stages **five** for Task 3. Five is not "some hundred", and **no score this trial produces is evidence either way about the 144-folder case.** Recorded as an axis-two risk and a **Phase 9** handoff (research Open Question 6), exactly as it was recorded *before* any score existed — see § *One adverse fact that the trial structurally cannot test*. A good five-album score must not be read as evidence the UI scales |
| 6 | `beets==2.12.0` hard pin | **OBSERVED — pin held, confirmed by both instruments** | `requirements.txt` was written pinned; the startup install resolved **without touching beets**, installing only its extras (`python3-discogs-client==2.9`, `oauthlib==3.3.1`). Runtime assertion: `beets.__version__` → **`2.12.0`**. OD-2 is enforced by prevention *and* confirmed by detection, which is what the plan asked for |
| 7 | Still in RC since 2025-12-29; last stable is v1.2.1 | **OBSERVED — recorded as a durability risk, not a defect** | The container self-reports `Backend: 2.0.0-rc6 / Frontend: 2.0.0-rc6 / Mode: prod`. Nothing about the RC status broke in this deployment. It is carried as an axis-two **durability** question for a tool this project would depend on: eight months in RC is a statement about maintenance cadence, not about whether today's build works |
| 8 | Docs' `apk`-based `startup.sh` examples are stale (base is Debian since rc4) | **NOT EXERCISED — deliberately** | No `startup.sh` was written at all, so the stale `apk` examples were never followed. The plan directs that if one were ever needed, `apt-get` is the correct tool. Recorded so a future reader does not copy the docs' example. One correction *to* the research: the mechanism is `uv pip install -r`, **not** plain `pip` — read from `/repo/entrypoint_user_scripts.sh`, which checks `/config/requirements.txt` **and** `/config/beets-flask/requirements.txt` |
| **9** | **NEW, found by this deployment —** rc6 validates the **beets** config against its own JSON schema, which is stricter than beets | **OBSERVED — and it is a startup-breaking trap** | See below. Not in the research |

### Friction 9, in full, because it is the one that would have silently spoiled the trial

The terminal arm's config writes `plugins:` in beets' own canonical form — a space-separated
string, which is what beets' documentation shows and what `03-spike-beets-config.yaml` uses.
**rc6 rejects it:**

```
eyconf.validation.exceptions.MultiConfigurationError:
  'musicbrainz discogs importsource fromfilename' is not of type 'array', 'null'
  in section 'plugins'
```

The danger is not the error — it is **what survived it**. The server still started and served a
page on 5002. What died was `launch_watchdog_worker.py`, and the watchdog is the thing that makes
the inbox folders react at all. **The three policy-carrying inboxes would have been inert**, and
the trial would have scored a beets-flask whose central architecture was not running, against a
UI that looked perfectly alive.

This is the same defect class as TAGR-05 and as `03-04`'s finding: **a configuration failure that
presents as "nothing is happening" rather than as a configuration error.** Fixed by writing
`plugins:` as a YAML list; the plugin *set* is unchanged, and the loaded-plugin assertion below
proves it.

### The assertions behind the table

Each of these is the *authoritative* instrument, chosen with the phase's own instrument lessons in
mind rather than the convenient one.

| Assertion | Command | Result |
|---|---|---|
| beets version (OD-2) | `python3 -c 'import beets; print(beets.__version__)'` | **`2.12.0`** |
| Plugins actually **loaded** | `beet version` → `plugins:` line | **`discogs, fromfilename, importsource, musicbrainz`** |
| No `/mnt/tank/media` mount | `docker inspect --format '{{json .Mounts}}'` | **`[]`** — the three mounts are bf-config, bf-inbox, bf-clean |
| Loopback binding | `docker inspect --format '{{json .NetworkSettings.Ports}}'` | `{"5001/tcp":[{"HostIp":"127.0.0.1","HostPort":"5002"}]}` |
| Loopback binding, **proven not asserted** | `curl` from the host | `127.0.0.1:5002` → **HTTP 200**; `172.16.1.159:5002` → **HTTP 000, refused**; `ss -ltn` shows `docker-proxy` on `127.0.0.1:5002` only |
| Zero Traefik labels | `docker inspect --format '{{json .Config.Labels}}'` | **zero** keys beginning `traefik.` (only compose and OCI labels) |
| Music freeze, **after** container creation (Pitfall 6) | `check-music-freeze.sh` **on LXC 100** | exit **0**; `tagger-class writers: 0`; `declared rw reaching Music: 0`; `FAILURES total: 0` |
| Discogs source available | config API | `plugins: ['musicbrainz','discogs','importsource','fromfilename']`; `python3-discogs-client 2.9` |

**The plugin assertion is deliberately `beet version`, not a config dump.** `03-04` measured that
`beet config -d` prints a full `discogs:` block *even when the plugin failed to load*, because
`DiscogsPlugin.__init__` registers its defaults before it calls `setup()`. A config-dump grep
proves nothing about plugin load; the loaded-plugin line is the only instrument that does.

**The freeze check has a "could not look" mode that looks like a pass, and it was hit.** Run from
the macOS workstation it reports `0 running containers, 0 mounts enumerated` and
`declared rw reaching Music: 0` — because `/mnt/tank`, the fence and docker are all absent there.
It exits **1** on the missing fence, which is what saved it, but the *summary counters read like a
clean estate*. The audit above is the run **on LXC 100**, and that distinction is recorded because
a future reader glancing at counters could easily record the wrong run.

### A4 — bundled Redis: **CONFIRMED**

Asserted at runtime, not assumed: `redis-cli PING` inside the container returns **`PONG`**, with no
`redis` service declared anywhere in the compose file and `REDIS_URL` deliberately unset. Confirmed
from primary source too — `/repo/entrypoint.sh` contains
`if [ -z "$REDIS_URL" ]; then redis-server --daemonize yes; fi`. A4 is **not** falsified, so no
`redis:7-alpine` sidecar was added.

*Instrument note:* the first attempt counted `redis-server` in `ps` output and returned **0** —
because the image ships **no `ps`** (`bash: line 1: ps: command not found`). That is an instrument
failure, not a finding, and it is recorded because a `grep -c` over a missing binary's empty output
returns a confident, wrong zero. The same defect class as DEF-03-05.

### The token did not leak

Checked, because this phase has already written the Discogs token to disk twice, and because
`python3-discogs-client` sends it as a **`?token=` query parameter** rather than an
`Authorization` header — so anything rendering URLs can leak it. beets-flask has **no
authentication**, so anything its API returns is readable by anyone who reaches the port.

Compared **inside the container**, against the live `DISCOGS_USER_TOKEN`, so the value never
crossed a transcript or an argv:

| Probed response | Token value present? | `user_token` key |
|---|---|---|
| `/api_v1/config/` | **No** | absent |
| `/api_v1/config` | **No** | absent |
| `/openapi.json` | **No** | absent |

The token reaches the container only through `env_file:`, and is rendered into
`/config/beets/config.yaml` at mode **0600** by a script that reads `os.environ` and prints only a
redacted confirmation. That file is outside the repository. The committed artefact is the
**token-free template**.

---

## The bootleg inbox

`autotag: "bootleg"` is documented as *"Import as-is using the meta data of files, and group albums
using the metadata… effectively `beet import ... --group-albums -A`"*. The research called it *the
single strongest pro-beets-flask finding* — a first-class UI affordance for exactly the content
criterion 4 is about.

**It is real, it is first-class, and on this content it did the wrong thing.**

`bootleg` is confirmed present in rc6 from primary source rather than from the docs:
`backend/beets_flask/config/schema.py:110` declares
`autotag: Literal["auto", "preview", "bootleg", "off"] = "off"`. Note that the **shipped
`config_bf_example.yaml` documents only `off`/`auto`/`preview` and never mentions `bootleg`** — the
example file alone would have hidden the feature entirely.

### What it actually did

`VA-Mastermix.Crate.071.Afro.House-2025` was dropped into the `bootleg` inbox. The watchdog picked
it up after the 30-second debounce and imported it with no prompt and no error:

```
[INFO] beets-flask.wdog: Watchdog: Starting inbox handler task …/bf-inbox/bootleg/VA-Mastermix.Crate.071.Afro.House-2025
[INFO] beets-flask.wdog: Watchdog: Enqueuing …/bf-inbox/bootleg/VA-Mastermix.Crate.071.Afro.House-2025 as import_bootleg
```

**One 20-track DJ release went in. Twenty single-track albums came out.**

| Property | Value |
|---|---|
| Source | 1 folder, **20** mp3 |
| Albums created in `library.db` | **20** |
| Items | 20 |
| `album` on every item | **empty** |
| `albumartist` on every item | the individual **track** artist |
| `track` on every item | `00` |
| `comp` | `False` |
| Destination layout | `bf-clean/<track artist>/00 <title>.mp3` — **no album directory level at all** |
| Errors | none. The log is clean |

Sample of the resulting "albums":

```
&Me, Rampa, Adam Port, Alan Dixon, Keinemusik Feat. Arabic Piano -
Adam Port & Stryv Feat. Malachiii X Keinemusik -
Adam Port & Theus Mago -
Bob Sinclar Feat. Steve Edwards -
Dennis Ferrer -
```

The trailing dash is where the album title would be.

### Why, and why this generalises

`--group-albums` groups by the metadata that is **there**. `VA-Mastermix.Crate.071.Afro.House-2025`
is the V3 folder `03-SAMPLE.md` records as `has_album_count = **0**`, `has_artist_count = 20` — it
has **no album tag on any file**, and twenty distinct track artists. Grouping on
(albumartist, album) over that input yields twenty groups of one, which is arithmetically exactly
what happened.

**So bootleg's grouping is only as good as the metadata it groups by — and the defining
characteristic of the content criterion 4 is about is that its metadata is absent or wrong.** On
V1/V2 folders, which carry a clean-ish issue string in `album`, bootleg would plausibly group
correctly. On V3 (no album at all) it fragments the release. On V5 (`album == artist`, 43 of the
144 backlog folders) it would group all tracks under the *placeholder* — a different wrong answer,
not a right one.

This does not retire the finding; it **bounds** it. `bootleg` remains a genuine, first-class
affordance the terminal arm has no equivalent of, and it is still the mechanism criterion 4's
beets-flask row should name. But it is **not** a solution to untagged DJ content on its own: it is
a fast path for content whose tags are already grouped correctly, and PROJECT.md's sequencing
already says so — **normalise tags first (the mutagen script, which won D-13 independently), then
import**. Run in the other order, bootleg produces a confidently wrong library shape with no error
and no prompt, which CLAUDE.md § *Autotagging ceiling* names as worse than no match.

### Scope of this observation

This was run on `VA-Mastermix.Crate.071.Afro.House-2025`, **not** on the trial's `dj-no-match`
album (`VA-Mastermix.Crate.068-070-2025`), deliberately: importing the trial album here would have
made the operator's Task 3 run a **second pass** over an album already in the library, and a second
pass is always faster. The ordering control in `03-ERGONOMICS-SHEET.md` exists to prevent exactly
that contamination, and it would have been defeated before the operator sat down.

Both folders are zero-Discogs-candidate folders per `03-DISCOGS-EVIDENCE.md` (cases B and C
respectively), so the substitute is drawn from the same evidence class.

**The library and `bf-clean` were reset to empty after this observation and before Task 3 staged
the trial** — see § *Trial staging* — so the operator begins against an empty library. One folder
was imported for this section and then unwound; the observation above is what it produced.

---

## Trial staging

Task 3's environment, prepared and asserted so the operator's trial is one command to start. The
full operator-facing instructions live in
[`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md) § *AMENDMENT 2026-09-04*; this section records
the assertions behind them.

### The reset, and what it proves

| Assertion after unwinding the bootleg observation | Result |
|---|---|
| `bf-clean` files | **0** |
| `bf-inbox` files | **0** (before staging) |
| `spike-flask.blb` | **absent** |
| `raw/VA-Mastermix.Crate.071.Afro.House-2025` mp3 count | **20** — the bootleg source survived its own import |
| `find /mnt/tank/downloads/complete/nzb -newermt '2026-09-04 09:00' -type f` | **0 files** — the real backlog was never touched at any point in this plan |

The removals were **targeted paths only**. No `git clean`, no blanket `rm -rf` of a tree, no
`--remove-orphans`.

### The five albums

Staged into `bf-inbox/preview/`, each in its own directory, reflinked from atlantis. Counts
re-verified on disk and matching `03-SAMPLE.md` exactly: 21 + 10 + 47 + 31 + 60 = **169 audio files
across 5 folders**, **2.6 G**. The `dj-no-match` fifth album is
`VA-Mastermix.Crate.068-070-2025`, `03-DISCOGS-EVIDENCE.md` **case C** — zero Discogs candidates on
both the probe and an independent hand-transcribed `beet import -t`, agreeing on all ten
properties.

**Mount freshness cross-checked before handing over**, because the bind pins the directory inode
and a re-materialised host directory leaves the container reading an empty tree while every command
exits 0 reporting 0 files:

| Reading | Folders | Audio files |
|---|---|---|
| Host | 5 | 169 |
| Inside `beets-flask-spike` | 5 | 169 |
| Inside `beets-spike` | 5 | — |

### Why all five went into the `preview` inbox

`preview` tags but never imports, which is the closest analog to the terminal arm's
`beet import -t` — so both arms put the **same decision** in front of the operator, and the trial
compares how each presents it rather than comparing "one asked me and one didn't". Staging into
`auto` would have removed the operator's decision entirely, which is the thing being timed.

`bootleg` and `auto` are reachable from there by moving a folder between inboxes, and that move is
itself a one-command affordance the terminal arm has no equivalent of. The exact command is in the
sheet.

### Both arms verified live

| Arm | Version | Plugins loaded (`beet version`) | Reachable |
|---|---|---|---|
| `beets-spike` (terminal) | **2.13.1** | `discogs, fromfilename, importsource, musicbrainz` | `docker exec -it`, and it can `ls` all five albums |
| `beets-flask-spike` (flask) | **2.12.0** | `discogs, fromfilename, importsource, musicbrainz` | SSH tunnel **tested end-to-end, HTTP 200**; LAN IP refused |

Identical plugin sets on both arms, asserted from the loaded-plugin line rather than a config dump.
The terminal arm's Discogs token is the pre-existing `/spike-config/config.yaml` from plans 03-04 /
03-07 (mode 0600, outside the repo); the flask arm's is rendered into `/config/beets/config.yaml`
at mode 0600 from `env_file`. Neither is in this repository.

### One constraint worth stating before the operator starts

The terminal arm has **no writable path on `tank`** — its only rw mounts are
`/mnt/fast/spike-03/out` and `/mnt/fast/spike-03/beets-config`, both of which are on **LXC 100's
ext4 root, not the `fast` pool** (`03-SAMPLE.md` § *Scratch tree*). So its import destination
consumes `/`. At 2.6 G staged against **35 G free** and an OD-1 floor of 8 GiB there is ample
headroom, but the thing to watch is `df -h /`, never `zfs list`.

It also mounts `bf-inbox` **read-only**, which is a stronger guarantee than the config's
`import.move: no`: the terminal arm *could not* move the trial sources even if misconfigured.
