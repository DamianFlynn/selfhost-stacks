# Quick Task 261108-lp2: Deploy Termix stack

**Created:** 2026-11-08
**Branch:** main

## Goal
Deploy the already-defined Termix stack (web SSH/terminal, `terminal.deercrest.info`).
It was classified DORMANT (`profiles: ["dormant"]`, 2026-09-25) and never ran.
Operator confirmed it never worked and nothing important is configured — clean start.

## Tasks
1. Remove `profiles: ["dormant"]` from `stacks/selfhosted/termix/termix.yaml` so it runs
   as a normal auto-restarting stack. Leave image (release-2.4.1), t3_proxy network,
   termix_data volume, and traefik+chain-authelia labels unchanged.
2. Commit + push to main (atomic).
3. Host deploy (operational): ensure `/mnt/fast/appdata/termix/data` exists 568:568,
   `git pull`, `docker compose -f stacks/selfhosted/termix/compose.yaml up -d`.
4. Verify container healthy and `terminal.deercrest.info` returns an Authelia redirect.

## Verification
- `docker ps` shows termix Up.
- `terminal.deercrest.info` → 302/200 via Authelia (not 404/502).
