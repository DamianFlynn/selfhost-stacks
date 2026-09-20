# Phase 6: Tagger Configuration and Dry Run - Research

**Researched:** 2026-09-20
**Domain:** beets 2.12.0/2.13.1 configuration semantics; beets-flask v2.0.0-rc6 internals; ID3/Vorbis/RIFF tag field mapping; Jellyfin 10.11.11 and Music Assistant 2.10/2.11 artist parsing
**Confidence:** HIGH on everything read from pinned upstream source or measured on the live estate; MEDIUM on two named open questions (OQ-1, OQ-2)

> **Reading rule for this document.** Every claim carries one of:
> `[SOURCE: <file>@<tag>:<line>]` — read from pinned upstream source at the exact version this estate runs.
> `[MEASURED: <date> <how>]` — a command was run and its output observed.
> `[CITED: <url>]` — read from a published spec/doc.
> `[ASSUMED]` — training knowledge, not verified in this session. Treat as needing confirmation.
> `NOT VERIFIED` — stated because it matters, explicitly not established here.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `.planning/phases/06-tagger-configuration-and-dry-run/06-CONTEXT.md` § Implementation Decisions. **D-01 … D-32 are locked. Nothing below re-litigates them.** Where research contradicts one, the contradiction is reported as a finding (§ *Contradictions With Locked Decisions*) and the decision is left standing for the operator.

**beets-flask: scope, version and topology**

- **D-01: beets-flask is stood up in this phase.** This honours Phase 5's D-16 and ends a defer chain that has now run Phase 4 → 5 → 6. The ROADMAP's six criteria do not mention it; that is a gap in the criteria, not evidence it belongs elsewhere. Phase 3 chose it as the front end on the operator's own T3 self-assessment, and a config proven against a runtime that will not execute it proves the wrong thing.

- **D-02: Accept beets 2.12.0 under flask as the executing runtime, as a dated pin with a named revisit trigger.** Newest beets-flask release is still `v2.0.0-rc6`, published 2026-08-30. rc6's `backend/pyproject.toml` pins `beets==2.12.0`. `main` is worse, not better: stale 1.x line, last commit 2025-12-29, pinning `beets==2.5.1`. Upstream has live `beets_2_13` and `beets_2_14` branches; repo pushed 2026-09-17, 65 open issues, not archived. **Revisit trigger:** an rc7 (or any release) on beets ≥ 2.13, or the `beets_2_13` branch merging. Building our own image on 2.13.1 was considered and **rejected**.

- **D-03: One vendored beets config, one `library.db`, mounted into BOTH containers.** Single config and single database at `/mnt/fast/appdata/arrs/beets/config/`. Keeps Phase 4's D-28 true and makes "effective config" in criteria 1, 2 and 5 unambiguous. Forces the config to be valid under **both** rc6's stricter JSON schema and beets 2.13.1 — which is what forces D-10's `plugins:` list form.

- **D-04: The 2.13.1 survivor always passes an explicit throwaway `-l`, made structural and asserted.** With one database mounted into two beets versions, 2.13.1 opening it would migrate the schema under 2.12.0's feet. **Only flask's 2.12.0 ever opens the real `library.db`.** The existing D-16 discipline becomes an assertion in `scripts/quick-health-check.sh`. *Accepted consequence:* the CLI arm reads a throwaway, so it cannot answer "what is in the library" — flask's UI does that.

- **D-05: `/mnt/tank/media` stays `:ro` for the entire phase, for both containers.** `beets.yaml:69`'s "Phase 6 grants it rw" comment **is wrong and must be corrected**. A read-only mount cannot fail open. Granting `rw` becomes **Phase 7's first act**.

- **D-06: Three inboxes registered; `04-hold`, `99-quarantine` and `_done` are NOT registered.** `01-auto` → `auto`, `02-review` → `preview`, `03-asis` → `bootleg`.

- **D-07: flask is reached at `beets.deercrest.info` via Traefik + `chain-authelia@file` on `t3_proxy`, with NO host port.** **The dormant survivor's traefik labels are removed.** **Needs a Cloudflare CNAME** — no wildcard exists for `deercrest.info`, and a Traefik certificate is not evidence that DNS resolves.

- **D-08: The folder-count lag risk is NOT tested here.** Carried to Phase 9. Phase 3's friction 5 stays `NOT EXERCISED`.

- **D-09: Inbox liveness is proven BOTH ways.** (1) Assert **all three** inboxes appear in the startup log; fail closed on fewer than three. (2) **Drive one throwaway folder** through `02-review`, confirm a preview is generated, then remove it. > **This AMENDS Phase 5's D-17.**

- **D-10: `plugins:` must be written as a YAML list, not beets' canonical space-separated string.** `config.yaml:60` is currently `plugins: musicbrainz` — the string form, which rc6 **rejects**.

- **D-11: `check-music-freeze.sh`'s `tagger definitions: 1` expectation is revised to 2, both named and classed.** Expect exactly two and assert them **by name** — the flask front end and the dormant 2.13.1 CLI arm — each printed on its own line with its class.

- **D-12: The dormant 2.13.1 survivor's purpose is stated: the agent-driven CLI arm.** Stays `restart: "no"`, `profiles: ["manual"]`, commented out of the include list, always throwaway `-l`, `/media:ro`. **Its purpose is written into `beets.yaml`'s header, and that comment is the guard.**

**Path formats**

- **D-13: DJ content goes to a top-level `DJ/` sibling** — e.g. `DJ/Mastermix/Issue 433/NN Title.ext` — via `--set albumtype=dj` + a `paths: albumtype:dj:` rule.
- **D-14: Multi-disc is flat and disc-prefixed — `2-05 Title.ext`, one directory per album.** `Disc N/` subdirectories were **rejected**. Track-only flat naming was also rejected.
- **D-15: The `comp:` path rule is explicitly overridden to resolve to `$albumartist`.** **Override, do not delete.** Hard-coding a literal `Various Artists/` was rejected.
- **D-16: `%aunique{}` is KEPT, and every folder where it fires is reported by the dry run.** Every `%aunique{}` firing is a known MA risk to verify in Phase 7.
- **D-17: DJ content IS visible in Music Assistant — no narrowing of MA's provider path.**
- **D-18: A NAMED protected DJ-field list goes in the config, and the dry run REPORTS any proposed change to any of them.** Fields: `bpm`/`TBPM`, `initialkey`/`TKEY`, `EnergyLevel`, `genre`, `comment`. **Needs research:** the exact field-name mapping per container format (ID3 vs FLAC vs WAV).
- **D-19: Phase 6 preserves DJ fields only — it generates nothing.**
- **D-19a: The path format is made structurally incapable of producing album-folder == artist-folder, AND the existing defect is scheduled for repair in Phase 7.**
- **D-19b: Singletons get their own path rule, and the dry run FLAGS any folder that resolved to them.**

**Criterion 4 — the consumer proof**

- **D-20: Search the existing library FIRST, exhaustively.** All 1,244 files and every delimiter form **before** the fallback is invoked at all.
- **D-21: Pre-authorised fallback — a fenced test file with a scoped `rw` grant.** ZFS snapshot → grant `rw` → single write → observe → roll back → revoke `rw`.
- **D-22: "Parsed correctly" means N distinct browseable artist entities in EACH consumer, checked separately.**
- **D-23: `;` is configured on the WRITE side too, and shown in the dry run.** *Constrains the sample draw: it must include a multi-artist release.*
- **D-24: Jellyfin sees the file via a targeted scan — NEVER `FullRefresh`.** **The distinction must be written into the plan, because the two buttons sit next to each other and only one is safe.**
- **D-25: Jellyfin is proven FIRST; Music Assistant LAST and only if needed.** MA never purges stale entries; a rolled-back fenced write leaves a phantom in MA forever.

**Dry-run sample and the oracle**

- **D-26: Deterministic, seeded draw, committed to git BEFORE any dry run.** Must include a multi-artist release, a multi-disc release, a compilation, and a *Now!* volume.
- **D-27: The oracle is BOTH a committed expected-tree diff AND class assertions.**
- **D-28: Criterion 5 proves `preferred.countries` as written — the embedded Discogs id is NOT used.**
- **D-29: "Wrote nothing" is asserted across all three layers.** (1) Library — structurally, by `:ro`. (2) Source — a before/after **checksum manifest**, not a count. (3) beets' own state — `library.db` byte-identical, and no `incremental` state recorded.
- **D-30: The dry run executes BOTH ways — `docker exec` for the oracle, `preview` as cross-check.** **If the two disagree, that disagreement is itself a finding worth having before Phase 7.**
- **D-31: Criterion 2's `incremental` trap is PROVEN with a negative control, not merely set.**
- **D-32: `tank/downloads@pre-phase5` is KEPT.** Its release moves to after Phase 7's pilot passes.

### Claude's Discretion

- Exact beets path-template syntax for D-13/D-14/D-15/D-19b.
- Which Jellyfin and MA API endpoints serve D-22's per-consumer artist-entity check, and MA's sync cycle timing.
- The exact `docker exec` invocation shape for D-30, and flask's appdata path layout.
- Whether rc6 exposes pagination/inbox-size knobs worth recording for Phase 9 (D-08 declined to measure, not to read).

### Deferred Ideas (OUT OF SCOPE)

- **BPM / key / energy generation for the ~616 `dj-mixes` files that have none** (D-19).
- **The `bootleg` album-populated gate** — Phase 7 routing-time concern.
- **The per-file `LOCATION=…/release/NNNNNN` Discogs id** as a bulk disambiguation shortcut (D-28). Phase 9.
- **beets-flask's folder-count lag** past ~100 folders (D-08). Phase 9.
- **Repairing `Def Leppard/Def Leppard (2015)/`** (D-19a). Phase 7.
- **`beet modify +=` / `-=` and the `edit` album-YAML header** — beets 2.13 features absent from rc6's 2.12.0 pin.
- **DUPE-01 / DUPE-02** — needs a roadmap decision **before Phase 7**.
- **`mac-music-archive/`'s 23,874 uncharacterised entries.**
- **The four Phase 5 OPEN items.**
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONF-01 | Imports copy rather than move, so a bad run is reversible | § *Effective config under flask* — `import.copy: yes` / `move: no` are beets 2.12/2.13 **defaults** AND rc6 **type-enforces** them (`Literal[True]`/`Literal[False]`); a `move: yes` config is rejected at validation, which per friction 9 kills the watchdog silently. F-01, F-06. |
| CONF-02 | `incremental: yes` with `incremental_skip_later: yes` | § *Incremental mechanics*. Both default `no`. State lives in a **pickle at `statefile:`, not in `library.db`** — `-l` does not redirect it. F-13, F-14. D-31's negative control design given in full. |
| CONF-03 | Path formats put `ALBUMARTIST` at the top level exactly, case included — `Various Artists/`, never `Compilations/` | § *Path formats*. `comp:` survives as a default key even when the user config defines `paths:` — proven from the `get_path_formats` docstring. Concrete stanza given. `$albumartist` for a VA release resolves to the `va_name` config value verbatim. F-08, F-09, F-10. |
| CONF-04 | `;` is the multi-artist delimiter, the one both consumers parse | § *Multi-artist, end to end*. **beets has no configurable write delimiter** (F-16). MA prefers the `ARTISTS` tag and splits on `;` only (F-18). Jellyfin ignores `ARTISTS` and does not split on `;` unless `UseCustomTagDelimiters` is on — **and it is off on the live Music library** (F-19, F-20). |
| CONF-05 | `preferred.countries` using `GB` not `UK`, `preferred.original_year`, `musicbrainz.extra_tags` | § *Match disambiguation*. Keys confirmed present in both versions' `config_default.yaml`; entries are regexes (`match.preferred.countries: []`). **`--pretend` cannot demonstrate any of it** (F-02). |
| CONF-06 | `beet import --pretend` on a sample of each bucket produces the intended tree | **F-02 is the headline finding: `--pretend` prints SOURCE paths only and never calls `lookup_candidates`.** The instrument must be `beet move -p` (or flask `preview`). |
</phase_requirements>

---

## Summary

Four things in this phase are not what the ROADMAP and CONTEXT assume, and each is established from pinned source or a live measurement rather than inference.

**First, `beet import --pretend` cannot produce the intended tree.** In beets 2.12.0 the pretend pipeline is exactly two stages — `read_tasks` → `log_files` — and `log_files` prints the *source* directory and the *source* file paths. `lookup_candidates` is not in the pipeline at all, so no MusicBrainz query runs, no match exists, and no destination path is ever computed. This is the same fact REQUIREMENTS.md already records against TAGR-05 ("It is not `--pretend`, which in beets v2.13.1 never calls `lookup_candidates`"), now confirmed at the exact version flask runs. The instrument that *does* evaluate the path templates and print `source -> destination` is **`beet move -p`**, which calls `item.destination()` per item. The phase needs `beet move -p` (against a throwaway library populated by a real, fenced, in-place import) plus flask's `preview` as D-30's cross-check.

**Second, beets-flask rc6 injects its own schema defaults into beets' config at the highest priority**, so "the effective config of the thing that actually runs" genuinely differs from `beet config -d` run in the same container. `commit_to_beets()` calls `beets.config.set(self.to_dict(extra_fields=True))`, and `to_dict` serialises the *whole* schema dataclass — defaults included. The consequences are concrete and dangerous: `import.duplicate_action` becomes **`remove`** (beets' own default is `ask`), `match.medium_rec_thresh` becomes `0.10` (beets: `0.25`), and an unset `directory:` becomes `/music/imported`. The vendored config must set each of these explicitly. Separately, rc6 will **write its own opinionated example config into `$BEETSDIR/config.yaml` if that file does not exist** — a config that turns on `embedart.auto: yes`, `lastgenre.auto: yes` with `force: yes`, and `scrub` — i.e. the exact three SAFE-01 switches this project spent Phase 1 turning off.

**Third, D-20's exhaustive search is already answered, offline, at zero risk — and D-21's fenced write is not needed.** Phase 1's `pre-project.ndjson.gz` snapshot covers all 1,244 library files. Twelve of them carry `;` in an artist-ish tag: six in `ARTIST` (all in `P!nk/TRUSTFALL (2023)`, including a three-artist track) and six in `ARTISTS` (P!nk, Lady Gaga, Katy Perry). Jellyfin today reports exactly the six `ARTIST` ones as multiple distinct artist entities and none of the six `ARTISTS` ones. **But Jellyfin's Music library has `UseCustomTagDelimiters=False` and `PreferNonstandardArtistsTag=False`, and 10.11.11's prober only splits on `;` when the former is true** — so the six correct entries are very likely stale database state from an older Jellyfin, and a targeted rescan could collapse them. That is OQ-1, and it changes criterion 4 from "observe" to "decide a Jellyfin library option".

**Fourth, D-23 is not satisfiable by beets configuration.** beets builds `item.artist` by concatenating MusicBrainz artist-credit *join phrases* (`" & "`, `" feat. "`, `""`) — measured in `_parse_artist_credits` at the v2.12.0 tag — and there is no config key anywhere in `config_default.yaml` that changes it. What beets *does* write is the per-artist list into `TXXX:ARTISTS` (MP3) / `ARTISTS` (Vorbis). Music Assistant reads that tag preferentially. Jellyfin reads it **only** when `PreferNonstandardArtistsTag` is enabled. So the real, achievable CONF-04 shape is not "`;` in ARTIST" — it is "beets writes `ARTISTS`; enable `PreferNonstandardArtistsTag` on the Jellyfin Music library so both consumers read the same field".

**Primary recommendation:** Build the vendored config around `beet move -p` as the oracle instrument, pin every key rc6's schema would otherwise default (`directory`, `import.duplicate_action`, `match.medium_rec_thresh`, `statefile`), assert the vendored config file is present *before* the container's first start so rc6 cannot install its own destructive example, run D-20's delimiter search offline against `pre-project.ndjson.gz` (answer: 12 candidate files, no `rw` grant needed), and take the CONF-04 question to the operator as a Jellyfin library-option decision rather than a beets one.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Path-format evaluation (CONF-03, D-13/14/15/19b) | beets library layer (`Item.destination()`) | — | Templates are evaluated by the library model, not the importer. Reachable without an import via `beet move -p`. |
| Match/candidate selection (CONF-05) | beets autotag + `musicbrainz` plugin | MusicBrainz WS/2 over the network | `lookup_candidates` is an importer stage; it is skipped entirely under `--pretend`. |
| Import policy per folder (D-06) | beets-flask inbox watchdog | beets importer | The `auto`/`preview`/`bootleg` policy is a beets-flask concept; beets sees only the resulting import invocation. |
| Effective-config resolution | beets-flask `commit_to_beets()` (server process) | confuse (`beet` CLI) | **These two disagree.** The server injects schema defaults at top priority; the CLI does not. D-30's two arms are measuring two different objects. |
| Library-state mutation (`library.db`, `state.pickle`) | beets `_open_library()` + `ImportState` | — | `_open_library` runs for **every** `beet` subcommand incl. `config`. `statefile` is a separate config key from `library`. |
| Tag write (what lands in the file) | beets `Item.write()` → `mediafile` → `mutagen` | — | Only fields in `Item._media_tag_fields` are written; unknown frames (e.g. `TXXX:EnergyLevel`) are preserved by mutagen's save. |
| Artist-entity parsing (D-22) | Jellyfin `AudioFileProber` (per-library options) / MA `helpers/tags.py` | ATL (Jellyfin) / mutagen (MA) | Both consumers parse independently and **do not agree by default**. |
| Targeted rescan (D-24) | Jellyfin `LibraryMonitor.ReportFileSystemChanged` | `POST /Library/Media/Updated` | Works with `EnableRealtimeMonitor` off; debounced by `LibraryMonitorDelay`. |

---

## Contradictions With Locked Decisions

Reported, not planned around. Each names the decision, the evidence, and the smallest change that would reconcile it.

| # | Decision | Evidence | Smallest reconciliation |
|---|----------|----------|-------------------------|
| C-1 | **D-27 / D-30 / CONF-06 / ROADMAP criterion 3 & 5** assume `beet import --pretend` output can be diffed against an expected *tree*. | F-02: the pretend pipeline is `read_tasks → log_files`; `log_files` prints `Album: <source dir>` then `  <source file>` for each item. `lookup_candidates` is not in the pipeline. `[SOURCE: beets/importer/session.py@v2.12.0:201-240]`, `[SOURCE: beets/importer/stages.py@v2.12.0:266-274]` | Keep `beet import --pretend` as the "which folders would be offered" instrument (it does prove `incremental`/`ignore`/grouping), and add **`beet move -p`** as the destination-path oracle. Both are read-only. |
| C-2 | **D-23** "`;` is configured on the WRITE side too". | F-16: `item.artist` is `"".join(artist_parts)` where the parts are MB names interleaved with MB `joinphrase` values. `[SOURCE: beetsplug/musicbrainz.py@v2.12.0:341-367]`. No delimiter/separator/join key exists in `config_default.yaml` at either version `[MEASURED: 2026-09-20 grep -i "sep\|delim\|join" over both config_default.yaml]`. | Reframe CONF-04's write side as **`ARTISTS` (TXXX / Vorbis), not `;` in ARTIST**, and make the consumer half a Jellyfin library-option decision (see C-3). |
| C-3 | **Criterion 4 / D-20 / D-22** assume the Jellyfin half is an observation. | F-19/F-20: Music library has `UseCustomTagDelimiters=False`, `PreferNonstandardArtistsTag=False` `[MEASURED: 2026-09-20 GET /Library/VirtualFolders]`; 10.11.11's prober splits on custom delimiters only when the former is true `[SOURCE: MediaBrowser.Providers/MediaInfo/AudioFileProber.cs@v10.11.11:227-246]`. Yet the DB shows 3 artists for `ARTIST=Marshmello;P!nk;Sting`. | Treat it as a **decision**: enable `PreferNonstandardArtistsTag` (aligns with what beets writes) and/or `UseCustomTagDelimiters` (aligns with what the 12 existing files carry). Both are Jellyfin library-option writes, outside the `/mnt/tank/media:ro` fence. See OQ-1. |
| C-4 | **D-07** "Needs a Cloudflare CNAME". | `beets.deercrest.info` **already resolves** to two Cloudflare proxied addresses, and a random `zzz-nonexistent-test.deercrest.info` does **not** — so it is a real record, not a wildcard. `[MEASURED: 2026-09-20 getent hosts from LXC 100]` | Downgrade from "create a CNAME" to "verify the existing record points at the right origin and that Traefik has a cert". |
| C-5 | **D-08** "Phase 6 registers three inboxes against a tree D-17 created empty … there is no population to lag at". | `02-review` already contains `Madonna/` and `Michael Jackson/` (mtime 2026-09-19 21:03); `99-quarantine` contains two `_FAILED_Garth.Brooks…` dirs. `[MEASURED: 2026-09-20 ls -la /mnt/tank/downloads/complete/nzb/_inbox/*]` | Either clear `02-review` before registering it, or record that registering `02-review` will immediately enqueue two real preview tasks against real content — which is a *live* action, not a paper one. |
| C-6 | **D-13** `--set albumtype=dj` as the DJ routing mechanism. | `--set` is a `beet import` CLI flag (`import.set_fields`). rc6's inbox schema (`InboxFolderSchema`) carries only `path`, `name`, `auto_threshold`, `autotag` — **there is no per-inbox `set_fields`** `[SOURCE: backend/beets_flask/config/schema.py@v2.0.0-rc6:88-95]`. And D-04 forbids the CLI arm from opening the real library. | Phase 6 can still *prove* the `albumtype:=dj` path rule via `--set` on a throwaway library. **The mechanism for setting `albumtype=dj` on a real flask-driven import is an unowned gap** — flag it for Phase 7. Candidates: global `import.set_fields` (wrong, hits everything), post-import `beet modify albumtype=dj` + `beet move`, or a hook plugin. |
| C-7 | **CONTEXT.md** refers three times to "the ROADMAP's six criteria" for Phase 6. | `.planning/ROADMAP.md:858-885` lists exactly **five** numbered success criteria before `**Plans**: TBD`. | Cosmetic; note it so the plan's criterion numbering (which CONTEXT uses consistently, and which matches the five) is not read as missing one. |

---

## Standard Stack

### Core (already chosen — versions confirmed, not re-decided)

| Component | Version | Purpose | Evidence |
|-----------|---------|---------|----------|
| `metasauce/beets-flask` | `v2.0.0-rc6` (2026-08-30) | The executing front end (D-01/D-02) | Still newest release as of 2026-09-20 `[MEASURED: GitHub releases API]` |
| beets (under flask) | `2.12.0` exact pin | The engine that actually imports | rc6 `backend/pyproject.toml` `[CITED: raw.githubusercontent.com/metasauce/beets-flask/v2.0.0-rc6/backend/pyproject.toml]` |
| `lscr.io/linuxserver/beets` | `2.13.1-ls349` | Dormant CLI arm (D-12) | `stacks/selfhosted/arrs/beets/beets.yaml:6` |
| `mediafile` | `>= 0.17.0` (current 0.17.0, 2026-04-24) | Tag read/write layer beets uses | **Both** beets 2.12.0 and 2.13.1 require `mediafile>=0.17.0` `[MEASURED: pyproject.toml at both tags]` |
| `mutagen` | 1.48.1 (2026-06-25) | Under mediafile; also `scripts/normalise-dj-tags.py` | `[MEASURED: PyPI JSON API]` |
| Jellyfin | `jellyfin/jellyfin:10.11.11` | Consumer 1 | `[MEASURED: 2026-09-20 docker ps on LXC 100]` |
| Music Assistant | `2.11.0b0` recorded as proven | Consumer 2 | `scripts/check-music-consumers.sh:200` |

**Not current, deliberately:** beets 2.14.1 shipped 2026-09-17 `[MEASURED: PyPI]`. It is outside D-02's revisit trigger (which is keyed to a beets-flask release, not a beets release) and is recorded only so the gap is dated.

### Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `beets` | PyPI | since 2013-01-29 | high | github.com/beetbox/beets | `[OK]` | Approved |
| `mutagen` | PyPI | long-established | high | github.com/quodlibet/mutagen | `[OK]` | Approved |
| `mediafile` | PyPI | — | — | github.com/beetbox/mediafile | not run (transitive dep of beets, pinned by beets' own metadata) | Approved as transitive |

`[MEASURED: 2026-09-20 slopcheck install beets mutagen → "scanned 2 packages, 2 OK"]`. slopcheck then attempted `pip install` and crashed because `pip` is absent on this workstation — **nothing was installed**; the audit itself completed before the crash.

**Packages removed due to `[SLOP]`:** none.
**Packages flagged `[SUS]`:** none.

**This phase installs no new package into the estate.** The only install-shaped action is rc6's `uv pip install -r /config/requirements.txt` at container start, which Phase 3 already audited (`03-BEETS-FLASK.md` § 3: `beets mutagen python3-discogs-client` → 3 OK, 0 SUS, 0 SLOP) and which must be written pinned as `beets==2.12.0` (Phase 3's OD-2). Note the survivor's config deliberately carries no Discogs credential (Phase 4 D-24), so the `[discogs]` extra should **not** be requested here.

---

## P1 — The DJ protected-field map, per container format (D-18)

### The table the dry-run reporter keys on

`beets field` is the name to use in a beets query, `beet modify`, `beet ls -f '$field'`, and in `Item._media_tag_fields` diffs. `ffprobe key` is what Phase 1's snapshot and `scripts/diff-music-tags.sh` actually see.

| D-18 name | beets field | MP3 / ID3v2 frame | WAV (RIFF `id3 ` chunk) | FLAC / Vorbis comment | ffprobe key | beets models it? |
|---|---|---|---|---|---|---|
| **bpm** | `bpm` (`types.INTEGER`) | `TBPM` | `TBPM` (same ID3 tag, inside the `id3 ` chunk) | `BPM` | `TBPM` (mp3/wav), `BPM` (flac) | **Yes** — fixed Item field |
| **initialkey** | `initial_key` (`types.MusicalKey()`) | `TKEY` | `TKEY` | `INITIALKEY` | `TKEY` (mp3/wav), `INITIALKEY` (flac) | **Yes** — fixed Item field |
| **EnergyLevel** | *(none)* | `TXXX:EnergyLevel` | `TXXX:EnergyLevel` | `ENERGYLEVEL` *(convention; mediafile has no mapping)* | `EnergyLevel` | **No** — not a beets field, not a mediafile field |
| **genre** | `genres` (`types.MULTI_VALUE_DSV`) — **not `genre`** | `TCON` (multi-value list) | `TCON` | `GENRE` (repeatable) | `genre`/`GENRE`/`Genre` | **Yes**, but as `genres` |
| **comment** | `comments` (`types.STRING`) | `COMM` (description-keyed) | `COMM` | `DESCRIPTION` *(preferred)* or `COMMENT` | `comment`/`COMMENT` | **Yes** — fixed Item field |

Storage-style evidence, all from `mediafile/__init__.py@master` (= 0.17.x, the version both beets tags require):
- `bpm = MediaField(MP3StorageStyle("TBPM"), MP4StorageStyle("tmpo", as_type=int), StorageStyle("BPM"), ASFStorageStyle("WM/BeatsPerMinute"), out_type=int)` — line 525.
- `initial_key = MediaField(MP3StorageStyle("TKEY"), MP4StorageStyle("----:com.apple.iTunes:initialkey"), StorageStyle("INITIALKEY"), ASFStorageStyle("INITIALKEY"))` — line 885.
- `genres = ListMediaField(MP3ListStorageStyle("TCON"), MP4ListStorageStyle("\xa9gen"), ListStorageStyle("GENRE"), ASFStorageStyle("WM/Genre"))`; `genre = genres.single_field()` — lines 413-419.
- `comments = MediaField(MP3DescStorageStyle(key="COMM"), MP4StorageStyle("\xa9cmt"), StorageStyle("DESCRIPTION"), StorageStyle("COMMENT"), ASFStorageStyle("WM/Comments"), ASFStorageStyle("Description"))` — lines 511-518. **Note the order: `DESCRIPTION` is listed before `COMMENT`, so on a Vorbis write mediafile writes `DESCRIPTION` first.**

`StorageStyle(...)` with no prefix is mediafile's **generic/Vorbis** style; `MP3StorageStyle` is ID3. `wav` is a supported mediafile type (`TYPES` includes `"wav": "WAVE"` in `mediafile/constants.py`), and `MediaFile` detects it via `type(self.mgfile).__name__ == "WAVE"` → `self.type = "wav"` (line 193-205), after which the **ID3 styles apply** — mutagen's `WAVE` object exposes an `ID3` tag object. Confirmed operationally by this repo's own normaliser.

### WAV is the awkward one, and this repo already solved it

`scripts/normalise-dj-tags.py` (docstring lines 117-130) records, from measurement on this exact corpus:

> A WAVE carries TWO tag containers: an ID3 tag inside a RIFF `id3 ` chunk, and a RIFF LIST/INFO chunk (`IPRD` is its album). This script writes the ID3 tag ONLY … It never uses `mutagen.File(easy=True)` for a WAV: on a WAVE that yields a raw frame-keyed ID3, not an EasyID3 map, which is how the tool wrote 0 of 134 WAVs (`TypeError: … not a Frame instance` on every one) and read album=None from the 87 that carry one. **ID3 only, because D-23 records that ID3 is what both consumers read.**

Consequences the dry-run reporter must honour:
1. For a WAV, the ID3 header is **not at file offset 0** — it is at the data offset of the `id3 ` chunk (`wave_id3_offset()`, line 748). Any frame-set comparison must use that offset.
2. `mediafile` / beets write **only** the ID3 chunk. A pre-existing `LIST/INFO` `IGNR`/`ICMT` remains and will silently disagree. The normaliser already reports this as `info_iprd` for album; the same disagreement class exists for genre/comment.
3. `mutagen` does not round-trip what it read. Three defaults broaden the write past the fields asked for — ID3 major-version translation (`TYER`/`TDAT`/`TIME` → `TDRC`), ID3v1 merge into a `COMM:ID3v1 Comment:eng` frame, and `save(v1=UPDATE)` regenerating the whole 128-byte trailer (which moves `audio_md5`, the key the tag-diff scripts join on). All three are set explicitly in `normalise-dj-tags.py` and all three apply to any beets write too.

### What the corpus actually carries — measured, not assumed

`[MEASURED: 2026-09-20, `zcat /mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz`, 9,736 records, aggregated by extension]`

Scan roots in that snapshot: `unsorted` 7,451 · `media/Music` **1,244** · `dj-mixes` 764 · `music` 277. Extensions: mp3 8,407 · flac 1,059 · wav 268 · wv 2.

| D-18 field | MP3 (8,407) | FLAC (1,059) | WAV (268) |
|---|---|---|---|
| bpm | `TBPM` **799** | `BPM` **40** | **0** |
| initialkey | `TKEY` **306** | **0** (no `INITIALKEY`, no `KEY`) | **0** |
| EnergyLevel | `EnergyLevel` **90** | **0** | **0** |
| genre | `genre` **8,086** | `GENRE` 498 + `Genre` 332 + `genre` 110 | **0** |
| comment | `comment` **5,933** (+ `ID3v1 Comment` 74) | `COMMENT` 229 + `comment` 39 | `comment` **174** |

Three things fall out:
- **No WAV in this estate carries BPM, key or energy.** The "awkward format" is awkward for album/artist, not for the DJ fields. D-18's WAV branch will have nothing to report.
- **FLAC casing is inconsistent** (`GENRE`/`Genre`/`genre`, `COMMENT`/`comment`). Vorbis keys are case-insensitive by spec and mutagen normalises on read, but a naive `ffprobe` key comparison will show spurious differences. The reporter must fold case for Vorbis.
- The D-19 figures ("148 of 764 `dj-mixes` carry `TKEY`, 45 carry `EnergyLevel`") are a `dj-mixes`-only slice; the estate-wide totals above are larger and are the denominator a global reporter would use. Neither number is wrong — they count different sets.

### How beets treats each field on import — the mechanism D-18 needs

`Item._media_fields = set(MediaFile.readable_fields()) & Item._field_names` and `Item._media_tag_fields = set(MediaFile.fields()) & Item._field_names` `[SOURCE: beets/library/models.py@v2.12.0:711-717]`. Therefore:

- `bpm`, `initial_key`, `genres`, `comments` **are** beets fields → read from disk on import, and **written back** by `Item.write()`. MusicBrainz supplies none of them, so with `scrub.auto: no` and `overwrite_null` at its default they are preserved from the file. This is the mechanism D-18's list is protecting; it is a *mechanism*, not a guarantee, which is exactly why D-18 wants a named list and a report.
- `EnergyLevel` is **not** a beets field and **not** a mediafile field. beets never reads it, never writes it, and mutagen's `save()` preserves frames it did not touch. So `TXXX:EnergyLevel` survives any beets import **unless** `scrub` runs. The correct assertion for it is a raw frame-set comparison (the `assert_frame_set_unchanged()` shape `normalise-dj-tags.py:114` already implements), **not** a beets query — a beets query for `EnergyLevel` would return nothing and read as "clean".
- ⚠ **`genre` is not a beets field name in 2.x.** `Item._field_names` contains `genres`, not `genre` (`[SOURCE: beets/library/fields.py@v2.12.0]` — `TYPE_BY_FIELD` has `"genres": types.MULTI_VALUE_DSV` and no `genre` entry). `$genre` in a path template or `beet ls genre:…` will not behave as expected; use `genres`. `MULTI_VALUE_DSV` joins with `MULTI_VALUE_DELIMITER = "\\␀"` (backslash + U+2400) in the database `[SOURCE: beets/dbcore/types.py@v2.12.0:33]`, converted to the real NUL by mediafile on write — so a `$genres` template renders that literal separator and must be passed through `%first{}` if it is ever used in a path.

---

## P2 — Path formats: the actual stanza (D-13 / D-14 / D-15 / D-19b)

### How beets selects a path rule — first match wins, in config order

```python
for query, path_format in path_formats:
    if query == PF_KEY_DEFAULT:  continue
    query, _ = parse_query_string(query, type(self))
    if query.match(self):  break
else:
    # fall back to the key literally named "default"
```
`[SOURCE: beets/library/models.py@v2.12.0:1182-1215]`

`path_formats` is built by:
```python
PF_KEY_DEFAULT = "default"
PF_KEY_QUERIES = {"comp": "comp:true", "singleton": "singleton:true"}

def get_path_formats(subview):
    """…The mapping is read through Confuse's ``items()`` view so keys from lower-
    priority sources remain visible when higher-priority config only overrides
    part of ``paths``. This keeps inherited defaults such as ``default``,
    ``comp``, and ``singleton`` available unless they are explicitly replaced."""
    return [(PF_KEY_QUERIES.get(q, q), template(v.as_str())) for q, v in subview.items()]
```
`[SOURCE: beets/util/pathformats.py@v2.12.0]` — **byte-identical between v2.12.0 and v2.13.1** `[MEASURED: diff]`.

Three consequences, all of which D-15 is right about and now has a citation for:
1. **`comp:` and `singleton:` are only aliases** for the queries `comp:true` and `singleton:true`. Every other key is a full beets query string.
2. **Defining `paths:` in the user config does NOT remove the default keys.** The docstring says so verbatim. So `Compilations/` survives unless `comp:` is explicitly overridden — D-15's "override, do not delete" is structurally required, not stylistic.
3. **Order = confuse key order = user-config keys (in YAML order) first, then keys present only in the defaults.** `Subview.keys()` iterates `self.resolve()` (highest-priority source first) and dedupes `[SOURCE: confuse/core.py, Subview.keys/items]`. So an un-overridden `singleton:` lands *after* every user key and therefore has the **lowest** precedence of any non-default rule — which is why D-19b's rule must be written out, and written **first**.

### Query syntax available in a path key

beets query prefixes (both versions): `:` → `RegexpQuery`, `=~` → `StringQuery` (case-insensitive exact), `=` → `MatchQuery` (exact), no prefix → `SubstringQuery` `[SOURCE: beets/library/queries.py@v2.12.0:18-22]`.

⚠ **`albumtype:dj` as written in D-13 is a SUBSTRING match.** It matches `albumtype=djmix`, `albumtype=adjacent`, anything containing `dj`. Use `albumtype:=dj` (exact).
⚠ The key is `shlex.split()` before parsing, so spaces become AND terms and shlex quoting applies. And `PathQuery.is_path_query(s)` rewrites any bare term containing `/` into a path query — **never put a `/` in a path-format key**.
`albumtype` and `albumtypes` are **fixed** Album fields (and, by inheritance, Item fields), not flexible attributes `[SOURCE: beets/library/models.py@v2.12.0:278-279, 632-634]` — so `albumtype:=dj` is a first-class typed query and `--set albumtype=dj` sets a real column.
`disctotal` is `types.PaddedInt(2)` → `NumericQuery`, which supports Ruby-style ranges `2..` `[SOURCE: beets/library/fields.py; beets/dbcore/query.py@v2.12.0:429-436]`.

YAML parses all of these unquoted-or-quoted as intended `[MEASURED: 2026-09-20 python3 -c yaml.safe_load]`:
```
'albumtype:=dj'                 -> 'DJ/...'
'disctotal:2..'                 -> '...'
'albumtype:=dj disctotal:2..'   -> '...'   (shlex -> ['albumtype:=dj', 'disctotal:2..'])
```

### The recommended stanza

```yaml
# Order is load-bearing: Item.destination() takes the FIRST non-`default` key
# whose query matches, and confuse puts user keys ahead of default-only ones.
paths:
    # D-19b — singletons FIRST. An un-overridden `singleton:` inherits the lowest
    # precedence of any rule, so it must be written out to sit where we want it.
    singleton:                      'Singles/$artist/$title%sunique{}'

    # D-13 + D-14 — DJ content, multi-disc
    'albumtype:=dj disctotal:2..':  'DJ/$albumartist/$album%aunique{}/$disc-$track $title'
    # D-13 — DJ content, single disc
    'albumtype:=dj':                'DJ/$albumartist/$album%aunique{}/$track $title'

    # D-14 — everything else, multi-disc. Placed BEFORE `comp:` on purpose: a
    # multi-disc compilation should get the disc prefix, and this template is
    # already identical to the comp override below.
    'disctotal:2..':                '$albumartist/$album%aunique{}/$disc-$track $title'

    # D-15 — the comp override. Identical to `default` by design: that is what
    # "resolve to $albumartist" means, written as an override rather than a deletion.
    comp:                           '$albumartist/$album%aunique{}/$track $title'

    default:                        '$albumartist/$album%aunique{}/$track $title'

# D-14 requires $track to be the PER-DISC number, not the absolute one.
per_disc_numbering: yes
```

Supporting keys that the D-14/CONF-03 result depends on and that must be stated explicitly rather than inherited:

```yaml
per_disc_numbering: yes   # default is `no`
asciify_paths: no         # default is `no`, but rc6's example config sets `yes`
va_name: "Various Artists"  # default; CONF-03's exact string, case included
max_filename_length: 0
```

### What `per_disc_numbering: yes` actually changes

```python
"track": self.index,
"medium_index": (mindex if (mindex := self.medium_index) is not None else self.index)
                 if config["per_disc_numbering"] else self.index,
...
if config["per_disc_numbering"] and self.medium_total is not None:
    data["tracktotal"] = self.medium_total
```
with `MEDIA_FIELD_MAP = {..., "medium": "disc", "medium_index": "track"}`
`[SOURCE: beets/autotag/hooks.py@v2.12.0:415-455]`

So with `yes`: `$track` = per-disc index, `$tracktotal` = that medium's track count, `$disc` = medium number. With `no`: `$track` = absolute index across the release, which makes `$disc-$track` render `02-17` for disc 2 track 5 — plausible-looking and wrong. **This key is the difference between D-14 working and D-14 producing a number nobody notices is wrong.**

### ⚠ The rendering is `02-05`, not `2-05`

`disc` and `track` are both `types.PaddedInt(2)` `[SOURCE: beets/library/fields.py@v2.12.0]`, so `$disc-$track` renders **`02-05`**, not the `2-05` D-14's text writes. Options, both valid:
- Accept `02-05` and write the committed expected tree (D-27) to `02-05`. Recommended — it sorts correctly and matches the existing library's own `CD 02-01 …` convention (see below).
- `%right{$disc,1}-$track` → `2-05`. **Breaks at disc 10** (`%right{"10",1}` = `0`). Not recommended.

Relevant context the planner should see before choosing: **the existing 1,244-file library already uses `CD DD-TT Artist - Title.ext`** — e.g. `/mnt/tank/media/Music/P!nk/TRUSTFALL (2023)/CD 02-01 P!nk - Dreaming.flac` `[MEASURED: 2026-09-20 ls]`. The proposed `02-05 Title.ext` is a *third* convention, neither the old one nor D-14's literal text. Phase 6 does not have to reconcile them, but the expected-tree oracle has to pick one and say so.

### `%aunique{}` — exactly what it appends and when (D-16)

`[SOURCE: beets/library/models.py@v2.12.0:1356-1395 (tmpl_aunique) and 1440-1525 (_tmpl_unique)]`

1. Returns `""` immediately if there is no `item`/`lib`, or `album_id is None` (i.e. **singletons never get a disambiguator**, and neither does an item not yet in a library).
2. Queries the library for other albums matching `aunique.keys` (default `albumartist album`). **If exactly one album matches, returns `""`.**
3. Otherwise walks `aunique.disambiguators` in order (default `albumtype year label catalognum albumdisambig releasegroupdisambig`) and takes the **first** one whose values are distinct across the whole ambiguous set.
4. Returns `f" {bracket_l}{disam_value}{bracket_r}"` — **with a leading space**, brackets from `aunique.bracket` (default `[]`). So `$album%aunique{}` → `TRUSTFALL [2023]`.
5. If **no** disambiguator distinguishes them, it returns `f" {bracket_l}{item_id}{bracket_r}"` — the **numeric database id**. That value is not reproducible across libraries and will differ between a throwaway library and the real one. Any committed expected tree containing ` [123]` is a landmine.
6. Results are memoised in `lib._memotable`.

⚠ **Consequence for the dry run (D-16 + D-27).** `%aunique{}` is evaluated **against whatever library the item is in**. A `beet move -p` against a throwaway library containing only the sample cannot see collisions with the real 1,244-file library, so it will report *fewer* firings than a real import would. Two ways to handle it, both honest:
- (a) Run the oracle against a **copy** of the real `library.db` (read-only use, throwaway path), so aunique sees the real collision set. Best fidelity; note that beets 2.13.1 opening a 2.12.0 db would migrate it — so the copy must be opened by **flask's 2.12.0**, per D-04.
- (b) Run against a bare throwaway and **record in the plan that aunique firings are a lower bound**, not a count. Cheaper, and honest, but weaker than D-16 asks for.

`%sunique{}` is the singleton analogue: `keys: artist title`, `disambiguators: year trackdisambig`, same bracket, and returns `""` for anything with a non-null `album_id` `[SOURCE: models.py@v2.12.0:1398-1440; beets/config_default.yaml sunique block]`.

### Version compatibility for the whole stanza

`config_default.yaml` at v2.12.0 and v2.13.1 differ by **exactly one line** — v2.13.1 adds `create_backup_before_migrations: yes` `[MEASURED: 2026-09-20 diff of the two raw files]`. `beets/util/pathformats.py` is byte-identical. The template-function set (`lower upper capitalize title left right if asciify time aunique sunique first ifdef`) is identical; only type annotations were added in 2.13.1 `[MEASURED: diff of `def tmpl_` lines]`. **Nothing in the recommended stanza differs between the two versions.**

`create_backup_before_migrations: yes` is itself relevant to D-04: if the 2.13.1 survivor ever *did* open the real `library.db`, 2.13.1 would take a backup first — a mitigation, not a permission. D-04's structural rule stands.

---

## P3 — The exact invocation shapes (D-30 / D-04)

### F-02: what `beet import --pretend` actually does

```python
if self.query is None: stages = [stagefuncs.read_tasks(self)]
else:                  stages = [stagefuncs.query_tasks(self)]

# In pretend mode, just log what would otherwise be imported.
if self.config["pretend"]:
    stages += [stagefuncs.log_files(self)]
else:
    ... group_albums / lookup_candidates / user_query / import_asis
    ... plugin stages ...
    stages += [stagefuncs.manipulate_files(self)]
```
`[SOURCE: beets/importer/session.py@v2.12.0:201-240]`

```python
def log_files(session, task):
    if isinstance(task, SingletonImportTask): log.info("Singleton: {}", displayable_path(task.item["path"]))
    elif task.items:
        log.info("Album: {}", displayable_path(task.paths[0]))
        for item in task.items: log.info("  {}", displayable_path(item["path"]))
```
`[SOURCE: beets/importer/stages.py@v2.12.0:266-274]`

So `--pretend` output is: source album directory, then one source file path per item. **No destination. No candidate. No MusicBrainz query. No `finalize` stage.**

What `--pretend` *does* legitimately prove: which folders are offered as tasks (so it **does** exercise `incremental`, `ignore`, `ignore_hidden`, `clutter`, `singletons`, and album grouping), and it proves it **without** reaching `finalize`, which is the only place `save_history()`/`save_progress()` are called (`[SOURCE: beets/importer/tasks.py@v2.12.0:310-320]`). That is a real, useful, read-only instrument — it is just not the tree oracle.

### `beet move -p` — the destination-path oracle

```python
if pretend:
    show_path_changes([(item.path, item.destination(basedir=dest)) for ...])
```
printing `Source … -> Destination` pairs (or two lines each if the terminal is narrow) `[SOURCE: beets/ui/commands/move.py@v2.12.0]`. `move_cmd.parser.add_option("-p", "--pretend", … help="show how files would be moved, but don't touch anything")`.

`item.destination()` is the *same* code path a real import uses, so this evaluates the full `paths:` stanza, `%aunique{}`, `replace:`, `asciify_paths`, `legalize_path` and `max_filename_length`. It operates on items **already in a library**, so the oracle needs the sample imported into a throwaway library first.

⚠ `move_items` filters out items where `item.path == item.destination(...)` and prints `"(N already in place)"`. If the throwaway import was done in place (`copy: no, move: no`) the items' paths are their source paths, so nothing is "already in place" and everything is listed. Good. But **read the "already in place" count** — a silent 0-row output is the failure mode.

### The throwaway library, and the state file `-l` does NOT cover

`_open_library()` runs for **every** `beet` subcommand, including `config`:
```python
lib = _open_library(config)            # in _setup(), called by _raw_main for every command
...
def _open_library(config):
    dbpath = util.bytestring_path(config["library"].as_filename())
    _ensure_db_directory_exists(dbpath)
    lib = library.Library(dbpath, config["directory"].as_filename())
    lib.get_item(0)   # Test database connection
```
`[SOURCE: beets/ui/__init__.py@v2.12.0:787, 842-860]`

- `-l /tmp/throwaway.db` on a nonexistent file: `_ensure_db_directory_exists` only prompts if the **directory** is missing; `/tmp` exists, so it proceeds and `library.Library()` creates the file and applies the full migration set **silently, with no prompt**. D-04's mechanism works. ✔
- **`-l` does not redirect `statefile:`.** `ImportState.__init__` takes `config["statefile"].as_filename()` `[SOURCE: beets/importer/state.py@v2.12.0]`, and `statefile` is an independent top-level key (`statefile: state.pickle`, resolved relative to the config dir). There is **no CLI flag** for it. A real (non-pretend) import on a throwaway `-l` will therefore still write the **shared** `state.pickle` — and there is one on the host today (`/mnt/fast/appdata/arrs/beets/config/state.pickle`, 47 bytes, mtime 2025-11-18 `[MEASURED: 2026-09-20 ls]`).
- ⇒ **Every throwaway invocation must use a `-c` overlay that sets `library:`, `statefile:` and `directory:`**, not just `-l`. `beet -c overlay.yaml` adds the file at highest priority (`config.set_file(overlay_path)` in `_configure` `[SOURCE: beets/ui/__init__.py@v2.12.0]`).

Suggested overlay:
```yaml
# /tmp/phase06-throwaway.yaml  (inside the container; /tmp is tmpfs on LXC 100 — keep it tiny)
library:   /tmp/phase06/throwaway.db
statefile: /tmp/phase06/throwaway-state.pickle
directory: /tmp/phase06/tree          # never /mnt/tank/media
```
D-29 layer 3 then has a clean assertion: the real `library.db` and the real `state.pickle` are byte-identical (sha256) before and after.

### The beets-flask container: image internals

All from `docker/Dockerfile@v2.0.0-rc6` and `docker/entrypoints/*@v2.0.0-rc6`:

| Fact | Value |
|---|---|
| Image | `metasauce/beets-flask:v2.0.0-rc6` (digest verified by Phase 3: `sha256:9548e78f…`) |
| Python venv | `/venv` (`ENV UV_PROJECT_ENVIRONMENT=/venv`; `COPY --from=builder_py --chown=beetle:beetle /venv /venv`) |
| `beet` binary | `/venv/bin/beet` — **not on `PATH` for a `docker exec`.** The ENTRYPOINT does `source /venv/bin/activate`; `.bashrc` sources a *different*, non-existent path (`/repo/backend/.venv/bin/activate`) and only for interactive bash. |
| Runtime user | `beetle` (built as uid 1000, remapped by `entrypoint_fix_permissions.sh` from `USER_ID`/`GROUP_ID`, **or `PUID`/`PGID`** — both are honoured) |
| `BEETSDIR` | `/config/beets` (image ENV) |
| `BEETSFLASKDIR` | `/config/beets-flask` (image ENV) |
| `BEETSFLASKLOG` | `/logs/beets-flask.log` |
| Server port | 5001 (`launch_server.py`; the image declares **no** `ExposedPorts`) |
| Redis | bundled; `entrypoint.sh` starts it only `if [ -z "$REDIS_URL" ]` |
| User install hook | `uv pip install -r /config/requirements.txt` **and** `/config/beets-flask/requirements.txt`, run as root before `su beetle` |
| User startup hook | `/config/startup.sh` and `/config/beets-flask/startup.sh` |
| `EXTRA_GROUPS` | `"name1:gid1,name2:gid2"` — supported by `entrypoint_add_groups.sh` |

**`entrypoint_fix_permissions.sh` chowns only `/home/beetle /logs /repo` — it does NOT touch `/config`.** `[SOURCE: docker/entrypoints/entrypoint_fix_permissions.sh@v2.0.0-rc6]` This is materially better than the LSIO image's `lsiown -R /config` and means **a `:ro` single-file config mount into `/config` is safe from a boot-time chown**. The s6/`lsiown` race documented at `beets.yaml:45-60` does **not** apply to this image.

`entrypoint.sh` does:
```sh
mkdir -p /logs /config/beets /config/beets-flask
python -c "from beets_flask.database.migration import run_migrations; run_migrations()"
python -c "from beets.ui import _open_library; from beets_flask.config.beets_config import get_config; _open_library(get_config().beets_config)"
```
— i.e. **the container itself opens and migrates the real `library.db` at every start**, under 2.12.0. Consistent with D-04 (flask's 2.12.0 is the only thing that opens it), and it is the reason the container must not be started before the vendored config is in place.

### The `docker exec` forms

```bash
# D-30 arm 1 — effective config as the CLI sees it
docker exec -u beetle beets-flask /venv/bin/beet \
    -c /tmp/phase06-throwaway.yaml config -d

# ... and the list of files the config was actually assembled from
docker exec -u beetle beets-flask /venv/bin/beet \
    -c /tmp/phase06-throwaway.yaml config -p -d

# `beet config -d` REDACTS fields marked sensitive. Pass -c/--clear to un-redact.
#   config_out = config.dump(full=opts.defaults, redact=opts.redact)   [ui/commands/config.py]
# This repo holds no beets credential (Phase 4 D-24), so redaction should be a no-op —
# assert that it is, rather than assuming.

# Which folders would be offered (proves incremental / ignore / grouping; NOT the tree)
docker exec -u beetle beets-flask /venv/bin/beet \
    -c /tmp/phase06-throwaway.yaml import --pretend /path/to/sample

# The tree oracle, after a fenced in-place import into the throwaway library
docker exec -u beetle beets-flask /venv/bin/beet \
    -c /tmp/phase06-throwaway.yaml move -p
```

⚠ **`docker exec` inherits the image `ENV`, so `BEETSDIR=/config/beets` applies** and `beet` will load `/config/beets/config.yaml` *underneath* the `-c` overlay. That is what makes `beet config -d` meaningful — but it also means the overlay must set every key it wants to win, since the vendored config sits beneath it.

⚠ **Do not gate the exec on `docker inspect .State.Status == running`.** The LSIO lesson at `beets.yaml:54-60` generalises: for rc6 the correct gate is that `entrypoint.sh` has reached the server, which is observable as the watchdog's inbox-registration line in the logs. Phase 3 captured its exact shape:
```
[INFO] beets-flask.wdog: Registering watchdog with debounce of 30 seconds for inboxes:
  ['…/preview', '…/auto', '…/bootleg']
```
`[03-BEETS-FLASK.md:195-198]` — this is D-09 part 1's assertion target, and it prints **all** registered inboxes in one line, so "fewer than three" is directly checkable.

### D-30's two arms measure two different objects — and here is why

`BeetsFlaskConfig.commit_to_beets()`:
```python
beets.config.clear()
beets.config.read()
# Put our defaults that come from schema at lowest priority
beets.config.add(asdict_with_aliases(BeetsSchema()))
# Inserts user config into confuse
beets.config.set(self.to_dict(extra_fields=True))
```
`[SOURCE: backend/beets_flask/config/beets_config.py@v2.0.0-rc6]`

and
```python
def to_dict(self, extra_fields: bool = True) -> dict:
    data = asdict_with_aliases(self.proxy._data)     # the FULL dataclass -> includes defaults
    if extra_fields: data = merge_dicts(data, self.proxy._extra_data)
    return data
```
`[SOURCE: eyconf 0.8.0, eyconf/config/extra_fields.py:233-238]`

`confuse.Configuration.set()` inserts at **highest** priority. `to_dict()` serialises the whole `BeetsSchema` dataclass, so **every schema field the user did not set is injected at top priority with the schema's default value.** The schema defaults that differ from beets' own:

| Key | beets 2.12 default | rc6 schema default | Effect if the vendored config is silent |
|---|---|---|---|
| `import.duplicate_action` | `ask` | **`remove`** | Duplicates are **removed** without a prompt. |
| `match.medium_rec_thresh` | `0.25` | `0.10` | A much narrower "medium" band; changes which imports are offered as auto. |
| `directory` | `~/Music` | **`/music/imported`** | Imports target a path that does not exist in this container. |
| `import.duplicate_keys.album` | `albumartist album` (str) | `["albumartist","album"]` | Equivalent via `str_seq`; harmless. |
| `import.move` / `import.copy` | `no` / `yes` | `Literal[False]` / `Literal[True]` | Same values — but **type-enforced**: a config setting `move: yes` is *rejected*, not overridden. |
| `plugins` | `[musicbrainz]` | `["musicbrainz"]` | Same. |

⇒ **Action for the vendored config:** set `directory:`, `import.duplicate_action:` and `match.medium_rec_thresh:` explicitly. An absent key here is not a default — it is rc6's default, and for `duplicate_action` that is a delete.

⇒ **Action for D-30:** `docker exec … beet config -d` shows the *confuse* view (vendored file + overlay). It does **not** show `commit_to_beets()`'s injection, which happens only inside the server process. So D-30's "effective config of the thing that actually runs" is best read from a python one-liner inside the container:
```bash
docker exec -u beetle beets-flask /venv/bin/python -c \
 "import beets, yaml; from beets_flask.config.beets_config import get_config; \
  c=get_config(commit_to_beets=True); print(beets.config.dump(full=True, redact=True))"
```
(shape confirmed from the module's own public API; **NOT VERIFIED by execution** — no container exists yet.)

### rc6's own config validation — friction 9, at source

`reload()` loads **both** `$BEETSDIR/config.yaml` and `$BEETSFLASKDIR/config.yaml` into the same eyconf schema, and "EYConfs update method also validates against the schema" `[SOURCE: beets_config.py@v2.0.0-rc6, reload()]`. `BeetsSchema.plugins: list[str]` is why `plugins: musicbrainz` is rejected — D-10 confirmed at source.

`validate()` additionally:
- strips trailing slashes from inbox paths (and logs a warning);
- substitutes the YAML heading for `name` when it is `_use_heading`;
- **raises `ConfigurationError` for any inbox folder whose `path` does not exist** (except paths under `/music/beets_flask_config_example/`).
⇒ **All three registered inbox directories must exist before the container starts.** They do `[MEASURED: 2026-09-20 ls of `_inbox/`]`.

Extra (non-schema) keys **are** allowed, at every nesting level: `ConfigExtra.__init__` walks `iter_dataclass_type(self._schema)` and sets `__allow_additional = True` on each dataclass in the tree `[SOURCE: eyconf/config/extra_fields.py:184-192]`. So `import.incremental`, `import.incremental_skip_later`, `match.preferred.countries`, `paths:`, `per_disc_numbering`, `aunique:` etc. all pass validation untouched. **This removes the main risk to CONF-02, CONF-03 and CONF-05 under rc6.**

### ⚠ The destructive-default landmine in rc6's bootstrap

`BeetsFlaskConfig.__init__` calls `write_examples_as_user_defaults()` **before** `reload()`:
```python
if not os.path.exists(beets_config_path):
    shutil.copy2(_BEETS_EXAMPLE_PATH, beets_config_path)   # $BEETSDIR/config.yaml
```
`[SOURCE: beets_config.py@v2.0.0-rc6]`

The example it copies (`config_b_example.yaml@v2.0.0-rc6`) enables:
```yaml
plugins: [info, the, fetchart, embedart, ftintitle, lastgenre, missing, albumtypes,
          scrub, zero, mbsync, duplicates, convert, fromfilename, inline, edit, spotify, musicbrainz]
embedart:  { auto: yes, ifempty: yes, remove_art_file: yes }
ftintitle: { auto: yes }
lastgenre: { auto: yes, count: 4, force: yes, source: track, separator: "; " }
asciify_paths: yes
per_disc_numbering: no
```
That is `embedart.auto: yes` (rewrites the audio file), `lastgenre.auto: yes` with `force: yes` (overwrites genre unconditionally, even when one exists), and `scrub` loaded — **the exact three SAFE-01 switches Phase 1 turned off**, plus `asciify_paths: yes` which would silently mangle `P!nk` and every non-ASCII album name in the tree CONF-03 is about.

**Mitigation, and it must be a pre-start assertion rather than a post-hoc check:** the vendored config must already exist at `$BEETSDIR/config.yaml` at the moment the container first starts. Two ways:
- **(a) Recommended:** set `BEETSDIR=/config` in the flask service's `environment:`. Then `$BEETSDIR/config.yaml` = `/config/config.yaml` = the single vendored file both containers already read, and `library: /config/library.db` resolves to the same file in both. One vendored config, one path expression, D-03 satisfied with no duplication. (`BEETSFLASKDIR` stays `/config/beets-flask`.)
- (b) Mount the vendored file a second time at `/config/beets/config.yaml`.

Either way, **assert non-emptiness and content** of that path immediately after first start, and assert the log line `Beets config not found at …` / `Copying default config to …` did **not** appear. That log line is the detector; it is emitted at `log.info` `[SOURCE: beets_config.py write_examples_as_user_defaults()]`.

### P5c — rc6 pagination / inbox-size knobs (D-08 read-only answer)

`BeetsFlaskSchema` exposes, in total: `gui.num_preview_workers` (int, default 4), `gui.inbox.ignore`, `gui.inbox.debounce_before_autotag` (int, default **30** seconds), `gui.inbox.temp_dir`, `gui.inbox.folders{}`, `gui.library.readonly` (bool, default False), `gui.library.artist_separators` (default `[",", ";", "&"]`), `gui.terminal.enabled`, `gui.terminal.start_path` `[SOURCE: backend/beets_flask/config/schema.py@v2.0.0-rc6]`.

**There is no pagination, page-size, or inbox-item-limit knob at all.** The only levers on the documented "laggy past some hundred folders" risk are `gui.inbox.ignore` (reduce what is *listed*) and batch cadence (Phase 9's chosen mitigation). Recorded for Phase 9; D-08 stands.

Two of these are directly useful here:
- `gui.inbox.debounce_before_autotag: 30` — **D-09 part 2's throwaway folder will not be picked up for at least 30 s.** A liveness test that polls for 10 s and gives up reads as a failure that is really a debounce.
- `gui.library.readonly: true` — a cheap extra belt for the whole of Phase 6, since the phase writes nothing. Worth considering; it is a beets-flask UI guard, not a mount, so it is weaker than `:ro` and does not replace D-05.

---

## P4 — Consumer verification endpoints (D-22 / D-24 / D-25)

### Jellyfin: the two buttons that sit next to each other

Both from the **10.11.11** OpenAPI document — the exact running version `[CITED: repo.jellyfin.org/files/openapi/stable/jellyfin-openapi-10.11.11.json]`. (The live server's own `/api-docs/openapi.json` returns **500 "Error processing request."** `[MEASURED: 2026-09-20]` — worth knowing before a plan tries to read it.)

**THE ONE THAT MUST NOT BE USED (D-24):**
```
POST /Items/{itemId}/Refresh
  ?metadataRefreshMode=FullRefresh     <-- Phase 1 measured this rewriting 83 of 91 .nfo
  &imageRefreshMode=...&replaceAllMetadata=...&replaceAllImages=...
MetadataRefreshMode enum: None | ValidationOnly | Default | FullRefresh
```
Also **not** to be used for a targeted scan: `POST /Library/Refresh` — "Starts a library scan", no scope parameter, all libraries.

**THE TARGETED ONE (D-24):**
```
POST /Library/Media/Updated
Content-Type: application/json
{"Updates":[{"Path":"/media/Music/<Artist>/<Album>","UpdateType":"Modified"}]}
```
`MediaUpdateInfoPathDto = { Path: string, UpdateType: string /* Created, Modified, Deleted */ }`.
Note the path is the **Jellyfin-internal** path (`/media/Music/...`), not the host path.

Why it is safe and why it works with the Phase 1 freeze in force — traced to source:
```csharp
public ActionResult PostUpdatedMedia([FromBody, Required] MediaUpdateInfoDto dto) {
    foreach (var item in dto.Updates)
        _libraryMonitor.ReportFileSystemChanged(item.Path ?? throw …);
    return NoContent();
}
```
`[SOURCE: Jellyfin.Api/Controllers/LibraryController.cs@v10.11.11:646-654]`
```csharp
public void ReportFileSystemChanged(string path) { … CreateRefresher(path); }
```
`[SOURCE: Emby.Server.Implementations/IO/LibraryMonitor.cs@v10.11.11:346-381]`
— it does **not** consult whether the FS watcher was started, so `EnableRealtimeMonitor: false` does not disable it. The refresher then calls `item.ChangedExternally()` per affected item `[SOURCE: Emby.Server.Implementations/IO/FileRefresher.cs@v10.11.11:130-156]`, i.e. a **Default**-mode refresh, not `FullRefresh`.

Three operational facts the plan needs:
1. **Debounce: `LibraryMonitorDelay` = 60** on this server `[MEASURED: 2026-09-20 grep of /mnt/fast/appdata/media/jellyfin/config/system.xml]`. The refresher restarts a 60 s timer on every reported change. Budget ≥ 90 s before reading back.
2. `GetAffectedBaseItem` walks **up** the path until it finds an item the library already knows `[SOURCE: FileRefresher.cs@v10.11.11:157-170]`. For a path Jellyfin has never seen, the "targeted" scope becomes the nearest known ancestor — potentially the Music library root. Still not a full-library refresh, but not as narrow as the endpoint name implies.
3. `MetadataSavers: ["Nfo"]` is still configured on the Music library `[MEASURED: 2026-09-20]`. `SaveLocalMetadata: false` is the gate; the saver list is still armed behind it. Worth asserting rather than assuming, per Phase 1's own finding.

**Reading back distinct artist entities (D-22):**
```
GET /Items
  ?IncludeItemTypes=Audio
  &Recursive=true
  &ParentId=7e64e319657a9516ec78490da03edccb      # the Music library ItemId, measured
  &Fields=ArtistItems,Artists,AlbumArtist,Path
  &Limit=5000
```
`BaseItemDto.ArtistItems : NameGuidPair[]` — **this is the browseable-entity list D-22 asks for** (each has an `Id`); `Artists : string[]` is the flat name list `[CITED: jellyfin-openapi-10.11.11.json, components.schemas.BaseItemDto]`. `/Artists` and `/Artists/{name}` also exist if a per-artist page needs to be proven reachable.

Header form, following the existing pattern at `scripts/check-music-consumers.sh:433-441` so the key never enters argv:
```bash
curl -s -G -H @<(printf 'Authorization: MediaBrowser Token="%s"\n' "$JELLYFIN_API_KEY") "http://${ADDR}${path}"
```
with `ADDR` from `docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'):8096` — `localhost:8096` is refused from LXC 100.

### Jellyfin's Music library options — measured, and they change criterion 4

`[MEASURED: 2026-09-20 GET /Library/VirtualFolders]`

| Option | Value | Why it matters here |
|---|---|---|
| `ItemId` | `7e64e319657a9516ec78490da03edccb` | matches the pinned constant at `check-music-consumers.sh:245` |
| `Locations` | `["/media/Music"]` | the path for `/Library/Media/Updated` |
| **`PreferNonstandardArtistsTag`** | **`False`** | Jellyfin **ignores** the `ARTISTS`/`ALBUMARTISTS` tags — which is exactly what beets writes |
| **`UseCustomTagDelimiters`** | **`False`** | Jellyfin does **not** split `ARTIST` on `;` |
| `CustomTagDelimiters` | `['/', '|', ';', '\\']` | `;` is already in the list — the switch is off, not the delimiter |
| `DelimiterWhitelist` | `[]` | no protected names (e.g. `AC/DC`) declared |
| `SaveLocalMetadata` | `False` | Phase 1 freeze, confirmed live |
| `EnableRealtimeMonitor` | `False` | Phase 1 freeze, confirmed live |
| `SaveLyricsWithMedia` | `False` | Phase 1 freeze, confirmed live |
| `MetadataSavers` | `['Nfo']` | armed behind the gate |
| `AutomaticRefreshIntervalDays` | `0` | no periodic per-library refresh |

The prober logic both flags gate `[SOURCE: MediaBrowser.Providers/MediaInfo/AudioFileProber.cs@v10.11.11:195-250]`:
```csharp
if (libraryOptions.PreferNonstandardArtistsTag) { TryGetSanitizedAdditionalFields(track, "ARTISTS", out var s); if (s is not null) performers = s.Split(InternalValueSeparator); }
if (performers is null || performers.Length == 0) performers = trackArist.Split(InternalValueSeparator);
if (libraryOptions.UseCustomTagDelimiters) performers = performers.SelectMany(p => SplitWithCustomDelimiter(p, libraryOptions.GetCustomTagDelimiters(), libraryOptions.DelimiterWhitelist)).ToArray();
```
`InternalValueSeparator = ''`, set into ATL as `ATL.Settings.DisplayValueSeparator`. ATL joins *multiple same-named tag fields* with its own internal separator and converts it on read (`value.Replace(Settings.InternalValueSeparator, Settings.DisplayValueSeparator)` `[SOURCE: atldotnet ATL/Track.cs@main:1079]`); it does **not** split a single field containing `;`.

⇒ With today's options, a fresh probe of `ARTIST=Marshmello;P!nk;Sting` should yield **one** artist literally named `Marshmello;P!nk;Sting`. See OQ-1.

### Music Assistant

⚠ **MA was not reachable at research time.** `[MEASURED: 2026-09-20T03:26Z from LXC 100]`: `172.16.1.31` answers ICMP, but TCP **8095 closed, 8123 closed, 8096 closed**. `MA_URL=http://172.16.1.31:8095` `[MEASURED: grep of /mnt/fast/secrets/ma-deercrest.env]`. Both Music Assistant and Home Assistant are therefore down or not serving on the NUC. **D-22/D-25's MA arm is currently blocked**; re-probe before planning around it. This may be transient — it is recorded as a dated observation, not a diagnosis.

Because the API could not be exercised, MA's artist behaviour below is read from source at tag `2.10.4` (the newest stable; this estate runs `2.11.0b0`, so treat as MEDIUM confidence for 2.11):

```python
# the only multi-item splitter we accept is the semicolon,
# which is also the default in Musicbrainz Picard.
# the slash is also a common splitter but causes collisions with
# artists actually containing a slash in the name, such as AC/DC
TAG_SPLITTER = ";"
FEATURING_SPLITTERS = [" featuring ", " feat. ", " feat ", " duet with ", " presents ",
                       " ft. ", " vs. ", " vs ", " (feat. ", " (ft. ", "(feat. ", "(ft. "]
EXTRA_SPLITTERS = [" & ", ", ", " + ", " with "]
```
```python
@property
def artists(self) -> tuple[str, ...]:
    # Preferred path when unambiguously separated artist names are available
    # Vorbis: multiple ARTIST fields, ID3: TXXX:ARTISTS or multi-value TPE1
    if tag := self.tags.get("artists"):
        mb_id_count = len(self.musicbrainz_artistids)
        if isinstance(tag, list) and len(tag) > 1: artists = clean_tuple(tag)
        elif mb_id_count == 1: return (tag if isinstance(tag, str) else tag[0],)
        else: artists = split_items(tag)          # splits on ";"
        return artists
    # Fallback to single artist string, splitting if necessary
```
`[SOURCE: music_assistant/helpers/tags.py@2.10.4:37-41, 102-135, 328-350]`

So MA: **prefers the `ARTISTS` tag**, splits it on `;`, and falls back to splitting `ARTIST`. `allow_unsafe_splitters` (which adds `/` and `, `) is explicitly documented as "use for genres, not artists". ⚠ Note the `mb_id_count == 1` short-circuit: a single MusicBrainz artist id **suppresses splitting entirely** — so a track beets tags with one `mb_artistid` and a `;`-joined name would read as one artist in MA.

API shape for D-22, following `check-music-consumers.sh`'s existing helpers (`ma_login` → `POST /api {"command":..., "args":{...}}` with the JWT via `-H @<(...)`; responses are **not** `.result`-wrapped; `music/albums/count` **silently ignores** its `provider` argument, so use `music/albums/library_items` with an explicit `provider` instance id `filesystem_local--XJaJWNUS`). The track-level analogue is `music/tracks/library_items`, whose track objects carry an `artists: [...]` list. **NOT VERIFIED — the command name and response shape could not be confirmed against the live server.** Confirm against `GET /api-docs/commands.json` (the script's own authority) before writing it into a plan.

---

## P5 — Incremental, the write-side delimiter, and the rest

### P5a — `incremental` / `incremental_skip_later` mechanics (D-31)

Defaults: `incremental: no`, `incremental_skip_later: no` `[SOURCE: beets/config_default.yaml@v2.12.0 and @v2.13.1 — identical]`.

**Where the state lives.** Not in `library.db`. `ImportState` pickles `{"tagprogress": {...}, "taghistory": set()}` to `config["statefile"].as_filename()` `[SOURCE: beets/importer/state.py@v2.12.0]`:
- `taghistory` — a `set` of `tuple(paths)` per completed album. This is the **incremental** log.
- `tagprogress` — `{toppath: [paths]}`. This is the **resume** log.

**What gets recorded, and when.**
```python
def finalize(self, session):
    if session.want_resume: self.save_progress()
    if session.config["incremental"] and not (self.skip and session.config["incremental_skip_later"]):
        self.save_history()
    self.cleanup(...)
```
`[SOURCE: beets/importer/tasks.py@v2.12.0:310-322]`
```python
def save_history(self): ImportState().history_add(self.paths)
```
So: with `incremental: yes` and `incremental_skip_later: no`, a **skipped** task still calls `save_history()` — the folder is permanently marked done. With `incremental_skip_later: yes`, the skip is not recorded and the folder is re-offered. **That is the trap, exactly as the ROADMAP states it, now with the line number.**

**How the skip is detected on the next run:**
```python
def already_imported(self, toppath, paths):
    if self.is_resuming(toppath) and all(ImportState().progress_has_element(toppath, p) for p in paths): return True
    if self.config["incremental"] and tuple(paths) in self.history_dirs: return True
    return False
```
`[SOURCE: beets/importer/session.py@v2.12.0:255-270]` — with `history_dirs` cached per session (`_history_dirs`). Note `set_config` forces `resume: False` whenever `incremental` is truthy `[SOURCE: session.py@v2.12.0:111-114]`, so the two are mutually exclusive by construction.

**D-31's negative control, as a concrete design.** `finalize` is not reached under `--pretend`, so the control must use a real (in-place) import. Everything below writes only to `/tmp` inside the container.

1. Overlay A: `library: /tmp/p6a/lib.db`, `statefile: /tmp/p6a/state.pickle`, `directory: /tmp/p6a/tree`, `import: {incremental: yes, incremental_skip_later: no, copy: no, move: no, write: no, autotag: no, quiet: yes, quiet_fallback: skip}`.
   ⚠ `import.copy` and `import.move` are both `Literal` in rc6's schema — but an **overlay passed to `beet -c` is not validated by rc6**, only the file at `$BEETSDIR/config.yaml` is. Confirm that before relying on it; if it bites, use `copy: yes` into `/tmp/p6a/tree` instead.
   ⚠ `write: no` keeps the source files untouched — essential, since `/mnt/tank/downloads` is `rw`.
2. Import one throwaway folder, forcing a **skip** (e.g. `quiet_fallback: skip` with `autotag: yes` and no match, or answer `s`). Assert `taghistory` now contains its path tuple: `python -c "import pickle;print(pickle.load(open('/tmp/p6a/state.pickle','rb'))['taghistory'])"`.
3. Re-run the same import; assert the run reports `Skipped 1 paths.` (`stages.py:71-73`) and offers nothing. **This is the "permanently marked done" half.**
4. Overlay B: same, fresh `/tmp/p6b`, `incremental_skip_later: yes`. Repeat 2-3; assert `taghistory` is **empty** after the skip and the folder **is** re-offered on the second run.
5. Assert the real `state.pickle` and `library.db` sha256 are unchanged throughout (D-29 layer 3).

The control discriminates because step 3 and step 4 differ in exactly one config key and produce opposite observable outcomes — which is what "prove capable of failing" means here.

### P5b — the multi-artist write delimiter (D-23): beets cannot be configured to emit `;`

```python
for el in artist_credits:
    joinphrase = el["joinphrase"]
    for name, parts, multi in ((artist_object["name"], artist_parts, artists), ...):
        parts.extend([name, joinphrase]); multi.append(name)
return {"artist": "".join(artist_parts), ..., "artists": artists, ...}
```
`[SOURCE: beetsplug/musicbrainz.py@v2.12.0:341-367]`, docstring: *"MusicBrainz represents credits as a sequence of credited artists, each with a display name and a `joinphrase` (for example `' & '`, `' feat. '`, or `''`)."*

`item.artist` is therefore **MusicBrainz's own join phrases**, verbatim. `grep -i "sep\|delim\|join"` over `config_default.yaml` at both versions returns only `path_sep_replace`, `drive_sep_replace` and a comment about path separators `[MEASURED: 2026-09-20]` — **there is no write-delimiter key.** (`lastgenre.separator` exists but is genre-only; `gui.library.artist_separators` exists but is a beets-flask *display* setting.)

What beets *does* write:

| beets field | MP3 | Vorbis (FLAC) | Value |
|---|---|---|---|
| `artist` | `TPE1` | `ARTIST` | one string, MB join phrases |
| `artists` | **`TXXX:ARTISTS`** | **`ARTISTS`** | the per-artist list |
| `albumartist` | `TPE2` | `ALBUM ARTIST` / `ALBUM_ARTIST` / `ALBUMARTIST` | one string |
| `albumartists` | `TXXX:ALBUMARTISTS` | `ALBUMARTISTS` | list |

`[SOURCE: mediafile/__init__.py@master:395-406, 538-560]` — `artists = ListMediaField(MP3ListDescStorageStyle(desc="ARTISTS"), …, ListStorageStyle("ARTISTS"), …)`. List values are stored as multiple text values in **one** frame (`MP3ListDescStorageStyle.store` builds a single `TXXX` frame with `text=values`, encoding UTF-8) `[SOURCE: mediafile/storage/mp3.py@master:194-219]`; in ID3v2.4 mutagen serialises those NUL-separated.

⇒ **Honest statement of what the pipeline actually produces:** beets writes multi-artist information as a *multi-valued `ARTISTS` tag*, not as a `;`-joined `ARTIST`. MA reads that natively. Jellyfin reads it only with `PreferNonstandardArtistsTag` on. The `;` in CONF-04 is a property of the **existing** library's 12 files, not of anything beets will write.

### D-20 answered offline: the exhaustive delimiter survey, already done

`[MEASURED: 2026-09-20, all 1,244 library records in /mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz, keys folded to {artist, artists, album_artist, albumartist, albumartists, band, performer}]`

| Tag key | delimiter | library files |
|---|---|---|
| `ARTISTS` | `;` | **6** |
| `ARTIST` | `;` | **6** |
| `album_artist` | `, ` | 16 |
| `ARTIST` | `, ` | 15 |
| `Artist` | ` & ` | 11 |
| `ARTIST` | ` & ` | 1 |
| `artist` | `, ` | 1 |

Albums touched by the `;` set: `P!nk/TRUSTFALL (2023)` ×6 (in `ARTIST`), `P!nk/The Truth About Love (2012)` ×3, `Lady Gaga/ARTPOP (2013)` ×2, `Katy Perry/Teenage Dream (2010)` ×1 (the last three in `ARTISTS`).

Worked examples:
- `ARTIST = "Marshmello;P!nk;Sting"` — `…/TRUSTFALL (2023)/CD 02-01 P!nk - Dreaming.flac` — **three** artists, the strongest single candidate.
- `ARTISTS = "Lady Gaga;T.I.;Too $hort;Twista"` — `…/ARTPOP (2013)/CD 01-05 Lady Gaga - Jewels n' Drugs.flac` — **four** artists in the tag beets actually writes.
- `ARTISTS = "Katy Perry;Snoop Dogg"` — `…/Teenage Dream (2010)/CD 01-03 Katy Perry - California Gurls.flac`.

One false positive to exclude explicitly: `/mnt/tank/downloads/.../14. Busta Rhymes Feat; Q-Tip , Kanye West & Lil Wayne - Thank You.mp3` carries `artist = "Busta Rhymes Feat; Q-Tip , Kanye West & Lil Wayne"` — a `Feat;` typo, not a delimiter. It is in `unsorted`, not the library.

⇒ **D-21's fenced write with the scoped `rw` grant is NOT required.** D-20's primary route has candidates in both tag positions, with 2-, 3- and 4-artist cases. The `:ro` invariant can stay unbroken for the whole phase. (D-21 stays written into the plan as the pre-authorised fallback, per the decision — it simply should not fire.)

Jellyfin's current view of that set `[MEASURED: 2026-09-20 GET /Items?IncludeItemTypes=Audio&Fields=ArtistItems…, 1244 of 1244 returned]`: exactly **6** items have more than one `ArtistItems` entry — all six of the `ARTIST`-delimited TRUSTFALL tracks, with correctly separated names and distinct Ids. **None** of the six `ARTISTS`-delimited tracks is split, which is consistent with `PreferNonstandardArtistsTag: False`. See OQ-1 for why the first six are the puzzle.

---

## Common Pitfalls

### Pitfall 1 — `--pretend` reads as a pass because it prints a lot of lines
**What goes wrong:** a `--pretend` run over the sample prints one line per file and exits 0; a reader takes that as "the tree is right".
**Why:** the pipeline is `read_tasks → log_files`; those lines are the *source* paths.
**How to avoid:** the oracle asserts on `beet move -p` output, which contains ` -> `. Add a class assertion that every oracle line contains ` -> ` (or the two-line `  -> ` form), and that the count of ` -> ` lines equals the sampled file count. A `--pretend` transcript will fail that trivially.
**Warning sign:** the output contains no `/mnt/tank/media/Music/` substring at all.

### Pitfall 2 — beets-flask silently installs a destructive config
**What goes wrong:** the container starts before the vendored config is mounted (or `BEETSDIR` points somewhere unexpected), rc6 copies its example in, and `embedart.auto: yes` + `lastgenre.auto: yes, force: yes` + `asciify_paths: yes` become the effective config.
**How to avoid:** assert `$BEETSDIR/config.yaml` exists and matches the vendored sha256 **before** first start; after first start, assert the log does **not** contain `Beets config not found at` or `Copying default config to`.
**Warning sign:** a `/config/beets/config.yaml` whose `plugins:` list is 18 entries long.

### Pitfall 3 — an absent key is rc6's default, not beets' default
**What goes wrong:** `import.duplicate_action` unset → flask commits `remove`. Duplicates are deleted with no prompt.
**How to avoid:** set `directory`, `import.duplicate_action`, `match.medium_rec_thresh` explicitly. Assert them from the *server's* committed config, not from `beet config -d`.
**Warning sign:** `beet config -d` shows `duplicate_action: ask` while the UI removes duplicates. The two are both telling the truth about different objects.

### Pitfall 4 — `-l` does not move the state file
**What goes wrong:** a throwaway import writes the real `state.pickle`, silently poisoning `incremental` for the real library.
**How to avoid:** always use a `-c` overlay setting `library`, `statefile` **and** `directory`. Assert the real `state.pickle` sha256 is unchanged (D-29 layer 3 should name it alongside `library.db`).
**Warning sign:** `state.pickle`'s mtime moves during a run that was supposed to write nothing.

### Pitfall 5 — `albumtype:dj` is a substring match
**What goes wrong:** the DJ rule captures releases whose `albumtype` merely contains `dj`, or (worse) fails to capture and everything silently falls through to `default`, which still produces a valid-looking tree.
**How to avoid:** `albumtype:=dj` (exact). Add a class assertion that the count of oracle lines under `DJ/` equals the count of sampled DJ folders — **an equality, not a floor**.

### Pitfall 6 — `%aunique{}` against a throwaway library under-reports
**What goes wrong:** D-16 asks for every firing to be reported; a bare throwaway library has no collisions to find, so the report is empty and reads as "no risk".
**How to avoid:** either run the oracle against a copy of the real `library.db` opened by flask's 2.12.0, or label the count a lower bound in the report itself.
**Warning sign:** `%aunique{}` fires zero times on a sample drawn from a library with 828 measured duplicate groups.

### Pitfall 7 — `per_disc_numbering` left at its default
**What goes wrong:** `$disc-$track` renders `02-17` instead of `02-05` for disc 2 track 5, because `$track` is the absolute index. It looks like a number, sorts plausibly, and is wrong.
**How to avoid:** `per_disc_numbering: yes`, and put a multi-disc release in the sample (D-26 already requires it) whose disc-2 first track is known.

### Pitfall 8 — the targeted Jellyfin scan is read back too early
**What goes wrong:** `POST /Library/Media/Updated` returns 204 immediately; a read-back 10 s later shows nothing and reads as a failure.
**How to avoid:** `LibraryMonitorDelay` is **60 s** on this server. Wait ≥ 90 s, and distinguish "not yet" from "did not happen" by watching the Jellyfin log for `… will be refreshed.` (`FileRefresher.cs:144`).

### Pitfall 9 — a `docker exec` without `/venv/bin`
**What goes wrong:** `docker exec beets-flask beet …` → `executable file not found`. Or worse, it finds a *different* `beet` and reads a different config.
**How to avoid:** absolute `/venv/bin/beet`, and `-u beetle`.

### Pitfall 10 — running the oracle from macOS
**What goes wrong:** the estate's standing rule. `timeout N cmd | wc -l` exits 0 silently; macOS has no GNU `timeout`; `sed $'\033'` not `\x1b`.
**How to avoid:** bound remote commands Linux-side, `set -o pipefail` inside the remote string, read the ssh RC on the next line.

---

## Runtime State Inventory

This is a configuration phase, not a rename — but it touches five stores that a file-level audit would miss.

| Category | Items found | Action required |
|---|---|---|
| **Stored data** | `/mnt/fast/appdata/arrs/beets/config/library.db` (53,248 B, mtime 2026-09-11) and `state.pickle` (47 B, mtime 2025-11-18) `[MEASURED]`. beets-flask adds its **own** DB via `run_migrations()` plus a Redis queue, both created at first start. | sha256 both beets files before/after every run (D-29 layer 3). Record the flask DB's path once it exists. |
| **Live service config** | Jellyfin's Music-library options live in Jellyfin's config DB, not in git — `PreferNonstandardArtistsTag`, `UseCustomTagDelimiters`, `SaveLocalMetadata`, `MetadataSavers` all measured above. MA's provider config likewise (`filesystem_local--XJaJWNUS`). | If OQ-1 is resolved by flipping a Jellyfin library option, that change is **not** captured by any repo file — record it in `beets.md` and add it to `check-music-consumers.sh`'s assertions. |
| **OS-registered state** | None. No systemd unit, timer, cron entry or Task Scheduler entry is created by this phase. `scripts/quick-health-check.sh` remains manual-only (Phase 02.1 D-22). | None — stated explicitly. |
| **Secrets / env vars** | `/mnt/fast/secrets/jellyfin-deercrest.env` and `/mnt/fast/secrets/ma-deercrest.env`, both mode `600 root` and asserted so by `check-music-consumers.sh:496-527`. **No beets credential exists and none must be created** (Phase 4 D-24). rc6 needs no secret. | None new. Do not add a Discogs token to the vendored config; the repo is public. |
| **Build artifacts / installed packages** | rc6's `uv pip install -r /config/requirements.txt` installs into the container's `/venv` at **every start** — an unpinned requirement would silently move the beets version. | Write `beets==2.12.0` as an exact pin, and assert `beets.__version__` at runtime. Both halves, per Phase 3's OD-2. |
| **Inbox tree (live, changed since Phase 5)** | `02-review/` holds `Madonna/` and `Michael Jackson/`; `99-quarantine/` holds two `_FAILED_Garth.Brooks…` dirs `[MEASURED: 2026-09-20]`. | Decide before registering `02-review`: clearing it, or accepting that registration enqueues two real preview tasks. See C-5. |

---

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| LXC 100 `selfhost` over ssh | everything | ✓ | — | — |
| Docker on LXC 100 | flask + survivor | ✓ | — | — |
| Jellyfin | D-22/D-24 | ✓ | 10.11.11, reachable at `192.168.90.17:8096` on `t3_proxy` | — |
| Jellyfin API key | D-22/D-24 | ✓ | `/mnt/fast/secrets/jellyfin-deercrest.env`, mode-gated | — |
| Jellyfin `/api-docs/openapi.json` | endpoint discovery | ✗ | returns **500** | use the published `jellyfin-openapi-10.11.11.json` (done — see § P4) |
| **Music Assistant** | D-22/D-25 | **✗** | `172.16.1.31:8095` **closed** at 2026-09-20T03:26Z (8123 also closed; host answers ICMP) | **None.** D-25 already sequences MA last and "only if needed" — but if MA stays down, criterion 4's MA half is UNKNOWN, not green. |
| Home Assistant (NUC) | MA's host | ✗ | `8123` closed | — |
| `beets.deercrest.info` DNS | D-07 | ✓ | resolves to two Cloudflare proxied addrs; **no wildcard exists** | — |
| Inbox directories | D-06, rc6 `validate()` | ✓ | all six present, `568:568` | — |
| `/mnt/fast` free space | rc6 `/config`, `/venv`, `/logs` | ⚠ | `/mnt/fast` is **not a mountpoint** — it is on LXC 100's 126 G ext4 root, **95 G used, 25 G avail, 80 %** | Known backlogged defect. Watch `/` headroom; `check-jellyfin-transcode.sh` already asserts a floor. |
| Phase 1 tag snapshot | D-20, D-18, D-26 | ✓ | `/mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz`, 9,736 records incl. all 1,244 library files | — |
| `slopcheck` | package audit | ✓ (workstation) | crashes *after* reporting, because `pip` is absent | audit output is still valid |
| `ctx7` | documentation lookup | ✗ | not installed | all library facts here came from pinned upstream source instead |

**Missing with no fallback:** Music Assistant. **Missing with fallback:** Jellyfin's self-served OpenAPI (use the published spec), Context7 (use source).

---

## Validation Architecture

**Framework:** this repository has **no** unit-test framework. There is no `tests/`, no `pytest.ini`, no `package.json`, no `setup.cfg` `[MEASURED: 2026-09-20 ls]`. Validation is done by assertion scripts that exit 0/1, plus in-script `--self-test` modes (`scripts/normalise-dj-tags.py`, `scripts/spike03-wrtag-arms.sh`).

| Property | Value |
|---|---|
| Framework | bash + python3 assertion scripts; `scripts/quick-health-check.sh` is the single entry point |
| Config file | none — by design |
| Quick run command | `scripts/check-music-freeze.sh` (from the repo root, ssh-delegating) |
| Full suite command | `scripts/quick-health-check.sh` (folds in `check-music-freeze.sh`, `check-music-consumers.sh`, `check-jellyfin-transcode.sh`) |
| Sampling rate | per task: the task's own assertion block; per wave: `check-music-freeze.sh`; phase gate: `quick-health-check.sh` exit 0 |

### Phase requirements → test map

| Req | Behaviour to prove | Type | Command | Exists? |
|---|---|---|---|---|
| CONF-01 | `copy: yes` / `move: no` in the **server's committed** config | assertion | `docker exec -u beetle beets-flask /venv/bin/python -c "…get_config(commit_to_beets=True); print(beets.config.dump(full=True))"` + grep | ❌ Wave 0 |
| CONF-02 | `incremental: yes` **and** `incremental_skip_later: yes` read back | assertion | as above | ❌ Wave 0 |
| CONF-02 | the trap **fires** and is **defeated** (D-31) | driven negative control | two `-c` overlays; assert `taghistory` contents and the re-offer, per § P5a | ❌ Wave 0 |
| CONF-03 | every oracle top-level == an `ALBUMARTIST`, case-exact; `Various Artists/` present; `Compilations/` absent | oracle diff + class assertion | `beet move -p` output vs the committed expected tree | ❌ Wave 0 |
| CONF-04 | N distinct artist entities in Jellyfin | API read-back | `GET /Items?…&Fields=ArtistItems` and assert `len(ArtistItems) == N` per candidate | ⚠ extend `check-music-consumers.sh` |
| CONF-04 | N distinct artist entities in MA | API read-back | `music/tracks/library_items` + `artists[]` | ❌ **blocked** — MA unreachable |
| CONF-04 | write side: what beets would emit | oracle | assert the beets fields the import would write (`artist`, `artists`) on the sampled multi-artist release | ❌ Wave 0 |
| CONF-05 | `preferred.countries` contains `GB` (not `UK`), `original_year`, `musicbrainz.extra_tags` | assertion | committed-config read-back | ❌ Wave 0 |
| CONF-05 | a *Now!* volume prefers the UK release | driven | **cannot** be `--pretend`. Needs a real candidate lookup — `beet import -t` on a throwaway, or flask `preview`, reading the chosen candidate's `country` | ❌ Wave 0 |
| CONF-06 | zero-diff against the committed expected tree | oracle diff | `diff <(beet move -p …) 06-EXPECTED-TREE.txt` | ❌ Wave 0 |
| D-09 | three inboxes registered | log assertion | grep the startup log for the `Registering watchdog … for inboxes: [...]` line; **fail closed on < 3** | ❌ Wave 0 |
| D-09 | an inbox actually fires | driven | one throwaway folder into `02-review`, wait ≥ 35 s (`debounce_before_autotag: 30`), confirm a preview task, remove | ❌ Wave 0 |
| D-11 | exactly two tagger definitions, **named and classed** | assertion | revise `check-music-freeze.sh:793-801`; the pattern already matches `beets-flask` | ⚠ revise in place |
| D-29 | wrote nothing, three layers | assertion | (1) `docker inspect` mount RW=false on `/media`; (2) sha256 manifest over sampled source folders; (3) sha256 of `library.db` **and** `state.pickle` | ❌ Wave 0 |

### Wave 0 gaps

- [ ] `scripts/check-beets-config.sh` — reads the **server-committed** config and asserts CONF-01/02/03/05 keys. Must distinguish "could not look" from "correct".
- [ ] `scripts/phase06-oracle.sh` — runs the throwaway import + `beet move -p`, emits the path-change list in a stable, diffable form.
- [ ] `.planning/phases/06-…/06-EXPECTED-TREE.txt` — committed **before** the first oracle run (D-27).
- [ ] `.planning/phases/06-…/06-SAMPLE.md` — the seeded draw, committed before any run (D-26).
- [ ] `scripts/phase06-incremental-control.sh` — D-31's two-overlay negative control.
- [ ] `check-music-freeze.sh` — revise the tagger census to `expected=2, named` (D-11) and add the throwaway-`-l` assertion (D-04); `quick-health-check.sh` — extend the vendored-file drift block to cover **two** consumers of one file (D-03).
- [ ] `check-music-consumers.sh` — add the per-consumer artist-entity check (D-22), reusing the existing `jf_api`/`ma_api` argv-safe helpers.
- [ ] No framework install needed. Do **not** introduce pytest for this phase.

---

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1`.

| ASVS category | Applies | Standard control, as it lands here |
|---|---|---|
| V2 Authentication | **yes** | beets-flask ships **no authentication of any kind** and a tmux-backed web terminal with shell access (`gui.terminal.enabled` defaults **true**, `start_path` defaults `/repo`). D-07 puts it behind Traefik + `chain-authelia@file` with **no host port**. That chain is the only auth. |
| V3 Session Management | yes (delegated) | Authelia owns sessions. ⚠ The estate's standing failure mode: a bare `431 Request Header Fields Too Large` on any `*.deercrest.info` is Authelia's `server.buffers.read: 4096`, not the app — and **`curl` sends no cookies**, so a curl smoke test passes while every browser fails. |
| V4 Access Control | **yes** | The container mounts `tank`. Anyone who reaches the page gets a shell inside it. Consider `gui.terminal.enabled: false` for Phase 6 — the phase needs no terminal, and Phase 3's rationale for keeping it (ergonomics measurement) has been discharged. |
| V5 Input Validation | yes | eyconf/jsonschema validates the config. ⚠ Friction 9: a validation failure **kills the watchdog while the server keeps serving a page** — inboxes go inert behind a UI that looks alive. D-09's two-part liveness proof exists for exactly this. |
| V6 Cryptography | no | No credential is introduced. The vendored config must stay credential-free; **this repository is public and already carries one exposure recoverable via `git log -S`**. |
| V7 Error handling / logging | yes | `LOG_LEVEL_BEETSFLASK: DEBUG` writes to `/logs` **inside the container writable layer**, i.e. LXC 100's ext4 root at 80 % used. Either bind `/logs` to `/mnt/fast` or keep the level at INFO. |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Unauthenticated web shell reachable from the LAN | Elevation of Privilege | `networks: [t3_proxy]` **and** no `ports:`; Traefik router with `chain-authelia@file`. WR-02's lesson: a `traefik.enable=true` label with a missing `networks:` key makes the auth illusory while a host port serves unauthenticated. Both halves must be asserted from `docker inspect`, not read from the file. |
| `docker compose config` leaking an env-file value | Information Disclosure | No `env_file` is needed here (no credential). If one is ever added, render with `--no-env-resolution`. |
| Credential in argv on a host with a world-readable process table | Information Disclosure | Reuse `check-music-consumers.sh`'s `-H @<(printf …)` process-substitution pattern for every Jellyfin/MA call. Never `-e TOKEN=` on a `docker exec`. |
| Unpinned startup `pip install` moving the runtime under the measurement | Tampering | Exact pin **plus** runtime `beets.__version__` assertion. A pin without verification and a verification without a pin are each half a control. |
| Two services claiming `beets.deercrest.info` | Denial of Service | D-07 removes the survivor's traefik labels. Assert that exactly one router rule in the whole of `stacks/` carries that Host(). |

---

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | MA 2.11.0b0's artist parsing matches the 2.10.4 source read here (`TAG_SPLITTER=";"`, `ARTISTS` preferred). | P4 | CONF-04's MA half could behave differently. Low risk — the comment block naming `;` as "the only multi-item splitter we accept" has been stable — but MA was unreachable, so nothing was confirmed live. |
| A2 | `music/tracks/library_items` is the MA command whose objects carry `artists[]`. | P4 | The D-22 MA check would need rewriting. Resolve against `GET /api-docs/commands.json` — the script's own stated authority. |
| A3 | A `-c` overlay passed to `beet` is **not** run through rc6's eyconf validation (only `$BEETSDIR/config.yaml` is). | P5a | If wrong, `import.copy: no` in a throwaway overlay would be rejected and the D-31 control needs `copy: yes` into `/tmp` instead. Cheap to test. |
| A4 | `docker exec` into the rc6 container inherits the image `ENV` (`BEETSDIR`, `BEETSFLASKDIR`). | P3 | Standard Docker behaviour, but if wrong the exec would read the wrong config and `beet config -d` would be meaningless. One-command check. |
| A5 | The python one-liner shape for dumping the server-committed config (`get_config(commit_to_beets=True)` then `beets.config.dump`) works as written. | P3 | D-30 arm 1 would need a different instrument. The API is public in `beets_config.py`; the exact call was not executed. |
| A6 | The MA/HA outage observed at 2026-09-20T03:26Z is transient. | Env | If MA stays down, criterion 4's MA half is UNKNOWN for the phase. |
| A7 | `beet move -p` on a library whose items were imported in place lists every item (none "already in place"). | P3 | If items land at their destination by coincidence the oracle would under-report. Guarded by reading the `(N already in place)` line. |

---

## Open Questions

### OQ-1 — Why does Jellyfin currently show three artists for a file it should show one for? *(highest planning impact)*

**What we know.** `ARTIST = "Marshmello;P!nk;Sting"` in a single Vorbis comment `[MEASURED: ffprobe]`. Jellyfin reports `ArtistItems = [Marshmello, P!nk, Sting]` with distinct Ids `[MEASURED: GET /Items]`. The Music library has `UseCustomTagDelimiters = False` and `PreferNonstandardArtistsTag = False` `[MEASURED]`. 10.11.11's prober splits on `CustomTagDelimiters` **only** when the former is true `[SOURCE: AudioFileProber.cs:227-246]`. ATL joins multiple same-named fields with an internal separator and converts it on read; it does **not** split a single field on `;` `[SOURCE: atldotnet ATL/Track.cs:1079, ATL/Settings.cs:63-72]`. There is no `.nfo` in that album directory `[MEASURED: ls]`. And the six `ARTISTS`-delimited files are **not** split, which is exactly what `PreferNonstandardArtistsTag: False` predicts — so the settings clearly are in force for that path.

**What's unclear.** Whether the three-artist state is stale DB content from a Jellyfin version whose prober split unconditionally (`UseCustomTagDelimiters` is a 10.10-era addition), or whether some read path not traced here still splits.

**Why it matters.** If it is stale, then (a) the observation is *not* evidence that Jellyfin parses `;` today, and (b) **D-24's targeted rescan could collapse those six entries to one artist each** — destroying the evidence criterion 4 is built on, inside the library, during a phase whose whole premise is that it writes nothing. That would not violate the `:ro` fence (the change is in Jellyfin's DB, not the tree) but it would be an irreversible-ish change to the consumer's view.

**Recommendation.** Do not resolve this by rescanning the candidate album. Resolve it by **decision**, and take it to the operator as such:
- **Option A (recommended):** enable `PreferNonstandardArtistsTag` on the Music library. This aligns Jellyfin with the tag beets actually writes (`ARTISTS`) and with what MA already prefers — it makes the two consumers agree *by construction* rather than by coincidence, which is what CONF-04 is really asking for. Cost: the six `ARTISTS` files start splitting; the six `ARTIST` files would need `UseCustomTagDelimiters` too.
- **Option B:** enable `UseCustomTagDelimiters` (`;` is already in `CustomTagDelimiters`). Matches the existing 12 files, but not what beets will write.
- **Option C:** enable both. Widest coverage; also the widest blast radius on a 1,244-file library, since `/` and `|` and `\` come along with `;` unless `CustomTagDelimiters` is narrowed to `[';']` and `DelimiterWhitelist` is populated (`AC/DC` is the canonical casualty).
Whichever is chosen, it is a **live-service config change not captured in git** — record it in `beets.md` and assert it in `check-music-consumers.sh`.

### OQ-2 — How does `albumtype=dj` get set on a real flask-driven import? (C-6)

**What we know.** `--set` is a `beet import` CLI flag backed by `import.set_fields`. rc6's `InboxFolderSchema` has no per-inbox field-setting mechanism. D-04 forbids the CLI arm from opening the real library.
**What's unclear.** Whether rc6's UI exposes anything equivalent (a per-task field edit before import), and whether a global `import.set_fields` could be scoped by inbox some other way.
**Recommendation.** Phase 6 proves the **path rule** with `--set` on a throwaway library — that is sufficient for CONF-03/CONF-06. Register the *mechanism* gap explicitly as a Phase 7 routing-time item alongside the `bootleg` album-populated gate, which is already carried there.

### OQ-3 — Which library does the oracle run against?

`%aunique{}` and beets' duplicate detection are library-relative. A bare throwaway under-reports (Pitfall 6); a copy of the real `library.db` reports correctly but must be opened by flask's 2.12.0 (D-04) and must be a copy, not the file. **Recommendation:** copy `library.db` to `/tmp/p6/lib.db` inside the flask container, import the sample in place against it, run `beet move -p`, and assert the original's sha256 is unchanged. Record explicitly which was used, because the aunique count is only meaningful with that label attached.

### OQ-4 — Does rc6's `preview` produce destination paths at all?

D-30 arm 2 is the cross-check. Phase 3 recorded that the preview UI shows candidate selection, but **no record exists of whether it shows the computed destination paths** the oracle diff needs. If it does not, "the two arms agree" has to be defined on something else (e.g. the chosen MBID and the resulting `albumartist`/`album`/`track` triple) rather than on paths. Resolve by inspection once the container is up — cheap, and it must be resolved before the plan writes the comparison.

---

## Sources

### Primary (HIGH confidence — pinned source at the exact running version)

- `github.com/beetbox/beets` @ **v2.12.0** — `beets/config_default.yaml`, `beets/importer/{session,stages,tasks,state}.py`, `beets/library/{models,fields,queries}.py`, `beets/util/pathformats.py`, `beets/dbcore/{types,query,queryparse}.py`, `beets/ui/__init__.py`, `beets/ui/commands/{move,config}.py`, `beets/autotag/hooks.py`, `beetsplug/musicbrainz.py`
- `github.com/beetbox/beets` @ **v2.13.1** — `beets/config_default.yaml`, `beets/library/models.py`, `beets/util/pathformats.py`, `pyproject.toml` (diffed against v2.12.0)
- `github.com/beetbox/mediafile` @ **master (0.17.x)** — `mediafile/__init__.py`, `mediafile/constants.py`, `mediafile/storage/{mp3,base}.py`
- `github.com/metasauce/beets-flask` @ **v2.0.0-rc6** — `backend/beets_flask/config/{schema.py,beets_config.py,config_b_example.yaml,config_bf_example.yaml}`, `docker/Dockerfile`, `docker/entrypoints/{entrypoint,entrypoint_fix_permissions,entrypoint_user_scripts}.sh`, `docker/docker-compose.yaml`
- `eyconf` **0.8.0** (PyPI wheel) — `eyconf/config/extra_fields.py`, `eyconf/config/base.py`
- `github.com/jellyfin/jellyfin` @ **v10.11.11** — `Jellyfin.Api/Controllers/LibraryController.cs`, `Emby.Server.Implementations/IO/{LibraryMonitor,FileRefresher}.cs`, `MediaBrowser.Providers/MediaInfo/AudioFileProber.cs`, `MediaBrowser.Model/Configuration/LibraryOptions.cs`
- `repo.jellyfin.org/files/openapi/stable/jellyfin-openapi-10.11.11.json` — endpoint/schema definitions
- `github.com/music-assistant/server` @ **2.10.4** — `music_assistant/helpers/tags.py`
- `github.com/Zeugma440/atldotnet` @ master — `ATL/Settings.cs`, `ATL/Track.cs`, `ATL/AudioData/IO/VorbisTag.cs`
- `github.com/beetbox/confuse` @ master — `confuse/core.py` (`Subview.keys`/`items`)

### Live estate measurements (2026-09-20, read-only, from LXC 100 `selfhost`)

- `docker ps` → `jellyfin/jellyfin:10.11.11`
- `GET /System/Info`, `GET /Library/VirtualFolders`, `GET /Items?IncludeItemTypes=Audio&Fields=ArtistItems,Artists,AlbumArtist,Path&Limit=5000` (1,244 of 1,244)
- `ffprobe -show_entries format_tags` on `CD 02-01 P!nk - Dreaming.flac`
- `grep -oE '<LibraryMonitorDelay>[^<]*<' /mnt/fast/appdata/media/jellyfin/config/system.xml` → 60
- `zcat /mnt/fast/safety/music-pre-project/tags/pre-project.ndjson.gz` — 9,736 records, aggregated by extension and by tag key; full delimiter survey over the 1,244 library records
- `ls -la` of `/mnt/fast/appdata/arrs/beets/config/`, `/mnt/tank/downloads/complete/nzb/_inbox/*`, the TRUSTFALL album dir
- `getent hosts beets.deercrest.info` and a random-name wildcard control
- TCP probes of `172.16.1.31:{8095,8123,8096}`
- `findmnt /mnt/fast` (not a mountpoint), `df -h /`
- `docker inspect jellyfin --format '{{range .Mounts}}…'`

### Repository (this project's own prior measurements)

- `.planning/phases/06-…/06-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md:858-885`
- `.planning/phases/03-tagger-spike/03-BEETS-FLASK.md` (frictions 1-9, the watchdog log line, OD-2, the slopcheck audit)
- `.planning/phases/03-tagger-spike/03-spike-beets-flask.yaml` (the measured rc6 deployment shape)
- `.planning/phases/05-…/05-INBOX-PATHS.md` (the six measured inbox paths, devids, the D-18 prohibition)
- `stacks/selfhosted/arrs/beets/{config.yaml,beets.yaml}`, `stacks/selfhosted/arrs/beets.md:1232,1255,1327`
- `scripts/normalise-dj-tags.py` (lines 85-135, 280-340, 624-850 — the measured mutagen/WAV contract)
- `scripts/check-music-consumers.sh` (lines 107-200, 370-441, 975-1050 — the argv-safe API helpers and the MA shape notes)
- `scripts/check-music-freeze.sh:755-801` (the tagger census D-11 revises)

### Tertiary (LOW — marked for validation)

- The MA command name `music/tracks/library_items` (A2) — inferred from the album-side command's shape; **not** confirmed against `commands.json`.
- OQ-1's "stale DB state" explanation — the best-supported reading of five measured facts, but not directly observed.

---

## Metadata

**Confidence breakdown:**
- Standard stack / versions — **HIGH**. Every version read from a pinned tag or the live host.
- beets path-format and importer semantics — **HIGH**. Read from source at both versions and diffed.
- beets-flask rc6 internals — **HIGH** for source-read behaviour (schema, entrypoints, config injection); **MEDIUM** for the exec/dump invocations, which were not executed because no container exists yet (A4, A5).
- DJ field map per format — **HIGH**. mediafile source + this repo's own measured WAV contract + a 9,736-file corpus census.
- Jellyfin endpoints and library options — **HIGH**. Version-exact OpenAPI plus live read-back plus source trace of the refresh path.
- Jellyfin's current artist-splitting behaviour — **MEDIUM**, and flagged as OQ-1: the measurement and the source disagree, and the disagreement is the finding.
- Music Assistant — **MEDIUM**. Source-read at 2.10.4; **the live service was unreachable**, so nothing was confirmed against 2.11.0b0.
- D-20's delimiter survey — **HIGH**. Exhaustive over all 1,244 library files, offline, from Phase 1's fence.

**Research date:** 2026-09-20
**Valid until:** 2026-10-20 for the pinned-source facts (beets 2.12.0 / rc6 / Jellyfin 10.11.11 do not move). **7 days** for the live-estate readings — MA's outage, `/` at 80 %, and the two folders sitting in `02-review` are all current-state observations that will have changed.
