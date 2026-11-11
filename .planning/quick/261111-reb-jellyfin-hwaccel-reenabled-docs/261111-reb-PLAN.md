---
phase: quick-261111-reb
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - CLAUDE.md
  - README.md
  - MEDIA.md
  - DEPLOYMENT.md
  - stacks/selfhosted/media/jellyfin.yaml
  - stacks/selfhosted/monitoring/README.md
  - scripts/deploy-stacks.sh
  - scripts/disable-jellyfin-hwaccel.sh
autonomous: true
requirements: [QUICK-261111-reb]

must_haves:
  truths:
    - "No in-scope doc or comment still says Jellyfin hardware transcoding is OFF or must not be re-enabled"
    - "Every place that describes the new state says VAAPI was re-enabled 2026-11-11 after kernel 7.0.14-28-pve shipped the amdgpu fix (#7905, upstream 631849ff, CVE-2026-68101)"
    - "The docs warn that `disable-jellyfin-hwaccel.sh enable` must not be used, and say why; `disable` is still the emergency off-switch"
    - "The docs say where to look if amdgpu oopses come back: dmesg for amdgpu_hmm_invalidate_gfx, /proc/sys/kernel/tainted (4097 baseline, +128 = oops), then run `disable`"
    - "DEPLOYMENT.md records the two host-only atlantis changes (ARC ceiling 6 GiB, scrub pause/resume window), marked as not in Terraform"
    - "No functional YAML or script behaviour changed; both edited scripts pass `bash -n`"
  artifacts:
    - path: "CLAUDE.md"
      provides: "Infrastructure Warnings bullet rewritten to the re-enabled state"
      contains: "2026-11-11"
    - path: "MEDIA.md"
      provides: "§ 4 Transcoding describes VAAPI on, the incident as history, the enable caveat"
      contains: "vaapi"
    - path: "DEPLOYMENT.md"
      provides: "Dated host-only atlantis changes note"
      contains: "zfs-scrub-window"
    - path: "scripts/disable-jellyfin-hwaccel.sh"
      provides: "Dated header note; behaviour unchanged"
      contains: "2026-11-11"
  key_links:
    - from: "CLAUDE.md / README.md / MEDIA.md"
      to: "scripts/disable-jellyfin-hwaccel.sh"
      via: "do-not-use-enable caveat, disable as off-switch"
      pattern: "disable-jellyfin-hwaccel"
---

<objective>
Bring the repo's docs and comments in line with the live state: Jellyfin VAAPI transcoding was
RE-ENABLED on 2026-11-11 because atlantis now runs a kernel carrying the amdgpu null-ptr-deref fix
that caused the 2026-08-31 (~6 h) outage behind D-30. Also record the two host-only atlantis changes
made the same day (ZFS ARC ceiling, scrub pause/resume window).

Purpose: the repo currently instructs every agent "do not re-enable it" — that is now false and
would cause someone to revert a deliberate, tested change. And the host-only changes would be
invisible to anyone reading the repo.

Output: edited docs/comments in 8 files, one commit pushed to origin main. Docs and comments ONLY —
no host commands, no functional config, no behaviour changes.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@./CLAUDE.md
@./CONVENTIONS.md  (rule 12: durable rationale stays in-band, round-by-round history does not)

## Facts verified live 2026-11-11 (DATA — use as given, do not re-derive, do not run host commands)

- atlantis (172.16.1.158) runs kernel **7.0.14-28-pve** (PVE 9.2.26). Its changelog carries
  "fix #7905: cherry-pick fix for null-ptr deref in amdgpu" = upstream **631849ff**
  ("drm/amdgpu: fix check in amdgpu_hmm_invalidate_gfx", **CVE-2026-68101**) — the bug behind the
  2026-08-31 outage.
- Jellyfin `encoding.xml`: `HardwareAccelerationType=vaapi`, `EnableHardwareEncoding=true`, changed
  via the encoding REST API (GET then POST `/System/Configuration/encoding`, only those two fields
  changed). Guards untouched: `EnableThrottling` true, `EnableSegmentDeletion` true,
  `SegmentKeepSeconds` 300, `EncoderPreset` auto. Backup:
  `/mnt/fast/appdata/media/jellyfin/config/encoding.xml.pre-hwaccel-enable-20261111` (named outside
  the script's `*.bak.*` glob on purpose).
- Test: Jellyfin-driven h264 transcode with PGS subtitles burned in (the 08-31 trigger class) ran
  `-hwaccel vaapi` / `hwupload_vaapi` / `scale_vaapi` / `h264_vaapi` at 9–13x; 0
  `amdgpu_hmm_invalidate_gfx` oopses, taint unchanged at 4097, no orphaned ffmpeg, GPU DRM client
  table empty afterwards. Jellyfin 12.2 built an all-VAAPI overlay (no vulkan/libplacebo, unlike the
  08-31 pipeline).
- CAVEAT: `scripts/disable-jellyfin-hwaccel.sh enable` must NOT be used. It restores the whole
  newest `encoding.xml.bak.*`, which is the 2026-08-31 pre-Jellyfin-12 file containing
  `<EncoderPreset xsi:nil="true"/>`; Jellyfin 12 cannot deserialise that, so the whole file fails to
  load and the transcode guards reset to defaults. Re-enable/disable via the API changing only the
  two fields. `disable` remains valid as the emergency off-switch.
- If oopses recur: on atlantis `dmesg | grep amdgpu_hmm_invalidate_gfx` and
  `/proc/sys/kernel/tainted` (4097 = clean ZFS baseline; +128 = oops), run `disable`, see incident
  history (MEDIA.md § 4 / script header).
- Host-only on atlantis, NOT in Terraform, not in repo:
  (a) `/etc/modprobe.d/zfs.conf` `zfs_arc_max` 3113222144 → **6442450944 (6 GiB)**. Not higher:
  the host routinely has only 2–6 GB available (LXC 100 cap 24 GB + mpe 8 GB on a 28 GB host); a
  bigger ARC recreates memory exhaustion. Real fix = fill the empty second DIMM slot (CT32G56C46S5,
  32 GB DDR5-5600 SODIMM). Backup `/root/zfs.conf.bak-20261111`.
  (b) `/usr/local/sbin/zfs-scrub-window` (`pause|resume`, all pools, logs via
  `logger -t zfs-scrub-window`) + `/etc/cron.d/zfs-scrub-window`: pause any in-progress scrub at
  17:00, resume any paused scrub at 01:00. Stock Debian zfsutils-linux cron still STARTS the monthly
  scrub (2nd Sunday 00:24); a full tank scrub takes ~35 h and stalled Jellyfin DirectPlay for hours
  on 2026-11-08 (393 MB/s of scrub reads on the spinning pool). A paused scrub survives reboot.

## Locations found at planning time (line numbers go stale — re-grep before editing)

- CLAUDE.md:9 (MEDIA.md description: "the D-30 amdgpu constraint"), CLAUDE.md:33-35 (warning bullet)
- README.md:329-345 (§ GPU Hardware Acceleration: Services bullet + "Do not re-enable" callout)
- MEDIA.md:209-231 (§ 4 "Hardware acceleration is OFF, deliberately" through the Ollama paragraph)
- stacks/selfhosted/media/jellyfin.yaml: comments at ~18, ~21, ~47, ~59-72, ~77, ~123-132, ~239-244
- scripts/deploy-stacks.sh:114 data-table string; stacks/selfhosted/monitoring/README.md:486 same note
- scripts/disable-jellyfin-hwaccel.sh header (usage block ~lines 12-24)
- DEPLOYMENT.md § 3 Storage conventions (line ~136) — the host-only note goes there as a new
  subsection

## Explicitly out of scope (do not touch)

- stacks/selfhosted/silo/compose.yaml; everything under .planning/ except this task's files.
- scripts/check-jellyfin-transcode.sh and scripts/quick-health-check.sh: the check only REPORTS the
  two values (verified: `info` at ~line 732), so it stays green; its "drift here is the expensive
  regression" wording is stale but changing it is a separate decision — mention it in the SUMMARY
  as a follow-up, do not edit.
- Any functional YAML: `/dev/dri` passthrough, `group_add`, `mem_limit` values stay byte-identical.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rewrite the top-level docs (CLAUDE.md, README.md, MEDIA.md) to the re-enabled state</name>
  <files>CLAUDE.md, README.md, MEDIA.md</files>
  <action>
Re-grep each file for `D-30|HardwareAccelerationType|re-enable|DISABLED|OFF deliberately` first.

CLAUDE.md — replace the "Jellyfin hardware transcoding is OFF deliberately" bullet (~line 33) with a
bullet of similar length (3-4 lines) stating: Jellyfin VAAPI transcoding is ON again since 2026-11-11
(kernel 7.0.14-28-pve carries the amdgpu fix for the D-30 / 2026-08-31 outage); do NOT use
`scripts/disable-jellyfin-hwaccel.sh enable` (restores a pre-Jellyfin-12 encoding.xml that fails to
load) — toggle via the encoding API, two fields only; `disable` is still the off-switch; if oopses
recur check `dmesg | grep amdgpu_hmm_invalidate_gfx` and tainted (4097 baseline, +128 = oops) on
atlantis, then `disable`; see MEDIA.md § Transcoding. On line ~9, change "the D-30 amdgpu
constraint" minimally to e.g. "the D-30 amdgpu history" so it does not imply a live constraint.

README.md (§ GPU Hardware Acceleration ~329-345) — change the Services bullet to "hardware
transcoding (VAAPI) — active since 2026-11-11". Replace the "Do not re-enable" callout with a short
callout: re-enabled 2026-11-11 after the kernel fix (name kernel, #7905, 631849ff,
CVE-2026-68101); one sentence that it was proven on the 08-31 trigger class (PGS burn-in, all-VAAPI
pipeline, 0 oopses, taint unchanged); the do-not-use-`enable` caveat with its reason; the
oops-recurrence pointer. Keep the blast-radius sentence (dockerd/smaps → Traefik dies; PSI full
~96% with idle CPU) because it is durable diagnosis, but frame it as "if it recurs". Drop the
"Proxmox kernel 7.0.14-8 does not carry a fix" and "high CPU is correct behaviour" claims — both now
false.

MEDIA.md § 4 (~209-231) — retitle to "Hardware acceleration is ON (VAAPI) since 2026-11-11"; code
block shows `HardwareAccelerationType : vaapi` / `EnableHardwareEncoding : true`. State the kernel fix
and the test result in 2-3 sentences, the backup filename, the API-only toggle rule and the
do-not-use-`enable` caveat. Keep the failure-mode paragraph as a dated "History: D-30 (2026-08-31 →
2026-11-11)" paragraph with the diagnosis signals (they are what you need if it recurs) plus the
dmesg/tainted check; rewrite "Failure mode if re-enabled" and "does not carry a fix" accordingly.
Keep the Ollama/orphaned-ffmpeg sentence as durable rationale (it explains why `disable` is at
Jellyfin). Do not touch the Retention levers table. Per CONVENTIONS rule 12: durable rationale only,
no narrative of how the change was carried out beyond one dated sentence.
  </action>
  <verify>
    <automated>cd /Users/damian/Development/damianflynn/selfhost-stacks && ! grep -nE "OFF deliberately|Do not re-enable|Do not \"re-enable\"|hardware transcoding is DISABLED|HardwareAccelerationType *: *none|does \*\*not\*\* carry a fix|does not carry a fix" CLAUDE.md README.md MEDIA.md && grep -c "2026-11-11" CLAUDE.md README.md MEDIA.md && grep -n "disable-jellyfin-hwaccel" CLAUDE.md README.md MEDIA.md</automated>
  </verify>
  <done>All three files describe VAAPI as on since 2026-11-11, carry the do-not-use-`enable` caveat and the oops-recurrence check, and no longer assert hwaccel is off or must stay off.</done>
</task>

<task type="auto">
  <name>Task 2: Update comments/notes in jellyfin.yaml, deploy-stacks.sh, monitoring README, disable script header</name>
  <files>stacks/selfhosted/media/jellyfin.yaml, scripts/deploy-stacks.sh, stacks/selfhosted/monitoring/README.md, scripts/disable-jellyfin-hwaccel.sh</files>
  <action>
Before editing, capture a functional baseline: `grep -vE '^\s*#' stacks/selfhosted/media/jellyfin.yaml > $SCRATCH/jf-before.txt` (use the session scratchpad dir).

jellyfin.yaml — COMMENTS ONLY. Re-grep `D-30|HardwareAccelerationType|out of scope|re-enable|hardware transcode`. Rewrite every comment that says Jellyfin is not configured to use VAAPI, that HardwareAccelerationType is/must be none, that re-enabling is out of scope, or "Do not restore this comment to claim hardware transcoding is active" — to state VAAPI is active since 2026-11-11 (kernel fix), toggle via the encoding API two fields only, never `disable-jellyfin-hwaccel.sh enable`. Keep the durable warning at ~70 (partial POST silently flips EnableHardwareEncoding because the constructor default is true) — it is still true and still matters; reword its framing so it no longer implies the target is false. mem_limit comment at ~77: keep the value; update only the reasoning (3g headroom no longer rests on "hardware transcode is off"; with VAAPI the encode work moves to the GPU, so 3g remains generous — state that, nothing more). Do not alter any non-comment line.

scripts/deploy-stacks.sh:~114 — change the string to "jellyfin|major-upgrade procedure; HW transcode ON since 2026-11-11, toggle via API only (never disable-jellyfin-hwaccel.sh enable); Renovate manual-review". Keep quotes/pipe delimiter intact. stacks/selfhosted/monitoring/README.md:~486 — same text in the table cell (escape nothing; no `|` inside the cell other than the column separators — use a comma or semicolon instead of the inner pipe).

scripts/disable-jellyfin-hwaccel.sh — header only: insert a short dated block right after the Usage block (before "⚠️ `disable` and `enable` MUTATE live state"), titled `# STATUS 2026-11-11`, ~6 lines: kernel 7.0.14-28-pve carries the amdgpu fix (#7905 / 631849ff / CVE-2026-68101); VAAPI re-enabled via the encoding API (two fields only); DO NOT run `enable` — it restores the newest `encoding.xml.bak.*`, the pre-Jellyfin-12 file with `<EncoderPreset xsi:nil="true"/>` that Jellyfin 12 cannot load, resetting the transcode guards; `disable` remains the emergency off-switch; recurrence check = dmesg amdgpu_hmm_invalidate_gfx + tainted 4097/+128. Also append "(DO NOT USE since 2026-11-11 — see STATUS)" to the `enable` usage line. No code change.
  </action>
  <verify>
    <automated>cd /Users/damian/Development/damianflynn/selfhost-stacks && bash -n scripts/deploy-stacks.sh && bash -n scripts/disable-jellyfin-hwaccel.sh && grep -vE '^\s*#' stacks/selfhosted/media/jellyfin.yaml | diff - "$SCRATCH/jf-before.txt" && git diff -U0 scripts/disable-jellyfin-hwaccel.sh | grep -E '^[+-][^+-]' | grep -vE '^[+-]#' | wc -l | grep -qx 0 && ! grep -nE "stays OFF|OUT OF SCOPE|NOT configured to use it|hardware transcode is off|NOT \"VAAPI\"" stacks/selfhosted/media/jellyfin.yaml scripts/deploy-stacks.sh stacks/selfhosted/monitoring/README.md</automated>
  </verify>
  <done>Both scripts parse; jellyfin.yaml non-comment content byte-identical to baseline; the disable script diff is comment-only; no remaining "stays OFF / out of scope / hardware transcode is off" assertions in these files.</done>
</task>

<task type="auto">
  <name>Task 3: Record host-only atlantis changes in DEPLOYMENT.md, verify scope, commit and push</name>
  <files>DEPLOYMENT.md</files>
  <action>
Add a new subsection at the end of DEPLOYMENT.md § 3 Storage conventions (before the next `## 4.` heading; re-grep for its line), titled e.g. "### Host-only atlantis tuning (2026-11-11) — not in Terraform". Two bullets, concise, durable rationale only (rule 12):
(a) ZFS ARC ceiling: `/etc/modprobe.d/zfs.conf` `zfs_arc_max=6442450944` (6 GiB, was 3113222144); why not higher (2–6 GB routinely available: LXC 100 cap 24 GB + mpe 8 GB on a 28 GB host — a bigger ARC recreates the memory exhaustion); real fix = second DIMM slot, CT32G56C46S5 32 GB DDR5-5600 SODIMM; backup `/root/zfs.conf.bak-20261111`.
(b) Scrub window: `/usr/local/sbin/zfs-scrub-window` (`pause|resume`, all pools, `logger -t zfs-scrub-window`) driven by `/etc/cron.d/zfs-scrub-window` — pause in-progress scrubs at 17:00, resume paused ones at 01:00. The stock zfsutils-linux cron still starts the monthly scrub (2nd Sunday 00:24); a full tank scrub is ~35 h and on 2026-11-08 stalled Jellyfin DirectPlay for hours (393 MB/s scrub reads on spinning disks). A paused scrub survives reboot. Note: a rebuilt atlantis loses both; re-create by hand.

Then verify scope and commit:
- `git status --porcelain` / `git diff --stat` must list only the 8 files in files_modified plus this quick task's own .planning/quick/261111-reb-* files. The pre-existing unrelated changes (`.planning/phases/07-.../07-UAT.md`, `.planning/trips/`, `projects/`) must NOT be staged — stage by explicit path only, never `git add -A`.
- Final grep across all in-scope files: `grep -nE "OFF deliberately|Do not re-enable|stays OFF|OUT OF SCOPE for this phase" CLAUDE.md README.md MEDIA.md stacks/selfhosted/media/jellyfin.yaml scripts/deploy-stacks.sh stacks/selfhosted/monitoring/README.md` returns nothing.
- Commit with plain `git commit` (not gsd-sdk commit, which mangles messages): subject `docs(jellyfin): record VAAPI re-enable after amdgpu kernel fix; note host-only atlantis tuning`, short body, final line exactly `Claude-Session: https://claude.ai/code/session_01U6L4aqFUkCSrsCfTUHx8AQ`.
- `git push origin main`. If the push is rejected, `git pull --rebase origin main` then push again; do not force-push. Confirm `git status -sb` shows no ahead count. No host-side pull/deploy is needed (docs/comments only).
  </action>
  <verify>
    <automated>cd /Users/damian/Development/damianflynn/selfhost-stacks && grep -n "zfs-scrub-window" DEPLOYMENT.md && grep -n "6442450944" DEPLOYMENT.md && git show --stat HEAD | grep -E "CLAUDE.md|README.md|MEDIA.md|DEPLOYMENT.md|jellyfin.yaml|deploy-stacks.sh|disable-jellyfin-hwaccel.sh" && ! git show --stat HEAD --name-only --format= | grep -E "07-UAT|trips/|^projects/|silo/" && git log -1 --format=%B | tail -1 | grep -qx "Claude-Session: https://claude.ai/code/session_01U6L4aqFUkCSrsCfTUHx8AQ" && git status -sb | head -1 | grep -v ahead</automated>
  </verify>
  <done>DEPLOYMENT.md carries the dated host-only note with paths, values and why; one commit touching only in-scope files is on origin/main with the Claude-Session trailer.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| repo → public GitHub | repo is public; docs must not leak secrets |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-261111-01 | Information disclosure | DEPLOYMENT.md / MEDIA.md | mitigate | Record only paths, values, IPs already public in NETWORK.md; no tokens, API keys or passwords (the API toggle is described, not its key) |
| T-261111-02 | Tampering | jellyfin.yaml, deploy-stacks.sh, disable-jellyfin-hwaccel.sh | mitigate | Non-comment baseline diff on jellyfin.yaml, comment-only diff check on the disable script, `bash -n` on both scripts |
| T-261111-03 | Denial of service | stale guidance | mitigate | Every doc says "never run `enable`" so nobody reloads the pre-12 encoding.xml that resets transcode guards |
</threat_model>

<verification>
- No in-scope file asserts hwaccel is OFF / "do not re-enable" (Task 1 + Task 3 greps).
- `bash -n` passes on scripts/deploy-stacks.sh and scripts/disable-jellyfin-hwaccel.sh.
- jellyfin.yaml non-comment content unchanged; disable script diff comment-only.
- Commit touches only the 8 listed files (+ this quick task's planning files); pushed to origin main.
</verification>

<success_criteria>
The repo tells a reader the truth: VAAPI is on since 2026-11-11 because the kernel fix landed, how
to toggle it safely (API, two fields; never `enable`), what to check if oopses recur, and what
host-only tuning atlantis now carries outside Terraform.
</success_criteria>

<output>
Create `.planning/quick/261111-reb-jellyfin-hwaccel-reenabled-docs/261111-reb-SUMMARY.md` when done.
Include the follow-up: scripts/check-jellyfin-transcode.sh still labels the two values "amdgpu
mitigation, D-30 ... drift here is the expensive regression" (REPORTED, not asserted, so it stays
green) — wording is stale; changing it is a separate decision.
</output>
