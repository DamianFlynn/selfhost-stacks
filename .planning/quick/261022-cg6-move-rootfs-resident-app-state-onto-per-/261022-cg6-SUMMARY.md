---
quick_id: 261022-cg6
status: complete
date: 2026-10-22
completed: 2026-10-23
---

# 261022-cg6 — rootfs-resident app state onto per-app ZFS datasets

## Outcome

Six apps whose only copy of state lived on the LXC 100 rootfs (outside every ZFS snapshot and
backup) now run from their own `fast/appdata/*` datasets. Variant H: every mount hot-plugged into
the running container (mp32–mp36); LXC 100 never restarted.

| App | Mount | Downtime | Proof vs PREFLIGHT baseline |
|---|---|---|---|
| monitoring | mp34 (quota 25G) | 21 s | Grafana ok; Prometheus lowest ts unchanged; up 10/10 |
| airtrail | mp35 (16K) | 28 s | flights 374 |
| trek | mp33 | 78 s (incl. 4.3.4 pull) | healthy; named volumes → binds |
| n8n | inside existing `automation` dataset (no new mount) | 7 s | workflow_entity 70 |
| teslamate | mp32 (16K) | 8 s | drives max(id) 510, positions 688075, charging 25; pg_dump fence kept |
| silo | mp36 (16K) | 0 (dormant) | copied, kept stopped |

Every copy passed `scripts/appdata-copy-verify.sh` (owner/mode/size/mtime + sha256 manifests).

## Reconciliation

- Terraform: mp32–mp36 `mount_point` blocks added; plan with `mount_point` lifted from
  `ignore_changes` = `0 to add, 1 to change, 0 to destroy` (the one change is the pre-existing mpe
  `memory.dedicated` drift). Never applied.
- Backups: full sends `@backup-20261022-cg6`, then the 2026-10-23 00:15 incremental logged
  `DONE send_rc=0` for all five. `check-backup-freshness.sh` exit 0.
- `check-music-freeze.sh` interpolated-path pin 9 → 8 (n8n became a literal path).

## Task 6 — old copies deleted 2026-10-23

Preconditions held (send_rc=0 ×5, freshness exit 0, operator confirmed TeslaMate/AirTrail/TREK/n8n).
Guarded delete removed `/mnt/fast/appdata/{monitoring,airtrail,silo}.rootfs-pre-cg6`,
`/automation/n8n-postgres.rootfs-pre-cg6` and volumes `trek_trek_{data,uploads}`,
`teslamate_teslamate-{db,grafana-data,import}`. `/` 86G → 83G used (45%). Post-check counts 0 and 0.
Kept: TeslaMate `.dump` fences (`pgdumps/`, `/mnt/tank/backups/teslamate-db/`), `/root/cg6/` proofs.

## Follow-up

- Paperless `documents` is also rootfs-resident (bind-type named volumes) — its own quick task.
- `fast/appdata/buzz` is still backed up nightly though Buzz is retired.
