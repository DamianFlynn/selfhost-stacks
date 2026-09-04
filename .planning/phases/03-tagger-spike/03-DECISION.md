# Phase 3 decision record: one engine, one front end

Companion to [`stacks/selfhosted/arrs/beets.md`](../../../stacks/selfhosted/arrs/beets.md) (the
Phase 1 durable record) and [`stacks/selfhosted/music/wrtag.yaml`](../../../stacks/selfhosted/music/wrtag.yaml)
(the frozen wrtag definition this phase reads and quotes but never edits).

Nothing here is applied by `docker compose`. This is the record of which tagger and which front end
were chosen, on what numbers, against thresholds committed before those numbers existed.

State as of 2026-09-03 — **thresholds committed, no evidence collected yet.** Every result cell in
this document reads `PENDING` by design.

> **This document decides nothing yet, and that is the point.** The three overturning thresholds
> below (T1, T2, T3), the estimator T1 is tested against, and the corrected denominators are
> committed **before a single Discogs request is issued, a single folder sampled or a single weight
> measured**. ROADMAP Phase 3 criterion 5 is unprovable retroactively — the only evidence that a
> threshold predated a number is a commit that predates the number's commit. **Phase 4 deletes the
> loser and Phase 6 grants the winner `rw` on `/mnt/tank/media/Music` — not before.** Nobody holds
> `rw` on Music during Phases 1–3 (Phase 1 D-20).

---

## Pre-committed thresholds (criterion 5)

Three thresholds, in falsifiable form, each with an instrument named. **`Tested?` and `Returned`
stay `PENDING` until the measuring plans run.** A threshold added, moved or reworded after the
evidence fails criterion 5 outright; this table is what a later `git log -p` is diffed against.

| # | Threshold | Falsifiable form | Instrument | Tested? | Returned |
|---|---|---|---|---|---|
| T1 | Discogs matching under **40%** of the backlog after normalisation | The **backlog-weighted strict** rate per D-05, where **strict** means a Discogs candidate appears AND its track count agrees with the folder AND `extra_items == 0` AND `extra_tracks == 0`. Computed **per stratum** over the plan-03-03 sample, then weighted by each stratum's prevalence across the committed 143-folder backlog, and summed. The `discogs.index_tracks` setting that produced the headline number is stated beside it. The **unweighted** per-folder sample rate is reported alongside and is explicitly **not** the figure T1 is tested against — see § *The estimator T1 is tested against*. The **40% threshold value is unchanged** | The criterion-1 `tag_album()` probe (plan 03-06/03-07), cross-checked by a hand-transcribed `beet import -t` on **4–5 folders** that between them cover at least one **DMC** folder, one **missing-`album` (V3)** folder, one **index-track-sensitive** folder, and one **zero-candidate** folder. Three folders cannot cover the four cases most likely to diverge, and paired-instrument confidence must not be claimed more broadly than the cross-check supports | **YES** — plan 03-07, 2026-09-04 | **FIRED.** Backlog-weighted strict rate **27.08%**, below the 40% threshold, at `discogs.index_tracks: no` / `search_limit: 5` on the normalised arm. Unweighted sample rate **25.00%** (6/24) reported beside it and **not** the tested figure. Un-normalised arm: weighted strict **27.08%**, weighted loose **40.16%**. Normalised weighted loose **51.39%** (unweighted 54.17%, 13/24); strict/loose gap **7 folders / 29.2%**. Robust: V6's 0%/100% bound gives 27.08–**36.80%**, still below 40%; the "strict **and** the release is correct" reading is **22.80%** weighted (1 of the 6 strict hits is a confident wrong release). Cross-checked by hand-read `beet import -t` on **5** folders covering DMC, missing-`album` V3, zero-candidate and a strict hit — Discogs candidate set agrees **5 of 5**. The index-track-sensitive case is recorded **NOT COVERED because it does not exist**: 0 of 70 Discogs candidate pairs change between `index_tracks` `no` and `yes`. Evidence: [`03-DISCOGS-EVIDENCE.md`](03-DISCOGS-EVIDENCE.md) |
| T2 | Rate limiting makes bulk import impractical | **More than 4 hours of projected wall-clock for the 143-folder backlog**, OR **any observed HTTP 429 during the timed run**. Either condition alone fires the threshold | `time` around the probe run, cross-checked against `grep -c 'api\.discogs\.com'` on the probe stderr (`urllib3` DEBUG), plus a **separate 429 counter** — `python3-discogs-client` retries a 429 up to 100 times with jittered backoff, so a rate-limited run stalls silently rather than erroring | **YES** — plan 03-07, 2026-09-04 | **NOT FIRED — neither limb.** Projected wall-clock for the backlog = **21.8 minutes** (1,308.1 s), computed per stratum and summed against the corrected **144**-folder denominator; naive unweighted baseline 22.0 min. Pure-API floor **7.43 min** at the observed ceiling (`x-discogs-ratelimit` = **60**, re-confirmed). **Observed HTTP 429 = 0**, on both correct instruments (the HTTP status column and the probe's in-process counter) across **all six** cells. Measured **M = 3.125** Discogs requests per folder (75 responses / 24 folders, both instruments agreeing exactly), plus 1 identity probe per run; total spend this plan ≈ **291** requests, and `ratelimit-remaining` never fell below 31. Recorded beside it: **44 × HTTP 503 from `musicbrainz.org`** on the headline cell — MusicBrainz throttles with 503, not 429, and it is why wall-clock is ~3× the API floor. See § *AMENDMENT — 2026-09-04, plan 03-07* for the instrument substitution and the denominator correction. Evidence: [`03-DISCOGS-EVIDENCE.md`](03-DISCOGS-EVIDENCE.md) |
| T3 | The operator will not sit at the interactive prompt | An explicit **written self-assessment** after the timed hands-on trial, in the operator's own words. **T3 is deliberately not a number** — the roadmap defines it as a self-assessment and quantifying it would be false rigour | Plan 03-10's timed hands-on trial, scored on [`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md) | **YES** — plan 03-11, 2026-09-04. *(Was `PARTIAL` at 03-10 close: the trial ran but the instrument T3 names did not return. The orchestrator then asked the operator directly, after they had driven both arms, and the instrument returned.)* | **FIRED.** The operator's written self-assessment, obtained 2026-09-04 and reproduced **verbatim**: *"If you're asking me directly if I'm going to use the command line or the web interface, then it's the web interface ahead of the command line any day. Right? It is a much more pleasing experience, and the web interface is clean. I understand what's happening, and I know that I need to remove the stuff from the inbox when it's all copied. The command line interface, I'm not a fan. It's fine for a bot to drive us, but for me, as a human, no."* — T3's falsifiable form is *"the operator will not sit at the interactive prompt"*, its named instrument is an explicit written self-assessment in their own words, and that is what this is. **T3 fires.** Three details in the answer that are themselves evidence and must not be lost: (a) *"It's fine for a bot to drive us, but for me, as a human, no"* — the CLI is rejected as a **human interface**, not as a mechanism, so a scripted agent-driven `beet` invocation remains acceptable to them; (b) *"I know that I need to remove the stuff from the inbox when it's all copied"* — the copy-then-clean mental model transferred **within a single trial**, unprompted, which is a real ergonomics result for the policy-inbox architecture; (c) *"I understand what's happening"* is said of the web interface **after** the trial in which that interface silently dropped 9 files and mis-wrote 4 tracks — it endorses rc6's **legibility**, not its **correctness**, and this record does not read it as the latter. **What T3 firing does NOT produce is the consequence 03-02 predicted** — see § *AMENDMENT — 2026-09-04, plan 03-11* § 2. **PRESERVED VERBATIM — the plan-03-10 reading of this cell. It was correct when written and is superseded only because the instrument it says was missing subsequently returned, not by re-interpretation of the same evidence:** NOT ANSWERED — and deliberately not inferred. The operator ran the trial personally and declared it complete, but **the terminal arm ran on 1 of 5 albums** (`clean-1`, a happy-path 87.7% match: 30 s, 1 intervention, 1 context switch, outcome `imported`) and recorded **one** contemporaneous verbatim across the whole trial: *"this is what i see if i move fast"* — which is about the **flask** arm's crash, not the prompt. **One happy-path album is not a test of whether someone will sit at a prompt for 144 folders.** T3 asks for an explicit written self-assessment; no such sentence exists, and writing one in the operator's voice would fabricate the exact instrument this threshold specifies. What the trial *does* establish, and it is narrower: **the operator's tolerance was exhausted by defects, not by the prompt** — they stopped running the terminal arm because the flask arm had already decided the comparison. **Plan 03-11 must obtain the sentence from the operator before closing axis two.** Evidence: [`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md) § *Criterion 8* and § *AMENDMENT B* |

---

## Denominators, committed before the run

Committed here because criterion 2's extrapolation is only interpretable against a stated
denominator, and because the denominator this project has been carrying is wrong by ~8×.

**The backlog denominator is 143 folders (~7,726 audio files).** That is `unsorted` 120 folders
(7,451 files) + `music` 23 folders (275 files). **`dj-mixes` contributes nothing new**: it is a
byte-for-byte duplicate copy of a subset of `unsorted` — separate inodes (242325 vs 206407), link
count 1, identical sizes, and all 85 of its entries appear in `unsorted` by name.

| Bucket | Audio-bearing dirs | Audio files | Notes |
|---|---|---|---|
| `nzb/music` | 23 | 275 | bucket A/B, FLAC-heavy |
| `nzb/dj-mixes` | 60 | 764 | **duplicate of `unsorted` content — contributes 0 to the denominator** |
| `nzb/unsorted` | **120** | **7,451** | wrtag's only source mount |
| **Deduplicated** | **143** | **≈7,726** | `unsorted` ∪ `music` |

> **Retire "7,451 files across ~1,000 folders" wherever it appears** — in `PROJECT.md`, in
> `CLAUDE.md` § Technology Stack, and in any plan that inherited it. The **file count was right**;
> the **folder count was off by ~8×**. This matters because **Discogs requests scale with folders,
> not files**, so the corrected denominator makes it materially *more likely* that T2 does **not**
> fire. That is exactly the kind of pre-committed-threshold outcome this phase exists to establish
> honestly, and it is being recorded before the timing run rather than discovered after it.

**The `dj-mixes` sample population is 60 audio-bearing folders, not 84.** Of the 85 entries, **24
are empty shells** containing zero files. Those 24 include
`VA-Now_That.s_What_I_Call_Music__1-115_2023` — **the "45 GB `1-115` set" that `PROJECT.md` and
`CLAUDE.md` instruct a later phase to split per volume, and which does not exist on disk.** Retire
that instruction with the folder count.

**The match rate is computed per folder as the headline**, because that is the unit of work and the
unit T1 was written against. It is **cross-checked per distinct `audio_md5`** against the QUAL-01
NDJSON at `/mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz` (9,736 records,
`audio_md5`-keyed). **Both are reported.** Phase 1 measured **828 duplicate groups / 1,892 records /
19.4% duplication**, which is why a naive per-folder rate taken over both trees would double-count
the same audio — and why the sample must be drawn from one de-duplicated population.

| Denominator | Value | Role |
|---|---|---|
| Backlog folders | **143** | T2's extrapolation base; the estimator's weighting base |
| Backlog audio files | ≈7,726 | Reported, not used as a rate denominator |
| `dj-mixes` audio-bearing folders | **60** | Corrected from 84 |
| `dj-mixes` empty shells | 24 | Includes the non-existent `1-115` set |
| Headline rate unit | per folder | The unit T1 was written against |
| Cross-check rate unit | per distinct `audio_md5` | Guards against the 19.4% duplication |

---

## The estimator T1 is tested against — weighted by stratum, and fixed NOW

The plan-03-03 sample is drawn **stratified, never random**. It deliberately over-weights minority
variants so that every tag convention in the collection is exercised, and it excludes the 27
scan-bearing folders. That is the correct design for **surfacing failure modes**. It is the wrong
design for **estimating a population rate**: request volume and match likelihood vary by stratum *by
construction* — a V3 folder with no `album` tag issues **no Discogs query at all**, while a V1
folder paginates — so an unweighted average over the sample is skewed by the very thing that makes
the sample useful.

**Therefore T1's headline is a weighted roll-up.** Compute the strict rate within each stratum over
the sampled folders of that stratum, multiply by that stratum's prevalence across the committed
143-folder backlog, and sum. **The same arithmetic governs criterion 2's request extrapolation:**
per-stratum requests-per-folder × per-stratum backlog count, summed — **not** an unweighted
`M × 143`.

The per-stratum weights come from plan 03-03's variant survey, which classifies the whole backlog.
The weight table is recorded **now**, with every weight cell empty. **The *method* is committed in
this commit; the *weights* are a measured fact recorded later; the *rates* are measured later still.
That ordering is the point.**

| Stratum | Definition (from the 764-file ffprobe survey) | Backlog weight | Sampled folders | Strict rate | Weighted contribution |
|---|---|---|---|---|---|
| V1 | `artist="Mastermix"`, `album="Mastermix Issue NNN"` — `va_likely=false`, query = album alone | 0.2569 (37/144) | 6 | 0.6667 (4/6) | **0.1713** |
| V2 | `artist` is `VA` / `Various Artists` / `Various`, `album` present — query becomes `"VA <album>"` | 0.2708 (39/144) | 9 | 0.0000 (0/9) | **0.0000** |
| V3 | `album` absent — **no Discogs query is issued at all** | 0.0764 (11/144) | 2 | 0.0000 (0/2) | **0.0000** |
| V4 | `artist` absent — `va_likely=true` via `not consensus["artist"]` | **0.0000** (0/144) | 0 | n/a — unsampled, zero weight | **0.0000** |
| V5 | `album` present but noisy (`- Disc 1`, ` WEB`, `Vol.`, `Mastermix - ` prefix, trailing space) | 0.2986 (43/144) | 6 | 0.3333 (2/6) | **0.0995** |
| V6 | Real per-track artists (newer issues) — `va_likely=false`, query = album alone | 0.0972 (14/144) | 1 | 0.0000 (0/1) — thin; bounded 0%/100% | **0.0000** (bound 0.0000–0.0972) |
| **Weighted total** | Sum of contributions — **this is the figure T1 is tested against** | 0.9999 (rounding) | 24 | — | **0.2708 = 27.08%** (bound 27.08–36.80%) |
| *(memo)* Unweighted | Plain per-folder rate across the whole sample — **reported, not tested** | n/a | 24 | 0.2500 (6/24) | n/a |

**Report the unweighted per-folder figure beside the weighted one in every table.** Both are honest
numbers about different things; only the weighted one is tested against T1.

### Why fixing the estimator here preserves criterion 5

Stated explicitly so it cannot later read as moving the goalposts:

Criterion 5 requires the overturning thresholds to be committed before the evidence. **The threshold
value — 40% — is not changing, has never changed, and is not changeable after this commit.** What is
being fixed here is *how the number T1 is compared against is computed*, and it is being fixed at
the same moment as the threshold itself — **before a single folder has been sampled, a single weight
measured or a single Discogs request issued.**

An estimator chosen **after** a rate exists is goalpost-moving. An estimator specified **before any
rate can exist** is simply specifying the measurement. This is the same structure as OD-3's widening
directly below, and for the same reason. **Plan 03-03, which draws the sample and measures the
weights, depends on this plan and cannot run before it.** Plan 03-07, which measures the rates,
depends on 03-03.

This change adds **zero** additional Discogs requests and **zero** additional sampled folders. It is
arithmetic over data the phase already collects.

---

## OD-3 — the sample population is widened, and it is widened NOW

D-06 stratified ~20 folders over `dj-mixes`. Research then measured that **`dj-mixes` contains no
DMC content at all** — it is Mastermix-only — while **criterion 4 explicitly names DMC**, and every
DMC folder lives in `unsorted`: `VA-DMC-Commercial.Collection.498/499`,
`VA-DMC.Commercial.Collection.305/306/310/312/327/332`, `VA-DMC-Essential.Hits.233/234/235`.

**The operator's decision is to draw the ~20 folders across `dj-mixes` ∪ `unsorted` as ONE
de-duplicated population**, superseding D-06's population.

**The widening happens before any evidence is collected, so T1's 40% is committed against the
widened population from the outset.** Criterion 5's "threshold committed before the evidence"
property is therefore preserved. This paragraph exists so the widening cannot later be read as a
post-hoc move: at the moment of this commit there is no sample, no survey output and no evidence
file anywhere in the tree.

**De-duplication rule:** because `dj-mixes` duplicates `unsorted` byte-for-byte, **the draw must
dedupe or the same audio is sampled twice.** The sample is drawn from one tree; a naive union over
both would double-count every overlapping folder.

---

## OD-2 — the two axes are measured at different beets versions, deliberately

beets-flask `v2.0.0-rc6`'s `backend/pyproject.toml` carries `beets==2.12.0` — **an exact pin, not a
floor.** Axis one and axis two therefore **structurally cannot share a version**.

| Axis | What it measures | beets version | Container |
|---|---|---|---|
| Axis one | Engine, match rates | **2.13.1** | `lscr.io/linuxserver/beets:2.13.1-ls349` |
| Axis two | Front end, ergonomics | **2.12.0** (hard-pinned by rc6) | `metasauce/beets-flask:v2.0.0-rc6` |

**Justification, recorded here rather than discovered later:** axis two is scored on *interaction*,
not on match quality; `importsource` — the one 2.x feature later phases depend on — landed in 2.6.0
and is present in **both**; and nothing in 2.13.0's changelog affects Discogs candidate generation.

The 2.13.0 features absent from rc6 are all Phase 6/7 concerns or moot against throwaway databases:

| 2.13.x feature | In rc6? | Why it does not contaminate the comparison |
|---|---|---|
| `beet modify` `+=` / `-=` | ✗ | Phase 6/7 concern |
| `edit` plugin album-level YAML header | ✗ | Affects the terminal arm only, which runs 2.13.1 anyway |
| Automatic DB backup before migrations | ✗ | Spike DBs are throwaway |
| `importsource` | **✓** | Present in both — this is the one that matters |
| `plugins: [musicbrainz]` default | ✓ both | TAGR-05's defect exists at both versions |

---

## OD-4 — D-08's constraint stands; its worked example is corrected

D-08 says the normalisation script principally repairs **swapped `artist`/`album`**. All **764**
files in Phase 1's ffprobe fence were measured and **that defect is not present.**

- `album` carries a correct-ish issue string in **657 of 764** files.
- `artist` is a **placeholder**: `Mastermix` 197, `VA` 160, `Various Artists` 138, missing 77,
  `Various` 20.
- **107 files have no `album` at all** — which `beets`' own Discogs plugin documents as issuing
  **no query**: *"The search terms sent to the Discogs API are based on the artist and album tags of
  your tracks. If those are empty no query will be issued."*

**D-08's constraint is kept exactly:** minimum viable, `--dry-run` mode (and it is the *default*),
committed under `scripts/`, and **explicitly NOT the DJCC-01 tool**. Only the worked example is
replaced, by the three measured rules:

1. If `album` is empty/missing → derive `Mastermix Issue NNN` from the folder name (V3, 107 files).
2. Canonicalise `album`: strip ` WEB`, ` - Disc N`, `Vol.`, leading `Mastermix - `, trailing
   whitespace, `_` → ` ` (V5).
3. Set `artist` to a single consistent value across the folder (V2/V4) — **and record which value**,
   because the choice flips `va_likely` and therefore the query shape.

Touch nothing else. Not `title`, not `track`, not `TKEY`, not `EnergyLevel`.

---

## Axis one — the engine (beets vs wrtag)

Scored independently of axis two. **Criterion 6 is not met by a record that answers only this axis.**

| Question | beets 2.13.1 | wrtag v0.20.0 / v0.33.0 / v0.34.0 |
|---|---|---|
| Discogs backend exists | **YES** — `discogs` plugin asserted **loaded** on both arms via `beet version` (`discogs, fromfilename, importsource, musicbrainz`), not inferred from a config dump, which 03-04 measured cannot prove plugin load. It issued **291** live Discogs requests in plan 03-07 | **NO** — D-12 claim-audit rows 1 and 2, re-checked against primary source 2026-09-01 and **HOLDS**: no non-MusicBrainz backend exists in `cmd/` or `go.mod` at v0.20.0 or v0.34.0, and none of v0.30.0–v0.34.0's release notes add one |
| Strict match rate on the widened sample (backlog-weighted) | **27.08%** at `discogs.index_tracks: no` / `search_limit: 5` on the normalised arm (unweighted 25.00%, 6/24; most-favourable V6 bound 36.80%; "strict **and** correct" 22.80%). Loose 51.39% weighted, so the strict/loose gap is **7 folders / 29.2%** — [`03-DISCOGS-EVIDENCE.md`](03-DISCOGS-EVIDENCE.md) | **Not measurable, and not for want of trying** — a Discogs rate cannot be computed for a tool with no Discogs backend. The comparable MusicBrainz-only figure is what wrtag's own `researchlink` config concedes: the operator gets a URL |
| Path format renders at all | n/a | **NO, at all three tags** (plan 03-08). v0.20.0: renders, but `-1 - ` on 21 of 21 single-disc tracks, and a template execute error on multi-disc. v0.33.0 and v0.34.0: **refused at startup**, exit 2, `ambiguous format: multiple directories created for the same release`. One-line ablation (disc out of the directory) makes both current tags render correctly and byte-identically — see [`03-WRTAG-EVIDENCE.md`](03-WRTAG-EVIDENCE.md) |
| Behaviour on unmatched DJ content | **`beet import -A` (as-is) after normalisation** — a real mechanism inside the tool, with `--set albumtype=dj` and a `paths: albumtype:dj:` rule routing it clear of `Compilations/`. Under beets-flask the same primitive is a first-class UI affordance: an `autotag: "bootleg"` inbox. See § *Criterion 4* | **`WRTAG_RESEARCH_LINK` — a hyperlink for the human to resolve manually** (plan 03-08, quoted verbatim from `wrtag.yaml:73`). **Plus a side effect:** a real `move`/`copy` calls `tags.WriteTags(destPath, destTags, tags.Clear)` at `wrtag.go:267`, wiping every tag not in wrtag's computed set — **148 `TKEY` and 45 `EnergyLevel` files at stake** |
| Normalisation tool (D-13, binding either way) | **`scripts/normalise-dj-tags.py`** — dry-run by default, per-file NDJSON diff, 1 process for 335 files / 205 distinct value pairs, 0 lines of bespoke driver | wrtag's `metadata`: **540** invocations for 205 changed files, **no dry run and no flags at all** on `write`, 0 lines of output on success, 80 lines of bespoke `sh` — which wrote the artist value into the album field on **20 of 205** files while the field-loss gate scored it clean. [`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md) |

**Axis one verdict: the engine is beets 2.13.1.**

**The single fact that decided it, stated plainly rather than dressed up: wrtag has no
non-MusicBrainz metadata source, and this backlog's content is not in MusicBrainz.** That is
`PROJECT.md`'s original argument, it is D-12 claim-audit rows 1 and 2, and the audit re-checked it
against primary source on 2026-09-01 and found it **HOLDS**. The spike's job was to produce a
number rather than to relitigate a direction; **a number that confirms the direction is still a
number**, and it would have been dishonest to manufacture suspense the evidence does not support.

What the phase added beyond that argument is worth recording, because three of the four items were
not known when the direction was set:

1. **The Discogs advantage is real but far weaker than assumed.** T1 **fired**: 27.08% weighted
   strict, against a 40% threshold committed before any folder was sampled. It fires on every
   reading — unweighted 25.00%, most-favourable V6 bound 36.80%, strict-and-correct 22.80%. So
   beets wins axis one **while its headline advantage is under half of what would have been
   needed to call that advantage decisive on its own.** [`03-DISCOGS-EVIDENCE.md`](03-DISCOGS-EVIDENCE.md)
2. **The DMC stratum, which criterion 4 names explicitly, scored zero.** Loose 2 of 4, **strict
   0 of 4**. The two loose candidates are *Commercial Collection 326* and *318* against a folder
   that is *Commercial Collection 498*. `CLAUDE.md` records Discogs carrying *DMC Commercial
   Collection 350*; this backlog's issues are 498, 499, 233 and 234, and the catalogue does not
   reach them.
3. **wrtag was not merely out-argued, it was disqualified on measurement.** Criterion 3 ran at
   **three** tags on single-disc and multi-disc arms and **this repository's `WRTAG_PATH_FORMAT`
   works on none of them.** Both ends of the Renovate pin are broken.
   [`03-WRTAG-EVIDENCE.md`](03-WRTAG-EVIDENCE.md)
4. **T2 did not fire.** Rate limiting is not the obstacle: 21.8 minutes projected for the whole
   backlog against a 4-hour limb, and **zero HTTP 429** on both correct instruments. Recorded
   because a threshold that does *not* fire is as much a result as one that does, and because
   three of T2's originally-specified instruments turned out to be defective (DEF-03-05/06/07).

**Evidence artefacts this verdict rests on, by filename:**
[`03-DISCOGS-EVIDENCE.md`](03-DISCOGS-EVIDENCE.md) (criteria 1 and 2, T1 and T2),
[`03-WRTAG-EVIDENCE.md`](03-WRTAG-EVIDENCE.md) (criterion 3),
[`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md) (D-13),
[`03-SAMPLE.md`](03-SAMPLE.md) (the strata, weights and denominator),
[`03-NORMALISATION.md`](03-NORMALISATION.md) and [`03-PROBE-SMOKE.md`](03-PROBE-SMOKE.md).

**What this verdict does not claim.** It does not claim beets will tag this backlog well — T1
fired, so on Discogs it will not. It claims only that **of the two engines, one can reach this
content's metadata at all and the other structurally cannot**, and that the one that can also
renders the paths this repository asks for.

---

## Axis two — the front end (raw terminal prompt vs reviewable queue)

Scored independently of axis one. **Criterion 6 is not met by a record that answers only axis one.**

**What axis two actually compares, stated so its verdict is not later read as a narrower claim than
it is:** this is **not** only "terminal versus queue UI". beets-flask's arm carries a **policy
architecture** — per-inbox `autotag` policies of **`preview`**, **`auto`** and **`bootleg`** over
**one shared `library.db`**, which is precisely the Phase 5 structure — and the terminal arm carries
no equivalent. **Axis two therefore scores a raw interactive flow against a policy-carrying workflow
system, and the verdict is a verdict on that broader thing.**

Recorded as an axis-two risk before the trial: beets-flask's own `docs/limitations.md` states the UI
*"will get laggy"* past *"some hundred folder or so"* (#164, #175). **The backlog is 143 folders —
just under that stated pain threshold.** The 5-album trial cannot exercise it; it is carried as a
**Phase 9 handoff**, not as a measured finding.

| Question | beets-terminal (2.13.1) | beets-flask (2.12.0) |
|---|---|---|
| Wall-clock across the 5-album set | **NOT MEASURED** across the set — the arm ran on **1 of 5** albums (operator decision). The one row: **30 s** on `clean-1` | **NOT MEASURED.** The operator did not record wall-clock on any row. The only timing available is the tool's own *"Imported 39 seconds ago"* on the `bootleg` run, which is an import duration, **not** the sheet's operator wall-clock, and is deliberately not entered as one |
| Interventions | **1** on `clean-1` (pressed `A` on an 87.7% match); not measured on the four unrun albums | **NOT MEASURED** on any row. Qualitatively: `bootleg` took one `mv` and **zero candidate decisions**; the picker rows are unquantified |
| Context switches | **1** on `clean-1`; not measured on the four unrun albums | **NOT MEASURED.** Qualitatively, the crash (DEF-03-13) forced repeated browser reloads and a container-side log check that found nothing |
| Answer for content no source will match | **NOT EXERCISED** — `dj-no-match` was never run through this arm | **`bootleg` — measured, and it is the best result either arm produced.** On `VA-Mastermix.Crate.068-070-2025` (zero strict Discogs candidates per 03-07): one `mv`, zero decisions, **3 correct albums × 20 files**, `APIC` **60/60**, `TBPM` **60/60**, genre correct per crate, `COPY` with the source intact. **But `TRCK` 0/60** — no track tag at all, so playback order is undefined — and the same button shredded `Crate.071` into 20 single-track albums because that folder's `album` was empty, **with no UI signal distinguishing the cases** (DEF-03-16) |

**Axis two verdict — filled by plan 03-11**, **now against measured evidence rather than
against nothing**, and honouring the two constraints recorded at 03-10 close on what it may claim:
(a) **no wall-clock or intervention-count claim is available** — 9 of 10 rows are `not measured`
and only 1 of 5 albums is a paired cross-arm comparison; (b) T3 was unanswered at 03-10 and had to
be obtained from the operator first — **it now has been, and it FIRED** (see the threshold table).
The decision-relevant findings are the flask arm's blocking defect (DEF-03-13), its silent 9-file
loss with 4 mis-tagged tracks under a false safety assertion (DEF-03-14), its working
`UNDO IMPORT`, and `bootleg`'s result above. Evidence:
[`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md).

### The scoring sheet's own figures, quoted rather than summarised

Axis two must be scored on the sheet, so the sheet is quoted here including where it is empty.
**Nine of ten measurement rows read `not measured` or `not run`, and that is the finding, not a
gap in this record.**

| Sheet figure | beets-terminal (2.13.1) | beets-flask (2.12.0) |
|---|---|---|
| `wall_clock_s` | **30 s** on `clean-1`. `not run` on the other four (operator decision, AMENDMENT B-3) | **`not measured` on all five.** The only timing that exists is the tool's self-reported *"Imported 39 seconds ago"* on the `bootleg` run — an import duration, **not** the sheet's operator wall-clock, deliberately not entered as one |
| `interventions` | **1** on `clean-1` (pressed `A` on an 87.7% match). `not run` ×4 | **`not measured` on all five.** Qualitatively: `bootleg` took one `mv` and **zero** candidate decisions; the picker rows are unquantified |
| `context_switches` | **1** on `clean-1`. `not run` ×4 | **`not measured` on all five.** Qualitatively the crash forced repeated browser reloads and a container-side log check that found nothing |
| `outcome` | `imported` ×1, `not run` ×4 | `imported` ×5 |
| `stuck_points` (the operator's **one** contemporaneous verbatim, whole trial) | — | **"this is what i see if i move fast"** — said of having to outrun the crash to read the diff modal |

**So no quantitative ergonomics claim is made here, in either direction.** The sheet cannot support
one and never will now: 1 terminal row against 5 flask rows, with the ordering control exercised on
exactly one album. **A fabricated figure would be undetectable afterwards**, in a phase whose
premise is that this pipeline was built three times on unverified assumptions.

### What actually decided axis two, and it is not axis one's reasoning

Three things, in order of weight. **None of them is "beets won axis one, therefore its front end
wins".** Axis one is settled by *metadata source coverage*; axis two is settled by *what the
operator will open in week six and whether it can be trusted to write their files*. Different
questions, different evidence, and here they pull in opposite directions.

**1. T3 fired, in the operator's own words, and it is not close.** *"The command line interface,
I'm not a fan. It's fine for a bot to drive us, but for me, as a human, no."* T3's named instrument
is exactly this — an explicit written self-assessment — and this record does not get to discount it
because the alternative measured badly. **The raw terminal prompt is out.**

**2. The rc6 interactive picker is out too, on measurement, and the reason is not ergonomics.**
It accepted a 75% match that **dropped 9 of 31 audio files and wrote 4 tracks onto entirely
different songs**, while the UI asserted *"All tracks on disk found online"* **and** *"All tracks
online present on disk"* — both false, on the one album where the match was wrong (DEF-03-14).
Add an intermittent full-page crash on a cosmetic CORS-blocked thumbnail fetch that the backend
never logs (DEF-03-13), so the operator **cannot tell in advance whether a given run is safe**.
A front end whose job is to let a human review a match, and which makes a false falsifiable safety
claim precisely when the match is wrong, has failed at the thing it exists for.

**3. The one path that satisfies both is the policy-carrying inbox, and it is not a compromise —
it produced the best result either arm achieved.** `autotag: "bootleg"` on
`VA-Mastermix.Crate.068-070-2025`, a folder 03-07 measured at **zero** strict Discogs candidates:
one `mv`, **zero** candidate decisions, 3 correct albums × 20 files, `APIC` **60/60**, `TBPM`
**60/60**, `TALB` and `TCON` 60/60 with genre correct per crate, `COPY` with the source intact.
**It requires no interactive prompt at all**, which is why T3 does not touch it, and **it bypasses
the picker**, which is where every measured defect lives.

**Axis two verdict: the front end is beets-flask's policy-carrying inbox architecture — the
`preview` / `auto` / `bootleg` inboxes over one shared `library.db` — and explicitly NOT its
interactive candidate picker, which is disqualified on measured safety.**

### The tension this verdict does not smooth over

**It selects the tool with the worst measured safety record in the phase, on the operator's stated
preference. That is uncomfortable and it is stated rather than written around.** The resolution is
that *"beets-flask"* is not one thing: the trial measured a **policy architecture** and a
**candidate picker** bolted to it, and they scored oppositely. The architecture scored best; the
picker scored worst. Selecting the first while refusing the second is a real distinction with a
real mechanism behind it — an inbox's `autotag` policy is a config key, and `preview`/`auto`/
`bootleg` never present the picker's candidate-selection page at all.

**What this verdict therefore costs, and it is a genuine cost, not a rounding error:**

- **`bootleg` is unguarded.** The same button that produced the best result **shredded
  `Crate.071` into twenty single-track albums**, purely because that folder's `album` tag was
  empty — **with no UI signal distinguishing the two cases before the operator commits**
  (DEF-03-16). And **~40% of sampled Mastermix folders carry the bare, useless `album=Mastermix`**,
  so **the Crate 068–070 success is not representative of the Mastermix backlog.** The mitigation
  is already prescribed and already won D-13 independently: **normalise first
  (`scripts/normalise-dj-tags.py`), then import.** Running them in the other order produces a
  confidently wrong library shape silently, which `CLAUDE.md` § *Autotagging ceiling* names as
  worse than no match.
- **`bootleg` writes no `TRCK` at all** — `0/60` on the good run. Playback order is undefined.
  DEF-03-17 is the route to fixing that deterministically rather than by guess.
- **Two one-click bulk destructive affordances must never be used on this collection**:
  `DELETE IMPORTED FOLDERS`, keyed on an `Imported` badge that was set on the Lady Gaga folder
  while it was 9 files short, and `IMPORT BEST`, a bulk accept with no per-album review on a
  collection measured at a 1-in-6 wrong-strict-match rate (DEF-03-15). Neither was pressed or
  scripted at any point in this phase, deliberately.
- **rc6 is a release candidate and has been one for eight months.** *"Still in RC after eight
  months"* stops being a version number and becomes a durability finding about a tool this project
  would depend on.
- **The 144-folder case is untested and this verdict is not evidence about it.** Friction 5 stays
  **NOT EXERCISED**: beets-flask's own `docs/limitations.md` says the UI *"will get laggy"* past
  *"some hundred folder or so"*, the backlog is just under that, and five albums cannot test it.
  Carried as a **Phase 9** risk (see § *Handoff to Phase 5, 6 and 7*).

**What is genuinely better in this arm and must not be lost:** a **working `UNDO IMPORT`**
(verified by use — see § *AMENDMENT — 2026-09-04, plan 03-11* § 5, because it contradicts a
standing project constraint); per-folder persistent `Tagged`/`Imported` badges, which are exactly
the resume signal a 144-folder run needs against the abandoned-halfway failure mode — **read as
*"an import ran"*, never as *"the import was complete and correct"***; `copy`-only, so it
structurally cannot do the dangerous thing the estate's real beets config (`import.move: yes`)
currently does; and a UI that editorialises match quality (*"Really? This is what you're going
with?"* on a 44% match), which the terminal arm has no equivalent of.

---

## The D-12 claim audit

Each row of `PROJECT.md`'s beets-vs-wrtag head-to-head re-checked against a primary source on
2026-09-01. Verdicts: **holds** / **changed** / **falsified**.

**Row count, stated so a counter is not misled:** the audit covers **16 numbered claims**, three of
which (3a, 3b, 3c) are sub-rows expanding claim 3 — **19 physical rows in total**. Rows **3, 3a, 3b,
3c, 5, 6, 8 and 15** carry verdicts of falsified or changed and are what this phase's evidence is
measured against.

| # | PROJECT.md claim | Current primary source | Verdict | One-line impact |
|---|---|---|---|---|
| 1 | wrtag: *"Metadata sources: **MusicBrainz only**"* | README §"Available operations", §Configuration; no non-MB backend in `cmd/` or `go.mod` | **HOLDS** | **This is the argument that does all the work, and it survives intact.** |
| 2 | *"Non-MusicBrainz DJ releases: [wrtag] **Cannot.** No non-MB source exists or is planned"* | Same; v0.30.0–v0.34.0 changelogs add no source backends | **HOLDS** | Unchanged |
| 3 | *"Repairing existing wrong tags: [wrtag] **No facility.**"* | `cmd/metadata/` exists at **v0.20.0 and v0.34.0**; ships in the container | **FALSIFIED** — as D-12 states | wrtag *can* write tags. **But see row 3a** — the capability is far narrower than the falsification implies |
| 3a | *(D-12's inference)* `metadata` is *"plausibly a direct competitor to the mutagen script"* | `cmd/metadata/main.go` `cmdWrite()`: builds one literal `map[string][]string` and applies it to **every** path via `iterFiles`; **no `-dry-run`, no diff, no field-to-field move**; only flags are `-log-level`, `-properties` (read), `-index`/`-type`/`-desc`/`-mime-type` (images) | **CHANGED — materially weaker than claimed**; **MEASURED 2026-09-04, plan 03-09** | An `artist`→`album` remap needs one `read` + one `write` **per file**, in a shell loop, writing blind. D-13's bake-off is still worth running (it is cheap) but the reviewability requirement in D-08 is unmet by `metadata` unless wrapped. **Measured, no longer an inference:** 205 changed files cost **540** invocations (335 `read` + 205 `write`), the loop is **134 lines / 80 code lines** of bespoke `sh`, `metadata write` accepts **no flags at all** and prints **nothing** on success, and the loop written for this bake-off wrote the artist value into the album field on **20 of 205** files while `diff-music-tags.sh` scored it `FIELDS_DROPPED = 0`. See [`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md) |
| 3b | *(new, not in PROJECT.md)* what `metadata write` does to unlisted tags | `tags.WriteTags(path, t, 0)` — flag `0`, **not** `tags.Clear` | **NEW — favourable to `metadata`**; **CONFIRMED EMPIRICALLY 2026-09-04, plan 03-09, with a boundary** | `metadata write` **merges**; it will not silently drop `TKEY`/`EnergyLevel`. Confirm empirically with `diff-music-tags.sh` — do not take this from source alone. **Confirmed, no longer a source read:** `FIELDS_DROPPED = 0` on both the `audio_md5` and the path-keyed join, `TKEY` **40 → 40**, `EnergyLevel` **20 → 20**, `TBPM` **110 → 110**, values byte-identical to the untouched twin, with live `ffprobe` agreeing on every cell. **The boundary the source read did not imply:** the merge holds only **inside the ID3v2 container** — the same `save()` promoted 205 files from ID3v2.3 to v2.4 (`TYER`→`TDRC` on 155, invisible to `ffprobe`), rewrote 175 ID3v1 blocks, **created an ID3v1 block on 30 files that had none**, and re-serialised the APEv2 tag on 14. Nothing was lost; nothing was requested, reported or preventable either. See [`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md) |
| 3c | *(new)* what a real `wrtag move`/`copy` does to unlisted tags | `wrtag.go:267` — `tags.WriteTags(destPath, destTags, tags.Clear)` | **NEW — decisive for TAGR-02** | **A real wrtag run WIPES every tag not in its computed set.** 148 `TKEY` and 45 `EnergyLevel` files in `dj-mixes` would be destroyed without a configured `keep` rule. This belongs in the criterion 4 record |
| 4 | *"beets: `import -A`, `edit`, `modify` (`+=`/`-=` since 2.13.0), `zero`, `write`, query language"* | beets changelog 2.13.0 confirms `modify +=`/`-=` and the `edit` album-YAML header | **HOLDS** | Unchanged. Note `+=`/`-=` is **absent from beets-flask rc6** (pinned 2.12.0) |
| 5 | *"Current version: beets 2.13.1 (29 Jul 2026) / wrtag v0.33.0 (11 Jul 2026)"* | PyPI: beets 2.13.1 still latest 2026-09-01. Docker Hub: **wrtag v0.34.0, 26 Aug 2026** | **CHANGED** | Criterion 3 runs at v0.20.0, v0.33.0 **and** v0.34.0 (OD-5), so D-01 is honoured as written and the question is settled by measurement |
| 6 | *"Container: `lscr.io/linuxserver/beets:2.13.1` / `sentriz/wrtag:v0.33.0`"* | Both exist; LSIO `2.13.1` **floats** across ls-revisions | **CHANGED (sharpened)** | Pin `2.13.1-ls349`. The floating-2-part-tag hazard is already recorded in project MEMORY (Renovate deploy drift) |
| 7 | *"Bulk re-tag of an organised library: `wrtag sync` — genuinely better, this is wrtag's standout feature"* | README §"Re-tagging in bulk"; `sync -dry-run`, `-num-workers`, `-age-older`; treelock | **HOLDS** | Unchanged — and irrelevant to this phase, which has no organised library to re-tag |
| 8 | *"Path-format safety: [wrtag] validates the format can't collide two tracks/releases at startup"* | v0.20.0 `Validate` builds **single-medium** synthetic releases only; v0.30.0 adds *"validations for multi disc releases"* | **CHANGED — the claim is version-dependent** | At v0.20.0 the validation is **strictly weaker than advertised**, and that is precisely why the repo's broken format passed startup for eight months |
| 9 | *"beets Web UI: the `web` plugin is a library browser, not an importer"* | beets docs `plugins/web` | **HOLDS** | Which is exactly why axis two needs beets-flask |
| 10 | *"wrtagweb: real import queue with notify + confirm — genuinely better"* | README §"Tool `wrtagweb`", `POST /op/{copy,move,reflink}` with `mbid`/`confirm` | **HOLDS** | **But** it can only confirm *MusicBrainz* candidates. For bucket C its notify-and-confirm loop has nothing to offer |
| 11 | *"`WRTAG_RESEARCH_LINK` … wrtag's answer was 'here is a link, go look it up yourself'"* | `wrtag.yaml:73` + README §researchlink; v0.32.0 added *"researchlink: add mbid data"* and *"render MBID only on positive match"* | **HOLDS** | Quote it verbatim in the criterion 4 record — it is the cleanest statement of what "the content lives outside the tool" looks like in practice |
| 12 | *"beets `library.db` … this repo has **two**"* | 01-02: there are **four**; `soulbeet`'s does not exist | **FALSIFIED (already corrected in Phase 1)** | Carried forward for completeness; no Phase 3 impact |
| 13 | *"beets 2.13.1 … The LSIO image handles [Python >=3.10,<3.15]"* | PyPI `requires_python: <3.15,>=3.10`; LSIO base `baseimage-alpine:3.23` | **HOLDS** | — |
| 14 | *"beets ≥ 2.4.0: `musicbrainz` must be listed explicitly in any customised list"* | `config_default.yaml` v2.13.1 line 10: `plugins: [musicbrainz]` | **HOLDS** | Still true at 2.13.1 and at 2.12.0. beets-flask's own v1.2.0 release notes carry the same warning |
| 15 | *"Bulk import of thousands: [beets] works, but interactive by nature"* | beets-flask `docs/limitations.md`: *"once you hit some hundred folder or so, this will get laggy"* (#164, #175) | **CHANGED — a new, adverse fact for axis two** | The backlog is **143 folders**, which is *just under* the stated pain threshold. Record it; it is the single strongest argument against beets-flask and it was not previously known |
| 16 | *"beets-flask … one shared `library.db` across N policy-carrying inbox folders"* | `docs/configuration.md`: config is `config/beets/config.yaml` (a **normal beets config**, so one `library`) + `config/beets-flask/config.yaml` defining `gui.inbox.folders.*` each with its own `autotag` policy | **HOLDS — confirmed from primary source** | Criterion 7's central claim is verified. This *is* the Phase 5 structure |

**Capability found during the audit that `PROJECT.md` does not mention:** beets-flask's
`autotag: "bootleg"` inbox mode — *"Import as-is using the meta data of files, and group albums
using the metadata… Effectively `beet import ... --group-albums -A`"*. That is a **first-class UI
affordance for exactly the content criterion 4 asks about**, and it belongs in the axis-two score.

---

## Criterion 4 — what happens to Mastermix / DMC / Music Factory content

Not a measurement; **a statement this record must contain.** A tagger whose answer is "that content
lives outside the tool" has failed the requirement that matters most here.

| Under | The unmatched-content answer | Answer confirmed? |
|---|---|---|
| beets (terminal) | `beet import -A` (as-is) after normalisation; `--set albumtype=dj` + a `paths:` rule routes it out of `Compilations/` | **CONFIRMED AS A MECHANISM; NOT EXERCISED END-TO-END, AND THE DIFFERENCE IS STATED RATHER THAN GLOSSED.** The primitive is real and present at 2.13.1: `-A` is beets' as-is import and `PROJECT.md` § *What NOT to Use* already records the constraint that makes it correct — *"`-A` is correct **after** normalisation, not instead of it"*. **What this phase measured** is the two halves separately: the normalisation half ran on real files (335 MP3, 205 changed, per-file NDJSON diff, `FIELDS_DROPPED = 0`, [`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md)), and the as-is import half ran through beets-flask's `bootleg` inbox, which its own docs define as *"effectively `beet import ... --group-albums -A`"* — **the same beets primitive reached through a different front end** (3 correct albums, `APIC` 60/60, `TBPM` 60/60). **What was NOT run is `beet import -A` from the terminal on a DJ folder**: the `dj-no-match` album was never put through the terminal arm (AMENDMENT B-3, operator decision). So the mechanism is confirmed by construction and by its flask-side equivalent, **not** by a terminal-arm observation, and this record does not claim otherwise. The `--set albumtype=dj` + `paths:` routing is likewise a documented beets facility that this phase did not exercise — **Phase 6 owns proving it** |
| beets-flask | An inbox with `autotag: "bootleg"` — *"Import as-is using the meta data of files, and group albums using the metadata… Effectively `beet import ... --group-albums -A`"* | **CONFIRMED, AND BOUNDED** (plans 03-10 tasks 2 and 3). Present in rc6 from primary source (`schema.py:110`); the shipped example config never mentions it. **Measured twice with opposite outcomes on the same button.** On `Crate.068-070` (`album` populated): 3 correct albums × 20, `APIC` 60/60, `TBPM` 60/60, one `mv`, zero decisions — but `TRCK` **0/60**. On `Crate.071` (`album` empty): **one 20-track release became twenty single-track albums**, `album` empty, `track` `00`, no album directory level, **no error and no prompt**. `--group-albums` groups on the metadata that is *there*, so **bootleg is a fast path for already-correctly-grouped content, not an answer for untagged content** — and ~40% of sampled Mastermix folders carry the bare `album=Mastermix` (DEF-03-16). It is still a first-class affordance the terminal arm has no equivalent of. Vindicates PROJECT.md's *normalise first, then import* |
| wrtag | **`WRTAG_RESEARCH_LINK` — a hyperlink to a Discogs search, for the human to resolve manually** | **CONFIRMED** (plan 03-08). Quoted verbatim from `wrtag.yaml:73` in [`03-WRTAG-EVIDENCE.md`](03-WRTAG-EVIDENCE.md) § *wrtag's answer for unmatched content*. wrtag has no non-MusicBrainz backend at v0.20.0 or v0.34.0 and none of v0.30.0–v0.34.0's release notes add one, so the link is a hyperlink, not an integration |
| wrtag (side effect) | A real `move`/`copy` calls `tags.WriteTags(dest, destTags, tags.Clear)` — **all tags not in wrtag's computed set are wiped** unless a `keep` rule is configured | **CONFIRMED IN SOURCE ONLY — NOT OBSERVED AT RUNTIME** (plan 03-08). `wrtag.go:267` read at v0.34.0 with its `if !op.CanModifyDest() { continue }` guard at 259; `tags.Clear` is `taglib.Clear`, documented at its definition as *"all existing tags not present in the new map should be removed"*. **The dry runs could not exhibit it**: `-dry-run` makes `CanModifyDest()` false so line 267 is never reached — and separately, `logTagChanges` iterates `for k := range after`, so a tag present in the source and absent from wrtag's set **is never logged even at DEBUG**. Empirical confirmation needs a real `move` onto scratch with a `TKEY`-bearing folder, which D-20 forbids in Phases 1–3 |

The verbatim quote from `stacks/selfhosted/music/wrtag.yaml:73`:

```
WRTAG_RESEARCH_LINK=https://www.discogs.com/search/?q={query},https://musicbrainz.org/search?query={query}
```

**Whoever configured that line already knew this content lives on Discogs, and wrtag's answer was to
hand the operator a URL.** Criterion 4 calls that shape of answer a failure.

And the path format it sits beside, `wrtag.yaml:71`, quoted verbatim because Phase 4's TAGR-03 will
cite it:

```
WRTAG_PATH_FORMAT=/music/library/Compilations/{{ .Release.Title | safepath }} ({{ .Release.Date.Year }})/{{ if gt (len .Release.Media) 1 }}Disc {{ .Media.Position }}/{{ end }}{{ pad0 2 .Track.Position }} - {{ if .IsCompilation }}{{ artistsString .Track.Artists | safepath }} - {{ end }}{{ .Track.Title | safepath }}{{ .Ext }}
```

**The decisive TAGR-02 fact, recorded now as a prediction to be confirmed:** a real `wrtag
move`/`copy` calls `tags.WriteTags(destPath, destTags, tags.Clear)` at **`wrtag.go:267`**, which
**wipes every tag not in wrtag's computed set**. **148 `TKEY` and 45 `EnergyLevel` files in
`dj-mixes` are at stake.** Confirmation status: ~~PENDING — filled by plan 03-08~~ →
**CONFIRMED IN SOURCE ONLY, 2026-09-03, plan 03-08.** Read at v0.34.0 with its guard, and
`tags.Clear`'s own definition quoted. **Not observed at runtime and not observable by the dry
runs** — see the criterion 4 table row above and § *AMENDMENT — 2026-09-03, plan 03-08* below.

### The answer, stated concretely for Mastermix, DMC and Music Factory under the named winner

Criterion 4 requires a named tagger and a concrete statement of what happens to this content under
it. **The named winner is beets, met through beets-flask's policy-carrying inboxes.** Here is what
happens to the DJ-service content, in the order it happens, with the measured number behind each
step:

1. **It is normalised first, by `scripts/normalise-dj-tags.py`.** Not optional and not a
   preference: `bootleg` groups on the metadata that is *there*, and this content's defining
   characteristic is that its metadata is absent or wrong. The three committed rules derive
   `Mastermix Issue NNN` from the folder name where `album` is missing (V3, 107 files),
   canonicalise noisy `album` strings (V5), and set one consistent `artist` per folder (V2/V4).
   D-13 named this tool **binding regardless of which engine won**. It touches nothing else — not
   `title`, not `track`, not `TKEY`, not `EnergyLevel`.
2. **Then it is imported as-is, and it keeps its own tags.** Through the `bootleg` inbox — *"Import
   as-is using the meta data of files, and group albums using the metadata… Effectively
   `beet import ... --group-albums -A`"* — or equivalently `beet import -A` from the terminal.
   **Measured on a real DJ folder Discogs scored at zero strict candidates:** 3 correct albums ×
   20 files, embedded cover art **60/60**, `TBPM` **60/60**, genre correct per crate, source
   intact. That is what "the tool owns this content" looks like concretely: one `mv`, zero
   decisions, nothing lost.
3. **Autotagging is not attempted on it, and that is a decision rather than a failure.** T1 fired
   at **27.08%** and the **DMC stratum scored strict 0 of 4** — the catalogue does not reach
   issues 498, 499, 233 and 234. `CLAUDE.md` § *Autotagging ceiling* already calls a confident
   wrong match worse than no match, and this phase measured that twice independently: a Mastermix
   issue matched to a 2006 Specialten DVD on a ten-track coincidence (DEF-03-08), and four tracks
   written onto entirely different songs under a UI asserting nothing was missing (DEF-03-14).
4. **It is routed away from `Compilations/`** by `--set albumtype=dj` plus a `paths: albumtype:dj:`
   rule, so a DJ release never lands among genuine various-artist albums. Mechanism confirmed,
   **not exercised in this phase — Phase 6 owns proving it.**
5. **Track order, the one thing this leaves genuinely open, has a measured route.** `bootleg`
   wrote `TRCK` **0/60**, so playback order is undefined. DEF-03-17 found that
   `mastermixdj.com` publishes the running order as a plain HTML table with per-track BPM and
   duration — every BPM matching the embedded `TBPM` and every duration matching disk within ~1 s
   on the one page checked — which makes track numbers **assignable deterministically by duration
   match rather than guessed.** **One product page. Coverage across the 99 Mastermix folders is
   unproven and is Phase 4 research, not a claim made here.**

**The phrase "that content lives outside the tool" appears in this record only as the named failure
mode, and it is what wrtag's answer is.** `WRTAG_RESEARCH_LINK` hands the operator a Discogs URL to
resolve by hand — and whoever configured that line **already knew this content lives on Discogs**.
The winner's answer is a mechanism inside the tool, run over the whole tree, by the single writer
the project's core value asks for.

**Stated honestly, because the requirement is about the whole tree and not only the easy part:**
this answer is good for DJ-service content whose tags are already grouped correctly, and it is
**unguarded** for the ~40% of sampled Mastermix folders carrying a bare `album=Mastermix`. Step 1
is what converts the second group into the first, which is exactly why the order of steps 1 and 2
is load-bearing and not stylistic.

---

## D-13 — the stated prediction, recorded before the bake-off

Stated honestly, before the measurement, so the bake-off is not theatre:

wrtag's `metadata` tool applies **one literal key→value map to every path** in the invocation, has
**no dry-run and no diff**, and offers **no field-to-field move primitive**. **The reviewability
requirement in D-08 is therefore not met by it without a wrapper.** On this project's own standing
rule — *verify with a second independent instrument before you write it down* — that is close to
decisive.

**The bake-off runs anyway**, for three reasons: D-13 asks for it; it is cheap; and `metadata`'s
`go.senan.xyz/taglib` backend **may handle the 134 WAV files better than mutagen does** — which
would be a genuine, unanticipated reason to prefer it for one stratum.

| Axis | mutagen script | wrtag `metadata` | Measured result |
|---|---|---|---|
| Dry-run | **Yes, and it is the default** | **No.** No flag exists on `write` | **CONFIRMED, observed.** `metadata write -h` errors `stat -h: no such file or directory` — `write` takes no flags at all. Every one of this plan's 205 MP3 writes and 134 WAV writes was blind |
| Reviewable diff before writing | Yes, per-file | No | **CONFIRMED, observed.** mutagen: 292 NDJSON records (MP3) and 134 (WAV), each with `old`/`new`. `metadata`: `driver-writes.log` is **0 lines** across 205 successful writes — it prints nothing on success |
| Per-file distinct values in one invocation | Yes | **No** — one literal map to every path | **CONFIRMED, observed.** mutagen: 1 process for 335 files / 205 distinct value pairs. `metadata`: **540** invocations (335 `read` + 205 `write`), exactly two per changed file |
| Field-to-field move | Yes (read then write) | **No primitive** | **CONFIRMED, observed.** Rule 2 canonicalises the album it just read on 155 files; `metadata` needs the value computed outside the tool and handed back as a literal, which is the sole reason its read pass exists |
| Preserves unlisted tags | Yes | Yes — `WriteTags(path, t, 0)`. **Verify empirically** | **A3 CONFIRMED, with a boundary.** Inside ID3v2 `metadata` merges: `FIELDS_DROPPED` 0 on both joins, `TKEY` 40→40, `EnergyLevel` 20→20, `TBPM` 110→110, values identical, `ffprobe` agreeing. **Outside ID3v2 it does not:** ID3v2.3→2.4 on 205 files, `TYER`→`TDRC` on 155, ID3v1 rewritten on 175 and **created on 30**, APEv2 re-serialised on 14. No loss (audio identical 335/335, no APE item lost) but none of it requested, reported, preventable or visible to the gate. mutagen: frame set moved on exactly 40 files = the 40 frames its rules created, ID3v1/APEv2/ID3v2-version untouched |
| Formats | MP3, FLAC, WAV (partial) | MP3, FLAC, **WAV** and 30+ others via taglib | **OVERTURNED, and by more than predicted.** MP3: both 335/335. **WAV: `metadata` 130 of 134; the committed mutagen script 0 of 134** (`TypeError: … not a Frame instance` on every file — `mutagen.File(easy=True)` on WAVE returns a raw frame-id-keyed `ID3`, not an EasyID3 map). `metadata`'s 4 failures are files whose ID3 text frames carry non-ASCII; it throws inside taglib-on-WASM and can neither read nor write them. **The path hypothesis was falsified** by an ASCII rename. FLAC unexercised on both — neither sample contains any |
| Committed, versioned, auditable | Yes (`scripts/`) | The loop would be; the tool is not | **CONFIRMED, observed.** mutagen: **0** lines of bespoke driver — the committed 948-line script is the tool, sha-verified before every run. `metadata`: **134 total / 80 code lines** of bespoke `sh` per arm, before any rule logic, and this run proved they need review — 20 of 205 files were written wrong by that shell on the first attempt |

**Prediction:** the mutagen script wins on reviewability; `metadata` may win on WAV. **Verdict:**
~~PENDING — filled by plan 03-09~~ → **THE NORMALISATION TOOL IS THE COMMITTED MUTAGEN SCRIPT,
`scripts/normalise-dj-tags.py`, AND THAT HOLDS REGARDLESS OF WHICH ENGINE WINS THE MAIN
DECISION.** Not split by stratum. The prediction **held on reviewability** — demonstrated rather
than argued: the `metadata` arm's own driver wrote the artist value into the album field on 20 of
205 files and `diff-music-tags.sh` scored that run `FIELDS_DROPPED = 0`. It was **overturned on
WAV**, by a wider margin than it anticipated (130 written against 0), and the overturn is
nonetheless **not** carried into the verdict, because the mutagen failure is a three-line defect in
*our* script that mutagen's own WAVE API resolves on the first attempt — including on the exact
file `metadata` cannot open — while `metadata` hard-fails on 3.0% of the stratum and would cost two
tools for one job. Full evidence, including the cost this verdict leaves unpaid:
[`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md).

---

## AMENDMENT — 2026-09-03, plan 03-08: criterion 3 measured

**Nothing in this section changes T1, T2, T3, the 40% threshold value, the estimator definition
or any denominator.** Criterion 3 is not one of the pre-committed thresholds; it is a
disqualifier whose outcome this document was always going to receive. The original wording of
every paragraph below is left standing above and below this section so a `git log -p` diff shows
what was corrected and when. Full evidence:
[`03-WRTAG-EVIDENCE.md`](03-WRTAG-EVIDENCE.md).

**Three statements elsewhere in this document, and in `PROJECT.md`, `CLAUDE.md` and
`03-RESEARCH.md`, are superseded by measurement:**

| Superseded statement | Where it appears | What was measured, 2026-09-03 |
|---|---|---|
| *"`v0.33.0` — the existing path format is already correct for it"* | `CLAUDE.md` § *What NOT to Use* | **FALSIFIED.** v0.33.0 and v0.34.0 **refuse this repo's format at startup** — `validate: ambiguous format: multiple directories created for the same release`, exit **2**, before any file is read. Four arms, byte-identical refusal text |
| *"wrtag v0.30.0+ … Breaking. **Not used by this repo's format**"* | `PROJECT.md` § *Version Compatibility*; echoed in `03-RESEARCH.md` State of the Art as *"no path-format change"* | **HALF TRUE, AND THE WRONG HALF.** The v0.30.0 **migration table** (`.TrackNum`, `len .Tracks`, `.Tracks`) genuinely does not apply — this repo's format uses none of them. What was missed is the **new multi-disc validation shipped in the same release**, which rejects the format outright |
| § *Handoff to Phase 4* below: *"The real defects are that v0.20.0 **forces `d.Track.Position = -1`** … and that **`.Media.Position` is absent from v0.20.0's `Data` struct**"* | this document, § *Handoff to Phase 4* | **CORRECT AND CONFIRMED, BUT INCOMPLETE.** Both defects were demonstrated at runtime — 21 of 21 single-disc paths render `-1 - `, and the multi-disc arm errors with `can't evaluate field Media in type pathformat.Data`. What the paragraph does not say is that the **newer versions do not run at all**. Phase 4 must not read it as "unpin and it works" |

**The corrected one-sentence statement for TAGR-03 to cite:** *this repository's
`WRTAG_PATH_FORMAT` works on none of v0.20.0, v0.33.0 or v0.34.0 — it renders `-1 - ` on every
single-disc track and hard-errors on multi-disc at v0.20.0, and is refused at startup by both
current tags — and the sole cause of the startup refusal is the `Disc N/` **subdirectory**, proven
by an ablation that changes nothing else and validates at both current tags.*

**Also corrected:** `renovate.json5:91` names `.Release.Date.Year`, `.Release.Media`,
`.Track.Position` and `artistsString`. § *Handoff to Phase 4* below already retracts two of the
four as innocent. **All four are innocent** — all four exist at v0.20.0, three of them
demonstrably so in the rendered output of arm 1. The one field genuinely absent from v0.20.0 is
**`.Media`**, which the rule does not name.

**Confirmations, not corrections** — recorded so the claim audit's verdicts are not re-litigated:

| Claim | Outcome |
|---|---|
| D-12 row 8: v0.20.0's `Validate` builds single-medium synthetic releases only, *"which is precisely why the repo's broken format passed startup for eight months"* | **CONFIRMED** from source: v0.20.0 `pathformat.go:143-159` does exactly one `release.Media = append(...)` |
| D-12 row 3c: a real `move`/`copy` wipes unlisted tags via `tags.Clear` | **CONFIRMED IN SOURCE ONLY.** See the criterion 4 table above; the dry runs structurally could not exhibit it, and `logTagChanges` structurally could not log it |
| D-12 row 11: `WRTAG_RESEARCH_LINK` is wrtag's answer for unmatched content | **CONFIRMED**, quoted verbatim |
| D-12 row 5 / OD-5: v0.34.0 exists and is a path-format no-op against v0.33.0 | **CONFIRMED** on three instruments — byte-identical refusals, byte-identical rendered path sets under the ablation, and a changelog whose only breaking change is `deps: bump to go1.27` |

**One methodological finding worth more than any of the above, carried to every later plan in
this phase:** the disc class of a wrtag arm **is not a property of the source folder**. A
21-file, no-`disc`-tag, `track=N/21` album was resolved by MusicBrainz to a **two-medium vinyl
release** and hard-errored on `.Media.Position` on the very first, unpinned run. wrtag queries
with `limit=1` and takes what comes back. Any experiment that means to hold the disc class
constant must pin the release MBID; one that does not is measuring MusicBrainz's mood.

---

## AMENDMENT — 2026-09-04, plan 03-07: criteria 1 and 2 measured

**Nothing in this section changes T1's or T2's threshold VALUE, the estimator definition, or which
folders are in the population.** The original wording of every paragraph above is left standing so
a `git log -p` diff shows exactly what moved: the `Tested?`/`Returned` cells, the weight table's
`PENDING` cells, and this section. Full evidence:
[`03-DISCOGS-EVIDENCE.md`](03-DISCOGS-EVIDENCE.md).

### 1. The denominator is **144**, not 143 — a measured fact corrected by a better instrument

§ *Denominators, committed before the run* above commits **143 folders (≈7,726 files)**, on
`nzb/music` = 23 folders / 275 files. **Plan 03-03's variant survey measured 24 and 277** with two
independent instruments — a live audio-extension `find` on LXC 100, and Phase 1's QUAL-01 capture
grouped by scan root. The corrected split is `unsorted` 120 / 7,451 + `music` 24 / 277 =
**144 folders / 7,728 audio files**.

**T1's 40% threshold value is unaffected, and so is T2's 4-hour limb.** The correction was made
*before any rate or timing existed*, by a better instrument, and it moves the extrapolation base by
0.7%. The `backlog_weight` column in § *The estimator T1 is tested against* and every figure in
§ *Extrapolation* of the evidence file use **144**. The exact fractions are 37/144, 39/144, 11/144,
0/144, 43/144, 14/144.

### 2. The 429 instrument is substituted — the threshold VALUE is unchanged

T2's second limb is *"any observed HTTP 429"*. The **instrument** named for it in
`03-07-PLAN.md` (lines 275, 333 and 414) is `grep -c '429'` on the probe stderr, required to
return 0. **That instrument cannot return 0 and is not measuring HTTP 429** (DEF-03-05).

Measured on this plan's six cells: the bare substring form returns **25 on every single cell**,
*including the two MB-only cells that issued zero Discogs requests*. It matches the probe's own 24
per-folder progress labels (`0 x429`) plus its summary label (`discogs 429 responses: 0`), and in
03-06 it also matched the Discogs release ID `3542996`.

Had it been used as written it would have **falsely fired a pre-committed threshold limb on all six
cells** and triggered a re-run of each — 150–260 requests apiece against a 60/min ceiling — on the
evidence that the probe printed the digits "429" while reporting it had seen none.

**The substituted instruments, both already available and both used:**

```bash
grep -oE 'HTTP/1\.1" [0-9]{3}' <stderr> | sort | uniq -c   # the HTTP STATUS COLUMN
#   plus the probe's in-process counter, scoped to api.discogs.com:
#   discogs 429 responses:        0
```

**This is an instrument correction, not a threshold move.** The limb still reads *"any observed
HTTP 429"*; only the way 429 is counted changed, and it changed to something that actually counts
429s. Both instruments returned **0** on every cell.

### 3. A related instrument correction: the request counter over-counts 2×

T2's named cross-check is `grep -c 'api\.discogs\.com'` on the stderr. `urllib3` emits **two** lines
per request — `Starting new HTTPS connection` and the response line — so the bare form returns
**150** where the true count is **75**. Counting only lines carrying the HTTP status
(`grep -cE 'api\.discogs\.com.*HTTP/1\.1"'`) reproduces the probe's in-process counter exactly.
**M = 3.125 requests per folder**, not the 6–11 that 03-RESEARCH.md predicted.

### 4. Recorded, not corrected: MusicBrainz throttles with 503

Neither limb of T2 names it and neither is affected, but it is the dominant term in the wall-clock
and any later plan watching only for 429 will see a clean run while MusicBrainz throttles it: the
headline cell logged **44 × HTTP 503, every one from `musicbrainz.org`, zero from
`api.discogs.com`**. It is why projected wall-clock (21.8 min) is ~3× the pure-API floor
(7.43 min).

### 5. Recorded, not corrected: D-05 strict admits confident wrong matches

D-05 requires a track-count agreement; it does not require the release to be right. **One of the
six strict hits is a wrong release** — `Mastermix_Issue_412` matched Discogs `1534659`
*"Specialten Issue 14"*, a 2006 DVD, at 31.2%, because both have ten tracks. **T1 is scored on
D-05 as written (27.08%)**; the "strict and correct" reading (**22.80%** weighted) is recorded
beside it and fires the threshold just as clearly. The proximate cause is that
`Mastermix_Issue_412`'s album tag reads bare `Issue 412` — the same defect class 03-SAMPLE.md found
when it reclassified `album == artist` out of V1.

### 6. Criterion 4 gains a measured fact

**Not one of the four DMC folders produced a Discogs candidate that survived a track-count check**
(loose 2/4, strict **0/4**). The two loose candidates are *Commercial Collection 326* and *318*
against a folder that is *Commercial Collection 498*. `CLAUDE.md` records Discogs carrying *DMC
Commercial Collection 350*; this backlog's issues are 498, 499, 233 and 234, and the catalogue does
not reach them.

---

## AMENDMENT — 2026-09-04, plan 03-09: D-13 measured, A3 settled, the WAV question answered

**Nothing in this section changes T1, T2, T3, the 40% threshold value, the estimator definition or
any denominator.** D-13 is not one of the pre-committed thresholds; it is a bake-off whose outcome
this document was always going to receive, and its **prediction text above is byte-identical to
threshold commit `137b6d9e92cb44d9c6a48b3963bb33fe0194622f`** — asserted with
`git show 137b6d9e…:03-DECISION.md | sed -n '/^## D-13/,/^---$/p'` diffed against the current file,
which returns zero lines of difference. Only `PENDING` result cells were replaced. Full evidence:
[`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md).

### 1. The prediction is scored honestly: held on one half, overturned on the other

**Held — reviewability.** And it was demonstrated rather than argued. The `metadata` arm's driver
silently wrote the **artist value into the album field on 20 of 205 files** on its first run
(`Mastermix.Issue.421.2021` ×10 and `Mastermix_Issue_415` ×10 — exactly the artist-only rows), and
**`diff-music-tags.sh` scored that run `FIELDS_DROPPED = 0`**. `metadata write` has no dry run in
which to have caught it, and a correct-shaped wrong value drops no field. The cause was a POSIX
subtlety — TAB is an IFS *whitespace* character, so `IFS=$TAB read -r p album artist` collapses the
empty column — and the run was repeated from a re-materialised, byte-identical tree.

**Overturned — WAV, by more than the prediction anticipated.** Not *"`metadata` may handle WAV
better"*: `metadata` wrote **130 of 134** WAV files and the committed mutagen script wrote **0 of
134**, failing `TypeError: … not a Frame instance` on every one.

### 2. The overturn is recorded and then argued down, not suppressed

The verdict is still the mutagen script, and the three measured reasons are: the WAV failure is a
defect in **our own script** — `mutagen.File(path, easy=True)` on a WAVE returns a raw frame-id-keyed
`ID3`, not an EasyID3 map — which mutagen's own `WAVE()` API resolves on the first attempt on all
three probe classes, **including the exact non-ASCII file `metadata` cannot open**; `metadata`
hard-fails on **4 of 134 (3.0%)** of the stratum; and adopting it for one stratum costs two tools,
two drivers and two review surfaces for one job, against a core value of *exactly one pipeline that
someone owns*.

**The cost this leaves unpaid is carried, not dissolved:** `scripts/normalise-dj-tags.py` has a
**broken WAV write path today**. It fails loudly into its `.failed` ledger rather than silently, and
the stratum is **268 of 8,492 audio files (3.2%)** — all Now-compilation content, none of it the
DJ-service content the three committed rules fire on. A dry run of those rules over all 134 WAV
files reports `files that would change: 0`.

### 3. A3 is confirmed, and its boundary is narrower than row 3b implied

Recorded above in claim-audit row 3b. In one line: **`metadata write`'s flag-`0` `WriteTags` merges
inside the ID3v2 container and does not touch `TKEY` or `EnergyLevel`** — but the same `save()`
promotes ID3v2.3 to v2.4, rewrites or creates the ID3v1 block, and re-serialises any APEv2 tag.
Note the asymmetry with row 3c, which stays a source read: a real `wrtag move`/`copy` calls
`WriteTags(..., tags.Clear)` and **wipes**; `metadata write` **adds**.

### 4. Recorded, not corrected: the phase's field-loss gate has now hidden three different writes

`diff-music-tags.sh` scored `FIELDS_DROPPED = 0` on all of: 03-05's `TYER`→`TDRC` translation (both
render as `date`), this plan's `metadata` arm promoting 205 files to ID3v2.4 with the same
translation, and this plan's run-1 driver writing the wrong value into the right field. It is
working exactly as specified — it detects **field loss** — and that is a narrower question than
"did the tool do what was asked". Any later phase that gates on it alone should read this and
03-05's finding 1 together.

### 5. Recorded, not corrected: `metadata` cannot open a file whose tags carry non-ASCII

4 of 134 WAV files threw `__cxa_allocate_exception (recovered by wazero)` inside taglib-compiled-to-
WASM, on both `read` and `write`. The obvious path-encoding hypothesis was **falsified** — an
ASCII-renamed copy fails identically, and all 3 of the 335 MP3 files with non-ASCII paths
succeeded. The correlation is with **ID3 text-frame content**: `no tags` 47 → 0 failures, `ASCII
ID3 text` 83 → 0 failures, **`non-ASCII ID3 text` 4 → 4 failures**. Nothing in this phase depends on
it, since the verdict does not adopt `metadata`; it is logged so a later phase does not reach for
`metadata` on a European-artist library and discover it there.

---

## AMENDMENT — 2026-09-04, plan 03-10: criteria 7 and 8 measured, T3 left open

**Nothing in this section changes T1, T2 or T3's threshold VALUE, the estimator definition, the
40% threshold, or any denominator.** Criteria 7 and 8 are not pre-committed thresholds; they are
axis-two questions this document was always going to receive. The threshold table's T1/T2 prose,
the estimator section and the denominator section are **byte-identical to threshold commit
`137b6d9e92cb44d9c6a48b3963bb33fe0194622f`**. Only `PENDING` result cells were replaced, plus
T3's two result cells, which now record **why the threshold did not return** rather than a
manufactured answer. Full evidence: [`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md) and
[`03-BEETS-FLASK.md`](03-BEETS-FLASK.md).

### 1. The trial ran, and it was decided by a defect rather than by a stopwatch

The operator ran the trial personally on 2026-09-04. **The counters the sheet was built to collect
were largely not collected** — `wall_clock_s` and `interventions` are `not measured` on 9 of 10
rows, and 4 of the 5 terminal rows read `not run` by operator decision. They are recorded as
absent, with reasons, rather than filled: **a fabricated ergonomics figure would be undetectable
afterwards**, in a phase whose premise is that this pipeline was built three times on unverified
assumptions.

Three verified findings decided axis two instead, each re-confirmed on disk at plan close:

| Finding | Status |
|---|---|
| rc6's interactive picker crashes intermittently — full-page `TypeError` from a **CORS-blocked third-party cover-art fetch with no error boundary**; backend logged **zero** errors; reproduced on 2 albums across 2 browsers | **DEF-03-13** |
| A **75%** match on the flattened-two-releases album **dropped 9 of 31 audio files and mis-tagged 4 tracks onto entirely different songs**, while the UI asserted *"All tracks on disk found online"*. Bounded to that folder shape — the other three albums lost **zero** | **DEF-03-14** |
| **`UNDO IMPORT` works** — verified reversal (destination gone, library 0 entries, source intact at 31 files) | see § 3 below |

### 2. This is D-05's confident-wrong-match, one level down

DEF-03-08 recorded that D-05's strict rule admits a confident wrong *release*
(`Mastermix_Issue_412` → a 2006 Specialten DVD, on a ten-track coincidence). Plan 03-10 found the
same failure mode **at track level, and it is worse**: there the whole album was obviously wrong,
whereas here **17 of 22 tracks are perfect, so nothing looks amiss** — and the four wrong titles
are written into the files' `title` tags, not merely into the paths.

**The instrument that would have caught it does not exist in this phase:** an assertion that
**source audio count == imported item count**. `CLAUDE.md` already says *"never accept a match
without a track-count check"*; DEF-03-14 carries it to file granularity for Phase 6/7. Note the
family resemblance to DEF-03-10: a correct-shaped wrong value defeats a loss-detecting gate.

### 3. A standing project constraint is contradicted by measurement

`CLAUDE.md` § *Constraints* and `PROJECT.md` both state, as a hard constraint, that **"beets has no
`undo` command — verified against the live CLI"**, which is why Phase 1 had to pair `library.db`
backups with ZFS snapshots to obtain reversibility at all.

**beets-flask rc6 has a working `UNDO IMPORT`**, verified by use rather than read from docs. The
constraint remains true of the **beets CLI**, which is what it was measured against — so it is not
falsified, it is **narrower than it reads**. Recorded here rather than edited into `CLAUDE.md`,
because D-03 and the mid-wave rule keep this phase out of shared documents; **plan 03-11 should
pick it up**, and it is the single most useful capability the trial found.

### 4. A reframing of what T1's number means — and explicitly NOT a change to it

The operator identified that **`mastermixdj.com` is canonical for the publisher-branded majority of
the backlog**, in a plain HTML table carrying per-track number, artist, title, version, **BPM** and
duration — with every BPM matching the embedded `TBPM` and every duration matching disk within
~1 s, on the one page checked. **115 of 151 backlog folders (~76%) are DJ-service branded** (99
Mastermix, 13 DMC, 3 Toolkit, 2 Crate).

**T1 fired at 27.08% measuring the *Discogs* strict match rate against that population.** That
number was measured correctly against its stated definition and is **unchanged, as is its 40%
threshold, its estimator and its 144-folder denominator.** What changes is only the *reading*:
**Discogs was substantially the wrong instrument for the majority of the backlog.** T1's outcome —
FIRED — is unaffected and, if anything, better explained.

**Not over-claimed:** exactly **one** product page was checked; coverage across the 99 Mastermix
folders is **unproven**; it is a commercial site, so any lookup must be gentle, cached and
terms-checked. And Mastermix's own tagging is inconsistent — ~40% of sampled folders carry a bare
`album=Mastermix` — so the join key is likely the **folder name**, which none of the three taggers
parses. Recorded as **DEF-03-17**.

### 5. Recorded, not corrected: two denominators and one unsatisfiable assertion

- **151 vs 144.** This session counted 151 backlog folders on a different path set and dedup rule
  than 03-03's deduplicated 144. Neither threshold outcome moves (T1's weights are explicit
  fractions over 144; T2's 21.8 min is nowhere near its 4-hour limb), but **plan 03-11 should state
  which is authoritative.** **DEF-03-18.**
- **`zfs diff` on the Music snapshot cannot return clean.** 03-10's own closing criterion requires
  it; measured from atlantis it returns **2,674 lines, all `M`, zero `+`/`-`/`R`** — against a tree
  of exactly **2,674** entries. That is Phase 1 plan 01-08's chown signature against a snapshot from
  2026-08-18, and it has been non-clean ever since. The assertion it was reaching for holds on a
  better instrument: **0** files under Music have an mtime or ctime inside the trial window.
  **DEF-03-19.**

### 6. What criterion 8 does and does not deliver

The criterion 8 verdict is written in `03-ERGONOMICS-SHEET.md` and is **explicitly labelled
scribe-assembled from verified observations**, quoting the operator's one contemporaneous verbatim
(*"this is what i see if i move fast"*). It carries four stated confidence boundaries: it is not a
wall-clock finding, not evidence about the 144-folder case (**friction 5 stays `NOT EXERCISED` — a
five-album trial structurally cannot test "laggy past some hundred folders", as recorded before any
score existed**), not a finding about the beets *engine* (the arms ran different versions per OD-2,
and the mis-match is candidate behaviour that the front end then *misdescribed*), and not a paired
comparison. **The operator should countersign or replace it in their own words before 03-11 closes
axis two.**

---

## Handoff to Phase 4

**ROADMAP Phase 4 success criterion 4 is unsatisfiable as written.** It requires *"a `--pretend` run
on one known-good album returns a MusicBrainz candidate instead of skipping"*. From
`beets/importer/session.py` v2.13.1, `ImportSession.run()`:

```python
        # In pretend mode, just log what would otherwise be imported.
        if self.config["pretend"]:
            stages += [stagefuncs.log_files(self)]
        else:
            ...
            if self.config["autotag"]:
                stages += [
                    stagefuncs.lookup_candidates(self),
                    stagefuncs.user_query(self),
                ]
```

`--pretend` **replaces the entire pipeline with a file lister.** It never calls `lookup_candidates`,
issues **zero** API calls and reports **zero** candidates. **It needs rewording to `beet import -t`
or a `tag_album()` probe.** Recorded here so Phase 4 does not spend a plan discovering it.

**Also recorded for Phase 4:** `renovate.json5:91`'s stated evidence is wrong in a way Phase 4 must
not repeat. The rule reads *"HOLD at v0.20.x — v0.30.0 changed path-format fields"*, but of the
three fields it implicates, **two are innocent**: `.Release.Date.Year` and `.Release.Media` are both
present at v0.20.0. The real defects are that v0.20.0 **forces `d.Track.Position = -1`** (so every
single-disc file renders `-1 - Artist - Title.ext`) and that **`.Media.Position` is absent from
v0.20.0's `Data` struct** (a template execute error, but only when `len .Release.Media > 1`, because
`{{ if }}` bodies are lazily evaluated). **Cause and effect are reversed in that rule.** See plan
03-08 for the measured proof. TAGR-03 owns releasing the pin; **this phase does not touch it.**

---

## Threshold commit provenance

`git log -p` on a local branch is **evidence, not proof**: a local history can be amended or rebased
before it is published, so custody that rests only on local commit ordering rests on the author's
restraint. **A pushed commit is a fact about a remote.** This section records that fact.

| Property | Value |
|---|---|
| **Threshold commit SHA** | `137b6d9e92cb44d9c6a48b3963bb33fe0194622f` |
| Committer timestamp (UTC) | `2026-09-03 19:27:13 +0000` |
| Remote | `origin` — `git@github.com:DamianFlynn/selfhost-stacks.git` |
| Ref pushed to | `refs/heads/worktree-agent-a810735978952a3c4` |
| Contents | `03-DECISION.md` and `03-ERGONOMICS-SHEET.md`, 513 insertions, 0 deletions |
| Reachable from | `origin/worktree-agent-a810735978952a3c4` (verified with `git branch -r --contains`) |

That commit is the one that introduced **T1, T2, T3, the backlog-weighted estimator and the
corrected 143-folder denominator**. **Every measurement in this phase is committed after it**, and
the threshold text and the estimator definition are asserted **unchanged** against it in plans 03-07
and 03-11 by `git log -p 137b6d9e92cb44d9c6a48b3963bb33fe0194622f -- .planning/phases/03-tagger-spike/03-DECISION.md`.

**Recorded honestly — the ref this was pushed to, and why it is not `main`.** Plan 03-02 executed as
an isolated worktree agent, and at the moment of the push **`origin/main` stood at `c88c268`, which
is *behind* this plan's own base commit `41de755`** ("docs(phase-03): begin phase 03 execution") —
the phase-start commit had not itself been published. Publishing this branch's history onto `main`
would therefore have pushed unmerged parallel work ahead of the orchestrator that owns the merge.
The commit was pushed to its own remote branch instead. **This satisfies what the push is for:** the
SHA is now immutable and independently verifiable on a remote, so criterion 5's custody no longer
rests on a mutable local branch. **`origin/main` reachability completes when the orchestrator merges
the wave**, and because this repository merges rather than squashes or rebases (see `0ee20c7`,
`merge(02.1-15)`), **the SHA above survives that merge unchanged**.

**Required of plan 03-07:** reproduce this SHA verbatim in `03-DISCOGS-EVIDENCE.md`, and **assert it
is an ancestor of `origin/main` before recording any number** —
`git merge-base --is-ancestor 137b6d9e92cb44d9c6a48b3963bb33fe0194622f origin/main`. If that
assertion fails, the merge has not happened yet and no evidence may be recorded against it.

---

## Files this phase reads and quotes but does NOT edit (D-03)

- `stacks/selfhosted/music/wrtag.yaml` — lines 71 and 73, quoted verbatim above.
- `stacks/selfhosted/arrs/beets/beets.yaml` — `:ro` on `/media`, `restart: "no"`,
  `profiles: ["manual"]`.
- `renovate.json5` line 91 — the wrtag hold rule.

Both spike containers are **throwaway**. The spike measures; **Phase 4 deletes the loser; Phase 6
configures the winner.** Do not half-deploy a decision that has not been made.
