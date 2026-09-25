# Phase 7: Pilot — 12 Albums End to End - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 7-pilot-12-albums-end-to-end
**Areas discussed:** The new archive and import scope, The sample draw, DUPE-01 last-wins (E7),
The undo shape (QUAL-04), Execution path + the rw grant (E3/E11), Closure, Remaining entry criteria

The operator selected all four offered gray areas and raised a fifth unprompted — *"we have
discovered 1TB of music that needs to be de-duped and processed, that is now a folder on this
system also, we need to discuss when and how that gets added to the import scope"* — which was
taken first because it constrains the sample draw.

---

## The new archive and import scope

**Finding that framed the area:** `tank/downloads/mybook-music-archive` (1.30 T, 175,050 files,
165,467 audio, 21,923 duplicate groups, 450 distinct DJ releases) is **not one of the four QUAL-01
capture roots** pinned in `scripts/snapshot-music-tags.sh`, so criterion 4's diff is uncomputable
for anything drawn from it.

| Option | Description | Selected |
|--------|-------------|----------|
| No — own phase, decide trigger now *(recommended)* | Phase 7 draws only from QUAL-01-covered roots; the archive gets its own capture-then-import phase with a named trigger | ✓ |
| Capture its before-state during Phase 7 | Run `snapshot-music-tags.sh --roots` over it in parallel; ~17× Phase 1's file count, a multi-day background run | |
| Draw some of the 12 from it | Capture a bounded before-state over chosen folders first; reintroduces hand-picking | |

**User's choice:** No — own phase, decide trigger now.

| Option | Description | Selected |
|--------|-------------|----------|
| New Phase 10, after 9 *(recommended)* | Inside v1.0 but strictly last; trigger = Phase 9's criteria satisfied | |
| Beyond This Milestone, with a named trigger | Beside DUPE/NOWB/DJCC/LIDR; keeps v1.0's denominator honest | |
| New phase between 8 and 9 | Capture + dedupe first so Phase 9 draws from the whole backlog | ✓ |

**User's choice:** New phase between 8 and 9.
**Notes:** Overruled the recommendation toward doing the work earlier. Follows the `02.1` inserted-
phase precedent. Consequence: Phase 9 stops being purely throughput and inherits a deduped backlog.

---

## The sample draw

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 6's ten + 2 fresh *(recommended)* | Reuse `06-SAMPLE.md`; turns the dry run into a validated prediction against `06-EXPECTED-TREE.txt` | ✓ |
| Fresh seeded draw of twelve | Tests generalisation; no committed oracle exists | |
| Stratified fresh draw | Guarantees the required shapes; discards the Phase 6 oracle | |

**User's choice:** Phase 6's ten + 2 fresh.
**Notes:** Reading `06-SAMPLE.md` in full then surfaced that it is *already* stratified and seeded
(S1–S7), that **S6 is a `media/Music` library folder and not importable**, and that S4 and S5 are
buckets B and C — which reopened the composition question below.

| Option | Description | Selected |
|--------|-------------|----------|
| Bucket A only — 6 reused + 6 fresh *(recommended)* | Honours criterion 1 as written; E1 defers a fourth time | |
| All nine importable + 3 fresh | Spans all three buckets; forces E1 and ends the defer chain | |
| Bucket A + the DJ pair | Six bucket-A rows + 2 S5 + 4 fresh; drops the *Now!* volume; E1 gets decided | ✓ |

**User's choice:** Bucket A + the DJ pair.
**Notes:** Second overrule toward the stronger option. Directly causes E1 to become a Phase 7
decision rather than a fourth deferral (Phase 4 → 5 → 6 → 7).

| Option | Description | Selected |
|--------|-------------|----------|
| `beet modify` + `beet move`, post-import *(recommended)* | Works today, no new code; `beet move` is the proven instrument | ✓ |
| Hook plugin keyed on source path | Correct on first write; new Python inside a pre-release web app | |
| Global `import.set_fields` | Roadmap names and rejects it — would stamp every import | |

**User's choice:** `beet modify` + `beet move`, post-import.
**Notes:** Must run inside the flask container via `docker exec` — D-04 forbids the 2.13.1 arm from
opening the real `library.db`. Surfaced during the question, not after.

| Option | Description | Selected |
|--------|-------------|----------|
| Reserve one of the four fresh slots for it *(recommended)* | Declared ≥4-artist stratum, target 1, drawn within its eligible set | ✓ |
| Take it opportunistically | Unconstrained draw; E6's second measurement probably defers again | |
| Write a fenced test file, as D-21 did | Guarantees the measurement; D-25's MA phantom risk | |

**User's choice:** Reserve one of the four fresh slots for it.

| Option | Description | Selected |
|--------|-------------|----------|
| One album, gate, then eleven *(recommended)* | Plan 05-09's shape; catches a systemic fault after one album | ✓ |
| All twelve in one batch | Simplest; failure harder to attribute | |
| Three batches of four | Rehearses Phase 9 cadence; ceremony out of proportion | |

**User's choice:** One album, gate, then eleven.

| Option | Description | Selected |
|--------|-------------|----------|
| S2 — Michael Jackson, *The Essential* *(recommended)* | 32 FLAC, `disctotal=2`, four artists; the gate can genuinely fail | ✓ |
| The Benson Boone duplicate pair | Hardest case first; learns about duplicates before the pipeline | |
| An S1 single-artist album | Simplest; close to the vacuous gate 05-09 warned about | |

**User's choice:** S2 — Michael Jackson, *The Essential*.
**Notes:** Framed against plan 05-09, where the operator amended the proposed pilot because
`Vol 077` had zero proposed changes and would have passed its gate vacuously.

| Option | Description | Selected |
|--------|-------------|----------|
| `music/` and `unsorted/` combined *(recommended)* | 162 folders / 3,236 files; `unsorted/` is Phase 9's real population | ✓ |
| `music/` only | Cleanest material; avoids DUPE-01 entirely | |
| `unsorted/` only | Maximum DUPE-01 exposure; includes the untested WAV shape | |

**User's choice:** `music/` and `unsorted/` combined.
**Notes:** This choice created the `ROADMAP.md` conflict resolved in the DUPE area below.

| Option | Description | Selected |
|--------|-------------|----------|
| Freeze Phase 6's lines, append new ones *(recommended)* | `git show <commit>:…` byte-identical; convention 10 | ✓ |
| Re-derive all twelve from current config | One consistent oracle; but derived from the config it judges | |
| Both — frozen and re-derived, diffed | D-27's "both oracles" shape; a third artifact | |

**User's choice:** Freeze Phase 6's lines, append new ones.

| Option | Description | Selected |
|--------|-------------|----------|
| Named read-only class assertion, no import *(recommended)* | `beet move -p` over one of the seven `disctotal=2` folders; what 06-11 was told to do and did not | ✓ |
| Leave it deferred, as the roadmap says | Avoids hand-picking; leaves an unevaluated rule live through an `rw` phase | |
| Add one of the seven as a thirteenth album | Exercises rule 2 end to end; breaks criterion 1's count | |

**User's choice:** Named read-only class assertion, no import.

---

## DUPE-01 last-wins (E7)

**Finding that framed the area:** `scripts/diff-music-tags.sh:156` —
`def index: reduce .[] as $r ({}; .[$r.k] = $r);` keeps only the last record per `audio_md5`.
`dupgroups` reports the count *after* the join discarded those rows, so whether QUAL-02 fires
depends on file-walk order.

| Option | Description | Selected |
|--------|-------------|----------|
| Fail closed — AMBIGUOUS, exit 3 *(recommended)* | Three-state convention; identical duplicates collapse harmlessly | ✓ |
| Union the BEFORE duplicates | Deterministic and order-independent; silently picks a policy | |
| Exclude twinned folders from the draw | Sidesteps it for the pilot; leaves the instrument broken for Phase 9 | |

**User's choice:** Fail closed — AMBIGUOUS, exit 3.

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow the rule to bulk import, amend in band *(recommended)* | `ROADMAP.md`'s "must precede any import of `unsorted`" → "any BULK import", pilot named as the exception | ✓ |
| Pull the fresh draws back to `music/` only | Honours the rule as written; reverses the earlier decision | |
| Resolve DUPE-01/02 before the pilot | Honours the rule fully; puts an open-ended data project in front of the pilot | |

**User's choice:** Narrow the rule to bulk import, amend in band.
**Notes:** The option text carried its own counter-argument — *narrowing a safety rule to fit the
plan is exactly how safety rules die* — and the decision is recorded with the requirement that the
amendment be argued, not merely edited.

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into the new phase between 8 and 9 *(recommended)* | One dedupe for the whole estate, against one inventory | ✓ |
| Leave in Beyond This Milestone | The fail-closed gate discharges E7's urgency; Phase 9 adjudicates by hand | |
| Its own phase, before 9 | Two independent reconciliations over overlapping data | |

**User's choice:** Fold into the new phase between 8 and 9.

| Option | Description | Selected |
|--------|-------------|----------|
| Synthetic fixtures AND the real snapshot *(recommended)* | Both ways on fixtures, plus a run over the real QUAL-01 snapshot | ✓ |
| Synthetic fixtures only | Offline and permanent; the exact shape E12 names as residue | |
| Real snapshot only | Real corpus; a passing run does not prove the arm can fire | |

**User's choice:** Synthetic fixtures AND the real snapshot.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — symmetric, both sides fail closed *(recommended)* | An AFTER-side duplicate is a `.1`-collision or `duplicate_action` miss | ✓ |
| BEFORE side only | Minimal change targeted at E7 as written | |

**User's choice:** Yes — symmetric, both sides fail closed.

---

## The undo shape (QUAL-04)

| Option | Description | Selected |
|--------|-------------|----------|
| flask's `UNDO IMPORT`, `state.pickle` proven *(recommended)* | The operator-facing path; `beets.md:1331` flags it as the CLI's missing undo | ✓ |
| `docker exec beet remove` + tree + state reset | Scriptable, Phase 9's eventual shape; three steps to trust | |
| Whole-fence ZFS rollback for both criteria | Simplest and complete; undoes all twelve to back out one | |

**User's choice:** flask's `UNDO IMPORT`, `state.pickle` proven.

| Option | Description | Selected |
|--------|-------------|----------|
| The gated first album, right after it passes *(recommended)* | Undo proven with one album at risk; "a good state" is verifiable | ✓ |
| Whichever album actually shows a problem | Most faithful; may never occur | |
| Deliberately regress one album | Exercises "treated as regressed"; writes bad tags during the `rw` phase | |

**User's choice:** The gated first album, right after it passes.

| Option | Description | Selected |
|--------|-------------|----------|
| Both datasets snapshotted, arrs restored by file only *(recommended)* | `tank/media/Music` + `fast/appdata/arrs` in one remote step; `zfs rollback` on arrs prohibited | ✓ |
| Music snapshot + file copies into the safety fence | Avoids the shared dataset; "taken together" becomes a discipline | |
| Both snapshotted, plus file copies | Two recovery routes; two routes to the same state diverge | |

**User's choice:** Both datasets snapshotted, arrs restored by file only.
**Notes:** `fast/appdata/arrs` was measured on atlantis as a real dataset during the question —
the memory note claiming `/mnt/fast/appdata` is not a mountpoint is LXC 100's view, not the disk's.

| Option | Description | Selected |
|--------|-------------|----------|
| 45-01 mechanical, pre-phase5 gated *(recommended)* | Honours the operator's own "no judgement left in it"; E4's release stays estate-wide | ✓ |
| Both mechanical | Consistent; forecloses an estate-wide recovery option unattended | |
| Both gated | 06-52 precedent; re-inserts the judgement the rewrite removed | |

**User's choice:** 45-01 mechanical, pre-phase5 gated.

| Option | Description | Selected |
|--------|-------------|----------|
| Fence holds, resumable, nothing auto-rolls *(recommended)* | A written STOP state names which albums landed | ✓ |
| Auto-roll back on abandonment | Always a known state; destroys work on a timer | |
| Complete-or-roll-back, no middle state | Phase 9's discipline; binds a lot to one sitting | |

**User's choice:** Fence holds, resumable, nothing auto-rolls.

| Option | Description | Selected |
|--------|-------------|----------|
| Inventory with owner and release condition, destroy none *(recommended)* | Read-only register; `DEF-06-52-02`'s lesson that silence reads as absence | |
| Leave them entirely | Out of scope; snapshots are near-free | |
| Inventory and prune the superseded ones | Same register plus destruction of superseded snapshots | ✓ |

**User's choice:** Inventory and prune the superseded ones.
**Notes:** Third overrule toward the wider action. Because pruning is destructive, a follow-up
question made the supersession rule mechanical rather than a judgement.

| Option | Description | Selected |
|--------|-------------|----------|
| Named successor + operator gate per snapshot *(recommended)* | Strictly newer same-dataset successor NAMED as covering the same undo; `autonomous: false` gate | ✓ |
| Age plus a newer same-dataset snapshot | Fully deterministic; age does not track what a snapshot undoes | |
| Only prune ones with zero recorded owner | Conservative; an unattributed snapshot may be an unwritten record | |

**User's choice:** Named successor + operator gate per snapshot.

---

## Execution path + the rw grant (E3/E11)

| Option | Description | Selected |
|--------|-------------|----------|
| `02-review` preview, confirm each *(recommended)* | The front end Phase 3 chose; pairs with `UNDO IMPORT` | ✓ |
| `docker exec beet import`, scripted | Auditable, Phase 9's shape; proves a path the operator will not use | |
| `01-auto`, unattended | Closest to Phase 8; the E11 hazard exercised during the `rw` phase | |

**User's choice:** `02-review` preview, confirm each.

| Option | Description | Selected |
|--------|-------------|----------|
| De-register it for the phase, re-register in Phase 8 *(recommended)* | Structural absence rather than an argument about what bounds it | ✓ |
| Keep it registered, set `import.write` deliberately | Closer to Phase 8's shape; unprompted path stays live | |
| Keep it registered, flip `autotag` off | Smaller change; moves the config sha256 (`DEF-06-21-01`) | |

**User's choice:** De-register it for the phase, re-register in Phase 8.

| Option | Description | Selected |
|--------|-------------|----------|
| One commit, old digest preserved beside the new *(recommended)* | All four changes plus a re-baseline that keeps Phase 6's proofs attributable | ✓ |
| Two commits — config first, then the mount | Strongest audit trail on the `rw` line; leaves an undescribed intermediate state | |
| Mount first, config second | Most literal reading of "first act"; widest open window in the phase | |

**User's choice:** One commit, old digest preserved beside the new.
**Notes:** Established during the question that `import.write` is **forced, not chosen** —
criterion 3 requires `ffprobe` showing new tags on the file, impossible with `write: no`.

| Option | Description | Selected |
|--------|-------------|----------|
| Stays `rw`, with a standing assertion *(recommended)* | Phases 8 and 9 both need it; assertion names the owning phase | ✓ |
| Revoke at phase end, re-grant per phase | Keeps `:ro` the default; a skipped revoke looks like an intended grant | |
| Revoke only if the pilot fails | Grant earned by evidence; couples a mount setting to a verdict | |

**User's choice:** Stays `rw`, with a standing assertion.
**Notes:** Accepted consequence recorded in CONTEXT.md — D-05's argument was that `:ro` *cannot
fail open*, and a standing assertion is a policy-enforced rule rather than a mechanism-enforced one.

---

## Remaining entry criteria

| Option | Description | Selected |
|--------|-------------|----------|
| Repair Def Leppard, measure the 30 *(recommended)* | Tests `DEF-06-45-03`'s E5-not-E6 hypothesis for one API call | ✓ |
| Repair Def Leppard only | Keeps the phase focused; leaves E6's explanation untested | |
| Defer both to after the pilot | D-19a scheduled the repair here; deferring twice is how it became permanent | |

**User's choice:** Repair Def Leppard, measure the 30.

**Finding:** criterion 7's detection sweep does not exist — the only repository hits for
`mb_albumid` / `tracktotal` are three Phase 5 scripts.

| Option | Description | Selected |
|--------|-------------|----------|
| Standing script, folded into `quick-health-check.sh` *(recommended)* | Phase 9 criterion 2 runs it after every batch | ✓ |
| Phase-local script, promote later | Keeps `quick-health-check.sh` from growing; promotion acquires no owner | |
| One-off assertions inside the plan | Minimal surface; cannot be driven against a control | |

**User's choice:** Standing script, folded into `quick-health-check.sh`.

**Multi-select — E2 and E10:**

| Option | Description | Selected |
|--------|-------------|----------|
| E2: leave `03-asis` unused, gate stays untested | Records honestly rather than manufacturing a staging | ✓ |
| E2: assert the gate refuses, read-only | Turns an untested gate into a tested predicate | ✓ |
| E10: every new `beet` invocation compliant or registered | Pinned count moving is a red by design | ✓ |
| E10: drive the undriven overlay-key half | `DEF-06-21-06`; the pilot supplies natural material | ✓ |

**User's choice:** All four. The two E2 options are compatible — the `bootleg` path stays unused
while its precondition is asserted read-only.

**Multi-select — E8, E9 and E12:**

| Option | Description | Selected |
|--------|-------------|----------|
| E8: verify every `%aunique{}` firing in Music Assistant | The Benson Boone pair is a predicted firing | ✓ |
| E9: assert match order, record `search_limit` rank per folder | Track count alone is insufficient (`Vol 002`) | ✓ |
| E12: confirm the four hardenings on the first real `--run` | Including the fence under the container's `dash` | ✓ |
| E12 rider: record `wc -c` of `arm1.dump` | `DEF-06-29-04`; the margin GC-01 was measured against | ✓ |

**User's choice:** All four.

---

## Closure

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence map up front + operator trust verdict *(recommended)* | Map committed before the run; `/gsd-verify 07` scores once; a separate recorded trust verdict | ✓ |
| Evidence map + `/gsd-verify` only | Purely mechanical; eight criteria can read TRUE on a flow nobody trusts | |
| Phase 6's round model | Surfaces real defects; 52 plans and six rounds and still not closed | |

**User's choice:** Evidence map up front + operator trust verdict.
**Notes:** The roadmap states the deliverable is trust, not a count — this makes that a written
artifact rather than an implication.

---

## Claude's Discretion

- The seed and exact derivation script for the four fresh draws, following `06-SAMPLE.md`'s
  `LC_ALL=C` mechanism.
- The precise `jq` shape of the AMBIGUOUS classification in `diff-music-tags.sh`, and where the new
  exit state sits in its existing 0/1/2 contract.
- Which Jellyfin and Music Assistant API endpoints serve the E5 and E8 readings.
- The exact `docker exec` invocation shape for the DJ routing and the rule-2 class assertion.
- Whether the snapshot register lives in `artifacts/` or as a committed top-level record.

## Deferred Ideas

- The 1.3 T `mybook-music-archive` phase, inserted between 8 and 9 — capture plus dedupe.
  **Enacting it in `ROADMAP.md` is `/gsd-phase` work, deliberately not done by the context commit.**
- DUPE-01 / DUPE-02, folded into that same phase and moved out of *Beyond This Milestone*.
- `CLAUDE.md`'s stale 144-folder denominator (carried twice) and ~46-DJ-release baseline, against
  the measured 450.
- Bucket B — the *Now!* series; S4 dropped from the sample.
- E2's first real `bootleg` exercise; DJ path rule 2 exercised by a real import.
- BPM / key / energy generation for the ~616 untagged `dj-mixes` files.
- `mac-music-archive/`'s 23,874 uncharacterised entries — also lacking a QUAL-01 before-state.
- The per-file `LOCATION=…/release/NNNNNN` Discogs id as a bulk disambiguation shortcut.
- beets-flask's folder-count lag past ~100 folders.
- Three live un-rotated secrets on LXC 100 (`DEF-06-29-09`) — not this phase's, must not be lost.
- 23 lines / 24 pipelines of the `| grep -q`-under-`pipefail` shape estate-wide, five inverted.
