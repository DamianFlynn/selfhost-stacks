---
phase: 06-tagger-configuration-and-dry-run
plan: 44
subsystem: infra
tags: [conf-04, d-22, jellyfin, health-checks, prose-correction, recorded-negative, override-carry, def-06-39-06, gc-04]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-43's one machine-readable line — `BRANCH: B`, the mtime hypothesis recorded disproven — read rather than re-derived"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-43 SECTION P's operator decision, `negative-carry-e6`, which authorises the CARRY and explicitly not a close"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-42's corroboration on UNTOUCHED code — `INSTRUMENT RUN: MEASURED`, `JF_AT_TARGET: 0`, `JF_PENDING: 3`, `EXIT CODE: 3` — taken in wave 20, before this plan existed"
provides:
  - "`scripts/check-music-consumers.sh` — the standing CONF-04 drift detector, with five in-band sites corrected to the round-5 truth and its logic provably untouched"
  - "`scripts/quick-health-check.sh` — the health entry point's exit-3 arm, naming BOTH E6 owners rather than one, still setting `EXIT_CODE=1`"
  - "A mechanical proof that no logic moved: 0 changed lines that are neither a comment nor a printed message, and 0 added `if`/`elif`/`case`/`EXIT_CODE=` lines, across both files"
  - "The baseline column's retention argued in band as the post-discharge REGRESSION detector, so it is not tidied away once the target is met"
  - "A driven cross-file contract: the 8-line exit-3 banner pushed through `quick-health-check.sh`'s exact `sed ... | sed -n '1,8p'` window, end anchor and both halves intact"
affects: [06-45, phase-07-entry-criterion-E6]

tech-stack:
  added: []
  patterns:
    - "When a round's result is a NEGATIVE, correct the instrument's PROSE and prove mechanically that its LOGIC did not move — a changed-line audit requiring every diff line to be a comment or a printed message turns 'I only edited comments' from a claim into a test"
    - "Take the instrument's own corroborating run BEFORE the operator's binding decision, not after: the run that certifies a verdict must happen on code nobody has yet had a reason to edit"
    - "Write an override as a CARRY of an open requirement and say so in the same sentence, every time it is mentioned — the inference a downstream reader makes wrongly is 'override' -> 'closed'"
    - "Correct both sides of a cross-file contract in the SAME round and then DRIVE it, rather than asserting the two texts agree (the `GC-04` stale-citation class)"
    - "Keep the counted token in BRACKETED form in every downstream document too, and measure the count AFTER the edit lands — the only method that has caught this class, now three rounds running"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/06-44-SUMMARY.md"
  modified:
    - "scripts/check-music-consumers.sh"
    - "scripts/quick-health-check.sh"
    - ".planning/STATE.md"
    - ".planning/ROADMAP.md"

key-decisions:
  - "THE PROSE WAS CORRECTED TO `BRANCH: B` AS READ, NOT AS RE-DERIVED. 06-43 hands down one line and this plan consumed it. The measurement it rests on was taken by the deployed, unmodified instrument in 06-42 task 3 — wave 20, before the branch was computed and before the operator decided anything — so nothing here is a verdict written by the agent that also wrote the conclusion."
  - "THE JELLYFIN HALF IS WRITTEN AS CARRIED, NEVER AS CLOSED, at every one of the five corrected sites. `negative-carry-e6` authorises an explicit, auditable carry of an OPEN requirement to Phase 7 entry criterion E6. CONF-04 stays unticked, `requirements mark-complete` was NOT run, and each site says in its own words that an override is not a close — 06-43 flagged this as the single easiest inference for a downstream reader to make wrongly."
  - "THE EXIT CODE WAS DELIBERATELY NOT TUNED. `check-music-consumers.sh` still exits 3 because `MA_ARTIST_PENDING` is 1 — a reported measured discrepancy owned by E6's SECOND measurement — and 06-42's own artifact records that it would have exited 3 on a fully successful re-probe too. `EXIT_CODE=1` stays on `quick-health-check.sh`'s exit-3 arm. Not one line was changed to make any process end on 0, and the banner now states that in band."
  - "THE BASELINE COLUMN IS ARGUED IN BAND AS THE REGRESSION DETECTOR AND EXPLICITLY RETAINED. After E6 discharges the Jellyfin half, a row back at its 2026-09-20 baseline means something reverted — most likely `PreferNonstandardArtistsTag`, which section 4a asserts independently — rather than that the estate is waiting. Deleting either numeric column would trade a detector for a tidier table."
  - "THE TWO HALVES ARE NOW ATTRIBUTED TO TWO DIFFERENT E6 MEASUREMENTS, which makes the never-summed rule MORE load-bearing rather than less. The Jellyfin count waits on a Phase 7 write or import; the MA count waits on the >=4-artist discrimination that separates 'MA caps the list at 3' from 'Twista specifically failed to map'. Round 5 produced no evidence bearing on the second and did not close it."
  - "THE CROSS-FILE CONTRACT WAS DRIVEN RATHER THAN ASSERTED. The rewritten banner is 8 lines against the consuming arm's `sed -n '1,8p'` cap, so it was rendered locally with stub counters and pushed through that exact pipeline: 8 of 8 lines survive, the `Discharges on ROADMAP` end anchor is still on the last one, and both halves are named inside the window a reader actually sees."
  - "NO ESTATE CONTACT, AND THE LIVE RUN WAS REFUSED ON PURPOSE. A live `quick-health-check.sh` would have exercised this plan's local arm against the OLD prose still deployed on LXC 100 — a partial and misleading test — while the plan's objective forbids estate contact. The local harness drives exactly what changed and is strictly more informative."

patterns-established:
  - "A prose-only correction plan whose acceptance criteria are a MECHANICAL DIFF AUDIT rather than a review: every changed line must be a comment or a printed message, and the diff must add no control flow or exit-code assignment"
  - "Ordering the corroborating instrument run into the MEASUREMENT plan (wave 20) rather than the prose-correction plan (wave 22), so the round's one independent cross-check lands before the operator's binding decision instead of after it"

requirements-completed: []

duration: 20min
completed: 2026-09-24
---

# Phase 06 Plan 44: The Instrument's Prose Summary

**Five sentences in the estate's standing CONF-04 drift detector and its health entry point named Phase 7 as the sole owner of a discharge that was driven on 2026-09-24 and measured not to happen; all five now state the round-5 truth and write the Jellyfin half as CARRIED to E6 under the recorded override rather than closed — with a mechanical diff audit proving that not one line of logic, threshold, counter or exit code moved to get there.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 2 of 2, both `auto`, both committed individually
- **Files modified:** 2 scripts (+ the two execution-record files)
- **Estate contact:** none. No HTTP, no ssh, no write outside this repository.
- **Artifacts written:** none — this plan's output is the two corrected scripts.

## Accomplishments

- **Corrected all five named sites**, each citing plan `06-41` and the artifacts by name: the `⚠ THE \`target\` COLUMN IS NOT TRUE TODAY` paragraph above `ARTIST_PROOF_ROWS`; the header's `EXIT 3` point (c); section 4b's PENDING-branch `echo` block; the `artist rows PENDING (JF)` summary line; and the exit-3 banner.
- **Recorded the negative where the hypothesis was stated.** The paragraph that named "a file whose mtime has not changed" as the blocking condition now records that this exact lever was driven inside a ZFS snapshot fence and is measured false for this estate at Jellyfin 10.11.11 — **ZERO of three rows moved**, not "two of three"; the 1,244-row census delta was empty; `PreferNonstandardArtistsTag` re-read `true` afterwards, so the refresh ran, reached the items, and the prober did not re-read `ARTISTS`.
- **Kept the fence intact while recording a negative.** Every new sentence states that the correct response to a disproven mechanism is the recorded negative — not a second refresh, not a wider refresh mode, and not the aggressive per-item one, which stays forbidden, was not issued, and was unreachable from every branch.
- **Named which half each count belongs to and who owns it**, in the banner, in the summary line and in `quick-health-check.sh`'s arm — and restated the never-summed rule rather than weakening it.
- **Argued the baseline column's retention in band** so a later tidy-up does not delete the regression detector.
- **Drove the cross-file contract** instead of asserting the two files agree.

## Task Commits

1. **Task 1: correct `check-music-consumers.sh`'s in-band prose** — `646583a` (docs)
2. **Task 2: correct `quick-health-check.sh`'s exit-3 arm** — `8cac538` (docs)

## Files Created/Modified

- `scripts/check-music-consumers.sh` — +79 / −12. Five prose sites corrected. All three `ARTIST_PROOF_ROWS` definitions verbatim with both numeric columns; the four `JELLYFIN_D34_OPTIONS` rows unchanged; both `*_ARTIST_PENDING` counter names unchanged; the `📊 6. Summary` heading present once and un-renumbered.
- `scripts/quick-health-check.sh` — the `-eq 3` arm only. The load-bearing `EXIT_CODE=1` paragraph gained a two-owner breakdown; the printed block gained five lines naming both halves.
- `.planning/STATE.md`, `.planning/ROADMAP.md` — execution record only. No CONF-04 verdict, no checkbox moved.

## The Mechanical Proof That No Logic Moved

This is the plan's substance, so the numbers are recorded rather than summarised.

| Assertion | `check-music-consumers.sh` | `quick-health-check.sh` |
|---|---|---|
| `bash -n` | exit 0 | exit 0 |
| `shellcheck -S warning` vs pre-edit | **byte-identical** (0 findings both sides) | **byte-identical** (0 findings both sides) |
| Changed lines that are neither comment nor printed message | **0** | **0** |
| Added `if` / `elif` / `case` / `EXIT_CODE=` lines | n/a | **0** |
| `ARTIST_PROOF_ROWS` definitions present verbatim | 3 of 3, both numeric columns | n/a |
| Exit ladder order (`--baseline` < `FAILURES` < pending < green banner) | **1699 < 1704 < 1732 < 1746** | n/a |
| `exit 0` / `exit 1` / `exit 2` / `exit 3` present | 2 / 1 / 1 / 1 | n/a |
| `JELLYFIN_D34_OPTIONS` rows | 4, unchanged | n/a |
| `📊 6. Summary` anchor | present, un-renumbered | 5 occurrences of the guard pattern |
| `CONSUMERS_OVERRIDDEN" -eq 1` guard count | n/a | **7**, its measured value, unmoved |
| `EXIT_CODE=1` inside the `-eq 3` arm | n/a | present (>= 2 required) |

Both task `<automated>` verify blocks were re-run at the final tree state: `TASK 1 VERIFY: OK`, `TASK 2 VERIFY: OK`.

## The Cross-File Contract, Driven

`quick-health-check.sh`'s exit-3 arm extracts the audit's banner with
`sed -n '/CONF-04 IS NOT CLOSED/,/Discharges on ROADMAP/p' | sed -n '1,8p'`. The rewritten banner is
exactly **8** lines, so it was rendered locally with stub counters (`JF=3`, `MA=1`, `FAILURES=0`) and
pushed through that exact pipeline. Result: **8 of 8 lines survive the cap**, the
`Discharges on ROADMAP` end anchor is still on the last one, and the extracted window contains the
never-summed rule, `JF half:` and `MA half:` — so the correction is visible where a reader actually
sees it, not only in the audit's own output. A note was added above the banner recording that the
phrase is a cross-file anchor and that the block must stay at or under 8 lines.

## Deviations from Plan

### Auto-fixed Issues

Neither task's own work required a fix — both executed exactly as written, and no bug, missing
critical functionality or blocking issue was found in either script. One defect was found in **this
plan's own round-audit measurement** and is recorded rather than smoothed.

**1. [Rule 1 - Bug] The `DEF-06-39-06` detector was vacuous: `grep -F` with a bracketed needle can never match the real token**

- **Found during:** the post-commit round audit, *after* the SUMMARY was written — not by an assertion made beforehand.
- **Issue:** the forbidden-token count was taken with `/usr/bin/grep -cF 'Full[R]efresh'`, copied in shape from 06-43 SECTION O's recipe `(O-a)`. `-F` treats the brackets as literal characters, so the command searches for the *mitigation form* and is structurally incapable of matching the real token. It returned `1` on this SUMMARY (the bracketed text) and `0` on both scripts — a result that reads clean while measuring nothing. This is the `DEF-06-39-06` class one level in: the detector became an occurrence of the mitigation instead of a test for the prohibited thing.
- **Fix:** re-measured with `-cE`, where `[R]` is a character class matching the real `R`, and **driven in both directions against a one-line control file containing the real token** — `-cE` returns 1, `-cF` returns 0 — so the correct form is proven non-vacuous and the broken form is proven non-detecting, rather than either being argued. Corrected counts recorded in the Threat Flags section with both columns shown. The result is unchanged: **0 occurrences of the real token in either script and in this SUMMARY.**
- **Carried, not fixed here:** `06-43`'s published recipe `(O-a)` has the same defect. Its `0` is true of those artifacts (the task verify blocks checked the plain literal separately) but was not earned by the command it publishes. Correcting a committed artifact's recipe is not this plan's to do — flagged for 06-45 / `/gsd-verify 06`.
- **Files modified:** none (the defect was in a measurement, not in a committed file)
- **Commit:** `78d6488`

**2. [Rule 1 - Bug] The write-up of finding 1 was itself an occurrence of the token it counts**

- **Found during:** the re-measurement taken *after* finding 1's correction landed — the same method, one revision later.
- **Issue:** the corrected Threat Flags section explained why `-F` is right in the verify blocks and wrong in the audit recipe, and did so by **quoting the verify-block command with the literal token in it**. That took this SUMMARY's real-token count from 0 to **1**. A paragraph written to document the self-referential-measurement mitigation became an instance of the hazard it documents.
- **Fix:** the needle is now *described* rather than quoted, the miss is recorded in band beside the corrected table, and the count was re-taken a third time. Final state: **0**.
- **Files modified:** `.planning/phases/06-tagger-configuration-and-dry-run/06-44-SUMMARY.md`
- **Commit:** the follow-up commit recorded below.

### Deliberate Non-Deviations

- **The branch was READ, not re-derived.** `BRANCH: B` came from 06-43 SECTION M as one line, exactly as that plan set intended. The instrument's corroborating verdict was earned in **06-42 task 3**, on untouched code, in wave 20 — this plan never re-ran it and never needed to.
- **The exit code was not tuned.** Exit 3 survives because `MA_ARTIST_PENDING` is 1, which is correct. `EXIT_CODE=1` survives on the health check's arm. No override, threshold, grace period or skip sentinel was added to either file.
- **CONF-04 was not ticked and `requirements mark-complete` was not run.** `REQUIREMENTS.md:152` still reads `- [ ] **CONF-04**`. 06-45 owns the record edits behind its own gate.
- **Out of scope, untouched:** section 4c, the MA half, `MA_VERSION_PROVEN`, `stacks/selfhosted/arrs/beets.md`, `06-EXPECTED-TREE.txt`, `06-VERIFICATION.md`, `stacks/selfhosted/arrs/beets/config.yaml`, and `DEF-06-10-01` (the freeze fold-in's inner-ssh bound — a named, owned deferral out of this round's scope). `quick-health-check.sh` was edited **only** inside the `-eq 3` arm; the header's round-1-era notices were left alone because the plan scoped the edit to the arm.
- **Neither snapshot released, no rollback executed.** `tank/media/Music@pre-06-41-conf04-reprobe` and `tank/downloads@pre-phase5` both stay held.
- **`/usr/bin/grep` was used for every workstation-side screen** — the bare name is shadowed by a shell function in this session and has silently matched nothing before.

### A Judgement Call, Recorded Rather Than Buried

The standing rule "if you change a health script, run it afterwards and record the real exit code"
was **not** satisfied by a live run, and that was deliberate. A live `quick-health-check.sh` contacts
the estate — which this plan's objective forbids — and, more importantly, it would have run this
plan's edited local arm against the **old prose still deployed** on LXC 100, since nothing in this
phase has been pushed. That is a partial and misleading test of exactly the thing that changed.
What was done instead drives precisely the changed surface with no estate contact: `bash -n` and a
`shellcheck` delta on both files, both `<automated>` verify blocks re-run at final state, and the
rendered-banner harness through the consuming arm's real `sed` pipeline. The live run belongs with
the `git push` + host `git pull --ff-only` that this phase is already waiting on — an operator action.

## Authentication Gates

None. This plan issued no authenticated call and read no secret.

## Known Stubs

None. Two prose-only edits; no new code path, no placeholder, no unwired data source.

## Threat Flags

None. No network endpoint, auth path, file-access pattern or schema change was introduced — the
diff adds no control flow and no executable statement at all.

**Credential screen (this repository is PUBLIC).** Both scripts screened before each commit: no
added line matches `password|token|api[-_ ]?key|secret|bearer` or any opaque run of 32+ base64-ish
characters. NUL delta measured as `raw − tr -d '\000'` — **0 bytes** on both files — never the
vacuous `grep -c $'\000'` shape (the needle reduces to the empty string and matches every line).

**`DEF-06-39-06`, seventh consecutive round, measured AFTER the edits landed rather than asserted
beforehand.** The forbidden refresh mode's literal token and the forbidden UI button's phrase are
written here in bracketed form — `Full[R]efresh` and `replace all [m]etadata` — for the reason the
deferral exists and which is stated in band rather than left to be rediscovered: a document that
names the thing it counts becomes an occurrence of its own detector, and a prohibition written
plainly is an occurrence of the thing it prohibits.

**⚠ AND THE FIRST ATTEMPT AT THAT MEASUREMENT WAS VACUOUS — caught, as ever, by measuring after the
edit landed.** The recipe reached for was `/usr/bin/grep -cF 'Full[R]efresh'`, copied in shape from
06-43 SECTION O's recipe (O-a). **`-F` makes the brackets LITERAL**, so that command searches for the
*mitigation* and can never match the real token. It returned `1` on this SUMMARY — the bracketed
form — and `0` on both scripts, which looked like a clean result and measured nothing. The correct
detector uses `-E`, where `[R]` is a character class matching the real `R`. Driven both ways against
a one-line control file containing the real token: `-cE` returns **1**, `-cF` returns **0**. So the
`-F` form is proven non-detecting and the `-E` form is proven non-vacuous, rather than either being
assumed. **`(O-a)`'s published recipe carries the same defect and should be corrected where it is
cited** — its `0` was true of those artifacts but was not earned by that command. `(O-b)`, the UI
phrase, already uses `-ciE` and is correct.

Counts taken after both commits and after this SUMMARY was written, with the corrected detector:

| File | real token (`grep -cE 'Full[R]efresh'`) | bracketed form (`grep -cF`) | forbidden UI phrase (`grep -ciE`) |
|---|---|---|---|
| `scripts/check-music-consumers.sh` | **0** | 0 | 0 |
| `scripts/quick-health-check.sh` | **0** | 0 | 0 |
| this SUMMARY | **0** | 1 — the mitigation itself, as intended | 0 |

(The SUMMARY row was **1** in the real-token column for one revision — see the note below the next
paragraph — and is 0 as committed.)

Independently, both task verify blocks assert a `grep -cF` against the **plain, unbracketed literal**
— a correct fixed-string detector, because there are no brackets in the needle for `-F` to take
literally — and it returns `0` on each script. Both verify blocks passed. Two detectors of different
construction, one answer.

**⚠ AND THIS PARAGRAPH ITSELF FIRED THE DETECTOR ONCE, ON THE FIRST WRITING.** It originally quoted
that verify-block command *with the literal token inside it*, to show why `-F` is correct there and
wrong above — and in doing so made this SUMMARY an occurrence of the thing it counts, taking the
`-cE` count from 0 to **1**. Caught by re-measuring after the edit landed, and rewritten to describe
the needle rather than quote it. **Third consecutive round in which the only thing that caught this
class was a post-edit measurement, and the second time in this single document**: first the vacuous
`-F` detector, then this. The lesson is not "remember to bracket it" — it is that **a document
discussing a token cannot be trusted to know its own count, so the count must be re-taken after every
edit to that document**, including edits that exist to explain the mitigation.

## Self-Check: PASSED

Re-asserted against disk and git *after* this summary was written.

- `scripts/check-music-consumers.sh` — FOUND, modified, `bash -n` clean.
- `scripts/quick-health-check.sh` — FOUND, modified, `bash -n` clean.
- Commits `646583a` and `8cac538` — both FOUND in `git log`.
- `TASK 1 VERIFY: OK` and `TASK 2 VERIFY: OK` re-run at final tree state.
- Changed-line audit: **0** non-comment, non-message lines in either diff; **0** added control-flow or `EXIT_CODE=` lines.
- `ARTIST_PROOF_ROWS`: `|4|0|3|ARTISTS|Jewels n`, `|2|1|2|ARTISTS|California Gurls`, `|2|1|2|ARTISTS|Just Give Me a Reason` — all three present verbatim.
- Never-summed rule present (`ARE NEVER SUMMED INTO ONE CONF-04 ANSWER`); the E6-second-measurement sentence present in both scripts.
- Banner block measured at **8** lines and driven through the consuming arm's `1,8p` window: 8 of 8 survive.
- `ROADMAP.md`'s Phase 6 Notes cell verified **APPEND-ONLY**: all 26,064 prior bytes survive as a strict prefix after the one intended `43/45` → `44/45` substitution. `STATE.md` frontmatter parses, no multi-line field orphaned.
- `REQUIREMENTS.md:152` still reads `- [ ] **CONF-04**`; `06-VERIFICATION.md` and `stacks/selfhosted/arrs/beets.md` untouched.

## What This Hands 06-45

- Two scripts whose in-band prose already says **carried, not closed** — so the record edits have a
  consistent source to cite instead of a contradicting one.
- An unticked `CONF-04`, an untouched `06-VERIFICATION.md`, and a `In Progress` Phase 6 status row.
- The never-summed rule and the E6 second-measurement carve-out restated in the instrument itself,
  so neither has to be reconstructed.
- `tank/media/Music@pre-06-41-conf04-reprobe`, still held.
- One thing worth carrying into the record: **the exit code is not a CONF-04 completion signal.**
  The audit exits 3 while either half is pending, and would have exited 3 on a fully successful
  Jellyfin re-probe. Any prose in 06-45 that reads an exit code as a verdict reintroduces the
  summing this round spent its effort preventing.
