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

**⚠ DESCRIPTION CORRECTED 2026-09-22 (round 2, plan 06-27; recorded here by plan 06-29). The
substance, the disposition and the driving condition above are UNCHANGED — only what the run tag
is *said to buy* was wrong.** Two corrections:

1. **The PID is a label, not a namespace, and it is the wrong process's.** `$$` is the *macOS
   workstation's* bash PID, not anything inside the container whose `/tmp` is world-writable; PIDs
   are small, sequential and enumerable, and they recycle. The property that actually protects an
   in-container scratch name is `mktemp`'s **O_EXCL creation**, not the name being unguessable —
   the single threat-model decision plan 06-25 recorded for both sibling instruments
   (`artifacts/06-25-incremental-tempnames.txt` § 4). The oracle's comment now credits the step-1
   probe, which is what genuinely refuses a pre-placed name; the run tag narrows only the TOCTOU
   window between that probe and the step-5 `mkdir`. That was round-2 finding **GC-07**.
2. **The reason the leaf names were not minted here is SCOPE, not a dependency conflict.** An
   earlier reading held that renaming them would invalidate committed proof artifacts. That is
   true of the **directory** `/tmp/p6` — pinned by the WR-07 fence allow-list, the precheck, the
   cleanup assertion and the committed 06-11 artifacts — and **false of the leaves**:
   `artifacts/06-11-oracle-run.txt` still quotes the *pre-06-18* names `/tmp/p6/lib.db` and
   `/tmp/p6/state.pickle`, so plan 06-18 already renamed them once and invalidated nothing.
   Recorded so a future plan that mints them does not inherit a fabricated obstacle.

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

## DEF-06-21-07 — ✅ DRIVEN AND PASSING 2026-09-22 (closed) — the `quick-health-check.sh` exit-3 arm's heading anchor guard

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

**✅ DRIVEN 2026-09-22 by plan 06-26, task 2, commit `33ed08b` — and it PASSES.** The stated
condition was executed exactly as written: a stub whose `📊 6. Summary` heading is renumbered to
`📊 7.`, reached through `CONSUMERS_SCRIPT`, with no estate contact beyond a `/tmp` stub. The arm
reported

```
⚠️ UNKNOWN — the audit exited 3 but its '📊 6. Summary' block was not found
```

and printed **no counts** — a refusal where a wrong number would belong. **Not a new finding:** it
behaves as plan 06-17 designed it. Residue of `WR-03`, which is `FIXED`; this entry is **closed**.
Evidence: `artifacts/06-26-qhc-knobs-and-tail.txt`. Recorded by plan 06-29, which owns this file
for round 2.

**Note for the register:** GC-17's fourth site mattered here. Before plan 06-26 quoted
`bash $CONSUMERS_SCRIPT`, a `CONSUMERS_SCRIPT` value containing a space exited **127** and landed
in the generic ❌ BROKEN arm — so the exit-3 arm, the branch this knob exists to make driveable,
**could not be reached at all**. A knob whose only purpose is to make a branch driveable is
worthless if the knob's own value cannot survive the transport.

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

**⚠ CONFIRMED FOUR MORE TIMES IN ROUND 2**, with new shapes. See `DEF-06-29-07`, which extends
this entry rather than restating it.

---

# Round 2 (2026-09-22) — `DEF-06-29-*`

*Written by plan 06-29, the last plan of gap-closure round 2. Entries 01–07 are residue of rows
that are themselves `FIXED` in `06-DISPOSITIONS-GAP.md`. Entries 08–11 are items round 2 surfaced
that belong to no GC finding and to no other plan; they are here because an item recorded nowhere
is an item nobody owns.*

## DEF-06-29-01 — 23 lines / 24 pipelines of `… | grep -q` under `pipefail` remain across the estate's scripts, FIVE of them inverted

**Found during:** plan 06-22, task 3, inventorying the GC-01 shape repo-wide rather than fixing
two sites and forgetting the rest (2026-09-22).
**Disposition:** residue of `GC-01`, which is `FIXED`. **Inventoried, not swept.**
**Inventory:** `artifacts/06-22-pipefail-141.txt`, with file, line, provenance, size class and
failure direction recorded per site.

**How this differs from `DEF-06-21-08`, which must not be confused with it.** `DEF-06-21-08`
records this shape as a **planner-side** defect in plan `<verify>` blocks — text that is executed
once and thrown away. **This entry is about SHIPPED CODE** in the estate's health scripts, which
runs unattended and whose verdicts an operator acts on. Same mechanism, different blast radius,
different owner.

**The mechanism, measured twice independently on darwin 27.0.0** (plan 06-22 in
`check-beets-config.sh`, plan 06-24 in `phase06-oracle.sh`, different needles and haystacks):
`grep -q` exits on first match, the upstream `printf` takes SIGPIPE and exits **141**, `pipefail`
hands 141 to the pipeline, and the `if` evaluates **false**. Clean at 8/16/32/48/56 KiB;
**141 at 64/96/128 KiB**. It is **position-dependent** — a match near the top is missed, one near
the bottom is found.

**25 of 29 scripts under `scripts/` set `pipefail` for their own shell.** 28 lines / 29 pipelines
carried the shape; 5 were closed by this round (2 by 06-22, 3 by 06-24). **The remainder is 23
lines / 24 pipelines.**

**The five that fail in the DANGEROUS direction** — toward a false green, or toward the
destructive answer. A *positive* assertion failing to 141 is a false RED: noisy and safe. An
**inverted** one — where a grep *match* is the failure case — is a false GREEN:

| site | why it matters |
|---|---|
| `check-jellyfin-transcode.sh:490` | match → `fail`; a 141 reports `/data/transcode` gone when it is present |
| `check-jellyfin-transcode.sh:513` | match → `fail`; **the only remaining site whose input is unbounded** (`docker volume ls -q`, ~1,008 volumes to the ceiling) |
| `check-music-consumers.sh:939` | match → `export_fail`; a 141 reports `fsid=` absent when it is set |
| `spike03-image-headroom.sh:316` / `:317` | match → PROTECT; **a 141 drops a *referenced* image into the reap list** |
| `spike03-image-headroom.sh:408` | match → `fail` |

**Why a sweep was not done inside a gap-closure round.** Three of the affected scripts
(`check-jellyfin-transcode.sh`, `check-music-consumers.sh`, `check-music-freeze.sh`) are folded
into `scripts/quick-health-check.sh`, the estate's single health entry point. Editing the health
path's semantics inside a round whose mandate is *"close these seventeen findings and change
nothing else"* is the wrong trade — it would ship unreviewed changes to the instrument that
reports whether everything else is working. The shape was inventoried with its failure direction
per site so the sweep can be planned rather than improvised.

**Condition that would drive it:** feed each site an input above the 64 KiB pipe buffer with the
needle on the **first** line, and confirm the assertion still fires. `check-jellyfin-transcode.sh:513`
is the one to do first: it is inverted **and** its input is unbounded, so it is the only site where
the threshold can be crossed by the estate growing rather than by a deliberate fixture.

**⚠ HAZARD WORTH NAMING EXPLICITLY, because it is a trap for the next person tidying this file:
`scripts/quick-health-check.sh` carries SIX instances of the shape and they are correct today
ONLY because that file has no local `set` line at all** — measured, `grep -cE '^[[:space:]]*set '`
returns **0**. **Anyone "tightening" it by adding `set -euo pipefail` arms all six at once.** That
correctness is a property of an absent line, not of a control, which is exactly why it is written
down.

**Urgency:** latent and size-dependent. Not urgent today; it becomes urgent silently, which is the
worst property a defect can have. The two most dangerous sites are in the image-reaper, where the
failure direction is *delete something that is in use*.

---

## DEF-06-29-02 — a ninth stale `file:line` citation survives in `quick-health-check.sh`

**Found during:** plan 06-28, task 1, enumerating cross-file references (2026-09-22). Recorded in
that plan's SUMMARY as **NEW-06-28-01**; independently confirmed at HEAD by the orchestrator and
again by plan 06-29.
**Disposition:** residue of `GC-04`, which is `FIXED`.

`scripts/quick-health-check.sh` cites `scripts/check-music-freeze.sh:144` for
`TAGGER_CENSUS_PROMOTED=1`. **Line 144 is an unrelated comment about the criterion-1 row; the
assignment is at `:160`.** Re-measured at HEAD `23b2b82` with `/usr/bin/grep`: the citation sits at
`quick-health-check.sh:27`, and `TAGGER_CENSUS_PROMOTED=1` is at `check-music-freeze.sh:160`.

**Why it was reported rather than fixed.** `quick-health-check.sh` is not in plan 06-28's
`files_modified`; plan 06-26 owned it in the same round, and **three** round-2 plans landed in it
(06-23, 06-26 and, at the tail, 06-26 again). Editing a fourth agent's file to repair a comment is
how a round produces a merge conflict over a non-functional change. Consistent with how 06-26 and
06-27 handled their own out-of-scope discoveries.

**No functional impact:** nothing asserts on the citation.

**Condition that would drive it — and it is cheap:** the replacement anchor is **already
verified**. `TAGGER_CENSUS_PROMOTED=1` returns exactly **1** hit in the target, so the assignment
is its own unique, single-line anchor. Replace `check-music-freeze.sh:144` with a grep instruction
for that token, and re-run `grep -c` in the target to confirm it still resolves.

**Urgency:** cosmetic in isolation, and this project's known plan-failure mode in aggregate —
`DEF-06-21-08` records citations going stale in four consecutive plans, and 06-28 had to re-anchor
nine of them. Fold it into whatever next edits that file.

---

## DEF-06-29-03 — the oracle's three fence copies are protected by a check that FORBIDS the DRY fix

**Found during:** plan 06-24, running its own verification (2026-09-22).
**Disposition:** residue of `GC-02`, which is `FIXED`. **A latent conflict in a committed
acceptance check, not a defect in shipped code.**

Plan 06-24's verification asserts that the narrow `[!A-Za-z0-9._-]*` fence predicate appears at
**five or more** sites, while the plan's own comment beside it says *"four sites"* —
self-contradicting on its face. The shipped resolution is **three literal fence copies** (two
outer + three inner = 5 sites), with the drift risk closed by an **executed byte-equality case**
asserting the two stamp copies identical and each destructive program asserted to begin with the
fence text the self-test drove.

**The trap:** sharing one fence text between the two stamp programs — which would make drift
**structurally impossible**, strictly stronger than testing for it — yields **four** sites and
**fails that check**. So a future plan that legitimately de-duplicates these fences will trip an
acceptance criterion written to protect them.

**Why it is recorded rather than fixed:** the count is a *proxy* for "the narrow class is
everywhere it needs to be". Rewriting a committed plan's verification after the fact is not this
plan's to do, and silently relaxing the number would remove the only thing standing between a
future edit and a bare glob adjacent to an `rm -rf`.

**Condition that would drive it:** any plan that aliases `STAMP_RM_FENCE_SH` to
`STAMP_WRITE_FENCE_SH` (or otherwise shares the text). It must replace the site-count check with a
predicate over the property actually wanted — *every* `rm`-adjacent fence resolves to the narrow
class — rather than over the number of textual copies.

**Urgency:** none today; it fires only when someone does the right thing. That is precisely the
kind of trap worth writing down, because it punishes an improvement and the punishment looks like
a regression.

---

## DEF-06-29-04 — the LIVE arm-1 config dump has never been sized, so whether GC-01 was firing against the estate is unknown

**Found during:** plan 06-22, task 1, and named in that plan's NOT-DRIVEN register (2026-09-22).
**Disposition:** residue of `GC-01`, which is `FIXED`. **The mechanism is gone either way** — this
is about the historical record, not about current exposure.

`GC-01` states the mechanism is proven but that *"whether it fires against the live estate today
is unconfirmed and is size-dependent"*. `$raw` is the whole arm-1 server-committed config dump — a
multi-line YAML/JSON dump that grows with every beets release and every plugin enabled. Plan 06-22
**removed the pipeline**, so no size can now produce a false negative. It did **not** measure the
dump, because the plan made no estate contact by design: reaching it needs ssh to LXC 100 and a
`docker exec` into `beets-flask`.

**Why this is worth a line at all:** the review's brief recorded one instance of this shape
measured at **~17 % below the 64 KiB ceiling**. If the live dump is in that band, GC-01 was a
BLOCKER about to start firing rather than a latent one — and that is a different sentence to write
in the phase's history than the one currently written.

**Condition that would drive it:** on the next live run of `scripts/check-beets-config.sh`, record
`wc -c` of `$WORKDIR/arm1.dump`. **That number is the margin, and it has never been written down.**

**Urgency:** none operationally — the fix does not depend on the answer. Record it the next time
someone is in there, and do not make a trip for it.

---

## DEF-06-29-05 — round 2's undriven residue closes on Phase 7's live pilot and on nothing else

**Found during:** plans 06-24, 06-25, 06-27, reading their own NOT-DRIVEN registers (2026-09-22).
**Disposition:** residue of `GC-02`, `GC-05`, `GC-08` and `GC-15`, all of which are `FIXED`.
**Also carried by ROADMAP Phase 7 entry criterion E12.**

Four items, grouped because they share one driving condition — a real `--run`, which **imports**,
and importing is out of scope for a paper phase:

1. **The oracle's three destructive programs were never executed — deliberately.** What was driven
   is the fence *text* (23 self-test cases, refusals and accepting partners, with a bare-glob
   mutant build going red on 11 of 134), plus an assertion that each program literally *begins
   with* that text. The step from "the fence refuses" to "the program refuses" is sound but
   **structural**; no `rm` has been observed declining to run. **The reason for not driving it is
   the finding itself:** if the fence regressed, a case driving `SCRATCH=/tmp/p6-x/../etc` against
   `CLEANUP_PROG` would become `rm -rf /tmp/p6-x/../../../home`. A self-test must not be able to
   destroy the machine it is proving safe.
2. **The fence predicate has never run under the container's `dash`.** All cases were driven with
   the macOS `/bin/sh` (bash in sh-compat mode). The text is deliberately POSIX and uses no
   bash-only construct, and `phase06-incremental-control.sh` has carried the same shape against
   that dash for several plans — **corroboration, not proof**.
3. **GC-15's two `dex_cmd sha256sum` sites as SENT.** What was driven is the constructed command
   string and the argv a bash far side builds from it; the container never saw it. A `REAL_LIB_DB`
   carrying a space is **predicted** — UNKNOWN + exit 3 at `[ -n "$LIB_SHA_BEFORE" ]`, because
   `awk`'s `$2` cannot key a whitespace path — and predicted is not measured.
4. **GC-05's live vacuity arms.** The verdict change (vacuous D-15 / D-13 now exit **3 UNKNOWN**
   rather than **1 RED**) was driven through `run_assert` over synthetic fixtures including the
   counters. A real DJ-less or compilation-less **sample** has not been through a live run.

**Condition that would drive all four:** the next real `phase06-oracle.sh --run`, which Phase 7's
pilot import is the first thing to perform. Confirm: both `layer3.before`/`layer3.after` parse and
both `awk` keys match; the fence refuses end to end under the container's dash; and no
`/tmp/p6-mf.*` or `/tmp/p6-taghist.*` survives the run.

**Urgency:** every one of these fails **closed** — a wrong construction refuses a run that would
otherwise proceed. None can produce a false green. That is why they are residue rather than
findings, and why they wait for the pilot rather than justifying a run of their own.

---

## DEF-06-29-06 — thirteen cross-file `file:line` citations resolve TODAY, which is the property that expires

**Found during:** plan 06-28, task 1 (2026-09-22).
**Disposition:** residue of `GC-04`, which is `FIXED`. **Recorded deliberately rather than
silently passed over.**

Of the 23 cross-file references plan 06-28 enumerated, **9 were stale and repaired with proven
anchors; 13 resolve correctly and were left alone**, each judgement recorded in
`artifacts/06-28-citations-and-counts.txt`. They are line numbers. They **will** rot again — this
round alone moved the oracle's cited positions by ~300 lines beyond what the plan predicted, and
moved one `beets.md` register row from *correct at planning* to *rotted at execution*.

**The shape that makes this survive review:** one of the repaired nine was a cited **pair**
(`CLAUDE.md:152` and `PROJECT.md:187`) where **one half still worked**. A spot-check of either
citation had a 50 % chance of clearing a half-rotted reference. **Checking one of a cited pair does
not clear the pair.**

**Condition that would drive it:** re-resolve all thirteen at any later commit and count how many
still land on their claimed content. Better: convert them to greppable anchors using 06-28's
method — `grep -c` the candidate anchor **in the target** for uniqueness and the single-line
property **before** writing it into the citing file.

**Urgency:** low individually, systemic in aggregate. The argument for anchoring is that a stale
citation is checked once and then trusted, and this phase has now produced that failure five
separate times (`DEF-06-21-08`, GC-04, `DEF-06-29-02`, and both halves of the pair above).

---

## DEF-06-29-07 — SEVEN wrong-premise `<verify>` checks across eight plans, plus a template defect five agents hit independently

**Found during:** every plan of round 2 (2026-09-22).
**Disposition:** recorded. This is a **planner-side** finding with no code to change. It
**extends** `DEF-06-21-08` rather than restating it — that entry catalogued round 1's six shapes;
these are seven **new** shapes, from plans written after round 1's lesson was recorded.

**That is the finding: the shapes keep being new.** Round 1 concluded with a catalogue and a cure;
round 2's plans were written with that catalogue available and produced seven fresh instances
anyway. A catalogue of known shapes does not generalise to the class.

**The seven, each reported by its executing plan rather than absorbed:**

1. **A wrong grep method** (06-22) — the plan's comment filter classified `quick-health-check.sh`
   as a `pipefail` setter, because three of its mentions sit on **executable** lines inside remote
   command strings. Fixed by anchoring to `^[[:space:]]*set `. *Method wrong, conclusion right.*
2. **A wrong "next free letter"** (06-23) — the plan said "the next free letter after L"; measured,
   **A–O are all taken**, because an earlier notice used M, N and O out of alphabetical order.
   Following the plan literally would have produced a second condition M. Used **P**, and recorded
   the grep that finds the next free letter.
3. **A non-existent anchor section** (06-24) — the plan said to put new cases "beside the existing
   WR-07 fence cases". **There were none.** 111 self-test cases and not one touched either fence
   layer; the 06-18 fence shipped with zero executed coverage. **That is why GC-02 survived** —
   nothing could have caught it.
4. **A self-contradicting threshold** (06-24) — comment says "four sites", test says "5 or more",
   and the DRY fix yields four. See `DEF-06-29-03`.
5. **An expected count its own fix invalidates** (06-23) — condition P's plan-required message is
   an `echo` carrying a literal `beet`-invocation token, so it survives the comment strip and lands
   in both the raw and the comment-stripped count the plan pinned. **Reported as a deviation, not
   absorbed**, with containment measured (35 → 36 matches, the +1 being that echo alone) and both
   pins shown unmoved.
6. **A `-F` absence test that substring-matches its own correct fix** (06-26) —
   `grep -cF 'cd $D04_REPO_ROOT'` expects 0, but `-F` matches a **substring** and that token is a
   **prefix** of the corrected `cd $D04_REPO_ROOT_Q`. Measured on the correctly fixed file, the
   plan's own method returns **1 for all four sites**. **The correct fix fails the check.** Fixed
   by testing the token with its trailing separator.
7. **Twice: a check that cannot distinguish a claim from its retraction** (06-27, 06-28) —
   `grep -ci 'removes the predictability'` must be 0, and `grep -cF '2166, 2179, 2313'` must be 0.
   In both cases the correct prose **quotes the old claim in order to disown it**, which fails the
   check. Both were satisfied **honestly** — the sentence reworded to describe the old claim
   without quoting it; the stale positions moved into the audit artifact — never worked around.

**And the template defect, which is separate and is not the executors' fault.** Every round-2
plan's `<verify>` block opens with:

```
cd /Users/damian/Development/damianflynn/selfhost-stacks
```

That is the **MAIN CHECKOUT**, which does not carry a worktree agent's edits. Obeying it literally
measures the **unmodified** file and reports a green describing nothing — a false GREEN generated
by the plan template itself. **Five agents hit this independently** (06-24, 06-25, 06-26, 06-27,
06-28) and all five correctly refused, resolving the repo root from
`git rev-parse --show-toplevel` instead. **The template is the defect, not the executors.**

**Condition that would drive it — for the template half, which is the fixable one:** emit
`cd "$(git rev-parse --show-toplevel)"` in generated `<verify>` blocks instead of a hard-coded
absolute path, and confirm a worktree-executed plan measures its own edits. That single change
removes the defect for every future plan; the seven shapes above cannot be fixed that way, which
is why they are catalogued rather than repaired.

**Urgency:** planner-side, and in front of whoever plans Phase 7. The cure that worked in both
rounds is unchanged: materialise text into a **file** and grep the file, never let a pipeline carry
a verdict; **drive the assertion red** before trusting it; confirm an unmutated control still
passes; and fix a verify by **strengthening** what it asserts, never by relaxing it.

---

## DEF-06-29-08 — the D-04 no-sentinel arm names a path the block may never have visited

**Found during:** plan 06-26, task 1, driving the GC-17 quoting fix (2026-09-22). Recorded in that
plan's SUMMARY as **NEW-06-26-01**; re-confirmed at HEAD by plan 06-29.
**Disposition:** not a GC finding. **Diagnosis defect; verdict unaffected.**

`scripts/quick-health-check.sh`'s D-04 no-sentinel arm prints:

```
⚠️  UNKNOWN — the D-04 scan produced no sentinel (ssh exit $D04_RC; 3 = no
/mnt/fast/stacks checkout, 4 = 'git grep' failed).
```

while the `cd` above it uses **`$D04_REPO_ROOT`**. Under an override the operator is told a path
that was **never visited** — and is sent to look for a directory that is right there. Confirmed at
HEAD `23b2b82` with `/usr/bin/grep`: the message hard-codes the literal at `:1852`, the `cd` uses
`$D04_REPO_ROOT_Q` at `:1840`.

**Its two siblings get this right** — the drift arm (`:1471`, `$DRIFT_REPO_ROOT`) and the D-03
render arm (`:1638`, `$D03_REPO_ROOT`) each interpolate their own knob. So this is the **same
three-of-four-siblings shape as GC-17** and the **same wrong-diagnosis class as GC-14**, one block
across, in a file where round 2 has just closed both.

**Verdict is unaffected:** the arm sets `EXIT_CODE=1` regardless, so no override can produce green.
It is what the operator is told, not what the script concludes. Visible in
`artifacts/06-26-qhc-knobs-and-tail.txt`'s BEFORE transcript, where the message says
`/mnt/fast/stacks` while the run was pointed at `/tmp/qhc-06-26/probe root with space`.

**Why it was not fixed:** out of scope for 06-26, which was closing three named findings in a file
three plans landed in that round.

**Condition that would drive it:** run with `D04_REPO_ROOT` set to a path that does not exist, and
read the message — it must name the overridden path, not `/mnt/fast/stacks`. Anchor for the fix:
`grep -n "4 = 'git grep' failed"` (1 hit).

**Urgency:** low and cheap. It is a one-token change of the same kind GC-17 and GC-14 just made
four and six times respectively, and leaving it is how a class gets fixed at three of four sites —
which is the defect this round's own subject.

---

## DEF-06-29-09 — three LIVE secrets sit on LXC 100 in an un-rotated file the repo would have committed

**Found during:** round 2, while widening `.gitignore` (2026-09-22). Commit `456ad06`.
**Disposition:** **NOT CLOSED.** The repo-side hole is closed; the secrets are not.
**Outside Phase 6 entirely.** The operator has been told; recorded here so it is not lost.

`stacks/selfhosted/karakeep/.env.pre-pocket` on LXC 100 holds **`MEILI_MASTER_KEY`**,
**`NEXTAUTH_SECRET`** and **`OPENAI_API_KEY`**, and matched **neither** `**/.env` **nor**
`*.env.backup`. **This repository is PUBLIC.** A `git add -A` would have committed three live
secrets.

**What is closed:** commit `456ad06` widened the ignore to `**/.env.*` with `.env.sample` and
`.env.example` re-admitted, and verified that **no tracked file becomes ignored** by the change.
The repo can no longer pick the file up.

**What is NOT closed:** **the file is still on the host and the three keys are not rotated.** An
ignore rule prevents a future accident; it does nothing about a key that may already be
compromised and nothing about the file's continued existence.

**Condition that would close it:** rotate all three keys, then remove or relocate the file. Rotation
is the load-bearing half — if the value ever left the host, ignoring it changes nothing.
Independently: confirm no other `.env.<suffix>` on the estate holds live credentials, since this one
was found by accident rather than by a sweep.

**Urgency:** the highest in this file, and it is **not a Phase 6 item** — which is exactly how an
item like this gets lost between two phases that each correctly decline it. It needs an owner
outside this project's phase sequence.

---

## DEF-06-29-10 — two path-safety violations actually occurred, both of the "hard-coded absolute repo path" class

**Found during:** round 2 waves 1 and 2, by the orchestrator merging them (2026-09-22).
**Disposition:** recorded. Both were repaired at merge time; the **class** is what is carried.

Two agents wrote outside their own worktree:

1. **Plan 06-22 wrote its SUMMARY into the main checkout as well as its worktree**, which
   **blocked the wave-1 merge** until it was cleared.
2. **An unrelated `.gitignore` edit was left in the main checkout** by a wave-2 agent.

Both are the same class: **resolving an output path from a hard-coded absolute repo path instead
of `git rev-parse --show-toplevel`.** It is the mirror image of `DEF-06-29-07`'s template defect —
there, a hard-coded path made an agent *read* the wrong file and report a false green; here it
made an agent *write* to the wrong tree. **One root cause, two failure directions, and the write
direction is the one that costs a merge.**

**Condition that would drive it:** none needed — it has fired twice. The preventive check is
mechanical: before any `Write`/`Edit` to an absolute path inside a worktree, assert the path is
contained in `git rev-parse --show-toplevel` (with a boundary check, not a glob prefix — a prefix
match admits a sibling worktree whose name extends the root's).

**Urgency:** it costs wall-clock at merge time and, in the worse case, silently splits a plan's
output across two trees so that neither is complete. It should be fixed in the same place as
`DEF-06-29-07`'s template half, because it is the same variable.

---

## DEF-06-29-11 — the deployed host is at a pre-Phase-6 commit, and its symptoms LOOK like phase fallout

**Found during:** plans 06-23 and 06-26, running live checks (2026-09-22).
**Disposition:** recorded as a **deliberate non-finding**, restated here because it will be
misread. Also `06-DISPOSITIONS-GAP.md` § Deliberate non-findings items 2 and 8.

`/mnt/fast/stacks` on LXC 100 is at **`c67d497`**, pre-Phase-6. **Nothing in this phase has been
pushed.** Three consequences that present as defects and are not:

1. **The D-04 block reports UNKNOWN on the live estate.** The executable count there is genuinely
   0, so the vacuity guard correctly refuses.
2. **The live consumers exit-3 arm cannot be reached**, because the host's
   `check-music-consumers.sh` is a pre-Phase-6 copy with **zero** `exit 3` occurrences. That is
   why the live consumers arm is green **while the new tail correctly says CONF-04 is open** — the
   two are not in conflict, and `CONSUMERS_SCRIPT` exists precisely so the arm is driveable from a
   scratch copy without waiting for a deploy.
3. **`check-music-freeze.sh` is ❌ in every run** —
   `interpolated-host-path inventory MOVED: expected=12, found=13`. The host's own deployed copy,
   untouched by any plan in this phase.

**All three clear on the same act and on nothing else:** the operator's `git push` plus a host
`git pull --ff-only` — which the vendored-drift block has been waiting on since round 1.

**Condition that would drive it:** push and pull, then re-run `scripts/quick-health-check.sh` and
confirm items 1 and 3 clear while item 2 is *replaced* by the intended CONF-04-pending ⚠️, which
stays until Phase 7 entry criterion **E6** discharges CONF-04. **Do not tune that one out.**

**Urgency:** operator's call, and it is a decision rather than a task — pushing makes the health
entry point exit non-zero on the consumers block by design. Recorded so that a future reader
seeing three reds after a deploy does not attribute them to round 2's changes.
