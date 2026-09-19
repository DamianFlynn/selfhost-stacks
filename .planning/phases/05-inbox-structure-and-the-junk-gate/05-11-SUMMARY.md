---
phase: 05-inbox-structure-and-the-junk-gate
plan: 11
subsystem: phase-closure
tags: [closure, live-reassertion, criteria, devid-instability, inode-collision, zfs-diff-collapse, idmap, D-03, D-18, D-22, D-25, D-26]
requires:
  - "05-02 — the criterion-4 assertion block in quick-health-check.sh and the three in-band ROADMAP amendments"
  - "05-04 — the swept music tree criterion 2 is asserted against"
  - "05-07 — the 115 Vol NNN folders criterion 3 is asserted against"
  - "05-09 — one album value per volume folder, the tag deliverable that makes the split coherent"
  - "05-10 — the 26,005-entry chown, after which ownership readings are worth taking"
provides:
  - "host:/mnt/fast/safety/phase05/phase05-final-assertions.txt — all four criteria re-derived from live state at phase close"
  - "host:/mnt/fast/safety/phase05/close-c3-scan.py + close-c3-scan.json — an independent read-only ffprobe walk of the Now! collection"
  - "stacks/selfhosted/arrs/beets.md § Phase 5 — the durable estate record beside the stack"
  - ".planning/REQUIREMENTS.md — INBX-01/02/03 Complete, addenda and requirement text intact"
  - ".planning/ROADMAP.md — Phase 5 closed, executed plan list, per-criterion TRUE-as-of markers"
affects: [06, 07, 08, 09]
tech-stack:
  added: []
  patterns:
    - "re-derive a closure's claims from live state before writing them down — a closure written from plan summaries launders intentions into looking twice-confirmed"
    - "assert a criterion with an instrument that is neither the tool that produced the state nor the tool that captured it"
    - "show an exclusion is not vacuous by running the same query WITHOUT it and seeing the excluded items returned"
    - "read a block's own verdict line, never a composite script's exit code, when the script has an unrelated standing red"
key-files:
  created:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-11-final-assertions.txt
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-11-close-c3-scan.py
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-11-close-c3-scan.json
    - .planning/phases/05-inbox-structure-and-the-junk-gate/artifacts/05-11-quick-health-check.log
  modified:
    - stacks/selfhosted/arrs/beets.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
key-decisions:
  - "Criterion 4's negative control was deliberately NOT re-driven — creating a probe inside the library at phase close writes into the library for no benefit; the 2026-09-18 05-02 run is cited with its date instead"
  - "The criterion-3 re-assertion used a purpose-written read-only ffprobe walk rather than re-reading 05-09's capture, so the verdict comes from an instrument that neither split the collection nor wrote its tags"
  - "The Potter clause is recorded as satisfied on the NAMED PATH and the substring form is recorded as now-invalid, rather than quietly widening the test to make the count read zero"
requirements-completed: [INBX-01, INBX-02, INBX-03]
duration: ~50 min
completed: 2026-09-19
---

# Phase 5 Plan 11: Four Criteria, Re-Measured Rather Than Restated Summary

**All four Phase 5 criteria were measured again at close — after the sweep, the split, the album
write and the chown — and all four are TRUE with zero FAILs. The closure written into `beets.md`
quotes those live verdicts by artifact name rather than paraphrasing the plans that intended them.
Three known traps were re-confirmed harder than the phase had them (devids have now moved twice,
the inode-34 collision turns out to be three-way, and the 115 volume directories are `568:568` on
disk against a summary that recorded `root:root` from inside the container), and one new trap was
found in the act of testing: `-iname '*potter*'` over the music tree now returns a legitimate song,
because the split moved it where a depth-3 sweep can reach it.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-09-19T21:03Z
- **Completed:** 2026-09-19T21:52Z
- **Tasks:** 2
- **Commits:** 2 (plus this one)

## What was done

### Task 1 — the four criteria, re-derived from live state

Written to `host:/mnt/fast/safety/phase05/phase05-final-assertions.txt`, committed as
`artifacts/05-11-final-assertions.txt`. Every remote command was bounded Linux-side; every remote
string containing a pipe carried `set -o pipefail`; the ssh status was read with no local pipe in
front of it. Before any whole-tree pass: atlantis load 0.97, 8 GB available,
`takeout-import.service` inactive, no `immich-go` process — **one whole-tree pass at a time**, which
is the rule plan 05-09 paid for with a host reboot.

**Criterion 1 — TRUE.** Six directories present. `_inbox` on devid **70** with `unsorted/` and
`dj-mixes/`; the library on **81**. Zero ZFS datasets named `_inbox`. Zero equivalents under
`/mnt/tank/media` to depth 3. The D-21 inode proof was **driven again after the chown**, both
controls, both value pairs observed: same-dataset `(70, 295296)` → `(70, 295296)`, cross-dataset
→ `(43, 128)`, with the probe's absence re-asserted on both sides afterwards.

**Criterion 2 — TRUE against the D-12/D-14/D-15 amendment.** Zero `_FAILED_`/`_UNPACK_` directories
and zero `.rar`-form files across the five music paths outside `99-quarantine`.
`/mnt/tank/downloads/lidarr-import` is **absent**. The exclusion was shown **not to be vacuous**: the
same `find` without it returns the two quarantined Garth Brooks directories (51 entries, 44 FLAC).

**Criterion 3 — TRUE against the D-02/D-05/D-08 amendment and the operator's merge decisions.**
Measured by `close-c3-scan.py`, written for this closure — neither the tool that split the
collection nor the tool that wrote its tags. 115 depth-1 directories named exactly `Vol 001`…
`Vol 115`; 0 at depth 2; 4,746 mp3 summing to the freshly measured total; 0 mp3 at the collection
root; 0 ffprobe failures; **0 volumes carrying anything other than exactly one `album` value**, 115
distinct strings across 115 folders. **Manifest-only entries: 0**, reported on its own line and
never folded into any total. The `files == Σ modal tracktotal` exception set measured **11 rows**
and matched the pre-declared post-merge list — volumes 3, 4, 8, 9, 15, 18, 39, 52, 70, 83, 98 —
**11 for 11, zero differences to name**, with volumes 4/8/9 reproducing the amendment's stated
`+13 / +9 / +13` exactly.

**Criterion 4 — TRUE, and this is D-22's AFTER half.** The block's own verdict line:
`Library underscore-dir guard: ✅ No '_'-prefixed directories under /mnt/tank/media/Music`,
corroborated by an independent `find` from atlantis returning 0. The negative control was **not**
re-driven; the 2026-09-18 run in plan 05-02 is cited with its date and its mechanism, because
creating a probe inside the library at phase close would write into the library for no benefit.

**Two decisions confirmed held rather than merely stated.** D-25:
`grep -v '^[[:space:]]*#' scripts/quick-health-check.sh | grep -c 'tank/downloads.*568'` → **0**, and
in fact the comment-stripped script carries no `tank/downloads` reference at all. D-18: confirmed at
criterion 1.

### Task 2 — the closure, and the requirement and roadmap statuses

`stacks/selfhosted/arrs/beets.md` gains a `## Phase 5 — closed 2026-09-19` section following the
Phase 4 conventions: a heading carrying the verdict and the date, verdicts **quoted** from the named
evidence artifact, distinctions stated plainly. Sub-headings: the four criteria, what keeps these
true, ten traps, recorded-not-fixed, still open, how to re-run, and rollback.

`REQUIREMENTS.md`: INBX-01/02/03 ticked in the requirement list and marked **Complete** in the
status table, each carrying what was re-measured at close. The 05-02 addenda are intact and the
requirement text at lines 155-165 is unchanged apart from the three checkbox characters — the diff
is six lines in, six out.

`ROADMAP.md`: the Phase 5 entry is checked off with its closure verdict, the `**Plans**: 11 plans`
line is replaced by the executed list with one objective per plan, and each of the four criteria
carries a bold **✅ TRUE as of 0X-0Y** marker naming the plan that made it true. The diff **removes
exactly three lines** — the two checkboxes and the Plans line — so the three 05-02 amendments are
provably untouched.

## The traps the closure records

Ten, of which four are worth repeating here because they were sharpened or discovered during this
run:

1. **ZFS devids are not stable.** `tank/downloads` / `tank/media/Music` read 68/76 on 2026-09-18,
   70/75 earlier on 2026-09-19 and **70/81** at close. The property holds; the numbers never do.
2. **The inode-34 collision is three-way**, not two: `/mnt/tank/downloads`, `/mnt/tank/media/Music`
   **and** `/mnt/fast` all report inode 34. Assert the pair `(devid, inode)`.
3. **Never read ownership from LXC 100.** Plan 05-09's summary recorded the 115 `Vol NNN`
   directories as `root:root`; on disk they were `100000:100000`, and at close they are `568:568`
   with zero foreign entries anywhere under the collection. The container view is the idmap.
4. **`-iname '*potter*'` is no longer a valid test.** The 05-07 split moved
   `Vol 066/21. The Proclaimers Featuring Brian Potter (2) & Andy Pipkin — I'm Gonna Be (500 Miles)…`
   into a depth-2 folder where a depth-3 sweep reaches it, so the obvious re-run returns 1 hit that
   is a song. The named rip path is absent; assert the path.

Also recorded: D-03's `Vol.36 CD1` / `Vol.36  CD2` **verbatim with the double space**, D-18's
dataset trap, `zfs diff`'s renamed-and-modified `R`-collapse, a `stat` manifest's blindness to a
`chown` (mtime vs ctime), `ffprobe`'s one-input-file rule, the one-whole-tree-pass-at-a-time rule,
and D-26's by-design mixed ownership under `_inbox`.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — plan factual drift] The plan's criterion-1 wording expects `zfs list -r
tank/downloads` to return one line; it now returns two.** `tank/downloads/icloud-export` exists. The
assertion D-18 actually needs is "**no dataset named `_inbox`**", which holds. Recorded in the
assertions file and in the closure rather than silently reinterpreted, and `05-INBOX-PATHS.md`'s
"returns exactly one line" phrasing is flagged as stale.

**2. [Rule 1 — instrument no longer discriminating] The plan asks to "confirm the Potter rip path
… is absent", and the obvious substring form now returns 1.** The hit was opened rather than
counted: it is `Vol 066/21. The Proclaimers Featuring Brian Potter (2) & Andy Pipkin — I'm Gonna Be
(500 Miles)…mp3`, a legitimate track. The **named** rip path is absent, and the substring form is
recorded as invalid for future re-runs. Widening the pattern to force a zero would have been the
"edit the assertion to make it pass" move this estate repeatedly records as the defect.

**3. [Rule 2 — the record would otherwise be wrong] The prior-wave brief's statement that the 115
`Vol NNN` directories are `100000:100000` on disk is stale.** It was true before plan 05-10; at
close they are `568:568`, and `find <collection> ! -uid 568 -o ! -gid 568` returns 0 from atlantis.
The trap is kept in its general form — never read ownership from LXC 100 — with the current
measurement stated beside it, rather than carrying forward a figure that is no longer true.

### Rule 4 items

None. No architectural decision arose.

## Deferred Issues

None new. The four items already in `deferred-items.md` are carried into the closure's *Still open*
and *Recorded, not fixed* sub-headings rather than left only in the planning tree: the pre-existing
`interpolated-host-path` gate, `mac-music-archive/`, `dropbox/` inside nine `rw` binds, and the
Immich API key on `takeout-import.service`'s command line.

## Known Stubs

None. This plan produced documentation and one read-only measurement script; nothing is wired to a
placeholder data source.

## Threat Flags

None. No file changed in this plan introduces a network endpoint, an auth path, a file-access
pattern or a schema at a trust boundary. The one new executable,
`artifacts/05-11-close-c3-scan.py`, is read-only against the collection and writes a single JSON
file under `/mnt/fast/safety/phase05/`.

## Authentication Gates

None.

## The fence, restated because it is the one thing that must not be tidied away

`tank/downloads@pre-phase5`, taken 2026-09-18 15:42, verified present at close. It is the **only**
undo for 05-07's 4,750 renames, 05-09's 751 in-place tag writes and 05-10's 26,005 chowns. **Do not
destroy it before Phase 6 has signed off.** It is also **not a clean undo** — the closure says so in
full, and says what rolling back would cost.

## Self-Check: PASSED

All four created artifacts present on disk; `05-11-SUMMARY.md` and the modified `beets.md` present;
both task commits (`fbdf1f0`, `e2f3703`) resolve in `git log --all`; and
`host:/mnt/fast/safety/phase05/phase05-final-assertions.txt` is present and non-empty on LXC 100.
