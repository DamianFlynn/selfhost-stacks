# Phase 6 — disposition register for `06-REVIEW.md`

**Written:** 2026-09-22 by plan 06-21 (wave 9).

## Why this file exists

`06-VERIFICATION.md` § Required Artifacts marks `06-REVIEW.md` **NOT WIRED** — *"The Critical
finding (CR-01) and all 10 Warnings remain unaddressed; no fix commit, no override, no
carry-forward reference."* Gap-closure plans 06-15 through 06-20 supplied the fixes. This file
supplies the part a fix commit cannot: a statement of what happened to **each** of the 24
findings, so the set cannot be lost at the next context boundary.

It is referenced from `06-REVIEW.md`'s appended block and from ROADMAP Phase 7 entry criteria
**E10** and **E11**, because an item recorded where the next phase does not read is an item
nobody owns.

## Source

| | |
|---|---|
| Source review | `.planning/phases/06-tagger-configuration-and-dry-run/06-REVIEW.md` |
| Reviewed | **2026-09-21T22:33:04Z** |
| `diff_base` | **db281a2** |
| Depth | standard; 11 files (6 shell, 5 YAML) |

## Counts

**Findings, as the review's own frontmatter records them:**

| class | count |
|---|---|
| critical | **1** |
| warning | **10** |
| info | **13** |
| **total** | **24** |

**Dispositions, by class:**

| disposition | count |
|---|---|
| FIXED | **19** |
| FIXED (undriven) | **4** |
| ACCEPTED | **0** |
| CARRIED | **1** |

**Reconciliation, stated so an arithmetic slip is visible rather than latent:**
19 + 4 + 0 + 1 = **24**, and 1 + 10 + 13 = **24**. The two totals agree.

**`ACCEPTED` is zero, and that is a finding in itself.** No review finding was judged not worth
changing. The one finding not changed — WR-09 — is `CARRIED` rather than `ACCEPTED`, because it
has a scheduled owner and a named decision point rather than a reason to leave it alone.

## The vocabulary, which is closed

Exactly four words are used. No other word appears in the disposition column.

- **FIXED** — a commit changed the behaviour **and** the changed branch was driven. Cites the
  plan, the commit and the artifact holding the driven transcript. For a change with no runtime
  branch (a header constant, a claim in prose) the file's own committed state is the observation,
  and the row says so.
- **FIXED (undriven)** — a commit changed the behaviour but the branch was **never observed
  firing** in this phase. Cites the plan, the commit, the artifact, **and** the condition that
  would drive it. This is the register's honest middle. It is not collapsed into FIXED, because a
  FIXED recorded for something only written manufactures confidence in a branch nobody has seen
  work.
- **ACCEPTED** — deliberately not changed, for one of exactly three reasons: the change would
  invalidate a committed proof artifact; the change requires running an instrument this gap
  closure is forbidden to run; or the finding's own text establishes it as hygiene with a named,
  working compensating control. Unused in this register.
- **CARRIED** — deferred by name, to a `DEF-06-21-NN` entry or a ROADMAP entry criterion that
  exists.

### How FIXED and FIXED (undriven) were separated

The test applied to every row was: **did a summary record the changed branch being observed to
fire?** Where a plan's own NOT-DRIVEN register named the item, that record governs (06-18 named
IN-06 and IN-11). Where no plan recorded a drive and the change sits inside a runtime branch that
no run reached, the row is `FIXED (undriven)` even though the plan did not itself use that phrase
— IN-03 and IN-07 are the two rows in that position, and both are flagged in `06-21-SUMMARY.md`
as this plan's judgement rather than a sibling's.

A drive over a **synthetic fixture** counts as driven; the evidence cell names the fixture, and
where a real-run drive is still outstanding it is recorded as residue rather than upgraded into
the disposition.

---

## The register — all 24 findings, in review order

### Critical

| ID | Defect, in one clause | Disposition | Evidence |
|---|---|---|---|
| **CR-01** | The D-04 "no bare `beet` invocation" assertion asserted over an **empty set** and printed a green tick, while a live violation sat in the repo it structurally could not see | **FIXED** | Two halves. **Live half** — plan **06-15**, commit `8d74d40`: all three `check-beets-config.sh` invocations carry `-l /tmp/p6-cbc-throwaway.blb`, and the throwaway library was *measured* to exist in the container (`53248` bytes, beetle-owned), so the real `/config/library.db` was never **opened**, not merely never changed. Artifact `artifacts/06-15-check-beets-config-rerun.txt`. **Detector half** — plan **06-16**, commit `5f4d0c0`: pattern widened (local regex *and* the remote `git grep`, which was case-sensitive and returned none of them), executable count **0 → 8**, vacuity guard `elif [ "$D04_N_EXE" -eq 0 ]` added, exemption register `D04_EXEMPT_RE` / `D04_EXEMPT_BASELINE=5` named and pinned. Driven **six times live**; pre-fix and post-fix transcripts taken in the same minute against the deployed estate. Artifact `artifacts/06-16-d04-driven.txt`. **Residue carried to ROADMAP E10** — see below. |

**CR-01's residue, carried not closed.** Three things survive the fix and are named in ROADMAP
Phase 7 entry criterion **E10**: the exemption register is a *pinned baseline* that Phase 7 must
revisit rather than inherit; the block reports **UNKNOWN on the live estate** until the operator
pushes and the host pulls (correct, and expected); and the ✅ green line itself is
**asserted by construction, not observed** (06-16 N-1) — against the real tree the executable
count is genuinely 0, so the guard correctly refuses, and against a scratch tree the additive
override correctly refuses. Also carried: 06-16 N-4, the overlay-key half of `D04_EXEMPT_RE`,
which 06-16 nominated as the register's weakest link — `DEF-06-21-06`.

### Warnings

| ID | Defect, in one clause | Disposition | Evidence |
|---|---|---|---|
| **WR-01** | An in-container pipeline made an unreadable scratch directory read as "absent or empty" — a could-not-look reported as the green answer | **FIXED** | Plan **06-19**, commit `bc81d5d`. The file's one in-container pipeline is gone, replaced by `SCRATCH_PROBE_PROG`, which reads `find`'s status with `out=$(…) || exit 4` and answers with a **word** (`absent` / `empty` / `notadir` / `nonempty <entry>`) so emptiness of stdout is never evidence. Driven red in `--self-test` over local `/bin/sh` using the file's existing WR-08 technique: the old shape returns **rc 0 and empty output for BOTH an empty and an unreadable directory**, byte-identical — measured, which is what made this a real defect. Artifact `artifacts/06-19-oracle-vacuity-driven.txt`. Residue: the container's dash, `docker exec`'s propagation of exit 4, and a `$SCRATCH` unreadable by `beetle` specifically (06-19 N-1) — a refusal path, so a wrong construction can only refuse a run that would otherwise proceed. |
| **WR-02** | The oracle's `manifest_compare` had no empty-file guard — two empty manifests reported "identical before and after", satisfying layer 2 of the wrote-nothing proof by having measured nothing | **FIXED** | Plan **06-19**, commit `bc81d5d`. The sibling's `-s` guard copied into `manifest_compare` with its reason text **verbatim** rather than paraphrased. Measured by lifting the same function bodies out of the real file at both commits and feeding one fixture: rc **0** ("identical before and after") at `92512d5`, rc **2** with the vacuity reason after. Reachable with a *clean* ssh status, since `find -type f -printf` returns rc 0 and no output on an existing empty directory. Artifact `artifacts/06-19-oracle-vacuity-driven.txt`. Driven over a synthetic fixture; a drive from a real oracle run is residue (06-19 N-2). |
| **WR-03** | The D-22 artist-entity rows could not fail the run — `check-music-consumers.sh` exited 0 and printed the green banner while CONF-04 was measurably open | **FIXED** | Plan **06-17**, commits `dc0fd47` (the exit-3 gate, the header register, the branch comments) and `b79b902` (the `quick-health-check.sh` fold-in arm, the TWELFTH notice, `CONSUMERS_SCRIPT`). Driven live **in both directions**: rc **3** with the green banner *provably absent* (`grep -c` = 0 on the transcript), and — forcing both counters to zero on a **copy** — rc **0 with** the banner, so the gate is proven to release as well as to block. Tracked file sha256 `1ed695cf…` identical either side. Pending counts predicted from `06-14-SUMMARY.md` before the run and agreed at all four positions (JF pending 3, MA reported 1, `FAILURES` 0). Artifact `artifacts/06-17-conf04-exit3.txt`. **Read the fix correctly:** no `warn()` call site was routed into `FAILURES` — all ten remain advisory. The fix is a third exit code, not a promotion; collapsing pending into red would destroy the distinction the file exists to preserve. |
| **WR-04** | `touch` does not truncate — arm 2's "no-op overlay" was only no-op if nothing else had written to it | **FIXED** | Plan **06-15**, commit `8d74d40`. The overlay is created with `: >` (a POSIX redirect, so nothing need be installed in the container) **and its size is asserted 0**. Both fail-closed branches driven red live and kept distinct per README § Health Checks rule 1: **branch A** (could not look) — the overlay path replaced by a directory, exit 1, no `config` call; **branch B** (measured non-empty) — a `touch`-mutant **copy** against a planted 44-byte overlay, exit 1, `measured '44' bytes, not 0`, which drives precisely the regression WR-04 described. The header's *"nothing is written"* claim now names its one exception. Artifact `artifacts/06-15-check-beets-config-rerun.txt`. |
| **WR-05** | `check-beets-config.sh` opened the real `library.db` three times per run with no `-l` — a rule violation the CR-01 detector could not see | **FIXED** | Plan **06-15**, commit `8d74d40`. `-l /tmp/p6-cbc-throwaway.blb` ahead of `-c ${OVERLAY}` on all three invocations, so the D-29 layer-3 hash comparison upgrades from *proving nothing changed* to *corroborating that nothing was opened*. Self-test case **6** asserts the `-l` + `-c` contract over the script's **own source** and is proven falsifiable — stripping `-l` from one real invocation takes it to 2 red and `--self-test` to exit 1. Exactly 3 compliant invocations survive comment-stripping. Artifact `artifacts/06-15-check-beets-config-rerun.txt`. |
| **WR-06** | `report_multi_artist` returned 0 on an unreadable input, so `run_assert` printed a green tick whose text said the instrument did not look | **FIXED** | Plan **06-19**, commit `bc81d5d`. Returns **2** and routes to `unknown()`. Measured by lifting the same six definitions out of the real file at both commits: before — `✓ CONF-04 write side: the fields TSV is missing or unreadable…` with `UNKNOWNS=0`; after — `⚠ UNKNOWN, not green: …` with `UNKNOWNS=1`. **The counter is the half that matters**: before the change that branch could not affect the verdict at all. Scope extended deliberately — the **empty**-input branch also returns 2, since zero rows counted out of an empty file is a could-not-look wearing a different hat. The double report at the two sites is **kept**, with the second saying in band that it is a restatement: the sites report different conditions, and suppressing the second would make the `CONF-04 write side` label vanish from the transcript on exactly the input it cannot judge. Artifact `artifacts/06-19-oracle-vacuity-driven.txt`. |
| **WR-07** | Env-overridable paths were interpolated **unquoted** into remote `rm -rf` / `rm -f`, so `SCRATCH='/tmp/p6 /config'` word-split into a command deleting the real `library.db`, `state.pickle` and the vendored config | **FIXED** | Plan **06-18**, commit `7c2e349`. Literal `case` allow-lists on `SCRATCH` and `STAMP_REMOTE`, evaluated before the script's first ssh in **every** mode, and **duplicated inside** the two remote programs adjacent to the `rm`. The allow-list constrains the *suffix* to `[A-Za-z0-9._-]`, not just the `/tmp/p6-*` glob — a bare glob still admits `/tmp/p6-x /config`, the exact word-splitting shape the fence exists to refuse. "Before any ssh" is **measured, not asserted**: `ssh` was replaced on PATH by a poisoned stub that records and never connects, and the log is empty across all four fence refusals including under `--baseline`, with the counter itself controlled by an allowed value that *does* reach ssh. Artifact `artifacts/06-18-oracle-fence-driven.txt`. Residue: the **receiving-layer** fence inside the remote programs is reachable only if the two allow-lists drift apart — which is the drift the duplication exists to survive (06-18 register, WR-07 (a)). |
| **WR-08** | `printf '%q'`-quoted paths were embedded inside single-quoted remote `sh -c '…'` strings, so an apostrophe in a folder name broke the command | **FIXED** | Plan **06-18**, commit `89a349b`. `remote_sh_c` puts every remote path across the ssh → docker exec → dash boundary as a **positional parameter** rather than as program text. Driven in `--self-test` against an apostrophe-and-`$` fixture, **paired** with a DRIVEN RED showing the old construction failing. The `find` argv is proven **byte-identical** to the pre-change value, `-printf` format included (proven with a stub `find` that prints its own argv, not argued), so the committed 174-destination artifact stays comparable. Reverting `remote_sh_c` in a copy turns six of seven new cases red. Artifact `artifacts/06-18-oracle-fence-driven.txt`. Residue: the construction against the **live** GNU `find` awaits the next real `--run` (06-18 register, WR-08 (b)). |
| **WR-09** | `import.write: yes` is live in the vendored config while `/downloads` is mounted `:rw` and the `01-auto` inbox is registered `autotag: auto` under an always-restarting watchdog — and **none of the three controls the config names covers that mount** | **CARRIED** | Owned by **`DEF-06-21-01`** and **ROADMAP Phase 7 entry criterion E11**; stated in the runbook at `stacks/selfhosted/arrs/beets.md` § *Still open at Phase 6 close*. **Why carried rather than fixed:** the review's stronger option is `import.write: no` in the vendored `config.yaml`, and **any** edit to that file changes the sha256 of the exact object every CONF-01 / CONF-02 / CONF-05 assertion in this phase was measured against, plus the appdata copy the vendored-drift block compares. That is a dependency conflict with a committed proof, not a judgement that the fix is hard (threat T-06-125). What actually bounds the exposure today is that nothing automatic stages into `_inbox/` and that `tank/downloads@pre-phase5` is un-released (**E4**) — and *"nobody has put a file there"* is not one of the three controls the file claims. The decision is scheduled beside the `rw` grant (**E3**), Phase 7's first act, where every other Phase-7 behaviour flag already moves. |
| **WR-10** | The D-04 remote scan converted a `timeout` kill (124) into exit 4, making the block's dedicated 124 branch unreachable and attributing a wedged host to a broken `git grep` | **FIXED** | Plan **06-16**, commit `5f4d0c0` (landed in task 1 rather than task 2 because the 124 test and the pattern widening edit the same six-line `D04_CMD` string; task 2's verify still checks it). **DRIVEN** as control 4, with a negative control showing the pre-fix script reporting `ssh exit 4` for the same condition. Artifact `artifacts/06-16-d04-driven.txt`. |

### Info

| ID | Defect, in one clause | Disposition | Evidence |
|---|---|---|---|
| **IN-01** | `expect_ne()` was defined and never called | **FIXED** | Plan **06-15**, commit `4aaf79a`. **Retained and called**, not deleted — the `UK` check routes through it and its load-bearing sentence (*"MusicBrainz stores GB, so UK matches nothing and fails SILENTLY"*) survives word for word. `grep -c '\bexpect_ne\b'` now returns **4**. The UK check moved **inside** the readable-list branch so an absent `match.preferred.countries` is counted once rather than twice; this is what keeps all five existing self-test red counts unchanged (22, 1, 1, 2, 0). Exercised by `--self-test`. Artifact `artifacts/06-15-check-beets-config-rerun.txt`. |
| **IN-02** | `remote_is_blind()` was defined and never called | **FIXED** | Plan **06-20**, commit `18b25e0`. **Deleted, not routed through.** The function tested `RE_RC` in `{124, 2, 255}` while every caller tests `-ne 0`, which also catches 1, 125, 126 and 127 — adopting the narrow test would have been a regression dressed as a cleanup on an instrument whose entire value is failing closed. The wider inline test stays; a comment at the old site records the reason and the rule for any future helper (at least as wide as `-ne 0`, **and called**), deliberately not spelling the identifier so the grep guard keeps reading 0. Occurrences **1 → 0**, driven as a mutation. Artifact `artifacts/06-20-incremental-driven.txt`. |
| **IN-03** | The readiness-gate failure message overstated how long it waited (30s rendered, 25s actually slept) | **FIXED (undriven)** | Plan **06-15**, commit `4aaf79a`; artifact `artifacts/06-15-check-beets-config-rerun.txt`. The arithmetic is corrected to `$(( (READY_ATTEMPTS - 1) * READY_SLEEP ))`. **Undriven because** the corrected text lives inside the readiness-gate *failure* branch, and every run in this phase reached ready, so the branch was never observed firing. **Condition that would drive it:** five consecutive failed readiness probes against `beets-flask` — i.e. run the script with the container stopped, and read the message. Carried as **`DEF-06-21-04`**. |
| **IN-04** | The header named a constant that does not exist (`EXEC_USER` vs `EXEC_USER_FLAG`) | **FIXED** | Plan **06-15**, commit `8d74d40` — landed in task 1 rather than task 2 because the paragraph naming the non-existent constant is the same paragraph task 1 had to rewrite to document `THROWAWAY_DB`; leaving a known-wrong constant name inside a paragraph being rewritten was not defensible. Task 2's verify still checks and passes it. **No runtime branch exists** for this finding — it is a claim in the header, so the committed file's own state is the observation. Artifact `artifacts/06-15-check-beets-config-rerun.txt`. |
| **IN-05** | `--arm` with no value exited 1 silently, and 1 is the code the exit table reserves for a **measured** failure | **FIXED** | Plan **06-20**, commit `18b25e0`. `shift 2` is gone from the dispatch entirely (audited — `--arm` was the only one, and the verify asserts the idiom's absence); the dispatch shifts once unconditionally, takes a value only if present, and validates against `a\|b`, routing both failure modes through `usage_error()` to **stderr and exit 3**. Measured before/after: pre-fix `exit 1`, silent; post-fix `exit 3` with `--arm requires a value…`, and `--arm zzz` → `exit 3` with `'zzz' is not a legal arm…`. Artifact `artifacts/06-20-incremental-driven.txt`. |
| **IN-06** | Predictable, non-unique temp paths inside the container | **FIXED (undriven)** | Plan **06-18**, commit `89a349b`; artifact `artifacts/06-18-oracle-fence-driven.txt` § 10. The in-container temp files beneath `$SCRATCH` carry the run's PID (`lib.$$.db`, `overlay.$$.yaml`, `state.$$.pickle`); `$SCRATCH` itself is deliberately unchanged so every path the fence, the precheck and the committed 06-11 artifacts name stays true. **Undriven because** `--self-test` never reaches step 5, which is where those names are used. **Condition that would drive it:** the next real `--run`. Recorded as undriven by plan 06-18 itself. Carried as **`DEF-06-21-02`**. |
| **IN-07** | `EXTRA_FORBIDDEN_SUBSTRINGS` was expanded unquoted, so it globbed as well as split | **FIXED (undriven)** | Plan **06-15**, commit `4aaf79a`; artifact `artifacts/06-15-check-beets-config-rerun.txt`. Replaced with `IFS=':' read -r -a forb_arr <<<"$EXTRA_FORBIDDEN_SUBSTRINGS"`, so field splitting happens and pathname expansion does not. **Undriven because** the whole loop sits behind `if [[ -n "$EXTRA_FORBIDDEN_SUBSTRINGS" ]]` and the knob's default is empty, so no run in this phase entered it. The defect was additive-only (it could add spurious failures, never suppress real ones), which is why it was never observed. **Condition that would drive it:** a run with `EXTRA_FORBIDDEN_SUBSTRINGS` set to a value containing `*` or `?` from a cwd holding matching filenames — the old form expands it against the tree, the new form does not. Carried as **`DEF-06-21-05`**. |
| **IN-08** | The two sibling scripts disagreed on whether RED or UNKNOWN wins | **FIXED** | Both halves, and neither was marked satisfied before the other landed. **Incremental control** — plan **06-20**, commit `1bcf229`: the verdict tail factored into `arm_verdict()` so the ordering is a named, driveable decision, blind consulted first, matching the oracle; an EXIT CODES block stating the convention, its one-sentence reason and naming the sibling, bounded by a `# ====` delimiter; `--self-test` § 7/7 drives the full **2×2 precedence truth table**. **Oracle** — plan **06-19**, commit `cfec2ec`: the same convention stated in its EXIT CODES block, naming the incremental control back. The house convention is **a blind instrument outranks a measured red**, because reporting a red while an instrument was blind asserts a cause the run did not establish. Artifacts `artifacts/06-20-incremental-driven.txt` and `artifacts/06-19-oracle-vacuity-driven.txt`. **The exit-code NUMBERING difference is deliberately untouched** — see § Deliberate non-findings. |
| **IN-09** | `assert_dj_count` had no vacuity guard, unlike its neighbour — a sample whose S5 rows sum to 0 compared `0 -ne 0` and passed | **FIXED** | Plan **06-19**, commit `cfec2ec`. Refuses a zero wanted count as **VACUOUS** in its neighbour's own vocabulary, and names `DEF-06-12-01` — path rule 2, the only `paths:` rule no Phase 6 instrument has evaluated. Measured before: `✓ DJ/ destinations = 0, exactly the sampled DJ file count`. `grep -c VACUOUS` (comment-stripped) now returns 5 against the plan's floor of 2. Every new guard ships with a **passing partner** in the same transcript, because a guard that refuses everything invites its own removal. Artifact `artifacts/06-19-oracle-vacuity-driven.txt`. Driven over a synthetic fixture; a real-run drive is residue (06-19 N-2). |
| **IN-10** | The re-offer classifier hard-coded a path count of 1, so any multi-album source fell through to `indeterminate` → BLIND | **FIXED** | Plan **06-20**, commit `18b25e0`. The count now reads as any non-negative integer; only the count widened, and the three outcomes plus the `indeterminate` fall-through for genuinely unrecognised output are unchanged. The classifier was **lifted out of `run_arm` into `classify_reoffer()`** — while inline it could only be reasoned about, never fed an input. **Driven as a pair**, because widening a pattern and proving only the new case is how a widening becomes a regression: count 1 unchanged (`not-offered`), counts 2 and 17 fixed (`indeterminate` → `not-offered`), and `Album:`-only, both-markers, unrecognised and **empty** all unchanged — the empty transcript notably does **not** pass vacuously. The `blind` message was reworded, since a message a reader takes as the rule must not describe a rule the code no longer applies. Artifact `artifacts/06-20-incremental-driven.txt`. |
| **IN-11** | No cleanup trap — an aborted run leaves a copy of the real `library.db` in the container and a stamp on the host, and the next run's refusal presents as unexplained | **FIXED (undriven)** | Plan **06-18**, commit `7c2e349`; artifact `artifacts/06-18-oracle-fence-driven.txt` § 10. The dirty-destination refusal now prints the exact cleanup command and states that `--baseline` always leaves the host stamp **by design**. **Undriven because** reaching it needs a genuinely dirty `$SCRATCH` inside the live container. **Condition that would drive it:** a `--run` aborted between step 5 and step 12, leaving `/tmp/p6` populated inside `beets-flask`, then a second invocation. Recorded as undriven by plan 06-18 itself. Carried as **`DEF-06-21-03`**. |
| **IN-12** | An empty field view was reported as a pass — `✓ field view read: 0 items, six columns each` | **FIXED** | Plan **06-19**, commit `bc81d5d`. The judgement was **factored out** into `assert_field_view()` rather than guarded in place, precisely so an empty `fields.tsv` could be fed to it — inline, the branch could never be driven. An empty view is now a refusal saying the view was **NOT PRODUCED**, instead of a tick asserting that every one of zero items had six columns. Artifact `artifacts/06-19-oracle-vacuity-driven.txt`. Driven over a synthetic fixture; a real-run drive is residue (06-19 N-2). |
| **IN-13** | The D-03 CLI-render branch hard-coded the checkout path its sibling had just made overridable, so its `exit 3` was the one path in the two new blocks that could not be driven to red | **FIXED** | Plan **06-16**, commit `18b06a5`. `D03_REPO_ROOT` added with the same additive contract as `DRIFT_REPO_ROOT` and `D04_REPO_ROOT` — it can only make the verdict redder. **DRIVEN** as control 5: UNKNOWN, **not** a pass. Artifact `artifacts/06-16-d04-driven.txt`. This is the third of four knobs added in `quick-health-check.sh` for the reason the file states in full and plan 06-17 quoted again: *an undriveable branch is an unproven branch*. |

---

## Deliberate non-findings — recorded so they are not re-reported

Three things look like findings on a fresh read and are not. Each was examined and left alone on
purpose.

1. **The exit-code NUMBERING difference between the two sibling instruments.**
   `phase06-incremental-control.sh` uses UNKNOWN=2 / usage=3; `phase06-oracle.sh` uses UNKNOWN=3 /
   usage=2. **IN-08 was about precedence, not numbering**, and the precedence is now fixed and
   stated in both. Renumbering would invalidate committed evidence that cites those codes. Left
   alone deliberately by plan 06-20 and confirmed by plan 06-19 (06-20 register item 6; 06-19
   register item 7).
2. **The D-04 block reports UNKNOWN on the live estate.** Correct and expected: `/mnt/fast/stacks`
   is at `c67d497`, pre-Phase-6, so the executable count there is genuinely 0 and the new vacuity
   guard rightly refuses. It clears on the operator's `git push` plus a host `git pull --ff-only`
   and on nothing else (06-16).
3. **`quick-health-check.sh` will exit non-zero on the consumers block** from the moment this phase
   is pushed and the host pulls, and will stay non-zero until Phase 7 entry criterion **E6**
   discharges CONF-04. **Intended. Do not tune it out** — the twelfth notice says so inline (06-17).

## What this register does NOT do

**It changes no verdict.** No CONF-04 disposition, no requirement checkbox, no phase-status
wording is altered by plan 06-21. `REQUIREMENTS.md` is untouched and `- [ ] CONF-04` stands.
CONF-04's two verdicts — **Jellyfin pending, Music Assistant discharged** — are recorded
separately and **are never summed**. The measurements taken for E6 on 2026-09-22 were: Jellyfin
pending **3**, Jellyfin at target **0**, Music Assistant reported **1**, Music Assistant at target
**2**, `FAILURES` **0**. ROADMAP entry criterion **E6** still owns the discharge.

## A systemic finding about the plans, not the code

Worth recording because it is the clearest cross-plan signal this phase produced: **all six
gap-closure plans found defects in their own plan's `<verify>` blocks — every one**, and 06-19
found three distinct shapes in two blocks simultaneously. Two plans introduced a fresh instance of
the class while fixing it. This is a **planner-side** defect class, not an execution one. The
recurring shapes, and this plan hit two more of them (see `06-21-SUMMARY.md`):

- `grep -q` downstream of a pipe under `set -o pipefail`, propagating **141** — a false-RED
  generator that fires exactly when the file is correct;
- `\$\{…\}` inside a double-quoted bash string going vacuous under BSD grep — a false-GREEN
  generator;
- a bare `'` inside a `bash -c '…'` body, which closes the body;
- **unbounded `awk` ranges**, where the start pattern recurs later in the file;
- case-sensitive greps against FULL-CAPS emphasis;
- **acceptance criteria naming a string or artifact that does not exist**.

Related: plan line citations went stale in four consecutive plans as siblings edited the same
files — 06-17's were off by ~175 lines, 06-19's by 200–300. `grep -n` on anchor text is the
reliable route; a cited line number is not. Carried as **`DEF-06-21-08`**.

---

_Register written 2026-09-22 by plan 06-21._
_Source: `06-REVIEW.md`, reviewed 2026-09-21T22:33:04Z against `diff_base` db281a2._
_Gap closure: plans 06-15, 06-16, 06-17, 06-18, 06-19, 06-20, 06-21._
