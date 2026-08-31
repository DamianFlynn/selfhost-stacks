---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 01
subsystem: infra-measurement
status: halted-at-checkpoint
tags: [nfs, stage-0, measurement, blocking-checkpoint, amdgpu-hmm]
requires: []
provides:
  - "Stage 0 measured-state record for atlantis (probes 1-7 complete)"
  - "Blocking finding: atlantis is in an active amdgpu_hmm_invalidate_gfx kernel-oops incident"
affects:
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-02-PLAN.md"
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-03-PLAN.md"
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-04-PLAN.md"
tech-stack:
  added: []
  patterns:
    - "Remote probe delegation over `ssh -o BatchMode=yes -o ConnectTimeout=N` (check-music-freeze.sh convention)"
    - "`pct exec 100 -- …` from atlantis as the fallback channel when LXC 100 sshd is unreachable"
key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-01-SUMMARY.md"
  modified: []
decisions:
  - "Stage 0 probe 4 is CLEAN — no competing export table and no `sharenfs` anywhere on `tank`"
  - "`terraform plan` could not return an exit code — it hung refreshing state against a non-serving Proxmox API"
  - "D-44's before-snapshot was deliberately NOT taken; a transcript captured during an unrelated incident cannot serve as a blast-radius baseline"
metrics:
  duration: "~35 minutes"
  completed: 2026-08-31
  tasks_completed: 1
  tasks_total: 4
---

# Phase 02 Plan 01: Stage 0 Measured State Summary

Stage 0 measurement of atlantis is complete and the export preconditions are clean — but the host is
in an **active, recurring `amdgpu_hmm_invalidate_gfx` kernel-oops incident** that halts the phase at
Task 2's blocking checkpoint.

## Status

| Task | Type | Disposition |
|------|------|-------------|
| Task 1 — atlantis export preconditions | auto | **Complete.** All seven probe groups recorded. |
| Task 2 — Terraform drift gate + Stage 0 blocking findings | checkpoint:decision (blocking) | **HALTED — awaiting operator ruling.** |
| Task 3 — NUC / Music Assistant / audit-script reachability | auto | **Not started** (gated behind Task 2). |
| Task 4 — conditional MA `/setup` | checkpoint:human-action | **Not evaluated** — its fire condition is Task 3 measurement 4, which has not run. |

---

## HEADLINE FINDING — atlantis is mid-incident

This is not a Phase 2 finding. It is a pre-existing estate incident that Stage 0 surfaced, and it is
the reason the phase cannot proceed.

**`atlantis` has oopsed four times today on the exact signature recorded in project memory as the
July 2026 incident**, and the kernel is now tainted `[D]=DIE`:

```
[Mon Aug 31 07:56:58 2026] BUG: kernel NULL pointer dereference, address: 0000000000000000
[Mon Aug 31 07:56:58 2026] Oops: Oops: 0000 [#1] SMP NOPTI
[Mon Aug 31 07:56:58 2026] CPU: 12 UID: 0 PID: 173 Comm: kcompactd0 Tainted: P           O        7.0.14-4-pve #1
[Mon Aug 31 07:56:58 2026] RIP: 0010:amdgpu_hmm_invalidate_gfx+0x42/0xd0 [amdgpu]

[Mon Aug 31 10:43:54 2026] Oops: Oops: 0000 [#2]  Comm: postgres    Tainted: P      D    O
[Mon Aug 31 12:00:06 2026] Oops: Oops: 0000 [#3]  Comm: prometheus  Tainted: P      D    O
[Mon Aug 31 12:15:04 2026] Oops: Oops: 0000 [#4]  Comm: apt-get     Tainted: P      D    O
```

`dmesg | grep -c amdgpu_hmm_invalidate_gfx` = **8** since boot (13 days uptime).

### Measured consequences

```
$ cat /proc/loadavg
358.15 357.84 355.35 1/6561 3135336

$ cat /proc/pressure/io
some avg10=98.93 avg60=98.89 avg300=98.92
full avg10=96.89 avg60=96.27 avg300=96.22

$ cat /proc/pressure/cpu
some avg10=0.00 avg60=0.00 avg300=0.00      <-- NOT cpu-bound

$ cat /proc/pressure/memory
some avg10=16.00 avg60=16.00 avg300=16.00

D-state process count (via /proc walk): 331
```

Load rose monotonically **352.11 → 358.15 across the ~12 minutes** of this measurement session.

`/proc/diskstats` reports **zero in-flight requests** on every device, so this is not a stalled disk.
The D-state `wchan` values name the real mechanism — a memory-management lock, not I/O:

```
1204875 [celeryd: celer  wchan=softleaf_entry_wait_on_locked
1287773 postgres         wchan=softleaf_entry_wait_on_locked
1763479 pveproxy worker  wchan=folio_wait_bit_common
1886959 pveproxy worker  wchan=folio_wait_bit_common
1897410 ps               wchan=show_smaps_rollup
2137    pvestatd         wchan=__access_remote_vm
2633747 postgres         wchan=ext4_buffered_write_iter
2634227 pg_isready       wchan=folio_wait_bit_common   (x9 more, a looping healthcheck piling up)
```

`softleaf_entry_wait_on_locked`, `show_smaps_rollup` and `__access_remote_vm` are all `mmap_lock`
paths. Processes are piling up behind page-table state, which is precisely what
`amdgpu_hmm_invalidate_gfx` manipulates.

### The July mitigation is fully in place and did not prevent this

This is the important part — the known remedy is already applied and was **not** sufficient:

```
$ cat /sys/kernel/mm/transparent_hugepage/enabled
always madvise [never]
$ cat /proc/sys/vm/compaction_proactiveness
0
$ grep -rn 'compaction_proactiveness' /etc/sysctl.d/
/etc/sysctl.d/99-amdgpu-hmm-mitigation.conf:8:vm.compaction_proactiveness = 0
$ cat /proc/cmdline
BOOT_IMAGE=/boot/vmlinuz-7.0.14-4-pve root=/dev/mapper/pve-root ro quiet amd_iommu=pgtbl_v2 transparent_hugepage=never
```

`vm.compaction_proactiveness = 0` suppresses only *proactive* compaction; **direct/reactive
compaction under memory pressure still runs**, and `kcompactd0` was oops victim #1 at 07:56. Memory
is 26 Gi used of 28 Gi with 2.6 Gi available — exactly the pressure that triggers reactive compaction.

**Hedged claim, flagged deliberately:** `/proc/173` (the PID the oops names as `kcompactd0`) no longer
exists, which would mean compaction has been dead for ~7 hours and fragmentation has been
accumulating unchecked ever since. **This was NOT confirmed with a second instrument.** The
verification attempt (`pgrep -a kcompactd` plus an independent `/proc` walk) **itself hung** — by then
`ps` and `pgrep` had joined the D-state pile. Recorded as unconfirmed rather than stated as settled,
per the 01-09 rule ("verify with a second independent instrument before writing it down").

### Blast radius observed during this session

- **LXC 100 sshd accepts TCP but never emits a banner.** Confirmed from two vantage points — the
  workstation over Tailscale, and atlantis itself over the LAN (`/dev/tcp/172.16.1.159/22` opens;
  `head -c 60` from the socket times out). `sshd` *is* listening (`pid=118`) and the container is
  `running`. Every LXC 100 probe in this phase must currently route via
  `ssh root@172.16.1.158 'pct exec 100 -- …'`.
- **The Proxmox API layer is not serving.** `terraform plan` hung — see Task 2 below.
- `apt-get` was oops victim #4 at 12:15. **Plan 02-02 installs `nfs-kernel-server` with `apt-get` on
  this host.** That is the same call that just took a kernel oops.

---

## Task 1 — atlantis export preconditions (COMPLETE)

All probes run over `ssh -o BatchMode=yes -o ConnectTimeout=8 root@172.16.1.158`.

### Probe 1 — dataset and mount point (A3) — PASS

```
$ zfs list -o name,mountpoint,mounted tank/media/Music
NAME              MOUNTPOINT             MOUNTED
tank/media/Music  /mnt/tank/media/Music  yes

$ mountpoint /mnt/tank/media/Music
/mnt/tank/media/Music is a mountpoint
exit=0
```

**The `mountpoint` export option (D-33 M1) is a usable option, not an assumption.**

### Probe 2 — child datasets (A4) — PASS

```
$ zfs list -r -o name,mountpoint tank/media/Music
NAME              MOUNTPOINT
tank/media/Music  /mnt/tank/media/Music
```

Exactly one row. `crossmnt` stays excluded, as RESEARCH.md intended.

### Probe 3 — ownership inherited from Phase 1 WRIT-04 — PASS

```
$ stat -c '%U:%G %u:%g %a %n' /mnt/tank/media/Music
apps:apps 568:568 777 /mnt/tank/media/Music
```

Run from atlantis, not LXC 100. Confirms `anonuid=568,anongid=568` (D-12) and confirms the tree is
still `0777`, so the export **must** be `ro`.

### Probe 4 — competing export tables (A2, D-19) — CLEAN

Verbatim, all four sub-probes:

```
$ cat /etc/exports
cat: /etc/exports: No such file or directory
exit=1

$ ls -la /etc/exports.d/
ls: cannot access '/etc/exports.d/': No such file or directory
exit=2

$ exportfs -v
bash: line 20: exportfs: command not found
exit=127

$ zfs get -r -s local,received sharenfs tank
(no output)
exit=0
```

**No competing export table exists.** `exportfs` being absent is itself consistent with A1 — the
command ships with `nfs-kernel-server`, which is not installed. **D-19's blocking condition does not
fire.**

### Probe 5 — server package and provenance (A1, T-02-SC) — PASS

```
$ dpkg -s nfs-kernel-server
dpkg-query: package 'nfs-kernel-server' is not installed and no information is available

$ apt-cache policy nfs-kernel-server
nfs-kernel-server:
  Installed: (none)
  Candidate: 1:2.8.3-1
  Version table:
     1:2.8.3-1 500
        500 http://deb.debian.org/debian trixie/main amd64 Packages
```

**T-02-SC provenance check passes** — the sole candidate origin is `http://deb.debian.org/debian
trixie/main`, a Debian archive mirror. No third-party repo offers this package. Version to be
installed by plan 02-02 is **`1:2.8.3-1`**.

### Probe 6 — listening ports before the change (B-3) — DEVIATES FROM EXPECTATION

The plan expected nothing. **Port 111 is already listening:**

```
$ ss -lntp | grep -E ':(111|2049)'
LISTEN 0 4096  0.0.0.0:111  0.0.0.0:*  users:(("rpcbind",pid=1540,fd=4),("systemd",pid=1,fd=43))
LISTEN 0 4096     [::]:111     [::]:*  users:(("rpcbind",pid=1540,fd=6),("systemd",pid=1,fd=45))

$ ss -lnup | grep -E ':(111|2049)'
UNCONN 0 0    0.0.0.0:111  0.0.0.0:*  users:(("rpcbind",pid=1540,fd=5),("systemd",pid=1,fd=44))
UNCONN 0 0       [::]:111     [::]:*  users:(("rpcbind",pid=1540,fd=7),("systemd",pid=1,fd=46))
```

Cause: `nfs-common 1:2.8.3-1` and `rpcbind 1.2.7-1` are already installed and enabled (PVE ships
them as NFS *client* support), and `rpcbind.service` / `rpcbind.socket` / `nfs-blkmap.service` are all
`enabled`.

**Correct B-3 before-state, for plan 02-03 to diff against:**

| Port | Before | Expected after |
|------|--------|----------------|
| 111/tcp + 111/udp | **already open** (rpcbind, pre-existing, unrelated to this phase) | unchanged |
| 2049/tcp | closed | open |

Asserting "111 opened as a result of this phase" would be **false**. Only 2049 is this phase's
delta.

### Probe 7 — naming the unnamed SMB writer — atlantis RULED OUT

```
$ systemctl list-units --type=service --state=running | grep -Ei 'smb|samba|nmb|nfs'
  nfs-blkmap.service   loaded active running   pNFS block layout mapping daemon

$ systemctl list-units --type=service --all | grep -Ei 'smb|samba|nmb|nfs'
  nfs-blkmap.service            loaded    active   running   pNFS block layout mapping daemon
● nfs-kernel-server.service     not-found inactive dead      nfs-kernel-server.service
● nfs-server.service            not-found inactive dead      nfs-server.service
  nfs-utils.service             loaded    inactive dead      NFS server and client services
  rpc-gssd.service              loaded    inactive dead      RPC security service for NFS client and server
  rpc-statd-notify.service      loaded    active   exited    Notify NFS peers of a restart
  rpc-svcgssd.service           loaded    inactive dead      RPC security service for NFS server
● smb.service                   not-found inactive dead      smb.service

$ ls -la /etc/samba/
-rw-r--r--  1 root root    8 Oct 16  2025 gdbcommands
-rw-r--r--  1 root root 8604 Oct 16  2025 smb.conf
```

`/etc/samba/smb.conf` exists, which looks alarming until read. Follow-up probe resolves it:

- **No Samba *server* is installed on atlantis.** Only client-side packages: `samba-common`,
  `samba-libs`, `smbclient`, `libsmbclient0`, `cifs-utils`. No `samba` / `smbd` package, and
  `smb.service` is `not-found`.
- `smb.conf` is the stock `samba-common` default and shares **only** `[homes]`, `[printers]` and
  `[print$]`. **No share of any media path.** Verbatim share stanzas:
  `[global] workgroup = WORKGROUP … map to guest = bad user` / `[homes] browseable = no, read only =
  yes, valid users = %S` / `[printers] path = /var/tmp` / `[print$] path = /var/lib/samba/printers`.

**Conclusion: atlantis is not the macOS writer.** The library tree reaches userland via one route —
`/etc/pve/lxc/100.conf:28: mp25: /mnt/tank/media/Music,mp=/mnt/tank/media/Music` — so **the writer is
a container inside LXC 100**, and that is where the enumeration must finish.

**That enumeration is INCOMPLETE.** It requires `docker ps` inside LXC 100, which is unreachable
(sshd banner hang, above). Carried as an open item for Task 3, which already probes LXC 100.

Bonus datum: the `.DS_Store` has been normalised by Phase 1's 01-08 chown and no longer reads
`65534:65534`:

```
$ stat -c '%U:%G %u:%g %a %n %y' /mnt/tank/media/Music/.DS_Store
apps:apps 568:568 777 /mnt/tank/media/Music/.DS_Store 2025-10-01 11:50:50.454172635 +0100
```

Last written **2025-10-01** — nearly 11 months ago. The writer is real but not currently active.

---

## Task 2 — Terraform drift gate (RESOLVED 2026-08-31 19:5x — ruling `update-code`)

### Resolution summary (read this before the halted transcript below)

The host recovered at **2026-08-31 18:48:08** (reboot via `sysrq s+b`; io pressure `full avg300`
96.22 → 0.59; `dmesg -T | grep -c amdgpu_hmm_invalidate_gfx` = **0** this boot). The Proxmox API
serves again, so `terraform plan` was re-run and **returned a real exit code for the first time.**

**D-17's answer is `2`, and the plan that produced it would have destroyed the Docker host.**

```
Plan: 2 to add, 1 to change, 1 to destroy
# proxmox_virtual_environment_container.selfhost must be replaced
```

`proxmox_virtual_environment_container.selfhost` **is LXC 100** — the estate's Docker host, ~102
running containers, every compose stack in the repo. A bare `terraform apply` in plan 02-03 would
have destroyed and recreated it. The landmine had been armed since February, on a config nobody had
edited, waiting for the first person to run `apply` without reading the plan.

**Cause was a provider artefact, not real infrastructure drift.** 33 `mount_point` blocks each
diffed as `mount_options = [] -> null` plus `path_in_datastore -> (known after apply)`, every one
marked `# forces replacement`. This config never sets `mount_options`; `bpg/proxmox 0.95.0` holds
`[]` in state, reads the config's absence as `null`, and treats that transition on a nested block as
replacement-forcing. The actual bind mounts on the host are correct and unchanged.

**A second, genuinely real drift was found underneath it.** `var.mpe_memory_mb` defaulted to `20480`
while LXC 102 had been running at `8192` — set by hand months ago and never reflected in code. **The
code was the drifted side, not the host.**

### Ruling recorded: `update-code`

Of the plan's five options, the operator's ruling is **`update-code`** — absorb the drift into the
Terraform rather than push code values at a running estate. Applied in two commits, nothing applied
to infrastructure:

| Commit | Change | Reasoning |
|--------|--------|-----------|
| `1588f19` | `prevent_destroy = true` **and** `ignore_changes = [mount_point]` on `selfhost`; `ignore_changes = [mount_point]` on `mpe` | Two independent guards on the Docker host deliberately: `ignore_changes` alone silences the failure mode we diagnosed, `prevent_destroy` covers the ones we have not. `mpe` gets no `prevent_destroy` — it is single-purpose, not the Docker host. |
| `3051695` | `var.mpe_memory_mb` default `20480` → `8192`, with the rationale on the variable | Adopting the host value, not pushing the code value. Raising a memory cap is the wrong direction on a 28 GB host with a live kernel bug where memory pressure drives compaction and compaction fires the amdgpu MMU notifier. |

**Trade-off, recorded in both `.tf` files so it is not discovered the hard way:** with
`ignore_changes = [mount_point]` set, Terraform will no longer act on **real** `mount_point` changes
either. Adding or removing a bind mount by editing `lxc-selfhost.tf` will now plan clean and do
nothing. Until the provider bug is fixed, bind-mount changes are a deliberate manual act — edit
`/etc/pve/lxc/100.conf` (or `pct set`), then reconcile the code.

### Post-remediation plan — verbatim, re-run by this executor

```
$ cd infra && terraform init -input=false -no-color        # INIT_EXIT=0
$ terraform plan -detailed-exitcode -input=false -no-color
null_resource.host_setup: Refreshing state... [id=840970196947308370]
null_resource.mpe_dataset: Refreshing state... [id=5470274411816671512]
proxmox_virtual_environment_container.mpe: Refreshing state... [id=102]
proxmox_virtual_environment_container.selfhost: Refreshing state... [id=100]
null_resource.patch_lxc_config_mpe: Refreshing state... [id=1685583725846800294]
null_resource.start_lxc_mpe: Refreshing state... [id=3344723184432828451]
null_resource.provision_lxc_mpe: Refreshing state... [id=4125812078130848173]
null_resource.patch_lxc_config: Refreshing state... [id=6527165114509707633]
null_resource.start_lxc: Refreshing state... [id=170581700761079279]
null_resource.provision_lxc: Refreshing state... [id=3245546985982411627]
null_resource.copy_ssh_keys: Refreshing state... [id=846225439303678084]

  # null_resource.nfs_music_export will be created
  + resource "null_resource" "nfs_music_export" {
      + id       = (known after apply)
      + triggers = {
          + "exports_content" = <<-EOT
                # Managed by Terraform (infra/nfs-music-export.tf). Do not edit by hand.
                # CONS-01: read-only export of the tagged music library to the HA NUC.
                /mnt/tank/media/Music 172.16.1.31(ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys)
            EOT
          + "revision"        = "1"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ verify_commands = <<-EOT   (the nfs-music-export verify block, additive)

TF_PLAN_EXIT=2
```

Terraform v1.15.8 on darwin_arm64, `bpg/proxmox v0.95.0`, `hashicorp/null v3.2.4`.
`infra/terraform.tfvars` present; contents deliberately not printed (T-02-05).

**Zero resources marked `forces replacement`. Zero destroys. The only pending resource is this
phase's own `null_resource.nfs_music_export`.** The residual exit code of `2` is that resource
itself — which is the *correct* reading of D-17: `infra/` now has nothing pending except Phase 2's
own change, so criterion 1's "a re-apply is clean" will measure only the export.

### What this changes for plan 02-03 — read before applying

1. **Do not run a bare `terraform apply`.** Run `terraform plan -detailed-exitcode -out=…` first,
   read it, and assert that the plan contains **exactly one** resource — `null_resource.nfs_music_export` —
   and **zero** destroys. Then apply the saved plan file. The whole point of this finding is that a
   plan nobody read was one command away from taking the estate down.
2. Criterion 1's "a re-apply is clean" is measured **unnarrowed** — a bare
   `terraform plan -detailed-exitcode` expecting **0** after the apply. The `targeted` option was
   *not* chosen, so no `-target=` expression narrows it.
3. `prevent_destroy = true` on `selfhost` is now a live guard. If a future plan legitimately needs to
   replace LXC 100, that is a code edit and a deliberate act, which is the intent.

### Historical record — the halted attempt (2026-08-31 ~16:00, host mid-incident)

Kept because it is the evidence that a hang is not an exit code, and that the July amdgpu mitigation
was insufficient.

#### `terraform plan` did not return an exit code — it hung

```
$ cd infra && terraform init -input=false
init-exit=0

$ terraform plan -detailed-exitcode -input=false -no-color
null_resource.host_setup: Refreshing state... [id=840970196947308370]
null_resource.mpe_dataset: Refreshing state... [id=5470274411816671512]
proxmox_virtual_environment_container.mpe: Refreshing state... [id=102]
proxmox_virtual_environment_container.selfhost: Refreshing state... [id=100]
Stopping operation...
Interrupt received.
Error: operation canceled

TF_PLAN_EXIT=124        <-- 124 is `timeout`'s SIGTERM code, after 420 s
```

`-detailed-exitcode` defines 0 / 1 / 2. **The measured result is none of them.** The refresh reached
all four resources and never returned, which is in-band confirmation of the headline finding: the
`pveproxy` workers serving that API are in D state.

Terraform v1.15.8, provider `bpg/proxmox v0.95.0`. `infra/terraform.tfvars` is present (55 lines,
contents deliberately not printed — T-02-05).

At the time, Task 2's acceptance criterion "exit code is captured and recorded verbatim (0, 1, or 2)"
could not be satisfied. D-17's precondition was **unproven, not disproven** — and it has since been
proven, badly, above.

**`reconcile-shares` was ruled out on evidence** and remains so — probe 4 is clean, there is no
competing export table, D-19's blocking condition does not fire.

---

## Stage 0 measured-state table (RESEARCH.md A1–A15)

| # | Assumption | Verdict | Measured value |
|---|-----------|---------|----------------|
| A1 | `nfs-kernel-server` not installed; PVE ships only `nfs-common` | **measured-true** | Not installed. `nfs-common 1:2.8.3-1` + `rpcbind 1.2.7-1` present and enabled. Candidate `1:2.8.3-1` from `deb.debian.org/debian trixie/main`. |
| A2 | Nothing exported; `sharenfs` `off` across `tank` | **measured-true** | No `/etc/exports`, no `/etc/exports.d/`, `exportfs` absent, `zfs get -r -s local,received sharenfs tank` empty. |
| A3 | `/mnt/tank/media/Music` mounted and is a mount point | **measured-true** | `mounted=yes`; `mountpoint` exits 0. |
| A4 | No child datasets under `tank/media/Music` | **measured-true** | Exactly one row. |
| A5 | NUC source address toward atlantis is `172.16.1.31` | **NOT MEASURED** | Task 3, not reached. |
| A6 | No firewall/VLAN between `.31` and `.158:2049` | **NOT MEASURED** | Task 3, not reached. |
| A7 | MA add-on is 2.9.13 stable, not 2.10.0rc6 BETA | **NOT MEASURED** | Task 3, not reached. |
| A8 | MA admin credentials exist / token can be minted | **NOT MEASURED** | Task 3 measurement 4, not reached. Task 4's fire condition is therefore unevaluated. |
| A9 | ZFS evaluates NFSv4 ACL against squashed uid | not in scope for this plan | Stage 4, plan 02-05. |
| A10 | `RequiresMountsFor=` will not resolve a ZFS mount | not in scope for this plan | Plan 02-02. |
| A11 | `folder_name` is the right `missing_album_artist_action` | resolved by decision, not measurement | D-01 (permanent, D-02). |
| A12 | Protection mode still OFF on the HA SSH add-on | **NOT MEASURED** | Task 3, not reached. |
| A13 | HAOS busybox has `showmount` / `nc` / `sha256sum` / `findmnt` | **NOT MEASURED** | Task 3, not reached. |
| A14 | MA provider setup drivable headlessly | not in scope for this plan | Plan 02-06. |
| A15 | Failed HA media mounts do self-recover on current Supervisor | not in scope for this plan | Plan 02-08 negative control. |

**Four of the nine in-scope assumptions are measured; all four hold.** The five unmeasured ones are
all NUC-side and all sit behind Task 2's blocking gate.

Two findings have **no** corresponding assumption in RESEARCH.md, because the research had no live
access to know to ask:

| New | Finding |
|-----|---------|
| **N1** | Port 111 is *already* open (rpcbind). B-3's before-state is not "nothing"; only 2049 is this phase's delta. |
| **N2** | atlantis runs no Samba server, so the macOS writer must live inside LXC 100 — narrowing D-32's target from "some share nobody has named" to one host. |

---

## Deviations from Plan

### [Rule 3 — Blocking issue] LXC 100 unreachable by SSH; probe channel switched to `pct exec`

- **Found during:** Task 1 probe 7 (the SMB enumeration needs `docker ps` inside LXC 100).
- **Issue:** `ssh root@172.16.1.159` fails with `Connection timed out during banner exchange`. Not a
  network fault — TCP opens and `sshd` is listening (`pid=118`); it never sends a banner. Reproduced
  from atlantis on the LAN, so it is not a Tailscale artefact.
- **Fix:** Probes re-routed via `ssh root@172.16.1.158 'pct exec 100 -- …'`. **No attempt was made to
  restart `sshd`** — this plan is read-only by contract except Task 4, and the host is mid-incident.
- **Caveat — the fallback is not reliable either.** `pct exec 100 -- hostname` and
  `pct exec 100 -- ss -lntp` returned fine, but `pct exec 100 -- systemctl is-active ssh sshd` and
  `pct exec 100 -- free -h` both **hung indefinitely** and had to be killed. Short commands get
  through; anything that walks `/proc` or talks to systemd joins the D-state pile. Wrap every
  `pct exec` in `timeout N` and read a hang as a symptom of the incident, not as a script bug.
  This caveat exists so nobody resuming reads "which works" above and burns time debugging their
  own command.
- **Impact on later plans:** every `ssh root@172.16.1.159` in plans 02-03 and 02-04, including
  Task 3's own automated verify, currently fails. `check-music-consumers.sh` is specified to be
  host-resident on LXC 100 (D-41).

### [Deliberate omission] D-44's before-snapshot was NOT captured

`scripts/quick-health-check.sh` was **not** run. Two reasons, both disqualifying:

1. It would be red for reasons entirely unrelated to the NFS export, so it cannot function as the
   "before half of the blast-radius argument" — an after-run compared against it would prove nothing
   about the export either way.
2. It fans out into many `ssh`, `docker` and `zfs` calls against a host where `ps`, `pgrep`,
   `apt-get` and the Proxmox API are already stalling. Each new call adds a process to a 331-deep
   D-state pile.

**D-44's before-snapshot must be taken after recovery and before plan 02-02 applies anything.** This
is now a hard precondition on plan 02-02, not a step inside plan 02-01.

### [Scope boundary] The amdgpu incident is recorded, not actioned

Diagnosed and escalated only. Nothing was restarted, killed, reconfigured or rebooted. Recovery
requires a host reboot, which the memory record notes **hangs on a graceful shutdown and needs
`sysrq s+b`** — that is squarely an operator decision on an estate running 78+ containers, and is the
substance of the checkpoint.

---

## Threat Flags

None. This plan added no code and no network surface. Threat register dispositions status:

| Threat ID | Status |
|-----------|--------|
| T-02-05 (probe output → public repo) | **mitigated.** `terraform.tfvars` contents never printed; no tokens, passwords or bearer values recorded. `git grep` for credential patterns returns nothing. |
| T-02-06 (pre-existing export table) | **measured clear.** Probe 4 clean on all four sub-probes. |
| T-02-SC (`nfs-kernel-server` provenance) | **verified.** Sole candidate origin `deb.debian.org/debian trixie/main`. |
| T-02-10 (unnamed SMB writer) | **narrowed.** atlantis ruled out; target is inside LXC 100. Enumeration incomplete pending LXC 100 access. |
| T-02-04 (NUC source address) | **not measured.** Task 3, not reached. |

---

## Known Stubs

None — this plan creates no code.

## Open Items Carried Forward

1. **BLOCKING — atlantis amdgpu HMM incident.** Task 2 checkpoint. Nothing in Phase 2 proceeds first.
2. **BLOCKING — `terraform plan` has no recorded exit code.** D-17 unproven. Re-run after recovery.
3. **LXC 100 sshd banner hang.** May resolve with the host; if it survives recovery it is its own
   defect, and it blocks `check-music-consumers.sh` being host-resident (D-41).
4. **D-44 before-snapshot outstanding.** Precondition on plan 02-02.
5. **Plan 02-02 installs `nfs-kernel-server` via `apt-get`** — the same call that took oops #4 at
   12:15. Do not run it until the host is clean.
6. **SMB writer enumeration incomplete.** Finish inside LXC 100 during Task 3 (T-02-10, D-32).
7. **B-3 before-state correction.** Port 111 is already open. Plan 02-03 must assert on 2049 only.
8. **`vm.compaction_proactiveness = 0` is not a sufficient mitigation.** It does not stop reactive
   compaction, and `kcompactd0` was oops victim #1. The July 2026 memory entry should be corrected —
   it currently reads as though the mitigation resolved the issue.

---

## Self-Check

Files claimed created:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-01-SUMMARY.md` — FOUND

Commits: this plan produced no per-task code commits (Task 1's `<files>` is `none — read-only
probes`). The single commit is this SUMMARY.

Probe transcripts retained in the session scratchpad (not committed — they are working artefacts and
the verbatim content that matters is inlined above):
`task1-probes.txt`, `task1-probe7-followup.txt`, `lxc100-sshd-diag.txt`, `atlantis-load-diag.txt`,
`atlantis-load-diag2.txt`, `atlantis-io-diag.txt`, `atlantis-oops.txt`, `atlantis-mitigation.txt`,
`tf-init.txt`, `tf-plan.txt`.

## Self-Check: PASSED
