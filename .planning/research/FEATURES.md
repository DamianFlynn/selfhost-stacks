# Feature Research

**Domain:** Self-hosted music tagging pipeline (post-acquisition: tag → organise → publish to two consumers)
**Researched:** 2026-08-17
**Confidence:** HIGH for tool behaviour and consumer requirements (official docs + live MusicBrainz API queries); MEDIUM for community practice patterns

---

## Framing

"Users" here are three parties, and they want different things:

| Party | Wants |
|---|---|
| Damian (operator) | To not have to babysit the pipeline, and to not have to rebuild it a fourth time |
| Jellyfin | Correct embedded tags; folder names that match the `ALBUMARTIST` tag exactly, case included |
| Music Assistant | Correct embedded tags; `ALBUMARTIST` **mandatory**; `/artist/album` folder structure |

The dominant constraint is not technical difficulty. It is that **this project has been abandoned three times**, so every feature below is scored on "does this get abandoned if it stalls?" Features that require an unbounded human attention budget are anti-features here regardless of how good they look.

---

## Key Research Corrections to Existing Project Assumptions

Two claims in `PROJECT.md` / `beets.md` did not survive verification. Both change the feature set.

### 1. "DJ service releases are not in MusicBrainz" — partly wrong

Live MusicBrainz web-service queries (2026-08-17, confidence HIGH — these are API results, not recollection):

| Query | Releases in MB | Notes |
|---|---|---|
| `"Mastermix Issue"` | 18 | Issues 300–366, dated 2011–2016 |
| `"DMC Commercial Collection"` | 19 | Incl. issue 485, dated 2023-06-02 |
| `"Music Factory Mastermix"` | 9 | Issues 3, 4, … |
| `"Essential Hits"` | 55 | Ambiguous — needs disambiguation |
| `"Mastermix Crate"` | 0 | Genuinely absent |
| `"Mastermix Toolkit"` | 0 | Genuinely absent |
| `"Mastermix Issue 430/433/441/444"` | 0 each | The backlog's actual issues are absent |

The MusicBrainz *series* entities exist and are actively curated — `Mastermix: DJ Beats` has 28 entities, and the series annotation carries explicit entry guidance (these must be entered as **Album + Compilation**, *not* `DJ Mix`, because MB reserves "DJ Mix" for continuously blended audio).

**What this changes:** "no autotagger will ever match these" is too strong. The correct feature is a cheap **coverage probe** per release, not a blanket `-A`. Blanket `-A` across 85 folders throws away the handful that would have matched cleanly, and — worse — preserves the known-broken field mapping on those too. Expect the probe to come back mostly negative; run it anyway because it is one command and it is the difference between "we decided" and "we assumed".

### 2. beets has no undo

Verified against the current CLI reference (commands are: `import`, `list`, `remove`, `modify`, `move`, `update`, `write`, `stats`, `fields`, `config`). There is **no `beet undo`**. All reversibility must be manufactured from (a) `import.copy` leaving the source intact and (b) a `library.db` snapshot taken before the run. This makes "non-destructive by default" a table-stakes feature rather than a nicety.

---

## Feature Landscape

### Table Stakes (the pipeline is broken without these)

| # | Feature | Why Expected | Complexity | Notes / Dependencies |
|---|---------|--------------|------------|----------------------|
| T1 | **One owned ingest path, exactly one** | Four entry points is why the state is unknowable. Three are dead but still defined. | LOW (deletion work) | Blocks T2–T12 in the sense that they must be built on the survivor. Requires the tagger decision (spike). |
| T2 | **Persistent library database** | The current `audio.bash` `rm`s its `library.blb` every run. A stateless tagger cannot do duplicate detection, incremental import, or produce an audit trail — every one of those features silently degrades to a no-op. | LOW | Prerequisite for T3, T6, D4, D7. This is the single highest-leverage fix. |
| T3 | **Non-destructive default: `copy`, not `move`** | beets defaults `copy: yes` / `move: no`; the local config overrides to `move: yes`. Combined with no undo, a bad bulk run over 97 GB is unrecoverable. `tank` has 9 T free. | LOW | Requires T2 for a DB snapshot to be meaningful. |
| T4 | **Explicit disposition for every item — no silent `skip`** | `quiet_fallback` defaults to `skip`. The last two SABnzbd jobs (1 Aug, 8 Aug) both logged `skip` and nobody noticed. A pipeline whose failure mode is indistinguishable from success is not a pipeline. | MEDIUM | Requires T5 (log) and T6 (quarantine). |
| T5 | **Import log as a worklist, not a report** | `beet import -l LOGFILE` records every skip / as-is / duplicate, and `--from-logfile LOGFILE` re-imports from it. That turns the log into a resumable queue. | LOW | Native. Enables T4 and T7. |
| T6 | **Quarantine path for rejects** | Rejected content must land somewhere visible and non-empty, not stay in the source pile where it is indistinguishable from unprocessed input. | LOW | Requires T3 (copy semantics) so quarantining is cheap. |
| T7 | **Resumability + incremental** | 7,451 files. Imports get interrupted. `import.incremental: yes` skips already-processed dirs; `resume` defaults to `ask`, `-p`/`-P` force it. | LOW | **Must pair with `incremental_skip_later: yes`** — see dependency notes; the default (`no`) permanently marks hard albums as done. |
| T8 | **Correct `ALBUMARTIST` on every track** | Music Assistant treats this as **mandatory**; missing it falls back to a configurable action defaulting to "Various Artists". Jellyfin groups albums by it. This is the single tag both consumers depend on most. | MEDIUM | Hard part is the DJ backlog where the field mapping is rotated (artist↔album↔title). Depends on D6. |
| T9 | **Folder names that match tags exactly, including case** | Jellyfin issues #12845 and #11190: an artist folder whose name differs from the `ARTIST`/`ALBUMARTIST` tag — *even only in capitalisation* — renders a duplicate artist page. MA derives fallback metadata from folder names. | LOW (config), MEDIUM (verification) | Path-format design. Interacts with T10. |
| T10 | **Compilations under `Various Artists/`, not `Compilations/`** | beets' stock `comp:` format is `Compilations/$album/...`. That is a two-level layout with a folder name that matches no tag — precisely the Jellyfin duplicate-artist trigger, and it violates MA's documented `/artist/album` expectation. | LOW | Config change. Conflicts with beets defaults; must be set explicitly. |
| T11 | **Semicolon as the multi-artist delimiter** | Jellyfin recognises `;` and treats comma-joined strings as one literal artist. MA states `;` is *the only* supported splitter. Both consumers converge on this. | LOW | Tag-writing config. |
| T12 | **Staging area outside `/media/Music`** | Jellyfin's `SaveLocalMetadata: true` writes `.nfo`/`.jpg`/`.lrc` into any folder under `/media/Music` within minutes. Staging untagged content there contaminates it and the contamination is not trivially reversible. | LOW | Already known. Must be encoded in the pipeline, not held in memory. |
| T13 | **Junk gate before import (bucket D)** | `_FAILED_`, `_UNPACK_`, stray `.rar` parts, and misfiled non-music (a Harry Potter BluRay rip currently sits in `dj-mixes`). Importing these produces database entries that then need removing. | LOW | Pure triage. Should precede every other import phase. |
| T14 | **Verification against both consumers, not against disk** | `PROJECT.md` is right that "files landed" is an insufficient success test. Jellyfin and MA are separate scanners with separate failure modes; MA additionally needs the HAOS-side mount, which cannot be done via fstab. | MEDIUM | Depends on the HAOS mount existing. This is the gate on "done". |

### Differentiators (genuinely valuable, optional)

| # | Feature | Value Proposition | Complexity | Notes / Dependencies |
|---|---------|-------------------|------------|----------------------|
| D1 | **Preview-and-review UI (beets-flask)** | The reason this stalls is that interactive import is a terminal session that must be held open. beets-flask generates a *preview* of what beets would do per inbox folder and lets you approve/redirect asynchronously. Sessions are persisted and resumable; interactive terminal import was deliberately removed in favour of this. Directly attacks the abandonment failure mode. | MEDIUM | Requires T2 (persistent DB). Adds a container. Its `bootleg` inbox mode is literally `beet import --group-albums -A` — the DJ path, already built. |
| D2 | **Separate library root for DJ content** | Keeps `Compilations/` clean (a stated project goal) *and* keeps ~85 pseudo-artists out of Jellyfin's artist list. Best implemented as a second library root (`/mnt/tank/media/DJ`) registered as its own Jellyfin library and its own MA filesystem provider — **not** as a `DJ-Mixes/` pseudo-artist folder inside the music root. | LOW–MEDIUM | Depends on T9/T10 conventions. See anti-feature A15 for why the pseudo-artist variant is wrong. |
| D3 | **Cover-scan extraction for tracklists** | 27 of 85 `dj-mixes` folders contain images (54 files), and where present the scans carry full tracklistings — more reliable than any autotagger for this content. | HIGH if OCR-automated, MEDIUM if manual | Only covers 32% of folders. Prefer manual transcription of the highest-value releases over building an OCR pipeline. |
| D4 | **Duplicate reconciliation with tiebreak + quarantine** | beets `duplicates` plugin: `-k/--key` to match on `artist title album` instead of the default `[mb_trackid, mb_albumid]` (which is useless for untagged rips), `tiebreak` config to pick the winner (default: richest metadata; override to `bitrate` for best rip), `-m DEST` to **move** rather than `--delete`. | MEDIUM | Requires T2. All 85 folder names are shared between `dj-mixes` and `unsorted`, sizes differing in *both* directions — no side is automatically authoritative. |
| D5 | **MusicBrainz coverage probe for DJ releases** | One scripted pass over the 85 folder names against the MB web service tells you which are catalogued. Converts an assumption into a fact for ~10 minutes of work. Already partially done above. | LOW | Feeds D6 — a matched release gives you the *correct* field mapping to normalise the rest toward. |
| D6 | **Field-mapping normalisation pass for DJ releases** | The observed rotation (`artist="R'n'b Hits 1990-1999 Pt.1 108"`, `album="VA"`, `title="Mastermix_Issue_444 WEB"`) means `-A` faithfully preserves *wrong* data. Needs a deterministic remap plus BPM extraction from trailing numbers in titles. | MEDIUM–HIGH | **This is the real DJ work.** Depends on T8. `beet modify` for bulk, `edit` plugin for inline fixes. Mp3tag-style filename→tag actions are the community-standard tool for this shape of problem. |
| D7 | **`unimported` as a leak detector** | `beet unimported` lists files present in the library folder but absent from the DB — the exact signature of a partially-failed import or a hand-copied folder. | LOW | Requires T2. Cheap ongoing health check. |
| D8 | **Integrity gate (`badfiles`)** | `badfiles` with `check_on_import: yes` and `import_action_on_error: skip` runs e.g. `flac --test --warnings-as-errors` per file. Catches truncated Usenet rips before they enter the library. | LOW | Slows import. Worth it for the backlog pass; arguably not for routine ingest. |
| D9 | **Backfill passes decoupled from import** | ReplayGain, lyrics, artwork, genre, fingerprints all run *after* import as targeted `beet` queries. The docs explicitly endorse this for ReplayGain ("analysis is not fast"). | LOW | Avoids A5, A10. Requires T2 so the DB knows what still needs backfilling. |
| D10 | **`mbsubmit` contribution loop** | `beet mbsubmit album:"..."` prints an MB-ready tracklisting for an unmatched album. Turns a dead-end release into a one-time contribution that makes it (and every future copy) autotaggable. | LOW per release, unbounded in aggregate | Genuinely nice. Strictly opt-in per release — see A14 for the failure mode. |
| D11 | **`match.preferred.countries`** | The UK and US *Now!* series share album titles with completely different tracklistings, and beets has nothing to break the tie without this. `countries: ['GB', 'US']`. | LOW | Biases, does not guarantee. Bucket B still needs `-t` (timid) and manual release-ID paste (`I` at the prompt). Already identified in `beets.md`. |

### Anti-Features (deliberately NOT building)

Scope discipline is the primary deliverable of this section.

| # | Anti-Feature | Why It Looks Attractive | Why It's Problematic | Do Instead |
|---|---|---|---|---|
| A1 | **Unattended autotag-on-ingest as the primary path** | "New downloads just get tagged." It is what `audio.bash` already attempts. | This is the existing failure, not a future one. `quiet_fallback` defaults to `skip`, so uncertain matches vanish silently; setting it to `asis` is worse, because it writes bad metadata into the library where it is much harder to find than an untagged file in a staging folder. Both SABnzbd jobs on record logged `skip`. | Ingest **routes** to an inbox and *notifies*; a human (or D1's preview) approves. Auto-import only above a high confidence threshold, with everything below it queued, never silently dropped. |
| A2 | **Throwaway per-download library database** | Statelessness feels clean and avoids DB corruption worries. | Destroys duplicate detection, incremental import, `unimported`, and any audit trail — the exact features you need at 7,451 files. A stateless tagger cannot know it has seen a release before. | T2: one persistent DB, snapshotted before bulk runs. |
| A3 | **`import.move: yes` on the backlog** | Saves disk; feels tidy. | beets' own docs call moving "risky" and recommend backups. There is no `beet undo`. One bad path-format over 97 GB is unrecoverable. | `copy`, verify in both consumers, *then* delete the source as an explicit separate step. |
| A4 | **`scrub` with `auto: yes` on DJ content** | Cleans crufty tags left by other tools; the current soulbeet config already enables it. | `scrub.auto` **defaults to `yes`** and removes *all* tag types before writing. The docs warn "any information in the tags that is out of sync with the database will be lost." For DJ pool content that means BPM, mix/version, key and clean/dirty flags — the fields that make the collection useful and that MusicBrainz will never give back. | `scrub: auto: no` at minimum on the DJ path. Scrub only mainstream content where MB is authoritative for everything you care about. |
| A5 | **AcoustID / chroma fingerprinting for DJ content** | "Identify files by the actual audio, no tags needed" is exactly what you want for untagged rips. | Fingerprinting costs significantly more CPU and memory than ordinary tagging (a reported FLAC album went from <2 min to ≥15 min). And it does not work here: DJ pool edits — intro edits, BPM-shifted reworks, redrums — are *distinct recordings* from the commercial versions, so matches point at the wrong release. Worst case is chroma enabled without musicbrainz: all cost, zero candidates. | `chroma.auto: no`. If ever wanted, run `beet fingerprint` as a post-hoc pass (D9). |
| A6 | **Reconciling the two `library.db` files** | Two databases writing one tree is obviously wrong. | Reconciling means re-importing one side — 34 GB of already-correct, Jellyfin-visible content, at real risk of `SaveLocalMetadata` artefacts and path churn. Already Out of Scope in `PROJECT.md`; restating because it will look tempting once the new pipeline works. | Retire the redundant entry point (T1) and leave the existing library alone. Treat the split as a documented hazard. |
| A7 | **beets owning the filesystem for Lidarr-acquired content** | One tool doing everything. | Servarr's guidance is an explicit split: **Lidarr controls the filesystem, beets controls tag content**, and preventing beets from touching the filesystem is called the most important thing to get right. When Lidarr renames a file, beets' DB retains the old path and treats it as missing. | Per-path ownership. On the Lidarr path: `move: no`, `copy: no`, `write: yes`. On the backlog path beets owns the filesystem, because Lidarr never touched it. Run `beet update` after any Lidarr rename. |
| A8 | **Music Assistant reading via the Jellyfin provider** | Avoids the awkward HAOS mount entirely; one scanner, one source of truth. | MA's own Jellyfin provider docs state it has **no dedicated developer**, is maintained best-effort, and explicitly suggest sharing music directly with MA instead. It also still requires a sync, so it does not even remove the second scan. And it makes the music library depend on Jellyfin's API being up. | The filesystem provider, per `PROJECT.md`. The HAOS mount is the cost of doing this correctly. |
| A9 | **Clearing the entire 97 GB as a project deliverable** | It is the visible problem. | Unbounded scope with no completion signal — the shape that killed the previous three attempts. | Already Out of Scope. Ship the pipeline + bucket A proven in both consumers. Buckets B and C become routine work. |
| A10 | **Chasing complete metadata (lyrics, genres, art) for everything** | A "finished" library. | The `lyrics` plugin has **no request throttling** and reliably triggers HTTP 429 from Genius within seconds of a bulk run (beets issue #6728); Discogs rate-limits similarly. `lastgenre` defaults `force: true` and re-queries Last.fm even for items that already have a genre. Chasing completeness turns a 3-hour import into a multi-day one that fails partway. | D9: import fast with expensive plugins off, backfill later on targeted queries. `lastgenre.force: no`. |
| A11 | **Transcoding / normalising audio at import (`convert`, inline ReplayGain)** | One pass, consistent library. | Irreversible, slow, and orthogonal to the actual problem (tags and layout). Neither consumer requires it. | Skip entirely. If ReplayGain is ever wanted, run it as a backfill (D9). |
| A12 | **A custom beets metadata source / plugin for DJ pools** | "Just write a Mastermix source and the whole bucket autotags." | High effort against an undocumented, unstable, login-walled target, for a collection that is not growing meaningfully. Brittle: the source breaks, and the pipeline that depends on it is dead a fourth time. | D5 (probe MB) + D6 (deterministic remap) + D10 (contribute the good ones back to MB). |
| A13 | **Auto-delete duplicates (`beet duplicates --delete`)** | 85 shared folder names is a lot of manual comparison. | Sizes differ in *both* directions across the 85 pairs — neither tree is authoritative. Community reports of DB/disk divergence after move+delete sequences (files remaining on disk with only one DB entry) mean the automated path can leave you worse off *and* less able to tell. | `beet duplicates -F -m /quarantine -k artist -k title -k album`, then inspect, then remove. Move, don't delete. |
| A14 | **Submitting every unmatched release to MusicBrainz** | Fixes the problem permanently and helps others. | ~85 DJ folders × careful catalogue/barcode/tracklist entry is a second project. Worse, MB *deletes* poorly-added releases after downvotes, so sloppy bulk submission is wasted effort — and DJ-pool repacks from download sites are exactly the category that gets voted down. Entry style is also non-obvious (Album + Compilation, never `DJ Mix`). | D10 opt-in, for releases where a cover scan (D3) already provides an authoritative tracklisting. Cap it — e.g. five releases — and treat it as a bonus, not a phase. |
| A15 | **`DJ-Mixes/` as a pseudo-artist folder inside the music root** | It is the one-line config from `beets.md`: `albumtype:dj: DJ-Mixes/$album/$track $title`. | Creates a folder name matching no tag — the documented Jellyfin duplicate-artist trigger (#12845/#11190) — and breaks MA's `/artist/album` expectation, where the folder is used as the albumartist fallback. It also still pollutes the main artist list. | D2: a separate library root, registered as its own Jellyfin library and its own MA filesystem provider, structured `Mastermix/Issue 433 (2023)/...` so folder == `ALBUMARTIST`. |
| A16 | **`from_scratch: yes`** | Guarantees clean, consistent metadata. | Discards existing metadata when a match is applied. On DJ content the existing tags are the *only* metadata, misaligned or not. Silent and irreversible. | Leave at default `no`. Fix mapping explicitly via D6. |
| A17 | **A single import pointed at `VA-Now_That.s_What_I_Call_Music__1-115_2023`** | It is one folder; point beets at it. | 115 albums, 45 GB, in one directory. beets groups by directory, so this is one enormous mismatched "album". | Split per volume first, then bucket B treatment (`-t` + `preferred.countries` + manual release IDs). |
| A18 | **A watch folder that imports with no human gate** | Zero-touch. | This is A1 wearing different clothes, and it is what `soulbeet` and `wrtag` were both meant to be. Both are now dead containers. Zero-touch systems fail silently and nobody finds out for months (`wrtag.db` unchanged since 23 Jan 2026). | Watch folder that *previews and notifies* (D1). Human approval is the feature, not the friction. |

---

## Feature Dependencies

```
T1 (one owned path)
 └──enables──> T2 (persistent DB)
                ├──requires──> T3 (copy not move)        [no undo exists]
                ├──enables───> T7 (incremental + resume)
                ├──enables───> D4 (duplicate reconciliation)
                ├──enables───> D7 (unimported leak detector)
                └──enables───> D9 (decoupled backfill)

T4 (explicit disposition)
 ├──requires──> T5 (import log as worklist)
 └──requires──> T6 (quarantine path)

T8 (correct ALBUMARTIST)
 ├──requires──> D6 (DJ field-mapping normalisation)   [DJ subset only]
 └──enables───> T14 (both-consumer verification)

T9 (folder == tag) ──constrains──> T10 (Various Artists/) ──constrains──> D2 (DJ library root)

T12 (staging outside /media/Music) ──gates──> every import phase
T13 (junk gate) ──precedes──> every import phase

D5 (MB coverage probe) ──informs──> D6 (which mapping is correct)
D3 (cover scans) ──feeds──> D6 and D10
D1 (review UI) ──enhances──> T4, and its `bootleg` mode ──implements──> the DJ as-is path

T7 ──CONFLICTS WITH──> its own default: incremental_skip_later
A5 (chroma) ──CONFLICTS WITH──> D6 (DJ edits are distinct recordings)
A4 (scrub auto) ──CONFLICTS WITH──> DJ BPM/key/version tags
A7 ──CONFLICTS WITH──> beets owning the filesystem on the Lidarr path
```

### Dependency Notes

- **T3 exists only because there is no undo.** Verified against the current beets CLI reference: the command set is `import`, `list`, `remove`, `modify`, `move`, `update`, `write`, `stats`, `fields`, `config`. Reversibility is entirely manufactured from copy-mode plus a DB snapshot. If the chosen tagger *does* have an undo (worth checking during the tagger spike), T3 relaxes from mandatory to prudent.

- **T7 conflicts with its own defaults, and this is the sharpest trap in the whole feature set.** `incremental: yes` records every directory it processes. `incremental_skip_later` defaults to **`no`**, meaning *skipped* directories are also recorded — so a quiet first pass permanently marks every hard album as "done", and it will never be offered again. The backlog workflow requires `incremental_skip_later: yes`. Get this wrong and the 97 GB silently becomes invisible rather than imported. Note the CLI flag naming is genuinely confusing (`--incremental-skip-later` vs `--noincremental-skip-later`); set it in config, not on the command line.

- **T2 is upstream of almost everything.** Deduplication, incremental, leak detection and backfill are all DB-mediated. Fixing `audio.bash`'s throwaway `library.blb` is not one bug fix — it is the unlock for four other features.

- **D6 is the actual DJ deliverable, and D5 comes first.** `-A` preserves tags faithfully, including the rotated mapping. So `-A` alone makes DJ content *worse* than untagged: it is confidently wrong. D5 finds the handful of MB-catalogued releases, which give you a known-correct target mapping to normalise the other 80 toward.

- **T9 → T10 → D2 is one decision, applied three times.** The rule is: *the folder name must equal the `ALBUMARTIST` tag, exactly.* That single rule produces `Various Artists/` over `Compilations/`, kills the `DJ-Mixes/` pseudo-artist, and prevents Jellyfin's case-mismatch duplicate-artist bug. Encode it once.

- **T11 is free convergence.** Jellyfin recognises `;` and mis-parses `,`; MA supports `;` and nothing else. There is no tradeoff to reason about.

---

## MVP Definition

### Launch With (v1) — matches `PROJECT.md` Core Value

- [ ] **T1** One tagger chosen, others retired — the fourth half-built path is the outcome that must not happen
- [ ] **T2** Persistent library DB on the ingest path — the `audio.bash` `library.blb` deletion is the root defect
- [ ] **T3** `copy` not `move` — no undo exists
- [ ] **T4 + T5 + T6** Explicit disposition, logged, quarantined — a silent `skip` is what killed the last attempt
- [ ] **T12** Staging outside `/media/Music` — otherwise Jellyfin contaminates the input
- [ ] **T13** Bucket D triaged — junk in, junk out
- [ ] **T9 + T10 + T11** Path/tag conventions fixed before any volume moves through
- [ ] **T8** `ALBUMARTIST` correct on bucket A (mainstream albums autotag it correctly for free)
- [ ] **T14** Bucket A visible in **both** Jellyfin and Music Assistant

That set is the "provable win" `PROJECT.md` defines as done. Nothing else ships in v1.

### Add After Validation (v1.x)

- [ ] **T7** Incremental + `incremental_skip_later: yes` — trigger: the first bulk run over `unsorted`
- [ ] **D11** `preferred.countries` + timid mode — trigger: starting bucket B (*Now!*)
- [ ] **D1** Preview/review UI — trigger: manual review becomes the bottleneck (it will, around bucket B)
- [ ] **D2** Separate DJ library root — trigger: before the first DJ import, not after
- [ ] **D4** Duplicate reconciliation — trigger: before importing `unsorted`, since all 85 `dj-mixes` names collide with it
- [ ] **D7** `unimported` leak check — trigger: after the first bulk run, as verification
- [ ] **D9** Backfill passes — trigger: once the library is stable and you want art/ReplayGain

### Future Consideration (v2+)

- [ ] **D5 + D6** DJ coverage probe and field-mapping normalisation — genuinely valuable, genuinely a project of its own. Defer until the mainstream pipeline has run unattended for a month.
- [ ] **D3** Cover-scan tracklist extraction — 32% coverage, high effort. Manual transcription of favourites beats an OCR pipeline.
- [ ] **D8** `badfiles` integrity gate — defer; it slows every import for a problem not yet observed.
- [ ] **D10** `mbsubmit` contributions — capped, opt-in, bonus only.

---

## Feature Prioritization Matrix

| Feature | Operator Value | Implementation Cost | Priority |
|---|---|---|---|
| T2 Persistent library DB | HIGH | LOW | **P1** |
| T3 Copy not move | HIGH | LOW | **P1** |
| T4/T5/T6 Explicit disposition + log + quarantine | HIGH | MEDIUM | **P1** |
| T1 Retire the three dead paths | HIGH | LOW | **P1** |
| T9/T10/T11 Path + tag conventions | HIGH | LOW | **P1** |
| T12 Staging outside `/media/Music` | HIGH | LOW | **P1** |
| T13 Bucket D junk gate | MEDIUM | LOW | **P1** |
| T14 Both-consumer verification | HIGH | MEDIUM | **P1** |
| T8 Correct `ALBUMARTIST` (bucket A) | HIGH | LOW | **P1** |
| T7 Incremental + skip_later | HIGH | LOW | **P2** |
| D11 `preferred.countries` + timid | MEDIUM | LOW | **P2** |
| D2 Separate DJ library root | MEDIUM | LOW | **P2** |
| D4 Duplicate reconciliation | MEDIUM | MEDIUM | **P2** |
| D1 Preview/review UI | HIGH | MEDIUM | **P2** |
| D7 `unimported` leak detector | MEDIUM | LOW | **P2** |
| D9 Decoupled backfill | MEDIUM | LOW | **P2** |
| D5 MB coverage probe | MEDIUM | LOW | **P3** |
| D6 DJ field-mapping normalisation | HIGH | HIGH | **P3** |
| D8 `badfiles` integrity gate | LOW | LOW | **P3** |
| D3 Cover-scan extraction | MEDIUM | HIGH | **P3** |
| D10 `mbsubmit` contributions | LOW | MEDIUM | **P3** |

**Note on D6:** it carries HIGH operator value but sits at P3 deliberately. It is the most interesting problem here, which is exactly why it is the most likely to consume the project and cause the fourth abandonment. It must not be attempted before v1 ships.

---

## How Comparable Pipelines Do It

| Concern | beets manual (current) | beets-flask | Lidarr + beets (Servarr pattern) | Picard + Mp3tag (manual) | Recommended here |
|---|---|---|---|---|---|
| Trigger | Human runs `beet import` | Inbox folder watched, preview generated | Lidarr Connect → Custom Script on import | Human drags files in | Inbox + preview + notify (D1) |
| Filesystem ownership | beets | beets | **Lidarr** (`move: no`, `copy: no`, `write: yes`) | Picard | Split by path: Lidarr on its path, beets on the backlog (A7) |
| Uncertain matches | Interactive prompt | Persisted preview, resumable | `duplicate_action: remove`, threshold-gated | Human decides | Queued + logged, never silently skipped (T4) |
| Uncatalogued content | `-A --flat` | `bootleg` mode = `--group-albums -A` | Not addressed | Filename→tag actions, then hand-fix | `bootleg`/`-A` **after** a coverage probe (D5), then remap (D6) |
| Review | Terminal session | Web UI, async | None (fire and forget) | Whole workflow is review | D1 |
| Reversibility | `copy` + DB backup | Undo an import, pick another candidate | Lidarr re-import | Undo in tool | `copy` + DB snapshot; there is no `beet undo` |
| Known failure | Stalls when the human stops (18 Nov 2025) | Extra container, extra config precedence | DB/path desync after Lidarr renames — needs `beet update` | Does not scale past a few hundred albums | — |

The pattern worth stealing is beets-flask's: **the automation produces a decision, the human ratifies it, and the decision is persisted so ratification can happen later.** Every abandoned attempt here was zero-touch automation that failed silently, or interactive tagging that required an unavailable human. The reviewable-queue model is the one that survives interruption.

---

## Sources

**Official documentation (HIGH confidence)**
- beets configuration reference — `quiet_fallback: skip`, `copy: yes`, `move: no`, `duplicate_action: ask`, `incremental_skip_later: no`, `strong_rec_thresh: 0.04`, `from_scratch: no` — https://beets.readthedocs.io/en/stable/reference/config.html
- beets CLI reference — command set (no `undo`), `-l/--from-logfile`, `-i`, `-p/-P`, `--pretend`, `-t` — https://beets.readthedocs.io/en/stable/reference/cli.html
- beets tagger guide — https://beets.readthedocs.io/en/stable/guides/tagger.html
- beets `scrub` plugin — `auto` defaults to `yes`, removes all tag types, "out of sync with the database will be lost" — https://beets.readthedocs.io/en/stable/plugins/scrub.html
- beets `duplicates` plugin — default keys `[mb_trackid, mb_albumid]`, `tiebreak`, `-F/-m/-k` — https://beets.readthedocs.io/en/stable/plugins/duplicates.html
- beets `chroma` plugin — CPU/memory cost, `auto: no` — https://beets.readthedocs.io/en/stable/plugins/chroma.html
- beets `unimported` plugin — https://beets.readthedocs.io/en/stable/plugins/unimported.html
- beets `badfiles`, `edit`, `fromfilename`, `mbsubmit`, `hook`, `replaygain` plugin docs (via Context7 `/websites/beets_readthedocs_io_en_stable`)
- Jellyfin music library docs — one album per folder, metadata over filenames, disc-number tags, artwork/lyrics naming — https://jellyfin.org/docs/general/server/media/music/
- Music Assistant filesystem source — `/artist/album`, **Album Artist mandatory**, semicolon-only splitter, `_`-prefixed folders ignored, artwork filenames — https://www.music-assistant.io/music-providers/filesystem/
- Music Assistant Jellyfin source — no dedicated developer, best-effort, "consider sharing your music directly with MA instead" — https://www.music-assistant.io/music-providers/jellyfin/
- beets-flask docs — inbox modes (`no`/`preview`/`auto`/`bootleg`), persisted resumable sessions — https://beets-flask.readthedocs.io/latest/

**Live API queries (HIGH confidence, run 2026-08-17)**
- MusicBrainz web service `/ws/2/release/?query=...` for Mastermix Issue, DMC Commercial Collection, Music Factory Mastermix, Mastermix Crate/Toolkit, and issues 430/433/441/444
- MusicBrainz series `Mastermix: DJ Beats` (9e0fd4c3-f09e-4bc6-ad8b-362b57faa55e) — 28 entities, annotation on Album+Compilation vs DJ Mix — https://musicbrainz.org/series/9e0fd4c3-f09e-4bc6-ad8b-362b57faa55e

**Issue trackers and community (MEDIUM confidence)**
- Jellyfin #12845 — duplicate artists when folder name differs from artist tag — https://github.com/jellyfin/jellyfin/issues/12845
- Jellyfin #11190 — duplicate artist from capitalisation mismatch alone — https://github.com/jellyfin/jellyfin/issues/11190
- beets #6728 — lyrics plugin has no throttling, triggers 429 on bulk imports — https://github.com/beetbox/beets/issues/6728
- beets #360 — chroma slows import considerably — https://github.com/beetbox/beets/issues/360
- Servarr wiki, Lidarr + beets integration — Lidarr owns the filesystem, beets owns tags — https://wiki.servarr.com/lidarr/beets-integration
- MxMarx/lidarr-beets — reference config (`write: yes`, `copy: no`, `move: no`) — https://github.com/MxMarx/lidarr-beets
- beets discourse — large-library import strategy, `incremental_skip_later` motivation — https://discourse.beets.io/t/importing-large-music-library/704
- MusicBrainz Picard FAQ — what to do when a release is missing — https://picard-docs.musicbrainz.org/en/latest/faq/faq_usage.html

**Project-internal**
- `.planning/PROJECT.md`
- `stacks/selfhosted/arrs/beets.md`

---

## Confidence and Gaps

| Area | Confidence | Basis |
|---|---|---|
| beets behaviour and defaults | HIGH | Official docs fetched directly; negative claim about `undo` verified against the live command list |
| Jellyfin layout requirements | HIGH | Official docs + three corroborating issue reports on folder/tag mismatch |
| Music Assistant requirements | HIGH | Official filesystem-source docs, explicit on mandatory Album Artist and the semicolon splitter |
| MusicBrainz DJ-pool coverage | HIGH | Live API queries, reproducible |
| Community practice / anti-patterns | MEDIUM | Forum and issue-tracker synthesis; directionally consistent across sources but not authoritative |
| DJ field-mapping remap design | LOW | No established pattern found for this specific rotation; will need a spike against real files |

**Open gaps for later phase research:**
1. Whether the chosen tagger has an undo/rollback (relaxes T3 if so) — belongs in the tagger spike.
2. Exact HAOS-side mount mechanism for the NUC to reach `/mnt/tank/media/Music`, and whether MA's remote-share cache mode (`Loose` is recommended for read-heavy music libraries) matters at this size — belongs in the T14 phase.
3. Whether MA and Jellyfin both tolerate a *second* library root cleanly, or whether Jellyfin's multi-root artist-duplication issues (#12764, #12976) resurface with D2. Worth a small test with three albums before committing the DJ tree.
4. Whether the trailing numbers in DJ titles are uniformly BPM or sometimes track/issue numbers — determines whether D6 can be scripted or must be semi-manual.

---
*Feature research for: self-hosted music tagging pipeline*
*Researched: 2026-08-17*
