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
