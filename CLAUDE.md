# CLAUDE.md

Repository guidance for code agents and maintainers.

## Documentation

- **[NETWORK.md](NETWORK.md)**: Complete network infrastructure map, all hosts, IPs, access methods, and cleanup tasks

## Scope Split

- `infra/`: Terraform for Proxmox host setup + workload provisioning
- `stacks/`: Docker Compose stack definitions deployed to LXC `100` (`selfhost`)

## Platform

- Hardware: Minisforum NS5Pro
- Proxmox host "atlantis": `172.16.1.158` (Proxmox VE 9.1)
- LXC `100` (`selfhost`): `172.16.1.159` (main Docker host - 78+ containers)

## Infrastructure Rules

- Terraform is authoritative for host/LXC/VM resources.
- Do not manually drift critical Proxmox config Terraform manages.
- Keep provisioning logic in `infra/` only.

## Stack Rules

- Keep selfhosted compose stacks under `stacks/selfhosted/<stack>/`.
- `stacks/selfhosted/traefik/compose.yaml` defines shared proxy network(s).
- Stack ops run from repo root at `/mnt/fast/stacks`.
- Cerebro VM stacks archived to agent-os/Archives (no longer managed here).

## Common Commands

```bash
# Terraform
cd infra
terraform plan
terraform apply

# Compose
ssh root@172.16.1.159
cd /mnt/fast/stacks
docker compose -f stacks/selfhosted/traefik/compose.yaml up -d
docker compose -f stacks/selfhosted/arrs/compose.yaml up -d
```

## Storage and Permissions

- Repo path on host/LXC: `/mnt/fast/stacks`
- Appdata path: `/mnt/fast/appdata`
- Service account: `apps:apps` (`568:568`)
- GPU groups: `video:44`, `render:110`
