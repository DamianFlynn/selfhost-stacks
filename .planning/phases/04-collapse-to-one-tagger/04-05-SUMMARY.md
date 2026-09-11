---
phase: 04-collapse-to-one-tagger
plan: 05
subsystem: docs
tags: [docs, sweep, d-07, d-14, d-24, tagr-03]

# Dependency graph
requires:
  - phase: 04-collapse-to-one-tagger
    provides: "04-03's repo deletions (wrtag/soulbeet definitions) and PRE_DELETION_SHA 5d0af70"
  - phase: 04-collapse-to-one-tagger
    provides: "04-04's D-14 wording in CLAUDE.md and STACK.md, reused byte-identically here"
  - phase: 03-tagger-spike
    provides: "03-WRTAG-EVIDENCE.md § The corrected pin-inversion proof; 03-DECISION.md § Handoff to Phase 4"
provides:
  - "beets.md carries the D-14 correction with the Phase 3 sentence verbatim and the measured 'unpinning buys nothing' table"
  - "beets.md's Discogs standing action carries a dated D-24 dismissal in-band; the original text and its four causes stand"
  - "beets.md header and banner no longer link to or assert facts about files deleted in 04-03"
  - "the interim D-07 sweep verdict table: every non-.planning hit has a verdict and an owning plan"
  - ".gitignore's narrowness example names a file that still exists; both tracked beets configs proven unmasked"
  - "scripts/spike03-wrtag-arms.sh kept with the reproduction route for a recorded measurement"
affects: [04-06, 04-07, 04-10, 04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A comment-only edit to a script is proven comment-only by a diff filter plus a zero-removed-lines count, and proven harmless by running the script's own --self-test"
    - "When an edit removes the last match of the grep that an acceptance criterion counts, record both the pre-edit and post-edit denominators rather than reporting the post-edit one as if it were the baseline"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-05-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets.md
    - .gitignore
    - scripts/spike03-wrtag-arms.sh

key-decisions:
  - "The D-14 sentence is reused byte-identically from what 04-04 committed to CLAUDE.md and STACK.md, so the three copies cannot drift"
  - "The retired Renovate rule is paraphrased and never quoted, so its reversed cause/effect wording is not reproduced in a new place"
  - "beets.md's 'Two beets, one library' table is NOT rewritten: it describes runtime state that only becomes true after 04-11. One dated Superseded line points at 04-13"
  - "The host and workstation stacks/selfhosted/music/.env files are LEFT IN PLACE. This plan has no host-runtime action and no mandate to delete them; handed to 04-07"
  - ".gitignore's replacement example does not spell the deleted path even as history, because that would have left the dead filename in the file the plan required to stop naming it"

requirements-partial: [TAGR-03]

# Metrics
duration: ~25min
completed: 2026-09-11
---

# Phase 4 Plan 05: Land the D-14 Correction and Sweep the Stale References Summary

**The durable estate record now carries the corrected cause of the wrtag pin verbatim, and answers
the Discogs question with the operator's own dismissal rather than an open action nobody closed.
Every stale `wrtag|soulbeet` reference outside `.planning/` has a verdict and a named owner.**

## Performance

- **Duration:** about 25 min
- **Tasks:** 2 of 2
- **Files:** 3 modified (plus this SUMMARY)

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | beets.md: header/banner links, D-14 verbatim correction, D-24 amendment | `0a94212` |
| 2 | .gitignore example, spike03-wrtag-arms.sh keep-with-reason note, D-07 sweep | `4d62a9d` |

## What changed, per file

### `stacks/selfhosted/arrs/beets.md` (+68 / −4)

Four hunks. **Exactly four lines were removed** — the three "Companion to …" header lines and the
one banner line. **No table row appears as a removed line** (`git diff | grep '^-.*|'` = 0).

- **Header (lines 3-5).** The links to `soulbeet.yaml` and `soulbeet/beets_config.yaml` are gone.
  The replacement names all three deleted files as deleted by plan 04-03 on 2026-09-11 (D-01/D-05)
  and gives `5d0af70` as the last commit containing them, with a working `git show` recovery form.
- **Banner (line 13).** It previously asserted *"Both beets definitions now mount the library `:ro`,
  and wrtag's library mount is deleted"* — a claim about definitions that no longer exist. It now
  states that the definitions are deleted from the repo, that the one survivor mounts `:ro`, and
  that **host runtime retirement has not happened yet**, naming 04-07 and 04-11 as its owners. The
  original "Nothing in this document's advice will write …" sentence is unchanged.
- **"Two beets, one library" (the table).** **Not rewritten**, as the plan directs. One dated line
  added above it: *"Superseded by Phase 4 (2026-09-11) — rewritten in § Phase 4 when the runtime
  change lands (plan 04-13)."*
- **New section `### Correction: the wrtag pin's stated cause was reversed (2026-09-11, Phase 4
  D-14)`**, placed after the existing 981-990 in-band correction. It paraphrases the retired rule
  (never quotes it), names the two innocent fields (`.Release.Date.Year`, `.Release.Media`, both
  present at v0.20.0), states the two real defects (`d.Track.Position = -1` forced at
  `pathformat.go:113-115`; `.Media` absent from v0.20.0's `Data` struct, lazily gated so startup
  validation never caught it), carries the D-14 sentence verbatim, and adds the three-row
  "unpinning buys nothing" table from 03-DECISION § *Handoff to Phase 4*. It cites
  `03-WRTAG-EVIDENCE.md` § *The corrected pin-inversion proof* — a link that resolves.
- **Standing action (Discogs).** The heading is untouched and the original text stands in full. A
  dated blockquote is prepended: *"Dismissed by the operator 2026-09-06, Phase 4 D-24"*, the
  operator's words verbatim, "a choice, not an oversight or a silence", and pointers to PROJECT.md
  § Key Decisions and DEF-03-21. **No action was taken on the token, and no rotation step exists in
  this plan.**

### `.gitignore` (+3 / −1)

Line 45's "cannot mask a legitimate tracked config such as …" example named
`stacks/selfhosted/music/wrtag.yaml`, deleted by 04-03. It now names
`stacks/selfhosted/arrs/sabnzbd/beets-config.yaml`, which is tracked and present. The
`import-xcheck.yaml` and `**/beets-config/*.yaml` rules are **byte-unchanged**.

### `scripts/spike03-wrtag-arms.sh` (+31 / −0)

A dated `KEPT AFTER PHASE 4 (2026-09-11)` block added after the existing header. **31 added lines,
every one a comment; zero removed lines; zero executable lines changed.** It records why the script
is kept (Phase 3 criterion-3 instrument, cited by `03-WRTAG-EVIDENCE.md`), that its `WRTAG_YAML`
default now points at a deleted file, the `git show 5d0af708…:stacks/selfhosted/music/wrtag.yaml`
restore plus `WRTAG_YAML=` override that reproduces a recorded arm, and that the `renovate.json5:91`
citation names a rule deleted in Phase 4. Neither stale reference is repaired in place, because
repairing either would silently change what the recorded arms measured.

## Interim D-07 sweep verdict table

Commands, run after this plan's edits:
`git ls-files | grep -v '^\.planning/' | xargs grep -il 'wrtag\|soulbeet'` and
`git grep -nE 'library\.blb|line 285|beets\.log|01-09 folds|Two beets|soulbeet\.deercrest'`.

**This is the interim table. The final sweep is 04-13's**, which must find zero hits left in the
"correct — pending" state.

| # | File | Hits | Verdict | Reason | Owner |
|---|---|---|---|---|---|
| 1 | `.gitignore` | 45 before; **0 after** | **corrected** | Example named a file 04-03 deleted. Replaced with the tracked sabnzbd config. It left the grep as a result of this correction | **04-05 (done)** |
| 2 | `CLAUDE.md` | 27 lines | **corrected** | D-07/D-14 landed; no instruction to keep, fix or unpin wrtag; D-14 sentence verbatim; generator parity proven | 04-04 (done) |
| 3 | `renovate.json5` | 428, 457 | **keep-with-reason** | The rule itself is deleted. Both remaining hits are deliberate references to *"the retired wrtag <0.30.0 pin, deleted in Phase 4"* inside the Jellyfin and beets rule descriptions, cited as exactly why an `allowedVersions` ceiling is the wrong instrument. Deleting them removes the reasoning, not a stale fact | 04-03 (done) |
| 4 | `scripts/spike03-wrtag-arms.sh` | 66, incl. the `WRTAG_YAML` default | **keep-with-reason** | Phase 3 criterion-3 instrument cited by `03-WRTAG-EVIDENCE.md`. Deleting it destroys the reproducibility of a recorded measurement. Dated header note added naming `5d0af70` | **04-05 (done)** |
| 5 | `stacks/selfhosted/arrs/beets.md` | header 3-5, banner 13 | **corrected** | Links and moot assertions fixed; D-14 and D-24 landed | **04-05 (done)** |
| 6 | `stacks/selfhosted/arrs/beets.md` | 35-57 table (incl. `soulbeet.deercrest.info` at 49), 102, 247, 279, 290 | **correct — pending** | The table describes runtime state that is only true after 04-11; rewriting it now would make the page wrong in a new way. Dated Superseded line added. The 247/279/290 hits are inside **dated evidence blocks** (an executed 2026-08-18 `check-music-freeze.sh` transcript) and are **keep** — historical output is never edited | **04-13** |
| 7 | `stacks/selfhosted/arrs/beets.md` | 968 | **keep** | Inside the dated Phase 3 section; correct against what it measured | — |
| 8 | `scripts/check-music-freeze.sh` | 80 (`TAGGER_PATTERN`), 252; widened: 9, 53 | **correct — pending** | D-21 replaces name-based classification with mount-based, and the pattern names two taggers this phase deleted | **04-06** |
| 9 | `scripts/spike03-image-headroom.sh` | 112 (`KEEP_PATTERNS "sentriz/wrtag"`) | **correct — pending** | It protects the retired wrtag image from ever being reaped. Removed in the same plan that reaps the image | **04-07** |
| 10 | `stacks/selfhosted/arrs/sabnzbd.yaml` | 93; widened: 57, 59, 89 | **correct — pending** | The `arrs/soulbeet.yaml` shape reference, the "line 285" description (false after the strip) and the "01-09 folds that comparison in" claim (false today, F6) | **04-10** |
| 11 | `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` | 13; widened: 5, 7, 110 | **correct — pending** | Consumer header names a caller that stops existing after the strip; `plugins:` line is TAGR-05's | **04-10** |
| 12 | `scripts/normalise-dj-tags.py` | 1331 | **keep-with-reason** | Cites `spike03-wrtag-arms.sh` as the style analog for its `--self-test` table. That script is kept (row 4), so the reference resolves | — |
| 13 | `scripts/freeze-music-apply.sh` | 256, 263, 277 (widened only) | **keep-with-reason** | Phase 1 tool. The `library.blb` names are **discovered at runtime, never hard-coded** (its own comment says so), and the `.bak` naming discussion describes pre-project files that still exist | — |
| 14 | `.planning/**` (72 files) | — | **keep** | Provenance. Never rewritten | — |

### Row-count arithmetic (the acceptance criterion, stated honestly)

The criterion asks that the row count equal the `wrtag|soulbeet` non-`.planning` file count plus the
widened-grep files. **This plan's own edit changes that denominator**, so both values are recorded:

- **Before any edit:** 10 files matched (`.gitignore`, `CLAUDE.md`, `renovate.json5`,
  `check-music-freeze.sh`, `normalise-dj-tags.py`, `spike03-image-headroom.sh`,
  `spike03-wrtag-arms.sh`, `beets.md`, `sabnzbd.yaml`, `sabnzbd/beets-config.yaml`).
- **After:** **9.** `.gitignore` dropped out because removing the dead path removed its only
  `wrtag` string — it is still row 1, because it is a file this plan corrected.
- **Widened grep adds one file** not already in that list: `scripts/freeze-music-apply.sh`. The
  other four widened files are already rows 6, 8, 10 and 11.
- **9 + 1 (`.gitignore`) + 1 (`freeze-music-apply.sh`) + 1 (`.planning/**`) = 12 files**, carried as
  **14 rows** because `beets.md` is split into three rows with different verdicts and owners
  (corrected / correct-pending / keep). Splitting is deliberate: one verdict per file would have
  forced a single wrong answer for a file that genuinely has three.

## The host `stacks/selfhosted/music/.env` verdict

**Verdict: LEAVE IN PLACE. Owner: 04-07.**

04-03 handed this to 04-05. **This plan does not delete them**, for reasons that are about mandate,
not caution:

- This plan's `files_modified` is three documentation/config files. It has **no host-runtime action
  at all** — no ssh step, nothing that reaches LXC 100. Deleting a host file from a docs plan would
  be an unmandated, irreversible act outside its stated scope.
- Neither file is a tagger definition. TAGR-03 is about definitions in git, and **nothing under
  `stacks/selfhosted/music/` is tracked** (`git ls-files` on that path is empty).
- Both are ignored, not untracked-and-pending: `.gitignore:1 **/.env` and `.gitignore:11
  *.env.backup`. `git status` on the directory is empty, so they cannot be committed by accident.
  The public-repo exposure risk is already closed.
- **Their contents were never read or printed**, per the plan's instruction.

On the workstation: `.env` (336 B, 2026-01-22) and `.env.backup` (336 B, 2026-03-05). 04-RESEARCH
§ *Secrets / env vars* records that the variables these files carry (`SOULBEET_SECRET_KEY`,
`WRTAG_API_KEY`) are **referenced only by the YAML that 04-03 deleted**, so removing them is
optional hygiene and **nothing breaks if they are left**. 04-07 owns host teardown and should
dispose of the host copy there; the operator may delete the workstation copies at will.

## Acceptance

| Check | Result |
|---|---|
| Task 1 `<verify>` chain | `1` / `1` / `0` — **pass** |
| `grep -c 'works on none of v0.20.0, v0.33.0 or v0.34.0'` beets.md | **1** (byte-identical to the CLAUDE.md and STACK.md copies 04-04 committed) |
| `grep -c 'Track.Position = -1'` beets.md | **2** (≥ 1 required) |
| Dead-link grep `\]\((\.\./)?(soulbeet\.yaml\|soulbeet/beets_config\.yaml\|\.\./music/wrtag\.yaml)\)` | **0** |
| Every markdown link target in beets.md resolves | **4 targets, 0 MISSING** (`beets/beets.yaml`, `03-DECISION.md`, `03-WRTAG-EVIDENCE.md`, one anchor) |
| `Standing action, carried forward` heading still present | **1**, at line 1055 |
| `Dismissed by the operator` precedes the original text | line **1057** precedes `**Rotate the Discogs…**` at **1070** |
| beets.md removed lines / removed table rows | **4** (the 3 header lines + 1 banner line) / **0** |
| Table hunk | `@@ -28,0 +37,2 @@` — a pure insertion (Superseded line + blank). No table body line altered |
| Secret screen on beets.md added lines (40-char runs; `user_token\|discogs.env\|/secrets/\|token=`) | **0** / **0** |
| Task 2 `<verify>` chain | `music/wrtag.yaml` = **0**, `bash -n` **exit 0**, `KEPT AFTER PHASE 4` = **1**, survivor config.yaml **not masked** — pass |
| `beets-config/*.yaml` and `import-xcheck.yaml` rules | **1** / **1**, byte-unchanged |
| `git check-ignore` on both tracked beets configs | **no output, rc=1** (neither is masked) |
| **Driven positive control:** the rules still fire | `import-xcheck.yaml` → `.gitignore:51`; `…/beets-config/anything.yaml` → `.gitignore:52` |
| spike03 comment-only diff filter | **empty**; non-comment added lines **0**; removed lines **0** |
| **Driven check:** `spike03-wrtag-arms.sh --self-test` | **exit 0** — all fence cases (incl. the CR-01 bypass and the symlink escape) and all five WR-13 manifest cases behaved as expected |
| `git show 5d0af708…:stacks/selfhosted/music/wrtag.yaml` | **rc=0**, returns the file — the reproduction route in the header note works |
| STATE.md / ROADMAP.md sha256 vs wave baseline | **identical**; `git diff 890fe2d HEAD --` on both is **empty** |
| Post-commit deletion check, both commits | **0 deleted files** |

## Deviations from Plan

### 1. [Self-caught error, fixed before commit] The first `.gitignore` draft kept the dead path

- **What:** my first edit replaced the example but added a parenthetical reading *"The previous
  example named stacks/selfhosted/music/wrtag.yaml…"*. That would have left
  `grep -c 'music/wrtag.yaml' .gitignore` = **1**, failing both the plan's `<verify>` and its
  acceptance criterion.
- **Why it mattered beyond the grep:** the point of the change is that the file stops naming a file
  nobody can open. Preserving the dead name as history defeats it.
- **Fix:** rewritten to describe the replaced file without spelling its path. Caught by reading my
  own edit against the acceptance criteria **before** staging; the defective text was never
  committed.

### 2. [Defective instrument, self-caught] The "pre-edit count at HEAD" command did not read HEAD

- **What:** I ran `git ls-files | grep -v '^\.planning/' | xargs grep -il …` a second time intending
  to capture the pre-edit denominator. `git ls-files` lists paths but `grep` reads the **working
  tree**, so it re-measured the edited files and returned **9**, not the pre-edit **10**.
- **Resolution:** the genuine pre-edit value is taken from the first sweep run, executed before any
  edit, which listed 10 files including `.gitignore`. **The bogus 9 is not reported as a baseline
  anywhere**; the arithmetic section states both values and which run produced each.

### 3. [Bounded] The "one added Superseded line" is one line plus a blank

- The table hunk is `+37,2`: the Superseded line and the blank line markdown requires to terminate
  the blockquote before the paragraph. No table body line was altered.

### 4. [Placement] `beets.md` gets three sweep rows, not one

- The plan's table shape is one row per hit. `beets.md` genuinely has three different verdicts with
  two different owners (corrected here / pending with 04-13 / keep-as-historical). Collapsing them
  would have recorded a single wrong answer. The file-count arithmetic is stated separately so the
  criterion remains checkable.

**Total:** 1 self-caught error fixed pre-commit, 1 self-caught defective instrument recorded rather
than relied on, 1 bounded clarification, 1 table-shape choice. No file outside the plan's three was
touched.

## Truthfulness notes

- **No host runtime state is claimed as done.** The banner explicitly says retirement has not
  happened and names 04-07/04-11. The images, appdata trees and the `wrtag.deercrest.info` DNS
  record were not inspected by this plan and are not asserted either way.
- **Nothing was pushed.** These two commits are local; `origin/main` and LXC 100 remain at
  `d08842c`. Git is the delivery path, so nothing in this plan has reached the host.
- The D-14 sentence in `beets.md` was verified byte-identical to the copies 04-04 committed, so the
  three do not drift.

## Requirements

- **TAGR-03:** its documentary half is advanced, not completed. The durable estate record now
  carries the corrected cause; the remaining `correct — pending` rows belong to 04-06, 04-07, 04-10
  and 04-13.
- STATE.md and ROADMAP.md were **not** touched, and no `gsd-sdk query state.*` or `roadmap.*` verb
  was called (orchestrator instruction).

## Known Stubs

None.

## Threat Flags

None. **T-04-05-01** mitigated: the D-24 amendment carries no token value, prefix, path or file
content — only the decision and the operator's words — and the added lines were screened for
40-character runs and secret-path strings (0 each). **T-04-05-02** mitigated:
`spike03-wrtag-arms.sh` is kept, and the pre-deletion SHA reproduction route was **executed**, not
just written down. **T-04-05-03** mitigated: `git check-ignore` proves neither tracked beets config
is masked, and a driven positive control proves both ignore rules still fire.

## Self-Check: PASSED

- FOUND commits `0a94212` and `4d62a9d` (`git log`). Post-commit deletion check: **0** deleted
  files in each.
- FOUND `stacks/selfhosted/arrs/beets.md`, `.gitignore`, `scripts/spike03-wrtag-arms.sh`, each
  re-grepped **after** writing for the strings in the Acceptance table.
- Working tree clean of anything this plan did not write; `stacks/selfhosted/music/.env` and
  `.env.backup` left untouched and unread.
- STATE.md and ROADMAP.md sha256 unchanged from the wave baseline.
