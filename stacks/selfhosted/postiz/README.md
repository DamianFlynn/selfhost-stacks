# Postiz

Self-hosted social media scheduling platform. Manages posting across 30+ platforms (X, LinkedIn, Instagram, TikTok, YouTube, Bluesky, Reddit, Mastodon, Discord, and more).

- **UI:** https://social.deercrest.info (Authelia protected)
- **Stack:** `postiz.yaml` (app + postgres + redis)

## MCP Integration

Postiz includes a built-in MCP server — no separate container needed.

**Endpoint:** `https://social.deercrest.info/mcp/<API_KEY>/sse`

The `/mcp` path bypasses Authelia; the API key in the URL is the authentication.

### Getting your API key

Postiz → **Settings → Developers → Public API** → copy the key.

Store it locally:
```bash
# ~/.claude/secrets/postiz.env
POSTIZ_URL=https://social.deercrest.info/public/v1
POSTIZ_API_KEY=<your-key-here>
```

### Register with Claude Code

```bash
claude mcp add --transport sse postiz https://social.deercrest.info/mcp/<API_KEY>/sse
```

## REST API

Base URL (self-hosted): `https://social.deercrest.info/public/v1`

Auth header: `Authorization: <API_KEY>` (no Bearer prefix)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/integrations/status` | Check connectivity |
| GET | `/integrations` | List connected social channels |
| POST | `/posts` | Schedule a post |
| GET | `/posts` | List posts (`?startDate=&endDate=`) |
| DELETE | `/posts/{id}` | Delete a post |
| DELETE | `/posts/group/{id}` | Delete all posts in a group |
| PATCH | `/posts/{id}/status` | Change draft/scheduled state |
| POST | `/uploads/file` | Upload media (max 50 MB) |
| POST | `/uploads/url` | Import media from URL |
| GET | `/analytics/platform/{id}` | Channel analytics |
| GET | `/analytics/posts/{id}` | Per-post analytics |

### Example: list channels

```bash
source ~/.claude/secrets/postiz.env
curl -s -H "Authorization: $POSTIZ_API_KEY" "$POSTIZ_URL/integrations" | jq '.[] | {id, name, type}'
```

### Example: schedule a post

```bash
source ~/.claude/secrets/postiz.env
curl -s -X POST \
  -H "Authorization: $POSTIZ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "schedule",
    "date": "2026-07-01T10:00:00.000Z",
    "shortLink": false,
    "posts": [{
      "integration": { "id": "<INTEGRATION_ID>" },
      "value": [{ "content": "Your post text here" }],
      "settings": { "__type": "x" }
    }]
  }' \
  "$POSTIZ_URL/posts"
```

## Rate limits

Default: 90 requests/hour on POST `/posts` (adjustable via `API_LIMIT` env var).
