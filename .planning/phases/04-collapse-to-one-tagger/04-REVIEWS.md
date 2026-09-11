---
phase: 4
reviewers: [gemini, opencode-grok, copilot-gpt-6-astra, copilot-gpt-5.4]
reviewed_at: 2026-09-11T14:06:27Z
plans_reviewed: [04-01-PLAN.md, 04-02-PLAN.md, 04-03-PLAN.md, 04-04-PLAN.md, 04-05-PLAN.md, 04-06-PLAN.md, 04-07-PLAN.md, 04-08-PLAN.md, 04-09-PLAN.md, 04-10-PLAN.md, 04-11-PLAN.md, 04-12-PLAN.md, 04-13-PLAN.md]
self_cli_skipped: claude
unavailable: [codex]
---

# Cross-AI Plan Review — Phase 4: Collapse to One Tagger

Four independent reviews from three model families, each given the same ~100k-token prompt:
instructions naming the phase's ten safety invariants, the failure modes to hunt, a
do-not-re-litigate list and known reviewer traps; then PROJECT context, the roadmap section,
TAGR-03/04/05, `04-CONTEXT.md` (D-01…D-35), 03-DECISION § Handoff to Phase 4, `04-RESEARCH.md`,
`04-VALIDATION.md`, `04-PATTERNS.md`, and all 13 plans.

| Reviewer | Invocation | Family | Overall risk |
|---|---|---|---|
| Gemini | `gemini -m gemini-3.1-pro-preview -p -` | Google | HIGH |
| Grok | `opencode run --model xai/grok-4.6 --agent plan -` | xAI | MEDIUM ("bordering HIGH") |
| Copilot · gpt-6-astra | `gh copilot -- -p "<prompt>" --model gpt-6-astra` | OpenAI | HIGH |
| Copilot · gpt-5.4 | `gh copilot -- -p "Read the file …"` (default model) | OpenAI | HIGH |

**Not run:** `claude` — skipped deliberately; this session authored the plans, so a same-model
review would not be independent. `codex` — its OpenAI API key has no credits remaining; Copilot on
`gpt-6-astra` (the model Codex is configured for) stands in for it.

**Every HIGH was graded against the plan text before being recorded** — see *Consensus Summary* at
the end: **3 HIGH confirmed, 2 HIGH refuted, 5 reclassified.** Read that section first; the raw
reviews follow unedited (tool-trace lines and ANSI codes stripped).

---

## Gemini Review

#### Summary

The phase plan successfully translates the complex requirements of retiring multiple legacy taggers into a structured sequence. However, it violates core safety invariants regarding wave boundaries, data fencing, and `beet` execution. Specifically, two plans introduce strict health checks before the estate complies with them, leaving the estate in a failing state across wave boundaries. Furthermore, active sabnzbd databases are deleted without fresh fence copies, and `beet` is invoked against the live survivor database rather than a throwaway.

#### Strengths

*   **Robust Research Integration:** The plans accurately incorporate the extensive live-estate findings (e.g., F1-F15), ensuring edge cases like the mutated `normalise-dj-tags.py` mutagen calls and the missing `Scarecrow` album are handled proactively.
*   **Strong Negative Controls:** The use of additive overrides (`RETIRED_DB_PATHS`, `DRIFT_EXPECT_*`) to drive assertions red without mutating real files is an excellent pattern that strictly adheres to the fail-closed doctrine.
*   **Impeccable Credential Hygiene:** The deletion of the Cloudflare DNS record avoids exposing the token in process arguments by piping it directly to `curl` via a bash builtin.

#### Concerns

*   **HIGH: Standing health checks left red across wave boundaries.**
    *   **Where:** 04-06 Task 2 ("EXPECTED RED WINDOW: from this plan's push until plan 04-11, the freeze fold-in in quick-health-check.sh is red") and 04-10 Task 3 ("plain run -> drift block ❌ for audio.bash AND sabnzbd beets-config.yaml").
    *   **What goes wrong:** 04-06 (Wave 2) introduces strict census checks that fail because the retired paths aren't deleted until 04-07 (Wave 3). 04-10 (Wave 5) introduces a drift check that fails because the repo files aren't installed to the host until 04-11 (Wave 6). If execution stops at either wave boundary, the estate is left with a failing routine health check, directly violating Invariant 1.
    *   **What would refute this:** Evidence that the health checks are conditionally bypassed or only warn until the corresponding wave completes, or that the wave boundaries are merged.

*   **HIGH: Unconfirmed deletion of active sabnzbd beets state.**
    *   **Where:** 04-11 Task 2. "Re-assert fence confirmations: `library.blb` and `.config/beets/library.db` rows from 04-01 are `y`/`y` (Phase 1 copies — D-04 does not require fresh archives of these regenerated/empty DBs)".
    *   **What goes wrong:** The plan explicitly skips fencing `scripts/library.blb` because it assumes the Phase 1 copy is sufficient, despite `04-RESEARCH.md` confirming `library.blb` is regenerated on every music job. It also deletes the 11 `.bak` files inside `.config/beets/` without confirming their fence copies. This violates Invariant 2, which requires a confirmed copy "not assumed from Phase 1" for these specific files.
    *   **What would refute this:** Evidence that the Phase 1 fence already contains up-to-date copies of all 11 `.bak` files and the freshly regenerated `library.blb`.

*   **HIGH: `beet` invoked against the live library database.**
    *   **Where:** 04-09 Task 1. "`docker exec -u abc beets beet stats` (default config -> `library: /config/library.db`)" and "`docker exec -u abc beets beet -l /config/library.db version`".
    *   **What goes wrong:** The plan invokes `beet stats` and `beet version` against the actual survivor database (`/config/library.db`). `beet` is not read-only, and Invariant 5 strictly forbids invoking `beet` without an explicit throwaway `-l <db>`. Running `beet stats` against the live DB to initialize it violates this invariant.
    *   **What would refute this:** Evidence that `/config/library.db` is a throwaway database, or that the command strings include a throwaway `-l` path.

*   **MEDIUM: Unverifiable verification step.**
    *   **Where:** 04-06 Verify block. `<automated>... timeout 200 ssh -n -o BatchMode=yes -o ConnectTimeout=10 root@172.16.1.159 "set -o pipefail; cd /mnt/fast/stacks && timeout 150 bash scripts/check-music-freeze.sh 2>&1 | grep -c 'retired path PRESENT'"</automated>`
    *   **What goes wrong:** The command executes the negative control run of `check-music-freeze.sh`, which correctly and intentionally exits 1. However, because `set -o pipefail` is active, the non-zero exit code of the script propagates to the `ssh` command, causing the entire `<automated>` verification pipeline to exit 1. The verification will reliably fail the plan on a perfectly successful execution.
    *   **What would refute this:** Evidence that `grep -c` overriding the pipeline status circumvents `pipefail`, which it does not.

*   **MEDIUM: Missing negative control for TAGGER_DEFS assertion.**
    *   **Where:** 04-06 Task 2.
    *   **What goes wrong:** Task 1 adds a new assertion that `TAGGER_DEFS` equals exactly 1. Invariant 7 requires every new assertion to be proven capable of failing via a driven negative control. Task 2's controls only observe the assertion passing (`tagger definitions: 1`) on the un-retired estate because 04-03 already deleted the extra definitions. It is never driven to fail.
    *   **What would refute this:** Evidence of a control that temporarily injects a dummy tagger definition into the stack YAML to prove the assertion goes red.

#### Suggestions

*   **For 04-06 and 04-10:** Shift the introduction of the health check assertions into the waves where the respective fixes are applied (merge 04-06 into Wave 3 alongside 04-07, and merge 04-10's drift check into Wave 6 alongside 04-11).
*   **For 04-11 Task 2:** Take a fresh `sqlite3 .backup` of `scripts/library.blb` and explicitly copy the 11 `.bak` files under `.config/beets/` to the fence, appending them to `MANIFEST.txt` with `integrity_check ok` immediately before deletion.
*   **For 04-09 Task 1:** Use an explicit throwaway `-l /config/throwaway.blb` for both `beet stats` and `beet version`, or omit the `beet stats` command entirely and allow the DB to initialize on its first legitimate use.
*   **For 04-06 Verify:** Remove `set -o pipefail;` from the `ssh` command string in the `<automated>` block, or append `|| true` to the `check-music-freeze.sh` invocation so its expected exit 1 does not fail the pipeline.
*   **For 04-06 Task 2:** Add a negative control that writes a dummy `image: metasauce/beets-flask` line to a scratch YAML file in `stacks/` to prove the `TAGGER_DEFS` assertion can turn red.

#### Risk Assessment

**HIGH**. The wave boundary violations guarantee the estate will be left in a failing health state if execution halts mid-phase. The unconfirmed deletion of `library.blb` risks permanent data loss of actively regenerated state, violating explicit safety fences. Finally, invoking `beet` without a throwaway risks silent migrations on the live database.

---

## Grok Review (opencode · xai/grok-4.6)

### 1. Summary

The 13 plans compose a coherent retirement: fence → repo delete → guard (red on live state) → host teardown → D-17 probe on the still-broken sabnzbd config → then TAGR-05/`audio.bash` → boot proof → green. D-17 ordering, git-as-delivery, `:ro` on Music, line-285-only strip, and token-on-argv rules are respected. Three defects would still make the phase unshippable or unprovable: `check-music-freeze.sh`’s planned `find` will abort under `set -e` on the estate’s measured RC 1; 04-07/04-09 tell the executor the freeze is “red only for X” while sabnzbd’s beets DBs keep `beets databases ≠ 1` until 04-11; and 04-11 deleting `library.blb` before the D-12 job can make `beets()`’s leftover `rm` fire under `set -e`, so the pre-declared chmod `Exit(1)` never appears. Several Wave 2/4 seams are real but narrower.

### 2. Strengths

- **D-17 is actually ordered.** 04-09 copies live sabnzbd `beets-config.yaml` and HALTs if the sha ≠ 04-01; 04-10 is the first plan that edits `plugins:`. Gate control (`--require-plugin musicbrainz` refuses) plus `--require-plugin embedart` for a real zero-candidate ledger is the right split.
- **Fence-before-rm is mechanical.** 04-01 D-35 `.backup` + `integrity_check ok` + MANIFEST; 04-07/04-11 re-assert immediately before an allow-listed `realpath` delete (S5). `wrtag.db` is no longer the D-04 hole.
- **`audio.bash` vendoring is two commits** (verbatim `fdcddca2…`, then one-line strip) so C3-a can prove the guard is byte-identical. Provenance stays in `sabnzbd.yaml`, not in the script.
- **Pattern 3 is real, not a slogan.** 04-06 lands before 04-07; first run must print `retired path PRESENT` for the 04-01 paths. Drift block (04-10) goes red on the un-installed host before 04-11 copies.
- **Secrets and public-repo hygiene are consistent.** Cloudflare `read -r` + `-H @<(printf …)`; SAB queue via `curl -K`; `--mb-only` never takes `DISCOGS_USER_TOKEN`; D-12 truncates `script_line`; `beets.log` goes to the fence, not git.
- **Agent-driven `import -t`** (`printf 'b\n' | docker exec -i` + `-l` throwaway + `-W -C` + overlay `write/copy/move: no`) matches the operator’s “bot yes, human prompt no.” 04-12’s pass/OPEN/FAIL is written in 04-01 before anyone looks.
- **D-30 two-rule Renovate shape** is copied from the measured validator transcript; `automerg` negative control is required, not hoped for.

### 3. Concerns

#### HIGH — 04-06 Task 1: `find` RC 1 under `set -euo pipefail` kills the census

**Where:** 04-06 Task 1, DB discovery: *“DB discovery: `find "$APPDATA_ROOT"` WITHOUT `-xdev` … pruning heavy trees you measure at execution”* — no handling of find’s exit status. Script conventions keep `set -euo pipefail`.

**What goes wrong:**
1. RESEARCH already measured this census method: *“find RC 1 = unreadable subpaths, stderr suppressed”* while still seeing 5/5 DBs.
2. `check-music-freeze.sh` is `set -e`. `found=$(find "$APPDATA_ROOT" …)` or a bare `find` returning 1 aborts the script before `retired path PRESENT`, before UNKNOWN counters, before `📊 7. Summary`.
3. 04-06 Task 2 control (a) never prints the required `retired path PRESENT:` lines (script died). Executor “fixes” with `find … || true` and no positive-control check, or abandons the section.
4. 04-11 Task 2 cannot get freeze exit 0 / C5-a. Criterion 5 has no instrument.

**What would refute this:** the landed script runs `find` in a context that ignores RC 1 *and* still fails closed if the Jellyfin positive-control DB is missing (`UNKNOWN — census blind`, FAILURES++). A transcript from LXC 100 with find RC 1 and a complete 6b section would refute.

---

#### HIGH — 04-11 Task 2 × 04-12: deleting `library.blb` can abort `beets()` before the baseline chmod

**Where:** 04-11 Task 2 *“delete … scripts/library.blb … so nothing can regenerate them”*; 04-10 Task 1 inventory *“beets() body minus the invocation (log lines + transient beets-match)”* — anatomy still has **lines 272–273 `rm library.blb`**, and lines 64–65 `set -e`; 04-12 / 04-D12-EVIDENCE pass condition *“script_line beginning `Exit(1): chmod: changing permissions of '/downloads/complete/nzb/music/`”*.

**What goes wrong:**
1. D-10 forbids editing 272–273. After the strip, every music job still enters `beets()` (gate 322–324 stays) and still `rm`s `library.blb`.
2. 04-11 deletes that file so freeze can go green, then 04-12 opens the window.
3. If 272–273 are not `rm -f` / not existence-guarded, `rm` of a missing file exits 1, `set -e` aborts **before** line 334 `chmod`.
4. SAB history is no longer the F8 baseline chmod line → 04-12 cannot PASS. Residual Audio.txt lines may also be missing. Criterion 3 is unsatisfiable without relaxing the pre-declared pass condition (the thing 04-01 existed to prevent).

**What would refute this:** live `audio.bash` 272–273 is `rm -f` or `[[ -f ]] && rm`. A 04-01 dump of those two lines would settle it; the plans never quote them.

---

#### HIGH — 04-07 Task 1 / 04-09 Task 1: expected freeze redness is wrong (seam with 04-06)

**Where:** 04-07 Task 1: *“`retired path PRESENT` now names only the three sabnzbd paths; beets databases fails because SURVIVOR_DB is absent … nothing else newly red.”* 04-09 Task 1: *“`beets databases` now 1 (the survivor) plus the sabnzbd ones still present → still red only on the sabnzbd retired paths.”*

**What goes wrong:**
1. 04-06 Task 1 asserts *“Fail unless beets DBs = 1 and that one is SURVIVOR_DB”* and classifies sqlite files with `items`+`albums` (and `library.db*` / `*.blb*` / `.bak` globs).
2. Until 04-11, sabnzbd still has `scripts/library.blb` (+ `.bak`) and `.config/beets/library.db` (+ `.bak`). Those are beets DBs. After 04-07, `beets databases` is **not** “0 because SURVIVOR_DB is absent”; it is ≥2 extras. After 04-09 it is survivor + extras, **never** 1.
3. Executor sees extra `beets databases` / `unclassified` failures, concludes 6b is wrong, and weakens the classifier (exclude `*.blb`, skip `.bak`, special-case sabnzbd) — recreating DEF-03-01’s blindness under a new name.
4. 04-11 then “turns green” against a check that no longer counts the DBs D-21/D-25 care about.

**What would refute this:** 04-06 explicitly excludes sabnzbd `*.blb` / `.bak` from the beets-DB **count** (while still `fail`ing them as retired paths), and 04-07/04-09 transcripts are rewritten to list every expected fail line. As written, 04-06’s classifier and 04-07/04-09’s expected output cannot both be true.

---

#### MEDIUM — 04-08 Task 2 depends on 04-06 output without `depends_on`

**Where:** 04-08 `depends_on: [04-03]` (Wave 2, parallel with 04-06). Task 2: *“on the host `bash scripts/check-music-freeze.sh` — its section 2 … must be unchanged versus 04-06's run.”*

**What goes wrong:** Wave 2 can run 04-08 first. There is no 04-06 SUMMARY to compare to; section 2 may still be the pre-D-21 script. The check that the new yaml adds no library mount is then vacuous or skipped.

**What would refute this:** orchestrator always finishes 04-06 before 04-08, or 04-08 compares to 04-01’s unfiltered mount census instead.

---

#### MEDIUM — 04-09 Task 1: `beet stats` with no `-l` (invariant 5)

**Where:** 04-09 Task 1: *“if `/config/library.db` does not yet exist, `docker exec -u abc beets beet stats` (default config → `library: /config/library.db`).”*

**What goes wrong:** Invariant 5 exists because Phase 1 `beet config` opened the default library and ran 11 migrations. If the D-27 file bind did not actually overlay `/config/config.yaml` (EROFS flip still in progress, wrong inode after `cp`/`mv`, LSIO default still winning), bare `beet stats` opens whatever default path the image believes — not a throwaway. `beet -l /config/library.db stats` creates the same D-28 file and keeps the invariant.

**What would refute this:** a `docker exec` transcript showing `library: /config/library.db` from `beet config` **with** `-l /config/probe-04/…` before the create, or the create command itself using `-l /config/library.db`.

---

#### MEDIUM — 04-09 Task 3: `state.pickle` sha must be unchanged vs svc-beets

**Where:** 04-09 Task 3: *“`state.pickle` must be unchanged because statefile pointed into probe-04”*; RESEARCH Pattern 2 / A3: `svc-beets` runs `beet web` on the **default** BEETSDIR (not the probe overlay) for the whole up-interval.

**What goes wrong:** Probe isolation starts in Task 2. Task 1 `up` already crash-loops `beet web` (no `web` plugin). That process can rewrite `/config/state.pickle` before any overlay exists. Task 3 acceptance then fails; executor drops the assertion and cannot tell a probe leak from s6 noise.

**What would refute this:** Task 1 records `state.pickle` sha **after** `up` (not only pre-up) and Task 3 diffs against the post-up sha; or a measured `beet web` failure that does not touch `state.pickle`.

---

#### MEDIUM — 04-06 / 04-10: census cost vs `REMOTE_TIMEOUT` 120 s

**Where:** 04-06 Task 1: *“the whole script must stay well under quick-health-check's 120 s REMOTE_TIMEOUT”*; VALIDATION raised the **plan verify** bound to 200 s because 6b walks all container states and ZFS children; 04-06 Task 2 / 04-10 do **not** change `REMOTE_TIMEOUT` in `quick-health-check.sh`. 04-10 then adds a second pipefail ssh (drift) in the same run.

**What goes wrong:** If pruning is not enough, fold-in RC 124 → UNKNOWN, exit 1. 04-11 “all guards green” never happens even with a correct estate. Tight pruning to beat 120 s can drop child datasets / Jellyfin positive control → false 0 or UNKNOWN.

**What would refute this:** 04-06 control (a) elapsed time ≪ 120 s on LXC 100 with the Jellyfin control DB found, and 04-10’s full `quick-health-check.sh` wall time ≤ 200 s.

---

#### LOW — 04-09 Task 1: pulling automerged `ls350` onto LXC 100

**Where:** 04-09 Task 1: *“If Renovate has already automerged a newer `2.13.1-lsNNN` … `docker pull` that exact tag … the probe then proves the version the repo ships.”* D-30: *“The host stays on ls349 until a deliberate redeploy.”* D-19/D-03: prove the pin that was measured.

**What goes wrong:** A patch-class image pull on `/` is bundled into criterion 4. Likely same beets 2.13.1, but it is not the spike image, and it leaves `ls350` resident for Phase 5/6 without a separate deploy decision.

**What would refute this:** treating 04-09 as D-30’s “deliberate redeploy,” with digest recorded and 2.13.1 confirmed via `beet version`.

### 4. Suggestions

1. **04-06 Task 1:** Run `find` with `set +e` / `find … || true`, keep stderr, and **fail UNKNOWN** if the Jellyfin MANIFEST DB is not in the result set. Do not let RC 1 abort, and do not `|| true` without the positive control.
2. **04-01 Task 1 (d):** Quote `audio.bash` lines 272–273 verbatim in 04-01-SUMMARY. If they are unguarded `rm`, either leave a sacrificial `library.blb` until after 04-12 (and accept freeze red on that one path), or widen 04-12’s pass line *in 04-01* to the actual `rm` error — do not discover it in 04-12.
3. **04-07 Task 1 / 04-09 Task 1:** Expected freeze list must include `beets databases` ≠ 1 (name sabnzbd `library.blb`, `.config/beets/library.db`, and any `.bak` the glob will see) until 04-11 Task 2. Do not say “red only on retired paths.”
4. **04-08:** Add `depends_on: [04-03, 04-06]` **or** compare section 2 to 04-01, not to 04-06.
5. **04-09 Task 1:** Create the DB with `beet -l /config/library.db stats` (and `-c /config/config.yaml` if you need to prove the overlay). Never a bare `beet`.
6. **04-09 Task 3:** Baseline `state.pickle` (and maxdepth-1 listing) **after** `up`+fresh DB, not pre-up; allow LSIO/s6 deltas recorded in Task 1.
7. **04-06 Task 2 / 04-10:** If control (a) is not comfortably under 120 s, raise `REMOTE_TIMEOUT` in the same commit as 6b (VALIDATION already argued 200 s) and say so in the EXIT-CODE notice.
8. **04-09 Task 2:** If `beet -c broken.yaml version` does not show embedart **only**, HALT — do not “fix” by dropping `--require-plugin` or editing the live sabnzbd file. Fallback: probe overlay must replace `plugins` (e.g. extra `-c` that is the sole plugins source), not merge with D-27’s `musicbrainz`.
9. **04-01 Task 1 (e):** Derive the container album path from `beets.yaml` volume lines, not a hardcoded `/mnt/tank/downloads` → `/downloads` rewrite.

### 5. Risk Assessment

**MEDIUM**, bordering HIGH until 04-06’s `find` and the `library.blb` `rm`/D-12 interaction are fixed on paper.

Retirement order, D-17, fences, `:ro` on Music, git delivery, and credential rules are in good shape; an executor who follows the freeze “expected redness” literally, or who hits find RC 1 / unguarded `rm`, can ship a blind guard or an unpassable criterion 3. Those are plan bugs, not estate mysteries — cheap to close before Wave 1.

---

## GitHub Copilot Review · gpt-6-astra (Codex stand-in)

### Summary

**The plans are not safe to execute as written.** The measured estate facts and locked decisions are generally handled carefully, including the live-config negative control and the one-line hook change. The principal defects are in composition: fatal health checks are activated several waves before their conditions become true; backup confirmation does not cover everything scheduled for deletion; the all-states census exempts an unsafe class of containers; and several verification commands can certify absence when their instruments failed. The survivor lifecycle and the real-job evidence also need tighter guarantees.

### Strengths

- **04-10 Task 1** makes the hook change unusually auditable: a byte-identical vendoring commit followed by exactly one deleted line, with separate guard-byte comparison.
- **04-09 Task 2** preserves the important D-17 distinction: the missing-plugin refusal is a separate control, while the actual negative arm requires `embedart` so it can execute and measure zero candidates. Fixing the survivor’s base config does not inherently invalidate this experiment; the overlay plugin checks address that interaction.
- **04-03 Tasks 2–3** incorporate the measured Renovate failures rather than merely copying the Jellyfin rule: separate versioning and update-policy rules, repository-mode validation, and discriminating controls.
- **04-01 Task 3 / 04-12 Task 2** predeclare the residual hook messages and baseline chmod failure, and provide an honest OPEN outcome without requiring the operator to drive an interactive beets prompt.

### Concerns

**C1 — HIGH: The planned red window violates independently shippable wave boundaries.**

**Where:** **04-06 Task 2**, “expected until 04-11”; its conventions explicitly declare “from this plan’s push until plan 04-11 … red.” **04-10 Task 3** similarly activates fatal drift assertions before installation in **04-11 Task 1**.

**What goes wrong:** Wave 2 finishes with the routine health check deliberately failing. Wave 3 deletes the survivor’s old databases, adding an absent-survivor failure until Wave 4. Wave 5 adds another fatal block whose expected mismatches are not repaired until Wave 6. There *is* a later green-making plan, but stopping at these earlier boundaries leaves permanent expected failures in the standing operational check. Documenting that condition does not make those boundaries independently shippable, and it makes additional failures harder to distinguish from unfinished phase work.

**What would refute this:** An explicit activation mechanism that keeps the existing standing checks operational until the new assertions’ conditions are satisfied, or a wave arrangement that completes the negative-control-to-green transition within the same boundary.

**C2 — HIGH: The deletion list is broader than the confirmed backup coverage.**

**Where:** **04-01 Task 2, step 5** reconfirms four primary database paths. **04-11 Task 2** then deletes “each `library.blb*` file by exact name” and the entire `.config/beets` directory, relying on the primary database rows being “`y`/`y`.”

**What goes wrong:** Research found **22 migration backups**, while the Phase 1 fence inventory includes **11**. Task 1 inventories the live files, but Task 2 does not establish verified fence coverage for each backup subsequently deleted. In particular, confirming a primary `.config/beets/library.db` copy does not confirm its eleven `.bak` files; confirming `scripts/library.blb` does not confirm its regenerated backup siblings. The final acceptance criterion requires confirmation for every deleted path, but the action supplies no procedure that produces that evidence. Execution can therefore delete files outside the confirmed fence.

This does not challenge the decision to reuse the historical primary-database copies; it identifies additional deletion targets lacking their own demonstrated coverage.

**What would refute this:** A source-to-fence mapping covering every backup file in the final deletion listing, with recorded hash and integrity confirmation before deletion.

**C3 — HIGH: The all-states census allows idle tagger-class containers to retain writable library mounts.**

**Where:** **04-06 Task 1** says section 1 “keeps its running-container scope,” while section 6b fails “any other **non-tagger** rw holder” and lists tagger-capable containers separately. **04-11 Task 2** and **04-13 Task 1** consume its green result as the criterion-5 proof.

**What goes wrong:** A created or exited beets container can have the proper beets config mount and a writable `/mnt/tank/media` mount. Section 1 ignores it because it is not running. Section 6b recognizes it as tagger-capable, so the specified non-tagger failure condition does not apply. Its capability is merely reported. With the normal repository definition still read-only, the declared-mount check need not catch this runtime deviation either. The census can therefore pass with exactly the idle writable tagger this phase must exclude.

**What would refute this:** A separate fail-closed assertion over **all container states** that rejects every writable mount reaching Music except Jellyfin, demonstrated using a created/exited tagger fixture.

**C4 — HIGH: The survivor bootstrap explicitly bypasses the throwaway-library invariant.**

**Where:** **04-09 Task 1** instructs `docker exec -u abc beets beet stats`, followed by `beet -l /config/library.db version`. It also knowingly starts the stock `svc-beets` command, `beet web`.

**What goes wrong:** The first explicit command lacks `-l`; the second targets the surviving database rather than a throwaway database. The stock service supplies another implicit-library invocation. Calling these operations “deliberate” or a “read path only” does not satisfy invariant 5—the precise lesson was that nominally informational beets commands can open and migrate a library. Fresh-database creation is required by D-28, but that does not authorize the plan’s broader CLI exception or repeated implicit opens during the probe.

**What would refute this:** A bootstrap procedure that initializes the required fresh database without unqualified beets CLI calls, puts all informational/probe CLI invocations on an explicit throwaway library, and prevents the stock service from opening the survivor database implicitly.

**C5 — HIGH: Several absence verifications turn instrument failure into success.**

**Where:** **04-07 Task 2, automated verification** combines a count inside `test` with `! timeout 30 docker image inspect …`. **04-09 Task 3, automated verification** uses the same container-count pattern. **04-13 Task 2, automated verification** uses `! gh issue view … | grep -q 'terry90/soulbeet'`.

**What goes wrong:** If Docker cannot enumerate containers, `grep -c` can print `0`; the surrounding `test` succeeds despite the failed command substitution. Remote `pipefail` does not make `test` inherit that failure. An image-inspection timeout or daemon error is also accepted by `!` as proof the image is absent. Consequently, 04-07 can print `CLEAN` while Docker is unavailable. Separately, a failed GitHub lookup produces no matching text, so the negated pipeline can pass and allow `SUITE-OK` without observing the dashboard.

These are executable false-green paths, not merely missing explanatory prose.

**What would refute this:** Driven unavailable/timeout controls showing that these exact acceptance paths return nonzero and UNKNOWN, with command status captured independently of the absence assertion.

**C6 — HIGH: Failure after survivor startup has no guaranteed return to dormancy.**

**Where:** **04-09 Task 1** starts the survivor. **Task 2** subsequently says “if not, HALT” when the album is unavailable, and also halts if the live broken-config hash changed. The `down` operation exists only in **Task 3**.

**What goes wrong:** The downloads tree is explicitly live. If Scarecrow disappears between the earlier measurement and Task 2, the plan halts after creating a running survivor. A config mismatch or failed probe can produce the same sequence. Nothing specifies unconditional cleanup on those exits, so Task 3 may never execute. `restart: "no"` does not stop an already running container or its internal service supervision. The phase then leaves the survivor running despite D-02 and invariant 10.

**What would refute this:** A lifecycle wrapper with guaranteed cleanup on success, failure, interruption and bounded-command termination, plus evidence that a forced post-start failure removes the survivor.

**C7 — MEDIUM: The real-job plan does not establish the predeclared “untagged” condition.**

**Where:** **04-01 Task 3** requires no MusicBrainz tags absent from the release as downloaded and explicitly makes the untagged outcome conditional on `ReplaygainTagging="false"`. **04-12 Task 3** substitutes a file-mtime comparison and states, “beets never ran, so any such tag came with the release.”

**What goes wrong:** 04-12 captures no pre-hook tag baseline for the selected release. File mtime is not proof of tag provenance, and the quoted reasoning assumes the conclusion the job is meant to establish. The consumer plan also never reasserts the ReplayGain prerequisite. If that setting changes during the potentially multi-day window, `r128gain` can write tags without creating beets databases or MusicBrainz keys, while the listed checks still pass. Conversely, an innocent release containing existing MusicBrainz tags cannot be conclusively judged from the proposed timestamp heuristic.

**What would refute this:** A before/after tag comparison tied to the same downloaded files, together with confirmation that the relevant runtime hook settings remained at their required values for the observed job.

**C8 — MEDIUM: 04-08 consumes a same-wave result without depending on its producer.**

**Where:** **04-08 Task 2** requires the freeze result to be “equal to 04-06’s recorded value,” but its frontmatter is `wave: 2`, `depends_on: [04-03]`. **04-06** also runs in Wave 2.

**What goes wrong:** A valid wave scheduler can execute 04-08 before 04-06 has produced its transcript or summary. The required comparison is then unavailable. The Wave 1 barrier supplies 04-01’s measurements, but it does not order these two Wave 2 plans. Execution must invent serialization, defer an acceptance condition, or compare against something other than the specified baseline.

**What would refute this:** An explicit scheduler guarantee ordering 04-06 before 04-08, or a revised task that obtains an independent before/after baseline without consuming 04-06’s output.

### Suggestions

1. **04-06 Task 2; 04-10 Task 3; 04-11 Tasks 1–2:** Run the new retirement assertions as candidate checks before cutover, then promote them into the routine fatal path only after their real-state controls and green run. Alternatively, consolidate activation and remediation into one wave. Do not weaken the checks with success-producing overrides.

2. **04-01 Task 2; 04-11 Task 2:** Build a per-file deletion/fence ledger, including both backup sets. Reconcile it against the final live listing and refuse deletion of any unmatched file. Fence missing backups before proceeding.

3. **04-06 Task 1:** Separate tagger classification from write authorization. Apply the Music write prohibition to every container state, regardless of tagger classification, with Jellyfin as the sole exception. Reuse the library-reachability helper and add a stopped/created-tagger control.

4. **04-09 Tasks 1–3:** Specify a narrowly scoped fresh-database initialization mechanism, retain throwaway `-l` paths for all CLI observations, and prevent implicit opens by `svc-beets`. Move album/config preconditions before startup and put startup, probe and teardown inside one guaranteed-cleanup lifecycle.

5. **04-07 Task 2; 04-09 Task 3; 04-13 Task 2:** Capture producer status before parsing its output. Distinguish successful empty enumeration, explicit not-found responses, transport errors and timeouts. Drive each error branch rather than relying on `pipefail` or negated commands.

6. **04-12 Tasks 1–3:** Implement the actual checklist contract: obtain a pre-hook tag baseline and compare afterward; assert the runtime ReplayGain prerequisite for the observation window. Replace the mtime-based provenance claim with evidence, or leave that condition unproven.

7. **04-08 Task 2:** Add the 04-06 dependency and move 04-08 to Wave 3, or remove that dependency on its output by measuring an independent baseline.

### Risk Assessment

**HIGH.** The ordinary happy path may complete, but the plans currently permit unfenced deletion, false-green absence proofs, and an idle writable tagger escaping the standing census. They also deliberately cross several wave boundaries with fatal checks red and lack guaranteed survivor cleanup on failure. These are execution-safety and evidence-validity defects; fixing them does not require reopening the chosen engine, retirement scope, or dismissed decisions.

---

## GitHub Copilot Review · gpt-5.4

### Summary

The plans are strongest where they fence deletions, preserve the D-17 negative-control ordering, and keep the `audio.bash` edit surgically constrained. The main problem is compositional: they knowingly commit the routine health checks red for multiple waves and, in the middle of that red window, delete the survivor’s last databases before creating the replacement. That breaks the phase’s own “independently shippable at every wave boundary” rule. The remaining defects are narrower but still real: one standing-check classifier misses soulbeet’s actual config filename, 04-09 violates the explicit-`-l` safety rule with a bare `beet` invocation, the new MB-only safety branch is never driven to fail, and 04-13 can publish a Phase 4 closure even if criterion 3 is still only OPEN.

### Strengths

- The D-17 experiment is well protected: 04-09 halts if the live broken sabnzbd config has drifted, so the negative control cannot be silently invalidated.
- Deletion fencing is generally excellent: 04-01/04-07/04-11 consistently require fence re-assertion immediately before destructive steps.
- 04-10’s two-commit `audio.bash` plan matches invariant 6 well: vendor verbatim first, then delete line 285 only, with byte-identity checks around the guard.
- Git delivery-path discipline is carried through consistently: commit/push/pull precedes host-side use of changed repo files.

### Concerns

- **HIGH — Routine checks are intentionally left red across several wave boundaries, and wave 3 also creates a zero-database half-state.**
  - **Where:** 04-06 Task 2, *“EXPECTED RED WINDOW: from this plan’s push until plan 04-11”*; 04-07 Task 1, *“the survivor’s old library.db and musiclibrary.blb... are deleted”*; 04-09 Task 1, *“if `/config/library.db` does not yet exist, `docker exec -u abc beets beet stats`”*; 04-10 Task 3, *“plain run → drift block `❌` ... overall exit 1”*.
  - **What goes wrong:** After 04-06, `quick-health-check.sh` is supposed to fail on the live estate. After 04-07, the survivor’s only two remaining beets DBs are gone. The replacement DB is not created until 04-09, and the sabnzbd drift block is then intentionally committed red again until 04-11 installs the host copies. If execution stops after wave 2, 3, 4, or 5, the estate is left with a routine standing health check that is red by design; if it stops after 04-07 specifically, it is also left with **zero** survivor DBs. That is exactly the kind of half-state invariant 1 says must not exist.
  - **What would refute this:** An explicit rule that these red runs stay out of the routine committed health check until 04-11, or a re-ordering that keeps 04-07’s survivor-DB deletion and 04-09’s fresh-DB creation in one shippable unit.

- **MEDIUM — 04-13 can “close” the phase even if criterion 3 is still OPEN or FAIL.**
  - **Where:** 04-12 Task 3, *“`Verdict: OPEN — no music job arrived ...`”*; 04-13 Task 1, *“row 3 quoting the D-12 verdict exactly as in 04-D12-EVIDENCE.md”* and *“`## Phase 4 — one tagger`”*.
  - **What goes wrong:** 04-12 explicitly allows an OPEN outcome when no real music job arrives. 04-13 does not require PASS; it only requires that row 3 quote whatever verdict 04-12 produced. So the plan set can publish a Phase 4 closure section, run the final sweep, and look “done” even though ROADMAP criterion 3 was never proven, or was proven false.
  - **What would refute this:** A hard gate in 04-13 that stops closure unless 04-D12-EVIDENCE says `Verdict: PASS`, with OPEN/FAIL treated as “phase not closable yet.”

- **MEDIUM — The new mount-based classifier misses soulbeet’s actual config filename, weakening the standing guard against resurrection.**
  - **Where:** 04-06 Task 1, *“`is_tagger_mount SRC` returning true when SRC ... is a file named `beets-config.yaml`, `library.db`, `*.blb` or `wrtag.db`”*; elsewhere the retired file is consistently `arrs/soulbeet/beets_config.yaml`.
  - **What goes wrong:** 04-06 deliberately removes the old name-based `TAGGER_PATTERN` and replaces it with a mount-based classifier. But the classifier matches `beets-config.yaml` and not `beets_config.yaml`, which is soulbeet’s actual config name throughout the material. A resurrected soulbeet mounting only that config path, before it creates a DB and without an rw Music mount, can slip past the “tagger-capable” classification and leave the counters green when D-21 says a resurrected tagger should fail the guard.
  - **What would refute this:** Evidence that the real soulbeet mount source would still be caught by another branch of `is_tagger_mount` in practice, or a plan edit that matches both hyphen and underscore forms.

- **MEDIUM — 04-09 breaks the explicit-`-l` rule with a bare `beet` invocation at the exact moment it is trying to prove which DB is “the one.”**
  - **Where:** 04-09 Task 1, *“`docker exec -u abc beets beet stats` (default config → `library: /config/library.db`)”*.
  - **What goes wrong:** The phase invariant is explicit: *“`beet` is never invoked without an explicit throwaway `-l <db>`.”* That rule exists because Phase 1 already demonstrated that a bare `beet` command can open and migrate the wrong library. Here the plan is trying to create and prove the one fresh survivor DB, but it makes that proof config-dependent again by omitting `-l /config/library.db`. If the bind mount or config resolution is not exactly what the plan thinks, the command can touch the wrong DB and blur the evidence.
  - **What would refute this:** A source-backed proof that, in this exact state, `beet stats` cannot touch any path except `/config/library.db`; otherwise the safer form is simply to pass `-l /config/library.db`.

- **LOW — The new MB-only safety branch is never proven capable of failing.**
  - **Where:** 04-08 Task 1 must-have, *“`--mb-only` ... REFUSES to run if the discogs plugin is loaded”*; acceptance, *“exits non-zero naming SPIKE_CONFIG and NOT naming DISCOGS_USER_TOKEN”*; 04-09 Task 2 gate control, *“REFUSES, naming musicbrainz as not loaded.”*
  - **What goes wrong:** The phase invariant for new assertions is “proven capable of failing.” But the only exercised MB-only failure is the missing-env path, and the only probe refusal exercised in 04-09 is the pre-existing missing-`musicbrainz` gate. Nothing actually runs `--mb-only` against a config that loads `discogs`, so the new “refuse if discogs is loaded” branch is only statically present, not demonstrated.
  - **What would refute this:** One driven control in 04-08 or 04-09 using a scratch config with `discogs` loaded and asserting a refusal that explicitly names `discogs`.

### Suggestions

- In **04-06 / 04-07 / 04-09 / 04-10 / 04-11**, stop wiring expected-red checks into `quick-health-check.sh` until the same wave that turns them green, and move the survivor DB deletion from **04-07 Task 1** to the same shippable unit that creates the fresh DB in **04-09 Task 1**.
- In **04-13 Task 1**, make Phase 4 closure conditional on **04-12 Task 3** producing `Verdict: PASS`; if it is OPEN or FAIL, write an interim status section instead of a closure.
- In **04-06 Task 1**, widen `is_tagger_mount` to recognize both `beets-config.yaml` and `beets_config.yaml`, or more generally any mounted beets config file regardless of basename.
- In **04-09 Task 1**, replace bare `beet stats` with an explicit-path invocation, ideally `beet -l /config/library.db stats`, so the “one DB” proof is not configuration-implicit.
- In **04-08 Task 1** or **04-09 Task 2**, add one explicit negative control for MB-only against a config that loads `discogs`, and assert the refusal text.

### Risk Assessment

**HIGH** — mostly because the plans violate their own shippability invariant in the middle of execution: they commit the routine health checks red for multiple waves, and one of those waves removes the survivor’s last DB before its replacement exists. The other defects are fixable, but as written this plan set can leave the estate in an acknowledged half-state and can also publish a Phase 4 closure without criterion 3 ever being proven.

---

## Consensus Summary

Four reviewers, three model families. Every HIGH was graded against the plan text — and, where a
reviewer made a claim about the estate, against the live file — before being recorded. Verdicts:
**CONFIRMED** (the defect is in the text as written), **PLAUSIBLE** (the mechanism is real, the
impact unmeasured), **REFUTED**.

### Revision priorities (graded)

| # | Finding | Raised by | Verdict | Severity after grading |
|---|---|---|---|---|
| 1 | **Red window crosses wave boundaries.** 04-06 makes the freeze fold-in fatal-red from wave 2 until 04-11 (wave 6); 04-10 adds a second fatal-red block in wave 5. A stall at any of waves 2–5 leaves the routine health check permanently red, and masks any genuine new failure in the same block | Gemini H1, astra C1, gpt-5.4 H1 | **CONFIRMED** by three reviewers — `quick-health-check.sh:16-17` states the script is built so it "does not inherit a permanent red"; 04-06's conventions declare the window openly. Violates invariant 1 | **HIGH** |
| 2 | **Absence verifications go green when the instrument fails.** `test $(docker ps … \| grep -c …) = 0` passes when docker is unreachable (the substitution prints `0`; `test` never sees the failed pipeline); `! docker image inspect …` passes on a daemon error; `! gh issue view … \| grep -q …` passes when `gh` fails | astra C5 | **CONFIRMED** — 04-07 Task 2 `<verify>`, 04-09 Task 3 `<verify>`, 04-13 Task 2 `<verify>`. The "silence read as clean" class README § Health Checks forbids | **HIGH** |
| 3 | **04-09 has no guaranteed return to dormancy.** Task 1 starts the survivor; Task 2 can HALT (album gone, broken-config sha moved); `down` exists only in Task 3 | astra C6 | **CONFIRMED** — both HALTs sit after `up -d`. Violates invariant 10 on the failure path. Cheap fix: move both preconditions before `up`, wrap start → probe → down in a `trap` | **HIGH** |
| 4 | **Fence coverage is narrower than the 04-11 deletion list.** 04-11 deletes every `library.blb*` and all of `.config/beets/` (two sets of 11 `.bak`) but re-confirms only the two primary DBs; `library.blb` is regenerated on every job, so its Phase 1 copy is not the file being deleted. 04-07 takes a fresh `.backup` when a live sha drifted; 04-11 does that for `beets.log` only | Gemini H2, astra C2 | **CONFIRMED** — RESEARCH F2/F3: the fence holds 11 `.bak` of *one* DB. 04-11's own C5-b ("every deleted sabnzbd path has a recorded fence confirmation") cannot be met by its action. The content is low-value (regenerated per job / Phase 1 probe migrations), hence the downgrade | MEDIUM (was HIGH) |
| 5 | **04-08 consumes 04-06's output with no dependency.** Both are wave 2; 04-08 Task 2 requires freeze section 2 "equal to 04-06's recorded value" | Grok M1, astra C8 | **CONFIRMED** — independent convergence. Fix: `depends_on: [04-03, 04-06]` (→ wave 3), or compare against 04-01 | MEDIUM |
| 6 | **04-13 publishes the Phase 4 closure whatever criterion 3's verdict.** 04-12 legitimately allows `OPEN`; 04-13 Task 1 gates on the freeze exit code but only *quotes* the D-12 verdict | gpt-5.4 M1 | **CONFIRMED** — honest quoting prevents misrepresentation, but a section headed as the closure should not be written over an OPEN/FAIL criterion. Fix: closure only on `Verdict: PASS`, otherwise an interim status section | MEDIUM |
| 7 | **The census exempts idle tagger-class containers holding rw on Music.** 6b fails only *non-tagger* rw holders and merely *lists* tagger-capable ones; section 1 covers running containers only | astra C3 | **CONFIRMED** — 04-06 Task 1 (iv). Criterion 5's letter exempts taggers, but Phase 1 D-20 (nobody holds rw on Music until Phase 6) does not. Narrow: needs a runtime-only deviation on a non-running container | MEDIUM |
| 8 | **`find` RC 1 aborts the census under `set -euo pipefail`** | Grok H1 | **CONFIRMED** — RESEARCH line 522 measured "`find` RC 1 = unreadable subpaths"; 04-06 never says how RC is handled. Contained if the executor follows the house `\|\| true` pattern (`check-music-freeze.sh:361/366/442`) *and* keeps the Jellyfin positive control the plan already mandates | MEDIUM (was HIGH) |
| 9 | **04-07/04-09 state the wrong expected-red set.** 04-09 Task 1 says "still red only on the sabnzbd retired paths", but 04-06's classifier also counts sabnzbd's `library.blb` / `.config/beets/library.db` / `.bak` as beets DBs until 04-11. An executor who sees the extra red may weaken the classifier to match the prose | Grok H3 | **CONFIRMED** — and contradicted by 04-09 Task 3, which gets it right | MEDIUM (was HIGH) |
| 10 | **04-06's own `<verify>` fails on a correct run** — remote `set -o pipefail` plus the freeze script's intended exit 1, piped into `grep -c` | Gemini M1 | **CONFIRMED** — 04-06 line 122 | MEDIUM |
| 11 | **04-12 cannot establish "untagged".** MusicBrainz-tag provenance is judged by an mtime heuristic that assumes its conclusion ("beets never ran, so any such tag came with the release"); the `ReplaygainTagging="false"` prerequisite 04-01 declared is never re-asserted for the window | astra C7 | **CONFIRMED** — 04-12 Task 3 step (5); 04-12 reads no `extended.conf` | MEDIUM |
| 12 | **`tagger definitions = 1` is never driven red** (invariant 7) | Gemini M2 | **CONFIRMED** — 04-06 Task 2 controls (a)–(d) only observe it pass | LOW |
| 13 | **MB-only's new "refuse if discogs is loaded" branch is never driven** (invariant 7) | gpt-5.4 L1 | **CONFIRMED** — 04-08's smoke exercises only the missing-env path; 04-09's gate control exercises the pre-existing missing-`musicbrainz` refusal | LOW |
| 14 | **`is_tagger_mount` misses soulbeet.** It matches `beets-config.yaml`; soulbeet mounted `…/soulbeet/beets_config.yaml` (underscore) and keeps `soulbeet.db` | gpt-5.4 M2 | **CONFIRMED** — `soulbeet.yaml@HEAD:50,55`. Downgraded: a resurrection is still caught twice (6b's `tagger definitions` git grep includes `ghcr.io/terry90/soulbeet`; the retired-path check covers `/mnt/fast/appdata/arrs/soulbeet`), and an *unclassified* container with rw on Music fails as a non-tagger anyway | LOW |
| 15 | **04-09 pulls a Renovate-automerged `ls350` onto the host**, while D-30 says the host stays on ls349 until a deliberate redeploy | Grok L1 | **CONFIRMED** as a text conflict — either name 04-09 as that deliberate redeploy, or keep ls349 and record the delta | LOW |
| 16 | `state.pickle` baseline taken pre-`up`, but `svc-beets` runs for the whole up-interval | Grok M3 | **PLAUSIBLE** — unmeasured whether a failing `beet web` writes the statefile. A post-`up` baseline costs nothing | LOW |
| 17 | Census runtime vs `REMOTE_TIMEOUT` 120 s | Grok M4 | **PLAUSIBLE** — 04-06 already requires < 60 s measured; the risk is that pruning to meet it drops the positive control | LOW |

### Refuted — recorded so they are not re-raised

- **"`beet` invoked against the live survivor DB" — Gemini H3 (HIGH), astra C4 (HIGH), Grok M2,
  gpt-5.4 M3.** Four reviewers converged on the *mechanism*, and the HIGH is still wrong: the DB
  `beet stats` opens is the *fresh, empty* one D-28 exists to create, and 04-09 says so
  ("deliberately and separately from the probe"; it even anticipates `svc-beets` creating it first).
  Invariant 5 protects databases that hold something. **Accepted as LOW hardening:** write the
  create as `beet -l /config/library.db stats`, so the path is explicit rather than config-derived —
  which also answers Grok's "what if the overlay did not take" variant.
- **"Deleting `library.blb` aborts `beets()` under `set -e` before the baseline `chmod`, making
  criterion 3 unpassable" — Grok H2 (HIGH).** Refuted against the live file (sha256
  `fdcddca234b2`, the exact file 04-10 vendors): `audio.bash:272-275` is
  `if [ -f /config/scripts/library.blb ]; then rm …` — existence-guarded. Grok's own refutation
  condition is met.
- **"Wave 3 leaves the survivor with zero databases" — gpt-5.4, inside its H1.** True and harmless:
  the survivor is dormant, both deleted DBs are fenced and unused (D-28), and nothing reads the path
  until 04-09 creates the fresh one. The red-window half of that finding stands as row 1.
- **(Orchestrator's own suspicion) the 6b `git ls-files` census breaks when the script is invoked
  from outside the repo.** Refuted: `check-music-freeze.sh:68-69` `cd`s to `REPO_ROOT` itself.

### Agreed Strengths

- **D-17 is genuinely ordered and genuinely discriminating** (all four): 04-09 copies the live
  broken config and HALTs if its sha moved; the missing-plugin *refusal* is a separate control from
  the `--require-plugin embedart` negative arm that actually runs and measures zero.
- **`audio.bash` in two commits** — verbatim `fdcddca2…`, then a one-line strip — makes the
  byte-identical `SAB_PP_STATUS` guard provable (Grok, astra, gpt-5.4).
- **Fence-before-delete is mechanical** where it is specified: allow-listed `realpath`, re-asserted
  immediately before `rm` (Gemini, Grok, gpt-5.4).
- **Git delivery discipline** — commit, push, pull before any host-side use — is carried through
  every plan (Grok, gpt-5.4).
- **Credential handling is consistent**: `read -r` + `-H @<(printf …)`, `curl -K`, and `--mb-only`
  never touches the Discogs token (Gemini, Grok). No reviewer found a credential exposure.

### Divergent Views

- **The red-first guard pattern.** Gemini, astra and gpt-5.4 make it the phase's top HIGH; **Grok
  lists it as a strength** ("Pattern 3 is real, not a slogan"), and RESEARCH § Pattern 3 recommends
  it. Both sides are right about different things: the *driven negative control on real state* is
  valuable; the *fatal fold-in during the window* is what breaks invariant 1. The resolution astra
  and gpt-5.4 both propose keeps both — run the new assertions red-first as a candidate check, and
  promote them into the fatal `quick-health-check.sh` path only in the wave that turns them green.
- **The two OpenAI models did not echo each other.** astra and gpt-5.4 shared only rows 1 and the
  refuted `beet stats` item; astra alone found rows 2, 3, 7 and 11, gpt-5.4 alone rows 6, 13 and 14.
  Same-family is not the same review, but their agreement on row 1 counts for less than Gemini's.
- **Overall risk:** Gemini, astra and gpt-5.4 HIGH; Grok MEDIUM ("bordering HIGH"). Nobody asks for
  the engine, the retirement scope or any dismissed decision to be reopened — every finding is a
  plan-text fix.

### Nobody raised

- **The D-17 overlay mechanism itself** — that `-c broken.yaml`'s `plugins:` *replaces* the
  survivor's `plugins: musicbrainz` rather than merging with it. That silence is correct: 04-09
  Task 2 step (1) measures it directly with `beet version` before either probe arm runs, and Grok
  suggested halting if it ever shows otherwise.
- **The sabnzbd recreate's network dependence** (`scripts_init.bash` runs `pip install -U beets`
  and git/curl on every boot). 04-11 bounds the boot wait at 15 minutes and records the residual,
  but a boot during an upstream outage fails the proof for a reason unrelated to `:ro`. Worth one
  line in 04-11 distinguishing "init failed for network" from "init failed for EROFS" before the
  rollback branch fires.

### Suggested revision order for `/gsd-plan-phase 4 --reviews`

1. Rows 1–3 (HIGH): the candidate-check/promote split for 04-06 and 04-10; a producer-status-first
   rewrite of the three `<verify>` absence checks; the pre-`up` preconditions plus a `trap` in 04-09.
2. Rows 4–11 (MEDIUM): each is a local edit to one or two plans; row 5 changes 04-08's wave.
3. Rows 12–17 (LOW) and the `beet -l` hardening: fold into the same edits where they touch the same task.
