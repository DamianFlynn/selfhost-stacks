# Phase 4: Collapse to One Tagger - Research

**Researched:** 2026-09-11
**Domain:** Estate retirement: compose/Renovate/doc deletion, host runtime-state removal, one vendored post-processing script, three health-check repairs, one mutagen WAV fix
**Confidence:** HIGH on the live-estate facts (all measured on LXC 100 / atlantis today); MEDIUM on two LSIO boot behaviours (read from source, still to be proven at boot per D-09)

## Summary

This phase is **retirement, not construction**, and the research brief was to measure the live
estate rather than trust documents. LXC 100 and atlantis were both reachable and every fact below
tagged `[VERIFIED: live …]` was read from them on 2026-09-11, **read-only**. No container was
started, stopped, pulled or recreated. No file on either host was edited. No `beet` command was
run.

The headline is that **the estate is closer to "one tagger" than CONTEXT.md assumed in some places
and further away in others**:
- **Closer:** no wrtag, soulbeet or beets container exists in *any* state (`docker ps -a`, no
  filter). The only rw holder over `/mnt/tank/media/Music` is Jellyfin, the documented D-21
  exception.
- **Further:** there are **five** tagger databases, not two. One of them, `wrtag.db`, is **not in
  the Phase 1 fence**. The survivor's own tree holds **two** beets databases and a `config.yaml`
  that is a pasted compose file, not a beets config.
- **Unavailable:** the D-18 probe album no longer exists on disk.
- **Live:** sabnzbd's broken beets path ran as recently as **today, 01:22 UTC**.

Four locked decisions will not produce the outcome they intend if executed literally, and each
needs a planner response. None of them re-opens a decision:
- **D-15** as written ("mirror the Jellyfin rule") would be **inert**. Renovate's docker versioning
  treats `-ls349` as a compatibility suffix and has never offered the survivor an update. Folding a
  `versioning` key into the same rule is **rejected by the validator**. A two-rule shape is proven
  to validate.
- **D-18** names an album that is gone.
- **D-10**'s one-line strip leaves `audio.bash` logging "Matching N tracks with Beets" and
  "ERROR: Unable to match using beets" on every job.
- **D-13** "extends" a beets-config drift check that **was never built**.

**Primary recommendation:**
1. Plan the phase as **fence gaps first**: copy `wrtag.db` into the fence and archive `beets.log`
   there.
2. Then the **repo retirement**, with the validated two-rule Renovate change and a
   `renovate-config-validator --strict --no-global` gate.
3. Then the **criterion-4 probe inside the survivor** (negative control first).
4. Then **TAGR-05 plus the `audio.bash` vendoring** with a real boot proof.
5. Then the **health-check guards**, landed so that their first run on the un-retired estate *is*
   their driven negative control.
6. Then **host deletion**.
7. Close with **one organic music job and an executed check run** feeding `beets.md`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### The surviving definition

- **D-01: Retire only; `arrs/beets/beets.yaml` is the one survivor.** Phase 4 deletes wrtag and
  soulbeet. beets-flask is **not** stood up here — Phase 5 is literally "Inbox Structure", and
  beets-flask's policy-carrying inboxes (`preview`/`auto`/`bootleg` over one shared `library.db`)
  *are* that deliverable. Standing it up now would ship it inert, at beets 2.12.0 (rc6's hard pin,
  below the 2.13.1 the engine was scored at), against inboxes that do not exist.

- **D-02: The survivor stays dormant.** It remains commented out of `arrs/compose.yaml`'s
  `include:` list, `restart: "no"`, `profiles: ["manual"]`, and `/mnt/tank/media:ro`. Criterion 5
  wants *zero* idle containers holding `rw` on the library; a definition that is not included
  holds nothing. The one exception is D-16 below — it is started on its `manual` profile for the
  criterion-4 probe and stopped again.

- **D-03: Bump the survivor's image to `lscr.io/linuxserver/beets:2.13.1-ls349`** (from
  `2.5.1-ls295`). This is the fully-qualified tag the spike actually measured. Blast radius is nil
  — dormant, `restart: "no"`, `:ro` on the library — and leaving the survivor at a version nothing
  was measured on means Phase 6 inherits an unproven engine. The `-ls349` suffix also closes the
  documented floating-2-part-tag hazard.

- **D-04: Retirement reaches host runtime state, not just the repo.** Repo definitions deleted,
  containers stopped and `docker rm`'d, and the retired taggers' appdata trees deleted on the
  host — **but only after confirming Phase 1's fence at `/mnt/fast/safety` already holds a copy**
  (01-02 took 18 `library.db` copies, each integrity-checked). "One `library.db`" must be a
  measured fact about the estate, not a claim about the repo.

- **D-05: `stacks/selfhosted/music/` is deleted entirely** — both `compose.yaml` and `wrtag.yaml`.
  Its only service is wrtag, so removing wrtag would leave a compose project with zero services:
  the commented-out-definition problem in another shape.

- **D-06: Dead `include:` entries are cleaned, not just the files** *(operator instruction,
  mid-discussion)*. `arrs/compose.yaml` carries `#  - soulbeet.yaml`; that line goes with
  `soulbeet.yaml` itself. `#  - beets.yaml` **stays** — it is the survivor, deliberately dormant
  per D-02. The unrelated `#  - listenarr.yaml` / `#  - boxarr.yaml` comments are left alone.

- **D-07: Grep-driven stale-reference sweep, every hit triaged.** A repo-wide
  `grep -ril 'wrtag\|soulbeet'` becomes a plan step, and every hit gets an explicit verdict:
  deleted, corrected, or deliberately kept with the reason recorded. Known hits at discussion time:
  `.gitignore`, `renovate.json5`, `CLAUDE.md`, `stacks/selfhosted/arrs/beets.md`,
  `scripts/check-music-freeze.sh`, `scripts/spike03-wrtag-arms.sh`,
  `scripts/spike03-image-headroom.sh`. `CLAUDE.md` currently tells a reader to keep the wrtag
  `<0.30.0` pin and cites the retired "7,451 files across ~1,000 folders" figure — both are wrong
  and both are in scope for correction.

### `audio.bash` and the sabnzbd beets path

- **D-08: Vendor `audio.bash` into the repo**, same pattern plan 01-07 used for
  `beets-config.yaml`. The file lives on the host at
  `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/audio.bash` and upstream `setup.bash`
  re-downloads it — which is precisely why `scripts_init.bash` was vendored in the first place. An
  in-place host edit has a measured revert path and nothing detects the divergence.

- **D-09: Bind-mount the vendored `audio.bash` `:ro`**, and re-examine whether
  `beets-config.yaml` can move from `:rw` to `:ro` in the same pass. Plan 01-07 measured exactly
  what the `:rw` mount buys: `mv tmp dest` is blocked (EBUSY — the overwrite upstream actually
  performs) but `> dest` in-place truncation still reaches the host file. Neither file is written
  by anything legitimate. **Proven, not assumed:** LSIO images do chown/permission passes over
  `/config` at boot, so the container must be shown to still start and post-process.

- **D-10: Strip the beets block only.** Remove the invocation at `audio.bash` line 285
  (`beet -c /config/scripts/beets-config.yaml -l /config/scripts/library.blb -d "$1" import -q "$1"`)
  and nothing else. The local `SAB_PP_STATUS` guard stays **byte-identical** — SABnzbd 5.0 runs
  post-processing for FAILED jobs too, and that guard is the only thing stopping failed downloads
  being post-processed into the library. Any *other* tag-writing step in the script is
  **inventoried and reported, not removed**; Phase 8 owns the hook's eventual shape.

- **D-11: Keep the vendored `beets-config.yaml` as a defused guard; delete its database.**
  `library.blb` and `beets.log` go (criterion 5's "one `library.db`"). The config and its bind
  mount **stay**, with `musicbrainz` added to its `plugins:` line per TAGR-05. The reason it was
  vendored still holds: restoring stock `setup.bash` re-downloads a config with `scrub.auto`,
  `lastgenre.auto` and `embedart.auto` all defaulting to **yes**, against a 34 GB library with no
  undo. Keeping it defused is cheaper than trusting nobody reverts.

- **D-12: Criterion 3 is proven on a real music job, end to end.** Queue one genuine music
  download and watch it complete: `beets.log` gains no line, no `.blb` is created or touched, no
  `.bak` files appear, and the folder lands untagged in `complete/nzb/music`. A static grep on the
  vendored script proves the file, not the behaviour — the class of evidence this project has
  repeatedly recorded as insufficient.

- **D-13: The vendored `audio.bash` gets a fail-closed repo-vs-host drift assertion** in
  `scripts/quick-health-check.sh`, extending the comparison plan 01-09 added for
  `beets-config.yaml`. Per README § Health Checks: fail closed with "could not look" kept distinct
  from "nothing is wrong", bounded **Linux-side** with `timeout`, asserting rather than reporting,
  and with a **driven negative control** proving the new assertion can fail. Explicitly **not** the
  report-only `info()` shape — that is the exact CR-01 defect Phase 02.1 spent four gap-closure
  plans repairing.

### Renovate and criterion 4

- **D-14: Delete the wrtag Renovate rule outright.** The package no longer exists in the repo, so
  the rule matches nothing. `renovate.json5:91`'s stated evidence is *wrong* — of the three fields
  it blames, `.Release.Date.Year` and `.Release.Media` are both present at v0.20.0; the real
  defects are that v0.20.0 forces `d.Track.Position = -1` and that `.Media.Position` is absent
  from its `Data` struct. Cause and effect are reversed in that rule. The **corrected finding**
  lands in `beets.md` and `CLAUDE.md`, verbatim from Phase 3:
  > *this repository's `WRTAG_PATH_FORMAT` works on none of v0.20.0, v0.33.0 or v0.34.0 — it
  > renders `-1 - ` on every single-disc track and hard-errors on multi-disc at v0.20.0, and is
  > refused at startup by both current tags — and the sole cause of the startup refusal is the
  > `Disc N/` **subdirectory**, proven by an ablation that changes nothing else and validates at
  > both current tags.*

- **D-15: Add a beets Renovate rule mirroring the Jellyfin rule.** Minor **and** major go to
  manual review; **patch automerge is preserved**; **no `allowedVersions` ceiling** — citing the
  wrtag pin as exactly why a ceiling is the wrong instrument. Placed after `packageRules[2]` so it
  wins. The reasoning transfers cleanly: beets 2.4.0 turned MusicBrainz into a plugin and silently
  disabled autotagging estate-wide, which is a *minor* release changing semantics.
  `renovate-config-validator` must pass (criterion 2) — a config error silently stops the whole
  repo run.

- **D-16: Criterion 4's instrument is the `tag_album()` probe plus one hand-read
  `beet import -t`.** `--pretend` is unsatisfiable and this is not to be rediscovered:
  `beets/importer/session.py` v2.13.1 replaces the entire pipeline with `log_files` under
  `pretend`, so `lookup_candidates` is never called, zero API calls are issued and zero candidates
  are reported *by construction*. The probe is the machine-readable assertion; the hand-read
  `beet import -t` is the cross-check — the same paired-instrument method that carried T1 and that
  caught three defective instruments in 03-07. **Both runs pass an explicit throwaway `-l <db>`:
  `beet` is NOT read-only — in Phase 1 it opened the default library and ran 11 migrations from a
  config probe alone.**

- **D-17: The probe gets a negative control against the *live* broken config.** Run it against
  today's `plugins: embedart` config and record **zero** candidates, then against the fixed config
  — same album, same throwaway `-l`, only the `plugins:` line differing. This turns "the missing
  `musicbrainz` plugin caused the 1 Aug and 8 Aug skips" from a well-reasoned inference into a
  measurement.

- **D-18: The probe album is `Garth_Brooks-Ropin_The_Wind`** — a folder the broken config
  genuinely skipped (named in `beets.log`), single-disc and well covered by MusicBrainz.
  **Deliberately not `Def.Leppard-CD.Collection`:** it is multi-disc, and this estate has a live
  `Def Leppard/Def Leppard (2015)/` empty-album-artist defect that would confound the result.

- **D-19: The probe runs inside the survivor, started on its `manual` profile**, then stopped.
  `profiles: ["manual"]` exists for exactly this. It proves the container this phase actually
  ships, at the version D-03 pins, through the mounts it declares — a throwaway container would
  prove a container this phase does not ship, and 03-04 already measured that a config dump cannot
  prove which plugins actually loaded (assert via `beet version`).

- **D-20: Amend ROADMAP criterion 4 and REQUIREMENTS TAGR-05 in-band and dated**, following the
  02.1-11 precedent exactly: quote the original wording, state why `--pretend` is unsatisfiable
  with the `session.py` evidence, and name the substitute instrument. **Substance preserved, never
  reduced.** A success criterion nobody can satisfy as written is how a verification pass returns
  `gaps_found` for a reason that is not a real gap.

### Phase 3 carry-ins

Three of Phase 3's four suggested carry-ins are in scope. Each touches a file this phase is
already editing.

- **D-21: DEF-03-01 — fix `check-music-freeze.sh` by behaviour, and assert the retired databases
  are absent.** `TAGGER_PATTERN='beets|soulbeet|wrtag|lidarr'` classifies by container *name*, so
  it structurally cannot see beets running inside `sabnzbd` — it reported `tagger-class writers: 0`
  while **blind**, not while clean. Classify tagger-class by what a container *mounts* (a beets
  config or database path). Then invert DEF-03-01's mtime suggestion: this phase deletes two of
  the four databases, so assert the **retired ones are gone** and only the survivor's exists. That
  turns the check into a standing guard on this phase's own outcome — a resurrected tagger fails
  it. Needs a **driven negative control** per README § Health Checks. It has to change anyway: the
  D-07 sweep is deleting two of the four names in that regex.

- **D-22: `check-renovate.sh`'s five `grep -v '^$'` pipefail aborts are repaired** (lines 90, 100,
  115, 138, 157). **Line 157 is inverted — it aborts when ZERO Renovate PRs are pending, i.e.
  exactly when the estate is healthy.** Criterion 2 requires `renovate-config-validator` to pass
  and this phase edits `renovate.json5`, so the tool that checks that file is in the blast radius
  regardless. ROADMAP § 02.1 named Phase 4 as one of its two homes.

- **D-23: DEF-03-09 — fix `normalise-dj-tags.py`'s WAV write path, ID3 only, with the container
  disagreement made visible.** The tool writes **0 of 134** WAV files, failing all 134 loudly with
  `TypeError: … not a Frame instance` — `mutagen.File(easy=True)` on a WAVE returns a raw
  frame-id-keyed `ID3`, not an EasyID3 map. Fix with mutagen's correct WAVE API
  (`WAVE` + `add_tags()` + `setall`). **Write ID3 only** — that is what both consumers read — but
  make the stale RIFF `LIST`/`INFO` chunk an **explicit recorded finding** surfaced by the
  dry-run NDJSON, so nobody later discovers two containers disagreeing (`IPRD` holding the old
  album) and reads it as corruption. Add the **three-case regression test**: untagged WAV,
  ASCII-tagged WAV, non-ASCII-tagged WAV, asserting the value reads back with every other frame
  (`APIC`, `TDRC`, `TIT2`, `TPE1`, `TRCK`) intact. Scope is bounded: 268 of 8,492 audio files
  (3.2%), all `Now!` compilation content, none of it content the three committed rules fire on.

- **D-24: The Discogs token rotation is explicitly OUT, on the operator's own assessment.**
  Recorded as a **reasoned dismissal, not an oversight or a silence**, in the same style as
  PROJECT.md's `sec=sys` row, so a future security review meets an answer. The operator's words:
  *"Discogs token rotation is not important at all, there is nothing there that has any value, i
  am not concerned"*. The standing action and its four causes remain on the record in
  `03-DECISION.md` § 9 and `deferred-items.md` DEF-03-21; nothing in this phase depends on it, and
  no plan should spend a step on it.

### Closure and the issue trail

- **D-25: Criterion 5 is measured into `beets.md` and guarded by the standing check.** The three
  counters — tagger definitions = 1, beets `library.db` = 1, `rw` library mounts on non-tagger
  containers = 0 — come from an **executed run of the D-21 `check-music-freeze.sh`**, not from
  reading the diff, and land as a dated closure section in `stacks/selfhosted/arrs/beets.md`, the
  durable record already sitting beside the stack. The check then keeps asserting them, so
  "strictly better" survives the phase rather than being a snapshot. This is how Phases 1, 2 and
  02.1 each closed.

- **D-26: Close GitHub issue #306 with the evidence.** Cite the concrete reasons: the image
  `ghcr.io/terry90/soulbeet` is gone from GHCR, it was never deployed, its data directory is
  empty, and the definition plus `arrs/soulbeet/beets_config.yaml` are now deleted. **#305 stays
  open** until the milestone completes; **#307 (rybbit) is unrelated** to this phase. A closing
  comment that says *why* is what stops it being reopened on a whim.

### Claude's Discretion

- Plan decomposition and ordering, subject to two constraints the discussion fixed: the D-17
  negative control must run against the **live** broken config **before** TAGR-05 fixes it, and
  D-04's appdata deletion must follow the fence confirmation, never precede it.
- Exact wording of the in-band ROADMAP/REQUIREMENTS amendments (D-20), following the 02.1-11
  shape.
- Whether the `beets-config.yaml` `:rw` → `:ro` move (D-09) lands in this phase or is recorded as
  measured-and-deferred, decided on what the boot-time check actually shows.

### Deferred Ideas (OUT OF SCOPE)

- **beets-flask stack definition** — Phase 5, where its `preview`/`auto`/`bootleg` inboxes over
  one shared `library.db` are the actual deliverable. Carry Phase 3's friction 9 with it: rc6
  validates the beets config against its own stricter JSON schema, and a rejected `plugins:`
  string kills the watchdog **while the server still serves a page** — the inboxes go inert behind
  a UI that looks alive.
- **Moving `beets.yaml` into a music-named stack** — raised and rejected for this phase. A move
  is a change to the survivor in a phase that is otherwise pure deletion, and it churns paths
  Phase 5/6 will touch anyway.
- **Reworking `audio.bash` into a minimal move-only hook** — Phase 8 (INGS-01). The inbox it
  would move into does not exist until Phase 5.
- **Removing other tag-writing steps from `audio.bash`** (ReplayGain, lyrics, embedded art) —
  D-10 inventories and reports them; Phase 8 decides.
- **Granting the survivor `rw` and configuring it** — Phase 6 (CONF-01…06).
- **Discogs token rotation** — explicitly dismissed by the operator (D-24), not deferred. Recorded
  so a future review meets a reasoned answer rather than a silence.
- **`renovate.json5`'s cosmetic label wart** (`addLabels` is additive and Renovate has no
  `removeLabels`, so a manual-review PR inherits `automerge`/`safe` as decoration) — already
  documented in the Jellyfin rule and deferred there; D-15 inherits the same wart and the same
  deferral.
- **DUPE-01 / DUPE-02** — needs a roadmap decision before Phase 7. Phase 1 measured 828 duplicate
  groups / 19.4% duplication and Phase 3 re-confirmed `dj-mixes` is a byte-for-byte duplicate
  subset of `unsorted`, which makes Phase 7's diff join **last-wins** — a silent behaviour, not a
  chosen one.
- **`/mnt/tank/media/TV` on the orphan gid 545** — 114,218 entries, outside this milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TAGR-03 | The losing tagger definitions are deleted and their Renovate rules released, including the wrtag `<0.30.0` pin that enforces the broken state | § D-07 sweep verdict table (every hit, 14 repo files + 72 `.planning` files); `renovate.json5` edit validated with `renovate-config-validator` 44.80.0 `--strict` in both modes (§ Code Examples 1–2); description-index hazard (Pitfall 6); `spike03-image-headroom.sh` KEEP_PATTERNS (Pitfall 11) |
| TAGR-04 | soulbeet is removed (issue #306) and the beets block stripped from `audio.bash` | Live `audio.bash` read in full (339 lines, sha256 `fdcddca2…`); line map + side-effect inventory (§ `audio.bash` anatomy); vendoring/boot facts (Pitfalls 7–8); #306 body read (it proposes a salvage step the closing comment must answer, Pitfall 14); SAB history shows every music job already ends `Exit(1)` (Pitfall 3) |
| TAGR-05 | Every remaining beets config declares the `musicbrainz` plugin | Estate-wide beets-config census (§ Runtime State Inventory): the sabnzbd config, the survivor's host `config.yaml` (**not a beets config and not in the repo**), `config.yaml.old`, and the soulbeet config. Probe mechanics for D-16/17/19 (§ Code Examples 4–5); D-18 album unavailable, substitute measured (Open Question 3) |
</phase_requirements>

## ⚠ Facts CONTEXT.md relies on that the live estate does not support

Read this before planning. Each row was measured 2026-09-11. The "Planner response" column is a
recommendation; decisions marked **(needs ruling)** touch a locked decision's letter and belong
in front of the operator, not silently in a plan.

| # | CONTEXT.md says / assumes | Measured reality | Planner response |
|---|---|---|---|
| F1 | D-18: probe album `Garth_Brooks-Ropin_The_Wind` | **Gone.** `beets.log` names `Garth_Brooks-Ropin_The_Wind-Remastered-CD-FLAC-2008-ERP` (skipped 26 Jan). Nothing matching `*ropin*` survives under `/mnt/tank/downloads` (depth 4) except `_FAILED_Garth.Brooks-Ropin.The.Wind-CDP.7.06330-2-CD-FLAC-1991-EMG`, a failed SAB job (bucket D). `[VERIFIED: live find]` | Substitute meeting every stated D-18 criterion: `Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost`. Skipped by the broken config 6 Sep (in `beets.log`). 12 FLAC, single disc, not Def Leppard. MusicBrainz carries a 12-track 2001-11-13 US HDCD release at score 100 `[VERIFIED: MB WS/2]`. **(needs ruling)**. Re-assert presence at execution: the tree is live |
| F2 | D-04: fence "holds a copy" of every retired DB; "18 `library.db` copies" | Fence holds **4 distinct beets DBs + 11 migration `.bak` of one + 3 Jellyfin DBs = 18 files** (`MANIFEST.txt`: `library-db files=15`, Jellyfin added at 14:28). **`wrtag.db` is NOT in the fence** (315,392 B, mtime 2026-01-23, at `/mnt/fast/appdata/media/wrtag/data/wrtag.db`, which is **not** under `arrs/` or `music/`). soulbeet has no DB (its `data/` is empty). `[VERIFIED: live]` | D-04's precondition **fails for wrtag**. Add a fence-copy step (`sqlite3 .backup` + `PRAGMA integrity_check`, the 01-02 method) before deleting `media/wrtag`. It is the only way to honour D-04's letter |
| F3 | D-11: sabnzbd-side state is `library.blb` + `beets.log` | **Two** beets DBs live under sabnzbd `/config`: `scripts/library.blb` (+11 `.bak`, **all regenerated on every music job**, last 2026-09-11 01:22Z), and `.config/beets/library.db` (+11 `.bak`, created 2026-08-18 21:12 by Phase 1's `beet config` probe; the fence holds its pre-migration 36,864 B copy). `[VERIFIED: live]` | "One `library.db`" is false while `.config/beets/` exists. Delete it too **(needs ruling: not named in D-11)** |
| F4 | TAGR-05: "every remaining beets config" is fixable in the repo | The survivor's host config `/mnt/fast/appdata/arrs/beets/config/config.yaml` (3,293 B) is **a pasted compose service definition** (`services:` → `beets:` → `image: …2.5.1-ls295`, volumes including a stale `/mnt/tank/media:/media:rw` string) plus the three SAFE-01 keys. It has **no `plugins:`, `library:` or `directory:` key** and **is not in the repo**. Its sibling `config.yaml.old` is LSIO's default (`plugins: fetchart embedart convert scrub replaygain lastgenre chroma web`, no `musicbrainz`). `beets.md:46-47` already records the first half. `[VERIFIED: live + CITED: LSIO defaults/config.yaml]` | The survivor's effective plugins today are beets' default `[musicbrainz]`, but nothing *declares* it. TAGR-05 needs this file addressed **(needs ruling: Open Question 1)** |
| F5 | D-25: survivor tree = "one `library.db`" | Survivor tree holds **two**: `library.db` (53,248 B, 2025-11-18, the default path beets uses when `library:` is absent) and `musiclibrary.blb` (36,864 B, 2025-10-27, LSIO's default `library:`). Both fenced, both unchanged since the fence. Plus `Music/__` (~1.4 GB), an **accidental 2025-11-18 import into beets' default `directory`**. `[VERIFIED: live]` | Decide which survives. Deleting the other needs a ruling **(Open Question 2)**. Do **not** touch `Music/__` (Phase 6) |
| F6 | D-13: "extending the comparison plan 01-09 added for `beets-config.yaml`" | **No such comparison exists.** `grep` over every `scripts/*.sh` for `beets-config`, `sabnzbd`, `blb` in `quick-health-check.sh` returns nothing. 01-09-SUMMARY never claims it. Only `sabnzbd.yaml:89-90`'s comment asserts it (docs describe intent, not reality). Repo and host `beets-config.yaml` are byte-identical today (`7a059a40…`), so no drift is hiding. `[VERIFIED: repo grep + live sha256]` | D-13 builds the **first** vendored-file drift check. Cover **both** vendored files in one assertion. Correct `sabnzbd.yaml:89-90` |
| F7 | D-10: stripping line 285 alone yields "a SABnzbd music job completes without invoking any tagger" | True for *invocation*, but `beets()` still runs: it `rm`s `library.blb`, logs `Matching N tracks with Beets`, then finds nothing newer and logs **`ERROR: Unable to match using beets to a musicbrainz release`** in `/config/logs/Audio.txt` on **every** job. `requireBeetsMatch="false"` in `extended.conf`, so no `rm -rf`. `[VERIFIED: live audio.bash + extended.conf]` | Pitfall 2. Either accept and pre-declare the two lines in the D-12 evidence, or strip the gate at 322–324 as well **(needs ruling: D-10 is locked to one line)** |
| F8 | D-12: "watch it complete" | **Every music job since at least 2026-08-01 already records `Completed` with `Exit(1): chmod: changing permissions of '/downloads/complete/nzb/music/…'`** (8/8 in SAB history). `audio.bash:334`'s `chmod 777 "$1"` fails EPERM on `tank` (`aclmode=restricted`) under `set -e`. `[VERIFIED: live history1.db read-only]` | The Exit(1) is **baseline, not a regression**. The D-12 evidence must name it, or a verifier will read it as one. Do not fix it here (D-10) |
| F9 | D-15: a rule "mirroring the Jellyfin rule" | **Inert.** Renovate docker versioning treats text after the first hyphen as a compatibility suffix `[CITED]`. The Dependency Dashboard lists `lscr.io/linuxserver/beets 2.5.1-ls295` with **no update offered**, though 2.13.1 has existed for months and minors automerge. **Every `-lsNNN`-pinned LinuxServer image in the estate shows the same silence.** Adding `versioning` to the same rule is **rejected**: `packageRules cannot combine both matchUpdateTypes and versioning` `[VERIFIED: validator 44.80.0]` | Two rules: a versioning-only rule, then the manual-review rule. Validated `--strict` in both modes (§ Code Example 1). Consequence: Renovate will immediately propose `2.13.1-ls350` (exists since 2026-09-04) as a **patch** and automerge it **(needs ruling: Open Question 4)** |
| F10 | Criterion 5 / D-25: "`rw` library mounts on non-tagger containers = 0" | **Jellyfin holds `/mnt/tank/media → /media:rw`** (documented D-21 exception). It is the **only** rw holder over Music across all 97 containers, in any state. `[VERIFIED: docker inspect, all containers]` | State the counter honestly: "0 excluding the D-21 consumer exception (Jellyfin), printed separately". This is the WRIT-01 shape, not a gap |
| F11 | D-06: `#  - beets.yaml` "is the survivor" | The include line resolves to `arrs/beets.yaml`, which **does not exist**. The survivor is `arrs/beets/beets.yaml`. Uncommenting it breaks the arrs project. `[VERIFIED: file listing]` | Correct it to `#  - beets/beets.yaml` as a D-07 "corrected" verdict **(needs ruling: D-06 says the line "stays")** |
| F12 | D-22: "five `grep -v '^$'` aborts (lines 90, 100, 115, 138, 157)" | Only **115, 138, 157** are `grep -v '^$'`. **90 and 100** are `grep -r… \| sort` / `\| sed` pipelines that abort under `pipefail` when grep finds nothing (latent: this repo always has matches). `[VERIFIED: file read]` | Fix all five, but with the right remedy per shape (§ Code Example 3) |
| F13 | Criterion 2: "`renovate-config-validator` passes" | `check-renovate.sh:62` runs `renovate-config-validator "$CONFIG_FILE"`. **Passing a filename validates it as GLOBAL self-hosted config**, not repo config (`INFO: Validating renovate.json5 as global config`) `[CITED + VERIFIED]` | Use `--no-global` (or no argument). The current file passes `--strict` in **both** modes today, so this is correctness, not a blocker |
| F14 | D-16: reuse `scripts/spike03-discogs-probe.py` | The probe **hard-requires `DISCOGS_USER_TOKEN`** (`REQUIRED_ENV`) and **unconditionally** calls the Discogs identity endpoint (`main()` line 895). `--require-plugin musicbrainz` narrows the plugin gate only. `[VERIFIED: source]` | Add an MB-only mode that drops the token and identity probe, or D-16 drags the dismissed (D-24) credential into the survivor for no reason (Pitfall 9) |
| F15 | D-07/D-14: correct `CLAUDE.md` | `CLAUDE.md:159-343` sits between `<!-- GSD:stack-start source:research/STACK.md -->` markers. It is **generated** from `.planning/research/STACK.md` by `gsd-tools generate-claude-md` (called by `new-project`) `[VERIFIED: file + gsd-tools.cjs]` | Edit `CLAUDE.md` and add a dated in-band note to `STACK.md`, or the correction reverts on regeneration (low probability, real mechanism) |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tagger definitions, Renovate policy, docs | Repo (git, public) | Workstation | Git is the delivery path. Nothing reaches LXC 100 until pushed to `origin` and pulled at `/mnt/fast/stacks` |
| Container runtime state (containers, images, networks) | LXC 100 dockerd | — | Retirement must be measured with `docker ps -a` (no filter), never inferred from git |
| Tagger databases and appdata trees | LXC 100 `fast/appdata/*` ZFS datasets | atlantis (ZFS) | `appdata/arrs` and `appdata/media` are **separate child datasets** (`find -xdev` is blind across them, Pitfall 12) |
| Recovery fence | LXC 100 `/mnt/fast/safety` (ext4 on `/`) | — | Copies land here via `sqlite3 .backup`. No container mounts it (asserted by the freeze check) |
| SAB post-processing (`audio.bash`) | sabnzbd container (`/config/scripts`) | host appdata copy + repo copy | Runtime-authoritative copy is appdata. The repo copy is for review and drift detection (01-07 hybrid) |
| Renovate update proposals | Mend Renovate (SaaS, reads repo) | GitHub (PRs, Dependency Dashboard #3) | Validator on the workstation is the only pre-merge check. The dashboard is the post-merge signal |
| Public hostnames | Cloudflare DNS | Traefik (docker labels) | Traefik routes vanish with the container. **DNS records do not** (`wrtag.deercrest.info` still resolves) |
| Criterion-4 probe | Survivor container (`manual` profile) | — | D-19: prove the container this phase ships |
| WAV regression test (D-23) | LSIO beets image (mutagen 1.48.1) | — | mutagen is **absent** on the LXC 100 host python and on the workstation `[VERIFIED]` |

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `lscr.io/linuxserver/beets` | `2.13.1-ls349` | Survivor image (D-03), probe host (D-19), mutagen host (D-23) | **Already resident on LXC 100** (image ID `159e62e4d611`, created 2026-08-29T01:55Z, manifest-list digest `sha256:7bf852f3…`). Tag exists on Docker Hub (pushed 2026-08-29) `[VERIFIED: live + Docker Hub API]`. **No pull needed**, so no `/` cost |
| `renovate-config-validator` (npm `renovate`) | 44.80.0 (latest, 2026-09-11) | Criterion 2 | Official validator. `--strict` fails on warnings, errors and needed migrations; `--no-global` = repo semantics `[CITED: docs.renovatebot.com/config-validation]` |
| `sqlite3` | present on LXC 100 | Fence copy of `wrtag.db`; read-only SAB history reads | The 01-02 method (`.backup` + `PRAGMA integrity_check`) `[VERIFIED: used read-only today]` |
| `docker compose` | host v2; workstation v5.0.0-desktop | `config --quiet` validation after edits; survivor lifecycle | `config --quiet` exits 0 today for both the arrs project and the standalone survivor on the host `[VERIFIED]` |
| mutagen | 1.48.1 (inside the beets image) | D-23 WAV fix + regression test | Already the tool D-13 chose. `mutagen.wave.WAVE.tags` is `mutagen.id3.ID3`; `add_tags()` adds an empty ID3 `[CITED: mutagen.readthedocs.io/en/latest/api/wave.html]` |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `gh` | Close #306; read the Dependency Dashboard (#3) before and after | D-26; criterion-2 post-merge signal (soulbeet lookup warning should vanish) |
| `dig` | Prove the Cloudflare `wrtag` record is gone (if removal is ruled in) | Runtime-state verification |
| `ffprobe` (LXC 100) | Read-only tag evidence for D-12 (the job's files carry no beets-written tags) | D-12 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Scratch-prefix npm install of the validator | `npx --yes --package renovate …` | **Prohibited by name** in `check-renovate.sh:56-58` and 02.1 (downloads and executes an unverified package per run). Do not use |
| Scratch-prefix npm install | `docker run renovate/renovate:<ver> renovate-config-validator` on the workstation | Works without node, but a large image pull. Fine on the workstation, **never on LXC 100** (`/` headroom) |
| Starting the survivor for D-23 | `docker run --rm --entrypoint python3 lscr.io/linuxserver/beets:2.13.1-ls349 …` | D-19's "prove the shipped container" governs criterion 4 only. D-23 can use a throwaway container **from the resident image** (never a pull) |

**Validator installation (workstation, pinned, no lifecycle scripts). Measured 19 s, 614 packages:**
```bash
S=<scratch dir outside the repo>
npm install --prefix "$S" renovate@44.80.0 --ignore-scripts --no-audit --no-fund
cp renovate.json5 "$S/cur/renovate.json5" && (cd "$S/cur" && "$S/node_modules/.bin/renovate-config-validator" --strict)
```
`--ignore-scripts` leaves the optional `re2` native module unbuilt, so Renovate logs
`WARN: RE2 not usable, falling back to RegExp` and still validates (exit 0). Node 26.8.2 runs it,
although `engines` says `^24.11.0` `[VERIFIED]`.

## Package Legitimacy Audit

This phase installs **no packages into the project or onto any host**. The only install is a
workstation-scratch copy of the validator.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `renovate` | npm | multi-year; 44.80.0 published 2026-09-11 | 205,747/wk (npm API) | github.com/renovatebot/renovate (maintainers jamietanna, viceice) | **UNAVAILABLE in check-only mode.** `slopcheck install` auto-detected **PyPI** and reported `[SLOP] … does not exist on pypi`, a wrong-ecosystem false positive. It also **installs** clean packages, so it was not re-run with `-e npm` | `[ASSUMED]` per protocol. Gate behind `checkpoint:human-verify`. No `postinstall`/`install` script in registry metadata; install with `--ignore-scripts` regardless |
| `mutagen` | PyPI | — | — | github.com/quodlibet/mutagen | not run (the same install behaviour; would have tried `pip install`) | Already inside the resident LSIO image (1.48.1). **No install** |

**Packages removed due to `[SLOP]`:** none (the `renovate` verdict was wrong-ecosystem).
**Packages flagged `[SUS]`:** none.

## Architecture Patterns

### System Architecture Diagram

```
                     ┌──────────────── workstation (repo, public) ─────────────────┐
 D-07 grep sweep ──► │ delete: arrs/soulbeet.yaml, arrs/soulbeet/, music/          │
                     │ edit:   arrs/compose.yaml include, arrs/beets/beets.yaml tag│
                     │         renovate.json5 (−wrtag rule, +2 beets rules,        │
                     │           fix Jellyfin description index refs)              │
                     │         sabnzbd.yaml (+audio.bash :ro), sabnzbd/audio.bash  │
                     │         sabnzbd/beets-config.yaml (plugins += musicbrainz)  │
                     │         scripts/{check-music-freeze,check-renovate,         │
                     │           quick-health-check}.sh, normalise-dj-tags.py      │
                     │ validate: renovate-config-validator --strict --no-global    │
                     └───────────────┬─────────────────────────────────────────────┘
                                     │ git push → origin (the ONLY delivery path)
                                     ▼
 Renovate SaaS ◄── reads repo ── GitHub ── Dependency Dashboard #3 (soulbeet warning clears)
                                     │ git pull at /mnt/fast/stacks (host is 1 commit behind today)
                                     ▼
 ┌────────────────────────────── LXC 100 (172.16.1.159) ───────────────────────────────┐
 │ fence: /mnt/fast/safety ◄── sqlite3 .backup wrtag.db ; cp beets.log   (FIRST)        │
 │                                                                                      │
 │ survivor (manual profile) ── up ──► svc-beets runs `beet web` (opens /config DB!)    │
 │   docker exec -u abc: beet -c <overlay> -l <throwaway> version  (broken / fixed)     │
 │   docker exec -u abc: python3 probe --mb-only  (neg control, then pos)               │
 │   docker exec -i -u abc: beet … import -t -W -C  ← abort at prompt   ── down ──►     │
 │                                                                                      │
 │ sabnzbd ── recreate ──► init: lsiown every /config file; scripts_init.bash           │
 │   (pip -U beets!, chmod -R /config/scripts) ── boot proof: exited 0, HTTP 200        │
 │   music job ──► audio.bash (guard ▸ clean ▸ verify ▸ [beets() minus L285] ▸ chmod✗)  │
 │                    evidence: SAB history row, Audio.txt, no .blb/.bak/beets.log      │
 │                                                                                      │
 │ delete: appdata/arrs/soulbeet, appdata/media/wrtag, sabnzbd scripts/library.blb*,    │
 │         beets.log, .config/beets/  (each after its fence copy is asserted)           │
 │                                                                                      │
 │ check-music-freeze.sh (host-resident) ◄── folded into quick-health-check.sh (ssh -n) │
 │   census: tagger defs=1 · beets DBs=1 · retired DBs absent · rw-on-Music (all states) │
 └──────────────────────────────────────────────────────────────────────────────────────┘
 Cloudflare DNS: wrtag.deercrest.info (proxied) survives all of the above unless removed
```

### Recommended plan decomposition (Claude's discretion; the two fixed orderings are honoured)

| Order | Plan | Contents | Why here |
|---|---|---|---|
| 1 | **Fence gaps + baseline** | Read-only census (no status filter), sha256 of every file slated for deletion, **copy `wrtag.db` into the fence** (`.backup` + integrity check), **copy `beets.log` into the fence** (not the repo, Pitfall 13), record the baseline Exit(1) SAB history rows | D-04 precondition (F2). Nothing irreversible yet |
| 2 | **Repo retirement + Renovate** | Delete the soulbeet/music files, D-06 include line, D-03 tag bump, `renovate.json5` (−rule, +2 rules, description index fix), validator gate, D-22 fixes, D-07 sweep verdict table incl. `CLAUDE.md`/`STACK.md`/`PROJECT.md`/`beets.md` corrections, D-20 amendments | Pure repo work. Validator proves it. Push before any host step |
| 3 | **Criterion-4 probe** | Probe MB-only mode, overlay configs, survivor up → `beet version` ×2 → `tag_album` neg → pos → hand-read `import -t` → down | Must precede plan 4 (D-17 ordering). Needs plan 2's pushed tag bump |
| 4 | **TAGR-05 + `audio.bash`** | Vendor `audio.bash`, strip L285, `:ro` mount, `plugins: embedart musicbrainz`, survivor-config decision (OQ1), sabnzbd recreate with boot proof, decide `beets-config.yaml` `:ro` on evidence | After the negative control. The recreate is the D-09 proof |
| 5 | **Guards (D-21, D-13)** | Behaviour-based freeze-check section and drift assertion; fold-in selector widened | **Land before host deletion.** The first run on the un-retired estate is the driven negative control: it must go red naming `wrtag.db`, `library.blb` and the rest (Pattern 3) |
| 6 | **Host deletion (D-04)** | Delete appdata trees and sabnzbd DB state, each gated on its fence copy. Optional: DNS record, image reap via the gate. Re-run guards → green | After 1 (fence) and 5 (guard) |
| 7 | **Closure** | D-12 real music job (**human checkpoint / organic wait**), executed freeze-check run → D-25 section in `beets.md`, close #306 | Needs everything above |
| any | **D-23 WAV fix** | Independent of all the above | Can run in parallel slot 2–6 |

### Pattern 1: Vendored runtime file = repo copy + appdata copy + fail-closed drift check

**What:** The 01-07 hybrid. The compose mount points at the **appdata** copy (runtime-authoritative).
The repo copy is for review, and a check asserts the two are byte-identical.
**Do it this way:** mount `…/config/scripts/audio.bash:/config/scripts/audio.bash:ro`, the same shape
as the existing `beets-config.yaml` line (`sabnzbd.yaml:95`). The execute bit is preserved: the host
file is `0777` today.
**Drift check location (D-13 says `quick-health-check.sh`):** compare **both halves on the host**,
so the workstation's own dirty or unpushed tree cannot fake drift, and so one bounded ssh does it.
See Code Example 6.

### Pattern 2: Survivor lifecycle for a one-off probe (D-19)

```bash
# on LXC 100, from /mnt/fast/stacks, after `git pull` (host was at 3327dcf vs origin 4604764 on 2026-09-11)
F=stacks/selfhosted/arrs/beets/beets.yaml
E=stacks/selfhosted/arrs/.env        # exists; never print it (compose `config` without --quiet renders env)
docker compose -f "$F" --env-file "$E" --profile manual config --quiet      # measured exit 0
docker compose -f "$F" --env-file "$E" --profile manual up -d beets         # project name "beets", network beets_default
docker exec -u abc beets beet -c /config/probe-04/broken.yaml -l /config/probe-04/probe.blb version
# ... probe steps (Code Example 4/5) ...
docker compose -f "$F" --env-file "$E" --profile manual down                # removes container + beets_default
docker ps -a --format '{{.Names}}' | grep -cx beets                         # must be 0 — NO status filter
```
**Known side effects of `up` to record, not avoid:**
- LSIO `init-beets-config` runs `lsiown -R abc:abc /config`, which covers the 1.4 GB `Music/__`.
  `cp -n` of the defaults is a no-op because `config.yaml` exists. `[CITED: docker-beets init-beets-config/run]`
- `svc-beets` runs `s6-setuidgid abc beet web` `[CITED: docker-beets svc-beets/run]`. With no
  `plugins:`/`library:` in `/config/config.yaml` that means: default library
  `/config/library.db`, which **will be opened and migrated 2.5.1→2.13.1 with `.bak` files**; no
  `web` plugin, so `beet web` fails and s6 restarts it. `[ASSUMED from source: A3]`
- Port 8337 is free on LXC 100 `[VERIFIED]`.

Record the survivor DBs' sha256 and the `.bak` count before and after. The fence holds both
pre-migration copies `[VERIFIED]`.

### Pattern 3: A guard whose first run is its own negative control

Land the D-21 census and D-13 drift assertion **before** the deletions they guard. Run them on the
un-retired estate: they must go **red**, naming each retired DB path that still exists. Then run
them green after deletion. That is a *driven* negative control against a real, not synthetic,
failure. Keep an env-overridable expectation (the `EXPECT_*` precedent from 02.1-11) for a second,
repeatable control that perturbs the **expectation**, never the file.

### Anti-Patterns to Avoid

- **`docker ps --filter status=…` for "containers are gone".** It misses `created`
  (memory `docker-created-state-blind-spot.md`). Use `docker ps -a`, unfiltered.
- **`find -xdev` over `/mnt/fast` for a DB census.** It stops at child datasets and returns
  **zero** results with **exit 0**. Measured today, and it would have reported "no beets DBs on
  the estate". Always carry a positive control: the census must list the 5 known DBs.
- **`timeout N cmd | wc -l`** exits 0 on timeout (README § Health Checks). Put
  `set -o pipefail` in the remote string and read the ssh RC.
- **Passing a secret or token in argv**, even to a count (DEF-03-21). Relevant if DNS removal
  uses the Cloudflare token: read it from the file inside the process, never `-H "Authorization:
  Bearer $(cat …)"` on a command line that `ps` can show.
- **`docker compose config` without `--quiet`** renders the resolved `.env` (secrets) to stdout
  (03-04 finding).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Is `renovate.json5` valid? | Node `JSON5.parse` + shape assertions (the 02.1-08 stopgap) | `renovate-config-validator --strict --no-global` | Parse-OK ≠ valid. The validator caught the `matchUpdateTypes`+`versioning` conflict that a parse cannot, and rejects a misspelled key (`automerg` → exit 1, measured) |
| Copy a live SQLite DB into the fence | `cp` | `sqlite3 SRC ".backup DEST"` + `PRAGMA integrity_check` | 01-02's method. `MANIFEST.txt` documents the non-byte-identical-by-design copies |
| WAV ID3 write | `mutagen.File(easy=True)` | `mutagen.wave.WAVE` + `add_tags()` + `tags.setall(...)` | DEF-03-09: easy mode yields a raw `ID3` on WAVE → `TypeError` on every file |
| Read RIFF `LIST`/`INFO` (`IPRD`) | Python `chunk` module | ~20 lines of `struct` over the RIFF chunk list | mutagen's WAVE API does not expose INFO `[CITED: docs silent]`; `chunk` was removed in Python 3.13 `[ASSUMED]` |
| Counting non-empty lines under `pipefail` | `grep -v '^$' \| wc -l` | `awk 'NF{n++} END{print n+0}'` | awk exits 0 on zero matches. grep exits 1 and aborts under `set -e` |
| Compose file validity after edits | eyeballing | `docker compose -f … config --quiet` | Measured exit 0 today, the baseline to compare against |

## Runtime State Inventory

> Retirement phase. After every repo file is updated, these still carry the retired taggers.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| **Stored data** | (1) `/mnt/fast/appdata/media/wrtag/data/wrtag.db`, 315,392 B, 2026-01-23: **not fenced**. (2) `/mnt/fast/appdata/arrs/soulbeet/`: `data/` empty since 2026-01-05, plus `beets_config.yaml` (sha `83028925…` **== repo copy**, so git covers it). (3) sabnzbd `config/scripts/library.blb` + 11 `.bak` (**regenerated every music job**) + `beets.log` (12 KB, 89 imports since 2026-01-04, **the only record of the 1 Aug / 8 Aug skips**; line 276's wrong path means `audio.bash` never deletes it). (4) sabnzbd `config/.config/beets/library.db` + 11 `.bak` (Phase 1 probe artefact). (5) Survivor: `library.db` + `musiclibrary.blb` (both fenced), `config.yaml` (compose junk), `config.yaml.old` (LSIO default, **no musicbrainz, arms scrub/lastgenre**), `state.pickle`, `Music/__` (~1.4 GB). **Census method:** `find /mnt/fast` without `-xdev`, heavy trees pruned, 5/5 positive control; `find` RC 1 = unreadable subpaths, stderr suppressed. 22 DB `.bak` files total under `appdata/arrs` | **Data migration** (fence copies) for (1) and the `beets.log` half of (3). **Deletion** for (1)–(4) after their fence asserts. (5) needs rulings (OQ1, OQ2). `Music/__` untouched |
| **Live service config** | **Cloudflare DNS: `wrtag.deercrest.info` resolves (proxied, CF anycast)**. A random-name control returns nothing, so this is an explicit record, not a wildcard. `beets.deercrest.info` also resolves (survivor, keep). No `soulbeet` record. Renovate Dependency Dashboard #3 carries `Failed to look up … ghcr.io/terry90/soulbeet`. GitHub #306 OPEN. **PR #310 open** (`sabnzbd 5.1.0 → 5.1.3`, labelled automerge, since 2026-08-18). `sabnzbd.ini`: `[[music]] script = audio.bash` (unchanged). `extended.conf`: `BeetsTagging="TRUE"` (left). No Traefik/Authelia/Homepage config references wrtag/soulbeet (grep over appdata `*.yml/yaml/json/conf/toml/ini`, depth 5). **No Uptime Kuma/Homepage/Gatus DB found** at depth 4, so nothing to inspect | DNS record: removal via Cloudflare API with traefik's DNS-01 token, **host-side** (memory `cloudflare-dns-deercrest-access.md`) **(needs ruling: not in CONTEXT)**. Dashboard warning: self-clears after deletion (verification signal). #306: D-26. PR #310: check image residency before any sabnzbd recreate (Pitfall 8) |
| **OS-registered state** | **None.** LXC 100 crontabs/`/etc/cron.d` and systemd unit-files/timers: no `beet\|wrtag\|soulbeet\|audio.bash` (grep RC 1). atlantis: same, none | None. Verified 2026-09-11 |
| **Secrets / env vars** | `stacks/selfhosted/arrs/.env` holds `SOULBEET_SECRET_KEY`, `SLSKD_*` and wrtag's `WRTAG_API_KEY` is interpolated from some `.env`. **Names referenced by the deleted YAML only**. Values never read in this research. `/mnt/fast/secrets/discogs.env` (D-24: leave) | Code edit only: the variables become unreferenced. Removing them from the host `.env` is optional hygiene, never print values. Nothing breaks if left |
| **Build artifacts / images** | Resident: `sentriz/wrtag:v0.20.0` (172 MB), `metasauce/beets-flask:v2.0.0-rc6` (1.12 GB, Phase 5), `lscr.io/linuxserver/beets:2.13.1-ls349` (638 MB, survivor). `spike03-image-headroom.sh` **KEEP_PATTERNS protects `sentriz/wrtag` from ever being reaped**. No docker volumes or networks named for any tagger; no `music` compose project (`docker compose ls -a`). **sabnzbd's `scripts_init.bash` `pip install -U beets[…]` on every boot**, so beets stays installed in sabnzbd after this phase (host-only file, sha `b3927…`, **not in git**) | Remove `sentriz/wrtag` from KEEP_PATTERNS (D-07 "corrected"). Optionally reap it through the two-process gate (never `docker image prune -a`). `pip -U` is **inventory, not scope** (Phase 8) |

## D-07 sweep: every `wrtag|soulbeet` hit, with a proposed verdict

Command: `git ls-files | xargs grep -il 'wrtag\|soulbeet'`. It returns **14 files outside
`.planning/`** and **72 inside it** `[VERIFIED: repo grep 2026-09-11]`. README.md, DEPLOYMENT.md,
NETWORK.md and MEDIA.md have zero hits.

| File | Hits (lines) | Verdict | Reason / action |
|---|---|---|---|
| `stacks/selfhosted/arrs/soulbeet.yaml` | whole file | **delete** | D-01 |
| `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` | whole file | **delete** | D-01. Byte-identical to the host copy (`83028925…`), so git history covers it. Name the pre-deletion SHA in the #306 comment (Pitfall 14) |
| `stacks/selfhosted/music/compose.yaml`, `music/wrtag.yaml` | whole files | **delete (whole directory)** | D-05 |
| `stacks/selfhosted/arrs/compose.yaml` | `#  - soulbeet.yaml` | **delete line** | D-06. See F11 for the separate `#  - beets.yaml` path defect (needs ruling) |
| `renovate.json5` | 90–104 (the rule); 452 (Jellyfin description cites `packageRules[3]` "the wrtag pin" and `packageRules[5]`) | **delete** the rule; **correct** the description text | D-14; Pitfall 6. Add the two beets rules (Code Example 1) |
| `CLAUDE.md` | 102 (#306); 163–168 (headline 1); 198; 212–236 (head-to-head + overturning table, incl. 234's "7,451 files across ~1,000 folders"); 206 ("7,451-file import"); 276–279 (install block "EITHER fix the pin"); 283; 293–294; 315–316; 325–327; 332/338 (sources) | **correct** | D-07/D-14. Land the verbatim Phase 3 sentence. Lines 91–157 are generated from `PROJECT.md` and 159–343 from `.planning/research/STACK.md` (F15), so correct the sources or add dated notes there too. **Keep** line 309's `1-115` split instruction: `beets.md` § Phase 3 records that a later measurement found the set **exists** (45 G, 4,746 files), retracting 03-DECISION's "does not exist" |
| `stacks/selfhosted/arrs/beets.md` | 4 (header link); 13 (banner); 27–47 ("Two beets, one library" table, and "the real tunables live in `soulbeet/beets_config.yaml`"); 92; 237; 269; 280; 958 | **correct** header, banner and table. **Keep** the dated phase sections (historical; amend in-band). **Add** the D-14 verbatim correction and the D-25 closure section | Living operational doc |
| `stacks/selfhosted/arrs/sabnzbd.yaml` | 93 ("Same hybrid shape as arrs/soulbeet.yaml") | **correct** | Also correct in the same pass: 56–61 ("audio.bash line 285", false after the strip); 89–90 ("Plan 01-09 folds that comparison into quick-health-check.sh", false today, F6); 93–94 ("knowingly broken … Phase 4 TAGR-05 owns it") |
| `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` | 13 ("Same hybrid shape as soulbeet/beets_config.yaml") | **correct** | Also 3–8 (consumer header: nothing invokes it after the strip) and 24–35 (KNOWN DEFECT block, fixed by TAGR-05). The file's own rule (line 22): re-screen for credentials before committing |
| `scripts/check-music-freeze.sh` | 80 (`TAGGER_PATTERN`); 252 (section-2 prose naming `arrs/soulbeet.yaml`) | **correct** | D-21 |
| `scripts/spike03-image-headroom.sh` | 112 (KEEP_PATTERNS `"sentriz/wrtag"`) | **correct** (remove the entry) | Pitfall 11. Keep `metasauce/beets-flask` (Phase 5) and the beets entries |
| `scripts/spike03-wrtag-arms.sh` | 66 hits; the default `WRTAG_YAML=stacks/selfhosted/music/wrtag.yaml` at 147 | **keep-with-reason**, plus a header note | Phase 3 criterion-3 instrument, cited by `03-WRTAG-EVIDENCE.md`. Still reproducible via `git show <pre-deletion-sha>:stacks/selfhosted/music/wrtag.yaml > <scratch>` with a `WRTAG_YAML=` override. Deleting it destroys the reproducibility of a recorded measurement |
| `.gitignore` | 45 (comment example naming `stacks/selfhosted/music/wrtag.yaml`) | **correct** the example | It points at a deleted file |
| `.planning/PROJECT.md` | 58–66 (entry-points table; 64 = the wrtag row) | **correct in-band, dated** | Living doc. The 7,451 **file** count at 72 is right (03-DECISION: "the file count was right") |
| `.planning/REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` | traceability and history | **keep**; D-20 amendments only | Historical record |
| `.planning/research/{ARCHITECTURE,FEATURES,PITFALLS,STACK,SUMMARY}.md` | dated research snapshot | **keep-with-reason**; `STACK.md` gets a dated forward-pointer | F15 |
| `.planning/phases/**` (the remaining ~63 files) | — | **keep** | Provenance. Never rewritten |

**Widen the sweep by one grep after the strip.** This phase *creates* new stale references that
the `wrtag|soulbeet` pattern cannot see:

```bash
git grep -nE 'library\.blb|line 285|beets\.log|01-09 folds|Two beets|soulbeet\.deercrest'
```

Every hit gets the same delete / correct / keep-with-reason treatment.

## `audio.bash` anatomy (live, 339 lines, sha256 `fdcddca234b2…`)

| Lines | Step | Mutates the download? | Active with today's `extended.conf`? |
|---|---|---|---|
| 27–35 | `SAB_PP_STATUS` guard (**byte-identical, D-10**) | no | yes |
| 41 | `source /config/extended.conf` | — | yes |
| 64–65 | `set -e; set -o pipefail` (**global**, applies to 334) | — | yes |
| 133–158 | `clean()`: deletes non-audio files, flattens subdirs, deletes empty dirs, **deletes MP3s when FLAC present** | **yes (file deletion)** | yes, always |
| 160–165 | `detectsinglefilealbums()`: exit 1 on a file > `MaxFileSize` (153600k) | no (fails job) | yes (`DetectNonSplitAlbums="TRUE"`) |
| 167–188 | `verify()`: `flac -t`. **On failure `rm -rf "$1"/*`** | **yes (deletion)** | yes (`AudioVerification="TRUE"`) |
| 190–261 | `conversion()`: ffmpeg transcode | would rewrite | **no-op** (`ConversionFormat="FLAC"`) |
| 120–131 | `AudioQualityMatch()` | would delete | no (`RequireAudioQualityMatch` unset) |
| 263–267 | `replaygain()`: `r128gain` **writes tags** | would tag | **no** (`ReplaygainTagging="false"`) |
| 269–302 | `beets()`: 272–273 `rm library.blb`; 276 tests the **wrong path** `/config/scripts/beets/beets.log`; 281 `touch beets-match`; **285 `beet … import -q`**; 286–295 "SUCCESS"/"**ERROR: Unable to match**" + `requireBeetsMatch` branch | 285 would tag (never matches, so it never has) | yes (`BeetsTagging="TRUE"`, `requireBeetsMatch="false"`) |
| 322–324 | `if BeetsTagging = TRUE; then beets "$1"` | — | yes |
| 334–335 | `chmod 777 "$1"; chmod 666 "$1"/*`: **EPERM on tank → `set -e` → Exit(1)** | no (fails) | yes (every job) |

**D-10 inventory result:** after the line-285 strip, **no tag-writing step is active** under
today's `extended.conf`. `r128gain` is the only other tag writer and it is off. The file-deleting
steps (`clean`, `verify`) are not tag writers and stay (Phase 8). "Folder lands untagged" (D-12) is
therefore a true expectation, **conditional on `ReplaygainTagging="false"`**. Record that
dependency in the evidence.

## Common Pitfalls

### Pitfall 1: D-18's album is gone, and the backlog is a live tree
**What goes wrong:** the plan names a folder that no longer exists (F1). A substitute can also move
before execution: Lidarr imports, and new jobs land daily. **Avoid:** name the substitute with its
selection criteria, and assert presence + 12 FLAC at execution time. **Never** run `import -t`
without `-W -C` (the source is on a `:rw` downloads mount).

### Pitfall 2: Line-285-only strip keeps beets "talking"
**What goes wrong:** `Audio.txt` keeps printing `Matching 36 tracks with Beets` and
`ERROR: Unable to match using beets…` (F7). A verifier greps `Audio.txt` for "Beets" and concludes
beets ran. **Avoid:** D-12's evidence must say, before the job runs, that those two lines are
expected and why (the function body and gate remain), and that the proof of non-invocation is
the absence of `library.blb`, `.bak`, `beets.log` and `beets-match` side effects. Or seek a
ruling to strip 322–324 too.

### Pitfall 3: The Exit(1) that is not a regression
**What goes wrong:** every music job already ends `Completed` + `Exit(1): chmod: changing
permissions …` (F8). Read after the strip, it looks like the strip broke post-processing.
**Avoid:** capture the baseline history rows in plan 1. The D-12 pass condition is "same status
and same script line as baseline, with no beets side effects".

### Pitfall 4: D-15 as written is inert, and the obvious fix fails validation
See F9 and Code Example 1. **Warning sign:** the Dependency Dashboard lists the beets tag with no
`→ Updates` long after a newer release exists.

### Pitfall 5: `renovate-config-validator FILE` validates the wrong thing
It validates as **global** config (F13). **Avoid:** `--no-global`, or run it with no argument from
a directory holding the file. Fix `check-renovate.sh:62` in the D-22 pass.

### Pitfall 6: Deleting `packageRules[3]` silently falsifies another rule's description
The Jellyfin rule's description (`renovate.json5:452`) cites **`packageRules[2]`** (still correct),
**`packageRules[5] only catches MAJOR`** (becomes `[4]`) and **"see packageRules[3], the wrtag
<0.30.0 pin"** (becomes the Security rule). Measured with the edited config: major rule index 5→4,
Jellyfin 36→35, beets rules appended at 36/37. **Avoid:** rewrite those references by *description*,
not index. This is a text-only edit, and re-run the validator after it. STATE.md's "index 38" for
Jellyfin was already not a 0-based index (it is 36 today).

### Pitfall 7: `:ro` bind mounts vs LSIO's boot-time ownership passes
**What happens (from source):** sabnzbd's `init-sabnzbd-config` runs
`find /config … -exec lsiown abc:abc {} +`, which reaches the `:ro` files. `scripts_init.bash:~128`
runs `chmod 777 -R /config/scripts`. Both will hit EROFS on the `:ro` files.
`[CITED: docker-sabnzbd init-sabnzbd-config/run]` `init-custom-files` logs a non-zero exit and
continues, never fatal `[CITED]`. `scripts_init.bash` has **no `set -e`** and ends
`chmod … ; if …; fi; exit`, so it exits 0 regardless `[VERIFIED: file]`. `lsiown` itself was **not
located in source**. It is assumed to tolerate EROFS with a warning `[ASSUMED: A1]`.
**Avoid:** the D-09 boot proof must capture: `[custom-init] scripts_init.bash: exited 0`
(baseline boot shows exactly this), any `lsiown`/`chmod` EROFS lines, container `running`,
SABnzbd HTTP 200, and both files' sha256 unchanged. Then a job (D-12) proves post-processing.

### Pitfall 8: A sabnzbd recreate is not just a recreate
- `scripts_init.bash` runs `pip install -U beets[…]` + `git clone` SMA + `curl sma.ini` on every
  boot: network-dependent, slow, and beets floats to PyPI latest.
- **PR #310 (5.1.3) is open with automerge labels.** If it merges and the host pulls, the D-09
  recreate **pulls a new image onto `/`** and bundles a version change into the boot proof.

**Avoid:** assert `docker image ls` residency of the exact tag in `sabnzbd.yaml` before
`up -d sabnzbd` (the 02.1-05 lesson). A recreate also interrupts active downloads, so check the
queue.

### Pitfall 9: The probe drags a dismissed credential into the survivor
F14. **Avoid:** give `spike03-discogs-probe.py` an explicit MB-only mode (no `DISCOGS_USER_TOKEN`
in `REQUIRED_ENV`, no identity probe, `--require-plugin musicbrainz`, refuse if `discogs` is in
the loaded plugins). Deliver the script into the survivor via its `/config` bind
(`/mnt/fast/appdata/arrs/beets/config/probe-04/`), never `docker exec -e`.

### Pitfall 10: `beet` writes more than the `-l` DB
With an explicit `-l`, the import session still writes `statefile` (default
`BEETSDIR/state.pickle` = the survivor's `/config/state.pickle`) and the import log if configured.
The sabnzbd config sets `import.log: /config/scripts/beets.log`, a path absent in the survivor.
**Avoid:** the probe overlay sets `statefile:` and `import.log:` under `/config/probe-04/` and
`import.write: no`, `copy: no`, `move: no`. Pass `-W -C` anyway. Abort (`b`) at the timid prompt.
Delete `/config/probe-04/` afterwards and assert the survivor tree's file list matches its
pre-probe list apart from the recorded migration `.bak` files. `[ASSUMED: A4 on statefile write]`

### Pitfall 11: The retired image is protected from reaping forever
`spike03-image-headroom.sh` KEEP_PATTERNS still lists `sentriz/wrtag`. After this phase nothing
references it, yet no future inventory will ever list it. **Avoid:** remove it from KEEP_PATTERNS
in the D-07 sweep.

### Pitfall 12: Blind census instruments
`find -xdev` across ZFS children (measured: 0 results, exit 0). A container enumeration using
`docker ps -q` (running only), which is what `check-music-freeze.sh:190` does today. "Idle" in the
phase goal includes exited and created. **Avoid:** the D-21 section enumerates `docker ps -aq`,
and every census carries a positive control and prints `UNKNOWN` (not `0`) when its input was
unobservable (DEF-03-11).

### Pitfall 13: `beets.log` is evidence, and it is not publishable
It is the only record proving the 1 Aug / 8 Aug skips (the claim D-17 turns into a measurement).
It is also a list of release folder names. **Avoid:** copy it into `/mnt/fast/safety` (not the
public repo) before D-11 deletes it. Quote only the lines the evidence needs.

### Pitfall 14: #306's own proposal is unanswered by a bare close
The issue body proposes *folding soulbeet's config into the manual beets config before deleting*,
and says "Blocked on the direction in #305". **Avoid:** the D-26 closing comment should say the
salvage is deliberately **not** done here, because Phase 6 (CONF-01…05) owns the survivor's config
and Phase 3 set the direction. The config stays recoverable from git history (name the commit
SHA before deletion).

### Pitfall 15: D-21's classifier will always flag sabnzbd
D-11 keeps `beets-config.yaml` bind-mounted in sabnzbd, and sabnzbd's `/config` bind contains the
beets DB paths until they are deleted. A mount-based classifier therefore labels sabnzbd
tagger-class **permanently**. That is correct, but it must not read as a failure: sabnzbd holds
**no `/mnt/tank/media` mount at any mode** `[VERIFIED]`. **Avoid:** report per container
"tagger-capable (mounts a beets config/DB)" separately from "rw on the library". The
criterion-5 counter is the second.

## Code Examples

### 1. The beets Renovate rules: the only shape that both works and validates
```json5
// Source: validated with renovate-config-validator 44.80.0 --strict (repo mode AND --no-global), 2026-09-11.
// Append AFTER the Jellyfin rule (i.e. after packageRules[2], so it wins on automerge).
{
  "description": "beets: LSIO tag scheme. Default docker versioning treats '-ls349' as a COMPATIBILITY suffix and never proposes an update (the Dependency Dashboard listed 2.5.1-ls295 with no update for months). A rule may not combine versioning with matchUpdateTypes, so versioning lives here alone. build (lsNNN) bumps are handled like PATCH.",
  "matchDatasources": ["docker"],
  "matchPackageNames": ["lscr.io/linuxserver/beets"],
  "versioning": "regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)-ls(?<build>\\d+)$"
},
{
  "description": "beets: minor and major require manual review; patch automerge preserved; NO allowedVersions ceiling (see the retired wrtag <0.30.0 pin, deleted in Phase 4, which enforced a broken state for months). beets 2.4.0 turned MusicBrainz into a plugin and silently disabled autotagging — a MINOR release changing semantics.",
  "matchDatasources": ["docker"],
  "matchPackageNames": ["lscr.io/linuxserver/beets"],
  "matchUpdateTypes": ["minor", "major"],
  "automerge": false,
  "addLabels": ["stack:arrs", "major-update", "manual-review-required"]
}
```
Measured failures, so nobody retries them:
- `versioning` + `matchUpdateTypes` in one object → `ERROR: packageRules[36]: packageRules cannot
  combine both matchUpdateTypes and versioning` (exit 1).
- The plain (no-`versioning`) mirror validates, but is inert (F9).

`build`→patch semantics: `[CITED: docs.renovatebot.com/modules/versioning/regex]` ("`build` and
`revision` updates are handled like `patch` updates").

### 2. Validator invocation and its negative control
```bash
# repo semantics; both exit 0 on today's file and on the edited file
renovate-config-validator --strict                      # discovery mode, run where renovate.json5 is
renovate-config-validator --strict --no-global renovate.json5
# negative control (measured exit 1): a copy with a misspelled key, e.g. "automerg": false
```

### 3. `check-renovate.sh` pipefail repairs (D-22)
```bash
# 115/138/157 — count non-empty lines without an exit-1-on-zero grep:
POSTGRES_COUNT=$(printf '%s\n' "$POSTGRES_INSTANCES" | awk 'NF{n++} END{print n+0}')
# 90/100 — a grep that may legitimately match nothing must not abort the script:
YAML_WITH_IMAGES=$( { grep -rl "image:" stacks/selfhosted --include="*.yaml" --include="*.yml" || true; } | sort)
# 62 — repo semantics:
renovate-config-validator --no-global "$CONFIG_FILE"
# Driven control for 157 (the inverted one): run with an empty RENOVATE_BRANCHES, e.g. a PATH-stubbed `git`
# whose `branch -r` prints nothing — expect "✅ No pending Renovate PRs" and exit 0 (unreachable today).
```
Also note: lines 101–103 use `sed 's/^\s*…'`, and `\s` is a GNU extension that BSD sed on the
workstation does not honour `[ASSUMED: A6]`. It is out of D-22's scope, so record it rather than
silently fixing it.

### 4. Criterion-4 probe overlays (D-16/D-17): only `plugins:` differs
```yaml
# /mnt/fast/appdata/arrs/beets/config/probe-04/broken.yaml  = the LIVE sabnzbd beets-config.yaml verbatim, plus:
statefile: /config/probe-04/state.pickle
import: { write: no, copy: no, move: no, log: /config/probe-04/import.log }
# probe-04/fixed.yaml = byte-identical except:   plugins: embedart musicbrainz
```
```bash
docker exec -u abc beets beet -c /config/probe-04/broken.yaml -l /config/probe-04/probe.blb version  # plugins: embedart
docker exec -u abc beets beet -c /config/probe-04/fixed.yaml  -l /config/probe-04/probe.blb version  # plugins: embedart, musicbrainz
# tag_album probe, MB-only mode (Pitfall 9), same album, same -l:
docker exec -u abc -e SPIKE_CONFIG=/config/probe-04/broken.yaml -e SPIKE_DB=/config/probe-04/probe.blb beets \
  python3 /config/probe-04/spike03-discogs-probe.py --mb-only --require-plugin musicbrainz "/downloads/complete/nzb/music/<album>"
#   broken → expect: plugin gate REFUSES (musicbrainz not loaded) or a `no_candidates` record — decide which the plan asserts
#   fixed  → expect: ≥1 record with "source": "MusicBrainz"
# hand-read cross-check (agent-driven is acceptable per the operator's T3 words), abort at the prompt:
printf 'b\n' | docker exec -i -u abc beets beet -c /config/probe-04/fixed.yaml -l /config/probe-04/probe.blb \
  import -t -W -C "/downloads/complete/nzb/music/<album>"
```
`-c` is an **overlay merged over** `/config/config.yaml`, not a replacement
`[CITED: beets.readthedocs.io/en/stable/reference/cli.html]`. That is harmless here because the
survivor's base file has no `plugins:` key. **Design decision for the plan:** the existing probe's
refusal-1 plugin gate will *refuse* to run when `musicbrainz` is absent. For the negative control
the plan must choose between asserting "the refusal names the missing plugin" and running with
`--require-plugin embedart` to obtain a genuine `no_candidates` record. The second is closer to
"record **zero** candidates" (D-17).

### 5. Fence copy of `wrtag.db` (plan 1)
```bash
D=/mnt/fast/safety/music-pre-project/library-db
sqlite3 /mnt/fast/appdata/media/wrtag/data/wrtag.db ".backup '$D/media_wrtag_data_wrtag.db'"
sqlite3 "$D/media_wrtag_data_wrtag.db" "PRAGMA integrity_check;"      # must print exactly: ok
cp -p /mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log "$D/../audit/sabnzbd-beets.log.$(date -u +%Y%m%dT%H%M%SZ)"
# append both to MANIFEST.txt with sha256 — the fence's own convention
```

### 6. Drift assertion (D-13), one bounded ssh, host-side comparison of both vendored files
```bash
DRIFT_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 'set -o pipefail; cd /mnt/fast/stacks || exit 3
  for p in audio.bash beets-config.yaml; do
    r=$(timeout '"$REMOTE_TIMEOUT"' git show "HEAD:stacks/selfhosted/arrs/sabnzbd/$p" | sha256sum | cut -d" " -f1) || exit 4
    h=$(timeout '"$REMOTE_TIMEOUT"' sha256sum "/mnt/fast/appdata/arrs/sabnzbd/config/scripts/$p" | cut -d" " -f1) || exit 5
    echo "$p repo=$r host=$h"; done')
DRIFT_RC=$?
# empty output first (zero-byte/unreachable → UNKNOWN), then RC 124 (timeout → UNKNOWN), then RC≠0 (could not look),
# then compare repo==host per line → fail() naming the file with both hashes. Never info().
# Negative control: DRIFT_EXPECT_OVERRIDE / point the host path at a scratch copy — perturb the expectation, not the file.
```
`git show HEAD:` makes a dirty host working tree irrelevant. The host checkout must be pulled
first (it was 1 commit behind origin on 2026-09-11).

### 7. mutagen WAVE write (D-23), from DEF-03-09's measured probe
```python
import mutagen.wave, mutagen.id3
w = mutagen.wave.WAVE(path)
if w.tags is None:
    w.add_tags()
w.tags.setall("TALB", [mutagen.id3.TALB(encoding=3, text=[new])])   # per field via FIELD_FRAME
w.save()
# read path: w.tags.getall(FIELD_FRAME[field]) — NOT mutagen.File(easy=True)
```
The regression test runs **inside the beets image**, the only place mutagen exists
(`--self-test` inside the script, the estate's convention; there is no pytest in this repo). Build
its three WAVs synthetically:
- **untagged:** the stdlib `wave` module writes a short silent PCM file
- **ASCII:** `add_tags()` + `TIT2`/`TPE1`/`TRCK`/`TDRC`/`APIC`
- **non-ASCII:** the same with a non-ASCII `TPE1`, plus a hand-written RIFF `LIST/INFO/IPRD` chunk

Assert the written album reads back and the other five frames are byte-equal. The dry-run NDJSON
gains an `info_iprd` field whenever `IPRD` disagrees with the new `TALB`.

### 8. D-12 evidence: read-only, no API key needed
```bash
sqlite3 "file:/mnt/fast/appdata/arrs/sabnzbd/config/admin/history1.db?mode=ro" \
  "SELECT datetime(completed,'unixepoch'), status, script_line FROM history WHERE category='music' ORDER BY completed DESC LIMIT 3;"
# before/after the job, from one stamp: no library.blb, no *.bak, no beets.log, no beets-match under /config/scripts
find /mnt/fast/appdata/arrs/sabnzbd/config/scripts -newer <stamp> -printf '%p\n'   # expect only logs you name
```
SAB history `completed` is UTC; `sabnzbd.log` and `beets.log` are container-local (Europe/Dublin,
UTC+1). Do not compare them naively.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `fileMatch` | `managerFilePatterns` (glob or `/regex/`) | Renovate 41 | Already in use. The first pattern string is a regex-shaped *glob* (probably matches nothing, harmless). **Out of scope** |
| Default `plugins: []` | `plugins: [musicbrainz]` default; customised lists must name it | beets 2.4.0 (2025-09) | TAGR-05's whole reason |
| `--pretend` as a match test | `tag_album()` probe / `import -t` | always (pretend never autotags) | D-16/D-20 |
| Renovate `docker` versioning for LSIO tags | `regex:` versioning with `-ls(?<build>\d+)` | documented pattern | Estate-wide: **every `-lsNNN` pin is silently frozen today**. Only beets is in scope |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | LSIO `lsiown` tolerates EROFS on a `:ro` file with a warning, not a failure | Pitfall 7 | If it aborts init, sabnzbd fails to start on the D-09 recreate. The boot proof catches it. Rollback = restore `:rw` |
| A2 | Renovate will propose `2.13.1-ls350` as a patch-class update and automerge it via `packageRules[1]` once regex versioning lands | Code Ex. 1, OQ4 | If not, the rule is inert in a new way. Check the dashboard after merge |
| A3 | Starting the survivor opens and migrates `/config/library.db` (svc `beet web`, no `library:` key) and `beet web` crash-loops for want of the `web` plugin | Pattern 2 | Only noise if wrong. The fence covers the DB either way |
| A4 | A `beet import` session writes `statefile` (default `BEETSDIR/state.pickle`) even with `-l`/`-W`/`-C` and an abort | Pitfall 10 | A stray write to the survivor's `state.pickle`. Mitigated by setting `statefile:` in the overlay |
| A5 | Python's `chunk` module is removed in 3.13 | Don't Hand-Roll | Low. The recommendation (manual `struct` parse) is safe either way |
| A6 | BSD sed does not honour `\s` in `check-renovate.sh:101-103` | Code Ex. 3 | Cosmetic inventory miscount on the workstation only |
| A7 | MusicBrainz's 12-track 2001 *Scarecrow* is the release the folder's audio actually is | F1 / OQ3 | The negative/positive pair still discriminates. The candidate may just score lower |
| A8 | `renovate` npm package legitimacy (slopcheck unavailable in check-only mode) | Package audit | Negligible: official repo, 205k/wk, pinned version, `--ignore-scripts` |

## Open Questions (for the planner, several for the operator) (RESOLVED)

> **All ten resolved on 2026-09-11**, after this document was written. The operator ruled on
> OQ1–OQ8; OQ9 and OQ10 were settled by the orchestrator within CONTEXT's discretion. The
> questions below are kept as written; the answers are in `04-CONTEXT.md` § *Operator rulings
> after research* and in the plans:
>
> | OQ | Resolved by | Ruling |
> |---|---|---|
> | 1 | D-27 | Minimal vendored survivor config (`plugins: musicbrainz`, SAFE-01 keys, explicit `library:`); `config.yaml.old` deleted |
> | 2 | D-28 | **Neither** — both old survivor DBs deleted after fence check; one fresh `library.db` at the explicit path |
> | 3 | D-29 | Scarecrow, presence re-asserted at execution |
> | 4 | D-30 | Two-rule shape, effective; the `ls350` PR is expected |
> | 5 | D-31 | Line 285 only; residual log lines and baseline `Exit(1)` pre-declared |
> | 6 | D-32 | Delete sabnzbd `.config/beets/` after fence check |
> | 7 | D-33 | Remove the DNS record host-side, token never on argv |
> | 8 | D-34 | Correct the include line to `#  - beets/beets.yaml` |
> | 9 | plan 04-12 | Human checkpoint: trigger a Lidarr search or wait for an organic job; OPEN if none arrives |
> | 10 | plans 04-10/04-11 | `beets-config.yaml` goes `:ro` in the same recreate as `audio.bash`; `:rw` rollback only if boot fails |

1. **The survivor's host `config.yaml` (TAGR-05).** It is compose junk, not in the repo, with no
   `plugins:` key. *Recommendation:* replace it with a minimal beets config (`plugins: musicbrainz`
   + the three SAFE-01 keys + explicit `library:`), **vendored** into the repo with the 01-07
   hybrid shape, so "every remaining beets config declares musicbrainz" is checkable in git. Delete
   `config.yaml.old` (the LSIO default arms scrub/lastgenre and omits musicbrainz). **Needs
   ruling:** CONTEXT assigns the survivor's configuration to Phase 6. This is the minimal slice
   TAGR-05 forces.
2. **Which survivor DB is "the one"?** `library.db` (what beets opens today, holds the Nov 2025
   import) or `musiclibrary.blb` (LSIO default, Oct 2025). *Recommendation:* keep `library.db`,
   because it is what the container actually uses. Delete `musiclibrary.blb` (fenced).
   **Needs ruling.**
3. **D-18 substitute.** *Recommendation:* `Garth Brooks-Scarecrow-CD-FLAC-2001-FLACME-xpost`
   (F1). **Needs ruling.**
4. **Make D-15 effective (two-rule shape) or leave it inert on purpose?** Effective means an
   immediate `ls349→ls350` patch PR that automerges in the **repo only** (deploy drift keeps the
   host on ls349). *Recommendation:* effective, and record the ls350 PR as expected.
   **Needs ruling.**
5. **Line 285 only, or 285 + the 322–324 gate?** (F7). *Recommendation:* honour D-10's letter.
   Pre-declare the residual log lines in the D-12 evidence.
6. **`sabnzbd/config/.config/beets/` deletion** (F3). *Recommendation:* delete (fenced).
   **Needs ruling.**
7. **Cloudflare `wrtag` DNS record.** *Recommendation:* remove, host-side, token never in argv.
   **Needs ruling** (not in CONTEXT).
8. **`#  - beets.yaml` → `#  - beets/beets.yaml`** (F11). *Recommendation:* correct the path.
   **Needs ruling** (D-06 says "stays").
9. **D-12 trigger.** Organic music jobs arrived 1 Aug, 8 Aug, 3 Sep ×2, 5 Sep, 6 Sep and 11 Sep,
   so about one every 1–5 days. *Recommendation:* a human checkpoint that either triggers a Lidarr
   search or waits for the next organic job. Never script SAB with an API key on argv.
10. **`beets-config.yaml` `:rw` → `:ro`** (D-09 discretion). The boot proof applies identically to
    both files. *Recommendation:* do both in the same recreate. If EROFS lines appear but the
    container is healthy, keep `:ro` and record the lines.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| ssh → LXC 100 (172.16.1.159) | every host step | ✓ | — | — |
| ssh → atlantis (172.16.1.158) | none required (census done) | ✓ | — | — |
| docker / compose on LXC 100 | survivor, sabnzbd recreate | ✓ | compose v2 | — |
| `lscr.io/linuxserver/beets:2.13.1-ls349` | D-03/D-19/D-23 | ✓ resident | ls349 | — (never pull on LXC 100 without a `/` check; `/` free 33.1 GiB) |
| sqlite3 on LXC 100 | fence copy, history read | ✓ | — | — |
| ffprobe on LXC 100 | D-12 tag evidence | ✓ | — | — |
| mutagen | D-23 | ✗ host, ✗ workstation, **✓ in beets image** (1.48.1) | 1.48.1 | Run inside the image |
| `renovate-config-validator` | criterion 2 | ✗ installed; ✓ via scratch npm install (measured) | 44.80.0 | Docker image on the workstation |
| node / npm (workstation) | validator | ✓ | 26.8.2 / 11.19.1 | — |
| `gh` (authenticated) | #306, dashboard | ✓ | — | — |
| `timeout` Linux-side | health checks | ✓ on LXC 100 (asserted by quick-health-check) | coreutils | — |

**Missing with no fallback:** none. **Missing with fallback:** mutagen (use the image), validator (scratch install).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Estate bash health checks with driven negative controls, plus `--self-test` modes. **No pytest/bats in repo** |
| Config file | none. Checks are self-contained scripts |
| Quick run command | `bash scripts/quick-health-check.sh` (workstation; folds in `check-music-freeze.sh` via `ssh -n`) |
| Full suite command | the above + `bash scripts/check-renovate.sh` + `renovate-config-validator --strict --no-global renovate.json5` + (on LXC 100) `bash scripts/check-music-freeze.sh` |

### Phase Requirements → Test Map
| Req / Criterion | Behavior | Type | Automated Command (what proves it) | "Could not look" looks like | Exists? |
|---|---|---|---|---|---|
| C1 / TAGR-03 | Exactly one tagger definition in deployable stacks | static | `git ls-files stacks \| xargs grep -lE '^\s*image:\s*(lscr\.io/linuxserver/beets\|sentriz/wrtag\|ghcr\.io/terry90/soulbeet\|metasauce/beets-flask)'` → exactly `stacks/selfhosted/arrs/beets/beets.yaml`. Plus `git ls-files \| grep -E 'soulbeet\|selfhosted/music/'` → empty. Folded into the D-21 census as "tagger definitions: 1" | n/a (git) | ❌ Wave 0 (census section) |
| C1 / TAGR-04 | #306 closed with evidence | manual/API | `gh issue view 306 --json state,comments` → `CLOSED`, comment cites the 4 D-26 facts | gh auth failure → UNKNOWN | n/a |
| C2 / TAGR-03 | wrtag rule gone; beets rules valid; config valid | static | `grep -c 'sentriz/wrtag' renovate.json5` → 0; `renovate-config-validator --strict --no-global renovate.json5` → exit 0; negative control copy with `automerg` → exit 1 | validator absent → `check-renovate.sh` prints yellow UNVALIDATED (must not be accepted as pass) | ✅ route exists (`VALIDATOR_ROUTE`); ❌ `--no-global` fix |
| C2 post-merge | Renovate accepted it | observation | Dependency Dashboard #3 no longer shows the soulbeet lookup warning or any `music/wrtag.yaml` section; no "Action Required" issue | Renovate has not run since the merge → state "not yet observed" | manual |
| C3 / TAGR-04 | Beets block stripped; job completes with no tagger | e2e | Static: `grep -c '^\s*beet ' sabnzbd/audio.bash` → 0 and guard lines 27–35 byte-identical to `fdcddca2…`'s. **Behavioural (D-12):** one real `music` job, SAB history row status `Completed` and `script_line` equal to the **baseline** `Exit(1): chmod …`; `find …/scripts -newer <stamp>` shows no `library.blb`/`*.bak`/`beets.log`/`beets-match`; `ffprobe` on the job's files shows no `MUSICBRAINZ_*`/beets-written tags | No job arrived in the window → the criterion is **open**, not passed | ❌ Wave 0 (evidence script or checklist) |
| C3 / D-09 | sabnzbd boots and post-processes with `:ro` mounts | e2e | After recreate: `docker logs sabnzbd` shows `[custom-init] scripts_init.bash: exited 0`; `docker inspect` shows both mounts `RW=false`; HTTP 200 on `:8084`; sha256 of both files unchanged; then the D-12 job | container not running → FAIL (not UNKNOWN) | manual |
| C3 / D-13 | Vendored-file drift is detected | health | `quick-health-check.sh` drift block: exit 0 green naming both files; **driven control**: override the expected hash → exit 1 naming the file with both hashes | ssh empty → UNKNOWN; RC 124 → UNKNOWN (timeout) | ❌ Wave 0 |
| C4 / TAGR-05 | Every remaining beets config declares musicbrainz | static+live | Repo: every beets config file's `plugins:` contains `musicbrainz`. Host: the same grep over the census list (sabnzbd `beets-config.yaml`, survivor `config.yaml` per OQ1) | host unreachable → UNKNOWN | ❌ Wave 0 |
| C4 (amended, D-20) | Probe: broken → 0 MB candidates; fixed → ≥1 MB candidate; `beet version` plugins lines differ | e2e | Code Example 4 transcripts. NDJSON `jq '[.[]\|select(.source=="MusicBrainz")]\|length'` → 0 then ≥1; hand-read `import -t` shows a MusicBrainz candidate list for the same album | 503 from musicbrainz.org (MB throttles with 503, DEF-03-07) → re-run, never read as zero | ❌ Wave 0 (MB-only probe mode) |
| C5 / D-21 / D-25 | tagger defs = 1; beets DBs = 1; retired DBs absent; rw-on-Music on non-tagger containers = 0 (+ Jellyfin D-21 printed separately); all container states | health | `check-music-freeze.sh` new section + summary lines; `quick-health-check.sh` selector widened to show them green. **Driven control:** first run **before** deletion must fail naming each retired path; `RETIRED_DB_PATHS` override pointing at an existing scratch file → exit 1 | docker unavailable → counters print `UNKNOWN`, exit 1 (DEF-03-11) | ❌ Wave 0 |
| D-22 | `check-renovate.sh` survives empty inputs; 157 no longer inverted | unit-ish | PATH-stubbed `git` with empty `branch -r` → prints "✅ No pending Renovate PRs", exit 0; empty postgres/redis sets → counts 0, exit 0 | — | ❌ Wave 0 (stub harness, 02.1-08 precedent) |
| D-23 | WAV write works, 3 cases, other frames intact, IPRD disagreement surfaced | unit | `docker run --rm --entrypoint python3 -v <scratch>:/w lscr.io/linuxserver/beets:2.13.1-ls349 /w/normalise-dj-tags.py --self-test` → exit 0; a deliberately broken write (old `easy=True` path) → self-test exit 1 | image absent → refuse, never pull silently | ❌ Wave 0 |
| D-04 | Retired runtime state gone | live | `docker ps -a --format '{{.Names}}' \| grep -ciE 'wrtag\|soulbeet'` → 0; `test ! -e` on each deleted path; fence copies listed in `MANIFEST.txt` with `integrity_check ok` | — | covered by the C5 census |

### Sampling Rate
- **Per task commit:** validator (`--strict --no-global`) for any `renovate.json5` touch; `bash -n` + the script's `--self-test` for any script touch; `docker compose … config --quiet` for any compose touch.
- **Per wave merge:** `bash scripts/quick-health-check.sh` from the workstation after the host `git pull`.
- **Phase gate:** full suite green **plus** the D-12 job evidence **plus** the executed D-21 run whose counters are pasted into `beets.md` (D-25).

### Wave 0 Gaps
- [ ] `scripts/check-music-freeze.sh`: new all-states census section + summary counters + `RETIRED_DB_PATHS`/`SURVIVOR_DB` env overrides (C5, D-21)
- [ ] `scripts/quick-health-check.sh`: drift block for both vendored files; selector widened to the new counters (C3, D-13, C5)
- [ ] `scripts/spike03-discogs-probe.py`: MB-only mode without token/identity probe (C4)
- [ ] `scripts/normalise-dj-tags.py`: `--self-test` with three synthetic WAVs (D-23)
- [ ] `scripts/check-renovate.sh`: PATH-stub control for line 157 (D-22)
- [ ] D-12 evidence checklist naming the two expected `Audio.txt` lines and the baseline Exit(1)

## Security Domain

`security_enforcement: true`, ASVS level 1. This phase touches configuration, deletion and one
public repo.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture (config as code) | yes | Repo copy + runtime copy + fail-closed drift assertion (D-13) |
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | Filesystem write-reach: no rw on `/mnt/tank/media/Music` except D-21; `:ro` binds for vendored scripts (D-09) |
| V5 Input Validation | yes | `renovate-config-validator`; `docker compose config --quiet`; path fences before any `rm -rf` (resolve, then assert the prefix, the CR-01 lesson) |
| V6 Cryptography | no | — (sha256 used for integrity comparison only) |
| V8 Data Protection | yes | Fence copies before deletion; no credential or release-name dumps in the public repo |
| V10 Malicious Code / supply chain | yes | Pinned validator install with `--ignore-scripts`, outside the repo; no `npx --yes`; note sabnzbd's `pip install -U` at boot as an unpinned supply-chain input (inventory, Phase 8) |
| V14 Configuration | yes | Renovate policy (manual review for beets minor/major); no floating tags (D-03) |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Deleting the wrong tree (`rm -rf` on a mistyped or `..` path) | Tampering | Resolve with `realpath`, assert an allow-listed prefix, `..` guard, list-then-delete with the list reviewed (spike03-wrtag-arms.sh CR-01 pattern) |
| Deleting data with no copy (`wrtag.db`) | Tampering / Repudiation | Fence copy + `integrity_check` asserted before deletion (F2) |
| Credential in argv (Cloudflare token for DNS removal) | Information disclosure | Read the token inside the process (`curl -H @file` or a script reading the file); never `$(cat …)` on a command line; never `pgrep -af` |
| Secrets rendered by `docker compose config` | Information disclosure | Always `--quiet` (or `--no-env-resolution`) |
| Committing `beets.log` / SAB history (release names) to a public repo | Information disclosure | Fence-only; quote minimal lines |
| Silent revert of the vendored script by upstream `setup.bash` | Tampering | `:ro` mount (prevents EBUSY-rename and truncation from inside the container) + drift assertion (detects host-side edits) |
| Unpinned `pip -U beets` on every sabnzbd boot | Tampering (supply chain) | Out of scope. Record as residual risk in the D-10 inventory |

## Project Constraints (from CLAUDE.md)

- Terraform is authoritative for host/LXC/VM. **Never `terraform apply`/`plan` in `infra/` for this phase** (bare apply can plan the destruction of LXC 100). Nothing here needs Terraform.
- Stacks live under `stacks/selfhosted/<stack>/`; stack ops run from `/mnt/fast/stacks` on LXC 100.
- Storage: appdata `/mnt/fast/appdata`; service account `apps:apps` `568:568`; `chmod` EPERM on `tank`; `chown` fails from LXC 100 (run from atlantis); `rsync` absent on LXC 100 (use `rsync -rlt --no-p --no-o --no-g` where it exists).
- Health checks: fail closed with "could not look" distinct from "nothing is wrong"; bound remote commands **Linux-side**; assert rather than report; `timeout N cmd | wc -l` exits 0, so use `set -o pipefail` remote-side and read the ssh RC.
- **This repo is public:** credentials by variable name/path only, never values (and never in argv, per DEF-03-21).
- LXC 100 `/tmp` is tmpfs backed by host RAM. Stage large files under `/mnt/fast/`.
- GSD workflow: repo edits only through GSD commands.
- **Jellyfin hardware transcoding stays OFF** (D-30); untouched here.
- `CLAUDE.md:159-343` is GSD-generated from `.planning/research/STACK.md` (F15).

## Sources

### Primary (HIGH confidence)
- **Live LXC 100 (172.16.1.159), read-only, 2026-09-11:**
  - `docker ps -a` (97 containers), `docker inspect` of all mounts, `docker image ls/inspect`, `docker logs sabnzbd` (boot lines), `docker compose config --quiet` (arrs + survivor), `docker compose ls -a`
  - `find` DB census (with a positive control) and appdata tree listings
  - `/mnt/fast/safety` + `MANIFEST.txt`
  - `audio.bash`, `extended.conf` (selected keys), `scripts_init.bash`, `sabnzbd.ini` categories, `beets.log`, `Audio.txt`, `sabnzbd.log`, SAB `history1.db` (`mode=ro`)
  - survivor `config.yaml` (secret-shaped keys counted: 0), `ffprobe` of the substitute albums, crontab/systemd, `ss -ltn`
- **Live atlantis (172.16.1.158):** crontab/systemd (no tagger entries)
- **Repo:** full reads of the stack YAMLs, `renovate.json5`, `check-renovate.sh`, `check-music-freeze.sh` (sections 0–2, 5–7), `quick-health-check.sh` (fold-in 481–557), `normalise-dj-tags.py` (475–635), `spike03-discogs-probe.py` (env/main), `beets.md`, `PROJECT.md`, and 03-DECISION § Handoff to Phase 4, deferred-items DEF-03-01/09/21
- **`renovate-config-validator` 44.80.0**, executed on the current file and on 4 edited variants plus a negative control
- https://docs.renovatebot.com/config-validation/ (file argument = global; `--no-global`; `--strict`)
- https://docs.renovatebot.com/modules/versioning/docker/ (suffix = compatibility)
- https://docs.renovatebot.com/modules/versioning/regex/ (`build` handled like patch; LSIO example)
- https://github.com/linuxserver/docker-beets: `Dockerfile` (BEETSDIR/HOME=/config), `svc-beets/run` (`beet web`), `init-beets-config/run` (`lsiown -R`), `root/defaults/config.yaml`
- https://github.com/linuxserver/docker-sabnzbd: `init-sabnzbd-config/run` (`find /config … lsiown`)
- https://github.com/linuxserver/docker-baseimage-alpine: `init-custom-files/run` (non-zero exit logged, not fatal)
- https://beets.readthedocs.io/en/stable/reference/cli.html (`-c` overlay semantics; `-W`/`-C`/`-t`)
- https://mutagen.readthedocs.io/en/latest/api/wave.html (`WAVE.tags` is ID3; `add_tags`)
- Docker Hub tags API (`linuxserver/beets`: 2.13.1-ls349 pushed 2026-08-29; ls350 2026-09-04)
- MusicBrainz WS/2 release search (*Scarecrow*, Garth Brooks)
- `gh`: issue #306 body/state, #305, #307, PR #310, Dependency Dashboard #3

### Secondary (MEDIUM confidence)
- `dig @1.1.1.1` (proxied Cloudflare records, with a random-name wildcard control)

### Tertiary (LOW confidence)
- `lsiown` behaviour on EROFS (source not located), A1

## Metadata

**Confidence breakdown:**
- Live-estate facts (F1–F15, inventory): **HIGH**. Measured today, read-only, with positive controls where a census could be blind.
- Renovate changes: **HIGH**. Executed against the real validator in both modes, with a discriminating negative control.
- LSIO boot behaviour under `:ro`: **MEDIUM**. Sourced from LSIO scripts except `lsiown`. D-09's boot proof is the real test.
- Probe mechanics: **MEDIUM-HIGH**. The source was read. The negative-control design choice (refusal vs `no_candidates`) is the planner's.

**Research date:** 2026-09-11
**Valid until:** ~2026-09-18 for the live-estate facts. The backlog tree, SAB history, PR #310 and
the LSIO `-lsNNN` stream all move weekly, so re-assert F1, F3, F8 and the PR state at execution.
Renovate/LSIO/beets docs: 30 days.
