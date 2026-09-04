---
phase: 03-tagger-spike
plan: 07
subsystem: measurement-criterion-1-2
tags: [beets, discogs, musicbrainz, T1, T2, D-05, weighted-estimator, criterion-5, rate-limit, TAGR-01]
requires:
  - "03-02 — the pre-committed thresholds T1/T2/T3 and the estimator, commit 137b6d9e, now an ancestor of origin/main"
  - "03-03 — the 24-folder stratified draw, the backlog weights, and the corrected 144-folder denominator"
  - "03-05 — the normalised arm, the bind-mount inode trap, and the V2/V5 non-disjointness"
  - "03-06 — the gated probe, the corrected 429 instrument, and the request arithmetic"
provides:
  - ".planning/phases/03-tagger-spike/03-DISCOGS-EVIDENCE.md — criterion 1 and 2 evidence: the four cells, the strict/loose gap, the weighted roll-up, timing, requests, 429s and the T1/T2 verdicts"
  - "T1 marked TESTED and FIRED: backlog-weighted strict Discogs rate 27.08% against a 40% threshold"
  - "T2 marked TESTED and NOT FIRED: 21.8 min projected wall-clock for 144 folders, 0 observed HTTP 429"
  - "scripts/spike03-gen-import-config.sh — generates the token-bearing beet import -t config without the value ever reaching an argv"
  - "the measured request rate: M = 3.125 Discogs requests per folder, not the predicted 6-11"
  - "DEF-03-06, DEF-03-07, DEF-03-08 — three new instrument/definition defects"
affects:
  - "03-11 — axis one is now informed on both engines: Discogs resolves ~27% of the backlog by folder, and wrtag renders this repo's path format on no tag at all (03-08)"
  - "03-09 — the D-13 WAV bake-off cannot use this sample: the draw contains zero WAV, so Open Question 5 is UNANSWERED"
  - "03-10 — inherits the import-xcheck config pattern and the same probe build"
  - "03-11 — teardown must remove /mnt/fast/spike-03/beets-config/import-xcheck.yaml (mode 600, holds the token) and the six cell artefacts under out/"
tech-stack:
  added: []
  patterns:
    - "Parameterising a refusal gate rather than weakening it: --require-plugin defaults to the full set and prints NARROWED in the banner when it is not"
    - "Bounding a thin stratum's contribution at 0% and 100% and reporting the band, so a threshold verdict is shown to be robust rather than asserted to be"
    - "Reading every candidate that satisfied a metric, because a track-count rule does not identify a release"
    - "Recording a required cross-check case as NOT COVERED with the count that proves the phenomenon is absent, rather than substituting an arbitrary unit"
key-files:
  created:
    - .planning/phases/03-tagger-spike/03-DISCOGS-EVIDENCE.md
    - scripts/spike03-gen-import-config.sh
  modified:
    - .planning/phases/03-tagger-spike/03-DECISION.md
    - .planning/phases/03-tagger-spike/deferred-items.md
    - scripts/spike03-discogs-probe.py
decisions:
  - "T1 FIRED and is recorded as fired: 27.08% weighted strict against a 40% threshold. The phase exists to produce a number including an inconvenient one"
  - "The headline is produced at discogs.index_tracks: no, and the setting is inert - 0 of 70 Discogs candidate pairs change between no and yes"
  - "T1 is scored on D-05 as written (27.08%) with the 'strict AND the release is correct' reading (22.80%) recorded beside it, rather than redefining a pre-committed rule mid-phase"
  - "The index-track-sensitive cross-check case is recorded NOT COVERED because it does not exist in this sample, rather than substituting an arbitrary folder"
  - "The plan's commit-ordering criterion is unsatisfiable given the plan's own instruction to write verdicts into 03-DECISION.md; the threshold commit's 11.8 h lead over the evidence is asserted instead"
  - "TAGR-01 is NOT marked complete: both halves of its measurement exist, but 'the tagger decision is recorded' is plan 03-11's job"
metrics:
  duration: "~1h05m"
  completed: 2026-09-04
---

# Phase 3 Plan 07: The Discogs Match Rate and the Rate-Limit Projection Summary

Measured criterion 1 and criterion 2 over the 24-folder sample in six cells and **291 Discogs
requests**, and filled in the phase's two measurable pre-committed thresholds: **T1 FIRED** —
the backlog-weighted strict Discogs match rate is **27.08%** against a 40% threshold — and **T2
did not**, at **21.8 minutes** projected wall-clock and **zero** observed HTTP 429.

## What was measured

**`.planning/phases/03-tagger-spike/03-DISCOGS-EVIDENCE.md`** — the four-cell matrix, both
`index_tracks` settings, the weighted roll-up, the strict/loose gap, three breakdowns, both
denominators, the paired-instrument cross-check, timing, requests, and the T1/T2 verdicts.

**Custody first, before any number.** The threshold commit
`137b6d9e92cb44d9c6a48b3963bb33fe0194622f` resolves to a commit, `git branch -r --contains` lists
`origin/main`, `git merge-base --is-ancestor … origin/main` exits 0, and the commit introduced the
T1/T2/T3 rows and the estimator with **402 insertions and 0 deletions**. The orchestrator's push
completed the ancestry check that 03-02 had to defer.

| Cell (24 folders each) | LOOSE | STRICT | Gap |
|---|---|---|---|
| `raw` × `musicbrainz` | 0 | 0 | — |
| `normalised` × `musicbrainz` | 0 | 0 | — |
| `raw` × `musicbrainz discogs` | 9/24 (37.5%) | 6/24 (25.0%) | 3 |
| **`normalised` × `musicbrainz discogs`** | **13/24 (54.2%)** | **6/24 (25.0%)** | **7** |

### The headline

| Figure | Value |
|---|---|
| **WEIGHTED STRICT (the figure T1 is tested against)** | **27.08%** |
| WEIGHTED LOOSE | 51.39% |
| Unweighted strict / loose — reported, **not** tested | 25.00% / 54.17% |
| V6 robustness band (its one folder at 0% and 100%) | 27.08% – **36.80%**, does not straddle 40% |
| "Strict **and** the release is correct" | **22.80%** weighted, 20.83% unweighted |
| Per distinct `audio_md5` cross-check | strict **13.07%** (40/306), loose 34.97% |

## Results

| Assertion | Result |
|---|---|
| Custody — SHA resolves / reachable from `origin/main` / introduced the thresholds | **all three PASS** |
| Preflight — host vs container, both arms | **24 folders / 335 audio** both sides; inodes identical |
| Probe build — staged file vs committed blob | **sha256 identical** before every run |
| Folders per cell (`jq -s 'group_by(.folder)|length'`) | **24** on all six |
| Failure ledgers / exit codes | **0 lines** and **exit 0** on all six |
| Independent `jq` D-05 predicate vs the probe's own counters | **AGREE exactly on all six cells** |
| `index_tracks` no vs yes — Discogs candidates compared | **70 pairs, identical key sets, 0 differ** |
| **HTTP 429 — status column + in-process counter** | **0 on every cell** |
| Naive `grep -c '429'` — **not** the instrument | **25 on every cell**, incl. the zero-Discogs ones |
| Requests, headline cell — two instruments | **75 and 75** (naive host grep: 150, over-counts 2×) |
| M — Discogs requests per folder | **3.125** (predicted 6–11) |
| `x-discogs-ratelimit` | **60**, re-confirmed; `remaining` never fell below 31 |
| Wall-clock — shell vs probe-internal, six cells | agree to within **0.4%** (max delta 0.9 s) |
| Weighted extrapolation to 144 folders | **445.7 requests**, floor **7.43 min**, wall-clock **21.8 min** |
| Naive unweighted baseline | 450.0 requests, 22.0 min |
| Second instrument — `beet import -t` on 5 folders | **Discogs set AGREES 5 of 5** on count, releases, ordering, scores, track counts |
| Probe wrote nothing — `find -newer`, `.meta` and `.sha` subtree diffs, both arms | **0 lines**, **empty**, **empty** (364 files/arm) |
| Both arms `RW=false`; `beets-spike-rw` in `docker ps -a` | **false / false**; **absent** |
| Token screen by value, inside the container, 1,173 files | **2 hits**, both mode-600 configs in the throwaway dir; **0** in any stderr, **0** in shell history, **0** committed |
| `token=` vs `REDACTED` per Discogs cell | 75/75, 75/75, 72/72, 72/72 — **one-to-one** |
| `bash scripts/check-music-freeze.sh` | **exit 0**, all four counters 0 |

## The findings that outlive this plan

**1. T1 fired, and it fired on every reading.** 27.08% weighted, 25.00% unweighted, 36.80% at V6's
most favourable bound, 22.80% on the correct-match reading. The estimator was fixed in advance
precisely so it could not be chosen to land on a convenient side of 40%, and **in the event it did
not matter** — every reading is below. `PROJECT.md` names this as the evidence that would overturn
the beets recommendation, and it has been produced.

**2. D-05's strict rule admits confident wrong matches — 1 of 6 here (DEF-03-08).**
`Mastermix_Issue_412` satisfied D-05 against Discogs `1534659` *"Specialten Issue 14"*, a 2006 DVD,
at 31.2% confidence, because both carry ten tracks. The proximate cause is a stratum definition,
not the rule: that folder's album tag is the bare string `Issue 412`, it is classified **V1**
("already the good case"), so no normalisation rule fired — the same defect class 03-SAMPLE.md
found when it reclassified `album == artist` out of V1. **27.08% is an upper bound on the rate of
correct matches.**

**3. Normalisation buys loose candidates and no strict ones.** Loose 37.5% → 54.2% (+4 folders),
strict 25.0% → 25.0% (+0). The entire lift is in V2, and per 03-05 finding 1 it is the **joint**
effect of the artist rule and the album canonicalisation, so it cannot be attributed to the artist
rule alone. The practical effect is that normalisation **doubles the manual-verification bill**
(gap 3 → 7 folders) while adding no correct matches.

**4. DMC returns zero strict matches on all four folders.** Loose 2/4, strict **0/4**. The two
loose candidates are *Commercial Collection 326* and *318* against a folder that is *498*.
`CLAUDE.md` records Discogs carrying *DMC Commercial Collection 350*; this backlog's issues are
498, 499, 233 and 234, and the catalogue does not reach them. **DMC is the content criterion 4
names explicitly, and Discogs does not answer it.**

**5. The per-file rate is half the per-folder rate — Discogs resolves the tail, not the mass.**
13.07% per distinct `audio_md5` against 25.00% per folder, because five of the six strict hits are
10-file Mastermix issues while the folders that fail are the large ones (one Crate folder is 60
files; the four DMC folders carry 65 between them).

**6. `index_tracks` is inert on this content.** 70 (folder, release) Discogs candidate pairs, both
arms, identical key sets, **0** differing on `n_tracks`/`extra_items`/`extra_tracks`. The required
"index-track-sensitive" cross-check case therefore **does not exist**, and is recorded as NOT
COVERED with the count that establishes it rather than filled with an arbitrary folder.

**7. MusicBrainz throttles with 503, not 429 (DEF-03-07).** 44 of them on the headline cell, every
one from `musicbrainz.org` and none from `api.discogs.com`. It is why projected wall-clock (21.8
min) is ~3× the pure-API floor (7.43 min), and it is the explanation for the only cross-check
disagreement in this plan. **A later plan that guards only on 429 will report a clean run while
MusicBrainz throttles it.**

**8. Two of T2's own named instruments were wrong, in the same direction as DEF-03-05.**
`grep -c 'api\.discogs\.com'` over-counts requests **exactly 2×** because `urllib3` logs a
connection line and a response line per request (DEF-03-06), and `grep -c '429'` returned **25 on
every cell including the two that issued no Discogs request at all**. Three instrument defects in
one threshold row is itself the finding: **this phase's recurring failure mode is a control that is
in place, reasoned about correctly, and measuring the wrong thing.**

**9. M = 3.125 requests per folder, not 6–11.** The prediction was sound and 03-06's measurement of
7 for one mainstream album was correct; a folder whose search returns nothing costs **one** request
with no release fetches behind it, and this backlog has many. Criterion 2's cost is an order of
magnitude below what `PROJECT.md`'s retired "~1,000 folders" figure implied.

## Deviations from Plan

### 1. [Rule 3 — Blocking issue] The probe's plugin gate refused two of the four required cells

- **Found during:** Task 1 setup.
- **Issue:** `REQUIRED_PLUGINS = ("discogs", "musicbrainz")` is a hardcoded constant, so the two
  MB-only cells — which omit `discogs` **by design** — exited 2 at the startup gate. Two of the
  four cells the plan requires could not run.
- **Fix:** the gate was **parameterised, not weakened**. `--require-plugin` is repeatable and
  **defaults to `REQUIRED_PLUGINS`**, so all four Discogs cells ran under the unchanged two-plugin
  gate; an MB-only cell must state its narrower expectation on the command line, and the narrowing
  is **printed in the run banner** rather than silently inferred from the config.
- **Verified both directions before use:** the MB-only config under the default gate still exits
  **2** naming `discogs`; under `--require-plugin musicbrainz` it runs and the banner reads
  `NARROWED from discogs + musicbrainz`.
- **Both probe hashes are recorded** rather than conflated — `0dd5520d…` (03-06's gated build, the
  A1 gate) and `33499c03…` (this plan's build, all six cells). The change **cannot** affect a
  Discogs cell: those pass no `--require-plugin`, so the path is byte-for-byte the old behaviour.
- **Commit:** `1e9ee34`

### 2. [Rule 1 — Bug] The plan's 429 instrument would have falsely fired a pre-committed threshold

- **Issue:** DEF-03-05, mandated for substitution before this plan ran. Measured here at full
  scale: `grep -c '429'` returns **25 on every one of the six cells**, including the two MB-only
  cells with zero Discogs requests. It matches the probe's own 24 progress labels plus its summary
  label.
- **Impact avoided:** used as written, it fires T2's *"any observed 429"* limb on all six cells and
  triggers a re-run of each at 150–260 requests apiece.
- **Fix:** the HTTP status column and the probe's in-process counter, both returning **0**.
  Recorded as a **dated amendment** in `03-DECISION.md` beside the unchanged threshold text, so the
  distinction between correcting an instrument and moving a threshold is visible in the record.
- **Commit:** `88c3295`

### 3. [Rule 1 — Bug] T2's request-counting instrument over-counts 2× (DEF-03-06)

- **Issue:** `grep -c 'api\.discogs\.com'` returns 150 for the headline cell where the true count
  is 75, because `urllib3` emits a `Starting new HTTPS connection` line **and** a response line per
  request. T2's two "independent instruments" disagreed by a factor of two.
- **Fix:** restricted to lines carrying the HTTP status, which reproduces the probe's in-process
  counter exactly. Logged as DEF-03-06 and recorded as a dated amendment.
- **Commit:** `88c3295`

### 4. [Deviation — sanctioned by the plan] A generator script was added under `scripts/`

`scripts/spike03-gen-import-config.sh` is not in the plan's `files_modified`, but the plan
explicitly permits *"a small generator script, committed under `scripts/` or inlined in the plan's
run transcript"*. Committing it is the more auditable of the two options. It gates the credential
file on `600 root`, `source`s it with **no `set -a`**, `export`s the **name** only, sets
`umask 077`, and has a Python child read the value from its **own `os.environ`** — the value never
reaches an `echo`, a `printf` argument, a heredoc at a prompt, a `docker exec -e` or any argv.

### 5. [Method] The denominator is 144, and 03-DECISION.md's 143 is amended rather than overwritten

03-03 corrected the backlog to **144 folders / 7,728 files** with two independent instruments
before any rate existed. Every figure here uses 144. `03-DECISION.md` keeps its original "143"
wording with a dated amendment beside it, per the standing instruction not to rewrite
pre-committed text.

## Verification that could not be satisfied as written

**The plan's commit-ordering criterion is unsatisfiable, and the property it reaches for holds.**
Line 418 requires `git log -1 --format=%ct -- 03-DECISION.md` to *predate* the same query on
`03-DISCOGS-EVIDENCE.md` — but the plan also *requires* writing the T1/T2 verdicts into
`03-DECISION.md`, which necessarily makes its last commit later. The two cannot both hold. What
criterion 5 needs is that the **threshold-introducing** commit predates the evidence, and it does
by **42,469 s ≈ 11.8 hours** (`137b6d9e` at `1788463633`; the evidence at `1788506102`). Recorded
as a retraction in the evidence file with the correct instrument, alongside a byte-level assertion
that the T1/T2/T3 `Threshold`, `Falsifiable form` and `Instrument` columns and the estimator
section's prose are **identical** to `137b6d9e`.

**Open Question 5 (WAV) is NOT answered and must not be read as answered.** The draw contains
**zero WAV** — 134 of `dj-mixes`' 764 WAV files all sit in V3/V6 folders that were scan-bearing or
undrawn. Plan 03-09's D-13 bake-off needs WAV folders named separately.

**`tagger-class writers: 0` remains silence rather than a clean reading for one tagger.**
`check-music-freeze.sh` exits 0 with every counter at 0, but its `TAGGER_PATTERN` cannot match
`sabnzbd` (DEF-03-01), which runs beets as a live post-processing path over the same backlog trees
this sample was reflinked from. The decisive attribution is the **mount table, not the clock**:
`beets-spike` holds no mount under `/mnt/fast/appdata`, and both arms are `:ro`.

**One false zero occurred and was caught by the preflight.** The first container-side count
returned `0 / 0` because the command used `/spike-samples/<arm>`, a path that does not exist — the
mount destination mirrors the host path. Re-asserted correctly at 24/335 with matching inodes. The
preflight worked on the operator's own error rather than on a stale inode, which is the case it was
written for.

## Requirements

**TAGR-01 is NOT marked complete.** Both halves of its *measurement* now exist — Discogs coverage
measured on normalised DJ folders (27.08% weighted) and import timing extrapolated against the API
rate ceiling (21.8 min against 60 req/min) — but the requirement reads *"the tagger **decision** is
recorded with numbers"*, and the decision is plan 03-11's. Marking it here would claim the phase's
headline requirement on the strength of half of it, which is the same call 03-06 made and for the
same reason.

## Known Stubs

None. Three PENDING states remain in `03-DECISION.md` that are deliberately not this plan's:
**T3** (plan 03-10's self-assessment), the **axis one and axis two verdicts** (03-11), and the
**D-13 bake-off table** (03-09). T1 and T2 no longer read PENDING.

## Threat Flags

No new security surface. Every disposition in the plan's register was exercised:

| Threat | Outcome |
|---|---|
| T-03-37 (the runtime config holds the token) | **Held** — mode `600`, outside the repo, generated without the value touching an argv; 03-11 deletes it. A by-value screen over 1,173 files finds it in exactly 2 mode-600 configs and nowhere else |
| T-03-38 (stderr quoted into a summary) | **Held** — screened by value from inside the container printing only counts; `token=` and `REDACTED` are one-to-one on every Discogs cell; **0** `Authorization` in any artefact. Note the plan's own text at line 443 names the wrong channel (DEF-03-04) |
| T-03-39 (moving a threshold after the evidence) | **Held, and asserted byte-for-byte** — the T1/T2/T3 threshold columns and the estimator prose are identical to `137b6d9e`, which is reachable from `origin/main` |
| T-03-39b (reporting a coverage sample as a population rate) | **Held** — every headline is the weighted roll-up, the unweighted figure is reported beside it and labelled untested, and the one thin stratum is reported as a **band** |
| T-03-40 (a number from one instrument) | **Held** — rate, requests and wall-clock each have a named second instrument with a recorded agreement verdict. The one disagreement is explained and confined to MusicBrainz |
| T-03-41 (the shared 60 req/min budget) | **Held** — six cells run strictly **serially** via `setsid`+`nohup`; 0 HTTP 429; `ratelimit-remaining` never below 31 |
| T-03-42 (the sample copies) | **Held** — both arms `:ro`, `beets-spike-rw` absent, `find -newer` 0 lines and empty whole-subtree `.meta` and `.sha` diffs on both arms |
| T-03-43 (`/mnt/tank/media/Music`) | **Held** — no mount under `/mnt/tank/media`; `check-music-freeze.sh` exit 0 |
| T-03-SC (package installs) | **Held** — zero installs |

## Self-Check: PASSED

- `.planning/phases/03-tagger-spike/03-DISCOGS-EVIDENCE.md` — FOUND; contains `index_tracks` (13×)
  and the threshold SHA verbatim (4×)
- `scripts/spike03-gen-import-config.sh` — FOUND
- `.planning/phases/03-tagger-spike/03-DECISION.md` — FOUND; T1 and T2 rows no longer read
  `PENDING`; threshold columns and estimator prose asserted identical to `137b6d9e`
- `.planning/phases/03-tagger-spike/deferred-items.md` — FOUND; DEF-03-05 closed, DEF-03-06/07/08
  added
- Commit `1e9ee34` (`fix(03-07)`) — FOUND
- Commit `316af3a` (`feat(03-07)`) — FOUND
- Commit `88c3295` (`docs(03-07)`) — FOUND
- Zero file deletions across all three commits — VERIFIED
