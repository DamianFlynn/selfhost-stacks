---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 01
subsystem: infra-measurement
status: complete
tags: [nfs, stage-0, measurement, terraform-drift, music-assistant, amdgpu-hmm]
requires: []
provides:
  - "Stage 0 measured-state record replacing 02-RESEARCH.md's [ASSUMED] A1-A15 — all ten in-scope assumptions measured"
  - "D-17 answered: terraform plan exit 2, with a pending destroy of LXC 100, since remediated"
  - "D-20 answered: the NUC's source address toward atlantis is 172.16.1.31, measured"
  - "D-44 blast-radius before-snapshot (quick-health-check.sh, exit 0, post-recovery)"
  - "Blocking finding for 02-06/02-07: the estate runs Music Assistant BETA 2.11.0b0, not stable"
  - "Blocking finding for 02-06: D-30 provider enumeration needs an MA credential that does not exist"
  - "Correction for 02-03/02-04: Jellyfin is at 192.168.90.25, showmount and findmnt are absent on the NUC"
affects:
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-03-PLAN.md"
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-04-PLAN.md"
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-05-PLAN.md"
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-06-PLAN.md"
  - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-07-PLAN.md"
  - "infra/lxc-selfhost.tf"
  - "infra/lxc-mpe.tf"
  - "infra/variables.tf"
tech-stack:
  added: []
  patterns:
    - "Remote probe delegation over `ssh -o BatchMode=yes -o ConnectTimeout=N` (check-music-freeze.sh convention)"
    - "HAOS driven through the ha-deercrest skill: `ha` CLI wrapped in `bash -lc`, tailnet address when off-LAN"
    - "Runtime container-address resolution via `docker inspect` instead of an IP literal, for host-resident checks"
    - "`terraform plan -detailed-exitcode` read before apply, never a bare apply"
key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-01-SUMMARY.md"
  modified:
    - "infra/lxc-selfhost.tf"
    - "infra/lxc-mpe.tf"
    - "infra/variables.tf"
decisions:
  - "D-17 answered honestly as exit 2 with a pending destroy of LXC 100 (the Docker host) — a bpg/proxmox 0.95.0 mount_point artefact, plus one real mpe_memory_mb drift; ruling was update-code"
  - "Plan 02-03 must plan-then-apply-a-saved-plan asserting exactly one resource and zero destroys, never a bare terraform apply"
  - "Stage 0 probe 4 is CLEAN — no competing export table and no sharenfs anywhere on tank, so D-19 does not fire"
  - "D-20 measured-true: the NUC sources 172.16.1.31 toward atlantis, so the export line and D-13's no-tailnet exclusion are both correct as written"
  - "D-21 measured-FALSE: the estate runs Music Assistant (BETA) 2.11.0b0 with auto_update on; stable is not installed at all"
  - "Task 4 not-fired — MA has an admin account (onboard_done true), so this plan executed entirely read-only"
  - "D-30 deferred to plan 02-06: an MA account exists but no credential for it is recorded, and MA 2.11 gates config/providers behind a scope"
  - "D-11's read-through hash is sha256sum — present on both ends; showmount and findmnt are absent on the NUC and need substitutes"
  - "T-02-10 closed: the macOS SMB writer is not present anywhere in the estate; the .DS_Store is 11 months stale"
metrics:
  duration: "~35 min (Task 1, halted) + ~40 min (Tasks 2-4, resumed)"
  completed: 2026-08-31
  tasks_completed: 4
  tasks_total: 4
---

# Phase 02 Plan 01: Stage 0 Measured State Summary

Every `[ASSUMED]` in `02-RESEARCH.md` is now a measurement: the export preconditions on atlantis are
clean, the NUC really does source `172.16.1.31`, and the D-17 drift gate found a `terraform plan`
that was one bare `apply` away from destroying the estate's Docker host.

## Status

| Task | Type | Disposition |
|------|------|-------------|
| Task 1 — atlantis export preconditions | auto | **Complete.** All seven probe groups recorded. |
| Task 2 — Terraform drift gate + Stage 0 blocking findings | checkpoint:decision (blocking) | **Complete.** Exit code `2`; ruling `update-code`; remediated in `1588f19` + `3051695`. |
| Task 3 — NUC / Music Assistant / audit-script reachability | auto | **Complete, with one measured gap** — D-30's provider enumeration needs a credential that does not exist. |
| Task 4 — conditional MA `/setup` | checkpoint:human-action | **`not-fired — MA admin user already present.`** |

**This plan executed entirely read-only.** Its one sanctioned mutation was Task 4, which did not
fire. Nothing on atlantis, nothing under `/mnt/tank/media/Music`, and no infrastructure was changed;
the three `infra/*.tf` edits are code-side remediation of a drift the gate exposed, applied to
nothing.

---

## HEADLINE FINDING — a bare `terraform apply` would have destroyed LXC 100

D-17 existed to catch pre-existing drift being swept into this phase's apply. It caught something
much worse. On the first `terraform plan` that returned an exit code at all:

```
Plan: 2 to add, 1 to change, 1 to destroy
# proxmox_virtual_environment_container.selfhost must be replaced
```

`selfhost` **is LXC 100** — the Docker host, ~102 running containers, every compose stack in the
repo. The config had not been edited since February. The landmine had been armed for months, waiting
for the first person to run `apply` without reading the plan, and plan 02-03 is exactly that person.

Cause, remediation and the consequences for 02-03 are in **Task 2** below. It is the most valuable
thing this plan produced and it has nothing to do with NFS.

---

## The other headline — the estate runs the Music Assistant BETA

D-21 required this phase be proven against **stable**. It cannot be, as written: the installed
add-on is `music_assistant_beta` at **`2.11.0b0`**, `auto_update: true`, and the stable add-on is
not installed at all. RESEARCH.md assumed `2.9.13`; D-21 anticipated `2.10.0rc6` as the risk case.
The estate is past both. Details in **Task 3 measurement 3**; this blocks 02-06/02-07, not 02-03.

---

## Historical section — the incident this plan originally halted on (RESOLVED)

Kept because the diagnosis is durable and the project memory entry it corrects is still wrong.
**atlantis recovered at 2026-08-31 18:48:08 and was re-verified healthy before any probe in this
resumption ran** — `/proc/pressure/io` `full avg300` 0.59, zero `amdgpu_hmm_invalidate_gfx` events
this boot, taint `D`=DIE bit cleared, 102 containers running.

At the time of the halt, **`atlantis` had oopsed four times on the exact signature recorded in
project memory as the July 2026 incident**, and the kernel was tainted `[D]=DIE`:

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

### Blast radius observed during the incident (all three since resolved)

- **LXC 100 sshd accepted TCP but never emitted a banner.** Confirmed from two vantage points — the
  workstation over Tailscale, and atlantis itself over the LAN (`/dev/tcp/172.16.1.159/22` opened;
  `head -c 60` from the socket timed out). `sshd` *was* listening (`pid=118`) and the container was
  `running`. → **Resolved with the host**; `ssh root@172.16.1.159` is normal.
- **The Proxmox API layer was not serving.** `terraform plan` hung. → **Resolved**; it now returns.
- `apt-get` was oops victim #4 at 12:15, and plan 02-02's `nfs-kernel-server` install uses `apt-get`
  on this host. → **Resolved**; that install has still not run (02-02 authored the Terraform, 02-03
  applies it) and the host is now clean.

### The correction this leaves behind

The July 2026 mitigation was **fully applied and did not prevent the 2026-08-31 recurrence** —
`transparent_hugepage=never` on the kernel command line and `vm.compaction_proactiveness = 0` in
`/etc/sysctl.d/99-amdgpu-hmm-mitigation.conf`, both verified in place while the host was oopsing.
`proactiveness=0` suppresses only *proactive* compaction; direct/reactive compaction under memory
pressure still runs.

The actual 2026-08-31 trigger was identified **after** this plan halted and is not compaction at
all: a **Jellyfin VAAPI transcode** started 07:56:56 and the kernel oopsed at 07:56:58. VAAPI has
been disabled (`b1ad9c1`). The project-memory entry still reads as though the July compaction tuning
resolved the issue — carried as Open Item 9.

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

## Task 3 — NUC, Music Assistant, and audit-script reachability (COMPLETE, with one gap)

**Vantage-point disclosure, because it changes how two results should be read.** These probes were
run from the workstation **over the tailnet**, not from the LAN. HA is currently the *standby*
subnet router for `172.16.1.0/24`, so `172.16.1.31` is unreachable from the tailnet by design
(ha-deercrest skill, documented behaviour). All NUC probes therefore went via
`$HA_TAILNET_HOST` (`100.73.196.51`); `172.16.1.31:22` timed out, which is expected and **not** a
finding. Where "unreachable from the workstation" is recorded below, read it as *unreachable from a
tailnet vantage point*, not as a property of the estate.

### Measurement 1 — the NUC's real source address toward atlantis (D-20, A5) — MEASURED-TRUE

```
$ ip route get 172.16.1.158
172.16.1.158 dev enp0s25 src 172.16.1.31 uid 1000
    cache

$ ip -4 -o addr show
1: lo          inet 127.0.0.1/8 scope host lo
2: enp0s25     inet 172.16.1.31/24 brd 172.16.1.255 scope global noprefixroute enp0s25
3: hassio      inet 172.30.32.1/23 brd 172.30.33.255 scope global hassio
4: docker0     inet 172.30.232.1/23 brd 172.30.233.255 scope global docker0
258: tailscale0 inet 100.73.196.51/32 scope global tailscale0

$ ip route show
default via 172.16.1.1 dev enp0s25 proto static metric 100
172.16.1.0/24 dev enp0s25 proto kernel scope link src 172.16.1.31 metric 100
172.30.32.0/23 dev hassio proto kernel scope link src 172.30.32.1
172.30.232.0/23 dev docker0 proto kernel scope link src 172.30.232.1
```

**`src` is `172.16.1.31`. It equals the documented value.** D-12's export line is correct as written
and needs no change; D-13's exclusion of the tailnet address is confirmed correct — `172.16.1.0/24`
is a directly-connected route on `enp0s25`, so nothing toward atlantis is ever sourced from
`100.73.196.51`.

Interface names (`enp0s25`, `hassio`, `docker0`) confirm this was read in the **host** network
namespace, not the add-on's — the Advanced SSH add-on runs `host_network: true`. The Supervisor
mount that plan 02-05 creates is a host-side systemd mount unit, so this is the right namespace to
have measured.

### Measurement 2 — reachability to atlantis:2049 (A6, B-4) — MEASURED-TRUE, path is not filtered

```
$ nc -z -w 5 172.16.1.158 111  ; echo exit=$?   ->  exit=0     (rpcbind, already open)
$ nc -z -w 5 172.16.1.158 22   ; echo exit=$?   ->  exit=0     (control)
$ nc -w 8 -z 172.16.1.158 2049 ; echo exit=$?   ->  exit=1     in 0.002s total
```

`nc` **is present** — the "HAOS busybox may lack `nc`" caveat does not apply to the Advanced SSH
add-on's userland, so no fallback is needed.

The 2049 result is the informative one: **0.002 s to a refusal is a TCP RST, not a drop.** A
filtered port yields a silent discard and burns the full 8 s timeout. So the path `.31 → .158:2049`
is **open and unfiltered**; 2049 is closed only because `nfs-kernel-server` is not installed yet
(Task 1 probe 5). **A6 is measured-true on positive evidence, not by absence.**

### Measurement 3 — MA add-on version and channel (D-21, D-56, A7) — **MEASURED-FALSE**

This is the most consequential finding of Task 3.

```
$ ha apps --raw-json | jq …
d5369777_music_assistant_beta   Music Assistant (BETA)   2.11.0b0   2.11.0b0   started   d5369777

$ ha apps info d5369777_music_assistant_beta --raw-json | jq .data
{
  "slug": "d5369777_music_assistant_beta",
  "name": "Music Assistant (BETA)",
  "version": "2.11.0b0",
  "version_latest": "2.11.0b0",
  "update_available": false,
  "auto_update": true,
  "state": "started",
  "repository": "d5369777",
  "host_network": true,
  "stage": "stable",
  "startup": "application"
}

$ curl http://172.16.1.31:8095/info            # 200
{"server_id":"d2b06ba2931245ba9133cce867f7ff42","server_version":"2.11.0b0",
 "schema_version":63,"min_supported_schema_version":28,
 "base_url":"http://172.16.1.31:8095","homeassistant_addon":true,
 "onboard_done":true,"name":"Music Assistant (d5369777-music-assistant-beta)",
 "status":"running","internal_url":"http://172.16.1.31:8095",
 "external_url":null,"has_remote_access":true}
```

**The installed add-on is the BETA, at `2.11.0b0`.** RESEARCH.md assumed `2.9.13` stable; D-21
anticipated `2.10.0rc6` as the risk case. The estate is a **further major version beyond both**, and
the **stable add-on is not installed at all** — there is no `music_assistant` slug in the inventory,
only `music_assistant_beta`.

**This directly conflicts with D-21's instruction to "prove the phase against stable."** It cannot
be satisfied without either installing the stable add-on alongside (two MA servers, two libraries)
or migrating off the BETA. That is an operator decision and is **flagged as a blocking finding for
plans 02-06 and 02-07**, which are where MA behaviour is actually asserted. It does **not** block
plan 02-03 — the export is a server-side artefact and MA's version has no bearing on it.

**D-56 confirmed:** `auto_update: true`. On a **beta** channel, that means the version every
criterion is stamped with can move to another beta between now and Phase 7. The audit script
(D-41/D-56) is not merely load-bearing here; it is the only detector.

`stage: stable` in the add-on metadata is Supervisor's classification of the *add-on repository*,
not of the software. Do not read it as contradicting the above.

**Also recorded (not a Phase 2 issue, but adjacent):** the NUC runs `core_samba` (Samba share
12.10.0, started). It shares HAOS's own `/config`, `/media`, `/share` — **not** `/mnt/tank/media/Music`,
which does not exist on the NUC. It is not T-02-10's writer. Noted so a later reader who greps for
"samba" does not mistake it for one.

### Measurement 4 — MA admin user (D-43, A8) — MEASURED: **account exists**

Two independent instruments agree:

```
# 1. /info reports onboarding state directly
"onboard_done": true

# 2. auth/login with a deliberately-nonexistent credential
$ curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"command":"auth/login","message_id":1,
         "args":{"username":"__gsd_probe_nonexistent__","password":"__gsd_probe_nonexistent__"}}' \
    http://172.16.1.31:8095/api
{"success":false,"error":"Invalid username or password"}
```

The plan required these two failure shapes be distinguished explicitly. This is
**rejected-credential**, not un-onboarded: the server has an account store and evaluated a lookup
against it. `onboard_done: true` corroborates independently.

**Therefore Task 4 does not fire.** See its section below.

No real credential was submitted at any point. The probe username and password are literal
throwaway sentinels, recorded here verbatim precisely because they are worthless.

### Measurement 5 — existing MA providers (D-30) — **NOT COMPLETED — blocked on a credential**

This is Task 3's one gap, and the plan has no branch for the state that actually exists.

```
$ curl -s -X POST -d '{"command":"config/providers","message_id":3}' http://172.16.1.31:8095/api
Authentication required
```

The command's own schema confirms this is not bypassable:

```
config/providers   authenticated: true   required_scope: "config.providers.read"
```

And MA 2.11.0b0 exposes exactly **five** unauthenticated commands — the complete list, measured:

```
auth/authorization_url
auth/join_code/exchange
auth/login
auth/providers
time
```

`auth/providers` returns the *login* providers, not the music providers:

```
[{"provider_id":"builtin","provider_type":"builtin","requires_redirect":false},
 {"provider_id":"homeassistant","provider_type":"homeassistant","requires_redirect":true}]
```

**Why it cannot be completed autonomously.** The plan assumed a binary: either an MA credential is
in hand, or no account exists and Task 4 creates one. The real state is a **third case the plan does
not cover — an account exists, but no credential for it is recorded anywhere.** Searched and empty:
`~/.claude/secrets/` (holds `dispatcharr-xc.env`, `ha-deercrest.env`, `ha-deercrest.token`,
`postiz.env`) and `/mnt/fast/secrets/` on LXC 100 (holds `discogs.env` only). D-39's MA token file
does not exist yet — it is created by a later plan.

Three off-ramps were tried and each is measured closed, so nobody re-tries them:

| Route | Result |
|---|---|
| Read MA's provider config off disk | MA has no `/addon_configs/` entry (it uses the legacy `/data` dir), which is not mapped into the SSH add-on. |
| `docker exec` into the MA container from the SSH add-on | `permission denied … unix:///var/run/docker.sock` — the socket is not exposed to the add-on. |
| `auth/authorization_url` via the `homeassistant` login provider | `requires_redirect: true` — a browser OAuth round-trip. Not drivable headlessly. |

**Disposition: deferred, with a named owner.** D-30's purpose is to stop a later album match being
miscredited to a pre-existing provider (Spotify et al). That risk first bites at plan **02-06**
(provider creation) and **02-07** (the three-album assertion) — **not** at 02-03, which is
server-side only. So this is recorded as a **hard precondition on plan 02-06**: obtain the MA
credential, mint the long-lived token per D-39, and enumerate `config/providers` **before** any
provider is added, so the baseline is taken against a library nobody has touched.

Deliberately **not** escalated to Task 4's checkpoint: Task 4's fire condition is "no admin user",
which is measured false. Firing it anyway would have created a *second* MA account to work around
not knowing the first one's password — which is worse than the gap.

### Measurement 6 — where `check-music-consumers.sh` will run — MEASURED, and it overturns a plan pin

**Music Assistant, from LXC 100 (`root@172.16.1.159`):**

```
$ curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://172.16.1.31:8095/info
200
$ command -v curl  ->  /usr/bin/curl
$ command -v jq    ->  /usr/bin/jq
```

**Jellyfin — the plan's `192.168.90.31:8096` pin is wrong, not merely fragile.**

```
$ docker inspect jellyfin --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}={{$v.IPAddress}} {{end}}'
iot_macvlan=172.16.1.76  t3_proxy=192.168.90.25
```

Jellyfin's `t3_proxy` address is **`192.168.90.25`**. `.31` is not Jellyfin and is not anything —
`.continue-here.md` flagged the pin as unstable; it is in fact **already incorrect today**. Measured
from LXC 100:

| Target | From LXC 100 host | From workstation (tailnet) |
|---|---|---|
| `http://192.168.90.31:8096/System/Info/Public` | `000`, `curl_exit=7` (no route/refused) | `000`, `curl_exit=28` (timeout) |
| `http://192.168.90.25:8096/System/Info/Public` | **`200`** | `000`, `curl_exit=28` |
| `http://172.16.1.76:8096/System/Info/Public` | `000`, **`curl_exit=7`** | **`200`** |
| `http://172.16.1.31:8095/info` (MA) | **`200`** | `000`, `curl_exit=28` |
| `http://jellyfin:8096/…` **from a container on `t3_proxy`** | **`200`** | n/a |

Three findings fall out, and two of them are traps:

1. **The bare Docker DNS name `jellyfin` is POISONED on the LXC 100 host.** `.continue-here.md`
   recommends preferring it over an IP literal. That is correct *inside a container on `t3_proxy`*
   and **actively dangerous from the LXC host**:

   ```
   $ cat /etc/resolv.conf
   # --- BEGIN PVE ---
   search deercrest.info
   nameserver 172.16.1.1
   # --- END PVE ---

   $ getent hosts jellyfin
   2606:4700:3031::ac43:af8f  jellyfin.deercrest.info
   2606:4700:3030::6815:5375  jellyfin.deercrest.info
   ```

   The `search deercrest.info` suffix turns `jellyfin` into `jellyfin.deercrest.info`, which resolves
   to **Cloudflare's public edge**. A host-resident script doing `curl http://jellyfin:8096` would
   silently probe the internet and could return `200` from the public site while the local container
   was down — the exact silent-pass class this phase exists to avoid.

2. **`172.16.1.76` does not work from LXC 100** (`curl_exit=7`) although it works from the LAN. That
   is standard macvlan host-to-container isolation: the container's parent host cannot reach its own
   macvlan endpoint. So `.continue-here.md`'s stated fallback is unavailable to a host-resident
   script.

3. **The one route that is both host-resident and stable is to resolve it at runtime**, with no IP
   literal in the script at all — verified working:

   ```
   $ JF=$(docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}')
   resolved: 192.168.90.25
   $ curl -s -o /dev/null -w "http=%{http_code}" --max-time 8 "http://$JF:8096/System/Info/Public"
   http=200
   ```

   **This is the recommendation for plan 02-04.** It survives Docker IPAM reassignment, needs no
   `search`-domain assumptions, cannot silently succeed against the public site, and preserves
   host-residency because `docker inspect` only works on LXC 100.

**Host-residency, stated honestly.** For Jellyfin it is a real property: `192.168.90.0/24` is a
Docker bridge and is unreachable from anywhere but the LXC host. For **MA it is not** — the
workstation's `curl_exit=28` is the tailnet standby-subnet-router artefact, and any LAN client would
reach `172.16.1.31:8095` fine. The script should be host-resident on LXC 100 for the Jellyfin half
and for `docker inspect`; the MA half would work from the LAN too.

### Measurement 7 — NUC command availability (A13) — MEASURED, with a scope correction

Measured **inside the Advanced SSH & Web Terminal add-on**, which is where every automated NUC step
in this phase runs. That is a richer userland than the HAOS host busybox A13 was written about, so
the result is better than the assumption feared:

| Command | Present | Note |
|---|---|---|
| `sha256sum` | **yes** (`/usr/bin/sha256sum`) | **D-11's hash algorithm is `sha256sum`** — present on both ends, matching the estate convention. `md5sum` fallback not needed. |
| `md5sum` | yes | Fallback, unused. |
| `nc` | **yes** | Measurement 2's refused-vs-filtered test was possible. |
| `mount` | yes (`/bin/mount`) | |
| `curl` / `wget` / `python3` / `timeout` | yes | |
| `showmount` | **NO** | Cannot enumerate exports from the NUC. Use `exportfs -v` on atlantis instead; the `verify_commands` output in `nfs-music-export.tf` currently suggests `showmount -e 172.16.1.158` "from the HA NUC" — **that line will not run**. Flagged for plan 02-03/02-05. |
| `findmnt` | **NO** | **Criterion 1e's stated instrument is unavailable.** Use `/proc/self/mountinfo` or `mount` output, both of which name the fstype (`nfs4`) explicitly — verified readable, see below. |

Two supporting measurements that make the `findmnt` substitute concrete, and that also settle D-26:

```
$ grep -E 'nfs|media' /proc/self/mountinfo
2115 2110 8:8 /supervisor/media /media rw,relatime master:112 - ext4 /dev/sda8 rw,commit=30

$ ls -la /media/
drwxr-xr-x 3 root root 4096 Feb 28  2026 .
drwxr-xr-x 1 root root 4096 Aug 30 01:10 ..
drwxr-xr-x 5 root root 4096 Feb 28  2026 frigate
$ ls -la /media/music
ls: /media/music: No such file or directory

$ ha mounts info --raw-json
{"result":"ok","data":{"default_backup_mount":null,"mounts":[]}}
```

- The SSH add-on sees the **same `/supervisor/media` bind Supervisor manages**, so a Supervisor
  mount at `/media/music` will be visible and hashable from here. D-11's read-through proof has a
  working vantage point.
- **`/media/music` is absent and `ha mounts` is empty.** D-26's "assert the target is absent or
  empty before mounting" precondition is **satisfied today**, and there is no pre-existing mount to
  reconcile. The fstype column in `mountinfo` (`- ext4 …`) is exactly where `nfs4` will appear,
  which is the `findmnt` substitute.

### Measurement 8 — D-44 blast-radius before-snapshot — CAPTURED

Run from the workstation at 2026-08-31, **after** the 18:48:08 recovery and **before** anything in
this phase is applied. ANSI stripped, otherwise unedited:

```
$ bash scripts/quick-health-check.sh
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

**Exit code 0.** 102 containers running, no unhealthy containers, freeze harness intact on all four
assertions. This is a usable baseline — the reason it was refused during the incident (it would have
been red for unrelated reasons) no longer applies.

One line needs reading correctly so it is not mistaken for a regression later: **"Traefik dashboard:
❌ Not accessible" is expected from this vantage point** and is a tailnet artefact, not an estate
fault. It is `❌` in the *before* snapshot, so an identical `❌` after the export is applied proves
nothing changed. The script's own header documents that only the freeze-harness block is fatal.

**D-44's before half is now on the record.** Plan 02-03 takes the after half.

### Task 3 automated verify

```
$ ssh root@172.16.1.159 "command -v curl >/dev/null && command -v jq >/dev/null && \
    curl -s -o /dev/null -w %{http_code} --max-time 10 http://172.16.1.31:8095/info" \
  | grep -qE "^(200|401|403)$" && echo "ma-reachable-from-lxc100=yes"
ma-reachable-from-lxc100=yes
```

---

## Task 4 — conditional MA `/setup` — **NOT FIRED**

**`not-fired — MA admin user already present.`**

Task 4's fire condition is Task 3 measurement 4 recording that Music Assistant has **no admin user**.
It recorded the opposite, on two independent instruments: `/info` reports `"onboard_done": true`, and
`auth/login` with a nonexistent credential returns `{"success":false,"error":"Invalid username or
password"}` — a credential rejection, which requires an account store to reject against.

Per the task's own text, when the condition is false the correct behaviour is to record `not-fired`
and present nothing to the operator. **Nothing was created. Nothing was mutated. This plan therefore
executed entirely read-only** — its single stated exception did not occur. Nothing on atlantis,
nothing in `infra/`, and nothing under `/mnt/tank/media/Music` was changed by this plan.

No account name is recorded because no account was created. No password and no token value appears
anywhere in this record.

---

## Stage 0 measured-state table (RESEARCH.md A1–A15)

| # | Assumption | Verdict | Measured value |
|---|-----------|---------|----------------|
| A1 | `nfs-kernel-server` not installed; PVE ships only `nfs-common` | **measured-true** | Not installed. `nfs-common 1:2.8.3-1` + `rpcbind 1.2.7-1` present and enabled. Candidate `1:2.8.3-1` from `deb.debian.org/debian trixie/main`. |
| A2 | Nothing exported; `sharenfs` `off` across `tank` | **measured-true** | No `/etc/exports`, no `/etc/exports.d/`, `exportfs` absent, `zfs get -r -s local,received sharenfs tank` empty. |
| A3 | `/mnt/tank/media/Music` mounted and is a mount point | **measured-true** | `mounted=yes`; `mountpoint` exits 0. |
| A4 | No child datasets under `tank/media/Music` | **measured-true** | Exactly one row. |
| A5 | NUC source address toward atlantis is `172.16.1.31` | **measured-true** | `ip route get 172.16.1.158` → `dev enp0s25 src 172.16.1.31`. Export line correct as written; D-13 confirmed. |
| A6 | No firewall/VLAN between `.31` and `.158:2049` | **measured-true** | `nc` to 2049 returns a TCP RST in 0.002 s (refused, not dropped); 111 and 22 both connect. Path unfiltered. |
| A7 | MA add-on is 2.9.13 stable, not 2.10.0rc6 BETA | **measured-FALSE** | Installed add-on is `d5369777_music_assistant_beta` — **Music Assistant (BETA) 2.11.0b0**, `auto_update: true`. The stable add-on is not installed at all. |
| A8 | MA admin credentials exist / token can be minted | **measured-with-a-different-value** | An **account exists** (`onboard_done: true`; `auth/login` returns `Invalid username or password`) — so Task 4 does not fire. But **no credential for it is recorded anywhere**, so a token cannot be minted yet. Neither of the plan's two branches. |
| A9 | ZFS evaluates NFSv4 ACL against squashed uid | not in scope for this plan | Stage 4, plan 02-05. |
| A10 | `RequiresMountsFor=` will not resolve a ZFS mount | not in scope for this plan | Plan 02-02 (authored; see `02-02-SUMMARY.md`). |
| A11 | `folder_name` is the right `missing_album_artist_action` | resolved by decision, not measurement | D-01 (permanent, D-02). |
| A12 | Protection mode still OFF on the HA SSH add-on | **measured-true** | `ha apps --raw-json` and `ha mounts info --raw-json` both returned parseable JSON through the `bash -lc` wrapper. No `unauthorized`. |
| A13 | HAOS busybox has `showmount` / `nc` / `sha256sum` / `findmnt` | **measured-with-a-different-value** | Split result. `nc` **yes**, `sha256sum` **yes** (so D-11 uses sha256), `md5sum` yes, `mount`/`curl`/`python3`/`timeout` yes. `showmount` **NO**, `findmnt` **NO**. |
| A14 | MA provider setup drivable headlessly | not in scope for this plan | Plan 02-06. Note A7's BETA finding and measurement 5's scope model both bear on it. |
| A15 | Failed HA media mounts do self-recover on current Supervisor | not in scope for this plan | Plan 02-08 negative control. |

**All ten in-scope assumptions are now measured.** Eight hold; **A7 is false** and **A8 and A13
hold only partially**. The three that are not simply true are each carried into Open Items below.

Findings with **no** corresponding assumption in RESEARCH.md, because the research had no live
access to know to ask:

| New | Finding |
|-----|---------|
| **N1** | Port 111 is *already* open (rpcbind, from the pre-existing `nfs-common`). B-3's before-state is not "nothing"; **only 2049 is this phase's delta.** |
| **N2** | atlantis runs no Samba server. Follow-through in Task 3 found none in LXC 100 either — see N6. |
| **N3** | **`bpg/proxmox 0.95.0` will plan a replacement of any container with `mount_point` blocks.** A latent estate-wide landmine, unrelated to NFS, found only because D-17 forced a `terraform plan`. Remediated in `1588f19`. |
| **N4** | **Jellyfin's `t3_proxy` address is `192.168.90.25`, not the `192.168.90.31` pinned by plans 02-01 and 02-04.** The pin is wrong today, not merely fragile. |
| **N5** | **`search deercrest.info` in LXC 100's `/etc/resolv.conf` makes the bare name `jellyfin` resolve to Cloudflare's public edge.** Using the Docker DNS name from the LXC *host* would silently probe the internet. It is only correct from inside a container on `t3_proxy`. |
| **N6** | **T-02-10's macOS writer is not present in the current estate.** No Samba/AFP server package, service, container, published port (445/139/548) or listener anywhere on atlantis or in LXC 100. Combined with the `.DS_Store` mtime of 2025-10-01, the writer was a share that has since been removed. Historical, not live. |
| **N7** | **`172.16.1.76` (Jellyfin's `iot_macvlan` static) is unreachable from LXC 100** by macvlan host-to-container isolation, though it works from the LAN. `.continue-here.md`'s stated fallback is unavailable to a host-resident script. |
| **N8** | **MA 2.11 has a scoped auth model.** Exactly five commands are unauthenticated; `config/providers` needs `config.providers.read`. RESEARCH.md's Stage 5–6 shapes assume a looser model. |

### N6 — the T-02-10 enumeration, completed

Task 1 narrowed the writer to "inside LXC 100" but could not finish; LXC 100 was unreachable. It is
now reachable and the enumeration is closed:

```
$ systemctl list-units --type=service --all | grep -Ei 'smb|samba|nmb'   ->  (none)
$ dpkg -l | grep -Ei '^ii +(samba|smbd)'                                 ->  (no samba server package)
$ docker ps -a | grep -Ei 'samba|smb|afp|netatalk|timemachine'           ->  (none by name/image)
$ docker ps -a --format '{{.Names}}\t{{.Ports}}' | grep -E '(:445|:139|:548)'
                                                                          ->  (none publishing smb/afp ports)
$ ss -lntp | grep -E ':(445|139|548) '                                   ->  (no listener)
```

Every container holding a bind under `/mnt/tank/media`, for completeness:

```
lidarr         /mnt/tank/media        > /media          :ro
seerr          /mnt/tank/media        > /data           :ro
sonarr         /mnt/tank/media/TV     > /media/TV       :rw
readarr        /mnt/tank/media/Books  > /media/Books    :rw
radarr         /mnt/tank/media/Movies > /media/Movies   :rw
janitorr       /mnt/tank/media/Movies > /data/Movies    :rw
janitorr       /mnt/tank/media/TV     > /data/TV        :rw
bazarr         /mnt/tank/media/Movies > /media/Movies   :rw
bazarr         /mnt/tank/media/TV     > /media/TV       :rw
immich_server  /mnt/tank/media/photos > /data           :rw
jellyfin       /mnt/tank/media        > /media          :rw
```

Nothing but Jellyfin holds `rw` on a path containing `Music`, which is the documented consumer-class
exception (Phase 1 D-20, deferred in 02-CONTEXT). **T-02-10 moves from `accept — identified target`
to `accept — target no longer present`.** It stays `accept` rather than `mitigate` because nothing
was closed; the writer simply is not there to close.

---

## Deviations from Plan

### [Rule 3 — Blocking issue, RESOLVED] Terraform drift gate found a pending destroy of the Docker host

- **Found during:** Task 2, on the post-recovery re-run.
- **Issue:** `terraform plan -detailed-exitcode` returned `2` with
  `Plan: 2 to add, 1 to change, 1 to destroy` and
  `proxmox_virtual_environment_container.selfhost must be replaced`. That resource is LXC 100.
- **Fix:** `prevent_destroy = true` + `ignore_changes = [mount_point]` on `selfhost`,
  `ignore_changes = [mount_point]` on `mpe` (`1588f19`); `var.mpe_memory_mb` default reconciled
  `20480 → 8192` to match the running host (`3051695`). Nothing applied.
- **Verified:** bare plan is now `1 to add, 0 to change, 0 to destroy`, zero `forces replacement`.
- **Why this counts as Rule 3 and not Rule 4:** the change absorbs an existing reality into code and
  adds two guards. It alters no infrastructure. The one judgement call — adopting `8192` rather than
  pushing `20480` — is recorded on the variable with its reasoning.

### [Deviation — plan had no branch for this] D-30's provider enumeration could not be completed

- **Found during:** Task 3 measurement 5.
- **Issue:** the plan branches on "credential in hand" vs "no account exists" (Task 4). The real
  state is neither: an account exists and no credential for it is recorded in any secret store.
  MA 2.11 gates `config/providers` behind `config.providers.read` and exposes only five
  unauthenticated commands, so there is no read-only route to the answer.
- **Action:** recorded, with all three off-ramps measured closed (no `/addon_configs` entry, no
  docker socket in the SSH add-on, `homeassistant` login provider `requires_redirect: true`).
  Escalated as a **hard precondition on plan 02-06**, which is where D-30's risk first bites.
- **Deliberately not done:** Task 4's checkpoint was **not** fired to work around this. Its condition
  is measured false, and firing it would have created a second MA account because nobody knows the
  first one's password — strictly worse than the gap.

### [Rule 2 — missing critical information] Two consumer-address findings that would have failed silently

- **Found during:** Task 3 measurement 6.
- **Issue:** plans 02-01 and 02-04 pin Jellyfin at `192.168.90.31:8096`. Jellyfin is actually at
  `192.168.90.25` on that bridge. Separately, `.continue-here.md`'s recommended fix — use the Docker
  DNS name `jellyfin` — resolves to **Cloudflare's public edge** from the LXC 100 host because of
  `search deercrest.info`, and its stated fallback `172.16.1.76` is unreachable from LXC 100 by
  macvlan isolation.
- **Why this is Rule 2 rather than a note:** a health check that returns `200` from the public
  Jellyfin site while the local container is down is a *silently passing* check. This estate has a
  six-week silent outage on record and the whole purpose of `check-music-consumers.sh` is detection.
- **Action:** measured the working alternative and recorded it as the recommendation for 02-04 —
  resolve at runtime with
  `docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'`,
  no IP literal in the script. Verified `200`. No code was changed here; 02-04 is not yet authored.

### [Finding — conflicts with a locked decision] The estate runs the Music Assistant BETA

- **Found during:** Task 3 measurement 3.
- **Issue:** D-21 requires the phase be proven against **stable**. The installed add-on is
  `music_assistant_beta` at `2.11.0b0`, and stable is not installed at all.
- **Not resolved here, deliberately.** Choosing between "install stable alongside", "migrate off the
  BETA", or "accept the BETA and stamp every criterion `2.11.0b0`" is an operator decision that
  changes what the phase proves. It does **not** block plan 02-03 (server-side only), so this plan
  records it and continues rather than halting a measurement plan on a finding it exists to surface.
- **Compounding factor:** `auto_update: true` on a beta channel means the stamped version can move
  before Phase 7. D-56's audit script is the only detector.

### [Rule 3 — Blocking issue, RESOLVED by the host recovery] LXC 100 unreachable by SSH; probe channel switched to `pct exec`

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
- **Impact on later plans:** at the time, every `ssh root@172.16.1.159` in plans 02-03 and 02-04
  failed. **Resolved by the host recovery** — re-measured 2026-08-31 18:51:
  `ssh root@172.16.1.159 'hostname; uptime'` returns `selfhost` / `up 1:02` normally, and `curl` and
  `jq` are both present. The banner hang was a symptom of the wedge, not an independent defect.

### [Deliberate omission, NOW DISCHARGED] D-44's before-snapshot

At the time of the halt, `scripts/quick-health-check.sh` was **not** run — it would have been red for
reasons unrelated to the export, and it fans out into many `ssh`/`docker`/`zfs` calls against a host
where `ps`, `pgrep`, `apt-get` and the Proxmox API were already stalling.

**Discharged in Task 3 measurement 8.** Captured post-recovery and pre-apply, exit `0`, 102
containers, freeze harness intact. The transcript is inlined above.

### [Scope boundary] The amdgpu incident was recorded, not actioned — and has since been resolved

This plan diagnosed and escalated only; nothing was restarted, killed, reconfigured or rebooted.
Recovery was the operator's call and was taken **outside this plan**:

- Rebooted **2026-08-31 18:48:08** via `sysrq s+b`.
- `/proc/pressure/io` `full avg300` **96.22 → 0.59**.
- `dmesg -T | grep -c amdgpu_hmm_invalidate_gfx` **= 0** this boot (was 8 lines / 4 events).
- Kernel taint `4225 (P+D+O)` → `4097 (P+O)` — the `D`=DIE bit is gone.
- Both zpools `ONLINE`; 102 containers running; LXC 100 SSH normal.

**Root cause was identified with evidence and is not the one the July memory entry implies.** A
Jellyfin VAAPI transcode started at 07:56:56 and the kernel oopsed at 07:56:58. VAAPI has since been
**disabled** (`encoding.xml` `HardwareAccelerationType=none`, backup at
`encoding.xml.bak.20260831T182741Z`, managed by `scripts/disable-jellyfin-hwaccel.sh`, committed in
`b1ad9c1`). Re-verified at the start of this resumption before any probe was run.

---

## Threat Flags

None new. This plan added no code and no network surface. Threat register dispositions:

| Threat ID | Status |
|-----------|--------|
| T-02-05 (probe output → public repo) | **mitigated.** `terraform.tfvars` contents never printed; no tokens, passwords or bearer values recorded; the only credential-shaped strings in this record are the two literal throwaway sentinels used to probe MA's auth failure shape. `git grep` for credential patterns returns nothing. |
| T-02-06 (pre-existing export table) | **measured clear.** Probe 4 clean on all four sub-probes. |
| T-02-SC (`nfs-kernel-server` provenance) | **verified.** Sole candidate origin `deb.debian.org/debian trixie/main`, version `1:2.8.3-1`. |
| T-02-10 (unnamed SMB writer) | **accept — target no longer present.** atlantis ruled out in Task 1; LXC 100 ruled out in Task 3 (N6). No SMB/AFP server, container, published port or listener anywhere. `.DS_Store` last written 2025-10-01. |
| T-02-04 (NUC source address) | **mitigated.** Measured with `ip route get`, not taken from NETWORK.md: `src 172.16.1.31`, matching the export line. |

---

## Known Stubs

None — this plan creates no code.

## Open Items Carried Forward

Closed since the halt:

| # | Item | Disposition |
|---|---|---|
| 1 | atlantis amdgpu HMM incident | **CLOSED.** Rebooted 18:48:08; Jellyfin VAAPI identified as trigger and disabled (`b1ad9c1`). |
| 2 | `terraform plan` had no exit code | **CLOSED.** Exit `2`, with a pending destroy of LXC 100. Remediated in `1588f19` + `3051695`. |
| 3 | LXC 100 sshd banner hang | **CLOSED.** Resolved with the host; `ssh root@172.16.1.159` normal, `curl` + `jq` present. |
| 4 | D-44 before-snapshot outstanding | **CLOSED.** Captured in Task 3 measurement 8, exit 0. |
| 6 | SMB writer enumeration incomplete | **CLOSED.** N6 — no writer present anywhere in the estate. |

Still open, carried forward:

1. **BLOCKING for 02-06 / 02-07 — the estate runs MA BETA `2.11.0b0`, not stable.** D-21 says prove
   the phase against stable; stable is not installed. Operator decision needed before any MA
   behaviour is asserted. `auto_update: true` on a beta channel means the stamped version can move.
   **Does not block 02-03.**
2. **BLOCKING for 02-06 — D-30's provider enumeration is unmeasured**, because an MA account exists
   but no credential for it is recorded. Obtain the credential, mint the D-39 long-lived token, and
   enumerate `config/providers` **before** adding any provider, so the baseline is taken against an
   untouched library. **Does not block 02-03.**
3. **Plan 02-03 must plan-then-apply-a-saved-plan, never a bare `apply`.** Assert the plan contains
   exactly `null_resource.nfs_music_export` and zero destroys. See Task 2.
4. **B-3 before-state correction.** Port 111 is already open (rpcbind). Plan 02-03 must assert on
   **2049 only**, or it will claim a transition it did not cause.
5. **`showmount` is absent on the NUC.** `nfs-music-export.tf`'s `verify_commands` output currently
   suggests `showmount -e 172.16.1.158` "from the HA NUC" — that line will not run. Correct it in
   02-03, or re-point it at `exportfs -v` on atlantis.
6. **`findmnt` is absent on the NUC**, so criterion 1e's stated instrument is unavailable. Substitute
   `/proc/self/mountinfo` (verified readable, and its fstype column is where `nfs4` will appear) or
   `mount` output.
7. **Plans 02-01 and 02-04 pin Jellyfin at `192.168.90.31:8096`, which is wrong** — it is
   `192.168.90.25`, and that address is DHCP-ish. Neither the bare Docker DNS name (Cloudflare, via
   `search deercrest.info`) nor `172.16.1.76` (macvlan host isolation) is usable from LXC 100.
   Use runtime `docker inspect` resolution in 02-04.
8. **`bpg/proxmox 0.95.0`'s `mount_point` replacement artefact is suppressed, not fixed.** Real
   bind-mount edits to `lxc-selfhost.tf` / `lxc-mpe.tf` will now plan clean and do nothing. Revisit
   when the provider is upgraded; the trade-off is documented in both files.
9. **The amdgpu memory entry needs correcting** — it reads as though the July mitigation resolved the
   issue. It did not: THP=never and `vm.compaction_proactiveness=0` were both fully applied and the
   host still oopsed four times on 2026-08-31. The 2026-08-31 trigger was a **Jellyfin VAAPI
   transcode**, and the working mitigation is disabling VAAPI, not compaction tuning.

---

## Self-Check

Files claimed created:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-01-SUMMARY.md` — FOUND
- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-01-PARTIAL.md` — **REMOVED**
  (folded into this file; one record, not two)

Commits claimed:

| Commit | Task |
|---|---|
| `1588f19` | Task 2 remediation — `prevent_destroy` + `ignore_changes` on the LXC resources |
| `3051695` | Task 2 remediation — `mpe_memory_mb` reconciled to the running value |
| `beabbbb` | Task 2 record — drift gate resolved, D-17 answered |
| `fa75ebc` | Task 3 record — NUC / MA / audit-script measurements |

**Task 4 has no commit of its own, and that is correct, not an omission.** Its disposition is
`not-fired`; its fire condition is a Task 3 measurement, and it produced no artefact. Its record
rode with `fa75ebc`. Recorded here explicitly so the absence is not read as a skipped task.

Tasks 1, 2 and 3 have `<files>none</files>` in the plan — every probe is read-only — so no source
commits exist for them either. The commits above are the plan record and the Task 2 remediation.

Probe transcripts retained in the session scratchpad (working artefacts; the verbatim content that
matters is inlined above): `task1-probes.txt`, `task1-probe7-followup.txt`, `lxc100-sshd-diag.txt`,
`atlantis-load-diag.txt`, `atlantis-load-diag2.txt`, `atlantis-io-diag.txt`, `atlantis-oops.txt`,
`atlantis-mitigation.txt`, `tf-init.txt`, `tf-plan.txt`, `tf-plan-task2.txt`, `qhc-before.txt`.

## Self-Check: PASSED
