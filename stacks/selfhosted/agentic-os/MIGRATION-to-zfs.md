# Moving the agentic-os Postgres off the ext4 root

**Status: STAGED, not executed.** The dataset exists and the Terraform block is committed.
Nothing has moved. Run this in a maintenance window.

**What it costs:** a reboot of LXC 100, so **every container on that host stops** — Traefik,
Authelia, Immich, the \*arrs, Ollama, ~97 of them. Budget for the reboot, not for the 754 MB copy.

**Do NOT use `terraform apply` for this.** See "Why this is a manual act" below — it would not add
the mount, and it would silently shrink another container's RAM.

---

## Why

`/mnt/fast/appdata/agentic-os/postgres` is on `/dev/mapper/pve-vm--100--disk--0` — the container's
**ext4 root**, not ZFS. `agentic-os` predates the rule that every `appdata` path must be a named
dataset, and nothing asserted it. `immich` already does this correctly with its own
`immich/postgres` child dataset.

It holds **17,225 `memory_chunks` from 1,185 sources, 754 MB** — the live v1 memory store, which
the neocortex memory API reads through a read-only bridge. Phase 4 will roughly double the
footprint on that disk, which is why this wants doing first.

Full finding: `neocortex-platform` →
`planning/neocortex-v2/findings/2026-09-22_the-v1-memory-store-is-on-lxc-100s-root-disk.md`

## Already done (2026-09-22)

- `zfs create fast/appdata/agentic-os` on **atlantis** (172.16.1.158), `chown 568:568`, `chmod 0755`.
  Empty, lz4, no quota — matching `automation`, `immich` and `hoarder`.
- A `mount_point` block is committed in `infra/lxc-selfhost.tf` — as **documentation**, see below.

## Why this is a manual act, not `terraform apply`

`mount_point` is in the container resource's `ignore_changes`, and the lifecycle block says so
in as many words:

> *"with this here, Terraform will no longer act on REAL mount_point changes either. Adding or
> removing a bind mount by editing this file will plan clean and do nothing. Until the provider
> bug is fixed, bind-mount changes are a deliberate manual act."*

Confirmed rather than assumed — `terraform plan` on 2026-09-22 showed **zero diff for container
100** after the block was added. The committed block keeps the file honest about what the
container has; it is not what puts it there.

**⚠ And an apply would do harm.** The same plan showed unrelated pre-existing drift: container
**102 (`mpe`) plans `memory.dedicated 8192 -> 3072`**. Anyone running `terraform apply` to "add
the mount" would not add it *and* would cut that container's RAM from 8 GB to 3 GB. Resolve that
drift separately, on purpose.

## The trap this runbook exists to avoid

Mounting the **empty** dataset over the directory that currently holds the live data **hides** it
rather than moving it — and it still occupies the 754 MB on ext4, invisibly. Postgres comes back
to an empty data directory and initialises a new one.

**So the mount and the copy are one operation, and the copy goes first.**

---

## The window

### 0. Back up first

This is the live v1 store. Take whatever backup you normally would and confirm it before step 1.

```sh
ssh root@172.16.1.159
set -a; . /mnt/fast/stacks/stacks/selfhosted/agentic-os/.env; set +a
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" agentic-os-db \
  pg_dump -U "$POSTGRES_USER" -d agentic_os -Fc \
  > /mnt/fast/appdata/automation/agentic_os-$(date -u +%Y%m%dT%H%M%SZ).dump
ls -lh /mnt/fast/appdata/automation/agentic_os-*.dump
```

### 1. Record the truth, so the end can be compared to it

```sh
docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" agentic-os-db \
  psql -U "$POSTGRES_USER" -d agentic_os -Atc \
  "SELECT 'chunks', count(*) FROM memory_chunks
   UNION ALL SELECT 'sources', count(*) FROM memory_sources
   UNION ALL SELECT 'events',  count(*) FROM search_events;"
# expected 2026-09-22: chunks|17225  sources|1185  events|139   (events grows with use)
```

**Do not use `pg_stat_user_tables.n_live_tup`** — after a restart it reports `memory_chunks|0`
while the table holds 17,225 rows. Use `count(*)`.

### 2. Stop Postgres, copy to staging on ZFS

Staging goes on `automation`, which is **already** a mounted dataset, so it survives the restart.

```sh
docker stop agentic-os-db
mkdir -p /mnt/fast/appdata/automation/_agentic-os-migration
rsync -aHAX --numeric-ids --info=progress2 \
  /mnt/fast/appdata/agentic-os/postgres/ \
  /mnt/fast/appdata/automation/_agentic-os-migration/postgres/
du -sh /mnt/fast/appdata/agentic-os/postgres \
       /mnt/fast/appdata/automation/_agentic-os-migration/postgres   # must match
```

`--numeric-ids` matters: run inside the container, uids are container-native, and the idmap
(`u 568 568 1`, container root → host 100000) is handled by Proxmox on the way out.

### 3. Move the original aside — do NOT delete it yet

Out of the mount path, so the new mount lands on a clean directory *and* the original survives
until the new copy is proven.

```sh
mv /mnt/fast/appdata/agentic-os/postgres /root/agentic-os-postgres-ext4-preserve
ls -ld /root/agentic-os-postgres-ext4-preserve
```

Still on ext4, still 754 MB. Step 7 reclaims it.

### 4. Add the mount and reboot — this is the outage

On **atlantis** (the PVE host, 172.16.1.158), not inside the container:

```sh
pct set 100 -mp32 /mnt/fast/appdata/agentic-os,mp=/mnt/fast/appdata/agentic-os
grep '^mp32' /etc/pve/lxc/100.conf        # confirm it is written
pct reboot 100
```

`mp0`–`mp31` are in use; 32 is the next free index. If that has changed, take
`grep -o '^mp[0-9]*' /etc/pve/lxc/100.conf | sed 's/mp//' | sort -n | tail -1` and add one.

Every container on LXC 100 stops and restarts here. Wait for it, then confirm the mount landed:

```sh
ssh root@172.16.1.159 'findmnt -T /mnt/fast/appdata/agentic-os -o TARGET,SOURCE,FSTYPE,AVAIL'
# SOURCE must read fast/appdata/agentic-os, FSTYPE zfs
```

### 5. Restore from staging

```sh
rsync -aHAX --numeric-ids --info=progress2 \
  /mnt/fast/appdata/automation/_agentic-os-migration/postgres/ \
  /mnt/fast/appdata/agentic-os/postgres/
ls -ldn /mnt/fast/appdata/agentic-os/postgres        # 568:568
ls -ldn /mnt/fast/appdata/agentic-os/postgres/18     # 0:0 (container root)
```

### 6. Start, and prove the data is the same data

```sh
cd /mnt/fast/stacks/stacks/selfhosted/agentic-os && docker compose up -d
docker ps --filter name=agentic-os-db     # healthy
```

Re-run **step 1's query**. The three numbers must match (`search_events` may have grown).
Then check the memory API still answers through the bridge:

```sh
curl -s https://cortex.deercrest.info/v1/health | jq '.legacy_bridge'
```

### 7. Reclaim the space — only once step 6 passed

```sh
rm -rf /root/agentic-os-postgres-ext4-preserve
rm -rf /mnt/fast/appdata/automation/_agentic-os-migration
df -h /       # ~754 MB lower
```

---

## If it goes wrong

Nothing is destroyed until step 7. To roll back after the mount is in place:

```sh
# inside LXC 100
docker stop agentic-os-db

# on atlantis — remove the mount and reboot again
pct set 100 -delete mp32
pct reboot 100

# inside LXC 100, once it is back: the ext4 copy is visible again at its old path
mv /root/agentic-os-postgres-ext4-preserve /mnt/fast/appdata/agentic-os/postgres
cd /mnt/fast/stacks/stacks/selfhosted/agentic-os && docker compose up -d
```

Also revert the `mount_point` block in `infra/lxc-selfhost.tf` so the file keeps matching reality.

The `pg_dump` from step 0 is the backstop if both copies are somehow lost.

## Afterwards

Update the finding's status, and note in `STANDARDS.md` that `agentic-os` is no longer the
exception to "every appdata path is a named dataset" — assuming a check is added that would catch
the next one, which is the part that was missing all along.
