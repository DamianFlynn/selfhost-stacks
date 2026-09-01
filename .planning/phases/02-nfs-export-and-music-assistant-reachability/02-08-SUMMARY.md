---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 08
subsystem: infra
status: complete
tags: [music-assistant, home-assistant, cons-03, criterion-4, m1, m3, m4, d-32, d-34, d-36, d-37, d-38, d-54, reboot-race, negative-control, mount-failed]

requires:
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-07's proven criterion 3 (three albums exact-matched, provider-attributed); 02-06's filesystem_local--XJaJWNUS provider; 02-05's live Supervisor NFS mount at /media/music; 02-04's check-music-consumers.sh; 02-03's applied export"

provides:
  - "CRITERION 4a PROVEN — NUC rebooted, zero manual intervention, mount active, 70 albums, both proof albums EXACT, audit exit 0"
  - "CRITERION 4b PROVEN — the race was deliberately fired and the guards held: empty read-only /media/music, MA scanned zero files, the empty-scan deletion guard preserved 70 albums rather than purging"
  - "UNATTENDED RECOVERY SETTLED at 432 s (7 m 12 s) — the half the community reports dispute, measured on this estate at this version, NUC untouched throughout"
  - "M1 PROVEN (superseding 02-03 and 02-05) — the `mountpoint` export option DOES make rpc.mountd refuse a fresh client mount when the dataset is unmounted"
  - "A REAL ALERTING DEFECT found by the live test and FIXED — D-54a could not fire on a boot into a failed mount; both new trigger paths now fired and trace-confirmed"
  - "D-54b DIAGNOSED with direct evidence — trigger config correct, blind at boot by deterministic integration-setup ordering"
  - "TWO INSTRUMENT CORRECTIONS: `mount | grep emergency/music` can never match on this Supervisor; `exportfs -v` cannot tell you an export will serve"

affects:
  - "02-09 — the corrected HA YAML below is what beets.md must carry (D-47); the audit script now lands via `git pull` on LXC 100, so the fold-in into quick-health-check.sh has a real pull path; three items are logged for it below"
  - "Phase 7 — the mount is proven to survive a reboot and to degrade safely, which is the precondition Phase 7 was gated on"
  - "infra/nfs-music-export.tf — 02-03's threat_flag: control-not-enforced is RETIRED, and the measurement is now recorded in the file itself"

tech-stack:
  added:
    - "Home Assistant `rest_command` integration (new domain on this NUC — required a core restart)"
    - "Home Assistant `command_line` sensor integration (new domain on this NUC)"
  patterns:
    - "Verify the transport by watching the DESTINATION's own state change, never by the HTTP status the caller got back"
    - "Detect the failure STATE, not the failure EVENT: /media/music present-but-empty is the failure, so 'does the path exist' is exactly the check that returns a false green"
    - "A trigger that fires and then evaluates a condition leaves a readable trace; a trigger with `for:` on it leaves nothing. Prefer the former when the trigger must be provable"
    - "Only a trigger that fires AT ATTACH TIME can catch a fault that predates the automation. `homeassistant` `event: start` does; state and numeric_state triggers structurally cannot"

key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-SUMMARY.md"
  modified:
    - "infra/nfs-music-export.tf (comment-only — records that `mountpoint` is proven enforced; terraform validate Success, plan -detailed-exitcode 0)"
  deleted:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-PARTIAL.md (folded into this file — one record, not two)"
  off-repo:
    - "/config/packages/music02_ma_nfs_mount.yaml on the NUC (created, then CORRECTED by this continuation — full text reproduced below; backups music02_ma_nfs_mount.yaml.bak.20260901T133540Z)"
    - "/config/secrets.yaml on the NUC (one key: ma_ha_sync_authorization; backup at /config/secrets.yaml.bak.20260901T104546Z)"

key-decisions:
  - "CONS-03 IS TICKED. Both reboots ran, criterion 4a passed and criterion 4b fired. The requirement's text is 'Music Assistant's view survives a NUC reboot' and that is now proven twice — once with the server healthy and once with it deliberately dead"
  - "The negative control is recorded as FIRED, not as 'not fired, inconclusive'. Two of the three named evidence items fired; the third could not, because the instrument named for it does not exist on this Supervisor version. That is a defect in the prediction, not a missing behaviour, and the mechanism was positively identified by other means"
  - "D-54a's fix keeps the original numeric_state trigger and ADDS two more. Coverage was added, never swapped"
  - "The load-bearing part of the fix is the `homeassistant start` trigger, NOT the `state: to: \"0\"` trigger the defect report proposed. Measured: the sensor lands on its boot value ~6-15 s BEFORE the automation attaches, so a state trigger would have missed it too"
  - "`for:` moved off D-54a's triggers and into the action as a delay plus a re-read — one debounce for all three paths, and a trigger that leaves a trace"
  - "D-54b is NOT fixed. Its trigger is correct and proven; it is blind at boot by integration-setup ordering. Closing it would duplicate D-54a for the only issue type in scope and would page for pre-existing issues nobody has chosen to act on"
  - "MA 2.11 DOES have a long-lived token API — `auth/token/create`, 1 year, revocable by token_id. Prior phase records say MA 2.11 has no API token; true of the UI, false of the API"
  - "D-54 shipped as ONE file with FOUR automations, not two files"

requirements-completed: [CONS-03]
requirements-carried: []

metrics:
  duration: "~195 min across the day (Task 1 ~110 min; Tasks 2-3 the two operator-authorised reboots; this continuation ~40 min)"
  completed: 2026-09-01
  tasks_completed: 3
  tasks_total: 3
---

# Phase 02 Plan 08: Reboot Resilience Summary

CONS-03 proven by rebooting the NUC twice — once healthy, once with `nfs-server` deliberately
stopped — and the negative control found a real alerting defect that is now fixed, plus two
instruments that were silently incapable of ever reporting a failure.

**This file replaces `02-08-PARTIAL.md`, which has been removed.** `phase-plan-index` marks a plan
complete on a `*-SUMMARY.md` existing alone and never reads `status:` frontmatter, so a halted plan
carries `-PARTIAL.md` and is folded into one record on genuine completion — the same thing 02-01
did. There is one record of this plan, not two.

## Status

| Task | Disposition | By |
|------|-------------|-----|
| 1 — verify the `rest_command`, build M4 and D-54's alert | **Complete, PASS.** M4 shipped and proven end-to-end, not deferred. | prior executor, commit `1dfea75` |
| 2 — positive reboot, criterion 4a | **Complete, PASSED.** | orchestrator, operator-authorised |
| 3 — negative control, criterion 4b | **Complete, FIRED.** | orchestrator, operator-authorised |
| *(defect work)* — fix what the control found | **Complete.** D-54a fixed and both trigger paths fired; D-54b diagnosed. | this continuation |

## Commits

| Unit | Commit | What |
|---|---|---|
| Task 1 | `1dfea75` | M4 + D-54 alerting (HA config is off-repo; the commit is the plan record) |
| M1 correction | `a4174e6` | `infra/nfs-music-export.tf` — records `mountpoint` as proven enforced, retires 02-03's threat flag |
| Plan close | *(this commit)* | SUMMARY, PARTIAL removal, STATE, ROADMAP, REQUIREMENTS |

The D-54a fix itself has no commit by design: Home Assistant configuration lives at `/config/` on
the NUC and this repo contains no HA config at all. Stated so the absence is not read as skipped
work. The exact YAML is reproduced below so a NUC rebuild can restore it.

---

## HEADLINE — WHAT THIS PLAN ACTUALLY SETTLED

1. **Criterion 4a passed, and passing proves nothing on its own.** atlantis was healthy, so the
   mount simply succeeded and the race was never exercised. Recorded as the plan required.
2. **Criterion 4b fired.** The library went stale, not empty. That is the guard working.
3. **Unattended recovery is real here: 432 s.** The disputed half is settled on this estate.
4. **M1 is proven** — and the three plans that recorded it unproven were using the wrong instrument.
5. **D-54's alerting did not fire, and that is the single most valuable output.** A live test caught
   a detector that was structurally unable to detect the thing it was written for.

---

## TASK 2 — CRITERION 4a: PASSED

**A green result here is NOT sufficient for criterion 4, and Task 3 is the reason.** atlantis was
healthy throughout, so Supervisor's mount simply succeeded; the race the phase exists to guard
against was never exercised at all. This result is fully consistent with the guards being completely
broken. It is recorded because criterion 4a asks for it, not because it settles anything.

- Maintenance window ON at 12:39Z (silencing `res02_unexpected_restart_alert`, which pages both
  phones on every HA start), OFF again at 13:2xZ. Verified both ways.
- Gateway pre-flight: `cloud-gateway-max` ACTIVE on the tailnet before rebooting, so the LAN kept a
  tailnet path while the NUC — the estate's **second** subnet router — was down.
- Pre-reboot baseline re-read LIVE, matching the staged capture exactly: mount
  `{"state":"active","read_only":true}`, `mount | grep -c emergency/music` = 0, sensor 13,
  MA albums (provider-filtered) **70**, both `Lifelines / Chris Norman` and
  `The Ultimate Hits / Garth Brooks` **EXACT**.
- Reboot issued 12:39:49Z. Down 12:41:12Z–12:42:33Z.
  boot_id `b86dada0-931d-4130-853b-19b2a0b9852a` → **`3a7906c0-e658-4f1f-93f9-c507c8c2ebd3`**
  — changed, so the reboot is proven rather than assumed.
- **NO manual intervention.** No remount, no `ha mounts reload`, no add-on restart, no hand sync.
- Post-reboot assertions: mount `{"state":"active","read_only":true}`; emergency count 0; sensor 13;
  MA albums **70**; both proof albums **EXACT**.
- **M4a fired on its own** at `2026-09-01T12:43:25.944109+00:00` — ~120 s after HA start, unprompted.
- Audit script: exit **0**, FAILURES **0**, MA **2.11.0b0**, provider `filesystem_local--XJaJWNUS`,
  albums matched in MA 2/2, in Jellyfin 2/2 (`docker-inspect:192.168.90.25:8096` — resolved fresh,
  never pinned). The VA album correctly reported `scope=temp-export`, out of scope, not asserted.

---

## TASK 3 — CRITERION 4b: THE CONTROL FIRED

- `nfs-server` stopped on atlantis 12:48:05Z, `systemctl is-active` → `inactive` (confirmed).
- Reboot 2 issued 12:48:05Z. Down 12:49:15Z–12:51:36Z.
  boot_id `3a7906c0…` → **`a2869d72-b412-4283-ba8f-ef605a5ce5f3`**.

### The verdict, and the reasoning behind it so it can be disagreed with

**The control FIRED.** Two of the three named evidence items fired. The third could not, because the
instrument named for it **does not exist on this Supervisor version** — that is a defect in the
prediction, not a missing behaviour, and the mechanism it was meant to detect was positively
identified by other means. The substance of the failure mode was reproduced in full: empty read-only
`/media/music`, MA loads, scans zero files, deletion guard preserves a stale library.

D-37's "fewer than three means not fired, inconclusive" rule exists to stop a 1-of-3 being reported
as a pass. It is not being waived here: the missing item is a **proven-invalid instrument**, and the
replacement instrument for the same mechanism produced a positive result. Stated explicitly so a
reader who disagrees can see exactly which step to attack.

### Evidence 1 — `mount | grep emergency/music`: DID NOT MATCH, and never can

⚠ **A CORRECTION TO RESEARCH.md THAT MUST NOT BE LOST.**

```
mount | grep -c -i emergency          ->  0        (no bind mount named emergency, anywhere)
ls -ld /media/music                   ->  dr--r--r--    2 root  root  4096 Sep  1 13:50 music
ls -A /media/music | wc -l            ->  0
```

Supervisor does **not** create `/mnt/data/supervisor/emergency/music` and bind-mount it. It makes the
media directory **read-only in place** and leaves it empty. Supervisor's own log names the path:

```
mounting read-only fallback for /mnt/data/supervisor/media/music
```

— the *media* path, not an `/emergency/` path.

**THE CORRECTED, WORKING PROOF LINE IS:** `/media/music` exists, is a directory, is mode
`dr--r--r--`, is root-owned, and contains **0** entries. Healthy, for contrast: `drwxrwxrwx 15
568 568`, 13 artist folders. This correction is now written into the header of the NUC's package file
as well, because that file previously asserted the emergency-bind mechanism as fact.

Note the direction of this failure: a check for `emergency/music` produces a false **negative** — it
reports "the control did not fire" when it did. That is the opposite of a silent pass and just as
dangerous, because it argues for abandoning a guard that works.

### Evidence 2 — Supervisor's read-only fallback: FIRED

ANSI stripped, otherwise unedited:

```
2026-09-01 13:50:58.312 WARNING (MainThread) [supervisor.mounts.manager] Mount music failed to mount, mounting read-only fallback for /mnt/data/supervisor/media/music
```

and immediately before it:

```
2026-09-01 13:50:58.310 ERROR (MainThread) [supervisor.mounts.mount] Mounting music did not succeed. Check host logs for errors from mount or systemd unit mnt-data-supervisor-mounts-music.mount for details.
2026-09-01 13:50:58.311 INFO (MainThread) [supervisor.resolution.module] Create new issue mount_failed - mount / music
```

⚠ **FIFTH SILENT-PASS MECHANISM IN THIS PHASE.** The **default** `ha supervisor logs` window does not
reach back to boot. A default-depth `grep -i 'read-only fallback'` returns **nothing** and is
indistinguishable from "the fallback did not happen". `-n 2000` was required to see it. The staged
command used the default depth and would have mis-recorded this as not fired.

### Evidence 3 — MA's `Aborting sync`: FIRED

```
2026-09-01 13:54:22.020 ERROR (MainThread) [music_assistant.Filesystem (local disk)] Aborting sync for Filesystem (local disk): scan found no files but 1244 were previously indexed
```

**N = 1244** previously-indexed items.

### The deletion guard held — the whole point

| | MA albums, provider-filtered on `filesystem_local--XJaJWNUS` |
|---|---|
| before | **70** |
| during the degraded window | **70** |
| after recovery | **70** |

**MA did not purge.** The library went stale, not empty — exactly as the phase predicted and exactly
as it must. Mount state during the fault: `{"state":"failed","read_only":true}`. Sensor `0`,
`last_changed 2026-09-01T12:52:06.605694+00:00`.

---

## UNATTENDED RECOVERY — THE DISPUTED QUESTION, SETTLED

- `nfs-server` restarted on atlantis, **t0 = 13:01:28Z**, `systemctl is-active` → `active`, export
  line verified intact and byte-identical:

  ```
  /mnt/tank/media/Music 172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
  ```

- Mount state polled every 60 s, **NUC untouched throughout** — no `ha mounts reload`, no add-on
  restart, no manual mount:

  ```
  13:01:39Z failed | 13:02:39Z failed | 13:03:39Z failed | 13:04:39Z failed
  13:05:39Z failed | 13:06:40Z failed | 13:07:40Z failed | 13:08:40Z ACTIVE
  ```

- **RECOVERED UNATTENDED at 13:08:40Z — 432 s (7 m 12 s) after t0.**

  This settles the half the community reports dispute against current Supervisor source: **on this
  estate, at this version, a failed media mount DOES self-recover without intervention.** Note the
  measured interval was **~7 minutes, not the ~900 s the research assumed** — the retry is more
  frequent than the plan's own text says.

- Sensor lagged as expected (`scan_interval: 300`): `0` until 13:11:54Z, **`13` at 13:12:54Z**.
- **M4b fired on its own at `2026-09-01T13:12:06.616219+00:00`** and re-synced MA. Recovery was
  self-healing; nothing was hand-triggered. This is the deviation-1 trigger the plan did not ask for,
  and it earned its place.
- Post-recovery re-assertion: mount `{"state":"active","read_only":true}`, sensor 13, MA albums
  **70**, both proof albums **EXACT**. atlantis `nfs-server` active, `uptime -s` still
  `2026-08-31 18:48:08` (unchanged — no host reboot occurred).

---

## M1 IS PROVEN — SUPERSEDING 02-03 AND 02-05

**This closes an item carried through 02-03, 02-05 and the first half of 02-08. Do not re-open it.**

### The control, run first and deliberately, to prove the instrument before spending a window

Dataset **mounted**, fresh client mount from the NUC:

```
sudo mount -t nfs4 -o ro,soft,timeo=50,retrans=2 172.16.1.158:/mnt/tank/media/Music /tmp/m1probe
CONTROL_MOUNT_EXIT=0
entries=14
```

A successful mount is therefore possible with this exact command from this exact host. **A later
failure means refusal, not incapacity** — which is what the earlier attempts could never establish.

### The probe

Dead-man restore armed on atlantis 13:41:52Z (`setsid nohup`, unconditional `zfs mount` +
`exportfs -ra` at +240 s). On atlantis, `zfs unmount tank/media/Music` (**no `-f`, ever**):

```
unmount_exit=0
mountpoint_exit=32
entries_under_mp=0
exportfs -v STILL SHOWS THE LINE:
/mnt/tank/media/Music 172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
```

NUC, same command as the control:

```
mount: mounting 172.16.1.158:/mnt/tank/media/Music on /tmp/m1probe failed: No such file or directory
M1_MOUNT_EXIT=255
entries=0
```

### Verdict, and the nuance that matters most

**M1 WORKS.** The `mountpoint` export option DOES cause `rpc.mountd` to refuse a fresh client mount
when the ZFS dataset is not mounted. Clean discriminating pair: exit 0 / 14 entries mounted, versus
exit 255 / ENOENT / 0 entries unmounted — same command, same client, minutes apart.

⚠ **THE INFERENCE, NOT THE OBSERVATION, WAS WRONG.** 02-03 and 02-05 both concluded M1 was unproven
because `exportfs -v` keeps listing the export while the dataset is unmounted. That observation was
correct. What was drawn from it was not. **The export TABLE is non-discriminating; the SERVED MOUNT
is genuinely refused.** `exportfs -v` was simply the wrong instrument for M1 all along, and the guard
was working for three plans while being recorded as unproven.

⚠ **SIXTH SILENT-PASS MECHANISM IN THIS PHASE:** `exportfs -v` showing an export line does **not**
mean that export will serve. Anything asserting export health from `exportfs -v` alone can pass
against an export that refuses every client. The only `mountpoint`-quality check is a real client
mount attempt.

### Why the earlier probes failed, and it was not what was recorded

The 02-08 first-pass probe returned `mount: permission denied (are you root?)` and was recorded as a
NUC privilege limit that would need the HAOS local console to lift. **That reading was wrong.**
Measured read-only from the SSH add-on during this continuation:

```
id                          uid=1000(sysadmin) gid=1000(sysadmin) groups=10(wheel),1000(sysadmin)
sudo -n id                  uid=0(root) gid=0(root) groups=0(root),...   <- passwordless
sudo -n -l                  (ALL) NOPASSWD: ALL
/proc/self/status CapBnd    00000000aaa635fb  -> CAP_SYS_ADMIN (bit 21) PRESENT
ha addons info a0d7b954_ssh protected=false
                            privileged=[NET_ADMIN, SYS_ADMIN, SYS_RAWIO, SYS_TIME, SYS_NICE]
```

Protection mode was **already off**. The probe failed only because it was run as `sysadmin` without
escalating. The fix was one word — `sudo`.

### Consequences

1. **02-03's `threat_flag: control-not-enforced` against `infra/nfs-music-export.tf` is RETIRED.**
   The measurement is now recorded in the file itself (`a4174e6`) so nobody re-opens it.
2. **Do NOT remove the `mountpoint` option.** It is measured to do exactly what it was added for.
3. M2 (`After=zfs-mount.service`) remains the boot-race guard; M1 is now a proven **second layer**
   beneath it rather than an unverified hope. The residual exposure previously recorded as "narrow:
   a stale or empty MA library, never data loss" is narrower still.

### Estate verified whole after the probe

atlantis: dead-man killed by PID (`deadman_pid=terminated`, 0 matching processes),
`/root/m1-deadman.sh` removed, dataset mounted, entries=14, `nfs-server` active, export line
byte-identical to the pre-probe line, `zpool status -x tank` → `pool 'tank' is healthy`, `uptime -s`
still `2026-08-31 18:48:08` (no host reboot). NUC: Supervisor mount
`{"state":"active","read_only":true}`, sensor 13, MA albums provider-filtered 70, `/tmp/m1probe`
removed.

---

## THE DEFECT THE CONTROL FOUND — D-54's ALERTING DID NOT FIRE

This is the most valuable output of the plan. A detector was built, validated as far as it could be
without a fault, and was still **structurally unable to detect the thing it was written for**. Only
firing the real fault exposed it.

### What was measured

| Automation | `last_triggered` after the fault | Should have |
|---|---|---|
| `automation.music_nfs_library_mount_failed_or_is_empty` (D-54a) | **null** | fired — the sensor held `0` for **9 minutes** against a `for: "00:05:00"` trigger. Polled 12:57:34Z and 13:01:10Z; null both times |
| `automation.music_supervisor_raised_a_system_issue` (D-54b) | **null** | fired — `Create new issue mount_failed - mount / music` at 13:50:58.311 |

### D-54a — diagnosis, in two parts. The second part is the one that matters

**Cause 1 — `numeric_state` fires on a CROSSING.** Home Assistant *arms* a `numeric_state` trigger
only when a state change evaluates as NOT matching, then fires on the next change that does match.
After a reboot into a failed mount, the sensor's first value in that HA run is already `0`, so the
trigger is never armed and there is nothing to cross. It is structurally unable to fire in the exact
scenario it was written for.

The contrast that confirms it: `music02_ma_sync_on_mount_restored` (M4b) uses `numeric_state
above: 0` — a genuine `0 → 13` crossing — and **DID** fire, at `2026-09-01T13:12:06.616219+00:00`.
Same file, same sensor, same HA run, opposite direction, opposite outcome.

**Cause 2 — and this is why the proposed fix was not enough on its own.** The defect report proposed
adding a `state` trigger with `to: "0"`. **That would have missed the boot case too.** A state trigger
only sees state changes that occur *after* the automation attaches, and on the control boot the
sensor landed on its value first. HA's own log, local time is UTC+1:

```
13:51:54.531   Setup of domain command_line took 0.07 seconds     <- the sensor's platform
12:52:06.605Z  sensor.music_library_nfs_mount last_changed, state 0
12:52:10.386Z  Setup of domain automation took 0.01 seconds
12:52:21.950Z  Initialized trigger Music: NFS library mount failed or is empty
```

The sensor reached `0` **15.3 s before** the automation was listening, and never changed again — an
unchanged poll fires no `state_changed` event at all. Reproduced live during this continuation on a
deliberate Core restart: sensor `last_changed` 13:47:05.168Z, trigger attached 13:47:10.938Z, a
**5.77 s** head start. Four HA starts observed on 2026-09-01, the ordering identical every time.

### The fix, and which part is load-bearing

Three triggers, coverage **added** not swapped:

| id | trigger | Covers | Status |
|---|---|---|---|
| `boot` | `homeassistant` `event: start` | **the reboot case** — fires AT ATTACH TIME, so it cannot be outrun by an event that happened earlier | **the load-bearing one** |
| `crossing` | `numeric_state below: 1` | the mount failing while HA is already up | the original, KEPT |
| `landed` | `state to: ["0","unknown","unavailable"]` | the sensor landing on a bad value with no numeric crossing, while HA is up | new |

`for: "00:05:00"` moved **off** the triggers and **into** the action as a `delay` plus a re-read
condition. Three reasons: the boot trigger cannot express `for:` at all; one debounce now serves all
three paths; and `for:` makes a trigger **unobservable** — nothing anywhere records that it armed,
which is precisely how this defect stayed hidden for a plan and a half. `mode: single` de-duplicates
for free when two triggers match the same state change.

### ⚠ WHICH HALF OF THE ALERT PATH WAS ACTUALLY PROVED

Stated precisely, because this phase has already caught five silent passes and an overclaim here
would be the sixth.

**PROVEN BY FIRING — the trigger path, both new triggers, trace-confirmed:**

| | `landed` (state trigger) | `boot` (homeassistant start) |
|---|---|---|
| how | sensor forced `13 → unknown` via `POST /api/states/...`. `numeric_state` cannot fire on a non-numeric value, so the run is unambiguously the state trigger | a real `ha core restart` at 13:46:14Z |
| `last_triggered` | null → `2026-09-01T13:37:40.555854Z`, **417 µs** after the state change at 13:37:40.555437Z | null → `2026-09-01T13:47:10.965423Z`, **27 ms** after the trigger attached at 13:47:10.938Z |
| trace step | `trigger/2`, `id: "landed"`, `platform: state`, `from: "13"`, `to: "unknown"` | `trigger/0`, `id: "boot"`, `platform: homeassistant`, `description: "Home Assistant starting"` |

**PROVEN BY FIRING — the action gate.** Both runs completed and both correctly refused to page:

```
delay:              {"delay": 300.0, "done": true}
condition action/1: {"result": false, "entities": ["sensor.music_library_nfs_mount"]}
script_execution:   "aborted"
action/2 (notify):  NOT PRESENT IN THE TRACE — never reached
```

So the five-minute re-read genuinely swallows a transient and a healthy mount. No false page was
sent during any of this testing.

**NOT PROVEN BY FIRING — say so plainly:**

1. **The literal `"0"` in the `to:` list has not itself fired.** Nothing can force `"0"` in isolation:
   any transition into `0` also arms and fires `crossing`, so the two cannot be separated without a
   real boot. What *is* proven is (a) the state-trigger mechanism and `to:`-list matching, on
   `unknown` from the same list, and (b) a **read-back of HA's own loaded config**, twice — via
   `automation/config` and again inside the run trace's embedded `config`:
   `{"trigger":"state","entity_id":"sensor.music_library_nfs_mount","to":["0","unknown","unavailable"],"id":"landed"}`.
   HA matches `to:` list members uniformly, so this is a sound inference — but it is an inference,
   not a firing.
2. **The notify step has never been reached from this automation against a genuinely bad mount.**
   Its delivery path is proven only as it was in Task 1: `notify.mobile_app_crusader` is a registered
   service and both message templates render against live state. Closing this needs another fault
   injection, and none was performed.
3. `crossing` was not re-fired. It is unchanged apart from losing its `for:`.

### D-54b — DIAGNOSED. Cause evidenced. NOT fixed, and recorded open

**The trigger configuration is CORRECT — proven.** A synthetic event was fired at
`POST /api/events/repairs_issue_registry_updated` with
`{"action":"create","domain":"hassio","issue_id":"SELF-TEST 02-08 synthetic event, no real issue, ignore this push"}`:

```
before: null
fired:  2026-09-01T13:32:22Z
after:  2026-09-01T13:32:22.542343+00:00     <- 542 ms
```

The notification delivered (deliberately self-labelling, so the one test push on the operator's phone
identifies itself), and the Core log shows no error from that run. `event_type` and the `event_data`
filter both match reality.

**It is blind at boot, and it is an ORDERING, not a race.** From the control boot:

```
12:50:58.311Z  Supervisor: "Create new issue mount_failed - mount / music"
               (Supervisor mounts during its own boot, long before HA Core exists)
12:51:52.927Z  HA Core: "Setup of domain hassio took 0.00 seconds"
12:51:53.032Z  hassio mirrors a Supervisor issue into HA's repairs registry — a REAL
               {action: create, domain: hassio} event. Verifiable today: repairs/list_issues
               shows issue_id 269d34e854d74e17b0e67ce71de77edb, translation_key
               issue_addon_detached_addon_removed, created 2026-09-01T12:51:53.032157+00:00
12:52:10.386Z  HA Core: "Setup of domain automation took 0.01 seconds"
12:52:21.951Z  "Initialized trigger Music: Supervisor raised a system issue"
               <- 28.92 s AFTER the event it needed to hear
```

The clincher is that `269d34e8…` is a **genuine** `hassio`-domain `create` event that matches this
trigger exactly, and it was still missed. That holds regardless of whether the `mount_failed` issue
was also mirrored (it was removed by Supervisor when the mount recovered, so it cannot be checked
after the fact — stated rather than glossed).

The `hassio → automation` setup gap was **17.7 s, 17.5 s, 17.5 s and 13.3 s** across the four HA
starts on 2026-09-01. `hassio` is a bootstrap-stage integration and `automation` is not; the order
does not vary, so this misses **every** time rather than sometimes.

**NOT FIXED — recorded open, with the reason.** Closing it needs a state-based check of Supervisor's
resolution centre at startup (a `command_line` sensor against `http://supervisor/resolution/info`
using `$SUPERVISOR_TOKEN`, which the SSH add-on's sudoers already `env_keep`s) rather than the create
event. Rejected for now on two grounds: for the only issue type this phase cares about it would
**duplicate** `music02_nfs_mount_failed_alert`, which now has its own boot trigger; and scoped any
wider it would immediately and repeatedly page for pre-existing issues nobody has chosen to act on
(today: `detached_addon_removed` for `a0d7b954_influxdb`). Both limitations are written into the
package file itself, not left as a silence.

---

## THE SILENT-PASS TALLY FOR THIS PHASE

Kept because the count is the point: six is not bad luck.

| # | Mechanism | Found in |
|---|---|---|
| 1 | `music/albums/count` has no provider parameter — reports green off Spotify with no mount | 02-04 |
| 2 | MA `POST /api` responses are not `.result`-wrapped — a `.result[]` filter under `\|\| true` reads as "no providers" | 02-04 |
| 3 | `missing_album_artist_action` reads back `folder_name` while silently using `Various Artists` | 02-07 |
| 4 | Destroying a `null_resource` removes nothing from the host — the export stayed live while `terraform plan` reported clean | 02-07 |
| 5 | Default `ha supervisor logs` depth does not reach back to boot — a default-depth grep is indistinguishable from "it did not happen" | **02-08** |
| 6 | `exportfs -v` printing an export line does not mean that export will serve | **02-08** |

Related but the opposite failure mode, so listed apart: `mount \| grep emergency/music` produces a
false **negative** — it can never match on this Supervisor version, so it argues that a working guard
did not fire.

---

## THE EXACT HA YAML — `/config/packages/music02_ma_nfs_mount.yaml`

Reproduced verbatim so a NUC rebuild can restore it. The token appears only as its `!secret`
reference. 02-09 carries this into `beets.md` per D-47. Live file: 19952 bytes,
md5 `f63c8816274e4cfb5b65b595113d4055`, `root:root`. Backup of the pre-correction version at
`/config/packages/music02_ma_nfs_mount.yaml.bak.20260901T133540Z`.

```yaml
# ============================================================================
# Music Assistant — NFS library mount: recovery sync (M4) + failure alerting
# ============================================================================
# Repo:    damianflynn/selfhost-stacks — "Music Library Consolidation"
# Phase:   02 nfs-export-and-music-assistant-reachability, plan 02-08
# Created: 2026-09-01
# Revised: 2026-09-01 (02-08 continuation) — after the live negative control.
#          Two things in the original text were WRONG and are corrected below:
#          the shape of Supervisor's fallback, and D-54a's trigger.
#
# WHY THIS FILE EXISTS
#   /media/music is an NFS mount of tank/media/Music on atlantis (172.16.1.158),
#   created by HA Supervisor (Settings > System > Storage, usage media,
#   read-only) and propagated rslave into the Music Assistant add-on container.
#
#   If atlantis is unreachable inside Supervisor's <=40 s mount window at boot,
#   Supervisor does NOT leave /media/music absent. It makes the media directory
#   READ-ONLY IN PLACE and leaves it EMPTY. Music Assistant then finds a path
#   that exists and is a directory, loads normally, scans zero files, and its
#   empty-scan deletion guard preserves the library in a STALE state: every
#   album still listed, none of them playable. Supervisor retries the real mount
#   on its own, but MA only re-reads the tree on its next sync — up to 12 hours
#   later (sync_interval stays at the 12 h default deliberately; shortening it
#   was considered and rejected as M5).
#
#   ⚠ CORRECTION, MEASURED 2026-09-01 DURING THE LIVE NEGATIVE CONTROL.
#   The original text of this header asserted that Supervisor "creates an EMPTY
#   read-only directory (/mnt/data/supervisor/emergency/music) and bind-mounts
#   THAT there instead". That is NOT what this Supervisor version does, and
#   anything that looks for it will silently never match:
#       mount | grep -c -i emergency          ->  0    (no such bind mount)
#       ls -ld /media/music                   ->  dr--r--r--  2 root root
#       ls -A /media/music | wc -l            ->  0
#       supervisor log                        ->  "mounting read-only fallback
#                                                  for /mnt/data/supervisor/
#                                                  media/music"   <- the MEDIA
#                                                  path, not an /emergency/ one
#   THE WORKING PROOF LINE IS THEREFORE:  /media/music exists, is a directory,
#   is mode dr--r--r--, is root-owned, and contains 0 entries.
#   NOT:  mount | grep emergency/music   — which can never match here.
#   Healthy, for contrast: drwxrwxrwx 15 568 568, 13 artist folders.
#
#   M4 below collapses that staleness window from <=12 h to ~2 minutes.
#   D-54 below makes the failure say something instead of sitting silent. This
#   estate has had dispatcharr and teleport down for six weeks and podsync's
#   yt-dlp broken for thirteen months; in both cases nothing said anything.
#
# WHY IT IS NOT IN THE REPO
#   Home Assistant configuration lives at /config/ on the NUC and selfhost-stacks
#   contains no HA config at all. The record of this file is
#   .planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-*.md
#   and stacks/selfhosted/arrs/beets.md. The token is a !secret and must NEVER be
#   committed — that repo is public and has one prior credential exposure.
#
# ROTATING THE TOKEN
#   secrets.yaml key: ma_ha_sync_authorization — holds the COMPLETE header value
#   ("Bearer <token>"), because Music Assistant rejects a bare token with
#   "Authentication required" (measured 2026-09-01).
#   Minted 2026-09-01 via MA `auth/token/create`, name
#   "HA M4 music sync (phase 02-08)", 1 year, no auto-renew.
#   SEPARATE from the audit-script credential in /mnt/fast/secrets/ma-deercrest.env
#   on LXC 100, so either can be replaced without breaking the other.
#     list:   {"command": "auth/tokens"}
#     revoke: {"command": "auth/token/revoke", "args": {"token_id": "..."}}
#
# PINNED VALUES — these are identities, not settings. Changing them silently
# breaks the automation without any error:
#   provider instance  filesystem_local--XJaJWNUS   (MA local filesystem provider)
#   MA endpoint        http://172.16.1.31:8095/api  (add-on, LAN IP of this NUC)
#   MA version proven  2.11.0b0 (BETA, auto_update on — stamp every assertion)
# ============================================================================

# ---------------------------------------------------------------------------
# M4 — the sync call itself.
# MA exposes no sync service to the Home Assistant integration, so this has to
# be a rest_command against MA's POST /api. That route was research-flagged as
# unverified; it is verified working as of 2026-09-01 (see 02-08 SUMMARY).
# ---------------------------------------------------------------------------
rest_command:
  music_assistant_sync_local:
    url: "http://172.16.1.31:8095/api"
    method: post
    content_type: "application/json"
    headers:
      Authorization: !secret ma_ha_sync_authorization
    payload: >-
      {"command": "music/sync",
       "args": {"providers": ["filesystem_local--XJaJWNUS"],
                "media_types": ["track"]}}
    timeout: 30

# ---------------------------------------------------------------------------
# D-54 — the detector.
#
# Counting entries under /media/music is the detector that matches the ACTUAL
# failure mode. In the failure the path exists and is a directory — it is simply
# EMPTY — so "does /media/music exist" is exactly the check that returns a false
# green. 13 top-level artist folders healthy, 0 under Supervisor's read-only
# fallback, unknown when the NFS server is gone and the soft-mount errors out.
#
# CONFIRMED IN ANGER 2026-09-01: during the negative control this sensor read
# 0 for the whole 20-minute degraded window and 13 either side of it. It is the
# instrument that works; `mount | grep emergency/music` is the one that does not
# (see the CORRECTION in the header).
#
# `ls -1` deliberately, not `ls -A`: the library root carries a .DS_Store, so
# `ls -A` reads 14 where `ls -1` reads 13. The expected value below is 13.
#
# This runs in the HA Core container, which receives the same /media bind.
# ---------------------------------------------------------------------------
command_line:
  - sensor:
      name: "Music library NFS mount"
      unique_id: music02_music_library_nfs_mount
      command: "ls -1 /media/music 2>/dev/null | wc -l"
      unit_of_measurement: "folders"
      scan_interval: 300
      command_timeout: 20

automation:
  # -------------------------------------------------------------------------
  # M4a — boot recovery. Supervisor mounts before add-ons start, so by the time
  # HA is up the mount has either succeeded or fallen back to the empty
  # read-only /media/music (see the CORRECTION in the header — there is no
  # /emergency/ bind on this version). 120 s gives Supervisor's mount work room
  # to settle before a sync is asked for.
  # -------------------------------------------------------------------------
  - id: music02_ma_sync_after_ha_start
    alias: "Music: re-sync Music Assistant 120 s after Home Assistant starts"
    description: >-
      M4. Collapses the post-reboot staleness window from <=12 h (MA's default
      sync_interval) to ~2 min. Harmless when the mount is healthy — it is a
      read-only re-scan of a 34 GB tree, ~3 min wall clock, against a ro export.
    mode: single
    triggers:
      - trigger: homeassistant
        event: start
    conditions: []
    actions:
      - delay: "00:02:00"
      - action: rest_command.music_assistant_sync_local

  # -------------------------------------------------------------------------
  # M4b — recovery after Supervisor's 900 s mount reload.
  #
  # M4a alone only covers a reboot where the mount came back immediately. The
  # window M4 actually exists to close is the other one: the mount failed at
  # boot, Supervisor re-mounted it up to 15 min later, and MA is still holding a
  # stale library because its next scheduled sync is hours away. Without this,
  # that case still waits <=12 h.
  # -------------------------------------------------------------------------
  - id: music02_ma_sync_on_mount_restored
    alias: "Music: re-sync Music Assistant when the NFS library mount returns"
    description: >-
      Fires when the folder count goes from 0/unknown back to a real value —
      i.e. Supervisor's retry replaced the empty read-only fallback with the
      real export. Also says so, because an alert that never reports recovery
      teaches people to ignore it. PROVEN 2026-09-01T13:12:06Z: it fired on its
      own after an unattended recovery and re-synced MA with nothing by hand.
    mode: single
    triggers:
      - trigger: numeric_state
        entity_id: sensor.music_library_nfs_mount
        above: 0
    conditions:
      - condition: template
        value_template: >-
          {{ trigger.from_state is not none
             and (trigger.from_state.state in ['0', 'unknown', 'unavailable']) }}
    actions:
      - action: rest_command.music_assistant_sync_local
      - action: notify.mobile_app_crusader
        data:
          title: "Music library mount recovered"
          message: >-
            /media/music is back ({{ states('sensor.music_library_nfs_mount') }}
            artist folders) and Music Assistant has been told to re-sync.
          data:
            push:
              sound:
                name: default
            interruption-level: active

  # -------------------------------------------------------------------------
  # D-54a — the failure alert that matches the real failure state.
  #
  # ⚠ THIS AUTOMATION DID NOT FIRE DURING THE 2026-09-01 NEGATIVE CONTROL, and
  # the reason is structural. It is written up here because the shape of the bug
  # is more valuable than the fix.
  #
  #   Measured: the sensor held 0 for 9+ minutes against a `for: "00:05:00"`
  #   numeric_state trigger. last_triggered stayed null.
  #
  #   Cause 1 — numeric_state fires on a CROSSING. HA arms the trigger only when
  #   a state change evaluates as NOT matching, then fires on the next change
  #   that does match. After a reboot into a failed mount the sensor's FIRST
  #   value in that HA run is already 0, so the trigger is never armed and there
  #   is nothing to cross. It is structurally unable to fire in the exact
  #   scenario it was written for.
  #   The contrast that confirms it: music02_ma_sync_on_mount_restored uses
  #   `numeric_state above: 0` — a genuine 0 -> 13 crossing — and DID fire, at
  #   2026-09-01T13:12:06Z. Same file, same sensor, same HA run, opposite
  #   direction, opposite outcome.
  #
  #   Cause 2 — and this is why adding `state: to: "0"` alone is NOT enough.
  #   A state trigger only sees state changes that happen AFTER the automation
  #   attaches. On the control boot, HA's own log gives the order:
  #       13:51:54.531  Setup of domain command_line   (the sensor's platform)
  #       12:52:06.605Z sensor.music_library_nfs_mount last_changed, state 0
  #       12:52:21.950Z "Initialized trigger Music: NFS library mount failed..."
  #   The sensor landed on 0 fifteen seconds BEFORE this automation was
  #   listening, and it never changed again (an unchanged poll fires no event).
  #   A `to: "0"` trigger would have missed it too.
  #
  # THE FIX, and which part is load-bearing:
  #   - trigger `boot` is the one that closes the reboot case. The homeassistant
  #     start trigger fires AT ATTACH TIME — HA runs it the moment the automation
  #     is set up — so it cannot be outrun by an event that happened earlier.
  #     Proven on this NUC: music02_ma_sync_after_ha_start attached at
  #     12:52:21.950Z and its last_triggered is 12:52:21.984Z, 34 ms later.
  #   - trigger `landed` covers the mount going bad while HA is already up but
  #     without a numeric crossing (e.g. after a command_line reload).
  #   - trigger `crossing` is the original and is KEPT — it still covers the
  #     ordinary case of the mount failing mid-run. Coverage was added, not
  #     swapped.
  #
  #   `for:` has moved OFF the triggers and INTO the action as a delay plus a
  #   re-read. Three reasons: (a) the boot trigger cannot express `for:` at all;
  #   (b) one debounce now serves all three paths; (c) `for:` makes a trigger
  #   unobservable — nothing anywhere records that it armed — and that is
  #   precisely how this defect stayed hidden. A trigger that fires and then
  #   evaluates a condition leaves a trace you can read.
  #
  #   mode: single de-duplicates for free. On a mid-run failure both `crossing`
  #   and `landed` match the same state change; the first run holds the slot for
  #   five minutes and the second is dropped.
  #
  #   Why 5 minutes and not longer: the measured unattended recovery on this
  #   estate was 432 s (7 m 12 s) from the NFS server returning. So a genuine
  #   boot race that heals itself CAN page ~2 minutes before it heals. That is
  #   deliberate — the library is unplayable in the meantime, and this estate's
  #   documented failure mode is silence, not noise. If it proves noisy, raise
  #   the delay to ~16 min (above Supervisor's own retry) rather than deleting
  #   the alert.
  # -------------------------------------------------------------------------
  - id: music02_nfs_mount_failed_alert
    alias: "Music: NFS library mount failed or is empty"
    description: >-
      D-54. /media/music present but empty is Supervisor's read-only fallback,
      and it is indistinguishable from a healthy mount to anything that only
      checks the path exists. 5 minutes of it is a real fault, not a blip.
    mode: single
    triggers:
      # (1) THE LOAD-BEARING ONE. Fires at attach time, so a mount that was
      #     already broken before this automation existed still gets caught.
      - trigger: homeassistant
        event: start
        id: boot
      # (2) The original. Still correct for a mount that fails mid-run.
      - trigger: numeric_state
        entity_id: sensor.music_library_nfs_mount
        below: 1
        id: crossing
      # (3) The sensor LANDS on a bad value without crossing anything.
      - trigger: state
        entity_id: sensor.music_library_nfs_mount
        to:
          - "0"
          - "unknown"
          - "unavailable"
        id: landed
    conditions: []
    actions:
      # Hold, then RE-READ. This replaces the `for:` that used to sit on the
      # triggers. A blip is not a fault; a value that is still bad five minutes
      # later is.
      - delay: "00:05:00"
      - condition: template
        value_template: >-
          {{ states('sensor.music_library_nfs_mount')
             in ['0', 'unknown', 'unavailable'] }}
      - action: notify.mobile_app_crusader
        data:
          title: "Music library mount is down"
          message: >-
            /media/music has {{ states('sensor.music_library_nfs_mount') }}
            artist folders (expected 13). Music Assistant will still list the
            albums but none of them will play. Check nfs-server on atlantis
            (172.16.1.158). Supervisor does retry on its own — measured
            2026-09-01, it recovered unattended 7 min after the server returned.
          data:
            push:
              sound:
                name: default
            interruption-level: active

  # -------------------------------------------------------------------------
  # D-54b — the literal Supervisor repairs-issue wire.
  #
  # MOUNT_FAILED reaches Home Assistant as a repairs issue in the `hassio`
  # domain with translation_key `issue_mount_mount_failed`. LIMITATION, stated
  # rather than hidden: the repairs_issue_registry_updated event carries only
  # {action, domain, issue_id}, the issue_id is an opaque Supervisor UUID, and
  # translation_key is not reachable from a template — so this cannot be
  # narrowed to mount failures alone. It therefore fires on ANY new hassio-domain
  # repairs issue. That is deliberate: hassio issues are rare (2 in the registry
  # on 2026-09-01, both raised at some point with nobody noticing) and all of
  # them are worth knowing about. music02_nfs_mount_failed_alert above is the
  # precise, mount-specific detector; this one is the broad safety net.
  #
  # ⚠ SECOND LIMITATION, MEASURED 2026-09-01 — THIS AUTOMATION IS BLIND AT BOOT,
  # AND IT IS NOT A RACE, IT IS AN ORDERING.
  #
  #   The trigger below is CORRECT. Proven directly on 2026-09-01T13:32:22Z by
  #   firing a synthetic event at POST /api/events/repairs_issue_registry_updated
  #   with {"action":"create","domain":"hassio","issue_id":"..."}: last_triggered
  #   went null -> 13:32:22.542Z, 542 ms later, and the notification delivered.
  #   The event_type and the event_data filter both match reality.
  #
  #   It still did not fire during the negative control, and the reason is that
  #   the event is emitted before this automation is listening. From the same
  #   boot, all on 2026-09-01:
  #       12:50:58.311Z  Supervisor: "Create new issue mount_failed - mount /
  #                      music"          (Supervisor mounts during its own boot,
  #                                       long before HA Core exists)
  #       12:51:52.927Z  HA Core: "Setup of domain hassio took 0.00 seconds"
  #       12:51:53.032Z  hassio mirrors a Supervisor issue into HA's repairs
  #                      registry — a REAL {action: create, domain: hassio}
  #                      event, verifiable today as issue_id
  #                      269d34e854d74e17b0e67ce71de77edb
  #       12:52:10.386Z  HA Core: "Setup of domain automation took 0.01 seconds"
  #       12:52:21.951Z  "Initialized trigger Music: Supervisor raised a system
  #                      issue"   <- 28.92 s AFTER the event it needed to hear
  #
  #   The hassio -> automation gap was 17.7 s, 17.5 s and 17.5 s across the three
  #   HA starts on 2026-09-01. hassio is a bootstrap-stage integration and
  #   automation is not; the order does not vary, so this misses EVERY time
  #   rather than sometimes.
  #
  #   NOT FIXED HERE, deliberately. Closing it needs a state-based check of
  #   Supervisor's resolution centre at startup (a command_line sensor against
  #   http://supervisor/resolution/info using $SUPERVISOR_TOKEN) rather than the
  #   create event. That was considered and rejected for now on two grounds:
  #   for the only issue type this phase cares about it would duplicate
  #   music02_nfs_mount_failed_alert, which now has its own boot trigger; and
  #   scoped any wider it would immediately and repeatedly page for pre-existing
  #   issues nobody has chosen to act on (today: detached_addon_removed for
  #   a0d7b954_influxdb). Recorded as open in 02-08-SUMMARY.md.
  # -------------------------------------------------------------------------
  - id: music02_supervisor_issue_raised
    alias: "Music: Supervisor raised a system issue"
    description: >-
      D-54's MOUNT_FAILED wire. Broad by necessity — see the comment above.
    mode: queued
    max: 10
    triggers:
      - trigger: event
        event_type: repairs_issue_registry_updated
        event_data:
          action: create
          domain: hassio
    conditions: []
    actions:
      - action: notify.mobile_app_crusader
        data:
          title: "Supervisor raised a system issue"
          message: >-
            Home Assistant Supervisor raised a new repairs issue
            ({{ trigger.event.data.issue_id }}). If the music library is
            involved this is MOUNT_FAILED — check Settings > System > Repairs.
          data:
            push:
              sound:
                name: default
            interruption-level: active
```

`/config/secrets.yaml` gained exactly one key. Its value is **not** reproduced anywhere:

```yaml
# Music Assistant long-lived API token for the M4 mount-recovery sync automation.
# Stored as the complete Authorization header value: MA rejects a bare token.
# Minted 2026-09-01 via MA auth/token/create, name "HA M4 music sync (phase 02-08)", 1-year expiry.
# SEPARATE from the audit script credential in /mnt/fast/secrets/ma-deercrest.env on LXC 100,
# so either can be revoked (auth/token/revoke) without breaking the other.
ma_ha_sync_authorization: Bearer <REDACTED — lives only on the NUC>
```

---

## TASK 1 — M4 VERIFIED WORKING, NOT DEFERRED (folded in from the PARTIAL)

D-34 required the `rest_command` route to be proven **before** anything was built on it, and
RESEARCH.md rated M4 only MEDIUM confidence precisely because that route was unverified. It is
verified, and the proof is MA's own task record — not an HTTP status.

`ha core restart` returned at `12:17:43Z`. The `homeassistant.start` trigger fired at `12:17:39Z`.
The automation waits 120 s. Music Assistant's `Sync Tracks for Filesystem (local disk)` task moved:

```
before   status=partial_success   started_at=2026-09-01T10:05:43.805042+00:00   <- 02-07's deliberate sync
after    status=success           started_at=2026-09-01T12:19:39.340638+00:00   <- M4
```

`12:17:39Z + 120 s = 12:19:39Z`, to the second. Nothing else could have caused it: MA's own schedule
for that task is 12-hourly and it last ran at `10:05`, and the MA add-on was not restarted at any
point. **The HTTP status was never used as evidence.**

It came back `success` where 02-07's full sync was `partial_success`. The `Def Leppard (2015)`
empty-album-artist error did not recur, consistent with a delta scan skipping unchanged files. The
defect is unrepaired and still owned by Phase 7; this is not evidence it went away.

### The token — a genuinely separate credential, and a correction to the record

**Correction, measured 2026-09-01:** MA 2.11 **does** have a long-lived token API. 02-04 recorded
"MA 2.11 has no API-token UI" and that is correct; the inference that no separate token was
obtainable is not. `/api-docs/commands.json` carries `auth/token/create`, `auth/tokens` and
`auth/token/revoke`:

```
auth/token/create  "Create a new long-lived access token for current user or another user (admin only).
                    Long-lived tokens are intended for external integrations and API access.
                    They expire after 1 year and do NOT auto-renew on use."
                   parameters: name (required), user_id (optional, admin only)
auth/token/revoke  parameters: token_id (required)
```

```
minted     2026-09-01
name       "HA M4 music sync (phase 02-08)"
lifetime   1 year, no auto-renew
proof      auth/me with that token alone -> {"username":"damian","role":"admin"}
storage    /config/secrets.yaml on the NUC, key ma_ha_sync_authorization
backup     /config/secrets.yaml.bak.20260901T104546Z (taken before the write)
written    over ssh stdin, never argv
length     403 chars minted, 403 chars stored (asserted equal — no truncation)
```

**MA rejects a bare token.** Measured three ways in one second:

```
Authorization: <token>          ->  "Authentication required"
Authorization: Bearer <token>   ->  {"user_id":"...","username":"damian","role":"admin",...}
{"command":"auth/me","token":"<token>"}  (in the body)  ->  "Authentication required"
```

`rest_command` headers accept neither a template nor a concatenation, so the secret holds the
**complete header value**.

### Secret hygiene (T-02-05) — re-asserted at plan close

| Assertion | Result |
|---|---|
| `grep -cE '(eyJ[A-Za-z0-9_-]{10,}\|Bearer [A-Za-z0-9._-]{20,})' /config/configuration.yaml` | **0** |
| same pattern in `/config/packages/music02_ma_nfs_mount.yaml` | **0** |
| `git grep -nE '(eyJ[A-Za-z0-9_-]{20,}\|Bearer [A-Za-z0-9._-]{20,})'` anywhere tracked | **(none)** |
| `git grep -n 'ma_ha_sync'` outside `.planning/` | **(none)** |

The token never entered this repository, never entered a local file, and never appeared in argv.

### D-38 — `sync_interval` untouched, read back

```
Sync Tracks for Filesystem (local disk)      schedule {"type":"hourly","every":12}
Sync Playlists for Filesystem (local disk)   schedule {"type":"hourly","every":12}
Sync Albums for Filesystem (local disk)      schedule {"type":"hourly","every":12}
Sync Artists for Filesystem (local disk)     schedule {"type":"hourly","every":12}
```

M5 stays rejected. Nothing in this plan wrote to MA's configuration.

---

## Deviations from Plan

### 1. [Rule 2 — missing critical functionality] M4 got a second trigger the plan did not specify

- **Issue:** the plan specifies one automation, on `homeassistant_started`. That only covers the case
  where the mount came back *immediately* at boot.
- **Fix:** `music02_ma_sync_on_mount_restored` (M4b) — re-sync when the folder count returns from
  `0`/`unknown`, and say so.
- **Vindicated in the live control:** M4b fired unprompted at `13:12:06.616219Z` after the unattended
  recovery and re-synced MA. Without it that case would still have waited up to 12 h.

### 2. [Rule 3 — blocking] The plan's own `rest_command` assertion path does not exist on this NUC

- The acceptance criteria and automated verify both read `grep -c 'rest_command'
  /config/configuration.yaml`. That file contains no integration blocks at all; every integration on
  this NUC lives in one of 29 files under `/config/packages/`.
- Declaring `rest_command:` at the top level of `configuration.yaml` *and* in a package is a hard
  YAML conflict — HA refuses a duplicate domain key. It is one place or the other.
- **Fix:** kept the package convention. Corrected assertion:
  `grep -rc rest_command /config/packages/music02_ma_nfs_mount.yaml` → **4**, plus the far stronger
  runtime check that `rest_command.music_assistant_sync_local` is a registered service observed
  causing a real MA sync.

### 3. [Rule 1 — bug] D-54a could not fire on a boot into a failed mount

The full write-up is above. Two triggers added, `for:` moved into the action, both new trigger paths
fired and trace-confirmed, action gate fired and trace-confirmed. Original coverage retained.
`/config/packages/music02_ma_nfs_mount.yaml` on the NUC (off-repo); backup
`.bak.20260901T133540Z`.

### 4. [Rule 1 — bug] The package file asserted a mechanism that does not exist on this version

The header claimed Supervisor bind-mounts `/mnt/data/supervisor/emergency/music`. Measured false.
Corrected in the header, and the two downstream repetitions in M4a's and M4b's comments were
corrected with it — a correction that leaves the same wrong claim in three other places is not a
correction.

### 5. [Rule 2 — recorded] Two Home Assistant Core restarts were performed; the NUC was not rebooted

The first (Task 1, `12:16:44Z` → `12:17:43Z`, 59 s) was unavoidable: adding `rest_command:` and
`command_line:` created two domains that did not previously exist, and `homeassistant.reload_all`
only reloads domains already set up. The second (this continuation, `13:46:14Z` → `13:47:13Z`, 59 s)
was deliberate — it is the only way to fire a `homeassistant start` trigger, and proving the
load-bearing half of the D-54a fix was worth 6 minutes.

A **core restart is not a host reboot**: it does not touch Tailscale, the subnet-router role, the
alarm, heating or cameras. `input_boolean.ha_maintenance_window` was set **on** beforehand — the
estate's own documented mechanism — so `res02_unexpected_restart_alert` did not page both phones, and
set back **off** afterwards rather than left to its 2 h auto-clear.

### 6. [Rule 2 — correction to the record] The NUC is not privilege-limited; the earlier reading was wrong

The 02-08 first-pass M1 probe was recorded as blocked by a genuine privilege limit of the HAOS SSH
add-on ("no root, no host filesystem, no docker socket") needing the local console to lift.
Measured: `sudo` is `NOPASSWD: ALL`, `CapBnd` carries `CAP_SYS_ADMIN`, and the add-on already runs
with Protection mode **off**. The probe failed for want of `sudo`, nothing more. Recording this
because "we cannot do X here" is exactly the kind of claim that ossifies if not re-tested.

### 7. [Rule 2 — recorded] One deliberate test notification was sent to the operator's phone

Firing D-54b's synthetic event is the only way to distinguish "the trigger is misconfigured" from
"the event arrived before anyone was listening", and that distinction is the whole diagnosis. The
`issue_id` was set to `SELF-TEST 02-08 synthetic event, no real issue, ignore this push` so the push
identifies itself on the lock screen. No other notification was sent: every other test run ended at
the condition gate with `script_execution: "aborted"`.

### Not fixed — logged, out of scope

- **MA's token table has 100 entries, 99 of them `WebSocket Session - damian`**, one per audit-script
  run, each with a 30-day sliding expiry. `auth/tokens` is capped at 100 in the response, so the list
  will start truncating. Now that `auth/token/create` is known to exist, the fix is a named
  long-lived token for the audit script too. **Logged for 02-09.**
- The single pre-existing long-lived token is `Xonora`, created 2026-02-21, expiring **2036**, last
  used 2026-03-29. Ten-year lifetime, unused for five months, unattributed. Not touched — not this
  plan's to revoke — but it belongs in the project-close rotation alongside the Discogs token.
- **Spotify is still `auth_required`.** Pre-existing, not caused here, not fixed. Every MA assertion
  is provider-filtered on `filesystem_local--XJaJWNUS`; the filter was never relaxed.
- **D-54b's boot blind spot** — see the diagnosis above. Open, with the specific fix recorded.
- Two pre-existing untracked files on LXC 100 (`prometheus.yaml.bak`,
  `monitoring.app.yaml.disabled`), an untracked `body.txt` at repo root, and a pre-existing
  `stash@{0}: On main: media` — none of them this plan's, none touched.

## Authentication gates

None blocking. `~/.claude/secrets/music-assistant.env` and `~/.claude/secrets/ha-deercrest.env`
authenticated on every call; the MA password reached `curl` only through a `jq`-built body on
`--data-binary @-`, never argv, and a fresh session was minted per invocation. The NUC was reached
over the tailnet address `100.73.196.51` throughout, because while it is the standby subnet router
its own LAN IP is unreachable from the tailnet.

## Housekeeping

- **The 41 local commits were PUSHED to `origin/main` with explicit operator approval** —
  `aa2b502..90cdddc`, after a clean `git pull --rebase` (no conflicts).
- **The `scp` workaround is RETIRED.** `git pull --ff-only` in `/mnt/fast/stacks` on LXC 100 now
  lands `scripts/check-music-consumers.sh` (verified this continuation: `Already up to date`, script
  present at HEAD `90cdddc`, ran from there, exit 0). **02-09's fold-in into
  `quick-health-check.sh` now has a real pull path** — this closes the blocker 02-05, 02-07 and
  02-08's first half all flagged.

## Threat Register Status

| Threat ID | Disposition | Status at plan close |
|-----------|-------------|----------------------|
| T-02-05 | mitigate | **CLOSED.** Zero bearer/JWT patterns in `configuration.yaml` or the package file; token is a `!secret` only; `git grep` clean. Re-asserted at close. |
| T-02-32 | mitigate | **CLOSED.** `systemctl is-active nfs-server` on atlantis is `active` at plan close, export line byte-identical, `zpool status -x tank` healthy, both harnesses exit 0. |
| T-02-33 | accept | **EXERCISED and survived.** Gateway confirmed ACTIVE on the tailnet before each reboot, so the LAN kept a tailnet path while the standby subnet router was down. |
| T-02-34 | mitigate | **HELD.** 4a is explicitly recorded as insufficient, with Task 3 named. 4b's verdict states its reasoning so it can be attacked. |
| T-02-35 | mitigate | **HELD.** Route A confirmed as 02-05's winner and its evidence set named before any transcript existed. D-25's re-characterisation clause did not fire. |
| T-02-36 | mitigate | **CLOSED on the real path.** Recovery re-asserted the albums after a sync that M4b triggered on its own. Staleness window is ~2 min, not ≤12 h. |
| T-02-37 | mitigate | **MOSTLY CLOSED, honestly.** D-54a's trigger path now fires on the boot case — proven, traced. Residual: the notify step has never been reached against a genuinely bad mount, and D-54b is blind at boot. Both stated above rather than smoothed over. |
| T-02-03 | mitigate | **HELD.** Nothing wrote to the library. The export is `ro`; all MA activity was read-only re-scans. |
| 02-03's `control-not-enforced` on `infra/nfs-music-export.tf` | — | **RETIRED.** M1 proven; the measurement is in the file (`a4174e6`). |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: detection-not-narrowed | `/config/packages/music02_ma_nfs_mount.yaml` (NUC, no repo file) | `music02_supervisor_issue_raised` fires on **any** new `hassio`-domain repairs issue, not on `MOUNT_FAILED` alone, and is **blind at boot** by deterministic integration-setup ordering. Both limitations are documented in the file itself. `music02_nfs_mount_failed_alert` is the precise detector and now covers the boot case. |
| threat_flag: state-not-in-git | `/config/packages/music02_ma_nfs_mount.yaml` and `/config/secrets.yaml` (NUC) | Unchanged in kind from 02-06/02-07's flags: this HA configuration has no home in any repo. Its only record is this file and, from 02-09, `beets.md`. A NUC rebuild restores it from here — the token excepted, which must be re-minted. |

## Known Stubs

None. Every artefact is live and loaded; every claim above is either a firing or is labelled as an
inference.

## Requirements

**CONS-03 is TICKED, and here is the justification.** The requirement's text is *"Music Assistant's
view survives a NUC reboot"*. Both reboots ran. With the server healthy the mount came back active,
70 albums intact, both proof albums exact, audit exit 0, and M4a re-synced unprompted. With the
server deliberately dead the failure was reproduced in full and **MA's view survived it** — 70 albums
before, 70 during, 70 after, no purge — then recovered unattended in 432 s with M4b re-syncing on its
own. Criterion 4a and 4b are both satisfied on their own terms.

**What is NOT being claimed by that tick:** the D-54 alerting is a *decision* (D-54), not part of
CONS-03's text. Its defect is fixed and its remaining gap is recorded above. 02-07 set the standard
by reverting an unearned CONS-03 tick when no reboot had happened; that standard is why this one is
earned — the reboots are the thing that was missing, and they have now happened.

`CONS-01`'s traceability row is corrected too: it carried "M1 (`mountpoint`) remains
configured-but-unproven". M1 is proven.

## Verification at plan close

```
atlantis (172.16.1.158)
  systemctl is-active nfs-server        active
  uptime -s                             2026-08-31 18:48:08   (unmoved — no host reboot)
  exportfs -v, Music line                /mnt/tank/media/Music 172.16.1.31(sync,wdelay,hide,
                                         no_subtree_check,mountpoint,anonuid=568,anongid=568,
                                         sec=sys,ro,secure,root_squash,all_squash)
  zpool status -x tank                  pool 'tank' is healthy
  /proc/pressure/io full avg300         0.34   (the 2026-08-31 halt was 96.22)

the NUC (100.73.196.51)
  boot_id                               a2869d72-b412-4283-ba8f-ef605a5ce5f3
  ha mounts info -> music               {"state":"active","read_only":true}
  ls -ld /media/music                   drwxrwxrwx 15 568 568
  ls -1 /media/music | wc -l            13
  sensor.music_library_nfs_mount        13
  ha core check                         Command completed successfully.
  four music02_* automations            all state=on, current=0
    music02_ma_sync_after_ha_start      last_triggered 2026-09-01T13:47:10.965046Z
    music02_ma_sync_on_mount_restored   last_triggered 2026-09-01T13:12:06.616219Z
    music02_nfs_mount_failed_alert      last_triggered 2026-09-01T13:47:10.965423Z   <- was null
    music02_supervisor_issue_raised     last_triggered 2026-09-01T13:32:22.542343Z   <- was null
  input_boolean.ha_maintenance_window   off

Music Assistant
  version (live)                        2.11.0b0   (BETA, auto_update on — every assertion stamped)
  albums, filesystem_local--XJaJWNUS    70
  Lifelines / Chris Norman              EXACT
  The Ultimate Hits / Garth Brooks      EXACT

LXC 100 (172.16.1.159), from a git pull rather than an scp
  check-music-consumers.sh              exit 0, FAILURES total 0, 2/2 MA, 2/2 Jellyfin
  check-music-freeze.sh                 exit 0, FAILURES total 0

repo
  terraform validate                    Success
  terraform plan -detailed-exitcode     0  (No changes)
  git grep for bearer/JWT patterns      (none)
```

## Self-Check

Files claimed created or modified:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-SUMMARY.md` — this file
- `infra/nfs-music-export.tf` — modified, commit `a4174e6`
- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-PARTIAL.md` — REMOVED

Off-repo artefacts, re-verified live at plan close:

- `/config/packages/music02_ma_nfs_mount.yaml` — 19952 bytes, md5 `f63c8816274e4cfb5b65b595113d4055`,
  `root:root`, md5 matches the source byte-for-byte
- `/config/packages/music02_ma_nfs_mount.yaml.bak.20260901T133540Z` — 11018 bytes, the
  pre-correction version
- `/config/secrets.yaml` — key `ma_ha_sync_authorization` present ×1
- `/config/secrets.yaml.bak.20260901T104546Z` — FOUND
- loaded trigger config read back from HA's runtime (not the file):
  `[{"trigger":"homeassistant","event":"start","id":"boot"},{"trigger":"numeric_state","entity_id":"sensor.music_library_nfs_mount","below":1,"id":"crossing"},{"trigger":"state","entity_id":"sensor.music_library_nfs_mount","to":["0","unknown","unavailable"],"id":"landed"}]`

## Self-Check: PASSED
