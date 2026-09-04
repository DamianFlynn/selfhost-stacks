# Phase 3 criterion 7: beets-flask evaluated by name

Companion to [`03-DECISION.md`](03-DECISION.md) § *Axis two* and to
[`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md) (the sheet the operator fills during the timed
trial).

Nothing here is applied by `docker compose`. This is the record of what beets-flask actually is,
what it was acknowledged to be **before** it was deployed, and what its eight known frictions turned
out to look like against observation rather than against documentation.

State as of 2026-09-04 — **acknowledgement drafted, nothing deployed.** No `beets-flask-spike`
container exists.

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

**Status: AWAITING OPERATOR — nothing deployed.**

> _Decision (verbatim):_ **PENDING**
>
> _Date:_ **PENDING**

Recorded here verbatim, with a date, before any container is created. Task 2 of plan 03-10 does not
begin until this line is filled.

---

## Frictions, checked against observation

*To be filled by Task 2 — all eight research frictions, each with an
observed / not observed / not exercised verdict and what was actually seen.*

---

## The bootleg inbox

*To be filled by Task 2 — what `autotag: "bootleg"` actually did on the DJ folder.*
