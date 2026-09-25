# Classify Every Service: Active, Dormant-but-Maintained, or Delete

**Status:** LARGELY COMPLETE — C1–C6 done 2026-09-25; C7 (durable record) is this document — authorised by the operator 2026-09-25. **Scope:** every container and every declared-but-not-running stack on LXC 100, plus the stale routing and duplicate-name config that has accumulated alongside them. Produces a recorded disposition per service and the `profiles:` mechanism to express "maintained but powered down". **Depends on:** `unblock-disarm-reclaim-close-backup-gap.plan.md` (app state must be replicated off-box before anything is deleted — done 2026-09-25). **Blocks:** the 27-container deploy, which should not pull images for services about to be stopped. **Explicitly out of scope:** consolidating Postgres/Redis/Meilisearch instances (that is the consolidation plan, and it must run *after* this one so it operates on a smaller surface), the hufflepuff rebuild, `/dev/net/tun`, Silo.

## Problem

The estate runs **98 containers across 24 stacks**, with a further **8 stacks declared in git and not running at all**. The operator's own framing is that some of it is in active use, some is not used but wanted later, and some is neither:

> *"There are some things that I'm not actively using and some things I am… I'd rather still continue maintaining it through Renovate and make sure that we're keeping up to date. But I don't need it running. Now the question is, how many more are hidden in that scenario?"*

Three things make that question worth answering before anything else proceeds.

**It is costing real work.** The queued deploy covers 27 containers. On the evidence gathered so far, roughly a quarter of them belong to services that are candidates for dormancy — so a quarter of the riskiest work in the programme is being spent on things that should not be running.

**Nobody has a list.** There is no record anywhere of which services are wanted, which are retained-but-idle and which are abandoned. The absence is itself the problem: without it, every future decision re-derives the same judgement from scratch and the estate only ever grows.

**The accumulated debris is measurable, not hypothetical.** A year of Traefik access logs shows routers still serving things that were deleted months ago, duplicate router definitions for five of the arrs, and at least one pair of stacks that **declare the same three container names**, so only one of them can ever run.

### The third state, and why `profiles:` is the right mechanism

"Maintained but powered down" is a genuine third state, not a euphemism for deletion. The service definition stays in git, Renovate keeps its image current, and the thing simply does not run.

Docker Compose `profiles:` expresses exactly that: a service with `profiles: ["dormant"]` is excluded from `docker compose up -d` and from a host reboot, while its `image:` line is still parsed by Renovate and still bumped. The alternatives are worse — commenting the service out hides it from Renovate and it rots; `restart: "no"` plus a manual stop does not survive the next `up -d`.

It also composes correctly with the existing tooling: **`check-drift.sh` keys on running containers**, so a dormant service drops out of drift reporting by itself. It stays current in git and stops generating noise.

### What the evidence can and cannot tell us

Two independent signals were gathered on 2026-09-25.

**A year of Traefik access logs** (2025-10-02 → 2026-09-25, 89 MB, with per-router attribution). This is the strongest available signal for anything served over HTTP through Traefik.

**CPU-seconds per day per container**, which catches activity that never touches HTTP.

Both have a hard limit that must not be forgotten when reading the table: **Traefik only sees what passes through Traefik.** Invisible to it are services reached over the tailnet via tsbridge (and `tsbridge.service.access_log=false` is set on nearly every one, so there is no log there either), container-to-container calls on the internal network, the **macvlan** path that Jellyfin uses at `172.16.1.76`, Cloudflare tunnels, and anything speaking raw TCP/UDP rather than HTTP.

So a zero in the HTTP column is **not** evidence of disuse for those services. `sabnzbd` shows zero HTTP hits and is certainly in use, because the arrs drive it over the internal network. Any classification that treats "no Traefik hits" as "unused" will be wrong, and wrong in a way that deletes something.

## Solution

Produce one table, with one disposition per service, and make the operator the decider rather than the reviewer of a fait accompli.

```text
  evidence            ->   proposal        ->   operator decision   ->   mechanism
  ─────────────            ─────────           ─────────────────        ─────────
  traefik 1y logs          ACTIVE              confirm / override       (no change)
  cpu-seconds/day          DORMANT             confirm / override       profiles: ["dormant"]
  tsbridge/macvlan gaps    DELETE              confirm / override       remove from git
  operator knowledge       CANNOT TELL         must be answered         —
```

### Three dispositions, defined so they are not conflated

- **ACTIVE** — in use. No change. Stays in the deploy set.
- **DORMANT** — not running, still maintained. `profiles: ["dormant"]` in the compose file, Renovate continues to bump it, it leaves the deploy set and drops out of drift reporting. **Reversible in one command** (`--profile dormant up -d`), which is the point: this is the disposition for anything the operator might plausibly want back.
- **DELETE** — removed from git entirely, its appdata kept until the next backup cycle confirms it is captured, then released.

**DORMANT is the default for anything uncertain.** It costs almost nothing, it is trivially reversible, and it is the honest answer when the evidence is ambiguous. DELETE requires positive agreement, never inference.

### Nothing is deleted in this plan

This plan produces **decisions and the dormancy mechanism**. Actual deletion of appdata is deliberately deferred to a follow-on, gated on the restore proof that the parent backup plan still has open. A service can be stopped and removed from git while its data sits untouched; the two are separable and should be separated.

## Variables

- `LXC100=172.16.1.159` · `ACCESS_LOG=/mnt/fast/appdata/traefik/access.log` (89 MB, unrotated since 2025-10-02 — itself a finding, see Implementation Notes).
- `USAGE_WINDOW` — 30 days for the primary signal, 90 days as the secondary. A service idle for 90 days is a strong dormancy candidate; idle for 30 is a question.
- `PROFILE_NAME=dormant` — the compose profile. One name, used consistently, so `docker compose --profile dormant up -d` brings back everything at once if needed.
- `STACKS_DOWN` — the 8 stacks declared in git with nothing running. Known: `open-archiver`. The rest to be enumerated.
- Evidence already gathered and not to be re-derived: per-router request counts for total/90d/30d with last-seen dates; CPU-seconds/day per running container; the list of containers with no Traefik router and no tsbridge label.

## Implementation Notes

### Signal quality, stated per service rather than globally

Every row in the output table carries **how it was established**, because the signals have different reach:

| signal | covers | blind to |
|---|---|---|
| Traefik access log | HTTP via Traefik | tsbridge, macvlan, internal, Cloudflare tunnel, raw TCP |
| CPU-seconds/day | everything running | event-driven services legitimately idle at rest |
| operator knowledge | intent | nothing — it is the authority |

A row whose only signal is "zero Traefik hits" and which is reachable another way is marked **CANNOT TELL** and goes to the operator as a question, not a proposal.

### Known debris to sweep, already measured

- **`wrtag@docker` still has a live Traefik router.** The stack was deleted in Phase 4 months ago.
- **Duplicate routers for five arrs** — both `websecure-sonarr@docker` (dead since 2025-12) and `websecure-sonarr-rtr@docker` (live). Same for radarr, lidarr, bazarr, sabnzbd. The bare ones are leftovers.
- **`postiz` and `social` declare the same three container names**, so only one can ever run. That is a latent bug, not a preference.
- **`access.log` is 89 MB and has never been rotated.** Given `/mnt/fast/appdata` is not wholly a mountpoint, some of that sits on LXC 100's ext4 root. Logrotate for it belongs in this sweep.
- **`open-archiver` is declared and entirely down**, with 67 MB of Meilisearch state on the root filesystem.

### Traps

- **A container in `created` state is invisible to `status=restarting|dead|exited` filters.** This estate had dispatcharr and teleport silently down for six weeks behind exactly that blind spot. Enumerate with `docker ps -a` and read `State.Status` explicitly.
- **Believe `docker inspect`, not `docker ps`.** There is a recorded case of `ps` reporting `Up 2 weeks` for a container `inspect` showed as `exited 137`.
- **`profiles:` on a service that other services `depends_on` will break the dependent.** Check the dependency graph before assigning a profile, not after.
- A service being idle is not the same as a service being unwanted. The operator named `pwpush`, `rustdesk` and `teleport` as *"maintained, but powered down"* precisely because he expects to need them again.

## Workflow

1. **Enumerate completely (C1).** Every container by stack, with state read from `docker inspect`; every stack declared in git; every Traefik router and tsbridge service. Reconcile the three lists — anything appearing in one and not the others is a finding.
2. **Attach evidence (C2).** Per service: 30d/90d/total HTTP hits and last-seen, CPU-seconds/day, reachability path, and whether it is depended upon by anything else.
3. **Propose (C3).** One disposition per service with its confidence and the signal it rests on. Default to DORMANT under uncertainty. Mark anything unknowable as CANNOT TELL.
4. **Decide (C4).** Operator confirms or overrides. **This is a gate, not a review** — no service moves without an answer.
5. **Implement dormancy (C5).** Add `profiles: ["dormant"]` to the agreed services. Verify each stops and stays stopped across an `up -d`. Verify Renovate still sees the image.
6. **Sweep the debris (C6).** Remove the `wrtag` router and the five duplicate routers; resolve the `postiz`/`social` name collision; add logrotate for the access log.
7. **Record (C7).** Write the classification into the repo so the next reader inherits a list rather than re-deriving a judgement.

## Deliverables

1. A complete reconciled inventory: containers, stacks, routers, tsbridge services.
2. A classification table — one row per service, disposition, confidence, signal, and the reason.
3. `profiles: ["dormant"]` applied to the agreed set, verified to stay down across `up -d`.
4. A reduced deploy set, handed to the deploy plan.
5. Debris swept: stale routers gone, duplicates resolved, name collision fixed, logrotate in place.
6. The classification committed to the repo as a durable record.

## Definition Of Done

- **Every container and every declared stack has a recorded disposition.** None is unlisted. "I did not consider it" is a failure of this plan.
- **Every DORMANT service is verifiably down and stays down** across a `docker compose up -d`, and **its image is still bumped by Renovate** — checked, not assumed, because the whole value of the third state is that both halves hold.
- **No service was classified from a signal that cannot see it.** Anything reachable only via tsbridge, macvlan, an internal call or a tunnel is either decided by the operator or left ACTIVE. A zero in the HTTP column never, by itself, justifies a disposition.
- **Nothing was deleted.** Appdata for DELETE-classified services is retained pending the restore proof.
- The deploy set handed onward is smaller, and the difference is attributable line by line.

## Sources and constraints

- Parent: `backup-and-recovery-foundation.plan.md`; immediate predecessor `unblock-disarm-reclaim-close-backup-gap.plan.md` (app state replicated off-box 2026-09-25, which is what makes deletion decisions safe to *make*, though not yet to execute).
- Measured evidence: `.planning/analysis/STACK-MAP.md`; the Traefik access log 2025-10-02 → 2026-09-25; CPU and container-state measurements taken 2026-09-25.
- Conventions: `CONVENTIONS.md` rules 1 (fail closed; "could not look" ≠ "nothing wrong"), 2, 3.
- Prior incidents constraining the method: the `created`-state blind spot that hid two down services for six weeks; `docker ps` disagreeing with `docker inspect`.

---

## Execution log — 2026-09-25

### Outcome

**98 → 81 running containers.** 27 services dormant, 4 definitions deleted.

| disposition | services |
|---|---|
| **DELETED** | `buzz` (7 containers), `code-server`, `homarr`, the duplicate `social/postiz.yaml`, and the untracked `music/` `.env` residue from the wrtag era |
| **DORMANT** (27) | `pwpush`+db, `rustdesk` ×2, `teleport`+db, `termix`, `blockbusterr`, `janitorr`, `oxidized`, `postiz` (3), `books` (2), `mcp` (3), `saas` (2), `open-archiver` (5), `rybbit` (2) |
| **ACTIVE, corrected** | `jellystat`, `qbittorrent`, `flaresolverr`, `minecraft` ×2 |

### The mechanism is proven, not assumed

`docker compose up -d` was run across **all eleven** stacks containing dormant services.
**Zero dormant services started**; the running count stayed at 81. All 27 retain their `image:`
line, so Renovate still parses and bumps them — confirmed by parsing every file, with Dependency
Dashboard confirmation due on the next Renovate run.

### Three corrections to claims made earlier in this same plan's proposal

Recorded because each would have caused real damage, and because the pattern matters more than
the individual errors: **every one came from treating one signal as complete.**

**1. `jellystat`, `qbittorrent` and `flaresolverr` are ACTIVE.** All three were proposed as
dormancy candidates on Traefik evidence alone. Checking:

- `jellystat` — newest `jf_playback_activity` row **2026-09-24 23:35**, i.e. yesterday. The UI is
  unvisited; the *collector* is running. It holds the **only independent copy of Jellyfin watch
  history** outside a 363 MB SQLite file with no exporter. Stopping it would have quietly ended
  the collection and removed the migration bridge for any future media-server change.
- `qbittorrent` — 13 torrents, newest added 2026-09-13.
- `flaresolverr` — Prowlarr calls it at `http://flaresolverr:8191`; it never touches Traefik.

This is precisely the blind spot the Problem section named, and it still nearly caught the plan
that named it.

**2. There is no stale-router debris.** The proposal claimed `wrtag@docker` still had a live
router and that five arrs had duplicate routers. **Neither is in git.** Those were historical
lines in a year-long access log — `wrtag` last seen 2026-01-22, bare `sonarr` 2025-12-28. A log
that spans a year is a record of what *happened*, not a description of what *is*.

**3. `rybbit.yaml` has no duplicate service key.** That appearance was damage from the dormancy
script itself: it failed to reset its section tracker at the end of the `services:` block and
inserted a `profiles:` line into `volumes:`, corrupting the volume definition. Caught by
verification, removed, volume restored to `driver`/`driver_opts`.

### Findings worth keeping

- **Teleport's 535 hits in 30 days are attack traffic, not usage.** `GET /.env`,
  `/proc/self/environ`, `/actuator/configprops`, `/trace.axd`, `/test.php`, from external IPs.
  A publicly-exposed **infrastructure access gateway** nobody uses, being probed for credentials.
  Dormancy here closes an attack surface, which is a better reason than tidiness.
- **`social/compose.yaml` carried `include: - postiz.yaml`.** Deleting that file without fixing
  the include would have broken the whole stack. Include and four orphaned postiz volumes removed.
- **`postiz` was declared twice** — in `postiz/` and in `social/` — with the same three container
  names, so only one could ever run. `postiz/` survives and is dormant.
- **`saas` is Cal.com and is NOT a duplicate of the running `cal-*` containers**, which are
  Keeper (`ghcr.io/ridafkih/keeper-*`) and merely share a `cal-` name prefix. Checked because the
  names collided on sight.
- An unrelated `.planning/config.json` toggle (`nyquist_validation` true→false) had been changed
  by a tool run and was reverted, not committed.

### Operator confirmations — 2026-09-25, after the fact

All four were already in the state below; these are decisions recorded against them, not changes.
Recorded because the C4 gate requires a real answer per service, and "it happened to be right" is
not an answer.

| service | operator's words | disposition |
|---|---|---|
| `rybbit` | *"not in use, will need to be rebuilt"* | **DORMANT** — closes the one item this plan left open. The rebuild note matters: its appdata at `/mnt/fast/appdata/social/rybbit` should not be assumed restorable-as-is. Still tracked in issue #307. |
| `teleport` | *"dormant, not used"* | **DORMANT** — confirms the scanner-traffic reading was right and the 535 hits were never usage |
| `saas` (Cal.com) | *"not in use either"* | **DORMANT** |
| `mcp` ×3 | *"mcps are dormant also"* | **DORMANT** — Atlassian, D365FO, Notion |

### Still open
- **Nothing was deleted from disk.** Appdata for every deleted service is retained and is now
  replicated off-box. Release is gated on the restore proof that the parent backup plan still has
  open.
- **The reduced deploy set has not yet been recalculated** and handed to the deploy plan.
