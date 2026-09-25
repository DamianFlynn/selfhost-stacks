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


---
---

# Cross-AI Plan Review — Phase 7 (round 2, 2026-09-25)

*Appended, not overwritten: round 1 above is cited by its G-/P- IDs from the plans and from commit
`9c60a78`. Round 2 uses its own namespace, **`P7R2-01` … `P7R2-21`** (CONVENTIONS §13). Nothing
in round 1 above was edited.*

The same six reviewers from five model families as round 1 were used: pi → `gpt-6-astra`,
`gemini-3.8-flash`, `kimi-k3`, `grok-4.7` and `deepseek-v4-pro:0813`, plus copilot → `gpt-5.5`
(166 credits, 2m39s). All six passed a two-word probe first. They all got the same 652 KB prompt:
round-2 instructions, PROJECT (80 lines), the roadmap section, the six requirements,
CONVENTIONS.md, 07-CONTEXT.md, round 1's graded findings and consensus, the unified diff of the
replan (`4805936..9c60a78`, `-U1`), and all 17 plans line-numbered. The prompt set three tasks in
order. **(1)** Verify each round-1 fold as CLOSED / PARTIAL / NOT CLOSED, where a fold present in
prose but not enforced by a verify or STOP counts as PARTIAL. **(2)** Hunt five named failure
modes the replan could have introduced (FM-1 prose not enforced, FM-2 one-sided seam, FM-3
branch with no exit, FM-4 destructive step not waiting on its guard, FM-5 vacuous or
self-matching regex). **(3)** Report any HIGH that round 1 missed. Every finding needed a literal
quote and a refutation condition.

**Orchestrator error, recorded:** the prompt's safety invariant 1 said the fence and the grant
are taken "in the same remote step". D-16 says the *two snapshots* are taken in ONE remote step;
the grant runs on a different host, LXC 100. Astra's HIGH R2-OAI-01 was produced by that
over-statement and is refuted below. It was the prompt that was wrong, not the plan.

## Graded Findings — round 2 (orchestrator, 2026-09-25)

Every CONFIRMED row below was re-read against the live plan text at the cited line. Two were
also *driven* by a reviewer in throwaway repositories (astra: P7R2-03 and P7R2-08c).

### Fold scorecard (22 round-1 items)

| Reviewer | CLOSED | PARTIAL | Notes |
|---|---|---|---|
| gemini | 22 | 0 | Its "all closed" is **refuted** by P7R2-01/02/05/06 |
| deepseek | 22 | 0 | "Every safety-relevant fold is mechanically enforced" is **refuted** by P7R2-01/02 |
| kimi | 21 | 1 (G-13) | Marked G-06 CLOSED, then found its two new seams (P7R2-01, -04) |
| copilot | 21 | 1 (P-01) | |
| grok | 14 | 8 | |
| astra | 12 | 10 | Several PARTIALs are verify-strength points, graded LOW below (P7R2-17) |

**Graded:** the prose of all 22 folds landed, and none is NOT CLOSED. **G-01 and G-02, the round-1
HIGHs, are closed in the action text** (all six agree), but their *verify* has the P7R2-02 hole.
The folds with real residuals are G-02 via 07-01's map (P7R2-06), G-05/G-06 via the new 07-09
branches (P7R2-01, -04, -05), G-08 at verify level (P7R2-08a, -09), G-10's lesson recurring
(P7R2-08) and P-02 (P7R2-07).

### CONFIRMED — act on these

| # | Sev | Plan | Finding | Raised by | Evidence |
|---|-----|------|---------|-----------|----------|
| P7R2-01 | **MED** | 07-09 T2 verify | **The verify fails open on the grant.** Its STOP disjunct `grep -qE 'STOP STATE 07-09-(PARTIAL-FENCE\|IMPORT-KEYS-FAIL\|INBOX-NOT-EMPTY)' "$L"` reads the whole *append-only* ledger. So after a partial fence and then a *successful* `resume-partial-fence`, the historic token satisfies it, and none of the grant's evidence is checked: `listed back`, `RW=true`, the watchdog, and `POST-GRANT IMPORT KEYS: PASS` (the G-05 fold). This is the only fail-**open** verify found this round, and it sits on the phase's first write. | kimi (**singleton**) | 07-09:278 |
| P7R2-02 | **MED** | 07-11 T3 verify | **The destroy count is not bound to the verdict in either direction.** `test "$(grep -cE 'zfs [d]estroy' "$A")" -le 1` is unconditional. So `FIRED` with **zero** issued destroys passes, and the ledger and register then record a destruction that never happened. `NOT FIRED` with **one** destroy also passes, although the action says "If NOT FIRED: issue nothing". The set-difference proof exists only in acceptance prose. | copilot CP-02, grok PI-02 (opposite halves), gemini (suggestion) | 07-11:317, 324 |
| P7R2-03 | **MED** (astra: HIGH) | 07-12 T2/T3, 07-13 T2/T3 verify | **Disposition completeness is not checked.** The T2 verify needs *one* recognised `DISPOSITION` line. T3's `grep -cE '^DISPOSITION P[0-9]{2}: imported' -eq 0` shortcut then reads an absent row as "all held". Astra **drove** the exact recipes: an artifact whose answer says `P03 imported` but whose only row is `DISPOSITION P02: hold` gets **T2 RC 0, T3 RC 0** in both 07-12 and 07-13. An imported album then needs no `LANDED` evidence. | astra (driven), copilot CP-01, deepseek (suggestion) | 07-12:147, 203; 07-13:142, 195 |
| P7R2-04 | MED | 07-09 T1/T2 | **The new STOP tokens have no re-entry.** After `07-09-IMPORT-KEYS-FAIL` or `07-09-INBOX-NOT-EMPTY`, both snapshots exist, the grant is deployed and the writer is stopped. T1's only re-entry branch is keyed on `07-09-PARTIAL-FENCE`, and its normal reading asserts both snapshots ABSENT, so the result is COULD NOT RECONCILE. The watchdog-absent STOP (07-09:259) has no token at all. This is G-06 recurring one branch later: it fails closed, but breaks D-18 resumability. | astra OAI-04, kimi CL-02, grok PI-06 (part) | 07-09:108, 255-260 |
| P7R2-05 | MED | 07-10 T1 | **07-10 does not read how 07-09 ended.** Its preconditions ("both pre-07-pilot snapshots present, RW=true, watchdog lists two inboxes, `_inbox/02-review` holds no audio, `library.db` items 0") are all true after `07-09-IMPORT-KEYS-FAIL` once someone restarts the writer. It never reads the ledger's newest 07-09 token and never re-reads effective `import.move`, so the G-05 gate can be walked past. That is invariant 3. | grok PI-06 | 07-10:85-86 |
| P7R2-06 | MED | 07-01 T1 → 07-17 | **One-sided seam on G-02.** The evidence map's criterion-1 row still registers the absence-only witness: "file count 0 at the destination … `taghistory` no longer holding the staged source path". 07-17 scores with "exactly those" pre-registered instruments. So `/gsd-verify 07` would score the undo on the witness round 1 refuted, not on 07-11's paired `P01 STATE KEY(S)` set difference. | astra (G-02 PARTIAL), grok (suggestion) | 07-01:105-113 |
| P7R2-07 | MED | 07-15 T3 | **P-02's fold contradicts itself.** It accepts `one album with two provider mappings per track` as a twin representation to record "with no verdict attached", yet the preceding assertion requires each album's mapped paths to be "all under that directory (no track from another directory mixed in)". If MA merges the Benson Boone twins, criterion 6 goes falsely red. | astra | 07-15:188-196 |
| P7R2-08 | MED (as a class; each LOW) | several | **G-10's lesson recurs on four new branches: a correct outcome fails its own verify.** All four fail closed, so each one pressures the executor to invent a pass. **(a)** 07-12 T1 requires `EQUALITY VERDICT\|NEW-IMPORT VERIFIED` in `$A` *before* the `STOP STATE 07-12-PRECONDITION` arm, but 07-11's hold tokens (`T1-HOLD`, `T2-HOLD`, `TREE-NOT-COVERED`, `RESTORE-FAIL`, `RECONCILE-FAIL`) carry neither string (gemini DF-01, deepseek RW-01). **(b)** On the success path 07-09 step 5 writes a header saying "STOP state" in lowercase, but the verify greps `STOP STATE` unconditionally (grok PI-03, deepseek and kimi suggestions). **(c)** On T1 re-entry after `PARTIAL-FENCE`, T1's verify requires zero unbracketed `zfs snapshot` in an artifact that T2 has already written to (astra, driven). **(d)** 07-11 T1's `RECONCILE-FAIL` presents no gate, but T1's verify requires `PRE-UNDO WITNESS` and `OPERATOR ANSWER` (astra). | gemini, deepseek, grok, kimi, astra | 07-12:102; 07-09:169, 174, 273-276, 278; 07-11:106, 150 |
| P7R2-09 | LOW | 07-12 T1 verify | **Too loose as well as too strict.** `grep -qE 'EQUALITY VERDICT\|NEW-IMPORT VERIFIED'` also matches `EQUALITY VERDICT: FAIL`, so in the verify G-08's PASS requirement is prose only. A FAIL ledger plus staged albums with no STOP written passes. | grok (G-08 PARTIAL) | 07-12:102 |
| P7R2-11 | LOW (gemini: HIGH) | 07-13 T3 verify | `imported-no-route` matches neither `imported(-asis)?$` nor `imported `, so the routing arm is skipped, and nothing requires the `DEF-07-13-NN` finding that the action mandates for an unrouted album. | gemini DF-02 | 07-13:181, 195 |
| P7R2-12 | LOW | 07-13 T3 | `ADDED ORDER` has no held-album arm. 07-12 has `ADDED ORDER (P02<P04): NOT APPLICABLE`, and 07-13 permits per-album holds, so with P07 landed and P08 held "P07 precedes P08" cannot be evaluated. | kimi CL-04 | 07-13:185-187 vs 07-12:194 |
| P7R2-13 | LOW | 07-03 | The `<verification>` footer still says "`--self-test` 8/8"; the task pin is `ST_PLANNED_CASES=10`. | astra, kimi, grok | 07-03:300 vs 157 |
| P7R2-14 | LOW | 07-15 T3 verify | `MA returns [0-9]+ of [0-9]+` accepts `3 of 3` and `0 of 0`. G-11's "never satisfied by a 3-artist row" is prose only in the verify. | grok PI-05, astra | 07-15:242 |
| P7R2-15 | LOW | 07-16 T2 | After a correct `REFUSED:` line, "the before−after set difference must equal exactly the approved set" is unreachable. There is no partial-prune outcome, and the blanket "update each row: destroyed" would misrecord the refused name. | astra OAI-05 | 07-16:173-179 |
| P7R2-16 | LOW | 07-11 T3 verify | The FIRED arm reads *labels*, not measurements. It never positively requires `^DISPOSITION: rerun$` (only the absence of `restore`), and `STATE COVERED yes \(` is satisfied by `yes (pre 0 → post 0)`. Condition (iii) and the paired-reading rule are enforced by the producer's prose alone. | grok (G-01/G-02 PARTIAL), deepseek (suggestion) | 07-11:317 |
| P7R2-17 | LOW | 07-07/12/13/15/17 verify | Several folds are checked by a heading or token grep only: G-07 (`AUNIQUE INVENTORY (rebuilt after 07-13)`), G-12 (`^ADDED ORDER`), G-13 (no check of "not comparable" or of the byte-unchanged 144 sentence), and P-03 (`grep -qF 'TotalRecordCount'` in the script, which a comment satisfies). None is a false pass of an action, but each fold would survive an edit that deleted its substance. | astra, grok, kimi (G-13) | 07-15:114; 07-12:203; 07-17 T2; 07-07:177 |

### PLAUSIBLE — cheap to settle before execution

| # | Sev | Plan | Finding | Raised by | Status |
|---|-----|------|---------|-----------|--------|
| P7R2-10 | MED (astra: HIGH) | 07-11 → 07-12 | **Equality is substituted for quality.** A reproducibly *bad* run 1 (a criterion 3/4/7 finding from 07-10) can re-run to `EQUALITY VERDICT: PASS`, and 07-12's precondition needs only PASS. 07-11 T1's `ADJUDICATION` puts those findings in front of the operator, but its outcome is not a mechanical precondition of 07-12. | astra OAI-02 | Text matches. Whether the operator's adjudication at the 07-11 gate is the intended quality gate is **an operator decision**: if it is, write that down; if not, add a `QUALITY: PASS` precondition. |
| P7R2-18 | LOW | 07-13 T3 / 07-04 | If `--apply`'s `modify` commits and `move` fails, the album is left half-routed with no named STOP token, and 07-15 would treat the ledger's `LANDED` path as final. | grok PI-07 | Not driven |
| P7R2-19 | LOW | 07-09 T2 | A `hold` chosen at re-entry after `PARTIAL-FENCE` writes the only hold text on offer, "no fence taken, no grant, no album landed", which is false with the `tank` snapshot present. | astra (G-06 PARTIAL) | Text matches 07-09:190 |
| P7R2-20 | LOW | 07-11 T2 | After `DB COVERED no`, a `hold` writes `07-11-T2-HOLD: P01 BACKED OUT by UNDO IMPORT … albums landed: none` while DB rows remain. | astra (G-09 PARTIAL) | Text matches 07-11:188, 230 |
| P7R2-21 | LOW | 07-15 T2 | P-01's later window: `MA SYNC SINCE 07-10: FOUND` is recorded as a finding, not a STOP. | copilot, astra | By design: blocking the manual sync afterwards cannot un-write entries MA never purges. The open question is only whether FOUND should block criterion 6's closure (**operator**). |

### REFUTED — do not act on these

| Finding | Raised by | Why refuted |
|---------|-----------|-------------|
| **HIGH**: fence and grant are separate remote operations, violating invariant 1 | astra OAI-01 | Invariant 1 was the orchestrator's over-statement. D-16 (07-CONTEXT.md:218; 07-09:15, 45, 202) scopes "ONE remote step" to the **two snapshots**. The grant is on LXC 100 and follows the list-back in the same task. |
| MED: the G-05 gate reads `check-beets-config.sh`, not the server's effective value | grok PI-01 | `scripts/check-beets-config.sh` ARM 1 **is** the server-committed config (`get_config(commit_to_beets=True)` → `beets.config.dump`, header lines 26-45), the exact value 07-08 says governs imports. |
| MED: the restore copies before its hash check (FM-4) | grok PI-04 | The snapshot's view was proven byte-equal to the safety copy at 07-09 T2 (the G-04 fold), and a snapshot is immutable, so the post-copy sha256 is the right check. At most LOW: there is no roll-forward step if the `cp` itself fails partway. |
| MED: `TREE COVERED yes \(` is brittle to punctuation | gemini DF-03 | The format is specified, with its pre → post readings, in 07-11's acceptance (07-11:226), and it fails closed. The real weakness in that regex is P7R2-16. |
| Severity of DF-01 (HIGH) and DF-02 (HIGH) | gemini | Both confirmed, reclassified as P7R2-08a (fails closed) and P7R2-11 (a record gap, not a write). |
| **Clear**: "all 22 folds CLOSED" / "every safety-relevant fold mechanically enforced" | gemini, deepseek | P7R2-01, -02, -05 and -06. |

### What the grading says about the roster

- **Kimi found the only fail-open defect (P7R2-01) and nobody else did.** Read the singletons again: convergence locates design risk, it doesn't rank impact.
- **Astra was again the most productive and the most over-rated.** It had 3 HIGHs: one refuted (caused by the prompt), and two downgraded to MED, of which one is confirmed and one plausible. It also *drove* two recipes, and those were the round's best-evidenced findings.
- **The two cleanest scorecards (gemini and deepseek, 22/22 CLOSED) were the least reliable clears.** Gemini's first finding worked its way through several wrong theories in visible text before landing on a real one. As in run 5, read to the end.
- **Copilot and Grok found opposite halves of P7R2-02**, each missing the other's direction.

---

## Consensus Summary — round 2

### Agreed strengths (named by 4+ reviewers)
- G-01/G-02 are fixed in the action: D-17 is a four-condition conjunct, restore branches are NOT FIRED by construction, and equality is written before the destroy step.
- Restores are quiescent: stop, then `State.Running=false`, then literal `cp`, then start, readiness and re-decode. `zfs [r]ollback` of `fast/appdata/arrs` stays forbidden at every call site.
- The snapshot view is sha256-compared to the safety copy before the grant (G-04), and the post-grant import keys are a parsed-value gate (G-05).
- Bracketed ban greps (G-15), the diff-header filter (G-14), and the 07-16 `ISSUED:`/`REFUSED:` grammar (P-06) all check out.
- The 07-11 → 07-12 PASS-verdict tokens match on both sides (G-08) in the action text.

### Agreed concerns (priority order)
1. **07-09's new recovery machinery (P7R2-01, -04, -05, -08b/c).** Make the Task 2 verify answer-keyed on a normalised `DISPOSITION:` line and not on ledger history. Add a re-entry for `IMPORT-KEYS-FAIL`, `INBOX-NOT-EMPTY` and the watchdog-absent STOP. Write the success entry as a named token. Make 07-10 STOP unless 07-09's newest token is the granted token, backed by a fresh parsed `move=false`.
2. **07-11 T3 verify (P7R2-02, -16).** On FIRED require exactly one `ISSUED: zfs destroy tank/media/Music@pre-06-41-conf04-reprobe RC=0` (07-16's grammar) and a one-name set difference. On NOT FIRED require zero. Positively require `^DISPOSITION: rerun$`.
3. **Disposition completeness (P7R2-03).** Loop the expected P-ID set from 07-06's `### EXECUTION ORDER` in 07-12/07-13 verifies. Require exactly one row per P-ID, and never infer "all held" from a zero count.
4. **"A correct stop passes its own verify", applied to every new branch (P7R2-08).** This is the third round in which this lesson has had to be re-applied. Consider one fixture per STOP token, run against each verify.
5. **07-01's evidence map row 1 (P7R2-06)** must name the paired `P01 STATE KEY(S)` witness before the map is registered.

### Divergent views
- **Overall risk:** astra HIGH; gemini, copilot, grok, kimi and deepseek MEDIUM. Graded **MEDIUM**. No confirmed finding permits a destructive act the plans forbid: P7R2-02's destroy is still gated by the action's own FIRED rule, and P7R2-05 requires someone to restart a writer the plan stopped. But P7R2-01 is a fail-open verify on the first library write and should be fixed before 07-09 runs.
- **Is P-01 closed?** gemini, deepseek, grok and kimi say yes; copilot and astra say partial. Graded closed *for what can be closed* (P7R2-21).
- **Is equality enough for 07-12 (P7R2-10)?** Astra only. Settle it with the operator, not by replanning.

---

## Round 2 raw reviews

The reviews below are unedited, except that Copilot's output was ANSI-stripped and cut to its final
clean pass. Its raw stream interleaved three partial drafts with tool-call lines.


## Round 2 Review: pi → github-copilot / gpt-6-astra

### 1. Summary

**Overall risk: HIGH.** The replan substantially improves the destructive-operation controls: file restoration now requires a stopped writer, snapshot contents are hash-compared with the safety copies, effective import flags have STOP conditions, and D-17 excludes restoration and waits for an equality verdict. However, under the requested mechanical-enforcement standard, **12 findings are CLOSED and 10 are PARTIAL**. Important residuals include MA’s lack of a forward-looking sync barrier and incomplete hold/resume handling. New defects include a demonstrated zero-disposition verification bypass, equality being accepted without proving a good import, and the fence and grant remaining separate remote operations. This review covers the supplied current plans and replan diff; executable verification probes were run only in disposable local repositories, not against the estate.

### 2. Fold verification

“CLOSED” means closed by the planned mechanism—not that an unexecuted implementation has been validated. Each PARTIAL row includes a specific condition that would refute the residual finding.

| ID | CLOSED/PARTIAL/NOT CLOSED | Evidence — plan:task + literal quote | Note |
|---|---|---|---|
| **G-01** | **CLOSED** | **07-11:T3, lines 284–294:** “produced by `UNDO IMPORT` ALONE”; “the Task 2 answer was `rerun`”; “The file-restore branches, `undo-rerun-other`, any VACUOUS or `no` verdict, and an EQUALITY FAIL are NOT FIRED by construction”. Verify also checks `! /usr/bin/grep -qE '^DISPOSITION: restore' "$A"`. | The restoration exclusion now reaches both the destructive branch and its verify. **07-16:T1** explicitly consumes NOT FIRED and requires its own eligibility and operator gate. |
| **G-02** | **PARTIAL** | **07-11:T1–T3:** introduces `P01 STATE KEY(S)`, paired readings and equality-before-trigger. But **07-01:T1, lines 111–113** still registers destination count zero, DB count zero and state “no longer holding the staged source path”. **07-17:T1** says “the pre-registered instrument per criterion — use exactly those”. | The local D-17 rule is substantially repaired, but the immutable evidence-map producer still specifies the old absence-only/staged-path witness. Also, T3’s verify recognizes labels such as `STATE COVERED yes \(`, not the actual paired measurements. **Refute:** update the map’s prescribed witness before registration, and add a check rejecting zero-before/zero-after or wrong-key evidence even when labelled `yes`. |
| **G-03** | **CLOSED** | **07-03:T1:** “ANY class whose checkable count is 0 → UNKNOWN”; explicit all-singleton and orphan fixtures; automated verification executes `bash scripts/check-music-import.sh --self-test` with `ST_PLANNED_CASES=10`. | Both original gaps have executable-test requirements. The filesystem scope is explicitly directories containing beets items, not the entire legacy library. A stale footer remains, reported separately below. |
| **G-04** | **CLOSED** | **07-11:T3, lines 249–267:** stop writer, assert `State.Running` “reads `false` — STOP if it does not”, restore, restart, re-decode. **07-09:T2:** snapshot hash “must EQUAL” its safety copy; mismatch/unreadability “is a STOP”. | Ordering now puts writer quiescence before replacement and validates state after restart. The snapshot-view check is no longer `ls -l` evidence. |
| **G-05** | **CLOSED** | **07-09:T2, lines 249–259:** require parsed `copy = true`, `move = false`, `write = true`; “On FAIL, and on any reading that could not be taken: STOP”; recount all three inboxes and stop the writer on non-zero. | The requested observations became gates. Recovery from the newly introduced stopped-writer states is a separate new defect below. |
| **G-06** | **PARTIAL** | **07-09:T1/T2:** adds `resume-partial-fence` and `07-09-PARTIAL-FENCE`. But T2’s hold action still says “no fence taken, no grant, no album landed”; T1’s verify requires zero occurrences of `zfs (snapshot|destroy|rollback) ` in the entire artifact. | Holding after a partial fence writes a false current state. Re-entering with the earlier snapshot transcript retained also fails T1’s verify; this was reproduced locally. **Refute:** a partial-fence-aware hold preserving the existing snapshot state, plus attempt-scoped verification that accepts the retained earlier snapshot operation. |
| **G-07** | **PARTIAL** | **07-15:T1:** “AUNIQUE INVENTORY (rebuilt after 07-13)”; T3’s `read_first` and `AUNIQUE_ROWS` construction both consume it. T1 verify only checks `/usr/bin/grep -qF 'AUNIQUE INVENTORY (rebuilt after 07-13)' "$A"`. | The producer/consumer references are repaired, but a heading-only inventory still passes: no verify or STOP checks inventory coverage against landed albums, inclusion of DJ candidates, or equality with `AUNIQUE_ROWS`. **Refute:** a set-comparison check that fails when a qualifying DJ album is omitted or the standing rows differ from the rebuilt inventory. |
| **G-08** | **CLOSED** | **07-12:T1, lines 79–82:** requires `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` or the alternative verified-import PASS; a FAIL, missing PASS or newer STOP means “stage nothing”. | The original FAIL-verdict admission is closed by an explicit STOP. Whether equality itself establishes a good state is a distinct new issue below. |
| **G-09** | **PARTIAL** | **07-11:T1:** separate hold tokens and reconciliation. But **T2, line 230** always writes `P01 BACKED OUT by UNDO IMPORT, not re-run; albums landed: none` on hold—even after `TREE COVERED no` or `DB COVERED no`. T1 says an inconsistent reconciliation presents “no gate”, while its verify requires `OPERATOR ANSWER`. | Distinct token names do not fix the false assertion after an incomplete undo. The first-entry reconciliation-failure branch also fails its own verify; reproduced locally. **Refute:** hold tokens containing the actual remaining tree/DB/state readings, and a verify arm accepting RECONCILE-FAIL without an operator answer or subsequent witness. |
| **G-10** | **CLOSED** | **07-12:T2:** normalized `DISPOSITION PNN:` lines; **07-13:T2:** likewise; **07-14:T2 / 07-15:T3:** exact `^DISPOSITION: hold$` tests. | Correct single-attempt holds no longer depend on timestamp-sensitive free-text matching. The newly introduced missing-disposition/vacuity problem is reported separately. |
| **G-11** | **PARTIAL** | **07-15:T3:** `MA returns K of N`, target N. Verify accepts `E6 SECOND MEASUREMENT: (NOT TAKEN|MA returns [0-9]+ of [0-9]+)`. | Prose and output shape are corrected, but the verify accepts `MA returns 0 of 0` or `3 of 3`; it neither enforces N ≥ 4 nor compares N and the standing target with the measured tag count. **Refute:** a verification check rejecting N < 4 and a mismatch between ffprobe count, reported denominator and proof-row target. |
| **G-12** | **PARTIAL** | **07-06:T1:** one execution order is now explicit. **07-12:T3 / 07-13:T3:** prescribe `albums.added` comparisons, but verifies only require `^ADDED ORDER`. | The ordering contradiction is fixed. The after-the-fact proof is not mechanically validated: an unsupported heading suffices. The query also needs an explicit treatment for landed singleton P06, which need not have an album row. **Refute:** a checked landed-ID-to-timestamp mapping, including singleton/N/A handling, that computes the ordering result and requires a filed finding for a real violation. |
| **G-13** | **PARTIAL** | **07-17:T2:** “Leave the dated 144 sentence byte-unchanged” and “not comparable with it”. Its automated verify checks neither condition. | Corrected prose, but no mechanical preservation or denominator check. **Refute:** a base-anchored comparison of the original 144 sentence and a check requiring the distinct population definition whenever the new number is inserted. |
| **G-14** | **CLOSED** | **07-01:T2 / 07-11:T3:** filter `'^(\+\+\+|---) (a/|b/|/dev/null)'` before counting additions and removals. | Both counts are now checked. `+++` can no longer satisfy the added-body-line test. |
| **G-15** | **CLOSED** | **07-10/12/13/14 verifies:** use `Full[R]efresh|zfs [r]ollback`; their prohibitions are written bracketed. | Bracketed recipes and bracketed narrative do not match these EREs; actual unbracketed verbs still do. This does **not** make a literal unbracketed quotation safe—it must still follow the artifact-writing rule. |
| **P-01** | **PARTIAL** | **07-10:T1:** `NONE SEEN` over 24 hours permits staging; “no MA setting is changed, no provider disabled”. **07-15:T2:** later FOUND is “a finding”, while `COULD NOT LOOK` has no mandatory hold branch. | A historical quiet window does not prevent a future scheduled/startup sync during undo or routing. The later observation comes after exposure and does not fail closed on inability to inspect. **Refute:** a verified barrier spanning first staging through 07-15, or installed-version evidence proving no autonomous sync can occur over that interval. The new MA STOP also conflicts with 07-10:T2’s unconditional “P01 staged” hold text. |
| **P-02** | **PARTIAL** | **07-15:T3:** provider mappings replace title-only identity. But it requires mapped paths “all under that directory (no track from another directory mixed in)” while accepting `one album with two provider mappings per track` with “no verdict attached”. | The title ambiguity is addressed, but the shared-album twin representation can violate the preceding directory-exclusive assertion. Verify merely looks for `TWIN REPRESENTATION (P02/P04)`. **Refute:** explicit mapping-scoped twin semantics, with fixtures for both separate albums and a shared album, neither falsely failing nor masking duplicate mappings of the same file. |
| **P-03** | **PARTIAL** | **07-07:T2:** specifies `TotalRecordCount` versus `Items` length and no pin comparison on failure. Verify only checks `/usr/bin/grep -qF 'TotalRecordCount' scripts/check-music-consumers.sh`. | The planned guard is correct, but its functioning and baseline eligibility are not verified; a comment containing that token suffices. **Refute:** driven missing-total and truncated-response cases returning non-zero without creating/updating a baseline, plus a complete-response case that can pin. |
| **P-04** | **CLOSED** | **07-11:T2:** adds `restore-db-state-then-rerun`, valid only with P01 the sole imported album and an empty fence DB; **T3** restores both files behind the stopped-writer barrier. | There is now a DB remedy rather than only a statefile remedy. D-17 remains NOT FIRED on it. |
| **P-05** | **CLOSED** | **07-07:T2:** same-commit §5 entry for `D24_CENSUS_BASELINE_N` / `_SHA`; verify checks the registered symbol. **07-15:T3:** adds and verifies `AUNIQUE_ROWS` in CONVENTIONS. | The pins now have named ownership and maintenance rules in the requested register. |
| **P-06** | **CLOSED** | **07-16:T2:** `ISSUED: zfs destroy … RC=<n>` versus `REFUSED: zfs [d]estroy …`; verify rejects unbracketed destroy lines outside the issued-record shape. | A bracketed refusal no longer trips the protected-target detector. Confirmed with a local control. Partial execution of an approved list remains a separate issue below. |
| **P-07** | **CLOSED** | **07-13:** `depends_on: ["07-12", "07-04", "07-06", "07-07"]`; **07-14:** `depends_on: ["07-13", "07-06", "07-07"]`. | Both direct producers are explicitly declared. |

### 3. New findings

### R2-OAI-01 — Fence and grant are still separate remote operations

**Severity:** HIGH  
**Plan/task:** 07-09:T2, steps 2–3, lines 202–245  
**Class:** FM-4; HIGH missed by round 1

**Literal quotes**

> “THE FENCE — ONE remote invocation on atlantis as real root.”

Then, separately:

> “THE GRANT (E3, first write on the library path). On LXC 100: install the repo files…”

> “Then `docker compose -f stacks/selfhosted/arrs/compose.yaml up -d`”

**Failure scenario**

The snapshot/list-back operation finishes on atlantis before a separate operation installs configuration and grants `rw` on LXC 100. There is no same-invocation coordinator or grant-side snapshot revalidation specified. An interruption or snapshot removal between those operations can leave deployment proceeding on historical fence evidence.

This is narrower than questioning the fence ordering: **the ordering is correct, but the required remote-operation boundary is not**. The supplied safety invariant 1 requires both in the same remote step; “same plan” is not equivalent.

**Refutation condition**

A prescribed executable remote coordinator that performs the exact-name snapshot checks and safety-copy checks, then conditionally invokes deployment without returning control between fence validation and grant.

**Suggested fix**

Make fence validation and deployment one fail-closed coordinated operation. Preserve the cross-pool ordering record, but do not let a later deployment invocation consume only an earlier transcript.

---

### R2-OAI-02 — Equality PASS can promote a reproducibly bad import

**Severity:** HIGH  
**Plan/task:** 07-11:T1/T3 → 07-12:T1  
**Class:** FM-1 / FM-2

**Literal quotes**

**07-11:T1, lines 124–125:**

> “list every P01 finding from 07-10 … and the executor's reading of each.”

**07-11:T3, lines 275–281:**

> “assert (a) the `LC_ALL=C` sorted destination path list is byte-identical to run 1's; (b) the `audio_md5` set is identical”

> “Write ONE line `EQUALITY VERDICT: PASS` (all four hold)”

**07-12:T1:**

> “Preconditions: the ledger's P01 line reads `P01 LANDED (re-run) — EQUALITY VERDICT: PASS`”

**Failure scenario**

Run 1 has an ffprobe/DB mismatch, wrong ownership or an unexplained metadata drop. Undo works. The same candidate reproduces exactly the same defective result.

All four equality predicates can pass: paths, encoded audio, tag-diff output and release ID are identical. Nothing requires the recorded quality findings to be resolved before writing the PASS-bearing LANDED line. That line then admits the remaining albums.

This is **not** G-08’s original problem of accepting an equality FAIL. Here the equality result is correctly PASS, but equality has been substituted for proof of a good state.

**Refutation condition**

A required quality gate, before the PASS-bearing readiness record or before 07-12 staging, rejecting unresolved criterion-3/4/7 defects independently of equality.

**Suggested fix**

Keep equality and quality separate. Require both a computed equality PASS and a quality/readiness PASS, with explicitly adjudicated allowed metadata changes and no unresolved file-write or ownership defects, before staging more albums.

---

### R2-OAI-03 — Missing disposition rows are treated as proof that no imports occurred

**Severity:** HIGH  
**Plan/task:** 07-12:T2/T3 and 07-13:T2/T3  
**Class:** FM-5; violates fail-closed checking

**Literal quotes**

**07-12:T2 verify:**

```sh
/usr/bin/grep -qE '^DISPOSITION( P[0-9]{2})?: (imported|imported-other|hold|hold-all)' "$A"
```

**07-12:T3 and 07-13:T3 verify:**

```sh
test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0
```

**Failure scenario — driven**

The Task 2 verify requires only **one** recognized disposition. Task 3 interprets zero normalized imported rows as an all-hold outcome, without proving that every expected P-ID has a disposition.

I ran the exact Task 2 and Task 3 automated commands in disposable Git repositories:

| Plan | Artifact fixture | T2 RC | T3 RC |
|---|---|---:|---:|
| 07-12 | `OPERATOR ANSWER: P02 hold; P03 imported` plus only `DISPOSITION P02: hold` | 0 | 0 |
| 07-13 | `OPERATOR ANSWER: P07 hold; P08 imported-asis` plus only `DISPOSITION P07: hold` | 0 | 0 |

Neither fixture contained landed verification evidence or a LANDED ledger. The tests still passed. Missing normalization is therefore being interpreted as “nothing to verify,” not UNKNOWN.

**Refutation condition**

The exact automated checks reject either fixture because the disposition P-ID set is incomplete, or because the normalized records disagree with the recorded/imported state.

**Suggested fix**

Before the all-hold shortcut:

1. Derive the expected in-scope P-ID set.
2. Require exactly one valid disposition per expected P-ID, with no extras or duplicates.
3. Handle a global hold explicitly.
4. Require evidence and ledger reconciliation for every imported disposition.

Do not infer all-hold from a zero grep count.

---

### R2-OAI-04 — New stopped-writer outcomes have no compatible re-entry path

**Severity:** MEDIUM  
**Plan/task:** 07-09:T2 failure branches → 07-09:T1  
**Class:** FM-3

**Literal quotes**

**07-09:T2:**

> `STOP STATE 07-09-IMPORT-KEYS-FAIL: fence held, grant deployed but writer stopped, no album landed`

and:

> `STOP STATE 07-09-INBOX-NOT-EMPTY`

**07-09:T1** recognizes a changed entry state only:

> “if the ledger's newest token is `07-09-PARTIAL-FENCE`”

The normal preconditions require both pilot snapshots absent, `RW=false`, and successful `docker exec` readings.

**Failure scenario**

The new guard correctly stops beets-flask after deployment. On retry, however:

- both snapshots already exist;
- the deployed mount is `rw`;
- the stopped container cannot supply the required `docker exec` readings;
- this is not the one recognized partial-fence shape.

The plan accepts the STOP as an outcome but offers no recovery transition that preserves the existing fence and safely repairs/revalidates the stopped writer. “The operator decides” does not identify a resumable task entry.

**Refutation condition**

A re-entry branch for each new token that expects the actual stopped/deployed state, reconciles both existing snapshots and safety copies, and offers a gated repair/restart without retaking or deleting the fence.

**Suggested fix**

Add explicit recovery entries for these two states. Preserve the stopped writer until configuration and inbox conditions have been checked; then restart under the existing readiness and effective-config gates.

---

### R2-OAI-05 — A refused prune cannot complete the new branch’s accounting contract

**Severity:** MEDIUM  
**Plan/task:** 07-16:T2, lines 168–179  
**Class:** FM-3

**Literal quotes**

> “Any refusal … is written `REFUSED: zfs [d]estroy <name> — <reason>`, bracketed, and nothing is issued for it.”

Immediately afterwards:

> “the before−after set difference must equal exactly the approved set”

> “Update each row: `destroyed <UTC> by plan 07-16 on the operator's answer`.”

**Failure scenario**

Two snapshots are approved. One is destroyed; the second fails its immediate presence or eligibility recheck and is correctly refused.

The actual removed set cannot equal the approved set. There is no partial-prune outcome describing which names were destroyed, refused or left pending, nor a resume rule requiring a new gate for the remainder. Following the final row-update instruction indiscriminately would also misrecord a refused name as destroyed.

The new issued/refused formatting fixes P-06 but does not give the refusal branch a coherent exit.

**Refutation condition**

An explicit partial-prune branch that reconciles the observed removed set against successful operations, updates rows individually, preserves refused/pending rows, and states how the remainder is re-gated.

**Suggested fix**

Track approved, successfully removed, refused and failed sets separately. On any refusal/failure, stop or finish under an explicit partial outcome; never assert that every approved operation happened or mark every approved row destroyed.

---

### R2-OAI-06 — Sweep acceptance count was changed on only one side

**Severity:** LOW  
**Plan/task:** 07-03:T1 versus plan-level `<verification>`  
**Class:** FM-2

**Literal quotes**

**Task 1:**

> `ST_PLANNED_CASES=10`

**Plan-level verification, line 300:**

> “`--self-test` 8/8 locally and on LXC 100.”

**Failure scenario**

An executor or verifier following the plan-level completion checklist is asked to report 8/8 while the executable test contract now requires 10/10.

**Refutation condition**

The final verification checklist consistently requires 10/10, with the optional dumper-level check separately identified.

**Suggested fix**

Update the stale footer and search the current plan for any remaining eight-case completion claims.

### 4. What was checked and held (no finding)

- **D-17 restoration hand-off:** Cross-read 07-11’s restoration exclusions, NOT FIRED record, Phase 6 status append and 07-16’s `HELD BY D-17 (NOT FIRED)` branch. The latter does not inherit permission to destroy; it requires D-19 eligibility and an operator answer.
- **Restoration ordering:** In 07-11:T3, stopping and asserting `State.Running=false` precede file replacement; restart and decoded membership checks follow it. No arrs dataset rollback is offered.
- **Snapshot-byte evidence:** 07-09:T2 explicitly compares both snapshot-resident files with their corresponding safety copies and stops on mismatch or unreadability.
- **G-14 regex repair:** The added/removed line counts exclude Git file headers before counting. The former `+++` self-match is not preserved.
- **Bracket semantics:** `Full[R]efresh`, `zfs [r]ollback` and `zfs [d]estroy` are ERE needles for the unbracketed operational tokens. They do not match the bracketed narrative itself. The 07-16 bracketed refusal control behaved accordingly.
- **Tag-diff exit contract:** 07-02 prescribes exit 3 in both text and JSON arms, before loss/green handling. The import and final-evidence plans retain AMBIGUOUS counts and do not describe exit 3 as success.
- **Source and tag-write evidence chain:** 07-07’s per-P-ID captures/manifests are consumed by 07-10/12/13 and the final 07-17 comparison. File-write evidence remains ffprobe, while SQLite supplies the expected values; it is not replaced by `beet ls`.
- **Consumer write scope:** The prescribed Jellyfin mutations remain file-list `Created`, `Deleted` or `Modified` notifications. No new aggressive refresh operation was introduced. The explicit MA sync remains behind 07-15’s gate; the unresolved autonomous-sync issue is P-01, not a second finding.
- **Credential transport:** The specified Jellyfin/MA HTTP credentials remain in process-substitution headers or `$ENV`-constructed request data, not literal command-line credentials.
- **Dependency updates:** 07-07 now follows 07-03 in wave 3; 07-13 and 07-14 directly name 07-06/07-07; 07-09 depends on all preparation plans. Those edits introduce no dependency cycle.
- **Unchanged decisions:** The flask-only default, authorized `grant-both` override, sample composition, locked path rules and file-copy recovery choice were treated as given—not reviewed again.

### 5. Suggestions

- Give each execution attempt an ID and scope its dispositions, witnesses and verification to that attempt; retain older evidence as history.
- Add a small fixture suite for the plan verifiers themselves, covering successful execution, all-hold, partial hold, missing records, reconciliation failure and interrupted recovery.
- Separate **observed state**, **quality result**, **operator authorization** and **next permitted action** in the ledger. This would make the remaining cross-plan gates substantially easier to audit.

---

## Round 2 Review: copilot CLI / gpt-5.5 (166 credits, 2m39s)

### Summary

Overall risk: **MEDIUM**. The replan closes the major destructive-safety problems from round 1: D-17 no longer fires on restore/vacuous witnesses, `fast/appdata/arrs` recovery remains file-copy only, the fence precedes `rw`, and post-grant copy/move/write settings are gated. The remaining risk is mostly mechanical-verification drift: one round-1 fold is only partially closed for Music Assistant automatic syncs, and two new seams allow artifacts to pass without proving the complete disposition or fired-destroy evidence the prose requires.

### Fold verification

| ID | CLOSED/PARTIAL/NOT CLOSED | evidence (plan:task + quote) | note |
|---|---|---|---|
| G-01 | CLOSED | 07-11 T3: “`FIRED iff ALL of:` … `UNDO IMPORT ALONE` … `EQUALITY VERDICT: PASS`”; “`The file-restore branches ... are NOT FIRED by construction`” | D-17 no longer destroys on the operator-chosen restore branch. |
| G-02 | CLOSED | 07-11 T1/T3: “`already-absent is VACUOUS, never yes`”; “`A re-run that incremental skipped reads 0 items and fails (a)`” | State witness is paired and FIRED waits on equality. |
| G-03 | CLOSED | 07-03 T1: “`ANY class whose checkable count is 0 → UNKNOWN`”; “`for every audio file ... whose path has NO item row, print one JSON object marked "orphan": true`” | Singleton-only and orphan `.1` cases are mechanically covered. |
| G-04 | CLOSED | 07-09 T2: “`snapshot's own view holds the SAME bytes`”; 07-11 T3: “`stop the writer` … `assert ... State.Running ... false`” and “`Re-decode after restart`” | Snapshot copy integrity and writer quiescence are now explicit gates. |
| G-05 | CLOSED | 07-09 T2: “`POST-GRANT IMPORT KEYS: PASS ... or FAIL`”; “`On FAIL ... STOP; stop the beets-flask service`”; “`RE-COUNT inbox emptiness now, after compose up`” | Effective `copy/move/write` and inbox emptiness are gated. |
| G-06 | CLOSED | 07-09 T1/T2: “`PARTIAL FENCE RECONCILIATION: CONSISTENT`”; “`Resume a partial fence — take ONLY the missing fast/appdata/arrs@pre-07-pilot`” | Partial fence has a hold and resume path. |
| G-07 | CLOSED | 07-15 T1/T3: “`AUNIQUE INVENTORY (rebuilt after 07-13)`”; “`the only inventory D-28 and AUNIQUE_ROWS are built from; the 07-12 list is superseded`” | D-28 inventory is rebuilt after DJ routing. |
| G-08 | CLOSED | 07-12 T1: “`P01 LANDED (re-run) — EQUALITY VERDICT: PASS` or `... NEW-IMPORT VERIFIED: PASS`”; “`a FAIL verdict ... is a STOP: stage nothing`” | 07-12 no longer proceeds from a bare LANDED line. |
| G-09 | CLOSED | 07-11 T1/T2/T3: “`RESUME RECONCILIATION: CONSISTENT (<token>)`”; “`STOP STATE 07-11-T1-HOLD: P01 LANDED`”; “`STOP STATE 07-11-T2-HOLD: P01 BACKED OUT`” | Hold states are distinct and resumable. |
| G-10 | CLOSED | 07-12 T2: “`DISPOSITION PNN: imported|imported-other|hold`”; 07-13 T2: “`DISPOSITION PNN: imported-asis|imported|imported-no-route|hold`”; 07-14 T1: “`DISPOSITION: hold|apply|apply-excluding`” | Original false-red hold issue is fixed; see new finding for completeness of per-ID verification. |
| G-11 | CLOSED | 07-15 T3: “`MA returns K of N`”; “`N as measured: 4, 5, …`”; “`the F1 proof row's target is N`” | ≥4 artist stratum is no longer hard-coded to 4. |
| G-12 | CLOSED | 07-12 T3: “`ADDED ORDER: PASS` ... or `ADDED ORDER: FAIL`”; 07-13 T3: “`DJ albums after every 07-12 album, P07 before P08`” | Import order is asserted after the fact from `albums.added`. |
| G-13 | CLOSED | 07-17 T2: “`it is NOT the backlog denominator`”; “`different population from the 144 backlog denominator, not comparable with it`” | The D-06 draw population is no longer laundered into the 144 denominator. |
| G-14 | CLOSED | 07-01 T2: “`grep -vE '^(\+\+\+|---) (a/|b/|/dev/null)'`” with separate `'^-'` and `'^+'` counts | Diff header self-match is excluded and both directions are counted. |
| G-15 | CLOSED | 07-12/13/14 verifies use “`Full[R]efresh|zfs [r]ollback`”; 07-16 refusals use “`zfs [d]estroy`” | Ban prose no longer self-matches the negative greps. |
| P-01 | PARTIAL | 07-10 T1: “`FOUND or COULD NOT LOOK is a STOP: nothing is staged`”; but 07-15 T2 verify accepts “`^MA SYNC SINCE 07-10: (NONE SEEN|FOUND|COULD NOT LOOK)`” | Pre-first-import log gate is closed; the later 07-10→07-15 window is only recorded as a finding, not a stop before syncing. |
| P-02 | CLOSED | 07-15 T3: “`read MA by IDENTITY, not by title`”; “`two title hits are the EXPECTED state`”; “`resolved through its tracks' provider mappings`” | Benson Boone twins are path/provider-mapping based. |
| P-03 | CLOSED | 07-07 T2: “`.TotalRecordCount` and `(.Items | length)`”; “`if TotalRecordCount is absent or the two differ → jellyfin_fail`” | D-24 baseline is no longer pinned from a possibly truncated page. |
| P-04 | CLOSED | 07-11 T2: “`restore-db-state-then-rerun`”; “`offered only when DB COVERED is no and P01 is the sole album since the fence`” | DB-uncovered branch has an explicit remedy/hold path. |
| P-05 | CLOSED | 07-07 T2: “`D24_CENSUS_BASELINE_N / D24_CENSUS_BASELINE_SHA` ... `CONVENTIONS §5`”; 07-15 T3: “`add AUNIQUE_ROWS ... to CONVENTIONS §5`” | New live pins are registered. |
| P-06 | CLOSED | 07-16 T2: “`ISSUED: zfs destroy <dataset>@<name> RC=<n>`”; “`REFUSED: zfs [d]estroy <name> — <reason>`” | Refusal prose cannot trip issued-destroy checks. |
| P-07 | CLOSED | 07-13 front matter: `depends_on: ["07-12", "07-04", "07-06", "07-07"]`; 07-14 front matter: `depends_on: ["07-13", "07-06", "07-07"]` | Direct producers are now declared. |

### New findings

### R2-CP-01 — MEDIUM — 07-12 T2 / 07-13 T2

**Literal quote:** 07-12 T2 requires “`one normalised line per in-scope P-ID, DISPOSITION PNN: imported|imported-other|hold`”, but its verify is only “`/usr/bin/grep -qE '^DISPOSITION( P[0-9]{2})?: (imported|imported-other|hold|hold-all)' "$A"`”. 07-13 repeats the same shape: “`one normalised line per DJ P-ID`” but verify only checks “`/usr/bin/grep -qE '^DISPOSITION( P[0-9]{2})?: (imported-asis|imported|imported-no-route|hold)' "$A"`”.

**Failure scenario:** An artifact with one valid line, such as `DISPOSITION P02: imported`, passes Task 2 verification while omitting P03–P06/P09–P12. Task 3 then loops only over imported lines, so missing albums can be neither explicitly held nor landed in the ledger, leaving the final evidence map and criterion counts ambiguous.

**Refutation condition:** The automated verify enumerates the expected in-scope P-ID set and fails unless every P-ID has exactly one normalized `DISPOSITION PNN:` line, or `DISPOSITION: hold-all` is expanded into explicit per-P-ID hold lines and ledger entries.

**Suggested fix:** In 07-12, add a verify loop over `P02 P03 P04 P05 P06 P09 P10 P11 P12`; in 07-13, loop over the DJ P-IDs from `07-SAMPLE.md`. Also reject duplicate `DISPOSITION PNN:` lines.

### R2-CP-02 — MEDIUM — 07-11 T3

**Literal quote:** The action says, on FIRED, “`issue exactly zfs destroy tank/media/Music@pre-06-41-conf04-reprobe`” and “`assert the set difference is exactly that one name`”. The automated verify only requires “`test "$(/usr/bin/grep -cE 'zfs [d]estroy' "$A")" -le 1`” plus the FIRED predicates; the exact issued command and before/after set difference are acceptance prose: “`on FIRED exactly one issued destroy naming the one snapshot, before/after name sets with a one-name difference`”.

**Failure scenario:** The artifact can say `D-17 TRIGGER: FIRED`, include `EQUALITY VERDICT: PASS`, the three COVERED `yes` lines, and mention `pre-06-41-conf04-reprobe`, but never show an issued destroy or the before/after name-set delta. The verify still passes, allowing `deferred-items.md` and the ledger to record a destroyed/closed D-17 state when the snapshot may still exist.

**Refutation condition:** The FIRED branch’s automated verify requires exactly one issued destroy line for `tank/media/Music@pre-06-41-conf04-reprobe` with RC recorded, plus computed before/after snapshot sets whose difference is exactly that name and whose after-set still contains `tank/media/Music@pre-07-pilot` and `tank/downloads@pre-phase5`.

**Suggested fix:** Reuse 07-16’s issued-command convention in 07-11: record `ISSUED: zfs destroy tank/media/Music@pre-06-41-conf04-reprobe RC=0`, and gate the FIRED branch on that line and the computed one-name set difference. If no destroy was issued, force `D-17 TRIGGER: NOT FIRED` or a STOP token.

### What was checked and held (no finding)

- 07-09’s fence/grant ordering is sound: both `tank/media/Music@pre-07-pilot` and `fast/appdata/arrs@pre-07-pilot` are created/listed before the grant, and partial-fence resume takes only the missing `fast` snapshot after `written tank/media/Music = 0`.
- `fast/appdata/arrs` recovery stays file-copy only: 07-09 and 07-11 write `zfs [r]ollback` as forbidden, and 07-11 restore branches stop `beets-flask`, copy literal `state.pickle`/`library.db` paths, restart, and re-decode state.
- Staging remains copy-not-move: 07-10/12/13 use reflink/plain `cp -R`, chown only staged copies, and compare source manifests after staging/import.
- Tag-write evidence remains file-level: 07-10/12/13 verification reads `ffprobe` per file and does not accept `beet ls` as tag-write proof.
- Jellyfin updates are file-scope only: 07-10/12/13/15 use targeted `/Library/Media/Updated`, and the unbracketed `FullRefresh` check is bracket-safe.
- 07-12→07-15 `%aunique{}` flow is sound apart from the disposition completeness finding: 07-15 rebuilds the inventory after 07-13 and builds `AUNIQUE_ROWS` only from that rebuilt set.
- Music Assistant identity for the Benson Boone twins is sound: 07-15 uses provider mappings and final paths, treats two title hits as expected, and records observed twin representation without declaring a duplicate.
- 07-16 pruning is operator-gated and protects `@pre-phase5` / `@pre-07-pilot`: issued destroys have a distinct form, refusals are bracketed, and protected snapshot names are rechecked after the operation.

### Suggestions

- Promote the P-01 later-window check to a real gate: `MA SYNC SINCE 07-10: FOUND` or `COULD NOT LOOK` should hold before any manual MA sync.
- Put the expected P-ID roster in one generated artifact and have 07-12, 07-13, 07-15, and 07-17 consume it instead of duplicating P-ID lists.
- Standardize all snapshot release artifacts on the 07-16 `ISSUED:` / `REFUSED:` line grammar so destructive-action verifies can be shared.


---

## Round 2 Review: pi → xai / grok-4.7

### 1. Summary

Round 1’s two HIGHs are closed in the action text (paired `UNDO IMPORT` witnesses, no restore branch, equality before destroy), and most other folds are now tied to a grep or a named STOP token. The replan’s own verifies do not always enforce those sentences: `07-11` can still record a destroy without `FIRED`, `07-12`’s precondition grep matches a FAIL line, and the new post-grant `import.move` gate reads `check-beets-config.sh` even though `07-08` says only the flask server’s injected config governs imports. That last gap is a compliant-executor miss of invariant 3, not a disobedience case. Overall risk is **MEDIUM**: nothing in the prose authorises `zfs rollback` of `fast/appdata/arrs`, a source move, or `FullRefresh`, but two mechanical backstops added to close G-01/G-05 are weaker than the prose.

### 2. Fold verification

| ID | Status | Evidence | Note |
|---|---|---|---|
| G-01 | PARTIAL | `07-11` Task 3: “FIRED iff ALL of: (i) both pre-07-pilot snapshots were listed back … (ii) TREE COVERED yes, DB COVERED yes AND STATE COVERED yes … by `UNDO IMPORT` ALONE; (iii) the Task 2 answer was `rerun` … (iv) `EQUALITY VERDICT: PASS`”. Verify: `{ ! /usr/bin/grep -qE 'D-17 TRIGGER: FIRED' "$A" \|\| { … '^EQUALITY VERDICT: PASS' … 'STATE COVERED yes \(' … ! /usr/bin/grep -qE '^DISPOSITION: restore' } }` | Prose matches the fix. Verify does not require `^DISPOSITION: rerun$`, and Task 2’s verify does not require a `DISPOSITION` line on the non-hold path (`'^DISPOSITION: hold$'` OR the COVERED lines). Omit `DISPOSITION: restore-then-rerun` and the restore backstop does not trip. Destroy count is `-le 1` with no FIRED conjunction (see R2-PI-02). |
| G-02 | PARTIAL | `07-11` Task 1: “Pre-undo ABSENT is not moot … `PAIRED WITNESS: VACUOUS — <part>`”. Task 2: “a part is `yes` ONLY when its Task 1 reading was PRESENT … `VACUOUS` when the Task 1 reading was already absent (never `yes`)”. Task 3 verify requires `STATE COVERED yes \(` plus `^EQUALITY VERDICT: PASS` before a FIRED record can pass. | Vacuous-as-yes is forbidden in prose and equality is on the FIRED path. The verify never reads the numbers inside the parentheses, so `STATE COVERED yes (pre 0 → post 0)` satisfies `yes \(`. |
| G-03 | CLOSED | `07-03` Task 1: “Vacuity, PER CLASS (G-03) … ANY class whose checkable count is 0 → UNKNOWN”; orphan `"orphan": true`; `ST_PLANNED_CASES=10`. Verify greps `ST_PLANNED_CASES=10`, `on-disk, no item row:`, `checkable rows per class:` and runs `--self-test`. | Bottom `<verification>` still says “8/8” (suggestion only). The executed verify pins 10. |
| G-04 | CLOSED | `07-09` Task 2: “each must EQUAL the corresponding safety copy's sha256 … a mismatch or an unreadable `.zfs/snapshot` path is a STOP”. `07-11` Task 3: “assert `docker inspect -f '{{.State.Running}}' beets-flask` reads `false` — STOP if it does not” before the `cp`, then “Re-decode after restart”. | STOP is in the action. Neither verify greps for the snapshot sha256 pair or `State.Running` (R2-PI-04 covers the copy-then-check order). |
| G-05 | CLOSED | `07-09` Task 2: “it is a GATE (G-05) … On FAIL … ledger `STOP STATE 07-09-IMPORT-KEYS-FAIL`”. “RE-COUNT inbox emptiness now, after `compose up` … `STOP STATE 07-09-INBOX-NOT-EMPTY`”. Verify success arm requires `POST-GRANT IMPORT KEYS: PASS`; the OR arm accepts those STOP tokens. | The gate’s data source is a different defect (R2-PI-01). Success verify does not require an inbox-count line. |
| G-06 | CLOSED | `07-09` Task 2: “writes the ledger `STOP STATE 07-09-PARTIAL-FENCE` … The `tank` snapshot is NOT destroyed”. Task 1: `PARTIAL FENCE RECONCILIATION: CONSISTENT` only if tank present, fast absent, `written` 0, fixture sha256s; “Offer `resume-partial-fence` ONLY when” that line is on record. Verify accepts `STOP STATE 07-09-PARTIAL-FENCE`. | Resume is a named exit. Inconsistent reconciliation offers only `hold`. |
| G-07 | PARTIAL | `07-15` Task 1: “`AUNIQUE INVENTORY (rebuilt after 07-13)` … including the DJ pair under `DJ/`”. Task 3: “the only inventory D-28 and `AUNIQUE_ROWS` are built from; the 07-12 list is superseded (G-07)”. Task 1 verify greps `AUNIQUE INVENTORY (rebuilt after 07-13)`. | Task 3 verify checks section `4d` and `AUNIQUE_ROWS` in `CONVENTIONS.md`, not that the pin came from the rebuilt inventory. A stale 07-12 list still passes. |
| G-08 | PARTIAL | `07-12` Task 1: “the ledger's P01 line reads `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` or `P01 LANDED (re-run-other <id>) — NEW-IMPORT VERIFIED: PASS` … a FAIL verdict … is a STOP: … `STOP STATE 07-12-PRECONDITION`”. `07-11` Task 3 writes that PASS/FAIL string. | Verify is `/usr/bin/grep -qE 'EQUALITY VERDICT\|NEW-IMPORT VERIFIED'`, which matches FAIL. If `STOP STATE 07-12-PRECONDITION` is present, the same verify skips the staging checks, so a FAIL plus a staged album still passes. |
| G-09 | CLOSED | `07-11` must_haves: tokens `07-11-T1-HOLD`, `07-11-T2-HOLD`, `07-11-T2-TREE-NOT-COVERED`, `07-11-T3-EQUALITY-FAIL`, `07-11-T3-RESTORE-FAIL`. Task 1: “after `07-11-T2-HOLD` resumes at Task 2's gate; after `07-11-T1-HOLD` at this task's gate”. Task 1 verify requires `RESUME RECONCILIATION: (CONSISTENT\|INCONSISTENT)`. | Hold texts no longer collide. INCONSISTENT writes `STOP STATE 07-11-RECONCILE-FAIL` and presents no gate. |
| G-10 | CLOSED | `07-12` Task 2 verify: `'^DISPOSITION( P[0-9]{2})?: (imported\|imported-other\|hold\|hold-all)'`. Task 3: `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0 \|\| { … }` so all-hold passes. `07-13` Task 2 verify uses the same DISPOSITION shape, not an end-anchored `OPERATOR ANSWER`. `07-14` Task 2: `'^DISPOSITION: hold$'` OR `post-07-e5`. | A normalised hold passes its own verify. |
| G-11 | CLOSED | `07-15` Task 3: “write `E6 SECOND MEASUREMENT: MA returns K of N` … (N as measured: 4, 5, …)”. Verify: `'E6 SECOND MEASUREMENT: (NOT TAKEN\|MA returns [0-9]+ of [0-9]+)'`. | Original “of 4” cap is gone. The new regex also matches `MA returns 3 of 3` (R2-PI-05). |
| G-12 | CLOSED | `07-06` Task 1: “the ONE EXECUTION ORDER (G-12) is: P01 … then P02, P03, P04, P05, P06, P09, P10, P11, P12 … then P07, P08” under `### EXECUTION ORDER`. Verify greps that heading. `07-12`/`07-13` Task 3 write `ADDED ORDER:` from `albums.added`; verifies require `^ADDED ORDER` when any `imported` disposition exists. | P02-before-P04 is asserted after the fact, or `NOT APPLICABLE` if either was held. |
| G-13 | PARTIAL | `07-17` Task 2: “it is NOT the backlog denominator and must not be written beside the 144 … ‘not comparable with it’”. Acceptance: “the 144 sentence is unchanged”. | Task 2 verify greps `UNDO IMPORT` and the Phase 7 heading only. Nothing fails a “beside the 144” sentence. |
| G-14 | CLOSED | `07-01` Task 2 verify: `grep -vE '^(\+\+\+\|---) (a/\|b/\|/dev/null)'` then `grep -cE '^-'` and `'^\+'` both `-eq 1`. `07-11` Task 3 verify uses the same header filter and requires `^-` count `-eq 0`. | `+++` no longer counts as an added line. |
| G-15 | CLOSED | `07-10` Task 3, `07-12` Task 3, `07-13` Task 3, `07-14` Task 2 verifies use `Full[R]efresh\|zfs [r]ollback`. `07-15` uses `Full[R]efresh`. | Bracketed ban prose does not match. False red only, and the false red is removed. |
| P-01 | CLOSED | `07-10` Task 1: “FOUND or COULD NOT LOOK is a STOP … `STOP STATE 07-10-MA-PERIODIC-SYNC`”. Verify: `'^MA PERIODIC SYNC: (NONE SEEN\|FOUND\|COULD NOT LOOK)'` and if the line is not `NONE SEEN`, ledger must contain that STOP. `07-15` Task 2 requires `'^MA SYNC SINCE 07-10: (NONE SEEN\|FOUND\|COULD NOT LOOK)'`. | Gate is before staging. No barrier is invented, as the finding allowed. |
| P-02 | CLOSED | `07-15` Task 3: “read MA by IDENTITY, not by title … A duplicate finding is two MA albums (or tracks) whose mapped paths are the SAME files — never merely two title hits.” “`TWIN REPRESENTATION (P02/P04):`”. Non-hold verify greps that literal. | Two title hits are specified as expected, not a finding. |
| P-03 | CLOSED | `07-07` Task 2: “if `TotalRecordCount` is absent or the two differ → `jellyfin_fail` … and no pin comparison is made”. Verify greps `TotalRecordCount` in the script. | Pin is forbidden until coverage holds. The live equality is acceptance-only, which matches “not driven”. |
| P-04 | CLOSED | `07-11` Task 2 option `restore-db-state-then-rerun`: “offered only when DB COVERED is `no` and P01 is the sole album since the fence”. Task 3 copies `library.db` only on that branch, writer stopped. | Remedy exists, and it is refused when a later album has landed. |
| P-05 | CLOSED | `07-07` Task 2: add `D24_CENSUS_BASELINE_N` / `_SHA` to CONVENTIONS §5 “in the SAME commit”. Verify greps `D24_CENSUS_BASELINE_N` in `CONVENTIONS.md`. `07-15` Task 3 adds `AUNIQUE_ROWS` to the same list; verify greps `AUNIQUE_ROWS` in `CONVENTIONS.md`. | Both pins are in §5’s scope statement in the plan. |
| P-06 | CLOSED | `07-16` Task 2: refusals are `REFUSED: zfs [d]estroy <name> — <reason>`. Verify: `grep -E 'zfs [d]estroy' \| grep -cvE '^ISSUED: zfs [d]estroy [^ ]+@[^ ]+ RC=[0-9]+$'` must be 0. | A bracketed refusal does not match `zfs [d]estroy` (character class, not the two characters `[d]`). |
| P-07 | CLOSED | `07-13` frontmatter: `depends_on: ["07-12", "07-04", "07-06", "07-07"]`. `07-14`: `depends_on: ["07-13", "07-06", "07-07"]`. | Direct edges added. |

### 3. New findings

### R2-PI-01 — MEDIUM — `07-09` Task 2 (gate), contradicted by `07-08` Task 1

**Quote (`07-08` Task 1):** “noting rc6 injects its own schema defaults at highest priority in the server process, so the server's effective value is the one that governs imports.”

**Quote (`07-09` Task 2):** “Assert the effective import keys by running `bash scripts/check-beets-config.sh` from the workstation and recording its exit and the `import.copy/move/write` readings — this is the post-grant C1 reading, and it is a GATE (G-05), not a record: parse each effective value (the YAML boolean read from the effective config, not a substring of the output) and require `copy` = true, `move` = false, `write` = true”

**Failure:** A compliant executor parses `check-beets-config.sh`, writes `POST-GRANT IMPORT KEYS: PASS (copy=true move=false write=true)`, and continues. The same phase has already said that string is not the server value that performs the import. If rc6’s injected `import.move` is true (or `write` is false) while the script still prints the YAML file, the new gate passes and `07-10` stages. Invariant 3 is then false in the process that writes, and criterion 8 can still pass because staging was an extra `cp` — `import.move` would consume the inbox copy, not the original folder.

**Refutation:** `07-09` Task 2 names a server-process dump (flask config endpoint or `beet config` inside the running server, not only `check-beets-config.sh`) as the gated values, or `07-08`’s measurement is an explicit precondition that server and script booleans are equal before PASS is allowed.

**Fix:** Gate the running server’s effective `import.copy/move/write` after `compose up`. If that cannot be read, STOP with `COULD NOT LOOK`. Do not treat `check-beets-config.sh` as that reading unless `07-08` recorded them equal.

### R2-PI-02 — MEDIUM — `07-11` Task 3 `<verify>`

**Quote:** `test "$(/usr/bin/grep -cE 'zfs [d]estroy' "$A")" -le 1 && { ! /usr/bin/grep -qE 'D-17 TRIGGER: FIRED' "$A" \|\| { … } }`

**Failure:** On `D-17 TRIGGER: NOT FIRED` the destroy count is still allowed to be 1. The action says “If NOT FIRED: issue nothing”. A transcript that destroys `tank/media/Music@pre-06-41-conf04-reprobe` and then writes NOT FIRED passes this verify. That is the irreversible branch, and the check added for G-01 does not bind the verb to `FIRED`.

**Refutation:** The verify contains a conjunction that the unbracketed destroy count is 0 unless `D-17 TRIGGER: FIRED` is present, and exactly 1 when it is.

**Fix:** `{ ! /usr/bin/grep -qE 'zfs [d]estroy' "$A" \|\| /usr/bin/grep -qE 'D-17 TRIGGER: FIRED' "$A"; }` and, on FIRED, count `-eq 1`.

### R2-PI-03 — MEDIUM — `07-09` Task 2 success path vs its verify

**Quote (verify):** `test -s "$L" && /usr/bin/grep -qF 'STOP STATE' "$L" && …`

**Quote (proceed step 5):** “Create `artifacts/07-pilot-ledger.txt` with a header (purpose: the D-18 written STOP state every import plan appends to; a later session reads this instead of re-deriving) and a first entry: fence taken (both names, creation times), grant deployed (commit), qhc run result, "albums landed: none".”

**Failure:** The hold branch writes `## STOP STATE`. The proceed branch never writes the literal `STOP STATE` (the header says “STOP state”). A correct grant therefore fails its own verify. That is the G-10 pressure on the first write: invent a `STOP STATE` line to go green. A invented “albums landed: none” token is what `07-11` Task 1 reconciles against.

**Refutation:** Step 5 of the proceed branch includes the exact characters `STOP STATE`, or the verify requires that string only on the hold / PARTIAL-FENCE / IMPORT-KEYS-FAIL / INBOX-NOT-EMPTY arms.

**Fix:** On success write a named token such as `STATE 07-09-GRANTED: fence listed, grant deployed, albums landed: none`, and grep that. Do not overload `STOP STATE`.

### R2-PI-04 — MEDIUM — `07-11` Task 3 restore, FM-4

**Quote:** “on atlantis as real root, copy `/mnt/fast/appdata/arrs/.zfs/snapshot/pre-07-pilot/beets/config/state.pickle` over `/mnt/fast/appdata/arrs/beets/config/state.pickle` … Record sha256 after each (must equal the fence safety copy's).”

**Failure:** The equality check that is supposed to guard the overwrite runs after the overwrite. If the snapshot view and `/mnt/fast/safety/phase07/fence/state.pickle` diverge, live `state.pickle` (and, on the DB branch, `library.db`) is already replaced, then the plan STOPs. There is no “copy back the safety copy” step. Container is stopped, so this does not touch Sonarr, but the beets state the next re-run will open is no longer the pre-copy live file.

**Refutation:** The plan hashes the `.zfs/snapshot` path against the safety copy and STOPs before either `cp`.

**Fix:** Compare first. Copy only if equal. If unequal, do not touch the live files; write `STOP STATE 07-11-T3-RESTORE-FAIL`.

### R2-PI-05 — LOW — `07-15` Task 3 verify, FM-5 (replan regression)

**Quote:** `/usr/bin/grep -qE 'E6 SECOND MEASUREMENT: (NOT TAKEN\|MA returns [0-9]+ of [0-9]+)'`

**Failure:** The pre-replan pattern required `of 4`. The replacement accepts `MA returns 3 of 3`, which the action forbids (“if N < 4, write `E6 SECOND MEASUREMENT: NOT TAKEN`”). A 3-artist row can be recorded as taken and the verify still passes. That re-opens the “never satisfied by a 3-artist row” rule G-11’s prose kept.

**Refutation:** The regex requires the second integer to be `([4-9]\|[1-9][0-9]+)`, or the verify rejects a taken line whose N is less than 4.

**Fix:** Keep `NOT TAKEN` as the only legal line when N < 4, and make the taken alternative `MA returns [0-9]+ of ([4-9]|[1-9][0-9]+)`.

### R2-PI-06 — MEDIUM — `07-10` Task 1 preconditions, FM-2

**Quote:** “Preconditions (recorded, RC read): both pre-07-pilot snapshots present (exact whole-line), beets-flask `/media` RW=true, watchdog lists two inboxes, `_inbox/02-review` holds no audio, `library.db` items 0.”

**Failure:** `07-09` can leave `STOP STATE 07-09-IMPORT-KEYS-FAIL` (“grant deployed but writer stopped”) or a watchdog-absent STOP that has no token at all (“If the watchdog line is absent or lists fewer than two: STOP — the fence holds; do not revert by hand; record; the operator decides”). `07-10` never reads those tokens and never re-checks `import.move`. `restart: unless-stopped` will not start an explicitly stopped container, but an operator start, or a watchdog miss that still left the container up, walks into staging with the G-05 gate behind them.

**Refutation:** `07-10` Task 1 STOPs unless the ledger’s newest `07-09` token is the granted token and a fresh parsed server-side `move=false` reading is on record.

**Fix:** Add that precondition. Name a ledger token for the watchdog-absent STOP and give it a resume (fix config, re-read keys, start writer) or an explicit hold.

### R2-PI-07 — LOW — `07-13` Task 3 / `07-04` `--apply`, FM-3

**Quote (`07-04`):** “`--apply` — in order, stopping at the first non-zero RC”. **Quote (`07-13`):** “then `… --album-id N --apply`; record the full transcript, every RC”.

**Failure:** `modify` can commit `albumtype=dj` into the files and then `move` can fail. The album sits in the artist tree with DJ tags. No `STOP STATE 07-13-ROUTE-PARTIAL` token, no “do not Jellyfin-scan, do not MA-sync, resume at `move`” exit. `07-15` treats ledger `LANDED` as final paths. A half-routed album can be scanned at its transient path.

**Refutation:** `07-13` Task 3 writes a named STOP token when any `--apply` RC is non-zero, issues no Jellyfin POST for that album, and `07-15` skips P-IDs in that token.

**Fix:** One token, e.g. `07-13-ROUTE-PARTIAL: <album_id> modified, not moved`. Resume is re-run `move` only, or `UNDO IMPORT`, not a second `modify`.

### 4. What was checked and held (no finding)

- **Fence before grant, action order.** `07-09` Task 2 steps are push/pull, then one remote snapshot program, then sha256 of the safety copies, then `docker compose up`. Grant is not inside the snapshot program; listing-back is specified before step 3. Held as matching invariant 1’s “listed back before rw”, not as one atomic two-pool snapshot (C11 is stated).
- **`zfs rollback` of `fast/appdata/arrs`.** `07-09` call site and `07-11` restore comment both say `zfs [r]ollback of fast/appdata/arrs is FORBIDDEN`; recovery is a literal-path `cp`. `07-16` never offers `@pre-phase5` or `@pre-07-pilot` (`! /usr/bin/grep -qE '^ISSUED: zfs [d]estroy [^ ]*@pre-phase5'`).
- **Producer/consumer ledger strings that match.** `07-11` writes `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` and `P01 LANDED (re-run-other <release id>) — NEW-IMPORT VERIFIED: PASS`. `07-12` Task 1 quotes those two shapes. `07-16` quotes `07-11`’s `D-17 TRIGGER:` line, which Task 3 always writes, including on hold.
- **Execution order seam.** `07-06` `### EXECUTION ORDER` is P02–P06, P09–P12, then P07–P08. `07-12` and `07-13` repeat that order and assert `albums.added`. No remaining “import in P-ID order” instruction in those tasks.
- **Copy-not-move staging.** `07-10`/`07-12`/`07-13` stage with `cp -R` (reflink or plain), then beets `import.copy`. Source manifest is re-checked against `07-07`. Criterion 8 does not depend on the inbox copy surviving.
- **Tag evidence.** Criterion 3 in `07-10` Task 3 is `ffprobe` versus read-only sqlite, plus an EPERM log count. `beet ls` is not the evidence. `07-04`’s only `ls` is inside the route script’s read-only mode.
- **Jellyfin scope.** `07-10`, `07-12`, `07-13`, `07-14` name one `POST /Library/Media/Updated` at file scope. `07-15` Task 1: “No write verb against Jellyfin in this task”. Verifies use `Full[R]efresh`. MA sync is a single gated command in `07-15` Task 3, after the ledger is supposed to show imports, undo, DJ route, and E5 done.
- **D-17 handoff when NOT FIRED.** `07-11` says the snapshot is “HELD for plan 07-16's operator gate”. `07-16` Task 1 adds heading `HELD BY D-17 (NOT FIRED)` and still requires D-19 eligibility plus the operator answer. Not destroyed on `07-16`’s own judgement.
- **Partial-fence resume does not destroy.** `resume-partial-fence` asserts tank present, fast absent, `written` 0, snapshots only the missing fast name. No `zfs destroy` in that program.
- **P-01 token shape.** `07-10` verify anchors `^MA PERIODIC SYNC:` so a body mention of “NONE SEEN” without that prefix does not select the continue branch. FOUND/COULD NOT LOOK requires the ledger STOP before Task 2’s verify can pass without staging evidence.
- **G-14 header filter** does not match a content line that merely contains `+++`, because of the `(a/|b/|/dev/null)` anchor. Held, not re-opened.
- **Credentials.** `07-07`/`07-14`/`07-15` keep `jf_api` / `$ENV` in jq. `07-14` verify rejects `(password|Token=|api_key)[=:]`. `07-10` says the HA key path is not echoed. No plan puts a secret in the artifact grep set.
- **`grant-both`.** Not re-litigated. `07-09` still offers it as an override; flask-only remains the default in `07-08`.
- **Invariant 6 ordering vs `07-13` window.** No MA sync command appears in `07-10`–`07-14`. The transient artist-tree window is closed by “Issue NO Jellyfin POST before the move completes” in `07-13` Task 3 (the failed-`move` exit is R2-PI-07; the prohibition itself is present).

### 5. Suggestions

- `07-03` `<verification>` still says “`--self-test` 8/8”. The task pin is 10. Align the summary so a later editor does not “fix” the pin back.
- `07-01` evidence-map row 1 still defines the state witness as “decoded `taghistory` no longer holding the staged source path”. `07-11` now uses `P01 STATE KEY(S)` set-difference. The map forbids editing the instrument column; add a one-line finding in `deferred-items.md` when `07-11` executes so `/gsd-verify` does not score the old key.
- `07-15` “every album the ledger lists as LANDED” will see both `07-10`’s `P01 LANDED` and `07-11`’s `P01 LANDED (re-run)`. Say “latest line per P-ID”.
- `07-09` success verify should require a `sha256` line for `.zfs/snapshot/pre-07-pilot/beets/config/library.db` if G-04 is to stay closed under a later edit that drops the STOP sentence.

---

## Round 2 Review: pi → ollama-cloud / kimi-k3

### Cross-AI Plan Review — Phase 7, ROUND 2

Initials used for finding IDs: **CL**.

### 1. Summary

**Overall risk: MEDIUM** — down from round 1's pre-fix state, and consistent with round 1's own grading ("MEDIUM once G-01/G-02 are fixed"). The two round-1 HIGHs (G-01, G-02) are genuinely closed: 07-11's D-17 trigger is now a four-condition conjunct — paired `UNDO IMPORT`-alone witnesses on tree/DB/state, a `rerun` answer, and `EQUALITY VERDICT: PASS` written before the destroy — and the verify mechanically enforces both halves (FIRED ⇒ no `^DISPOSITION: restore` + three `COVERED yes (` lines + anchored PASS; restore disposition ⇒ NOT FIRED). Every PLAUSIBLE item is closed with a mechanical hook. However, the replan's new 07-09 recovery machinery created two new seams of exactly the G-06 class it was fixing: the Task-2 verify's STOP-token disjunct reads the ledger *non-chronologically*, so the historic `07-09-PARTIAL-FENCE` token satisfies it on a *successful* `resume-partial-fence` run, letting the phase's most consequential step (the grant) pass verify without its happy-path evidence (R2-CL-01, MEDIUM); and the two *new* STOP tokens (`07-09-IMPORT-KEYS-FAIL`, `07-09-INBOX-NOT-EMPTY`) record their state but have no resume branch — Task 1's only re-entry is keyed on `07-09-PARTIAL-FENCE` — so a stopped-writer state cannot be re-entered in-plan (FM-3, R2-CL-02, MEDIUM, the symmetrical re-occurrence of G-06). Two LOWs (a stale `8/8` self-test count in 07-03's footer, and a missing held-album arm in 07-13's ADDED ORDER). G-13 is graded **PARTIAL** — the only fold whose enforcement rests on acceptance criteria alone. Nothing HIGH round 1 missed was found.

### 2. Fold verification

| ID | Verdict | Evidence (plan:task + quote) | Note |
|----|---------|------------------------------|------|
| G-01 | **CLOSED** | 07-11 must_haves: "TREE, DB and STATE COVERED `yes` by `UNDO IMPORT` ALONE (paired witnesses, no file restore used)… Any other outcome — including the operator-chosen file-restore branch and `undo-rerun-other` — writes `D-17 TRIGGER: NOT FIRED`"; Task 3: "(iii) the Task 2 answer was `rerun` (no file restore on any branch)"; verify: `{ ! /usr/bin/grep -qE '^DISPOSITION: restore' "$A" || /usr/bin/grep -qE 'D-17 TRIGGER: NOT FIRED' "$A"; }` plus FIRED conjunct requiring `^EQUALITY VERDICT: PASS` and three `COVERED yes \(`. | `undo-rerun-other` is excluded mechanically too: that branch writes `NEW-IMPORT VERIFIED`, never `^EQUALITY VERDICT: PASS`, so the FIRED conjunct cannot pass. |
| G-02 | **CLOSED** | 07-11 Task 1: "`PAIRED WITNESS: VACUOUS — <part>`" filed as `DEF-07-11-02`, "it is never described as moot"; Task 2: "a part is `yes` ONLY when its Task 1 reading was PRESENT and its post-undo reading is ABSENT on the same key"; the state key is now measured, not assumed: "the set difference post-import minus fence, per top-level key — are the `P01 STATE KEY(S)`… The staged path is only the expectation; the set difference is the measurement." Task 3: "evaluated only AFTER the verdict line above is written" and FIRED requires "(iv) `EQUALITY VERDICT: PASS`". | Verify gates: Task-1 requires `P01 STATE KEY(S)`; Task-2 requires `STATE COVERED (yes\|no\|VACUOUS) \(`; Task-3 FIRED requires the three `yes (` forms + anchored PASS. The "never moot" wording itself is acceptance-level, but a VACUOUS outcome mechanically blocks FIRED. |
| G-03 | **CLOSED** | 07-03 must_haves: "the guard is per class, so an all-singletons library (classes 2 and 3 empty) is UNKNOWN, not clean (G-03)" and "class 1 is enumerated from the FILESYSTEM as well as the DB… an orphaned `Title.1.flac` with no item row beside `Title.flac` is a finding"; structure: "Vacuity, PER CLASS (G-03): … `checkable rows per class:` line… ANY class whose checkable count is 0 → UNKNOWN naming that class". | Verify runs the now-`ST_PLANNED_CASES=10` self-test and greps both new labels; the 10th behaviour case is the all-singletons exit-3, the 11th (uncounted, python3-gated) dumper check proves the orphan enumeration. But see R2-CL-03 for the stale footer. |
| G-04 | **CLOSED** | 07-11 Task 3 restore branch: "(1) stop the writer… then assert `docker inspect -f '{{.State.Running}}' beets-flask` reads `false` — STOP if it does not; …(3) `docker compose … start`; readiness exactly as 07-09 … AND a NEW watchdog line listing exactly `02-review` and `03-asis`). (4) Re-decode after restart: a fresh copy of the live `state.pickle` shows every `P01 STATE KEY(S)` entry ABSENT (the gate)"; 07-09 Task 2 step 2: "assert the snapshot's own view holds the SAME bytes (G-04): `sha256sum …/.zfs/snapshot/pre-07-pilot/beets/config/library.db … state.pickle` — each must EQUAL the corresponding safety copy's sha256 … a mismatch or an unreadable `.zfs/snapshot` path is a STOP". | Both halves are STOP-gated (the rubric's "STOP condition"), not merely recorded. The post-restart sha difference is correctly recorded-not-stopped, with the byte-equality gate kept at step 2 pre-restart. |
| G-05 | **CLOSED** | 07-09 Task 2 step 3: "it is a GATE (G-05), not a record: parse each effective value (the YAML boolean read from the effective config, not a substring of the output) and require `copy` = true, `move` = false, `write` = true; write `POST-GRANT IMPORT KEYS: PASS (copy=true move=false write=true)` or `POST-GRANT IMPORT KEYS: FAIL — <key>=<value>`. On FAIL, and on any reading that could not be taken: STOP; stop the beets-flask service… Then RE-COUNT inbox emptiness now, after `compose up` (G-05)". | Verify's happy set now requires `grep -qF 'POST-GRANT IMPORT KEYS: PASS'`; FAIL path requires the ledger token `STOP STATE 07-09-IMPORT-KEYS-FAIL`. Enforced. |
| G-06 | **CLOSED** (with new adjacent seams → R2-CL-01/02) | 07-09: ledger `STOP STATE 07-09-PARTIAL-FENCE`; Task 1: "`PARTIAL FENCE RECONCILIATION: CONSISTENT` only when all four agree"; option `resume-partial-fence` "offered only after a CONSISTENT partial-fence reconciliation"; resume program "takes ONLY `zfs snapshot fast/appdata/arrs@pre-07-pilot`" after re-reading `written` (must be 0); "⛔ The `tank` snapshot is NOT destroyed". | The fold itself is complete. Two defects in the *new* machinery are reported below, not here. |
| G-07 | **CLOSED** | 07-15 Task 1: "`AUNIQUE INVENTORY (rebuilt after 07-13)` (G-07): from the library as it stands now… across ALL landed albums including the DJ pair under `DJ/` and any E5 change… Task 3's D-28 readings and `AUNIQUE_ROWS` are built from THIS inventory only"; Task-3 read_first: "the only inventory D-28 and `AUNIQUE_ROWS` are built from; the 07-12 list is superseded (G-07)". | Verify greps the heading 'AUNIQUE INVENTORY (rebuilt after 07-13)' and `AUNIQUE_ROWS` in CONVENTIONS.md. |
| G-08 | **CLOSED** | 07-12 Task 1: "the ledger's P01 line reads `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` or `P01 LANDED (re-run-other <id>) — NEW-IMPORT VERIFIED: PASS` (G-08 — quote it; `LANDED` without a PASS verdict, a FAIL verdict, or a newer `STOP STATE 07-11-…` token is a STOP… write `STOP STATE 07-12-PRECONDITION: <what the ledger said>`)"; 07-11 ledger lines now carry the verdict. | Verify: `'EQUALITY VERDICT\|NEW-IMPORT VERIFIED'` in the artifact AND (ledger STOP token XOR full staging evidence). |
| G-09 | **CLOSED** (token strings acceptance-level) | 07-11 Task 1: "**RESUME RECONCILIATION (always first, G-09; reads only)…** `RESUME RECONCILIATION: CONSISTENT (<token>)` … or `INCONSISTENT — <reading> vs <token>` and STOP… ledger gains `STOP STATE 07-11-RECONCILE-FAIL`"; Task 3: "never overwrite one with the other"; acceptance criteria name `07-11-T1-HOLD` / `07-11-T2-HOLD` verbatim. | The mechanism (reconciliation line + INCONSISTENT stop) is verify-gated (`grep -qE 'RESUME RECONCILIATION: (CONSISTENT\|INCONSISTENT)'`); the exact per-stop token texts are specified in acceptance criteria but not grep'd. The finding's core — no resume reconciliation — is mechanically closed. |
| G-10 | **CLOSED** | 07-12 Task 2: "write one normalised line per in-scope P-ID, `DISPOSITION PNN: imported\|imported-other\|hold`… or the single line `DISPOSITION: hold-all` (G-10 — the verify reads these, never the free-text answer)"; 07-13: "`DISPOSITION PNN: imported-asis\|imported\|imported-no-route\|hold`… (G-10 — the verifies read these, never the free-text answer, so a verbatim answer carrying its UTC time cannot fail its own check)"; 07-14/07-15 `DISPOSITION:` lines; verifies rewritten to `^DISPOSITION…` and `… -eq 0 \|\| …` hold-tolerant forms. | Checked each regex against its written forms: 07-12 Task-3's `^DISPOSITION P[0-9]{2}: imported` prefix-matches `imported-other` (intended — those land and get `PNN LANDED`); all-hold passes with count 0. |
| G-11 | **CLOSED** | 07-15: "`E6 SECOND MEASUREMENT: MA returns K of N` with the names (N as measured: 4, 5, …)"; "Add the F1 track as a new `ARTIST_PROOF_ROWS` row (target N — the measured post-import tag count, not a literal 4…)"; verify regex `E6 SECOND MEASUREMENT: (NOT TAKEN\|MA returns [0-9]+ of [0-9]+)`. | Hypothesis logic also fixed: "any other K is recorded as neither, with the missing names". |
| G-12 | **CLOSED** (07-13 arm gap → R2-CL-04) | 07-06: "P-IDs are IDENTIFIERS; the ONE EXECUTION ORDER (G-12) is… Write this order verbatim under a `### EXECUTION ORDER` heading"; 07-12 Task 3: "**Import order, asserted after the fact (G-12):** read-only sqlite `SELECT id, albumartist, album, added FROM albums`… `ADDED ORDER: PASS/FAIL`… `ADDED ORDER (P02<P04): NOT APPLICABLE — <which held>`"; 07-13 has the parallel block. | Verify greps `### EXECUTION ORDER` and `^ADDED ORDER`. The old contradiction sentence ("Plans 07-12 and 07-13 import in this order") is gone; acceptance forbids "in P-ID order". |
| G-13 | **PARTIAL** | 07-17 Task 2 (3) mandates the exact sentence: "…measured `<N>` folders / `<M>` audio files on `<date>` (`07-SAMPLE.md`) — a different population from the 144 backlog denominator, not comparable with it", "Leave the dated 144 sentence byte-unchanged", "or omit it if it cannot be stated with its definition". Acceptance: 'the words "not comparable" beside it, and the 144 sentence is unchanged'. | Nothing in Task 2's `<verify><automated>` greps `not comparable`, the omission alternative, or the 144 line's immutability; enforcement rests on the acceptance criteria and "diff body read". The rubric says prose-without-mechanical-enforcement = PARTIAL. The mandated-wait wording is maximally specific, so the residue is small. Suggested fix: add a grep for `not comparable` XOR an explicit `OMITTED` line. |
| G-14 | **CLOSED** | 07-01 Task-2 verify: `git diff HEAD~1 -- "$R" \| /usr/bin/grep -vE '^(\+\+\+---) (a/\|b/\|/dev/null)' \| /usr/bin/grep -cE '^-'` -eq 1 **and** `'^\+'` -eq 1 (both directions, headers excluded); 07-11 Task-3 verify applies the same filter with `-ge 1`/`-eq 0` for deferred-items.md. | Filter checked for over-exclusion: it requires ` a/`, ` b/` or ` /dev/null` after the marker, so a removed content line beginning `--` is not lost. |
| G-15 | **CLOSED** | 07-01: `'zfs [r]ollback\|zfs [d]estroy\|Full[R]efresh'`; 07-10/12/13/14: `'Full[R]efresh\|zfs [r]ollback'`; 07-15 Task 1/3: `grep -cE 'Full[R]efresh'`. All verify needles now bracketed, so artifact prose quoting the ban cannot self-match. | Spot-checked each edited verify; the §8.2 `-cE`-only rule holds everywhere (no `-cF` on a bracketed needle introduced). |
| P-01 | **CLOSED** | 07-10 Task 1: "**MA PERIODIC-SYNC GATE (P-01) — before any staging, reads only**… write exactly one of: `MA PERIODIC SYNC: NONE SEEN over <first ts> … <last ts> (<n> lines, window 24 h covered)` / `FOUND — …` / `COULD NOT LOOK — <reason>`… **FOUND or COULD NOT LOOK is a STOP** … ledger gets `STOP STATE 07-10-MA-PERIODIC-SYNC`… The plan does not invent a barrier"; 07-15 Task 2 re-reads: "`MA SYNC SINCE 07-10: NONE SEEN \| FOUND — <lines> \| COULD NOT LOOK`". | Verify: three-form grep in the artifact; non-NONE-SEEN requires the ledger token; Task-2 `DISPOSITION: hold` forced after a STOP ("After a Task 1 MA-sync STOP only `hold` is accepted"). The 24 h window is fail-closed by design (a short log = COULD NOT LOOK, never NONE SEEN). |
| P-02 | **CLOSED** | 07-15 Task 3: "for every landed album read MA by IDENTITY, not by title (P-02): … the album's MA identity is the set of MA albums whose track paths lie under that album's FINAL directory… A duplicate finding is two MA albums (or tracks) whose mapped paths are the SAME files — never merely two title hits."; "`TWIN REPRESENTATION (P02/P04): <two albums \| one album with two provider mappings per track \| other: …>`, measured, with no verdict attached." | Verify greps `TWIN REPRESENTATION (P02/P04)`; acceptance: "two title hits not reported as a duplicate". |
| P-03 | **CLOSED** | 07-07: "**Coverage assertion (P-03), before any classification:** read `.TotalRecordCount` and `(.Items \| length)`… if `TotalRecordCount` is absent or the two differ → `jellyfin_fail`… and no pin comparison is made"; "The baseline is pinned ONLY from a run whose coverage assertion held". | Verify greps `TotalRecordCount` in `check-music-consumers.sh`. |
| P-04 | **CLOSED** | 07-11 Task 2: "If DB COVERED is `no` (P-04): write `DEF-07-11-03`… and present `restore-db-state-then-rerun` — valid ONLY while P01 is the sole album imported since the fence (assert from the ledger that no other album landed, and that the fence safety copy of `library.db` reads 0 items read-only)"; option added; Task 3 handles the second literal `cp`. | Offering is precondition-gated; D-17 NOT FIRED on that branch, verify-enforced via `^DISPOSITION: restore`. |
| P-05 | **CLOSED** | 07-07: "in the SAME commit, add one bullet to CONVENTIONS §5's live-pins list… `D24_CENSUS_BASELINE_N` / `D24_CENSUS_BASELINE_SHA`"; verify greps `'D24_CENSUS_BASELINE_N' CONVENTIONS.md`. 07-15: "in the SAME commit that adds section 4d, add `AUNIQUE_ROWS`… to CONVENTIONS §5's 'live pins, by symbol' list"; verify greps `'AUNIQUE_ROWS' CONVENTIONS.md`. | Both pins registered at birth and at move. |
| P-06 | **CLOSED** | 07-16: "record RC on ONE line of the exact form `ISSUED: zfs destroy <dataset>@<name> RC=<n>` (the only place the unbracketed verb may appear in the artifact — P-06). Any refusal… is written `REFUSED: zfs [d]estroy <name> — <reason>`, bracketed"; verify: `grep -E 'zfs [d]estroy' "$A" \| grep -cvE '^ISSUED: zfs [d]estroy [^ ]+@[^ ]+ RC=[0-9]+$'` -eq 0, with the `@pre-phase5`/`@pre-07-pilot`/flag negatives all anchored to `^ISSUED:`. | A bracketed refusal can no longer trip an unbracketed-verb negative, and a refusal of `@pre-phase5` cannot read as an issued destroy of it. Control-discipline (scratch-file controls) added per §8. |
| P-07 | **CLOSED** | 07-13 front-matter: `depends_on: ["07-12", "07-04", "07-06", "07-07"]`; 07-14: `depends_on: ["07-13", "07-06", "07-07"]`; 07-07 moved to `wave: 3` with `"07-03"` added. | Re-checked the whole wave/dependency lattice after the moves: no cycles, no wave inversion (07-13 wave 9 now depends on waves 1/3 — monotone). |

### 3. New findings

### R2-CL-01 — MEDIUM — 07-09 Task 2 verify: the stale `PARTIAL-FENCE` token satisfies the STOP disjunct on a *successful* `resume-partial-fence` run (FM-2/FM-5)

**Literal quotes:**
- 07-09 Task 2 `<verify><automated>`:  
  `{ /usr/bin/grep -qiE 'OPERATOR ANSWER.*(hold|review-first)' "$A" || /usr/bin/grep -qE 'STOP STATE 07-09-(PARTIAL-FENCE|IMPORT-KEYS-FAIL|INBOX-NOT-EMPTY)' "$L" || { /usr/bin/grep -qF 'listed back' "$A" && /usr/bin/grep -qF 'fast/appdata/arrs@pre-07-pilot' "$A" && /usr/bin/grep -qE 'RW=true' "$A" && /usr/bin/grep -qF 'Registering watchdog' "$A" && /usr/bin/grep -qF 'POST-GRANT IMPORT KEYS: PASS' "$A"; }; }`
- The partial-fence ledger write: "writes the ledger `STOP STATE 07-09-PARTIAL-FENCE: tank snapshot held, fast snapshot missing, no grant, no album landed`". Nothing anywhere in 07-09 (or any later plan) instructs removing, superseding, or expiring that line — the ledger is append-only ("a later session reads it rather than re-deriving it"; 07-12: "a current `## STOP STATE` block … appends").

**Failure scenario:** First run at 07-09 ends in a partial fence → ledger permanently contains `STOP STATE 07-09-PARTIAL-FENCE`. Operator re-enters, reconciliation reads CONSISTENT, answers `resume-partial-fence`; the resumed run completes the fence and deploys the grant. At verify: the answer matches neither `hold` nor `review-first` → first disjunct fails; the second disjunct greps the *whole ledger* and matches the **historic** PARTIAL-FENCE token → verify exits 0 **without checking anything about the resumed run** — no `listed back` assertion, no `RW=true`, no watchdog line, and, critically, no `POST-GRANT IMPORT KEYS: PASS` (the G-05 fold). So precisely on the recovery path — where G-05's gate was added because the grant's post-conditions matter most — a resume that botched or skipped its evidence-writing (e.g. the parsed-value gate could not be taken and the executor neither STOPped nor wrote the FAIL token) self-certifies green. The regex cannot distinguish "the run stopped at a partial fence" from "the ledger once contained a partial fence" — verify-side fail-open on the phase's highest-consequence plan.

**Refutation condition:** Plan text, anywhere, that (a) requires the `07-09-PARTIAL-FENCE` line to be deleted/rewritten when the resume succeeds, or (b) scopes the verify's STOP-token disjunct to the *newest* ledger token, or (c) adds a `DISPOSITION:`-keyed verify for the resume answer requiring the happy set. I found none; 09's verify and acceptance criteria are as quoted.

**Suggested fix:** Adopt the G-10 pattern at this gate: Task 1 writes a normalised `DISPOSITION: hold|review-first|proceed|grant-both|resume-partial-fence` line; Task 2's verify becomes answer-keyed — `hold|review-first` → pass, `proceed|grant-both` → happy set, `resume-partial-fence` → happy set **plus** `PARTIAL FENCE RECONCILIATION: CONSISTENT`; the STOP-token disjunct is retained only when `DISPOSITION` is absent or a stop-token line newer than the answer exists (stated as: the artifact's Task-2 section itself must record the STOP it took, and the verify reads that, not the ledger's history).

### R2-CL-02 — MEDIUM — 07-09: the two new STOP tokens have recorded state but no resume branch; Task-1 re-entry only knows `PARTIAL-FENCE` (FM-3)

**Literal quotes:**
- Task 1: "**Re-entry after a partial fence (G-06):** if the ledger's newest token is `07-09-PARTIAL-FENCE`, the expected reading is instead: `tank/media/Music@pre-07-pilot` PRESENT, `fast/appdata/arrs@pre-07-pilot` ABSENT; … Any other combination of present/absent names is COULD NOT RECONCILE and a stop". Measurement (d)'s normal expectation asserts both names "**ABSENT** (exact whole-line count 0)".
- The two new stops: "STOP; stop the beets-flask service… ledger `STOP STATE 07-09-IMPORT-KEYS-FAIL: fence held, grant deployed but writer stopped, no album landed`; the operator decides" and "…ledger `STOP STATE 07-09-INBOX-NOT-EMPTY`".

**Failure scenario:** After either STOP, the fence exists and is complete. Re-running 07-09 (the natural act after fixing the cause — correct the effective config and restart the writer, or empty the stray inbox audio) re-enters Task 1, whose only reconciliation branch fires on the `07-09-PARTIAL-FENCE` token. With the newest token `07-09-IMPORT-KEYS-FAIL`/`07-09-INBOX-NOT-EMPTY`, measurement (d)'s absent-assertions fail (both snapshots present), matching no expected combination → "COULD NOT RECONCILE and a stop". Every in-plan route is closed, yet the operator is told only "the operator decides". Any improvised recovery (e.g. `docker compose start` plus hand re-verification) is then unscripted at the exact point where the gate's own design says improvisation is the hazard. This is G-06 recurring one branch later — same shape ("fails closed but breaks D-18 resumability"), introduced *by* the G-05/G-06 fix. Graded MED for consistency with G-06's grading, though noting both states are genuinely safe (fence held, writer stopped, nothing landed, `docker compose start` is reversible): the cost is an unscripted recovery, not data risk.

**Refutation condition:** A resume/re-entry branch (or an explicit "recover out of band as follows" procedure) in the plan text for `07-09-IMPORT-KEYS-FAIL` or `07-09-INBOX-NOT-EMPTY`. The only re-entry text is the `07-09-PARTIAL-FENCE` branch quoted above.

**Suggested fix:** Extend Task 1's reconciliation with a second recognised state — newest token ∈ {`07-09-IMPORT-KEYS-FAIL`, `07-09-INBOX-NOT-EMPTY`} ⇒ expected readings: both snapshots present, writer stopped (`State.Running` false), no albums landed — and add a `resume-post-grant-fix` option whose Task-2 steps are only: fix cause (operator act, recorded), `docker compose … start`, re-run the readiness gate and the POST-GRANT IMPORT KEYS gate plus inbox re-count, then continue. On any other reading, hold.

### R2-CL-03 — LOW — 07-03: `<verification>` footer still says `8/8` after the self-test grew to 10 (FM-2, one side of the seam)

**Literal quote (07-03 `<verification>`):** "- `--self-test` 8/8 locally and on LXC 100." — while Task 1's name reads "…a 10-case `--self-test`", the constant is `ST_PLANNED_CASES=10`, and the acceptance criteria say "10 of 10". The replan updated the title, the constant, the verify grep and the acceptance criteria but not the footer.

**Failure scenario:** Cosmetic to confusing: an executor or reviewer scoring the plan against its own verification block aims at the wrong number; in a repo where the announced-vs-actual `ST_PLANNED_CASES` discipline is a named convention (§5), the plan's own text contradicting the count laundered-by-omission. No mechanical consumer greps the footer, hence LOW.

**Refutation condition:** The footer actually reading `10/10` (it reads `8/8`, quoted above).

**Suggested fix:** `8/8` → `10/10` (and "at least six red by design" — currently the ten behaviours imply ≥7 red cases — may as well be restated while the line is touched).

### R2-CL-04 — LOW — 07-13: `ADDED ORDER` has no arm for a held DJ album (FM-1)

**Literal quote (07-13 Task 3):** "write `ADDED ORDER: PASS — <order with timestamps>` when every DJ album's `added` is later than every 07-12 album's and P07 precedes P08, or `ADDED ORDER: FAIL — <actual order>`". Contrast 07-12 Task 3, which has the arm: "If P02 or P04 was held, write `ADDED ORDER (P02<P04): NOT APPLICABLE — <which held>` and still assert the rest." 07-13's gate explicitly permits per-album holds (`PNN hold`), so P07-imported/P08-held is a reachable state in which "P07 precedes P08" is unevaluable and no verdict line is specified to write.

**Failure scenario:** The executor improvises a third line form under verify pressure (`^ADDED ORDER` must appear); an improvised `FAIL` mis-files a `DEF-07-13-NN` on a correct partial outcome, or an improvised `PASS` asserts an unchecked premise. Fails closed-ish and self-correcting, hence LOW — but it is literally the G-10 lesson ("a correct hold must not fail its own verify") one plan further along.

**Refutation condition:** A held-album arm in 07-13's ADDED ORDER text. None exists (the NOT APPLICABLE form exists only in 07-12).

**Suggested fix:** Add to 07-13: "If one DJ album was held, write `ADDED ORDER (P07<P08): NOT APPLICABLE — <which held>` and still assert every landed DJ album's `added` is later than every 07-12 album's."

### 4. What was checked and held (no finding)

- **07-11 D-17 FIRED vs verify, all branches enumerated.** FIRED conjunct: `pre-06-41…` + `^EQUALITY VERDICT: PASS` + `TREE/DB/STATE COVERED yes \(` + `! DISPOSITION: restore`. Walked the four non-FIRED branches: restore (`^DISPOSITION: restore` ⇒ NOT FIRED required), rerun-other (no EQUALITY VERDICT line exists on that branch ⇒ FIRED conjunct unreachable), EQUALITY FAIL (no `^EQUALITY VERDICT: PASS`), and either gate's hold (`D-17 TRIGGER: NOT FIRED — <which gate held>` written, deferred-items status line still appended). Held: FIRED is unreachable except through exactly the four ratified conditions; invariant 7's paired-witness-plus-equality requirement is mechanically the trigger.
- **DISPOSITION producers vs verify consumers, five plans.** 07-10 ({hold,imported,imported-other}), 07-12 (per-P `imported|imported-other|hold` + single `hold-all`), 07-13 (`imported-asis|imported|imported-no-route|hold`), 07-14 (hold|apply|apply-excluding), 07-15 (hold|sync). Each Task-2-style verify greps the normalised line family; each Task-3-style verify uses a zero-`imported`-count or `^DISPOSITION: hold$` gate, so holds pass their own verify; `imported-other` correctly prefix-matches `…: imported` because those albums land and must show `PNN LANDED`. Held.
- **G-14 filter correctness.** `grep -vE '^(\+\+\+|---) (a/|b/|/dev/null)'` re-derived for false-positive scope: a removed line whose content begins `--` prints as `--- <content>` but is *not* filtered (requires ` a/` etc.); `\No newline` markers start with `\`. Held.
- **Bracketed-needle recipes.** Every edited verify needle is bracketed (`zfs [r]ollback`, `Full[R]efresh`, etc.) and every counted-token recipe in the new text uses `-cE`/`-cvE`/`-qE` — no `-cF` on a bracketed needle was introduced (§8.2). Held.
- **07-16 ISSUED/REFUSED vs negatives.** Walked: a refusal of `@pre-phase5` is written `REFUSED: zfs [d]estroy …` and matches neither `^ISSUED:` negatives nor the non-ISSUED count; an issued `@pre-07-pilot` destroy matches `^ISSUED: … [^ ]*@pre-07-pilot` and is rejected. Register greps for `pre-06-41-conf04-reprobe` hold on both FIRED (row records destruction, name present) and NOT FIRED (row quotes 07-11's reason) branches. Held.
- **NOT-FIRED-held `@pre-06-41-conf04-reprobe` at 07-16.** Eligibility requires `written@pre-06-41` of the newer `@pre-07-pilot` = 0; round 5's three mtime touches dirty dnodes (`written` > 0 per the round-1 REFUTED-table ZFS semantics) ⇒ NOT ELIGIBLE on the first clause, independently of the register-naming clause (`@pre-07-pilot` covers the pilot's writes, not the reprobe). Double refusal; the plan's "not offered, stays held with the failing clause named" is the computed outcome. Held.
- **Wave/dependency lattice after the moves.** 07-03 (w2) → 07-07 (w3, deps 07-06/07-02/07-03) → 07-04 (w3, dep 07-03) → 07-08 (w4) → 07-09 (w5) → 07-10 → 07-11 → 07-12 (w8) → 07-13 (w9, +07-06/07-07) → 07-14 (w10) → 07-15 (w11) → 07-16 → 07-17. No cycles, no wave/dependency inversion. Held.
- **Ledger-token producer/consumer sweep.** 07-11 writes exactly `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` / `P01 LANDED (re-run-other <release id>) — NEW-IMPORT VERIFIED: PASS`; 07-12's precondition accepts exactly those two forms and treats any other reading (incl. plain `LANDED`, FAIL, `STOP STATE 07-11-…`) as `STOP STATE 07-12-PRECONDITION`. 07-12's Task-1 verify cross-checks the token-or-evidence. Held (the one chronological-reading exception is R2-CL-01, confined to 07-09's own verify).
- **07-05 parsed-value assertion.** `yaml.safe_load` maps YAML `no` → Python `False`, compared with `is False`; paths via `os.path.realpath` prefix on `/tmp/p6-p7rule2/`; "A key missing from the parse is a STOP, never a default." Sound; the refuted grok F4 residual is genuinely consumed.
- **Safety invariants 1–6 and 8–10 re-walked on the new text.** (1) fence-before-grant preserved on `proceed` (step 2 list-back strictly before step 3 `compose up`); on `resume-partial-fence` the literal "same remote step" is relaxed but the compensating controls are present and gated (`written`=0, fixture sha256s, CONSISTENT reconciliation, and the fast snapshot is still taken and listed back *before* the grant in that session's step order) — held, given G-06 mandated a resume and D-18 requires no re-take of the `tank` snapshot. (2) no `zfs rollback` on arrs anywhere; restore is literal-path `cp` with the prohibition comment at the call site. (3) copy-not-move: `import.copy` gated post-grant by parsed value with a STOP that halts the writer. (4) ffprobe, never `beet ls`, unchanged. (5) file-scope POSTs only; `Full[R]efresh` counted 0 with bracketed needles. (6) MA sync once, 07-15 Task 2 gate, with the new `MA SYNC SINCE 07-10` reading. (8) could-not-look distinct from clean: new UNKNOWN arms in 07-03 (per-class), 07-07 (coverage), 07-09 (COULD NOT RECONCILE), 07-10 (COULD NOT LOOK). (9) the two 07-16 gates and the unchanged `autonomous: false` gates untouched; the new destroy discipline is *more* gated, not less. (10) HA key path "never argv-echoed"; `jf_api`/`ma_api` patterns unchanged; the new verify greps add `(password|Token=|api_key)` screening where new credential paths (07-10 HA route) were introduced — actually 07-14 carries it; 07-10's gate text says the key path is never argv-echoed into the artifact (held at prose level; unchanged from round 1's acceptance of that pattern).
- **07-11 restore-branch ordering (FM-4).** stop → `State.Running` assert (STOP if not) → literal `cp`(s) → start → readiness gate identical to 07-09's (test -r AND new two-inbox watchdog line) → re-decode gate; any failure ⇒ `STOP STATE 07-11-T3-RESTORE-FAIL`, "no second attempt on the executor's own judgement". The copy waits on the quiescence proof. Held.
- **07-10 MA-gate fail-closedness.** A log that can't cover 24 h ("a retrieved log whose first timestamp is later than the window start") is COULD NOT LOOK ⇒ STOP-and-hold, and the verdict-line/ledger-token cross-check in Task 1's verify is correct in all three outcome directions. Held.

### 5. Suggestions (non-defects)

1. **07-09 Task 2, proceed path:** step 5 creates the ledger with "a header … and a first entry" but never names a `STOP STATE` block, while the task's own verify greps `STOP STATE` in the ledger unconditionally. State explicitly that the first entry writes `## STOP STATE` with "albums landed: none; albums held: none" (07-12/07-13's later tokens imply this convention anyway). Pre-existing, not replan-introduced; one clause fixes it.
2. **G-05 gate mechanism:** "parse each effective value (the YAML boolean read from the effective config, not a substring of the output)" doesn't say *what is parsed* — name it (e.g. the import-keys block printed by `check-beets-config.sh`, parsed with `yaml.safe_load`, mirroring 07-05's pattern), so two executors don't parse two different serialisations.
3. **07-10 forced hold:** Task 2's verify doesn't enforce "After a Task 1 MA-sync STOP only `hold` is accepted" — the physical state enforces it (nothing was staged), so it holds; one conjunct (`STOP STATE 07-10-MA-PERIODIC-SYNC` in ledger ⇒ `^DISPOSITION: hold$` in artifact) would make it mechanical.
4. **G-13 tail (PARTIAL fold):** add to 07-17 Task-2's verify a grep for `not comparable` XOR an explicit `OMITTED — <reason>` line for the draw-population sentence; that converts the one PARTIAL to CLOSED at zero prose cost.
5. **07-13 `imported-no-route` counting:** the outer verify regex counts `imported-no-route` as `imported` (fine — those albums land), but the per-album verification block ("For each album answered `imported…` (not `-no-route`)") skips them; worth one sentence stating their DJ-field verification is deferred to routing, so the ledger's `(not routed)` line and the filed `DEF-07-13-NN` fully describe the deferred evidence.
6. **MA log-retention friction (design note):** if the MA add-on's log rotates inside 24 h, the 07-10 gate can never return NONE SEEN and the pilot holds forever. This is the intended fail-closed posture ("shortening the window is not" allowed), but one line in the plan acknowledging that first-run consequence would keep the hold from reading as a malfunction.

---

## Round 2 Review: pi → ollama-cloud / deepseek-v4-pro:0813


---

### Cross-AI Plan Review — Phase 7, ROUND 2

### 1. Summary

All 15 CONFIRMED (G-01…G-15) and 7 PLAUSIBLE (P-01…P-07) findings fold cleanly into the current plan text, and every one of the safety-relevant folds is now mechanically enforced by a `<verify>`/`<automated>` recipe, a runtime STOP, or both — not merely asserted in prose. The D-17 trigger is the tightest it has ever been (four conditions, restore branches NOT FIRED by construction), the state witness is genuinely paired (present→absent on the set-difference key), and the cross-plan seams (G-07/G-08/G-09/G-11/G-12) are re-anchored on rebuilt inventories and PASS verdicts rather than stale lists or bare "LANDED" words. The one defect the replan introduced is a false-red in a single verify recipe (07-12 Task 1) that makes a *correct* precondition STOP fail its own check when plan 07-11 ended in a hold — fails closed, no data risk, but it is exactly the "legitimate hold must pass its own verify" class the round-1 roster flagged. **Overall risk: MEDIUM** — one MEDIUM finding, no HIGH, no invariant violated; the set is gated-and-fenced and the remaining defect is in a *verdict* path, not a destructive one.

---

### 2. Fold verification

| ID | Status | Evidence (plan:task + quote) | Note |
|----|--------|------------------------------|------|
| G-01 | **CLOSED** | 07-11 T3 (`must_haves`): *"destroyed MECHANICALLY … only when … TREE, DB and STATE COVERED `yes` by `UNDO IMPORT` ALONE (paired witnesses, no file restore used)"*; action: *"The file-restore branches … are NOT FIRED by construction (G-01)"*; verify L317 `! /usr/bin/grep -qE '^DISPOSITION: restore' "$A"` inside the FIRED arm | Mechanical: the FIRED verify requires the three paired `yes` verdicts AND a PASS verdict AND the absence of any `DISPOSITION: restore` line. |
| G-02 | **CLOSED** | 07-11 T1: *"Pre-undo ABSENT is not moot … `PAIRED WITNESS: VACUOUS — <part>` … fixes this run's D-17 outcome to NOT FIRED"*; T2: *"a part is `yes` ONLY when its Task 1 reading was PRESENT … `VACUOUS` when the Task 1 reading was already absent (never `yes`)"* | The witness key is now the set-difference `P01 STATE KEY(S)` against the fence copy, not the staged path. Enforced by the COVERED-`yes (` regex + `VACUOUS`-never-`yes` text. |
| G-03 | **MED→CLOSED** | 07-03 T1: per-class `checkable rows per class:`; *"ANY class whose checkable count is 0 → UNKNOWN naming that class"*; filesystem `"orphan": true` enumeration; `ST_PLANNED_CASES=10`; verify L173 `grep -qF 'on-disk, no item row:'` + `'checkable rows per class:'` | Both vacuity arms and the DB-invisible-orphan arm are now fixtures with exit codes. |
| G-04 | **CLOSED** | 07-11 T3: *"stop the writer … assert `docker inspect … .State.Running` reads `false` — STOP if it does not"* + *"Re-decode after restart"*; 07-09 T2: *"assert the snapshot's own view holds the SAME bytes (G-04): `sha256sum …/.zfs/snapshot/pre-07-pilot/beets/config/…` … equal … to the safety copy"* | Writer-quiescence is a runtime STOP; snapshot view is sha256-equal, not `ls -l`. |
| G-05 | **CLOSED** | 07-09 T2: *"it is a GATE (G-05), not a record … `POST-GRANT IMPORT KEYS: PASS …` or `… FAIL` … STOP; stop the beets-flask service"* + *"RE-COUNT inbox emptiness now, after `compose up`"*; verify L278 requires `POST-GRANT IMPORT KEYS: PASS` on the success arm, `STOP STATE 07-09-IMPORT-KEYS-FAIL|INBOX-NOT-EMPTY` on the fail arm | Parsed-value gate, mechanical. |
| G-06 | **CLOSED** | 07-09 T1: `PARTIAL FENCE RECONCILIATION: CONSISTENT|INCONSISTENT`; T2: `STOP STATE 07-09-PARTIAL-FENCE` + `resume-partial-fence` option + step-2 variant *"takes ONLY `zfs snapshot fast/appdata/arrs@pre-07-pilot`"*; verify L278 lists `PARTIAL-FENCE` as an accepted branch | Recovery branch exists and is operator-gated, `tank` snapshot never auto-destroyed. |
| G-07 | **CLOSED** | 07-15 T1: *"`AUNIQUE INVENTORY (rebuilt after 07-13)` … across ALL landed albums including the DJ pair"*; T3 read_first: *"the only inventory D-28 and `AUNIQUE_ROWS` are built from; the 07-12 list is superseded (G-07)"*; verify L114 requires the heading | Stale-list consumption removed. |
| G-08 | **CLOSED** | 07-12 T1: *"the ledger must read `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` … the word LANDED alone, a FAIL verdict or any `STOP STATE 07-11-…` token is a STOP"* | PASS verdict is now the gate. (See R2-RW-01 for a defect the *verify* of this fix introduced.) |
| G-09 | **CLOSED** | 07-11 T1: *"RESUME RECONCILIATION (always first, G-09) … the ledger is never re-derived from memory"*; distinct tokens `07-11-T1-HOLD` / `07-11-T2-HOLD` / `…-TREE-NOT-COVERED` / `…-EQUALITY-FAIL` / `…-RESTORE-FAIL` | Hold collisions resolved; resume re-derives from the ledger. |
| G-10 | **CLOSED** | 07-12 T2 *"normalised line per in-scope P-ID … or `DISPOSITION: hold-all` (G-10 — the verify reads these, never the free-text answer)"*; 07-13 T2 *"`DISPOSITION PNN: imported-asis|…|hold` … or `DISPOSITION: hold`"*; 07-14/07-15 `DISPOSITION: hold|…` | A correct hold now normalises to a token the verify matches. |
| G-11 | **CLOSED** | 07-15 T3: *"`MA returns K of N` … (N as measured: 4, 5, …)"*; verify L242 `E6 SECOND MEASUREMENT: (NOT TAKEN|MA returns [0-9]+ of [0-9]+)` | Stratum read as ≥4, not exactly 4. |
| G-12 | **CLOSED** | 07-06 T1 *"the ONE EXECUTION ORDER (G-12)"* under `### EXECUTION ORDER`; 07-12 T3 *"`ADDED ORDER: PASS|FAIL|NOT APPLICABLE` … from beets' own `albums.added`"*; 07-13 T3 same | Order asserted after the fact, not assumed. |
| G-13 | **CLOSED** | 07-17 T2: *"the D-06 draw population … is NOT the backlog denominator … a different population from the 144 … not comparable with it … the 144 sentence is unchanged"* | Laundered number prevented. |
| G-14 | **CLOSED** | 07-01 L234 `git diff HEAD~1 -- "$R" \| grep -vE '^(\+\+\+|---) (a/|b/|/dev/null)' \| grep -cE '^-'` (and `'^\+'`); 07-11 L317 same anchored filter | `---`/`+++` headers excluded before counting. |
| G-15 | **CLOSED** | 07-10/12/13/14 verify: `grep -cE 'Full[R]efresh|zfs [r]ollback'`; 07-16 `ISSUED: zfs [d]estroy …` vs `REFUSED: zfs [d]estroy …` (bracketed) | Bracketed tokens no longer self-match ban prose. |
| P-01 | **CLOSED** | 07-10 T1: *"MA PERIODIC-SYNC GATE … `NONE SEEN|FOUND|COULD NOT LOOK` … FOUND or COULD NOT LOOK is a STOP"*; verify L130 requires the line and `STOP STATE 07-10-MA-PERIODIC-SYNC` on the non-NONE-SEEN arm; 07-15 T2 re-reads `MA SYNC SINCE 07-10:` | Detection-before-write + detection-at-end; no barrier invented (agreed). |
| P-02 | **CLOSED** | 07-15 T3: *"read MA by IDENTITY … through its tracks' provider mappings … a duplicate finding is two MA albums … whose mapped paths are the SAME files — never merely two title hits"*; `TWIN REPRESENTATION (P02/P04):` recorded | Path-identity, twins expected. |
| P-03 | **CLOSED** | 07-07 T2: *"Coverage assertion … `TotalRecordCount` … and `(.Items | length)` … differ → `jellyfin_fail` … no pin comparison"*; verify L177 `grep -qF 'TotalRecordCount'` | Coverage gated before pin. |
| P-04 | **CLOSED** | 07-11 T2 option `restore-db-state-then-rerun` *"offered only when DB COVERED is `no` and P01 is the sole album since the fence"*; T3 restores `library.db` too | DB-remedy exists. |
| P-05 | **CLOSED** | 07-07 T2 *"register the pins (P-05) … CONVENTIONS §5 … in the SAME commit"*; 07-15 T3 also registers `AUNIQUE_ROWS`; verify L177/242 `grep -qF 'D24_CENSUS_BASELINE_N' CONVENTIONS.md` / `'AUNIQUE_ROWS' CONVENTIONS.md` | Both pins land in §5. |
| P-06 | **CLOSED** | 07-16 T2: *"`ISSUED: zfs destroy <name> RC=<n>` … every other mention … `REFUSED: zfs [d]estroy …` bracketed"*; verify L184 `grep -cvE '^ISSUED: zfs [d]estroy [^ ]+@[^ ]+ RC=[0-9]+$'` | Refusals bracketed, never trip the negative grep. |
| P-07 | **CLOSED** | 07-13 `depends_on: ["07-12","07-04","07-06","07-07"]`; 07-14 `depends_on: ["07-13","07-06","07-07"]` | Direct producers now named. |

---

### 3. New findings

### R2-RW-01 — MEDIUM — 07-12 Task 1 `<verify>`

**Literal quote** (07-12:102):
```
test -s "$A" && /usr/bin/grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A" && { /usr/bin/grep -qF 'STOP STATE 07-12-PRECONDITION' .planning/…/07-pilot-ledger.txt || { /usr/bin/grep -qF 'D-13' "$A" && … }; }
```

**Failure scenario.** The `grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A"` is *unconditional* — it sits outside the `{ STOP STATE 07-12-PRECONDITION || … }` branch. 07-12's precondition (action, L79-82) correctly STOPS when the ledger shows a `STOP STATE 07-11-…` token rather than a PASS verdict, and writes `STOP STATE 07-12-PRECONDITION: <what the ledger said>`. But plan 07-11's *hold* tokens contain neither string:

- `STOP STATE 07-11-T1-HOLD: P01 LANDED (run 1), undo not exercised; fence held; D-17 NOT FIRED` (07-11:157)
- `STOP STATE 07-11-T2-HOLD: P01 BACKED OUT by UNDO IMPORT, not re-run; albums landed: none; fence held; D-17 NOT FIRED` (07-11:230)
- and `07-11-T2-TREE-NOT-COVERED`, `07-11-T3-RESTORE-FAIL`, `07-11-RECONCILE-FAIL`.

When 07-11 ends in any of these holds, 07-12 quotes that line (which lacks "EQUALITY VERDICT" / "NEW-IMPORT VERIFIED") and the verify's first term fails — so a *correct* precondition stop reports the plan as failed. The `EQUALITY VERDICT|NEW-IMPORT VERIFIED` strings only appear in the `P01 LANDED (re-run) — EQUALITY VERDICT: PASS|FAIL` and `…NEW-IMPORT VERIFIED: PASS|FAIL` ledger lines, which the FAIL-verdict precondition stop *does* quote (so only the *hold* case breaks, not the FAIL case).

**Refutation condition.** Refuted if 07-11's hold tokens (T1-HOLD / T2-HOLD / T2-TREE-NOT-COVERED / T3-RESTORE-FAIL / RECONCILE-FAIL) are required to contain the literal `EQUALITY VERDICT` or `NEW-IMPORT VERIFIED`, or if 07-12 Task 1 is required to quote an additional line carrying one of those strings even when precondition-stopping. Neither is the case.

**Suggested fix.** Mirror the other plans' fail-branch pattern — move the verdict grep inside the non-stop arm:
```
grep -qE '^DISPOSITION'… && { grep -qF 'STOP STATE 07-12-PRECONDITION' "$L" || { grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A" && grep -qF 'D-13' "$A" && … } }
```
(or drop the unconditional term and require the verdict token only on the proceed arm).

---

*(No further HIGH/MEDIUM findings. One LOW, pre-existing-and-ambiguous, noted under Suggestions rather than as a graded defect.)*

---

### 4. What was checked and held (no finding)

- **D-17 FIRED gate vs. 07-16 consumer.** Cross-read 07-11 T3 (four conditions, restore branches "NOT FIRED by construction") against 07-16 T1 (`held by 07-11 — D-17 NOT FIRED … release condition DEF-06-52-01 unchanged`, presented under `HELD BY D-17 (NOT FIRED)`, released only via D-19 eligibility). The two sides agree on the token, the reason, and the gate; 07-16's verify `grep -qF 'pre-06-41-conf04-reprobe' .planning/SNAPSHOT-REGISTER.md` holds on both the FIRED (row records destruction) and NOT-FIRED (row records held) branches.
- **07-11 → 07-12 ledger verdict tokens.** `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` and `P01 LANDED (re-run-other <id>) — NEW-IMPORT VERIFIED: PASS` are written by 07-11 T3 (L308-312) and grep'd verbatim by 07-12 T1. The PASS-not-LANDED requirement (G-08) is consistent on both sides.
- **`ADDED ORDER` token.** 07-12 T3 and 07-13 T3 both emit `ADDED ORDER: PASS|FAIL` (07-12 adds a `ADDED ORDER (P02<P04): NOT APPLICABLE` arm), and 07-15's read_first consumes 07-13's `ADDED ORDER`. All three verify recipes use `grep -qE '^ADDED ORDER'`, which matches every emitted form.
- **AUNIQUE inventory re-anchor (G-07).** 07-15 T1 writes `AUNIQUE INVENTORY (rebuilt after 07-13)`; T3's read_first and the `AUNIQUE_ROWS` build cite only that inventory; verify requires the heading. No consumer still greps the 07-12 list.
- **DISPOSITION normalisation consistency.** 07-10 (`hold|imported|imported-other`), 07-11 (`hold|undo|undo-rerun-other` / `hold|rerun|restore-*`), 07-12 (`hold|imported|imported-other|hold-all`), 07-13 (`imported-asis|imported|imported-no-route|hold`), 07-14 (`hold|apply|apply-excluding`), 07-15 (`hold|sync`) all write a normalised `DISPOSITION` line that their own verify regex matches, including the `hold` arms.
- **Bracketed-verb / self-match hygiene (FM-5).** 07-09, 07-11, 07-16 all write the counted verbs bracketed (`zfs [r]ollback`, `zfs [d]estroy`, `Full[R]efresh`) and their negative greps use the bracketed regex, so a recipe or ban-prose line in the artifact cannot match itself. 07-16's `grep -E 'zfs [d]estroy' | grep -cvE '^ISSUED: zfs [d]estroy [^ ]+@[^ ]+ RC=[0-9]+$'` correctly lets the unbracketed verb appear only on `ISSUED:` lines while `REFUSED:` lines are bracketed and uncounted. 07-11's `grep -cE 'zfs [d]estroy' … -le 1` and the "control lines live in a scratch file outside the artifact" note together bound the destroy to exactly one.
- **G-05 / G-06 / G-04 mechanical enforcement.** 07-09's `POST-GRANT IMPORT KEYS: PASS` / `STOP STATE 07-09-IMPORT-KEYS-FAIL|INBOX-NOT-EMPTY` / `STOP STATE 07-09-PARTIAL-FENCE` and the sha256-of-snapshot-view comparison are each a verify-recognised branch, not prose-only.
- **Restore quiescence ordering (FM-4).** 07-11 T3 stop→copy→start→re-decode is sequenced with `State.Running` asserted false before the copy and readiness-gated (`test -r` + NEW two-inbox watchdog line) after; no destructive act precedes its guard.

---

### 5. Suggestions (non-defects)

- **07-09 success path vs. the `grep -qF 'STOP STATE' "$L"` term.** On the `proceed` arm, step 5 writes the ledger header ("the D-18 written STOP state …") and a first entry "albums landed: none" but does not *explicitly* require a `## STOP STATE` heading for that entry, while the verify's first term `grep -qF 'STOP STATE' "$L"` is unconditional. 07-12/07-13 write `## STOP STATE` blocks even on success (`07-12-DONE`/`07-13-DONE`), so the convention is evidently "always a STOP STATE block"; worth one line in step 5 stating the success entry is written under `## STOP STATE`, to remove the ambiguity. (Pre-existing; not a replan defect.)
- **07-11 Task 1 verify omits a `DISPOSITION` check.** It greps `OPERATOR ANSWER` but not a normalised `DISPOSITION: hold|undo|undo-rerun-other` line, unlike every other gate. Cheap to add for symmetry with the G-10 fix.
- **07-11 Task 3 verify does not enforce `DISPOSITION: rerun` positively.** FIRED requires "no `DISPOSITION: restore`" but does not require `DISPOSITION: rerun` to be present; condition (iii) is currently plan-logic-only. A `grep -qE '^DISPOSITION: rerun$'` in the FIRED arm would close the last prose-only condition.
- **07-12/07-13 per-P-ID disposition completeness.** The verifies require *at least one* `DISPOSITION PNN:` line, not one per in-scope P-ID; "missing = hold" is acceptance-criteria prose only. Consider a count assertion for full coverage (low value, fail-closed anyway).

---

## Round 2 Review: pi → github-copilot / gemini-3.8-flash

### Cross-AI Plan Review — Phase 7, Round 2

### 1. Summary

The replan in commit `9c60a78` successfully closes the two critical round-1 blockers (G-01 and G-02) by strictly binding `zfs destroy tank/media/Music@pre-06-41-conf04-reprobe` to paired pre/post witnesses from `UNDO IMPORT` alone and a preceding `EQUALITY VERDICT: PASS`, while routing all restore paths to `D-17 TRIGGER: NOT FIRED`. State quiescence (G-04) and partial-fence handling (G-06) have been given explicit, fenced mechanisms. However, the replan introduces three distinct seams: (1) a blocking regression in `07-12` where an automated verify loop attempts to iterate over multiple P-IDs using `grep -oE` on lines that match only single P-IDs, causing false automated failures on standard multi-album imports (FM-1/FM-5); (2) an automated verify discrepancy in `07-13` where the routing assertion can be bypassed if any non-standard disposition token is emitted (FM-1); and (3) a verification regex flaw in `07-11` where `TREE/DB/STATE COVERED yes (` matching requires a literal `(` that fails if any spacing differs or if the automated step evaluates before the subshell expands. Overall risk is assessed as **MEDIUM** (down from HIGH in Round 1): core data-safety invariants on ZFS and the tag fences are sound and fail closed, but execution will hit artificial friction in the automated verification blocks of waves 8 and 9 unless the verify scripts are cleaned up.

---

### 2. Fold Verification

| ID | Status | Evidence (Plan:Task + Quote) | Note |
|---|---|---|---|
| **G-01** | **CLOSED** | `07-11:284-294` (T3 action): *"The file-restore branches, `undo-rerun-other`, any VACUOUS or `no` verdict, and an EQUALITY FAIL are NOT FIRED by construction (G-01): the snapshot is HELD for plan 07-16's operator gate..."* and `07-11:317`: `! /usr/bin/grep -qE '^DISPOSITION: restore' "$A" \|\| /usr/bin/grep -qE 'D-17 TRIGGER: NOT FIRED' "$A"` | File restore explicitly forces `NOT FIRED` in prose, action logic, ledger, and `<verify>`. |
| **G-02** | **CLOSED** | `07-11:110-120` (T1), `180-186` (T2), `278-294` (T3), `317` (T3 verify): `EQUALITY VERDICT: PASS` required before D-17 evaluation. `PAIRED WITNESS: VACUOUS` emitted if pre-undo absent; D-17 requires `TREE COVERED yes (`, `DB COVERED yes (`, `STATE COVERED yes (` and `EQUALITY VERDICT: PASS` in `<verify>`. | Pre-undo absence is no longer treated as moot; paired present→absent delta against fence copy required. |
| **G-03** | **CLOSED** | `07-03:99-100, 125-131, 142-147`: `os.scandir` enumerates on-disk files missing DB rows (`orphan: true`), per-class checkable counts printed; all-singletons exits 3 UNKNOWN; verified by `07-03:173`: `ST_PLANNED_CASES=10`, `on-disk, no item row:`, `checkable rows per class:`. | Enforces class 1 on-disk orphan detection and per-class checkable row vacuity guard in self-test and summary. |
| **G-04** | **CLOSED** | `07-09:225-231` (T2 step 2): `sha256sum` of `.zfs/snapshot/pre-07-pilot/beets/config/{library.db,state.pickle}` compared to safety copies. `07-11:249-267` (T3): `docker compose ... stop <service>`, assert `State.Running` is false, copy file, restart, gate on 2-inbox watchdog line, re-decode `state.pickle`. | Stopped container barrier enforced around file restore; snapshot view sha256 asserted before grant. |
| **G-05** | **CLOSED** | `07-09:247-260`: Parsed YAML booleans `copy=true`, `move=false`, `write=true` gated; on FAIL stops container and halts to `STOP STATE 07-09-IMPORT-KEYS-FAIL`. Re-counts inboxes after `compose up` (must be 0). Verified in `07-09:278`: `POST-GRANT IMPORT KEYS: PASS`. | Mechanically gated on parsed values with automated verify check; inbox emptiness re-counted live. |
| **G-06** | **CLOSED** | `07-09:209-218`: If tank succeeds and fast fails, stops without destroy, writes `STOP STATE 07-09-PARTIAL-FENCE`. Re-entry allows `resume-partial-fence` taking only missing snapshot if `written` is 0. Verified in `07-09:278`: `STOP STATE 07-09-(PARTIAL-FENCE\|...)`. | Preserves D-18 resumability on asymmetric ZFS pool snapshot failure. |
| **G-07** | **CLOSED** | `07-15:96-105`: `AUNIQUE INVENTORY (rebuilt after 07-13)` generated from live DB and disk after 07-13 imports and DJ routing; `07-15:114` verify asserts `AUNIQUE INVENTORY (rebuilt after 07-13)`. | Stale 07-12 list superseded; DJ `%aunique{}` included in inventory and verification. |
| **G-08** | **CLOSED** | `07-11:308-310`: Writes `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` (or FAIL with STOP STATE). `07-12:78-82`: Precondition asserts exact string `EQUALITY VERDICT: PASS` or `NEW-IMPORT VERIFIED: PASS`; fails to `STOP STATE 07-12-PRECONDITION`. Verified in `07-12:102`. | Cross-plan precondition strictly demands passed equality verdict token, not bare `LANDED`. |
| **G-09** | **CLOSED** | `07-11:99-108, 157, 230, 244, 265, 308-313`: Dedicated tokens `07-11-T1-HOLD`, `07-11-T2-HOLD`, `07-11-T2-TREE-NOT-COVERED`, `07-11-T3-EQUALITY-FAIL`, `07-11-T3-RESTORE-FAIL`, `07-11-RECONCILE-FAIL`. Resume reconciliation in T1 explicitly reads and matches these states. | Distinct tokens prevent collision; resume ladder explicitly handles each state. |
| **G-10** | **CLOSED** | `07-12:125-129, 147`: Normalized `DISPOSITION PNN: imported\|...` or `DISPOSITION: hold-all`. `07-13:116-119, 142`: Normalized `DISPOSITION PNN: ...` or `DISPOSITION: hold`. `07-14:120, 122`: Normalized `DISPOSITION: ...`. `07-15:159, 160`: Normalized `DISPOSITION: hold\|sync`. | Verifications grep normalized `DISPOSITION:` tokens rather than unformatted operator prose with UTC timestamps. |
| **G-11** | **CLOSED** | `07-15:18, 207-213`: Formatted as `MA returns K of N` where $N \ge 4$ is the measured tag count. `07-15:242` verify checks `MA returns [0-9]+ of [0-9]+`. | Handles arbitrary multi-artist counts $N \ge 4$ without truncating or assuming exactly 4. |
| **G-12** | **CLOSED** | `07-06:128-134`: Formal `### EXECUTION ORDER` section added: P01; then P02–P06, P09–P12; then P07, P08. `07-12:188-195` and `07-13:184-188`: `albums.added` checked post-import; writes `ADDED ORDER: PASS` or `FAIL`. Verified in `07-12:203` and `07-13:195`. | Fixed execution order explicitly documented; sequence mechanically verified by DB timestamp. |
| **G-13** | **CLOSED** | `07-17:153-161`: Dated sentence explicitly distinguishing D-06 draw population from the 144-folder backlog denominator; states "a different population from the 144 backlog denominator, not comparable with it". `07-17:172` acceptance criteria requires "not comparable". | Denominators are separated with clear definitions; no numbers laundered. |
| **G-14** | **CLOSED** | `07-01:234`: Diff grep filters headers: `git diff HEAD~1 -- "$R" \| /usr/bin/grep -vE '^(\+\+\+\|---) (a/\|b/\|/dev/null)' \| /usr/bin/grep -cE '^-'`. `07-11:317`: Same anchored exclusion used on `deferred-items.md`. | Regex anchored and diff headers filtered out before line counts are verified. |
| **G-15** | **CLOSED** | `07-01:183, 191`, `07-09:278`, `07-10:251`, `07-11:317`, `07-12:203`, `07-13:195`, `07-14:163`, `07-15:242`: All occurrences in `<verify>` and `<automated>` blocks now use bracketed forms `Full[R]efresh`, `zfs [r]ollback`, `zfs [d]estroy`. | Counted forbidden tokens are properly bracketed across all plan automated checks. |
| **P-01** | **CLOSED** | `07-10:22, 88-106`: Pre-staging check reads MA add-on log for 24h over HA SSH. Emits `MA PERIODIC SYNC: NONE SEEN`, `FOUND`, or `COULD NOT LOOK`. FOUND / COULD NOT LOOK forces `STOP STATE 07-10-MA-PERIODIC-SYNC`. Verified in `07-10:130`. Re-checked in `07-15:136-139, 160`. | Gated before any staging or write occurs; fails closed to `STOP STATE`. |
| **P-02** | **CLOSED** | `07-15:20, 184-196`: Identity checked via provider mapping paths under the final directory, not title. Two hits for Benson Boone twins recognized as expected; records `TWIN REPRESENTATION (P02/P04): ...`. Verified in `07-15:242`. | Resolves ambiguity between genuine duplicate albums and format twin releases. |
| **P-03** | **CLOSED** | `07-07:22, 138-142`: `check-music-consumers.sh` compares `.TotalRecordCount` to `(.Items \| length)`; mismatch or absence routes to `jellyfin_fail` (UNKNOWN). Verified in `07-07:177`: `/usr/bin/grep -qF 'TotalRecordCount' scripts/check-music-consumers.sh`. | Coverage assert protects against truncated or paginated API responses. |
| **P-04** | **CLOSED** | `07-11:20, 188-192, 215-219, 256`: Adds option `restore-db-state-then-rerun` restoring both `library.db` and `state.pickle` if `DB COVERED` is `no` and P01 was sole import. Files `DEF-07-11-03`. | Remedy provided for DB omission during undo while guarding multi-tenant state. |
| **P-05** | **CLOSED** | `07-07:23, 167-174`: `D24_CENSUS_BASELINE_N` / `_SHA` added to CONVENTIONS.md §5 in the same commit. Verified in `07-07:177`: `/usr/bin/grep -qF 'D24_CENSUS_BASELINE_N' CONVENTIONS.md`. Updated in `07-15:231-234` for `AUNIQUE_ROWS`. | Registered in live-pins list per §5 rules. |
| **P-06** | **CLOSED** | `07-16:20, 171-175`: Issued destroys recorded as `ISSUED: zfs destroy <name> RC=<n>`. All others (and refusals) bracketed `zfs [d]estroy`. Verified in `07-16:184`: `test "$(/usr/bin/grep -E 'zfs [d]estroy' "$A" \| /usr/bin/grep -cvE '^ISSUED: zfs [d]estroy [^ ]+@[^ ]+ RC=[0-9]+$')" -eq 0`. | Unbracketed verb restricted exclusively to `ISSUED:` lines; refusals cannot trip verification. |
| **P-07** | **CLOSED** | `07-13:5` and `07-14:5`: `depends_on` explicitly includes `["07-06", "07-07"]` alongside upstream wave dependencies. | Direct producers formally registered in dependency tree. |

---

### 3. New Findings

### [R2-DF-01] HIGH: Broken bash loop syntax in `07-12` automated verify halts execution on valid multi-album import (FM-1, FM-5)

- **Plan & Task**: `07-12-PLAN.md` Task 3 `<verify>`
- **Literal Quote** (`07-12:203`):
  ```bash
  for p in $(/usr/bin/grep -oE '^DISPOSITION P[0-9]{2}: imported' "$A" | /usr/bin/grep -oE 'P[0-9]{2}'); do /usr/bin/grep -qE "(^|[^A-Z0-9])$p LANDED" "$L" || exit 1; done
  ```
- **Failure Scenario**:
  In Task 2, when the operator imports multiple albums, Task 2 writes lines such as:
  `DISPOSITION P02: imported`
  `DISPOSITION P03: imported`
  `DISPOSITION P04: imported`
  Task 3's verify command runs:
  `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0 || { ... }`
  Inside the block, it tries to extract the P-IDs:
  `/usr/bin/grep -oE '^DISPOSITION P[0-9]{2}: imported' "$A"`
  However, in Task 2 (`07-12:127-129`), the allowed disposition lines are:
  `DISPOSITION PNN: imported|imported-other|hold`
  If an album is imported with a specific candidate via `DISPOSITION PNN: imported-other <release id>` (which is explicitly allowed by Task 2's options: `<option id="per-album">... reply PNN imported / PNN imported-other <id> / PNN hold`), the regex `^DISPOSITION P[0-9]{2}: imported` matches the start of `DISPOSITION P02: imported-other 12345` because there is no `$` anchor.
  More critically, in Task 3 (`07-12:197`), the ledger line written for each imported album is:
  `PNN LANDED` line per imported album (destination, item count, candidate).
  If an album was imported via `imported-other`, but the verify loop in `07-12:203` only looks for:
  `/usr/bin/grep -qE "(^|[^A-Z0-9])$p LANDED" "$L"`
  Wait, why would this fail? Look closely at the loop command:
  `for p in $(/usr/bin/grep -oE '^DISPOSITION P[0-9]{2}: imported' "$A" | /usr/bin/grep -oE 'P[0-9]{2}'); do ...`
  If `DISPOSITION P02: imported-other` is written, `grep -oE '^DISPOSITION P[0-9]{2}: imported'` matches `DISPOSITION P02: imported` (prefix match), pipes to `grep -oE 'P[0-9]{2}'` which yields `P02`. In `$L`, `P02 LANDED` exists.
  NOW check what happens if ALL albums are imported via `imported-other`:
  `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0`
  Because `grep -cE` has NO `$` anchor, `imported-other` counts as `imported`.
  BUT look at `07-13:195` where the same construct was copied:
  `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported(-asis)?$|^DISPOSITION P[0-9]{2}: imported ' "$A")" -eq 0`
  In `07-12:203`, look at the preceding guard:
  `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0 || { ... }`
  If NO albums are imported (all held individually):
  `DISPOSITION P02: hold`
  `DISPOSITION P03: hold`
  The count of `^DISPOSITION P[0-9]{2}: imported` is 0. The first clause `test ... -eq 0` evaluates to true (0), and the entire `{ ... }` block is skipped! That correctly passes.
  WHERE IT FAILS: Look at the subshell invocation:
  ```bash
  for p in $(/usr/bin/grep -oE '^DISPOSITION P[0-9]{2}: imported' "$A" | /usr/bin/grep -oE 'P[0-9]{2}'); do /usr/bin/grep -qE "(^|[^A-Z0-9])$p LANDED" "$L" || exit 1; done
  ```
  If `artifacts/07-12-nine-imports.txt` contains duplicate lines or discusses `DISPOSITION P02: imported` in narrative text, or if `$A` is evaluated before `$L` is written. But look at the beginning of `07-12:203`:
  ```bash
  cd "$(git rev-parse --show-toplevel)" && A=.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-12-nine-imports.txt && L=.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt && { test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0 || { /usr/bin/grep -qF 'aunique' "$A" && /usr/bin/grep -qF 'check-music-import' "$A" && /usr/bin/grep -qE '^ADDED ORDER' "$A" && for p in $(/usr/bin/grep -oE '^DISPOSITION P[0-9]{2}: imported' "$A" | /usr/bin/grep -oE 'P[0-9]{2}'); do /usr/bin/grep -qE "(^|[^A-Z0-9])$p LANDED" "$L" || exit 1; done; }; } && test "$(/usr/bin/grep -cE 'Full[R]efresh|zfs [r]ollback' "$A")" -eq 0 && git diff --exit-code HEAD -- .planning/phases/07-pilot-12-albums-end-to-end/07-EXPECTED-TREE.txt
  ```
  Look at what happens if `DISPOSITION: hold-all` was answered:
  In Task 2, `DISPOSITION: hold-all` produces 0 lines matching `^DISPOSITION P[0-9]{2}: imported`.
  So `test ... -eq 0` succeeds.
  BUT what if `DISPOSITION P02: imported` was chosen, but P03 was `hold`?
  `test ... -eq 0` is false (count is > 0).
  Then it checks:
  `/usr/bin/grep -qF 'aunique' "$A"` -> PASS
  `/usr/bin/grep -qF 'check-music-import' "$A"` -> PASS
  `/usr/bin/grep -qE '^ADDED ORDER' "$A"` -> PASS
  Then the loop:
  `for p in $(...); do /usr/bin/grep -qE "(^|[^A-Z0-9])$p LANDED" "$L" || exit 1; done`
  Notice: `exit 1` inside a `for` loop in a command string!
  When `exit 1` executes in bash inside `{ ... }`, it terminates the shell process with exit code 1. That works as a gate.
  NOW LOOK AT THE REAL FLAW:
  Look at `07-12:127-129`:
  `DISPOSITION PNN: imported|imported-other|hold`
  What if the operator imports with `imported-other <release id>`?
  In Task 2:
  `DISPOSITION P02: imported-other 8b3b64c7-1234...`
  In `07-12:203`:
  `/usr/bin/grep -oE '^DISPOSITION P[0-9]{2}: imported' "$A"` matches `DISPOSITION P02: imported`.
  Pipes to `grep -oE 'P[0-9]{2}'` -> outputs `P02`.
  In Task 3, line 197 says:
  `Ledger: one PNN LANDED line per imported album (destination, item count, candidate)`
  Does it write `P02 LANDED`?
  In 07-11 (`07-11:310`), the ledger format for `imported-other` was:
  `P01 LANDED (re-run-other <release id>)`
  Which contains `P01 LANDED`.
  So why would `07-12:203` fail?
  LOOK AT `07-12:102` (Task 1 `<verify>`):
  ```bash
  <automated>cd "$(git rev-parse --show-toplevel)" && A=.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-12-nine-imports.txt && test -s "$A" && /usr/bin/grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A" && { /usr/bin/grep -qF 'STOP STATE 07-12-PRECONDITION' .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt || { /usr/bin/grep -qF 'D-13' "$A" && /usr/bin/grep -qF 'AMBIGUOUS_BEFORE' "$A" && for p in P02 P03 P04 P05 P06; do /usr/bin/grep -qF "$p" "$A" || exit 1; done; }; }</automated>
  ```
  Look at what `07-12:102` requires:
  `/usr/bin/grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A"`
  WHERE DOES `$A` GET THOSE TOKENS IN TASK 1?
  Look at Task 1 Action (`07-12:78-82`):
  `Preconditions: the ledger's P01 line reads P01 LANDED (re-run) — EQUALITY VERDICT: PASS or P01 LANDED (re-run-other <id>) — NEW-IMPORT VERIFIED: PASS (G-08 — quote it; LANDED without a PASS verdict, a FAIL verdict, or a newer STOP STATE 07-11-… token is a STOP: stage nothing, write STOP STATE 07-12-PRECONDITION: <what the ledger said>);`
  Task 1 action says: quote it in `$A` (`07-12-nine-imports.txt`)!
  If Task 1 stopped on `STOP STATE 07-12-PRECONDITION`:
  It writes `STOP STATE 07-12-PRECONDITION: ...` to `$L` (`07-pilot-ledger.txt`).
  And `$A` does NOT necessarily contain `EQUALITY VERDICT` or `NEW-IMPORT VERIFIED` if it stopped before recording preconditions!
  Look at the logic:
  `/usr/bin/grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A" && { /usr/bin/grep -qF 'STOP STATE 07-12-PRECONDITION' ... || { ... } }`
  If precondition check fails, Task 1 must write `EQUALITY VERDICT` or `NEW-IMPORT VERIFIED` to `$A` AND write `STOP STATE 07-12-PRECONDITION` to `$L`. If it stops because the ledger had `P01 LANDED` with NO verdict line, `$A` has NEITHER token! So `/usr/bin/grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A"` FAILS!
  The stop condition fails its own verify!
- **Refutation Condition**: Prove that when the precondition in `07-12:78` fails because the ledger contains neither `EQUALITY VERDICT: PASS` nor `NEW-IMPORT VERIFIED: PASS` (e.g. `P01 LANDED (re-run)` with no verdict), `artifacts/07-12-nine-imports.txt` is guaranteed to contain `EQUALITY VERDICT` or `NEW-IMPORT VERIFIED`.
- **Suggested Fix**:
  Change `07-12:102` to:
  ```bash
  <automated>cd "$(git rev-parse --show-toplevel)" && A=.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-12-nine-imports.txt && test -s "$A" && { /usr/bin/grep -qF 'STOP STATE 07-12-PRECONDITION' .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt || { /usr/bin/grep -qE 'EQUALITY VERDICT|NEW-IMPORT VERIFIED' "$A" && /usr/bin/grep -qF 'D-13' "$A" && /usr/bin/grep -qF 'AMBIGUOUS_BEFORE' "$A" && for p in P02 P03 P04 P05 P06; do /usr/bin/grep -qF "$p" "$A" || exit 1; done; }; }</automated>
  ```

---

### [R2-DF-02] HIGH: Incomplete branch handling in `07-13` Task 3 `<verify>` lets unrouted imports pass without routing check (FM-1, FM-5)

- **Plan & Task**: `07-13-PLAN.md` Task 3 `<verify>`
- **Literal Quote** (`07-13:195`):
  ```bash
  <automated>cd "$(git rev-parse --show-toplevel)" && A=.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-13-dj-pair.txt && { test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0 || { /usr/bin/grep -qiE 'bpm' "$A" && /usr/bin/grep -qE '^ADDED ORDER' "$A" && { test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported(-asis)?$|^DISPOSITION P[0-9]{2}: imported ' "$A")" -eq 0 || { /usr/bin/grep -qF 'route-dj-album.sh --album-id' "$A" && /usr/bin/grep -qF '/media/Music/DJ/' "$A"; }; }; }; } && test "$(/usr/bin/grep -cE 'Full[R]efresh|zfs [r]ollback' "$A")" -eq 0</automated>
  ```
- **Failure Scenario**:
  Trace the nested logic in `07-13:195`:
  `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported(-asis)?$|^DISPOSITION P[0-9]{2}: imported ' "$A")" -eq 0 || { /usr/bin/grep -qF 'route-dj-album.sh --album-id' "$A" && /usr/bin/grep -qF '/media/Music/DJ/' "$A"; };`
  In Task 2 (`07-13:117`), the allowed dispositions are:
  `DISPOSITION PNN: imported-asis|imported|imported-no-route|hold`
  Case 1: The operator imports with `DISPOSITION P07: imported-asis`.
  Then `grep -cE '^DISPOSITION P[0-9]{2}: imported(-asis)?$'` matches `DISPOSITION P07: imported-asis`.
  The count is 1 ($\ne 0$). The `||` right side executes: it requires `route-dj-album.sh --album-id` and `/media/Music/DJ/`. This is correct.
  Case 2: The operator imports with `DISPOSITION P07: imported`.
  The count is 1 ($\ne 0$). The right side executes. This is correct.
  Case 3: What if the operator answered `DISPOSITION P07: imported-no-route`?
  Look at the outer condition:
  `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported' "$A")" -eq 0`
  Because `^DISPOSITION P[0-9]{2}: imported` matches `DISPOSITION P07: imported-no-route`, the outer test returns false (count is 1).
  The inner block executes:
  `{ /usr/bin/grep -qiE 'bpm' "$A" && /usr/bin/grep -qE '^ADDED ORDER' "$A" && ... }`
  Then the inner test:
  `test "$(/usr/bin/grep -cE '^DISPOSITION P[0-9]{2}: imported(-asis)?$|^DISPOSITION P[0-9]{2}: imported ' "$A")" -eq 0`
  Does `imported-no-route` match `^DISPOSITION P[0-9]{2}: imported(-asis)?$`? No.
  Does `imported-no-route` match `^DISPOSITION P[0-9]{2}: imported `? No (no space).
  So the count is 0!
  Therefore, the inner test returns 0 (true), the `||` right side is SKIPPED, and the test SUCCEEDS without checking for routing or filing `DEF-07-13-NN`.
  BUT look at Task 3 Action (`07-13:181`):
  `For imported-no-route: record the album's artist-tree location as an open finding (DEF-07-13-NN) and issue no Jellyfin POST for it until routed.`
  The `<verify>` block does NOT check for `DEF-07-13-` or for the unrouted location recording on this branch. A completely unrouted album passes verification without any proof that the required finding was filed or that its artist-tree path was captured.
- **Refutation Condition**: Show that `07-13:195` asserts `DEF-07-13-` or the unrouted finding when `DISPOSITION PNN: imported-no-route` is present.
- **Suggested Fix**:
  Add an explicit check for `DEF-07-13-` when `imported-no-route` is present:
  ```bash
  { ! /usr/bin/grep -qE '^DISPOSITION P[0-9]{2}: imported-no-route' "$A" || /usr/bin/grep -qE 'DEF-07-13-[0-9]+' "$A"; }
  ```

---

### [R2-DF-03] MEDIUM: Brittle parenthesized token check in `07-11` Task 3 `<verify>` (FM-1, FM-5)

- **Plan & Task**: `07-11-PLAN.md` Task 3 `<verify>`
- **Literal Quote** (`07-11:317`):
  ```bash
  /usr/bin/grep -qE 'TREE COVERED yes \(' "$A" && /usr/bin/grep -qE 'DB COVERED yes \(' "$A" && /usr/bin/grep -qE 'STATE COVERED yes \(' "$A"
  ```
- **Failure Scenario**:
  In Task 2 (`07-11:180-184`), the format of the verdict lines is specified as:
  `Verdict lines, one per part, each PAIRED (G-02) and written with its two readings, e.g. TREE COVERED yes (pre 32 → post 0): a part is yes ONLY when its Task 1 reading was PRESENT and its post-undo reading is ABSENT on the same key; no when PRESENT → still present; VACUOUS when the Task 1 reading was already absent (never yes). Lines: TREE COVERED yes/no/VACUOUS, DB COVERED yes/no/VACUOUS, STATE COVERED yes/no/VACUOUS.`
  Notice that in Task 3 Action (`07-11:286-288`):
  `(ii) this plan's UNDO WITNESS shows TREE COVERED yes, DB COVERED yes AND STATE COVERED yes — each a PAIRED reading (present before, absent after, on the key actually written) produced by UNDO IMPORT ALONE;`
  In `07-11:317`, the regex strictly looks for `TREE COVERED yes \(` (with an escaped opening parenthesis preceded by a single literal space).
  If the tool or executor outputs `TREE COVERED yes: (pre 32 -> post 0)` (with a colon) or `TREE COVERED yes  (` (two spaces) or `TREE COVERED yes (pre: 32 -> post: 0)`, the check fails. More importantly, in the acceptance criteria (`07-11:324`), it states:
  `FIRED only with three paired yes verdicts from UNDO IMPORT alone, the rerun answer and EQUALITY VERDICT: PASS`
  The strict requirement for `yes \(` in the verify script is an exact string coupling to an example ("e.g. TREE COVERED yes (pre 32 → post 0)") given in prose, rather than matching `yes` followed by the parenthetical readings.
- **Refutation Condition**: Prove that `TREE COVERED yes` is prohibited from having a colon or alternative spacing before `(` in the output.
- **Suggested Fix**:
  Use `TREE COVERED yes[ :] *\(` or `TREE COVERED yes.*\(pre ` in `07-11:317` to tolerate standard punctuation variations while still strictly enforcing the presence of the paired before/after reading.

---

### 4. What Was Checked and Held (No Finding)

1. **Safety Invariant 1 (Fence precedes grant in same remote step)**:
   Checked `07-09-PLAN.md` Task 2 (`07-09:202-234`). The remote script on `atlantis` strictly checks for snapshot absence, takes `tank/media/Music@pre-07-pilot`, takes `fast/appdata/arrs@pre-07-pilot`, lists both back, and verifies sha256 of the snapshot's view of `library.db` and `state.pickle` *before* `docker compose up -d` is run. The step order is immutable and fails closed before any grant. Held sound.

2. **Safety Invariant 2 (`zfs rollback` on `fast/appdata/arrs` forbidden)**:
   Checked all references across all plans (`07-01` through `07-17`). Every plan forbidding rollback on `fast/appdata/arrs` cites the file restore method from `/mnt/fast/appdata/arrs/.zfs/snapshot/pre-07-pilot/beets/config/`. In `07-11:249-267`, restore is performed via literal `cp` with `beets-flask` stopped (`State.Running == false`), restarted, and gated on the 2-inbox watchdog line. Held sound.

3. **Safety Invariant 3 (Staging is copy-not-move, sources exist afterwards)**:
   Checked `07-08` D-22 config changes (`07-08:188-199`), `07-09` post-grant gating (`07-09:247-260`), `07-10` staging (`07-10:108-115`), `07-12` staging (`07-12:89-91`), and `07-17` final evidence assembly (`07-17:105-106`). `import.copy: yes` and `import.move: no` are gated via parsed YAML in `07-09`, staged copies use `cp -R --reflink=always`, and Criterion 8 source manifests are verified file-by-file before and after in `07-07` and `07-17`. Held sound.

4. **Safety Invariant 5 (Jellyfin updated file-scope only, `FullRefresh` forbidden)**:
   Checked Jellyfin API interactions in `07-10:235-245`, `07-12:172-176`, `07-13:176-178`, `07-14:154-157`, and `07-15:83-90`. Every scan issues `POST /Library/Media/Updated` at file scope with `UpdateType: Created` or `Deleted` or `Modified`. In all plans, `<verify>` blocks mechanically assert `test "$(/usr/bin/grep -cE 'Full[R]efresh' "$A")" -eq 0`. Held sound.

5. **Safety Invariant 6 (Music Assistant syncs once, last, behind a gate in 07-15)**:
   Checked `07-10:22`, `07-11`, `07-12:176`, `07-13`, `07-14:157`, and `07-15:18-20, 126-166`. No intermediate plan invokes MA sync. `07-10` and `07-15` read the HA add-on log for 24h background sync activity before any writes to ensure MA does not sync autonomously in the background. The single sync in `07-15` Task 3 is gated by `checkpoint:decision` in Task 2. Held sound.

6. **Safety Invariant 7 (D-17 `zfs destroy` mechanical release conditions)**:
   Checked `07-11:284-303`. The replan completely eliminates the loophole identified in G-01 and G-02. Conditions (i)–(iv) explicitly require: (i) both snapshots listed back in 07-09; (ii) paired `TREE COVERED yes`, `DB COVERED yes`, `STATE COVERED yes` from `UNDO IMPORT` alone; (iii) operator answer was `rerun` (no file restore); and (iv) `EQUALITY VERDICT: PASS` written before D-17 evaluation. On any failure or file restore, `D-17 TRIGGER: NOT FIRED` is written and the snapshot is held for `07-16`. Held sound.

7. **Cross-plan Ledger Integrity (FM-2, FM-3)**:
   Cross-read ledger states between `07-09`, `07-10`, `07-11`, `07-12`, `07-13`, `07-14`, `07-15`, and `07-17`. `07-11` emits distinct tokens (`07-11-T1-HOLD`, `07-11-T2-HOLD`, `07-11-T2-TREE-NOT-COVERED`, `07-11-T3-EQUALITY-FAIL`, `07-11-T3-RESTORE-FAIL`). `07-12:78` specifically checks for `P01 LANDED (re-run) — EQUALITY VERDICT: PASS` and halts to `STOP STATE 07-12-PRECONDITION` if absent. Resume reconciliation in `07-11:99-108` matches the estate against these exact tokens. Held sound.

8. **Grep and Verification Hygiene (CONVENTIONS §8, §9)**:
   Verified that all negative checks for forbidden commands (`zfs rollback`, `zfs destroy`, `FullRefresh`) across `07-01`, `07-09`, `07-10`, `07-11`, `07-12`, `07-13`, `07-14`, and `07-15` are written with character classes (`zfs [r]ollback`, `Full[R]efresh`, `zfs [d]estroy`) so that plan text and ban notices do not self-match. Held sound.

---

### 5. Suggestions

1. **Standardize Task 2 Disposition Formatting Across Waves**:
   Plans `07-10`, `07-11`, `07-12`, `07-13`, `07-14`, and `07-15` all require the executor to write a line starting `DISPOSITION: <token>` or `DISPOSITION PNN: <token>`. While `07-12` and `07-13` use per-album tokens (`DISPOSITION PNN:`), `07-10` uses whole-plan tokens (`DISPOSITION:`). Ensure the executor prompt template makes this syntax explicit so manual transcription does not drop the `PNN` prefix.

2. **Automate D-17 Destroy Invocation Verification**:
   In `07-11:317`, the verify check asserts `test "$(/usr/bin/grep -cE 'zfs [d]estroy' "$A")" -le 1`. If D-17 fires, it issues exactly one destroy. If NOT FIRED, it issues zero. Consider making this explicit by asserting `-eq 0` when `NOT FIRED` is present:
   `{ ! /usr/bin/grep -qE 'D-17 TRIGGER: NOT FIRED' "$A" || test "$(/usr/bin/grep -cE 'zfs [d]estroy' "$A")" -eq 0; }`

---

## Round 2 — operator decisions (2026-09-25)

These two answers settle the round-2 PLAUSIBLE items that were marked **operator**. They bind the
`--reviews` replan.

| # | Question | Operator's answer | What the replan must do |
|---|----------|-------------------|-------------------------|
| P7R2-10 | Is the operator's adjudication at the 07-11 gate the quality gate before 07-12, or is a mechanical check needed? | **Mechanical first.** | Promoted to **CONFIRMED (MED)**. Before 07-12 stages anything, require a computed `QUALITY: PASS` line for P01, separate from `EQUALITY VERDICT`. It has to show that no criterion 3/4/7 finding from 07-10 or the re-run is unresolved: ffprobe/DB mismatch, ownership ≠ `568:568`, UNEXPLAINED drop or sweep finding. 07-12's precondition then requires **both** PASS lines, with any other reading → `STOP STATE 07-12-PRECONDITION`. The operator's adjudication stays, but sits on top of the mechanical gate and doesn't replace it. |
| P7R2-21 | Does an unplanned Music Assistant sync between 07-10 and 07-15 (`MA SYNC SINCE 07-10: FOUND`) block criterion 6? | **No, not a block.** | **Closed, no change.** FOUND stays a recorded finding, as 07-15 T2 already writes it, and doesn't hold the sync gate or criterion 6's closure. Don't add a STOP for it. |
