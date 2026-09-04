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

## Criterion 5 — the thresholds, and the proof none of them moved

All three rows of § *Pre-committed thresholds* now carry a `Tested?` and a `Returned` line.
**Two fired, one did not**, and the outcomes are recorded whichever way they went.

| # | Outcome | What it changed about the decision |
|---|---|---|
| **T1** | **FIRED** — weighted strict **27.08%** against a 40% threshold | It did **not** flip the engine, because the alternative was disqualified independently (criterion 3). What it changed is what the winner is expected to *do*: **the plan may not assume Discogs autotags this backlog.** It fires on every reading — unweighted 25.00%, most-favourable V6 bound 36.80%, strict-and-correct 22.80% |
| **T2** | **NOT FIRED — neither limb** — 21.8 min projected against a 4-hour limb, **0** HTTP 429 on both correct instruments | Rate limiting is **not** the obstacle, so no design may be justified on the grounds that it is. Recorded as a result in its own right: three of T2's originally-named instruments were defective (DEF-03-05/06/07) and were substituted with instruments that measure the stated quantity, **without the limb's value changing** |
| **T3** | **FIRED** — the operator's own words, quoted verbatim in the threshold table | It removed the raw terminal prompt from axis two. **It did not produce the consequence 03-02 predicted** — see § *AMENDMENT — 2026-09-04, plan 03-11* § 2 |

**No threshold was recorded indeterminate.** The one place a hole stratum could have straddled the
threshold was V6 — 1 sampled folder, 0.0972 weight, `0.0000` contribution — and its 0%/100%
contribution band gives **27.08–36.80%**, whose *upper* bound is still below 40%. So T1's outcome
is robust to the thinnest stratum in the sample rather than resting on it.

### Custody: the threshold commit, and why a remote is the only proof

**`git log -p` on a local branch is evidence, not proof** — a local history can be amended or
rebased before it is published, so custody resting on local commit ordering rests on the author's
restraint. **A pushed commit is a fact about a remote.** The threshold commit is:

```
137b6d9e92cb44d9c6a48b3963bb33fe0194622f
```

Re-asserted **in this plan**, from this worktree, rather than taken on plan 03-07's word:

| Assertion | Command | Result |
|---|---|---|
| It resolves to a commit object | `git cat-file -t 137b6d9e92cb44d9c6a48b3963bb33fe0194622f` | **`commit`** |
| It is reachable from `origin/main` | `git branch -r --contains 137b6d9e92cb44d9c6a48b3963bb33fe0194622f` | **`origin/main`** (and `origin/HEAD -> origin/main`) |
| It is an ancestor of `origin/main` | `git merge-base --is-ancestor 137b6d9e92cb44d9c6a48b3963bb33fe0194622f origin/main` | **exit 0** |

That closes the open item recorded in § *Threshold commit provenance*: at 03-02 close the commit
was reachable only from `origin/worktree-agent-a810735978952a3c4`, because `origin/main` then stood
behind this phase's own base. **The orchestrator has since merged the waves, and because this
repository merges rather than squashes or rebases, the SHA survived that merge unchanged** — which
is exactly what the provenance section predicted and is now verified rather than assumed.

**The commits that put each piece of evidence in place, all of them after the threshold commit:**

| Evidence | Introducing commit | Covers |
|---|---|---|
| Thresholds, estimator, empty ergonomics sheet | `137b6d9e92cb44d9c6a48b3963bb33fe0194622f` | T1, T2, T3, the denominator, the sheet's definitions |
| `03-DISCOGS-EVIDENCE.md` | `316af3a9339bae3c324e035142af77108da4934b` (03-07) | criterion 1 — the four-cell matrix |
| T1/T2 marked tested | `88c3295721e2f6364adff92f44ed3c01389bf2ce` (03-07) | criterion 2 — timing and extrapolation |
| `03-WRTAG-EVIDENCE.md` | `621a5b525d4b77d27a1141fb07ad8b7bdc30b59e` (03-08) | criterion 3 |
| `03-NORMALISER-BAKEOFF.md` | `7c82cd0805da9f51518d8075f9035ab0d00e9914` (03-09) | D-13 |
| `03-BEETS-FLASK.md` | `497361cce9374c73d25ceae9a8c144240f245518` (03-10) | criteria 7 and 8 |

### Two things were fixed pre-evidence, and neither moved afterwards

Stated explicitly because criterion 5 is unprovable retroactively and this is the shape of the
proof:

1. **The threshold *values*** — 40%; 4 hours **or** any 429; an honest self-assessment.
2. **The *estimator* T1 is tested against** — the backlog-weighted per-stratum roll-up.

**Both were fixed in the same pre-evidence commit**, before a single folder was sampled, a single
weight measured or a single Discogs request issued. **An estimator chosen after a rate exists is
goalpost-moving; an estimator specified before any rate can exist is simply specifying the
measurement** — the same structure as OD-3's widening. Plan 03-03, which drew the sample and
measured the weights, depends on 03-02 and could not run before it; plan 03-07, which measured the
rates, depends on 03-03.

Asserted mechanically in this plan, not claimed:

- The T1/T2/T3 rows' **Threshold**, **Falsifiable form** and **Instrument** columns are
  **byte-identical** to `137b6d9e` — extracted with `cut -d'|' -f2,3,4,5` on both revisions and
  `diff`ed to zero lines.
- § *The estimator T1 is tested against* differs from `137b6d9e` **only in its `PENDING` weight and
  rate cells**; every line of its prose, including the definitions and § *Why fixing the estimator
  here preserves criterion 5*, is unchanged.

### The weighted and unweighted figures, side by side

| Figure | Value | Status |
|---|---|---|
| **Backlog-weighted strict rate** | **27.08%** | **This is what T1 was tested against.** Fires the 40% threshold |
| Unweighted per-folder sample rate | 25.00% (6/24) | Reported beside it, **explicitly not the tested figure** |
| Most-favourable bound (V6 at 100%) | 36.80% | Still fires |
| Strict **and** the release is correct | 22.80% weighted | Reported beside it; fires more clearly. 1 of 6 strict hits is a confident wrong release (DEF-03-08) |
| Weighted **loose** rate (normalised) | 51.39% | The strict/loose gap is **7 folders / 29.2%** — a deliverable in its own right, not a softer headline |

**Both weighted and unweighted are honest numbers about different things. Only the weighted one is
tested against T1**, because request volume and match likelihood vary by stratum by construction —
a V3 folder with no `album` tag issues no Discogs query at all, while a V1 folder paginates.

---

## Criterion 7 — beets-flask, evaluated by name

Required to be evaluated **by name**, not dismissed and not assumed. It was deployed as
`metasauce/beets-flask:v2.0.0-rc6` (digest `sha256:9548e78f…`, re-verified against the live host)
behind a recorded operator acknowledgement (`deploy-rc6`, verbatim, dated, and **provably
pre-deployment** — zero containers named `beets-flask-spike` existed at the moment of answering).
Full record: [`03-BEETS-FLASK.md`](03-BEETS-FLASK.md).

**All eight researched frictions carry an observation. A ninth was found by this deployment.**
*"Not exercised"* is used honestly and is not a synonym for *"fine"*.

| # | Friction (as researched) | Verdict | What was actually seen |
|---|---|---|---|
| 1 | 1.0 removed the interactive terminal import in favour of UI candidate selection; a tmux-backed web terminal exists for pasting a release ID | **OBSERVED** | Present and enabled. The shipped example defaults `gui.terminal.start_path` to a `/music/inbox` that does not exist here; the spike overrode it rather than mounting a `/music` to satisfy a default. The terminal grants a shell inside a container that mounts `tank` — which is why the service is loopback-bound with **zero** Traefik labels |
| 2 | Inbox entries must be directories; loose files never trigger (documented wontfix) | **OBSERVED — by direct probe** | A single loose `LOOSE-FILE-PROBE.mp3` was never imported. The reaction is subtler than "nothing happens": the watchdog enqueued **the inbox root itself** as a preview task and the API reported `tagged_via_gui: 1, imported_via_gui: 0`. A loose file produces **a task against the wrong unit of work** |
| 3 | Music paths must match inside and outside the container | **OBSERVED — identical-path mounts sufficed** | `beet ls` inside returns paths that resolve on the host; the import wrote to the host path the config names. Cross-checked for mount freshness: 21 host-side and 21 container-side |
| 4 | Only `copy` is supported, never `move` | **OBSERVED — and favourable here** | Source folder kept all 20 mp3; `bf-clean` held 20 copies. It enforces what `PROJECT.md`'s storage constraint already wants. Recorded as a friction only because a later phase that genuinely wants `move` cannot have it |
| 5 | UI gets laggy past "some hundred" folders (#164, #175) | **NOT EXERCISED — and structurally cannot be by this trial** | The backlog is 144 folders; the trial ran **one** folder through `bootleg` and **five** through the picker. **No score this trial produced is evidence either way about the 144-folder case.** Recorded before any score existed. Carried as a **Phase 9** handoff |
| 6 | `beets==2.12.0` hard pin | **OBSERVED — pin held, both instruments** | `requirements.txt` written pinned; the startup install resolved without touching beets. Runtime assertion `beets.__version__` → **2.12.0**. OD-2 enforced by prevention **and** confirmed by detection |
| 7 | Still in RC since 2025-12-29; last stable v1.2.1 | **OBSERVED — a durability risk, not a defect** | Self-reports `Backend 2.0.0-rc6 / Frontend 2.0.0-rc6 / Mode prod`. Nothing about the RC status broke. Eight months in RC is a statement about maintenance cadence for a tool this project would depend on |
| 8 | Docs' `apk`-based `startup.sh` examples are stale (Debian base since rc4) | **NOT EXERCISED — deliberately** | No `startup.sh` was written, so the stale examples were never followed. One correction *to* the research: the mechanism is `uv pip install -r`, **not** plain `pip`, and it checks **two** requirements paths |
| **9** | **NEW —** rc6 validates the **beets** config against its own JSON schema, stricter than beets | **OBSERVED — a startup-breaking trap** | `plugins:` as beets' canonical space-separated string is **rejected**: *"…is not of type 'array', 'null'"*. **The danger is what survived it** — the server started and served a page while `launch_watchdog_worker.py` died, so **the three policy inboxes would have been inert** and the trial would have scored a beets-flask whose central architecture was not running, against a UI that looked alive. Same defect class as TAGR-05: a configuration failure presenting as *"nothing is happening"* |

### The `bootleg` finding, and its boundary

`autotag: "bootleg"` is confirmed present in rc6 **from primary source**
(`backend/beets_flask/config/schema.py:110`) — and note that the **shipped example config never
mentions it**, so the example file alone would have hidden the feature entirely. It is *"Import
as-is using the meta data of files, and group albums using the metadata… Effectively
`beet import ... --group-albums -A`"*.

**Measured twice, on the same button, with opposite outcomes**, and both are recorded:

| Folder | `album` tag | Result |
|---|---|---|
| `VA-Mastermix.Crate.068-070-2025` | populated | **The best result either arm produced.** 3 correct albums × 20 files, `APIC` 60/60, `TBPM` 60/60, `TALB`/`TCON` 60/60, one `mv`, zero decisions, `COPY` with source intact — on a folder Discogs scored at **zero** strict candidates. **But `TRCK` 0/60** |
| `VA-Mastermix.Crate.071.Afro.House-2025` | **empty** | **One 20-track release became twenty single-track albums.** `album` empty, `track` `00`, no album directory level, `comp` False. **No error, no prompt, and a clean log** |

**`--group-albums` groups on the metadata that is *there*.** So `bootleg` is a fast path for
already-correctly-grouped content, **not** an answer for untagged content — which vindicates
`PROJECT.md`'s *normalise first, then import* sequencing rather than replacing it. **The only
difference between the two outcomes is whether `album` is populated, and nothing in the UI
distinguishes them before the operator commits** (DEF-03-16).

### The architecture confirmation — this is the Phase 5 structure

Confirmed from primary source (D-12 claim-audit row 16) **and exercised at runtime**, which matters
because friction 9 shows a config that validates is not a config that runs:

- `config/beets/config.yaml` is a **normal beets config**, so there is exactly **one `library`**.
- `config/beets-flask/config.yaml` defines `gui.inbox.folders.*`, **each with its own `autotag`
  policy** — `off` / `preview` / `auto` / `bootleg`.
- rc6's own watchdog registered all three at startup, which is the runtime proof rather than a
  documentation read:

```
[INFO] beets-flask.wdog: Registering watchdog with debounce of 30 seconds for inboxes:
  ['/mnt/tank/downloads/spike-03/bf-inbox/preview',
   '/mnt/tank/downloads/spike-03/bf-inbox/auto',
   '/mnt/tank/downloads/spike-03/bf-inbox/bootleg']
```

**One shared `library.db` across N policy-carrying inbox folders is therefore verified, not
assumed — and it is exactly the Phase 5 structure the roadmap needs.** It is also the thing the
terminal arm has no equivalent of: there, every decision is made per album, at the prompt, by hand,
and there is nowhere to express *"content of this shape is handled this way"* other than in the
operator's head.

**One credential check, recorded because this phase leaked the Discogs token to disk twice.**
`python3-discogs-client` sends the token as a **`?token=` query parameter**, not an `Authorization`
header (DEF-03-04), and beets-flask has **no authentication at all** — so anything its API renders
is readable by anyone who reaches the port. Probed **inside the container**, comparing against the
live value so it never crossed a transcript: `/api_v1/config/`, `/api_v1/config` and
`/openapi.json` **all returned no token and no `user_token` key.**

---

## Criterion 8 — the week-six verdict, in the operator's own words

The pre-committed rubric for this section, restored verbatim above the verdict in
[`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md): **"It works" is not the finding — "it works and
I will still open it" is.**

**The operator has now answered exactly that question, and this is their answer, word for word:**

> **"If you're asking me directly if I'm going to use the command line or the web interface, then
> it's the web interface ahead of the command line any day. Right? It is a much more pleasing
> experience, and the web interface is clean. I understand what's happening, and I know that I need
> to remove the stuff from the inbox when it's all copied. The command line interface, I'm not a
> fan. It's fine for a bot to drive us, but for me, as a human, no."**
>
> — the operator, 2026-09-04, after driving both arms

**And the `stuck_points` that produced it**, recorded beside it as the criterion requires. The
trial produced **one** contemporaneous operator verbatim across all ten rows, on being asked to
read the flask arm's diff modal before the page crashed:

> **"this is what i see if i move fast"**

The remaining `stuck_points` are the executor's contemporaneous notes, not the operator's voice,
and are reproduced from the sheet:

| Row | `stuck_points` |
|---|---|
| `clean-1` / terminal | operator wrote outcome `tagged`, not one of the four permitted values; reconciled to `imported` in AMENDMENT B-2, **with the original word kept because it is itself data** — on an arm whose whole interaction was pressing `A`, describing the result as *"tagged"* rather than *"imported"* suggests it did not leave them confident an import had happened |
| `clean-1` / flask | 88% preview was already waiting before the operator looked; 21 → 21, nothing dropped |
| `clean-2` / flask | **full-page `TypeError` crash reproduced on this album**, across 2 browsers. 10 → 10 |
| `hard-va-compilation` / flask | 86%; 47 → 47, 3 non-audio correctly ignored. The 46-distinct-artist case cost nothing |
| `hard-flat-multidisc` / flask | **75% accepted → 9 of 31 audio files silently dropped and 4 tracks mis-tagged onto different songs**, while the UI asserted *"All tracks on disk found online"*. Crash also reproduced here. `UNDO IMPORT` verified working |
| `dj-no-match` / flask | picker's best offer was a **44% wrong** match. `bootleg` instead: one `mv`, zero decisions, 3 correct albums, 60/60 covers, 60/60 `TBPM` — but **no `track` tag at all** |
| four terminal rows | `not run` — operator decision (AMENDMENT B-3) |

### How the operator's answer and the measured defects are both honoured

**Read carefully, the answer is about legibility and it is not a safety endorsement.** The operator
says *"I understand what's happening"* of the web interface — and they say it **after** the trial in
which that interface silently dropped 9 files and mis-wrote 4 tracks under a false safety claim.
**Both things are true at once**: rc6's *workflow* is legible and its *correctness* is not
established. This record does not read the first as the second, and criterion 8 is answered on the
first because that is what criterion 8 asks about.

**And what the answer explicitly does not reject is the CLI as a mechanism.** *"It's fine for a bot
to drive us, but for me, as a human, no."* A scripted, agent-driven `beet` invocation remains
acceptable to the operator. **What is rejected is the human sitting at the prompt** — which is
precisely T3's falsifiable form and precisely what the policy-inbox architecture removes.

**One ergonomics result worth more than any timing that was not taken:** *"I know that I need to
remove the stuff from the inbox when it's all copied."* The copy-then-clean mental model
transferred **within a single trial, unprompted.** That is a direct, measured hit against the
abandoned-halfway failure mode this project exists to prevent, and it is the strongest positive
evidence axis two produced.

**Confidence boundaries, so this is not over-read** — carried unchanged from the sheet:

- **Not** a wall-clock or intervention-count finding. Neither was measured on 9 of 10 rows.
- **Not** evidence about the 144-folder case. Friction 5 stays `NOT EXERCISED`.
- **Not** a finding about the beets *engine*: the 22-track mis-match is candidate behaviour that
  the front end then *misdescribed*, and the arms ran different beets versions (OD-2). **The
  front-end failure is the false safety claim, not the bad match.**
- **Not** a paired comparison: 1 terminal row against 5 flask rows.

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

## AMENDMENT — 2026-09-04, plan 03-11: T3 answered, the phase closed, and four claims corrected

**Nothing in this section changes T1's, T2's or T3's threshold VALUE, the falsifiable form, the
named instrument, the estimator definition, the 40% threshold or any denominator's committed
value.** T1/T2/T3's `Threshold`, `Falsifiable form` and `Instrument` columns are asserted
**byte-identical** to `137b6d9e92cb44d9c6a48b3963bb33fe0194622f` in § *Criterion 5*, mechanically
rather than by claim. What changed in this plan is: T3's two **result** cells, the axis one and
axis two verdict cells, criterion 4's beets-terminal **result** cell, and new sections appended
below. Prior plans' wording is preserved and amended, never overwritten.

### 1. T3 is answered, and the instrument was the one the threshold named

Plan 03-10 recorded T3 `NOT ANSWERED` and was **right to**: T3's named instrument is an explicit
written self-assessment in the operator's own words, no such sentence existed, and writing one in
their voice would have fabricated the exact instrument the threshold specifies. **The orchestrator
subsequently asked the operator directly, after they had driven both arms, and the instrument
returned.** T3 **FIRES**. The answer is quoted verbatim in the threshold table and again in
§ *Criterion 8*; the 03-10 reading is preserved in full inside the same cell and marked superseded
**by the arrival of the missing instrument, not by re-interpreting the same evidence.**

### 2. The consequence 03-02 predicted for a firing T3 is VOID — and it is recorded, not dropped

The pre-committed record anticipated, in `PROJECT.md` § *Evidence that would overturn this*:

> *"If the answer is no, the plan needs wrtag for A/B and manual/scan work for C — two tools, which
> contradicts the core value."*

**That predicted consequence is void, and the reason is a finding from this same phase.** Plan
03-08 established that **wrtag cannot render this repository's path format at any tag**: v0.20.0
emits `-1 - ` on 21 of 21 single-disc paths and hard-errors on multi-disc; v0.33.0 and v0.34.0
refuse the format at startup with exit 2. **wrtag is not available as the A/B arm the prediction
depends on, so the two-tool split it warned about cannot form — because the second tool does not
function here.**

**The prediction is recorded rather than quietly deleted**, because a pre-committed expectation
that was overtaken by evidence is exactly the kind of thing this phase exists to keep visible. It
was a sound prediction on what was known when it was written; it was falsified by measurement
taken afterwards, by a plan whose whole purpose was to take that measurement.

So the decision space after T3 fires is **narrower and different** from what was anticipated:
beets-terminal ruled out by T3 in the operator's own words; wrtag ruled out by 03-08 on
measurement; and beets-flask rc6 both the operator's stated preference **and** the arm with the
worst measured safety record in the phase. **That tension is resolved explicitly in § *Axis two*
§ *The tension this verdict does not smooth over*, by distinguishing the policy architecture from
the candidate picker — not by discounting either the operator's answer or the defects.**

### 3. The denominator question is settled: **144 is authoritative**, and the tree is live

DEF-03-18 recorded two figures in circulation, **151** and **144**. Re-measured from LXC 100 on
2026-09-04, all three readings reconcile exactly:

| Reading | Path set | Rule | Value |
|---|---|---|---|
| DEF-03-18's 151 | `complete/nzb/{unsorted,music}` | `-maxdepth 1 -type d`, **no audio test** | `unsorted` 121 + `music` 30 = **151** |
| Audio-bearing, today | same | directory contains ≥ 1 audio file | `unsorted` 120 + `music` 25 = **145** |
| 03-03's census, 2026-09-03 20:36 UTC | same | audio-bearing, deduplicated | `unsorted` 120 + `music` 24 = **144** |

**151 − 145 = the six directories that hold no audio at all**, enumerated so the gap is a fact
rather than an inference:

```
unsorted :: Harry.Potter.And.The.Deathly.Hallows.Part.1.2010.PROPER.1080p.BluRay.x264-MOOVEE
music    :: Ed Sheeran - ÷ (2017) FLAC
music    :: Garth.Brooks-Man.Against.Machine-CD-FLAC-2014-NBFLAC
music    :: Pink-Missundaztood-2LP-24BIT-FLAC-2001-REETKEVER
music    :: _UNPACK_Ed Sheeran - Ed Sheeran [self titled] (EP) (2006) MP3
music    :: _UNPACK_Katy Perry - Prism (2013) FLAC
```

That is one misfiled movie rip, two `_UNPACK_` stubs and three folders with no audio — **exactly
`beets.md`'s bucket D**, which is triage-and-delete work, not tagging work. A bare
`-maxdepth 1 -type d` counts them; a rate denominator must not.

**145 − 144 = one folder that arrived while the phase was running**, and this is the more
important half:

```
/mnt/tank/downloads/complete/nzb/music/Taylor Swift - The Life Of A Showgirl-WEB-2025-ALTAiR INT-xpost
  mtime = 2026-09-03 21:17:19 UTC     12 audio files
03-03's census commit 4a0b5f3239ba844dd4b312ec93df9274a8202dbe = 2026-09-03 20:36:42 UTC
```

**It landed 41 minutes after the census was committed.** The backlog is not a fixed set: sabnzbd is
still writing into `complete/nzb/music` unattended — DEF-03-01 recorded a post-processing beets run
on that very tree at 2026-09-03 20:30 UTC — so **every backlog denominator is a timestamped
snapshot of a moving population, and any two taken at different moments will disagree.**

**The ruling:**

- **144 is authoritative for this phase and must be quoted with its date.** Not because it is the
  most recent — it is not — but because **it is the frozen basis of T1's estimator.** The weights
  are explicit fractions over it (37/144, 39/144, 11/144, 0/144, 43/144, 14/144), and a rate
  computed against one denominator may not be quoted against another. **T1's outcome does not move
  on any of the three figures**, and neither does T2's (21.8 min against a 4-hour limb).
- **151 is not wrong — it is a different measurement**, and any later plan quoting it must say so
  and must not pair it with 144-based weights.
- **Whoever re-counts must record the path set, the audio test and the timestamp**, because the
  tree changes underneath the count. **DEF-03-18 is closed by this ruling.**

### 4. Four claims this phase falsified, corrected here rather than in the documents that carry them

`CLAUDE.md`, `PROJECT.md` and this document each carry a statement this phase measured to be wrong.
They are corrected **in this record** and left standing in their originals, because D-03 keeps this
phase out of shared documents and because overwriting them would erase the evidence that they were
ever believed. **Phase 4 owns editing the originals.**

| # | Claim, and where it lives | Measured correction |
|---|---|---|
| 1 | *"`v0.33.0` — the existing path format is already correct for it"* — `CLAUDE.md` § *What NOT to Use* | **FALSIFIED** (03-08). v0.33.0 and v0.34.0 **refuse this repo's format at startup**, exit 2, before a file is read. Four arms, byte-identical refusal text |
| 2 | *"wrtag v0.30.0+ … Breaking. **Not used by this repo's format**"* — `PROJECT.md` § *Version Compatibility* | **HALF TRUE, AND THE WRONG HALF** (03-08). The v0.30.0 *migration table* genuinely does not apply. What was missed is the **new multi-disc validation shipped in the same release**, which rejects the format outright |
| 3 | *"The backlog denominator is **143** folders"* — this document, § *Denominators, committed before the run* | **CORRECTED TO 144** by a better instrument, before any rate existed (03-07 amendment § 1); and now re-confirmed against a live tree that has since grown to 145 — see § 3 above |
| 4 | *"the 45 GB `1-115` set … **does not exist on disk**"* and *"Retire that instruction"* — this document, § *Denominators* | **RETRACTED.** The set **does exist** — 4,746 audio files, **61% of the backlog's files**. So **`PROJECT.md`'s and `CLAUDE.md`'s split-per-volume instruction STANDS** and must not be retired. The 03-03 claim was made against an `unsorted`-tree reading that did not reach it |

**Correction 4 is the one that would have done real damage if left standing**, because a later
phase acting on *"retire that instruction"* would have pointed a single import at 115 albums in one
folder — the exact failure `beets.md` § *Two config gaps* warns about.

### 5. A standing project constraint is narrower than it reads, and this is the trial's most useful find

`CLAUDE.md` § *Constraints* and `PROJECT.md` both state as a **hard constraint**:

> *"beets has no `undo` command — verified against the live CLI."*

**beets-flask rc6 has a working `UNDO IMPORT`**, verified **by use** rather than read from docs:
destination gone, library 0 entries, source intact at 31 files.

**This does not falsify the constraint — it bounds it.** The constraint is true of the **beets
CLI**, which is what it was measured against. It is **not** true of the front end this phase just
selected on axis two. That matters because the constraint is load-bearing: it is why Phase 1 had to
pair `library.db` backups with ZFS snapshots to obtain reversibility at all, and why *"roll back
the tree and the database together or neither"* is written into `beets.md`.

**Flagged explicitly because it changes the reversibility story the project has been planning
around**, and because plan 03-10 recorded it as *"the single most useful capability the trial
found"* and asked 03-11 to pick it up. **Phase 4 should amend the constraint in `CLAUDE.md` and
`PROJECT.md` to read "the beets CLI has no `undo`"**, and Phase 7 — whose success criterion is
*"undo exercised"* — should note it now has two candidate mechanisms, not one. **Not amended here:
D-03 keeps this phase out of those documents.**

**Do not over-read it either.** It was exercised on **one** import, in a release candidate, and on
the very album whose import was catastrophically wrong — so what is verified is that the reversal
worked, not that it is reliable across shapes. And it does not reverse the *tag writes* made into
the files, only the import.

### 6. DEF-03-17 reframes what T1's number means — and changes nothing about the number

The operator identified that **`mastermixdj.com` is canonical for the publisher-branded majority of
the backlog**, publishing per-track number, artist, title, version, **BPM** and duration as a plain
HTML table. On the one page checked (catalogue **MDJ2159**, 20 tracks, stated running time
**1:09:43** against **1 h 9 m 44 s** computed from the files), **every BPM matches the embedded
`TBPM`** and **every duration matches disk within ~1 s**. **115 of 151 backlog folders (~76%) are
DJ-service branded** (99 Mastermix, 13 DMC, 3 Toolkit, 2 Crate).

**T1 fired at 27.08% measuring the *Discogs* strict match rate against that population. That number
is unchanged, and so are its threshold, its definition, its estimator and its 144-folder
denominator.** What changes is only the *reading*: **Discogs was substantially the wrong instrument
for the majority of the backlog.** T1's outcome — FIRED — is unaffected and, if anything, better
explained.

**Explicitly not over-claimed, because this is the finding most likely to be over-read:**

- **Exactly one product page was verified.** Coverage across the 99 Mastermix folders is
  **UNPROVEN**. It is a hypothesis with one confirming instance, and Phase 4 research must measure
  coverage before anything is designed around it.
- Mastermix's own tagging is inconsistent — **~40% of sampled folders carry a bare
  `album=Mastermix`** — so the join key is likely the **folder name**, which none of the three
  taggers parses.
- It is a **commercial site**. Any lookup must be gentle, cached, rate-limited and terms-checked,
  and this project should not build a scraper without checking the site's terms.
- **If** coverage holds, it likely displaces both the Discogs path **and** the planned VLM
  cover-scan extraction (54 images / 27 folders) for Mastermix content. **That is a conditional,
  not a plan.** The cover-scan work is not cancelled by this record; it is flagged as possibly
  unnecessary, pending the coverage measurement.

### 7. Recorded, not corrected: `grep -c PENDING` cannot return 0 on this document

This plan's own acceptance criterion requires `grep -c PENDING .planning/phases/03-tagger-spike/03-DECISION.md`
to return **0**. **It cannot, without destroying provenance this phase's rules protect.** Seven
occurrences of the literal string survive, and **none of them is an unfilled result cell**:

| Where | Why it must stay |
|---|---|
| § header, *"Every result cell in this document reads `PENDING` by design"* | **Pre-committed prose from `137b6d9e`.** It is the record of what the document looked like before any evidence existed |
| § *Pre-committed thresholds*, *"stay `PENDING` until the measuring plans run"* | Same — pre-committed prose from `137b6d9e` |
| § *Criterion 4* and § *D-13*, `~~PENDING — filled by plan 03-0N~~ →` | **Strikethrough provenance markers added by plans 03-08 and 03-09**, showing the cell's prior state beside its filled value |
| Three amendment paragraphs, *"Only `PENDING` result cells were replaced"* | Prior plans' own audit statements about what they changed |

**Answered on a better instrument instead**, which measures the thing the criterion was reaching
for — a `PENDING` occupying a table cell or a verdict slot:

```bash
grep -cE '\| *PENDING *(\||$)|verdict:\*\* PENDING|status: PENDING' 03-DECISION.md   # -> 0
```

It returned **6** before this plan (axis one ×3 + its verdict, axis two's verdict, criterion 4's
beets-terminal row) and returns **0** after. **Logged as DEF-03-20.** This is the same shape as
DEF-03-19: a closing assertion that is unsatisfiable as written, answered honestly with an
instrument that measures the intent, rather than waved through or satisfied by deleting evidence.

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

**Third item, finalised by plan 03-11: the version this spike would deploy, and the trap in the
obvious reading.** Phase 4 retires the loser, so it needs to know what "unpin wrtag" would actually
buy — and the answer is **nothing**, which is not what `CLAUDE.md` currently says.

| Question | Answer, measured (OD-5, three tags, plan 03-08) |
|---|---|
| Would this spike deploy wrtag at any version? | **No.** wrtag is the loser on axis one; Phase 4 deletes it. There is no version to deploy |
| Does unpinning to v0.33.0 fix the path format? | **No.** v0.33.0 **refuses the format at startup**, exit 2, `ambiguous format: multiple directories created for the same release`, before a file is read |
| Does v0.34.0 differ from v0.33.0 on this? | **No — it is a path-format no-op**, confirmed on three instruments: byte-identical refusal text, byte-identical rendered path sets under the ablation, and a changelog whose only breaking change is `deps: bump to go1.27` |
| So what is the sole cause of the refusal? | **The `Disc N/` subdirectory.** A one-line ablation lifting the disc out of the directory level makes **both** current tags render correctly and byte-identically. That is an ablation, not a fix — nobody is asked to adopt it |
| What would a real `wrtag move` have done to this content? | Called `tags.WriteTags(destPath, destTags, tags.Clear)` at `wrtag.go:267` — **wiping every tag not in wrtag's computed set**, with **148 `TKEY` and 45 `EnergyLevel` files at stake**. **Source read, not runtime observation**: `-dry-run` makes `CanModifyDest()` false so line 267 is never reached, and `logTagChanges` iterates `for k := range after`, so a dropped tag is never logged even at DEBUG |

**The one-sentence statement TAGR-03 should cite, verbatim:** *this repository's
`WRTAG_PATH_FORMAT` works on none of v0.20.0, v0.33.0 or v0.34.0 — it renders `-1 - ` on every
single-disc track and hard-errors on multi-disc at v0.20.0, and is refused at startup by both
current tags — and the sole cause of the startup refusal is the `Disc N/` **subdirectory**, proven
by an ablation that changes nothing else and validates at both current tags.*

**And the methodological finding Phase 4 must not lose**, because it invalidates the obvious
experiment: **the disc class of a wrtag arm is not a property of the source folder.** A 21-file,
no-`disc`-tag, `track=N/21` album was resolved by MusicBrainz to a **two-medium vinyl release** and
hard-errored on `.Media.Position` on the first unpinned run. wrtag queries with `limit=1` and takes
what comes back. **Any experiment that means to hold the disc class constant must pin the release
MBID; one that does not is measuring MusicBrainz's mood.**

---

## Handoff to Phases 5, 6, 7 and 9

Four things later phases must not rediscover. Each is a measured finding from this phase with the
artefact that carries it.

**1. The normalisation tool is decided, and the decision is independent of the engine.**
`scripts/normalise-dj-tags.py` — the committed mutagen script — **wins D-13 and binds regardless of
which engine or front end is adopted.** It is dry-run **by default**, emits a per-file NDJSON diff
before writing, does 335 files in one process with 205 distinct value pairs, and needs **zero**
lines of bespoke driver. wrtag's `metadata` needs **540** invocations for the same job, has **no
flags at all** on `write`, prints nothing on success — and the shell loop written to drive it wrote
the artist value into the album field on **20 of 205** files while the field-loss gate scored that
run clean. [`03-NORMALISER-BAKEOFF.md`](03-NORMALISER-BAKEOFF.md).

**The unpaid cost is carried, not dissolved: the script's WAV write path is broken today.** It
writes **0 of 134** WAV files and fails all **134**, loudly, into its `.failed` ledger
(`TypeError: … not a Frame instance` — `mutagen.File(easy=True)` on a WAVE returns a raw frame-id-keyed `ID3`, not an EasyID3
map). The stratum is **268 of 8,492 audio files (3.2%)**, all Now-compilation content, **none of it
content the three committed rules fire on** — a dry run over all 134 reports *files that would
change: 0*. **Phase 4 fixes it alongside TAGR-04**, with the `LIST`/`INFO`-chunk decision DEF-03-09
records and a regression test over untagged, ASCII-tagged and non-ASCII-tagged WAV. **DEF-03-09.**

**2. Phase 5's structure is confirmed, not assumed: one shared `library.db` across N
policy-carrying inbox folders.** Verified from primary source **and** exercised at runtime — rc6's
watchdog registered three inboxes at startup, each with its own `autotag` policy. That is exactly
the shape the roadmap needs, and the terminal arm has no equivalent of any of it. **Phase 5 should
also carry friction 9 forward:** rc6 validates the beets config against its own stricter JSON
schema, and a rejected `plugins:` string kills the watchdog **while the server still serves a
page** — the inboxes go inert behind a UI that looks alive. [`03-BEETS-FLASK.md`](03-BEETS-FLASK.md).

**3. Phase 6/7 need two gates this phase proved are missing, and one it proved is unreliable.**

- **Assert `source audio count == imported item count` and fail closed on a mismatch.** This is the
  only instrument that would have caught DEF-03-14 — 31 source files in, 22 out, 9 silently
  dropped, 4 tracks written onto entirely different songs — while the UI asserted *"All tracks on
  disk found online"*. `CLAUDE.md` already says *"never accept a match without a track-count
  check"*; this is that rule **at file granularity**. Add a per-track duration cross-check, which
  is what identified the mis-mapping.
- **Never route a folder to `bootleg` without first asserting `album` is populated and distinct
  across the intended groups.** The same button produced the phase's best and worst results purely
  on that condition, with **no UI signal** distinguishing them (DEF-03-16).
- **`diff-music-tags.sh` is a field-**loss** detector and is repeatedly read as a wrongness
  detector.** It scored `FIELDS_DROPPED = 0` on three different writes nobody asked for, including
  a correct-shaped wrong value. Pair it with an assertion that the set of changed
  (file, field, value) triples **equals the set the tool proposed** — which
  `normalise-dj-tags.py`'s dry-run NDJSON already provides and a blind tool structurally cannot.
  **DEF-03-10.**
- **Phase 7's "undo exercised" criterion now has two candidate mechanisms, not one** — see
  § *AMENDMENT — 2026-09-04, plan 03-11* § 5.

**4. Phase 9 inherits an untested risk and a duplication decision.**

- **The 144-folder lag risk is UNTESTED and this phase's good five-album showing is not evidence
  against it.** beets-flask's own `docs/limitations.md` says the UI *"will get laggy"* past *"some
  hundred folder or so"* (#164, #175), and the backlog sits just under that. **Recorded before any
  score existed**, precisely so a good score could not be read as reassurance. Friction 5 stays
  `NOT EXERCISED`.
- **DUPE-01 needs a roadmap decision before Phase 7.** Phase 1 measured **828 duplicate groups /
  1,892 records / 19.4% duplication**, and this phase re-confirmed that **`dj-mixes` is a
  byte-for-byte duplicate subset of `unsorted`** — separate inodes (242325 vs 206407), link count
  1, identical sizes, all 85 entries present in `unsorted` by name. **That makes Phase 7's diff
  join last-wins**, which is a silent behaviour, not a chosen one. Decide which side wins **before**
  importing, or the library gets both — `beets.md` § *Before any bulk run* already says so and the
  measurement now backs it.

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

**CLOSED — 2026-09-04, plan 03-11.** The open item above is resolved and the resolution is recorded
here rather than replacing the paragraph, so the sequence stays visible. The orchestrator has since
merged the waves, and all three assertions were re-run **from plan 03-11's own worktree** rather
than taken on any earlier plan's word:

```
$ git cat-file -t 137b6d9e92cb44d9c6a48b3963bb33fe0194622f
commit

$ git branch -r --contains 137b6d9e92cb44d9c6a48b3963bb33fe0194622f
  origin/HEAD -> origin/main
  origin/main

$ git merge-base --is-ancestor 137b6d9e92cb44d9c6a48b3963bb33fe0194622f origin/main ; echo $?
0
```

**The SHA survived the merge unchanged**, which is what this section predicted on the grounds that
this repository merges rather than squashes or rebases — now verified rather than assumed. Custody
of criterion 5 therefore rests on `origin/main`, not on a local branch and not on the author's
restraint.

---

## Teardown — 2026-09-04, plan 03-11

Everything this phase created is throwaway by construction. This section records each step, the
command, the result, and the route for anything delegated to atlantis. **The artefacts are the
deliverable and are kept**: every `.md` in the phase directory, the six committed scripts under
`scripts/`, and the three archived YAMLs.

### 1. Containers — all three gone, confirmed with no status filter

```
docker compose -p spike-03-beets-flask --profile manual -f 03-spike-beets-flask.yaml down
docker compose -p spike-03            --profile manual -f 03-spike-beets.yaml       down
```

| Container | `docker ps -a --format '{{.Names}}' \| grep -cx` |
|---|---|
| `beets-spike` | **0** |
| `beets-spike-rw` | **0** (already down since 03-05's `--apply`) |
| `beets-flask-spike` | **0** |
| any name containing `spike` | **(none)** |

**No status filter was used**, deliberately: this estate has a documented `created`-state blind
spot, and `status=restarting/dead/exited` once missed two containers that were silently down for
six weeks. **`--remove-orphans` was not passed to either file** (DEF-03-12), and an **explicit
`-p`** was passed to both so neither could reach the other's container.

**A trap found while doing it, recorded because it fails silently.** The flask arm's service
carries `profiles: ["manual"]`. The first `down` **without** `--profile manual` **exited 0, printed
nothing at all, and left the container running** — and a teardown that greps for "Removed" in the
output would have recorded a pass. It was caught only by asserting the container's absence
afterwards rather than trusting the command's exit code. Written into the file's own banner.

**Container count: 104, against the `03-REAP-LIST.md` baseline of 103 — and the +1 is not this
phase's.** All three spike containers are provably absent. The delta is a non-spike container
created **2026-09-02**, after the 2026-09-01T23:02Z baseline was taken; the `cal-*` (keeper.sh)
stack was recreated that day. **Stated as unattributed rather than explained away** — the baseline
recorded a count, not a name list, so the specific container cannot be identified from the record.

### 2. Credential-bearing runtime files — deleted, and the sweep found MORE than the plan named

**The plan named one file: `/mnt/fast/spike-03/beets-config/spike-runtime.yaml`. That path did not
exist.** A value sweep found **three** token-bearing files under `/mnt/fast/spike-03/`:

```
/mnt/fast/spike-03/beets-config/config.yaml
/mnt/fast/spike-03/beets-config/import-xcheck.yaml
/mnt/fast/spike-03/bf-config/beets/config.yaml
```

**Delete-by-name alone would have left all three.** This is why the acceptance criterion is a value
sweep and not a filename: the plan's own inventory of where a credential went was wrong, in the
direction of under-counting.

The whole `/mnt/fast/spike-03/` tree (215 M) was then removed by exact path.

| Sweep | Result |
|---|---|
| `/mnt/fast/` full recursive, **before** teardown | **4** files — the 3 above **+** `/mnt/fast/secrets/discogs.env` |
| `/mnt/fast/` full recursive, **after** teardown | **1** file — `/mnt/fast/secrets/discogs.env` **only** |
| `/mnt/fast/secrets/discogs.env` | **present**, `mode=600`, `owner=root:root` — the phase cleaned up its copies, not the source |
| Shell history on LXC 100 | **0 hits.** Only **one** history file exists at all (`/root/.bash_history`, 522 bytes, **mtime 2026-08-15** — before this phase began). `/root/.zsh_history`, `.python_history` and `.sqlite_history` do not exist and `/home` is empty. Non-interactive `ssh host 'cmd'` does not append, which is why 03-07's design intent held |

**The `/mnt/tank/downloads` half is answered by containment, not by scanning, and the reason is
stated so the substitution is auditable.** A full-content sweep of that pool is not viable —
`zfs list` reports it at **2.05 TB** (it holds a large `dropbox`, `google takeout` and `icloud`
archive alongside the backlog), and a byte-by-byte grep would run for hours. Two bounded
instruments answer the same question:

1. **Containment, from the archived compose files.** Every `/mnt/tank/**` mount on **either** arm
   points inside `/mnt/tank/downloads/spike-03/` — asserted mechanically:
   `grep -hoE 'source: /mnt/tank/[^ ]*' <both files> | sort -u | grep -v '/mnt/tank/downloads/spike-03'`
   returns **nothing**. **No spike process could reach any other path under that pool**, so the
   scratch tree is the complete candidate set.
2. **A full, unbounded grep of that candidate set, run BEFORE it was deleted:**
   `/mnt/tank/downloads/spike-03/` held **0** token-bearing files. The tree is now gone regardless.

**Both instruments were run with the token supplied through `grep -f <(printf …)`** — `printf` is a
bash builtin, so the value never entered any process's argv. **That technique was adopted
mid-teardown after the earlier one leaked; see § 8.**

### 3. The scratch tree — gone, and nothing over-deleted

`/mnt/tank/downloads/spike-03` (**45 G**) removed by exact path. All ten children the phase created
were present and went with it: `raw/`, `normalised/`, `normalised-metadata/`, `wrtag-src/`,
`bf-inbox/`, `bf-clean/`, `smoke/`, `wav-raw/`, `wav-mutagen/`, `wav-metadata/`.

**No `git clean`, no blanket `rm -rf` of a parent, no glob.** Siblings asserted intact afterwards:
`complete`, `dropbox`, `google takeout`, `icloud`, `incomplete`, `lidarr-import`, `media`,
`pickup`.

**ZFS was re-read after a deliberate wait**, because it frees asynchronously and a figure taken
immediately is not a measurement:

| | Before | After |
|---|---|---|
| `tank/downloads` used | 2.05 T | **2.00 T** |
| pool available | 8.98 T | **8.99 T** |

**Only ~50 G came back from a 45 G tree, and that is the expected result, not a discrepancy:** the
tree was **reflinked** from the real backlog, so most of its blocks were shared and are still
referenced by `complete/nzb`. Reflinked clones free space only when the last reference goes.

### 4. Snapshots — two destroyed, Phase 1's fence untouched

**Route: run on atlantis (`172.16.1.158`), the Proxmox host.** LXC 100 is unprivileged and cannot
destroy a ZFS snapshot. Destroyed by exact name, one at a time:

| Snapshot | Decision | Reason |
|---|---|---|
| `tank/downloads@spike-03-t0` | **DESTROYED** | Its only purpose was `normalise-dj-tags.py`'s rollback, and the tree it protected no longer exists |
| `tank/downloads@spike-03-t2-wav` | **DESTROYED** | Same, for the 03-09 WAV bake-off |
| `tank/downloads@pre-project` | **KEPT** | Phase 1's fence. Not this phase's to touch |
| `tank/downloads@pre-chown` | **KEPT** | Phase 1's |
| `tank/media/Music@pre-project` | **KEPT** — asserted present | Phase 1's fence |

**A measured confirmation of why a stale snapshot is not free.** `@spike-03-t2-wav` held **236 M**
while the scratch tree existed. The moment the tree was deleted it held **31.6 G** — the snapshot
had become the last reference to every block the delete released. Had it been kept, the 45 G tree
would have been "deleted" while costing more disk than before.

### 5. The three spike YAMLs — ARCHIVED, and the trade-off recorded in both directions

**This is a deliberate exception to the teardown, decided by the operator, and it cuts against this
project's own documented failure mode. It is recorded as a resolved trade-off so a later reader
does not read it as an oversight.**

**For deleting them:** a surviving spike config is exactly how a fourth tagging path gets read back
into the repo six weeks later, and **this project exists because the pipeline was built three times
and abandoned three times.** `PROJECT.md` § *Core Value* names a fourth half-built path as "the one
outcome that must not happen".

**For archiving them:** these files sit under `.planning/`, **never under `stacks/`**, so they are
not on any deployable path in this repo's documented workflow. Deleting them destroys — one-
directionally — **the exact executable configuration behind every number in this phase**, which is
what makes the spike reproducible and auditable if the decision is later challenged. A prose
reproduction in a summary is not the same artefact.

**The operator chose archiving.** The controls that make it safe, each asserted:

| Control | Assertion | Result |
|---|---|---|
| Banner is the literal first line | `head -1` on each of the three | **`# THROWAWAY — DO NOT DEPLOY`** ×3 |
| Nothing deployable points at them | `grep -rl '03-spike-' stacks/` | **(nothing)** |
| Still tracked, not deleted | `git ls-files .planning/phases/03-tagger-spike/` | all three present |
| State recorded in-file | each carries a block naming the removed containers, that absence was confirmed with **no status filter**, that the trees it mounts are gone so an accidental `up` fails on missing binds, and that any future use needs a decision recorded in a plan | added by this plan |

**What this does NOT relax:** the containers are still gone, and **every credential-bearing runtime
file is still deleted**. The banner is a marker on an inert file, not permission for one to run.
The residual risk is a human deliberately running `docker compose -f` against a `.planning/` path
in defiance of the banner — and none of the three would start, because their binds no longer exist.

**No archived YAML ever carried a credential.** `03-spike-beets-config.yaml` has no `user_token`
key by construction, and both compose files reach the token through `env_file:` by variable name.

### 6. Images — a decision per image, no blanket sweep

| Image | Size | Decision | Reason |
|---|---|---|---|
| `lscr.io/linuxserver/beets:2.13.1-ls349` | 638 MB | **RETAIN** | Axis one's winner. Phase 6 configures it, and the digest-pinned tag is the exact build every axis-one number was measured on |
| `metasauce/beets-flask:v2.0.0-rc6` | 1.12 GB | **RETAIN** | Axis two's winner (the inbox architecture). Phase 5 needs this exact RC — it is what the frictions and the `bootleg` results were measured against, and rc7 would not be the same tool |
| `sentriz/wrtag:v0.33.0` | 186 MB | **PRUNED** | Loser, pulled by this phase for criterion 3. Disqualified on measurement; nothing downstream needs it |
| `sentriz/wrtag:v0.34.0` | 189 MB | **PRUNED** | Same. OD-5 recorded it as a path-format no-op against v0.33.0, so re-pulling would answer nothing new |
| `sentriz/wrtag:v0.20.0` | 172 MB | **LEFT ALONE — not this phase's to decide** | It **predates** this phase and is the tag `stacks/selfhosted/music/wrtag.yaml` still pins. Pruning it would break a frozen stack definition D-03 forbids this phase from touching. **Phase 4 owns it, alongside TAGR-03** |

Both removals were **by tag, never by ID** — 03-01 measured that deleting by ID fails where two
tags share one image — and each was preflighted with a check that **no container in `docker ps -a`
referenced it** (none did).

### 7. `/` headroom — better than the phase found it

| Reading | Value |
|---|---|
| `03-REAP-LIST.md` § *After* (2026-09-02, post-prune) | 36 GiB |
| During the trial (03-10 close) | 34 G |
| **At Phase 3 close** | **35 G free of 126 G (72% used)** |
| OD-1 floor | 8 GiB |

**`/` is 1 G better than the phase left it at 03-10 close and 1 G below the post-prune high-water
mark**, having carried a 215 M runtime tree, a 638 MB and a 1.12 GB image and a beets import
destination on it throughout. **No remediation needed.** The thing to watch on this path is
`df -h /`, never `zfs list`: `/mnt/fast/spike-03` was on **LXC 100's ext4 root, not the `fast`
pool**, and `/` has a documented history of being filled to zero.

### 8. A credential exposure caused by this plan's own verification, recorded rather than buried

**The Discogs token was exposed three ways during this teardown, by my own improvised sweep
command.** It is recorded here in full because DEF-03-04 already warned about exactly this class
of lapse and this is its third occurrence in the phase.

**What happened.** The first sweeps passed the token as a **command-line argument**
(`grep -lF -- "$TOK" …`). A process's argv is world-readable through `/proc` on Linux, so for the
~45 minutes those scans ran, **any local user on LXC 100 could read the live token from `ps`.**
Then, while trying to confirm the scans had stopped, `pgrep -af` **rendered that argv** — printing
the token into the executing agent's transcript **and** into a persisted tool-output file on the
workstation at
`~/.claude/projects/-Users-damian-Development-damianflynn-selfhost-stacks/…/tool-results/bla6jts0m.txt`.
**That file could not be deleted from within this session** (the delete was refused by policy) and
**is still on disk.**

**Contained, to the extent it can be.** Every token-bearing process was terminated and
`pgrep -c -x grep` returns **0**, so the value is no longer in any argv on the host. The remaining
sweeps were re-run with `grep -f <(printf '%s' "$TOK")` — `printf` is a bash **builtin**, so the
value never enters any process's argv. Nothing token-bearing was committed to this repository.

**What cannot be contained:** the transcript, and the persisted workstation file named above.

**This is not a new *kind* of finding — it is the same one, a third time.** DEF-03-04 recorded the
token written to a `644` file by `urllib3` DEBUG logging because it travels as a **query
parameter**, not an `Authorization` header, and its closing instruction was explicit: *"Never write
a credential to disk from an improvised verification command… screen by value, from inside the
container, printing only counts."* **This plan printed only counts and still leaked**, because the
leak channel was the **argv of the counting command**, which that instruction did not name.

**Consequences for the standing rotation action — see § 9.** Logged as **DEF-03-21**.

### 9. Standing action carried forward: rotate the Discogs token — now with FOUR causes

**The operator has DECIDED that rotation happens at PROJECT CLOSE, not now.** This plan did **not**
rotate and did **not** block on it. The action is carried forward prominently because the reasons
have accumulated well beyond D-04's original one:

| # | Cause | Recoverable? |
|---|---|---|
| 1 | D-04: the token passed through a conversation transcript when it was first supplied | **No** |
| 2 | DEF-03-04: written in cleartext to a `644 root:root` file by `urllib3` DEBUG, because `python3-discogs-client` sends it as a **`?token=` query parameter**, not a header. Contained same-day — redacted copy at `600`, original `shred -u -n 3`ed | The file, yes; the agent transcript it also reached, **no** |
| 3 | This plan, § 8: exposed in **process argv** on LXC 100 for ~45 min, world-readable via `/proc` | Processes killed; the window cannot be un-opened |
| 4 | This plan, § 8: rendered by `pgrep -af` into an agent transcript **and** a persisted workstation file that **could not be deleted from this session** | **No — and the file is still on disk** |

**Cause 4 is new information the operator did not have when they set the timing.** It is surfaced
at the closing checkpoint rather than acted on unilaterally: **the decision on when to rotate is
theirs, and this record's job is to make sure it is made on current facts.**

**The standing rule this repository operates under, restated because it was breached here:** this
repo is **public** and pushed to `origin`. Credentials live in `/mnt/fast/secrets/` (mode `600`,
root-owned) and `~/.claude/secrets/`, and are referenced **by variable name only**. Screen every
artefact by **value** and by token prefix before committing — and **never pass a secret as a
command-line argument**, on any host, even to a command that prints only a count.

### 10. Retained deliberately, and why

| Artefact | Why it is kept |
|---|---|
| `scripts/normalise-dj-tags.py` | **D-08 requires it committed and regenerable**, and D-13 named it *the* normalisation tool. Its WAV defect (DEF-03-09) is Phase 4's to fix |
| `scripts/spike03-discogs-probe.py` | Criterion 1's paired figures must be reproducible. Also carries the `SecretRedactingFilter` that closed DEF-03-04 at the logging record |
| `scripts/spike03-variant-survey.sh` | Produced the per-stratum weights T1's estimator is computed from |
| `scripts/spike03-wrtag-arms.sh` | Criterion 3's six arms; the disqualifier must be re-runnable |
| `scripts/spike03-image-headroom.sh` | The OD-1 gate, read-only `inventory` mode included |
| `scripts/spike03-gen-import-config.sh` | Rendered the `beet import -t` config from `os.environ` **without** the token reaching argv or a plan file |
| Every `.md` in the phase directory | **This is the deliverable.** Nine evidence artefacts plus this record |

All six scripts are **committed and tracked** (`git ls-files scripts/`), so deleting the host
staging copies under `/mnt/fast/spike-03/` lost nothing.

### 11. Library integrity at close

| Assertion | Instrument | Result |
|---|---|---|
| Real backlog untouched | `find /mnt/tank/downloads/complete/nzb -type f \| wc -l`, before and after teardown | **8,934 → 8,934** |
| Real backlog not written during this plan | `find … -newermt '2026-09-04 16:00'` and `-newerct` | **0 and 0** |
| …and the instrument was **sighted**, not blind | the same `find` over the downloads tree at `-maxdepth 2` | **1** — the downloads root itself, whose mtime moved when `spike-03/` was removed. Per DEF-03-11, a zero from an instrument that cannot see anything is not a pass |
| Phase 1 fence intact | `zfs list -t snapshot` on both datasets, from atlantis | `tank/downloads@pre-project` and `tank/media/Music@pre-project` both **present** |

**`zfs diff tank/media/Music@pre-project` is NOT asserted "clean", because that assertion is
unsatisfiable and has been since 2026-08-18** (DEF-03-19). It returns 2,674 lines against a tree of
exactly 2,674 entries — the signature of Phase 1 plan 01-08's ownership normalisation against a
snapshot predating it. **The substitute instruments DEF-03-19 recommended are used instead**, and
the remaining Music-tree assertions are run at the closing checkpoint.

---

## Files this phase reads and quotes but does NOT edit (D-03)

- `stacks/selfhosted/music/wrtag.yaml` — lines 71 and 73, quoted verbatim above.
- `stacks/selfhosted/arrs/beets/beets.yaml` — `:ro` on `/media`, `restart: "no"`,
  `profiles: ["manual"]`.
- `renovate.json5` line 91 — the wrtag hold rule.

Both spike containers are **throwaway**. The spike measures; **Phase 4 deletes the loser; Phase 6
configures the winner.** Do not half-deploy a decision that has not been made.
