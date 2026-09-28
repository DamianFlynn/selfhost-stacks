---
phase: 07-pilot-12-albums-end-to-end
plan: 20
subsystem: music-pipeline / beets-flask deploy
tags: [beets, fetchart, preferred-media, deploy, halted]
status: halted
halt: "STOP STATE 07-20-DEPLOY-FAIL (step B9, T-06-33)"
requires: ["07-19"]
provides: ["07-19 config installed in appdata (sha == repo); host == origin == workstation"]
affects: ["07-21", "07-22", "07-23"]
key-files:
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-20-deploy-backfill.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Operator gate answer 2026-09-28T11:54:15Z: deploy-and-backfill (Recommended), accepting DEF-07-19-05 and DEF-07-19-04"
  - "Deploy halted at B9 per the plan's failure path; beets-flask stopped; the new config is left installed; reinstating the old config is an operator decision"
metrics:
  completed: 2026-09-28
  tasks: "1 of 2 (Task 2 halted at step B9)"
---

# Phase 7 Plan 20: deploy halted at the post-deploy check (PARTIAL)

The 07-19 fetchart and preferred.media config is now live in appdata, sha-equal to the repo. Host,
origin and workstation all sit at eb794b5. `check-beets-config.sh` then failed exactly one assertion.
That assertion was not an art/media one: it was T-06-33, the redaction no-op. Following the plan's
failure path, beets-flask is **stopped**, and the P10 backfill was **not taken**.

## What happened

| Step | Reading |
|------|---------|
| Gate | `OPERATOR ANSWER` "deploy-and-backfill (Recommended)" at 11:54:15Z, recorded as `DISPOSITION: deploy-and-backfill` |
| B1–B2 | origin had not moved. Push 548b951..eb794b5. Host `pull --ff-only` put it at eb794b5 == workstation == origin, porcelain 0 |
| B3 | safety copy `/mnt/fast/safety/phase07/0720/config.yaml.pre-0720` = adf838dd… (760 568:568) |
| B4 | installed with 760 568:568, appdata sha 9b482632… == repo |
| B5–B7 | beets-flask recreated alone and ready in 10 s. New watchdog line lists exactly 02-review and 03-asis. Mount shape correct |
| B8 | library.db 8f5994b8… and state.pickle b8ce8afd… unchanged by the recreate |
| B9 | `check-beets-config.sh` RC=1, FAILURES 1. Every art/media assertion PASS. ❌ T-06-33 redaction no-op DIFFERS |
| B-STOP | `compose stop beets-flask`, Running=false at 11:56:41Z. DB and state hashes still unchanged |
| B10, B11, C | not run |

## Why T-06-33 is red

I diagnosed it read-only, with values masked (artifact § B9a). The redacted and unredacted
`beet config` dumps differ only in fetchart's `fanarttv_key`, `google_key`, `google_engine` and
`lastfm_key`. fetchart marks all four `redact = True` whatever their value. Three are null. The fourth,
`google_engine`, holds beets' shipped default. The repo sets none of them, so no credential is present
and the red is a gap in the check. 07-19's live pre-deploy run never loaded fetchart, so it could not
see this. Filed as **DEF-07-20-01**.

## Deviations from Plan

None to the method. Step B9 failed and the plan's failure path was taken as written. The one addition
was a read-only diagnosis (B9a), run before the stop, so the operator has the cause.

## Current estate state (for the operator)

- beets-flask is **STOPPED**, so the music importer is down. The 8 entries in 02-review are
  untouched.
- The appdata config is the NEW one (9b482632…), and the old one is at the safety path. The drift
  red from A9 should now be clear, but quick-health-check was not re-run.
- There were no library writes: no fetchart, no cover.jpg, and album 1's artpath is still NULL.

## Decisions needed

1. **Fix T-06-33 and resume.** The recommended fix scopes T-06-33 to non-default values of the
   redacted keys (DEF-07-20-01). Once fixed, a continuation re-runs B9–B11 and C. Pushing the check
   change and pulling it on the host adds a commit, so "host == origin" is re-measured.
2. **Or accept this T-06-33 red for now, restart beets-flask, and run B10, B11 and C.** That would
   need an explicit operator waiver, because the plan's B9 requires exit 0.
3. **Or reinstate the old config** from the safety copy and restart. This is the plan's
   operator-only undo, and it reopens UAT gaps 1–2.

## Self-Check

- Artifact contains `OPERATOR ANSWER`, one `DISPOSITION:` line and `STOP STATE 07-20-DEPLOY-FAIL`,
  with no unbracketed `zfs [r]ollback` or `Full[R]efresh` token.
- Commits eb794b5 (gate answer) and 6ed1d90 (pre-gate) exist.
