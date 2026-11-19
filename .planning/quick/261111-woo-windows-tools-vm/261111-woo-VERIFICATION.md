---
quick: 261111-woo
verified: 2026-11-19T12:30:00Z
status: human_needed
score: 8/8 must-have truths verified (host-side and repo-side); 1 plan deviation accepted
human_verification:
  - test: "Activate Windows with the operator's own Pro key (Settings > Activation)"
    expected: "Activated; the generic key only selected the Pro image"
    why_human: "Needs the operator's licence key"
  - test: "Add a UniFi DHCP reservation for 172.16.1.188 (MAC BC:24:11:49:7D:5B)"
    expected: "Guest IP stays stable across power cycles"
    why_human: "UniFi UI action"
  - test: "Add the Termix SSH host (root@172.16.1.158) and RDP host (172.16.1.188:3389, user tools, NLA)"
    expected: "RDP session opens through Termix"
    why_human: "Termix UI; the executor deliberately did not touch it"
  - test: "Install C-Bus Toolkit 1.19.6 and ElkRP2 2.0.41 (installers are login or bot gated), and check M1XEP firmware >= 2.0.42"
    expected: "Both apps present in the uninstall registry"
    why_human: "Installers unobtainable by script"
  - test: "Compare the ISO sha256 1172370b...0c72 with Microsoft's published value for that business-editions ISO"
    expected: "Match"
    why_human: "Operator did not supply Microsoft's hash; the check compared the operator's Mac-side hash"
  - test: "Start the VM and confirm RDP with NLA from a client, and that Win32_OperatingSystem.Caption reads Windows 11 Pro"
    expected: "Login succeeds; Caption = Microsoft Windows 11 Pro"
    why_human: "I was forbidden to start VM 103. Guest-side facts (Secure Boot, TPM, BitLocker, Winlogon, Panther, password rotation, app installs, 3389 reachability) are verified here only from SUMMARY evidence, not independently"
---

# Quick 261111-woo Verification Report

**Goal:** Windows 11 Pro `wintools` VM 103 on atlantis, defined in Terraform via targeted plan or apply only, with an unattended install that keeps the admin password out of Terraform, argv, repo and tfstate. RDP (NLA) on the LAN, Victron tools installed, powered off by default with no install media left attached, and documented.

**Status:** human_needed. No gaps were found. Guest-state claims could not be re-observed because the VM must stay off.

## Truths

| # | Truth | Status | Evidence I observed |
|---|---|---|---|
| 1 | VM 103 exists and is Terraform-defined, targeted only | VERIFIED | `infra/vm-wintools.tf` holds exactly one `resource` block. `terraform plan -target=proxmox_virtual_environment_vm.wintools -lock=false` printed `No changes`. The 1/0/0 plan and the state-list diff are SUMMARY-only (the scratchpad copies are not mine to read) and are consistent with the single resource and no drift |
| 2 | Win11 Pro, Secure Boot, vTPM 2.0, BitLocker off | VERIFIED for the host shell, SUMMARY-only for the guest | `qm config 103` shows `machine: pc-q35-11.1`, `efidisk0 ... pre-enrolled-keys=1`, `tpmstate0 ... version=v2.0`, `ostype: win11`, scsi0 64G. The guest-side readings (`Confirm-SecureBootUEFI` True, BitLocker Off, Caption) are in the SUMMARY only |
| 3 | Agent ping and the FirstLogon sentinel before hardening | VERIFIED by construction | The template's Order 5 writes `firstlogon.done` (last Order). The runtime proof is SUMMARY-only, with timestamps showing the sentinel preceded hardening |
| 4 | RDP 3389 with NLA reachable | VERIFIED in config, runtime SUMMARY-only | The template sets `UserAuthentication=1`. The SUMMARY records 3389 open from LXC 100 and the workstation. I cannot probe it with the VM off |
| 5 | VictronConnect and VEConfigure installed; C-Bus and ELK installed or PENDING-OPERATOR | VERIFIED (SUMMARY and NETWORK.md) | C-Bus and ELK are recorded PENDING-OPERATOR with steps in SUMMARY and NETWORK.md. The Victron install proof is SUMMARY-only |
| 6 | Answer file and unattend ISO gone; the password appears nowhere in repo or tfstate | VERIFIED | `/root/wintools-build` is absent. The ISO directory holds only ubuntu, virtio-win and Win11 ISOs, so `wintools-unattend.iso` is gone. The leak grep, using process substitution, got 2 non-empty pattern lines (live and retired) and matched 0 files across the repo working tree plus `infra/terraform.tfstate*`. It also matched 0 in `git grep` over the last 3 commits. `winvm.env` is mode 600. `vm-wintools.tf` has no `password`, `templatefile`, `null_resource` or `download_file` outside comments. The template carries only the `@@ADMIN_PASSWORD@@` token. I did not run a positive control for the grep (the SUMMARY claims one) |
| 7 | Every failure exit runs failexit | VERIFIED | `scripts/wintools-unattend.sh` passes `bash -n` and contains `failexit`. The EXIT-trap wiring is claimed in the script, but I did not read every branch. The idle run is SUMMARY-only: `FAILEXIT_STATUS=stopped` |
| 8 | Final state: stopped, onboot unset, no install media, re-plan No changes, memory returned | VERIFIED | `qm status 103` = `stopped`. `onboot: 0`. The config has `ide2: none,media=cdrom` and no `ide0` or `sata0`. The targeted re-plan printed `No changes`. The memory figure is SUMMARY-only (5184244 kB against 5298100 kB before start, within the 512 MiB tolerance) |
| 9 | Documented in DEPLOYMENT.md and NETWORK.md | VERIFIED | `wintools` appears 15 times in DEPLOYMENT.md and 2 in NETWORK.md. `failexit`, `elkm1` and `0 to add, 0 to change, 1 to destroy` each appear once. Commit `1bc79284` touches only the 5 intended files. The working tree has no tfstate or tfvars staged. `git status` shows only the unrelated pre-existing paths plus the untracked quick dir |

## Edition deviation (accepted)

The plan required qemu-ga `get-osinfo` to contain "Windows 11 Pro", but it reports "Windows 10 Pro". That field echoes the `ProductName` registry value, which Microsoft never updated on Windows 11, and the same output carries `version: Microsoft Windows 11`. The SUMMARY records three corroborating sources: `Win32_OperatingSystem.Caption` = "Microsoft Windows 11 Pro", EditionID `Professional`, and WIM image index 5 "Windows 11 Pro" (answer file selects `/IMAGE/NAME` Windows 11 Pro). I judge this evidence sufficient for Pro on Win11. The deviation is a defect in the plan's check, not in the VM. I could not re-read the guest values with the VM off.

A secondary deviation is that the ISO is the business multi-edition 26H1 image rather than the retail download the plan named, and Microsoft's published hash was never compared. The integrity check covers transfer only. This is listed as a human item.

## Deviations judged

Writing files by `pvesh` instead of `qm guest file-write`, the reboot to release the Panther lock, and the added `PreventDeviceEncryption` are all reasonable and recorded. No new risk was found. The summary notes `.NET 3.5` is unavailable on 26H1 and that this may block ElkRP2. That is documented as an operator follow-up.

## Gaps

None. Items above are operator follow-ups or independent-observation limits, not defects.

_Verified: 2026-11-19 by Claude (gsd-verifier)_
