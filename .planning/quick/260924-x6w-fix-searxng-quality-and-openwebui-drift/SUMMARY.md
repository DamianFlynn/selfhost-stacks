---
quick_id: 260924-x6w
slug: fix-searxng-quality-and-openwebui-drift
date: 2026-09-25
status: complete
---

# Summary — SearXNG result quality, Open WebUI search + RAG, openwebui stack drift

## Outcome

Search works. The reported "shocking bad results" had **five** independent causes, not the
one that was suspected, and two of them meant Open WebUI's web search and RAG embedding
were returning *nothing at all* rather than returning something poor.

Measured before: 0 results through the Open WebUI path (HTTP 403), 2 web engines live,
DuckDuckGo/Brave/Startpage all CAPTCHA'd or 429'd.
Measured after: **41–43 results** through the Open WebUI path from **4 engines**, zero
blocking failures across 25 consecutive probe queries.

## What was actually wrong

| # | Fault | Evidence |
|---|---|---|
| F1 | DuckDuckGo CAPTCHA, Brave 429, Startpage CAPTCHA, Yahoo disconnect | container logs |
| F2 | Image 3 months / ~90 releases stale, predating the curl_cffi TLS-impersonation migration | `httpx.RemoteProtocolError` in logs proves pre-migration |
| F3 | `settings.yml` was a frozen 70 KB full copy overriding the image | its `suspended_times` were the pre-Feb-2026 defaults |
| F4 | `formats: [html]` → Open WebUI's JSON API got **403**; all chat web search returned nothing | direct request, internal and external |
| F5 | `RAG_ENBEDDING_MODEL` typo **and** no embedding model on the box at all | `ollama list` had only `qwen2.5:3b` |
| F6 | Renovate had never raised a PR for searxng — calver+hash tag unparseable | no rule, no PR history |
| F7 | open-webui/ollama/docling drifted from git | `docker inspect` vs git |

**F2 was the primary cause and F3 was why fixing it alone would not have worked.**

## The finding that changed the fix

The plan was to retire the blocked engines and replace them with independent ones. After
upgrading the image I probed the candidates instead of trusting the research, and the
result inverted the plan:

```
brave   5/5  (~24 results)   <- was HTTP 429, benched 3600s
google  5/5  (10 results)
bing    5/5  (10 results)
yahoo   5/5  ( 7 results)    <- was RemoteProtocolError
duckduckgo  FAILED, CAPTCHA  <- the only one that did NOT recover
```

The 2026-09-04 curl_cffi migration added browser TLS/JA3 impersonation and **fixed the
blocking by itself**. Brave went from benched-for-an-hour to the strongest engine in the
set. So brave/google/bing were *enabled*, not replaced.

Two traps caught the first draft of the config, both of which fail **silently**:

- **`inactive: true` is not `disabled: true`.** An inactive engine is never loaded, so
  `disabled: false` against it does nothing and the engine just never appears. mojeek,
  startpage, findborg, dogpile and marginalia are all inactive in this image — the first
  config "enabled" four engines that could not run. mojeek/startpage are inactive because
  they now demand a proof-of-work CAPTCHA; marginalia needs an API key.
- **Naming an engine in `&engines=` does not prove it ran.** SearXNG falls back to the
  default set, so an unrunnable engine returns a full, plausible result list. The first
  probe read as four healthy engines returning ~25 results each; they were all the same
  fallback. Verdicts must be read from each result's own `engines` field.

## Verification (all pass)

| Check | Result |
|---|---|
| internal `?format=json` (the Open WebUI path) | **200**, 41 results, 4 engines |
| external `GET ?format=json` | **403** |
| external `POST /search` | **403** |
| external `GET /search?q=` | **200**, 36 result articles, on-topic |
| `ollama list` contains `nomic-embed-text` | pass |
| image tags git vs `docker inspect` ×4 | all match |
| engine errors since restart | none except upstream wikidata 502 |

**A hole in my own fix was found by this pass and closed.** The first Traefik rule matched
`format=json` in the query string; Traefik cannot read a request body, and SearXNG's
default `method: POST` puts the parameter there. `POST /search?format=json` measured
**200** — a complete bypass. Fixed with `server.method: GET` plus a second router denying
external `POST /search`. Both halves are required.

## Not verified — needs a human

**V7, an actual web search in the Open WebUI chat UI, was not tested end-to-end.** That
path needs an authenticated session token. Everything underneath it is proven — Open WebUI
reaches SearXNG internally and gets 41 results, the embedding model is present, and the
env is correct — but the last hop is inference, not measurement. Worth one search in the
UI to confirm.

## Unrelated findings, surfaced not fixed

1. **Uncommitted work was live on the host.** `/mnt/fast/stacks` had a 19-line
   modification to `neocortex-memory/compose.yaml` adding a tsbridge tailnet route
   (TODO-317), applied to production and never committed. It blocked `git pull`. It was
   preserved — patch saved to `/mnt/fast/host-uncommitted-neocortex-tsbridge-20260925.patch`,
   stashed, restored, and verified byte-identical against the patch. **It is still
   uncommitted and still only on the host.** This is the estate's documented drift
   problem running in the opposite direction and it will block the next deploy too.
2. **`open-archiver` is not running at all** — no containers. Its Meilisearch pin is moot.
3. **karakeep Meilisearch drift** — git `v1.53.2`, host `v1.53.1`, latest `v1.54.0`.
   Deferred to its own pass by decision; needs the `--upgrade-db` one-off.
4. **Open WebUI MCP tool server error**, pre-existing and unrelated: it cannot fetch
   `http://ai-openwebui-mcp:8000/postgress/openapi.json`.
5. `wikidata` returns upstream 502s from `query.wikidata.org/sparql`. Transient and not
   ours; left on defaults deliberately.

## Decisions recorded

- **No backup** was taken before the Open WebUI v0.9.6 → v0.11.4 schema migration. The
  user was told it is not reversible by downgrading and declined. The upgrade completed
  cleanly, but this was an accepted, unhedged risk.
- Meilisearch deferred; `karakeep` and `open-archiver` untouched.
- Public HTML retained, JSON blocked at the edge rather than dropping the public router.

## Commits

| Commit | Scope |
|---|---|
| `1569121` | compose: image bumps, env fixes, cache volume, JSON block, logging |
| `9d1518e` | renovate: searxng regex versioning + weekly schedule |
| `08e7ce3` | searxng: frozen 70 KB copy → delta file |
| `3e6d81a` | searxng: engine set corrected from measurement; POST bypass closed |
