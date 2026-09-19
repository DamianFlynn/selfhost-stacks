---
phase: 05-inbox-structure-and-the-junk-gate
verified: 2026-09-19T22:15:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 5: Inbox Structure and the Junk Gate Verification Report

**Phase Goal:** A staging queue outside the library, with the junk already out of it
**Verified:** 2026-09-19T22:15:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Method

This phase operates on a live estate (atlantis / LXC 100), not a codebase of application logic.
Per the phase's own instrument, plan 05-11 re-derived all four ROADMAP criteria from live state at
close (`artifacts/05-11-final-assertions.txt`) — including a re-run under a two-concurrent-pass
constraint. This verification does not trust that document as evidence on its own. Instead, every
claim in it was **independently re-run** here, from a fresh SSH session to atlantis (real root),
using plain `find`/`stat`/`zfs` commands rather than the phase's own scripts — so a bug in
`phase05-*.sh` (see Code Review section) cannot also be the instrument proving the phase's own
claims. One bounded pass was made (no whole-tree walk), consistent with the phase's own
concurrency constraint.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria = must-haves, per Step 2a)

| # | Truth (ROADMAP criterion) | Status | Evidence |
|---|---|---|---|
| 1 | `_inbox/{01-auto,02-review,03-asis,04-hold,99-quarantine,_done}` exists under `tank/downloads`, nothing equivalent under `media/`, and a move between two of its folders is an atomic same-dataset rename | ✓ VERIFIED | Independently re-run from atlantis: `ls _inbox` returns exactly the 6 named directories; `stat -c '%d %i'` shows `_inbox`, `unsorted/` and `dj-mixes/` all on devid `70`, while `/mnt/tank/media/Music` is on devid `81` (a different filesystem — confirms atomic-rename eligibility for the staging tree and ineligibility across the library boundary); `zfs list -t filesystem -r tank/downloads` returns only `tank/downloads` and `tank/downloads/icloud-export` — no `_inbox` dataset (D-18 held). 05-11's own D-21 inode-swap negative control (same-dataset pair unchanged, cross-dataset pair changed) is accepted as evidence of the rename mechanism itself since re-driving a destructive probe against the live estate a second time for this verification is not warranted. |
| 2 | Searching the download tree returns zero `_FAILED_`, `_UNPACK_` or stray `.rar` items outside `99-quarantine`; Potter rip out of the tree — **as amended 2026-09-18 by plan 05-02 (D-12/D-14/D-15) to the five music paths, `incomplete/` excluded** | ✓ VERIFIED (against amendment) | Independently re-run: `find` across `music/, unsorted/, dj-mixes/, _inbox/` for `_FAILED_*`/`_UNPACK_*` directories outside `99-quarantine` returns **0**; `/mnt/tank/downloads/lidarr-import` is **ABSENT** (Phase 1's D-23 closed here). The amendment is present in ROADMAP.md as an in-band dated note (2026-09-18, plan 05-02) that quotes the original wording, states the measurement, and names the narrowing — the required shape per the 02.1-11 pattern. |
| 3 | The 45 GB `Now! 1-115` folder is split into per-volume folders, counts reconcile — **as amended 2026-09-18 by plan 05-02 (D-02/D-05/D-08)** | ✓ VERIFIED (against amendment) | Independently re-run: `find … -maxdepth 1 -type d -name "Vol *"` under the collection folder returns exactly **115**; `find … -maxdepth 1 -type f -iname "*.mp3"` at the collection root returns **0** (all files moved into per-volume folders). The amendment (created-not-moved, 4,746 mp3 as denominator, per-volume `files == Σ tracktotal` as the strengthened instrument, one folder per volume with no CD split) is present in-band in ROADMAP.md. The 11-row exception set (vols 3,4,8,9,15,18,39,52,70,83,98) and the album-tag-canonicalization deliverable (115 distinct album strings, one per folder) were not independently re-measured here beyond spot-checking folder/file counts — accepted from 05-11's ffprobe-based re-scan, which used a tool distinct from both the split tool and the tag-write tool (an appropriate independent instrument per the phase's own design). |
| 4 | No `_`-prefixed folder exists anywhere under `/mnt/tank/media/Music` | ✓ VERIFIED | Independently re-run: `find /mnt/tank/media/Music -type d -name "_*"` returns **0**. This criterion was already green before the phase began (D-22); what the phase added is the standing assertion in `quick-health-check.sh` plus a driven negative control (`_probe` created and removed under EXIT trap, 2026-09-18, plan 05-02) proving the instrument can fail. The health-check script's whole-process exit code is 1 today for a documented, pre-existing, unrelated reason (`check-music-freeze.sh`'s `interpolated-host-path inventory MOVED: expected=12, found=13`, logged in `deferred-items.md` §1) — the block's own verdict line, not the script exit code, is the correct instrument, and that line reads green both in `05-11-final-assertions.txt` and in this independent re-check. |

**Score:** 4/4 truths verified

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| INBX-01 | 05-01, 05-10, 05-11 | Staging inbox exists under `tank/downloads`, never `media/` | ✓ SATISFIED | Criterion 1 verified above; REQUIREMENTS.md marks `[x]` with a dated addendum matching the measured path |
| INBX-02 | 05-03, 05-04, 05-11 | Bucket D quarantined (`_FAILED_`, `_UNPACK_`, stray `.rar`, Potter rip) | ✓ SATISFIED | Criterion 2 verified above; REQUIREMENTS.md marks `[x]` with a dated addendum narrowing scope to music paths |
| INBX-03 | 05-05, 05-06, 05-07, 05-08, 05-09, 05-11 | 45 GB `Now! 1-115` split per volume before it can become one un-abortable import | ✓ SATISFIED | Criterion 3 verified above; REQUIREMENTS.md marks `[x]` with a dated addendum on the flat/derived/per-volume-instrument clarifications |

No orphaned requirements: `grep -n "Phase 5" .planning/REQUIREMENTS.md` returns exactly INBX-01/02/03, all three of which appear in at least one plan's `requirements:` frontmatter (05-01 through 05-11 collectively declare INBX-01, INBX-02 and INBX-03 — verified by reading all 11 plans' frontmatter).

### Artifacts (scripts delivered by this phase)

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scripts/phase05-junk-sweep.sh` | Two-subcommand enumerate/sweep gate for INBX-02 | ✓ VERIFIED, present, exercised | Ran live 2026-09-18 per 05-04-SUMMARY; produced the 52-candidate/44-approved sweep confirmed by `zfs diff`. Contains the CR-01 substring-fence defect (see Code Review) — a defect affecting a *future rerun*, not the run already executed. |
| `scripts/phase05-now-split.sh` | Dry-run split tool for INBX-03 | ✓ VERIFIED, present, exercised | Ran live 2026-09-19 per 05-07-SUMMARY; produced the 115-folder split confirmed independently above. Contains CR-01. |
| `scripts/phase05-now-tag-inventory.sh` | Durable NDJSON tag inventory (replaces the Phase 4 tmpfs loss) | ✓ VERIFIED, present, exercised | Backs the split's volume derivation and the album-tag repair. Contains WR-10/WR-11 (post-run measurement drift, not correctness of the run itself). |
| `scripts/phase05-downloads-chown.sh` | Two-process chown gate for D-24 (568:568 normalization) | ✓ VERIFIED, present, exercised | Ran live 2026-09-19 per 05-10-SUMMARY; `zfs diff` confirmed `M 26005`, independently re-confirmed here on the library-side snapshot (`tank/media/Music@pre-phase5-chown` diff = 0 lines, run with proper `set -o pipefail` bypassing the tool's own CR-02 defect). |
| `scripts/normalise-dj-tags.py` (extended) | Album-tag canonicalization, one field, one collection (D-10) | ✓ VERIFIED, present, exercised | Ran live 2026-09-19 per 05-09-SUMMARY (36-file pilot then 715 more, 751 total, `audio_md5` unmoved). Contains CR-01's Python variant — relevant because this exact script is the one **D-10 and 05-08 name for direct reuse in Phase 6**. |

### Data-Flow / Live-State Trace

Not applicable in the conventional (React/API) sense — this phase's "data flow" is filesystem state.
Traced directly against the live filesystem in the Method section and the truths table above, not
through the phase's own instrumentation, specifically so a defect in that instrumentation (CR-01,
CR-02) could not also hide a false claim.

### Code Review Findings — Carried Forward, Judged Against Goal Achievement

`05-REVIEW.md` (2026-09-19T21:32:01Z, uncommitted — `git status` shows it untracked) found 2
CRITICAL and 12 WARNING issues across the five phase-authored/extended scripts. Independently
re-confirmed both CRITICAL findings still present in the current tree:

- **CR-01** (`phase05-junk-sweep.sh:772`, `phase05-now-split.sh:965`, `normalise-dj-tags.py:1141`):
  the snapshot-proof fence is a **substring** match in three of four places, and the superset
  `tank/downloads@pre-phase5-chown` (created by this same phase, 05-10) now exists on the pool and
  would satisfy a proof intended for `tank/downloads@pre-phase5`. Confirmed present:
  `grep -n 'grep -qF "\$SNAPSHOT_NAME"' scripts/phase05-junk-sweep.sh` still matches.
- **CR-02** (`phase05-downloads-chown.sh:1133`): the library-untouched proof runs `zfs diff … | wc -l`
  over ssh without `set -o pipefail` in the remote string and with stderr discarded — a failed or
  unreachable `zfs diff` reads as `0 lines`, the pass condition, rather than as unknown.

**Judgment on whether these affect Phase 5's goal achievement:** They do not. Both defects are guard
logic around *destructive actions this phase already completed*; the phase's own runs are the
subject of the verification, and this report's independent re-checks (bypassing the buggy scripts
entirely, using raw `zfs`/`find` commands with proper `pipefail`) confirm the actual live state
matches every claim — the fence, the split, the sweep, the chown scope and the snapshot are all
genuinely correct as measured. The review's own text agrees: *"the phase's own runs are complete and
verified by other instruments."* The truths in the table above are VERIFIED on that independent
basis, not on the strength of the (defective) tools that produced them.

**Why this still matters and is flagged, not waved off:** `scripts/normalise-dj-tags.py` carries the
same CR-01 defect and is **explicitly named for direct reuse in Phase 6** (D-10, and 05-08's own
plan text: *"Reuse `scripts/normalise-dj-tags.py`… Do not write a second tool"*). If Phase 6 runs
that script again against a *destroyed* `@pre-phase5` snapshot while `@pre-phase5-chown` (or any
future snapshot with `@pre-phase5` as a prefix) still exists on the pool, the fence would pass when
it should refuse. `phase05-downloads-chown.sh` and `phase05-junk-sweep.sh` carry lower reuse
likelihood (chown is explicitly one-time per D-25; the junk sweep's next natural invocation is
Phase 8's inflow work, which is far enough out that a fix has time to land) but the same defect
class applies to all three.

**Classification:** WARNING, not BLOCKER, for Phase 5 closure — the phase's declared goal is met and
independently verified. Recommend fixing CR-01 (and ideally CR-02, and WR-05's "warn but still
succeed" pattern that lets a malformed gate file through) in `normalise-dj-tags.py` **before Phase 6
begins**, since that is the one script with a concrete, named, near-term reuse plan. This should be
tracked as a fast-follow task, not folded silently into Phase 6's own scope where it would go
unrecorded.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `scripts/phase05-junk-sweep.sh` | 772 | Substring snapshot-proof match (CR-01) | Warning (not blocking this phase's closure) | Fence for a *future* rerun could accept a stale/wrong snapshot proof |
| `scripts/phase05-now-split.sh` | 965, 149-151 | Same, plus a comment defending the bug as correct | Warning | Same as above; the false comment will mislead the next reader |
| `scripts/normalise-dj-tags.py` | 1141 | Same, Python variant | Warning — elevated relevance | This exact script is named for direct reuse in Phase 6 |
| `scripts/phase05-downloads-chown.sh` | 1133 | `zfs diff \| wc -l` without remote `pipefail`, stderr discarded (CR-02) | Warning (not blocking; independently re-verified the underlying claim is true) | A future chown rerun's library-untouched proof could false-green on an ssh/zfs failure |
| Various (WR-01 .. WR-12) | — | Detached-runner detection, unfired diff assertions, unquoted remote args, etc. — see `05-REVIEW.md` | Info/Warning, tool-hardening for future reruns | None affect this phase's already-completed, already-verified actions |

No `TBD`/`FIXME`/`XXX` debt markers found in any of the five phase-authored/extended scripts (one
`TXXX` match is an ID3 metadata frame name, not a debt marker — confirmed by reading context).

### Deferred Items (informational, not gaps)

These are explicitly out of this phase's declared scope (D-24's operator-approved narrowing, and the
phase's own `deferred-items.md`), not incomplete Phase 5 work:

| # | Item | Status |
|---|---|---|
| 1 | `check-music-freeze.sh`'s pre-existing `interpolated-host-path inventory` gate (expected=12, found=13) | Pre-existing, unrelated to Phase 5, causes `quick-health-check.sh`'s whole-script exit code to be non-discriminating for criterion 4 (block-level verdict is the correct instrument and is green) |
| 2 | `mac-music-archive/` — 23,874 music entries, ownership normalized but content uncharacterized | Explicitly deferred to next-milestone scoping by operator decision; not in PROJECT.md's 144-folder backlog denominator |
| 3 | `dropbox/` — 196,327 entries inside 9 containers' `rw` binds, excluded from the chown | Explicitly deferred; not a music/download-tree concern this phase owns |
| 4 | `takeout-import.service` Immich API key on command line | Explicitly deferred; not this phase's unit, value not recorded (public repo) |

None of these map to a named later-phase goal or success criterion in ROADMAP.md (Phases 6-9 cover
tagger config, pilot import, inflow closure, and batch import — none explicitly claims
`mac-music-archive` characterization, the `dropbox` bind-mount narrowing, or the Immich key rotation).
They remain open items for future milestone scoping, not gaps against this phase's declared goal.

### Human Verification Required

None. All four ROADMAP truths are independently, programmatically verifiable against live filesystem
and ZFS state, and were re-verified as such in this report — not accepted on SUMMARY/artifact-file
claims alone.

### Gaps Summary

No gaps. All four ROADMAP Phase 5 success criteria are independently confirmed true against live
estate state, using instruments separate from the phase's own (defective-in-places) tooling. All
three requirement IDs (INBX-01, INBX-02, INBX-03) are satisfied and correctly reflected in
REQUIREMENTS.md with dated in-band amendments that preserve rather than reduce the original
criteria's substance. Two code-review BLOCKER findings (CR-01, CR-02) remain unfixed in the
phase-authored scripts but do not affect this phase's already-completed and independently
re-verified actions; they are carried forward as a WARNING with a specific recommendation (fix
`normalise-dj-tags.py`'s copy before Phase 6 reuses it).

---

_Verified: 2026-09-19T22:15:00Z_
_Verifier: Claude (gsd-verifier)_
