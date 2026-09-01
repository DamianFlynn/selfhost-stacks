---
phase: 02-nfs-export-and-music-assistant-reachability
plan: 09
subsystem: infra
status: complete
tags: [phase-closure, criterion-5, d-41, d-47, d-48, d-45, d-55, quick-health-check, project-md, network-md, beets-md, silent-pass]

requires:
  - phase: 02-nfs-export-and-music-assistant-reachability
    provides: "02-08's proven criterion 4a/4b, proven M1 and fixed D-54a; 02-07's proven criterion 3 and the tested teardown; 02-05's Route A decision and export-layer criterion 2; 02-04's check-music-consumers.sh; 02-03's applied export"
  - phase: 01-safety-harness-and-freeze-the-writers
    provides: "scripts/quick-health-check.sh's 01-09 block, whose three traps this plan copies verbatim; check-music-freeze.sh as the wave gate"

provides:
  - "CONS-01/02/03 have STANDING coverage — check-music-consumers.sh runs on every quick-health-check.sh, the path already in use from the workstation"
  - "CRITERION 5 SATISFIED — Route A recorded as a Key Decision WITH Route B's failure symptom, and PROJECT.md's prior mount-route assertion REWRITTEN (11 deleted lines), not supplemented"
  - "The folder_name permanence AND its measured conditionality, the export line with mountpoint's justification, the no-tailnet decision, and the accepted sec=sys residual risk — all recorded in PROJECT.md as choices"
  - "The Phase 2 operational record beside the stack in beets.md: export table, mount commands, API shapes, MA version, reboot transcripts, the HA automations, how-to-re-run, and D-45's TESTED rollback runbook"
  - "NETWORK.md maps atlantis:2049 for the first time and names Music Assistant for the first time"
  - "The six silent-pass mechanisms collected in one durable in-repo place"
  - "D-54b carried forward as an explicitly open item with its diagnosis and its recorded fix"
  - "A five-criterion closure verdict, each row naming its evidence and its producing plan"
  - "PHASE 02 CLOSED — operator approved 2026-09-01 by a STRONGER test than the gate asked for: tracks were PLAYED to confirm the audio matches the metadata, which no assertion in this phase could reach"
  - "D-08 independently confirmed from the consumer side: MA's browse root lists exactly 13 single-named-artist folders, no Various Artists entry anywhere"
  - "D-46's two-sided teardown confirmed from the consumer side after the fact — the temporary-export album is ABSENT from MA"

affects:
  - "Phase 7 — check-music-consumers.sh with its pinned album set is the tool CONS-04 calls; the folder_name precondition is a blocker it must check rather than assume"
  - "scripts/quick-health-check.sh — now has TWO fatal remote dependencies on LXC 100, stated in the file header"
  - "Project close — the rotation list (MA audit credential, Jellyfin music-consumers-audit key, MA HA-sync token, Discogs, and the unattributed Xonora token)"

tech-stack:
  added: []
  patterns:
    - "A harness nobody runs is the same failure as no harness — fold every new check into the path already in use, in the exact shape of the existing block rather than a paraphrase of it"
    - "Record a correction as a rewrite, not an addition. Leaving the superseded claim standing beside the correction is how a document acquires two answers"
    - "Collect the phase's silent-pass mechanisms in one place. The count is the signal: six is not bad luck"

key-files:
  created:
    - ".planning/phases/02-nfs-export-and-music-assistant-reachability/02-09-SUMMARY.md"
  modified:
    - "scripts/quick-health-check.sh"
    - ".planning/PROJECT.md"
    - "stacks/selfhosted/arrs/beets.md"
    - "NETWORK.md"

key-decisions:
  - "The consumers block is a VERBATIM copy of the 01-09 freeze block's shape, including its `\\x1b is a GNU sed extension` comment. That comment makes the plan's literal `grep -c '\\\\x1b'` acceptance criterion read 2 rather than 0 — but it read 2 before this plan touched the file, because the criterion matches the 01-09 comment it told me to copy. The code lines use `$'...'` quoting, which is what the criterion is actually about"
  - "PROJECT.md's mount-route passage was REWRITTEN. `git diff` shows 11 deletions, not only additions — D-47 asks for corrected either way, and supplementing would have left two answers standing"
  - "The six silent-pass mechanisms live in `beets.md`, not in PROJECT.md. They are operational knowledge about instruments, and beets.md is the document-beside-the-stack that a future operator reaches for"
  - "D-54b is carried forward as OPEN with its recorded fix, not quietly closed. Its trigger is correct and proven; it is blind at boot by deterministic integration-setup ordering"
  - "The MA-side notify path against a genuinely bad mount is recorded as NOT proven by firing. Saying so is the point of a closure verdict"
  - "D-55's human gate earned its place. Every automated check here verifies that MA's DATABASE says the right thing, never that the BYTES behind the entry are the right song — and the documented stale state is exactly 'entries exist, playback fails'. Playback is the only test that closes it, and it is not automatable from here. The operator's approval is NOT an approval of the two items recorded open"

requirements-completed: []
requirements-carried: []

metrics:
  duration: "~50 min"
  completed: 2026-09-01
  tasks_completed: 3
  tasks_total: 3
---

# Phase 02 Plan 09: Fold-in, Criterion 5, and the Closure Verdict Summary

**The phase's work is durable and the phase closes honestly.** The consumers audit now runs on the
path already in use, so CONS-01/02/03 have standing coverage rather than a script somebody might
remember. Criterion 5 is satisfied: Route A is a Key Decision with Route B's failure symptom named,
and PROJECT.md's prior assertion is **rewritten**, not supplemented. Four documents carry the
operational record, and the closure verdict names its evidence per criterion.

**The single most valuable thing in this phase is not the export.** It is the six silent-pass
mechanisms it found — six distinct ways to read green off a broken system — and the two occasions
where a *correct observation* produced a *wrong inference* and stood for three plans. Those are now
written down in one place, in the repo, beside the stack.

## Status

| Task | Disposition |
|------|-------------|
| 1 — fold the consumers check into `quick-health-check.sh` | **Complete, PASS.** All three traps copied verbatim; full run exit 0 with both blocks green; the unreachable-host branch fired for real and exited 1. |
| 2 — criterion 5 in PROJECT.md, the record in beets.md and NETWORK.md | **Complete.** Seven Key Decision rows; the old assertion rewritten (11 deletions); a dated `## Phase 2` section beside the stack; atlantis:2049 mapped. No credential anywhere. |
| 3 — closure verdict | **Complete, PASS.** Machine gate green three ways; **operator approved** — and by a stronger test than the gate asked for. See "Closure response". |

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | `9f915a9` | `feat(02-09): fold the consumers audit into quick-health-check.sh` |
| 2 | `e37039b` | `docs(02-09): record criterion 5 — the mount route, the export, and the operational detail` |
| 3 / close | *(this commit)* | SUMMARY, STATE, ROADMAP |

---

## THE CLOSURE VERDICT — five criteria, evidence and producing plan per row

Made against `.planning/ROADMAP.md` § "Phase 2" **verbatim**, not against what was built. Phase 1
recorded **six** occasions where a check reported a pass it had not earned, every one of them from
partial data stated as settled. **A criterion passed by a weaker test than the one specified is
recorded here as a fail.** None had to be.

| # | Criterion | Verdict | Evidence | Plan |
|---|---|---|---|---|
| 1 | NFSv4 export of the Music dataset, served from the Proxmox host, defined in `infra/` Terraform, clean re-apply; visible from the NUC; `ro` and restricted to the NUC's IP on the host | **PROVEN — all five sub-parts, named individually below** | see the 1a–1e table | 02-03 + 02-05 |
| 2 | A write attempt from the NUC against the mounted path fails — read-only enforced at the **export layer**, not by configuration politeness | **PROVEN, by Stage 4b — NOT by 4a** | A hand-rolled `mount -o rw` **SUCCEEDED** and every write was still refused `EROFS`. That the mount succeeded is what makes the test meaningful: a client-side refusal alone would have passed against a fully writable export and is not what the criterion asks. **4a is insufficient on its own** — the naive `mount -o rw` negotiated **NFSv3**, while the Supervisor mount MA actually reads through is **NFSv4.2**. 4b is the re-run over v4.2, i.e. over the protocol in use. Proving read-only on a protocol nobody uses would have been the seventh unearned pass | **02-05, Stage 4b** |
| 3 | Three already-correct albums appear in Music Assistant **under the correct album artist** within one sync cycle | **PROVEN — exact match, not "an album appeared"** | Byte-for-byte exact on **both** halves — album name AND `artists[0].name` — with no substring and no case folding, and every one re-checked against `provider_mappings[].provider_instance` client-side on top of the server-side provider filter: `Lifelines`/`Chris Norman`, `The Ultimate Hits`/`Garth Brooks` (both `filesystem_local--XJaJWNUS`), `Mastermix Essential Hits - Pop 4 - 2005-2009`/`Various Artists` (`filesystem_local--f5gkrCpU`, the D-08 substitute through the temporary export). Inside **one deliberately-triggered sync**: `music/sync` at 10:05:43Z, finished 10:08:40Z, **177 s** — not a 12 h wait. Provider-filtered album count 20 → 70. Spotify was live throughout and the filter was never relaxed | 02-07 |
| 4 | After a NUC reboot with **no manual intervention**, those albums are still present — the mount-timing race shows up on a restart, not a first sync | **PROVEN — and it needs BOTH 4a and 4b. A green 4a alone is explicitly insufficient** | see the 4a/4b breakdown below | 02-08 |
| 5 | The winning mount route recorded as a Key Decision in PROJECT.md with the **losing route's failure symptom** noted, and PROJECT.md's current assertion corrected either way | **PROVEN — satisfied by this plan** | PROJECT.md § Key Decisions gains a Route A row naming Route B's failure symptom: **it exposes no client-side `ro` option at all** (MA hardcodes its NFS option list), so Route B would have discarded a layer of defence in depth and left the server-side `ro` as the sole guarantee. The prior "OPEN QUESTION" passage is **rewritten** — `git diff .planning/PROJECT.md` shows **11 deleted lines**, not only additions. Six further rows record the `folder_name` permanence and conditionality, the export line with `mountpoint`'s justification, the no-tailnet decision, the accepted `sec=sys` risk, D-27's consequence, and the three NUC-only runtime-state items | **02-09** |

### Criterion 1, sub-part by sub-part

| Sub-part | Verdict | Evidence | Plan |
|---|---|---|---|
| **1a** export correct | PROVEN | `/mnt/tank/media/Music 172.16.1.31(sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash)`. Client is exactly `172.16.1.31`, a bare address — wildcard/CIDR count **0**, `no_root_squash` count **0**. Continuations joined before parsing, because `exportfs -v` wraps the `client(options)` field | 02-03 |
| **1b** clean re-apply | PROVEN | `terraform apply` of a **read saved plan**: 1 to add, **0 to destroy**, 0 forces-replacement. A second `terraform plan` reports `No changes.` **Re-verified today at plan close: `terraform plan -detailed-exitcode` → 0** | 02-03, re-asserted 02-09 |
| **1c** served from the host | PROVEN | `nfs-kernel-server 1:2.8.3-1` (`deb.debian.org/debian trixie/main`) installed and **enabled** on atlantis, so it survives a host reboot; `After=zfs-mount.service` drop-in present on disk and in `systemctl show`. Port delta measured **from both ends**: **2049 closed → open**. 111 was already open from the pre-existing `nfs-common` and is deliberately **not** claimed | 02-03 |
| **1d** visible from the NUC | PROVEN | Supervisor mount `{"state":"active","read_only":true,"user_path":"/media/music"}`; 13 artist directories readable; and — the part that matters — visible **inside the running Music Assistant container** by `docker exec`, propagated `rslave` (`master:1105`) into a container that had started two days before the mount existed | 02-05 |
| **1e** NFSv4 negotiated | PROVEN | `vers=4.2` in the `nfs4` line, read from **`/proc/self/mountinfo`** — `findmnt` and `showmount` are both **ABSENT** on the NUC (measured), so the instrument named in the original `verify_commands` could never have run | 02-05 |

### Criterion 4, both halves

**4a — the positive reboot. Recorded as necessary and NOT sufficient**, because atlantis was healthy
throughout, so Supervisor's mount simply succeeded and the race the phase exists to guard against
was never exercised. This result is fully consistent with the guards being completely broken.

- `boot_id` `b86dada0…` → `3a7906c0…` — the reboot is **proven**, not assumed
- **Zero manual intervention**: no remount, no `ha mounts reload`, no add-on restart, no hand sync
- Mount `{"state":"active","read_only":true}`; sensor 13; **70** albums provider-filtered; both
  library proof albums **EXACT**; audit exit **0**, FAILURES 0
- `M4a` fired **on its own** at `12:43:25.944109Z`, ~120 s after HA start

**4b — the negative control. It FIRED**, with `nfs-server` deliberately stopped before the reboot
(`boot_id` `3a7906c0…` → `a2869d72…`):

1. Supervisor logged `Mount music failed to mount, mounting read-only fallback for
   /mnt/data/supervisor/media/music` at 13:50:58.312, preceded by
   `Create new issue mount_failed - mount / music`
2. `/media/music` present, a directory, mode `dr--r--r--`, root-owned, **0 entries** — the corrected
   proof line. `mount | grep emergency/music` matched 0 and **can never match on this Supervisor
   version**; that instrument produces a false *negative*
3. MA logged `Aborting sync for Filesystem (local disk): scan found no files but 1244 were
   previously indexed`
4. **MA's deletion guard HELD: 70 albums before, 70 during the degraded window, 70 after.** The
   library went **stale, not empty** — which is the entire point of the criterion
5. And beyond what was asked: **Supervisor recovered UNATTENDED in 432 s (7 m 12 s)** from
   `nfs-server` returning, NUC untouched throughout — settling the half community reports dispute
   against Supervisor source. `M4b` then fired **on its own** at `13:12:06.616219Z` and re-synced
   MA. Recovery was self-healing; nothing was hand-triggered

The measured recovery interval is **~7 minutes, not the ~900 s the research assumed**.

### Machine gate at plan close — all three exit 0

```
LXC 100 (172.16.1.159), from /mnt/fast/stacks at HEAD 90cdddc, landed by `git pull --ff-only`
  check-music-consumers.sh                exit 0    FAILURES total 0
  check-music-consumers.sh --baseline     exit 0
  check-music-consumers.sh --bogus        exit 2    (contract intact)
  check-music-freeze.sh                   exit 0

workstation
  quick-health-check.sh                   exit 0    both blocks green
```

Consumers summary at close, ANSI stripped, otherwise unedited:

```
📊 6. Summary
  MA version (live):           2.11.0b0   (assertions proven at 2.11.0b0)
  export route:                ssh:172.16.1.158
  ma route:                    http://172.16.1.31:8095
  jellyfin route:              docker-inspect:192.168.90.25:8096
  ha route:                    skipped   (skipped is expected on LXC 100 — see header)
  pinned provider instance:    filesystem_local--XJaJWNUS
  temp provider instance:      <unset — scope=temp-export rows reported, not asserted (D-15)>
  proof albums pinned:         3   (target 3: single-artist, multi-disc, various-artists)
  albums matched in MA:        2   (target 2, exact name+albumartist, provider-attributed)
  MA out-of-scope:             1   (scope=temp-export with no temp provider pinned — reported, not asserted)
  albums matched in Jellyfin:  2   (target 2, exact name+albumartist)
  jellyfin out-of-scope:       1   (scope!=library — reported, not asserted)
  MA albums, local provider:   70   (target >= 3)
  toolchain missing:           0
  export assertions failed:    0
  MA assertions failed:        0
  Jellyfin assertions failed:  0
  FAILURES total:              0
✅ Both music consumers see the pinned albums through the NFS export
```

`quick-health-check.sh` at close, ANSI stripped, otherwise unedited:

```
Music freeze harness: ✅ Intact
    tagger-class writers:        0   (target 0)
    unclassified writers:        0   (target 0)
    declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
    ownership mismatches:        0   (target 0, want 568:568)
Music consumers audit: ✅ Both consumers see the library
    MA version (live):           2.11.0b0   (assertions proven at 2.11.0b0)
    albums matched in MA:        2   (target 2, exact name+albumartist, provider-attributed)
    albums matched in Jellyfin:  2   (target 2, exact name+albumartist)
    FAILURES total:              0
```

The `Traefik dashboard: ❌ Not accessible` line is a **tailnet-vantage artefact** and is present in
D-44's *before* snapshot too. Not a regression.

### The human gate (D-55) — SATISFIED

`check-music-consumers.sh` exiting 0 is the machine verdict. Criterion 3 is ultimately about what a
person sees, and **this project exists because pipelines were declared working three times and were
not.** The operator approved on 2026-09-01 — and closed a gap the machine gate cannot reach, by
**playing tracks** to confirm the audio matches the metadata. Full record in "Closure response"
below.

---

## WHAT IS NOT PROVEN — stated plainly, because a closure verdict that only lists passes is worthless

None of these blocks a criterion. All of them would otherwise be discovered by someone else later.

1. **The mount-failure notification has never been delivered against a genuinely bad mount.**
   `music02_nfs_mount_failed_alert`'s trigger path is proven **by firing** — both new triggers fired
   and are trace-confirmed — and its action gate is proven to swallow a transient and a healthy
   mount (`script_execution: "aborted"`, the notify step never reached). Delivery is proven only as
   "`notify.mobile_app_crusader` is a registered service and both message templates render against
   live state". Closing this needs another deliberate fault injection.
2. **The literal `"0"` in that automation's `to:` list has not itself fired.** Nothing can force
   `"0"` in isolation — any transition into `0` also arms and fires the `crossing` trigger. What is
   proven is the state-trigger mechanism and `to:`-list matching (on `unknown`, from the same list)
   plus a read-back of HA's own loaded config, twice. Sound inference, but an inference.
3. **D-54b is blind at boot and is NOT fixed** — see "Carried forward" below.
4. **`/mnt/tank/media/Music/Def Leppard/Def Leppard (2015)/` is a live library defect, recorded and
   deliberately unrepaired.** It derives an **empty** album artist and hard-errors
   `CD 01-06 Def Leppard - Sea of Love.flac`, because the album folder name equals the artist folder
   name. D-05 forbids tag repair, nobody holds `rw` on Music until Phase 6, and the export is `ro` —
   so the remedy is both forbidden in principle and unavailable in fact. `zpool status -v tank` is
   clean, so this is **not** 2026-07 scrub damage. Handed to Phase 7.

---

## CARRIED FORWARD

### D-54b — the Supervisor repairs-issue wire is DIAGNOSED, NOT FIXED, and is OPEN

Recorded here and in `stacks/selfhosted/arrs/beets.md` § "Still open" so it survives the phase.

**The trigger configuration is correct — proven.** A synthetic
`POST /api/events/repairs_issue_registry_updated` with `{"action":"create","domain":"hassio",…}`
fired it in **542 ms** and the notification delivered.

**It is blind at boot by ORDERING, not by race.** `hassio` mirrors Supervisor issues into HA's
repairs registry **13–18 s before the `automation` domain sets up**, consistently across four
observed starts on 2026-09-01. A **genuine** `{action: create, domain: hassio}` event at
`12:51:53.032Z` hit a trigger that attached at `12:52:21.951Z` — 28.9 s too late. `hassio` is a
bootstrap-stage integration and `automation` is not, so the order does not vary: this misses
**every** time rather than sometimes.

**The recorded fix**, so nobody has to re-derive it: a *state-based* check of Supervisor's resolution
centre at startup — a `command_line` sensor against `http://supervisor/resolution/info` using
`$SUPERVISOR_TOKEN`, which the SSH add-on's sudoers already `env_keep`s — instead of the create
event. Rejected **for now**, on two grounds worth keeping: for the only issue type this phase cares
about it duplicates `music02_nfs_mount_failed_alert`, which now has its own boot trigger; and scoped
any wider it would immediately and repeatedly page for pre-existing issues nobody has chosen to act
on (today: `detached_addon_removed` for `a0d7b954_influxdb`).

### For Phase 7 specifically

- **`scripts/check-music-consumers.sh` with its pinned album set is the tool CONS-04 calls.** CONS-04
  is "a file is imported only when verified with `ffprobe` on the file *and* visible in both Jellyfin
  and Music Assistant". This script is the both-consumers half, and it now runs on every
  `quick-health-check.sh`.
- **`missing_album_artist_action: folder_name` is CONDITIONAL.** It fires only when a file's `album`
  **tag** agrees with its album **folder** name; on a mismatch MA silently yields `Various Artists`
  while `config/providers/get` still reads back `folder_name`. **The API cannot tell you it did not
  fire.** Album identity is `albumartist + os.sep + album`, so a wrong album artist is durable, and
  clearing it means removing the provider — a complete purge of everything exclusive to it, with
  every favourite and play count attached. **Check the precondition; do not assume it.**
- **The mount is proven to survive a reboot and to degrade safely** — stale, never purged — which is
  the precondition Phase 7 was gated on.
- **Every assertion in this phase was proven at MA `2.11.0b0`** — a BETA, `auto_update` **on**,
  stable not installed at all. The version stamp is the drift detector.

### Three runtime-state items live only on the NUC and in no git repository

Recorded in PROJECT.md as a Key Decision so a NUC rebuild is a known cost, not a discovery:

1. **Supervisor's `mounts.json`** — the `music` NFS mount
2. **MA's provider settings** — MA 2.11 does not expose a filesystem provider's `path` through its
   API at all, so this is recoverable *only* from a SUMMARY
3. **MA's `library.db`**

Plus `/config/packages/music02_ma_nfs_mount.yaml` and one `/config/secrets.yaml` key, both
reproduced in `02-08-SUMMARY.md` (fully annotated) and in `beets.md` (the declarations) — the token
excepted, which must be re-minted.

### Rotate at project close

The MA audit credential, the Jellyfin `music-consumers-audit` API key, the MA HA-sync token, and
Discogs. Plus **`Xonora`** — a pre-existing MA long-lived token created 2026-02-21, expiring
**2036**, unused since 2026-03-29, unattributed. And the outstanding UCG-Max root password rotation
recorded in project memory, which is unrelated to this phase but on the same list.

---

## THE SIX SILENT-PASS MECHANISMS — now in one durable place

Written into `stacks/selfhosted/arrs/beets.md` § "The six silent-pass mechanisms found in Phase 2",
because it is operational knowledge about *instruments* and that is the document a future operator
reaches for. Every one produces a **green result from a broken system**.

| # | Mechanism | Found in |
|---|---|---|
| 1 | `music/albums/count` has **no provider parameter** — 87 with and without the arg while the provider-filtered list held 9. Reports green off Spotify with no mount at all | 02-04 |
| 2 | MA `POST /api` responses are **not `.result`-wrapped** — a `.result[]` filter errors, and under `\|\| true` that reads as "no providers" | 02-04 |
| 3 | `missing_album_artist_action` **reads back `folder_name` while silently using `Various Artists`** | 02-07 |
| 4 | **Destroying a `null_resource` removes nothing from the host** — the export stayed live while `terraform plan` reported clean | 02-07 |
| 5 | **Default `ha supervisor logs` depth does not reach back to boot** — a default-depth grep is indistinguishable from "it did not happen"; `-n 2000` was required | 02-08 |
| 6 | **`exportfs -v` printing an export line does not mean that export will serve** | 02-08 |

Listed apart because it is the opposite failure mode: `mount | grep emergency/music` produces a
false **negative** — it can never match on this Supervisor version, so it argues that a working guard
did not fire. And from MA's API rather than this estate: `search` on `library_items` is **not** a
substring match, which produces a false *failure* on a gate whose whole value is being trusted.

Two of the six share a deeper shape worth naming: **a correct observation producing a wrong
inference.** `exportfs -v` really does keep listing the export while the dataset is unmounted (true),
therefore `mountpoint` is not enforced (false) — that stood for three plans. Reading
`missing_album_artist_action` back really does return `folder_name` (true), therefore the fallback
will use the folder name (false).

## M1 IS PROVEN — with the `exportfs -v` correction

Recorded here because it is a **retraction of a claim this phase made twice**. 02-03 and 02-05 both
recorded M1 (the `mountpoint` export option) as configured-but-unproven. It works, and the guard was
working for three plans while being written down as unverified.

Control-probe-control from the NUC, same command, same client, minutes apart, with a dead-man
restore armed on atlantis before the dataset was ever unmounted:

```
A  dataset mounted    -> mount exit 0,   14 entries
B  dataset unmounted  -> mount exit 255, "No such file or directory", 0 entries
C  dataset remounted  -> mount exit 0,   14 entries
```

The control was run **first and deliberately**, to prove the instrument before spending a window:
without it, a failure cannot be distinguished from incapacity. **The export TABLE is
non-discriminating; the SERVED MOUNT is genuinely refused.** 02-03's `threat_flag:
control-not-enforced` against `infra/nfs-music-export.tf` is retired (`a4174e6`), the measurement is
recorded in the file itself, and **the `mountpoint` option must not be removed.** M2
(`After=zfs-mount.service`) remains the first guard; M1 is a proven second.

---

## Deviations from Plan

### 1. [Recorded, not a fix] The plan's `grep -c '\x1b'` acceptance criterion cannot read 0

- **Found during:** Task 1 verification.
- **Issue:** the criterion reads *"The ANSI-strip line uses `$'...'` quoting, not `\x1b` —
  `grep -c '\\x1b' scripts/quick-health-check.sh` outputs `0`"*. It reads **2**, and it read **1**
  before this plan touched the file. The match is not code: it is the 01-09 block's own comment,
  *"`\x1b` is a GNU sed extension and this script runs on macOS"* — the comment the plan explicitly
  instructed be copied **verbatim**.
- **Resolution:** the verbatim-copy instruction wins, and consistency between the two blocks is the
  point. The criterion's *intent* is satisfied and was checked directly: **no non-comment line in the
  file contains `\x1b`**, and both ANSI-strip lines (93 and 125) use
  `LC_ALL=C sed $'s/\033\\[[0-9;]*m//g'`. Recorded rather than resolved by rewording, because
  silently diverging the new block from the one it was told to copy is the worse outcome.

### 2. [Rule 2 — recorded] The `showmount` prohibition applies to what is WRITTEN, not only to what is run

The blocking anti-pattern is that `showmount` and `findmnt` are absent on the NUC. Both `NETWORK.md`
and `beets.md` now mention `showmount` **once each — as a prohibition**: "`showmount` and `findmnt`
do not exist on this host — use `/proc/self/mountinfo` … and `exportfs -v` on atlantis". A future
reader who greps for `showmount` finds the warning, not an instruction. Stated so the grep count of
1 in each file is not read as a violation.

### 3. [Rule 2 — recorded] The consumers block's fatal status is written into the file, not only here

`quick-health-check.sh` now has **two** fatal remote dependencies on LXC 100. The file-level header
note was extended rather than left stale, naming CONS-01/02/03 and the auto-update reasoning,
following the precedent 01-09 set for exactly this: *"a silent-to-failing change is exactly the kind
of thing that should be visible in the file, not only in a plan."*

### 4. [Verified once, as required] The unreachable-host branch was fired for real

Not asserted from reading the code. The block was extracted with the host address replaced by an
unused address:

```
Music consumers audit: ssh: connect to host 172.16.1.253 port 22: Connection refused
⚠️  UNKNOWN — 172.16.1.253 unreachable or the audit produced no output
  The consumers state is unknown, NOT green. Check the host, then re-run:
  ssh root@172.16.1.253 'cd /mnt/fast/stacks && git pull --ff-only && bash scripts/check-music-consumers.sh'
❌ Health check FAILED — see the music freeze harness and/or the consumers audit above.
unreachable-exit=1
```

An unreachable host and a healthy host do not look the same.

### 5. [Resolved, not worked around] The `scp` workaround is gone; the fold-in uses the pull path

02-05, 02-07 and 02-08's first half all flagged that `git pull` on LXC 100 could not land
`check-music-consumers.sh`, and each `scp`'d it in and removed it again. The operator approved a
push in 02-08 (`aa2b502..90cdddc`), so the block was written against the **pull** path and that path
was exercised twice today: `git pull --ff-only` → `Already up to date`, script present at HEAD
`90cdddc`, ran from there, exit 0.

### Not fixed — logged, out of scope

- **`gsd-sdk`'s `state.*` verbs corrupted STATE.md again** — the same family every plan in this phase
  has hit. Repaired by hand and `git diff`'d before committing. See "SDK repairs" below.
- The untracked `body.txt` at repo root, left alone as in 02-03 through 02-08.
- Two pre-existing untracked files on LXC 100 (`prometheus.yaml.bak`,
  `monitoring.app.yaml.disabled`) and a pre-existing `stash@{0}: On main: media` — none touched.
- **Spotify is still `auth_required`** on the MA instance. Pre-existing, not caused here, not fixed.
  Every assertion is provider-filtered and the filter was never relaxed.
- **Nothing was pushed.** See "Repository state" below.

## Authentication gates

None. Every credential was referenced by variable name and read from `~/.claude/secrets/` or
`/mnt/fast/secrets/` at the point of use; none reached argv and none entered this repository.

## Threat Register Status

| Threat ID | Disposition | Status at plan close |
|-----------|-------------|----------------------|
| T-02-05 | mitigate | **CLOSED.** `git grep -nE '(eyJ[A-Za-z0-9_-]{10,}\|Bearer [A-Za-z0-9._-]{20,})'` across the whole tree returns **nothing**. The HA token appears in `beets.md` only as its `!secret` reference. Every credential is named by variable. |
| T-02-38 | accept | **HELD.** The export line published in `NETWORK.md` and `beets.md` contains only RFC 1918 addresses and uid/gid values already stated openly in `STANDARDS.md`, `NETWORK.md` and `CLAUDE.md`. The control is the export table on a LAN-only service; 2049 is not port-forwarded. |
| T-02-37 | mitigate | **CLOSED.** D-41 done: the consumers check runs on every `quick-health-check.sh`, the path already in use. With the MA add-on on `auto_update` this is the only detector of an MA release changing provider behaviour. |
| T-02-39 | mitigate | **CLOSED, by firing.** `$?` captured before any pipe; empty output → `UNKNOWN` + `EXIT_CODE=1`; verified once against a deliberately unreachable host (deviation 4). |
| T-02-40 | mitigate | **CLOSED.** Every criterion has an explicit verdict naming its evidence and producing plan; criterion 1's five sub-parts are individually named; criterion 2 states 4b not 4a; criterion 4 cites both halves with 4b's five evidence items. A "WHAT IS NOT PROVEN" section lists four items that pass no criterion. |
| T-02-04 | mitigate | **CLOSED.** `sec=sys` is recorded in PROJECT.md as a considered-and-rejected-alternatives **choice**, with `xprtsec=` (RFC 9289) and `sec=krb5` named and the reason for rejecting each. A future security review meets an answer, not a silence. |
| T-02-26 | mitigate | **CLOSED.** The three NUC-only runtime-state items are recorded in PROJECT.md and above. |

## Threat Flags

None new. This plan created no network endpoint, no auth path, no file access pattern and no schema
change. It wrote documentation and one health-check block.

Carried, unchanged in kind, from 02-07/02-08 and now also recorded in `beets.md`:
`threat_flag: state-not-in-git` against the MA provider configuration and the NUC's HA package file.

## Known Stubs

None. The one intentionally unresolved item is the `Def Leppard (2015)` empty-album-artist defect,
which is a **finding handed to Phase 7**, not a stub: the remedy is forbidden here by D-05 and
physically unavailable through a read-only export.

## SDK repairs

`gsd-sdk query state.*` corrupted `.planning/STATE.md` again, in the same family every plan in this
phase has recorded. Repaired by hand and verified with `git diff .planning/STATE.md` against a
pre-write copy before committing. `state.add-decision` and `state.record-metric` take **named
flags**, not positionals — passed positionally they return `{"error": ...}` and, if the output is
discarded, write nothing while looking like success. `requirements.mark-complete` was not invoked:
this plan completes no requirement that was not already ticked, and 02-07 caught that verb ticking
CONS-03 unearned.

## Repository state

**Nothing was pushed.** The operator's push approval in 02-08 covered `aa2b502..90cdddc` only. The
tree finishes this plan **5 commits ahead of `origin/main`** — `a4174e6` and `6ff2332` from 02-08,
plus this plan's `9f915a9`, `e37039b` and the closing commit. Pushing is the operator's call.

Note the consequence, so it is not a surprise: `/mnt/fast/stacks` on LXC 100 is at `90cdddc` and
therefore does **not** yet carry the folded-in `quick-health-check.sh`. That does not matter — that
script runs from the **workstation**, not from LXC 100 — but a future `git pull` there is what lands
the rest.

## Requirements

| Req | State after this plan | Owner |
|---|---|---|
| CONS-01 | **Complete** (02-03 parts 1a/1b/1c + 02-05 parts 1d/1e). M1's "configured-but-unproven" caveat was corrected in 02-08; the export now has **standing** coverage on every `quick-health-check.sh` | closed |
| CONS-02 | **Complete** (02-06 + 02-07). Three albums, exact on album name AND album artist, provider-attributed. Now asserted continuously | closed |
| CONS-03 | **Complete** (02-08). Two reboots — one healthy, one with the server deliberately dead. MA's view survived both | closed |

No requirement was ticked by this plan. It completes none that was not already earned.

## Closure response

**✅ APPROVED 2026-09-01. D-55's closure gate is SATISFIED and the phase is CLOSED.**

Operator's words, verbatim:

> "i have spot checked a couple and played them to make sure the song matchs - all good, no various
> artists, no singles . mastermix is not there"

### The operator did MORE than the gate asked, and that is the finding

The gate asked for the albums to *appear* under the right album artists. The operator browsed Music
Assistant's **Filesystem (local disk)** provider directly, spot-checked several albums, and
**played tracks to confirm the audio matches the metadata**.

**No assertion in this phase could have done that last part.** Every automated check in
`check-music-consumers.sh` verifies that **MA's database says the right thing** — album name,
`artists[0].name`, `provider_mappings[]` — and not that **the bytes behind the entry are the right
song**. And the documented stale state this phase spent two plans characterising is precisely
*"entries exist, playback of any of them fails"*: during the negative control MA held 70 albums that
were all unplayable, and every database-level assertion about them would still have passed.
**Playback is the only test that closes that gap, and it is not automatable from here.**

So the human gate caught a class of failure the machine gate is **structurally** unable to reach.
That is the whole reason D-55 exists, and it is the seventh entry in this project's running theme:
a check can be green for a reason that has nothing to do with the thing you care about.

### What was observed

| Observation | Significance |
|---|---|
| Browse root of `Filesystem (local disk)` lists **exactly 13 artist folders**, every one a single named artist — Benson Boone, BLACKPINK, Chris Norman, Def Leppard, Ed Sheeran, Garth Brooks, Hawthorne Heights, Katy Perry, Lady Gaga, P!nk, Sabrina Carpenter, Taylor Swift, Vengaboys | Independently confirms **D-08** (the library holds no Various Artists compilation) **from the consumer side**, and matches `sensor.music_library_nfs_mount` = 13 exactly — two instruments, one number |
| `Chris Norman / Lifelines (2026)` opened: **15 tracks, every row attributed `Chris Norman • Lifelines • 2026`** | Criterion 3's exact match on album name AND album artist, confirmed **by eye** rather than only by API — and at track level, not just album level |
| **Tracks played; the audio matches the metadata** | The one thing no assertion in this phase could reach. See above |
| **No `Various Artists` entry anywhere** | The `missing_album_artist_action` fallback never misfired on real library content. The 02-07 matrix showed it *can* yield `Various Artists` on an album-tag/album-folder mismatch; on this library's actual content it did not |
| **No stray singles** — no loose tracks promoted to album entries | The provider's `content_type: music` and the tree's `ALBUMARTIST/Album/NN Title` shape are behaving as intended |
| **`Mastermix Essential Hits - Pop 4 - 2005-2009` is ABSENT** | **The correct result, and it is positive evidence.** It was served through the temporary export, and both it and provider `filesystem_local--f5gkrCpU` were torn down in 02-07. Its absence is **D-46's two-sided teardown confirmed from the consumer side, after the fact** — a fourth, independent check on top of the four assertions 02-07 executed |

### One thing that is present and must not be misread

**The `Def Leppard` folder IS visible in the browse listing. That is expected and is NOT the defect
being resolved.** The known defect is at the album/track level *inside* it:
`Def Leppard/Def Leppard (2015)/` derives an **empty** album artist and hard-errors
`CD 01-06 … Sea of Love.flac`, because the album folder name equals the artist folder name. The
artist folder itself is perfectly normal and holds other albums. **The defect remains deliberately
unrepaired under D-05** — nobody holds `rw` on Music until Phase 6 and the export is `ro` — and it is
still owned by Phase 7. Stated explicitly so a future reader does not read the folder's presence as
the defect having gone away.

### What this approval does NOT sweep up

The operator approved **criterion 3 — what a person sees in Music Assistant**. It is not an approval
of the two items recorded open above, and neither is closed by it:

1. **D-54b (`music02_supervisor_issue_raised`) is blind at boot and NOT fixed** — diagnosed, with its
   fix recorded and deliberately deferred.
2. **The mount-failure notification has never been delivered against a genuinely bad mount** — its
   trigger path and action gate are proven by firing; delivery is proven only as "service registered
   + templates render".

Both remain in `.planning/STATE.md` § Blockers/Concerns and in
`stacks/selfhosted/arrs/beets.md` § "Still open".

**PHASE 02 IS CLOSED.** All five criteria proven, CONS-01/02/03 complete, standing coverage in
place, and the human gate satisfied by a stronger test than it asked for.

## Self-Check

Files claimed created or modified:

- `.planning/phases/02-nfs-export-and-music-assistant-reachability/02-09-SUMMARY.md` — this file
- `scripts/quick-health-check.sh` — modified, `bash -n` exit 0, full run exit 0
- `.planning/PROJECT.md` — modified, 40 insertions / **11 deletions** (the rewrite, not an append)
- `stacks/selfhosted/arrs/beets.md` — modified, new `## Phase 2` H2 present
- `NETWORK.md` — modified, contains `2049`, `/mnt/tank/media/Music`, `172.16.1.31`,
  `nfs-music-export.tf` and Music Assistant

Commits:

- `9f915a9` — `feat(02-09): fold the consumers audit into quick-health-check.sh`
- `e37039b` — `docs(02-09): record criterion 5 — the mount route, the export, and the operational detail`

Live state re-verified at close:

- `bash scripts/quick-health-check.sh` → **0**, both blocks green
- `bash scripts/check-music-consumers.sh` on LXC 100 → **0**; `--baseline` → 0; `--bogus` → 2
- `bash scripts/check-music-freeze.sh` on LXC 100 → **0**
- `terraform plan -detailed-exitcode` → **0**
- `git grep -nE '(eyJ[A-Za-z0-9_-]{10,}|Bearer [A-Za-z0-9._-]{20,})'` → **nothing**
- MA version live → **2.11.0b0**; albums, `filesystem_local--XJaJWNUS` → **70**

## Self-Check: PASSED
