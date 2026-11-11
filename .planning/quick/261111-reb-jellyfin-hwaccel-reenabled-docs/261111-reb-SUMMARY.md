---
phase: quick-261111-reb
plan: 01
status: complete
subsystem: docs/media
tags: [jellyfin, vaapi, amdgpu, D-30, zfs, atlantis, docs]
requirements: [QUICK-261111-reb]
key-files:
  modified:
    - CLAUDE.md
    - README.md
    - MEDIA.md
    - DEPLOYMENT.md
    - stacks/selfhosted/media/jellyfin.yaml
    - stacks/selfhosted/monitoring/README.md
    - scripts/deploy-stacks.sh
    - scripts/disable-jellyfin-hwaccel.sh
decisions:
  - "Jellyfin VAAPI is documented as ON since 2026-11-11. Toggle it through the encoding API only, changing two fields. Never run `disable-jellyfin-hwaccel.sh enable`. `disable` stays the off-switch."
  - "Host-only atlantis tuning (6 GiB ARC ceiling, zfs-scrub-window cron) is recorded in DEPLOYMENT.md § 3 as not in Terraform."
metrics:
  completed: 2026-11-11
  tasks: 3
  files: 8
  commit: 8f0324b3
---

# Quick 261111-reb: Jellyfin VAAPI re-enabled — docs aligned Summary

The repo now records that Jellyfin VAAPI has been on since 2026-11-11. The kernel `7.0.14-28-pve` carries the amdgpu fix #7905 (upstream 631849ff, CVE-2026-68101). Every in-scope doc and comment now has three things: the API-only toggle rule, the warning never to run `enable`, and the dmesg and tainted recurrence check. DEPLOYMENT.md records the two host-only atlantis changes.

## Tasks

| # | Task | Commit |
|---|------|--------|
| 1 | Rewrite CLAUDE.md, README.md and MEDIA.md § 4 to the re-enabled state | 8f0324b3 |
| 2 | Comment-only updates to jellyfin.yaml, deploy-stacks.sh, the monitoring README and the disable-script header | 8f0324b3 |
| 3 | DEPLOYMENT.md host-only atlantis note, scope check, commit and push | 8f0324b3 |

The plan asked for a single commit, so all three tasks are in one commit. It is pushed to origin/main as `63e456b2..8f0324b3`. The push was not rejected, so no rebase was needed.

## Verification

- No in-scope file still says "OFF deliberately", "Do not re-enable", "stays OFF", "OUT OF SCOPE" or "HardwareAccelerationType: none" as the current state.
- `bash -n` passes on `scripts/deploy-stacks.sh` and `scripts/disable-jellyfin-hwaccel.sh`.
- The non-comment lines of jellyfin.yaml are byte-identical to the baseline taken before editing. `/dev/dri`, `group_add` and `mem_limit: 3g` are unchanged.
- The disable-script diff touches comments only.
- The commit contains only the 8 in-scope files. 07-UAT.md, `.planning/trips/` and `projects/` were not staged.

## Deviations from Plan

**1. [Rule 1 - Stale doc] MEDIA.md § 4 "How to tell which path a session took"**
- **Issue:** The evidence table gave `libx264` as the re-encode signature, and the PGS note said burn-in "converts a remux into a `libx264` encode". With VAAPI on, the re-encode shows as `h264_vaapi`.
- **Fix:** The table row now reads "`h264_vaapi` (or `libx264` with hwaccel off), no `-readrate 10`". The PGS note now says "converts a remux into a re-encode".
- **Commit:** 8f0324b3

**2. Verify-command portability (no code impact).** Two of the plan's chained verify one-liners fail on macOS even when the work is correct:
- `wc -l | grep -qx 0` never matches, because BSD `wc` pads its output with spaces.
- `git log -1 --format=%B | tail -1` returns an empty line, because `%B` adds a trailing newline.

I re-checked each step on its own. All of them pass, and the trailer is the last non-empty line.

## Follow-up (out of scope, not edited)

- `scripts/check-jellyfin-transcode.sh` still labels `HardwareAccelerationType` / `EnableHardwareEncoding` as "amdgpu mitigation, D-30 ... drift here is the expensive regression". The check only reports the two values and does not assert them, so it stays green. The wording is stale, though, and changing it is a separate decision. `scripts/quick-health-check.sh` was not touched either.

## Known Stubs

None.

## Self-Check: PASSED

- All 8 modified files are in commit 8f0324b3, which is on origin/main (`git status -sb` shows no ahead count).
- DEPLOYMENT.md contains `zfs-scrub-window` and `6442450944`.
