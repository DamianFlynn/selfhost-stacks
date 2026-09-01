---
phase: 3
reviewers: [codex, copilot, gemini]
reviewed_at: 2026-09-01T21:55:44Z
plans_reviewed: [03-01-PLAN.md,03-02-PLAN.md,03-03-PLAN.md,03-04-PLAN.md,03-05-PLAN.md,03-06-PLAN.md,03-07-PLAN.md,03-08-PLAN.md,03-09-PLAN.md,03-10-PLAN.md,03-11-PLAN.md]
self_cli_skipped: claude
---

# Cross-AI Plan Review — Phase 3: Tagger Spike

Three independent reviewers. `claude` was deliberately skipped: this session authored the plans,
so a review from the same model would not be independent.

| Reviewer | CLI | Overall risk |
|---|---|---|
| Codex | `codex exec` | MEDIUM |
| GitHub Copilot | `gh copilot -p` (read-only) | **HIGH** |
| Gemini | `gemini -p` | LOW–MEDIUM |

---

## Codex Review

## Summary

The plan set is unusually rigorous on safety, provenance, and measurement hygiene, and it is likely to produce a defensible Phase 3 decision if executed exactly. The main weakness is sequencing: several protections depend on commit ordering or prior artefacts, but the dependency graph does not always enforce that ordering. There is also some over-engineering that may turn the spike into a fragile mini-project, especially around hand-transcribed second instruments, full Docker cleanup, and the beets-flask ergonomics trial.

## Strengths

- Strong separation of **engine** and **front end** decisions across plans `03-02`, `03-07`, `03-10`, and `03-11`.
- Good safety posture: no planned `rw` access to `/mnt/tank/media/Music`, scratch copies only, freeze checks repeated, and frozen stack files protected.
- The plans correctly reject weak instruments like `beet import --pretend` and use `tag_album()` for measurable candidate data.
- Criterion 5 is treated seriously: thresholds are intended to be committed before evidence, with `PENDING` result cells and git-history checks.
- OD decisions are mostly honoured, especially OD-2, OD-4, OD-5, and OD-6.
- The strict-vs-loose Discogs gap is elevated properly instead of hidden as a footnote.
- `wrtag` is evaluated more fairly than the old context allowed: old pin, D-01 tag, and latest tag all measured.
- The beets-flask release-candidate and no-auth risks are surfaced before deployment rather than buried.

## Concerns

- **HIGH — `03-03`**: The sample plan depends only on `03-01`, but it reads and operationalizes `03-DECISION.md` from `03-02`. This can allow sample selection before OD-3/T1 are committed, weakening Criterion 5’s chain of custody. Make `03-03` depend on `03-02`.

- **HIGH — `03-02` / `03-03` / `03-07`**: OD-3 changes T1’s population from original D-06 `dj-mixes` to widened `dj-mixes ∪ unsorted`. That is defensible only if committed before *any* sample work. Because `03-03` can currently run in parallel, this becomes retroactive in practice.

- **HIGH — `03-01`**: The image prune helper is risky. It tries to infer safe deletion from `docker ps -a`, image IDs, tags, dangling parents, and allow-list patterns. That is better than `docker image prune -a`, but still cannot see human-retained rollback images, one-off manual images, or compose files not currently materialized as containers. The human approval gate helps, but the generated list may look more authoritative than it is.

- **HIGH — `03-05`**: The normalisation acceptance criterion says “exactly album and artist changed across the sample and no other field was gained or dropped.” With mutagen, WAV, ID3 version normalization, timestamp changes, encoding normalization, and container-level tag rewriting, this may be too strict and could block a valid run on representation-level changes. The plan should distinguish semantic tag-field changes from container/serialization changes.

- **HIGH — `03-06` / `03-07`**: The request-counting method using `grep -c 'api\.discogs\.com'` over `urllib3` DEBUG stderr may not reliably equal HTTP requests. Retries, redirects, connection reuse, logging format changes, or cached master fetches can skew it. It is acceptable as a second instrument, but not as a hard equality oracle unless validated in the smoke test.

- **HIGH — `03-10`**: Beets-flask is unauthenticated and includes a web terminal. Loopback binding is good, but “reachable over Tailscale” conflicts with the control unless Tailscale is only used to SSH tunnel to loopback. The plan should explicitly prohibit binding the Flask port to a Tailscale interface.

- **MEDIUM — `03-03` / `03-07`**: The 24-folder stratified sample is operationally useful, but statistically it is not a generalizable match-rate estimate for the full 143-folder backlog. It is deliberately enriched for difficult variants and DMC. The decision should call the rate a **stratified spike result**, not a population estimate.

- **MEDIUM — `03-07`**: Extrapolating wall-clock from 24 folders to 143 assumes folder-level independence and similar Discogs/MusicBrainz complexity. DMC, Now, mainstream FLAC, and Mastermix folders may have different request profiles. The extrapolation is useful for order of magnitude, not a strong operational forecast.

- **MEDIUM — `03-07`**: “Any observed HTTP 429” firing T2 is too sensitive. A single transient 429 could come from shared Discogs traffic or a retry artifact and may not prove bulk import is impractical. Better threshold: repeated 429s, sustained backoff, or projected wall-clock exceeding the committed ceiling.

- **MEDIUM — `03-07`**: The plan rejects recording a 429-bearing run and says rerun after budget reset, but T2 itself says any observed 429 fires the threshold. These conflict. Either 429 is evidence, or it invalidates the run. Pick one.

- **MEDIUM — `03-06` / `03-07`**: Hand-transcribed `beet import -t` as a second instrument is brittle and hard to audit. It also introduces operator variability and may not produce the same candidate ordering or metadata path as the probe. Good as a sanity check, weak as formal validation.

- **MEDIUM — `03-09`**: The `metadata` bake-off risks scope creep. D-13 is legitimate, but the driver loop, tag preservation proof, WAV-specific analysis, line counting, and source/observed capability matrix may consume more effort than the engine decision warrants.

- **MEDIUM — `03-10`**: The ergonomics trial imports the same album twice through two front ends. Even with copies and alternation, the second run benefits from learned knowledge. Alternation helps but does not eliminate carryover. This should be acknowledged in the scoring, not just controlled.

- **MEDIUM — `03-11`**: Teardown before final human sign-off may remove runtime evidence the operator might want to inspect. The Markdown/NDJSON artefacts remain, but the live environment disappears before confirmation. Consider operator sign-off before destructive cleanup, or preserve a “review window.”

- **MEDIUM — `03-11`**: The final claim “library is byte-identical” is stronger than some instruments prove. `check-music-freeze.sh` plus `zfs diff tank/media/Music@pre-project` is strong, but only if the snapshot baseline is correct and the diff is interpreted properly. Keep this, but avoid over-claiming beyond the exact checked dataset.

- **LOW — `03-01`**: “All four spike images” is inconsistent with later acceptance criteria that track five spike images including pre-existing `wrtag:v0.20.0`. Minor wording issue, but it can confuse sign-off.

- **LOW — `03-02`**: The plan asks to reproduce all 16 D-12 rows verbatim. That is useful, but it may bloat `03-DECISION.md` and make later review harder. A summarized table with links to evidence may be more maintainable.

- **LOW — `03-04` / `03-10`**: Literal `PUID`/`PGID` values are pragmatic, but if `apps:apps` changes later the spike docs become stale. Acceptable for this phase, but record that these are phase-local literals.

- **LOW — `03-05`**: The phrase “snapshot is its only rollback” is not fully true because `raw/`, originals, and `@pre-project` also exist. The snapshot is the intended rollback for the scratch mutation, not the only recovery path.

## Suggestions

1. Add `depends_on: ["03-01", "03-02"]` to `03-03`. This is the most important fix.

2. In `03-02`, explicitly record that no sample artefact, survey output, or evidence file exists before the threshold commit. Do not only check for `03-*EVIDENCE*.md`.

3. In `03-07`, resolve the 429 contradiction:
   - Either “any 429 fires T2 and is recorded,” or
   - “429 invalidates the run and only sustained/repeated 429s fire T2.”

4. Reword match-rate claims as “measured on the stratified spike sample,” not “estimated for the backlog,” unless confidence intervals or population weighting are added.

5. Add a weighted extrapolation in `03-07`: compute per-stratum request/time figures and extrapolate against known stratum counts where available, with the simple `143 * M` figure as a baseline.

6. For `03-06`, add a smoke assertion that `grep -c api.discogs.com` matches an in-process request counter on the known-good album within an explicit tolerance.

7. For `03-05`, define “only album and artist changed” as semantic tag-key changes from the snapshot tool, and explicitly allow harmless serialization/container-level differences if audio checksum and protected fields are stable.

8. For `03-10`, state that Tailscale access means SSH tunneling over Tailscale only; the app port must remain bound to `127.0.0.1`.

9. For `03-11`, consider moving destructive teardown after operator confirmation, or split sign-off into “decision review” before teardown and “closure” after teardown.

10. Reduce mechanical grep-based acceptance where possible. Several plans already warn against prose grep false positives, but still use grep heavily. Prefer parsed YAML/JSON or explicit generated summaries.

## Risk Assessment

**Overall risk: MEDIUM.**

The phase is well-designed and much safer than a typical spike touching live media infrastructure. The biggest risk is not data loss; the plans have strong controls around Music and scratch paths. The bigger risk is procedural: `03-03` can run before the Criterion 5 threshold record, and some measurements are so elaborate that execution errors or brittle validation could undermine the decision. Fix the dependency ordering and clarify the 429/statistical language, and this becomes a defensible measurement phase rather than tool advocacy.

---

## GitHub Copilot Review

## Summary

This phase is unusually disciplined about safety, audit trails, and adversarial verification, and it does a much better job than most spike plans of separating “measured” from “argued.” The problem is that the two most decision-critical surfaces are still shaky: the **headline Discogs rate / backlog extrapolation is not statistically defensible as written** because it is derived from a deliberately stratified, tree-skewed sample and then treated as a population estimate, and the **beets-flask trial can silently stop measuring the intended 2.12.0 runtime** because `requirements.txt` installs unpinned `beets[discogs]` at startup. Until those are fixed, this is close to a defensible decision framework but not yet one.

## Strengths

- **03-02** is the right shape for criterion-5 integrity: thresholds, denominators, and the ergonomics sheet are committed before evidence, with explicit `PENDING` cells to make post-hoc filling visible.
- **03-03 / 03-05 / 03-08** take safety seriously in the right places: reflinked copies, ZFS rollback points, no `/mnt/tank/media/Music` mounts, and repeated freeze checks are strong controls against accidental writes escaping into the live library.
- **03-06 / 03-07** distinguish **loose** vs **strict** matching and require a second instrument before recording numbers. That is exactly the right instinct for a phase whose output is mostly measurements.
- **03-08** is commendably honest about provenance: the wrtag `tags.Clear` result is explicitly carried as a source-read finding rather than misrepresented as a runtime observation.
- **03-10** correctly treats ergonomics as operator-owned evidence, not something an agent can simulate, and fixes the intervention/context-switch definitions before the trial.

## Concerns

- **HIGH — 03-03 / 03-07:** The plan mixes up **coverage sampling** with **decision-threshold estimation**. A sample drawn as `20 dj-mixes + 4 unsorted DMC`, stratified “never random,” and excluding all scan-bearing folders is useful for surfacing failure modes, but it is **not a defensible estimator** for the full-population strict match rate or wall-clock extrapolation to 143 folders. Right now T1 and T2 are being decided from a deliberately biased sample and then narrated as headline population numbers.

- **HIGH — 03-10:** `requirements.txt` containing unpinned **`beets[discogs]`** can upgrade the beets version inside `metasauce/beets-flask:v2.0.0-rc6`, which directly breaks **OD-2**. The plan says axis two must run on beets **2.12.0**, but the startup install mechanism can silently move that to a newer version before the trial. The runtime version check detects drift only after the environment has already changed.

- **MEDIUM — 03-02 / 03-07 / 03-11:** Criterion-5 “pre-committed threshold” enforcement is weaker than the prose claims. Local commit ordering is evidence, but it is **not tamper-resistant** if the branch can still be rebased/amended before push. `git log -p` on a mutable local history is not enough if you really want to rule out threshold movement.

- **MEDIUM — 03-04 / 03-06 / 03-07:** The beets spike container gets **rw over the entire `/mnt/tank/downloads/spike-03` tree**, even for read-only probe work. That means the safety model depends on post-hoc detection (`find -newer`, spot hashes) rather than mount-layer prevention. For the most measurement-sensitive steps, `raw/` and often `normalised/` should be mounted read-only.

- **MEDIUM — 03-07:** The “second instrument” for the probe is too thin. Hand-transcribing **3 folders** from different strata is not enough to validate the whole matrix, especially given the known sensitivities around **DMC**, **`index_tracks: yes`**, and **zero-candidate** folders. A divergence that only appears in one of those cases can still slip through while the plan claims paired-instrument confidence.

- **MEDIUM — 03-03 / 03-05 / 03-07 / 03-09:** Too many “nothing wrote” assertions rely on **mtime-based `find -newer` checks plus hashes on only 5 files**. That is weaker than the rest of the phase design. If a tool preserves mtimes, or writes outside the 5 sampled files, the plan can miss it while still reporting a pass.

- **MEDIUM — 03-11:** Deleting the spike compose/config YAMLs hurts reproducibility more than it helps repo hygiene. These files live under `.planning/phases/03-tagger-spike/`, not `stacks/`, so they are already clearly experimental. Removing the exact executable configs used in the spike makes future re-runs and audits harder, while the “fourth tagging path” risk is fairly low in that location.

- **LOW — 03-10:** Axis two is not a pure “front end” comparison anymore; it also compares **policy architecture** (`preview` / `auto` / `bootleg`) against a raw terminal flow. That may be the right product decision, but it means the verdict is about a broader workflow system than “terminal vs queue UI.” The plan should say that more explicitly.

## Suggestions

1. **Separate the sampling goals.** Keep the current stratified 24-folder sample for failure discovery and criterion-4 coverage, but add either:
   - a small **random/weighted** sample for the headline T1/T2 numbers, or
   - a **weighted roll-up by stratum/tree prevalence** from the census instead of treating the curated sample as population-representative.

2. **Make criterion-5 custody harder to fake.** Require **03-02 to be pushed** before any evidence plans start, and record that commit SHA verbatim in `03-DISCOGS-EVIDENCE.md` and `03-DECISION.md`. An annotated tag would be even better.

3. **Pin the beets-flask startup install.** If that container must install at startup, pin it to **`beets[discogs]==2.12.0`** or otherwise ensure startup cannot upgrade beets at all. Right now OD-2 is a hope plus a post-start check.

4. **Tighten mounts by plan role.** For read-only measurement plans, mount:
   - `raw/` read-only,
   - `normalised/` read-only unless that plan is the writer,
   - output/log/db dirs writable separately.
   This makes sample corruption impossible rather than merely detectable.

5. **Strengthen the second instrument.** In **03-07**, require the 3 manual cross-check folders to include at least:
   - one **DMC** folder,
   - one **V3 / missing-album** case,
   - one **index-track-sensitive** case,
   - and preferably one **zero-candidate** folder if you want real coverage of the probe’s edge behavior.

6. **Replace mtime checks with whole-tree evidence where possible.** For scratch trees, use a manifest or snapshot-based diff across the entire sampled subtree instead of `find -newer` plus 5-file spot checks.

7. **Archive, don’t delete, the spike configs.** Keep the phase YAMLs in the planning directory with an explicit “throwaway / do not deploy” banner, but still tear down the running containers and delete the credential-bearing runtime files. That preserves reproducibility without creating a live fourth path.

## Risk Assessment

**HIGH** — The plan is strong on operational safety, but the decision itself is still vulnerable on two fronts: **biased sampling being treated as a headline population number** and **axis-two runtime drift caused by unpinned startup installs**. Those are not cosmetic flaws; they can change the winner while leaving a very polished evidence trail behind them. Fix those, and this drops substantially.


---

## Gemini Review

### 1. Summary
The plan set is exceptionally rigorous, well-sequenced, and meticulously aware of the system's previous failures (false passes, unearned confidence, UI frictions, blind spots). It successfully builds an environment to objectively measure `beets` against `wrtag` and `beets-flask` without committing untested configuration or modifying the live library. The commitment to proving claims empirically through a "paired-instrument rule" establishes a level of operational discipline that directly counteracts the project's historical abandonment modes.

### 2. Strengths
- **Empirical Rigor:** The "paired-instrument rule" is an excellent defense against false passes. Demanding independent verification for every metric (e.g., `tag_album()` probe vs. `beet import -t` transcript; `time` vs. NDJSON timestamps; calculated requests vs. `stderr` logging) guarantees high confidence.
- **Safety First:** The use of `cp --reflink=always` ensures rapid, non-destructive testing that strictly isolates the live library. The hardcoded root check in the normalisation script, explicit read-only mounts, and comprehensive teardowns show strong defensive engineering.
- **Commit Ordering (Criterion 5):** Enforcing the commit of `03-DECISION.md` with overturning thresholds *before* any evidence is gathered ensures the decision is objective and not post-rationalized.
- **Addressing Ergonomics:** Recognizing that "a painful tool is an abandoned tool" and formally measuring UI interventions, context switches, and wall-clock time for the operator (Axis Two) is a crucial project-saving insight that honors the reality of the work.

### 3. Concerns

- **HIGH: Statistical Invalidity in Extrapolating `M` (Plan `03-07`)**
  The sample of 24 folders is *stratified*, meaning it artificially forces coverage of minority edge cases to ensure all shapes are tested (e.g., forcing 4 V3 folders, forcing 4 DMC folders). However, the plan calculates the average requests per folder (`M`) directly from this stratified sample and multiplies it by the total population size (143). If the API request volumes vary significantly by stratum (e.g., a V3 folder fails early with 0 requests because `album` is missing, while V1 does full pagination), an unweighted average of `M` will heavily skew the 143-folder extrapolation, invalidating the Criterion 2 API floor.
- **HIGH: Non-interruptible Backoff Sleep (Plan `03-06`)**
  The `tag_album()` probe implements `--max-seconds` by checking a flag at the *top* of the folder loop. However, `python3-discogs-client` handles 429 errors with `time.sleep()`. If the client hits a 429, it could sleep for hours inside the library call. The `--max-seconds` check will never be reached during this sleep, causing the script to hang and absorb the delay silently despite the wall-clock ceiling.
- **MEDIUM: Determinism of the Sample Draw (Plan `03-03`)**
  Task 2 instructs the script to "Draw 20 folders... Stratified, never random". However, it does not explicitly define *how* to deterministically pick the N folders from a larger stratum. Without a defined sort, the script author may inadvertently use a pseudo-random selection or rely on an unstable `find` directory-read order, which violates the requirement for strict repeatability.
- **MEDIUM: Credential Leak via Host Shell History (Plan `03-07`)**
  Task 1 creates a temporary config with the token for `beet import -t`. While the file itself is deleted in `03-11`, if the operator or script generates this file by echoing the token into a file or placing it in an un-sanitized script variable, it could persist in the host's `.bash_history`.
- **LOW: Docker Image Pruning Collateral Damage (Plan `03-01`)**
  The `inventory` uses `docker ps -a` (unfiltered) to protect `created` and stopped containers. However, this does not protect images for compose stacks that have been temporarily `docker compose down`'d. Those images will be reaped and require re-downloading later. Given the extreme disk pressure this is likely acceptable, but it should be explicitly acknowledged as collateral damage.

### 4. Suggestions

- **Weighted Extrapolation (Plan `03-07`):** Update the extrapolation math. Instead of `total_requests = 143 * M`, calculate the average `M` *per stratum*, then multiply by the actual population size of each stratum in the backlog, and sum them. This produces a statistically valid extrapolation that respects the stratification.
- **Alarm-based Timeout (Plan `03-06`):** In the probe script, use `signal.alarm()` to enforce `--max-seconds` instead of just checking elapsed time at the top of the loop. This ensures the script breaks out of a deep `time.sleep()` from the `discogs_client` backoff.
- **Deterministic Draw Sorting (Plan `03-03`):** Explicitly instruct `spike03-variant-survey.sh` (or the downstream draw script) to sort eligible folders alphabetically or by `audio_md5` before taking the top N for the draw to guarantee identical runs.
- **Secure Config Generation (Plan `03-07`):** Specify that the temporary `beet import -t` config should be generated using a script that reads the token directly from the sourced environment variable (via `discogs.env`), ensuring no plaintext token is passed through a command line that could leak into `.bash_history`.

### 5. Risk Assessment
- **Overall Risk:** LOW to MEDIUM
- **Justification:** The architectural planning, safety boundaries, and threshold discipline are exceptionally high-quality and directly mitigate the project's historical failure modes. The remaining risks are localized to statistical mechanics (extrapolation math) and edge-case execution hangs (uninterruptible sleeps). Implementing the suggestions will close these final gaps, yielding a highly defensible, safe, and secure spike phase.

---

## Consensus Summary

All three reviewers independently rate the phase strong on **operational safety** and **measurement
hygiene**, and all three locate the risk in the same place: not in whether the spike will damage
anything, but in **whether the number it produces is defensible**. Copilot puts it most sharply —
the failure mode is "a very polished evidence trail" around a figure that does not support the
weight placed on it.

Two findings were verified against the plan files before being recorded here.

### Agreed Concerns (2+ reviewers — highest priority)

**C1 — HIGH — The stratified sample is used as a population estimator.** *(Copilot, Gemini —
independently, and the single strongest consensus in the review.)*
The 24 folders are drawn stratified, "never random", deliberately forcing coverage of minority
variants, and excluding the scan-bearing folders. That is the right design for *surfacing failure
modes*. It is not a valid estimator for a headline strict match rate, nor for an unweighted
`M × 143` request extrapolation — if request volume varies by stratum (a V3 folder with no `album`
issues no query at all; a V1 folder paginates), the average is skewed by construction. **Both T1 and
T2 are currently decided from a deliberately biased sample and then narrated as population numbers.**
Gemini's fix is concrete: compute `M` per stratum, multiply by each stratum's real backlog
prevalence, and sum. Copilot's alternative is to keep the curated sample for discovery and add a
weighted roll-up (or a separate random draw) for the headline.

**C2 — MEDIUM — "Nothing was written" rests on `find -newer` plus 5 spot hashes.** *(Codex, Copilot)*
Weaker than the rest of the phase's design. A tool that preserves mtimes, or writes outside the five
sampled files, passes. Suggested: a whole-subtree manifest or snapshot diff for scratch trees.

**C3 — MEDIUM — Criterion 5's custody is local-history-only.** *(Codex, Copilot)*
`git log -p` on a mutable local branch is evidence, not proof — history can be amended or rebased
before push. Copilot's fix: require 03-02 to be **pushed** before any evidence plan starts, and
record that commit SHA verbatim in both the evidence file and the decision record.

### Verified Findings (checked against the plans, not just asserted)

**V1 — HIGH — `03-03` can run before `03-02`, breaking criterion 5's chain of custody.** *(Codex)*
**Confirmed:** both plans are `wave: 2` with `depends_on: ["03-01"]`, and `03-03` references
`03-DECISION.md` — which `03-02` creates — twice. So the sample can be drawn before the thresholds
that govern it are committed. This is exactly the property OD-3 was written to protect, and the
dependency graph does not enforce it. Fix is one line: `03-03` must depend on `03-02`.

**V2 — HIGH — `03-10` pip-installs unpinned `beets[discogs]`, which can silently break OD-2.**
*(Copilot)* **Confirmed:** the beets-flask arm installs `beets[discogs]` from `requirements.txt` at
container start with no version constraint. The plan *does* assert `beets.__version__ == 2.12.0` at
runtime, so drift is detected — but only after the environment has already moved, and the whole
point of OD-2 is that axis two is measured at the version beets-flask actually ships. Fix is
trivial and strictly better: pin `beets[discogs]==2.12.0`.

### Other Notable Single-Reviewer Concerns

- **HIGH (Gemini) — `03-06`'s wall-clock ceiling is not enforceable during a 429 backoff.**
  `--max-seconds` is checked at the top of the folder loop, but `python3-discogs-client` handles 429
  with `time.sleep()`. A long backoff inside the library call is never interrupted, so the probe can
  hang well past its stated ceiling. Suggested fix: `signal.alarm()` rather than a loop-top check.
- **MEDIUM (Copilot) — read-only mounts by plan role.** The beets container gets rw over the whole
  `spike-03` tree even for read-only probe work. Mounting `raw/` (and `normalised/` outside its
  writer) read-only converts sample corruption from *detectable* to *impossible*.
- **MEDIUM (Copilot) — the second instrument is thin.** Three hand-transcribed folders do not cover
  DMC, the missing-`album` variant, index-track sensitivity, and the zero-candidate case. Paired-
  instrument confidence is claimed more broadly than three folders support.
- **MEDIUM (Gemini) — the sample draw is not deterministic.** "Stratified, never random" does not say
  *how* N are chosen from a larger stratum; an unstable `find` order would defeat repeatability.
  Fix: sort explicitly before taking the top N.
- **MEDIUM (Gemini) — token could reach shell history** if the temporary `-t` config is generated by
  echoing the value rather than reading `DISCOGS_USER_TOKEN` from the sourced env.
- **LOW (Gemini) — prune collateral.** `docker ps -a` protects `created` and stopped containers but
  not images for a stack currently `compose down`'d; those get reaped and need re-pulling. Probably
  acceptable under the disk pressure, but should be acknowledged rather than discovered.

### Divergent Views

- **Overall risk splits widely: Copilot HIGH, Codex MEDIUM, Gemini LOW–MEDIUM.** The divergence is
  entirely about how much weight the sampling flaw (C1) carries. Copilot treats it as decision-
  changing — a biased number can pick the wrong winner while looking rigorous. Gemini treats it as
  localised "statistical mechanics" with a known fix. Both agree on the fix; they disagree on whether
  shipping without it invalidates the phase.
- **Teardown of the spike compose files.** The plans delete them in 03-11 on the grounds that a
  surviving spike config is how a fourth tagging path gets read back into the repo. Copilot argues
  the opposite — they live under `.planning/`, not `stacks/`, so the risk is low and deleting the
  exact executable configs hurts reproducibility and auditability. **This is a genuine trade-off
  against the project's own documented failure mode, and worth an explicit operator decision rather
  than a default.**
- **Scope of axis two.** Copilot notes (LOW) that axis two now compares *policy architecture*
  (`preview`/`auto`/`bootleg`) as well as front end, so the verdict is about a broader workflow than
  "terminal vs queue UI". Not a defect — but the decision record should say so plainly.

### Nobody Raised

No reviewer challenged the phase's direction, the two-axis framing, OD-1's disk gate, OD-5's
three-tag wrtag test, or the honesty of the D-13 bake-off's stated expected outcome. The
`beet import --pretend` finding and its Phase 4 handoff went unchallenged by all three.
