# Rebuild hufflepuff as the Offline Backup Tier

**Status:** proposed plan; no implementation authorised by this document. **Scope:** the decommissioned host `hufflepuff` (172.16.1.21) — extracting the ~18 GB of application state its scavenge never enumerated, retiring its NixOS generation, moving the OS to the Crucial M4, building a two-disk mirror from the surviving 16 TB drives, and standing it up as the normally-powered-off tier 2 of the backup architecture. **Depends on:** `backup-and-recovery-foundation.plan.md` — tiers 0 and 1 must land first; this plan is that plan's G6 expanded. **Explicitly out of scope:** the email-archive recovery that prompted part of this work (no mail was found here — see Problem), the `open-archiver` deployment, and everything in the LXC 100 restructuring programme. **Decisions already taken by the operator and encoded here, not re-litigated:** keep hufflepuff rather than sell it; discard the failed 16 TB disk entirely rather than rebuild a raidz1; mirror the two survivors; move the OS to the M4 so the 840 EVO can go to the NUC.

## Problem

`backup-and-recovery-foundation.plan.md` establishes that the estate has **one** off-box copy of its data, on a single always-attached USB disk, and that this does not survive loss of atlantis, theft, fire, or an operator error propagating. The missing leg is a second copy that is **physically separate and normally powered off**. hufflepuff is the designated host for that role.

It cannot take the role in its current state, for four reasons — three of which are live faults rather than design questions.

### It rearms itself every time it boots

Measured 2026-09-25: `systemctl is-enabled docker` → `enabled`, `is-active` → `active`, with `immich_postgres`, `immich_redis` and `immich_machine_learning` up 13 hours and `immich_server` crash-looping. **The operator confirmed this was not intentional.** 30 containers are defined; only 4 run, because the rest lost their volumes when the pool was destroyed on 2026-09-22.

This is the September incident recurring. That incident put a second Jellyfin on production's ports (including 1900/udp and 7359/udp, which are DLNA auto-discovery), plus prowlarr and sabnzbd **sharing the production indexer and usenet accounts**, and a Home Assistant VM with autostart enabled, live on the LAN for two days. It was noticed only because `zpool destroy` refused with "pool is busy".

A host that is going to be powered on by a timer, weekly, unattended, **must not be able to do this**. Stopping the unit is not sufficient — it was stopped in September and is running again. The unit must be disabled, and the VM autostart path confirmed clear.

### Its root filesystem was never enumerated, and it holds real context

The 2026-09 scavenge covered `/pool/*` and `/mnt/mediahub`. It did not cover `/`. The estate's own record of that job is that **three gaps surfaced after it was declared complete**, and the standing lesson was *enumerate the whole filesystem before calling a source copied*. That lesson was not applied to the OS disk.

Measured as root on 2026-09-25, `/` holds 212 G — but the composition matters:

| path | size | disposition |
|---|---|---|
| `/var/lib/docker/overlay2` | **140 G** | container layers. Reclaimable, not state. |
| `/srv/appdata` | **50 G** | **the unscavenged application state** |
| `/nix` | 13 G | store; rebuilt from config, not data |
| `/home` + `/root` | 836 M | user files, shell history, keys |

Within `/srv/appdata`, `podsync` is 32 G of re-downloadable media. **The genuinely irreplaceable remainder is roughly 18 GB**: `jellyfin` 7.4 G (watch history and user accounts from the previous generation of the estate), `n8n` 1.2 G (workflows and credentials), `open-webui` 890 M (chat history), `radarr`/`sonarr`/`lidarr`/`readarr` configs with scheduled backups reaching back to **2023**, plus `authelia`, `freshrss`, `homebridge`, `prowlarr`, `traefik3`, `webvirtcloud`, `pinchflat`, `sabnzbd`, `minecraft`.

Some of this is genuinely superseded by the Proxmox estate and can be discarded after inspection. Some — the Jellyfin watch history in particular — is the kind of thing that is only noticed to be missing years later. **Nothing may be wiped before this is extracted and verified.**

### The NixOS configuration is a previous generation

The host is NixOS (kernel 6.6.87) configured for a workload that no longer exists: a 48 TB media pool, Samba exports, k3s, libvirt VMs, and a 30-container Docker stack that duplicates production. Carrying that configuration forward into a backup appliance would carry the duplicate-stack hazard with it.

The target role needs almost none of it: sshd, ZFS, a WoL-capable network stack, and nothing else. This is a **rewrite of the configuration to a minimal generation**, not an edit — and NixOS makes that unusually safe, because the old generation remains bootable until it is garbage-collected.

### One of the three 16 TB disks is bad, and which one is not yet established

The old pool was `raidz1-0` with three `ST16000NM001G` members plus a `loop0` sparse file standing in for a failed disk. One member, **`ata-ST16000NM001G_WL20VFEK`, was DEGRADED with "too many errors"**. The pool was destroyed on 2026-09-22 and `wipefs -a` run on `sda`, `sdd`, `sde` and `sdb`.

`lsblk` today shows three 14.6 T `ST16000NM001G` devices at `sda`, `sdd`, `sde`. **The mapping from that serial to a current device letter has not been made**, and USB/SATA letters are not stable. Building a mirror without first identifying and excluding `WL20VFEK` by serial would put the bad disk into the new pool.

Whether `WL20VFEK` is genuinely failing or was a cable/controller fault is also unverified. The operator's decision is to discard it regardless, which is the right call for a backup target — but the plan must still *identify* it correctly to discard the right one.

### What this plan does not solve

The operator's stated goal in this area was to find **email archives — PST/OST files spanning 10–15 years of Outlook — and specifically flight records from before ~2010**.

**They are not on hufflepuff.** Two searches were run with real privilege and both returned nothing:

- As root across hufflepuff's entire rootfs (`find / -xdev` for `pst|ost|olm|mbox|eml|emlx|msg|dbx|nsf|mbx`): the only hits were `.msg` files inside `/nix/store` — git-gui translation files, false positives.
- As root across the 1.19 TB scavenged copy on atlantis (`/mnt/tank/backups/hufflepuff-scavenge`): zero hits.

An earlier unprivileged attempt returned empty *because `sudo` failed*, not because the disk was clean; that result was discarded rather than recorded. This finding rests on the privileged runs only.

So the mail archive is somewhere else, and finding it is a separate discovery problem — see `## Sources and constraints`. It is named here so that a future reader does not assume the question was never asked.

## Solution

Extract, then rebuild from bare metal to a minimal generation, then mirror, then enrol as tier 2.

```text
 PHASE A — extract (nothing destructive)
   /srv/appdata  (18 G after excluding podsync)  ─┐
   /home /root                                    ├─> tank, then to the backup pool
   /etc/nixos (the old generation, as a record)  ─┘   verified by hash before anything is wiped

 PHASE B — disarm and rebuild
   systemctl disable docker  ──>  840 EVO out (to the NUC)  ──>  M4 in
                                        │
                              minimal NixOS generation:
                              sshd + ZFS + WoL. No docker. No libvirt. No samba.

 PHASE C — storage
   identify WL20VFEK by SERIAL ──> exclude it ──> zpool create mirror <two survivors>
                                                    ~16 T usable, real redundancy

 PHASE D — enrol as tier 2
   atlantis ──(zfs send -i, weekly)──> hufflepuff ──> power down
        WoL or smart switch. Offline between runs. Restore proven independently.
```

### Extract before you trust the plan, not after

Phase A is deliberately first and deliberately non-destructive. The cost of extracting 18 GB that turns out to be worthless is an hour and some disk. The cost of wiping 18 GB that turns out to matter is unbounded and discovered late. The estate has already paid this lesson once on this exact host.

Extraction goes to `tank` and then through the tier-1 backup, so the extracted copy is itself protected before the source is destroyed. **The source is not wiped until the extract is verified by hash on the backup pool** — not merely present on tank.

### A mirror, not a raidz1

Two disks, one vdev, `mirror`. ~16 T usable against a current tier-1 footprint of 3.50 T, so headroom is not the constraint. A mirror of two gives genuine redundancy and, unlike the old three-disk raidz1 with a sparse-file member, it is honest about what it is. The failed disk leaves the machine rather than sitting in a slot waiting to be mistaken for a spare.

### Minimal generation, and the old one kept bootable

Build the new configuration as a fresh generation with docker, libvirt, samba, k3s and the media mounts absent. NixOS keeps the previous generation in the bootloader, so a mistake is a reboot rather than a reinstall — but note the OS disk is changing, so the old generation lives on the **840 EVO**, which is leaving for the NUC. **Capture `/etc/nixos` as a file before the disk goes**, because once the EVO is flashed for the NUC the old configuration is gone.

### Powered off is the feature

The point of tier 2 is that it is not reachable between runs. A disk that is always mounted is exposed to whatever reaches the host; a machine that is off is not. The replication window is the only time it is online, and the backup account on atlantis should be able to *send* without being able to *destroy* on the target.

## Variables

- `HUFFLEPUFF=172.16.1.21`, user `damian`, key auth from the workstation. Credentials in `~/.claude/secrets/hufflepuff.env` (`HUFFLEPUFF_SUDO_PASS`). **Sudo requires a password**; pass it on stdin, never in argv — see CONVENTIONS rule 7.
- `ATLANTIS=172.16.1.158`; `BACKUP_POOL=backup` (tier 1, WD Elements USB, 11.0 T free); `NEW_POOL` — name to be chosen at Phase C, **not** `pool` (the old name, to avoid any script or muscle memory reaching the wrong target).
- Disks by role. **Always address by `/dev/disk/by-id`, never `/dev/sdX`.**
  - `sda`, `sdd`, `sde` — 3× `ST16000NM001G` 14.6 T. **One is `ata-ST16000NM001G_WL20VFEK` and is to be discarded; its current device letter is UNKNOWN and is a Phase C task to establish by serial.**
  - `sdb` — `M4-CT512M4SSD1` 476.9 G, wiped 2026-09-22. **New OS disk.** 10 yr powered on, wear-level normalised 76, zero reallocations. `smartctl` flags its firmware `000F` for the M4 BSOD bug — check whether `070H` can be applied while the case is open.
  - `sdc` — `Samsung SSD 840 EVO 1 TB`, current OS disk. **Leaves for the NUC**, flashed to `EXT0DB6Q` (ISO already downloaded to `~/Downloads/`, sha256 `b11658ab…`). An interrupted flash bricks the drive.
- `EXTRACT_SRC` — `/srv/appdata` **minus `podsync`** (32 G, re-downloadable), `/home`, `/root`, `/etc/nixos`. `EXTRACT_DST` — a new dataset under `tank/backups/`, created with `zfs create`, **not `mkdir -p`** (a plain directory is silently skipped by the send as MISSING).
- `EXCLUDE_FROM_EXTRACT` — `/var/lib/docker` (140 G of container layers), `/nix` (13 G, rebuildable from config).
- Replication window and trigger for Phase D: WoL magic packet or smart switch, both to be decided at D. `RECV_USER` on hufflepuff should hold receive-only ZFS delegation, not root.

## Implementation Notes

### Facts this plan rests on, and how they were established

| Fact | Value | How |
|---|---|---|
| docker state | `enabled` + `active`, 4 containers up 13 h | `systemctl`, `docker ps`, 2026-09-25 |
| `/` used | 212 G | `df -h /` |
| `/srv/appdata` | 50 G, of which podsync 32 G | `du -xh` as root |
| `/var/lib/docker/overlay2` | 140 G | `du -xh` as root |
| mail archives on `/` | **none** | `find / -xdev` **as root** |
| mail archives in scavenge | **none** | `find` as root on atlantis |
| pool | destroyed; `zpool list` → no pools | 2026-09-25 |
| disks present | 3× 16 T, M4, 840 EVO | `lsblk` |

### Traps specific to this host

- ⚠️ **`uptime` and `who -b` lie by more than two years** — both report ~811 days from a stale utmp. `/proc/uptime` reads 5.0 days and is the only honest source. **Never date anything on this machine from `uptime`, `who -b` or file mtimes.** Same shape as `docker ps` reporting `Up 2 weeks` for a container `inspect` showed as `exited 137`.
- **An unprivileged `find` that returns nothing is not evidence of absence.** This plan's mail-archive finding was nearly recorded from a run where `sudo` had silently failed. Check `sudo -n true` before trusting any privileged sweep, and keep "could not look" distinct from "nothing there" — CONVENTIONS rule 1.
- **`wipefs -a` was already run on `sda`/`sdd`/`sde`/`sdb`**, so there are no pool labels to read. Disk identity must come from **SMART serials**, not from ZFS metadata.
- **The EVO is the current OS disk** (`sdc1` → `/boot`, `sdc2` → `/`). Wiping or pulling it before the M4 is installed and bootable kills the machine mid-job. This ordering error was avoided once already in September.
- **`rsync -a` fails writing to `tank`** (`mkstemp … Operation not permitted`, from `acltype=nfsv4` + `aclmode=restricted`) while printing stats that look like success and exiting 23. Use `rsync -rlt --no-p --no-o --no-g`.
- **`zfs recv` does not create intermediate parents**; `rc=141` (SIGPIPE) on a `send | recv` pipeline means the *receiver* died — read recv's stderr, not the exit code.

### Sequencing constraints that are not negotiable

1. Extract and verify **before** any wipe. Verified means hashed on the backup pool, not copied to tank.
2. Disarm docker **before** any reboot. The case has to be opened to swap disks, which means a boot, which is exactly when the duplicate stack returns.
3. Capture `/etc/nixos` **before** the EVO leaves.
4. Install and boot the M4 **before** removing the EVO.
5. Identify `WL20VFEK` by serial **before** creating the mirror.

### What is deliberately deferred

Whether the discarded 16 TB disk is genuinely faulty or was a controller fault is not investigated — it leaves the machine either way, per the operator's decision. The M4 firmware update is opportunistic (do it while the case is open) and not a gate. Offsite is still not addressed: tier 2 is physically separate and offline, but remains in the same building.

## Workflow

1. **Disarm (G0).** `systemctl disable --now docker`; assert `is-enabled` → `disabled` and `is-active` → `inactive`. Confirm no libvirt autostart path exists. Record what the four running containers were and whether anything on the LAN had bound to them. **This gate is independent of every other decision in this plan and should not wait for it.**
2. **Extract (G1).** Create the destination as a dataset. Copy `/srv/appdata` (minus podsync), `/home`, `/root`, `/etc/nixos`. Verify by file count and hash. Replicate to the backup pool and verify there. **Only after this is green does anything become destructive.**
3. **Triage the extract (G2).** Inspect what was recovered and record a disposition per application: superseded by the Proxmox estate, worth importing, or worth keeping only as an archive. Jellyfin watch history and n8n workflows get an explicit decision each — they are the two most likely to be quietly missed.
4. **Prepare the disks (G3).** Read SMART on all three 16 TB drives; map serials to device letters; **identify `WL20VFEK`**. Record the health of the two survivors as a baseline. Flash the 840 EVO to `EXT0DB6Q` and the M4 to `070H` if applicable, while the case is open.
5. **Rebuild the OS (G4).** Install the M4 as the boot disk with a **minimal NixOS generation**: sshd, ZFS, WoL. No docker, no libvirt, no samba, no k3s, no media mounts. Boot it. Remove the 840 EVO and hand it to the NUC work. Confirm the machine comes up cleanly with nothing listening that should not be.
6. **Build storage (G5).** `zpool create <NEW_POOL> mirror <two verified survivors, by-id>`. Physically remove the discarded disk from the chassis so it cannot be mistaken for a spare. Scrub the empty pool once to establish a clean baseline.
7. **Enrol as tier 2 (G6).** Implement the power-on, receive, power-off cycle. Replicate the tier-1 set. Use a receive-only delegated account rather than root. Prove the window works unattended.
8. **Prove by restore (G7).** Restore from **hufflepuff**, not from tier 1, onto a disposable target, and reconcile. Tier 2 is not a backup until this passes.

## Deliverables

1. hufflepuff disarmed and provably unable to restart its old stack on boot — closing an incident that has now recurred twice.
2. A verified extract of `/srv/appdata`, `/home`, `/root` and `/etc/nixos`, present on both tank and the backup pool, hashed.
3. A per-application disposition record for the extracted state, with Jellyfin watch history and n8n workflows individually decided.
4. SMART baseline for the two surviving 16 TB disks, and positive identification of the discarded one by serial.
5. A minimal NixOS configuration, in version control, that cannot run containers or VMs.
6. The 840 EVO flashed and released to the NUC work; the M4 in place as the boot disk.
7. A two-disk mirror, scrubbed clean, with the failed disk physically removed from the chassis.
8. A working unattended replication window, using a receive-only account.
9. Restore evidence from tier 2, independent of tier 1.
10. An updated `NETWORK.md` entry: hufflepuff changes from "decommissioned, to be sold" to an operational backup appliance with a documented power schedule.

## Definition Of Done

### Safety

- Booting hufflepuff starts **no** container and **no** VM. Verified by an actual reboot, not by reading unit files.
- Nothing on the LAN can reach a duplicate Jellyfin, Immich, prowlarr or sabnzbd originating from this host. The shared indexer and usenet accounts see no traffic from it.
- The replication account on hufflepuff can receive but cannot destroy. A compromised atlantis cannot wipe tier 2 by running `zfs destroy` against it.

### Nothing lost

- Every path in `EXTRACT_SRC` is present on the backup pool with a matching hash, **or** appears on a written exclusion list with a reason. No path is unaccounted for.
- The extract is verified on the **backup pool**, not merely on tank. A copy that exists in one place is not a rescue.
- `/etc/nixos` from the old generation is captured as a file before the EVO leaves the machine.
- Anything discarded from the extract is discarded by a recorded decision, not by omission.

### The tier works

- A restore has been performed **from hufflepuff** and reconciled by count and hash. Until then tier 2 is an untested copy, not a backup.
- The mirror is genuinely two physical disks; `zpool status` shows no sparse file, no loopback, no missing member. The discarded disk is out of the chassis.
- An unattended cycle has run end to end — powered on, received, powered down — without a human, and a failure or a skipped run is visible rather than silent.

### Honest about scope

- This plan does not deliver offsite backup, and does not claim to. Both tiers remain in one building.
- The email archives the operator is looking for are **not** here; that is recorded as a searched-and-absent finding, and the search continues elsewhere under its own plan.

## Sources and constraints

- Parent plan: `.planning/plans/backup-and-recovery-foundation.plan.md` (this plan is its G6, expanded; tiers 0 and 1 are prerequisites).
- Measured evidence: `.planning/analysis/STACK-MAP.md`; direct measurement of hufflepuff on 2026-09-25 (`df`, `du` as root, `lsblk`, `systemctl`, `docker ps`, `find / -xdev` as root).
- Prior incidents constraining this plan: the September 2026 duplicate-stack event (30 containers, HA VM, two days, shared indexer/usenet accounts); the scavenge that was declared complete with three gaps outstanding; the stale-utmp clock; the `zpool destroy` that failed "pool is busy".
- Hardware history: SMART verdicts from 2026-09-20 — **these predate the pool destroy and must be re-read**, not trusted as current. Firmware: Samsung `EXT0DB6Q` ISO already downloaded and verified as a bootable ISO 9660 image; Crucial M4 `000F` carries the known BSOD defect.
- Standing conventions: `CONVENTIONS.md` rules 1 (fail closed; "could not look" ≠ "nothing wrong"), 2 (bound remote commands Linux-side), 3 (assert, do not report), 7 (credentials never in argv).
- **DEFERRED by the operator, 2026-09-25 — do not re-escalate:** the email/PST archive hunt. Confirmed absent from hufflepuff `/` and from the scavenged copy (both searched as root). The operator's read is that it may be on **optical media** and will be dealt with separately; nothing in this programme blocks on it and no plan should treat it as an open gap.
  - Candidate locations if it is ever picked up: CD/DVD-R archives, the intel-mac (macOS 13.7.8), the mac-mini, M365/OneDrive via the work tenant, iCloud, any Gmail account (the Gmail MCP connector exists but was **not connected** when tried here).
  - One time-sensitive note recorded once, not as a prompt to act: **CD-R and DVD-R written in the 2000s degrade**, and dye-layer rot is silent — a disc can mount and still return unreadable sectors. If those discs are the source, reading them is worth doing before the drive and the media age further. This is a note for whoever picks it up, not a reason to bring it forward now.
  - The destination already exists: `stacks/selfhosted/open-archiver/compose.yaml` declares a full mail-archiving stack (`logiclabshq/open-archiver:v0.6.0` + Postgres 18 + Valkey + Meilisearch v1.54 + Tika) that has **never been deployed**. It needs a plan of its own *and* a consolidation decision, since it would add a third Meilisearch, a thirteenth Postgres and a third Tika to the estate.
