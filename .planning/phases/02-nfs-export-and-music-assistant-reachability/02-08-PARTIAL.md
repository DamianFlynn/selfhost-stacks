---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 08
subsystem: infra
status: partial
halted_at: "Task 2 — Positive reboot (criterion 4a), blocking human checkpoint (D-36)"
tags: [music-assistant, home-assistant, cons-03, criterion-4, m4, d-34, d-54, d-38, d-36, rest-command, mount-failed, reboot-race]

requires:
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-07's proven criterion 3 (three albums exact-matched, provider-attributed); 02-06's filesystem_local--XJaJWNUS provider; 02-05's live Supervisor NFS mount at /media/music; 02-04's check-music-consumers.sh"

provides:
  - "M4 SHIPPED AND PROVEN END-TO-END — the rest_command route D-34 gated on is verified working, by MA's own sync task record moving, not by an HTTP status"
  - "A dedicated, independently-revocable MA long-lived token for M4, held only as a !secret on the NUC"
  - "D-54's alerting built — a mount-content detector that matches the ACTUAL failure mode plus the literal Supervisor repairs-issue wire"
  - "D-38 read back and confirmed: all four Filesystem sync tasks still on the 12-hour default"
  - "The pre-reboot baseline and both reboots' evidence-capture commands, staged copy-pasteable"

affects:
  - "02-08 continuation — Tasks 2 and 3 are the operator's reboots; everything they need is staged below"
  - "02-09 — the exact HA YAML below is what beets.md must carry (D-47); MA's auth/token/create corrects a claim in 02-04's record"

tech-stack:
  added:
    - "Home Assistant `rest_command` integration (new domain on this NUC — required a core restart)"
    - "Home Assistant `command_line` sensor integration (new domain on this NUC)"
  patterns:
    - "Verify the transport by watching the DESTINATION's own state change, never by the HTTP status the caller got back"
    - "Detect the failure state, not the failure event: /media/music present-but-empty is the failure, so 'does the path exist' is exactly the check that returns a false green"

key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-PARTIAL.md"
  modified: []
  off-repo:
    - "/config/packages/music02_ma_nfs_mount.yaml on the NUC (new — full text reproduced below)"
    - "/config/secrets.yaml on the NUC (one key added: ma_ha_sync_authorization; backup at /config/secrets.yaml.bak.20260901T104546Z)"

key-decisions:
  - "MA 2.11 DOES have a long-lived token API — `auth/token/create`, 1 year, no auto-renew, individually revocable by token_id. Prior phase records say MA 2.11 has no API token; that is true of the UI and false of the API. M4 therefore gets a genuinely separate credential rather than a second JWT off the same login"
  - "MA rejects a bare token in Authorization (`Authentication required`). The secret holds the COMPLETE header value, `Bearer <token>`, because rest_command headers take neither a template nor a concatenation"
  - "The HA config went into /config/packages/, matching the estate's 29-file convention, NOT into configuration.yaml. This makes the plan's literal `grep -c rest_command /config/configuration.yaml` check wrong; a duplicate top-level key would be a hard YAML conflict with the package, so there is no way to satisfy both"
  - "D-54 ships as ONE file with FOUR automations, not two files. M4's sync and the mount alerting are the same concern — the NFS mount's lifecycle — and one file is one thing to find during a rebuild"
  - "M4 got a SECOND trigger the plan did not ask for: re-sync when the mount returns. homeassistant_started alone only covers a reboot where the mount came back immediately; the window M4 exists to close is the other one"

requirements-completed: []
requirements-carried: [CONS-03]

metrics:
  duration: "~110 min to the checkpoint"
  halted: 2026-09-01
  tasks_completed: 1
  tasks_total: 3
---

# Phase 02 Plan 08: Reboot Resilience — PARTIAL (halted at the first blocking checkpoint)

**This record is deliberately `-PARTIAL.md`, not `-SUMMARY.md`.** `phase-plan-index` marks a plan
complete on that filename's existence alone and never reads `status:` frontmatter. A `-SUMMARY.md`
here would silently skip the two reboot tasks forever.

**Task 1 is complete and M4 is proven.** Tasks 2 and 3 are blocking human checkpoints (D-36): both
reboot the house's automation hub, which is also the estate's second Tailscale subnet router.
Nothing was rebooted.

## Status

| Task | Disposition |
|------|-------------|
| Task 1 — verify the `rest_command`, build M4 and D-54's alert | **Complete, PASS.** M4 shipped and proven end-to-end, not deferred. |
| Task 2 — positive reboot, criterion 4a | **Not started — blocking human checkpoint.** Baseline captured, commands staged. |
| Task 3 — negative control, criterion 4b | **Not started — blocking human checkpoint.** Evidence set selected (Route A), commands staged. |

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | *(none — `<files>none in-repo</files>`)* | HA configuration lives at `/config/` on the NUC. Same precedent as 02-05 Tasks 1/2/3, 02-06 Task 1 and 02-07 Task 1. Stated so the absence is not read as skipped work. |

---

## TASK 1 — M4 IS VERIFIED WORKING, NOT DEFERRED

### The gate D-34 set, and how it was answered

D-34 required the `rest_command` route to be proven **before** anything was built on it, and
RESEARCH.md rated M4 only MEDIUM confidence precisely because that route was unverified. It is now
verified, and the proof is MA's own task record — not an HTTP status.

`ha core restart` returned at `12:17:43Z`. The `homeassistant.start` trigger fired at `12:17:39Z`
(HA's own `last_triggered` on the automation). The automation waits 120 s. Music Assistant's
`Sync Tracks for Filesystem (local disk)` task then moved:

```
before   status=partial_success   started_at=2026-09-01T10:05:43.805042+00:00   <- 02-07's deliberate sync
after    status=success           started_at=2026-09-01T12:19:39.340638+00:00   <- M4
```

`12:17:39Z + 120 s = 12:19:39Z`, to the second. Nothing else could have caused it: MA's own
schedule for that task is 12-hourly and it last ran at `10:05`, and the MA add-on was not
restarted at any point. **The HTTP status was never used as evidence.**

Polled every 15 s from `12:18:04Z` to `12:27:56Z` (transcript in the task log). The sync completed
inside one 15 s window — a delta re-scan with nothing changed, against 02-07's 177 s full scan of
875 files.

Note it came back `success` where 02-07's full sync was `partial_success`. The `Def Leppard (2015)`
empty-album-artist error did not recur, consistent with a delta scan skipping unchanged files. The
defect is unrepaired and still owned by Phase 7; this is not evidence it went away.

### Registration, read back from HA

```
rest_command services registered:   music_assistant_sync_local, reload
sensor.music_library_nfs_mount:     state=13  unit=folders  last_updated=2026-09-01T12:17:32Z

automation.music_re_sync_music_assistant_120_s_after_home_assistant_starts
    id=music02_ma_sync_after_ha_start        state=on  last_triggered=2026-09-01T12:17:39.331664+00:00
automation.music_re_sync_music_assistant_when_the_nfs_library_mount_returns
    id=music02_ma_sync_on_mount_restored     state=on  last_triggered=null
automation.music_nfs_library_mount_failed_or_is_empty
    id=music02_nfs_mount_failed_alert        state=on  last_triggered=null
automation.music_supervisor_raised_a_system_issue
    id=music02_supervisor_issue_raised       state=on  last_triggered=null
```

`ha core check` → `Command completed successfully.`

`rest_command.reload` is registered, so future edits to the call itself do **not** need another core
restart. Adding the `rest_command:` and `command_line:` domains did, because neither existed on this
NUC before and `homeassistant.reload_all` only reloads domains already set up.

### The token — a genuinely separate credential, and a correction to the record

**Correction, measured 2026-09-01:** MA 2.11 **does** have a long-lived token API. 02-04 recorded
"MA 2.11 has no API-token UI" and that is correct; the inference that no separate token was
obtainable is not. `/api-docs/commands.json` carries `auth/token/create`, `auth/tokens` and
`auth/token/revoke`:

```
auth/token/create  "Create a new long-lived access token for current user or another user (admin only).
                    Long-lived tokens are intended for external integrations and API access.
                    They expire after 1 year and do NOT auto-renew on use."
                   parameters: name (required), user_id (optional, admin only)
auth/token/revoke  parameters: token_id (required)
```

So M4 got a real second credential, not a second JWT off the same login:

```
minted     2026-09-01
name       "HA M4 music sync (phase 02-08)"
lifetime   1 year, no auto-renew
proof      auth/me with that token alone -> {"username":"damian","role":"admin"}
storage    /config/secrets.yaml on the NUC, key ma_ha_sync_authorization
backup     /config/secrets.yaml.bak.20260901T104546Z (taken before the write)
written    over ssh stdin, never argv
length     403 chars minted, 403 chars stored (asserted equal — no truncation)
```

It is **separate from the audit script's credential** in `/mnt/fast/secrets/ma-deercrest.env` on
LXC 100 (which stores username+password and mints a fresh session per run, D-39's intent). Either
can be replaced without breaking the other: revoke this one with
`{"command":"auth/token/revoke","args":{"token_id":"..."}}`, list ids with `auth/tokens`.

**MA rejects a bare token.** Measured three ways in one second:

```
Authorization: <token>          ->  "Authentication required"
Authorization: Bearer <token>   ->  {"user_id":"...","username":"damian","role":"admin",...}
{"command":"auth/me","token":"<token>"}  (in the body)  ->  "Authentication required"
```

`rest_command` headers accept neither a template nor a concatenation, so the secret holds the
**complete header value** (`Bearer <token>`) and is named `ma_ha_sync_authorization` to say so.

### Secret hygiene (T-02-05)

| Assertion | Result |
|---|---|
| `grep -cE '(eyJ[A-Za-z0-9_-]{10,}\|Bearer [A-Za-z0-9._-]{20,})' /config/configuration.yaml` | **0** |
| same pattern in `/config/packages/music02_ma_nfs_mount.yaml` | **0** |
| `grep -c '!secret'` in the package file | 2 (one live reference, one in the header prose) |
| `git grep -nE 'rest_command\|!secret'` outside `.planning/` | **(none)** |
| `git grep -nE 'eyJ[A-Za-z0-9_-]{20,}\|Bearer [A-Za-z0-9._-]{20,}'` anywhere tracked | **(none)** |
| `git grep -n 'ma_ha_sync'` | **(none)** |

The token never entered this repository, never entered a local file, and never appeared in argv.

### D-38 — `sync_interval` untouched, read back

All four Filesystem sync tasks, read from `tasks/list` after M4 ran:

```
Sync Tracks for Filesystem (local disk)      schedule {"type":"hourly","every":12}
Sync Playlists for Filesystem (local disk)   schedule {"type":"hourly","every":12}
Sync Albums for Filesystem (local disk)      schedule {"type":"hourly","every":12}
Sync Artists for Filesystem (local disk)     schedule {"type":"hourly","every":12}
```

M5 stays rejected. Nothing in this plan wrote to MA's configuration.

### D-54 — one file, four automations, and an honest statement of what is not proven

Shipped as **one YAML addition, not two** (the discretion D-54 leaves open). M4's sync and the mount
alerting are the same concern — the NFS mount's lifecycle — and one file is one thing to find during
a rebuild.

**The detector matches the actual failure mode.** The failure is not "`/media/music` is missing" —
Supervisor bind-mounts an *empty read-only directory* there, so the path exists and is a directory.
Anything that checks for existence returns a false green. `sensor.music_library_nfs_mount` counts
top-level entries: **13** healthy, **0** under the emergency bind, `unknown` when the soft NFS mount
errors out (`softerr,timeo=100,retrans=2`, confirmed in the live mount options below).

Verified without raising a false alarm on the operator's phone:

```
notify.mobile_app_crusader registered                       PRESENT
failure message template renders  -> "/media/music has 13 artist folders (expected 13). Music
                                      Assistant will still list the albums but none of them will play."
recovery message template renders -> "/media/music is back (13 artist folders) and Music Assistant
                                      has been told to re-sync."
```

That closes both silent-failure modes of an HA notification — a missing notify service and a
template that throws. **What is NOT yet proven is the trigger firing against a real fault**; see
deviation 3. The operator's Task 3 negative control exercises it for real, and the staged commands
below capture it.

**A stated limitation, not hidden.** The `repairs_issue_registry_updated` event carries only
`{action, domain, issue_id}`; `issue_id` is an opaque Supervisor UUID and `translation_key` — the
stable `issue_mount_mount_failed` string — is not reachable from a template. So the repairs-issue
automation cannot be narrowed to mount failures and fires on **any** new `hassio`-domain issue. That
is deliberate: there are two such issues in the whole registry
(`issue_addon_detached_addon_removed`, `issue_system_reboot_required`), both raised at some point
with nobody noticing, which is itself the argument for the alert.

---

## THE EXACT HA YAML — `/config/packages/music02_ma_nfs_mount.yaml`

Reproduced verbatim so a NUC rebuild can restore it. The token appears only as its `!secret`
reference. 02-09 carries this into `beets.md` per D-47.

```yaml
# ============================================================================
# Music Assistant — NFS library mount: recovery sync (M4) + failure alerting
# ============================================================================
# Repo:    damianflynn/selfhost-stacks — "Music Library Consolidation"
# Phase:   02 nfs-export-and-music-assistant-reachability, plan 02-08
# Created: 2026-09-01
#
# WHY THIS FILE EXISTS
#   /media/music is an NFS mount of tank/media/Music on atlantis (172.16.1.158),
#   created by HA Supervisor (Settings > System > Storage, usage media,
#   read-only) and propagated rslave into the Music Assistant add-on container.
#
#   If atlantis is unreachable inside Supervisor's <=40 s mount window at boot,
#   Supervisor does NOT leave /media/music absent. It creates an EMPTY read-only
#   directory (/mnt/data/supervisor/emergency/music) and bind-mounts THAT there
#   instead. Music Assistant then finds a path that exists and is a directory,
#   loads normally, scans zero files, and its empty-scan deletion guard preserves
#   the library in a STALE state: every album still listed, none of them
#   playable. Supervisor retries the real mount every 900 s, but MA only re-reads
#   the tree on its next sync — up to 12 hours later (sync_interval stays at the
#   12 h default deliberately; shortening it was considered and rejected as M5).
#
#   M4 below collapses that staleness window from <=12 h to ~2 minutes.
#   D-54 below makes the failure say something instead of sitting silent. This
#   estate has had dispatcharr and teleport down for six weeks and podsync's
#   yt-dlp broken for thirteen months; in both cases nothing said anything.
#
# WHY IT IS NOT IN THE REPO
#   Home Assistant configuration lives at /config/ on the NUC and selfhost-stacks
#   contains no HA config at all. The record of this file is
#   .planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-*.md
#   and stacks/selfhosted/arrs/beets.md. The token is a !secret and must NEVER be
#   committed — that repo is public and has one prior credential exposure.
#
# ROTATING THE TOKEN
#   secrets.yaml key: ma_ha_sync_authorization — holds the COMPLETE header value
#   ("Bearer <token>"), because Music Assistant rejects a bare token with
#   "Authentication required" (measured 2026-09-01).
#   Minted 2026-09-01 via MA `auth/token/create`, name
#   "HA M4 music sync (phase 02-08)", 1 year, no auto-renew.
#   SEPARATE from the audit-script credential in /mnt/fast/secrets/ma-deercrest.env
#   on LXC 100, so either can be replaced without breaking the other.
#     list:   {"command": "auth/tokens"}
#     revoke: {"command": "auth/token/revoke", "args": {"token_id": "..."}}
#
# PINNED VALUES — these are identities, not settings. Changing them silently
# breaks the automation without any error:
#   provider instance  filesystem_local--XJaJWNUS   (MA local filesystem provider)
#   MA endpoint        http://172.16.1.31:8095/api  (add-on, LAN IP of this NUC)
#   MA version proven  2.11.0b0 (BETA, auto_update on — stamp every assertion)
# ============================================================================

# ---------------------------------------------------------------------------
# M4 — the sync call itself.
# MA exposes no sync service to the Home Assistant integration, so this has to
# be a rest_command against MA's POST /api. That route was research-flagged as
# unverified; it is verified working as of 2026-09-01 (see 02-08 SUMMARY).
# ---------------------------------------------------------------------------
rest_command:
  music_assistant_sync_local:
    url: "http://172.16.1.31:8095/api"
    method: post
    content_type: "application/json"
    headers:
      Authorization: !secret ma_ha_sync_authorization
    payload: >-
      {"command": "music/sync",
       "args": {"providers": ["filesystem_local--XJaJWNUS"],
                "media_types": ["track"]}}
    timeout: 30

# ---------------------------------------------------------------------------
# D-54 — the detector.
#
# Counting entries under /media/music is the detector that matches the ACTUAL
# failure mode. In the failure the path exists and is a directory — it is simply
# EMPTY — so "does /media/music exist" is exactly the check that returns a false
# green. 13 top-level artist folders healthy, 0 when the emergency bind is in
# place, unknown when the NFS server is gone and the soft-mount errors out.
#
# This runs in the HA Core container, which receives the same /media bind.
# ---------------------------------------------------------------------------
command_line:
  - sensor:
      name: "Music library NFS mount"
      unique_id: music02_music_library_nfs_mount
      command: "ls -1 /media/music 2>/dev/null | wc -l"
      unit_of_measurement: "folders"
      scan_interval: 300
      command_timeout: 20

automation:
  # -------------------------------------------------------------------------
  # M4a — boot recovery. Supervisor mounts before add-ons start, so by the time
  # HA is up the mount has either succeeded or fallen back to the empty
  # emergency directory. 120 s gives Supervisor's mount work room to settle
  # before a sync is asked for.
  # -------------------------------------------------------------------------
  - id: music02_ma_sync_after_ha_start
    alias: "Music: re-sync Music Assistant 120 s after Home Assistant starts"
    description: >-
      M4. Collapses the post-reboot staleness window from <=12 h (MA's default
      sync_interval) to ~2 min. Harmless when the mount is healthy — it is a
      read-only re-scan of a 34 GB tree, ~3 min wall clock, against a ro export.
    mode: single
    triggers:
      - trigger: homeassistant
        event: start
    conditions: []
    actions:
      - delay: "00:02:00"
      - action: rest_command.music_assistant_sync_local

  # -------------------------------------------------------------------------
  # M4b — recovery after Supervisor's 900 s mount reload.
  #
  # M4a alone only covers a reboot where the mount came back immediately. The
  # window M4 actually exists to close is the other one: the mount failed at
  # boot, Supervisor re-mounted it up to 15 min later, and MA is still holding a
  # stale library because its next scheduled sync is hours away. Without this,
  # that case still waits <=12 h.
  # -------------------------------------------------------------------------
  - id: music02_ma_sync_on_mount_restored
    alias: "Music: re-sync Music Assistant when the NFS library mount returns"
    description: >-
      Fires when the folder count goes from 0/unknown back to a real value —
      i.e. Supervisor's 900 s reload replaced the empty emergency bind with the
      real export. Also says so, because an alert that never reports recovery
      teaches people to ignore it.
    mode: single
    triggers:
      - trigger: numeric_state
        entity_id: sensor.music_library_nfs_mount
        above: 0
    conditions:
      - condition: template
        value_template: >-
          {{ trigger.from_state is not none
             and (trigger.from_state.state in ['0', 'unknown', 'unavailable']) }}
    actions:
      - action: rest_command.music_assistant_sync_local
      - action: notify.mobile_app_crusader
        data:
          title: "Music library mount recovered"
          message: >-
            /media/music is back ({{ states('sensor.music_library_nfs_mount') }}
            artist folders) and Music Assistant has been told to re-sync.
          data:
            push:
              sound:
                name: default
            interruption-level: active

  # -------------------------------------------------------------------------
  # D-54a — the failure alert that matches the real failure state.
  # -------------------------------------------------------------------------
  - id: music02_nfs_mount_failed_alert
    alias: "Music: NFS library mount failed or is empty"
    description: >-
      D-54. /media/music present but empty is Supervisor's emergency read-only
      bind, and it is indistinguishable from a healthy mount to anything that
      only checks the path exists. 5 minutes of it is a real fault, not a blip.
    mode: single
    triggers:
      - trigger: numeric_state
        entity_id: sensor.music_library_nfs_mount
        below: 1
        for: "00:05:00"
      - trigger: state
        entity_id: sensor.music_library_nfs_mount
        to:
          - "unknown"
          - "unavailable"
        for: "00:05:00"
    conditions: []
    actions:
      - action: notify.mobile_app_crusader
        data:
          title: "Music library mount is down"
          message: >-
            /media/music has {{ states('sensor.music_library_nfs_mount') }}
            artist folders (expected 13). Music Assistant will still list the
            albums but none of them will play. Check nfs-server on atlantis
            (172.16.1.158). Supervisor retries every 15 min on its own.
          data:
            push:
              sound:
                name: default
            interruption-level: active

  # -------------------------------------------------------------------------
  # D-54b — the literal Supervisor repairs-issue wire.
  #
  # MOUNT_FAILED reaches Home Assistant as a repairs issue in the `hassio`
  # domain with translation_key `issue_mount_mount_failed`. LIMITATION, stated
  # rather than hidden: the repairs_issue_registry_updated event carries only
  # {action, domain, issue_id}, the issue_id is an opaque Supervisor UUID, and
  # translation_key is not reachable from a template — so this cannot be
  # narrowed to mount failures alone. It therefore fires on ANY new hassio-domain
  # repairs issue. That is deliberate: hassio issues are rare (2 in the registry
  # on 2026-09-01, both raised at some point with nobody noticing) and all of
  # them are worth knowing about. music02_nfs_mount_failed_alert above is the
  # precise, mount-specific detector; this one is the broad safety net.
  # -------------------------------------------------------------------------
  - id: music02_supervisor_issue_raised
    alias: "Music: Supervisor raised a system issue"
    description: >-
      D-54's MOUNT_FAILED wire. Broad by necessity — see the comment above.
    mode: queued
    max: 10
    triggers:
      - trigger: event
        event_type: repairs_issue_registry_updated
        event_data:
          action: create
          domain: hassio
    conditions: []
    actions:
      - action: notify.mobile_app_crusader
        data:
          title: "Supervisor raised a system issue"
          message: >-
            Home Assistant Supervisor raised a new repairs issue
            ({{ trigger.event.data.issue_id }}). If the music library is
            involved this is MOUNT_FAILED — check Settings > System > Repairs.
          data:
            push:
              sound:
                name: default
            interruption-level: active
```

`/config/secrets.yaml` gained exactly one key. Its value is **not** reproduced anywhere:

```yaml
# Music Assistant long-lived API token for the M4 mount-recovery sync automation.
# Stored as the complete Authorization header value: MA rejects a bare token.
# Minted 2026-09-01 via MA auth/token/create, name "HA M4 music sync (phase 02-08)", 1-year expiry.
# SEPARATE from the audit script credential in /mnt/fast/secrets/ma-deercrest.env on LXC 100,
# so either can be revoked (auth/token/revoke) without breaking the other.
ma_ha_sync_authorization: Bearer <REDACTED — lives only on the NUC>
```

---

## THE PRE-REBOOT BASELINE — captured 2026-09-01T12:31:56Z

This is the "before" half of criterion 4a. **The album count is the number to compare against.**

### Music Assistant (`2.11.0b0`, BETA, `auto_update: true`)

```
provider-filtered album count, filesystem_local--XJaJWNUS      70
   (music/albums/library_items with provider set — NEVER music/albums/count,
    which has no provider parameter and reports 87 off Spotify's catalogue)

three proof albums, exact on name AND artists[0].name:
   Lifelines          / Chris Norman   ->  EXACT MATCH
   The Ultimate Hits  / Garth Brooks   ->  EXACT MATCH
   Mastermix Essential Hits - Pop 4 - 2005-2009 / Various Artists
                                       ->  scope=temp-export, out of scope since 02-07's teardown

provider status    loaded / enabled=true / last_error=null
missing_album_artist_action.value   folder_name      (conditional — 02-07's finding stands)
```

### The NUC

```
ha mounts info
  {"name":"music","server":"172.16.1.158","path":"/mnt/tank/media/Music","usage":"media",
   "read_only":true,"state":"active","user_path":"/media/music"}

mount | grep -c emergency/                     0

/proc/self/mountinfo, /media/music:
  2002 2115 0:248 / /media/music ro,relatime master:1105 - nfs4
  172.16.1.158:/mnt/tank/media/Music ro,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,
  softerr,softreval,fatal_neterrors=none,proto=tcp,timeo=100,retrans=2,sec=sys,
  clientaddr=172.16.1.31,local_lock=none,addr=172.16.1.158

  ^ softerr,timeo=100,retrans=2 is Supervisor's own NFSMount.options, exactly as the research
    read it from source. It is why a dead server produces an ERROR rather than a hang, and why
    sensor.music_library_nfs_mount goes `unknown` rather than freezing.

uptime                    up 14 days, 4:27
boot_id                   b86dada0-931d-4130-853b-19b2a0b9852a   <- MUST CHANGE after each reboot
sensor.music_library_nfs_mount             13 folders
supervisor log, "read-only fallback"       0 occurrences
MA add-on log, "Aborting sync"             0 occurrences
hassio repairs issues                      issue_addon_detached_addon_removed,
                                           issue_system_reboot_required
```

### atlantis (`172.16.1.158`), precondition per `.continue-here.md`

```
uptime -s                                     2026-08-31 18:48:08   (unmoved)
/proc/pressure/io  full avg300                0.25                  (the halt was 96.22)
dmesg | grep -c amdgpu_hmm_invalidate_gfx     0
systemctl is-active nfs-server                active
```

### `check-music-consumers.sh` from LXC 100 — exit **0**

`scp`'d in, run, then removed (verified absent) — `git pull` there still cannot land it.

```
MA version (live):           2.11.0b0   (assertions proven at 2.11.0b0)
pinned provider instance:    filesystem_local--XJaJWNUS
albums matched in MA:        2   (target 2, exact name+albumartist, provider-attributed)
MA out-of-scope:             1   (scope=temp-export, no temp provider pinned — reported)
albums matched in Jellyfin:  2   (target 2, exact name+albumartist)
MA albums, local provider:   70   (target >= 3)
FAILURES total:              0
PRE_REBOOT_EXIT=0
```

---

## STAGED — the exact commands for both reboots

Every command below is copy-pasteable. `$SSH` is the ha-deercrest pattern:

```bash
. ~/.claude/secrets/ha-deercrest.env
SSH="ssh -i $HA_SSH_KEY -o StrictHostKeyChecking=no -o BatchMode=yes -p $HA_SSH_PORT $HA_SSH_USER@$HA_TAILNET_HOST"
```

Use `$HA_TAILNET_HOST` (`100.73.196.51`), **not** `172.16.1.31`, from any tailnet vantage: while the
NUC is the standby subnet router its own LAN IP is unreachable from the tailnet.

### Before either reboot — silence the estate's own restart pager

`res02_unexpected_restart_alert` pages **both phones** on every HA start unless the maintenance
flag is set. It auto-clears after 2 h.

```bash
curl -s -X POST -H "Authorization: Bearer $(cat $HA_TOKEN_FILE)" -H "Content-Type: application/json" \
  -d '{"entity_id":"input_boolean.ha_maintenance_window"}' \
  "$HA_TAILNET_URL/api/services/input_boolean/turn_on"
```

### TASK 2 — positive reboot (criterion 4a)

```bash
# 1. Reboot. NOTHING ELSE. No remount, no `ha mounts reload`, no add-on restart,
#    no hand-triggered sync — the point of criterion 4 is what happens without you.
$SSH -n "bash -lc 'ha host reboot'"

# 2. Wait for it to return (~2-4 min), then prove the reboot actually happened:
$SSH -n "uptime; cat /proc/sys/kernel/random/boot_id"
#    boot_id MUST differ from b86dada0-931d-4130-853b-19b2a0b9852a

# 3. The four assertions.
$SSH -n "bash -lc 'ha mounts info --raw-json'" | jq -c '.data.mounts[]|select(.name=="music")|{state,read_only}'
#    expect {"state":"active","read_only":true}
$SSH -n "mount | grep -c emergency/music"
#    expect 0
curl -s -H "Authorization: Bearer $(cat $HA_TOKEN_FILE)" \
  "$HA_TAILNET_URL/api/states/sensor.music_library_nfs_mount" | jq -c '{state}'
#    expect {"state":"13"}

# 4. MA: album count must equal 70, and both library albums must exact-match.
. ~/.claude/secrets/music-assistant.env
TOK=$(jq -n --arg u "$MA_USERNAME" --arg p "$MA_PASSWORD" \
  '{command:"auth/login",args:{username:$u,password:$p}}' \
  | curl -s -X POST "$MA_TAILNET_URL/api" -H "Content-Type: application/json" --data-binary @- \
  | jq -r .access_token)
jq -n '{command:"music/albums/library_items",args:{provider:"filesystem_local--XJaJWNUS",limit:2000}}' \
  | curl -s -X POST "$MA_TAILNET_URL/api" -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOK" --data-binary @- \
  | jq 'length, ([.[]|{n:.name,a:(.artists[0].name//"")}] as $L
        | [["Lifelines","Chris Norman"],["The Ultimate Hits","Garth Brooks"]]
        | map(. as [$n,$a] | "\($n) / \($a) -> " + (if ($L|any(.n==$n and .a==$a)) then "EXACT" else "MISS" end)))'
#    expect 70, then two EXACT
#    DO NOT use music/albums/count — it has no provider parameter and reads off Spotify.

# 5. M4a should have fired on its own ~120 s after HA started. Confirm, do not trigger:
curl -s -H "Authorization: Bearer $(cat $HA_TOKEN_FILE)" \
  "$HA_TAILNET_URL/api/states/automation.music_re_sync_music_assistant_120_s_after_home_assistant_starts" \
  | jq -c '{state,last_triggered:.attributes.last_triggered}'

# 6. The audit script. scp in, run, remove.
scp scripts/check-music-consumers.sh root@172.16.1.159:/mnt/fast/stacks/scripts/
ssh -n root@172.16.1.159 "cd /mnt/fast/stacks && bash scripts/check-music-consumers.sh; echo POST_REBOOT_EXIT=\$?"
ssh -n root@172.16.1.159 "rm -f /mnt/fast/stacks/scripts/check-music-consumers.sh"
```

**Expect this to pass, and record that passing proves nothing on its own.** atlantis is healthy, so
the mount simply succeeds and the race is never exercised. A green 4a is fully consistent with the
guards being completely broken. Task 3 is the reason.

### TASK 3 — negative control (criterion 4b)

**Route A won in 02-05, so D-25's re-characterisation clause does NOT fire and `mount | grep
emergency/music` IS available as a proof line.** The Route A evidence set — selected before running
anything, as D-25 requires:

1. `emergency/music` present in `mount`
2. Supervisor's `failed to mount, mounting read-only fallback`
3. MA's `Aborting sync … scan found no files but N were previously indexed`

**All three. Fewer than three means the control did not fire and the test proved nothing** — record
it as *not fired, inconclusive*, never as a pass.

```bash
# 0. Before value (should still be 70 — re-read it, do not assume):
#    ... same MA block as Task 2 step 4 ...

# 1. Break it, server-side.
ssh -n root@172.16.1.158 'systemctl stop nfs-server; systemctl is-active nfs-server'

# 2. Reboot the NUC.
$SSH -n "bash -lc 'ha host reboot'"

# 3. After it returns — capture ALL THREE, verbatim, ANSI-stripped:
$SSH -n "mount | grep emergency/music"                                  | sed 's/\x1b\[[0-9;]*m//g'
$SSH -n "bash -lc 'ha supervisor logs'" | grep -i 'read-only fallback'   | sed 's/\x1b\[[0-9;]*m//g'
$SSH -n "bash -lc 'ha apps logs d5369777_music_assistant_beta'" \
        | grep -i 'Aborting sync'                                        | sed 's/\x1b\[[0-9;]*m//g'
#    Record N from the MA line.

#    Fourth, free, and this estate's own detector — it should have gone to 0:
curl -s -H "Authorization: Bearer $(cat $HA_TOKEN_FILE)" \
  "$HA_TAILNET_URL/api/states/sensor.music_library_nfs_mount" | jq -c '{state}'
#    and after 5 minutes of that, music02_nfs_mount_failed_alert should have paged.
#    THIS IS THE ONLY LIVE TEST D-54's TRIGGER GETS — capture last_triggered:
for a in music_nfs_library_mount_failed_or_is_empty music_supervisor_raised_a_system_issue; do
  curl -s -H "Authorization: Bearer $(cat $HA_TOKEN_FILE)" \
    "$HA_TAILNET_URL/api/states/automation.$a" | jq -c '{e:.entity_id,last_triggered:.attributes.last_triggered}'
done

# 4. Prove MA did NOT purge — the deletion guard working:
#    ... same MA block ... expect STILL 70. Equal to the before value is the assertion.

# 5. Restore, and DO NOT TOUCH THE NUC.
date -u +%H:%M:%SZ    # <- t0, record it
ssh -n root@172.16.1.158 'systemctl start nfs-server; systemctl is-active nfs-server'

#    Now wait out Supervisor's ~900 s reload. No `ha mounts reload`, no add-on restart,
#    no manual mount. This wait IS the experiment — it is the half the community reports
#    dispute against current Supervisor source, and only this settles it on this estate.
#    Poll read-only, every 60 s, and record the elapsed time to state=active:
while :; do
  echo "$(date -u +%H:%M:%SZ) $($SSH -n "bash -lc 'ha mounts info --raw-json'" \
    | jq -r '.data.mounts[]|select(.name=="music")|.state')"
  sleep 60
done

# 6. After it goes active:
$SSH -n "mount | grep -c emergency/music"    # expect 0
#    M4b should have re-synced MA on its own when the folder count came back — check it
#    BEFORE triggering anything by hand, because an automatic recovery is a stronger result:
curl -s -H "Authorization: Bearer $(cat $HA_TOKEN_FILE)" \
  "$HA_TAILNET_URL/api/states/automation.music_re_sync_music_assistant_when_the_nfs_library_mount_returns" \
  | jq -c '{last_triggered:.attributes.last_triggered}'
#    Only if it did NOT fire, trigger a sync by hand:
#      jq -n '{command:"music/sync",args:{providers:["filesystem_local--XJaJWNUS"],media_types:["track"]}}' | ...

# 7. Re-assert the three albums, then the audit script, then confirm the estate is whole:
ssh -n root@172.16.1.158 'systemctl is-active nfs-server'    # MUST be active at plan close
bash scripts/check-music-freeze.sh; echo FREEZE_EXIT=$?
```

**Do not conflate this with M1.** Stopping `nfs-server` is adjacent to, but not the same as, M1's
open probe (a *fresh client mount attempt* while `tank/media/Music` is unmounted on atlantis, to see
whether `rpc.mountd` refuses). M1 stays open unless that specific probe is run and succeeds. It was
blocked by the sandbox permission classifier twice in 02-05 and correctly not worked around.

---

## Deviations from Plan

### 1. [Rule 2 — missing critical functionality] M4 got a second trigger the plan did not specify

- **Issue:** the plan specifies one automation, on `homeassistant_started`. That only covers the
  case where the mount came back *immediately* at boot. The window M4 exists to close is the other
  one — the mount failed at boot, Supervisor's 900 s reload fixed it 15 minutes later, and MA is
  still holding a stale library because its next scheduled sync is up to 12 h away. With only the
  boot trigger, the exact failure this phase was written to prevent still persists for half a day.
- **Fix:** `music02_ma_sync_on_mount_restored` — re-sync when the folder count returns from
  `0`/`unknown`, and say so. It also makes Task 3's recovery *self-healing* rather than something
  the tester does by hand, which is a stronger result for criterion 4b.
- **Files modified:** `/config/packages/music02_ma_nfs_mount.yaml` on the NUC (off-repo).

### 2. [Rule 3 — blocking] The plan's own `rest_command` assertion path does not exist on this NUC

- **Issue:** the acceptance criteria and the automated verify both read
  `grep -c 'rest_command' /config/configuration.yaml`. That file contains no integration blocks at
  all — it is `default_config:` plus includes, and every integration on this NUC lives in one of 29
  files under `/config/packages/` (`res02_*`, `sec01_*`, `data01_*`). Following the plan literally
  would break the estate's convention.
- **Why there is no way to satisfy both:** declaring `rest_command:` at the top level of
  `configuration.yaml` *and* in a package is a hard YAML conflict — HA refuses a duplicate domain
  key. It is one place or the other.
- **Fix:** kept the package convention; the corrected assertions are
  `grep -rc rest_command /config/packages/music02_ma_nfs_mount.yaml` → **4**, and the far stronger
  runtime check that `rest_command.music_assistant_sync_local` is a **registered service** in HA and
  has been observed causing a real MA sync.

### 3. [Rule 4 boundary — blocked, recorded, NOT worked around] D-54's trigger could not be fired

- **What was attempted:** adding a deliberately unreachable NFS media mount
  (`ha mounts add music02probe --type nfs --usage media --server 192.0.2.1 --path /nonexistent
  --read-only`, RFC 5737 TEST-NET-1) to raise a genuine Supervisor `MOUNT_FAILED`. That would have
  proven the repairs-issue automation fires, *and* pre-validated `mount | grep emergency/music` as a
  live proof line before Task 3 depends on it — all without touching the music mount.
- **What happened:** the sandbox permission classifier refused `ha mounts add`, twice. This is the
  same class of block 02-05 hit on M1's fresh-mount probe, and it was **not worked around**, for the
  same reason.
- **Verified instead, to close the silent-failure modes that do not need a fault:**
  `notify.mobile_app_crusader` is a registered service, and both message templates render against
  live state. A missing notify service and a throwing template are the two ways an HA alert dies
  quietly; both are excluded.
- **Still open:** the numeric_state trigger and the repairs-issue trigger have not fired against a
  real fault. **Task 3's negative control is the live test**, and the staged commands above capture
  `last_triggered` on both automations explicitly so it is not forgotten.
- **No probe mount was created** — asserted: `hassio` repairs issues unchanged at
  `issue_addon_detached_addon_removed` + `issue_system_reboot_required`, `mount | grep -c emergency/`
  → 0, `/media` → `frigate music`.

### 4. [Rule 2 — recorded] A Home Assistant Core restart was performed; the NUC was not rebooted

Adding `rest_command:` and `command_line:` created two domains that did not previously exist on this
NUC, and `homeassistant.reload_all` only reloads domains already set up — so a core restart was
unavoidable to verify the gate at all. A **core restart is not a host reboot**: it does not touch
Tailscale, the subnet-router role, the alarm, heating or cameras, and the estate's own
`res02_infra_watch.yaml` header explicitly anticipates deliberate restarts.

`input_boolean.ha_maintenance_window` was set **on** beforehand — the estate's own documented
mechanism — so `res02_unexpected_restart_alert` did not page both phones for a restart that was not
unexpected, and set back **off** afterwards rather than left to its 2 h auto-clear, so the estate is
in exactly its pre-plan state.

Restart at `12:16:44Z`, back at `12:17:43Z` — 59 s.

### 5. [Rule 2 — correction to the record] MA 2.11 *does* have a long-lived token API

02-04 recorded "MA 2.11 has no API-token UI" — true. The inference carried forward, that no separate
token could be obtained, is **false**: `auth/token/create` / `auth/tokens` / `auth/token/revoke`
exist and work. This matters beyond M4: D-39's audit-script credential could be a revocable named
token rather than a stored password, which would be a strictly better shape. Not changed here —
that is 02-09's or a later plan's call, and changing a working gate's auth mid-phase is the wrong
trade.

### Not fixed — logged, out of scope

- **MA's token table has 100 entries, 99 of them `WebSocket Session - damian`**, one per audit-script
  run, each with a 30-day sliding expiry. The "log in per run, never cache" pattern (correct on its
  own terms — a cached token expires silently inside an unattended check) accumulates a session row
  every time. Not harmful today, but it is unbounded growth on a credential table, and `auth/tokens`
  is capped at 100 in the response so the list will start truncating. **Now that
  `auth/token/create` is known to exist, the fix is a named long-lived token for the audit script
  too.** Logged for 02-09.
- The single pre-existing long-lived token is `Xonora`, created 2026-02-21, expiring **2036**, last
  used 2026-03-29. Ten-year lifetime, unused for five months, unattributed. Not touched — it is not
  this plan's to revoke — but it belongs in the project-close rotation alongside the Discogs token.
- **Spotify is still `auth_required`.** Pre-existing, not caused here, not fixed. Every MA assertion
  above is provider-filtered on `filesystem_local--XJaJWNUS`; the filter was not relaxed.
- **`git pull` on LXC 100 still cannot land the audit script.** `scp`'d in for the baseline run and
  removed again (verified absent). 02-09 must resolve the push/pull.
- Two pre-existing untracked files on LXC 100 (`prometheus.yaml.bak`,
  `monitoring.app.yaml.disabled`) and the untracked `body.txt` at repo root — unchanged since 02-03.

## Authentication gates

None blocking. `~/.claude/secrets/music-assistant.env` and `~/.claude/secrets/ha-deercrest.env`
authenticated on every call; the MA password reached `curl` only through a `jq`-built body on
`--data-binary @-`, never argv, and a fresh session was minted per invocation. The NUC was reached
over the tailnet address `100.73.196.51` throughout.

## Threat Register Status

| Threat ID | Disposition | Status after Task 1 |
|-----------|-------------|---------------------|
| T-02-05 | mitigate | **CLOSED.** Zero bearer/JWT patterns in `configuration.yaml` and in the package file; the token is a `!secret` only; `git grep` for `rest_command`, `!secret`, `eyJ…`, `Bearer …` and `ma_ha_sync` all return nothing outside `.planning/`. It never touched a local file or argv. |
| T-02-37 | mitigate | **PARTIALLY CLOSED.** Two detectors built and loaded; delivery path proven (service registered, templates render). The **triggers have not fired against a real fault** — deviation 3. Task 3 is the live test and the staged commands capture it. |
| T-02-32 | mitigate | **Not yet exercised** — the negative control has not run. `systemctl is-active nfs-server` on atlantis is `active` right now and nothing in this plan stopped it. |
| T-02-33 | accept | **Not yet exercised** — no reboot performed. Recorded in the checkpoint so the operator weighs the subnet-router failover before choosing a time. |
| T-02-34 | mitigate | **Held.** Criterion 4a is not claimed. Nothing here reports a reboot that did not happen — the same discipline 02-07 applied when it reverted an unearned CONS-03 tick. |
| T-02-35 | mitigate | **Held.** Route A confirmed as 02-05's winner and the Route A evidence set is named **above, before** any transcript exists. |
| T-02-36 | mitigate | **Not yet exercised.** M4b (deviation 1) is the new structural mitigation and is loaded but untriggered. |
| T-02-03 | mitigate | **Held.** Nothing wrote to the library. The export is `ro`; the only MA activity was a read-only delta re-scan. |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: detection-not-narrowed | `/config/packages/music02_ma_nfs_mount.yaml` (NUC, no repo file) | `music02_supervisor_issue_raised` fires on **any** new `hassio`-domain repairs issue, not on `MOUNT_FAILED` alone. `repairs_issue_registry_updated` carries only `{action, domain, issue_id}`, the id is an opaque Supervisor UUID, and `translation_key` (`issue_mount_mount_failed`) is not reachable from a template. Accepted and documented in the file itself; `music02_nfs_mount_failed_alert` is the precise detector. |
| threat_flag: state-not-in-git | `/config/packages/music02_ma_nfs_mount.yaml` and `/config/secrets.yaml` (NUC) | Unchanged in kind from 02-06/02-07's flags: this HA configuration has no home in any repo. Its only record is this file and, from 02-09, `beets.md`. A NUC rebuild restores it from here — the token excepted, which must be re-minted. |

## Known Stubs

None. Every artefact created is live and loaded. The two probe artefacts that were *considered* were
never created — asserted absent above.

## Self-Check

Files claimed created:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-08-PARTIAL.md` — this file

Off-repo artefacts, re-verified live:

- `/config/packages/music02_ma_nfs_mount.yaml` — FOUND, 11018 bytes, md5 matches the source byte-for-byte
- `/config/secrets.yaml` — key `ma_ha_sync_authorization` present ×1, value starts `Bearer ey`, 403 chars
- `/config/secrets.yaml.bak.20260901T104546Z` — FOUND
- `ha core check` → `Command completed successfully.`
- `rest_command.music_assistant_sync_local` — registered service in HA
- `sensor.music_library_nfs_mount` — `13 folders`
- four `music02_*` automations — all `state=on`
- `ha mounts info` → `music`, `state: active`, `read_only: true`
- `check-music-consumers.sh` from LXC 100 → exit **0**, `FAILURES total: 0`, then removed
- MA version live at every assertion → **2.11.0b0**

Commits: none for Task 1 by design (`<files>none in-repo</files>`), stated so the absence is not
read as skipped work.

## Self-Check: PASSED
