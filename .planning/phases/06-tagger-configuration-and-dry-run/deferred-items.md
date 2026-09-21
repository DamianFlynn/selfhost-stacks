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

---

## DEF-06-11-01 — the library will grow TWO "various artists" tops: `Various Artists/` and `Various/`

**Found during:** plan 06-11, task 2, § 7.1 of the oracle run (2026-09-21).

The zero-diff tree contains both `/media/Music/Various Artists/` (44 files, the S3
stratum) and `/media/Music/Various/` (30 files, the S4 stratum). Neither is a path-rule
defect and CONF-03 passes on both: each top level DOES equal its item's own
`ALBUMARTIST`, byte-exact, which is what CONF-03 asserts. They differ because the two
strata's **tags** differ — S3 is flagged compilation and takes `va_name`'s
`Various Artists`, S4 is not flagged compilation and its files carry the literal tag
`Various`.

**Why it matters:** two spellings of the same idea means TWO ARTIST PAGES in Jellyfin
and in Music Assistant — the same duplicate-artist-page defect CONF-03 exists to
prevent, arriving through the tags rather than through the paths.

**Why it is deferred, not fixed here:** no path rule can fix it. The fix is either a tag
normalisation over the affected albums (set `albumartist` to the canonical string) or a
`comp` flag correction on the S4-shaped content (which would route it through rule 5 and
pick up `va_name` automatically). Both are Phase 7 decisions with their own blast radius:
the *Now!* `1-115` set is 115 folders / 4,746 files, and it is the population this shape
is drawn from. Choosing between "normalise the tag" and "fix the comp flag" needs a
count of how many backlog albums carry each shape, which has not been taken.

**Not urgent, and not a regression:** the fixture predicted both tops, so this is a
pre-existing property of the content, surfaced by the dry run rather than caused by it.

---

## DEF-06-11-02 — plan 06-11's task-1 verify cannot distinguish a path from prose about a path

**Found during:** plan 06-11, task 1, running the plan's own verify (2026-09-21).

The verify greps `06-11-oracle-run.txt` for the literal `Compilations` + `/` and treats
**any** occurrence as a failure. That predicate cannot tell a destination path from a
sentence stating that no such path exists — nor from the oracle's own D-15 SUCCESS
message, which reads "zero Compilations/ components". Including the run's verbatim
console output therefore makes the check fail on the evidence that it passed.

**Worked around, not weakened:** the artifact avoids the literal (writing the component
name without its trailing slash, and saying why), and the verbatim console log is filed
in the companion `06-11-wrote-nothing.txt`, which carries all three D-29 layers and every
class-assertion verdict and explains the relocation. The check stayed strict on the file
that carries the 174-line destination list.

**The general form, which is the part worth keeping:** a "no such string anywhere in the
artifact" predicate is not a substitute for "no such string in the MEASUREMENT". Future
plans in this family should scope the negative to the machine-generated block — e.g.
`sed -n '/^BEGIN DESTINATIONS$/,/^END DESTINATIONS$/p' | grep -q ...` — so that an
artifact is free to discuss the defect it is proving absent.
