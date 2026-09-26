---
phase: 07-pilot-12-albums-end-to-end
plan: 09
status: stopped
executed: partial
stop_token: "STOP STATE 07-09-GRANT-FAIL"
requirements: [IMPT-01, QUAL-04]
requirements-completed: []
date: 2026-09-26
---

# Phase 7 Plan 09: STOPPED at GRANT-FAIL — fence taken, grant not deployed

Named `-PARTIAL.md`, not `-SUMMARY.md`, on purpose: phase-plan-index marks a plan complete on the
existence of a SUMMARY file, and this plan is not complete.

## What happened (RUN 2, 2026-09-26T14:44Z–14:52Z; operator answered `proceed`)

- **Re-measure** (the estate moved after RUN 1: 1a0f556, 61acd67, dc84c5b committed and pushed by
  another session): workstation = origin = host = `dc84c5b`, host tree clean; both pre-07-pilot names
  absent, `tank/downloads@pre-phase5` present, `written` 0; `library.db`/`state.pickle` at fixture;
  items 0; inboxes 0/0/0; `/media` RW=false. dc84c5b changes only `DECLARED_INTERP_EXPECTED` 13 → 9;
  the `PHASE7_RW_TAGGER` exception is untouched and `check-music-freeze.sh` ran green on the host
  (FAILURES 0, declared D-22 exception 1).
- **Step 1** push / `pull --ff-only`: both no-ops; HEAD equal.
- **Step 2 fence: PASS.** One ssh step on atlantis: `tank/media/Music@pre-07-pilot` (14:48:27Z) then
  `fast/appdata/arrs@pre-07-pilot` (14:48:28Z), both listed back by exact whole-line match. Safety copies
  in `/mnt/fast/safety/phase07/fence/`; the snapshot view is sha256-equal to them (G-04).
- **Step 3 grant: FAIL.** Both configs installed, sha256 = repo (`7d726454…`, `875fcf7e…`), but
  `docker compose -f stacks/selfhosted/arrs/compose.yaml up -d --no-deps beets-flask` failed with a
  name conflict. The live container belongs to compose project `beets` (brought up from
  `arrs/beets/flask.yaml` directly on 2026-09-24T23:07:39Z), not project `arrs`. Writer stopped via
  the owning project's compose file; `State.Running=false`, `/media` still RW=false.
- Steps 4 (qhc) and 5 (GRANTED) not run.

## Operator decision needed (the `resume-post-grant` fix)

(a) `docker rm beets-flask` (the container only, since every mount is a bind), then `resume-post-grant`
    runs the plan's arrs-project `up -d`. This also makes the arrs stack the container's owner in the
    future. Or (b) amend 07-09 to deploy and stop through the `beets` project file.

## Deviations

- The stop command named in the plan (`arrs/compose.yaml stop`) was a no-op against a container from
  a different project. The same reversible stop went through `arrs/beets/flask.yaml`, which owns it.
- `install -m 660` produced mode `760`, because fast/appdata/arrs is nfsv4 ACL passthrough. Recorded
  and not chmod-ed.

Evidence: `artifacts/07-09-fence-and-grant.txt` § RUN 2; `artifacts/07-pilot-ledger.txt`.
