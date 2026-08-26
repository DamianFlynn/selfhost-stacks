# Phase 2: NFS Export and Music Assistant Reachability - Research

**Researched:** 2026-08-26
**Domain:** Linux knfsd export of a ZFS dataset; Home Assistant OS Supervisor network storage; Music Assistant filesystem providers; Terraform-over-SSH host configuration
**Confidence:** HIGH on the mount-route question and the export mechanics; MEDIUM on the live-estate preconditions (see § Session Limitation)

---

## Session Limitation — read this first

**No live estate access was available during this research session.** Tailscale is stopped on the
workstation and `ssh root@172.16.1.158` timed out (off-LAN). Every claim below about the *current*
state of atlantis, LXC 100, the NUC, or Music Assistant's installed configuration is therefore
`[ASSUMED]` or inherited from Phase 1 artifacts, **not** measured in this session. Every claim
about *how the software behaves* is drawn from upstream source at a pinned tag and is `[VERIFIED]`
or `[CITED]`.

The plan must open with a probe step that measures the assumed preconditions. They are listed in
§ Environment Availability with the exact commands.

---

## Summary

The phase's headline open question — Route A (HAOS network storage → `/media/<name>` → MA "Local
Disk" provider) versus Route B (MA's own "Filesystem (NFS share)" provider) — **is resolvable from
primary sources and both routes work.** The apparent contradiction between the HA Supervisor source
and Music Assistant's documentation is not a contradiction at all: MA's doc sentence is about
mounting a **local host folder** into `/media`, which Supervisor genuinely refuses (its mounts API
schema accepts only `cifs` and `nfs`, never `bind`). Mounting a **network share** with
`usage: media` is exactly what Supervisor is built to do, it lands at `/media/<name>`, and the
bind into the add-on carries `PropagationMode.RSLAVE` so it is visible inside the Music Assistant
container. The MA maintainer confirmed the HA-storage route in discussion #1198. Route A is the
recommendation; Route B is fully specified below as a drop-in fallback and is *also* known-good
(the MA base image ships `nfs-common`, and the add-on's AppArmor profile explicitly permits
`mount`).

Two premises carried in from the ROADMAP need correcting, and both change what the plan must do.
**First, "Music Assistant never purges stale entries" is false** for the installed version:
`sync_library()` computes `prev_filenames - cur_filenames` and calls `_process_deletions()` plus
`_process_orphaned_albums_and_artists()` on every sync. It is guarded — a scan that returns zero
files against a previously non-empty library aborts deletions — but it is not absent. The
"three albums first" gate is still right, for a *different and better* reason: the album's provider
identity is `albumartist + os.sep + album`, so an album imported under the wrong album artist
creates a durable wrong-artist entry, and the cheapest place to discover that is on three albums,
not on 34 GB. **Second, the reboot race is not a Supervisor ordering bug.** `sys_mounts.load()` runs
sequentially *before* `sys_apps.load()` in `Core.setup()`, and add-ons only boot in `Core.start()`
after that. The race is narrower and nastier than "MA starts first": if the NFS server is
unreachable during Supervisor's ≤40 s mount window, Supervisor bind-mounts an **empty read-only
emergency directory** into `/media/<name>` — so MA sees a path that exists and is empty, not a
missing path or an error.

On the server side, one export option closes the worst failure mode this phase can produce and is
not in either candidate recorded in CLAUDE.md: **`mountpoint`**. It refuses to export a path unless
that path is itself a mount point, which means a host reboot where `nfs-server.service` starts
before `zfs-mount.service` exports *nothing* rather than exporting the empty stub directory
underneath the unmounted dataset. Between CLAUDE.md's Option A and Option B, **Option B wins** —
`all_squash,anonuid=568,anongid=568` — which is also what Phase 1's 01-08 summary already
recommended on the strength of the ownership normalisation it completed.

**Primary recommendation:** Export `/mnt/tank/media/Music` from atlantis via an
`/etc/exports.d/music.exports` drop-in with
`172.16.1.31(ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys)`,
managed by a `null_resource` with `triggers` in `infra/nfs-music-export.tf`. Consume it via
Route A: `ha mounts add music --type nfs --usage media --server 172.16.1.158 --path
/mnt/tank/media/Music --read-only`, then an MA "Filesystem (local disk)" provider at
`/media/music`. Assert everything through MA's JSON-RPC `POST /api` endpoint, never the GUI.

---

## Project Constraints (from CLAUDE.md)

No `02-CONTEXT.md` exists for this phase (`gsd-sdk query init.phase-op 2` → `has_context: false`),
so there are no locked user decisions to copy verbatim. The binding constraints come from
`./CLAUDE.md`, `.planning/ROADMAP.md` and Phase 1's closure artifacts.

| # | Directive | Source | Consequence for this phase |
|---|-----------|--------|----------------------------|
| C-1 | Terraform is authoritative for host/LXC/VM resources. Keep provisioning logic in `infra/` only. Do not manually drift critical Proxmox config Terraform manages. | CLAUDE.md § Infrastructure Rules | The export MUST be defined in `infra/`. A hand-run `exportfs` is a defect, not a shortcut. |
| C-2 | Modes are `0777` everywhere on `tank` and stay that way; `chmod` fails `EPERM` even as real root under `aclmode=restricted` + `aclinherit=passthrough`. | CLAUDE.md § Constraints; 01-08-PLAN.md:14 | The export **must** be read-only. There is no mode-based way to make a writable export safe. |
| C-3 | ZFS `acltype=nfsv4` ACLs are not exported by knfsd — mode bits are the only lever NFS clients see. | CLAUDE.md § Constraints; 01-08-SUMMARY.md:479 | Clients will see `0777`. Access control is entirely `ro` + host restriction. |
| C-4 | Ownership is `568:568` (`apps:apps`) across all 2,674 entries including the library root, verified from the Proxmox host and by `zfs diff`. | CLAUDE.md § Constraints; WRIT-04 / 01-08 | `anonuid=568,anongid=568` is coherent and safe. |
| C-5 | `no_root_squash` is explicitly rejected. | CLAUDE.md § What NOT to Use | `all_squash` supersedes the question (it squashes root too). |
| C-6 | Never stage untagged content under `/media/Music`. Jellyfin already reads this tree; nothing may disturb it. | CLAUDE.md § Constraints | This phase adds a *reader*, changes no content. Blast radius must be argued, not assumed. |
| C-7 | This repo is **public**. Credentials go in `~/.claude/secrets/` by variable name only. | MEMORY.md `gateway-password-exposed-rotate` | The Music Assistant API token MUST NOT land in the repo, in `infra/terraform.tfvars`, or in a plan file. |
| C-8 | Start work through a GSD command; no direct repo edits outside a GSD workflow. | CLAUDE.md § GSD Workflow Enforcement | Execution is `/gsd-execute-phase`. |
| C-9 | The export's `anonuid`/`anongid` take the value decided in Phase 1 (WRIT-04). | ROADMAP.md Phase 2 § Depends on | Forces Option B over Option A. Not a free choice. |

**Project skills:** `.claude/skills/` and `.agents/skills/` do not exist in this repo. The relevant
skill is the global `~/.claude/skills/ha-deercrest/SKILL.md`, which supplies the HA REST/WS API
patterns, the SSH invocation, and the `bash -lc` wrapper without which the `ha` CLI returns
`unauthorized`. That skill is the mechanism for driving HAOS non-interactively.

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONS-01 | An NFSv4 export serves the Music dataset read-only from the Proxmox host, defined in Terraform, restricted to the NUC | § Export Options — Final Recommendation (the exact line, every option justified from `exports(5)`); § Terraform Representation (the `null_resource` + `triggers` pattern and what "clean re-apply" means); § Which client IP |
| CONS-02 | Music Assistant reads the library and shows albums under the correct album artist | § Route A vs Route B (decided, with the fallback pre-specified); § The `albumartist` Hard Requirement (source-level confirmation, the three fallback behaviours, and the API-observable assertion); § Empirical Decision Protocol |
| CONS-03 | Music Assistant's view survives a NUC reboot | § The Reboot Race (characterised from Supervisor source, not folklore — the emergency empty-dir bind is the actual failure mode); § Proving the Race Was Exercised |

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Serving the Music dataset over NFS | Proxmox host `atlantis` (172.16.1.158) | — | `nfsd` is privileged-only; LXC 100 is unprivileged and cannot run it. The dataset is mounted on the host; the LXC only sees a bind mount. |
| Defining and applying the export | Terraform in `infra/` (`null_resource` + `remote-exec` over SSH) | — | C-1. The repo has no config-management tier; `host.tf` already establishes remote-exec-over-SSH as the host-config mechanism. |
| Guarding against exporting an unmounted path | Kernel export layer (`mountpoint` option) | systemd ordering drop-in | Belongs at the export layer because it is evaluated per-request, not once at boot. |
| Mounting the export on the NUC | HA Supervisor (`systemd` transient `.mount` unit via D-Bus) | MA's own in-container `mount -t nfs` (Route B) | HAOS is an appliance OS; `fstab` is unavailable. Supervisor owns host mounts. |
| Exposing the mount to the add-on | Supervisor Docker bind of `/media` with `rslave` propagation | — | `rslave` is what makes a mount created *after* container start visible inside it. |
| Cataloguing and grouping the library | Music Assistant server (filesystem provider) | — | MA is the system of record for its own library; nothing else can assert "under the correct album artist". |
| Asserting the success criteria | Workstation-resident `scripts/check-music-consumers.sh` calling MA `POST /api` and `ha mounts info` | — | Matches the estate's established audit-script convention (`scripts/check-music-freeze.sh`). |
| Reading the same tree for video/music playback | Jellyfin in LXC 100 (unchanged) | — | Existing consumer. This phase must not touch it. |

---

## Headline Findings

### 1. The Route A / Route B "conflict" is not a conflict — both statements are true

The two primary sources say different things about different operations.

**Music Assistant's documentation says** — verbatim, from
[`music-assistant.io/src/content/docs/music-providers/local-files.md`](https://raw.githubusercontent.com/music-assistant/music-assistant.io/main/src/content/docs/music-providers/local-files.md):

> On Home Assistant OS only the /media folder can be accessed, and it is not possible to mount a
> folder from Home Assistant into that path. Docker users can mount their own folder paths.

**HA Supervisor's source says** the mounts API accepts only two types, and `bind` is not one of them
— `supervisor/mounts/validate.py`:

```python
_SCHEMA_BASE_MOUNT_CONFIG = vol.Schema(
    {
        vol.Required(ATTR_NAME): VALIDATE_NAME,
        vol.Required(ATTR_TYPE): vol.All(
            vol.In([MountType.CIFS.value, MountType.NFS.value]), vol.Coerce(MountType)
        ),
        vol.Required(ATTR_USAGE): vol.Coerce(MountUsage),
        vol.Optional(ATTR_READ_ONLY, default=False): vol.Boolean(),
    },
    extra=vol.REMOVE_EXTRA,
)
```

`MountType.BIND` exists in `supervisor/mounts/const.py` but is used only internally, and
`BindMount.__init__` raises `ValueError("Path must be within Supervisor's data directory!")` for
anything outside Supervisor's own tree.

**Reading:** MA's sentence is about mounting a *local folder* (a bind) into `/media`. That is
genuinely impossible. It is not a statement about network shares. `[VERIFIED: upstream source,
supervisor/mounts/validate.py + supervisor/mounts/mount.py]` **Confidence: HIGH.**

And Supervisor's network-share path lands exactly where MA needs it — `supervisor/mounts/mount.py`,
`Mount.container_where`:

```python
match self.usage:
    case MountUsage.MEDIA:
        return PurePath(PATH_MEDIA, self.name)      # PATH_MEDIA = PurePath("/media")
    case MountUsage.SHARE:
        return PurePath(PATH_SHARE, self.name)
    case MountUsage.BACKUP | None:
        return None
```

and `supervisor/mounts/manager.py::_bind_media()` bind-mounts the live NFS mount to
`path_extern_media / mount.name`, i.e. `/media/<name>`.

**The load-bearing detail nobody documents:** the add-on's `/media` bind carries `rslave`
propagation — `supervisor/docker/app.py:568-577` (note: `docker/addon.py` was renamed to
`docker/app.py` upstream, consistent with `ha addons` → `ha apps`):

```python
if MappingType.MEDIA in app_mapping:
    mounts.append(
        DockerMount(
            type=MountType.BIND,
            source=self.sys_config.path_extern_media.as_posix(),
            target=app_mapping[MappingType.MEDIA].path or PATH_MEDIA.as_posix(),
            read_only=app_mapping[MappingType.MEDIA].read_only,
            bind_options=MountBindOptions(propagation=PropagationMode.RSLAVE),
        )
    )
```

Without `rslave`, a mount created under `/media` *after* the container started would be invisible
inside it — which is precisely the shape of bug that would have produced MA's doc sentence. With
`rslave`, it propagates. `[VERIFIED: upstream source]` **Confidence: HIGH.**

**Corroboration from the MA side:** in
[music-assistant/discussions/1198](https://github.com/orgs/music-assistant/discussions/1198),
maintainer @OzGav describes the pre-native-NFS workaround as: *"You can make the NFS Mount in HA at
Settings Storage and then add network storage… If it is created you can add it in MA as being Local
Disk."* `[CITED: github.com/orgs/music-assistant/discussions/1198]` **Confidence: MEDIUM-HIGH**
(maintainer statement, but a discussion thread rather than docs).

**Conditions under which each statement holds:**

| Operation | Supported? | Evidence |
|-----------|-----------|----------|
| Mount a **local host folder** into `/media` via HA Settings → Storage | **No** | `validate.py` accepts only `cifs`/`nfs`; `BindMount` is internal-only. This is what MA's doc means. |
| Mount an **NFS/CIFS network share** with `usage: media` → appears at `/media/<name>` | **Yes** | `container_where`, `_bind_media`, `PATH_MEDIA`. |
| That mount visible inside the MA add-on container | **Yes** | `map: [media:rw]` in add-on `config.yaml` + `rslave` propagation in `docker/app.py`. |
| MA mounting the NFS share itself, in-container | **Yes** | `filesystem_nfs/provider.py` shells out to `mount -t nfs`; base image installs `nfs-common`; AppArmor profile permits `mount`. |

### 2. "Music Assistant never purges stale entries" is **false** — and the real reason for the three-album gate is better

`music_assistant/providers/filesystem_local/__init__.py` at tag **2.9.13** (the installed add-on
version), `sync_library()`:

```python
# do not run deletions on a clean but empty scan of a previously non-empty library
# (wrong share mounted, empty backup mount, ...)
if prev_filenames and not cur_filenames:
    self.logger.error(
        "Aborting sync for %s: scan found no files but %d were previously indexed", ...
    )
    report_current_task_failure(...)
    return

deleted_files = prev_filenames - cur_filenames
await self._process_deletions(deleted_files)
await self._process_orphaned_albums_and_artists()
```

`_process_deletions()` removes tracks/playlists whose relative path disappeared, then removes albums
with no remaining tracks and artists with no remaining albums or tracks.
`_process_orphaned_albums_and_artists()` sweeps the same, scoped to
`provider_instance = '<this instance>'`. `[VERIFIED: upstream source at tag 2.9.13, lines 445-475
and 544-618]` **Confidence: HIGH.** Present identically on `dev` (2.10.x) with an additional
`scan_errors.incomplete` guard.

**So why keep the three-album gate?** Because of how album identity is constructed. In the same
file, an album's provider item id is:

```python
item_id = album_artists[0].name + os.sep + track_tags.album
```

An album ingested with the wrong album artist gets a *durable, differently-keyed* library entry. It
does self-heal on a later sync (old album loses all tracks → orphan sweep removes it), but the
interval between "wrong" and "healed" is one sync cycle, which defaults to **12 hours**, and any
favourites, play counts or playlist references attached to the wrong entry are lost when it is
purged. Discovering that pattern on 34 GB rather than three albums is the expensive version of the
same lesson. **The gate stands; the justification in ROADMAP.md should be rewritten.**

### 3. The reboot race is an *empty directory*, not a missing one — and it is guarded on both sides

`supervisor/core.py::setup()` executes its load list **sequentially** (`for setup_task in
setup_loads:`), with `self.sys_mounts.load()` at position 6 and `self.sys_apps.load()` at
position 11. Add-ons are not *started* until `Core.start()`, later still. So Supervisor never starts
Music Assistant before attempting the mount. `[VERIFIED: upstream source, supervisor/core.py:146-189
and 212-295]` **Confidence: HIGH.** This contradicts the common community framing ("the add-on comes
up before the mount") — see § Where Sources Conflict.

What actually happens when the mount fails — `supervisor/mounts/manager.py::_bind_mount()`:

```python
emergency = mount.state != UnitActiveState.ACTIVE
if not emergency:
    path = mount.where
else:
    _LOGGER.warning("Mount %s failed to mount, mounting read-only fallback for %s", ...)
    path = self.sys_config.path_emergency / mount.name

    def emergency_mkdir():
        if not path.exists():
            path.mkdir(mode=0o444)
    ...
self._bound_mounts[mount.name] = bound_mount = BoundMount(
    mount=mount,
    bind_mount=BindMount.create(..., path=path, where=where, read_only=emergency),
    emergency=emergency,
)
```

**`/media/music` therefore exists and is empty**, mode `0444`, read-only. MA's local provider checks
`if not await isdir(self.base_path): raise "Music Directory ... does not exist"` — the directory
*does* exist, so the provider loads normally, then scans zero files. The empty-scan guard in
finding 2 then aborts deletions and the library survives, marked stale. `[VERIFIED: upstream source]`
**Confidence: HIGH.**

Timing budget on the Supervisor side, from the comment block in `supervisor/mounts/mount.py`:

```
NFS RPC timeout (timeo=100,retrans=2) ~30 s
  < systemd unit TimeoutSec (MOUNT_UNIT_TIMEOUT_USEC)  35 s
  < supervisor state-await (UPDATE_STATE_TIMEOUT)      40 s
```

Recovery is automatic: `supervisor/misc/tasks.py` registers `self.sys_mounts.reload` on
`RUN_RELOAD_MOUNTS = 900` — **every 15 minutes** — and `Mount.reload()` escalates reload → restart
when the `statvfs` liveness probe fails. `[VERIFIED: upstream source]` **Confidence: HIGH.**

---

## Route A vs Route B — Decision

### Route A (RECOMMENDED): HAOS network storage → `/media/music` → MA "Filesystem (local disk)"

**Why it wins:**

1. One mount, owned by Supervisor, with a supported UI/CLI/API surface (`ha mounts`, `POST /mounts`).
2. Supervisor retries it every 900 s automatically; Route B's provider raises `SetupFailedError` on
   a mount failure and its retry cadence is provider-reload, not a timer.
3. `read_only: true` is enforced at the client kernel mount (`Mount.options` → `["ro"]`) *and* at the
   export. Route B gives no `ro` option at all — see the defect below.
4. It survives an MA add-on reinstall/upgrade without reconfiguration; the mount is Supervisor state,
   not provider state.
5. The failure mode is benign and well-characterised (§ finding 3).

**Configuration (fully non-interactive):**

```bash
# From the workstation, via the ha-deercrest skill's SSH pattern.
source ~/.claude/secrets/ha-deercrest.env
SSH="ssh -i $HA_SSH_KEY -o StrictHostKeyChecking=no -o BatchMode=yes -p $HA_SSH_PORT $HA_SSH_USER@$HA_SSH_HOST"

$SSH "bash -lc 'ha mounts add music \
  --type nfs \
  --usage media \
  --server 172.16.1.158 \
  --path /mnt/tank/media/Music \
  --read-only'"

$SSH "bash -lc 'ha mounts info --raw-json'"
```

`bash -lc` is mandatory — a non-login shell lacks `SUPERVISOR_TOKEN` and the CLI returns
`unauthorized`; a PTY is not enough (`~/.claude/skills/ha-deercrest/SKILL.md`).

**Two schema traps, both from `supervisor/mounts/validate.py`:**

| Trap | Rule | Consequence |
|------|------|-------------|
| Mount name charset | `RE_MOUNT_NAME = re.compile(r"^[A-Za-z0-9_]+$")` | **No hyphens.** `music` or `tank_music`; `tank-music` is rejected. |
| Target must be empty | `Mount.mount()` → `ensure_empty_folder()` raises `MountTargetNotEmptyError` if `/media/music` already has content | If anything ever wrote into `/media/music`, the mount silently fails into the emergency path. Recover with `ha mounts reload music` or Supervisor's `relocate_local_data`. |

`[VERIFIED: upstream source]` **Confidence: HIGH.**

**MA provider config (Route A):** provider domain `filesystem_local`, config key `path` set to
`/media/music`. From `filesystem_local/__init__.py::setup()`:
`base_path = cast("str", config.get_value(CONF_PATH))` — an arbitrary absolute path, default
`/media`. `[VERIFIED: upstream source at 2.9.13]`

**Route A failure symptom to assert on (so the plan can branch deterministically):**

| Observable | Location | PASS | FAIL |
|-----------|----------|------|------|
| `ha mounts info --raw-json` → `.data.mounts[] \| select(.name=="music") \| .state` | HAOS SSH | `active` | `failed` / `inactive` |
| Same object, `.user_path` | HAOS SSH | `/media/music` | absent |
| `mount \| grep ' /mnt/data/supervisor/media/music '` | HAOS SSH | source is `172.16.1.158:/mnt/tank/media/Music` | source contains `/emergency/` → **emergency bind, Route A has failed** |
| `ls /media/music` inside the MA container | MA add-on | artist folders | empty |
| Supervisor log | `ha supervisor logs` | — | `Mount music failed to mount, mounting read-only fallback for /media/music` |

That log line is the exact, greppable Route-A-failed signal. `[VERIFIED: upstream source,
supervisor/mounts/manager.py]`

### Route B (PRE-SPECIFIED FALLBACK): MA "Filesystem (NFS share)" provider

Real, stable, and shipped in the installed version — `filesystem_nfs/manifest.json` at tag 2.9.13
declares `"stage": "stable"`, `"name": "Filesystem (NFS share)"`. Introduced in **2.8.0b20**
(maintainer @OzGav, discussion #1198). `[VERIFIED: upstream source + CITED: discussion #1198]`

**Exact provider config** — keys from `filesystem_nfs/constants.py` and `__init__.py`:

| Key | Value | Notes |
|-----|-------|-------|
| `host` | `172.16.1.158` | Validated by `get_ip_from_host()`; an IP short-circuits DNS. **This is why the IP is mandatory** — HAOS has no guaranteed resolver, and an unresolvable host raises `SetupFailedError`. |
| `export_path` | `/mnt/tank/media/Music` | Must start with `/` and pass `is_safe_path()`. |
| `subfolder` | *(empty)* | Only needed if music lives below the export root. It does not. |
| `nfs_version` | `""` (Auto) — set `4.2` only if Auto misbehaves | Options are `""`, `3`, `4`, `4.1`, `4.2`. |
| `content_type` | `music` | Set in the setup flow; read-only afterwards. |
| `missing_album_artist_action` | `various_artists` (default) — see § albumartist | Options: `track_artist`, `various_artists`, `folder_name`. |

**Where the NFS options go — you do not choose them.** `NFSFileSystemProvider._get_mount_options()`
hardcodes them:

```python
if platform.system() == "Darwin":
    options = ["resvport", "noatime", "soft", "timeo=30", "retrans=5"]
else:
    options = ["noatime", "nolock", "tcp", "soft", "timeo=30", "retrans=5"]
nfs_version = str(self.get_setup_value(CONF_NFS_VERSION) or "")
if nfs_version:
    options.append(f"vers={nfs_version}")
```

**There is no `ro` in that list, and no way to add one.** Under Route B the export's server-side `ro`
is the *only* thing preventing MA from writing into the library — which is precisely the guarantee
CLAUDE.md C-2 requires. That is a strong argument for `ro` at the server regardless of route, and a
mild argument against Route B. `[VERIFIED: upstream source]` **Confidence: HIGH.**

The mount point is `/tmp/{instance_id}`, created in `setup()`. The add-on sets `tmpfs: true`, so
`/tmp` is a tmpfs; mounting NFS over a subdirectory of tmpfs is fine.

**What `SYS_ADMIN` / `DAC_READ_SEARCH` buy** — `music_assistant/config.yaml`:

```yaml
privileged:
  - SYS_ADMIN
  - DAC_READ_SEARCH
apparmor: true
```

`CAP_SYS_ADMIN` is the capability the `mount(2)` syscall requires. `CAP_DAC_READ_SEARCH` bypasses
file read/directory-search permission checks, which matters when the squashed identity does not
match on-disk ownership. Capabilities alone are not sufficient under an AppArmor profile, and the
add-on's profile grants the matching rules explicitly —
`music_assistant/apparmor.txt`:

```
profile music_assistant_addon flags=(attach_disconnected,mediate_deleted) {
  capability,
  file,
  signal,
  mount,
  umount,
  remount,
  ...
  capability sys_admin,
  capability dac_read_search,
  ...
  /media/** rw,
}
```

`[VERIFIED: upstream source, music-assistant/home-assistant-addon@main]` **Confidence: HIGH.**

**The stale community claim that Route B cannot work is wrong.** `Dockerfile.base` at tag 2.9.13
installs, with a comment naming the reason:

```dockerfile
# cifs utils and libnfs are needed for smb and nfs support (file provider)
cifs-utils \
libnfs13 \
nfs-common \
```

`nfs-common` provides `/sbin/mount.nfs`. `[VERIFIED: upstream source]` **Confidence: HIGH.**

**Route B failure symptoms:** `SetupFailedError` surfaced in the MA UI and in `config/providers`
(`last_error`), with translation keys `host_unresolvable`, `mount_failed`, `subfolder_not_found`, or
`invalid_subfolder`. Provider `available: false`. Diagnostics expose
`{"mounted": <bool>}` via `get_diagnostics()`.

### Alternatives rejected

| Instead of | Could Use | Why rejected |
|------------|-----------|--------------|
| NFS | SMB/CIFS to HAOS | Would need a Samba server on atlantis (more surface, more state), and MA docs record a kernel limitation: emoji/special characters in names are skipped on CIFS. NFS has no such limit. |
| NFS | WebDAV | MA docs: *"Writing to the WebDAV server is not supported… Library sync will be slower than local or SMB."* Wrong tool. |
| Route A / B | MA reads Jellyfin as a provider (`filesystem`-free) | Makes Jellyfin's catalogue the source of truth for MA, which defeats CONS-04's independent double-check. Explicitly not what the requirement asks for. |
| Export from atlantis | Export from LXC 100 | LXC 100 is unprivileged; `nfsd` requires privilege. Non-starter, already recorded in the ROADMAP. |
| Terraform-managed `/etc/exports.d` | `zfs set sharenfs=...` | See § Terraform Representation. |

---

## Empirical Decision Protocol

Runnable end to end. Every step names its PASS observable and its FAIL symptom. GUI is required in
exactly one place, flagged inline.

### Stage 0 — Preconditions (Proxmox host, `ssh root@172.16.1.158`)

```bash
# 0.1 Is the dataset actually mounted and is it its own dataset?
zfs list -o name,mountpoint,mounted tank/media/Music
mountpoint -q /mnt/tank/media/Music && echo "PASS: is a mountpoint" || echo "FAIL: not a mountpoint"

# 0.2 Are there child datasets under Music? (decides whether crossmnt matters)
zfs list -r -o name,mountpoint tank/media/Music

# 0.3 Ownership + modes, as inherited from Phase 1
stat -c '%U:%G %a %n' /mnt/tank/media/Music
find /mnt/tank/media/Music -maxdepth 1 ! -uid 568 -o -maxdepth 1 ! -gid 568 | head

# 0.4 Is anything already exported? Is sharenfs set anywhere on tank?
cat /etc/exports 2>/dev/null; ls -la /etc/exports.d/ 2>/dev/null
zfs get -r -s local,received sharenfs tank | grep -v '\boff\b'

# 0.5 Is the server package present?
dpkg -l nfs-kernel-server 2>/dev/null | grep '^ii' || echo "NOT INSTALLED (expected)"
```

PASS for 0.1: `mounted` is `yes` and `mountpoint -q` succeeds — required for the `mountpoint` export
option. FAIL: anything else halts the phase; do not export an unmounted path.
PASS for 0.4: empty. If `sharenfs` is set anywhere on `tank`, **stop** and reconcile — mixing ZFS
share management with `/etc/exports.d` is the documented way to get a silently wrong export table.

### Stage 1 — Create the export (Terraform, from the workstation)

```bash
cd infra
terraform plan     # expect: 1 to add (null_resource.nfs_music_export)
terraform apply
terraform plan     # expect: "No changes. Your infrastructure matches the configuration."
```

The **second** `terraform plan` returning `No changes` is CONS-01's "a re-apply is clean". FAIL:
any diff on the second plan means the `triggers` map is derived from something non-deterministic.

### Stage 2 — Verify the export on the server

```bash
ssh root@172.16.1.158 '
  systemctl is-active nfs-server
  exportfs -v
  showmount -e localhost
'
```

PASS: `exportfs -v` shows

```
/mnt/tank/media/Music
		172.16.1.31(ro,sync,wdelay,hide,no_subtree_check,mountpoint,sec=sys,ro,secure,root_squash,all_squash)
```

The `ro` and `all_squash` tokens and the single-host restriction are the three things to assert on.
FAIL: `no_root_squash` present, `rw` present, or the client shown as `*` or a subnet.

### Stage 3 — Route A: mount from the NUC

```bash
source ~/.claude/secrets/ha-deercrest.env
SSH="ssh -i $HA_SSH_KEY -o StrictHostKeyChecking=no -o BatchMode=yes -p $HA_SSH_PORT $HA_SSH_USER@$HA_SSH_HOST"

$SSH "bash -lc 'ha mounts add music --type nfs --usage media \
  --server 172.16.1.158 --path /mnt/tank/media/Music --read-only'"

$SSH "bash -lc 'ha mounts info --raw-json'" | jq '.data.mounts[] | select(.name=="music")'
```

PASS: `.state == "active"`, `.read_only == true`, `.user_path == "/media/music"`.
FAIL: `.state` is `failed`/`inactive`, **or** the Supervisor log carries
`Mount music failed to mount, mounting read-only fallback` → **abandon Route A, go to Stage 3B.**

Confirm the mount is real, not the emergency stub:

```bash
$SSH "mount | grep -E ' /mnt/data/supervisor/(media/music|emergency/music) '"
```

PASS: source is `172.16.1.158:/mnt/tank/media/Music`. FAIL: source contains `/emergency/`.

### Stage 4 — CONS-01 criterion 2: prove read-only is enforced at the export

Two independent attempts, because a client-side `ro` and a server-side `ro` are different claims and
only the second is the requirement.

```bash
# 4a. Through the Supervisor mount (proves the client mount is ro):
$SSH "sudo touch /mnt/data/supervisor/media/music/_ro_probe_$$ 2>&1; echo exit=\$?"
# PASS: "Read-only file system", exit non-zero.

# 4b. Bypass the client ro, to prove the SERVER refuses. Mount rw by hand from the NUC:
$SSH "sudo mkdir -p /tmp/ro_probe && sudo mount -t nfs -o rw 172.16.1.158:/mnt/tank/media/Music /tmp/ro_probe \
      && sudo touch /tmp/ro_probe/_ro_probe_$$ 2>&1; echo exit=\$?; sudo umount /tmp/ro_probe"
# PASS: touch fails "Read-only file system" DESPITE -o rw. That is the export enforcing it.
# FAIL: the file is created -> the export is rw and CONS-01 is not met.
```

4b is the criterion. 4a alone would pass on a `rw` export and is therefore not sufficient evidence.
Clean up any probe file that does land, and record the fact as a failure.

### Stage 5 — Configure the MA provider

**This is the one unavoidable GUI step, and only for the *first* configuration.** MA provider setup
runs through a config *flow* (`config/providers/setup` → `config/flows/submit`), and the flow's
intermediate step ids are not documented outside the running server.

Click path (MA UI, reachable at `http://172.16.1.31:8095` or through the HA sidebar panel):
**Settings → Music Providers → `+` Add Music Provider → "Filesystem (local disk)"** →
set **Content type** = `Music`, **Path** = `/media/music` → **Save**.

Then open the new provider's settings and set **"Action when a track is missing the Albumartist ID3
tag"** to a value chosen deliberately (see § albumartist for why the default is a trap).

Alternative, if the executor wants it scripted: the flow *is* API-driven, and the step ids can be
discovered live rather than guessed —

```bash
# Discover the exact command + argument schema from the running server (unauthenticated route):
curl -s http://172.16.1.31:8095/api-docs/commands.json | jq '.[] | select(.command|startswith("config/providers"))'
curl -s http://172.16.1.31:8095/api-docs/openapi.json | jq '.paths | keys'
```

`/api-docs/` is in `auth_middleware.py`'s `unauthenticated_paths`, so this works without a token.
`[VERIFIED: upstream source]` The plan should run this discovery step *first* and only fall back to
the GUI if the flow cannot be driven headlessly.

### Stage 6 — Trigger a sync and assert on album artist (CONS-02)

Get a token once (store it in `~/.claude/secrets/ma-deercrest.env`, **never** in the repo — C-7):

```bash
MA=http://172.16.1.31:8095
# auth/login is declared authenticated=False in music_assistant/controllers/webserver/auth.py
TOK=$(curl -s -X POST $MA/api -H 'Content-Type: application/json' \
  -d '{"command":"auth/login","args":{"username":"'"$MA_USER"'","password":"'"$MA_PASS"'"}}' | jq -r '.result.token')
# then mint a long-lived one (365 days):
LLT=$(curl -s -X POST $MA/api -H 'Content-Type: application/json' -H "Authorization: Bearer $TOK" \
  -d '{"command":"auth/token/create","args":{"name":"gsd-phase-2"}}' | jq -r '.result')
```

Then:

```bash
api() { curl -s -X POST $MA/api -H 'Content-Type: application/json' -H "Authorization: Bearer $LLT" \
        -d "{\"command\":\"$1\",\"args\":${2:-\{\}}}"; }

# 6.1 Find the provider instance id
api config/providers | jq '.result[] | {domain, instance_id, available, last_error}'

# 6.2 Force a sync of just this provider (do not wait 12 hours)
api music/sync '{"providers":["<instance_id>"],"media_types":["track"]}'

# 6.3 Watch it finish
api music/albums/count '{"provider_filter":["<instance_id>"]}'

# 6.4 THE ASSERTION: the three albums, under the right album artist
api music/albums/library_items '{"search":"<Album Name>","provider_filter":["<instance_id>"],"limit":5}' \
  | jq '.result[] | {name, artists: [.artists[].name], uri}'
```

PASS for CONS-02: for each of the three albums, `.artists[0].name` equals the album artist tagged in
the files. FAIL: it is `Various Artists`, or the folder name, or the track artist — each of which
identifies *which* fallback fired (§ albumartist).

Cross-check the artist side:

```bash
api music/artists/library_items '{"search":"<Album Artist>","provider_filter":["<instance_id>"],"limit":5}' \
  | jq '.result[] | {name, uri}'
```

Command names confirmed from `controllers/music/media/base.py:195-232` (`music/{media_type}s/count`,
`.../library_items`, `.../get`) and `controllers/music/controller.py:373`
(`@api_command("music/sync")` → `start_sync(media_types, providers)`). `[VERIFIED: upstream source]`

### Stage 7 — CONS-03: reboot

```bash
$SSH "bash -lc 'ha host reboot'"
# wait for the NUC to come back, then, with NO manual intervention:
$SSH "bash -lc 'ha mounts info --raw-json'" | jq '.data.mounts[] | select(.name=="music") | .state'
api music/albums/library_items '{"search":"<Album Name>","provider_filter":["<id>"],"limit":5}' \
  | jq '.result[] | {name, artists: [.artists[].name]}'
```

PASS: state `active`, all three albums still present with the right artist. See § Proving the Race
Was Exercised — a clean pass here is necessary but **not sufficient**.

### Stage 3B — Route B fallback (only if Stage 3 or Stage 4 fails on the Route A side)

Remove the Supervisor mount first so `/media/music` cannot confuse the picture:

```bash
$SSH "bash -lc 'ha mounts delete music'"
```

Then add the MA provider **Filesystem (NFS share)** with `host=172.16.1.158`,
`export_path=/mnt/tank/media/Music`, `subfolder=` empty, `nfs_version=` Auto, `content_type=music`.
Resume at Stage 6 unchanged — everything from Stage 6 on is route-independent.

If Route B *also* fails with `mount_failed`, capture the error before escalating:

```bash
# The provider records the raw mount error; MA also exposes it via diagnostics.
api config/providers | jq '.result[] | select(.domain=="filesystem_nfs") | .last_error'
# And on the server side, watch what the client actually asked for:
ssh root@172.16.1.158 'journalctl -u nfs-server -n 50 --no-pager; rpcdebug -m nfsd -s all'
```

---

## The Reboot Race (Success Criterion 4)

### What actually goes wrong

Not "MA starts before the mount" — Supervisor mounts first, sequentially, in `Core.setup()`. The
real sequence when the server is unreachable inside the ≤40 s window:

1. `sys_mounts.load()` → `Mount.load()` → `mount()` → transient systemd unit fails (or times out at
   `MOUNT_UNIT_TIMEOUT_USEC = 35 s`).
2. `MountManager._bind_media()` → `_bind_mount()` sees `mount.state != ACTIVE` → **emergency path**:
   creates `/mnt/data/supervisor/emergency/music` mode `0444` and bind-mounts *that* read-only onto
   `/media/music`.
3. A `MOUNT_FAILED` resolution issue is raised (visible in HA → Settings → System → Repairs).
4. `Core.start()` boots add-ons. MA's local provider finds `/media/music` — it exists, it is a
   directory — so `handle_async_init()` succeeds and the provider loads normally.
5. `INITIAL_SYNC_DELAY = 10` seconds later, the first sync runs and scans **zero** files.
6. `if prev_filenames and not cur_filenames:` fires. Deletions abort. The library is *preserved but
   stale*: entries exist, playback of any of them fails.
7. Every 900 s, `sys_mounts.reload()` retries. On success the mount comes back and the emergency bind
   is replaced.
8. The library only self-corrects on the **next sync** — up to `DEFAULT_SYNC_INTERVAL = 12 * 60`
   minutes away — unless a sync is triggered.

`[VERIFIED: upstream source — supervisor/core.py, supervisor/mounts/manager.py,
supervisor/misc/tasks.py, music_assistant/providers/filesystem_local/__init__.py,
music_assistant/controllers/music/constants.py]` **Confidence: HIGH.**

### Mitigations, ranked

| # | Mitigation | Where | Effect | Confidence |
|---|-----------|-------|--------|-----------|
| M1 | `mountpoint` on the export | atlantis `/etc/exports.d/music.exports` | Removes the *server-side* half entirely: a host reboot that starts `nfs-server` before `zfs-mount` exports nothing rather than an empty stub, so the NUC gets a clean `access denied`, not a silently empty tree. | HIGH — `exports(5)` |
| M2 | `After=zfs-mount.service` drop-in for `nfs-server.service` | atlantis | Removes the ordering window that M1 guards. Belt and braces; M1 alone is sufficient for correctness, M2 makes it not *happen*. | MEDIUM — ZFS mounts are not systemd `.mount` units, so `RequiresMountsFor=` will not resolve; use `After=`/`Wants=`. |
| M3 | Do nothing further; rely on Supervisor's 900 s reload | NUC | The mount self-heals within 15 min. This is upstream's designed behaviour. | HIGH |
| M4 | Add a HA automation on `homeassistant_started` that waits 120 s then calls the MA sync | NUC | Collapses step 8 from ≤12 h to ~2 min. Costs one automation to maintain. | MEDIUM — MA does not currently expose a `sync` service in the HA integration; the automation would have to `rest_command` MA's `POST /api`. **Verify before planning it.** |
| M5 | Shorten MA's `sync_interval` from 12 h | MA core config | Blunt. Increases scan load on a 34 GB tree for a rare event. | Not recommended |
| — | **Rejected:** `nofail`/`bg` mount options from community advice | — | Supervisor builds the option list itself (`NFSMount.options` returns `super().options + ["softerr","timeo=100","retrans=2"]`); there is no user-supplied options field in the mounts API schema. The advice applies to hand-rolled `mount` commands, not to HAOS. | HIGH |
| — | **Rejected:** `startup:` stage in the MA add-on config | — | Not settable by us — it is upstream's `config.yaml`, and it has no `startup:` key so it defaults to `application` (the last stage). More importantly, add-on stage is irrelevant because mounts complete in `setup()` before *any* stage boots. | HIGH |

**Recommendation: M1 + M2 + M3.** M1 is free and closes the only failure mode that can silently
corrupt state. M4 is a nice-to-have; if the plan includes it, gate it behind verifying that a
`rest_command` to MA works.

### Proving the race was exercised, not merely absent

A NUC reboot with atlantis healthy **does not exercise the race at all** — the mount will simply
succeed. Criterion 4 as written can therefore pass by luck and prove nothing. The plan must include
a deliberate negative control:

```bash
# 1. Stop the server so the NUC cannot mount.
ssh root@172.16.1.158 'systemctl stop nfs-server'

# 2. Reboot the NUC.
$SSH "bash -lc 'ha host reboot'"

# 3. After it returns, capture the evidence the race DID fire:
$SSH "bash -lc 'ha mounts info --raw-json'" | jq '.data.mounts[] | select(.name=="music") | .state'
#    expect: "failed" or "inactive"
$SSH "mount | grep emergency/music"
#    expect: a match  <- THIS is the proof the emergency path ran
$SSH "bash -lc 'ha supervisor logs'" | grep -i 'failed to mount, mounting read-only fallback'
#    expect: a match

# 4. Confirm MA did NOT purge:
api music/albums/count '{"provider_filter":["<id>"]}'
#    expect: unchanged from before the reboot
#    and in the MA log: "Aborting sync for <name>: scan found no files but N were previously indexed"

# 5. Restore and confirm recovery WITHOUT touching the NUC:
ssh root@172.16.1.158 'systemctl start nfs-server'
sleep 900   # Supervisor's RUN_RELOAD_MOUNTS
$SSH "bash -lc 'ha mounts info --raw-json'" | jq '... .state'   # expect "active"
# then force a sync and re-assert the three albums.
```

**Evidence that the race was exercised:** the presence of `emergency/music` in `mount` output AND
the `mounting read-only fallback` log line AND MA's `Aborting sync … scan found no files` line. All
three, or the negative control did not fire and step 3 tested nothing.

**Evidence that criterion 4 passes:** the *positive* reboot (Stage 7, server healthy) shows
`state: active` and three albums present, **and** the negative control above shows the system
degrades safely and recovers unattended.

### Where sources conflict — stated, not silently resolved

Community threads (e.g.
[community.home-assistant.io/t/nfs-after-reboot-when-server-is-down/894095](https://community.home-assistant.io/t/nfs-after-reboot-when-server-is-down/894095))
report that a failed media mount *"never recovers until HA is rebooted again"* and that `media`-type
mounts behave differently from `backup`-type mounts across reboots. **The current Supervisor source
contradicts the first claim outright** — `tasks.py` registers `sys_mounts.reload` on a 900 s
schedule, and `Mount.reload()` escalates to `RestartUnit`. The second claim has a plausible
explanation in source (`backup` mounts have no `container_where` and therefore no bind-into-`/media`
step, so they cannot land in the emergency path), which would make it a real historical difference
rather than a myth.

**Resolution:** treat the community reports as describing an **older Supervisor**. Do not design
around them, but *do* run the negative control above — it is the only thing that settles it on this
estate, at this version. `[Sources conflict — flagged, not resolved from documentation alone]`

---

## The `albumartist` Hard Requirement (Success Criterion 3)

### It is a hard requirement, with a configurable fallback — not a skip

MA's documentation, verbatim:

> MA requires the Album Artist tag to be set. If that tag is not set then what happens to those
> tracks when the provider is scanned depends on the `Action when a track is missing the Albumartist
> ID3 tag` setting for the local provider.

and, on the setting itself:

> MA needs an album artist defined so that the item can be added correctly to the database. Instead
> of skipping tracks that do not have this information, this setting defines how the situation
> should be handled. By default, `Various Artists` will be used but the other options available are
> `Track Artist` and `Folder name (if possible)`.

`[CITED: music-assistant.io/music-providers/local-files/]`

Confirmed in source — `filesystem_local/constants.py`:

```python
CONF_MISSING_ALBUM_ARTIST_ACTION = "missing_album_artist_action"

CONF_ENTRY_MISSING_ALBUM_ARTIST = ConfigEntry(
    key=CONF_MISSING_ALBUM_ARTIST_ACTION,
    type=ConfigEntryType.STRING,
    default_value="various_artists",
    options=[
        ConfigValueOption("track_artist"),
        ConfigValueOption("various_artists"),
        ConfigValueOption("folder_name"),
    ],
    depends_on=CONF_CONTENT_TYPE,
    depends_on_value="music",
)
```

`[VERIFIED: upstream source]` **Confidence: HIGH.**

**Why the default is a trap for this project.** `various_artists` means a missing `albumartist`
produces a *plausible-looking* library entry rather than a visible failure. Given this library is
heavy on DJ compilations that legitimately *are* Various Artists, the default makes the two cases
indistinguishable. **Recommendation: set `folder_name` for the pilot**, because CONF-03 already
mandates that the path's top level *is* the album artist — so `folder_name` and a correct
`albumartist` tag agree when the tag is present and disagree loudly when it is not. Record the
choice as a decision. `[ASSUMED — reasoned, needs user confirmation]`

**Album identity is derived from it.** `filesystem_local/__init__.py`:

```python
item_id = album_artists[0].name + os.sep + track_tags.album
```

So the album artist is not cosmetic; it is half the primary key. This is the mechanism behind the
"prove it on three albums first" gate.

**Multi-artist parsing (relevant to CONF-04's `;` delimiter):** MA's documented order is
(1) `ARTISTS` tag for ID3v2.3/MP4, (2) multiple `ARTIST` Vorbis fields for FLAC/OGG/Opus,
(3) null-separated values for ID3v2.4/APEv2, (4) fall back to parsing the `ARTIST` string with `;`
as primary separator. *"The album artist tag is parsed the same way as ARTIST."*
`[CITED: music-assistant.io/music-providers/local-files/]` — this corroborates CONF-04.

### Observable via the API, not the UI

```bash
api music/albums/library_items '{"search":"<Album>","provider_filter":["<id>"],"limit":5}' \
  | jq '.result[] | {name, album_artists: [.artists[].name]}'
```

`music/albums/library_items` is registered in `controllers/music/media/base.py:198-203` with
`required_scope=Scope.LIBRARY_READ`. `[VERIFIED: upstream source]`

### How long is "one sync cycle", and can it be forced?

| Question | Answer | Source |
|----------|--------|--------|
| Scheduled interval | **12 hours** (`DEFAULT_SYNC_INTERVAL = 12 * 60` minutes), overridable via the core config key `sync_interval` | `controllers/music/constants.py` |
| First sync after a provider loads | **10 seconds** (`INITIAL_SYNC_DELAY = 10`) | `controllers/music/constants.py` |
| On-demand trigger | **Yes** — `music/sync` with optional `media_types` and `providers` filters | `controllers/music/controller.py:373` |
| Concurrency guard | `if self.sync_running: logger.warning("Library sync already running"); return` | `filesystem_local/__init__.py` |

So criterion 3's "within one sync cycle" is satisfiable in seconds via `music/sync`, and the plan
should use that rather than waiting. `[VERIFIED: upstream source]` **Confidence: HIGH.**

---

## Stale-Entry Purge and the Cost of a Full Reset

### MA does purge — with three guards

| Guard | Condition | Behaviour | Version |
|-------|-----------|-----------|---------|
| Empty-scan | `prev_filenames and not cur_filenames` | Log `Aborting sync … scan found no files but N were previously indexed`, report task failure, **return before any deletion** | 2.9.13 and dev |
| Root-scan error | `root_scan_errors` non-empty | Log `Aborting sync … root scan error(s)`, `_set_available(False)`, return | 2.9.13 |
| Incomplete scan | `scan_errors.incomplete` | Log `Skipping deletions for %s: %s`, skip deletions but keep additions | dev / 2.10.x only |

Otherwise: `deleted_files = prev_filenames - cur_filenames` → `_process_deletions()` →
`_process_orphaned_albums_and_artists()`. `[VERIFIED: upstream source at 2.9.13 and dev]`

**Purge granularity is `provider_item_id` = the file's path relative to the provider root.** A
retag-in-place keeps the id and updates the row. A *rename or move* (which any beets import performs)
looks like delete-old + add-new. That is a Phase 7+ concern, but it is worth recording now: mass
imports will churn MA's library, and the churn is *by design*, not a fault.

### Cheaper cleanups short of a full reset

| Lever | API command | Scope |
|-------|-------------|-------|
| Remove one item | `music/library/remove_item` | Single track/album/artist |
| Remove one album | `music/albums/remove` | One album + its provider mapping |
| Drop the whole provider | `config/providers/remove` | Removes that instance's rows; other providers untouched |
| Force re-read of one item | `music/refresh_item` | One item |

`[VERIFIED: upstream source — controllers/music/controller.py, controllers/music/media/base.py,
controllers/config/providers.py]`

**`config/providers/remove` is the important one.** Removing and re-adding the filesystem provider
purges *only* that provider's mappings and leaves the rest of `library.db` intact. That is the
correct recovery for "the pilot went in under the wrong album artist" — not a full reset.

### What a full reset actually costs

`controllers/music/database.py::_reset_database()`:

```python
async def _reset_database(self) -> None:
    await self.close()
    db_path = os.path.join(self.mass.storage_path, "library.db")
    await asyncio.to_thread(os.remove, db_path)
    await self._setup_database()
    await self.start_sync()
```

It **deletes the file**. Exposed as an advanced `ConfigEntryType.ACTION` (`reset_db`) on the core
music config; the handler also calls `mass.cache.clear()`.

Everything in `library.db` is lost:

| Table | What is lost |
|-------|--------------|
| `playlog` | Play counts, recently-played, resume positions, per-user history |
| `artists`, `albums`, `tracks`, `playlists`, `radios`, `audiobooks`, `podcasts` | The catalogue and every favourite flag on it |
| `provider_mappings`, `external_id_lookup` | Cross-provider links (local ↔ Spotify/Tidal matches) |
| `loudness_measurements`, `audio_analysis` | Every computed loudness/analysis result — recomputed the slow way |
| `thumbnails`, `genres`, `genre_media_item_*` | Artwork cache and genre assignments/exclusions |
| `settings` | Music-controller-scoped settings |

**Not lost:** provider *configuration* (it lives outside `library.db` in MA's settings store), player
configs, and users/tokens (`AuthenticationManager` has its own storage).

`[VERIFIED: upstream source — constants.py DB_TABLE_* lines 219-241, database.py:255-262]`
**Confidence: HIGH.**

**Conclusion for the plan:** the three-album gate is justified, but the stated stake ("re-doing this
after a bulk import ends at a full library database reset") **overstates the cost** — a provider
remove-and-readd is the real fallback and is far cheaper. Say so honestly rather than defending a
claim the source contradicts; the gate survives on the album-identity argument alone.

---

## Export Options — Final Recommendation

### The line

Write to `/etc/exports.d/music.exports` (**not** `/etc/exports` — see § Terraform):

```
# Managed by Terraform (infra/nfs-music-export.tf). Do not edit by hand.
# CONS-01: read-only export of the tagged music library to the HA NUC.
/mnt/tank/media/Music 172.16.1.31(ro,all_squash,anonuid=568,anongid=568,mountpoint,no_subtree_check,sec=sys)
```

### Every option, justified

| Option | Why | Source | Confidence |
|--------|-----|--------|-----------|
| `172.16.1.31` (single host, no netmask) | The NUC's LAN IP. CONS-01 says "restricted to the NUC". A `/24` or `*` fails the criterion. | NETWORK.md:36,200 | HIGH |
| `ro` | C-2/C-3: the tree is `0777` and knfsd shows clients mode bits only. Read-write would hand every client full write to the library. `exports(5)`: *"The default is to disallow any request which changes the filesystem. This can also be made explicit by using the ro option"* — state it explicitly so it is auditable in `exportfs -v`. | `exports(5)` | HIGH |
| `all_squash` | Every client uid maps to `anonuid`. Supersedes the `root_squash`/`no_root_squash` question entirely (C-5) and makes access deterministic regardless of what uid MA runs as. | `exports(5)` | HIGH |
| `anonuid=568,anongid=568` | C-4/C-9: `568:568` is the on-disk owner of all 2,674 entries. Squashing to the *owner* means access is decided by `owner@` in the NFSv4 ACL, the entry least likely to be surprising. Squashing to the default `65534` would rely on `everyone@`. `exports(5)`: *"By default, exportfs chooses a uid and gid of 65534 for squashed access. These values can also be overridden by the anonuid and anongid options."* | `exports(5)`; WRIT-04 | HIGH |
| **`mountpoint`** | *"This option makes it possible to only export a directory if it has successfully been mounted… This allows you to be sure that the directory underneath a mountpoint will never be exported by accident if, for example, the filesystem failed to mount due to a disc error."* `/mnt/tank/media/Music` is its own dataset, so it *is* a mount point. This is the single highest-value option here and is in **neither** of CLAUDE.md's candidates. | `exports(5)` | HIGH |
| `no_subtree_check` | The export root is a whole filesystem, so subtree checking buys nothing and costs reliability on renames. It is the modern default; state it to silence `exportfs`'s warning and keep `exportfs -v` output stable (which matters for the `triggers` hash). | `exports(5)` | HIGH |
| `sec=sys` | The default. Stated explicitly so `exportfs -v` output is deterministic and any future drift to `krb5` is a visible diff. | `exports(5)` | HIGH |
| **`fsid=` — deliberately ABSENT** | See below. | linux-nfs.org wiki | MEDIUM-HIGH |
| **`crossmnt` — deliberately ABSENT** | See below. | `exports(5)` | HIGH |
| **`no_root_squash` — FORBIDDEN** | C-5, and moot under `all_squash`. | CLAUDE.md | HIGH |

### Option A vs Option B from CLAUDE.md

**Option B wins.** Three reasons, in order of weight:

1. **C-9 forces it.** ROADMAP.md states the export's `anonuid`/`anongid` take Phase 1's WRIT-04
   value. Option A has no `anonuid`/`anongid` at all. 01-08-SUMMARY.md:511-513 reached the same
   conclusion independently once the normalisation completed.
2. **Determinism under ZFS NFSv4 ACLs.** knfsd shows clients mode bits, but the *server-side*
   permission decision is made by ZFS against the on-disk NFSv4 ACL for the squashed uid. Squashing
   to `568` — the owner — makes that decision fall on `owner@`. Option A's `root_squash` squashes
   only root, letting other uids through to be evaluated against `everyone@` or named ACEs. With the
   tree at `0777` both should work; Option B does not *depend* on that being true.
   `[VERIFIED for the knfsd half via CLAUDE.md/01-08; ASSUMED for the exact ZFS ACL evaluation path
   — verify empirically in Stage 4]`
3. **Option A's "world-read" precondition is not enforceable.** C-2 says `chmod` is `EPERM`
   pool-wide. Option A relies on modes staying world-readable, and nothing in the repo can assert or
   restore that. Option B does not care.

### `fsid=` — why it is absent

The linux-nfs.org wiki (the nfs-utils/nfsd maintainers' own wiki) states that designating a real
filesystem as the NFSv4 pseudo-root with `fsid=0` *is no longer recommended*; on any recent Linux
distribution you list exports exactly as you would for NFSv2/v3 and nfsd constructs the pseudo-
filesystem automatically. Clients then mount `server:/real/path`.
`[CITED: wiki.linux-nfs.org/wiki/index.php/Nfsv4_configuration]` **Confidence: MEDIUM-HIGH.**

This matters because both consumers use the full path: HA Supervisor builds
`what = f"{self.server}:{self.path.as_posix()}"` and MA builds `f"{server}:{export_path}"`. Adding
`fsid=0` would relocate the pseudo-root and require the client path to become `/`, breaking both.
**Do not add it.**

`exports(5)` notes `fsid=` remains necessary for filesystems on non-block devices where the kernel
cannot derive a stable UUID. ZFS datasets do supply one. **Verify in Stage 2** — if
`exportfs -v` or the client mount reports `fsid` trouble, that assumption is the thing to revisit.

### `crossmnt` — why it is absent

`exports(5)`, under `nohide`: *"This option is not relevant when NFSv4 is use. NFSv4 never hides
subordinate filesystems. Any filesystem that is exported will be visible where expected when using
NFSv4."* And on `crossmnt`: *"If a child of a crossmnt file is not explicitly exported, then it will
be implicitly exported with the same export options as the parent… This makes it impossible to not
export a child of a crossmnt filesystem."*

We export `tank/media/Music` **directly**, not a parent, so nothing needs crossing. Adding `crossmnt`
would make any future child dataset under `Music` implicitly exported — a silent scope expansion.
`[VERIFIED: exports(5)]` **Confidence: HIGH.** Stage 0.2 confirms there are no child datasets today.

### Which NFS version will be negotiated

**NFSv4.2**, downgrading as needed, on both routes:

| Route | Client options | Version outcome |
|-------|---------------|-----------------|
| A (Supervisor) | `["ro", "softerr", "timeo=100", "retrans=2"]` — no `vers=` | Kernel default. On any current kernel that is NFSv4.2 → 4.1 → 4.0 → 3. |
| B (MA in-container) | `["noatime","nolock","tcp","soft","timeo=30","retrans=5"]` + optional `vers=` | Same default unless `nfs_version` is set. |

`[VERIFIED: upstream source — supervisor/mounts/mount.py::NFSMount.options;
filesystem_nfs/provider.py::_get_mount_options]`

Two consequences:
- **CONS-01 says "NFSv4"** — assert it, do not assume it. On the NUC:
  `$SSH "mount -t nfs4 | grep music"` or `findmnt -no FSTYPE,OPTIONS /mnt/data/supervisor/media/music`
  and confirm `vers=4.2` (or at least `4.x`).
- MA's `filesystem_nfs/provider.py` carries a comment worth heeding if v3 is ever negotiated:
  *"NFSv3's rpc.mountd only hands out a filehandle for a path that is itself exported"* — which is
  another reason the export is the dataset root, not a subdirectory of it.

### Which client IP — and does the tailnet address need to be in the export?

**Export to `172.16.1.31` only. Do NOT add `100.73.196.51`.**

| Reason | Detail | Confidence |
|--------|--------|-----------|
| The traffic is LAN-local | Both boxes are on `172.16.1.0/24`. NFS never crosses the tailnet in this design. | HIGH |
| The tailnet source would not be `100.73.196.51` anyway | The NUC is a *subnet router* for `172.16.1.0/24`. Traffic it originates toward `172.16.1.158` egresses its LAN interface with source `172.16.1.31`. | MEDIUM — reasoned from the topology in MEMORY.md `tailnet-lan-redundancy`; verify with `exportfs -v` + a denied-mount test |
| MA documents the security boundary | *"Music Assistant assumes your NFS or SMB server is on your local network. It adds no encryption or access control of its own, so these shares should not be reached over the internet."* | HIGH — CITED |
| Adding it widens the blast radius for nothing | Any tailnet peer that could spoof or route as `100.73.196.51` would gain read access to the library. | HIGH |

If a future need arises to mount from off-LAN, the correct answer is a Tailscale-scoped export line
added deliberately, not a pre-emptive one. Record this as a decision so it is not re-litigated.

---

## Terraform Representation of the Export

### The established pattern in this repo

`infra/` uses `bpg/proxmox ~> 0.95` plus `hashicorp/null ~> 3.2`, and `host.tf` is a single
`null_resource "host_setup"` with a `connection` block and one `remote-exec` provisioner containing
a list of individually idempotent shell commands (`grep -q … || echo … >>`,
`getent group apps >/dev/null 2>&1 || groupadd …`). Its header states the contract: *"All operations
are idempotent — safe to re-run if the resource is tainted."*

There is **no** Proxmox provider resource for host file content — `bpg/proxmox`'s file resources
target PVE *storages*, not `/etc`. `null_resource` + `remote-exec` is the only mechanism available
and is the repo's own convention. `[VERIFIED: codebase — infra/providers.tf, infra/host.tf]`

### Recommended shape: `infra/nfs-music-export.tf`

```hcl
# nfs-music-export.tf — CONS-01
#
# Read-only NFSv4 export of the tagged music library to the Home Assistant NUC.
# Served from the Proxmox host because nfsd is privileged-only and LXC 100 is unprivileged.
#
# Re-apply is clean: the null_resource re-runs only when a value in `triggers` changes.

locals {
  music_export_path = "/mnt/tank/media/Music"

  music_export_line = join("", [
    local.music_export_path,
    " ",
    var.ha_nuc_ip,
    "(ro,all_squash,anonuid=${var.apps_uid},anongid=${var.apps_gid},",
    "mountpoint,no_subtree_check,sec=sys)",
  ])

  music_export_file = <<-EOT
    # Managed by Terraform (infra/nfs-music-export.tf). Do not edit by hand.
    # CONS-01: read-only export of the tagged music library to the HA NUC.
    ${local.music_export_line}
  EOT
}

resource "null_resource" "nfs_music_export" {
  triggers = {
    exports_content = local.music_export_file
    # bump to force a re-run without changing the export itself
    revision = "1"
  }

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "5m"
  }

  provisioner "file" {
    content     = local.music_export_file
    destination = "/etc/exports.d/music.exports"
  }

  provisioner "remote-exec" {
    inline = [
      # 1. Server package. Debian archive, not a PVE package; PVE ships only nfs-common.
      "dpkg -s nfs-kernel-server >/dev/null 2>&1 || (apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nfs-kernel-server)",

      # 2. Order nfs-server after the ZFS mounts. ZFS datasets are not systemd .mount
      #    units, so RequiresMountsFor= cannot resolve them — After=/Wants= is the lever.
      "mkdir -p /etc/systemd/system/nfs-server.service.d",
      "printf '[Unit]\\nAfter=zfs-mount.service\\nWants=zfs-mount.service\\n' > /etc/systemd/system/nfs-server.service.d/10-zfs-order.conf",
      "systemctl daemon-reload",

      # 3. Refuse to proceed if the dataset is not mounted. The `mountpoint` export
      #    option protects the running server; this protects the apply.
      "mountpoint -q ${local.music_export_path} || { echo 'FATAL: ${local.music_export_path} is not a mount point'; exit 1; }",

      # 4. Enable + apply.
      "systemctl enable --now nfs-server",
      "exportfs -ra",

      # 5. Prove it. Non-zero exit fails the apply, which is the point.
      "exportfs -v | grep -q '${var.ha_nuc_ip}' || { echo 'FATAL: export not present after exportfs -ra'; exit 1; }",
      "exportfs -v | grep -q 'no_root_squash' && { echo 'FATAL: no_root_squash present'; exit 1; } || true",
    ]
  }
}
```

Add to `variables.tf`:

```hcl
variable "ha_nuc_ip" {
  description = "LAN IP of the Home Assistant NUC — the only client permitted to mount the music export"
  type        = string
  default     = "172.16.1.31"
}
```

### The specific questions answered

| Question | Answer | Confidence |
|----------|--------|-----------|
| `/etc/exports` vs `/etc/exports.d/` | **`/etc/exports.d/music.exports`.** `exports(5)`: *"After reading /etc/exports exportfs reads files in the /etc/exports.d directory as extra export tables. Only files ending in .exports are considered."* A drop-in is a whole-file write (trivially idempotent), leaves `/etc/exports` untouched for anything else, and makes the Terraform-managed surface exactly one file. | HIGH |
| Does `exportfs -ra` need to run, and how is it idempotent? | **Yes.** `exports(5)`: *"To apply changes to this file, run exportfs -ra or restart the NFS server."* `exportfs -ra` is itself idempotent — it re-syncs the kernel table to the files, converging rather than appending. Running it on every apply is harmless; the apply only happens when `triggers` change. | HIGH |
| Does `nfs-kernel-server` need managing? | **Yes, install and enable.** Proxmox ships only `nfs-common` (client). `nfs-kernel-server` comes from the Debian archive; PVE 9 is Debian trixie and `host.tf` already configures the `pve-no-subscription` repo and runs `apt-get update`. Guard with `dpkg -s … \|\| install` so re-runs are no-ops. | MEDIUM-HIGH — verify with Stage 0.5 |
| What does "a re-apply is clean" mean concretely? | A second `terraform plan` immediately after `apply` prints **`No changes. Your infrastructure matches the configuration.`** `null_resource` re-creates only when a `triggers` value changes; `local.music_export_file` is a pure function of variables, so it is stable across plans. **Trap:** `host.tf`'s `null_resource` has *no* `triggers` — it therefore never re-runs, even when its inline script changes. Do not copy that; `triggers` is what makes the export both clean *and* responsive to edits. | HIGH |

### Why not `zfs set sharenfs=`

| Consideration | Verdict |
|--------------|---------|
| Idempotency | A tie. A ZFS property either equals the string or does not. |
| Where the config lives | `sharenfs` puts the export inside a ZFS property, which `zfs send`/`recv` carries to any replication target — a silent way to export the library somewhere unintended. |
| Auditability | The generated `/etc/exports.d/zfs.exports` is *regenerated* and must not be hand-edited, so the file on disk is not the source of truth. A drop-in file is. |
| Option syntax | ZFS `sharenfs` uses comma-separated options with per-host syntax that differs from `exports(5)`. `mountpoint` in particular is unproven through that path. |
| Mixing | Every source consulted says pick one mechanism and never both. Stage 0.4 confirms `sharenfs` is currently unused. |
| C-1 fit | The repo's Terraform already manages ZFS properties (`zfs set mountpoint=` in `host.tf`), so `sharenfs` would *not* violate C-1. It is rejected on the four rows above, not on C-1. |

**Decision: `/etc/exports.d/` drop-in.** Record it, and record that `sharenfs` must stay `off` on
`tank` so nothing regenerates a competing table. `[VERIFIED for the mechanism via OpenZFS docs and
exports(5); MEDIUM on the `mountpoint`-through-`sharenfs` claim, which was not tested]`

---

## Blast Radius — What Must Not Break

| # | Concern | Assessment | Check |
|---|---------|-----------|-------|
| B-1 | **Jellyfin reads the same tree** | No regression possible from this phase. Jellyfin reads via LXC 100's bind mount of the host path. knfsd exporting the same directory adds a second *reader* at the VFS layer; it changes no inode, no mode, no owner. The export is `ro`, so nothing can be written through it. | After Stage 2, confirm Jellyfin still lists the Music library and can play one track. Assert `/mnt/tank/media/Music` file count and `zfs list -o used tank/media/Music` unchanged before/after. |
| B-2 | **LXC 100's bind mount of `tank`** | No interaction. A bind mount and an NFS export are independent views of the same dentry tree; nfsd does not take an exclusive reference and does not alter mount propagation for the container. The LXC is unprivileged with an idmap, but the export is `ro` so no uid shifting can occur through it. | `pct config 100 \| grep mp` before and after; `ssh root@172.16.1.159 'ls /media/Music \| head'` still works. |
| B-3 | **Installing `nfs-kernel-server` on the PVE host** | Opens 2049/tcp (and 111 via `rpcbind` for v3 compatibility) on all interfaces. PVE's own NFS *client* function is unaffected. Standard, widely documented on PVE. | `ss -lntp \| grep -E ':(111\|2049)'`. Confirm `pvesm status` is unchanged. |
| B-4 | **Firewall between .31 and .158** | Both hosts are on the same `172.16.1.0/24` behind the UCG-Max, which does not filter intra-VLAN traffic. No rule change expected. `[ASSUMED — verify]` | From the NUC: `nc -vz 172.16.1.158 2049` before attempting the mount. |
| B-5 | **`exportfs -ra` disturbing a pre-existing export** | `exportfs -ra` re-reads `/etc/exports` plus every `/etc/exports.d/*.exports` and converges the kernel table. If atlantis already exports something, that export survives — but its *options* are re-applied from file, so a hand-added export that only exists in the kernel table would be dropped. | Stage 0.4 captures the before-state. If it is non-empty, capture `exportfs -v` and diff after. |
| B-6 | **ZFS ARC / memory on atlantis** | An `ro` NFS export adds page-cache and ARC pressure proportional to what MA reads. MA scans metadata, not full files, so the working set is small. The box has 28 GB and a documented history of memory pressure (`lxc100-tmp-is-tmpfs`, `amdgpu-hmm` incident). Low risk but worth a look. | `arcstat 1 5` on atlantis during MA's first full sync. |
| B-7 | **MA writing into the library** | Route B has **no `ro` client option** (§ Route B). The server-side `ro` is the only guarantee. MA's `check_write_access()` deliberately writes a random temp file at the provider root on every load: `temp_file_name = self.get_absolute_path(f"{shortuuid.random(8)}.txt")`. On a `ro` export this raises, is logged at DEBUG, `write_access` stays `False`, and nothing is created. **If the export were `rw`, MA would create and delete a stray `.txt` in the library root on every provider load.** | Stage 4b is exactly this test. Also `find /mnt/tank/media/Music -maxdepth 1 -name '*.txt' -newer <marker>` after MA loads. |
| B-8 | **Sidecar pollution (Phase 1's `SaveLocalMetadata` freeze)** | MA does not write `.nfo`/`.jpg`/`.lrc`. It *reads* them (docs: `.lrc` lyrics, `folder.jpg` artwork, `.nfo` metadata). Under a `ro` export it could not write them regardless. Phase 1's freeze is unaffected. | Re-run `bash scripts/check-music-freeze.sh` after the phase; expect the same exit code as at Phase 1 closure. |
| B-9 | **Snapshot/rollback interaction** | An active NFS export holds open file handles on the dataset. `zfs rollback` requires no open files with certain flags; a stale NFS client can block it. Future phases roll back `tank/media/Music`. | Record the recovery order: `ha mounts delete music` (or stop the MA provider) → `exportfs -u 172.16.1.31:/mnt/tank/media/Music` → `zfs rollback` → re-export. **Add this to the phase's operational notes.** |

**Nothing in this phase modifies content, ownership, modes, or any container mount.** The only
mutations are: one Debian package, one systemd drop-in, one file in `/etc/exports.d/`, one Supervisor
mount record on the NUC, and one MA provider instance.

---

## Runtime State Inventory

This is not a rename/refactor phase, but it *creates* runtime state outside git, which is the same
class of hazard. Recording it so a later phase does not have to rediscover it.

| Category | Items created / touched | Action required |
|----------|------------------------|-----------------|
| Stored data | MA `library.db` gains rows for three albums + their artists/tracks, keyed on `provider_instance` and relative path. Lives at the add-on's `/data/library.db` → `/mnt/data/supervisor/addons/data/core_music_assistant/` on the NUC. **Not in git, not in this repo, not on atlantis.** | None now. Note it in PROJECT.md as state the estate carries. |
| Live service config | (a) The **Supervisor mount record** — stored in `mounts.json` in Supervisor's config, **only** on the NUC, not in git. Captured in HA backups. (b) The **MA provider instance** config — stored in MA's settings store on the NUC, not in git; excluded from add-on backup only for `cache.db`, so it *is* backed up. | Record both in `NETWORK.md` or a new `stacks/…/music-assistant.md` so a NUC rebuild does not lose them silently. |
| OS-registered state | `nfs-server.service` enabled on atlantis; `/etc/systemd/system/nfs-server.service.d/10-zfs-order.conf`. Both re-created by `terraform apply` — **provided the `null_resource` is tainted or its trigger changed.** A fresh atlantis rebuild re-runs it from scratch. | Ensure the drop-in is written by Terraform, not by hand, or a rebuild loses it. |
| Secrets / env vars | A Music Assistant **long-lived API token** is needed for the assertions. C-7: it goes in `~/.claude/secrets/ma-deercrest.env` by variable name only, **never** in the repo, `terraform.tfvars`, or a plan file. MA credentials (`MA_USER`/`MA_PASS`) likewise. | Create the secrets file; add `ma-deercrest` to the ha-deercrest skill's sibling set or document it in the skill. |
| Build artifacts | None. | — |

**The canonical question — after every file in the repo is updated, what runtime systems hold state
this repo cannot see?** Three: Supervisor's `mounts.json`, MA's provider settings, and MA's
`library.db`. All three live on the NUC. All three are inside HA's backup. **None is in git.**

---

## Common Pitfalls

### Pitfall 1: The mount target is not empty, so the mount silently degrades
**What goes wrong:** `/media/music` already contains something (an earlier failed attempt, a stray
file), so `Mount.mount()` raises `MountTargetNotEmptyError` and the emergency empty-dir bind takes
over. Everything *looks* configured; MA sees an empty folder.
**Why:** `ensure_empty_folder()` in `supervisor/mounts/mount.py` refuses a non-empty target by design.
**Avoid:** Before adding the mount, `$SSH "ls -la /mnt/data/supervisor/media/"`. If `music` exists
and is non-empty, use Supervisor's `relocate_local_data` (it moves the content to
`music_local_recovery` rather than deleting it) instead of `rm`.
**Warning sign:** `MOUNT_FAILED` repair issue in HA, plus the `mounting read-only fallback` log line.

### Pitfall 2: A hyphen in the mount name is rejected
**What goes wrong:** `ha mounts add tank-music` fails validation with an opaque error.
**Why:** `RE_MOUNT_NAME = re.compile(r"^[A-Za-z0-9_]+$")`.
**Avoid:** `music`. **Warning sign:** HTTP 400 from `POST /mounts`.

### Pitfall 3: `ha` CLI returns `unauthorized` over SSH
**What goes wrong:** `ssh sysadmin@172.16.1.31 "ha mounts info"` → `unauthorized: missing or invalid
API token`. A PTY (`ssh -tt`) does not fix it.
**Why:** non-login shells do not export `SUPERVISOR_TOKEN`.
**Avoid:** `bash -lc 'ha …'`. Use `bash`, not `zsh` — `zsh -lc` prints the MOTD banner first and
breaks JSON parsing. Requires protection mode OFF on the SSH add-on (confirmed off 2026-07-27).
**Source:** `~/.claude/skills/ha-deercrest/SKILL.md`.

### Pitfall 4: Testing read-only through the client mount only
**What goes wrong:** `touch` fails, the plan records PASS, and the export is actually `rw`.
**Why:** Route A mounts with `ro` client-side. That proves the *client* is read-only, not the export.
**Avoid:** Stage 4b — a hand-rolled `mount -o rw` from the NUC that bypasses the Supervisor mount.
That, and only that, tests CONS-01 criterion 2.

### Pitfall 5: Exporting an unmounted directory after a host reboot
**What goes wrong:** atlantis reboots, `nfs-server` starts before `zfs-mount`, and the export points
at the empty stub directory under the unmounted dataset. The NUC mounts successfully and sees zero
files. MA's empty-scan guard saves the library, but every track is unplayable until someone notices.
**Avoid:** the `mountpoint` export option (M1) plus the systemd ordering drop-in (M2).
**Warning sign:** `exportfs -v` on atlantis shows the export but `mountpoint -q /mnt/tank/media/Music`
fails — an impossible combination once `mountpoint` is set, which is the point.

### Pitfall 6: Trusting the default `missing_album_artist_action`
**What goes wrong:** untagged tracks land under `Various Artists`, which is indistinguishable from
the DJ compilations that legitimately belong there. Criterion 3 passes on three well-tagged albums
and the trap detonates at Phase 7 scale.
**Avoid:** set the action deliberately (recommend `folder_name`, which agrees with CONF-03's path
format) and record the choice.

### Pitfall 7: `172.16.1.31` unreachable from the tailnet during a failover
**What goes wrong:** the plan is executed off-LAN, HA is the *standby* subnet router, and its LAN IP
`172.16.1.31` is unreachable from the tailnet (reply egresses `tailscale0` with a source outside the
peer's AllowedIPs).
**Avoid:** from off-LAN use `100.73.196.51` for SSH/API. The **export line still names
`172.16.1.31`** — that is the source address the NUC uses toward atlantis, and it is unrelated to how
the operator reaches the NUC. **Source:** MEMORY.md `tailnet-lan-redundancy`, ha-deercrest SKILL.md.

### Pitfall 8: Adding `fsid=0` from an old tutorial
**What goes wrong:** the export becomes the NFSv4 pseudo-root, and both HA Supervisor and MA — which
both build `server:/full/path` — fail to mount.
**Avoid:** no `fsid=` at all. **Warning sign:** client mount fails with `access denied by server`
while `exportfs -v` looks correct.

### Pitfall 9: Doing this after content flows
**What goes wrong:** the album-identity key (`albumartist + os.sep + album`) means a wrong album
artist creates a durable wrong entry. Discovered at 34 GB, the cheapest repair is
`config/providers/remove` + re-add, which drops every favourite and play count attached to that
provider's items.
**Avoid:** the three-album gate, which is what the phase is for.

---

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Mounting NFS on HAOS | An `fstab` edit, an `/etc/rc.local` hook, or a `shell_command` automation running `mount` | `ha mounts add` / Supervisor `POST /mounts` | HAOS's OS partition is immutable and reset on update. Supervisor owns mounts, retries them every 900 s, provides the emergency fallback, and survives HA updates. Every community `shell_command` workaround is fighting that. |
| Retrying a failed mount | A cron/automation loop | Supervisor's `RUN_RELOAD_MOUNTS = 900` scheduled `sys_mounts.reload()` | Already exists, escalates reload → restart, and dismisses the resolution issue on success. |
| Preventing an unmounted-path export | A pre-flight shell check in an ExecStartPre | The `mountpoint` export option | Evaluated per-request by the kernel, not once at start. A shell check only covers the boot path. |
| Detecting whether MA can see the files | Parsing the MA UI, or `ls` from inside the container | `music/albums/library_items` + `music/albums/count` via `POST /api` | "Files are visible" is not the gate — CONS-02 is about album-artist grouping, which only MA's own model can answer. |
| Triggering a library scan | Restarting the add-on, or waiting 12 h | `music/sync` with `providers` and `media_types` filters | Restarting also re-runs provider setup and `check_write_access()`, which muddies the evidence. |
| Reading MA's library | `sqlite3` against `library.db` on the NUC | The API | The schema is at `DB_SCHEMA_VERSION: 58` and migrates without notice. The API is the contract. |
| Managing the export file | `sed`/`awk` append into `/etc/exports` | A whole-file `/etc/exports.d/music.exports` written by Terraform's `file` provisioner | Whole-file writes are idempotent by construction; append-guards are not, and `exports(5)` explicitly supports the drop-in directory. |
| Restricting access | Firewall rules on atlantis | The export's host specification | The export table is the NFS access-control mechanism, it is visible in `exportfs -v`, and it is what the requirement asks for. |

**Key insight:** every layer in this phase already has a purpose-built, source-visible mechanism for
the thing being asked. The failure mode in this domain is not missing capability, it is reaching for
a shell workaround because the built-in mechanism was not looked up.

---

## Code Examples

### Mount options Supervisor actually uses (you cannot override them)

```python
# supervisor/mounts/mount.py
class NetworkMount(Mount, ABC):
    @property
    def options(self) -> list[str]:
        options = super().options            # ["ro"] if read_only else []
        if self.port:
            options.append(f"port={self.port}")
        return options

class NFSMount(NetworkMount):
    @property
    def what(self) -> str:
        return f"{self.server}:{self.path.as_posix()}"

    @property
    def options(self) -> list[str]:
        return super().options + ["softerr", "timeo=100", "retrans=2"]
```
Source: https://github.com/home-assistant/supervisor/blob/main/supervisor/mounts/mount.py

### Supervisor's liveness probe — what `state: active` really means

```python
def _probe_network_mount(path: Path) -> bool:
    """Verify `path` is a live mount on a reachable server."""
    os.statvfs(path)
    return path.stat().st_dev != path.parent.stat().st_dev
```
`statvfs` forces an NFS `FSSTAT` RPC (uncacheable), and the `st_dev` comparison distinguishes a real
mount from a "ghost mount" where `statvfs` silently returned the underlying root filesystem's stats.
This is why `ha mounts info` state is trustworthy evidence and not just systemd's opinion.
Source: same file.

### The deletion guard that saves the library on a failed mount

```python
# music_assistant/providers/filesystem_local/__init__.py (tag 2.9.13)
if prev_filenames and not cur_filenames:
    self.logger.error(
        "Aborting sync for %s: scan found no files but %d were previously indexed",
        self.name, len(prev_filenames),
    )
    report_current_task_failure(
        f"Sync aborted: scan found no files but {len(prev_filenames)} were previously indexed"
    )
    return
```
Source: https://github.com/music-assistant/server/blob/2.9.13/music_assistant/providers/filesystem_local/__init__.py

### MA's write probe — why the export must be `ro`

```python
async def check_write_access(self) -> None:
    """Perform check if we have write access."""
    temp_file_name = self.get_absolute_path(f"{shortuuid.random(8)}.txt")
    try:
        async with aiofiles.open(temp_file_name, "w") as _file:
            await _file.write("test")
        await asyncio.to_thread(os.remove, temp_file_name)
        self.write_access = True
    except Exception as err:
        self.logger.debug("Write access disabled: %s", str(err))
```
It writes into the **library root** on every provider load. It does not raise on failure, so `ro` is
safe — but on a `rw` export it would create and delete a stray file in `/mnt/tank/media/Music` every
time. Source: same file.

### Non-interactive assertion helper (shape for `scripts/check-music-consumers.sh`)

```bash
#!/usr/bin/env bash
# check-music-consumers.sh — read-only audit of CONS-01/02/03.
# READ-ONLY BY CONTRACT, matching scripts/check-music-freeze.sh.
# Exit-code convention (inherited from check-music-freeze.sh):
#   default    — every red finding increments FAILURES; non-zero exit.
#   --baseline — print everything, always exit 0.
set -uo pipefail
FAILURES=0
fail() { printf '\033[31m❌ %s\033[0m\n' "$*"; FAILURES=$((FAILURES+1)); }
ok()   { printf '\033[32m✅ %s\033[0m\n' "$*"; }

source ~/.claude/secrets/ha-deercrest.env
source ~/.claude/secrets/ma-deercrest.env
SSH="ssh -i $HA_SSH_KEY -o BatchMode=yes -p $HA_SSH_PORT $HA_SSH_USER@$HA_SSH_HOST"
api() { curl -s -X POST "$MA_URL/api" -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $(cat "$MA_TOKEN_FILE")" \
        -d "{\"command\":\"$1\",\"args\":${2:-\{\}}}"; }

# CONS-01: export exists, is ro, single-host
EXP=$(ssh root@172.16.1.158 'exportfs -v' 2>/dev/null)
grep -q '/mnt/tank/media/Music' <<<"$EXP" || fail "CONS-01: Music not exported"
grep -q '172.16.1.31'           <<<"$EXP" || fail "CONS-01: export not restricted to the NUC"
grep -q 'no_root_squash'        <<<"$EXP" && fail "CONS-01: no_root_squash present"
grep -qE '\(.*[,(]ro[,)]'       <<<"$EXP" || fail "CONS-01: export is not ro"

# CONS-03 precondition: mount is live, not the emergency stub
STATE=$($SSH "bash -lc 'ha mounts info --raw-json'" | jq -r '.data.mounts[]|select(.name=="music")|.state')
[[ "$STATE" == "active" ]] || fail "CONS-03: mount state is '$STATE'"
$SSH "mount | grep -q emergency/music" && fail "CONS-03: emergency bind in place"

# CONS-02: the three albums, under the right album artist
while IFS='|' read -r ALBUM ARTIST; do
  GOT=$(api music/albums/library_items "{\"search\":\"$ALBUM\",\"limit\":5}" \
        | jq -r --arg a "$ALBUM" '.result[]|select(.name==$a)|.artists[0].name')
  [[ "$GOT" == "$ARTIST" ]] && ok "CONS-02: $ALBUM → $GOT" \
                            || fail "CONS-02: $ALBUM → '$GOT' (expected '$ARTIST')"
done < .planning/phases/02-nfs-export-and-music-assistant-reachability/pilot-albums.txt

exit $(( FAILURES > 0 ? 1 : 0 ))
```

---

## State of the Art

| Old approach | Current approach | When changed | Impact here |
|--------------|------------------|--------------|-------------|
| NFSv4 requires a `fsid=0` pseudo-root plus bind-mounts into an export tree | List exports normally; nfsd builds the pseudo-fs automatically; clients mount `server:/real/path` | Long-standing; linux-nfs.org wiki calls `fsid=0` "no longer recommended" | **Do not add `fsid=`.** Most tutorials still show the old way. |
| MA can only reach network shares through HA's `/media` | MA ships first-class `Filesystem (NFS share)` and `Filesystem (remote share)` (SMB) providers | NFS provider added in **2.8.0b20**, 12 Mar 2026 | Route B is a real fallback, not a hack. |
| The MA container lacks NFS tooling | `Dockerfile.base` installs `cifs-utils`, `libnfs13`, `nfs-common`; the add-on's AppArmor profile permits `mount`/`umount`/`remount` | Current at 2.9.13 | The widely-repeated "MA can't see NFS mounts" advice is stale. |
| A failed HA media mount never recovers without a reboot | Supervisor reloads mounts every 900 s and escalates reload → restart on a failed liveness probe | Present in current Supervisor `misc/tasks.py` | Sources conflict with community reports — see § Where Sources Conflict. |
| MA leaves stale library entries forever | `_process_deletions` + `_process_orphaned_albums_and_artists` run every sync, behind an empty-scan guard | Present at 2.9.13 | **Corrects the ROADMAP premise.** |
| `supervisor/docker/addon.py`, `ha addons` | `supervisor/docker/app.py`, `ha apps` (`addons` deprecated) | Recent upstream rename | Matters when reading source or scripting the CLI. |

**Deprecated / outdated:**
- `no_root_squash` — rejected by C-5 and unnecessary under `all_squash`.
- `fsid=0` for a non-root export — see above.
- `nohide` — `exports(5)`: *"not relevant when NFSv4 is use."*
- Community `nofail`/`bg` mount-option advice for HAOS — Supervisor builds its own option list; there is no user-supplied options field.

---

## Environment Availability

Everything below is `[ASSUMED]` — **no live estate access was available this session** (§ Session
Limitation). The plan's first task must measure them.

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| SSH to `root@172.16.1.158` | Terraform `remote-exec`, all server-side checks | ? | — | None — blocking |
| SSH to `sysadmin@172.16.1.31` (or `100.73.196.51`) | `ha` CLI, mount verification, reboot | ? | — | HA REST API via `$HA_URL/api/…`, but `ha mounts` has no REST equivalent outside `/mounts` on the Supervisor API |
| `terraform` ≥ 1.6 on the workstation | `infra/` apply | ? | — | None — blocking |
| `nfs-kernel-server` on atlantis | CONS-01 | **Expected NOT installed** | — | Install from Debian archive (`pve-no-subscription` repo already configured by `host.tf`) |
| `nfs-common` on the NUC (HAOS host) | Mounting | Expected present (HAOS supports NFS network storage natively) | — | None — Supervisor requires it |
| `zfs` / dataset `tank/media/Music` mounted | `mountpoint` export option | Expected yes | — | None — blocking |
| MA add-on running | CONS-02/03 | Expected 2.9.13 | 2.9.13 | — |
| MA API credentials / long-lived token | Every assertion | **Does not exist yet** | — | HA ingress (needs an ingress session — messier); or manual UI verification, which weakens the evidence |
| `jq` on the workstation | Parsing every JSON assertion | Likely | — | `python3 -m json.tool` |
| `nc` or `ss` on the NUC | B-4 firewall check | HAOS ships a busybox userland; `nc` availability uncertain | — | Attempt the mount and read the error |
| Protection mode OFF on the SSH add-on | `ha` CLI over SSH | Confirmed off 2026-07-27 (may have drifted) | — | Turn it off via the add-on UI (Info tab → ⋮) |

**Missing with no fallback (blocking):** SSH to atlantis; Terraform; the dataset being mounted.
**Missing with a fallback:** the MA API token — it is *created* during the phase, not a precondition,
but it must exist before Stage 6 and the credentials to mint it must be known. **Confirm with the
user that MA admin credentials exist and where they live.**

---

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json`.

### Test framework

| Property | Value |
|----------|-------|
| Framework | **None.** `01-PATTERNS.md`: *"there is no test framework, no Python anywhere in the tree."* The estate convention is bash audit scripts under `scripts/` with a documented exit-code contract. |
| Config file | none |
| Quick run command | `bash scripts/check-music-consumers.sh` |
| Full suite command | `bash scripts/check-music-consumers.sh && bash scripts/check-music-freeze.sh` |
| Exit-code contract | Inherit `check-music-freeze.sh` exactly: default mode increments `FAILURES` per red finding and exits non-zero; `--baseline` prints everything and always exits 0. Stated in the file header, because the estate's older scripts exit 0 on findings and that silence is what hid the `created`-state blind spot for six weeks. |

### Success criterion → evidence map

| Crit | Behaviour | Type | Automated command | Exists? |
|------|-----------|------|-------------------|---------|
| 1a | Export exists, is `ro`, restricted to `172.16.1.31`, no `no_root_squash` | integration | `ssh root@172.16.1.158 'exportfs -v'` parsed in `check-music-consumers.sh` | ❌ Wave 0 |
| 1b | Terraform re-apply is clean | integration | `cd infra && terraform apply -auto-approve && terraform plan -detailed-exitcode` (**exit 0** = no changes) | ❌ Wave 0 |
| 1c | Export served from the host, not LXC 100 | integration | `ssh root@172.16.1.158 'systemctl is-active nfs-server'` **and** `ssh root@172.16.1.159 'systemctl is-active nfs-server \|\| echo absent'` | ❌ Wave 0 |
| 1d | Visible from the NUC | integration | `$SSH "showmount -e 172.16.1.158"` (falls back to the mount attempt if `showmount` is absent on HAOS) | ❌ Wave 0 |
| 1e | NFSv4 actually negotiated | integration | `$SSH "findmnt -no FSTYPE,OPTIONS /mnt/data/supervisor/media/music"` → expect `nfs4` and `vers=4.x` | ❌ Wave 0 |
| 2 | A write from the NUC fails **at the export layer** | integration | Stage 4b: hand `mount -o rw` then `touch`; assert EROFS | ❌ Wave 0 |
| 3 | Three albums under the correct album artist within one sync cycle | integration | `music/sync` then `music/albums/library_items`, compared against `pilot-albums.txt` | ❌ Wave 0 |
| 4a | Positive reboot: mount active, albums present, no intervention | manual trigger + automated assert | `ha host reboot`, wait, then `check-music-consumers.sh` | ❌ Wave 0 |
| 4b | Negative control: the race actually fires and recovers unattended | manual trigger + automated assert | § Proving the Race Was Exercised — assert on `emergency/music` in `mount`, the `read-only fallback` log line, MA's `Aborting sync` line, then unattended recovery | ❌ Wave 0 |
| 5 | Winning route + losing route's failure symptom recorded in PROJECT.md; the current mount-route assertion corrected | doc assert | `grep -q 'Key Decision' .planning/PROJECT.md` plus a manual read — **manual-only**, justified: prose correctness is not machine-checkable | n/a |
| B-1 | Jellyfin unaffected | integration | `bash scripts/check-music-freeze.sh` exits with the Phase 1 closure code; plus a Jellyfin API library-count check | partially exists |

### Sampling rate

- **Per task commit:** `bash scripts/check-music-consumers.sh` — target < 30 s (four SSH round-trips
  plus three API calls).
- **Per wave merge:** the full suite (consumers + freeze), so a Phase 1 regression cannot hide behind
  a Phase 2 pass.
- **Phase gate:** full suite green, **plus** criterion 4b's negative control run once with its three
  pieces of evidence captured in the SUMMARY. A green 4a without 4b is not sufficient — the race can
  pass by luck.
- **Standing:** fold the consumers check into `scripts/quick-health-check.sh` the way 01-09 folded in
  `check-music-freeze.sh`, so estate health covers CONS-01/03 from then on.

### Wave 0 gaps

- [ ] `scripts/check-music-consumers.sh` — covers CONS-01, CONS-02, CONS-03; exit-code contract in the header
- [ ] `.planning/phases/02-.../pilot-albums.txt` — the three albums as `Album|Album Artist`, chosen from content that is *already correctly tagged* (criterion 3 says "already-correct albums")
- [ ] `~/.claude/secrets/ma-deercrest.env` — `MA_URL`, `MA_TOKEN_FILE`, and the credentials used to mint the token (C-7: outside the repo)
- [ ] A one-line addition to `scripts/quick-health-check.sh` invoking the consumers check
- [ ] Framework install: **none** — bash + `jq` + `curl` only

---

## Security Domain

`workflow.security_enforcement` is `true`, `security_asvs_level` is `1`.

### Applicable ASVS categories

| ASVS category | Applies | Standard control for this phase |
|---------------|---------|-------------------------------|
| V2 Authentication | Yes | MA API uses bearer tokens (`auth/login` → `auth/token/create`, long-lived = 365 days, `TOKEN_LONG_LIVED_EXPIRATION`). HA uses a long-lived access token. **NFS `sec=sys` provides no authentication at all** — the control is host restriction plus `ro`, and that must be stated as a limitation, not glossed. |
| V3 Session management | No | No user sessions introduced. MA ingress requests are authenticated by socket-level verification of the ingress bind address (`is_request_from_ingress`), not by headers — a header-spoofing bypass is explicitly closed upstream. |
| V4 Access control | **Yes** | Single-host export specification + `ro` + `all_squash,anonuid=568,anongid=568`. `no_root_squash` forbidden. The tailnet address deliberately excluded. |
| V5 Input validation | Minimal | Supervisor validates mount config (`SCHEMA_MOUNT_CONFIG`, `RE_MOUNT_NAME`); MA validates `export_path` with `is_safe_path()` and the subfolder against mountpoint escape. Terraform inputs come from `variables.tf` with typed defaults. |
| V6 Cryptography | No | Nothing is encrypted, and nothing should be — this is LAN-local traffic. `exports(5)` documents `xprtsec=` (RPC-with-TLS, RFC 9289) as available; **not adopted**, because it needs `tlshd` on both ends for a threat model (LAN eavesdropping on a music library) that does not justify it. Record the decision so it is a choice, not an oversight. |
| V7 Error handling / logging | Yes | Supervisor raises a `MOUNT_FAILED` resolution issue; MA reports task failures. Both are observable. Ensure the check script surfaces them rather than only checking the happy path. |
| V12 File / resources | **Yes** | This phase's core control: the export is `ro`, the tree is `0777`, and mode bits are all NFS clients see. Route B has no client-side `ro` option, so the server-side `ro` is load-bearing. |
| V14 Configuration | Yes | Secrets outside the repo (C-7). Terraform inputs marked `sensitive` where they are passwords. |

### Known threat patterns for this stack

| Pattern | STRIDE | Mitigation |
|---------|--------|-----------|
| Any host on the LAN mounts the export and reads the library | Information disclosure | Single-host export specification (`172.16.1.31`, no netmask); assert in `exportfs -v`. |
| A client claims uid 0 and gets root on the dataset (`sec=sys` trusts client-asserted uids) | Elevation of privilege | `all_squash` — every uid, including 0, is mapped to `568`. `no_root_squash` is forbidden by C-5. |
| A writable export lets any reader corrupt or delete 34 GB of curated library | Tampering / Denial of service | `ro` at the export, tested by Stage 4b (which bypasses the client-side `ro` to make the test meaningful). |
| ARP/IP spoofing of `172.16.1.31` to bypass the host restriction | Spoofing | Accepted residual risk: `sec=sys` on a trusted LAN. Documented, not mitigated. `xprtsec=` or `sec=krb5` would mitigate; both are disproportionate here. Record as an accepted risk in PROJECT.md. |
| The MA API token leaks into the public repo | Information disclosure | C-7: `~/.claude/secrets/` only, by variable name. The repo is public and has one prior credential exposure on record (`gateway-password-exposed-rotate`). **Add a plan-level check that no token string appears in any committed file.** |
| `no_root_squash` reintroduced by a future edit | Elevation of privilege | The Terraform `remote-exec` asserts its absence and fails the apply; the check script asserts it again. Two independent gates. |
| Export widened to `*` or a `/24` by a future edit | Information disclosure | `check-music-consumers.sh` asserts the exact host string. |
| Exposing NFS beyond the LAN | Information disclosure | MA docs: *"these shares should not be reached over the internet."* The tailnet address is deliberately not in the export; NFS ports are not forwarded (NETWORK.md lists only 443 and 21115-21119). |

---

## Package Legitimacy Audit

**No language-ecosystem packages are installed by this phase.** Nothing from npm, PyPI, crates.io,
Go modules, or any other registry is added.

| Package | Registry | Age | Downloads | Source repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `nfs-kernel-server` | Debian archive (trixie `main`) — **not** a language registry | Debian-packaged since the 1990s | n/a | https://git.linux-nfs.org/?p=steved/nfs-utils.git | n/a — out of scope for slopcheck | Approved |

`nfs-kernel-server` is the Debian binary package of upstream `nfs-utils`, installed by name from the
distribution's own signed archive over apt's cryptographic verification. Slopsquatting is not the
threat model for a distribution archive: names are assigned by the distribution, not
self-registered. Verify presence and provenance at execution time with `apt-cache policy
nfs-kernel-server` (confirm the origin is `deb.debian.org` / a Proxmox-configured Debian mirror,
not a third-party repo).

**Packages removed due to a `[SLOP]` verdict:** none.
**Packages flagged `[SUS]`:** none.
**slopcheck run:** not applicable — no registry packages to check.

---

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|--------------|
| A1 | `nfs-kernel-server` is not currently installed on atlantis; PVE ships only `nfs-common` | Terraform Representation | Low — the install is guarded by `dpkg -s … \|\|`. |
| A2 | Nothing is currently exported from atlantis and `sharenfs` is `off` on all of `tank` | Empirical Protocol Stage 0.4 | **Medium-high.** `exportfs -ra` would re-converge the table; a competing `sharenfs` would produce two tables for the same path. Stage 0.4 must run before Stage 1. |
| A3 | `/mnt/tank/media/Music` is currently mounted and is a mount point | Export options (`mountpoint`) | **High** — with `mountpoint` set, an unmounted dataset means the export silently does not exist. Stage 0.1 gates this, and the Terraform apply fails hard on it. |
| A4 | No child ZFS datasets exist under `tank/media/Music` | `crossmnt` absent | Low — a child dataset would simply be invisible to clients. Stage 0.2 measures it. |
| A5 | The NUC's LAN IP is `172.16.1.31` and it is the source address the NUC uses toward `172.16.1.158` | Which client IP | **High** — a wrong source address means every mount is denied. Verify from `exportfs -v` plus `journalctl -u nfs-server` on the first denied attempt. |
| A6 | No firewall or VLAN separation between `172.16.1.31` and `172.16.1.158:2049` | Blast radius B-4 | Medium — the mount just fails; diagnosable. |
| A7 | MA add-on is at 2.9.13 (stable channel), not the BETA add-on at 2.10.0rc6 | Route A/B and all API commands | **Medium.** The API command names and the deletion guard exist in both, but 2.10 adds the `scan_errors.incomplete` guard and changes the NFS provider's subfolder handling. Confirm with `ha apps --raw-json` and MA's `/info` endpoint. |
| A8 | MA admin credentials exist and are known, so a long-lived token can be minted | Empirical Protocol Stage 6 | **High** — every assertion in the phase depends on it. If MA has no users, `/setup` must be completed first. **Confirm with the user.** |
| A9 | ZFS evaluates the on-disk NFSv4 ACL against the *squashed* uid for NFS access decisions | Option A vs Option B rationale #2 | Low — with the tree at `0777` both squash targets should read fine. This is an argument for robustness, not a correctness dependency. Stage 4 measures the real behaviour. |
| A10 | `RequiresMountsFor=` will not resolve a ZFS mount, so `After=zfs-mount.service` is the correct ordering lever | Mitigation M2 | Low — if `After=` proves insufficient, `mountpoint` (M1) still guarantees correctness. |
| A11 | `folder_name` is the right `missing_album_artist_action` for this library | The albumartist requirement | Medium — it is a reasoned recommendation, not a measured one. **Needs user confirmation** before it becomes a decision. |
| A12 | Protection mode is still OFF on the HA SSH add-on (last confirmed 2026-07-27) | ha CLI usage | Low — visible immediately as `unauthorized`; fixed in the add-on UI. |
| A13 | HAOS's busybox userland has `showmount` / `nc` | Validation 1d, B-4 | Low — fall back to attempting the mount and reading the error. |
| A14 | MA provider setup can be driven headlessly via `config/providers/setup` + `config/flows/submit` | Empirical Protocol Stage 5 | Medium — the flow's step ids are not documented. The `/api-docs/commands.json` discovery step resolves it; the GUI click path is the stated fallback. |
| A15 | The community claim that failed HA media mounts never self-recover describes an older Supervisor | Where Sources Conflict | Medium — settled by criterion 4b's negative control, which is exactly why that control is mandatory. |

---

## Open Questions

1. **Does the MA provider setup flow run headlessly?**
   - Known: `config/providers/setup` and `config/flows/submit` exist as API commands with
     `Scope.CONFIG_PROVIDERS_WRITE`; `/api-docs/commands.json` is served unauthenticated and
     enumerates every command with its argument schema.
   - Unclear: the intermediate flow step ids for `filesystem_local` and `filesystem_nfs`, which are
     runtime values.
   - Recommendation: the plan runs the `/api-docs/commands.json` discovery *first*. If the flow
     cannot be driven, use the GUI click path in Stage 5 — but only for the initial creation.
     Everything downstream (`config/providers/save`, `music/sync`, `music/albums/library_items`) is
     confirmed headless.

2. **Which three albums?**
   - Criterion 3 says "already-correct albums". Choosing them requires reading the live library,
     which was not possible this session.
   - Recommendation: pick from the Phase 1 QUAL-01 snapshot (9,736 records keyed on `audio_md5`) —
     three albums whose `albumartist` is non-empty, non-`Various Artists`, and whose folder name
     matches the tag. Deliberately choose **one single-artist album, one multi-disc release, and one
     legitimate `Various Artists` compilation** so the album-identity key is exercised in all three
     shapes, not just the easy one. This anticipates QUAL-03's "include the historically painful
     cases" one phase early, at negligible cost.

3. **Does the estate want the M4 boot-time sync automation?**
   - Known: without it, a mount that recovers 15 minutes after boot leaves MA stale until the next
     12-hourly sync.
   - Unclear: whether MA's HA integration exposes a callable sync service, or whether this needs a
     `rest_command` to MA's `POST /api` (which would put an MA token in HA's `secrets.yaml`).
   - Recommendation: defer to a follow-up. Criterion 4 does not require it, and the token-placement
     question deserves its own decision. Record as a deferred idea.

4. **Is `xprtsec=` / RPC-with-TLS worth it here?**
   - Known: `exports(5)` documents it (RFC 9289); it needs `tlshd` configured on both ends.
   - Recommendation: **no**, for a read-only LAN-local music library. Record it as an explicitly
     considered and rejected control so V6 has an answer rather than a silence.

5. **What is atlantis's current export state?**
   - Could not be measured (§ Session Limitation). A2/A3/A4 all hang off it.
   - Recommendation: Stage 0 is a mandatory first task, not a formality.

---

## Sources

### Primary (HIGH confidence)

**Home Assistant Supervisor** — `github.com/home-assistant/supervisor`, `main`, fetched 2026-08-26:
- `supervisor/mounts/mount.py` — `Mount.container_where`, `Mount.options`, `NFSMount.options`,
  `NetworkMount.is_mounted`, `_probe_network_mount`, `ensure_empty_folder`, the layered-timeout
  comment block, `MOUNT_UNIT_TIMEOUT_USEC`, `UPDATE_STATE_TIMEOUT`
- `supervisor/mounts/manager.py` — `_bind_media`, `_bind_mount` and the emergency read-only fallback,
  `reload_mount`, `relocate_local_data`
- `supervisor/mounts/validate.py` — `RE_MOUNT_NAME`, `SCHEMA_MOUNT_NFS`, the `cifs`/`nfs`-only type
  restriction
- `supervisor/mounts/const.py` — `MountType`, `MountUsage`
- `supervisor/docker/app.py:546-577` — the `/media` and `/share` binds with `PropagationMode.RSLAVE`
- `supervisor/docker/const.py:199-200` — `PATH_SHARE`, `PATH_MEDIA`
- `supervisor/core.py:146-189, 212-295` — sequential `setup()` load order; `start()` add-on stages
- `supervisor/misc/tasks.py:46,87` — `RUN_RELOAD_MOUNTS = 900`
- `supervisor/api/mounts.py` — `POST/PUT/DELETE /mounts`, `/mounts/{mount}/reload`

**Home Assistant CLI** — `github.com/home-assistant/cli`, `master`:
- `cmd/mounts.go`, `cmd/mounts_add.go` — the `ha mounts add` flag set including `--read-only`

**Music Assistant server** — `github.com/music-assistant/server`, tag `2.9.13` (installed) and branch
`dev` (2.10.x), fetched 2026-08-26:
- `music_assistant/providers/filesystem_local/__init__.py` — `sync_library()` and its deletion
  guards, `_process_deletions`, `_process_orphaned_albums_and_artists`, `check_write_access`,
  the `album_artists[0].name + os.sep + track_tags.album` item id, `setup()` / `CONF_PATH`
- `music_assistant/providers/filesystem_local/constants.py` — `CONF_ENTRY_MISSING_ALBUM_ARTIST`
  with its three options and `various_artists` default; `CONF_ENTRY_PATH` default `/media`
- `music_assistant/providers/filesystem_nfs/{provider,constants,__init__,manifest.json}` — mount
  options, `SetupFailedError` translation keys, `/tmp/{instance_id}` mount path, the config entries
- `music_assistant/controllers/music/controller.py:373` — `@api_command("music/sync")`
- `music_assistant/controllers/music/constants.py` — `DEFAULT_SYNC_INTERVAL = 12*60`,
  `INITIAL_SYNC_DELAY = 10`, `CONF_RESET_DB`
- `music_assistant/controllers/music/database.py:255-262` — `_reset_database()`
- `music_assistant/controllers/music/media/base.py:195-232` — `music/{type}s/library_items|count|get`
- `music_assistant/constants.py:219-241` — the `DB_TABLE_*` inventory
- `music_assistant/controllers/webserver/controller.py` — `DEFAULT_SERVER_PORT = 8095`, routes
  `POST /api`, `GET /ws`, `GET /api-docs/*`
- `music_assistant/controllers/webserver/helpers/auth_middleware.py` — unauthenticated path list,
  `is_request_from_ingress` socket-level verification
- `music_assistant/controllers/webserver/auth.py` — `auth/login` (`authenticated=False`),
  `auth/token/create`, `TOKEN_LONG_LIVED_EXPIRATION = 365`
- `Dockerfile.base` — `cifs-utils`, `libnfs13`, `nfs-common`

**Music Assistant add-on** — `github.com/music-assistant/home-assistant-addon`, `main`:
- `music_assistant/config.yaml` — version 2.9.13, `map: [media:rw, ssl:ro]`,
  `privileged: [SYS_ADMIN, DAC_READ_SEARCH]`, `apparmor: true`, `host_network: true`,
  `ingress_port: 8094`, `tmpfs: true`, no `startup:` key
- `music_assistant/apparmor.txt` — `mount`, `umount`, `remount`, `capability sys_admin`,
  `capability dac_read_search`, `/media/** rw`
- `music_assistant_beta/config.yaml` — 2.10.0rc6

**Music Assistant documentation** —
`github.com/music-assistant/music-assistant.io`, `src/content/docs/music-providers/local-files.md`
(rendered at https://www.music-assistant.io/music-providers/filesystem/): the `/media` mount
sentence, the album-artist requirement, the NFS/SMB/WebDAV provider configuration, the
`/artist/album` structure guidance, UTF-8 and CIFS-emoji limits, the multi-artist parsing order, and
the "should not be reached over the internet" statement.

**exports(5)** — https://man7.org/linux/man-pages/man5/exports.5.html — `mountpoint`/`mp`, `fsid=`,
`crossmnt`, `nohide` ("not relevant when NFSv4 is use"), `all_squash`, `anonuid`/`anongid` (65534
default), `sec=` (`sys` default), `ro` default, `exportfs -ra`, `/etc/exports.d/*.exports`,
`xprtsec=`.

**This repository** — `infra/{providers,host,variables}.tf`; `CLAUDE.md`; `NETWORK.md`;
`.planning/{PROJECT,REQUIREMENTS,ROADMAP,config.json}`;
`.planning/phases/01-safety-harness-and-freeze-the-writers/{01-08-PLAN,01-08-SUMMARY,01-PATTERNS,01-DISCUSSION-LOG}.md`;
`scripts/check-music-freeze.sh`; `~/.claude/skills/ha-deercrest/SKILL.md`;
`~/.claude/projects/…/memory/MEMORY.md`.

### Secondary (MEDIUM confidence)

- [music-assistant/discussions/1198](https://github.com/orgs/music-assistant/discussions/1198) —
  maintainer @OzGav confirms the HA Settings → Storage → MA "Local Disk" route and dates native NFS
  support to 2.8.0b20 (12 Mar 2026). Maintainer statement, but a discussion thread.
- [wiki.linux-nfs.org — Nfsv4 configuration](https://wiki.linux-nfs.org/wiki/index.php/Nfsv4_configuration)
  — `fsid=0` is no longer recommended; nfsd builds the pseudo-fs automatically. Upstream project
  wiki; corroborated by exports(5)'s wording but not stated there in those terms.
- [Proxmox forum — NFS Server on Proxmox / Terraform](https://forum.proxmox.com/threads/nfs-server-on-proxmox-terraform.127112/)
  and [Export NFS to VMs](https://forum.proxmox.com/threads/export-nfs-to-vms-what-is-the-recommended-practice.104874/)
  — PVE ships `nfs-common` only; `nfs-kernel-server` comes from the Debian archive; the
  `sharenfs`-vs-`/etc/exports` "pick one" guidance.
- [Klara Systems — NFS Shares with ZFS](https://klarasystems.com/articles/nfs-shares-with-zfs/) and
  OpenZFS `sharenfs` documentation — `/etc/exports.d/zfs.exports` is generated and must not be
  hand-edited; `zfs-share.service` regenerates it at boot; the nfs-server-before-pool-import
  ordering hazard.

### Tertiary (LOW confidence — flagged, not relied upon)

- [community.home-assistant.io — NFS after reboot when server is down](https://community.home-assistant.io/t/nfs-after-reboot-when-server-is-down/894095)
  and [Media mount on nas keeps disconnecting on reboot](https://community.home-assistant.io/t/media-mount-on-nas-keeps-disconnecting-on-reboot/611340)
  — the "never recovers until reboot" and "media mounts behave differently from backup mounts"
  reports. **Contradicted** on the first point by current Supervisor source
  (`RUN_RELOAD_MOUNTS = 900`); plausibly explained on the second (`backup` mounts have no
  `container_where` and so never enter the emergency bind path). Treated as describing an older
  Supervisor and settled empirically by criterion 4b's negative control, not by argument.
- Community `nofail`/`bg` mount-option advice for HAOS — **not applicable**; the Supervisor mounts
  API has no user-supplied options field.
- The claim that the MA container lacks NFS tooling — **disproven** by `Dockerfile.base`.

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Route A vs Route B resolution | **HIGH** | Both sides read at source; the apparent contradiction explained by a schema restriction (`cifs`/`nfs` only, no `bind`) that makes both statements literally true; corroborated by a maintainer statement. |
| The `rslave` propagation mechanism | **HIGH** | `supervisor/docker/app.py:568-577`, explicit. |
| Reboot-race characterisation | **HIGH** | Traced end to end through `core.py` → `mounts/manager.py` → `filesystem_local/__init__.py`; the emergency empty-dir bind and the empty-scan guard are both explicit in source, with the exact log strings to assert on. |
| MA purge behaviour | **HIGH** | Read at the installed tag (2.9.13) *and* `dev`. Corrects a ROADMAP premise. |
| `albumartist` requirement + fallbacks | **HIGH** | Documented verbatim and confirmed in `constants.py`; the album-identity key found in source. |
| Sync cadence and on-demand trigger | **HIGH** | Named constants and the registered API command. |
| Export options | **HIGH** | Every option quoted from `exports(5)`. `mountpoint` is the material addition to CLAUDE.md's candidates. |
| `fsid=` absence | **MEDIUM-HIGH** | linux-nfs.org wiki is upstream but a wiki; several dated sources still say the opposite. Verified in Stage 2 by an actual client mount. |
| Terraform pattern | **HIGH** | The repo's own `host.tf` is the analog; the `triggers` gap in it is a real trap and is called out. |
| ZFS NFSv4-ACL evaluation for a squashed uid | **MEDIUM** | Reasoned, not measured. Not correctness-critical at `0777`. |
| Live estate preconditions | **LOW** | No estate access this session. All `[ASSUMED]`; Stage 0 measures them. |
| MA headless provider setup | **MEDIUM** | The API commands exist; the flow step ids are runtime values. Discovery step + GUI fallback specified. |

**Research date:** 2026-08-26
**Valid until:** 2026-09-25 (30 days). Shorter for anything version-pinned: Music Assistant ships
prereleases daily (2.10.0rc6 on 2026-08-25, a `.dev` build on 2026-08-26), so re-verify the MA
findings against the installed version if the add-on updates before execution.
