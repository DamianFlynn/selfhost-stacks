# Phase 4: Collapse to One Tagger - Context

**Gathered:** 2026-09-06
**Status:** Ready for planning

<domain>
## Phase Boundary

**Retirement, not construction.** The estate ends with one tagger definition, one beets
`library.db`, and no idle container holding a read-write mount on `/mnt/tank/media/Music`.

This phase **must be independently shippable**. The project has been abandoned three times; if
attempt four stalls here, the estate must still be strictly better than it started, so attempt
five does not inherit attempt four's wreckage. Every decision below is filtered through that.

**In scope:** TAGR-03 (delete losing tagger definitions, release their Renovate rules), TAGR-04
(soulbeet removed with issue #306 closed, beets block stripped from `audio.bash`), TAGR-05 (every
remaining beets config declares `musicbrainz`), plus three carry-ins from Phase 3 that touch the
same files.

**Explicitly NOT in scope:** granting anything `rw` on the library (Phase 6 owns that — D-20
still holds), standing up beets-flask (Phase 5), configuring the tagger (Phase 6), importing any
content (Phase 7), and changing the SABnzbd hook's eventual shape (Phase 8).

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The decision this phase implements
- `.planning/phases/03-tagger-spike/03-DECISION.md` § *Handoff to Phase 4* — the three items
  Phase 4 must not rediscover: the `--pretend` unsatisfiability with its `session.py` evidence,
  the `renovate.json5:91` cause/effect reversal, and the measured answer that unpinning wrtag buys
  **nothing**. **Read this section before writing any plan.**
- `.planning/phases/03-tagger-spike/03-DECISION.md` § *Axis one* and § *Axis two* — the engine is
  beets 2.13.1; the front end is beets-flask's **policy-carrying inbox architecture** and
  explicitly **not** its interactive candidate picker (disqualified on measured safety) nor the
  raw terminal prompt (T3 fired).
- `.planning/phases/03-tagger-spike/03-WRTAG-EVIDENCE.md` — criterion 3's measurements at v0.20.0
  / v0.33.0 / v0.34.0; the source for D-14's verbatim correction.
- `.planning/phases/03-tagger-spike/deferred-items.md` — DEF-03-01 (D-21), DEF-03-09 (D-23),
  DEF-03-21 (D-24, dismissed).

### Phase scope and requirements
- `.planning/ROADMAP.md` § *Phase 4: Collapse to One Tagger* — the five success criteria.
  Criterion 4 is amended by D-20.
- `.planning/REQUIREMENTS.md` — TAGR-03, TAGR-04, TAGR-05 (lines 126–130). TAGR-05 is amended by
  D-20.
- `.planning/PROJECT.md` § *Context* — the four (five) entry points table and why three are dead;
  § *Constraints* → *Reversibility* records that there are **four** beets databases, not two, and
  that the `soulbeet` one does not exist at all.

### The durable estate record
- `stacks/selfhosted/arrs/beets.md` — the Phase 1 durable record; D-25's closure section and
  D-14's correction land here.
- `CLAUDE.md` § *Technology Stack* and § *What NOT to Use* — carries two claims this phase
  corrects: keep the wrtag `<0.30.0` pin, and the retired "7,451 files across ~1,000 folders"
  figure (the file count was right; the folder count was off ~8×, the real denominator is 144).
- `README.md` § *Health Checks* — the three rules D-13 and D-21 must follow (fail closed with
  "could not look" distinct from "nothing is wrong"; bound remote commands **Linux-side**;
  assert rather than report; `timeout N cmd | wc -l` silently exits 0).
- `DEPLOYMENT.md` — how change reaches the estate; git is the delivery path.

### Files this phase edits
- `stacks/selfhosted/arrs/compose.yaml` — the `include:` list (D-06)
- `stacks/selfhosted/arrs/beets/beets.yaml` — the survivor (D-01, D-02, D-03)
- `stacks/selfhosted/arrs/soulbeet.yaml`, `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` —
  deleted (D-01)
- `stacks/selfhosted/music/compose.yaml`, `stacks/selfhosted/music/wrtag.yaml` — deleted (D-05)
- `stacks/selfhosted/arrs/sabnzbd.yaml` — the vendored `audio.bash` mount (D-08, D-09)
- `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` — `plugins:` line (D-11, TAGR-05)
- `renovate.json5` — wrtag rule deleted, beets rule added (D-14, D-15)
- `scripts/check-music-freeze.sh` — behaviour-based classification (D-21)
- `scripts/check-renovate.sh` — five pipefail aborts (D-22)
- `scripts/quick-health-check.sh` — the `audio.bash` drift assertion (D-13)
- `scripts/normalise-dj-tags.py` — the WAV write path (D-23)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **The vendoring pattern is already proven** — plan 01-07 vendored
  `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` and bind-mounts it over
  `/config/scripts/beets-config.yaml`. D-08 reuses it verbatim for `audio.bash`.
- **The Jellyfin Renovate rule** (`renovate.json5`, after `packageRules[2]`) is the template D-15
  mirrors — including its explicit refusal to add an `allowedVersions` ceiling, which cites the
  wrtag pin by name.
- **`scripts/spike03-discogs-probe.py`** carries the `tag_album()` NDJSON emitter D-16 reuses.
- **`scripts/check-music-freeze.sh`** is the criterion-5 instrument once D-21 fixes it; it is
  already folded into `scripts/quick-health-check.sh`.
- **`/mnt/fast/safety`** holds Phase 1's fence — 18 integrity-checked `library.db` copies. D-04
  confirms against it rather than taking a fresh archive.

### Established patterns
- Host-resident scripts under `scripts/`, `#!/usr/bin/env bash`, `set -euo pipefail`, ALL-CAPS
  constants, run from `/mnt/fast/stacks` after a `git pull`. **Commits must reach `origin` before
  LXC 100 can pull and run them — git is the delivery path.**
- A `.md` beside the stack it documents (`arrs/beets.md`, `media/dispatcharr.md`). Operational
  detail lives beside the thing it describes, not in `.planning/`.
- In-band dated amendments preserving original wording (the 02.1-11 shape), for any artifact whose
  text a later measurement falsified.
- Prove an assertion is *capable of failing* with a driven negative control, never merely observed
  passing.

### Integration points and hazards
- **`beet` is not read-only.** A bare `beet config` opened the default library and ran 11
  migrations in Phase 1. Always pass an explicit throwaway `-l <db>` (D-16).
- **A beets config with a customised `plugins:` list that omits `musicbrainz` silently disables
  all autotagging** since 2.4.0. The symptom looks like "no match found", not like a config error.
  This is the confirmed cause of the 1 Aug / 8 Aug skips.
- **SABnzbd 5.0 runs post-processing for FAILED jobs too.** The local `SAB_PP_STATUS` guard in
  `audio.bash` is the only thing stopping failed downloads being post-processed into the library,
  and it survives **only** because `scripts_init.bash` is vendored. D-10 keeps it byte-identical.
- **The `:rw` bind mount is a partial barrier, measured not assumed:** `mv tmp dest` → EBUSY
  (blocked, and this is the overwrite upstream actually performs); `> dest` → succeeds and reaches
  the host file. D-09 closes the second half with `:ro`.
- **`zfs` cannot exist on LXC 100** (unprivileged) — use `ssh root@172.16.1.158`. `rsync`, `tmux`
  and `screen` are not installed on LXC 100. `chmod` fails EPERM everywhere on `tank`;
  `chown` fails from LXC 100 for a different reason (sparse idmap).
- **`docker ps` filters on `status=restarting/dead/exited` MISS `created`** — a documented estate
  blind spot that hid two down containers for six weeks. D-04's "containers are gone" assertion
  must use no status filter.
- **Renovate deploy drift:** a merged PR never touches the host. `docker ps` and git disagree.
  D-03's version bump is not live until the host pulls and the container is recreated.
- **D-20 (Phase 1) still holds:** nobody holds `rw` on `/mnt/tank/media/Music` until Phase 6.
  Nothing in this phase grants it, and the survivor's `/mnt/tank/media:ro` line is not to be
  flipped "just to run one import".

</code_context>

<specifics>
## Specific Ideas

- The `renovate.json5:91` correction is worth landing **verbatim** from Phase 3 rather than
  paraphrased — the rule's own text reverses cause and effect, and a paraphrase risks reproducing
  the error in a new place.
- The D-17 negative control is the more interesting half of criterion 4. A returned MusicBrainz
  candidate proves the fix took; running the *same* album against the *live* broken config first
  proves the defect explains the observed skips — which is currently inference.
- D-21's inversion (assert the retired databases are **absent**) makes the standing check a guard
  on this phase's own outcome. It is cheap and it is the difference between a snapshot and a
  standing guarantee.
- The operator's Phase 3 verdict is worth carrying into how this phase's evidence is presented:
  *"It's fine for a bot to drive us, but for me, as a human, no."* Agent-driven `beet` invocations
  are acceptable; a plan that ends in "now sit at this prompt" is not.

</specifics>

<deferred>
## Deferred Ideas

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

</deferred>

---

*Phase: 4-collapse-to-one-tagger*
*Context gathered: 2026-09-06*
