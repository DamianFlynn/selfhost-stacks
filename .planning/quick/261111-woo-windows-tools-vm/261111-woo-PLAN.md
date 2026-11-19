---
phase: quick-261111-woo
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - infra/vm-wintools.tf
  - scripts/wintools-unattend.sh
  - scripts/wintools-autounattend.xml.tmpl
  - DEPLOYMENT.md
  - NETWORK.md
  - .planning/quick/261111-woo-windows-tools-vm/261111-woo-SUMMARY.md
autonomous: false
requirements: [QUICK-261111-woo]
user_setup:
  - service: microsoft-windows-iso
    why: "Microsoft bot-checks scripted ISO downloads (Mido/Fido flow returned no link on 2026-11-11)"
    dashboard_config:
      - task: "Generate the 24 h Windows 11 x64 English ISO link and paste it, or download in a browser and name the Mac path; paste Microsoft's published sha256"
        location: "https://www.microsoft.com/software-download/windows11"
  - service: c-bus-toolkit-and-elkrp2
    why: "se.com returns 403 to scripts; ElkRP2 is behind an elkproducts.com login"
    dashboard_config:
      - task: "Download C-Bus Toolkit 1.19.6 and ElkRP2 2.0.41 installers in a browser; name their ~/Downloads paths"
        location: "se.com C-Bus Software & Updates page; elkproducts.com/elkdoc/elkrp2-remote-programming-software/"

must_haves:
  truths:
    - "VM 103 'wintools' exists on atlantis, created by a targeted Terraform apply whose plan read exactly 'Plan: 1 to add, 0 to change, 0 to destroy.', and `terraform state list` before/after differs only by the added wintools address"
    - "The guest runs Windows 11 Pro (qemu-ga get-osinfo) with Secure Boot on and a vTPM 2.0 present, and BitLocker off"
    - "qm agent 103 ping succeeds while the VM is running, and the FirstLogonCommands sentinel C:\\ProgramData\\wintools\\firstlogon.done exists before any hardening step runs"
    - "TCP 3389 on the guest is reachable from LXC 100 and from the workstation, with NLA required"
    - "VictronConnect and VEConfigure are installed (uninstall registry entries present); C-Bus Toolkit and ElkRP2 are installed or recorded PENDING-OPERATOR with exact instructions"
    - "The rendered autounattend.xml and wintools-unattend.iso no longer exist on atlantis; the guest's Panther (incl. UnattendGC) answer-file copies are gone; reg query shows Winlogon DefaultPassword absent and AutoAdminLogon=0; the install-time admin password has been rotated so any surviving copy (LSA secret, CoW blocks) is a dead credential; neither password appears in the repo or in infra/terraform.tfstate*"
    - "Every failure exit (every STOP branch, and any halt while VM 103 may be running) runs `wintools-unattend.sh failexit`, which cleans up the unattend artefacts and leaves `qm status 103` = stopped, with that status recorded as evidence"
    - "After provisioning, qm status 103 = stopped, onboot is not set, a final targeted re-plan reads No changes, and atlantis MemAvailable is back to within 512 MiB of the pre-start reading"
  artifacts:
    - path: "infra/vm-wintools.tf"
      provides: "proxmox_virtual_environment_vm.wintools — VM shell only, no credentials"
      contains: "resource \"proxmox_virtual_environment_vm\" \"wintools\""
    - path: "scripts/wintools-unattend.sh"
      provides: "Runs ON atlantis: build (render answer file from stdin password, genisoimage, qm set ide0/sata0, start + sendkey), cleanup (eject, shred/delete ISO + rendered XML, delete ide0/sata0) and failexit (cleanup, then shutdown with stop fallback, then assert stopped) subcommands"
      contains: "failexit"
    - path: "scripts/wintools-autounattend.xml.tmpl"
      provides: "Win11 Pro answer-file template with @@ADMIN_PASSWORD@@ placeholder, LogonCount 1 autologon, a final firstlogon.done sentinel command, and no secret"
      contains: "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
    - path: "DEPLOYMENT.md"
      provides: "VM 103 wintools section: lifecycle, Terraform discipline, password location, rebuild, failure exit and rollback"
      contains: "wintools"
    - path: "NETWORK.md"
      provides: "VM 103 entry under atlantis, Termix SSH/RDP hosts, ELK one-connection caveat, Remote VEConfigure workflow"
      contains: "VM 103"
  key_links:
    - from: "infra/vm-wintools.tf"
      to: "local:iso/Win11_x64_en-us.iso"
      via: "cdrom block on ide2 (the provider's single cdrom slot)"
      pattern: "Win11_x64_en-us.iso"
    - from: "scripts/wintools-unattend.sh"
      to: "~/.claude/secrets/winvm.env"
      via: "password arrives on stdin only (printf builtin | ssh), substituted with bash parameter expansion — never argv, never Terraform"
      pattern: "read -r"
    - from: "scripts/wintools-unattend.sh"
      to: "qm set 103 --ide0 / --sata0"
      via: "virtio-win + unattend ISOs attached outside Terraform; covered by lifecycle ignore_changes"
      pattern: "qm set"
    - from: "every STOP branch in Tasks 2a/2b/2c (and build's EXIT trap)"
      to: "wintools-unattend.sh failexit"
      via: "cleanup, then qm shutdown --timeout 120 falling back to qm stop, then assert qm status 103 = stopped"
      pattern: "failexit"
---

<objective>
Provision a Windows 11 Pro "tools" VM (VMID 103, `wintools`) on atlantis for C-Bus Toolkit, ElkRP2,
VictronConnect and VEConfigure. It stays powered off by default and is reached by RDP through
Termix. Terraform defines only the VM shell. The answer file, which carries the admin password, is
rendered and destroyed on atlantis by a repo script that takes the password on stdin.

Purpose: the operator gets a Windows box for vendor config tools without a permanent RAM cost on a
host that has about 6 GiB available and a record of memory-exhaustion freezes, and without a
credential reaching tfstate or git. This repo is public, and tfstate has leaked credentials before.
Because a running 4 GiB guest is itself the hazard, every failure path ends with VM 103 stopped.

Output: `infra/vm-wintools.tf`, `scripts/wintools-unattend.sh`,
`scripts/wintools-autounattend.xml.tmpl`, DEPLOYMENT.md and NETWORK.md entries, and a SUMMARY that
marks every proof PROVEN, NOT PROVEN or PENDING-OPERATOR.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/quick/261111-woo-windows-tools-vm/261111-woo-RESEARCH.md
@./CLAUDE.md
@./CONVENTIONS.md
@infra/providers.tf
@infra/lxc-mpe.tf
@infra/.gitignore

Facts the planner measured (2026-11-11). Use them instead of re-deriving.
- Terraform runs from `infra/` on the workstation. State is LOCAL (`infra/terraform.tfstate`), and the
  credentials come from `infra/terraform.tfvars`. Both are git-ignored by `infra/.gitignore`, which
  also ignores `terraform.tfstate.*` and `*.tfplan`. `proxmox_node` in tfvars is `atlantis`, while the
  variable default is `pve`, so always use `var.proxmox_node` and never a literal. The provider is
  bpg/proxmox `~> 0.95` with the lock at 0.95.0. Do not run `terraform init -upgrade`.
- `var.cerebro_vmid = 101` is reserved. 102 is LXC `mpe`. Nothing in `infra/*.tf` references 103.
- `infra/lxc-mpe.tf` is the style reference: `started = false`, `var.proxmox_node`, and banner comments.
- Research §3 gives the resource sketch and §2 the answer-file XML (which already sets AutoLogon
  `LogonCount` 1). Both are adopted with the overrides listed below.
- Windows OpenSSH admins authenticate with `C:\ProgramData\ssh\administrators_authorized_keys`, not
  the per-user file. Several keys sit in the workstation's `~/.ssh`. Use the one that
  `ssh -G root@172.16.1.158` resolves, and never the `sk-` key, because it needs a touch.

Overrides of the research, all from the orchestrator and all binding:
- NO password in Terraform. No sensitive var, no `templatefile`, no file provisioner, no
  `null_resource`. Terraform creates exactly one resource.
- The extra CD-ROMs (virtio-win on `ide0`, unattend on `sata0`) come from `qm set` inside the script.
  This replaces the research's `null_resource`.
- virtio-win is fetched with `curl` on atlantis, not with `proxmox_virtual_environment_download_file`,
  so that the plan stays at 1 to add.
- OpenSSH Server and its authorized keys are set up via `qm guest exec` / `qm guest file-write` after
  the agent is up, not in FirstLogonCommands, so that a failure shows instead of passing silently.

## Failure exit (FX) — invoked by EVERY STOP branch from Task 2a onwards

Any STOP in Tasks 2a, 2b or 2c — and any unplanned error or executor halt while VM 103 may be
running — runs FX before reporting. FX is the `failexit` subcommand of `scripts/wintools-unattend.sh`
(written in Task 1), invoked as `ssh root@172.16.1.158 'timeout 400 bash /root/wintools-build/wintools-unattend.sh failexit'`,
with the ssh RC read. It is idempotent and does, in order:
1. Run `cleanup` (unattend ISO + every rendered XML). A cleanup failure is recorded but does NOT
   prevent steps 2–3; the RAM hazard outranks the tidy-up.
2. If `qm status 103` is `running`: `timeout 180 qm shutdown 103 --timeout 120`; if that fails or
   times out, `timeout 60 qm stop 103` and print `FAILEXIT_FORCED_STOP=1`.
3. Once stopped, `qm set 103 --delete ide0,sata0` if either is present (ignore "not present").
4. Assert `qm status 103` prints exactly `status: stopped`; print `FAILEXIT_STATUS=stopped` and the
   current MemAvailable on a `FAILEXIT_MEMAVAILABLE_KB=` line. Exit non-zero if the VM is not stopped
   or if cleanup failed.
Diagnostic evidence (e.g. `stuck.ppm`) is captured BEFORE FX and is not deleted by FX. The executor
records the FX output (status line, forced-stop flag, MemAvailable) in the SUMMARY as the evidence
for the failure-exit must-have. If FX itself cannot reach `stopped`, report that as the top line of
the STOP report: the operator must act on atlantis immediately.

## Rollback (documented and available — NOT executed by default)

Run only on an explicit operator decision. Both routes start by copying `infra/terraform.tfstate`
and `infra/terraform.tfstate.backup` to the scratchpad.
- Route R1 (preferred, Terraform): `terraform plan -destroy -target=proxmox_virtual_environment_vm.wintools -no-color -out=<scratchpad>/wintools-destroy.tfplan`.
  The output must contain exactly `Plan: 0 to add, 0 to change, 1 to destroy.` (`/usr/bin/grep -F`),
  and the only resource address shown must be `proxmox_virtual_environment_vm.wintools`. Anything
  else (LXC 100 above all) means STOP. Then `terraform apply <scratchpad>/wintools-destroy.tfplan`
  and delete the plan file. Never a bare `terraform destroy`.
- Route R2 (alternative, Proxmox-side): FX first, then `qm destroy 103 --purge --destroy-unreferenced-disks 1`,
  then `terraform state rm proxmox_virtual_environment_vm.wintools` so state does not go stale; prove
  with `terraform state list` that only that address disappeared.
- After either route: `pvesm list local-lvm | grep -E 'vm-103-'` must be empty. Any surviving
  efidisk/tpmstate volume is removed with `pvesm free <volid>`, each volid passing an inline fence
  `^local-lvm:vm-103-disk-[0-9]+$` (CONVENTIONS rule 6). Remove the ISOs: run `cleanup` (unattend
  ISO) if the script is still on atlantis, and `rm` exactly `/var/lib/vz/template/iso/virtio-win-0.1.302.iso`
  (exact-path fence). The Win11 ISO is removed only if the operator says so.
</context>

<tasks>

<task type="checkpoint:human-action" gate="blocking">
  <name>Task 0: Operator puts the Windows 11 ISO on atlantis, supplies Microsoft's sha256, and names the C-Bus/ELK installer paths</name>
  <files>/var/lib/vz/template/iso/Win11_x64_en-us.iso (on atlantis; not a repo file)</files>
  <what-needed>
    1. The Windows 11 x64 English ISO at exactly `/var/lib/vz/template/iso/Win11_x64_en-us.iso` on atlantis
       (172.16.1.158). Microsoft bot-checks scripted downloads, so a human must generate the link.
    2. The sha256 Microsoft publishes for that ISO on the same download page.
    3. Optional now and required for full completion: the Mac paths of the C-Bus Toolkit 1.19.6
       installer and the ElkRP2 2.0.41 installer.
    4. Optional: the C-Bus PC interface type (CNI/Wiser on the LAN, or USB). USB conflicts with the
       locked no-USB decision, so it is recorded as an open issue rather than solved.
  </what-needed>
  <action>
    Route A, preferred. Open https://www.microsoft.com/software-download/windows11 on the Mac, choose
    "Download Windows 11 Disk Image (ISO) for x64 devices", then English, and copy the 64-bit link
    (valid 24 h). Paste it into the chat. The executor then runs, Linux-side and bounded:
    `ssh root@172.16.1.158 'timeout 3600 curl -fL --retry 3 -o /var/lib/vz/template/iso/Win11_x64_en-us.iso "<link>"'`.
    The link is a signed URL, not a credential, so argv is acceptable here.
    Route B, the fallback if the link is IP-bound and fails from atlantis (research A1). Download in
    the browser and name the Mac path. The executor runs `scp <path> root@172.16.1.158:/var/lib/vz/template/iso/Win11_x64_en-us.iso`.
    Hash check, machine-enforced and fail closed (both routes): the executor writes the
    operator-pasted Microsoft hash to `<scratchpad>/win11.sha256.expected`, then computes
    `a` = the first field of `ssh root@172.16.1.158 'timeout 600 sha256sum /var/lib/vz/template/iso/Win11_x64_en-us.iso'`
    (ssh RC read; non-zero or empty `a` = STOP, "could not look") and `b` = the expected file
    lower-cased with `tr 'A-F' 'a-f'` and stripped of whitespace. It then requires
    `[ -n "$a" ] && [ "$a" = "$b" ]`. Any other result means STOP: do not proceed to Task 1, and
    delete nothing. Eyeballing the hashes is not acceptable. Record both values and the route in the SUMMARY.
    For the C-Bus/ELK installers, the operator replies with paths such as
    `~/Downloads/C-Bus_Toolkit_V1_19_6.exe` and `~/Downloads/ElkRP2_Setup.exe`, or "not yet".
  </action>
  <resume-signal>Paste the ISO link (or the Mac path) and the Microsoft sha256, and name the two installer paths or say "not yet"</resume-signal>
  <verify>
    <automated>set -o pipefail; a=$(ssh root@172.16.1.158 'timeout 600 sha256sum /var/lib/vz/template/iso/Win11_x64_en-us.iso' | cut -d' ' -f1) && b=$(tr 'A-F' 'a-f' < /private/tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/2dd23e3d-dac4-409d-9a75-1b031091b6c7/scratchpad/win11.sha256.expected | tr -d '[:space:]') && [ -n "$a" ] && [ "$a" = "$b" ] && echo SHA256_MATCH && ssh root@172.16.1.158 'timeout 30 pvesm list local --content iso' | /usr/bin/grep -F Win11_x64_en-us.iso</automated>
  </verify>
  <done>The ISO is present in `local:iso`; the `[ "$a" = "$b" ]` comparison against Microsoft's published sha256 passed (both values recorded); the installer paths are recorded, or "not yet" is recorded as PENDING-OPERATOR</done>
</task>

<task type="auto">
  <name>Task 1: Write the Terraform VM shell, the atlantis-side unattend script (build/cleanup/failexit) and the answer-file template, then create VM 103 with a targeted plan that must read 1 add / 0 change / 0 destroy</name>
  <files>infra/vm-wintools.tf, scripts/wintools-unattend.sh, scripts/wintools-autounattend.xml.tmpl</files>
  <action>
**Preflight (fail closed).** Read-only ssh to atlantis, bounded Linux-side with `timeout 30`.
1. Prove VMID 103 is free: `qm status 103` must error, `/etc/pve/qemu-server/103.conf` and `/etc/pve/lxc/103.conf` must be absent, and `pvesh get /cluster/resources --type vm` must not list 103. If 103 is taken, STOP.
2. Prove `pc-q35-11.1` appears in `kvm -machine help`.
3. Prove `local-lvm` has at least 70 GB free (`pvesm status`).
4. Record whether any vzdump job in `pvesh get /cluster/backup` has `all` set. Note it in the SUMMARY; change nothing.
5. Record `findmnt -T /var/lib/vz/template/iso` (filesystem type), which is needed for the shred caveat in Task 2c.

**infra/vm-wintools.tf.** Write one resource, `proxmox_virtual_environment_vm.wintools`, following research §3 and the locked decisions:
- `node_name = var.proxmox_node`, `vm_id = 103`, `name = "wintools"`, a short `description`.
- `started = false`, `on_boot = false`, `stop_on_destroy = true`.
- `machine = "pc-q35-11.1"` (explicit, per research §3 "machine drift"), `bios = "ovmf"`, `scsi_hardware = "virtio-scsi-single"`, `operating_system { type = "win11" }`, `agent { enabled = true }`.
- `cpu { cores = 2, type = "x86-64-v3" }` and `memory { dedicated = 4096, floating = 4096 }`.
- `efi_disk` on local-lvm with `type = "4m"` and `pre_enrolled_keys = true`.
- `tpm_state` on local-lvm with `version = "v2.0"`.
- A single `disk`: scsi0, 64 GB on local-lvm, raw, `iothread = true`, `discard = "on"`, `ssd = true`.
- `network_device { bridge = "vmbr0", model = "virtio" }`. DHCP comes from UniFi, with no cloud-init and no `initialization` block.
- A single `cdrom { file_id = "local:iso/Win11_x64_en-us.iso", interface = "ide2" }`.
- `boot_order = ["scsi0", "ide2"]`.
- `lifecycle { ignore_changes = [cdrom, started] }`.

Header comments must say:
(a) Terraform holds NO credential for this VM. The admin password lives only in `~/.claude/secrets/winvm.env` and reaches atlantis only on stdin to `scripts/wintools-unattend.sh`, because tfstate is local, this repo is public, and tfstate has leaked credentials before.
(b) bpg 0.95.0 allows only one `cdrom` block (MaxItems 1, PR #2748 unmerged). virtio-win on ide0 and the unattend ISO on sata0 are therefore attached by `qm set` in the script. `ignore_changes = [cdrom]` covers ejecting ide2 afterwards, and `started` covers the operator's `qm start`/`qm shutdown`.
(c) The machine version is pinned deliberately. Upgrading it re-enumerates the NIC and can flip the network profile to Public, which closes RDP.
(d) Only ever plan and apply this resource with `-target`. Rollback is a saved targeted destroy plan that must read 0/0/1 (see DEPLOYMENT.md).

Do not add variables, outputs, `null_resource` or `download_file`.

**scripts/wintools-autounattend.xml.tmpl.** Use research §2's XML with these changes:
- The `UserAccounts` and `AutoLogon` password values are the literal token `@@ADMIN_PASSWORD@@`.
- Keep AutoLogon `<LogonCount>1</LogonCount>` (per W8: one autologon only, so Windows decrements and disables it after FirstLogonCommands).
- DriverPaths: keys 1–12 cover `vioscsi`, `NetKVM` and `Balloon` `\w11\amd64` on D:, E:, F: and G:. All keys must be unique.
- Keep FirstLogonCommands Orders 1–4: guest tools, Private profile plus the RDP firewall group, power settings with no password expiry, and NetFx3 from `sources\sxs`. Drop research Order 5 (OpenSSH), which moves to Task 2b.
- Add a NEW final Order 5 sentinel (per W5): `cmd /c mkdir C:\ProgramData\wintools 2>nul &amp; echo done> C:\ProgramData\wintools\firstlogon.done`. It must be the highest Order so it runs only after Orders 1–4 have returned. (Agent ping only proves Order 1 ran; the sentinel proves the whole list finished.)
- Keep RDP with `UserAuthentication=1` (NLA) and BypassNRO in `specialize`.
- Key `VK7JG-NPHTM-C97JM-9MPGT-3V66T` with `/IMAGE/NAME` `Windows 11 Pro`.
- ComputerName `WINTOOLS`, TimeZone `GMT Standard Time`, user `tools` in Administrators.

The file holds no secret.

**scripts/wintools-unattend.sh.** Bash with `set -euo pipefail`. It runs ON atlantis as root and lives at `/root/wintools-build/` (mode 700). It takes three subcommands: `build`, `cleanup`, `failexit`.

`build`:
1. Read the password with `IFS= read -r PW` from stdin. Read the following stdin lines as the `administrators_authorized_keys` content, up to EOF, and save them to `/root/wintools-build/authorized_keys` for Task 2b (they are public).
2. Refuse unless PW matches `^[A-Za-z0-9]{20,}$` and contains an upper-case letter, a lower-case letter and a digit. This avoids XML escaping and satisfies Windows complexity rules.
3. Refuse if `qm status 103` is not `stopped`.
4. With `umask 077`, `mktemp -d /root/wintools-build/render.XXXXXX`. Immediately install `trap on_build_exit EXIT`, where `on_build_exit` captures `$?` and, if it is non-zero, runs the `failexit` function (cleanup, then stop the VM if it is running, then assert stopped) before exiting with the original code. This covers both a failure before `qm start` (rendered XML/ISO left behind) and one after it (VM left running). Load the template into a variable and substitute with bash `${tmpl//@@ADMIN_PASSWORD@@/$PW}`. Write it with the `printf` builtin to `autounattend.xml` in that dir. Never `sed` or `envsubst` with the password, because it would sit in argv (CONVENTIONS rule 7).
5. Assert the rendered file has zero remaining `@@` tokens. Assert `xmllint --noout` passes if xmllint exists; otherwise assert that a `python3 -I -c` parse passes, reading the file path only.
6. Fetch virtio-win if absent: pinned archive URL `https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.302-1/virtio-win.iso` to `/var/lib/vz/template/iso/virtio-win-0.1.302.iso` with `timeout 1800 curl -fL`. Print its sha256. Prove the driver layout with `isoinfo -J -l -i <iso>` (fall back to `isoinfo -R -l` if `-J` lists nothing), matching case-insensitively (`grep -i`) on the directory headers for `vioscsi/w11/amd64` and `netkvm/w11/amd64` and on the file name `virtio-win-guest-tools.exe` (per W7: ISO9660 names are upper-cased, so a case-sensitive match on a plain `-l` listing would refuse a good ISO). If any is missing, refuse (research A2).
7. Build `/var/lib/vz/template/iso/wintools-unattend.iso` with `genisoimage -quiet -J -joliet-long -r -V WINTOOLS_UNATTEND`, then `chmod 600`.
8. `qm set 103 --ide0 local:iso/virtio-win-0.1.302.iso,media=cdrom --sata0 local:iso/wintools-unattend.iso,media=cdrom`.
9. Capture MemAvailable once into a variable, `PRESTART_KB=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)` (per W4). Refuse to start if `PRESTART_KB` is below 5 GiB (5242880 kB), exiting with a distinct code (fail closed; the EXIT trap cleans up).
10. `qm start 103`, then 20 × (`sleep 1`; `qm sendkey 103 ret`) for the "press any key" prompt (research A3).
11. Print exactly that captured variable on a `PRESTART_MEMAVAILABLE_KB=${PRESTART_KB}` line — not a fresh read after the VM has started.

`cleanup`:
1. If the VM is running, eject with `qm set 103 --sata0 none,media=cdrom --ide0 none,media=cdrom`. If stopped, use `qm set 103 --delete ide0,sata0`. Tolerate "not present".
2. `shred -u` the unattend ISO and every `/root/wintools-build/render.*/autounattend.xml`, then `rm -rf` the `render.*` dirs.
3. Every destructive target passes a literal-path fence before it runs. Exact-match the ISO path; the render dirs must match `^/root/wintools-build/render\.[A-Za-z0-9]{6}$`. The fence is stated inline at each call site (CONVENTIONS rule 6), with a distinct REFUSED wording per site.
4. Print a warning that `shred` is best-effort on copy-on-write filesystems.
5. Finally assert: the ISO is absent, `pvesm list local --content iso` lacks `wintools-unattend`, and `find /root /tmp /var/lib/vz \( -name 'autounattend.xml*' -o -name 'wintools-unattend.iso' \)` is empty. Exit non-zero otherwise.

`failexit` (the FX procedure in `<context>`, per BLOCKER 1): run `cleanup` in a subshell and record its RC without letting `set -e` abort; if `qm status 103` is running, `timeout 180 qm shutdown 103 --timeout 120`, falling back to `timeout 60 qm stop 103` and printing `FAILEXIT_FORCED_STOP=1`; once stopped, `qm set 103 --delete ide0,sata0` if present; then assert `qm status 103` is exactly `status: stopped`, print `FAILEXIT_STATUS=stopped` and `FAILEXIT_MEMAVAILABLE_KB=<value>`, and exit non-zero if the VM is not stopped or cleanup failed. It must be safe to run when the VM is already stopped and nothing has been rendered.

Never echo PW and never `set -x`.

**Create the VM.** Wait for Task 0. In `infra/` run `terraform validate`, then `terraform plan -target=proxmox_virtual_environment_vm.wintools -no-color -out=<scratchpad>/wintools.tfplan`, with the plan file under `/private/tmp/claude-501/-Users-damian-Development-damianflynn-selfhost-stacks/2dd23e3d-dac4-409d-9a75-1b031091b6c7/scratchpad/` and never in the repo. The output must contain exactly `Plan: 1 to add, 0 to change, 0 to destroy.` (check with `/usr/bin/grep -F`), and the only resource address shown must be `proxmox_virtual_environment_vm.wintools`. Anything else means STOP and report; do not apply. Never run a bare plan or apply.

State safety (per W3), before apply: copy `infra/terraform.tfstate` and `infra/terraform.tfstate.backup` (if present) to `<scratchpad>/tfstate-pre-wintools/` and save `terraform state list` to `<scratchpad>/state-list.before`. These copies stay out of the repo and are the Rollback starting point.

Then `terraform apply <scratchpad>/wintools.tfplan`, so the apply is exactly the reviewed plan, and delete the plan file. Save `terraform state list` to `<scratchpad>/state-list.after` and require that `diff state-list.before state-list.after` shows exactly one added line, `> proxmox_virtual_environment_vm.wintools`, and no removed or changed line. Anything else means STOP and report (do not attempt repair; the pre-apply state copy is the evidence).

Re-run the same targeted plan. It must say `No changes`. If it shows a diff on `efi_disk` (research A7), add `efi_disk` to `ignore_changes`, note why in a comment, and re-prove `No changes`.

Confirm on atlantis that `qm config 103` shows machine `pc-q35-11.1`, efidisk0 with `pre-enrolled-keys=1`, tpmstate0 `version=v2.0`, scsi0 64G, net0 virtio on vmbr0, no `onboot: 1`, and `qm status 103` = stopped.

Exercise FX once on the idle VM: `scp` the script to `/root/wintools-build/` (after `mkdir -m 700`) and run `failexit`. With nothing rendered and the VM stopped it must exit 0 and print `FAILEXIT_STATUS=stopped`. Record the output; this proves the stopped-branch and cleanup assertions before any real failure depends on them.
  </action>
  <verify>
    <automated>cd infra && terraform validate && bash -n ../scripts/wintools-unattend.sh && ! /usr/bin/grep -nE 'password|templatefile|null_resource|download_file' vm-wintools.tf | /usr/bin/grep -v '^[0-9]*:[[:space:]]*#' && /usr/bin/grep -c '@@ADMIN_PASSWORD@@' ../scripts/wintools-autounattend.xml.tmpl && /usr/bin/grep -F -c 'firstlogon.done' ../scripts/wintools-autounattend.xml.tmpl && /usr/bin/grep -F -c '<LogonCount>1</LogonCount>' ../scripts/wintools-autounattend.xml.tmpl && /usr/bin/grep -v '^[[:space:]]*#' ../scripts/wintools-unattend.sh | /usr/bin/grep -c -E 'failexit|isoinfo -J|PRESTART_KB' && ssh root@172.16.1.158 'timeout 30 qm config 103 | grep -E "^(machine|efidisk0|tpmstate0|scsi0|net0|ide2):" ; timeout 10 qm status 103'</automated>
  </verify>
  <done>VM 103 exists from a reviewed targeted plan that read 1/0/0 (plan text excerpt in the SUMMARY). The state-list diff shows only the wintools address added, and pre-apply state copies sit in the scratchpad. A re-plan reads No changes. The VM is stopped with onboot unset. `failexit` ran once on the idle VM and printed `FAILEXIT_STATUS=stopped`. The three repo files exist, and none of them holds a credential.</done>
</task>

<task type="auto">
  <name>Task 2a: Generate the password, build and start the unattended install, wait for the agent and the FirstLogon sentinel, prove the edition, and clean up the unattend artefacts</name>
  <files>.planning/quick/261111-woo-windows-tools-vm/261111-woo-SUMMARY.md</files>
  <action>
Every STOP in this task runs FX (see `<context>`) first and records its output. That includes any unplanned error after `build` has been invoked.

**Password.** If `~/.claude/secrets/winvm.env` is absent, create it with `umask 077`. Generate the value in a pipe (`LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24`), so it never appears in argv or the transcript, and regenerate until it holds an upper-case letter, a lower-case letter and a digit. The file holds `WINVM_ADMIN_USER=tools` and `WINVM_ADMIN_PASSWORD=...`, plus `WINVM_IP=` filled in later. `chmod 600`. Never print it. If the file already exists, reuse it.

**Build.** `scp` the template to `root@172.16.1.158:/root/wintools-build/` (the script is already there from Task 1; re-copy it if it changed). Then pipe the password and keys over ssh to `bash /root/wintools-build/wintools-unattend.sh build`. The stdin is a subshell that sources winvm.env and uses the `printf` builtin to print the password line, followed by `cat` of the public key that `ssh -G` resolves for atlantis plus atlantis's own `/root/.ssh/id_ed25519.pub` content (fetched beforehand; public). Capture `PRESTART_MEMAVAILABLE_KB` and keep it in the scratchpad for Task 2c. If `build` exits non-zero, its EXIT trap has already run `failexit`; run FX once more (idempotent) to capture evidence, then STOP. The distinct low-memory exit code is reported as "refused: MemAvailable below 5 GiB".

**Wait for the install.** Run the poll on atlantis inside `timeout 5400`: `qm agent 103 ping` every 30 s until it succeeds, which means guest tools from FirstLogon Order 1 are in. On timeout: take `qm monitor 103` `screendump /root/wintools-build/stuck.ppm` for diagnosis, then FX, record NOT PROVEN, and STOP. FX does not delete `stuck.ppm`.

**Wait for the sentinel (per W5).** Agent ping does not mean FirstLogonCommands finished. Poll on atlantis inside `timeout 1800`, every 30 s: `qm guest exec 103 --timeout 30 -- cmd /c type C:\ProgramData\wintools\firstlogon.done`, and treat a returned JSON `exitcode` of 0 as done. Nothing in Task 2b may start before this succeeds. On timeout: screendump to `/root/wintools-build/stuck-sentinel.ppm`, FX, record NOT PROVEN, STOP.

**Prove the edition and find the IP.** Record `qm guest cmd 103 get-osinfo`; its pretty-name must contain `Windows 11 Pro`, otherwise FX and STOP. Record `qm guest cmd 103 network-get-interfaces` and take the IPv4 on 172.16.1.0/24 as WINVM_IP, which goes into winvm.env. No such address means FX and STOP.

**Clean up the unattend artefacts now.** Run `cleanup` while the VM is running; it ejects ide0 and sata0. Record its assertions. If any assertion fails, FX and STOP.

Write the SUMMARY skeleton now with the proof-table rows filled so far (ISO sha256, plan 1/0/0, state-list diff, re-plan No changes, FX idle run, edition, agent ping, sentinel, unattend ISO/XML gone), so a later STOP still leaves evidence.
  </action>
  <verify>
    <automated>ssh root@172.16.1.158 'timeout 20 qm status 103; timeout 30 qm guest exec 103 --timeout 20 -- cmd /c type C:\\ProgramData\\wintools\\firstlogon.done; test ! -e /var/lib/vz/template/iso/wintools-unattend.iso && echo UNATTEND_ISO_GONE; timeout 60 find /root /tmp /var/lib/vz \( -name "autounattend.xml*" -o -name "wintools-unattend.iso" \) | wc -l' && test -s .planning/quick/261111-woo-windows-tools-vm/261111-woo-SUMMARY.md</automated>
  </verify>
  <done>The guest reports Windows 11 Pro, the agent answers, the sentinel file exists, WINVM_IP is recorded in winvm.env, the unattend ISO and rendered XML are gone from atlantis, and the SUMMARY skeleton holds the evidence so far. Or: a STOP happened, FX ran, and the SUMMARY records `FAILEXIT_STATUS=stopped`.</done>
</task>

<task type="auto">
  <name>Task 2b: Harden the guest (OpenSSH, Winlogon, Panther, password rotation, Secure Boot/TPM/BitLocker, RDP) and install the apps</name>
  <files>.planning/quick/261111-woo-windows-tools-vm/261111-woo-SUMMARY.md</files>
  <action>
Every STOP in this task runs FX (see `<context>`) first and records its output. Precondition: Task 2a's sentinel succeeded.

**Guest hardening via qemu-ga.** Use `qm guest file-write 103 C:\\Windows\\Temp\\<name>.ps1` plus `qm guest exec 103 --timeout 900 -- powershell -NoProfile -ExecutionPolicy Bypass -File ...`. This avoids nested quoting, and the .ps1 files are deleted afterwards. No .ps1 ever contains a password. Steps:
- (a) Install OpenSSH Server with `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`. If that fails, fall back to `msiexec /i` of `OpenSSH-Win64-v10.4.0.0.msi` from github.com/PowerShell/Win32-OpenSSH releases, downloaded in the guest. Set `sshd` to Automatic and start it, and allow TCP 22 inbound with the Private profile only. If both routes fail: FX, STOP.
- (b) Write `C:\ProgramData\ssh\administrators_authorized_keys` from `/root/wintools-build/authorized_keys` using `qm guest file-write` (public keys only). Then run `icacls` on it with `/inheritance:r /grant *S-1-5-32-544:F /grant SYSTEM:F`. Prove key auth with `ssh -o BatchMode=yes tools@WINVM_IP hostname` from atlantis.
- (c) Winlogon (per W8): remove the `DefaultPassword` value and `AutoLogonCount`, and set `AutoAdminLogon=0`, under `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`. Record evidence with `reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword` (must fail "unable to find") and `reg query ... /v AutoAdminLogon` (must show `0x0` or `0`).
- (d) Delete the answer-file copies: `C:\Windows\Panther\unattend*.xml`, `C:\Windows\Panther\Unattend\*`, `C:\Windows\Panther\UnattendGC\*` (per W8) and any `C:\Windows\System32\Sysprep\unattend.xml`. Then prove with `Get-ChildItem -Recurse C:\Windows\Panther -Include *unattend*` returning nothing.
- (e) Rotate the admin password once (per W8; this neutralises the LSA-secret caveat and the shred-on-CoW caveat together). Windows Setup's autologon may persist the install password as an LSA secret that `reg query` cannot see and that clearing `DefaultPassword` does not remove; reading LSA secrets needs SYSTEM-level tooling, so it is not checked. Instead the install password is made dead. Generate a new value exactly as in Task 2a (pipe, never argv) into winvm.env as `WINVM_ADMIN_PASSWORD_PENDING=`. Write a secret-free `C:\Windows\Temp\rotate.ps1` that reads one line from `[Console]::In`, converts it with `ConvertTo-SecureString -AsPlainText -Force`, calls `Set-LocalUser -Name tools -Password`, and prints `PasswordLastSet`. Feed the pending value with the `printf` builtin from a subshell that sources winvm.env, piped to `ssh root@172.16.1.158 'qm guest exec 103 --pass-stdin 1 --timeout 120 -- powershell -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\rotate.ps1'`. If `--pass-stdin` is rejected, use the same stdin over the guest's OpenSSH (`ssh tools@WINVM_IP powershell -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\rotate.ps1`) with key auth. Prove success by exitcode 0 and a `PasswordLastSet` later than the sentinel time. Only then rewrite winvm.env without argv (awk reading the file, `umask 077`, `chmod 600`): the old value becomes `WINVM_INSTALL_PASSWORD_RETIRED=` (kept only so the Task 2c leak grep can search for it) and the pending value becomes `WINVM_ADMIN_PASSWORD=`. If the rotation fails, keep the old value as `WINVM_ADMIN_PASSWORD`, delete the pending line, record NOT PROVEN, and FX/STOP.
- (f) Record `Confirm-SecureBootUEFI` (must be True) and `Get-Tpm` (TpmPresent must be True). If either is false the VM is misbuilt: FX, STOP. Check `manage-bde -status C:`; if protection or encryption is on, run `manage-bde -off C:` and record it (research §5.3).
- (g) Confirm that `fDenyTSConnections=0`, that `UserAuthentication=1` (NLA), and that the RDP firewall rules are enabled.

**Apps.** For each Victron installer, download on atlantis into `/root/wintools-build/dl/` with `timeout 900 curl -fL`:
- VictronConnect: `https://updates.victronenergy.com/feeds/VictronConnect/windows/w10/VictronConnectInstaller.exe`
- VEConfigure: `https://www.victronenergy.com/Executables/VEConfig/VECSetup_B.exe`. Not `/upload/software/VECSetup.exe`, which is a 2015 relic.

Prove each file is an Inno Setup PE before use: the first two bytes are `MZ`, and `grep -a -c 'Inno Setup'` is at least 1. Record the sha256 and Last-Modified. If either check fails, do not install, and record NOT PROVEN (no STOP; continue — this deliberately fails the Task 2c verify so the gap is surfaced, never hidden).

`scp` the installers from atlantis into the guest's `C:\Installers\` over the guest's OpenSSH as `tools@WINVM_IP`, using key auth with atlantis's key. Install each through guest exec with `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`.

For C-Bus Toolkit and ElkRP2, take the operator-supplied Mac paths from Task 0 and `scp` them from the workstation to `tools@WINVM_IP:C:/Installers/`. Their silent switches are UNVERIFIED (research A6), so try them in this order, each bounded by `--timeout`:
1. Inno: `/VERYSILENT /NORESTART`
2. InstallShield/MSI: `/s /v"/qn"`
3. NSIS: `/S`

If none produces an uninstall entry, leave the file in `C:\Installers\` and record PENDING-OPERATOR with the exact RDP steps. If the paths were "not yet", record PENDING-OPERATOR with exact steps: download URL, scp command and interactive install over RDP. These are PENDING, not failed.

Verify the installs with one guest-exec script that lists the DisplayName and DisplayVersion of `HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*` and the `WOW6432Node` equivalent, matching `VictronConnect|VE ?Config|C-Bus|Toolkit|ElkRP`. Delete the `C:\Windows\Temp\*.ps1` files written by this task. Add the rows from this task to the SUMMARY.
  </action>
  <verify>
    <automated>ssh root@172.16.1.158 'timeout 20 qm status 103; timeout 60 qm guest exec 103 --timeout 50 -- reg query "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v AutoAdminLogon; timeout 60 qm guest exec 103 --timeout 50 -- powershell -NoProfile -Command "Get-ChildItem -Recurse C:\\Windows\\Panther -Include *unattend* -ErrorAction SilentlyContinue | Measure-Object | Select -Expand Count"' && /usr/bin/grep -c '^WINVM_INSTALL_PASSWORD_RETIRED=' ~/.claude/secrets/winvm.env && ! /usr/bin/grep -q '^WINVM_ADMIN_PASSWORD_PENDING=' ~/.claude/secrets/winvm.env</automated>
  </verify>
  <done>OpenSSH key auth works for `tools`; Winlogon evidence shows DefaultPassword absent and AutoAdminLogon=0; no Panther/UnattendGC answer-file copy remains; the install password is rotated and retired in winvm.env (600); Secure Boot and TPM are True and BitLocker is off; NLA is on; Victron apps are installed or NOT PROVEN with evidence, and C-Bus/ELK are installed or PENDING-OPERATOR with exact steps. Or: a STOP happened, FX ran, and the SUMMARY records `FAILEXIT_STATUS=stopped`.</done>
</task>

<task type="auto">
  <name>Task 2c: Prove reachability, shut down, eject, re-plan No changes, prove memory returned, run leak checks, and finish the SUMMARY</name>
  <files>.planning/quick/261111-woo-windows-tools-vm/261111-woo-SUMMARY.md</files>
  <action>
Every STOP in this task taken while the VM may still be running runs FX first and records its output.

**Reachability.** These failures are NOT PROVEN rows, not STOPs; the shutdown below still happens.
- From LXC 100: `ssh root@172.16.1.159 'timeout 5 bash -c "</dev/tcp/WINVM_IP/3389" && echo OPEN'`.
- From the workstation: `nc -z -G 5 WINVM_IP 3389`.

**Shut down.**
1. Run `qm shutdown 103 --timeout 300` on atlantis inside `timeout 360`. Do not use `qm stop` unless the shutdown times out; if it does, run FX (which stops it) and record that the graceful shutdown failed.
2. Once stopped, `qm set 103 --delete ide0,sata0` if either is still present, and `qm set 103 --ide2 none,media=cdrom` so the VM does not hold the Win11 ISO. Terraform ignores cdrom.
3. Assert `qm status 103` = stopped, and that `qm config 103` has no `onboot: 1`, no ide0 and no sata0.
4. Final re-plan (per W2): from `infra/`, run `terraform plan -target=proxmox_virtual_environment_vm.wintools -no-color` (no apply, no plan file in the repo). It must contain `No changes`. This proves `ignore_changes` holds after the ide2 eject, the out-of-band `qm set` calls and the power cycle. Any diff means NOT PROVEN and STOP: do NOT apply; report the diff.
5. Wait 60 s and read MemAvailable. It counts as PROVEN if it is at least the Task 2a `PRESTART_MEMAVAILABLE_KB` minus 524288 kB; otherwise record NOT PROVEN with both numbers (ARC noise is possible).

**Leak checks.**
- Run `/usr/bin/grep -rlF -f <(sed -nE 's/^WINVM_(ADMIN_PASSWORD|INSTALL_PASSWORD_RETIRED)=//p' ~/.claude/secrets/winvm.env)` over the repo working tree (excluding `.git`) and over `infra/terraform.tfstate*`. It must match nothing (exit 1). First assert the process substitution yields exactly two non-empty lines, so an empty pattern list cannot pass vacuously. The patterns go through a process substitution, so they stay out of argv. Note: on the workstation `grep` is ugrep, hence `/usr/bin/grep`.
- On atlantis, re-run the cleanup `find` assertion, and remove `/root/wintools-build/` (fenced to that exact literal path).

**SUMMARY.** Finish it with a proof table. Each row's status cell holds exactly one of `PROVEN`, `NOT PROVEN` or `PENDING-OPERATOR`, with the command and the observed value. The token `NOT PROVEN` appears ONLY in status cells, never in prose, so the verify can count it. Rows:
- ISO sha256
- plan 1/0/0
- state-list diff (only wintools added)
- re-plan No changes (Task 1)
- FX idle run (`FAILEXIT_STATUS=stopped`)
- edition
- Secure Boot
- TPM
- BitLocker
- agent ping
- FirstLogon sentinel
- 3389 from LXC 100
- 3389 from workstation
- NLA
- each of the four apps
- unattend ISO/XML gone
- Panther/UnattendGC gone
- Winlogon DefaultPassword absent / AutoAdminLogon=0 (reg query output)
- install password rotated
- password absent from repo and tfstate
- stopped
- onboot unset
- final re-plan No changes
- memory returned
- Termix SSH host + RDP host — always `PENDING-OPERATOR` (the executor does not touch Termix), with the exact steps from NETWORK.md

Also record:
- the guest IP
- the shred-on-CoW caveat for the filesystem recorded in preflight, and that the password rotation makes any surviving copy dead
- the LSA-secret caveat: Windows Setup autologon may have stored the install password as an LSA secret; it was not read (needs SYSTEM tooling), and it is stale because the password was rotated
- the vzdump `all` finding
- the C-Bus interface question
- any FX invocations, with their output
- the operator follow-ups: UniFi DHCP reservation for WINVM_IP; activation with the operator's own key (Settings → Activation → Change product key); M1XEP firmware ≥ 2.0.42 check; adding the Termix SSH host and RDP host. Do not touch Home Assistant.
  </action>
  <verify>
    <automated>set -o pipefail; S=.planning/quick/261111-woo-windows-tools-vm/261111-woo-SUMMARY.md; ssh root@172.16.1.158 'timeout 20 qm status 103 | grep -Fx "status: stopped" && ! timeout 20 qm config 103 | grep -E "^(onboot: 1|ide0|sata0):"; test ! -e /var/lib/vz/template/iso/wintools-unattend.iso && test ! -e /root/wintools-build && test "$(timeout 60 find /root /tmp /var/lib/vz \( -name "autounattend.xml*" -o -name "wintools-unattend.iso" \) | wc -l)" -eq 0 && echo ATLANTIS_CLEAN' && test "$(/usr/bin/grep -c -F 'NOT PROVEN' "$S")" -eq 0 && test "$(/usr/bin/grep -c -E '\| (PROVEN|PENDING-OPERATOR) \|' "$S")" -ge 28 && /usr/bin/grep -E 'Termix' "$S" | /usr/bin/grep -F -q 'PENDING-OPERATOR'</automated>
  </verify>
  <done>Every proof row has a status and evidence; the verify passes only when zero `NOT PROVEN` rows exist (any NOT PROVEN row fails it, surfacing the gap rather than counting it as a pass). The VM is stopped with no install media attached and the final re-plan read No changes. No answer-file artefact remains on atlantis or in the guest. The live password and the retired install password exist only in ~/.claude/secrets/winvm.env (600). Termix is PENDING-OPERATOR. C-Bus/ELK are installed or PENDING-OPERATOR with exact steps.</done>
</task>

<task type="auto">
  <name>Task 3: Document VM 103 in DEPLOYMENT.md and NETWORK.md, screen, and commit explicit paths</name>
  <files>DEPLOYMENT.md, NETWORK.md</files>
  <action>
**DEPLOYMENT.md.** Make two changes in §1 Infrastructure:
- Add VM 103 to the "Terraform manages" sentence.
- Add a subsection, "VM 103 `wintools` (Windows 11 Pro tools VM)", covering:
  - Purpose: C-Bus Toolkit, ElkRP2, VictronConnect, VEConfigure.
  - Powered off by default. `on_boot=false`, and 4 GiB against roughly 6 GiB host MemAvailable, so check MemAvailable before starting.
  - Terraform defines only the shell, with no credential, and is changed only via `terraform plan -target=proxmox_virtual_environment_vm.wintools -out=<file outside the repo>` followed by applying that file. Anything other than the expected counts means stop.
  - Why `ignore_changes = [cdrom, started]` and the single-cdrom provider limit.
  - The rebuild path: Task 0 ISO steps (with the machine-enforced sha256 comparison), then `wintools-unattend.sh build` with the password on stdin, then `cleanup`, then rotate the install password.
  - Failure exit: `wintools-unattend.sh failexit` cleans up and leaves VM 103 stopped; run it whenever a build or session is abandoned.
  - Rollback, as in this plan's `<context>` § Rollback: copy tfstate first; R1 saved targeted destroy plan that must read `Plan: 0 to add, 0 to change, 1 to destroy.` with only the wintools address, applied from the file; R2 `qm destroy 103 --purge` plus `terraform state rm`; then remove leftover `vm-103-disk-*` (efidisk/tpmstate) volumes and the virtio/unattend ISOs. Not run unless decided.
  - The admin account `tools`, with the password in `~/.claude/secrets/winvm.env` (600) and never in tfvars or tfstate.
  - Activation is the operator's own key; the generic key only selects Pro.
  - The pinned machine version warning.
  - Keep BitLocker off.

**NETWORK.md.**
- Under "Proxmox Cluster → atlantis", add a "VM 103 `wintools`" entry with the IP (DHCP; reservation recommended), the role, and "powered off by default".
- Add a row to the SSH Access Summary for `wintools`: user `tools`, key auth, only when running.
- Add a short "Windows tools VM (VM 103) — operating it" subsection with:
  - Start and stop from Termix: add an SSH host for root@172.16.1.158 in Termix and run `qm start 103` / `qm shutdown 103`. Check `qm status 103` = stopped when done. State that the Termix hosts are not yet configured (PENDING-OPERATOR).
  - Add the RDP host in Termix: host WINVM_IP, port 3389, user `tools` (or `WINTOOLS\tools`), NLA security, ignore the self-signed certificate. Whether Termix exposes the security and cert fields is unverified.
  - The ELK caveat: the M1XEP takes ONE TCP session. Disable Home Assistant's `elkm1` integration for the ElkRP2 session, then re-enable it. Connect on secure port 2601. The M1XEP firmware must be ≥ 2.0.42 for Windows 11 TLS (operator check); 2101 non-secure is the fallback.
  - The Remote VEConfigure via VRM workflow from research §4: GX VRM Portal = Full; download the `.rvsc`; edit; use **Close**, not Save As; upload the same `.rvsc`. VictronConnect reaches GX-attached devices via VictronConnect-Remote over VRM. There is no USB or Bluetooth.
  - The C-Bus interface: CNI/Wiser on the LAN works, while a USB PC interface conflicts with no-USB.

State reality, not intent: use the IP actually measured in Task 2a, and say which apps are installed versus PENDING-OPERATOR.

**Screen and commit.**
1. Run the DEPLOYMENT §4 secret screen over the staged diff, with a positive control first.
2. Re-run the password-absence grep for both the live and retired passwords (process-substitution pattern, two non-empty lines asserted).
3. Stage explicit paths only: `infra/vm-wintools.tf`, `scripts/wintools-unattend.sh`, `scripts/wintools-autounattend.xml.tmpl`, `DEPLOYMENT.md`, `NETWORK.md`, and the files in `.planning/quick/261111-woo-windows-tools-vm/`.
4. Before committing, assert that `git diff --cached --name-only` lists only those paths, and that none of `infra/terraform.tfstate*`, `infra/terraform.tfvars`, `.planning/phases/07-pilot-12-albums-end-to-end/07-UAT.md`, `.planning/trips/` or `projects/` is staged.
5. Commit with a `feat(quick-261111-woo): ...` message ending with the line `Claude-Session: https://claude.ai/code/session_01U6L4aqFUkCSrsCfTUHx8AQ`.
  </action>
  <verify>
    <automated>/usr/bin/grep -c 'wintools' DEPLOYMENT.md NETWORK.md && /usr/bin/grep -F -c 'elkm1' NETWORK.md && /usr/bin/grep -F -c 'failexit' DEPLOYMENT.md && /usr/bin/grep -F -c '0 to add, 0 to change, 1 to destroy' DEPLOYMENT.md && git show --stat --format=%B HEAD | /usr/bin/grep -F 'Claude-Session: https://claude.ai/code/session_01U6L4aqFUkCSrsCfTUHx8AQ' && ! git show --name-only --format= HEAD | /usr/bin/grep -E 'tfstate|tfvars|07-UAT|^projects/|^\.planning/trips/'</automated>
  </verify>
  <done>DEPLOYMENT.md and NETWORK.md describe VM 103 as measured, covering power-off default, failure exit, rollback, Termix start/stop/RDP (PENDING-OPERATOR), the ELK one-connection caveat, the VRM workflow and the password location. One commit contains only the explicit paths, with no state, tfvars or unrelated files, and the secret screen passed.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| workstation → atlantis (ssh stdin) | The admin password crosses here on stdin only |
| atlantis → guest (qemu-ga `--pass-stdin`) | The rotated password crosses here on stdin only |
| Terraform → local tfstate (public repo dir) | Must carry no credential for VM 103 |
| internet → atlantis/guest | Vendor installers and virtio-win are downloaded |
| LAN → guest :3389/:22 | RDP and OpenSSH are exposed on the flat LAN while the VM runs |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-woo-01 | Information disclosure | tfstate / git | mitigate | No password var, templatefile or provisioner in `vm-wintools.tf`. A grep for both the live and retired passwords over the repo and `terraform.tfstate*` uses a process-substitution pattern (two non-empty lines asserted) and must match nothing |
| T-woo-02 | Information disclosure | rendered XML / unattend ISO on atlantis | mitigate | umask 077, `chmod 600` and a root-only dir. `cleanup` shreds and deletes them with a fenced literal path, and a `find` assertion proves they are gone. The CoW shred caveat is recorded, and the install password is rotated so any CoW residue is a dead credential |
| T-woo-03 | Information disclosure | Panther (incl. UnattendGC) / Winlogon DefaultPassword / LSA secret in guest | mitigate | Panther copies deleted and proven by a recursive listing; `reg query` evidence for DefaultPassword absent and AutoAdminLogon=0; AutoLogon LogonCount 1; the install password is rotated via qemu-ga stdin so a persisted LSA secret is stale |
| T-woo-04 | Information disclosure | argv / transcript | mitigate | Passwords move via the `printf` builtin into ssh stdin (and `qm guest exec --pass-stdin`) and are substituted with bash parameter expansion. No `set -x`, no echo, and winvm.env is rewritten with awk reading the file (CONVENTIONS rule 7) |
| T-woo-05 | Tampering | vendor installers / ISOs | mitigate | Win11 sha256 is compared machine-side with `[ "$a" = "$b" ]` against Microsoft's published hash, fail closed. Victron files must pass the MZ and Inno Setup header checks and have their sha256 recorded. virtio-win comes from the pinned archive URL with its sha256 recorded and its driver layout proven with `isoinfo -J -l` |
| T-woo-06 | Elevation of privilege | RDP / OpenSSH on LAN | mitigate | NLA is required, sshd is key-only for Administrators, firewall rules are Private-profile only, and the VM is powered off by default |
| T-woo-07 | Denial of service | atlantis RAM (≈6 GiB available, recorded memory-exhaustion freezes) | mitigate | `build` refuses to start below 5 GiB MemAvailable (captured once, before start); `build`'s EXIT trap and every STOP branch run `failexit`, which stops VM 103 (shutdown, then `qm stop`) and asserts `stopped`; the balloon is not inflated (floating = dedicated); recovery of MemAvailable after shutdown is proven |
| T-woo-08 | Tampering | Terraform apply blast radius (LXC 100 landmine) | mitigate | Only targeted plans saved to files outside the repo; create must read 1/0/0, rollback destroy must read 0/0/1 with only the wintools address, and exactly that plan file is applied. tfstate is copied to the scratchpad before apply and `terraform state list` is diffed after. A final targeted re-plan must read No changes |
| T-woo-SC | Tampering | package installs | accept | No npm/pip/cargo installs. OpenSSH comes from Windows FoD or the Microsoft MSI |
</threat_model>

<verification>
- The ISO sha256 matched Microsoft's published value by machine comparison.
- The targeted plan read `Plan: 1 to add, 0 to change, 0 to destroy.`, the state-list diff added only the wintools address, and both the post-apply and the final re-plan read `No changes`.
- `failexit` ran on the idle VM and printed `FAILEXIT_STATUS=stopped`; any real STOP recorded FX output with the VM stopped.
- `qm agent 103 ping` succeeded, the FirstLogon sentinel existed before hardening, and get-osinfo shows Windows 11 Pro.
- 3389 is open from LXC 100 and from the workstation.
- The uninstall registry lists the Victron apps (and C-Bus/ELK, or they are PENDING-OPERATOR).
- No unattend ISO or XML remains on atlantis, the guest's Panther/UnattendGC copies are gone, Winlogon evidence is recorded, the install password is rotated, and neither password is in the repo or tfstate.
- `qm status 103` = stopped, onboot is unset, and MemAvailable is within 512 MiB of the pre-start value.
</verification>

<success_criteria>
Every row of the SUMMARY proof table is PROVEN or PENDING-OPERATOR (the Task 2c verify fails on any NOT PROVEN row, so a gap is surfaced, explained with evidence, and never counted as a pass). VM 103 is stopped at the end of the run on every path, success or failure. The commit contains only the explicit paths listed in Task 3.
</success_criteria>

<output>
Create `.planning/quick/261111-woo-windows-tools-vm/261111-woo-SUMMARY.md` (skeleton in Task 2a, extended in 2b, finished in 2c, committed in Task 3)
</output>
