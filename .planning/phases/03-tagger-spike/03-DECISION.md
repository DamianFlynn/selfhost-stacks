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
| T1 | Discogs matching under **40%** of the backlog after normalisation | The **backlog-weighted strict** rate per D-05, where **strict** means a Discogs candidate appears AND its track count agrees with the folder AND `extra_items == 0` AND `extra_tracks == 0`. Computed **per stratum** over the plan-03-03 sample, then weighted by each stratum's prevalence across the committed 143-folder backlog, and summed. The `discogs.index_tracks` setting that produced the headline number is stated beside it. The **unweighted** per-folder sample rate is reported alongside and is explicitly **not** the figure T1 is tested against — see § *The estimator T1 is tested against*. The **40% threshold value is unchanged** | The criterion-1 `tag_album()` probe (plan 03-06/03-07), cross-checked by a hand-transcribed `beet import -t` on **4–5 folders** that between them cover at least one **DMC** folder, one **missing-`album` (V3)** folder, one **index-track-sensitive** folder, and one **zero-candidate** folder. Three folders cannot cover the four cases most likely to diverge, and paired-instrument confidence must not be claimed more broadly than the cross-check supports | PENDING | PENDING |
| T2 | Rate limiting makes bulk import impractical | **More than 4 hours of projected wall-clock for the 143-folder backlog**, OR **any observed HTTP 429 during the timed run**. Either condition alone fires the threshold | `time` around the probe run, cross-checked against `grep -c 'api\.discogs\.com'` on the probe stderr (`urllib3` DEBUG), plus a **separate 429 counter** — `python3-discogs-client` retries a 429 up to 100 times with jittered backoff, so a rate-limited run stalls silently rather than erroring | PENDING | PENDING |
| T3 | The operator will not sit at the interactive prompt | An explicit **written self-assessment** after the timed hands-on trial, in the operator's own words. **T3 is deliberately not a number** — the roadmap defines it as a self-assessment and quantifying it would be false rigour | Plan 03-10's timed hands-on trial, scored on [`03-ERGONOMICS-SHEET.md`](03-ERGONOMICS-SHEET.md) | PENDING | PENDING |

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
| V1 | `artist="Mastermix"`, `album="Mastermix Issue NNN"` — `va_likely=false`, query = album alone | PENDING — filled by plan 03-03 | PENDING | PENDING | PENDING |
| V2 | `artist` is `VA` / `Various Artists` / `Various`, `album` present — query becomes `"VA <album>"` | PENDING — filled by plan 03-03 | PENDING | PENDING | PENDING |
| V3 | `album` absent — **no Discogs query is issued at all** | PENDING — filled by plan 03-03 | PENDING | PENDING | PENDING |
| V4 | `artist` absent — `va_likely=true` via `not consensus["artist"]` | PENDING — filled by plan 03-03 | PENDING | PENDING | PENDING |
| V5 | `album` present but noisy (`- Disc 1`, ` WEB`, `Vol.`, `Mastermix - ` prefix, trailing space) | PENDING — filled by plan 03-03 | PENDING | PENDING | PENDING |
| V6 | Real per-track artists (newer issues) — `va_likely=false`, query = album alone | PENDING — filled by plan 03-03 | PENDING | PENDING | PENDING |
| **Weighted total** | Sum of contributions — **this is the figure T1 is tested against** | PENDING — filled by plan 03-03 | PENDING | PENDING | PENDING |
| *(memo)* Unweighted | Plain per-folder rate across the whole sample — **reported, not tested** | n/a | PENDING | PENDING | n/a |

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
| Discogs backend exists | PENDING | PENDING |
| Strict match rate on the widened sample (backlog-weighted) | PENDING | PENDING |
| Path format renders at all | n/a | PENDING |
| Behaviour on unmatched DJ content | PENDING | PENDING |

**Axis one verdict:** PENDING — filled by plan 03-11.

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
| Wall-clock across the 5-album set | PENDING | PENDING |
| Interventions | PENDING | PENDING |
| Context switches | PENDING | PENDING |
| Answer for content no source will match | PENDING | PENDING |

**Axis two verdict:** PENDING — filled by plan 03-11.

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
| 3a | *(D-12's inference)* `metadata` is *"plausibly a direct competitor to the mutagen script"* | `cmd/metadata/main.go` `cmdWrite()`: builds one literal `map[string][]string` and applies it to **every** path via `iterFiles`; **no `-dry-run`, no diff, no field-to-field move**; only flags are `-log-level`, `-properties` (read), `-index`/`-type`/`-desc`/`-mime-type` (images) | **CHANGED — materially weaker than claimed** | An `artist`→`album` remap needs one `read` + one `write` **per file**, in a shell loop, writing blind. D-13's bake-off is still worth running (it is cheap) but the reviewability requirement in D-08 is unmet by `metadata` unless wrapped |
| 3b | *(new, not in PROJECT.md)* what `metadata write` does to unlisted tags | `tags.WriteTags(path, t, 0)` — flag `0`, **not** `tags.Clear` | **NEW — favourable to `metadata`** | `metadata write` **merges**; it will not silently drop `TKEY`/`EnergyLevel`. Confirm empirically with `diff-music-tags.sh` — do not take this from source alone |
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
| beets (terminal) | `beet import -A` (as-is) after normalisation; `--set albumtype=dj` + a `paths:` rule routes it out of `Compilations/` | PENDING |
| beets-flask | An inbox with `autotag: "bootleg"` — *"Import as-is using the meta data of files, and group albums using the metadata… Effectively `beet import ... --group-albums -A`"* | PENDING |
| wrtag | **`WRTAG_RESEARCH_LINK` — a hyperlink to a Discogs search, for the human to resolve manually** | PENDING |
| wrtag (side effect) | A real `move`/`copy` calls `tags.WriteTags(dest, destTags, tags.Clear)` — **all tags not in wrtag's computed set are wiped** unless a `keep` rule is configured | PENDING |

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
`dj-mixes` are at stake.** Confirmation status: PENDING — filled by plan 03-08.

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
| Dry-run | **Yes, and it is the default** | **No.** No flag exists on `write` | PENDING |
| Reviewable diff before writing | Yes, per-file | No | PENDING |
| Per-file distinct values in one invocation | Yes | **No** — one literal map to every path | PENDING |
| Field-to-field move | Yes (read then write) | **No primitive** | PENDING |
| Preserves unlisted tags | Yes | Yes — `WriteTags(path, t, 0)`. **Verify empirically** | PENDING |
| Formats | MP3, FLAC, WAV (partial) | MP3, FLAC, **WAV** and 30+ others via taglib | PENDING |
| Committed, versioned, auditable | Yes (`scripts/`) | The loop would be; the tool is not | PENDING |

**Prediction:** the mutagen script wins on reviewability; `metadata` may win on WAV. **Verdict:**
PENDING — filled by plan 03-09.

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

## Files this phase reads and quotes but does NOT edit (D-03)

- `stacks/selfhosted/music/wrtag.yaml` — lines 71 and 73, quoted verbatim above.
- `stacks/selfhosted/arrs/beets/beets.yaml` — `:ro` on `/media`, `restart: "no"`,
  `profiles: ["manual"]`.
- `renovate.json5` line 91 — the wrtag hold rule.

Both spike containers are **throwaway**. The spike measures; **Phase 4 deletes the loser; Phase 6
configures the winner.** Do not half-deploy a decision that has not been made.
