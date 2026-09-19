# Phase 6: Tagger Configuration and Dry Run - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-20
**Phase:** 6-tagger-configuration-and-dry-run
**Areas discussed:** beets-flask scope, Path format specifics, Criterion 4's consumer proof,
Dry-run sample + the oracle

**Framing finding raised before area selection:** Phase 5's D-16 assigns beets-flask to Phase 6, but
none of Phase 6's six ROADMAP criteria mention it; the survivor is beets 2.13.1 while rc6 pins
2.12.0; and the vendored config's `plugins: musicbrainz` string form is the exact shape Phase 3
measured rc6 rejecting — killing the watchdog while the server still serves a page.

---

## beets-flask: in or out

| Option | Description | Selected |
|--------|-------------|----------|
| Config + dry run only (Recommended) | Stay as the criteria read; flask gets its own phase | |
| Stand flask up, prove config through it | Proving a config on 2.13.1 that 2.12.0 will execute proves the wrong thing | ✓ |
| Config here, flask defined-but-inert | Commit a definition that isn't started | |

**User's choice:** Stand flask up — *"2, but should we not be runing the latest version of beets and
not an older version 2.12 vs 2.13 or latest"*
**Notes:** The operator challenged the pin rather than accepting it. This triggered live research
against the upstream repo, which **closed Phase 5's open research question**: newest release is still
`v2.0.0-rc6` (2026-08-30) pinning `beets==2.12.0`; `main` is the stale 1.x line on `beets==2.5.1`;
live `beets_2_13` / `beets_2_14` branches exist unreleased. So "latest beets" and "the chosen front
end" are mutually exclusive today.

| Option | Description | Selected |
|--------|-------------|----------|
| Accept 2.12.0 under flask (Recommended) | Dated pin, named revisit trigger; 2.13.1 stays the CLI arm | ✓ |
| Wait for rc7 / beets_2_13 | Defers D-16 a third time on an upstream timeline | |
| Build our own image on 2.13.1 | Estate maintains a fork of a pre-release app writing to a 34 GB library | |

| Option | Description | Selected |
|--------|-------------|----------|
| One config, one DB, both mount it (Recommended) | Keeps Phase 4's D-28 true; makes "effective config" unambiguous | ✓ |
| One config, flask owns the only DB | Removes schema-migration risk; CLI arm can't query the library | |
| Separate configs, separate DBs | Reverses Phase 4's verified criterion 5 | |

| Option | Description | Selected |
|--------|-------------|----------|
| Survivor always uses throwaway -l (Recommended) | Only 2.12.0 opens the real library.db; asserted in health check | ✓ |
| Survivor mounts the DB :ro | Structural, but SQLite may need write access just to open | |
| Don't mount the DB into the survivor at all | Strongest, but needs a compose edit to ever undo | |

| Option | Description | Selected |
|--------|-------------|----------|
| Stays :ro for all of Phase 6 (Recommended) | Cannot fail open, unlike a file count | ✓ |
| Flask gets rw now, survivor stays ro | Deployment settled, but c5 falls back to file counts | |
| Both go rw now | Max exposure in the phase designed as the last cheap moment | |

| Option | Description | Selected |
|--------|-------------|----------|
| Three inboxes, hold/quarantine unregistered (Recommended) | 01-auto→auto, 02-review→preview, 03-asis→bootleg | ✓ |
| Two inboxes — no bootleg yet | DJ content gets no path through the tool | |
| Three inboxes, but 03-asis gated | Adds a script to a config-and-dry-run phase | |

**Notes:** Choosing three-without-gate leaves Phase 3's *"never route to bootleg without asserting
album is populated"* handoff unaddressed **in this phase**. Since nothing stages into `03-asis` here,
it is carried to Phase 7 routing time rather than dropped.

| Option | Description | Selected |
|--------|-------------|----------|
| Traefik + Authelia, no host port (Recommended) | The shape beets.yaml was corrected into after WR-02 | ✓ |
| Traefik + Authelia on a new hostname | Two DNS records and two routers for one logical tool | |
| Loopback host port only, no Traefik | SSH-tunnel friction on the axis that decides whether this finishes | |

| Option | Description | Selected |
|--------|-------------|----------|
| No — stays a Phase 9 risk (Recommended) | Nothing is staged here, so there is no population to lag at | ✓ |
| Yes — measure it cheaply now | Touches the inbox tree; empty folders may not reproduce real lag | |
| Partly — record the deploy knobs only | May find nothing | |

| Option | Description | Selected |
|--------|-------------|----------|
| Assert watchdog registration in logs (Recommended) | Cheap, fails on exactly the friction-9 condition | |
| Drive it — drop a folder in and watch | Proves firing, not registration | |
| Both — log assertion plus one driven folder | Catches silent schema rejection AND a registered-but-inert watchdog | ✓ |

**Notes:** The operator chose the stronger option over the recommendation. This **amends Phase 5's
D-17** ("the tree is created empty") — one folder transits `02-review` and is removed. Recorded as an
amendment rather than left as a contradiction.

| Option | Description | Selected |
|--------|-------------|----------|
| Revise to 2, both named and classed (Recommended) | Phase 4's F10 shape; a third unnamed definition still fails | ✓ |
| Keep 1 — retire the survivor definition | Loses the agent-driven CLI arm the operator kept | |
| Raise the number to 2, unnamed | A bare count is exactly what F10 exists to prevent | |

| Option | Description | Selected |
|--------|-------------|----------|
| Agent-driven CLI arm, stays dormant (Recommended) | Purpose written into beets.yaml's header as the drift guard | ✓ |
| Kept only as a break-glass tool | Forecloses scripted bulk work in Phases 8/9 | |
| Kept, purpose decided later | "A tool with no stated owner" is the shape this project prevents | |

---

## Path format specifics

| Option | Description | Selected |
|--------|-------------|----------|
| Top-level DJ/ sibling (Recommended) | `DJ/Mastermix/Issue 433/NN Title.ext` beside artist folders | ✓ |
| Separate library root entirely | Second export and second library per consumer | |
| ALBUMARTIST like everything else | Reverses a standing PROJECT.md requirement | |

| Option | Description | Selected |
|--------|-------------|----------|
| Flat, disc-prefixed `2-05 Title.ext` (Recommended) | Both consumers read disc from the tag; one directory = one album | ✓ |
| `Disc N/` subdirectory | The exact shape that hard-failed wrtag's validator, proven by ablation | |
| Flat, track only `05 Title.ext` | Disc 1 and disc 2 track 5 collide → the `.1` suffix c7 hunts | |

| Option | Description | Selected |
|--------|-------------|----------|
| Override comp: to use albumartist (Recommended) | Top level uniformly ALBUMARTIST, no exceptions | ✓ |
| Delete the comp: rule entirely | An absent rule is invisible to the next reader | |
| Keep comp: but point it at a literal Various Artists/ | Misfiles a compilation whose albumartist is a named DJ or label | |

| Option | Description | Selected |
|--------|-------------|----------|
| Keep %aunique, assert the divergence (Recommended) | 828 duplicate groups make removal worse; firings become Phase 7 MA risks | ✓ |
| Drop %aunique entirely | Trades a detectable MA problem for silent path collisions | |
| Fold the year into the album tag too | Modifies metadata to suit a path convention — a QUAL-02 argument waiting to happen | |

| Option | Description | Selected |
|--------|-------------|----------|
| Decide now, implement in Phase 7 (Recommended) | Narrow MA's provider path so DJ content doesn't flood browse | |
| Let DJ content into MA too | No narrowing | ✓ |
| Out of scope — defer entirely | Discovering it at Phase 7 criterion 6 is the worst moment | |

**User's choice (free text):** *"dj content into ma, but remember the metadata is important, as a dj
using traktor, algroidm dj, rekord box, etc i cant play if my tracks are not tagged, and setup my
crates"*
**Notes:** This is the most consequential disclosure of the session. The DJ collection is **working
material, not an archive**. It retroactively explains why Phase 1's fence specifically captured
`TKEY` (148 files) and `EnergyLevel` (45 files), and it reframes DJ metadata as a **config**
obligation in Phase 6, not only a Phase 7 QUAL-02 concern — because MusicBrainz carries none of
BPM / key / energy / operator comments, so a MusicBrainz-driven import is precisely what strips them.

| Option | Description | Selected |
|--------|-------------|----------|
| Named protected field list in config (Recommended) | Enumerate DJ fields; dry run reports any proposed change | ✓ |
| Rely on scrub.auto: no being off | The "absent key is the on switch" reasoning this project has been bitten by | |
| Protect, and treat any DJ-field change as a hard stop | A Phase 7 gate wearing Phase 6 clothes | |

| Option | Description | Selected |
|--------|-------------|----------|
| No — preserve only, analysis is separate (Recommended) | Those plugins rewrite audio files; own phase | ✓ |
| Enable beets' analysis plugins now | Rewrites files — the operation most carefully kept off | |
| Let the DJ software own it entirely | The existing 148 TKEY files suggest they do want it in the files | |

| Option | Description | Selected |
|--------|-------------|----------|
| Prevent by rule, don't repair the file (Recommended) | Nothing new lands in that shape; Def Leppard stays bad | |
| Prevent AND schedule the repair for Phase 7 | Also fixes the existing entry rather than leaving MA noise | ✓ |
| Neither — leave it as a known one-off | If it's a class, Phase 9 reproduces it at scale | |

| Option | Description | Selected |
|--------|-------------|----------|
| Own path rule, and flag them in the dry run (Recommended) | The report is the real deliverable | ✓ |
| Refuse singletons entirely | Hand-handling an unknown number of folders in Phase 9 | |
| Default beets handling | The exact configuration under which 20 became 20 silently | |

---

## Criterion 4's consumer proof

| Option | Description | Selected |
|--------|-------------|----------|
| Find one already in the library (Recommended) | Zero writes, zero rw exposure, tests real content | ✓ |
| One deliberate test file, fenced and removed | Requires reversing the :ro decision just made | |
| Defer criterion 4 to Phase 7 | Closes a criterion on "tool configured" | |

| Option | Description | Selected |
|--------|-------------|----------|
| Fall back to a fenced test file (Recommended) | Pre-authorised so the rw grant is deliberate, not improvised | ✓ |
| Accept a `/` or `,` delimited example instead | Answers a different question than c4 asks | |
| Mark criterion 4 OPEN and carry to Phase 7 | Honest, and this project has done it before rather than fake a pass | |

| Option | Description | Selected |
|--------|-------------|----------|
| Two distinct artist entities in each consumer (Recommended) | Checked separately, because a setting can read back correct while behaving otherwise | ✓ |
| Artist count matches, in both | A count can match while names are wrong — Phase 3 measured that class | |
| Visible in both, artists rendered | "It looks right" is the standard CONS-04 exists to replace | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — configure and verify in the dry run (Recommended) | Otherwise we prove consumers read a delimiter the pipeline may never produce | ✓ |
| Read side only, write side in Phase 7 | The split that makes a phase close green and a later one fail | |
| Write side only — trust the consumer research | Reading a setting back is not proof it applies | |

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted scan, never FullRefresh (Recommended) | FullRefresh rewrote 83 of 91 .nfo even with SaveLocalMetadata off | ✓ |
| Unpause the scheduled scan for this phase | Re-enables a deliberately permanent freeze | |
| Read Jellyfin's API without scanning | Only works on the primary route | |

| Option | Description | Selected |
|--------|-------------|----------|
| Prove in Jellyfin first, MA last and only if needed (Recommended) | MA never purges — a rolled-back test file leaves a permanent phantom | ✓ |
| Accept the phantom, record it by name | Small junk, but this project's thesis is that it compounds | |
| Find MA's purge path first | May not exist short of a full library reset — the outcome Phase 2 avoided | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — search harder before falling back (Recommended) | Primary route has zero phantom risk and zero rw exposure | ✓ |
| No — keep them equally weighted | Convenience picks the route with rw and a permanent artefact | |
| Yes, and widen the search beyond the library | A backlog file isn't in either consumer, so it can't answer the question | |

---

## Dry-run sample + the oracle

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic draw, committed before running (Recommended) | Same discipline as Phase 3's 24-folder draw | ✓ |
| Hand-picked to cover the criteria | Proves the config works on cases chosen because it works on them | |
| Whole backlog, --pretend only | Output too large to actually read = unverified in practice | |

| Option | Description | Selected |
|--------|-------------|----------|
| Committed expected-tree file, diffed (Recommended) | Zero-diff is the pass; makes case-sensitivity checkable | |
| Assertions over the output | Only catches classes someone thought to assert | |
| Both — expected tree plus assertions | Wrong path fails the diff; a new failure class still trips an assertion | ✓ |

**Notes:** Second time the operator chose the stronger option over the recommendation.

| Option | Description | Selected |
|--------|-------------|----------|
| No — prove preferred.countries as written (Recommended) | Using the embedded id proves a different mechanism | ✓ |
| Use it as a cross-check only | Confirming the id means a Discogs lookup; credential dismissed | |
| Yes — prefer the embedded id | Rewrites c5's stated mechanism, needs the dismissed credential | |

| Option | Description | Selected |
|--------|-------------|----------|
| Assert all three layers (Recommended) | Library by :ro, source by checksum manifest, beets state by byte-identical DB | ✓ |
| Counts before and after, all three | The criterion's own wording is the weak part | |
| Rely on :ro and --pretend semantics | Pure inference; beet has surprised this project once already | |

| Option | Description | Selected |
|--------|-------------|----------|
| docker exec into the flask container (Recommended) | "Effective config" = the config of the thing that runs | |
| Use flask's `preview` policy as the dry run | Previews aren't path-format output, so nothing to diff | |
| Both — exec for the oracle, preview as cross-check | A disagreement between them is itself a finding | ✓ |

**Notes:** Third time the stronger option was chosen.

| Option | Description | Selected |
|--------|-------------|----------|
| Prove it with a negative control (Recommended) | Shown capable of failing, not merely observed passing | ✓ |
| Set both, assert them in effective config | Reading a setting back is not proof it applies | |
| Set both, and add a standing drift check | Guards the future, never demonstrates the present | |

| Option | Description | Selected |
|--------|-------------|----------|
| Keep it — sign-off is Phase 7's, not Phase 6's (Recommended) | A paper phase produces no evidence Phase 5's changes were correct | ✓ |
| Release it at Phase 6 close | Destroys the only undo for 26,005 chowns before the phase that first writes | |
| Take a fresh combined fence instead | A new snapshot doesn't capture the pre-Phase-5 state | |

---

## Claude's Discretion

- Exact beets path-template syntax for the DJ, multi-disc, compilation and singleton rules.
- Which Jellyfin and MA API endpoints serve the per-consumer artist-entity check; MA sync timing.
- The `docker exec` invocation shape for the dry run, and flask's appdata path layout.
- Whether rc6 exposes pagination/inbox-size knobs worth recording for Phase 9.

## Deferred Ideas

- BPM / key / energy generation for the ~616 `dj-mixes` files that have none — own phase, own fence.
- The `bootleg` album-populated gate — Phase 7 routing time.
- The per-file `LOCATION=…/release/NNNNNN` Discogs id as a bulk shortcut — Phase 9.
- beets-flask's folder-count lag past ~100 folders — Phase 9.
- Repairing `Def Leppard/Def Leppard (2015)/` — scheduled into Phase 7.
- `beet modify +=` / `-=` and the `edit` album-YAML header — unblocked by the D-02 revisit trigger.
- DUPE-01 / DUPE-02 — needs a roadmap decision **before Phase 7**; now the nearest unowned blocker.
- `mac-music-archive/`'s 23,874 uncharacterised entries, and the stale 144-folder denominator.
- The four Phase 5 OPEN items.
