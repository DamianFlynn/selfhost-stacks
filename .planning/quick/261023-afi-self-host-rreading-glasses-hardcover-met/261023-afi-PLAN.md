---
phase: quick-261023-afi
plan: 01
type: execute
wave: 1
depends_on: [quick-261022-wp7]
files_modified:
  - stacks/selfhosted/arrs/rreading-glasses.yaml        # new
  - stacks/selfhosted/arrs/compose.yaml
  - stacks/selfhosted/arrs/.env.sample                  # new (arrs had none)
  - renovate.json5
  - README.md                                           # Task 2
  - MEDIA.md                                            # Task 2
autonomous: false   # Task 2 is gated on the operator putting HARDCOVER_AUTH into arrs/.env
requirements: [QUICK-261023-afi]

must_haves:
  truths:
    - "rreading-glasses is pinned by DIGEST (blampe/rreading-glasses:hardcover publishes no version tags) with a `# renovate:` comment, and Renovate will not automerge its digest bumps"
    - "Neither new service publishes a host port or carries Traefik labels. The DB is reachable only from rreading-glasses (private internal network); rreading-glasses shares t3_proxy with readarr"
    - "rreading-glasses-db (postgres:18-alpine) is bound at /var/lib/postgresql (PG18 layout), host path /mnt/fast/appdata/arrs/rreading-glasses/postgres on the fast/appdata/arrs ZFS dataset; no named volume; stat -f inside the container prints 2fc12fc1"
    - "RREADING_GLASSES_DB_PASSWORD is generated on the host, never printed, never in argv; HARDCOVER_AUTH is added only by the operator"
    - "`docker compose config -q` on the host for arrs passes; check-music-freeze DECLARED_INTERP_EXPECTED stays 8 (literal host paths only)"
    - "(Task 2) Bookshelf metadataSource = http://rreading-glasses:8788 and an author lookup returns results through it"
---

<objective>
Self-host the rreading-glasses Hardcover metadata service so Bookshelf (container `readarr`,
`ghcr.io/pennydreadful/bookshelf:hardcover-v0.4.21.182`) stops depending on the overloaded hosted
`https://hardcover.bookinfo.pro` (429s / timeouts). Task 1 lands the definition, secret and an
empty initialised DB. Task 2 starts the service once the operator has supplied a Hardcover token.
</objective>

<context>
- Upstream: https://github.com/blampe/rreading-glasses — `docker-compose-hardcover.yml`, README
  ("Postgres (any version)"; "the app will use as much memory as it has available ... run the
  container with a --memory limit"). Image is `gcr.io/distroless/static:nonroot` — no shell, so
  no in-container healthcheck is possible. Routes (internal/handler.go): `/author/{id}`,
  `/book/{id}`, `/work/{id}`, `/search`, `/debug/metrics`, `/` (swagger UI).
- Memory: `cmd/root.go` sets the Go memory limit to 90% of what is available and
  `internal/memory.go` gives the ristretto LRU 50% of that. The in-memory tier is only the hot
  layer over Postgres, which is the durable cache. 512m (upstream example 128m) bounds it to
  roughly 230 MB of hot cache — enough for a single-user library — without letting a cache
  grow into LXC 100's limited headroom.
- readarr is on `t3_proxy` only. Bookshelf's current `metadataSource`
  (GET /api/v1/config/development) is `https://hardcover.bookinfo.pro`.
- PG18 mount trap: bind at /var/lib/postgresql, never /var/lib/postgresql/data (see silo).
- `/mnt/fast/appdata/arrs` is ZFS `fast/appdata/arrs` (findmnt, 2026-10-23).
</context>

<tasks>

<task type="auto">
  <name>Task 1: Define rreading-glasses + DB, secret on host, lint, DB-only start, push</name>
  <files>stacks/selfhosted/arrs/rreading-glasses.yaml, stacks/selfhosted/arrs/compose.yaml, stacks/selfhosted/arrs/.env.sample, renovate.json5</files>
  <action>
    1. New `arrs/rreading-glasses.yaml`: `rreading-glasses` (digest-pinned, entrypoint
       ["/main","serve"], mem_limit 512m, no-new-privileges, unless-stopped, networks t3_proxy +
       rreading-glasses, depends_on db service_healthy, env HARDCOVER_AUTH + POSTGRES_*) and
       `rreading-glasses-db` (postgres:18-alpine, internal network only, pg_isready healthcheck,
       literal bind /mnt/fast/appdata/arrs/rreading-glasses/postgres:/var/lib/postgresql).
       Include it from arrs/compose.yaml after readarr.yaml.
    2. arrs/.env.sample (names + placeholders only; repo is public).
    3. renovate.json5: rule excluding blampe/rreading-glasses from automerge (digest bumps of an
       untagged image are unreviewable otherwise). check-drift already never deploys a
       digest-pinned mismatch.
    4. Host: mkdir the DB dir root:root 0755 (silo-db precedent; the PG18 entrypoint creates and
       chowns 18/docker itself); append RREADING_GLASSES_DB_PASSWORD generated on the host,
       never echoed, skip if present.
    5. Commit, pull --rebase --autostash, push, CI green, `git pull --ff-only` on host;
       `docker compose config -q`; `up -d rreading-glasses-db` ONLY; prove healthy + ZFS magic.
  </action>
  <verify>compose config -q exit 0; db healthy; `stat -f -c %t /var/lib/postgresql` = 2fc12fc1; no Type=volume mount; DECLARED_INTERP_EXPECTED unchanged at 8.</verify>
  <done>Definition on main and on the host; DB initialised and healthy; app container NOT created.</done>
</task>

<task type="checkpoint:human-action" gate="blocking">
  <name>Task 2: Start rreading-glasses and point Bookshelf at it (after HARDCOVER_AUTH is set)</name>
  <files>README.md, MEDIA.md</files>
  <action>
    Precondition: operator confirms `HARDCOVER_AUTH=Bearer ...` is in arrs/.env (hidden prompt).
    Check presence only: `grep -c '^HARDCOVER_AUTH=Bearer ' .env` = 1.
    1. `docker compose -f stacks/selfhosted/arrs/compose.yaml up -d rreading-glasses`;
       `docker logs rreading-glasses` — no auth / postgres errors.
    2. In-network probe, no host port: `docker run --rm --network t3_proxy curlimages/curl -s -o
       /dev/null -w '%{http_code}' http://rreading-glasses:8788/swagger.json` (200), then
       `.../search?q=John%20Grisham` and `.../author/<id from search>` (200, JSON with works).
    3. Bookshelf: GET /api/v1/config/development (API key via `curl -H @-`, never argv), set
       `metadataSource` to `http://rreading-glasses:8788`, PUT it back to
       /api/v1/config/development/1; re-GET to confirm. Restart not expected to be needed.
    4. GET /api/v1/author/lookup?term=John%20Grisham and ...Alexandra%20Potter — results via the
       new source. Add each (POST /api/v1/author) with rootFolderPath /media/Books, the existing
       quality + metadata profile ids, monitored true, addOptions.monitor "all",
       searchForMissingBooks false; then POST /api/v1/command {name:"AuthorSearch", authorId}.
       Report books found / monitored / grabbed (GET /api/v1/book?authorId=, /api/v1/queue).
       If either author is already present (wp7 added on-disk authors with monitor=none), PUT
       the existing author to monitored + monitor all instead of re-adding.
    5. README / MEDIA.md: one note each — Bookshelf metadata now comes from the self-hosted
       rreading-glasses (arrs stack), why, and the fallback (`https://hardcover.bookinfo.pro`).
  </action>
  <verify>metadataSource reads back http://rreading-glasses:8788; lookups return results; AuthorSearch commands complete.</verify>
  <done>Bookshelf no longer depends on hardcover.bookinfo.pro.</done>
</task>

</tasks>
