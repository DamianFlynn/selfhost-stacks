# Phase 4: Collapse to One Tagger - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-06
**Phase:** 4-collapse-to-one-tagger
**Areas discussed:** The surviving definition, audio.bash + sabnzbd beets, Renovate + criterion 4, Phase 3 carry-ins

---

## The surviving definition

### Where does beets-flask get stood up?

| Option | Description | Selected |
|--------|-------------|----------|
| Retire only; beets.yaml survives | Delete wrtag + soulbeet; beets-flask lands in Phase 5 where its inbox policies are the deliverable | ✓ |
| Swap to beets-flask now | Delete beets.yaml too and land beets-flask as the single survivor | |
| Both, beets-flask profile-gated | Keep beets.yaml and add beets-flask behind a profile or comment | |

**Notes:** rc6 hard-pins beets 2.12.0 (below the 2.13.1 the engine was scored at), it has been an
RC for eight months, and its inbox folders do not exist until Phase 5 — so it would ship inert.
Criterion 1's "deleted, not commented out" rules out the third option.

### Dormant or re-enabled?

| Option | Description | Selected |
|--------|-------------|----------|
| Leave dormant, as-is | Stays commented out of the include, `restart: "no"`, `profiles: [manual]`, `/mnt/tank/media:ro` | ✓ |
| Re-enable the include, keep :ro | Uncomment `- beets.yaml` so the one tagger is deployable | |
| Delete the container definition entirely | Zero tagger definitions until Phase 5/6 | |

**Notes:** Criterion 5 wants zero idle containers holding `rw`; a definition that is not included
holds nothing. D-20 (Phase 1) says nobody gets `rw` until Phase 6 anyway. Deleting outright was
rejected because criterion 1 says *one* definition, not zero, and TAGR-05's `musicbrainz` fix
would have no repo config to land in.

### How far does retirement reach into host state?

| Option | Description | Selected |
|--------|-------------|----------|
| Stop + remove containers, delete appdata | Repo defs deleted, containers stopped and `docker rm`'d, appdata deleted after confirming the Phase 1 fence | ✓ |
| Repo-only; leave host state in place | Delete definitions, stop containers, leave every appdata tree | |
| Delete appdata, take a fresh archive first | Same as the first, but don't trust the Phase 1 fence | |

**Notes:** "One `library.db`" has to be a measured fact about the estate, not a claim about the
repo — repo/host divergence is a documented recurring failure here. Phase 1's fence already holds
18 integrity-checked `library.db` copies, so a fresh archive was judged unnecessary.

### What happens to the music/ stack?

| Option | Description | Selected |
|--------|-------------|----------|
| Delete the whole music/ directory | Both files go | ✓ |
| Keep music/, empty and documented | Reserve the slot for Phase 5's beets-flask stack | |
| Keep music/, move beets.yaml into it | Relocate the survivor into the stack named for the job | |

**Notes:** An empty compose project is the commented-out-definition problem in another shape. The
move was rejected as a change to the survivor in an otherwise pure-deletion phase, churning paths
Phase 5/6 will touch anyway.

### Does the survivor's image get bumped?

| Option | Description | Selected |
|--------|-------------|----------|
| Bump to 2.13.1-ls349 | The fully-qualified tag the spike measured | ✓ |
| Leave at 2.5.1-ls295 | Pure retirement; Phase 6 owns version and config together | |
| Bump to whatever 2.13.1 resolves to now | Take the current ls-revision | |

**Notes:** Blast radius is nil (dormant, `restart: "no"`, `:ro`), and leaving the survivor at a
version nothing was measured on means Phase 6 inherits an unproven engine. The floating 2-part tag
was rejected against this estate's own recorded deploy-drift finding.

### How wide is the stale-reference sweep?

| Option | Description | Selected |
|--------|-------------|----------|
| Grep-driven sweep, every hit triaged | Repo-wide grep; each hit deleted, corrected, or kept with reason | ✓ |
| Compose + Renovate + docs only | Leave the scripts alone | |
| Compose files only | Strictly the stack definitions and include entries | |

**Notes:** Raised by the operator mid-discussion — *"if they are in the stack compose files, clean
those also"* — which widened the question from files to references. `check-music-freeze.sh` still
classifies on those names and `CLAUDE.md` still tells a reader to pin wrtag `<0.30.0` for a reason
Phase 3 falsified. `#  - beets.yaml` stays (it is the survivor, deliberately dormant); the
unrelated `listenarr`/`boxarr` comments are left alone.

---

## audio.bash + sabnzbd beets

### How does the audio.bash edit become durable?

| Option | Description | Selected |
|--------|-------------|----------|
| Vendor audio.bash into the repo | Same pattern as `beets-config.yaml` (plan 01-07) | ✓ |
| Edit in place on the host, record in beets.md | Direct host edit, documented | |
| Unhook at the SABnzbd category level instead | Detach the script from the `music` category | |

**Notes:** Upstream `setup.bash` re-downloads `audio.bash` — that is exactly why
`scripts_init.bash` was vendored. An in-place edit has a measured revert path with no detection.
The category unhook was rejected because criterion 3 says the *block* is stripped, and a config
unhook is one UI click from returning.

### What happens to the sabnzbd-side beets state?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the config as a guard, delete the database | `library.blb` + `beets.log` go; config stays with `musicbrainz` added | ✓ |
| Delete all three and the bind mount | Nothing sabnzbd-side is a "remaining config" any more | |
| Keep all three, fix the config | Preserve the historical import record | |

**Notes:** TAGR-04 and TAGR-05 collide here. Keeping the config defused preserves the barrier
against upstream's rename-based overwrite — a stock `setup.bash` restore would otherwise land a
config with `scrub`/`lastgenre`/`embedart` all defaulting to yes, against a library with no undo.
Keeping `library.blb` was rejected: criterion 5's "one `library.db`" would be false.

### What proves criterion 3?

| Option | Description | Selected |
|--------|-------------|----------|
| A real music job, end to end | Queue a genuine download; no beets.log line, no .blb, no .bak | ✓ |
| Replay a completed job through post-processing | Same code path, no Usenet dependency | |
| Static assertion on the vendored script | Grep for `beet`, assert zero | |

**Notes:** The estate's standing rule is prove it *fires*, not prove it's *set*. A replay may not
exercise the same category/status branch a live job does — and SAB 5.0's FAILED-job behaviour is
exactly the kind of branch that bit this estate before.

### How is the vendored audio.bash mounted?

| Option | Description | Selected |
|--------|-------------|----------|
| :ro, and re-examine beets-config.yaml | Closes the truncation hole; check whether the config can move to :ro too | ✓ |
| :rw, matching the existing pattern | Consistent with `beets-config.yaml` | |
| No bind mount — deliver by git pull and copy | Detection replaces prevention | |

**Notes:** Plan 01-07 measured what `:rw` buys — `mv tmp dest` blocked (EBUSY, the overwrite
upstream actually performs), `> dest` truncation still reaches the host file. Neither file is
written by anything legitimate. Needs a proven-not-assumed check that the container still starts,
since LSIO does chown/permission passes over `/config` at boot.

### How much comes out of audio.bash?

| Option | Description | Selected |
|--------|-------------|----------|
| The beets block only | Line 285; `SAB_PP_STATUS` guard byte-identical; other tag-writers inventoried | ✓ |
| Beets plus any other tag-writing step | Strip ReplayGain, lyrics, embedded art too | |
| Replace with a minimal move-only script | Jump to Phase 8's end state | |

**Notes:** The bigger strip pre-empts decisions Phase 8 owns, and the move-only script would build
against an inbox that does not exist until Phase 5. Keeping the diff small enough to review
honestly is what makes this phase shippable.

### Does the vendored audio.bash get a drift check?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — same comparison, fail-closed | Extend `quick-health-check.sh`, assert not report, driven negative control | ✓ |
| Yes, but report-only for now | Add as `info()`, promote later | |
| No — the :ro mount is the guarantee | Rely on prevention over detection | |

**Notes:** Report-only is precisely the CR-01 defect Phase 02.1 spent four gap-closure plans
repairing — a value printed but never asserted, green regardless. The `:ro` mount protects the
container's view; it does not stop someone editing the host file directly.

---

## Renovate + criterion 4

### What replaces the wrtag rule?

| Option | Description | Selected |
|--------|-------------|----------|
| Delete the rule, record the correction elsewhere | Rule goes; corrected finding lands in `beets.md` and `CLAUDE.md` | ✓ |
| Delete the rule, correction in the commit message only | Minimal footprint | |
| Keep a corrected rule as a tombstone | Document the misdiagnosis where it happened | |

**Notes:** The rule's stated evidence is wrong — `.Release.Date.Year` and `.Release.Media` are
both present at v0.20.0; the real defects are the forced `d.Track.Position = -1` and the absent
`.Media.Position`. Cause and effect are reversed. A `packageRules` entry matching nothing is dead
config, and a config error silently stops the whole Renovate run.

### Does the surviving tagger get a rule?

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror the Jellyfin rule | Minor + major manual, patch automerge preserved, no `allowedVersions` ceiling | ✓ |
| No rule — it's dormant and :ro | Add it in Phase 6 when it gets `rw` | |
| Manual-only for every update type | No automerge at all, patch included | |

**Notes:** beets 2.4.0 turning MusicBrainz into a plugin is precisely a minor release changing
semantics — the same argument the Jellyfin rule makes. The ceiling was rejected citing the wrtag
pin by name. "No rule" was rejected against the estate's documented unworked-Renovate-backlog
failure mode.

### What instrument replaces --pretend?

| Option | Description | Selected |
|--------|-------------|----------|
| tag_album() probe + one hand-read `beet import -t` | Machine-readable assertion plus cross-check | ✓ |
| tag_album() probe alone | Programmatic, repeatable | |
| `beet import -t` alone | Closest to what an operator would run | |

**Notes:** `--pretend` replaces the whole pipeline with a file lister
(`beets/importer/session.py` v2.13.1), so it never calls `lookup_candidates` and returns zero
candidates by construction. The paired-instrument method is the one that carried T1 and caught
three defective instruments in 03-07. Both runs pass an explicit throwaway `-l <db>` — `beet` is
not read-only.

### Does the probe get a negative control?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — run it against the broken config first | Live `plugins: embedart` config → zero candidates, then fixed → candidate | ✓ |
| Yes, but with a synthetic broken config | Cleaner isolation of the variable | |
| No — a returned candidate is sufficient | | |

**Notes:** Using the *historical* broken config makes the claim "this defect caused the 1 Aug and
8 Aug skips" a measurement rather than an inference. A synthetic config would prove the mechanism
but not the explanation.

### Do the ROADMAP and REQUIREMENTS get amended?

| Option | Description | Selected |
|--------|-------------|----------|
| Amend both, in-band and dated | 02.1-11 precedent: quote the original, state why, name the substitute | ✓ |
| Amend the ROADMAP only | TAGR-05's wording is already instrument-agnostic | |
| Leave both; record the substitution in the plan | Roadmap keeps its original text as history | |

**Notes:** A success criterion nobody can satisfy as written is how a verification pass returns
`gaps_found` for a reason that is not a real gap. Substance preserved, never reduced.

### Which album does the probe run against?

| Option | Description | Selected |
|--------|-------------|----------|
| A folder that actually skipped — Garth Brooks | `Garth_Brooks-Ropin_The_Wind`, single-disc, well covered by MusicBrainz | ✓ |
| A skipped folder plus one clean control | Second album for attribution if the first returns nothing | |
| A fresh bucket-A album from the backlog | Tests the pipeline as it will be used | |

**Notes:** Deliberately not `Def.Leppard-CD.Collection` — multi-disc, and the live
`Def Leppard (2015)` empty-album-artist defect would confound the result.

### Where does the probe execute?

| Option | Description | Selected |
|--------|-------------|----------|
| Start the survivor on its `manual` profile | Proves the container this phase ships, at the pinned version, through its declared mounts | ✓ |
| A throwaway spike-style container | Reuse the Phase 3 pattern | |
| Either — you decide at plan time | | |

**Notes:** A throwaway container would prove a container this phase does not ship. 03-04 already
measured that a config dump cannot prove which plugins actually loaded — assert via `beet version`.

---

## Phase 3 carry-ins

### Which of Phase 3's four suggested carry-ins are in scope?

| Option | Description | Selected |
|--------|-------------|----------|
| DEF-03-01 — check-music-freeze blind spot | Name-based `TAGGER_PATTERN` cannot see beets inside `sabnzbd`; it is the criterion-5 instrument | ✓ |
| check-renovate.sh pipefail aborts | Five aborts; line 157 inverted (fires when the estate is healthy) | ✓ |
| DEF-03-09 — the WAV write path | `normalise-dj-tags.py` writes 0 of 134 WAV files | ✓ |
| Discogs token rotation | Standing action with four causes | |

**User's choice:** All three technical carry-ins folded in; the token rotation explicitly refused.

**Notes:** Operator, verbatim: *"Discogs token rotation is not important at all, there is nothing
there that has any value, i am not concerned"*. Recorded in CONTEXT.md as a **reasoned dismissal**
rather than an oversight or a silence, in the same style as PROJECT.md's `sec=sys` residual-risk
row, so a future security review meets an answer. The standing action and its four causes remain
on the record in `03-DECISION.md` § 9 and `deferred-items.md` DEF-03-21.

### What shape does the fixed freeze check take?

| Option | Description | Selected |
|--------|-------------|----------|
| Behaviour-based, and assert the retired ones are absent | Classify by mounts; assert only the survivor's database exists | ✓ |
| Behaviour-based classification only | Fix the blind spot, no database assertions | |
| Minimum: correct the regex | Drop `soulbeet`/`wrtag`, add `sabnzbd` | |

**Notes:** DEF-03-01 suggested asserting the mtime of all four databases, but this phase deletes
two of them — so the suggestion is inverted into "assert the retired ones are gone". That makes
the standing check a guard on this phase's own outcome: a resurrected tagger fails it. The regex
has to change anyway, since the sweep deletes two of its four names.

### The WAV fix's LIST/INFO chunk decision

| Option | Description | Selected |
|--------|-------------|----------|
| Write ID3 only, and assert the disagreement is visible | Correct WAVE API; stale `LIST`/`INFO` surfaced as a recorded finding; three-case regression test | ✓ |
| Write both containers, matching wrtag | Internally consistent file | |
| Write ID3 only, no extra reporting | Smallest fix | |

**Notes:** ID3 is what both consumers read. Writing both doubles the write surface on a path that
currently writes nothing, on a stratum no committed rule fires on — more risk than the 3.2%
justifies. Surfacing the disagreement stops a future reader discovering two containers disagreeing
and reading it as corruption.

### Where does criterion 5's outcome statement live?

| Option | Description | Selected |
|--------|-------------|----------|
| Measured into beets.md, guarded by the standing check | Counters from an executed check run; dated closure section beside the stack | ✓ |
| Phase VERIFICATION.md only | | |
| Both, plus a CLAUDE.md summary line | | |

**Notes:** Operational detail belongs beside the thing it describes — the person who needs it will
be editing `beets.md`, not reading a `.planning/` file. Adding to `CLAUDE.md` before pruning the
stale music-pipeline detail this phase is already correcting risks compounding it.

### How is the issue side handled?

| Option | Description | Selected |
|--------|-------------|----------|
| Close #306 with the evidence, leave the others | Cite GHCR removal, never deployed, empty data dir, definition deleted | ✓ |
| Close #306 and post a Phase 4 summary to #305 | | |
| Close #306 only at phase close, not during | | |

**Notes:** A closing comment that says *why* is what stops it being reopened on a whim. #305 stays
open until the milestone completes; #307 (rybbit) is unrelated to this phase.

---

## Claude's Discretion

- Plan decomposition and ordering, subject to two fixed constraints: the negative control must run
  against the **live** broken config before TAGR-05 fixes it, and the appdata deletion must follow
  the fence confirmation.
- Exact wording of the in-band ROADMAP/REQUIREMENTS amendments, following the 02.1-11 shape.
- Whether the `beets-config.yaml` `:rw` → `:ro` move lands in this phase or is recorded as
  measured-and-deferred, decided on what the boot-time check shows.

## Deferred Ideas

- beets-flask stack definition — Phase 5 (carry friction 9: a rejected `plugins:` string kills
  rc6's watchdog while the server still serves a page).
- Moving `beets.yaml` into a music-named stack — raised and rejected for this phase.
- Reworking `audio.bash` into a minimal move-only hook — Phase 8 (INGS-01).
- Removing other tag-writing steps from `audio.bash` — inventoried here, decided in Phase 8.
- Granting the survivor `rw` and configuring it — Phase 6 (CONF-01…06).
- Discogs token rotation — explicitly dismissed by the operator, not deferred.
- `renovate.json5`'s cosmetic additive-label wart — already deferred in the Jellyfin rule.
- DUPE-01 / DUPE-02 — needs a roadmap decision before Phase 7.
- `/mnt/tank/media/TV` on the orphan gid 545 — outside this milestone.
