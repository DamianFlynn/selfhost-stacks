---
phase: 04-collapse-to-one-tagger
plan: 13
subsystem: docs
tags: [closure, interim-status, docs, sweep, renovate-observation, census, d-25, d-07, d-30]

# Dependency graph
requires:
  - plan: 04-12
    provides: "04-D12-EVIDENCE.md section 6 filled with exactly one verdict line, `Verdict: OPEN`, and the measured mechanism for why no valid PRE-HOOK snapshot exists"
  - plan: 04-11
    provides: "both guards promoted into the routine fatal path, so a no-env run of check-music-freeze.sh prints the census unprompted; the 36-file deletion ledger that made `beets databases: 1` true"
  - plan: 04-09
    provides: "the criterion-4 pair (0 vs 1 MusicBrainz candidates) and the record that 04-09 was NOT D-30's deliberate redeploy — the host stayed on 2.13.1-ls349"
  - plan: 04-05
    provides: "the interim D-07 sweep table, its owners, and the recorded 10 -> 9 denominator change"
provides:
  - "stacks/selfhosted/arrs/beets.md carries `## Phase 4 — interim status (2026-09-13): criterion 3 OPEN` — NOT a closure — with the executed census pasted ANSI-stripped from a routine run"
  - "the final D-07 sweep: 8 files in the wrtag|soulbeet sweep and 6 in the widened sweep, every hit with a verdict, ZERO gap rows"
  - "the D-30 Renovate outcome OBSERVED: the expected ls350 patch automerge never happened and now cannot — upstream moved to 2.14.0-ls352, a MINOR, correctly routed to manual review and additionally rate-limited"
  - "DEF-04-01: the orphaned 'beets has no undo command' correction deferred IN WRITING to Phase 7, with the reason it was not fixed here"
affects: [phase-verification, phase-05, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A section headed as a closure must not sit on top of an OPEN criterion: the heading is chosen by a machine-readable verdict line, and the mapping is enforced by the plan's own verify"
    - "When a `tail` truncates the very line an acceptance criterion names, re-run the producer and capture it rather than inferring it from the exit code — an exit code that is 0 for several reasons cannot stand in for the line that says which"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/deferred-items.md
    - .planning/phases/04-collapse-to-one-tagger/04-13-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets.md

key-decisions:
  - "beets.md gains an INTERIM STATUS section, never a closure. The verdict line is OPEN, and REVIEWS row 6 is explicit that a closure heading over an OPEN criterion is the defect to avoid"
  - "The clean side effects of 04-12's two jobs (no beets state regenerated, zero SUCCESS lines, 25/25 byte-identical) are recorded as weaker, separate evidence and were NOT used to upgrade criterion 3"
  - "The orphaned 'no undo' item is DEFERRED in writing rather than fixed: this plan's mandate is one file, and CLAUDE.md:152 sits inside the generated GSD project region whose source is PROJECT.md, so a one-file edit reverts on regeneration"
  - "tagger-capable containers: 2 (sabnzbd + lidarr) is documented in beets.md as the EXPECTED value with the reason, so a later reader does not read it as a defect and narrow the classifier"

requirements-advanced: [TAGR-03, TAGR-04, TAGR-05]
requirements-completed: []  # TAGR-04's behavioural half remains unsatisfied: criterion 3 is OPEN.

# Metrics
duration: ~15min
completed: 2026-09-13
---

# Phase 4 Plan 13: Interim Status, the Final Sweep and the Renovate Observation Summary

**Criterion 5 is now a measured fact sitting beside the stack, from a routine run that needed no
environment variable to print it — and the section that records it is headed `interim status`, not
`closure`, because criterion 3's verdict is OPEN and a closure heading over an OPEN criterion is
exactly the failure REVIEWS row 6 exists to prevent. The D-07 sweep closes with zero gaps; the
Renovate observation is that the expected patch automerge never happened and now cannot, which is a
finding rather than a green tick; and the one item in this phase with no owner is deferred in
writing with a named destination rather than dropped.**

## Performance

- **Duration:** ~15 min (2026-09-13 ~12:35Z → ~12:50Z)
- **Tasks:** 2 of 2
- **Files:** 1 repo file modified, 1 created (plus this summary). No host state was changed — this
  plan read the estate and wrote documentation.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Executed census run → beets.md interim status; living-text correction | **`a0fa259`** |
| — | The orphaned DEF-04-01, deferred in writing | **`60b7b8c`** |
| 2 | Final D-07 sweep, Renovate observation, full suite | **none** — measurement only; no sweep hit owned by this plan remained (the plan's own `<files>` says "none unless a sweep hit owned by this plan remains") |

**Plan metadata:** this SUMMARY's own commit.

## Delivery

| Item | Value |
|---|---|
| Workstation HEAD before | `90581f3` (the orchestrator's wave-7 tracking commit) |
| Pushed at plan start | `763b851..90581f3  main -> main` — origin was **behind** the workstation |
| Host `/mnt/fast/stacks` HEAD before | `763b851` |
| Host HEAD after `git pull --ff-only` | **`90581f3`** (fast-forward, `pull_rc=0`) |
| Host porcelain | the same 2 pre-existing untracked files before and after — `prometheus.yaml.bak`, `monitoring.app.yaml.disabled`. Not mine, untouched |

Every host-side measurement below ran against host HEAD `90581f3`, re-derived inside the same
command rather than assumed.

---

## THE HEADLINE: this is an interim status, not a closure

`04-D12-EVIDENCE.md` carries **exactly one** line matching `^Verdict: (PASS|OPEN|FAIL)`
(`grep -cE` = **1**, at line 184) and zero `PENDING` markers. It reads:

> `Verdict: OPEN — two music jobs completed in the window and every other pass condition held, but
> neither job has a valid PRE-HOOK snapshot: job A's was taken after its `Matching` line and job B's
> cannot be ordered against its own, so the "untagged by bytes" condition of § 1 item 4 is UNPROVEN
> and § 5 requires OPEN rather than PASS.`

So `beets.md` gains **`## Phase 4 — interim status (2026-09-13): criterion 3 OPEN`**. Measured on
the written file: interim heading count **1**, `## Phase 4 — one tagger` count **0**.

**The phase is not closable, and `/gsd-verify-work` must treat criterion 3 as the open gap.**

**What the section says about criterion 3, and what it deliberately does not say.** It states in
plain words that the phase is not closed; quotes the verdict; and then gives the mechanism, because
"OPEN" without the mechanism invites a future reader to assume incompetence rather than a structural
instrument limit. SABnzbd moves a finished job into `complete/nzb/music/` and **then** invokes the
hook, so a watcher on the destination tree can never sample before the hook — and one of the two
jobs ran hook-start to completion in **one second**, against a contract requiring a *stable*
snapshot (two agreeing passes ≥ 2 s apart). The section names the two fixes (snapshot in
`incomplete/` before the move, or drop the stability wait) and says explicitly that **both are
watcher changes and the estate needs nothing**.

**What was NOT done, on purpose.** 04-12's window produced genuinely clean side effects — no beets
state regenerated, zero `SUCCESS: Matched with beets`, 25/25 files byte-identical at completion,
`extended.conf` unchanged. That is real and is recorded. It is **weaker, separate evidence than the
pre-hook byte proof the criterion asks for, and it was not used to upgrade the verdict.** The
criterion table's row 3 quotes the verdict verbatim.

---

## Task 1: the executed census, and the living text

### The census — executed, routine, no environment variables

`bash scripts/check-music-freeze.sh` on LXC 100, **2026-09-13T12:37:32Z**, host HEAD `90581f3`.
ANSI stripped by `perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g'`, otherwise unedited.

| Property | Value |
|---|---|
| `FREEZE_RC` | **0** |
| output | 11,297 bytes / 180 lines (printed beside the greps, so no reading is taken over an empty capture) |
| `❌` count | **0** |
| `⚠️` count | **2** — the two permanent mode reports (`directory mode: 88`, `file mode: 2586`), D-12 scoped out |
| census heading | printed **unprompted** — no `CENSUS_CANDIDATE`, no env at all |

```
📊 7. Summary
  tagger definitions:          1   (target 1)
  beets databases:             1   (target 1 = SURVIVOR_DB)
  tagger databases:            0   (target 0 — wrtag.db*/soulbeet.db*)
  retired paths present:       0   (target 0)
  rw on Music, non-tagger:     0   (target 0, excluding the D-21 consumer exception)
  rw on Music, tagger-capable: 0   (target 0 — Phase 1 D-20, any container state)
  rw on Music, Jellyfin D-21:  1   (documented consumer exception, printed separately)
  tagger-capable containers:   2   (mounts a beets/wrtag/soulbeet config or DB; reported)
  FAILURES total:              0
```

**That the run was routine is the load-bearing part.** A candidate-gated run would prove the check
can be made to print these lines; a no-env run proves 04-11's promotion took, so the counters are
asserted on every future health check rather than on request.

**`tagger-capable containers: 2` is carried into `beets.md` as the EXPECTED value with its reason**
(sabnzbd, which mounts the defused config and holds no `/mnt/tank/media` mount at any mode; and
lidarr, matched by the renamer clause and holding `:ro`). Neither fails anything — the
`rw on Music, tagger-capable: 0` line is what asserts that. This is the corrected REVIEWS row 9
expectation, written down so nobody later reads `2` as a defect and narrows the classifier, which is
how DEF-03-01's blindness was built the first time.

### The criterion table, as landed

Five rows. Row 3 quotes the D-12 verdict exactly as it appears in the evidence file.

| Criterion | What the section records |
|---|---|
| 1 — one tagger definition | resolves to exactly `arrs/beets/beets.yaml`; census `tagger definitions: 1`; issue #306 closed with the D-26 evidence |
| 2 — Renovate config valid | `--strict --no-global` exit 0, re-run today; 04-03's `"automerg": false` negative control exit 1 |
| 3 — a real music job with no tagger | **`Verdict: OPEN`**, verbatim |
| 4 — every beets config declares `musicbrainz` | 0 MusicBrainz candidates on the live broken config vs 1 (12/12 tracks, distance 0.048) on the one-line-fixed copy; hand-read 95.2% |
| 5 — one database, no idle rw holder | the executed census above |

Named as the standing guards: `check-music-freeze.sh` § 6b (`TAGGER_CENSUS_PROMOTED=1`) and
`quick-health-check.sh`'s vendored-file drift block (`VENDORED_DRIFT_PROMOTED=1`), both promoted by
04-11 in the same commit as the runs that turned them green and each then driven red through the
routine path.

### Living text

| Region | Change |
|---|---|
| `## Two beets, one library` (was 35-57) | Rewritten as **`## One beets, one library`**. Two rows: the survivor (`arrs/beets/beets.yaml`, `2.13.1-ls349`, `restart: "no"` + `profiles: ["manual"]` + include line commented, vendored `arrs/beets/config.yaml` bind-mounted `:ro`, `plugins: musicbrainz`, one fresh `library.db` at the explicit `library: /config/library.db`, `/media` `:ro`) and the defused sabnzbd guard (`arrs/sabnzbd/beets-config.yaml`, `:ro`, `plugins: embedart musicbrainz`, **nothing invokes it** since line 285 was stripped, and **no database** since 04-11). A short paragraph records *why* the sabnzbd config is kept rather than deleted (D-11 — stock `setup.bash` re-downloads a config arming `scrub`/`lastgenre`/`embedart` `auto: yes`) |
| The 04-05 `Superseded by Phase 4` line | **Removed** (`grep -c` = **0**) |
| The host `config.yaml` blockquote | Rewritten: it *used to be* a copy of the compose service definition; replaced 2026-09-11 by D-27's vendored file |
| § *Two config gaps* opening (line ~102) | Dated in-band correction. The config it was written against is deleted; **the two gaps still stand** and are now advice for whoever configures the survivor, whose vendored config is deliberately minimal, so neither gap is closed there either. **Phase 6 owns closing them** |
| All dated historical sections | **Unchanged** |

Re-derived after writing: every fact above was read from the repo files themselves
(`beets.yaml:6,10,11,61,69`, `config.yaml:60,64`, `compose.yaml:39`, `beets-config.yaml:54`,
`sabnzbd.yaml:109,145`), and `grep -cE '^[[:space:]]*beet ' audio.bash` = **0**.

### `soulbeet/beets_config.yaml` occurrences (the acceptance criterion, with line numbers)

**3 occurrences, all dated or explicitly labelled as describing a deleted file** — none is live
advice:

| Line | Context |
|---|---|
| 5 | the dated 2026-09-11 header note naming the three files 04-03 deleted, with the `git show 5d0af70:` recovery form |
| 114 | **new** — inside this plan's dated `> **Corrected 2026-09-13 (plan 04-13, D-07)**` blockquote, naming it as the thing that was measured |
| 121 | the corrected prose immediately under it: "The deleted `soulbeet/beets_config.yaml` **was** otherwise sane…" |

`soulbeet.deercrest` count in `beets.md`: **0** (was 1, at the old table's URL row).

### Diff hygiene

163 lines added, 22 removed, one file. **Secret screen on added lines only: 0** 40-character runs,
**0** matches for `user_token|discogs.env|/secrets/|token=|apikey|api_key`. No release or folder name
appears in the added text; the census paste is counters and paths only (T-04-13-01 mitigated).
Post-commit deletion check: **0** deleted files.

---

## Task 2: the final D-07 sweep

Commands, run after this plan's edits:
`git ls-files | grep -v '^\.planning/' | xargs grep -il 'wrtag\|soulbeet'` and
`git grep -nE 'library\.blb|line 285|beets\.log|01-09 folds|Two beets|soulbeet\.deercrest' -- ':!.planning'`.

### Sweep A — `wrtag|soulbeet`, outside `.planning/`: **8 files**

| # | File | Hits | Verdict | Reason |
|---|---|---|---|---|
| 1 | `CLAUDE.md` | 27 | **corrected (04-04)** | Every remaining hit is a dated correction or the retired-tool comparison table inside the generated `stack` region. Nothing instructs anyone to pin, fix, unpin or deploy wrtag; the D-14 sentence is present verbatim |
| 2 | `renovate.json5` | 2 (428, 457) | **keep-with-reason** | Both are deliberate references to *"the retired wrtag `<0.30.0` pin, deleted in Phase 4"* inside the Jellyfin and beets rule descriptions, cited as exactly why an `allowedVersions` ceiling is the wrong instrument. Deleting them removes the reasoning, not a stale fact |
| 3 | `scripts/check-music-freeze.sh` | 17 | **keep-with-reason** | The census **must** name `wrtag`/`soulbeet` to assert they are absent — image patterns (711), retired-DB globs (738, 774, 809), and the `is_tagger_mount` classifier (255, 266) which matches **both** `beets-config.yaml` and `beets_config.yaml` on purpose (REVIEWS row 14). Removing the names blinds the guard |
| 4 | `scripts/normalise-dj-tags.py` | 1 (1331) | **keep-with-reason** | Cites `spike03-wrtag-arms.sh` as the style analog for its `--self-test` table. That script is kept (row 7), so the reference resolves |
| 5 | `scripts/quick-health-check.sh` | 1 (170) | **keep-with-reason — NEW since 04-05** | 04-11's sixth EXIT-CODE notice, listing "any wrtag/soulbeet tagger database present" as a new exit-1 condition. It names the retired taggers *because* it asserts their absence |
| 6 | `scripts/spike03-image-headroom.sh` | 2 (112, 116) | **corrected (04-07)** | The `KEEP_PATTERNS "sentriz/wrtag"` entry that protected the retired image from reaping is **gone**; both remaining hits are the dated note recording its removal |
| 7 | `scripts/spike03-wrtag-arms.sh` | 73 | **keep-with-reason (04-05)** | Phase 3 criterion-3 instrument, cited by `03-WRTAG-EVIDENCE.md`. Deleting it destroys the reproducibility of a recorded measurement. Dated `KEPT AFTER PHASE 4` header names `5d0af70` and the reproduction route, which 04-05 **executed** |
| 8 | `stacks/selfhosted/arrs/beets.md` | 12 | **corrected (04-13, this plan)** | Living text rewritten; `soulbeet.deercrest` gone. Remaining hits: the dated header/banner (5, 8, 16), this plan's own dated corrections (38-41, 114, 121), two **dated historical evidence blocks** (266, 298 — an executed 2026-08-18 transcript, never edited), and the new census paste and criterion table (1166, 1171, 1187) |

### Sweep B — the widened grep, outside `.planning/`: **6 files**

| File | Hits | Verdict | Reason |
|---|---|---|---|
| `scripts/check-music-freeze.sh` | 9, 101, 824, 826, 827 | **keep** | 9/101 record that plan 01-09 folds this script into `quick-health-check.sh` — **true**, that fold-in exists. 824-827 are the `RETIRED_DB_PATHS` constants, which must spell the retired database paths to assert they are absent |
| `scripts/freeze-music-apply.sh` | 256, 263, 277 | **keep-with-reason (04-05)** | Phase 1 tool. The `library.blb` names are **discovered at runtime, never hard-coded** (its own comment says so), and the `.bak` discussion describes pre-project files |
| `stacks/selfhosted/arrs/beets.md` | 37, 54 | **correct as written (04-13)** | 37 is this plan's own dated note that the section *used to be* headed "Two beets, one library"; 54 records that `library.blb` and `.config/beets/` were fenced and deleted by 04-11 |
| `stacks/selfhosted/arrs/sabnzbd.yaml` | 129 | **keep — load-bearing** | "…still removes `library.blb` behind an existence guard" is precisely why the now-absent database cannot abort `beets()` under `set -e`. This is the refutation of Grok's H2; deleting it would delete the answer |
| `stacks/selfhosted/arrs/sabnzbd/audio.bash` | 272, 273, 276, 277 | **keep — must not be edited** | The vendored upstream hook. C3-a asserts it is byte-identical to the live `fdcddca2…` copy **except line 285**. Any other edit breaks that proof |
| `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` | 132, 133 | **keep-with-reason (04-10)** | `log: /config/scripts/beets.log` in the **defused** config, with a comment recording that 04-11 deleted the file. Nothing invokes this config |

### GAP rows: **ZERO**

Every hit whose 04-05 verdict was `correct — pending` has been corrected by its named owner:

| 04-05 row | Owner | Outcome, measured today |
|---|---|---|
| 6 — `beets.md` table | 04-13 | **corrected** (this plan) |
| 8 — `check-music-freeze.sh` `TAGGER_PATTERN` | 04-06 | **corrected** — name-based classification replaced by mount-based; no `TAGGER_PATTERN` hit remains |
| 9 — `spike03-image-headroom.sh` `KEEP_PATTERNS` | 04-07 | **corrected** |
| 10 — `sabnzbd.yaml` | 04-10 | **corrected** — `grep -ci 'wrtag\|soulbeet'` = **0** |
| 11 — `sabnzbd/beets-config.yaml` | 04-10 | **corrected** — `grep -ci 'wrtag\|soulbeet'` = **0** |

### The denominator, stated honestly — 9 → 8, and it is not a regression

The orchestrator's measured non-`.planning` set was **9** files. Today it is **8**. Both moves are
accounted for:

- **Out (−2):** `stacks/selfhosted/arrs/sabnzbd.yaml` and `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml`
  — 04-10 corrected the last `wrtag|soulbeet` string in each, so they left the grep **as a result of
  being fixed**.
- **In (+1):** `scripts/quick-health-check.sh` — 04-11's EXIT-CODE notice added the first
  `wrtag/soulbeet` string that file has ever carried, and it is there **because** the check now
  asserts those databases are absent.

9 − 2 + 1 = **8**. This is the same class of arithmetic 04-05 recorded when `.gitignore` dropped out
(10 → 9): a file leaving a stale-reference grep because it was corrected is the intended direction,
and reporting only the post-edit number would hide that.

---

## Task 2: the Renovate observation (D-30, C2-b, C2-c, REVIEWS rows 2 and 15)

### Producer status captured first, with a positive control (REVIEWS row 2)

| Read | RC | Result |
|---|---|---|
| `gh issue view 3 --json title` | **0** | `Dependency Dashboard` — **positive control satisfied**; issue 3 is the dashboard |
| `gh issue view 3 --json body` | **0** | **20,571 bytes**, non-empty (byte count printed beside every grep taken over it) |
| `gh issue list --state open --search 'Action Required in:title' --json number -q length` | **0** | **0** — no config-error issue |
| `gh pr list --state all --search 'linuxserver/beets'` | **0** | `[]` |

### The driven error branch — an UNKNOWN, never a clean dashboard

```
$ GH_TOKEN=invalid-04 gh issue view 3 --json title -q .title
HTTP 401: Bad credentials (https://api.github.com/graphql)
Try authenticating with:  gh auth login -h github.com
trc=1
```

`rc=1` → the branch reports **UNKNOWN**. This is the whole point of REVIEWS row 2: the naive form
`! gh issue view 3 | grep -q 'terry90/soulbeet'` **passes** on this exact failure, because a failed
lookup produces no matching text. The suite check reads the status first and refuses to interpret
the output at all when it is non-zero.

### C2-c — Renovate accepted the config

| Assertion | Result |
|---|---|
| Dashboard names `terry90/soulbeet` | **0** hits |
| Dashboard names `music/wrtag.yaml` | **0** hits |
| Dashboard names `wrtag` **at all** (case-insensitive) | **0** hits |
| "Action Required" config-error issue open | **0** |

**The soulbeet lookup failure is gone from Dependency Dashboard #3.** One nuance recorded so it is
not misread: the dashboard **does** carry a `## Repository Problems` block reading
`⚠️ WARN: Package lookup failures` — but its one named dependency is
`ghcr.io/rybbit-io/rybbit: no-result`, affecting `stacks/selfhosted/social/rybbit.yaml`. That is
issue **#307**, explicitly unrelated to this phase. Reporting "Repository Problems present" as a
Phase 4 finding would be wrong; reporting nothing would hide it.

### C2-b / REVIEWS row 15 — what actually happened, and it is not what D-30 predicted

**D-30 predicted:** *"Renovate will then immediately propose `2.13.1-ls350` as a patch and automerge
it in the repo; that PR is expected and is recorded as expected, not as drift."*

**Observed 2026-09-13 — that PR was never created, and now cannot be:**

| Observation | Value |
|---|---|
| `gh pr list --state all --search 'linuxserver/beets'` | **`[]`** — no beets image PR has ever existed, open, closed or merged |
| Broader `--search 'beets'` over all PRs | only **#301** (`docs(beets): record library state…`, open) and **#243** (docs, merged 2026-07-31). **Neither is an image update** |
| Dashboard § *Detected Dependencies* | `lscr.io/linuxserver/beets 2.13.1-ls349` → `[Updates: 2.14.0-ls352]` in `stacks/selfhosted/arrs/beets/beets.yaml` |
| Dashboard § **Rate-Limited** | `renovate/lscr.io-linuxserver-beets-2.x` → `chore(deps): update lscr.io/linuxserver/beets docker tag to v2.14.0-ls352` |
| Repo pin today | `lscr.io/linuxserver/beets:2.13.1-ls349`, unchanged |
| Host image resident | `sha256:159e62e4d611…` at `2.13.1-ls349` |

**Recorded as an observation, not as "working" and not as drift.** Three separate things are true
and each matters:

1. **The versioning rule took.** Before D-30, Renovate read `-ls349` as a compatibility suffix and
   had **never offered this image an update at all**. It now offers one. That is the rule working —
   observable in *Detected Dependencies*, which now shows an `Updates:` entry where it previously
   showed none.
2. **The expected `ls350` patch automerge never happened and is now unreachable.** Upstream moved
   past it: the offered update is `2.14.0-ls352`, a **MINOR**, which the D-30 two-rule shape
   correctly routes to manual review rather than automerge. The prediction was about a patch that no
   longer exists as the newest tag. **"Not yet observed" is the honest reading for the patch
   automerge specifically** — it has not been exercised, and no evidence here says it works.
3. **No PR exists because the update is rate-limited**, sitting behind an `unlimit-branch` checkbox
   alongside 19 others. That is Renovate's PR-hourly limit, an estate-wide condition, not a beets
   one.

**REVIEWS row 15 — was 04-09 D-30's deliberate redeploy? No.** 04-09-SUMMARY records it explicitly:
*"This was NOT D-30's deliberate redeploy. The image tag at HEAD is still
`lscr.io/linuxserver/beets:2.13.1-ls349` — Renovate has not moved the repo past it, so the redeploy
branch never opened and `ls349` was used as-is."* Tag `2.13.1-ls349`, image id
`sha256:159e62e4d611…`, RepoDigest `sha256:7bf852f33b0d…`, already resident, **nothing pulled**. The
host stayed on ls349, exactly as D-30 requires, and still is.

**Follow-up, recorded not fixed:** `2.14.0-ls352` is a genuine minor awaiting a human, and beets
2.4.0 is the precedent for why (a minor release turned MusicBrainz into a plugin and silently
disabled autotagging estate-wide). It is **not** this phase's to merge — Phase 5/6 own the survivor's
version decision.

---

## Full suite

Every exit code captured, against host HEAD `90581f3`.

| Check | Where | RC | Evidence |
|---|---|---|---|
| `renovate-config-validator --strict --no-global renovate.json5` | workstation, scratch prefix | **0** | `INFO: Validating renovate.json5 as repo config` / `INFO: Config validated successfully against 1 file(s)` |
| `check-renovate.sh` with the prefix on `PATH` | workstation | **0** | `✅ renovate.json5 validates (renovate-config-validator)` and **`Validator route: local`** (line 31 of 10,643 bytes) |
| `bash scripts/quick-health-check.sh` | workstation | **0** | 12:39:12Z. Drift `✅ vendored files match (3)`; census counters folded in; **0** `⚠️`; sole `❌` is `Traefik dashboard: Not accessible` — the report-only 04-01 ROUTINE BASELINE entry |
| `bash scripts/check-music-freeze.sh` | LXC 100 | **0** | 12:37:32Z, pasted above |
| D-23 self-test | LXC 100 | **0** | `docker run --rm --pull never --network none --entrypoint python3 -v /mnt/fast/stacks/scripts:/w:ro lscr.io/linuxserver/beets:2.13.1-ls349 /w/normalise-dj-tags.py --self-test` → `-- 3 cases, 0 failed --`, python 3.12.14, mutagen 1.48.1 |
| Task 2 `<verify>` block, verbatim | workstation | **0** | `SUITE-OK` |

**Validator supply chain (T-04-SC).** The same pinned `renovate@44.80.0` approved at 04-03's
blocking-human gate, installed with `--ignore-scripts --no-audit --no-fund` into a `mktemp -d`
prefix outside the repo; installed version asserted `44.80.0` by reading the installed
`package.json`; **nothing installed globally or into the repo; `npx` never used**; prefix deleted and
asserted absent (`PREFIX-ABSENT`) after **each** of the two runs. The recurring
`WARN: RE2 not usable, falling back to RegExp` is expected under `--ignore-scripts`, which leaves the
native `re2` module unbuilt — recorded by 04-03 and unchanged.

---

## The orphaned item: DEF-04-01, deferred in writing

`stacks/selfhosted/arrs/beets.md` (§ *One correction to this page's own § The recovery fence*)
records that the hard constraint *"beets has **no `undo` command**"* remains true of the beets **CLI**
but is **narrower than it reads**, because beets-flask rc6 has a working `UNDO IMPORT`, verified by
use. It says **Phase 4 owns amending `CLAUDE.md` and `PROJECT.md`**. No Phase 4 plan, `04-CONTEXT.md`
decision or `04-RESEARCH.md` note covers it, and both files still carry the unqualified claim —
re-verified present today at **`CLAUDE.md:152`** and **`.planning/PROJECT.md:187`**.

**Disposition: DEFERRED IN WRITING**, as `DEF-04-01` in
`.planning/phases/04-collapse-to-one-tagger/deferred-items.md` (commit `60b7b8c`), **destination
Phase 7**, which owns the "undo exercised" criterion and now has two candidate mechanisms rather
than one. It is also listed in `beets.md`'s own *Recorded, not fixed* list, so a reader of the estate
record meets it without opening `.planning/`.

**Why it was not simply fixed here**, stated because "deferred" with no reason is indistinguishable
from "forgotten":

- **Mandate.** This plan's `files_modified` is one file. Amending two further files — one of them the
  repo-root agent contract — from a status plan is the unmandated-edit class 04-05 declined for the
  host `.env` files.
- **`CLAUDE.md:152` is generated.** It sits inside the `<!-- GSD:project-start -->` region whose
  source is `.planning/PROJECT.md`. Hand-editing only `CLAUDE.md` **reverts on regeneration** — the
  exact F15 defect 04-04 had to solve for the `stack` region. Both files must be amended in one
  edit, PROJECT.md first, with parity proven.

The deferral note records the three things the amendment must not drop, the third being the one most
likely to be lost in a paraphrase: **it reverses the import, not the tag writes made into the
files.**

---

## Deviations from Plan

### 1. [Rule 3 — blocking, resolved] origin was behind the workstation, so the host could not pull the plan's own prerequisite

- **Issue:** the plan's first action is a host `git pull --ff-only`. `origin/main` was at `763b851`
  while the workstation was at `90581f3` (the orchestrator's wave-7 tracking commit, carrying
  04-12's SUMMARY and the filled evidence file). A host pull would have succeeded and changed
  nothing, and the census would then have run against a checkout missing the artefacts this plan
  reasons from.
- **Fix:** pushed `763b851..90581f3` first, then pulled host-side — fast-forward, `pull_rc=0`, host
  HEAD `90581f3`. Host HEAD was re-derived **inside** the same command as every subsequent
  measurement rather than assumed to have stuck.

### 2. [My own defective instrument, self-caught] A `tail -25` truncated the exact line an acceptance criterion names

- **Issue:** my first `check-renovate.sh` run was piped through `tail -25` to keep the output short.
  The script prints `Validator route: local` **before** the PR listing, so the tail cut it. I had
  `check_renovate_rc=0` and nothing else — and an exit code of 0 is reachable with route
  `unavailable` too, in which case the script prints a **yellow UNVALIDATED** line that
  `04-VALIDATION.md` row C2-a says explicitly "is **not** a pass".
- **Resolution:** I did **not** infer the route from the exit code. The scratch prefix had already
  been deleted, so I reinstalled the same pinned version and re-ran capturing the whole output to a
  file: `Validator route: local` at line **31**, with
  `✅ renovate.json5 validates (renovate-config-validator)` at line 30. Prefix deleted again and
  asserted absent.
- **Recorded because the failure direction is the dangerous one:** had I written "rc 0, route local"
  from the exit code alone, the SUMMARY would have asserted a specific measured string that I never
  saw — the same "silence read as clean" class as this phase's `wc -l` on a missing file (04-12
  deviation 2) and `grep -c` exiting 1 on zero (04-11 deviation 6). It is the fourth instrument in
  this phase caught this way, and the first where the defect was in the *reporting* rather than the
  measuring.

### 3. [Orchestrator fact refined, not refuted] The sweep denominator is 8, not 9

- The orchestrator supplied a 9-file non-`.planning` set. Measured today: **8**. Not a regression and
  not an error in the note — `sabnzbd.yaml` and `sabnzbd/beets-config.yaml` left the grep because
  04-10 corrected them, and `quick-health-check.sh` entered it because 04-11's EXIT-CODE notice names
  the retired taggers in order to assert their absence. Both moves are recorded above with the
  arithmetic, in the shape 04-05 used for its own 10 → 9.

### 4. [Plan silence, resolved conservatively] The orphaned "no undo" item

- The plan text does not mention it; the orchestrator's brief requires it be fixed or deferred in
  writing. Deferred, with a named destination and the reason — see above. **No file outside this
  plan's mandate was edited.**

### 5. [Scope note] Task 2 carries no commit

- Its `<files>` is *"(none unless a sweep hit owned by this plan remains)"*. No such hit remained —
  the only `beets.md` hits this plan owned were corrected in Task 1. Task 2 is measurement, and its
  output is this SUMMARY. The `deferred-items.md` commit is recorded separately rather than folded
  into a task row it does not belong to.

---

**Total deviations:** 5 — 1 blocking prerequisite resolved, **1 defective instrument of my own**,
1 refinement of an inherited figure, 1 conservative resolution of a plan silence, 1 scope note.
**No assertion was weakened, no file was edited or created to satisfy a grep, no evidence was
fabricated, and the criterion-3 verdict was not upgraded on the strength of the clean side effects.**

## Known Stubs

None.

## Threat Flags

None. This plan added no network endpoint, auth path, file-access pattern or schema change. Against
the plan's register:

- **T-04-13-01 (information disclosure via the pasted census)** — mitigated. Only the `📊 7. Summary`
  counter lines are pasted: counter names, integers and target annotations. No release name, no
  folder name, no path beyond the constants already in the public script. Added lines screened: **0**
  40-character runs, **0** secret-path strings.
- **T-04-SC (validator reinstall)** — mitigated. Same pinned `renovate@44.80.0` from 04-03's
  blocking-human approval, `--ignore-scripts`, `mktemp -d` prefix outside the repo, installed version
  asserted, prefix deleted and asserted absent after each of the two runs. No `npx`, nothing global.
- **T-04-13-02 (repudiation — closure claims)** — mitigated. The census is an **executed** routine run
  with its UTC timestamp, literal command and host HEAD; it exited 0 with zero `❌`, so no red run was
  pasted as green. The closure heading was withheld because the verdict is not PASS, and the verify
  enforces that mapping rather than trusting the author.
- **T-04-13-03 (false-green dashboard check)** — mitigated. `gh` status captured before any output was
  read, the issue title used as a positive control, and the error branch **driven** with
  `GH_TOKEN=invalid-04` and shown to return rc 1 / UNKNOWN.

## Issues Encountered

- No credential, `.env` value or release name was printed. The workstation and host
  `stacks/selfhosted/music/.env` files were **listed but never read** — both still present, both
  still gitignored, `git ls-files` on that path is empty. 04-05's ruling (leave in place) stands.
- No host state was changed by this plan: no container started or stopped, no file written outside
  the repo, no SABnzbd or Lidarr API call, nothing deleted. The only host writes were git's own
  fast-forward.

## Next Phase Readiness

- **`/gsd-verify-work` must treat criterion 3 as the open gap.** Criteria 1, 2, 4 and 5 are measured
  and hold; 3 is OPEN with its mechanism recorded. The phase is **not closable**.
- **Re-running criterion 3 is cheap and the blocker is known.** The estate side is ready and proven
  over two real jobs. Only the watcher changes: snapshot in `/downloads/incomplete/` before the move,
  or drop the 2-second stability wait. One more organic or operator-triggered music job re-opens the
  window.
- **Phase 5 must revise the census's `tagger definitions` target** when beets-flask lands. A second
  legitimate definition fails that counter until the target moves with it. Carry 04-11's warning:
  **do not narrow the classifier** — that is how DEF-03-01's blindness was built.
- **Phase 6 inherits two open config gaps** (`match.preferred.countries`, and `fromfilename`/`edit`
  for bucket C). `beets.md` now says so explicitly rather than implying they are solved in a file
  that no longer exists.
- **Phase 7 inherits DEF-04-01**, and both files to amend in one edit, PROJECT.md first.
- **`2.14.0-ls352` awaits a human.** The D-30 rule is working as designed by *withholding* automerge
  on a minor. Nobody should merge it to make the dashboard tidy.

## Self-Check: PASSED

- FOUND `stacks/selfhosted/arrs/beets.md` — re-grepped **after** writing: interim heading **1**,
  `## Phase 4 — one tagger` **0**, `tagger definitions:` **3**, `ANSI stripped, otherwise unedited`
  **1**, `Superseded by Phase 4` **0**, `soulbeet.deercrest` **0**. The plan's full `<verify>` chain
  returns **MAP-OK(open/fail)**.
- FOUND `.planning/phases/04-collapse-to-one-tagger/deferred-items.md`.
- FOUND `.planning/phases/04-collapse-to-one-tagger/04-13-SUMMARY.md`.
- FOUND commit `a0fa259` (touches exactly `stacks/selfhosted/arrs/beets.md`) and `60b7b8c` (touches
  exactly `.planning/phases/04-collapse-to-one-tagger/deferred-items.md`).
- Post-commit deletion check on both: **0** deleted files.
- `04-D12-EVIDENCE.md`: `grep -cE '^Verdict: (PASS|OPEN|FAIL)'` = **1**, `PENDING` markers **0** —
  re-derived, not taken from 04-12.
- **`.planning/STATE.md` and `.planning/ROADMAP.md` were NOT modified by this plan, and no
  `gsd-sdk query state.*` or `roadmap.*` verb was called.** Neither file appears in either commit's
  `--name-only`.
- Only explicit paths were staged; `git add -A` / `git add .` was never used. The two pre-existing
  untracked host files were left alone, as were the two gitignored `music/.env*` files.
- Both npm scratch prefixes deleted and asserted absent. No `rm -rf` was executed against any estate
  path.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-13*
