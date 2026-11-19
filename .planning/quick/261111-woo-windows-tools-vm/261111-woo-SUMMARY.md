---
phase: quick-261111-woo
plan: 01
subsystem: infra (atlantis / Proxmox)
tags: [windows, proxmox, terraform, unattend, wintools, vm-103]
requires: [Win11 ISO on atlantis (Task 0, operator)]
provides: [VM 103 wintools — Windows 11 Pro tools VM, powered off by default]
affects: [infra/, scripts/, DEPLOYMENT.md, NETWORK.md]
tech-stack:
  added: [bpg/proxmox VM resource (0.95.0, existing pin), virtio-win 0.1.302, Windows OpenSSH (FoD)]
  patterns: [targeted saved-plan Terraform, password on stdin only, fenced cleanup + failexit]
key-files:
  created: [infra/vm-wintools.tf, scripts/wintools-unattend.sh, scripts/wintools-autounattend.xml.tmpl]
  modified: [DEPLOYMENT.md, NETWORK.md]
decisions:
  - "Edition proven from Win32_OperatingSystem Caption + EditionID, because qemu-ga get-osinfo pretty-name reads the stale ProductName registry value ('Windows 10 Pro') on Windows 11"
  - "Device encryption auto-started during install; reversed with manage-bde -off and blocked with PreventDeviceEncryption=1"
  - "Guest rebooted once (qm reboot) to release taskhostw TpmTasks' lock on Panther\\UnattendGC logs so the Panther check could reach zero"
metrics:
  started: 2026-11-19T11:29:41Z
  completed: 2026-11-19T12:10:00Z
  duration: ~40 min
---

# Quick 261111-woo: Windows 11 Pro tools VM (VM 103 `wintools`) Summary

VM 103 `wintools` is now on atlantis. Terraform created it as a shell only, from one targeted
saved plan that read 1/0/0. The guest runs Windows 11 Pro build 28000 (26H1) with Secure Boot, a
vTPM 2.0 and BitLocker off. RDP is on with NLA, and OpenSSH works with keys only.
VictronConnect 6.43.1 and VEConfigure are installed. C-Bus Toolkit and ElkRP2 are PENDING-OPERATOR.
The install password was rotated and proven dead. The VM ended stopped with no media attached, and
the final targeted re-plan read `No changes`.

## Proof table

| Proof | Status | Command → observed |
|---|---|---|
| ISO sha256 (transfer integrity) | PROVEN | `[ "$a" = "$b" ]`: atlantis `sha256sum` = expected file = `1172370b7f82820bbb6f4740e364ca8e17524a2f39d2abc26cb13f150fe40c72` → `SHA256_MATCH`. Route: operator scp (business multi-edition ISO `en-us_windows_11_business_editions_version_26h1_updated_oct_2026_x64_dvd_921ccd7c.iso`) |
| Microsoft-published hash comparison | PENDING-OPERATOR | The operator did not supply the hash. The expected value is the operator's Mac-side hash. Compare it with the subscriber/volume portal's published sha256 for that ISO |
| ISO holds a `Windows 11 Pro` image | PROVEN | Read-only loop mount of the WIM XML: index 5 `Windows 11 Pro` / EditionID `Professional`, build 28000 (10 images in total) |
| Targeted plan 1/0/0 | PROVEN | `terraform plan -target=proxmox_virtual_environment_vm.wintools -out=<scratchpad>` → `Plan: 1 to add, 0 to change, 0 to destroy.`; the only address shown was `# proxmox_virtual_environment_vm.wintools will be created` |
| State-list diff | PROVEN | `diff state-list.before state-list.after` → `16a17` / `> proxmox_virtual_environment_vm.wintools` only (16 → 17 entries). Pre-apply tfstate copies are in `<scratchpad>/tfstate-pre-wintools/` |
| Re-plan No changes (Task 1) | PROVEN | `No changes. Your infrastructure matches the configuration.`, with no efi_disk diff (the `ms-cert=2023k` marker caused none, so A7 did not fire) |
| VM shell config | PROVEN | `qm config 103`: machine `pc-q35-11.1`, efidisk0 `pre-enrolled-keys=1,ms-cert=2023k`, tpmstate0 `version=v2.0`, scsi0 64G, net0 virtio on vmbr0, `onboot: 0` |
| FX idle run | PROVEN | `failexit` on the idle VM → `CLEANUP_OK=1`, `FAILEXIT_STATUS=stopped`, `FAILEXIT_MEMAVAILABLE_KB=5069400`, `FAILEXIT_CLEANUP_RC=0`, ssh rc 0 |
| Start gate | PROVEN | `build` printed `PRESTART_MEMAVAILABLE_KB=5298100` (≥ 5242880), so the VM started |
| Edition | PROVEN | `Win32_OperatingSystem.Caption` = `Microsoft Windows 11 Pro`, EditionID `Professional`, build 28000. qemu-ga `get-osinfo` gives `version: Microsoft Windows 11` / `version-id: 11`, but its pretty-name is `Windows 10 Pro` because it echoes the registry ProductName, which also reads `Windows 10 Pro`. See Deviations |
| Secure Boot | PROVEN | `Confirm-SecureBootUEFI` → `True` |
| TPM | PROVEN | `Get-Tpm` → `TpmPresent=True TpmReady=True`; SpecVersion `2.0` |
| BitLocker | PROVEN | Device encryption had auto-started (`Used Space Only Encrypted`, 100 %, Protection Off, no protectors). `manage-bde -off C:` → `Fully Decrypted` / `0.0%`; after reboot `Get-BitLockerVolume` → `Off / FullyDecrypted`; `PreventDeviceEncryption=0x1` |
| Agent ping | PROVEN | `qm agent 103 ping` succeeded at 2026-11-19T11:47:27Z |
| FirstLogon sentinel | PROVEN | `qm guest exec … type C:\ProgramData\wintools\firstlogon.done` → exitcode 0, `done`, at 11:47:33Z (file written 11:47:23Z). This was before any hardening step |
| OpenSSH key auth | PROVEN | Capability `NotPresent` → `Installed`; sshd Running/Automatic; FW rule Private only. `ssh -o BatchMode=yes tools@172.16.1.188 hostname` → `WINTOOLS` from atlantis and from the workstation |
| 3389 from LXC 100 | PROVEN | `ssh root@172.16.1.159 'timeout 5 bash -c "</dev/tcp/172.16.1.188/3389"'` → `OPEN_FROM_LXC100` |
| 3389 from workstation | PROVEN | `nc -z -G 5 172.16.1.188 3389` → `succeeded` |
| NLA | PROVEN | `fDenyTSConnections=0 UserAuthentication=1`; RDP rules (TCP, UDP, Shadow) Enabled=True; network profile `Private` |
| VictronConnect | PROVEN | Uninstall registry: `VictronConnect version 6.43.1 \| 6.43.1`. Installer: MZ + `Inno Setup` ×3, sha256 `ed8c6fa9fa2f22a4b54eed9ea9f488dcb031a36ad2c762d1121a547a3a0b4e24`, Last-Modified Tue, 10 Nov 2026 12:43:34 GMT; `/VERYSILENT …` exitcode 0 |
| VEConfigure | PROVEN | Uninstall registry: `VEFlash, VEConfig and VE.Bus configure tools \| 248.166.161.159` (the vendor's DisplayVersion string). Installer `VECSetup_B.exe`: MZ + `Inno Setup` ×3, sha256 `ba1027dff4428e9358167d9eb108cf5bc48470dd8b6745652326308d843f0a5b`, Last-Modified Mon, 21 Sep 2026 16:30:16 GMT; exitcode 0 |
| C-Bus Toolkit | PENDING-OPERATOR | Installer not supplied (se.com 403s scripts). Steps below |
| ElkRP2 | PENDING-OPERATOR | Installer not supplied (elkproducts.com login). Steps below |
| Unattend ISO/XML gone (atlantis) | PROVEN | `cleanup` while running: `ejected ide0/sata0 (live)`, `shredded …/wintools-unattend.iso`, `shredded …/render.yGSEYI/autounattend.xml`, `CLEANUP_OK=1`. Re-asserted at the end: `CLEANUP_OK=1`, `ATLANTIS_CLEAN`, `find … | wc -l` = 0, `/root/wintools-build` removed |
| Panther/UnattendGC gone | PROVEN | Deleted `Panther\unattend.xml` and `unattend-original.xml`. UnattendGC was locked by `taskhostw.exe TpmTasks`, so it was deleted after one guest reboot. `Get-ChildItem -Recurse C:\Windows\Panther -Include *unattend*` → `PANTHER_UNATTEND_REMAINING=0`; `Sysprep\unattend.xml` absent |
| Winlogon DefaultPassword absent / AutoAdminLogon=0 | PROVEN | `reg query … /v DefaultPassword` → `ERROR: The system was unable to find the specified registry key or value.` (exit 1); `reg query … /v AutoAdminLogon` → `AutoAdminLogon REG_SZ 0`; `AutoLogonCount` absent. Re-read after the reboot, same values |
| Install password rotated | PROVEN | `rotate.ps1` over `qm guest exec --pass-stdin 1` → exitcode 0, `PASSWORD_LAST_SET=2026-11-19T11:54:35Z`, later than the sentinel (11:47:23Z). `ValidateCredentials` → `CURRENT_VALID=True`, `RETIRED_VALID=False` |
| Guest leak scan | PROVEN | Byte scan (ASCII + UTF-16LE) of both passwords over Panther, Windows\Temp, ProgramData\wintools, Sysprep, Windows\Setup, Windows\Logs and Windows\debug → `SCANNED=76 HITS=0 UNREADABLE=11` (11 locked files were not read). Positive control on a planted dummy file → `HITS=1` |
| Password absent from repo and tfstate | PROVEN | Process substitution gave exactly 2 non-empty lines. `/usr/bin/grep -rlF --exclude-dir=.git -f <(…) . infra/terraform.tfstate*` → rc 1 (no match). Scratchpad also rc 1. Positive control matched |
| Stopped | PROVEN | `qm shutdown 103 --timeout 300` rc 0 (graceful, no forced stop) → `status: stopped` |
| onboot unset / no install media | PROVEN | `qm config 103`: `onboot: 0`, no ide0, no sata0, `ide2: none,media=cdrom` |
| Final re-plan No changes | PROVEN | Targeted plan after the ide2 eject, the out-of-band `qm set` calls and the power cycles → `No changes. Your infrastructure matches the configuration.` |
| Memory returned | PROVEN | 60 s after shutdown, MemAvailable = 5184244 kB, which is ≥ 5298100 − 524288 = 4773812 kB |
| Termix SSH host + RDP host | PENDING-OPERATOR | The executor did not touch Termix. Steps are in NETWORK.md § Windows tools VM (VM 103) and below |

## Recorded facts

- **Guest IP:** 172.16.1.188 (DHCP), recorded as `WINVM_IP` in `~/.claude/secrets/winvm.env` (600).
- **Preflight:** VMID 103 was free (`qm status 103` errored, both confs absent, cluster VMs `[100, 102]`).
  `pc-q35-11.1` was listed. local-lvm had 135,246,418 KiB free.
- **vzdump `all` finding:** `pvesh get /cluster/backup` → `[]`. There are no backup jobs at all, so
  none has `all` set, and VM 103 is not backed up by any job.
- **Shred caveat:** `/var/lib/vz/template/iso` and `/root` are on `/dev/mapper/pve-root`, **ext4**
  (journalled, on LVM). `shred` is best-effort there, so old blocks may survive. Because the
  install password is rotated and proven invalid (`RETIRED_VALID=False`), any surviving copy is a
  dead credential.
- **LSA-secret caveat:** Windows Setup's autologon may have stored the install password as an LSA
  secret. It was not read, because that needs SYSTEM-level tooling. It is stale because the
  password was rotated.
- **virtio-win:** 0.1.302 from the pinned archive URL, sha256
  `303f7ae40dad495d6ae474fdc571df58958a4dbc5c37a522d80f9a203867949d`. `isoinfo -J -l` proved
  vioscsi and netkvm `w11/amd64` and `virtio-win-guest-tools.exe`. It stays at
  `/var/lib/vz/template/iso/virtio-win-0.1.302.iso` (rollback removes it).
- **.NET 3.5 is not an optional feature on 26H1 (build 28000).** `dism /online /get-featureinfo
  /featurename:NetFx3` → `0x800f080c Feature name NetFx3 is unknown`, so FirstLogon Order 4 was a
  no-op. .NET 4.8.x is present (Release `0x82406`). ElkRP2 (.NET 2.0+) may need Microsoft's
  standalone .NET Framework 3.5 installer. This is recorded in NETWORK.md.
- **C-Bus interface question (open):** CNI/Wiser on the LAN works from this VM. A USB PC interface
  conflicts with the no-USB decision. NETWORK.md already lists a `cgate` Pi (172.16.1.128) as the
  C-Gate host. The operator should confirm which interface the site uses.
- **FX invocations:** one, the planned idle run (output in the table). No STOP branch fired, so no
  real failure exit was needed.
- **Guest reboot:** one `qm reboot 103` (rc 0, agent back at 12:03:18Z), to release the UnattendGC lock.

## Operator follow-ups

1. **UniFi DHCP reservation** for 172.16.1.188 (MAC `BC:24:11:49:7D:5B`).
2. **Activation:** Settings → Activation → Change product key, using your own Pro key. The generic
   key only selected the Pro image.
3. **M1XEP firmware ≥ 2.0.42** check (needed for Windows 11 TLS on port 2601).
4. **Termix:** add an SSH host `root@172.16.1.158` (to run `qm start 103` / `qm shutdown 103`), and
   an RDP host 172.16.1.188:3389, user `tools`, NLA, ignore the self-signed cert. Do not touch Home
   Assistant beyond disabling `elkm1` for an ElkRP2 session.
5. **C-Bus Toolkit 1.19.6** (se.com C-Bus Software & Updates page) and **ElkRP2 2.0.41**
   (elkproducts.com, login): download in a browser on the Mac, start the VM, then
   `scp ~/Downloads/<installer>.exe tools@172.16.1.188:C:/Installers/` (key auth), RDP in and install
   interactively. Install .NET Framework 3.5 (Microsoft's standalone installer) if ElkRP2 asks for it.
   Shut the VM down afterwards and confirm `status: stopped`.
6. **Microsoft-published sha256:** compare it with `1172370b…0c72` when convenient.
7. **Note:** `scripts/wintools-unattend.sh failexit` is no longer on atlantis because
   `/root/wintools-build` was removed per plan. Re-copy the script before any rebuild.

## Deviations from Plan

1. **[Rule 1 - Check bug] Edition check source.** The plan required qemu-ga `get-osinfo`
   pretty-name to contain `Windows 11 Pro`, but it returned `Windows 10 Pro`. qemu-ga echoes
   `HKLM\…\Windows NT\CurrentVersion\ProductName`, which Microsoft never updated for Windows 11 (the
   guest reads `Windows 10 Pro` there too). In the same output, qemu-ga reports
   `version: Microsoft Windows 11`. The authoritative sources agree: `Win32_OperatingSystem.Caption`
   = `Microsoft Windows 11 Pro`, EditionID `Professional`, and the ISO image selected was index 5,
   `Windows 11 Pro`. The edition was the thing being proven, and it was proven, so no STOP/FX was
   taken. The orchestrator should confirm it agrees.
2. **[Rule 3 - Blocking] `qm guest file-write` does not exist on PVE 9.2.** Files were written with
   `pvesh create /nodes/atlantis/qemu/103/agent/file-write --encode 0` and base64 content. They
   were public keys and secret-free .ps1 scripts only.
3. **[Rule 2 - Critical] BitLocker device encryption had auto-started.** It was decrypted (plan
   step f), and `PreventDeviceEncryption=1` was added so it does not re-arm.
4. **[Rule 3 - Blocking] Panther\UnattendGC was locked** by `taskhostw.exe TpmTasks`. One guest
   reboot released it. It held only setup logs (no answer-file copy), and the guest leak scan found
   neither password in Panther.
5. **Additional proof (not in plan):** after the rotation, `ValidateCredentials` showed the current
   password is valid and the retired one is not. The guest leak scan was added with a positive control.
6. **Commit scope:** per the orchestrator's constraint, SUMMARY/PLAN/RESEARCH under
   `.planning/quick/261111-woo-windows-tools-vm/` were left for the orchestrator to commit.

## Known Stubs

None. C-Bus Toolkit, ElkRP2 and Termix are PENDING-OPERATOR by design, because their installers
and the UI are operator-gated.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: lan-ssh | (guest) | OpenSSH Server on 172.16.1.188:22. It is key-only for Administrators, the firewall rule is Private-profile only, and it is reachable only while the VM runs. This is in the plan (T-woo-06) and is noted here as live LAN surface |
| threat_flag: no-backup | (atlantis) | No vzdump job exists, so VM 103's disk is not backed up |

## Commit

- `1bc79284` feat(quick-261111-woo): Windows 11 Pro tools VM 103 wintools on atlantis (not pushed)

## Self-Check: PASSED

All three repo files exist, commit `1bc79284` exists, and the Task 1, 2c and 3 automated verifies printed PASS.
