---
phase: 05-inbox-structure-and-the-junk-gate
plan: 02
subsystem: planning-records-and-standing-checks
tags: [roadmap, requirements, amendment, health-check, criterion-4, negative-control, atlantis]
requires:
  - "05-PREMEASURE.md §§ 3,4,5,6 — the measurements all three amendments cite"
  - "05-CONTEXT.md D-02/D-05/D-08/D-12/D-14/D-15/D-22/D-25 — the rulings the amendments encode"
provides:
  - ".planning/ROADMAP.md — Phase 5 criteria 2, 3 and 4 amended in band and dated, originals intact"
  - ".planning/REQUIREMENTS.md — INBX-01/02/03 inline ADDENDUM entries in the TAGR-05 shape"
  - "scripts/quick-health-check.sh — the criterion-4 standing assertion, seventh fatal block, driven red and green"
  - ".planning/phases/05-inbox-structure-and-the-junk-gate/deferred-items.md — the pre-existing unrelated red that makes the script exit code non-discriminating"
affects: [05-03, 05-04, 05-05, 05-06, 05-07, 05-10, 05-11]
tech-stack:
  added: []
  patterns:
    - "in-band dated amendment, four moves (quote original / state measurement / name change / preserve substance), never replacing the criterion"
    - "inline table-cell ADDENDUM for requirements, distinct from the blockquote used for criteria"
    - "bounded remote count: set -o pipefail INSIDE the remote string, ssh status on the very next line, 124 split out"
    - "three verdicts never two — could-not-look / there-are-none / BROKEN"
    - "driven negative control on real state, with the instrument seen both red and green in one session"
key-files:
  created:
    - .planning/phases/05-inbox-structure-and-the-junk-gate/deferred-items.md
  modified:
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - scripts/quick-health-check.sh
decisions:
  - "The criterion-4 block increments EXIT_CODE, not a fail()/FAILURES helper — quick-health-check.sh has no such helper; that is check-jellyfin-transcode.sh's mechanism and the plan named the wrong file"
  - "Registration is the failure tail plus a ninth EXIT-CODE notice, not a summary selector — selectors in this file parse a FOLDED-IN script's summary and this block folds in nothing"
  - "The offending-paths listing is captured to a variable rather than piped inline, so the house-rule grep over 'timeout $REMOTE_TIMEOUT.*|' gains no new line to reason about"
  - "The 'at least 5' acceptance count on the substance phrase is unsatisfiable as written and was NOT made to pass by editing the two pre-existing amendments"
metrics:
  duration: ~35 min
  completed: 2026-09-18
  tasks: 2
  commits: 2
---

# Phase 5 Plan 02: The Criteria Now Say What Was Measured, and Criterion 4 Has Been Seen to Fail — Summary

Three of Phase 5's four success criteria drifted from the measurements; all three now carry dated
in-band amendments that annotate rather than replace, and criterion 4 has stopped being a green
claim and become an instrument that was driven red on real library state and back to green in the
same session.

## What was done

**Task 1 — three amendments and three addenda.** `.planning/ROADMAP.md` gained **75 inserted lines
and zero deleted ones**: the text of criteria 2, 3 and 4 is byte-identical to its pre-plan state and
every amendment sits underneath the criterion it annotates, blockquoted, in the 02.1-11 / 04-04
four-move shape — quote the original, state the measurement with its `05-PREMEASURE.md` section,
name the change, preserve substance with the rejected alternative named.

- **Amendment A (criterion 2, D-12 + D-14)** narrows the junk sweep to the music paths
  (`complete/nzb/music/`, `unsorted/`, `dj-mixes/`, `/mnt/tank/downloads/lidarr-import/`, the new
  `complete/nzb/_inbox/`) and rules `incomplete/` out entirely under D-15. It names all four music
  `_FAILED_`/`_UNPACK_` items and all six TV/movie ones, so the narrowing is visibly a *scope*
  change and not a loss. **D-14 is folded in as a note inside A, not given an amendment of its
  own** — the Potter clause names the wrong tree (`find` over `dj-mixes` for `*potter*` returns
  zero), the rip is `unsorted/Harry.Potter…MOOVEE`, and it is ordinary junk for D-13's gate.
- **Amendment B (criterion 3, D-02/D-05/D-08)** records the flat 4,760-file / zero-subdirectory
  shape, replaces the 4,760 reconciliation target with **4,746 mp3 plus 14 sidecars accounted
  separately**, adds the strictly stronger per-volume identity **`files_present == sum of
  tracktotal`**, and states that all discs of a volume live in one folder. It names the rejected
  alternative: reconciling against the m3u's 4,770 entries would fail by 24 every run.
- **Amendment C (criterion 4, D-22 + D-25)** quotes the criterion unchanged, records that
  `05-PREMEASURE.md` § 6 measured zero, and converts it from work-to-perform into a standing
  assertion proven capable of failing. It also states **D-25's prohibition** in the same place,
  because that is the adjacent temptation a reader meets next.

The Phase 5 `**Research**:` line gained a dated confirmation that research was *deliberately*
skipped and that the amendment chain from criterion to measurement is followable without a
RESEARCH.md.

`.planning/REQUIREMENTS.md` gained inline `**ADDENDUM 2026-09-18 (05-02, …)**` text on the
**INBX-01, INBX-02 and INBX-03 status rows only** — `git diff -U0` shows a single hunk at
`@@ -277,3 +277,3 @@`, so the requirement text at lines 155-165 is untouched. Each closes with
"The text above is deliberately not rewritten."

**Task 2 — the criterion-4 assertion, and driving it.** `scripts/quick-health-check.sh` gained a
seventh fatal block asserting **zero directories whose basename begins with `_` anywhere under
`/mnt/tank/media/Music`**, placed with the other music-library blocks. It copies the shape of the
container-count block at `:796-839`, not its content, and carries both halves of that block's
two-part fix: `set -o pipefail` **inside** the remote command string, and the ssh status captured on
the **very next line** with no local pipe in front of it. Three verdicts, never two — could-not-look
(124 split out first, then any other non-zero or a non-integer answer), there-are-none, and BROKEN —
with each could-not-look message stating in words that *nothing was counted* and that this is not
"zero underscore directories".

It is the first block in that file whose primary read targets **atlantis (172.16.1.158)** rather
than LXC 100, so the WR-10 reachability gate at the top does not cover it and ssh 255 is handled
inside the block as its own named UNKNOWN. `MUSIC_UNDERSCORE_HOST` and `MUSIC_UNDERSCORE_ROOT` are
overridable and either override forces a non-green run, reusing the existing `DASH_HOST` /
`EXTCONF_HOST` convention rather than inventing a second one.

A ninth `EXIT-CODE BEHAVIOUR CHANGED` notice was added to the header, and the failure tail at the
bottom was extended **in the same commit as the block that can now reach it** — the discipline that
file states three times and that this makes four.

## The driven negative control

`05-PREMEASURE.md` § 6 measured the true count as zero, which makes green the default path and would
otherwise have left this an assertion nobody has seen fail. It was driven, in one process under an
`EXIT` trap so the trap genuinely covered the window:

| Step | Observation |
|---|---|
| Pre-state | `test ! -e /mnt/tank/media/Music/_probe` → absent |
| `mkdir` from **atlantis as real root** (the D-20 sanctioned route) | `/mnt/tank/media/Music/_probe 76 127 root:root 777` |
| Health check WITH probe | `❌ 1 '_'-prefixed director(y|ies) under /mnt/tank/media/Music`, listing `/mnt/tank/media/Music/_probe`; script exit 1 |
| `rmdir`, absence re-asserted | removed |
| Health check WITHOUT probe | `✅ No '_'-prefixed directories under /mnt/tank/media/Music` |
| Independent post-assertion from atlantis | `find … -maxdepth 1 -type d -name '_*' \| wc -l` → **0**, rc 0 |
| Trap on exit | `TRAP: probe absent` |

No `chmod` was attempted: `mkdir` and `rmdir` both work on `tank`, `chmod` fails `EPERM` even as
real root. The probe was safe to create because Jellyfin's real-time monitoring and metadata savers
are off for the Music library (Phase 1, 01-06), so an empty directory present for seconds writes
nothing — and nothing was written.

**⚠ The probe tripped a SECOND, independent instrument, which is the most useful line in the whole
transcript.** `check-music-freeze.sh` also went red on it — `❌ ownership: 1 entries differ from
568:568` — because a `mkdir` as real root creates `root:root`. Two instruments that share no code
saw the same probe, and both returned to baseline after it was removed. The red/amber line set of
the post-probe run is **byte-identical to the pre-probe baseline** (`diff` clean), which is the
evidence the estate is exactly as it was found.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — plan factual error] The plan named a `fail()` helper and a `FAILURES` counter that
`quick-health-check.sh` does not have.**
- **Found during:** Task 2, before writing the block.
- **Issue:** The action and an acceptance criterion require the violation branch to "call the
  failure helper that increments `FAILURES`, not `info()`". `grep` over the file finds **no**
  `fail()` or `info()` definition and no `FAILURES` variable of its own: those belong to
  `check-jellyfin-transcode.sh` and `check-music-freeze.sh`. `quick-health-check.sh`'s failure
  mechanism is `EXIT_CODE=1`, set at every fatal site in the file.
- **Fix:** the violation branch sets `EXIT_CODE=1`, as do both could-not-look branches. The plan's
  *intent* — that the violation must move the script's verdict rather than merely print — is
  satisfied and was proven by the driven control, which exited the script 1 with the block red.
- **Files modified:** `scripts/quick-health-check.sh`. **Commit:** `15ca5d6`.

**2. [Rule 3 — blocking, instrument hygiene] The offending-paths listing would have added a line to
the file's own house-rule grep.**
- **Found during:** Task 2, checking `grep -n 'timeout \$REMOTE_TIMEOUT.*|'` after the first draft.
- **Issue:** `ssh … "timeout $REMOTE_TIMEOUT find …" | sed` puts the pipe **locally**, which is
  harmless, but the file's greppable rule at `:444-453` cannot tell which side of the quotes a pipe
  is on. A new line in that grep's output is a new line a future reader has to adjudicate.
- **Fix:** captured into `UNDERSCORE_PATHS` and printed on the next line, with a comment saying why.
  The grep now returns only the three pre-existing lines (804, 1099, 1100) and no new one.
- **Files modified:** `scripts/quick-health-check.sh`. **Commit:** `15ca5d6`.

### Deviations recorded rather than made to pass

**3. Two acceptance criteria in this plan's own contract are unsatisfiable as written, and neither
was satisfied by editing anything that already existed.**

- **`grep -c 'The substance is kept, not reduced' .planning/ROADMAP.md` returns 3, not "at least
  5".** The two pre-existing amendments write the phrase as `The **substance is kept, not
  reduced**` — the bold markers fall *inside* the literal, so the exact string has never matched
  them and returned **0** at the parent commit. The three new amendments write it as
  `**The substance is kept, not reduced**`, where the whole phrase is emphasised and the literal
  survives intact, so the exact grep now returns 3. **The discriminating substitute is
  `grep -c 'substance is kept, not reduced'`, which returns 5** — the two pre-existing plus the
  three added, exactly the number the criterion was reaching for. The pre-existing amendments were
  **not** reformatted to make a grep pass; they are the locked 2026-09-03 and 2026-09-11 records,
  and rewriting settled text to satisfy a string test is the defect this estate has recorded five
  times under "a mechanical check satisfied by prose about the thing rather than by the thing".

- **"Registering the new check in the script's selector" has no referent.** The selectors in
  `quick-health-check.sh` (`:1447`, `:1511`, `:1622`, `:1726`) each parse the **summary of a
  separate folded-in script**. This block folds in nothing — it is an inline assertion, like the
  container counts and the dashboard probe, neither of which appears in any selector. The
  equivalent registrations for an inline block are the **failure tail** and a **header notice**, and
  both were done.

### Out of scope, logged not fixed

**4. `scripts/quick-health-check.sh` exits 1 today for a reason that has nothing to do with Phase
5.** `check-music-freeze.sh` fails its `interpolated-host-path inventory MOVED: expected=12,
found=13` assertion. Checked rather than assumed: that assertion counts *compose volume lines*, it
runs from the host-side repo at `/mnt/fast/stacks` (`b27255b`, where
`grep -c MUSIC_UNDERSCORE_ROOT scripts/quick-health-check.sh` is **0**), and this plan's edits are
workstation-local in a different file. Its own failure text demands each new line be **read by hand**
with `DECLARED_INTERP_EXPECTED` moved in the same commit — a human-review gate on a compose change
this phase did not make. Logged in `deferred-items.md`.

**Consequence a verifier must know:** the whole-script exit code is **non-discriminating** for
criterion 4 while that red stands. The block's own verdict line is the instrument. This plan's
control was therefore driven on the verdict line *and* on the `diff` of the run's red/amber line
set, not on the exit code — the same near-vacuous-exit-code honesty 02.1-09 recorded.

## Verification

| Check | Result |
|---|---|
| `grep -c 'Amended 2026-09-18 by plan 05-02' .planning/ROADMAP.md` | **3** |
| `grep -c 'ADDENDUM 2026-09-18 (05-02' .planning/REQUIREMENTS.md` | **3** |
| `grep -c 'The text above is deliberately not rewritten' .planning/REQUIREMENTS.md` | **4** |
| `grep -c 'substance is kept, not reduced' .planning/ROADMAP.md` | **5** (exact-literal variant: 3 — see deviation 3) |
| `grep -c 'files_present == sum of tracktotal' .planning/ROADMAP.md` | **1** |
| `git diff --numstat .planning/ROADMAP.md` | **75 / 0** — additions only, no criterion line touched |
| `git diff -U0 .planning/REQUIREMENTS.md` hunks | one, `@@ -277,3 +277,3 @@` — lines 155-165 untouched |
| `bash -n scripts/quick-health-check.sh` | exit **0** |
| `grep -c 'mnt/tank/media/Music' scripts/quick-health-check.sh` | **7** |
| `grep -v '^[[:space:]]*#' … \| grep -c 'tank/downloads.*568'` | **0** — no D-25 ownership assertion added |
| `grep -n 'timeout \$REMOTE_TIMEOUT.*\|'` minus pipefail/`grep -q` | 804, 1099, 1100 only — all pre-existing |
| EXIT-CODE notice counts, measured before and after | headers **8 → 9**, raw **11 → 12**, offset unchanged at 3 — exactly what the new notice claims |
| Block red with probe | `❌ 1 '_'-prefixed director(y\|ies) …`, path listed, script exit 1 |
| Block green after removal | `✅ No '_'-prefixed directories under /mnt/tank/media/Music` |
| `find /mnt/tank/media/Music -maxdepth 1 -type d -name '_*' \| wc -l` at task end | **0** |

## Commits

| Commit | What |
|---|---|
| `00a49a6` | ROADMAP amendments A/B/C and the three INBX addenda |
| `15ca5d6` | the criterion-4 assertion block, its header notice, the failure tail, and the driven control |

## What this unblocks

- **05-03/05-04** meet a criterion 2 they can actually satisfy: the sweep's rule list is scoped to
  five named music paths, `incomplete/` is explicitly out, and the Potter item is ordinary junk for
  the approval gate rather than a special case.
- **05-05/05-06/05-07** meet a criterion 3 whose denominator (4,746 mp3) and whose real instrument
  (`files_present == sum of tracktotal` per volume) are both written down before the run.
- **05-10** meets D-25 stated in two places — the ROADMAP amendment and a comment beside the new
  block — so the tree-wide chown does not acquire a standing assertion that would go red on the next
  download.
- **05-11** can re-assert criterion 4 by running the estate's own standing check rather than by
  taking a fresh one-off measurement.

## Known Stubs

None.

## Requirements deliberately NOT ticked

This plan's frontmatter names `INBX-01, INBX-02, INBX-03`, but `requirements mark-complete` was
**not** run and none of the three is ticked. This plan **amended the records** for those
requirements; it did not satisfy any of them — the inbox exists but the phase still has to sweep the
junk (05-03/04), split the `Now!` collection (05-05…07) and re-assert everything from live state.
05-01 made the same call for the same reason. All three ticks belong to **05-11**. Ticking a
requirement that later plans in the same phase still have work against is how a verifier ends up
reading a green box over unfinished work.

## STATE.md write hazards hit again, and repaired

Recorded because it is now four-for-four and the repair is not optional:

- `state.advance-plan` **broke the multi-line `Status:` field** (replacing only its first line and
  orphaning `gates are …`) and **truncated the frontmatter `last_activity:`** to a bare date, losing
  05-01's description. It also rewrote an unrelated `Last activity:` line 560 lines further down,
  mid-paragraph. All repaired; the in-band note at the top of STATE.md was extended.
- `state.update-progress` **rewrote the milestone `Progress:` line for the fourth time**, this time
  to 85% against a 74-plan denominator. Reverted; the fourth occurrence is recorded on that line
  beside the previous three.
- `state.record-session` **truncated `last_activity:` a second time**, after it had just been
  repaired. Repaired again.

`git diff .planning/STATE.md` after every single `state.*` call is the only reason none of this
landed in a commit.

## Self-Check: PASSED

All three named files exist on disk; both commit hashes (`00a49a6`, `15ca5d6`) are present in
`git log`.
