# Quick Task 260906-e6l: Bound atlantis memory oversubscription

**Created:** 2026-09-06
**Status:** Ready for execution

## Why

atlantis has **29,686 MB** usable RAM. The two running LXCs are capped at **32,768 MB** combined —
**3,082 MB oversubscribed** before ZFS ARC asks for its 3,113 MB `c_max`.

This is not theoretical. Measured on the live host 2026-09-05/06:

| Reading | Value |
|---|---|
| `memory_available_bytes` (host) | **709 MB** of 29.7 GB |
| ARC `size` | **910 MB** — *below* its own `c_min` of 972 MB |
| Swap in use | ~952 MB |
| Load average | **68** with CPU **77% idle**, PSI io `full` ~30% |

`infra/variables.tf:262-267` already records what that state arms:

> atlantis has 28 GB total and a live kernel bug where memory pressure drives compaction,
> compaction fires the amdgpu MMU notifier, and `amdgpu_hmm_invalidate_gfx` NULL-derefs — which
> wedged the whole estate for ~6 hours on 2026-08-31.

On 2026-09-05 the same pressure stalled dispatcharr's buffer and froze live TV for ~95 s.

## Measured evidence (cgroup high-water marks, 5 d 15 h window)

```
LXC 100 (selfhost)   current 21.65 GB   peak 23.52 GB   max 24.00 GB
LXC 102 (mpe)        current  1.77 GB   peak  2.17 GB   max  8.00 GB
```

Two facts drive this plan:

1. **mpe is massively over-capped** — it peaked at 2.17 GB against an 8 GB cap (27%).
2. **LXC 100 peaked at 23.52 GB of its 24 GB cap** — within 0.48 GB of its own ceiling.

*Caveat, stated so it is not over-read:* cgroup `memory.current`/`memory.peak` include reclaimable
page cache, so 23.52 GB is not 23.52 GB of anonymous memory. `docker stats` totalled 19.03 GB
across 103 containers. The peak still bounds the worst case the kernel had to service.

## Scope

Two changes. **Code only — no `terraform apply`, no container restarts.**

### Task 1 — `infra/variables.tf`: `mpe_memory_mb` 8192 → 3072

3072 MB sits **42% above** mpe's observed 5-day peak of 2.17 GB. It ends the oversubscription:
24576 + 3072 = **27,648** on a 29,686 MB host, leaving 2,038 MB for the host and ARC (whose
`c_min` is 972 MB).

Rejected 4096: it leaves only 1,014 MB for host + ARC, which re-creates the starved-ARC condition
this task exists to remove.

LXC 102 runs ERPNext (frappe backend, scheduler, two queue workers, mariadb), n8n, traefik and
cloudflared — 14 containers. ERPNext background jobs are bursty, which is why the cap is set from
the observed peak with headroom rather than from current usage.

Update the existing heredoc description in the same style as the note already there (which records
the 20480 → 8192 reconcile): state the new number, the measured peak it derives from, and the date.

**Do not run `terraform apply`.** `memory` is *not* in `lxc-selfhost.tf`'s `ignore_changes` list
(only `started`, the password, and `mount_point` are), so Terraform *will* act on this — unlike
bind-mount edits, which plan clean and do nothing. Given the documented LXC 100 destroy landmine,
the apply is the user's call. Show what the plan would do; do not execute it.

### Task 2 — `mem_limit` on the largest uncapped containers

Only 13 of 103 containers have any limit today; all 13 are in `stacks/selfhosted/buzz/compose.yaml`,
which already establishes the convention and comment style to follow.

Measured `docker stats` 2026-09-06, with the cap to add:

| Container | File | Measured | `mem_limit` | Ratio |
|---|---|---|---|---|
| `immich_server` | `immich/compose.yaml` | 1720 MB | `3g` | 1.8× |
| `dispatcharr` | `media/compose.yaml` | 1299 MB | `3g` | 2.4× |
| `jellyfin` | `media/compose.yaml` | 1022 MB | `3g` | 3.0× |
| `postiz` | `postiz/compose.yaml` | 969 MB | `2g` | 2.1× |
| `ai-docling` | `openwebui/compose.yaml` | 912 MB | `2g` | 2.2× |
| `open-archiver` | `open-archiver/compose.yaml` | 891 MB | `2g` | 2.3× |
| `ai-openwebui` | `openwebui/compose.yaml` | 609 MB | `1536m` | 2.5× |
| `pwpush` | `automation/compose.yaml` | 565 MB | `1g` | 1.8× |
| `paperless` | `documents/compose.yaml` | 553 MB | `1536m` | 2.8× |
| `homarr` | `homarr/compose.yaml` | 462 MB | `1g` | 2.2× |
| `janitorr` | `arrs/compose.yaml` | 431 MB | `1g` | 2.4× |
| `ai-tika` | `openwebui/compose.yaml` | 372 MB | `1g` | 2.7× |

Deliberately generous on three:
- **`dispatcharr` 3g** — live-stream buffers scale with concurrent viewers. Under-capping this
  OOM-kills the exact stream this whole task started from.
- **`jellyfin` 3g** — hardware transcode is deliberately off (D-30 amdgpu mitigation), so
  transcodes are CPU-side and bursty, and library scans spike independently.
- **`immich_server` 3g** — upload + thumbnail generation bursts.

**SKIPPED, deliberately: `immich_postgres` (564 MB).** Capping a database without also tuning
`shared_buffers` / `work_mem` invites an OOM kill mid-write. A killed Postgres is a corruption and
recovery problem, which is strictly worse than the memory it would reclaim. Tuning Postgres is its
own task with its own testing; it does not belong in a quick change.

**Honest limitation:** these caps bound *one runaway service*. They do **not** prevent aggregate
exhaustion — the sum of the caps exceeds LXC 100's own 24 GB cap, and is meant to. The goal is that
no single container can be the cause, not that the total is arithmetically safe. The total is what
the RAM upgrade fixes.

## Out of scope

- `terraform apply` — user's call, see Task 1.
- Deploying or restarting containers — `mem_limit` takes effect on recreate; see deploy step below.
- Retiring unused services (AI stack / open-archiver / postiz ≈ 4.2 GB) — needs the user's judgement
  on what is still wanted.
- The 32 GB → 64 GB RAM upgrade (DIMM 1 is empty; max 64 GB). The real fix, but it is hardware.

## Verification

- `terraform fmt -check` and `terraform validate` in `infra/` both clean.
- `docker compose -f <file> config -q` parses clean for every edited compose file.
- `grep -c mem_limit` across `stacks/selfhosted/*/compose.yaml` rises by exactly 12.
- No credential, token or password appears in the diff (repo is public).

## Deploy step (user runs when ready)

`mem_limit` only applies on container **recreate**, not restart:

```bash
ssh root@172.16.1.159
cd /mnt/fast/stacks && git pull
docker compose -f stacks/selfhosted/<stack>/compose.yaml up -d   # per edited stack
```

Terraform side, separately and with the plan read carefully:

```bash
cd infra && terraform plan    # expect exactly one in-place update: LXC 102 memory 8192 -> 3072
```
