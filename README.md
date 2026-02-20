# Selfhost Stacks

This repository is split into two clean domains:

- `infra/` — Terraform for Proxmox host prep + workload provisioning
- `stacks/` — Docker Compose stacks that run in `selfhost` LXC (`VMID 100`)

## Current Platform

- Proxmox host: `172.16.1.158`
- LXC `100` (`selfhost`): `172.16.1.159` (Docker runtime)
- VM `102` (`Cerebro`): Ubuntu 24.04 at `172.16.1.160`

## Repository Layout

- `infra/`
  - Host bootstrap and ZFS prep
  - LXC `100` provisioning (Docker + mounts + GPU device mapping)
  - VM `102` provisioning (Ubuntu 24.04 + static IP + GPU passthrough + Docker/Ollama/Cerebro provisioning)
- `stacks/`
  - `arrs/`, `media/`, `traefik/`, `openwebui/`, etc.
  - `wrappers/` (legacy app wrappers)
- `scripts/`
  - Utility scripts for backup/restore/ops

## Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

## Docker Stack Operations

Run these inside `selfhost` (`ssh root@172.16.1.159`) from repo root `/mnt/fast/stacks`:

```bash
docker compose -f stacks/traefik/compose.yaml config
docker compose -f stacks/traefik/compose.yaml up -d
docker compose -f stacks/arrs/compose.yaml up -d
docker compose -f stacks/media/compose.yaml up -d
```

## Notes

- Terraform is authoritative for host/LXC/VM infrastructure.
- Compose stack runtime content belongs under `stacks/`.
- Historical docs/scripts removed from head can be recovered via git history.
