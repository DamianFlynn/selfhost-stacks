---
status: diagnosed
phase: 06-tagger-configuration-and-dry-run
source: 06-01-SUMMARY.md .. 06-52-SUMMARY.md (52 plans, 5 gap-closure rounds)
started: 2026-09-24T22:55:54Z
updated: 2026-09-24T23:12:28Z
executed_by: claude (operator delegated execution — "you dont need me to do that, you have the access")
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: beets-flask v2.0.0-rc6 restarts clean from a full `down`/`up -d`; log shows the vendored config loaded (BEETSDIR=/config), three inboxes registered, no traceback; `docker inspect` (not just `ps`) shows it running; no host port published.
result: pass
measured: |
  `docker compose -f flask.yaml down` removed the container entirely (`docker ps -a` empty),
  then `up -d` recreated it. After 25 s:
    State=running  Running=true  ExitCode=0  Image=metasauce/beets-flask:v2.0.0-rc6
    Ports={}                                   (no host port)
    BEETSDIR=/config, /config/config.yaml present
    Entrypoint: beetle 568:568, Backend 2.0.0-rc6, Frontend 2.0.0-rc6, Mode prod
    "Registering watchdog ... for inboxes: ['01-auto', '02-review', '03-asis']"
    "Web-Terminal is disabled, skipping setup"
    Traceback count in the whole boot log: 0
  library.db / state.pickle sha256 BYTE-IDENTICAL across the cold start
  (fbbdde0c…7da1a / f6a9a1ad…4bc7c) — the restart wrote nothing.
  The pre-restart dangling-state FileNotFoundError noise (documented plan-06-06 wart)
  cleared on recreation.

### 2. beets-flask reachable behind Authelia
expected: unauthenticated request 302s to Authelia; exactly one Traefik router on chain-authelia@file port 5001; no host port.
result: pass
measured: |
  beets.deercrest.info → 172.67.175.143 / 104.21.83.117 (Cloudflare proxy, genuinely public)
  GET https://beets.deercrest.info/ → HTTP 302
    → https://auth.deercrest.info/?rd=https%3A%2F%2Fbeets.deercrest.info%2F&rm=GET
  Exactly one router `beets`: rule Host(`beets.deercrest.info`), middlewares
  chain-authelia@file, service beets-svc, tls + dns-cloudflare, priority 99,
  loadbalancer.server.port 5001. NetworkSettings.Ports = {} .
  Re-confirmed 302 AFTER the test-1 cold start — the route came back by itself.

### 3. Inbox fires on a dropped folder
expected: a dropped folder is picked up by the watchdog; preview touches neither library.db nor state.pickle.
result: pass
deviation: |
  Tested through `02-review` (autotag: preview), NOT `01-auto` as this test was first
  written. `01-auto` is `autotag: auto` — it imports without asking, and beets.md's
  own "Still open at Phase 6 close" section carries WR-09/DEF-06-21-01: "`import.write:
  yes` is live, `/downloads` is `:rw`, and `01-auto` autotags — and NONE of the three
  controls the config names reaches that path. Read this before you drop a folder into
  an inbox." Plan 06-06 drove D-09 part 2 through 02-review for the same reason, so
  02-review is the faithful test, not a weakened one.
measured: |
  Dropped _UAT06-D09-20260924T230905Z (2 FLACs, chown 568:568) into 02-review.
  After the 30 s debounce the log read:
    "Watchdog: Starting inbox handler task /downloads/.../_inbox/02-review/_UAT06-D09-…"
    "Watchdog: Enqueuing /downloads/.../_inbox/02-review/_UAT06-D09-… as preview"
  The inbox FIRED, and as `preview` — not as an import. The folder stayed put in
  02-review; nothing was moved or written.
  library.db / state.pickle sha256 identical at all three sampling points
  (before drop, after enqueue, after preview settle): fbbdde0c… / f6a9a1ad… .
  Throwaway folder removed; 02-review is empty again.

### 4. check-beets-config.sh self-test
expected: exit 0, "all 7 cases behaved as expected (6 of them red)".
result: pass
measured: `bash scripts/check-beets-config.sh --self-test` → EXIT 0, "✅ --self-test: all 7 cases behaved as expected (6 of them red)". The instrument proves it can go red before it is trusted going green.

### 5. check-beets-config.sh against the live server config
expected: CONF-01/02/05 asserted green from the SERVER-COMMITTED config; exit 0.
result: pass
measured: |
  EXIT 0. FAILURES total: 0, arm-1 assertion failures: 0, toolchain missing: 0,
  arm 1 blind: 0, arm 2 blind: 0.
  CONFIG_ROUTE (arm 1): server-committed. D-30 two-arm comparison: 3 of 26 keys
  differ (library, gui.num_preview_workers, gui.terminal.start_path) — expected,
  and the point of D-30. Redaction no-op; no-op overlay size 0 bytes (WR-04).
  D-29 before == after on library.db and state.pickle.
  Closing line: "CONF-01 (copy not move), CONF-02 (incremental AND
  incremental_skip_later), CONF-05 (GB not UK, original_year,
  musicbrainz.extra_tags), the four rc6 schema-default landmines, the SAFE-01 three
  and the path stanza are all asserted TRUE of the SERVER-COMMITTED config."
  Also correctly REPORTED-not-asserted: `import.write = true` is Phase 7 behaviour.

### 6. phase06-oracle.sh self-test
expected: exit 0, 140 cases; no-args prints usage and exits 2.
result: pass
measured: `--self-test` → EXIT 0, "self-test: 140 case(s), every fail-closed branch behaved exactly as expected". No-args → EXIT 2 (refuses to drive anything live). Fence self-checks included the byte-identity assertion on the two stamp fence copies.

### 7. Incremental two-arm negative control
expected: self-test green; the two arms, one config key apart, produce OPPOSITE outcomes; real library untouched.
result: pass
measured: |
  --self-test → EXIT 0, "all branches behaved as expected (including every refusal
  and every blind case)".
  ARM A (incremental_skip_later: no)  → EXIT 0. taghistory POPULATED;
    --pretend re-run: "No files imported … Skipped 1 paths" → classified not-offered.
    "the trap FIRED (permanently marked done)".
  ARM B (incremental_skip_later: yes) → EXIT 0. taghistory EMPTY;
    --pretend re-run offered the album back → classified offered.
    "the trap is DEFEATED by incremental_skip_later".
  Opposite outcomes, one key apart — this is CONF-02 demonstrated, not merely set.
  Both arms: source manifest (path+size+mtime+sha256) IDENTICAL before and after;
  0 files under the rw downloads mount newer than the stamp; D-29 layer 3 after
  each arm identical to the 06-04 baseline. --cleanup asserted both trees GONE.

### 8. check-music-consumers.sh is honest about CONF-04
expected: exit 3, JF_AT_TARGET 0, JF_PENDING 3, FAILURES 0 — honest, not falsely green.
result: pass
note: |
  Run from the workstation it exits 1 with 13 failures, because the MA and Jellyfin
  credentials live at /mnt/fast/secrets/*.env — LXC 100 paths that do not exist on
  macOS. That is the script failing CLOSED (routes "unavailable", sections "UNKNOWN,
  not green"), which is convention 1 working, not a defect — and it is not the
  documented entry point: quick-health-check.sh invokes the copy at
  /mnt/fast/stacks/scripts/check-music-consumers.sh over ssh (line 926).
measured: |
  On LXC 100 (git 08e7ce3): EXIT 3.
    artist rows at target (JF): 0      artist rows PENDING (JF): 3
    artist rows at target (MA): 2      artist rows REPORTED (MA): 1
    albums matched in MA: 2   albums matched in Jellyfin: 2   MA local provider: 70
    D-34 options: PreferNonstandardArtistsTag=true, UseCustomTagDelimiters=false,
                  SaveLocalMetadata=false, EnableRealtimeMonitor=false
    toolchain missing: 0    FAILURES total: 0
  "CONF-04 IS NOT CLOSED … The two counts are SEPARATE and are NEVER summed …
   Exiting 3: measured, not at target; NOT a failure (FAILURES is 0) and NOT green."
  Exactly the state the verification report records. The instrument is honest.

### 9. quick-health-check.sh folds in the new checks
expected: runs end to end within REMOTE_TIMEOUT; consumers section names both E6 owners in the exit-3 arm.
result: issue
reported: "Runs and the CONF-04 prose is exactly right, but the run exits 1 on two reds that have nothing to do with CONF-04: the deployed beets config has drifted from the repo, and the music-freeze harness is red on a pinned-count trap that has been firing since 2026-09-18."
severity: major
measured: |
  EXIT 1. The consumers section is CORRECT and complete — it names both E6 owners,
  carries the "a carry is not a close" wording, and the by-design ⚠ is explained in
  the footer ("Do not tune it out").
  Green: Traefik, Authelia, 98 containers, 0 unhealthy, dashboard 302, D-03 one
  vendored config both containers, D-04 no asserted beet invocation opens the real
  library, extended.conf switches disarmed (requireBeetsMatch=false), library
  underscore-dir guard, Jellyfin transcode retention (FAILURES 0), image drift
  (11 drifted, REPORTED not asserted, 0 could-not-look).
  RED (two, both unrelated to CONF-04) — see Gaps 1 and 2.

### 10. The dry run wrote nothing to the real library
expected: library byte-unchanged; /media RW=false; library.db and state.pickle unchanged; no new sidecars.
result: pass
measured: |
  beets-flask /media mount: RW=false, src=/mnt/tank/media. (The `beets` CLI container
  has no /media mount at all — the CLI arm is dormant, consistent with D-03's
  "declared (dormant CLI arm, rendered)".)
  library.db fbbdde0c…7da1a / state.pickle f6a9a1ad…4bc7c — identical to the values
  check-beets-config.sh reported as its own D-29 before AND after, and unchanged
  again after the test-1 cold start and the test-3 preview.
  /mnt/tank/media/Music: .nfo count 91 (the known baseline — round 5 asserted 0 of 91
  differing; it has not grown), .lrc 944 (pre-existing).
  Files modified in the last 3 days: exactly 3 — the three CONF-04 rows
  (Just Give Me a Reason, Jewels n' Drugs, California Gurls). These are plan 06-41's
  deliberate mtime touches inside the snapshot fence, whose CONTENT sha256 round 5
  asserted unchanged. Nothing else in the library moved.

### 11. CONF-04's open state is recorded honestly, not papered over
expected: REQUIREMENTS.md CONF-04 unticked; ROADMAP Phase 6 not ticked; override recorded, not applied.
result: pass
measured: |
  .planning/REQUIREMENTS.md:152 — `- [ ] **CONF-04**`. Unticked count 1, ticked count 0.
  .planning/ROADMAP.md:54 — `- [ ] **Phase 6: Tagger Configuration and Dry Run**`.
  REQUIREMENTS.md:305 spells the carry out in full, including "That override is NOT a
  close. The checkbox stays unticked, `requirements mark-complete` was not run."
  ROADMAP 06-47 row states explicitly that the "In Progress" status "is CORRECT and
  must not be flipped". Nothing ticked anything as a side effect of the override.

### 12. The ZFS snapshot fence is still held, deliberately
expected: tank/media/Music@pre-06-41-conf04-reprobe still present.
result: pass
measured: |
  On atlantis, `zfs list -t snapshot tank/media/Music`:
    tank/media/Music@pre-06-41-conf04-reprobe   0B   Thu Sep 24 09:05 2026
  Present and held, alongside @pre-project, @safe05-watch-t0, @pre-chown,
  @pre-phase5-chown, @backup-20260922, @inc-20260923-1319.
  0B used — the fence costs nothing to keep, which is consistent with DEF-06-52-01's
  hold decision.

### 13. beets.md documents the Phase 6 close truthfully
expected: an accurate account; nothing claimed that the measurements do not support.
result: pass
measured: |
  The head pointer (R6-05, plan 06-47) is accurate and self-aware: it names the
  authoritative section by HEADING TEXT not line number, warns that the file is an
  append-only running log, disambiguates the twice-occurring "### The five criteria"
  by parent, and states the disposition as "CLOSED WITH ONE OPEN REQUIREMENT:
  CONF-04, on its Jellyfin half only", names the negative-carry-e6 override, says the
  checkbox is "deliberately still unticked", and states the two verdicts are never
  summed. Line 1843 carries the round-5 update in the same terms.
  Every claim I could check against live state held. The WR-09 warning about
  `01-auto` is prominent enough that it changed how I ran test 3 — the documentation
  did its job.
minor_observation: |
  The "Still open at Phase 6 close" subsection (the 06-14 closure text) still ends
  "It discharges on Phase 7's first write or import of a multi-artist release" — the
  exact sentence ROADMAP.md names as SUPERSEDED by round 5. The head pointer and
  line 1843 both correct it, and the file's stated convention is that later text
  supersedes earlier, so this is consistent with the document's own rules rather than
  a false claim. Noted, not raised as a gap.

## Summary

total: 13
passed: 12
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "quick-health-check.sh — the estate's single health entry point — exits 0 when nothing is wrong, with CONF-04's exit-3 warning as the only expected non-green"
  status: failed
  reason: "User reported: Runs and the CONF-04 prose is exactly right, but the run exits 1 on two reds that have nothing to do with CONF-04: the deployed beets config has drifted from the repo, and the music-freeze harness is red on a pinned-count trap that has been firing since 2026-09-18."
  severity: major
  test: 9
  sub_gaps: [gap-1-config-drift, gap-2-pinned-count]

- id: gap-1-config-drift
  truth: "The vendored beets config that actually imports is the one in the repo"
  status: failed
  reason: "Vendored-file drift block: survivor-config.yaml DRIFTED — repo=661c7297…4668f host=96a7c622…e3e1f7"
  severity: minor
  test: 9
  root_cause: >-
    The DEPLOYED copy at /mnt/fast/appdata/arrs/beets/config/config.yaml is stale.
    Its mtime is 2026-09-20 23:36; the repo copy was edited 2026-09-21 08:20 by plan
    06-07, which replaced the max_filename_length comment block with its own
    retraction ("`0` does not mean no truncation … it selects a real 200-CHARACTER-
    PER-COMPONENT limit"). The edit reached git and reached LXC 100's checkout at
    /mnt/fast/stacks (which hashes 661c7297… — correct), but was never copied into
    the appdata path the container bind-mounts. This is the estate's documented
    Renovate-deploy-drift class: merged repo changes never touch the host.
  blast_radius: >-
    COMMENTS ONLY. The full diff is 23 lines and entirely inside one comment block;
    max_filename_length: 0 is byte-identical on both sides, and no functional key
    differs. check-beets-config.sh reads the SERVER-COMMITTED config and passes green
    (test 5), so CONF-01/02/05 are unaffected. The real cost is that plan 06-07 wrote
    its retraction specifically so "a grep for it returns its retraction" — and a grep
    of the RUNNING config returns the superseded, wrong explanation instead.
  artifacts:
    - path: "/mnt/fast/appdata/arrs/beets/config/config.yaml"
      issue: "stale deployed copy, mtime 2026-09-20 23:36, sha256 96a7c622…e3e1f7"
    - path: "stacks/selfhosted/arrs/beets/config.yaml"
      issue: "correct repo copy, sha256 661c7297…4668f — this is the one that should be deployed"
  missing:
    - "Copy the repo config.yaml over the appdata copy (or re-run whatever deploy step was meant to), then re-run quick-health-check.sh and confirm the vendored-file drift block goes green"
    - "Consider why the appdata copy is a copy at all rather than a bind-mount of the checkout — D-03 already asserts one config into both containers"

- id: gap-2-pinned-count
  truth: "check-music-freeze.sh's §2 interpolated-host-path inventory matches its declared pin, so §2's pass is a claim about a fully-read tree"
  status: failed
  reason: "interpolated-host-path inventory MOVED: expected=12, found=13 — check-music-freeze.sh exits 1, which forces quick-health-check.sh to exit 1"
  severity: major
  test: 9
  root_cause: >-
    Commit 2f19870 (2026-09-18, "feat(260918-c12): textfile collector, drift timer
    units and Grafana Telegram alerting") added a 13th interpolated volume line —
    ${APPDATA_DIR}/monitoring/node-exporter-textfile:/var/lib/node_exporter/textfile_collector:ro
    in stacks/selfhosted/monitoring/node-exporter.yaml — WITHOUT moving
    DECLARED_INTERP_EXPECTED from 12 to 13 in scripts/check-music-freeze.sh in the
    same commit. Its own --stat confirms check-music-freeze.sh is not among the 10
    files it touched. Proven by re-running the script's own grep against a checkout
    of the pin commit 5b07652 (12 rows) and against HEAD (13 rows) and diffing: the
    single added row is the node-exporter one.
    This is CONVENTIONS.md convention 5 (pinned counts) firing exactly as designed —
    the instrument is right and the commit was wrong.
  blast_radius: >-
    The new line is :ro, points at a monitoring appdata directory, and does not reach
    the music library — so §2's actual concern is unaffected and the script correctly
    says §2 is UNKNOWN rather than falsely clean. The cost is that the estate's single
    health entry point has exited 1 for a week on a stale pin, which is precisely how
    an operator learns to tune out a red.
  artifacts:
    - path: "scripts/check-music-freeze.sh:508"
      issue: "DECLARED_INTERP_EXPECTED=\"${DECLARED_INTERP_EXPECTED:-12}\" — pin is one behind reality"
    - path: "stacks/selfhosted/monitoring/node-exporter.yaml:20"
      issue: "the 13th interpolated host path, added by 2f19870 without moving the pin"
  missing:
    - "Read the node-exporter textfile line by hand (done: :ro, monitoring appdata, does not reach the library) and move DECLARED_INTERP_EXPECTED from 12 to 13 in the same commit, per the script's own remediation text"
    - "Do NOT use the DECLARED_INTERP_EXPECTED env override to silence it — the script states its only sanctioned use is making the check REDDER"
