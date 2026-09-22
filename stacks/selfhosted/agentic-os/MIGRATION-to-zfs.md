# Adopting a dedicated ZFS dataset for the agentic-os Postgres

**Status: OPTIONAL TIDY-UP. The urgent problem is already fixed.**

On 2026-09-22 the data was moved off the ext4 root onto the **`automation`** dataset, with no
reboot and no new mount point — see "What was already done". It now lives at
`/mnt/fast/appdata/automation/agentic-os/postgres` on ZFS with 1.3 T free.

What remains is cosmetic-plus: giving the database **its own** dataset, so it gets independent
quota and snapshots instead of sharing `automation` with CouchDB and the memory stack. Worth
doing at the next reboot you were having anyway. **Not worth a reboot of its own.**

**What it costs:** a reboot of LXC 100, so **every container on that host stops** — Traefik,
Authelia, Immich, the \*arrs, Ollama, ~97 of them. Budget for the reboot, not for the 754 MB copy.

**Do NOT use `terraform apply` for this.** See "Why this is a manual act" below — it would not add
the mount, and it would silently shrink another container's RAM.

---

## What was already done (2026-09-22) — the part that mattered

`/mnt/fast/appdata/agentic-os/postgres` was on `/dev/mapper/pve-vm--100--disk--0`, the container's
**ext4 root**, holding the live v1 memory store: **17,225 `memory_chunks` from 1,185 sources,
754 MB**. `agentic-os` predated the rule that every `appdata` path must be a named dataset, and
nothing asserted it.

Damian chose the interim fix over a reboot, and it is complete:

- `pg_dump -Fc` taken first — 134 M, on the `automation` dataset.
- Copied with `tar` (**there is no `rsync` on LXC 100**) to
  `/mnt/fast/appdata/automation/agentic-os/postgres`. Verified before starting: **790,042,734
  bytes and 1,890 files on both sides**, ownership preserved (`568:568` parent, `0:0` for `18/`),
  destination confirmed `zfs` by `findmnt`.
- `compose.yaml` repointed, database restarted **healthy**, and the counts re-read as
  **17,225 / 1,185 / 139** — identical to the baseline — plus a real `source_path` read.
- The old copy was moved to `/root/agentic-os-postgres-ext4-SUPERSEDED-20260922` and
  `/mnt/fast/appdata/agentic-os` **no longer exists**, so nothing can silently start on the stale
  directory if someone reverts the compose path later.

**Still to reclaim, with an owner and a trigger.** That superseded copy is 754 MB on ext4, kept
deliberately as a rollback. Damian's decision (2026-09-22): **it goes at the close of neocortex v2
Phase 3**, *"as we should be confident it's not needed"* — by then the store will have served the
API, the legacy bridge and the indexer for a whole phase. It is a checklist item in **TODO-324**
so it has a trigger rather than a good intention.

Before deleting, confirm the live store is still the `automation` copy — if anything repointed
`compose.yaml` back, this directory **is** the live store:

```sh
ssh root@172.16.1.159 "docker inspect agentic-os-db --format '{{json .HostConfig.Binds}}'"
# must show /mnt/fast/appdata/automation/agentic-os/postgres
ssh root@172.16.1.159 'rm -rf /root/agentic-os-postgres-ext4-SUPERSEDED-20260922; df -h /'
```

Root is at **66 % with 41 G free** (it was 80 % / 25 G before the image prune), so there is no
pressure to hurry.

## Why you might still want the dedicated dataset

Sharing `automation` means the database has no quota or snapshot boundary of its own — it sits
alongside CouchDB's data and the memory stack's `node_modules` and model cache. `immich` models
the alternative with its own `immich/postgres` child dataset. This is a real but modest benefit.

Full finding: `neocortex-platform` →
`planning/neocortex-v2/findings/2026-09-22_the-v1-memory-store-is-on-lxc-100s-root-disk.md`

## What is already staged for it

- `zfs create fast/appdata/agentic-os` on **atlantis** (172.16.1.158), `chown 568:568`, `chmod 0755`.
  Empty, lz4, no quota — matching `automation`, `immich` and `hoarder`. **Not mounted.**
- A `mount_point` block is committed in `infra/lxc-selfhost.tf` — as **documentation**, see below.
- Because the data already moved, **every step below starts from the `automation` path**, not
  from ext4.

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
the mount" would not add it *and* would cut that container's RAM from 8 GB to 3 GB.

**Owner: the self-hosted agent**, told 2026-09-22. Re-check the plan is clean before any apply
here; do not assume it has been reconciled just because it was reported.

## The trap this runbook exists to avoid

Mounting the **empty** dataset at `/mnt/fast/appdata/agentic-os` gives you a second, empty home
while the real data sits at `/mnt/fast/appdata/automation/agentic-os/postgres`. If `compose.yaml`
is repointed at the new path before the data is copied there, **Postgres initialises a fresh empty
cluster** and the store looks wiped.

**So the copy happens first, and `compose.yaml` is repointed last** — step 7, not step 4.

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
# NOTE: there is no rsync on LXC 100 — use tar.
mkdir -p /mnt/fast/appdata/automation/_agentic-os-migration/postgres
tar -C /mnt/fast/appdata/automation/agentic-os/postgres -cpf - . \
  | tar -C /mnt/fast/appdata/automation/_agentic-os-migration/postgres -xpf -
du -sb /mnt/fast/appdata/automation/agentic-os/postgres \
       /mnt/fast/appdata/automation/_agentic-os-migration/postgres   # must match
```

`tar -p` preserves ownership: run inside the container, uids are container-native, and the idmap
(`u 568 568 1`, container root → host 100000) is handled by Proxmox on the way out.

### 3. Move the original aside — do NOT delete it yet

Out of the mount path, so the new mount lands on a clean directory *and* the original survives
until the new copy is proven.

```sh
mv /mnt/fast/appdata/automation/agentic-os/postgres /mnt/fast/appdata/automation/agentic-os/postgres-PREVIOUS
ls -ld /mnt/fast/appdata/automation/agentic-os/postgres-PREVIOUS
```

Still on ZFS, so this costs no root-disk space. Step 7 removes it.

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
mkdir -p /mnt/fast/appdata/agentic-os/postgres
tar -C /mnt/fast/appdata/automation/_agentic-os-migration/postgres -cpf - . \
  | tar -C /mnt/fast/appdata/agentic-os/postgres -xpf -
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

Remember to repoint `compose.yaml` back to `/mnt/fast/appdata/agentic-os/postgres` and commit it,
**before** starting in step 6 — otherwise the container keeps using the `automation` copy and this
whole exercise changes nothing.

```sh
rm -rf /mnt/fast/appdata/automation/agentic-os/postgres-PREVIOUS
rm -rf /mnt/fast/appdata/automation/_agentic-os-migration
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
mv /mnt/fast/appdata/automation/agentic-os/postgres-PREVIOUS /mnt/fast/appdata/automation/agentic-os/postgres
# revert compose.yaml to the automation path
cd /mnt/fast/stacks/stacks/selfhosted/agentic-os && docker compose up -d
```

Also revert the `mount_point` block in `infra/lxc-selfhost.tf` so the file keeps matching reality.

The `pg_dump` from step 0 is the backstop if both copies are somehow lost.

## Afterwards

Update the finding's status, and note in `STANDARDS.md` that `agentic-os` is no longer the
exception to "every appdata path is a named dataset" — assuming a check is added that would catch
the next one, which is the part that was missing all along.
