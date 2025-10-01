# BYO-NAS Stacks (TrueNAS SCALE + Docker Compose)

This repository contains the **Docker Compose stacks** and **TrueNAS Apps wrappers** for a self‑hosted media and productivity server. It’s built for a Minisforum **N5 Pro** (AMD iGPU) running **TrueNAS SCALE 25.10** with:

- NVMe pool `fast` for app data/config
- HDD pool `tank` for media
- TrueNAS **Apps → Install via YAML** using an *include* wrapper
- **GitOps** workflow (+ **Renovate**) to keep images fresh with pinned digests
- **Users/permissions** pattern: `apps:apps` service account owns stacks and appdata; you work as `damian` (member of `apps`)

Current stacks:
- **code-server** (LinuxServer) – browser VS Code
- **Immich** (server + CPU‑ML + valkey + pinned Postgres) – private photo library with face/thing detection

> Traefik & Pangolin can be layered later using the same include pattern.

---

## TL;DR (Quickstart)

```bash
# One-time Git safety (repo owned by group 'apps')
git config --global --add safe.directory /mnt/fast/stacks
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global core.sharedRepository group

# Commit compose & wrappers (keep .env untracked; commit .env.sample)
git add stacks/**/compose.yaml stacks/**/.env.sample renovate.json
git commit -m "init: code-server + immich stacks with pinned images"
```

Deploy each stack in TrueNAS: **Apps → Discover Apps → Install via YAML → paste wrapper**

```yaml
# stacks/wrappers/code-server.app.yaml
services: {}
include:
  - /mnt/fast/stacks/code-server/compose.yaml
```

```yaml
# stacks/wrappers/immich.app.yaml
services: {}
include:
  - /mnt/fast/stacks/immich/compose.yaml
```

---

## Repository Layout

```text
repo-root/
├─ renovate.json
└─ stacks/
   ├─ code-server/
   │  ├─ compose.yaml
   │  ├─ .env            # ignored (PUID/PGID/TZ)
   │  └─ .env.sample     # non-secret template
   ├─ immich/
   │  ├─ compose.yaml
   │  ├─ .env            # ignored (paths, DB creds, TZ)
   │  └─ .env.sample
   └─ wrappers/
      ├─ code-server.app.yaml
      └─ immich.app.yaml
```

```mermaid
flowchart TD
    A[repo-root] --> B[renovate.json]
    A --> C[stacks/]
    C --> C1[code-server/]
    C1 --> C1a[compose.yaml]
    C1 --> C1b[.env.sample]
    C --> C2[immich/]
    C2 --> C2a[compose.yaml]
    C2 --> C2b[.env.sample]
    C --> C3[wrappers/]
    C3 --> C3a[code-server.app.yaml]
    C3 --> C3b[immich.app.yaml]
```

---

## Runtime Architecture (TrueNAS + Docker)

```mermaid
flowchart LR
    U[Clients (LAN/WAN)] -- HTTPS:8443 --> CS[code-server]
    U -- HTTPS:2283 --> IM[Immich Server]

    subgraph Docker
      CS --- V1[/mnt/fast/appdata/code-server:/config/]
      IM --- V2[/mnt/tank/media/photos:/data/]
      IM --- DRI[/dev/dri]:::dev

      ML[Immich ML (CPU)] --- V3[(model-cache)]
      R[Valkey]:::svc
      DB[(Postgres (pinned))]:::db --- V4[/mnt/fast/appdata/immich/postgres]
    end

    classDef svc fill:#eef,stroke:#66f,stroke-width:1px;
    classDef db fill:#efe,stroke:#4a4,stroke-width:1px;
    classDef dev fill:#fee,stroke:#e66,stroke-width:1px;
```

- **/dev/dri** is mapped into *immich-server* for VAAPI decode/encode on AMD iGPU (video previews).  
- *immich-machine-learning* is CPU-only in this build (stable everywhere). Re-enable ROCm later if `/dev/kfd` exists and Immich’s ROCm image supports your GPU.

---

## Users, Groups & Permissions

- **Service owner:** `apps:apps` (no login) owns `/mnt/fast/stacks` and `/mnt/fast/appdata`
- **Your user:** `damian` belongs to `apps` group (not a GUI admin)
- **Git safety:** repo marked safe for group ownership (`safe.directory`)

Recommended POSIX modes on the host:
```bash
# roots
chown -R apps:apps /mnt/fast/stacks /mnt/fast/appdata
chmod g+s /mnt/fast/stacks /mnt/fast/appdata
find /mnt/fast/{stacks,appdata} -type d -exec chmod 2775 {} \;
find /mnt/fast/{stacks,appdata} -type f -exec chmod 0664 {} \;

# EXCEPT database folders (Postgres wants postgres:postgres and 700)
chown -R postgres:postgres /mnt/fast/appdata/immich/postgres
chmod 700 /mnt/fast/appdata/immich/postgres
```

TrueNAS datasets used:
- `tank/media/photos` → Immich library originals (`/data`)
- `fast/appdata/immich` (+ `/immich/postgres`) → config + DB
- `fast/appdata/code-server` → config

---

## Stacks

### code-server

- Image: `lscr.io/linuxserver/code-server` (pinned digest; see compose)
- Ports: `8443:8443`
- Volumes:
  - `/mnt/fast/appdata/code-server:/config`
  - `/mnt/fast/stacks:/stacks` (so you can edit other stack files in VS Code)
- Env (in `.env` – ignored): `PUID=568`, `PGID=568`, `TZ=Europe/Dublin`

### Immich (server + ML + valkey + Postgres)

- **Server**: `ghcr.io/immich-app/immich-server:release@sha256:...`
  - `devices: /dev/dri` for VAAPI
  - Mounts `/mnt/tank/media/photos:/data` (library originals)
- **Machine Learning**: CPU-only (`immich-machine-learning:release@sha256:...`)
  - `EXECUTION_PROVIDERS=CPUExecutionProvider`
  - Optional ROCm later if `/dev/kfd` exists & image supports it
- **Valkey**: pinned (`valkey:8-bookworm@sha256:...`)
- **Postgres**: **pinned** image/tag+digest from Immich’s compose (no Renovate)
  - Data at `/mnt/fast/appdata/immich/postgres`
  - **Must be `postgres:postgres` and `700`**

`.env` (ignored by Git) carries paths and DB credentials; add a `.env.sample` with placeholders for onboarding.

---

## TrueNAS Apps Wrappers

We use a tiny wrapper file per app to satisfy the TrueNAS YAML validator and include the real compose:

```yaml
# stacks/wrappers/<name>.app.yaml
services: {}
include:
  - /mnt/fast/stacks/<name>/compose.yaml
```

- Paste the wrapper in **Apps → Install via YAML**.
- On updates, edit files under `stacks/<name>/` and click **Update/Upgrade** on the app.  
- Do **not** include `.env` in the wrapper – it’s not YAML.

---

## Renovate

We use Renovate to keep images fresh **with pinned digests** for reproducible deploys.

- **Automerge** safe services: `code-server`, `valkey` (minor/patch/digest)
- **Manual review**: `immich-server`, `immich-machine-learning`
- **Locked**: Immich **Postgres** (update manually when upstream changes their recommended tag)

`renovate.json` (at repo root) includes labels and rules like:

```json
{
  "extends": ["config:recommended", ":pinDigests"],
  "enabledManagers": ["docker-compose"],
  "labels": ["renovate"],
  "packageRules": [
    {
      "matchPackageNames": ["lscr.io/linuxserver/code-server", "docker.io/valkey/valkey"],
      "matchUpdateTypes": ["minor", "patch", "digest"],
      "labels": ["safe", "automerge"],
      "automerge": true,
      "platformAutomerge": true
    },
    {
      "matchPackagePatterns": ["^ghcr\\.io/immich-app/immich-server$", "^ghcr\\.io/immich-app/immich-machine-learning$"],
      "labels": ["stack:immich", "manual-merge"],
      "automerge": false
    },
    {
      "matchPackagePatterns": ["^ghcr\\.io/immich-app/postgres$"],
      "enabled": false,
      "labels": ["stack:immich", "component:postgres", "locked"]
    }
  ]
}
```

### Pinning digests (once per image)
```bash
docker pull lscr.io/linuxserver/code-server:latest
docker image inspect lscr.io/linuxserver/code-server:latest --format '{{index .RepoDigests 0}}'
# copy the sha256 into compose.yaml after the tag:  :latest@sha256:...

docker pull ghcr.io/immich-app/immich-server:release
docker image inspect ghcr.io/immich-app/immich-server:release --format '{{index .RepoDigests 0}}'

docker pull ghcr.io/immich-app/immich-machine-learning:release
docker image inspect ghcr.io/immich-app/immich-machine-learning:release --format '{{index .RepoDigests 0}}'
```

### Nice-to-have labels in your Git host
Create labels like `automerge`, `manual-merge`, `stack:immich`, `stack:code-server`, `update:minor`, etc. Renovate will tag PRs accordingly.

---

## Backups & Snapshots

- **App config** (`/mnt/fast/appdata/**`): periodic ZFS snapshots; replicate off-box if you can
- **Immich DB**: snapshot the dataset + consider periodic `pg_dump` for point-in-time recovery
- **Immich library** (`/mnt/tank/media/photos`): snapshot & replicate
- **Time Machine**: configured as an SMB “Time Machine Share” on its own dataset with a ZFS **quota**

---

## Troubleshooting

- **“YAML missing required `services` key”** in Apps → Install via YAML  
  Use the wrapper with `services: {}` then `include: /path/to/compose.yaml`. Don’t include `.env` there.
- **“top-level object must be a mapping”**  
  You included a non‑YAML file (like `.env`) in `include:`. Remove it.
- **Postgres won’t start after chown**  
  Ensure `/mnt/fast/appdata/immich/postgres` is `postgres:postgres` and `700`. If unsure, run a one‑off container to fix:
  ```bash
  docker run --rm -v /mnt/fast/appdata/immich/postgres:/var/lib/postgresql/data \
    ghcr.io/immich-app/postgres:16 bash -lc 'chown -R postgres:postgres /var/lib/postgresql/data; chmod 700 /var/lib/postgresql/data'
  ```
- **SSH key auth failing**  
  Home dir or `.ssh` perms too open. Ensure: `~`=750, `~/.ssh`=700, `authorized_keys`=600 (owned by the user).

---

## Conventions

- **Paths**: absolute host paths in compose (`/mnt/...`) for reliability with TrueNAS Apps
- **.env**: contains non‑committed secrets/paths; commit `.env.sample` only
- **Digest pinning**: `image: tag@sha256:...`
- **Group model**: `apps:apps` owns; `damian` edits via group; GUI admin stays separate

---

## Roadmap

- Add **Traefik** network + labels to stacks (t3_proxy), Authelia chain
- Enable **ROCm** ML when supported (`/dev/kfd` present; image supports your GPU)
- Add more stacks (Arrs/Jellyfin/N8N/Immich add‑ons) using the same include pattern
- Add Renovate rules per new stack with appropriate risk labels

---

Happy self‑hosting! 🚀
