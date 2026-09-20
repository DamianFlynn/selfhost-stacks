---
phase: 06-tagger-configuration-and-dry-run
plan: 03
subsystem: consumers
tags: [jellyfin, music-assistant, conf-04, d-34, d-22, d-20, d-24, health-checks]
requires:
  - Jellyfin 10.11.11 on LXC 100, reachable on t3_proxy
  - /mnt/fast/secrets/jellyfin-deercrest.env at mode 600 root (D-40)
  - Phase 1's offline tag fence at /mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz
provides:
  - "PreferNonstandardArtistsTag enabled on Jellyfin's Music library, proven and asserted"
  - "a standing assertion that the change cannot silently revert (check-music-consumers.sh 4a)"
  - "a D-22 artist-entity check in both consumers with per-consumer measured baselines (4b, 4c)"
  - "before/after ArtistItems censuses over all 1,244 library audio items"
affects:
  - scripts/check-music-consumers.sh
  - stacks/selfhosted/arrs/beets.md
  - plan 06-13 (owns closing CONF-04's MA half)
  - Phase 7 (the re-probe that discharges the Jellyfin half arrives with the first real write)
tech-stack:
  added: []
  patterns:
    - "jf_api's -H @<(printf ...) process substitution, reused unchanged — the admin-equivalent key never enters argv"
    - "read-modify-write over a complete options object, then assert exactly one field differs"
    - "per-consumer measured baseline alongside a target, so 'not yet' is reported and counted, never ticked and never permanently red"
key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-03-jellyfin-artist-before.txt
    - .planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-03-jellyfin-artist-after.txt
  modified:
    - scripts/check-music-consumers.sh
    - stacks/selfhosted/arrs/beets.md
decisions:
  - "D-34 applied: PreferNonstandardArtistsTag true on the Music library; UseCustomTagDelimiters deliberately left false (AC/DC)"
  - "D-21's fenced rw write did not fire — the :ro invariant is unbroken for the whole phase"
  - "The forbidden aggressive refresh mode was NOT issued, so CONF-04's Jellyfin read-back is deferred rather than bought with .nfo rewrites"
  - "The D-22 check is written as a drift detector with both target and measured baseline, rather than as a permanently-red assertion"
metrics:
  duration: ~75 min
  completed: 2026-09-20
---

# Phase 6 Plan 03: Jellyfin artist parsing (D-34) Summary

`PreferNonstandardArtistsTag` is now true on Jellyfin's Music library, proven field by field and
asserted forever after — and the plan's central assumption turned out to be wrong in a way worth
more than the change itself: **the option is probe-time, so it does not retroactively re-parse the
existing 1,244 items, and the only refresh that would is the one Phase 1 forbade.**

## What was done

**Task 1 — the before-state** (commit `3936d7f`). D-20's delimiter survey was re-run against Phase
1's offline fence, library-scoped: `ARTISTS;` = 6 and `ARTIST;` = 6, matching research exactly, so
the fence has not moved and criterion 4's design still stands. **D-21 did not fire** — the
pre-authorised fenced `rw` write was not needed and was not performed. The complete `LibraryOptions`
object was captured as the task-2 diff basis, three `ARTISTS` proof rows were pinned with expected
counts and a WHY each, the six `ARTIST`-delimited TRUSTFALL rows were recorded separately and marked
**DO NOT RESCAN**, and a 1,244-row `ArtistItems` census was taken with `TotalRecordCount` and the
returned length agreeing.

**Task 2 — the write** (commit `79b12e3`). `POST /Library/VirtualFolders/LibraryOptions` -> HTTP 204,
built as a one-field edit over the complete captured object. Read-back diff over the union of both
key sets: **exactly one field differs, and it is `PreferNonstandardArtistsTag`.** The Phase 1 freeze
was then asserted by name, field by field — `SaveLocalMetadata`, `EnableRealtimeMonitor`,
`SaveLyricsWithMedia` all false, `MetadataSavers` still `["Nfo"]`. The restore path was not needed.
The targeted scan was `POST /Library/Media/Updated` and nothing else, the TRUSTFALL paths excluded.

**Task 3 — the standing assertion** (commit `203e07f`). `check-music-consumers.sh` gained section
4a (the four-field D-34 assertion, on its own route, reading an endpoint nothing else in the repo
reads), 4b (the D-22 entity check in Jellyfin) and 4c (the same in Music Assistant, failing closed).
Live run on LXC 100: exit 0, all four D-34 fields green.

## The finding

Enabling `PreferNonstandardArtistsTag` **changed nothing about the existing library**, and that is
not a failure of the write — it is how the option works.

It is a **probe-time** option: it governs what `AudioFileProber` does the next time it runs on a
file. `POST /Library/Media/Updated` produces a **Default**-mode refresh, and a Default-mode refresh
does not re-run the prober on a file whose mtime has not changed. Measured twice — once with the
three album directories in the update body, once with the three individual track files — with
Jellyfin's `LibraryMonitor` confirming by name that it refreshed all six items:

```
[22:55:50] LibraryMonitor: ARTPOP (/media/Music/Lady Gaga/ARTPOP (2013)) will be refreshed.
[23:02:26] LibraryMonitor: jewels n' drugs (…/CD 01-05 Lady Gaga - Jewels n’ Drugs.flac) will be refreshed.
```

**Zero of 1,244 census rows changed** — not a count, not a name, not an Id. The one refresh mode
that would re-probe is the aggressive per-item one Phase 1 measured rewriting 83 of 91 `.nfo` files
with `SaveLocalMetadata` already off. It is forbidden (D-24, T-06-11) and was not issued.

So the useful half of the result: **the option is correct and in place BEFORE the first import**,
which is precisely the case the project's core value is about — "new music downloads land in the
library correctly tagged". The evidence arrives with Phase 7's first write.

## Music Assistant came back up, and mostly agrees

Research recorded MA as down for maintenance; it answered by the time task 3 ran. Two of the three
pinned rows read **exactly at target**: `California Gurls` -> `Katy Perry | Snoop Dogg`,
`Just Give Me a Reason` -> `P!nk | Nate Ruess`. MA prefers `ARTISTS` and splits it on `;` natively,
exactly as the source read predicted. Research assumption **A2 is empirically confirmed**:
`music/tracks/library_items` with `{limit, provider}` returned a 1,244-element array of track
objects carrying `artists[]` on MA 2.11.0b2. It is still not checked against
`GET /api-docs/commands.json`, which is that script's stated authority — 06-13 owns that.

The third row is a **measured discrepancy, not a pending state**: `Jewels n' Drugs` carries four
`ARTISTS` values (`Lady Gaga;T.I.;Too $hort;Twista`) and MA returns three
(`T.I. | Lady GaGa | Too $hort`) — `Twista` absent, and the spelling is the `ARTIST` tag's
"Lady GaGa", not the `ARTISTS` tag's "Lady Gaga". MA read this file fresh through the export, so
"not yet re-probed" does not explain it. 06-13 owns it.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 - Blocking] A second `Media/Updated` pass at file scope**
- **Found during:** Task 2
- **Issue:** the album-scope scan the plan specified ran and changed nothing. Two hypotheses fit:
  the album refresh never reached its Audio children, or a Default refresh never re-probes an
  unchanged file at all. Without separating them, the finding would have been a guess.
- **Fix:** one additional `POST /Library/Media/Updated` with the three individual track paths —
  the same sanctioned endpoint, strictly *narrower* scope, still excluding the TRUSTFALL set. The
  `LibraryMonitor` named all three Audio items; the census still did not move. Second hypothesis
  confirmed, first eliminated.
- **Files modified:** artifact only
- **Commit:** `79b12e3`
- Two auto-fix attempts were spent; a third was not. The only remaining lever is the forbidden
  refresh mode, and retrying a permitted endpoint does not turn it into that one.

**2. [Rule 1 - Bug] The D-22 assertion is a drift detector, not a bare equality**
- **Found during:** Task 3
- **Issue:** the plan says "assert `len(ArtistItems) == N`". Given the finding, that is a
  **permanent red** on every `quick-health-check.sh` run until Phase 7 — and this repo has recorded
  (01-09) exactly what a permanently-red check does to a reader. Asserting the current value
  instead would be manufacturing success.
- **Fix:** each pinned row carries BOTH a post-re-probe target and the measured 2026-09-20 baseline,
  per consumer. `== target` passes; `== baseline` is reported, counted in the summary, and never
  ticked; anything else is red. The falsifiable parts are asserted hard and unconditionally: a `;`
  inside any entity Name is an immediate red (the precise failure D-22 exists to catch), as are
  duplicate Ids and a missing envelope. A closing banner names the pending counts so the existing
  green line cannot stand alone over an unproven criterion.
- **Files modified:** `scripts/check-music-consumers.sh`
- **Commit:** `203e07f`

**3. [Rule 1 - Bug] The pinned search term had to become the exact track title**
- **Found during:** Task 3, first live run
- **Issue:** `Jewels` narrowed Jellyfin's `SearchTerm` fine but produced a bogus "not in MA", because
  the MA side matches the track name **exactly** (MA 2.11's own `search` returned `[]` for an item's
  own exact name when 02-07 measured it, so all matching in that file is local).
- **Fix:** full title as the search term, with the reason written above the table. Note the path
  carries U+2019 while the title tag carries an ASCII apostrophe — the row is selected by exact
  `Path`, so both spellings are load-bearing in different places.
- **Commit:** `203e07f`

**4. [housekeeping] The remote before-capture directory was overwritten**
- A re-run of the capture script during task 2 overwrote `/tmp/06-03-jf-before/` on LXC 100 with
  after-state content. No data was lost: the authoritative before-state was already committed to
  git. Recorded so a reader who goes looking on the host is not misled by a stale scratch directory.

### Not done, deliberately

- **`UseCustomTagDelimiters` was not enabled.** D-34 rejected it; `/`, `|` and `\` come along with
  `;` across 1,244 files and `AC/DC` is the canonical casualty.
- **The TRUSTFALL set was not rescanned.** It is unchanged, all six rows, distinct Ids intact. The
  finding also explains why it was never actually at risk: nothing re-probes it either.
- **`REQUIREMENTS.md` was not touched.** CONF-04 is **not** complete — the plan says so itself, and
  the measurement makes it emphatic. Marking it would be false.
- **STATE.md and ROADMAP.md were not touched** (worktree mode; the orchestrator owns them).

## Verification

| Check | Result |
|---|---|
| `bash -n scripts/check-music-consumers.sh` | pass |
| `shellcheck -S error` / `-S warning` | both clean |
| Live run on LXC 100 | **exit 0**; four D-34 fields green; 3 Jellyfin rows pending; MA 2 at target, 1 reported |
| `grep -rn 'FullRefresh' artifacts/06-03-*.txt` | no matches |
| `grep -c '^/media/Music/'` on both artifacts | 1244 and 1244 |
| Changed fields on the options write | **1**, `PreferNonstandardArtistsTag` |
| Phase 1 freeze after the write | `SaveLocalMetadata=false`, `EnableRealtimeMonitor=false`, `SaveLyricsWithMedia=false`, `MetadataSavers=["Nfo"]` |
| `album.nfo` mtimes in all four touched albums | still 2026-08-18 14:34 — nothing written into the library |
| `docker inspect jellyfin` Music bind | `/mnt/tank/media -> /media`, unchanged |

## Success criteria

| # | Criterion | Verdict |
|---|---|---|
| 1 | D-20 re-confirmed offline; D-21's `rw` fallback did not fire | **TRUE** |
| 2 | `PreferNonstandardArtistsTag` true, `UseCustomTagDelimiters` false, freeze fields proven false field by field | **TRUE** |
| 3 | N distinct artist entities read back for every pinned `ARTISTS` row (D-22) | **NOT MET — and not obtainable in this phase.** 0/3 in Jellyfin (nothing re-probed), 2/3 in MA. Achieving it in Jellyfin requires the forbidden refresh mode. |
| 4 | The change is in `beets.md` and asserted in `check-music-consumers.sh` | **TRUE** |
| 5 | CONF-04 remains OPEN | **TRUE, and now with a measured reason** |

## Known stubs

None. Nothing was stubbed, mocked or hardcoded to make a check pass. The two baseline columns in
`ARTIST_PROOF_ROWS` are measured values with dated provenance, not placeholders, and the branch that
uses them reports rather than passes.

## Open for the operator

1. **CONF-04's Jellyfin half is PENDING, not passed.** Do not let the script's exit 0 be read as
   closure — the closing banner says so, and so does `beets.md`.
2. **An untaken decision.** Obtaining the Jellyfin proof today means one aggressive refresh on three
   albums, at the cost of their `.nfo` being rewritten inside a phase whose premise is that it
   writes nothing. The default was not to. If that trade is wanted, it is an operator call, not an
   executor one.
3. **MA version drift**: live `2.11.0b2` against `MA_VERSION_PROVEN=2.11.0b0`. The banner warns by
   design. Re-prove the provider assertions against the new build and move the constant in the same
   commit — do not just bump the number.
4. **30 items with zero `ArtistItems`** (all of `Lady Gaga/ARTPOP`, all of `Lady Gaga/Joanne`, one
   Def Leppard track) while carrying a populated `Artists` string list. Unexplained, left alone, and
   the reason one pinned row's baseline is 0. It is also the reason the check asserts on
   `ArtistItems` and not on `Artists`.

## Delivery note

`scripts/check-music-consumers.sh` reaches LXC 100 **only by git** — the host runs it from
`/mnt/fast/stacks` after `git pull --ff-only`. The live run recorded above was made from a
throwaway copy at `/mnt/fast/06-03-test/`, which was **removed at the end of the plan** so no
untracked copy of the script is left drifting on the host. The extension is not in effect on the
host until this branch merges and the host pulls.

## Self-Check: PASSED

All five files present on disk; all four commits present in `git log --all`
(`3936d7f`, `79b12e3`, `203e07f`, `de4d00f`).

