# Phase 6 — disposition register for `06-REVIEW-GAP3.md` (gap closure, ROUND 4)

**Written:** 2026-09-23 by plan 06-39 (wave 17).

## Why this file exists

`06-REVIEW-GAP3.md` is a deep code review of **round 3's own gap-closure changes** — the 320-insertion,
44-deletion diff that plans 06-30 through 06-34 wrote across four scripts to close
`06-REVIEW-GAP2.md`. It found **0 Critical, 6 Warning and 4 Info inside those fixes**. Round-4 plans
06-35 through 06-38 supplied the fixes. This file supplies the part a fix commit cannot: a statement
of what happened to **each** of the ten findings, so the set cannot be lost at the next context
boundary.

Round 1's headline lesson, recorded in `06-DISPOSITIONS.md`, is that *a finding recorded where the
next phase does not read is a finding nobody owns*. Round 2 existed because round 1 was declared
closed before anyone read its own diff. Round 3 existed because round 2 closed several classes
**partially** while writing in-band claims that they were closed **completely**. **Round 4 exists
because round 3 did the same thing** — and found, in round 3's own diff, four more live instances of
a shape the file's own ⛔ paragraph forbids, eleven lines *below* that paragraph, under a sentence
declaring the class closed. The recursion stops by recording honestly, not by recording nothing.

It is referenced from `06-REVIEW-GAP3.md`'s appended wiring block and from `.planning/ROADMAP.md`'s
Phase 6 disposition paragraph.

## Source

| | |
|---|---|
| Source review | `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP3.md` |
| Reviewed | **2026-09-23** (frontmatter `reviewed: 2026-09-23T00:00:00Z`) |
| `diff_base` | **`fff070a97cd867c8bd52d10bff2b074e0530ba74`** — the tree as it stood *before* round 3, so the diff under review is round 3's entire output (`320` insertions, `44` deletions) |
| Depth | **deep**, scoped to `git diff fff070a..HEAD -- scripts/` |
| Files reviewed | **4**: `scripts/check-beets-config.sh`, `scripts/phase06-incremental-control.sh`, `scripts/phase06-oracle.sh`, `scripts/quick-health-check.sh` |
| ID space | `WR-01 … WR-06`, `IN-01 … IN-04` — **which is round 1's namespace.** See the mapping table immediately below; the fixes are cited in band as `R4-01 … R4-10` |
| Adjudication | **NONE. There was no cross-family adjudication in round 4.** Round 2 had one; rounds 3 and 4 did not. See the note below — this is stated rather than left ambiguous |

**The review's own measurement note, carried forward because it bounds every finding below.** Every
grep in the review was run as `/usr/bin/grep` **by absolute path**, not the operator's zsh `grep` →
`ugrep` alias. **There was no estate contact of any kind**: no ssh, no docker, no `--run`, no
`--arm`. **`scripts/quick-health-check.sh` was not executed at all.** The only script executed was
`scripts/phase06-oracle.sh --self-test`. Several findings are therefore explicitly *static reasoning
about code that was read*, and the rows below say which.

### On the absent adjudication

Round 2's register records a cross-family adjudication (`gemini-3.1-pro-preview`) that **appended two
findings**, GC-16 and GC-17, taking that round from 15 to 17. **Round 3 had no such adjudication, and
neither did round 4.** No second model family was asked, nothing was appended, and the ten findings
`WR-01 … IN-04` are the whole set. This is written down because an absent adjudication that is not
mentioned reads exactly like a lost one. The absence is a fact about round 4, not a claim that
another family would have found nothing — and it is worth noting that round 2's appended pair
contained, between them, a real BLOCKER-graded defect and the finding that R3-01, and then R4-01,
each landed on in turn.

---

## THE ID MAPPING TABLE — read this before following any citation

| Review ID | In-band ID | File | Subject, in one line |
|---|---|---|---|
| **WR-01** | **R4-01** | `scripts/quick-health-check.sh` | the ⛔-forbidden `\"$KNOB\"` shape is live four times, eleven lines below its own prohibition, and R3-01's new text says the class is closed |
| **WR-02** | **R4-02** | `scripts/phase06-oracle.sh` | `ST_PLANNED_CASES=134` is not invariant over the self-test's own documented environment-conditional skips — a false red with a wrong stated cause |
| **WR-03** | **R4-03** | `scripts/phase06-incremental-control.sh` | the new `INT TERM HUP` handlers do not exit, so a delivered signal is swallowed: the scratch path is deleted and the program runs on to exit 0 |
| **WR-04** | **R4-04** | `scripts/phase06-incremental-control.sh` | R3-09's stated mechanism (`timeout` delivering SIGTERM to the in-container shell) is not established, and the signal that most likely *does* arrive — `PIPE` — was not in the list |
| **WR-05** | **R4-05** | `scripts/check-beets-config.sh` | the hunk correcting a self-referential grep count states a raw count (`raw is 4`) that its own text falsified to 5 |
| **WR-06** | **R4-06** | `scripts/phase06-oracle.sh` | the new sha256 line parser guards the layer-3 `-l` assertion and has no case in the set R3-02 pinned in the same round |
| **IN-01** | **R4-07** | `scripts/quick-health-check.sh` | `DASH_RESOLVE_IP` still reaches a remote command string raw, and the new census does not mention it |
| **IN-02** | **R4-08** | `scripts/quick-health-check.sh` | the census recipe's second grep misses two `bounded_ssh` remote call sites |
| **IN-03** | **R4-09** | `scripts/phase06-oracle.sh` | `awk -v p="$REAL_LIB_DB"` applies awk escape processing to an overridable knob |
| **IN-04** | **R4-10** | `scripts/phase06-oracle.sh` | R3-04's two new `exit 3` arms leave the container scratch and the LXC stamp behind, unstated in band |

### Why the aliasing exists — two clauses, both measured

**Clause one: round 4's report reuses round 1's `WR-*` / `IN-*` namespace.** Round 1's review
(`06-REVIEW.md`, 24 findings) used `CR-*` / `WR-*` / `IN-*`. Round 2 used `GC-*`. Round 3 used
`R3-*`. Round 4's report went back to `WR-*` / `IN-*`.

**Clause two: round 1's IDs are already cited in band in all four scripts**, so `WR-01`, `WR-02`,
`WR-03`, `WR-04`, `WR-05`, `WR-06`, `IN-01`, `IN-02` and `IN-03` each **already mean something else
in the very files round 4's findings land in**. Measured at HEAD with `/usr/bin/grep -cF`:

| File | Round-1 in-band hits for IDs round 4 reuses |
|---|---|
| `scripts/quick-health-check.sh` | `WR-01` **7**, `WR-02` **1**, `WR-03` **5**, `WR-05` **2** |
| `scripts/phase06-oracle.sh` | `WR-01` **4**, `WR-02` **2**, `WR-06` **6** |
| `scripts/check-beets-config.sh` | `WR-04` **2**, `IN-01` **1**, `IN-03` **1** |
| `scripts/phase06-incremental-control.sh` | `IN-02` **1** |

None of those hits has anything to do with round 4. `WR-01` in `quick-health-check.sh` is the 2026-09-14
`extended.conf` destructive-switches finding; `WR-06` in `phase06-oracle.sh` is the CONF-04 write-side
report finding. **The whole-namespace figure, at the review's own `diff_base` `fff070a` so the
round-4 edits cannot inflate it:** `/usr/bin/grep -coE 'WR-0[1-9]|IN-0[1-9]'` returns **35 / 28 / 5 / 4**
across `quick-health-check.sh`, `phase06-oracle.sh`, `check-beets-config.sh` and
`phase06-incremental-control.sh` — **72** pre-existing citations in the round-1 namespace across the
four files round 4 reviewed.

**Recipe, so this is re-derivable rather than pinned** (the raw counts above move with every comment
that names an ID — this file's own subject matter):

```sh
for f in scripts/quick-health-check.sh scripts/phase06-oracle.sh \
         scripts/phase06-incremental-control.sh scripts/check-beets-config.sh; do
  printf '%s: ' "$f"; /usr/bin/grep -coE 'WR-0[1-9]|IN-0[1-9]' "$f"
done
```

**Without this table, half of round 4's record is unresolvable.** A future reader greps `WR-02` in
`phase06-oracle.sh`, finds two hits about empty manifests, and concludes round 4's oracle finding was
never recorded — or worse, attributes round 1's text to round 4. The four fix plans therefore wrote
**`R4-01 … R4-10`** in band and in every verify block, and each plan's summary carries its own slice
of this table.

### The naming rule this establishes

**A review's ID namespace must be unique per round, and must be chosen before the review is
written.** These IDs become permanent in-band citations in the reviewed files. A namespace collision
makes every grep for a finding non-discriminating **in exactly the files where it matters most** —
the ones that carry the citation. Round 3 got this right by using `R3-*`; round 4's report did not,
and the cost was paid four times over in aliasing work across four plans.

**For a round 5, if there is one: give it a fresh namespace (`R5-*`) up front, not an alias
afterwards.** Carried as `DEF-06-39-01`.

---

## Counts

**Findings, as the review's own frontmatter records them:**

| class | count |
|---|---|
| critical | **0** |
| warning | **6** |
| info | **4** |
| **total** | **10** |

**Dispositions, by class:**

| disposition | count |
|---|---|
| FIXED | **9** |
| FIXED (undriven) | **1** |
| ACCEPTED | **0** |
| CARRIED | **0** |

**Fix-kind, by class — this column survives from round 3, and round 4 needed it just as badly:**

| fix kind | count | which |
|---|---|---|
| CODE | **3** | R4-03, R4-06, R4-09 |
| CLAIM CORRECTION | **3** | R4-05, R4-08, R4-10 |
| BOTH | **4** | R4-01, R4-02, R4-04, R4-07 |

**Reconciliation, stated so an arithmetic slip is visible rather than latent:** the review's
frontmatter 0 + **6 Warning** + **4 Info** = **10**; the dispositions 9 + 1 + 0 + 0 = **10**; the fix
kinds 3 + 3 + 4 = **10**. Three routes, one total.

**On the planning expectation.** Plan 06-39 carried a cross-check figure of *roughly* 3 CODE /
3 CLAIM CORRECTION / 4 BOTH, to be overridden by the summaries if they disagreed. **They did not
disagree** — the distribution read off `06-35-SUMMARY.md`, `06-36-SUMMARY.md`, `06-37-SUMMARY.md` and
`06-38-SUMMARY.md` is exactly 3 / 3 / 4. The figures above are the summaries', not the plan's; the
agreement is recorded rather than the plan's number being reused.

**The one row that needed a judgement call, stated rather than smoothed:** `06-37-SUMMARY.md` asks
for R4-04 to be carried as *"FIXED — code half undriven"*. That is not one of the four permitted
words. It is recorded here as **FIXED (undriven)**, which is the closed vocabulary's name for exactly
that condition and the same disposition R3-09 — this finding's direct ancestor — carried in round 3's
register. The nuance is preserved in full in the row itself: the handler *shape* was driven locally
under `/bin/dash` in both directions with a positive control; the *delivery* of SIGPIPE by the
container transport was not observed and is graded BELIEVED.

**`ACCEPTED` and `CARRIED` are zero, and — as in rounds 2 and 3 — that is not a claim that nothing is
outstanding.** No round-4 finding was judged not worth changing and none was deferred instead of
fixed; every one of the ten has a commit. What *is* outstanding is residue attached to rows that are
themselves FIXED, plus **the round's refusals**, and all of it is carried by name in
`deferred-items.md` as `DEF-06-39-01` … `DEF-06-39-06`. Reading these zeros as "nothing left to do"
would be the inversion this register exists to prevent.

## The vocabulary, which is closed

Exactly four words, unchanged from `06-DISPOSITIONS.md`, `06-DISPOSITIONS-GAP.md` and
`06-DISPOSITIONS-GAP2.md`. No fifth word was invented.

- **FIXED** — a commit changed the behaviour **and** the changed branch was driven. Cites the plan,
  the commit and the artifact holding the driven transcript. A drive over a **synthetic fixture**
  counts as driven; the row names the fixture. For a change with no runtime branch (a comment, a
  claim in prose) the file's own committed state is the observation, and the row says so.
- **FIXED (undriven)** — a commit changed the behaviour but the branch was **never observed firing**
  in this phase. Cites the plan, the commit, the artifact **and** the condition that would drive it.
  One row: **R4-04**.
- **ACCEPTED** — deliberately not changed. Unused in this register.
- **CARRIED** — deferred by name to a `DEF-` entry or a ROADMAP entry criterion that exists. Unused
  in this register as a *disposition*; residue and refusals attached to FIXED rows are carried
  separately in `deferred-items.md`.

### Fix kinds, also closed

- **CODE** — the executable behaviour changed.
- **CLAIM CORRECTION** — no executable behaviour changed; an in-band claim was narrowed or withdrawn
  to match what the code already did. Round 4's claim corrections proved this mechanically rather
  than asserting it: **0 non-comment lines** in the diff, and byte-identical `--self-test` output
  across it.
- **BOTH** — code widened *and* a claim corrected, because neither half alone closes the finding.

---

## The register — all 10 findings, in ID order

### Warnings

| Review ID / in-band ID | Defect, in one clause | Disposition | Fix kind | Confirmed by (provenance) | Evidence |
|---|---|---|---|---|---|
| **WR-01** / **R4-01** | The ⛔ paragraph in `quick-health-check.sh` forbids hand-escaping quotes inside a remote command string, and R3-01 appended to it, in the same hunk, that the class was closed. **Four live instances of the identical shape sit eight to eleven lines *below* the prohibition** (`:1535-1538`), interpolating the env-overridable `DRIFT_APPDATA_ROOT` into `_drift_pair` call sites. A value containing `"` terminates the wrapper and the remote shell re-parses the remainder as command text | **FIXED** | **BOTH** | **Verified by read + grep; not executed** — the review says so of itself, and plan 06-35 executed `quick-health-check.sh` zero times either. The injection consequence is **static reasoning on both sides**. The *rendering* was then proven by **capture**: the command string that would be sent was generated with `echo`, never sent, and re-parsed locally with `set --`, which is the same word splitting the remote bash performs | Plan **06-35**, commit `0f4a73a`, artifact `artifacts/06-35-qhc-drift-quoting-and-census.txt`. **Both halves, because neither alone closes it.** Four per-pair renderings (`DRIFT_AUDIO_Q`, `DRIFT_SABBEETS_Q`, `DRIFT_SURVIVOR_Q`, `DRIFT_FLASK_Q`), each rendering the **whole concatenated path** rather than the root with a suffix bolted on outside the escaping — the one way this fix ships broken while looking right. The four call sites interpolate the rendered form **unquoted**, because `_drift_pair`'s body already quotes `"$3"`. Round 3's closure sentence is **withdrawn** and replaced by a record of where the four survivors were, **paraphrased rather than quoted**, so a mechanical grep can prove the false clause absent (06-28's lesson, applied on purpose). Capture matrix: the quote-bearing value `/mnt/fast/app"data` went from **argc 2 / `$3` EMPTY** to **argc 4 / full path, quote intact**; the default value is byte-identical either way. **The bound is carried over intact and not inflated:** this could never produce a green tick — a non-default `DRIFT_APPDATA_ROOT` already forces `EXIT_CODE=1` at the override guard, a broken remote command lands in the could-not-look arm, and the operator who sets the knob already has root on the LXC. **The defect is the claim, not the exploit** |
| **WR-02** / **R4-02** | R3-02's new `ST_PLANNED_CASES=134` gate — **round 3's centrepiece fix** — is a fixed constant compared with `-ne` against a self-test carrying three *documented* environment-conditional skips (root skips 1+4, no `python3` skips 2). Without `python3` the self-test exits 1 announcing **"A SECTION DID NOT RUN"** when every section ran; as root the figure is 129, same false message. **A false red with a wrong stated cause** — the fix made the instrument less trustworthy than it found it | **FIXED** | **BOTH** | **Confirmed independently by the orchestrator, and by execution on both sides.** The review drove it (estate-free `--self-test` only) and got `132 case(s) ran but 134 were announced`. Plan 06-36 reproduced all four before-states against its own base commit `24d6624` — this workstation rc=0/134, `python3` absent rc=1/132, root rc=1/129, `self_test_fences` dropped rc=1/111 — **the same message for two deliberate skips and one genuinely dropped section** | Plan **06-36**, commit `ef8181f` (run **last**, so the count had stopped moving), artifact `artifacts/06-36-oracle-pin-parser-and-cleanup.txt`. **CODE:** each of the three environment-conditional arms now decrements `ST_PLANNED_CASES` **beside the `warn` that reports its skip**, so a deliberate skip adjusts the announcement at the site where the condition is decided and a dropped section — which adjusts nothing — still fires the gate. **CLAIM:** the base was **re-measured by ablation** (not counted by eye — `st_mc`, `st_assert` and `st_grep_why` all funnel into `st_case`) to **140**, with per-arm deltas **1 / 2 / 4** proven additive; and the gate now names three causes it cannot distinguish and rules out the deliberate skip. **The reference environment is named in band beside the constant**: macOS 27.0 (darwin), **non-root (uid 501)**, **`python3` PRESENT**, bash, BSD grep, BWK awk. **The non-vacuity control is the drive that matters:** dropping `self_test_fences` still exits 1 (`117` vs 140), and deleting one `st_case` from an unconditional section still exits 1 (`139` vs 140) — had either gone green the skip-awareness would have disabled the guard it replaced. **⚠ Correction to the source material, see § Corrections item 1: 134 was already stale.** The re-measured base is **140** |
| **WR-03** / **R4-03** | Both new `INT TERM HUP` handlers in `phase06-incremental-control.sh` (`:503-505`, `:563-565`) carry no `exit` and no re-raise. POSIX runs a trapped signal's action and then **resumes** the shell, so round 3's widening converted "terminate" into "delete the scratch directory, keep going, and exit 0". Two reachable paths produce a **normal-looking transcript over an interrupted run**: `MANIFEST OK` after the last manifest write, and the taghistory program file removed between its write and its execution. The in-band claim names only the SIGKILL residual | **FIXED** | **CODE** | **Confirmed by execution on both sides, and independently re-verified by the orchestrator against the code.** The review drove the pre-fix shape under `/bin/dash` — the same interpreter family the container runs — and got `STILL RUNNING AFTER SIGNAL … exit=0`. Plan 06-37 drove both shapes, both program families, both directions, with a **delivery witness** and a **positive control**. No estate contact on either side | Plan **06-37**, commit `65c8cca`, artifact `artifacts/06-37-incremental-terminal-traps.txt`. Both programs now carry a **named cleanup function** (`_p6_mf_clean`, `_p6_th_clean`), a separate `EXIT` trap, and four handlers that clean, `trap - SIG`, then `kill -SIG $$`, so the program dies from the signal it was sent and the caller's rc says so. Drive matrix under `/bin/dash` (identified by path and sha256 `5a09397855d4…`, since it carries no version string): pre-fix TERM/INT/HUP → **wait status 0, ran past the signal, terminal line printed**; post-fix TERM → **143**, INT → **130**, HUP → **129**, none ran past the signal. **`EXIT` is kept separate and marked must-not-fold-in**: on a shell that runs EXIT traps on signal death the cleanup runs twice, which is harmless and is said so in band, so nobody "optimises" it away and re-opens the common normal-termination case. **R3-10's predicate was moved into the cleanup function byte-identical** — proven by diffing the extracted text with a second whitespace-sensitive comparison showing something really did move — because round 4 certified that predicate correct and it was not to be re-derived, tightened or simplified |
| **WR-04** / **R4-04** | R3-09's comment names `timeout` delivering SIGTERM to the in-container `sh -s` as a **routine** outcome. `timeout` signals the `docker exec` **client on LXC 100**; `docker exec` is not known to forward signals inward. If that holds, the added `TERM` never fires for these programs at all. What *does* happen is the exec's stdout stream closes and the in-container shell takes `EPIPE`/`SIGPIPE` on its next write — and a shell killed by an **untrapped** SIGPIPE runs no trap at all. `PIPE` was not in the new list | **FIXED (undriven)** | **BOTH** | **Reasoned statically on BOTH sides, and the row is labelled so rather than flattened.** The review says of itself *"Reasoned statically. Not executed; deliberately, per the no-estate-contact constraint."* Plan 06-37 did not upgrade that grade: the SIGPIPE mechanism is recorded in band as **BELIEVED at the same static grade as the SIGTERM claim it replaces — explicitly not an upgrade over it**. The handler *shape* was driven; the *delivery* was not | Plan **06-37**, commits `65c8cca` (code) and `368322e` (claim), artifact `artifacts/06-37-incremental-terminal-traps.txt`. **CODE:** `PIPE` joins the list, closing the leak that survives even where the `TERM` arm is inert. Driven under `/bin/dash`: pre-fix PIPE → wait status 141 with the **scratch directory PRESENT (the leak)**; post-fix PIPE → 141 with the scratch **gone**. **CLAIM:** the sentence *"so a bound expiry is a ROUTINE outcome for a manifest over a large tree"* is **withdrawn**, and the paragraph now grades three claims by name — **ESTABLISHED** (the transport, grep-confirmable at `remote_exec`; POSIX's exit-trap rule), **NOT ESTABLISHED** (that `timeout` delivers SIGTERM to the in-container shell — untested, and *why*: this phase makes no estate contact), **BELIEVED at the same static grade** (stream close → SIGPIPE). Round 3's "widening SHRINKS the window" is also corrected: the signal was **absorbed**, not narrowed. **Why this row is `FIXED (undriven)` and R4-03 is not:** R4-03's defect and fix are both about the handler shape, which was driven; R4-04's is about which signal the container transport actually delivers, which nobody has observed. **Condition that would drive it:** a live `--arm a` / `--arm b` pair under a deliberately short `REMOTE_TIMEOUT`, checking the container's `/tmp` for surviving `/tmp/p6-mf.*` and `/tmp/p6-taghist.*` names — attaches to the **existing** Phase 7 entry criterion **E12**; `DEF-06-39-04`, `DEF-06-34-06` |
| **WR-05** / **R4-05** | The hunk in `check-beets-config.sh:433-436` whose subject is *"a number written into a file that greps itself is moved by the sentence that states it"* states, present-tense, that the raw count "is 4". It is **5** — it was 4 at `fff070a`, and the recipe line **the same hunk added** made it 5. The hedge "and rises with prose like this" is not a fix; the hunk that wrote the hedge is what rose it. **The self-referential measurement error, recurring inside the fix for it** | **FIXED** | **CLAIM CORRECTION** | **Verified by grep** — the review ran `/usr/bin/grep -c` at HEAD (5) and at `fff070a` (4); the orchestrator independently re-verified. Plan 06-38 re-measured **after the edit landed**, not before: verifying a census only against the pre-edit tree is the precise mistake this finding records | Plan **06-38**, commit `b5831b2`, artifact `artifacts/06-38-checker-count-audit.txt`. **The figure was DELETED, not corrected to a new number** — re-pinning would have set up the fourth drift, arriving with the next comment naming the symbol. The replacement states the raw count is **deliberately not pinned** with the reason in one clause, cites the sibling precedent (R3-05 in `quick-health-check.sh`, same round, which took the same decision) and `06-DISPOSITIONS-GAP2.md` § Corrections item 1 for the three-ref measurement rather than re-deriving numbers in band, **paraphrases** the retired construction instead of pasting it, and **contains no raw figure anywhere, including in the sentence disowning it**. The comment-stripped census (`The answer is 2`) was correct and was left exactly as it stood. **Proven comment-only, with the vacuity guard first:** the diff is non-empty (`grep -c '^[+-][^+-]'` ≥ 1), the same diff filtered for non-comment lines is **0**, and `--self-test` output is **byte-identical** across the edit (`cmp` rc 0) — with the determinism of that comparison established first by running `--self-test` twice against the *unedited* tree, without which a `cmp` rc 0 proves nothing. **Zero executable lines changed across the whole plan** |
| **WR-06** / **R4-06** | R3-03's new whitespace-tolerant sha256 line parser guards the layer-3 `-l` assertion — *"the one assertion whose whole job is to prove `-l` kept the real library.db closed"* — and **has no case in the 134-case set R3-02 pinned in the same round**. A future edit to the regex, the two-space separator or the `print $1` field index goes green. R3-03's own house rule: *"an undriveable branch is an unproven branch"* | **FIXED** | **CODE** | **Verified by grep** — the review checked `self_test_core` / `self_test_classes` / `self_test_vacuity` / `self_test_fences` and found no case driving `sub(/^[0-9a-f]+  /…)` or either `*_SHA_*` assignment. The fix was then **driven to FAIL on four scratch mutants**, which is the property the finding asks for | Plan **06-36**, commit `5c7eac6`, artifact `artifacts/06-36-oracle-pin-parser-and-cleanup.txt`. Six `st_case` assertions in `self_test_vacuity` over **one non-empty fixture**, so every refusal is a refusal over a file whose other lines the positives matched: a **space**-bearing path matched exactly (the case R3-03 exists for); a **backslash**-bearing path matched exactly (R4-09 driven); a **GNU backslash-escaped** line refused (R3-03's deliberate refusal, now pinned as intended); a **suffix-only near-miss** refused (exact equality, never a suffix test); a **truncated** line refused; and an **identity case** asserting that exactly 4 lines of the script carry both the driven program text and the live-only `"$OUT/layer3.` marker. **The identity case counts on the live-only marker as well as the program text, deliberately** — the self-test's own copy is in the same file, so a bare count would have been self-referential and would have moved the moment the block was added, which is the GC-10 / R3-05 / R4-05 defect exactly. It resolves the script path **fail-closed**: unreadable prints a `warn`/`info` pair and is driven RED with `COULD-NOT-LOOK`, never a silent pass. **Driven to FAIL:** mutating one live consumer's field index, its two-space separator, or its hex class each takes the identity case 4 → 3 and prints `SELF-TEST REGRESSION` — the exact three edits the review said currently go green. The four live copies were **not** hoisted into one shared variable, per `DEF-06-29-03` |

### Info

| Review ID / in-band ID | Defect, in one clause | Disposition | Fix kind | Confirmed by (provenance) | Evidence |
|---|---|---|---|---|---|
| **IN-01** / **R4-07** | `DASH_RESOLVE_IP` (`quick-health-check.sh:1354`) reaches a remote `curl --resolve` command string raw. The R3-01 census recipe sets the criterion as *"for each knob that reaches a remote command string, check that only its `_Q` form is interpolated"* — broader than "path" — and this knob meets it and is un-rendered. Harmless today (override-guarded, and a split word makes `curl` fail loudly); listed because running the file's own stated recipe as written surfaces a site no plan owns | **FIXED** | **BOTH** | **Verified by grep; not executed.** `quick-health-check.sh` was run zero times by the review and zero times by plan 06-35. The rendering was proven by the same **capture** method as R4-01 | Plan **06-35**, commit `0f4a73a`, artifact `artifacts/06-35-qhc-drift-quoting-and-census.txt`. `DASH_RESOLVE_IP_Q` rendered beside its knob definition and swapped into the `curl --resolve` remote string **only** — the override comparison and the operator `echo` keep the raw value, because rendering those would print backslashes at a human. The census gained the knob, so running the recipe no longer surfaces an unowned site. **BOTH**, not CODE alone: the code was rendered *and* the census that failed to list it was corrected |
| **IN-02** / **R4-08** | The census recipe's second grep (`:1490-1491`) is `/usr/bin/grep -n 'ssh -n \$SSH_OPTS'`, which misses `:1070` and `:1092` — both `bounded_ssh "$PROBE_TIMEOUT" ssh $SSH_OPTS root@…`, with no `-n`. Neither interpolates a knob today, so nothing is wrong now; but **a recipe offered as the durable replacement for a wrong number under-counts its own haystack by two** | **FIXED** | **CLAIM CORRECTION** | **Verified by grep on both sides.** Nothing executable was involved — **by design**. The bound here is stronger than R4-07's: *neither newly-covered call site interpolates a knob today. Nothing in the file was wrong; the recipe was* | Plan **06-35**, commit `8799e02`, artifact `artifacts/06-35-qhc-drift-quoting-and-census.txt`. The recipe's second grep widened from `ssh -n \$SSH_OPTS` to `ssh (-n )?\$SSH_OPTS` (`-E`). **18 hits before, 20 after; the two new hits are exactly the `bounded_ssh` probes the review named.** Nothing executable changed. **⚠ The instructive part is a deviation, recorded in § Corrections item 2:** the first draft of the in-band explanation **quoted the two newly-covered call sites verbatim**, so the widened recipe matched its own documentation — caught by the plan's own self-non-matching check, rewritten in prose, re-run at 20 hits with **zero comment lines among them**, and the warning is now carried in band |
| **IN-03** / **R4-09** | `awk -v p="$REAL_LIB_DB"` (`phase06-oracle.sh:2754-2755`, `:2915-2916`) applies awk's escape processing to an env-overridable knob, so a backslash-bearing path is mangled before the `rest == p` comparison. It fails closed (empty → `unknown` → `exit 3`), so this is a residual rather than a contradiction | **FIXED** | **CODE** | The review states its own basis: **"Reasoned statically."** The fix was then **driven both directions** on the backslash case | Plan **06-36**, commit `fa6204a`, artifact `artifacts/06-36-oracle-pin-parser-and-cleanup.txt` § 1 probe 7: under `ENVIRON` the backslash-bearing path matches; under the old `-v` form it does not. All four layer-3 consumers changed to `LC_ALL=C p="$REAL_LIB_DB" awk '… rest == ENVIRON["p"] …'` — **all four, for R3-03's own reason: four consumers of one output format must not carry two parsers.** Bounded in band rather than inflated: the old form already failed closed, so this buys correctness for a backslash-bearing knob, **not a new safety property**. R3-03's deliberate refusal of GNU `sha256sum`'s escaped *output* form is untouched — `ENVIRON` changes how the **requested** path arrives, not how the **printed** line is read |
| **IN-04** / **R4-10** | R3-04's two new `exit 3` arms (`phase06-oracle.sh:2927-2928`) skip step 12's `rm -rf` (container scratch) and `rm -f` (LXC stamp). A **pre-existing class** — two `exit 3` arms two lines above already do this — and leaving state behind on a could-not-look is arguably right for a forensic instrument. Recorded because R3-04 increased the count of such exits and the gap is nowhere stated in band | **FIXED** | **CLAIM CORRECTION** | **Verified by read**; the review confirmed by grep that **no `trap` exists anywhere in `phase06-oracle.sh`**. Plan 06-36 did not execute the arms either — that the scratch and stamp survive is **reasoned from step 12 being below them in a straight-line script with no trap**, verified by grep, not by an interrupted live run | Plan **06-36**, commit `fa6204a`, artifact `artifacts/06-36-oracle-pin-parser-and-cleanup.txt`. An in-band note at the two guards, **graded as the review graded it**: the class is pre-existing and shared with the two arms above; the two leftovers are named (`$SCRATCH`, `$STAMP_REMOTE`); and the operator clean-up command is **cited by anchor** — the step-1 precheck's `'nonempty '*` refusal arm — rather than duplicated, because two copies of a destructive command line in one file is how GC-02's fences drifted apart in this very file. **NO TRAP WAS ADDED, and that is a deliberate refusal, not an omission** — `grep -c '^[[:space:]]*trap '` on `phase06-oracle.sh` is still **0**. Carried as `DEF-06-39-02` |

---

## What was driven and what was not — the summary this register must not flatten

Ten `FIXED`s with no distinction would be precisely the over-claim the review is about. Stated per
surface:

1. **`scripts/quick-health-check.sh` was executed ZERO times — by the review and by plan 06-35.** It
   contacts LXC 100 (172.16.1.159) and atlantis (172.16.1.158), and this phase makes no estate
   contact. **Every R4-01 and R4-07 assertion is a capture (`echo`, never sent) or a grep.** The
   capture is a faithful model of the remote word splitting — bash on both ends — but it is a model:
   it shows `_drift_pair` receives the right argument; it does not show the remote function then
   behaves as expected. R4-08 has no runtime branch to drive. Named rather than left as a silence,
   the file's undriven surfaces include the vendored-drift block's match / drift / short-answer /
   could-not-look branches and its remote exit-3/4/5 arms, both override guards firing at runtime,
   the dashboard probe's 124 / 255 / curl-non-zero / 302 / 401 / 200 arms, and `bounded_ssh`'s
   watchdog and sentinel paths. `DEF-06-39-05`.
2. **The oracle's layer-3 block remains reachable only from a live `--run`.** R4-06's six new cases
   prove **the parser** over synthetic `sha256sum` output; they do **not** prove the block, the remote
   `sha256sum` invocation, `dex_cmd`'s rendering, or that the container's `sha256sum` prints the
   `<hash><SP><SP><path>` form these fixtures assume. This is the same residue **`DEF-06-34-04`**
   already owns; round 4 adds no duplicate entry for it.
3. **The container-side signal behaviour is still UNOBSERVED inside `beets-flask` — both paths.** The
   `timeout` → SIGTERM → in-container-shell path is graded **NOT ESTABLISHED**; the stream-teardown →
   SIGPIPE path is graded **BELIEVED at the same static grade, explicitly not an upgrade**. The local
   `dash` drive proves the **handler shape**, not the **delivery**: it shows that *if* a signal
   arrives, the pre-fix shape absorbs it and the post-fix shape dies from it, and says nothing about
   which signal the container transport actually delivers. `SIGKILL` remains an **unclosable
   residual** — **`DEF-06-34-06`** already owns that half. `DEF-06-39-04`.
4. **Three findings closed with zero executable change** (R4-05, R4-08, R4-10), and one of them proved
   it mechanically rather than asserting it: plan 06-38's whole-plan non-comment changed-line count in
   `check-beets-config.sh` is **0**, with `--self-test` output byte-identical to the pre-plan baseline
   (`cmp` rc 0) — and the determinism of that comparison established first with a double run against
   the *unedited* tree.
5. **The root and `python3`-absent conditions were ABLATED, not genuinely entered.** R4-02's root
   drives force the `[ "$(id -u)" = "0" ]` test on scratch copies; nothing ran as uid 0. The
   `command -v python3` test was ablated, not the interpreter removed. Proven: the skip branch
   self-adjusts. **Not proven:** that a real root run has no other behavioural difference.
   `DEF-06-39-03`.
6. **A fourth environment-conditional skip would not be detected.** If one is added and its author
   forgets the decrement, the gate fires with the corrected three-cause message — which points at the
   right question — but nothing detects the omission itself. The verify's `-ge 3` is a **floor, not a
   census**. `DEF-06-39-03`.
7. **What *was* executed, and is worth naming because it is the smaller half:** the R4-02 before-state
   matrix at base commit `24d6624` (four conditions) and the two non-vacuity controls after; the
   R4-06 six-case fixture plus four scratch mutants driven to FAIL; the R4-09 `ENVIRON`-vs-`-v`
   probe; the full R4-03/R4-04 `dash` signal matrix across two program families in both directions,
   with a delivery witness and a positive control; `sh -n` and `dash -n` over both extracted heredoc
   bodies; `bash -n` on all four scripts; and all three `--self-test` runs at HEAD.

**Instruments re-measured at HEAD by this plan, not carried forward from any plan's text:**
`phase06-oracle.sh --self-test` exit **0** at **140** cases; `check-beets-config.sh --self-test` exit
**0** at **7** cases (6 of them red); `phase06-incremental-control.sh --self-test` exit **0**;
`bash -n` clean on **all four** scripts; and `sh -n` **and** `/bin/dash -n` clean on **both extracted
in-container programs** — the gate `bash -n` cannot give, since it parses heredocs as data.

---

## Verified-and-clean — **round 4's own list, and a round 5 must not re-litigate these**

`06-REVIEW-GAP3.md` closes with a *What I checked and found clean* section. It records places a
reviewer would expect a defect given this codebase's history, checked adversarially and found
**correct as written**. They are reproduced here as a **named, closed list**: a round-5 review should
**cite this register** for them rather than re-deriving them, and a finding that merely restates one
of these is **not a new finding**.

1. **R3-10's predicate, both sites.** `""`, `/tmp/p6-mf.`, `/tmp/p6-mf.a/../../../home` and a real
   `mktemp` name all behave as round 3's artifact claims. The class `[A-Za-z0-9._-]` excludes `/`;
   the empty remainder is caught by the first `case` arm. Driven locally by the reviewer, no `rm`
   executed.
2. **Every other destructive site in `phase06-incremental-control.sh`.** `:424`, `:447`, `:612`,
   `:1018`, `:1031` act on `ARM_A_ROOT` / `ARM_B_ROOT`, which are **plain constants** at `:151-152`,
   not `${VAR:-default}` knobs. `:612` additionally re-fences against a literal allow-list.
3. **Both heredoc bodies parse clean.** Extracted `write_prog_manifest` and `write_prog_taghistory`
   and ran both under `/bin/sh -n` and `dash -n`.
4. **The five new `_Q` consumption sites are remote WORDS** — the one context `printf '%q'` is
   correct for: `D03_FLASK_CONTAINER_Q`, `D03_CLI_PROFILE_Q` + `D03_CLI_COMPOSE_Q`, and
   `MUSIC_UNDERSCORE_ROOT_Q` at two sites.
5. **`EXTCONF_PATH_Q` reaches the inner `sh -c` as a positional parameter**, with the literal `sh`
   supplied as `$0`; the program text names no path. That is the right shape.
6. **No new pipeline was introduced** in any of the four files by round 3's diff. `grep -qF` in
   `check-beets-config.sh` still reads from here-strings (GC-01 intact).
7. **`ST_PLANNED_CASES=7` in `check-beets-config.sh` is unconditional** — six `run_case` calls plus
   the manual case 6. `--self-test` exits 0. Case 7's `bytes7 > 65536` precondition still holds.
8. **R3-08's refusal of a third conjunct is correctly reasoned.** With both conjuncts true,
   `ARM1_FAILS` is necessarily 1, so the conjunct could never independently fail.
9. **R3-06's narrowed sentence is accurate.** Three cases each test `case "$X" in *"rm "*)`, and
   nothing below tests for `touch` or for redirection.
10. **The claims verified TRUE by grep:** the `EXIT-CODE BEHAVIOUR CHANGE[D]` header count really is
    13 at both `fff070a` and HEAD; the bracketed recipe lines are genuinely not self-matching; the
    comment-stripped `assert_beet_invocation_contract` census really is 2; `library.db CHANGED`
    returns exactly one hit; all four layer-3 awk consumers were converted with no `$2 == p`
    surviving; all nine `_Q`-rendered knobs have an override guard forcing `EXIT_CODE=1`.

### The two items round 4 changed, so the list does not go stale on arrival

**Item 1 — R3-10's predicate — was verified clean by the review AND then moved by plan 06-37.** It
now lives inside a named cleanup function (`_p6_mf_clean` / `_p6_th_clean`) rather than inline in the
trap body. **The move was proven verbatim:** 06-37 diffed the extracted predicate text
indentation-normalised and found it byte-identical, with a second whitespace-sensitive comparison
showing something really did move. The single-quote constraint that shaped the empty pattern (`""`
rather than `''`) no longer binds now that the predicate lives in a function, and it was still left
**byte-identical anyway**, because changing it would be a gratuitous edit to the one fence round 4
certified — and `dash` treats the two patterns identically. **Item 1 remains clean, at the same
predicate, at a new site.**

**Item 7 — `ST_PLANNED_CASES=7` — was verified unconditional by the review and was then EXCLUDED BY
NAME from plan 06-38's count audit.** It was not touched. It is a gated pin over an unconditionally
executed set, not a prose claim, and it is the one number in that file that is supposed to be a
number; "fixing" it would have broken a working guard. Recorded as a refusal, `DEF-06-39-02`.

Every other item on the list is untouched by round 4.

---

## Corrections to the source material

A register that only repeats its source would lose these. Round 2 recorded three, round 3 one; round
4 has three, one of which is a defect in the review's **form** rather than in its findings.

### 1. `ST_PLANNED_CASES` was already stale at 134 before round 4 touched it — the re-measured base is **140**

`06-REVIEW-GAP3.md` § WR-02 reasons throughout from **134**, and so do the 06-36 plan,
`06-DISPOSITIONS-GAP2.md` and `06-REVIEW-GAP2.md`'s wiring. **Plan 06-36 re-measured the base by
ablation and got 140** — 134 plus the six cases R4-06 added in the same round, task 2 running before
task 3 precisely so the count had stopped moving when it was pinned.

**The finding's conclusion is correct and entirely unaffected**: a fixed constant compared with `-ne`
against a set with environment-conditional members is not an invariant, whatever the constant is.
Only the number moved. It is recorded here — and in band in `06-REVIEW-GAP3.md`'s wiring block — the
way round 2 recorded the GC-15/GC-17 label crossing and round 3 recorded R3-07's census: **as a
correction in band, not a silent fix and not a downgrade of the finding.** A verification that pinned
the review's number would have failed on arrival.

**The three documents recording 134 are now stale on that figure** and were deliberately **not**
edited: `06-REVIEW-GAP2.md` and `06-DISPOSITIONS-GAP2.md` are dated records of round 3, and
`06-REVIEW-GAP3.md` is a dated record of round 4. The live figure is in the script, beside the
constant, with its reference environment named.

**The general form, which is the part worth keeping:** *a pin over a set with
environment-conditional members must adjust where the condition is decided, or it is a constant
pretending to be an invariant.*

### 2. The ID namespace collision is a defect in the review's FORM, recorded in band rather than fixed silently

Round 4's report reuses round 1's `WR-*` / `IN-*` namespace — see the mapping table above, with the
measured collision counts. This is **not** a downgrade of any finding: all ten stand exactly as
written. It is a form defect with a real cost, paid four times over as every fix plan had to build
and carry its own alias table, and it would have been paid again by every future reader following a
citation. Recorded the way round 2 recorded the GC-15/GC-17 label crossing. The rule it establishes
is stated under the mapping table and carried as `DEF-06-39-01`.

### 3. Two self-referential-measurement instances fired **during** round 4's execution, in the plans closing that very class

Neither was caught by an assertion. Both were caught by **measuring after the edit landed**, which is
the only method that works here.

- **Plan 06-35, task 2.** The first draft of the in-band explanation of the widened census recipe
  **quoted the two newly-covered call sites verbatim** in order to describe them. That paragraph then
  matched the widened pattern, and the plan's own self-non-matching check returned it as a
  comment-line hit — the recipe counting its own documentation. Rewritten in prose; re-run returns 20
  hits, **zero of them comment lines**. The in-band text now carries the warning.
- **Plan 06-38, its own artifact.** The artifact pinned a raw `ST_PLANNED_CASES`-related count at 4
  (wrong when written — it was 6), corrected it to 6, and then **task 2's own audit-pointer comment
  moved it again**; withdrawn at row 3 rather than corrected a third time. A separate figure in the
  same artifact was pinned at 18 and measured 22. Logged by that plan as `F-06-38-02`.

**Plus one finding about the verify blocks themselves, which nothing in the round's brief was looking
for.** Plan 06-38's own task-2 `<automated>` block asserted a **raw** `grep -cF '| grep -q'` count of
**0** against `check-beets-config.sh`. It answers **2** at the plan's base commit and 2 after — the
two hits being **comments quoting the retired construction to explain the phase's only BLOCKER**. The
assertion could never have passed, and satisfying it would have required deleting that
documentation. Substituted with the comment-stripped form, which measures 0 at base and 0 now and
still fails loudly on a real executable regression. **No code was changed to make a test pass**; the
assertion was wrong about the tree and the tree was right. Logged by that plan as `F-06-38-01` and
carried here as `DEF-06-39-06`: **this round closed raw self-referential counts in the scripts while
the blocks checking them carried the same defect.**

---

## What this register does NOT do

**It changes no verdict, and it does not re-verify the phase.** No `/gsd-verify` run was performed by
plan 06-39 and **no verification result is claimed here**.

- **CONF-04 is NOT closed.** `REQUIREMENTS.md` is untouched by this plan and `- [ ] **CONF-04**`
  stands. Its Jellyfin half is still **OPEN** and ROADMAP entry criterion **E6** still owns the
  discharge. Its two verdicts — Jellyfin pending, Music Assistant discharged — are recorded
  separately and **are never summed**.
- **No requirement checkbox moves** and no phase-status wording is altered. **The phase is not
  declared complete**; that is the verifier's call, on a re-verification this plan does not perform.
- **Rounds 1, 2 and 3's carried items stay carried.** CR-01's residue is owned by Phase 7 entry
  criterion **E10**, WR-09 (round 1's) by **E11**, and the undriven-until-the-pilot residue by
  **E12**. `DEF-06-21-*`, `DEF-06-29-*` and `DEF-06-34-*` are unchanged — none renumbered, reworded
  or removed.
- **It does not re-open what is already owned.** The ~23 remaining `printf … | grep -q` SIGPIPE-141
  sites (`DEF-06-29-01`), the three un-rotated live secrets on LXC 100 (`DEF-06-29-09`), the host
  sitting at a pre-Phase-6 commit (`DEF-06-29-11`), the undriven layer-3 block (`DEF-06-34-04`) and
  the SIGKILL residual (`DEF-06-34-06`) each already have an owner; round 4 adds no duplicate entry
  for any of them.
- **It adds no new Phase 7 entry criterion.** Round 4's residue is small enough to live in
  `DEF-06-39-01` … `DEF-06-39-06`, and the live-run part attaches to the **existing** **E12**.

### And one thing round 3's register did not need to say

**`06-VERIFICATION.md` IS STALE, and it was deliberately not touched.** It records round **1's**
closure, dated **2026-09-22**, with `status: passed` and `gaps_remaining: []` — written **before
rounds 2, 3 and 4 existed**. It is not round 4's gap source and it is not round 4's to correct.

**`/gsd-verify 06` has NOT been run since round 2.** A passing verification sitting beside four
gap-closure rounds is exactly the kind of artifact a future reader closes a phase on, which is why it
is named here, in the ROADMAP disposition paragraph and in STATE.md's Current Position — three
places, because one is where a reader does not look.

---

## Lessons — round 4's own, not round 3's restated

### 1. Zero Critical, and the review said so plainly rather than manufacturing a BLOCKER

Round 4 is the first round whose **headline is the absence of a Critical finding**. The review opens
with it: *"No Critical finding. Stated plainly, because it is a real result: I could not construct a
path from any round-3 change to data loss, to an estate outage, or to a false green on a destructive-
command fence."* The largest finding, R4-02, is a **false red with a wrong stated cause** — the
opposite polarity from the defect class this phase spent three rounds removing.

Round 3 named the exit condition: **a review whose findings are Info-only and whose fixes are claim
corrections.** Round 4 is closer to that than round 3 was — zero Critical, no reproducible false
green, three of ten fixes changing no executable line at all — **and it is not yet there**: six
Warnings, three of them requiring real code, and one finding (R4-03) where round 3's change had made
a program *stop dying* when told to.

### 2. A documented prohibition survived a SECOND consecutive round inside the file documenting it — and the survivors were eleven lines below it

R4-01 is not "a forgotten site three hundred lines away". The four live instances of the ⛔-forbidden
hand-escaped-`\"` shape sit **eight to eleven lines below the prohibition paragraph itself**, inside
the very `DRIFT_CMD` string the paragraph is embedded in, under a sentence added in the same hunk
declaring the class closed.

**The lesson is not "write better prohibitions".** Round 3's prohibition was correct, prominent and
freshly re-endorsed, and it still did not cause the sweep to happen. **A class is not closed until
the sweep is mechanical** — which is exactly why the census in that file is now a **recipe** rather
than a count, and why R4-08 (widening the recipe's own haystack) is a real finding rather than
pedantry: a recipe that under-counts its haystack is a mechanical sweep with a blind spot, which is
worse than an honest manual one.

### 3. Round 3's centrepiece fix was round 4's largest finding

`ST_PLANNED_CASES=134` was round 3's flagship — a pin added on the sound premise that an unpinned set
lets a guard silently stop being exercised. **It made the instrument less trustworthy than it found
it:** a false red, announcing "A SECTION DID NOT RUN" when every section ran, with a wrong stated
cause, firing most readily on the machines **least likely to be the operator's** (a `python3`-less
box, a root shell). The in-band remediation instruction made it worse — an operator re-pinning to 132
would break every box that *has* `python3`.

**The general form, stated so it transfers:** *a pin over a set with environment-conditional members
must adjust where the condition is decided, or it is a constant pretending to be an invariant.* The
fix is not a bigger constant; it is three decrements, each beside the `warn` that reports its own
skip, plus a gate message that names the causes it cannot distinguish. And the base that remains a
typed number is now typed **for a named reference environment**, stated in band beside it.

### 4. Self-referential measurement, for the THIRD consecutive round — and the mitigation is unchanged

GC-10 → R3-05 → R4-05, the last of them **inside the fix for the second**. R4-05's subject is a hunk
whose own thesis is that a number in a self-grepping file is moved by the sentence stating it, and
which then states a number that its own added line had already moved.

**The mitigation is unchanged and is now applied in both sibling files: state a recipe, not a
number.** Round 3 applied it in `quick-health-check.sh` (R3-05: the figure was dropped, not
re-pinned) and did not apply it in `check-beets-config.sh`; round 4 applied it there too, by the same
method — **withdrawal, not re-pinning**, because re-pinning sets up the next drift. Where a number
must appear, bracket the pattern so the recipe is not an occurrence of what it measures
(`EXTRA_FORBIDDEN_SUBSTRINGS:[-]`, `EXIT-CODE BEHAVIOUR CHANGE[D]`), pin the comment-stripped form
rather than the raw one, and **verify the recipe after writing it in band, not before**.

### 5. The hazard has migrated into the verification, and nothing was looking there

Plan 06-38 found that **its own task-2 verify block could never have passed at its own base commit** —
a raw count assertion over a file whose comments legitimately quote the counted token. The defect
class this round closes *in the scripts* was simultaneously present *in the blocks that check them*,
and the round's brief did not cover verify blocks at all.

**Corollary for any future round:** sweep the `<automated>` blocks for raw self-referential counts
before executing, and prefer the comment-stripped recipe or an inequality to a raw equality in any
assertion counting a token in a file that discusses that token. `DEF-06-39-06`.

### 6. A refusal that is not written down reads as an oversight

Round 3 recorded three refusals; round 4 recorded at least three more (no cleanup `trap` on
`phase06-oracle.sh`; `ST_PLANNED_CASES=7` excluded by name; the four live layer-3 copies not hoisted,
per `DEF-06-29-03`). Each is in band at its site **and** in `deferred-items.md` with its reason and
its revisit condition. The alternative is a round 5 spending its budget re-proposing them.

---

_Register written 2026-09-23 by plan 06-39._
_Source: `06-REVIEW-GAP3.md`, reviewed 2026-09-23 against `diff_base` `fff070a` over four scripts,
depth deep; **no cross-family adjudication**._
_Gap closure round 4: plans 06-35, 06-36, 06-37, 06-38, 06-39._
_All measurements in this file answered by `/usr/bin/grep` (BSD grep), by absolute path, not the
operator's zsh `ugrep` alias._
