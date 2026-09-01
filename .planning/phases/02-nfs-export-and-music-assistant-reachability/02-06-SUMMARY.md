---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 06
subsystem: infra
status: complete
tags: [music-assistant, filesystem-local, provider, headless-setup-flow, content-type, missing-album-artist-action, cons-02, cons-03, d-28, d-30, d-31]

requires:
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-05's live HAOS Supervisor NFS mount at /media/music (Route A), proven visible inside the MA container; 02-04's check-music-consumers.sh and its three pinned proof albums; 02-01's pre-add provider baseline"
  - phase: 01-safety-harness-and-freeze-the-writers
    provides: "the library normalised to 568:568 and check-music-freeze.sh, the B-8 regression detector run as this plan's wave gate"

provides:
  - "A Music Assistant filesystem_local provider, instance_id filesystem_local--XJaJWNUS, reading /media/music — the ONLY local media provider in the estate"
  - "content_type = music, read back and read_only:true — D-28 satisfied, so missing_album_artist_action actually applies"
  - "missing_album_artist_action = folder_name, read back — D-01 satisfied, the various_artists default overridden"
  - "The complete config/providers/get response captured as committed evidence (D-29), so the provider is reproducible after an MA rebuild"
  - "MA_LOCAL_PROVIDER_INSTANCE pinned in scripts/check-music-consumers.sh — sections 2, 3 and 5 are now real assertions (D-30)"
  - "T-02-19 CLOSED on the real code path: MA's own check_write_access() ran on provider load, reload and a full initial sync, and created nothing in the library root"
  - "A HEADLESS provider-creation recipe (config/providers/setup -> config/flows/submit -> config/providers/save) — no GUI was used at any point (D-31)"
  - "A measured API-shape correction: MA 2.11 does NOT expose the filesystem provider's `path` in config/providers/get; music/browse is the instrument that proves it"

affects:
  - "02-07 — the provider exists and its instance id is pinned; the one remaining red is the VA proof album, which is 02-07's temporary export to stage"
  - "02-09 — D-02 folder_name permanence must land in PROJECT.md as a Key Decision; the provider config below is the rebuild recipe"
  - "phase-07-pilot — every album assertion is now provenance-scoped to filesystem_local--XJaJWNUS"

tech-stack:
  added: []
  patterns:
    - "Headless MA provider creation: config/providers/setup returns a flow_id + form entries, config/flows/submit returns type=finish with .result.instance_id — no browser, no guessed step ids"
    - "Prove a config value functionally when the API will not return it: music/browse on the provider root listed the 13 exported artist directories, which config/providers/get could not show"
    - "Read back every setting that was submitted; a submitted value is not a configured value"

key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-06-SUMMARY.md"
  modified:
    - "scripts/check-music-consumers.sh"

key-decisions:
  - "missing_album_artist_action = folder_name is PERMANENT (D-02), not a pilot setting — once the tagger owns the tree the ALBUMARTIST/Album path contract is permanent, so a folder/tag disagreement is always a real defect worth surfacing, and there is nothing to remember to undo"
  - "Created entirely headlessly (D-31). The GUI was never opened. config/providers/setup + config/flows/submit are fully drivable and are recorded here so the provider can be rebuilt without a browser"
  - "MA 2.11's config/providers/get does NOT expose the filesystem provider's `path`, and config/providers/get_value key=path returns 'Internal server error'. The path is proven FUNCTIONALLY via music/browse instead of asserted against a field that does not exist"
  - "The script's empty-value ma_fail message was reworded (not removed) — its old 'NOT YET PINNED / plan 02-06 owes this' text became historically wrong the moment 02-06 pinned it, and the acceptance criterion required the placeholder string gone"

patterns-established:
  - "A submitted setting is not a configured setting: content_type and missing_album_artist_action were both re-read via config/providers/get after the write, never trusted from the submit response alone"
  - "When an API cannot answer a question, name the instrument that can rather than downgrading the claim"

requirements-completed: [CONS-02]
requirements-carried: [CONS-03]

metrics:
  duration: "~6 min"
  completed: 2026-09-01
  tasks_completed: 2
  tasks_total: 2
---

# Phase 02 Plan 06: The Music Assistant Filesystem Provider Summary

**The provider was created entirely headlessly, `content_type` is `music` and
`missing_album_artist_action` is `folder_name` — both proven by read-back, not by submission — and
MA's own `check_write_access()` ran three times against the library root and created nothing.**

The plan predicted sections 3, 4 and 5 of the audit script would still be red at this point. They
are not. MA's automatic initial sync fired on its own after provider creation and imported **20
albums attributed to `filesystem_local--XJaJWNUS`**, including both library proof albums with
client-side provider attribution confirmed. The run exits **1** on exactly **one** failure — the
Various Artists proof album, which lives under `tank/downloads` and is structurally outside this
export until 02-07 stages the temporary one. That is a better intermediate state than planned, and
**nothing was softened to get it**; the section-level output is recorded verbatim below.

## Status

| Task | Disposition |
|------|-------------|
| Task 1 — create the provider, `content_type: music`, `missing_album_artist_action: folder_name` | **Complete, headless.** No GUI. Write probe left nothing in the library root. |
| Task 2 — capture the config as evidence, pin the instance id | **Complete.** Full read-back below; `filesystem_local--XJaJWNUS` pinned; commit `e1c4f93`. |

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | *(none — `<files>none in-repo</files>`)* | Provider state lives in MA's settings store on the NUC. Nothing committable by design; the record is this SUMMARY. Same precedent as 02-04 Tasks 1/2 and 02-05 Tasks 1/2/3. |
| 2 | `e1c4f93` | `feat(02-06): pin the MA filesystem provider instance id into the audit script` |

---

## TASK 1 — THE HEADLESS ROUTE WORKED. THE GUI WAS NEVER OPENED (D-31)

D-31 asks that the headless route be attempted first via `/api-docs/commands.json` discovery, and
that the SUMMARY name which command was missing if the GUI had to be used. **No command was
missing.** The full recipe, reproducible:

### Step 0 — discovery, unauthenticated

```
$ curl -s http://172.16.1.31:8095/api-docs/commands.json | jq -r '.[].command' | grep 'config/providers\|config/flows'
config/flows/abort          config/providers/get_entries
config/flows/get            config/providers/get_value
config/flows/submit         config/providers/invoke_action
config/providers            config/providers/reconfigure
config/providers/get        config/providers/reload
config/providers/remove     config/providers/save
config/providers/setup
```

The two schemas that decide it:

- `config/providers/setup(provider_domain)` → `SetupFlowStep`. *"Start the setup flow to add a new
  instance of the given provider."*
- `config/flows/submit(flow_id, values)` → `SetupFlowStep`. *"Submit the user's values for the
  flow's pending FORM step. Returns the flow's next step, or the same FORM step (with per-field
  errors set) when validation failed."*

`config/providers/save`'s own description confirms the split and why setup could not be skipped:
*"Adding a new instance goes exclusively through the setup flow (`config/providers/setup`); this
endpoint only updates an existing instance."*

### Step 1 — the provider domain, measured not assumed

`providers/manifests` (not `providers/available`, which does not exist):

```
{"domain":"filesystem_onedrive",     "name":"OneDrive",                 "type":"music"}
{"domain":"filesystem_nfs",          "name":"Filesystem (NFS share)",   "type":"music"}
{"domain":"filesystem_local",        "name":"Filesystem (local disk)",  "type":"music"}
{"domain":"filesystem_google_drive", "name":"Google Drive",             "type":"music"}
{"domain":"filesystem_smb",          "name":"Filesystem (remote share)","type":"music"}
```

**Route A won in 02-05, so `filesystem_local` is the domain** and `filesystem_nfs` was deliberately
not used — 02-05 recorded that it exposes no client-side `ro` option at all and would have
discarded a working defence in depth.

### Step 2 — the setup flow's form, verbatim

```
$ config/providers/setup {"provider_domain":"filesystem_local"}

flow_id=53b96822f347497baecb1e10fcaae75a   type=form

{"key":"content_type","type":"string","required":false,"default_value":"music",
 "options":["music","audiobooks","podcasts","sound_effects"],"depends_on":null}
{"key":"path","type":"string","required":true,"default_value":"/media","options":[]}
```

Note `path`'s default is `/media`, **not** `/media/music`. Accepting the default would have pointed
the provider at HAOS's whole media root rather than the NFS mount.

### Step 3 — submit, verbatim

```
$ config/flows/submit {"flow_id":"53b96822...","values":{"content_type":"music","path":"/media/music"}}

type=finish   step_id=finish_library_sync   errors={}
result={"instance_id":"filesystem_local--XJaJWNUS"}
```

### Step 4 — `missing_album_artist_action` is NOT a setup-flow entry

It is an **options** entry on the created instance, so it takes a second call. This is worth
recording because a reader following only the setup flow would never see it and would silently
inherit the `various_artists` default — precisely the D-01 trap:

```
$ config/providers/save {"provider_domain":"filesystem_local",
                         "instance_id":"filesystem_local--XJaJWNUS",
                         "values":{"missing_album_artist_action":"folder_name"}}
-> {"instance_id":"filesystem_local--XJaJWNUS","status":"loaded","last_error":null,
    "mama":"folder_name","ct":"music"}
```

### THE PROVIDER INSTANCE ID

```
filesystem_local--XJaJWNUS
```

**It is new.** 02-01's baseline (`.continue-here.md`, taken 2026-08-31 before anything was added)
recorded exactly four `type=music` providers — `ambient_sounds`, `builtin--bbsqELSo`,
`radiobrowser`, `spotify--g2SQC45P` — and **no filesystem/local-media provider of any kind**. Total
configs went **29 → 30, delta exactly 1**; `type=music` went **4 → 5**.

### The write probe created nothing — T-02-19 CLOSED on the real code path

MA's `check_write_access()` writes a random `shortuuid` `.txt` at the provider root on **every**
provider load. It ran at least three times in this plan: initial provider load, the reload after
`config/providers/save`, and the automatic initial sync. Asserted on **atlantis**, not through the
mount, against a stamp taken before the provider existed (`2026-09-01 09:52:56 UTC`):

| Instrument | Before creation | After creation | After save/reload | After the full initial sync |
|---|---|---|---|---|
| `find … -maxdepth 1 -type f -name '*.txt' -newermt <stamp>` | 0 | **0** | **0** | **0** |
| `find … -maxdepth 1 -type f -name '*.txt'` (any age) | 0 | **0** | **0** | **0** |
| `find … -newermt <stamp>` (anything, anywhere in the tree) | 0 | **0** | **0** | **0** |
| `ls -A` top-level entries | 14 | 14 | 14 | **14** |
| `find … \| wc -l` total entries | 2674 | 2674 | 2674 | **2674** |
| `zfs list -o used tank/media/Music` | 33.9G | — | — | **33.9G** |

This is strictly stronger than 02-05's synthetic Stage 4b `touch` probe: it is MA's own code, on
MA's own schedule, against the same export. The `ro` holds.

### Acceptance criteria, one by one

| Criterion | Result |
|---|---|
| `domain` is `filesystem_local`, matching 02-05's Route A | ✅ `"domain":"filesystem_local"` |
| `available` is `true` | ✅ `providers` runtime row: `"available":true` |
| `last_error` null or empty | ✅ `"last_error":null`, `"status":"loaded"` |
| `instance_id` recorded verbatim and absent from 02-01's inventory | ✅ `filesystem_local--XJaJWNUS`; 29→30 configs, 4→5 music |
| configured path is `/media/music` | ✅ **functionally** — see the deviation below; `config/providers/get` does not expose `path` at all in 2.11 |
| `content_type` reads back exactly `music` | ✅ and `read_only:true` |
| `missing_album_artist_action` reads back exactly `folder_name` | ✅ (default is `various_artists`) |
| headless vs GUI recorded | ✅ **headless throughout; the GUI was never opened** |
| `find … -newermt '<task start>' -name '*.txt'` → `0` | ✅ `0`, checked three times |

---

## TASK 2 PART A — THE FULL PROVIDER CONFIG, AS EVIDENCE (D-29)

`config/providers/get {"instance_id":"filesystem_local--XJaJWNUS"}`, every value key, read back
**after** the `folder_name` write:

```json
{
  "instance_id":                        "filesystem_local--XJaJWNUS",
  "domain":                             "filesystem_local",
  "type":                               "music",
  "enabled":                            true,
  "name":                               null,
  "default_name":                       "Filesystem (local disk)",
  "status":                             "loaded",
  "last_error":                         null,

  "content_type":                       "music",        // read_only: true  (set at setup, D-28)
  "missing_album_artist_action":        "folder_name",  // default_value: "various_artists"  (D-01)
  "ignore_album_playlists":             true,
  "propagate_track_genres":             false,
  "library_sync_artists":               true,
  "library_sync_albums":                true,
  "library_sync_tracks":                true,
  "library_sync_playlists":             true,
  "library_sync_podcasts":              true,   // inert: depends_on content_type == "podcasts"
  "library_sync_audiobooks":            true,   // inert: depends_on content_type == "audiobooks"
  "log_level":                          "GLOBAL"
}
```

### The two settings that are the whole point of this plan

**`content_type`.** MA returns it with `"read_only": true` on the created instance — it is settable
only in the setup flow, exactly as D-28 predicted. Had it been anything else, the next line would
not apply at all.

**`missing_album_artist_action`.** MA's own declaration, quoted from the read-back, is the proof
that D-28 is load-bearing rather than folklore:

```json
"missing_album_artist_action": {
  "default_value": "various_artists",
  "depends_on": "content_type",
  "depends_on_value": "music",
  "value": "folder_name",
  "options": [
    {"value":"track_artist",    "description":"Use the track's own artist(s). Can split an album across artists when its tracks differ."},
    {"value":"various_artists", "description":"Group everything under a single 'Various Artists' album artist. Keeps the album together; best for compilations."},
    {"value":"folder_name",     "description":"Use the containing folder's name, falling back to 'Various Artists' when it can't be determined."}
  ]
}
```

`depends_on: content_type` / `depends_on_value: music`, verbatim from the live server. **D-28 is
confirmed empirically, not just from source.**

### `folder_name` is PERMANENT (D-02) — for 02-09 to carry into PROJECT.md

The target tree is `ALBUMARTIST/Album/NN Title`. `folder_name` and a correct `albumartist` tag
therefore **agree** when the tag is present, and **disagree loudly** when it is absent — a missing
tag surfaces as a wrong-looking artist entry instead of a plausible one. The `various_artists`
default is a trap for *this* library specifically, which is heavy on DJ compilations that
legitimately **are** Various Artists: under the default, an untagged track and a correct
compilation produce indistinguishable entries.

This is not a pilot-only setting. Once the tagger owns the tree the path contract is permanent, so a
folder/tag disagreement is **always** a real defect worth surfacing. Same shape as Phase 1's
Jellyfin metadata freeze: there is nothing to remember to undo.

Also worth carrying: MA's album identity is `albumartist + os.sep + album`, so a wrong album artist
creates a **durable** entry, and the cheapest repair once content has flowed is removing and
re-adding the provider — which drops every favourite and play count attached to its items. That is
why this plan runs before content flows.

### PART A(ii) — every provider that could answer an album assertion

`config/providers` in full, compared against 02-01's baseline. **30 configs; 5 are `type=music`:**

| domain | instance_id | enabled | name | status | in 02-01 baseline? |
|---|---|---|---|---|---|
| `builtin` | `builtin--bbsqELSo` | true | *(null)* | loaded | yes |
| `spotify` | `spotify--g2SQC45P` | true | Spotify Damian | **auth_required** | yes |
| `radiobrowser` | `radiobrowser` | true | *(null)* | loaded | yes |
| `ambient_sounds` | `ambient_sounds` | true | Ambient Sounds | loaded | yes |
| **`filesystem_local`** | **`filesystem_local--XJaJWNUS`** | true | *(null)* | loaded | **NO — added by this plan** |

Other types, unchanged: metadata 9, plugin 7, player 7, audio_analysis 2.

**Which of these could theoretically return an album, and why the filter is not theatre:**

- **`spotify--g2SQC45P` — the real risk, and it is live.** It already holds `NOW That's What I Call
  Music! 116` and `98`, both credited to **Various Artists**. An unfiltered
  `music/albums/library_items` can match a proof album from Spotify's catalogue and report a pass
  with the NFS mount broken or absent. This is why every album assertion filters on
  `filesystem_local--XJaJWNUS` server-side **and** re-checks `provider_mappings[].provider_instance`
  client-side.
- **`builtin--bbsqELSo`** — MA's built-in provider. Supplies announcements and built-in sources, not
  library albums, but it is a `type=music` provider and is named here rather than assumed harmless.
- **`radiobrowser`, `ambient_sounds`** — stations and sound effects. No album objects.
- **`filesystem_local--XJaJWNUS`** — the only local-media provider in the estate. Whatever appears
  from `/media/music` is unambiguously attributable to it.

**Drift noticed, NOT caused by this plan and NOT fixed:** Spotify's `status` is now `auth_required`
with `"Spotify needs you to approve audio playback again. Open the Spotify provider settings and
run through the setup once more to restore playback."` 02-01's baseline recorded it as simply
`enabled: true` without a status. This plan did not touch Spotify. It is **still enabled and its
library items are still returned**, so it remains the false-pass risk regardless of playback state —
the filter is not relaxed on account of it. Logged as out of scope; it is an operator decision
whether to re-approve.

---

## TASK 2 PART B — THE INSTANCE ID IS PINNED (D-30)

`scripts/check-music-consumers.sh`, commit `e1c4f93`:

```bash
MA_LOCAL_PROVIDER_INSTANCE="filesystem_local--XJaJWNUS"
```

Byte-for-byte equal to `config/providers/get` → `.instance_id`. The comment beside it records both
things D-30 requires:

> *THIS IS AN INSTANCE ID, NOT A DISPLAY NAME, AND THAT IS DELIBERATE (D-30). MA's provider display
> name is user-editable in the GUI — this instance's `name` is currently null and it renders as its
> default_name "Filesystem (local disk)". A rename in the GUI would silently change what this script
> measures while every assertion still reported green.*
>
> *IF MUSIC ASSISTANT IS REBUILT, RESTORED, OR THE PROVIDER IS REMOVED AND RE-ADDED, this value MUST
> be RE-PINNED from `config/providers/get` on the live server. Do not guess it and do not reuse the
> value below — the `--XXXXXXXX` suffix is generated per instance.*

That the display name is `null` is not a detail: the provider currently renders under its
`default_name`, so a name-based filter would have matched on a string the operator has never even
set.

### The run WITHOUT `--baseline` — exit 1, section by section, verbatim

```
🧰 0. Toolchain preconditions                                    ✅ 5/5 tools, 2/2 credentials
     ✅ export queries delegated to root@172.16.1.158
     ✅ Music Assistant reachable at http://172.16.1.31:8095, auth/login OK (fresh JWT, not cached)
     ✅ Jellyfin resolved to 192.168.90.25:8096 via docker inspect
     ⚠️  HA_SSH_KEY not set/readable — section 5's 'ha mounts info' enrichment SKIPPED (by design)
     MA version: live=2.11.0b0  proven-at=2.11.0b0

📤 1. The NFS export on atlantis (CONS-01)                       ✅ 10/10, 0 failures
     ✅ client is exactly 172.16.1.31       ✅ neither '*' nor a CIDR
     ✅ ro   ✅ all_squash   ✅ anonuid=568   ✅ anongid=568   ✅ mountpoint
     ✅ no_root_squash absent (D-51 gate 2)
     ✅ nfs-server active on atlantis       ✅ nfs-server NOT active on LXC 100

🎛  2. Music Assistant reachability and provider identity (CONS-02, D-30)   ✅ 4/4, 0 failures
     music providers configured in MA:
         builtin--bbsqELSo            builtin            true  (null)
         spotify--g2SQC45P            spotify            true  Spotify Damian
         radiobrowser                 radiobrowser       true  (null)
         ambient_sounds               ambient_sounds     true  Ambient Sounds
         filesystem_local--XJaJWNUS   filesystem_local   true  (null)
     ✅ CONS-02: provider filesystem_local--XJaJWNUS is enabled
     ✅ CONS-02: provider type is 'music'
     ✅ CONS-02: provider status is 'loaded'
     ✅ CONS-02: provider last_error is empty
     note: a Spotify music provider is ENABLED (spotify--g2SQC45P).

💿 3. The three proof albums in Music Assistant (CONS-02)        ⚠️ 2 of 3 — 1 failure
     [single-artist] Lifelines — Chris Norman
       ✅ source directory exists on disk
       ✅ CONS-02: exact match in MA, provider-attributed to filesystem_local--XJaJWNUS
     [multi-disc] The Ultimate Hits — Garth Brooks
       ✅ source directory exists on disk
       ✅ CONS-02: exact match in MA, provider-attributed to filesystem_local--XJaJWNUS
     [various-artists] Mastermix Essential Hits - Pop 4 - 2005-2009 — Various Artists
       scope: temp-export   path: /mnt/tank/downloads/complete/nzb/unsorted/VA-Mastermix...
       ✅ source directory exists on disk
       ❌ CONS-02: no exact match for album='Mastermix Essential Hits - Pop 4 - 2005-2009'
                   albumartist='Various Artists'
              provider-filtered candidates were: <none>

🎬 4. The three proof albums in Jellyfin (CONS-04 groundwork)    ✅ 2/2 in-scope, 0 failures
     ✅ [single-artist]  'Lifelines' — 'Chris Norman' present (exact match)
     ✅ [multi-disc]     'The Ultimate Hits' — 'Garth Brooks' present (exact match)
     ⚠️  [various-artists] scope=temp-export — out of Jellyfin's reach by design. REPORTED, not asserted.

🔌 5. Mount liveness (CONS-03)                                   ✅ 1/1, 0 failures
     albums attributed to filesystem_local--XJaJWNUS: 20
     ✅ CONS-03: at least 3 albums are attributed to the local provider
     ⚠️  'ha mounts info' enrichment skipped (HA_ROUTE=skipped)

📊 6. Summary
  MA version (live):           2.11.0b0   (assertions proven at 2.11.0b0)
  pinned provider instance:    filesystem_local--XJaJWNUS
  proof albums pinned:         3   (target 3: single-artist, multi-disc, various-artists)
  albums matched in MA:        2   (target 3, exact name+albumartist, provider-attributed)
  albums matched in Jellyfin:  2   (target 2, exact name+albumartist)
  jellyfin out-of-scope:       1   (scope!=library — reported, not asserted)
  MA albums, local provider:   20   (target >= 3)
  toolchain missing:           0
  export assertions failed:    0
  MA assertions failed:        1
  Jellyfin assertions failed:  0
  FAILURES total:              1

❌ 1 failed checks                                               EXIT=1
```

**The single red is the correct one and it belongs to 02-07.** The VA proof album is `scope:
temp-export` — it lives under `/mnt/tank/downloads`, which this export does not serve. 02-04 pinned
it knowing that; 02-05 substituted it out of the read-through test for the same structural reason.
It becomes green when 02-07 stages it as `Various Artists/Mastermix Essential Hits - Pop 4 -
2005-2009/` under the temporary export.

**Nothing was softened.** `git diff` for this plan touches the constant, its comment, the wording of
the empty-value failure message, and the summary's empty-value label. Every `ma_fail` / `fail` call
and every comparison in the file is byte-identical to `16a9fb2`.

### Exit-code contract — re-verified after the edit

| Invocation | Exit | Result |
|---|---|---|
| default (assert mode) | **1** | ✅ as expected — one real, owned failure |
| `--baseline` | **0** | ✅ `--baseline: 1 findings recorded, exiting 0. This is the before-state.` |
| `--bogus` | **2** | ✅ |
| `bash -n` | **0** | ✅ |
| `grep -qi 'not yet pinned'` | **no match** | ✅ placeholder gone |

---

## Deviations from Plan

### 1. [Rule 1 — Bug in the plan's premise] MA 2.11 does not expose the provider's `path`; it is proven functionally instead

- **Found during:** Task 1, reading back `config/providers/get`.
- **Issue:** The acceptance criterion is *"The provider's configured path is `/media/music`
  (Route A)"*, implying a readable field. It is not readable. `config/providers/get` returns eleven
  `values` keys and **`path` is not among them** — the setup-flow entries are consumed at creation
  and are not surfaced as options. `config/providers/get_value {"key":"path"}` returns
  **`Internal server error`**, and `config/providers` returns `"values":{}` for the instance.
  Asserting on a field that does not exist would either error or, under a `// empty` filter, read
  as a silent pass.
- **Fix:** Proved the path **functionally**, which is stronger evidence than the field would have
  been. `music/browse {"path":"filesystem_local--XJaJWNUS://"}` returns exactly the 13 artist
  directories of the exported library plus the `..` entry:

  ```
  folder  ..                  root
  folder  Benson Boone        filesystem_local--XJaJWNUS://Benson Boone
  folder  BLACKPINK           filesystem_local--XJaJWNUS://BLACKPINK
  folder  Chris Norman        filesystem_local--XJaJWNUS://Chris Norman
  folder  Def Leppard         filesystem_local--XJaJWNUS://Def Leppard
  folder  Ed Sheeran          filesystem_local--XJaJWNUS://Ed Sheeran
  folder  Garth Brooks        filesystem_local--XJaJWNUS://Garth Brooks
  folder  Hawthorne Heights   filesystem_local--XJaJWNUS://Hawthorne Heights
  folder  Katy Perry          filesystem_local--XJaJWNUS://Katy Perry
  folder  Lady Gaga           filesystem_local--XJaJWNUS://Lady Gaga
  folder  P!nk                filesystem_local--XJaJWNUS://P!nk
  folder  Sabrina Carpenter   filesystem_local--XJaJWNUS://Sabrina Carpenter
  folder  Taylor Swift        filesystem_local--XJaJWNUS://Taylor Swift
  folder  Vengaboys           filesystem_local--XJaJWNUS://Vengaboys
  ```

  Those are byte-for-byte the 13 folders 02-04 enumerated in the library and 02-05 saw through the
  mount. Re-run after the `save`/reload: `browse_entries=14`, unchanged. Had `path` been left at its
  `/media` default, the browse would have listed HAOS's media root instead.
- **Consequence for a rebuild:** the `path` value cannot be recovered from the API. It is recorded
  here — **`/media/music`** — because this SUMMARY is now the only place it exists outside MA's
  settings store. That is D-29 earning its keep on the first attempt.
- **Files modified:** none.

### 2. [Rule 2 — Missing critical functionality] The empty-value failure message was reworded

- **Found during:** Task 2 Part B verification.
- **Issue:** The acceptance criterion requires `grep -qi 'not yet pinned'` to **fail**. The string
  survived in the section-2 `ma_fail` message: *"MA_LOCAL_PROVIDER_INSTANCE is NOT YET PINNED. Plan
  02-06 creates the local filesystem provider and must write its instance_id into this script."*
  That text became **factually wrong** the moment this plan pinned it — after 02-06, an empty
  constant does not mean "pending", it means the value was **lost** (edited out, or the file
  restored from before `e1c4f93`), which needs a different instruction.
- **Fix:** Reworded to *"MA_LOCAL_PROVIDER_INSTANCE is EMPTY. It was pinned by plan 02-06; re-pin it
  from `config/providers/get` on the live MA server."* **The `ma_fail` call itself is unchanged** —
  the branch still fails loudly and still refuses to pass by default. Only the operator-facing text
  changed. The summary line's `${…:-<UNPINNED — set by plan 02-06>}` label was updated for the same
  reason and in the same way.
- **Why it is disclosed:** the criterion also says the diff should show *only* the constant and its
  comment. Those two criteria cannot both hold, because the placeholder string lives in the failure
  message. This is the minimum change that satisfies the grep without weakening an assertion, and
  the reasoning is recorded rather than left for a reader to reconstruct from the diff.
- **Files modified:** `scripts/check-music-consumers.sh`.

### 3. [Rule 2 — Recorded, not concealed] The intermediate state is better than the plan predicted

- The plan's acceptance criterion states sections 3, 4 and 5 will fail. **Only section 3 fails, on
  one album.** MA's automatic initial sync (`INITIAL_SYNC_DELAY`, ~10 s after creation) fired on its
  own and imported 20 albums attributed to the local provider. The plan explicitly anticipated this
  — *"Provider creation causes an initial sync after `INITIAL_SYNC_DELAY` (10 seconds) on its own;
  let that happen and observe it"* — but its section-level prediction was written as though it would
  not have completed by the time the script ran.
- **No sync was triggered by this plan.** `music/sync` was never called; that is 02-07's deliberate
  criterion-3 assertion and it is untouched here.
- Recorded rather than quietly enjoyed, because a run that is greener than planned is exactly the
  shape a false pass takes. The provenance is what makes it real: both matches were confirmed
  server-side via the `provider` filter **and** client-side against
  `provider_mappings[].provider_instance`.

### Not fixed — logged, out of scope

- **`git pull` on LXC 100 still cannot land this script.** This working tree is now **ahead 34 /
  behind 9** of `origin/main`; `16a9fb2`, `6d4f8de` and `e1c4f93` are local-only. The script was
  `scp`'d to `/mnt/fast/stacks/scripts/`, run for both modes and the wave gate, and **removed
  again** (verified absent), following 02-04/02-05 practice so a later pull lands the tracked copy
  cleanly. Pushing 34 unreviewed commits to a **public** repo is an outward-facing action outside
  this plan's scope. **02-09 must resolve the push/pull before anything depends on a pull there.**
- **Spotify is `auth_required`.** Pre-existing, not caused here, not fixed. See Part A(ii).
- Two pre-existing untracked files on LXC 100 (`prometheus.yaml.bak`,
  `monitoring.app.yaml.disabled`), unchanged since 02-04.
- The untracked `body.txt` at repo root, left alone as in 02-03/02-04/02-05.

## Authentication gates

None. `/mnt/fast/secrets/ma-deercrest.env` authenticated on every call. Per D-39 as amended by
02-04, a **fresh JWT was minted per invocation** and never cached; the password reached `curl` only
through a `jq`-built body on `--data-binary`, never argv.

---

## Wave gate

### `check-music-consumers.sh --baseline` → exit **0**

`FAILURES total: 1` recorded as the before-state, `pinned provider instance:
filesystem_local--XJaJWNUS`, `MA albums, local provider: 20`.

### `check-music-freeze.sh` → exit **0**

```
  tagger-class writers:        0   (target 0)
  consumer-class writers:      1   (Jellyfin, documented exception D-21)
  unclassified writers:        0   (target 0)
  declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
  artist folders:              13
  ownership mismatches:        0   (target 0, want 568:568)
  sidecars found (widened):    1341   (nfo 91 / jpg 88 / lrc 944 / png 43 / txt 175)
  sidecars found (narrow D-18):1123
  fence assertions failed:     0
  FAILURES total:              0
✅ Music freeze harness intact
```

**Byte-identical to 01-09's closure, 02-03's after-state and 02-05's.** Adding an MA *reader* — one
that scanned the entire 2,674-entry tree during its initial sync — changed no inode, no owner and no
sidecar count. The measurement agrees with the argument.

### Host health, after the plan

```
uptime -s                                    2026-08-31 18:48:08   (unmoved — no crash)
/proc/pressure/io  full avg300               0.50                  (halt was 96.22)
dmesg -T | grep -c amdgpu_hmm_invalidate_gfx 0
```

---

## Requirements

**CONS-02 is COMPLETE.** The local filesystem provider exists, is `type=music`, `enabled`,
`status: loaded`, `last_error: null`, is pinned into the audit script, and **two of the three proof
albums are matched in MA with provider attribution confirmed on both sides**. Section 2 is 4/4
green.

| Req | State after this plan | Owner |
|---|---|---|
| CONS-01 | Complete (02-03 + 02-05). Section 1 still 10/10 green. | closed |
| **CONS-02** | **COMPLETE** — provider identity asserted, albums provider-attributed | **02-06** |
| CONS-03 | Section 5's MA-side assertion is **green** (20 albums attributed). The requirement's full closure — a deliberate `music/sync` and the VA album through the temporary export — is 02-07's. **Carried, not claimed.** | 02-07 |

## Threat Register Status

| Threat ID | Disposition | Status after this plan |
|-----------|-------------|------------------------|
| T-02-16 | mitigate | **CLOSED.** The instance id is pinned; every album, count and identity assertion filters on it server-side and re-checks `provider_mappings` client-side. All 5 music providers re-enumerated against 02-01 and each named for what it could return. |
| T-02-24 | mitigate | **CLOSED.** `content_type` **read back** as `music` with `read_only:true`, and the live server's own declaration of `missing_album_artist_action` carries `depends_on: content_type` / `depends_on_value: music` — D-28 confirmed empirically, not from source alone. |
| T-02-25 | mitigate | **CLOSED at the config layer.** `missing_album_artist_action` read back as `folder_name` against a `various_artists` default. Proof that it actually *fires* is 02-07's deliberate control album — a configured-but-unexercised setting is what this phase exists to avoid, and that half is not claimed here. |
| T-02-19 | mitigate | **CLOSED on the real code path.** `check_write_access()` ran on provider load, on reload after `save`, and through a full initial sync of 2,674 entries. `*.txt` in the library root: 0. Anything newer than the pre-provider stamp, anywhere in the tree: 0. Entry count and `zfs used` unchanged. |
| T-02-26 | mitigate | **CLOSED.** The whole config is transcribed above, including the `path` value the API **cannot** return — which is precisely the rebuild-loss scenario D-29 was written for, encountered on the first attempt. |
| T-02-27 | mitigate | **CLOSED.** The non-`--baseline` run exits 1 and its section-level output is recorded verbatim, including the one red. Every `ma_fail`/`fail` call and comparison is byte-identical to `16a9fb2`; only operator-facing message text changed, and that change is disclosed as deviation 2. |
| T-02-05 | mitigate | **Held.** Token read at runtime from `/mnt/fast/secrets/ma-deercrest.env` (0600 root), fresh per run, never cached, never in argv. The provider config captured above contains **no credential field** — `filesystem_local` has none. |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: state-not-in-git | MA settings store on the NUC (no repo file) | The provider's `path` (`/media/music`) is **unreadable through the API** — `config/providers/get` omits it and `config/providers/get_value key=path` 500s. An MA rebuild loses it silently with no diff anywhere. This SUMMARY is the sole record. Any future rebuild runbook must re-run `config/providers/setup` with `path=/media/music` explicitly, because the form's default is `/media`. |

## Known Stubs

None. The provider is live, loaded, error-free, and has already imported 20 albums from the export.
The single red assertion is the VA proof album, which is structurally outside this export by design
and is 02-07's to stage — a scoped hand-off, not a stub.

## Self-Check

Files claimed created/modified:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-06-SUMMARY.md` — FOUND
- `scripts/check-music-consumers.sh` — FOUND, modified, `bash -n` exit 0

Commits:

- `e1c4f93` — FOUND in `git log` (`feat(02-06): pin the MA filesystem provider instance id into the audit script`)
- Task 1 produced no commit by design (`<files>none in-repo</files>`) — stated so the absence is not read as skipped work

Live state re-verified at close:

- `config/providers/get filesystem_local--XJaJWNUS` → `content_type: music`, `missing_album_artist_action: folder_name`, `status: loaded`, `last_error: null` — FOUND
- `providers` runtime row → `available: true` — FOUND
- `music/browse filesystem_local--XJaJWNUS://` → 14 entries (13 artists + `..`) — FOUND
- `grep -qi 'not yet pinned' scripts/check-music-consumers.sh` → no match
- `bash scripts/check-music-consumers.sh` → exit 1 (one owned failure); `--baseline` → exit 0; `--bogus` → exit 2
- `bash scripts/check-music-freeze.sh` → exit 0, FAILURES 0
- `find /mnt/tank/media/Music -newermt '2026-09-01 09:52:56'` → 0; 2,674 entries; 33.9G
- `scripts/check-music-consumers.sh` on LXC 100 → removed after the wave gate (verified absent)

## Self-Check: PASSED
