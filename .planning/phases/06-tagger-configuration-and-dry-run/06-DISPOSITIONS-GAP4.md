# Phase 6 — disposition register for `06-REVIEW.md` (gap closure, ROUND 6)

**Written:** 2026-09-24 by plan 06-50 (wave 3).

## Why this file exists

`06-REVIEW.md` is a standard-depth code review of this phase's changed files — the six bash
instrument scripts plus the beets / beets-flask configuration and compose definitions they assert
against. It found **0 Critical, 3 Warning and 2 Info**. Round-6 plans 06-46 through 06-49 supplied
the fixes and the one deliberate refusal. This file supplies the part a fix commit cannot: a
statement of what happened to **each** of the five findings, so the set cannot be lost at the next
context boundary.

Round 1's headline lesson, recorded in `06-DISPOSITIONS.md` and re-learned in three subsequent
rounds, is that *a finding recorded where the next phase does not read is a finding nobody owns*.
Round 4 additionally learned that a review reusing a prior round's ID namespace makes every grep for
a finding non-discriminating **in exactly the files that carry the citation**, and paid for it four
times over. `06-REVIEW.md` reuses `WR-*` / `IN-*` — round 1's namespace, already cited in band across
all six scripts — so round 6 uses **`R6-*`**, chosen up front rather than aliased afterwards, and
this register carries the mapping table.

It is referenced from `06-REVIEW.md`'s appended wiring block and from `.planning/ROADMAP.md`'s
Phase 6 disposition paragraph.

## Source

| | |
|---|---|
| Source review | `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW.md` |
| Reviewed | **2026-09-24** (frontmatter `reviewed: 2026-09-24T15:08:05Z`) |
| `diff_base` | **none recorded.** Unlike rounds 3 and 4, this review's frontmatter carries no `diff_base`: it is a standard-depth pass over the phase's changed files as they stand, not a review of a named diff |
| Depth | **standard** |
| Files reviewed | **12**: the six scripts `check-beets-config.sh`, `check-music-consumers.sh`, `check-music-freeze.sh`, `phase06-incremental-control.sh`, `phase06-oracle.sh`, `quick-health-check.sh`, plus `stacks/selfhosted/arrs/beets.md`, the four beets / beets-flask YAML files and `stacks/selfhosted/arrs/compose.yaml` |
| Status | `issues_found` |
| ID space | `WR-01 … WR-03`, `IN-01 … IN-02` — **which is round 1's namespace.** See the mapping table immediately below; the fixes are cited in band as `R6-01 … R6-09` |
| Adjudication | **NONE. There was no cross-family adjudication in round 6.** Round 2 had one; rounds 3, 4, 5 and 6 did not. Stated rather than left ambiguous — an absent adjudication nobody mentions reads exactly like a lost one |

**The review's own measurement note, carried forward because it bounds every finding below.** The
review states that `shellcheck -S warning` was clean on five of the six scripts and that it traced
control flow by reading rather than by executing. **There was no estate contact of any kind** in the
review or in any of round 6's plans: no ssh, no docker, no `--run`, no HTTP verb, no package install.
`quick-health-check.sh` was executed **zero** times, by the review and by every round-6 plan.

---

## THE ID MAPPING TABLE — read this before following any citation

Round 6's in-band namespace is **`R6-*`**. Nine rows: the five review findings plus the round's four
non-review items, so one table covers the whole round.

| Review ID | In-band ID | Owner / subject file | Subject, in one line | Disposition |
|---|---|---|---|---|
| **WR-01** | **R6-01** | plan 06-46 — `scripts/check-music-freeze.sh` | `xs` and `xdst` are bound but never referenced in the five-field tagger-inventory read — the only `shellcheck -S warning` finding across all six scripts | **FIXED** |
| **WR-02** | **R6-02** | plan 06-49 — all six scripts | the extreme comment-to-code ratio: round-by-round historical narrative interleaved with durable rationale at the same visual weight | **ACCEPTED** |
| **WR-03** | **R6-03** | plans 06-46 + 06-49 — `check-music-freeze.sh`, `CONVENTIONS.md` | pinned counts that gate pass/fail with no automated cross-check and no discoverable remedy in the failure message | **FIXED** |
| **IN-01** | **R6-04** | plan 06-49 — `CONVENTIONS.md`, `CLAUDE.md` | `CLAUDE.md` claims no conventions exist while the scripts enforce several load-bearing ones | **FIXED** |
| **IN-02** | **R6-05** | plan 06-47 — `stacks/selfhosted/arrs/beets.md` | a 2,470-line running log with nothing at the top pointing at the authoritative current state | **FIXED** |
| *(no review ID)* | **R6-06** | plan 06-48 — `deferred-items.md` § `DEF-06-48-01` | `DEF-06-45-04`'s non-detecting `-cF`-over-a-bracketed-needle recipe, corrected and driven against a control | **FIXED** |
| *(no review ID)* | **R6-07** | plan 06-48 — `deferred-items.md` § `DEF-06-48-02` | the bracketing convention's undecided scope, now a written decision with reasoning and a revisit condition | **FIXED** |
| *(no review ID)* | **R6-08** | plan **06-51** (wave 4, `autonomous: false`) — outcome lands in `DEF-06-51-01` and in this register's **`ROUND CLOSE`** section, filled by `06-52` task 3 | the host `git pull --ff-only` sync of LXC 100 at `/mnt/fast/stacks` | **PENDING** |
| *(no review ID)* | **R6-09** | plan **06-52** (wave 5, `autonomous: false`) — outcome lands in `DEF-06-52-01` and in this register's **`ROUND CLOSE`** section, filled by `06-52` task 3 | the `tank/media/Music@pre-06-41-conf04-reprobe` snapshot-release go/no-go | **PENDING** |

⚠ **The last two rows describe plans that had NOT executed when this register was written.** This
register is written at wave 3; `06-51` runs at wave 4 and `06-52` at wave 5, both `autonomous: false`
and both carrying legitimate `halt` / `hold` branches. Their disposition cells were therefore written
at wave 3 as the literal word `PENDING`, and `06-52` task 3 replaces them with the real outcomes —
`PENDING` is **not** one of this register's four disposition words and is deliberately not one.
`DEF-06-51-01` and `DEF-06-52-01` are the **authoritative fallback**: if the
round never reaches its close, a reader following those two rows still lands on the truth rather than
on a silence.

### Why the aliasing exists — two clauses, both measured

**Clause one: `06-REVIEW.md` uses `WR-*` / `IN-*`.** Round 1's review used `CR-*` / `WR-*` / `IN-*`;
round 2 used `GC-*`; round 3 used `R3-*`; round 4's report went back to `WR-*` / `IN-*`; round 6's
report does the same.

**Clause two: those IDs already mean something else in the very files round 6's findings land in.**
Measured with `/usr/bin/grep -cF` at this plan's base commit `3085da1`, for exactly the five IDs the
review reuses:

| File | `WR-01` | `WR-02` | `WR-03` | `IN-01` | `IN-02` |
|---|---|---|---|---|---|
| `scripts/quick-health-check.sh` | 7 | 1 | 5 | 0 | 0 |
| `scripts/phase06-oracle.sh` | 4 | 2 | 0 | 0 | 0 |
| `scripts/phase06-incremental-control.sh` | 0 | 0 | 0 | 0 | 1 |
| `scripts/check-beets-config.sh` | 0 | 0 | 0 | 1 | 0 |
| `scripts/check-music-freeze.sh` | 0 | 0 | 3 | 0 | 0 |
| `scripts/check-music-consumers.sh` | 5 | 1 | 7 | 1 | 1 |

**39 pre-existing citations of the five reused IDs**, none of which has anything to do with round 6.
The whole-namespace figure across the same six files is **35 / 28 / 4 / 5 / 4 / 18 = 94**, and it is
**identical at the pre-round-6 commit `75c7989` and at base `3085da1`** — round 6 added **zero** new
`WR-*` / `IN-*` in-band citations, which is the mechanical form of "the namespace was chosen up front
rather than aliased afterwards".

**Recipe, so this is re-derivable rather than pinned** (these counts move with every comment that
names an ID — this file's own subject matter, so the figures above are a dated measurement taken
2026-09-24 at `3085da1`, not an invariant):

```sh
for f in scripts/quick-health-check.sh scripts/phase06-oracle.sh \
         scripts/phase06-incremental-control.sh scripts/check-beets-config.sh \
         scripts/check-music-freeze.sh scripts/check-music-consumers.sh; do
  printf '%s: ' "$f"; /usr/bin/grep -coE 'WR-0[1-9]|IN-0[1-9]' "$f"
done
```

**The rule `DEF-06-39-01` established, honoured here:** *a review's ID namespace must be unique per
round, and must be chosen before the review is written.* Round 4 minted `R4-*` **after** the fact and
paid for it in four plans. Round 6 minted `R6-*` **in the plans themselves**: plan 06-46's two edits
to `check-music-freeze.sh` carry `R6-01` and `R6-03` citations in band — measured **3** occurrences of
`R6-0[1-9]` in that file — and no plan had to build an alias table of its own.

---

## D-R6-M4 — what the `Plans Complete` column means. Decided; not argued here

**Decision `D-R6-M4`, owner: the operator, 2026-09-24.** `ROADMAP.md`'s phase-status table header
reads `| Phase | Plans Complete | Status | Completed |` and the Phase 4 precedent row reads
`16/16 | In Progress` noted "All 16 plans executed": **the column means EXECUTED, not authored.** So
the numerator this round writes into the Phase 6 status row is the **measured count of plans actually
executed at the moment of the edit** — counted as `06-NN-SUMMARY.md` files present in the phase
directory, a `-PARTIAL.md` not counting — over a denominator of **52**, and `06-52` at wave 5 closes
it to `52/52` as the round's last act. In the same clause: the `**Plans**: … plans in … waves`
header near the Phase 6 section is **owned by `06-52`** for the same reason and was left byte-untouched
by this plan, so it is not left unowned again.

---

## Counts

**Findings, as the review's own frontmatter records them:**

| class | count |
|---|---|
| critical | **0** |
| warning | **3** |
| info | **2** |
| **total** | **5** |

**Dispositions, by class:**

| disposition | count |
|---|---|
| FIXED | **4** |
| FIXED (undriven) | **0** |
| ACCEPTED | **1** |
| CARRIED | **0** |

**Fix-kind, by class — the column survives from round 3, and round 6 needed it:**

| fix kind | count | which |
|---|---|---|
| CODE | **1** | R6-01 |
| CLAIM CORRECTION | **3** | R6-02, R6-04, R6-05 |
| BOTH | **1** | R6-03 |

**Reconciliation, stated so an arithmetic slip is visible rather than latent:** the review's
frontmatter 0 + **3 Warning** + **2 Info** = **5**; the dispositions 4 + 0 + 1 + 0 = **5**; the fix
kinds 1 + 3 + 1 = **5**. Three routes, one total. The three routes agree; no disagreement to state.

**⚠ THE SCOPE OF THIS RECONCILIATION, AND WHO MUST EXTEND IT.** The arithmetic above covers the
**five review findings only** — `R6-01` … `R6-05`. `R6-06` … `R6-09` are round items with no review
ID and sit **outside** it: they are not counted in any of the three routes. When **`06-52` task 3**
fills the `R6-08` and `R6-09` rows it **must EXTEND this section** with their two dispositions and
re-state the totals, rather than leaving the arithmetic describing a subset that no longer matches
the table. `06-52` task 3 is named here as the owner of that extension. A reconciliation that is
never re-run after its table grows is a check that has stopped checking.

## The vocabulary, which is closed

Exactly four words, unchanged from `06-DISPOSITIONS.md`, `-GAP.md`, `-GAP2.md` and `-GAP3.md`. No
fifth word was invented, and `PENDING` is **not** one of them — it is a state, was written at wave 3
onto the two non-review rows and nowhere else, and is excluded from every count above.

- **FIXED** — a commit changed the behaviour **and** the changed branch was driven. Cites the plan,
  the commit and the artifact holding the driven transcript. A drive over a **synthetic fixture**
  counts as driven; the row names the fixture. For a change with no runtime branch (a comment, a
  document, a claim in prose) the file's own committed state is the observation, and the row says so.
- **FIXED (undriven)** — a commit changed the behaviour but the branch was **never observed firing**
  in this phase. Unused in this register.
- **ACCEPTED** — deliberately not changed, with a stated reason and a revisit condition. One row:
  **R6-02**.
- **CARRIED** — deferred by name to a `DEF-` entry or a ROADMAP entry criterion that exists. Unused
  in this register as a *disposition*; the round's refusals and residue are carried separately in
  `deferred-items.md`.

### Fix kinds, also closed

- **CODE** — the executable behaviour changed.
- **CLAIM CORRECTION** — no executable behaviour changed; a claim was narrowed, withdrawn or replaced
  to match what the code already did.
- **BOTH** — code widened *and* a claim corrected, because neither half alone closes the finding.

**One judgement call, stated rather than smoothed.** Three of round 6's fixes are *documents written*
(`CONVENTIONS.md`, the `beets.md` pointer, the `CLAUDE.md` mirror) rather than in-band claims
narrowed. The closed vocabulary has no word for "durable documentation added", and **no fifth word was
invented for it**: each is recorded as **CLAIM CORRECTION**, which is the set's name for *no executable
line changed*, and each row says in its own text what was actually written. R6-04 is a claim
correction in the strict sense as well — `CLAUDE.md`'s `Conventions not yet established` was a false
statement and was replaced.

---

## The register — all 5 findings, in ID order

### Warnings

| Review ID / in-band ID | Defect, in one clause | Disposition | Fix kind | Confirmed by (provenance) | Evidence |
|---|---|---|---|---|---|
| **WR-01** / **R6-01** | `while IFS='\|' read -r xn xs xsrc xdst xflag` in the tagger-capable inventory binds `xs` and `xdst` and references neither. Flagged twice by `shellcheck -S warning` (SC2034) — **the only shellcheck finding across all six scripts in scope**. Not a functional bug, but an unused binding in a five-field destructuring read is where a future column insertion hides | **FIXED** | **CODE** | **Verified by execution of the instrument that found it, on both sides.** `shellcheck -S warning` went from clean-on-five to **clean on all six**, exit 0 with zero output on each. The *premise* was checked before the edit rather than assumed: a grep for `\b(xs\|xdst)\b` at plan 06-46's base returned exactly one line — the binding itself — so the plan's STOP condition (either column actually being consumed) was live and did not fire | Plan **06-46**, commit `e515970`, artifact `artifacts/06-46-freeze-fixes.txt`. **The named form was taken, not the review's bare-underscore alternative.** WR-01 offers `read -r xn _ xsrc _ xflag`; two anonymous positions discard the column NAMES, which is precisely the drift the finding is about. The binding is `xn _xs xsrc _xdst xflag` — shellcheck-clean and self-describing, field count still five. **The column order was read from the producer, not inferred from the names:** the `docker inspect --format` that feeds the loop emits `name\|state\|source\|destination\|rw-flag`, so `_xs` is the container state and `_xdst` the mount destination, confirming the two underscore-prefixed names are the two the body does not use. One `R6-01` comment line accompanies the change. **The zero-expecting confirmation was driven:** the identical comment-stripped recipe returned **1** against a one-line control containing a real reference and **0** against the script |
| **WR-02** / **R6-02** | Every file in scope carries a dense internal audit trail — dozens of named defect IDs cross-referencing each other, prior rounds and specific artifacts — with **no separation between "why this exists" (durable) and "what changed in round N" (historical)**, interleaved at the same visual weight. `quick-health-check.sh` carries thirteen numbered exit-code-behaviour notices in its header alone; locating assertion logic in it or in `phase06-oracle.sh` means scrolling past thousands of lines of narrative | **ACCEPTED** | **CLAIM CORRECTION** | **No execution was required or performed, on either side.** The review states the finding as a maintainability cost, not a defect to patch, and explicitly calls the narrative *"a genuine asset for provenance"*. The acceptance and its self-binding claim are **measured** — see § *The WR-02 position*, which publishes the round's script-diff line count, its comment share and the recipes that produced them | Plan **06-49**, commit `0d9c6f2`, `CONVENTIONS.md` convention 12. **ACCEPTED, not fixed, and the round binds itself so the cost does not grow** — the full reasoning is its own section below. The durable half of WR-02's fix is taken as a **forward rule**: from here a comment explains *why a branch exists*, and *which round changed what* goes to the phase directory cited by one short ID. **The existing narrative is not stripped**, and convention 12 says so in its own text. One correction to the source material came out of writing it, recorded in § *Corrections* item 1 |
| **WR-03** / **R6-03** | Three pinned counts gate pass/fail and must be hand-moved in the same commit as an unrelated change elsewhere in the tree: `DECLARED_INTERP_EXPECTED` and `TAGGER_DEF_EXPECTED` in `check-music-freeze.sh`, and `ST_PLANNED_CASES=7` in `check-beets-config.sh`. They fail **loud**, so this is not a fail-open risk — it is a standing maintenance trap whose remedy is not discoverable from the failure message | **FIXED** | **BOTH** | **Both of the review's own fix options were delivered, and both fail arms were driven in both directions.** The drives ran from a harness extracted **verbatim by line range out of the file plan 06-46 commits** (interp block, tagger block), green and red, with the red transcripts showing the interpolation live — `from 12 to 13` rendered from the real variables. The artifact states its own limit in one clause: this proves the arm TEXT and its interpolation, **not** the live block, which needs estate contact this round makes none of | Plans **06-46** (commit `049e9a3`, artifact `artifacts/06-46-freeze-fixes.txt`) and **06-49** (commit `0d9c6f2`, `CONVENTIONS.md` convention 5). **Fix option (a):** both fail arms now print the literal edit — the constant named by NAME, never by line number; pinned → measured interpolated; the read-by-hand precondition; the same-commit rule; and a prohibition on using the env override to silence a red, written as a **policy on top of the header's documented capability** rather than a contradiction of it. The tagger arm refuses the count bump by name and requires a `TAGGER_DEF_<NAME>` + `_CLASS` pair into the expected SET, because D-11 asserts the pair BY NAME AND BY CLASS. Both are plain `echo` beside the existing `fail`, so `FAILURES` is untouched and one violation cannot double-count — asserted at **24** comment-stripped `fail ` call sites at both ends. **Fix option (b):** `CONVENTIONS.md` convention 5 names all four live pins by symbol and carries the harder rule this phase learned twice — *a pin over a set with environment-conditional members must adjust where the condition is decided, or it is a constant pretending to be an invariant.* **The third site, `ST_PLANNED_CASES=7`, was deliberately NOT touched** — see § *The round's refusals* item 1 |

### Info

| Review ID / in-band ID | Defect, in one clause | Disposition | Fix kind | Confirmed by (provenance) | Evidence |
|---|---|---|---|---|---|
| **IN-01** / **R6-04** | `CLAUDE.md` says *"Conventions not yet established"* and *"Architecture not yet mapped"*, while the scripts in this phase collectively establish several real, load-bearing conventions — the additive-only `${VAR:-default}` override contract, the deliberately duplicated two-layer destructive fence, the `EXIT_CODE` / pending / UNKNOWN three-state exit, the `📊 N. Summary` cross-file grep anchor. None is captured anywhere a contributor would look | **FIXED** | **CLAIM CORRECTION** | **Verified by reading every canonical example before writing it down, and by an ordered correspondence check that was driven RED first.** No script was executed — this plan changed no executable file. The structural fact that decided the deliverable was **measured, not assumed**: `CLAUDE.md`'s `## Conventions` block is a GSD block whose opening marker *names its own source* (`GSD:conventions-start source:CONVENTIONS.md`), and that file **did not exist at the repo root** — which also resolves the review's own confused reading that "the repo's own `CONVENTIONS.md` is currently empty". It was absent, not empty | Plan **06-49**, commits `0d9c6f2` (`CONVENTIONS.md`, new, **319 lines / 13 sections / 20 lines citing `scripts/`**, every entry naming a canonical example **by file and symbol, never by line number**) and `51ca680` (the `CLAUDE.md` mirror). **The mirror is proven by ORDERED name-for-name correspondence, not by a count floor:** `\|A\| == \|B\| == 13` and `B[i]` contains `A[i]` at every index, **with the comparator driven red first** against a copy of B with entry 3 mutated — a `>= 8` floor is satisfiable by eight wrong names, which is how a mirror goes quietly stale while passing its own check. Both GSD marker lines byte-identical to base; the diff a single hunk strictly inside the marker pair; text outside the span byte-identical on both sides. **⚠ The architecture half of this finding is ACCEPTED and `ARCHITECTURE.md` was deliberately NOT created** — see § *The round's refusals* item 2. `Architecture not yet mapped` still reads **1** in `CLAUDE.md`, asserted mechanically |
| **IN-02** / **R6-05** | `stacks/selfhosted/arrs/beets.md` mixes phase-by-phase historical narrative with the information a reader actually needs at a glance. Finding the authoritative current state requires knowing to jump to the end of the file; **nothing at the top points there** | **FIXED** | **CLAIM CORRECTION** | **Verified mechanically rather than by eye.** The pointer's citation of the Phase 6 closure heading is proven byte-identical to the real heading: `/usr/bin/grep -cF` of the full heading string returns **2** over the file (pointer plus real heading) and **1** restricted to `#`-prefixed lines — so it reproduces exactly one real heading, and that heading is a heading rather than prose. The edit is purely additive: **26 insertions, 0 deletions** | Plan **06-47**, commit `6a38e02`. A `Current state — read this first` blockquote inserted so it is the **first blockquote a reader meets**, naming the Phase 6 closure section by exact heading text, restating Phase 6's disposition in the same words the other records use, and carrying a **go-forward rule** — every future closure section must update the pointer **in the same commit**, and a closure section whose pointer was not updated is the defect, not the pointer. **⚠ IN-02's own suggested fix is a LINE NUMBER (`see § Phase N closed, line X`) and was deliberately NOT taken**; the departure and its reason are stated **in the pointer itself**, so it cannot later read as an oversight. **⚠ `### The five criteria` occurs TWICE in the file** — once under Phase 5's closure, once under Phase 6's — so the pointer names it as nested under the Phase 6 heading and discloses the ambiguity in band |

---

## The WR-02 position — stated once, plainly, and not straddled

**`WR-02` is ACCEPTED, with rationale. It is NOT fixed this round, and the round binds itself so that
the cost does not grow.**

The reasoning, as reasoning:

- WR-02's proposed fix is a **bulk relocation of round-by-round narrative** out of
  `quick-health-check.sh` (3,148 lines), `phase06-oracle.sh` (3,274) and four siblings. That is the
  largest possible diff across the six most heavily reviewed files in this repository, proposed at the
  end of a five-round recursion in which **every round's own diff became the next round's findings**,
  and in which round 3's centrepiece fix was round 4's largest finding.
- The review itself calls the narrative *"a genuine asset for provenance (every fail-closed branch has
  a stated reason and a driven test)"*. A bulk strip risks losing **the reason a fail-closed branch
  exists**, on instruments that run against a host carrying ~103 containers. The cost of the ratio is
  real; the cost of getting the strip wrong is higher and lands on the estate.
- The durable half of WR-02's fix is therefore taken as a **forward rule**, written into
  `CONVENTIONS.md` by plan 06-49 as convention 12: from here on a comment explains *why a branch
  exists*, and *which round changed what* goes to the phase directory, cited by one short ID. The
  existing narrative is **not** stripped.
- Round 6 **binds itself to that rule**, and the binding is **measured rather than asserted**:

| Measurement of round 6's own in-band footprint | Value |
|---|---|
| files under `scripts/` changed by the whole round | **1** (`check-music-freeze.sh`) |
| lines added / deleted under `scripts/` | **6** / **1** |
| of the 6 added lines, comment lines | **3** — each a single-line `R6-01` / `R6-03` citation at the changed site |
| of the 6 added lines, emitted remediation (`echo`) | **2** — *failure output*, printed where the maintainer is standing, which is the opposite of the WR-02 problem |
| of the 6 added lines, executable rebinding | **1** — the `read` line replacing the deleted one |
| new in-band historical narrative added by round 6 | **0 lines** |
| new `WR-*` / `IN-*` in-band citations added by round 6 | **0** (94 at `75c7989`, 94 at `3085da1`) |

Recipe, so the figures are re-derivable rather than pinned (`75c7989` is the pre-round-6 tree):

```sh
git diff --numstat 75c7989..HEAD -- scripts/
git diff 75c7989..HEAD -- scripts/ | /usr/bin/grep -cE '^\+[^+]'
git diff 75c7989..HEAD -- scripts/ | /usr/bin/grep -E '^\+[^+]' | /usr/bin/grep -cE '^\+[[:space:]]*#'
```

A round that claims restraint without a number is the over-claim this register exists to prevent.
The round's other 2,510 added lines are planning documents and `CONVENTIONS.md` — *out of band*,
which is convention 12's whole point.

**Revisit condition:** the first time a maintainer cannot locate an assertion in one of the six
scripts within a reasonable read, or the first phase that adds a fresh round of in-band narrative in
violation of convention 12. The fix then is still not a bulk strip — it is to move the **already
superseded** paragraphs, file by file, each with its own driven before/after on `--self-test`.

---

## What was driven and what was not — the summary this register must not flatten

Four `FIXED`s with no distinction would be the over-claim the review is about. Stated per surface:

1. **`scripts/quick-health-check.sh` was executed ZERO times** — by the review, and by every plan in
   round 6. It contacts LXC 100 and atlantis, and this round makes no estate contact. Nothing in this
   register claims anything about its runtime behaviour. `DEF-06-39-05` already owns that residue.
2. **R6-03's two fail arms were driven from an EXTRACTED HARNESS, not from the live block.** The
   harness text was taken verbatim by line range out of the committed file, so the arm text and its
   interpolation are proven; the live block still requires a real `check-music-freeze.sh` run against
   the estate, which nothing in round 6 performed.
3. **R6-02, R6-04 and R6-05 changed no executable line at all** — three of five findings. `CONVENTIONS.md`
   is a description, not an enforcer: nothing executes it, and the correspondence check that proves
   `CLAUDE.md` mirrors it **is not committed as a script**, so a future edit to either list will not be
   caught automatically. The mirror check proves the two documents match each other; it does **not**
   prove either matches the scripts.
4. **The instruments were re-measured at HEAD by plan 06-46, not carried forward, and were NOT
   re-driven by plans 06-47, 06-48 or 06-49** — those three changed no executable file and say so
   rather than restating figures as though re-driven. At 06-46: `check-beets-config.sh --self-test`
   exit **0 / 7 cases** (6 red), `phase06-oracle.sh --self-test` exit **0 / 140 cases**, in the named
   reference environment (macOS 27.0 arm64, **non-root uid 501**, `python3` PRESENT, GNU bash 5.3.15,
   ShellCheck 0.11.0, BSD grep at `/usr/bin/grep`). The 140 figure is valid only in that environment.
5. **R6-06's re-derived zeros are about the estate; R6-06's control drive is what makes them
   evidence.** Both halves are stated without either being softened into the other: the published `0`
   is TRUE — re-derived across seven files, fourteen readings — **and** it was not earned by the
   command originally printed beside it.
6. **What *was* executed, named because it is the smaller half:** `shellcheck -S warning` across all
   six scripts before and after; the two `--self-test` runs above; the four extracted-harness arm
   drives; the `-cE` / `-cF` control matrix; the `-cE`-reads-`[R]`-as-a-class third drive; the
   ordered-correspondence comparator green and red; and every zero-expecting screen in every plan,
   each driven against a control first.

---

## Verified-and-clean — round 6's own list, and a round 7 must not re-litigate these

`06-REVIEW.md`'s summary records places a reviewer would expect a defect in this codebase and found
**correct as written**. Reproduced here as a named, closed list: a round-7 review should **cite this
register** rather than re-deriving them, and a finding that merely restates one of these is **not a
new finding**.

1. **`shellcheck -S warning` is clean on all six scripts** at HEAD — five at the review, six after
   R6-01.
2. **No committed credential** in the beets / beets-flask YAML or in `compose.yaml`.
3. **No drift between the two active tagger definitions and the census that asserts them** — checked
   by the review against `check-music-freeze.sh` and `beets.md`.
4. **No non-detecting `grep -F` over a bracketed pattern in the scripts**, and **no vacuous NUL-byte
   test**, and **no unbounded remote pipeline** — the review checked all three by name. (The one
   non-detecting recipe that did exist was in a dated **artifact**, not in a script, and is `R6-06`.)
5. **No Critical-severity defect of any kind.** The review states it plainly rather than manufacturing
   one: *"No Critical-severity (security/data-loss/crash) defects were found in this pass."*
6. **The pinned counts fail LOUD, not open** — the review read the branches at each of the three sites
   and confirmed a mismatch is a `fail`, never a `pass`. R6-03 improves the *message*, not the
   polarity, and nothing in round 6 changed a predicate.

---

## The round's refusals — recorded as loudly as its fixes

Each carries a reason and a revisit condition. A refusal nobody wrote down reads as an oversight, and
costs the next round its budget re-proposing it.

1. **`ST_PLANNED_CASES=7` in `check-beets-config.sh` was NOT touched** — the third site named by
   WR-03. Round 4 excluded it **by name** (`DEF-06-39-02`; `06-DISPOSITIONS-GAP3.md` §
   *Verified-and-clean* item 7): it is a **gated pin over an unconditionally executed set** — six
   `run_case` calls plus the manual case 6, no environment-conditional members — so "fixing" it breaks
   a working guard. Plan 06-46 asserted the file byte-unchanged with `git diff --exit-code HEAD --`.
   **Revisit condition:** the first environment-conditional case added to that self-test, at which
   point convention 5's rule applies and the decrement goes beside the skip.
2. **No `ARCHITECTURE.md` was created** — IN-01's architecture half is **ACCEPTED**. This estate's
   architecture is already documented in `NETWORK.md`, `MEDIA.md`, `DEPLOYMENT.md` and `TAILSCALE.md`,
   all four linked from `CLAUDE.md` § Documentation, so a stub would add a fifth, emptier front door
   to a mapped system. `Architecture not yet mapped` is deliberately left standing and the count is
   asserted at **1**. **Revisit condition:** a structural change that none of the four existing
   documents covers — or a decision to make one of them the canonical architecture front door, which
   is a smaller edit than writing a fifth.
3. **`artifacts/06-43-conf04-verdict.txt` was not edited** — a dated record, and `DEF-06-45-04`'s own
   instruction, honoured. Proven against plan 06-48's captured base commit by **sha256** (`d85ebe4b…`
   both sides, cross-checked with a second implementation) rather than by an index-anchored
   `git diff`, because `HEAD` moved twice during that plan's own execution. `DEF-06-45-04`'s body
   digests identically too — it is closed by `DEF-06-48-01` **referring** to it, not by anything
   written into it. **Revisit condition:** none. Editing evidence to make a later reading true
   destroys its value as evidence.
4. **The bracketing convention was NOT widened to `ROADMAP.md`** — decided with reasoning in
   `DEF-06-48-02`, scoped **by function rather than by directory name**: any file whose content is
   counted by a published recipe must bracket the counted token. `ROADMAP.md` is deliberately readable
   prose and has never been inside a published detector's counted scope, so widening pays a
   readability cost for zero measurement benefit; dropping is equally wrong, because inside
   `artifacts/` the hazard is live and has fired in seven consecutive rounds. **No `ROADMAP.md` token
   edit was made or is required.** **Revisit condition:** the first detector whose counted scope
   includes a prose document — the convention follows the detector.
5. **No CONF-04 work of any kind** — no re-probe, no mtime touch, no refresh verb, no checkbox move.
   The mtime lever is a **measured negative** (`DEF-06-45-02`, round 5, BRANCH B) and must not be
   retried; the aggressive per-item refresh mode remains forbidden and unreached; CONF-04's Jellyfin
   half belongs to Phase 7 entry criterion **E6**, first measurement, and **E6's second measurement
   (the ≥4-artist MA discrimination) stays with Phase 7 on every branch**. `06-VERIFICATION.md` is
   explicit that *"no further action inside Phase 6 is warranted or safe"*.

---

## Corrections to the source material

A register that only repeats its source would lose these. Round 6 has three.

### 1. `06-REVIEW.md` § WR-02 quotes `check-beets-config.sh` at 1,223 lines; it measures **1,222**

Plan 06-49 re-measured with `wc -l` before writing the figure down and shipped the **measured**
number in `CONVENTIONS.md` convention 12, with the review's figure named beside it and one clause
saying the difference does not touch the finding. Restating an unverified number launders it — and a
conventions file quoting a stale count inside the entry *about* stale in-band counts would be
self-refuting. The other two figures in the same finding were re-measured and are **exact**:
`quick-health-check.sh` **3,148**, `phase06-oracle.sh` **3,274**; and `set -euo pipefail` really is at
line 124, so the review's "the first 123 are header comment" is correct.

`06-REVIEW.md` itself is a **dated record** and was deliberately not edited above its append point.

### 2. `06-REVIEW.md` § WR-03 fix (b) says "the repo's own `CONVENTIONS.md` is currently empty" — it was **absent**, not empty

The distinction decided plan 06-49's whole deliverable. `CLAUDE.md`'s `## Conventions` GSD block
**names its own source** in its opening marker (`source:CONVENTIONS.md`), and no such file existed at
the repo root. Writing the index into the generated block alone would have left the next regeneration
to overwrite or orphan it — so the **source** is the authoritative deliverable and the block is
downstream of it, which `CONVENTIONS.md`'s opening paragraph states. The review's wording is a small
misreading with a large consequence, and is recorded rather than silently worked around.

### 3. Plan 06-47's four-record consistency audit named **no** divergence owned by this plan

`artifacts/06-47-disposition-consistency.txt` records **0 DISAGREE** across `ROADMAP.md`, `beets.md`,
`deferred-items.md` and `REQUIREMENTS.md` on all five checks, and states in band that no owning plan
is named for `ROADMAP.md` (which would have been this plan) and none for `deferred-items.md`. **So
this register carries no correction from that audit, and that is a result rather than a silence.**

The judgement call 06-47 left standing is **dispositioned here as standing**: `deferred-items.md` is
**silent** on two of the five checks — the MA half being discharged, and the `REQUIREMENTS.md`
checkbox state — and is verdicted `COULD NOT LOOK`, not `DISAGREE`, with **no owning plan named**.
Silence is not contradiction, and manufacturing an owner for a non-divergence would have shipped a
phantom correction into this file. That reading is correct and this register adopts it.

**Also recorded, because it is the round's seventh consecutive instance and it fired inside the entry
describing it:** `DEF-06-48-02`'s first draft quoted its scratch control line **plainly**, so the
plan's own zero-expecting screen returned **1** instead of 0 — the entry had become an occurrence of
what it measures. Bracketed and re-measured at 0, with the scratch control keeping the plain form so
it still returns 1. Caught, as every previous instance was, **by measuring after the edit landed, not
by an assertion written beforehand** (`DEF-06-39-06`).

---

## ROUND CLOSE

**Not yet written.** This section is a deliberate placeholder, created at wave 3 by plan 06-50 so the
round's ending has a named owner rather than being an omission nobody notices.

**Owner:** plan **`06-52`, task 3**, running at wave 5 as the round's last act.

**Sources it must fold in:** `DEF-06-51-01` (R6-08 — the host `git pull --ff-only` sync, plan 06-51,
wave 4) and `DEF-06-52-01` (R6-09 — the snapshot-release go/no-go, plan 06-52, wave 5). Those two
`DEF-` entries are the authoritative fallback if this section is never filled.

**What `06-52` task 3 owes when it fills this section:**

1. The `R6-08` and `R6-09` rows of the mapping table, replaced with their real outcomes.
2. The § *Counts* reconciliation, **extended** with those two dispositions and re-stated — see the
   ⚠ paragraph in that section.
3. The `ROADMAP.md` Phase 6 status row's plan-count numerator, closed to `52/52` per `D-R6-M4`.
4. The `ROADMAP.md` `**Plans**: … plans in … waves` header, which is `06-52`'s and no earlier plan's.

Both `06-51` and `06-52` are `autonomous: false` and carry legitimate `halt` / `hold` branches. **If
the round halts, this section stays as written and that is the correct outcome** — an incomplete
record beats a wrong one.

---

## What this register does NOT do

**It changes no verdict, and it performs no verification.** No `/gsd-verify` run was made by plan
06-50 and **no verification result is claimed here**.

- **CONF-04 is NOT closed.** `.planning/REQUIREMENTS.md` is untouched by this plan — asserted with
  `git diff --exit-code HEAD -- .planning/REQUIREMENTS.md` — and `- [ ] **CONF-04**` stands, measured
  **1** unticked and **0** ticked, with the ticked recipe driven to **1** against a control first so
  the zero is the absence of a tick and not the absence of a working recipe.
- **No requirement checkbox moves**, `requirements mark-complete` was not run, and the `ROADMAP.md`
  Phase 6 status word still reads `In Progress` — the value `06-VERIFICATION.md` (`gaps_found`, 5/6)
  and plan 06-47's audit both say is the correct one.
- **The ROADMAP plan-count numerator is the executed count at the moment of the edit, not `52`**, per
  `D-R6-M4`. It is not this plan's job to close it.
- **The `**Plans**: … plans in … waves` header is untouched** and belongs to `06-52`.
- **`R6-08` and `R6-09` were recorded as `PENDING` at the time of writing, because they had not
  executed.** This register states no outcome for either: no commit the host moved to, no sha256
  verdict, no `proceed`/`halt` answer, no `hold`/`release`/`defer` answer. Their outcomes land in
  `DEF-06-51-01`, `DEF-06-52-01` and § *ROUND CLOSE*.
- **No script was edited by this plan** — `git diff --exit-code HEAD -- scripts/` returns 0.
- **Prior rounds' carried items stay carried.** CR-01's residue is owned by Phase 7 entry criterion
  **E10**, round 1's WR-09 by **E11**, and the undriven-until-the-pilot residue by **E12**. No `DEF-`
  entry from any round was renumbered, reworded or removed by this plan.
- **It adds no new Phase 7 entry criterion.** Round 6's residue lives in `DEF-06-48-01`,
  `DEF-06-48-02` and the two pending entries named above.
- **It does not re-open what is already owned** — the remaining `printf … | grep -q` SIGPIPE sites
  (`DEF-06-29-01`), the three un-rotated live secrets on LXC 100 (`DEF-06-29-09`), the stale host
  checkout (`DEF-06-29-11`, now `R6-08`'s subject), the undriven layer-3 block (`DEF-06-34-04`) and
  the SIGKILL residual (`DEF-06-34-06`) each already have an owner.
- **`06-VERIFICATION.md` was not re-scored.** It stands at `gaps_found`, 5/6, verified
  2026-09-24T15:11:55Z. Re-scoring is `/gsd-verify 06`'s call, not this plan's.

---

## Lessons — round 6's own, not earlier rounds' restated

### 1. The review that closes a recursion is the one whose largest finding is the cost of the record itself

WR-02 is not a defect in any branch. It is the accumulated weight of five rounds of honest
record-keeping, landing on the six files those rounds were most careful with. **The honest response is
a forward rule plus measured self-restraint, not a bulk rewrite** — because a bulk relocation across
`quick-health-check.sh` and `phase06-oracle.sh` is exactly the shape of diff that has become the next
round's findings every single time. Round 6 wrote **0** lines of new in-band historical narrative and
published the number.

### 2. A detector can publish a TRUE number and still be vacuous — and the true number is what hides it

`DEF-06-45-04`'s `-cF`-over-a-bracketed-needle recipe survived a full review pass, a verification pass
and five rounds, because the `0` beside it was **right about the estate**. `-F` and a bracketed needle
are mutually exclusive *by construction*: `-F` suppresses exactly the metacharacter interpretation the
bracketing mitigation depends on. **A true number from a vacuous instrument is the worst shape there
is, because it survives review.** The mitigation is now a rule (`DEF-06-48-01`, `CONVENTIONS.md`
convention 8): `-cE`, never `-cF`, and drive every zero-expecting recipe against a control that makes
it non-zero before publishing the zero.

### 3. A convention with an undecided scope drifts in whichever direction the next writer pushes it

The bracketing convention had been enforced inside `artifacts/` for six rounds and had never been
*decided*. The verification recorded two unbracketed occurrences in `ROADMAP.md` prose "for a future
round to fold in", which reads equally as *widen it* and as *you have a violation*. `DEF-06-48-02`
decides it — **scoped by function, not by directory name** — and states in the entry that **no
`ROADMAP.md` edit is made or required**, so nobody "finishes the job" later. **Scope is part of the
convention; a rule without one is an invitation.**

### 4. "Do not publish an outcome before it happens" has to be applied to EVERY record, not to the two you were looking at

Round 6's own cross-AI review found `STATE.md` still claiming a host sync and a snapshot decision that
had not happened, **after** this register and the ROADMAP had both been corrected to the two-step
PENDING treatment. The fix had been applied where it was being discussed and nowhere else, and
`STATE.md` is precisely the record the next session reads as *position*. Three records, one rule,
applied three times — and the PENDING prose in each is written as a **dated statement about the moment
of writing** so it does not go false the instant `06-52` fills the rows.

### 5. A plan that holds one pen must not assert a multi-record outcome

Plan 06-47 could edit `beets.md` and nothing else, so it **measured** what the other three records say
and named an owner for any divergence rather than claiming four records agree. It found none, and it
recorded a **silence as a silence** (`COULD NOT LOOK`) instead of counting it as agreement or
inventing an owner for it. Both moves kept a phantom correction out of this file.

---

_Register written 2026-09-24 by plan 06-50 (wave 3)._
_Source: `06-REVIEW.md`, reviewed 2026-09-24T15:08:05Z, depth standard, 12 files, `issues_found`,
no `diff_base` recorded; **no cross-family adjudication**._
_Gap closure round 6: plans 06-46, 06-47, 06-48, 06-49, 06-50, and — not executed at the time of
writing — 06-51 and 06-52._
_All measurements in this file answered by `/usr/bin/grep` (BSD grep), by absolute path, not the
operator's zsh `ugrep` alias._
