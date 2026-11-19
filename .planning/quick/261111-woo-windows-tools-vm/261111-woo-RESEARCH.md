# Quick 261111-woo: Windows 11 Pro "tools" VM on atlantis — Research

**Researched:** 2026-11-11
**Domain:** Proxmox VE 9.2 / bpg Terraform / unattended Windows 11 / vendor config tools
**Confidence:** MEDIUM overall. Host and provider facts were measured directly. The Windows answer-file mechanics are cited. The vendor installers are only partly verifiable: ElkRP2 is behind a login and se.com blocks scripted downloads.

<user_constraints>
## Locked operator decisions (verbatim from the task brief)
- Win 11 Pro using Microsoft's public generic Pro install key. The operator activates later with their own key.
- 4 GB RAM / 2 cores / 64 GB on `local-lvm` (lvmthin).
- q35 + OVMF + Secure Boot (pre-enrolled keys) + vTPM v2.0.
- virtio-scsi + virtio-net on `vmbr0` (flat LAN 172.16.1.0/24, DHCP from UniFi).
- `onboot=false`. The VM stays powered off except during sessions, because host RAM is tight.
- Victron access is through the Cerbo/Venus GX on LAN/VRM only. No USB, no Bluetooth.
- Access is RDP through Termix's built-in RDP plugin.
</user_constraints>

## Summary

The repo's lock file pins **bpg/proxmox 0.95.0**. The newest release is 0.121.0 (2026-11-09). Stay on 0.95.0. **In 0.95.0 (and in 0.121.0) the legacy `proxmox_virtual_environment_vm` resource allows only ONE `cdrom` block (`MaxItems: 1`).** Multi-cdrom support is PR #2748, which was never merged, and issue #718 is still open. [VERIFIED: provider source at tags v0.95.0/v0.121.0]. The install needs three ISOs: Windows, virtio-win and the answer file. Terraform should own the Windows ISO on `ide2`. A `null_resource` (the repo's existing pattern) should `qm set` the other two onto `ide0` and `sata0`.

You cannot rely on downloading the Win11 ISO by script. Here is the 2026-11-11 test of the Mido/Fido API flow (run from the workstation):
- The first call worked and returned the edition ID (`3813`, "Windows 11 (multi-edition ISO for x64 devices)").
- The SKU-table step came back empty, so no link was produced.
- Microsoft has also been blocking Fido-style automation with error `715-123130` since Feb 2026.

Plan on this route instead: the operator generates the official 24-hour link in a browser on the Mac, and atlantis runs `curl` against that link.

The host is ready:
- PVE 9.2.26, kernel 7.0.14-28.
- `pve-edk2-firmware-ovmf 4.2026.08-1`, which means new EFI disks get both the 2011 and 2023 Microsoft Secure Boot certificates.
- `swtpm 0.10.2`, `genisoimage` installed (`xorriso` is not).
- `local` has 75 GB free and `local-lvm` 140 GB free.
- **Only about 6 GiB of RAM is available** out of 28.
- No VMs exist yet. The next free ID is 101, but 101 is reserved by `var.cerebro_vmid`, **so use VMID 103.**

**Primary recommendation:**
- Terraform owns the VM shell, with `started=false`, `on_boot=false`, `boot_order=["scsi0","ide2"]` and `lifecycle.ignore_changes=[cdrom]`.
- A one-shot host script builds the answer-file ISO, attaches the extra CD-ROMs, starts the VM and presses a key at the "Press any key to boot from CD" prompt with `qm sendkey`.
- After install the extra CD-ROMs are detached and the answer ISO is **deleted**, because it holds the admin password.

## Host facts (measured on atlantis, 2026-11-11, read-only ssh)

| Fact | Value |
|---|---|
| PVE / kernel | `pve-manager/9.2.26`, `7.0.14-28-pve` |
| CPU | AMD Ryzen AI 9 HX PRO 370 (Zen 5) |
| RAM | 28 GiB total, ~6 GiB `available` — a 4 GiB VM fits, with little headroom |
| q35 versions | `q35` = alias of `pc-q35-11.1` (newest) |
| OVMF | `pve-edk2-firmware-ovmf 4.2026.08-1`; `OVMF_VARS_4M.ms.fd` present |
| ISO tooling | `genisoimage 1.1.11` ✓, `xorriso` ✗ |
| Storage | `local` dir, 75 GB free; `local-lvm` lvmthin, 140 GB free |
| IDs in use | LXC 100, 102; no QEMU VMs; `var.cerebro_vmid=101` reserved → **use 103** |

## 1. Getting the ISOs onto atlantis

**Win11: do not script it.** The Mido/Fido flow has three steps: the `vlscppe.microsoft.com/tags` session permit, then `getskuinformationbyproductedition`, then `GetProductDownloadLinksBySku` [CITED: github.com/ElliotKillick/Mido `consumer_download()`]. When I ran it on 2026-11-11 it returned the edition ID and then an empty SKU table, so it produced no link. Further probing was stopped deliberately, because it amounts to working around a bot check. Since Feb 2026 Microsoft has also been returning `715-123130` to Fido-style automation; community reports say the block is aimed mainly at Insider ISOs. [CITED: windowsforum.com/threads/…401425, hothardware.com/news/rufus-accuses-ms-blocking-downloads]

Procedure for the operator:
1. On the Mac, open https://www.microsoft.com/software-download/windows11 and go to "Download Windows 11 Disk Image (ISO) for x64 devices".
2. Choose English, then copy the 64-bit link. It is valid for 24 hours.
3. On atlantis, run `curl -fL -o /var/lib/vz/template/iso/Win11_x64_en-us.iso '<link>'`. Do not route the ~7 GB through the Mac.
4. Check `sha256sum` against the hash list Microsoft publishes on the same page.

Whether the link works from a different IP than the browser that generated it is [ASSUMED]. Mido generates the link and downloads with it in one process, so it does not answer that. **Fallback:** download in the browser, then `scp` the file to `/var/lib/vz/template/iso/`.

**virtio-win, current stable = 0.1.302-1** (released 2026-08-27; bundles qemu-ga-win 110.2.3) [VERIFIED: the fedorapeople `stable-virtio/virtio-win.iso` 302-redirects to `archive-virtio/virtio-win-0.1.302-1/virtio-win.iso`].
- Stable URL: `https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso`.
- For reproducibility, pin the archive URL `…/archive-virtio/virtio-win-0.1.302-1/virtio-win.iso`.
- The ISO has `w11\amd64` driver folders, which work for 24H2/25H2 [CITED: schneegans unattend-generator `modifier/Disk.cs` builds `vioscsi\w%OS_VERSION%\amd64`; the exact 0.1.302 folder list was not enumerated — [ASSUMED] that `w11` is present, verify with `isoinfo -l` before writing the answer file].
- Community note: 0.1.285 had a vioscsi regression on Server 2025; 0.1.302 is the release after it [CITED: medium.com/@PlanB./virtio-win-0-1-302-is-stable…, LOW].
- Terraform can fetch this ISO directly with `proxmox_virtual_environment_download_file` (`content_type="iso"`, `datastore_id="local"`, `url=<archive URL>`, `file_name="virtio-win-0.1.302.iso"`).

## 2. Unattended install

### Packaging and attachment
- **Answer-file search:** Setup implicitly looks for `autounattend.xml` at the root of removable and CD/DVD media [CITED: learn.microsoft.com/windows-hardware/manufacture/desktop/windows-setup-automation-overview]. So build a tiny ISO whose root holds `autounattend.xml`. The file name matters. The volume label does not.
- **Build command:** `genisoimage -quiet -J -joliet-long -r -V WINTOOLS_UNATTEND -o /var/lib/vz/template/iso/wintools-unattend.iso /root/wintools-unattend/`. Joliet (`-J`) keeps the long, mixed-case name intact for Windows.
- **Slots:** q35 exposes only `ide0` and `ide2` for IDE [CITED: bpg docs `cdrom.interface`]. Layout:
  - `ide2` = Win11 ISO (Terraform `cdrom`)
  - `ide0` = virtio-win (`qm set`)
  - `sata0` = unattend ISO (`qm set`)
- **"Press any key to boot from CD or DVD":** the Microsoft `efisys.bin` waits about 5 seconds for a key, then falls through. Set `boot_order = ["scsi0","ide2"]`.
  - First boot: the disk is empty, so OVMF falls through to the CD. Have the start script send keys: `qm start 103; for i in $(seq 1 20); do sleep 1; qm sendkey 103 ret; done` [ASSUMED timing — have the script screenshot or watch the console once].
  - Every later boot: the disk boots first, so the prompt never comes back.
  - Alternative: remaster the ISO with `efi/microsoft/boot/efisys_noprompt.bin`. That needs `xorriso`, which is not installed, plus ~7 GB of scratch space. Use it only if `sendkey` proves flaky.

### Minimal `autounattend.xml` (amd64)

The template lives in the repo. Its password placeholder is filled from a `sensitive` Terraform var through `templatefile()`, then uploaded with a `file` provisioner. **The password never goes on a command line** (CONVENTIONS rule 7).

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
 <settings pass="windowsPE">
  <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
   <InputLocale>en-US</InputLocale><SystemLocale>en-IE</SystemLocale><UILanguage>en-US</UILanguage><UserLocale>en-IE</UserLocale>
  </component>
  <component name="Microsoft-Windows-PnpCustomizationsWinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <DriverPaths>
    <!-- CD letters in WinPE are not deterministic: list D..G for each driver. Keys must be unique. -->
    <PathAndCredentials wcm:action="add" wcm:keyValue="1"><Path>D:\vioscsi\w11\amd64</Path></PathAndCredentials>
    <PathAndCredentials wcm:action="add" wcm:keyValue="2"><Path>E:\vioscsi\w11\amd64</Path></PathAndCredentials>
    <PathAndCredentials wcm:action="add" wcm:keyValue="3"><Path>F:\vioscsi\w11\amd64</Path></PathAndCredentials>
    <PathAndCredentials wcm:action="add" wcm:keyValue="4"><Path>G:\vioscsi\w11\amd64</Path></PathAndCredentials>
    <!-- repeat keys 5-8 for NetKVM\w11\amd64 and 9-12 for Balloon\w11\amd64 -->
   </DriverPaths>
  </component>
  <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <DiskConfiguration><Disk wcm:action="add"><DiskID>0</DiskID><WillWipeDisk>true</WillWipeDisk>
    <CreatePartitions>
     <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
     <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
     <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
    </CreatePartitions>
    <ModifyPartitions>
     <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
     <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID></ModifyPartition>
     <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label><Letter>C</Letter></ModifyPartition>
    </ModifyPartitions></Disk></DiskConfiguration>
   <ImageInstall><OSImage>
    <InstallFrom><MetaData wcm:action="add"><Key>/IMAGE/NAME</Key><Value>Windows 11 Pro</Value></MetaData></InstallFrom>
    <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
   </OSImage></ImageInstall>
   <UserData><AcceptEula>true</AcceptEula>
    <ProductKey><Key>VK7JG-NPHTM-C97JM-9MPGT-3V66T</Key><WillShowUI>OnError</WillShowUI></ProductKey>
   </UserData>
  </component>
 </settings>
 <settings pass="specialize">
  <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <ComputerName>WINTOOLS</ComputerName><TimeZone>GMT Standard Time</TimeZone>
  </component>
  <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <RunSynchronous>
    <RunSynchronousCommand wcm:action="add"><Order>1</Order><Path>reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f</Path></RunSynchronousCommand>
    <RunSynchronousCommand wcm:action="add"><Order>2</Order><Path>reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
    <RunSynchronousCommand wcm:action="add"><Order>3</Order><Path>reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
   </RunSynchronous>
  </component>
 </settings>
 <settings pass="oobeSystem">
  <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <InputLocale>en-US</InputLocale><SystemLocale>en-IE</SystemLocale><UILanguage>en-US</UILanguage><UserLocale>en-IE</UserLocale>
  </component>
  <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <OOBE><HideEULAPage>true</HideEULAPage><HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
    <HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><ProtectYourPC>3</ProtectYourPC></OOBE>
   <UserAccounts><LocalAccounts><LocalAccount wcm:action="add">
    <Name>tools</Name><Group>Administrators</Group><Password><Value>${admin_password}</Value><PlainText>true</PlainText></Password>
   </LocalAccount></LocalAccounts></UserAccounts>
   <AutoLogon><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>tools</Username>
    <Password><Value>${admin_password}</Value><PlainText>true</PlainText></Password></AutoLogon>
   <FirstLogonCommands>
    <SynchronousCommand wcm:action="add"><Order>1</Order><CommandLine>cmd /c for %d in (D E F G) do if exist %d:\virtio-win-guest-tools.exe start /wait %d:\virtio-win-guest-tools.exe /install /quiet /norestart</CommandLine></SynchronousCommand>
    <SynchronousCommand wcm:action="add"><Order>2</Order><CommandLine>powershell -NoProfile -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private; Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'"</CommandLine></SynchronousCommand>
    <SynchronousCommand wcm:action="add"><Order>3</Order><CommandLine>cmd /c powercfg /change standby-timeout-ac 0 &amp; powercfg /change monitor-timeout-ac 0 &amp; powercfg /h off &amp; net accounts /maxpwage:unlimited</CommandLine></SynchronousCommand>
    <SynchronousCommand wcm:action="add"><Order>4</Order><CommandLine>cmd /c for %d in (D E F G) do if exist %d:\sources\sxs DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:%d:\sources\sxs</CommandLine></SynchronousCommand>
    <SynchronousCommand wcm:action="add"><Order>5</Order><CommandLine>powershell -NoProfile -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0; Set-Service sshd -StartupType Automatic; Start-Service sshd"</CommandLine></SynchronousCommand>
   </FirstLogonCommands>
  </component>
 </settings>
</unattend>
```

Notes on the answer file:
- **Drivers:** `PnpCustomizationsWinPE/DriverPaths` loads the drivers in WinPE. "Boot-critical drivers appear on the Windows image before Setup installs that image" [CITED: learn.microsoft.com/…/add-device-drivers-to-windows-during-windows-setup], so vioscsi is carried into the installed OS. That a DriverPath on a drive letter that does not exist is skipped harmlessly is [ASSUMED — it is common community practice; a failure would show up as Setup halting at the disk step]. The schneegans generator does the same job with an explicit `drvload` plus `dism /Add-Driver` [CITED: github.com/cschneegans/unattend-generator `modifier/Disk.cs`].
- **Generic key:** `VK7JG-NPHTM-C97JM-9MPGT-3V66T` is the generic (default/RTM) Pro key. It selects the edition and does not activate. Microsoft does not publish it on Learn; it is documented by many secondary sources [CITED: winaero.com/windows-11-generic-keys-for-all-editions, elevenforum.com/t/…3713, MEDIUM]. Do **not** use the GVLK `W269N-…`, because it puts the install on the Volume channel. Later, the operator runs Settings → Activation → Change product key.
- **Local account on 24H2/25H2:** `OOBE\BypassNRO.cmd` was removed (26200.5516), and `start ms-cxh:localonly` was blocked in the Oct 2025 Insider builds. **An answer file that declares `LocalAccounts` still creates a local account and skips the MSA screens.** Microsoft still lists answer files as a supported provisioning route [CITED: ghacks.net/2023/01/26/…, windowsforum.com/threads/…383989, github.com/Stensel8/BypassNRO (tested 25H2 26200, 2026-09-19)]. The BypassNRO registry value in `specialize` is belt-and-braces, and is reported still honoured on 26120/26220 [CITED: gHacks, MEDIUM].
- **Time zone:** Europe/Dublin = `GMT Standard Time` [ASSUMED from Windows tz list].
- **RDP:** the RDP firewall rule group is the indirect string `@FirewallAPI.dll,-28752`, which avoids locale issues [ASSUMED].
- **.NET 3.5:** enabled offline from the Win11 ISO's `sources\sxs` (ElkRP2 needs .NET 2.0+, see §4). This needs the Win11 ISO still attached at first logon, which it is.
- **OpenSSH Server** is a Feature on Demand, so `Add-WindowsCapability` needs internet/Windows Update access. UniFi DHCP gives the VM internet, so expect it to work. Fallback: Microsoft's own MSI, `OpenSSH-Win64-v10.4.0.0.msi` from github.com/PowerShell/Win32-OpenSSH (latest release 2026-10-20) [VERIFIED: GitHub API]. Run it with `msiexec /i … /qn`.
- **virtio-win-guest-tools.exe** is a WiX Burn bundle. `/install /quiet /norestart` is [ASSUMED from community usage]. It installs all drivers plus qemu-ga.
- **Password exposure:** the `${admin_password}` placeholder is rendered **in plain text** into an ISO under `/var/lib/vz/template/iso`, and also into Terraform state when it is passed through a resource. Delete the ISO after install. The repo is public; `terraform.tfstate` and `tfvars` are git-ignored [VERIFIED: `git check-ignore`].

## 3. bpg/proxmox 0.95.0 resource sketch

```hcl
resource "proxmox_virtual_environment_vm" "wintools" {
  node_name = var.proxmox_node            # "atlantis"
  vm_id     = 103
  name      = "wintools"
  started   = false                       # never let apply boot it
  on_boot   = false
  stop_on_destroy = true
  machine   = "pc-q35-11.1"               # pin explicitly; PVE pins Windows guests anyway
  bios      = "ovmf"
  scsi_hardware = "virtio-scsi-single"    # one controller per disk => iothread works
  operating_system { type = "win11" }
  agent    { enabled = true }             # harmless until qemu-ga is installed; started=false means no wait
  cpu      { cores = 2  type = "x86-64-v3" }
  memory   { dedicated = 4096  floating = 4096 }   # balloon device present (stats), no inflation
  efi_disk  { datastore_id = "local-lvm"  type = "4m"  pre_enrolled_keys = true }
  tpm_state { datastore_id = "local-lvm"  version = "v2.0" }
  disk {
    datastore_id = "local-lvm"  interface = "scsi0"  size = 64
    file_format = "raw"  iothread = true  discard = "on"  ssd = true
  }
  network_device { bridge = "vmbr0"  model = "virtio" }
  cdrom { file_id = "local:iso/Win11_x64_en-us.iso"  interface = "ide2" }
  boot_order = ["scsi0", "ide2"]
  lifecycle { ignore_changes = [cdrom] }  # detached/emptied after install; ide0/sata0 are qm-set, outside TF
}
```

Pitfalls with the provider:
- **Only one `cdrom` block.** Attach `ide0`/`sata0` with `qm set 103 --ide0 local:iso/virtio-win-0.1.302.iso,media=cdrom --sata0 local:iso/wintools-unattend.iso,media=cdrom` from a `null_resource` that uses the repo's ssh-password connection. These attachments are outside Terraform's model, so they will not show up as drift.
- **`machine` drift.** For Windows guests, PVE pins the machine version at creation [CITED: pve.proxmox.com/wiki/QEMU_Machine_Version_Upgrade]. Plain `q35` can therefore read back as `pc-q35-11.1` and show a permanent diff [ASSUMED]. Setting `pc-q35-11.1` explicitly avoids this; it passes the provider's `MachineTypeValidator` regex [VERIFIED: v0.95.0 `validators.go`].
- **TPM.** `tpm_state.version` is creation-only. Changing it recreates the VM [CITED: bpg docs].
- **Secure Boot certificates.** With firmware ≥ 4.2025.05-1, new EFI disks contain both the 2011 and 2023 MS certificates and get the `ms-cert=2023k` marker [CITED: `man qm` on atlantis]. Provider 0.95.0 has no `ms_cert` attribute. Whether it shows a diff on that marker is [ASSUMED no]. Check `terraform plan` after create.
- **Targeted apply only.** CLAUDE.md warns that a bare `apply` in `infra/` has planned to destroy LXC 100. Use `terraform plan -target=proxmox_virtual_environment_vm.wintools -target=null_resource.wintools_*` and read the plan.
- **Timeouts.** With `started=false`, create returns quickly and the 1800 s defaults are fine.
- **`keyboard_layout`.** It defaults to `en-us`. That only affects the noVNC console; RDP uses the client's keyboard.

## 4. Apps (vendor sources only)

| App | Version | Download | Gated? | Installer / silent |
|---|---|---|---|---|
| **C-Bus Toolkit** | **1.19.6** (paired with C-Gate 3.9.0) [CITED: se.com C-Bus Software & Updates page] | `https://www.se.com/au/en/download/document/C-Bus_Toolkit_V1_19_6/` | Not login-gated on the page, **but se.com returns HTTP 403 to `curl`** (bot protection) → operator downloads in a browser | UNVERIFIED technology and switches. Toolkit bundles C-Gate 3 (JRE 11 since C-Gate 3.4.0) and installs to Program Files/ProgramData since 1.19.0. Install interactively in the first RDP session. |
| **ElkRP2** | **2.0.41** [CITED: elkproducts.com/elkdoc/elkrp2-remote-programming-software/] | elkproducts.com, **login required** ("Access to this content is restricted. Login or Register"); ELK grants end-user accounts on request against the system serial | **Yes** | UNVERIFIED technology. Requires .NET 2.0+ → enable NetFx3 (done in FirstLogon). Install interactively. |
| **VictronConnect** | 6.43 per the vendor page [CITED: victronenergy.com/support-and-downloads/software via search] | `https://updates.victronenergy.com/feeds/VictronConnect/windows/w10/VictronConnectInstaller.exe` — resolves 200, 123.7 MB, Last-Modified 2026-11-10 [VERIFIED: HTTP HEAD]. Path inferred from the `/w7/` path documented by silentinstallhq, so [ASSUMED] to be the same file the page links. | No | **Inno Setup 6.3.0** [VERIFIED: header fingerprint] → `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-` |
| **VEConfigure 3** (VE Configuration tools) | VEConfigure 3 v9004248 per the vendor page | `https://www.victronenergy.com/Executables/VEConfig/VECSetup_B.exe` — 200, 9.6 MB, Last-Modified 2026-09-21 [VERIFIED: HTTP HEAD]. `VECSetup_A.exe` is the older 2026-04 build; `/upload/software/VECSetup.exe` is a **2015 relic, do not use**. | No | **Inno Setup 5.5.6** [VERIFIED] → same switches |

Connection notes:
- **ELK: ElkRP2, not ElkRP.** ElkRP2 is the current tool for the M1 [CITED: elkproducts.com; ELK forum replies say to use 2.0.41 with M1XEP firmware ≥ 2.0.34, latest 2.0.51].
  - Connect over the LAN to the M1XEP on **2601**, the secure port, with "Connect Non-Secure" unticked.
  - M1XEP firmware older than 2.0.42 only offers SSLv3/TLS 1.0, which Windows 11 has disabled. If the connection fails, check the XEP firmware first. Fallback is the non-secure port 2101.
  - **The M1XEP accepts one TCP session at a time.** If Home Assistant's `elkm1` integration is connected, ElkRP2 cannot connect, or it will knock HA off. Disable HA's ELK integration for the session [CITED: elkproducts.com forums, cocoontech; MEDIUM].
- **Victron, no USB:** there is no MK3 adapter, so VEConfigure works **only through Remote VEConfigure on VRM**:
  1. On the GX: Settings → VRM Online Portal → VRM Portal = **Full** (the old name is "two-way communication"). The GX must be powered from the battery and online. Venus OS ≥ 2.62 for the current flow.
  2. On VRM → Device list → **Remote VEConfigure**, download the `.rvsc` file. Do not choose "open in VEConfigure".
  3. Edit it, then close with VEConfigure's **Close** button. Not "Save As": that writes a `.vsc` that cannot be uploaded.
  4. Upload the same `.rvsc` file.

  [CITED: victronenergy.com/media/pg/VRM_Portal_manual/en/remote-veconfigure.html]

  VictronConnect reaches GX-attached devices through **VictronConnect-Remote** over VRM. That needs Full access and a VRM login, and covers VE.Direct/VE.Can products [CITED: victronenergy.com/media/pg/VictronConnect_app/en/victronconnect-remote…]. The VictronConnect installer may offer to install the MK3/VE.Direct USB drivers; they are harmless and not needed.
- **C-Bus link — OPEN QUESTION.** Toolkit reaches the network through a CNI/Wiser over TCP (LAN, fine) or a USB/serial PC interface (needs USB passthrough, which the locked decisions exclude). Confirm which interface the site has.

## 5. Pitfalls (Win11 on PVE 9.2 / kernel 7.0)

1. **CPU type:** use `x86-64-v3`. Zen 5 supports it, and 24H2 needs v2 (POPCNT/SSE4.2). It does not expose SVM, so Windows will not enable VBS/HVCI on top of KVM, which on 2 vCPUs is a noticeable cost. `host` is the alternative if a tool needs a CPU feature [ASSUMED rationale].
2. **Memory:** 4 GiB against ~6 GiB available on the host. Start the VM only when needed (`onboot=false`, as decided). Set `floating = dedicated` so the balloon driver reports stats but does not inflate. Real ballooning in Windows at 4 GiB just causes paging. ZFS ARC is the host's flexible consumer, not the VM [ASSUMED; see memory note *atlantis load 68 + idle CPU = memory exhaustion*].
3. **Secure Boot + virtio:** Red Hat signs the virtio-win drivers and they load under Secure Boot. The 2023 CA question is handled by the current firmware (§3). Leave BitLocker off: device encryption can auto-enable on Win11 Pro with TPM. If `manage-bde -status` shows it on, turn it off, because a vTPM reset would otherwise lock the disk.
4. **Guest agent:** `agent.enabled=true` before qemu-ga exists is harmless only because `started=false`. Do not let any provisioner wait on `wait_for_ip`, since there is no static IP. Read the DHCP lease from UniFi, or run `qm guest cmd 103 network-get-interfaces` once the agent is up. Pin a DHCP reservation in UniFi so Termix has a stable target.
5. **RDP from Termix (non-domain):** use NLA with the local account. Username `tools` (or `.\tools`/`WINTOOLS\tools`), security `nla` or `any`, and ignore the self-signed certificate. Termix 26.x runs RDP itself by default, with no external guacd unless "Use an external guacd" is on [CITED: docs.termix.site/plugins/remote-desktop/reference/]. Whether Termix exposes security-mode and ignore-cert fields is UNVERIFIED. Termix runs on LXC 100, which reaches 172.16.1.0/24 through vmbr0.
6. **Machine-version pin:** never upgrade `pc-q35-11.1` casually. Windows re-enumerates the NIC and the network profile can flip back to Public, which closes RDP.
7. **Clean-up step:**
   1. Shut down.
   2. `qm set 103 --delete ide0,sata0`.
   3. Delete `wintools-unattend.iso` (it holds the password).
   4. Optionally set the Terraform `cdrom` to `file_id = "none"`. `ignore_changes` stops that from being drift either way.

## Assumptions Log

| # | Claim | Risk if wrong |
|---|---|---|
| A1 | The Win11 24 h link works from atlantis's IP | Fallback is `scp` from the Mac |
| A2 | Missing DriverPaths letters are skipped harmlessly | Setup stops at the disk page; switch to `drvload` in a RunSynchronous loop |
| A3 | `qm sendkey … ret` catches the CD prompt | Remaster with `efisys_noprompt.bin` (install xorriso) |
| A4 | `virtio-win-guest-tools.exe /install /quiet /norestart` | No qemu-ga; install `guest-agent\qemu-ga-x86_64.msi /qn` instead |
| A5 | The `VictronConnect …/w10/` URL is the current official build | Download from the vendor page in a browser |
| A6 | C-Bus Toolkit and ElkRP2 installer switches | Install interactively over RDP (recommended anyway) |
| A7 | The bpg 0.95.0 efidisk `ms-cert` marker causes no diff | Add `efi_disk` to `ignore_changes` |

## Open Questions
1. **C-Bus interface:** CNI on the LAN, or a USB PC interface? A USB interface conflicts with the no-USB decision.
2. **ElkRP2 account:** does the operator have an elkproducts.com login? If not, an approval lead time is needed. Ness's AU site hosts Ness-branded builds; prefer ELK's.
3. **VMID 103 and hostname `WINTOOLS`:** the operator should confirm both. A UniFi DHCP reservation is recommended.

## Sources
- bpg provider source/docs at tags v0.95.0 and v0.121.0 (`proxmoxtf/resource/vm/vm.go`, `validators.go`, `docs/resources/virtual_environment_vm.md`); PR github.com/bpg/terraform-provider-proxmox/pull/2748 (unmerged); issue #718 (open)
- atlantis `man qm` (Secure Boot Certificate Expiration), `pveversion`, `kvm -machine help`, `dpkg -l`
- https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/ (stable → 0.1.302-1), https://github.com/virtio-win/virtio-win-pkg-scripts README
- https://github.com/ElliotKillick/Mido (Mido.sh `consumer_download`)
- https://windowsforum.com/threads/windows-11-insider-iso-downloads-blocked-rufus-fido-and-mct-workarounds.401425/ ; https://hothardware.com/news/rufus-accuses-ms-blocking-downloads
- https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-device-drivers-to-windows-during-windows-setup
- https://github.com/cschneegans/unattend-generator (`modifier/Disk.cs`)
- https://www.ghacks.net/2023/01/26/how-to-bypass-the-microsoft-account-requirement-during-windows-setup/ ; https://windowsforum.com/threads/windows-11-oobe-local-account-bypass-removed-provision-with-autounattend.383989/ ; https://github.com/Stensel8/BypassNRO
- https://winaero.com/windows-11-generic-keys-for-all-editions/ ; https://www.elevenforum.com/t/generic-product-keys-to-install-or-upgrade-windows-11-editions.3713/
- https://pve.proxmox.com/wiki/QEMU_Machine_Version_Upgrade
- https://www.se.com/au/en/work/services/training/c-bus-network-and-electrical-distribution-training/c-bus-software-and-updates/
- https://www.elkproducts.com/elkdoc/elkrp2-remote-programming-software/ ; https://www.elkproducts.com/forums/topic/cannot-connect-to-elk-m1/ ; https://cocoontech.com/threads/elkrpii-wont-connect-to-specific-m1xep.29711/
- https://www.victronenergy.com/support-and-downloads/software ; https://www.victronenergy.com/media/pg/VRM_Portal_manual/en/remote-veconfigure.html ; https://www.victronenergy.com/media/pg/VictronConnect_app/en/victronconnect-remote--vc-r----configuration-and-monitoring-via-vrm.html ; https://silentinstallhq.com/victronconnect-silent-install-how-to-guide/
- https://github.com/PowerShell/Win32-OpenSSH/releases
- https://docs.termix.site/plugins/remote-desktop/reference/

**Valid until:** ~2026-12-11. Re-check the virtio-win stable version, the vendor app versions and the bpg pin before executing.
