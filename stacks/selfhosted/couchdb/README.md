# CouchDB: neocortex LiveSync backend

Single-node Apache CouchDB 3.5 that the Obsidian **Self-hosted LiveSync** plugin replicates the
neocortex vault against — the M5, the mini and the iPhone all sync through it. Vault content is
end-to-end encrypted by the plugin before it leaves each device; this server holds ciphertext
chunks. Added 2026-09-16 for neocortex v2 Phase 2 (TODO-214); not yet deployed at the time of the
commit that introduced this file.

| | |
|---|---|
| URL | `https://livesync.deercrest.info` |
| Image | `couchdb:3.5.2` (Docker Hub official image) |
| Container | `couchdb`, uid/gid `5984`, `mem_limit: 1g`, no host port |
| Data | `/mnt/fast/appdata/automation/couchdb/data` |
| Config | `/mnt/fast/appdata/automation/couchdb/etc/local.d/` (`neocortex.ini` + runtime files) |
| Auth | CouchDB's own — `require_valid_user = true`. **No Authelia, no Traefik middleware** |
| Renovate | Excluded from **all** automerge (`renovate.json5`, last rule) |

## Request path

```
Obsidian LiveSync (app://obsidian.md, capacitor://localhost)
  → Cloudflare        proxied CNAME  livesync.deercrest.info → deercrest.info (orange cloud — to confirm, see "Cloudflare proxy")
  → Traefik           websecure, TLS via the dns-cloudflare DNS-01 resolver, readTimeout=0s
  → (no middleware)
  → couchdb:5984      t3_proxy network
```

There is **no wildcard DNS record** on `deercrest.info` (see `trek/README.md`), so
`livesync.deercrest.info` needs its own record before anything below will resolve. A Traefik
certificate is not evidence that DNS resolves.

### Why no middleware

- **`chain-authelia@file`** — forwardAuth redirects an API client to a login page, and the chain's
  `buffering` middleware caps request bodies at 10 MB.
- **`chain-no-auth@file`** — looks harmless, is not. Its `secure-headers` middleware sets
  `accessControlAllowMethods: GET, OPTIONS, PUT`. A Traefik headers middleware with CORS options
  answers the **preflight itself**, so LiveSync's `POST` and `DELETE` would be refused before they
  reach CouchDB. CouchDB owns CORS here (`[cors]` in `neocortex.ini`).

## Storage — why `automation`, and why this must be checked

`/mnt/fast/appdata` is **not a mountpoint** inside LXC 100 — only its children are ZFS datasets,
each bind-mounted by `infra/lxc-selfhost.tf`. A new `/mnt/fast/appdata/couchdb` would silently land
on the 126 G ext4 root (73 % used on 2026-09-16). Creating a new dataset is a manual `pct set`
(Terraform ignores `mount_point` changes), so CouchDB reuses the **already-mounted
`fast/appdata/automation`** dataset. Read-only check on 2026-09-16:

```
$ findmnt -T /mnt/fast/appdata/automation
TARGET                       SOURCE                  FSTYPE OPTIONS
/mnt/fast/appdata/automation fast/appdata/automation zfs    rw,noatime,xattr,noacl,casesensitive
```

The image declares `VOLUME /opt/couchdb/data`; it is bound in `compose.yaml`, so no anonymous
volume is created on `/`.

### Why 5984, not apps:apps (568)

The estate convention is `568:568`. CouchDB is the exception: the image's `couchdb` user is
`5984`, owns `/opt/couchdb` and is its `HOME` (where Erlang writes `.erlang.cookie`). Running as
`5984` from the start — `user: "${PUID}:${PGID}"` with `PUID=PGID=5984` — is what the LiveSync
docs use, means the entrypoint never runs as root and never `chown`s the bind mounts, and avoids
the arbitrary-uid failure modes of running the Erlang VM as a user that does not own its home. In
the unprivileged LXC, `5984` inside maps to `105984` on atlantis; that is expected.

### The config directory holds runtime state

CouchDB writes every runtime change (`PUT /_node/_local/_config/...`, the hashed admin password,
the generated `uuid` and `[chttpd_auth] secret`) to the **last** `.ini` file in its chain. That is
why deploy creates an empty `zz-runtime.ini`: it sorts after `docker.ini` and `neocortex.ini`, so
runtime writes land there and `neocortex.ini` stays identical to the committed template (and can be
re-copied safely). Consequences:

- `local.d/` contains secrets at rest: `docker.ini` keeps the admin password **as supplied** by the
  entrypoint (the same value already sits in this stack's `.env` on the host), and
  `zz-runtime.ini` holds the hash, uuid and cookie secret. Directory mode `0750`, owner `5984`.
  **Never copy anything from `local.d/` back into this repo** — it is public.
- **Never delete or overwrite `zz-runtime.ini`** on a running install: a new `uuid`/secret
  invalidates sessions and replication checkpoints.
- The TODO-217 backup archives the whole `couchdb/` tree, so the backup inherits these secrets;
  it is protected by restic's encryption, not by this directory's mode.

## Secrets (Bitwarden)

| Item | Username | Used by |
|---|---|---|
| `neocortex/shared/couchdb-admin` | CouchDB server admin | `.env`, healthcheck, provisioning, user/db creation |
| `neocortex/shared/livesync-damian` | `damian` | LiveSync on every device (member of `neocortex` only) |
| `neocortex/shared/livesync-e2e` | — (password field = passphrase) | LiveSync end-to-end encryption passphrase (TODO-215) |

Damian creates all three before step 4. Nothing below prints or embeds a value: commands read from
`bw` into shell variables. Run them on the **M5** (it has `bw`, `jq` and `deno`), in a single shell
with an unlocked vault (`export BW_SESSION="$(bw unlock --raw)"`).

## Deploy (Damian)

Run the LXC steps as `root@172.16.1.159`; the rest from the M5. Every step is safe to re-run.

```bash
# ── 0. Before: record the byte counts the acceptance compares ────── (LXC 100)
df -B1 --output=used,avail / | tail -1
du -sb /mnt/fast/appdata/automation 2>/dev/null | cut -f1
docker system df

# ── 1. Prove the parent IS the mounted dataset, BEFORE creating anything ── (LXC 100)
findmnt -T /mnt/fast/appdata/automation
#   must print SOURCE fast/appdata/automation, FSTYPE zfs, TARGET /mnt/fast/appdata/automation.
#   If TARGET is "/" — STOP. The dataset is not mounted and the dirs would land on the root disk.
mountpoint -q /mnt/fast/appdata/automation && echo "dataset ✓" || { echo "ON / — STOP"; false; }

# ── 2. Pull the stack and create the directories as uid/gid 5984 ─── (LXC 100)
cd /mnt/fast/stacks && git pull --ff-only origin main
install -d -m 0750 -o 5984 -g 5984 /mnt/fast/appdata/automation/couchdb
install -d -m 0750 -o 5984 -g 5984 /mnt/fast/appdata/automation/couchdb/data
install -d -m 0750 -o 5984 -g 5984 /mnt/fast/appdata/automation/couchdb/etc
install -d -m 0750 -o 5984 -g 5984 /mnt/fast/appdata/automation/couchdb/etc/local.d
findmnt -T /mnt/fast/appdata/automation/couchdb/data    # TARGET must still be /mnt/fast/appdata/automation

# ── 3. Install the committed settings + the empty runtime file ───── (LXC 100)
install -m 0640 -o 5984 -g 5984 stacks/selfhosted/couchdb/neocortex.ini \
  /mnt/fast/appdata/automation/couchdb/etc/local.d/neocortex.ini
[ -e /mnt/fast/appdata/automation/couchdb/etc/local.d/zz-runtime.ini ] || \
  install -m 0640 -o 5984 -g 5984 /dev/null /mnt/fast/appdata/automation/couchdb/etc/local.d/zz-runtime.ini
ls -la /mnt/fast/appdata/automation/couchdb/etc/local.d

# ── 4. Write .env on the host from Bitwarden ─────────────────────── (M5)
#   Values travel over ssh stdin, never argv. The key names are assembled by printf so that no
#   "<name>=<value>" assignment for the password appears in this public file.
CDB_USER="$(bw get username neocortex/shared/couchdb-admin)"
CDB_PASS="$(bw get password neocortex/shared/couchdb-admin)"
{ printf 'COUCHDB_%s=%s\n' USER "$CDB_USER" PASSWORD "$CDB_PASS"
  printf '%s\n' PUID=5984 PGID=5984 TZ=Europe/Dublin DOMAINNAME=deercrest.info
} | ssh root@172.16.1.159 'umask 077; cat > /mnt/fast/stacks/stacks/selfhosted/couchdb/.env'
ssh root@172.16.1.159 'cut -d= -f1 /mnt/fast/stacks/stacks/selfhosted/couchdb/.env'   # names only
unset CDB_USER CDB_PASS

# ── 5. DNS: Cloudflare record for livesync.deercrest.info ───────── DONE 2026-09-17
#   CNAME livesync → deercrest.info, proxied (same as keeper.deercrest.info), created via the
#   Cloudflare API with Traefik's zone DNS token. Verify: dig +short livesync.deercrest.info

# ── 6. Start it ─────────────────────────────────────────────────── (LXC 100)
cd /mnt/fast/stacks
docker compose -f stacks/selfhosted/couchdb/compose.yaml pull
docker image inspect couchdb:3.5.2 --format '{{json .Config.Volumes}}'   # only /opt/couchdb/data (bound)
docker compose -f stacks/selfhosted/couchdb/compose.yaml up -d
docker compose -f stacks/selfhosted/couchdb/compose.yaml ps       # wait for (healthy)
docker logs couchdb 2>&1 | tail -20
```

### 7. LiveSync provisioning (`couchdb-init.sh`) — from the M5

Upstream's `utils/couchdb/couchdb-init.sh` is now a thin wrapper that runs `provision.ts` under
**Deno 2** (it no longer curls the config keys itself). It performs `_cluster_setup
enable_single_node` and sets `chttpd/require_valid_user`, `chttpd_auth/require_valid_user`,
`httpd/WWW-Authenticate`, `httpd/enable_cors`, `chttpd/enable_cors`,
`chttpd/max_http_request_size`, `couchdb/max_document_size`, `cors/credentials` and `cors/origins`
— the same values `neocortex.ini` already carries, so this run is confirmation plus the single-node
system databases (`_users`, `_replicator`). Its writes persist to `zz-runtime.ini`.

It is **not vendored** into this repo. Run it pinned to a reviewed upstream commit
(`04b57340896101a16211e5100dc476d79a4e91fb`, the last change to `utils/couchdb/` as of 2026-09-16),
and read the two files before running them:

```bash
LS_REF=04b57340896101a16211e5100dc476d79a4e91fb
LS_RAW="https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/${LS_REF}/utils/couchdb"
curl -fsSL "${LS_RAW}/couchdb-init.sh" -o "${TMPDIR:-/tmp}/couchdb-init.sh"
curl -fsSL "${LS_RAW}/provision.ts"    | less     # review: only the config PUTs listed above

( # subshell: the tool reads lower-case hostname/username/password, keep them out of your shell
  export provision_script_url="${LS_RAW}/provision.ts"
  export hostname=https://livesync.deercrest.info
  export username="$(bw get username neocortex/shared/couchdb-admin)"
  export password="$(bw get password neocortex/shared/couchdb-admin)"
  unset database            # deliberate — see below
  bash "${TMPDIR:-/tmp}/couchdb-init.sh"
)   # expect: CouchDB provisioning completed.
```

`database` is left **unset** on purpose. With it set, the tool also creates the database *and*
writes LiveSync's database-version document through Commonlib, so `doc_count` would not read `0`
in verification. The database is created empty in step 8; the first device (TODO-215) initialises
it through the plugin's own onboarding.

### 8. Database `neocortex` and member user `damian` — from the M5

```bash
CDB=https://livesync.deercrest.info
CDB_AUTH="$(bw get username neocortex/shared/couchdb-admin):$(bw get password neocortex/shared/couchdb-admin)"
LS_USER="$(bw get username neocortex/shared/livesync-damian)"
[ "$LS_USER" = damian ] || { echo "livesync-damian username is '$LS_USER', expected damian"; false; }

# 8a. the database (201 created, or 412 if it already exists)
curl -s -o /dev/null -w '%{http_code}\n' -u "$CDB_AUTH" -X PUT "$CDB/neocortex"

# 8b. the user — password goes through jq --arg on stdin, never on a command line
bw get password neocortex/shared/livesync-damian \
  | jq -Rn --arg n "$LS_USER" '{name:$n, password:input, roles:[], type:"user"}' \
  | curl -s -u "$CDB_AUTH" -X PUT -H 'Content-Type: application/json' --data-binary @- \
      "$CDB/_users/org.couchdb.user:$LS_USER"
#   (to rotate: GET the doc, keep _rev, PUT again with the new password)

# 8c. make damian the only member of neocortex (members may read/write docs, not change design/security)
jq -n --arg n "$LS_USER" '{admins:{names:[],roles:[]}, members:{names:[$n],roles:[]}}' \
  | curl -s -u "$CDB_AUTH" -X PUT -H 'Content-Type: application/json' --data-binary @- \
      "$CDB/neocortex/_security"

# 8d. prove the member can read it and an anonymous caller cannot
curl -s -o /dev/null -w 'member %{http_code}\n' -u "$LS_USER:$(bw get password neocortex/shared/livesync-damian)" "$CDB/neocortex"   # 200
curl -s -o /dev/null -w 'anon %{http_code}\n' "$CDB/neocortex"                                                                      # 401
unset CDB_AUTH
```

### Two databases, not two servers

| Database | When | Members |
|---|---|---|
| `neocortex` | now (Phase 2) | `damian` |
| `neocortex-breege` | Phase 5 | a separate member user; its own `_security`; its own E2E passphrase |

Each vault is its own database on this one instance, isolated by `_security` membership rather
than by a second container. Adding `neocortex-breege` is step 8 again with a different database
name, user and Bitwarden items — not a new stack.

## Verification — the six checks (TODO-214 Expected)

```bash
CDB=https://livesync.deercrest.info
CDB_AUTH="$(bw get username neocortex/shared/couchdb-admin):$(bw get password neocortex/shared/couchdb-admin)"

# 1. no anonymous access                                        → 401
curl -s -o /dev/null -w '%{http_code}\n' "$CDB/"

# 2. alive, with credentials                                   → {"status":"ok"}
curl -su "$CDB_AUTH" "$CDB/_up"

# 3. the database exists and is empty                          → "doc_count": 0
curl -su "$CDB_AUTH" "$CDB/neocortex" | jq '{db_name, doc_count}'

# 4. is the route Cloudflare-proxied? (compare keeper.deercrest.info)   → cf-ray present = proxied
curl -sI "$CDB/" | grep -i cf-ray
curl -sI https://keeper.deercrest.info/ | grep -i cf-ray

# 5. binds are only the automation paths                          (on LXC 100)
docker inspect couchdb --format '{{.HostConfig.Binds}}'
#   → [/mnt/fast/appdata/automation/couchdb/data:/opt/couchdb/data /mnt/fast/appdata/automation/couchdb/etc/local.d:/opt/couchdb/etc/local.d]

# 6. the data dir resolves through the automation mount, not the root disk   (on LXC 100)
findmnt -T /mnt/fast/appdata/automation/couchdb/data
#   → TARGET /mnt/fast/appdata/automation  SOURCE fast/appdata/automation  FSTYPE zfs
unset CDB_AUTH
```

Then repeat step 0 and compare: growth under `/mnt/fast/appdata/automation` is CouchDB's data;
growth on `/` should be bounded to the pulled image and container layer (`docker system df`).

## Cloudflare proxy — risk and fallback

Every `*.deercrest.info` record except `tv.deercrest.info` is orange-cloud (NETWORK.md, TV chain).
If `couchdb` is proxied too:

- **Free-plan request cap is 100 MB.** LiveSync chunks notes and attachments far below that, so
  ordinary sync is unaffected; a single enormous attachment is the edge case.
- **Long-lived requests.** Continuous replication holds `_changes` feeds open. Traefik's
  `websecure` already has `readTimeout=0s`; Cloudflare's own proxy timeouts are the remaining
  unknown. If live sync on the phone repeatedly stalls or reconnects, suspect the proxy first.

**Fallback (Damian's router decision):** switch the record to **DNS-only (grey cloud)** and reach
Traefik directly on 443 — exactly how `tv.deercrest.info` works for long-lived MPEG-TS. That
publishes the origin IP; CouchDB's `require_valid_user` remains the boundary. Re-run check 4 to
confirm `cf-ray` is gone.

## Renovate deploy drift

CouchDB is **excluded from automerge for every update type** (`renovate.json5`, the
`CouchDB (neocortex LiveSync)` rule). Even so, merging a Renovate PR deploys nothing
(DEPLOYMENT.md § 5): the host keeps running the old image until someone pulls and recreates. Check
that git and the running container agree:

```bash
# on LXC 100
git -C /mnt/fast/stacks log -1 --oneline                                   # what the checkout is at
git -C /mnt/fast/stacks log -1 --oneline -- stacks/selfhosted/couchdb/     # last change to this stack
grep -E '^\s*image:' /mnt/fast/stacks/stacks/selfhosted/couchdb/compose.yaml
docker ps --filter name=^couchdb$ --format '{{.Names}} {{.Image}} {{.Status}}'
#   the image tag in compose.yaml and in docker ps must match; also compare
#   `git -C /mnt/fast/stacks rev-parse HEAD` with `git rev-parse origin/main` on the workstation
```

To take an update: merge the PR, then on LXC 100 `git pull --ff-only`, `docker compose -f
stacks/selfhosted/couchdb/compose.yaml pull && ... up -d`, and re-run checks 2 and 3 (`doc_count`
must be unchanged). Stop LiveSync on the devices first for anything beyond a patch.

## Rollback

```bash
docker compose -f stacks/selfhosted/couchdb/compose.yaml down          # LXC 100
findmnt -T /mnt/fast/appdata/automation/couchdb                         # confirm the path FIRST
# only with Damian's explicit approval:
# rm -rf /mnt/fast/appdata/automation/couchdb
```

Then revert the stacks commit and delete the `couchdb` DNS record in Cloudflare.
