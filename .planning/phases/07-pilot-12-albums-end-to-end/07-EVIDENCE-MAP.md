# Phase 7 EVIDENCE MAP — registered before the run (D-31)

**Authored against base commit:** `60039c7589fb0e188d380848b40697ea50da20b2` (HEAD when plan 07-01
began, 2026-09-25T22:39Z).

**This file is an INPUT, not an output.** It is committed before `tank/media/Music@pre-07-pilot`
exists and before any Phase 7 write to the library, and its only value is the commit that predates
the first import. It sits at the phase root rather than under `artifacts/` for the same reason
`06-EXPECTED-TREE.txt` gives in its header: every committed file under `artifacts/` is an output
recorded after the run that produced it, and filing the statement of *what would close this*
beside the evidence it judges would blur the one distinction that makes the evidence non-vacuous.

**Column contract.** Later plans FILL the `measured` column (plan 07-17 assembles it). They never
edit the `instrument` or `satisfied-for-scoring when` columns. A change to either is a **finding**,
recorded in `.planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md` with its reason —
not an edit to this file. Plan 07-09's gate asserts this file's commit is an ancestor of HEAD
before the fence and the grant (T-07-01-01).

**Vocabulary.** "SATISFIED-FOR-SCORING" means the artifact contains what `/gsd-verify 07` needs to
score the criterion — it is not a verdict, and no plan in this phase writes one (§ Closure
protocol). "UNKNOWN" means *could not look*, kept distinct from *nothing is wrong*
(CONVENTIONS.md convention 1). Counted tokens are written bracketed (CONVENTIONS.md convention 8).

## The eight criteria

| # — criterion (one line) | Owning plan(s) | Artifact path | Instrument (exact) | Reads as SATISFIED-FOR-SCORING when | Reads as UNKNOWN when | Measured |
|---|---|---|---|---|---|---|
| **1** — twelve bucket-A albums imported inside a snapshot fence (Music dataset + `library.db` together), rollback exercised at least once | 07-09, 07-11 | `artifacts/07-09-fence-and-grant.txt`, `artifacts/07-11-p01-undo-rerun.txt` | **Fence:** `zfs list -t snapshot -H -o name` with an exact whole-line match (`grep -qxF`) for BOTH `tank/media/Music@pre-07-pilot` and `fast/appdata/arrs@pre-07-pilot`, plus a sha256'd file copy of `library.db` and `state.pickle` under `/mnt/fast/safety/phase07/fence/`. **Rollback exercised:** D-15's back-out of the gated first album (P01) through beets-flask rc6 `UNDO IMPORT` (D-14), witnessed by a PAIRED reading per part (G-02, P7R2-06) — each part's P01 entry PRESENT before the undo and ABSENT after it, on the key that was actually written, as plan 07-11 records it (`PRE-UNDO WITNESS` → `UNDO WITNESS`, lines `<PART> COVERED yes (pre n → post 0)`): **tree** — P01 destination file count n ≥ 1 → 0; **database** — read-only sqlite P01 item count n ≥ 1 → 0; **state** — the `P01 STATE KEY(S)`, i.e. the set difference, per top-level key, of the decoded post-import `state.pickle` minus the decoded fence safety copy `/mnt/fast/safety/phase07/fence/state.pickle`, each entry present before and absent after. | Both snapshot names match exactly, both safety copies exist with recorded sha256, AND all three parts read `COVERED yes (pre n → post 0)` with n ≥ 1. A part whose pre-undo reading was already absent is `VACUOUS` and **never** satisfies the row — an absence-only reading is not a witness. **Registered mapping, stated before the run:** the roadmap text says "rollback"; D-14 chose `UNDO IMPORT` as the mechanism; this map registers that criterion 1's "rollback exercised" is offered as discharged by that back-out, and that NO `zfs [r]ollback` of `tank/media/Music` is planned. `/gsd-verify 07` accepts or rejects that mapping; no plan decides it. | Either snapshot name is absent or the listing could not be read; a safety copy is missing or unhashed; any part reads `VACUOUS` or its pre/post reading could not be taken; the `P01 STATE KEY(S)` set difference is empty (nothing to witness) or the pickle could not be decoded. |  |
| **2** — the hard shapes (≥1 various-artist compilation, ≥1 multi-disc release) are named in the plan before the run | 07-06 | `07-SAMPLE.md` | `git merge-base --is-ancestor <commit that added 07-SAMPLE.md> <commit that added artifacts/07-10-p01-import.txt>` exits 0, and `07-SAMPLE.md` names S3 (compilation) and S2 (multi-disc) by folder path. | The ancestry test exits 0 AND both S3 and S2 are named by folder path in `07-SAMPLE.md`. | Either commit cannot be resolved (`git log --diff-filter=A` returns nothing for the path), or the ancestry test exits other than 0/1. |  |
| **3** — every imported file passes `ffprobe` showing the new tags on the file itself, and ownership matches `568:568` | 07-10, 07-12, 07-13, 07-17 | `artifacts/07-17-evidence.txt` § criterion 3 | `ffprobe -show_format -show_streams` on every imported file, compared field by field against beets' own row for that item read through read-only sqlite (`file:/config/library.db?mode=ro`) for `title`, `artist`, `album`, `albumartist`, `track`, `disc`, and `mb_albumid` where matched; plus `stat -c '%u:%g'` read FROM ATLANTIS as real root equals `568:568`. **`beet ls` is NOT acceptable evidence** — beets logs a tag-write `EPERM` as a warning and continues, so the database can read perfectly while the file keeps its old tags. | Every imported file probed (probed count = beets item count for the pilot albums, non-zero), zero field mismatches, every file `568:568` as read from atlantis. | `ffprobe` fails on any file, the probed count differs from the item count or is zero, the sqlite read fails, or ownership was read from LXC 100 (whose sparse idmap collapses unmapped ids to `65534`) rather than from atlantis. |  |
| **4** — QUAL-02: a field-level before/after diff for every pilot file shows no net metadata loss | 07-02, 07-07, 07-10, 07-12, 07-13, 07-17 | `artifacts/07-17-evidence.txt` § criterion 4 | `scripts/diff-music-tags.sh`, carrying plan 07-02's AMBIGUOUS arm, over the `pre-07-pilot` BEFORE capture (plan 07-07) and the `post-07-pilot` AFTER capture. **BEFORE of record = `pre-07-pilot`, not Phase 1's `pre-project`.** Reason: `pre-project` (2026-08-18) predates the `music/` tree's growth (277 files then, 531 at the 06-SAMPLE live pass) and Phase 5's 751 in-place tag writes, so it is not the state these files arrive in; `pre-07-pilot` is taken immediately before import. `pre-project` coverage of the pilot files is recorded as the cross-check. | Exit 0; `AMBIGUOUS_BEFORE` and `AMBIGUOUS_AFTER` both 0; the zero-BEFORE-fields counter read and stated; every dropped field listed with a recorded reason (fields gained listed). | Exit 3 (an ambiguous join on either side, or either capture unreadable). Exit 1 is a measured loss — not UNKNOWN — and means the import is rejected and re-run. |  |
| **5** — QUAL-04: undo demonstrated, not assumed — one album backed out and re-run to a good state with no hand-repair, covering tree AND `incremental` state | 07-11 | `artifacts/07-11-p01-undo-rerun.txt` | The three-part PAIRED witness registered in row 1 (tree / database / `P01 STATE KEY(S)`, `PRE-UNDO WITNESS` → `UNDO WITNESS`), then the re-run's destination path list and `audio_md5` set compared byte for byte with the first run's. | All three parts `COVERED yes (pre n → post 0)` with n ≥ 1, AND the re-run's path list and `audio_md5` set are identical to the first run's, AND no hand-repair step appears in the transcript. | Any part `VACUOUS` or unreadable; either run's path list or `audio_md5` set could not be captured. |  |
| **6** — CONS-04: all twelve appear in Jellyfin with the new metadata and in Music Assistant under the correct album artist; the compilation as ONE album under `Various Artists`, the multi-disc as one album with disc numbering intact | 07-10 (Jellyfin half of the gated album), 07-15 | `artifacts/07-15-consumers.txt` | Jellyfin `/Items` per album (one `MusicAlbum`, `AlbumArtist`, child count, disc numbers), then Music Assistant API per album (album present once, album artist, track count, disc numbers). Order carried from Phase 6 D-25: **Jellyfin FIRST, Music Assistant LAST**. ⛔ `Full[R]efresh` forbidden. | Twelve of twelve albums read correctly in both consumers; the compilation is one album under `Various Artists`; the multi-disc release is one album with its disc numbers intact. | Either API is unreachable or unauthenticated, or a per-album selector demonstrably cannot miss (no planted-absent control driven). |  |
| **7** — the post-import detection sweep runs and reports nothing, or its findings are resolved (`.1` collisions, empty `mb_albumid`, track count vs `tracktotal`) | 07-03, 07-17 | `artifacts/07-17-evidence.txt` § criterion 7 | `scripts/check-music-import.sh`, exit 0, with its self-test controls driven red first; findings, if any, listed with their resolution. | Controls observed red, then exit 0 over the pilot; or findings listed each with a resolution and a clean re-run. | Exit 3, or the controls were not driven red first (a green never observed failing is not evidence). |  |
| **8** — the source folders still exist afterwards (copy, not move) | 07-07, 07-17 | `artifacts/07-07-source-manifest-before.tsv` and the after manifest in `artifacts/07-17-evidence.txt` | Per-file `sha256` + size manifest of every source folder, read from atlantis, before and after. | The before and after manifests are identical and non-empty, one row per source file. | Either manifest is empty, could not be read, or was read from somewhere other than atlantis. |  |

## Entry criteria E1 … E12 — owner and handling

| Entry criterion | Owner(s) | Handling |
|---|---|---|
| E1 — DJ-routing mechanism does not exist; DJ path rule 2 unevaluated | 07-04 + 07-13 (D-08); 07-05 (D-09 rule 2) | D-08: post-import `beet modify albumtype=dj` then `beet move`, built by 07-04 and exercised on the DJ pair by 07-13. D-09: rule 2 gets a named read-only class assertion in 07-05, no import. |
| E2 — never route to `bootleg` without the album-populated predicate | 07-06 | D-26 predicate asserted read-only over the draw; `03-asis` stays unused. The import exercise of the gate is carried forward, not done here. |
| E3 — the `rw` grant is Phase 7's FIRST act, fence already in place | 07-09 | Two-dataset fence first, then the grant, in the gated plan. |
| E4 — `tank/downloads@pre-phase5` not released until the pilot passes | NOT released by this phase (D-17) | Listed by 07-16's snapshot register only. |
| E5 — repair `Def Leppard/Def Leppard (2015)/`; measure the 30-item entity gap | 07-14 (+ 07-07 / 07-15 readings, D-24) | Named repair operation; the entity gap measured before (07-07) and after (07-15). |
| E6 — CONF-04 Jellyfin half open; two measurements | First measurement (Jellyfin re-probe → 4/2/2): 07-15, new-import reading. Second measurement (≥4-artist track in MA → 4 or 3): 07-06 (D-05 stratum) + 07-15 | **Each dispositioned separately and never summed.** The mtime route is not retried (`DEF-06-45-02`). The `REQUIREMENTS.md` `- [ ] **CONF-04**` box stays unticked by every plan in this phase. |
| E7 — DUPE-01/02 roadmap decision; last-wins join | 07-02 (D-11 / D-12) + 07-01 (D-13) | 07-02 makes the join fail closed on AMBIGUOUS, both sides, driven on fixtures and real data; 07-01 amends the ROADMAP `unsorted` row in band, conditional on that arm. |
| E8 — every `%aunique{}` firing is an MA risk | 07-15 (D-28) | Verified directly in Music Assistant, never inferred from `config/providers/get`. |
| E9 — match-check order; `search_limit` rank | 07-10, 07-12, 07-13 (D-29) | Gate on `recommendation` → track count → per-track distance; rank of the accepted candidate recorded per folder. |
| E10 — D-04 exemption register pinned baseline | 07-04 (D-27) | Every new `beet` invocation compliant or registered with its reason; the overlay-key half driven. The pin is never raised to make a run green. |
| E11 — decide `import.write` with the `rw` grant | 07-08 (D-21 / D-22) | The ONE D-22 commit; `01-auto` de-registered for the phase. |
| E12 — four round-2 hardenings never run for real; `arm1.dump` unsized | 07-05 (D-30) | First real oracle `--run` before the grant; `wc -c` of `arm1.dump` recorded. |

## Coupling index C1 … C11

Couplings are those in `07-PATTERNS.md` § "Couplings the CONTEXT file list does not name".

| Coupling | Subject (short) | Owning plan(s) |
|---|---|---|
| C1 | `import.move` already `no` / `copy: yes` in the vendored config | 07-08 / 07-09 |
| C2 | `01-auto` registration lives in `flask-config.yaml`, not `flask.yaml` | 07-08 |
| C3 | `gui.library.readonly: true` in `flask-config.yaml` | 07-08 |
| C4 | flask readiness gate: fewer than three inboxes is RED | 07-08 / 07-09 |
| C5 | `quick-health-check.sh` D-03 block asserts `/media` RW=false on both containers | 07-08 |
| C6 | `check-music-freeze.sh` mount census fails a tagger-capable rw holder on Music | 07-08 |
| C7 | `phase06-oracle.sh --run` step 2 asserts `/media` RW=false | 07-05 (sequenced before the grant) + 07-08 (disposition recorded) |
| C8 | `phase06-oracle.sh --run` asserts `library.db` sha == `FIXTURE_LIB_SHA256` | 07-05 (sequenced before the grant) + 07-08 (disposition recorded) |
| C9 | vendored-drift block compares repo ↔ appdata for both configs | 07-09 |
| C10 | vendored config digest already moved once since the 06-04 proof | 07-08 |
| C11 | `fast` and `tank` are different pools — one remote step, not one atomic snapshot | 07-09 |

## Closure protocol (D-31)

1. **`/gsd-verify 07` scores the eight criteria ONCE**, at the end of the phase, against the rows
   above. No plan writes a verification verdict, ticks a `REQUIREMENTS.md` box, or re-scores
   anything. Plan 07-17 assembles evidence; it does not judge it.
2. **The operator records a separate trust verdict** in `07-TRUST-VERDICT.md` (plan 07-17) on the
   question the criteria cannot score: *do you believe this flow?* The deliverable is trust, not a
   count, and this makes it a written artifact rather than an implication.
3. **ONE code review of this phase's own changes is budgeted** — offered at plan 07-09's gate,
   before the grant, where a finding is cheapest; otherwise run once after execution. Not six
   rounds: Phase 6's recursion is explicitly not adopted. The lesson kept is that verification
   (were the must-haves met?) and review (is the code that meets them correct?) are separate acts.

## Out of scope

- **D-01 — `tank/downloads/mybook-music-archive`.** Mechanical reason: it has no QUAL-01
  before-state. `scripts/snapshot-music-tags.sh` pins four capture roots by name (`unsorted`,
  `dj-mixes`, `complete/nzb/music`, `media/Music`) and the archive is none of them, so criterion 4
  is uncomputable for any album drawn from it.
- **D-02 / D-03 — the inserted archive phase (between Phase 8 and Phase 9) and folding DUPE-01/02
  into it.** Decided, but **enacting either in `ROADMAP.md` is `/gsd-phase` work and is NOT done by
  this phase's plans.** Plan 07-01's D-13 edit touches only the in-band text of the existing DUPE
  row.
- **S4 / bucket B** (the *Now!* series) — dropped from the sample (D-04).
- **Any bulk import** — Phase 9 owns throughput.
- **E6's mtime re-probe route** — measured dead for this estate at Jellyfin 10.11.11
  (`DEF-06-45-02`). ⛔ Do not retry.
