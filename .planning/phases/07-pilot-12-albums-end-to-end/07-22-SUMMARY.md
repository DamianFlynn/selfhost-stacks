---
phase: 07-pilot-12-albums-end-to-end
plan: 22
subsystem: music-assistant, standing-checks
tags: [music-assistant, d-28, aunique, uat-gap-closure, cons-04]
requires: ["07-18", "07-20"]
provides:
  - "MA library without the P04 twin (album 169 ABSENT); P02 as one clean album (170)"
  - "D-28 standing check keyed on a P02 control row; CONVENTIONS §5 amended"
affects: [scripts/check-music-consumers.sh, CONVENTIONS.md, quick-health-check]
tech-stack:
  added: []
  patterns: ["provider-scoped MA sync with a one-shot sentinel", "control row keeps an assertion non-empty"]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/07-22-SUMMARY.md
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-22-ma.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
    - scripts/check-music-consumers.sh
    - CONVENTIONS.md
decisions:
  - "The refresh of album 167 was not issued: the sync deleted 167 and re-created P02 as album 170, already clean. Writing to an id the operator never named would have been improvising."
  - "MA OWN COVERS is recorded strictly as 7/8. P12's (album 3) first image is Spotify's NOW 116 front for the same release, which is correct art but falls outside the plan's three own-source classes."
metrics:
  duration: "~15 min (Task 3 only; Task 1 was committed as 0509100)"
  completed: 2026-09-28
---

# Phase 7 Plan 22: Music Assistant repair after the P04 back-out Summary

One provider-scoped Music Assistant sync removed the P04 twin (album 169). It also re-created P02 as a single clean
album 170, with its own cover and only its own external ids. The D-28 standing check now keys on a P02 control row and
reads 1/1 on the host.

## Operator gate (Task 2)

- The answer came through AskUserQuestion and was recorded at 2026-09-28T13:32:37Z. The selection, verbatim, was
  "apply (Recommended)", described as "Run the sync, the refreshes and the conditional 169 removal, then deploy the
  D-28 check fix."
- The gate restated the accepted limitation that MA gets no database backup. The artifact records `DISPOSITION: apply`
  exactly once.

## What was done (Task 3)

| Step | Result |
|---|---|
| S. Sync | Exactly one `music/sync {"providers":["filesystem_local--XJaJWNUS"]}`, issued 13:32:51.300Z and complete by 13:32:55.748Z. It ran before the 13:55:48Z scheduled run, so the NOT NEEDED arm did not apply. MA logged `Found 12 changed/new items`. There was no restart. |
| R. After the sync | Albums went 79 → 78; tracks stayed 1412 and artists 201. Albums 167 and 169, and track 1541, are gone (MediaNotFoundError). Album 170 was created: `Benson Boone/American Heart`, 10 tracks. `MA ALBUM 169: ABSENT (sync)`. The recording successor of 1541 is 1629, which maps NOW 121 and P02 only, with no P04 path. |
| X. 169 removal | Not entered. 169 was absent after the sync. Neither `music/albums/remove` nor `music/library/remove_item` was issued. |
| F. Refresh 167 | **Not issued**, because the target no longer exists (see Deviations). The P02 album, now 170, reads `FIRST IMAGE: OWN` (its own FLAC embedded art). `EXTERNAL IDS: CLEAN`: only barcode 00093624834588, RG 8e25d6da… and its own MBID c0df8104…. None of NOW 121's ids remain. DEF-07-22-02 is not filed. |
| T. Tasks | `MA FS-SYNC TASKS: 4/4 enabled`, last_error null. MA moved next_run to 2026-09-29T01:32:5xZ. No `tasks/set_enabled` call was made. |
| P. Own covers | `MA OWN COVERS: 7/8` (strict). Albums 170, 168, 165, 164, 163 and 162 use their own embedded art, and 166 uses the CAA front for its own MBID. Album 3 (P12) leads with Spotify's image, which was fetched and viewed: it is the NOW 116 cover. That is correct art but not from an own source, and it predates this plan. No album shows another album's cover. |
| D. Deploy | Commit 596438a was pushed, and the host ran `pull --ff-only` to 596438a (HEAD equal, porcelain 0). On LXC 100, section 4d reads `✅ D-28: MA album 170 maps 'Benson Boone/American Heart' and reads album artist 'Benson Boone'`, which is `1 (target 1)`. D-24 is 29, equal to its pin, so there is no re-pin. FAILURES 0 and RC 3 is the documented CONF-04 state. `CHECK 4d: PASS (1/1)`. |

**quick-health-check after the deploy:** it exited 1, so the result is **not fully green**. The D-28 ❌ from the
pre-gate run is gone, and every block reads ✅ with FAILURES 0, except one. That one is the consumers audit's ⚠️
"CONF-04 MEASURED AND OPEN (exit 3)". It is the by-design state until E6 discharges CONF-04, and the script documents
it as not a pass. D-28 was the last RED, but CONF-04's ⚠️ still sets the exit to 1.

## Deviations from Plan

1. **[Scope reduction] No refresh of album 167 was issued.** The sync deleted album 167 together with 169. It also
   deleted all ten P02 tracks (1541, 1548, 1621–1628) and re-created them as album 170 with tracks 1629–1638. With no
   target left, `music/refresh_item` on 167 would have done nothing. A refresh of 170 was not authorised by name, and it
   was not needed: every property F set out to measure already reads clean on 170. The plan's `MA ALBUM 167 …` lines
   are kept so its verify still binds, and each one names the successor id. This was one write fewer, not a substitute
   write.
2. **[Observation, filed as DEF-07-22-04]** MA re-creates an album under new ids when its tracks change, and does not
   update it in place. Any MA favourite, playlist entry or play history on the old P02 ids is gone. None of these was
   measured before the sync. Nothing in the repo pins an MA numeric id. Album 166 did not pick up the NOW 117
   `cover.jpg` that 07-20 wrote, because no NOW 117 track changed. It still shows the correct CAA front.
3. **[Execution] The workstation run of check-music-consumers.sh could not look.** The MA and Jellyfin secrets live
   only on LXC 100, so that run recorded FAILURES 15, all UNKNOWN. The recorded reading comes from the host checkout,
   which is the route quick-health-check uses.
4. **[Grep hygiene, CONVENTIONS §9]** The artifact first carried the literal stop-state token in a sentence saying it
   had *not* arisen. The plan's verify short-circuits to pass whenever that token is present, so the sentence was
   reworded before commit and the verify was re-run without the short-circuit (pass).

## Hard rules held

- The provider list was exactly `["filesystem_local--XJaJWNUS"]`, and a sentinel refuses a second sync.
- `music/library/remove_item` was never issued, and neither was `music/albums/remove`.
- There was no MA restart: the only `Starting Music Assistant Server` line is 2026-09-25.
- There was no Jellyfin or beets write. Credentials passed only through `ma-lib.sh`, using `$ENV` for jq and stdin or
  process substitution for curl, never argv.
- STATE.md and ROADMAP.md were not touched.

## Known Stubs

None.

## Commits

- 0509100: Task 1 (pre-state, gate presented). Earlier session.
- 596438a: `docs(07-22): MA drops P04 twin, refresh 167; D-28 control row (07-UAT gaps 2-3)`
- (this commit): the artifact's § D plus this SUMMARY.

## Self-Check: PASSED

- The artifact, deferred-items.md, the script and CONVENTIONS.md exist. Commit 596438a is on origin/main and is the
  host HEAD.
- The plan's Task 2 and Task 3 automated verifies pass, the latter with the stop-state token absent.
