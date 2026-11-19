# Deployment Guide

How change reaches the estate: Terraform for infrastructure, git for stacks, and the checks that
tell you whether it landed.

> **Rewritten 2026-09-03.** The previous version of this file described a **TrueNAS Scale Apps**
> workflow with `/mnt/tank/stacks` paths and a TrueNAS UI deployment step. That estate no longer
> exists — the platform is Proxmox VE with an unprivileged LXC. None of the old commands would have
> worked. Verified against the live host.

**Platform:** Proxmox VE 9.1 on `atlantis` (172.16.1.158) → LXC `100` `selfhost` (172.16.1.159),
103 containers.

---

## The deployment model in one paragraph

The repo is a **git clone on the host** at `/mnt/fast/stacks`, tracking `origin/main`. You never
copy files to the server. You commit, push to GitHub, then `git pull` on the LXC and bring the
affected stack up. Terraform owns everything below the container line — the Proxmox host, the LXC
itself, its mounts and its datasets — and is **authoritative**: do not hand-edit what it manages.

```
workstation ──commit──> GitHub (origin/main) ──git pull──> /mnt/fast/stacks on LXC 100
                                                                    │
                                                            docker compose up -d
```

---

## Prerequisites

- SSH to `root@172.16.1.158` (Proxmox host) and `root@172.16.1.159` (LXC 100)
- Terraform 1.10+ locally, for `infra/` only
- Secrets in `~/.claude/secrets/` — **this repo is public**; `.env` files are gitignored and
  credentials are referenced by variable name only, never by value

---

## 1. Infrastructure (Terraform)

```bash
cd infra
terraform init
terraform plan          # ALWAYS read this
terraform apply
```

Terraform manages: the ZFS pool and datasets, LXC 100 (unprivileged, GPU passthrough, bind mounts),
VM 102, VM 103 `wintools` (the Windows tools VM shell only — see below), the `apps:apps` (568:568)
service account, and GPU device mapping (`video:44`, `render:110`).

> ### 🔴 `terraform apply` can destroy LXC 100
>
> A bare apply has planned **`1 to destroy`** on the Docker host and its ~100 containers — armed
> since February by a `bpg/proxmox` provider artifact around `mount_point`. It is now guarded by
> `prevent_destroy` + `ignore_changes`.
>
> The guard has a cost you must know about: **genuine bind-mount edits now plan clean and do
> nothing.** A mount change that appears to apply successfully may not have applied at all.
>
> **Never `apply` without reading the plan.** If you see `destroy` against `lxc-selfhost`, stop.

### Adding a quota'd dataset

Anything that grows without bound gets its own dataset with a `quota`, declared in `infra/` —
never created by hand. `infra/jellyfin-transcode-dataset.tf` is the worked example.

Use **`quota`, not `refquota`**: `quota` counts descendants and returns `ENOSPC`, which is the errno
this estate's log greps key on. `refquota` returns `EDQUOT` and would be invisible to them.

### VM 103 `wintools` (Windows 11 Pro tools VM)

Built 2026-11-19 by quick task 261111-woo. Definition: `infra/vm-wintools.tf`; install tooling:
`scripts/wintools-unattend.sh` + `scripts/wintools-autounattend.xml.tmpl`. Operating it (Termix,
RDP, ELK and Victron workflows): NETWORK.md § *Windows tools VM (VM 103) — operating it*.

- **Purpose:** vendor configuration tools — C-Bus Toolkit, ElkRP2, VictronConnect, VEConfigure.
- **Powered off by default.** `on_boot = false`. The guest takes 4 GiB against roughly 5–6 GiB
  host MemAvailable on a host with a record of memory-exhaustion freezes, so read MemAvailable
  (`grep MemAvailable /proc/meminfo` on atlantis) before `qm start 103`, and `qm shutdown 103` when
  the session ends. Prove `qm status 103` reads `status: stopped` afterwards.
- **Terraform defines the VM shell only and holds no credential.** Change it only with a targeted,
  saved plan, kept outside the repo, then apply exactly that file:

  ```bash
  cd infra
  terraform plan -target=proxmox_virtual_environment_vm.wintools -out=/path/outside/repo/wintools.tfplan
  terraform apply /path/outside/repo/wintools.tfplan
  ```

  Anything other than the expected counts (and any address other than
  `proxmox_virtual_environment_vm.wintools`) means stop — never a bare plan or apply here.
- **Why `ignore_changes = [cdrom, started]`:** bpg/proxmox 0.95.0 allows exactly one `cdrom`
  block, so only the Windows ISO on `ide2` is in Terraform. virtio-win (`ide0`) and the unattend ISO
  (`sata0`) are attached by `qm set` in the script; `ide2` is ejected after install; and the
  operator starts and stops the VM by hand. None of that is drift.
- **Pinned machine version `pc-q35-11.1`.** Do not upgrade it casually: Windows re-enumerates the
  NIC and the network profile can flip to Public, which closes RDP.
- **Keep BitLocker off.** Device encryption **did** auto-start during the 2026-11-19 install (100 %
  used-space encrypted, no protectors); it was reversed with `manage-bde -off C:` to
  `FullyDecrypted`, and `HKLM\SYSTEM\CurrentControlSet\Control\BitLocker\PreventDeviceEncryption=1`
  was set so it does not recur. A vTPM reset with BitLocker on would lock the disk.
- **Installed (2026-11-19):** VictronConnect 6.43.1 and VEConfigure (VE Configuration tools).
  C-Bus Toolkit and ElkRP2 are PENDING-OPERATOR (installers are gated). .NET 3.5 is not an
  optional feature on this build (26H1, 28000); ElkRP2 may need Microsoft's standalone installer.
- **Admin account `tools`.** Its password lives only in `~/.claude/secrets/winvm.env` (mode 600) as
  `WINVM_ADMIN_PASSWORD` — never in tfvars, tfstate or this repo. The install-time password was
  rotated after install; the retired value is kept there only so leak greps can search for it.
- **Activation** is the operator's own key (Settings → Activation → Change product key). The
  generic key in the answer file only selects the Pro image.

**Rebuild path.**
1. ISO: put the Windows 11 x64 ISO at `/var/lib/vz/template/iso/Win11_x64_en-us.iso` on atlantis
   (browser download — Microsoft bot-checks scripts — then `scp`). Compare its sha256 by machine,
   fail closed: `[ -n "$a" ] && [ "$a" = "$b" ]` with `a` from `sha256sum` on atlantis and `b` the
   expected hash lower-cased and whitespace-stripped. Never eyeball it.
2. Create the shell with the targeted plan above (it must read `Plan: 1 to add, 0 to change, 0 to destroy.`).
3. Copy the script and template to `/root/wintools-build/` (mode 700) on atlantis, then pipe the
   password (line 1, `printf` builtin from a subshell that sources `winvm.env`) and the public keys
   for `administrators_authorized_keys` into `bash /root/wintools-build/wintools-unattend.sh build`.
   It refuses to start below 5 GiB MemAvailable (exit 42).
4. Wait for `qm agent 103 ping`, then for `C:\ProgramData\wintools\firstlogon.done`.
5. Run `wintools-unattend.sh cleanup` (ejects and shreds the unattend ISO and rendered XML, then
   asserts they are gone), delete the guest's Panther answer-file copies and Winlogon
   `DefaultPassword`, and **rotate the install password** — `shred` is best-effort on the ext4/LVM
   storage underneath, so the rotation is what makes any surviving copy a dead credential.

**Failure exit.** `ssh root@172.16.1.158 'timeout 400 bash /root/wintools-build/wintools-unattend.sh failexit'`
runs `cleanup`, then `qm shutdown 103` (falling back to `qm stop`), deletes `ide0`/`sata0`, and
asserts `status: stopped`, printing `FAILEXIT_STATUS=stopped` and `FAILEXIT_MEMAVAILABLE_KB=`. Run
it whenever a build or session is abandoned; `build` runs it itself from its EXIT trap on any
failure. If it cannot reach `stopped`, act on atlantis immediately — a running 4 GiB guest is the
memory hazard.

**Rollback (not run unless decided).** First copy `infra/terraform.tfstate` and
`infra/terraform.tfstate.backup` somewhere outside the repo.
- **R1 (preferred):** `terraform plan -destroy -target=proxmox_virtual_environment_vm.wintools -out=<outside-repo>/wintools-destroy.tfplan`.
  It must read exactly `Plan: 0 to add, 0 to change, 1 to destroy.` and show only
  `proxmox_virtual_environment_vm.wintools` — anything else (LXC 100 above all) means stop. Apply
  that file, then delete it. Never a bare `terraform destroy`.
- **R2:** failure exit first, then `qm destroy 103 --purge --destroy-unreferenced-disks 1`, then
  `terraform state rm proxmox_virtual_environment_vm.wintools`, proving with `terraform state list`
  that only that address disappeared.
- After either: `pvesm list local-lvm | grep -E 'vm-103-'` must be empty; free any leftover
  efidisk/tpmstate volume with `pvesm free <volid>`, each volid matching `^local-lvm:vm-103-disk-[0-9]+$`.
  Remove `/var/lib/vz/template/iso/virtio-win-0.1.302.iso` (exact path) and, only if the operator
  says so, the Windows ISO.

---

## 2. Stacks (git + compose)

### The normal flow

```bash
# 1. locally: commit and push
git add stacks/selfhosted/<stack>/
git commit -m "feat(<stack>): ..."
git push origin main

# 2. on the host: pull and bring up
ssh root@172.16.1.159
cd /mnt/fast/stacks
git pull --ff-only origin main
docker compose -f stacks/selfhosted/<stack>/compose.yaml up -d
```

`--ff-only` is deliberate — it fails loudly rather than creating a merge commit on a host you are
not developing on.

Or drive both ends from the workstation:

```bash
bash scripts/sync-repo.sh    # pulls locally AND on the host, then compares commits
```

### Order matters once

**Traefik first** — it defines the shared `t3_proxy` network every other stack attaches to:

```bash
docker compose -f stacks/selfhosted/traefik/compose.yaml up -d
```

`iot_macvlan` is the other external network (real LAN addresses; only `jellyfin` and `dispatcharr`
use it — see [MEDIA.md](MEDIA.md) § 2).

After that, stacks are independent:

```bash
docker compose -f stacks/selfhosted/media/compose.yaml up -d
docker compose -f stacks/selfhosted/arrs/compose.yaml up -d
```

### Verifying it actually landed

```bash
ssh root@172.16.1.159 'cd /mnt/fast/stacks && git rev-parse HEAD'
git rev-parse origin/main            # these must match
docker compose -f stacks/selfhosted/<stack>/compose.yaml ps
```

> ⚠️ **`docker ps` hides a whole class of failure.** A container stuck in `created` is not
> `running`, but also not `exited`, `dead` or `restarting`, so the usual filters miss it. Two
> containers sat silently down for six weeks this way.
>
> ```bash
> docker ps -a --format '{{.State}}' | sort | uniq -c   # the true census
> ```

---

## 3. Storage conventions

| Path | What |
|------|------|
| `/mnt/fast/stacks` | this repo, on the host |
| `/mnt/fast/appdata/<stack>` | persistent app state |
| `/mnt/fast/transcode` | Jellyfin transcode scratch (`fast/transcode`, 50 G quota) |
| `/mnt/tank/media` | media library (9 T) |
| `/mnt/tank/media/Recordings` | server DVR (`tank/media/Recordings`, 250 GB quota, LXC `mp31`) |
| `/mnt/tank/downloads` | download staging |

Ownership `apps:apps` = **568:568**.

BookOrbit was created on its own datasets from day one (`fast/appdata/bookorbit` on mp37 and
`fast/appdata/bookorbit/postgres` on mp38, 16K) on 2026-10-22 by the four-step recipe in
README § Per-app datasets: create the dataset, hotplug with `pct set`, reconcile
`infra/lxc-selfhost.tf`, full send to the backup pool.

**DVR deployment:** `infra/dispatcharr-recordings.tf` declares the recording
dataset and reconciles `mp31`; `infra/lxc-selfhost.tf` also declares the path.
Review a saved plan before applying: the LXC resource's `mount_point` changes are
ignored to prevent replacement. Confirm the actual dataset is mounted inside
LXC 100 before recreating Dispatcharr or Jellyfin with their recording binds.
Use the normal git deployment flow and check both apps for active playback first.
Then run `python3 /mnt/fast/stacks/scripts/dispatcharr-recordings.py --configure-library`
on LXC 100. The [runbook](stacks/selfhosted/media/dispatcharr.md#server-recordings-2026-09-06)
covers the first scan and a recording/playback test. The helper verifies library
settings; verify the ZFS quota separately on Proxmox.

### ⚠️ `/mnt/fast/appdata` is not a mountpoint — check before you assume

`/mnt/fast` and `/mnt/fast/appdata` are **plain directories on LXC 100's 200 G ext4 root disk**.
Only the *children* are ZFS datasets. A new stack directory under `/mnt/fast/appdata/` with no
dataset behind it writes to `/` — and looks identical to one that doesn't.

```bash
# df LIES here — it reports /'s figures for a non-mountpoint. Use:
mountpoint -q /mnt/fast/appdata/<stack> && echo "dataset ✓" || echo "ON / — unbounded ⚠"
```

`teslamate`, `trek`, `monitoring`, `airtrail`, `silo` and n8n's Postgres moved onto datasets on
2026-10-22 (README § Per-app datasets). What is still on `/`, measured that day:

- `documents` — **LIVE**. paperless binds it through `driver_opts` bind volumes
  (`type=none,o=bind,device=/mnt/fast/appdata/documents/...`), so `docker inspect` shows
  `Source: /var/lib/docker/volumes/...` and a "Source not under /mnt/" check misses it. It is the
  next candidate for its own dataset.
- `open-archiver` and `rustdesk` — leftovers of undeployed stacks. Keep them: `rustdesk` holds the
  relay keypair (`id_ed25519`) that clients pin.
- `_ops` (one operator log) and `buzz` (an empty mount-target shadow) — artefacts.

See [MEDIA.md](MEDIA.md) § 8.

**Checklist for a new dataset**, in this order:

1. `zfs create fast/appdata/<name>` on atlantis, owned `568:568`, mode `0755`.
2. `pct set 100 -mpN /mnt/fast/appdata/<name>,mp=/mnt/fast/appdata/<name>`. A new `mpN` hotplugs
   live. Then check from inside a container, not only the LXC shell:
   `docker run --rm -v /mnt/fast/appdata/<name>:/p alpine stat -f -c %t /p` must print `2fc12fc1`
   (ZFS; busybox prints the name as `UNKNOWN`).
3. Append the `mount_point` block to `infra/lxc-selfhost.tf` in host index order. Plan only.
4. **A new dataset is not backed up until a full send creates `backup/appdata/<name>`.
   `backup-incremental.sh` skips it** (it logs "needs a FULL send" and moves on), and
   `check-backup-freshness.sh` cannot see a dataset that is not on the backup pool.

### ⛔ Never leave an anonymous volume

A path the image declares as `VOLUME` but the compose file does not bind gets an **anonymous
volume** under `/var/lib/docker/volumes` — on `/`, unnamed and unbounded. This is how 19 GB of
Jellyfin transcode cache emptied the root filesystem.

```bash
docker image inspect <image> --format '{{json .Config.Volumes}}'   # before deploying
docker volume ls -qf dangling=true                                  # after
```

See [STANDARDS.md](STANDARDS.md) § Volume Mounting.

### Do not stage large files in `/tmp` on the LXC

`/tmp` is **tmpfs, backed by host RAM**. 1.1 GB of XML there took the whole 28 GB box down and
killed SSH on host *and* LXC while ping still worked. Stage under `/mnt/fast/` instead.

### Host-only atlantis tuning (2026-11-11) — not in Terraform

Two changes live only on atlantis (`172.16.1.158`). Terraform does not manage them and the repo
holds no copy, so **a rebuilt atlantis loses both — re-create them by hand.**

- **ZFS ARC ceiling.** `/etc/modprobe.d/zfs.conf` sets `zfs_arc_max=6442450944` (6 GiB; was
  `3113222144`). Not higher: the host routinely has only 2–6 GB available (LXC 100 capped at 24 GB
  plus `mpe` at 8 GB on a 28 GB host), so a bigger ARC recreates the memory exhaustion. The real fix
  is the empty second DIMM slot — a CT32G56C46S5 (32 GB DDR5-5600 SODIMM). Backup:
  `/root/zfs.conf.bak-20261111`.
- **Scrub window.** `/usr/local/sbin/zfs-scrub-window` (`pause|resume`, all pools, logs via
  `logger -t zfs-scrub-window`), driven by `/etc/cron.d/zfs-scrub-window`: pause any in-progress
  scrub at 17:00, resume any paused scrub at 01:00. The stock zfsutils-linux cron still *starts* the
  monthly scrub (2nd Sunday, 00:24). A full `tank` scrub takes ~35 h, and on 2026-11-08 its
  393 MB/s of reads on the spinning pool stalled Jellyfin DirectPlay for hours. A paused scrub
  survives reboot.

---

## 4. Secrets

- `.env` files are **gitignored** and live beside each stack; `.env.sample` is the committed
  template
- **This repo is public.** Credentials go in `~/.claude/secrets/`, referenced by variable name
  only. A gateway password sat in this repo for ~6 months and remains recoverable via
  `git log -S` — redaction is not rotation
- Screen before pushing, and let the screen **gate** the push rather than run alongside it:

```bash
git diff origin/main..HEAD | grep '^+' | \
  grep -inE 'api_key=|password[=:]|Bearer [A-Za-z0-9]{8}|BEGIN [A-Z ]*PRIVATE KEY'
```

Run a positive control first against known secret-shaped text — a screen that has never matched
anything is not evidence of cleanliness.

---

## 5. Updates (Renovate)

Renovate raises PRs against this repo for image tags.

> ⚠️ **Merging a Renovate PR does not deploy anything.** It changes the compose file in git only.
> The host still runs the old image until someone pulls and recreates the container.
>
> Two-part tags like `2.13` **float** — re-pull rather than rewriting the tag.

**There is now an instrument for this. Use it instead of eyeballing `docker ps`:**

```bash
ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-drift.sh'
```

`scripts/check-drift.sh` names every running container whose image tag differs from the pin in this
repo, resolving each one through **its own compose labels** (so `include:` and `${VAR}` both
resolve, and the same image pinned at two different tags in two stack files is never confused). It
also runs **hourly on a systemd timer**, writing a node-exporter textfile that Grafana alerts on
into **Telegram** — drift, unhealthy/`created` containers, and the check's own staleness. Full
detail, the metric list and the gated install steps are in
[stacks/selfhosted/monitoring/README.md](stacks/selfhosted/monitoring/README.md) § Image drift
detection.

> ⛔ **It alerts. It does not deploy.** The pull and the recreate are still manual and deliberately
> so (v1 is alert-only). Nothing will clear a drift alert but a human.

The apply half is `scripts/deploy-stacks.sh` — dry-run by default, apply only via the systemd drop-in, held services stay manual — see [stacks/selfhosted/monitoring/README.md](stacks/selfhosted/monitoring/README.md) § Deploy agent.

Two limits worth knowing before you trust a green:

- **A floating tag that has moved upstream reads as no drift** — `:latest`, `:main` and two-part
  tags all float, so both sides of the comparison still carry the same string. This is the same
  trap as the note above, seen from the other side.
- **`commits behind` is a lower bound** without a fetch: it reads the last-fetched `origin/main`.

The real backlog lives on the **Dependency Dashboard issue**, not the PR list. A config error (e.g.
a `"// key"` comment) silently stops the entire repo run — validate before merging:

```bash
npx --yes renovate-config-validator renovate.json5
bash scripts/check-renovate.sh
```

---

## 6. Post-deploy health check

```bash
bash scripts/quick-health-check.sh      # from the workstation. 0 = healthy, 1 = violation
REMOTE_TIMEOUT=300 bash scripts/quick-health-check.sh   # busy host / slow link
```

Folds in `check-music-freeze.sh`, `check-music-consumers.sh`, `check-jellyfin-transcode.sh` and
`check-drift.sh`. Design rules for adding a check are in [README.md](README.md) § Health Checks —
fail closed, bound remote commands Linux-side, assert rather than report, and (for anything that
runs unattended) assert its own staleness.

> The image-drift block is fatal on **could-not-look** and on the unresolvable-pin set moving, but
> **never on the drift count itself** — see `IMAGE_DRIFT_PROMOTED` in `quick-health-check.sh`.

---

## 7. Troubleshooting

| Symptom | Check |
|---------|-------|
| Container not in `docker ps` | `docker ps -a` — it may be stuck in `created` |
| `address already in use` | Host-level systemd services own ports too (`pulse-agent` owns 9191). See NETWORK.md |
| Service unreachable via `*.deercrest.info` | Traefik up? On `t3_proxy`? Labels correct? |
| Traefik and everything behind it dead, macvlan services fine | Suspect the amdgpu HMM oops — `/proc/pressure/io` `full` ≈ 96% with **idle CPU**, `tainted` bit 7. Recover with sysrq `s`+`b`. See MEDIA.md § 4 |
| `/` filling | `docker system df -v`, `docker volume ls -qf dangling=true`, and § 3 above |
| Certificate issues | `docker logs traefik`; Cloudflare DNS-01 credentials in the traefik `.env` |

```bash
docker logs -f <container>
docker compose -f stacks/selfhosted/<stack>/compose.yaml logs -f
journalctl -u pulse-agent -n 50        # host-level services
```

---

## Reference

- [README.md](README.md) — architecture, storage, health checks
- [NETWORK.md](NETWORK.md) — addressing, ports, host-level services
- [MEDIA.md](MEDIA.md) — media stack LLD
- [TAILSCALE.md](TAILSCALE.md) — remote access LLD
- [STANDARDS.md](STANDARDS.md) — compose and volume conventions

*Last updated: 2026-09-03. Commands verified against the live estate.*
