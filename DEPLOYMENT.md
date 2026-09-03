# Deployment Guide

How change reaches the estate: Terraform for infrastructure, git for stacks, and the checks that
tell you whether it landed.

> **Rewritten 2026-09-03.** The previous version of this file described a **TrueNAS Scale Apps**
> workflow with `/mnt/tank/stacks` paths and a TrueNAS UI deployment step. That estate no longer
> exists — the platform is Proxmox VE with an unprivileged LXC. None of the old commands would have
> worked. Verified against the live host.

**Platform:** Proxmox VE 9.1 on `atlantis` (172.16.1.158) → LXC `100` `selfhost` (172.16.1.159),
103 containers.

---

## The deployment model in one paragraph

The repo is a **git clone on the host** at `/mnt/fast/stacks`, tracking `origin/main`. You never
copy files to the server. You commit, push to GitHub, then `git pull` on the LXC and bring the
affected stack up. Terraform owns everything below the container line — the Proxmox host, the LXC
itself, its mounts and its datasets — and is **authoritative**: do not hand-edit what it manages.

```
workstation ──commit──> GitHub (origin/main) ──git pull──> /mnt/fast/stacks on LXC 100
                                                                    │
                                                            docker compose up -d
```

---

## Prerequisites

- SSH to `root@172.16.1.158` (Proxmox host) and `root@172.16.1.159` (LXC 100)
- Terraform 1.10+ locally, for `infra/` only
- Secrets in `~/.claude/secrets/` — **this repo is public**; `.env` files are gitignored and
  credentials are referenced by variable name only, never by value

---

## 1. Infrastructure (Terraform)

```bash
cd infra
terraform init
terraform plan          # ALWAYS read this
terraform apply
```

Terraform manages: the ZFS pool and datasets, LXC 100 (unprivileged, GPU passthrough, bind mounts),
VM 102, the `apps:apps` (568:568) service account, and GPU device mapping (`video:44`,
`render:110`).

> ### 🔴 `terraform apply` can destroy LXC 100
>
> A bare apply has planned **`1 to destroy`** on the Docker host and its ~100 containers — armed
> since February by a `bpg/proxmox` provider artifact around `mount_point`. It is now guarded by
> `prevent_destroy` + `ignore_changes`.
>
> The guard has a cost you must know about: **genuine bind-mount edits now plan clean and do
> nothing.** A mount change that appears to apply successfully may not have applied at all.
>
> **Never `apply` without reading the plan.** If you see `destroy` against `lxc-selfhost`, stop.

### Adding a quota'd dataset

Anything that grows without bound gets its own dataset with a `quota`, declared in `infra/` —
never created by hand. `infra/jellyfin-transcode-dataset.tf` is the worked example.

Use **`quota`, not `refquota`**: `quota` counts descendants and returns `ENOSPC`, which is the errno
this estate's log greps key on. `refquota` returns `EDQUOT` and would be invisible to them.

---

## 2. Stacks (git + compose)

### The normal flow

```bash
# 1. locally: commit and push
git add stacks/selfhosted/<stack>/
git commit -m "feat(<stack>): ..."
git push origin main

# 2. on the host: pull and bring up
ssh root@172.16.1.159
cd /mnt/fast/stacks
git pull --ff-only origin main
docker compose -f stacks/selfhosted/<stack>/compose.yaml up -d
```

`--ff-only` is deliberate — it fails loudly rather than creating a merge commit on a host you are
not developing on.

Or drive both ends from the workstation:

```bash
bash scripts/sync-repo.sh    # pulls locally AND on the host, then compares commits
```

### Order matters once

**Traefik first** — it defines the shared `t3_proxy` network every other stack attaches to:

```bash
docker compose -f stacks/selfhosted/traefik/compose.yaml up -d
```

`iot_macvlan` is the other external network (real LAN addresses; only `jellyfin` and `dispatcharr`
use it — see [MEDIA.md](MEDIA.md) § 2).

After that, stacks are independent:

```bash
docker compose -f stacks/selfhosted/media/compose.yaml up -d
docker compose -f stacks/selfhosted/arrs/compose.yaml up -d
```

### Verifying it actually landed

```bash
ssh root@172.16.1.159 'cd /mnt/fast/stacks && git rev-parse HEAD'
git rev-parse origin/main            # these must match
docker compose -f stacks/selfhosted/<stack>/compose.yaml ps
```

> ⚠️ **`docker ps` hides a whole class of failure.** A container stuck in `created` is not
> `running`, but also not `exited`, `dead` or `restarting`, so the usual filters miss it. Two
> containers sat silently down for six weeks this way.
>
> ```bash
> docker ps -a --format '{{.State}}' | sort | uniq -c   # the true census
> ```

---

## 3. Storage conventions

| Path | What |
|------|------|
| `/mnt/fast/stacks` | this repo, on the host |
| `/mnt/fast/appdata/<stack>` | persistent app state |
| `/mnt/fast/transcode` | Jellyfin transcode scratch (`fast/transcode`, 50 G quota) |
| `/mnt/tank/media` | media library (9 T) |
| `/mnt/tank/downloads` | download staging |

Ownership `apps:apps` = **568:568**.

### ⚠️ `/mnt/fast/appdata` is not a mountpoint — check before you assume

`/mnt/fast` and `/mnt/fast/appdata` are **plain directories on LXC 100's 126 G ext4 root disk**.
Only the *children* are ZFS datasets. A new stack directory under `/mnt/fast/appdata/` with no
dataset behind it writes to `/` — and looks identical to one that doesn't.

```bash
# df LIES here — it reports /'s figures for a non-mountpoint. Use:
mountpoint -q /mnt/fast/appdata/<stack> && echo "dataset ✓" || echo "ON / — unbounded ⚠"
```

Six stacks are currently in this state (`monitoring`, `agentic-os`, `mattermost`, `documents`,
`open-archiver`, `rustdesk`) — see [MEDIA.md](MEDIA.md) § 8.

### ⛔ Never leave an anonymous volume

A path the image declares as `VOLUME` but the compose file does not bind gets an **anonymous
volume** under `/var/lib/docker/volumes` — on `/`, unnamed and unbounded. This is how 19 GB of
Jellyfin transcode cache emptied the root filesystem.

```bash
docker image inspect <image> --format '{{json .Config.Volumes}}'   # before deploying
docker volume ls -qf dangling=true                                  # after
```

See [STANDARDS.md](STANDARDS.md) § Volume Mounting.

### Do not stage large files in `/tmp` on the LXC

`/tmp` is **tmpfs, backed by host RAM**. 1.1 GB of XML there took the whole 28 GB box down and
killed SSH on host *and* LXC while ping still worked. Stage under `/mnt/fast/` instead.

---

## 4. Secrets

- `.env` files are **gitignored** and live beside each stack; `.env.sample` is the committed
  template
- **This repo is public.** Credentials go in `~/.claude/secrets/`, referenced by variable name
  only. A gateway password sat in this repo for ~6 months and remains recoverable via
  `git log -S` — redaction is not rotation
- Screen before pushing, and let the screen **gate** the push rather than run alongside it:

```bash
git diff origin/main..HEAD | grep '^+' | \
  grep -inE 'api_key=|password[=:]|Bearer [A-Za-z0-9]{8}|BEGIN [A-Z ]*PRIVATE KEY'
```

Run a positive control first against known secret-shaped text — a screen that has never matched
anything is not evidence of cleanliness.

---

## 5. Updates (Renovate)

Renovate raises PRs against this repo for image tags.

> ⚠️ **Merging a Renovate PR does not deploy anything.** It changes the compose file in git only.
> The host still runs the old image until someone pulls and recreates the container. Check
> `docker ps`, not just the PR list.
>
> Two-part tags like `2.13` **float** — re-pull rather than rewriting the tag.

The real backlog lives on the **Dependency Dashboard issue**, not the PR list. A config error (e.g.
a `"// key"` comment) silently stops the entire repo run — validate before merging:

```bash
npx --yes renovate-config-validator renovate.json5
bash scripts/check-renovate.sh
```

---

## 6. Post-deploy health check

```bash
bash scripts/quick-health-check.sh      # from the workstation. 0 = healthy, 1 = violation
REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh   # busy host / slow link
```

Folds in `check-music-freeze.sh`, `check-music-consumers.sh` and `check-jellyfin-transcode.sh`.
Design rules for adding a check are in [README.md](README.md) § Health Checks — fail closed, bound
remote commands Linux-side, assert rather than report.

---

## 7. Troubleshooting

| Symptom | Check |
|---------|-------|
| Container not in `docker ps` | `docker ps -a` — it may be stuck in `created` |
| `address already in use` | Host-level systemd services own ports too (`pulse-agent` owns 9191). See NETWORK.md |
| Service unreachable via `*.deercrest.info` | Traefik up? On `t3_proxy`? Labels correct? |
| Traefik and everything behind it dead, macvlan services fine | Suspect the amdgpu HMM oops — `/proc/pressure/io` `full` ≈ 96% with **idle CPU**, `tainted` bit 7. Recover with sysrq `s`+`b`. See MEDIA.md § 4 |
| `/` filling | `docker system df -v`, `docker volume ls -qf dangling=true`, and § 3 above |
| Certificate issues | `docker logs traefik`; Cloudflare DNS-01 credentials in the traefik `.env` |

```bash
docker logs -f <container>
docker compose -f stacks/selfhosted/<stack>/compose.yaml logs -f
journalctl -u pulse-agent -n 50        # host-level services
```

---

## Reference

- [README.md](README.md) — architecture, storage, health checks
- [NETWORK.md](NETWORK.md) — addressing, ports, host-level services
- [MEDIA.md](MEDIA.md) — media stack LLD
- [TAILSCALE.md](TAILSCALE.md) — remote access LLD
- [STANDARDS.md](STANDARDS.md) — compose and volume conventions

*Last updated: 2026-09-03. Commands verified against the live estate.*
