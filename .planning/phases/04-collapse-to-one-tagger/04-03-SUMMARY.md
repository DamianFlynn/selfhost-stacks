---
phase: 04-collapse-to-one-tagger
plan: 03
subsystem: infra-config
tags: [renovate, compose, deletion, validator, tagr-03, tagr-04, d-22]

# Dependency graph
requires:
  - phase: 03-tagger-spike
    provides: "the beets decision (03-DECISION.md) and the measured 2.13.1-ls349 tag"
  - phase: 04-collapse-to-one-tagger
    provides: "04-01's finding that no wrtag/soulbeet/beets container exists on LXC 100"
provides:
  - "exactly one tagger definition in git: stacks/selfhosted/arrs/beets/beets.yaml at lscr.io/linuxserver/beets:2.13.1-ls349"
  - "arrs/compose.yaml include list: soulbeet line gone, survivor line corrected to `#  - beets/beets.yaml` (still commented)"
  - "renovate.json5: wrtag <0.30.0 rule and the empty Music auto-label rule deleted; two-rule beets policy (versioning-only regex, then minor+major manual review)"
  - "scripts/check-renovate.sh: --no-global validation, no pipefail abort on zero matches or zero pending PRs"
  - "PRE_DELETION_SHA 5d0af70 and soulbeet config sha256 83028925... for 04-05 and the 04-07 #306 comment"
affects: [04-05, 04-07, 04-13, phase-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A/B control for a script that derives REPO_ROOT from its own path: run old and fixed copies from identical mirror trees (scripts/ + stacks symlink + config copy), so only the script differs"
    - "Validator gate triple: --strict --no-global FILE, --strict discovery mode in a scratch dir, and a misspelled-key copy that must exit 1"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-03-SUMMARY.md
  modified:
    - renovate.json5
    - scripts/check-renovate.sh
    - stacks/selfhosted/arrs/compose.yaml
    - stacks/selfhosted/arrs/beets/beets.yaml
  deleted:
    - stacks/selfhosted/arrs/soulbeet.yaml
    - stacks/selfhosted/arrs/soulbeet/beets_config.yaml
    - stacks/selfhosted/music/compose.yaml
    - stacks/selfhosted/music/wrtag.yaml

key-decisions:
  - "D-07 verdict: the 'Auto-label by stack: Music' Renovate rule is DELETED. It matched only stacks/selfhosted/music/**, which D-05 deleted, and the wrtag|soulbeet grep cannot see it"
  - "Jellyfin description: packageRules[2] references kept (index 2 is still the auto-merge-minor rule after the edit); the [5] and [3] references rewritten by description"
  - "The gitignored stacks/selfhosted/music/.env (workstation and host) and .env.backup (workstation) were NOT deleted. They are untracked local files, not tagger definitions, and not created by this plan. Handed to 04-05 (host runtime retirement)"
  - "New beets rule descriptions reference other rules by description text, never by index (Pitfall 6)"

requirements-completed: [TAGR-03]
requirements-partial: [TAGR-04]

# Metrics
duration: ~30min
completed: 2026-09-11
---

# Phase 4 Plan 03: Retire the Losing Tagger Definitions Summary

**wrtag and soulbeet deleted from git. The survivor beets.yaml is bumped to `2.13.1-ls349` and is now governed by a two-rule Renovate policy that validates `--strict` in both modes. check-renovate.sh no longer aborts on a healthy estate.**

## Performance

- **Duration:** about 30 min (this executor; an earlier attempt died on a provider 429 before committing anything)
- **Completed:** 2026-09-11T21:40Z
- **Tasks:** 3 of 3 (Task 1 was a human gate, resolved before this executor started)
- **Files:** 4 modified, 4 deleted

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1 | Package legitimacy gate for `renovate` | none (human gate, no files) |
| 2 | Delete the losers, fix the include list, bump the survivor, rewrite renovate.json5 | `e63e0fd` |
| 3 | Repair check-renovate.sh (D-22, F12, F13); push and pull | `d08842c` |

## Task 1: Package legitimacy gate (resolved)

The orchestrator presented the plan's three checks to the operator in an interactive question on
2026-09-11, during this execute-phase run: npmjs.com/package/renovate links to
github.com/renovatebot/renovate, version 44.80.0 is listed, and weekly downloads are in the hundreds
of thousands. It also stated the exact install form. **The operator's verbatim reply was:
"approved"**. That was a genuine human answer, not an auto-approval. It covers `renovate@44.80.0`
with exactly `--ignore-scripts --no-audit --no-fund`, and nothing else.

Before installing, I checked the approval premise against the registry myself. Nothing contradicted
it:

```
$ npm view renovate@44.80.0 name version repository.url dist.tarball scripts.postinstall scripts.install scripts.preinstall
name = 'renovate'
version = '44.80.0'
repository.url = 'git+https://github.com/renovatebot/renovate.git'
dist.tarball = 'https://registry.npmjs.org/renovate/-/renovate-44.80.0.tgz'
(no preinstall/install/postinstall script)
```

Install: `npm install --prefix "$S" renovate@44.80.0 --ignore-scripts --no-audit --no-fund` into the
`mktemp -d` scratch `$TMPDIR/tmp.KfhQ3Yw791`, which is outside the repo. It added 614 packages in
22 s. The installed `package.json` reports `44.80.0` and the renovatebot repository. Nothing was
installed globally or into the repo, and `npx` was never used. **The scratch was deleted at plan
end.** The stray `tmp.pS0jG3boU9` from the earlier attempt was left alone for the orchestrator.

## Task 2: Retirement and Renovate policy

### Recorded for later plans

| Item | Value |
|---|---|
| `PRE_DELETION_SHA` | `5d0af708ae9f04b9ab491cec731b6551ba6bb205` (`5d0af70`, now on origin) |
| `sha256 stacks/selfhosted/arrs/soulbeet/beets_config.yaml` | `83028925559bc8416a6da6a238bb6d1b20dbaed43f306a08e4395496cbbd3576` (expected prefix `83028925`, matches) |

Recover either deleted file with `git show 5d0af70:<path>`.

### Validator transcripts (renovate-config-validator 44.80.0)

Every run also printed `WARN: RE2 not usable, falling back to RegExp`. That is expected under
`--ignore-scripts`, which leaves the native `re2` module unbuilt (RESEARCH § Standard Stack).

| Run | Config | Exit | Key lines |
|---|---|---|---|
| Baseline `--strict --no-global renovate.json5` | unchanged | **0** | `Validating renovate.json5 as repo config` / `Config validated successfully against 1 file(s)` |
| Baseline discovery `--strict` (scratch copy) | unchanged | **0** | `Validating renovate.json5` / `Config validated successfully against 1 file(s)` |
| **Gate 1** `--strict --no-global renovate.json5` | edited | **0** | `Validating renovate.json5 as repo config` / `Config validated successfully against 1 file(s)` |
| **Gate 2** discovery `--strict` in `$S/cur/` | edited | **0** | `Validating renovate.json5` / `Config validated successfully against 1 file(s)` |
| **Gate 3** negative control, `"automerg": false` added to the manual-review rule | edited + 1 line | **1** | `ERROR: Found errors in configuration` / `"topic": "Configuration Error"` / `"message": "Invalid configuration option: packageRules[36].automerg"` |

The negative-control diff against the real file was exactly one added line (`463a464 > "automerg": false,`).
The control discriminates: it names the misspelled key at the index of the new rule.

### packageRules index dump (json5 2.2.3 parse of the edited file)

```
 0  Label by update type
 1  Default: Auto-merge patch and digest updates for all Docker
 2  Default: Auto-merge minor updates for all Docker images
 3  Security: Pin digests for security-critical components
 4  Default: Require manual review for major updates
 5  Sensitive: PostgreSQL (Immich) - Pin to prevent automatic up
 6  Sensitive: Redis/Valkey (Immich) - Pin to prevent automatic
 7  GLOBAL: PostgreSQL major versions require manual migration (
 8  Immich: Main applications (server/ML) - Manual review for al
 9  Auto-label by stack: Immich
10  Auto-label by stack: Traefik
11  Auto-label by stack: Code Server
12  Auto-label by stack: Minecraft
13  Auto-label by stack: OpenWebUI
14  Auto-label by stack: Hoarder
15  Auto-label by stack: Automation
16  Auto-label by stack: Core (Traefik/Auth)
17  Auto-label by stack: Keeper.sh (Calendar Sync)
18  Auto-label by stack: RustDesk (Remote Desktop)
19  Auto-label by stack: Open Archiver
20  Auto-label by stack: Dawarich (Location Tracking)
21  Auto-label by stack: Books
22  Auto-label by stack: Social
23  Auto-label by stack: SaaS
24  Auto-label by stack: Documents
25  Auto-label by stack: Media
26  Auto-label by stack: Teleport
27  Auto-label by stack: Postiz (Social Media Manager)
28  Auto-label by stack: ARRs (Media Automation)
29  Auto-label by stack: MCP (Model Context Protocol)
30  Auto-label by stack: Monitoring
31  Auto-label by stack: FreshRSS
32  Auto-label by stack: Termix
33  Auto-label by stack: Generic stacks
34  Jellyfin: minor releases are de-facto majors -- require manu
35  beets (1 of 2): LSIO tag scheme, versioning ONLY. Default do
36  beets (2 of 2): minor and major releases require manual revi
TOTAL=37 BOTH_VERSIONING_AND_UPDATETYPES=[]
beets rule idx 35 keys=description,matchDatasources,matchPackageNames,versioning
beets rule idx 36 keys=description,matchDatasources,matchPackageNames,matchUpdateTypes,automerge,addLabels
```

- Index 2 is still the auto-merge-minor rule, so the Jellyfin description's `packageRules[2]`
  references stay. They are the only index references left in the file (3 occurrences).
- `packageRules[5] only catches MAJOR` became `The 'Default: Require manual review for major updates'
  rule only catches MAJOR` (that rule is now index 4).
- `see packageRules[3], the wrtag <0.30.0 pin ... ever since` became `see the retired wrtag <0.30.0
  pin, deleted in Phase 4 -- it was added on a misdiagnosis on 2026-06-24 and enforced a broken
  state for months until it was removed.`
- No object carries both `versioning` and `matchUpdateTypes`, and neither beets rule has
  `allowedVersions`.
- The beets rules follow the auto-merge-minor rule (35 and 36, after 2), so `automerge: false` wins
  for minor and major.

### D-07 item the `wrtag|soulbeet` grep cannot see

**"Auto-label by stack: Music" (formerly lines 415-423): DELETED.** Its only matcher was
`**/stacks/selfhosted/music/**`, and that directory is gone from git (D-05). A rule that matches
nothing is the dead-definition problem in another form. Deleting it does not move `[2]` or `[4]`.
`grep -c 'selfhosted/music' renovate.json5` = 0.

### Acceptance

| Check | Result |
|---|---|
| C1-a `git ls-files stacks \| xargs grep -lE '^\s*image:\s*(lscr\.io/linuxserver/beets\|sentriz/wrtag\|ghcr\.io/terry90/soulbeet\|metasauce/beets-flask)'` | exactly `stacks/selfhosted/arrs/beets/beets.yaml` |
| C1-a `git ls-files \| grep -E 'soulbeet\|selfhosted/music/'` | empty |
| C1-c `'^#  - beets/beets.yaml$'` / `'^#  - beets.yaml$'` / `soulbeet` in arrs/compose.yaml | 1 / 0 / 0 |
| listenarr and boxarr comment lines | untouched (lines 32, 38) |
| beets.yaml `restart: "no"` / `profiles: ["manual"]` / `/mnt/tank/media:/media:ro` | 1 / 1 / 1. The diff touches only line 6, the image |
| beets.yaml `image: lscr.io/linuxserver/beets:2.13.1-ls349` | 1 |
| `sentriz/wrtag` / `ls(?<build>` / `packageRules\[3\], the wrtag` in renovate.json5 | 0 / 1 / 0 |
| `docker compose -f stacks/selfhosted/arrs/compose.yaml config --quiet` | exit 0 (baseline 0) |
| `docker compose -f stacks/selfhosted/arrs/beets/beets.yaml --env-file stacks/selfhosted/arrs/.env --profile manual config --quiet` | exit 0 (baseline 0) |
| Host, after pull: `docker compose -f stacks/selfhosted/arrs/compose.yaml config --quiet` | exit 0 |

The plan's `<verify>` chain failed at its first term, for a reason that is not a defect in the
outcome. See Deviations 1.

## Task 3: check-renovate.sh repair

### Edits

- **Line 62:** `renovate-config-validator "$CONFIG_FILE"` became `renovate-config-validator --no-global "$CONFIG_FILE"` (F13), with a comment saying why.
- **Lines 90 and 100:** each `grep -r…` is wrapped as `{ grep … || true; } |` (F12), with a comment above line 90.
- **Lines 115, 138 and 157:** `echo "$X" | grep -v '^$' | wc -l | tr -d ' '` became `printf '%s\n' "$X" | awk 'NF{n++} END{print n+0}'` for POSTGRES_COUNT, REDIS_COUNT and RENOVATE_COUNT. There is a comment above 115, and the comment the plan asked for above 157 says the old form aborted exactly when zero Renovate PRs were pending.
- Lines 101-103 were **not** touched. Their BSD-sed `\s` is out of scope (A6, see Deferred Issues).

Result: `bash -n` passes. `renovate-config-validator --no-global` appears 1 time, non-comment
`grep -v '^$'` lines = 0, `awk 'NF{n++} END{print n+0}'` appears 3 times, and the plan's third
verify term = 0.

### F13 evidence: what `--no-global` changes

| Invocation | Exit | Validator's own mode line |
|---|---|---|
| `renovate-config-validator renovate.json5` (the old line 62) | 0 | `Validating renovate.json5 as global config` |
| `renovate-config-validator --no-global renovate.json5` (the new line 62) | 0 | `Validating renovate.json5 as repo config` |

Both forms pass on this file today, but only the second checks it in the semantics Renovate actually
reads.

### Route table (02.1-08 shape)

The stub is a 7-line `$S/stub/git`: `fetch` exits 0 silently, `branch -r` prints nothing and exits
0, and every other subcommand `exec`s `/usr/bin/git`. I checked it before use: `branch -r` gave 0
lines, `fetch` gave rc 0, `rev-parse` was delegated. The real repo has 28 `origin/renovate/*`
branches. `grep` and `sed` in the script resolve to BSD `/usr/bin/grep` (2.6.0-FreeBSD) and
`/usr/bin/sed`.

The `-old` rows run `git show HEAD:scripts/check-renovate.sh`, taken before the Task 3 commit
(sha256 `8fc273a3…`, identical to the committed pre-fix file).

| # | Script | Tree | Stub input | Validator | Script exit | Verdict line |
|---|---|---|---|---|---|---|
| a-old | pre-fix | `mirror-old` (repo `stacks` symlink + real config) | `branch -r` empty | absent | **1** | none. Output stops right after `🔄 Pending Renovate PRs...`, with `No pending Renovate PRs` ×0 and `Validation Complete` ×0. **The line-157 defect was real** |
| a | fixed | `mirror-new` (identical tree) | `branch -r` empty | absent | **0** | `✅ No pending Renovate PRs`, `Pending PRs: 0`, `Validation Complete` |
| a | fixed | repo root | `branch -r` empty | absent | **0** | `✅ No pending Renovate PRs`, `Pending PRs: 0`, `Validation Complete` (yellow `UNVALIDATED`, route `unavailable`) |
| b-old | pre-fix | `empty-old` (`services: {}` only) | `branch -r` empty | absent | **1** | none. Output stops right after `🐳 Checking Docker image declarations...`. **The line-90 defect was real** |
| b | fixed | `empty-new` (`services: {}` only) | `branch -r` empty | absent | **0** | `✅ No PostgreSQL instances found`, `✅ No Redis/Valkey instances found`, `PostgreSQL: 0`, `Redis/Valkey: 0`, `✅ No pending Renovate PRs`, `Validation Complete` |
| c | fixed | repo root | none (real git, real fetch) | pinned 44.80.0 on PATH | **0** | `Validating renovate.json5 as repo config`, `✅ renovate.json5 validates (renovate-config-validator)`, `Validator route: local`, `Pending PRs: 28`, `Validation Complete` |
| d | fixed | `badcfg` (real stacks + the `automerg` config) | `branch -r` empty | pinned 44.80.0 on PATH | **1** | `Invalid configuration option: packageRules[36].automerg`, then red `❌ renovate.json5 FAILED validation`. Inventory lines after the failure: 0 |

Rows a-old and b-old are the controls that could fail and did. They prove the fixed rows pass
because of the repair and not because of the harness. Row d proves the `--no-global` branch still
fails closed on a bad config.

### Push and host

- `git push origin main`: `ddbd3ff..d08842c`. This carried the two earlier docs commits (`006828a`,
  `5d0af70`), as expected. `git log origin/main -1` = `d08842c` = local HEAD.
- LXC 100: `git -C /mnt/fast/stacks pull --ff-only` moved the host from `ddbd3ff` to **`d08842c`**. It
  was a fast-forward, with the four `delete mode` lines printed. The printed `pull_rc=0` was `tail`'s
  exit code, not git's. The evidence is the HEAD move and the fast-forward output.
- The two pre-existing untracked host files (`monitoring/prometheus.yaml.bak`,
  `wrappers/monitoring.app.yaml.disabled`) are still untracked and untouched. Nothing was stashed or
  reset.
- Host after the pull: `arrs/soulbeet.yaml` is gone, the include reads `#  - beets/beets.yaml`
  (line 39), and beets.yaml line 6 is `2.13.1-ls349`. No container was started, stopped or
  recreated. The survivor is dormant and not included, and 04-01 found no wrtag or soulbeet
  containers.

## Deviations from Plan

### 1. [Defective assertion] `test ! -e stacks/selfhosted/music` fails on a correct outcome

- **Found during:** Task 2 step 3.
- **What:** after the `git rm`, `stacks/selfhosted/music/` still exists on the workstation. It holds
  `.env` and `.env.backup`, both gitignored (`.gitignore:1 **/.env`, `.gitignore:11 *.env.backup`)
  and never tracked. The host shows the same thing: after the pull, `music/` holds only a gitignored
  `.env` (336 B, 2026-03-05). `arrs/soulbeet/` had no ignored files, so git removed it cleanly.
- **Why not "fixed":** these files are local, untracked, likely secret-bearing, not created by this
  plan, and not tagger definitions. Deleting them is irreversible and was not in the plan's action,
  which is `git rm`. The acceptance criterion the test stands in for, C1-a, is git-based and passes.
- **Handoff:** **04-05 (host runtime retirement) should decide the host `stacks/selfhosted/music/.env`**
  alongside the wrtag appdata. The operator may delete the workstation copies at will. Their
  contents were not read.

### 2. [Harness correction] The old-script control ran from a mirror tree, not as `$S/old.sh`

- **Found during:** Task 3, while designing control (a).
- **Issue:** `check-renovate.sh` sets `REPO_ROOT` from `dirname "${BASH_SOURCE[0]}"/..`. Run as
  `$S/old.sh`, it would `cd` to `$TMPDIR`, find no config and exit 1 with `no Renovate config
  found`. That is non-zero for the wrong reason, a control that cannot tell the defect from the
  harness.
- **Fix:** I built identical `mirror-old` and `mirror-new` trees (`scripts/check-renovate.sh` + a
  symlink to the real `stacks` + a copy of the real `renovate.json5`) and ran both under the same
  stub. The fixed script was also run from the real repo root, as the plan specifies. No repo file
  was affected.

### 3. [Addition] Two extra controls: b-old and d

- The plan asked for (a) old+fixed, (b) fixed and (c). I added **b-old** (the pre-fix script on the
  empty fixture, exit 1 at the line-90 inventory) so control (b) can also fail. I added **d** (the
  fixed script with the real validator on the `automerg` config, exit 1 red) so the changed
  line-62 branch is shown to fail closed, not only to pass.

### 4. [Minor] Explanatory comments beyond the one required

- Short comments were added above lines 62, 90 and 115 as well as the required one above 157.
  Comment lines only, with no behaviour change. They are covered by the acceptance greps, which
  exclude comment lines.

**Total deviations:** 1 defective assertion (recorded, not edited around), 1 harness correction, 2
added controls, and comment-only additions. No change beyond the plan's file list.

## Deferred Issues (out of scope, recorded only)

1. **check-renovate.sh lines 80/91/106 miscount an empty set as 1.** `echo "$X" | wc -l | tr -d ' '`
   counts the trailing newline of an empty string. Control (b) printed `Found 1 YAML files with
   Docker images` and `Unique images: 1` for a tree with **zero** images. It is a wrong count, not
   an abort, and it is outside D-22's five named lines. The fix is the same awk form.
2. **BSD-sed `\s` at lines 101-103 (A6).** Not touched, as the plan directed. The real run still
   produced `Unique images: 96`, but whether leading whitespace is stripped under BSD sed was not
   investigated.
3. **Estate-wide `-lsNNN` Renovate silence (F9).** Deferred by the CONTEXT rulings. Only the survivor
   is fixed here.

## Expected Next (not drift)

Per D-30, Renovate should now read `2.13.1-ls349` through the regex versioning, propose
**`2.13.1-ls350` as a PATCH** and automerge it in the repo. **That PR is expected and is not
drift.** The host stays on ls349 until a deliberate redeploy. It has not been observed yet: C2-b
and C2-c (Dependency Dashboard #3 no longer listing soulbeet or `music/wrtag.yaml`, and no
"Action Required" issue) are owned by 04-13 and must read "not yet observed" until Renovate has
run.

## Requirements

- **TAGR-03:** repo half satisfied. There is one tagger definition in git, and the Renovate config
  validates and governs it.
- **TAGR-04:** partially satisfied. The soulbeet definition and config are deleted and the pre-deletion SHA
  is recorded. Closing #306 is 04-07's job.
- STATE.md and ROADMAP.md were **not** touched, and no `gsd-sdk query state.*` or `roadmap.*` verb
  was called (orchestrator instruction). `git diff --stat 5d0af70 HEAD -- .planning/STATE.md
  .planning/ROADMAP.md` is empty.

## Known Stubs

None.

## Threat Flags

None. T-04-SC was mitigated by the human gate, the exact pin, `--ignore-scripts`, a scratch prefix
outside the repo (deleted), and no `npx`. T-04-03-01 was mitigated by the three validator gates and
row d. T-04-03-02 was mitigated by the byte-unchanged `:ro`, `restart: "no"` and `profiles:
["manual"]`. T-04-03-03 was mitigated because every compose render used `--quiet`. T-04-03-04 was
mitigated by manual review for minor and major with no ceiling. The anticipated ls350 automerge is
covered by D-30.

## Self-Check: PASSED

- FOUND commit `e63e0fd`; FOUND commit `d08842c`
- FOUND `renovate.json5`, `scripts/check-renovate.sh`, `stacks/selfhosted/arrs/beets/beets.yaml`, `stacks/selfhosted/arrs/compose.yaml`
- Git-tracked losers: none. STATE/ROADMAP diff since `5d0af70`: empty
- origin/main = local = host = `d08842c`
- Validator scratch `$TMPDIR/tmp.KfhQ3Yw791` removed; `git status --porcelain scripts/` empty
