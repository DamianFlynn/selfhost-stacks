---
phase: 07-pilot-12-albums-end-to-end
fixed_at: 2026-09-27T21:26:13Z
review_path: .planning/phases/07-pilot-12-albums-end-to-end/07-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
partial: 0
skipped: 0
status: all_fixed
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-09-27T21:26:13Z (first pass 2026-09-27T20:03:56Z; operator-decision pass 2026-09-27T21:26:13Z)
**Source review:** .planning/phases/07-pilot-12-albums-end-to-end/07-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (CR7-01, WR7-01 to WR7-07; IN7-* out of scope)
- Fixed: 8. WR7-02 to WR7-07 in the first pass. CR7-01 and WR7-01 in the second pass, after the operator's decisions. WR7-05's standing assertion (the follow-up) also landed in the second pass.
- Partial: 0
- Skipped: 0

Everything was done in the repository only. Nothing was run against atlantis or LXC 100, and nothing is deployed.

## Operator decisions (2026-09-27, operator)

1. **CR7-01:** set `03-asis` to `autotag: "off"` for the rest of Phase 7. It stays registered, so it is listed but runs no automatic action, and an as-is import happens only when a human starts it in the UI. Re-enabling `bootleg` is a Phase 8 inflow decision.
2. **WR7-01:** narrow the beets-flask grant to `/mnt/tank/media:/media:ro` plus `/mnt/tank/media/Music:/media/Music:rw`. Every consumer of the old shape moves in the same commit.
3. **WR7-05 follow-up:** add a standing inbox-registration assertion. The expected set is exactly {02-review, 03-asis}, read from the most recent registration line after the container's StartedAt.

## Deploy steps (the operator's job, not done here)

Run these in order. Until each one is done, the red it names is the detector working correctly, not a regression.

1. On LXC 100: `cd /mnt/fast/stacks && git pull`. This brings the scripts and compose files. From this point, quick-health-check shows two expected reds until steps 2 and 3 are done:
   - The vendored-file drift block reports `survivor-config.yaml DRIFTED` and `flask-config.yaml DRIFTED`.
   - D-23 reports condition V, `/mnt/tank/media -> /media at RW=true, expected RW=false`, and "0 mounts /mnt/tank/media/Music -> /media/Music".
2. Install the two vendored files to `/mnt/fast/appdata/arrs/beets/config/`, as 07-09 did:
   - `stacks/selfhosted/arrs/beets/config.yaml` -> `/mnt/fast/appdata/arrs/beets/config/config.yaml` (comment-only change)
   - `stacks/selfhosted/arrs/beets/flask-config.yaml` -> `/mnt/fast/appdata/arrs/beets/config/beets-flask/config.yaml` (**behaviour change:** 03-asis becomes `autotag: "off"`)

   Owner and mode should be `568:568` (07-09 used `install -m 660 -o 568 -g 568`).
3. Recreate beets-flask so the new mounts apply. A restart is not enough, because mounts are fixed at create time: `docker compose -f stacks/selfhosted/arrs/compose.yaml up -d --no-deps --force-recreate beets-flask`. **beets (the dormant CLI arm) is NOT changed.** `beets.yaml` already declares `/mnt/tank/media:/media:ro` and carries no rw grant, so it does not need recreating.
4. Wait for readiness, then run `bash scripts/quick-health-check.sh` from the workstation. Also run `bash scripts/check-beets-config.sh`, which is where the new registration assertion lives (§ 1b). It is **not** folded into quick-health-check, so a green quick-health-check does not cover it.
5. Things to verify live, because nothing here has observed them:
   - `docker inspect beets-flask` shows `/mnt/tank/media /media false` and `/mnt/tank/media/Music /media/Music true`. It must also show that a write under `/media/Music` actually lands. RW=true only reports what the daemon attached.
   - `/media/TV` is not writable from inside beets-flask.
   - The newest registration line still lists `03-asis` now that it is `autotag: "off"`. This has never been observed: every capture had 03-asis as `bootleg`. If rc6 does not list `off` inboxes, § 1b will go red with "fewer than two" and "02-review" alone. Settle that from the live line, and do not widen `REG_EXPECTED` to make it pass.
   - `docker logs --since <StartedAt>` accepts the nanosecond RFC3339 StartedAt on this Docker version.

## Fixed Issues

### WR7-02: route-dj-album's `timeout 120 docker exec` kills the docker client, not the beets write

**Files modified:** `scripts/route-dj-album.sh`
**Commit:** 352104f
**Applied fix:** Added `writer_timed_out()`. A 124 on writing step (c) `modify` or (e) `move` no longer goes to `fail … (exit 124)`. Instead the script says only the docker CLIENT was killed. It then lists the container's processes once with host-side `docker top beets-flask -eo pid,args`, bounded by `ROUTE_TOP_TIMEOUT=20`, so no tool is needed inside the image. It prints any live `<modify|move> -a … id:N` process and exits 3 UNVERIFIED, telling the operator not to roll back, re-run, undo or scan until no writer remains. A failed `docker top` is reported as UNKNOWN, and a clean look is not treated as proof. The header "Where it runs" and EXIT CODES sections are corrected. The in-container `timeout` alternative was not taken because it is unverified whether coreutils `timeout` exists in the image.
**Verification:** `bash -n` passed and `shellcheck` is clean. The branch was driven locally with stubbed `docker`/`timeout`: a live writer on step (e) exited 3 and listed the writer; the same on step (c) exited 3; no live writer exited 3 with the "not proof" wording; `id:55` did not match album 5; a failed `docker top` exited 3 with UNKNOWN. D-04 scan emulation over the tree gave executable 15 = asserted 3 + exempt 12, unchanged, so the `D04_EXEMPT_BASELINE=12` pin still holds. No new line carries `$BEET_REALLIB` or an invocation-shaped `beet`.
**Status:** fixed: requires human verification. `docker top`'s args format on LXC 100 has not been observed live.

### WR7-03: consumers exit-3 arm labels a D-24 census change as CONF-04

**Files modified:** `scripts/quick-health-check.sh`
**Commit:** 4b547ca
**Applied fix:** The arm now counts the audit's `CONF-04 IS NOT CLOSED` and `D-24 CENSUS CHANGED` banners and chooses its header by cause:
- both banners: "CONF-04 OPEN AND D-24 census CHANGED"
- D-24 only: "D-24 CENSUS CHANGED … CONF-04 rows not pending"
- CONF-04 only: the original header, kept byte-identical because `.planning/quick/260925-ae4-*` acceptance greps for it
- neither: "the CAUSE is not established"

It prints the D-24 block (`sed -n '/D-24 CENSUS CHANGED/,/NOT green/p'`, capped at `1,4p`) whenever that banner is present. The `SUMMARY` grep now also matches `D-24 census` and `D-28 aunique`. The CONF-04 explanation only prints when CONF-04 is actually open. The anchor guard and `EXIT_CODE=1` are unchanged, and no fatal site was added or removed.
**Verification:** `bash -n` passed. The extracted arm was driven with synthetic outputs for both / D-24-only / CONF-04-only / neither / no-summary, and every case gave the right header with EXIT_CODE=1.

### WR7-04: failure tail says RW=false on beets-flask "is expected until plan 07-09 deploys the grant"

**Files modified:** `scripts/quick-health-check.sh`
**Commit:** 027fc67
**Applied fix:** The tail now says RW=false on beets-flask is "a REGRESSION of the D-22 grant (a container recreated from an older compose file?) — it is NOT expected". As the finding's fix asked, the sweep line's "BY DESIGN until the first pilot import" framing is replaced with the durable rule: an empty library or a class with 0 checkable rows is exit 3, never green. The dated header notice T and the block comments were left alone (IN7-03 is out of scope).
**Verification:** `bash -n` passed.

### WR7-05: the "fewer than two / names 01-auto" registration gate is documented but not implemented

**Files modified:** `stacks/selfhosted/arrs/beets/flask-config.yaml`, `stacks/selfhosted/arrs/beets/flask.yaml`
**Commit:** 6ee2f2e
**Applied fix:** Took the review's "retract the claim" option. Both files now carry a dated RETRACTED paragraph stating that no script implements the gate. `check-beets-config.sh` `READY_LINE` only asserts that the line is present anywhere in `docker logs` history, so a pre-restart line satisfies it; it counts no inboxes and never looks for 01-auto. quick-health-check has no registration assertion. The inbox set is UNASSERTED. I did not implement the standing check because its expected set depends on the CR7-01 decision, and pinning it now would pin a set the operator is about to change.
**Verification:** Both files parse (`yaml.safe_load`). The credential screen on the added lines found no credential-class key, URL or e-mail. The only 20+ char run is the path `check-beets-config.sh`.
**Superseded 2026-09-27:** once the CR7-01 decision fixed the expected set, the gate was implemented (see "WR7-05 follow-up" below, commit 782b9dc), and the RETRACTED paragraphs were replaced by a pointer to it.

### WR7-06: `IMPORT_SWEEP_TIMEOUT` cannot be raised without going red, so the `REMOTE_TIMEOUT=300` remedy cannot work

**Files modified:** `scripts/check-music-import.sh`, `scripts/quick-health-check.sh`
**Commit:** 3c57d07
**Applied fix:** Took the review's second option. `IMPORT_SWEEP_TIMEOUT_DEFAULT` goes from 120 to 600, so it is a generous Linux-side backstop that still bounds a standalone run, and the caller's `REMOTE_TIMEOUT` becomes the knob. Any `REMOTE_TIMEOUT` below 600 now binds first, so the printed `REMOTE_TIMEOUT=300` remedy works. The additive-only override guard is unchanged: a non-default `IMPORT_SWEEP_TIMEOUT` still forces exit 1. The KNOBS header explains why, and the fold-in's 124 arm now says the inner bound is 600 s.
**Verification:** `bash -n` passed on both files. `check-music-import.sh --self-test` exited 0, with all 13 cases as expected (9 red by design) and the uncounted dumper check green.
**Status:** fixed: requires human verification. The trade-off is that a standalone run against a wedged dockerd now waits up to 10 minutes before reporting UNKNOWN.

### WR7-07: section 4d's truncation check runs only on zero hits

**Files modified:** `scripts/check-music-consumers.sh`
**Commit:** e8ae727
**Applied fix:** The at-limit test (`AU_RETURNED >= MA_LIBRARY_SCAN_LIMIT`) now runs before the per-row loop. A truncated list gives one `ma_fail` naming all rows UNKNOWN, so no row can pass as "exactly one mapping". The now-redundant at-limit sub-branch in the `AU_N -eq 0` arm was removed, and the loop body was re-indented under the new `else`.
**Verification:** `bash -n` passed. `shellcheck` findings are identical before and after (10 pre-existing). Section 4d was driven with a stubbed MA response: under the limit, both rows PASS; at the limit, a single UNKNOWN `ma_fail` and no PASS. `check-music-consumers.sh` has no `--self-test` mode.

### CR7-01: `03-asis` (`autotag: bootleg`) is a second unattended importer into the rw library

**Files modified:** `stacks/selfhosted/arrs/beets/flask-config.yaml`, `stacks/selfhosted/arrs/beets/config.yaml`, `stacks/selfhosted/arrs/beets/flask.yaml`
**Commits:** 3cac248 (first pass, text-only retraction), 13c5206 (operator decision)
**Applied fix:**
- In `flask-config.yaml`, `03-asis` goes from `autotag: bootleg` to `autotag: "off"`. The value is quoted because a bare `off` is a YAML 1.1 boolean. The inbox stays registered.
- The comment beside it gives the durable reason: bootleg was an unattended importer outside D-20, and "the directory is empty" is not a control. It also records the dated operator decision and that re-enabling bootleg is a Phase 8 inflow decision.
- The "OPEN OPERATOR DECISION / stage nothing into 03-asis" wording in `config.yaml` (`import.write` note) and `flask.yaml` (D-22 sub-bullet) is replaced by a dated RESOLVED note.
- `config.yaml` now names what bounds `write: yes`: no inbox imports unattended, D-20 confirmation applies, and the D-16 fence is in place.

**Verification:** All three files pass `yaml.safe_load`, and the parsed folder map is `{02-review: preview, 03-asis: 'off'}`. The credential screen over the added lines is clean.
**Status:** fixed: requires human verification. This is a runtime behaviour change once installed to appdata. Whether rc6 still lists an `off` inbox on the registration line has not been observed (see deploy step 5).

### WR7-01: the rw grant covers all of `/mnt/tank/media` (TV, Movies), but the D-16 fence covers only `tank/media/Music`

**Files modified:** `stacks/selfhosted/arrs/beets/flask.yaml`, `scripts/check-music-freeze.sh`, `scripts/quick-health-check.sh`, `scripts/phase06-oracle.sh`, `stacks/selfhosted/arrs/beets/config.yaml`, `stacks/selfhosted/arrs/beets/flask-config.yaml`, `stacks/selfhosted/arrs/beets.md`
**Commit:** 092a020
**Applied fix:**
- **`flask.yaml`:** the grant is now `/mnt/tank/media:/media:ro`, followed by `/mnt/tank/media/Music:/media/Music:rw`. The nested mount comes after its parent, and a short dated NARROWED note explains why.
- **`beets.yaml` is unchanged.** It already declares `/mnt/tank/media:/media:ro` and carries no rw grant.
- **`check-music-freeze.sh`:** `PHASE7_RW_TAGGER_SRC/_DST` move to `/mnt/tank/media/Music` and `/media/Music`. Sections 1, 2 and 6b all key on these constants. A beets-flask that still holds the parent rw no longer matches the exception, so it fails as a tagger-capable writer. The parser was emulated over the tree: the flask.yaml Music line maps to the exception, and the parent `:ro` line is skipped.
- **`quick-health-check.sh` D-23:** the runtime arm now asserts an exact shape. It needs exactly one `/mnt/tank/media -> /media` row at RW=false and exactly one `/mnt/tank/media/Music -> /media/Music` row at RW=true. Any other row whose source is under `/mnt/tank/media` or whose destination is under `/media` is a red, and that includes a row the space-split cannot parse. It adds new additive knobs (`D03_MEDIA_DEST`, `D03_MUSIC_SOURCE`, `D03_MUSIC_DEST`) to the override guard. It also adds a new EXIT-CODE notice for conditions V and W (letters measured free first) and updates the failure tail and the in-band block prose.
- **`phase06-oracle.sh` layer 1:** this was found by grepping every script for `.Mounts` and `RW=` parsing. The check looked only at the `/media` destination, so it would have read the new shape (parent ro, Music rw) as "/media is read-only", which is a silent pass. `assert_media_readonly` now treats any writable mount beneath the wanted destination as a red. There is a new self-test case, the base pin moves 140 -> 141, and the pin's arithmetic comment is updated.
- **Prose:** `config.yaml` (`directory` note and D-22 correction), `flask-config.yaml` (`readonly` note) and `beets.md` (operating-model bullet).
- **Consumers searched and left unchanged**, with whole-file greps over `scripts/*.sh` for `.Mounts`, `RW=true|RW=false`, `/mnt/tank/media:/media` and `"/media"`:
  - `check-beets-config.sh`, `check-music-import.sh`, `check-music-consumers.sh`, `route-dj-album.sh`, `diff-music-tags.sh` and `snapshot-music-tags.sh` use `/media/Music` only as a path and parse no mount shape.
  - `check-jellyfin-transcode.sh`, `pg-migrate.sh` and `setup-couchdb.sh` parse `.Mounts` for other containers.
  - The D-03 CLI arm still expects the dormant arm's parent `ro`, which is still true.

**Verification:**
- `bash -n` passes.
- The D-23 runtime arm was driven with 11 synthetic `docker inspect` outputs. The expected shape gave the tick with `D03_BAD=0`. Every other shape went red with `EXIT_CODE=1`: old shape, parent rw with Music rw, swapped flags, Music ro, no parent, an extra TV rw mount, a foreign source into `/media`, the parent at the wrong destination, an unparseable spaced row, and no media mounts at all.
- `phase06-oracle.sh --self-test` exits 0 with 141 cases.
- `shellcheck` findings are identical to the e50e24f baseline for all three scripts.
- The notice header count after the edit, from the thirteenth notice's header recipe, is **16** (15 before).
- Across the D-03 block, `EXIT_CODE=1` sites went from 2 to 5 in the runtime media arm. The failure-tail enumeration artifact (`06-26-qhc-knobs-and-tail.txt`) was not re-run.

**Status:** fixed: requires human verification. The mounts must be observed live after the recreate (deploy steps 3 to 5).

### WR7-05 follow-up: the standing inbox-registration assertion

**Files modified:** `scripts/check-beets-config.sh`, `stacks/selfhosted/arrs/beets/flask-config.yaml`, `stacks/selfhosted/arrs/beets/flask.yaml`
**Commit:** 782b9dc
**Applied fix:**
- **Line format:** it is taken from observed lines, not invented. The 07-09 artifact (`07-09-fence-and-grant.txt` § Step 3) and the 07-11 artifact (`07-11-p10-undo-rerun.txt` § RESTORE (3)) each captured the post-D-21 line, and the Phase 6 artifacts captured the three-inbox form. In rc6 it is a Python list repr of the inbox paths: `... for inboxes: ['/downloads/complete/nzb/_inbox/02-review', '/downloads/complete/nzb/_inbox/03-asis']`.
- **New pure function `assert_inbox_registration`:**
  - It takes the newest line carrying `READY_LINE` and `for inboxes: `.
  - It extracts the quoted items and re-joins them. If the re-joined list differs from the line, the result is UNKNOWN, so a format it only half understands never counts as a pass.
  - It returns RED when 01-auto is named, when fewer than two inboxes are listed, when any path falls outside `REG_EXPECTED`, or when the sorted list is not exactly `REG_EXPECTED` (for example a duplicate).
  - It returns UNKNOWN when there is no line or the list is unparseable.
  - `REG_EXPECTED` and `REG_FORBIDDEN_NAME` are plain constants, not overrides.
- **New live section § 1b:**
  - One ssh command reads `docker inspect -f '{{.State.StartedAt}}'` and then `docker logs --since "$StartedAt"`. Each docker call is bounded Linux-side with `timeout`, the command runs under `set -o pipefail`, it contains no pipe, and the ssh RC is read.
  - 124, 97 (empty StartedAt), any other non-zero, or a missing STARTED_AT header all give UNKNOWN.
  - A "no line yet" result is polled on the readiness gate's schedule before it becomes UNKNOWN.
  - The summary gains an `inbox registration (WR7-05)` line.
- **Prose:** the "UNASSERTED" retraction in `flask-config.yaml` and `flask.yaml` is replaced by a pointer to the check.

**Placement:** `check-beets-config.sh`, not quick-health-check. It already owns `READY_LINE` and has a pinned `--self-test`, and quick-health-check has no self-test harness. The cost is that the assertion is standing only when `check-beets-config.sh` is run: it is **not folded into quick-health-check**. Folding it in (a new fatal block, notice and tail entry) is left as a follow-up.

**Verification:**
- `bash -n` passes.
- `--self-test` exits 0 with 13 cases (was 7), 11 red. The six new cases are:
  - the expected set gives PASS
  - 01-auto present gives RED
  - one inbox gives RED
  - an unexpected name gives RED
  - no line gives UNKNOWN
  - an older good line followed by a newest line naming 01-auto gives RED
- The function was also driven directly:
  - The real 07-09 artifact line and a CRLF-terminated line both PASS.
  - `[]`, a duplicate, and three entries with a duplicate are all RED.
  - A double-quoted item and a line with no list are both UNKNOWN.
  - An old bad line followed by a newest good line PASSES.
  - A path in another directory is RED.
- § 1b was driven end to end with stubbed `ssh`, `timeout` and `docker`: good gives PASS, 01-auto gives RED, no line gives UNKNOWN after polling, 124 gives UNKNOWN, and an empty StartedAt gives UNKNOWN.
- The D-04 contract case still passes, and the invocation-pattern emulation count over the file is unchanged (3 -> 3).
- `shellcheck` shows one extra SC2029 note on the new ssh line. It is the same intentional client-side-expansion class as the three existing ssh notes in the file.

**Status:** fixed: requires human verification. The "off"-inbox listing and `--since` with a nanosecond timestamp are unobserved (deploy step 5).

## Verification record

First pass:
- `bash -n`: ok on `route-dj-album.sh`, `quick-health-check.sh`, `check-music-import.sh`, `check-music-consumers.sh`.
- `bash scripts/check-music-import.sh --self-test`: exit 0, "all 13 cases behaved as expected (9 of them red by design)", uncounted dumper check green.
- `bash scripts/diff-music-tags.sh --self-test`: exit 0, "all 5 cases behaved as expected (4 of them red by design)". The file was not modified.
- D-04 scan emulation over the final tree: executable 15 = asserted 3 + exempt 12 (`D04_EXEMPT_BASELINE=12` holds).
- No self-test failed, so nothing was reverted.

Second pass (operator decisions, 2026-09-27):
- `bash -n`: ok on `check-beets-config.sh`, `quick-health-check.sh`, `check-music-freeze.sh`, `phase06-oracle.sh`, `check-music-import.sh`, `diff-music-tags.sh`.
- `check-beets-config.sh --self-test`: exit 0, all 13 cases (11 red).
- `phase06-oracle.sh --self-test`: exit 0, 141 cases.
- `check-music-import.sh --self-test`: exit 0, all 13 cases (9 red).
- `diff-music-tags.sh --self-test`: exit 0, all 5 cases (4 red).
- `shellcheck` against the e50e24f baseline: `quick-health-check.sh` 35 -> 35, `check-music-freeze.sh` 2 -> 2 and `phase06-oracle.sh` 27 -> 27, all identical. `check-beets-config.sh` 3 -> 4, the one extra being an SC2029 note on the new ssh line, the same class as the existing three.
- The invocation-shaped `beet` count (D-04 pattern, comment-stripped) is unchanged in every touched script, so `D04_EXEMPT_BASELINE` is unaffected.
- Every vendored YAML parses, and the credential screen over the added lines is clean.
- No self-test failed, so nothing was reverted.

---

_Fixed: 2026-09-27T20:03:56Z (first pass); 2026-09-27T21:26:13Z (operator-decision pass)_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

## Deploy and live verification (2026-09-27, 21:32Z)

The operator authorised the deploy. `main` was pushed at `09d5f96` and the host pulled it with `--ff-only` from a clean checkout. `_inbox/03-asis` held 0 entries before the switch.

- **Install:** before installing, the appdata configs were backed up as `*.pre-07fix.20260927T213212Z` alongside the originals. Against the repo, `config.yaml` differed in comments only. `flask-config.yaml` differed in exactly one non-comment line, `autotag: bootleg` → `"off"`. After `install`, the modes came out wrong (0744); they were restored from the backups (`0760`, `568:568`).
- **Recreate:** `docker compose up -d --force-recreate --no-deps beets-flask`. The container started at `2026-09-27T21:32:21.821570896Z` with 0 restarts.
- **Mounts (live verification item 1): CLOSED.** `inspect` shows `/media rw=false` and `/media/Music rw=true`. A probe as root inside the container: a `touch` under `/media/Music` succeeded and was removed, while `/media/TV` and `/media` both returned `Read-only file system`.
- **Does an `"off"` inbox stay registered (item 2): CLOSED, yes.** The newest registration line after the recreate reads `inboxes: ['/downloads/complete/nzb/_inbox/02-review', '/downloads/complete/nzb/_inbox/03-asis']`.
- **Does `docker logs --since` accept the nanosecond StartedAt (item 3): CLOSED, yes** (Docker 29.2.1).
- **`check-beets-config.sh`:** exit 0, and § 1b is green on the live line.
- **`quick-health-check.sh`:** exit 1. The only red is the LXC 100 `/` headroom from `check-jellyfin-transcode.sh`: 16.22 GiB against the 20 GiB D-17 floor. That shortfall **predates this deploy**: Phase 7 already recorded 16.90 GiB. D-23, the freeze, the vendored-file drift check and the import sweep are all green.
- **Unrelated finding:** `scripts/quick-health-check.sh` is `100644` in git (it already was at `bcbfe0a`), so it has to be run as `bash scripts/quick-health-check.sh`.
- **Headroom remediated (2026-09-27, operator-run):** the operator ran `docker image prune -a -f` on LXC 100, which reclaimed 9.109 GB; the pre-prune image list with digests is at `/mnt/fast/appdata/_ops/image-prune-*.txt`. `/` headroom is now 25.46 GiB, above the 20 GiB floor. On the re-run, `quick-health-check.sh` still exits 1, and its only remaining non-green is the consumers audit's by-design CONF-04 ⚠️ (exit 3: 3 Jellyfin and 1 MA artist rows at baseline). The WR7-03 header correctly names CONF-04 alone.
