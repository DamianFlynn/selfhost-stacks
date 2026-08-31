---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 02
subsystem: infra
tags: [terraform, nfs, exports, knfsd, zfs, systemd, null_resource, cons-01]
requires:
  - phase: 01-safety-harness-and-freeze-the-writers
    provides: "Library ownership normalised to 568:568 (WRIT-04) — the export's anonuid/anongid, and the 0777 mode that forces the export to be ro"
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "Plan 02-01 Stage 0 probes 1-7 — mount point confirmed, single dataset, no competing export table, nfs-kernel-server provenance"
provides:
  - "infra/nfs-music-export.tf — the CONS-01 read-only export of /mnt/tank/media/Music to the HA NUC, defined in Terraform"
  - "Guarded nfs-kernel-server install co-located with the export it serves (D-14)"
  - "M1 (mountpoint export option) and M2 (After=/Wants=zfs-mount.service drop-in) (D-33)"
  - "Two apply-failing security assertions — export line present, no_root_squash absent (gate 1 of D-51's two)"
  - "Flag-gated temporary control export, off by default, teardown-by-apply (D-15)"
  - "ha_nuc_ip / music_temp_export_enabled / music_temp_export_path in infra/variables.tf"
  - "verify_commands extended with the export's inspection surface"
affects:
  - "02-03 — applies this code and proves it; owns every host-touching step deferred here"
  - "02-04 — check-music-consumers.sh, gate 2 of D-51"
  - "02-05 — Stage 4b write-refusal proof against the ro export"
  - "02-07 — temp-export teardown assertions (D-46)"
tech-stack:
  added: []
  patterns:
    - "null_resource with `triggers` keyed on a generated config string — first in infra/; makes an edit to the config re-run the resource instead of being silently inert"
    - "provisioner \"file\" with content = — first in infra/; a whole-file write is idempotent by construction where the repo's `grep -q … || echo … >>` append-guard is not"
    - "count = var.<flag> ? 1 : 0 conditional resource — first in infra/; makes teardown an apply rather than a memory"
    - "/etc/exports.d/ drop-in rather than /etc/exports, so the Terraform-managed surface is exactly one file"
key-files:
  created:
    - "infra/nfs-music-export.tf"
  modified:
    - "infra/variables.tf"
    - "infra/outputs.tf"
key-decisions:
  - "Export line is /mnt/tank/media/Music 172.16.1.31(ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys) — anonuid/anongid interpolated from var.apps_uid/var.apps_gid, never written as literals"
  - "fsid=, crossmnt and no_root_squash are absent, each with the reason recorded in the file so the absence is not read as an oversight"
  - "xprtsec= (RFC 9289) and sec=krb5 recorded in the file header as considered-and-rejected, with sec=sys on a trusted LAN as an accepted residual risk"
  - "The guarded install runs in a remote-exec placed BEFORE the file provisioner, because scp/sftp will not create /etc/exports.d/ and it does not exist on a stock PVE host"
  - "The temporary export's scratch path is created as its own ZFS dataset so the mountpoint option holds uniformly and both exports share one option set"
patterns-established:
  - "Terraform `triggers` on generated config: infra/'s existing null_resources have none and therefore never re-run; this file states why it departs"
  - "Apply-failing assertions inside remote-exec as a security gate, not just an echo"
requirements-completed: []  # CONS-01 is carried, NOT completed — see "Requirements" below
requirements-carried: [CONS-01]
duration: 28min
completed: 2026-08-31
---

# Phase 02 Plan 02: Terraform for the Read-Only Music Export Summary

**The CONS-01 export is now defined in Terraform — a `ro,all_squash` NFSv4 drop-in for
`/mnt/tank/media/Music` restricted to the HA NUC, with the server install, the boot-ordering
drop-in and two apply-failing security assertions in one resource — and nothing has been applied
to any host.**

## Performance

- **Duration:** ~28 min
- **Tasks:** 3 of 3
- **Files modified:** 3 (1 created, 2 modified)
- **Hosts contacted:** **0** — by design, and by the constraint below

## The generated export line

Rendered with the defaults now in `infra/variables.tf`:

```
/mnt/tank/media/Music 172.16.1.31(ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys)
```

No literal `568` appears in `infra/nfs-music-export.tf` — the `568`s above are what
`${var.apps_uid}` / `${var.apps_gid}` evaluate to. That is the point: ROADMAP C-9's inheritance
from Phase 1's WRIT-04 is now visible in the code rather than being a coincidence of two literals
happening to agree.

The temporary control export renders as the same option set against
`/mnt/tank/downloads/_phase2-albumartist-control`, to the same single host.

## Accomplishments

| Task | Delivered | Commit |
|------|-----------|--------|
| 1 | `ha_nuc_ip`, `music_temp_export_enabled` (the first `type = bool` in `infra/`), `music_temp_export_path` | `5e62368` |
| 2 | `infra/nfs-music-export.tf` — header contract, `locals`, the main export resource | `86ffce9` |
| 3 | The flag-gated temporary export + `verify_commands` extension | `4409e6d` |

### What the main resource does, in order

1. Guarded `dpkg -s nfs-kernel-server || apt-get install` and `mkdir -p /etc/exports.d`
2. `provisioner "file"` writes `/etc/exports.d/music.exports`
3. `10-zfs-order.conf` drop-in with `After=zfs-mount.service` / `Wants=zfs-mount.service`, then `daemon-reload`
4. Pre-flight `mountpoint -q /mnt/tank/media/Music || exit 1`
5. `systemctl enable --now nfs-server` (enable, not merely start) then `exportfs -ra`
6. Two assertions that exit 1: the export line for `var.ha_nuc_ip` must be in `exportfs -v`, and `no_root_squash` must not be
7. `echo '--- music export ready ---' && exportfs -v` so the apply log carries its own evidence

## Verification

Both offline instruments pass across the whole directory:

```
$ cd infra && terraform fmt -check -recursive
FMT-CLEAN across infra/

$ terraform validate -no-color
Success! The configuration is valid.
```

Structural assertions (all from the plan's acceptance criteria):

| Check | Result |
|---|---|
| `anonuid=${var.apps_uid}` / `anongid=${var.apps_gid}` present | 1 / 1 |
| `anonuid=568` literal present | 0 |
| `fsid=` on a non-comment line | 0 |
| `crossmnt` on a non-comment line | 0 |
| `no_root_squash` on a non-comment line | **1** — exactly the assertion that fails the apply |
| `destination = "/etc/exports"` | 0 |
| `After=zfs-mount.service` / `Wants=zfs-mount.service` | 1 / 1 |
| `systemctl enable --now nfs-server` | 1 |
| `depends_on = [null_resource.host_setup]` | present |
| `xprtsec` / `krb5` in the header, each marked rejected | 1 / 2 |
| Every `remote-exec` inline entry has a `#` comment above it | audited, no exceptions |
| Secret literal anywhere in the file | none — see below |

### The count gate, proven offline

The plan's acceptance criterion for the `count` gate is `terraform plan -detailed-exitcode` in
`infra/` showing exactly one resource to add. **That requires reaching atlantis and was not run**
(see the boundary section). Rather than assert the gate untested, it was proven in an isolated
throwaway config with no providers, in the session scratchpad:

```
=== default (flag false) ===
  # null_resource.nfs_music_export will be created
Plan: 1 to add, 0 to change, 0 to destroy.

=== flag true ===
  # null_resource.nfs_music_export will be created
  # null_resource.nfs_music_temp_export[0] will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

This proves the expression and the `[0]` indexing, which is the part at risk. It does **not**
substitute for the real plan against real state — that assertion still belongs to 02-03.

## Host boundary — what was deliberately NOT done

atlantis (`172.16.1.158`) remains in the `amdgpu_hmm_invalidate_gfx` incident recorded in
`02-01-PARTIAL.md`, with no reboot since 2026-08-18 09:50. This plan's own objective states it
writes code only. Nothing here contacted a host, and the following are recorded as **belonging to
plan 02-03**, not as gaps:

| Deferred to 02-03 | Why |
|---|---|
| `terraform plan -detailed-exitcode` in `infra/` (one resource to add) | Refreshes state against the Proxmox API; hung 420 s with no exit code during 02-01 |
| D-17's drift gate — still **unproven, not disproven** | Same reason. It gates *applying*, not authoring |
| D-44's before-snapshot (`quick-health-check.sh`) | Anti-pattern 4: a transcript taken mid-incident cannot serve as a blast-radius baseline. Precondition on the apply |
| D-20 — measuring the NUC's actual source address toward `172.16.1.158` | 02-01 Task 3 never ran; A5 is `NOT MEASURED`. `ha_nuc_ip` defaults to NETWORK.md's `172.16.1.31` and the variable description says to confirm it before the first apply |
| Everything the `remote-exec` blocks do | They are provisioners; they run at apply time and only then |

Related, for whoever writes 02-03's assertions: **port 111 is already open** from the pre-existing
`nfs-common`/`rpcbind`. **2049 is this phase's only port delta.** The `verify_commands` comment now
says so in the code.

## Requirements

**CONS-01 was deliberately NOT marked complete in `REQUIREMENTS.md`.**

The requirement reads: *"An NFSv4 export **serves** the Music dataset read-only from the Proxmox
host, defined in Terraform, restricted to the NUC."* This plan satisfies the **"defined in
Terraform"** clause in full. It does not satisfy **"serves"** — nothing has been applied and no
NFS server is running. Six plans in this phase carry `CONS-01` in their frontmatter; **02-03** is
the one that applies and proves it, and that is where the checkbox belongs.

Ticking it here would be exactly the failure this project has already recorded against itself six
times in Phase 1: partial data stated as settled. `REQUIREMENTS.md:70` still reads `- [ ]`, and
`REQUIREMENTS.md:207` still reads `Pending`, on purpose.

## Deviations from Plan

### 1. [Rule 3 — Blocking issue] `mkdir -p /etc/exports.d` added before the `file` provisioner

- **Found during:** Task 2
- **Issue:** The plan specifies `provisioner "file"` → `provisioner "remote-exec"` in that order,
  with the guarded install as inline step 1 of the remote-exec. But `provisioner "file"` uses
  scp/sftp, which **will not create a missing parent directory** — and 02-01 probe 4 measured that
  `/etc/exports.d/` **does not exist** on atlantis (`ls: cannot access '/etc/exports.d/': No such
  file or directory`, exit 2). The first apply would have failed at the file write, before the
  remote-exec that would have created the directory ever ran.
- **Fix:** The resource now has three provisioners: a short `remote-exec` carrying the guarded
  install and `mkdir -p /etc/exports.d`, then the `file` provisioner, then the main `remote-exec`.
- **What this does not change:** D-14 is still satisfied — the guarded install lives in the *same
  resource* that writes the export, which is what D-14 asks for. Nothing was added to a different
  resource and nothing was hand-run.
- **Files modified:** `infra/nfs-music-export.tf`
- **Commit:** `86ffce9`

### 2. [Verification-command correction] The plan's `grep -q 'anonuid=${var.apps_uid}'` fails spuriously on this workstation

- **Found during:** Task 2 verification
- **Issue:** `grep` on this machine is **ugrep 7.8.4**, not BSD or GNU grep. It parses `{…}` in a
  basic regular expression as an interval expression, so `grep -q 'anonuid=${var.apps_uid}'`
  returns **no match against a file that plainly contains that exact string** on line 74. The
  plan's automated verify block for Task 2 therefore fails for a reason that has nothing to do with
  the code.
- **Fix:** Verified with `grep -F` (literal). No code changed. Recorded here rather than silently
  worked around, because 02-03 and 02-04 will hit the same trap: **use `grep -F` for any pattern
  containing `${…}` on this workstation.**
- **Files modified:** none

### 3. [Verification-command correction] The plan's secret-scan grep would fail on the mandated connection block

- **Found during:** Task 2 verification
- **Issue:** The plan's `<verification>` includes
  `git grep -nE '(password|token|secret) *=' -- infra/nfs-music-export.tf` returning nothing. But
  the same plan mandates a four-key `connection` block using `var.proxmox_ssh_password` — so the
  file necessarily contains `password = var.proxmox_ssh_password`, exactly as `host.tf:17` and
  `lxc-mpe.tf:58` do. The check as written is over-broad and would fail on correct code.
- **Fix:** Asserted the substantive property instead, which is what T-02-11 actually cares about:
  the only match in the file is that one variable *reference*; no secret value appears; and no
  `sensitive` variable is referenced by any `local` or any `triggers` entry. `triggers` carries
  only `local.music_export_file` (a path, an IP, two uids) and a revision string, so nothing
  sensitive can reach the committed public `terraform.tfstate`.
- **Files modified:** none

### 4. [Scope boundary] Task 3's `terraform plan` acceptance criterion was not run

Recorded above under **Host boundary**. Substituted with an isolated offline proof of the `count`
expression, and the real assertion is carried into 02-03.

## Threat Register Status

| Threat ID | Disposition | Status after this plan |
|-----------|-------------|------------------------|
| T-02-01 | mitigate | **Built.** Single-host spec from `var.ha_nuc_ip`; no netmask, no wildcard anywhere in the file |
| T-02-02 | mitigate | **Built.** `all_squash` maps every uid including 0 to `anonuid`/`anongid` |
| T-02-03 | mitigate | **Built (server side).** `ro` in the option list. Proof of write refusal is 02-05's Stage 4b |
| T-02-06 | mitigate | **Gate 1 built.** `exportfs -v \| grep -q 'no_root_squash' && exit 1`. Gate 2 is 02-04 |
| T-02-07 | mitigate | **Built.** Line generated from a single-value variable; apply asserts that exact string is in `exportfs -v` |
| T-02-08 | mitigate | **Built.** Tailnet address absent; the reason is in the `ha_nuc_ip` description in code |
| T-02-04 | accept | **Recorded.** `xprtsec=` and `krb5` rejections plus the accepted residual risk are in the file header |
| T-02-11 | mitigate | **Verified.** No secret in any local or trigger; the sole `password` hit is the mandated `var.proxmox_ssh_password` reference |
| T-02-12 | mitigate | **Built.** Same `ro,all_squash` set, same single host, scratch path under `tank/downloads`, `count`-gated off by default |
| T-02-SC | mitigate | **Inherited from 02-01.** `nfs-kernel-server 1:2.8.3-1`, sole candidate origin `deb.debian.org/debian trixie/main`. No npm/PyPI/crates package added |

## Threat Flags

None. This plan adds no new network surface at authoring time — the surface appears when 02-03
applies, and it is exactly the one already in the register (2049/tcp; 111 was already open).

## Known Stubs

None. Every resource in the file is complete and would execute as written. The one thing it does
not do is run — which is the plan's stated design, not a stub.

## Self-Check

Files claimed created/modified:

- `infra/nfs-music-export.tf` — FOUND
- `infra/variables.tf` — FOUND (modified)
- `infra/outputs.tf` — FOUND (modified)
- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-02-SUMMARY.md` — FOUND

Commits:

- `5e62368` — FOUND
- `86ffce9` — FOUND
- `4409e6d` — FOUND

Working tree carries no unintended changes; the pre-existing untracked `body.txt` at repo root was
left alone, and `infra/terraform.tfvars` remains uncommitted.

## Self-Check: PASSED
