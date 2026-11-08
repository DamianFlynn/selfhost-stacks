---
status: complete
---
# Quick Task 261108-lp2: Deploy Termix stack — SUMMARY

**Status:** complete ✓  •  **Date:** 2026-11-08  •  **Commit:** 382b2f8c

## What changed
- Removed `profiles: ["dormant"]` from `stacks/selfhosted/termix/termix.yaml` so Termix
  runs as a normal auto-restarting stack (was parked dormant 2026-09-25, never worked).
- Everything else unchanged: image `ghcr.io/lukegus/termix:release-2.4.1`, `t3_proxy`
  network, `termix_data` → `/mnt/fast/appdata/termix/data`, traefik + `chain-authelia`
  for `terminal.deercrest.info`.

## Deploy + verify
- Host `git pull` → `docker compose -f stacks/selfhosted/termix/compose.yaml up -d`.
- `docker ps`: **termix Up, healthy**. Logs: schema migration + DB init clean, backend
  started (223 ms), 0 hosts (fresh — nothing important was configured, as operator noted).
- External: `terminal.deercrest.info` → **HTTP 302 to auth.deercrest.info** (Authelia),
  i.e. routed and auth-protected (not 404/502). It genuinely works this time.

## Notes
- appdata dir `/mnt/fast/appdata/termix/data` already existed (apps:apps / 568:568); not wiped.
- Ports 8080 + 30001-30006 are container-internal (not host-published); access is via traefik.
