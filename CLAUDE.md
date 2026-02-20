# CLAUDE.md

Repository guidance for code agents and maintainers.

## Scope Split

- `infra/`: Terraform for Proxmox host setup + workload provisioning
- `stacks/`: Docker Compose stack definitions deployed to LXC `100` (`selfhost`)

## Platform

- Proxmox host: `172.16.1.158`
- LXC `100` (`selfhost`): `172.16.1.159`
- VM `102` (`Cerebro`, Ubuntu 24.04): `172.16.1.160`

## Infrastructure Rules

- Terraform is authoritative for host/LXC/VM resources.
- Do not manually drift critical Proxmox config Terraform manages.
- Keep provisioning logic in `infra/` only.

## Stack Rules

- Keep all compose stacks under `stacks/<stack>/`.
- `stacks/traefik/compose.yaml` defines shared proxy network(s).
- Stack ops run from repo root at `/mnt/fast/stacks`.

## Common Commands

```bash
# Terraform
cd infra
terraform plan
terraform apply

# Compose
ssh root@172.16.1.159
cd /mnt/fast/stacks
docker compose -f stacks/traefik/compose.yaml up -d
docker compose -f stacks/arrs/compose.yaml up -d
```

## Storage and Permissions

- Repo path on host/LXC: `/mnt/fast/stacks`
- Appdata path: `/mnt/fast/appdata`
- Service account: `apps:apps` (`568:568`)
- GPU groups: `video:44`, `render:110`
