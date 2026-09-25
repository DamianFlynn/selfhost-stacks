---
phase: 07-pilot-12-albums-end-to-end
plan: 05
subsystem: quality-gates
tags: [d-30, e12, d-09, def-06-29-04, def-06-29-05, def-06-12-01, phase06-oracle, check-beets-config, dj-path-rule-2, pre-grant]
requires: []
provides:
  - "the first live `phase06-oracle.sh --run` after the Phase 6 hardenings, taken PRE-GRANT (RW=false, library.db at fbbdde0c…): exit 0 GREEN, zero-diff, 174/174 pairs"
  - "E12 confirmations 1-3 CONFIRMED on real material (layer3 keys parse both sides; CLEANUP_PROG refuses 4/4 under the container's dash with a surviving canary; no p6-mf/p6-taghist litter); confirmation 4 (GC-15 space path) left PREDICTED, not driven"
  - "the live arm-1 dump size: 5977 bytes against the 65536-byte GC-01 ceiling, and the pre-grant C1 reading (copy=true, move=false, write=true) for 07-08"
  - "DJ path rule 2 evaluated by an instrument for the first time: 10/10 destinations DJ/Various Artists/<album>/0[12]-NN <title>.mp3, no defect shape"
affects: [07-08, 07-09]
tech-stack:
  added: []
  patterns: ["canary-targeted drive of a destructive fence: the refusal cases aim at a sentinel owned by the same user the rm runs as", "parsed-value config assertion (yaml.safe_load, `is False`, realpath prefix) with doctored-input parser controls", "listing recipes driven against a planted control before an empty listing is believed"]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-05-oracle-run.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-05-rule2-assertion.txt
  modified:
    - scripts/check-beets-config.sh
decisions:
  - "The oracle ran with OUT overridden to a fresh directory, so layer3.before/after are unambiguously this run's (the default OUT held an earlier run's files)"
  - "E12 confirmation 4 is recorded as not driven, predicted UNKNOWN + exit 3, with a dated caveat that R3-03/R4-09 changed the consumer after DEF-06-29-05 was written, so the parse side now predicts a MATCH; the send side is unmeasured either way"
  - "Rule-2 source manifests were measured on atlantis as real root and stored on LXC 100 under /mnt/fast/safety/phase07/rule2/, beside 07-02's phase-7 state (atlantis has no phase07/ directory)"
  - "Rule 2 folder = Mastermix_Issue_403, first of the seven by LC_ALL=C; disctotal=2 on all 10 files, so no fallback"
metrics:
  duration: "~10 min wall-clock (22:47Z-22:57Z, 2026-09-25)"
  completed: 2026-09-25
  tasks: 3
  files: 3
---

# Phase 7 Plan 05: Pre-Grant Oracle Run, arm1 Size, and the DJ Rule-2 Class Assertion Summary

The oracle's Phase 6 hardenings have now been exercised on live material, before the library became
writable. The oracle's `--run` exited 0 GREEN with zero diff. Its destructive cleanup program was
driven end to end under the container's `dash` against a canary: it refused all four hostile
arguments, and the canary survived. The arm-1 dump size is now recorded: 5,977 bytes, about 9 % of
the GC-01 pipe ceiling. DJ path rule 2 has been rendered for the first time and came out correct:
`DJ/Various Artists/Mastermix Issue Vol. 403 (January 2020)/01-01 … 02-05 …`.

## What was done

- **Task 1: live oracle, pre-grant (commit `d39af8a`).** Preconditions held at 22:48:06Z: `/media`
  RW=false, `library.db`/`state.pickle` at the fixture hashes `fbbdde0c…`/`f6a9a1ad…`, and the
  container's `/bin/sh` resolves to `/usr/bin/dash`. `--self-test` ran 140 cases and exited 0.
  `--run` exited 0 GREEN, with the full transcript recorded. It showed 174 pairs == 174 files, zero
  diff, all nine class assertions green, layers 1–3 clean, and the `-newer` sweep at 0. The E12
  confirmations:
  1. **CONFIRMED.** Both `layer3.*` files parse with the oracle's own awk, giving four non-empty
     64-hex values.
  2. **CONFIRMED.** `CLEANUP_PROG` was extracted by symbol (sha256 `1d3f04f7…`) and sent through
     `dex_cmd`+`remote_sh_c`. It printed `REFUSED` with exit 3 on all four arguments. The sentinel
     `/tmp/p7-canary/keep` survived, even though it was owned by `beetle`, the user the `rm` runs
     as. The positive probe on `/tmp/p6-p7probe` returned `gone`.
  3. **CONFIRMED.** The listing recipe listed a planted control on LXC 100 and on the workstation.
     The post-run listings were empty on LXC 100, inside the container, and on the workstation.
  4. **Not driven; predicted** (with the dated caveat above).

  The real state hashes were unchanged at the end.
- **Task 2: arm1 size (commit `8bee310`).** One line was added after the `arm1.dump` copy:
  `info "arm1.dump bytes: …"` (diff +1 −0, no `beet` token). The self-test still reports 7 cases
  with 6 red and exits 0. A live run exited 0 with 0 failures and gave `arm1.dump bytes: 5977`.
  Against the 65,536-byte ceiling in `06-22-pipefail-141.txt`, that is 91 per mille, with 59,559
  bytes of headroom. So GC-01 was latent and never close to firing. The pre-grant C1 reading for
  07-08 is `import.copy=true`, `import.move=false`, `import.write=true`, all from arm 1.
- **Task 3: rule 2 (commit `7e1cc71`).**
  - **Folder:** `Mastermix_Issue_403`, the first of the seven by `LC_ALL=C`. It is exactly one
    directory, and `mediafile` shows `disctotal=2` on all 10 files.
  - **Before import:** atlantis-root sha256 and `%P\t%s\t%T@` manifests were taken. The effective
    config was asserted on parsed values: write, copy and move are each `False` by `is False`, and
    library and statefile resolve under `/tmp/p6-p7rule2/`. The parser controls were driven: a
    doctored `move: yes` gave FAIL (exit 8), and a missing key gave STOP (exit 9).
  - **Run:** `import -A -q --set albumtype=dj`, then `move -p` with both `-l` and `-c` (ad hoc, not
    committed).
  - **Checks:** the negative recipes were driven first against four controls, and each was detected.
    Then all ten checks passed on the 10 captured destinations, with both discs present and the
    literal `02-05` row present.
  - **Afterwards:** scratch was removed through the fenced `CLEANUP_PROG` (`gone`). The source
    manifests are byte-identical before and after, with mtime also identical. The real hashes are
    unchanged, and `config.yaml` has no diff.

## Deviations from Plan

None that changed scope. Four small execution notes:

- **Task 1 got its own commit.** The plan named commits only for tasks 2 and 3. Task 1 was committed
  separately to keep one commit per task, and the task 3 commit carries only the rule-2 artifact,
  since the oracle artifact was already committed.
- **The first workstation listing ran under zsh.** Its NOMATCH aborted the `ls` before it listed
  anything. Both halves (the control and the post-run listing) were re-run under bash, and the
  artifact records both attempts.
- **The overlay carries extra keys.** Besides the plan's keys, it sets `autotag/resume/incremental: no`,
  `duplicate_action: keep` and `ui.color: no`, copied from the oracle's own overlay so it matches
  the proven shape. Nothing was relaxed.
- **An observation, not a finding.** Titles containing `:` render with `_` (beets' default
  `replace:`). This applies to every rule and is not a rule-2 defect, so nothing was added to
  `deferred-items.md`.

## Notes for downstream plans

- E12 is satisfied except for GC-15's space-path send side, which stays a prediction. GC-05's live
  vacuity arms were not exercised either, because this sample holds DJ files and Various Artists
  destinations, so neither D-13 nor D-15 was vacuous.
- The oracle has now had its one pre-grant run. After 07-09's grant, `assert_media_readonly` and
  `FIXTURE_LIB_SHA256` will go red by design (C7/C8).
- **LXC 100 state:** `/mnt/fast/safety/phase07/rule2/` holds four small manifest files (about 3.6 KB)
  as evidence, and nothing else was left behind.

## Self-Check: PASSED

- FOUND: .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-05-oracle-run.txt
- FOUND: .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-05-rule2-assertion.txt
- FOUND: scripts/check-beets-config.sh (exactly one `arm1.dump bytes:` line)
- FOUND commits: d39af8a, 8bee310, 7e1cc71
- 823fe04 remains an ancestor of HEAD
