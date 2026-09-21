# Phase 6 — deferred items

Out-of-scope discoveries, written down rather than silently carried.

## DEF-06-10-01 — `timeout 120` on the freeze fold-in does not bound its inner ssh

**Found during:** plan 06-10, task 3, control F (2026-09-21).

`scripts/quick-health-check.sh` folds in the music-freeze harness as
`ssh root@172.16.1.159 "timeout $REMOTE_TIMEOUT bash /mnt/fast/stacks/scripts/check-music-freeze.sh"`.
`check-music-freeze.sh` itself opens an **inner** `ssh root@172.16.1.158` for its zfs
queries (`zfs_query()`, because LXC 100 is unprivileged and has no `zfs`). `timeout`
signals only its direct child, so the inner ssh can survive holding the pipe open — and
the **outer** ssh then never returns. Observed once: a run sat at
`Music freeze harness:` for ~10 minutes and had to be killed, having already printed
every earlier block. The same fold-in returned normally minutes earlier in the same
session, so it is intermittent and depends on atlantis responsiveness.

This is the same class as the CR-03 finding already documented in
`quick-health-check.sh` ("the bound does not bind through a pipe on its own") but a
different mechanism: here the bound does not bind through a **child process**.

**Why it is deferred, not fixed here:** the fix belongs in `check-music-freeze.sh`'s
`zfs_query()` (its `ssh` carries `ConnectTimeout=5` but no wall-clock bound on the
command) or in the fold-in's `timeout` invocation (`--kill-after`, or a process group).
Plan 06-10's mandate is three named files and the D-03/D-04/D-11 assertions; changing
the estate's single health entry point's bounding semantics is a separate decision with
its own controls, and a half-considered `timeout -k` on a script that ssh's to the
Proxmox host is exactly the kind of change that should not be made in passing.

**Not urgent:** it makes the check hang rather than report wrong, which is worse to sit
through but not a false green — and the reader is in front of it, because nothing
schedules this script (its own KNOWN LIMIT notice).
