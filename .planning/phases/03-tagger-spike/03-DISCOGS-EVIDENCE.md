# Phase 3 criterion 1 and 2 evidence — the Discogs match rate and the rate-limit projection

Companion to [`03-DECISION.md`](03-DECISION.md) (the pre-committed thresholds this document fills
in), [`03-SAMPLE.md`](03-SAMPLE.md) (the 24 drawn folders and the backlog weights),
[`03-NORMALISATION.md`](03-NORMALISATION.md) (what the normalised arm actually contains) and
[`03-PROBE-SMOKE.md`](03-PROBE-SMOKE.md) (the A1 gate that licensed this run).

Nothing here is applied by `docker compose`. This is the record of what Discogs returned for this
collection, timed, and what that does to T1 and T2.

State as of 2026-09-04 — **six cells run, 291 Discogs requests spent, zero HTTP 429, T1 and T2
both tested.**

> **Headline, up front: T1 FIRES and T2 does NOT.**
> The backlog-weighted strict Discogs match rate on the normalised arm is **27.08%**, against a
> pre-committed threshold of 40%. The projected wall-clock for the whole backlog is **21.8
> minutes** against a 4-hour limb, with **zero** observed HTTP 429. Neither threshold value was
> moved, and neither was the estimator.

---

## Custody — checked BEFORE any number was recorded

Criterion 5's proof is a commit on a remote, not an ordering on a local branch. Plan 03-02 pushed
its threshold commit to its own worktree branch because `origin/main` then stood *behind* the
phase-start commit; the orchestrator has since merged and pushed `main`, so the ancestry check
that 03-02 deferred now completes.

| Assertion | Command | Result |
|---|---|---|
| The SHA resolves | `git cat-file -t 137b6d9e92cb44d9c6a48b3963bb33fe0194622f` | **`commit`** |
| Reachable from the remote | `git branch -r --contains 137b6d9e…` | lists **`origin/main`** (and `origin/HEAD -> origin/main`) |
| Ancestor of `origin/main` | `git merge-base --is-ancestor 137b6d9e… origin/main` | **exit 0** |
| It introduced the thresholds | `git show 137b6d9e… -- 03-DECISION.md` | **402 insertions, 0 deletions**; adds the T1, T2 and T3 rows and § *The estimator T1 is tested against* |
| Its subject | | `docs(03-02): commit T1/T2/T3, the estimator and the empty scoring sheet before any evidence` |
| Committer timestamp | | `2026-09-03 20:27:13 +0100` |

**The threshold commit SHA, verbatim:**

```
137b6d9e92cb44d9c6a48b3963bb33fe0194622f
```

All four limbs passed before the first probe ran. Had any failed the run would have stopped: a
threshold whose custody rests on an unpushed local branch is a threshold that could have been
amended.

---

## Mandatory preflight — the bind-mount inode assertion

03-05 finding: a bind mount pins the directory **inode**, not the path. A re-materialised
directory leaves the container bound to the dead inode, and every command over it **exits 0
reporting 0 files**. This plan measures *rates*, where zero is a plausible-looking answer that
would falsify T1 on an artefact — so the assertion is made from both sides, before measuring.

| Arm | Host folders / audio | Container folders / audio | Host inode | Container inode | Agree |
|---|---|---|---|---|---|
| `raw` | 24 / 335 | 24 / 335 | 229532 | 229532 | **yes** |
| `normalised` | 24 / 335 | 24 / 335 | 232124 | 232124 | **yes** |

No force-recreate was needed. **One false zero did occur and was caught**: the first container-side
count returned `0 / 0` because the command used `/spike-samples/<arm>`, a path that does not exist —
the mount destination *mirrors the host path*. That is the preflight working exactly as intended,
on the operator's own command rather than on a stale inode.

The instrument itself was re-verified before use: the staged probe and the committed blob both
hash to `0dd5520d6e9cfddb11967761efb7ff5817c1c4a4d44b99fedb27cc91f8e962c7`, 03-06's recorded value.
It was then modified once, deliberately, and re-staged — see § *The one change made to the probe*.

---

## The four cells

`discogs.search_limit: 5`, `musicbrainz.searchlimit: 5`, `match.preferred.countries: ['GB','US']`,
`discogs.index_tracks: no` unless stated. Every cell covers **24 distinct folders**
(`jq -s 'group_by(.folder)|length'` = 24 on all six NDJSON files) with an **empty `.failed`
ledger** and exit **0**.

| Cell | Arm | Plugins | LOOSE | LOOSE % | STRICT | STRICT % | Gap |
|---|---|---|---|---|---|---|---|
| `raw-mb` | un-normalised | `musicbrainz` | 0/24 | 0% | 0/24 | 0% | 0 |
| `normalised-mb` | normalised | `musicbrainz` | 0/24 | 0% | 0/24 | 0% | 0 |
| `raw-mbdiscogs` | un-normalised | `musicbrainz discogs` | **9/24** | **37.5%** | **6/24** | **25.0%** | **3** |
| `normalised-mbdiscogs` | normalised | `musicbrainz discogs` | **13/24** | **54.2%** | **6/24** | **25.0%** | **7** |

The two MB-only cells return **zero** Discogs candidates *by construction* — the plugin is not
loaded, and `grep -c 'api\.discogs\.com'` on their stderr is **0**. They are the control that shows
the Discogs numbers above are the Discogs plugin's doing and not an artefact of the harness.

**Normalisation buys loose matches and buys no strict ones.** The un-normalised arm is criterion
1's "raw tags" figure and the normalised arm is the figure T1 applies to. Normalisation lifts the
loose rate by **4 folders** (37.5% → 54.2%) and moves the strict rate **not at all** (6 → 6). The
lift is entirely in V2 — the stratum whose `artist` was set to a consistent label — and it converts
"no candidate at all" into "a candidate that does not survive a track-count check".

### The D-05 strict predicate, and the second reading of it

Scored independently of the probe's own counters, straight from the NDJSON:

```bash
jq -s 'group_by(.folder)
  | map({folder: .[0].folder,
         loose:  (any(.[]; .source == "Discogs")),
         strict: (any(.[]; .source == "Discogs"
                        and .n_tracks == .n_files
                        and .extra_items == 0
                        and .extra_tracks == 0))})' cell-<name>.ndjson
```

| Cell | Probe's own summary | Independent `jq` | Agree |
|---|---|---|---|
| `raw-mbdiscogs` | loose 9, strict 6 | loose 9, strict 6 | **yes** |
| `normalised-mbdiscogs` | loose 13, strict 6 | loose 13, strict 6 | **yes** |
| `raw-mbdiscogs-it` | loose 9, strict 6 | loose 9, strict 6 | **yes** |
| `normalised-mbdiscogs-it` | loose 13, strict 6 | loose 13, strict 6 | **yes** |

---

## `index_tracks` — measured, and it is a no-op on this sample

The strict rule is meaningless without stating how tracks were counted, and Mastermix/DMC releases
on Discogs commonly carry index tracks and headings. Both settings were therefore **run**, not
reasoned about — `index_tracks` changes what the Discogs plugin *fetches*, so it cannot be applied
to an existing NDJSON at scoring time.

| Arm | `index_tracks: no` | `index_tracks: yes` |
|---|---|---|
| `raw` | loose 9, strict 6 | loose 9, strict 6 |
| `normalised` | loose 13, strict 6 | loose 13, strict 6 |

Stronger than the equal rates, and the reason no folder flipped:

> **70 (folder, release) Discogs candidate pairs were compared across the two settings, on both
> arms. The candidate key sets are identical, and `0` of the 70 differ on `n_tracks`,
> `extra_items` or `extra_tracks`.**

**The headline number is produced at `discogs.index_tracks: no`** — the config default and the
setting 03-06 gated the instrument at. The `yes` arm is reported beside it and returns the same
figure.

One folder does differ in total record count between the two runs — `Mastermix_Issue_410.1`, 2
records against 7. The difference is entirely on the **MusicBrainz** side and is explained in
§ *MusicBrainz throttles with 503*; no Discogs candidate moved.

---

## The strict/loose gap

| Arm | Loose | Strict | Gap (folders) | Gap (% of 24) |
|---|---|---|---|---|
| `raw` | 9 | 6 | **3** | **12.5%** |
| `normalised` | 13 | 6 | **7** | **29.2%** |

**What the gap implies for verification load.** On the normalised arm, **7 of the 13 folders that
return a Discogs candidate — 54% of them — return one that fails the track-count check.** A
workflow that accepted "a Discogs candidate appeared" as success would take a wrong release more
often than not on the folders it thought it had solved. The gap is the manual-verification bill,
and normalisation more than doubles it (3 → 7) while adding no correct matches.

---

## Weighted roll-up — the headline

Computed exactly as the estimator committed in `137b6d9e…` specifies: the strict rate within each
stratum over that stratum's sampled folders, multiplied by that stratum's prevalence across the
backlog, and summed. `backlog_weight` values are from
[`03-SAMPLE.md` § *Stratum prevalence*](03-SAMPLE.md).

### Strict — `normalised` × `musicbrainz discogs`, `index_tracks: no`

| Stratum | Sampled | Strict hits | Strict rate | `backlog_folders` | `backlog_weight` | Contribution |
|---|---|---|---|---|---|---|
| V1 | 6 | 4 | 0.6667 | 37 | 0.2569 | 0.6667 × 0.2569 = **0.1713** |
| V2 | 9 | 0 | 0.0000 | 39 | 0.2708 | 0.0000 × 0.2708 = **0.0000** |
| V3 | 2 | 0 | 0.0000 | 11 | 0.0764 | 0.0000 × 0.0764 = **0.0000** |
| V4 | 0 | — | n/a | **0** | **0.0000** | **0.0000** — zero weight, contributes nothing whatever its rate |
| V5 | 6 | 2 | 0.3333 | 43 | 0.2986 | 0.3333 × 0.2986 = **0.0995** |
| V6 | 1 | 0 | 0.0000 | 14 | 0.0972 | 0.0000 × 0.0972 = **0.0000** |
| **Sum** | **24** | **6** | | **144** | **0.9999** | **0.2708** |

`0.1713 + 0.0000 + 0.0000 + 0.0000 + 0.0995 + 0.0000 = 0.2708`

### **WEIGHTED STRICT RATE = 27.08%**

### Loose — same cell

| Stratum | Sampled | Loose hits | Loose rate | `backlog_weight` | Contribution |
|---|---|---|---|---|---|
| V1 | 6 | 5 | 0.8333 | 0.2569 | **0.2141** |
| V2 | 9 | 5 | 0.5556 | 0.2708 | **0.1505** |
| V3 | 2 | 0 | 0.0000 | 0.0764 | **0.0000** |
| V4 | 0 | — | n/a | 0.0000 | **0.0000** |
| V5 | 6 | 3 | 0.5000 | 0.2986 | **0.1493** |
| V6 | 1 | 0 | 0.0000 | 0.0972 | **0.0000** |
| **Sum** | **24** | **13** | | **0.9999** | **0.5139** |

`0.2141 + 0.1505 + 0.0000 + 0.0000 + 0.1493 + 0.0000 = 0.5139`

### **WEIGHTED LOOSE RATE = 51.39%**

### The un-normalised arm, same arithmetic

| | Weighted strict | Weighted loose |
|---|---|---|
| `raw` × `musicbrainz discogs` | **27.08%** | **40.16%** |
| `normalised` × `musicbrainz discogs` | **27.08%** | **51.39%** |

### Why the weighted figure is the headline

*The sample was built to find failure modes, not to estimate a population. A coverage sample
over-weights minority strata by construction — it deliberately over-represents V3, whose folders
issue no Discogs query at all, and under-represents V5, which is the single heaviest stratum in
the backlog — so its unweighted average is not the backlog's rate. The weighted figure is the
headline for that reason, and the estimator was fixed in the pre-evidence commit
`137b6d9e92cb44d9c6a48b3963bb33fe0194622f`, not chosen after these numbers existed.*

### No stratum is a hole, and the one thin stratum does not change the verdict

A hole would be a stratum with `backlog_weight > 0` and `sampled_folders == 0`, which would have to
be reported as a 0%/100% band and could render T1 **indeterminate**. **There is none.** V4 is the
only unsampled stratum and its `backlog_weight` is exactly **0.0000** — it exists once, in
`dj-mixes`, and nowhere in the deduplicated backlog.

**V6 is thin, not a hole**, and 03-SAMPLE.md flagged it in advance: it rests on **one** sampled
folder, so its rate is 0% or 100% with nothing between, against a weight of 0.0972. Its measured
rate is 0%. Bounding it rather than trusting the point estimate:

| V6 assumption | Weighted strict rate | Verdict against 40% |
|---|---|---|
| V6 = 0% (measured) | **27.08%** | below |
| V6 = 100% (its most favourable bound) | 27.08 + 9.72 = **36.80%** | **still below** |

**The band is 27.08% – 36.80%, width 9.72 points, and it does not straddle 40%.** T1's verdict is
therefore determinate and is not an artefact of V6 resting on one folder. The same is true of V3
(2 folders, weight 0.0764): even at 100% it adds 7.64 points, and V3 + V6 both at 100% reach
44.44% — which is the only combination that crosses 40%, and it requires two zero-measured strata
to both be perfect.

---

## Unweighted sample rate

Reported because it is an honest number about the sample. **It is not the figure T1 is tested
against** — see the estimator paragraph above.

| Arm | Unweighted loose | Unweighted strict |
|---|---|---|
| `raw` × `musicbrainz discogs` | 9/24 = **37.50%** | 6/24 = **25.00%** |
| `normalised` × `musicbrainz discogs` | 13/24 = **54.17%** | 6/24 = **25.00%** |

Both the weighted (27.08%) and the unweighted (25.00%) strict figures fall below 40%. **T1's
verdict does not depend on which estimator is used**, which is worth stating plainly: the estimator
was fixed in advance precisely so that it could not be chosen to land on a convenient side, and in
the event it did not matter.

---

## What actually satisfied D-05 — the finding that qualifies the headline

D-05 requires a track-count agreement. It does **not** require the release to be the right one.
Every strict-satisfying candidate was therefore read:

| Folder | Queried `album` tag | Discogs release that satisfied D-05 | Confidence | Correct? |
|---|---|---|---|---|
| `Mastermix_Issue_410` | `Mastermix Issue 410` | `32813244` *Mastermix Issue 410* | 75.6% | **yes** |
| `Mastermix_Issue_410.1` | `Mastermix Issue 410` | `32813244` *Mastermix Issue 410* | 75.6% | **yes** |
| `VA-Mastermix.Issue.426-2021` | `Mastermix Issue 426` | `25298851` *Mastermix Issue 426* | 64.3% | **yes** |
| `VA-Mastermix.Issue.426-2021.1` | `Mastermix Issue 426` | `25298851` *Mastermix Issue 426* | 64.3% | **yes** |
| `VA-Mastermix.Issue.427.2CD-2021` | `Mastermix Issue 427` | `32816841` *Mastermix Issue 427* | 59.6% | **yes** |
| **`Mastermix_Issue_412`** | **`Issue 412`** | **`1534659` *Specialten Issue 14*** | **31.2%** | **NO** |

**One of the six strict matches is a confident wrong match** — a 2006 Specialten DVD with ten
tracks, matched to a Mastermix issue because both have ten tracks. This is exactly what
`CLAUDE.md` § *Autotagging ceiling* names as worse than no match, and it survived D-05 because
D-05 counts tracks rather than identifying releases.

**The proximate cause is a bare album tag.** `Mastermix_Issue_412`'s `album` reads `Issue 412`, not
`Mastermix Issue 412`. It is classified **V1** — "already the good case" — so no normalisation rule
fired on it. This is the same defect class 03-SAMPLE.md found when it reclassified `album == artist`
out of V1: **V1's definition admits album strings that are clean but identify no release.**

Recomputing the headline on the stricter reading — a Discogs candidate that passes D-05 **and**
names the right release:

| Reading | Unweighted | **Weighted** |
|---|---|---|
| D-05 strict as written | 6/24 = 25.00% | **27.08%** |
| D-05 strict **and correct** | 5/24 = 20.83% | **22.80%** |

**T1 fires on both readings.** The 27.08% headline is reported as the tested figure because it is
what D-05 defines; the 22.80% is recorded beside it because it is the number a later phase should
plan against. A confidence floor of 50% would have separated the six cleanly in this sample — every
correct match scored ≥ 59.5%, the wrong one 31.2% — but that is a one-sample observation, not a
calibrated threshold, and it is offered as a lead for Phase 4 rather than a rule.

---

## By stratum

`normalised` × `musicbrainz discogs`, `index_tracks: no`.

| Stratum | Sampled | Loose | Loose rate | Strict | Strict rate | Reading |
|---|---|---|---|---|---|---|
| V1 | 6 | 5 | 83.3% | 4 | 66.7% | The good case, and it genuinely is — but one of the four is the wrong release |
| V2 | 9 | 5 | 55.6% | **0** | **0.0%** | Normalisation converts no-candidate into candidate, and **none survives the track count** |
| V3 | 2 | 0 | 0.0% | 0 | 0.0% | Derived album names do not resolve on Discogs |
| V4 | 0 | — | — | — | — | Zero backlog weight |
| V5 | 6 | 3 | 50.0% | 2 | 33.3% | Both strict hits are the `Mastermix_Issue_410` near-duplicate pair |
| V6 | 1 | 0 | 0.0% | 0 | 0.0% | One folder; bounded above |

**V2 is the single most important row.** It carries the second-heaviest backlog weight (0.2708),
normalisation lifted its loose rate from 0% to 55.6%, and its strict rate stayed at **zero**. Per
03-05 finding 1, V2's measured lift is the **joint** effect of the artist rule and the album
canonicalisation — 7 of the 9 sampled V2 folders also carry a V5-shaped album that rule 2
rewrote — so it cannot be attributed to the artist rule alone.

---

## By tree (Mastermix vs DMC)

**This is an additional breakdown, not a re-cut of the headline.** Per **OD-3** the sample is ONE
de-duplicated widened population, and **T1's headline strict and loose rates are computed over the
full 24-folder sample with the DMC folders in the denominator** — exactly the population T1's 40%
was committed against in 03-02. Carving DMC out would test the threshold against a different
population than the one it was committed to and would break criterion 5's chain of custody. The
weighting in § *Weighted roll-up* changes how the rate over that population is computed; it does
not change which folders are in it.

| Tree | Folders | Loose | Loose rate | Strict | Strict rate |
|---|---|---|---|---|---|
| `dj-mixes` (Mastermix) | 20 | 11 | 55.0% | 6 | **30.0%** |
| `unsorted` (DMC) | 4 | 2 | 50.0% | **0** | **0.0%** |
| **Total** | **24** | **13** | 54.2% | **6** | 25.0% |

`20 + 4 = 24`, matching the per-cell folder count asserted above.

**For criterion 4, concretely: not one of the four DMC folders produced a Discogs candidate that
survived a track-count check.** Two returned candidates loosely — `Commercial Collection 326` and
`Commercial Collection 318` against a folder that is *Commercial Collection 498* — and both are the
wrong issue by 172 and 180 respectively. `CLAUDE.md` records Discogs carrying `DMC Commercial
Collection 350`; these are issues 498, 499, 233 and 234, and the catalogue does not reach them.
DMC is the content criterion 4 names explicitly, and on this evidence **Discogs does not solve it**.

---

## By dominant format

| Format | Files | Folders | Loose rate | Strict rate |
|---|---|---|---|---|
| MP3 | **335** | 24 | 54.2% | 25.0% |
| WAV | **0** | 0 | — | — |
| FLAC | 0 | 0 | — | — |

**The draw contains zero WAV**, as 03-SAMPLE.md records and flags as a limitation rather than a
convenience: 134 of `dj-mixes`' 764 files are WAV, and all of them sit in V3 and V6 folders that
were either scan-bearing or not drawn. **Research Open Question 5 — whether WAV tagging is
materially weaker here — is therefore NOT answered by this run and must not be read as answered.**
Plan 03-09's D-13 bake-off needs WAV folders named separately.

---

## Denominator statement

| Denominator | Value | Role | Strict | Loose |
|---|---|---|---|---|
| **Per folder** | **24** | **The headline.** The unit of work, and the unit T1 was written against | **6/24 = 25.00%** unweighted, **27.08%** weighted | 13/24 = 54.17% unweighted, 51.39% weighted |
| Per distinct `audio_md5` | **306** | The cross-check, against Phase 1's measured 19.4% duplication | **40/306 = 13.07%** | 107/306 = 34.97% |

The sample was drawn from **one de-duplicated population** precisely so that a naive union over
`dj-mixes` and `unsorted` could not double-count the same audio: 03-SAMPLE.md proves **0** shared
`audio_md5` between the two sides on two independent instruments.

**The two denominators disagree sharply, and the direction matters.** The per-file rate (13.07%) is
roughly half the per-folder rate (25.00%) because **the folders that match are the small ones** —
five of the six strict hits are 10-file Mastermix issues — while the folders that do not match are
the large ones: `VA-Mastermix.Crate.068-070-2025` alone is 60 files, and the four DMC folders carry
65 between them. **Discogs resolves the tail of this collection, not its mass.** Both figures are
reported; the per-folder one is the tested figure because Discogs requests scale with folders.

*(Note DEF-03-03: `audio_md5` is not tag-invariant — it absorbs a trailing ID3v1 block. It is a
valid key here because this cross-check reads a single snapshot; nothing is joined across a write.)*

---

## Second instrument — hand-transcribed `beet import -t`

Timid mode suppresses `tag_album()`'s strong-MBID early return, so it sees the same candidate set
the probe does. Five folders, chosen to cover the cases most likely to diverge rather than three
arbitrary ones. Run through `import-xcheck.yaml` — the same `spike.yaml` with the token injected,
so `search_limit` and `index_tracks` match the headline cell exactly. Every run ended in `B`
(abort); nothing was applied, and both arms are mounted `:ro`.

| Case | Folder | Arm | Case it covers |
|---|---|---|---|
| A | `VA-DMC-Commercial.Collection.498-WEB-2024-MST` | normalised | **DMC** — different label, different tree, the reason OD-3 widened the population |
| B | `VA-Mastermix.Crate.071.Afro.House-2025` | **raw** | **missing-`album` V3** — `has_album_count = 0`, so the plugin issues no query at all |
| C | `VA-Mastermix.Crate.068-070-2025` | normalised | **zero-candidate** — a folder the probe scored loose-fail, selected after the run |
| D | `Mastermix_Issue_412` | normalised | **strict hit** — exercises the strict side, and is where the wrong-match finding came from |
| E | `VA-Mastermix.Issue.446-202` | **raw** | a V3 folder that *does* issue a query (10 of its 20 files carry an album) |

### Agreement, per case

| Case | Probe: total / Discogs / MB | `beet import -t`: total / Discogs / MB | Discogs releases agree | Scores agree | Verdict |
|---|---|---|---|---|---|
| A | 7 / 2 / 5 | 7 / 2 / 5 | **yes** — `326` @ 32.9%, `318` @ 19.2% | yes, both | **Discogs AGREE**; MB set differs |
| B | 5 / **0** / 5 | 5 / **0** / 5 | **yes** — zero on both | n/a | **Discogs AGREE**; MB set differs |
| C | 5 / **0** / 5 | 5 / **0** / 5 | **yes** — zero on both | yes, all 5 | **AGREE, all 10 properties** |
| D | 10 / 5 / 5 | 10 / 5 / 5 | **yes** — all five, in order | yes, all 10 | **AGREE, all 10 properties** |
| E | 10 / 5 / 5 | 10 / 5 / 5 | **yes** — all five, in order | yes, all 10 | **AGREE, all 10 properties** |

Worked example, case D, transcribed from the screen with ANSI codes stripped and matched against
the probe's NDJSON row for row:

```
  1. 31.7% Various Artists - Series 4, Issue 12        Discogs,     2xVinyl, 1985, US, Hot Tracks,      SA 4-12
  2. 31.2% Various Artists - Specialten Issue 14       Discogs,     DVD,     2006, UK, Specialten,      ISSUE 14
  3. 29.8% Maison book girl - 412                      MusicBrainz, CD,      2017, JP, JAPAN RECORD,    TKCA-74530
  4. 29.6% Conflict - Standard Issue II 88-94          Discogs,     Vinyl,   1995, UK, Mortarhate,      MORT 170
  5. 26.8% Noel Nanton - The Issue                     Discogs,     Vinyl,   2002, UK, Honchos Music,   HONM017
  6. 25.8% Seventh House - 412                         MusicBrainz, None,    None, None, None,          None
  7. 25.4% Abbie Gale - 4:12                           MusicBrainz, CD,      2007, GR, Inner Ear,       INN01
  8. 24.0% Chris Cutler & Fred Frith - The Stone…      Discogs,     CD,      2007, US, Tzadik,          TZ 0003
  9. 22.4% Mastermix - Grandmaster 70s                 MusicBrainz, CD,      2004, GB, Music Factory,   70M1
 10. 16.2% Mastermix - Grandmaster 2002                MusicBrainz, 2xCD,    2002, None, Music Factory, CD405
```

The probe's `distance` reproduces every one of those ten percentages as `(1 - distance) × 100`, in
the same order, with the same source split.

### **The agreement verdict**

> **The two instruments AGREE on the Discogs candidate set — the set T1 is computed from — on
> 5 of 5 cases: same candidate count, same releases, same ordering, same scores, same track
> counts. This verdict is claimed ONLY across the four cases actually covered (DMC,
> missing-album V3, zero-candidate, strict hit) plus case E, and no more broadly.**

### The disagreement, stated rather than smoothed over

**Cases A and B disagree on the MusicBrainz half of the candidate list.** In case A the probe
returned MB releases `485` and `295` where the cross-check returned `240` and `303`; in case B the
two MB sets are disjoint. The disagreement is **explained, and the explanation is measurable**:

1. It is confined to MusicBrainz. **Zero** Discogs candidates differ in any of the five cases.
2. The headline cell logged **44 HTTP 503 responses, all of them `musicbrainz.org`** — MusicBrainz
   throttles with 503 — so the probe's MB candidate set was collected under throttling that the
   later cross-check did not experience.
3. Both disagreeing folders issue a **degenerate query**: case B's `album` is empty, so the query
   is `"&Me, Rampa, Adam Port, Alan Dixon, Keinemusik Feat. Arabic Piano - "`. A low-relevance
   query returns low-relevance results that are not stable between runs.

The specific failure mode 03-RESEARCH.md said was worth testing for — *the probe reporting zero
candidates for a folder where `beet import -t` shows some, meaning plugin loading differs between
the two paths* — **does not occur.** Plugin loading is identical, and it is the Discogs half, which
is measured under a 60/min budget that was never exhausted, that is stable.

### The case that could not be covered, and why it is not covered

The plan requires an **index-track-sensitive** folder — "a Mastermix/DMC release whose candidate
track count changes between `discogs.index_tracks: no` and `yes`. Pick it from the probe's own
output, where the two scorings disagree."

> **No such folder exists in this sample. The two scorings disagree nowhere: 70 of 70 Discogs
> candidate pairs are identical on `n_tracks`, `extra_items` and `extra_tracks`.**

Rather than substitute an arbitrary folder and claim a coverage the evidence does not support,
this case is recorded as **NOT COVERED, because the phenomenon is absent**. That absence is itself
the finding — `index_tracks` is inert on this content — and it is reported in
§ *`index_tracks` — measured, and it is a no-op on this sample* with the count that establishes it.

---

## Timing

Both instruments, all six cells. **Instrument A** is a shell clock around the `docker exec`;
**instrument B** is the probe's own internal wall clock, cross-read against the span of the
per-folder UTC timestamps embedded in the NDJSON.

| Cell | A (shell) | B (probe) | Delta | Agreement | NDJSON first→last span |
|---|---|---|---|---|---|
| `raw-mb` | 207.0s | 206.3s | 0.7s | 0.3% | 194s |
| `normalised-mb` | 157.0s | 156.3s | 0.7s | 0.4% | 149s |
| `raw-mbdiscogs` | 267.0s | 266.1s | 0.9s | 0.3% | 260s |
| **`normalised-mbdiscogs`** | **221.0s** | **220.1s** | **0.9s** | **0.4%** | 205s |
| `raw-mbdiscogs-it` | 154.0s | 153.5s | 0.5s | 0.3% | 148s |
| `normalised-mbdiscogs-it` | 156.0s | 155.7s | 0.3s | 0.2% | 149s |

**Stated tolerance: 2%. Every cell agrees to within 0.4%**, and the residual is accounted for —
`docker exec` startup, interpreter start, plugin load and the identity probe all sit inside A and
outside B. The NDJSON span is shorter than both because it is measured between the first and last
*record*, not from process start.

Headline cell: **220.1s for 24 folders = 9.2s per folder.**

---

## Requests

| Quantity | Headline cell (`normalised` × `musicbrainz discogs`) |
|---|---|
| **Instrument A** — probe's in-process counter, scoped to `api.discogs.com` | **75** HTTP responses (75 new connections) |
| **Instrument B** — `grep -cE 'api\.discogs\.com.*HTTP/1\.1"'` on stderr | **75** |
| Naive `grep -c 'api\.discogs\.com'` | 150 — **over-counts exactly 2×** |
| Identity probe | **1 per run**, not per folder, and invisible to both counters |
| **M — measured Discogs requests per folder** | **75 / 24 = 3.125** |
| `discogs.search_limit` in force | **5** |
| `x-discogs-ratelimit` observed | **60** — A6 re-confirmed a third time |
| MusicBrainz requests on the same `urllib3` stream | 186 lines / 138 × 200 + 44 × 503 |

**Instruments A and B agree exactly at 75.** The plan names instrument B as
`grep -c 'api\.discogs\.com'`, which returns **150** — because `urllib3` emits a
`Starting new HTTPS connection` line *and* a response line per request. Counting only lines
carrying the HTTP status reproduces the in-process counter exactly. **The bare form over-counts
requests by a factor of two and must not be carried forward.**

**M was measured, not assumed.** 03-RESEARCH.md predicted 6–11 per folder and 03-06 measured 7 on a
mainstream album; the sample average is **3.125**, roughly half the low end of the prediction. The
reason is visible in the per-stratum table below: V2 and V6 folders average **1.0** request each,
because a search that returns nothing costs one request and no release fetches follow.

---

## Extrapolation to the backlog

**Per stratum and summed — never `M × N`.** Request volume varies by stratum by construction: a V3
folder with an empty `album` issues no Discogs query at all, while a V1 folder with a clean issue
string paginates through `search_limit` releases and their cached masters.

### The denominator: 144, and the amendment behind it

`03-DECISION.md` § *Denominators* commits **143** folders. **03-03's variant survey corrected this
to 144** with two independent instruments — a live audio-extension `find` on LXC 100 and Phase 1's
QUAL-01 capture grouped by scan root — both returning **24** folders for `nzb/music` where
03-DECISION.md commits 23. The corrected split is `unsorted` 120 + `music` 24 = **144 folders /
7,728 audio files**.

**This is a measured fact corrected by a better instrument, before any rate existed, and T1's
threshold value — 40% — is unaffected.** The correction is recorded as a dated amendment in
`03-DECISION.md` rather than written over the original text.

### Per-stratum table — headline cell

| Stratum | Sampled | `M_s` (req/folder) | `T_s` (s/folder) | `backlog_folders_s` | Requests contribution | Seconds contribution |
|---|---|---|---|---|---|---|
| V1 | 6 | 5.500 | 7.98 | 37 | 5.500 × 37 = **203.5** | 7.98 × 37 = **295.2** |
| V2 | 9 | 2.444 | 9.75 | 39 | 2.444 × 39 = **95.3** | 9.75 × 39 = **380.2** |
| V3 | 2 | 1.000 | 6.25 | 11 | 1.000 × 11 = **11.0** | 6.25 × 11 = **68.7** |
| V4 | 0 | n/a | n/a | **0** | **0** — zero weight | **0** — zero weight |
| V5 | 6 | 2.833 | 10.82 | 43 | 2.833 × 43 = **121.8** | 10.82 × 43 = **465.4** |
| V6 | 1 | 1.000 | 7.04 | 14 | 1.000 × 14 = **14.0** | 7.04 × 14 = **98.6** |
| **Sum** | **24** | | | **144** | **445.7** | **1308.1** |

`203.5 + 95.3 + 11.0 + 0 + 121.8 + 14.0 = 445.6` (445.7 before rounding each row)
`295.2 + 380.2 + 68.7 + 0 + 465.4 + 98.6 = 1308.1`

### The projected figures

| Figure | Value |
|---|---|
| **`total_requests` = Σ (`M_s` × `backlog_folders_s`)** | **445.7** |
| **`api_floor_minutes` = 445.7 / 60** | **7.43 minutes** |
| **`wall_clock_minutes` = 1308.1 / 60** | **21.8 minutes** (0.36 hours) |
| Naive unweighted baseline — `144 × M` (3.125) | 450.0 requests |
| Naive unweighted baseline — `144 × T` (9.17s) | 22.0 minutes |

**The weighted and unweighted figures barely differ here** — 445.7 vs 450.0 requests, 21.8 vs 22.0
minutes — and that is worth stating rather than hiding, because the estimator was committed on the
expectation that they might diverge materially. They do not, for a specific reason: the sample's
per-stratum request counts happen to be close to its mean, and the two heaviest strata by weight
(V5 at 0.2986 and V2 at 0.2708) are also well sampled at 6 and 9 folders. **The estimator was
still the right thing to fix in advance** — it just did not, in the event, change the answer. On
criterion 1 it moved the strict rate by only 2.08 points (25.00% → 27.08%) and the loose rate by
2.78 (54.17% → 51.39%), in opposite directions.

**Wall-clock exceeds the API floor by ~3×** (21.8 min against 7.43 min), and it is expected to:
MusicBrainz is separately rate-limited and returned 44 × 503 on this cell alone, `ffprobe` reads
cross ZFS, and there is per-folder Python overhead. **Both figures are recorded because the floor
alone would understate the real cost by a factor of three.**

### The retraction this carries forward

> **Retire "7,451 files across ~1,000 folders".** It appears in `PROJECT.md` and `CLAUDE.md`
> § *Technology Stack*. The **file count was right**; the **folder count was off by roughly 8×**.
> Discogs requests scale with **folders**, not files — so criterion 2's extrapolation shrinks by
> about an order of magnitude against what those documents assumed, and that is precisely why T2
> does not fire.

---

## The 429 count, and the instrument that measures it

**DEF-03-05 is confirmed, and more decisively than 03-06 could show it.**

| Instrument | `raw-mbd` | `norm-mbd` | `raw-mbd-it` | `norm-mbd-it` | `raw-mb` | `norm-mb` |
|---|---|---|---|---|---|---|
| **HTTP status column** (`grep -oE 'HTTP/1\.1" [0-9]{3}'`) | 216 × 200, 13 × 503 | 213 × 200, 44 × 503 | 216 × 200, 26 × 503 | 219 × 200, 28 × 503 | 144 × 200, 14 × 503 | 144 × 200, 28 × 503 |
| **Probe's in-process 429 counter** | **0** | **0** | **0** | **0** | **0** | **0** |
| Naive `grep -c '429'` — **NOT the instrument** | 25 | 25 | 25 | 25 | **25** | **25** |

### **HTTP 429 responses observed, on both correct instruments, on every cell: ZERO.**

**The naive substring form returns 25 on every single cell — including the two MB-only cells, which
issued zero Discogs requests.** It matches the probe's own 24 per-folder progress labels (`0 x429`)
plus its summary label (`discogs 429 responses: 0`). Had `grep -c '429'` been used as
`03-07-PLAN.md` lines 275, 333 and 414 specify, **it would have falsely fired a pre-committed T2
threshold limb on all six cells and triggered a re-run of every one — 150–260 requests each,
against a 60/min ceiling — on the evidence that the probe printed the digits "429" while reporting
that it had seen none.**

The instrument substitution was mandated before this plan ran and is recorded as a dated amendment
in `03-DECISION.md`. **The threshold VALUE is unchanged; only the instrument was corrected.**

### MusicBrainz throttles with 503

Not a 429, and not a Discogs event — but it is the dominant cost in the wall-clock, so it is
recorded rather than dropped:

| Cell | 503 responses | All from |
|---|---|---|
| `normalised-mbdiscogs` (headline) | **44** | `musicbrainz.org` — **zero** from `api.discogs.com` |

MusicBrainz signals rate limiting with **503 Service Unavailable**, not 429. Any later plan that
watches only for 429 will see a clean run while MusicBrainz throttles it. This is the same shape as
DEF-03-05 — an instrument aimed at the wrong signal — and it explains both the 3× gap between the
API floor and the wall-clock, and the two MusicBrainz-side cross-check disagreements above.

---

## T1 and T2 verdicts

Neither threshold **value** was changed after the evidence, and **the estimator was not changed
either**. The pushed threshold-commit SHA, reproduced verbatim, resolves to a commit and is an
ancestor of `origin/main`:

```
137b6d9e92cb44d9c6a48b3963bb33fe0194622f
```

### T1 — **FIRED**

| | |
|---|---|
| **Threshold** | Discogs matching under **40%** of the backlog after normalisation |
| **Tested?** | **Yes** |
| **Returned** | **Backlog-weighted strict rate = 27.08%** at `discogs.index_tracks: no`, `search_limit: 5`, on the normalised arm. Unweighted sample rate **25.00%** (6/24) beside it. Un-normalised arm: weighted **27.08%**, unweighted 25.00%. Weighted loose **51.39%**; unweighted loose 54.17% |
| **Verdict** | **27.08% is BELOW 40% — the threshold FIRES** |
| Robustness | The V6 bound (its one sampled folder at 100%) gives 36.80%, still below 40%. The unweighted figure is also below. The "strict **and correct**" reading is 22.80% weighted, further below |

**T1 firing means the evidence that would overturn the beets recommendation has been produced.**
`PROJECT.md` states it plainly: *"Discogs matches < ~40% of `dj-mixes` folders even after tag
normalisation → beets' only structural advantage evaporates."* This is recorded as measured, not
softened. Axis one must now be decided knowing that Discogs resolves roughly a quarter of the
backlog by folder and an eighth of it by file, that DMC — the content criterion 4 names — returns
**zero** strict matches, and that one in six strict matches is a confidently wrong release.

### T2 — **NOT FIRED**

| | |
|---|---|
| **Threshold** | Rate limiting makes bulk import impractical: **> 4 hours** projected wall-clock for the backlog, **OR any observed HTTP 429** |
| **Tested?** | **Yes** |
| **Returned** | Projected wall-clock for the 144-folder backlog = **21.8 minutes** (1308.1s), per-stratum weighted; naive baseline 22.0 min. Pure-API floor **7.43 min** at the observed ceiling of 60 req/min. **Observed HTTP 429: 0**, on both the status-column instrument and the probe's in-process counter, across all six cells |
| **Verdict** | **Neither limb fires.** 21.8 min ≪ 4 h, and 429s = 0 |
| Caveat recorded | 44 × HTTP **503** from `musicbrainz.org` on the headline cell. MusicBrainz throttling is real and is the main reason wall-clock is 3× the API floor — but it is not a 429 and not the limb T2 names |

**Total Discogs spend across this plan: 291 requests** (72 + 75 + 72 + 72 across the four Discogs
cells, plus 6 identity probes and ~25 for the `beet import -t` cross-check), against a 60/min
budget that was never exhausted — `x-discogs-ratelimit-remaining` never fell below 31.

---

## The one change made to the probe

`REQUIRED_PLUGINS = ("discogs", "musicbrainz")` was a hardcoded constant, so the two **MB-only
cells — which omit `discogs` by design** — were refused at startup with exit 2. The gate was
**parameterised, not weakened**:

- `--require-plugin` is repeatable and **defaults to `REQUIRED_PLUGINS`**, so all four Discogs
  cells ran under the unchanged two-plugin gate.
- An MB-only cell must state its narrower expectation on the command line, and the narrowing is
  **printed in the run banner** (`plugins REQUIRED: musicbrainz  <-- NARROWED from discogs +
  musicbrainz`) rather than silently inferred from the config.
- Verified in both directions before use: the MB-only config under the default gate still exits
  **2** naming `discogs`; under `--require-plugin musicbrainz` it runs.

The probe therefore has two hashes in this phase, and both are recorded rather than conflated:

| Build | sha256 | Used for |
|---|---|---|
| 03-06's gated build | `0dd5520d6e9cfddb11967761efb7ff5817c1c4a4d44b99fedb27cc91f8e962c7` | The A1 gate |
| This plan's build | `33499c0331c2be77950d5ac034525c73180628ed3adc14d97a04f8a1a392328e` | **All six cells here** |

The staged file on LXC 100 and the committed blob hash identically, checked before the run. **The
change cannot affect any Discogs cell**: those pass no `--require-plugin`, so the code path is
byte-for-byte the previous behaviour.

---

## The probe wrote nothing — four instruments over the whole subtree

| Instrument | `raw` | `normalised` |
|---|---|---|
| `find <arm> -newer .cell-stamp -type f` | **0 lines** | **0 lines** |
| Whole-subtree `%p\t%s\t%T@` manifest diff, before vs after | **empty** (364 files) | **empty** (364 files) |
| Whole-subtree `sha256sum` manifest diff, before vs after | **empty** (364 files) | **empty** (364 files) |
| `docker inspect beets-spike` mount mode | **`RW=false`** | **`RW=false`** |

Both manifests cover **364 files per arm** — the 335 audio files plus the 29 non-audio entries a
rules-only check would never look at. The five-file spot check is retired phase-wide (03-05).

The structural argument is the stronger one: **both arms are mounted `:ro`, and
`beets-spike-rw` is absent from `docker ps -a`** (count 0). The probe *could not* write, rather
than merely did not. `tag_album()` constructs no `ImportSession`, and `SPIKE_DB` is byte- and
mtime-identical across every cell (`size 53248`, `mtime 1788469035`).

---

## Screening — performed, and what it found

**Screened before any of the stderr was quoted here.** DEF-03-04: the Discogs token is a
`?token=` **query parameter**, not an `Authorization` header, so `urllib3` DEBUG — criterion 2's own
request-counting instrument — is a credential sink. `03-07-PLAN.md`'s trust-boundary table at line
443 states the opposite; it is wrong, and the screening instruction it carries is right for the
other reason.

| Screen | Scope | Result |
|---|---|---|
| The live 40-char token, **by value**, executed **inside the container** printing only counts | 1,173 files under `/mnt/fast/spike-03` and `/mnt/tank/downloads/spike-03` | **2 files** — both mode `600`, both inside the throwaway config dir |
| Which two | | `beets-config/import-xcheck.yaml` (generated here) and `beets-config/config.yaml` (pre-existing, 03-04) |
| The token in any **cell stderr** | all six | **0** |
| `token=` vs `token=REDACTED` in each Discogs cell stderr | | **75 / 75**, **75 / 75**, **72 / 72**, **72 / 72** — one-to-one, no unredacted occurrence |
| The token in any **shell history** on LXC 100 | `/root/.bash_history` and every `.*history` under `/root` and `/home` | **0** |
| `Authorization` in any artefact quoted or committed | | **0** |
| The token in any **committed** file | the repository | **never** — no 40-char token-shaped string in any tracked file |

**This document contains no `Authorization` header and no token value.** The one file that holds
the token in plaintext is `/mnt/fast/spike-03/beets-config/import-xcheck.yaml`, mode `600`, outside
the repository, generated by
[`scripts/spike03-gen-import-config.sh`](../../../scripts/spike03-gen-import-config.sh) — which
`source`s the `600 root`-gated env file with **no `set -a`**, `export`s the **name** only, sets
`umask 077`, and has a Python child read the value from its **own `os.environ`**. The value is
never an `echo` argument, a `printf` argument, a heredoc typed at a prompt, a `docker exec -e`, or
any other argv. **Plan 03-11 deletes it.**

The operator has decided the token is rotated at **project close**, not now.

---

## Health of the estate around the run

| Assertion | Result |
|---|---|
| `bash scripts/check-music-freeze.sh` | **exit 0** — `tagger-class writers: 0`, `unclassified writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` |
| Failure ledgers across all six cells | **0 lines** each |
| Exit codes across all six cells | **0** each |
| `beets-spike-rw` present | **no** |

**`tagger-class writers: 0` carries the standing DEF-03-01 caveat**: `check-music-freeze.sh`'s
`TAGGER_PATTERN` cannot match `sabnzbd`, which runs beets as a **live** post-processing path over
the same backlog trees this sample was reflinked from. For that one tagger the counter is *silence*,
not a clean reading. The decisive attribution is the **mount table, not the clock**: `beets-spike`
holds no mount under `/mnt/fast/appdata` at any mode, and both sample arms are `:ro`.

---

## Corrections to this plan's acceptance criteria

Recorded as retractions rather than quiet replacements, in the `beets.md:55-58` house style. The
underlying facts hold; three of the *instruments* named in `03-07-PLAN.md` do not.

**1. `grep -c '429'` returning 0 is unsatisfiable and measures the wrong thing** (lines 275, 333,
414). It returns **25 on every cell**, including cells that issued no Discogs request at all. The
substitution was mandated before this plan ran, is logged as **DEF-03-05**, and is recorded as a
dated amendment in `03-DECISION.md`. **The threshold value is unchanged; only the instrument
moved.** The fact the criterion reaches for holds and is proven by the better instruments: **0 HTTP
429**.

**2. `grep -c 'api\.discogs\.com'` over-counts requests exactly 2×** (line 330, and T2's own
`Instrument` column). `urllib3` logs a `Starting new HTTPS connection` line *and* a response line
per request, so the headline cell returns 150 where the true count is 75. Restricting to lines
carrying the HTTP status reproduces the probe's in-process counter exactly. The criterion's intent
— an instrument independent of beets' own bookkeeping — is met by the restricted form.

**3. The commit-ordering assertion is unsatisfiable as written, and the property it reaches for
holds.** Line 418 requires `git log -1 --format=%ct -- 03-DECISION.md` to *predate*
`git log -1 --format=%ct -- 03-DISCOGS-EVIDENCE.md`. But this plan is *required* to write the T1
and T2 verdicts back into `03-DECISION.md`, which necessarily makes that file's **last** commit
later than the evidence. The two instructions cannot both be satisfied.

What criterion 5 actually needs is that the **threshold-introducing** commit predates the evidence,
and it does:

| Commit | `%ct` | Meaning |
|---|---|---|
| `137b6d9e92cb44d9c6a48b3963bb33fe0194622f` | **1788463633** | T1/T2/T3 and the estimator committed |
| `03-DISCOGS-EVIDENCE.md` first commit | **1788506102** | the evidence |
| Difference | **+42,469 s ≈ 11.8 hours** | the thresholds predate the evidence |

The amendment commit that follows is *later* than the evidence **by design** — that is what
"filling in a result cell" looks like — and § *AMENDMENT — 2026-09-04* plus the byte-level
assertion that the threshold columns are unchanged is what makes it auditable.

**4. The denominator is 144, and the section is titled accordingly.** The plan asks for
`## Extrapolation to 143 folders`; 03-03 corrected the backlog to **144** with two instruments
before any rate existed. The section here is § *Extrapolation to the backlog* and every figure in
it uses 144. `03-DECISION.md` retains its original "143" wording with a dated amendment beside it,
rather than being overwritten.

**5. The index-track-sensitive cross-check case does not exist in this sample**, so the
cross-check subset covers four cases across five folders rather than the four the plan enumerates.
Evidence and reasoning in § *The case that could not be covered*.

---

## What this evidence hands to axis one

Stated compactly, because plan 03-11 reads it:

1. **Discogs resolves about a quarter of the backlog by folder and an eighth by file**, strictly —
   27.08% weighted, 13.07% per distinct `audio_md5`.
2. **DMC returns zero strict matches on four folders.** Criterion 4 names DMC explicitly. Discogs
   does not answer it.
3. **The strict rule admits confident wrong matches** — one of six here. The correct-match rate is
   22.80% weighted.
4. **Normalisation buys loose candidates and no strict ones**, and doubles the manual-verification
   gap from 3 folders to 7.
5. **Rate limiting is not the obstacle.** 21.8 minutes for the whole backlog, zero 429s. T2 does
   not fire, and the "~1,000 folders" figure that made it look prohibitive was wrong by 8×.
6. **`index_tracks` is inert on this content** — 0 of 70 candidates change.

T1's firing does **not** by itself decide axis one: wrtag was measured in plan 03-08 to render this
repository's path format on **none** of v0.20.0, v0.33.0 or v0.34.0, and it has no non-MusicBrainz
source at all. **Both engines are now known to be weak on this collection, for different reasons.**
That is the comparison plan 03-11 has to resolve, and it should resolve it knowing that neither
tool's headline claim survived measurement.
