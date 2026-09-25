---
phase: 7
reviewers: [pi/gpt-6-astra, pi/gemini-3.8-flash, pi/kimi-k3, pi/grok-4.7, pi/deepseek-v4-pro, copilot/gpt-5.5]
reviewed_at: 2026-09-25T17:10:00Z
plans_reviewed: [07-01-PLAN.md, 07-02-PLAN.md, 07-03-PLAN.md, 07-04-PLAN.md, 07-05-PLAN.md, 07-06-PLAN.md, 07-07-PLAN.md, 07-08-PLAN.md, 07-09-PLAN.md, 07-10-PLAN.md, 07-11-PLAN.md, 07-12-PLAN.md, 07-13-PLAN.md, 07-14-PLAN.md, 07-15-PLAN.md, 07-16-PLAN.md, 07-17-PLAN.md]
---

# Cross-AI Plan Review — Phase 7 (round 1)

Six reviewers from five model families (OpenAI ×2, Google, Moonshot, xAI, DeepSeek). The same
489 KB prompt went to all six: the instructions, the phase's twelve safety invariants, the named
failure modes, a do-not-re-litigate list, PROJECT (80 lines), the roadmap section, the six
requirements, CONVENTIONS.md, 07-CONTEXT.md, 07-PATTERNS.md and all 17 plans. Each reviewer had to
give a refutation condition for every finding and a "checked and held" section. The plan-checker's
0/4/1 was given to them to extend, not repeat.

**Every finding below was graded against the plan text, and where possible against the live repo
or estate.** Read the Graded Findings section first. The raw reviews follow it unedited, apart
from Copilot's tool-call preamble, which was stripped.

## Graded Findings (orchestrator, 2026-09-25)

### CONFIRMED — act on these

| # | Sev | Plan | Finding | Raised by | Evidence |
|---|-----|------|---------|-----------|----------|
| G-01 | **HIGH** | 07-11 T3 | D-17's FIRED condition accepts "state covered … **or by the operator-chosen file restore**", so the mechanical `zfs destroy …@pre-06-41-conf04-reprobe` fires on the branch where the plan has just recorded "D-14 stands falsified". D-15's ratification names an `UNDO IMPORT` back-out covering all three parts, not a restore. | deepseek, copilot, astra, grok, kimi (**5 of 6**) | 07-11:219-222 |
| G-02 | **HIGH** | 07-11 T1→T2→T3 | The state witness can be vacuous. T1 accepts the pre-undo `taghistory` entry being ABSENT ("the undo question is moot"), and T2 scores `STATE COVERED yes` on post-undo absence alone. Tree and DB have the same shape ("expected 0"). **The trigger does not wait on re-run equality**: FIRED is conditions (i)+(ii) only. So if `taghistory` is keyed differently from the staged path, D-17 destroys the snapshot even though the re-run is later skipped by `incremental`. | gemini, astra, grok (kimi *cleared* it — **refuted**, see below) | 07-11:90-94, 148-150, 219-222 |
| G-03 | MED | 07-03 T1 | Vacuity gap: a library where every item is a singleton leaves classes 2 and 3 with zero checkable rows, and neither vacuity arm fires (`items == 0`; album groups > 0 with zero checkable class-3 groups), so it exits 0. No self-test case covers this. The pilot never hits it, but Phase 9 batches can. Also, class 1 is DB-driven: an orphaned `Title.1.flac` with no item row is never enumerated. | kimi, astra (rated HIGH → MED) | 07-03:94-97, 121-132 |
| G-04 | MED | 07-11 T2, 07-09 T2 | No writer-quiescence barrier. `restore-then-rerun` copies `state.pickle` over the live file while beets-flask runs: no container stop and no re-decode after restart. 07-09 checks the snapshot's own view of `library.db` by `ls -l` only, not by sha256 against the safety copy. | astra (HIGH → MED), grok F5 + F11 | 07-11:199-203; 07-09:195-201 |
| G-05 | MED | 07-09 T2 | The post-grant `import.copy/move/write` readings are **recorded, not gated**. Nothing STOPs if the effective `move` is true, and inbox emptiness is not re-counted at `compose up`. | grok F6 | 07-09:216-217 |
| G-06 | MED | 07-09 T2 | Partial fence: `tank` and `fast` are separate pools. If the first snapshot succeeds and the second fails, a re-run hits "refuse if either exists", and there is no branch to recover. This fails closed but breaks D-18 resumability. | copilot | 07-09:188, 268 |
| G-07 | MED | 07-15 T3 | The D-28 `%aunique{}` inventory is taken from `07-12-nine-imports.txt`, before 07-13 imports and routes the DJ pair (whose path rule also carries `%aunique{}`). `AUNIQUE_ROWS` is built from that stale list. | astra | 07-15:156, 172, 188 |
| G-08 | MED | 07-11 T3 → 07-12 | 07-12's precondition is "ledger shows P01 LANDED (re-run)". 07-11 writes "LANDED (re-run) **with the equality verdict**", and nothing requires that verdict to be a pass before 07-12 stages more albums. | astra | 07-11:237; 07-12:15, 78 |
| G-09 | MED | 07-11 | Hold semantics: a Task 1 `hold` (P01 landed) and the Task 3 `hold` text ("P01 backed out, nothing landed") collide, and no resume entry reconciles the ledger with the snapshots and state. | astra | 07-11:196-197 |
| G-10 | LOW | 07-12/13 (+14/15) verify | A legitimate hold can fail the automated verify. In 07-12, per-P-ID `hold` lines are neither `hold-all` nor `LANDED`. In 07-13, `OPERATOR ANSWER:? *hold *$` is end-anchored, while the acceptance criteria require "verbatim with UTC time". This fails closed, but it pressures the executor to invent a pass. | grok F7, kimi F5 | 07-12:136 vs 185; 07-13:183 |
| G-11 | LOW | 07-15 T3 | The ≥4-artist stratum is consumed as "K of 4" and "target 4". A drawn 5-artist track would under-report. | astra | 07-06:114-115; 07-15:180, 185 |
| G-12 | LOW | 07-06 / 07-12 | 07-06 says "Plans 07-12 and 07-13 import in this order" (P07/P08 before P09–P12), but 07-12 imports P09–P12 first. Separately, the P02-before-P04 order is never asserted after the fact (`added`). | astra, kimi F4 | 07-06:127-129; 07-12:15 |
| G-13 | LOW | 07-17 T2 | The live D-06 draw population is written "beside the 144" as though it were the same denominator. It isn't: that launders a number into a different population. | grok F9 | 07-17:154 |
| G-14 | LOW | 07-01 T2, 07-11 T3 verify | Weak git-diff greps. 07-01 counts removed lines only (`^-[^-]` = 1), never added lines. 07-11's `git diff HEAD~1 … \| grep -qE '^\+'` also matches the `+++` header. | grok F10, deepseek F3 | 07-01:234; 07-11:241 |
| G-15 | LOW | 07-10/12/13/14 verify | `grep -cE 'FullRefresh\|zfs rollback' "$A"` is unbracketed, so any artifact prose quoting the ban reads as a violation. That is a false **red** only, never a false pass. (Gemini's sub-claim that 07-09's `zfs [r]ollback` regex matches *bracketed* prose is wrong: the regex matches the literal verb.) | gemini F3 | 07-10:226; 07-12:185; 07-13:183; 07-14:163 |

### PLAUSIBLE — ungraded, cheap to settle before execution

| # | Sev | Plan | Finding | Raised by | Status |
|---|-----|------|---------|-----------|--------|
| P-01 | MED (astra: HIGH) | 07-10 onward | MA's *automatic* sync is not barred before the first import. A scheduled sync during the 07-11 undo or 07-13 routing window would plant entries that MA never purges and that the fence does not cover. | astra, grok F8 | **Measured 2026-09-25:** MA 2.11.0b0 exposes **no sync-interval setting**, on either `filesystem_local--XJaJWNUS` or core `music` config. Whether a periodic sync runs anyway is **unmeasured**. Read MA's add-on log for recurring provider-sync lines before 07-10. |
| P-02 | MED (astra: HIGH) | 07-15 T3 | Title-based MA lookup can't tell the FLAC/MP3 Benson Boone twins apart. Two hits are expected, yet the plan calls more than one hit a "duplicate" finding. Identity should come from MA provider mappings and track paths. | astra | Plan text matches the quote; the right MA representation of a twin pair is undecided |
| P-03 | LOW | 07-07 T2 | The D-24 census takes one `/Items` call with no `TotalRecordCount == length` coverage assertion before the baseline is pinned. | kimi F3 | Not driven |
| P-04 | LOW | 07-11 T2 | If `DB COVERED` is `no`, no remedy is offered: `restore-then-rerun` restores `state.pickle` only. | kimi F6 | Text matches |
| P-05 | LOW | 07-07/07-15 | The new `D24_CENSUS_BASELINE_*` pins aren't registered in CONVENTIONS §5. | gemini F5 | Not checked against §5's scope |
| P-06 | LOW | 07-16 T2 | A refusal message that prints `zfs destroy …@pre-phase5` would trip the negative grep. | gemini F4 | Fails closed only |
| P-07 | LOW | 07-13/14 | `depends_on` omits direct producers 07-06 and 07-07. They are reached only transitively. | deepseek F4 | Cosmetic under the current waves |

### REFUTED — do not act on these

| Finding | Raised by | Why refuted |
|---------|-----------|-------------|
| **HIGH** — `grant-both` re-opens the ratified flask-only grant | copilot | Its own refutation condition is met: 07-CONTEXT.md:316 (the D-22 ratification) says *"07-09's gate keeps a `grant-both` override, but flask-only is the decided default."* |
| **HIGH** — 07-04's `$BEET_REALLIB` writer is invisible to `D04_INV_RE`, so N=0 and the register stays green | grok F3 | **Driven:** the live `D04_INV_RE` (`scripts/quick-health-check.sh:2062`) has a `\$\{?BEET[A-Z_]*\}?` alternative and **matches** both `docker exec beets-flask "$BEET_REALLIB" modify …` and `… move …`. The positive control `docker exec x beet ls` matched and the negative control didn't. Residual (LOW): 07-04 has no explicit STOP if N = 0. |
| MED — stray `<` at the end of 07-11 T3's `<automated>` is a bash syntax error | gemini F2 | It is the `</automated>` closing tag (07-11:241). |
| MED — 07-16's `written@ = 0` doesn't see chown-only changes | deepseek F2 | On ZFS semantics a chown dirties the dnode, so `written` > 0. kimi cleared it independently. Not driven: that would need snapshots on a live pool. At most LOW ("drive it if it's free"). |
| MED — 07-05's write-block assert is a substring match | grok F4 | 07-05:191-194 prints the **effective** config and says "STOP if any differs". At most LOW (specify comparison by parsed value). |
| kimi's **clear** of the 07-11 state witness ("a skipped re-run shows 0 items") | kimi | D-17's FIRED condition does not include re-run equality (07-11:219-222), so the downstream failure doesn't stop the destroy. |

### What the grading says about the roster

- **Convergence:** G-01 was found by 5 of 6 reviewers. Gemini missed it. It is the clearest defect in the set, and the fix is one sentence.
- **Kimi raised no HIGH and was right about everything but one clear.** That clear (G-02) was the most consequential miss of the round. Three other reviewers found it from different directions.
- **Both refuted HIGHs came from reviewers whose other findings were good** (Copilot, Grok). Grok's was settled only by *driving* the regex, not by reading it.
- **Astra (gpt-6-astra) produced the most confirmed cross-plan seams**: G-07, G-08, G-09 and G-11. Several of its HIGHs were over-rated and have been reclassified to MED.


---

## Review: pi → github-copilot / gpt-6-astra

### 1. Summary

**Overall risk: HIGH.** The plans have strong foundations: commit-anchored evidence, copy-only staging, file-level tag verification, explicit snapshot names, and tightly scoped destructive commands. The main weaknesses are at the transitions between those controls. A recorded import can unlock subsequent writes without having passed its checks; Music Assistant’s background synchronization is not stopped; and the mechanical snapshot-release trigger accepts a recovery branch that falsifies the registered undo claim. There are also state-consistency risks around copying live beets state and false-clean possibilities in the collision sweep and consumer lookup. These findings concern execution safety and evidence validity, not the operator’s ratified choice of `UNDO IMPORT`, flask-only `rw`, or one final verification round.

### 2. Findings

### 1. P7XR-01 — HIGH — “LANDED” substitutes for passing the first-album gate

**Plans/tasks:** 07-11 Task 3 → 07-12 Task 1; the same problem reaches 07-15 Tasks 1–2.

**Literal text:**

> “Ledger: P01 LANDED (re-run) with the equality verdict, or the STOP state.”

> “Preconditions: ledger shows P01 LANDED (re-run); both pre-07-pilot snapshots present;”

07-15’s sync gate requires:

> “Confirm from the ledger that no further write is planned in this phase (E5 done, DJ routing done, undo cycle done).”

**Failure scenario:** P01’s first and second imports both produce a QUAL-02 exit 3 or the same unexplained metadata loss. Their paths, audio hashes and diff outputs can nevertheless be identical. The re-run gets recorded as `LANDED`, satisfying 07-12’s stated precondition. Later, 07-15 can authorize MA synchronization because writes are finished, even if the sweep remains red or Jellyfin’s measured values are wrong.

07-10 does route findings to 07-11 for adjudication; the defect is that **07-11 does not produce an explicit successful operational gate that 07-12 consumes**. Recording a finding or reproducing it is not clearing it. Likewise, “Jellyfin read first” is weaker than “Jellyfin proven first.”

**Fix:** Introduce a machine-checkable operational readiness record, separate from formal phase verification. Require it before 07-12 stages anything and again before 07-15 offers `sync`. It must reject UNKNOWN, unresolved losses, file/DB mismatches, unresolved sweep findings and failed Jellyfin assertions. Deliberate drops need an explicit accepted disposition. Final `/gsd-verify 07` still scores only once.

**Refutation condition:** This finding is wrong if 07-11 requires these checks to clear before emitting the state consumed by 07-12, and 07-15 explicitly refuses synchronization while any applicable safety/quality gate is unresolved.

---

### 2. P7XR-02 — HIGH — Deferring manual MA synchronization does not prevent automatic synchronization

**Plan/task:** 07-15 Task 2, with the missing prerequisite belonging before 07-10’s first import.

**Literal text:**

> “whether any pilot album is already visible in MA (MA may have a scheduled sync — if so, record which, since that is an unplanned earlier sync).”

**Failure scenario:** MA’s scheduled filesystem sync runs after P01 lands but before its undo, or during a DJ album’s temporary artist-tree placement. MA records content that is subsequently removed or moved. Discovering this in 07-15 is too late: the plans themselves establish that MA never purges stale entries and its database is outside the fence.

Across the supplied plans, avoiding explicit MA write commands is the control; there is no pre-import barrier that disables automatic synchronization and waits for an already-running sync to finish.

**Fix:** Before the first library mutation, measure the provider’s automatic-sync behavior, suspend its synchronization through a supported mechanism, and assert that no sync is running. Preserve that barrier across holds and resumes. Release it only after the final readiness gate in 07-15. Record the previous configuration for restoration.

**Refutation condition:** This finding is wrong if a mandatory pre-write task or instrument explicitly establishes and verifies that the MA filesystem provider cannot synchronize automatically or continue an in-flight sync until 07-15.

---

### 3. P7XR-03 — HIGH — D-17’s destruction trigger accepts a failed or unexercised undo

**Plan/task:** 07-11 Task 3, with the non-vacuity issue introduced in Task 1.

**Literal text:**

> “state covered either by UNDO IMPORT (STATE COVERED yes) or by the operator-chosen file restore — i.e. ‘rollback exercised’ on tree, DB and state.”

The resulting action is:

> “`zfs destroy tank/media/Music@pre-06-41-conf04-reprobe`”

Task 1 also permits the pre-undo history entry to be absent:

> “then `state.pickle` never held the path and the undo question is moot for it, which is itself a finding against the incremental model”

**Failure scenario:** `UNDO IMPORT` misses `state.pickle`; the operator authorizes a file restore to recover the pilot. Task 3 then treats that recovery as sufficient to destroy the held snapshot mechanically. That broadens the pre-registered, ratified discharge—`UNDO IMPORT` covering all three components—without separately amending its release condition.

There is another path: history membership is absent before undo and remains absent afterward. Task 2 can report `STATE COVERED yes` based on absence, although no state transition was exercised. Task 3 does not require the positive pre-undo witness.

**Fix:** Keep recovery authorization distinct from D-17 eligibility. Require a non-vacuous witness: the relevant incremental/import-source state exists before undo and is removed by `UNDO IMPORT`, together with tree and DB reversal. A file-restored or unexercised state arm leaves D-17 unfired under the registered mapping. If a broader trigger is desired, amend that trigger explicitly before relying on it—not by inference in the destroy task.

**Refutation condition:** This finding is wrong if D-17’s registered trigger explicitly authorizes the file-recovery branch and requires a positive pre-undo state witness, or if 07-11 excludes both branches from mechanical release.

---

### 4. P7XR-04 — HIGH — Live-state copies lack a writer-quiescence barrier

**Plans/tasks:** 07-09 Task 2 and its objective; 07-11 Task 3.

**Literal text:**

07-09’s justification says:

> “nothing can write `library.db` in the gap because the mount is still `:ro` and no import is possible.”

Its fence step copies the live files:

> “`/mnt/fast/appdata/arrs/beets/config/library.db` and `state.pickle` into  
> `/mnt/fast/safety/phase07/fence/`”

07-11 restores state using:

> “a single `cp` naming both literal paths; assert both literals before issuing”

**Failure scenario:** `/media:ro` does not make `/config/library.db` or `state.pickle` read-only. The project’s own EPERM warning explains why database progress can occur despite failed file writes. A queued or finishing worker can therefore change beets state between the preflight, snapshots and live-file copies.

The recovery branch is more direct: copying over `state.pickle` while flask/workers remain active can expose a truncated pickle to a reader or have the restored state overwritten by a worker’s cached state. An immediate matching hash does not establish a durable recovery.

**Fix:** Add a beets-only quiescence protocol: stop admission of work, finish or explicitly stop workers, and verify no state writer remains. Take the two snapshots under that barrier and copy the recovery files from the snapshot view, verifying both files. For restoration, keep writers stopped, install the file atomically with preserved ownership/mode, restart, then decode and verify the state actually used by the process. Address SQLite journal/WAL requirements if restoring `library.db`; never roll back the shared arrs dataset.

**Refutation condition:** This finding is wrong if mandatory steps stop and verify all beets state writers across capture/restoration, or the referenced implementation supplies an equivalent demonstrated locking and reload protocol.

---

### 5. P7XR-05 — HIGH — The collision sweep can report clean without inspecting the relevant filesystem state

**Plan/task:** 07-03 Task 1.

**Literal text:**

> “selects from `items` the columns `id, path, album_id, mb_albumid, track, tracktotal, disc, disctotal`”

> “the same directory holds the suffix-stripped name ON DISK (`os.path.exists`, read-only stat)”

> “class 1 = suffix-shaped AND sibling-exists → finding; suffix-shaped without sibling → counted  
> `SUFFIX_NO_SIBLING` (printed with paths, not a failure)”

**Failure scenario:** An interrupted import leaves `Title.1.flac` on disk without a committed item row. With other healthy albums in the DB, the sweep is non-vacuous but never enumerates that file and can exit 0. It therefore misses precisely the partial-import/collision residue criterion 7 needs to find.

Separately, `os.path.exists` can return false when a path cannot be inspected because of permissions. That turns “could not look for the sibling” into the expressly non-failing `SUFFIX_NO_SIBLING` category.

**Fix:** Give class 1 an independent, bounded filesystem census covering the pilot’s affected directories, including unregistered files. Reconcile filesystem and DB path sets. Treat inspection errors as UNKNOWN, not absence. Keep the legitimate `Op.64.flac` case, but do not let sibling nonexistence alone prove that a suffix-shaped path is harmless. Add controls for an orphaned collision file and a failed filesystem inspection.

**Refutation condition:** This finding is wrong if the class-1 implementation is required to enumerate affected filesystem paths independently of DB rows and distinguish inspection failure from confirmed absence.

---

### 6. P7XR-06 — HIGH — Title-based MA lookup cannot prove both members of the deliberate duplicate pair

**Plan/task:** 07-15 Task 3.

**Literal text:**

> “album found once (search  
> by title with the provider filter; record every hit — more than one is a finding: duplicate album),  
> its `album_artist`, track count, and disc numbers on the tracks.”

**Failure scenario:** P02 and P04 are deliberately the same Benson Boone album in FLAC and MP3. If MA indexes only one of them, a title/provider search can return that same single album for both P-IDs. Artist, track count and disc numbers can match both expectations, creating two apparently satisfactory rows from one represented source. Conversely, two legitimate representations may be labelled a duplicate finding merely because the title has two hits.

The provider filter prevents another provider answering; it does not establish which filesystem album answered.

**Fix:** Resolve each P-ID through filesystem-provider item mappings and final file paths, recording stable MA IDs and track-path coverage. Explicitly define the acceptable MA representation of the FLAC/MP3 pair: separate albums or a merged album with demonstrable coverage of both path sets. Do not use title-hit cardinality as the identity predicate.

**Refutation condition:** This finding is wrong if the prescribed lookup verifies each result’s provider mapping and track paths against the particular P-ID, rather than accepting title/provider/count agreement.

---

### 7. P7XR-07 — MEDIUM — The two undo holds produce contradictory STOP states, and resume is not specified

**Plan/tasks:** 07-11 Tasks 1 and 3; related fresh-run preconditions in 07-09 and 07-10.

**Literal text:**

Task 1 offers:

> “Hold — leave P01 landed, stop the pilot here”

Task 3 says:

> “Skip the re-run on `hold` (ledger STOP STATE: P01 backed out, nothing landed; D-17 trigger NOT fired  
> — record why).”

07-09’s fence step says:

> “refuse if either exists”

**Failure scenario:** A hold before undo must retain P01 as landed; a hold after undo must record it as backed out. Task 3’s undifferentiated branch can overwrite the former with the latter. Historical `OPERATOR ANSWER.*hold` greps also do not distinguish gate instances after a resume.

Additionally, a pause after one or both snapshots exist cannot resume by following the fresh-run fence step. Similar zero-item/empty-inbox preconditions apply to 07-10. These generally fail closed, but they do not implement D-18’s promised resumability.

**Fix:** Use explicit gate/run identifiers and distinct states such as `HELD_BEFORE_UNDO`, `UNDONE_AWAITING_RERUN` and `RERUN_VERIFIED`. Add a resume entry that reconciles the ledger with snapshots, tree, DB, incremental state and import-source state before deciding which operation remains. Preserve fail-if-exists for a genuinely new run.

**Refutation condition:** This finding is wrong if Task 1’s hold terminates all later ledger-writing tasks explicitly, and a mandatory resume procedure validates existing state before bypassing fresh-run preconditions.

---

### 8. P7XR-08 — MEDIUM — The execution sequence contradicts the predeclared import order

**Plans/tasks:** 07-06 Task 1; 07-12 Tasks 1–2; 07-13 Tasks 1–3.

**Literal text:**

07-06 declares:

> “P07 = S5 Mastermix.Issue.420.2021; P08 = S5  
> Mastermix.Issue.421.2021; P09 = F1; P10 … P12 = F2 … F4. Plans 07-12 and 07-13 import in this  
> order.”

07-12 instead scopes itself to:

> “P02–P06, P09–P12”

07-13 depends on completion of 07-12.

**Failure scenario:** Fresh P09–P12 imports precede P07/P08, contrary to the committed order used to reason about `%aunique{}`. A fresh draw that collides with DJ content can therefore encounter a different library state from the one the declaration describes. The preservation of P02-before-P04 does not repair the rest of the order.

**Fix:** Before the declaration is committed, either declare the actual executable order or split the import plans so the promised order is achievable. Derive collision predictions from that same ordered list.

**Refutation condition:** This finding is wrong if 07-12 defers P09–P12 until after P07/P08, or 07-06 explicitly declares the non-DJ-before-DJ sequence.

---

### 9. P7XR-09 — MEDIUM — D-28 consumes an `%aunique{}` inventory taken before the last imports

**Plans/tasks:** 07-12 Task 3 → 07-13 Task 3 → 07-15 Task 3.

**Literal text:**

07-12 creates:

> “`%aunique{}` list: from the landed paths, every album directory whose name carries a disambiguator  
> suffix, plus every pair of albums sharing `(albumartist, album)`”

07-15 reads:

> “`artifacts/07-12-nine-imports.txt` § aunique list and the copy-based `move -p` output.”

Its standing rows are:

> “built from the aunique list”

**Failure scenario:** 07-13 subsequently imports and routes the DJ pair and any fresh DJ twins. Those writes can introduce additional disambiguators or change the collision set. Their new cases are not appended to the inventory that 07-15 uses for the supposedly exhaustive D-28 check. Generic per-album MA readings do not make the standing `AUNIQUE_ROWS` complete.

**Fix:** Recompute the disambiguator/collision inventory after all imports and routing, immediately before 07-15’s gate. Re-run the copy-based path prediction on that final DB and reconcile the final inventory with the earlier one. Build standing rows from the final set.

**Refutation condition:** This finding is wrong if 07-13 updates the consumed inventory, or 07-15 independently enumerates all final landed paths and collision groups before building its checks.

---

### 10. P7XR-10 — MEDIUM — The ≥4-artist stratum is consumed as an exactly-four-artist test

**Plans/tasks:** 07-06 Task 1 → 07-15 Task 3.

**Literal text:**

The draw permits:

> “≥4 distinct non-empty entries”

The measurement reports:

> “MA returns K of 4”

The standing check is added with:

> “target 4, the measured Jellyfin and MA values  
> as baselines”

**Failure scenario:** The seeded draw selects a track with five artists. MA returns four. The plan reports “4 of 4,” supports the “Twista-specific” interpretation, and installs target 4 despite one artist being missing. It also does not establish identity agreement merely by counting four returned names.

**Fix:** Preserve the declared ≥4 eligibility. Measure the actual distinct post-import artist set of size N, report K of N, compare names/identities, and set the standing target from N. Treat the cap/Twista hypotheses as supported only to the extent the observed sets justify them.

**Refutation condition:** This finding is wrong if the consumer task selects a demonstrated exactly-four track from the drawn folder, or derives its denominator and target from the actual post-import artist set.

---

### 11. P7XR-11 — MEDIUM — New consumer checks are trusted without the required driven controls

**Plans/tasks:** 07-07 Task 2; 07-15 Task 3.

**Literal text:**

07-07 accepts the new changed-set branch based on:

> “A changed set is routed to the exit-3 arm, never to green (read by eye; line numbers in the SUMMARY).”

07-15 requires:

> “`bash -n`; run the edited script (scp'd, sha256 equal) on LXC 100 and record its exit”

Its D-28 predicate specifies:

> “routes `Various Artists`/empty to `ma_fail`”

**Failure scenario:** A successful live baseline cannot prove that the new census detects a changed set, refuses an incomplete response, or reaches the intended UNKNOWN branch. An overall exit 3 is particularly weak evidence here because existing CONF-04 rows already produce it.

For D-28, the specified failure predicate also names only two bad values. A different, non-empty but incorrect artist needs an explicit comparison against `expected album artist`; a legitimate compilation whose expected artist is `Various Artists` must not be rejected simply for that value.

**Fix:** Before live reliance, drive the actual selectors and exit paths with controlled responses: unchanged census, added/removed path, failed or incomplete enumeration, missing/duplicate MA item, unexpected non-empty artist, expected `Various Artists`, and empty aunique inventory. Assert exact expected-artist equality and per-section outcomes independently of the script’s pre-existing pending state.

**Refutation condition:** This finding is wrong if a mandatory task supplies those positive/error controls for the new branches and explicitly compares the measured artist with each row’s expected value.

### 3. What was checked and held — no finding

These are textual clears, not claims about the live estate.

- **Fence ordering:** 07-09 Task 2 explicitly takes both named snapshots in one remote invocation, checks command results and lists both back before installing the grant. It correctly distinguishes one remote step from cross-pool atomicity. The writer-quiescence issue is separate.
- **Shared-dataset rollback prohibition:** The recovery tasks prohibit `zfs rollback` of `fast/appdata/arrs`, including at the file-restore call site. No permitted branch instructs an arrs rollback.
- **Default grant scope and commit coupling:** 07-08 keeps the dormant CLI arm read-only and places the flask grant, de-registration, behavior documentation, check changes and digest register in one specified commit. C1 and C10 are measured rather than copied from stale evidence.
- **Diff hardening:** 07-02 specifies symmetric ambiguity detection, exit 3 in both text and JSON modes, UNKNOWN precedence, a red-before-fix test, and real or explicitly real-derived controls.
- **Copy and file evidence:** 07-10/12/13 stage copies rather than moving originals. They require source-manifest comparisons and `ffprobe` comparisons against DB rows, with ownership read from atlantis—not `beet ls` as file-write evidence.
- **Frozen prediction:** 07-06 carries 132 lines from a named commit, verifies them using two hash implementations, and forbids silently fitting frozen rows to import results.
- **Snapshot destruction scope:** Apart from the D-17 eligibility finding above, 07-11 limits its destruction to one literal snapshot. 07-16 requires an operator-approved eligible list, prohibits recursive flags, compares complete name sets and protects both pilot snapshots and `tank/downloads@pre-phase5`.
- **Credentials and refresh verbs:** The supplied API recipes use stdin/environment-based JSON construction and process-substitution headers. No reviewed branch authorizes `FullRefresh`, aggressive per-item refresh or another attempt at E6’s disproven mtime route.
- **Dependency graph:** The 17-plan graph is acyclic; named artifact producers are available through direct or transitive dependencies. The import-order defect is not a missing-artifact dependency defect.
- **Formal verification separation:** 07-17 assembles measurements, leaves requirement boxes unchanged and reserves formal scoring for `/gsd-verify 07`.

**Read/search scope:** The complete supplied context, pattern map and all 17 plans were reviewed, including objectives, actions, acceptance blocks and threat registers. Absence checks for synchronization barriers, writer quiescence and control drives used a full-document search, not a section-only read:

```sh
/usr/bin/grep -nEi \
'schedul|automatic.*sync|sync.*automatic|disable.*sync|pause.*sync|quiesc|stop beets-flask|stop.*watchdog|positive control|self-test|D-17 TRIGGER|STOP STATE' \
prompt.md
```

The pattern was driven against matching control strings. Referenced implementation files and the live estate were not available for independent verification.

### 4. Suggestions

- Give every evidence bundle a run ID and record the instrument commit, configuration digests and capture timestamps alongside its measurements.
- Keep a short operator run card for the UI actions—confirm, undo, retry and hold—with links to the detailed evidence rather than duplicating the plans.
- Place the single code-review round where it can cover the final consumer-check changes too; do not describe a review of only 07-02 through 07-08 as covering code added in 07-15.
- Estimate the wall-clock cost of the repeated full-file probes and hashes before execution, so stopping for the evening is planned rather than improvised.

---

## Review: copilot CLI / gpt-5.5 (219 credits, 2m55s)

### Summary

Overall risk: **HIGH**. The plan set is mostly strong on the core safety spine — fence-before-grant, `ffprobe` evidence, copy-not-move, fail-closed instruments, credential handling, no self-scored verification, and Jellyfin-before-MA ordering are all explicitly wired. The high risk comes from two branches that undermine settled safety invariants: 07-09 re-opens the ratified flask-only `rw` grant by offering `grant-both`, and 07-11 lets the D-17 snapshot release fire even when `UNDO IMPORT` failed to cover `state.pickle` and required a manual file restore.

### Findings

1. **HIGH — 07-09-PLAN.md / Task 1 + Task 2 — `grant-both` re-opens a ratified forbidden second writer**

   **Literal quoted text:**

   > `The D-22 commit grants rw to beets-flask only (the dormant CLI arm stays ro) — say \`grant-both\` to amend that before deploy.`

   > `<option id="grant-both">`  
   > `<name>Proceed, but grant rw to the dormant CLI arm too</name>`  
   > `<cons>Creates an unsanctioned second writer (D-04 forbids it the real library) and reds the freeze census when started.</cons>`

   > `**On \`grant-both\`:** first make a one-line amendment commit changing \`beets.yaml\`'s mount to \`:rw\` and qhc's CLI-render expectation to \`rw\` with a dated note citing the operator's answer, then continue as \`proceed\`.`

   **Concrete failure scenario:** The prompt’s status section says the plan-checker warning was already ratified: the `:rw` grant is **flask.yaml ONLY**. The “Do NOT re-litigate” list also includes the flask-only rw grant. This plan nevertheless gives the operator a branch that makes the dormant CLI arm writable, even while the option itself states that D-04 forbids that arm from opening the real library. If that branch is selected, the estate can end up with a second tagger-capable writer to `/media`, outside the sanctioned beets-flask path and outside the `check-music-freeze.sh` exact `beets-flask` exception shaped in 07-08. That is a library-corruption risk and a gate that should fail.

   **Fix:** Remove `grant-both` from 07-09 entirely. If the operator wants to revisit flask-only, the correct outcome is `hold` plus a new context/plan amendment that re-decides D-22, D-04, `check-music-freeze.sh`, qhc, and the dormant-arm safety model together. In 07-09, the only write branch should keep `beets.yaml` `:ro`.

   **Refutation condition:** This finding is wrong if `07-CONTEXT.md` D-22 or the plan-checker ratification text explicitly says `grant-both` remains an allowed branch after the flask-only decision. The text provided says the opposite: flask-only was ratified.

2. **HIGH — 07-11-PLAN.md / Task 3 — D-17 can destroy the Phase 6 snapshot after a manual state restore, even though `UNDO IMPORT` failed the thing D-17 depends on**

   **Literal quoted text:**

   > `If STATE COVERED is \`no\`: write \`DEF-07-11-01\` in the phase \`deferred-items.md\` — "\`UNDO IMPORT\` does not cover \`state.pickle\`; D-14's claim is falsified for the incremental state" — and present the restore option.`

   > `**On \`restore-then-rerun\`:** on atlantis as real root, copy \`/mnt/fast/appdata/arrs/.zfs/snapshot/pre-07-pilot/beets/config/state.pickle\` over \`/mnt/fast/appdata/arrs/beets/config/state.pickle\` ... Then proceed as \`rerun\`.`

   > `**D-17, mechanical, no gate.** The trigger (DEF-06-52-01) has FIRED iff: (i) both pre-07-pilot snapshots were listed back ... AND (ii) this plan's UNDO WITNESS shows TREE COVERED yes, DB COVERED yes, and state covered either by UNDO IMPORT (STATE COVERED yes) or by the operator-chosen file restore — i.e. "rollback exercised" on tree, DB and state.`

   > `If FIRED ... issue exactly \`zfs destroy tank/media/Music@pre-06-41-conf04-reprobe\``

   **Concrete failure scenario:** If `UNDO IMPORT` does not cover `state.pickle`, the plan correctly records D-14 as falsified. But the same task then allows a manual file restore to count as D-17’s “rollback exercised” trigger and mechanically destroys `tank/media/Music@pre-06-41-conf04-reprobe`. That release condition was supposed to fire when the planned rollback/undo mechanism was proven, not when it failed and was patched by a manual restore that criterion 5 explicitly leaves for `/gsd-verify 07` to judge. This can wrongly destroy a held snapshot on evidence that should keep it held.

   **Fix:** Make D-17 fire only when `TREE COVERED yes`, `DB COVERED yes`, and `STATE COVERED yes` are all produced by `UNDO IMPORT`, followed by the byte-equal re-run. If `restore-then-rerun` is used, record `D-17 TRIGGER: NOT FIRED — state required manual restore`, hold `tank/media/Music@pre-06-41-conf04-reprobe`, and let `/gsd-verify 07` or a later operator-gated plan decide release.

   **Refutation condition:** This finding is wrong if `DEF-06-52-01`, D-15, or D-17 explicitly says a file restore from `fast/appdata/arrs@pre-07-pilot` counts as the mechanical release trigger. The provided text frames that restore as a remedy when D-14 is falsified, not as proof that `UNDO IMPORT` covered state.

3. **MEDIUM — 07-09-PLAN.md / Task 2 — partial two-pool fence failure leaves an unrecoverable-in-plan STOP state**

   **Literal quoted text:**

   > `zfs snapshot tank/media/Music@pre-07-pilot`, capture RC, stop on non-zero; `zfs snapshot fast/appdata/arrs@pre-07-pilot`, capture RC, stop on non-zero; list both back ...

   > `If ANY step of 2 fails: STOP; the grant is not deployed; record; ledger STOP STATE.`

   **Concrete failure scenario:** Because `tank` and `fast` are different pools, the fence cannot be atomic. If `tank/media/Music@pre-07-pilot` is created successfully and `fast/appdata/arrs@pre-07-pilot` fails, the plan stops with a partial fence. A rerun then hits Task 1’s exact absence check for both names and refuses because the tank snapshot now exists, but there is no branch to complete the missing fast snapshot or safely retire the partial tank snapshot. No library write occurred, so this is not data loss, but it breaks D-18’s resumability and pushes the operator toward manual ZFS cleanup outside the plan.

   **Fix:** Add an explicit `PARTIAL FENCE` branch. If the first snapshot exists and the grant has not run, either complete the missing snapshot after re-asserting `/media` is still `ro` and item count is still 0, or present an operator gate to destroy exactly the partial snapshot and retry. Record that state in the ledger, with exact name-set checks.

   **Refutation condition:** This finding is wrong if the remote fence program contains an unquoted cleanup/trap that removes the first snapshot when the second snapshot fails, or if the plan has a later partial-fence recovery branch. The quoted Task 2 text only says STOP.

### What was checked and held (no finding)

- **07-01 evidence map and D-13 amendment:** The map is pre-run, does not self-score verification, keeps `REQUIREMENTS.md` unchanged, and makes the `unsorted` exception conditional on 07-02’s AMBIGUOUS control.
- **07-02 diff hardening:** The AMBIGUOUS join fix is symmetric, covers `--json`, states exit-3 precedence, preserves the duplicate-info retraction, and is driven by fixtures plus real/real-derived data.
- **07-03 import sweep:** `check-music-import.sh` is fail-closed with vacuity handling, positive controls, a qhc fold-in, no `beet` invocation, and read-only sqlite access.
- **07-04 DJ routing instrument:** Default mode is read-only, `--apply` is required for writes, the beets version/container are pinned to beets-flask 2.12.0, and D-04 registration is deliberate rather than hidden.
- **07-05 pre-grant sequencing:** The Phase 6 oracle run is correctly placed before the D-22 grant, and DJ rule 2 is exercised read-only in a throwaway library.
- **07-06 sample/oracle:** The sample declaration precedes measurement, S2/S3 are named before import, archive roots are excluded for the QUAL-01 reason, and frozen expected-tree rows are commit-anchored.
- **07-07 before-state:** Per-album BEFORE captures, source manifests from atlantis, D-24 census baseline, and consumer baselines are all taken before the first write.
- **07-08 D-22 default branch:** The main path keeps `beets.yaml` `:ro`, grants only beets-flask, de-registers `01-auto`, updates qhc and freeze checks, and records previous/new config digests.
- **07-10 through 07-13 import flow:** Per-album UI confirmation, D-29 ordered match checks, copy staging, ffprobe-vs-DB checks, QUAL-02 diffs, source-manifest rechecks, Jellyfin file-scope scans, and MA-last ordering are all consistently specified.
- **07-14 E5 repair:** The repair is measured first, writes only approved fields through `mediafile`, verifies with the same diff instrument, and keeps recovery to file copy rather than rollback.
- **07-15 consumers:** Jellyfin is read first, MA sync is gated and once-only, D-28 reads MA directly rather than inferring from config, E6’s second measurement has a proper NOT TAKEN branch, and `REQUIREMENTS.md` remains untouched.
- **07-16 snapshot register:** The register uses owner/undo/release rows, treats silence as could-not-look, keeps `@pre-phase5` operator-gated, and requires a single operator gate before any destroy.
- **07-17 closure:** The plan assembles measurements without verdict words, leaves `/gsd-verify 07` as the scorer, records a separate trust verdict, and updates durable docs in the same commit as the beets.md pointer.

### Suggestions

- Add a short “ratified decisions are not gate options” rule to the plan template so branches like `grant-both` cannot reappear after operator ratification.
- Add a standard partial-fence recovery pattern for multi-pool snapshot fences; this phase is the first place where “one remote step” is explicitly not atomic.
- In 07-11, separate “undo mechanism proven” from “state recovered somehow” in the artifact vocabulary so `/gsd-verify 07` cannot accidentally inherit the same ambiguity.


---

## Review: pi → xai / grok-4.7

### 1. Summary

Overall risk is **HIGH**. The fence-before-grant order, flask-only `:rw` commit, copy-not-move staging, ffprobe-not-`beet ls`, MA-last, and “no plan scores `/gsd-verify`” structure are coherent and mostly fail closed. The hole is plan **07-11**: `TREE`/`DB`/`STATE COVERED` are defined as post-undo absence, which is the same observation as “never had it,” and that verdict is what mechanically fires `zfs destroy` of `tank/media/Music@pre-06-41-conf04-reprobe`. A second HIGH is plan **07-04**: the new real-library writer is required to contain no literal `beet` token, while the only quoted `D04_INV_RE` matches a literal `beet` token, and a zero match is not a stop — so the D-04 gate can stay green over an invisible writer (the E10 failure this phase is supposed to inherit as a pin, not repeat).

### 2. Findings

1. **HIGH — 07-11 Task 2 and Task 3.** Undo “covered” is an unchecked absence, and that absence is the D-17 destroy trigger.

Literal text (Task 2): “`(state) state.pickle sha256 and decoded taghistory membership of the staged P01 path — expected ABSENT`” and “`Verdict lines, one per part: TREE COVERED yes/no, DB COVERED yes/no, STATE COVERED yes/no.`” Task 1 already allows the pre-undo reading to be absence: “`if ABSENT, record it: then state.pickle never held the path and the undo question is moot for it`”. Task 2 does not require PRESENT-before → ABSENT-after. The same shape is used for the tree: “`P01 destination file count — expected 0`”.

Literal text (Task 3): “`The trigger (DEF-06-52-01) has FIRED iff: (i) both pre-07-pilot snapshots were listed back in 07-09-fence-and-grant.txt (quote the lines), AND (ii) this plan's UNDO WITNESS shows TREE COVERED yes, DB COVERED yes, and state covered either by UNDO IMPORT (STATE COVERED yes) or by the operator-chosen file restore`” and then “`issue exactly zfs destroy tank/media/Music@pre-06-41-conf04-reprobe`”.

Failure: if `taghistory` stores the destination path, or bytes rather than the inbox string, membership is ABSENT before and after. Task 2’s expected value is met, `STATE COVERED yes` is written, and D-17 destroys the Phase 6 snapshot. `incremental: yes` still skips the re-run. Re-run equality would later fail, but the destroy does not wait on equality. A `find` of a wrong or missing destination is the same false `TREE COVERED yes` (zero is not UNKNOWN).

Fix: `COVERED yes` only on a paired witness: pre-undo file count equals the 07-10 item count and post-undo count is 0 on that same path; pre-undo `taghistory` contains the path actually written (discover the key; do not assume the inbox path) and post-undo does not. If pre-undo is already absent, `STATE COVERED` is `no` / UNKNOWN, `DEF-07-11-01` is filed, and `D-17 TRIGGER: NOT FIRED`. Do not destroy on a zero that was never shown to move.

Refutation: wrong if Task 2 text requires `STATE COVERED yes` only when the same decoded key was PRESENT in the pre-undo witness and ABSENT after, and Task 3 fires D-17 only on that transition (and the same for tree/DB counts against the 07-10 non-zero witness).

2. **HIGH — 07-11 Task 3.** File restore is treated as criterion 1’s “rollback exercised,” which is the wrong destroy condition.

Literal text: “`state covered either by UNDO IMPORT (STATE COVERED yes) or by the operator-chosen file restore — i.e. "rollback exercised" on tree, DB and state.`” The ratified mapping in the review brief (D-15) is that criterion 1 is discharged by `UNDO IMPORT` covering tree, `library.db`, and `state.pickle` together, and that D-17 fires on that back-out plus the new snapshot. Task 2 itself says a restore means “`D-14 stands falsified`” and “`criterion 5's "no hand-repair" is then for /gsd-verify 07 to judge`”.

Failure: `UNDO IMPORT` misses `state.pickle`, the operator picks `restore-then-rerun`, the plan writes `D-17 TRIGGER: FIRED` and destroys `@pre-06-41-conf04-reprobe` even though the ratified discharge did not happen. That snapshot is then gone before `/gsd-verify 07` can reject the mapping. Irreversible, and it is the plan’s own judgement wearing a mechanical label.

Fix: D-17 fires only when `STATE COVERED yes` came from `UNDO IMPORT` with the paired witness in finding 1. `restore-then-rerun` is `D-17 TRIGGER: NOT FIRED — state covered by file copy, not UNDO IMPORT`. Leave `@pre-06-41-conf04-reprobe` listed and held.

Refutation: wrong if the D-17 paragraph limits `FIRED` to `STATE COVERED yes` from the UI undo, and names file restore as `NOT FIRED`.

3. **HIGH — 07-04 Task 1 and Task 2.** The real-library writer is built to be invisible to the only quoted invocation regex, and a zero match does not stop registration.

Literal text (Task 1 verify): “`test "$(/usr/bin/grep -vE '^[[:space:]]*#' scripts/route-dj-album.sh | /usr/bin/grep -cE '(^|[^A-Za-z_$"])beet[[:space:]]')" -eq 0`”. Literal text (PATTERNS, D-04 block): “`What the scan matches (D04_INV_RE, line 2062) includes docker[[:space:]][^`]*[[:space:]]beet[[:space:]]` — so D-08's `docker exec … beet modify` / `beet move` lines … WILL be counted`”. Literal text (Task 2): “`Record the route script's lines that land in D04_INVOKE_ASSERT (expected: every "$BEET_REALLIB" line) — this is the count moving, a red by design`” and “`Move D04_EXEMPT_BASELINE default from 5 to 5 + N where N is the number of route-script lines the measurement found`”. There is no stop if that set is empty. The threat row’s “`D04_INV_RE's BEET[A-Z_]*`” is not the pattern PATTERNS quotes.

Failure: every `"$BEET_REALLIB"` line misses the quoted `beet[[:space:]]` alternative, N is 0, the pin stays 5, the new alternation never matches, and `quick-health-check.sh`’s D-04 block stays green. Plan 07-09 then treats “D-04 register green” as a proceed condition while `route-dj-album.sh --apply` opens `/config/library.db`. That is E10 again: a green tick over an empty match set.

Fix: before editing the register, require N ≥ 1 and every executable invocation line in the assert set; if N is 0, STOP and do not add an exemption. Make the on-disk `D04_INV_RE` match the token the script actually emits (or emit a literal `beet` token the quoted alternative already matches), and move `D04_EXEMPT_BASELINE` only with that measured N in the same commit.

Refutation: wrong if the `D04_INV_RE` assignment (not a comment) already matches `"$BEET_REALLIB"` / `BEET_REALLIB`, and Task 2 aborts when the pre-edit assert count for `scripts/route-dj-album.sh` is 0.

4. **MEDIUM — 07-05 Task 3.** An autonomous `beet import` of a real `dj-mixes` folder runs before any fence; the write-block is a substring assert.

Literal text: “`write an overlay YAML redirecting library: /tmp/p6-p7rule2/lib.db … and setting import: {write: no, copy: no, move: no}`” then “`assert import.write: no, copy: no, move: no`” then “`import -A -q --set albumtype=dj <container path of folder>`”. `/downloads` is already `:rw`, and the vendored config’s live key is `write: yes` (PATTERNS quotes that stanza, including a comment that talks about overriding write to `no`).

Failure: `beet config` output that merely contains the comment, or a dump of the overlay file rather than the loaded keys, satisfies the assert while the effective key stays `write: yes`. The import then retags the only copy of that folder. The post-run sha256 check detects it and does not undo it. The only content undo is `tank/downloads@pre-phase5`, which this phase is forbidden to roll back.

Fix: parse the three keys out of `beet config` (values, not substrings); STOP unless each is `no`. Keep the sha256 manifest, but do not treat a mismatch as a clean finding — the folder is already dirty.

Refutation: wrong if the assert is specified as a parsed effective value (for example `beet config | awk` equality on the three keys) and the import command is not reached unless that parse matches.

5. **MEDIUM — 07-11 Task 2.** A failed tree/DB undo can still be re-run; a failed state undo is “fixed” by copying `state.pickle` under a live writer.

Literal text: options include “`rerun`” and “`restore-then-rerun`” with “`copy /mnt/fast/appdata/arrs/.zfs/snapshot/pre-07-pilot/beets/config/state.pickle over /mnt/fast/appdata/arrs/beets/config/state.pickle`” and no requirement that `TREE COVERED` and `DB COVERED` are `yes`, and no restart of `beets-flask`.

Failure: re-import on top of a still-present album produces a `.1` collision or a duplicate row (criterion 7’s own bug class). A file copy onto `state.pickle` while flask is running is overwritten from memory or ignored, so `incremental_skip_later: yes` still skips the re-run and equality fails for a reason the witness will mis-name.

Fix: `rerun` is illegal unless all three `COVERED` verdicts are the paired yes from finding 1. On `restore-then-rerun`, stop the container, copy, sha256-match the snapshot file, start, re-decode `taghistory`, then re-stage.

Refutation: wrong if Task 2’s `rerun` option is specified to be refused unless `TREE COVERED yes` and `DB COVERED yes`, and the restore step stops `beets-flask` before the `cp` and re-decodes after start.

6. **MEDIUM — 07-09 Task 2.** Post-grant `import.move` / `import.copy` are recorded, not gated, and inbox emptiness is not re-checked at the grant.

Literal text: “`Assert the effective import keys by running bash scripts/check-beets-config.sh … and recording its exit and the import.copy/move/write readings (copy true, move false, write true)`”. The only STOP in that step is “`If the watchdog line is absent or lists fewer than two: STOP`”. Inbox counts are task 1 item (f), not repeated after the operator gap.

Failure: rc6’s effective `move` can disagree with the vendored file (C1 says the server value is the one that governs). The plan still marks the grant done. The next import then moves the inbox copy. Originals survive only because staging was a separate copy — criterion 8 does not notice a consumed staged tree. A file landing in `02-review` during the gate is previewed or imported as soon as the mount flips.

Fix: STOP the grant unless parsed effective `copy` is true and `move` is false. Re-count audio under `_inbox/01-auto`, `02-review`, and `03-asis` in the same remote step as `compose up`, and STOP if any count is non-zero.

Refutation: wrong if Task 2 step 3 already STOPs on those parsed keys and re-asserts the three inbox counts immediately before `compose up`.

7. **MEDIUM — 07-12 Task 3 verify and 07-13 Task 3 verify.** A legal all-hold answer fails the mechanical check unless the artifact grows a success string.

Literal text (07-12): “`{ /usr/bin/grep -qiE 'OPERATOR ANSWER.*hold-all' "$A" || { /usr/bin/grep -qF 'aunique' "$A" && /usr/bin/grep -qF 'check-music-import' "$A" && /usr/bin/grep -qE 'P0[2-6] LANDED|P1[0-2] LANDED|P09 LANDED' "$L"; }; }`”. The resume-signal says a missing P-ID line “`is treated as hold`”, which is not `hold-all`. Literal text (07-13): the success arm is skipped only for “`OPERATOR ANSWER:? *hold *$`”, otherwise it requires “`route-dj-album.sh --album-id`”.

Failure: per-album holds are the outcome D-20 calls successful. The verify does not pass unless a `LANDED` line or a route transcript exists. That is pressure to invent a landed album, or to run `--apply`, so the plan can go green.

Fix: pass the verify when every in-scope P-ID has an explicit `hold` line and the ledger lists them as not landed; require `LANDED` / `--apply` only for IDs answered `imported`.

Refutation: wrong if those verify blocks already accept a per-album `hold` ledger with zero `LANDED` lines.

8. **MEDIUM — 07-15 Task 2.** An already-synced Music Assistant does not force `hold`, so the “MA last” invariant is advisory.

Literal text: “`whether any pilot album is already visible in MA (MA may have a scheduled sync — if so, record which, since that is an unplanned earlier sync)`” and the recommendation is still “`hold` first” as an option, not a required stop. Task 3 on `sync` then “`issue the one sync command`”.

Failure: a scheduled sync during the 07-11 undo or the 07-13 artist-tree window has already written MA’s database, which no snapshot covers and which never purges. Another sync adds a second view. Criterion 6 then “passes” on a store the fence cannot repair.

Fix: if any pilot album is already in MA, the only legal option is `hold`, and the artifact records `E6`/`D-28`/`criterion 6 MA` as `NOT TAKEN — unplanned earlier sync`. Do not offer `sync` on that branch.

Refutation: wrong if Task 2 says an already-visible pilot album removes the `sync` option.

9. **MEDIUM — 07-17 Task 2.** The backlog denominator in the files every session loads is “corrected” with a different population.

Literal text: “`the backlog denominator: add the measured live figure from 07-SAMPLE.md with its date beside the 144 (do not delete the dated 144)`”. `07-SAMPLE.md`’s live count is the D-06 draw population (`music/` ∪ `unsorted/`, Now! excluded, reused folders excluded), not the 144-folder backlog figure CONTEXT calls stale.

Failure: CLAUDE.md / PROJECT.md gain a number that looks like a replacement denominator and is not. Later phases will size work from it. CONTEXT’s own deferred note says restating an unverified number launders it.

Fix: either re-measure the same denominator the 144 referred to, or write the 07-SAMPLE figure only as “D-06 eligible population on &lt;date&gt;, not the 144-folder backlog count.”

Refutation: wrong if Task 2 names the 07-SAMPLE figure as a different population and forbids placing it in the backlog-denominator sentence.

10. **LOW — 07-01 Task 2 verify.** The safety-rule edit is checked for one deletion, not one insertion.

Literal text: “`test "$(git diff HEAD~1 -- "$R" | /usr/bin/grep -c '^-[^-]')" -eq 1`”. Acceptance requires the diff “`removes exactly one line (the old row) and adds exactly one`”. The automated check does not count `^+[^+]`.

Failure: a second added line (a broader exception, a second row) still passes the verify.

Fix: also require the added-line count to be 1, and `git diff HEAD~1 --numstat -- ROADMAP.md` to show a one-line replacement.

Refutation: wrong if the verify already counts added lines as exactly 1.

11. **LOW — 07-09 Task 2.** The criterion-1 “taken together” file copy is not hashed against the snapshot.

Literal text: copy `library.db` and `state.pickle` and “`record sha256sum of source and copy (equal; the fixture values). Also assert the snapshot's own view holds them: ls -l /mnt/fast/appdata/arrs/.zfs/snapshot/pre-07-pilot/beets/config/library.db`”.

Failure: `ls -l` is existence. A writer between the arrs snapshot and the copy (watchdog, idle beets) makes `/mnt/fast/safety/phase07/fence/` a different object than the snapshot. Later “restore the fence copy” is not the snapshot.

Fix: `sha256sum` the `.zfs/snapshot/pre-07-pilot/...` files and require equality with the safety copies before the grant.

Refutation: wrong if Task 2 already hashes the snapshot paths and stops on mismatch.

### 3. What was checked and held (no finding)

- **Fence before library mutation.** No plan before 07-09 writes `tank/media/Music`. 07-09 Task 2 order is pull → one remote step (`tank/media/Music@pre-07-pilot` then `fast/appdata/arrs@pre-07-pilot`, fail-if-exists, list back) → only then install and `compose up`. 07-10/12/13 re-require both snapshot names before staging. 07-05’s import is a throwaway `-l` under `/tmp/p6-p7rule2` (finding 4 is the source-tag residual, not a library write).
- **`zfs rollback` of `fast/appdata/arrs`.** No task’s executable steps issue it. 07-09, 07-11, and 07-16 name file-copy recovery only. 07-16’s call site also refuses `@pre-phase5` and `@pre-07-pilot`, no `-r`/`-R`/`-f`.
- **Copy, not move.** 07-08 leaves `copy: yes` / `move: no` unless C1 measurement says otherwise; staging is `cp -R --reflink=always` or plain `cp -R`, with source manifests re-checked. Criterion 8’s originals are not the inbox copy.
- **ffprobe, not `beet ls`.** 07-10/12/13/14/17 compare `ffprobe` to a read-only sqlite row and take `568:568` from atlantis, and they count `EPERM` / `Error writing` log lines.
- **MA last / `FullRefresh`.** 07-10 states why MA is not synced before the undo; 07-12/13/14 do not sync MA; 07-15 is the single sync, after E5. No plan issues `FullRefresh` or a library-wide scan; Jellyfin writes are file-scope `POST /Library/Media/Updated`. E6’s mtime route is not retried.
- **D-22 one commit, flask-only.** 07-08 Task 3’s commit is the seven-file grant; `beets.yaml` stays `:ro`; `01-auto` is removed from `flask-config.yaml`; digest register keeps the previous object. `grant-both` is an operator override at 07-09, not the default. Deploy is 07-09, not 07-08.
- **D-31.** 07-17 fills only the measured column, forbids verdict words in the map, and leaves `REQUIREMENTS.md` unchecked including CONF-04. Trust verdict is a separate file.
- **D-11 seam.** 07-02 puts exit 3 above exit 1 on both the text and `--json` arms; 07-10/12/17 treat exit 3 as UNKNOWN, not pass. 07-12 refuses `unsorted/` staging unless the deployed script’s sha256 matches the repo and contains `AMBIGUOUS_BEFORE`.
- **D-07.** Frozen rows come from `git show <anchor>:06-EXPECTED-TREE.txt`, 132-line check, two hashers; later plans classify divergences and the verifies use `git diff --exit-code HEAD --` on the oracle file. No bare `git diff --exit-code <path>` (index form) showed up in these plans.
- **C7/C8 sequencing.** 07-05 is a 07-09 dependency and STOPs if `/media` is already RW=true or `library.db` is off `fbbdde0c…`.
- **D-13 amendment.** Original “Must precede any import of `unsorted`” stays visible; exception is the bounded pilot and is conditional on the D-11 arm; D-02/D-03 enactment is explicitly not done here.
- **Credential pattern.** Jellyfin/MA reads are specified as `jf_api` / `$ENV` in jq / process substitution, with artifact screens. (07-15’s new sync call should reuse `ma_api` rather than a raw `-H` string; that is a suggestion, not a second finding, because Task 3’s read_first points at that helper.)
- **Cross-plan artifact ownership.** 07-09 depends on 07-01…07-08; import plans sit after the grant; 07-13 depends on 07-04 for `route-dj-album.sh`; 07-12’s D-13 check consumes 07-02’s script via the 07-09 pull, which depends on 07-02. Evidence-map artifact names match the files later plans create (`07-09-fence-and-grant.txt`, `07-11-p01-undo-rerun.txt`, `07-15-consumers.txt`, `07-17-evidence.txt`, `07-SAMPLE.md`).

### 4. Suggestions

- 07-09’s host `git status --porcelain` must be empty, with no remediation. This estate’s dirty/untracked checkout will STOP the phase before a fence exists. Name the allowed cleanup (list untracked paths, operator deletes or commits) so the stop is not improvised beside `zfs`.
- 07-11: if undo leaves an empty album directory, say that a later `.1` path is a finding and that removing the directory is hand-repair. Do not leave that implicit.
- 07-12 should warn, in the gate table, that P04 meets P02 under `duplicate_action: ask` (Phase 6’s `skip` dropped ten files). The operator will see that prompt and the plan currently talks only about `%aunique{}`.
- 07-09 success path should write the literal `## STOP STATE` heading the Task 2 verify greps for; the proceed action currently omits it.
- 07-15 Task 3’s sync request should say “through `ma_api` / `-H @<(printf …)`”, not only “issue the one sync command”, so the JWT cannot land in argv on the one new write.

---

## Review: pi → ollama-cloud / kimi-k3

### Cross-AI Plan Review — Phase 7: Pilot, 12 Albums End to End

### 1. Summary

Overall risk **MEDIUM** (near the LOW boundary). The set is unusually disciplined: nearly every prose condition has a mechanical enforcement beside it, fail-closed semantics are pervasive, and the known cross-plan seams — 07-02's exit-3, the frozen oracle rows, C1…C11, the qhc notice-count ladder (14 → 15), the D-04 register, the ledger, `REQUIREMENTS.md` under `HEAD --` — are wired in both directions by the plans themselves. The two MEDIUMs are both in the destructive/standing-instrument class rather than the import path: 07-11 defines the D-17 mechanical destroy trigger more permissively than the ratified mapping, and does so on exactly the branch where the undo tool has just been proven incomplete; and 07-03's sweep ships a vacuity guard that its own must_have claims but whose behaviour list and self-test don't deliver for one class. Everything else found is LOW. No HIGH found: nothing writes before the fence, every write is gated or fenced, `zfs rollback` is screened out at every call site, credentials never enter argv, and no gate's pass condition can be satisfied by a could-not-look.

### 2. Findings

---

**Finding 1 — MEDIUM — 07-11, Task 3: the D-17 mechanical destroy fires on a trigger the plan redefines past the ratified mapping**

Literal text (07-11 Task 3 action):

> "**D-17, mechanical, no gate.** The trigger (DEF-06-52-01) has FIRED iff: (i) both pre-07-pilot snapshots were listed back in `07-09-fence-and-grant.txt` (quote the lines), AND (ii) this plan's UNDO WITNESS shows TREE COVERED yes, DB COVERED yes, and state covered **either by UNDO IMPORT (STATE COVERED yes) or by the operator-chosen file restore** — i.e. 'rollback exercised' on tree, DB and state."

Against the ratified text (07-CONTEXT, D-15 plan-time ratification):

> "ROADMAP criterion 1's **'rollback exercised at least once' is discharged by this `UNDO IMPORT` back-out** covering tree, `library.db` and `state.pickle` together"

and D-17:

> "`tank/media/Music@pre-06-41-conf04-reprobe` (`DEF-06-45-01`) is destroyed **mechanically**, in the same step that records **criterion 1 satisfied** (new snapshot taken **and** rollback exercised)."

Concrete failure scenario: on the `restore-then-rerun` branch, STATE COVERED is `no` — UNDO IMPORT has just been measured NOT to cover `state.pickle` (the plan itself files `DEF-07-11-01` saying "D-14's claim is falsified"). The state is then recovered by a manual `cp` out of `.zfs/snapshot/`. The ratified discharge event — an UNDO IMPORT back-out covering all three parts — did not occur; the estate needed a hand in it. Yet 07-11's own definition declares `D-17 TRIGGER: FIRED` and issues `zfs destroy tank/media/Music@pre-06-41-conf04-reprobe` in the same step, explicitly with no gate. Two consequences: (a) the estate's last pre-pilot hedge snapshot is destroyed in precisely the run where the chosen undo mechanism proved incomplete — the run where extra hedges are worth the most; and (b) "criterion 1 satisfied" gets recorded on a discharge mapping no ratification named, which brushes against both invariant 6 (the ONE mechanical release is the *named* one) and the operator's own stated standard for this item — "one named trigger, no judgement left in it." Redefining the trigger *inside the executing plan* is judgement.

Fix: on the restore branch record `D-17 TRIGGER: NOT FIRED — state not covered by UNDO IMPORT (DEF-07-11-01); destroy held. A restore-augmented back-out is not the ratified discharge. Release question carried to plan 07-16's gate.` Fire the destroy only when STATE COVERED is `yes`. This costs one held snapshot against a falsification that may never happen, and 07-16's operator gate already exists to answer exactly this question with the full register in hand.

Refutation condition: this finding is wrong if the operator's D-15/D-17 ratification, or DEF-06-52-01's trigger text in `.planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md`, defines the release event as "tree, DB and state returned to pre-import state by any sanctioned means, including a snapshot file restore" — i.e. if the restore fallback was already inside the named trigger; or if the `restore-then-rerun` gate answer is itself recorded as authorising the destroy.

---

**Finding 2 — MEDIUM — 07-03, Task 1: the vacuity guard the must_have claims is not delivered for class 2 (or for the no-album-rows case), and no self-test case drives it**

Literal must_have text:

> "D-25: it fails closed with a vacuity guard — **an empty library, an unreadable database, or a class with zero checkable rows is UNKNOWN (exit 3) and never a pass**"

Literal behaviour list (the normative spec the executor builds), in full for the vacuity cases:

> "Empty item set → exit 3 UNKNOWN.
> A library where every album-disc has `tracktotal` 0/NULL (nothing checkable for class 3) → exit 3 UNKNOWN (class vacuity)."

And the judge spec: "Vacuity: items == 0 → UNKNOWN; album groups > 0 but checkable class-3 groups == 0 → UNKNOWN."

Concrete failure scenario: class 2's checkable rows are album items (`album_id` not NULL). A dump with `items > 0` where **every** item is a singleton (`album_id` NULL) leaves classes 2 AND 3 with zero checkable rows. The implemented vacuity arms don't fire (`items != 0`; "album groups > 0" is false), class 1 evaluates fine, and the script exits **0 green** — a green the instrument never earned, printed under the `📊 5. Summary` heading and folded into qhc's green arm. In the pilot this can't occur (11 albums land beside the singletons), but D-25's whole justification is that Phase 9 runs this after every batch — including DJ/single-heavy batches. The second half of the same miss: the 8 self-test cases enumerate empty-set and class-3-vacuity but no all-singletons case, so the missing branch is also unproven-able-to-fail (CONVENTIONS §3).

Fix: one rule, implemented per class, not per case: track `CHECKABLE_C1/C2/C3` counters; any class with `CHECKABLE == 0` increments UNKNOWN (class 1's checkable set is `items`, which is already covered). Add a ninth behaviour to the list ("all items singletons → exit 3") and make it self-test case 9 — `ST_PLANNED_CASES=9`, pin moved in the same commit with the CONVENTIONS §5 note.

Refutation condition: this finding is wrong if the judge routes the zero-album-items condition to exit 3 by a mechanism not enumerated in the quoted behaviour list (e.g. a general per-class checkable-rows rule), and a self-test case drives it.

---

**Finding 3 — LOW — 07-07, Task 2: the D-24 census pins a baseline from one `/Items` call with no coverage assertion**

Literal text:

> "using `jf_api /Items` ONCE with `IncludeItemTypes=Audio`, `Recursive=true`, `ParentId=${JELLYFIN_MUSIC_LIBRARY_ID}`, `Fields=ArtistItems,Artists,Path` (no `SearchTerm`), then select with jq `(.Artists // [] | length) > 0 and ((.ArtistItems // []) | length) == 0` and collect `.Path`."
> "Pin the recorded set: `D24_CENSUS_BASELINE_N` (the count) and `D24_CENSUS_BASELINE_SHA` … both filled with THIS task's measured values"

Concrete failure scenario: if the `/Items` response is ever paginated or otherwise truncated, the census silently undercounts the 1,244-item library, and the truncated result is pinned as `D24_CENSUS_BASELINE_N/_SHA` on its first run. Every later comparison (including 07-15's after-census, the event that reads DEF-06-45-03's hypothesis) inherits the short baseline, and the pin moves only "with a stated reason" — so a wrong pin is sticky. Partial mitigations exist: the expected-30 prose figure and the separately-recorded Audio count in the same task would probably expose a gross truncation. But nothing mechanically asserts the response covered the library.

Fix: one line in the section — assert `(.Items | length) == .TotalRecordCount` (or pass an explicit `Limit` comfortably above 1,244 and assert the returned count equals the separately-recorded Audio item count), routing a mismatch to `jellyfin_fail` before the pin is read.

Refutation condition: this finding is wrong if the script's `/Items` call sets a `Limit` covering the full library elsewhere in `jf_api`, or if Jellyfin 10.11's `/Items` with no `Limit` is guaranteed to return the full set — in which case the expected-30-vs-measured cross-check is sufficient.

---

**Finding 4 — LOW — 07-12, Tasks 2–3: the P02-before-P04 import order is a stated must_have with no mechanical check**

Literal must_have:

> "D-20: each album is imported through `02-review` and confirmed by the operator in the UI, **in the P-ID order fixed in 07-SAMPLE.md (P02 before P04, so the Benson Boone pair's second arrival meets the ambiguity)**"

Nothing in Task 3's verification asserts the order actually happened — the aunique list records which twin *carries* the disambiguator, but a reversed order import (operator clicks P04 first) verifies cleanly on every criterion while silently voiding the frozen prediction in 07-SAMPLE.md ("state which of P02/P04 is predicted to carry the disambiguator under ordered import"). No safety invariant is violated; the failure is that a must_have truth can be false with no signal. The order is observable after the fact: beets records `added` per item.

Fix: in Task 3's aunique section, read `added` for the two twins from the read-only sqlite dump and assert `P02.added < P04.added`; a violation is recorded as a finding, not a retry demand.

Refutation condition: this finding is wrong if 07-12 Task 3's verification beyond the quoted text (or 07-SAMPLE.md's prediction procedure) already asserts the realised order via `added` or equivalent.

---

**Finding 5 — LOW — 07-12, 07-13, 07-14, 07-15 verify blocks: legitimate hold outcomes are un-acceptable by the automated verify**

Literal texts:
- 07-12 Task 3: `{ /usr/bin/grep -qiE 'OPERATOR ANSWER.*hold-all' "$A" || { … /usr/bin/grep -qE 'P0[2-6] LANDED|P1[0-2] LANDED|P09 LANDED' "$L"; … } }` — but the plan's own resume-signal says "A P-ID with no line is treated as `hold`", so a per-line all-holds answer is legitimate, matches neither `hold-all` nor any `LANDED`, and fails the verify.
- 07-13 / 07-14 / 07-15: `/usr/bin/grep -qiE 'OPERATOR ANSWER:? *` + backtick + `?hold` + backtick + `? *$'` — while every gate's acceptance criterion requires the answer "recorded **verbatim with UTC time**". A line like `OPERATOR ANSWER: hold (2026-09-26T18:22:11Z)` fails the end-anchored pattern, pushing the conditional into the sync/apply branch whose artifacts don't exist, and the verify fails on a correctly-completed hold.

Concrete failure scenario: the operator holds (a first-class outcome in every gate, and 07-12 explicitly frames "A held album is a successful outcome"); the executor commits a correct artifact; the automated verify exits non-zero; the executor is now stuck re-editing a correct artifact or weakening the check. Fail-closed rather than fail-open — this blocks progress, it cannot corrupt anything — which is why LOW.

Fix: match the hold branch the way 07-09 does — `OPERATOR ANSWER.*\bhold\b` — or mandate the timestamp on a separate `OPERATOR ANSWER TIME:` line. For 07-12, treat "zero LANDED lines with every in-scope P-ID dispositioned" as an acceptable verify outcome.

Refutation condition: this finding is wrong if the gate conventions require the answer token to be the entire content of the `OPERATOR ANSWER` line with the UTC time recorded on a separate line — but the four plans' acceptance criteria say "verbatim with UTC timestamp", so as written the two requirements conflict.

---

**Finding 6 — LOW — 07-11, Task 2 gate: no named remedy for the DB-COVERED-no case**

Literal context text:

> "If the undo covered tree, DB and state, the operator re-imports P01 in 02-review with the same candidate … If state was NOT covered, a re-run would be skipped by `incremental`; the sanctioned remedy is a FILE copy of state.pickle out of the arrs snapshot — never a ZFS rollback of that dataset."

Concrete failure scenario: UNDO IMPORT is verified on tree. If it turns out NOT to cover the DB (DB COVERED `no`) — plausibly coupled with STATE COVERED `no`, since both are the same tool — the gate offers `hold`, `rerun`, or `restore-then-rerun` (state.pickle only). The correct safe action (file restore of `library.db` from the same `.zfs/snapshot/pre-07-pilot/beets/config/`, the mechanism D-16 names for "database recovery … a file restore out of the snapshot, only") is unoffered; the operator faces "any other answer is treated as `hold`" at the exact moment the tool has failed twice. Fail-safe by default, but the plan stops mid-flight without its defined next step.

Fix: extend `restore-then-rerun` to "restore the uncovered files (`state.pickle` and/or `library.db`) from the arrs snapshot by file copy", with the same literal-path assertion and prohibition text.

Refutation condition: this finding is wrong if beets.md's documented recovery section (read by the operator at this gate) already names the library.db file-restore route, making the omission presentational rather than real.

### 3. What was checked and held (no finding)

- **Wave/depends_on graph**: fully chained where it matters. 07-09 lists all of 07-01…07-08; 07-10→07-17 is a strict chain; 07-13 additionally names 07-04 (route-dj-album). Every cross-plan artifact read (07-12→07-10, 07-14→07-07, 07-15→07-12, 07-16→07-11/07-09, 07-17→all) is transitively covered. 07-08 needs no dependency on 07-07 (disjoint files).
- **Ordering**: no plan can write the library before the fence. 07-05/07-06/07-07 are read-only or throwaway-scoped with `import.write:no` asserted *before* their imports; 07-08 builds but deploys nothing; 07-09's fence strictly precedes its grant with absent-assertions, RC capture per snapshot, and exact whole-line list-back per name.
- **`git diff --exit-code HEAD --`** is used in the tight form everywhere it matters (07-01, 07-05, 07-08, 07-12, 07-15, 07-17). 07-01's `git diff HEAD~1 --` and 07-08's `git diff --cached` uses are deliberate and correct for their purposes.
- **D-16 rollback prohibition**: restated at the 07-09 fence call site, 07-11 restore call site, 07-14 recovery text, and 07-16 scope fence; every artifact is screened for the unbracketed verb with recipes driven both ways.
- **Criterion 3 evidence**: everywhere ffprobe-on-the-file against read-only sqlite `mode=ro`; `beet ls` named as not evidence (07-01 map row 3); EPERM log lines counted with a driven control.
- **D-14/QUAL-04 design**: the state.pickle coverage test is well-formed — decoded *copy*, never the live file; the pre-undo witness handles even the vacuous case ("path ABSENT pre-undo → finding against the incremental model"), and the restore branch re-asserts sha equality with the fence copy; DB/state/landed-count failures all surface loudly downstream (a skipped re-run shows 0 items).
- **07-16 eligibility**: analysed `written@<older> == 0` — sound, because any mutation (including unlink) dirties directory/ZAP blocks and registers as written; 0 ⇒ zero mutations ⇒ the newer snapshot is the identical undo point. The `@pre-phase5` refusal is enforced at the destroy call site (`! grep -qE 'zfs [d]estroy [^ ]*@pre-phase5'`), not merely by gate options.
- **D-04 register coupling**: 07-04 measures the route script's lines landing in the asserted set *before* registering, moves `D04_EXEMPT_BASELINE` in the same commit with a named reason, leaves `D04_DOC_BASELINE` at 2, uses no env override, and drives the overlay-key half both ways in a throwaway clone with fenced cleanup and a real-repo `git log` absence check.
- **Credential handling**: `jf_api`/`ma_api` process-substitution headers, `$ENV` in jq, mode-600 root gates; artifacts screened (07-14/07-15 verify greps).
- **No FullRefresh anywhere**: the only Jellyfin write is the round-5 targeted `POST /Library/Media/Updated` at file scope (Created/Deleted/Modified per plan), address resolved fresh each time; absence of the forbidden token asserted with driven recipes.
- **MA-last ordering**: MA untouched through 07-10…07-14 (deliberately, including not syncing around the undo cycle), one gated sync in 07-15 with provider filter never empty.
- **Invariant 12**: 07-17 fills only the `measured` column; acceptance requires the instrument/"satisfies when" columns byte-unchanged from the map's first commit and asserts verdict words absent by grep; `REQUIREMENTS.md` asserted untouched in 07-01, 07-11, 07-15, 07-17.
- **D-13 conditionality**: 07-12 enforces the amendment's condition mechanically (deployed diff script sha256-equal-to-repo AND containing the AMBIGUOUS token) before any `unsorted/` staging — the conditional amendment is not just prose.
- **C1–C11**: each has a mechanical carrier — C1 measured-then-verified (07-08 task 1 → 07-09 post-grant readings), C4's two-inbox watchdog asserted at readiness with a *new post-recreate* line, C9 install sha-asserts, C7/C8 retirement recorded with 07-05 sequenced pre-grant and 07-09's gate re-asserting RW=false before proceed.
- **The E6 second measurement** cannot be satisfied by a 3-artist row (two permitted output forms only, NOT TAKEN otherwise), and the F1 stratum target is committed before its eligible set is measured.
- **Frozen oracle rows**: extracted via `git show <anchor>:…`, line-by-line `grep -qxF` loop, two hashers, 132-line count pinned; consumers (07-10/12/13) classify divergences and file findings rather than editing.
- **07-05's dash canary design**: every refusal case targets a disposable sentinel, so even a fail-open fence deletes only the canary; the extracted program text is sha256'd against the committed file (tests what runs, not a restatement).

### 4. Suggestions (non-defects)

- **Consumed staged copies**: after a successful import, the staged copy remains in `_inbox/02-review` (import.copy). Harmless (incremental skip would refuse a re-offer), but they accumulate across the 07-12 batch as UI clutter. Consider recording each staged copy's disposition in the ledger, or a fenced removal after verification.
- **07-08 Task 2 verify**'s YAML parse needs PyYAML on the workstation; note an alternate (the container's `/venv/bin/python` on LXC 100) as the fallback so a missing module fails with an explanation rather than an opaque verify error.
- **07-03's judge**: implement the per-class vacuity check as one shared helper over `CHECKABLE_C{1,2,3}` counters (see Finding 2) so Phase 9 can't inherit three slightly different rules.
- **Census reads**: standardise `TotalRecordCount == returned` assertion on every whole-library Jellyfin read (D-24 census today; anything similar later).
- **07-11 restore branch**: re-read `state.pickle`'s sha256 immediately before the re-run (not only right after the `cp`), so a server-side rewrite in the gap is caught at the moment it matters rather than inferred from a skipped re-import.
- **D04_INV_RE drift**: 07-04 keys the register on `\$BEET_REALLIB`, which works only because the invocation pattern matches variable names; when task 2 measures N, have it also record *which* `D04_INV_RE` alternative matched each line, so a future widening of the exempt file's prose can't silently change the counted set.

---

## Review: pi → ollama-cloud / deepseek-v4-pro:0813

### Cross-AI Plan Review — Phase 7 (Pilot, 12 Albums End to End)

### 1. Summary

**Overall risk: MEDIUM.** These seventeen plans are, as a set, the most internally-consistent and
defensively-written plan set I have reviewed in this project. All twelve safety invariants are
honoured mechanically in the normal path; the fence-before-grant ordering (07-09), the
flask-only `rw` grant (07-08), the copy-not-move discipline, the ffprobe-not-`beet ls` evidence
rule, and the Jellyfin-first/MA-last ordering are all stated and enforced, not merely asserted.
The residual risk is not in the happy path but in two **branch** paths: (a) the D-17 mechanical
destroy's trigger condition in 07-11 is broader than the operator-ratified wording, so a snapshot
destroy can fire on a path the plan itself labels "D-14 stands falsified"; and (b) 07-16's prune
eligibility rests on a `written@… = 0 ⟹ byte-identical undo point` equivalence that is never driven
against a metadata-only change — the exact class (chown) the register's own rows protect. Both are
gated by operator reads and `/gsd-verify 07`, so nothing is hidden, but each is a
weaker-than-ratified trigger on an irreversible act. No HIGH (library corruption / clean data loss /
silent gate-pass) was found; the plan-checker's 0-BLOCKER reading is consistent with my own.

---

### 2. Findings

### Finding 1 — MEDIUM (highest-severity; HIGH-adjacent)
**Plan/task:** 07-11, Task 3 ("execute the chosen re-run path … fire (or hold) D-17 mechanically").

**Literal text quoted:**
> "The trigger (DEF-06-52-01) has FIRED iff: (i) both pre-07-pilot snapshots were listed back in `07-09-fence-and-grant.txt` (quote the lines), AND (ii) this plan's UNDO WITNESS shows TREE COVERED yes, DB COVERED yes, and state covered either by UNDO IMPORT (STATE COVERED yes) **or by the operator-chosen file restore** — i.e. 'rollback exercised' on tree, DB and state."

Compare the operator-ratified trigger in 07-CONTEXT.md § D-15:
> "ROADMAP criterion 1's 'rollback exercised at least once' is discharged by this `UNDO IMPORT` back-out **covering tree, `library.db` and `state.pickle` together** … D-17's mechanical release of `tank/media/Music@pre-06-41-conf04-reprobe` fires on that back-out plus the new snapshot."

And the plan's own Task 2 option text:
> "`restore-then-rerun` … A restore step outside `UNDO IMPORT`; criterion 5's 'no hand-repair' is then for `/gsd-verify 07` to judge, **and D-14 stands falsified.**"

**Failure scenario:** `UNDO IMPORT` fails to cover `state.pickle` (the precise half `beets.md`
flags as unproven). The operator chooses `restore-then-rerun` (a file copy of `state.pickle` out of
the arrs snapshot — D-16's only sanctioned arrs recovery). The plan's condition (ii) then counts
"operator-chosen file restore" as satisfying "rollback exercised on tree, DB and state", and the
mechanical `zfs destroy tank/media/Music@pre-06-41-conf04-reprobe` fires **in the same step** — on
evidence that, by the plan's own words, "D-14 stands falsified" and criterion 5's "no hand-repair"
is compromised. The ratification tied the release specifically to "`UNDO IMPORT` back-out covering
tree, `library.db` and `state.pickle` **together**"; a file-restore path is not that event. The
destroy is irreversible, and it is being released on a trigger the ratification did not name.

**Fix:** Tighten condition (ii) to require `STATE COVERED yes` via `UNDO IMPORT` **natively**.
If `UNDO IMPORT` misses `state.pickle`, record `D-17 TRIGGER: NOT FIRED — state not covered by
UNDO IMPORT` and **hold** `@pre-06-41-conf04-reprobe` (its release then becomes `/gsd-verify 07`'s
and the operator's to adjudicate, not a mechanical same-step destroy). Alternatively, before
execution, get the operator to extend DEF-06-52-01's literal text to name the file-restore path as
an acceptable firing event — but that must happen in the trigger definition, not in the plan that
reads it.

**Refutation condition:** This finding is wrong if
`.planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md` `DEF-06-52-01`'s literal
wording already enumerates "a file restore of `state.pickle` out of `fast/appdata/arrs@pre-07-pilot`"
as one of the events that fires the release (rather than only "`UNDO IMPORT` covering tree, DB and
state together"). The plan text itself only cites "release when Phase 7 Success Criterion 1's two
events have both happened," which does not authorise the broader reading.

---

### Finding 2 — MEDIUM
**Plan/task:** 07-16, Task 1 ("measure every project snapshot, write the register, compute eligibility").

**Literal text quoted:**
> "the register also requires that nothing changed between the two: `zfs get -H -p -o value written@<older> <dataset>@<newer>` returns `0` (bytes written between them) — **then the newer is byte-for-byte the same undo point** and the register can NAME it as covering the older's change."

Set against the register's own rows:
> "`tank/downloads@pre-phase5`: owner Phase 5, undo for 4,750 renames / 751 tag writes / **26,005 chowns**."

**Failure scenario:** The eligibility instrument is the equivalence `written@… = 0 ⟺ "byte-for-byte
the same undo point"`. This is a *new* gate on a destructive act, and per the estate's own
conventions it must be proven able to fail before its zero is trusted (CONVENTIONS §3; §8.3 /
`DEF-06-45-04`: "drive every zero-expecting recipe against a control first"). The plan never drives
`written@` against a **metadata-only** change — a `chown`/`chmod` with no data-block write. If
`zfs get written` does not increment on ownership/metadata changes (which is precisely the change
class `@pre-phase5` / `@pre-phase5-chown` / `@pre-chown` exist to undo — 26,005 chowns), then a
chown-fence snapshot could be marked ELIGIBLE (its "newer" sibling reporting `written@` = 0) and
destroyed on the operator's `release-listed`, while the newer snapshot does **not** in fact hold the
pre-chown metadata. `@pre-phase5` is operator-gated and safe, but `@pre-chown` and
`@pre-phase5-chown` are subject to the mechanical rule.

**Fix:** Before writing any ELIGIBLE row, drive the instrument: take a throwaway snapshot, perform a
`chown` (or `chmod`) on a scratch file with no content change, take a second snapshot, and record
`zfs get written@<older>` of the newer. If it reads `0`, the rule must be amended (eligibility
additionally requires that the register's "undo for" is content-only, or the rule is rejected for
metadata-bearing snapshots). Record the drive in `07-16-prune-decision.txt` the same way 07-02/07-03
record their positive controls.

**Refutation condition:** This finding is wrong if the register or the artifact records a drive
showing `written@` increments on a chown/metadata-only change (or if ZFS `written` is documented in
the repo as including metadata), in which case the `= 0 ⟹ byte-identical` equivalence is sound.

---

### Finding 3 — LOW
**Plan/task:** 07-11, Task 3 `<verify>` (last line).

**Literal text quoted:**
> `git diff HEAD~1 -- .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md | /usr/bin/grep -qE '^\+'`

**Failure scenario:** `^\+` matches *any* line beginning with `+`, including the diff's own
`+++ b/…` header line. The check therefore succeeds whenever the file appears in the diff at all,
even though its intent (per the acceptance criteria) is "gains **only** the dated status line under
`DEF-06-52-01`". It is a "grep that can pass on the wrong thing" — a `+`-line match that does not
discriminate the added *content* from the diff header. The real constraint is enforced only by a
human reading the acceptance criteria, not by this recipe.

**Fix:** Use `^+[^+]` (a content-added line) and, better, assert the added line is the single dated
status line: e.g. `/usr/bin/grep -cE '^\+[^+]'` on the diff equals `1` and the line matches
`DEF-06-52-01`. Drive the recipe against a control first, per convention 8.3.

**Refutation condition:** This finding is wrong if the working-tree/`HEAD~1` relationship at the
time of the verify guarantees the only `+` line is a content line and a separate (unquoted) check
elsewhere counts content additions — the quoted line alone does not establish that.

---

### Finding 4 — LOW
**Plan/task:** 07-13 (frontmatter) and 07-14 (frontmatter).

**Literal text quoted:**
> 07-13: `depends_on: ["07-12", "07-04"]`
> 07-14: `depends_on: ["07-13"]`

**Failure scenario:** 07-13's Task 3 reads `07-EXPECTED-TREE.txt` and `07-SAMPLE.md` (both produced
by **07-06**), and 07-14's Task 1 reads the D-24 census list produced by **07-07**; neither lists
that producer in `depends_on`. Under the current wave ordering this is harmless (07-06 is wave 1,
07-07 wave 2, and both are reached transitively through 07-12 → 07-11 → 07-10 → 07-09). The
fragility is that the dependency is *implicit*: if the 07-12 chain or a future re-wave ever changed,
07-13/07-14 could be scheduled without their oracle/census inputs, and the plan text would still
"pass" a dependency audit. 07-13 lists 07-04 (which is *also* transitively reachable via 07-09) but
omits 07-06, which is the artifact it actually gates on — an inconsistent direct-dependency choice.

**Fix:** Add `07-06` to 07-13's `depends_on` and `07-07` to 07-14's `depends_on` (or document, once,
that transitive deps are not listed and rely on wave ordering). This is a documentation/robustness
fix, not a live race.

**Refutation condition:** This finding is wrong if the planning harness's `depends_on` is defined as
*transitive-closure* (so listing a downstream plan implies all its ancestors), in which case 07-13 →
07-12 already implies 07-06 and the omission is by convention.

---

### 3. What was checked and held (no finding)

- **Fence-before-mutation (invariant 1):** 07-09 Task 2 orders push → host `pull --ff-only` → one-step
  two-dataset fence (list-back asserted) → `library.db`/`state.pickle` file copy → grant. The fence
  strictly precedes the first write; a failed fast-forward or absent-assertion is a STOP before any
  write. Held.
- **`zfs rollback` prohibition on `fast/appdata/arrs` (invariant 2):** forbidden on every branch in
  07-09/07-11/07-14/07-16, written bracketed at the call sites, and the unbracketed verb is
  grepped to 0 with a control drive in the recipes. Held.
- **Copy, never move (invariant 3):** staging by reflink/plain copy, `import.copy`, per-album source
  manifests re-taken and asserted identical in 07-10/07-12/07-13/07-17. Held.
- **ffprobe as evidence, never `beet ls` (invariant 4):** 07-10/07-12/07-13 criterion 3 compare
  ffprobe against a read-only sqlite row; 07-01's map names "`beet ls` is NOT acceptable evidence
  (EPERM is logged as a warning)". Held.
- **Undo covering tree + library.db + state.pickle (invariant 5):** 07-11 decodes a *copy* of
  `state.pickle` and reads `taghistory` membership at four stages; three COVERED verdicts, and the
  failure mode filed as `DEF-07-11-01`. Held (except the D-17 trigger broadening in Finding 1).
- **No snapshot destroyed on a plan's own judgement (invariant 6):** 07-16 is one `autonomous: false`
  gate; 07-11's destroy is the single D-17 mechanical release; `tank/downloads@pre-phase5` is
  operator-gated and never a target. Held (subject to Finding 1's trigger-width concern).
- **Fail-closed / vacuity guard / positive controls (invariant 7):** 07-02 (5-case self-test, red-then-green,
  real-data drive), 07-03 (8-case self-test + near-miss `Op.64.flac` + empty-library UNKNOWN), 07-05
  (canary fence drive under dash). Held.
- **`${VAR:-default}` additive-only (invariant 8):** every new knob (`IMPORT_SWEEP_SCRIPT`, etc.)
  carries the `_Q` render, the override-in-effect → non-green guard, and `⛔ DO NOT REUSE`. Held.
- **Credentials never in argv (invariant 9):** `jf_api`/`ma_api` process-substitution headers, `$ENV`
  for jq, mode-600 root secrets gate; artifacts screened (`! grep -qE '(api_key|Token=|password)'`).
  Held.
- **FullRefresh forbidden / Jellyfin first, MA last (invariant 10):** targeted file-scope
  `POST /Library/Media/Updated` only; MA synced once in 07-15 behind a gate after every write;
  `Full[R]efresh`/`ReplaceAllMetadata=true` grepped to 0 with control. Held.
- **01-auto de-registered / one D-22 commit (invariant 11):** 07-08 builds the single seven-file
  commit; 07-09 asserts the watchdog lists exactly two inboxes post-recreate; prior digest preserved
  by measured `git show <base>:…` two-hash, never copied from 06-04. Held.
- **No plan self-scores VERIFICATION (invariant 12):** 07-17 fills only the `measured` column, asserts
  verdict words absent, `REQUIREMENTS.md` byte-unchanged under `HEAD --`. Held.
- **Cross-plan seams, positive:** 07-02's exit-3 semantics are read consistently by 07-07/07-10/07-12/
  07-13/07-17; 07-03's sweep exit-3 UNKNOWN is read as UNKNOWN in 07-09 (empty library) and expected
  exit-0 only after 32 items; the evidence map's named artifacts match what later plans actually
  write; C7/C8 (oracle retirement) is sequenced correctly (07-05's `--run` is wave 1, pre-grant).
- **Frozen-row arithmetic:** 07-06's 132-line selection (35+32+44+20+1) checks; the S5 pair and the
  rule-2 folder set (403…429) are disjoint from the drawn S5 pair (420/421), so 07-05's read-only
  assertion cannot touch the sample.
- **`git diff --exit-code` forms:** every immutability assertion I found uses `HEAD --` (or
  `git show <base>:…` digests); no bare `git diff --exit-code <path>` that would pass a staged edit.
- **Pinned counts:** 07-04 moves `D04_EXEMPT_BASELINE` 5→5+N with a registered reason and leaves
  `D04_DOC_BASELINE` at 2; 07-03/07-02 add `ST_PLANNED_CASES` to CONVENTIONS §5 in the same commit.
  No raise-to-green detected.

---

### 4. Suggestions (non-defect)

1. **07-12 Task 3, compliant re-path check:** the plan asserts the `beet move -p` invocation is
   "compliant (`-l` on a COPY outside `/config/library.db` AND `-c` overlay)", but the literal
   command (the `docker exec … beet move -p -l … -c …` shape) is not shown in the plan text. Publish
   the exact invocation in the artifact so D-27 compliance is auditable, as 07-04 does for
   `route-dj-album.sh`.
2. **07-07/07-15 D-24 census classification:** a census *change* from baseline is routed to the
   exit-3 (pending) arm, but "measured change" is arguably drift (exit-1 red) rather than "at
   baseline" (exit-3 pending). Harmless today (the script exits 3 regardless), but the header
   should state which of the two a D-24 delta is, so a future reader does not read a red as pending.
3. **07-16, `written@` drive (see Finding 2):** even if the equivalence holds, add the positive
   control drive to the artifact — it is the same "drive every zero-expecting recipe against a
   control" discipline the other plans apply to their sweeps and fences, and the register's rows
   name chowns as the protected change.
4. **07-11 verify grep (Finding 3):** switch `^\+` to `^+[^+]` and pin the added line to
   `DEF-06-52-01`; also consider asserting the D-17 `FIRED`/`NOT FIRED` line and the zero-destroy
   condition are mutually consistent (FIRED ⟺ exactly one issued destroy).
5. **07-13 depends_on (Finding 4):** list `07-06` directly since `07-EXPECTED-TREE.txt` /
   `07-SAMPLE.md` are the artifacts its Task 3 gates on; the current reliance on transitive ordering
   is the one place a future re-wave could silently break the oracle/consumer seam.

---

## Review: pi → github-copilot / gemini-3.8-flash

### Cross-AI Plan Review: Phase 7 — Pilot, 12 Albums End to End

### 1. Summary
**Overall Risk: MEDIUM.** 
The plan suite exhibits extraordinary rigor in structural defense, fail-closed telemetry, and fencing discipline (e.g., dual-dataset ZFS snapshot before deploy, strict duplication of the `fast/appdata/arrs` rollback prohibition, and pre-registered immutable evidence mapping). The risk is classified as MEDIUM rather than LOW primarily due to an enforcement blind spot in the criterion-5 undo verification (vacuous `taghistory` assertion if the inbox path is dropped/relocated by rc6) and a brittle git ancestry verify assertion in plan 07-11 that will fail when executed as a single-commit task. Additionally, several acceptance criteria and automated verify commands introduce subtle pass-throughs or syntax hazards (an unbounded grep regex in 07-16, an unbracketed `zfs rollback` check in 07-10/12/13/14 verify scripts, and a missing pin update in CONVENTIONS.md for the new D-24 census). These are mechanical and evidentiary issues rather than fundamental architectural flaws, and are straightforward to correct.

---

### 2. Findings

### Finding 1 (HIGH) — Plan 07-11 Task 1: Vacuous Undo Witness for `state.pickle` if rc6 Cleans Inbox on Import
- **Severity**: HIGH
- **Plan + Task**: `07-11-PLAN.md` Task 1
- **Literal Text**:
  > `the decoded taghistory membership of the staged P01 source path (expected PRESENT after an import — if ABSENT, record it: then state.pickle never held the path and the undo question is moot for it, which is itself a finding against the incremental model)`
  and in Task 2:
  > `(state) state.pickle sha256 and decoded taghistory membership of the staged P01 path — expected ABSENT`
- **Concrete Failure Scenario**:
  Criterion 5 and QUAL-04 mandate that undo is proven to cover `state.pickle`, because an un-reverted `state.pickle` leaves incremental tracking claiming the folder/files are already done. In beets, `taghistory` records paths that have been imported. However, in beets-flask rc6, staging happens under `/downloads/complete/nzb/_inbox/02-review/<folder>`. If beets-flask rc6 records the underlying inode, or records the resolved source path before copy, or if `taghistory` does not key on the raw staged string, the pre-undo check will observe the staged path `ABSENT`. The prose shrugs: *"if ABSENT, record it: then state.pickle never held the path and the undo question is moot for it"*.
  If this happens, the task proceeds to Task 2, where `STATE COVERED` is evaluated: Task 2 checks if the path is `ABSENT`. Since it was *already* absent before undo, Task 2 reports `STATE COVERED yes` vacuously! The plan then concludes `UNDO IMPORT` covered `state.pickle` when in fact `state.pickle` was untouched, never modified by `UNDO IMPORT`, or keyed on a different path format. This would satisfy the mechanical trigger for D-17 and release snapshot `@pre-06-41-conf04-reprobe` on false evidence.
- **Fix**:
  Assert as an invariant in Task 1 that `state.pickle` has mutated between pre-import (fixture `f6a9a1ad...`) and post-import: `test "$STATE_SHA_POST_IMPORT" != "$STATE_SHA_PRE_IMPORT"`. If the specific staged path string is absent from `taghistory`, locate what key or path *was* added to `state.pickle` (by diffing `state.keys()` or unpickled entries against pre-import). In Task 2, require that the exact delta introduced into `state.pickle` by import has been reverted (`$STATE_SHA_POST_UNDO == $STATE_SHA_PRE_IMPORT` or the added key is removed), rather than checking absence of a path that was never present.
- **Refutation Condition**:
  This finding is wrong if beets-flask rc6 is proven by code inspection to always insert the literal container path `/downloads/complete/nzb/_inbox/02-review/<folder>` into `taghistory` on preview-confirm, AND if `STATE COVERED` explicitly requires that the entry was present in Task 1 before asserting it absent in Task 2.

---

### Finding 2 (MEDIUM) — Plan 07-11 Task 3: `<verify>` Fails Because `git diff HEAD~1` Checks Wrong Commit on Multi-Commit Execution
- **Severity**: MEDIUM
- **Plan + Task**: `07-11-PLAN.md` Task 3
- **Literal Text**:
  > `<automated>cd "$(git rev-parse --show-toplevel)" && A=.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-11-p01-undo-rerun.txt && /usr/bin/grep -qE 'D-17 TRIGGER: (FIRED|NOT FIRED)' "$A" && test "$(/usr/bin/grep -cE 'zfs [r]ollback' "$A")" -eq 0 && test "$(/usr/bin/grep -cE 'zfs [d]estroy' "$A")" -le 1 && { ! /usr/bin/grep -qE 'D-17 TRIGGER: FIRED' "$A" || /usr/bin/grep -qF 'pre-06-41-conf04-reprobe' "$A"; } && /usr/bin/grep -qF 'pre-phase5' "$A" && git diff HEAD~1 -- .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md | /usr/bin/grep -qE '^\+' </automated>`
- **Concrete Failure Scenario**:
  The verify block ends with:
  `... && git diff HEAD~1 -- .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md | /usr/bin/grep -qE '^\+' <`
  First, notice the stray `<` at the very end of the line: `| /usr/bin/grep -qE '^\+' <` (syntax error in bash: `<` with no file operand causes a redirection error and non-zero exit).
  Second, if Task 3 is executed in the working tree, the commit `docs(07-11): P01 undo proven on tree/DB/state, re-run equal; D-17 trigger recorded` touches `deferred-items.md`. `git diff HEAD~1 -- deferred-items.md` inspects the parent commit against `HEAD`. However, if the executor commits in steps or if verification runs before commit (or if there are intermediate commits), checking `HEAD~1` is fragile. But most critically, the stray `<` at the end makes this command abort immediately with `syntax error near unexpected token 'newline'` or `ambiguous redirect`.
- **Fix**:
  Remove the trailing `<` from `<automated>`. Use `git show HEAD -- .planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md | /usr/bin/grep -qE '^\+.*DEF-06-52-01'` to test that the committed change in `HEAD` updated the section.
- **Refutation Condition**:
  This finding is wrong if `<automated>` is stripped of trailing characters by the harness before execution and bash ignores trailing `<`.

---

### Finding 3 (MEDIUM) — Plans 07-10, 07-12, 07-13, 07-14: Verification Shell Commands Grep for Unbracketed `zfs rollback` Which Triggers False Positive on the Ban Notice
- **Severity**: MEDIUM
- **Plan + Task**: 
  - `07-10-PLAN.md` Task 3 `<verify>`
  - `07-12-PLAN.md` Task 3 `<verify>`
  - `07-13-PLAN.md` Task 3 `<verify>`
  - `07-14-PLAN.md` Task 2 `<verify>`
- **Literal Text** (from `07-10-PLAN.md` line 5194):
  > `test "$(/usr/bin/grep -cE 'FullRefresh|zfs rollback' "$A")" -eq 0`
  (repeated verbatim in 07-12 line 5724, 07-13 line 5955, and 07-14 line 6165).
- **Concrete Failure Scenario**:
  CONVENTIONS §8 states: *"any file whose content is counted by a published recipe writes the counted token in bracketed form — `EXIT-CODE BEHAVIOUR CHANGE[D]`, `EXTRA_FORBIDDEN_SUBSTRINGS:[-]` — so the recipe is not itself an occurrence of what it measures."*
  In Plan 07-09, the rule was carefully written as `test "$(/usr/bin/grep -cE 'zfs [r]ollback' "$A")" -eq 0`.
  However, in 07-10, 07-12, 07-13, and 07-14, the automated `<verify>` command explicitly runs:
  `/usr/bin/grep -cE 'FullRefresh|zfs rollback' "$A"`
  Notice that here, `zfs rollback` is NOT bracketed!
  If any tool, script header, CLI output, or fence reminder emitted into the artifact `$A` (e.g. `artifacts/07-10-p01-import.txt`) prints the prohibition notice `zfs rollback on fast/appdata/arrs is FORBIDDEN`, `/usr/bin/grep -cE '...|zfs rollback'` will match it and return non-zero! The automated test will fail despite no rollback having occurred.
  Conversely, if the plan writes the prohibition with bracketed `zfs [r]ollback` (as required by CONVENTIONS §8 and D-16), why does the regex search for the unbracketed literal `zfs rollback`? If someone *did* issue `zfs rollback`, but in prose someone wrote `zfs [r]ollback`, the regex behavior is inverted between plans. Specifically, in 07-09:
  `test "$(/usr/bin/grep -cE 'zfs [r]ollback' "$A")" -eq 0`
  In 07-09, searching for `zfs [r]ollback` means if the prohibition *is* written in bracketed form in the artifact, `grep -cE 'zfs [r]ollback'` matches it! (Because `[r]` in grep regex matches `r`).
- **Fix**:
  Standardize the verify commands across 07-09, 07-10, 07-12, 07-13, and 07-14 to screen for actual command execution rather than raw prose mentions, or consistently use the comment-stripped / command-transcript boundary. If screening for raw tokens, ensure the grep matches unbracketed tokens while allowing bracketed prose:
  `test "$(/usr/bin/grep -v '\[r\]ollback' "$A" | /usr/bin/grep -c 'zfs rollback') -eq 0"`
- **Refutation Condition**:
  This finding is wrong if `artifacts/07-10-p01-import.txt` and subsequent artifacts are guaranteed to never contain the string `zfs rollback` in any captured log, stderr, or warning message.

---

### Finding 4 (MEDIUM) — Plan 07-16 Task 2: Regex in `<verify>` Has Unanchored Trailing Space Matching Any Dataset Suffix
- **Severity**: MEDIUM
- **Plan + Task**: `07-16-PLAN.md` Task 2
- **Literal Text**:
  > `! /usr/bin/grep -qE 'zfs [d]estroy [^ ]*@pre-phase5' "$A" && ! /usr/bin/grep -qE 'zfs [d]estroy [^ ]*@pre-07-pilot' "$A"`
- **Concrete Failure Scenario**:
  The verify command checks:
  `! /usr/bin/grep -qE 'zfs [d]estroy [^ ]*@pre-07-pilot' "$A"`
  In `07-09-PLAN.md`, the snapshots created are:
  `tank/media/Music@pre-07-pilot` and `fast/appdata/arrs@pre-07-pilot`.
  If an output log, script dry-run, or transcript in `$A` lists:
  `zfs destroy tank/media/Music@pre-07-pilot-temp` or if a command had arguments after the snapshot name (such as `zfs destroy fast/appdata/arrs@pre-07-pilot`), the pattern `[^ ]*@pre-07-pilot` matches `@pre-07-pilot` as a prefix, but without an end-of-token delimiter (`($|[[:space:]])`), it does not strictly match the exact snapshot token boundary. More importantly, in the acceptance criteria:
  *"none of `@pre-phase5` or `@pre-07-pilot`; before/after set difference equals the approved set exactly"*
  If the transcript prints a refusal message such as `REFUSED: cannot zfs destroy tank/downloads@pre-phase5`, the grep will find `zfs destroy [^ ]*@pre-phase5` and fail the `<verify>` gate even though the command was refused!
- **Fix**:
  Anchor the command match to command execution lines (e.g. `^(\+ )?zfs destroy ...`), or ensure refusal log text does not format as `zfs destroy <snapshot>`.
- **Refutation Condition**:
  This finding is wrong if `$A` only ever contains lines starting with executed commands and never prints refusal messages or trace text containing the command pattern.

---

### Finding 5 (LOW) — Plans 07-07 & 07-15: `D24_CENSUS_BASELINE_N` Pin Added to `check-music-consumers.sh` Without Registering in `CONVENTIONS.md` §5
- **Severity**: LOW
- **Plan + Task**: `07-07-PLAN.md` Task 2, `07-15-PLAN.md` Task 3
- **Literal Text** (from `07-07-PLAN.md` line 4281):
  > `Pin the recorded set: D24_CENSUS_BASELINE_N (the count) and D24_CENSUS_BASELINE_SHA (sha256 of the LC_ALL=C-sorted path list, newline-terminated)... (CONVENTIONS §5)`
- **Concrete Failure Scenario**:
  `CONVENTIONS.md` § 5 ("Pinned counts: the trap, and the remedy") exhaustively enumerates all pinned symbols in the estate (`DECLARED_INTERP_EXPECTED`, `TAGGER_DEF_EXPECTED`, `ST_PLANNED_CASES`). Plans 07-02 and 07-03 explicitly update `CONVENTIONS.md` §5 when introducing `ST_PLANNED_CASES` for `diff-music-tags.sh` and `check-music-import.sh`.
  Plan 07-07 introduces two new pins into `check-music-consumers.sh` (`D24_CENSUS_BASELINE_N` and `D24_CENSUS_BASELINE_SHA`), and 07-15 moves them, invoking CONVENTIONS §5. However, neither 07-07 nor 07-15 includes `CONVENTIONS.md` in `files_modified`, nor do they add these pins to the index in `CONVENTIONS.md` §5. This leaves `CONVENTIONS.md` out of sync with the codebase's active pins.
- **Fix**:
  Add `CONVENTIONS.md` to `files_modified` in `07-07-PLAN.md` and append `D24_CENSUS_BASELINE_N` to the live pins index in `CONVENTIONS.md` § 5.
- **Refutation Condition**:
  This finding is wrong if `CONVENTIONS.md` §5 is intended only for test-case counters and not data baseline pins.

---

### 3. What Was Checked and Held (No Finding)

1. **Ordering of Fence vs Mutation (Safety Invariant 1 & E3)**:
   - Verified that in `07-09-PLAN.md` Task 2, `zfs snapshot tank/media/Music@pre-07-pilot` and `zfs snapshot fast/appdata/arrs@pre-07-pilot` are executed and asserted via `zfs list` *before* the D-22 commit is deployed and before compose is updated to `:rw`.
   - Verified that prior plans (07-01 through 07-08) perform zero library writes; `07-05` (oracle run and rule 2 assertion) operates strictly inside container tmpfs `/tmp/p6-*` with `import.write: no` and overlay-redirected paths.

2. **Rollback Prohibition on `fast/appdata/arrs` (Safety Invariant 2 & D-16)**:
   - Verified that `zfs rollback` on `fast/appdata/arrs` is explicitly banned across all plans.
   - Verified that recovery for DB/state is specified exclusively as single-file copies from `/mnt/fast/appdata/arrs/.zfs/snapshot/pre-07-pilot/beets/config/`.

3. **Copy, Never Move (Safety Invariant 3 & Criterion 8)**:
   - Verified that `config.yaml` enforces `copy: yes` / `move: no`.
   - Verified that source directories are snapshotted in `07-07` via per-file SHA256 and size manifests and verified identical after import in `07-10`, `07-12`, `07-13`, and `07-17`.

4. **`ffprobe` as Ground Truth (Safety Invariant 4 & Criterion 3)**:
   - Verified that no plan accepts `beet ls` as proof of tag modification on disk. Plans 07-10, 07-12, 07-13, and 07-17 invoke `ffprobe -show_format -show_streams` and assert match against DB rows, checking ownership from atlantis as real root (`568:568`).

5. **Mechanical Release of `@pre-06-41-conf04-reprobe` (Safety Invariant 6 & D-17)**:
   - Verified that Plan 07-11 Task 3 triggers `zfs destroy tank/media/Music@pre-06-41-conf04-reprobe` *only* when the trigger is evidenced as `FIRED` (fence listed back AND undo witnessed on tree, DB, and state).
   - Verified that `tank/downloads@pre-phase5` is completely excluded from destruction across all plans.

6. **Additive-Only Overrides and Pinned Counts (Safety Invariant 8 & CONVENTIONS 4, 5)**:
   - Verified that knobs in `07-03` (`check-music-import.sh`), `07-04` (`route-dj-album.sh`), and `07-08` (`quick-health-check.sh`) strictly enforce non-zero/fatal exits when non-default values are supplied.
   - Verified that `D04_EXEMPT_BASELINE` is incremented in the exact commit adding new invocations with reason stated.

7. **Jellyfin First, Music Assistant Last, No FullRefresh (Safety Invariants 9, 10 & D-24, D-25)**:
   - Verified that Music Assistant sync is withheld during all individual import and undo tasks (07-10, 07-11, 07-12, 07-13, 07-14) and executed exactly once in `07-15` behind a blocking human gate.
   - Verified that Jellyfin updates use targeted `POST /Library/Media/Updated` at file scope; `FullRefresh` and `ReplaceAllMetadata=true` are strictly forbidden and screened by grep.
   - Verified credentials are passed via process substitution or `$ENV` in jq, never in argv.

8. **Single D-22 Commit Structure (Safety Invariant 11 & D-21, D-22)**:
   - Verified that Plan 07-08 stages all seven touched files (`flask.yaml`, `beets.yaml`, `flask-config.yaml`, `config.yaml`, `quick-health-check.sh`, `check-music-freeze.sh`, `beets.md`) into a single commit, preserving previous digests and de-registering `01-auto`.

9. **Verification Isolation (Safety Invariant 12 & D-31)**:
   - Verified that no plan self-declares verification passes; Plan 07-17 populates only the `measured` column of `07-EVIDENCE-MAP.md` with raw counts, leaving criterion evaluation to `/gsd-verify 07`.

10. **Wave and Dependency Sequencing**:
    - Checked wave order: Wave 1 (07-01, 07-02, 07-05, 07-06) -> Wave 2 (07-03, 07-07) -> Wave 3 (07-04) -> Wave 4 (07-08) -> Wave 5 (07-09) -> Wave 6 (07-10) -> Wave 7 (07-11) -> Wave 8 (07-12) -> Wave 9 (07-13) -> Wave 10 (07-14) -> Wave 11 (07-15) -> Wave 12 (07-16) -> Wave 13 (07-17). All artifact handoffs respect this DAG.

---

### 4. Suggestions

1. **Clarify Reflink Support on Atlantis ZFS**:
   - In `07-10-PLAN.md` Task 1 (and 07-12, 07-13), the staging command uses `cp -R --reflink=always`. ZFS on Linux does not support block cloning (`--reflink=always`) unless the `block_cloning` pool feature is enabled and supported by the kernel/coreutils. The plan already includes fallback prose (*"If reflink is refused... use a plain cp -R"*), but using `--reflink=auto` or checking `zpool get feature@block_cloning tank` beforehand would avoid deliberate EOPNOTSUPP errors in the execution transcript.
2. **Explicit Verification of Empty Directory Cleanup**:
   - In `07-11-PLAN.md` Task 2, `UNDO IMPORT` leaves behind empty directories if beets-flask only unlinks files. The plan notes this as informational (*"an empty directory is noted, not hand-removed"*). It would be beneficial to record whether Jellyfin treats an empty directory as a ghost album when rescanned after undo.
3. **Double-Check `python3` Availability on Atlantis**:
   - Tasks in 07-08, 07-09, and 07-16 execute commands on `atlantis` as real root. Note that Proxmox VE hosts typically have system Python at `/usr/bin/python3`, but lack `pyyaml` by default. Plan 07-08 Task 1 suggests parsing with `python3 -c 'import yaml...'` on LXC 100, which is correct (LXC 100 has python/yaml), but care should be taken never to assume `pyyaml` is installed on `atlantis`.

---

## Consensus Summary

### Agreed strengths (named by 4+ reviewers)
- The fence precedes the grant in one remote step. Both snapshots are asserted to be absent first, then listed back by exact name, and nothing writes the library before 07-09.
- `zfs rollback` on `fast/appdata/arrs` is prohibited at every recovery call site, and recovery is by file copy only.
- Copy-not-move staging, with source manifests re-checked. `ffprobe` against a read-only sqlite row is the evidence, never `beet ls`.
- Jellyfin first with file-scope updates only, and no `FullRefresh`. MA syncs once, behind a gate, in 07-15.
- D-22 is one flask-only commit that preserves the previous digest. 07-17 fills only the measured column, and `/gsd-verify 07` scores.
- 07-02's exit-3 AMBIGUOUS contract is consumed consistently downstream, and the frozen oracle rows are commit-anchored.

### Agreed concerns (priority order)
1. **G-01 + G-02: 07-11's D-17 trigger.** Fix both together. FIRED requires a *paired* witness from `UNDO IMPORT`: the entry is PRESENT before the undo and ABSENT after it, on the key that was actually written, for tree, DB and state, **and** the re-run must be proven equal before the destroy. The restore branch writes `D-17 TRIGGER: NOT FIRED` and holds the snapshot for 07-16's operator gate.
2. **G-04 + G-05 + G-06: 07-09 / 07-11 state handling.** Stop beets-flask around any `state.pickle`/`library.db` file restore and re-decode after restart. Hash the snapshot's view against the safety copy. Gate (don't just record) the post-grant `copy`/`move` readings. Add a partial-fence branch.
3. **P-01: measure MA's automatic sync before 07-10.** If it runs periodically, the "MA last" invariant is advisory until a barrier exists.
4. **G-07 / G-08 / G-09: cross-plan seams.** Rebuild the aunique inventory after 07-13. Make 07-12's precondition a *passed* equality, not "LANDED". Give each hold its own ledger state.
5. **G-10: hold-branch verify regexes** (two reviewers). A correct hold must not fail its own verify.

### Divergent views
- **Is the state witness sound?** Kimi says yes. Gemini, Astra and Grok say no. Graded **no** (G-02).
- **Overall risk:** HIGH from Astra, Copilot and Grok; MEDIUM from Gemini, DeepSeek and Kimi. After grading, the two confirmed HIGHs are both in one paragraph of one plan (07-11 T3) and have one fix, so the set is **MEDIUM once G-01/G-02 are fixed**.
- **`written@ = 0` as the pruning criterion:** DeepSeek doubts it; Kimi clears it. Graded sound on ZFS semantics, but not driven.
