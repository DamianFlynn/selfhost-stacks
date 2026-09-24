---
phase: 06-tagger-configuration-and-dry-run
plan: 51
round: 6
wave: 4
status: complete
autonomous: false
gap_closure: true
requirements: [CONF-04, CONF-06]
requirements_completed: []
executed: 2026-09-24
---

# 06-51 — Host git sync of LXC 100, under a real pre-flight

## Outcome

**Complete, on the `proceed` branch, taken on a CLEARED pre-flight — not an override.**

`/mnt/fast/stacks` on LXC 100 moved `ee82fb2` → `b9c09b5`. The six instrument scripts are now
byte-identical between the repository and the deployed tree, proven per file by `sha256` on both
sides. Nothing was redeployed, proven on all three of name, image and status.

## The two-stage gate, which is the part worth reading

Task 1's read-only pre-flight returned **4 CLEAR and 1 STOP**. The clear four were real: tracked
tree empty, branch `main`, deployed commit a strict ancestor of repo HEAD, and an untracked
inventory containing **exactly** the two known debris paths and no third. What fired was **S4** —
three stash entries on a production checkout, dated 2026-03-09, 2026-03-09 and 2025-10-03, their
subjects naming production monitoring and proxy work, all three base commits still resolvable.
The gate therefore offered **no unqualified `proceed`**, only a recommendation to halt plus an
override path that would have been recorded as an override.

The operator took neither. Shown the finding, they took the third path the gate itself named:
**dispose of the entries, then re-run the gate.** Re-measured before any write, the stash list
returned EMPTY at rc=0 — a real empty, scored on its own class, not a could-not-look — and the gate
re-read **5 CLEAR / 0 STOP**.

⚠ **The override field is NO, and that distinction must survive into every downstream record.** An
override says *we wrote to a host we had measured as unsafe*. A clearing says *we made the host
safe, then wrote to it*. Equally, the fact that S4 fired at all is **not** erased: both stages are
in the artifact and in `DEF-06-51-01`, and `06-52` task 3 should carry both halves into the
register rather than a tidy clean-pre-flight narrative.

## What was measured

| | task 1 pre-flight | after the sync |
|---|---|---|
| `sha256`, six instrument scripts | **3 MATCH / 3 DIFFERS** | **6 MATCH / 0 DIFFERS** |
| container count | 99 | 99 |
| state census | 98 `Up` + 1 `Exited(0)` | 98 `Up` + 1 `Exited(0)` |
| created / restarting / paused / dead | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| stash entries | **3 (S4 STOP)** | 0 (CLEAR) |

The three that differed were exactly the three rounds 5 and 6 edited — `check-music-consumers.sh`,
`check-music-freeze.sh`, `quick-health-check.sh`. A matching commit hash would not have shown this,
which is why the plan demanded per-file digests.

The no-redeploy proof used the **normalised `name|image|status` triple set**, computed as a set
difference in both directions (empty each way), not asserted. `status` is the only field that moves
on a restart or a same-image recreation, so a name+image comparison would have let exactly that
event pass as "no redeploy".

## Deviations and corrections

1. **[Rule 1] The plan's commit-count was wrong and is corrected by measurement.** `D-R6-H3`'s
   preamble says the host was "20 commits behind". It was **40** at pre-flight and **41** at the
   push. Recorded in band in the artifact rather than silently used.

2. **[Execution mode] Task 2 ran INLINE, not in a delegated executor.** Two subagent dispatches
   were refused by the runtime's permission classifier, the second citing `[Remote Shell Writes]`.
   Rather than work around the refusal, the task was run inline so every host-writing command
   passed through the per-command permission gate with the operator present — a narrower grant than
   a standing subagent mandate. No safety rule of the plan was relaxed. Recorded because it changes
   who approved what.

3. **[Honesty] One comparator control was INVALID and is kept rather than replaced.** The first
   drive of the `sha256` comparator mutated the *filename* column, so nothing joined and it returned
   0 DIFFERS for the wrong reason — the `DEF-06-45-04` shape, occurring inside the drive meant to
   guard against it. A second, valid control (one digest mutated, filenames intact) returned 1.
   Both are in the transcript.

4. **[Honesty] The self-referential hazard fired twice more — ninth and tenth firings.** First in
   this task's prose *denials* ("No `--force`…", "no reset, no checkout -f"), which made the
   transcript an occurrence of what it measures and returned 2 on a screen that should read 0. Then
   **again inside the note written to explain the first**, because that note quoted both the
   offending text and the detector's own alternation. Caught both times by measuring after the edit
   landed, never by assertion; bracketed; re-measured to 0 on the third pass. The structural lesson
   is recorded in the artifact: a prose mention, a quotation of a prose mention, and a quotation of
   the *detector* are all indistinguishable to the detector.

## What this closes, and what it explicitly does not

**CLOSED:** `DEF-06-45-05` **item 2** — the deployed instruments are no longer behind the
repository, proven per file. `DEF-06-29-11` closes on the same measurement: the host is no longer
at a pre-Phase-6 commit, so a live run is no longer *uninformative*.

**NOT CLOSED:** `DEF-06-39-05` is **unblocked but not closed**. This plan deliberately did not run
`quick-health-check.sh` — its job was to make the instrument honest, not to take a measurement with
it. The script has now been executed **zero** times across rounds 3, 4, 5 and 6. A live run is the
natural next step for whoever wants it, and it will still exit non-zero on the pre-existing
`interpolated-host-path` gate if that inventory has moved — a known, documented red, not a fresh
finding.

`DEF-06-45-05` items 1 and 3 are untouched. **No requirement checkbox moved; CONF-04 was not driven
in any direction; `06-VERIFICATION.md` was not re-scored.** The `requirements:` frontmatter cites
CONF-04/CONF-06 for citation-defensibility, not completion.

**Disposition mapping for the register:** the closed four-word vocabulary has no `halt` entry, so
**halt → `CARRIED`** — recorded for completeness only. This plan did **not** halt, so `R6-08`'s
disposition is the proceed outcome, not `CARRIED`.

## Scope fences held

No ZFS snapshot taken, listed for decision, or destroyed — that is 06-52's decision. No `git stash`
subcommand run, locally or on the host. No compose verb issued; the only `docker` verb used in
either task was `ps`. No service restarted, no container created or removed. No `git cl[e]an` in any
form — the two removals were by name, one invocation per path, no glob, no `-r`. The pull was
`--ff-only`, so a divergence would have failed rather than merged. `scripts/sync-repo.sh` was
neither used nor edited. `scripts/` and `.planning/REQUIREMENTS.md` both return rc=0 under
`git diff --exit-code HEAD --`. Every remote command bounded Linux-side with its ssh return code
read; no timeout fired.

## Key files

- created: `.planning/phases/06-tagger-configuration-and-dry-run/06-51-SUMMARY.md`
- modified: `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-51-host-sync.txt` (task 1's transcript + the OPERATOR ANSWER section + the full task 2 record, 1,344 lines)
- modified: `.planning/phases/06-tagger-configuration-and-dry-run/deferred-items.md` (`DEF-06-51-01`)

## Commits

- `b9c09b5` — task 1, the measured host pre-flight; STOP condition S4 fired
- `4d8c5ae` — task 2, host synced to `b9c09b5` on a cleared pre-flight
- `DEF-06-51-01` commit — the deferred-items record

## Self-Check: PASSED

Plan's task-2 `<automated>` verify block re-run at HEAD: **PASS**. All three zero-expecting screens
over the artifact (forbidden docker verbs, the clean-verb literal, reset/force family) return 0, and
each was driven against a control returning non-zero first. Artifact is UTF-8 with no NUL bytes
(screened by byte-count delta across `tr -d`, not by the vacuous `grep -c $'\000'`). No credential,
key or secret reproduced.
