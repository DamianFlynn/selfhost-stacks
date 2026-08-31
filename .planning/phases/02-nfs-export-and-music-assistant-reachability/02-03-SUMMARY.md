---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 03
subsystem: infra
status: complete
tags: [nfs, knfsd, exportfs, terraform-apply, zfs, systemd, cons-01, blast-radius, m1-unproven]
requires:
  - phase: 01-safety-harness-and-freeze-the-writers
    provides: "Library normalised to 568:568 (WRIT-04) — the export's anonuid/anongid; check-music-freeze.sh, the B-8 regression detector"
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-01 Stage 0 measured state (mount point, no competing export table, NUC src 172.16.1.31, D-44 before-snapshot); 02-02 the Terraform"
provides:
  - "A LIVE ro,all_squash NFSv4 export of /mnt/tank/media/Music to 172.16.1.31, served from the Proxmox host"
  - "CONS-01 parts 1a (export correct), 1b (clean re-apply, exit 0) and 1c (served from the host, not LXC 100) — proven"
  - "nfs-kernel-server 1:2.8.3-1 installed and ENABLED on atlantis (survives a host reboot)"
  - "M2 proven on disk AND in systemd: nfs-server After=zfs-mount.service"
  - "BLOCKING FINDING for 02-05: M1 (the mountpoint export option) is NOT enforced at exportfs time on nfs-utils 1:2.8.3-1 — configured but unproven"
  - "B-3 port delta measured from BOTH ends: 2049 closed->open; 111 unchanged"
  - "D-44 blast-radius AFTER-snapshot, identical to the before"
  - "B-9 recovery ordering recorded for every future zfs rollback of tank/media/Music"
affects:
  - "02-05 — owns CONS-01 parts 1d/1e, and now also owns the definitive M1 client-side test"
  - "02-04 — check-music-consumers.sh; the Jellyfin item-count-via-API assertion lands there with the D-40 key"
  - "02-09 — the full teardown runbook; the B-9 server half is recorded here"
tech-stack:
  added:
    - "nfs-kernel-server 1:2.8.3-1 (Debian trixie/main) on atlantis"
    - "libnl-genl-3-200 3.7.0-2 (transitive dependency)"
  patterns:
    - "plan -out=<file> -> terraform show -> assert resource count/destroys/forces-replacement -> apply the saved plan -> delete the plan file"
    - "Remote assertion blocks delivered over `ssh host 'bash -s' <<'EOF'` rather than nested quoting — a nested-quote bug silently returned all-zero counts on the first attempt"
    - "Second-instrument discipline: a failing assertion is diagnosed with an independent instrument before it is written down as either pass or fail"
key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-03-SUMMARY.md"
  modified:
    - "infra/outputs.tf"
    - "infra/terraform.tfstate (gitignored — null_resource.nfs_music_export recorded as applied)"
decisions:
  - "The showmount line in verify_commands was corrected BEFORE the apply, so the live output was right on first write rather than needing a second apply"
  - "M1 recorded as configured-but-UNPROVEN rather than claimed. exportfs -au + exportfs -a while the dataset is unmounted silently re-creates the export line with no warning on nfs-utils 1:2.8.3-1"
  - "CONS-01 deliberately NOT ticked. Criterion 1 has five parts; this plan closes 1a/1b/1c, and 1d/1e need a client (02-05). Traceability row updated to the precise interim state instead"
  - "zfs unmount was never forced. It succeeded cleanly (exit 0, no device busy) and the dataset was remounted and re-exported inside the same script"
metrics:
  duration: "~25 min"
  completed: 2026-08-31
  tasks_completed: 3
  tasks_total: 3
requirements-completed: []
requirements-carried: [CONS-01]
---

# Phase 02 Plan 03: Apply the Export and Prove CONS-01 Server-Side Summary

**The read-only export is live** — `ro,all_squash,anonuid=568,anongid=568,mountpoint` on
`/mnt/tank/media/Music`, restricted to the single bare address `172.16.1.31`, served by
`nfs-server` on the Proxmox host and consumed by nothing. The apply added exactly one resource and
destroyed none, and a second plan reports `No changes.`

**And the plan's headline test failed, which is the most valuable thing here.** M1 — the
`mountpoint` export option — does **not** behave as `exports(5)` documents on
`nfs-utils 1:2.8.3-1`. With the dataset unmounted, `exportfs` re-created the export line silently.
M1 is recorded as **configured but unproven**, not as passed.

## Status

| Task | Disposition |
|------|-------------|
| Task 1 — apply, prove the re-apply is clean | **Complete.** Plan exit 2 → apply exit 0 → re-plan exit **0**, `No changes.` |
| Task 2 — assert the export; prove M1 | **Complete on 1a/1c and M2. M1 FAILED to prove** — see the finding below. Dataset restored. |
| Task 3 — blast-radius after-snapshot | **Complete.** B-1, B-2, B-3, B-7, B-8 all measured; D-44 after-snapshot identical to before. |

---

## HEADLINE FINDING — M1 does not do what `exports(5)` says, on this nfs-utils

D-33's M1 is the `mountpoint` export option. Its stated job: if `nfs-server` ever starts before
`zfs-mount` at boot, export **nothing** rather than the empty stub directory beneath the unmounted
dataset. `02-CONTEXT.md` D-35 prescribes proving it by simulated unmount, and the plan's acceptance
criterion is that `exportfs -v | grep -c '/mnt/tank/media/Music'` outputs **`0`** at step 4.

**It output `1`.** Verbatim, dataset confirmed unmounted (`zfs get mounted` → `no`):

```
### STEP 2 — zfs unmount tank/media/Music  (NO -f, EVER)
unmount_exit=0
unmount_output=(none)
mounted_now=no
mountpoint_exit_now=32

### STEP 3 — systemctl start nfs-server (this is the simulated boot race)
start_exit=0
is-active=active

### STEP 4 — THE PROOF: exportfs must show NOTHING for /mnt/tank/media/Music
--- exportfs -v (VERBATIM, dataset UNMOUNTED) ---
/mnt/tank/media/Music
		172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
music_line_count_while_unmounted=1
total_export_lines_while_unmounted=1
```

### It was not written down until a second instrument had been tried

Per the 01-09 rule. Three follow-ups, all with the dataset unmounted:

| Instrument | Result | Verdict |
|---|---|---|
| `/proc/fs/nfsd/exports` (kernel table) | `# Version 1.1` / header only — **empty in BOTH states**, mounted and unmounted | **Non-discriminating.** It is a client-demand cache and populates when a client mounts. No client has mounted, so it says nothing either way. Recorded so nobody else burns time on it. |
| `/var/lib/nfs/etab` | Line **present** in both states | The persisted userspace table keeps the export |
| `exportfs -ra` stderr | **Silent** — no warning, no refusal | No refusal at convergence time |
| `exportfs -au` then `exportfs -a` (full re-evaluation, not a converge) | etab `1 → 0 → 1`. **Silently re-created** | Rules out "my convergence command didn't re-evaluate it" |
| `man 5 exports` on the host itself | *"If it isn't then the export point is not exported."* | The documented behaviour is unambiguous and is not what happened |
| `rpc.mountd` | `active`, 1 process | Present, so request-time enforcement is at least possible |

**Conclusion, stated at the confidence the evidence supports:** on `nfs-kernel-server 1:2.8.3-1`
the `mountpoint` option is **not enforced at `exportfs` time**. It is carried in the export table
and, if enforced at all, is evaluated by `rpc.mountd`/`nfsd` when a client actually requests the
export. **That test requires a client, and the client belongs to plan 02-05.** M1 therefore moves
from *configured* to *configured-but-unproven* — it does **not** move to *proven*, and it is not
claimed as a mitigation anywhere in this record.

### What this does NOT undermine — two guards that ARE proven

1. **M2 is real and is the actual boot-race fix.** The drop-in is on disk *and* systemd has read it:

   ```
   $ cat /etc/systemd/system/nfs-server.service.d/10-zfs-order.conf
   [Unit]
   After=zfs-mount.service
   Wants=zfs-mount.service

   $ systemctl show nfs-server -p After | tr ' ' '\n' | grep zfs
   zfs-mount.service
   zfs-share.service
   ```

   M1 was always the belt to M2's braces. The braces hold.

2. **The apply-time guard works.** `mountpoint -q` returned **32** (not a mount point) while
   unmounted, so `nfs-music-export.tf`'s pre-flight
   `mountpoint -q /mnt/tank/media/Music || exit 1` would have failed the apply. An apply can never
   write an export over an unmounted dataset.

The residual exposure is narrow and now named: a host reboot in which systemd's ordering is
defeated *and* the dataset is unmounted could export the empty stub. Its consequence is a stale or
empty Music Assistant library, not data loss — the export is `ro`.

**Carried as a hard item for 02-05:** while a client mount is being set up anyway, re-run the
unmount simulation and assert from the *client* side whether the mount is refused. That is the only
remaining instrument, and it costs almost nothing once 02-05's client exists.

---

## Task 1 — apply, and the clean re-apply

### The pre-apply assertion, which is the whole discipline

02-01 found a `terraform plan` one bare `apply` away from destroying LXC 100. Every assertion was
read before anything was applied:

```
$ terraform plan -out=tfplan.binary -detailed-exitcode -input=false -no-color
TF_PLAN_EXIT=2                      <-- 2 = changes present, expected

$ terraform show -no-color tfplan.binary
  # null_resource.nfs_music_export will be created
Plan: 1 to add, 0 to change, 0 to destroy.

resource_lines=1
forces_replacement=0
must_be_replaced=0
selfhost_mentions=0                 <-- selfhost absent ENTIRELY, not merely not-destroyed
nfs_music_export=1
temp_export=0                       <-- music_temp_export_enabled defaults false, gate holds
```

`terraform fmt -check -recursive` → `FMT-CLEAN`; `terraform validate` → `Success!`.
The saved plan file was **deleted immediately after the apply** (plan files may carry secrets and
are gitignored).

### The apply

```
null_resource.nfs_music_export: Creating...
  Unpacking libnl-genl-3-200:amd64 (3.7.0-2) ...
  Unpacking nfs-kernel-server (1:2.8.3-1) ...
  Created symlink '/etc/systemd/system/multi-user.target.wants/nfs-server.service' → ...
null_resource.nfs_music_export (remote-exec): --- music export ready ---
null_resource.nfs_music_export (remote-exec): /mnt/tank/media/Music
null_resource.nfs_music_export (remote-exec): 		172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
null_resource.nfs_music_export: Creation complete after 9s [id=641327131749786294]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
TF_APPLY_EXIT=0
```

`nfs-kernel-server` installed at **`1:2.8.3-1`** — exactly the version and origin T-02-SC verified
in 02-01. The apply's own two security gates both passed to get this far: the export line for
`172.16.1.31` was present after `exportfs -ra`, and `no_root_squash` was absent.

### Criterion 1b — the clean re-apply

```
$ terraform plan -detailed-exitcode -input=false -no-color
No changes. Your infrastructure matches the configuration.
TF_REAPPLY_EXIT=0
```

**Exit 0. Measured UNNARROWED** — 02-01 Task 2 recorded the ruling as `update-code`, **not**
`targeted`, so no `-target=` expression narrows this and none is restated. The `triggers` map
derives only from `local.music_export_file` (a path, an IP, two uids) and a revision string, so it
is deterministic across plans, which is what exit 0 confirms.

`infra/terraform.tfstate` contains `nfs_music_export`. It is gitignored (`infra/.gitignore:5`), as
is `terraform.tfvars` (`infra/.gitignore:2`) — verified with `git check-ignore -v`, neither is
committed.

---

## Task 2 Part A — the export asserted (criteria 1a and 1c)

### Verbatim `exportfs -v`

```
/mnt/tank/media/Music
		172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
```

The on-disk drop-in that generated it:

```
$ cat /etc/exports.d/music.exports
# Managed by Terraform (infra/nfs-music-export.tf). Do not edit by hand.
# CONS-01: read-only export of the tagged music library to the HA NUC.
/mnt/tank/media/Music 172.16.1.31(ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys)
```

### Assertion counts

| Assertion | Required | Measured |
|---|---|---|
| `/mnt/tank/media/Music` present | 1 | **1** |
| `172.16.1.31` present | 1 | **1** |
| `,ro,` present | ≥1 | **1** |
| `all_squash` present | ≥1 | **1** |
| `anonuid=568` | 1 | **1** |
| `anongid=568` | 1 | **1** |
| `mountpoint` | 1 | **1** |
| `sec=sys` | 1 | **1** |
| **`no_root_squash`** | **0** | **0** |
| wildcard `*(` | 0 | **0** |
| CIDR `/NN(` | 0 | **0** |
| `rw` as an export option | 0 | **0** |
| **total export lines** | 1 | **1** |

`root_squash` *does* appear — that is the kernel default and is **not** `no_root_squash`; it is
also moot under `all_squash`, which maps every client uid including 0 to `568:568`.

`systemctl is-active nfs-server` → **`active`**. `systemctl is-enabled nfs-server` → **`enabled`**
(D-14 — it survives a host reboot).

`/etc/exports` was created by the package install (`Creating config file /etc/exports with new
version`) and contains **no active lines** — the Terraform-managed surface remains exactly the one
drop-in, as designed.

### Criterion 1c — served from the Proxmox host, NOT LXC 100

Asserted rather than argued:

```
hostname=selfhost
nfs-server is-active: inactive
nfs-server is-enabled: not-found
nfs-kernel-server pkg: absent
exportfs binary: absent
2049 listener count: 0
--- /proc/self/uid_map (unprivileged, sparse idmap) ---
         0     100000        568
       568        568          1
       569     100569      64967
```

The container is unprivileged, so `nfsd` is not merely absent but impossible. Note the middle row:
`568 → 568` is an identity mapping, which is why the library's `apps:apps` ownership reads
correctly from inside LXC 100.

### B-3 — the port delta, measured from both ends

| Port | Before (02-01 / re-measured pre-apply) | After | This phase's delta? |
|------|--------|-------|---|
| 111/tcp | **2 listeners** (rpcbind, pre-existing `nfs-common`) | 2 listeners | **No — unchanged** |
| 2049/tcp | **0 listeners** | **2 listeners** (v4/v6) | **YES — the only delta** |

Asserted on 2049 alone. Claiming 111 as this phase's change would have been false
(`.continue-here.md` anti-pattern 3).

Confirmed from the **client** end too, which is the half that matters. 02-01 measured
`nc -w 8 -z 172.16.1.158 2049` → exit 1 (TCP RST in 0.002 s). After the apply, from the NUC:

```
hostname=a0d7b954-ssh
src_toward_atlantis=172.16.1.31      <-- still matches the export line exactly
nc_2049_exit=0                        <-- was exit 1 (RST) before the apply
nc_2049_elapsed_ms=0
nc_111_exit=0
media_music_present=no
no_nfs_mounts_yet
```

**Nothing was mounted** — mounting is plan 02-05's work and was not started. D-26's precondition
(`/media/music` absent, no NFS mounts on the NUC) still holds for 02-05.

---

## Task 2 Part B — M1

Covered in the headline finding above. Two operational points:

**`zfs unmount` was never forced.** It succeeded cleanly — `unmount_exit=0`, no output, no
`device busy`. The plan's contingency (record the blocker, never force) did not need to fire.
Notably the LXC 100 bind mount of the same path did **not** pin the dataset, and LXC 100's own view
of the library was undisturbed throughout.

**Restore verified inside the same script**, every time the simulation ran:

```
mount_exit=0  mounted=yes
exportfs_ra_exit=0
--- exportfs -v after restore (VERBATIM) ---
/mnt/tank/media/Music
		172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)
music_line_after_restore=1
mountpoint_after_restore=0
file_count_top=13
is-active=active  is-enabled=enabled
```

T-02-13 (the DoS threat of leaving the dataset unmounted or unexported) is closed: 13 top-level
entries, `mountpoint -q` exit 0, export line back, unit active **and** enabled.

---

## Task 3 — blast radius, argued from measurement

### B-8 — Phase 1's harness is untouched

`bash scripts/check-music-freeze.sh` on LXC 100:

| | Phase 1 closure (01-09) | After this plan |
|---|---|---|
| Exit code | **0** | **0** |
| `FAILURES total` | **0** | **0** |
| `ownership mismatches` | 0 | **0** |
| `tagger-class writers` | 0 | **0** |
| `unclassified writers` | 0 | **0** |
| `declared rw reaching Music` | 0 | **0** |
| `fence assertions failed` | 0 | **0** |

```
✅ Music freeze harness intact
```

An NFS export adds a second *reader* at the VFS layer and changes no inode — the measurement agrees
with the argument.

### D-44 — `quick-health-check.sh` after-snapshot

```
=== Quick Server Health Check ===
Traefik: ✅ Running
  Health:
no healthcheck
Authelia: ✅ Running
Containers running: 102
✅ No unhealthy containers
Traefik dashboard: ❌ Not accessible
Music freeze harness: ✅ Intact
    tagger-class writers:        0   (target 0)
    unclassified writers:        0   (target 0)
    declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
    ownership mismatches:        0   (target 0, want 568:568)

QHC_EXIT=0
```

**Identical to 02-01's before-snapshot, line for line.** Exit 0, 102 containers, no unhealthy
containers. `Traefik dashboard: ❌ Not accessible` is present in the **before** snapshot too — a
tailnet-vantage artefact, not a regression this plan caused. Comparison is like-for-like: the
consumers block does not fold in until 02-09.

### B-1 — Jellyfin still reads the library

Resolved at runtime, with no IP literal and never by the bare name (anti-pattern 5):

```
jellyfin_resolved=192.168.90.25
container_state=running
public_info_http=200
{"LocalAddress":"jellyfin.deercrest.info","ServerName":"jellyfin","Version":"10.11.11",...}

container_media_Music_top_entries=13
Benson Boone / BLACKPINK / Chris Norman / Def Leppard / Ed Sheeran / Garth Brooks /
Hawthorne Heights / Katy Perry / Lady Gaga / P!nk / Sabrina Carpenter / Taylor Swift / Vengaboys
```

13 artist directories read from **inside** the Jellyfin container at `/media/Music`, matching the
harness's own `artist folders: 13`. `zfs list` → `33.9G`, unchanged.

**One acceptance criterion substituted, and named.** The plan asks for "a Jellyfin API call
returning the Music library with a non-zero item count". Jellyfin's library endpoints require an
API key, and D-40 mandates a **newly minted, purpose-named** key rather than reuse of the four
unattributable `ApiKeys` rows Phase 1 found — and that key is minted in **02-04**, not here.
Substituted with the read-through proof above plus API liveness (`200`), which answers the same
question (does Jellyfin still see the library?) without minting an unowned credential. The
item-count assertion lands in 02-04 with the key.

### B-2 — LXC 100's bind mount

`pct config 100 | grep '^mp'`, before vs after, sorted and `diff`ed:

```
BYTE-IDENTICAL: yes (31 mount_point lines)
```

`mp25: /mnt/tank/media/Music,mp=/mnt/tank/media/Music` unchanged, and from LXC 100
`ls /mnt/tank/media/Music` returns the 13 artist directories.

### B-7 — no stray writes into the library

```
new_top_level_files=0        # find -maxdepth 1 -type f -newermt '2026-08-31 19:35:51 UTC'
new_txt_anywhere_60min=0     # find -maxdepth 1 -type f -name '*.txt' -mmin -60
```

Zero rows. Top level is the 13 artist directories plus the single historic `.DS_Store`
(last written 2025-10-01, T-02-10, writer no longer present). This is the clean baseline for the
same check in 02-06: MA's `check_write_access()` writes a random `.txt` at the provider root on
every provider load, and on a `ro` export that must raise and create nothing.

### B-9 — recovery ordering (operational note)

An active NFS export holds open file handles, and a stale client can block `zfs rollback`. Future
phases roll back `tank/media/Music`. **The order is:**

1. **Remove the client mount** — `ha mounts remove music` on the NUC, or stop the MA provider
2. **Unexport** — `exportfs -u 172.16.1.31:/mnt/tank/media/Music` on atlantis
3. **`zfs rollback`** `tank/media/Music@<snapshot>`
4. **Re-export** — `exportfs -ra` on atlantis (or `terraform apply`, which re-converges)

This is also the server half of D-45's tested teardown. 02-09 records the full runbook.

---

## Deviations from Plan

### 1. [Rule 2 — missing/incorrect critical information] `showmount` removed from `verify_commands`

- **Found during:** Task 1, reading the plan diff before applying.
- **Issue:** `infra/outputs.tf` emitted `showmount -e 172.16.1.158` as the "from the HA NUC"
  verification step. 02-01 Task 3 measurement 7 measured **`showmount` and `findmnt` are both
  absent** from the HA SSH add-on's userland. The line could never have run. An operator following
  the repo's own verify output would get `command not found` and could reasonably read it as "the
  export is not visible", which is a *false negative on a security-relevant check*.
- **Fix:** Replaced with `nc -z -w 5 <host> 2049` plus
  `grep -E 'nfs|/media/music' /proc/self/mountinfo` — the substitute 02-01 verified readable from
  the add-on, whose fstype column is exactly where `nfs4` will appear for criterion 1e. The
  comment names both absent commands so the substitution is not later "corrected" back.
- **Done before the apply deliberately**, so the live output was right on first write rather than
  needing a second apply. Re-planned and re-asserted afterwards: still exactly one resource, zero
  destroys, zero forces-replacement, `selfhost` absent.
- **Files modified:** `infra/outputs.tf`
- **Commit:** `57379a2`

### 2. [Finding — a plan acceptance criterion could not be met] M1 is unproven

Full detail in the headline finding. Recorded as a finding rather than worked around: the option is
in the export table exactly as designed, but the behaviour `exports(5)` documents was **not
observed**, on three independent attempts with four instruments. Not claimed as proven, not
"fixed" by forcing anything, and carried to 02-05 with the specific remaining test named.

### 3. [Verification-command correction] Nested quoting silently returned all-zero assertion counts

- **Found during:** Task 2 Part A, first attempt.
- **Issue:** The assertion block was passed inside a single-quoted `ssh host '...'` argument with
  `$(echo \"$E\" | grep -c ...)` nested inside. The quoting collapsed on the remote side; `grep`
  reported `": No such file or directory` and **every count returned `0`** — including
  `no_root_squash_count=0` and `path_present=0`. The security-relevant assertions "passed" for
  entirely spurious reasons, and `wildcard_or_cidr_count` died on a syntax error, which is the only
  reason the breakage was visible at all.
- **Why this is worth recording:** a `0` from `grep -c` is indistinguishable from a real pass on
  every *negative* assertion in this plan (`no_root_squash`, wildcard, CIDR, `rw`). Had the syntax
  error not fired, this would have been a silently passing security check — the exact failure class
  this phase exists to avoid.
- **Fix:** All remote assertion blocks are now delivered over
  `ssh host 'bash -s' <<'REMOTE' … REMOTE`, so the remote script is never re-parsed by an
  intermediate shell. Every count was re-measured and the positives are non-zero, which is itself
  the evidence that the negatives are real.
- **Files modified:** none. **Recorded as a pattern for 02-04 and 02-05.**

### 4. [Rule 1 — bug, auto-fixed] The GSD SDK corrupted two lines in `STATE.md`

- **Found during:** state updates, reviewing `git diff .planning/STATE.md` before committing.
- **Issue, two separate defects:**
  1. `state.update-progress` wrote `percent: 11` into the frontmatter while computing
     `completed_plans: 12 / total_plans: 18` and rendering the body bar as `67%`. The frontmatter
     and the body disagreed by 56 points.
  2. **`state.add-decision` silently deleted the word `none` from an unrelated pre-existing
     blocker line**, turning the amdgpu record's
     `encoding.xml HardwareAccelerationType=none` into `HardwareAccelerationType=`. That handler
     documents itself as "removes placeholders", and it appears to strip the literal token `none`
     wherever it occurs — not only where it is a placeholder. The damaged line is the record of
     **how the 2026-08-31 host outage was mitigated**; left uncorrected it would read as though
     the setting were blank.
- **Fix:** Both restored by hand — `percent: 67`, and `HardwareAccelerationType=none`. The rest of
  the `STATE.md` diff was scanned line-by-line for further deletions; there are none.
- **Why this is in scope** (it is not a pre-existing issue): both were introduced by *this plan's*
  state-update commands, in this session.
- **Carried forward:** treat `state.add-decision` / `state.add-blocker` as capable of editing
  unrelated lines. **Always `git diff .planning/STATE.md` before committing state updates.**
- **Files modified:** `.planning/STATE.md`

### 5. [Substitution, named] Jellyfin item-count-via-API deferred to 02-04

Recorded under Task 3 B-1 above. Not silently dropped: substituted with a read-through proof plus
API liveness, with the reason (D-40's newly-minted key belongs to 02-04) and the owner stated.

---

## Requirements — CONS-01 is NOT ticked, deliberately

CONS-01 reads: *"An NFSv4 export **serves** the Music dataset read-only from the Proxmox host,
defined in Terraform, restricted to the NUC."* Every clause is now satisfied **server-side** and
the reachability transition is confirmed from the client's own address.

It is still not ticked, for one reason: **this plan's own objective states criterion 1 has five
separately-falsifiable parts, and that parts 1d (visible from the NUC) and 1e (NFSv4 negotiated)
belong to plan 02-05.** This plan closes 1a, 1b and 1c. Three of five is not five.

The M1 finding is the argument made concrete, in this same session: an option that was correctly
configured, present in the live export table, and verified by every server-side assertion
nonetheless **did not behave as documented**. Nothing has yet read a single byte through this
export. Ticking "serves" now and having 02-05 discover an NFSv4 negotiation or `rpc.mountd` problem
would mean un-ticking a completed requirement — the "partial data stated as settled" failure this
project has already recorded against itself six times in Phase 1.

**What was done instead:** `REQUIREMENTS.md`'s traceability row for CONS-01 moves from bare
`Pending` to the precise interim state, so the information gained is not lost and the remaining
work is named. The checkbox at `REQUIREMENTS.md:69` stays `- [ ]`, and **02-05 owns it.**

This is a recommendation the operator can overrule in one line if they read "serves" as
server-side only.

## Threat Register Status

| Threat ID | Disposition | Status after this plan |
|-----------|-------------|------------------------|
| T-02-01 | mitigate | **Closed.** Client field is the bare address `172.16.1.31`; wildcard count 0, CIDR count 0, total export lines 1 |
| T-02-02 | mitigate | **Closed.** `all_squash`, `anonuid=568`, `anongid=568` all present in the live table, not merely in the file |
| T-02-06 | mitigate | **Both gates fired.** The apply's own assertion passed (or the apply would have failed), and the independent `exportfs -v` grep counts `no_root_squash` = **0** |
| T-02-03 | mitigate | **Server side closed** — `ro` present, `rw` count 0. The definitive write-refusal test is 02-05 Stage 4b, and this plan does not claim otherwise |
| T-02-13 | mitigate | **Closed.** Restore verified in-script: mounted, exported, `mountpoint -q` exit 0, 13 entries, unit active + enabled. `zfs unmount` never forced |
| T-02-14 | mitigate | **Closed.** No pre-existing export existed (02-01 probe 4); after the apply the table holds exactly one line |
| T-02-08 | accept | **Recorded, not discovered later.** 2049/tcp now has 2 listeners on all interfaces; 111 unchanged. Access control is the single-host export spec, not a firewall. NETWORK.md records no port forward for 2049 |
| T-02-SC | mitigate | **Closed.** `nfs-kernel-server 1:2.8.3-1` installed from `deb.debian.org/debian trixie/main`, the version and origin 02-01 pre-verified |
| T-02-05 | mitigate | **Held.** No credential value appears in this record; `terraform.tfvars` never printed; the saved plan file was deleted after the apply |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: control-not-enforced | `infra/nfs-music-export.tf` | The `mountpoint` export option is present and documented as a guard but is **not enforced at `exportfs` time** on nfs-utils 1:2.8.3-1. Anyone reading the option list would reasonably assume a protection that is unverified. The comment in the `.tf` file describing what `mountpoint` does is now stronger than what was measured. M2 (`After=zfs-mount.service`) is the proven guard; 02-05 must settle M1 from the client side. |

## Known Stubs

None. The export is live and complete. It is consumed by nothing, which is D-52's intended shape
for this increment, not a stub.

## Self-Check

Files claimed created/modified:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-03-SUMMARY.md` — FOUND
- `infra/outputs.tf` — FOUND (modified)
- `infra/terraform.tfstate` — FOUND, contains `nfs_music_export`; **gitignored**, not committed
- `tfplan.binary` — **deliberately DELETED** after the apply

Commits:

| Commit | Task |
|---|---|
| `57379a2` | Task 1 — `showmount` removed from `verify_commands` before the apply |

Tasks 2 and 3 declare `<files>none</files>` — they are assertions and a reversible service/mount
cycle — so they produce no source commits. Their record rides with this SUMMARY, matching 02-01's
precedent. Recorded explicitly so the absence is not read as skipped work.

Working tree carries no unintended changes; the pre-existing untracked `body.txt` at repo root was
left alone, and `infra/terraform.tfvars` and `infra/terraform.tfstate` remain uncommitted.

Verified: `infra/tfplan.binary` **absent** (deleted post-apply); `terraform.tfstate` contains
`nfs_music_export`; commit `57379a2` present in `git log`.

## Self-Check: PASSED
