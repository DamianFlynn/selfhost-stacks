# Adding Rybbit analytics to a Hugo site

Written for the publishing agent. Everything here is taken from the Rybbit **v2.9.3** docs (sources
at the end). Do not add attributes, settings or endpoints that are not listed here or there.

## 1. What this is

Rybbit is the self-hosted web analytics running at **https://pulse.deercrest.info** (the
`analytics` stack). Each Hugo site gets one tracking script:

```html
<script src="https://pulse.deercrest.info/api/script.js?siteId=<ID>" async></script>
```

Use this URL form, with `siteId` in the query string. Upstream recommends it because script optimizers
rebuild script tags and drop `data-*` attributes, while leaving the URL intact (`script.mdx`). The older
`data-site-id` attribute still works but is not used here.

The **site ID** comes from the Rybbit dashboard: **Add site**, once per Hugo site, then read the ID
from the script snippet it shows. One site ID per Hugo site.

## 2. The partial

Create `layouts/partials/rybbit.html`:

```go-html-template
{{- /* Rybbit analytics. Renders only in production builds and only when a siteId is set. */ -}}
{{- with site.Params.rybbit }}
  {{- if and hugo.IsProduction .siteId }}
<script src="{{ .host | default "https://pulse.deercrest.info" }}/api/script.js?siteId={{ .siteId | urlquery }}" async
  {{- with .tag }} data-tag="{{ . }}"{{ end }}
  {{- with .skipPatterns }} data-skip-patterns="{{ . | jsonify }}"{{ end }}></script>
  {{- end }}
{{- end }}
```

- `hugo.IsProduction` is true for `hugo` builds (environment `production`) and false for `hugo server`
  (environment `development`), so **local previews are never counted**.
- `data-tag` is optional: a label stored on every event from this page, max 256 characters
  (`tagging.mdx`). Emitted only if `tag` is set.
- `data-skip-patterns` is optional: a JSON array of path patterns whose pageviews are not tracked;
  `*` matches within a segment, `**` across segments, `re:` prefixes a regex (`script.mdx`). Emitted
  only if `skipPatterns` is set.

## 3. Site configuration

`hugo.toml`:

```toml
[params.rybbit]
  siteId = ""                              # from Rybbit: Add site -> script snippet
  host = "https://pulse.deercrest.info"
  # tag = "blog"                           # optional, max 256 chars
  # skipPatterns = ["/drafts/**", "/preview/*"]
```

`hugo.yaml` equivalent:

```yaml
params:
  rybbit:
    siteId: ""                             # from Rybbit: Add site -> script snippet
    host: https://pulse.deercrest.info
    # tag: blog
    # skipPatterns: ["/drafts/**", "/preview/*"]
```

Leaving `siteId` empty disables tracking entirely, which is the safe default for a new site.

## 4. Including it in `<head>`

Add one line inside `<head>`:

```go-html-template
{{ partial "rybbit.html" . }}
```

Where it goes depends on the theme. **Check the theme for a head-extension hook first**, before
overriding anything:

- Themes with a hook (PaperMod and many others): create `layouts/partials/extend_head.html` in the
  site (not the theme) and put the line there.
- Otherwise: the site's `layouts/partials/head.html`, or the `<head>` of `layouts/_default/baseof.html`.
  Only override `baseof.html` if there is no hook and no head partial.

## 5. Site settings, not attributes

Outbound-link tracking, Web Vitals, error tracking, SPA navigation, URL parameters and session replay
are **site settings in the Rybbit dashboard**, fetched by the script when it loads (`script.mdx`,
"Site Settings Configuration"). They are not script attributes.

Recommended per site: enable **Outbound Links** and **Web Vitals**; leave **Session Replay** off.

## 6. Custom events

Two upstream-documented ways (`track-events.mdx`), nothing else:

1. Attributes on any clickable element: `data-rybbit-event="<name>"`, plus optional
   `data-rybbit-prop-<key>="<value>"` for properties.
2. JavaScript: `window.rybbit.event(name, props)`.

Example, a call-to-action link:

```html
<a href="/contact/" data-rybbit-event="book_a_call" data-rybbit-prop-location="post-footer">Book a call</a>
```

No other event attributes are supported. Do not invent any.

## 7. UTM convention for social links

Every link posted to LinkedIn or X carries:

```
?utm_source=linkedin&utm_medium=social&utm_campaign=<post-slug>
?utm_source=x&utm_medium=social&utm_campaign=<post-slug>
```

- All lowercase. `<post-slug>` is the Hugo page slug, hyphenated.
- Rybbit filters and breaks down by `utm_source`, `utm_medium`, `utm_campaign` and channel
  (`shared/src/filters.ts`).
- After the first real visit, check the site's **URL Parameters** setting: it must not strip query
  strings in a way that hides the UTMs.

## 8. Verify after deploy

a. Script is public, no login:

```bash
curl -sS -o /dev/null -w '%{http_code} %{content_type}\n' https://pulse.deercrest.info/api/script.js
```

Expect `200` and a JavaScript content type.

b. Open the **production** page, devtools Network tab: `script.js` 200,
   `tracking-config/<id>` 200, and a POST to `/api/track` 200.

c. The visit appears in the dashboard's realtime / overview within a minute.

d. An ad blocker may still block the script. Note it; do not try to work around it.

## 9. Pulling the evidence

- **Dashboard**: the date-range picker plus the **Pages** tab (per-URL sessions and time on page,
  `pages-tab.mdx`), filtered by `utm_source` or channel.
- **Export**: the site sub-header **Export** offers CSV and PDF.
- **Stats API**: `GET /api/sites/<id>/metric?parameter=pathname&start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&time_zone=Europe/Dublin`
  with an organisation or personal API key as `Authorization: Bearer <key>`
  (`api/getting-started.mdx`, `api/overview/metric.mdx`); `GET /api/sites/<id>/export/pdf` returns a
  PDF (`api/sites/export-pdf.mdx`).

**Deployment caveat.** In this deployment every non-tracking `/api` path is behind Authelia, so an
API-key call from outside gets an Authelia redirect, not data. Run API calls on LXC 100 against the
backend container's internal port, with the key read from a root-only file on stdin, never in argv
(CONVENTIONS § 7):

```bash
# On LXC 100. /root/rybbit-api-key is mode 600.
docker exec -i rybbit-backend node -e '
let k = ""; process.stdin.on("data", d => k += d).on("end", async () => {
  const u = "http://127.0.0.1:3001/api/sites/1/metric?parameter=pathname&start_date=2026-11-01&end_date=2026-11-30&time_zone=Europe/Dublin";
  const r = await fetch(u, { headers: { Authorization: "Bearer " + k.trim() } });
  console.log(r.status, await r.text());
});' < /root/rybbit-api-key
```

Weekly email reports need SMTP, which this deployment does not configure.

## 10. Upstream sources (pinned to v2.9.3)

- Script and attributes: https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/docs/content/docs/(docs)/script.mdx
- Custom events: https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/docs/content/docs/(docs)/track-events.mdx
- Tagging: https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/docs/content/docs/(docs)/tagging.mdx
- Pages tab: https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/docs/content/docs/(docs)/feature-guides/pages-tab.mdx
- Stats API: https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/docs/content/docs/api/getting-started.mdx and https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/docs/content/docs/api/overview/metric.mdx
- PDF export API: https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/docs/content/docs/api/sites/export-pdf.mdx
- Filters incl. `utm_*`: https://raw.githubusercontent.com/rybbit-io/rybbit/v2.9.3/shared/src/filters.ts
