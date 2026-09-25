# Unblock: Disarm hufflepuff, Reclaim Disk, Close the Backup Gap

**Status:** IN PROGRESS — authorised by the operator 2026-09-25. This is an execution plan, not a proposal. **Scope:** four bounded actions across `hufflepuff` and LXC 100 that remove one live hazard, clear one hard blocker, and take the estate from *no off-box copy of application state* to *covered and scheduled*. **Parent:** `backup-and-recovery-foundation.plan.md` (this is its G0/G2/G5 partial, plus a disk-reclaim item that plan named as follow-on) and `hufflepuff-rebuild-as-backup-tier.plan.md` (its G0). **Explicitly out of scope:** the 27-container deploy, service classification, consolidation, the hufflepuff rebuild, `/dev/net/tun`, Silo. **Nothing in this plan is irreversible** except the image prune, which is recoverable by re-pull.

## Problem

Three conditions are live simultaneously, and each blocks or endangers the restructuring programme queued behind it.

**1. hufflepuff is running a duplicate stack right now.** Measured 2026-09-25: `docker` is `enabled` **and** `active`, with `immich_postgres`, `immich_redis` and `immich_machine_learning` up 13 hours and `immich_server` crash-looping. The operator confirmed this was not intentional. This is the September incident recurring — the one where 30 containers, including prowlarr and sabnzbd **on the shared indexer and usenet accounts**, ran beside production for two days. Stopping the unit is not enough; it was stopped in September and is running again. It must be **disabled**.

**2. LXC 100 cannot take the deploy.** `/` is 126 G, **99 G used, 21 G free, 83 %** — with roughly **21 GB of genuinely unreferenced Docker images** (`docker system df` claims 60.9 GB reclaimable, but that counts shared layers still held by running containers — see the T2 log). The queued deploy pulls 27 images. It would not fit, and a full root filesystem on a host running ~100 containers is an outage that arrives without warning.

**3. No application state has an off-box copy.** `run-backup.sh` replicates seven `tank` datasets and **zero bytes of `fast/appdata`**. Nothing schedules it. The deploy queued behind this contains one-way schema migrations — Paperless `3.0.4 → 3.2.1`, Dawarich `1.10.3 → 1.15.2` — that cannot be downgraded out of.

The reframing that makes (3) an hour rather than a project: `fast/appdata` is 169 G, but **142 G of it is `fast/appdata/hoarder`**, which holds podsync's re-downloadable media despite its name. Genuine exposure is **~27 G against 11.0 T free** on the backup pool. This is a configuration gap, not a capacity problem.

## Solution

Four actions, ordered so that each is independently verifiable and none depends on a decision.

```text
 T1  hufflepuff: systemctl disable --now docker     removes a live hazard
 T2  LXC 100:   docker image prune -a               unblocks the deploy, 83% -> ~35%
 T3  atlantis:  extend backup set to fast/appdata   closes the gap (~27 G)
 T4  atlantis:  systemd timer + failure visibility  keeps it closed
```

T1 and T2 are independent of each other and of T3/T4. T4 depends on T3. Nothing here waits on a decision the operator has not already made.

### Why prune is safe

Docker images are re-pullable by definition — every tag in the estate is pinned in git, and the deploy that follows re-pulls what it needs anyway. `prune -a` removes images **not referenced by a container**; running containers keep theirs. The one real consequence is that a rollback to a previous tag becomes a pull rather than an instant restart, which is acceptable given the alternative is a full root filesystem.

### Why `hoarder` is excluded, stated once so it is not mistaken for an oversight

`fast/appdata/hoarder` is 142 G of podsync-downloaded media — re-acquirable, not state. The dataset name is actively misleading (karakeep, which it is named for, is **979 KB**), and the architecture map initially mis-attributed it before correcting itself. The exclusion is a decision with a reason, and it must be re-examined if anything non-media is ever written there.

## Variables

- `ATLANTIS=172.16.1.158` (owns all pools) · `LXC100=172.16.1.159` · `HUFFLEPUFF=172.16.1.21` user `damian`.
- hufflepuff sudo needs a password: `~/.claude/secrets/hufflepuff.env` → `HUFFLEPUFF_SUDO_PASS`. **Pipe on stdin, never argv** (CONVENTIONS rule 7).
- `BACKUP_POOL=backup` — single vdev `usb-WD_Elements_25A3_3242485330374E4E-0:0`, **address by `by-id` only**; 14.5 T, 11.0 T free.
- `INCLUDE` — all of `fast/appdata/*` except the two exclusions below.
- `EXCLUDE` — `fast/appdata/hoarder` (142 G, re-downloadable podsync media) and `fast/appdata/agentic-os` (96 K, empty orphan dataset).
- `SCRIPTS=/usr/local/bin/{run-backup.sh,backup-incremental.sh}` on atlantis.
- Pre-change baselines, pinned for comparison: LXC `/` **21 G free / 83 %**; genuinely unreferenced images **~21 GB** (not the 60.9 GB `docker system df` reports); `backup` **11.0 T free / 24 % CAP**; datasets replicated off-box **7**; `fast` live snapshots **1**.

## Implementation Notes

### Traps already paid for — do not rediscover

- **`zfs recv` does not create intermediate parents.** Every send in the first backup run died with `rc=141` (SIGPIPE) and `cannot open 'backup/media': dataset does not exist`. **`rc=141` on a `send | recv` pipeline means the receiver died** — read recv's stderr, not the pipeline exit code. Fix: `zfs create -p "$parent"` first.
- **A plain directory is not a dataset.** `/mnt/tank/backups/immich-db` was `mkdir -p`'d, so the send skipped it as MISSING while the files sat there looking fine.
- **`run-backup.sh` skips any dataset already on the target**, so re-running it is a silent no-op. `backup-incremental.sh` is the update path.
- **Write scripts locally and pipe them over ssh.** A heredoc-through-ssh version produced a literal `rc=${PIPESTATUS[0]}` in every log line, making success unverifiable from the log.
- **ZFS frees space asynchronously** — `zfs list` can lag a large delete by ~20 s. Do not assert free space immediately after a destroy.
- **Never date anything on hufflepuff from `uptime`/`who -b`** — stale utmp reports ~811 days; `/proc/uptime` is the only honest source.
- **Check `sudo -n true` before trusting a privileged sweep** — an unprivileged `find` returning empty is "could not look", not "nothing there". This nearly produced a false finding during the mail-archive search.

### Verification standard for every task

Per CONVENTIONS rules 1–3: fail closed, bound remote commands Linux-side, and **assert rather than report**. No step is complete because a command exited 0. Each task below names the specific post-condition that must be true, measured after the fact.

## Workflow

| # | Task | Host | Verification | Status |
|---|---|---|---|---|
| T1 | Disarm docker/k3s/samba **via the nix flake**, not `systemctl` | hufflepuff | units report `not-found`; sshd still active | ✅ **DONE** |
| T2 | `docker image prune -a` | LXC 100 | `df /` free space materially up; all 98 running containers still running | ✅ **DONE** |
| T3 | Extend backup set to `fast/appdata` minus exclusions; run it | atlantis | every included dataset present on `backup` with a snapshot; sizes reconcile | ✅ **DONE** |
| T4 | Install `backup-incremental.timer`; prove failure is visible | atlantis | `systemctl list-timers` shows it; a forced failure produces a signal | ⚠️ **MOSTLY** — timer done + freshness check written and red-branch-driven; fold-in to `quick-health-check.sh` outstanding |

1. **T1 — disarm.** Record what the four containers were before stopping them, so the incident is closed with evidence rather than just silenced.
2. **T2 — reclaim.** Capture `docker system df` before and after. Assert the running-container count is unchanged — a prune that takes a container down is a failure, not a success.
3. **T3 — close the gap.** Read the existing scripts before editing. Create parent datasets explicitly. Verify by presence and size on the target, not by exit code.
4. **T4 — keep it closed.** A backup that silently stops is worse than none, because it manufactures confidence. Failure *and silence* must both be visible.

## Deliverables

1. hufflepuff disarmed, with a record of what was running and for how long.
2. Reclaimed disk on LXC 100, with before/after figures, and the deploy unblocked.
3. `run-backup.sh` / `backup-incremental.sh` extended to `fast/appdata` with the exclusions stated in-file, committed to the repo rather than living only on the host.
4. A systemd timer, installed and verified.
5. Updated baselines recorded here so the next reader can see what moved.

## Definition Of Done

- **hufflepuff cannot restart its old stack on boot.** `is-enabled` returns `disabled`. Not "the containers are stopped" — that was true in September and did not hold.
- **LXC 100 has enough headroom for the deploy**, measured, with all previously-running containers still running afterwards.
- **Every dataset under `fast/appdata` is either replicated to the backup pool or on the written exclusion list with a reason.** No dataset is unaccounted for.
- **The backup runs on a schedule, and a failed or missed run is visible** without someone reading a log by hand.
- Every check distinguishes "verified" from "could not look". Anything unverifiable is recorded as such, not assumed good.
- **Not claimed:** this plan does not prove restore. That is the parent plan's G5 and it is the gate the deploy actually waits on. Closing the backup gap and proving it are different things, and only the first is done here.

## Sources and constraints

- Parent plans: `backup-and-recovery-foundation.plan.md`, `hufflepuff-rebuild-as-backup-tier.plan.md`.
- Measured evidence: `.planning/analysis/STACK-MAP.md`; direct measurement of all three hosts on 2026-09-25.
- Existing implementations to extend, not replace: `/usr/local/bin/run-backup.sh`, `/usr/local/bin/backup-incremental.sh` on atlantis.
- Conventions: `CONVENTIONS.md` rules 1, 2, 3, 7. `DEPLOYMENT.md` § Storage conventions.
- Prior incidents: the September duplicate-stack event; the first backup run's `rc=141` and `mkdir -p` failures.

---

## Execution log

*(appended as tasks complete; each entry records what was measured, not what was intended)*

### T1 — hufflepuff disarmed — 2026-09-25 — DONE, with one unintended side effect

**`systemctl disable` does not work on this host, and that is not a detail.** hufflepuff is NixOS;
`/etc/systemd/system` is generated into the read-only Nix store, so the attempt failed with
`Read-only file system`. The plan's premise that this was "two commands" was wrong.

Chasing it produced a finding worth more than the task: **`/etc/nixos/` is not the live config.**
It is 84 lines dated Nov 2023, does not mention Docker at all, and is unused. The real
configuration is a snowfall flake at **`/home/damian/snow`**, a git repo with remote
`https://github.com/DamianFlynn/nix-snowfall.git`. So the rebuild plan's instruction to "capture
`/etc/nixos` before the EVO leaves" was aimed at the wrong file — **that plan must be corrected**,
and the good news is the real config is already pushed to GitHub and cannot be lost with the disk.

Also established: **only generation 64 existed** before this change. The rebuild plan's assumption
that "the old generation remains bootable" was true only by luck — there was exactly one.

Action taken, after asserting each target line matched before editing (a refusal was wired in and
would have aborted on any mismatch):

```
systems/x86_64-linux/hufflepuff/default.nix
  44  docker.enable = true;  ->  false
  45  k3s.enable    = true;  ->  false
  63  samba enable  = true;  ->  false     (shares point at /pool/*, destroyed in September)
```

then `nixos-rebuild switch --flake .#hufflepuff`. Backup of the original at `.bak-20260925`.

**Result — stronger than the plan asked for:**

| check | before | after |
|---|---|---|
| `docker.service` enabled | `enabled` | **`not-found`** |
| `docker.service` active | `active` | `inactive` |
| `k3s` | enabled | **`not-found`** |
| `samba-smbd` | enabled | **`not-found`** |
| running containers | 4 (Immich) | **0** |
| `sshd` | active | active |
| generations | 64 only | 64 retained, **65 current** |

`not-found` is a stronger guarantee than `disabled`: booting generation 65 cannot start Docker
because the unit does not exist in that generation. The DoD said "cannot restart its old stack on
boot" and this satisfies it — with the caveat that **booting generation 64 from the bootloader
would bring it all back**, which is inherent to NixOS and is not a defect.

**⚠️ UNINTENDED SIDE EFFECT, recorded rather than buried: the OS was downgraded 24.11 → 23.11.**
The running system was `24.11.20250412` (generation 64); the rebuild produced
`23.11.20240709`. Cause: the repo's `flake.lock` is older than whatever generation 64 was built
from, and `git status` showed it already modified *before* this session touched anything. The
lock should have been compared against the running version before rebuilding; it was not.
Generation 64 remains available for rollback. Left in place pending an operator decision, on the
reasoning that this host is destined for a wipe and a minimal rebuild regardless — **that is a
judgement, not a verification, and is flagged as such.**

**Failed units after the rebuild, with honest attribution:**

- `zfs-import-pool.service` — **pre-existing and predicted.** The config still declares
  `system.zfs.pools = [ "pool" ]` and that pool was destroyed on 2026-09-22. Fix when the new
  mirror is built.
- `home-manager-damian.service`, `systemd-oomd.service`/`.socket` — **attribution unknown.** No
  baseline of failed units was captured before the rebuild, so these cannot be claimed as
  pre-existing. Recorded as unknown rather than assumed harmless.

### T2 — LXC 100 disk reclaimed — 2026-09-25 — DONE

| | before | after |
|---|---|---|
| `/` used | 99 G | **81 G** |
| `/` free | 21 G | **39 G** |
| `/` capacity | 83 % | **68 %** |
| running containers | 98 | **98** (unchanged — asserted) |

Reclaimed **18.93 GB**. The deploy is unblocked.

**Correction to this plan's own Problem section, and to the two parent plans: the "60.9 GB
reclaimable" figure was wrong.** `docker system df` reports shared layer space that running
containers still hold, not space that can be freed. Enumerating images actually unreferenced by
any container gave ~21 GB, and the measured result was 18.93 GB.

**The metric is provably misleading: after pruning everything removable, `docker system df` still
reports "60.9GB (100%)" reclaimable.** Do not quote that field as free-able space. Enumerate
unreferenced images instead — `docker ps -aq | xargs docker inspect -f '{{.Image}}'` against
`docker images`.

Four of the five reclaimed images (`docling-serve:v1.25.0` 8.86 GB, `open-webui:v0.9.6` 4.78 GB,
`ollama:0.32.5` 4.76 GB, `searxng:2026.6.23` 259 MB) were the versions superseded by the SearXNG
deploy earlier the same day, plus 8 dangling layers (~2.3 GB).

### T3 — `fast/appdata` now replicated off-box — 2026-09-25 — DONE, VERIFIED

Both scripts extended (backups at `.bak-20260925`). One generalisation and one addition:

- Target mapping `backup/${ds#tank/}` → `backup/${ds#*/}`, so it works for any source pool.
  `tank/media/Photos` → `media/Photos` is unchanged; `fast/appdata/arrs` → `appdata/arrs` is new.
- The `fast/appdata` list is **enumerated dynamically, not hardcoded.** A static list silently
  misses any dataset created later, and a backup that quietly stops covering new things is the
  exact failure this whole exercise exists to close. New datasets are in by default; exclusion is
  an explicit act with a reason recorded in the script.

Ran `run-backup.sh`: `pg_dumpall` rc=0 at **858 MB** (clears the 1 MB assertion), the seven tank
datasets correctly skipped as already present, and **16 `fast/appdata` datasets sent, every one
rc=0**, in under three minutes.

**Verified by assertion, not by reading the log** — every included dataset present on the target
with `refer` within 50 % of source, and both exclusions confirmed *absent*:

```
checked=16  fail=0
ok absent: backup/appdata/hoarder
ok absent: backup/appdata/agentic-os
backup  3.52T alloc  11.0T free  ONLINE
```

Also fixed a cosmetic bug introduced by the append: `say "ALL DONE"` was left mid-script, so the
log claimed completion before the `fast/appdata` sends ran. Moved to the end.

### T4 — scheduled, and silence made loud — 2026-09-25 — MOSTLY DONE

`backup-incremental.service` + `.timer` installed, `enabled`, `active`, first run 2026-09-26 00:25.

Two deliberate properties:

- **`ConditionPathIsDirectory=/backup`** — the service does not start if the USB pool is not
  imported. A run that "succeeds" against a missing target is the failure mode that leaves a stale
  backup looking healthy.
- **`Persistent=true`** — if the machine was off at the scheduled time it runs on next boot rather
  than silently skipping the day. Silence is the thing this timer exists to prevent.

Proven via systemd, not just by running the script: `Result=success`, `ExecMainStatus=0`, and the
incremental correctly found `backup-20260925` as the base for the new datasets and sent against it.

New `scripts/check-backup-freshness.sh`. It asserts on **snapshot age**, not on a log line or a
marker file, because a snapshot on the target exists only if a `zfs recv` actually completed — a
log can be written by a run that then died. Checks pool health, per-dataset freshness (48 h default),
datasets holding data with no snapshot at all, and that the timer is still enabled.

**It caught itself being wrong, which is the part worth recording.** The first version ran a
`while read` loop *inside* the ssh payload; the escaping mangled it, so it returned one line
instead of 28 and printed `all 0 snapshotted datasets are within 48h` and **exited 0 having
examined nothing**. A false green, in the check written to prevent false greens — the same class
as this repo's documented heredoc-through-ssh trap. Fixed by keeping the remote side to flat
single commands and joining locally, plus a **cardinality guard**: fewer than 5 datasets on a pool
holding 3.5 T is itself a violation.

All branches driven, not assumed:

| branch | result |
|---|---|
| green (real state) | 27 datasets examined, 23 snapshotted, 0 stale, **exit 0** |
| `BACKUP_MAX_AGE_HOURS=0` | every dataset STALE, **exit 1** |
| unreachable host | `ssh transport failed (rc=255)` → **exit 1** |
| absent pool | `pool not imported (remote rc=1)` → **exit 1** |

The pool-absent message initially blamed ssh, because `zpool list` exits 1 and the transport check
caught it first. Now 255 is distinguished from other non-zero, so a reader is sent to the disk
rather than to the network.

**OUTSTANDING:** folding this into `scripts/quick-health-check.sh`. That file is 400+ lines of
documented convention — block ordinals, the `📊 N. Summary` grep anchor (CONVENTIONS rule 11),
per-branch reasoning — and doing it hastily would be worse than doing it deliberately. Until it is
folded in, the check exists and passes but **nothing runs it automatically**, which is a weaker
position than the DoD asks for and is recorded as such rather than ticked.
