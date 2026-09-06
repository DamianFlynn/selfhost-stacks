---
task: 260906-e6l
title: Bound atlantis memory oversubscription
status: complete
date: 2026-09-06
branch: main
commits:
  - 00d24e1 fix(infra) cap mpe LXC at 3 GB to end atlantis memory oversubscription
  - af2f8e5 fix(stacks) bound the 12 largest uncapped containers with mem_limit
files_changed: 11
deployed: false
---

# Quick Task 260906-e6l Summary

Code-only change. Nothing was applied, deployed or restarted.

## What changed

### Task 1 - `infra/variables.tf`

`mpe_memory_mb` default **8192 -> 3072**. The heredoc `description` gained a note in the style of
the existing 20480 -> 8192 record, stating the new number, the measured peak it derives from
(LXC 102 cgroup `memory.peak` 2.17 GB over 5 d 15 h, `memory.current` 1.77 GB, so ~42% headroom),
the arithmetic that makes it matter (24576 + 8192 = 32768 MB of caps on a 29686 MB host, 3082 MB
oversubscribed before ZFS ARC's 3113 MB `c_max`; new total 27648 leaves 2038 MB for host + ARC,
`c_min` 972 MB), why 4096 was rejected (1014 MB left, re-creating the starved-ARC condition), and
that the cap is sized from peak not current because LXC 102's ERPNext/n8n/traefik/cloudflared
workload is bursty.

The existing amdgpu-compaction warning was **kept verbatim** - that reasoning is still live and is
the reason the cap matters at all.

### Task 2 - `mem_limit` on 12 containers

| Container | File edited | Cap |
|---|---|---|
| `immich_server` | `stacks/selfhosted/immich/compose.yaml` (svc `immich-server`) | `3g` |
| `dispatcharr` | `stacks/selfhosted/media/dispatcharr.yaml` | `3g` |
| `jellyfin` | `stacks/selfhosted/media/jellyfin.yaml` | `3g` |
| `postiz` | `stacks/selfhosted/postiz/postiz.yaml` | `2g` |
| `ai-docling` | `stacks/selfhosted/openwebui/compose.yaml` | `2g` |
| `open-archiver` | `stacks/selfhosted/open-archiver/compose.yaml` | `2g` |
| `ai-openwebui` | `stacks/selfhosted/openwebui/compose.yaml` (svc `openwebui`) | `1536m` |
| `paperless` | `stacks/selfhosted/documents/paperless.yaml` | `1536m` |
| `pwpush` | `stacks/selfhosted/automation/pwpush.yaml` | `1g` |
| `homarr` | `stacks/selfhosted/homarr/homarr.yaml` | `1g` |
| `janitorr` | `stacks/selfhosted/arrs/janitorr.yaml` | `1g` |
| `ai-tika` | `stacks/selfhosted/openwebui/compose.yaml` | `1g` |

Each carries a short comment recording the measured figure and that the cap bounds a runaway, not
steady state. The three generous caps (`dispatcharr`, `jellyfin`, `immich_server`) additionally
record *why* they are generous, so a later tightening pass does not undo the reasoning.

## Deviations from the plan

**1. The service definitions are not in the `compose.yaml` files the plan named.**

Seven of the ten stacks use `include:` - `compose.yaml` declares only `name`, `networks` and
`volumes`, and the services live in per-service files (`media/jellyfin.yaml`,
`media/dispatcharr.yaml`, `postiz/postiz.yaml`, `automation/pwpush.yaml`,
`documents/paperless.yaml`, `homarr/homarr.yaml`, `arrs/janitorr.yaml`). Only `immich/`,
`openwebui/` and `open-archiver/` define services inline in `compose.yaml`. The caps were applied
where the services are actually defined. The stack-level effect is identical.

**2. The plan's "only 13 containers have any limit, all in buzz" is wrong.**

Six further `mem_limit` entries already existed outside buzz, and were missed for exactly the same
reason as deviation 1 - they live in included files that a `stacks/selfhosted/*/compose.yaml` glob
never sees:

```
automation/n8n-postgres.yaml   1g
automation/n8n.yaml            4g
mattermost/mattermost-db.yaml  512m
mattermost/mattermost.yaml     1g
monitoring/cadvisor.yaml       1g
monitoring/prometheus.yaml     2g
```

This does not change any cap chosen here, but it does mean the pre-existing capped population was
larger than the plan assumed. `n8n` at `4g` is worth a look in a later pass - it is the single
largest cap in the estate and exceeds every cap added today.

**3. The `grep -c mem_limit stacks/selfhosted/*/compose.yaml` check could not work as written**,
for the same reason. Substituted an equivalent, stronger check - see below.

## Which `postiz` is real

Both `postiz/postiz.yaml` and `social/postiz.yaml` define `container_name: postiz`. **Capped
`stacks/selfhosted/postiz/postiz.yaml`**; left `social/` alone. Evidence:

- `postiz/` has a real `.env`; `social/` has only `.env.sample`. With `env_file: .env` and no
  `required: false`, the social stack cannot start at all.
- `postiz/postiz.yaml` carries the MCP traefik router (`/mcp` PathPrefix, `chain-no-auth`).
  That endpoint is live and registered in neocortex. `social/postiz.yaml` has no MCP router.
- Bind targets differ: `/mnt/fast/appdata/postiz/*` vs `/mnt/fast/appdata/social/postiz/*`.

`social/postiz.yaml` reads as the stale/alternate definition. Not deleted - out of scope.

## Verification

| Check | Result |
|---|---|
| `terraform fmt -check` in `infra/` | clean, rc=0 |
| `terraform validate` in `infra/` | `Success! The configuration is valid.` |
| New `mem_limit` lines in diff | **exactly 12** (`git diff -U0 -- stacks/ \| grep -c '^+.*mem_limit'`) |
| YAML parses + cap on the right service | 12/12 PASS via `yaml.safe_load` + assertion on service key, `container_name` and value |
| `immich_postgres` untouched | confirmed `mem_limit = None` on svc `database` |
| Compose renders the caps | `postiz`/`openwebui`/`open-archiver`/`homarr`/`arrs` render `2147483648`, `1073741824`, `1610612736` - compose accepts the field |
| `docker compose config -q` - postiz, openwebui, open-archiver, homarr, arrs | **clean** |
| `docker compose config -q` - immich, media, automation, documents | fails on env only; **byte-identical failure at HEAD** |
| Credentials in diff | none (`grep -iE 'password\|token\|secret\|api[_-]?key\|credential'` over the full diff: no matches) |

The four `config -q` failures were proven pre-existing by extracting `HEAD` to a scratch tree with
`git archive` and running the same command there:

- `media`, `automation` - `env file /mnt/fast/stacks/.../.env not found`. These use **absolute**
  `env_file` paths that only resolve on LXC 100.
- `documents` - same, repo-relative `.env`, not present on the workstation.
- `immich` - unset `${UPLOAD_LOCATION}`/`${DB_DATA_LOCATION}` produce an empty volume spec. With
  dummy values supplied, HEAD and the current tree fail **identically** on a pre-existing schema
  complaint (`services.immich-machine-learning.group_add items at 0 and 1 are equal`).

No env values were invented.

## Skipped, and why

- **`terraform plan`** - not run. The provider endpoint is `https://${var.proxmox_host}:8006/`
  with credentials in `terraform.tfvars`; a plan authenticates against and reads the live Proxmox
  host. Instruction was to skip if it needs provider auth or touches the live host. It does.
- **`terraform apply`** - explicitly out of scope. Note that `memory` is **not** in
  `lxc-selfhost.tf`'s `ignore_changes` list, so Terraform *will* act on this. Expect exactly one
  in-place update: LXC 102 memory 8192 -> 3072. Read the plan before applying - the LXC 100 destroy
  landmine is in the same state.
- **Deploying / restarting containers** - nothing was touched. `mem_limit` applies on container
  **recreate**, not restart, so these caps are inert until the user runs
  `docker compose -f <file> up -d` per edited stack.
- **`immich_postgres` (564 MB)** - skipped deliberately per the plan. Capping a database without
  tuning `shared_buffers`/`work_mem` invites an OOM kill mid-write.

## Observations for later (not acted on)

1. `immich-machine-learning` has **duplicate entries in `group_add`**, which compose reports as a
   schema error. Pre-existing, unrelated, one-line fix.
2. `stacks/selfhosted/postiz/.env` and `automation/.env`, `homarr/.env`, `arrs/.env` exist on
   disk in a **public** repo. They appear untracked/ignored - worth confirming with
   `git check-ignore` that none is committed.
3. `n8n` is capped at `4g`, larger than anything added today, and was invisible to the plan's
   survey.
4. These caps bound one runaway service each. They do **not** make the total arithmetically safe -
   the sum of caps deliberately exceeds LXC 100's own 24 GB cap. The real fix remains the
   32 GB -> 64 GB RAM upgrade (DIMM 1 is empty).
