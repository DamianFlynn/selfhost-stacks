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

## DEF-06-12-01 — path rule 2 (`albumtype:=dj disctotal:2..`) is UNEXERCISED and now UNOWNED

**Found during:** plan 06-12, reading its own mandate against three other documents (2026-09-21).

Three committed documents assign the rule-2 class assertion to **plan 06-12**:
`06-SAMPLE.md:316-324` ("Plan 06-11 should assert rule 2 as a **named class assertion** over one
of those seven rather than expect a row for it here" — and 06-11 read that as 06-12's),
`06-09-SUMMARY.md`, and `06-11-SUMMARY.md` § Known Stubs ("`06-EXPECTED-TREE.txt`'s header,
`06-SAMPLE.md` and `06-09-SUMMARY.md` all assign this to **plan 06-12**").

**`06-12-PLAN.md` contains no task for it.** Its two tasks are CONF-05's country-preference
demonstration and D-30 arm 2; neither its `must_haves`, its `artifacts` list nor its
`success_criteria` mentions rule 2, `albumtype`, `disctotal` or the seven folders. Plan 06-12 did
not invent one, because adding an unplanned class assertion over a folder outside the drawn sample
is the hand-picking D-26 exists to prevent, and because `files_modified` names exactly two
artifacts.

**So the state is:** rule 2 is the only `paths:` rule in the committed stanza that no Phase 6
instrument has evaluated. Both drawn S5 folders resolved to rule 3 (`albumtype:=dj`, single disc)
because `Mastermix.Issue.420.2021` carries `disc {1,2}` but **no `disctotal`** and
`Mastermix.Issue.421.2021` carries neither.

**The shape does exist in the population** — 7 of the 60 `dj-mixes` folders carry `disctotal = 2`
on all ten files: `Mastermix_Issue_403`, `_404`, `_413`, `_418_April_2021`,
`VA-Mastermix.Issue.422-2021`, `.427.2CD-2021`, `.429-2022` (`06-SAMPLE.md:316-324`).

**What it would take:** one `beet import -A --set albumtype=dj` of one of those seven into a
throwaway library, then `beet move -p`, asserting the destination renders
`DJ/$albumartist/$album%aunique{}/$disc-$track $title` — i.e. a `NN-NN` filename prefix rather
than rule 3's bare `NN`. `scripts/phase06-oracle.sh` already has every mechanism this needs.

**Owner:** unassigned within Phase 6. The natural homes are plan 06-13 or 06-14 if either has
room, otherwise it belongs with the OQ-2 DJ-routing item Phase 7 already inherits — the two are
the same subject. **It must not be left to Phase 7's first real import to discover**, because a
rule that has never been evaluated is exactly where a `-1 - ` / `00-01` rendering defect hides,
and Phase 3 found one of those in the tagger this project retired.

## DEF-06-12-02 — `musicbrainz.search_limit` is 5, and at 5 whole classes of candidate are never offered

**Found during:** plan 06-12, task 1 (2026-09-21).

The committed config does not set `musicbrainz.search_limit`, so beets' default of **5** applies
(`beets/metadata_plugins.py@v2.12.0:201`). Measured on the S4 `Vol 001` row:

| `search_limit` | candidates | countries offered | US candidates |
|---|---|---|---|
| 5 (as committed) | 5 | DK, FI, GB, JP, NZ | **0** |
| 25 (instrument widening) | 25 | DK, FI, GB, IL, JP, NZ, US, XW, (none) | **7** |

At 5, the three best GB candidates for this release are joined by four foreign pressings and the
correct answer still wins — but the pool is too small to contain the alternative
`match.preferred.countries` exists to discriminate against, so at the committed value the setting
had nothing to prefer against on this row at all.

**Why it is deferred, not changed here:** raising it has a real cost on both sides. More
candidates means more MusicBrainz round-trips per folder (the backlog is 162 audio-bearing
folders), more think time at an interactive prompt, and more chances for a human to pick the wrong
one from a longer list. Lowering the risk of "the right release was never offered" raises the risk
of "the wrong release was offered plausibly". That is a Phase 7 throughput-and-accuracy decision
with the pilot import's own numbers in front of it, not a value to change inside a paper phase on
one row's evidence.

**Do not read this as a recommendation to raise it.** It is a recommendation to *measure* it
during Phase 7's pilot: count, per folder, whether the accepted candidate was in the first 5.
