---
phase: 07-pilot-12-albums-end-to-end
fixed_at: 2026-09-27T20:03:56Z
review_path: .planning/phases/07-pilot-12-albums-end-to-end/07-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 6
partial: 1
skipped: 1
status: partial
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-09-27T20:03:56Z
**Source review:** .planning/phases/07-pilot-12-albums-end-to-end/07-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (CR7-01, WR7-01 to WR7-07; IN7-* out of scope)
- Fixed: 6 (WR7-02, WR7-03, WR7-04, WR7-05, WR7-06, WR7-07)
- Partial, text only: 1 (CR7-01). The false claim is retracted, but the structural fix still needs an operator decision.
- Skipped: 1 (WR7-01, which needs an operator decision)

Everything was done in the repository only. Nothing was run against atlantis or LXC 100, and nothing is deployed.

## Operator decisions outstanding

1. **CR7-01: 03-asis (`autotag: bootleg`).** This is still an unattended importer into the rw library, with `import.write: yes`. The choice is to de-register `03-asis` in `flask-config.yaml`, or register it with `autotag: "off"`, for the rest of Phase 7. Either way the change has to be installed to appdata and beets-flask restarted. Until then, stage nothing into `_inbox/03-asis`.
2. **WR7-01: rw grant scope.** Should `/mnt/tank/media:/media:rw` be narrowed to `/mnt/tank/media:/media:ro` plus `/mnt/tank/media/Music:/media/Music:rw`? If so, `PHASE7_RW_TAGGER_SRC/_DST` in `check-music-freeze.sh` and D-23's `D03_MEDIA_SOURCE` expectation in `quick-health-check.sh` must move in the same commit. D-23 should also assert that the parent stays `RW=false`.
3. **WR7-05 follow-up.** A standing registration assertion should be implemented once decision 1 fixes the expected inbox set.

## Deploy consequences (the operator's job, not done here)

- `stacks/selfhosted/arrs/beets/config.yaml` (CR7-01) and `stacks/selfhosted/arrs/beets/flask-config.yaml` (WR7-05) are **vendored files**. The edits are comment-only, but once the host pulls, quick-health-check's vendored-file drift block will report `survivor-config.yaml DRIFTED` and `flask-config.yaml DRIFTED` until both files are installed to `/mnt/fast/appdata/arrs/beets/config/`. That red is the drift detector working correctly, not a regression. Installing a comment-only change does not change beets-flask's runtime behaviour.
- The script changes (`route-dj-album.sh`, `quick-health-check.sh`, `check-music-import.sh`, `check-music-consumers.sh`) reach LXC 100 via `git pull` in `/mnt/fast/stacks`.

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

## Partially Fixed

### CR7-01: `03-asis` (`autotag: bootleg`) is a second unattended importer into the rw library

**Files modified:** `stacks/selfhosted/arrs/beets/config.yaml`, `stacks/selfhosted/arrs/beets/flask.yaml`
**Commit:** 3cac248
**Applied fix (text only):** Added a dated CORRECTED paragraph under `import.write` in `config.yaml`, and a CORRECTED sub-bullet under the D-22 grant in `flask.yaml`. Both retract "no unattended importer reads this key / can reach this mount" and state what is actually true. 03-asis stays registered with `autotag: bootleg`, which imports as-is outside D-20, and the only thing bounding it today is that the directory is empty, which is not a control. They also record that closing it is an open operator decision and that nothing should be staged into 03-asis until then.
**Not done (operator decision):** the structural close, which is de-registering 03-asis or setting `autotag: "off"` in `flask-config.yaml`. That disables an importer and changes live beets-flask behaviour, which this run was told not to decide.
**Verification:** Both YAML files parse. Comment-only change.

## Skipped Issues

### WR7-01: the rw grant covers all of `/mnt/tank/media` (TV, Movies), but the D-16 fence covers only `tank/media/Music`

**File:** `stacks/selfhosted/arrs/beets/flask.yaml:184` (plus `scripts/check-music-freeze.sh` `PHASE7_RW_TAGGER_SRC/_DST`, `scripts/quick-health-check.sh` D-23 `D03_MEDIA_SOURCE`)
**Reason:** skipped because it needs an operator decision. Narrowing the grant changes the rw scope in a compose file and the running container's mounts, and it requires moving the D-23 and freeze-census expectations in the same commit. This run was told explicitly not to make that decision. See decision 2 above.
**Original issue:** beets-flask can write to `/mnt/tank/media/TV` and Movies on the parent `tank/media` dataset, which has no snapshot, and the freeze census and D-23 certify the wider grant as deliberate.

## Verification record

- `bash -n`: ok on `route-dj-album.sh`, `quick-health-check.sh`, `check-music-import.sh`, `check-music-consumers.sh`.
- `bash scripts/check-music-import.sh --self-test`: exit 0, "all 13 cases behaved as expected (9 of them red by design)", uncounted dumper check green.
- `bash scripts/diff-music-tags.sh --self-test`: exit 0, "all 5 cases behaved as expected (4 of them red by design)". The file was not modified.
- D-04 scan emulation over the final tree: executable 15 = asserted 3 + exempt 12 (`D04_EXEMPT_BASELINE=12` holds).
- No self-test failed, so nothing was reverted.

---

_Fixed: 2026-09-27T20:03:56Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
