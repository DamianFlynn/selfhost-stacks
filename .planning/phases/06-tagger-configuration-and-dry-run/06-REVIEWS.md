---
phase: 06-tagger-configuration-and-dry-run
round: 6
scope: plans 06-46 … 06-52 (planned, not yet executed)
reviewers: [pi/gpt-6-astra, pi/gemini-3.8-flash, pi/kimi-k3, pi/grok-4.7, pi/deepseek-v4-pro, copilot/gpt-5.5]
reviewer_families: 5
reviewed_at: 2026-09-24
plans_reviewed:
  - 06-46-PLAN.md
  - 06-47-PLAN.md
  - 06-48-PLAN.md
  - 06-49-PLAN.md
  - 06-50-PLAN.md
  - 06-51-PLAN.md
  - 06-52-PLAN.md
findings_confirmed: 12
findings_refuted: 4
findings_reclassified: 3
status: issues_found
verdict: proceed_with_fixes
---

# Cross-AI Plan Review — Phase 06, gap-closure round 6

Six reviewers across **five model families** (OpenAI, Google, Moonshot, xAI, DeepSeek) reviewed
plans 06-46 … 06-52. Claude was deliberately excluded as the reviewing agent's own family.

**Every HIGH was graded against the live files and the live estate before being recorded here.**
Four findings were refuted, three reclassified. Two of the most valuable findings came from
measuring the estate, which no text reviewer can do.

## Verdict

**Proceed with fixes.** No §1 safety invariant is breached, and no reviewer found a path by which
this round writes to the Music library, redeploys the estate, ticks CONF-04, or issues a forbidden
ZFS verb. The defects are concentrated in *self-enforcement* — truths asserted a shade more broadly
than the mechanism that produces them — plus one detector that is structurally non-detecting and one
pre-flight gate that will stop the round on arrival.

Reviewer verdicts split, and the split is informative: `kimi-k3` and `deepseek-v4-pro`, the two that
explicitly cross-read all seven `files_modified` lists before reporting, both returned **0 HIGH /
YES WITH FIXES**. `gpt-6-astra`, `copilot/gpt-5.5` and `gemini-3.8-flash` returned **NO**. Grading
resolved most of that gap in favour of the careful two: gemini's blocking HIGH is refuted outright.

---

## Graded findings

Ordered by graded severity, not by reviewer confidence.

### CONFIRMED — HIGH

**H1 · `STATE.md` is told to record the outcomes of two plans that have not run.**
*Found by 4 of 6 reviewers (astra, copilot, grok, kimi) — the round's consensus finding.*
06-50 runs at **wave 3**. Its Task 2(c) requires the `STATE.md` round-6 block to state "round 6
executed plans 06-46 … 06-52" and "the two operator actions **and their outcomes**". 06-51 (wave 4)
and 06-52 (wave 5) have not run at that point, are both `autonomous: false`, and both have
legitimate halt/hold branches. **`.planning/STATE.md` appears in no later plan's `files_modified`**,
so nothing repairs it. Task 1 of the same plan correctly writes the register rows as `PENDING` —
the fix was applied to the register and to ROADMAP, and missed the third file.
*Why it matters:* `STATE.md` is what the next session reads as position. It will claim a host sync
and a snapshot decision that may never have happened.
*Fix:* 06-50 (c) writes R6-08/R6-09 as pending with 06-52 named as closing owner; 06-52 Task 3
takes `.planning/STATE.md` into `files_modified` and folds in the real outcomes.

**H2 · The no-redeploy detector passes a transcript containing real redeploys. (DRIVEN)**
*Found by copilot alone. Explicitly cleared as sound by kimi — divergence resolved by measurement.*
06-51's published check is `grep -icE 'docker com[p]ose (up|down|restart|recreate|pull)'`, which
requires the verb **immediately** after `docker compose`. Driven against a control:

```
docker compose -f stacks/selfhosted/traefik/compose.yaml up -d
docker-compose up -d
docker compose --profile media pull
```
→ the published detector returns **0**. Against bare `docker compose up` it returns 1.
*Why it matters:* this is precisely the `DEF-06-45-04` shape the round exists to correct — a true
number from an instrument structurally incapable of detecting what it counts — reappearing in the
plan that guards a 103-container host.
*Fix:* allow intervening options and catch the hyphenated form, or whitelist `docker ps` as the
only permitted docker invocation and assert the verb set.

**H3 · 06-51's pre-flight STOP condition fires on arrival. (MEASURED ON THE LIVE HOST)**
*Found by no reviewer — not derivable from the plan text.*
06-51 Task 1(a) expects `git status --porcelain` on LXC 100 to be **empty**, and its STOP list
makes "a `git status --porcelain` with any output" a halt. Measured on `172.16.1.159` now:

```
?? stacks/selfhosted/monitoring/prometheus.yaml.bak
?? stacks/selfhosted/wrappers/monitoring.app.yaml.disabled
```

Two **untracked** files. Neither can block a fast-forward, and I confirmed the fast-forward is
otherwise safe: host HEAD `ee82fb2` **is** an ancestor of local HEAD (20 commits behind), and
neither untracked path appears in the incoming diff.
*Why it matters:* as written, the round's live-estate plan halts at its first gate for a reason
unrelated to its purpose, and the sync it exists to perform does not happen. The gate is
fail-closed, which is correct — but it does not distinguish untracked from tracked-modified.
*Fix:* make the cleanliness test `git status --porcelain --untracked-files=no` (or treat `??` lines
as a reportable non-blocker), or clear the two files first. Note also that only
`check-music-consumers.sh` and `quick-health-check.sh` currently differ between host and repo.

### CONFIRMED — MEDIUM

**M1 · `git diff --exit-code <path>` is blind to a staged edit. (DRIVEN)**
*astra + kimi, two families.* Driven in a scratch repo: with the edit staged,
`git diff --exit-code protected.txt` exits **0** while `git diff --exit-code HEAD -- protected.txt`
exits **1**. This idiom is the round's single most-repeated protection — it carries the
CONF-04-stays-unticked guarantee, 06-48's dated-artifact immutability guarantee, and the
no-script-changed guarantee in 06-50/51/52. These plans stage and commit during execution, so the
blind state is the likely one. *Fix: add `HEAD --` to each of these recipes.*

**M2 · 06-52's acceptance criterion sends the reader to the block the plan says gives the wrong answer.**
*copilot + gemini + grok + kimi — 4 of 6.* The action (Task 1, Q2) correctly says to answer from
Phase 7's **Success Criteria item 1**, and `read_first` warns that searching only the entry-criteria
block "would produce a 'not planned' answer by omission". The acceptance criterion then requires the
answer to be "read from the ROADMAP's Phase 7 **entry criteria**". Commit `d7df994` fixed the
citation in the action and left it in the acceptance text. I verified Success Criteria item 1 does
commit the fence; the entry-criteria block does not. *Bias is toward `hold`, which is safe — but the
recorded fact would be false.*

**M3 · The container fingerprint captures `status` and then does not compare it.**
*astra + deepseek.* Task 1(g) captures a "name+image+**status** triple"; Task 2 step 5 compares
"the sorted name+image list … and the container count". Status is the one field that moves on a
restart. *Fix: compare the full triple.*

**M4 · `52/52` is written at wave 3 into a column labelled "Plans Complete".**
*astra + grok.* 06-50 explicitly considered and defended this ("the count is true the moment the
seven plans exist"). But the table's header is `Plans Complete`, and the Phase 4 precedent row reads
`16/16 | In Progress` with the note "All 16 plans executed" — so the column's established meaning is
*executed*, not *authored*. Under that meaning `52/52` at wave 3 is the false record 06-50 says it
is avoiding. **This is a contested design decision, not an oversight** — recorded so it is decided
rather than re-litigated.

**M5 · `halt` / `hold` / `defer` have no stated disposition word.**
*grok alone — read the singletons.* 06-52 Task 3(a) requires each of R6-08/R6-09 to carry one of the
closed four-word vocabulary (`FIXED` / `FIXED (undriven)` / `ACCEPTED` / `CARRIED`) and says "do not
invent a fifth word"; leaving `PENDING` fails the plan's own verify. Both plans define halt/hold as
*successful* outcomes. **grok's claimed deadlock is refuted** — `CARRIED` fits both cleanly — but the
plan never states the mapping while forbidding invention. *Fix: one sentence mapping halt/hold/defer
→ `CARRIED`.*

**M6 · 06-49 is about to cite `DECLARED_INTERP_EXPECTED` as an example of the redder-only rule.**
*astra, reframed.* astra called the override a §1.6 breach; the script's own header **already states
and accepts** the behaviour: "It can only ever move a green to a red **or a red to a green BY
DECLARATION** — it resolves nothing". So the invariant breach is **refuted** as a new defect. What
survives is sharper: 06-49 writes this variable into `CONVENTIONS.md` as the canonical example of
"the `${VAR:-default}` override contract that may only ever make a check redder", and by the
script's own words it is a counter-example. *Fix: cite a different example, or state the exception.*

### CONFIRMED — LOW

**L1 · A bare `WR-02` pinned into ROADMAP re-creates the §4 namespace trap.** *(kimi)* ROADMAP
already carries 6 `WR-02` occurrences with at least two referents (`R4-02 (WR-02)` and round 1's
`closes WR-01/WR-02/WR-06/…`). 06-50's criterion requires the literal `WR-02` without mandating the
established paired form `R6-02 (WR-02)`.

**L2 · The `Complete` criterion is case-sensitive and cannot fail.** *(grok)* Measured: the Phase 6
status row is one 33,323-character line containing **0** `Complete` but **10** case-insensitive
matches (4 `COMPLETE`, 6 `complete`). The criterion passes vacuously today — so grok's worry that it
forces a narrative wipe is **refuted** — but it cannot catch a status word written in caps.

**L3 · The `**Plans**: 45 plans in 23 waves` header is left stale.** *(deepseek)* Confirmed unowned:
no round-6 plan names it. After round 6 it should read 52 plans / 28 waves, leaving ROADMAP carrying
two disagreeing counts.

**L4 · Other unenforced-condition items worth folding in while nearby:** 06-47's consistency audit
names no owner for a `deferred-items.md` divergence and states its three-record truth
unconditionally though it may edit only one file *(deepseek)*; 06-49's "mirror" is enforced as a
≥8-name floor rather than a correspondence check *(deepseek)*; the register's Counts reconciliation
is never extended to R6-08/09 once filled *(deepseek)*; the register's "are recorded as PENDING"
prose goes stale and sits outside the `^\|` anchor that re-checks the rows *(kimi)*; 06-47's abort
branch ships a `-SUMMARY.md` *(kimi, deepseek)*.

---

## Refuted — recorded because a wrong blocker costs a revision cycle too

| Claim | Reviewer | Grading |
|---|---|---|
| **"06-50 Task 1's `grep -coE 'R6-0[89]' … -ge 9` is a regex typo that guarantees a hard fail"** — gemini's #1 blocking recommendation | gemini-3.8-flash | **REFUTED.** The actual line 219 reads **`R6-0[1-9]`**. gemini conflated it with line 231's `R6-0[89]`, a *different* check correctly scoped to the two PENDING rows. Driven: `R6-0[1-9]` returns 9 on a nine-ID control. Acting on this would have "fixed" correct code. |
| "`docker com[p]ose` / `zfs [r]ollback` bracketing is broken" | gemini-3.8-flash | **REFUTED — by gemini itself**, mid-answer. It worked through the ERE semantics in visible text and concluded "this is the exact deliberate self-referential bracketing idiom … Marking REFUTED." Correct. |
| "06-51 prescribes GNU `sha256sum` on a macOS workstation that lacks it" | kimi-k3 | **REFUTED.** `/sbin/sha256sum` is present on this workstation; kimi's own stated refutation condition is met. |
| "06-52 does not mechanically enforce 'only `zfs list`, or one exact destroy'" (HIGH) | copilot/gpt-5.5 | **RECLASSIFIED to LOW.** The prose criteria are far stronger than credited: one fully-qualified snapshot name, no `-r`/`-R`/`-f`/glob, plus a *computed* before/after name-set difference and an assertion that `tank/downloads@pre-phase5` survives. Only the `<automated>` block is narrow (it tests `zfs [r]ollback` alone). kimi independently examined the same fencing and passed it. |

---

## Consensus

### Agreed strengths (named by 3+ reviewers)
- The wave-separated hand-offs are **internally consistent**. Both reviewers who explicitly
  cross-read all seven `files_modified` lists (kimi, deepseek) reported **no fence walk-through**:
  `deferred-items.md` (06-48 → 06-51 → 06-52), the register (06-50 creates, 06-52 closes) and
  `ROADMAP.md` (06-50 writes, 06-52 appends) are strictly sequential, and wave 1's three parallel
  plans share no file.
- Every `PENDING` / `ROUND CLOSE` placeholder names a concrete owner and a `DEF-` fallback.
- The bracketed-verb discipline with **driven controls** is applied consistently in both transcript
  plans — a recipe must be shown to detect before a 0 is accepted as evidence.
- 06-52's destroy fencing and its refusal to offer `zfs rollback` on any branch.
- The round is, in deepseek's words, "remarkably sound for a sixth adversarial pass."

### Agreed concerns
1. **H1 STATE.md** — 4 of 6.
2. **M2 the Phase 7 citation in 06-52's acceptance text** — 4 of 6.
3. **Premature completion records generally** (H1 + M4) — the round's dominant theme: the fix for
   "don't publish outcomes before they happen" was applied to two of the three records.

### Divergent views — worth more than the agreements
- **kimi explicitly cleared 06-51's no-redeploy guarantee** as satisfying §1.4, including the
  compose-verb grep. copilot found it defective and **driving it proved copilot right** (H2).
  Convergence located the design risk; measurement decided it.
- **Verdict split** was 3 NO / 3 YES-WITH-FIXES, and the two most methodical reviewers were both in
  the YES camp while the reviewer returning the loudest NO had its blocking finding refuted.
- grok and kimi disagree on severity for the same register mechanics — grok reads the disposition
  vocabulary as a deadlock, kimi reads the hand-off as sound. Graded: neither, a missing sentence.

### What no reviewer could see
H3 (the host's working tree is dirty with two untracked files) and the ancestry/incoming-diff
measurements came from the estate, not the text. Per this project's own recorded lesson: **run the
reviewers on the text, then grade against the box.**

---

## Recommended order of fixes

1. **H1** — give `STATE.md` the two-step treatment the register and ROADMAP already have.
2. **H2** — repair the compose detector, and drive it against a control containing options.
3. **H3** — make 06-51's cleanliness gate distinguish untracked from tracked-modified.
4. **M1** — add `HEAD --` to every `git diff --exit-code` guarantee in the round.
5. **M2, M3, M5, M6** — each is a one-to-two-sentence correction.
6. **M4** — an explicit decision, not an edit: decide what the `Plans Complete` column means.

---

## Reviewer outputs, verbatim


### gpt-6-astra (via pi / github-copilot) — 4 HIGH, 4 MEDIUM — verdict NO

### [HIGH] The additive-only override rule is still mechanically false
- **Plan(s):** 06-46, 06-49
- **Location:** 06-46, “Scope fence” and Task 2(a); 06-49, Task 1, convention 4
- **Mode:** B (unenforced condition)
- **Finding:** 06-46 prohibits changing predicates and retains `DECLARED_INTERP_EXPECTED="${DECLARED_INTERP_EXPECTED:-12}"`, followed by comparison against the overridden value. Printing “do not export … to silence this” does not enforce the additive-only contract. I drove the existing comparison offline with `INTERP_COUNT=13`: without the override it increments `FAILURES`; with `DECLARED_INTERP_EXPECTED=13` it does not. No separate guard on this override exists in `scripts/check-music-freeze.sh`. 06-49 then names this variable as a canonical example of additive-only overrides.
- **Why it matters:** An operator can suppress the inventory-change failure without reviewing the newly invisible mount. This directly violates §1 invariant 6. The prohibition is also emitted only on the failure branch—the successful bypass suppresses its own warning.
- **REFUTATION CONDITION:** `06-46-PLAN.md` requires an unconditional failure when this override departs from the built-in policy, and requires a driven case showing that setting the override equal to a mismatched measured count cannot remove that failure.

### [HIGH] Wave 3 publishes completion of plans that have not executed
- **Plan(s):** 06-50, 06-51, 06-52
- **Location:** 06-50, Task 1, “Do NOT move ROADMAP’s `52/52` plan-count bump”; Task 2(b)(3) and Task 2(c)
- **Mode:** A (scope fence) / B (unenforced condition)
- **Finding:** 06-50 correctly leaves R6-08 and R6-09 pending in the register, but simultaneously requires ROADMAP’s count to become `52/52` and STATE to say “round 6 executed plans 06-46 … 06-52,” including both operator outcomes. The count’s justification is factually wrong: `.planning/ROADMAP.md` labels that column **Plans Complete**, not plans authored. `.planning/STATE.md` currently explicitly counts plans **executed**. At wave 3, plans 06-51 and 06-52 have not run. Moreover, 06-52’s closeout owns the register and ROADMAP, not STATE, so its actual outcomes cannot repair STATE within the declared ownership.
- **Why it matters:** The primary progress records claim execution before the gates occur, including if execution stops before either gate. Leaving the phase status `In Progress` does not make the completion count or execution narrative true. The previously added register closeout does not resolve this separate false record.
- **REFUTATION CONDITION:** `06-50-PLAN.md` requires the completion numerator and STATE narrative to describe only executed plans, leaves both future outcomes pending, and explicitly assigns subsequent STATE outcome updates to a later plan.

### [HIGH] The no-redeploy fingerprint cannot detect a same-image recreation or restart
- **Plan(s):** 06-51
- **Location:** Task 1(g), “running container fingerprint”; Task 2, step 5, “Prove nothing was redeployed”
- **Mode:** B (unenforced condition)
- **Finding:** The binding comparison is only the sorted container **name+image list and count**. A container recreated under the same name from the same image passes all three comparisons. Restarting an existing container also passes. Although the pre-flight records status, the post-flight assertion explicitly omits it and records neither container identity nor an exact start timestamp.
- **Why it matters:** The transcript can publish a successful “no-redeploy” verdict after an actual recreation or restart. It therefore cannot establish the plan’s central safety claim about the live Docker host. A statement that the executor issued no compose command proves a narrower fact, not unchanged runtime instances.
- **REFUTATION CONDITION:** `06-51-PLAN.md` requires before/after assertions over container identity and exact start state, with a same-name, same-image recreation or restart explicitly required to fail the comparison.

### [HIGH] The halt branch is required to claim the health-check run is unblocked
- **Plan(s):** 06-51, 06-52
- **Location:** 06-51, Task 2 acceptance criterion for `DEF-06-39-05`; 06-52, Task 3(a), R6-08 outcome
- **Mode:** B (unenforced condition)
- **Finding:** Both plans unconditionally require the record to say `DEF-06-39-05` is “unblocked but not closed.” But 06-51’s legitimate `halt` branch leaves the host untouched and `DEF-06-45-05` item 2 open. The stale deployed scripts—the stated reason the live run is blocked—remain stale. 06-52 repeats the unconditional “unblocked” assertion even while explicitly supporting an R6-08 outcome of `halt`.
- **Why it matters:** A valid safety halt produces a false readiness statement in both the deferred register and the round’s primary record. A later executor can rely on that statement to run the very stale instrument this plan was intended to replace.
- **REFUTATION CONDITION:** `06-52-PLAN.md` Task 3 requires “unblocked” only after a successful six-file sync proof, and requires the halt outcome to retain the blocked state consistently with `DEF-06-51-01`.

### [MEDIUM] Healthy empty pre-flight results are defined as stop conditions
- **Plan(s):** 06-51
- **Location:** Task 1, “Treat any non-zero or empty answer as COULD NOT LOOK”
- **Mode:** B (unenforced condition)
- **Finding:** The blanket empty-output rule conflicts with the explicitly expected empty output of `git status --porcelain` and the required empty stash list. The workstation’s `git log origin/main..HEAD` can also legitimately be empty when everything is already pushed. There is no command-specific exception or framing that distinguishes those successful empty results from failed collection.
- **Why it matters:** Following the stated rule literally rejects a clean, unstashed host before offering `proceed`. Ignoring the rule requires the executor to invent exceptions at runtime. This is a false-red defect, not an argument to weaken fail-closed handling.
- **REFUTATION CONDITION:** `06-51-PLAN.md` Task 1 explicitly accepts empty output with a captured zero exit status for status, stash and commit-list queries, while retaining nonempty-result requirements for branch, hash and inventory queries.

### [MEDIUM] The approved commit is not bound to either git write
- **Plan(s):** 06-51
- **Location:** Task 1(h)–(j) and STOP conditions; Task 2, steps 1–4
- **Mode:** B (unenforced condition)
- **Finding:** The gate measures workstation `HEAD`, hashes the workstation’s files and lists `origin/main..HEAD`, but the write pushes **local `main`**, not necessarily that HEAD. There is no STOP condition requiring the workstation to be on `main` with reviewed files matching the committed tree. The subsequent host pull consumes the then-current remote `main`, without asserting it equals the commit approved at the gate. Only the host’s pre-flight values are rechecked before pulling.
- **Why it matters:** On another workstation branch, the displayed commit list can differ from what is pushed. A remote advance between push and pull can also add unapproved commits. The six-script comparison may detect some discrepancies only after the host has been changed; changes outside those scripts can pass it entirely.
- **REFUTATION CONDITION:** `06-51-PLAN.md` binds the gate to one full commit hash, asserts that local `main` and the six committed script contents match it, and refuses the host update unless the fetched target is that same approved hash.

### [MEDIUM] The corrected recipe retains a moving counted set
- **Plan(s):** 06-48
- **Location:** Task 1, Section 2, “with `-cF` replaced by `-cE` and nothing else changed”
- **Mode:** B (unenforced condition)
- **Finding:** The source recipe in `artifacts/06-43-conf04-verdict.txt` SECTION O actually loops over `artifacts/06-4*-*.txt`. Replacing only the grep option preserves that glob. It already includes the verdict artifact in addition to the four named source files, and round 6 adds matching `06-46`, `06-47` and `06-48` artifacts. Listing four filenames beside the recipe does not restrict what the shell executes.
- **Why it matters:** The replacement is published as a fixed four-file instrument while it measures a growing set, including its own new transcript. Because 06-46 and 06-47 execute in the same wave, the measured membership can also depend on execution timing. This contradicts the promised reproducible scope of the correction.
- **REFUTATION CONDITION:** `06-48-PLAN.md` requires the published executable loop to enumerate exactly the four source filenames explicitly, with the verdict artifact and scripts measured in a separately identified set.

### [MEDIUM] The dated-artifact preservation check does not compare against the base
- **Plan(s):** 06-48
- **Location:** Task 1 acceptance criterion, `git diff --exit-code …/06-43-conf04-verdict.txt`; final verification
- **Mode:** B (unenforced condition)
- **Finding:** The plan treats plain `git diff --exit-code <path>` as proof that the dated artifact is untouched. That command compares the working tree with the index, not with the pre-plan commit. A staged modification passes; a modification already committed during execution also passes. Unlike the explicit base-content comparison specified for `DEF-06-45-04`, no base-anchored comparison is required for the dated artifact itself.
- **Why it matters:** An accidental edit to the historical evidence can survive the designated mechanical preservation check. This is precisely the file whose immutability is the central safety property of 06-48; a clean working-tree diff is not evidence of historical byte identity.
- **REFUTATION CONDITION:** `06-48-PLAN.md` requires a byte comparison of the final artifact against its contents at a full base commit captured before the plan starts, independent of staging or intermediate commits.

## Verdict
- Findings: 4 HIGH, 4 MEDIUM, 0 LOW
- Would you let this round execute as written? NO
- The single most important thing to fix first: Make `DECLARED_INTERP_EXPECTED` mechanically incapable of suppressing the inventory-change failure; the current plan preserves that bypass while documenting it as additive-only.

---

### gpt-5.5 (GitHub Copilot standalone) — 3 HIGH, 2 MEDIUM, 1 LOW — verdict NO

### [HIGH] 06-50 writes future operator outcomes into `STATE.md`
- **Plan(s):** 06-50, 06-51, 06-52
- **Location:** 06-50 Task 2, `.planning/STATE.md` action: “the two operator actions and their outcomes”
- **Mode:** A (scope fence)
- **Finding:** 06-50 runs in wave 3 before the two haltable operator plans in waves 4 and 5, but its `STATE.md` task still says the round-6 block will state “the two operator actions and their outcomes.” That contradicts 06-50 Task 1’s corrected register design, where R6-08 and R6-09 are explicitly `PENDING` until 06-52 fills `ROUND CLOSE`.
- **Why it matters:** `STATE.md` can publish outcomes for `git pull --ff-only` and snapshot release before either operator gate has happened. If 06-51 or 06-52 halts, the primary session state becomes a false record that a later phase will rely on.
- **REFUTATION CONDITION:** Read 06-50 Task 2’s `.planning/STATE.md` action and find that it instructs the executor to record R6-08/R6-09 as `PENDING`, owned by 06-51/06-52 and `ROUND CLOSE`, rather than recording their “outcomes.”

### [HIGH] The no-redeploy detector misses normal `docker compose` forms
- **Plan(s):** 06-51
- **Location:** 06-51 Task 2 verify/acceptance: `/usr/bin/grep -icE 'docker com[p]ose (up|down|restart|recreate|pull)'`
- **Mode:** B (unenforced condition)
- **Finding:** The detector only catches a compose verb immediately after `docker compose`. It misses ordinary redeploy commands such as `docker compose -f stacks/selfhosted/traefik/compose.yaml up -d`, `docker compose --profile x pull`, and `docker-compose up`. The plan’s prose says the only allowed Docker verb is `ps`, but the mechanical check does not enforce that.
- **Why it matters:** This is a direct breach risk for the round invariant “No redeploy.” A transcript containing a real compose redeploy with options could still pass the published detector and be recorded as “no compose verb issued.”
- **REFUTATION CONDITION:** Read 06-51 Task 2 and find a whitelist that extracts every Docker command from the transcript and asserts only `docker ps` / `docker ps -a` occur, or a detector that catches `docker compose`/`docker-compose` with intervening options before `up|down|restart|recreate|pull`.

### [HIGH] 06-52 does not mechanically enforce “only `zfs list`, or one exact destroy”
- **Plan(s):** 06-52
- **Location:** 06-52 Task 2 acceptance criteria: rollback/destroy grep checks
- **Mode:** B (unenforced condition)
- **Finding:** The safety invariant says every branch is `zfs list` only, except an explicit `release` branch may issue exactly one `zfs destroy` against exactly one named snapshot. Task 2 mechanically checks for no rollback and counts destroy, but it does not reject other ZFS write verbs such as `zfs hold`, `zfs release`, `zfs snapshot`, `zfs set`, or `zfs rename`.
- **Why it matters:** A non-destroy ZFS mutation could appear in the transcript and still pass the plan’s automated checks, violating the “everything else is `zfs list`” invariant.
- **REFUTATION CONDITION:** Read 06-52 Task 2 acceptance criteria and find a command whitelist that extracts all unbracketed `zfs` invocations from the transcript and proves the verb set is exactly `list` plus, only on `release`, one literal `destroy tank/media/Music@pre-06-41-conf04-reprobe` with no flags/globs.

### [MEDIUM] 06-51 measures local cleanliness but does not make it a STOP condition
- **Plan(s):** 06-51
- **Location:** 06-51 Task 1 action items (h)–(i), STOP conditions list, and Task 2 step 1 `git push origin main`
- **Mode:** B (unenforced condition)
- **Finding:** The plan captures workstation `git status --porcelain` and branch, but the STOP conditions only cover the host tree/branch/ancestor/stash and could-not-look. A dirty workstation or non-`main` current branch can still proceed. `git push origin main` pushes the local `main` ref, not necessarily the current dirty working tree or current branch HEAD that the pre-flight sha table was computed from.
- **Why it matters:** The host can be fast-forwarded to stale `origin/main`, while the plan compares against uncommitted or wrong-branch local files. That can fail only after writing the host, or worse, record a misleading sync picture.
- **REFUTATION CONDITION:** Read 06-51 Task 1 STOP conditions and find explicit stops for local dirty worktree, local branch not `main`, and mismatch between the commit being pushed (`refs/heads/main`) and the commit/file hashes used for the comparison.

### [MEDIUM] 06-52’s acceptance criterion reintroduces the wrong Phase 7 fence location
- **Plan(s):** 06-52
- **Location:** 06-52 Task 1 acceptance criterion: “read from the ROADMAP’s Phase 7 entry criteria”
- **Mode:** B (unenforced condition)
- **Finding:** The plan correctly warns in `read_first` and the action that Phase 7’s pilot snapshot fence is committed under Phase 7 **Success Criteria item 1**, not under `Entry criteria inherited from Phase 6`. But the acceptance criterion then requires Question 2 to state the answer as “read from the ROADMAP’s Phase 7 entry criteria.”
- **Why it matters:** The executor can satisfy the acceptance text by looking in the exact block the plan says is insufficient, producing a false “pilot fence not planned” dependency answer and biasing the snapshot decision record.
- **REFUTATION CONDITION:** Read 06-52 Task 1 acceptance criteria and find that Question 2 must be answered from Phase 7 `**Success Criteria** item 1`, with the inherited-entry-criteria block consulted separately only for E4/E5/E6 context.

### [LOW] 06-49 asserts a register location before the register exists
- **Plan(s):** 06-49, 06-50
- **Location:** 06-49 Task 1 action, section “Review ID namespaces are unique per round…”; 06-49 `depends_on`
- **Mode:** A (scope fence)
- **Finding:** 06-49 is required to write `CONVENTIONS.md` before 06-50 creates `06-DISPOSITIONS-GAP4.md`, but it instructs the conventions file to state that round 6’s mapping table “lives in `06-DISPOSITIONS-GAP4.md`.” The same task also requires every claim in `CONVENTIONS.md` to be traceable to something read in `read_first`; the register cannot be read yet.
- **Why it matters:** The conventions file becomes a source-of-truth document that asserts a future artifact as if it already exists. If 06-50 changes shape or fails, `CONVENTIONS.md` is immediately stale.
- **REFUTATION CONDITION:** Read 06-49 Task 1 and find that the round-specific `06-DISPOSITIONS-GAP4.md` sentence is removed, marked explicitly as a forward pointer pending 06-50, or moved into 06-50 after the register exists.

## Verdict
- Findings: 3 HIGH, 2 MEDIUM, 1 LOW
- Would you let this round execute as written? **NO**
- The single most important thing to fix first: 06-50 must stop writing 06-51/06-52 outcomes into `STATE.md` before those haltable operator plans run; then harden 06-51’s Docker-command whitelist before any live-host sync.


---

### gemini-3.8-flash (via pi) — 2 HIGH, 4 MEDIUM, 1 LOW — verdict NO (headline HIGH refuted)

### [MEDIUM] Verification automated check tests for hardcoded token that plan prose does not require in code
- **Plan(s):** 06-46
- **Location:** `<verify>` and `<acceptance_criteria>` in Task 2
- **Mode:** B (unenforced condition)
- **Finding:** Task 2 `<verify>` runs:
  `test "$(/usr/bin/grep -vE '^[[:space:]]*#' scripts/check-music-freeze.sh | /usr/bin/grep -c 'remediation')" -eq 2`
  and the acceptance criteria state:
  `Exactly two non-comment lines in scripts/check-music-freeze.sh emit a remediation sentence — one per fail arm. Measured comment-stripped, never raw: /usr/bin/grep -vE '^[[:space:]]*#' scripts/check-music-freeze.sh | /usr/bin/grep -c 'remediation' returns 2.`
  However, in Task 2 `<action>`, the prompt specifies what the printed text must contain for arm (a) (constant name, values, hand-read requirement, same commit, env override prohibition) and arm (b) (TAGGER_DEF_EXPECTED, TAGGER_DEF_<NAME>_CLASS, why count alone fails). Nowhere in `<action>` is the word `"remediation"` specified as mandatory literal text in the emitted `echo` strings (the action specifies adding short `# R6-03` comment lines, but comment lines are excluded by `-vE '^[[:space:]]*#'`). If the executor writes `echo "         fix: update DECLARED_INTERP_EXPECTED..."` without including the literal substring `"remediation"`, the automated verification step will fail despite satisfying all functional requirements.
- **Why it matters:** The automated verify script in plan 06-46 will fail during automated execution unless the executor happens to include the exact word `remediation` inside the emitted echo string.
- **REFUTATION CONDITION:** Read `scripts/check-music-freeze.sh` and find that the word `remediation` is already used on non-comment lines in those blocks, or read Task 2 `<action>` and find an instruction explicitly requiring the string `remediation:` or `remediation` in the `echo` commands.

---

### [MEDIUM] Acceptance criteria for `docker com[p]ose` in 06-51 Task 2 uses broken bracketing regex
- **Plan(s):** 06-51
- **Location:** Task 2 `<acceptance_criteria>`
- **Mode:** B (unenforced condition)
- **Finding:** Task 2 acceptance criteria state:
  `Assert /usr/bin/grep -icE 'docker com[p]ose (up|down|restart|recreate|pull)' returns 0 against the transcript. Drive that recipe against a control string containing the real phrase first and observe 1, so a non-detecting recipe cannot pass.`
  The regex needle used is `'docker com[p]ose (up|down|restart|recreate|pull)'`.
  In regular expression syntax (POSIX ERE / `grep -E`), `[p]` is a character class matching the single character `p`. Therefore, `docker com[p]ose` matches the literal string `"docker compose"` in extended regex! It does NOT match `"docker com[p]ose"`.
  If the transcript writes narrative sentences using the bracketed form `"docker com[p]ose up"`, `grep -E 'docker com[p]ose ...'` will match them, returning ≥ 1 instead of 0, failing the acceptance check.
  Conversely, in the automated verification command:
  `<automated>... test "$(/usr/bin/grep -icE 'docker com[p]ose (up|down|restart|recreate|pull)' "$A")" -eq 0 ...</automated>`
  it searches for `"docker compose (up|down...)"`. If narrative lines write `docker com[p]ose up`, `grep -E` matches it! To search for the bracketed literal in ERE, the brackets themselves must be escaped (`\[p\]`), or the character class must be bracketed like `com\[p\]ose` or `com[[]p[]]ose`.
- **Why it matters:** When the executor follows the instruction to write narrative mentions as `docker com[p]ose up`, `grep -E 'docker com[p]ose ...'` treats `[p]` as matching `p` and matches the text! The automated verify check will count the narrative lines and fail with `exit 1` because count is not 0.
- **REFUTATION CONDITION:** Test `echo "docker com[p]ose up" | grep -icE 'docker com[p]ose (up|down)'`. It returns 1 if it matches `"docker compose up"` and 0 if it requires literal brackets. Running `/usr/bin/printf 'docker com[p]ose up\n' | /usr/bin/grep -icE 'docker com[p]ose (up|down)'` returns 0 on literal `com[p]ose` only if `[p]` does not match `[` and `]`. But `printf 'docker compose up\n' | grep -icE 'docker com[p]ose (up|down)'` returns 1! Thus, if literal `docker compose up` is absent and only `docker com[p]ose up` is present, it returns 0, but the control test (`echo "docker compose up" | grep -icE 'docker com[p]ose (up|down)'`) returns 1. However, if the transcript mentions `docker compose` unbracketed (e.g. in command output or error messages), it returns non-zero. More critically, `zfs [r]ollback` in 06-52 has the exact same trap: in ERE, `[r]` matches `r`, so it matches `zfs rollback`!
- *Correction on analysis*: Wait, `[r]` in ERE matches the character `r`. So `zfs [r]ollback` matches `zfs rollback`! It does NOT match `zfs [r]ollback`. So if the file contains `zfs [r]ollback`, `grep -E 'zfs [r]ollback'` returns 0, while against `zfs rollback` it returns 1. But wait: if someone writes `docker com[p]ose`, `grep -E 'docker com[p]ose'` sees `[p]` matching `p`, which matches `docker compose`! This was the intended mitigation technique for avoiding self-matching!
  Let's re-verify: Does `zfs [r]ollback` in the file match `grep -E 'zfs [r]ollback'`?
  In the file: `zfs [r]ollback`.
  Regex: `zfs [r]ollback` -> matches `zfs ` followed by `r` followed by `ollback` -> `zfs rollback`.
  Does string `zfs [r]ollback` match `zfs rollback`? No, because the string has `[` and `]`, which are not `r`!
  So `grep -E 'zfs [r]ollback'` matches the *unbracketed* string `zfs rollback` and DOES NOT match the bracketed string `zfs [r]ollback`!
  Therefore this is the exact deliberate self-referential bracketing idiom used throughout the repo (`DEF-06-39-06`). So this is NOT a bug, it is the intentional design! Marking REFUTED.

---

### [HIGH] Cross-plan modification of ROADMAP.md between 06-50 and 06-52 breaks 06-50's verify if run out of order or if git diff check fails
- **Plan(s):** 06-50, 06-52
- **Location:** 06-50 Plan frontmatter and Task 2; 06-52 Plan frontmatter and Task 3
- **Mode:** A (scope fence)
- **Finding:**
  In 06-50:
  `06-50-PLAN.md` modifies `.planning/ROADMAP.md` in Task 2.
  `06-50` Task 2 `<verify>` asserts:
  `test "$(/usr/bin/grep -cE '^\| 6\. Tagger Configuration and Dry Run \| 52/52 \| In Progress' .planning/ROADMAP.md)" -eq 1`
  In 06-52:
  `06-52-PLAN.md` modifies `.planning/ROADMAP.md` in Task 3.
  Task 3 `<action>` states:
  `Append one or two sentences to the Phase 6 disposition paragraph's round-6 block naming R6-08's and R6-09's outcomes and pointing at DEF-06-51-01 / DEF-06-52-01 for the detail. This is a narrative append only.`
  However, in 06-50 Task 2:
  `ROADMAP.md`'s Phase 6 status row is currently line 1615 in `.planning/ROADMAP.md`.
  Notice what 06-50 Task 2 does:
  `1. The seven round-6 plan lines were already added at plan time (06-46 … 06-52...). Verify, do not re-append.`
  `2. Amend the Phase 6 disposition paragraph with a round-6 block...`
  `3. Update the Phase 6 status row: the plan count moves from 45/45 to 52/52 and the narrative cell gains a round-6 clause.`
  Notice that in 06-50 Task 2, it adds a round-6 clause to the status row narrative cell and to the Phase 6 disposition paragraph.
  Then in 06-52 Task 3, it modifies the Phase 6 disposition paragraph AGAIN to append sentences about R6-08 and R6-09.
  While wave ordering (`06-50` in Wave 3, `06-52` in Wave 5) sequences them, 06-52's acceptance criteria state:
  `git diff on ROADMAP.md and on the register shows zero deletions of pre-existing content lines other than the PENDING row cells and the ROUND CLOSE placeholder being replaced. Read the diff BODY; a --stat-only check does not satisfy this criterion.`
  Because the Phase 6 disposition paragraph is a markdown block starting with `**Phase 6 disposition:**`, appending to it without breaking markdown formatting or deleting lines requires precise editing. More importantly, 06-52 Task 3 action instructs:
  `Do not touch the Phase 6 status row. Its 52/52 plan count and its In Progress status word are 06-50's and are already correct.`
  This is clean sequentially, but see next finding for where the real defect lies in 06-50.

---

### [HIGH] `06-50` Task 1 acceptance criteria requires non-existent R6-08 and R6-09 table rows in a file it creates from scratch
- **Plan(s):** 06-50
- **Location:** Task 1 `<verify>` and `<acceptance_criteria>`
- **Mode:** B (unenforced condition)
- **Finding:**
  In 06-50 Task 1 `<action>`:
  `Write 06-DISPOSITIONS-GAP4.md, matching 06-DISPOSITIONS-GAP3.md's structure section for section.`
  It explains that `R6-08` and `R6-09` have not yet executed, and instructs:
  `Write both rows' disposition cell as the literal word PENDING, and beside each name (i) its owning plan, (ii) the DEF- entry that will carry its outcome (DEF-06-51-01, DEF-06-52-01) and (iii) the ROUND CLOSE section below...`
  Then in `<acceptance_criteria>`:
  `The R6-08 and R6-09 rows read PENDING and each names its owning plan, its DEF- entry and the ROUND CLOSE section. Measure with the token written bracketed, so the criterion is not an occurrence of what it counts: /usr/bin/grep -cE '^\|.*R6-0[89].*PEN[D]ING' returns 2. The ^\| anchor is load-bearing: it restricts the count to table rows, so prose elsewhere in the register that discusses the word cannot inflate it.`
  Now look at 06-50 Task 1 `<verify>`:
  `<automated>cd "$(git rev-parse --show-toplevel)" && R=.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP4.md && test -s "$R" && test "$(/usr/bin/grep -cF 'THE ID MAPPING TABLE' "$R")" -ge 1 && test "$(/usr/bin/grep -coE 'R6-0[89]' "$R")" -ge 9 && test "$(/usr/bin/grep -cE 'Full[R]efresh' "$R")" -eq 0</automated>`
  Look at `test "$(/usr/bin/grep -coE 'R6-0[89]' "$R")" -ge 9`:
  `R6-0[89]` matches ONLY `R6-08` and `R6-09`!
  It matches `R6-08` and `R6-09`, NOT `R6-01` through `R6-07`.
  If there are 9 rows in total (`R6-01` through `R6-09`), `R6-0[89]` only matches `R6-08` and `R6-09`. There will only be 2 (or a few) occurrences of `R6-08` and `R6-09`.
  Therefore, `/usr/bin/grep -coE 'R6-0[89]' "$R"` will count occurrences of `R6-08` and `R6-09`. In a table with rows `R6-01` to `R6-09`, `grep -coE 'R6-0[89]'` will return 2 (or maybe 4 with prose), which is **LESS THAN 9**!
  The regex intended to match `R6-0[1-9]` (all nine IDs), but the plan author wrote `R6-0[89]`!
  As a result, `test ... -ge 9` will evaluate to `test 2 -ge 9`, which returns **FALSE (exit code 1)**!
  The automated verification command in `06-50-PLAN.md` Task 1 is guaranteed to hard-fail during automated execution!
- **Why it matters:** When executing `06-50-PLAN.md`, Task 1's automated `<verify>` command will fail every single time, blocking the plan and round execution.
- **REFUTATION CONDITION:** Run `/usr/bin/grep -coE 'R6-0[89]'` on a file containing `R6-01`, `R6-02`, `R6-03`, `R6-04`, `R6-05`, `R6-06`, `R6-07`, `R6-08`, `R6-09`. It counts only `R6-08` and `R6-09` (count = 2), not 9.

---

### [HIGH] 06-52 Task 3 verification regex will match 0 lines on control row and fail the acceptance criterion
- **Plan(s):** 06-52
- **Location:** Task 3 `<acceptance_criteria>`
- **Mode:** B (unenforced condition)
- **Finding:**
  In 06-52 Task 3 `<acceptance_criteria>`:
  `Neither the R6-08 nor the R6-09 mapping-table row still reads PENDING. Measure this with the token written bracketed so the criterion is not an occurrence of what it counts: /usr/bin/grep -cE '^\|.*R6-0[89].*PEN[D]ING' returns 0. The ^\| anchor restricts the count to table rows so prose cannot inflate it. Drive the recipe first: against a control row containing the real word it must return 1...`
  Look closely at the recipe:
  `/usr/bin/grep -cE '^\|.*R6-0[89].*PEN[D]ING'`
  Notice the bracketed pattern: `PEN[D]ING`.
  As evaluated in POSIX ERE (`grep -E`), `[D]` is a character class matching the single character `D`.
  So `PEN[D]ING` matches the string `"PENDING"`.
  Now, how does it match `R6-08` OR `R6-09`? `R6-0[89]` matches `R6-08` or `R6-09`.
  The acceptance criterion requires:
  `Drive the recipe first: against a control row containing the real word it must return 1, and only then is a 0 against the register evidence that the rows were filled rather than evidence that the recipe matches nothing.`
  If the control row contains both rows or if a control has `| R6-08 | ... | PENDING |` and `| R6-09 | ... | PENDING |`, it returns 2, not 1! But more importantly:
  Look at Task 3 `<verify>` command:
  `<automated>cd "$(git rev-parse --show-toplevel)" && R=.planning/phases/06-tagger-configuration-and-dry-run/06-DISPOSITIONS-GAP4.md && test "$(/usr/bin/grep -cF 'ROUND CLOSE' "$R")" -ge 1 && test "$(/usr/bin/grep -cF 'DEF-06-51-01' "$R")" -ge 1 && test "$(/usr/bin/grep -cF 'DEF-06-52-01' "$R")" -ge 1 && test "$(/usr/bin/grep -cE '^\|.*R6-0[89].*PEN[D]ING' "$R")" -eq 0 && test "$(/usr/bin/grep -cE '^\| 6\. Tagger Configuration and Dry Run \| 52/52 \| In Progress' .planning/ROADMAP.md)" -eq 1 && git diff --exit-code .planning/REQUIREMENTS.md && git diff --exit-code scripts/</automated>`
  In `06-DISPOSITIONS-GAP4.md`, where are `R6-08` and `R6-09`?
  In Task 1 of 06-50:
  `THE ID MAPPING TABLE comes before anything a reader might follow a citation from. Round 6's in-band namespace is R6-*. The rows, five for the review plus four for the round's other items so one table covers the round:`
  `...`
  `(no review ID) → R6-08 — the host git pull --ff-only sync (plan 06-51).`
  `(no review ID) → R6-09 — the snapshot-release decision (plan 06-52).`
  And:
  `Write both rows' disposition cell as the literal word PENDING`
  Now, when 06-52 Task 3 updates the table:
  `(a) Close the register. Replace 06-DISPOSITIONS-GAP4.md's ROUND CLOSE placeholder with the two outcomes, and change the R6-08 and R6-09 mapping-table rows from PENDING to their real dispositions, drawn from the register's own closed four-word vocabulary (FIXED / FIXED (undriven) / ACCEPTED / CARRIED)`
  What happens to the ID mapping table vs the register table?
  In `06-DISPOSITIONS-GAP3.md`, there are TWO tables:
  1. `THE ID MAPPING TABLE` (which maps Review ID -> In-band ID -> Finding name, with NO disposition column!)
  2. The register table under `## The Register` (which has columns: `Finding | Review ID | Severity | Disposition | Fix kind | Files modified | Commit | Driven artifact`).
  In 06-50 Task 1, `R6-08` and `R6-09` are defined as `(no review ID)`.
  If the ID mapping table has no disposition column, where was `PENDING` placed?
  06-50 Task 1 says: "Write both rows' disposition cell as the literal word PENDING".
  So `R6-08` and `R6-09` are in the Register table.
  In 06-52 Task 3, replacing `PENDING` with `FIXED` or `ACCEPTED` leaves 0 lines matching `^\|.*R6-0[89].*PEN[D]ING`.
  So `test "$(/usr/bin/grep -cE '^\|.*R6-0[89].*PEN[D]ING' "$R")" -eq 0` will pass.
  However, look at the acceptance criteria instruction in 06-52:
  `Drive the recipe first: against a control row containing the real word it must return 1`
  If someone feeds a control with two rows (one for 08 and one for 09), it returns 2, failing "must return 1". The instruction should specify "a single control row" or "test each row". This is a minor ambiguity, not a fatal failure like 06-50 Task 1.
- **Why it matters:** Ambiguity in test execution instructions.
- **REFUTATION CONDITION:** The instruction says "a control row" (singular). If fed a single control row `| R6-08 | PENDING |`, it returns 1.

---

### [MEDIUM] Plan 06-47 Task 1 verification checks line count that can fail if head commentary expands
- **Plan(s):** 06-47
- **Location:** Task 1 `<verify>` and `<acceptance_criteria>`
- **Mode:** B (unenforced condition)
- **Finding:**
  In 06-47 Task 1 `<verify>`:
  `test "$(/usr/bin/head -n 45 stacks/selfhosted/arrs/beets.md | /usr/bin/grep -cF 'Phase 6 closed 2026-09-21')" -ge 1`
  and acceptance criteria:
  `The pointer appears within the first 45 lines of the file and before the existing > **Amended 2026-09-11 (plan 04-05).** blockquote. Assert by comparing line numbers from /usr/bin/grep -n.`
  Let's check the current line numbers in `stacks/selfhosted/arrs/beets.md`:
  The existing line 11 is:
  `State as of 2026-09-04, after the Phase 1 safety harness and the Phase 3 tagger spike (last two sections).`
  Line 14 is:
  `> **Amended 2026-09-11 (plan 04-05).** The wrtag and soulbeet **definitions are deleted...`
  Task 1 `<action>` requires inserting a blockquote with 5 detailed points:
  1. Running log explanation
  2. Location of authoritative current state (reproducing exact heading text)
  3. Cited by heading text, never line number, with reason
  4. Phase 6 disposition in full
  5. Go-forward rule
  This blockquote will be approximately 20-30 lines long.
  Inserting a 25-line blockquote between line 11 and line 14 means the inserted block will occupy roughly lines 13 to 40.
  Line 45 will then fall inside or immediately around line 45.
  If the blockquote is 35 lines long, lines 12 + 35 = 47.
  If the heading text `'Phase 6 closed 2026-09-21'` is cited on line 46 of the file, `head -n 45` will truncate BEFORE that line!
  Then `/usr/bin/head -n 45 stacks/selfhosted/arrs/beets.md | /usr/bin/grep -cF 'Phase 6 closed 2026-09-21'` returns 0, and the automated verify will fail!
  Why pin `head -n 45` when the file is 2,470 lines and the goal is simply to be within the top section before `## One beets, one library`?
- **Why it matters:** An executor writing a complete, thorough 5-point blockquote as instructed by Task 1 `<action>` can easily exceed 32 lines of blockquote, pushing the citation of `Phase 6 closed 2026-09-21` beyond line 45, causing `<verify>` to fail on an arbitrary line boundary.
- **REFUTATION CONDITION:** Measure the exact line count of the proposed blockquote and show that even with full elaboration of all 5 points it cannot exceed 30 lines.

---

### [MEDIUM] Plan 06-51 Task 1 stop-condition logic lacks handling for divergent origin/main vs local main
- **Plan(s):** 06-51
- **Location:** Task 1 `<action>` and Task 2 `<action>`
- **Mode:** B (unenforced condition)
- **Finding:**
  In 06-51 Task 1:
  Item (i) measures `git log --oneline origin/main..HEAD` on the workstation.
  In Task 1 STOP conditions:
  `the host's HEAD is not an ancestor of the workstation's HEAD (verify with git merge-base --is-ancestor <host-HEAD> <local-HEAD>)`
  In Task 2, step 1:
  `Push from the workstation: git push origin main. Never --force, never --force-with-lease, never a rebase. Capture the raw output and the resulting origin/main hash.`
  In Task 2, step 3:
  `timeout "$REMOTE_TIMEOUT" git -C /mnt/fast/stacks pull --ff-only origin main`
  Notice: On the host, it pulls from `origin main` (or `origin/main`).
  What if `origin/main` on GitHub/remote has commits that are NOT in the local workstation's branch (e.g. if someone else pushed, or an automated workflow pushed)?
  Step 1 (`git push origin main`) will fail with `[rejected - non-fast-forward]`!
  Task 1 pre-flight checks whether `<host-HEAD>` is an ancestor of `<local-HEAD>`, but it does NOT check whether `origin/main` is an ancestor of `<local-HEAD>` (i.e. whether `git fetch origin` was run to check if `origin` diverged from the workstation).
  If `git push origin main` fails in Task 2 step 1 because remote is ahead or divergent, Task 2 has no recovery or stop handling for push failure before attempting host pull.
- **Why it matters:** If `origin/main` has diverged, `git push origin main` will fail immediately in Task 2, leaving the plan in an unhandled error state without a pre-flight stop gate.
- **REFUTATION CONDITION:** Prove that `git fetch` was already executed or that the pre-flight explicitly checks `git merge-base --is-ancestor origin/main HEAD`. In 06-51 Task 1, `git fetch` is not listed in `<read_first>` or `<action>`.

---

### [LOW] Plan 06-50 Task 2 plan list verification checks `06-52-PLAN.md` but not `06-46-PLAN.md`
- **Plan(s):** 06-50
- **Location:** Task 2 `<verify>`
- **Mode:** B (unenforced condition)
- **Finding:**
  In 06-50 Task 2 `<verify>`:
  `test "$(/usr/bin/grep -cF '06-52-PLAN.md' .planning/ROADMAP.md)" -ge 1`
  It checks that `06-52-PLAN.md` exists in ROADMAP.md, but doesn't check `06-46-PLAN.md` in `<verify>` (though the acceptance criteria mention checking that all seven lines exist).
  Since `06-52-PLAN.md` is the last plan in the list, checking it ensures the tail of the block exists. However, earlier plans already added all 7 plan lines (as noted in Task 2 `<action>`: "The seven round-6 plan lines were already added at plan time... Verify, do not re-append").
  Because lines `06-46` through `06-52` are already present in `ROADMAP.md` before 06-50 executes (as verified in the current repository state), `test "$(/usr/bin/grep -cF '06-52-PLAN.md' .planning/ROADMAP.md)" -ge 1` will pass even if Task 2 does nothing.
- **Why it matters:** The automated verify test for Task 2 tests a condition that was already satisfied before Task 2 began, providing no verification of the changes Task 2 actually makes to ROADMAP.md (such as the status row update or the disposition paragraph update).
- **REFUTATION CONDITION:** Check git history of ROADMAP.md to see if `06-52-PLAN.md` is already in `ROADMAP.md`. (Running `git grep "06-52-PLAN.md" .planning/ROADMAP.md` confirms it is already at line 1132).

---

### [MEDIUM] Plan 06-52 Task 1 Question 2 citation instructs reading nonexistent heading text
- **Plan(s):** 06-52
- **Location:** Task 1 `<read_first>` and `<action>`
- **Mode:** B (unenforced condition)
- **Finding:**
  In 06-52 Task 1 `<read_first>`:
  `item 1 is where Phase 7's pilot snapshot fence is actually committed ("Twelve bucket-A albums are imported inside a snapshot fence — ZFS snapshot of the Music dataset and a copy of library.db taken together — with rollback exercised at least once"). This is DEF-06-45-01's second release clause and the crux of this decision. Verified present at planning time by direct read.`
  However, in Task 1 `<action>`, under `DEPENDENCY REASONING`, question 2:
  `Is DEF-06-45-01's second release clause satisfied? Is Phase 7's pilot fence planned? Answer from Phase 7's Success Criteria item 1... Then state separately what the Entry criteria inherited from Phase 6 block does and does not say about it...`
  Now look at Acceptance Criterion 5 for Task 1:
  `Question 2's answer states, as a measured fact read from the ROADMAP's Phase 7 entry criteria, whether Phase 7's pilot fence is planned — and therefore whether DEF-06-45-01's second release clause is met or not met.`
  Notice the contradiction inside Plan 06-52:
  `<read_first>` and `<action>` emphasize that the pilot fence is NOT in the `Phase 7 entry criteria` (it is in `Phase 7 Success Criteria item 1`), and warns:
  `Searching only the entry-criteria block and finding no pilot fence would produce a "not planned" answer by omission... Read both.`
  Yet the acceptance criterion explicitly states:
  `Question 2's answer states, as a measured fact read from the ROADMAP's Phase 7 entry criteria, whether Phase 7's pilot fence is planned...`
  If a checker verifies whether the fact was "read from the ROADMAP's Phase 7 entry criteria", it directly contradicts `<read_first>`, which established that reading from Phase 7 entry criteria gives the WRONG answer!
- **Why it matters:** The acceptance criterion misnames the section ("Phase 7 entry criteria" instead of "Phase 7 success criteria"), which can mislead an agent checking acceptance criteria to assert the pilot fence was found in entry criteria, re-introducing the exact confusion plan 06-52 warned about.
- **REFUTATION CONDITION:** Read 06-52 acceptance criterion 5: if it says "read from the ROADMAP's Phase 7 success criteria", this finding is refuted. It explicitly says "read from the ROADMAP's Phase 7 entry criteria".

---

## Verdict
- Findings: 2 HIGH, 4 MEDIUM, 1 LOW
- Would you let this round execute as written? NO
- The single most important thing to fix first:
  Fix the automated verification command in `06-50-PLAN.md` Task 1 (`test "$(/usr/bin/grep -coE 'R6-0[89]' "$R")" -ge 9`), which has a regex typo (`R6-0[89]` instead of `R6-0[1-9]`) that causes `test 2 -ge 9` and will guaranteed-fail the automated verification of the plan.

---

### grok-4.7 (via pi / xAI) — 2 HIGH, 6 MEDIUM — verdict YES WITH FIXES

### [HIGH] STATE.md is told that plans 06-51 and 06-52 already happened, and nothing later is allowed to correct it
- **Plan(s):** 06-50, 06-52
- **Location:** 06-50 Task 2 (c) ("the block states: round 6 executed plans 06-46 … 06-52" and "the two operator actions and their outcomes"); 06-50 Task 1 ("R6-08 and R6-09 HAVE NOT EXECUTED when this register is written"); 06-52 `files_modified`
- **Mode:** A (scope fence)
- **Finding:** Task 1 of 06-50 correctly records R6-08 and R6-09 as `PENDING` because those plans have not run. Task 2 (c) of the same plan then requires `.planning/STATE.md` to say round 6 executed 06-46 through 06-52 and to state the two operator actions' outcomes. Those outcomes do not exist at wave 3. 06-52 Task 3 is the designated closer for the register and the ROADMAP disposition paragraph, but `STATE.md` is not in 06-52's `files_modified`, and no other plan edits it after 06-50. The Current Position sentence that already reads "ROUND 6 PLANNED, not yet executed" is also not named as an edit target, while the acceptance criterion requires the `Plan:` line to read `52 of 52`.
- **Why it matters:** `STATE.md` is what the next session treats as position. Followed as written, it will claim a host sync and a snapshot decision that have not occurred, and a later halt or `hold` will not be written back. That is a false primary record, not an incomplete one.
- **REFUTATION CONDITION:** 06-50 Task 2 (c) tells the executor to write those two outcomes as not-yet-known / `PENDING`, or 06-52 `files_modified` includes `.planning/STATE.md` and Task 3 updates that block from `DEF-06-51-01` and `DEF-06-52-01`.

### [HIGH] The beets.md pointer names a dated closure section whose criterion-4 cell is already false
- **Plan(s):** 06-47
- **Location:** Task 1 action item 2 (authoritative state is the heading `Phase 6 closed 2026-09-21 — four criteria TRUE, one OPEN on a named half, all five RE-MEASURED at close`); Task 1 `<verify>` (`head -n 45` plus `-cF` of that heading); Task 2 ("If any record disagrees, correct it" inside `beets.md` only)
- **Mode:** B (unenforced condition)
- **Finding:** That heading's criterion-4 cell still says the option applies "next time it runs, and nothing has re-probed these files." `### Still open at Phase 6 close`'s first bullet still says it "discharges on Phase 7's first write" and does not name `negative-carry-e6`. The 2026-09-24 measurement is a different heading, `### The sequel to that finding: mechanism (b) was DRIVEN on 2026-09-24, and it does not work`. Task 1's automated verify passes as soon as the heading string appears in the first 45 lines. It does not check that the cited section states the five facts the pointer is required to state. Task 2 then requires the records to agree, and the only file it may edit is `beets.md`, without requiring a retraction that leaves the 2026-09-21 cell standing. The scope fence says superseded claims stay as retractions.
- **Why it matters:** A reader who follows the new "read this first" pointer lands on a section that says the re-probe never happened. Satisfying the five-fact audit by rewriting that cell makes a 2026-09-21 measurement claim a 2026-09-24 fact. Either result is a false operational record in the file this plan calls authoritative.
- **REFUTATION CONDITION:** In `stacks/selfhosted/arrs/beets.md`, the criterion-4 cell under `## Phase 6 closed 2026-09-21 — four criteria TRUE, one OPEN on a named half, all five RE-MEASURED at close` and the first bullet of `### Still open at Phase 6 close` already name `negative-carry-e6` and do not say the files have not been re-probed.

### [MEDIUM] 06-52's acceptance criterion sends clause two back to the block the action says must not be used
- **Plan(s):** 06-52
- **Location:** Task 1 `<action>` question 2 ("Answer from Phase 7's `**Success Criteria**` item 1" and "Do not reach 'not planned' by having searched only one heading"); Task 1 acceptance criteria ("as a measured fact read from the ROADMAP's Phase 7 entry criteria"); `hold` option pros ("Correct whenever Phase 7's own pilot fence is not yet planned")
- **Mode:** B (unenforced condition)
- **Finding:** The action was revised so the pilot fence is read from `### Phase 7: Pilot — 12 Albums End to End` / `**Success Criteria**` item 1, which does commit "Twelve bucket-A albums are imported inside a snapshot fence". The acceptance criterion still requires the answer to be read from the entry-criteria block. That block (E1–E6 as read) does not contain the pilot-fence commitment. The `hold` pros already describe "not yet planned" as the condition that makes hold correct. An executor who satisfies the acceptance criterion reports clause two of `DEF-06-45-01` unmet.
- **Why it matters:** That clause is what makes `release` eligible. A false "not planned" becomes the evidence in `artifacts/06-52-snapshot-decision.txt` and `DEF-06-52-01`. The bias is toward `hold`, which is safe, but the record of whether Phase 7's fence is planned will be wrong, and the gate the operator sees will not match the ROADMAP.
- **REFUTATION CONDITION:** 06-52 Task 1's acceptance criterion for question 2 names `**Success Criteria**` item 1 under `### Phase 7: Pilot — 12 Albums End to End`, not the entry-criteria block, as the required source.

### [MEDIUM] The tagger-arm remediation is told both to not bump the pin and to move it in the same commit
- **Plan(s):** 06-46
- **Location:** Task 2 (b) items 1 and 2; acceptance criterion "contains a prohibition on bumping the count alone"
- **Mode:** other
- **Finding:** Item 1 requires the emitted sentence to say the remedy is not to bump `TAGGER_DEF_EXPECTED`. Item 2 requires the same sentence to say `TAGGER_DEF_EXPECTED` is moved in the same commit as the new `TAGGER_DEF_<NAME>` and `TAGGER_DEF_<NAME>_CLASS` constants. The acceptance criterion is the coherent rule (do not bump the count alone). The action text the executor copies into the failure output is not.
- **Why it matters:** This line is what a contributor reads when the census goes red. Followed literally, they either add a third definition and leave the pin at 2 (permanent red) or bump the pin and ignore the "not to bump" sentence. The check stays loud either way, but the self-describing fix this plan exists to add is self-contradictory.
- **REFUTATION CONDITION:** 06-46 Task 2 (b) item 1 already says "not to bump the count alone", and item 2 does not also require `TAGGER_DEF_EXPECTED` to be moved.

### [MEDIUM] The prescribed harness cannot drive the interpolated-path red arm, because the copied block overwrites the stubs
- **Plan(s):** 06-46
- **Location:** Task 2 "Then drive both arms" (stub `INTERP_ROWS`, `INTERP_COUNT`, then drive mismatched counts); the live block at `DECLARED_INTERP_EXPECTED="${DECLARED_INTERP_EXPECTED:-12}"` through the following `if`
- **Mode:** B (unenforced condition)
- **Finding:** The block 06-46 tells the executor to copy assigns `INTERP_ROWS` and `INTERP_COUNT` from a live `grep` over `$STACKS` before the branch. Stubbing those names above the copy does nothing. A red arm is reachable only by editing the extracted text, pointing `$STACKS` at a fixture the plan does not mention, or setting the env override — which the same task tells the maintainer not to treat as the remedy. The acceptance criterion still demands captured interp-red output with both stub values interpolated, and the artifact is allowed to disclaim that it does not prove the live block.
- **Why it matters:** The must-have that both fail arms were driven is satisfied by a harness that is no longer the shipped text, or by narrated output. That is the vacuous-instrument shape this phase keeps removing, reproduced in the plan that claims to drive the arms.
- **REFUTATION CONDITION:** The `DECLARED_INTERP_EXPECTED` block in `scripts/check-music-freeze.sh` does not assign `INTERP_ROWS` or `INTERP_COUNT` inside the text Task 2 says to copy, so a preceding stub survives into the `if`.

### [MEDIUM] 06-51's identity proof hashes the working tree, and a dirty workstation is not a stop
- **Plan(s):** 06-51
- **Location:** Task 1 items (h) and (j); STOP conditions (host porcelain, host branch, ancestry, stash, could-not-look — workstation porcelain is captured and not a stop); Task 2 steps 1 and 4 ("compare each against the workstation value")
- **Mode:** B (unenforced condition)
- **Finding:** `git push origin main` publishes commits, not the working tree. The six-file sha256 taken in Task 1 is of the working tree. A dirty workstation is presented and `proceed` is still offered. After a fast-forward, the host matches `HEAD`. Comparing it to a dirty working-tree hash yields `DIFFERS` even when the pull did exactly what was asked. Nothing requires the post-pull comparison to be against `git show HEAD:scripts/<file>`.
- **Why it matters:** The task then fails a correct sync, or the executor "fixes" a `DIFFERS` by copying working-tree files onto LXC 100 outside the fast-forward. The must-have is byte identity with the committed copies, and the prescribed comparison is not that.
- **REFUTATION CONDITION:** 06-51's STOP list includes a non-empty workstation `git status --porcelain`, and Task 2 step 4 compares the host hashes to `git show HEAD:` of the six scripts rather than to the Task 1 working-tree sums.

### [MEDIUM] "Complete must not appear in that row" cannot be true without rewriting the status cell 06-52 is forbidden to gut
- **Plan(s):** 06-50, 06-52
- **Location:** 06-50 Task 2 acceptance ("The word `Complete` does not appear in that row"); T-06R6-22 ("the word `Complete` is forbidden in it"); the live Phase 6 status row beginning `| 6. Tagger Configuration and Dry Run | 45/45 | In Progress|`
- **Mode:** B (unenforced condition)
- **Finding:** That status row is one 33,323-character line. It already contains `COMPLETE`, `complete`, and `mark-complete` (ten matches), inside round-2 through round-5 narrative that 06-50 is supposed to leave in place. The automated verify only pins `52/52 | In Progress`. The prose acceptance criterion, and T-06R6-22, forbid `Complete` in the row. 06-52 Task 3 then requires zero deletions of pre-existing ROADMAP lines other than the outcome append, and requires that same row to remain `52/52 | In Progress`.
- **Why it matters:** A mechanical pass of 06-50's acceptance criterion means editing that cell to strip historical "COMPLETE" wording. That is the narrative-wipe this round's own threat model forbids, and it races 06-52's byte-preservation check. A case-sensitive reading of `Complete` happens to miss `COMPLETE`, so the criterion does not even check the word that is there.
- **REFUTATION CONDITION:** The Phase 6 status row in `.planning/ROADMAP.md` is not a single line containing `COMPLETE` / `complete`, or 06-50's acceptance criterion restricts the ban to the status-word cell and not the narrative cell.

### [MEDIUM] Halt, hold, and defer have no legal disposition word, and a fifth word is forbidden
- **Plan(s):** 06-52, 06-50
- **Location:** 06-52 Task 3 (a) (replace `PENDING` with `FIXED` / `FIXED (undriven)` / `ACCEPTED` / `CARRIED`; "do not invent a fifth word"); 06-50 Task 1 ("`PENDING` is not a disposition word and may appear only on the R6-08 / R6-09 rows")
- **Mode:** B (unenforced condition)
- **Finding:** R6-08 can end at `halt` with `DEF-06-45-05` item 2 still open. R6-09 can end at `hold` or `defer` with `DEF-06-45-01` still open. Both are defined as successful plan outcomes. Task 3 requires exactly one of the four closed words on each mapping-table row and forbids any other word. It never maps halt/hold/defer onto that set. Filing either as `FIXED` makes the register say the live-estate item was fixed. Leaving `PENDING` fails 06-52's own verify (`^\|.*R6-0[89].*PEN[D]ING` must be 0).
- **Why it matters:** The round's primary register, which 06-52 exists to close, cannot record the two outcomes the plans treat as first-class without either a false `FIXED` or a failed verify.
- **REFUTATION CONDITION:** 06-52 Task 3 contains an explicit mapping (for example halt → `CARRIED`, hold/defer → `ACCEPTED` or `CARRIED`) that stays inside the four-word set and does not call an unfixed item `FIXED`.

## Verdict
- Findings: 2 HIGH, 6 MEDIUM, 0 LOW
- Would you let this round execute as written? YES WITH FIXES
- The single most important thing to fix first: 06-50 Task 2 (c) must not write 06-51/06-52 outcomes into `STATE.md`, and 06-52 must own that block the same way it owns `ROUND CLOSE` — otherwise the next session inherits a finished round that has not happened.

---

### kimi-k3 (via pi / ollama-cloud) — 0 HIGH, 1 MEDIUM, 6 LOW — verdict YES WITH FIXES

# Round 6 Cross-AI Review — plans 06-46 … 06-52

Reviewed all seven plans against §1 invariants, cross-read all seven `files_modified` lists and scope fences against each other (MODE A), and traced each `must_haves.truths` entry to the task and check that produces it (MODE B). The wave-separated hand-offs that *are* designed — deferred-items.md (06-48 → 06-51 → 06-52, append-only with heading-count invariants), the register (06-50 creates the ROUND CLOSE placeholder, 06-52 fills it), and ROADMAP.md (06-50 writes the block, 06-52 appends the outcome sentences) — are internally consistent and were checked first. The findings below are what survives that reading.

---

### [MEDIUM] 06-50's STATE.md block is instructed to record operator-action *outcomes* at wave 3 — two waves before they exist — and no plan in the round owns the close-out for STATE.md
- **Plan(s):** 06-50 (with 06-52 implicated by omission)
- **Location:** 06-50 task 2, action item **(c)** — "The block states: round 6 executed plans 06-46 … 06-52; … **the two operator actions and their outcomes**; and … that re-verification has NOT been performed by this round" — and 06-52's `files_modified` / task 3 `<files>`, which are the register, ROADMAP.md, the artifact and deferred-items.md. **`.planning/STATE.md` appears nowhere in 06-52.**
- **Mode:** B (a condition the prose requires that nothing can truthfully produce at the wave it runs, and no later task enforces or repairs it)
- **Finding:** This is the unfixed half of the §5-caught "folding operator outcomes into the round record" item, one file over — not a restatement. The fix correctly gave the *register* PENDING rows plus a ROUND CLOSE placeholder, and gave *ROADMAP* a closing sentence in 06-52 task 3. But 06-50 writes **four** files, and the third of them — STATE.md, the file a context-reset reader sees first — still carries the pre-fix instruction: its round-6 block must state "the two operator actions and their outcomes." At wave 3, 06-51's gate has not even been *presented*. A literal execution fabricates outcomes for two plans that have not run and can end at `halt`; a sensible execution writes "pending" — which then never gets closed, because 06-52 task 3's reasoning paragraph ("a reader consulting only the register or the ROADMAP narrative") enumerates exactly the two files it fixes and omits STATE.md. 06-52's acceptance criteria re-check the register rows and the ROADMAP status row but never re-open STATE.md.
- **Why it matters:** Either STATE.md's "Current Position" records outcomes that were invented before the events happened — a false record of exactly the class every round this phase has been hunting — or it permanently reads "outcomes pending" long after R6-08/R6-09 have landed, which is the "finding recorded where the next phase does not read" failure 06-50's own objective names. The minimal fix: 06-50 (c) should write the block with R6-08/R6-09 as *pending, with 06-52 named as the closing owner*, and 06-52 task 3 should gain STATE.md in `files_modified` with an instruction and acceptance criterion to fold both outcomes in, mirroring the register treatment.
- **REFUTATION CONDITION:** Read 06-52's `files_modified` frontmatter and task 3 `<files>`/`<action>`. If either names `.planning/STATE.md` with an instruction to close the R6-08/R6-09 sentence there, this finding is wrong. In the text as provided it does not. Also refuted if 06-50 task 2 (c) instructs writing "pending with named owners" rather than "their outcomes" — the quoted text says "their outcomes."

---

### [LOW] Every "file untouched" proof in the round is `git diff --exit-code`, which diffs worktree against the *index* — a staged edit passes all of them
- **Plan(s):** 06-47, 06-48, 06-50, 06-51, 06-52 (also 06-46's `git diff --exit-code scripts/check-beets-config.sh`)
- **Location:** e.g. 06-47 task 2 `<verify>` (`git diff --exit-code .planning/REQUIREMENTS.md`), 06-48 task 2 `<verify>` (×4), 06-50 task 2 `<verify>`, 06-51 task 2 `<verify>`, 06-52 task 2 and task 3 acceptance criteria.
- **Mode:** B
- **Finding:** `git diff --exit-code <path>` compares the working tree to the index. An edit to REQUIREMENTS.md, ROADMAP.md, a dated artifact, or a script that has been *staged* — and these plans all stage and commit their own artifacts during execution — returns 0, so the "byte-unchanged" guarantee the round's §1.2 and §1.5 defenses rest on is blind to exactly the modification state most likely to occur mid-execution. The tight form is `git diff --exit-code HEAD -- <path>` (index plus worktree vs. commit) or `git status --porcelain -- <path>`.
- **Why it matters:** The CONF-04 unticked guarantee, the dated-artifact guarantee (06-48), and the no-script-changed guarantee (06-50/51/52) are each single-instrumented by this pattern. The failure requires an executor error *and* staging, so likelihood is low — but the cost of the stronger form is one word per recipe.
- **REFUTATION CONDITION:** Find any acceptance criterion in these plans using `git diff --exit-code HEAD --` or a `git status --porcelain` content check on the protected paths. In the text as provided, all use the index-relative form. (SPECULATIVE in degree, not in mechanism: exposure depends on the executor's staging habits, which the plans do not pin.)

---

### [LOW] 06-50's acceptance criterion pins a bare `"WR-02"` into ROADMAP's round-6 block, permitting the exact ID collision the R6 namespace was minted to prevent
- **Plan(s):** 06-50
- **Location:** task 2 acceptance — "The Phase 6 disposition paragraph gains a round-6 block containing the literal strings `round 6`, `WR-02`, `ACCEPTED`…"
- **Mode:** other — a fresh instance of §4's namespace trap
- **Finding:** ROADMAP.md already contains "WR-02" with two different referents: the `- [x] 06-19-PLAN.md … closes WR-01/WR-02/WR-06…` line (round 1's WR-02) and the round-4 amendment's `closes R4-02 (WR-02)` (the gap-3 review's WR-02). A round-6 block that says "WR-02 is ACCEPTED" without the `R6-02`-pairing satisfies the stated criterion and makes every ROADMAP grep for WR-02 three-way non-discriminating — in the file future phases actually read. The established idiom (round 4's own `R4-01 (WR-01)` form) would fix it and *also* satisfies the literal-substring criterion; the defect is that the criterion does not require it, so a compliant execution can ship the ambiguous form.
- **Why it matters:** The round's own justification for R6-* — "a fresh namespace, and the table says which R6-* means which WR-*/IN-*" — is undermined at the single highest-traffic citation site.
- **REFUTATION CONDITION:** A sentence in 06-50 task 2's (b)2 action requiring the paired form `R6-02 (WR-02)` in the ROADMAP block. The action text says "that WR-02 is ACCEPTED with its reasoning named" — no pairing mandate.

---

### [LOW] 06-47's "record it and stop" path names no artifact; `<output>` unconditionally promises a `06-47-SUMMARY.md` — the §4 filename-means-complete trap on the abort branch
- **Plan(s):** 06-47
- **Location:** task 2 action ("If the disagreement is in `REQUIREMENTS.md`, do **not** edit it at all — record it and stop") vs. `<output>` ("Create `.planning/phases/…/06-47-SUMMARY.md` when done.")
- **Mode:** other — §4 trap (a `*-SUMMARY.md` marks a plan complete on filename alone; halted plans must be `-PARTIAL.md`)
- **Finding:** 06-51's halt path is explicitly declared "a legitimate, complete outcome," so its -SUMMARY.md is safe; 06-47's stop-on-REQUIREMENTS-divergence is an *abort* — an unexpected, unowned disagreement in the requirement record — and the plan says nothing about what the summary file should be named on that branch. The default reading of `<output>` ships `06-47-SUMMARY.md`, which downstream tooling and reviewers read as complete regardless of what its `status:` frontmatter says.
- **Why it matters:** A recorded disposition-divergence in REQUIREMENTS.md — the worst thing this audit can find — would land beside a filename that announces success.
- **REFUTATION CONDITION:** The summary template at `$HOME/.claude/get-shit-done/templates/summary.md` or the execute-plan workflow mandating `-PARTIAL.md` on any non-clean stop. Not shown in the review material, so partially SPECULATIVE; it is not cited by the plan.

---

### [LOW] 06-52's Question-2 acceptance criterion still points the pilot-fence measurement at "the ROADMAP's Phase 7 entry criteria" — the surviving instance of the §5-caught citation
- **Plan(s):** 06-52
- **Location:** task 1 acceptance — "Question 2's answer states, as a measured fact read from **the ROADMAP's Phase 7 entry criteria**, whether Phase 7's pilot fence is planned"
- **Mode:** other (coverage gap of an already-caught finding, not a restatement)
- **Finding:** §5 records that the wrong Phase 7 fence citation was caught and fixed — and it was, in `read_first` ("the pilot-fence commitment is NOT in this block") and in the action ("quote the committing sentence verbatim" from **Success Criteria item 1**). But the acceptance bullet — the text the executor's completion check runs against — keeps the old locus: the E1–E12 entry-criteria block, which per the plan's own warning does not contain the fence commitment. An executor that calibrates to the acceptance text performs the "not planned by omission" reading the read_first calls "a wrong reading." The plan itself assesses the bias direction as safe (toward `hold`), which is why this is LOW.
- **Why it matters:** The measurement presented to the snapshot go/no-go could record DEF-06-45-01's second clause as *not met* despite being committed — inside the artifact the operator decides from.
- **REFUTATION CONDITION:** The action text requires quoting Success Criteria item 1 verbatim and stating separately what the entry-criteria block does and does not say — an executor following the action satisfies the acceptance bullet under a charitable reading of "Phase 7 entry criteria." If the acceptance bullet is the only text the executor gates on, the finding stands; the bullet's wording is the defect.

---

### [LOW] 06-51 prescribes GNU `sha256sum` for the workstation side of the hash comparison, on the same macOS machine whose lack of GNU tooling the plan itself invokes
- **Plan(s):** 06-51
- **Location:** task 1 action (j) ("`sha256sum` of the same six scripts in the repository") and task 2 step 4, against the plan's own "(macOS has no GNU `timeout`)" caveat in the same action.
- **Mode:** other — sibling of the §4 `timeout` trap
- **Finding:** Stock macOS has `shasum -a 256`, not `sha256sum`. The remote (Linux) side is correctly specified; the local side assumes GNU coreutils. The hex digests are identical either way, so the cost is a command-not-found hiccup and an improvised substitution mid-gate — but this phase's recorded lesson is that macOS/GNU asymmetries get named in the plan, not discovered during an operator-gated step.
- **Why it matters:** The six-row MATCH table is 06-51's load-bearing proof; its workstation half should name the tool that exists on the workstation.
- **REFUTATION CONDITION:** `command -v sha256sum` resolving on the operator's workstation (e.g., via Homebrew coreutils). If so, the finding is cosmetic.

---

### [LOW] The register's "recorded as `PENDING` here" prose outside the anchored table rows goes stale the moment 06-52 fills them, and no acceptance criterion reaches it
- **Plan(s):** 06-50, 06-52
- **Location:** 06-50 task 1 — the *What this register does NOT do* section must state "R6-08 and R6-09 **are recorded as `PENDING` here** because they had not executed when this was written"; 06-52 task 3's PENDING-clearance check is `'^\|.*R6-0[89].*PEN[D]ING'`, anchored to table rows by design.
- **Mode:** B
- **Finding:** After task 3 runs, the mapping-table rows correctly read FIXED/CARRIED, while the unanchored NOT-do prose — instructed in present tense and scoped only by "when this was written" — still says the rows are PENDING. The register's own standard ("a register that quietly re-totals is worse than one that shows its arithmetic moving") is applied to the rows and counts but not to this sentence, and the `^\|` anchor that rightly excludes prose from the row count also guarantees the prose is never re-checked.
- **Why it matters:** The round's primary record closes in self-contradiction on exactly the rows it spent a task fixing. One past-tense/dated phrasing in 06-50's instruction ("were recorded as PENDING at wave 3") dissolves it.
- **REFUTATION CONDITION:** The register as actually written phrasing the NOT-do sentence in past or wave-scoped tense. The plan text's mandated wording ("are recorded as PENDING here") invites the present-tense stale form; if the executor date-scopes it, the finding dissolves.

---

**What was checked and held (no finding):** the 06-52 destroy fencing (single fully-qualified name, no `-r`/`-R`/`-f`, literal-equality fence, re-asserted presence immediately before the act, computed before/after name-set difference, `tank/downloads@pre-phase5` asserted present on every branch) satisfies §1.3; the bracketed-verb discipline with driven controls is consistent in both transcript plans. 06-51's no-redeploy guarantee (compose-verb transcript grep with the self-reference defect consciously avoided, fingerprint comparison) and `--ff-only`-only interlock satisfy §1.4. Every plan that touches planning documents carries the REQUIREMENTS.md/unticked-checkbox greps (06-47/48/50/51/52), satisfying §1.5; the MODE A cross-read of all seven `files_modified` sets found no fence walk-through — the shared files are wave-separated and the register hand-off is explicitly designed on both sides. The must_haves.truths of 06-46, 06-48, and 06-49 each trace to a mechanical gate, including the anti-self-report clause in 06-46's harness and the driven control matrices in 06-47/06-48.

## Verdict
- Findings: 0 HIGH, 1 MEDIUM, 6 LOW
- Would you let this round execute as written? **YES WITH FIXES**
- The single most important thing to fix first: give STATE.md the same two-step treatment the register and ROADMAP received — 06-50 task 2 (c) should write R6-08/R6-09 as *pending with 06-52 named as closing owner*, and 06-52 task 3 should take `.planning/STATE.md` into `files_modified` with an instruction and acceptance criterion to fold in both actual outcomes. As written, the round either fabricates operator outcomes two waves early in the one file a context-reset reader sees first, or leaves "pending" there permanently with no owner.

---

### deepseek-v4-pro (via pi / ollama-cloud) — 0 HIGH, 1 MEDIUM, 6 LOW — verdict YES WITH FIXES

I've read the full material and cross-checked the seven plans' `files_modified` lists, scope fences, wave/dependency structure, and each `must_haves.truths` against the task bodies and acceptance criteria. Below are my findings.

---

### [MEDIUM] The no-redeploy proof captures status but never compares it — a container restart is invisible to the mechanical check

- **Plan(s):** 06-51
- **Location:** Task 1 measurement (g) vs. Task 2 step 5 ("Re-take the container fingerprint … and compare")
- **Mode:** B (unenforced condition)
- **Finding:** Task 1 (g) captures the fingerprint as a "name+image+**status** triple per container." Task 2 step 5 then compares only "the sorted name+image list must be identical, and the container count must be unchanged" — the **status** field is silently dropped from the comparison. The acceptance criterion likewise only demands "a single word plus the count on each side." Status (the `Up N minutes/hours` string) is precisely the field that changes when a container restarts; name+image and count are invariant under a restart. So the independent half of the no-redeploy proof — the fingerprint — cannot detect the one thing it exists to corroborate, and the only remaining guard is the transcript's own `grep` that no `docker com[p]ose` verb appears (a self-report).
- **Why it matters:** The `must_haves.truths` "No service was redeployed: the running container set … is identical before and after" is asserted against a comparison that cannot falsify it for a restart. A restart triggered by any means other than a logged `docker compose` verb (a git hook, a manual `docker restart`, a supervisor action) would pass the name+image check and the self-reported compose-verb grep, leaving a false "nothing was redeployed" on a host running ~103 containers.
- **REFUTATION CONDITION:** Read `06-51-PLAN.md` Task 2 step 5 and show that "name+image list" is intended to include the `status` column captured in (g), or that some other step re-compares `docker ps` `Status`/`StartedAt` before vs. after. If no such step exists, the finding stands.

---

### [LOW] "halt"/"hold"/"defer" outcomes still emit `-SUMMARY.md`, in tension with the repo's own "-PARTIAL.md for halted plans" rule

- **Plan(s):** 06-51, 06-52
- **Location:** 06-51 Task 2 halt branch + `<output>`; 06-52 Task 2 hold/defer branch + `<output>`
- **Mode:** other (§4 trap)
- **Finding:** Both live-estate plans can reach an outcome that leaves the underlying action **undone** — 06-51 `halt` leaves the host unsynced (`DEF-06-45-05` item 2 open), 06-52 `hold`/`defer` leaves the snapshot held — yet each plan's `<output>` unconditionally names the file `06-NN-SUMMARY.md`. The plans frame these as "a legitimate, complete outcome," but the repo's own recorded trap (§4) is that a `-SUMMARY.md` filename marks a plan complete **regardless of `status:` frontmatter**, and "halted plans must be named `-PARTIAL.md`." Neither plan reconciles its "halt/negative-outcome" framing with that convention, nor states that the negative-outcome file will carry a `status:` the tooling actually honours.
- **Why it matters:** A later verification or reader that marks complete on filename alone will read a halted 06-51 or a held 06-52 as "done," when the host sync or snapshot release it was supposed to produce did not happen — exactly the masking the trap exists to prevent, on the two plans whose outcomes the round's primary record (`ROUND CLOSE`) will fold in.
- **REFUTATION CONDITION:** Show that 06-51/06-52 (or `06-50`'s register) explicitly states that a negative-gate outcome is written to a `-PARTIAL.md` (or that the `-SUMMARY.md` frontmatter `status:` is honoured over the filename by the tooling in this repo). If neither statement exists, the finding stands.

---

### [LOW] The three-way consistency audit names an owner for a ROADMAP and REQUIREMENTS divergence but not for a `deferred-items.md` divergence

- **Plan(s):** 06-47
- **Location:** Task 2 action, the "If any record disagrees" paragraph
- **Mode:** B (unenforced condition)
- **Finding:** The audit quotes **four** sources — `ROADMAP.md`, `beets.md`, `deferred-items.md`, `REQUIREMENTS.md` — but its divergence-handling names a correction owner for only three: `beets.md` (correct it here), `ROADMAP.md` (record, "06-50 will carry the correction"), `REQUIREMENTS.md` (record and stop). A disagreement found in `deferred-items.md` (e.g. `DEF-06-45-02`'s statement of the carry reading differently from the other records) has **no named owner and no handling branch** — the default "correct it but ONLY inside `beets.md`" is nonsensical for a divergence that lives in `deferred-items.md`.
- **Why it matters:** If `deferred-items.md` ever disagrees, the audit records a divergence nobody owns; it is neither corrected nor assigned, and the `must_haves.truths` "three records state the same thing" fails silently against a source the plan could not have fixed and did not route.
- **REFUTATION CONDITION:** Show a sentence in `06-47-PLAN.md` Task 2 naming the owner of a `deferred-items.md` divergence (a plan in round 6 that may edit it — 06-48/06-51/06-52 all do). If none is named, the finding stands.

---

### [LOW] `must_haves.truths` asserts unconditional three-record consistency, but the plan can only edit one of the three files

- **Plan(s):** 06-47
- **Location:** frontmatter `must_haves.truths` third bullet vs. `<success_criteria>`
- **Mode:** B (unenforced condition)
- **Finding:** The third truth reads "The three records of Phase 6's disposition — `ROADMAP.md`, `beets.md`'s Phase 6 closure section, and `deferred-items.md` — state the same thing…" as an unqualified end-state. But the plan's `files_modified` is only `beets.md` and one artifact, and its scope fence forbids touching `ROADMAP.md` (owned by 06-50) and `REQUIREMENTS.md`. So the truth is not achievable by 06-47 whenever `ROADMAP.md` or `deferred-items.md` diverges; it becomes true only later, after 06-50 runs. The `<success_criteria>` correctly softens this ("…or the divergence is named with its owning plan"), but the frontmatter truth — the thing a verifier mechanically checks — is stated unconditionally.
- **Why it matters:** If `ROADMAP.md` diverges at audit time, 06-47's own `must_haves.truths` is false at its close, and a strict verification flags a plan that did exactly what its success criteria permit. The truth and the success criteria describe two different contracts.
- **REFUTATION CONDITION:** Show that the third truth is conditional (e.g. "…or the divergence is named with its owner") in the frontmatter, or that 06-47 may edit `ROADMAP.md`/`deferred-items.md` to make it true. If it is unconditional and those files are out of scope, the finding stands.

---

### [LOW] The ROADMAP "Plans: 45 plans in 23 waves" header is left stale when the status row moves to 52/52

- **Plan(s):** 06-50
- **Location:** Task 2(b) item 3 ("the plan count moves from `45/45` to `52/52`") vs. the ROADMAP "**Plans**: 45 plans in 23 waves" narrative header
- **Mode:** other (§4 trap — "a count pinned as a constant that must be hand-moved")
- **Finding:** 06-50 updates the phase-status-table row to `52/52`, but its three additive edits (verify the seven plan lines, amend the disposition paragraph, update the status row) do **not** name the "Plans: 45 plans in 23 waves" header. After round 6 adds seven plans across five waves, that header should read `52 plans in 28 waves` and gain a round-6 clause; nothing in 06-50's action (nor 06-52's) updates it.
- **Why it matters:** The ROADMAP then carries two plan counts that disagree — the machine-read `52/52` status row and the stale `45 plans` narrative header — which is exactly the hand-moved-count drift the project has recorded firing before, and a later phase plans against whichever one it finds first.
- **REFUTATION CONDITION:** Show that 06-50 Task 2(b) (or 06-52 Task 3) updates the "Plans: N plans in M waves" header, or that this header is machine-regenerated. If it is neither edited nor regenerated, the finding stands.

---

### [LOW] The "CLAUDE.md mirrors CONVENTIONS.md" claim is enforced as a name-count floor, not as a match

- **Plan(s):** 06-49
- **Location:** Task 2 action ("a compact list of the convention **names** from `CONVENTIONS.md`") vs. acceptance criterion ("lists at least **8** convention names") and the `must_haves.truths` mirror claim
- **Mode:** B (unenforced condition)
- **Finding:** The truth asserts `CLAUDE.md`'s block "mirrors `CONVENTIONS.md`, which is the authoritative source." But the only mechanical acceptance check is that the block "lists at least 8 convention names" — a floor, not a correspondence check. There is no criterion asserting that the listed names are a subset of, or match, `CONVENTIONS.md`'s actual sections. A mirror listing eight wrong or invented names satisfies every acceptance criterion and the truth verbatim.
- **Why it matters:** A hand-maintained "mirror" that is not verified to match its source is exactly the "documentation-as-source-of-truth" drift this phase's own reviews keep catching; it will silently diverge the next time `CONVENTIONS.md` changes and the block is not re-synced.
- **REFUTATION CONDITION:** Show an acceptance criterion requiring the block's names to be a subset of `CONVENTIONS.md`'s `## ` headings (not merely ≥8). If only the ≥8 floor exists, the finding stands.

---

### [LOW] The register's three-way Counts reconciliation is never extended to R6-08/R6-09 after 06-52 fills them

- **Plan(s):** 06-50, 06-52
- **Location:** 06-50 Counts section (scoped to the 5 review findings) vs. 06-52 Task 3(a) ("change the R6-08 and R6-09 … rows from `PENDING` to their real dispositions")
- **Mode:** B (unenforced condition)
- **Finding:** 06-50 deliberately scopes its "reconcile three ways" Counts to the five review findings, explicitly excluding R6-08/R6-09 as `PENDING` "not counted in the reconciliation." 06-52 Task 3 fills R6-08/R6-09 with real dispositions from the closed four-word set, and says "if either row's disposition disagrees with what 06-50's Counts section predicted, say so." But 06-50's Counts predicted nothing for these rows (they were `PENDING`), so there is nothing to disagree with — and no step re-totals the now-seven dispositioned items. The register ends with 7 dispositioned rows but a reconciliation that still sums to 5.
- **Why it matters:** The register's central self-check ("totals reconcile three ways") silently stops covering two of its own rows at the moment they become real; a future reader trusting the Counts arithmetic will under-count the round's live-estate dispositions by two.
- **REFUTATION CONDITION:** Show that 06-52 Task 3 instructs updating the Counts section to include R6-08/R6-09 (or that 06-50's Counts section already includes a PENDING-accounting that 06-52 updates). If Counts remains 5-only, the finding stands.

---

## Verdict

- Findings: **0 HIGH, 1 MEDIUM, 6 LOW**
- Would you let this round execute as written? **YES WITH FIXES**
- The single most important thing to fix first: **06-51's no-redeploy fingerprint comparison must re-include the `status` column (or `StartedAt`) so a container restart is actually detectable by the independent check, rather than leaving the self-reported "no `docker com[p]ose` verb" grep as the only guard.** It is the one finding touching a live-estate safety proof, and it is a one-line fix (compare the full name+image+status triple both sides, not name+image).

The round is otherwise remarkably sound for a sixth adversarial pass — the cross-plan `files_modified` fences and wave/dependency structure check out cleanly (the three plans touching `deferred-items.md`, and the two touching `06-DISPOSITIONS-GAP4.md`/`ROADMAP.md`, are all strictly sequential, and every `PENDING`/`ROUND CLOSE` placeholder names a concrete owner and a `DEF-` fallback). The defects above are mostly the *last mile* of self-enforcement — truths asserted a shade more broadly than the mechanism that produces them, and one dropped field in a proof. None breaches the §1 invariants.

---
