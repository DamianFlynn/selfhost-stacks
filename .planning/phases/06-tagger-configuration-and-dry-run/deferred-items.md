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

---

## DEF-06-21-01 — `import.write: yes` over a `:rw` `/downloads` with an `autotag: auto` inbox, covered by none of the three named controls

**Found during:** plan 06-21, task 2, dispositioning review finding **WR-09** (2026-09-22).
**Disposition:** `CARRIED`. Also ROADMAP Phase 7 entry criterion **E11**, and stated in the
runbook at `stacks/selfhosted/arrs/beets.md` § *Still open at Phase 6 close*.

`stacks/selfhosted/arrs/beets/config.yaml` sets `write: yes` and names three controls that make it
safe during Phase 6: the `-c` overlay, the `:ro` mount (D-05) and the statefile sha256 (D-29).
**All three protect `/media` or beets' own state. None of them protects `/downloads`** — which is
mounted **`:rw`** (`flask.yaml:146`) and is where all three registered inboxes live. The
beets-flask watchdog is the **active** runtime (`restart: unless-stopped`) and `01-auto` is
registered with **`autotag: auto`** (`flask-config.yaml:80-83`), so any folder that appears under
`/downloads/complete/nzb/_inbox/01-auto` is imported without a prompt, by a config whose
`import.write` is `yes`. The overlay control reaches only invocations *this phase's scripts* make;
the watchdog reads the vendored config directly and the overlay never touches it.

**What actually bounds the exposure today**, stated plainly because the config does not state it:
nothing automatic stages into `_inbox/` (SABnzbd lands in `complete/nzb/music/`, and plan 06-04
moved the two real folders to the **unregistered** `04-hold`), and `tank/downloads@pre-phase5` is
**un-released** (D-32, entry criterion **E4**). **"Nobody has put a file there" is not one of the
three controls the file claims**, and it is not a control at all.

**Why it is deferred, not fixed here — a dependency conflict, not a difficulty judgement.** The
review's stronger option is to set `import.write: no` in the vendored `config.yaml` for the
remainder of Phase 6. Any edit to that file changes its **sha256** — and that digest is the exact
object every CONF-01, CONF-02 and CONF-05 assertion in this phase was measured against, as well as
the appdata copy the `quick-health-check.sh` vendored-drift block compares repo-side against
host-side. Editing it to close a latent finding would invalidate committed proof artifacts for
three requirements in order to harden a path nothing currently writes to. That trade is wrong in
this direction and right in the other, which is why the change belongs where the proofs are being
re-taken anyway.

**Scheduled, not open-ended:** Phase 7's **first act is the `rw` grant (E3)**, which is where every
other Phase-7 behaviour flag is already scheduled to move. `import.write` moves with them, as a
decision recorded in that commit rather than a default nobody chose.

**Urgency:** latent, not active — but it is the one finding in `06-REVIEW.md` that describes a path
by which files could be **written** rather than an instrument that could **report** wrongly. It
must not be discovered by an operator dropping a folder into `01-auto` to see what happens.

---

## DEF-06-21-02 — the oracle's run-tagged in-container temp names are written but never exercised

**Found during:** plan 06-21, task 2, dispositioning review finding **IN-06** (2026-09-22).
**Disposition:** `FIXED (undriven)` — plan 06-18, commit `89a349b`,
`artifacts/06-18-oracle-fence-driven.txt` § 10. Recorded as undriven by plan 06-18 itself.

`scripts/phase06-oracle.sh`'s in-container temp files beneath `$SCRATCH` now carry the run's PID
(`lib.$$.db`, `overlay.$$.yaml`, `state.$$.pickle`) instead of fixed names in a world-writable
directory. `$SCRATCH` itself was deliberately left as `/tmp/p6`, because the precheck, the cleanup
assertion, the 06-18 fence allow-list and the committed 06-11 artifacts all quote that path by
name.

**Why undriven:** `--self-test` never reaches step 5, which is the only place those names are used.
No `--run` was performed by 06-18, 06-19 or 06-21.

**Condition that would drive it:** the next real `phase06-oracle.sh --run`. Confirm the three
files appear inside `beets-flask` under `/tmp/p6/` carrying the invoking PID, and that two runs
back to back do not collide on them.

**Urgency:** hygiene on a single-tenant container. The risk it closes is a stale root-owned
leftover turning a read into a BLIND, which fails closed.

---

## DEF-06-21-03 — the oracle's dirty-destination cleanup text has never been printed

**Found during:** plan 06-21, task 2, dispositioning review finding **IN-11** (2026-09-22).
**Disposition:** `FIXED (undriven)` — plan 06-18, commit `7c2e349`,
`artifacts/06-18-oracle-fence-driven.txt` § 10. Recorded as undriven by plan 06-18 itself.

Every `exit 3` path between the oracle's step 5 and step 12 leaves `/tmp/p6/lib.db` — a byte copy
of the real library — inside the container, and `/mnt/fast/safety/phase06/oracle.stamp` on LXC 100.
The next run's dirty-destination precheck then refuses, which is **correct** but used to present as
an unexplained refusal. The refusal now prints the exact cleanup command and states that
`--baseline` always leaves the host stamp **by design**.

**Why undriven:** reaching it needs a genuinely dirty `$SCRATCH` inside the live container, and no
run was aborted mid-flight during the gap closure.

**Condition that would drive it:** abort a `--run` between step 5 and step 12 (or plant
`/tmp/p6/lib.db` as `beetle`), then invoke the oracle again and read the refusal — confirming the
printed command is the one that actually clears the state.

**Urgency:** it makes a correct refusal legible. It cannot produce a wrong verdict in either
direction.

---

## DEF-06-21-04 — `check-beets-config.sh`'s corrected readiness-timeout message has never been printed

**Found during:** plan 06-21, task 1, dispositioning review finding **IN-03** (2026-09-22).
**Disposition:** `FIXED (undriven)` — plan 06-15, commit `4aaf79a`,
`artifacts/06-15-check-beets-config-rerun.txt`.

The readiness-gate failure message rendered `READY_ATTEMPTS * READY_SLEEP` (30 s) when the loop
sleeps only *between* attempts (5 × 5 s = 25 s). Corrected to
`$(( (READY_ATTEMPTS - 1) * READY_SLEEP ))`.

**Why undriven, and note this classification is plan 06-21's, not 06-15's.** 06-15 recorded IN-03
as retired and did not call it undriven; the register applies its own vocabulary test — the
corrected text lives inside the readiness-gate **failure** branch, and every run in this phase
reached ready, so the branch has never been observed firing. Calling it `FIXED` would assert a
drive that did not happen.

**Condition that would drive it:** run `scripts/check-beets-config.sh` with the `beets-flask`
container stopped, so five consecutive readiness probes fail, and read the elapsed figure in the
message.

**Urgency:** the defect is a wrong number in a diagnostic message. It misleads a reader about how
long the tool waited; it changes no verdict.

---

## DEF-06-21-05 — the glob-free forbidden-substring loop is behind a knob nothing sets

**Found during:** plan 06-21, task 1, dispositioning review finding **IN-07** (2026-09-22).
**Disposition:** `FIXED (undriven)` — plan 06-15, commit `4aaf79a`,
`artifacts/06-15-check-beets-config-rerun.txt`.

`EXTRA_FORBIDDEN_SUBSTRINGS` was expanded as `local IFS=':'; for forb in $EXTRA_...`, so a value
containing `*` or `?` underwent **pathname expansion** against the repo root as well as the
intended field splitting. Replaced with `IFS=':' read -r -a forb_arr <<<"$EXTRA_..."`.

**Why undriven, and this classification is also plan 06-21's rather than 06-15's.** The whole loop
sits behind `if [[ -n "$EXTRA_FORBIDDEN_SUBSTRINGS" ]]` (`scripts/check-beets-config.sh:558`) and
the knob's default is empty, so no run in this phase entered it. The original defect was
additive-only — it could add spurious failures, never suppress real ones — which is precisely why
it was never observed.

**Condition that would drive it:** run the script from a directory holding matching filenames with
`EXTRA_FORBIDDEN_SUBSTRINGS='*'` (or a value containing `?`), and confirm the forbidden list is
the one literal string rather than the expanded directory listing.

**Urgency:** an override-only path whose failure mode is a spurious red, on a knob nothing in the
estate sets today.

---

## DEF-06-21-06 — the overlay-key half of `D04_EXEMPT_RE` is the exemption register's weakest link

**Found during:** plan 06-21, task 2, reading plan 06-16's NOT-DRIVEN register (item N-4).
**Disposition:** residue of `CR-01`, which is `FIXED`. Also named in ROADMAP entry criterion
**E10**. Plan 06-16 nominated this itself as *"the obvious next drive"*.

The D-04 exemption register partitions invocation-shaped lines into **asserted** (3) and
**exempt** (5), keyed per line on the overlay substring `$SCRATCH_OVERLAY` / `$ROOT/overlay.yaml`.
06-16's control 1 planted a non-compliant invocation in a **third** file, proving the register does
not swallow arbitrary files — but it did **not** exercise the per-line keying *inside* the two
exempt files. So "an exempt file's non-exempt lines still get asserted" is reasoned, not measured.

**Why it matters:** if the keying is wrong in the permissive direction, a future non-compliant
invocation added to `phase06-oracle.sh` or `phase06-incremental-control.sh` lands in the exempt
set and is never asserted over — silently restoring the CR-01 failure mode inside the two files
most likely to gain new `beet` calls.

**Condition that would drive it:** plant an invocation inside `scripts/phase06-oracle.sh` that does
**not** carry the overlay substring, run the D-04 block against that tree, and confirm it lands in
the **asserted** set (and goes red) rather than the exempt set — with the exempt count still 5.

**Urgency:** this is the highest-value single drive left from the whole gap closure, because it
protects the fix for the phase's only Critical finding.

---

## DEF-06-21-07 — the new `quick-health-check.sh` exit-3 arm's heading anchor guard is undriven

**Found during:** plan 06-21, task 2, reading plan 06-17's NOT-DRIVEN register (item N-3).
**Disposition:** residue of `WR-03`, which is `FIXED`. Plan 06-17 nominated this itself as *"the
weakest link in this plan's change and the obvious next drive"*.

The `CONSUMERS_RC -eq 3` arm echoes the audit's CONF-04 lines through a bounded `sed` range and
applies the `📊 6. Summary` anchor guard. The guard was written to the same shape as the `-eq 0`
arm's, which is **pre-existing and was not re-driven** — so it is the only branch protecting a
**cross-file heading contract** on a code path that did not exist before 2026-09-22.

**Why it matters:** if the guard does not fire, renaming or renumbering `📊 6. Summary` in
`check-music-consumers.sh` makes the health entry point print counts scraped from the wrong region
instead of reporting UNKNOWN — a wrong number where a refusal belongs.

**Condition that would drive it:** renumber the heading in a scratch copy of
`check-music-consumers.sh`, point `CONSUMERS_SCRIPT` at it, and confirm the arm reports UNKNOWN
rather than printed counts.

**Urgency:** it needs no estate contact — `CONSUMERS_SCRIPT` exists precisely so this is driveable
from a scratch copy.

---

## DEF-06-21-08 — plan `<verify>` blocks are a systemic defect class in this phase, not incidental

**Found during:** plan 06-21, closing the gap-closure wave (2026-09-22).
**Disposition:** recorded. This is a **planner-side** finding with no code to change.

**All six gap-closure plans found defects in their own plan's `<verify>` blocks — every one.**
06-19 found three distinct shapes in two blocks simultaneously. Two plans introduced a fresh
instance of the class *while fixing it*. Plan 06-21 found two more (see `06-21-SUMMARY.md`),
including an acceptance criterion asserting a string that has never existed in the target file.

The recurring shapes, which is the reusable part:

1. **`grep -q` downstream of a pipe under `set -o pipefail`** — `grep -q` exits on first match,
   the writer takes SIGPIPE, pipefail propagates **141**, and the failure branch fires precisely
   when the file is **correct**. A false-RED generator. 06-17 measured one sitting ~17 % below the
   64 KiB macOS pipe ceiling: it passes today and starts failing as the file grows.
2. **`\$\{…\}` inside a double-quoted bash string** — bash collapses `\$` to `$` and BSD grep reads
   it as an end-of-line anchor mid-alternative. Vacuous on macOS, fine on GNU: a silent platform
   split. A false-GREEN generator; 06-16 found an acceptance criterion never satisfiable on any
   commit because of it.
3. **A bare `'` inside a `bash -c '…'` body** — closes the body, and as a regex alternative matches
   almost anything.
4. **Unbounded `awk` ranges** — check the end delimiter exists *and* that the **start** pattern is
   unique; a recurring start is what makes a range run away.
5. **Case-sensitive greps against FULL-CAPS emphasis** — 06-17 fired a false RED searching for
   `NEVER summed` in a file whose register is `ARE NEVER SUMMED`.
6. **Verifies that grep for a string the script cannot emit** — prefer a derived verdict line.
7. **Unsatisfiable acceptance criteria** — if a criterion names an artifact or a literal string,
   check it exists *before* trying to satisfy it. The trap is that the obvious repair is to write
   the string in, which can silently change content the criterion existed to protect.

**Related, and the same root cause:** plan line citations went stale in **four consecutive plans**
as siblings edited the same files — 06-17's by ~175 lines, 06-19's by 200–300. `grep -n` on anchor
text is the reliable route; a cited line number is not.

**The cure that worked, applied by every plan that hit this:** materialise the text into a **file**
and grep the file, never let a pipeline carry a verdict; then **drive the assertion red** before
trusting it, and confirm an unmutated control still passes. Fix the verify by **strengthening**
what it asserts, never by relaxing it.

**Why it is recorded rather than fixed:** there is no artifact in this repository to change — the
defect is in how plans are written. It belongs in front of whoever plans the next phase.
