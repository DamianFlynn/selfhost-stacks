# Phase 6 — disposition register for `06-REVIEW-GAP.md` (gap closure, ROUND 2)

**Written:** 2026-09-22 by plan 06-29 (wave 13).

## Why this file exists

`06-REVIEW-GAP.md` is a code review of **round 1's own gap-closure changes** — the fixes plans
06-15 through 06-21 wrote to close `06-REVIEW.md`. It found **1 BLOCKER and 7 Warnings inside
those fixes**, and a cross-family adjudication appended two more. Round-2 plans 06-22 through
06-28 supplied the fixes. This file supplies the part a fix commit cannot: a statement of what
happened to **each** of the seventeen findings, so the set cannot be lost at the next context
boundary.

Round 1's own headline lesson, recorded in `06-DISPOSITIONS.md`, is that *a finding recorded
where the next phase does not read is a finding nobody owns*. Round 2 exists because round 1
was not re-reviewed until after it was declared closed. The same discipline therefore applies
again, one level in.

It is referenced from `06-REVIEW-GAP.md`'s appended wiring block and from
`.planning/ROADMAP.md`'s Phase 6 disposition paragraph.

## Source

| | |
|---|---|
| Source review | `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP.md` |
| Reviewed | **2026-09-22T10:45:00Z** |
| `diff_base` … `diff_head` | **7d1092b … 57ccdbf** (`main`) |
| Depth | deep; 6 files (5 shell, 1 markdown); static reading + `bash -n` + `shellcheck 0.11.0` + local reproduction. **Nothing was run against the live estate.** |
| ID space | `GC-01 … GC-15`, plus `GC-16` and `GC-17` from the appended cross-family adjudication |
| Adjudicator | `gemini-3.1-pro-preview` (a single non-Anthropic reviewer; `codex` was intended first choice and failed on billing) |

## Counts

**Findings, as the review's own frontmatter records them:**

| class | count |
|---|---|
| blocker | **1** |
| warning | **7** |
| info | **7** |
| **total** | **15** |

**Adjudicated counts, after the cross-family reviewer's two additions and the orchestrator's
grading correction to GC-16:**

| class | count | which |
|---|---|---|
| blocker | **1** | GC-01 |
| warning | **9** | GC-02 … GC-08 (7), **plus GC-16 and GC-17** |
| info | **7** | GC-09 … GC-15 |
| **total** | **17** | |

**Dispositions, by class:**

| disposition | count |
|---|---|
| FIXED | **17** |
| FIXED (undriven) | **0** |
| ACCEPTED | **0** |
| CARRIED | **0** |

**Reconciliation, stated so an arithmetic slip is visible rather than latent:**
17 + 0 + 0 + 0 = **17**, and 1 + 9 + 7 = **17**. The two totals agree. Against the review's own
pre-adjudication frontmatter: 1 + 7 + 7 = 15, and 15 + 2 (GC-16, GC-17) = **17**. Three routes,
one total.

**`FIXED (undriven)` is zero, and that needs saying rather than celebrating.** In round 1 it held
four rows. It holds none here for a structural reason: every round-2 plan's `<verify>` demanded a
**driven artifact**, and every one delivered one — a pre-fix reproduction, a post-fix refusal and
a passing partner in the same transcript. That is a property of how the round was planned, **not**
a claim that nothing is outstanding. What is outstanding is residue attached to rows that are
themselves FIXED, and it is carried by name in `deferred-items.md` as `DEF-06-29-01` …
`DEF-06-29-07`. Reading a zero in that column as "nothing left to drive" would be exactly the
inversion this register exists to prevent.

**`ACCEPTED` and `CARRIED` are also zero.** No round-2 finding was judged not worth changing, and
none was deferred instead of fixed. Every one of the seventeen has a commit. (Round 1's single
`CARRIED` row, WR-09, is unaffected and stays carried — see § What this register does NOT do.)

## The vocabulary, which is closed

Exactly four words are used, unchanged from `06-DISPOSITIONS.md`. No fifth word was invented, and
no other word appears in the disposition column.

- **FIXED** — a commit changed the behaviour **and** the changed branch was driven. Cites the
  plan, the commit and the artifact holding the driven transcript. For a change with no runtime
  branch (a comment, a claim in prose, a table of counts) the file's own committed state is the
  observation, and the row says so.
- **FIXED (undriven)** — a commit changed the behaviour but the branch was **never observed
  firing** in this phase. Cites the plan, the commit, the artifact, **and** the condition that
  would drive it. Unused in this register; see the note above on why, which is not "because
  everything is settled".
- **ACCEPTED** — deliberately not changed, for one of exactly three reasons: the change would
  invalidate a committed proof artifact; the change requires running an instrument this gap
  closure is forbidden to run; or the finding's own text establishes it as hygiene with a named,
  working compensating control. Unused in this register.
- **CARRIED** — deferred by name, to a `DEF-06-NN-NN` entry or a ROADMAP entry criterion that
  exists. Unused in this register.

### How FIXED and FIXED (undriven) were separated

The same test round 1 applied: **did a summary record the changed branch being observed to fire?**
Where a plan's own NOT-DRIVEN register named the item, that record governs. A drive over a
**synthetic fixture** counts as driven; the evidence cell names the fixture, and where a real-run
drive is still outstanding it is recorded as residue rather than downgraded into the disposition.

Applying that test row by row put all seventeen on the driven side. The four rows where the call
was closest, stated so a later reader can disagree with the judgement rather than the record:

- **GC-16** — the widened regex branch has **no current instance in the tree** (that is the
  finding). Driven against synthetic positive controls that go 0/2 → 2/2, with additivity proven
  against the real tree by comparing matched **line sets** under `diff`, not just counts.
- **GC-15** — the container never saw the quoted command. What was driven is the constructed
  command string and the **argv a bash far side builds from it**, captured. That is a synthetic
  fixture over the exact construction the fix changed.
- **GC-02** — the fence *predicate* was executed (23 new self-test cases, and a bare-glob mutant
  build goes red on 11 of 134). The full destructive programs were deliberately **never** run —
  see § Deliberate non-findings item 5.
- **GC-07 / GC-11 / GC-04 / GC-10** — comment- and documentation-only. No runtime branch exists,
  so the committed file's own state is the observation, exactly as round 1 recorded for IN-04.
  For GC-07 and GC-11 that claim is itself measured: 06-27's diff for that task is **0 non-comment
  lines** and the `--self-test` output is byte-identical before and after (sha256 `400f7183…`).

---

## The register — all 17 findings, in ID order

### Blocker

| ID | Defect, in one clause | Disposition | Confirmed by | Evidence |
|---|---|---|---|---|
| **GC-01** | `printf '%s' "$raw" \| grep -qF` under `set -o pipefail` returns **141** once `$raw` crosses the pipe buffer, so a forbidden substring that **is** present in the arm-1 config dump is reported **absent** — a false green over a live condition, and position-dependent (a match at the top is missed, one at the bottom is found) | **FIXED** | **Confirmed independently by the orchestrator, with a local reproduction** (the adjudicator confirmed the class but this row was carried by the orchestrator's own sweep) | Plan **06-22**, commit `b153c3b`. Both sites now `grep -qF -- "$forb" <<<"$raw"` — a here-string, **not** `set +o pipefail`, because turning the option off around one test weakens every other statement in scope. Driven: 8/16/32/48/56 KiB → rc 0 FOUND; **64/72/96/128 KiB → rc 141 MISSED** pre-fix, rc 0 FOUND post-fix. Self-test **case 7** feeds a **71,013-byte** synthetic dump with the forbidden substring on line 1, its size asserted in band so an under-size fixture FAILS rather than silently skipping; the case was proven to **discriminate** by running it against the pre-fix code (0 red — the MISS; self-test exit 1) as well as the fix (1 red — the CATCH). Artifact `artifacts/06-22-pipefail-141.txt`. **Residue:** the **live** arm-1 dump has never been sized, so whether the mechanism was firing against the estate *today* is unconfirmed — `DEF-06-29-04`. |

### Warnings

| ID | Defect, in one clause | Disposition | Confirmed by | Evidence |
|---|---|---|---|---|
| **GC-02** | The **receiving-side** fences adjacent to the `rm -rf` / `rm -f` are bare globs (`/tmp/p6-*`, `/mnt/fast/safety/phase06/*`) where the sending side restricts the suffix to `[A-Za-z0-9._-]` — so the inner layer accepted `/tmp/p6-x/../../../home`, while three comments beside it claimed it was the layer that could not be bypassed | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-24**, commit `76f5ba9`. All three inner fences now carry the outer predicate in POSIX form. A new `self_test_fences` section drives each fence text **with the outer fence entirely absent** — traversal, the WR-07 word-splitting shape, an empty suffix and a no-shared-prefix path, **each with an accepting partner** so the cases discriminate rather than refusing everything. Silent drift is now a red case: the two stamp copies are asserted **byte-identical** and each program is asserted to begin with the fence text the self-test drove. Self-test **111 → 134** cases. The driven red is against a **mutant build** (11 of 134 red), deliberately not inline, so that `grep -F '/tmp/p6\|/tmp/p6-*) : ;;'` stays at 0 and remains a working regression detector. Artifact `artifacts/06-24-oracle-fence-parity.txt`. **Residue:** the fence has never run under the container's `dash`, and the destructive programs were never executed — `DEF-06-29-05`. |
| **GC-03** | Condition K guards a zero **executable** count, but the block **iterates** executable-minus-exempt; with every executable line exempt the `while … <<< ""` runs zero times, `D04_BAD` stays 0, and the block prints `✅ … (0 of 5 …)` — **CR-01 reproduced one nesting level in** | **FIXED** | **Confirmed independently by the orchestrator, with a local reproduction** | Plan **06-23**, commit `8605b0e`. Three changes together: **condition P**, a fourth ladder arm `[ "$D04_N_ASSERT" -eq 0 ]` in condition K's vocabulary and the siblings' `⚠️ UNKNOWN` prefix; `[ "$D04_N_ASSERT" -gt 0 ]` inside the green condition so the tick and the `N of M` it prints cannot disagree; and the **thirteenth** `EXIT-CODE BEHAVIOUR CHANGED` notice. **Driven, not argued**, by extracting the shipping ladder with `awk` and running it over a synthetic all-exempt fixture built by deleting three *real* lines from a *real* scan: pre-fix `✅ … (0 of 5 …)` exit **0**; post-fix `⚠️ UNKNOWN — every invocation-shaped executable line is EXEMPT (5 of 5)` exit **1**; real tree still `✅ … (3 of 8 …)` exit 0. The belt-and-braces half was driven **alone**, by deleting condition P from a mutant: it withholds the tick but leaves `EXIT_CODE=0`, which is why the **arm** is the primary fix. Artifact `artifacts/06-23-d04-assert-vacuity.txt`. |
| **GC-04** | Cross-file `file:line` citations introduced by round 1 are wrong — the oracle's fence-duplication argument and `beets.md`'s exemption register both rest on numbers that went stale **inside the gap closure that wrote them** | **FIXED** | Recorded UNVERIFIABLE by the adjudication (the prompt carried only `git diff -- scripts/`; `beets.md` and `beets.yaml` were never supplied). **Verified during round-2 planning by opening the targets, and re-verified by the executing plan** — not disputed by anyone | Plan **06-28**, commit `ab5ff32`. **Nine stale, not four.** The plan mandated a mechanical enumeration rather than starting from the review's table: **23** cross-file references across the five files this round touched, of which **9** were stale and 13 resolve. Five of the nine were **not named by the review**, and one of those (`beets.yaml:54-60`) was load-bearing on the plan's own verify test 2 — repairing only the named four would have left the plan failing its own check. One (`PROJECT.md:187` / `CLAUDE.md:152`) was **half-rotted**: one of a cited pair still worked, which is exactly what lets this class survive a spot-check. Every anchor was `grep -c`'d in its **target** for uniqueness and the single-line property **before** being written into the citer; `PREP REFUSED` alone appears twice, so the anchor written in is `PREP REFUSED root`. The `beets.md` exemption register was rekeyed on `$SCRATCH_OVERLAY` and `$ROOT/overlay.yaml` — **literally the two alternations of `D04_EXEMPT_RE`** — so register and regex cannot drift apart. No runtime branch exists; the committed files' own state, plus each anchor's measured hit count in its target, is the observation. Artifact `artifacts/06-28-citations-and-counts.txt`. **Residue:** a ninth stale citation in `quick-health-check.sh`, out of that plan's scope — `DEF-06-29-02`; and the thirteen surviving `file:line` references resolve **today**, which is precisely the property that expires — `DEF-06-29-06`. |
| **GC-05** | `assert_dj_count`'s zero-expected arm returns **1** (`bad()` → RED) where the phase's three other vacuity guards return **2** (`unknown()`), so a rule the run never exercised is reported as a measured failure — and, because UNKNOWN outranks RED, the vacuity is then **erased entirely** by any unrelated blindness in the same run | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-27**, commit `613ace8`. Both arms — `assert_dj_count`'s zero-wanted and its neighbour `assert_no_compilations`' zero-`Various Artists` — now return **2**, and both self-test expectations moved `1 → 2` with them, so the pair stays symmetric rather than propagating the neighbour's misclassification. Driven **both ways including the counter**; the first harness measured nothing because `out="$(run_assert …)"` incremented `REDS`/`UNKNOWNS` in a subshell, which was caught and corrected (see § A systemic observation). The EXIT CODES block records the verdict change, gives its one-sentence reason, states **NOTHING WAS RENUMBERED**, and cross-references the precedence paragraph — because the practical effect reads backwards. Artifact `artifacts/06-27-oracle-vacuity-and-claims.txt`. **Residue:** the live vacuity arms have never been through a real `--run` over a sample with no S5 stratum — `DEF-06-29-05`. |
| **GC-06** | Three `printf \| grep -q` instances remain in shipped oracle code; **`:1831` is an inverted assertion**, where a grep *match* is the failure case, so a 141 makes the `if` false, `rc` stays 0, and the self-test reports **PASSED** at the precise moment it should have failed | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-24**, commit `3019c0c`. All three converted to here-strings; **zero** `… \| grep -q` pipelines remain in the oracle's executable code. The inverted assertion's danger is **demonstrated rather than asserted**: at 128 KiB the pipeline form reports the case **PASSED** on an input it is supposed to reject and the here-string reports **FAILED**; at the fixture's real 75 bytes both forms are correct, and that is recorded explicitly rather than glossed. The 64 KiB SIGPIPE threshold is **independently reproduced** here from a different script, needle and haystack — two reproductions on darwin 27.0.0. Artifact `artifacts/06-24-oracle-fence-parity.txt`. |
| **GC-07** | The IN-06 comment claims `RUN_TAG="$$"` *"removes the predictability"* — but PIDs are small, sequential and enumerable, `$$` is the **macOS workstation's** PID with no relationship to the container's namespace, and the step-1 probe is what actually refuses a pre-placed name | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-27**, commit `525ef7c`, applying the single threat-model decision plan **06-25** recorded for both siblings (`artifacts/06-25-incremental-tempnames.txt` § 4): *the threat is real and the treatment is a container-minted name, but the property relied on is `mktemp`'s **O_EXCL creation**, not secrecy* — which is exactly why `$$` was the wrong mechanism for the right threat. **No second decision was made**; the sibling's answer was quoted. **Comment-only, and proven comment-only**: 0 non-comment lines in the task's diff, `--self-test` output byte-identical. The committed file's own state is the observation. Artifact `artifacts/06-27-oracle-vacuity-and-claims.txt`. |
| **GC-08** | The IN-06 hardening was applied to **one of two sibling instruments**: `phase06-incremental-control.sh` still writes fixed, predictable `/tmp/p6-*` names with `>` redirections in the **same container as the same user** — and `/tmp/p6-taghist.py` is written and then **executed** | **FIXED** | Recorded UNVERIFIABLE by the adjudication (evidence not supplied). **Verified by the executing plan**, which re-checked the premise against the pre-fix file at `bf509f4` and found it holds **at all seven sites** — not disputed | Plans **06-25**, commits `871a531` and `c908c09`. `write_prog_manifest` mints one **directory** (`mktemp -d /tmp/p6-mf.XXXXXXXX`); `write_prog_taghistory` mints its **program path** and executes *that*. A failed mint is a **refusal** — a BLIND line in the file's existing vocabulary and exit **2 (UNKNOWN)** — with **no fallback to the fixed name**, because a fallback fires precisely when the environment is least trustworthy. Cleanup moved onto a **trap**, gated by a `case` re-test of the template prefix; the old `rm -f` sat after the last BLIND, so every could-not-look already leaked all three files, and minting makes a leftover unfindable rather than merely untidy. The threat was **measured, not assumed**: `/tmp` is `1777` and every non-PID-1 process in `beets-flask` runs as **uid 568, the same uid the instrument execs as**, so `fs.protected_symlinks`/`protected_regular` do not cover it. **Seven drives**, including the fail-closed branch in the **container's own dash** (D5) and the trap firing on an early exit (D7). Artifact `artifacts/06-25-incremental-tempnames.txt`. |
| **GC-16** | `D04_INV_RE`'s fourth (variable-expansion) branch anchors only on content start or an opening quote, while its three **literal** siblings also anchor on `&&` / `;` and on `docker` — so `&& $BEET_BIN config` or `docker exec … $BEET_BIN config` is invocation-shaped and **invisible to the detector CR-01 was raised against** | **FIXED** | Found by the cross-family reviewer; **its BLOCKER justification was FALSE and its substantive defect TRUE** — see § Three corrections to the source material. Graded **WARNING** by the orchestrator after reading the regex and the comment | Plan **06-23**, commit `58e4aaf`. Branch 4 gained its siblings' leading alternation; the **trailing** flag-or-subcommand requirement is untouched — that half is what holds the executable count at 8 rather than 26. **Additivity measured over identical input** (the scan of base `bf509f4`, so the regex is the only variable): all seven counts identical, and the matched **line sets byte-identical under `diff`**, which is the stronger statement. Controls: the two previously-invisible shapes go **0/2 → 2/2**; content-start and literal shapes stay 2/2; four mention/argument-passing shapes stay 0/4 under both. The most useful negative is `if [[ $BEET_EXEC_RC -eq 0 ]]; then` — it contains a `;` and is where the new anchor could have over-matched; it does not, because the anchor requires whitespace before the separator and the line reads `]];`. Artifact `artifacts/06-23-d04-assert-vacuity.txt`. |
| **GC-17** | Three overridable paths reach remote **command strings** unquoted in `quick-health-check.sh` (`cd $D03_REPO_ROOT`, `D04_CMD="cd $D04_REPO_ROOT`, `bash $CONSUMERS_SCRIPT`) — the WR-08 defect reproduced in the sibling file WR-08's plan did not own | **FIXED** | Found by the cross-family reviewer; **its three line numbers were wrong** (it numbered the diff, not the file) and were grep-repaired by the orchestrator; the finding stands at all three sites | Plan **06-26**, commit `96bf5ff`. **Four sites, not three** — `DRIFT_CMD="set -o pipefail; cd $DRIFT_REPO_ROOT …"` is the same shape and was found while planning. Fixing three of four instances of a class, **in the round whose subject is siblings that drifted apart**, would have been GC-08 committed deliberately. Each knob is rendered once with `printf '%q'` beside its own override-contract block; the bash dependency is stated in band once, cross-referenced from the other three, naming GC-17 and GC-11. **Driven live** against a scratch checkout on LXC 100 whose path contains spaces: before, all three `cd` sites gave `bash: line 1: cd: too many arguments` → ssh 3, and the consumers site gave **127** and landed in the generic ❌ BROKEN arm; after, every one reaches its intended branch. The interesting half is the **diagnosis**: all three `cd` sites reported *"3 = no `<path>` checkout"* while naming a path that existed, and the consumers exit-3 arm — the branch the knob exists to make driveable — **could not be reached at all**. Artifact `artifacts/06-26-qhc-knobs-and-tail.txt`. |

### Info

| ID | Defect, in one clause | Disposition | Confirmed by | Evidence |
|---|---|---|---|---|
| **GC-09** | The `EXIT_CODE != 0` tail enumerates the blocks that can carry a ❌/⚠️ and was **not extended** when plans 06-16 and 06-17 added new fatal conditions — the D-03 and D-04 blocks are not named in it at all, so *"a tail that lists every block except the failing one sends the reader to the green ones"* | **FIXED** | Recorded UNVERIFIABLE by the adjudication (evidence not supplied). **Verified and extended by the executing plan** — not disputed | Plan **06-26**, commit `5ffbc3d`. Rebuilt from a **mechanical enumeration**, not from the review's two examples: every executable `EXIT_CODE=1` site attributed to its owning block by grep'd anchor — **98 sites across 14 blocks**, 13 of which can reach the tail (the coreutils startup gate `exit 1`s on the spot). The tail named **11 of 13**; the two missing hold **30 of the 98 sites**. Coverage proven mechanically before and after, against the tail's **rendered** text, 11/13 → **13/13** — the first attempt matched the tail's *source* lines and reported false FAILs, because flattening `echo "…"` interleaves the quote delimiters into the prose. The tail also now names the consumers block's expected ⚠️ with **E6** as its clearing condition, and explicitly says CONF-04 is **not** closed. A sixth comment paragraph records that the tail fell behind three plans despite four in-band restatements of the same-commit discipline, and points the next author at the enumeration rather than at the list. **No new numbered notice** — this creates no new fatal condition; header count 13 before and after. Artifact `artifacts/06-26-qhc-knobs-and-tail.txt`. |
| **GC-10** | `beets.md`'s measured-counts table no longer matches the tree **and says it does** — the claim *"agreement at every position, both trees"* is self-invalidating, because the note's own body quotes the patterns it is counting | **FIXED** | Recorded UNVERIFIABLE by the adjudication (`beets.md` was never supplied). **Verified by the executing plan**, which found the inherited numbers stale **twice over** — not disputed | Plan **06-28**, commits `64886ab` and `ba810fb`. Both regexes were **extracted** from `quick-health-check.sh`, never retyped (06-23 widened `D04_INV_RE` in this same round), with the extraction asserted non-empty *and* unique before use. `beets.md` read **191 / 90**; the plan body quoted **199 / 98**; measured independently at base: **200 / 99**. The self-invalidating claim is gone and the two **unpinned** rows with it. Taking the drop was then **demonstrated rather than argued**: writing the prose that explains why the counts are not recorded moved raw **200 → 202** and comment-stripped **99 → 101**, in the same commit that removed the figures — GC-10's defect reproduced one last time by the fix for it. **No pinned figure moved at any point** (10 / 8 / 3 / 5 / 2 throughout). No runtime branch exists; the committed page's own state is the observation. Artifact `artifacts/06-28-citations-and-counts.txt`. **See the correction in § Three corrections, item 4** — the artifact's own summary table and its later section disagree on the after-reading, and this plan re-measured HEAD to settle it. |
| **GC-11** | `remote_sh_c`'s comment justifies `printf '%q'` on the grounds that *"the result lands in a bash WORD"* — which is the argument for the **arguments** and is silent about the **program text**, where `%q` renders multi-line programs as bash `$'…'` and therefore requires a bash-family shell at both remote hops | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-27**, commit `525ef7c`. One sentence added to `remote_sh_c`'s comment naming the dependency and grading it **fail-closed** — a non-bash transport gives a loud syntax error and a non-zero status, not a mangled `rm`. The dependency is real and measured (`transport = bash`: rc 0, program runs; `transport = dash`: rc 2, syntax error) and is almost certainly satisfied. **Comment-only, and proven comment-only** by the same 0-non-comment-lines / byte-identical-self-test check as GC-07. Artifact `artifacts/06-27-oracle-vacuity-and-claims.txt`. |
| **GC-12** | Self-test bookkeeping: a `UNKNOWNS=0` reset that is written and never read, in the section whose subject is counters that are never read; and a gate that fires on `ST_FAIL != 0` **or** `REDS != 0` but prints `'%s of %s case(s) FAILED'` with `ST_FAIL` — so a run failing only on `REDS` prints **`0 of N case(s) FAILED`**, a failure banner asserting nothing failed | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-27**, commit `38fd534`. The dead `UNKNOWNS=0` deleted; the banner names **both** counters. Driven both ways on two scratch copies. **`REDS` was deliberately NOT folded into `ST_FAIL`** — they count different things and the self-test exists to keep them apart; the fix is an honest banner, not a merged counter. Artifact `artifacts/06-27-oracle-vacuity-and-claims.txt`. |
| **GC-13** | `check-beets-config.sh` self-test case 6 funnels three outcomes through one counter and compares the **sum** against one expected total, so *"one real violation in the source"* + *"the checker is BLIND"* sums to 1 and the case reports `✅ … 1 red, as expected` — **two faults cancelling into a pass** | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-22**, commit `ad5a854`. `assert_beet_invocation_contract` now also sets `ARM1_REAL_VIOLATIONS` and `ARM1_SYNTH_REJECTED`, re-initialised per call, with **`-1` UNKNOWN sentinels at script level** so a gate reached without the producer having run FAILS rather than passing on a zero. Case 6 requires `real == 0 && synth_rejected == 1` and, on failure, names **which half** is wrong and its observed value — *"1 red, expected 1"* is exactly what made this invisible. `run_case`'s identical-looking summed comparison was **left alone** on measurement: there every red comes from the same pure function over one synthetic dump, so the sum *is* the whole outcome. Driven with **four** mutants, not the three the plan asked for: the fourth restores the **old summed gate** against the combined mutant and reproduces the defect directly (`[OLD GATE] … 1 red, as expected`, RC=0) — without it the evidence shows only that the new gate fails, not that the old one passed, which is the actual claim. Artifact `artifacts/06-22-pipefail-141.txt`. |
| **GC-14** | `CONSUMERS_OVERRIDDEN` is consulted only inside the `CONSUMERS_RC -eq 0` arm, so on the new exit-3 arm an overridden run prints `⚠️ CONF-04 MEASURED AND OPEN` with **no hint that the audit that answered was not the deployed one** — a diagnosis defect, telling the operator the estate is off target when what was measured is an arbitrary file | **FIXED** | Confirmed by the cross-family reviewer | Plan **06-26**, commit `33ed08b`. **Six arms, not two.** The plan's action named the exit-3 arm and the generic `else`; its own must-have said *"every arm that can report it"*, and six can. The empty-output and 124 arms needed it most: their existing text **names the deployed path** in its re-run advice, and the empty-output arm additionally says *"172.16.1.159 unreachable"* — a confident wrong diagnosis when the real cause is a stub that printed nothing. Five live drives with scratch stubs, plus an **isolated per-arm `EXIT_CODE` proof** from a ladder extracted out of the shipping file: nine fixture rows, **EXIT_CODE identical pre and post in every one**, the override column the entire delta (0 → 1). Diagnosis only; the single green arm is still the single green arm and no `warn()` site was promoted into `FAILURES`. **`DEF-06-21-07` was driven in the same task and PASSES** — see § Deliberate non-findings item 6. Artifact `artifacts/06-26-qhc-knobs-and-tail.txt`. |
| **GC-15** | Two overridable paths reach the remote command string unquoted: `rsh "$(dex_cmd sha256sum "$REAL_LIB_DB" "$REAL_STATE_PICKLE")"`, where `dex_cmd` renders with `"$*"` — no `printf '%q'`, no `remote_sh_c` — so a value with a space, a quote or a `$` word-splits on the far side | **FIXED** | Recorded UNVERIFIABLE by the adjudication (evidence not supplied), then **crossed with GC-17's citation** in the adjudication's own summary. **Verified by grep at its correct citation during round-2 planning**, and again by the executing plan — not disputed | Plan **06-27**, commit `38fd534`. Both sites pass `printf '%q'` output. Quoted **at the two call sites, not inside `dex_cmd`**, which would double-quote eighteen existing sites. The consuming `awk` keys were **confirmed to stay raw, not assumed**. Driven by capturing the command string and the **argv a bash far side builds from it**. Artifact `artifacts/06-27-oracle-vacuity-and-claims.txt`. **Residue:** the sites *as sent* — the container never saw the quoted command; and a `REAL_LIB_DB` carrying a space against a real container, whose outcome is **predicted** (UNKNOWN + exit 3, because `awk`'s `$2` cannot key a whitespace path) rather than measured — `DEF-06-29-05`. |

---

## Three corrections to the source material

A register that only repeats its source would lose these. Each is a correction to
`06-REVIEW-GAP.md` or to a number inherited from it, established during round 2.

### 1. The adjudication crossed GC-15 with GC-17

Its summary paragraph read: *"GC-15 was separately confirmed by the orchestrator while checking
GC-17 — the three sites are real, at `quick-health-check.sh:1515`, `:1728`, `:2196`."`* **Those
three sites are GC-17's.** GC-15 is two `dex_cmd sha256sum` sites in `phase06-oracle.sh`.

**Both findings are real, in different files, and both were grep-verified during round-2
planning.** Only the label was crossed. Caught by the round-2 planner; the correction was written
**into** `06-REVIEW-GAP.md` as a visible `> CORRECTION` block rather than silently repaired,
because an executor following the crossed citation would have "fixed" the wrong file and reported
success. That is not hypothetical: plan **06-26** records in its own decisions that it deliberately
did **not** open `phase06-oracle.sh` for this reason, and plan **06-27** records that it inherited
the correction rather than going looking. **A later reader following the adjudication's original
summary line will look for GC-15 in the wrong file.**

Established by: the round-2 planner (grep); recorded by the orchestrator in commit `3fa831c`.

### 2. GC-16's BLOCKER justification was false and its defect is true

The cross-family reviewer graded GC-16 **BLOCKER** and justified it by claiming the block comment
promises separator anchoring. **That justification is false** — the comment says *"content start,
or immediately inside an opening quote"*, which is exactly what the code did. There is no
documentation mismatch.

The **substantive** blind spot is real, has **no current instance in the tree** (executable count
8, all found), and is graded **WARNING**. Both halves matter: had the register recorded only the
grade, a later reader would believe a documentation defect that does not exist; had it recorded
only the false justification, a real blind spot would have been dismissed with it.

Established by: the orchestrator, reading the regex and the comment; restated in band by plan
06-23 in the file itself so it is not re-argued.

### 3. Five findings came back UNVERIFIABLE, and none of them is FALSE

`GC-04`, `GC-08`, `GC-09`, `GC-10` and `GC-15` were recorded UNVERIFIABLE by the adjudication
**because the evidence was never supplied to the reviewer** — the prompt carried only
`git diff 7d1092b..HEAD -- scripts/`, so `beets.md`, `beets.yaml` and full file bodies were absent.
That is the orchestrator's scope error, not a reviewer judgement, and the adjudication says so.

Four (GC-04, GC-08, GC-09, GC-10) were verified during round-2 planning by opening the targets;
GC-15 was verified at its correct citation. **All five were then verified again by their executing
plans, and three of them turned out to be WIDER than the review described** — GC-04 was nine stale
citations, not four; GC-09's enumeration found 98 sites across 14 blocks; GC-10's inherited numbers
were stale twice over. **The adjudication's own verdict table records ZERO false findings.**

**"Unverifiable" and "false" are different words, and this round must not let the first decay into
the second.** That is why every row above carries a `Confirmed by` cell naming who established the
finding and how.

### 4. A fourth correction, found by this plan: the GC-10 after-reading in `artifacts/06-28-citations-and-counts.txt` is internally inconsistent

Not a correction to the review — a correction to round 2's own record, and it is GC-10's own
defect firing one more time.

That artifact's RESULTS table records `06-28 AFTER … raw 200 / comment-stripped 99`, while its
later section — added in the same plan's second commit — records `64886ab (after Task 2) … 202 /
101` and explains the `+2` as the plan's own prose. The table was written before the prose landed
and was not re-read afterwards.

**Re-measured by this plan at HEAD (`23b2b82`), using the block's own pipeline with both regexes
extracted from the shipping file and every grep answered by `/usr/bin/grep` (BSD grep
2.6.0-FreeBSD), not the operator's interactive ugrep alias:**

| count | at HEAD | pinned? |
|---|---|---|
| raw | **202** | no |
| comment-stripped | **101** | no |
| invocation-shaped | **10** | adjacent |
| executable | **8** | no |
| asserted | **3** | no |
| exempt | **5** | **YES** (`D04_EXEMPT_BASELINE`) |
| documentation | **2** | **YES** (`D04_DOC_BASELINE`) |

**The pinned vector 10 / 8 / 3 / 5 / 2 did not move across the whole round.** The two unpinned rows
moved three times, which is the entire argument 06-28 made for dropping them from `beets.md` —
and this register therefore does **not** pin them either. For the historical record: **199 / 98**
is 06-23's old-regex-vs-new-regex pair over identical input (the only pair that can prove the
widening additive) and is *not* a reading of any tree's HEAD; **200 / 99** is the reading at three
independent points before 06-28's own prose landed.

Established by: this plan, plan 06-29, by measurement.

---

## Deliberate non-findings — recorded so they are not re-reported

The four from `06-DISPOSITIONS.md` still stand, unchanged, and are restated rather than
cross-referenced because a pointer that needs a second file open is a pointer that gets skipped:

1. **The exit-code NUMBERING difference between the two sibling instruments.**
   `phase06-incremental-control.sh` uses UNKNOWN=2 / usage=3; `phase06-oracle.sh` uses UNKNOWN=3 /
   usage=2. IN-08 was about **precedence**, not numbering, and the precedence is fixed and stated
   in both. Renumbering would invalidate committed evidence that cites those codes. **Re-confirmed
   in round 2** by plans 06-25 and 06-27: GC-05 moved two assertions *between* existing codes and
   06-27 states `NOTHING WAS RENUMBERED` in band.
2. **The D-04 block reports UNKNOWN on the live estate.** Correct and expected: `/mnt/fast/stacks`
   is at pre-Phase-6 `c67d497`, so the executable count there is genuinely 0 and the vacuity guard
   rightly refuses. It clears on the operator's `git push` plus a host `git pull --ff-only` and on
   nothing else. **Nothing in this phase has been pushed.**
3. **`quick-health-check.sh` will exit non-zero on the consumers block** from the moment this phase
   is pushed and the host pulls, and will stay non-zero until Phase 7 entry criterion **E6**
   discharges CONF-04. **Intended. Do not tune it out** — the twelfth notice says so inline, and
   round 2's rebuilt tail (GC-09) now names it with E6 as its clearing condition.
4. **The two verbatim Nov-2025 quotations in `beets.md`** are historic quotations and are not
   updated to match later measurements.

Round 2 examined and deliberately left alone:

5. **The oracle's three destructive programs were never executed — not even on paths the fence
   should refuse.** Deliberate, and the reason is worth keeping: a fence regression would turn the
   self-test itself into `rm -rf /tmp/p6-x/../../../home`. What *was* driven is the fence text, with
   each program asserted to begin with the exact text the self-test drove. The step from "the fence
   refuses" to "the program refuses" is sound but **structural**; no `rm` was observed declining to
   run. Carried as `DEF-06-29-05`.
6. **`DEF-06-21-07` is DRIVEN and it PASSES**, by plan 06-26 task 2 — pointed at a stub whose
   `📊 6. Summary` heading is renumbered, the exit-3 arm reports UNKNOWN and prints no counts,
   exactly as 06-17 designed it. It needed no estate contact. **Not a new finding**; residue of
   WR-03 and it can close. Marked driven in `deferred-items.md` rather than left open.
7. **Three literal fence copies in the oracle, rather than one shared string.** Aliasing would make
   drift structurally impossible, which is strictly stronger than testing for it. It was not done,
   and the honest second reason is recorded: 06-24's own verification asserts the narrow character
   class appears at **five or more** sites, and an alias yields four. The residual risk is closed by
   an executed byte-equality case. **This will trip a future plan that legitimately de-duplicates
   them** — carried as `DEF-06-29-03`.
8. **`check-music-freeze.sh` is ❌ on the live estate** (`interpolated-host-path inventory MOVED:
   expected=12, found=13`) and `check-music-consumers.sh` on the host has **zero** `exit 3`
   occurrences. Both are the host's pre-Phase-6 commit, **not** round-2 fallout, and both clear on
   the same push-and-pull as item 2. Recorded so neither is mistaken for a regression.

## What this register does NOT do

**It changes no verdict, and it does not re-verify the phase.** No `/gsd-verify` run was performed
by plan 06-29 and no verification result is claimed here.

- **CONF-04 is NOT closed.** `REQUIREMENTS.md` is untouched by this plan and `- [ ] **CONF-04**`
  stands. Its two verdicts — **Jellyfin pending, Music Assistant discharged** — are recorded
  separately and **are never summed**. The measurements taken for E6 on 2026-09-22 were: Jellyfin
  pending **3**, Jellyfin at target **0**, Music Assistant reported **1**, Music Assistant at target
  **2**, `FAILURES` **0**. ROADMAP entry criterion **E6** still owns the discharge.
- **No requirement checkbox moves** and no phase-status wording is altered. Whether Phase 6 is
  complete is the verifier's call on a re-verification this plan does not perform.
- **Round 1's carried items stay carried.** CR-01's residue is still owned by ROADMAP entry
  criterion **E10** and WR-09 by **E11**; `DEF-06-21-01` through `DEF-06-21-08` are unchanged apart
  from `DEF-06-21-07`, marked driven (item 6 above), and `DEF-06-21-02`, whose *description* was
  corrected in band by 06-27 while its substance and driving condition are unchanged.
- **It closes no Phase 7 entry criterion** and adds one: **E12**, carrying round 2's residue.

## A systemic observation

Round 1's systemic finding was about plans' `<verify>` blocks. Round 2's is about **rounds**, and
it is the more expensive of the two.

**A BLOCKER and seven Warnings were found inside the gap closure written to remove that exact
defect class** — and the single highest-value finding, GC-03, is the phase's Critical reproduced
one nesting level in: condition K guards the count the block *prints* while the block iterates a
different set, so a green tick over an empty asserted set survived the plan written to abolish
green ticks over empty asserted sets. GC-01, the BLOCKER, sits in the script that gates config
correctness and was introduced by a round-1 plan. GC-02's two fence copies **drifted at birth**, in
the direction that matters, with three comments beside them claiming the weaker copy was the one
that could not be bypassed.

What that implies, stated narrowly and only for what this round measured: **closing a round on
"the finding is fixed" is not the same as closing it on "the fix was reviewed".** Round 1 was
declared closed and verified 6/6 *before* anyone read its own diff; the 6/6 was true and the code
still carried a BLOCKER, because verification asks whether the must-haves were met and review asks
whether the code that meets them is correct. Those are different questions and round 1 answered
only the first.

Three smaller cross-plan signals, kept because each is reusable:

- **Seven wrong-premise `<verify>` checks across eight plans**, all reported rather than absorbed:
  a wrong grep method; a wrong "next free letter" (A–O all taken, because an earlier notice used
  M/N/O out of order); a non-existent anchor section (there were **no** WR-07 fence cases — the
  06-18 fence shipped with zero executed coverage, which is *why* GC-02 survived); a
  self-contradicting threshold (comment says four, test says five, and the DRY fix yields four);
  an expected count its own fix invalidates; a `grep -cF 'cd $VAR'` absence test that
  substring-matches the corrected `cd $VAR_Q`, so **the correct fix fails the check**; and
  **twice**, a check that cannot distinguish a claim from its retraction — forbidding a string that
  must be quoted in order to disown it. Carried as `DEF-06-29-07`.
- **Five agents independently hit the same template defect.** Every round-2 plan's `<verify>` opens
  with `cd /Users/damian/Development/damianflynn/selfhost-stacks` — the **main checkout**, which
  does not carry a worktree agent's edits. Obeying it measures the *unmodified* file and reports a
  green describing nothing. **The template is the defect, not the executors.** Carried as
  `DEF-06-29-07`.
- **Three plans' harnesses silently measured nothing before being caught** — `OUT=$(eval "$LADDER")`
  and `out="$(run_assert …)"` both run in a command-substitution subshell and discard the counter
  the harness exists to measure; `awk '/start/{f=1} /^fi$/{exit} f'` extracted zero lines because
  the terminator matched 17 times earlier in the file. Each was caught only because one row read
  the same as rows that demonstrably differed. **A harness that passes by measuring nothing is the
  same defect as the code it is testing**, which is the through-line of both rounds.

---

_Register written 2026-09-22 by plan 06-29._
_Source: `06-REVIEW-GAP.md`, reviewed 2026-09-22T10:45:00Z against `7d1092b..57ccdbf`, plus its
appended cross-family adjudication._
_Gap closure round 2: plans 06-22, 06-23, 06-24, 06-25, 06-26, 06-27, 06-28, 06-29._
_All measurements in this file answered by `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD)._
