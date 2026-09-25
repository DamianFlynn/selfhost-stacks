# Backup and Recovery Foundation for the Deer Crest Estate

**Status:** proposed plan; no implementation authorised by this document. **Scope:** the `backup` pool on the WD Elements USB disk, the decommissioned `hufflepuff` host as a second offline target, `fast/appdata` and the non-ZFS application state on LXC 100's ext4 root, `run-backup.sh` and `backup-incremental.sh` on atlantis, and the scheduling that neither currently has. **Explicitly out of scope:** the 25-container deploy debt, service classification, Postgres/Redis consolidation, `/dev/net/tun`, and the Silo evaluation — each is its own plan and none may start before this one's Definition Of Done is met. **Supersedes nothing.** This plan does not authorise wiping, selling or repurposing hufflepuff; it evaluates it as a target.

## Problem

The estate's stated governing constraint is *"I don't want to lose any of my context — I want to restructure smartly, not wipe and start over."* A restructuring programme is queued behind this plan. **That constraint is not currently met, and the gap is not small.**

Measured on 2026-09-25 against atlantis and LXC 100:

- `run-backup.sh` replicates exactly **seven datasets, all on `tank`** — Photos, the iCloud archive, the hufflepuff scavenge, an Immich `pg_dumpall`, Books, Music, and the MyBook music archive. Verified against `zfs list -r backup`.
- **Not one byte of `fast/appdata` has an off-box copy.** That is where every application's state lives.
- **Nothing schedules either script.** No systemd timer exists for `run-backup.sh` or `backup-incremental.sh`. Both work; both run only when a human runs them. The last full backup was 2026-09-22.
- `fast` carries **7 snapshots, 6 of which are dead 2025 `ix-apps` leftovers**. The only live one is `immich/postgres@pre-v3`.
- A further tier of state is **not on ZFS at all** — it is on LXC 100's ext4 root or in `/var/lib/docker/volumes`, so no `zfs send` can ever reach it: n8n's workflows and credentials (at `/automation/n8n-postgres`, not even under `/mnt`), Paperless documents and its OCR index, Teleport's cluster CA and audit log, TeslaMate, Dawarich location history, Grafana, Prometheus, the RustDesk keypair, Termix and Trek. Two anonymous Docker volumes (`janitorr`, `flaresolverr`) are the pattern `DEPLOYMENT.md` forbids.

The good news, and it reframes the work: **the real exposure is about 27 GB, not 169 GB.** `fast/appdata` totals 169 G, but **142 G of that is `fast/appdata/hoarder`**, which despite its name holds podsync's downloaded media — re-downloadable cache, not state. Karakeep, the thing the dataset is named after, is 979 KB. Against **11.0 T free on the `backup` pool**, the entire genuine gap fits with four orders of magnitude to spare.

So this is not a capacity problem. It is a configuration gap that has been sitting open, unscheduled and unnoticed, while a restructuring programme was being planned on top of it.

### Why the USB disk alone is not sufficient

The `backup` pool is a **single WD Elements USB disk** (`usb-WD_Elements_25A3_...`), 14.5 T, 3.50 T used, `copies=1` set deliberately. It is a good primary target and it already works. But it is:

1. **Non-redundant** — one vdev, one disk, by design (tank is the source, so a bad block is re-sent rather than self-healed).
2. **Attached to the machine it protects.** It does not survive atlantis dying, a PSU event, theft or fire.
3. **Always online**, so an accidental `zfs destroy`, a bad script or a compromised host can reach it.

That is one copy on one medium in one place. The failure modes that actually destroy estates — operator error propagating, and the whole machine going away — are precisely the ones it does not cover.

### Why hufflepuff is a genuine candidate, and what is wrong with it today

A normally-powered-off second target is the missing leg, and an **offline copy is immune to propagation** in a way an always-mounted USB disk is not. hufflepuff already exists, is already owned, and holds three 16 TB disks. Powered on by WoL or a smart switch for a weekly window, it is a credible second tier.

Four things must be established before it can be trusted with that role, and three of them are live problems:

1. ⚠️ **Powering it on restarts its old stack.** This is documented, it has already caused an incident (30 containers plus a Home Assistant VM ran beside production for two days in September, sharing indexer and usenet accounts), and **it is happening again right now**: measured 2026-09-25, `systemctl is-enabled docker` → `enabled`, `is-active` → `active`, with `immich_postgres`, `immich_redis` and `immich_machine_learning` up 13 hours and `immich_server` crash-looping. 30 containers are defined; 4 run because the rest lost their volumes when the pool was destroyed. **Any plan that powers this host on a schedule must disarm it first.**
2. **One of the three 16 TB disks was DEGRADED with "too many errors"** in the old raidz1. Whether that is the disk or was the controller/cable is unverified. A backup target built on an unverified disk is theatre.
3. **The OS disk is spoken for.** `/` lives on the Samsung 840 EVO (`sdc`), which was decided on 2026-09-22 to be flashed to EXT0DB6Q and deployed into the NUC after its Fanxiang S101Q failed. If the EVO leaves, hufflepuff needs a boot disk — the wiped Crucial M4 512 GB (`sdb`) is the candidate.
4. **`/` was never enumerated by the scavenge.** That job covered `/pool/*` and `/mnt/mediahub`; the OS disk holds 214 G of 915 G and the estate's own record is that *three gaps surfaced after the scavenge was declared complete*. The healthy `immich_postgres` running there today is direct evidence that application state exists on `/` that nobody has looked at.

### The honest alternative, and how it was settled

Keeping a whole server to hold a second copy has costs — power, space, one more thing to maintain, and old disks. A second USB disk is the obvious comparison, and this plan required it to be answered explicitly rather than assuming the server is free because it is already owned. The case for hufflepuff rests on *physical separation and being powered off*, not on capacity.

**DECIDED 2026-09-25 by the operator: keep hufflepuff.** Discard the failed 16 TB disk entirely rather than rebuild a raidz1; mirror the two survivors; move the OS to the Crucial M4 so the 840 EVO can be released to the NUC; rewrite the NixOS configuration to a new minimal generation rather than carry the old one forward. G1 below therefore no longer carries a keep-or-sell gate — it gathers the evidence that the execution plan needs. The execution itself is `hufflepuff-rebuild-as-backup-tier.plan.md`, which is this plan's G6 expanded.

## Solution

Build a **three-tier recovery position**, cheapest and most valuable first, and prove each tier by restore before relying on it.

```text
  LXC 100 (fast/appdata datasets)      LXC 100 ext4 root + docker volumes
   n8n? no — see tier 0 gap             n8n, paperless, teleport CA, teslamate,
            |                           dawarich, grafana, prometheus, rustdesk
            |                                        |
            |                            file-level dump into a ZFS dataset
            +--------------------+-------------------+
                                 |
                      atlantis: fast/appdata/*  +  tank/*
                                 |
                    zfs send -i  |  (scheduled, verified)
                                 v
        TIER 1  backup pool — WD Elements USB, 14.5 T, always attached
                                 |
                    zfs send -i  |  (weekly, host normally powered OFF)
                                 v
        TIER 2  hufflepuff — physically separate, offline between runs
```

### Tier 0 — close the ZFS gap (cheap, immediate, highest value per hour)

Extend the backup set from seven `tank` datasets to include `fast/appdata`, **excluding `fast/appdata/hoarder`**. That is roughly 27 GB of genuinely irreplaceable state against 11 T free, and it is a change to a script that already works, not new machinery.

`hoarder` is excluded on the explicit grounds that it is re-downloadable podsync media. That exclusion is a **decision with a stated reason**, recorded here so a future reader does not mistake it for an oversight — and it must be re-examined if anything non-media is ever written there. The dataset's misleading name is precisely the trap: the map that produced this plan initially attributed 143 GB to karakeep and corrected itself mid-investigation.

### Tier 0b — rescue the non-ZFS tier

State on the ext4 root cannot be reached by `zfs send`. Two options, and the plan must pick per service rather than globally:

- **Relocate to ZFS.** This is a **Terraform change**, not a `zfs create`: `/mnt/fast/appdata` is a dataset on atlantis, but LXC 100 receives only its *children* as `mp` binds, so a new child needs a new mount point declared in `infra/`. Correct long-term answer; costs a container restart each.
- **Dump into an existing dataset.** `pg_dumpall` for the Postgres instances (n8n, teleport, teslamate, dawarich), file-level copy for the rest, written into a dataset that is already replicated. Immediate, and the pattern already in use for Immich.

Do 0b by dump first — it closes the hole this week — and schedule relocation as follow-on work. **Do not let the better option delay the adequate one**; the current state is zero copies.

### Tier 1 — schedule and verify what already exists

`backup-incremental.sh` works and is proven (first incremental moved ~20 G, all seven snapshots present on the target). It has never been scheduled. Add a systemd timer, and — critically — **make failure visible**. A backup that silently stops is worse than none, because it manufactures false confidence. The estate has the exact precedent: `run-backup.sh` asserts its `pg_dumpall` is over 1 MB because a broken pipe exits 0 and leaves a tiny file that looks like a backup.

### Tier 2 — hufflepuff as an offline second copy, gated

Only after G1 answers whether it is worth keeping at all. If yes: disarm Docker permanently, verify the disks, rebuild a pool on **verified** members only, give it a boot disk, and replicate from tier 1 on a schedule that powers it on, receives, and powers it down. If no: sell it as originally planned and buy a second USB disk instead, which satisfies the same requirement with less to maintain.

### The ordering constraint

Tier 0 and tier 1 are independent of every open question about hufflepuff. **They must not wait for it.** The plan is explicitly sequenced so that the cheap, decisive work lands first and the hardware question is settled afterwards with evidence.

## Variables

- `ATLANTIS=172.16.1.158` (Proxmox host, owns all pools); `LXC100=172.16.1.159` (Docker host); `HUFFLEPUFF=172.16.1.21`, user `damian`, key auth from the workstation, creds `~/.claude/secrets/hufflepuff.env`.
- `BACKUP_POOL=backup` — single vdev `usb-WD_Elements_25A3_3242485330374E4E-0:0`. **Always address by `by-id`, never `/dev/sdX`**: this disk was `sdf` on hufflepuff and `sdd` on atlantis; USB letters are not stable across reboots.
- `SRC_DATASETS_TANK` — the existing seven. `SRC_DATASETS_FAST` — `fast/appdata/*` **minus** `fast/appdata/hoarder` (142 G, re-downloadable podsync media) and minus `fast/appdata/agentic-os` (96 K, empty orphan).
- `BACKUP_SCRIPTS=/usr/local/bin/{run-backup.sh,backup-incremental.sh}` on atlantis. `run-backup.sh` does FULL sends and **skips any dataset already present on the target**, so re-running it is a silent no-op; `backup-incremental.sh` is the update path.
- `ONROOT_STATE` — enumerate and pin at G1. Known members: `/automation/n8n-postgres`, paperless, teleport, teslamate, dawarich, grafana, prometheus, rustdesk, termix, trek, `/var/lib/docker/volumes` (19 volumes, 948.7 MB, 9 active), and `/mnt/fast/stacks-private/neocortex-platform` (236 MB, a separate repo — confirm it has a git remote before treating it as expendable).
- `RESTORE_TARGET` — a disposable dataset or a scratch LXC. **Never restore over a live path.**
- `TIMER_UNIT=backup-incremental.timer`; `ALERT_PATH` — the existing Grafana→Telegram route used by image-drift detection. Telegram credentials are a known open item (G4 of quick task 260918-c12) and must be confirmed working, not assumed.
- Free space at plan time, for later comparison: `backup` 11.0 T avail / 24% CAP; `fast` 1.40 T free / 22%; `tank` 8.08 T free / **88% CAP — past the ZFS performance threshold**; LXC 100 `/` **21 G free of 126 G, 83% used** (resolved 2026-09-25: pruned to 39 G free / 68%, reclaiming 18.93 GB). **Do not quote `docker system df`'s "60.9 GB reclaimable"** — it counts shared layers still held by running containers and still reports 60.9 GB *after* a full prune.

## Implementation Notes

### Measured state this plan is built on

| Fact | Value | Source |
|---|---|---|
| Datasets replicated off-box | 7, all `tank` | `zfs list -r backup`, 2026-09-25 |
| `fast/appdata` protected off-box | **0 bytes** | same |
| `fast/appdata` total | 169 G | `zfs list -r fast` |
| ...of which `hoarder` (podsync media) | **142 G** | same; contents confirmed `podsync/`, `karakeep/`, `freshrss/` |
| Genuine app state needing protection | **~27 G** | derived |
| `backup` pool free | **11.0 T** | `zpool list` |
| Live snapshots on `fast` | **1** (`immich/postgres@pre-v3`) | STACK-MAP.md §5 |
| Backup schedule | **none exists** | no timer unit |
| hufflepuff `docker` | **enabled + active**, 4 containers up 13 h | 2026-09-25 |

### Traps already paid for once — do not rediscover these

- **`zfs recv` does not create intermediate parents.** Every send in the first run died with `rc=141` (SIGPIPE) and `cannot open 'backup/media': dataset does not exist`. **`rc=141` on a `send | recv` pipeline means the receiver died** — read the recv stderr, not the exit code. Fix is `zfs create -p "$parent"` before each send.
- **A plain directory is not a dataset.** `/mnt/tank/backups/immich-db` was `mkdir -p`'d, so the send skipped it as `MISSING` while the dump sat there looking healthy.
- **Write scripts locally and pipe them over ssh.** A version written through a nested-quoted heredoc produced a literal `rc=${PIPESTATUS[0]}` in every log line, so success could not be confirmed from the log at all.
- **Never date anything on hufflepuff from `uptime`, `who -b` or file mtimes.** Both report ~811 days from a stale utmp; `/proc/uptime` reads 5.0 days and is the only honest source. Same failure shape as `docker ps` reporting `Up 2 weeks` for a container `inspect` showed as `exited 137`.
- **`rsync -a` fails writing to `tank`** (`mkstemp ... Operation not permitted`, `acltype=nfsv4` + `aclmode=restricted`) while printing stats that look like success and exiting 23. Use `rsync -rlt --no-p --no-o --no-g` for any file-level copy onto tank.
- **ZFS frees space asynchronously**; `zfs list` can lag a large delete by ~20 s. Do not assert on free space immediately after a destroy.

### Why `zfs send` and not rsync

Replication of snapshots means the second run is a cheap incremental rather than a full re-walk, and ZFS checksums both ends. This is already the established pattern and is not revisited here. File-level tooling is used **only** for the non-ZFS tier, where there is no alternative.

### What a backup is not

A snapshot on `fast` is a rollback point, not a backup — it dies with the pool. A `zfs send` to a disk attached to the same host is a backup against operator error and single-disk failure, not against loss of the host. **Neither is a backup until a restore has been performed.** This plan treats an unrestored copy as unproven, and its Definition Of Done is written accordingly.

### Deliberately not solved here

Tier 2 scheduling depends on the G1 keep-or-sell decision and is specified only to the point of that gate. The relocation of on-root state to ZFS is named as follow-on work with a Terraform dependency, not attempted inline. `tank` at 88% CAP is not fixed here and is recorded because it constrains the plans queued behind this one. The LXC image reclaim *was* done on 2026-09-25 (18.93 GB, 83% -> 68%) under `unblock-disarm-reclaim-close-backup-gap.plan.md`.

## Workflow

1. **Disarm hufflepuff and confirm intent (G0).** Establish whether the running Immich containers were started deliberately. If not: `systemctl disable --now docker`, confirm `is-enabled` → `disabled`, and confirm no `libvirt` autostart. **This is a safety action independent of the keep-or-sell decision** and is not contingent on the rest of the plan. Record what the four containers were doing and whether anything bound to them.

2. **Enumerate and baseline (G1).** Produce the pinned `ONROOT_STATE` inventory for **LXC 100** with sizes and owning service. Confirm `neocortex-platform` has a git remote. *(The hufflepuff half of this gate is closed: `/` was enumerated on 2026-09-25 — 212 G, of which 140 G is reclaimable Docker layers and ~18 G is genuinely irreplaceable application state on `/srv/appdata`. The keep decision is recorded above. SMART re-reads and serial identification move to the rebuild plan's G3, where they are acted on.)*

3. **Close the ZFS gap (G2).** Extend the backup set to `fast/appdata` minus the stated exclusions. Run a full send. Verify by dataset size and snapshot presence on the target, not by exit code.

4. **Rescue the non-ZFS tier (G3).** `pg_dumpall` per Postgres instance and file-level copies for the rest, into a replicated dataset, with a size assertion on every artefact. Re-run G2 so they reach the USB disk.

5. **Schedule and alert (G4).** Install `backup-incremental.timer`. Make a missed or failed run **visible** through the existing alert route — confirm that route works rather than assuming it, given its Telegram credentials are a known open item. A silent backup failure must be impossible to mistake for success.

6. **Prove by restore (G5).** Restore a representative set — one Postgres dump, one file tree, one full dataset — onto a **disposable** target. Reconcile counts and hashes. This gate, not G2, is what permits the queued restructuring plans to start.

7. **Stand up tier 2 (G6).** Delegated in full to `hufflepuff-rebuild-as-backup-tier.plan.md`: extract the unscavenged state, disarm permanently, rebuild the OS on the M4 with a minimal NixOS generation, build a mirror from the two verified 16 TB survivors, and implement the powered-on replication window. Prove a restore from tier 2 independently of tier 1. **G0 of that plan — disarming Docker — is a live safety action and does not wait for this plan's earlier gates.**

Each gate gets stable todos with owners, acceptance checks, evidence paths and a rollback. **No gate is passed on the strength of a command exiting 0.**

## Deliverables

1. A recorded decision on hufflepuff — keep as tier 2, or sell — with the measured numbers and the second-USB-disk alternative that it was weighed against.
2. hufflepuff disarmed: `docker` disabled, verified, and the September duplicate-stack incident closed rather than left recurring.
3. Pinned inventory of non-ZFS application state, by service, with size and chosen rescue method per entry.
4. An enumeration of hufflepuff's `/`, closing the gap the scavenge left.
5. Updated `run-backup.sh` / `backup-incremental.sh` covering `fast/appdata` with stated, reasoned exclusions.
6. A dump mechanism for the non-ZFS tier, with size assertions.
7. `backup-incremental.timer` installed, plus a **proven** alert path for failure and for silence.
8. A restore runbook and the evidence from an actual restore drill on a disposable target.
9. Follow-on work recorded, not silently dropped: relocating on-root state to ZFS (Terraform) and `tank` at 88% CAP. *(The image reclaim the deploy depended on is DONE — 18.93 GB, 2026-09-25.)*

## Definition Of Done

### Coverage

- Every stateful service in the estate is in exactly one of two lists: **replicated off-box**, or **explicitly and reasonedly excluded**. No service is unlisted. `fast/appdata/hoarder` appears on the exclusion list with its justification and a re-examination trigger.
- The non-ZFS tier is covered by dump or relocation. `n8n`'s workflows and credentials, Paperless's documents, and Teleport's CA are specifically confirmed present in the backup, because each is individually irreplaceable.
- `docker ps -a` on hufflepuff shows no container able to start on boot, and `systemctl is-enabled docker` returns `disabled`.

### Proof, not assertion

- **A restore has actually been performed** onto a disposable target and reconciled by count and hash. Until this is true, nothing in the restructuring programme starts.
- Backup success and failure are both observable without reading a log by hand: a failed run raises an alert, and so does a run that does not happen. The alert route has been driven, not assumed.
- Every verification distinguishes "checked and correct" from "could not look". A dataset that could not be read is reported as such and never counted as protected.
- No step in the chain treats exit code 0 as evidence. Size and content are asserted at every artefact boundary, per the `pg_dumpall` precedent.

### Decisions recorded

- The hufflepuff keep-or-sell decision is written down with its reason, so that a future reader meets an argument rather than a silence. If sold, the second-copy requirement is satisfied another way and that is stated.
- Any state deliberately left unprotected is a recorded decision with a named owner, not an omission.

### Not claimed

- This plan does not deliver offsite backup. Tier 2 on hufflepuff is *physically separate and offline*, which addresses propagation and host loss, but both tiers remain in one building. If fire or theft is in scope, that is a further plan and is explicitly not closed here.
- Restoring the estate is not the same as restoring a service. This plan proves data recovery; it does not prove a full rebuild of LXC 100 from bare metal, which depends on the Terraform work named as follow-on.

## Sources and constraints

- Measured evidence: `.planning/analysis/STACK-MAP.md` (672 lines, measured 2026-09-25 against LXC 100 and atlantis at commit `3798ed1`; read its §0 contradictions before trusting `MEDIA.md`).
- Estate documentation: `DEPLOYMENT.md` §5 and § Storage conventions; `NETWORK.md`; `CLAUDE.md` § Storage and Permissions, § Infrastructure Warnings; `CONVENTIONS.md` (rules 1–3 govern every check written here: fail closed, bound remote commands Linux-side, assert rather than report).
- Existing implementations: `/usr/local/bin/run-backup.sh` and `/usr/local/bin/backup-incremental.sh` on atlantis; `scripts/check-drift.sh` and `scripts/quick-health-check.sh` in this repo as the pattern for assertion and for alert-only reporting.
- Prior incidents that constrain this plan: the September duplicate-stack event on hufflepuff; the `zfs recv` parent-dataset and `rc=141` failures from the first backup run; the `mkdir -p` dataset trap; the stale-utmp clock on hufflepuff.
- Hardware facts: `zpool status backup` (single USB vdev); `lsblk` on hufflepuff 2026-09-25 (3× ST16000NM001G, M4 512 G, 840 EVO 931 G); SMART verdicts from 2026-09-20, **which predate the pool destroy and must be re-read before any disk is trusted**.
- Open dependency: the Grafana→Telegram alert route's credentials remain an open item from quick task 260918-c12 (G4). G5 of this plan cannot pass while that is unproven.


---

## Execution log — G5 restore drill, 2026-09-25 — **PASSED**

**This is the gate the restructuring programme was waiting on.** Until this ran, the estate had
copies whose recoverability was assumed. It is now measured.

### Method

Restored **from the backup pool**, never from the source, onto a **disposable** target — so the
drill proves the backup is self-sufficient rather than that tank can read its own datasets.

| what | from | to |
|---|---|---|
| `appdata/traefik` | `backup` pool snapshot | `tank/restore-drill/traefik` (new, disposable) |
| `appdata/dawarich` | `backup` pool snapshot | `tank/restore-drill/dawarich` (new, disposable) |
| Immich `pg_dumpall` | `/backup/backups/immich-db/immich-20260925.sql.gz` | throwaway Postgres on LXC 100 |

A **third pool** was used as the restore target (source `fast` → backup `backup` → restore `tank`),
and the dump was copied from the backup pool and **sha256-verified in transit** before use.

### Results

**Filesystem restores — byte-identical.** Compared against the *source-side snapshot of the same
name* rather than the live tree, so ongoing writes could not confound the comparison:

| dataset | files | tree sha256 |
|---|---|---|
| traefik | 78 = 78 | `2f542f8b0838523a` = `2f542f8b0838523a` |
| dawarich | 2,858 = 2,858 | `9efb5d9d9b51ac0c` = `9efb5d9d9b51ac0c` |

**Immich database — all 11 tables EXACT** against the live database:

```
asset        134,920   asset_exif   134,920   asset_face   183,836
face_search  183,835   smart_search 115,211   album_asset  232,962
asset_file   288,648   person         6,319   album            411
tag              130   user               2
```

`gzip -t` on the backup-pool copy passed before restore, confirming the stream was not truncated —
the failure mode the existing 1 MB size assertion exists to catch, checked independently.

The throwaway Postgres ran with `--network none`, no ports and no volumes, on the correct Immich
image (`postgres:14-vectorchord0.4.3-pgvectors0.2.0`), so it could not reach or be reached by the
live stack.

### What went wrong, kept because the trap is documented in this very plan

The first restore attempt failed with **`send_rc=141`** and
`cannot open 'tank/restore-drill': dataset does not exist`. **`zfs recv` does not create
intermediate parents** — a trap recorded in this plan's own Implementation Notes and in two
sibling plans, and walked into anyway. Fixed with `zfs create -p` first.

It is recorded because of *how* it was diagnosed: `rc=141` is SIGPIPE and says only that the
pipeline broke. The cause was legible solely because recv's **stderr was captured separately**.
Reading the exit code alone would have produced a mystery.

Separately, three table-count checks initially returned **COULD-NOT-LOOK** because Immich v3
renamed them (`users`→`user`, `exif`→`asset_exif`, `asset_faces`→`asset_face`). Per rule 1 those
were resolved rather than left, by enumerating `pg_stat_user_tables` and re-checking — which is
what turned a 4-table partial check into an 11-table exact one.

### Footnote — the harness later reported this command as FAILED. It did not fail.

Recorded because the record would otherwise contradict itself: the background task that ran the
restore was reported by the harness as `failed with exit code 255`, while this log says PASSED.

Reading the captured output settles it:

```
restore exit: 0                              <- the psql restore returned 0
ERROR:  current user cannot be dropped       <- expected
ERROR:  role "postgres" already exists       <- expected
Read from remote host 172.16.1.159: Operation timed out
client_loop: send disconnect: Broken pipe
[exited with code 255]
```

**Exit 255 is ssh's transport failure, raised after the restore had already returned 0** — the
session dropped while idle. The two `ERROR:` lines are the normal output of restoring a
`pg_dumpall --clean` into a fresh instance: you cannot `DROP` the role you are connected as, and
`postgres` already exists in a new container. Neither affects data.

The verdict does not rest on that exit code in any case: the eleven table counts were measured in
**separate** commands against the restored database afterwards, and all matched live exactly. That
is the evidence, not the wrapper's exit status.

Two things to carry forward: **read a pipeline's captured output before believing its exit code**
(the same lesson as `rc=141` above, arriving from the opposite direction — there a 0 would have
lied, here a 255 did), and expect those two benign `ERROR:` lines on any future Immich restore
drill rather than treating them as a failed restore.

### Cleanup

Throwaway container removed, staged dump deleted, `tank/restore-drill` destroyed behind a
two-layer fence: the target name was matched exactly, and its children were asserted to be
precisely the two datasets the drill created before `zfs destroy -r` ran. Source and backup
datasets confirmed intact afterwards.

### Consequence

**G5 is met. The deploy may proceed.** What is now proven: ZFS datasets restore byte-identically
from the backup pool to an unrelated pool, and the Immich database restores to exact row counts
from the backup-pool copy of the dump.

**What is still NOT proven, and must not be inferred from this:** a bare-metal rebuild of LXC 100.
This drill recovers *data*; it does not demonstrate reconstructing the host, its bind mounts or
its Terraform-managed configuration. That remains follow-on work.
