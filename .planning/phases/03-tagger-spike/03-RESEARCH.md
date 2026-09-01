# Phase 3: Tagger Spike - Research

**Researched:** 2026-09-01
**Domain:** Music metadata tooling (beets 2.13.1 / wrtag 0.34.0 / beets-flask 2.0.0-rc6), Discogs
API measurement protocol, Go template path-format forensics, ZFS scratch mechanics on `tank`
**Confidence:** HIGH on artefacts, versions and source-level claims (all read from tagged upstream
source or the live estate). MEDIUM on request-count arithmetic (derived from source, not yet run).
LOW on Discogs *coverage* — that number is what the spike exists to produce and cannot be
pre-empted here.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Versions under test**

- **D-01:** **wrtag is tested at v0.33.0**, not the pinned `v0.20.0`. Criterion 3 states the 0.x
  version number and the current container's brokenness are explicitly non-evidence.
  **The inverted pin is now confirmed from this repo's own config rather than from research.**
  `stacks/selfhosted/music/wrtag.yaml:71` sets a `WRTAG_PATH_FORMAT` using `.Release.Media`,
  `.Media.Position` and `.Track.Position` — **all three were introduced in v0.30.0 and none exist
  in v0.20.x.** So `renovate.json5:91`, whose description reads *"HOLD at v0.20.x — v0.30.0 changed
  path-format fields"*, is pinning wrtag to the one version range its own path format cannot render.
  Cause and effect are reversed in that rule. Latest release is **v0.33.0 (11 Jul 2026)**; v0.30.0
  (8 Apr 2026) was the breaking release.
- **D-02:** **beets is tested at 2.13.1**, not the installed `2.5.1-ls295`. Symmetry with D-01 —
  both engines measured at what would actually be deployed. 2.13.1 also carries things the spike
  and later phases depend on: album-level YAML in the `edit` plugin, `beet modify` `+=`/`-=`, and
  `importsource` for resumable imports. The researcher must confirm the exact LSIO tag exists before
  planning pins it; never `:latest` and never `:nightly`.
- **D-03:** **Throwaway spike containers. `stacks/selfhosted/music/wrtag.yaml` and
  `stacks/selfhosted/arrs/beets/beets.yaml` are NOT edited by this phase.** Both were deliberately
  frozen in Phase 1 behind `restart: "no"` + `profiles: ["manual"]`, and the beets mount is `:ro`
  until Phase 6. The spike measures; Phase 4 deletes the loser; Phase 6 configures the winner. Do
  not half-deploy a decision that has not been made.

**Discogs access**

- **D-04:** The Discogs personal access token lives at **`/mnt/fast/secrets/discogs.env` on LXC 100,
  mode `0600`, root-owned, outside the repo.** Written via stdin rather than a command argument so
  it never entered the process list on a host running 100+ containers. **Verified live 2026-08-19:**
  `GET /oauth/identity` → HTTP 200, username `damian.flynn`; `x-discogs-ratelimit: 60` confirming
  the authenticated tier that criterion 2 extrapolates against. **Never commit this value.**
  The token passed through a conversation transcript, so **rotate it on Discogs once the project is
  done** — a transcript is a different exposure surface than a `0600` file.
- **D-05:** **A "match" means a Discogs candidate appears AND its track count agrees with the
  folder.** PROJECT.md is explicit — *"never accept a match without a track-count check"* — because
  a confident wrong match is the worst outcome here, and stub entries of 5–10 tracks against 15–20
  track releases are exactly how that happens. **The ~40% overturning threshold applies to this
  strict figure.** Record the looser candidate-appears-at-all number beside it; the gap between the
  two is itself a finding about how much manual verification the winner implies.

**The 20-folder sample and its normalisation**

- **D-06:** The ~20 DJ folders are **stratified across the observed field-mapping variants**, plus a
  few with no usable tags. Not random (with 84 folders and several conventions, a random draw can
  miss a variant entirely and would not reveal that it had), and not the scan-bearing 27 (those may
  skew toward better-preserved rips and bias the rate upward).
- **D-07:** **Normalisation runs on COPIES, never on the originals.** Copy the sample to a scratch
  path under `tank/downloads`, normalise the copies, spike against those. `cp --reflink` works
  *within* `tank/downloads` (it fails `EXDEV` across to `tank/media`), so 20 folders is near-free.
  This keeps the spike cleanly repeatable from a known-good source and means a bad rule costs
  nothing — as opposed to relying on a dataset-wide `zfs rollback` that would revert everything else
  too.
- **D-08:** The normalisation script is **committed under `scripts/` with a dry-run mode**, so
  criterion 1's paired normalised/un-normalised figures can be regenerated and audited. It is
  **explicitly not the full DJCC-01 field-mapping tool**, which is v2 and the lowest-confidence
  research area. Write the minimum that makes the Discogs query valid — principally repairing
  `artist`/`album` where they are swapped — and stop there.

**Ergonomics (TAGR-06)**

- **D-09:** Ergonomics is measured by a **timed hands-on trial, run by the operator personally**,
  not predicted from documentation. The same albums go through the raw beets prompt and through the
  queue front end; record **wall-clock, number of interventions, and where the operator got stuck or
  annoyed**. The roadmap's own overturning threshold is *"an honest self-assessment that the
  interactive prompt will not be sat at"* — which can only be produced by sitting at it.
- **D-10:** The trial set is **5 albums: 2 clean mainstream, 2 hard shapes (one various-artist
  compilation, one flat multi-disc set), and 1 DJ folder Discogs will not match.** Ergonomic pain
  appears on ambiguous matches, not on the happy path — a front end can feel effortless on clean
  matches and become unbearable on the fraction that need a decision. The no-match case measures
  what happens when the tool *cannot* help, which is where a front end either saves the operator or
  loses them.
- **D-11:** **beets-flask is evaluated by name on axis two**, per criterion 7 — not dismissed and
  not assumed. Its known frictions are recorded as part of the evaluation rather than discovered in
  Phase 7: 1.0 removed the interactive terminal import in favour of UI candidate selection, inbox
  entries must be directories and loose files never trigger, and music paths must match inside and
  outside the container.

**Research scope — deliberately reopened (D-12)**

- **D-12:** **The beets-vs-wrtag head-to-head is re-verified claim by claim before the spike runs.**

  **Trigger — a specific, falsified premise.** The research states wrtag has *"No facility"* for
  repairing existing wrong tags, and that this is one of the two dominant reasons to prefer beets.
  **That is false.** wrtag ships a standalone **`metadata`** tool that *reads and writes* tags —
  `metadata [<options>] write ( <tag> <value>... , )...` — across multiple files and multiple tags
  in one invocation, using wrtag's own tag normalisation, designed to pair with the subproc addon.
  That is precisely a field-remap capability, and it is plausibly a direct competitor to the mutagen
  script the technology stack currently recommends for the DJ normalisation.

  **Scope — a claim audit, NOT a fresh direction essay.** Each row of the head-to-head gets: the
  current primary source, a verdict of **holds / falsified / changed**, and a one-line impact on the
  decision. The roadmap's warning stands and is not suspended: Phase 3 produces a number. This is
  bounded re-verification because one premise was demonstrably wrong, not licence to relitigate.

  **Confirmed still true (checked 2026-08-24, README + releases):** wrtag remains
  **MusicBrainz-only — there is no Discogs backend.** This is the argument that does the real work,
  and it survives.

- **D-13:** **`metadata` is measured against a mutagen script on the same sample folders** — one
  normalisation job, two tools. Whichever wins becomes the normalisation tool **regardless of which
  engine wins the main decision**. An engine that can also repair wrong tags is a materially
  different proposition from one that can only fetch fresh ones.

### Claude's Discretion

- Which beets-flask image/tag and how it is mounted for the trial; scratch path naming under
  `tank/downloads`; the exact shape of the claim-audit table.
- Whether the `metadata` binary is exercised via the wrtag container or as a static binary.
- The Renovate pin is **not touched by this phase** — TAGR-03 (Phase 4) owns releasing it, and this
  spike's v0.20.0-vs-v0.33.0 evidence is what justifies the change.

### Deferred Ideas (OUT OF SCOPE)

- **The full DJ field-mapping tool (DJCC-01)** — v2. D-08 deliberately builds only the minimum.
- **Releasing the Renovate wrtag pin** — Phase 4, TAGR-03. This spike produces the evidence.
- **Bucket A coverage measurement** — the spike measures DJ content because that is where the
  engines differ. Mainstream autotagging is assumed to work for both and is not measured here;
  raised and not pursued.
- **DUPE-01 / DUPE-02** — currently v2, but Phase 1 measured 19.4% duplication and found it makes
  the Phase 7 diff's join last-wins. **Flagged as needing a roadmap decision before Phase 7**, not
  resolvable inside this phase.
- **`/mnt/tank/media/TV` on the orphan gid 545** — 114,218 entries, recorded in `beets.md`, outside
  this milestone.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **TAGR-01** | The tagger decision is recorded with numbers — Discogs coverage measured on normalised DJ folders, import timing extrapolated against the API rate ceiling | § *Criterion 1 instrument* gives a mechanical candidate+track-count counter via `beets.autotag.match.tag_album()`; § *Criterion 2 instrument* gives the per-folder request arithmetic derived from `beetsplug/discogs` + `SearchApiMetadataSourcePlugin` source, and the corrected backlog denominator (**143 folders / ~7,726 files**, not "~1,000 folders") |
| **TAGR-02** | The surviving tagger can own the whole tree, including content that will never match MusicBrainz | § *Claim audit* rows 1, 4, 11; § *Criterion 4* — beets-flask's `autotag: "bootleg"` mode (`beet import --group-albums -A`) and beets `-A` are the concrete "owns the unmatched tree" mechanisms; wrtag's answer is `WRTAG_RESEARCH_LINK` (a hyperlink), plus `tags.WriteTags(..., tags.Clear)` which **wipes** unlisted tags |
| **TAGR-06** | Operator ergonomics is a weighted, recorded factor — including a reviewable-queue front end (e.g. beets-flask) rather than a raw terminal prompt | § *Axis two: beets-flask evaluated by name* — version, image, architecture (one shared `library.db`, N policy-carrying inboxes: **CONFIRMED**), five verified frictions incl. one new blocker (`beets==2.12.0` hard pin), and § *Criterion 6/8 instrument* — the scoring sheet for the timed trial |
</phase_requirements>

---

## Project Constraints (from CLAUDE.md)

Directives the planner must not contradict:

| Directive | Source | Bearing on Phase 3 |
|---|---|---|
| GSD workflow enforcement — no direct repo edits outside a GSD command | § GSD Workflow Enforcement | Plan tasks, not ad-hoc edits |
| Terraform is authoritative for host/LXC/VM resources; keep provisioning in `infra/` | § Infrastructure Rules | Spike containers are **compose**, never Terraform. Also: `terraform apply` in `infra/` is armed to destroy LXC 100 (project MEMORY) — do not go near it |
| Selfhosted compose stacks live under `stacks/selfhosted/<stack>/`; stack ops run from `/mnt/fast/stacks` | § Stack Rules | Throwaway spike compose files belong under a clearly-marked scratch path, **not** merged into `arrs/compose.yaml` or `music/` (D-03) |
| Appdata `/mnt/fast/appdata`; service account `apps:apps` = `568:568` | § Storage and Permissions | beets-flask `USER_ID`/`GROUP_ID` = `568` |
| `import.move: yes` is currently set — first passes must switch to `copy` | § Constraints | The spike must never run a non-`--pretend`, non-dry import against a path it does not own |
| `rsync -a` fails on `tank` (`aclmode=restricted`); use `rsync -rlt --no-p --no-o --no-g` | § Constraints | Moot — **`rsync` is not installed on LXC 100 at all** (verified 2026-09-01). Use `cp --reflink=always` |
| Never stage untagged content under `/media/Music` | § Constraints | Scratch lives under `tank/downloads` only |
| `cp --reflink` fails `EXDEV` across `tank/downloads` → `tank/media`; works within | § Constraints | **Re-verified**: `feature@block_cloning` is `active` on `tank`, `tank/downloads` is one dataset |
| beets has no `undo`; back up `library.db` **and** take a `zfs snapshot` in the same step | § Constraints | The spike uses throwaway `.blb` files, so this reduces to "never point a spike at a real database" |
| Never accept a match without a track-count check | § Constraints | Is D-05; the instrument in § *Criterion 1* implements it mechanically |
| Credentials by variable name only — this repo is public | project MEMORY, § gateway-password-exposed | `/mnt/fast/secrets/discogs.env` referenced by path and variable name only, everywhere |
| Never `lscr.io/linuxserver/beets:latest` or `:nightly` | § What NOT to Use | Pin `2.13.1-ls349` (verified below) |

---

## Summary

Everything the phase needs to *execute* is verified and available, but five load-bearing premises
in the upstream planning documents are wrong, and three of them change what the plan must do.

**The pin inversion is real but the stated reason is wrong, and the correct reason is stronger.**
Read from `pathformat/pathformat.go` at both tags: of the three fields D-01 and `renovate.json5`
name, `.Release.Media` and `.Track.Position` **both exist in v0.20.0** — only `.Media` is absent.
The actual defect is more damning and more demonstrable: v0.20.0 contains the literal lines
`// make sure these are not used` / `d.Track.Position = -1`, so *every single-disc release* renders
`-1 - Artist - Title.ext`, while `{{ .Media.Position }}` — guarded behind `{{ if gt (len
.Release.Media) 1 }}` and therefore lazily evaluated — hard-errors only on multi-disc releases.
v0.20.0's startup validation constructs a one-medium synthetic release, so it passes both. This is
now a demonstrable claim, exactly as `<specifics>` asked.

**wrtag's `metadata` tool exists, ships in the container, handles MP3/FLAC/WAV — and cannot do the
job D-13 imagines.** `cmdWrite` applies one *literal* key→value map to every path in the
invocation, has **no dry-run and no diff**, and there is no field-to-field move primitive. A
per-folder `artist`↔`album` remap is therefore a shell loop of one `metadata read` plus one
`metadata write` per file, writing blind. Against a Python+mutagen script with a `--dry-run` that
emits a reviewable diff, on a project whose stated rule is *"verify with a second independent
instrument before you write it down"*, the bake-off has a strongly-indicated outcome — but D-13
asks for it to be measured, and it is cheap to measure, so measure it.

**The DJ folders do not have swapped `artist`/`album`.** Surveyed all 764 files in Phase 1's own
ffprobe fence: `album` is a correct-ish Mastermix issue string in 657 of 764 files; `artist` is a
placeholder (`Mastermix` 197, `VA` 160, `Various Artists` 138, missing 77, `Various` 20). D-08's
"principally repairing `artist`/`album` where they are swapped" describes a defect that is not
present. The defect that *is* present is precisely characterisable, and it is worse and more
tractable: **107 files have no `album` at all** and the beets Discogs plugin documents that *"if
those are empty no query will be issued"*; and `VA_ARTISTS = ("", "various artists", "various",
"va", "unknown")` means the 160 `VA` and 138 `Various Artists` files flip `va_likely` to true,
which makes the Discogs query `"VA Mastermix Issue 444"` instead of `"Mastermix Issue 444"`, while
the 197 `Mastermix` files get the clean album-only query. That is a **precise, falsifiable
normalisation hypothesis** and the strongest possible foundation for criterion 1's paired
normalised/un-normalised comparison.

**Two hard blockers that will stop the plan on task one if not sequenced first.** LXC 100's root
filesystem — which holds `/var/lib/docker` — is at **99% (2.2 GB free of 126 GB)**, against
~2.0–2.3 GB of new images the spike must pull. And **beets-flask v2.0.0-rc6 hard-pins
`beets==2.12.0`** (`==`, not `>=`), so axis two structurally cannot be measured at D-02's 2.13.1.

**Primary recommendation:** Sequence the phase as *Wave 0: unblock and correct* (docker disk
headroom; measure the real sample population; smoke-test the candidate probe against a
known-good album) → *Wave 1: the two engine measurements* (criterion 1/2 via a mechanical
`tag_album()` probe on reflinked scratch copies, criterion 3 via `wrtag move -dry-run` at v0.20.0
**and** v0.34.0 side by side) → *Wave 2: the front-end trial* (beets-flask rc6, throwaway,
read-only music mount) → *Wave 3: the decision record*. Every number gets a second independent
instrument, per the six-false-passes rule.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Discogs / MusicBrainz candidate lookup | **beets engine** (Python, in-container) | — | Only beets has a Discogs backend; the lookup is a library call, not a UI concern |
| Candidate + track-count counting (criteria 1, 5) | **Python probe script** using `beets.autotag.match` | beets debug log as cross-check | Must be mechanical and re-runnable; an interactive prompt cannot produce a number |
| HTTP request counting (criterion 2) | **`urllib3` DEBUG log** inside the probe process | `discogs_client.LoggingDelegator` | Independent of beets' own accounting — this is the second instrument |
| Path-format rendering (criterion 3) | **wrtag CLI** (`move -dry-run`), in-container | Go source diff at the two tags | Runtime evidence + static evidence; neither alone is sufficient |
| Tag field remap (D-13) | **Python + mutagen script** on host, `--dry-run` first | wrtag `metadata` binary | Reviewability is the deciding property and only one candidate has it |
| Field-loss scoring after normalisation | **`scripts/diff-music-tags.sh`** (Phase 1, `audio_md5`-keyed) | `ffprobe` spot check | Already built, already proven on a negative control |
| Reviewable import queue (axis two) | **beets-flask** container (web UI + Redis + tmux terminal) | raw `beet import -t` terminal | The comparison *is* the measurement |
| Scratch dataset provisioning | **`cp --reflink=always`** within `tank/downloads`, from LXC 100 | — | `zfs` unavailable in LXC 100; reflink needs no ZFS CLI |
| Snapshot / rollback of scratch | **atlantis** (`ssh root@172.16.1.158`) | — | `zfs` is privileged-only; not resolvable inside LXC 100 |
| Ownership of scratch files | **atlantis** if `chown` needed | — | `chown` returns EPERM from LXC 100 (sparse idmap) |
| Secret delivery to containers | **`env_file: /mnt/fast/secrets/discogs.env`** | — | Never `-e`, never a command line — the host runs 103 containers with a readable process table |

---

## Headline findings that change the plan

### 1. The v0.20.0 breakage is real, but two of the three named fields are innocent

Read from tagged source, not from release notes.

`pathformat/pathformat.go` at **v0.20.0**, `type Data struct`:

```go
type Data struct {
	Release               musicbrainz.Release
	Ext                   string
	Track                 musicbrainz.Track
	Tracks                []musicbrainz.Track
	TrackNum              int
	IsCompilation         bool
	ReleaseDisambiguation string
}
```

…and, twelve lines above `pf.tt.Execute`:

```go
	// make sure these are not used
	d.Track.Number = ""
	d.Track.Position = -1
```

At **v0.34.0**:

```go
type Data struct {
	Release musicbrainz.Release
	Media   musicbrainz.Media
	Track   musicbrainz.Track
	Ext     string
}
```

`musicbrainz.Release` carries `Media []Media` and `musicbrainz.Track` carries `Position int` at
**both** tags — those structs are byte-identical between v0.20.0 and v0.34.0 apart from an added
`Aliases` field on `Release`.

Applying that to `wrtag.yaml:71`:

| Field in this repo's `WRTAG_PATH_FORMAT` | v0.20.0 | v0.34.0 | Effect under the pinned version |
|---|---|---|---|
| `.Release.Date.Year` | present | present | fine — **`renovate.json5:91` names this as reworked; it was not** |
| `.Release.Media` (inside `len`) | **present** | present | fine — **D-01 and `renovate.json5` both wrongly call this v0.30.0-new** |
| `.Track.Position` | present, **forced to `-1`** | real per-disc position | **every single-disc file renders `-1 - Artist - Title.ext`** |
| `.Media.Position` | **absent from `Data`** | present | Go template execute error — **but only when `len .Release.Media > 1`**, because `{{ if }}` bodies are lazily evaluated |
| `.IsCompilation` | field on `Data` | supplied by `withLegacyFields()` | fine at both |
| `artistsString`, `safepath`, `pad0` | present | present | fine at both |

And the reason nothing caught it: v0.20.0's `Validate` builds `var media musicbrainz.Media`
(singular) and appends one medium. v0.30.0's release notes list *"**pathformat:** add validations
for multi disc releases"* as a feature. **v0.20.0's startup validation constructs only single-disc
releases, so it exercises neither failure.**

> **Impact:** D-01's conclusion is correct and its evidence should be replaced with the above.
> The plan should render the proof as a task artefact (a diff of the two `Data` structs plus the
> `= -1` line), because Phase 4's TAGR-03 will cite it when it rewrites the Renovate rule.

### 2. wrtag v0.34.0 exists (26 Aug 2026) and D-01 names v0.33.0 as latest

| Tag | Published | Notes |
|---|---|---|
| `sentriz/wrtag:v0.34.0` | 2026-08-26 | Current. Breaking only in `deps: bump to go1.27`. Adds `cover-source`, `cover-max-size`, MusicBrainz 503 retry, umask-for-directories |
| `sentriz/wrtag:v0.33.0` | 2026-07-11 | D-01's stated target |
| `sentriz/wrtag:v0.30.0` | 2026-04-08 | The breaking path-format release |
| `sentriz/wrtag:v0.20.0` | 2026-01-17 | Currently pinned; present on LXC 100 (172 MB) |

Nothing between v0.33.0 and v0.34.0 touches path-format template data. D-01's *intent* is "measure
what would actually be deployed"; that is now v0.34.0.

> **Impact:** This is a D-01 amendment, not a re-opening. **Recommendation: test at v0.34.0 and
> record v0.33.0-vs-v0.34.0 as a no-op for the path format, with the changelog cited.** Flag to the
> operator at plan-approval; do not silently substitute. Either choice is defensible and neither
> changes the outcome.

### 3. beets-flask hard-pins `beets==2.12.0` — axis one and axis two cannot share a version

`backend/pyproject.toml` at `v2.0.0-rc6`:

```toml
dependencies = [
    ...
    "beets==2.12.0",
```

That is an exact pin, not a floor. So:

| Thing 2.13.x adds | In beets-flask rc6? | Matters to Phase 3? |
|---|---|---|
| `beet modify` `+=` / `-=` (2.13.0) | ✗ | No — Phase 6/7 concern |
| `edit` plugin album-level YAML header (2.13.0) | ✗ | Marginal — affects the ergonomics trial's *terminal* arm only, which runs 2.13.1 anyway |
| `importsource` plugin | **✓** (landed 2.6.0, Feb 2026) | Yes, and it is present in both |
| `plugins: [musicbrainz]` default | ✓ both | Yes — TAGR-05's defect exists at both versions |
| Automatic DB backup before migrations (2.13.0) | ✗ | No — spike DBs are throwaway |

> **Impact:** the plan must state this explicitly rather than let a checker discover a version
> mismatch. **Recommendation:** axis one (engine) is measured at 2.13.1 in the LSIO container;
> axis two (front end) is measured at whatever beets-flask ships, and the decision record says so.
> This does not contaminate the comparison — axis two is scored on *interaction*, not on match
> quality, and `importsource` (the one 2.x feature the later phases depend on) is present in both.
> Nothing in 2.13.0's changelog affects Discogs candidate generation.

### 4. The DJ folders do not have swapped `artist`/`album` — the real defect is sharper

Surveyed all **764** files in `/mnt/fast/safety/music-pre-project/dj-mixes-ffprobe` (Phase 1's own
SAFE-03 capture — read-only, no new I/O against `tank`):

```
files: 764   folders: 60

artist value histogram          album/artist/title absence
  197  'Mastermix'                album missing/empty:  107
  160  'VA'                       artist missing/empty:  77
  138  'Various Artists'          title  missing:         57
   77  <MISSING>
   20  'Various'
   ~50 real per-track artists (Sabrina Carpenter, Coldplay, …)

album distinct values (sample)   tag key presence (top)
  'Issue 407'                      title 707   album_artist 222
  'Issue 422 - Disc 1'             artist 687  disc 160
  'Mastermix - Issue 413 '         album 657   tkey 148
  'Mastermix - Issue 458 WEB'      date 564    energylevel 45
  'Mastermix - Issue Vol.451 '     track 555
  'Mastermix Crate 068 : …'        genre 408
```

`album` carries a recognisable issue string almost everywhere. `artist` is the placeholder field.
**There is no observed swap.** The observed variants are:

| # | Variant | Files (approx) | What normalisation must do |
|---|---|---|---|
| V1 | `artist="Mastermix"`, `album="Mastermix Issue NNN"` | ~197 | Nothing for the query — this is already the *good* case (`va_likely=false` → query = album alone) |
| V2 | `artist="VA"` / `"Various Artists"` / `"Various"`, album present | ~318 | Query becomes `"VA <album>"`. Test whether normalising the artist (or the album) improves the rate |
| V3 | `album` absent | **107** | **No Discogs query is issued at all.** Derive album from folder name |
| V4 | `artist` absent | 77 | `va_likely=true` via `not consensus["artist"]` |
| V5 | `album` present but noisy (`- Disc 1`, ` WEB`, `Vol.`, `Mastermix - ` prefix, trailing space) | many | Canonicalise to `Mastermix Issue NNN` |
| V6 | Real per-track artists (newer issues) | ~50 | `va_likely=false`, query = album alone. Different shape again |

The mechanism, from primary source — `beets/autotag/distance.py` v2.13.1:

```python
VA_ARTISTS = ("", "various artists", "various", "va", "unknown")
```

`beets/autotag/match.py` `tag_album()`:

```python
va_likely = (
    (not consensus["artist"])
    or (search_artist.lower() in VA_ARTISTS)
    or any(item.comp for item in items)
)
```

`beetsplug/discogs/__init__.py` `get_search_query_with_filters()`:

```python
query = f"{artist} {name}" if va_likely else name
```

and `docs/plugins/discogs.rst`:

> *"The search terms sent to the Discogs API are based on the artist and album tags of your tracks.
> **If those are empty no query will be issued.**"*

> **Impact on D-08:** the script's job is **not** an `artist`↔`album` swap. It is (a) fill missing
> `album` from folder name, (b) canonicalise `album` to `Mastermix Issue NNN`, (c) set a consistent
> `artist`. That is still "the minimum that makes the Discogs query valid" and still stops well
> short of DJCC-01 — D-08's *constraint* holds, only its *example* was wrong. **This should be
> surfaced to the operator, not silently reinterpreted.**

### 5. The sample population is 60 folders, not 84 — and `dj-mixes` contains no DMC at all

Measured on LXC 100, 2026-09-01:

| Fact | Value | Method |
|---|---|---|
| Entries in `dj-mixes` | 85 (incl. `.DS_Store`) | `ls -1` |
| Entries containing **zero** files | **24** | `find -type f \| wc -l` per folder |
| Audio-bearing folders | **60** — exactly the set Phase 1's fence covers | set-difference against `dj-mixes-ffprobe/` |
| Audio files | 764 (630 mp3 + **134 wav**) | extension histogram |
| Size | 25 GB | `du -sh` |
| Subdirectories | 4, all named `.covers` | `find -mindepth 2 -maxdepth 2 -type d` |

The 24 empty shells include `VA-Now_That.s_What_I_Call_Music__1-115_2023` — **the "45 GB `1-115`
set" that PROJECT.md and CLAUDE.md instruct the plan to split per volume does not exist on disk.**

Worse for D-06's framing: **`dj-mixes` is a byte-for-byte duplicate copy of a subset of
`unsorted`** — separate inodes (242325 vs 206407), link count 1, identical sizes — and all 85 of
its entries appear in `unsorted` by name. This is a direct, concrete instance of Phase 1's 828
duplicate groups / 19.4% finding.

And `unsorted`'s 37 non-overlapping entries are where the **DMC** content lives:
`VA-DMC-Commercial.Collection.498/499`, `VA-DMC.Commercial.Collection.305/306/310/312/327/332`,
`VA-DMC-Essential.Hits.233/234/235`, `VA-Mastermix.Essential.Hits.Pop.4.2005-2009-2025`,
`VA-Mastermix.90.s.12.inch.USB.Top.Up-2024`.

> **Impact:** criterion 4 requires the decision to state what happens to **Mastermix / DMC / Music
> Factory** content, and D-06 stratifies over `dj-mixes` — **which is Mastermix-only.** A 20-folder
> sample drawn purely from `dj-mixes` cannot speak to DMC. **Recommendation: keep D-06's
> stratification method and pool exactly as decided, and add 3–4 DMC folders drawn from `unsorted`
> as a clearly-labelled *separate* stratum**, reported as its own rate beside the `dj-mixes`
> rate — not merged into the ~40% threshold figure, which stays bound to D-06's population.
> Surface as a scope question at plan approval; do not fold it in unilaterally.

### 6. The backlog is 143 folders, not "~1,000" — criterion 2's extrapolation shrinks by an order of magnitude

| Bucket | Audio-bearing dirs | Audio files | Notes |
|---|---|---|---|
| `nzb/music` | 23 | 275 | bucket A/B, FLAC-heavy |
| `nzb/dj-mixes` | 60 | 764 | **duplicate of `unsorted` content** |
| `nzb/unsorted` | **120** | **7,451** | wrtag's only source mount; PROJECT.md's 7,451 figure matches exactly |
| **Deduplicated** | **≈143** | **≈7,726** | `unsorted` ∪ `music`; `dj-mixes` adds nothing new |

PROJECT.md says *"7,451 files across ~1,000 folders is hours of wall-clock"*. The file count is
right; the folder count is off by ~8×, and Discogs requests scale with **folders**, not files.

> **Impact:** the criterion 2 arithmetic in § *Criterion 2 instrument* uses 143 as the denominator.
> This makes it materially more likely that the rate-limit overturning threshold does **not** fire —
> which is exactly the kind of pre-committed-threshold outcome the phase exists to establish
> honestly. **The plan must commit the 143 denominator in writing before the timing run.**

### 7. `beet import --pretend` cannot produce a candidate — it never calls the lookup stage

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

`--pretend` replaces the *entire* pipeline with a file lister. It issues **zero** API calls and
reports **zero** candidates.

> **Impact on this phase:** `--pretend` is unusable for criteria 1 and 2. Use the `tag_album()`
> probe instead.
> **Impact on Phase 4 (handoff, out of scope here but must be recorded):** ROADMAP Phase 4 success
> criterion 4 states *"a `--pretend` run on one known-good album returns a MusicBrainz candidate
> instead of skipping"*. **That criterion is unsatisfiable as written** and needs rewording to
> `beet import -t` or a `tag_album()` probe. Flag it in the decision record so Phase 4 does not
> spend a plan discovering it.

---

## Standard Stack

### Core — all verified against upstream registries on 2026-09-01

| Artefact | Pin | Purpose | Verification |
|---|---|---|---|
| `lscr.io/linuxserver/beets` | **`2.13.1-ls349`** | Axis-one engine, and criteria 1/2 probe host | Docker Hub tag list: `2.13.1-ls349` published **2026-08-29**. `2.13.1` (unsuffixed) also exists but **floats across ls-revisions** — it moved ls344→ls349 between 29 Jul and 29 Aug. Pin the `-lsNNN` form [VERIFIED: hub.docker.com/v2/repositories/linuxserver/beets/tags] |
| `sentriz/wrtag` | **`v0.34.0`** (see finding 2; `v0.33.0` if D-01 is held literally) | Criterion 3 disqualifier, "after" arm | Docker Hub: v0.34.0 2026-08-26, v0.33.0 2026-07-11 [VERIFIED] |
| `sentriz/wrtag` | **`v0.20.0`** | Criterion 3 disqualifier, "before" arm | **Already present on LXC 100** (172 MB, no pull needed) [VERIFIED: `docker images` on 172.16.1.159] |
| `metasauce/beets-flask` | **`v2.0.0-rc6`** | Axis-two front end | Docker Hub `metasauce/beets-flask:v2.0.0-rc6` published **2026-08-30**; also on `ghcr.io/metasauce/beets-flask`. **The repo moved from `pSpitzner/` to `metasauce/` in Aug 2026** — the old Docker Hub repo stops at rc5 (16 Jun 2026) [VERIFIED: hub.docker.com + ghcr.io tag list + release notes] |
| beets | 2.13.1 | — | PyPI latest, uploaded 2026-07-29; `requires_python <3.15,>=3.10` [VERIFIED: pypi.org/pypi/beets/json] |
| mutagen | 1.48.1 | D-13 normalisation script | PyPI latest [VERIFIED] |
| `python3-discogs-client` | 2.9 | Discogs transport | **Already baked into the LSIO beets image** — see below [VERIFIED: linuxserver/docker-beets Dockerfile at tag `2.13.1-ls349`] |

### The Discogs plugin needs no install in the LSIO image

`linuxserver/docker-beets` `Dockerfile` at tag `2.13.1-ls349`:

```dockerfile
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.23/ \
    beautifulsoup4 \
    beets-extrafiles \
    beetcamp \
    python3-discogs-client \
    flask \
    ...
```

So enabling Discogs in the LSIO container is **config only**:

```yaml
plugins: musicbrainz discogs importsource   # musicbrainz MUST be listed — see TAGR-05
discogs:
    user_token: ...   # from /mnt/fast/secrets/discogs.env, never inline
```

No `pip install "beets[discogs]"` step, no build dependencies, no LSIO mod. `beetcamp` and
`pyacoustid` are also pre-installed.

**In beets-flask** the mechanism is different and documented: place `beets[discogs]` in a
`requirements.txt` inside `/config` (or `/config/beets-flask`) and the container pip-installs it at
startup, after running any `/config/startup.sh`. [CITED: docs/plugins.md, "Example requirements.txt:
discogs"]

> ⚠ The beets-flask docs' `startup.sh` examples use `apk` (Alpine). **rc4 changed the base image to
> `python:3.12-slim`**, and the rc6 `Dockerfile` confirms `python:3.12-slim-trixie` (Debian). The
> `apk` examples in `docs/faq.md` and `docs/plugins.md` are **stale**. Use `apt-get` if a
> `startup.sh` is needed — but for Discogs, `requirements.txt` alone should suffice since
> `python3-discogs-client` is pure Python.

### Supporting

| Tool | Where | Purpose |
|---|---|---|
| `metadata` (wrtag binary) | inside `sentriz/wrtag:*` at `/usr/local/bin/metadata` | D-13's challenger. Dockerfile does `go build -o /out/ ./cmd/...` then `COPY --from=builder /out/* /usr/local/bin/`, and `cmd/` contains `metadata`, `wrtag`, `wrtagweb` at **both** v0.20.0 and v0.34.0. README: *"The Docker image by default starts `wrtagweb`, but has the `wrtag` tools included too."* Also available as a static binary on the releases page |
| `scripts/diff-music-tags.sh` | repo, host-resident | Scores field loss after a normalisation run (D-13). `audio_md5`-keyed, proven on a mutated-copy negative control in 01-03 |
| `scripts/snapshot-music-tags.sh` | repo | Re-runnable before/after capture for the scratch copies |
| `scripts/check-music-freeze.sh` | repo | Re-run after the spike; exits 1 on any failed assertion |
| `ffprobe` | LXC 100 `/usr/bin/ffprobe` | Independent tag reader for cross-checks |
| `cp --reflink=always` | LXC 100 | D-07 scratch copies |
| `setsid` + `nohup` | LXC 100 | **The detach mechanism** — `tmux` and `screen` are both absent (Phase 1, 01-04) |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|---|---|---|
| `tag_album()` Python probe | `beet import -t` + transcript parsing | Timid mode requires a human keypress per folder; unusable across 20+40 runs, and the transcript is not machine-parseable. Keep `-t` as the *second* instrument on a 3-folder subset |
| `tag_album()` Python probe | `beet import -q --log` | Quiet mode logs only the *outcome* (`skip`/`asis`/`duplicate`), not the candidate set or its track counts. Cannot satisfy D-05 |
| `urllib3` DEBUG request counting | HTTP forward proxy with a counter | Heavier, and adds a moving part between the measurement and the truth. Use only if the log approach proves noisy |
| `metasauce/beets-flask:v2.0.0-rc6` | `pspitzner/beets-flask:v1.2.1` (`stable`) | v1.2.1 is the last **non-RC** release (28 Dec 2025) and is 8 months stale; rc6 is what a real deployment would use and is where the frictions actually live. **Use rc6**, and record "still in RC after 8 months" as an axis-two risk |
| mutagen script | `kid3-cli` | Not installed on LXC 100, and per-folder conditional logic is awkward. Genuine plan B, out of scope here |

**Nothing is installed on the host by this phase.** The only package installs happen *inside*
throwaway containers.

---

## Package Legitimacy Audit

Phase 3 installs no packages onto LXC 100 or the Proxmox host. It pulls three container images and
may pip-install one extra inside the beets-flask container.

Gate run 2026-09-01: `slopcheck install beets mutagen python3-discogs-client` → **3 OK, 0 SUS,
0 SLOP** (scan completed; slopcheck then aborted on its own subprocess handoff — the verdicts above
are from the completed scan phase).

| Package | Registry | Age | Downloads / signal | Source repo | slopcheck | Disposition |
|---|---|---|---|---|---|---|
| `beets` | PyPI | first upload **2013-01-29**, 75 releases, latest 2.13.1 (2026-07-29) | beets.io, very high repo activity | github.com/beetbox/beets | `[OK]` | **Approved** |
| `mutagen` | PyPI | first upload **2013-05-21**, 64 releases, latest 1.48.1 | standard tag library; beets' own dependency | mutagen.readthedocs.io | `[OK]` | **Approved** |
| `python3-discogs-client` | PyPI | first upload **2020-06-27**, 22 releases, latest 2.9 | maintained `joalla` fork of the abandoned official client | github.com/joalla/discogs_client | `[OK]` — flagged *"name ends with `-client`, classic LLM naming pattern… but package is established"* | **Approved.** Already vendored into `lscr.io/linuxserver/beets` — the phase does not install it directly |

**Container images** (not covered by slopcheck; verified by registry + source repo):

| Image | Provenance | Verdict |
|---|---|---|
| `lscr.io/linuxserver/beets:2.13.1-ls349` | linuxserver.io official; Dockerfile read at that tag; builds beets from `github.com/beetbox/beets` at `v${BEETS_VERSION}` | Approved |
| `sentriz/wrtag:v0.34.0` / `:v0.20.0` | `org.opencontainers.image.source=https://github.com/sentriz/wrtag`; Dockerfile read at both tags | Approved |
| `metasauce/beets-flask:v2.0.0-rc6` | Repo moved from `pSpitzner/beets-flask` (437★) to `metasauce/` per rc6 release notes; both Docker Hub and GHCR publish rc6 on 2026-08-30 | Approved **with a note** — this is a **release candidate**, not a stable release, and 2.0 has been in RC since 2025-12-29. The planner should gate the trial deployment behind a `checkpoint:human-verify` acknowledging that |

**Packages removed due to `[SLOP]`:** none.
**Packages flagged `[SUS]`:** none.

---

## D-12 Claim Audit — the PROJECT.md head-to-head, row by row

Method: each row re-checked against a primary source (tagged upstream source, official docs,
registry API) on 2026-09-01. Verdicts: **holds** / **changed** / **falsified**.

| # | PROJECT.md claim | Current primary source | Verdict | One-line impact on the decision |
|---|---|---|---|---|
| 1 | wrtag: *"Metadata sources: **MusicBrainz only**"* | README §"Available operations", §Configuration; no non-MB backend in `cmd/` or `go.mod` | **HOLDS** | **This is the argument that does all the work, and it survives intact.** |
| 2 | *"Non-MusicBrainz DJ releases: [wrtag] **Cannot.** No non-MB source exists or is planned"* | Same; v0.30.0–v0.34.0 changelogs add no source backends | **HOLDS** | Unchanged |
| 3 | *"Repairing existing wrong tags: [wrtag] **No facility.**"* | `cmd/metadata/` exists at **v0.20.0 and v0.34.0**; ships in the container | **FALSIFIED** — as D-12 states | wrtag *can* write tags. **But see row 4** — the capability is far narrower than the falsification implies |
| 3a | *(D-12's inference)* `metadata` is *"plausibly a direct competitor to the mutagen script"* | `cmd/metadata/main.go` `cmdWrite()`: builds one literal `map[string][]string` and applies it to **every** path via `iterFiles`; **no `-dry-run`, no diff, no field-to-field move**; only flags are `-log-level`, `-properties` (read), `-index`/`-type`/`-desc`/`-mime-type` (images) | **CHANGED — materially weaker than claimed** | An `artist`→`album` remap needs one `read` + one `write` **per file**, in a shell loop, writing blind. D-13's bake-off is still worth running (it is cheap) but the reviewability requirement in D-08 is unmet by `metadata` unless wrapped |
| 3b | *(new, not in PROJECT.md)* what `metadata write` does to unlisted tags | `tags.WriteTags(path, t, 0)` — flag `0`, **not** `tags.Clear` | **NEW — favourable to `metadata`** | `metadata write` **merges**; it will not silently drop `TKEY`/`EnergyLevel`. Confirm empirically with `diff-music-tags.sh` — do not take this from source alone |
| 3c | *(new)* what a real `wrtag move`/`copy` does to unlisted tags | `wrtag.go:267` — `tags.WriteTags(destPath, destTags, tags.Clear)` | **NEW — decisive for TAGR-02** | **A real wrtag run WIPES every tag not in its computed set.** 148 `TKEY` and 45 `EnergyLevel` files in `dj-mixes` would be destroyed without a configured `keep` rule. This belongs in the criterion 4 record |
| 4 | *"beets: `import -A`, `edit`, `modify` (`+=`/`-=` since 2.13.0), `zero`, `write`, query language"* | beets changelog 2.13.0 confirms `modify +=`/`-=` and the `edit` album-YAML header | **HOLDS** | Unchanged. Note `+=`/`-=` is **absent from beets-flask rc6** (pinned 2.12.0) |
| 5 | *"Current version: beets 2.13.1 (29 Jul 2026) / wrtag v0.33.0 (11 Jul 2026)"* | PyPI: beets 2.13.1 still latest 2026-09-01. Docker Hub: **wrtag v0.34.0, 26 Aug 2026** | **CHANGED** | See finding 2 — recommend testing at v0.34.0 |
| 6 | *"Container: `lscr.io/linuxserver/beets:2.13.1` / `sentriz/wrtag:v0.33.0`"* | Both exist; LSIO `2.13.1` **floats** across ls-revisions | **CHANGED (sharpened)** | Pin `2.13.1-ls349`. The floating-2-part-tag hazard is already recorded in project MEMORY (Renovate deploy drift) |
| 7 | *"Bulk re-tag of an organised library: `wrtag sync` — genuinely better, this is wrtag's standout feature"* | README §"Re-tagging in bulk"; `sync -dry-run`, `-num-workers`, `-age-older`; treelock | **HOLDS** | Unchanged — and irrelevant to this phase, which has no organised library to re-tag |
| 8 | *"Path-format safety: [wrtag] validates the format can't collide two tracks/releases at startup"* | v0.20.0 `Validate` builds **single-medium** synthetic releases only; v0.30.0 adds *"validations for multi disc releases"* | **CHANGED — the claim is version-dependent** | At v0.20.0 the validation is **strictly weaker than advertised**, and that is precisely why the repo's broken format passed startup for eight months |
| 9 | *"beets Web UI: the `web` plugin is a library browser, not an importer"* | beets docs `plugins/web` | **HOLDS** | Which is exactly why axis two needs beets-flask |
| 10 | *"wrtagweb: real import queue with notify + confirm — genuinely better"* | README §"Tool `wrtagweb`", `POST /op/{copy,move,reflink}` with `mbid`/`confirm` | **HOLDS** | **But** it can only confirm *MusicBrainz* candidates. For bucket C its notify-and-confirm loop has nothing to offer |
| 11 | *"`WRTAG_RESEARCH_LINK` … wrtag's answer was 'here is a link, go look it up yourself'"* (`<specifics>`) | `wrtag.yaml:73` + README §researchlink; v0.32.0 added *"researchlink: add mbid data"* and *"render MBID only on positive match"* | **HOLDS** | Quote it verbatim in the criterion 4 record — it is the cleanest statement of what "the content lives outside the tool" looks like in practice |
| 12 | *"beets `library.db` … this repo has **two**"* | 01-02: there are **four**; `soulbeet`'s does not exist | **FALSIFIED (already corrected in Phase 1)** | Carried forward for completeness; no Phase 3 impact |
| 13 | *"beets 2.13.1 … The LSIO image handles [Python >=3.10,<3.15]"* | PyPI `requires_python: <3.15,>=3.10`; LSIO base `baseimage-alpine:3.23` | **HOLDS** | — |
| 14 | *"beets ≥ 2.4.0: `musicbrainz` must be listed explicitly in any customised list"* | `config_default.yaml` v2.13.1 line 10: `plugins: [musicbrainz]` | **HOLDS** | Still true at 2.13.1 and at 2.12.0. beets-flask's own v1.2.0 release notes carry the same warning |
| 15 | *"Bulk import of thousands: [beets] works, but interactive by nature"* | beets-flask `docs/limitations.md`: *"once you hit some hundred folder or so, this will get laggy"* (#164, #175) | **CHANGED — a new, adverse fact for axis two** | The backlog is **143 folders** (finding 6), which is *just under* the stated pain threshold. Record it; it is the single strongest argument against beets-flask and it was not previously known |
| 16 | *"beets-flask … one shared `library.db` across N policy-carrying inbox folders"* | `docs/configuration.md`: config is `config/beets/config.yaml` (a **normal beets config**, so one `library`) + `config/beets-flask/config.yaml` defining `gui.inbox.folders.*` each with its own `autotag` policy | **HOLDS — confirmed from primary source** | Criterion 7's central claim is verified. This *is* the Phase 5 structure |

### New capability found during the audit that PROJECT.md does not mention

beets-flask's `autotag: "bootleg"` inbox mode is documented as *"Import as-is using the meta data of
files, and group albums using the metadata… Effectively `beet import ... --group-albums -A`"*.

That is a **first-class UI affordance for exactly the content criterion 4 asks about** — DJ
releases that will never match any source. It belongs in the axis-two score and in the criterion 4
answer, and it is arguably the single strongest pro-beets-flask finding in this research.

---

## Measurement Protocol — one instrument per success criterion

Standing rule for every row: **a number is not recorded until a second, independent instrument
agrees.** Phase 1 produced six unearned passes, every one from partial data stated as settled.

### Criterion 1 — Discogs match rate on normalised vs un-normalised DJ folders

**Primary instrument:** a Python probe inside the LSIO beets container calling
`beets.autotag.match.tag_album()` directly. This is the only mechanism that yields both the loose
and the strict figure mechanically, because `AlbumMatch` carries the candidate's track list *and*
the item/track mismatch:

```python
# beets/autotag/match.py v2.13.1 — the shape the probe consumes
class Proposal(NamedTuple):
    candidates: Sequence[AlbumMatch | TrackMatch]
    recommendation: Recommendation      # none | low | medium | strong

class AlbumMatch(Match):
    distance: Distance
    info: AlbumInfo                     # .data_source, .album, .album_id, .tracks
    mapping: dict[Item, TrackInfo]
    extra_items: list[Item]             # folder files with no matching track
    extra_tracks: list[TrackInfo]       # release tracks with no matching file

def tag_album(items, search_artist=None, search_name=None, search_ids=[]
) -> tuple[str, str, Proposal]: ...
```

Sketch (flagged for a Wave-0 smoke test against one known-good album before it is trusted — the
plugin-loading incantation is the part most likely to need adjusting):

```python
#!/usr/bin/env python3
# runs INSIDE the beets container. Writes NDJSON to stdout. Reads nothing it can write.
import json, os, sys, glob
from beets import config, plugins
config.set_file(os.environ["SPIKE_CONFIG"])          # explicit — never the default config
config["library"] = os.environ["SPIKE_DB"]           # explicit throwaway .blb (see Pitfall 1)
plugins.load_plugins(config["plugins"].as_str_seq())
plugins.find_plugins()

from beets.library import Item
from beets.autotag import match

for folder in sys.argv[1:]:
    paths = sorted(p for p in glob.glob(folder + "/*")
                   if p.lower().endswith((".mp3", ".flac", ".wav", ".m4a")))
    items = [Item.from_path(p) for p in paths]
    cur_artist, cur_album, prop = match.tag_album(items)
    for m in prop.candidates:
        print(json.dumps({
            "folder": os.path.basename(folder),
            "n_files": len(items),
            "cur_artist": cur_artist, "cur_album": cur_album,
            "source": m.info.data_source,
            "album": m.info.album,
            "album_id": m.info.album_id,
            "n_tracks": len(m.info.tracks or []),
            "extra_items": len(m.extra_items),      # files with no track  -> strict fail
            "extra_tracks": len(m.extra_tracks),    # tracks with no file  -> strict fail
            "distance": float(m.distance),
            "recommendation": str(prop.recommendation),
        }))
```

**Scoring, applying D-05 mechanically:**

- **Loose rate** = folders where `any(c.source == "Discogs")`
- **Strict rate** = folders where `any(c.source == "Discogs" and c.n_tracks == n_files and
  c.extra_items == 0 and c.extra_tracks == 0)`
- The **gap between them is a deliverable** (`<specifics>`), reported as a count and a percentage

**Second instrument:** `beet import -t` (timid) run interactively on **3 folders drawn from
different strata**, with the on-screen candidate list and its track counts transcribed by hand and
compared to the probe's NDJSON for those three. If they disagree, the probe is wrong. Timid mode
also suppresses the strong-MBID early return in `tag_album`, so it sees the same candidate set.

**Paired runs — four cells, not two:**

| | un-normalised | normalised |
|---|---|---|
| `musicbrainz` only | (baseline) | (isolates the normalisation effect on MB) |
| `musicbrainz` + `discogs` | **the "raw tags" figure the criterion demands** | **the headline figure the ~40% threshold applies to** |

The MB-only cells cost nothing extra (same probe, different `plugins:` line) and answer whether the
normalisation helps *at all* independent of source — which the Discogs number alone cannot.

**Rate denominator — state it explicitly (`<specifics>`).** Compute **per folder** as the headline,
because that is the unit of work and the unit the threshold was written against. Cross-check against
**distinct `audio_md5`** using the QUAL-01 NDJSON (`/mnt/fast/safety/music-pre-project/tags/
pre-project.ndjson.gz`, 9,736 records, `audio_md5`-keyed) and report both. With `dj-mixes` proven a
duplicate of `unsorted` content (finding 5), a naive union over both trees would double-count every
folder — the sample must be drawn from **one** tree.

**Interference to control for:** `discogs.index_tracks` defaults to `no`, and Mastermix/DMC releases
on Discogs commonly use index tracks and headings, which changes the candidate's reported track
count. **Run the strict scoring at both `index_tracks: no` and `yes` on the same sample** and report
which setting produced the headline number. A track-count rule is meaningless without stating how
tracks were counted.

**What would falsify the measurement itself:** the probe reporting Discogs candidates when the
`discogs` plugin is not actually loaded (impossible — `data_source` would say MusicBrainz), or the
probe reporting zero candidates for a folder where `beet import -t` shows some (means plugin
loading differs between the two paths — investigate before recording anything).

### Criterion 2 — request count and the hours-for-the-backlog extrapolation

**Requests per folder, derived from source** (`beetsplug/discogs/__init__.py` +
`beets/metadata_plugins.py`, v2.13.1):

| Call | Count | Source |
|---|---|---|
| `discogs_client.search(query, **filters)` → `.page(1)` | **1** | `get_search_response()` |
| `album_for_id()` → `Release(...)` then `getattr(result, "title")` | **≤ `search_limit`** | `candidates()` → `albums_for_ids()` |
| `get_master_year(master_id)` → `Master(...)` | **≤ `search_limit`**, `@cache`d **per process** | `get_album_info()` line 417 |

`search_limit` defaults to **5** (`beets/metadata_plugins.py:201`).

→ **6 to 11 Discogs requests per folder**, plus MusicBrainz requests (separately rate-limited at
1 req/s) when both plugins are on.

**Extrapolation arithmetic, with the corrected denominator from finding 6:**

```
folders_backlog          = 143          (unsorted 120 + music 23; dj-mixes is a duplicate)
req_per_folder_measured  = M            (measure — do not assume 6..11)
total_requests           = 143 * M
ceiling                  = 60 req/min authenticated  (x-discogs-ratelimit: 60, D-04)
api_floor_minutes        = 143 * M / 60
wall_clock_minutes       = measured_20_folder_seconds / 60 * (143 / 20)
```

For M in 6..11 the pure-API floor is **14 to 26 minutes**, not "hours". Wall-clock will exceed it
(MusicBrainz's 1 req/s, ffprobe reads over ZFS, per-folder Python overhead) — which is exactly why
both figures get recorded.

**Primary instrument:** wall-clock of the 20-folder probe run, `time`d, with a per-folder timestamp
in the NDJSON.

**Second instrument (the independent one):** enable `urllib3` DEBUG logging in the probe process and
count `api.discogs.com` request lines. This counts what actually left the process, independently of
beets' own bookkeeping:

```python
import logging
logging.basicConfig(level=logging.DEBUG, stream=sys.stderr)
logging.getLogger("urllib3.connectionpool").setLevel(logging.DEBUG)
# then: grep -c 'api\.discogs\.com' stderr.log
```

**The hazard that will silently corrupt this number.** `python3-discogs-client`'s fetchers set
`backoff_enabled = True` by default, and the `@backoff` decorator retries a `429` up to
**`MAX_ATTEMPTS = 100`** times with `2**i` seconds of jittered sleep. A rate-limited run therefore
does **not** error — it stalls, absorbing the delay into wall-clock with no visible signal.
**Count `429` responses separately and record them beside the timing**, or the extrapolation is
uninterpretable. (Recorded from `discogs_client/utils.py`, `get_backoff_duration` /
`backoff`.)

**Pre-committed threshold:** "rate limiting makes bulk impractical" must be given a number *before
the run*. Recommendation to the planner: **> 4 hours of projected wall-clock for the 143-folder
backlog**, or **any observed `429` during the 20-folder run**. Both are falsifiable; commit them in
the plan, not afterwards.

### Criterion 3 — the wrtag disqualifier

**Two arms, same throwaway album, same command shape, both recorded.**

```bash
# safe: -dry-run means op.CanModifyDest() == false, so wrtag.go:267's
# tags.WriteTags(destPath, destTags, tags.Clear) is skipped entirely (verified in source).
# Cover fetching is also gated on CanModifyDest(). Nothing is written.
docker run --rm \
  -v /mnt/tank/downloads/<scratch>/wrtag-src:/music/source:ro \
  -v /mnt/fast/<scratch>/wrtag-lib:/music/library:rw \
  -e WRTAG_PATH_FORMAT='<verbatim from wrtag.yaml:71>' \
  -e WRTAG_LOG_LEVEL=debug \
  sentriz/wrtag:v0.20.0 \
  wrtag move -dry-run "/music/source/<album>"
# …then identically with sentriz/wrtag:v0.34.0
```

The `-v .../wrtag-lib` destination is a **scratch** path; D-22 requires the target cannot be the
real library, and the repo's format is rooted at `/music/library`.

**What to record, per arm:**

| Observation | v0.20.0 expectation | v0.34.0 expectation |
|---|---|---|
| Startup path-format validation | **passes** (single-medium synthetic only) | passes |
| Rendered destination path, single-disc album | contains **`-1 - `** as the track number | contains the real per-disc position |
| Rendered destination path, **multi-disc** album | template execute error naming `Media` | renders `Disc N/` correctly |
| `logTagChanges` debug output (`WRTAG_LOG_LEVEL=debug`) | shows the intended tag set | shows the intended tag set |
| Files written | **zero** — assert with a before/after `find -newer` on both mounts | zero |

**The multi-disc arm is mandatory**, not optional: 160 of 764 `dj-mixes` files carry a `disc` tag,
and the single-disc arm alone cannot exhibit the `.Media.Position` failure. Pick one album from each
class.

**Second instrument:** the static source diff (finding 1) — the `Data` struct at both tags plus the
`d.Track.Position = -1` line. Runtime output and source must tell the same story; if they do not,
one of them is being misread.

**Explicitly non-evidence, per D-01 and the criterion:** the `0.x` version number; the current
container's brokenness; the age of the Renovate rule.

### Criterion 4 — what happens to Mastermix / DMC / Music Factory content

Not a measurement; a **statement the decision record must contain**, supported by criteria 1 and 3
plus these verified facts:

| Under | The unmatched-content answer | Source |
|---|---|---|
| beets (terminal) | `beet import -A` (as-is) after normalisation; `--set albumtype=dj` + a `paths:` rule routes it out of `Compilations/` | beets CLI docs |
| beets-flask | an inbox with `autotag: "bootleg"` — *"Import as-is using the meta data of files, and group albums using the metadata… Effectively `beet import ... --group-albums -A`"* | `docs/configuration.md` |
| wrtag | **`WRTAG_RESEARCH_LINK` — a hyperlink to a Discogs search, for the human to resolve manually.** `wrtag.yaml:73` already points at `https://www.discogs.com/search/?q={query}` | README §researchlink; the repo's own config |
| wrtag (side effect) | a real `move`/`copy` calls `tags.WriteTags(dest, destTags, tags.Clear)` — **all tags not in wrtag's computed set are wiped** unless a `keep` rule is configured. 148 `TKEY` + 45 `EnergyLevel` files are at stake | `wrtag.go:267`; README §"Tag configuration" |

Quote `wrtag.yaml:73` verbatim in the record (`<specifics>` asks for it) — whoever configured that
line already knew this content lives on Discogs, and wrtag's answer was to hand the operator a URL.

### Criterion 5 — pre-committed thresholds

Three thresholds, written into the **plan** before any evidence is collected, and each with a
recorded "tested / returned" line in the decision record:

| # | Threshold | Falsifiable form | Instrument |
|---|---|---|---|
| T1 | Discogs matching under **~40%** of `dj-mixes` after normalisation | **strict** rate (D-05) over the D-06 sample, `index_tracks` setting stated | Criterion 1 probe |
| T2 | Rate limiting makes bulk impractical | > 4 h projected wall-clock for 143 folders, **or** any observed `429` in the 20-folder run | Criterion 2 timing + `429` counter |
| T3 | The operator will not sit at the interactive prompt | An explicit written self-assessment after the timed trial, in the operator's own words | Criterion 6/8 trial |

T1 and T2 are numbers. T3 is deliberately not a number — the roadmap defines it as a self-assessment
and pretending otherwise would be false rigour.

### Criteria 6 and 8 — the ergonomics trial, scored rigorously

**The set (D-10), sourced concretely:**

| Slot | Draw from | Candidates observed |
|---|---|---|
| 2 clean mainstream | `nzb/music` (23 folders, FLAC) | `Ed Sheeran - ÷ (2017) FLAC`, `Lady Gaga - The Fame (2008) FLAC` |
| 1 various-artist compilation | `nzb/unsorted` | a `Now That's What I Call Music` volume |
| 1 flat multi-disc set | `nzb/unsorted` or `nzb/music` | `Def Leppard - CD Collection Volume 1 - 7CD`; **verify it is genuinely flat** before committing |
| 1 DJ folder Discogs will not match | the criterion-1 results | pick a folder the probe scored **loose-fail** — chosen *after* criterion 1 runs, not before |

**The scoring sheet — one row per (album × front end), filled during the run, not after:**

| Field | Type | Note |
|---|---|---|
| `front_end` | `beets-terminal` \| `beets-flask` | |
| `album` | id | |
| `wall_clock_s` | integer | Start when the operator first looks at the album; stop when it is imported or abandoned |
| `interventions` | integer | Every discrete decision or keystroke sequence the operator had to author. Define the counting rule in the plan and hold it constant |
| `outcome` | `imported` \| `as-is` \| `skipped` \| `abandoned` | |
| `stuck_points` | free text | *"where the operator got stuck or annoyed"*, D-09 — verbatim, at the moment, not reconstructed |
| `context_switches` | integer | Times the operator had to leave the tool (open a browser, grep a path, read docs) |

**Ordering control.** Run the same album on both front ends, but **alternate which front end goes
first across the five albums.** Second-pass runs are always faster because the operator now knows
the answer; a fixed order silently rewards whichever tool went second.

**Criterion 8's verdict is a sentence, not a score.** *"whether the chosen combination is one that
will still be used in week six"* — record it in the operator's own words, and record the
`stuck_points` that produced it beside it.

### Criterion 7 — beets-flask evaluated by name

**Verified facts to carry into the evaluation.** Every D-11 friction re-checked against current
docs/source, plus three not previously known:

| Friction | Status 2026-09-01 | Source |
|---|---|---|
| 1.0 removed interactive terminal import in favour of UI candidate selection | **HOLDS**; there is a built-in tmux-backed web terminal (`libtmux` in `pyproject.toml`, `gui.terminal.start_path` config) for pasting a release ID | rc-series release notes; `docs/configuration.md` §Terminal |
| Inbox entries must be directories; loose files never trigger | **HOLDS, and is a documented wontfix**: *"Singletons are not supported (wont fix)… The simple workaround is to place individual files in their own folder"*; and *"Files directly inside the inbox wont trigger an imported"* | `docs/limitations.md`, `docs/configuration.md` |
| Music paths must match inside and outside the container | **HOLDS**: *"`/music_path/clean/` needs to be consistent inside and outside of the container. Otherwise beets will not be able to manage files correctly."* | `docs/getting-started.md` |
| **NEW —** only `copy` is supported, never `move` | *"In order to provide an easy way to correct automatic imports that went wrong, it is easiest to only allow copies"* (#193) | `docs/limitations.md` |
| **NEW —** UI gets laggy past "some hundred" folders | *"You might be tempted to import a large existing library… once you hit some hundred folder or so, this will get laggy"* (#164, #175) | `docs/limitations.md` |
| **NEW —** `beets==2.12.0` hard pin | exact `==` in `backend/pyproject.toml` at rc6 | primary source |
| **NEW —** 2.0 has been in RC since 2025-12-29; last stable is v1.2.1 | GitHub releases | primary source |
| **NEW —** docs' `apk`-based `startup.sh` examples are stale (base is Debian since rc4) | rc4 release notes + rc6 `Dockerfile` (`python:3.12-slim-trixie`) | primary source |

`only copy is supported` is **favourable** here — PROJECT.md's storage constraint already requires
first passes to use `copy`, so beets-flask enforces what this project wants anyway.

**Architecture claim — CONFIRMED.** Criterion 7's *"one shared `library.db` across N
policy-carrying inbox folders"* is exactly the architecture: `config/beets/config.yaml` is a
**normal beets config** (so one `library`), and `config/beets-flask/config.yaml` defines
`gui.inbox.folders.*`, each with its own `autotag` policy:

```yaml
gui:
  inbox:
    folders:
      Inbox2: { name: "…", path: "/music/inbox_preview",  autotag: "preview" }   # fetch, don't import
      Inbox3: { name: "…", path: "/music/inbox_auto",     autotag: "auto",
                auto_threshold: null }                                            # null -> match.strong_rec_thresh
      Inbox4: { name: "…", path: "/music/inbox_bootlegs", autotag: "bootleg" }    # == import --group-albums -A
```

**Trial deployment that does not touch the frozen stacks (D-03).** Sketch — the planner owns the
exact file, which must live at a clearly-scratch path and be deleted at phase end:

```yaml
# NOT under stacks/selfhosted/{arrs,music}/ — a throwaway spike file, deleted in the closing plan.
services:
  beets-flask-spike:
    image: metasauce/beets-flask:v2.0.0-rc6      # RC, not stable — see the audit note
    container_name: beets-flask-spike
    restart: "no"
    profiles: ["manual"]                          # same discipline as the frozen stacks
    security_opt: [ no-new-privileges:true ]
    ports: [ "5002:5001" ]                        # 5002 — do not collide with anything on 5001
    environment:
      TZ: ${TZ}
      USER_ID: 568                                # apps:apps, the estate convention
      GROUP_ID: 568
      LOG_LEVEL_BEETSFLASK: DEBUG
    env_file:
      - /mnt/fast/secrets/discogs.env             # never -e, never a command line
    volumes:
      - /mnt/fast/<scratch>/bf-config:/config:rw
      # paths MUST be identical inside and outside the container:
      - /mnt/tank/downloads/<scratch>/inbox:/mnt/tank/downloads/<scratch>/inbox:rw
      - /mnt/tank/downloads/<scratch>/clean:/mnt/tank/downloads/<scratch>/clean:rw
      # D-20: nobody holds rw on Music during Phases 1-3. If Music is mounted at all, :ro.
      # Preferred: do not mount it.
```

Then `/config/requirements.txt` containing `beets[discogs]`, and `/config/beets/config.yaml`
declaring `plugins: musicbrainz discogs importsource` with `directory:` pointing at the scratch
`clean` path.

**Redis:** rc-series bundles it internally (`REDIS_URL` is *configurable*, not required —
`rq>=2.0.0` in `pyproject.toml`, and the published `docker-compose.yaml` declares no redis
service). No extra container. `redis:7-alpine` is already on the host if an external one is ever
wanted.

---

## Sample selection and normalisation (D-06, D-07, D-08)

### Where the variant inventory comes from — it already exists

**No new task is needed to establish it.** Phase 1's SAFE-03 capture,
`/mnt/fast/safety/music-pre-project/dj-mixes-ffprobe/`, holds one JSON per file for all **764**
files across **60** folders, and the variant table in finding 4 was produced from it read-only in a
single pass. The plan needs one short task to *formalise* that survey into a committed artefact
(folder → variant class), not to discover it.

### Stratification (D-06)

Six observed strata (finding 4). Suggested draw of 20, adjusted by the planner once the formal
survey lands:

| Stratum | Draw | Why |
|---|---|---|
| V1 `artist="Mastermix"` | 4 | The best case — establishes the ceiling |
| V2 `artist="VA"`/`"Various Artists"` | 5 | The `va_likely` query-pollution case; the main normalisation hypothesis |
| V3 `album` absent | **4** | *"a few with no usable tags"* (D-06) — and the only stratum where the un-normalised rate is provably 0% |
| V5 noisy `album` (`Disc N`, ` WEB`, `Vol.`) | 4 | Tests canonicalisation |
| V6 real per-track artists | 3 | Newest issues; a different shape entirely |
| — | | **Not** drawn from the 27 scan-bearing folders (D-06 excludes them) |

Record file format per folder alongside — **134 of 764 files are WAV**, and WAV tagging is
substantially weaker than MP3/FLAC in every tool here. If a stratum is WAV-dominant, that is a
finding, not noise.

**Suggested addition, for the operator to approve or reject:** 3–4 DMC folders from `unsorted` as a
**separate, separately-reported stratum** (finding 5), because `dj-mixes` contains no DMC and
criterion 4 names DMC explicitly.

### Scratch mechanics (D-07)

Re-verified 2026-09-01 from atlantis:

```
tank            38.1T used, 9.00T avail
tank/downloads  2.00T, one dataset, acltype=nfsv4 aclmode=restricted aclinherit=passthrough
tank/media      35.4T, separate dataset
tank  feature@block_cloning  active  (local)
```

```bash
# On LXC 100 (rsync is NOT installed; cp --reflink works within tank/downloads).
SRC=/mnt/tank/downloads/complete/nzb/dj-mixes
SCRATCH=/mnt/tank/downloads/spike-03           # sibling of complete/ => same dataset => reflink OK
mkdir -p "$SCRATCH"/{raw,normalised}
for f in <the 20 stratified folder names>; do
  cp -a --reflink=always "$SRC/$f" "$SCRATCH/raw/"      || exit 1   # fail loud, do not fall back
  cp -a --reflink=always "$SCRATCH/raw/$f" "$SCRATCH/normalised/"   # normalise THIS copy only
done
```

- `--reflink=always` (not `auto`): with `auto`, a cross-dataset mistake degrades silently to a full
  copy and the plan learns nothing. Fail loud.
- `cp -a` preserves mode/ownership; **`chmod` and `chown` both fail on `tank` from LXC 100** for two
  *different* reasons (`aclmode=restricted` and the sparse idmap respectively). Do not attempt
  either — everything on `tank` is `0777` already, so read access is not in question.
- **The originals in `dj-mixes` are themselves a duplicate copy of `unsorted`** (finding 5), so
  there are two independent fallbacks behind the reflink: `unsorted`, and `tank/downloads@pre-project`.
- Take a `zfs snapshot tank/downloads@spike-03-t0` from **atlantis** before the first write into
  `$SCRATCH/normalised`. `zfs` does not exist on LXC 100.
- Delete `$SCRATCH` in the phase's closing plan. Reflinked clones only free space when the last
  reference goes; ZFS frees asynchronously and `zfs list` can lag ~20 s.

### The normalisation script (D-08)

Established repo pattern: `scripts/*.sh`, `#!/usr/bin/env bash`, `set -euo pipefail`, ALL-CAPS
constants, run from `/mnt/fast/stacks` after a `git pull`. **Commits must reach `origin` before
LXC 100 can pull and run them** — git is the delivery path, and LXC 100 currently sits at `90cdddc`
while the workstation is at `5199db3`.

For this script, Python is the right tool (mutagen, per-file conditional logic), so:
`scripts/normalise-dj-tags.py` with a `scripts/normalise-dj-tags.sh` wrapper if the repo's shell
convention matters more than the language fit — planner's call.

**Minimum behaviour (and no more):**

1. `--dry-run` **is the default**; writing requires an explicit `--apply`. Inverting this is the
   single cheapest safety control available.
2. Emits a **per-file diff** (`field: old -> new`) on stdout in both modes, so the dry run is the
   review artefact D-08 asks for.
3. Refuses to run on any path not under the scratch root. A hardcoded prefix check.
4. Rules, in order:
   - if `album` empty/missing → derive `Mastermix Issue NNN` from the folder name (V3, 107 files)
   - canonicalise `album`: strip ` WEB`, ` - Disc N`, `Vol.`, leading `Mastermix - `, trailing
     whitespace, `_` → ` ` (V5)
   - set `artist` to a single consistent value across the folder (V2/V4) — **and record which
     value**, because the choice flips `va_likely` and therefore the query shape
   - touch nothing else. Not `title`, not `track`, not `TKEY`, not `EnergyLevel`
5. Writes with `mutagen`, preserving all other frames.

**Verification of the script itself:** run `scripts/snapshot-music-tags.sh` over
`$SCRATCH/normalised` before and after, then `scripts/diff-music-tags.sh`. The five difference
categories must show changes in **exactly** `album` and `artist` and nowhere else. That tool was
proven against a mutated-copy negative control in 01-03; it exits 1 with the right rows.

### D-13 — `metadata` vs mutagen, same job, same folders

| Axis | mutagen script | wrtag `metadata` |
|---|---|---|
| Dry-run | **Yes, and it is the default** | **No.** No flag exists on `write` |
| Reviewable diff before writing | Yes, per-file | No |
| Per-file distinct values in one invocation | Yes | **No** — `iterFiles` applies one literal map to every path |
| Field-to-field move | Yes (read then write) | **No primitive** — needs a `read` + `write` shell loop per file |
| Preserves unlisted tags | Yes | Yes — `WriteTags(path, t, 0)`, flag `0` not `tags.Clear`. **Verify empirically** |
| Formats | MP3, FLAC, WAV(partial) | MP3, FLAC, **WAV** and 30+ others via `go.senan.xyz/taglib v0.14.0` |
| Exit code on failure | script's own | Correct — `wrtaglog.Setup()` returns a deferred `os.Exit(1)` if any `slog.Error` fired |
| Committed, versioned, auditable | Yes (`scripts/`) | The loop would be, the tool is not |

Run both against the **same 20 normalised-copy folders in two separate reflinked trees**, score with
`diff-music-tags.sh` against the same before-snapshot, and record wall-clock and lines-of-driver.

> **Honest expectation, stated so the measurement is not theatre:** the reviewability requirement in
> D-08 is not met by `metadata` without a wrapper, and on this project's own standing rule
> (*"verify with a second independent instrument before you write it down"*) that is close to
> decisive. The bake-off is still worth running because it is cheap, because D-13 asks for it, and
> because `metadata`'s taglib backend may handle the 134 WAV files better than mutagen does — which
> would be a genuine, unanticipated reason to prefer it for one stratum.

---

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Counting Discogs candidates and their track counts | A parser for `beet import -t` terminal output | `beets.autotag.match.tag_album()` returning `Proposal`/`AlbumMatch` | The terminal output is for humans; `AlbumMatch.extra_items`/`extra_tracks` gives the strict-match answer directly |
| Detecting whether a normalisation run lost fields | A bespoke before/after comparator | `scripts/snapshot-music-tags.sh` + `scripts/diff-music-tags.sh` | Already built, `audio_md5`-keyed (survives renames), and already proven against a negative control |
| Deduplicating the sample across `dj-mixes`/`unsorted` | A filename matcher | The QUAL-01 `audio_md5` NDJSON | Filenames differ between the trees; the encoded bitstream does not |
| Copying 20 folders on ZFS | `rsync`, `tar`, `dd` | `cp -a --reflink=always` | `rsync` is not installed and `rsync -a` fails on `tank` anyway; reflink is near-free and same-dataset |
| Backgrounding a long probe run | `tmux` / `screen` | `setsid` + `nohup` | Neither is installed on LXC 100 (Phase 1, 01-04) |
| Passing the Discogs token to a container | `-e DISCOGS_TOKEN=…` or a config file in git | `env_file: /mnt/fast/secrets/discogs.env` | 103 containers on a host with a readable process table; this is why D-04 used stdin in the first place |
| Deciding whether v0.20.0 renders the path format | Reading release notes | Reading `pathformat.go` at both tags **and** running `move -dry-run` at both | The release notes' migration table omits `Track.Position = -1` entirely, which is the actual defect |
| Proving nothing escaped to the library | Reasoning about mount declarations | `scripts/check-music-freeze.sh` (exits 1 on any failed assertion) | It enumerates *running* containers, not YAML |

**Key insight:** almost every instrument this phase needs was built in Phase 1 and is sitting
unused. The phase's real risk is not missing tooling — it is reaching for a new tool when the
proven one is already there.

---

## Common Pitfalls

### Pitfall 1 — `beet config` (and any bare `beet` invocation) is not read-only

**What goes wrong:** beets opens its *default* library, runs schema migrations against it and
writes `.bak` files. In Phase 1 this migrated a database from 36,864 → 57,344 bytes and left 11
root-owned `.bak` files in an `apps:apps` tree.
**Why:** `BEETSDIR=/config` in the LSIO image; with no `-l`, beets resolves `library.db` there.
**How to avoid:** **every** beets invocation in this phase passes an explicit throwaway
`-l /tmp/spike-<name>.blb` *and* an explicit `-c <spike config>`. Never rely on `BEETSDIR`.
**Warning sign:** a `.bak` file, or an unexpected mtime on any `library.db` under
`/mnt/fast/appdata/`.

### Pitfall 2 — LXC 100's root filesystem is at 99% and holds `/var/lib/docker`

**Measured 2026-09-01:**

```
/dev/mapper/pve-vm--100--disk--0  126G  117G  2.2G  99% /
Docker Root Dir: /var/lib/docker        (on /)
Images 110, 80.33GB, 61.87GB reclaimable (77%)   Containers 103   Local Volumes 18.92GB
```

Compressed amd64 layer totals for the three images the spike needs:
`lscr.io/linuxserver/beets:2.13.1-ls349` **234 MB**, `metasauce/beets-flask:v2.0.0-rc6` **374 MB**,
`sentriz/wrtag:v0.34.0` **85 MB** — ≈693 MB compressed, typically **2.0–2.3 GB on disk**.

**A `docker pull` will fail or fill the root filesystem to zero.** Filling `/` on this host takes
down 103 containers.

**How to avoid:** a Wave-0 task that reclaims headroom *before any pull*, verifies with `df -h /`,
and states a floor (recommend ≥ 8 GB free). `docker system df` reports 61.87 GB reclaimable across
29 unused images. `docker image prune -a` is a **mutation** and therefore a planned task with an
explicit inventory step first (`docker images` diffed against `docker ps -a --format '{{.Image}}'`),
not a blind sweep — the estate has a documented `created`-state blind spot where containers exist
but never ran, and their images must not be reaped.
**Warning sign:** `no space left on device` from `docker pull`, or `df -h /` under 1 GB.

### Pitfall 3 — `find -xdev` silently skips every appdata dataset

`/mnt/fast/appdata/*` comprises 39 separate ZFS datasets. A `find /mnt/fast -xdev` exits 0 having
seen none of them. Phase 1 recorded this as one of its six unearned passes.
**How to avoid:** never `-xdev` under `/mnt/fast`. Enumerate by explicit path.

### Pitfall 4 — Discogs rate-limit exhaustion is invisible

`backoff_enabled = True`, `MAX_ATTEMPTS = 100`, `2**i` seconds jittered. A 429-saturated run does
not fail — it sleeps, for potentially hours, while looking healthy.
**How to avoid:** count `429`s explicitly; set a wall-clock ceiling on the probe run and abort past
it; never run the criterion-1 and criterion-2 probes concurrently against the same 60 req/min
budget.

### Pitfall 5 — an `import.move: yes` config reaching a real path

The estate's beets configs currently set `import.move: yes`, which *moves* files out of the source.
A spike config that inherits it and is pointed at a real path destroys the source.
**How to avoid:** the spike config sets `import.copy: yes` / `import.move: no` explicitly, and the
probe script never calls the import pipeline at all — `tag_album()` reads and returns; it does not
write, does not touch the library database, and does not move files. Assert with a before/after
`find -newer` on the scratch tree after every probe run.

### Pitfall 6 — the beets-flask trial acquiring a rw mount on Music

D-20 is unambiguous: **nothing holds rw on `/mnt/tank/media/Music` during Phases 1–3.** The
beets-flask compose above deliberately does not mount Music at all. If the trial needs library
context for match scoring, mount `:ro` and say so in the plan.
**How to avoid:** run `scripts/check-music-freeze.sh` (a) after the beets-flask container is
created and (b) at phase close. It exits 1 on any failed assertion and enumerates *running*
containers, not YAML.

### Pitfall 7 — an acceptance criterion written as a literal-string grep over a self-documenting file

Hit twice in Phase 1 (01-05 and 01-07): a comment explaining that a value was changed contained the
literal string the grep was searching for, producing a false failure.
**How to avoid:** acceptance criteria on this phase's artefacts should assert on parsed structure
(`jq` over the NDJSON, `beet config -d` inside the container) rather than `grep`ping prose.

### Pitfall 8 — reasoning about `uid:gid` from LXC 100's view

The sparse idmap collapses distinct on-disk owners. `uid 3000` owns 94.6% of `tank/downloads`.
Anything ownership-related must be checked from atlantis and must **say which view it came from**.
For this phase it is mostly moot — everything on `tank` is `0777` — but the beets-flask
`USER_ID`/`GROUP_ID` and `EXTRA_GROUPS` settings are where it would bite.

---

## Code Examples

### Verifying the pin inversion without a container (static arm)

```bash
# Source: github.com/sentriz/wrtag at the two tags
for T in v0.20.0 v0.34.0; do
  echo "=== $T ==="
  curl -sL "https://raw.githubusercontent.com/sentriz/wrtag/$T/pathformat/pathformat.go" \
    | sed -n '/^type Data struct/,/^}/p'
  curl -sL "https://raw.githubusercontent.com/sentriz/wrtag/$T/pathformat/pathformat.go" \
    | grep -n "Track.Position = -1" || echo "(no forced -1)"
done
```

### Confirming the Discogs plugin is loaded and reachable, without importing anything

```bash
# Source: 01-07's container-side read-back pattern. Note the explicit -c AND -l.
docker exec beets-spike \
  beet -c /config/spike.yaml -l /tmp/spike-probe.blb config -d | head -40
# A `discogs:` block with `search_limit: 5` proves the plugin is loaded.
# Per 01-07: `beet config -d` only prints a plugin's defaults when that plugin is LOADED —
# absence of the block is a loading failure, not a safe default.
```

### The rate-limit second instrument

```bash
# Count what actually left the process, independently of beets' own accounting.
docker exec -e PYTHONUNBUFFERED=1 beets-spike \
  python3 /config/probe.py "$SCRATCH/normalised"/* \
  1> /mnt/fast/<scratch>/candidates.ndjson \
  2> /mnt/fast/<scratch>/probe.stderr
grep -c 'api\.discogs\.com'      /mnt/fast/<scratch>/probe.stderr   # total requests
grep -c '"GET .* 429'            /mnt/fast/<scratch>/probe.stderr   # rate-limit hits — must be 0
jq -s 'group_by(.folder) | length' /mnt/fast/<scratch>/candidates.ndjson  # folders covered
```

### Scoring D-05 strictly from the NDJSON

```bash
# loose: a Discogs candidate appeared at all
jq -s '[ .[] | select(.source=="Discogs") ] | group_by(.folder) | length' candidates.ndjson
# strict: Discogs candidate AND track count agrees AND no unmatched files/tracks
jq -s '[ .[] | select(.source=="Discogs" and .n_tracks==.n_files
                      and .extra_items==0 and .extra_tracks==0) ]
       | group_by(.folder) | length' candidates.ndjson
```

---

## State of the Art

| Old (as recorded in PROJECT.md / CONTEXT.md) | Current | Changed | Impact |
|---|---|---|---|
| wrtag latest is v0.33.0 (11 Jul 2026) | **v0.34.0 (26 Aug 2026)** | 2026-08-26 | D-01 amendment; no path-format change |
| beets-flask lives at `pSpitzner/beets-flask` | **`metasauce/beets-flask`** | Aug 2026 (rc6) | Old Docker Hub repo stops at rc5 |
| beets-flask stable is 1.x | **2.0 in RC since 2025-12-29**; last stable v1.2.1 | ongoing | Trial an RC and record it as a risk |
| Discogs plugin needs `pip install "beets[discogs]"` | **`python3-discogs-client` is pre-installed in the LSIO image**; the pip step is only needed inside beets-flask | — | Removes a whole task from the plan |
| beets-flask container base is Alpine | **`python:3.12-slim-trixie`** since rc4 | 2026-03-17 | The docs' `apk` examples are stale |
| `beet import --pretend` can be used to check for a candidate | **It cannot** — `--pretend` bypasses `lookup_candidates` | always true; newly verified | Phase 4 criterion 4 needs rewording |
| The backlog is "7,451 files across ~1,000 folders" | **7,451 files across 120 folders** (143 deduplicated) | measured 2026-09-01 | Criterion 2's extrapolation shrinks ~8× |
| `dj-mixes` has 84 folders incl. a 45 GB `1-115` set | **60 audio-bearing folders, 25 GB; 24 empty shells incl. `1-115`** | measured 2026-09-01 | Changes the D-06 sampling pool |
| DJ folders have swapped `artist`/`album` | **They do not.** `album` is largely correct; `artist` is a placeholder; 107 files have no `album` | measured 2026-09-01 | Changes what D-08's script does |

**Deprecated / superseded:**
- `beets[discogs]` as an LSIO install step — unnecessary.
- The `renovate.json5:91` field list (`.Release.Date.Year`, `.Release.Media`, `.Track.Position`,
  `artistsString`) — three of the four are innocent. Phase 4 owns rewriting it.

---

## Environment Availability

Probed live 2026-09-01 on LXC 100 (`172.16.1.159`) and atlantis (`172.16.1.158`).

| Dependency | Required by | Available | Version / value | Fallback |
|---|---|---|---|---|
| `docker` | all three containers | ✓ | 103 containers, 110 images | — |
| **Disk headroom on `/`** | image pulls | **✗ — 2.2 GB free of 126 GB (99%)** | needs ≈2.0–2.3 GB | **None. Blocking — reclaim first** |
| `python3` | probe script, normalisation script | ✓ | `/usr/bin/python3` | — |
| `ffprobe` | independent tag reader | ✓ | `/usr/bin/ffprobe` | — |
| `jq` | NDJSON scoring | ✓ | `/usr/bin/jq` | — |
| `git` | script delivery to LXC 100 | ✓ | LXC at `90cdddc`, workstation at `5199db3` | — |
| `curl` | Discogs identity check | ✓ | — | — |
| `cp --reflink` within `tank/downloads` | D-07 | ✓ | `feature@block_cloning active` on `tank` | none needed |
| `zfs` on LXC 100 | scratch snapshot | ✗ (unprivileged, by design) | — | **`ssh root@172.16.1.158`** |
| `rsync` | — | ✗ | not installed | `cp --reflink` |
| `tmux` / `screen` | long-running probe | ✗ | neither installed | **`setsid` + `nohup`** (Phase 1 pattern) |
| `chmod` / `chown` on `tank` from LXC 100 | — | ✗ EPERM (two different causes) | — | atlantis, or don't — everything is `0777` |
| `/mnt/fast/secrets/discogs.env` | Discogs auth | ✓ | `-rw------- root root 225 Aug 18 23:19` | — |
| Free space on `tank` | scratch copies | ✓ | **9.00 T avail**; `dj-mixes` is 25 G total | — |
| `sentriz/wrtag:v0.20.0` image | criterion 3 "before" arm | ✓ **already pulled** | 172 MB | — |
| `redis:7-alpine` | beets-flask (if external redis wanted) | ✓ already present | 39.1 MB | rc-series bundles redis internally |
| `lscr.io/linuxserver/beets:*` | axis one | ✗ not pulled | — | pull `2.13.1-ls349` after Pitfall 2 is cleared |
| `metasauce/beets-flask:v2.0.0-rc6` | axis two | ✗ not pulled | — | ditto |
| beets container / soulbeet container | — | ✗ **neither exists** (`docker ps -a`) | — | The spike creates its own throwaway; nothing to stop |

**Missing with no fallback (blocking):**
- **Disk headroom on LXC 100's root filesystem.** Must be the first task in the phase.

**Missing with fallback (non-blocking):** `zfs` (delegate to atlantis), `rsync` (use reflink),
`tmux`/`screen` (use `setsid`+`nohup`).

---

## Validation Architecture

### Test framework

There is no unit-test framework in this repository and this phase should not introduce one — the
"tests" here are measurement runs against a live estate. The validation instrument is
**paired-instrument agreement**, enforced by the Phase 1 harness plus a per-measurement
cross-check, exactly per `beets.md`'s six-false-passes rule.

| Property | Value |
|---|---|
| Framework | Shell + Python assertions against live state. **No pytest/jest; none exists and none is warranted** |
| Config file | none — see Wave 0 |
| Quick run command | `bash scripts/check-music-freeze.sh` (exits 1 on any failed assertion; read-only by contract) |
| Full suite command | `bash scripts/check-music-freeze.sh && bash scripts/quick-health-check.sh` |

### Phase requirements → validation map

| Req | Behaviour to validate | Type | Command | Exists? |
|---|---|---|---|---|
| TAGR-01 | Discogs strict + loose rates recorded over the D-06 sample, with `index_tracks` setting stated | measurement + cross-check | `jq -s` over `candidates.ndjson` **vs** hand-transcribed `beet import -t` on 3 folders | ❌ Wave 0 (probe script) |
| TAGR-01 | Request count and timing extrapolated to 143 folders | measurement + cross-check | wall-clock `time` **vs** `grep -c 'api\.discogs\.com'` on the probe stderr | ❌ Wave 0 |
| TAGR-01 | Zero `429` observed during the timed run | assertion | `grep -c '429' probe.stderr` → must be `0` | ❌ Wave 0 |
| TAGR-01 | The normalisation changed **only** `album` and `artist` | regression | `scripts/snapshot-music-tags.sh` + `scripts/diff-music-tags.sh` over `$SCRATCH/normalised` | ✅ exists (01-03) |
| TAGR-02 | wrtag path format renders at v0.20.0 vs v0.34.0, single-disc **and** multi-disc | measurement + cross-check | `wrtag move -dry-run` output **vs** the `Data`-struct source diff | ❌ Wave 0 (throwaway compose) |
| TAGR-02 | The dry run wrote nothing | assertion | `find "$SCRATCH" -newer "$STAMP" -type f` → empty, both mounts, both arms | ❌ Wave 0 |
| TAGR-02 | The decision names one tagger and states the DJ-content answer concretely | doc review | decision record contains a named tool + a named mechanism per § *Criterion 4* | n/a |
| TAGR-06 | Both front ends scored on the same 5 albums with alternating order | measurement | the scoring sheet, 10 rows, no blanks | ❌ Wave 0 (sheet template) |
| TAGR-06 | beets-flask evaluated by name with its frictions recorded | doc review | § *Criterion 7* table reproduced in the decision record with the trial's own observations added | n/a |
| **all** | Nothing escaped to the library | **safety gate** | `bash scripts/check-music-freeze.sh` → exit 0, `tagger-class writers: 0`, `declared rw reaching Music: 0` | ✅ exists |
| **all** | The library is byte-identical to the Phase 1 baseline | **safety gate** | ownership/mode counts still `2,543 / 87 / 2,586`; `zfs diff tank/media/Music@pre-project` clean, run from atlantis | ✅ exists |

### Sampling rate

- **Per task commit:** `bash scripts/check-music-freeze.sh` — cheap, read-only, exits 1 on any
  failed assertion.
- **Per wave merge:** the freeze check **plus** `zfs diff tank/media/Music@pre-project` from
  atlantis, **plus** `find "$SCRATCH" -newer "$STAMP"` on any tree a tool touched.
- **Phase gate:** freeze check green; scratch tree deleted and its removal confirmed; both
  spike containers removed and confirmed absent from `docker ps -a`; the three pulled images
  either retained deliberately (with a stated reason) or pruned, and `df -h /` recorded.

### The paired-instrument rule, made concrete

Every number this spike produces gets **two independent readings before it is written down**:

| Number | Instrument A | Instrument B (independent) |
|---|---|---|
| Discogs loose/strict rate | `tag_album()` probe NDJSON | `beet import -t` transcript on 3 stratified folders |
| Requests per folder | derived from source (search + `search_limit` + masters) | `grep -c 'api.discogs.com'` on the probe's own stderr |
| Wall-clock per folder | `time` around the probe | per-folder timestamps in the NDJSON |
| wrtag v0.20.0 rendering | `move -dry-run` stdout | `pathformat.go` `Data` struct + the `= -1` line at both tags |
| Normalisation field loss | `diff-music-tags.sh` | `ffprobe` spot check on 5 files |
| Nothing written to Music | `check-music-freeze.sh` | `zfs diff` from atlantis |
| Nothing written to scratch by a dry run | `find -newer` | before/after `sha256sum` on 5 files |
| Sample population size | `ls`/`find` on the live tree | the Phase 1 ffprobe fence folder set |

**If A and B disagree, neither number is recorded** until the disagreement is explained. That is
the whole lesson of Phase 1's six unearned passes, and this phase's entire output is numbers.

### Wave 0 gaps

- [ ] **Docker disk headroom on LXC 100** — blocking; nothing else can start (Pitfall 2)
- [ ] `scripts/` probe script (`tag_album()` NDJSON emitter) — smoke-tested on one known-good album
      *before* it is trusted on the sample
- [ ] `scripts/normalise-dj-tags.py` with `--dry-run` as the default
- [ ] Formal variant survey artefact (folder → stratum) derived from the existing ffprobe fence
- [ ] Throwaway compose files for the beets spike and the beets-flask spike, at a scratch path
- [ ] The ergonomics scoring-sheet template (CSV or markdown table), committed before the trial
- [ ] The three pre-committed thresholds (T1/T2/T3) written into the plan **before** evidence
      collection — criterion 5 fails otherwise

---

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: high`.

### Applicable ASVS categories

| ASVS category | Applies | Standard control here |
|---|---|---|
| V2 Authentication | **yes** | Discogs personal access token; beets-flask has **no built-in auth**. The trial must not be exposed via Traefik — bind `127.0.0.1:5002` or reach it over Tailscale only. The frozen `beets.yaml`/`wrtag.yaml` carry `chain-authelia@file`; the throwaway spike carries **no Traefik labels at all** |
| V3 Session Management | no | No sessions created by this phase |
| V4 Access Control | **yes** | D-20: nothing holds rw on `/mnt/tank/media/Music`. Enforced at the mount layer, verified by `check-music-freeze.sh` on *running* containers |
| V5 Input Validation | limited | The normalisation script derives `album` from folder names — **path-derived data written into file metadata**. Sanitise: no path separators, bounded length, reject control characters |
| V6 Cryptography | no | No crypto implemented. `audio_md5` is an integrity join key, not a security control |
| V7 Error Handling & Logging | **yes** | Probe stderr will contain full HTTP request lines. **The Discogs token travels in the `Authorization` header**, and `urllib3` DEBUG does not log headers by default — but `requests`/`http.client` debug at level 1+ **does**. Use `urllib3.connectionpool` at DEBUG only; never `http.client.HTTPConnection.debuglevel = 1`. Screen `probe.stderr` before any of it is quoted into a summary or committed |
| V14 Configuration | **yes** | Pinned image digests/tags, `no-new-privileges:true`, `restart: "no"`, `profiles: ["manual"]`, no `privileged`, no `no_root_squash` |

### Known threat patterns for this stack

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Token leaking into the process table on a 103-container host | Information disclosure | `env_file:` only; never `-e`, never a CLI argument. This is *why* D-04 used stdin |
| Token leaking into git | Information disclosure | Secret lives at `/mnt/fast/secrets/discogs.env` outside the repo; `beets.yaml`-style configs get the 7-class credential screen from 01-07 before any commit; repo is **public** |
| Token leaking into a log or a phase summary | Information disclosure | `urllib3.connectionpool` DEBUG only; screen `probe.stderr` before quoting; `grep -c` for the token's own prefix on any artefact before it is committed |
| Token still live after project close | Information disclosure | D-04: **rotate on Discogs at project end** — it passed through a conversation transcript |
| A spike container acquiring rw on the library | Tampering | Explicit `:ro` or no mount; `check-music-freeze.sh` after container creation *and* at phase close |
| beets-flask exposed unauthenticated | Elevation of privilege | No Traefik labels; bind loopback; it has a **web terminal** with shell access to the container |
| A dry run that is not dry | Tampering | Verified in source (`op.CanModifyDest()` gates `tags.WriteTags`), **and** asserted with `find -newer` on every run |
| `docker image prune -a` reaping a `created`-state container's image | Denial of service | The estate has a documented `created`-state blind spot (dispatcharr + teleport were down 6 weeks). Inventory `docker ps -a --format '{{.Image}}'` — **not** `docker ps` — before pruning |
| Filling `/` on LXC 100 | Denial of service | 103 containers depend on it. Headroom floor asserted before any pull |
| Path-derived metadata written into audio files | Tampering | Sanitise folder-derived `album` values |

**No high-severity finding blocks this phase**, provided the disk-headroom task precedes the pulls
and the beets-flask trial is not published through Traefik.

---

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | The `tag_album()` probe's plugin-loading incantation (`plugins.load_plugins` + `find_plugins`) is sufficient in the LSIO container | Criterion 1 instrument | Probe returns MusicBrainz-only candidates and silently under-reports the Discogs rate. **Mitigation: the Wave-0 smoke test on a known-good album is a hard gate — if it does not return a Discogs candidate, stop** |
| A2 | Uncompressed on-disk image size is ~2–2.5× the compressed layer total | Pitfall 2 | The headroom floor is wrong. Mitigation: the task asserts `df -h /` **after** each pull, not before |
| A3 | `metadata write`'s flag-`0` `WriteTags` genuinely merges rather than replacing (read from `tags/tags.go` → `go.senan.xyz/taglib`, not confirmed at the taglib layer) | D-12 row 3b | `metadata` silently drops `TKEY`/`EnergyLevel`. Mitigation: D-13's bake-off scores this with `diff-music-tags.sh`, which would catch it |
| A4 | beets-flask rc6 bundles Redis internally and needs no sidecar (inferred from the absence of a redis service in the published compose + `rq` as a direct dependency) | Criterion 7 | The trial container fails to start. Cheap to discover; `redis:7-alpine` is already on the host |
| A5 | The 3–4 DMC folders in `unsorted` are structurally comparable to `dj-mixes` folders (flat, audio at top level) | Sample selection | The added stratum is not comparable. Mitigation: verify shape before drawing |
| A6 | Discogs' authenticated ceiling is still 60 req/min | Criterion 2 | The extrapolation is wrong by a constant factor. Last verified live 2026-08-19 (D-04). **Re-verify with one `GET /oauth/identity` at the start of the timing run and read `x-discogs-ratelimit`** |
| A7 | `search_limit: 5` will be left at its default in the spike config | Criterion 2 | Request count scales linearly with it. Mitigation: the spike config sets it explicitly and the decision record states the value |
| A8 | The 24 empty `dj-mixes` folders are genuinely abandoned rather than pending, and can be excluded | Finding 5 | The sample pool is smaller than it should be. All 24 are 0 files / 512 B, dated Oct 2025 – Jan 2026 |
| A9 | Discogs actually carries the sampled Mastermix issues (PROJECT.md asserts 430/433 and DMC 350 from a prior live query) | Criterion 1 | The whole strict/loose result. **Deliberately not re-verified here** — it burns rate-limit budget and it is precisely what the spike measures |

---

## Open Questions

1. **D-01 says wrtag v0.33.0; v0.34.0 shipped 26 Aug 2026.**
   - Known: v0.34.0 changes nothing in `pathformat`; its only breaking change is the Go toolchain.
   - Unclear: whether D-01's number is a deliberate pin or simply the latest at the time of writing.
   - Recommendation: **test at v0.34.0**, record the v0.33→v0.34 changelog as a path-format no-op,
     and flag the substitution for operator approval at plan sign-off.

2. **D-06 stratifies over `dj-mixes`, which contains no DMC content — but criterion 4 names DMC.**
   - Known: all DMC folders live in `unsorted` only; `dj-mixes` is a Mastermix-only duplicate subset.
   - Unclear: whether the operator wants the ~40% threshold bound to Mastermix alone.
   - Recommendation: keep D-06's population and threshold **exactly as decided**, and add DMC as a
     **separately reported** stratum. Present as a scope question; do not merge unilaterally.

3. **D-08's stated defect ("`artist`/`album` swapped") is not present in the data.**
   - Known: measured over all 764 files; `album` is largely correct, `artist` is a placeholder,
     107 files have no `album` at all.
   - Unclear: nothing technical. This is a documentation correction that needs acknowledging.
   - Recommendation: keep D-08's *constraint* (minimum viable, dry-run, committed, not DJCC-01) and
     replace its *example* with the three measured rules in § *The normalisation script*.

4. **Does Discogs' `index_tracks` treatment change the track count for these releases?**
   - Known: `index_tracks` defaults to `no`; the plugin has `_coalesce_index_track` and
     `_merge_subtracks`; Mastermix/DMC releases commonly use headings.
   - Unclear: by how much, on this content.
   - Recommendation: **run the strict scoring at both settings** and state which produced the
     headline number. Cannot be settled without running the spike.

5. **Are the 134 WAV files tractable for either tool?**
   - Known: `tags.CanRead` includes `.wav`; mutagen's WAV/ID3 support is weaker than its FLAC/MP3
     support; 17.5% of the DJ corpus is WAV.
   - Unclear: whether a WAV-heavy stratum systematically under-performs.
   - Recommendation: record format per sampled folder; if a stratum is WAV-dominant, report its rate
     separately. Cannot be settled without running the spike.

6. **Does beets-flask's "laggy past some hundred folders" limitation bite at 143?**
   - Known: the number is documented as approximate, with two open upstream issues (#164, #175).
   - Unclear: whether 143 is under or over the practical threshold.
   - Recommendation: **out of scope for the trial** (which is 5 albums). Record it as an axis-two
     risk in the decision record; it is a Phase 9 concern.

---

## Sources

### Primary (HIGH confidence)

- `github.com/sentriz/wrtag` — `pathformat/pathformat.go`, `musicbrainz/musicbrainz.go`, `wrtag.go`,
  `tags/tags.go`, `cmd/metadata/main.go`, `cmd/wrtag/main.go`, `cmd/internal/wrtaglog/wrtaglog.go`,
  `Dockerfile`, `go.mod` — read at tags **v0.20.0** and **v0.34.0**
- `github.com/sentriz/wrtag/releases` — v0.19.0 … v0.34.0 release bodies (v0.30.0's migration table
  quoted verbatim in finding 1)
- `github.com/sentriz/wrtag/blob/master/README.md` — `metadata` usage, `wrtagweb` API, addons,
  `keep` rules, "the Docker image … has the `wrtag` tools included too"
- `github.com/beetbox/beets` at **v2.13.1** — `beetsplug/discogs/__init__.py`,
  `beets/metadata_plugins.py`, `beets/autotag/match.py`, `beets/autotag/distance.py`,
  `beets/importer/session.py`, `beets/config_default.yaml`, `docs/plugins/discogs.rst`,
  `docs/reference/cli.rst`, `docs/changelog.rst`
- `github.com/metasauce/beets-flask` at **v2.0.0-rc6** and `main` — `backend/pyproject.toml`,
  `docker/Dockerfile`, `docker/docker-compose.yaml`, `docs/{configuration,limitations,faq,
  getting-started,plugins}.md`, GitHub releases v1.2.0 … v2.0.0-rc6
- `github.com/linuxserver/docker-beets` — `Dockerfile` at tag **2.13.1-ls349**
- `github.com/joalla/discogs_client` — `client.py`, `fetchers.py`, `utils.py` (backoff)
- Docker Hub tag APIs: `linuxserver/beets`, `sentriz/wrtag`, `pspitzner/beets-flask`,
  `metasauce/beets-flask`; GHCR tag list for `metasauce/beets-flask`
- `pypi.org/pypi/{beets,mutagen,python3-discogs-client}/json`
- **Live estate, read-only, 2026-09-01** — `ssh root@172.16.1.159` (`docker info`,
  `docker system df`, `docker images`, `docker ps -a`, `df -h`, `find`, `stat`, `ffprobe`,
  and a Python pass over `/mnt/fast/safety/music-pre-project/dj-mixes-ffprobe/`);
  `ssh root@172.16.1.158` (`zfs list`, `zfs get acltype,aclmode,aclinherit`,
  `zpool get feature@block_cloning`)
- **This repo** — `stacks/selfhosted/music/wrtag.yaml:71,73`,
  `stacks/selfhosted/arrs/beets/beets.yaml`, `renovate.json5:91`,
  `stacks/selfhosted/arrs/beets.md`, `.planning/phases/01-*/01-{02,04,07}-SUMMARY.md`,
  `.planning/{ROADMAP,REQUIREMENTS,PROJECT,STATE}.md`, `CLAUDE.md`

### Secondary (MEDIUM confidence)

- `slopcheck install beets mutagen python3-discogs-client` — 3 OK, run 2026-09-01
- Docker registry manifest sizes (compressed amd64 layer totals) — accurate as compressed sizes;
  the ~2–2.5× on-disk multiplier is an estimate (A2)

### Tertiary (LOW confidence)

- None. Every claim in this document is either read from a primary source, measured on the live
  estate, or explicitly listed in the Assumptions Log.

**Deliberately not consulted:** the live Discogs API. Verifying coverage of specific Mastermix/DMC
issues now would burn the 60 req/min budget the spike depends on and would pre-empt the very number
the phase exists to produce (A9).

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|---|---|---|
| Container tags and versions | **HIGH** | Read from Docker Hub / GHCR / PyPI APIs on the research date; every pin exists |
| wrtag path-format forensics | **HIGH** | Read from tagged Go source at both versions; the `= -1` line and the `Data` struct diff are unambiguous |
| `metadata` tool capability | **HIGH** | Read from `cmd/metadata/main.go` at v0.34.0; flag set enumerated from the source, not the README |
| beets Discogs request arithmetic | **HIGH** on structure, **MEDIUM** on the number | Call graph read from source; the actual per-folder count depends on how many results the API returns and must be measured |
| beets-flask architecture and frictions | **HIGH** | Official docs at `main` plus `pyproject.toml`/`Dockerfile` at rc6; every D-11 friction re-verified plus four new ones |
| DJ corpus tag variants | **HIGH** | Full census of all 764 files in Phase 1's own fence, not a sample |
| Sample population and backlog counts | **HIGH** | Measured on the live filesystem with two agreeing methods (`ls`/`find` and the fence's folder set) |
| Disk-headroom blocker | **HIGH** | `df -h` and `docker system df` on the live host |
| Discogs *coverage* of this content | **LOW — deliberately** | This is the spike's output, not its input. Any number here would be advocacy |
| The `tag_album()` probe running as sketched | **MEDIUM** | The API shape is verified from source; the plugin-bootstrap lines are the weak point and are gated behind a Wave-0 smoke test (A1) |

**Research date:** 2026-09-01
**Valid until:** 2026-10-01 for the source-level and structural findings. **7 days** for the
container tags — `linuxserver/beets` publishes a new `-lsNNN` weekly (ls344 → ls349 in five weeks),
and `metasauce/beets-flask` is mid-RC. Re-check both tags immediately before the plan pins them.
