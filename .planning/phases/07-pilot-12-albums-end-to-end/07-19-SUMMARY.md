---
phase: 07-pilot-12-albums-end-to-end
plan: 19
subsystem: music-tagging / beets pipeline config (fetchart + preferred.media), pipeline half of 07-UAT gaps 1–3
tags: [uat-gap-1, uat-gap-2, uat-gap-3, od-2, fetchart, cover-art-archive, preferred-media, check-beets-config, throwaway, phase7]
requires: [07-18]
provides:
  - "repo config.yaml: plugins [musicbrainz, fetchart]; art_filename cover; fetchart {auto: yes, sources: [coverart]}; match.preferred.media ['Digital Media', 'CD']; embedart unlisted, auto: no"
  - "check-beets-config.sh: exact plugin set {musicbrainz, fetchart} + four OD-2 assertions; self-test 15 cases (ST_PLANNED_CASES 13 -> 15)"
  - "throwaway proof: CAA cover.jpg written, artpath set, zero embedded-picture change, as-is fetches nothing"
  - "measured ranking effect for 07-20's gate (P02 -> Digital Media; P10 CD control holds)"
affects: [07-20, 07-21, 07-22]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-19-pipeline-config.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/07-19-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets/config.yaml
    - scripts/check-beets-config.sh
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Operator OD-2 (2026-09-28, \"Pipeline + pilot repair\"), items 1–3, applied to the repo copy only"
  - "The throwaway import used the plan's named fallback P03 (ef528afc). P06 was skipped by `-q` at distance 0.0455 (medium rec, the XW country term alone). No threshold was lowered to force it."
  - "Task 1 committed separately from Task 2 (atomic per task), instead of the plan's single combined commit"
requirements-completed: []
metrics:
  completed: 2026-09-28
  duration: "09:39Z – 09:57Z (~18 min)"
  tasks: 2
  files: 4
---

# Phase 7 Plan 19: fetchart + preferred.media in the repo config, checked and proven in a throwaway — Summary

**The repo's beets config now fetches each matched album's own Cover Art Archive front as a sidecar
`cover.jpg`, with no audio rewrite. It also prefers a Digital Media release, then a CD.
`check-beets-config.sh` asserts that shape, and its self-test drives every new assertion red. A
throwaway import inside beets-flask proved the art lands, `artpath` is set and no picture is
embedded. The live check goes red on exactly the four expected assertions. ⚠ The Task 1 commit
reached origin and the LXC 100 checkout through a concurrent session's push, before the appdata
install. The vendored-file drift block is red now, and resolving it is an operator decision (see
"Needs an operator decision").**

## What was done

- **Task 1 (1e054a6).** RED first: the self-test was moved to the target shape (cases 5a/5b, case 1 set to 26,
  `ST_PLANNED_CASES=15`) and failed 6 of 15. The failure shape differs from the plan's prediction: the old
  exactly-one-plugin assertion went red in every dump case, including 5b, which went red for the wrong reason. The
  artifact records this. GREEN: the plugin set must equal `{fetchart, musicbrainz}`, and four `expect_eq` assertions
  were added for `fetchart.auto`, `fetchart.sources`, `art_filename` and `match.preferred.media`. Result: 15/15.
  The empty dump gives 26 = 22 + 4, and the four new UNKNOWN lines are each named in the artifact. Repo config edited
  with WHY comments. The claims in those comments were verified in the installed beets 2.12.0: media weight 1.0
  against country 0.5, and the `(\d+x)?(…)` wrap. No credential-shaped content was added, and no invocation-shaped
  `beet` line.
- **Task 2 (82bc490)**, all inside beets-flask under `/tmp/p7-0719`, or read-only:
  - (a) beets 2.12.0, fetchart and requests import, and an IMBackend resizer is present (informational).
  - (b) `RC6 COMMIT KEEPS NEW KEYS: yes`. Plugins loaded: {fetchart, musicbrainz}.
  - (c) `BEETS-FLASK RUNS PLUGIN IMPORT STAGES: yes`. At `session.py:712-726`, plus `import_task_files` into
    fetchart's `assign_art`. This is a source proof; the first live proof is the first 02-review import after deploy.
  - (d) Ranking, read-only (staged sha256 sets unchanged). P02: CURRENT picks c0df8104 (CD) from a three-way
    physical tie. NEW picks b3a1e018 (Digital Media, XW), in an exact tie with cfb585a2. P10: b057dee8 (CD) stays
    first under both, with the margin 0.121 → 0.115.
  - (e) `THROWAWAY IMPORT: PASS` on P03. One `cover.jpg` (JPEG, 3,620,959 B, which equals CAA's content-length);
    `artpath` resolves; embedded pictures unchanged 15/15, with the same picture sha. The as-is control fetched
    nothing. The real `library.db` (8f5994b8…) and `state.pickle` (b8ce8afd…) are unchanged throughout.
    `/tmp/p7-0719` was removed through a two-layer fence written at the call site: 6 layer-2 and 4 layer-1
    negatives were refused, and absence was asserted.
  - (f) The oracle loads fetchart but cannot fetch, because every import is `-A` and `coverart` is remote. No
    DEF-07-19-03. The oracle was not edited.
  - (g) `PRE-DEPLOY LIVE RED SET: plugins, OD-2 fetchart.auto, OD-2 fetchart.sources, OD-2 match.preferred.media`
    (exit 1). `art_filename` is already green at beets' default.

## Deviations from Plan

1. **[Rule 3 – blocking] Throwaway album P06 → P03.** CAA does have P06's front (200). But `import -q` skipped
   P06 because its recommendation was medium (0.0455 > 0.04, entirely the XW country term). The plan's named
   fallback P03 was used. No threshold was lowered.
2. **Method note (instrument, not reading).** BSD `sed` ignored `\b` when the P03 driver was derived, so three
   listing lines in transcript (4b) point at P06's roots. Every P03 assertion comes from a read-only re-read of the
   correct roots (4c), taken before cleanup. The artifact states this.
3. **Commit split.** Task 1 (1e054a6) and Task 2 (82bc490) were committed separately, where the plan asked for one
   combined commit. The orchestrator asked for atomic per-task commits, and separate commits were safer while
   another session was committing to the same tree.
4. **Stray no-ops disclosed.** A `beet … config` read created `/tmp/p7-0719/x.db` inside the throwaway, which the
   fence then removed. An `rm -f /dev/null.x` ran on LXC 100 against a path that does not exist.

## Needs an operator decision (not a deviation by this executor)

**1e054a6 was pushed and deployed to the host checkout by a concurrent session.** Measured: 548b951
(teslamate) was committed on top of it at 10:52:35 +0100 and pushed. LXC 100's `/mnt/fast/stacks` HEAD is
548b951. `quick-health-check.sh` at 09:54:27Z exits 1 with `survivor-config.yaml DRIFTED — repo=9b48…
host=adf8…`. The running beets-flask is unaffected, because it reads the unchanged appdata copy. This executor ran
no push. The plan's verify conjunct "not pushed" is therefore FALSE. There are two ways to clear the red, and
both are outside this plan's exclusions: run 07-20's gated appdata install now, or revert 1e054a6 on main and
re-pull the host. The operator should choose at 07-20's gate. The same health check also shows a D-28
consumers red. That red comes from P04's removal in 07-18 and is owned by 07-21/07-22, not this plan.

## Deferred items filed

- **DEF-07-19-04** (observation): a fetchart `cover.jpg` is indistinguishable by extension from a Jellyfin `.jpg`
  sidecar in the freeze inventory. Attribute it via `artpath` before calling it a Jellyfin write.
- **DEF-07-19-05** (observation, for 07-20's gate): the files carry no media tag, so the preference ranks Digital
  Media above CD for CD rips too. A CD rip whose digital edition has the same tracklist and mediums would now match
  the digital edition.

## Known Stubs

None.

## Threat Flags

None. There is no new network endpoint or auth path. The outbound fetches to coverartarchive.org and
musicbrainz.org are in the plan's trust boundaries. T-07-19-01…05 were all mitigated as planned.

## Self-Check: PASSED

- FOUND: stacks/selfhosted/arrs/beets/config.yaml, scripts/check-beets-config.sh,
  artifacts/07-19-pipeline-config.txt, deferred-items.md (DEF-07-19-04, -05)
- FOUND commits: 1e054a6, 82bc490
- `--self-test` exit 0 (15/15); Task 1 and Task 2 plan-verify greps pass, except the "not pushed"
  conjunct, which is false because of the external push above.
