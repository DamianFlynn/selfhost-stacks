---
phase: 04-collapse-to-one-tagger
plan: 11
subsystem: infra
tags: [sabnzbd, recreate, boot-proof, ro-mount, deletion, ledger, fence, promotion, health-check, d-09, d-11, d-13, d-21, d-25, d-32]

# Dependency graph
requires:
  - plan: 04-10
    provides: "the vendored+stripped audio.bash (7e3bfe61…), the fixed beets-config.yaml (ba7ef255…), the :ro mount declarations in sabnzbd.yaml, and the drift block as a candidate"
  - plan: 04-09
    provides: "the D-09 prior (a :ro single-file mount into an LSIO /config), the init-race lesson (wait for readability, never for `running`), the survivor's fresh library.db, and the finding that beets 2.13.1 writes 11 migration .bak on first open"
  - plan: 04-06
    provides: "the candidate census (TAGGER_CENSUS_PROMOTED=0) and the pre-widened quick-health-check selector, so promotion was a two-constant change"
  - plan: 04-01
    provides: "the fence, the real MANIFEST path, the 24-row coverage preview, the live baselines and the ROUTINE BASELINE"
provides:
  - "the stripped audio.bash and the fixed beets-config.yaml are LIVE on the host, both bind-mounted :ro, proven by a boot: init exited 0, HTTP 200, both mounts RW=false, in-container sha256 = repo"
  - "D-09 CLOSED for sabnzbd: EROFS lines DO occur (2, from scripts_init.bash's chmod 777 -R /config/scripts) and :ro is KEPT — research assumption A1 is now measured, not assumed"
  - "a 36-row per-file deletion ledger: every deleted file has a fence copy, a sha256, a MANIFEST line and (for SQLite) integrity ok, recorded BEFORE its rm"
  - "sabnzbd's beets state is gone (25 files) and the 11 survivor migration .bak are gone (operator ruling), so the census `beets databases` counter reads exactly 1"
  - "both guards promoted into the routine fatal path in the same commit as the runs that turned them green (TAGGER_CENSUS_PROMOTED=1, VENDORED_DRIFT_PROMOTED=1), with the sixth EXIT-CODE notice"
  - "four post-promotion driven controls proving both blocks now fail through the ROUTINE path and neither env var can disable them"
affects: [04-12, 04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Install a vendored file with `cp` onto the EXISTING inode and assert the inode number is unchanged: a single-file bind mount follows the inode, so `mv`/`install` would silently detach the mount while leaving a correct-looking file on disk"
    - "A boot proof gates `docker exec` on the capability actually needed (`test -r`) and prints the log's BYTE COUNT beside every grep taken over it, so neither an init race nor an empty log can manufacture a clean reading"
    - "A failed boot is CLASSIFIED (EROFS / NETWORK / UNCLASSIFIED) from the logs before any mount is touched, so an upstream outage can never be mistaken for a `:ro` failure and weaken a security control"
    - "A deletion ledger keyed on the fence PATH as well as the sha256: `sqlite3 .backup` of two different empty databases produces byte-identical output, so a sha-only ledger would let one fence line appear to cover two sources"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-11-SUMMARY.md
  modified:
    - scripts/check-music-freeze.sh
    - scripts/quick-health-check.sh
  host-modified:
    - "/mnt/fast/appdata/arrs/sabnzbd/config/scripts/audio.bash (cp onto inode 131690; fdcddca2… -> 7e3bfe61…)"
    - "/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml (cp onto inode 22136; 7a059a40… -> ba7ef255…)"
    - "/mnt/fast/safety/music-pre-project/MANIFEST.txt (888 -> 963 lines, append-only proven)"
  host-deleted:
    - "(host) 25 sabnzbd beets files: scripts/library.blb + 11 .bak, scripts/beets.log, .config/beets/library.db + 11 .bak"
    - "(host) 11 survivor migration .bak beside /mnt/fast/appdata/arrs/beets/config/library.db (operator ruling)"
    - "(host dirs) /mnt/fast/appdata/arrs/sabnzbd/config/.config/beets and its now-empty parent .config (rmdir, never rm -rf)"

key-decisions:
  - "`:ro` is KEPT on both sabnzbd vendored files even though two EROFS lines appeared. The D-09 rule is explicit — EROFS lines with a healthy container and init exited 0 are recorded, not rolled back — and sabnzbd.yaml was therefore not edited at all"
  - "The 11 survivor migration .bak were fenced and deleted BY EXACT NAME through the same ledger discipline as sabnzbd's files. The operator ruled 'Delete the 11, fenced' and explicitly REJECTED teaching the census to ignore .bak, which would have re-created DEF-03-01's blindness"
  - "Fence copies were written under a never-overwrite rule: where the 04-01 naming convention collided with an existing fence file (13 of 35), a UTC stamp was appended rather than overwriting the Phase 1 copy"
  - "REMOTE_TIMEOUT left at 120 s on measurement: the slowest promoted check ran in 4 s (04-06 measured 6 s). REVIEWS row 17's condition (raise to 200 iff a candidate exceeded 60 s) was not met"

requirements-completed: [TAGR-05]  # C4-a is now true LIVE and not merely in git: both remaining beets configs on the host declare musicbrainz, and config.yaml.old is absent with config.yaml present as the positive control.
requirements-advanced: [TAGR-04]   # The strip is now LIVE on the host and running from a :ro mount, which is TAGR-04's static half. The behavioural half (D-12: a real music job completing with no tagger) is 04-12's, and is deliberately NOT claimed here.

# Metrics
duration: ~20min
completed: 2026-09-13
---

# Phase 4 Plan 11: Host Install, the Deletion Ledger and the Promotion Summary

**sabnzbd now runs the stripped hook from a read-only mount, and it was proven by a boot rather than asserted: init exited 0 over a 43,499-byte log, HTTP 200, both mounts `RW=false`, in-container hashes equal to the repo — with two `Read-only file system` lines present and deliberately kept, because D-09 says a healthy container plus `exited 0` is a pass, not a rollback. Thirty-six files then left the estate, each through a ledger row carrying a verified fence copy, and the census counter that has read 36 all phase now reads exactly 1. Both standing guards were promoted in the same commit as the runs that turned them green, and then driven red through the routine path.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-13 ~09:28Z
- **Completed:** 2026-09-13 ~09:47Z
- **Tasks:** 3 of 3
- **Files:** 2 repo scripts modified (1 commit), plus this summary. On the host: 2 files installed, 36 deleted, 2 directories removed, 35 fence copies written, 75 MANIFEST lines appended.

## Accomplishments

- **D-09 is answered for sabnzbd specifically, and the answer is not the one 04-09 saw.** The survivor logged *zero* EROFS lines; sabnzbd logs **two**, because `scripts_init.bash` runs `chmod 777 -R /config/scripts` over exactly the files now mounted `:ro`. Research assumption **A1 is now measured**: the ownership pass tolerates EROFS, `scripts_init.bash` has no `set -e`, and init still exits 0.
- **The install could not have silently detached the bind mount.** Both files were `cp`'d onto their existing inodes and the inode numbers were asserted unchanged (131690, 22136). A `mv` would have left a correct-looking file that the container never sees.
- **Nothing was pulled.** The image id is byte-identical before and after (`sha256:64c5054…`), so PR #310's 5.1.3 did not sneak a version change into the boot proof.
- **Every one of the 36 deleted files has a verified copy.** 35 fresh `sqlite3 .backup` copies, each `integrity_check ok` and each with a MANIFEST line; 1 (`beets.log`) already covered by its 04-01 line, re-verified. The MANIFEST grew 888 → 963 with the pre-append prefix hash unchanged.
- **The counter reached its target exactly.** `beets databases` went 36 → **1**, the arithmetic the operator ruling predicted (25 sabnzbd + 11 survivor `.bak` removed). It was not adjusted, and the classifier was not narrowed.
- **No red window, and the guards were proven able to fail *after* promotion.** Both routine checks exit 0; then p1 and p3 drove each block red through the routine path with no candidate env set at all.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Install both vendored files; recreate sabnzbd; boot proof + classification | **none** — host-only, no repo file changed (the 04-01 / 04-07 / 04-09 precedent). `sabnzbd.yaml` was untouched because no rollback was required. Evidence below |
| 2 | Per-file fence ledger, then ledger-gated deletion | **none** — host-only (appdata + `/mnt/fast/safety`) |
| 3 | Candidate green → promote both guards → routine green → driven controls | **`2572b71`** |

**Plan metadata:** this SUMMARY's own commit.

## Delivery

| Item | Value |
|---|---|
| Pushed | `c41593c..2572b71  main -> main` |
| origin `refs/heads/main` | `2572b71e22da506bebb473571b9334dee47144e6` |
| Host `/mnt/fast/stacks` HEAD before | `c41593c` |
| Host HEAD after `git pull --ff-only` | **`2572b71`** (fast-forward, `pull_rc=0`) |
| Host porcelain | the same 2 pre-existing untracked files, before and after — not mine, untouched |

The pull also carried `.planning/STATE.md` from the orchestrator's own wave-5 tracking commit (`9157de3`), which was already on the workstation when this plan started. **This plan did not modify STATE.md or ROADMAP.md** — see Self-Check.

---

## Re-derivation before acting

Every orchestrator fact this plan depended on was re-measured from the live estate first.

| Fact | Stated | Re-derived 2026-09-13 | Verdict |
|---|---|---|---|
| live `audio.bash` | `fdcddca2…` | `fdcddca234b282e4cb396764fa125fcacdbce350c21a94dd3f4ac024f87077ca` | unchanged |
| live sabnzbd `beets-config.yaml` | `7a059a40…` | `7a059a407d3ca18c9d7902c96267f75fa17ae134daf21d64f8bcbf7c073ee6ea` | unchanged |
| live survivor `config.yaml` | `a2f94cb6…` | `a2f94cb6…` (equals the repo copy — already green) | unchanged |
| host HEAD | `c41593c` | `c41593cb08042638283215b2bff981ff29b78e30` | equal |
| sabnzbd image resident | `5.1.0` | `sha256:64c505440b78…`, digest `…e79d3fd9282b…` | resident |
| `library-db/MANIFEST.txt` | plan cites it | **does not exist** | plan defect (Deviation 1) |
| ledger scope | 25 sabnzbd files | 25, **+ 11 survivor `.bak` = 36** | per operator ruling |

**One fact was materially different from the orchestrator's note, and it mattered.** The running sabnzbd container was created **2026-08-31**, before 04-10 wrote the mount declarations — so it had **no `/config/scripts/audio.bash` mount at all** and `beets-config.yaml` at **`RW=true`**. The `:ro` binds did not exist at runtime until this recreate created them. That is why 04-10's drift block was red for a real reason, and it means the boot proof below is the first time either `:ro` mount has ever existed on this container.

---

## Task 1: install, recreate, boot proof

### Pre-checks — all met before anything was installed

| Pre-check | Required | Measured |
|---|---|---|
| `image:` tag at host HEAD resident | yes | `ghcr.io/linuxserver/sabnzbd:5.1.0`, `docker image inspect` rc 0, id `sha256:64c505440b78…` |
| Queue idle | `noofslots` 0 | **`Idle\|0\|false`** — no polling needed |
| Baseline recorded | yes | `StartedAt=2026-08-31T17:49:26Z`, `RestartCount=0`, log 6,113,274 B, last boot `scripts_init.bash: exited 0` |

**The SAB API key never entered argv.** It was read with `grep`+`sed` into a shell variable inside the remote process and reached curl only through `curl -K <(printf 'url = "…apikey=%s"' "$KEY")` — `printf` is a builtin, so no process ever carried it. Only `status`, `noofslots` and `paused` were printed; the key's *length* (32) was printed as proof it was read, never its value. No `ps`/`pgrep -a` was run in the window, and nothing key-shaped appears in this file.

**On "no download is in flight":** the SAB *queue* is genuinely idle, and that is the precondition the plan sets. But `/mnt/tank/downloads/incomplete` does hold **6 stale orphan directories** dated 2026-01-05 to 2026-01-23, with **zero files modified in the previous 2 hours**. They are abandoned leftovers, not an active job — recorded so a future reader does not read "6 incomplete folders" as a contradiction of "queue idle". Zero music completions in 24 h.

### Install — onto the existing inode

| File | Inode | Mode | sha256 before → after | = repo? |
|---|---|---|---|---|
| `…/scripts/audio.bash` | **131690 → 131690** | 777 → 777 | `fdcddca2…` → **`7e3bfe61…`** | **yes** |
| `…/scripts/beets-config.yaml` | **22136 → 22136** | 777 → 777 | `7a059a40…` → **`ba7ef255…`** | **yes** |

`audio.bash` remained executable (`test -x` → `EXECUTABLE-OK`). Neither file was `mv`'d or `install`'d.

### Recreate

```
### RECREATE at stamp=2026-09-13T09:35:45Z
compose_config_rc=0
 Container sabnzbd Recreate / Recreated / Starting / Started
compose_up_rc=0
```

`docker compose … up -d --no-deps --pull never sabnzbd`. Every compose invocation used `--quiet`.

### The boot proof (C3-b) — all required values

| Assertion | Required | Measured |
|---|---|---|
| `[custom-init] scripts_init.bash: exited 0` after the stamp | present | **present**, ~40 s after the stamp |
| log bytes since the stamp | non-empty | **43,499** — printed beside every grep, so no reading below is taken over an empty log |
| `.State.Status` | running | **running** (`StartedAt=2026-09-13T09:35:50Z`, `RestartCount=0`) |
| HTTP on `:8084` | 200 | **200** |
| `/config/scripts/audio.bash` mount | `RW=false` | **false** |
| `/config/scripts/beets-config.yaml` mount | `RW=false` | **false** |
| in-container `audio.bash` sha256 | = repo | **`7e3bfe61…`** |
| in-container `beets-config.yaml` sha256 | = repo | **`ba7ef255…`** |
| image id after | unchanged | **`sha256:64c505440b78…`** — `IMAGE-UNCHANGED`, nothing pulled |
| queue after | idle | **`Idle\|0\|false`** |

Full `[custom-init]` sequence since the stamp: `No custom services found, skipping…` → `Files found, executing` → `scripts_init.bash: executing…` → `scripts_init.bash: exited 0`.

### The EROFS lines — Pitfall 7 measured, and `:ro` deliberately KEPT

Exactly two lines matched `Read-only file system|EROFS|lsiown|chmod:`, quoted verbatim:

```
chmod: changing permissions of '/config/scripts/audio.bash': Read-only file system
chmod: changing permissions of '/config/scripts/beets-config.yaml': Read-only file system
```

These are `scripts_init.bash`'s `chmod 777 -R /config/scripts` hitting the two `:ro` binds. **`CLASS=HEALTHY`**: init exited 0 and the container is running, so the D-09 rule applies as written — *"if EROFS lines appear but the container is healthy, keep `:ro` and record the lines"*. **`sabnzbd.yaml` was not edited**, which is why Task 1 carries no commit.

This differs from 04-09's survivor result (zero EROFS lines) for the reason 04-09 predicted: sabnzbd additionally runs `scripts_init.bash`'s recursive `chmod`. Research assumption **A1** — `lsiown`/`chmod` tolerate EROFS non-fatally, `scripts_init.bash` has no `set -e` — is now **measured on this estate**, not assumed.

### Classification was available and would have fired

The classifier ran on every path, not only on failure. Had init not exited 0 or the container not been running, it would have counted EROFS lines *naming a vendored file* and network-error lines (`Could not resolve host`, `Temporary failure in name resolution`, `Failed to connect`, `Connection timed out`, `ConnectionError`, `NewConnectionError`) and emitted `CLASS=EROFS` / `CLASS=NETWORK` / `CLASS=UNCLASSIFIED` **before any mount was touched**. It reported `CLASS=HEALTHY`. No rollback branch was entered, and `:ro` was never weakened.

---

## Task 2: the deletion ledger

### Producer status first

The listing `find` exited **0**, and the same pass was required to list `/config/scripts/audio.bash` as its positive control — **`audio.bash VISIBLE`**. The survivor's real `library.db` was asserted **not** to be in the target list before anything proceeded. Target count: **36**.

### The ledger — one complete row per deleted file

`live sha` and `fence sha` are 12-char prefixes; MANIFEST line numbers are in the fence-root `MANIFEST.txt`. All 35 SQLite rows are `integrity ok`; the one non-SQLite row is `beets.log`.

| # | Live file | Size | Live sha | Fence file | Fence sha | MAN line | Int | Source |
|---|---|---|---|---|---|---|---|---|
| 1 | `arrs/beets/config/library.db-before-albums-multi_genre_field.bak` | 53248 | `b4b806ed1c4b` | `arrs_beets_config_library.db-before-albums-multi_genre_field.bak` | `9e9cfbeea0b0` | 895 | ok | fresh-04-11 |
| 2 | `…beets…library.db-before-albums-relative_path.bak` | 53248 | `621eace43139` | `arrs_beets_config_library.db-before-albums-relative_path.bak` | `aee85738f4e1` | 897 | ok | fresh-04-11 |
| 3 | `…beets…library.db-before-items-instrumental_lyrics_in_flex_field.bak` | 53248 | `49b19f0c8679` | `arrs_beets_config_…instrumental_lyrics_in_flex_field.bak` | `ff116bc74a30` | 899 | ok | fresh-04-11 |
| 4 | `…beets…library.db-before-items-lyrics_metadata_in_flex_fields.bak` | 53248 | `3b829315138d` | `arrs_beets_config_…lyrics_metadata_in_flex_fields.bak` | `745b41954331` | 901 | ok | fresh-04-11 |
| 5 | `…beets…library.db-before-items-multi_arranger_field.bak` | 53248 | `a06041b9e204` | `arrs_beets_config_…multi_arranger_field.bak` | `33eadfdd73bb` | 903 | ok | fresh-04-11 |
| 6 | `…beets…library.db-before-items-multi_composer_field.bak` | 53248 | `f661a3eb2827` | `arrs_beets_config_…multi_composer_field.bak` | `e18a5d7199a7` | 905 | ok | fresh-04-11 |
| 7 | `…beets…library.db-before-items-multi_genre_field.bak` | 53248 | `d4accc637ce4` | `arrs_beets_config_…multi_genre_field.bak` | `bfcb0c195b7d` | 907 | ok | fresh-04-11 |
| 8 | `…beets…library.db-before-items-multi_lyricist_field.bak` | 53248 | `c677ad7fcf32` | `arrs_beets_config_…multi_lyricist_field.bak` | `7311d2f0cd6a` | 909 | ok | fresh-04-11 |
| 9 | `…beets…library.db-before-items-multi_remixer_field.bak` | 53248 | `56c2f7f4ec8b` | `arrs_beets_config_…multi_remixer_field.bak` | `479f5d9f1fb7` | 911 | ok | fresh-04-11 |
| 10 | `…beets…library.db-before-items-relative_path.bak` | 53248 | `7affb204a10f` | `arrs_beets_config_…relative_path.bak` | `184e9ea48baf` | 913 | ok | fresh-04-11 |
| 11 | `…beets…library.db-before-items-remove_inherited_artpath.bak` | 53248 | `0965639c84fe` | `arrs_beets_config_…remove_inherited_artpath.bak` | `d53a49fe980c` | 915 | ok | fresh-04-11 |
| 12 | `sabnzbd/config/.config/beets/library.db` | 57344 | `00635fb3bc35` | `arrs_sabnzbd_config_.config_beets_library.db.20260913T093821Z` | `7d994233fecc` | 917 | ok | fresh-04-11 |
| 13 | `…\.config/beets/library.db-before-albums-multi_genre_field.bak` | 57344 | `f6e3444c39dc` | `arrs_sabnzbd_config_.config_beets_…albums-multi_genre_field.bak` | `a5858ec65b83` | 919 | ok | fresh-04-11 |
| 14 | `…\.config/beets/library.db-before-albums-relative_path.bak` | 57344 | `dad8c395e9a6` | `…_.config_beets_…albums-relative_path.bak` | `ca1cf16ed88c` | 921 | ok | fresh-04-11 |
| 15 | `…\.config/beets/library.db-before-items-instrumental_lyrics_in_flex_field.bak` | 57344 | `d74fe7c0f36a` | `…_.config_beets_…instrumental_lyrics_in_flex_field.bak` | `e4fcbcb006fc` | 923 | ok | fresh-04-11 |
| 16 | `…\.config/beets/library.db-before-items-lyrics_metadata_in_flex_fields.bak` | 57344 | `ffd3f14b1316` | `…_.config_beets_…lyrics_metadata_in_flex_fields.bak` | `6f893be4482a` | 925 | ok | fresh-04-11 |
| 17 | `…\.config/beets/library.db-before-items-multi_arranger_field.bak` | 57344 | `2f4ae43b15e3` | `…_.config_beets_…multi_arranger_field.bak` | `f89a347cc3f2` | 927 | ok | fresh-04-11 |
| 18 | `…\.config/beets/library.db-before-items-multi_composer_field.bak` | 57344 | `4b8923340d92` | `…_.config_beets_…multi_composer_field.bak` | `3b2ded13bba1` | 929 | ok | fresh-04-11 |
| 19 | `…\.config/beets/library.db-before-items-multi_genre_field.bak` | 57344 | `86d6519bb022` | `…_.config_beets_…multi_genre_field.bak` | `e8215f8cdf3e` | 931 | ok | fresh-04-11 |
| 20 | `…\.config/beets/library.db-before-items-multi_lyricist_field.bak` | 57344 | `56dd34c217e6` | `…_.config_beets_…multi_lyricist_field.bak` | `d307b2c1db0e` | 933 | ok | fresh-04-11 |
| 21 | `…\.config/beets/library.db-before-items-multi_remixer_field.bak` | 57344 | `d3245dbdad90` | `…_.config_beets_…multi_remixer_field.bak` | `34c0b5d83daa` | 935 | ok | fresh-04-11 |
| 22 | `…\.config/beets/library.db-before-items-relative_path.bak` | 57344 | `d69ae2d2a589` | `…_.config_beets_…relative_path.bak` | `0f33075ed322` | 937 | ok | fresh-04-11 |
| 23 | `…\.config/beets/library.db-before-items-remove_inherited_artpath.bak` | 57344 | `c99dec76c4d0` | `…_.config_beets_…remove_inherited_artpath.bak` | `a93904fe7c7b` | 939 | ok | fresh-04-11 |
| 24 | `sabnzbd/config/scripts/beets.log` | 12046 | `7d95c924d442` | `audit/sabnzbd-beets.log.20260911T180026Z` | `7d95c924d442` | **884** | n/a | **existing** |
| 25 | `sabnzbd/config/scripts/library.blb` | 53248 | `b0eb3807939a` | `arrs_sabnzbd_config_scripts_library.blb.20260913T093821Z` | `218c8245e169` | 941 | ok | fresh-04-11 |
| 26 | `…/scripts/library.blb-before-albums-multi_genre_field.bak` | 53248 | `6384628d99af` | `…scripts_library.blb-before-albums-multi_genre_field.bak.20260913T093821Z` | `9e9cfbeea0b0` | 943 | ok | fresh-04-11 |
| 27 | `…/scripts/library.blb-before-albums-relative_path.bak` | 53248 | `f0db3d02f594` | `…-albums-relative_path.bak.20260913T093821Z` | `aee85738f4e1` | 945 | ok | fresh-04-11 |
| 28 | `…/scripts/library.blb-before-items-instrumental_lyrics_in_flex_field.bak` | 53248 | `4043771424ab` | `…-instrumental_lyrics_in_flex_field.bak.20260913T093821Z` | `ff116bc74a30` | 947 | ok | fresh-04-11 |
| 29 | `…/scripts/library.blb-before-items-lyrics_metadata_in_flex_fields.bak` | 53248 | `623f81f4d325` | `…-lyrics_metadata_in_flex_fields.bak.20260913T093821Z` | `745b41954331` | 949 | ok | fresh-04-11 |
| 30 | `…/scripts/library.blb-before-items-multi_arranger_field.bak` | 53248 | `ab4d35f7a8ae` | `…-multi_arranger_field.bak.20260913T093821Z` | `33eadfdd73bb` | 951 | ok | fresh-04-11 |
| 31 | `…/scripts/library.blb-before-items-multi_composer_field.bak` | 53248 | `568addcb1ad2` | `…-multi_composer_field.bak.20260913T093821Z` | `e18a5d7199a7` | 953 | ok | fresh-04-11 |
| 32 | `…/scripts/library.blb-before-items-multi_genre_field.bak` | 53248 | `44a232614b49` | `…-multi_genre_field.bak.20260913T093821Z` | `bfcb0c195b7d` | 955 | ok | fresh-04-11 |
| 33 | `…/scripts/library.blb-before-items-multi_lyricist_field.bak` | 53248 | `d90b372e8a8b` | `…-multi_lyricist_field.bak.20260913T093821Z` | `7311d2f0cd6a` | 957 | ok | fresh-04-11 |
| 34 | `…/scripts/library.blb-before-items-multi_remixer_field.bak` | 53248 | `ee744b7d9ff1` | `…-multi_remixer_field.bak.20260913T093821Z` | `479f5d9f1fb7` | 959 | ok | fresh-04-11 |
| 35 | `…/scripts/library.blb-before-items-relative_path.bak` | 53248 | `8e74178fda12` | `…-relative_path.bak.20260913T093821Z` | `184e9ea48baf` | 961 | ok | fresh-04-11 |
| 36 | `…/scripts/library.blb-before-items-remove_inherited_artpath.bak` | 53248 | `d0f26f5ed698` | `…-remove_inherited_artpath.bak.20260913T093821Z` | `d53a49fe980c` | 963 | ok | fresh-04-11 |

**Counts:** ledger rows **36**; `existing` **1**; `fresh-04-11` **35**; SQLite rows **35**, of which `integrity ok` **35**; rows whose fence file is missing **0**; files deleted **36**; directories removed **2**.

**A sha-only ledger would have been wrong here, and the fence proves why.** Rows 1 and 26 share the fence sha `9e9cfbeea0b0`; so do 2/27, 3/28, 4/29, 5/30, 6/31, 7/32, 8/33, 9/34, 10/35 and 11/36. `sqlite3 .backup` of two *different* empty databases with the same schema produces byte-identical output. This is exactly the hazard 04-01 flagged ("MANIFEST lines 847 and 848 carry the same sha256… a sha-keyed ledger must match on the fence *path* too"), and the ledger keys on **path + sha**, so no fence line can appear to cover two sources.

### MANIFEST — append-only, at the real path

| Item | Value |
|---|---|
| Lines before | **888** |
| Lines after | **963** (75 appended: 1 blank + 4 header comments + 35 × 2) |
| Pre-append prefix sha256 | `6ac8ce66d2d2…` before, **identical** after → `APPEND-ONLY-PROVEN` |
| Lines noted `phase 04 D-32 ledger` | **35** |
| Fence `library-db/` files | 19 → **54** |

### Deletion — ledger-gated, file by file

Before any `rm`: the targets were **re-listed** and every live target was confirmed to have a ledger row (`every live target has a ledger row`, with an explicit refusal path had one appeared); then every ledger row was re-validated (fence file present, fence sha re-hashed and still matching, SQLite integrity `ok`).

Each delete then passed the S5 guard: `..` refused → path must be under one of two literal allow-listed roots → **explicit refusal if the path equals the survivor `library.db`** → `realpath -e` must equal the ledger path exactly → `rm` (no glob, no `-r`, no `-f`) → `test ! -e`. **`rm -rf` appears nowhere in this plan.**

```
files_deleted=36
RMDIR-OK /mnt/fast/appdata/arrs/sabnzbd/config/.config/beets
RMDIR-OK /mnt/fast/appdata/arrs/sabnzbd/config/.config (was empty)
```

The directories went by `rmdir`, so an unledgered leftover would have blocked removal rather than being swept away.

### Post-delete assertions

| Assertion | Result |
|---|---|
| `.config/beets` | **ABSENT** |
| `library.blb*` / `beets.log` under `scripts/` | **0** (`find` rc 0) |
| survivor `library.db-before-*.bak` | **none** |
| positive control `audio.bash` | **still visible** |
| **survivor `library.db`** | **`fbbdde0c416e72b9884e56c562fd88eaa4da447926e1cb6cc17c3e04aee7da1a` — unchanged, never deleted** |
| survivor dir contents | `Music/`, `beet.log`, `beets.sh`, `config.yaml`, `library.db`, `state.pickle` |
| Queue immediately before / after the deletions | **`Idle\|0\|false`** / **`Idle\|0\|false`** |

---

## Task 3: candidate green → promotion → routine green → driven controls

### (1) Both candidates green BEFORE any promotion edit

| Candidate | When (UTC) | Result |
|---|---|---|
| `CENSUS_CANDIDATE=1 bash scripts/check-music-freeze.sh` (LXC 100) | 2026-09-13T09:39:21Z | **RC 0 in 4 s**, `FAILURES total: 0`, zero `❌` |
| `VENDORED_DRIFT_CANDIDATE=1 bash scripts/quick-health-check.sh` (workstation) | 2026-09-13T09:39:43Z | **RC 0 in 20 s**, `✅ vendored files match (3)` |

Census counters at that run — every one at target:

```
  tagger definitions:          1   (target 1)
  beets databases:             1   (target 1 = SURVIVOR_DB)
  tagger databases:            0   (target 0 — wrtag.db*/soulbeet.db*)
  retired paths present:       0   (target 0)
  rw on Music, non-tagger:     0   (target 0, excluding the D-21 consumer exception)
  rw on Music, tagger-capable: 0   (target 0 — Phase 1 D-20, any container state)
  rw on Music, Jellyfin D-21:  1   (documented consumer exception, printed separately)
  tagger-capable containers:   2   (mounts a beets/wrtag/soulbeet config or DB; reported)
  FAILURES total:              0
```

`sabnzbd` is listed tagger-capable (`mode on Music: none`) alongside `lidarr` (`ro`) — the expected **2**, per 04-06 deviation 3's `RENAMER_PATTERN` clause.

**The census counter progression across the phase, with the classifier never narrowed:** 04-06 **26** → 04-07 **24** → 04-09 **36** → **04-11: 1**.

### (2) The promotion commit — `2572b71`

| Check | Required | Measured |
|---|---|---|
| `grep -cx 'TAGGER_CENSUS_PROMOTED=1'` | 1 | **1** (and `=0` → **0**) |
| `grep -cx 'VENDORED_DRIFT_PROMOTED=1'` | 1 | **1** (and `=0` → **0**) |
| `grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` | 6 | **6** |
| the full sixth-notice literal present | 1 | **1**, on a single line so the whole string is greppable |
| `bash -n` / `/bin/bash -n` (3.2.57) | clean | **clean** on both |
| files touched | 2 | **2** |

The notice states every new exit-1 condition in five groups: (A) each census assertion, (B) the census being blind, (C) a drifted vendored file, (D) the drift block being blind, (E) a non-default `DRIFT_APPDATA_ROOT`. It also states that `CENSUS_CANDIDATE` / `VENDORED_DRIFT_CANDIDATE` are now ignored and cannot disable either block.

**REMOTE_TIMEOUT (REVIEWS row 17): left at 120 s, and the line was provably not touched.** Both measured figures: **04-06's candidate 6 s** and **this plan's candidate 4 s**. Neither exceeds 60 s, so the plan's condition for raising it to 200 was not met; the reasoning is recorded in the notice.

Both candidate-gate messages were kept but rewritten as **fail-closed tells** rather than left stating something no longer true: each is now unreachable by construction, and if either ever prints it says a constant has been set back to 0 and nothing is being asserted. The drift one additionally sets `EXIT_CODE=1`, so a reverted constant cannot produce a silent green.

### (3) Routine runs, NO env — both green

| Check | Where | RC | Wall | Evidence |
|---|---|---|---|---|
| `bash scripts/check-music-freeze.sh` | LXC 100 | **0** | 12 s | 6b heading printed **unprompted** (count 1); all 8 census counters printed; **0** `❌`; fail-closed tell count **0** |
| `bash scripts/quick-health-check.sh` | workstation | **0** | **20 s** (budget 200 s) | drift block `✅ vendored files match (3)`; fold-in now shows the census counters; sole `❌` `Traefik dashboard: Not accessible` |

The only `⚠️` lines on the host run are the two permanent mode reports (`directory mode: 88`, `file mode: 2586` — D-12 scoped out). **The finding set equals the 04-01 ROUTINE BASELINE, plus the census counters the promotion was for — no new red.**

### (4) Post-promotion driven controls — each red *through the routine path*

| Control | Drives | Result |
|---|---|---|
| **p1** `RETIRED_DB_PATHS=/mnt/fast/scratch-04/11/exists`, **no** `CENSUS_CANDIDATE` | a census assertion is fatal in the routine path | **RC 1**, `❌ retired path PRESENT: /mnt/fast/scratch-04/11/exists`, `retired paths present: 1` |
| **p2** `CENSUS_CANDIDATE=0` | the env cannot disable 6b | **RC 0**, 6b heading count **1**, counters printed — the section ran anyway |
| **p3** `DRIFT_EXPECT_SURVIVOR_BEETS_CONFIG=0×64`, **no** `VENDORED_DRIFT_CANDIDATE` | a drifted vendored file is fatal in the routine path | **RC 1**, `❌ survivor-config.yaml DRIFTED — repo=a2f94cb6… host=a2f94cb6… expected-override=0000…` |
| **p4** `VENDORED_DRIFT_CANDIDATE=0` | the env cannot disable the drift block | **RC 0**, block ran and printed `✅ vendored files match (3)` |

**p3 is the strongest single line of evidence in this plan.** `repo` and `host` are *equal* on that failure line — which simultaneously proves the survivor file really is green on the honest run, and proves the override is additive-only: it can add a failure but can never manufacture a pass.

Scratch was then removed behind the S5 guard, file by file, `rmdir` for the directories, **no `rm -rf`**: `SCRATCH-ABSENT`, `SCRATCH-PARENT-ABSENT`, with `/mnt/fast/stacks` visible as the positive control. A final routine freeze run after cleanup: **RC 0**, `beets databases: 1`, `retired paths present: 0`, `FAILURES total: 0`, 0 `❌`.

### (5) C4-a live

```
/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml:plugins: embedart musicbrainz
/mnt/fast/appdata/arrs/beets/config/config.yaml:plugins: musicbrainz
```

Both contain `musicbrainz`. `config.yaml.old` **ABSENT**, with `config.yaml` **PRESENT** as the positive control (so the absence is a reading, not a failure to look).

---

## Deviations from Plan

### 1. [Rule 3 — Blocking, pre-flagged] The plan's MANIFEST path does not exist

- **Issue:** the plan's `<files>` list, its action step (2) and its `<verify>` all name `/mnt/fast/safety/music-pre-project/library-db/MANIFEST.txt`. Verified again here: **that file does not exist**. The real and only manifest is the fence-root `/mnt/fast/safety/music-pre-project/MANIFEST.txt` (888 lines at start, not 875 as 04-01 recorded — it has grown since).
- **Fix:** fence *copies* were written to `library-db/` (correct, that is the real directory) while MANIFEST lines were read and appended at the **parent** path. A second manifest under `library-db/` was not created — that would fork the record.
- **Status:** this is the **third** plan to hit it (04-01 deviation 1 recorded it and explicitly warned 04-11). Recorded again as an uncorrected plan defect rather than worked around silently.

### 2. [Defective assertion — recorded, NOT satisfied] Task 2's `<verify>` fails on a correct outcome

- The plan's `<verify>` runs `grep -c 'phase 04 D-32 ledger' /mnt/fast/safety/music-pre-project/library-db/MANIFEST.txt`. Against the correct outcome that exits **2** with `No such file or directory` — the same defect as deviation 1, in the acceptance check.
- **Resolution:** recorded as defective. **The file was not created to satisfy the grep.** The intent was evaluated against the real path: `grep -c 'phase 04 D-32 ledger' …/MANIFEST.txt` → **35**, matching the 35 `fresh-04-11` rows exactly.

### 3. [Operator ruling] Scope extended from 25 files to 36

- The plan text scopes Task 2 to sabnzbd's 25 files. The operator ruled verbatim *"Delete the 11, fenced"* for the survivor's 11 migration `.bak` (04-09 deviation 3).
- **Applied through identical discipline:** fenced by exact name, `integrity_check ok`, MANIFEST lines 895–915, then deleted individually through the same S5 guard. The census classifier was **not** taught to ignore `.bak` — the alternative the operator explicitly rejected, and the one that would have re-created DEF-03-01's blindness.
- **Arithmetic confirmed:** 36 − 25 − 11 = **1**. The counter reached its target without being adjusted.

### 4. [Plan silent, resolved conservatively] Fence-name collisions

- The plan says to append a UTC stamp "if that name already exists — never overwrite a fence file". Measured: **13 of the 35** fresh names collided with Phase 1 fence files (`arrs_sabnzbd_config_scripts_library.blb` and its 11 `.bak`, plus `arrs_sabnzbd_config_.config_beets_library.db`).
- **Resolution:** the never-overwrite rule was applied mechanically to every row rather than hardcoded per file, and `mv -n` was used as a second barrier. All 13 carry `.20260913T093821Z`. **No Phase 1 fence file was overwritten** (`library-db/` went 19 → 54, i.e. +35, with no replacements).

### 5. [Measured finding, not a failure] EROFS lines DID appear, and `:ro` was kept

- 04-09's prior was zero EROFS lines on the survivor. sabnzbd produced **two**, exactly as Pitfall 7 predicted for `scripts_init.bash`'s `chmod 777 -R /config/scripts`.
- **Not treated as a failure and no rollback performed**, because the D-09 rule is explicit and init exited 0 with the container healthy. `sabnzbd.yaml` was therefore never edited — the one file the plan authorised changing only on a measured `:ro` boot failure.
- **Recorded because it would be easy to misread:** an EROFS line in a log is not automatically a broken mount, and the classifier was built precisely so that reading could not be made by reflex.

### 6. [My own defective instrument] `grep -c` exits 1 when it counts zero

- My wrapper around the candidate census ended with `grep -c "❌"`. On a perfectly green run that counts **0** and `grep` therefore **exits 1**, so the ssh reported `SSH_RC=1` on a run whose script exited 0.
- **Resolution:** the script's own `CENSUS_RC=0` and `FAILURES total: 0` are the authority; the wrapper's status was my instrument, not the estate. This is the estate's documented `timeout N cmd | wc -l` hazard in another costume, and the same class as 04-10's three self-caught instruments.

### 7. [My own defective instrument] A double-quoted grep for `REMOTE_TIMEOUT`

- I checked the line with `grep -c 'REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-120}"'` written inside **double** quotes, so my own shell expanded `${REMOTE_TIMEOUT:-120}` to `120` before grep ever saw the pattern. It reported **0** — which reads as "the line is gone" on a line that was never touched.
- **Resolution:** re-measured with correct quoting: the line is present at line 284, and `git diff` confirms **no `REMOTE_TIMEOUT` line appears in this plan's diff at all**. Recorded because a "0" there would have looked like a real regression in a constant this plan was explicitly asked to decide about.

### 8. [Estate fact, corrects an orchestrator note] The `:ro` mounts did not exist until this recreate

- The orchestrator's notes and 04-10 describe both files as `:ro`. That was true **in the repo**; the *running* container was created 2026-08-31 and had **no `audio.bash` mount at all**, with `beets-config.yaml` at **`RW=true`**.
- **Consequence, recorded:** this boot proof is the first time either `:ro` bind has existed at runtime, which makes it load-bearing rather than confirmatory.

### 9. [Scope note] `.config` was removed too

- The plan names `rmdir …/.config/beets`. Its parent `…/config/.config` was left holding nothing at all, so it was removed by `rmdir` as well (which fails safely if non-empty) and the removal is recorded. Nothing else lived under it.

### 10. [Pre-existing, not mine] Host porcelain is non-empty by design

- `prometheus.yaml.bak` and `monitoring.app.yaml.disabled` remain untracked and untouched, before and after. Any assertion demanding an empty host porcelain remains defective (04-06 deviation 2).

---

**Total deviations:** 10 — 1 blocking plan-path defect, 1 defective plan assertion recorded, 1 operator-ruled scope extension, 1 conservative resolution of a plan silence, 1 measured finding, **2 defective instruments of my own**, 1 correction to an inherited fact, 1 scope note, 1 pre-existing condition. **None weakens an assertion. No control was made to pass by editing prose, deleting a file, or changing the estate; no evidence was fabricated; and no counter was adjusted to reach its target.**

## Threat Flags

None. No new network endpoint, auth path or trust boundary — this plan closed one (`:rw` → `:ro` at runtime). The register's six entries:

- **T-04-11-01 (SAB API key disclosure)** — read into a variable in-process, passed via `curl -K <(printf …)`; never on argv, never echoed, no `ps`/`pgrep -a` during the window; only `status`/`noofslots`/`paused` printed. Nothing key-shaped appears in this file.
- **T-04-11-02 (DoS via the recreate)** — idle-queue precondition checked before *and* after; resident-tag assertion plus `--pull never` (image id identical before/after); full boot proof; failure classified before any rollback; NETWORK could never have weakened `:ro`.
- **T-04-11-03 (failed downloads post-processed)** — the `SAB_PP_STATUS` guard was asserted byte-identical in 04-10 (`50eada85…`) and the in-container sha256 of `audio.bash` equals the repo blob after boot, so the file the container runs is the reviewed one.
- **T-04-11-04 (host deletes / repudiation)** — 36-row per-file ledger, fence copy + sha + MANIFEST line + integrity before every `rm`; re-list and re-validate immediately before deleting; file-by-file S5 deletes with an explicit survivor-DB refusal; `rmdir` so an unledgered file blocks; **no `rm -rf` anywhere**.
- **T-04-11-05 (`pip install -U beets` at boot)** — **accepted**, recorded again: `scripts_init.bash` still runs it on every boot, and it ran during this recreate. Nothing invokes beets after the strip; Phase 8 owns the hook's shape.
- **T-04-11-06 (promotion over a red check)** — both candidates green first, with UTC-stamped transcripts preceding the promotion commit; four post-promotion controls prove the routine path now fails on both blocks and that neither env var can disable either.

## Known Stubs

None.

## Issues Encountered

- No credential, `.env` value or release name was printed. Every compose invocation used `--quiet`. The one place release names existed (the stale `incomplete/` orphans) was summarised by date and count.
- The SAB history and queue were read but never mutated: nothing was triggered, cancelled or paused via the SABnzbd or Lidarr API.
- The operator's added Lidarr artist ("Benson Boone") was left alone — no search was run and nothing was queued by this plan.

## Next Phase Readiness

- **04-12** now has what D-12 needs: the stripped hook is live and running from a `:ro` mount, `library.blb` and `beets.log` are **gone**, so their re-appearance during the observation window is itself evidence. Carry three things: (1) re-assert `ReplaygainTagging="false"` for the window (04-10's inventory shows "lands untagged" depends on it alone); (2) the two residual `Audio.txt` lines and the baseline `Exit(1): chmod …` are **pre-declared**, not failures; (3) `audio.bash:272-275` is existence-guarded (`if [ -f … ]; then rm …`), so the now-absent `library.blb` cannot abort `beets()` under `set -e` — re-confirmed against the live file, and the reason Grok's H2 stays refuted.
- **04-13** can quote criterion 5 as **measured from an executed routine run**: tagger definitions 1, beets databases 1, tagger databases 0, retired paths 0, rw on Music 0 for every container in every state, Jellyfin printed separately as the D-21 exception, `FAILURES total: 0`. Expect `tagger-capable containers: 2` (lidarr + sabnzbd), not 1.
- **Both guards are now fatal in the routine path.** Any later plan that changes a vendored file must install it on the host in the same wave, or `quick-health-check.sh` goes red — which is now the intended behaviour, not a regression.
- **The fence has grown:** `library-db/` 19 → 54 files, MANIFEST 888 → 963 lines. Any future coverage query should match on **path and sha**, never sha alone (see the ledger's identical-sha rows).

## Self-Check: PASSED

- FOUND commit `2572b71`; it is on `origin/main` (`2572b71e22da506bebb473571b9334dee47144e6`) and on the host at `2572b71`. It touches exactly two files: `scripts/check-music-freeze.sh`, `scripts/quick-health-check.sh`.
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-11-SUMMARY.md`.
- Both constants verified `=1` with zero `=0` forms; `grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` = **6**; the full sixth-notice literal present exactly once; `bash -n` and `/bin/bash -n` (3.2.57) clean.
- Boot proof complete: init `exited 0`, status `running`, HTTP `200`, both mounts `RW=false`, in-container sha256 = repo for both files, image id unchanged.
- Ledger: 36 rows, 36 files deleted, 0 rows with a missing fence file, 35/35 SQLite `integrity ok`, MANIFEST append-only proven (prefix sha `6ac8ce66d2d2…` unchanged), 35 lines noted `phase 04 D-32 ledger`.
- Survivor `library.db` intact at `fbbdde0c…`; `.config/beets` absent; zero `library.blb*`/`beets.log` leftovers; `audio.bash` positive control visible throughout.
- Routine freeze RC **0** and routine quick-health-check RC **0** after promotion; controls p1 **1**, p2 **0**, p3 **1**, p4 **0**, each as specified.
- `/mnt/fast/scratch-04` and `/mnt/fast/scratch-04/11` absent; **no `rm -rf` was executed anywhere in this plan**.
- **`.planning/STATE.md` and `.planning/ROADMAP.md` were NOT modified by this plan, and no `gsd-sdk query state.*` or `roadmap.*` verb was called.** Measured against `9157de3` — the parent of this plan's commit: `git diff --name-only 9157de3 HEAD -- .planning/STATE.md .planning/ROADMAP.md` is empty. **Do not diff from `c41593c`:** the workstation carried the orchestrator's own wave-5 tracking commit, which does touch STATE.md, and that baseline reports a false violation (the 04-10 deviation 6 trap).
- No commit deleted any tracked file.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-13*
