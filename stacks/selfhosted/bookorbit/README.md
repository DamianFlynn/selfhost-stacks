# BookOrbit

Self-hosted ebook and audiobook reader at **https://books.deercrest.info**. Upstream:
https://github.com/bookorbit/bookorbit (AGPL). Pinned to `ghcr.io/bookorbit/bookorbit:3.5.0`
with `pgvector/pgvector:0.8.7-pg18` for Postgres.

Replaces Booklore (retired 2026-10-22, 261022-wp7). Booklore was defined in `books/` but never
ran on the host.

## Request path

```
iPhone/Watch app, KOReader, Kobo, OPDS reader, browser
  -> Cloudflare (orange-cloud CNAME books -> deercrest.info)
  -> Traefik websecure, router bookorbit-rtr, middleware chain-no-auth@file
  -> bookorbit-app:3000 (t3_proxy)
  -> bookorbit-db:5432 (private bookorbit bridge)
```

No host port is published. The image's own HEALTHCHECK polls `/api/v1/health`.

## Auth design: the whole host is on BookOrbit's own login

There is one router and it carries **no forward-auth**. This is deliberate:

- Every native-client path is under `/api/`: the iOS/Watch app (`/api/v1/*`, including the
  public `/api/v1/server-identity`), KOReader (`/api/v1/koreader/*`), Kobo
  (`/api/kobo/<deviceToken>/v1/*`), OPDS (`/api/v1/opds`) and audiobook streaming
  (`/api/v1/audiobooks/:id/assets/:asset/content`). A bypass that lets the clients through
  already exposes all of the application logic.
- Forward-auth on what is left would guard only the static SPA bundle and the `/socket.io/`
  handshake, and BookOrbit authenticates its sockets itself.
- Authelia's forward-auth is a browser cookie. Native apps never carry it, so they would be sent
  to a login page. It would also mean a second login, and an Authelia account for Breege.
- The router does not rely on the estate-wide `^/api` Authelia bypass, which is flagged for
  repair (it matches any path starting `/ap`).

Compensating controls:

| Control | How it is enforced |
|---|---|
| One-time setup | `POST /api/v1/auth/setup` needs `x-setup-token` = `SETUP_BOOTSTRAP_TOKEN` (64 hex) and answers 409 once an admin exists |
| Registration closed | `POST /api/v1/auth/register` answers 403 "Registration is not open" |
| Swagger off | `SWAGGER_ENABLED` is unset, so `/api/v1/docs` is not served |
| OPDS off | left disabled until the operator opts in (admin settings) |
| Login throttle | upstream: login 5/min, register and setup 3/min |
| Edge | Cloudflare proxying; the origin IP is not published |

The login throttle is keyed on the client address as Traefik forwards it. If that ever collapses
to the proxy address, the worst case is a one-minute shared lockout.

Not used: the `rate-limit` middleware (50 requests per 60 s starves an SPA) and any buffering
middleware.

**Authelia OIDC** is supported upstream and is optional. It is not configured. Keep
`DISABLE_LOCAL_AUTH=false` until it exists, or nobody can log in.

**Cloudflare: orange cloud.** The 100 MB cap applies to request bodies only, BookOrbit uploads in
16 MiB chunks, and downloads and streams are not capped. Re-evaluate only on a 413 or 499.

## Client URLs

| Client | URL |
|---|---|
| iOS / Watch app | server `https://books.deercrest.info` |
| KOReader progress sync | `https://books.deercrest.info/api/v1/koreader` |
| Kobo | the device URL shown in BookOrbit's UI (under `/api/kobo/<token>/`) |
| OPDS | `https://books.deercrest.info/api/v1/opds` (disabled until enabled) |

## State and backups

| Dataset | LXC mp | recordsize | Bound at |
|---|---|---|---|
| `fast/appdata/bookorbit` | mp37 | 128K | `data/` -> `/data` (covers, book-bucket, uploads) |
| `fast/appdata/bookorbit/postgres` | mp38 | 16K | `/var/lib/postgresql` (PGDATA `18/docker`) |

No named volumes and nothing on LXC 100's rootfs. Both datasets are in `infra/lxc-selfhost.tf`
and are sent nightly to `backup/appdata/bookorbit{,/postgres}`. There is no quota on the Postgres
dataset: ENOSPC on the WAL is a Postgres PANIC.

Secrets live in `.env` on the host (mode 600, gitignored). The admin and user passwords live on
the workstation in `~/.claude/secrets/bookorbit.env` (mode 600).

## The library

`/mnt/tank/media/Books` (LXC mp23) is shared:

- Audiobookshelf reads it **rw** at `/audiobooks`;
- Readarr (Bookshelf, hardcover flavour) writes it **rw** at `/media/Books`;
- BookOrbit reads it **ro** at `/books` (proven: a write inside the container fails).

Layout is author/title, audio and ebooks side by side. Every entry is owned `568:568` since
2026-10-22.

## Sharp edges

- **Forward-only migrations.** Every start runs `migrate.js`. Take a `pg_dump` before any image
  bump; there is no down-migration. Renovate marks BookOrbit bumps manual-review.
- **Book Dock is unset** while the library is `:ro`. To use it, make the mount rw and set
  `BOOK_DOCK_PATH` in the same change.
- **`J.K. Rowling/` is flat:** the audiobook mp3s sit directly in the author folder (plus one
  nested `J.K. Rowling/` folder), so scanners see it as one item. Restructuring it was out of
  scope for 261022-wp7.
- **No SMTP.** Invites and password-reset e-mails cannot be sent; the admin sets passwords.
- **pg18 layout.** Postgres is bound at `/var/lib/postgresql`, not upstream's
  `/var/lib/postgresql/data`, so the image's declared VOLUME never lands on rootfs.
