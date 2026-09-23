# Phase 6 — disposition register for `06-REVIEW-GAP2.md` (gap closure, ROUND 3)

**Written:** 2026-09-23 by plan 06-34 (wave 15).

## Why this file exists

`06-REVIEW-GAP2.md` is a code review of **round 2's own gap-closure changes** — the fixes plans
06-22 through 06-29 wrote to close `06-REVIEW-GAP.md`. It found **0 Critical, 5 Warning and 5 Info
inside those fixes**. Round-3 plans 06-30 through 06-33 supplied the fixes. This file supplies the
part a fix commit cannot: a statement of what happened to **each** of the ten findings, so the set
cannot be lost at the next context boundary.

Round 1's headline lesson, recorded in `06-DISPOSITIONS.md`, is that *a finding recorded where the
next phase does not read is a finding nobody owns*. Round 2 existed because round 1 was declared
closed before anyone read its own diff. Round 3 exists because round 2 was reviewed and found to
have closed several classes **partially** while writing in-band claims that they were closed
**completely**. The recursion stops by recording honestly, not by recording nothing.

It is referenced from `06-REVIEW-GAP2.md`'s appended wiring block and from `.planning/ROADMAP.md`'s
Phase 6 disposition paragraph.

## Source

| | |
|---|---|
| Source review | `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW-GAP2.md` |
| Reviewed | **2026-09-22** (frontmatter `reviewed: 2026-09-22T00:00:00Z`), commit `766b2d0` |
| `diff_base` | **`bf509f46ba12c8536ec98b5c05cb17bb61c30df2`** — i.e. the tree as it stood *before* round 2, so the diff under review is round 2's entire output |
| Depth | standard, scoped to what round 2 changed |
| Files reviewed | **4**: `scripts/check-beets-config.sh`, `scripts/quick-health-check.sh`, `scripts/phase06-oracle.sh`, `scripts/phase06-incremental-control.sh` |
| ID space | `R3-01 … R3-10` (distinct from round 1's `CR-*`/`WR-*`/`IN-*` and round 2's `GC-*`) |
| Adjudication | **NONE. There was no cross-family adjudication in round 3.** See the note below — this is stated rather than left ambiguous |

**The review's own measurement note, carried forward because it bounds every finding below.** Every
grep in the review was run as `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD) **by absolute path**, not the
operator's zsh `grep` → `ugrep` alias. **No script was executed against the estate**: no `--run`, no
`--arm`, no `quick-health-check.sh` invocation. The self-tests were **not re-run** by the reviewer.
Several findings are therefore explicitly *static reasoning about code that was read*, and the rows
below say which.

### On the absent adjudication

Round 2's register records a cross-family adjudication (`gemini-3.1-pro-preview`) that **appended
two findings**, GC-16 and GC-17, taking that round from 15 to 17. **Round 3 had no such
adjudication.** No second model family was asked, nothing was appended, and the ten findings
`R3-01 … R3-10` are the whole set. This is written down because an absent adjudication that is not
mentioned reads exactly like a lost one — and round 2's appended pair were, between them, a real
BLOCKER-graded defect and the finding that R3-01 then landed on. The absence is a fact about round 3,
not a claim that another family would have found nothing.

## Counts

**Findings, as the review's own frontmatter records them:**

| class | count |
|---|---|
| critical | **0** |
| warning | **5** |
| info | **5** |
| **total** | **10** |

**Dispositions, by class:**

| disposition | count |
|---|---|
| FIXED | **9** |
| FIXED (undriven) | **1** |
| ACCEPTED | **0** |
| CARRIED | **0** |

**Fix-kind, by class — this column is the point of this round:**

| fix kind | count | which |
|---|---|---|
| CODE | **4** | R3-02, R3-04, R3-08, R3-09 |
| CLAIM CORRECTION | **3** | R3-05, R3-06, R3-07 |
| BOTH | **3** | R3-01, R3-03, R3-10 |

**Reconciliation, stated so an arithmetic slip is visible rather than latent:**
the review's frontmatter 0 + 5 + 5 = **10**; the dispositions 9 + 1 + 0 + 0 = **10**; the fix kinds
4 + 3 + 3 = **10**. Three routes, one total.

**Why the fix-kind column exists.** The review's central charge is that round 2 closed several
classes partially and then wrote that it had closed them completely. A register of ten
undifferentiated `FIXED` rows would reproduce exactly that ambiguity one level up: it cannot tell a
reader whether a fence was widened or a sentence was narrowed. **For three of these ten findings the
honest fix was to narrow the sentence, and for three more it was both.** That is recorded, not
smoothed over.

**`ACCEPTED` and `CARRIED` are zero, and — as in round 2 — that is not a claim that nothing is
outstanding.** No round-3 finding was judged not worth changing and none was deferred instead of
fixed; every one of the ten has a commit. What *is* outstanding is residue attached to rows that are
themselves FIXED, plus **two deliberate refusals**, and all of it is carried by name in
`deferred-items.md` as `DEF-06-34-01` … `DEF-06-34-06`. Reading these zeros as "nothing left to do"
would be the inversion this register exists to prevent.

## The vocabulary, which is closed

Exactly four words, unchanged from `06-DISPOSITIONS.md` and `06-DISPOSITIONS-GAP.md`. No fifth word
was invented.

- **FIXED** — a commit changed the behaviour **and** the changed branch was driven. Cites the plan,
  the commit and the artifact holding the driven transcript. A drive over a **synthetic fixture**
  counts as driven; the row names the fixture. For a change with no runtime branch (a comment, a
  claim in prose) the file's own committed state is the observation, and the row says so.
- **FIXED (undriven)** — a commit changed the behaviour but the branch was **never observed firing**
  in this phase. Cites the plan, the commit, the artifact **and** the condition that would drive it.
  One row: **R3-09**.
- **ACCEPTED** — deliberately not changed. Unused in this register.
- **CARRIED** — deferred by name to a `DEF-` entry or a ROADMAP entry criterion that exists. Unused
  in this register as a *disposition*; residue and refusals attached to FIXED rows are carried
  separately in `deferred-items.md`.

### Fix kinds, also closed

- **CODE** — the executable behaviour changed.
- **CLAIM CORRECTION** — no executable behaviour changed; an in-band claim was narrowed or withdrawn
  to match what the code already did. Two plans proved this mechanically rather than asserting it:
  **0 non-comment lines** in the diff, and byte-identical program output across it.
- **BOTH** — code widened *and* a claim corrected, because neither half alone closes the finding.

---

## The register — all 10 findings, in ID order

### Warnings

| ID | Defect, in one clause | Disposition | Fix kind | Confirmed by (provenance) | Evidence |
|---|---|---|---|---|---|
| **R3-01** | GC-17's new comment in `quick-health-check.sh` states as measured fact that "There are FOUR such sites in this file"; more survive, and `:2118` (`docker exec sabnzbd sh -c 'cat \"$EXTCONF_PATH\"'`) is the hand-escaped-quote construction the **same comment forbids sixty lines earlier** — on the block that reads the `requireBeetsMatch` guard, the one value standing between `audio.bash` and `rm -rf "$1"/*` | **FIXED** | **BOTH** | **Confirmed independently by the orchestrator.** The review grep-verified the surviving sites by absolute-path `/usr/bin/grep`; it states explicitly that *"the injection consequence in the last paragraph is **static reasoning, not executed**"*, and that bound is preserved here | Plan **06-30**, commit `55a2db3`, artifact `artifacts/06-30-qhc-census-and-counts.txt`. **Both halves, because neither alone closes it.** Five new `printf '%q'` renderings (4 → **9**), each sited beside its knob *definition* rather than its use site — `MUSIC_UNDERSCORE_ROOT` has **two** remote sites and proves why. The EXTCONF site **changed shape**: the path is now `sh -c`'s positional parameter, not text inside the program. The census sentence is replaced by two named per-plan lists plus the **recipe** to re-derive the total, with an explicit warning that neither list is a current count. The retired literal is **nowhere in the file**, not even quoted in a comment describing its removal — 06-28's lesson applied on purpose, since a grep for a token's absence cannot distinguish a claim from its retraction. **Driven by capture only (echo, never sent)**, with a space-bearing and a quote-bearing value. **Residue:** the five reshaped remote sites were never driven *on the wire* — `DEF-06-34-04` |
| **R3-02** | `phase06-oracle.sh`'s self-test banner claims "every fail-closed branch behaved exactly as expected" with **no pin on the case count** — so dropping `self_test_fences` from the dispatcher leaves `ST_FAIL` 0, `REDS` 0, exit 0 and a green banner over a set that no longer contains the only executed test of the `rm -rf` / `rm -f` receiving-side fences. `check-beets-config.sh` added exactly this guard (`ST_PLANNED_CASES`) in the same round; the oracle did not | **FIXED** | **CODE** | **Confirmed independently by the orchestrator.** The review grep-verified that of six `ST_RUN`/`ST_PLANNED`/`ST_FAIL=` hits, **none** is a comparison against an expected constant. The review's failure scenario was then **reproduced by execution**, not argued | Plan **06-31**, commit `e714632`, artifact `artifacts/06-31-oracle-pin-and-layer3.txt`. `ST_PLANNED_CASES=134` declared beside the dispatcher and compared against `ST_RUN` **as its own arm, ordered before** the `ST_FAIL`/`REDS` gate — mirroring the sibling, because GC-12(b) exists precisely because two failures once shared one banner. **Driven both directions by ablation** in a scratch copy from `mktemp -d`: a **one-line** deletion of `self_test_fences` from the dispatcher gives exit **1**, `✗ self-test: 111 case(s) ran but 134 were announced`; the real file gives exit **0** at the pinned 134. The load-bearing measurement is that the mutant produced **zero** failed cases and **zero** reds — the pre-existing gate would have passed it green. The pin was **measured, not copied from the plan**; task 3 ran last on purpose so the count had stopped moving. The review's weaker per-section-sentinel alternative was **refused** in favour of the sibling's existing idiom |
| **R3-03** | GC-15 fixed the **sending** side only. `sha256sum` prints `<hash><SP><SP><path>` and does not escape a space, so the local consumer `awk -v p="$REAL_LIB_DB" '$2 == p'` can never match for exactly the whitespace-bearing input GC-15 was written to support — and GC-15's comment asserts the consumers are fine | **FIXED** | **BOTH** | The review states its own basis: *"**static reasoning** over `sha256sum`'s documented output format. **Not executed** — the site contacts the estate."* The fix was then driven against synthetic `sha256sum` output on the workstation's own `awk`, **which is the real consumer** (the awk reads local files) | Plan **06-31**, commit `43e5d6c`, artifact `artifacts/06-31-oracle-pin-and-layer3.txt`. All four layer-3 consumers now carry one parser: strip a leading `<hex><SP><SP>` from a copy of the line, compare the **remainder for exact equality**, take the digest by position. The review's suffix-test suggestion was **refused with a reason**: a suffix test can match a line it was not asked about, turning R3-03's false UNKNOWN into a false GREEN. Six probes driven, including the two the fix must not break: a space-bearing path now returns its hash; a line that does not name the requested path returns **empty**, so the emptiness guards still fire. The GC-15 paragraph keeps its correct account of the *sending* side and **no longer claims the consumers were fine** — it names R3-03. **NOT DRIVEN:** the layer-3 block itself, reachable only from a live `--run` — `DEF-06-34-04` |
| **R3-04** | The layer-3 **AFTER** hashes have no emptiness guard, where the BEFORE block has two. An absent or unparseable second `sha256sum` line makes `LIB_SHA_AFTER` empty, the comparison false, and the script prints `❌ layer 3: the real library.db CHANGED (<64-hex> -> )` — **a measured failure asserted over a could-not-look**, the exact inverse of GC-05, and because UNKNOWN outranks RED here the misclassification also demotes the verdict | **FIXED** | **CODE** | The review states its own basis: *"**static**, by reading both blocks. **Not executed**."* The fix was driven as detached copies of both shapes, with both controls | Plan **06-31**, commit `43e5d6c`, artifact `artifacts/06-31-oracle-pin-and-layer3.txt`. The AFTER block now carries the BEFORE block's two guards, **above** the comparisons. Driven: an empty AFTER hash moves from RED/exit 1 with an arrow pointing at an empty string to **UNKNOWN/exit 3**; a genuinely different hash stays RED/exit 1; a matching hash stays green/exit 0. **The guard changes the verdict on exactly one input and leaves both real outcomes where they were** — which is the property that makes it a fix rather than a mute. Recorded in band in the file's own vocabulary: a could-not-look is never folded into another verdict. **NOT DRIVEN:** the live layer-3 block — `DEF-06-34-04` |
| **R3-05** | The thirteenth `EXIT-CODE BEHAVIOUR CHANGED` notice states, as a measurement taken across its own edit, `headers 12 -> 13`, `raw 15 -> 16` and a constant delta of three. Measured: headers 13, raw **17**, delta **four** — plan 06-26's GC-09 tail repair added a raw match later in the **same round**. The eighth notice institutionalised these two counts as the file's own drift detector, so a wrong baseline sends the fourteenth notice's author to a false starting number | **FIXED** | **CLAIM CORRECTION** | **Confirmed by execution, twice** — the review ran `/usr/bin/grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` and got **17** against 13 enumerated headers, and the orchestrator independently re-ran it. This is the one Warning whose confirmation is a measurement rather than a reading | Plan **06-30**, commit `82f4713`, artifact `artifacts/06-30-qhc-census-and-counts.txt`. **No behaviour change, no code move, no fourteenth notice** — and the omission of a fourteenth is recorded as a decision in the same paragraph, since the notice series exists for behaviour changes, not for corrections to its own arithmetic. The three lines are replaced by: a record that the counts were honest when taken and were invalidated within the same round (the **third** drift of these two numbers); the statement that the **header count is durable** and the raw count **deliberately unpinned**; and both recipes, written as `EXIT-CODE BEHAVIOUR CHANGE[D]` so the recipe lines are not themselves occurrences of the thing they measure — with one clause saying why, so nobody unbrackets it. **The review offered `raw 15 -> 17` and the drop was taken instead**: re-pinning a number that has drifted three times sets up the fourth drift. Proof the bracketing works: raw stayed **17 → 17** across an edit that added two recipe lines naming the string. Three earlier instances of the withdrawn sentence were **deliberately left alone** as dated historical records — `DEF-06-34-03` |

### Info

| ID | Defect, in one clause | Disposition | Fix kind | Confirmed by (provenance) | Evidence |
|---|---|---|---|---|---|
| **R3-06** | `self_test_fences`' in-band claim names three properties (no `rm`, no `touch`, no redirection into a path) and says "three cases below assert exactly that". The three cases assert **one** property — absence of the token `rm ` — for three different fence strings. `touch` is unasserted; "no redirection" is not merely unasserted but false as stated, since every fence text contains `>&2`. The claim is load-bearing: it is the stated reason a reader may trust these cases cannot delete anything | **FIXED** | **CLAIM CORRECTION** | The review verified by **reading the three cases**. No execution was involved on either side — the fix has no executable component **by design** | Plan **06-31**, commit `ad88ef5`, artifact `artifacts/06-31-oracle-pin-and-layer3.txt`. **Proven comment-only: 0 non-comment lines in the diff**, `*"rm "*` still returns 3, fence texts byte-unchanged. The prose now states only what is executed and **writes out the gap**: `touch` unasserted; redirection unasserted, with the `>&2` point resolved under **both** readings (a blanket no-redirection claim is false as stated; the narrower "nothing redirected into a PATH" sense does hold, since `>&2` opens nothing — but under either reading the property is unasserted, and that is the correction that matters). The two-character token bound is stated rather than left implicit. **The decision NOT to widen the three cases is recorded in band**, so the narrower sentence is not later read as a weakening — `DEF-06-34-05` |
| **R3-07** | Two observations in `check-beets-config.sh`, neither active today: GC-13's comment justifies preserving `ARM1_FAILS` on the grounds that "the live arm-1 summary line is a second consumer of it", but **this function never runs live**, so the stated reason does not apply to the change it justifies; and inside the function the *correct* outcome calls `cfg_fail` while the *defective* outcome (checker BLIND) is a bare `echo` — a polarity that is harmless under `--self-test` and wrong the moment anyone wires the function live | **FIXED** | **CLAIM CORRECTION** (plus a recorded precondition) | The review verified by grep — **and its census figure was wrong**; see § Corrections item 1. The polarity claim is **static reasoning over `cfg_fail`'s body**, not a measured outcome, and remains so: nothing was wired live | Plan **06-33**, commit `c4c708e`, artifact `artifacts/06-33-checker-case6-and-contract.txt`. The false reason is deleted and replaced with the true, narrower one (the self-test's per-case bookkeeping and the live summary share one counter), with the census given as a **recipe** rather than a number. The polarity precondition is recorded immediately above the function under the greppable opening **`IF THIS FUNCTION IS EVER CALLED LIVE`**, naming what must change *in the same commit as any wiring*, why it is harmless under `--self-test`, and why someone will be tempted — a live run currently never checks the `-l` + `-c` source contract at all. **Proven comment-only twice:** 0 non-comment lines in the diff, **and** `--self-test` output byte-identical across it (`cmp` rc 0). **REFUSED, deliberately:** wiring the function into the live path and re-polarising its arms. Both are behaviour changes to the live checker, outside a hardening round's brief — `DEF-06-34-02` |
| **R3-08** | After GC-13, case 6's gate reads `ARM1_REAL_VIOLATIONS` and `ARM1_SYNTH_REJECTED`; its `expect_reds` survives only to print `(expect 1 red)` in the banner, and the success line still prints a summed counter **nothing compares**. The banner can say "expect 1 red" while the gate passes a run that produced 0 or 2 — the announced-vs-actual drift `ST_PLANNED_CASES` was added twenty lines below to prevent, in miniature | **FIXED** | **CODE** | The review verified by anchor reading. **The fix drove the defect before removing it** — this row's evidence is executed, not reasoned | Plan **06-33**, commit `d560394`, artifact `artifacts/06-33-checker-case6-and-contract.txt`. The banner-only count is deleted; the banner now reads `(gate: real violations=0 AND synthetic rejected=1)` and the success line prints the two values the gate actually reads. `run_case`'s own summed comparison and cases 1-5 and 7 are untouched. **Driven:** on a scratch copy the summed counter was forced to 2 while both gated values stayed correct, and the pre-fix run printed `(expect 1 red)` over `2 red, as expected`, **green, exit 0** — two contradictory numbers in plain sight. **The review's second option was REFUSED, with the reason recorded at the gate**: adding `ARM1_FAILS -eq $expect_reds` as a third conjunct looks symmetric but is *implied by* the other two (when real violations are 0 and the synthetic was rejected once, the sum is necessarily 1), so it could never independently fail — the vacuous-assertion class CR-01, GC-03 and GC-05 each removed — `DEF-06-34-02` |
| **R3-09** | Both minted in-container scratch names in `phase06-incremental-control.sh` are cleaned on the `EXIT` pseudo-signal alone. A POSIX shell runs an `EXIT` trap on normal termination and on `exit`, **not** on an uncaught `SIGTERM`; both programs are `sh -s` under `timeout $REMOTE_TIMEOUT docker exec`, and a bound expiry is a routine outcome for a manifest over a large tree. The residue is then exactly what GC-08's own comment names as the worse case — *"a MINTED leftover is worse litter than a fixed one, because nobody knows its name"* — one unguessable directory per timed-out run, in a `/tmp` the same header records as mode 1777 | **FIXED (undriven)** | **CODE** | The review grep-confirmed the transport, and states its own basis for the rest: *"The signal behaviour below is **static reasoning about POSIX `sh`, not executed** against the container."* **It has not been executed since, either.** Neither trap has been observed firing inside `beets-flask` | Plan **06-32**, commit `928f9c2`, artifact `artifacts/06-32-incremental-trap-fences.txt`. Both traps now carry `INT TERM HUP` alongside `EXIT`. **The residual is stated in band rather than claimed away: `SIGKILL` cannot be trapped, so a hard kill still leaves the directory — the widening shrinks the window, it does not close it.** Outer gates after the change: `bash -n` clean and `--self-test` exit 0. The gate `bash -n` **cannot** give was supplied separately: both trap bodies live inside `<<'REOF'` heredocs, which `bash -n` parses as *data*, so both bodies were extracted with `awk` and parsed as POSIX `sh` — 65 and 31 lines, `sh -n` rc 0 on each. **Condition that would drive it:** a live `--arm a` / `--arm b` pair under a deliberately short `REMOTE_TIMEOUT`, checking the container's `/tmp` afterwards — `DEF-06-34-04`, `DEF-06-34-06`. **REFUSED:** the best-effort `/tmp/p6-mf.*` sweep the review floats in the same finding — `DEF-06-34-01` |
| **R3-10** | The two fences the same round introduced beside `rm -rf` / `rm -f` are **bare globs** — the exact property GC-02 had just removed from the sibling file, where a glob `*` matches `/` and the character class `[A-Za-z0-9._-]` does not — and the comment beside one claims it *"can never remove anything else"*. `/tmp/p6-mf.a/../../../home` matches `/tmp/p6-mf.*`. Latent, not reachable (`MANDIR` and `THPROG` are only ever `mktemp` output), so the finding is the **inconsistency plus the overstated claim** | **FIXED** | **BOTH** | The review states its own basis: *"**static**, by the same argument GC-02 makes in `phase06-oracle.sh`."* The fix's predicate was then **driven offline** with a positive control | Plan **06-32**, commit `befe732`, artifact `artifacts/06-32-incremental-trap-fences.txt`. Both fences now carry the sibling's **two-stage predicate**: template prefix, then a remainder that must be non-empty and drawn entirely from `[A-Za-z0-9._-]`. The empty pattern is written with double quotes — the trap body is a single-quoted string, so an inner single quote would terminate it. **Driven as a standalone `sh` snippet with no `rm`, `rmdir` or unlink of any kind in the drive file** (it prints `WOULD-REMOVE` / `REFUSED`): the traversal moves WOULD-REMOVE → **REFUSED**, the bare prefix `/tmp/p6-mf.` moves WOULD-REMOVE → **REFUSED**, a real `mktemp -d` name stays WOULD-REMOVE (the positive control, without which a tightened fence typically ships broken on its intended path), and the empty string stays REFUSED. Same four rows for the `/tmp/p6-taghist.` fence, identical outcomes. **The absolute claim is gone**: the comment now states the predicate and cites `scripts/phase06-oracle.sh`, so the two files state **one** rule rather than two, and records that the defect was latent rather than reachable |

---

## What was driven and what was not — the summary this register must not flatten

Ten `FIXED`s with no distinction would be precisely the over-claim the review is about. Stated
per surface:

1. **The whole layer-3 block (R3-03, R3-04) is UNDRIVEN as shipped.** It is reachable only from a
   live `--run`, which this phase does not perform. What *was* driven is the changed parts, as
   detached copies: the `awk` consumer verbatim against synthetic `sha256sum` output, and the
   guard/compare arms in the shape the file now carries. Both rows are `FIXED` under this
   register's vocabulary because a synthetic-fixture drive counts as driven — but the live block has
   never run, and that is residue, not a disposition. `DEF-06-34-04`.
2. **The `SIGTERM` behaviour behind R3-09 is static reasoning about POSIX `sh`**, on both sides: the
   review says so of its own finding, and plan 06-32 says so of its own fix. Neither trap has been
   observed firing inside the container. This is the single `FIXED (undriven)` row.
3. **`scripts/quick-health-check.sh` was not executed at all** — not by the review, not by plan
   06-30. It contacts LXC 100 and atlantis. R3-01's five reshaped remote sites are asserted by
   **capture** (a command string produced by `echo`, never sent) and by word-split trace; R3-01's
   injection consequence was never executed by anyone. R3-05 has no runtime branch to drive.
4. **Three findings closed with zero executable change** (R3-05, R3-06, R3-07), and two of them
   proved it mechanically rather than asserting it: 0 non-comment lines in the diff, and — for
   R3-07 — byte-identical `--self-test` output across the commit.
5. **Two things round 3 refused to do**, both recorded in band at their sites and carried in
   `deferred-items.md`: the `/tmp/p6-mf.*` sweep (`DEF-06-34-01`) and the pair of refusals under
   R3-07/R3-08 — the vacuous third conjunct, and wiring `assert_beet_invocation_contract` live
   (`DEF-06-34-02`).
6. **What *was* executed, and is worth naming because it is the smaller half:** the R3-02 ablation
   (both directions), the R3-08 pre-fix defect reproduction, the R3-10 predicate drive with its
   positive control, the R3-03 parser probes, the R3-04 guard arms, `sh -n` over both extracted
   heredoc bodies, and `bash -n` plus all three `--self-test` runs at HEAD.

---

## Verified-and-clean — **round 4 must not re-litigate these**

The review checked nine things adversarially and found them **correct as written**. Each is a place
a reviewer would expect a defect given this codebase's history, which is why the review recorded
them rather than staying silent. They are reproduced here as a **named, closed list**: a round-4
review should cite this register for them rather than re-deriving them, and a finding that merely
restates one of these nine is not a new finding.

1. **GC-01 here-strings** (`check-beets-config.sh`) — `grep -qF -- "$forb" <<<"$raw"` on both the
   built-in and the `EXTRA_FORBIDDEN_SUBSTRINGS` loops. No `| grep -q` remains in the file outside
   comments.
2. **Case 7 is genuinely a regression case**, not decoration — the 70,000-character pad is at the
   **top**, the only position the broken form would have missed; the pad contains neither
   `/music/imported` nor a `"` that could terminate the YAML scalar, so the expected red count is
   exactly 1.
3. **`D04_N_ASSERT` is computed correctly for the empty set** — `grep -c '^HEAD:'` yields 0 on the
   empty string. This is *not* the `printf | wc -l` off-by-one, and condition P's arm therefore
   actually fires.
4. **The `-1` UNKNOWN sentinels** on `ARM1_REAL_VIOLATIONS` / `ARM1_SYNTH_REJECTED` do what they
   claim: a case-6 gate reached without the producer having run fails rather than passing on a zero.
5. **`self_test_fences` cannot delete anything** — every behavioural case drives a `*_FENCE_SH`
   string, never a `*_PROG`; the byte-identity case between the two stamp fences is a real executed
   drift check; the refusal wordings genuinely differ.
6. **GC-07's correction is sound** — the `$$` run tag buys nothing (it is the macOS workstation's
   PID) and `SCRATCH_PROBE_PROG` is what actually refuses a pre-placed name.
7. **GC-12(a)'s deletion of `UNKNOWNS=0` is safe** — the self-test gate reads `ST_FAIL` and `REDS`
   only.
8. **GC-14's override notices are pure `echo`s** on every arm and touch no counter, so the additive
   contract is preserved.
9. **GC-16's regex widening** leaves the `(-|[a-z])` follower test intact, which is what holds the
   executable count at 8 rather than 26.

**Two of the nine were touched by round 3 and remain clean, which is worth saying so a round-4
reader does not assume the list went stale on arrival.** Item 4's sentinels are unchanged; item 5's
*cases* are unchanged (R3-06 narrowed the prose beside them and deliberately did not widen them —
`grep` for the token still returns 3, and the fence texts are byte-unchanged).

---

## Corrections to the source material

A register that only repeats its source would lose these. Round 2 recorded three; round 3 has one,
plus one methodological correction inherited from a plan's own diagnosis.

### 1. R3-07's own census sentence is wrong — it printed a code-only figure as a raw grep count

R3-07's **Verified** line reads: *"by grep — `assert_beet_invocation_contract` has **exactly two
hits**, the definition and one call site inside `run_self_test`."*

**Raw `/usr/bin/grep -cF` gives 4** at the tree the review was reading (post-round-2), and **5**
after plan 06-33 — definition, one call, and two (now three) comment mentions. It gives 2 only at
the review's own `diff_base` `bf509f4`, i.e. *before* the round under review added the comments.

**The finding's conclusion is correct and entirely unaffected**: exactly two occurrences are *code*,
and the code call is inside `run_self_test`, so the function does not run live. Only the census is
wrong. It is recorded here — and in band in `06-REVIEW-GAP2.md`'s wiring block — the way round 2
recorded the GC-15/GC-17 label crossing: **as a correction in band, not a silent fix and not a
downgrade of the finding.** A verification that pinned the review's number would have failed on
arrival, which is how this was caught.

Established by: plan 06-33's planning, by grep; re-measured by plan 06-34 at three refs
(`bf509f4` → 2, `fff070a` → 4, HEAD → 5); the durable figure is the **comment-stripped 2**, which is
what both the script and 06-33's verify now pin.

### 2. Quoting alone would have been a half-measure for R3-01, and the capture shows it

The review's **Fix** for R3-01 offers `EXTCONF_PATH_Q=$(printf '%q' "$EXTCONF_PATH")` alongside the
positional-parameter reshape. Plan 06-30 found, and captured, that the `_Q` alone would **not** have
closed the site: driven with `EXTCONF_PATH=/config/x";cat /etc/hostname;#`, the pre-change program
text is `cat "/config/x";cat /etc/hostname;#"` — **two commands** to the container's `/bin/sh`.
`printf '%q'` renders for a bash **word**; this value landed inside the **text** of a single-quoted
program, which is the one context `%q` is not correct for. **Only the positional form removes the
path from the program text.** The review is not wrong — it proposes the positional form for 2118 —
but the two halves of its fix are not interchangeable, and a reader taking the cheaper one would
have shipped a half-measure that looks like a fix, which is the thing the same comment block warns
about.

Established by: plan 06-30, by capture (`echo`, never sent).

---

## What this register does NOT do

**It changes no verdict, and it does not re-verify the phase.** No `/gsd-verify` run was performed
by plan 06-34 and **no verification result is claimed here**.

- **CONF-04 is NOT closed.** `REQUIREMENTS.md` is untouched by this plan and `- [ ] **CONF-04**`
  stands. Its Jellyfin half is still **OPEN** and ROADMAP entry criterion **E6** still owns the
  discharge. Its two verdicts — Jellyfin pending, Music Assistant discharged — are recorded
  separately and **are never summed**.
- **No requirement checkbox moves** and no phase-status wording is altered. **The phase is not
  declared complete**; that is the verifier's call, on a re-verification this plan does not perform.
- **Rounds 1 and 2's carried items stay carried.** CR-01's residue is owned by Phase 7 entry
  criterion **E10**, WR-09 by **E11**, round 2's undriven-until-the-pilot residue by **E12**.
  `DEF-06-21-*` and `DEF-06-29-*` are unchanged.
- **It does not re-open what is already owned.** The ~23 remaining `printf … | grep -q`
  SIGPIPE-141 sites (`DEF-06-29-01`), CONF-04's Jellyfin half (**E6**) and the three un-rotated
  secrets on LXC 100 (`DEF-06-29-09`) each already have an owner; round 3 adds no duplicate entry
  for any of them.
- **It adds no new Phase 7 entry criterion.** Round 3's residue is small enough to live in
  `DEF-06-34-01` … `DEF-06-34-06`, and the part that closes only on a live run attaches to the
  existing **E12**.

---

## Lessons — round 3's own, not round 2's restated

### 1. The dominant defect class was a claim broader than its code — and the honest fix was usually to narrow the sentence

Six of the ten findings are, at root, a comment that promises more than the code beside it delivers:
a census that says FOUR, a banner that claims "every fail-closed branch", a safety note that names
three properties over one assertion, a justification whose stated reason does not apply, a fence
comment that says "can never", and a notice whose arithmetic was true when written. **Three were
closed by narrowing the sentence, and three by doing both.**

The corollary is the part worth keeping: **a plan that silently widens scope to make a comment true
is worse than one that corrects the comment.** R3-06 is the clean case — the three `rm ` cases were
deliberately *not* widened and the prose was narrowed instead, with the decision recorded in band so
the shorter sentence is not later read as a weakening. R3-08 is the sharper case: the review offered
a third conjunct that would have made the banner and the gate agree, and taking it would have traded
an honest-announcement defect for a **vacuous assertion** — the exact class CR-01, GC-03 and GC-05
each removed. Refusing it was the fix.

### 2. Two reviews in a row produced findings inside the previous review's own fixes — and the way out is not another round

Round 2 found a BLOCKER and seven Warnings inside round 1's gap closure. Round 3 found five Warnings
and five Info inside round 2's. That is not a reason to run round 4 reflexively; it is a reason to
watch the **shape** of the findings. Round 3 found **zero Critical** and **no reproducible false
green**, and said so explicitly rather than manufacturing a BLOCKER. Most of its fixes were claim
corrections.

**The exit condition is a review whose findings are Info-only and whose fixes are claim
corrections** — which is most of what round 3 already was. A fourth review of round 3's own diff is
the same discipline that caught both previous rounds, and it should be a **deliberate decision**
rather than an omission; but the honest reading of round 3's own numbers is that the marginal return
has fallen sharply, and that `/gsd-verify 06` is the next step.

### 3. Self-referential measurement in files that grep themselves is this phase's signature hazard

Three separate instances, in one round:

- **R3-05's subject is a count invalidated by a later plan in the same round** — 06-23 measured the
  raw/header delta honestly, and 06-26's tail repair, in a line *saying a notice was deliberately
  not added*, added a raw match and broke it.
- **R3-07's own census sentence** printed a code-only figure as a raw grep count, because the round
  under review had added comment mentions of the very symbol being counted.
- **06-28 reproduced GC-10's defect with the fix for it** — the prose explaining why the counts are
  not recorded moved the counts.

**The mitigation adopted, and it is now this phase's standing practice: state a recipe, not a
number.** Where a number must appear in a file that greps itself, bracket the pattern so the recipe
is not an occurrence of the thing it measures (`EXIT-CODE BEHAVIOUR CHANGE[D]`), pin the
comment-stripped form rather than the raw one, and say in one clause why — because the next reader
will otherwise "simplify" it back. The proof that this works is R3-05's own: raw stayed **17 → 17**
across an edit that added two lines naming the string.

### 4. A corollary, cheap to state and expensive to relearn: do not paste a retired construction into the comment disowning it

Plan 06-30 removed the hand-escaped wrapper from `quick-health-check.sh` and described its shape in
prose, reconstructing the literal only in the artifact. Round 2 hit the same wall twice. **A grep
for a token's absence cannot distinguish a claim from its retraction**, so a comment that quotes
what it removed makes the mechanical check for that removal permanently unable to return zero.

---

_Register written 2026-09-23 by plan 06-34._
_Source: `06-REVIEW-GAP2.md`, reviewed 2026-09-22 (commit `766b2d0`) against `diff_base` `bf509f4`
over four scripts; no cross-family adjudication._
_Gap closure round 3: plans 06-30, 06-31, 06-32, 06-33, 06-34._
_All measurements in this file answered by `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD), by absolute
path, not the operator's zsh `ugrep` alias._
