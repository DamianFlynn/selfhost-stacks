# Phase 6: Tagger Configuration and Dry Run - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

The surviving tagger's configuration is shown to produce the intended tree **on paper**, at the last
cheap moment before a path-format error can be applied at scale.

**This phase writes nothing into the library.** `/mnt/tank/media` stays `:ro` for both containers
for the whole phase (D-05). The single named exception is criterion 4's fallback route, which is
pre-authorised, fenced and bounded (D-20, D-21).

**In scope, beyond the ROADMAP's six criteria:** standing up beets-flask. Phase 5's D-16 assigned it
here explicitly, and the operator confirmed that assignment rather than deferring it a third time
(Phase 4 D-01 → Phase 5 D-16 → here). The phase therefore delivers *the configuration and the thing
that will execute it*, proven together.

**Out of scope:** any real import (Phase 7); BPM/key analysis for untagged DJ tracks (own phase,
D-18); the beets-flask folder-count lag risk (Phase 9, D-08); the `bootleg` album-populated gate
(Phase 7 routing time — registered here, never exercised here).

</domain>

<decisions>
## Implementation Decisions

### beets-flask: scope, version and topology

- **D-01: beets-flask is stood up in this phase.** This honours Phase 5's D-16 and ends a defer
  chain that has now run Phase 4 → 5 → 6. The ROADMAP's six criteria do not mention it; that is a
  gap in the criteria, not evidence it belongs elsewhere. Phase 3 chose it as the front end on the
  operator's own T3 self-assessment, and a config proven against a runtime that will not execute it
  proves the wrong thing.

- **D-02: Accept beets 2.12.0 under flask as the executing runtime, as a dated pin with a named
  revisit trigger.** The operator asked directly whether we should be on 2.13.1 or latest instead.
  **Researched and answered on 2026-09-20 — this closes Phase 5's open research question and D-16's
  version-pin reasoning stands unchanged:**
  - Newest beets-flask release is still **`v2.0.0-rc6`, published 2026-08-30**. Nothing has shipped
    past it.
  - rc6's `backend/pyproject.toml` pins **`beets==2.12.0`** — confirmed verbatim at the tag, not
    inferred from Phase 3's record.
  - **`main` is worse, not better:** it is the stale 1.x line, last commit 2025-12-29, pinning
    `beets==2.5.1`. It is not a route to "latest".
  - Upstream has live **`beets_2_13` and `beets_2_14`** branches; repo pushed 2026-09-17, 65 open
    issues, not archived. **The pin is active work, not an abandoned one.**

  So "latest beets" and "the chosen front end" are mutually exclusive today. What 2.13 buys over
  2.12 for this phase, from Phase 3's own audit, is `beet modify +=`/`-=` and the `edit` album-YAML
  header — both recorded as "Phase 6/7 concerns", and **neither used by the `preview`/`auto`/
  `bootleg` inbox path chosen on axis two**.

  **Revisit trigger:** an rc7 (or any release) on beets ≥ 2.13, or the `beets_2_13` branch merging.
  Building our own image on 2.13.1 was considered and **rejected**: it makes this estate the
  maintainer of a fork of a pre-release web app that writes to a 34 GB library, owning the blast
  radius of a picker Phase 3 measured silently dropping 9 of 31 files, with no upstream to report to.

- **D-03: One vendored beets config, one `library.db`, mounted into BOTH containers.** Single config
  and single database at `/mnt/fast/appdata/arrs/beets/config/`. This keeps Phase 4's D-28 ("exactly
  one beets library.db survives") true and makes "effective config" in criteria 1, 2 and 5
  unambiguous. It forces the config to be valid under **both** rc6's stricter JSON schema and beets
  2.13.1 — which is what forces D-10's `plugins:` list form.

- **D-04: The 2.13.1 survivor always passes an explicit throwaway `-l`, made structural and
  asserted.** With one database mounted into two beets versions, 2.13.1 opening it would migrate the
  schema under 2.12.0's feet. Phase 1 already measured a bare `beet config` running 11 migrations
  unasked. **Only flask's 2.12.0 ever opens the real `library.db`.** The existing D-16 discipline
  becomes an assertion in `scripts/quick-health-check.sh` alongside the vendored-file drift block.
  *Accepted consequence:* the CLI arm reads a throwaway, so it cannot answer "what is in the
  library" — flask's UI does that.

- **D-05: `/mnt/tank/media` stays `:ro` for the entire phase, for both containers.** `beets.yaml:69`
  currently comments that "Phase 6 grants it rw"; **that comment is wrong and must be corrected**.
  A read-only mount is stronger evidence for criterion 5's "wrote nothing" than any file count,
  because it **cannot fail open** — and Phase 1 measured a path-set comparison returning a perfect
  pass while Jellyfin rewrote 83 of 91 `.nfo` files. Granting `rw` becomes **Phase 7's first act**,
  done deliberately with the snapshot fence already in place.

- **D-06: Three inboxes registered; `04-hold`, `99-quarantine` and `_done` are NOT registered.**
  `01-auto` → `auto`, `02-review` → `preview`, `03-asis` → `bootleg`. The three unregistered folders
  stay filesystem-only staging, so nothing can be imported out of them by accident. Matches Phase
  3's three-inbox architecture and keeps the routing decision a directory name, as D-16 intended.

- **D-07: flask is reached at `beets.deercrest.info` via Traefik + `chain-authelia@file` on
  `t3_proxy`, with NO host port.** Exactly the shape `beets.yaml` was corrected into on 2026-09-14
  after WR-02. **The dormant survivor's traefik labels are removed** so two services cannot claim one
  hostname. **Needs a Cloudflare CNAME** — no wildcard exists for `deercrest.info`, and a Traefik
  certificate is not evidence that DNS resolves.

- **D-08: The folder-count lag risk is NOT tested here.** beets-flask's `docs/limitations.md` says
  the UI "will get laggy" past "some hundred folder or so" and the backlog sits just under that.
  Phase 6 registers three inboxes against a tree D-17 created empty and its dry runs read directly
  from `unsorted/`, so there is no population to lag at. **Carried to Phase 9**, where batch cadence
  is the actual mitigation. Phase 3's friction 5 stays `NOT EXERCISED`.

- **D-09: Inbox liveness is proven BOTH ways.** Phase 3's friction 9: rc6 validates the beets config
  against its own stricter JSON schema, and a rejected `plugins:` string kills the watchdog **while
  the server still serves a page** — inboxes go inert behind a UI that looks alive.
  1. Assert **all three** inboxes appear in the startup log; fail closed on fewer than three.
  2. **Drive one throwaway folder** through `02-review`, confirm a preview is generated, then remove
     it.
  Registration and firing are separable — Phase 3 proved that — so both are required.
  > **This AMENDS Phase 5's D-17** ("the tree is created empty"). One folder transits `02-review`
  > during this phase and is removed. Recorded as an amendment rather than left to read as a
  > contradiction.

- **D-10: `plugins:` must be written as a YAML list, not beets' canonical space-separated string.**
  `stacks/selfhosted/arrs/beets/config.yaml:60` is currently `plugins: musicbrainz` — the string
  form, which rc6 **rejects** (`…is not of type 'array', 'null'`). This is the exact landmine D-09
  guards against, and fixing the form means the rejection cannot fire in the first place.

- **D-11: `check-music-freeze.sh`'s `tagger definitions: 1` expectation is revised to 2, both named
  and classed.** Flagged in advance at `stacks/selfhosted/arrs/beets.md:1327`. Expect exactly two
  and assert them **by name** — the flask front end and the dormant 2.13.1 CLI arm — each printed on
  its own line with its class. This is Phase 4's F10 shape: a bare count cannot read as a pass, and a
  third unnamed definition must still fail.

- **D-12: The dormant 2.13.1 survivor's purpose is stated: the agent-driven CLI arm.** Kept for
  scripted/agent `beet` work on the operator's own T3 words — *"It's fine for a bot to drive us, but
  for me, as a human, no."* Stays `restart: "no"`, `profiles: ["manual"]`, commented out of the
  include list, always throwaway `-l`, `/media:ro`. **Its purpose is written into `beets.yaml`'s
  header, and that comment is the guard** against it drifting into a second pipeline — the one
  outcome this project exists to prevent.

### Path formats

- **D-13: DJ content goes to a top-level `DJ/` sibling** — e.g. `DJ/Mastermix/Issue 433/NN Title.ext`
  — beside the artist folders, via `--set albumtype=dj` + a `paths: albumtype:dj:` rule. Phase 3
  confirmed the mechanism and recorded that **"Phase 6 owns proving it"**. Satisfies PROJECT.md's
  standing "DJ content on its own library path, not mixed into `Compilations/`".

- **D-14: Multi-disc is flat and disc-prefixed — `2-05 Title.ext`, one directory per album.** Both
  Jellyfin and Music Assistant read disc number from the **tag**, not the path, so one directory is
  the safest route to Phase 7's "one album with disc numbering intact" in both consumers.
  `Disc N/` subdirectories were **rejected**: that is the exact shape that hard-failed the previous
  tagger — wrtag's validator refused this repo's format *solely* because of the `Disc N/`
  subdirectory, proven by ablation (Phase 3 headline finding 1). Track-only flat naming was also
  rejected: disc 1 track 5 and disc 2 track 5 collide, and beets appends the `.1` suffix that Phase
  7's criterion 7 sweep exists to hunt.

- **D-15: The `comp:` path rule is explicitly overridden to resolve to `$albumartist`.** beets ships
  a `comp:` rule producing `Compilations/` by default; criterion 3 requires `Various Artists/` and
  explicitly not `Compilations/`. **Override, do not delete** — an absent rule is invisible, and this
  project has been bitten repeatedly by "an absent key is the on switch". Hard-coding a literal
  `Various Artists/` was rejected: it silently misfiles a compilation whose albumartist is
  legitimately a named DJ or label.

- **D-16: `%aunique{}` is KEPT, and every folder where it fires is reported by the dry run.**
  `%aunique{}` appends e.g. ` [2019]` on a name collision, which makes the album **folder** name
  diverge from the album **tag**. Phase 2 measured that MA's `missing_album_artist_action:
  folder_name` fires **only when those agree**, and **silently falls back to `Various Artists` when
  they do not — while `config/providers/get` still reads back `folder_name`.** Dropping the
  disambiguator was rejected: Phase 1 measured 828 duplicate groups / 19.4% duplication, so removal
  trades a *detectable* MA fallback for *silent* path collisions. Folding the year into the album tag
  was rejected: it modifies metadata to suit a path convention, which is a QUAL-02 argument waiting
  to happen. **Every `%aunique{}` firing is therefore a known MA risk to verify in Phase 7.**

- **D-17: DJ content IS visible in Music Assistant — no narrowing of MA's provider path.**
  *Operator's reasoning, and it reframes the DJ content's priority:* they DJ with Traktor, Algoriddim
  djay and Rekordbox, and **cannot play or build crates from untagged tracks**. The DJ collection is
  **working material, not an archive to be hidden**. This retroactively explains why Phase 1's fence
  went out of its way to capture `TKEY` and `EnergyLevel` specifically.

- **D-18: A NAMED protected DJ-field list goes in the config, and the dry run REPORTS any proposed
  change to any of them.** MusicBrainz carries **none** of BPM / key / energy / operator comments, so
  a MusicBrainz-driven import is the specific thing that strips exactly what makes a track playable.
  Fields: `bpm`/`TBPM`, `initialkey`/`TKEY`, `EnergyLevel`, `genre`, `comment`. **A named list is
  inspectable and fails loudly; "scrub is off so we're fine" is an inference** — and Phase 3 measured
  beets-flask silently dropping 9 of 31 *files* under a false safety claim, so tool defaults are not
  a guarantee here. Hard-stopping on any DJ-field change was rejected as a Phase 7 gate in Phase 6
  clothes. **Needs research:** the exact field-name mapping per container format (ID3 vs FLAC vs WAV).

- **D-19: Phase 6 preserves DJ fields only — it generates nothing.** Only 148 of 764 `dj-mixes` files
  carry `TKEY` and 45 carry `EnergyLevel` (Phase 1's fence). Generating BPM/key for the rest is
  analysis work, and those beets plugins **rewrite audio files** — the operation this project has
  most carefully kept off (`embedart.auto: no` exists for exactly that reason). Own phase; see
  Deferred Ideas.

- **D-19a: The path format is made structurally incapable of producing album-folder ==
  artist-folder, AND the existing defect is scheduled for repair in Phase 7.** PROJECT.md records
  `Def Leppard/Def Leppard (2015)/` deriving an EMPTY album artist in MA and hard-erroring one FLAC,
  deliberately unrepaired because D-05 forbade tag repair and nobody held `rw`. Phase 6 stops
  anything **new** landing in that shape; Phase 7 fixes the existing entry rather than leaving it as
  permanent noise.

- **D-19b: Singletons get their own path rule, and the dry run FLAGS any folder that resolved to
  them.** The path rule (e.g. `Singles/$artist/$title`) stops them landing in artist folders, but
  **the report is the real deliverable**: Phase 3 measured rc6 turning one 20-track release into
  twenty single-track albums when `album` was empty — **no error, no prompt, no UI signal**.

### Criterion 4 — the consumer proof

- **D-20: Search the existing library FIRST, exhaustively.** The library is 1,244 already-tagged
  audio files. The primary route has **zero phantom risk and zero `rw` exposure**; the fallback has
  both. So the search runs across all 1,244 files and every delimiter form **before** the fallback is
  invoked at all.

- **D-21: Pre-authorised fallback — a fenced test file with a scoped `rw` grant.** If no suitable
  `;`-delimited track exists: ZFS snapshot → grant `rw` → single write → observe → roll back → revoke
  `rw`. **Written into the plan in advance so the `rw` grant is a deliberate bounded exception with a
  fence, not an improvisation.** The `:ro` invariant has exactly one named hole, and this is it.

- **D-22: "Parsed correctly" means N distinct browseable artist entities in EACH consumer, checked
  separately.** Not one artist literally named `A; B`, and not a matching count — Phase 3 measured 4
  tracks written onto entirely different songs with counts looking plausible. Checked in each
  consumer's own UI/API independently, because **Phase 2 proved a setting can read back correct while
  behaving otherwise**.

- **D-23: `;` is configured on the WRITE side too, and shown in the dry run.** CONF-04 is two things:
  what beets writes when it has multiple artists, and what the consumers parse. Criterion 4 only
  tests the read side. Without the write-side check, Phase 6 proves the consumers can read a
  delimiter **the pipeline might never produce**, and Phase 7 discovers beets wrote `/` or `, `
  instead. *Constrains the sample draw: it must include a multi-artist release.*

- **D-24: Jellyfin sees the file via a targeted scan — NEVER `FullRefresh`.** Phase 1 froze scheduled
  scans and real-time monitoring permanently. Phase 1 also measured that "Refresh metadata"
  (`FullRefresh`) **still writes even with `SaveLocalMetadata` off**, rewriting 83 of 91 `.nfo`.
  **The distinction must be written into the plan, because the two buttons sit next to each other
  and only one is safe.** Re-enabling the scheduled task was rejected: the freeze was made permanent
  precisely so there would be nothing to remember to undo.

- **D-25: Jellyfin is proven FIRST; Music Assistant LAST and only if needed.** **MA never purges
  stale entries** — that is Phase 2's founding premise. A fenced test file written, seen by MA, then
  ZFS-rolled-back leaves a **phantom track in MA's `library.db` forever; the ZFS fence does not cover
  MA**. Jellyfin rescans cleanly, so it goes first. If MA must be exposed and does index it, the
  phantom is **accepted and recorded by name** in `beets.md` rather than discovered later as a
  mystery. (On the D-20 primary route this risk is nil — both consumers already have the track.)

### Dry-run sample and the oracle

- **D-26: Deterministic, seeded draw, committed to git BEFORE any dry run.** Same discipline as
  Phase 3's 24-folder draw, so the sample cannot be quietly reshaped to make the output look right.
  **Must include the shapes that hurt:** a multi-artist release (D-23), a multi-disc release
  (D-14), a compilation (D-15), and a *Now!* volume (criterion 5). Hand-picking was rejected — it
  proves the config works on cases chosen because the config works on them.

- **D-27: The oracle is BOTH a committed expected-tree diff AND class assertions.** Write the
  intended destination path for every sampled file before the run, commit it, and diff the
  `--pretend` output against it — zero-diff is the pass, and this is the only form in which "the
  intended tree" is a fact rather than an impression (and in which criterion 3's **case-sensitivity**
  is checkable). **Plus** class assertions over the output: every top level matches an `ALBUMARTIST`,
  no `Compilations/`, no `-1 - `, no `.1` suffixes, `%aunique{}` firings listed (D-16), singleton
  resolutions listed (D-19b), DJ-field changes listed (D-18). The diff catches wrong paths; the
  assertions catch **new** failure classes nobody wrote an expected line for.

- **D-28: Criterion 5 proves `preferred.countries` as written — the embedded Discogs id is NOT
  used.** This collection carries a per-file `LOCATION=https://www.discogs.com/…/release/NNNNNN` tag
  (Phase 5 deferred note). Using it would prove a **different mechanism** and leave the configured
  one untested — and D-24 dismissed the Discogs credential, with the survivor deliberately MB-only.
  Recorded as a **Phase 9 shortcut**, not acted on.

- **D-29: "Wrote nothing" is asserted across all three layers.**
  1. **Library** — structurally, by `:ro` (D-05).
  2. **Source** — a before/after **checksum manifest** over the sampled folders, **not a count**:
     Phase 1 proved a path-set diff passes while content changes underneath.
  3. **beets' own state** — `library.db` byte-identical, and no `incremental` state recorded.
  Relying on `:ro` + `--pretend` semantics alone was rejected as pure inference; `beet` has already
  surprised this project once by running 11 migrations on a bare `config` invocation.

- **D-30: The dry run executes BOTH ways — `docker exec` for the oracle, `preview` as cross-check.**
  Every Phase 6 criterion is phrased as `--pretend` / "effective config" (CLI), but flask is the
  runtime and its inboxes have no `--pretend`.
  1. Run `beet --pretend` and `beet config -d` **inside the flask container**, on a throwaway `-l`
     (D-04), so "effective config" means the effective config of **the thing that actually runs**.
  2. Run `preview` on a subset through `02-review` as the cross-check, confirming the inbox path
     agrees.
  **If the two disagree, that disagreement is itself a finding worth having before Phase 7.**

- **D-31: Criterion 2's `incremental` trap is PROVEN with a negative control, not merely set.** On a
  throwaway library: run a skip with `incremental_skip_later` **absent** and show the folder is
  permanently marked done; then with it set, show the same folder is **re-offered**. This project's
  standing rule — stated separately in Phases 2, 02.1 and 4 — is that **reading a setting back is not
  proof it applies**, and the ROADMAP calls this "the sharpest trap in the set". Cheap and entirely
  offline.

- **D-32: `tank/downloads@pre-phase5` is KEPT. Its release moves to after Phase 7's pilot passes,
  and PROJECT.md's wording is corrected.** PROJECT.md currently says it "must not be destroyed
  before Phase 6 signs off". **Phase 6 writes nothing, so it produces no evidence that Phase 5's
  changes were correct** — only Phase 7's real import exercises them. Releasing the only undo for
  4,750 renames, 751 tag writes and 26,005 chowns on the word of a paper phase, immediately before
  the phase that first writes at scale, is the wrong trade. Disk cost on 9 T free is negligible.

### Amendments made at plan time (2026-09-20, after 06-RESEARCH.md)

Four operator decisions taken during `/gsd-plan-phase`, each in response to a research finding that
contradicted a locked decision or a live-estate condition that had changed since discuss-phase.

- **D-33: CONF-06 keeps its text; `beet move -p` is added as the tree oracle by addendum.**
  `beet import --pretend` **cannot** produce the intended tree: the pretend pipeline is
  `read_tasks → log_files`, which prints the *source* album directory and *source* file paths;
  `lookup_candidates` is never in the pipeline, so no destination is ever computed
  (`beets/importer/session.py@v2.12.0:201-240`, `stages.py@v2.12.0:266-274`). This is not a new
  finding — `.planning/REQUIREMENTS.md:276` recorded it against TAGR-05 on 2026-09-11 in Phase 4,
  and CONF-06 was written anyway. **`beet move -p` is the destination-path oracle**; it prints
  `source -> destination` via `item.destination()` (`ui/commands/move.py@v2.12.0`). Both are
  read-only. `--pretend` is **kept** for what it genuinely proves — `incremental`, `ignore`, and
  album grouping (so it still serves D-31). Follows the precedent TAGR-05 set: **the requirement
  text is deliberately not rewritten**; the correction lands as a traceability addendum.
  *Guards against:* Pitfall 1 — `--pretend` prints a line per file and so reads as a pass while
  proving nothing about paths.

- **D-34: `PreferNonstandardArtistsTag` is ENABLED on Jellyfin's Music library.** Criterion 4's
  Jellyfin half is a **decision, not an observation**. The library measures
  `UseCustomTagDelimiters=False` and `PreferNonstandardArtistsTag=False`
  (`GET /Library/VirtualFolders`, 2026-09-20), and 10.11.11's prober splits on custom delimiters
  only when the former is true (`AudioFileProber.cs@v10.11.11:227-246`) — so today's 3-artist
  reading of `ARTIST=Marshmello;P!nk;Sting` is almost certainly **stale DB state from a pre-10.10
  probe**, and D-24's targeted rescan could collapse it. Enabling
  `PreferNonstandardArtistsTag` aligns Jellyfin with the `ARTISTS` tag beets actually writes
  (C-2: beets **cannot** be configured to emit `;` in `ARTIST`) and with what MA already prefers
  (`TAG_SPLITTER=";"`), so the two consumers agree **by construction rather than by coincidence**.
  Enabling `UseCustomTagDelimiters` as well was **rejected**: `/`, `|` and `\` come along with `;`
  across 1,244 files unless `CustomTagDelimiters` is narrowed and `DelimiterWhitelist` populated,
  and `AC/DC` is the canonical casualty.
  ⚠ **This is a live-service config change that git does not capture** — it must be recorded in
  `stacks/selfhosted/arrs/beets.md` and **asserted** in `scripts/check-music-consumers.sh`, or it
  is one UI click from silently reverting.
  > **This AMENDS D-23.** CONF-04's write side is `ARTISTS` (TXXX / Vorbis), **not** `;` in
  > `ARTIST` — no delimiter or join key exists in beets' `config_default.yaml` at either version.

- **D-35: `02-review` is emptied into `04-hold` BEFORE any inbox is registered.** D-08's premise
  ("there is no population to lag at") and Phase 5's D-17 ("the tree is created empty") are both
  **stale**: `02-review` holds `Madonna/` and `Michael Jackson/` (measured 2026-09-20). Registering
  it as-is would immediately enqueue two real preview tasks against real content — a live action
  inside a phase whose premise is that it writes nothing. Both folders move to `04-hold`, which
  D-06 leaves deliberately unregistered, so registration stays inert as D-08 assumed. Reversible,
  and it keeps D-09's throwaway folder the **only** thing that ever transits `02-review` this phase.

- **D-36: The Music Assistant arm is planned and gated, but NOT executed without operator
  confirmation.** MA (`8095`) and Home Assistant (`8123`) on `172.16.1.31` are both closed —
  measured twice, 2026-09-20 — because **the host is down for maintenance** (operator's own
  statement, not an inference from the probe). The MA half of criterion 4 is therefore written in
  full and gated two ways: (1) it asserts reachability first and reports **"could not look"
  distinctly from "nothing is wrong"** per README § Health Checks, so criterion 4 stays `OPEN`
  rather than passing if MA never returns; and (2) the task carrying it is **`autonomous: false`**
  — execution **stops and confirms with the operator that MA is back online** before running.
  Deferring the MA half to Phase 7 was rejected: Phase 7 is the phase that first writes at scale,
  and discovering an MA parsing failure there is precisely the late discovery Phase 6 exists to
  prevent.

### Claude's Discretion

- Exact beets path-template syntax for D-13/D-14/D-15/D-19b.
- Which Jellyfin and MA API endpoints serve D-22's per-consumer artist-entity check, and MA's sync
  cycle timing.
- The exact `docker exec` invocation shape for D-30, and flask's appdata path layout.
- Whether rc6 exposes pagination/inbox-size knobs worth recording for Phase 9 (D-08 declined to
  measure, not to read).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The tagger decision this phase implements
- `.planning/phases/03-tagger-spike/03-DECISION.md` — the two-axis decision record. Read §*Axis one*
  (engine = beets 2.13.1), §*Axis two* (front end = beets-flask's **policy inboxes**, explicitly NOT
  its picker, disqualified on measured safety), and §*Handoff to Phases 5, 6, 7 and 9* — which names
  the two gates Phase 6/7 must add and the one instrument it proved unreliable.
- `.planning/phases/03-tagger-spike/03-BEETS-FLASK.md` — friction 9 (the stricter JSON schema that
  kills the watchdog while the server still serves a page) and the `bootleg` measurements.
- `.planning/phases/03-tagger-spike/03-ERGONOMICS-SHEET.md` — the axis-two sheet, quoted including
  where it is empty. Nine of ten rows read `not measured`; **no quantitative ergonomics claim exists
  in either direction.**

### Inbox structure this phase configures against
- `.planning/phases/05-inbox-structure-and-the-junk-gate/05-CONTEXT.md` — D-16 (beets-flask moves to
  Phase 6), D-17 (tree created empty — **amended by D-09 above**), D-18 (`_inbox` must never become
  a ZFS dataset), D-19 (`_done/` holds the original as the undo path).
- `.planning/phases/05-inbox-structure-and-the-junk-gate/05-PREMEASURE.md` §8 — `dj-mixes`'s 84
  inconsistent top-level names, which the D-13 DJ path rule will meet.

### The files this phase edits
- `stacks/selfhosted/arrs/beets/config.yaml` — the vendored survivor config. **Line 60 is
  `plugins: musicbrainz` (string form) and must become a YAML list (D-10).** Its header states
  verbatim that "EVERYTHING ELSE ABOUT THIS TAGGER'S CONFIGURATION BELONGS TO PHASE 6".
- `stacks/selfhosted/arrs/beets/beets.yaml` — the survivor stack definition. **Line 69's comment
  claiming "Phase 6 grants it rw" is wrong and must be corrected (D-05).** Its WR-02 block is the
  precedent for D-07's exposure shape. Lines 45-60 record the s6/`lsiown` boot race: gate on
  `docker exec -u abc … test -r /config/config.yaml`, **never on `.State.Status` alone**.
- `stacks/selfhosted/arrs/beets.md` — the durable operational record. Line 1327 pre-flags D-11's
  census revision; line 1331 flags that "beets has no undo" is true of the **CLI** but rc6 has a
  working `UNDO IMPORT`.
- `scripts/check-music-freeze.sh` — carries the `tagger definitions: 1` expectation (D-11) and the
  grep pattern quoted verbatim in `beets.md:1255` so the two cannot drift.
- `scripts/quick-health-check.sh` — where D-04's throwaway-`-l` assertion lands, beside the existing
  vendored-file drift block.

### Project-level constraints that bind this phase
- `.planning/PROJECT.md` — §*Constraints* (no `beet undo`; `tank/downloads` and `tank/media/Music`
  are separate datasets so every move is copy-then-unlink; ownership `568:568`, modes stay `0777`),
  and §*Key Decisions* — the `missing_album_artist_action: folder_name` row, which carries the
  **conditional-firing** measurement D-16 turns on, and the `Def Leppard/Def Leppard (2015)/` live
  defect D-19a addresses.
- `.planning/REQUIREMENTS.md` — CONF-01 … CONF-06.
- `.planning/ROADMAP.md` §*Phase 6* — the six success criteria this context serves.
- `CLAUDE.md` §*Constraints* — the `rsync -rlt --no-p --no-o --no-g` requirement on `tank`, and
  "never accept a match without a track-count check".

### Upstream sources checked on 2026-09-20 (D-02)
- `https://api.github.com/repos/metasauce/beets-flask/releases` — newest is `v2.0.0-rc6`, 2026-08-30.
- `https://raw.githubusercontent.com/metasauce/beets-flask/v2.0.0-rc6/backend/pyproject.toml` —
  `beets==2.12.0`, confirmed at the tag.
- `https://raw.githubusercontent.com/metasauce/beets-flask/main/backend/pyproject.toml` — `main` is
  the stale 1.x line, `beets==2.5.1`.
- Branch list shows live `beets_2_13` / `beets_2_14`; repo pushed 2026-09-17, not archived.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`stacks/selfhosted/arrs/beets/config.yaml`** — the config Phase 6 extends. Already carries
  `library:` explicit, the three SAFE-01 `auto: no` keys, and a credential-screen block that must be
  re-run before committing (this repo is public).
- **`scripts/normalise-dj-tags.py`** — wins D-13 in Phase 3 and **binds regardless of engine or
  front end**. Dry-run by default, per-file NDJSON diff before writing. Its NDJSON output is
  precisely what D-27's "set of changed triples equals the set the tool proposed" assertion needs —
  a blind tool structurally cannot provide it.
- **`scripts/check-music-consumers.sh`** — already asserts both-consumer visibility on every
  `quick-health-check.sh` run. The natural home for D-22's per-consumer artist-entity check, and it
  already holds the Jellyfin API key handling pattern (mode-600 check, process substitution so the
  key never enters argv).
- **Phase 3's `scripts/spike03-discogs-probe.py`** — has an `--mb-only` mode added by plan 04-08
  that never loads the dismissed Discogs credential. Relevant if D-28's country-preference proof
  needs a programmatic MusicBrainz query.

### Established Patterns
- **Fail closed, and keep "could not look" distinct from "nothing is wrong"** — README §*Health
  Checks*. Binds D-09, D-11 and D-29.
- **Prove capable of failing, not merely observed passing** — every negative control in Phases 1–5.
  Binds D-31 directly, and D-09's two-part liveness proof.
- **Bound remote commands Linux-side** — macOS has no GNU `timeout`; `timeout N cmd | wc -l` exits 0
  silently, so the remote string needs `set -o pipefail` and the ssh RC must be read.
- **Name the exception on its own line, never fold it into a count** — Phase 4's F10 (Jellyfin as
  the documented `rw` holder). Binds D-11.
- **Vendored config + byte-for-byte drift block** — the repo copy is for review; the appdata copy is
  authoritative at runtime. D-03 puts **two** containers behind **one** vendored file, so the drift
  block's scope needs re-reading during planning.

### Integration Points
- **Traefik `t3_proxy` + `chain-authelia@file`** — D-07. The network must be declared in flask's own
  file, as `beets.yaml` does, because it may be brought up outside the parent compose.
- **Cloudflare DNS** — D-07 needs a new proxied `CNAME`. No wildcard exists; the working token is
  Traefik's DNS-01 Docker secret at `/mnt/fast/appdata/traefik/secrets/cf_dns_api_token` on LXC 100.
  **A Traefik certificate is not evidence that DNS resolves.**
- **Jellyfin REST API** — D-24's targeted scan. The admin-equivalent key is at
  `/mnt/fast/secrets/jellyfin-deercrest.env`; PROJECT.md's residual-risk row governs its use.
- **Music Assistant API** — D-22/D-25. MA 2.11 beta has no token UI (username+password → 90-day
  JWT, log in per run), responses are not `.result`-wrapped, and `music/albums/count` **silently
  ignores its `provider` argument**.

</code_context>

<specifics>
## Specific Ideas

- **The operator DJs with Traktor, Algoriddim djay and Rekordbox.** Their words on why the DJ
  metadata matters: *"as a dj using traktor, algroidm dj, rekord box, etc i cant play if my tracks
  are not tagged, and setup my crates"*. This is the reasoning behind D-17, D-18 and D-19, and it
  **raises** the priority of the DJ collection rather than lowering it — the fields MusicBrainz does
  not carry are the ones that make a track usable.

- **The operator challenged the 2.12.0 pin directly** rather than accepting it, which is what
  produced the D-02 research. The question was right to ask: the answer happens to be "no newer
  release exists", but upstream is visibly working on exactly it.

- **The operator chose the strongest option over the recommended one twice** — D-09 (both liveness
  proofs, accepting an amendment to Phase 5's D-17) and D-27 (both oracles). Where a cheaper option
  was on the table and the stronger one was picked, downstream agents should not quietly simplify
  back.

- **`beets.yaml`'s own comment is the model for D-12's header note:** *"If you flip this back to
  `:rw` to 'just run one import', you have re-created the exact failure this project exists to
  prevent: a fourth half-built tagging path."* The survivor's stated purpose should read in that
  register.

</specifics>

<deferred>
## Deferred Ideas

- **BPM / key / energy generation for the ~616 `dj-mixes` files that have none** (D-19). Only 148 of
  764 carry `TKEY`, 45 carry `EnergyLevel`. The beets plugins for this **rewrite audio files**, which
  is the operation this project has most carefully kept off. Deserves its own phase with its own
  fence. Directly valuable to the operator's DJ workflow, so this is a real backlog item, not a
  nicety.
- **The `bootleg` album-populated gate** — Phase 3's handoff: *never route a folder to `bootleg`
  without first asserting `album` is populated and distinct across the intended groups.* The same
  button produced Phase 3's best and worst results purely on that condition, **with no UI signal**.
  `03-asis` is registered in Phase 6 (D-06) but nothing stages into it, so this is a **Phase 7
  routing-time** concern. Carried forward, not dropped.
- **The per-file `LOCATION=…/release/NNNNNN` Discogs id** as a bulk disambiguation shortcut (D-28).
  Phase 9.
- **beets-flask's folder-count lag** past ~100 folders (D-08). Phase 9, where batch cadence is the
  mitigation.
- **Repairing `Def Leppard/Def Leppard (2015)/`** (D-19a). Scheduled into Phase 7 rather than left as
  permanent MA noise.
- **`beet modify +=` / `-=` and the `edit` album-YAML header** — beets 2.13 features absent from
  rc6's 2.12.0 pin. Unblocked by D-02's revisit trigger.
- **DUPE-01 / DUPE-02** — still needs a roadmap decision **before Phase 7**. Phase 1 measured 828
  duplicate groups / 19.4% duplication; Phase 3 re-confirmed `dj-mixes` is a byte-for-byte duplicate
  subset of `unsorted`, which makes Phase 7's diff join **last-wins** — a silent behaviour rather
  than a chosen one. Not Phase 6's, but it is now the nearest unowned blocker.
- **`mac-music-archive/`'s 23,874 uncharacterised entries** — in scope for the project by operator
  decision 2026-09-19, sequenced after the Phase 6/7 pipeline is proven. **Also makes the
  144-folder backlog denominator stale**, and `CLAUDE.md` carries that figure twice.
- **The four Phase 5 OPEN items** — the `interpolated-host-path` gate making `quick-health-check.sh`
  exit 1, the Immich API key on a systemd command line, and `dropbox/` inside nine `rw` binds.

</deferred>

---

*Phase: 6-tagger-configuration-and-dry-run*
*Context gathered: 2026-09-20*
