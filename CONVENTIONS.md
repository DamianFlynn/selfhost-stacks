# Conventions

**This file is authoritative.** `CLAUDE.md`'s `## Conventions` section is a GSD-generated
**mirror** of it — the marker that opens that section names this file as its source
(`GSD:conventions-start source:CONVENTIONS.md`), so when the two disagree, this file wins and the
mirror is the thing to fix. Until 2026-09-24 the mirror said *"Conventions not yet established"*
while this file did not exist at all; the conventions below were already being enforced by the
estate's instrument scripts and were recorded only inside those scripts' own headers.

This is an **index**, not a manual. Each entry is a rule, its reason in a clause or two, and a
**named canonical example** — a file plus a symbol or heading, **never a line number**. Line
citations in this repository go stale on arrival: the files carrying them are actively appended to,
and a previous round's verification shipped two citations that were already wrong. Every rule below
was read at its canonical example before being written down; where the code does not actually bear a
rule out, the entry says so rather than asserting it. A conventions file that describes intent
rather than reality is a defect this repository has already recorded.

---

## 1. Fail closed, and keep "could not look" distinct from "nothing is wrong"

Three states, not two. A check that cannot reach the thing it grades reports `UNKNOWN` and exits
non-zero — never `0 problems found`. The rule's source is `README.md` § *Health Checks* → *Design
rules these checks follow*, rule 1; it exists because a previous generation of checks printed a
green tick while blind.

**Canonical example:** `scripts/check-music-consumers.sh`, its `EXIT-CODE CONVENTION` header and the
`exit 3` pending state. Its three states are: red (`FAILURES` non-zero → exit 1), **pending** (read
successfully, sitting at its recorded baseline rather than its target → exit 3), and green. The
header states in full why `3` is neither: `FAILURES` is 0 on every exit-3 run by construction,
because the failure gate sits *above* the pending gate, and the green banner sits *below* it in
source order and is therefore unreachable while the pending count is non-zero.

**The consequence, and it is the point of the entry:** an exit code that cannot distinguish
"pending" from "failed" may never be published as a completion signal. `warn()` prints and touches
no counter, which is exactly how this script once printed the yellow *CONF-04 is not closed* block
and the green banner underneath it, and exited 0.

---

## 2. Bound remote commands Linux-side

The workstation is macOS and has no GNU `timeout`, so bounds go **inside** the remote command
string (`REMOTE_TIMEOUT`, default 120 s). A killed command surfaces as its own condition via exit
`124`. Source: `README.md` § *Health Checks*, rule 2.

**The specific trap:** `timeout N cmd | wc -l` **does not work** — `timeout` signals only the first
stage, `wc` counts the empty stream, and the pipeline exits `0`. The remote string needs
`set -o pipefail` **and** the ssh return code must be read. `${PIPESTATUS[0]}` does not rescue it:
an assignment is a simple command, not a pipeline.

**Canonical example:** `scripts/quick-health-check.sh`, the `bounded_ssh` helper. Read its
**KNOWN LIMIT** paragraph before reaching for it: it kills the ssh *client*, not the remote command,
so a remote `sleep` outlives it. It is for probes that have either already finished or never
started; use `REMOTE_TIMEOUT` for anything with side effects.

---

## 3. Assert, do not report

A value that is merely printed cannot fail the run. Anything that must not drift gets an explicit
expectation and increments `FAILURES` when it moves (`README.md` § *Health Checks*, rule 3).
Anything asserted must also be **proven able to fail** — driven red once, deliberately.

**Canonical example:** the tagger-definition census in `scripts/check-music-freeze.sh`. It does not
assert a count of two. It asserts `TAGGER_DEFS` against `TAGGER_DEF_EXPECTED` **and** the sorted
found set against `DEF_EXPECTED`, built from `TAGGER_DEF_FLASK` and `TAGGER_DEF_CLI` — so a bare
count of two whose **members differ** is a red, not a pass (D-11). Each member also carries a
`_CLASS` string, so the pass line names what each definition *is*, not just that it exists.

---

## 4. `${VAR:-default}` overrides are additive only — an override may only ever make a check redder

Overrides exist so a failure branch can be **driven** without editing a deployed file: an undriveable
branch is an unproven branch. They do not exist to silence a red, and there is deliberately no
success-producing override and no sentinel that skips a block anywhere in these scripts.

**Canonical example — a knob that obeys the rule by mechanism:** the `_Q`-rendered override guards
in `scripts/quick-health-check.sh` (`D04_DOC_BASELINE`, `D04_REPO_ROOT`, `D04_EXEMPT_BASELINE`,
`DRIFT_APPDATA_ROOT`, `DRIFT_REPO_ROOT`, `D03_REPO_ROOT`, `CONSUMERS_SCRIPT`, `EXTCONF_HOST`,
`EXTCONF_PATH`, `DASH_HOST`, `DASH_RESOLVE_IP`, `MUSIC_UNDERSCORE_HOST`, `MUSIC_UNDERSCORE_ROOT`).
Each guard is a one-line comparison against the default that prints *"override in effect — this run
cannot report … green"* and sets `EXIT_CODE=1` unconditionally. Setting a knob can therefore only
move the run toward red. That is the rule **enforced by mechanism**, and it is what this entry
illustrates. The same block's `⛔ DO NOT REUSE` paragraphs are part of the contract: three knobs
sharing one default path would let an override taken to drive one block's red branch silently move
another block's verdict.

### The one live exception, named rather than left implied

`DECLARED_INTERP_EXPECTED` in `scripts/check-music-freeze.sh` is the repository's one live
`${VAR:-default}` knob that does **not** obey the rule mechanically. Its own constant header says
so and accepts it:

> *"It can only ever move a green to a red or a red to a green BY DECLARATION — it resolves nothing
> and can never make an unparsed line parsed."*

Three things follow, and the entry states all three because the distinction is the whole reason the
exception is named:

- The knob's **capability is documented and accepted**. It is not a hidden bypass and it is not a
  new defect — the header argues at length why the inventory is pinned rather than blanket-refused
  (a permanently red check trains the reader to ignore it, which is the 01-09 trap).
- What governs it is therefore **policy, not mechanism**. Plan `06-46`'s remediation text, which the
  failure arm now prints, prohibits using the override to turn a red green and names its only
  sanctioned use — driving the failure branch.
- **A rule enforced by policy is weaker than one enforced by mechanism.** The two are not
  equivalent, and this file does not present them as if they were.

**Do not cite `DECLARED_INTERP_EXPECTED` as the canonical example of the redder-only rule.** It is a
counter-example the rule tolerates by declaration; writing it as the exemplar would make this file
contradict the source it cites.

---

## 5. Pinned counts: the trap, and the remedy

A count that gates pass/fail and must be hand-moved **in the same commit** as an unrelated change
elsewhere in the tree is a standing maintenance trap. The scripts fail loud rather than silently
when pin and measurement disagree, so this is not a fail-open risk — but the fix is not discoverable
from the failure message unless the convention is written down, which is what this entry is for.

**The live pins, by symbol:**

- `DECLARED_INTERP_EXPECTED` — `scripts/check-music-freeze.sh`, the pinned size of the
  interpolated-host-path inventory. Moves when any file under `stacks/selfhosted/` gains a
  `${VAR}/path:/dest` volume line, for reasons unrelated to this check.
- `TAGGER_DEF_EXPECTED` — `scripts/check-music-freeze.sh`, the named tagger-definition pair.
- `ST_PLANNED_CASES` — `scripts/check-beets-config.sh`, the announced self-test case count,
  compared against `st_cases`.
- `ST_PLANNED_CASES` — `scripts/phase06-oracle.sh`, the same idea over a much larger harness,
  compared against `ST_RUN`.

**The remedy, which the failure output now prints (plan `06-46`):** read every new line **by hand**
— they are invisible to the driving grep, so the section is `UNKNOWN`, not clean, until they are —
then move the pin in the **same commit** as the change that moved the count. Never set the
environment override to silence it. For `TAGGER_DEF_EXPECTED` the failure arm goes further and
refuses a bare count bump: a third definition must arrive as a `TAGGER_DEF_<NAME>` path constant
**and** a `TAGGER_DEF_<NAME>_CLASS` string, both added to the expected set.

**The harder rule this phase learned twice:** *a pin over a set with environment-conditional members
must adjust where the condition is decided, or it is a constant pretending to be an invariant.* A
fixed constant compared with `-ne` against a self-test that documents its own skips prints
*"A SECTION DID NOT RUN"* when every section ran — a false red with a wrong stated cause, firing
most readily on the machines least likely to be the operator's.

**Canonical example of the fix:** `scripts/phase06-oracle.sh`'s skip-aware decrements — each
environment-conditional arm decrements `ST_PLANNED_CASES` **beside the `warn` that reports its own
skip** — with the base constant's **named reference environment** stated beside it, because the
number is only valid in that environment.

---

## 6. The two-layer destructive-command fence is duplicated at each call site on purpose

Do not hoist it into one shared helper. A single shared fence is one edit away from being wrong
everywhere, and the duplication is what makes the self-test meaningful: the text driven by
`self_test_fences` is byte-for-byte the text that runs on the far side, not a restatement of it.

**Canonical examples:** `scripts/phase06-oracle.sh` — `SCRATCH_FENCE_SH`, `STAMP_WRITE_FENCE_SH` and
`STAMP_RM_FENCE_SH`, each concatenated in front of its own destructive program (`CLEANUP_PROG`,
`STAMP_WRITE_PROG`, `STAMP_RM_PROG`), fenced once where the value is accepted and again inside the
remote program via `remote_sh_c`; and `scripts/phase06-incremental-control.sh`, whose trap re-check
restates the same `[!A-Za-z0-9._-]*` class rather than importing it. That file's own comment records
the reason in one clause: *"The two files state ONE rule"*, and a claim stronger than its code *"is
precisely how the real fence eventually gets deleted as duplicated"*.

The two `REFUSED` wordings are also deliberately **different** between the scratch path and the stamp
path: `rm -rf` inside the container and `rm -f` on LXC 100 are different blast radii, and the
operator reading a refusal needs to know which one fired.

**⚠ Known trap, recorded as `DEF-06-29-03`:** a committed acceptance check counts fence *sites*, so a
future plan that legitimately shares one fence text — which would make drift structurally impossible,
strictly stronger than testing for it — will **fail** that check. Replace the site count with a
predicate over the property actually wanted before de-duplicating.

**Companion refusal:** `scripts/phase06-oracle.sh` carries **no cleanup `trap` anywhere**,
deliberately (`DEF-06-39-02`). One would fire on the forensic could-not-look `exit 3` arms too,
destroying the evidence they exist to preserve.

---

## 7. Credentials never enter argv

Use `-H @<(printf …)` process substitution, or stdin. Never a command-line argument, never a
here-string that lands in a transcript, and never echoed into an artifact. `curl`'s `-H @file` form
reads the header text from a file, so the secret is never visible in the process table.

**Canonical example:** `scripts/check-music-consumers.sh` — the Jellyfin key in `jellyfin_api` and
the Music Assistant token in `ma_api`, both passed as
`-H @<(printf 'Authorization: … %s\n' "$KEY")`.

---

## 8. Counted tokens are written bracketed — and only where something counts them

**The rule:** any file whose content is counted by a **published recipe** writes the counted token in
**bracketed** form — `EXIT-CODE BEHAVIOUR CHANGE[D]`, `EXTRA_FORBIDDEN_SUBSTRINGS:[-]` — so the
recipe is not itself an occurrence of what it measures. Writing a number into a file that greps
itself moves that number.

**The decided scope (`DEF-06-48-02`):** the convention is scoped by **function, not by directory
name**. `artifacts/` is simply where it is true today. Prose documents that no published detector
counts — `ROADMAP.md` among them — are deliberately **outside** the scope and stay readable; widening
to them would pay a readability cost for zero measurement benefit, and dropping the convention is
equally wrong, because inside `artifacts/` the hazard is live and has fired in six consecutive
rounds. The convention follows the detector, not the directory: if a future round publishes a
detector whose counted scope includes a prose document, it comes into scope then.

**Three hard sub-rules:**

1. **A bracketed needle requires `grep -cE` or `-ciE`. `grep -cF` with a bracketed needle can never
   match and is forbidden** (`DEF-06-48-01`, closing `DEF-06-45-04`). `-F` suppresses exactly the
   metacharacter interpretation the bracketing depends on; the two are mutually exclusive by
   construction. Driven both ways against a one-line control containing the real token: `-cE`
   returns **1**, `-cF` returns **0**.
2. **Verify a count AFTER writing it in band, never before.** The sentence stating the number is
   itself an occurrence. Every instance of this hazard so far has been caught by measuring after the
   edit landed, never by an assertion written beforehand (`DEF-06-39-06`).
3. **A recipe expected to return 0 must first be driven against a control that makes it return
   non-zero** (`DEF-06-45-04`). A `0` from an instrument that cannot detect is indistinguishable from
   a `0` that means clean — and a true number from a vacuous instrument is the worst shape there is,
   because it survives review.

**Canonical example:** the two census recipes in `scripts/quick-health-check.sh`'s
`EXIT-CODE BEHAVIOUR CHANGE[D]` notice block, with the ⚠️ paragraph stating that the final letter is
bracketed on purpose and must stay that way.

---

## 9. Grep hygiene

Use **`/usr/bin/grep` by absolute path** in any recorded measurement. The operator's zsh aliases
`grep` to `ugrep`, and a shell function that answers "no matches" when it was never consulted is a
false green. This is stated at the recipe block in `scripts/quick-health-check.sh` and is the reason
every recipe in that block is written with the absolute path.

Prefer the **comment-stripped** form over a raw count in any assertion that counts a token in a file
which also *discusses* that token:

```
/usr/bin/grep -vE '^[[:space:]]*#' <file> | /usr/bin/grep -c <token>
```

The corollary from the same block: **count the deliberate, countable act, not the prose.** A notice
*header* count is durable; the raw count is a side effect of prose and is deliberately not pinned
anywhere.

---

## 10. Byte-identity guarantees are anchored to a commit, never to the index

`git diff --exit-code <path>` compares the working tree with the **index**, so a *staged* edit passes
it silently. Driven in a scratch repository: with the edit staged, `git diff --exit-code p` exits
**0** while `git diff --exit-code HEAD -- p` exits **1**.

**Write every "this file is untouched" assertion as `git diff --exit-code HEAD -- <path>`.**

Where the guarantee is immutability **across a whole plan** rather than cleanliness at its end,
`HEAD --` is still not enough — a plan that commits moves `HEAD` too, and the assertion then compares
against the plan's own work. Anchor to a **base commit captured before the work starts** and compare
digests: `git show <base>:<path>` piped to a hash.

**Canonical example:** plan `06-48`'s treatment of `artifacts/06-43-conf04-verdict.txt` — base commit
captured by `git rev-parse HEAD` before anything was written, the digest read from
`git show <BASE>:<path>` and from the working file, and two independent hash implementations agreeing
so the digest is not an artefact of one of them.

---

## 11. The `📊 N. Summary` heading is a cross-file grep anchor

`scripts/quick-health-check.sh` folds in four subordinate checks and extracts each one's verdict with
`sed -n '/^📊 N\. Summary/,$p'`. **Renaming or renumbering one of those headings breaks a consumer in
another file.** Each fold-in carries an *anchor guard*: if the subordinate check exits as expected but
its summary block is not found, the fold-in reports `UNKNOWN` rather than assuming health — so the
failure mode is loud, but the coupling is real and is not visible from the file being renamed.

**Canonical example:** `scripts/quick-health-check.sh`, the `📊 6. Summary` and `📊 7. Summary`
extractions and their anchor guards, on both the exit-0 and the exit-3 arms.

---

## 12. In-band narrative: durable rationale stays, round-by-round history goes to the phase directory

**The rule, binding on everything written from here on:** a comment at a branch explains **why the
branch exists** and what would falsify it. The record of **which round changed what** belongs in
`.planning/phases/<phase>/` beside the artifacts, cited from the code by one short ID, not reproduced
in it.

**The measured cost that produced the rule** (`06-REVIEW.md` § WR-02; line counts re-measured
2026-09-24): `scripts/quick-health-check.sh` **3,148** lines, `scripts/phase06-oracle.sh` **3,274**,
`scripts/check-beets-config.sh` **1,222** — of which the first **123** are header comment before
`set -euo pipefail`. (The review states 1,223 for the third; the file measures 1,222 today. The
difference does not touch the finding, and the measured number is written here rather than the
quoted one.) There is today no separation between "why this exists" and "what changed in round N";
the two are interleaved at the same visual weight throughout.

**The corollary, stated explicitly: the existing narrative is NOT being stripped.** It is
load-bearing provenance — every fail-closed branch has a stated reason and a driven test — and
removing it in bulk would risk losing the reason a fail-closed branch exists, which is the one thing
this estate cannot afford to lose. This entry is a go-forward rule so the cost stops growing, not a
licence to delete. WR-02 is dispositioned ACCEPTED rather than retro-fixed; see `06-50` for that
reasoning.

---

## 13. Review ID namespaces are unique per round and chosen before the review is written

Reusing a prior round's namespace makes every grep for a finding non-discriminating **in exactly the
files carrying the citation** (`DEF-06-39-01`). Round 4's report reused round 1's `WR-*`/`IN-*`
namespace while 72 citations in that namespace were already live in band across the four reviewed
scripts, so round 4's fixes had to be written in band under an alias.

**This round's namespace is `R6-01` … `R6-09`.** Round 6's mapping table **will live** in
`06-DISPOSITIONS-GAP4.md`, which plan **`06-50`** writes — at wave 3, after this file is written.
That is a forward pointer, deliberately: a conventions file that asserts a future artifact in the
present tense is stale the moment the plan that would create it changes shape or halts.
