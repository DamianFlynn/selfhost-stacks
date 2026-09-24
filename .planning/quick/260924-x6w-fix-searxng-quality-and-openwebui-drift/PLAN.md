---
quick_id: 260924-x6w
slug: fix-searxng-quality-and-openwebui-drift
date: 2026-09-24
status: in-progress
---

# Fix SearXNG result quality, restore Open WebUI web search + RAG embedding, clear openwebui stack drift

## Problem

Reported: "openwebui and searxng are way behind, and searxng is returning shocking bad
results — I think we are getting blocked on DuckDuckGo and other upstream engines."

Confirmed, plus three faults the report did not cover. All measured on
`172.16.1.159` on 2026-09-24, none assumed.

### F1 — Upstream engine blocking is real

From `docker logs ai-searxng`:

```
ERROR:searx.engines.duckduckgo: CAPTCHA (uk-en)
ERROR:searx.engines.brave:      Too many request (suspended_time=3600)
ERROR:searx.engines.startpage:  get_sc_code redirected to /sp/captcha (suspended_time=86400)
ERROR:searx.engines.yahoo:      requests exception ... Server disconnected
```

### F2 — The image pin is the primary cause, not the engine list

Host runs `searxng/searxng:2026.6.23-e3713717f`; latest is `2026.9.23`. SearXNG is
rolling-release with daily builds, so this is ~90 releases of engine fixes behind.

Critically it predates **2026-09-04 `[mod] network: migrate to curl_cffi`**, which moved
outgoing HTTP from `httpx` to `curl_cffi` and added **browser TLS/JA3 impersonation**
(`impersonate`, default `chrome`). That is the standard mitigation for exactly the
CAPTCHA/429 pattern in F1. The `httpx.RemoteProtocolError` on yahoo is itself proof the
instance is pre-migration — current master has no `httpx` dependency at all.

`impersonate` is **not** admin-configurable; it is set per-request in engine code. The
benefit comes from upgrading, not from configuration.

### F3 — settings.yml is a frozen full copy that overrides the image

`/mnt/fast/appdata/llm-ai/searxng/settings.yml` is a verbatim 70,044-byte copy of a
default settings file with **no `use_default_settings:` key**, so it fully replaces
upstream defaults rather than layering on them.

Proof it predates the running image: its `suspended_times` are `86400`/`3600`, the
**pre-2026-02-22** defaults. Current upstream defaults are `3600`/`180`/`180`. The
2026.6.23 image ships the new values, so those numbers can only be coming from this file.

**Consequence: upgrading the image alone will not fix results.** F2 and F3 must be fixed
together or neither works.

### F4 — Open WebUI web search is not degraded, it is dead

`search.formats` is `[html]` only. Verified:

```
GET http://127.0.0.1:8080/search?q=test&format=json  ->  HTTP/1.1 403 Forbidden
GET https://search.deercrest.info/search?q=test&format=json -> 403
```

Open WebUI consumes the JSON API. Every web search in chat has been returning nothing,
independent of engine health.

### F5 — RAG embedding is dead too, for a separate reason

Two compounding bugs:

- `RAG_ENBEDDING_MODEL=nomic-embed-text:latest` in `compose.yaml` is a **typo**
  (`N` where `M` belongs), so it is silently ignored.
- The effective `RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2` is being sent
  to the **Ollama** engine (`RAG_EMBEDDING_ENGINE=ollama`), and `ollama list` returns only
  `qwen2.5:3b` and `qwen2.5:3b-32k`, both 7 months old.

**There is no embedding model on the box at all.**

### F6 — Renovate has never seen SearXNG

No `packageRules` entry matches `searxng/searxng`, and its tag shape
(`2026.6.23-e3713717f`, calver + git hash) is not parseable by Renovate's default `docker`
versioning. No update PR has ever been raised, which is why this rotted for three months
while `ollama` was bumped weekly.

### F7 — Deploy drift on the rest of the stack

The documented Renovate deploy-drift pattern (merged PR never reaches the host):

| Service | git | host | latest |
|---|---|---|---|
| open-webui | v0.11.1 | **v0.9.6** | v0.11.4 |
| ollama | 0.33.2 | **0.32.5** | v0.34.4 |
| docling-serve | v1.31.0 | **v1.25.0** | v1.35.0 |
| searxng | 2026.6.23 | 2026.6.23 | 2026.9.23 |

### F8 — Public JSON API would feed the block loop

`search.deercrest.info` is publicly reachable and `limiter: false`. Enabling `json`
globally turns it into an open, unauthenticated, trivially scriptable search API whose
every request is laundered through this residential WAN IP into Google/Brave/DDG — the
precise feedback loop that produces F1.

The limiter cannot defend it: `searx/botdetection/http_accept.py` rejects any request
whose `Accept` lacks `text/html`, and `http_user_agent.py` blocks Python UAs. **Every JSON
API client is a bot by that definition**, so `limiter: true` would break Open WebUI. There
is no `format=json` exemption.

## Decisions (user, explicit, 2026-09-24)

- **One pass** — searxng + open-webui + ollama + docling together.
- **No backup** before the Open WebUI v0.9.6 → v0.11.4 upgrade. The user was told it
  migrates the Postgres schema and is not reversible by downgrading, and declined a
  `pg_dump` and a ZFS snapshot. Recorded, not re-litigated.
- **Public HTML, JSON blocked externally at Traefik.** `search.deercrest.info` keeps
  serving HTML as a browser search engine; external `format=json` returns 403; Open WebUI
  reaches JSON internally on the Docker network.
- **Meilisearch/karakeep deferred** to a later pass. Do not touch `karakeep` or
  `open-archiver` here.

## Tasks

### T1 — `stacks/selfhosted/openwebui/compose.yaml`

- `searxng` → `searxng/searxng:2026.9.23-3cd69d30e` (pinned; never `:latest`)
- `open-webui` → `v0.11.4`, `ollama` → `0.34.4`, `docling-serve` → `v1.35.0`
- `SEARXNG_REDIS_URL` → `SEARXNG_VALKEY_URL=valkey://ai-redis:6379/1`
  SearXNG migrated Redis→Valkey (PR #4795); `redis.url` is still read but emits a
  DeprecationWarning and `valkey.url` wins. Use the `valkey://` **scheme** — whether
  `valkey.Valkey.from_url()` parses a `redis://` scheme is unverified. The existing
  `ai-redis` server is RESP-compatible and stays.
- Add `/mnt/fast/appdata/llm-ai/searxng-cache:/var/cache/searxng` — currently unmounted,
  so `faviconcache.db` and engine caches are lost on every recreate.
- `SEARXNG_QUERY_URL` → `http://ai-searxng:8080/search?q=<query>` (stop hairpinning out
  through Cloudflare/Traefik and back)
- Fix F5: `RAG_ENBEDDING_MODEL` → `RAG_EMBEDDING_MODEL=nomic-embed-text:latest`
- Raise searxng logging from `max-size 1m` / `max-file 1`. 24 h of history had already
  rotated away during this diagnosis, which is a "could not look" that should not recur.
- Traefik labels: second router matching `Host(...) && Query(format,json)` at higher
  priority, with an `ipallowlist` middleware scoped to TEST-NET-1 so it 403s everything.

### T2 — `renovate.json5`

Add a `packageRules` entry for `searxng/searxng` with an explicit versioning strategy so
it stops rotting silently. **No `allowedVersions` ceiling** — repo convention, per the
retired wrtag `<0.30.0` pin that enforced a broken state for months.

### T3 — host `/mnt/fast/appdata/llm-ai/searxng/settings.yml`

Back up to `settings.yml.bak-20260924` first (file is owned by uid `977`, not `apps`),
then replace with a small `use_default_settings: true` delta file.

Engine changes — **retire** `duckduckgo`, `startpage`, `brave`, `qwant`; **enable**
`duckduckgo web`, `findborg`, `dogpile`, `mojeek`, `marginalia`, `wikipedia`, `wikidata`.

Constraints that must hold:

- Use `disabled: true`, **never** `use_default_settings.engines.remove:` — open upstream
  bug searxng#6336 crashes the service when a base `network:` engine is removed while
  `brave.images`/`videos`/`news` still reference it. Same trap for mojeek/qwant/startpage.
- **Never enable `qwant`** — open upstream bug searxng#6358: it silently returns
  fabricated results when the IP is blocked, which would poison Open WebUI RAG. A wrong
  answer is worse than an error here.
- Do not enable `google` or `bing` — disabled upstream by default, heavy 2026 block churn.
- Keep `limiter: false` (F8) and `public_instance: false` (it enables `link_token`
  botdetection, categorically incompatible with a JSON API consumer).

Engines dropped from consideration because upstream **deleted** them: `presearch`
(removed 2026-07-30), `stract` (2026-03-03), `right dao` (2026-03-12).

### T4 — Deploy and verify

`ollama pull nomic-embed-text` (F5 — not currently on the box), then recreate the stack.

### T5 — Docs + close-out

Update stack README, write SUMMARY.md, hand-edit STATE.md Quick Tasks table.

## Verification — assert, do not report; fail closed; bound remote commands Linux-side

| # | Check | Pass |
|---|---|---|
| V1 | internal `?format=json` | HTTP 200, non-empty `results[]` |
| V2 | external `?format=json` | **403** |
| V3 | external plain search | **200** HTML (browser search still works) |
| V4 | `ollama list` | contains `nomic-embed-text` |
| V5 | `docker inspect` image tags vs git | all four match |
| V6 | `/stats/errors` | no CAPTCHA/429 on the new engine set |
| V7 | Open WebUI chat web search | returns actual results |

V5 uses `docker inspect`, not `docker ps` status text — this estate has a documented case
of `ps` reporting `Up 2 weeks` for a container `inspect` showed as `exited 137`.

## Rollback

- Repo: `git revert` the commits.
- Host settings: `settings.yml.bak-20260924` restores the previous SearXNG config.
- **Open WebUI has no rollback** — the v0.11.4 schema migration is one-way and the user
  declined a backup. Accepted risk, recorded here deliberately.
