---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-09-25T15:51:25.000Z"
progress:
  total_phases: 10
  completed_phases: 5
  total_plans: 141
  completed_plans: 124
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-17)

**Core value:** New music downloads land in the library correctly tagged, through exactly one
pipeline that someone owns.
**Current focus:** Phase 07 — pilot-12-albums-end-to-end (**PLANNED 2026-09-25, 17 plans in
13 waves, 0 executed**; Phase 06 stays `In Progress` at `gaps_found` 5/6 with CONF-04 carried to
Phase 7 E6 — `/gsd-verify 06` is still owed)

**Definition of done (CONS-04):** a file is imported only when verified with `ffprobe` on the file
*and* visible in both Jellyfin and Music Assistant. Never "tool configured".

## Current Position

**PHASE 07 PLANNED — 2026-09-25. 17 plans in 13 waves, committed in `114586e`; 0 executed.** Research
was skipped by operator decision (the ROADMAP entry says it is not needed) and **Nyquist validation
was disabled project-wide** (`workflow.nyquist_validation: false`) in the same run, so no
`07-RESEARCH.md` or `07-VALIDATION.md` exists and none is owed. `07-PATTERNS.md` recorded **eleven
measured couplings C1 … C11** the context did not name — among them that repo `config.yaml` already
reads `copy: yes` (so `CLAUDE.md`'s `import.move: yes` is stale or describes the appdata copy), that
`01-auto` is registered in `flask-config.yaml` not `flask.yaml`, and that **four standing checks go red
the moment `/media` becomes `rw`** (quick-health-check's D-03 block, `check-music-freeze.sh`'s mount
census, the oracle's `assert_media_readonly` and its `FIXTURE_LIB_SHA256`); every one has an owning
plan. Plan-checker verdict: **0 BLOCKER, 4 WARNING, 1 INFO, no revision round run** — warnings 1 and
2 were interpretive and the operator ratified both at plan time (recorded in band in `07-CONTEXT.md`
under D-15 and D-22): criterion 1's "rollback exercised" is discharged by `UNDO IMPORT`, **no
`zfs rollback` of `tank/media/Music` is planned**, and the `rw` grant is **flask-only**. Warning 3
(dense gated tasks in 07-09/11/12/15/17 — split rather than push through if a context window
stalls) and warning 4 (bare "D-04" means Phase 6's beet-invocation rule in some plans and Phase 7's
sample composition in others) are carried as execution notes. **9 of 17 plans are `autonomous: false`**
— every live-estate write (fence + grant, P01, undo, the other albums, the DJ pair, the Def Leppard
repair, the MA sync, snapshot pruning, the trust verdict) stops at a `hold`-first gate. ⛔ Standing
prohibitions carried into every plan: no `zfs rollback` of `fast/appdata/arrs`; no snapshot destroyed
on a plan's own judgement except D-17's single mechanical release; `tank/downloads@pre-phase5` never
offered; no `FullRefresh`; no E6 mtime-route retry. Next: `/gsd-execute-phase 07` (waves 1–4 are
repo-only and autonomous; wave 5 is the first gate). `total_plans` in the frontmatter moves
124 → 141 to carry the seventeen.

Phase: 06 (tagger-configuration-and-dry-run) — gap-closure **ROUND 6 COMPLETE: all seven plans
`06-46` … `06-52` have executed across 5 waves, and neither `autonomous: false` plan halted**
(round 5 executed and re-verified 2026-09-24: `06-VERIFICATION.md` **gaps_found, 5/6**, CONF-04 the
single failing truth, carried to Phase 7 E6 under the operator override `negative-carry-e6`)

**BOTH OPERATOR ACTIONS HAVE NOW EXECUTED — `R6-08`: PROCEED on a CLEARED pre-flight; `R6-09`:
HOLD, with the release condition made mechanical.** ✅ **The round-6 block further down this file has
been closed to match** — plan `06-52` task 3 replaced its two pending operator-action entries with
these outcomes at wave 5, so the caveat this paragraph used to carry (that the block below was stale
for R6-08 only) **no longer applies and has been removed**; the block and this paragraph now agree.
What 06-51 established: LXC 100's `/mnt/fast/stacks` moved `ee82fb2` → `b9c09b5`;
**6 of 6** instrument scripts now sha256-MATCH between repo and host, where the pre-flight measured
**3 MATCH / 3 DIFFERS**; nothing redeployed, proven on all three of name/image/status (set
difference empty both ways, 99 = 99 containers). STOP condition **S4** (three stash entries on the
production checkout) **fired** at the first pre-flight — the operator then **disposed of the
entries** and the gate re-read 5 CLEAR / 0 STOP, so this is a **clearing of S4, not an override**,
and both stages are kept in `DEF-06-51-01`. `DEF-06-45-05` item 2 and `DEF-06-29-11` are **CLOSED**;
`DEF-06-39-05` is **unblocked but NOT closed** — `quick-health-check.sh` has still been run **zero**
times across rounds 3-6. No requirement checkbox moved; CONF-04 untouched.
What 06-52 established (`R6-09`, 2026-09-24T22:29:38Z): the operator answered **`hold`** — ⛔
**nothing was destroyed, rolled back or released**, the only `zfs` verb issued on any branch was
`list`, and both `tank/media/Music@pre-06-41-conf04-reprobe` and `tank/downloads@pre-phase5` (a
different fence, entry criterion **E4**) were re-asserted PRESENT read-only after the decision.
`DEF-06-45-01` stays **OPEN**, disposition **CARRIED**, with its release condition **rewritten from a
judgement call into one mechanical trigger**: release when **Phase 7 Success Criterion 1 is
SATISFIED** — a new snapshot taken on the Music dataset **and** rollback exercised — not when Phase 7
is merely planned. ⚠ The executor **recommended `release`**; the operator overruled it on the
executor's own self-raised counter-argument that Phase 7's fence is *planned, not taken*, and
`defer` was explicitly rejected. Two further 06-52 outcomes, both independent of that decision: the
stale *"`tank` has ~9 T free"* figure corrected to the measured **5.26 T** in `DEF-06-45-01` and
`CLAUDE.md` § Constraints, and **`DEF-06-52-02`** filed as a **process defect** — a criteria-only
read of Phase 7's entry-criteria block would have answered "the pilot fence is not planned" **by
omission**; promoted to `CONVENTIONS.md` convention 14.

Plan: 52 of 52 executed — round 6 (**06-46..06-52**, 5 waves, planned 2026-09-24, commits `d500907`

+ `d7df994`) is the full `06-REVIEW.md` round: WR-01/02/03 + IN-01/02, the `DEF-06-45-04`

non-detecting-recipe fix, the bracketing-scope decision, and the two `autonomous: false`
live-estate plans (`06-51` host git sync, `06-52` snapshot go/no-go). ⛔ Round 6 drives **no**
CONF-04 work — `06-VERIFICATION.md` holds that no further Phase 6 action on it is warranted or
safe. `REQUIREMENTS.md:152` stays `- [ ] CONF-04`. Round 1 (06-15..06-21, waves 6-9, 2026-09-22) closed CR-01 and
dispositioned all 24 findings of `06-REVIEW.md`; re-verification is **6/6, status passed**
(`06-VERIFICATION.md`, gaps_remaining: [], regressions: []).
**The phase is NOT complete.** A code review of the round-1 changes themselves
(`06-REVIEW-GAP.md`, GC-01..GC-15) found 1 BLOCKER + 7 WARNING in the new code — the same
defect class round 1 existed to remove. Two confirmed independently by the orchestrator:

- **GC-01** `check-beets-config.sh:554,:567` — `printf | grep -qF` under `pipefail` returns 141
  at >=64 KiB input, so a forbidden substring that IS present reports as absent. Reproduced
  locally: FOUND at 8-56 KiB, MISSED at 64/96/128 KiB. Position-dependent; `--self-test` cannot
  catch it (synthetic dumps are tiny). Fix is `grep -qF -- "$forb" <<<"$raw"`.

- **GC-03** `quick-health-check.sh:1791` — the vacuity guard tests `D04_N_EXE` but the loop
  iterates `D04_INVOKE_ASSERT` and the tick prints `$D04_N_ASSERT of $D04_N_EXE`, so an empty
  ASSERTED set still prints a green tick. **CR-01 reproduced one nesting level in.**
A cross-family adjudication (`gemini-3.1-pro-preview`; `codex` failed on billing, `opencode`
installed, `gh copilot` extension NOT) added GC-16 and GC-17, for **GC-01..GC-17**.

**ROUND 2 IS DONE — 2026-09-22. Plans 06-22..06-28 closed all seventeen findings and plan 06-29
dispositioned them in `06-DISPOSITIONS-GAP.md`: 17 FIXED, 0 FIXED (undriven), 0 ACCEPTED,
0 CARRIED, reconciling three ways to 17.** `06-REVIEW-GAP.md` is WIRED to that register. Both
headline findings are closed **and driven in both directions**: GC-01's self-test now carries a
71,013-byte case proven to MISS against the pre-fix code and CATCH against the fix, and GC-03's
condition P was driven pre-fix (`✅ … 0 of 5`, exit 0) and post-fix (`⚠️ UNKNOWN … (5 of 5)`,
exit 1). Instruments at HEAD: `phase06-oracle.sh --self-test` exit 0 / **134 cases**,
`check-beets-config.sh --self-test` exit 0 / **7 cases**, `phase06-incremental-control.sh
--self-test` exit 0, `bash -n` clean on all four. D-04's **pinned** vector is unmoved at
**10 / 8 / 3 / 5 / 2**; raw/comment-stripped read **202 / 101** at HEAD and are deliberately
**not pinned anywhere** — writing them moves them, which is GC-10.
**⚠ RE-VERIFICATION HAS NOT BEEN PERFORMED.** Plan 06-29 records dispositions; it did **not** run
`/gsd-verify` and claims **no** verification result. **Do not read "round 2 complete" as "phase
complete"** — that is the verifier's call. **Run `/gsd-verify 06` next**, and consider a fresh
code review of **round 2's own changes** before the phase closes: round 2 exists *because* round 1
was declared closed and verified 6/6 before anyone read its own diff, and it still carried a
BLOCKER. Verification asks whether the must-haves were met; review asks whether the code that
meets them is correct.
**Still open, unchanged by round 2:** CONF-04's Jellyfin half (Phase 7 entry criterion **E6**),
CR-01's residue (**E10**), WR-09 (**E11**), and now round 2's undriven-until-the-pilot residue
(**E12**, `DEF-06-29-05`). `REQUIREMENTS.md` was **not** touched and no checkbox moved.
Round 2's residue is carried by name as `DEF-06-29-01`..`DEF-06-29-11` in the phase's
`deferred-items.md`; `DEF-06-21-07` was **driven and PASSES** (closed by 06-26).
**⚠ Three items that are NOT this phase's and must not be lost:** `DEF-06-29-09` — three LIVE
secrets (`MEILI_MASTER_KEY`, `NEXTAUTH_SECRET`, `OPENAI_API_KEY`) sit un-rotated on LXC 100 in
`stacks/selfhosted/karakeep/.env.pre-pocket`; the repo-side hole is closed (`456ad06` widened the
ignore to `**/.env.*`) but **the keys are not rotated**. `DEF-06-29-01` — 23 lines / 24 pipelines
of the `| grep -q`-under-`pipefail` shape remain estate-wide, **five inverted**, and anyone adding
`set -euo pipefail` to `quick-health-check.sh` arms six more at once. `DEF-06-29-11` — the host is
at pre-Phase-6 `c67d497`, **nothing in this phase has been pushed**, and three live reds are that
staleness rather than round-2 fallout.

**ROUND 6, WAVE 1 EXECUTED — 2026-09-24. Plan 06-46 closed `06-REVIEW.md`'s WR-01 (in band `R6-01`)
and the `check-music-freeze.sh` half of WR-03 (`R6-03`), in four added lines.** Two task commits
(`e515970`, `049e9a3`) plus the summary (`21c263e`); one artifact,
`artifacts/06-46-freeze-fixes.txt`. **`shellcheck -S warning` is now clean on ALL SIX reviewed
scripts where it was clean on five** — WR-01's two SC2034 findings at `:1044` were the only
shellcheck finding in the set, and the fix takes the **named** form `read -r xn _xs xsrc _xdst
xflag`, not the review's bare-underscore alternative, because two anonymous positions discard the
column NAMES and a five-field read with anonymous positions is exactly where a future column
insertion hides. The column ORDER was read from the producer (`docker inspect --format` at
`:981-983` emits `name|state|source|destination|rw-flag`), so `_xs` is the container state and
`_xdst` the mount destination; the premise was checked before editing and the plan's STOP condition
(either column being consumed) did not fire.
**Both pinned-count fail arms now print the literal edit they require.** `DECLARED_INTERP_EXPECTED`
names the constant (by NAME, never a line number — citations here go stale on arrival), interpolates
pinned → measured, states the read-by-hand precondition and the same-commit rule, and **prohibits
using the env override to silence a red** — written as a policy on top of the header's documented
capability, not a contradiction of it. `TAGGER_DEF_EXPECTED` refuses the count bump by name and
requires a `TAGGER_DEF_<NAME>` + `_CLASS` pair into the `DEF_EXPECTED` set (D-11).
**Both arms were driven in BOTH directions** from a harness extracted verbatim by line range out of
the committed file; the artifact states in one clause that this proves the arm TEXT and its
interpolation and **not** the live block.
**No predicate, no constant and no failure count moved, and all three were measured against the base
commit `75c7989`:** `TAGGER_DEF_EXPECTED=2` and `DECLARED_INTERP_EXPECTED:-12` byte-identical,
comment-stripped `fail ` call sites **24** at both ends (the remediation lines are plain `echo`, so
`FAILURES` is untouched). `check-beets-config.sh` is byte-identical — WR-03's `ST_PLANNED_CASES=7`
third is **not** this plan's and is dispositioned ACCEPTED in `06-50`.
⚠ **The one zero-expecting count this plan publishes was DRIVEN against a control first**
(`DEF-06-45-04` class): the identical recipe returned **1** against a one-line control containing
`echo "$xs $xdst"` and **0** against the real script, both captured verbatim.
**Instruments re-measured at HEAD, not carried forward:** `check-beets-config.sh --self-test` exit
**0 / 7 cases** (6 red) and `phase06-oracle.sh --self-test` exit **0 / 140 cases**, in the named
reference environment (macOS 27.0 arm64, **non-root uid 501**, `python3` PRESENT, GNU bash 5.3.15,
ShellCheck 0.11.0, BSD grep). **Zero estate contact** — no ssh, no docker, no `--run`, no package
install. Nothing about CONF-04 changed; `REQUIREMENTS.md` was not touched and no checkbox moved.

**ROUND 6, WAVE 1 ALSO EXECUTED 06-47 — 2026-09-24. `beets.md` now tells a reader where the
authoritative current state is, on line 16 instead of line 2051, and it does it by HEADING TEXT.**
Two task commits (`6a38e02`, `c06e6b5`); one artifact,
`artifacts/06-47-disposition-consistency.txt` (24,453 bytes). The pointer is **26 insertions,
0 deletions** — purely additive — inserted before the existing `Amended 2026-09-11` blockquote so it
is the FIRST blockquote a reader meets. It says the file is a running log appended phase by phase,
names the Phase 6 closure section by its exact heading, states the disposition, and carries a
**go-forward rule**: every future closure section must update the pointer **in the same commit**, and
a closure section whose pointer was not updated is the defect, not the pointer.
**⚠ `06-REVIEW.md` § IN-02's own suggested fix is a LINE NUMBER (`see § Phase N closed, line X`) and
it was deliberately NOT taken** — line citations in this repository go stale on arrival and this file
only ever grows by append. The departure is stated in the pointer itself, with the reason, so it
cannot later read as an oversight. Byte-identity of the cited heading is proven **mechanically**:
`/usr/bin/grep -cF` returns **2** over the file (pointer + real heading) and **1** restricted to
`#`-prefixed lines.
**⚠ `### The five criteria` OCCURS TWICE in `beets.md`** — once in the Phase 5 closure, once in
Phase 6's — so a bare sub-heading locator would have resolved to the wrong section for a reader
searching from the top. The pointer names it as nested under the Phase 6 closure heading and
discloses the ambiguity in band. `### Still open at Phase 6 close` is unique.
**The four-record disposition audit found 0 DISAGREE.** `ROADMAP.md`, `beets.md`,
`deferred-items.md` and `REQUIREMENTS.md` were quoted verbatim under labelled headings with
**heading-text locators, never line numbers**, then scored on five named checks each carrying a
verdict word from the closed set `{AGREE, DISAGREE, COULD NOT LOOK}`. No `beets.md` correction was
forced, no owning plan had to be named, and **the `REQUIREMENTS.md` ABORT branch did not fire** — so
this plan files a `-SUMMARY.md`, which in this repo is read as *plan complete* on filename existence
alone, and the filename is earned.
**⚠ `deferred-items.md` is SILENT on two of the five checks** (the MA half being discharged, and the
checkbox state) — measured three ways. It is verdicted **COULD NOT LOOK**, not DISAGREE, and **no
owning plan is named for it**: silence is not contradiction, and naming `06-50`/`06-51` for a
non-divergence would have shipped a phantom correction into `06-DISPOSITIONS-GAP4.md`.
**The artifact records EXPLICITLY that ROADMAP's `In Progress` is CORRECT and must not be flipped to
`Complete`**, with `06-VERIFICATION.md`'s `gaps_found` 5/6 as the reason — because a consistency
audit is exactly the document a later reader could misread as a mandate to make four records agree by
moving a status word.
**⚠ Four zero-expecting counts, all four DRIVEN against a control first** (`DEF-06-45-04` class):
the line-citation screen (control **2**, real **0**), the bracketed forbidden-token screen (control
**1**, real **0**, plus a third drive proving `-cE` reads `[R]` as a character class), the
ticked-CONF-04-checkbox screen (control **1**, real **0**, with the unticked recipe returning **1**
so the 0 is not the 0 of an absent line), and the "Phase 6 is complete/passed" screen (control **1**,
**0** on all four records). Every grep by absolute path.
**`REQUIREMENTS.md`, `ROADMAP.md` and `deferred-items.md` are byte-unchanged**, asserted with
`git diff --exit-code HEAD -- <path>` — the `HEAD --` is load-bearing, because a bare
`git diff --exit-code <path>` compares against the **index** and is blind to a staged edit, and this
plan stages. **Zero estate contact**: no ssh, no docker, no package install. Nothing about CONF-04
changed, no checkbox moved, and `06-VERIFICATION.md` was not re-scored.
**⚠ `total_plans` in this file's frontmatter was STALE at 119 and is corrected here to 124.** Round 6
added seven plans to phase 6 (45 → 52) and the project counter was never bumped, so `completed_plans`
was about to reach 119 of 119 and read as *every plan done* with `06-48..06-52` still outstanding.
72 (phases 1–5) + 52 (phase 6) = **124**; 72 + 47 executed = **119**. The arithmetic closes both ways.

**ROUND 6, WAVE 2 EXECUTED 06-48 — 2026-09-24. A recipe that could never have matched the thing it
forbids is replaced by one PROVEN to match it, and the bracketing convention's scope is now a written
decision instead of an open observation.** Two task commits (`da5a606`, `bcdefd0`) plus the summary
(`645d2d3`); one artifact, `artifacts/06-48-recipe-control-and-scope.txt`, sections 1–6. **BASE
COMMIT `ce358779329c4e37112a843bba877883e9a238f9`**, captured by `git rev-parse HEAD` before anything
was written, because every immutability claim in the plan is anchored to it and not to a moving
`HEAD`.
**The control matrix was driven BOTH WAYS and is the plan's whole point:** against a one-line scratch
control carrying the forbidden mode's real unbracketed token, the corrected `-cE` form returns **1**
and the published `-cF` form returns **0**. `-F` and a bracketed needle are **mutually exclusive by
construction** — `-F` suppresses exactly the metacharacter interpretation the bracketing mitigation
depends on — so `06-43-conf04-verdict.txt` SECTION O's `(O-a)` could only ever have measured the
mitigation form. `(O-b)` was **already sound** (`-ciE`) and was driven against its own control (**1**)
as a confirmation, not a correction; `(O-c)` is untouched. The fix is **surgical to `(O-a)`**.
**Counts RE-DERIVED, not restated:** the corrected recipe and the unchanged `(O-b)` run per file over
SECTION O's four named artifacts plus `06-43-conf04-verdict.txt` plus
`scripts/check-music-consumers.sh` and `scripts/quick-health-check.sh` — **0 on all fourteen
readings**, with § 1 named in band as the drive that makes those zeros evidence.
⚠ **BOTH HALVES ARE STATED WITHOUT EITHER BEING SOFTENED INTO THE OTHER: the published `0` is TRUE of
the estate, AND it was not earned by the command printed beside it.** A true number from a vacuous
instrument is the worst shape there is, because it survives review.
**The dated artifact is PROVEN IMMUTABLE AGAINST THE BASE COMMIT, not merely clean at the end:**
`git show <BASE>:…06-43-conf04-verdict.txt | /sbin/sha256sum` and the working file both read
`d85ebe4b…` (`shasum -a 256` agreed, so the digest is not an artefact of one implementation), and
`DEF-06-45-04`'s own body digests `b86042f3…` on both sides — it is **closed by `DEF-06-48-01`
referring to it, not by anything written into it**. The plan drove WHY that anchor is needed: with an
edit **staged**, `git diff --exit-code protected.txt` exits **0** while
`git diff --exit-code HEAD -- protected.txt` exits **1** — and even `HEAD --` is blind to an edit the
plan itself committed, which happened twice here.
**`DEF-06-48-02` DECIDES the bracketing convention's scope: it STAYS `artifacts/` — NOT widened to
`ROADMAP.md` prose, NOT dropped.** Scoped by **function, not directory name**: any file whose content
is counted by a published recipe must bracket the counted token. ROADMAP is deliberately readable
prose and has never been in a published detector's counted scope, so widening pays a readability cost
for zero measurement benefit; dropping is equally wrong, because inside `artifacts/` the hazard is
live and has fired six rounds running. The occurrence count was **re-measured at 2** with the
corrected `-cE` form and both sites named by **surrounding heading and table row, never by line
number** — the verification's own two citations for these same sites were **already stale**. The
entry states explicitly that **no `ROADMAP.md` edit is made or required**, so nobody "finishes the
job" later.
⚠ **THE SELF-REFERENTIAL HAZARD FIRED INSIDE THE ENTRY DESCRIBING IT — SEVENTH CONSECUTIVE ROUND.**
`DEF-06-48-02`'s first draft quoted its scratch control line PLAINLY, and the plan's zero-expecting
line-citation screen over the two new entries then returned **1** instead of 0: the entry had become
an occurrence of what it measures, and a naive reading of that 1 would have said *a line citation was
written*. Bracketed (`ROADMAP.md:[1]615`) and re-measured at **0**, with the scratch control keeping
the plain form so it still returns 1. Caught, as every previous instance was, **by measuring AFTER the
edit landed, not by an assertion written beforehand** (`DEF-06-39-06`).
**Register integrity anchored to the base commit:** `^## DEF-` headings **41 → 43** (= base + 2), with
**0** base-commit heading strings missing — no existing entry renumbered, reworded or removed.
**`ROADMAP.md`, `REQUIREMENTS.md` and all of `scripts/` byte-unchanged under `git diff --exit-code
HEAD --`** at both task commits (the ROADMAP progress row and 06-48 checkbox were bumped afterwards,
in the metadata commit, hand-edited with the body diffed: exactly 2 lines, Notes cell byte-length
identical at 33,550). **Zero estate contact** — no ssh, no docker, no HTTP verb, no package install,
no snapshot taken or destroyed; the three scratch controls lived outside the repository and none was
staged. Nothing about CONF-04 changed, no checkbox moved, and `06-VERIFICATION.md` was not re-scored.

**ROUND 6, WAVE 2 ALSO EXECUTED 06-49 — 2026-09-24. `CLAUDE.md` said "Conventions not yet
established" while the six reviewed scripts enforced a dozen load-bearing ones; the repository now has
an authoritative root-level `CONVENTIONS.md`, and the `CLAUDE.md` block is its proven mirror.** Two
task commits (`0d9c6f2`, `51ca680`) plus the summary (`4259b93`); **no artifact** — this plan wrote no
script, no planning document and made no estate contact. **BASE COMMIT `3fd748d`**, captured before
anything was written, because both byte-identity claims are anchored to it and not to a moving `HEAD`.
**The structural fact that decided the deliverable was MEASURED, not assumed:** `CLAUDE.md`'s
`## Conventions` section is a GSD block whose opening marker **names its own source**
(`GSD:conventions-start source:CONVENTIONS.md`) — and that file **did not exist at the repo root**. So
the authoritative deliverable is the SOURCE and the block is downstream of it; writing the index into
the generated block alone would have left the next regeneration to overwrite or orphan it. This also
resolves `06-REVIEW.md`'s own confused reading that "the repo's own `CONVENTIONS.md` is currently
empty" — it was absent, not empty.
**`CONVENTIONS.md` is 319 lines / 13 `## ` sections / 20 lines citing `scripts/`, and every entry
names a canonical example BY FILE AND SYMBOL, never by line number** (citations here go stale on
arrival). It covers fail-closed three-state exits, Linux-side bounding, assert-don't-report, the
additive-only override contract, pinned counts, the deliberately duplicated destructive fence,
credentials-never-in-argv, the bracketing convention, grep hygiene, commit-anchored byte identity, the
`📊 N. Summary` grep anchor, the in-band-narrative rule, and per-round ID namespaces.
**⚠ CONVENTION 4 IS THE PLAN'S WHOLE DISCIPLINE AND GETTING IT BACKWARDS WOULD HAVE SHIPPED THE EXACT
"docs describe intent, not reality" DEFECT THIS REPO HAS RECORDED.** The redder-only rule's canonical
example is the `_Q` override guards in `quick-health-check.sh`, each of which sets `EXIT_CODE=1`
**unconditionally** when its knob moves off the default — the rule enforced by MECHANISM.
`DECLARED_INTERP_EXPECTED` is the repo's one live knob that does **not** obey it mechanically, and it
appears in the same entry **under an explicit exception clause** quoting its own header's *"a red to a
green BY DECLARATION — it resolves nothing"*, naming 06-46's remediation prohibition as the governing
control, and stating in one clause that **a rule enforced by policy is weaker than one enforced by
mechanism**. The entry ends by instructing the reader not to cite it as the exemplar.
**WR-03's fix option (b) is delivered** as the pinned-count entry, naming all four live pins by symbol
(`DECLARED_INTERP_EXPECTED`, `TAGGER_DEF_EXPECTED`, and `ST_PLANNED_CASES` in BOTH
`check-beets-config.sh` and `phase06-oracle.sh`), the remedy 06-46's failure arms now print, and the
harder rule this phase learned twice: **a pin over a set with environment-conditional members must
adjust where the condition is decided, or it is a constant pretending to be an invariant.**
`DEF-06-48-02`'s decided scope is written down with its `-cE`-never-`-cF` rule and the
drive-against-a-control rule.
**⚠ THE MIRROR IS PROVEN BY ORDERED NAME-FOR-NAME CORRESPONDENCE, NOT BY A COUNT FLOOR — and the
comparator was DRIVEN RED FIRST.** `|A| == |B| == 13` and `B[i]` contains `A[i]` at every index; the
identical loop run against a copy of B with entry 3 mutated from `Assert, do not report` to
`Assert, and also report` **failed at index 3**. A `>= 8` floor is satisfiable by eight WRONG names,
which is precisely how a mirror goes quietly stale while passing its own check.
**Both GSD marker lines are byte-identical to the base commit** (`cmp -s`), the diff is a single hunk
(`@@ -349 +349,16 @@`) strictly inside the marker pair, and the text OUTSIDE the span is byte-identical
on both sides at the correct offsets — head lines 1–346 through the start marker, tail 33 lines from
the end marker to EOF (base `350..` vs now `365..`). `Architecture not yet mapped` still reads **1**:
the architecture half of IN-01 is dispositioned ACCEPTED in `06-50` and **`ARCHITECTURE.md` was
deliberately NOT created**, because the estate is already mapped by `NETWORK.md`, `MEDIA.md`,
`DEPLOYMENT.md` and `TAILSCALE.md`, all four linked from `CLAUDE.md` § Documentation.
**⚠ Four zero-expecting counts, all four DRIVEN against a control first** (`DEF-06-45-04` class): the
line-citation screen (control **1**, real **0**), the forbidden-mode `-cE` screen (control **1**, real
**0**, with the `-cF` form returning **0** against the same control as a second independent re-drive of
`DEF-06-48-01`), the UI-option `-ciE` screen (control **1**, real **0**), and
`Conventions not yet established` (control = `git show <base>:CLAUDE.md` → **1**, real **0**). Every
grep by absolute path; every control outside the repository and none staged.
**⚠ ONE MEASURED CORRECTION TO THE SOURCE MATERIAL, RECORDED IN BAND RATHER THAN RESTATED.**
`06-REVIEW.md` § WR-02 and this plan both quote `check-beets-config.sh` at **1,223** lines; `wc -l`
measures **1,222** today. The measured figure is what `CONVENTIONS.md` carries, with the review's
beside it — a conventions file that quotes a stale count inside the entry ABOUT stale in-band counts
would be self-refuting. The other two are exact (`quick-health-check.sh` **3,148**,
`phase06-oracle.sh` **3,274**) and `set -euo pipefail` is at line 124, so "the first 123 are header"
is correct.
**⚠ Convention 13 is written as a FORWARD POINTER, not a present-tense fact:** `06-DISPOSITIONS-GAP4.md`
does not exist — `06-50` writes it at wave 3, after this plan at wave 2 — so the entry says "will live
in" and names its author. A conventions file asserting a future artifact in the present tense is stale
the moment that plan changes shape or halts.
**`scripts/` byte-unchanged under `git diff --exit-code HEAD --` at both task commits**; no planning
document was touched by the task commits (the ROADMAP row bump 48/52 → 49/52 and the 06-49 checkbox
happen only in the metadata commit, hand-edited with the BODY diffed: exactly 2 hunks, phase-6 Notes
cell byte-length identical at 33,488 by `awk` field split). **Zero estate contact** — no ssh, no
docker, no HTTP verb, no package install. **No script was executed at all** — not `--self-test`, not
`bash -n` — because no executable file changed, so instrument state at HEAD is exactly what 06-46 last
measured and is deliberately NOT restated here as though re-driven. Nothing about CONF-04 changed, no
requirement checkbox moved, and `06-VERIFICATION.md` was not re-scored.

**ROUND 6, WAVE 3 EXECUTED 06-50 — 2026-09-24. Round 6 PLANNED plans 06-46 … 06-52; plans
06-46 … 06-50 have executed at the time this block was written, and 06-51 and 06-52 have NOT.**
`06-DISPOSITIONS-GAP4.md` is the round's register (536 lines): **4 FIXED, 0 FIXED (undriven),
1 ACCEPTED, 0 CARRIED — 5 total**, reconciling three ways — the review's frontmatter 0+3+2, the
dispositions 4+0+1+0, and the fix kinds **1 CODE + 3 CLAIM CORRECTION + 1 BOTH**. Two task commits —
`21eaad4` (the register) and the commit carrying this block; no artifact and no estate contact.
**BASE COMMIT
`3085da162460448aba1eb151ad4cabac390abbb1`**, captured before anything was written, because every
byte-identity claim is anchored to it and not to a moving `HEAD`.
**⚠ THE ID ALIAS, FIRST BECAUSE EVERY CITATION DEPENDS ON IT.** `06-REVIEW.md` reuses round 1's
`WR-*`/`IN-*` namespace, already cited in band across all six scripts — **39** pre-existing citations
of the five reused IDs and **94** across the whole namespace, measured at the base commit and
**identical at the pre-round tree `75c7989`**, which is the mechanical proof round 6 added none. The
round's IDs are `R6-01 … R6-09`, minted **up front in the fix plans** rather than aliased afterwards
(`DEF-06-39-01`), and the mapping table sits in the register immediately after its Source table,
before any citation is used in prose.
**The five findings and their dispositions:** `R6-01 (WR-01)` **FIXED** — the only
`shellcheck -S warning` finding across the six scripts, so the set is clean on all six where it was
clean on five; `R6-02 (WR-02)` **ACCEPTED**; `R6-03 (WR-03)` **FIXED** — both of the review's own fix
options delivered, the failure arms naming the literal edit and `CONVENTIONS.md` naming all four live
pins by symbol, with the third site `ST_PLANNED_CASES=7` deliberately untouched (`DEF-06-39-02`);
`R6-04 (IN-01)` **FIXED** — `CONVENTIONS.md` written and `CLAUDE.md`'s block proven a name-for-name
mirror by a comparator driven red first, with the **architecture half ACCEPTED and `ARCHITECTURE.md`
deliberately NOT created**; `R6-05 (IN-02)` **FIXED** — a heading-text pointer at the head of
`beets.md`, deliberately not the line-number form the finding itself suggested.
**`R6-02 (WR-02)` — the extreme comment-to-code ratio — is ACCEPTED with reasoning, not fixed: a bulk
strip of round-by-round narrative out of the six most heavily reviewed files, at the end of a
recursion in which every round's diff became the next round's findings, risks losing the reason a
fail-closed branch exists on instruments that run against ~103 containers, so the durable half is
taken as a forward rule (`CONVENTIONS.md` convention 12) and the round binds itself instead.** That
self-binding is **measured, not asserted**: one file under `scripts/` changed, **+6 / −1** lines, of
which 3 are single-line `R6-01`/`R6-03` citations and 2 are emitted failure output, with **0** lines
of new in-band historical narrative and **0** new `WR-*`/`IN-*` citations.
**The recipe correction and the scope decision are round items, outside the five-finding
reconciliation:** `R6-06` closed `DEF-06-45-04` — the `-cF`-over-a-bracketed-needle detector that
could never match, corrected to `-cE` and driven both ways against a control (`-cE` → 1, `-cF` → 0) —
and `R6-07` **DECIDED** the bracketing convention's scope in `DEF-06-48-02`: it **stays `artifacts/`**,
scoped by **function not directory name**, **not widened to `ROADMAP.md` prose** and **not dropped**,
with no `ROADMAP.md` token edit made or required. Re-measured after this plan's own edits, the
whole-file count of the forbidden token in `ROADMAP.md` is **2 at the base commit and 2 now** — round
6 added no third occurrence while deciding the convention.
✅ **THE TWO OPERATOR ACTIONS HAVE BOTH EXECUTED, AND THEIR REAL OUTCOMES ARE RECORDED HERE.**
Written into this block by **`06-52` task 3 at wave 5**, replacing the two `06-50`-era entries that
stated no outcome because neither plan had run when this block was written at wave 3. Both plans
carried legitimate halt/hold branches; **neither halted.**

**`R6-08` — the host `git pull --ff-only` sync of LXC 100 at `/mnt/fast/stacks` (plan `06-51`, wave 4).
Answer: `proceed`. Disposition: `FIXED`.** The operator's verbatim words, in order — *"ok i have
completed an investigation "* and *"i hit enter to quick the last time, did not wait for the clean up
to complete - done now"* — at **`2026-09-24T21:28:39Z`**. ⚠ **This was a CLEARING of STOP condition
S4, not an override — the override field is NO.** S4 (three stash entries on the production checkout,
dated 2026-03-09, 2026-03-09 and 2025-10-03) **fired** at the first pre-flight, which returned 4 CLEAR
/ 1 STOP and offered no unqualified `proceed`; the operator disposed of the entries and the re-run
gate read **5 CLEAR / 0 STOP**, measured before any write. *An override says we wrote to a host we had
measured as unsafe; a clearing says we made the host safe, then wrote to it.* Both stages stand.
The host moved **`ee82fb2` → `b9c09b5`** (41 commits, fast-forward); **6 of 6** instrument scripts
sha256-MATCH per file where the pre-flight read **3 MATCH / 3 DIFFERS**; nothing was redeployed,
proven on all three of `name|image|status` with the set difference empty both ways at **99 = 99**
containers and a census of 98 `Up` + 1 `Exited(0)`. **`DEF-06-45-05` item 2 is CLOSED** and
**`DEF-06-29-11` is CLOSED**. ⚠ **`DEF-06-39-05` is UNBLOCKED BUT NOT CLOSED** —
`quick-health-check.sh` was deliberately not run and has now been executed **zero** times across
rounds 3, 4, 5 and 6; an unconditional "unblocked" here would be a false readiness line. Detail:
**`DEF-06-51-01`**.

**`R6-09` — the `tank/media/Music@pre-06-41-conf04-reprobe` release go/no-go (plan `06-52`, wave 5).
Answer: `hold`, with the release condition made MECHANICAL. Disposition: `CARRIED`.** The operator's
verbatim answer at **`2026-09-24T22:29:38Z`**, load-bearing passage: *"Don't defer to Phase 7 planning
(option 3) — planning is a document, not a fence, and the item drifts again. Make the release
condition mechanical and already-scheduled: Release tank/media/Music@pre-06-41-conf04-reprobe when
Phase 7 Success Criterion 1 is satisfied — new snapshot taken on the same dataset and rollback
exercised — not when Phase 7 is planned. That's an event someone already has to produce evidence for,
so the item closes on a commit rather than on remembering. Disposition CARRIED, one named trigger, no
judgement left in it."* `defer` was explicitly rejected; `release` was rejected on the executor's own
self-raised counter-argument, which the operator took over the executor's stated recommendation.
⛔ **Nothing was destroyed, rolled back or released** — the only `zfs` verb issued on any branch was
`list`, and both the target and `tank/downloads@pre-phase5` (a different fence, entry criterion
**E4**, out of scope on every branch) were re-asserted PRESENT read-only after the decision at
2026-09-24T22:32:01Z. **`DEF-06-45-01` stays OPEN**, disposition **CARRIED**, its release condition
rewritten in place into one mechanical trigger: release when **Phase 7 Success Criterion 1 is
SATISFIED** — a new snapshot **taken** on the Music dataset and rollback **exercised** — not when
Phase 7 is merely planned. Detail: **`DEF-06-52-01`**; and **`DEF-06-52-02`**, the process defect
filed at the operator's direction, which records that a criteria-only read of Phase 7's
entry-criteria block would have answered "the pilot fence is not planned" **by omission** — it failed
safe here and would fail unsafe were the omitted thing a prohibition — promoted to `CONVENTIONS.md`
convention 14. A separate, independent correction landed in the same plan: the stale *"`tank` has
~9 T free"* figure in `DEF-06-45-01` and `CLAUDE.md` § Constraints is now the measured **5.26 T**.
Both plans' register rows are closed in `06-DISPOSITIONS-GAP4.md` § *ROUND CLOSE*, whose Counts
reconciliation is extended there over all nine round items.
**`D-R6-M4` — the operator's decision, 2026-09-24: `ROADMAP.md`'s `Plans Complete` column means
EXECUTED, not authored** (the Phase 4 precedent row reads `16/16` with its status cell still
`In Progress`, noted "All 16 plans executed"). So the numerator written this round is the **measured**
count of `06-NN-SUMMARY.md` files present in the phase directory — **49** when plan 06-50's task 2
wrote it, and **50** once 06-50's own summary landed and the identical recipe was re-run, never
`52/52` — and `06-52` at wave 5 closes it. The `Plan:` line above carries the same measured figure,
so the two records cannot disagree.
**⚠ RE-VERIFICATION HAS NOT BEEN PERFORMED BY THIS ROUND.** Plan 06-50 records dispositions; it ran
**no** `/gsd-verify` and claims **no** verification result. **Do not read "round 6 complete" as "phase
complete"** — that is the verifier's call. `REQUIREMENTS.md` was **not touched** (asserted
byte-unchanged under `git diff --exit-code HEAD --`), the unticked `- [ ] **CONF-04**` box **stands**
(measured 1 unticked / 0 ticked, the ticked recipe driven to 1 against a control first), no checkbox
moved, `ROADMAP.md`'s Phase 6 status cell still reads `In Progress`, and `06-VERIFICATION.md` stands
at `gaps_found`, **5/6**, un-rescored. **`/gsd-verify 06` is the next step, after `06-51` and `06-52`
have run.** No script was edited by this plan (`git diff --exit-code HEAD -- scripts/` returns 0), no
`state.*` or `roadmap.*` SDK verb was invoked, and there was **zero estate contact** — no ssh, no
docker, no HTTP verb, no package install.

Previous: Phase 05 (inbox-structure-and-the-junk-gate) — **COMPLETE, closed 2026-09-19 at 4/4
criteria TRUE**, 11 of 11 plans (fence taken, `_inbox` created, D-21 inode
proof driven; criteria 2/3/4 amended in band and criterion 4 now asserted by the standing check; the
junk gate built and its refusals and positive control driven; **the sweep has RUN** — 40 rows
removed, 4 moved, 8 excluded entirely, every affected path attributed to an approved row by
`zfs diff`, `lidarr-import` retired and Phase 1's D-23 closed; and the **`Now!` tag inventory is
durable again and D-04 is CLOSED** — 4,746 ffprobe records under `/mnt/fast`, zero failures, the
+13/+9/+14 surplus shown to be a grouping artefact of an album tag that cannot separate three
editions, and the 24-entry gap shown to be COLLISION rather than absence; **05-06 produced the
approvable mapping and moved nothing** — 4,751 rows, 119 manifest directories reduced to exactly
115 volume folders under a driven total-coverage assertion, the two instruments disagreeing on
**0 of 4,746** files, and the 23 flatten collisions reduced by the variant-edition merge to **4**
cross-volume cases, every one decided by the file's own `album` tag with the rejected claim
recorded in the map row; and **05-07 APPLIED the split** — the operator approved the mapping with no
amendments, the approval bound to `sha256 9ef5da2b…` which was re-read unchanged both before the
first rename and after the last, **4,750 inode-preserving renames** producing 115 flat `Vol 001`…
`Vol 115` folders holding all 4,746 mp3 with **zero directories at depth 2** and zero mp3 left at the
collection root, the affected set reconciled to the approved map by `zfs diff` at **0 off-map,
0 unrenamed, 0 unattributed and 0 deletions**, the per-volume identity computed from the resulting
tree landing on the pre-declared 11-row exception set exactly, and the **QUAL-01 before-state
captured complete** at 4,746 records with a zero-tag-field count of 0; and **05-08 proved the
album rule on paper and wrote nothing** — `normalise-dj-tags.py` gained a SECOND, NARROWER fence
(`--collection now`, root = the one collection folder, snapshot = `tank/downloads@pre-phase5`) with
`SCRATCH_ROOT` byte-identical and no constant equal to `/mnt/tank/downloads`, plus rule 4, which
derives the canonical album from the `Vol NNN` FOLDER and never from the album tag; the dry run
produced **4,746 proposals across 115 folders, one value per folder, 115 distinct values forming
exactly 1…115**, `album` the only field and rule 4 the only rule, 0 refusals and 0 failures, with
**volume 36's three spellings — including the double-space one — collapsing to a single value across
all 40 files**; only **751 of 4,746** files are actually wrong, in 22 volumes, 21 of which carry the
same missing exclamation mark, and the other 3,995 are recorded as `noop` rather than rewritten;
NOTHING WAS WRITTEN, proven by an identical 4,751-file mtime/size fingerprint either side and by
`zfs diff` showing **0 `M` lines on any mp3**; and both new self-test cases were proven able to FAIL
from mutated copies, one of them catching `save(v1=UPDATE)` regenerating the ID3v1 block — the
`audio_md5` hazard — in the act; **⚠ that plan's `zfs diff` evidence is now known to be vacuous — see 05-09**)
**05-09 HAS WRITTEN.** D-10's album repair is complete: **751 in-place tag writes across 22 volumes**, piloted on `Vol 036` (the operator amended the plan's `Vol 077`, which has zero proposed changes and would have passed its gate vacuously) and gated before the remaining 715. `album` is the ONLY field that changed on any file — asserted mechanically, 740 changed keys and one distinct field name — and `audio_md5` moved on NONE, which is the direct measurement that Phase 7's diff join survived. Each of the **115 volume folders now carries exactly one album string** (117 distinct values before, 115 after), read by a parser that is neither mutagen nor ffprobe. The 3,995 already-correct files were never written: a second `--apply` reports 4,746 no-ops and moves 0 mtimes. ID3v2 frame set and ID3v1 trailer are byte-identical to `@pre-phase5` on all 4,746, instrument driven to FAIL. **⚠ `zfs diff` is NOT a valid scope instrument on this collection** — 05-07 renamed every mp3, and `zfs diff` collapses renamed-and-modified into a single `R`, so it reports 0 `M` lines on any mp3 whether 751 files were written or none; replaced with a two-arm content control against the snapshot. Atlantis rebooted mid-verification under two concurrent whole-collection reads; 4,751 files were re-fingerprinted across it and **0 moved, 0 lost, 0 new** — no write was in flight.
**05-10 HAS CHOWNED — but not the chown D-24 described.** D-24 asked for "all 209,039 entries"; the survey measured **233,824**, of which **222,376** were not `568:568`, and the breakdown changed the decision: **84% of it was `dropbox/`** (196,327 entries of `code/`, `Archive/`, `Documents/`, `Projects/` — not downloads), 11% was `mac-music-archive/` (23,874 music entries **no phase has ever counted**), and `google takeout/` was being read by an **active** `takeout-import.service` throughout. The operator **narrowed the scope to 26,005 entries**; 26,005 + 196,371 excluded = 222,376, so the arithmetic closes and nothing was quietly dropped. **139 rows, 7 s of chown**, and `zfs diff` against a FRESH baseline returned exactly **`M 26005`** with zero `+`, `-` or `R` — the approved scope to the entry, and not one line under any excluded path. Library proof **0 lines**. The approved roots read back from atlantis at **37,191 entries, ZERO not `568:568`**. `dropbox/` and `google takeout/` proven untouched by a 330-line owner+ctime fingerprint (sha256 identical) that was **driven to FAIL** first. **⚠ D-24's preserved counter-argument is FALSE and was amended in band**: uid 3000 is outside every LXC 100 idmap range, has no passwd entry, and SABnzbd's own output is `568:568` — it is an orphan uid sitting on archives, not the download client. **⚠ `incomplete/` needed nothing** — the subtree D-24 singled out as the risky inclusion was already 100% correct. **⚠ The 115 `Vol NNN` dirs were never `root:root`** — that was 05-09's container view; on disk they were `100000:100000`. **⚠ ZFS devids have already moved** — `05-INBOX-PATHS.md`'s 68/76 read 70/75 a day later; never assert on a devid. D-25 holds: **no standing check, and there will not be one.**
**05-11 HAS CLOSED THE PHASE — 4/4 criteria TRUE, 0 FAIL, every one RE-MEASURED from live state**
rather than carried forward from the plan summaries. Evidence:
`host:/mnt/fast/safety/phase05/phase05-final-assertions.txt`, committed as
`artifacts/05-11-final-assertions.txt`. **C1**: six `_inbox` dirs, devid shared with `unsorted/` and
`dj-mixes/`, 0 `_inbox` datasets, 0 equivalents under `media/` to depth 3, and the D-21 inode proof
**driven again after the chown** — `(70, 295296)` → `(70, 295296)` same-dataset, `→ (43, 128)`
across. **C2** (against the D-12/D-14/D-15 amendment): 0 `_FAILED_`/`_UNPACK_` dirs and 0
`.rar`-form files outside `99-quarantine`, `lidarr-import` **absent**, the exclusion shown
non-vacuous by re-running without it. **C3** (against the D-02/D-05/D-08 amendment), measured by a
purpose-written read-only `ffprobe` walk that neither split the collection nor wrote its tags: 115
depth-1 `Vol 001`…`Vol 115`, 0 at depth 2, 4,746 mp3 summing to the live total, 0 at the root, 0
probe failures, **0 volumes carrying more than one `album` value**, **manifest-only entries 0**, and
the 11-row exception set matching the pre-declared post-merge list **11 for 11**. **C4** (D-22's
AFTER half): `Library underscore-dir guard: ✅ No '_'-prefixed directories under
/mnt/tank/media/Music`; the negative control was **deliberately not re-driven**, the 2026-09-18
05-02 run is cited instead. **⚠ Read C4 from the BLOCK's verdict line — `quick-health-check.sh`
exits 1 on the pre-existing `interpolated-host-path inventory MOVED: expected=12, found=13` gate,
the only red line in the run, so the script's exit code is non-discriminating.**
**⚠ Devids moved AGAIN**: 68/76 → 70/75 → **70/81**. **⚠ The inode-34 collision is THREE-way** —
`downloads`, the library **and** `/mnt/fast`. **⚠ `-iname '*potter*'` is no longer a valid test** —
it now matches a real song the split moved into `Vol 066`; assert the named path.
**Open at close, none of them a FAIL:** the `interpolated-host-path` gate; `mac-music-archive/`'s
23,874 uncharacterised music entries; an Immich API key on `takeout-import.service`'s command line;
`dropbox/` inside nine `rw` binds. **The fence `tank/downloads@pre-phase5` MUST NOT be destroyed
before Phase 6 signs off** — it is the only undo for 4,750 renames, 751 tag writes and 26,005
chowns, and it is **not** a clean undo.

**ROUND 3 REVIEW IS IN, AND THE PHASE WAS DELIBERATELY NOT VERIFIED ON IT — 2026-09-22.**
`06-REVIEW-GAP2.md` (commit `766b2d0`, findings `R3-01..R3-10`) reviewed round 2's OWN changes to
the four scripts: **0 Critical, 5 Warning, 5 Info, status `issues_found`**. No reproducible false
green was found, and round 2's substantive fixes were confirmed correct (GC-01 here-strings,
GC-13 counter split, GC-02 fence narrowing, GC-03 condition P), with a *Verified-and-clean*
section recording nine adversarial checks that passed so round 4 cannot re-litigate them.
**The pattern it did find: round 2 closed several defect classes PARTIALLY and then wrote in-band
comments claiming they were closed COMPLETELY** — the same drift the round existed to remove.
Three confirmed independently by the orchestrator:

- **R3-01** `quick-health-check.sh` — the new GC-17 comment at `:1426` asserts "There are FOUR
  such sites in this file"; more survive, and `:2118`
  (`docker exec sabnzbd sh -c 'cat \"$EXTCONF_PATH\"'`) is the hand-escaped-quote construction the
  SAME comment forbids sixty lines earlier. That site reads the `requireBeetsMatch` guard — the one
  value standing between `audio.bash` and `rm -rf "$1"/*`. Warning, not Critical: operator-set knob,
  safe default, injection consequence is static reasoning.

- **R3-02** `phase06-oracle.sh` — `ST_RUN` is never compared against an expected constant, so the
  self-test banner goes green over an unenumerated set. `check-beets-config.sh` added exactly this
  guard (`ST_PLANNED_CASES`, gated at `:788`) in the SAME round; the oracle — the file whose harness
  certifies the `rm -rf`/`rm -f` receiving-side fences — did not get it. Strongest candidate for
  promotion to Critical.

- **R3-05** `quick-health-check.sh` — `grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` returns **17** against
  **13** notice headers; plan 06-26's GC-09 tail repair added a raw match, so the file's own drift
  detector now carries a false baseline.
R3-03 and R3-04 are the mirrors of corrections made in the same round (GC-15 fixed the sending side
only — the local `awk '$2 == p'` consumer still cannot key a whitespace path; and the layer-3 AFTER
block asserts a measured RED over a could-not-look, the inverse of GC-05).
**Verification was NOT run on purpose.** Round 2 exists because round 1 was verified 6/6 *before
anyone read its own diff* and still carried a BLOCKER; verifying now, with five confirmed Warnings
in the file, would repeat that mistake one level deeper. Operator chose **gap-closure round 3**
(2026-09-22). Plan it against `06-REVIEW-GAP2.md`.

**ROUND 3 IS DONE — 2026-09-23. Plans 06-30..06-33 closed all ten findings and plan 06-34
dispositioned them in `06-DISPOSITIONS-GAP2.md`: 9 FIXED, 1 FIXED (undriven), 0 ACCEPTED,
0 CARRIED, reconciling three ways to 10** — the review's frontmatter 0+5+5, the dispositions
9+1+0+0, and the fix kinds **4 CODE + 3 CLAIM CORRECTION + 3 BOTH**. `06-REVIEW-GAP2.md` is
**WIRED** to that register. Ownership: 06-30 R3-01/R3-05, 06-31 R3-02/R3-03/R3-04/R3-06,
06-32 R3-09/R3-10, 06-33 R3-07/R3-08. **There was no cross-family adjudication this round** — round
2 had one, round 3 did not, and that is stated rather than left ambiguous, because an absent
adjudication nobody mentions reads like a lost one.
**The round's character, and the reason the fix-kind column exists:** the dominant defect class was
**a claim broader than its code**, so for several findings the honest fix was to narrow the sentence
rather than widen the code. Ten undifferentiated FIXEDs would have reproduced, one level up, the
exact over-claim the review is about. **Three refusals are recorded as loudly as the fixes** —
06-32 refused the best-effort `/tmp/p6-mf.*` sweep, and 06-33 refused both R3-08's third-conjunct
gate (implied by the other two conjuncts, therefore vacuous) and wiring
`assert_beet_invocation_contract` live. **What was NOT driven is recorded per finding:** the whole
layer-3 block (R3-03, R3-04) is reachable only from a live `--run` and is proven offline; the
`SIGTERM` behaviour behind R3-09 is static reasoning about POSIX `sh` (the single FIXED-undriven
row); and **`quick-health-check.sh` was not executed at all**, by the review or by the fix.
**Instruments re-measured at HEAD after this round, not carried forward from any plan's text:**
`phase06-oracle.sh --self-test` exit **0**, now **gated** on a pinned `ST_PLANNED_CASES=134`
compared against `ST_RUN` as its own arm before the banner (an ablation deleting `self_test_fences`
gives exit 1 at 111 ran / 134 announced, where the old gate passed it green);
`check-beets-config.sh --self-test` exit **0 / 7 cases** (`ST_PLANNED_CASES=7`);
`phase06-incremental-control.sh --self-test` exit **0**; `bash -n` clean on **all four** scripts;
and `sh -n` clean on **both extracted in-container programs** (`manifest.sh` 65 lines,
`taghist.sh` 31) — the gate `bash -n` cannot give, since it parses heredocs as data. Round 3's
residue is carried by name as `DEF-06-34-01`..`DEF-06-34-06`, and the part that closes only on a
live run attaches to the **existing** entry criterion **E12**; **no new criterion was added.** One
correction to the review is recorded in band: **R3-07's census figure was wrong and its finding is
not** — `assert_beet_invocation_contract` gives 4 raw hits at the reviewed tree and 5 now, not
"exactly two"; exactly two are *code*, so the conclusion stands.
**⚠ RE-VERIFICATION HAS NOT BEEN PERFORMED.** Plan 06-34 records dispositions; it did **not** run
`/gsd-verify` and claims **no** verification result. **Do not read "round 3 complete" as "phase
complete"** — that is the verifier's call. `REQUIREMENTS.md` was **not** touched and no checkbox
moved.
**Still open, unchanged by round 3:** CONF-04's Jellyfin half (Phase 7 entry criterion **E6**),
CR-01's residue (**E10**), WR-09 (**E11**), and round 2's undriven-until-the-pilot residue
(**E12**, `DEF-06-29-05`), which round 3's undriven residue now also attaches to.
**Is a round 4 warranted? Stated both ways, because it is the operator's call and not this plan's.**
Against: round 3 found **zero Critical** and no reproducible false green, and most of its fixes were
claim corrections — the marginal return has fallen sharply, and the next step is **`/gsd-verify 06`**.
For: a fourth review of round 3's own diff is **the same discipline that caught both previous
rounds**, and round 2 exists precisely because round 1 was verified 6/6 before anyone read its diff.
It should be a **deliberate decision**, not an omission.

**ANSWERED 2026-09-23 — the operator chose round 4, and it earned its keep.** Reviewed deep against
`fff070a..HEAD` (round 3's own 320-line diff across the four scripts), written to
`06-REVIEW-GAP3.md`: **0 Critical, 6 Warning, 4 Info**. The "For" case was right. Three Warnings
were re-verified independently by the orchestrator against the code, not taken from the review:

- **WR-02** — `ST_PLANNED_CASES=134`, round 3's **centrepiece** fix, is a fixed constant compared
  with `-ne` against a self-test carrying documented env-conditional skips (root skips 1+4, no
  python3 skips 2). As root it runs 129, without python3 132, and the gate then prints *"A SECTION
  DID NOT RUN"* when every section ran. **A false red with a wrong stated cause** — the fix made
  the instrument less trustworthy than it found it. Not a false green.

- **WR-03** — both new `INT TERM HUP` handlers in `phase06-incremental-control.sh` carry no `exit`
  and no re-raise, so POSIX resumes the shell: a SIGTERM deletes the scratch dir and the program
  **keeps running and exits 0**. The in-band claim names only the SIGKILL residual.

- **WR-05** — `check-beets-config.sh:434` says the raw count "is 4". It is **5**; it was 4 at
  `fff070a` and the recipe line the *same hunk* added made it 5. The self-referential measurement
  error, recurring inside the fix for it.
`06-REVIEW.md` was NOT overwritten — verified byte-identical (round 1's record is cited by ten
files). Round 4's report took the `-GAP3` suffix, continuing the `-GAP`/`-GAP2` convention.

**Operator decision 2026-09-23: the round against `06-REVIEW-GAP3.md` was authorised and planned as
plans 06-35 … 06-39** (waves 16 and 17). *(That decision was recorded here at the time under the
label "GAP-CLOSURE ROUND 5"; it is the phase's **fourth** gap-closure round and is called round 4
throughout the register, the ROADMAP and the block below. The label is corrected rather than deleted,
because the off-by-one is exactly the kind of thing a later reader reconstructs wrongly.)*
Verification is deferred behind it — deliberately, for the reason round 2 exists: round 1 was
verified 6/6 *before anyone read its diff*. **`/gsd-verify 06` has still NOT been run since round
2**, and the phase is NOT complete. No requirement checkbox moved by round 3 or round 4; CONF-04's
Jellyfin half remains OPEN under **E6**.

**ROUND 4 IS DONE — 2026-09-23. Plans 06-35..06-38 closed all ten findings and plan 06-39
dispositioned them in `06-DISPOSITIONS-GAP3.md`: 9 FIXED, 1 FIXED (undriven), 0 ACCEPTED,
0 CARRIED, reconciling three ways to 10** — the review's frontmatter 0+6+4, the dispositions
9+1+0+0, and the fix kinds **3 CODE + 3 CLAIM CORRECTION + 4 BOTH**. `06-REVIEW-GAP3.md` is
**WIRED** to that register. Ownership: 06-35 R4-01/R4-07/R4-08, 06-36 R4-02/R4-06/R4-09/R4-10,
06-37 R4-03/R4-04, 06-38 R4-05. **There was no cross-family adjudication this round either** — round
2 had one, rounds 3 and 4 did not, and that is stated rather than left ambiguous.
**⚠ THE ID ALIAS, FIRST BECAUSE EVERYTHING ELSE DEPENDS ON IT.** Round 4's report reuses round 1's
`WR-*`/`IN-*` namespace, and round 1's IDs are **already cited in band in all four scripts** — 72
pre-existing citations across them at the review's own diff base `fff070a`. The fixes are therefore
written in band as **`R4-01` … `R4-10`**, and the mapping table lives in `06-DISPOSITIONS-GAP3.md`
immediately after its Source table, with a pointer at the top of `06-REVIEW-GAP3.md`'s wiring block.
**Round 4's `WR-02` is `R4-02` and is NOT round 1's `WR-02`**, which is a live citation in
`phase06-oracle.sh` about empty manifests. The rule this establishes — a review's ID namespace must
be unique per round and chosen *before* the review is written — is `DEF-06-39-01`.
**The round's character, and it is uncomfortable: round 3's own centrepiece fix was round 4's
largest finding.** `ST_PLANNED_CASES=134` is a fixed constant compared with `-ne` against a self-test
carrying three *documented* environment-conditional skips, so it printed **"A SECTION DID NOT RUN"
when every section ran** — a false red with a wrong stated cause, firing most readily on the machines
least likely to be the operator's. And **a documented prohibition survived a second consecutive round
inside the file documenting it**: the four live instances of the ⛔-forbidden hand-escaped-`\"` shape
sat **eight to eleven lines below the prohibition paragraph itself**, under a sentence added in the
same hunk declaring the class closed.
**Instruments RE-MEASURED at HEAD after this round, not carried forward from any plan's text:**
`phase06-oracle.sh --self-test` exit **0** at **140** announced cases — the base is now **skip-aware**
(each of the three environment-conditional arms decrements it beside the `warn` that reports its own
skip), so the figure is valid only in the **named reference environment**: macOS 27.0 (darwin),
**non-root (uid 501)**, **`python3` PRESENT**, bash, BSD grep at `/usr/bin/grep`, BWK awk. ⚠ **134 is
stale** — it is what `06-REVIEW-GAP3.md`, `06-REVIEW-GAP2.md` and `06-DISPOSITIONS-GAP2.md` all
record, and the six cases R4-06 added moved it; the finding's conclusion is unaffected, only the
number. `check-beets-config.sh --self-test` exit **0 / 7 cases** (6 of them red, `ST_PLANNED_CASES=7`
untouched and excluded from the audit by name); `phase06-incremental-control.sh --self-test` exit
**0**; `bash -n` clean on **all four** scripts; and `sh -n` **and** `/bin/dash -n` clean on **both
extracted in-container programs** — the gate `bash -n` cannot give, since it parses heredocs as data.
**Three refusals are recorded as loudly as the fixes** (`DEF-06-39-02`): **no cleanup `trap` was added
to `phase06-oracle.sh`** under R4-10 — that file has none anywhere by design and one would fire on the
forensic `exit 3` arms too, destroying the evidence they exist to preserve; **`ST_PLANNED_CASES=7` in
`check-beets-config.sh` was excluded from the count audit by name**, because it is a gated pin over an
unconditionally executed set and "fixing" it would have broken a working guard; and the four live
layer-3 `awk` copies were deliberately **not** hoisted, per `DEF-06-29-03`.
**What was NOT driven is recorded per finding:** `quick-health-check.sh` was executed **zero** times
in round 4 either, by the review or by plan 06-35 — every R4-01/R4-07 assertion is a capture (`echo`,
never sent) or a grep (`DEF-06-39-05`); the oracle's layer-3 block is still reachable only from a live
`--run`, so R4-06's six new cases prove the **parser**, not the block (`DEF-06-34-04`); and the
container-side signal behaviour is **still unobserved inside `beets-flask` on both paths** — the
`timeout`→SIGTERM path graded **NOT ESTABLISHED**, the new SIGPIPE path **BELIEVED at the same static
grade and explicitly not an upgrade**, with SIGKILL the unclosable residual (`DEF-06-39-04`,
`DEF-06-34-06`). That residue attaches to the **existing** entry criterion **E12**; **no new criterion
was added.** Round 4's residue is carried by name as `DEF-06-39-01`..`DEF-06-39-06`, and no existing
`DEF-` entry was renumbered, reworded or removed (30 → 36 entries).
**Three corrections to the source material are recorded in band:** `ST_PLANNED_CASES` was already
stale at 134 before round 4 touched it; the **ID namespace collision**, which is a defect in the
review's form and not in its findings; and **two self-referential-measurement instances that fired
during round 4's own execution**, in the plans closing that very class — plan 06-35's first draft of a
census explanation matched the pattern it was widening, and plan 06-38 mis-pinned raw counts three
times inside its audit *of* the hazard. Both were caught by **measuring after the edit landed**,
neither by an assertion. That is the fourth consecutive round for this hazard, and the first in which
it also turned up **inside the `<automated>` verify blocks** rather than the code (`DEF-06-39-06`).
**⚠ RE-VERIFICATION HAS NOT BEEN PERFORMED.** Plan 06-39 records dispositions; it did **not** run
`/gsd-verify` and claims **no** verification result. **Do not read "round 4 complete" as "phase
complete"** — that is the verifier's call. **`/gsd-verify 06` has still NOT been run since round 2.**
`REQUIREMENTS.md` was **not** touched and no checkbox moved.
**⚠ `06-VERIFICATION.md` IS STALE and was deliberately NOT touched.** It records round **1's**
closure, dated 2026-09-22, with `status: passed` and `gaps_remaining: []` — written before rounds 2,
3 and 4 existed. A passing verification sitting beside four gap-closure rounds is exactly the artifact
a future reader closes a phase on. It is named as stale here, in `06-DISPOSITIONS-GAP3.md` and in the
ROADMAP disposition paragraph — three places, because one is where a reader does not look.
**Still open, unchanged by round 4:** CONF-04's Jellyfin half (Phase 7 entry criterion **E6**),
CR-01's residue (**E10**), WR-09 — round 1's — (**E11**), and the undriven-until-the-pilot residue
(**E12**, `DEF-06-29-05`), which round 3's and now round 4's undriven residue both attach to.
**Is a round 5 warranted? Stated both ways, because it is the operator's call and not this plan's.**
Against: round 4 found **zero Critical** and **no reproducible false green**; three of its ten fixes
changed no executable line at all; and round 3's stated exit condition was *a review whose findings
are Info-only and whose fixes are claim corrections* — round 4 is closer to that than round 3 was.
The next step on that reading is **`/gsd-verify 06`**. For: a fifth review of round 4's own diff is
**the same discipline that caught all three previous rounds**, and round 4 found four live instances
of a forbidden shape that three previous rounds had walked past, eleven lines below the paragraph
forbidding it. If a round 5 is commissioned, **give it a fresh `R5-*` ID namespace before it is
written** (`DEF-06-39-01`) and **sweep its `<automated>` blocks for raw self-referential counts before
executing** (`DEF-06-39-06`). It should be a **deliberate decision**, not an omission.

**ROUND 5, WAVE 18 EXECUTED — 2026-09-24. Plan 06-40 took the complete before-state for CONF-04's
Jellyfin re-probe and WROTE NOTHING.** One artifact,
`artifacts/06-40-conf04-reprobe-before.txt`, 1,810 lines, sections 0 through 9. Three commits,
one per task (`d5f49cd` Jellyfin, `f309bdb` filesystem, `69cd2a8` touch list).
**The round's premise is LIVE and was measured, not assumed:** `PreferNonstandardArtistsTag` reads
**`true`**, `UseCustomTagDelimiters` / `SaveLocalMetadata` / `EnableRealtimeMonitor` all **`false`**,
each read with `has($k)` rather than jq's `//` (which treats `false` as empty and would report a
correctly-false option as ABSENT). The Music library `ItemId` was **read back** from
`/Library/VirtualFolders` and asserted equal to the pinned `JELLYFIN_MUSIC_LIBRARY_ID` — a mismatch
would have meant the whole round was aimed at a recreated object.
**The three pinned rows read 0, 1, 1 — exactly the 2026-09-20 Jellyfin baselines.** Nothing moved,
so nothing needed escalating; the plan's halt condition did not fire. The census is **1,244** with
`TotalRecordCount` equal to the returned array length (a short answer would have been COULD NOT
LOOK, never "fewer files"), the length distribution is identical to 06-03's, and the six OQ-1
`TRUSTFALL` DO-NOT-RESCAN rows are listed by name with their entity Ids.
**On disk, read from atlantis as REAL ROOT** — never from LXC 100, whose sparse idmap surfaces
unmapped ids as `65534`: the three pinned files exist at `568:568` / `0777`, with mtimes recorded
to the second in UTC **and as epochs**, so the artifact is TZ-proof. All **91** `.nfo` are hashed
individually (Phase 1's number, unmoved), beside `.lrc` **944** and `.jpg` **88** with a
path+size+mtime fingerprint each. `tank/media/Music@pre-06-41-conf04-reprobe` is asserted **ABSENT**
with `grep -qxF` (so a name merely *containing* it could not satisfy the test), and the D-32 fence
`tank/downloads@pre-phase5` is **PRESENT**. beets' own state is fingerprinted: `library.db`
`fbbdde0c…` and `state.pickle` `f6a9a1ad…` under `/mnt/fast/appdata/arrs/beets/config`, the
`beets-flask` `/config` bind read back from `docker inspect` rather than assumed — and its `/media`
bind reads **`ro`**, which is D-05's fence, while Jellyfin's reads `rw` and always has.
**The touch list is DERIVED, not retyped.** `check-music-consumers.sh` was shipped to atlantis over
ssh STDIN from a quoted heredoc, its sha256 asserted byte-identical to the workstation copy
*before* parsing, and the three paths extracted from `ARTIST_PROOF_ROWS` and prefix-substituted.
All six assertions PASS — 3 lines, all `test -f`, all beginning with `/mnt/tank/media/Music/` by
`index()==1` rather than a substring match, `TRUSTFALL` substring count **0**, `cmp -s`
byte-identical on the reverse substitution including the U+2019, and three content sha256 values —
plus an **independent seventh** (`grep -qF` of each reversed path against the script) that shares no
code with the `awk` extractor, so a bug in the extractor cannot satisfy both.
**⚠ ONE MEASURED CORRECTION TO THE PLAN'S OWN TEXT, RECORDED IN BAND RATHER THAN SMOOTHED:**
06-40-PLAN.md states the Jellyfin container "is at 192.168.90.25 today" and that 06-03's
`192.168.90.17` is therefore stale. `docker inspect` returned **192.168.90.17** at run time. The
RULE is untouched and is the entire point — docker IPAM *can* move it, so it is resolved fresh and
never pinned — but writing the plan's number instead of the measured one is exactly the drift this
phase exists to stop.
**⚠ `zfs get atime tank/media/Music` is `off`** (relatime `on`), recorded so an atime-driven
surprise in 06-42's `zfs diff` is anticipated rather than mysterious. `sha256sum` reads; it does
not write.
**NOTHING WAS WRITTEN, and that is a measurement:** GET only, zero POST/PUT/DELETE, zero snapshots,
zero permission changes and none attempted (`chmod` fails `EPERM` on `tank` even as real root under
`aclmode=restricted`). The `tank/media/Music` snapshot set was re-read twice after the first read
and was byte-identical both times, and all four `/tmp` scratch files were deleted and verified
absent — `/tmp/06-40-*` on atlantis is empty.
**⚠ STATE.md WAS CORRUPTED AGAIN BY A `state.*` WRITE AND WAS REPAIRED BY HAND IN THIS PLAN'S
COMMIT.** The `Plan:` line had been replaced with a bare `Plan: 1 of 45`, orphaning
`dispositioned all 24 findings of 06-REVIEW.md…` as a dangling fragment, and `Status:` likewise
orphaned `against 06-REVIEW-GAP.md…`. Both continuations were rejoined; **nothing was deleted**.
This is the fourth recorded instance of that defect class. **Always `git diff .planning/STATE.md`
after any `state.*` write**, and prefer a hand edit.
**Nothing about CONF-04 changed.** No requirement checkbox moved, `06-VERIFICATION.md` was not
touched and is **still stale**, and CONF-04's Jellyfin half is still OPEN with **E6** owning it.
06-40 is the before-state; **06-41 is the plan that mutates, and it is `autonomous: false`** — it
gates on the operator, mints the snapshot and touches exactly the three files proved above.

**ROUND 5, WAVE 19 EXECUTED — 2026-09-24. Plan 06-41 HAS WRITTEN. The lever 06-03 named and never
pulled has been pulled, and it is the first write into the Music library since Phase 1 sealed it.**
One artifact, `artifacts/06-41-conf04-reprobe-drive.txt`, 693 lines, SECTIONS A and B. Two commits,
one per driving task (`2410058` the fence and the touch, `4961271` the refresh).
**The operator gate was answered `proceed`** (task 1, `checkpoint:decision`), presented with all six
required items read out of the 06-40 artifact and with its own verify measuring the snapshot count
at **0** immediately before presenting — nothing had been written at that moment.
**THE FENCE CAME FIRST AND IN THE SAME REMOTE STEP AS THE MUTATION**, so the two could not come
apart: `zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe` returned 0 and was **listed back and
asserted equal** before any file was touched. The touch list was **re-derived and all seven
assertions re-run** rather than carried forward — 06-40 proved it against a tree that had since been
snapshotted — from a copy of `check-music-consumers.sh` shipped over ssh STDIN from a quoted heredoc
and sha256-asserted `1ed695cf…` **before** parsing; `TRUSTFALL` substring count **0**.
**The permission was probed with its own no-op form first** (`touch -r f f` — the same `utimensat`,
setting each file's times to the values it already held) on all three, so an `EPERM` would have been
a recorded negative and a stop rather than a discovery mid-mutation. All three returned 0.
**Three mtimes moved and not one byte of audio did:** each mtime strictly newer than 06-40 Section
5's value, each content sha256 **identical** to Section 9 (f), sizes unchanged.
**`zfs diff` against the fence came back clean — three `M` entries, zero non-`M`, exactly three
distinct paths and all three pinned, zero metadata/lyric/image sidecars, zero DO-NOT-RESCAN rows.**
That one command proves both "only three files moved" and "nothing was written into the library"
from a single source, on a 33.9 GB dataset Jellyfin, Music Assistant and the operator all depend on.
**ONE WRITE VERB IN THE WHOLE PLAN:** a file-scope `POST /Library/Media/Updated` carrying three
`{Path, UpdateType:"Modified"}` entries built by `jq` from the derived list (nothing hand-escaped),
returning **204** — and **Jellyfin's `LibraryMonitor` named all three Audio items by full internal
path**, U+2019 included, **60 s later, matching `LibraryMonitorDelay = 60` exactly**. The API key
travelled via `-H @<(printf ...)` and never entered argv; no header value is recorded.
**⏱ THE SETTLE IS A SUBTRACTION, NOT A SENTENCE:** `POST_UTC: 1790237579` was written immediately
after the POST returned; the read-back began at 1790237714, **135 s** later. 06-42 recomputes that
from the epoch independently rather than inheriting a prose claim.
**Zero** metadata-save, image-save or sidecar lines in the log window, recorded as the literal word
`no`; and the four D-34 options plus `SaveLyricsWithMedia` were **re-read AFTER the refresh** with
`has($k)` and every one held. The endpoint audit shows **exactly one line beginning with `POST`**,
both prohibited scan endpoints are named descriptively only, and `FullRefresh` counts **0** over the
whole artifact.
**⚠ TWO DEFECTS IN THIS PLAN'S OWN INSTRUMENTS, RECORDED RATHER THAN SMOOTHED — NEITHER TOUCHED THE
ESTATE.** (1) The `zfs diff` path decoder ran `sed 's/\0/\/g'` before `printf %b`; zfs writes a
space as `\0040`, the sed rewrote it to `\40`, and a digit of the following filename was eaten —
`CD 01-03` decoded as `CD 1-03`. Assertions (6b)/(6c)/(6d) FAILED over a block that was **correct
from the first capture**. The three FAIL verdicts are **left standing in the artifact and annotated
in band**, with the corrected verdicts recomputed against a re-read proved byte-identical by
`cmp -s` — so the repair is a **read**, not a second mutation. `printf %b` already decodes `\0nnn`;
the sed was the entire bug. (2) That same overflow emitted **three NUL bytes** into the report,
caught only because `file` reported `data` rather than `text`. **Screen committed text artifacts for
NUL, not only for credentials.**
**⚠ `grep` IS A SHELL FUNCTION ON THE WORKSTATION AND SILENTLY MATCHED NOTHING** — several searches
over a file whose content was demonstrably present returned empty. Every screen was re-run with
`/usr/bin/grep`; the plan's `<automated>` blocks run under `bash -c`, which does not inherit it, and
both passed. **A tool that answers "no matches" when it was never really consulted is the exact
false-green shape this phase exists to remove.**
**⚠ `grep -c $'\000'` AND `awk 'index($0,"\000")'` ARE VACUOUS NUL TESTS** — the needle reduces to
the empty string and matches every line; both reported NULs in files that had none. The honest
instrument is a byte-count comparison across `tr -d '\000'`. Fifth consecutive round for the
self-referential-measurement class (`DEF-06-39-06`). Also: **`ls` under `pipefail` returns 2 on an
empty glob** and briefly looked like a failed cleanup; `find` returns 0. `/tmp/06-41*` is empty on
**both** atlantis and LXC 100.
**⚠ THE JELLYFIN ADDRESS IN 06-41'S OWN CONTEXT IS WRONG AGAIN** — it says 192.168.90.25;
`docker inspect` returned **192.168.90.17**, which is 06-40's measurement. Neither literal is
transcribed as a constant anywhere; the route is resolved fresh on every call.
**⚠ `tank/media/Music@pre-06-41-conf04-reprobe` IS NOW STANDING AND IS THE ONLY UNDO FOR THIS ROUND.
It must not be destroyed before 06-43 records its branch.** Rollback, one line:
`zfs rollback tank/media/Music@pre-06-41-conf04-reprobe`.
**WHAT THIS DOES NOT ESTABLISH, stated because 06-42 depends on the distinction:** the refresh
**started** and reached the three Audio items themselves — the thing whose absence would make a null
result uninterpretable, since an unmoved census is consistent both with "never started" and with
"started and found nothing". It does **NOT** establish that the prober re-read the `ARTISTS` tag, and
it does **NOT** establish that any `ArtistItems` row moved. That is **06-42's** measurement, and a
null result there is a **legitimate recorded negative** — not an argument for a wider refresh.
**Nothing about CONF-04 changed yet.** No requirement checkbox moved, `06-VERIFICATION.md` was not
touched and is **still stale**, and CONF-04's Jellyfin half is still OPEN with **E6** owning it.

**ROUND 5, WAVE 20 EXECUTED — 2026-09-24. Plan 06-42 HAS MEASURED, AND THE ANSWER IS NO. The lever
06-41 pulled did not move the rows.** Two artifacts —
`artifacts/06-42-conf04-reprobe-after.txt` (654 lines, SECTIONS C–K) and
`artifacts/06-42-consumers-rerun.txt` (352 lines) — and three task commits
(`8b1b917`, `ee82fb2`, `f85e539`).

**THE MEASUREMENT.** All three pinned rows read **AT-BASELINE**: row 1 (ARTPOP / *Jewels n' Drugs*)
at **0** browseable `ArtistItems` entities against a target of **4**; rows 2 and 3 at **1** each
against a target of **2**. The `;`-in-entity-name count is **0** on every row, reported FIRST for
each row as `check-music-consumers.sh` § 4b checks it. Every verdict is emitted twice — as prose and
as a fixed eight-field parseable line — and **every one survived independent recomputation** from
its own `target`/`baseline`/`measured`/`uniqids`/`semis` by § 4b's own five-step order, so a
misclassification would have failed a script rather than resting on the agent that wrote it.
⏱ **The settle is arithmetic across two files, as designed:** `READBACK_UTC: 1790257176` minus
06-41's `POST_UTC: 1790237579` = **19,597 s** against a floor of 120, recomputed by the verify block
rather than read from the `SETTLE_SECONDS` line.

**THIS IS A MEASUREMENT, NOT AN UNKNOWN — and that distinction is the round's whole value.** 06-41's
`LibraryMonitor` lines named all three Audio items by full internal path, so "the refresh never
started" is **ruled out** and "the refresh started and changed nothing" is what happened.
`PreferNonstandardArtistsTag` still reads **`true`**, re-read with `has($k)`, so the option did not
revert — the prober simply did not re-read the tag on these files.
⛔ **NOTHING WAS ESCALATED.** The aggressive per-item refresh mode was not issued, not widened to
and not reachable on any branch; no second refresh, no additional file touched, and **no
`zfs rollback` executed** — the command is recorded and left for the operator.

**THE FOUR-WAY SAFETY RE-ASSERT ENDS `SAFETY: PASS`.** The post-refresh `zfs diff` is
**BYTE-IDENTICAL** to 06-41's block (sha256 `a33ada4a…` on both sides, `cmp -s`): three `M` entries,
zero non-`M`, zero sidecars, zero DO-NOT-RESCAN rows — so across the POST, the LibraryMonitor
firing, the three refreshes and five and a half hours of live estate, **ZFS records not one
additional change under `tank/media/Music`**. The `.nfo` manifest differs on **0 of 91** lines in
sha256 and mtime; all three sidecar counts and fingerprints are identical (**91 / 944 / 88**); the
four D-34 options and `SaveLyricsWithMedia` all hold; `library.db` and `state.pickle` are
byte-identical; `tank/downloads@pre-phase5` is **PRESENT**. **The 1,244-row census delta is
EMPTY — 0 changed rows, 0 differing lines over all five fields, no path on one side only** — and the
six OQ-1 `TRUSTFALL` rows are unchanged in count and Id set, so the negative control held. That one
block carries two facts and neither is softened into the other: nothing outside the three moved,
**and the three themselves did not move.**

**THE INDEPENDENT CORROBORATION WAS TAKEN HERE, BEFORE ANY BRANCH IS COMPUTED** — relocated out of
06-44 by the round's own revision, so the one automated cross-check that could catch a wrong branch
has already run when 06-43 asks the operator. The **deployed, unmodified**
`check-music-consumers.sh` ran from `/mnt/fast/stacks` with no override and reported
`INSTRUMENT RUN: MEASURED`, `HOST CHECKOUT: MATCH`, `JF_AT_TARGET: 0`, `JF_PENDING: 3`
(**summing to the 3 pinned rows**), `MA_AT_TARGET: 2`, `MA_REPORTED: 1`, ending on **3** with
`FAILURES total: 0` — the pending gate, not the failure gate, exactly as the EXIT-CODE CONVENTION
predicts. **No line of any script was changed to make it end on 0**, and the Jellyfin and MA
counters are recorded side by side and never summed. Two instruments by two routes, one answer.

⚠ **THREE DEVIATIONS RECORDED RATHER THAN SMOOTHED.** (1) 06-40 records the `.lrc`/`.jpg`
**fingerprint values but not the command that made them**, so the recipe was **recovered against
06-40's own `.nfo` hash as an oracle** — four candidate constructions computed, exactly one
reproduced `e99b1992…`; guessing would have made the comparison a test of the guess rather than of
the estate. (2) **The host checkout went STALE mid-plan, by this plan's own two commits**, and the
plan's own named remedy was applied — push, `git pull --ff-only`, re-verify, re-run — rather than
relaxing the test or writing `MEASURED` over a `STALE`. (3) **06-41's claim that the host's copy of
`check-music-consumers.sh` is pre-Phase-6 (`c67d497`) with no `ARTIST_PROOF_ROWS` is MEASURED
FALSE** — the host copy is byte-identical to the repo copy (`1ed695cf…`) with a clean working tree.
Corrected in band so a later reader does not re-derive the old conclusion and invent the copy step
the plan forbids.

**STILL NOT A CLOSE.** No requirement checkbox moved, `06-VERIFICATION.md` was not touched and is
**still stale**, and CONF-04's Jellyfin half is still **OPEN**. **06-43 owns what the negative
means**, behind its operator gate, and `tank/media/Music@pre-06-41-conf04-reprobe` **is still
STANDING** as the undo for the whole round — it must not be destroyed before 06-43 records its
branch.

**ROUND 5, WAVE 21 EXECUTED — 2026-09-24. Plan 06-43 HAS COMPUTED THE VERDICT AND THE OPERATOR HAS
CHOSEN WHAT IT MEANS.** One artifact, `artifacts/06-43-conf04-verdict.txt` (443 lines, SECTIONS
L–P), two commits (`88857e3` the branch and the round audit, `7775a3d` the operator decision).

**THE LINE IS `BRANCH: B` — THE MTIME HYPOTHESIS IS RECORDED DISPROVEN — AND IT WAS COMPUTED, NOT
CLAIMED.** The plan's five-step rule was evaluated strictly in order over four recorded inputs, and
the plan's own `<automated>` verify block **independently recomputed the same value from the same
lines** and would have failed the task on disagreement, so the conclusion does not rest on the
agent that wrote it. Rule 1 did not fire (`SAFETY: PASS`); rule 2 did not fire
(`INSTRUMENT RUN: MEASURED`); rule 3 failed on **all three** conjuncts (AT-TARGET count 0 not 3,
`JF_AT_TARGET` 0 not 3, `JF_PENDING` 3 not 0); **rule 4 fired on all three.** SECTION L's `ROW`
verdict block was **extracted with `sed` and spliced with `awk` over a placeholder rather than
retyped**, then `diff`ed against 06-42's inside the verify — a transcription slip between the
measurement and the verdict could not survive, U+2019 included.
**⚠ THE EXIT CODE AND BOTH MA COUNTERS ARE RECORDED AND ARE EXPLICITLY NOT INPUTS**, stated inside
the rule rather than left implicit: `check-music-consumers.sh` exits **3 on branch A and branch B
alike** because `MA_ARTIST_PENDING` stays 1 either way, and an exit code that cannot distinguish A
from B cannot decide between them. A surviving `MA_REPORTED: 1` does **not** disqualify branch A,
and a green MA half may **never** offset a pending Jellyfin one — the script's own point (c),
applied at the one step where it would have been easiest to break.

**THE OPERATOR SELECTED `negative-carry-e6`**, recorded verbatim in SECTION P at
**2026-09-24T14:30:37Z UTC**. That is option **(a)** of `06-VERIFICATION.md` § Recommended path:
record the negative and **carry CONF-04's Jellyfin half to Phase 7 entry criterion E6 under an
explicit override**, so the roadmap's existing argument becomes **auditable rather than implicit**.
The branch-A acceptance option was neither offered nor selected on a `BRANCH: B`, so **no refusal
is recorded, because none occurred**.
**WHAT THE DECISION DOES NOT AUTHORISE, each named so it is not inferred:** ticking CONF-04 — **the
box at `REQUIREMENTS.md:152` STAYS UNTICKED**, because an override is a recorded, argued carry of
an OPEN requirement and must never be written as a close; re-scoring `06-VERIFICATION.md` to 6/6 —
that is **`/gsd-verify 06`'s call**, which 06-45 *recommends* rather than performs, and this plan
set does **not** self-declare a pass; any further refresh, any wider refresh mode, or the
aggressive per-item mode — **the hard fence is untouched by this decision and is unreachable from
it**; releasing either snapshot; or closing E6.

**THE ROUND-WIDE AUDIT, MECHANICAL AND DELIMITED:** 0 occurrences of the forbidden mode's literal
token across **all five** round-5 artifacts, 0 occurrences of the forbidden UI button's phrase,
**1 write verb for the entire round** (06-41's single file-scope `POST` → 204), **0 files changed
content**, **3 files changed mtime**, and **both snapshots PRESENT** — `tank/downloads@pre-phase5`
(D-32, Phase 7 entry criterion E4) and `tank/media/Music@pre-06-41-conf04-reprobe`, the latter
recorded as **STILL HELD, NOT RELEASED**: its release is a **separate operator decision**,
deliberately not bundled into this gate. Every count carries the instrument that produced it. No
`zfs rollback` was executed by any plan in this round.
**⚠ ONE DEFECT IN THIS PLAN'S OWN ARTIFACT, CAUGHT BY MEASURING AFTER THE EDIT LANDED AND RECORDED
IN BAND RATHER THAN SMOOTHED: the file MATCHED THE DETECTOR IT PUBLISHES.** SECTION O declared the
forbidden UI button's phrase written in bracketed form and published a count of **0**, while the
prose carried it **PLAINLY, TWICE** — in the hard-fence paragraph *forbidding* it and in SECTION
P's does-not-authorise list — so `/usr/bin/grep -ciE` over the file returned **2** against a
published **0**. The count over the four *source* artifacts was never wrong; what was wrong is that
this file was itself an occurrence of its own detector. Both were rewritten to the bracketed form,
an **`in this artifact`** audit row was added so the number is **asserted rather than assumed**,
and the top paragraph now states why it brackets the phrase *even while forbidding it*. **Sixth
consecutive round for the self-referential-measurement class (`DEF-06-39-06`)**, and the second
consecutive round in which it was caught by a **post-edit measurement** rather than by an assertion
written beforehand. **Screen a committed artifact against its OWN published detectors, not only for
credentials and NULs.**

**⚠ E6's SECOND MEASUREMENT IS NOT CLOSED BY THIS ROUND AND STAYS WITH PHASE 7** — whether a second
≥4-artist track yields four artists in Music Assistant or three, the only measurement separating
"MA caps the list at 3" from "`Twista` specifically failed to map". Round 5 never had it in scope,
took no step toward it, and produced no evidence bearing on it. **E5 is named in the artifact too:**
row 1 of `ARTIST_PROOF_ROWS` is one of the 30 items carrying a populated `Artists` string list with
**zero** linked artist entities, which is why a per-file refresh that performs no artist-entity
creation was always the weakest lever on that particular row.
**STILL NOT A CLOSE.** No requirement checkbox moved; `06-VERIFICATION.md` was not touched and is
**still stale**; `stacks/selfhosted/arrs/beets.md` is untouched; and CONF-04's Jellyfin half is
still **OPEN** — now with an **explicit, operator-signed override** carrying it to **E6**, which
**06-44 and 06-45** write. Both downstream plans **read the `BRANCH:` line** rather than
re-deriving the conclusion from the measurements.

**ROUND 5, WAVE 22 EXECUTED — 2026-09-24. Plan 06-44 HAS MADE THE INSTRUMENT'S PROSE TRUE, AND
CHANGED NOTHING ELSE.** Two prose-corrected scripts, two task commits (`646583a` for
`scripts/check-music-consumers.sh`, `8cac538` for `scripts/quick-health-check.sh`), **no artifact
and no estate contact** — this plan issued no HTTP, no ssh and no write outside the repository.
Every sentence in the standing CONF-04 drift detector and in the health entry point that named
**Phase 7 as the single owner** of the Jellyfin half's discharge now states the round-5 truth: the
mtime lever those very sentences named was **DRIVEN on 2026-09-24 inside a ZFS snapshot fence and
measured NOT to discharge it** — ZERO of three rows moved, the 1,244-row census delta was empty,
and `PreferNonstandardArtistsTag` re-read `true` afterwards, so the refresh ran, reached the items,
and the prober still did not re-read `ARTISTS`. **The Jellyfin half is written as CARRIED to Phase 7
entry criterion E6 under the recorded override, never as closed**, and the scripts say so in those
words in five places: the `target`-column paragraph, the EXIT 3 point (c), section 4b's PENDING
echo block, the `artist rows PENDING (JF)` summary line and the exit-3 banner.
**THE VERDICT WAS EARNED ON UNTOUCHED CODE AND THIS PLAN DID NOT RE-RUN IT.** The instrument
reached its Jellyfin-half verdict in **06-42 task 3**, in wave 20, before the branch was computed
and before the operator decided anything. The planning order was corrected for exactly that reason,
and this plan runs strictly downstream of the gate.
**THE MECHANICAL PROOF THAT NO LOGIC MOVED, which is the whole point of the round:** the changed-line
audit over both diffs reports **0 lines that are neither a comment nor a printed message**, and **0
added `if`/`elif`/`case`/`EXIT_CODE=` lines**. No `target`, `baseline`, threshold, branch condition,
counter or exit code changed; all three `ARTIST_PROOF_ROWS` definitions survive verbatim with **both
numeric columns**; the exit ladder is intact and in order (`--baseline` 1699 < `FAILURES` 1704 <
pending 1732 < green banner 1746); `EXIT_CODE=1` stays on the exit-3 arm; the `📊 6. Summary` anchor
and the **7** `CONSUMERS_OVERRIDDEN` notices are unmoved. `shellcheck -S warning` is **byte-identical
to the pre-edit run on both files** and `bash -n` is clean on both.
**⚠ THE EXIT CODE WAS DELIBERATELY NOT TUNED.** `check-music-consumers.sh` still exits **3**, because
`MA_ARTIST_PENDING` stays **1** — a reported measured discrepancy owned by **E6's SECOND
measurement** — and it would have exited 3 on a fully successful re-probe too. Not one line was
changed to make any process end on 0, and the banner now says so in band.
**⚠ THE BASELINE COLUMN IS RECORDED AS DELIBERATELY RETAINED**, in band, so it is not tidied away
once the target is met: after E6 discharges the Jellyfin half, a row back at its 2026-09-20 baseline
is a **REGRESSION** (most likely `PreferNonstandardArtistsTag` reverting, which section 4a asserts
independently), not a wait. Deleting either numeric column trades a detector for a tidier table.
**THE CROSS-FILE CONTRACT WAS EXERCISED, NOT ASSUMED.** The rewritten exit-3 banner is 8 lines and
`quick-health-check.sh`'s arm caps its `sed` window at `1,8p` — so the banner was rendered locally
with stub counters and pushed through that **exact** pipeline: all 8 lines survive, the
`Discharges on ROADMAP` end anchor is still on the last one, and **both halves are named inside the
window a reader actually sees**. The two files' accounts of the exit-3 contract were corrected in
the same round, which is what stops the `GC-04` stale-citation class recurring.
**DEF-06-39-06, SEVENTH CONSECUTIVE ROUND, AND CLEAN — MEASURED AFTER THE EDITS LANDED, not before:**
the forbidden mode's literal token and the forbidden UI button's phrase both count **0** in
`check-music-consumers.sh`, **0** in `quick-health-check.sh` and **0** in this plan's SUMMARY, which
writes both in bracketed form for exactly that reason. Both scripts credential-screened before each
commit (the repo is PUBLIC): no password, token, key or bearer string in any added line, and a NUL
delta of **0 bytes** measured as `raw − tr -d '\000'`, never the vacuous `grep -c $'\000'`.
**STILL NOT A CLOSE, AND THIS PLAN DID NOT MOVE ONE.** `REQUIREMENTS.md:152` still carries an
**unticked CONF-04**; `requirements mark-complete` was **not** run; `06-VERIFICATION.md` is untouched
and still stale; `stacks/selfhosted/arrs/beets.md` is untouched; and both snapshots stay held, with
no `zfs rollback` executed. **06-45 owns the record edits, behind its own gate.**

Status: Executing Phase 06 — gap-closure **ROUND 6 COMPLETE**, plans **06-46..06-52**, 5 waves,
**52 of 52 plans executed**. R6-08 executed 2026-09-24: proceed on a CLEARED pre-flight (S4 fired
and was cleared, override NO), host at `b9c09b5`, 6/6 sha256 MATCH, no redeploy. R6-09 executed
2026-09-24: **`hold`** — nothing destroyed, `DEF-06-45-01` OPEN/CARRIED with a mechanical release
trigger (Phase 7 Success Criterion 1 SATISFIED, not merely planned). `06-52` also closed the
register's `ROUND CLOSE`, `ROADMAP.md`'s `52/52` and its `52 plans in 28 waves` header, and this
file's round-6 block. **`/gsd-verify 06` is the next step and the verifier's call — round 6 complete
is NOT phase complete.** Round 5 is COMPLETE (waves 18-23, plans 06-40..06-45). Round 2 ran
against `06-REVIEW-GAP.md` (GC-01 blocker + 7 warnings in round 1's own code, plus GC-16/GC-17
from the cross-family adjudication) — all 17 closed and dispositioned in `06-DISPOSITIONS-GAP.md`
by plan 06-29. Still 1 open
requirement (CONF-04, Jellyfin half — owned by Phase 7 entry criterion E6, NOT closed here).
**Round 2 has landed, and that is still NOT a completion** — GC-03 was CR-01 one nesting level in,
so closing on "CR-01 fixed" would have been a false close; closing on "round 2 fixed it" without
re-verifying is the same shape one level further out. **`/gsd-verify 06` has NOT been run since
round 2.**
Do NOT run with `--auto`/`--chain` — four
gates are `checkpoint:decision`, which auto-selects the first option under auto-mode.

*(⚠ The three lines above were reassembled on 2026-09-18 by plan 05-01, and **the same corruption
fired again on the 05-02 write and was repaired the same way**. A `state.*` write replaces only the
FIRST line of a multi-line field, leaving its continuation dangling as an orphaned sentence fragment
— `gates are ...` under a `Plan:` line, `by a byte proof.** ...` under a `Status:` line — and it
also truncates the frontmatter `last_activity:` to a bare date and rewrites an unrelated
`Last activity:` line 560 lines further down, mid-paragraph. Nothing was deleted either time; every
fragment was rejoined to the text it belongs to. **Always `git diff .planning/STATE.md` after any
`state.*` write.** This is the same defect class as the Progress-line rewrite below.)*

**Phase 4 CLOSED 2026-09-18 at 5/5 — criterion 3 discharged by a signed override, not
by a byte proof.** Criteria 1, 2, 4 and 5 were verified by live measurement. Criterion 3's
static half is measured (`grep -cE '^[[:space:]]*beet ' audio.bash` → 0, vendored-drift guard
green); its behavioural half was never proven at the byte level. Three capture designs were
built: the destination-tree poll (window 1), the incomplete-tree poll (window 2), and
SABnzbd's own `pp` notification hook (built and self-tested in 04-17, all 14 synthetic
controls passing, **never armed**). Window 3 was closed unrun after external review of plan
04-18 by four independent AI model families found roughly 30 defects, including a judge binary
that self-reports every PASS condition — reviews preserved verbatim at
`.planning/phases/04-collapse-to-one-tagger/04-18-EXTERNAL-REVIEWS.md`. The operator signed
the prepared override on 2026-09-18, accepting the threefold unanimous side-effect evidence
(5 real jobs, 2 windows, 0 tagger artefacts) in its place. **Residual risk, stated once:** "no
evidence of tagging" is not identical to "proven absence of tagging at the byte level".
Plans 04-18 and 04-19 were never executed and are recorded as `-PARTIAL.md`, not `-SUMMARY.md`
— `04-18` in particular arms live SABnzbd config on a running container and must not be run
until its recorded defects are fixed.
**ESTATE UNTOUCHED** — `nscript_enable` still 0, `direct_unpack` still 1.

**02.1-10 COMPLETE. THE ESTATE'S ROUTINE HEALTH CHECK NOW COVERS THE THING THAT EMPTIED `/`, AND
EVERY ONE OF ITS FAIL-CLOSED BRANCHES HAS BEEN DRIVEN RATHER THAN READ.**
`scripts/quick-health-check.sh` gained a **third** fatal block — inline `ssh -n`, `RC=$?` on the very
next line, `$'\033'` ANSI stripping, anchored on the literal `📊 6. Summary`, with **both** UNKNOWN
branches present and each setting `EXIT_CODE=1`, and no second reachability probe (it inherits the
WR-10 gate). The third `EXIT-CODE BEHAVIOUR CHANGED` notice states the six conditions that can exit
the script 1 — five of which are "could not look", including an **unmounted `fast/transcode`**, which
is the least obvious and the most dangerous, since the bind still works and `zfs get quota` still
reads green while the quota covers nothing.

**Six proofs EXECUTED, not asserted.** Row 21 (`ZFS_HOST=192.0.2.1`, RFC 5737): exit 1, quota and
mounted each their own distinct red, summary `UNKNOWN` for both, never a `!= 53687091200` mismatch a
reader would parse as drift — **and the container-side device-id instrument kept answering**, which
is exactly why row 36 specifies two. Row 22 (non-existent container): exit 1, absence **reported**,
summary `volume mounts: UNKNOWN` not `0` — an empty `docker inspect` did **not** satisfy the
`result == ""` test it would have made meaningless, so no defect to fix. A third control pointed
`JELLYFIN_SECRETS` at a non-existent path (executable only because 02.1-02 made it overridable — the
alternative was chmod'ing a file whose `600 root` is an invariant another check asserts): exit 1,
section 5 UNREACHABLE with no values printed, real file `600 root` before **and** after. `--nonsense`
exits exactly **2**. Row 23 proven **without editing `quick-health-check.sh`**. Row 24: the anchor
renumbered `6.`→`7.` **while the underlying check still exited 0**, asserted separately — the UNKNOWN
branch printed and exit was 1, not the tick the WR-09 defect produces. **Every test that broke
something recorded a pre-test sha256, restored, asserted the hash (`d33356c5…` both times) and re-ran
green; both repos' `scripts/` are empty at the end.**

**⚠ THE TWO MOST USEFUL RESULTS ARE BOTH PLACES THE PLAN TEXT WAS WRONG, AND NEITHER WAS MASSAGED.**
(1) **Row 23's stated MECHANISM is false.** The plan says the ssh returns non-zero with *empty
output*, driving the empty-output branch. It does not: `ssh host "cmd 2>&1"` puts the redirection
**inside the remote command string**, so bash's own `No such file or directory` **is** captured —
output non-empty, RC 127, and the BROKEN branch fires. Row 23's actual claim (the exit code
propagates) holds regardless. The empty-output branch was then driven properly, with a **zero-byte
script**, which exposed the branch's key property: **a zero-byte script exits 0**, so `RC` was `0` —
a clean success — and the block still refused a tick, because `[ -z "$OUT" ]` is tested **before** the
return code. Reverse that order and a silently-truncated check reports green.
(2) **Two of the task's acceptance greps are non-discriminating and were ALREADY failing at the
parent commit** (raw 1 and 2): they match the notices that *explain* the `bash -s` and `\x1b`
prohibitions. The explanatory comments were **not** deleted to make them pass — that removes real
documentation to satisfy a string test. Comment-stripped substitutes return **0** against raw 1 and
3, the same device VALIDATION row 34 uses.

**One grep WAS satisfied by an edit, and the distinction is stated rather than glossed:** those two
fail because the *file is correct*; the third failed because the file's own **naming was
inconsistent** — the 02-09 notice opened "A SECOND FATAL BLOCK WAS ADDED" and never carried the shared
phrase, so a grep for the convention found one notice in a file holding two. Six words added, nothing
removed, with an in-band note. The count is now 4 (three headers plus one mention inside that note),
recorded explicitly because "prose mentioning the string satisfies a grep for the string" is
02.1-06's trap pointed the other way. Likewise the notice records **2026-09-03**, not the 2026-09-02
the criterion names: execution crossed midnight UTC, and 02.1-06 already lost a run to that exact
rollover.

**THE THREE KNOWN LIMITS WENT TO THREE DIFFERENT DESTINATIONS, chosen by who needs each one** — both
reviewers said a limit recorded where nobody reads it has not been recorded. **Manual-only (D-22)** is
in-band in `quick-health-check.sh`'s third notice, stating the thing a reader is most likely to get
wrong: *the fold-in closes the "we had no way to see it" half of the incident; it does not close the
"nobody looked for 36 hours" half.* Scheduling is deferred with its reason named — Phase 2 closed with
a notification never proven to deliver, and an unproven path is worse than a known-manual check
because it *feels* covered. **The Live TV gap (A8)** was already in `jellyfin.yaml` from 02.1-04 and
was **verified clause by clause, not duplicated** (`grep` is 1 there, **0** in PROJECT.md). **The
widened API-key blast radius** is the only one estate-wide enough for PROJECT.md, recorded as an
accepted residual risk stated as a CHOICE in the style of 02-09's `sec=sys` row: the key is
administrator-equivalent **by Jellyfin's design**, 10.11 has no scoped-key mechanism, and this phase
widened its use from read to **write**. PROJECT.md gained 3 insertions, 0 deletions.

**⚠ ONE POINTER WAS FOUND WRONG IN BOTH HALVES AND CORRECTED.** `jellyfin.yaml`'s D-11 note read "the
other **five** local Docker volumes … inventoried in **02.1-06-SUMMARY.md**". Measured: **seven**
plain local volumes (five referenced, two dangling), and the table plus the 36-versus-6 reconciliation
is in `artifacts/02.1-06-transcode-proof.txt` § 7. A pointer that points at the wrong file is worse
than no pointer, because it is checked once and then trusted.

**Nothing was implemented for any limit** — no cron, no unit, no notification code, no new or scoped
key, and **no container recreate**: `docker inspect jellyfin` still reports `StartedAt
2026-09-02T22:19:52Z`, the 02.1-05 cutover.

**THE D-32 WATCH IS CLOSED.** `/` went **21668859904 → 37022195712 bytes**; margin over the D-17 floor
**185 MiB → 14.48 GiB**, a factor of about eighty, verified with `stat -f` to the byte. 12.95 GiB of
it is 02.1-06's `docker volume rm` and 1.45 GiB is 02.1-09's reap — recorded separately, not merged.
The closing block records both what the watch bought (it fired on its first sample; three `/`-budget
grants and two ordering decisions were ruled on its lines) and what it did not: **it asserted nothing
all phase.**

**THE HONEST NOT-COVERED LIST IS RECORDED IN FULL** in `artifacts/02.1-10-negative-controls.txt`:
**six defective assertions** in this phase's own contract (VALIDATION rows 11, 15, 16, 33, 02.1-06's
task-3 verify, and two of this plan's own greps), all left failing rather than edited; **five factual
errors in plan text**; **seven open items**; and **three instrument traps**. **Five of the six
defective assertions are the same shape** — a mechanical check satisfied or defeated by *prose about*
the thing rather than by the thing — and this phase now carries the workaround in four separate
places. The load-bearing open items: the estate's **ENOSPC-keyed greps are still blind to a
transcode-quota refusal** (both `quota` and `refquota` return EDQUOT, so no property choice helps —
adding the quota-exceeded string to those greps would); **`renovate.json5` is UNVALIDATED**; and
**`check-renovate.sh` line 157 is INVERTED — it aborts when there are ZERO pending Renovate PRs, i.e.
exactly when the estate is healthy**, making its own "no pending PRs" branch unreachable, hidden today
only because 27 branches are open (remedy: `|| true` ×3, with 115 and 138).

**Explicitly checked rather than assumed: the new coverage does NOT inherit 02.1-06's
log-level-liveness hazard.** Neither the check nor the fold-in reads a log — the evidence is `df`,
`docker inspect`, `stat -c %d`, `zfs get` over ssh and one HTTP GET, every one a direct query whose
failure is distinguishable from an empty result. Recorded anyway, because the next thing folded in
may well read a log.

**And what real playback did and did not prove:** the operator watched a full episode ~22:20–22:40Z on
2026-09-02, after the cutover. It **direct-played** — zero segments, zero ffmpeg, zero bytes on `/`.
Real evidence the cutover does not break playback; **not** transcode evidence. An empty
`/mnt/fast/transcode` after a direct-play session is the *absence of a test*. The firing proofs are
02.1-06's two driven sessions.

**TRAN-05 is COMPLETE**, and with it every TRAN requirement: TRAN-01…TRAN-09 all closed.

Before that, **02.1-09 COMPLETE. THE ONE IRREVERSIBLE ACT OF THIS PHASE IS DONE, IT WENT
THROUGH THE HUMAN GATE, AND IT RAN EXACTLY ONCE.** The operator ruled **"approved unchanged"** on
all four rows — the explicit phrase 02.1-REAP-LIST.md asked for, so the record distinguishes a
deliberate no-edit from an untouched file. `reap-list.txt` was **re-validated by sha256 immediately
before the prune** (`1eaa2049…`, 4 lines, mtime still the inventory's own write); a mismatch would
have stopped the run, because it would mean the file changed under the approval.

`FLOOR_GB=20 … prune` exited 0: **removed 4, already reclaimed 0, rmi failures 0**. The script
re-derived the referenced set from `docker ps -a` (no status filter) six hours after the list was
built and found **0 conflicts**. `already reclaimed: 0` is the positive evidence this was the first
and only run — a second invocation inverts it.

**`/` went 35555835904 → 37039017984 bytes. Attributable delta 1558175744 B = 1.45 GiB**, measured
in a six-second window spanning only the prune. The plan's six-hour window reads 1483182080 B, and
**the two reconcile to the byte** once −72044544 of ordinary churn and −2949120 of post-run settling
are subtracted, which is why both are recorded rather than one being chosen. **Margin over the D-17
floor 13.11 → 14.49 GiB**, confirmed by the standing check as a second instrument.

**The per-tag diff is the evidence: four lines gone, zero added.** All five image measures move by
**exactly 4**, and the tag count moves by the same amount as the ID count — positive proof that none
of the four carried a second tag, so the multi-tagged-removal hazard did not arise. **Dangling stayed
9 → 9**: the three unreferenced untagged digests surfaced in task 1 were NOT touched. The operator did
not rule on them and scope was not expanded to them.

**⚠ THE ~1.09 GB FORECAST WAS RIGHT, AND FINDING THAT OUT REQUIRED NOTICING THE TWO NUMBERS ARE NOT
COMMENSURABLE.** The measured `df` delta was 1.45 GiB — 42% above forecast — which was investigated
rather than banked as a win. **`docker system df` Images SIZE moved 66.54 → 65.45 GB, a delta of
exactly 1.09 GB**, and that figure is deduplicated, so it is the right instrument for how much image
data left the store. The forecast's *mechanism* was right too: the 211.7 MB base was shared among the
four candidates, confirmed because the surviving `2.23` siblings still report `SHARED SIZE 205.4MB`
unchanged. **The gap is units.** `docker system df` reports *apparent* bytes; `df` reports *allocated
blocks*, and ext4 rounds every file to 4 KiB. These are Node images: `keeper-web:2.23` holds
**107,030 files** and allocates **1.342×** its apparent size — 191.2 MB of rounding overhead in one
image. This reap's implied ratio is 1.430. **Carry-forward: forecast in `docker system df`
Images-SIZE terms and expect `df` to move MORE, by ~1.2–1.4× for many-small-file images.**

**RECLAIMABLE misled again, in the opposite direction this time.** It fell only 0.21 GB (62.44 →
62.23) while 1.45 GiB of real disk was freed — where in 03-01 it *rose* 0.57 GB during an 18 GiB
reclaim. Two observations, opposite signs, same conclusion: it does not track reality and is context,
never a target. **A four-row list that freed ~1 GiB is the method working**, exactly as
§ *How this plan is measured* pre-committed.

**The estate is unharmed, and the blast radius was checked rather than assumed.** No container
changed state (`docker ps -a` diffed unfiltered, no differences; 0 `created`). The `cal-*` stack —
`keeper-sh`, internet-facing via Cloudflare with a live MCP endpoint, and the owner of all four
reaped images — is healthy: seven containers on `2.23` with **uptimes of 20–21 hours unchanged across
the prune**, which is the evidence none restarted. **cal-web genuinely serves** rather than merely
running: probed over HTTP it returns `307 → /login → 200 OK`. `check-jellyfin-transcode.sh` exits 0,
`FAILURES total: 0`, D-30 amdgpu mitigation intact.

**⚠ ONE SELF-INFLICTED DEVIATION, REVERTED AND RECORDED IN FULL.** The executor's *first* cal-web
probe used `curlimages/curl:latest` via `docker run --rm`. That image was not resident — 03-01 had
reaped it — so Docker **pulled** it, contradicting this plan's own T-021-SC ("no image is pulled").
It happened *after* every recorded measurement, so no figure was contaminated; it was caught on the
next check, removed with `docker rmi`, and the live store re-diffed **identical to the recorded
after-listing**. The probe was re-run with a resident image and it is that run quoted as evidence.
**Carry-forward: `docker run --rm <image>` is a PULL when the image is absent, and on a freshly
reaped host the generic utility images are exactly the ones most likely to be gone.**

VALIDATION row 33 is recorded **honestly**: exit 0 is *near-vacuous* on its own, because `/` already
cleared the 20 GiB floor by 13.11 GiB before the reap and the assertion would have passed had the
prune deleted nothing. Row 34 re-asserted after the run — comment-stripped grep **0**, raw **4**, so
the control is discriminating rather than vacuous. Round-2 **H1** re-checked after the run:
`grep -c 'headroom.sh prune'` over the task-3 verify block is **0**; its three `prune` tokens are the
guard comment plus the two alternatives of the read-only prohibition grep's own pattern. The script
is byte-identical to `b217ada` (`32f686f9…`, `git status` empty) — `FLOOR_GB=20` was an environment
override throughout.

Before that, **02.1-08 COMPLETE. THE TWO POLICY HOLES ARE CLOSED, AND THE SCRIPT THAT WAS
SUPPOSED TO BE WATCHING RENOVATE HAS EXECUTED FOR THE FIRST TIME IN ITS LIFE.** `renovate.json5` had
**no** `jellyfin/jellyfin` rule of any kind: Jellyfin fell through `packageRules[2]` (auto-merge
minor, `platformAutomerge`, at any time), and since Jellyfin has been on 10.x since 2019 its *de
facto* majors — 10.9 segment deletion, 10.10 lyric saving, 10.11 encoding — all presented as **minor**
and merged unattended, while `[5]` catches only major, which for Jellyfin means never. One rule now
sits at **index 38**, after `[2]` at index 2 so it wins on `automerge`: `automerge: false` on minor
**and** major, **patch deliberately NOT matched** so patch automerge survives (D-23), no
`allowedVersions` (D-24), no `platformAutomerge`. **The diff is purely additive — 19 insertions, 0
deletions — and all 38 pre-existing rules plus the top-level keys are asserted identical BY PARSE,
not by eye**; `packageRules[1]` still reads `automerge: true` / `["patch","digest"]`.

**The rule's `description` states the threat ACCURATELY, which is a correction the review demanded.**
The reviewed version implied an upgrade could revert the settings. **It cannot** — they live in
`encoding.xml` under `/mnt/fast/appdata` and swapping the image does not touch appdata. The two real
mechanisms are named instead: **semantic change across releases** (10.9 introduced
`EnableSegmentDeletion` in the first place, so a value that still reads back correctly can stop
meaning what it meant) and the estate's **documented Renovate deploy drift**, where a merged PR never
reaches the host and `docker ps` disagrees with git.

**`scripts/check-renovate.sh` line 22 tested a hard-coded `renovate.json` this repo does not have, so
lines 26-173 had NEVER EXECUTED. They ran for the first time here: EXIT 0, CLEAN**, 151 lines,
transcript committed. The review called this the phase's most likely stall; it was not. "Ran clean on
first execution" is stated explicitly rather than left as an absence of failure notes. All **four**
stale literals are gone — the plan named two (22 and 81); asserting rather than assuming found four
(22, 23, 27, 81), two of them inside the very block being replaced. A guarded `VALIDATOR_ROUTE` was
added because `grep -c renovate-config-validator` was **0**: the script called `check-renovate.sh`
**had never validated the Renovate config at all.**

**⚠ TWO THINGS THIS PLAN DID NOT PROVE, AND THEY ARE THE INTERESTING PART.** (1) **`renovate.json5`
is UNVALIDATED.** `renovate-config-validator` is not installed, installing it is out of scope
(T-021-SC), and `npx --yes` is prohibited by name. `node` parsed the file and asserted the rule's
shape — which proves **syntax and shape, not semantic validity**. An unknown key, a misspelled option
or a deprecated field would parse cleanly and **still silently stop the whole repo run**, because
Renovate does not fail loudly. This is a real open gap. (2) **The rule has never been observed
refusing to automerge anything.** There is **no `renovate/jellyfin-*` branch** among the 27 open ones,
so this half is discharged **by construction, not by a firing observation** — and under CONS-04 that
distinction is the whole point. The observation only becomes available when upstream next ships a
Jellyfin minor and **cannot be manufactured**. TRAN-06 is ticked with both caveats attached in the
traceability entry rather than hidden.

**⚠ THE PLAN'S OWN CANDIDATE LIST MADE THE PLAN'S OWN ASSERTION UNSATISFIABLE — a shape worth
remembering.** The acceptance criterion requires zero bare `renovate.json` in executable lines, but
the detection loop the plan and RESEARCH.md specified verbatim (`for f in renovate.json5
renovate.json …`) contains that literal as a legitimate candidate. It returned 2, not 0, and brace
expansion does not help (`{` is a non-word char, so `\b` still matches). **Resolved by COMPOSING the
names from basename × extension**, which is not a dodge of the assertion but what makes it honest: a
hard-coded filename is the exact defect being repaired, and writing four more of them into the
replacement reintroduces it in a new shape. Zero hard-coded config filenames now remain in executable
code, and the reasoning is recorded in the file so nobody simplifies it back.

**⚠ THREE LATENT `set -e` ABORTS ARE RECORDED AND DELIBERATELY NOT FIXED — and one of them is
inverted.** Lines **115**, **138** and **157** each do `echo "$VAR" | grep -v '^$' | wc -l` inside a
command substitution. When the variable is empty, `grep -v '^$'` matches nothing and exits 1 — a
*successful* grep reporting "none" — and `pipefail` + `set -e` turn that into an abort. **Line 157
therefore aborts when there are ZERO pending Renovate PRs, i.e. precisely when the estate is
HEALTHY**, which also makes its `✅ No pending Renovate PRs` branch unreachable. Proven real, not
theoretical, by running the construct in isolation both ways. They did not fire only because today's
counts are 5 / 5 / 27. Remedy is `|| true` on each — three tokens — deferred under the plan's scope
stop because none blocks completion. **If a future run of that script exits non-zero with a truncated
transcript, look at 115/138/157 first and do NOT read it as a regression from 02.1-08.**

**⚠ A NEW BRANCH ADDED WHILE REPAIRING NEVER-EXECUTED CODE WOULD HAVE BEEN THE SAME DEFECT ONE LEVEL
UP.** The `VALIDATOR_ROUTE=local` branch is brand-new and this workstation takes the `unavailable`
route, so the plan's criteria would have let it be committed unexecuted. Both sub-branches were driven
with a four-line PATH stub — **nothing installed, no network call**, `command -v` cannot tell the
difference: passing stub → exit 0 + green; **FAILING stub → exit 1 + red, aborting before the
inventory** (`grep -c 'compose.yaml files'` over its output is 0); absent → exit 0 + yellow
`UNVALIDATED`, no green tick anywhere. The failing route is the one that matters — a control that can
only ever pass is uninformative. The stub also echoed back `called with: renovate.json5`, proving
detection and validation share one variable rather than a second hard-coded name.

**⚠ THE TOLERANCE PROBE WAS ITSELF PROVEN TO DISCRIMINATE.** Round 2's finding was that a trailing
comma after the file's final `}` is invalid JSON5 and would fail a *working* parser, so both mutations
went **inside** the new rule object: a `/* tolerance probe */` block comment as its first body line,
and a trailing comma after its last key/value pair. The tolerant parse (`new Function("return
("+src+")")()`) exited **0** against the mutated copy. But "exit 0" is unfalsifiable on its own, so the
reviewed-fragile `JSON.parse` over a line-comment strip was run against the **same file** and **exit
1**, throwing at the block comment — the tolerant parse passes because it tolerates the mutations, not
because they are inert. The copy was deleted and `git status --porcelain` confirms it was never
committed.

**⚠ `origin/main` MOVED `2021d0f` → `5c13899` and `/mnt/fast/stacks` on LXC 100 is at `5c13899`.**
D-26 asserted in both halves, because a matching SHA and a landed payload are different claims: the
**host-side** copies were re-grepped after the pull (`jellyfin/jellyfin` → 1, `VALIDATOR_ROUTE` → 4,
bare `renovate.json` in executable lines → 0). The credential screen ran with a **positive control**
first (2 matches against known secret-shaped text), then over the full range: 1 match, and it is prose
in `02.1-07-SUMMARY.md` describing that same control, not a credential. A key-shape sweep returned 0.

**Regression checks after the pull: `check-jellyfin-transcode.sh` still `FAILURES total: 0`, exit 0**
(`/` headroom 33.10 GiB, volume mounts 0, quota 53687091200, transcode `devid=47 parent=64519`), the
**D-30 amdgpu mitigation unchanged** (`none` / `false`), and **`git diff 6242ad5..HEAD --name-only --
stacks/ infra/` is EMPTY** — the Jellyfin image pin (`jellyfin/jellyfin:10.11.11`), the compose
declaration and the clean `terraform plan` baseline are all untouched. **`packageRules[3]`, the wrtag
`<0.30.0` pin, is unchanged**: the new rule's description *cites* it as the D-24 cautionary tale and
explicitly calls it a misdiagnosis enforcing a broken state, neither modifying nor entrenching it.
Removing it stays with Phase 4.

Before that, **02.1-07 COMPLETE. THE ONE-COMMAND SILENT REVERT OF THIS PHASE IS DISARMED,
AND THE DISARMING WAS PROVEN ABLE TO FAIL.** `scripts/disable-jellyfin-hwaccel.sh` is the estate's
amdgpu recovery runbook for a fault that recurred 2026-08-31 and cost ~6 hours. Its `do_enable`
restored the **whole** `encoding.xml` from the newest `.bak` — and the only `.bak` next to the live
config is `encoding.xml.bak.20260831T182741Z`, taken **before** this phase's settings existed
(asserted: count 1, that filename). Running `enable` therefore reverted all five retention values
**and reported success**, because the IN-06 verification checked `HardwareAccelerationType` and
nothing else. `do_enable` now **captures the five from the LIVE config before the `cp`, re-asserts
them into the restored file, and verifies them on BOTH sides of the container restart** — naming any
moved field with its **before and after** values and exiting non-zero. The pre-restart gate exists so
a service the house is watching is never restarted onto a config that lost the settings.

**⚠ THE REVIEWED NEGATIVE CONTROL WAS STRUCTURALLY UNABLE TO FAIL, AND THAT IS THE POINT OF THIS
PLAN.** *"Perturb a value, re-run `enable`, expect non-zero"* cannot work: the verification lives
**inside** `do_enable`, which **re-captures the live values before restoring**, so it would have
captured the perturbed values, carried them across faithfully, compared them against themselves and
**passed** — emitting a transcript that reads exactly like a discharged control. Same failure class
as 02.1-06's log-level bug and 02-08's `exportfs -v`. **Two real fault-injection paths replaced it
and BOTH were executed:** (a) a standalone read-only `verify-retention` sub-action taking its
expectations from `$TRAN09_EXPECT` — **exit 1** on a perturbed config naming `EnableSegmentDeletion`
with `expected='true' found='false'`, **exit 0** once restored (a control that only ever fails is as
uninformative as one that only ever passes); (b) `TRAN09_FAULT=1 … enable` — **exit 1**, four of five
fields named with both values. **The most informative line in the whole transcript is the fifth:
`ThrottleDelaySeconds` was `180` either side and correctly PASSED inside a failing run**, which is
what proves the comparison is genuinely per-field rather than a switch that flips the whole block.

**The positive round trip ran too, exit 0:** `check` → `disable` (which created the stale `.bak`, the
hazard reproduced) → simulated phase write → `enable`, against a throwaway `encoding.xml` at
`/mnt/fast/spike-021/tran09/` and a disposable container, both overrides on every invocation. All
five values preserved **and** `HardwareAccelerationType` back to `vaapi` — the restore's actual job
still works. **The live config is provably untouched**: sha256 and mtime identical either side, the
`.bak` inventory unchanged, and `check-jellyfin-transcode.sh` still `FAILURES total: 0`. **The D-30
amdgpu mitigation is unchanged** (`none` / `false`) — this plan changed *how* `enable` restores,
never *whether* VAAPI should be on. **TRAN-09 is COMPLETE.**

**⚠ THE PLAN'S TWO NAMED DISPOSABLE IMAGES ARE NOT RESIDENT ON LXC 100 AT ALL.** D-31 constraint 2
orders this plan before the reap precisely to protect `alpine:3` and `curlimages/curl:latest` — but
03-01's reap had already taken them. `nginx:1.31.3-alpine` was used instead, asserted resident from
`docker image ls` and **probed** with `docker run --rm --entrypoint sleep <image> 1` → exit 0 before
the real container was created. **No pull occurred.** The residency assertion is only meaningful
because it *could* have failed — and against the plan's own candidates it would have.

**⚠ THE REST-API CONVERSION IS DEFERRED, RECORDED IN THE FILE, AND SHOULD NOT BE RE-OPENED.** The
script's comment said *"Once 02-04 lands, prefer the API"* and 02-04 has landed. It is nonetheless
deferred, because this runbook's entire value is that it works when Jellyfin is **down**, which is
the condition an amdgpu incident creates, and the REST route needs a **running** server.

**⚠ `origin/main` MOVED `8710116` → `2021d0f` (ten commits) and `/mnt/fast/stacks` on LXC 100 is now
at `2021d0f`**, carrying the 02.1-05 and 02.1-06 artifacts for the first time. D-26 was asserted in
both halves before the first invocation, because **a matching SHA and a landed payload are different
claims**: SHA equality, *and* `verify-retention` / `TRAN09_FAULT` greppable in the **host-side** copy.

Before that, **02.1-06 COMPLETE. THE BOUNDS FIRE, AND THE 12.55 GiB IS OFF `/`.** The
anonymous volume `d98b2ff9…` was deleted by name at **2026-09-02T23:52:53Z**, after — not before —
the observation it would have made vacuous. **`/` went 21674889216 → 35575803904 = +12.95 GiB**,
matched to the byte by `stat -f`. **The margin against the D-17 floor is now 13.13 GiB, from 185 MiB
at the phase head** — a factor of about seventy-three, and better than the ~33-36 GiB the plan set
was originally written against. **`check-jellyfin-transcode.sh` exits 0 in default mode for the first
time in the phase: FAILURES 1 → 0.**

**Every control is now proven FIRING from a real observation, not read back (CONS-04, D-15).** Two
driven playback sessions — one stream-copy, one real libx264 re-encode — with a purpose-built HLS
client that fetches segments sequentially at roughly realtime, because both controls key off the
client's *download position*: rows 4 (44 / 55 new `.mp4` in `/mnt/fast/transcode`), 5 (**0** new
files in the old volume during the same transcode, with the volume proven still to exist at that
moment), 16 (**8** `Deleting segment file(s) index` lines per session, ranges advancing), 17
(`-readrate 10` present on `copy`, correctly absent on `libx264`), 18 (**89+6** and **87+8**
throttler lines, **zero** `No throttle data`). Better than the row asked for: the throttler logs
`target gap 1800000000` ticks — **Jellyfin echoing `ThrottleDelaySeconds=180` back in its own
words.** And the quota **refused a write on attempt 1 of 10 while `/` moved by exactly 0 bytes**
across a 1 GB ballast.

**⚠ THREE ASSERTIONS IN THIS PHASE'S OWN CONTRACT FAIL ON CORRECT OUTCOMES — fix before 02.1-10.**
(1) **VALIDATION row 11's errno pair is INVERTED.** An OpenZFS dataset `quota` refusal surfaces as
**EDQUOT** (`Disk quota exceeded`), not ENOSPC; ENOSPC is a genuinely full *pool*. The plan's stated
inference — *"EDQUOT means refquota is in force and 02.1-03's property is wrong"* — was **tested and
is FALSE**: `refquota` is `0`/default, `quota` is `53687091200`/local, no ancestor carries either.
**02.1-03 chose correctly; the RESEARCH's errno mapping is what is wrong.** (2) **Row 16's numeric
ceiling** counts only the `SegmentKeepSeconds` retention window and omits the `ThrottleDelaySeconds`
forward buffer the configuration deliberately maintains, so a working cleaner cannot satisfy it.
(3) **02.1-06's own task-3 `<verify>` block cannot pass** and was deliberately not made to pass —
inserting the ENOSPC string to satisfy it would fabricate a firing that did not happen.

**⚠ A REAL ESTATE FOLLOW-UP, WORSE THAN THE PLAN DESCRIBED.** The reasoning behind choosing `quota`
was "so refusals match the estate's ENOSPC-keyed log greps". **Both** properties return EDQUOT, so
**no** choice of property produces a match: any monitoring keyed on the ENOSPC phrase is **blind to a
transcode-quota refusal**. Switching to `refquota` would not fix it; adding the EDQUOT string to
those greps would. Not fixed here — out of scope.

**⚠ THE PROOF CLIENT PRODUCED A CONFIDENT, COHERENT, COMPLETELY FALSE RESULT BEFORE IT WAS CAUGHT,
and the lesson generalises well beyond this phase.** Run 1 reported **zero** deletion lines, **zero**
throttling lines and zero `No throttle data` on *both* codec branches, with an advancing download
head and the ffmpeg pause key re-probed at `d=10000` as supported — every discriminator the plan
provided pointed at "the controls do not start on this estate". The cause was mine: `printf … | head`
under `pipefail` returns 141 on SIGPIPE, which fired the `ERR` trap during the *manifest fetch*; the
handler correctly restored Jellyfin to Information, but **`set +e` inside a trap handler is GLOBAL,
not function-local**, so with errexit off the script ran on for 200 more lines and grepped a log that
had been back at Information throughout. Both target lines are Debug-level and could not appear.
A false mechanism had already been drafted (that Jellyfin excludes the throttler on the copy path)
and was refuted by run 2. **The fix that closes it is a `Debug-liveness assertion at grep time`** —
an instrument that reads a log must prove the log was at the required level *for the window it
reads*, or "zero matches" and "the control did not fire" are the same output. That is 02-08's
`exportfs -v` in a new costume, and it is the third time this estate has paid for the same shape.

**⚠ THE 02.1-05 RECREATE MINTED TWO DANGLING ANONYMOUS VOLUMES** (`c479d815…`, `efbcf4d6…`, both
created `22:19:12Z`, both 0 bytes, unreferenced). Nothing writes to them — jellyfin holds zero
`Type: volume` mounts, asserted. **Deliberately NOT removed**: D-11 scopes 02.1-06 to an inventory
and nobody has ruled on deleting them. Recorded because this whole phase began as one anonymous
volume nobody was watching.

**TRAN-02, TRAN-03 and TRAN-04 are COMPLETE** — the first requirements in this phase ticked on
*firing* evidence rather than configuration. One caveat stated plainly: TRAN-03's "survives a UI
edit" clause is discharged **by construction, not by an executed edit** — Jellyfin cannot set ZFS
properties, which is the entirety of D-12.

Before that, **02.1-05 COMPLETED — THE CUTOVER.** At **2026-09-02T22:19:52Z** Jellyfin
stopped writing its cache to `/`. The container was recreated onto the binds 02.1-04 declared, and
the mount shape is now proven on the **runtime** rather than in the file: **zero `Type: volume`
mounts** (D-18's invariant, asserted before the container was even enumerated), `/cache/transcodes`
→ `bind /mnt/fast/transcode`, `/cache` → `bind /mnt/fast/appdata/media/jellyfin/cache`, and
`/data/transcode` in **no** destination. **Assumption A4 is CONFIRMED by probe, not by reading
moby's sort**: a file written into `/cache/transcodes` from *inside* the container appeared at
`/mnt/fast/transcode/` and **not** under the cache bind. Jellyfin then wrote its own
`.jellyfin-transcode` marker into the dataset at 22:20Z — the *server* agreeing, not just the daemon.

**Jellyfin's five retention values are live**, applied by strict read-modify-write (POST returned
204, no restart): `TranscodingTempPath=/cache/transcodes`, `EnableSegmentDeletion=true`,
`SegmentKeepSeconds` 720→**300**, `EnableThrottling=true`, `ThrottleDelaySeconds=180`. **The amdgpu
mitigation SURVIVED** — `HardwareAccelerationType=none` and `EnableHardwareEncoding=false`, asserted
against both the captured pre-write values and the literals. That endpoint is a **full-object
replace** and `EnableHardwareEncoding`'s constructor default is **true**, so a partial POST would
have silently re-armed the hazard that cost ~6 hours on 2026-08-31.

**The ZFS bound did not notice the container being destroyed and rebuilt** — `quota=53687091200`,
`mounted=yes`, both re-read from atlantis *after* the recreate (VALIDATION rows 10 and 36). That is
exactly why D-12 makes the ZFS property load-bearing rather than an application setting.

**Standing check at 02.1-05: `FAILURES total: 5` → `1`.** The one remaining red was section 3, *"the
anonymous volume STILL EXISTS"*, and it was **supposed** to be red there — it is the row that says
the rollback survives. **02.1-06 has since cleared it for the right reason: FAILURES `1` → `0`.**

**⚠ VALIDATION.md row 15 IS WRONG AS WRITTEN and needs correcting before 02.1-10 verifies against
it.** It asserts the changed-key set equals five names *including* `ThrottleDelaySeconds` — but that
value was already `180`, so setting it to `180` changed nothing, and the equality was unsatisfiable
from the moment it was written. The plan's own prose, 02.1-RESEARCH.md and `jellyfin.yaml` all say
`180 -> 180 UNCHANGED`. **This was NOT the full-object-replace hazard firing**: the hazard is the
*superset* direction and it was measured directly — `changed_keys − intended_five` = `[]`.

**Two numbers 02.1-04 discovered that the plan set did not have.** (1) The old volume's
`transcodes/` is **12.55 GiB across 1,324 files**, not the 472 K the plans assume — so it was
EXCLUDED from the copy (shadowed by the nested bind, deleted in 02.1-06, and copying it would
breach the headroom precondition outright). (2) **`rsync` is NOT INSTALLED on LXC 100** and was
deliberately not installed; the documented `cp` equivalence was used. Assumption **A5 is
CONFIRMED** — `cp --preserve=all` succeeds on `fast/appdata/media` (`nfsv4` + `passthrough`), so
the `tank` EPERM failure mode does not apply there.

Before that, 02.1-03 completed: `fast/transcode` is **declared** in `infra/` Terraform
(`infra/jellyfin-transcode-dataset.tf`, `var.jellyfin_transcode_quota`) and carries
**`quota=53687091200`** live, with `compression=off`, `sync=disabled`, `recordsize=1048576`,
`atime=off`, `mounted=yes` and `2775 apps:apps` — all read back from atlantis, not from Terraform's
own output. **TRAN-07 is COMPLETE**; TRAN-03 was left Pending there because it requires the bound proven
**firing**, not proven set — **and 02.1-06 has now provided exactly that, so TRAN-03 is COMPLETE.**

**⚠ BOTH OF 02.1-02's OPEN QUESTIONS ARE NOW RULED — do not re-litigate either.**
(1) The `/` **ORDERING** question: the reap **stays in 02.1-09**, 02.1-03 proceeded. Basis, measured
not assumed: every write in 02.1-03 lands on the `fast` pool (`stat -c %d` → `/mnt/fast/transcode` =
47, `/` and `/mnt/fast` both 64519) and none on `/`; the post-apply `/` reading of 20.16 GiB confirms
it. **The ruling covered 02.1-03 ONLY** — 02.1-04 (copy) and 02.1-05 (recreate) *do* touch `/` and
must be re-ruled on their own numbers against a **0.16 GiB** margin.
**02.1-04 HAS SINCE BEEN RE-RULED — by the EXECUTE-PHASE ORCHESTRATOR, not by the operator.** Weigh
it as an agent's ruling, not a human's: the D-17 floor is a conservative *policy* tripwire, not a
physical limit, actually-free is ~20.16 GiB, and the budget granted was numeric — halt if a step
would cost >2 GiB of `/`, if `/` actually-free would fall below 10 GiB, or if the transcode cache
resumed growing. **None fired, and the copy measured `/`-NEUTRAL (+14.0 MiB)** because source
(dev 64519, ext4) and destination (dev 63, zfs) are different filesystems.
**02.1-05 WAS RE-RULED IN TURN — again by the ORCHESTRATOR, not the operator** — on the same numeric
terms plus one addition specific to a recreate: **check image residency first**, because a pull is a
1.45 GiB write into `/var/lib/docker` on `/` and is the one genuine multi-GB consumer a compose
change has available. The image was already resident (digest `d57d4a0c…`, identical either side), so
**no pull occurred**. **Nothing fired and the recreate was `/`-POSITIVE: +37 MiB**, the old
container's writable layer released and not fully replaced. **The margin is now ~216 MiB, the widest
it has been all phase.** That ruling covers **02.1-05 ONLY**; 02.1-06 is the `docker volume rm`, a
different shape again — it *releases* 12.55 GiB rather than spending anything — and gets its own
numbers.
(2) The **TERRAFORM** question, which 02.1-03 halted on separately: the baseline
`terraform plan -detailed-exitcode` exited **2**, not 0, tripping VALIDATION row 28. The drift was
output-only (`verify_commands`, a stale heredoc from `76b3783`; non-no-op `resource_changes` measured
`count 0 / destroys 0 / addresses []`). **The operator ruled OPTION B** — clear it as its own
separate guarded apply first, then execute against a genuinely clean exit-0 baseline — because row 28
is a row this phase gets verified against and only B satisfies it *literally*. Executed as **two
applies**, each from its own saved workstation-local plan file, each mechanically asserted before it
ran. **`infra/` now has a clean exit-0 baseline**, so the next saved-plan assertion there contains
only its own change.

Before that, 02.1-01 landed the TRAN ids, cleared the
ROADMAP placeholders and opened the D-32 watch (still
open). Phase 02.1 was **replanned against cross-AI review**: 10 plans in 9 waves,
plan-checker passed with 0 blockers. 32 locked decisions (D-01…D-32, of which **D-29/D-30 were ruled
by the operator during plan-phase** and **D-31/D-32 during the review replan**; all four postdate
RESEARCH.md), 9 requirements TRAN-01…TRAN-09, and a 38-row VALIDATION.md contract that separates
**read-back** from **fires** — rows must be discharged by a real observation, never by reading a
setting back (CONS-04). **D-31 re-ordered the waves so the cutover is the critical path**: `/` is
structurally protected at the end of wave 6 of 9, not wave 4 of 5 behind a blocking human gate.
(Wave count went 8 → 9 in **review round 2**, when Codex — the first genuinely non-Anthropic
reviewer of this phase, its install having been repaired — raised four HIGH findings none of the
round-1 reviewers surfaced. Three were verified real against the plan text: a verification that
re-ran the destructive image prune, a playback transcript that would have committed the Jellyfin
API key into this **public** repo, and a quota restore written as prose with no `trap`. The fourth
reversed a round-1 decline and encoded `02.1-02`'s dependency on `02.1-01`, cascading every later
wave +1.)

**Phase 03 remains planned from 2026-09-01** — 11 plans, 8 waves, plan-checker passed,
then **cross-AI reviewed (codex / gh copilot / gemini) and revised against 13 findings**, and passed
the checker again clean. Research falsified parts of CONTEXT.md and six operator decisions (OD-1…OD-6)
now override it where they conflict; they are recorded in the plan set and must be carried into
execution.

**Wave 1's disk gate is CLEARED, but its premise was wrong — carry this into phase 2.1.** 03-01
completed 2026-09-02: the operator-approved 27-image reap ran with 0 `rmi` failures and reclaimed its
full 18 GiB estimate. But images were never the real lever. While 03-01 sat at its approval gate `/`
went from 2.2 GB free to **zero**, and measurement found the consumer was a **19 GB Jellyfin
transcode cache** in an *anonymous* Docker volume (`d98b2ff9…/_data/transcodes`) — larger than the
entire image reap, and unlike images it **refills**. No `ffmpeg` was running, so this is cache
retention, not the documented amdgpu/VAAPI orphan hazard. Clearing it plus the reap took `/` to
**36 GiB free** against the 8 GiB floor (34 GiB after the four spike pulls, so OD-1's A2 estimate of
2.0–2.3 GB holds). `docker system df` still reports ~62 GB reclaimable across images, so the audited
27 were always the conservative subset. **Phase 2.1 is inserted to fix the retention durably** — the
volume being anonymous rather than a declared bind mount to `/mnt/fast` is the root cause.

**⚠ Two review findings changed how the headline number is computed — carry these into execution:**

- **The 24-folder sample is a COVERAGE sample, not a population estimate.** It is stratified and
  deliberately never random. T1's headline strict rate and T2's extrapolation are therefore a
  **per-stratum roll-up weighted by each stratum's prevalence across the 143-folder backlog**
  (`Σ_s rate_s × weight_s`), never an unweighted average over the 24. The unweighted figure is
  reported beside it and is explicitly *not* what T1 is tested against. **The 40% threshold value is
  unchanged** — only the estimator was specified, and it was specified before any weight or rate
  existed, which is why criterion 5 survives. A stratum with backlog weight but no sampled folder is
  a **named hole**, enters the roll-up with a 0%/100% band, and if that band straddles 40% **T1 is
  recorded `indeterminate`** rather than resolved by picking an end.

- **Criterion 5's custody is a pushed commit, not local history.** 03-02 must reach `origin` before
  any evidence plan starts, and 03-07 re-asserts the SHA is reachable from `origin/main` before it
  measures anything. `git log -p` on a mutable local branch is evidence, not proof.

**Operator decisions taken at review:** the weighted roll-up (not a second random sample); and the
spike compose configs are **archived** under `.planning/` with a `THROWAWAY — DO NOT DEPLOY` banner
rather than deleted — containers and every credential-bearing runtime file are still purged.

**Phase 02 CLOSED 2026-09-01** — all nine plans executed, all five criteria
proven, CONS-01/02/03 complete, verification `passed` 5/5. The consumers audit is folded into
`quick-health-check.sh`, criterion 5 is recorded in
PROJECT.md with Route B's failure symptom and the old assertion rewritten, and the operational record
is in `beets.md` and `NETWORK.md`. **D-55's human gate is SATISFIED** — and by a stronger test than
it asked for: the operator browsed MA's Filesystem (local disk) provider, spot-checked albums, and
**played tracks to confirm the audio matches the metadata**. No assertion in this phase could do
that — every automated check verifies MA's *database* says the right thing, never that the *bytes*
are the right song, and the documented stale state is precisely "entries exist, playback fails".
deletion and throttling proven from Jellyfin's own Debug log across two driven playback sessions, the
ZFS quota proven to refuse a write while `/` moved by 0 bytes, the anonymous volume deleted by name
after the observation it would have made vacuous, **12.95 GiB reclaimed**, and the standing check
green at FAILURES 0. Three of the phase's own assertions were found to fail on correct outcomes and
are flagged for correction, not edited). Before that, 02.1-05 complete (**THE CUTOVER** — the container recreated onto the
declared binds at 22:19:52Z, assumption A4 confirmed by write-through probe, the quota and mount
proven to survive the recreate, and the five encoding settings applied by read-modify-write with the
amdgpu mitigation asserted intact). Before that, 02.1-04 completed (the cache copy and the compose
declaration; finished
by a continuation agent after the first executor was killed by a transient API error mid-plan, with
every assertion re-derived from live state rather than inherited). Before that, 02.1-03 completed
(the dataset declaration and the quota; two guarded
applies, A3 confirmed byte-exact). Before that, 02.1-02 completed (the standing transcode check and
its baseline), and before
that, 02.1-01 completed, and before that 02.1 was replanned against
cross-AI review in **two rounds**
(`/gsd-review` → `/gsd-plan-phase --reviews`): 9 plans in 5 waves became 10 in 8, then 10 in **9**
after round 2. **Round-2 plan-checker pass completed 2026-09-02 against commit `2755734`: 0
blockers, 3 warnings, all three fixed.**
**Round 1** — Gemini + Claude; **Codex could not run** (missing `@openai/codex-darwin-arm64`), so
Gemini was the sole cross-family reviewer. All 26 findings applied or reframed with a stated reason,
none rebutted. The two proofs that **could not fail** are repaired:
`disable-jellyfin-hwaccel.sh` gained a standalone `verify-retention` sub-action and a `TRAN09_FAULT=1`
gate, and the segment-deletion proof now drives a real HLS client whose download head must advance.
The 49.5 GB ballast became a temporary `quota=1G` shrink with `conv=fsync` and a bounded retry.
**Round 2** — the operator repaired the Codex install, and Codex reviewed the *revised* ten-plan set
(the first genuinely non-Anthropic review of this phase). It raised **four HIGH findings neither
round-1 reviewer surfaced**, three verified real against the plan text: `02.1-09`'s verification
**re-ran the destructive prune** it was meant to verify; `02.1-06` would have committed the Jellyfin
**API key** into this **public** repo, because Jellyfin embeds `api_key=` in `TranscodingUrl`; and the
`quota=50G` restore was **prose, not a `trap`**, so an aborted run left the dataset at `quota=1G` —
which takes the TV down on the next play. The fourth **reversed a round-1 decline**: `02.1-02`'s
dependency on `02.1-01` was unencoded, and `parallelization: false` is mutable executor config, not
dependency semantics. Encoding it cascaded 8 waves → 9 and D-31's descriptive wave number was
corrected (its substance — cutover first — is unchanged). Codex was also **wrong once**: it argued a
lost-append race on the D-32 watch because `02.1-07`/`08` share a wave, but neither writes to it —
the eight writers are each alone in their wave. **Standing lesson: three of the four HIGH findings
were plainly present in the plan text and no Anthropic-family reviewer saw them. Single-family
review understates its own blind spot; verify every finding against the text rather than counting
reviewers.**
Research characterised the incident from Jellyfin's own source at the running tag (`v10.11.11`) and
found the transcode was a **stream-copy remux** of an 18 GB / 17.93 Mbit/s source — one unbounded
orphan accounts for the whole 19 GB. Two operator rulings were taken mid-planning: **D-29** hardens
`scripts/disable-jellyfin-hwaccel.sh`, whose `do_enable` restores the whole `encoding.xml` from a
`.bak` predating this phase and would otherwise be a one-command silent revert of everything 02.1
installs; **D-30** preserves `HardwareAccelerationType: none` / `EnableHardwareEncoding: false` (the
2026-08-31 amdgpu mitigation) verbatim and asserts them after the write, because the encoding REST
endpoint is a **full-object replace**.

Prior activity: 2026-09-02 — Phase 03 execution started; 03-01 complete (disk-headroom gate cleared,
36 GiB free). Phase 03 **halted after 03-01** pending inserted phase 2.1 (Jellyfin transcode
retention), on operator instruction.

Prior activity: 2026-09-01 — quick task 260901-u96: read-write NFS export on atlantis for Home
Assistant backups. **Correction worth carrying into any future export work:** `nfs-music-export.tf`'s
"`ro` is forced, not a preference" is a property of the *TrueNAS-era datasets*, not of `tank`.
`tank` is `acltype=posix` (local); `tank/media/*`, `tank/downloads` and `tank/timemachine` each set
`acltype=nfsv4` locally. A new child of `tank` therefore has enforceable mode bits and `chmod`
works on it — which is the only reason a writable export is defensible. Do not generalise that `rw`
back onto anything under `/mnt/tank/media`.
Phase 1 complete: SAFE-01…05, WRIT-01…04, QUAL-01
Phase 2 complete: CONS-01, CONS-02, CONS-03

Progress: [██░░░░░░░░] 22%  *(MILESTONE progress: **2 of 9 phases** complete. All 19 plans written so far are executed 19/19 — but phases 3-9 are not planned yet, so plan-count is not milestone progress. ⚠ `gsd-sdk query state.update-progress` recomputed this as **51%** on 2026-09-02 by counting SUMMARY files against a 39-plan denominator that only covers planned phases; that figure is WRONG and was reverted. Do not let the SDK rewrite this line — phase 02.1 is an INSERTION and is not one of the 9 milestone phases. ⚠ **It happened a second time on 2026-09-13** during plan 04-14, recomputed as **97%** against a 60-plan denominator, and was reverted again. The verb rewrites this line every time it runs; `git diff .planning/STATE.md` after any state write is not optional. ⚠ **Third occurrence 2026-09-18** during plan 05-01, recomputed as **84%** against a 74-plan denominator, reverted again. ⚠ **Fourth occurrence 2026-09-18** during plan 05-02, recomputed as **85%** against the same 74-plan denominator, reverted again — and this time the verb ALSO truncated the frontmatter `last_activity:` back to a bare "Phase 05 execution started", so the damage is not confined to this line. ⚠ **Fifth occurrence 2026-09-18** during plan 05-03, recomputed as **86%** against the same 74-plan denominator, reverted again; on this run the collateral damage was all three of the documented sites at once — the frontmatter `last_activity:`, the `Status:` line (leaving `gates are ...` orphaned under it), and the `Last activity:` line 560 lines down. ⚠ **Sixth occurrence 2026-09-18** during plan 05-04, recomputed as **88%** against the same 74-plan denominator, reverted again, with the same three collateral sites damaged a second consecutive time — the damage set is now stable and predictable, which is the strongest argument yet for not running the verb against this line at all. ⚠ **Seventh occurrence 2026-09-18** during plan 05-05, recomputed as **89%** against the same 74-plan denominator, reverted again, same three collateral sites for the third consecutive run. Seven occurrences, seven figures, zero of them milestone progress — the verb cannot compute this figure and should not be run against this line ⚠ **Eighth occurrence 2026-09-18** during plan 05-06, recomputed as **91%** against the same 74-plan denominator, reverted again, same three collateral sites for the fourth consecutive run. Eight occurrences, eight figures, zero of them milestone progress. ✅ **Plan 05-07 broke the loop: `state.update-progress` was NOT RUN AT ALL**, on the strength of this note's own conclusion after eight identical reverts — acting on a written finding instead of re-deriving it a ninth time. This line is therefore untouched by that verb for the first time since 05-01. `state.advance-plan` was still required and still damaged its own three sites — the frontmatter `last_activity:`, the multi-line `Status:` field, and the `Last activity:` line ~600 — all three reverted, leaving only the intended `completed_plans` and `Plan:` changes. **The damage set has now been stable across five consecutive runs: `advance-plan` corrupts three sites, `update-progress` corrupts this one, and `record-metric`, `add-decision` and `record-session` were each driven this plan and corrupted nothing.** That breakdown is finer than "the SDK corrupts STATE.md" and is the actionable form: run the three clean verbs freely, diff after `advance-plan`, never run `update-progress` against this line. ✅ **Plan 05-10 did the same: `update-progress` NOT RUN**, and `advance-plan` damaged exactly the same three sites for the sixth consecutive run — frontmatter `last_activity:`, the multi-line `Status:` field, and `Last activity:` line 627 — all three reverted. Two further notes from 05-10, because the role prompt is wrong about both: `record-metric` and `add-decision` take **NAMED flags** (`--phase/--plan/--duration/--tasks/--files`, `--summary`), not positionals — called positionally they return `"error": "... required"` and write nothing; and `record-session` **also bumps `completed_plans`**, so `advance-plan` afterwards does not double-count it. `add-decision` still writes `[Phase ?]` and still needs correcting by hand. ⚠ **`gsd-sdk query phase.complete` is ALSO a corrupting verb — recorded 2026-09-19 at Phase 05 close, the tenth occurrence overall.** It did NOT touch this `Progress:` line (so the 05-07 finding holds: `update-progress` is the verb that rewrites it, and phase.complete does not call it), but it inflicted `advance-plan`-class damage on two of the three known sites: it replaced the first TWO lines of the multi-line `Current Position` field with `Phase: 6` / `Plan: Not started`, orphaning the entire Phase 05 narrative as a dangling fragment beginning `proof driven; criteria 2/3/4 ...`, and it truncated the `Last activity:` line ~654 to a bare date. Both repaired by hand, nothing deleted. **The rule is now: diff STATE.md after `phase.complete` too, not only after `advance-plan`.**)*

Plans 02-01 through 02-09 are executed. **CONS-01, CONS-02 and CONS-03 are all complete.**

**What the operator observed, from the consumer side — two of these are independent confirmations
of things this phase proved by other means:**

- MA's browse root lists **exactly 13 artist folders**, every one a single named artist. Confirms
  **D-08** (no Various Artists compilation in this library) from the consumer side, and matches
  `sensor.music_library_nfs_mount` = 13 exactly.

- `Chris Norman / Lifelines (2026)`: 15 tracks, every row `Chris Norman • Lifelines • 2026`.
  Criterion 3 confirmed **by eye**, at track level.

- **No `Various Artists` entry anywhere; no stray singles.** The `folder_name` fallback never
  misfired on real library content.

- **`Mastermix Essential Hits - Pop 4 - 2005-2009` is ABSENT — the correct result.** It was served
  through the temporary export, torn down in 02-07. Its absence is **D-46's teardown confirmed from
  the consumer side, after the fact**.

- The `Def Leppard` **folder** is visible and that is expected — the known empty-album-artist defect
  is at album/track level *inside* it and remains deliberately unrepaired under D-05. **Do not read
  the folder's presence as the defect being resolved.**

**⚠ THE APPROVAL COVERS CRITERION 3 ONLY.** It does not close D-54b's boot blindness or the
never-delivered mount-failure notification. Both stay open — see Blockers/Concerns.

**⚠ NOTHING IS PUSHED.** The operator's 02-08 approval covered `aa2b502..90cdddc`. The tree is
**5 ahead of `origin/main`**: `a4174e6` + `6ff2332` (02-08) and `9f915a9` + `e37039b` + the 02-09
close. `/mnt/fast/stacks` on LXC 100 is therefore still at `90cdddc` and does not carry the folded-in
`quick-health-check.sh` — which does not matter, because that script runs from the workstation.

**THE FIVE CRITERIA — every one PROVEN, evidence and producing plan in `02-09-SUMMARY.md`:**
1a-1e export/re-apply/host/NUC/NFSv4.2 (02-03 + 02-05) · 2 by Stage **4b** not 4a, at the **export**
layer (02-05) · 3 exact on album name AND album artist, provider-attributed, in one 177 s sync
(02-07) · 4 by **both** 4a and 4b, a green 4a alone explicitly insufficient (02-08) · 5 this plan.

**⚠ WHAT IS NOT PROVEN, carried deliberately:** the mount-failure **notification** has never been
delivered against a genuinely bad mount (trigger path and action gate are proven by firing; delivery
is proven only as "service registered + templates render"); the literal `"0"` in that automation's
`to:` list has not fired in isolation; and **D-54b is blind at boot and NOT fixed** (see Blockers).

**CONS-03 IS COMPLETE (02-08) — the NUC was rebooted twice and both criteria are met.**

**Criterion 4a (positive):** boot_id `b86dada0…`→`3a7906c0…`, **zero manual intervention**, mount
`active`/`read_only`, sensor 13, 70 albums provider-filtered, both proof albums EXACT, audit exit 0,
M4a re-synced unprompted at 12:43:25Z. Recorded as **necessary but not sufficient** — atlantis was
healthy, so the race was never exercised.

**Criterion 4b (negative control) FIRED.** `nfs-server` stopped, NUC rebooted
(`3a7906c0…`→`a2869d72…`). Supervisor's `mounting read-only fallback` logged; `/media/music` empty
and `dr--r--r--`; MA logged `Aborting sync … scan found no files but 1244 were previously indexed`.
**The deletion guard held: 70 albums before, 70 during, 70 after. MA went stale, not empty.**

**UNATTENDED RECOVERY SETTLED: 432 s (7 m 12 s)** from `nfs-server` returning to `state: active`,
NUC untouched throughout — no `ha mounts reload`, no add-on restart, no manual mount. The measured
interval is **~7 min, not the ~900 s the research assumed**. M4b then fired on its own at
13:12:06Z and re-synced MA.

**⚠ M1 IS PROVEN (02-08), superseding 02-03 and 02-05 — do NOT re-open it.** A discriminating
client-mount pair from the NUC, same command minutes apart: dataset **mounted** → exit 0 / 14
entries; dataset **unmounted** → exit 255 / `No such file or directory` / 0 entries. The `mountpoint`
export option genuinely makes `rpc.mountd` refuse. **The earlier readings were an instrument error,
not a defect** — `exportfs -v` keeps printing the line while the dataset is unmounted, so the export
*table* is non-discriminating while the *served mount* is refused. 02-03's `threat_flag:
control-not-enforced` on `infra/nfs-music-export.tf` is **retired** and the measurement is recorded
in the file itself (`a4174e6`). M2 (`After=zfs-mount.service`) remains the boot-race guard; M1 is a
proven second layer beneath it.

**⚠ THE CONTROL FOUND A REAL ALERTING DEFECT, NOW FIXED.** D-54a's `numeric_state below: 1` trigger
was **structurally unable to fire** on a boot into a failed mount: HA arms a numeric_state trigger
only on a non-matching change, and after such a boot the sensor's first value is already `0` — there
is nothing to cross. Confirmed by contrast: M4b's `numeric_state above: 0` is a genuine crossing and
did fire. **And the obvious fix — a `state: to: "0"` trigger — would have missed it too:** the
sensor lands on its boot value 6–15 s *before* the automation attaches, and an unchanged poll fires
no event. The load-bearing fix is a `homeassistant` `event: start` trigger, which fires **at attach
time** and therefore cannot be outrun. Both new trigger paths have now fired and are
trace-confirmed; the original numeric trigger was kept, not swapped.

**D-54b is diagnosed and left OPEN, deliberately.** Its trigger config is correct (proven with a
synthetic event: fired in 542 ms). It is blind at boot because `hassio` mirrors Supervisor's issues
into HA's repairs registry ~17 s *before* the `automation` domain sets up — an ordering, not a race,
identical across four observed HA starts. Fixing it would duplicate D-54a for the only issue type in
scope and would page for pre-existing unrelated issues.

**The mount is LIVE and proven** (02-05). Route A won on measurement: a HAOS Supervisor NFS mount
named `music`, `state: active`, `read_only: true`, `user_path: /media/music`, fstype `nfs4` at
`vers=4.2` — and `/media/music` is readable **inside the running Music Assistant container**,
propagated `rslave` into a container that started two days before the mount existed. Music
Assistant's own documentation says that is impossible; it means *local bind* mounts.
**CONS-01 is COMPLETE** and **criterion 2 is proven at the export layer**: a hand-rolled
`mount -o rw` succeeded and every write was still refused `EROFS`, on NFSv3 *and* NFSv4.2.

**CONS-02 is COMPLETE (02-06). The provider exists and is pinned:**

```
instance_id                  filesystem_local--XJaJWNUS      <-- pinned in check-music-consumers.sh
domain                       filesystem_local   (Route A)
path                         /media/music       <-- NOT readable via the API; see below
content_type                 music              (read_only after setup — D-28)
missing_album_artist_action  folder_name        (default is various_artists — D-01, PERMANENT per D-02)
enabled / status / error     true / loaded / null
```

Created **entirely headlessly** (D-31): `config/providers/setup` → `config/flows/submit` →
`config/providers/save`. The GUI was never opened. `providers/manifests` is the command that lists
addable domains — `providers/available` does not exist.

**⚠ MA 2.11 does NOT expose the provider's `path`.** `config/providers/get` omits it entirely and
`config/providers/get_value {"key":"path"}` returns `Internal server error`. The path is proven
**functionally** via `music/browse "filesystem_local--XJaJWNUS://"`, which lists the 13 exported
artist directories. `02-06-SUMMARY.md` is the **only** record that the value is `/media/music`; a
rebuild must re-run the setup flow with it set explicitly, because the form's default is `/media`.

**MA's `check_write_access()` created nothing** across provider load, reload and a full initial
sync of 2,674 entries — T-02-19 closed on the real code path, not a synthetic probe.

**CRITERION 3 IS PROVEN and CONS-02 is COMPLETE (02-07)** — CONS-03 was correctly *not* ticked there,
and was closed by 02-08's reboots. All three proof albums
exact-matched on album name **and** `artists[0].name`, provider-attributed, inside one deliberately
triggered `music/sync` — **177 s**, not the 12-hour default, which stays untouched per D-38.
`check-music-consumers.sh` exits **0** in steady state. Provider-filtered album count went 20 → 70.

**⚠ THE BIGGEST FINDING IN THE PHASE: `missing_album_artist_action: folder_name` is CONDITIONAL.**
It fires only when a file's `album` **TAG** agrees with its album **FOLDER** name. When it does not,
MA silently falls back to `Various Artists` — while `config/providers/get` still reads back
`folder_name`. Isolated with a 4-cell variant matrix; the track artist tag is irrelevant (a decoy
artist still produced the folder name). **A configured setting is not a firing setting**, and album
identity is `albumartist + os.sep + album`, so a wrong album artist is durable. Phase 7 must treat
album-tag/album-folder agreement as a precondition it *checks*, not one it assumes.

It does fire, at scale: **183 times** across the real library in that one sync (Def Leppard 57,
Taylor Swift 36, Ed Sheeran 28, Katy Perry 27, Hawthorne Heights 17, Sabrina Carpenter 16).

**⚠ A live library defect, recorded and NOT repaired:** `Def Leppard/Def Leppard (2015)/` derives an
**empty** album artist (the album folder name equals the artist folder name) and hard-errors
`CD 01-06 … Sea of Love.flac`. D-05 forbids tag repair and the export is `ro`, so no remedy was
available or attempted. `zpool status -v tank` is clean — this is not scrub damage. Phase 7 inherits it.

**Both temporary artefacts are provably gone**, asserted on both sides (D-46), and those four
assertions are D-45's rollback test — **now executed once against real state**, so 02-09 documents a
tested procedure. `exportfs -v` shows one `/mnt/tank` line, byte-identical to 02-03's; the second
provider is absent; its `library_items` is `[]`; `terraform plan -detailed-exitcode` is 0. The
scratch dataset was destroyed too (Terraform recreates it on the next enable).

**RESOLVED — the `scp` workaround is RETIRED.** The 41 local commits were pushed to `origin/main`
with explicit operator approval (`aa2b502..90cdddc`, clean `git pull --rebase`, no conflicts), and
`git pull --ff-only` in `/mnt/fast/stacks` on LXC 100 now lands
`scripts/check-music-consumers.sh` — verified 2026-09-01, script present at HEAD `90cdddc` and run
from there for both of 02-08's audit gates. **02-09's fold-in into `quick-health-check.sh` therefore
has a real pull path**, which closes the blocker 02-05, 02-07 and 02-08's first half all flagged.

Before any Terraform work, read the CORRECTION entries under Blockers/Concerns — a bare
`terraform apply` was measured to be one command away from destroying LXC 100, and port 111 was
already open so only 2049 is this phase's delta.

## Performance Metrics

**Velocity:**

- Total plans completed: 55
- Average duration: ~42m (excluding 01-06's 374-minute observation window)
- Total execution time: ~375m of work

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 9 | ~375m | ~42m |
| 02 | 9 | - | - |
| 02.1 | 14 | - | - |
| 03 | 11 | - | - |
| 05 | 11 | - | - |

**Per Plan:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| 01-01 | 20m | 3 tasks | 1 file |
| 01-02 | 25m | 3 tasks | 1 file |
| 01-03 | 45m | 3 tasks | 2 files |
| 04-14 | ~16m | 3 tasks | 1 file |

**Recent Trend:**

- Last 5 plans: 01-01 (20m), 01-02 (25m), 01-03 (45m)
- Trend: rising — 01-03 carried a 9,736-file measurement run, not just script authoring

*Updated after each plan completion*
| Phase 01 P04 | 55m | 2 tasks | 1 files |
| Phase 01 P05 | 35 minutes | 3 tasks | 10 files |
| Phase 01 P06 | 65m + 374m watch | 3 tasks | 3 files |
| Phase 01 P07 | ~40 minutes | 2 tasks | 3 files |
| Phase 01 P08 | ~35 minutes | 3 tasks | 2 files |
| Phase 01 P09 | ~55 minutes | 4 tasks | 5 files |
| Phase 02 P02 | 28min | 3 tasks | 3 files |
| Phase 02 P01 | 75m | 4 tasks | 3 files |
| Phase 02 P03 | 25min | 3 tasks | 2 files |
| Phase 02 P04 | 78min | 3 tasks | 1 files |
| Phase 02 P05 | 13min | 3 tasks | 1 files |
| Phase 02 P06 | 6min | 2 tasks | 1 files |
| Phase 02 P07 | 27min | 3 tasks | 2 files |
| Phase 02 P08 | 195m | 3 tasks | 3 files |
| Phase 02 P09 | 50 min | 3 tasks | 5 files |
| Phase 02.1 P01 | 12 minutes | 3 tasks | 3 files |
| Phase 02.1 P02 | ~29 minutes (two agents) | 2 tasks | 3 files |
| Phase 02.1 P03 | ~13 minutes (continuation agent) | 2 tasks | 5 files |
| Phase 02.1 P04 | 36 minutes | 3 tasks | 3 files |
| Phase 02.1 P05 | ~25 minutes | 2 tasks | 6 files |
| Phase 02.1 P06 | ~85 minutes | 3 tasks | 3 files |
| Phase 02.1 P07 | ~25 minutes | 2 tasks | 2 files |
| Phase 05 P01 | 12 min | 3 tasks | 4 files |
| Phase 05 P02 | ~35 min | 2 tasks | 4 files |
| Phase 05 P03 | ~75 min | 2 tasks | 5 files |
| Phase 05 P04 | ~60 min | 3 tasks | 11 files |
| Phase 05 P05 | ~40 min | 3 tasks | 11 files |
| Phase 05 P06 | ~55 min | 2 tasks | 8 files |
| Phase 05 P07 | ~30 min | 3 tasks | 10 files |
| Phase 05 P08 | 25m | 3 tasks | 2 files |
| Phase 05 P09 | ~2h25m | 3 tasks | 7 files |
| Phase 05 P10 | ~3 h 20 min | 4 tasks | 8 files |
| Phase 05 P11 | ~50 min | 2 tasks | 7 files |
| Phase 06 P42 | ~15 min | 3 tasks | 2 files |
| Phase 06 P45 | ~25 min | 3 tasks | 5 files |

## Accumulated Context

### Roadmap Evolution

- Phase 02.1 inserted after Phase 2: Jellyfin transcode retention — relocate the anonymous transcode volume off / and set a retention policy (URGENT)

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [06-45]: **CONF-04 stays OPEN and its checkbox stays UNTICKED — the tick gate held.** A tick
  required all four of `BRANCH: A`, `INSTRUMENT RUN: MEASURED`, `JF_AT_TARGET: 3`, `JF_PENDING: 0`;
  the measured state is `BRANCH: B` / `MEASURED` / `0` / `3`. The operator's `negative-carry-e6`
  override carries the Jellyfin half to Phase 7 entry criterion **E6** and is written at every site
  as an auditable **carry of an OPEN requirement, never a close** — the single easiest wrong
  inference for a downstream reader, flagged independently by 06-43 and 06-44.

- [06-45]: **No verification verdict was self-declared.** `06-VERIFICATION.md` keeps
  `status: gaps_found` / `score: 5/6` byte-identical; a `superseded_note:` states that re-scoring is
  **`/gsd-verify 06`'s call** and that running it is the recommended next step. Phase 6's Status cell
  stays `In Progress`; only the plan counter moved, 44/45 → 45/45.

- [06-45]: **Phase 7 entry criterion E6 now carries its two measurements separately**, because
  exactly one moved. The FIRST (Jellyfin's re-probe reaching 4/2/2) is STILL OPEN on a *driven*
  negative — the mtime route is measured false for this estate at Jellyfin 10.11.11, so Phase 7 must
  not repeat it (`DEF-06-45-02`). The SECOND (the ≥4-artist Music Assistant discrimination between
  "MA caps at 3" and "`Twista` specifically failed to map") was never in round 5's scope and stays
  with Phase 7 on every branch.

- [04-14]: **The PRE-HOOK snapshot moved to the `incomplete` tree, chosen on measurement rather than
  taste.** Job A's earliest *possible* destination-tree sighting was 12:18:00.074Z while its
  `Matching` line was already at 12:17:59Z, so the alternative — key the snapshot on first sighting
  with no stability wait — still races the hook and can never be *proven* earlier. Snapshotting while
  the folder is still under `incomplete` makes the ordering **structural**: SABnzbd cannot invoke the
  hook until it has performed the move. The assumption this rests on is named rather than hidden —
  SABnzbd's move preserves bytes — and the byte comparison is what tests it.

- [04-14]: **Where two causes are indistinguishable from the evidence, the ladder resolves to
  UNPROVEN, not FAIL.** Under `direct_unpack = 1` (measured, with `incomplete` and `complete` on the
  same dataset, device 68, and `postproc_time` under 4 s on 86 of 121 music rows) a file appearing only
  at COMPLETION is equally consistent with late extraction and with a hook rewrite. So snapshot
  completeness is *published* (`pre.inv` vs `last.inv`) and every UNPROVEN clause is evaluated before
  every FAIL clause. Reporting a late extraction as FAIL would be a false accusation against a clean
  estate — invariant 1's mirror. Driven by control SC-6, which fed a would-be-FAIL input and got
  `UNPROVEN reason=baseline-stale`.

- [02.1-07]: **A verification embedded in the mutating function it verifies CANNOT be fault-injected
  from outside.** `do_enable` re-captures live state before mutating, so perturb-then-rerun captures
  the perturbation and passes. The fix that generalises: give it a **separately-invocable entry point
  that takes its expectations from the CALLER** (`verify-retention` + `$TRAN09_EXPECT`), and a second
  hook that skips the **carry-across** while never skipping the **verification** (`TRAN09_FAULT=1`),
  so the comparison has a real difference to find and the run is loud and non-zero rather than
  silently permissive. Both were exercised; the sub-action was additionally proven to **pass** when
  it should, because a control that only ever fails is as uninformative as one that only ever passes.

- [02.1-07]: **A per-field comparison is proven per-field only when one field legitimately PASSES
  inside a failing run.** `ThrottleDelaySeconds` was `180` on both sides of the fault-injected
  restore and passed while four others failed. A blanket failure would have failed it too.

- [02.1-07]: **The retention check runs TWICE — before the container restart and again after it.**
  The plan's `key_links` said "verify before the container restart" while its action text said
  "widen the post-restore verification"; both were satisfied rather than one chosen. The pre-restart
  gate returns 1 **without restarting**, because restarting a service the house is watching onto a
  config that silently lost this phase's settings is strictly worse than not restarting at all. The
  post-restart check catches what the pre-restart gate structurally cannot — a Jellyfin that rewrites
  `encoding.xml` on startup.

- [02.1-07]: **The REST-API conversion of `disable-jellyfin-hwaccel.sh` is DEFERRED, not overlooked**,
  and the reason is now recorded in the file: the runbook's value is that it works when Jellyfin is
  **down**, which is exactly the condition an amdgpu incident creates, and the REST route needs a
  running server. 02-04 having landed does not change that.

- [02.1-06]: **VALIDATION row 11's errno pair is INVERTED, and the plan's inference from that was
  TESTED and found FALSE.** An OpenZFS dataset `quota` refusal surfaces as **EDQUOT**
  (`Disk quota exceeded`), not ENOSPC — ENOSPC is a genuinely full *pool*, and this one is 22%
  allocated. The plan says EDQUOT means `refquota` is in force and 02.1-03 picked the wrong property;
  measured, `refquota` is `0`/default and `quota` is `53687091200`/local with no ancestor quota.
  **02.1-03 chose correctly; the RESEARCH's errno mapping is what is wrong.** The consequence is
  worse than the plan described: *both* properties return EDQUOT, so **no** property choice matches
  an ENOSPC-keyed grep, and the estate's greps are blind to a transcode-quota refusal. Row 11 is
  **not marked passed**, no string was inserted to make the check pass, and the ENOSPC phrase is
  named rather than spelled out in the artifact so the grep returns the honest zero.

- [02.1-06]: **VALIDATION row 16's numeric ceiling is unsatisfiable by a working system.** It counts
  only the segments *behind* the download head awaiting the cleaner, and omits the segments *ahead*
  of it that `ThrottleDelaySeconds=180` deliberately buffers. Measured against session B in steady
  state: 119 segments behind + 74 ahead = 192, the exact observed count. Corrected form is
  `ceil((SegmentKeepSeconds + max(ThrottleDelaySeconds,120)) / segment_duration)` plus slack for the
  cleaner's 20 s tick and the throttler's 5 s poll. **Not waived** — what it protected is discharged
  by the cleaner's own log lines, by counts that oscillate rather than climb, and by the ZFS quota.

- [02.1-06]: **an instrument that reads a log MUST assert the log level at grep time.** Run 1 of the
  proof client produced a fully coherent false negative — zero deletion and zero throttling lines on
  both codec branches — because a SIGPIPE `ERR` trap restored the Debug level mid-run and `set +e`
  inside the handler leaked globally, letting the script continue and grep a log at Information.
  Fixes: `sed -n '1,Np'` instead of `| head -N`, an explicit `exit` on any non-zero path inside the
  handler, and a **Debug-liveness assertion** recorded beside every log grep. Third time this estate
  has paid for "silence read as a pass" (01-06's path-set diff, 02-08's `exportfs -v`).

- [02.1-06]: **a transcript must not contain the literal string its own verify greps for, in EITHER
  direction.** 02.1-01 and 02.1-05 both hit the version where correct prose *fails* a check; here,
  prose explaining an *unobserved* string would have *satisfied* a check it must fail. Both the
  ENOSPC phrase and the bulk volume-removal subcommand are therefore named in pieces, with in-band
  notes saying why.

- [02.1-06]: **a credential screen needs a positive control.** The artifacts were screened by pattern
  *and* by grepping the literal key value, with the same grep run against the secrets file to prove
  it could match at all. "0 occurrences" from a grep never shown capable of finding anything is the
  02-08 failure shape.

- [02.1-06]: the two dangling anonymous volumes the 02.1-05 recreate minted were **inventoried and
  NOT removed** — D-11 scopes 02.1-06 to an inventory, the bulk-removal subcommand is rejected by
  the plan, and removing them individually is a change nobody has ruled on.

- [02.1-05]: **VALIDATION row 15's key-set equality was CORRECTED, not waived.** It names
  `ThrottleDelaySeconds` as a changed key, but that value was already `180`, so setting it to `180`
  changed nothing and the equality was unsatisfiable as written — the plan's own prose, the research
  and `jellyfin.yaml` all say `180 -> 180 UNCHANGED`. It conflates "keys SET in the POST body" with
  "keys whose VALUE CHANGED". Replaced with the **subset** direction (`changed − intended == []`,
  which *is* the full-object-replace hazard) **plus** the value assertion — together strictly
  stronger, because a key-set comparison is silent on values and would pass a key changed to the
  *wrong* value. **The row still needs fixing in VALIDATION.md before 02.1-10.**

- [02.1-05]: a stopped **guard container** held the anonymous volume through the recreate, because
  whether compose v5 passes `RemoveVolumes` on `--force-recreate` is undocumented and is not a
  question worth answering by losing the rollback. The answer, for the record: **it does not.** The
  guard was created from the already-resident image (no pull) and removed immediately after, without
  `-v`.

- [02.1-05]: **TRAN-01 marked COMPLETE**, as 02.1-04 said it should be — the declaration and the
  writes finally agree. **TRAN-02, TRAN-03 and TRAN-04 stay Pending despite this plan's frontmatter
  claiming them**: TRAN-02 needs the volume *gone* (02.1-06), and TRAN-03/TRAN-04 need the bounds
  proven **firing** from Jellyfin's own logs rather than read back from the API (02.1-08) — which is
  exactly what this plan did. CONS-04's rule; Phase 2 paid to learn it.

- [02.1-05]: the pre-cutover reconciliation copied 10 live-cache files **deterministically** rather
  than letting row 6's tolerance absorb them, so the 99% floor stays a guard against *collapse*
  rather than a way of tolerating a stale copy. `rsync` is still absent and still deliberately not
  installed; the documented `cp` equivalence was used with per-file exit status.

- [02.1-04]: `transcodes/` (12.55 GiB, 1,324 files) was EXCLUDED from the cache copy — it is
  shadowed by the nested `/cache/transcodes` bind, it is deleted wholesale in 02.1-06, and copying
  it would breach the plan's own headroom precondition. The 391 MiB actually copied is the "392 MiB"
  every plan in this phase reasons about.

- [02.1-04]: the plan's literal headroom precondition (`floor + 2x source`) was REPLACED, not
  waived. Its `2x` term assumes a same-filesystem transient double; `stat -c %d` measures source on
  dev 64519 (ext4, `/`) and destination on dev 63 (zfs), so `/` consumption is zero. Measured
  outcome: `/` went UP 14.0 MiB across the copy.

- [02.1-04]: `rsync` is NOT INSTALLED on LXC 100 and was deliberately not installed — a package
  install to copy 391 MiB that `cp` copies correctly adds supply-chain surface for no gain. The
  documented equivalence `cp -r -d --preserve=timestamps` == `rsync -rlt --no-p --no-o --no-g` was
  used, with per-file exit status branched on rather than a printed summary.

- [02.1-04]: assumption **A5 CONFIRMED** — `fast/appdata/media` is `acltype=nfsv4` with
  `aclmode=passthrough` (not `restricted`), and `cp --preserve=all` succeeds there preserving mode
  and ownership. The `tank` EPERM failure mode does not apply to this dataset.

- [Roadmap]: Harness before spike — every harness item is tagger-independent and several protect
  assets that cannot be recreated.

- [Roadmap]: Phase 2 (NFS/MA) runs in parallel from the start and must complete before Phase 7 —
  Music Assistant never purges stale entries, so it is proven before content flows, not after.

- [Roadmap]: Phase 4 (retirement) is independently shippable — a fourth stall must still leave the
  estate with one tagger, one database, no idle container holding a rw mount.

- [Revision 2026-08-17]: **The library is not empty, so "it imported" is not the bar — "it did not
  get worse" is.** QUAL-01 puts a re-runnable before-state tag snapshot in Phase 1, before anything
  is staged; QUAL-02 gates the pilot on a field-level before/after diff with no net metadata loss.
  A file can pass CONS-04 in full while having lost fields it arrived with.

- [01-09 / Phase 1 closure]: **Library ownership is `568:568`; modes stay `0777`.** `568` is `apps`
  (four independent repo references, 76% of 535,298 media entries); the gid it replaced, **545, is
  an orphan** — `getent group 545` returns nothing on atlantis. The `0755`/`0644` target is recorded
  but **not achieved**: `chmod` fails `EPERM` on `tank` even as real root. Phase 2's export must be
  read-only as a result.

- [01-09 / Phase 1 closure]: **Jellyfin's Music metadata freeze is permanent, and Jellyfin stays the
  documented sole `rw` holder rather than going `:ro`** — consumer-class, frozen at the application
  layer, counted in its own audit class. Measured limit: `SaveLocalMetadata: false` does not stop an
  explicit `FullRefresh`.

- [02-09 / Phase 2 closure]: **Route A wins — Music Assistant reads the library through an HA
  Supervisor NFS network-storage mount, not through MA's own remote-share provider.** The losing
  route's failure symptom, recorded so it is not revisited: **Route B exposes no client-side `ro`
  option at all** (MA hardcodes its NFS option list), so it would have discarded a layer of defence
  in depth. MA's own documentation is **empirically disproven** on the sentence that created the open
  question — `docker exec … ls /media/music` inside the running add-on returns the 13 artist
  directories. PROJECT.md's prior "OPEN QUESTION" passage is **rewritten**, not supplemented.

- [02-09 / Phase 2 closure]: **`missing_album_artist_action: folder_name` is permanent — and it is
  CONDITIONAL.** It fires only when a file's `album` **tag** agrees with its album **folder** name;
  on a mismatch MA silently yields `Various Artists` while `config/providers/get` still reads back
  `folder_name`. **Reading the setting back is not proof it applies, and the API cannot tell you it
  did not fire.** Phase 7 must check the precondition, not assume it.

- [02-09 / Phase 2 closure]: **The export's `mountpoint` option stays, and is PROVEN** by
  control-probe-control (mounted → exit 0/14 entries; unmounted → exit 255/ENOENT/0; remounted →
  exit 0/14). It is in **neither** of CLAUDE.md's original candidate option sets. `ro` is **forced**,
  not chosen: the tree is `0777` and ZFS NFSv4 ACLs are not exported by knfsd, so mode bits are the
  only lever a client sees.

- [02-09 / Phase 2 closure]: **`sec=sys` on a trusted LAN is an accepted residual risk, recorded as a
  CHOICE.** Anything that can present as `172.16.1.31` can read the library. `xprtsec=` (RFC 9289,
  needs `tlshd` both ends) and `sec=krb5` (needs a KDC, unproven on HAOS) were both considered and
  rejected. The tailnet address is deliberately absent from the export line.

- [02-09 / Phase 2 closure]: **Standing coverage beats a one-off proof.**
  `scripts/check-music-consumers.sh` is folded into `scripts/quick-health-check.sh`, the path already
  in use. With the MA add-on on `auto_update` against a BETA (`2.11.0b0`), this is the only detector
  of an MA release changing provider behaviour under the pipeline.

- [01-09 / Phase 1 closure]: **`quick-health-check.sh` can now exit non-zero**, and the freeze
  harness runs on it. The library **mode** assertion was scoped to a report inside
  `check-music-freeze.sh` — a permanently-red check trains the reader to ignore it, which is the
  failure the fold-in exists to prevent. Ownership stays a hard assertion.

- [01-09 / Phase 1 closure]: **`/mnt/tank/media/TV` — 114,218 entries on orphan gid 545 — is
  recorded, not actioned.** No requirement covers it, and scope growth followed by abandonment is
  this project's documented failure mode. Working method recorded in `beets.md` (run `chown` from
  the Proxmox host, never LXC 100).

- [01-09 / Phase 1 closure]: **Six times this phase a check reported a pass it had not earned**, all
  from the same root: partial data stated as settled. The rule now written into `beets.md` — verify
  with a second independent instrument before writing it down.

- [Revision 2026-08-17]: **Ergonomics is a scored axis in the Phase 3 spike, not a footnote**
  (TAGR-06). Two separate questions: which engine (beets vs wrtag) and how the human meets it (raw
  CLI vs a reviewable queue). beets-flask is evaluated by name on the second. The operator's
  first-hand experience is that beets has been painful to get working, and a painful tool is the
  documented cause of all three prior abandonments — so the second axis may decide whether this
  finishes more than the first does.

- [Revision 2026-08-17]: **The pilot must meet the hard shapes** (QUAL-03) — at least one
  various-artist compilation and one multi-disc release, both historically painful here. Twelve
  clean single-artist albums would prove a flow that has never faced the real case, and would leave
  CONF-03 / CONF-05 asserted rather than exercised.

- [Revision 2026-08-17]: **Undo is a pilot gate** (QUAL-04), not a nice-to-have. At Phase 9 scale,
  "I cannot cleanly back this out" is indistinguishable from abandonment.

- [Revision 2026-08-17]: Replacing Lidarr is wanted and recorded as LIDR-01 in v2, deliberately not
  in this milestone. WRIT-03 already stops it writing to the library, which removes the harm; the
  rest is a separate project with its own migration.

- [01-01]: zfs is not resolvable inside LXC 100 (unprivileged); harness zfs queries are delegated over ssh to the Proxmox host 172.16.1.158
- [01-01]: audit scripts exit 1 on any failed assertion, exit 0 only in --baseline mode; the estate had no such convention and its silence hid a six-week outage
- [01-01]: WRIT-04 is ~2x its assumed size — 2,543 of 2,673 library entries have the wrong owner and every file and directory is mode 0777, so D-13's chmod pass touches 100% of the tree
- [Phase ?]: [01-03]: audio_md5 (ffmpeg -map 0:a -c copy -f md5) is the QUAL-01/QUAL-02 join key; proven by a flat 2CD set where all 21 track numbers collide and neither path nor filename disambiguates the disc
- [Phase ?]: [01-03]: D-02 scope is 9,736 audio files and 170.12 GiB, not 9,764 and ~140 GB; plan 01-04 projects to ~36 min, CPU-bound on md5 hashing and single-threaded, so it can run attended
- [Phase ?]: [01-03]: the unsorted and dj-mixes copies of Now! 120 are the SAME rip - 20/20 audio_md5 shared, 0 unique to either side; first hard DUPE-01 measurement, covering 1 of the 85 shared folder names
- [Phase ?]: [01-02]: fence copies made with sqlite3 .backup are verified with PRAGMA integrity_check, not sha256 equality — the plan mandated both and they are mutually unsatisfiable; cover scans still held to strict sha256
- [Phase ?]: [01-02]: the Mac Mini's non-interactive ssh PATH lacks head/basename/sqlite3 — verification over ssh must use absolute tool paths and keep stderr, or it fails closed and reports false corruption (cost two false 'all 15 databases bad' results)
- [Phase ?]: [01-02]: '794 dj-mixes files' is wrong — there are 764 audio files; the 794 figure was 764 audio + 30 jpg and missed the 24 BMP cover scans entirely
- [Phase ?]: 01-05: Photos gets no mount in any narrowed container — only Jellyfin retains it via its D-21 carve-out; containers able to reach it went 8 -> 1
- [Phase ?]: 01-05: wrtag frozen via 'compose --profile manual down'; a plain 'compose up -d' on the music stack now returns 'no service selected' — the gate is proven, not asserted
- [Phase ?]: 01-05: lidarr deliberately untouched (01-06 owns WRIT-03), so it is the single remaining rw holder in BOTH audit classes — expected, not a regression
- 01-06: WRIT-03 met — lidarr root folder off the library, renameTracks off, all metadata consumers off (already were), media mount :ro proven by an in-container write attempt; tagger-class rw holders on the library is now 0
- 01-06: deleting an *arr root folder does NOT repoint its artists — all 22 lidarr artists keep absolute /media/Music paths, so D-25's :ro mount is the load-bearing control, not D-23's root-folder move
- 01-06: SaveLyricsWithMedia is a THIRD Jellyfin write switch that SaveLocalMetadata does not gate; it wrote 944 of the 1,123 baseline sidecars. Any "is Jellyfin frozen?" check that reads only SaveLocalMetadata gives a false pass
- 01-06: lidarr had a DELETE path into the library (mediamanagement.deleteEmptyFolders: true) that WRIT-03 and D-24 do not count as a write path; now false
- 01-06: the SAFE-05 sidecar set is widened to .nfo/.jpg/.lrc/.png/.txt — 1,341 files, 19.4% more than D-18's 1,123; the narrow subtotal is still printed for comparability with the 01-01 baseline
- 01-06: **the SAFE-05 test as the roadmap words it is a path-set diff, and a path-set diff is structurally blind to the most likely form of Jellyfin pollution.** Measured: it returned 0 added / 0 removed while Jellyfin rewrote 83 of the library's 91 .nfo in place, 66 with genuinely changed content. Widening the extension set does NOT fix this — the comparison had to change. The watch now checks sha256 content, a whole-library size/mtime manifest, and a ZFS snapshot cross-check
- 01-06: **SaveLocalMetadata=false does NOT stop an explicit Jellyfin FullRefresh writing .nfo.** It gates the automatic scan-time save path only. The first .nfo was rewritten 1 second after the refresh POST, with the setting already false and read back from the API. SAFE-05 is true for "Jellyfin writes nothing unprompted" and FALSE for "Jellyfin cannot write" — a UI "Refresh metadata" click still writes. The only structural control would be an :ro mount, which D-21 deliberately rejected
- 01-06: the @pre-project ZFS snapshot was used in anger and works — SAFE-02 proven, not asserted. `snapdir=hidden`, so `/mnt/tank/media/Music/.zfs/snapshot/pre-project` must be typed; it will not list
- [Phase ?]: There are five beets configs in the estate, not three — beets' scrub/lastgenre/embedart/fetchart auto keys all DEFAULT to on, so an absent key was an armed key
- [Phase ?]: appdata/arrs/beets/config/config.yaml is a docker-compose file saved into BEETSDIR — beets ran on pure defaults and imported 47 tracks into /config/Music/__/
- [Phase ?]: find -xdev is unsafe for estate sweeps: /mnt/fast/appdata/* are separate ZFS datasets, so a sweep from /mnt/fast silently skips appdata and exits 0
- [Phase ?]: 01-08: the WRIT-04 chown must run on the Proxmox host - LXC 100 is unprivileged and physically cannot chown the library's unmapped uids/gids (EPERM, a different mechanism from aclmode=restricted with the same errno)
- [Phase ?]: 01-08: the 01-01 ownership census recorded the CONTAINER's view, not the disk - six on-disk owners collapse to five, and its writer attributions are wrong
- [Phase ?]: 01-08: D-11's 568:568 confirmed on evidence - Music was the only media subtree on gid 545 while Movies was already 568:568, so beets.md's 568:545 describes drift and D-14 stands
- [Phase ?]: 01-08: mode pass skipped with a printed explanation rather than run or swallowed; no zfs set of any property was executed
- [Phase ?]: 01-08 CORRECTION: gid 545 is NOT Music-specific - TV carries 114,218 entries on the same orphan gid (48x Music). The estate is split: Music+TV on 545, Photos+Movies+Books on 568. D-11's 568:568 still stands, but because 545 is an orphan gid (no group entry, unmapped in the LXC idmap) and 568 is the documented convention - not because Music was uniquely wrong
- [Phase ?]: 01-08: uid 3000 owns 197,776 of tank/downloads' 209,039 entries (94.6%) - the download client's identity, and the same uid as the library's .DS_Store; resolve before Phase 5 stages _inbox there
- [Phase ?]: 02-02: NFS music export defined in Terraform (infra/nfs-music-export.tf) - ro,all_squash,anonuid/anongid interpolated from var.apps_uid/gid, mountpoint, no_subtree_check, sec=sys, to 172.16.1.31 only; fsid=, crossmnt and no_root_squash absent with recorded reasons
- [Phase ?]: 02-02: xprtsec= (RFC 9289) and sec=krb5 considered and rejected in the file header; sec=sys on a trusted LAN recorded as an accepted residual risk
- [Phase ?]: 02-02: temporary control export is count-gated on music_temp_export_enabled (default false) - teardown is a terraform apply, not a memory
- [Phase ?]: 02-03: NFS export APPLIED and live — ro,all_squash,anonuid=568,anongid=568,mountpoint to 172.16.1.31 only; re-apply exit 0; served from atlantis, LXC 100 proven unable (unprivileged)
- [Phase ?]: 02-03: M1 (mountpoint export option) is NOT enforced at exportfs time on nfs-utils 1:2.8.3-1 — exportfs -au + -a silently re-creates the line while the dataset is unmounted. Configured-but-UNPROVEN; M2 (After=zfs-mount.service) is the proven guard; 02-05 must settle it client-side
- [Phase ?]: 02-03: CONS-01 deliberately NOT ticked — criterion 1 parts 1d/1e need a client and belong to 02-05; traceability row records the interim state
- [Phase 2]: 02-04: MA 2.11 has no API-token UI — check-music-consumers.sh logs in per run rather than caching the 90-day JWT, so the credential cannot expire silently inside an unattended check (D-39 intent, not its literal 365-day wording)
- [Phase 2]: 02-04: music/albums/count has NO provider parameter (returned 87 with and without one) — mount liveness uses provider-filtered music/albums/library_items instead; count would report green off Spotify's catalogue with the NFS mount absent
- [Phase 2]: 02-04: D-08 fired — the library has no Various Artists compilation (all 13 folders are single named artists), so the VA shape is substituted by VA-Mastermix.Essential.Hits.Pop.4 from the backlog, staged by 02-07 under the temporary export
- [Phase 2]: 02-05: ROUTE A WINS on measurement — /media/music is readable INSIDE the running Music Assistant container (rslave, master:1105, container up 2 days before the mount existed). MA's own docs say this is impossible; they mean local bind mounts. Route B's failure symptom: it exposes no client-side ro option at all
- [Phase 2]: 02-05: CRITERION 2 PROVEN AT THE EXPORT LAYER — a hand-rolled mount -o rw succeeded and every write was still refused EROFS. Re-run over NFSv4.2 because the plain mount -o rw negotiated vers=3, which is NOT the version MA reads through. Read-only holds on both
- [Phase 2]: 02-05: CONS-01 is COMPLETE — 1d proven by nc 2049 exit 0 plus a successful mount (showmount is absent on the NUC), 1e by /proc/self/mountinfo fstype nfs4 vers=4.2 (findmnt is absent too)
- [Phase 2]: 02-05: ssh -n EATS A HEREDOC — -n points stdin at /dev/null so 'ssh -n host bash -s <<EOF' discards the whole script and exits 0. Use -n for inline 'ssh host cmd' ONLY; never when feeding a script over stdin
- [Phase 2]: 02-05: the NFSv4 pseudo-root entries in /proc/fs/nfsd/exports carry no_root_squash (/, /mnt, /mnt/tank, /mnt/tank/media — all v4root and ro). Not a T-02-06 regression, but a grep of that table returns 4. Assert on exportfs -v, which check-music-consumers.sh already does
- [Phase 2]: 02-06: missing_album_artist_action=folder_name on the MA filesystem_local provider is PERMANENT (D-02), not a pilot setting
- [Phase 2]: 02-06: the MA provider was created entirely HEADLESSLY via config/providers/setup + config/flows/submit + config/providers/save (D-31); the GUI was never opened
- [Phase 2]: 02-06: MA 2.11 does NOT expose the filesystem provider's path via config/providers/get; /media/music is proven functionally via music/browse and recorded only in 02-06-SUMMARY.md
- [Phase 2]: 02-07: CRITERION 3 PROVEN — three albums exact-matched on album name AND artists[0].name, provider-attributed, in 177s via a deliberate music/sync rather than the 12-hour default (D-38 untouched)
- [Phase 2]: 02-07: missing_album_artist_action=folder_name is CONDITIONAL — it fires ONLY when the album TAG matches the album FOLDER name; otherwise MA silently uses Various Artists while config/providers/get still reads back folder_name. Isolated with a 4-cell variant matrix; the track artist tag is irrelevant
- [Phase 2]: 02-07: Def Leppard/Def Leppard (2015)/ derives an EMPTY album artist and hard-errors one file, because the album folder name equals the artist folder name. Recorded NOT repaired — D-05 forbids tag repair and the export is ro
- [Phase 2]: 02-07: a null_resource destroy removes NOTHING from the host — music_temp_export_enabled=false was not a teardown until 02-07 added an always-present reconciler resource. A destroy-time provisioner cannot be used: terraform validate refuses it, and the workaround puts the Proxmox root password in plaintext state and in every plan diff
- [Phase 2]: 02-07: MA 2.11's search arg on music/albums/library_items is NOT a substring match — searching an album's OWN EXACT NAME returned [] while a one-word prefix returned it. Filter on provider only and do the exact match locally, or the gate reports a false FAILURE
- [Phase 2]: 02-07: config/providers/remove is a COMPLETE purge of everything exclusive to that instance (84->79 albums, exactly -5; 55 tracks, 47 artists), no orphans — and it drops every favourite and play count attached to them
- [Phase 2]: 02-08: CONS-03 COMPLETE — criterion 4a passed (boot_id changed, zero manual intervention, 70 albums, both proof albums EXACT) and criterion 4b FIRED (Supervisor read-only fallback, MA 'Aborting sync … 1244 previously indexed', 70 albums preserved through the degraded window — stale not empty)
- [Phase 2]: 02-08: unattended recovery of a failed HAOS media mount is REAL and takes 432 s (7 m 12 s) on this estate at this version, not the ~900 s the research assumed — NUC untouched throughout, and M4b re-synced MA on its own at 13:12:06Z
- [Phase 2]: 02-08: M1 IS PROVEN, superseding 02-03 and 02-05 — the mountpoint export option DOES make rpc.mountd refuse a fresh client mount when the dataset is unmounted (exit 0/14 entries mounted vs exit 255/ENOENT/0 unmounted). The earlier 'unproven' readings were an INSTRUMENT ERROR: exportfs -v keeps printing the line, so the export table is non-discriminating while the served mount is refused
- [Phase 2]: 02-08: 'mount | grep emergency/music' can NEVER match on this Supervisor version — it makes the media directory read-only IN PLACE (dr--r--r--, 0 entries) rather than bind-mounting /mnt/data/supervisor/emergency/music. The working proof line is /media/music empty and dr--r--r--
- [Phase 2]: 02-08: an HA numeric_state trigger fires on a CROSSING and is armed only by a non-matching change, so it is structurally unable to fire on a boot into an already-failed state — and a state 'to:' trigger misses it too, because the sensor lands on its boot value 6-15 s BEFORE the automation attaches. Only a 'homeassistant event: start' trigger, which fires at attach time, can catch a fault that predates the automation
- [Phase 2]: 02-08: put the debounce in the ACTION (delay + re-read) rather than 'for:' on the trigger — 'for:' leaves no trace that the trigger ever armed, which is exactly how D-54a's defect stayed hidden for a plan and a half
- [Phase 2]: 02-08: D-54b's repairs-issue trigger is correct (synthetic event fired it in 542 ms) but is blind at boot by ORDERING not race — hassio mirrors Supervisor issues into HA's repairs registry ~17 s before the automation domain sets up, identically across four observed HA starts. Left open deliberately
- [Phase 2]: 02-08: the default 'ha supervisor logs' window does not reach back to boot — a default-depth grep for 'read-only fallback' returns nothing and is indistinguishable from 'it did not happen'. Use -n 2000 or deeper
- [Phase 2]: 02-08: the HAOS SSH add-on is NOT privilege-limited — sudo is NOPASSWD:ALL, CapBnd carries CAP_SYS_ADMIN and Protection mode is already off. The 02-05/02-08 probes failed for want of 'sudo', not for want of privilege
- [Phase ?]: 02.1-01: TRAN-01..09 are a PHASE INSERTION, not a milestone scope change — the v1 denominator stays at 39 and the nine are subtotalled separately (39 + 9 = 48). Incrementing it would make every prior 'N of 39' statement incomparable with every later one, in a milestone that is already part-executed
- [Phase ?]: 02.1-01: PHASE-START READING IS NOT WHAT THE PLAN SET ASSUMED — / is at 20.18 GiB avail, only 185 MiB above the D-17 20 GiB floor, not the ~33-36 GiB the plans were written against. The transcode cache has ALREADY refilled to 12.55 GiB across 1,324 files since the container came up 2026-08-31 (~6 GiB/day). The D-32 gate passes so the phase proceeds, but at that rate / crosses the floor in ~1 day and hits zero in ~3. Any stall — especially 02.1-09's blocking human gate — spends a budget measured in hours. Verified with stat -f as a second instrument. **[SUPERSEDED 2026-09-03 — kept as the record of what was true at phase start, but do NOT restate it as current.** 02.1-05's cutover stopped the ~6 GiB/day clock, 02.1-06 released the 12.55 GiB stock, and 02.1-09's reap freed a further 1.45 GiB. `/` margin is now **14.49 GiB**, not 185 MiB. The blocking human gate ran at wave 8 exactly as D-31 intended and cost the phase nothing.**]**
- [Phase ?]: [02.1-02]: jq's `//` is the ALTERNATIVE operator and treats `false` as empty as well as `null` — never use it to read a boolean back. The standing check's own first --baseline printed EnableSegmentDeletion, EnableThrottling and EnableHardwareEncoding as `<absent>` when all three were genuinely `false`, including the amdgpu mitigation flag where absent and false carry OPPOSITE implications for a ~6-hour outage hazard. An <absent> baseline would also have made 02.1-07's before/after read as 'the key appeared' rather than 'the value moved'
- [Phase ?]: [02.1-02]: a green `zfs get quota` on an UNMOUNTED dataset is a false pass — the bind still works, the container still writes, and the quota does not apply, while the property still reads 53687091200. The standing check asserts `mounted` by two instruments with no shared failure mode: the ZFS property from atlantis over ssh, and a container-side `stat -c %d` device-id comparison that needs neither ssh nor zfs. Baseline confirms the split is real: mounted GREEN, quota RED
- [Phase ?]: [02.1-02]: `/` margin is 182.6 MiB, tripping 02.1-02's own ~5 GiB stop condition. The plan was finished anyway because every action in it is read-only with respect to `/`. **The operator ordering decision is OWED BEFORE 02.1-03** (the first mutation): should 02.1-09's image reap move ahead of it? D-31 put the reap last when the plan set assumed ~13 GiB. Also measured: the cache was byte-identical across two watch samples 16 min apart — it grows during playback, not on a wall clock
- [Phase 02.1]: [02.1-03]: OPERATOR RULED OPTION B on the pre-existing exit-2 Terraform drift — clear it as its own separate, mechanically-asserted no-op apply FIRST, then execute against a genuinely clean exit-0 baseline. Chosen over proceeding with a documented exception because VALIDATION row 28 is a row this phase gets verified against and only B satisfies it literally. Two applies, each from its own saved workstation-local plan file, each asserted before it ran: count=0/destroys=0/addresses=[] then count=1/destroys=0/addresses=[null_resource.jellyfin_transcode_dataset]. Neither plan file was committed
- [Phase 02.1]: [02.1-03]: ASSUMPTION A3 IS CONFIRMED, BYTE-EXACT — df -B1 --output=size /mnt/fast/transcode inside LXC 100 went 1442767175680 to 53687091200, zero delta against the target, corroborated by stat -f (51200 blocks x 1048576 bsize). ZFS derives statvfs f_blocks from referenced+available with available capped by the quota, so the standing check gains a second instrument for the bound that needs neither ssh nor zfs. It proves the quota is SET, never that it FIRES — that is 02.1-08, and row 9 stays the primary
- [Phase 02.1]: [02.1-03]: TRAN-07 COMPLETE, TRAN-03 deliberately NOT — TRAN-07's two clauses (declared in infra/ Terraform; the apply provably scoped to that one resource with zero destroys) are both discharged with committed evidence, while TRAN-03 requires the bound proven FIRING rather than set. Read back from atlantis: quota=53687091200, compression=off, sync=disabled, recordsize=1048576, atime=off, mounted=yes, and stat 2775 apps:apps — the setgid bit survived the guarded chown plus unconditional chmod
- [Phase 02.1]: [02.1-09]: A DOCKER SIZE FORECAST AND A `df` DELTA ARE NOT THE SAME UNIT, and the difference is large enough to look like a beaten estimate. The reap forecast ≈1.09 GB and `df` moved 1.45 GiB — 42% more. `docker system df` Images SIZE (deduplicated) moved exactly 1.09 GB, so the forecast was right; `docker system df` reports APPARENT bytes while `df` reports ALLOCATED BLOCKS, and ext4 rounds every file to 4 KiB. Measured on the surviving keeper-web:2.23 sibling: 107,030 files, allocated/apparent = 1.342, i.e. 191.2 MB of rounding overhead in one image. Forecast in Images-SIZE terms and expect `df` to move MORE, by ~1.2-1.4x for many-small-file images
- [Phase 02.1]: [02.1-09]: `docker system df` RECLAIMABLE HAS NOW MISLED IN BOTH DIRECTIONS — it ROSE 0.57 GB during 03-01's 18 GiB reclaim and FELL only 0.21 GB during this 1.45 GiB one. Two observations, opposite signs, same conclusion: it does not track real disk and is context, never a target. The auditable per-tag diff and the measured byte delta are the evidence
- [Phase 02.1]: [02.1-09]: `docker run --rm <image>` IS A PULL when the image is absent, and it is indistinguishable from a local run once it succeeds. The executor broke this plan's own no-pull constraint reaching for `curlimages/curl:latest` to probe an HTTP endpoint — an image 03-01 had already reaped. On a freshly reaped host the generic utility images are precisely the ones most likely to be gone. Probe with an image confirmed present in the before-listing, or `docker exec` into a running container. Reverted, and the store re-diffed identical to the recorded after-listing
- [Phase 02.1]: [02.1-09]: WHEN AN IMAGE COUNT AND A TAG COUNT MOVE BY THE SAME AMOUNT, that equality is itself the finding — it proves no removed image carried a second tag, so no multi-tagged removal is hiding in the accounting. Five separate measures were recorded on both sides and all five moved by exactly 4. Dangling staying 9 -> 9 is the matching scope assertion: the three unreferenced untagged digests were surfaced and deliberately NOT deleted
- [Phase 02.1]: [02.1-09]: A PRUNE EXIT CODE THAT ASSERTS A FLOOR THE HOST ALREADY CLEARED IS NEAR-VACUOUS EVIDENCE. `FLOOR_GB=20 ... prune` exiting 0 would have passed identically had it deleted nothing, because `/` was 13.11 GiB clear of the floor beforehand. Recorded as such rather than banked as a pass. Also: `already reclaimed: 0` alongside `removed: 4` is the positive evidence a destructive run happened exactly ONCE — a second invocation inverts the pair
- [Phase 05]: [05-01]: D-21's negative control targets LXC 100's ext4 root, not the library — Phase 1 D-20 stays untouched
- [Phase 05]: [05-01]: the library mount path is kept out of Task 2's prose as well as its commands, so the criterion stays mechanically checkable
- [Phase 05]: [05-01]: host-side task evidence is committed as repo artifacts, because all three of Task 1's deliverables are otherwise off-repo
- [Phase 05]: [05-02]: criterion 4 is now a STANDING ASSERTION in quick-health-check.sh (seventh fatal block), driven RED on a real /mnt/tank/media/Music/_probe created from atlantis as root and GREEN after rmdir — not a green claim
- [Phase 05]: [05-02]: quick-health-check.sh has NO fail()/FAILURES helper — that is check-jellyfin-transcode.sh's mechanism; this file's failure counter is EXIT_CODE=1, and the plan named the wrong file
- [Phase 05]: [05-02]: the whole-script exit code is NON-DISCRIMINATING for criterion 4 while check-music-freeze.sh's interpolated-host-path inventory (expected=12, found=13) stays red — read the block's own verdict line; logged in deferred-items.md, not fixed
- [Phase 05]: [05-03]: the junk gate is two processes joined by a file on disk (D-13); sweep refuses without both the approved list and a proof naming tank/downloads@pre-phase5
- [Phase 05]: [05-03]: .covers directories are VALUE-FLAGGED, never hard-KEPT — this half of the gate proposes, the operator decides
- [Phase 05]: [05-04]: move-only is a property of the ROW (a destination field), not of the RULE — relabelling a spared row R8 would misreport it AND weaken its TOCTOU re-validation from rule+audio+size to audio alone
- [Phase 05]: [05-04]: an approved destructive list is amended MECHANICALLY by one awk program, never by retyping a path — and the amendment procedure itself is driven on a synthetic fixture before it touches the live list
- [Phase 05]: [05-04]: the 8 .covers rows were STRUCK from the approved list rather than redirected — a row in the list is a row the sweep moves, so striking is the only treatment that leaves them provably untouched
- [Phase 05]: [05-05]: D-04 CLOSED — volumes 4/8/9 have NO surplus. The +13/+9/+14 reproduces exactly under the album-tag grouping and vanishes under the manifest volume directory; the tag is "Now That's What I Call Music 4/8/9" WITHOUT the exclamation mark and cannot separate three editions. Both instruments agree on the file sets (45/42/44), so nothing is mis-tagged in from another volume and the split is safe.
- [Phase 05]: [05-05]: the 24-entry gap is COLLISION, not absence — 0 manifest lines lack a file on disk; 23 physical files are claimed by more than one volume directory (one by three). Named in artifacts/05-05-collided-files.tsv. Plan 05-06 needs an explicit placement rule; a file cannot be moved into two folders.
- [Phase 05]: [05-05]: group the Now! collection by the manifest volume directory found from the END of the path, never by a fixed field index (three path depths) and never by a trailing-number parse of the album string (D-03). 119 distinct directories, not the documented 116.
- [Phase 05]: 05-06: volume numbers come only from the manifest DIRECTORY component via a recorded rule chain; no regex touches an album value, and total coverage of 1..115 is asserted rather than counted
- [Phase 05]: 05-06: the 4 cross-volume collisions surviving the variant-edition merge are decided by the file's own album tag, with the rejected claim recorded in the map row; zero guessed, zero flagged
- [Phase 05]: 05-07: An operator approval is bound to a CONTENT HASH, re-read both before the first destructive act AND after the last — the second reading is what proves the tool acted FROM the approved artifact rather than rewriting it
- [Phase 05]: 05-07: A destructive batch is reconciled against `zfs diff`, not against the tool's own counters — a tool reporting on itself cannot detect a path it affected but never recorded; an off-map path is a FAILURE, not a footnote
- [Phase 05]: 05-07: Assert the (devid, inode) PAIR across a rename, never the inode alone — this estate has a known inode collision (tank/downloads and tank/media/Music both report inode 34), so an inode-only assertion can agree by accident
- [Phase 05]: 05-08: the Phase 5 tag fence is a SECOND, NARROWER named (root, snapshot) pair scoped to the Now! collection folder — SCRATCH_ROOT is byte-identical and no constant equals /mnt/tank/downloads, so SABnzbd's live working tree never enters a tag writer's reach
- [Phase 05]: 05-08: rule 4 derives the canonical album from the Vol NNN FOLDER, never from the album tag (D-03) — volume 36's three spellings, including the double-space one, collapse to one value across all 40 files
- [Phase 05]: 05-08: rule 4 proposes on every file and marks the 3,995 already-correct ones noop, so the review artefact shows total coverage while 05-09's apply writes only the 751 that differ
- [Phase 05]: 05-09: Pilot moved from the plan's Vol 077 to Vol 036 on the operator's amendment — Vol 077 has zero proposed changes, so its gate would have passed vacuously; Vol 036 is the only volume whose files do not all share one album value
- [Phase 05]: 05-09: The plan's zfs diff scope criterion is NON-DISCRIMINATING here and was replaced, not quoted — 05-07 renamed every mp3, and zfs diff collapses renamed-and-modified into a single R, so it reports 0 M lines on any mp3 whether 751 files were written or none
- [Phase 05]: 05-09: D-10's album write is COMPLETE — 751 files in 22 volumes, album the only field changed, audio_md5 unmoved on all of them, and each of the 115 volume folders now carries exactly one album string
- [Phase 05]: 05-10: D-24's scope was NARROWED from 222,376 entries to 26,005 by the operator, on a survey D-24 was written without — 84% of it was a personal Dropbox mirror and one subtree was being read by a live import. 26,005 + 196,371 excluded = 222,376, so the arithmetic closes and nothing was quietly dropped
- [Phase 05]: 05-10: A decision's own stated rationale is evidence to be tested, not a premise — D-24's preserved counter-argument said uid 3000 is the download client legitimately owning what it wrote; uid 3000 is outside every LXC 100 idmap range, has no passwd entry, and SABnzbd's own output is 568:568
- [Phase 05]: 05-10: Put every fence that needs no remote access AHEAD of the remote access — with the row fence sitting after route detection, all five excluded-tree negative controls exited 2 on 'no zfs route' and proved nothing while looking green
- [Phase 05]: 05-10: Prove an untouched-claim with an instrument driven to FAIL on the same shape of change elsewhere, and prefer a whole-DATASET instrument over a whole-ROOTS one — zfs diff can see a reach into a tree the positive instrument never walks
- [Phase 05]: Phase 5 closed at 4/4 criteria TRUE, every one re-measured from live state at close rather than carried forward from the plan summaries (05-11)
- [Phase 05]: Criterion 4's negative control was deliberately NOT re-driven at close — creating a probe inside the library for no benefit; the 2026-09-18 plan 05-02 run is cited with its date instead
- [Phase 05]: The Potter clause is recorded satisfied on the NAMED path and the -iname '*potter*' form recorded as now-invalid (it matches a real song in Vol 066), rather than widening the pattern to force a zero

### Pending Todos

- ~~01-06 Task 3 — the SAFE-05 watch~~ **PASSED 2026-08-18T20:54:49Z**, 374 minutes elapsed. All
  four content-aware gates zero: sidecars added 0, removed 0, content-changed 0, whole-library stat
  delta 0. `zfs diff` returned exactly one line — a permission probe from the `aclmode`
  investigation whose `ctime` moved while sha256, size, mtime, owner and mode stayed identical
  across live, `@safe05-watch-t0` and `@pre-project`. Independently re-run and reproduced.

- ~~01-06 open question: restore the 66 changed `.nfo`?~~ **DECIDED: no.** They are Jellyfin's own
  current metadata rather than damage, both ZFS snapshots hold the originals indefinitely, no audio
  file was touched, and restoring would mean writing into a library this phase just finished
  sealing in order to undo a write.

- **Decision recorded: the SAFE-05 window was kept QUIET on purpose.** `RefreshLibrary` was
  deliberately not triggered. Since an explicit `FullRefresh` is now *known* to write, an "active"
  window would be provoking the failure rather than testing the claim. The quiet result proves what
  SAFE-05 can honestly support — nothing writes unprompted — and the explicit-refresh hole is
  recorded beside the pass, not behind it.

### Blockers/Concerns

- ~~**⚠ OPEN, OPERATOR ACTION: LXC 100's `/mnt/fast/stacks` checkout has DIVERGED from
  `origin/main`.**~~ **RESOLVED by the operator 2026-09-25, same day, and verified.** Workstation
  `HEAD`, `origin/main` and host `HEAD` all measured at **`f6d94c3`** with **0 ahead / 0 behind**
  and **both working trees clean** (host dirty count 0, so the transient ` M
  scripts/check-music-freeze.sh` cleared exactly as predicted). The at-risk work was **preserved,
  not lost** — it now reads `cc9b74f` *"feat(neocortex-memory): a private tailnet route via
  tsbridge (TODO-317)"*; the old `745611e` no longer resolves on either side, so it was rebased
  onto the pushed history rather than discarded.
  **The `260925-ae4` fix survived that rebase** — `0228f4f` is still in history, the pin reads
  `13` on both sides, and `scripts/check-music-freeze.sh` is byte-identical workstation↔host
  (`01b77f25c4745c6f…`), so the file that was `scp`'d out-of-band is now legitimately git-tracked
  and the two are no longer distinguishable. Deployed beets config re-asserted at
  `661c729738a12be6…` = repo. Acceptance re-run after the reconciliation: both blocks still green,
  `UNKNOWN` sweep 0, exit 1 with CONF-04 pending as its sole cause.
  **Kept rather than deleted, because the lesson outlives the incident:** a production checkout
  that is simultaneously ahead and behind cannot `pull --ff-only`, and the host was the only copy
  of real work for roughly a day. The estate's Renovate-deploy-drift problem has this sharper
  second form, and it is worth recognising early next time.
  *Original entry, for the record:* Measured 2026-09-25 during quick task
  `260925-ae4`, independently re-confirmed by the orchestrator: host `HEAD` is `745611e`
  *"feat(neocortex-memory): a private tailnet route via tsbridge (TODO-317)"* — authored
  2026-09-24T23:23Z, 25 insertions to `stacks/selfhosted/neocortex-memory/compose.yaml` — and
  **`git cat-file -t 745611e` FAILS on the workstation**. It is unpushed and the production
  container host is its only copy. Common ancestor `c406259`; host is **1 ahead / 1 behind**, so
  `git pull --ff-only` *cannot* succeed and the usual deploy path is blocked until someone
  reconciles it.
  **Why this was not fixed in passing:** resolving someone's unpushed feature commit on a
  production checkout is an operator decision, not a side effect of a two-line health-check fix.
  `260925-ae4` therefore deployed its one file by `scp` and issued **no** `pull`/`rebase`/`merge`/
  `reset`/`checkout -f`/`clean` on the host at any point; `745611e` was re-asserted as host `HEAD`
  after the copy.
  **Disclosed transient cost:** the host tree now reports one modified file
  (` M scripts/check-music-freeze.sh`). It self-heals the moment `0228f4f` reaches `origin/main`
  and the divergence is resolved — it is not drift to chase separately.
  **Until it is resolved, every future host deploy inherits the same blockage.** The estate's
  documented Renovate-deploy-drift problem now has a second, sharper form: not "merged changes
  never reach the host" but "the host cannot fast-forward at all."

- **v1 is now 39 requirements** (was 34; earlier the header wrongly said 33). Arithmetic checks
  both ways: by category SAFE 5 + WRIT 4 + CONS 4 + TAGR 6 + CONF 6 + INBX 3 + QUAL 4 + IMPT 3 +
  INGS 4 = 39; by phase 10 + 3 + 3 + 3 + 3 + 6 + 6 + 4 + 1 = 39. No requirement is unmapped and
  appears twice.

- **Ordering hazard: QUAL-01 must complete before Phase 5 stages anything.** Once content is moved
  into the inbox or imported, the before-state can no longer be recovered and Phase 7's diff has
  nothing to compare against. This is now an explicit dependency on Phase 5.

- ~~**Phase 2 route unresolved:** HAOS `/media` mount vs Music Assistant's own remote-share
  provider.~~ **RESOLVED 2026-09-01 (02-05, recorded 02-09): Route A, on measurement.** MA's own
  documentation is the side that was wrong. Route B's failure symptom is recorded in PROJECT.md so
  this is not re-litigated: it exposes no client-side `ro` option at all.

- **⚠ OPEN, carried past Phase 2: `music02_supervisor_issue_raised` (D-54b) is BLIND AT BOOT.** Its
  trigger config is correct — a synthetic event fired it in 542 ms — but `hassio` mirrors Supervisor
  issues into HA's repairs registry **13–18 s before the `automation` domain sets up**, consistently
  across four observed starts. A genuine `{action: create, domain: hassio}` event at `12:51:53.032Z`
  hit a trigger that attached at `12:52:21.951Z`. `hassio` is bootstrap-stage and `automation` is
  not, so it misses **every** time, not sometimes. **Recorded fix:** a state-based `command_line`
  sensor against `http://supervisor/resolution/info` using `$SUPERVISOR_TOKEN` at startup, instead of
  the create event. Rejected for now because it duplicates `music02_nfs_mount_failed_alert` (which
  now has its own boot trigger) for the only issue type in scope, and scoped wider it would page
  repeatedly for pre-existing issues nobody has chosen to act on. Also open: the mount-failure
  **notification** has never been delivered against a genuinely bad mount.

- **⚠ A live library defect, recorded and deliberately UNREPAIRED:**
  `/mnt/tank/media/Music/Def Leppard/Def Leppard (2015)/` derives an **empty** album artist and
  hard-errors `CD 01-06 … Sea of Love.flac`, because the album folder name equals the artist folder
  name. D-05 forbids tag repair, nobody holds `rw` on Music until Phase 6, and the export is `ro`.
  `zpool status -v tank` is clean, so it is **not** scrub damage. Handed to Phase 7.

- **Phase 3 drift risk:** the spike must carry pre-committed overturning thresholds and a
  ~20-folder normalisation pre-step, or the Discogs number is invalid and the phase becomes tool
  advocacy.

- **Abandonment is the dominant risk, 3-for-3 historically.** Leading indicator: more than ~10 days
  since the last import ran. All three prior deaths look identical at day 10. The revision attacks
  this directly on two fronts: TAGR-06 makes "will I actually still open this in week six" a
  recorded spike output, and QUAL-04 makes a clean undo something proven at pilot scale rather than
  hoped for at backlog scale.

- ~~SAFE-05 blind spot (found in the 01-01 baseline): the library holds 43 .png and 175 .txt files outside D-18's .nfo/.jpg/.lrc sidecar definition.~~ **RESOLVED 2026-08-18 by 01-06** — `check-music-freeze.sh` section 5 now inventories `.nfo/.jpg/.lrc/.png/.txt` (1,341 files) and prints the narrow D-18 subtotal (1,123) alongside it so the widening stays auditable against the 01-01 baseline. `.DS_Store` is counted separately.

- ~~**BLOCKER for 01-08**~~ **RESOLVED by scoping (`b02dfb7`): D-12 is out; 01-08 delivers the
  ownership half of WRIT-04 only, its Task 2 is a confirmation rather than a mode-change pilot, and
  `zfs set aclmode=passthrough` is explicitly rejected. The finding itself stands and still governs
  Phase 2.** — `chmod` is impossible anywhere on `tank`. `tank/media`, `tank/media/Music`
  and `tank/downloads` all carry `acltype=nfsv4` + `aclmode=restricted` + `aclinherit=passthrough`.
  Every child inherits a non-trivial NFSv4 ACL, and `restricted` makes `chmod` on a non-trivial ACL
  return `EPERM` — **as root, for every mode, including a no-op `chmod 0777` on a file already at
  0777.** Measured directly during 01-06. Consequences:

  - **D-12/D-13's mode normalisation (87 dirs → 0755, 2,586 files → 0644) cannot be done with
    `chmod`.** `chown` is unaffected and still works, which is why 01-08 keeps the ownership half.

  - It explains 01-01's "every entry is mode 0777 with no exceptions" — nothing can change them.
  - It is the same root cause as PROJECT.md's documented `rsync -a` failure
    (`mkstemp ... Operation not permitted`).

  - Phase 2 inherits it: knfsd does not export NFSv4 ACLs, so mode bits are all an NFS client sees,
    and mode bits currently cannot be set below 0777.

  - Routes considered: (a) `zfs set aclmode=passthrough|discard` on the datasets, (b) install
    `nfs4-acl-tools` (absent on LXC 100 and on the Proxmox host), or (c) accept 0777 and drop D-12.
    **(c) was chosen** — 01-06 deliberately changed nothing and escalated; the user reproduced the
    result independently and scoped D-12 out in `b02dfb7`, explicitly rejecting (a).

- 01-06: a `.DS_Store` owned `65534:65534` sits in the library root — a macOS client has write access
  over a share. It is an uncounted writer that no container mount audit and no Lidarr or Jellyfin
  setting can close, and no current requirement covers it. The harness now counts it every run.

- 01-06: the fenced `jellyfin-jellyfin.db` carries an `ApiKeys` table with 4 admin-scoped rows. It is
  mode `0600` rather than the fence's usual `0644`. If `library-db/` is copied off-box again under
  D-07, those credentials travel with it.

- ~~01-02 task 3 blocked at checkpoint: off-box copy to the Mac Mini (D-07)~~ **RESOLVED 2026-08-18** — operator copied library-db/ (15) and cover-scans/ (54) to `data@datas-mac-mini:~/archive/music-pre-project`, verified 54/54 sha256 + 15/15 integrity_check. Left in place as a hazard note: that host's non-interactive ssh PATH lacks `head`/`basename`/`sqlite3`, which produced two false "all 15 databases corrupt" results before absolute tool paths were used.
- 01-03: a duplicated audio_md5 makes the diff join last-wins, so in Phase 7 (BEFORE holds both backlog copies, AFTER holds one import) tag differences between duplicate sources are invisible. DUPE-01 should be resolved before QUAL-02 is treated as complete. The diff always lists such pairs in its informational section.
- 01-03: unsorted WAV content is NOT tag-free - all 40 sampled Now! 120 WAV records carry 6 format tags (title/artist/album/track/date/comment) plus an embedded cover-art stream. Plan 01-04 and Phase 7 must not assume an empty before-state for unsorted's 134 WAV files.
- 01-07: the manual beets container is NOT inert — its BEETSDIR config.yaml is a docker-compose file, so beets ran on defaults and left 47 items / 1.4 GB of WAV in /config/Music/__/. Phase 4 must account for it, plus a fifth latent entry point at beets/config/beets.sh.
- OPEN/UNOWNED: /mnt/tank/media/TV is 114,218 entries on orphan gid 545, the same gid 01-08 normalised Music away from. Out of scope, no requirement covers it, and it will hit the identical chown-from-LXC-100 EPERM. Leaving Music and TV divergent may be worse than leaving both wrong.
- ~~BLOCKING 2026-08-31 (02-01 Stage 0): atlantis is mid-incident on the documented amdgpu_hmm_invalidate_gfx NULL deref~~ **RESOLVED 2026-08-31 18:48:08** — rebooted via sysrq s+b; io pressure full avg300 96.22 -> 0.59, zero amdgpu_hmm_invalidate_gfx events this boot, taint 4225 (P+D+O) -> 4097 (P+O), both zpools ONLINE, 102 containers running, LXC 100 sshd normal. Root cause was NOT compaction: a Jellyfin VAAPI transcode started 07:56:56 and the kernel oopsed at 07:56:58. VAAPI disabled (encoding.xml HardwareAccelerationType=none, backup encoding.xml.bak.20260831T182741Z, scripts/disable-jellyfin-hwaccel.sh, commit b1ad9c1). **The correction that survives:** the July 2026 mitigation (THP=never + vm.compaction_proactiveness=0) was fully applied and did NOT prevent the recurrence, so the project-memory entry reading as "resolved" is wrong and should be corrected to name VAAPI as the trigger.
- BLOCKING for 02-06/02-07 (02-01 Task 3): the estate runs **Music Assistant (BETA) 2.11.0b0**, slug `d5369777_music_assistant_beta`, `auto_update: true`. The **stable add-on is not installed at all**. D-21 requires the phase be proven against stable — that cannot be satisfied as written. Operator must choose: install stable alongside, migrate off the BETA, or accept the BETA and stamp every criterion `2.11.0b0`. Auto-update on a beta channel means the stamped version can move before Phase 7. Does NOT block 02-03 (server-side only).
- BLOCKING for 02-06 (02-01 Task 3 measurement 5): D-30's provider enumeration is **unmeasured**. MA has an admin account (`onboard_done: true`; `auth/login` returns "Invalid username or password") but **no credential for it is recorded anywhere** — not `~/.claude/secrets/`, not `/mnt/fast/secrets/` on LXC 100. MA 2.11 gates `config/providers` behind scope `config.providers.read` and exposes only five unauthenticated commands. Three off-ramps measured closed: no `/addon_configs` entry for MA, no docker socket in the SSH add-on, `homeassistant` login provider `requires_redirect: true`. Obtain the credential and mint the D-39 token BEFORE adding any provider, so the baseline is taken against an untouched library.
- CORRECTION for 02-03 (02-01 Task 2): **never run a bare `terraform apply`.** The D-17 gate returned exit 2 with `Plan: 2 to add, 1 to change, 1 to destroy` and `proxmox_virtual_environment_container.selfhost must be replaced` — that is LXC 100, the Docker host with ~102 containers. Cause was a bpg/proxmox 0.95.0 artefact (33 mount_point blocks diffing `mount_options = [] -> null`, each forces-replacement) plus one real drift (`mpe_memory_mb` 20480 vs a host running 8192). Remediated in 1588f19 + 3051695; bare plan is now 1 add / 0 change / 0 destroy with zero forces-replacement. 02-03 must `terraform plan -out=`, read it, assert exactly `null_resource.nfs_music_export` and zero destroys, then apply the saved plan.
- CORRECTION for 02-04 (02-01 Task 3 measurement 6): **Jellyfin's t3_proxy address is 192.168.90.25, not the 192.168.90.31 pinned in 02-01 and 02-04** — the pin is wrong today, not merely fragile. Two further traps: the bare Docker DNS name `jellyfin` resolves to **Cloudflare's public edge** from the LXC 100 host because of `search deercrest.info` in /etc/resolv.conf (a health check would silently pass against the public site while the container was down), and `172.16.1.76` is unreachable from LXC 100 by macvlan host-to-container isolation despite working from the LAN. Use runtime resolution: `docker inspect jellyfin --format '{{(index .NetworkSettings.Networks "t3_proxy").IPAddress}}'` — verified 200, no IP literal.
- CORRECTION for 02-03/02-05 (02-01 Task 3 measurement 7): **`showmount` and `findmnt` are both ABSENT on the NUC.** `nfs-music-export.tf`'s `verify_commands` output suggests `showmount -e 172.16.1.158` "from the HA NUC" — that line will not run; use `exportfs -v` on atlantis. Criterion 1e's `findmnt` proof of NFSv4 negotiation needs `/proc/self/mountinfo` instead (verified readable from the SSH add-on; its fstype column is where `nfs4` will appear). `sha256sum` and `nc` ARE present, so D-11's read-through hash is sha256.
- LATENT, suppressed not fixed (02-01 Task 2): `bpg/proxmox 0.95.0` plans a replacement for any container carrying `mount_point` blocks. `ignore_changes = [mount_point]` now silences it on both LXC resources, which means **real bind-mount edits to lxc-selfhost.tf / lxc-mpe.tf will plan clean and do nothing**. Bind-mount changes are a deliberate manual act (`pct set` / edit `/etc/pve/lxc/<vmid>.conf`, then reconcile) until the provider is upgraded. Trade-off documented in both files.
- ~~02-05 MUST re-test M1 from the client side~~ / ~~02-05: M1 (the mountpoint export option) is STILL UNPROVEN~~ **RESOLVED 2026-09-01 by 02-08 — M1 IS PROVEN, and the earlier readings were an INSTRUMENT ERROR, not a defect.** A discriminating client-mount pair from the NUC, same command minutes apart: dataset **mounted** → `mount -t nfs4` exit 0, 14 entries; dataset **unmounted** (`zfs unmount`, no `-f`, behind a dead-man restore) → exit 255, `failed: No such file or directory`, 0 entries. The `mountpoint` export option genuinely makes `rpc.mountd` refuse. `exportfs -v` printed the **identical line in both states** — the export *table* is non-discriminating while the *served mount* is refused, which is exactly why three plans read this wrong. The control was run first, with the dataset mounted, so a later failure could only mean refusal rather than incapacity. **02-03's `threat_flag: control-not-enforced` on `infra/nfs-music-export.tf` is RETIRED**; the measurement now lives in the file itself (`a4174e6`). Do NOT remove `mountpoint`. M2 (`After=zfs-mount.service`) remains the boot-race guard; M1 is a proven second layer. *Why the earlier probes failed:* they ran as `sysadmin` without `sudo`. The HAOS SSH add-on has `sudo` `NOPASSWD: ALL`, `CapBnd` with `CAP_SYS_ADMIN`, and Protection mode already off — it was never privilege-limited.
- ~~02-05: check-music-consumers.sh is STILL not on LXC 100 and a git pull there CANNOT land it~~ **RESOLVED 2026-09-01** — the 41 local commits were pushed to `origin/main` with explicit operator approval (`aa2b502..90cdddc`, clean `git pull --rebase`). `git pull --ff-only` in `/mnt/fast/stacks` now lands the script; both of 02-08's audit gates ran from a pulled copy at HEAD `90cdddc`, exit 0. The `scp` workaround is retired and **02-09's `quick-health-check.sh` fold-in has a real pull path.**
- **02-08 — an HA trigger that has never fired is not a detector.** D-54a was built, its delivery path validated (notify service registered, templates render), and it was still **structurally unable to fire** on the one scenario it existed for. Two generalisable rules came out of it: (a) `numeric_state` fires on a **crossing** and is armed only by a prior non-matching change, so it cannot catch a fault that was already true when HA started — and a `state: to: <value>` trigger cannot either, because the entity lands on its boot value **6–15 s before the automation attaches** (measured on four HA starts) and an unchanged poll fires no event. Only `homeassistant` `event: start`, which fires **at attach time**, can catch a pre-existing fault. (b) Put the debounce in the **action** (`delay` + re-read) rather than `for:` on the trigger: `for:` leaves no trace that the trigger ever armed, which is how this hid for a plan and a half.
- **OPEN (02-08): D-54b is blind at boot — an ordering, not a race.** `automation.music_supervisor_raised_a_system_issue`'s trigger is correct (a synthetic `repairs_issue_registry_updated` event fired it in 542 ms). It still misses every boot-time Supervisor issue, because HA's `hassio` integration mirrors those issues into the repairs registry **~13–18 s before the `automation` domain sets up** — identical across four observed HA starts, so it misses every time rather than sometimes. Evidence: a genuine `{action: create, domain: hassio}` event at `12:51:53.032Z` vs the trigger attaching at `12:52:21.951Z`. **Not fixed deliberately:** closing it needs a `command_line` sensor against `http://supervisor/resolution/info` with `$SUPERVISOR_TOKEN`, which for the only issue type in scope would duplicate `music02_nfs_mount_failed_alert` (now boot-covered) and, scoped wider, would page repeatedly for pre-existing issues nobody has chosen to act on.
- 02-05: ACCEPTED CONSEQUENCE (D-27/T-02-21) — Route A's usage:media also surfaces the music library in Home Assistant's own Media browser to anyone with HA access. Measured: HA Core reads the same 13 artist directories. Accepted: usage:media is what makes Route A work, the mount is ro on both client and export, and the audience already has HA access. Belongs in PROJECT.md per D-47.
- **BLOCKING FOR PHASE 7 (02-07): `missing_album_artist_action: folder_name` is CONDITIONAL, and a configured value is NOT a firing value.** Measured with a 4-cell variant matrix on a throwaway export: the fallback uses the artist folder name ONLY when the file's `album` TAG agrees with its album FOLDER name (year suffix ignored). On a mismatch MA silently uses `Various Artists` — while `config/providers/get` reads back `folder_name` throughout, so the API cannot tell you it did not fire. The track artist tag is irrelevant (a decoy artist still produced the folder name; an agreeing artist did not rescue a mismatched album tag). MA's own sync log (`tasks/log`) is the ONLY instrument that names which branch fired — `using foldername X as fallback` vs `using Various Artists as fallback`. Album identity is `albumartist + os.sep + album`, so a wrong album artist is a DURABLE entry and the only cheap repair is removing and re-adding the provider, which drops every favourite and play count attached to its items.
- **OPEN, recorded not repaired (02-07): `/mnt/tank/media/Music/Def Leppard/Def Leppard (2015)/` derives an EMPTY album artist and hard-errors one file** (`CD 01-06 Def Leppard - Sea of Love.flac`), because the album folder name equals the artist folder name — MA's derivation appears to lock onto the top-level `Def Leppard` directory as the album folder, whose parent is the provider root. Two files hit it; one errored. **No remedy was attempted and none is available here:** D-05 makes tag repair the wrong remedy on principle and the `ro` export makes it unavailable in fact. `zpool status -v tank` is clean, so this is NOT 2026-07 scrub damage. Phase 7 meets this at scale.
- **CORRECTION for anything querying MA albums (02-07): `search` on `music/albums/library_items` is NOT a substring match.** Searching an album's OWN EXACT NAME returned `[]` while a one-word prefix returned that same album, from the same provider, in the same second (`Mastermix Essential Hits - Pop 4 - 2005-2009` vs `Mastermix`). Short names happen to work, which is what makes it dangerous. Filter on `provider` ONLY and do the exact comparison locally — otherwise the gate reports `no exact match … candidates were: <none>`, indistinguishable from the album being genuinely absent. Fixed in `check-music-consumers.sh` (`ed1d367`).
- **CORRECTION for any future Terraform teardown (02-07): destroying a `null_resource` removes NOTHING from the host.** `music_temp_export_enabled = false` was not a teardown — the drop-in file stayed on disk and the export stayed live while `terraform plan` reported clean. Fixed by an always-present reconciler resource (`d7430ee`). **A destroy-time provisioner is NOT an option here:** `terraform validate` refuses one whose connection block reads variables, and the only workaround carries the Proxmox root password in `triggers` — plaintext state plus every plan diff, in a public repo. `self.triggers.*` is also unsafe at destroy time: it reads from STATE, so a key added after creation reads null and `grep -q ""` matches every line.
- ~~⏱ TIME-SENSITIVE (02.1-01, 2026-09-02): / on LXC 100 has 185 MiB of margin over the D-17 floor (20.18 GiB avail vs 20.00 GiB), and Jellyfin's transcode cache has already refilled to 12.55 GiB / 1,324 files at roughly 6 GiB/day.~~ **MATERIALLY REDUCED 2026-09-02T22:19:52Z by 02.1-05's cutover, but NOT cleared.** New transcode writes now land on `fast/transcode` under a 50 G quota, so **`oldvol_transcodes_bytes` is a FROZEN stock rather than a growing one** — the ~6 GiB/day clock has stopped and the "budget measured in hours" framing no longer applies. Margin is now ~216 MiB, the widest all phase, because the recreate was `/`-positive. **Two reasons it is not cleared:** (1) the 12.55 GiB is still *on* `/` and is only released by **02.1-06's `docker volume rm`**, which should not be left sitting; (2) the margin still erodes a few MiB per half-hour from ordinary churn across the other 78+ containers. **If `oldvol_transcodes_bytes` ever moves again, that is not the old problem continuing — it is `jellyfin.yaml` having been reverted, and the standing check's section 2 is the alarm.** ~~The operator decision point in 02.1-01's rollback table (moving 02.1-09's reap earlier) still stands if a D-32 sample reads below 21474836480.~~ **CLEARED 2026-09-03. This item is closed and no part of it is time-sensitive any more.** 02.1-06 deleted the anonymous volume and released the 12.55 GiB stock; 02.1-09's reap then freed a further 1.45 GiB. **`/` margin over the D-17 floor is 14.49 GiB — 185 MiB at phase start, a factor of about eighty.** The operator decision point is moot in both directions: the reap has now RUN, at wave 8 where D-31 put it, and it was never overtaken. **The "budget measured in hours" framing is retired — do not restate it.** The D-32 watch continues as a passive instrument, but it is watching a protected filesystem now, not a countdown.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Duplicates | DUPE-01, DUPE-02 | v2 — before any `unsorted` import | 2026-08-17 |
| Bucket B | NOWB-01, NOWB-02 | v2 — manual confirmation budget | 2026-08-17 |
| Acquisition | LIDR-01 — replace Lidarr as grabber | v2 — wanted; WRIT-03 removes the harm now | 2026-08-17 |
| Bucket C | DJCC-01 – DJCC-05 | v2 — lowest-confidence research area | 2026-08-17 |

## Quick Tasks Completed

| ID | Task | Date | Status |
|----|------|------|--------|
| 260826-0u0 | Document Tailscale configuration and low-level design across all systems | 2026-08-26 | complete ✓ |
| 260901-u96 | Read-write NFS export on atlantis for Home Assistant backups (external RES-04) | 2026-09-01 | complete ✓ |
| 260902-fxf | Refresh keeper-sh docs against live state, add keeper-mcp service, relocate misfiled Innofactor docs | 2026-09-02 | complete ✓ |
| 260902-gln | Document who gets reminders for Keeper-created events; plan the Work-calendar split | 2026-09-02 | complete ✓ |
| 260902-hya | Complete the keeper-sh .env.sample and correct the compose description comment | 2026-09-02 | complete ✓ |
| 260906-e6l | Bound atlantis memory oversubscription — cap mpe LXC at 3 GB, add mem_limit to 12 containers | 2026-09-06 | complete ✓ |
| 260906-eza | Reclaim ~2.8 GB: retire Mattermost, stop postiz/open-archiver/homarr, add TREK + TeslaMate | 2026-09-06 | complete ✓ |
| 260906-ilx | Dispatcharr server DVR: 250 GB recording dataset and verified Jellyfin playback (`85f6d26`, `e5076cd`) | 2026-09-06 | complete ✓ |
| 260914-a2y | Assert the two `extended.conf` switches that disarm `audio.bash`'s `rm -rf` branches — fifth fatal block, four controls driven; closes CR-01/WR-01 (`c0b04c3`, `220dcf4`) | 2026-09-14 | complete ✓ |
| 260915-k9p | Correct the Traefik dashboard probe: `:8080` was never published to the host, so the probe asserted a promise the config never made. Now asserts the real chain (websecure + `traefik-rtr` + TLS + `chain-authelia@file`), with an unauthenticated 200 as a new violation branch. 9 branches driven; the plan's own control-B driver was measured false and replaced (`9db2e39`) | 2026-09-15 | complete ✓ |
| 260918-c12 | Scheduled image-drift detection (repo pin vs running image) with Grafana->Telegram alerting; alert-only v1. First sweep: 14 of 97 containers drifted. G0-G3 deployed; G4 Telegram creds open (`91ec081`, `d68da3a`) | 2026-09-18 | complete ✓ (G4 open) |
| 260924-x6w | SearXNG result quality + Open WebUI web search and RAG. Five independent faults, not the one suspected: engine blocking was real, but the JSON API was returning **403** so chat web search returned *nothing*, and there was **no embedding model on the box at all** (`RAG_ENBEDDING_MODEL` typo). Root cause was the 3-month image pin predating the curl_cffi TLS-impersonation migration — after upgrading, **brave/google/bing measured 5/5 and were enabled rather than replaced**; only duckduckgo stayed blocked. The frozen 70 KB `settings.yml` (proven stale by its pre-Feb-2026 `suspended_times`) became a `use_default_settings` delta, now versioned in-repo. Verification found and closed a **POST bypass in this task's own Traefik JSON block**. 0 → 41 results via the Open WebUI path (`1569121`, `9d1518e`, `08e7ce3`, `3e6d81a`) | 2026-09-25 | complete ✓ (V7 chat-UI search unverified; needs a human) |
| 260925-ae4 | Close the two reds `/gsd-verify-work 6` found in `quick-health-check.sh` — **neither introduced by Phase 6**. (1) The interpolated-host-path pin was one behind reality: `2f19870` (2026-09-18) added a 13th line in `node-exporter.yaml` without moving `DECLARED_INTERP_EXPECTED` in the same commit, so convention 5's trap had been firing for a week and the estate's single entry point had been red for an unrelated reason. Pin moved 12 → 13 and the line **declared in band** — with the mechanism's own limit written down: *the pin gates on inventory SIZE, not CONTENT*, so repointing `${APPDATA_DIR}` under the library or dropping the `:ro` keeps the count at thirteen and the section green while the declaration silently becomes false. (2) The deployed beets `config.yaml` was stale against the repo — **comments-only**, `max_filename_length: 0` byte-identical, so no config-correctness impact; the cost was that plan 06-07's retraction never reached the running copy and a grep of it returned the superseded wrong explanation. Refreshed host-side through the existing inode (owner/mode preserved by mechanism); no container restart. ⚠ A repo-only edit would NOT have closed (1) — `quick-health-check.sh:2426` runs the freeze script **over ssh on LXC 100**, so the script was `scp`'d. **The host checkout has DIVERGED and that was deliberately left alone** — see Blockers/Concerns (`0228f4f`) | 2026-09-25 | complete ✓ (overall exit stays 1; CONF-04 pending is its sole cause, by design) |

## Session Continuity

Last session: 2026-09-25T13:16:59.848Z
Stopped at: Phase 7 context gathered — `/gsd-discuss-phase 7` complete. `07-CONTEXT.md` captures
**D-01 … D-31** across five areas plus closure. Three findings surfaced that were recorded nowhere:
(1) `tank/downloads/mybook-music-archive` (**1.30 T / 165,467 audio / 450 DJ releases**) has **no
QUAL-01 before-state** — `snapshot-music-tags.sh` pins four roots and it is none of them — so
criterion 4 is uncomputable against it; it is scoped OUT and given its own **inserted phase between
8 and 9**, with DUPE-01/02 folded in. (2) `diff-music-tags.sh:156`'s `reduce` join is **silently
last-wins** on duplicate `audio_md5`, so whether QUAL-02 fires depends on file-walk order — fixed by
a fail-closed **AMBIGUOUS/exit 3**, symmetric on both sides, driven on fixtures *and* the real
snapshot. (3) `ROADMAP.md`'s *"must precede any import of `unsorted`"* conflicts with the agreed
draw, and is **amended in band** to *bulk* import with the pilot named as the exception.
Sample: 6 reused bucket-A rows + the 2 DJ folders + 4 fresh (one slot reserved for E6's ≥4-artist
measurement); `Michael Jackson – The Essential` is the gated first album. ⛔ **Phase 6 is NOT
complete** — `06-VERIFICATION.md` stands at `gaps_found` 5/6, CONF-04 unticked, ROADMAP status
`In Progress`; `/gsd-verify 06` is still its next step. Next for Phase 7: `/gsd-plan-phase 7`.
⚠ `state.record-session` set `completed_phases: 6` / `total_plans: 126` / `percent: 60` unasked;
reverted to 5 / 124 / 50 against the ROADMAP's five `Complete` rows — 6 would have been a false
close of Phase 6.

Previously: 06-46-PLAN.md (round 6, wave 1) — WR-01 and the `check-music-freeze.sh` half
of WR-03 closed in band as `R6-01` / `R6-03`. **`shellcheck -S warning` is clean on all six reviewed
scripts, where it was clean on five**, and both pinned-count fail arms now emit the literal edit they
require plus the prohibition on silencing them with the env override. Four added lines; no predicate,
no constant and no `fail ` count moved (24 at both ends, asserted against base `75c7989`); zero estate
contact. The one zero-expecting count published was driven against a control returning 1 first.
Next: **06-47** (round 6, wave 2). ⛔ Do NOT run round 6 with `--auto`/`--chain` — `06-51` and `06-52`
are `autonomous: false` live-estate plans.
Previously: 06-45-PLAN.md (round 5, wave 23) — **GAP-CLOSURE ROUND 5 IS COMPLETE at
45/45, and the phase is NOT declared complete.** Five documents now state one truth value for
CONF-04: `REQUIREMENTS.md`'s checkbox and traceability row, `ROADMAP.md`'s Phase 6 criterion 4 and
status row and its Phase 7 entry criterion E6, `06-VERIFICATION.md`'s gap record, and
`stacks/selfhosted/arrs/beets.md`. **The tick gate held and CONF-04 is still unticked**
(`BRANCH: B` against a required `A`; `JF_AT_TARGET: 0`/`JF_PENDING: 3` against a required `3`/`0`);
`requirements mark-complete` was not run. E6 carries two separately-dispositioned measurements and
its second — the ≥4-artist MA discrimination — stays with Phase 7. Residue carried as
`DEF-06-45-01`..`05` (register 36 → 41), including the still-held snapshot
`tank/media/Music@pre-06-41-conf04-reprobe` and a non-detecting `grep -cF` recipe published in
06-43 SECTION O. All edits to dated records are purely additive, measured rather than asserted.
**NEXT: `/gsd-verify 06`.** It has not been run since 2026-09-23, and seven files have moved since
(these five documents plus the two instrument scripts 06-44 corrected). Re-scoring
`06-VERIFICATION.md` from 5/6 is the verifier's call and no plan in this round claimed it.
Also outstanding and unchanged: the operator `git push` + host `git pull --ff-only` in
`/mnt/fast/stacks`, without which a live `quick-health-check.sh` measures pre-06-44 prose
(`DEF-06-45-05`). Both snapshots stay held; no `zfs rollback` was executed.
Resume file: .planning/phases/07-pilot-12-albums-end-to-end/07-CONTEXT.md

_(The two lines below are the older Phase 6 entry-point note, kept because the wave-20 pointer above
supersedes only the resume position, not the phase context.)_
Previous resume file: .planning/phases/06-tagger-configuration-and-dry-run/06-CONTEXT.md

**NEXT: 02.1-10, the last plan of the phase (wave 9).** It is unblocked — it depends on 02.1-06 and
02.1-09 and both are now complete. Two things it should carry in:

1. **VALIDATION rows 11, 15, 16 and 02.1-06's task-3 `<verify>` FAIL ON CORRECT OUTCOMES.** Waves 5–8
   left them failing deliberately. 02.1-10 verifies against the text; do not "fix" them.

2. **This phase's reap is DONE and is not time-sensitive in any form.** `/` has 14.49 GiB of margin
   over the D-17 floor. Any prose still framing image reclaim as urgent is stale.

**02-09 IS COMPLETE AND THE PHASE IS CLOSED.**

Machine gate green three ways: `check-music-consumers.sh` **0** (FAILURES 0, `--baseline` 0,
`--bogus` 2), `check-music-freeze.sh` **0**, `quick-health-check.sh` **0** with both blocks green.
`terraform plan -detailed-exitcode` **0**. All five ROADMAP criteria have an explicit verdict with
named evidence in `02-09-SUMMARY.md`, including criterion 1's five sub-parts individually.

**D-55 APPROVED, verbatim:** *"i have spot checked a couple and played them to make sure the song
matchs - all good, no various artists, no singles . mastermix is not there"*

**The lesson worth carrying:** the operator **played tracks**. Every automated check in this phase
verifies that MA's **database** says the right thing — album name, album artist, provider
attribution — and none of them can verify that the **bytes behind the entry are the right song**.
The stale state this phase spent two plans characterising is exactly *"entries exist, playback of
any of them fails"* — 70 albums, all unplayable, every database assertion still passing. **Playback
is the only test that closes that, and it is not automatable from here.** D-55 earned its place.

**⚠ Do NOT push without asking.** **5 commits ahead of `origin/main`** — `a4174e6` + `6ff2332`
(02-08) and `9f915a9` + `e37039b` + the 02-09 close. `/mnt/fast/stacks` on LXC 100 is still at
`90cdddc`, so it does not yet carry the folded-in `quick-health-check.sh` — which does not matter,
because that script runs from the workstation.

---

**02-08 IS COMPLETE. All three tasks ran, plus a fix for the defect the live test found.** The
record is `02-08-SUMMARY.md`; `02-08-PARTIAL.md` has been folded into it and removed, so there is
one record, not two. **CONS-03 is ticked and earned** — the reboots were the only thing 02-07 was
missing, and they happened.

**The one-paragraph version of what the phase learned here:** a green result on the positive reboot
was never going to mean anything, and it did not — atlantis was healthy so the race was never
exercised. The negative control is what paid: it reproduced the failure exactly as predicted, proved
MA's deletion guard preserves rather than purges, settled unattended recovery at **432 s**, and
**found a detector that was structurally unable to detect the thing it was written for**. That last
one is the output worth having.

**Read `02-08-SUMMARY.md` before 02-09.** Four things in it change what a later plan may assume:

1. **`mount | grep emergency/music` can never match on this Supervisor version.** There is no
   `/emergency/` bind. Supervisor makes the media directory read-only **in place** and leaves it
   empty. The working proof line is `/media/music` present, `dr--r--r--`, root-owned, 0 entries.

2. **`exportfs -v` cannot tell you an export will serve.** It prints the line whether or not
   `rpc.mountd` will honour it. This is how M1 was mis-recorded as unproven for three plans.

3. **The default `ha supervisor logs` depth does not reach back to boot.** A default-depth grep
   returns nothing and looks exactly like "it did not happen". Use `-n 2000` or deeper.

4. **The HAOS SSH add-on is not privilege-limited.** `sudo` is `NOPASSWD: ALL`, `CapBnd` carries
   `CAP_SYS_ADMIN`, Protection mode is already off. Two earlier probes were recorded as blocked by a
   privilege limit; they were blocked by a missing `sudo`.

**A new long-lived MA token exists**, named `HA M4 music sync (phase 02-08)`, 1 year, held ONLY as
`ma_ha_sync_authorization` in `/config/secrets.yaml` on the NUC — never in this repo (asserted six
ways). **Correction to 02-04's record: MA 2.11 DOES have a token API** (`auth/token/create` /
`auth/tokens` / `auth/token/revoke`); it has no token *UI*. That also means the audit script's
log-in-per-run pattern, which has now accumulated 99 `WebSocket Session` rows against a 100-row
response cap, could become a named revocable token — **logged for 02-09**.

**Also logged for 02-09:** carry the corrected HA YAML into `beets.md` (D-47) — the SUMMARY holds it
verbatim; the `Xonora` token (created 2026-02-21, expiring 2036, unused since March, unattributed)
belongs in the project-close rotation alongside the Discogs token; and D-54b's boot blind spot is
open with its specific fix recorded.

**02-07 is complete. CONS-02 is ticked and criterion 3 is proven** (CONS-03 was correctly left for
02-08's reboots). Three albums,
exact on album name AND `artists[0].name`, provider-attributed, inside a 177-second deliberate
`music/sync`. `check-music-consumers.sh` exits **0** in steady state and `check-music-freeze.sh`
exits 0 with FAILURES 0, byte-identical to 01-09's closure. Nothing was written into
`/mnt/tank/media/Music` at any point: 2,674 entries, 33.9 G, zero files newer than the plan start,
asserted three times.

**The control FAILED before it passed, and that is the phase's most valuable output** — see the
`folder_name` blocker under Blockers/Concerns before planning Phase 7. Two instrument defects were
also found and fixed: MA's `search` argument produced a false FAILURE, and the temporary export's
teardown produced a silent PASS.

**The PARTIAL naming convention is still the rule for halted plans.** `phase-plan-index` treats any
`*-SUMMARY.md` as plan-complete on file existence alone, regardless of its `status:` frontmatter — so
a halted plan's record must be `-PARTIAL.md` and only becomes `-SUMMARY.md` when the plan genuinely
finishes.

Next in phase 2: **02-09**, the last plan. Read 02-08's SUMMARY and 02-07's blockers first — the
`folder_name` precondition is the one that changes what Phase 7 has to check, the
`Def Leppard (2015)` empty-album-artist case is a live example of it, the audit script now lands on
LXC 100 via `git pull` (the `scp` workaround is retired), and MA is still BETA `2.11.0b0` with
`auto_update: true`, so stamp the version on every assertion.

**D-45's rollback assertions have now been executed once against real state** (02-07 Task 3), so
02-09's runbook documents a tested procedure — including the part that did not work as authored.

**Two hazards carried from 02-05 for anyone touching the export.** `ssh -n` points stdin at
`/dev/null`, so `ssh -n host 'bash -s' <<EOF` silently discards the entire script and exits 0 — use
`-n` for inline `ssh host 'cmd'` only. And `/proc/fs/nfsd/exports` shows four `no_root_squash` hits
once a client mounts; they are auto-generated `v4root` traversal entries, not a T-02-06 regression.
Assert `no_root_squash` on `exportfs -v` — but **never assert export *health* on `exportfs -v`**:
02-08 measured it printing an intact line for an export that refused every client. The only
export-health check that means anything is a real client mount attempt.

Plans 01-02, 01-04, 01-06, 01-07, 01-08 and 01-09 are `autonomous: false` — they carry blocking
human checkpoints (the fence run, the ~140 GB capture, the Lidarr/Jellyfin freeze and its one-hour
watch, the beets config vendoring, the recursive chown, and the phase-closure verdict).

Next: `/gsd-plan-phase 2 --research-phase`
