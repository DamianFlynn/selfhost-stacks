---
phase: 07-pilot-12-albums-end-to-end
plan: 09
subsystem: music-tagging / beets-flask deploy
tags: [zfs-fence, d-22-grant, beets-flask, phase7]
requires: [07-01, 07-02, 07-03, 07-04, 07-05, 07-06, 07-07, 07-08]
provides: ["STATE 07-09-GRANTED — the token plan 07-10 gates on", "two-dataset pre-07-pilot fence", "beets-flask /media RW=true under compose project arrs"]
affects: [07-10, 07-11, 07-12, 07-13]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-09-fence-and-grant.txt
decisions:
  - "Operator: proceed (RUN 1 gate); on the GRANT-FAIL, 'rm + redeploy via arrs' (RUN 3)"
  - "beets-flask is now owned by compose project `arrs`; the stray `beets` project container was removed (stopped, bind mounts only)"
  - "Readiness test -r run as uid 568 (beetle), not LSIO `abc`, which does not exist in the beets-flask image"
requirements-completed: [IMPT-01, QUAL-04]
metrics:
  completed: 2026-09-26
  runs: 3
---

# Phase 7 Plan 09: Two-dataset fence taken, D-22 grant deployed — Summary

The library now sits behind `tank/media/Music@pre-07-pilot` + `fast/appdata/arrs@pre-07-pilot`
(listed back, G-04 sha256-equal safety copies). beets-flask is the only process that can write it
(`/media` RW=true), watching exactly two inboxes. The effective import keys are copy=true, move=false,
write=true. No album has landed.

## Runs

| Run | What | Outcome |
|-----|------|---------|
| 1 (00:08Z) | Measure, reason, ask | gate presented; operator: `proceed` |
| 2 (14:44Z) | Re-measure (another session had pushed dc84c5b), fence, grant | fence PASS; `up -d` name conflict → `STOP STATE 07-09-GRANT-FAIL`, writer stopped |
| 3 (14:56Z) | Post-grant reconciliation CONSISTENT; operator: `rm + redeploy via arrs` → resume-post-grant | `STATE 07-09-GRANTED` |

## Key facts

- Fence: tank first at 14:48:27Z, then fast at 14:48:28Z, in one ssh step (C11). Safety copies are in
  `/mnt/fast/safety/phase07/fence/` on atlantis: library.db `fbbdde0c…`, state.pickle `f6a9a1ad…`.
  Each equals its `.zfs/snapshot/pre-07-pilot` view.
- Host checkout = workstation = origin at `3ba4754` at deploy time; D-22 commit `926f1ff`.
- Appdata configs: `7d726454…` / `875fcf7e…`, equal to the repo (C9).
- Container recreated at 2026-09-26T14:58:36Z. Its compose project label is now **`arrs`** (config
  file `arrs/compose.yaml`). The watchdog line at 14:58:40Z lists `02-review` and `03-asis` only.
- quick-health-check: exit 1. The only non-green blocks are consumers ⚠ exit 3 (CONF-04, E6) and the
  import sweep ⚠ UNKNOWN (empty library). Both are expected. Freeze harness, D-03, D-04 and drift
  are all green.

## Deviations

1. **[Rule 3] Container owned by a stray compose project.** beets-flask had been brought up directly
   from `arrs/beets/flask.yaml` on 2026-09-24 as project `beets`, so `arrs/compose.yaml up -d` hit a
   name conflict. That was RUN 2's GRANT-FAIL. The plan's stop command through `arrs` did nothing to
   it, so the writer was stopped through the owning file. The fix was the operator's decision
   (RUN 3): `docker rm` of the stopped container, then the plan's arrs deploy. No file was moved or
   renamed; `flask.yaml` stays at the path that check-music-freeze.sh pins.
2. **[Rule 3] Readiness user.** `docker exec -u abc` fails because `abc` is not in this image's
   passwd file. The check was run as uid 568 (beetle), rc 0. The watchdog line (the rc6 gate) was up
   by +4 s.
3. **Mode.** `install -m 660` reads back as `760` because fast/appdata/arrs is acltype nfsv4 with
   aclmode passthrough. Owner 568:568 was preserved. Recorded, not chmod-ed.
4. The push in step 1 did nothing in RUN 2 (the other session had already pushed); RUN 3 pushed the
   07-09 docs commits.

## Known follow-ups
- `phase06-oracle.sh` layer 1 and its fixture check now go red by design (C7/C8, noted in 07-05).
- The plan text still uses `-u abc` and `arrs/compose.yaml stop`. Both are wrong for this container;
  later plans that stop the writer should use the arrs project, which now owns it.

## Self-Check: PASSED
Both snapshots were listed by exact name after the grant. The ledger's newest 07-09 token is
07-09-GRANTED. The Task 1 and Task 2 verify recipes both exit 0.
