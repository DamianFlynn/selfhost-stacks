# neocortex-memory

The memory service for the neocortex platform. One authenticated HTTP API in front of Postgres,
so that no client anywhere holds a database DSN.

- **URL:** `https://cortex.deercrest.info` — private only, DNS-only (grey) A record to `172.16.1.159`
- **Stack:** `stacks/selfhosted/neocortex-memory/`
- **Setup:** `scripts/setup-neocortex-memory.sh`
- **Plan:** neocortex v2 Phase 3, TODO-315

---

## What this is, in one paragraph

Before this stack, every client that wanted memory held a Postgres connection string. That makes
scope filtering advisory: a client that forgets a flag reads everything, and nothing server-side
can stop it. This service moves filtering, grants and audit behind an API, so a client holds a
**bearer token and nothing else** — no DSN, no model, no 400 MB download on a phone. Embeddings
are computed here (`MEMORY_API_SERVER_EMBEDDINGS=1`), which is what makes that possible.

## The two roles

This is the security model. Do not collapse it into one DSN.

| Role | Database | Privilege |
|---|---|---|
| `memory_api` | **owns** `neocortex_memory` | everything there; **nothing** on any `agentic_os` object |
| `memory_legacy_ro` | `agentic_os` (read) | `USAGE` on `public`, `SELECT` on `memory_chunks` and `memory_sources`, and nothing else; **nothing** in `neocortex_memory` |

`agentic_os` is Damian's **live v1 store**. The legacy bridge (TODO-311) reads it so that v1
recall keeps working until Phase 4 moves the content: one identity, ranked last, never writes —
no migrations, no `search_events`, no DDL.

**`provision` makes exactly one change to `agentic_os`:** `GRANT SELECT` on those two tables to
one new role. It records `\l+`, `\dn+`, `\dp` and per-table row counts before and after and prints
the diff, so "only that" is demonstrated rather than claimed.

**It deliberately does not `REVOKE CONNECT … FROM PUBLIC` on `agentic_os`.** Postgres grants that
to `PUBLIC` by default; revoking it would mean re-granting every existing role on a live store.
The boundary here is *privilege*, not connection — `memory_api` may connect to `agentic_os` and
can read nothing in it, and `verify` asserts exactly that.

---

## Deployment, in order

Steps marked **Damian** need a human: they involve a credential or a decision.

### 1. Prerequisites on LXC 100

`agentic-os-db` running (`pgvector/pgvector:pg18`), the `t3_proxy` and `agentic-os_default`
networks present, and the `fast/appdata/automation` dataset mounted. `prepare` checks all of it
and refuses rather than creating anything on the ext4 root.

### 2. The platform checkout — **Damian** (deploy key)

The code is a **pinned commit** of `DamianFlynn/neocortex-platform`, bind-mounted read-only.
Never a moving branch.

There is already an account-level SSH key on the box that can clone this today. The recommendation
is a **read-only deploy key** instead — this container serves HTTP, and a write-capable credential
on it is an unnecessary path from "someone reached the container" to "someone pushed to `main`".
Full instructions, including the `IdentitiesOnly yes` trap (without it, ssh offers the account key,
GitHub accepts it first, and the clone silently succeeds *as the account*), are in TODO-315.

```sh
mkdir -p /mnt/fast/stacks-private
git clone git@github-neocortex-platform:DamianFlynn/neocortex-platform.git \
  /mnt/fast/stacks-private/neocortex-platform
cd /mnt/fast/stacks-private/neocortex-platform
git checkout 138599d78f72f57ffc47105e082c9961ddef4c4f
git rev-parse HEAD
```

**Why that SHA and not `main`.** `138599d` is the tip with a recorded green CI
run (`35719324713`). Platform `main` has moved since, but every change to
`memory/` between the two is **comment-only** — the `aos-memory` → `pi-cortex`
rename, verified with `git diff 138599d..HEAD -- memory/ package.json
package-lock.json`. So the engine being deployed is byte-equivalent in
behaviour, and the pin keeps the deployed code tied to a CI run rather than to
whatever `main` happened to be. Re-pin deliberately, with a green run to point
at; never by pointing this checkout at a branch.

### 3. Directories

```sh
scripts/setup-neocortex-memory.sh prepare
```

Creates `/mnt/fast/appdata/automation/neocortex-memory/{root,models,deps}` owned `568:568`, and
warns if the checkout is on a branch rather than a detached commit.

### 4. Roles, database, extension, the one grant

```sh
scripts/setup-neocortex-memory.sh provision
```

Generates both role passwords, writes `.env` at mode `0600`, and prints the `agentic_os` privilege
diff. **Read that diff** — it is the evidence that the live store took exactly one change.

`MEMORY_API_TOKENS` and `MEMORY_LEGACY_BRIDGE_USER_ID` are left empty; the server refuses to start
until they are filled, which is deliberate — there is no window in which it is reachable and
unauthenticated.

### 5. Dependencies

```sh
cd /mnt/fast/stacks/stacks/selfhosted/neocortex-memory
docker compose run --rm deps
```

Needs outbound npm **and** the ONNX runtime's native binary download. If LXC 100 cannot reach
them, build `/deps` in the same image on another machine and stream the directory in.

`npm ci` runs against a *copy* of the manifests in a plain directory, not in `/app` — `/app` is
mounted read-only, and `npm ci` starts by deleting `node_modules`, which cannot be done to a bind
mount. The result is mounted back at **`/app/memory/node_modules`**.

**The manifests come from `memory/`, not the repo root.** The root `package.json` declares zero
dependencies and says so: *"Dependencies live in `memory/package.json`; install them with
`npm ci --prefix memory`."* Node resolves `require("pg")` from `memory/memory-api.cjs` by walking
up from `memory/`, so that is the first directory it checks — the same layout the Macs use.

Expect roughly **1 GB**: `@huggingface/transformers` brings the ONNX runtime with it. That is why
this lives on the `automation` dataset and not on LXC 100's root.

### 6. Schema

```sh
scripts/setup-neocortex-memory.sh migrate
```

The engine owns its own migrations and they run **inside the container**, against
`neocortex_memory`. Never from a laptop.

### 7. Identities and the first token — **Damian**

The control plane writes straight to the database over a DSN, with no API in the path. That is the
only way the first token can exist, since the server will not start without one.

> **This must run on LXC 100, in the container.** On a Mac the same command resolves a local
> PGLite store instead, creates identities in a database this API never reads, and prints a
> perfectly valid-looking token that authenticates nothing. It fails silently — a token is
> produced either way.

```sh
cd /mnt/fast/stacks/stacks/selfhosted/neocortex-memory

# Bootstrap: no actor required, these create the first admin.
docker compose run --rm admin memory-admin init-team neocortex
docker compose run --rm admin memory-admin add-user damian \
  --email <his email> --role admin \
  --private-id local-3a748bd8-28bd-4d7c-b034-f974077a9aad
#   ↑ prints the new users.id — copy it.

# Everything after this needs an explicit actor.
export MEMORY_ADMIN_ACTOR_USER_ID=<the users.id just printed>

# The token. Printed ONCE. Never stored, never recoverable.
docker compose run --rm admin memory-admin mint-token damian --capability admin
```

`--private-id` is Damian's **v1 local identity**, from the platform repo's committed
`memory/local-memory-identity.committed.json`. It must match exactly, or years of `private` rows
end up owned by an id nothing asks for.

#### Putting the token on a client

**Do not use `read -rs` inside a pasted block.** It was suggested once and it failed on the M5
(2026-09-22): the shell had the rest of the paste sitting in the tty buffer, `read` consumed that
instead of the token, and the file ended up containing the text of the command itself — silently,
with the right permissions, looking correct.

`readMemoryApiToken` calls `.trim()`, so a trailing newline is fine. Use `cat`, which shows you
what you are doing:

```sh
umask 077
mkdir -p ~/.config/neocortex
cat > ~/.config/neocortex/memory-api.token
# paste the token, press Enter, then Ctrl-D
chmod 600 ~/.config/neocortex/memory-api.token
```

**Then check it, without printing it.** A minted token is 32 random bytes base64url — 43
characters, so 43 or 44 bytes with the newline. Anything much longer is a pasted command:

```sh
wc -c < ~/.config/neocortex/memory-api.token     # expect 43 or 44
stat -f '%Lp' ~/.config/neocortex/memory-api.token   # expect 600   (macOS; Linux: stat -c '%a')
```

**And prove it against the live API.** This works before the DNS record exists, and keeps the
token out of `ps` by passing it through a curl config on a file descriptor rather than argv:

```sh
curl -sS --resolve cortex.deercrest.info:443:172.16.1.159 \
  -K <(printf 'header = "Authorization: Bearer %s"\n' \
       "$(cat ~/.config/neocortex/memory-api.token)") \
  -X POST https://cortex.deercrest.info/v1/memory/search \
  -H 'content-type: application/json' -d '{"query":"hello","topK":1}' \
  -o /dev/null -w 'HTTP %{http_code}\n'
```

`200` means the whole chain works. `401` means the file does not hold the token the server
hashed. Add `-k` only if the certificate is not issued yet — and if you need it, say so, because
that is a separate thing to fix.

---

`mint-token` prints two things:

1. the **bearer token** — goes only to each client's token file (`NEOCORTEX_MEMORY_TOKEN_FILE`,
   mode `0600`; the CLIs refuse a group- or other-readable file and name the `chmod`). Never into
   `.env`, never into a session, never into this repo.
2. the **map line** `<users.id>:admin:<sha256>` — paste into `MEMORY_API_TOKENS` in `.env`.

Then set `MEMORY_LEGACY_BRIDGE_USER_ID` to the **same `users.id`**. The bridge requires capability
`admin` *and* that id, and the server refuses to start if the configured bridge user is not an
`admin` entry in the token map.

### 8. Up, and the DNS record — **Damian**

```sh
docker compose up -d
scripts/setup-neocortex-memory.sh verify
```

The DNS record is a **DNS-only (grey) A record** `cortex.deercrest.info` → `172.16.1.159`.
Grey is not an oversight: this service is private-only, and an outside connection must time out
rather than be proxied. Recorded in `NETWORK.md`. The zone is unchanged, so Traefik's existing
Cloudflare token already covers it — no new token.

---

## Operating

### Health

```sh
curl -s https://cortex.deercrest.info/v1/health | jq
```

No auth. Names the backend, the database and whether the bridge is on. It deliberately exposes no
path, id or count.

### Renovate deploy drift

Merging a Renovate PR **deploys nothing**. The running container keeps whatever image it started
with until someone pulls and recreates it. To check for drift:

```sh
git -C /mnt/fast/stacks log -1 --format='%h %s' -- stacks/selfhosted/neocortex-memory/
docker inspect neocortex-memory-api --format '{{.Config.Image}}'
```

This stack is **excluded from all automerge** (`renovate.json5`). A Node bump changes the runtime
under a native ONNX binary compiled against the previous ABI, and that shows up as the embedder
dying at start-up rather than as a pull error. **After any Node bump: re-run `deps`, then check
`/v1/health`.**

### A second server will not start

The store takes a lock. `docker compose run --rm api` while the service is up exits non-zero and
names it; `docker compose stop api && docker compose start api` comes back, because the lock is
released on shutdown.

### Storage

Everything is under `/mnt/fast/appdata/automation/neocortex-memory/` on the ZFS dataset — **not**
on LXC 100's ext4 root, which was at 80% when this stack was written. `node_modules` and the
embedding model are the two large items and both live there by design.

The image declares no `VOLUME` (`docker image inspect node:22-bookworm-slim --format '{{json
.Config.Volumes}}'` → `null`), so it creates no anonymous volume — the failure mode that drove `/`
to zero with Jellyfin's transcode cache. If the image is ever changed, re-check that.

### Rollback

```sh
docker compose down
# in agentic_os, as superuser:
#   REVOKE ALL ON ALL TABLES IN SCHEMA public FROM memory_legacy_ro;
#   REVOKE USAGE ON SCHEMA public FROM memory_legacy_ro;
# then: DROP DATABASE neocortex_memory; DROP ROLE memory_api; DROP ROLE memory_legacy_ro;
# delete the DNS record; git revert the stack.
```

`agentic_os` data is untouched throughout, and its privilege listing returns to the recorded
"before".

---

## A rebuilt LXC

The repo is the source of truth. The only host state is the dataset, the pinned checkout and the
gitignored `.env`. Re-run steps 2–8; every subcommand is idempotent, and `provision` leaves an
existing `.env` alone (delete it to regenerate).
