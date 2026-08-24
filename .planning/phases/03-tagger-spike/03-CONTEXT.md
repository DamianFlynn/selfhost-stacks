# Phase 3: Tagger Spike - Context

**Gathered:** 2026-08-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Choose **one engine** (beets vs wrtag) and **one front end** (raw terminal prompt vs reviewable
queue) from measurements taken on this library's own content, against overturning thresholds
committed before the evidence is collected.

Delivers: TAGR-01, TAGR-02, TAGR-06.

**Not in this phase:** deleting the losing definitions or releasing the Renovate pin (Phase 4,
TAGR-03/04/05 — deliberately independently shippable); configuring the winner or granting it rw on
the library (Phase 6); building the `_inbox` structure (Phase 5); the full DJ field-mapping tool
(DJCC-01, v2).

**The spike produces a number.** It does not re-open the direction as an open question — with one
scoped exception recorded in D-12 below, which exists because a specific research claim was
falsified, not because the direction is in doubt.

</domain>

<decisions>
## Implementation Decisions

### Versions under test

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

### Discogs access

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

### The 20-folder sample and its normalisation

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

### Ergonomics (TAGR-06)

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

### Research scope — deliberately reopened (D-12)

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/ROADMAP.md` § "Phase 3: Tagger Spike" — the eight success criteria, and the explicit
  warning that the spike produces a number rather than relitigating a direction
- `.planning/REQUIREMENTS.md` — TAGR-01, TAGR-02, TAGR-06 (and TAGR-03/04/05 for the Phase 4 handoff)
- `.planning/PROJECT.md` § Constraints — the track-count rule, the `rsync -a` failure, separate
  datasets / `cp --reflink` `EXDEV`, no `beet undo`, and the corrected census
- `.planning/PROJECT.md` § Technology Stack — the head-to-head table that D-12 audits, including the
  "No facility" claim now known to be false

### Phase 1 output that constrains this phase
- `.planning/phases/01-safety-harness-and-freeze-the-writers/01-CONTEXT.md` — **D-20** (nobody holds
  rw on Music during Phases 1–3; the winner is granted rw in Phase 6) and **D-22** (wrtag retained
  for exactly this spike, against a scratch target that cannot be the real library)
- `stacks/selfhosted/arrs/beets.md` — **the Phase 1 durable record.** Ownership, the fence, the
  Jellyfin carve-out, the mount audit, the two traps, and the six-false-passes rule
- `.planning/phases/01-safety-harness-and-freeze-the-writers/01-07-SUMMARY.md` — all six beets
  configs with their live values, the vendoring shape, and the compose-file-in-BEETSDIR finding
- `.planning/phases/01-safety-harness-and-freeze-the-writers/01-02-SUMMARY.md` — the four beets
  databases (not two) and where each lives; `soulbeet`'s does not exist
- `.planning/phases/01-safety-harness-and-freeze-the-writers/01-04-SUMMARY.md` — the QUAL-01 capture
  and the **828 duplicate groups / 1,892 records / 19.4%** finding

### wrtag — user-specified, read before scoring wrtag
- https://github.com/sentriz/wrtag — **the user flagged this explicitly: "this project is getting
  updates and attention, its important to look at its tooling."** Ships three binaries: `wrtag`,
  `wrtagweb`, and `metadata`
- https://github.com/sentriz/wrtag/releases — v0.33.0 (11 Jul 2026) latest; v0.30.0 (8 Apr 2026) is
  the breaking path-format release
- https://github.com/sentriz/wrtag/blob/master/README.md — the `metadata` usage form and the
  subproc addon pairing

### Files this phase reads but must NOT edit
- `stacks/selfhosted/music/wrtag.yaml` line 71 — the `WRTAG_PATH_FORMAT` that proves the pin is
  inverted; line 73's `WRTAG_RESEARCH_LINK` already points at Discogs
- `stacks/selfhosted/arrs/beets/beets.yaml` — `:ro` on `/media`, `restart: "no"`, `profiles: [manual]`
- `renovate.json5` line 91 — the wrtag hold rule (Phase 4 releases it, not this phase)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- `/mnt/fast/secrets/discogs.env` on LXC 100 — the verified token, `0600`, outside the repo
- `scripts/check-music-freeze.sh` — the harness; re-run it after the spike to prove nothing drifted
- `scripts/snapshot-music-tags.sh` / `scripts/diff-music-tags.sh` — the QUAL-01 pair. **The diff
  tool can measure whether a normalisation run lost fields**, which is directly useful for scoring
  `metadata` against mutagen in D-13
- `tank/media/Music@pre-project`, `tank/downloads@pre-project`, `@pre-chown`, `@safe05-watch-t0` —
  existing snapshots; the spike works on copies so it should not need a new one

### Established patterns
- Host-resident scripts under `scripts/`, `#!/usr/bin/env bash`, `set -euo pipefail`, ALL-CAPS
  constants, run from `/mnt/fast/stacks` after a `git pull` (`setup-mpe.sh`, `pg-migrate.sh`)
- Commits must reach `origin` before LXC 100 can pull and run them — git is the delivery path
- A `.md` beside the stack it documents (`arrs/beets.md`, `media/dispatcharr.md`)

### Integration points and hazards carried from Phase 1
- **`zfs` does not and cannot exist on LXC 100** (unprivileged); use `ssh root@172.16.1.158`
- **`rsync`, `tmux` and `screen` are not installed** on LXC 100
- **`chmod` fails EPERM everywhere on `tank`**, even as real root — `aclmode=restricted`
- **`chown` fails from LXC 100** for a *different* reason (sparse idmap) — run it from the hypervisor
- **`find -xdev` is unsafe** — `/mnt/fast/appdata/*` are 39 separate ZFS datasets
- **`beet config` is NOT read-only** — it opened the default library and ran 11 migrations in Phase 1.
  Always pass an explicit throwaway `-l <db>` when probing beets configuration
- **Six times in Phase 1 a check reported a pass it had not earned.** Prefer the instrument that sees
  the actual filesystem; never discard stderr in a verification step

</code_context>

<specifics>
## Specific Ideas

- The pin inversion should be demonstrated, not asserted: `.Media.Position` / `.Track.Position` /
  `.Release.Media` in the repo's own path format against the v0.30.0 changelog is the proof.
- `WRTAG_RESEARCH_LINK` in `wrtag.yaml:73` already points at Discogs search. Whoever configured that
  already knew this content lives on Discogs, and wrtag's answer was "here is a link, go look it up
  yourself." Criterion 4 calls that shape of answer a failure — worth quoting in the decision record.
- The strict-vs-loose match rate gap (D-05) is a deliverable in its own right, not a footnote.
- The 828 duplicate groups mean a naive per-folder match rate can double-count the same audio.
  State whether the rate is computed per folder or per distinct `audio_md5`.

</specifics>

<deferred>
## Deferred Ideas

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

</deferred>

---

*Phase: 3-tagger-spike*
*Context gathered: 2026-08-24*
