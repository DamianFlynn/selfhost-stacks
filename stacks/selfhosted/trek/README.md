# TREK: trip planning

Self-hosted travel and trip planner — day-by-day itineraries, interactive maps, budgets, packing
lists, documents and photo uploads, shared between household members in real time. NestJS 11 +
React 19 in a single container, persisted to SQLite. Installable on a phone as a PWA.

Upstream: [`liketrek/TREK`](https://github.com/liketrek/TREK). Deployed 2026-09-06.

## Request path

```
Browser
  → Cloudflare        proxied CNAME  trek.deercrest.info → deercrest.info (orange cloud)
  → Traefik           websecure, TLS via the dns-cloudflare DNS-01 resolver
  → chain-authelia@file
  → trek:3000         t3_proxy network
```

**No host port is published.** `cal-web` (keeper-sh) already owns `127.0.0.1:3000`, and everything
in this estate routes through Traefik anyway. TREK is reachable only through the proxy.

There is **no wildcard DNS record** on `deercrest.info` — `trek.deercrest.info` is its own record.
A Traefik certificate is not evidence that DNS resolves; the two are independent.

## Sharp edge 1 — the image is not where the source is

```yaml
image: mauriceboe/trek:4.2.0        # Docker Hub
```

The GitHub repository is `liketrek/TREK`, but **`ghcr.io/liketrek/trek` does not exist** — it
returns 401/DENIED. Upstream publishes to `mauriceboe/trek` on Docker Hub instead. This is not
obvious from the repo name and will silently fail at `docker pull`, not at review time.

Same-project confirmation, in case the mismatch looks like a typosquat: Docker Hub `4.2.0` was
pushed `2026-09-03T14:28:04Z`; the GitHub `v4.2.0` tag landed 33 seconds later at `14:28:37Z`.

Verify any tag before writing it into compose:

```bash
docker manifest inspect mauriceboe/trek:<tag> >/dev/null && echo exists
```

## Sharp edge 2 — Authelia is not protecting the API

TREK sits behind `chain-authelia@file`, which reads as "protected". For the browsing UI it is.
**For the API it is not.**

Authelia's `access_control` is **first-match-wins**, and this rule sits near the top:

```yaml
- domain: "*.deercrest.info"
  policy: bypass
  resources:
    - "^/api/.*$"          # ← every host, every /api path
```

TREK is a NestJS app; its entire API — including `/api/auth/login` — is under `/api`. Those
requests never reach the `one_factor` catch-all further down. **TREK's own authentication (JWT,
OIDC, WebAuthn passkeys, TOTP MFA) is the real security boundary here**, not Authelia.

This is deliberate, not an oversight. TeslaMate *was* given a host-specific rule above the bypass,
because it has no authentication of its own. TREK was **not**, because forcing Authelia onto
`/api/*` hands the front-end an HTML login page where it expects JSON, breaking the PWA and the
WebSocket handshake. The trade is: TREK keeps working, and its own account security has to be real.

The practical consequence is in the next section.

## Sharp edge 3 — the first-run admin password is in the log forever

With `ADMIN_EMAIL` / `ADMIN_PASSWORD` unset, TREK seeds an admin on first boot and prints the
generated password to stdout:

```
║  TREK — First Run: Admin Account Created     ║
║  Email:    admin@trek.local                  ║
║  Password: <random>                          ║
```

Retrieve it with `docker logs trek 2>&1 | grep -A3 'First Run'`.

**Change it at first login** (Settings → Account), and move the address off the placeholder
`admin@trek.local` so password reset can actually deliver. That log line is not redacted, does not
expire, and is readable by anyone with docker access on LXC 100 — and per sharp edge 2, this
password is the only thing between the seeded admin account and the internet.

Setting `ADMIN_EMAIL` and `ADMIN_PASSWORD` in `.env` suppresses the random seed, which is the
better choice if the deployment ever needs to be reproducible from scratch.

## Sharp edge 4 — ENCRYPTION_KEY is not recoverable

`ENCRYPTION_KEY` wraps TREK's stored secrets at rest. **If it is lost or changed, everything it
wrapped is permanently unreadable** — a volume restore without the matching key yields an unusable
install. Back it up *with* the volumes, not separately.

Leaving it unset is worse than it looks: TREK generates one on first boot that then exists only
inside `trek_data`, so the key and the data it protects share a single failure.

Deer Crest: the live value is backed up in `~/.claude/secrets/trek.env`.

## Storage

| Volume | Mount | Holds |
|---|---|---|
| `trek_data` | `/app/data` | SQLite database, generated `.jwt_secret`, logs |
| `trek_uploads` | `/app/uploads` | User uploads — trip documents and photos |

Named volumes rather than the `/mnt/fast/appdata` bind used by older stacks. That bind buys nothing
here: **`/mnt/fast/appdata` is not a mountpoint** (only its children are ZFS datasets — see
[MEDIA.md § 3](../../../MEDIA.md)), so both land on LXC 100's **126 G ext4 root** regardless. The
named volume at least keeps runtime data out of the git working tree at `/mnt/fast/stacks`.

Both are small today. `trek_uploads` is the one to watch — photo uploads grow without a quota, on
a root filesystem with no dataset behind it.

## The WebSocket

The UI opens a WebSocket to `/ws` for live collaboration. Traefik performs the HTTP/1.1 Upgrade
natively and needs no extra label — but **do not add compression, buffering, or a Retry or
CircuitBreaker middleware to `trek-rtr`**. Any of them breaks the upgrade, and the failure is
quiet: the page loads and simply stops updating.

`TRUST_PROXY=1` and `FORCE_HTTPS=true` are required because Traefik terminates TLS — without them
TREK will not issue secure cookies. `HSTS_INCLUDE_SUBDOMAINS=false` is deliberate: not every
sibling `*.deercrest.info` host is HTTPS-only yet, and the inherited header would break them.

## Outbound e-mail

SMTP is configured and live — a Gmail relay on `smtp.gmail.com:587` (STARTTLS), used for invite,
reminder and password-reset mail. The sender is set via `SMTP_FROM`; the account and its app
password live in the host `.env` only.

`APP_URL=https://trek.deercrest.info` is set so links in that mail resolve. Without it TREK falls
back to the first `ALLOWED_ORIGINS` entry.

Gmail as a relay requires an **app password**, not the account password, and will silently stop if
2FA settings change on the Google account.

## Container hardening

Upstream's own posture, kept as-is: `read_only: true` with `/tmp` as a 128 M `noexec,nosuid` tmpfs
for scratch, `cap_drop: ALL` with only `CHOWN`/`SETUID`/`SETGID` added back, and
`no-new-privileges:true`. `mem_limit: 1g` against ~250 MB steady state — the cap bounds a runaway,
it is not a target.

Health check is `wget -qO- http://localhost:3000/api/health`, which runs inside the container and
so is unaffected by anything in the Traefik or Authelia path.

## Operating notes

Deploy — `mem_limit` and env changes need a **recreate**, not a restart:

```bash
ssh root@172.16.1.159
cd /mnt/fast/stacks && git pull
docker compose -f stacks/selfhosted/trek/compose.yaml up -d
```

`.env` is required — the stack will not start without one. It is gitignored (`**/.env`); only
`.env.sample` is committed. Secrets are backed up to `~/.claude/secrets/trek.env`.

## Known gaps

- **Renovate deploy drift applies.** The image is pinned, which is correct, but a merged Renovate
  PR never touches the host — the running container only changes on an explicit `pull` + recreate.
  `docker ps` is the source of truth for what is deployed, not git.
- **The Authelia config governing sharp edge 2 is not in git.** It lives only at
  `/mnt/fast/appdata/traefik/authelia/configuration.yml` on LXC 100. The `/api` bypass that
  determines TREK's real security posture is therefore unreviewable in a PR and would not survive a
  rebuild from this repository.
- **Registration and invite policy has not been reviewed.** TREK supports invite links and open
  registration; which is in force here has not been checked. Given sharp edge 2, this is worth
  confirming rather than assuming.
- **No backup of the SQLite database.** `trek_data` is not covered by any snapshot or backup job
  documented in this repo.
