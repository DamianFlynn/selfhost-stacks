# Stack Map — Deer Crest self-hosted estate

**Produced:** 2026-09-25. **Method:** every figure below was measured against the live estate
(`root@172.16.1.159` = LXC 100, `root@172.16.1.158` = atlantis/Proxmox) or read out of this
repository at commit `3798ed1`. Where a claim could not be verified it says so explicitly.
Repo docs (`MEDIA.md`, `NETWORK.md`, `DEPLOYMENT.md`, `CLAUDE.md`) were read first and are built
on; every contradiction found against the live host is recorded in § 0.

**Scale:** 99 containers on LXC 100 (98 `running`, 1 `exited` — `buzz-minio-init`, a one-shot).
Zero in `created`. Zero `unhealthy`. 32 stack directories in `stacks/selfhosted/`, of which
**24 have containers running** and **8 are declared-but-down**.

---

## 0. Contradictions between the docs and the live host

These are findings in their own right. Each was measured, not inferred.

| # | Claim in repo | Measured on the live host | Severity |
|---|---|---|---|
| **C-1** | `MEDIA.md` § 1: *"jellyfin — Image (live) `jellyfin/jellyfin:10.11.11`"* | The container's `Config.Image` **is** `jellyfin/jellyfin:10.11.11`, but that tag **no longer exists locally**. `docker images jellyfin/jellyfin` returns exactly one row: `jellyfin/jellyfin:latest`, image ID `d57d4a0c18b3`, **built 2026-06-06**, which is the image the container is running. The declared pin is right; the resolved local artefact carries only a floating tag. `check-drift.sh` does not flag it (it compares `Config.Image` to the declared string, and they match) — so this is a **blind spot in the estate's own drift instrument**. | HIGH — image provenance is unverifiable, and any `docker pull jellyfin/jellyfin:latest` silently changes the binary under a "pinned" declaration |
| **C-2** | `MEDIA.md` § 8 + `DEPLOYMENT.md` § 3: *"Five stacks are on `/`: `monitoring`, `agentic-os`, `documents`, `open-archiver`, `rustdesk`"* | **Four**, not five. `agentic-os` moved — its data is at `/mnt/fast/appdata/automation/agentic-os/postgres`, inside the `fast/appdata/automation` dataset. The on-root four are `documents` (113 M), `monitoring` (1.4 G), `open-archiver` (67 M), `rustdesk` (1.4 M). Separately, a `fast/appdata/agentic-os` dataset **exists on atlantis and is empty (96 K)** and is not bound into LXC 100 — an orphaned dataset. | MEDIUM — the list is stale and the orphan dataset is a trap for anyone who "fixes" agentic-os by pointing it at the obvious path |
| **C-3** | `MEDIA.md` § 8 lists the on-root total as *"~4.7 G"* | 1.58 G across those four today. But **two on-root stores are much larger and are not in that list**: `/automation/n8n-postgres` (**70 M**, the n8n Postgres data directory, at the LXC filesystem root — not under `/mnt` at all) and **`/var/lib/docker/volumes` (1019 M)** holding paperless, teslamate, teleport, dawarich, termix and trek state as named Docker volumes. | HIGH — § 5 |
| **C-4** | `NETWORK.md`: *"`tsbridge` … gives **nine** services their own tailnet nodes"* | **Ten** containers carry `tsbridge.enabled=true`: `ai-docling`, `ai-ollama`, `ai-openwebui`, `ai-openwebui-mcp`, `ai-searxng`, `code-server`, `immich_server`, `mc_vanilla`, `mc_yggdrasil`, `neocortex-memory-api`. | LOW |
| **C-5** | `DEPLOYMENT.md` header: *"103 containers"*; `CLAUDE.md`: *"103 containers as of 2026-09-03"*; `NETWORK.md`: *"78+"* | **99** (`docker ps -a`). | LOW |
| **C-6** | `README`/`MEDIA.md` treat `/mnt/fast/appdata` as *"a plain directory on ext4"* | True **from inside LXC 100** — and the *reason* is sharper than the docs say. On atlantis, `fast/appdata` **is** a ZFS dataset (169 G). LXC 100 receives only the **child** datasets as `mp1`–`mp15` bind mounts; the parent is never passed through. So a write to `/mnt/fast/appdata/<name>` where `<name>` has no `mp` entry lands on the LXC's ext4 root and is **invisible to the parent dataset too**. | MEDIUM — worth correcting in the docs, because "it's a plain directory" invites the wrong fix (`zfs create fast/appdata/documents` alone does nothing; it also needs an `mp` entry in `pct config 100`, i.e. a Terraform change) |
| **C-7** | `CLAUDE.md`: *"Jellyfin is exposed LAN-wide at `172.16.1.76:8096` … and is not reachable from LXC 100 itself"* | **Confirmed.** `jellyfin` is on `iot_macvlan` at `172.16.1.76`, `dispatcharr` at `172.16.1.75`, and those are the only two macvlan members. No correction needed — recorded here because it is load-bearing for § 6. | — |

---

## 1. Shared infrastructure and duplication

### 1.1 Search indexes

| Instance | Stack | Image (running / declared) | State path | Consumers | Status |
|---|---|---|---|---|---|
| `karakeep-meilisearch` | `karakeep` | running `getmeili/meilisearch:v1.53.1`, git declares `v1.54.0` (**drifted**) | `/mnt/fast/appdata/hoarder/karakeep/meili` (ZFS `fast/appdata/hoarder`) | `karakeep-web`, `karakeep-workers` (`MEILI_ADDR=http://meilisearch:7700`) | **Running.** 34.9 MiB RSS |
| `open-archiver_meilisearch` | `open-archiver` | declared `getmeili/meilisearch:v1.54` (**a floating 2-part tag** — karakeep pins three parts) | `/mnt/fast/appdata/open-archiver/meilisearch` — **on the LXC ext4 root**, plus a `meilisearch.bak-20260730` sibling | would be `open-archiver` | **NOT running.** The whole stack is down. 67 M of pre-seeded state survives on disk |

**Elasticsearch / Typesense / Sonic / OpenSearch: none.** Verified two ways — a keyword sweep of
the entire repo found zero occurrences of `ELASTIC`, `TYPESENSE`, `SONIC`, and no running
container image matches. This is a *checked and absent*, not a *could not check*.

**Consolidation verdict:** there is only one Meilisearch actually running, so there is nothing to
merge **today**. The decision is whether open-archiver comes back at all (§ 3). If it does, a
single Meilisearch can serve both — Meilisearch is multi-index by design and karakeep addresses it
by `MEILI_ADDR` + `MEILI_MASTER_KEY`, both of which are plain env. The blocker is that the two
declarations pin different versions and Meilisearch **requires an explicit `--experimental-dumpless-upgrade`
or dump/restore across minor versions** (karakeep already sets `MEILI_UPGRADE_DB=true` for exactly
this reason).

### 1.2 Databases

**Twelve Postgres servers are running. There is no MySQL, no MariaDB, no MongoDB** (repo keyword
sweep: zero hits for `MYSQL`, `MARIADB`, `MONGO`; no running image matches).

| Container | Stack | Server version (live `show server_version`) | Data path | Backing store | DB size | Consumers |
|---|---|---|---|---|---|---|
| `immich_postgres` | immich | **14.19** + `vchord 0.4.3`, `vector 0.8.0`, `pg_trgm`, `earthdistance`, `cube`, `unaccent`, `uuid-ossp` | `/mnt/fast/appdata/immich/postgres` | ZFS `fast/appdata/immich/postgres` (its own dataset, `mp8`) | **2368 MB** | `immich_server`, `immich_machine_learning`, `immich_kiosk` |
| `agentic-os-db` | agentic-os | 18.4 + `vector 0.8.3` | `/mnt/fast/appdata/automation/agentic-os/postgres` | ZFS `fast/appdata/automation` | `agentic_os` 538 MB + `neocortex_memory` 74 MB | **`neocortex-memory-api` (cross-stack)** — two roles, `memory_api` and `memory_legacy_ro` |
| `ai-postgress` | openwebui | 18.6 + `vector 0.8.3` (`pgvector/pgvector:0.8.6-pg18`) | `/mnt/fast/appdata/llm-ai/postgres` | ZFS `fast/appdata/llm-ai` | `owui` **82 MB** | `ai-openwebui`, `ai-openwebui-mcp` |
| `cal-postgres` | keeper-sh | 18.6 (`postgres:18-trixie`) | `/mnt/fast/appdata/automation/keeper/postgres` | ZFS `fast/appdata/automation` | `keeper` 13 MB | `cal-api`, `cal-cron`, `cal-worker`, `cal-mcp` |
| `teslamate-db` | teslamate | 18.6 | **named volume `teslamate_teslamate-db`** | **`/var/lib/docker/volumes` → LXC ext4 root** | `teslamate` 52 MB | `teslamate`, `teslamate-grafana` |
| `n8n-db` | automation | 18.4 | **`/automation/n8n-postgres`** (LXC filesystem root, not under `/mnt`) | **LXC ext4 root** | `n8n` 14 MB | `n8n` |
| `paperless_postgres` | documents | 18.4 | named volume `documents_paperless_postgres` | **LXC ext4 root** | `paperless` 16 MB | `paperless`, `paperless-gpt` |
| `teleport_postgres` | teleport | 18.4 | named volume `teleport_teleport_postgres` | **LXC ext4 root** | `teleport` ~0 (7.7 MB = empty) | `teleport` |
| `jellystat-db` | media | 18.4 (`postgres:18-alpine`) | `/mnt/fast/appdata/media/jellystat/postgres` | ZFS `fast/appdata/media` | `jfstat` **94 MB** | `jellystat` |
| `pwpush-db` | automation | 18.4 | `/mnt/fast/appdata/automation/pwpush/db` | ZFS `fast/appdata/automation` | `pwpush_db` 9.8 MB | `pwpush` |
| `dawarich_db` | dawarich | **17.10** (`postgis/postgis:17-3.5-alpine` — PostGIS, not plain PG) | named volume `dawarich_dawarich_db_data` | **LXC ext4 root** | `dawarich_production` 106 MB | `dawarich_app`, `dawarich_sidekiq` |
| `buzz-postgres` | buzz | **17.11** (`postgres:17-alpine`) | `/mnt/fast/appdata/buzz/postgres` | ZFS `fast/appdata/buzz` | `buzz` 35 MB | `buzz-relay`, `buzz-pairing-relay` |

Declared-but-down adds five more Postgres servers: `open-archiver_postgres`, `postiz_postgres`
(×2 — declared identically in two stacks), `rybbit_postgres`, `calcom_postgres`, `booklore_postgres`
— all `postgres:18-alpine`.

**Consolidation verdict — this is the single biggest structural win available.**

- **Nine of the twelve are already PG 18** (`agentic-os-db`, `ai-postgress`, `cal-postgres`,
  `teslamate-db`, `n8n-db`, `paperless_postgres`, `teleport_postgres`, `jellystat-db`, `pwpush-db`)
  and their *combined* payload is **793 MB**, of which 538 MB is one database (`agentic_os`). Nine
  postmasters, nine sets of shared buffers, nine WAL writers, for well under a gigabyte of data.
  Merging these into **one** PG 18 instance with nine databases and nine roles is mechanically
  simple (`pg_dump` per database; the repo already ships `scripts/pg-migrate.sh`) and removes eight
  containers and eight independent upgrade obligations.
- **Three cannot join and should not be asked to:**
  - `immich_postgres` is **PG 14** and carries `vchord` — Immich pins its own Postgres image and
    the version is part of the supported matrix. Leave it alone.
  - `dawarich_db` is **PostGIS 17** — a different extension surface.
  - `buzz-postgres` is **17** and is a vendored upstream stack.
- **Watch the version drift you already have inside the "PG 18" group**: 18.4 and 18.6 are both
  present because four of them pin `postgres:18` / `postgres:18-trixie` / `pgvector:pg18` — **two-part
  floating tags**, which `DEPLOYMENT.md` § 5 already warns about. A shared instance forces one
  version, which is a feature.

**SQLite-on-a-volume** (state that has no server and is therefore invisible to any `pg_dump`-based
backup). Top entries by size, measured:

| File | Size | Service | Backing store |
|---|---|---|---|
| `…/media/jellyfin/data/introskipper/introskipper-cache.db` | **855 MB** | Jellyfin Intro Skipper plugin | ZFS `fast/appdata/media` — **regenerable cache, the largest single state file in the estate** |
| `…/media/jellyfin/data/jellyfin.db` | **363 MB** | **Jellyfin — users, watch history, library** | ZFS `fast/appdata/media` |
| `…/arrs/sonarr/config/sonarr.db` | 211 MB | Sonarr | ZFS `fast/appdata/arrs` |
| `…/arrs/radarr/config/radarr.db` | 89.6 MB | Radarr | ZFS `fast/appdata/arrs` |
| `…/arrs/lidarr/config/lidarr.db` | 63.1 MB | Lidarr | ZFS `fast/appdata/arrs` |
| `…/arrs/prowlarr/config/prowlarr.db` | 16.3 MB | Prowlarr | ZFS `fast/appdata/arrs` |
| `…/media/wizarr/database/database.db` | 14.8 MB | Wizarr (invites, users, audit log) | ZFS `fast/appdata/media` |
| `…/homarr/appdata/db/db.sqlite` | 6.5 MB | **Homarr — not running** | ZFS `fast/appdata/homarr` |
| `…/media/seerr/config/db/db.sqlite3` | ~4 MB (+WAL) | Seerr (requests, users) | ZFS `fast/appdata/media` |
| `…/monitoring/grafana/grafana.db` | 1.6 MB | **Grafana — dashboards, users, alert rules** | **LXC ext4 root** |
| `…/traefik/authelia/db.sqlite3` | 344 KB | **Authelia — every 2FA enrolment and session** | ZFS `fast/appdata/traefik` |
| `…/rustdesk/db_v2.sqlite3` | ~1.3 MB | RustDesk peer registry | **LXC ext4 root** |
| `termix_termix_data`, `trek_trek_data`, `codeserver`, `podsync/db` | small | — | mixed |

### 1.3 Caches and brokers

Seven Redis-family instances. Six are standalone containers; the seventh is **inside** the
Dispatcharr all-in-one image. Keyspace measured live per instance.

| Instance | Image | Keyspace in use | Consumers | State path |
|---|---|---|---|---|
| `ai-redis` | `redis/redis-stack:7.4.0-v8` (the **Stack** build — RediSearch/JSON/Bloom/TimeSeries modules, ~895 MB image) | **db1** (1 key) = SearXNG; **db2** (2 keys) = open-webui general; **db3** (3 keys) = open-webui websocket manager | `ai-searxng` (`SEARXNG_VALKEY_URL=valkey://ai-redis:6379/1`), `ai-openwebui` (`REDIS_URL=…/2`, `WEBSOCKET_REDIS_URL=…/3`) | **ephemeral — no volume bound at all** |
| `paperless_redis` | `redis:7.4-alpine` | db0, 10 keys | `paperless` | named volume `documents_paperless_redis` → **LXC ext4 root** |
| `dawarich_redis` | `redis:7.4-alpine` | db0 (10) + **db1 (1306 keys)** = Sidekiq queue | `dawarich_app`, `dawarich_sidekiq` | named volume `dawarich_dawarich_shared` → **LXC ext4 root** |
| `cal-redis` | `redis:7-alpine` (**floating**) | db0, 234 keys | `cal-api`, `cal-cron`, `cal-worker` | `/mnt/fast/appdata/automation/keeper/redis` (ZFS) |
| `immich_redis` | `valkey/valkey:8-bookworm` (digest-pinned) | db0, 81 keys | `immich_server` | **anonymous volume** `078cfbcd…` → LXC ext4 root |
| `buzz-redis` | `redis:7-alpine` (**floating**) | empty | `buzz-relay` | `/mnt/fast/appdata/buzz/redis` (ZFS) |
| *(embedded)* `dispatcharr` | inside `ghcr.io/dispatcharr/dispatcharr:0.29.0` | db0, **201 keys** (Celery broker, `CELERY_BROKER_URL=redis://localhost:6379/0`) | dispatcharr's own Celery workers | inside the container — **lost on recreate** |

**Consolidation verdict.** `ai-redis` already proves the pattern works — three logical consumers,
three DB indices, one server. Every other instance holds trivial state (81, 234, 10, 10 keys) and
could share the same server on distinct indices. Two caveats that decide it:

- **Sidekiq (dawarich, 1306 keys) and Celery (dispatcharr, 201 keys) are job *queues*, not caches.**
  Losing them loses in-flight work. They can share a server but the shared server then needs
  persistence and a memory limit that cannot be evicted out from under them.
- **`ai-redis` has no volume bound.** Everything in it is lost on recreate today. That is correct
  for SearXNG and open-webui websockets and wrong for anything queue-shaped. Any consolidation must
  bind a volume first.
- `redis/redis-stack` is a 895 MB image carrying four modules. Nothing in the env of any consumer
  references RediSearch/JSON/TimeSeries. Replacing it with `valkey:8-alpine` saves ~870 MB of image
  and is likely a no-op functionally — **but I did not verify that open-webui makes no module
  calls, so treat this as a candidate to test, not a conclusion.**

### 1.4 Embedding / AI models — three independent stacks, zero sharing

| Path | Engine | Model | Vector store | Corpus | Measured |
|---|---|---|---|---|---|
| **open-webui RAG** | `ai-ollama` over HTTP (`RAG_EMBEDDING_ENGINE=ollama`, `RAG_OLLAMA_BASE_URL=http://ai-ollama:11434`) | `nomic-embed-text:latest` (274 MB, pulled 11 h ago) | `VECTOR_DB=pgvector` → `ai-postgress` (`vector 0.8.3`) | *(none)* | **`owui` is 82 MB and the only user table with live rows is `config` (354). The RAG pipeline is fully configured and effectively unused.** |
| **neocortex-memory** | **in-process ONNX**, not Ollama (`MEMORY_API_SERVER_EMBEDDINGS=1`, `MEMORY_MODEL_CACHE_DIR=/data/models`) | **`Xenova/bge-m3`**, 549 MB on disk at `/mnt/fast/appdata/automation/neocortex-memory/models/Xenova/bge-m3` | `agentic-os-db` (`vector 0.8.3`), DB `neocortex_memory` (74 MB) | the knowledge vault | Model files present and sized; container at **1.645 GiB / 2 GiB = 82 % of its own limit** |
| **immich** | `immich_machine_learning`, **CPU-only** (`IMMICH_ML_FORCE_CPU=true`, `DEVICE=cpu`, `EXECUTION_PROVIDERS=CPUExecutionProvider`) | CLIP + facial-recognition + OCR, **786 MB** in the `immich_model-cache` named volume | `immich_postgres` — `vchord 0.4.3` + `vector 0.8.0` (**pg14**) | 2368 MB `immich` DB over ~85 k assets | `ls /cache` → `clip`, `facial-recognition`, `ocr` |

**Cloud, not local — worth knowing because it is the opposite of the assumed picture:**

| Service | Provider | Model |
|---|---|---|
| `karakeep-web` / `karakeep-workers` | **OpenAI** (`OPENAI_API_KEY` set; no `OLLAMA_*` var present) | default |
| `paperless` | **OpenAI** (`LLM_PROVIDER=openai`, `OPENAI_BASE_URL=https://api.openai.com/v1`) | `gpt-4o-mini` |
| `paperless-gpt` | **OpenAI** | `gpt-4o-mini` |

**Is anything embedded twice? No.** Four corpora (open-webui documents, the neocortex vault,
Immich photos, karakeep bookmarks) with four different embedders and no overlap. The duplication
is not of *content*, it is of *machinery*: three model runtimes (Ollama, an in-process ONNX
runtime, Immich's ONNX runtime), three model caches (274 MB + 549 MB + 786 MB = **1.6 GB**), and
three vector stores across two pgvector 0.8.3 instances and one pg14/vchord instance.

**`ai-ollama` is idle.** `ollama ps` returns an empty table (no model resident) and
`docker logs --since 24h ai-ollama` contains **zero** `/api/*` request lines. It holds a 5.51 GB
image and 2.2 GB of models on disk (`nomic-embed-text` 274 MB, `qwen2.5:3b` and `qwen2.5:3b-32k`
1.9 GB each, the latter two **7 months old**). It also publishes itself on the tailnet
(`tsbridge.service.name=ollama`) and at `ollama.deercrest.info` with **no Traefik middleware at
all** — see § 1.5.

### 1.5 Reverse proxy / ingress

```
Internet ──443──> Cloudflare (per-host CNAME, no wildcard) ──> UCG Max :443
                                                                  │
                                                       172.16.1.159:443
                                                                  │
                                                             traefik (v3.7.9)
                                                              ├── socket_proxy ──> socket-proxy ──> /var/run/docker.sock
                                                              └── t3_proxy (192.168.90.0/24) ──> 74 containers

Tailnet ──> tsbridge (v0.13.1, own node per service) ──> 10 containers, bypassing Traefik entirely
LAN     ──> iot_macvlan ──> jellyfin 172.16.1.76, dispatcharr 172.16.1.75, bypassing Traefik entirely
```

**`t3_proxy` carries 74 of the 98 running containers** — it is the single largest coupling in the
estate.

Authelia coverage, counted from live container labels:

| Class | Count | Members |
|---|---|---|
| `chain-authelia@file` (SSO enforced) | **26 routers** | audiobookshelf, autobrr, bazarr, beets-flask, blockbusterr, dispatcharr (admin UI), flaresolverr, freshrss, janitorr, jellystat (UI), lidarr, oxidized, paperless, paperless-gpt, prometheus, prowlarr, qbittorrent, radarr, readarr, sabnzbd, sonarr, termix, teslamate, teslamate-grafana, traefik dashboard, trek |
| `chain-no-auth@file` (explicitly unauthenticated) | **14 routers** | authelia itself, dawarich, immich_server, jellystat `/api` etc., seerr, teleport, wizarr, **plus 7 `*-bypass` routers** |
| **No middleware at all** | **17 routers** | `docling.`, **`ollama.`**, `chat.`, **`mcp.`**, `search.`, `livesync.` (CouchDB), `grafana.`, `kiosk.`, **`jellyfin.`**, `podsync.`, `pwpush.`, `hass./.well-known`, `dispatcharr tv.` (rate-limit only), `cortex.`, and the three `@docker` middlewares below |
| `@docker` middlewares — **headers only, NOT auth** | 4 routers | `keeper`, `keeper-api`, `karakeep`, `n8n`. Verified: every label under these is `headers.*` (HSTS, `contentTypeNosniff`, `browserXSSFilter`). **None of them authenticate.** |

Findings in this layer:

- **`ollama.deercrest.info`, `mcp.deercrest.info` and `docling.deercrest.info` have no Traefik
  middleware and the applications behind them have no authentication of their own.** Ollama in
  particular has no auth mechanism at all. External reach depends on whether a Cloudflare CNAME
  exists for each host — `NETWORK.md` states there is **no wildcard**, so these may only be
  LAN/tailnet-reachable. **I did not resolve these names, so I cannot say whether they are
  internet-exposed. That is the one check worth running before anything else in this document.**
- **The seven `*-bypass` routers all share one header value.** `sonarr`, `radarr`, `readarr`,
  `lidarr`, `bazarr`, `sabnzbd`, `qbittorrent` each carry a router whose rule is
  `Header('auth-bypass-key', …)` → `chain-no-auth@file`. In git these are `${*_AUTH_BYPASS_KEY}`
  (so **not leaked in the public repo** — good), but at runtime **all seven resolve to the same
  date-shaped string**, and `audiobookshelf` and `jellystat` additionally carry a
  `TRAEFIK_AUTH_BYPASS_KEY` env var whose value is the literal placeholder `00000000-1234-1234-1234`.
  One guessed header defeats Authelia on seven admin UIs at once.
- **`searxng-denyjson` is an `ipallowlist.sourcerange = 192.0.2.1/32`** — TEST-NET-1, i.e. a
  deliberate deny-all dressed as an allow-list. Clever, and worth a comment in the file so it is
  not "fixed".
- **`tsbridge` binds `/var/run/docker.sock` read-write directly**, bypassing the `socket-proxy`
  that Traefik is deliberately routed through. So does `homarr` (read-only) when it runs. The
  socket-proxy is therefore a partial control, not a complete one.
- **`traefik` and `authelia` are both digest-pinned and both drifted** — running `traefik:v3.7.9`
  vs declared `v3.7.13`, `authelia:4.39.20` vs declared `4.39.28`. `check-drift.sh` reports these
  separately as `DIGEST_PINNED` and deliberately does **not** count them as drift.

### 1.6 Object storage, message queues, other shared components

| Component | Instance | Notes |
|---|---|---|
| **Object storage** | `buzz-minio` only (`minio/minio:RELEASE.2025-09-07T16-13-09Z`), bucket `buzz-media`, data on `/mnt/tank/buzz/minio` (ZFS `tank/buzz`, 14 M) | Used solely by `buzz-relay`/`buzz-pairing-relay`. Nothing else in the estate uses S3. Repo sweep: `MINIO`/`S3_` appear only in `buzz/` and `open-archiver/.env` |
| **Message queues** | **No RabbitMQ, no NATS, no Kafka, no AMQP** — repo sweep found zero occurrences of `RABBIT`, `AMQP`, `NATS`, and no running image matches | Queueing is Redis-backed: Sidekiq (dawarich) and Celery (dispatcharr) |
| **MQTT** | **Not on this host.** `teslamate` points at `MQTT_HOST=172.16.1.31` — the **Home Assistant NUC's** broker. An off-box, cross-estate dependency | Matches the recorded operating note that TeslaMate and HA must share one broker |
| **Document extraction** | **`apache/tika:3.3.1.0-full` runs TWICE** — `ai-tika` (openwebui) and `paperless_tika` (documents). Same image, same version, 843 MB. A third is declared in open-archiver | 274 MiB + 178 MiB RSS. **Directly consolidatable**: Tika is a stateless HTTP service; point `PAPERLESS_TIKA_ENDPOINT` and `TIKA_SERVER_URL` at one instance on a shared network |
| **Document conversion** | `paperless_gotenberg` (`gotenberg/gotenberg:8.34`, 1.68 GB image) — one instance, one consumer | — |
| **Headless browser** | `karakeep-chrome` (`zenika/alpine-chrome:124`) and `flaresolverr` (`v3.5.0`) both run Chromium for different reasons | Not trivially mergeable — different protocols (CDP vs FlareSolverr's HTTP API) |
| **Grafana** | **Two instances**: `grafana` (`13.1.1`, monitoring stack, SQLite on the LXC ext4 root) and `teslamate-grafana` (`4.2.0`, vendored, its own Postgres datasource, named volume) | The TeslaMate one ships pinned upstream dashboards. Merging means re-importing ~20 dashboards and repointing a datasource — possible, low value |
| **Metrics exporters** | 7 × `ghcr.io/onedr0p/exportarr:v2.3.0` sidecars (one per arr) + `node-exporter` | All 7 carry a stale `SLSKD_URL=http://slskd:5030` env — **`slskd` does not exist anywhere in the repo or on the host**; these are orphaned env vars from a deleted service, inert |
| **Docker socket** | `socket-proxy` (the intended broker), plus direct RW mount by `tsbridge` | § 1.5 |

---

## 2. Dependency graph

### 2.1 Stack-level graph

```
                     ┌──────────── traefik stack ────────────┐
                     │  socket-proxy ← traefik ← authelia    │   tsbridge
                     │        creates t3_proxy + socket_proxy│      │
                     └───────────────┬───────────────────────┘      │
                                     │ t3_proxy (74 containers)     │ own tailnet nodes (10)
   ┌──────┬──────┬─────────┬─────────┼─────────┬──────────┬─────────┴──┬──────────┐
 arrs   media  documents openwebui  monitoring keeper-sh dawarich   immich    automation
   │      │        │         │          │                               │          │
   │      │        │         │          │                               │      ┌───┴────┐
   │      └─ iot_macvlan ────┘          │                               │    n8n    couchdb
   │         (jellyfin, dispatcharr)    │                               │
   │                                    └── prometheus scrapes t3_proxy │
   └── /mnt/tank/downloads (shared bind, 8 writers)                     │
                                                                  tank/media/Photos
        agentic-os ──agentic-os_default──> neocortex-memory-api ──traefik_default──> tsbridge
                     (CROSS-STACK)                    │
                                              /mnt/fast/stacks-private/neocortex-platform
                                                  (a SEPARATE repo, not in this one)
```

### 2.2 (a) Single points of failure

| SPOF | Blast radius | Evidence |
|---|---|---|
| **`traefik` + the `t3_proxy` network** | **74 of 98 running containers**. Every `*.deercrest.info` hostname. `DEPLOYMENT.md` already states traefik must come up first because it *creates* the network | `docker network inspect t3_proxy` |
| **`authelia`** | The 26 SSO-gated routers. Authelia down = those services return 502, not "open" — fail-closed, which is correct | Router middleware census |
| **`socket-proxy`** | Traefik's only route to the Docker API → **all dynamic router discovery**. If it dies, Traefik keeps serving its last config but learns nothing new | `traefik` is on `socket_proxy` and has no direct socket bind |
| **`ai-redis`** | 3 logical consumers (SearXNG, open-webui general, open-webui websockets) and **has no persistent volume** — a restart is a data loss event by design | `docker inspect` shows zero mounts |
| **`agentic-os-db`** | `neocortex-memory-api` entirely (both its primary and legacy-bridge connections), and it is the **only cross-stack database dependency in the estate** | `MEMORY_DATABASE_URL` / `MEMORY_LEGACY_DATABASE_URL` both `@agentic-os-db:5432` |
| **`dispatcharr`** | The entire TV chain — Jellyfin Live TV, TiviMate at Fosse Road, **and the DVR**. Single source since 2026-08-14. It is also an all-in-one image with its own internal Redis holding 201 Celery keys | `MEDIA.md` § 5, verified: `iot_macvlan` 172.16.1.75 |
| **`/mnt/tank/downloads`** | A single bind shared RW by `sabnzbd`, `qbittorrent`, `prowlarr`, `sonarr`, `radarr`, `lidarr`, `readarr`, `bazarr`, `beets-flask` — **9 containers**. Not a service, but a shared-state SPOF | Mount census |
| **LXC 100's 126 GB ext4 root at 83 %** | Everything. 20.6 GB free. § 4 | `df -h /` |

### 2.3 (b) Hidden cross-stack couplings

| Coupling | Detail |
|---|---|
| **`neocortex-memory-api` joins THREE external networks** | `agentic-os_default` (to reach `agentic-os-db`), `traefik_default` (to be seen by `tsbridge`), `t3_proxy`. The first is the only container in the estate on another stack's *implicit default* network — **and that name only exists because `agentic-os/compose.yaml` sets no `name:`**. Adding `name:` to that file silently breaks neocortex. |
| **`tsbridge` lives on `traefik_default`, not `t3_proxy`** | It declares no network, so Compose puts it on the traefik project's default. That is why neocortex has to join `traefik_default` explicitly. Non-obvious and undocumented. |
| **`/mnt/fast/stacks-private/neocortex-platform` is a different repo** | Bind-mounted `:ro` into `neocortex-memory-api` as `/app`. 236 MB, **on the LXC ext4 root**, not a ZFS dataset, not in this git repo, not backed up. The container also depends on `…/neocortex-memory/deps/node_modules` built separately by a `profiles: ["setup"]` service. |
| **`couchdb` bind-mounts a file out of the git checkout** | `/mnt/fast/stacks/stacks/selfhosted/couchdb/neocortex.ini:ro`. A `git pull` changes live CouchDB config. Same pattern for `grafana` (3 provisioning files) and `prometheus` (`prometheus.yml`). |
| **`code-server` mounts the whole repo RW** | `/mnt/fast/stacks:/stacks:rw`. Anything in code-server can rewrite every stack definition on the host. |
| **`seerr` reaches Jellyfin, Sonarr and Radarr over the PUBLIC hostnames** | Its `settings.json` has all three at `port: 443, useSsl: true` — so requests leave the box, hit Cloudflare/Traefik and come back. Works, but couples three internal integrations to DNS, TLS and the WAN. |
| **`jellystat` reaches Jellyfin at `https://jellyfin.deercrest.info`** | Same pattern, confirmed from its `app_config` table. |
| **`teslamate` → `172.16.1.31`** | Hardcoded LAN IP of the HA NUC's MQTT broker. Cross-host, no service discovery. |
| **`audiobookshelf` and `jellystat` share the media stack `.env`** | `audiobookshelf` carries `JELLYSTATDB_USER`, `JELLYSTATDB_PASS`, `SABNZBD_API_KEY` and `TRAEFIK_AUTH_BYPASS_KEY` in its environment — none of which it uses. A stack-wide env file leaking credentials into unrelated containers. |
| **`prometheus` scrapes by container name across `t3_proxy`** | Its scrape config is a repo file; every target is a hardcoded container name. Renaming any container silently breaks a scrape. |
| **`fast/appdata/hoarder` is one dataset for three unrelated stacks** | Measured: `podsync` **143 G**, `freshrss` 48 M, `karakeep` **979 K**, plus a 26 M stale backup dir. A quota or snapshot on it hits all three, and the name suggests karakeep (formerly "hoarder") owns it when in fact podsync does. |
| **Jellyfin holds the ONLY RW mount on `/mnt/tank/media`** | Deliberate (D-21), asserted by `check-music-freeze.sh`. Any Jellyfin replacement inherits this decision. |

### 2.4 (c) Things depending on something that is not running

| Dependent | Missing dependency | Consequence |
|---|---|---|
| 7 × `*-exporter` | `slskd` (`SLSKD_URL=http://slskd:5030`) | **Inert** — `slskd` has no definition anywhere in the repo and no container. Orphaned env vars, verified harmless |
| `immich_postgres`, `immich_redis` | **`/mnt/fast/stacks/immich/compose.yaml` — a compose file that does not exist** | These two containers were created from a *deleted* path. `check-drift.sh` reports them as `UNRESOLVABLE` and the estate has whitelisted them as expected. **They will not be recreated by `docker compose -f stacks/selfhosted/immich/compose.yaml up -d` under the same identity** — the project's other three containers resolve from the correct path. This is a live split-brain in the immich stack |
| `janitorr` | Jellyfin integration `enabled: false`, empty api-key | By configuration, not by fault |
| `seerr` | A Plex server (`plex: {name: '', port: 32400}`) | Vestigial config, unused |
| `wrappers/{books,documents,saas,social}.app.yaml` | Use `extends: {file: …}` **with no `service:` key** | Compose requires `service:` under `extends`. These four wrappers are almost certainly non-functional; the other 24 use `include:` |
| `automation/falcon-player.yaml` (`fpp`) | Not referenced by any `include:` | Dead definition |

---

## 3. What is not running, or is orphaned

### 3.1 Stacks declared in git with zero containers running

| Stack | Declared containers | State on disk | Verdict |
|---|---|---|---|
| **`open-archiver`** | `open-archiver`, `open-archiver_postgres`, `open-archiver_valkey`, `open-archiver_meilisearch`, `open-archiver_tika` | **67 MB on the LXC ext4 root** — `postgres/`, `valkey/`, `meilisearch/` **and `meilisearch.bak-20260730/`**. Its data bind `/mnt/tank/archive/open-archiver` **exists and is empty** (created 2026-02-15, `root:root`, 4096 bytes) | **Never ingested anything.** Confirmed down. The 67 MB is pre-seeded DB/index skeletons. Safe to delete if the stack is retired; it is the second Meilisearch and the third Tika |
| **`social`** (postiz + rybbit) | `postiz`, `postiz_postgres`, `postiz_redis`, `rybbit`, `rybbit_postgres` | `/mnt/fast/appdata/social/*` — not present | Down. Tracked as issue #307 (rybbit) |
| **`postiz`** (standalone) | `postiz`, `postiz_postgres`, `postiz_redis` — **the same three container names as `social`** | **15 MB at `/mnt/fast/appdata/postiz`** on ZFS `fast/appdata/postiz` (has an `mp12` bind) | Down. **Name collision: only one of the two stacks can ever run.** Two wrappers, two `.env` sets, two bind roots. This must be resolved before either is deployed |
| **`saas`** (cal.com) | `calcom`, `calcom_postgres` | not present | Down |
| **`mcp`** | `mcp-atlassian`, `mcp-notion`, `mcp-d365fo` | none | Down. `mcp-notion` has **no image tag at all** → implicit `:latest` |
| **`homarr`** | `homarr` | **3.6 MB at `/mnt/fast/appdata/homarr`**, ZFS dataset with an `mp6` bind, contains a 6.5 MB `db.sqlite` | Down, but dataset + Terraform mount + state all still provisioned |
| **`books`** (booklore) | `booklore`, `booklore_postgres` | not present | Down |
| **`music`** | — | Directory contains **only `.env` and `.env.backup`** | `compose.yaml` and `wrtag.yaml` deleted in `e63e0fd`. Consistent with `CLAUDE.md`'s Phase 4 record |

Plus definitions that exist but are deliberately unreachable: `arrs/beets/beets.yaml`
(`profiles: ["manual"]`, `restart: "no"`, commented out of `include:`), `arrs/listenarr.yaml`,
`arrs/boxarr.yaml` (commented; would collide on host port 8888 with `oxidized`),
`immich_power_tools`, `karakeep-mcp`, `openwebui/ai-pipelines`, `automation/falcon-player.yaml`.

### 3.2 Containers running that git does not define

**None.** Every one of the 99 containers resolves to a compose file in this repo via its
`com.docker.compose.project.config_files` label, with the two documented exceptions in § 2.4
(`immich_postgres`, `immich_redis` — defined, but the *running instances* were created from a
deleted path).

`beets-flask` was worth checking and is **legitimate**: `stacks/selfhosted/arrs/beets/flask.yaml`
is tracked in git (`git ls-files` confirms four files under `arrs/beets/`), it is line 68 of the
`arrs/compose.yaml` `include:` list, and its image matches (`metasauce/beets-flask:v2.0.0-rc6`).

### 3.3 Container states

`docker ps -a --format '{{.State}}' | sort | uniq -c` → **98 running, 1 exited, 0 created, 0 dead,
0 restarting**. The one `exited` is `buzz-minio-init` (exit 0, 5 weeks ago) — a one-shot bucket
initialiser that is *supposed* to exit. `check-drift.sh` confirms **0 unhealthy** and **0 created**.

The `created`-state trap that cost six weeks in 2026 is not currently firing.

### 3.4 Images nothing references

`docker system df`:

| | Total | Active | Size | Reclaimable |
|---|---|---|---|---|
| Images | **89** | 83 | **79.83 GB** | **60.9 GB (76 %)** |
| Containers | 99 | 98 | 2.19 GB | 1.7 kB |
| Local volumes | 19 | 9 | 948 MB | 8.9 kB |

**60.9 GB is reclaimable on a filesystem with 20.6 GB free.** *[CORRECTED 2026-09-25: that figure is wrong. `docker system df`'s RECLAIMABLE counts shared layers still held by running containers. Enumerating images actually unreferenced by any container gave ~21 GB, and a full `prune -a` recovered **18.93 GB** (83% -> 68%). The field still reports 60.9 GB *after* the prune, which proves it does not describe free-able space. See `.planning/plans/unblock-disarm-reclaim-close-backup-gap.plan.md` § T2.]* 8 images are dangling. The
identifiable stale ones:

| Image | Size | Why it is stale |
|---|---|---|
| `quay.io/docling-project/docling-serve:v1.25.0` | **8.86 GB** | superseded by `v1.35.0`, which is also present (9.87 GB) |
| `ghcr.io/open-webui/open-webui:v0.9.6` | **4.78 GB** | superseded by `v0.11.4` |
| `ollama/ollama:0.32.5` | **4.76 GB** | superseded by `0.34.4` |

Those three alone are **18.4 GB**. A `docker image prune -a` (after confirming no stopped container
needs them) is the single highest-yield action available on the root filesystem.

Also reclaimable: **10 of 19 local volumes are unused**, and on atlantis
**`fast/ix-apps` is 238 GB of dead TrueNAS-era Docker root** — `zfs get mounted fast/ix-apps/docker`
returns **`no`**, `/.ix-apps/docker` does not exist, and its newest snapshot is from
2025-12-31. `fast/.system` (2.09 GB, also `mounted=no`) is the same vintage. **240 GB of the
`fast` pool's 460 GB used is TrueNAS leftover.**

---

## 4. Resource footprint

**Host:** LXC 100, `memory: 24576` MB, **`swap: 0`**, 8 cores.
**Measured `free -m`:** total 24576, used **21048**, free 1741, buff/cache 3613, **available 3527**.
**Sum of all 98 containers' `docker stats` RSS: 20 538 MiB = 20.06 GiB — 84 % of the host.**

### 4.1 Memory limits: declared vs actual

- **22 of 98 running containers have a `mem_limit`.** They sum to **exactly 36 GiB on a 24 GiB
  host — a 1.5× overcommit on the limited set alone.**
- **76 of 98 have no limit at all.** Any one of them can take the box.
- **Two containers are running WITHOUT a limit that git declares for them** — a deploy-drift class
  the estate's own `check-drift.sh` does not look for:

| Container | Declared in git | Running `HostConfig.Memory` |
|---|---|---|
| `janitorr` | `mem_limit: 1g` | **0 (unlimited)** — and it is using 422.6 MiB |
| `paperless` | `mem_limit: 1536m` | **0 (unlimited)** — and it is using 546.9 MiB |

### 4.2 Biggest consumers

| Container | RSS | Limit | % of its limit | Note |
|---|---|---|---|---|
| `immich_server` | **3.049 GiB** | 6 GiB | 51 % | largest single consumer |
| **`neocortex-memory-api`** | **1.645 GiB** | **2 GiB** | **82 %** | **closest to its ceiling of anything running.** Holds `bge-m3` in-process |
| `dispatcharr` | 1.151 GiB | 3 GiB | 38 % | all-in-one incl. its own Redis + Celery |
| `jellyfin` | 988.6 MiB | 3 GiB | 32 % | |
| `ai-docling` | 957.1 MiB | 2 GiB | 47 % | **idle** — no traffic observed |
| `beets-flask` | 712.6 MiB | **none** | — | |
| `ai-openwebui` | 626.8 MiB | 1.5 GiB | **41 %** | |
| `immich_postgres` | 576.8 MiB | **none** | — | |
| `pwpush` | 572.6 MiB | **none** | — | 572 MiB for a password-sharing page |
| `paperless` | 546.9 MiB | **none** (declared 1536m) | — | |
| `flaresolverr` | 308.8 MiB | **none** | — | Chromium |
| `wizarr` | 316.0 MiB | **none** | — | |
| `seerr` | 305.3 MiB | **none** | — | |
| `karakeep-workers` | 303.0 MiB | **none** | — | |
| `paperless_tika` + `ai-tika` | 274.2 + 178.1 = **452 MiB** | none / 1 GiB | — | **the same service, twice** |

### 4.3 Where the memory would come back

| Action | Measured saving | Confidence |
|---|---|---|
| Stop `ai-ollama` + `ai-docling` (both idle: no model resident, no 24 h traffic) | ~970 MiB RSS, ~15.4 GB of images | High — idleness measured, *usefulness* not judged |
| Merge 9 × PG 18 into 1 | ~8 postmasters ≈ **550 MiB** (measured RSS of the 8 smallest: 30.7+34.5+38.2+38.8+95.0+112.6+140.6+158.1) | High |
| Merge 6 standalone Redis into 1 | ~150 MiB | High |
| Merge the two Tika | ~180 MiB | High |
| Put a limit on the 76 unlimited containers | 0 today; converts an *unbounded* failure into a *bounded* one | — |

### 4.4 Disk

| Filesystem | Size | Used | Free | Note |
|---|---|---|---|---|
| **LXC 100 `/` (ext4 on `pve-vm--100--disk--0`)** | 126 G | **99 G** | **20.6 G (83 %)** | Docker images are ~80 GB of this. **60.9 GB reclaimable** |
| `fast` pool (atlantis) | 1.81 T | 423 G (22 %) | 1.40 T | **238 G of it is dead `ix-apps`** |
| **`tank` pool** | 70.9 T | **62.8 T (88 % CAP)** | 8.08 T | **Above the 80 % ZFS performance threshold** |
| `backup` pool | 14.5 T | 3.50 T (24 %) | 11.0 T | |

---

## 5. Data and state inventory — what survives a rebuild, and what does not

### 5.1 The backup reality

`/usr/local/bin/run-backup.sh` and `/usr/local/bin/backup-incremental.sh` on **atlantis** (read in
full) replicate **exactly seven datasets** to the `backup` pool:

```
tank/media/Photos                    tank/media/Books
tank/backups/icloud-photos-library   tank/media/Music
tank/backups/hufflepuff-scavenge     tank/downloads/mybook-music-archive
tank/backups/immich-db  ← pg_dumpall of immich_postgres, written by the script itself
```

Verified against `zfs list -r backup`: `backup/media/{Books,Music,Photos}`,
`backup/backups/{hufflepuff-scavenge,icloud-photos-library,immich-db}`,
`backup/downloads/mybook-music-archive`. **Nothing else exists on the backup pool.**

Therefore, measured facts:

1. **Not one byte of `fast/appdata` is backed up.** No `backup/appdata` dataset exists. Every
   application's configuration and state — arrs, Jellyfin, Traefik, Authelia, karakeep, all twelve
   Postgres instances except Immich's — has **zero off-box copy**.
2. **`fast` has essentially no snapshots either.** `zfs list -t snapshot -r fast` returns **7**, of
   which **6 are dead `ix-apps` snapshots from 2025**. The only live one is
   `fast/appdata/immich/postgres@pre-v3-20260918`.
3. **The backup is not scheduled.** `systemctl list-timers --all | grep -i backup` on atlantis
   returns only `dpkg-db-backup.timer`. **Nothing runs `run-backup.sh` but a human.**
4. `tank/media/TV` (20.1 T) and `tank/media/Movies` (15.3 T) are not backed up — presumably
   deliberate (re-acquirable), but it should be a stated decision rather than an omission.

### 5.2 State inventory

Legend — **Backup:** `BACKED UP` = on the backup pool · `ZFS only` = on a `fast` dataset, so it
survives an LXC rebuild but has no off-box copy and (bar one) no snapshot · **`LOST`** = on the LXC
ext4 root or in a Docker volume, destroyed by an LXC rebuild *and* by `docker compose down -v`.

| Service | State location | Size | Backing store | Backup |
|---|---|---|---|---|
| **Immich photos** | `/mnt/tank/media/photos` → **resolves to the `tank/media/Photos` dataset** (same inode 34; `tank/media` is `casesensitivity=insensitive` while its children are `sensitive`) | **651 G** | ZFS `tank/media/Photos` | ✅ **BACKED UP** |
| **Immich database** | `/mnt/fast/appdata/immich/postgres` | 3.39 G | ZFS `fast/appdata/immich/postgres` (`mp8`) | ✅ via `pg_dumpall` → `tank/backups/immich-db` → backup pool. **The script explicitly exists because this is not on tank.** Has the only live `fast` snapshot |
| **Music library** | `/mnt/tank/media/Music` | 33.9 G | ZFS | ✅ BACKED UP |
| **Books library** | `/mnt/tank/media/Books` | 21.2 G | ZFS | ✅ BACKED UP |
| **DJ music archive** | `tank/downloads/mybook-music-archive` | 1.30 T | ZFS | ✅ BACKED UP |
| **TV / Movies** | `tank/media/{TV,Movies}` | 20.1 T / 15.3 T | ZFS | ❌ not backed up (likely deliberate) |
| **DVR recordings** | `tank/media/Recordings` | 9.6 M | ZFS, 233 G quota | ❌ |
| **Jellyfin config + `jellyfin.db`** (users, watch history, library, collections, playlists) | `/mnt/fast/appdata/media/jellyfin` | **13 G** (of which `jellyfin.db` 363 MB, `introskipper-cache.db` 855 MB) | ZFS `fast/appdata/media` | ⚠️ **ZFS only — no backup, no snapshot** |
| **Jellystat playback history** | `jellystat-db` → `/mnt/fast/appdata/media/jellystat/postgres` | 94 MB (311 playback rows, 5 users, 2863 items) | ZFS `fast/appdata/media` | ⚠️ ZFS only |
| **Seerr requests/users** | `/mnt/fast/appdata/media/seerr/config` | ~4 MB | ZFS | ⚠️ ZFS only |
| **Wizarr invites/users** | `/mnt/fast/appdata/media/wizarr/database/database.db` | 14.8 MB | ZFS | ⚠️ ZFS only |
| **Arr state** (Sonarr 211 MB, Radarr 90 MB, Lidarr 63 MB, Prowlarr 16 MB, Readarr, Bazarr, sabnzbd history, qBittorrent) | `/mnt/fast/appdata/arrs/*` | 4.82 G | ZFS `fast/appdata/arrs` | ⚠️ ZFS only |
| **Traefik ACME certificates** | `/mnt/fast/appdata/traefik/acme/acme.json` | 16 KB | ZFS `fast/appdata/traefik` | ⚠️ ZFS only — re-issuable, but rate-limited by Let's Encrypt |
| **Authelia** — every 2FA enrolment, session, user | `…/traefik/authelia/db.sqlite3` + `users_database.yml` | 344 KB + 456 B | ZFS `fast/appdata/traefik` | ⚠️ ZFS only. Losing it means **every user re-enrols their TOTP/WebAuthn** |
| **Traefik secrets** (`cf_dns_api_token`, 3 × Authelia keys) | `/mnt/fast/appdata/traefik/secrets/` | tiny | ZFS | ⚠️ ZFS only. **Not in git** (correct) — so a rebuild without these cannot bring Authelia up at all |
| ⚠️ **`authelia.log`** | `/mnt/fast/appdata/traefik/authelia/authelia.log` | **528 MB, unrotated** | ZFS `fast/appdata/traefik` | Not state — but it is 1536× the size of the database it sits beside, and nothing rotates it. Also: `configuration.yml` contains a **commented-out `encryption_key:` line with a plaintext password-shaped value**; the live key comes from the Docker secret, but the string should be removed rather than commented |
| **podsync downloads** | `/mnt/fast/appdata/hoarder/podsync` | **143 G — the single largest app-state item in the estate, and 99.9 % of the `hoarder` dataset** | ZFS `fast/appdata/hoarder` | ⚠️ ZFS only. **This is a re-downloadable media cache sitting on the SSD pool with no quota.** It belongs on `tank`, or behind a quota, or both |
| **karakeep** bookmarks + assets + Meili index | `/mnt/fast/appdata/hoarder/karakeep/{data,meili}` | **979 KB** — measured. karakeep is effectively empty (consistent with its DNS record having been missing until 2026-09-17) | ZFS `fast/appdata/hoarder` | ⚠️ ZFS only, but there is almost nothing to lose |
| **freshrss** | `/mnt/fast/appdata/hoarder/freshrss` | 48 M | ZFS | ⚠️ ZFS only |
| *(stale)* `_backup-todo218-20260917-1501` | `/mnt/fast/appdata/hoarder/` | 26 M | ZFS | a leftover manual backup from the karakeep rename — deletable |
| **open-webui** (chats, users, settings, `owui` DB) | `/mnt/fast/appdata/llm-ai/{open-webui,postgres}` | 2.21 G total | ZFS `fast/appdata/llm-ai` | ⚠️ ZFS only |
| **Ollama models** | `/mnt/fast/appdata/llm-ai/ollama` | ~2.2 G | ZFS | ⚠️ re-pullable |
| **neocortex memory** (`neocortex_memory` 74 MB + `agentic_os` 538 MB) | `/mnt/fast/appdata/automation/agentic-os/postgres` | 612 MB | ZFS `fast/appdata/automation` | ⚠️ ZFS only |
| **neocortex platform code** | `/mnt/fast/stacks-private/neocortex-platform` | **236 M** | **LXC ext4 root** | 🔴 **LOST** — a separate repo, not in this git, no dataset. Verify it has a remote |
| **neocortex `bge-m3` model + `/data/root`** | `…/automation/neocortex-memory/{models,root,deps}` | 549 M models | ZFS `fast/appdata/automation` | ⚠️ models re-downloadable; `root` is not |
| **n8n workflows + credentials** | `/mnt/fast/appdata/automation/n8n*` (config) **+ `/automation/n8n-postgres` (the DATABASE)** | 1.98 G + **70 M** | config ZFS; **database on the LXC ext4 ROOT** | 🔴 **DATABASE LOST on an LXC rebuild.** The one bind in the estate that is not under `/mnt` at all |
| **CouchDB** (Obsidian LiveSync for every device) | `/mnt/fast/appdata/automation/couchdb/data` | in `automation` (1.98 G) | ZFS | ⚠️ ZFS only |
| **keeper-sh** (calendars) | `/mnt/fast/appdata/automation/keeper/{postgres,redis}` | 13 MB | ZFS | ⚠️ ZFS only |
| **pwpush** | `/mnt/fast/appdata/automation/pwpush/{db,data}` | ~10 MB | ZFS | ⚠️ ZFS only |
| **oxidized** (network device configs + **SSH keys**) | `/mnt/fast/appdata/automation/oxidized/{config,ssh}` | small | ZFS | ⚠️ ZFS only |
| **Grafana** (dashboards, users, alert rules) | `/mnt/fast/appdata/monitoring/grafana/grafana.db` | 1.6 MB | 🔴 **LXC ext4 root** | 🔴 **LOST** |
| **Prometheus TSDB** | `/mnt/fast/appdata/monitoring/prometheus` | **1.4 G and growing continuously** | 🔴 **LXC ext4 root, no quota** | 🔴 **LOST** — and it is the one on-root store that grows without bound |
| **Paperless** — documents, media, index, DB | 4 named volumes + `documents_paperless_postgres` under `/var/lib/docker/volumes`, plus `/mnt/fast/appdata/documents` (113 M) | ~113 M + volumes | 🔴 **LXC ext4 root** | 🔴 **LOST.** Scanned documents are usually the *least* reproducible data in a house |
| **TeslaMate** — every drive since installation | named volume `teslamate_teslamate-db` | 52 MB DB | 🔴 **LXC ext4 root** | 🔴 **LOST** |
| **TeslaMate Grafana** dashboards | named volume `teslamate_teslamate-grafana-data` | — | 🔴 LXC ext4 root | 🔴 LOST |
| **Teleport** — cluster CA, host certs, audit log | volumes `teleport_teleport_{data,config,postgres}` | small | 🔴 **LXC ext4 root** | 🔴 **LOST.** Losing the CA means re-enrolling every node |
| **Dawarich** — location history | volumes `dawarich_dawarich_{db_data,storage,public,watched,shared}` | 106 MB DB | 🔴 **LXC ext4 root** (the `fast/appdata/dawarich` dataset exists and holds only 103 M — the DB is in the volume) | 🔴 **LOST** |
| **Termix** (SSH host/credential manager) | volume `termix_termix_data` | 8.5 M | 🔴 LXC ext4 root | 🔴 LOST |
| **Trek** | volumes `trek_trek_{data,uploads}` | — | 🔴 LXC ext4 root | 🔴 LOST |
| **RustDesk** peer registry + server keypair | `/mnt/fast/appdata/rustdesk` | 1.4 M | 🔴 **LXC ext4 root** | 🔴 **LOST.** Losing the keypair re-keys every client |
| **Minecraft worlds** | `/mnt/fast/appdata/minecraft/{bedrock,yggdrasil}` | 795 M | ZFS | ⚠️ ZFS only |
| **Buzz** | `/mnt/fast/appdata/buzz/*` + `/mnt/tank/buzz/minio` | 42 M + 14 M | ZFS both | ⚠️ ZFS only |
| **code-server** settings | `/mnt/fast/appdata/code-server` | 1 M | ZFS | ⚠️ ZFS only |
| **`janitorr` and `flaresolverr` `/config`** | **anonymous volumes** (`273b4e7a…`, `98a3e069…`) | small | 🔴 LXC ext4 root, unnamed | 🔴 LOST — and exactly the anonymous-volume pattern `DEPLOYMENT.md` forbids |
| **`immich_redis` `/data`** | **anonymous volume** `078cfbcd…` | small | 🔴 LXC ext4 root | 🔴 LOST (cache, acceptable) |
| **`ai-redis`** | **no volume at all** | — | — | 🔴 LOST on every restart, by design |
| **`dispatcharr` internal Redis** | inside the container | 201 Celery keys | — | 🔴 LOST on recreate |

### 5.3 Explicit "would be LOST in a rebuild" list

Everything marked 🔴 above. Ranked by irreplaceability:

1. **Paperless** — scanned documents and their OCR/index. Nothing else holds them.
2. **`/automation/n8n-postgres`** — every n8n workflow and credential. An LXC-root path that is not
   under `/mnt`, so it is invisible to every convention this estate has.
3. **Teleport** — cluster CA and audit log. Rebuild means re-enrolling every node.
4. **TeslaMate** — every drive ever recorded. Not reproducible.
5. **Dawarich** — location history. Not reproducible.
6. **`/mnt/fast/stacks-private/neocortex-platform`** — 236 MB of code in a separate repo, on ext4,
   with no dataset. **I did not verify it has a git remote. That is the first thing to check.**
7. **Grafana + Prometheus** — dashboards, alert rules, and all metric history.
8. **RustDesk server keypair** — re-keys every client.
9. **Termix** — SSH host and credential store.
10. **Trek** — uploads.

And the tier below, which survives an LXC rebuild but has **no off-box copy and no snapshot**:
Jellyfin's `jellyfin.db` (363 MB) and its 13 GB config tree, all arr databases (4.8 GB), Authelia's
user/2FA store and the Traefik secrets, open-webui's chat history, the neocortex memory DB,
CouchDB, and podsync's 143 GB of downloads.

**The shortest path to fixing most of this**: `zfs snapshot -r fast/appdata` costs nothing and
would immediately give the ~165 GB of ZFS-resident app state a rollback point. It does **not** help
the 🔴 tier, because that data is not on `fast` at all.

---

## 6. Media stack

### 6.1 Topology (verified live)

```
HDHomeRun 172.16.1.161 ─┐
IPTV provider streams   ─┴─> dispatcharr  ──┬─> Jellyfin (HDHR tuner + XMLTV)
   (iot_macvlan 172.16.1.75, :9191)         ├─> TiviMate @ Fosse Road (Xtream Codes, over Tailscale)
                                            └─> /data/recordings ─> tank/media/Recordings (233 G quota)
                                                                        │
                                                          Jellyfin /recordings (ro) ─> "TV Recordings" library

  jellyfin  (iot_macvlan 172.16.1.76:8096  +  t3_proxy)
     ├─ /media      <- /mnt/tank/media            **rw — the ONLY rw holder on the library (D-21)**
     ├─ /config     <- /mnt/fast/appdata/media/jellyfin   (13 G, jellyfin.db 363 MB)
     ├─ /cache/transcodes <- /mnt/fast/transcode  (ZFS, 50 G quota)
     └─ /recordings <- /mnt/tank/media/Recordings (ro)

  arrs (t3_proxy only, no macvlan):
     sonarr  -> /mnt/tank/media/TV      rw      sabnzbd, qbittorrent -> /mnt/tank/downloads rw
     radarr  -> /mnt/tank/media/Movies  rw      prowlarr -> indexers
     bazarr  -> Movies + TV             rw      beets-flask -> /downloads rw, /media **ro**
     lidarr  -> /mnt/tank/media         **ro**  (reads like a writer, is not)
     janitorr-> Movies + TV             rw      (Jellyfin integration DISABLED)
```

### 6.2 What consumes Jellyfin's API

| Consumer | How it connects | Credential | Verified from |
|---|---|---|---|
| **`seerr`** (`requests.deercrest.info`) | `jellyfin: {port: 443, useSsl: true}` — i.e. **out through Cloudflare/Traefik and back**, not `http://jellyfin:8096` | An **admin-equivalent Jellyfin API key** | `/mnt/fast/appdata/media/seerr/config/settings.json`. Holds `serverId cb29670e…` and two library IDs (Movies `f137a2dd…`, Shows `a656b907…`). Also holds **Sonarr and Radarr API keys**, also over `:443/ssl` |
| **`jellystat`** (`jellystats.deercrest.info`) | `https://jellyfin.deercrest.info`, user `sysadmin` | API key stored in its own Postgres `app_config` row | `jfstat.app_config`. Syncs on a 60 min partial / 1440 min full schedule |
| **`wizarr`** (`invite.deercrest.info`) | `media_server` row 1 = `('Jellyfin ', 'jellyfin', 'https://jellyfin.deercrest.info')` — **also over the public hostname** | stored in `database.db` (14.8 MB) | queried live; `sqlite_master` also shows `invitation_server`, `library`, `user`, `activity_session`, `historical_import_job` |
| **`janitorr`** | `http://jellyfin:8096` — **`enabled: false`, empty api-key** | none | `/mnt/fast/appdata/media/janitorr/application.yml` |
| **`dispatcharr`** | Jellyfin is the *client* here, not the server — Jellyfin pulls `172.16.1.75:9191/hdhr` and `/output/epg` | — | `MEDIA.md` § 5, macvlan addresses confirmed |
| **`immich_kiosk`** | points at **Immich**, not Jellyfin (`KIOSK_IMMICH_URL=http://immich_server:2283`) | — | env |

### 6.3 What holds watch history and users — the answer that matters for a replacement

| Data | Where it lives | Size | Portable? |
|---|---|---|---|
| **Users, passwords, per-user library access, resume positions, played state, favourites, collections, playlists, display preferences** | **`/mnt/fast/appdata/media/jellyfin/data/jellyfin.db`** (SQLite) | **363 MB** | Jellyfin-internal schema. **No exporter is installed.** This is the hard part of any migration |
| **Playback *reporting*** (duration, device, client) | `playback_reporting.db` (160 KB) — the Playback Reporting plugin | small | The plugin has a CSV export |
| **An independent, already-external copy of playback history** | **`jellystat-db` → `jfstat.jf_playback_activity` (311 rows), `jf_users` (5), `jf_library_items` (2863)** | 94 MB | ✅ **Plain Postgres.** This is the one piece of watch history that is *already* out of Jellyfin and queryable. It is a partial record (Jellystat only sees what it has synced since install), but it is the natural bridge for any replacement |
| **Invitations / onboarding** | `wizarr` SQLite (14.8 MB) — `invitation`, `invitation_user`, `expired_user`, `audit_log`, `historical_import_job` | 14.8 MB | Wizarr already abstracts "media server" behind a `media_server` table, so it can likely be repointed rather than replaced |
| **Requests** | `seerr` SQLite | ~4 MB | Seerr supports Jellyfin, Emby and Plex |
| **Intro/credit timestamps** | `introskipper-cache.db` **855 MB** + `introskipper.db` 14 MB | 869 MB | Regenerable but expensive (it is fingerprint data over the whole library) |
| **Collections/artwork/metadata sidecars** | 201 collection folders under `…/jellyfin/data/collections`; `.nfo` in the library tree | — | `SaveLocalMetadata` is **off for Music permanently**, on for Movies/TV — so Movies/TV carry `.nfo` in-tree and Music does not |

### 6.4 Constraints any Jellyfin replacement inherits

1. **The macvlan address is the exposure.** `172.16.1.76:8096` is reachable from the whole LAN and,
   via the two subnet routers, the tailnet. `ports:` is inert under macvlan, and LXC 100 **cannot
   reach its own macvlan container** (host isolation). Any replacement either takes the macvlan IP
   or changes how every LAN client (TVs, Chromecasts) reaches it.
2. **Hardware transcoding must stay off.** `HardwareAccelerationType: none` is the **D-30 amdgpu
   mitigation** after a ~6 h outage on 2026-08-31. `/dev/dri` is mapped and the Radeon 890M is
   capable; Jellyfin deliberately does not use it. The failure mode is a kernel oops whose blast
   radius includes **Traefik and every `*.deercrest.info` service**, because `dockerd` reads
   `/proc/*/smaps`. A replacement that enables VAAPI by default re-arms this.
3. **The 50 G `fast/transcode` quota only binds if the replacement's temp path points at it.**
   Five settings are asserted by `check-jellyfin-transcode.sh`; `TranscodingTempPath` is the
   load-bearing one. A replacement bypasses all five assertions.
4. **Jellyfin is the sole RW holder on `/mnt/tank/media`** (D-21) and the Music library's write path
   is frozen at the *application* layer, not the mount. A replacement with different defaults can
   rewrite `.nfo` across the library on its first scan — as an explicit `FullRefresh` was measured
   to do to 83 of 91 files.
5. **Dispatcharr is the single tuner source** and is decoupled from Jellyfin — it serves HDHR +
   XMLTV over HTTP, so it survives a Jellyfin swap unchanged. TiviMate does not touch Jellyfin at
   all. The DVR writes MKV to `tank/media/Recordings` independently.
6. **Four services hold Jellyfin API keys** (seerr, jellystat, wizarr, and janitorr's disabled
   stub) and **three of them connect over the public hostname on :443** — so the migration also
   touches Cloudflare/Traefik, not just an internal endpoint swap.
7. **`jellyfin` is 3 GiB-limited and running at 988 MiB.** A replacement inherits a host with
   3.5 GiB available.

---

## 7. Ranked recommendations

These follow from the measurements above; they are not the deliverable, but they are what the
deliverable implies.

**Do first — cheap, high-consequence, no design decisions:**

1. `docker image prune -a` on LXC 100 — **60.9 GB** reclaimed on a filesystem with 20.6 GB free.
2. `zfs snapshot -r fast/appdata` on atlantis — gives ~165 GB of unbacked-up app state a rollback
   point, at zero cost, today.
3. Resolve the names in § 1.5's first bullet (`ollama.`, `mcp.`, `docling.`) against Cloudflare and
   confirm they do not resolve publicly.
4. Confirm `/mnt/fast/stacks-private/neocortex-platform` has a git remote.
5. Schedule `backup-incremental.sh` — it exists, it works, **nothing runs it**.

**Do next — reduces the LOST tier:**

6. Move the 🔴 state (§ 5.3) off the LXC ext4 root. Each needs a ZFS dataset **and** a matching
   `mp` entry in `pct config 100`, which is a Terraform change — and `CLAUDE.md` warns that
   bind-mount edits plan clean and do nothing under the current `ignore_changes` guard. Order by
   irreplaceability: paperless, n8n-postgres, teleport, teslamate, dawarich.
7. Extend the backup script to cover `fast/appdata` (169 GB; the `backup` pool has 11 TB free).
8. Destroy `fast/ix-apps` (238 GB) and `fast/.system` (2 GB) — both `mounted=no`, both TrueNAS-era.
9. Move or quota **podsync's 143 GB** of downloads. It is a re-downloadable media cache occupying
   99.9 % of the `hoarder` dataset on the SSD pool, with no bound. Rotate `authelia.log` (528 MB).

**Then — the consolidation this map was drawn for:**

10. One PG 18 instance replacing nine (793 MB of data across nine postmasters).
11. One Redis replacing six, with a volume bound and per-consumer DB indices.
12. One Tika replacing two.
13. Decide `postiz` vs `social` — they declare the same three container names and cannot coexist.
14. Decide whether `open-archiver` returns; if not, its 67 MB, its second Meilisearch and its third
    Tika all go away.
15. Put `mem_limit` on the 76 unlimited containers, and fix the two (`janitorr`, `paperless`) whose
    declared limits are not applied to the running container.

---

*Every figure in this document was measured on 2026-09-25 against LXC 100 (172.16.1.159) or
atlantis (172.16.1.158), or read from this repository at commit `3798ed1`. Items I could not verify
are marked as such rather than inferred.*
