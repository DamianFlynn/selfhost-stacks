# Phase 5: Inbox Structure and the Junk Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-18
**Phase:** 05-inbox-structure-and-the-junk-gate
**Areas discussed:** The Now! 1-115 split, Junk gate scope + destination, Seeding vs empty mkdir,
Ownership of the staging tree, Sidecar disposition, `_done/` semantics, Junk rule vs judgement,
Ordering fence

---

## Pre-discussion measurements

Three read-only probes were run from LXC 100 before the gray areas were presented, and
`05-PREMEASURE.md` (written independently from atlantis the same day) was read. Findings that
changed the questions asked:

- The Harry Potter rip is **not** in `dj-mixes` — it is in `unsorted/`. `dj-mixes` holds no video.
- `Now! 1-115` is **flat**: 4,760 files, zero subdirectories.
- 6 of the 10 `_FAILED_`/`_UNPACK_` directories belong to Sonarr and Radarr, not to music.
- A full `ffprobe` scan of all 4,746 mp3 returned **117 distinct `album` values for 115 volumes**,
  every file tagged. The m3u manifest lists **4,770** tracks — 24 more than exist on disk.

---

## The Now! 1-115 split

| Option | Description | Selected |
|--------|-------------|----------|
| m3u as map, tags as cross-check | Manifest carries original path (volume + CD1/CD2); album tag asserts agreement; disagreement quarantined | ✓ |
| album tag only | Group by normalised album string; needs three hand-rules; recovers no disc attribution | |
| m3u only | Build from manifest alone; unverified against the files themselves | |

**User's choice:** m3u as map, tags as cross-check
**Notes:** Chosen as the paired-instrument method that caught three defective instruments in 03-07.
The "m3u only" option was framed against Phase 4's criterion-3 failure, which rested on an unchecked
capture assumption.

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-declare as expected shortfall | Name all 24 by path before the run (D-31 shape) | ✓ |
| Investigate first, then decide | Determine why 24 vanished before splitting | |
| Treat as a blocking defect | Don't split until the 24 are recovered | |

**User's choice:** Pre-declare as expected shortfall
**Notes:** Cause is almost certainly filename collision during the flatten. Not chased.

| Option | Description | Selected |
|--------|-------------|----------|
| Flat per-volume, disc tags intact | One directory = one beets album candidate; every file carries `disc=1/2` | ✓ |
| Restore CD1/CD2 subdirectories | Faithful to the original shape the m3u records | |

**User's choice:** Flat per-volume, disc tags intact
**Notes:** Restoring the subdirectories risks beets matching each volume as two albums — the
multi-disc shape QUAL-03 reserves for Phase 7 to exercise deliberately.

| Option | Description | Selected |
|--------|-------------|----------|
| Move, in place under `unsorted/` | Atomic same-dataset rename; `unsorted/` stays the immutable source | ✓ |
| Move, straight into `_inbox/01-auto` | Split and stage in one pass | |
| Copy, leaving `unsorted/` untouched | 45 G duplicate on top of the snapshot | |

**User's choice:** Move, in place under `unsorted/`
**Notes:** The `_inbox/01-auto` option was flagged as seeding the wrong bucket — the Now! series is
bucket B, needing UK/US disambiguation and human confirmation.

| Option | Description | Selected |
|--------|-------------|----------|
| 4,746 mp3 on disk | What provably exists and what the split moves | ✓ |
| 4,770 from the manifest | Would fail by 24 on every run | |
| 4,761 total entries including sidecars | Mixes "did every track land" with "did the artwork land" | |

**User's choice:** 4,746 mp3 on disk
**Notes:** The 24 manifest-only entries reported on their own line, never folded into the total.

---

## Junk gate scope + destination

| Option | Description | Selected |
|--------|-------------|----------|
| Music paths only | `music/`, `unsorted/`, `dj-mixes/`, `lidarr-import/`; criterion 2 amended in-band | ✓ |
| Whole download tree, as written | Literal reading; quarantines Sonarr's and Radarr's failures | |
| Music paths now, report the rest | Sweep music, inventory the other six as a named finding | |

**User's choice:** Music paths only
**Notes:** The 6 TV/movie items are not lost by the narrowing — they are already named in
`05-PREMEASURE.md` § 5. This was confirmed to the user before the area closed.

| Option | Description | Selected |
|--------|-------------|----------|
| Move to `99-quarantine`, delete nothing | Atomic rename, reversible with `mv` | ✓ |
| Move, then delete after a stated dwell time | Purge would never fire — nothing in this estate is scheduled | |
| Delete outright | No undo; the 2 Garth Brooks items name Phase 4's probe album | |

**User's choice:** Move to `99-quarantine`, delete nothing
**Notes:** Matches DUPE-01's standing "quarantine, never `--delete`" posture.

| Option | Description | Selected |
|--------|-------------|----------|
| Means `unsorted/` — quarantine that one | Correct the criterion to name the right tree | ✓ |
| Already satisfied — assert and move on | True to the letter; leaves a movie rip in the music backlog | |
| Refile it to the movies tree | Hands content to another service's import path uninvited | |

**User's choice:** Means `unsorted/` — quarantine that one
**Notes:** `05-PREMEASURE.md` § 4 deliberately declined to choose between these two readings and
referred it to discuss-phase. This answers it.

| Option | Description | Selected |
|--------|-------------|----------|
| Out of scope entirely | SABnzbd's live working directory; `direct_unpack` drains jobs there | ✓ |
| In scope, read-only inventory | Count and record without touching | |
| In scope, sweep it too | Most likely single action in the phase to break a live download | |

**User's choice:** Out of scope entirely

**Continue check:** offered "More questions" / "Next area" — user chose **Next area**.

---

## Seeding vs empty mkdir

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 6, with Phase 5 fixing the paths | Keeps Phase 5 purely filesystem, matching its own criteria | ✓ |
| Phase 5, as D-01 said | Honours Phase 4's deferral literally | |
| Phase 5, definition only — not running | Dormant definition, paths wired in git | |

**User's choice:** Phase 6, with Phase 5 fixing the paths
**Notes:** This amends Phase 4's D-01. The tension was put to the user explicitly: D-01 deferred
beets-flask *to* Phase 5, but Phase 5's four criteria and all three INBX requirements are pure
filesystem. D-01's own objection ("inert, at beets 2.12.0, against inboxes that do not exist") was
noted to half-dissolve — the inboxes now exist, the version pin does not move.

| Option | Description | Selected |
|--------|-------------|----------|
| Empty tree, except the junk | Criterion 1 asks only that the tree exist and a move be atomic | ✓ |
| Seed a small bucket-A sample into `01-auto` | Gives Phase 6 a real staged sample | |
| Seed the Now! volumes into `02-review` | Commits 45 G to a queue before the tagger is configured | |

**User's choice:** Empty tree, except the junk

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — triage and fold in | Closes Phase 1's D-23 rather than passing it to Phase 8 | ✓ |
| Inventory only, defer the move | Confirm it isn't an active import target first | |
| Out of scope — Phase 8 | Phase 8 owns the inflow | |

**User's choice:** Yes — triage and fold in
**Notes:** Holds 2 artist folders (Madonna, Michael Jackson).

| Option | Description | Selected |
|--------|-------------|----------|
| Synthetic fixture + cross-dataset negative control | Proves the inode instrument can change, not just stay the same | ✓ |
| Synthetic fixture, positive proof only | Sufficient for the criterion's literal wording | |
| Use a real quarantined release | Ties evidence to work the phase does anyway | |

**User's choice:** Synthetic fixture + cross-dataset negative control
**Notes:** Flagged during CONTEXT.md authoring: the negative control writes into
`/mnt/tank/media/Music`, which Phase 1's D-20 protects until Phase 6. Recorded as a planner
constraint with a fallback (any dataset on a different `devid`).

---

## Ownership of the staging tree

| Option | Description | Selected |
|--------|-------------|----------|
| `568:568`, created from atlantis | Matches the library convention in four documents | ✓ |
| `3000`, matching the download client | Consistent with its neighbourhood rather than the library | |
| Whatever it inherits — don't specify | Leaves nothing for a later assertion to check | |

**User's choice:** `568:568`, created from atlantis

| Option | Description | Selected |
|--------|-------------|----------|
| No — staging is mixed by design, and say so | Stops a later "everything is 568:568" assertion that was never true | ✓ |
| Yes — chown on move | Uniform staging, at the cost of a privileged step per move | |

**User's choice:** No — staging is mixed by design, and say so

| Option | Description | Selected |
|--------|-------------|----------|
| No — record as measured-and-deferred with the reason | *(Recommended, NOT selected)* | |
| Yes — normalise `tank/downloads` to `568:568` | ~198k entries, host-only | ✓ |
| Partially — only the music paths | Smaller blast radius | |

**User's choice:** Yes — normalise `tank/downloads` to `568:568`
**Notes:** **Taken against the stated recommendation.** The recommendation's reasoning (downloads is
not NFS-exported, is 0777, and uid 3000 legitimately owns what it wrote) is preserved verbatim inside
D-22 so a future reviewer meets reasoning rather than silence. The consequence — that uid 3000
resumes writing immediately at ~1 job per 72 s — was raised once as a factual consequence and led to
two follow-up questions rather than a re-litigation of the decision.

| Option | Description | Selected |
|--------|-------------|----------|
| No — plain directory, and record WHY | A dataset would break criterion 1's atomic rename outright | ✓ |
| Yes — own dataset for quota and snapshots | Mirrors `fast/transcode` from Phase 02.1 | |

**User's choice:** No — plain directory, and record WHY

### Follow-ups raised by the normalisation decision

| Option | Description | Selected |
|--------|-------------|----------|
| One-time sweep, verified, no standing assertion | Measurement is the deliverable; no check that would go red on the next download | ✓ |
| Also change the download client to run as 568 | Fixes the source; reaches every category and other services | |
| Sweep now, add a periodic re-chown | Needs scheduling infrastructure the phase hasn't scoped | |

**User's choice:** One-time sweep, verified, no standing assertion

| Option | Description | Selected |
|--------|-------------|----------|
| All of `tank/downloads`, as decided | All 209,039 entries, one pass | ✓ |
| Music paths + `_inbox` only | Leaves the carry-in partly answered | |
| Everything except `incomplete/` | Avoids chowning files mid-unpack | |

**User's choice:** All of `tank/downloads`, as decided

---

**Wrap-up check:** offered "I'm ready for context" / "Explore more gray areas" — user chose
**Explore more gray areas**. Four further areas were identified and all four selected.

---

## Sidecar disposition in the Now! split

| Option | Description | Selected |
|--------|-------------|----------|
| Subfolders inside the Now! folder; sidecars stay put | Map survives in place; reconciliation stays exactly 4,746 with one file-type rule | ✓ |
| Sidecars follow their volume where attributable | Tidier per-volume result; makes the move rule conditional | |
| 115 folders as siblings under `unsorted/`; sidecars to the fence | Separates the map from the content it verifies | |

**User's choice:** Subfolders inside the Now! folder; sidecars stay put
**Notes:** The 14 sidecars are 3 `.m3u`, 7 EAC `.log`, 1 `.cue`, 3 `.bmp`. The decisive argument was
that one of them is the 9,541-line map the split is verified against.

---

## What `_done/` holds, and its cost

| Option | Description | Selected |
|--------|-------------|----------|
| Whole source folder, pruned only after CONS-04 passes | The original is the undo path; beets has no `undo` | ✓ |
| Receipt file only; source deleted after import | Deletes the untouched copy exactly when QUAL-02 might reject the import | |
| Whole source folder, kept indefinitely | Staging becomes permanent storage nobody owns | |

**User's choice:** Whole source folder, pruned only after CONS-04 passes

---

## What counts as junk — rule or judgement

| Option | Description | Selected |
|--------|-------------|----------|
| Script builds the list, operator approves it, script acts from the file | The `spike03-image-headroom.sh` gate 02.1-09 ran successfully | ✓ |
| Pure rule list, no gate | Repeatable; nothing stops a rule matching something worth keeping | |
| Judgement pass, human-driven | Accurate at this scale; not repeatable, and Phase 8 needs the rules written down | |

**User's choice:** Script builds the list, operator approves it, script acts from the file

---

## Ordering fence and resumability

| Option | Description | Selected |
|--------|-------------|----------|
| Snapshot → create `_inbox` → junk sweep → Now! split → chown last | Chown last also normalises what the phase created; shortest drift window | ✓ |
| Snapshot → chown → create `_inbox` → sweep → split | Drift window as long as the rest of the phase | |
| Let the planner decide the order | Only "snapshot first" fixed | |

**User's choice:** Snapshot → create `_inbox` → junk sweep → Now! split → chown last

---

## Claude's Discretion

- Plan decomposition within the D-25 ordering, subject to two fixed constraints: D-01's snapshot is
  the first act, and D-13's approval gate blocks the junk move.
- Exact wording of D-10's two in-band ROADMAP/REQUIREMENTS amendments (02.1-11 shape).
- How D-19's cross-dataset negative control is squared against Phase 1's D-20.
- The exact rule list D-13's enumerator implements beyond the four patterns criterion 2 names.
- Whether D-04's 24 files are listed inline in the plan or in a referenced artifact.

## Deferred Ideas

- beets-flask stack definition and configuration — Phase 6 (D-15), carrying Phase 3's friction 9;
  plus an open research question on whether it has shipped past `2.0.0-rc6`.
- `dj-mixes`'s 84 inconsistent top-level folder names — Phase 6 matching work
  (`05-PREMEASURE.md` § 8).
- The 6 TV/movie `_FAILED_` directories — out of scope by D-09, named in `05-PREMEASURE.md` § 5.
- The stalled `incomplete/Harry.Potter…hallowed` job with its `__ADMIN__` directory — SABnzbd's to
  clear; worth mentioning to Phase 8.
- Investigating why the 24 Now! tracks vanished in the flatten — pre-declared, not chased.
- Changing SABnzbd's runtime identity to uid 568 — considered and rejected under D-23.
- `_done/` pruning mechanics at backlog scale — Phase 9's batch cadence makes it operationally real.
- DUPE-01 / DUPE-02 — still needs a roadmap decision before Phase 7.
- `/mnt/tank/media/TV` on the orphan gid 545 — outside this milestone.

---

# Operator corrections — same session, after CONTEXT.md v1

The operator reviewed the captured context and corrected three things. Each is recorded with what it
superseded, because two of them reverse a decision made earlier in the same discussion.

## Correction 1 — the Potter rip is not a blocker

**Operator:** *"potter should not be a blocker - its a video - junk that is in a music folder, we need
to just git rid of it."*

**Superseded:** the earlier D-10, which made the Potter clause half of a two-part in-band criterion
amendment and treated "what did the clause mean" as a decision needing ceremony.

**Now (D-14):** it is ordinary junk. It goes through the same approval gate as everything else and is
deleted. The criterion's factual error — it names `dj-mixes`, which contains no video at all — is
corrected as a **one-line note inside the scope amendment**, not as an amendment of its own.

## Correction 2 — sidecars are triaged by value, and 99-quarantine deletes

**Operator:** *"we talk about side cars, most is also junk, but some might have context, a scan of the
cd case with track listings, an nfo file or m3u that has context, - if its vaule - then keep it -
otherwise it gets queued to 99 for review and delete."*

**Superseded two decisions:**
- The earlier D-06, "all 14 sidecars stay at the root, untouched", which was a blanket keep.
- The earlier D-11, "move to `99-quarantine`, delete nothing", which made quarantine an archive.

**Now (D-06, D-11, D-13):** each sidecar is judged individually on whether it carries context;
`99-quarantine` is a review-and-delete queue and the deletion happens inside this phase, through the
approval gate.

**Evidence gathered to apply the rule** — the files were opened rather than judged by extension:

| Sidecar | Found to be | Verdict |
|---|---|---|
| `00.Now…1-115.m3u` | The 9,541-line map the split depends on | Keep |
| `back.bmp` | **NOW 77** back cover — both tracklists, barcode, `UK:CDNOW77` | Keep → vol 77 |
| `cd1.bmp` | **NOW 77** disc 1 face | Keep → vol 77 |
| `cd2.bmp` | Presumed NOW 77 disc 2 — not individually opened | Keep, verify at execution |
| `NOW…115.cue` | EAC cue, per-track TITLE + PERFORMER, vol 115 | Keep → vol 115 |
| 7 × `.log` | EAC rip-verification logs (vols 110, 111, 113, 114, 115) | → 99, delete |
| `play.m3u`, `00. play.m3u` | 97- and 51-line playlists, no volume identity | → 99, delete |

**The finding that justified the rule:** the scans turned out to belong to volume **77**, while the
`.cue`/`.log` belong to 110–115. The sidecars are scattered leftovers from different volumes, so
nothing but opening them could have attributed them. A blanket keep would have hoarded seven
worthless rip logs; a blanket discard would have destroyed a tracklist scan and the map.

## Correction 3 — the tags should be correct

**Operator:** *"your now album point - each album has 1 2 or more disks and tracks, these can be all in
the one folder, but the tags should be correct if at all possible."*

**Confirmed** the earlier decision that all discs of a volume live in one folder (D-05).
**Added** a requirement the earlier context did not carry: tag correctness, not merely tag
preservation.

**Measured in response, full scan of all 4,746 mp3:**

| Check | Result |
|---|---|
| Missing `disc` tag | 0 |
| Missing `track` tag | 0 |
| Distinct `disc` formats | three only — `1/2`, `2/2`, `1/1` |
| Distinct `album` values | 117, for 115 volumes |
| Volumes failing `files == Σ tracktotal` | 13 |

So `disc` and `track` are **already correct**; `album` is the one wrong field. This produced two new
decisions and upgraded two existing ones.

### New questions put to the operator

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, but only the album tag, in this phase | One field, one collection; reuses `normalise-dj-tags.py` | ✓ |
| No — record the repair, let Phase 6 do it | Phase 5 stays pure filesystem | |
| Yes, and fix the 3 surplus volumes' tracktotal too | Needs investigation first | |

**User's choice:** Yes, but only the album tag, in this phase → **D-10**
**Notes:** Volume 36's folder would otherwise contain three different album strings and beets would
not see one album. Scoped deliberately narrow. The QUAL-01 snapshot is keyed on `audio_md5`, so a tag
write does not break Phase 7's diff join — this was the deciding safety property.

| Option | Description | Selected |
|--------|-------------|----------|
| Split them anyway, flag them in the record | An incomplete Now! volume is still importable | ✓ |
| Split, and route the 13 to `04-hold` | `04-hold` is scoped for missing artwork, not missing audio | |
| Investigate the 3 surplus volumes first | | |

**User's choice:** Split them anyway, flag them in the record → **D-09**

| Option | Description | Selected |
|--------|-------------|----------|
| Move to 99, operator reviews the list, approved items deleted | Quarantine is a review queue | ✓ |
| Move to 99 now, delete in a later pass | | |
| Delete outright, skip the quarantine hop | | |

**User's choice:** Move to 99, review, delete → **D-11**

### Upgrades this forced to existing decisions

- **D-04** — the 24-file gap changed from *counted* to *located*. The identity
  `files == Σ tracktotal` resolves it to named volumes: short by 1 (15, 18, 39, 52, 70, 83, 98),
  short by 2 (3), surplus (4 +13, 8 +9, 9 +14), plus the vol 36 split-tag mess. The three surplus
  volumes are flagged as needing an answer, not just a flag — they are all `[2019 Reissue]` and a
  surplus could mean mis-tagged files leaking in, which would corrupt the split.
- **D-08** — reconciliation is now per-volume rather than a single total of 4,746, because a bare
  total would pass even if every file landed in the wrong folder.
- **D-27** — the ordering gains a step: the tag repair runs **after** the split, since the split
  produces the grouping the repair applies to.

## Process notes worth keeping

- **`ffprobe` takes one input file.** The first full tag scan used `xargs -n 50 ffprobe`, which fed
  50 files to one invocation, produced zero output and exited clean. It reported "0 distinct album
  values" and looked like a finding. Caught only because zero was implausible. Recorded in
  CONTEXT.md § *Integration Points and Hazards*.
- **The tag inventory was written to `/tmp/now_tags.tsv` on LXC 100, which is tmpfs.** It is not
  durable and it consumes host RAM. CONTEXT.md § *Canonical References* requires the plan to
  regenerate it under `/mnt/fast/`.
