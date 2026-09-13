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

---

# Round 2 — gap-closure plans (2026-09-13)

> **Citation note.** Everything above this line is **round 1** (plans 04-01..04-13, reviewed
> 2026-09-11). The "REVIEWS row N" references in `04-01-PLAN.md`, `04-06-SUMMARY.md`,
> `04-D12-EVIDENCE.md` and `04-VERIFICATION.md` all point at **round 1's** Consensus table and
> are unaffected by this append. Cite round 2's findings as "round 2 row N".

**Reviewers:** gemini-3.1-pro-preview · xai/grok-4.6 (opencode) · copilot gpt-5.4 · copilot gpt-6-astra
**Plans reviewed:** 04-14-PLAN.md, 04-15-PLAN.md, 04-16-PLAN.md
**Excluded:** codex (API key out of credits) · claude (orchestrator's own family)


# Cross-AI Plan Review — Phase 4 gap closure (round 2)

Four reviewers across **three model families**: Gemini 3.1 Pro (Google), Grok 4.6 via opencode
(xAI), and GitHub Copilot on both `gpt-5.4` and `gpt-6-astra` (OpenAI, standing in for Codex,
which is out of credits). Each received an identical 183 KB prompt: all three plans in full, the
D-12 evidence contract, `04-VERIFICATION.md`, window 1's summary with its six deviations, the
phase's ten safety invariants, a named failure mode to hunt, a do-not-re-litigate list, and round
1's graded consensus with instructions to extend rather than repeat it.

**Scope.** Plans 04-01..04-13 are executed and were not reviewed. Criteria 1, 2, 4 and 5 are
verified and were not re-planned. This round covers only the three unexecuted gap-closure plans
that exist to close criterion 3 / TAGR-04's behavioural half.

Every finding below was graded before being recorded — against the plan text, and where it makes a
claim about the live system, against the live files and the live estate. Verdicts: **CONFIRMED**
(the defect is in the text as written), **PLAUSIBLE** (mechanism real, impact unmeasured),
**REFUTED**. Two findings were downgraded on measurement and two of the orchestrator's own leads
were discarded before they became findings; both are recorded below, because a wrong blocker costs
a revision cycle exactly as a missed one does.


## Gemini Review (gemini-3.1-pro-preview)

### 1. Summary

The plans are logically well-structured and exhibit excellent hygiene regarding synthetic controls, verifiable handoffs, and in-band contract amendments. However, they are **not fit to execute** due to a fundamental physical flaw in the new watcher's design. SABnzbd's immediate move of unpacked directories prevents a polling watcher from ever capturing a 2-second stable state in the `incomplete/` directory, guaranteeing an `UNPROVEN` or `FAIL` result for real jobs. Additionally, critical process cleanup verifications are missing from the automated `<verify>` blocks, risking abandoned background processes.

### 2. Strengths

- **Robust Verdict Extraction:** The use of `grep -oE` chained with `awk '{print $NF}'` in 04-16 Task 1's `<verify>` block is an elegant and bulletproof way to extract the verdict token, even when the line contains trailing prose.
- **Genuine Synthetic Controls:** Plan 04-14 Task 2 correctly demands that the instrument's exact failure conditions (`FAIL` and `UNPROVEN`) be proven by measurement on synthetic fixtures, not merely assumed.
- **Contract Integrity:** The in-band amendment to `04-D12-EVIDENCE.md` in 04-14 Task 3 is strictly additive and explicitly executed *before* the window opens, preventing the contract from being fitted to the evidence.

### 3. Concerns

- **Severity: HIGH**
  - **Location:** 04-14 Task 1 (impacts 04-15)
  - **Mechanism:** The core design of the new watcher requires a file to be stable in `incomplete/` for at least 2 seconds (two consecutive polls) to capture `pre.sha256`. However, SABnzbd moves the job folder to `complete/` immediately after assembly or unpacking is finished. The audio files will never sit in their final state in `incomplete/` for the 2 seconds required. The watcher will either fail to capture a snapshot (resulting in `UNPROVEN`) or capture a partial mid-unpack state (resulting in `FAIL changed=1`). The synthetic control (SC-1) only passes because it manually introduces an artificial pause before executing the `mv` command.
  - **Refutation condition:** Prove that SABnzbd's post-processing queue naturally introduces a delay of at least 2 seconds between completing a job's assembly/unpack and moving its folder to the destination tree.

- **Severity: HIGH**
  - **Location:** 04-14 Task 2 and 04-15 Task 3
  - **Mechanism:** Both tasks instruct the executor to "Prove no watcher process remains using the self-match-proof method" (using a captured `ps` snapshot and `grep -F -f`), but their `<verify>` blocks omit this check entirely. In 04-14 Task 2, the `.ps-probe-14` snapshot is taken and immediately deleted without searching for the watcher process. In 04-15 Task 3, only the deletion of the scratch folders is verified. If the watcher process fails to terminate, the `<verify>` block will still erroneously pass, violating the invariant that absence checks must be positively verified.
  - **Refutation condition:** Point to the command inside the `<verify>` blocks of 04-14 Task 2 and 04-15 Task 3 that actually asserts the absence of the watcher process (e.g., executing a `grep -F -f` check against the `ps` snapshot).

- **Severity: LOW**
  - **Location:** 04-14 Task 3
  - **Mechanism:** The `<verify>` block asserts `test "$(grep -c 'Verdict (window 2)' "$f")" = 0`, expecting the phrase `Verdict (window 2)` not to exist in the file. However, the action text instructs the executor to explain that the second window's result will be recorded in § 7. If the executor naturally writes the phrase "Verdict (window 2)" in their prose explanation (e.g., "The Verdict (window 2) will be recorded..."), the verify block will fail despite correct execution.
  - **Refutation condition:** Prove that the plan explicitly forbids the executor from using the phrase "Verdict (window 2)" in the prose added to § 5.

### 4. Suggestions

- **For 04-14 Task 1:** Acknowledge that a polling watcher in `incomplete/` cannot reliably capture the final post-unpack bytes without a race. Modify the strategy to either use `inotifywait` to trigger instantly on the directory move into `complete/` before the script executes, or implement a lightweight wrapper script around `audio.bash` that takes the `pre.sha256` snapshot synchronously *before* executing the remaining hook logic (though this temporarily modifies the estate). 
- **For 04-14 Task 2 & 04-15 Task 3:** Update the `<verify>` blocks to explicitly perform the `grep -F -f` search on the captured `ps` snapshot to assert the watcher process is dead, rather than just asserting the snapshot file is not empty.
- **For 04-14 Task 3:** Change the `<verify>` block's assertion to `test "$(grep -cE '^Verdict \(window 2\):' "$f")" = 0` to specifically prevent a premature machine-readable verdict line, while allowing the phrase "Verdict (window 2)" to appear safely in the prose.

### 5. Risk Assessment

**HIGH.** Executing these plans as written will reliably fail to close criterion 3 because the new watcher instrument is structurally incapable of capturing the final pre-move bytes of a real job. Furthermore, the omission of process liveness checks in the automated `<verify>` blocks risks leaving rogue watcher processes running indefinitely, directly violating the project's core safety invariants for instrument lifecycle and positive control verification.

---

## Grok Review (xai/grok-4.6 via opencode, `plan` read-only agent)

# Cross-AI Plan Review — 04-14 / 04-15 / 04-16

## 1. Summary

Fit to execute **after two local text fixes**; not fit as written. Design (a), the pre-window contract amendment, mechanical `STATUS=` extraction, and the window-2 verdict line that cannot collide with `^Verdict:` are the right shape. Two defects will spend the scarce job and still leave criterion 3 unprovable or wrongly FAIL: the watcher's empty-window exit condition (`LINGER=300` with a vacuous “every row seen” clause), and Task 2’s verify, which never gates `SC-1 STATUS=BYTES-OK`. Everything else is MEDIUM/LOW rework, not a reason to reopen the engine or the estate.

## 2. Strengths

- Design (b) is rejected on job A’s measured 12:18:00.074Z vs 12:17:59Z `Matching` line, not taste. Ordering becomes structural.
- Contract is amended and committed before the stamp; 04-15 Task 1’s action checks committer date `<` stamp; 04-16 selects the heading from the verdict line, not the author.
- `Verdict (window 2):` does not match `^Verdict: (PASS|OPEN|FAIL)` — invariant 9 survives by construction.
- 04-15’s verify accepts any verdict word (outcome, not a goal). SC-2/SC-3 use UNKNOWN (exit 3) vs FAIL (exit 1). Replaygain uses the anchored grep, not `-cx`.
- `$OUT` *is* the watch dir (`…/15/watch/map.tsv`), which is the 04-12 deviation-2 trap closed.
- Weaker side-effects cannot upgrade the verdict; window-1 § 6 is left standing; FLAC conversion is a no-op (`audio.bash:220-221`), so design (a) spanning `clean()` is the intended stronger span, not a hidden rewriter.

## 3. Concerns

- **HIGH — 04-14 Task 1 behaviour / 04-15 Task 1 launch.** Exit rule is “every history row seen has `post.sha256` and `LINGER` has elapsed since the last row” (04-14 line 126). Default `LINGER=300`. 04-15 does not override it; the 7-day bound is only the outer `timeout 604800`. Zero rows makes “every row has post.sha256” vacuously true. Self-test always inserts a row (`LINGER=10`), so the empty-window path is never driven. A literal implementation exits ~5 minutes after arming; Task 2 then waits 1–5 days with a dead watcher; the job is UNPROVEN; criterion 3 stays OPEN after the one chance is spent. 04-12’s rule was “exit after the *first job* has both snapshots plus 5 minutes, or when killed” — this wording dropped the “first job” guard. *Refutation:* the script (or 04-15 launch) requires a history row before linger starts, and the SUMMARY says so in those words; or 04-15 passes `LINGER=604800` *and* the empty-set path is a fifth control that must still be alive at 60 s.

- **HIGH — 04-14 Task 2 `<verify>` vs `<acceptance_criteria>`.** The verify gates `SC-2 STATUS=FAIL` and `SC-3 STATUS=UNPROVEN` only. It does not read `SC-1 STATUS=BYTES-OK`, `files_in_both=2`, or `SC-4 STATUS=READONLY-OK`. An always-FAIL judge (or SC-1 created before `START_INCOMPLETE` is recorded, so the folder is excluded) still passes the gate. 04-15 then spends the real job on an instrument that cannot return `BYTES-OK`. The action calls this verify “the gate that stops a failing instrument”; it is not. New instance of “`<verify>` passes when the instrument fails,” now on the *positive* path. *Refutation:* add `grep -qE '^SC-1 STATUS=BYTES-OK '` (and `files_in_both=2`, `changed=0`) to the verify; a run that then still exits 0 with SC-1 ≠ `BYTES-OK` refutes this.

- **MEDIUM — 04-14 Task 1 judge spec, read 129.** `FAIL` = completion-only audio matching no PRE file; `UNPROVEN` = no attributed `pre.sha256`. No precedence. A late-start job (SC-3, and any real job the watcher missed) is *both*. FAIL-first turns “could not look” into “estate rewrote bytes” — invariant 1’s mirror — and 04-16 would write `criterion 3 FAIL`. SC-3 currently stops that *if* the executor does not “fix” the expected token. *Refutation:* the script header states UNPROVEN short-circuits FAIL, and SC-3’s raw judge line is `STATUS=UNPROVEN` with completion files present.

- **MEDIUM — 04-14 Task 2 action, “29 names” (line 161).** § 4 / 04-01-SUMMARY list **30** columns (`id` … `time_added`). Off-by-one while hand-building `fx-hist.db`. Watcher only refuses if `storage` or `path` is missing, so this is a rework risk, not a silent pass. *Refutation:* `PRAGMA table_info` on the live DB returns 29, or the fixture is built from that PRAGMA rather than the plan’s count.

- **MEDIUM — 04-15 Task 1 `<verify>` (line 157).** Does not check (a) 04-14 amendment is an ancestor with committer date `<` stamp, (b) script sha256 equals `04-14-SUMMARY.md`, (c) `START_INCOMPLETE` entry count equals the pre-state (the `-s -o -f` form passes on an empty file). 04-14’s whole point can be skipped and the verify still prints `ARMED`. Empty `START_INCOMPLETE` also samples the 6 January orphans. *Refutation:* those three asserts are in the verify and a run with a hash mismatch or empty `START_INCOMPLETE` exits non-zero.

- **MEDIUM — 04-15 Task 3 acceptance vs window 1’s two jobs.** Residual-line acceptance is “exactly +1 / +1 / +0 **for the job**.” Window 1 produced two jobs 14 s apart from one Lidarr search. A second in-window job makes +2 and has no verdict rule (one `BYTES-OK` + one `UNPROVEN`? either `FAIL`?). *Refutation:* the plan states “one valid `BYTES-OK` job is sufficient for PASS; any `FAIL` is FAIL; +1 residual lines *per job*.”

- **MEDIUM — 04-14 Task 3 `<verify>` (line 264).** Does not assert `git diff --numstat` is 0 deletions or that the window-1 `Verdict:` line is byte-identical. Additive-only is acceptance-only. *Refutation:* the verify includes `test "$(git diff HEAD~1 --numstat -- "$f" | awk '{print $2}')" = 0`.

- **MEDIUM — 04-15 Task 1 launch vs 04-14 watcher.** Neither requires `mkdir -p "$OUT"` before `watch.pid`. 04-15 only `mkdir -p …/15`. First write can fail under `set -e`, watcher dies, `kill -0` fails — fail-closed, but a wasted arming cycle. *Refutation:* watcher or launcher creates `$OUT` and Task 1 verify still sees a live PID.

- **LOW — 04-14 Task 1 `<verify>`.** `grep -c STAMP_EPOCH` does not prove “no default / refuses unset.” `grep -cE 'BYTES-OK|UNPROVEN|FAIL' -ge 3` can pass on three `FAIL`s. `MUSIC_DIR:-` is acceptance-only.

- **LOW — 04-14 Task 2 `<verify>`.** The `ps` dump is written, checked non-empty, deleted — never matched against the watcher. T-04-14-05 claims liveness is in the verify; it is not. `selftest-14.txt` is never read by 04-15 (only deleted).

- **LOW — 04-14 Task 3 screening vs hashes.** “0 runs of 40+ characters” forbids the 64-hex sha256s the amendment must name. Precedent: this file already carries `54c5433b…`. Carve hex hashes out of the screen.

- **LOW — 04-14 Task 3 acceptance `grep -c 'OPEN, not passed'` over § 5.** That contiguous string is **not** in § 5 today (`**OPEN**, not` / newline / `passed.`). Count is 0. Restating the four rules in the blockquote will *change* it if the phrase is copied. Lock something that actually exists, or count only the original bullets.

- **LOW — 04-15 Task 3 pointer above § 6’s `Verdict:`.** If the pointer itself matches `^Verdict: (PASS|OPEN|FAIL)`, invariant 9 becomes 2 and 04-15/04-16 verify fail (fail-closed). Specify it must not.

- **LOW — 04-16 Task 1 `<verify>` vs acceptance.** PASS acceptance wants `grep -cE '^## Phase 4 — interim status' = 0`; verify’s `I` only counts headings that already say `criterion 3 (OPEN|FAIL)`. Criterion-table row 3 and `window 2` are acceptance-only. Task 2 verify never runs `check-music-freeze.sh` (QHC fold-in may cover it; still not the named command).

- **LOW — 04-15 Task 3 `grep -ci 'mtime'` inside § 7.** A “file mtimes are never used as provenance” sentence fails the criterion. Allow that disclaimer.

## 4. Suggestions

Minimal edits only:

1. **04-14 line 126:** “Exit only after **≥1** history row has `post.sha256` and `LINGER` seconds have elapsed since that row; with zero rows, stay up until `SIGTERM` or the outer timeout.” Add an SC-5: start watcher, sleep 60, still alive, no `map.tsv` rows.
2. **04-15 Task 1 launch:** pass `LINGER=604800` (or omit auto-exit) so the inner default cannot undercut the 7-day window.
3. **04-14 Task 2 verify:** add
   `grep -qE '^SC-1 STATUS=BYTES-OK ' && grep -qE '^SC-1 .*files_in_both=2 ' && grep -qE '^SC-1 .*changed=0 '`
   and `grep -qE '^SC-4 STATUS=READONLY-OK '`. Require `SC-1` created *after* `START_INCOMPLETE` is written.
4. **04-14 judge:** “If no attributed `pre.sha256` (token `none`, or file missing), emit `UNPROVEN` and do not apply the completion-only FAIL rule.” Compare hashes relative to the job folder, not absolute `sha256sum` paths.
5. **04-15 Task 1 verify:** `sha256sum` both scripts vs the two SUMMARY hashes; `git merge-base --is-ancestor <04-14-amendment> HEAD`; `wc -l START_INCOMPLETE` equals the recorded incomplete-dir count (drop `-o -f`).
6. **04-15 Task 3:** one valid `BYTES-OK` job is enough for PASS; any job `FAIL` is FAIL; residual-line deltas are per job. Pointer line must not match `^Verdict:`.
7. **04-14 Task 2:** build `fx-hist.db` from live `PRAGMA table_info(history)`, not “29 names.” `mkdir -p "$OUT"` in the watcher. `${STAMP_EPOCH:?}` not `${VAR:-default}` for that one input. Hex sha256s are exempt from the 40-char screen.

## 5. Risk Assessment

**MEDIUM** to execute as written — **HIGH** if 04-15 is armed before (1) and (3) are fixed.

The estate is not at risk (read-only, scratch-only, no API). The scarce real job is. LINGER-on-empty-set plus an ungated positive control are the two ways this round repeats 04-12: a complete-looking window whose one load-bearing measurement is UNPROVEN, or worse, FAIL. The rest is verify-vs-acceptance hygiene this phase already knows how to patch. Do not treat a confident HIGH here as optional: both are in the plan text, neither needs a live-estate measurement to grade.

---

## Copilot Review (gpt-5.4)

## Summary

These three plans are **not quite fit to execute as written**. The core design change in 04-14 is the right one — moving PRE-HOOK capture into `downloads/incomplete` and proving FAIL/UNPROVEN before spending a real job — but 04-15 and 04-16 still leave three blocking enforcement gaps: a no-job OPEN path that does not actually read SAB history, a machine-check that validates only the Phase 4 heading while leaving the criterion-3 table row unchecked, and a final guard verify that can pass without proving the host-side freeze check ran against the landed text. Those are small text fixes, not a re-plan, but I would fix them before execution.

## Strengths

- **04-14’s structural ordering fix is sound.** Replacing “earlier than a second-resolution log line” with “captured while the folder still exists under `incomplete/`” directly addresses the measured defect from 04-12 instead of racing it again.
- **The self-test design is materially better than window 1.** Requiring both a synthetic **FAIL** and a synthetic **UNPROVEN** before arming 04-15 is exactly the right response to the phase’s known failure mode.
- **04-16 keeps the right discipline at the headline level.** Selecting the Phase 4 heading from a machine-readable verdict line is the correct shape and preserves the “outcome, not goal” invariant.

## Concerns

- **HIGH — 04-15 Task 3, `<action>`, branch `If the reply was "window closed"`**  
  **Mechanism:** this branch writes `Verdict (window 2): OPEN — no music job arrived ...` after checking only the close-side `extended.conf` condition. It skips Task 3 read 1 entirely, so “no job arrived” is inferred from the operator reply rather than measured from `history1.db`. Because the watcher can stay up for 7 days and organic `music` jobs can appear, this can record **OPEN/no-job** even when a post-stamp music row actually exists. That is exactly the “prose requires it, nothing enforces it” defect class.  
  **Refutation condition:** this finding is wrong if the plan already requires an unconditional `SELECT ... FROM history WHERE category='music' AND completed > <stamp>` before taking the no-job branch, or if the no-job wording is gated on that query returning zero rows. As written, it is not.

- **HIGH — 04-16 Task 1, `<verify>`**  
  **Mechanism:** the verify enforces only the **heading mapping** (`PASS` → closure heading, `OPEN/FAIL` → interim heading). It does **not** verify the other output the task explicitly requires: that criterion-table row 3 quotes the **window-2 verdict word** and updates the source cell to `04-12, 04-14, 04-15, \`04-D12-EVIDENCE.md\``. A stale row 3 can therefore survive under a correct heading, leaving `beets.md` internally contradictory while the verify still prints `MAP-OK(...)`. This is a direct new instance of the acceptance-criterion/verify mismatch you asked reviewers to hunt.  
  **Refutation condition:** this finding is wrong if some verify in 04-16 already greps row 3 for the window-2 verdict word and the `04-12, 04-14, 04-15` source list. The current `<verify>` does not.

- **HIGH — 04-16 Task 2, `<verify>`**  
  **Mechanism:** the verify only proves three things: local `audio.bash` still has zero `beet` lines, workstation `quick-health-check.sh` exited 0, and that captured output contains `vendored files match (3)`. It does **not** prove the task’s explicit host-side requirement: that `check-music-freeze.sh` was run on LXC 100 **against a host checkout asserted to contain Task 1’s commit**. That matters here because Task 2 itself cites 04-13 deviation 1 as the reason to assert the host checkout. As written, `SUITE-OK` can pass while the plan never establishes that the host-side standing guard executed the landed text rather than a stale checkout.  
  **Refutation condition:** this finding is wrong if the verify already includes a remote assertion of the host commit and a direct remote `check-music-freeze.sh` success condition such as `FAILURES total: 0`. It does not.

- **MEDIUM — 04-14 Task 2, SC-4 READ-ONLY control**  
  **Mechanism:** SC-4 says “before SC-1 starts, record `sha256sum` of every fixture audio file”, but the fixture audio files are created inside SC-1/SC-2/SC-3. Unless they are pre-created first — which the plan never says — there is no true before/after hash baseline for the files the watcher is supposed to prove it left untouched. The second half is also self-contradictory: it says the only paths newer than the marker are the ones the controls created or mutated, then says “no path under `$OUT`’s parent outside the three `out-<control>` directories was written”, even though the controls themselves write `fixtures/` and `fx-hist.db` under that same parent.  
  **Refutation condition:** this finding is wrong if the plan already pre-creates all fixture audio files before the baseline and narrows the write-scope assertion to watcher-owned outputs rather than every path under `/mnt/fast/scratch-04/14`. As written, it does neither.

- **MEDIUM — 04-15 Task 2 → Task 3 seam on “one job”**  
  **Mechanism:** Task 2 asks the operator for the approximate finish time of **one** job, but Task 3 queries **all** `category='music'` rows after the stamp and tells the judge to record results “per job”. There is no rule for selecting the authoritative row if a second organic/parallel music job lands before cleanup. That leaves two outputs underspecified: the `Audio.txt` delta requirement of exactly `+1 / +1 / +0`, and the verdict when one row is `BYTES-OK` and another is `FAIL` or `UNPROVEN`. The plan assumes singularity in prose but never enforces it mechanically.  
  **Refutation condition:** this finding is wrong if the plan already binds the evidence to exactly one row — for example, the row nearest the operator-reported time, or the first post-stamp row with the window immediately closed afterward — and treats any extras as out-of-scope or separately recorded. It does not.

- **MEDIUM — 04-14 Task 2, first paragraph (“apply the S5 containment fence ... `realpath -e` both the target and the fixture root”)**  
  **Mechanism:** the task says to apply the fence **before any write**, but new targets such as `/mnt/fast/scratch-04/14/fixtures/fx-incomplete` do not exist yet, so `realpath -e` on the target fails on the very first creation step. The cited live S5 implementation in `scripts/spike03-wrtag-arms.sh` avoids this by resolving non-existent paths (`realpath -m` with a fallback), so the prose here is stricter than the referenced mechanism and can block execution unnecessarily.  
  **Refutation condition:** this finding is wrong if all fenced targets are guaranteed to exist before the check, or if the intended instruction is actually to resolve the existing parent/root rather than the not-yet-created leaf. The current text says `realpath -e` on the target.

## Suggestions

1. **04-15 Task 3:** move the SAB history query ahead of the `"window closed"` branch and make `OPEN — no music job arrived` legal only when that query returns zero post-stamp `music` rows.
2. **04-15 Task 3:** explicitly bind window 2 to **one** history row — easiest is “the row whose `completed` time is nearest the operator-reported finish time” — and say how additional post-stamp music rows are handled.
3. **04-16 Task 1 `<verify>`:** add a grep/assertion for criterion-table row 3 so it must contain the window-2 verdict word and the source cell `04-12, 04-14, 04-15`.
4. **04-16 Task 2 `<verify>`:** add a remote check that the host checkout contains Task 1’s commit, then run `bash scripts/check-music-freeze.sh` on LXC 100 and assert `FAILURES total: 0`.
5. **04-14 Task 2 SC-4:** either pre-create the fixture audio files before the baseline or restate SC-4 as a narrower claim about watcher-owned writes only; the current before/after hash proof is not well-formed.
6. **04-14 Task 2 fence wording:** replace `realpath -e` on the target with the same non-existent-path-safe resolution the cited S5 fence actually uses, or fence an existing parent directory instead.

## Risk Assessment

**HIGH.** The instrument redesign itself is good, but the execution/closure plans still have false-outcome paths: 04-15 can declare “no job arrived” without looking, and 04-16 can validate the heading while missing a stale criterion row or a stale host-side guard run. Those are exactly the kinds of defects this project has already paid revision cycles for. Fixing them is straightforward, but until they are fixed I would treat execution as high-risk for producing a formally clean yet mechanically under-proven closeout.


---

## Copilot Review (gpt-6-astra)

## 1. Summary

**These plans are not yet fit to execute against another scarce real job.** The scope and evidence discipline are sound, and the principal artifact paths line up correctly. However, the replacement watcher still lacks a mechanically sufficient proof that its snapshot is both pre-move and complete. Several verification gates also accept outcomes that their acceptance criteria expressly forbid. The most important fixes are to establish snapshot validity independently of delayed polling timestamps, exercise acquisition races, and make the self-test and verdict gates reject unsupported success. These are findings about the **planned instrument**, not claims that the estate is dirty.

## 2. Strengths

- Amending the contract before opening another window, preserving window 1, and separating the byte judge from the overall verdict are good choices.
- Mutation and missing-baseline controls directly address the previous instrument’s weaknesses.
- The named artifact paths are consistent: the two scripts and `selftest-14.txt` survive removal of `/14`; `/15` uses the same script names; 04-16 reads durable evidence rather than deleted scratch.
- 04-16’s heading mapping correctly distinguishes PASS from OPEN/FAIL for well-formed input. API avoidance, hashed job identities, and tag-key-only reporting also remain appropriate.

## 3. Concerns

- **C1 — HIGH: `pre.time < vanished.time` does not establish the claimed structural ordering.** **04-14 Task 1, hashing/disappearance behavior and judge; Task 3, amendment item 3; 04-15 Task 3, read 6.** `vanished.time` is when a later poll *observes* absence, not when the move occurred. A hash read can straddle the move: an already-open file descriptor remains usable after a rename, and the hook can run before hashing finishes. A snapshot completed after the hook can therefore still precede the next absence poll and satisfy the proposed validity rule. The specification requires neither a post-hash source-identity check nor rejection of a hash pass overlapping disappearance. This remains a defect even granting the plan’s assumption about SAB’s folder-move ordering. **Refutation condition:** show that publication of a valid snapshot requires the complete hash pass to finish while the same source directory/files remain at their incomplete paths, and demonstrate a move-during-hash control producing UNPROVEN rather than BYTES-OK.

- **C2 — HIGH: “last stable” is not necessarily “final after unpack,” so ordinary acquisition can become an estate FAIL.** **04-14 Task 1, stable-set retention; Task 2, SC-1/SC-2; 04-15 Task 3, read 6; 04-16 Task 1, FAIL interpretation.** Suppose two files stabilize and are hashed, then a third finishes extracting immediately before SAB moves the job. The retained snapshot contains two files, completion contains three, and the judge reports FAIL despite no hook writer running. An existing file changing before the move gives the equivalent false `changed=1` result. No rule invalidates an older snapshot when a newer unstable set is observed, and no evidence establishes a guaranteed final-audio residence time sufficient for two polls plus hashing. The fixtures avoid this problem by deliberately waiting before `mv`. **Refutation condition:** establish the complete, immutable pre-move audio set from the installed SAB execution path, or demonstrate controls in which late extraction/pre-move mutation invalidates the baseline rather than being attributed to the hook. I am not asserting that either scenario occurred in window 1.

- **C3 — HIGH: the byte judge permits a vacuous BYTES-OK result.** **04-14 Task 1, judge status definitions; Task 2, control coverage; 04-15 Task 3, read 6.** With an attributed two-file PRE manifest and a zero-entry COMPLETION manifest, every PRE file is simply `pre_only`; those deletions are explicitly exempted. There are no changed files or completion-only files, so the specified rules allow BYTES-OK with **zero compared audio files**. The specification also lacks explicit completeness requirements for both manifest reads and a defined disposition for missing, truncated, or unreadable completion evidence. Existing controls cover missing PRE, not failed COMPLETION acquisition. **Refutation condition:** require successfully acquired, fully parsed manifests and a nonzero byte-comparison positive control, with missing/partial/empty completion evidence driven to UNPROVEN or an explicit instrument error—not BYTES-OK.

- **C4 — HIGH: the four-control gate actually gates only two controls.** **04-14 Task 2, `<verify>` and self-test record construction.** The verifier counts four `SC-` lines but checks only SC-2’s FAIL/`changed=1` and SC-3’s UNPROVEN/missing-PRE fields. It accepts SC-1 returning FAIL and SC-4 reporting `READONLY-FAIL fixtures_identical=0/2 watch_err_bytes=100`. Duplicate SC-2/SC-3 rows can also satisfy the four-line count without SC-1 or SC-4 existing. Only status fields are explicitly extracted from observed judge output; the other asserted counters lack that same provenance requirement. Thus a watcher that cannot produce a positive measurement—or fails its read-only control—can pass the declared gate. **Refutation condition:** the gate rejects those records, requires exactly one of each control, and checks observed counters, ordering, read-only results, and each error-log byte count.

- **C5 — HIGH: the final evidence verifier accepts an unsupported PASS and immediately destroys its supporting material.** **04-15 Task 3, `<verify>` and cleanup; 04-16 Task 1, downstream mapping.** The verifier checks verdict-line counts, the section heading, and scratch absence. It does not check that a PASS has a BYTES-OK job, valid timestamps, successful producers, unchanged `extended.conf`, or satisfied side-effect conditions. A section containing `Verdict (window 2): PASS` alongside `STATUS=UNPROVEN` can satisfy it. This is a new instance of the prior review’s **acceptance condition existing only in prose**. 04-16 then faithfully turns that unsupported verdict into a closure heading. Cleanup removes the raw material before this gate runs. **Refutation condition:** demonstrate that the final gate rejects PASS when any required input is UNKNOWN, missing, invalid, or contradictory, using retained machine-readable observations before cleanup.

- **C6 — MEDIUM: the 04-14 → 04-15 provenance handoff is named but not mechanically enforced.** **04-14 Task 3, `<verify>`; 04-15 Task 1, action and `<verify>`.** The arming action requires exact script hashes and an amendment ancestor/date check, but its verifier checks neither. It does not read `selftest-14.txt` at all. The amendment verifier merely prints the latest touching commit; it does not establish the named amendment commit, additive-only changes, or unchanged window-1 verdict bytes. Consequently, the arming gate can say ARMED for different script bytes or an unestablished contract provenance chain. **Refutation condition:** changing either script hash, removing the self-test record, or failing the amendment ancestry/time comparison must make the pre-launch gate fail.

- **C7 — MEDIUM: legitimate OPEN and FAIL outcomes cannot satisfy several unconditional acceptance criteria.** **04-15 Task 3, acceptance criteria; 04-16 Task 2, action and acceptance criteria.** The required Audio.txt delta is unconditionally `+1/+1/+0`: a no-job OPEN has no residual lines, while a FAIL caused by a success line necessarily violates `+0`. Every FAIL is also required to identify a file position and both hashes, which does not apply to a log or database-artifact failure. Finally, a FAIL caused by regenerated beets state can correctly make the standing guards red, but 04-16 requires their exit codes to be zero. These branches need deviations merely to record honest results. **Refutation condition:** outcome-specific acceptance branches allow no-job OPEN, side-effect FAIL, and the corresponding nonzero guard results to complete without changing or concealing the observations.

- **C8 — MEDIUM: the “window closed” branch asserts an absence without measuring it.** **04-15 Task 3, early branch before read 1.** It writes “no music job arrived” and skips directly to cleanup based on the operator’s reply. An organic job may have completed unnoticed or between that reply and collection. The branch never queries history to distinguish zero jobs from an unreadable database or an uncollected job, and can discard evidence that should have been evaluated. This is a new instance of invariant 1’s absence-without-positive-control problem. **Refutation condition:** a successful, bounded history query showing zero qualifying rows is required before taking this branch; otherwise collection runs, or OPEN records inability to read rather than asserting no arrivals.

- **C9 — MEDIUM: cleanup cannot follow its stated fence and ordering literally.** **04-14 Task 2, `<verify>`; 04-15 Task 3, cleanup.** The former executes `rm -f /mnt/fast/scratch-04/.ps-probe-14` without the mandated `realpath -e` fence. The latter fences deletion to `/15`, then instructs deletion of three files outside that root “in the same pass.” It subsequently removes the parent and only then asks for pattern and `ps` snapshot files—although the only permitted host write area has just been removed. Its automated verifier proves directory absence, not watcher absence. **Refutation condition:** the cleanup sequence explicitly resolves and allow-lists the three parent-level files, completes the process proof while scratch still exists, and fences every deletion, including the probe.

- **C10 — MEDIUM: the long-string screen contradicts required evidence.** **04-14 Task 3, amendment item 5 and screening; 04-15 Task 3, evidence table and screening.** The amendment must contain both script sha256 values, and window-2 evidence must contain `extended.conf` hashes—and, on byte failure, both file hashes. Each is 64 hexadecimal characters. An unconditional requirement for zero runs of 40+ characters therefore rejects evidence these same tasks mandate. **Refutation condition:** the screen explicitly distinguishes allow-listed digest fields from prohibited secret-like strings, rather than requiring zero long runs.

- **C11 — MEDIUM: the final host-checkout requirement conflicts with this read-only phase.** **04-16 Task 2, `check-music-freeze.sh` prerequisite.** It requires the host checkout to contain Task 1’s newly created documentation commit. Pushing that commit does not update the host checkout. If the host lacks it, the executor must either stop or update estate files outside scratch; the latter violates the stated scope. The documentation-only commit does not change the guard being executed. **Refutation condition:** establish an already-satisfied, read-only route to that prerequisite, or bind the run to the relevant existing guard-script versions instead of the newly written documentation commit.

## 4. Suggestions

Make these focused changes before executing 04-14:

1. **Strengthen snapshot eligibility, not just its timestamp definition.** Require complete manifest acquisition, post-hash source-identity checks, and evidence that the selected baseline represents final audio. Treat an unestablished baseline as UNPROVEN. Add move-during-hash, late-extraction, pre-move-mutation, and failed/empty-completion controls.

2. **Replace the self-test greps with exact record validation.** Require one SC-1 through SC-4, observed—not expected—numeric fields, positive comparison counts, valid ordering, and independently measured read-only/error-log results. Clarify that SC-4’s status comes from its own assertions, not the byte judge’s three-token vocabulary.

3. **Make arming a single fail-closed prerequisite gate.** Validate the self-test receipt, both script hashes, amendment identity/ancestry, and amendment-before-stamp ordering before launching the watcher.

4. **Validate the verdict against structured observations before cleanup.** Explicitly map established violations to FAIL, missing/UNKNOWN evidence to OPEN, and fully satisfied conditions to PASS. Exercise that aggregation with contradictory inputs.

5. **Make acceptance criteria branch on the actual outcome.** Require residual-line deltas only where applicable; require hashes only for byte failures; record rather than suppress guard failures accompanying a FAIL. Query history before declaring a no-job window.

6. **Repair cleanup and documentation checks.** Perform process proofs before deletion, use explicit containment scopes for parent-level artifacts, allow-list documented hashes, and check the necessary guard versions without updating the host checkout.

7. **Tighten the durable-record format checks.** Compare window 1’s verdict bytes against the preserved version, not just its count. Require a delimiter after the verdict token: the current regex parses `Verdict (window 2): PASSING` as PASS. Also assert that beets.md’s criterion-3 row matches the selected window-2 verdict.

## 5. Risk Assessment

**HIGH as written.** The principal risk is another unprovable observation—or an incorrectly attributed byte failure—because the synthetic fixtures do not establish the real acquisition boundary the replacement relies on. Incomplete self-test and verdict gates can then turn that defect into apparently completed evidence and a durable closure heading. Fixing those boundaries and gates does not require reopening the tagger decision, changing the estate, or revisiting criteria 1, 2, 4, and 5.


---

## Consensus Summary

Twenty-plus distinct findings, graded. **No reviewer asks for the engine, the retirement scope, the
estate or any verified criterion to be reopened** — every finding is a fix to the three plans' text.
All four independently reach the same shape of conclusion: the *design* change in 04-14 (structural
ordering via the incomplete tree) is right, and the *gates* around it are not yet strong enough to
spend a scarce real job on.

### Blocking findings (graded HIGH)

| # | Finding | Raised by | Verdict | Grading evidence |
|---|---|---|---|---|
| 1 | **The watcher exits ~5 minutes after arming on an empty window.** 04-14's exit rule is "when every history row seen has a `post.sha256` and `LINGER` seconds have elapsed since the last row". `LINGER` defaults to **300**. With zero rows the first clause is **vacuously true**, so a literal implementation exits at ~5 minutes. 04-15 launches with `STAMP_EPOCH` and `OUT` only — it never overrides `LINGER`; the 7-day bound is just the outer `timeout 604800`. The operator then waits 1–5 days at the Task 2 checkpoint with a dead watcher, and the one real job is spent producing UNPROVEN | **Grok H1** (alone) | **CONFIRMED** | `LINGER` (default 300) at 04-14:115; exit rule verbatim at 04-14:126; `grep` of 04-15's launch line for `LINGER` → **0**. All three self-test controls insert a history row, so the empty-window path is **never driven** by the self-test that exists to catch exactly this | 
| 2 | **"Last stable" is not guaranteed to be "final after unpack" — and the failure mode is a FALSE FAIL, not UNPROVEN.** If a lull leaves a *subset* of audio files stable and hashed, the later-extracted files appear only at COMPLETION. The judge's own rule makes "a COMPLETION-only audio file matching no PRE-HOOK file" a **FAIL**. The contract scoped that rule to `clean()` flattening; 04-14 Task 3's amendment (items 1–5) redefines *where* the snapshot is taken and **never revisits it**. 04-16 would then write a false FAIL up as "a real finding about the estate requiring a follow-up phase decision" | **Gemini H1**, **astra C2**, **Grok M** (judge precedence), + orchestrator measurement — **four-way convergence from four directions** | **CONFIRMED (as risk)** | Measured on the live estate, not adjudicated from text: `direct_unpack = 1` (audio extracts *during* download); `incomplete` and `complete` are the **same ZFS dataset** (`tank/downloads`, device 68 both) so SAB's move is an instant rename; music `postproc_time` is **1–3 s** on recent jobs, and only **35 of 121** rows reach the 4 s two consecutive 2 s polls require. `grep -c 'COMPLETION-only'` in 04-14 → 1 (the judge spec), and Task 3's amendment items never touch it |
| 3 | **The "four-control gate" gates two controls.** Task 2's `<verify>` asserts only SC-2 (`FAIL`, `changed=1`) and SC-3 (`UNPROVEN`, `pre_sha256=absent`). It never reads `SC-1 STATUS=BYTES-OK` or `SC-4 STATUS=READONLY-OK`. An instrument that can **never return BYTES-OK**, or that fails its own read-only control, passes the gate the action calls "the gate that stops a failing instrument". The `grep -c "^SC-"` = 4 count is also satisfiable by duplicate SC-2/SC-3 rows | **astra C4**, **Grok H2** — independent convergence | **CONFIRMED** | Extracted every `SC-` clause from the verify at 04-14:189: five clauses, **all** SC-2 or SC-3. No SC-1 or SC-4 assertion exists |
| 4 | **The final evidence verify accepts an unsupported PASS, and cleanup then destroys the material that would disprove it.** 04-15 Task 3's `<verify>` checks verdict-line counts, the § 7 heading and scratch absence. It does not check that a PASS has a `BYTES-OK` job, valid ordering, successful producers, or unchanged `extended.conf`. A § 7 carrying `Verdict (window 2): PASS` beside `STATUS=UNPROVEN` satisfies it — and 04-16 faithfully converts that into a closure heading | **astra C5** | **CONFIRMED** | 04-15:305 verify text; 04-16:116 consumes the verdict word with no independent support check. This is round 1 row 6's defect class (closure over a non-PASS) reappearing one layer up |

### Confirmed, non-blocking (MEDIUM)

| # | Finding | Raised by | Verdict | Note |
|---|---|---|---|---|
| 5 | **Vacuous `BYTES-OK` on an empty COMPLETION manifest.** "every file present in both snapshots is sha256-equal" is vacuously true on an empty intersection; PRE-only files are explicitly exempt. Zero compared files → `BYTES-OK` | astra C3 | **CONFIRMED** | No nonzero floor anywhere in 04-14 (`grep` for a minimum on `files_in_both` → 0 matches) |
| 6 | **"Window closed" asserts an absence without measuring it.** The branch writes `OPEN — no music job arrived` from the operator's reply and skips to cleanup, never querying history — so it cannot distinguish zero jobs from an unread database, and can discard a job the watcher actually captured | gpt-5.4 H1, astra C8 — convergence | **CONFIRMED** | 04-15:216-218 verbatim. Invariant 1's own defect class |
| 7 | **The watcher-absence proof is never executed.** Both plans' acceptance criteria demand a self-match-proof process check. 04-14 Task 2's verify captures `ps` to `.ps-probe-14`, asserts it non-empty, and `rm -f`s it — **never matching it against the watcher**. 04-15 Task 3's verify has no process assertion at all. `T-04-14-05` claims liveness is enforced in the verify; it is not | Gemini H2, Grok LOW | **CONFIRMED** | Every `ps`/`grep` clause in 04-14:189 extracted — capture, non-empty test, delete. No match step |
| 8 | **Two jobs in one window is unhandled.** Task 2 asks the operator about **one** job; Task 3 queries **all** post-stamp music rows and records "per job". The `Audio.txt` delta criterion is unconditional `+1/+1/+0`, and there is no rule for a verdict when one row is `BYTES-OK` and another `UNPROVEN` or `FAIL` | gpt-5.4 M2, astra C7, Grok M | **CONFIRMED** | Not hypothetical: **window 1 produced two jobs 14 seconds apart** from a single Lidarr search |
| 9 | **04-15's arming verify asserts none of the three preconditions its action requires** — script sha256 equality, amendment ancestry/date, and `START_INCOMPLETE` count. Worse, `test -s FILE -o -f FILE` is inert: the `-f` disjunct passes on an **empty** file, so the 6 stale January orphan directories would be tracked as live jobs | Grok M | **CONFIRMED** | 04-15:157 verbatim: `test -s …/START_INCOMPLETE -o -f …/START_INCOMPLETE` |
| 10 | **SC-4's read-only baseline is taken before the files it baselines exist.** "Before SC-1 starts, record `sha256sum` of every fixture audio file" — but the fixtures are created inside SC-1/2/3. The write-scope half is also self-contradictory: it forbids writes under `$OUT`'s parent while the controls write `fixtures/` and `fx-hist.db` there | gpt-5.4 M1 | **CONFIRMED** | 04-14 Task 2, SC-4 vs SC-1 ordering |
| 11 | **The fence is misquoted as `realpath -e`**, which fails on not-yet-created fixture paths. The cited live implementation deliberately uses `realpath -m` | gpt-5.4 M3 | **CONFIRMED** | `scripts/spike03-wrtag-arms.sh:247-255`: "`-m` resolves components that do not exist yet", implemented as `realpath -m -- "$path"`. 04-15's deletion-time `realpath -e` is **correct** and is not part of this finding |
| 12 | **The screen forbids the evidence the same plans mandate.** 04-14 Task 3 item 5 requires naming both scripts by sha256 (64 hex characters) while screening added lines for "0 runs of 40 or more characters" | astra C10, Grok LOW | **CONFIRMED** | `04-D12-EVIDENCE.md` already carries **4** such runs (`fdcddca234b2…`, `54c5433bba38…` ×3) — the screen as worded would flag its own existing content |
| 13 | **`/mnt/fast/scratch-04` does not exist, and 04-14 never creates it.** Task 1 `scp`s to `/mnt/fast/scratch-04/watch-d12b.sh`; Task 2 builds `…/14/fixtures`. 04-14 contains **no `mkdir` at all**. Nor does anything create `$OUT` before the watcher writes `watch.pid` | **orchestrator** (live check) + Grok M (`$OUT` half) | **CONFIRMED** | `ls /mnt/fast/scratch-04` → "No such file or directory" (positive control: `/mnt/fast` present). 04-12 created it explicitly; 04-15 runs `mkdir -p …/15`. 04-14 is the only plan that writes there without creating it |
| 14 | **`fx-hist.db` is specified with the wrong column count** — "the 29 names" | Grok M | **CONFIRMED** | Live `PRAGMA table_info(history)` returns **30** columns. Grok's own refutation condition ("returns 29") is **not** met. Build the fixture from the live PRAGMA rather than a transcribed count |
| 15 | **04-14 Task 3's verify does not enforce additive-only.** "0 lines deleted" and "window-1 verdict byte-identical" are acceptance-only; the verify merely prints the latest commit touching the file | Grok M, astra C6 | **CONFIRMED** | 04-14:264 |
| 16 | **04-16 Task 1's verify enforces the heading but not the criterion-3 row.** A stale row 3 survives under a correct heading, leaving `beets.md` self-contradictory while the verify prints `MAP-OK` | gpt-5.4 H2 | **CONFIRMED**, severity lowered to MEDIUM | The heading — the part that could misrepresent closure — *is* mechanically enforced. A stale row is an internal inconsistency, not a false closure claim |

### LOW

- **Unanchored window-2 grep** (Gemini L1) — **CONFIRMED.** 04-14 Task 3's verify uses `grep -c 'Verdict (window 2)'` = 0, while 04-15 and 04-16 use the anchored `^Verdict \(window 2\): (PASS|OPEN|FAIL)`. Prose in the § 5 amendment mentioning the phrase would fail a correct execution. Anchor it.
- **`grep -c 'OPEN, not passed'` locks nothing** (Grok) — **CONFIRMED.** That contiguous string appears **0** times in the contract today; § 5 line-wraps as `**OPEN**, not` / `passed.`. The criterion "unchanged from before the edit" is satisfied by 0 = 0 and guards nothing.
- **`Verdict (window 2): PASSING` parses as PASS** (astra) — **CONFIRMED** as latent: `grep -oE '…(PASS|OPEN|FAIL)'` matches the prefix and `awk '{print $NF}'` yields `PASS`. Low likelihood (04-15 writes the line) but free to fix with a trailing delimiter.
- **`grep -ci 'mtime'` within § 7** (Grok) — the criterion limits `mtime` mentions to the `extended.conf` rows, yet the action mandates a "file mtimes are never used as provenance" disclaimer, which would violate it.

### Downgraded on grading — recorded so they are not re-raised as blockers

- **gpt-5.4 H3, "04-16's guard never runs host-side" → MEDIUM.** `quick-health-check.sh` **does** fold in `check-music-freeze.sh` over ssh (`scripts/quick-health-check.sh:697`), so the host-side guard genuinely runs. Only the narrower half stands: the verify never asserts the host checkout contains Task 1's commit.
- **astra C11, "the host-checkout requirement violates read-only scope" → LOW.** 04-16:147-148 explicitly contemplates pushing and a host pull, citing 04-13's precedent, so the executor is not forced to choose between stopping and a scope violation. The valid narrow half: coupling a docs-only commit to a guard run is gratuitous.
- **Gemini's H1 framing, calibrated.** Gemini asserts the watcher can **never** capture a stable state. The measurement does not support the absolute: **35 of 121** music jobs had `postproc_time` ≥ 4 s. Recorded as finding 2 in astra's better-calibrated form — the residence time is **not established**, so the baseline may be a subset — rather than as proven impossibility.

### Orchestrator's own leads, discarded before they became findings

- **"`audio.bash:334` runs `chmod 777` but the file says `chmod 666`."** Discarded. The contract measured the **pre-strip** 339-line file; removing the beet line shifted every later number by one. Live: 333 is `chmod 777`, 334 is `chmod 666`. The contract is right.
- **"Two watcher processes are still running from window 1."** Discarded. The first check's own ssh command line contained the search string and `ps` captured it — the exact self-match trap 04-12 deviation 6 documents. Re-run with a pattern built by concatenation plus two positive controls (731 `ps` lines, 5 `sshd`): **0**.

### Agreed strengths

- **The structural-ordering fix is the right change** (all four). Replacing "earlier than a second-resolution log line" with "captured while the folder is still under `incomplete/`" attacks the measured defect instead of racing it again, and design (b) is rejected on job A's measured 12:18:00.074Z vs 12:17:59Z rather than on taste.
- **Amending the contract before the window opens**, additively, with window 1's record left standing, is correct and was noticed by every reviewer.
- **Requiring a synthetic FAIL and a synthetic UNPROVEN before arming** is the right response to the phase's known failure mode — the defect is that the gate does not check them all, not that they are wrong.
- **`Verdict (window 2):` cannot collide with `^Verdict:`**, so invariant 9 survives by construction (Grok).
- **Mechanical `STATUS=` extraction** from the judge's own stdout — the record can disagree with the plan — and **machine-selected headings** in 04-16 (Gemini, Grok, gpt-5.4).

### Divergent views

- **Overall risk: Gemini, astra and gpt-5.4 say HIGH; Grok says MEDIUM**, "HIGH if 04-15 is armed before the LINGER and SC-1 fixes". Grok's is the better-reasoned position: it separates estate risk (none — read-only, scratch-only, no API) from the risk to the **scarce real job**, which is what actually gets spent.
- **Only Grok found the LINGER defect** — the single highest-impact finding of the round — while three reviewers converged on the snapshot-completeness family. Convergence located the *design* risk; a lone reviewer found the one that would have wasted the window outright.
- **The two OpenAI models did not echo each other.** `gpt-5.4` returned 6 findings, `astra` 11; they shared only the "window closed" branch. Same family is not the same review.
- **Gemini vs astra on the same mechanism**: Gemini calls it physically impossible, astra calls it unestablished. The measurement sides with astra.

### Nobody raised

No reviewer questioned whether the *estate* is clean — correctly, since the side-effect evidence is
doubled and strong. No reviewer proposed reopening beets, the retirements, or criteria 1/2/4/5. And
no reviewer noticed that `/mnt/fast/scratch-04` is absent on the live host, because none of them
could look — that finding required checking the estate, not the text.
