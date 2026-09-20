---
phase: 06-tagger-configuration-and-dry-run
plan: 02
subsystem: planning-record
tags: [beets, jellyfin, requirements, traceability, zfs-snapshot]

# Dependency graph
requires:
  - phase: 04-retire-the-dead-taggers
    provides: the TAGR-05 addendum precedent at REQUIREMENTS.md:276, including the already-recorded fact that `--pretend` never calls `lookup_candidates`
  - phase: 05-inbox-structure-and-the-junk-gate
    provides: the `tank/downloads@pre-phase5` snapshot whose release condition this plan corrects
provides:
  - CONF-06 traceability addendum naming `beet move -p` as the destination-path oracle (D-33)
  - CONF-04 traceability addendum recording the `ARTISTS` write side and the `PreferNonstandardArtistsTag` decision (D-34)
  - a written record that D-21's fenced `rw` grant is not required and must not fire this phase
  - PROJECT.md's corrected snapshot-release condition, moved to after Phase 7's pilot (D-32)
affects: [06-tagger-configuration-and-dry-run, 07-pilot-import, check-music-consumers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Addendum-not-rewrite: a requirement whose named instrument is wrong keeps its text and gains a dated traceability addendum naming the right instrument"
    - "Retraction-in-place: a superseded claim stays legible beside its correction so a mechanical grep for the old wording returns the retraction attached"

key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-02-SUMMARY.md
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/PROJECT.md

key-decisions:
  - "D-33: CONF-06's text stands; `beet move -p` is named as the destination-path oracle by addendum, and `--pretend` is kept only for what it proves (incremental/ignore/grouping)"
  - "D-34: CONF-04's write side is the `ARTISTS` tag, not `;` in `ARTIST` — beets has no delimiter or join key at 2.12.0 or 2.13.1; Jellyfin gets `PreferNonstandardArtistsTag`, and `UseCustomTagDelimiters` is deliberately refused"
  - "D-32: `tank/downloads@pre-phase5` is kept until after Phase 7's pilot passes — Phase 6 writes nothing, so its sign-off is not evidence Phase 5 was correct"
  - "D-20's delimiter search was answered offline from Phase 1's `pre-project.ndjson.gz`, so D-21's scoped `rw` grant must not fire and the `:ro` invariant holds for the whole phase"

patterns-established:
  - "Instrument correction is recorded as a discriminator, not a caveat: a `--pretend` transcript containing no ` -> ` and no `/mnt/tank/media/Music/` substring is a source listing, not a tree"
  - "A live-service config change git cannot capture is recorded with its assertion site named in the same sentence"

requirements-completed: [CONF-04, CONF-06]

# Metrics
duration: 11min
completed: 2026-09-20
---

# Phase 06 Plan 02: Record Corrections Before Measurement Summary

**Two dated traceability addenda naming `beet move -p` as CONF-06's destination-path oracle and the `ARTISTS` tag as CONF-04's write side, plus PROJECT.md's snapshot-release condition moved off a paper phase and onto Phase 7's pilot.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-20T00:00:00Z (approx — worktree execution)
- **Completed:** 2026-09-20
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- **CONF-06 (D-33)** carries an addendum stating that `beet import --pretend` cannot produce the intended tree — the pretend pipeline is exactly `read_tasks → log_files` (`beets/importer/session.py@v2.12.0:201-240`), `log_files` prints only source paths (`stages.py@v2.12.0:266-274`), and `lookup_candidates` is never in the pipeline, so no destination is ever computed. `beet move -p` is named as the oracle, with `item.destination()` and its citation (`ui/commands/move.py@v2.12.0`). The addendum states explicitly that this was **not a new finding** — the same fact is recorded against TAGR-05 on 2026-09-11 and CONF-06 was written after it.
- `--pretend` is kept in the record for what it genuinely proves (`incremental`, `ignore`, `ignore_hidden`, `clutter`, `singletons`, album grouping) without reaching `finalize`, the only caller of `save_history()`/`save_progress()` (`tasks.py@v2.12.0:310-320`), so it still serves D-31.
- The trap is written down as a **mechanical discriminator**, not a warning: a `--pretend` transcript contains no ` -> ` and no `/mnt/tank/media/Music/` substring at all.
- **CONF-04 (D-34, amending D-23)** carries an addendum recording that the write side is the `ARTISTS` tag (ID3 `TXXX:ARTISTS`, Vorbis `ARTISTS`) and that beets **cannot** be configured to emit `;` in `ARTIST` — it concatenates MusicBrainz `joinphrase` values (`beetsplug/musicbrainz.py@v2.12.0:341-367`) and no delimiter/separator/join key exists in `config_default.yaml` at 2.12.0 or 2.13.1. The read side becomes the `PreferNonstandardArtistsTag` decision, with `UseCustomTagDelimiters` refused and `AC/DC` named as the casualty; the live-service/no-git risk is recorded with its assertion site (`check-music-consumers.sh`, plan 06-12).
- The addendum also records that **D-21's fenced `rw` grant must not fire** — D-20's search was answered offline against Phase 1's `pre-project.ndjson.gz` (6 files with `;` in `ARTIST`, 6 in `ARTISTS`), so the `:ro` invariant holds for the whole phase.
- **PROJECT.md (D-32)** now says the snapshot is kept and released after Phase 7's pilot, with the reason stated rather than implied: Phase 6 writes nothing, so it produces no evidence Phase 5's changes were correct.

## Task Commits

1. **Task 1: CONF-06 and CONF-04 traceability addenda (D-33, D-34)** — `3569fd8` (docs)
2. **Task 2: Correct PROJECT.md's snapshot-release condition (D-32)** — `94a25a1` (docs)

## Files Created/Modified

- `.planning/REQUIREMENTS.md` — the CONF-04 and CONF-06 traceability rows gain dated addenda; status cells move from `Pending` to `Pending (addendum 2026-09-20)` so the addendum is discoverable from the status column. **The CONF-01…CONF-06 requirement statements are byte-identical** — `git diff` shows exactly two deleted lines, both status cells.
- `.planning/PROJECT.md` — the `tank/downloads@pre-phase5` release condition corrected in place, dated `(corrected 2026-09-20, plan 06-02, D-32)`, with the superseded "must not be destroyed before Phase 6 signs off" wording quoted so a grep for it returns its retraction. 8 insertions, 2 deletions; no other claim moved — the 144-folder denominator and the `mac-music-archive` figures are untouched, as the plan required.

## Decisions Made

None beyond the plan — D-32, D-33 and D-34 were locked in `06-CONTEXT.md` and are recorded verbatim in substance. Two presentation choices were forced by the files themselves and are noted here so they are not mistaken for drift:

- **The PROJECT.md correction is prose, not a blockquote.** `beets.md`'s retraction house style uses a `>` block, but the target text sits inside the `*Last updated: …*` italic run that spans PROJECT.md's closing paragraph; a blockquote inside it would break the emphasis span. The retraction is written as prose inside the italic block, quoting the superseded wording, which preserves the property that matters — a grep for the old claim returns the correction with it.
- **The pipe character in the CONF-04 addendum is escaped** (`\|`) because the addendum lives inside a markdown table cell, where a bare `|` would split the row.

## Deviations from Plan

None — plan executed exactly as written. No auto-fix rule fired; no bug, missing-critical or blocking condition was encountered. This plan touched only planning records: no code, no host access, no package manager, no network call.

## Issues Encountered

None. Both task verify commands' conditions were checked individually (the worktree isolation layer refuses compound `bash -c` strings it cannot parse, so each `grep` was run as a plain command rather than as the single composed line in the plan — same assertions, same results).

Verification results:
- `beet move -p` present: 1 occurrence; `lookup_candidates`: 2; both `ADDENDUM 2026-09-20 (06-02, D-33)` and `(06-02, D-34)` present; `PreferNonstandardArtistsTag` present; the precedent's closing sentence now appears **6** times (was 4; threshold ≥3).
- `git diff --numstat -- .planning/PROJECT.md` → `8 2`, within the ≤4-deletion budget.
- `git diff -- .planning/REQUIREMENTS.md | grep '^-' | grep -v '^---'` → exactly the two `Pending` status-cell lines.
- `git diff --stat` across both commits → exactly two files changed.

## User Setup Required

None — no external service configuration required by this plan. ⚠ Forward-looking, and recorded here because it is easy to lose: **D-34's `PreferNonstandardArtistsTag` is not yet applied to the live Jellyfin Music library.** This plan only records the decision. Applying it, documenting it in `stacks/selfhosted/arrs/beets.md` and asserting it in `scripts/check-music-consumers.sh` belong to later Phase 6 plans (06-12). Until the assertion exists, the setting is one UI click from silently reverting with no trace in any repo.

## Next Phase Readiness

- Phase 6's measurement plans can now be written against instruments that can actually measure: `beet move -p` for the tree, `--pretend` for task offering only.
- The `:ro` invariant is documented as holding for the entire phase — nothing in Phase 6 needs a write grant on `/mnt/tank/media/Music`.
- Phase 7 inherits the snapshot fence: `tank/downloads@pre-phase5` stays until its pilot passes.
- **Not done here, by design:** STATE.md and ROADMAP.md are untouched (worktree/parallel execution — the orchestrator owns those writes).

## Threat Flags

None. The addenda quote source file paths with line numbers, Jellyfin option names, and counts. No API key, token, JWT, password or credential path appears in either file's diff, and no new network, auth or file-access surface is introduced — this plan changes documents only (T-06-08 disposition holds).

## Self-Check: PASSED

- `.planning/REQUIREMENTS.md` — FOUND, modified, committed in `3569fd8`
- `.planning/PROJECT.md` — FOUND, modified, committed in `94a25a1`
- `.planning/phases/06-tagger-configuration-and-dry-run/06-02-SUMMARY.md` — FOUND (this file)
- Commit `3569fd8` — FOUND in `git log`
- Commit `94a25a1` — FOUND in `git log`

---
*Phase: 06-tagger-configuration-and-dry-run*
*Completed: 2026-09-20*
