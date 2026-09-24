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

---

## DEF-06-34-01 — REFUSED: the best-effort `/tmp/p6-mf.*` sweep the review floats under R3-09

**Found during:** plan 06-32, closing R3-09 (2026-09-23).
**Disposition:** **a deliberate REFUSAL, not an omission.** Recorded in band at the manifest trap
and in `artifacts/06-32-incremental-trap-fences.txt`, and carried here so the next round does not
re-open it as an obvious gap.

`06-REVIEW-GAP2.md` § R3-09 closes with: *"and consider a best-effort sweep of `/tmp/p6-mf.*` older
than a day in the same program, gated on the same prefix."* Plan 06-32 widened both traps — which
is the finding's substantive half — and **declined the sweep**.

**The reason, stated so it can be disagreed with rather than merely obeyed.** A prefix-gated
`rm -rf` over names *the current run did not mint* is a materially wider destructive reach than an
**INFO** litter finding justifies. The `/tmp` it would sweep is the `beets-flask` container's, which
the file's own header records as mode **1777**, and on which — measured by plan 06-25 — a redis, an
HTTP server and five rq workers all run as **uid 568, the same uid the instrument execs as**. A
sweep would therefore be one instrument deleting paths belonging to processes it does not own, on
an age heuristic, to tidy up after a timeout. The trap widening already shrinks the window that
produces the litter; the litter itself is bounded, named by prefix, and removable by hand.

**Condition under which it should be revisited:** evidence that the litter actually accumulates —
i.e. a live `--arm a`/`--arm b` pair (or several) under a short `REMOTE_TIMEOUT` that leaves
`/tmp/p6-mf.*` directories behind in numbers. If that happens, the right shape is almost certainly
**not** a sweep inside the instrument but a cleanup the *operator* runs with the prefix in front of
them. Do not implement it because a reader assumed R3-09 was closed only half way.

**Urgency:** low. The finding's substantive half is FIXED (`928f9c2`); this is the discarded
optional half.

---

## DEF-06-34-02 — REFUSED ×2: the vacuous third conjunct (R3-08) and wiring `assert_beet_invocation_contract` live (R3-07)

**Found during:** plan 06-33, closing R3-08 and R3-07 (2026-09-23).
**Disposition:** **two deliberate REFUSALS**, both recorded in band at their sites — the first at
case 6's gate, the second immediately above the function under the greppable opening
`IF THIS FUNCTION IS EVER CALLED LIVE`.

**(a) R3-08's second option was refused.** The review offers two fixes: drop `expect_reds` from case
6, or keep it and add `[[ $ARM1_FAILS -eq $expect_reds ]]` as a **third conjunct** so banner and
gate cannot disagree. Plan 06-33 took the first. The second looks symmetric and is not: when the two
existing conjuncts hold — real violations 0, synthetic rejected once — the summed counter is
**necessarily 1**, so the third conjunct is *implied by the other two* and **could never
independently fail**. Adding it to close a finding about honest announcements would have traded one
defect class for the worse one this phase has removed three times (CR-01, GC-03, GC-05): a vacuous
assertion that reads as coverage.

**(b) R3-07's live wiring was refused, and so was re-polarising its arms.** The review notes that a
live run currently never checks the `-l` + `-c` source contract at all, and that the function's arm
polarity is inverted with respect to `FAILURES` — a *correct* run would increment it and a *blind*
checker would increment nothing — the moment anyone wires it live. Plan 06-33 **did not wire it**.
Wiring is a behaviour change to the live checker, outside a hardening round's brief, and doing it in
the same breath as a claim correction would have buried it. What was done instead is to record the
**precondition at the site**, naming what must change *in the same commit as any wiring*, why it is
harmless under `--self-test`, and why someone will be tempted.

**Condition under which each should be revisited:** (a) never as stated — if case 6's announcement
drifts again, the answer is another gated value, not an implied conjunct. (b) when someone decides
the live checker *should* assert the D-04 source contract, which is a real gap and a reasonable
thing to want. That work must carry the arm re-polarisation in the same commit; the in-band note
exists so it cannot be missed.

**Urgency:** (a) none — refused on principle. (b) low, but genuine: this is the one place round 3
identified a live check that does not exist and chose not to build.

---

## DEF-06-34-03 — the raw exit-code-notice count in `quick-health-check.sh` is deliberately UNPINNED

**Found during:** plan 06-30, closing R3-05 (2026-09-23).
**Disposition:** a deliberate omission with a recipe in its place. Recorded because the next author
of a notice will look for a baseline and must find the reason, not a number.

R3-05's subject is that the thirteenth notice's measured counts (`headers 12 -> 13`, `raw 15 -> 16`,
"a constant delta of three") were **invalidated later in the same round** by plan 06-26's GC-09 tail
repair — a line saying a notice was deliberately *not* added, which in saying so added a raw match.
Measured at round 3's base: headers **13**, raw **17**, delta **four**. This was the **third** drift
of these two numbers.

**The review offered `raw 15 -> 17` and the drop was taken instead.** Re-pinning a number that has
drifted three times sets up the fourth drift. The file now states that the **header count is the
durable one** and the raw count is **deliberately unpinned**, and carries both recipes instead:

```
/usr/bin/grep -c '^# ⚠️  EXIT-CODE BEHAVIOUR CHANGE[D]' scripts/quick-health-check.sh   # headers
/usr/bin/grep -c 'EXIT-CODE BEHAVIOUR CHANGE[D]'        scripts/quick-health-check.sh   # raw
```

**The bracketed final letter is load-bearing and must not be "simplified" away.** `CHANGE[D]` is a
valid pattern that matches every real occurrence, while the recipe lines are **not themselves
occurrences** of the string they measure. The proof it works: the raw count stayed **17 → 17** across
the commit that added these two lines.

**⚠️ Three earlier instances of the withdrawn delta sentence were deliberately LEFT UNTOUCHED**, and
are labelled in band as dated historical records. Each was accurate as of its own edit and none was
re-measured. **Do not "correct" them** — doing so would turn three accurate statements into three
wrong ones, and is the single most likely way a future reader damages this file while trying to
help.

**Condition that would drive it:** none; there is nothing to drive. The item exists so the recipe is
found instead of a stale baseline.

**Urgency:** none. It is a standing instruction, not a task.

---

## DEF-06-34-04 — the oracle's layer-3 block is UNDRIVEN: R3-03 and R3-04 are proven offline only

**Found during:** plan 06-31, closing R3-03 and R3-04 (2026-09-23). Also
`06-DISPOSITIONS-GAP2.md` § What was driven and what was not, item 1.
**Disposition:** residue attached to two rows that are themselves FIXED. It is **not** a downgrade
of the disposition and must not be read as one.

The layer-3 block in `scripts/phase06-oracle.sh` — the assertion whose whole job is to prove `-l`
kept the real `library.db` closed — is reachable **only from a live `--run`**, which this phase does
not perform. Both round-3 fixes to it are therefore proven by an **offline parse drive and static
reading**, not by a live run:

- **R3-03** (the whitespace-tolerant `sha256sum` parser): driven against synthetic `sha256sum`
  output on the workstation's own `awk`, which *is* the real consumer — the awk reads local files.
  Six probes, including the two properties the fix must not break. What has never happened is a real
  `docker exec … sha256sum` returning a line this parser then keyed.
- **R3-04** (the two AFTER emptiness guards): driven as detached copies of both shapes with both
  controls. The guard changes the verdict on exactly one input. What has never happened is a live
  run producing a short or absent second `sha256sum` line.

Separately, **`scripts/quick-health-check.sh` was not executed at all** during round 3 — not by the
review, not by plan 06-30. Its five reshaped remote sites (R3-01) are asserted by **capture** (a
command string produced by `echo`, never sent) and by word-split trace. The defaults are unchanged
in every case and all five knobs are additive and force `EXIT_CODE=1` when non-default, which bounds
the exposure.

**Condition that would drive it:** the live pilot. A real `--run` exercises the layer-3 block on
both sides; a deploy plus a real `quick-health-check.sh` run exercises the five remote sites. This
attaches to the **existing** Phase 7 entry criterion **E12**, which already carries round 2's
undriven-until-the-pilot residue — no new criterion is added.

**Urgency:** low, and it is the ordinary state of this instrument rather than a defect. Recorded so
that "R3-03 and R3-04 are FIXED" is not read as "the layer-3 block has been exercised".

---

## DEF-06-34-05 — `self_test_fences`' `*"rm "*` token test is weaker than a destructive-program check, and the cases were deliberately not widened

**Found during:** plan 06-31, closing R3-06 (2026-09-23).
**Disposition:** a decision recorded, not a gap left open. The prose was narrowed; the cases were
not widened, and **that choice is the item**.

R3-06's substance is that the comment named three properties (no `rm`, no `touch`, no redirection
into a path) while the three cases assert **one** — absence of the two-character token `rm ` — for
three different fence strings. The prose is now narrowed to exactly what is executed, with the gap
written out: `touch` unasserted; redirection unasserted, with the `>&2` point resolved under both
readings.

**The cases were deliberately not widened**, and the bound that makes that defensible is stated
rather than assumed: the fence texts are **three short literals under version control**, and the
byte-identity case between the two stamp fences turns silent drift in them into a red case. The
residual weakness is real and narrow — a tab-separated or newline-terminated `rm` would slip past a
`*"rm "*` test.

**A wider reason the cases stay as they are, kept from round 2:** the oracle's three destructive
programs are **never executed**, not even on paths the fence should refuse, because a fence
regression would turn the self-test itself into `rm -rf /tmp/p6-x/../../../home`. That is
`06-DISPOSITIONS-GAP.md` § Deliberate non-findings item 5, carried as `DEF-06-29-05`; this entry
does not duplicate it, it records why the *token test* specifically was left alone.

**Condition that would drive it:** widening the cases to `*rm*` / `*touch*` / redirection, with the
`>&2` occurrences accounted for — worth doing only if the fence texts stop being three short
literals.

**Urgency:** low. **Do not read the narrower sentence as a weakening**; the code is unchanged and
the assertion is exactly as strong as it always was.

---

## DEF-06-34-06 — the `SIGKILL` residual survives on both in-container traps

**Found during:** plan 06-32, closing R3-09 (2026-09-23).
**Disposition:** an acknowledged, unclosable residual. Stated in band beside both traps rather than
claimed away.

Both traps in `scripts/phase06-incremental-control.sh` now carry `INT TERM HUP` alongside `EXIT`,
which covers the routine case: the programs are `sh -s` under `timeout $REMOTE_TIMEOUT docker exec`,
and a bound expiry on a manifest over a large tree is expected rather than exotic. **The widening
shrinks the window; it does not close it.** `SIGKILL` cannot be trapped, so a hard kill — `timeout
-k`, a container stop, an OOM kill — still leaves the minted directory behind.

That residue is what GC-08's own comment names as the worse case: *"a MINTED leftover is worse
litter than a fixed one, because nobody knows its name."* The fixed names at least self-limited to
three; minted ones accumulate one per killed run, in a `/tmp` the same header records as mode 1777.
The refused sweep in `DEF-06-34-01` is the obvious response and was refused for reasons that stand.

**Neither trap has been observed firing inside the container.** R3-09 is the register's single
`FIXED (undriven)` row for exactly this reason: the `SIGTERM` behaviour is static reasoning about
POSIX `sh` on both sides — the review says so of its finding, and plan 06-32 says so of its fix.
What *was* proven locally is that both program texts parse as POSIX `sh` (`sh -n` rc 0 over both
extracted heredoc bodies, 65 and 31 lines — the gate `bash -n` cannot give, since it parses
heredocs as data).

**Condition that would drive it:** a live `--arm a` / `--arm b` pair under a deliberately short
`REMOTE_TIMEOUT`, checking the container's `/tmp` afterwards for surviving `p6-mf` and `p6-taghist`
names. Attaches to Phase 7 entry criterion **E12** alongside `DEF-06-34-04`.

**Urgency:** low — it is litter in a container `/tmp`, not a correctness defect. Recorded so that
"the traps were widened" is not read as "the leak is closed".

---

## DEF-06-39-01 — round 4's review reused round 1's `WR-*`/`IN-*` ID namespace; a round 5 must be given a fresh one BEFORE it is written

**Found during:** plan 06-39, writing round 4's disposition register (2026-09-23), after all four fix
plans had independently built the same alias table.
**Disposition:** a **form defect in the review**, recorded in band rather than fixed silently — the
findings themselves stand exactly as written. Not a downgrade of anything.

`06-REVIEW-GAP3.md` numbers its findings `WR-01 … WR-06` and `IN-01 … IN-04`. **That is round 1's
namespace**, and round 1's IDs are already cited **in band in all four reviewed scripts**. Measured
at HEAD with `/usr/bin/grep -cF`, for the IDs round 4 reuses: `quick-health-check.sh` carries
`WR-01` ×7, `WR-02` ×1, `WR-03` ×5, `WR-05` ×2; `phase06-oracle.sh` carries `WR-01` ×4, `WR-02` ×2,
`WR-06` ×6; `check-beets-config.sh` carries `WR-04` ×2, `IN-01` ×1, `IN-03` ×1;
`phase06-incremental-control.sh` carries `IN-02` ×1. At the review's own `diff_base` `fff070a` —
i.e. before round 4 touched anything — `/usr/bin/grep -coE 'WR-0[1-9]|IN-0[1-9]'` returns
**35 / 28 / 5 / 4** across the four files, **72** pre-existing citations in that namespace.

None of them has anything to do with round 4. `WR-01` in `quick-health-check.sh` is the 2026-09-14
`extended.conf` destructive-switches finding; `WR-06` in `phase06-oracle.sh` is the CONF-04
write-side report finding. **A grep for a round-4 finding ID returns round 1's text, in exactly the
files where the citation matters most.**

**What was done instead of renaming the review:** all four fix plans wrote **`R4-01 … R4-10`** in
band and in every verify block, each summary carries its slice of the alias table, and the full
mapping — with these counts and the recipe to re-derive them — is in
`06-DISPOSITIONS-GAP3.md` under **THE ID MAPPING TABLE**, with a pointer in
`06-REVIEW-GAP3.md`'s wiring block so a reader following a `WR-` citation meets it first.

**The rule this establishes:** *a review's ID namespace must be unique per round, and must be chosen
before the review is written.* These IDs become permanent in-band citations in the reviewed files; a
namespace collision makes every grep for a finding non-discriminating precisely where it is most
needed. Round 3 got this right with `R3-*`.

**Condition under which it should be revisited:** immediately, and only in one direction — **if a
round 5 is commissioned, give it `R5-*` up front.** Do not retro-rename `06-REVIEW-GAP3.md`: it is a
dated record, ten files in this phase cite round 1's `WR-*`, and renaming a shipped review is how
round 2's GC-15/GC-17 label crossing happened.

**Urgency:** low as a defect, **immediate as a precondition** on any future review in this phase.

---

## DEF-06-39-02 — REFUSED ×3: no cleanup `trap` on `phase06-oracle.sh` (R4-10), `ST_PLANNED_CASES=7` excluded from the count audit, and the four layer-3 copies not hoisted

**Found during:** plans 06-36 and 06-38, closing R4-10, R4-05 and R4-06 (2026-09-23).
**Disposition:** **three deliberate REFUSALS**, each recorded in band at its site and carried here so
the next round does not re-open them as obvious gaps. A refusal nobody wrote down reads as an
oversight.

**(a) No cleanup `trap` was added to `scripts/phase06-oracle.sh` under R4-10.** The finding is that
R3-04's two new `exit 3` arms skip step 12's `rm -rf` (container scratch) and `rm -f` (LXC stamp).
The obvious fix is a cleanup trap. Plan 06-36 refused it and closed the finding as a **claim
correction** instead — grading the class exactly as the review graded it: *pre-existing*, shared with
the two `exit 3` arms two lines above, and *"leaving state behind on a could-not-look is arguably the
right call for a forensic instrument."* **The file has no `trap` anywhere, by design** —
`/usr/bin/grep -c '^[[:space:]]*trap '` returns **0** before and after — and a cleanup trap would fire
on **every** forensic `exit 3` arm, destroying precisely the evidence those arms exist to preserve.
What was done instead: an in-band note at the two guards naming both leftovers (`$SCRATCH`,
`$STAMP_REMOTE`) and **citing the operator clean-up command by anchor** — the step-1 precheck's
`'nonempty '*` refusal arm — rather than duplicating it, because two copies of a destructive command
line in one file is how GC-02's fences drifted apart in this very file.

**(b) `ST_PLANNED_CASES=7` in `scripts/check-beets-config.sh` was EXCLUDED BY NAME from plan 06-38's
count audit and was not touched.** Round 4's own *What I checked and found clean* section verified it
unconditional (six `run_case` calls plus the manual case 6), and it is **not a prose claim** — it is
a gated pin over an unconditionally executed set, the one number in that file that is *supposed* to
be a number. "Fixing" it in a sweep about self-referential counts would have broken a working guard.
It is recorded as an EXCLUDED row in the audit with that reason.

**(c) The four live layer-3 `awk` consumers in `phase06-oracle.sh` were NOT hoisted into one shared
variable** when R4-06 pinned them and R4-09 changed them. Four copies of one parser is exactly the
duplication a reader will want to DRY. It is refused under the standing `DEF-06-29-03`: the oracle's
fence-copy protection **forbids** that fix, and R4-06's identity case now pins the driven text to the
four shipped copies, so a divergence is caught rather than prevented.

**Condition under which each should be revisited:** (a) if the oracle ever grows a cleanup path, it
must be **arm-selective** — never a blanket `trap`, and never one that runs on an `exit 3`; (b) if a
fourth case group is ever added to the checker, the pin moves with it, which is the maintenance it
already advertises; (c) see `DEF-06-29-03`, which owns the question.

**Urgency:** none for (a) and (c) — refused on principle. Low for (b) — it is a correct guard being
left alone.

---

## DEF-06-39-03 — the oracle's announced-case base is ENVIRONMENT-DEPENDENT, and a re-measure is valid only in the named reference environment

**Found during:** plan 06-36, closing R4-02 (2026-09-23).
**Disposition:** a residual attached to a FIXED row. The gate is correct; the **procedure for
re-measuring it** is the fragile part, and it is written down here as well as in band.

R4-02's fix makes the base skip-aware: `ST_PLANNED_CASES` counts the **unconditional** cases, and
each of the three environment-conditional arms **decrements it at its own site**, beside the `warn`
that reports its skip. A deliberate skip therefore adjusts the announcement; a **dropped section**
adjusts nothing and still fires the gate. Both directions were driven — dropping `self_test_fences`
still exits 1 (117 vs 140), and deleting one `st_case` from an unconditional section still exits 1
(139 vs 140).

**The base is still a typed number, and it is only valid in one environment.** That environment is
named in band beside the constant and is repeated here because a number in a file is read far more
often than the paragraph beside it: **macOS 27.0 (darwin), non-root (uid 501), `python3` PRESENT,
bash, BSD grep at `/usr/bin/grep`, BWK awk.** Re-measured by ablation in that environment, the base
is **140** — not the **134** recorded in `06-REVIEW-GAP3.md`, the 06-36 plan,
`06-DISPOSITIONS-GAP2.md` and `06-REVIEW-GAP2.md`, all of which predate the six cases R4-06 added.
Per-arm deltas are **1** (root, mode-000 fixture), **2** (no `python3`), **4** (root,
present-but-unreadable fixture), and they are **additive**, which is the property that makes three
independent decrements correct.

**The failure mode this prevents, stated because it already happened once:** re-pinning the base from
a machine that is *not* the reference environment bakes that machine's skips into the constant, and
the pin then fails on every machine that does not share them. An operator hitting round 3's false red
on a `python3`-less box would have re-pinned to 132 and broken every box that has `python3`.

**Two things are NOT proven and are named rather than left silent:** the root and `python3`-absent
conditions were **ablated on scratch copies**, not genuinely entered — nothing ran as uid 0 and the
interpreter was never removed, so *that the skip branch self-adjusts* is proven while *that a real
root run has no other behavioural difference* is not. And **a fourth environment-conditional skip
would not be detected**: if one is added and its author forgets the decrement, the gate fires with
the corrected three-cause message — which points at the right question — but nothing detects the
omission itself. The verify's `-ge 3` is a **floor, not a census**.

**Condition under which it should be revisited:** whenever a case or a section is added or removed
(the pin's own advertised maintenance), and immediately if a **fourth** environment-conditional skip
is introduced — at which point the right shape is probably to count the announcement rather than type
it.

**Urgency:** low. The instrument is green and honest today; this entry exists so the next re-measure
is taken in the right place.

---

## DEF-06-39-04 — the container-side signal behaviour is STILL UNOBSERVED inside `beets-flask`, on both the SIGTERM and the new SIGPIPE path

**Found during:** plan 06-37, closing R4-03 and R4-04 (2026-09-23).
**Disposition:** residue attached to one FIXED row (R4-03) and the register's single **FIXED
(undriven)** row (R4-04). Recorded in band as a graded three-line register beside the traps, not
claimed away.

R4-03 is closed and **driven**: both in-container programs now carry a named cleanup function, a
separate `EXIT` trap, and four handlers (`INT`, `TERM`, `HUP`, `PIPE`) that clean, `trap - SIG`, then
`kill -SIG $$`. Under `/bin/dash`, pre-fix TERM/INT/HUP gave wait status **0** with the program
running past the signal; post-fix they give **143 / 130 / 129** and it does not.

**What is not observed is the DELIVERY, and it is graded rather than asserted:**

| Path | Grade | Why |
|---|---|---|
| `timeout` → SIGTERM → the in-container `sh -s` | **NOT ESTABLISHED** | `timeout` signals the `docker exec` **client on LXC 100**; `docker exec` is not known to forward signals to the exec'd process. If that holds here the `TERM` arm never fires for these programs at all. Untested — this phase makes **no estate contact** |
| client death → stream teardown → `EPIPE`/`SIGPIPE` on the next stdout write | **BELIEVED, at the same static grade — explicitly NOT an upgrade** | The reason `PIPE` is now in the list. Pre-fix PIPE left the scratch directory **PRESENT** (the leak); post-fix it is gone |
| `SIGKILL` | **UNCLOSABLE RESIDUAL** | Untrappable. Owned by `DEF-06-34-06`; **not duplicated here** |

**The local `dash` drive proves the HANDLER SHAPE, not the DELIVERY.** It shows that *if* a signal
arrives, the pre-fix shape absorbs it and the post-fix shape dies from it. It says nothing about
which signal the container transport actually delivers — which is the whole of R4-04, and why round 3
naming the SIGTERM path as a "ROUTINE outcome" was withdrawn rather than re-stated.

**Condition that would drive it:** a live `--arm a` / `--arm b` pair under a deliberately short
`REMOTE_TIMEOUT`, checking the container's `/tmp` afterwards for surviving `/tmp/p6-mf.*` and
`/tmp/p6-taghist.*` names. **Attaches to the EXISTING Phase 7 entry criterion `E12`**, alongside
`DEF-06-34-04` and `DEF-06-34-06`. **No new criterion was invented.**

**Urgency:** low. It is litter in a container `/tmp` plus an unverified mechanism claim, not a
correctness defect — but "the handlers are terminal" must not be read as "the leak is closed".

---

## DEF-06-39-05 — `scripts/quick-health-check.sh` was executed ZERO times in round 4 either

**Found during:** plan 06-35, closing R4-01, R4-07 and R4-08 (2026-09-23). Also true of the review
itself, which states it in its own closing line.
**Disposition:** an unchanged limit, restated because it now spans **two consecutive rounds** and a
reader may assume a file with this much churn has been run.

Neither `06-REVIEW-GAP3.md` nor plan 06-35 executed the script. It contacts LXC 100 (172.16.1.159)
and atlantis (172.16.1.158), and this phase makes no estate contact. Round 3 carried the same limit.

**Every assertion about its remote command strings is a capture or a grep.** The five `printf '%q'`
renderings R4-01 and R4-07 installed were proven by generating the command string that *would* be
sent with `echo`, never sending it, and re-parsing it locally with `set --` — the same word splitting
the remote bash performs. That is a faithful **model**, and it is a model: it shows `_drift_pair`
receives the right argument; it does **not** show the remote function then behaves as expected. The
decisive capture row is the quote-bearing value, which moved from **argc 2 with `$3` EMPTY** to
**argc 4 with the quote intact**. R4-08 changed nothing executable at all.

**The block-level behaviour closes only on a live run.** Named rather than left as a silence, the
undriven surfaces include: the vendored-drift block's match / drift / short-answer / could-not-look
branches and its remote exit-3/4/5 arms; the `DRIFT_APPDATA_ROOT`, `DRIFT_REPO_ROOT` and
`DASH_RESOLVE_IP` override guards firing at runtime; the dashboard probe's 124 / 255 /
curl-non-zero / 302 / 401 / 200 arms; `bounded_ssh`'s watchdog and sentinel paths at both probe
sites; and every other block in the file, none of which round 4 touched.

**Related but distinct, and not duplicated here:** `DEF-06-29-11` records that the deployed host sits
at a pre-Phase-6 commit, so a live run today would exercise a different file than the one in this
repo. That is the reason a live run is not merely deferred but currently **uninformative** about
round 4's changes.

**Condition that would drive it:** the same `git push` + host `git pull --ff-only` the vendored-drift
block is already waiting on, followed by a real `quick-health-check.sh` run. Operator's call.

**Urgency:** low, and unchanged from round 3. Recorded so that four rounds of edits to this file are
not mistaken for four rounds of testing it.

---

## DEF-06-39-06 — the self-referential-count hazard has migrated into the `<automated>` verify blocks, and nothing in the round's brief was looking there

**Found during:** plan 06-38, task 2 (2026-09-23), logged by that plan as `F-06-38-01` and
`F-06-38-02`.
**Disposition:** a **new surface** for a class this phase has closed three times in the scripts
(GC-10 → R3-05 → R4-05). Carried rather than fixed: it is a defect in how plans are *written*, not in
any shipped file.

**The instance.** Plan 06-38's own task-2 verify block asserted
`/usr/bin/grep -cF '| grep -q' scripts/check-beets-config.sh` **== 0**. It answers **2** at the plan's
own base commit and 2 after — *unchanged by the plan*. The two hits are **comments quoting the
retired construction to explain why GC-01 replaced it**, i.e. the two comments explaining this
phase's only BLOCKER. The assertion **could never have passed**, and satisfying it would have
required deleting that documentation. This is `06-DISPOSITIONS-GAP2.md` § Lessons 4 verbatim: *a grep
for a token's absence cannot distinguish a claim from its retraction.* Substituted with the
comment-stripped form, which measures 0 at base and 0 now and still fails loudly on a real executable
regression. **No code was changed to make a test pass** — the assertion was wrong about the tree and
the tree was right.

**The wider point.** Round 4 closed raw self-referential counts **in the scripts** while the blocks
**checking** those scripts carried the same defect. Artifacts are subject to it too: plan 06-38's own
artifact pinned a raw count at 4 (it was 6), corrected it to 6, and then had it moved again by the
plan's own new comment — withdrawn at the third attempt. A separate figure in the same artifact was
pinned at 18 and measured 22. Plan 06-35 hit the same shape from the other side: its first draft of
an in-band explanation **quoted the call sites the widened recipe matches**, so the recipe counted its
own documentation.

**Every one of these was caught by measuring AFTER the edit landed. None was caught by an
assertion.**

**Mitigation, for any future plan in this phase:** any verify assertion counting a token in a file
that *discusses* that token must use the **comment-stripped** recipe or an **inequality**, never a
raw equality; and any count written into a file that greps itself must be **bracketed** so the recipe
is not an occurrence of what it measures (`EXIT-CODE BEHAVIOUR CHANGE[D]`,
`EXTRA_FORBIDDEN_SUBSTRINGS:[-]`), **verified after being written in band, not before**.

**Condition under which it should be revisited:** at the planning stage of any round 5 — sweep the
`<automated>` blocks for raw self-referential counts **before** executing. `DEF-06-21-08` and
`DEF-06-29-07` already own the broader "plan `<verify>` blocks are a systemic defect class in this
phase" finding; this entry is the specific self-referential sub-case and cross-references them rather
than restating them.

**Urgency:** low in consequence, high in recurrence — this is the fourth consecutive round in which
the class has fired, and the first in which it fired in the verification rather than the code.

---

## DEF-06-45-01 — `tank/media/Music@pre-06-41-conf04-reprobe` is STILL HELD, and its release is a separate operator decision

**Found during:** plan 06-45, task 2, closing gap-closure round 5 (2026-09-24). Created by plan
06-41 and standing ever since.
**Disposition:** deliberately NOT bundled into the round's closure, and named here so that a later
tidy-up does not read "the round is over" as "the fence can go".

The snapshot is **round 5's only undo** for its three writes — three file mtimes under
`tank/media/Music`, and nothing else. It was taken in the *same remote step* as the mutation so the
fence and the change could not come apart, listed back and asserted equal before any file was
touched, and re-asserted PRESENT by 06-42 SECTION J and again by 06-43 SECTION O.

**No `zfs rollback` has been executed by any plan in this round, and none is an executor's to run.**
Rolling back a live shared dataset discards whatever Jellyfin, Music Assistant or the operator wrote
to it since the snapshot. The command is recorded in 06-42 SECTION K for the operator and is
deliberately left there.

**Cost of holding it:** negligible. The round changed 0 bytes of content, so the snapshot's
referenced-unique space is essentially nil, and `tank` has ~9 T free. There is no space argument for
destroying it in a hurry.

**Condition under which it should be released:** the round's outcome accepted (it now is —
`negative-carry-e6`, 2026-09-24T14:30:37Z) **and** Phase 7's pilot fence planned, so the estate is
never without an undo across the boundary. Release is then an operator action, not a plan's.

**Related and NOT the same fence:** `tank/downloads@pre-phase5` is also still held and is Phase 5's
only undo (D-32, Phase 7 entry criterion E4). Neither was released by this round.

**Urgency:** low to release, high to not destroy by accident.

---

## DEF-06-45-02 — the mtime lever was DRIVEN and did not re-probe: a measured negative Phase 7 must not spend its first hour repeating

**Found during:** plans 06-41 and 06-42, verdict computed in 06-43, recorded here by 06-45 task 2
(2026-09-24).
**Disposition:** a **result**, carried so it is not re-discovered. `06-03` listed "(b) the file's
mtime changing" as a mechanism that would cause Jellyfin to re-probe; round 5 pulled exactly that
lever inside a snapshot fence and measured that it does not.

**What was driven:** three file mtimes touched from atlantis as real root (the permission was
probed first with its own no-op form, `touch -r f f`, so an `EPERM` would have been a recorded
negative rather than a discovery mid-mutation), then the same targeted Default-mode
`POST /Library/Media/Updated` at **file** scope that 06-03 proved safe — **one write verb for the
entire round**, HTTP 204 — and a settle of 19,597 s against a floor of 120.

**What was measured:** ZERO of the three pinned rows moved. Row 1 measured **0** against a target of
**4**; rows 2 and 3 measured **1** each against a target of **2**; all three AT-BASELINE, with a
`;`-in-entity-name count of 0 on every row and an **EMPTY** 1,244-row census delta.

**Why it is a measurement and not an UNKNOWN** — the distinction is the whole value of the round:
06-41's `LibraryMonitor` named all three Audio items by full internal path 60 s after the POST, so
"the refresh never started" is ruled out; and `PreferNonstandardArtistsTag` re-read **`true`**
afterwards, so the option did not revert. The refresh ran, reached the items, and the prober did not
re-read the `ARTISTS` tag.

⛔ **The correct response to a disproven mechanism is the recorded negative.** Not a second refresh,
not a wider refresh mode, and not the aggressive per-item one — which stays forbidden, was not
issued, and was unreachable from every branch of the round.

**Where it attaches:** Phase 7 entry criterion **E6**, first measurement, which this round leaves
STILL OPEN under the operator's explicit `negative-carry-e6` override. The remaining untried
mechanism is a genuine write or new import of a multi-artist release.

**Condition under which it should be revisited:** Phase 7's first write or import. If someone
proposes re-touching mtimes to force a re-probe, this entry is the answer.

**Urgency:** low in consequence, high in save-the-next-person value.

---

## DEF-06-45-03 — HYPOTHESIS (not a conclusion): row 1 may be an E5 problem, not an E6 one

**Found during:** plan 06-43 SECTION N, recorded here by 06-45 task 2 (2026-09-24).
**Disposition:** carried as a **hypothesis with its evidence**, deliberately not written as a
finding. Round 5 produced no experiment that separates it from the simpler explanation.

**The evidence.** Row 1 of `ARTIST_PROOF_ROWS` —
`/media/Music/Lady Gaga/ARTPOP (2013)/CD 01-05 Lady Gaga - Jewels n’ Drugs.flac` — is one of the
**30** Jellyfin items that carry a populated `Artists` *string* list and **ZERO** linked
`ArtistItems` entities (all of `Lady Gaga/ARTPOP (2013)`, all of `Lady Gaga/Joanne (2016)`, and one
Def Leppard track). That set is Phase 7 entry criterion **E5**, and it predates round 5.

**The hypothesis.** "The prober re-ran" and "browseable artist entities exist" may be two different
facts. A per-file Default-mode refresh performs no artist-**entity** creation, so on an item already
in that shape it could re-probe and still produce zero entities — which would make row 1 the
**weakest** of the three rows to have pinned a mechanism test on, independent of whether the
mechanism works.

**Why it is NOT a conclusion.** Rows 2 and 3 are *not* in the 30-item set, and they did not move
either. The simplest reading of all three rows together is the one 06-43 recorded: the prober did
not re-read `ARTISTS` at all. The E5 shape would only become load-bearing if a future re-probe moved
rows 2 and 3 and left row 1 at zero.

**Condition under which it should be revisited:** at Phase 7's first write, if the Jellyfin rows
split 2-of-3. Then E5's artist-entity repair, not E6's re-probe, is the lever for row 1.

**Urgency:** low. Recorded so that a 2-of-3 result is recognised instead of puzzled over.

---

## DEF-06-45-04 — `06-43` SECTION O publishes a NON-DETECTING recipe: `grep -cF` with a bracketed needle can never match the real token

**Found during:** plan 06-44's post-commit round audit (2026-09-24), independently confirmed by the
orchestrator, and carried here because correcting a committed artifact's published recipe was
outside both plans' `files_modified`.
**Disposition:** **CARRIED, not fixed.** The defect is in a *recipe*, and the *number it published
is nevertheless true* — which is precisely why it is worth writing down rather than shrugging at.

**The defect.** `06-43-conf04-verdict.txt` SECTION O recipe **`(O-a)`** publishes
`/usr/bin/grep -cF "Full[R]efresh"` as the forbidden-mode detector. **`-F` makes the brackets
literal**, so the command searches for the *mitigation form* and is structurally incapable of
matching the real token. The correct form is **`-cE`**, where `[R]` is a character class matching
the real `R`.

**Driven both ways, not argued:** against a one-line control file containing the real token, `-cE`
returns **1** and `-cF` returns **0**. So the published form is proven non-detecting and the
corrected form is proven non-vacuous.

**The published `0` is still TRUE of those artifacts.** Re-measured with `-cE`, every round-5
artifact and both instrument scripts read **0**. The number was simply **not earned by the command
printed beside it** — a true result from a vacuous instrument, which is the worst shape of all
because it survives review.

**`(O-b)` is sound** and needs no correction: it already uses `-ciE` for the forbidden UI button's
phrase.

**This is `DEF-06-39-06` one level in:** the detector became an occurrence of its own mitigation
instead of a test for the prohibited thing. Cross-referenced rather than restated; see also
`DEF-06-21-08` and `DEF-06-29-07` for the broader "plan verify blocks are a systemic defect class in
this phase" finding.

**Condition under which it should be revisited:** whenever `(O-a)` is next cited or copied — by
`/gsd-verify 06`, by a Phase 7 plan, or by anyone reaching for a round-6 audit recipe. Copy the
`-cE` form from this entry, not the `-cF` form from the artifact. The artifact itself is a dated
record and is deliberately left unedited.

**Urgency:** low in consequence, high in copy-paste risk.

---

## DEF-06-45-05 — round 5's could-not-looks, named as could-not-looks rather than as clean results

**Found during:** plan 06-45, task 2, auditing what round 5 did and did not observe (2026-09-24).
**Disposition:** a standing limit restated, because a round that measured a great deal can make the
things it never looked at invisible.

**1. The live health check was not run — in this round either.** `scripts/quick-health-check.sh` was
executed **zero** times across round 5, as in rounds 3 and 4. 06-44 refused the live run
deliberately and said why: it would have exercised that plan's *edited local arm* against the **old
prose still deployed** on LXC 100, which is a partial and misleading test of exactly the thing that
changed. `DEF-06-39-05` already owns this limit; it is cross-referenced, not restated.

**2. The deployed instrument is once again behind the repository.** 06-42 took its corroborating run
on a host checkout asserted `MATCH` — the honest remedy (push, `git pull --ff-only`, re-run) having
been applied mid-plan rather than the test relaxed. But rounds 5's later commits (06-43's artifact,
06-44's two script corrections, and this plan's five documents) have **not** been pushed, so
`/mnt/fast/stacks` on LXC 100 now carries the pre-06-44 prose again. Any live run before a
`git pull --ff-only` measures the wrong file.

**3. What the round never touched, stated so it is not inferred as verified:** E6's second
measurement (see `ROADMAP.md`, and it produced no evidence bearing on it); the E5 artist-entity
repair (`DEF-06-45-03`); the container-side signal behaviour (`DEF-06-39-04`, E12); and
`06-VERIFICATION.md`'s score, which this round deliberately did not re-compute.

**Condition under which these clear:** the same operator `git push` + host `git pull --ff-only` the
vendored-drift block has been waiting on since round 1, followed by a real `quick-health-check.sh`
run; and `/gsd-verify 06` for the score.

**Urgency:** low individually. Recorded together because "round 5 measured the estate carefully" is
true and could easily be over-read.
