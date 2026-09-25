# Unblock: Disarm hufflepuff, Reclaim Disk, Close the Backup Gap

**Status:** IN PROGRESS — authorised by the operator 2026-09-25. This is an execution plan, not a proposal. **Scope:** four bounded actions across `hufflepuff` and LXC 100 that remove one live hazard, clear one hard blocker, and take the estate from *no off-box copy of application state* to *covered and scheduled*. **Parent:** `backup-and-recovery-foundation.plan.md` (this is its G0/G2/G5 partial, plus a disk-reclaim item that plan named as follow-on) and `hufflepuff-rebuild-as-backup-tier.plan.md` (its G0). **Explicitly out of scope:** the 27-container deploy, service classification, consolidation, the hufflepuff rebuild, `/dev/net/tun`, Silo. **Nothing in this plan is irreversible** except the image prune, which is recoverable by re-pull.

## Problem

Three conditions are live simultaneously, and each blocks or endangers the restructuring programme queued behind it.

**1. hufflepuff is running a duplicate stack right now.** Measured 2026-09-25: `docker` is `enabled` **and** `active`, with `immich_postgres`, `immich_redis` and `immich_machine_learning` up 13 hours and `immich_server` crash-looping. The operator confirmed this was not intentional. This is the September incident recurring — the one where 30 containers, including prowlarr and sabnzbd **on the shared indexer and usenet accounts**, ran beside production for two days. Stopping the unit is not enough; it was stopped in September and is running again. It must be **disabled**.

**2. LXC 100 cannot take the deploy.** `/` is 126 G, **99 G used, 21 G free, 83 %** — with **60.9 GB of reclaimable Docker images** (76 % of 79.83 GB total). The queued deploy pulls 27 images. It would not fit, and a full root filesystem on a host running ~100 containers is an outage that arrives without warning.

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
- Pre-change baselines, pinned for comparison: LXC `/` **21 G free / 83 %**; reclaimable images **60.9 GB**; `backup` **11.0 T free / 24 % CAP**; datasets replicated off-box **7**; `fast` live snapshots **1**.

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
| T1 | `systemctl disable --now docker`; confirm no libvirt autostart | hufflepuff | `is-enabled`→`disabled`, `is-active`→`inactive`, `docker ps` unreachable | ☐ |
| T2 | `docker image prune -a` | LXC 100 | `df /` free space materially up; all 98 running containers still running | ☐ |
| T3 | Extend backup set to `fast/appdata` minus exclusions; run it | atlantis | every included dataset present on `backup` with a snapshot; sizes reconcile | ☐ |
| T4 | Install `backup-incremental.timer`; prove failure is visible | atlantis | `systemctl list-timers` shows it; a forced failure produces a signal | ☐ |

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
