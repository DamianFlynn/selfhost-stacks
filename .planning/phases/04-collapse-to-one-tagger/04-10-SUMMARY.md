---
phase: 04-collapse-to-one-tagger
plan: 10
subsystem: health-check
tags: [vendoring, audio.bash, drift-check, beets-config, candidate, d-08, d-09, d-10, d-11, d-13]

# Dependency graph
requires:
  - plan: 04-01
    provides: "the live audio.bash baseline (fdcddca2…, 339 lines, 10230 B), the live broken sabnzbd config sha 7a059a40…, and the ROUTINE BASELINE control (d) is compared against"
  - plan: 04-06
    provides: "the candidate-gate pattern (PROMOTED=0 constant + opt-in env var) this plan reuses for the drift block, and the pre-widened selector precedent"
  - plan: 04-08
    provides: "the third vendored file, stacks/selfhosted/arrs/beets/config.yaml, without which the drift block would cover two files instead of three"
  - plan: 04-09
    provides: "the spent D-17 ordering — the negative control had already run against the LIVE broken sabnzbd config, so this plan was free to fix it; and the survivor config installed on the host, which is why one of the three files is green"
provides:
  - "stacks/selfhosted/arrs/sabnzbd/audio.bash: vendored in two commits — byte-identical (fdcddca2…) then minus exactly one line"
  - "the beets invocation is gone from the repo copy of the hook; the SAB_PP_STATUS guard is byte-identical (50eada85…)"
  - "both sabnzbd vendored files bind-mounted :ro, closing the in-place-truncation half D-09 measured open at :rw"
  - "sabnzbd beets-config.yaml declares `plugins: embedart musicbrainz` (TAGR-05's sabnzbd half, in git)"
  - "quick-health-check.sh: the FIRST vendored-file drift block, fail-closed, gated as a CANDIDATE (VENDORED_DRIFT_PROMOTED=0)"
  - "four driven controls, each recorded firing and not firing; the routine path proven byte-equal to the 04-01 baseline finding set"
affects: [04-11, 04-12, 04-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-commit vendoring: the verbatim copy lands alone so the subsequent strip is a one-line diff a reviewer can read in full. No provenance header may be added to a file whose byte-identity is the assertion — the provenance goes in the compose NOTE instead"
    - "An override that exists only to drive a could-not-look branch must force red unconditionally, so it can never be repurposed to manufacture a green"
    - "A drift comparison is taken HOST-SIDE on both halves (`git show HEAD:<path>` and `sha256sum`), so the workstation's own checkout cannot produce either a false green or a false red"

key-files:
  created:
    - stacks/selfhosted/arrs/sabnzbd/audio.bash
    - .planning/phases/04-collapse-to-one-tagger/04-10-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/sabnzbd.yaml
    - stacks/selfhosted/arrs/sabnzbd/beets-config.yaml
    - scripts/quick-health-check.sh
  host-created: []   # DELIBERATELY EMPTY. This plan made no host appdata or container change; 04-11 owns installation.

key-decisions:
  - "The `beets-config.yaml` :rw -> :ro flip was TAKEN in this plan rather than deferred (D-09 left it to discretion). The evidence is 04-09's measurement that a :ro single-file mount into an LSIO /config logged zero EROFS at boot; 04-11's recreate is what proves it for sabnzbd specifically, and it owns the :rw rollback if the boot disagrees"
  - "A file whose hashes match prints NO per-file line when another file drifts; only the aggregate ✅ is suppressed. Chosen so the block's output is the failure list, not a status table. The survivor's equality is still evidenced — control (b) prints its repo and host hashes and they are equal"
  - "The 6th `EXIT-CODE BEHAVIOUR CHANGED` match I accidentally introduced was removed by REWORDING MY OWN COMMENT, never by touching the file's existing notices. The count is a greppable convention and this commit had no right to change it"

requirements-completed: []  # Neither is satisfied here. TAGR-04's strip and TAGR-05's sabnzbd half now exist IN GIT, but the host still runs the unstripped audio.bash and the broken config — which is exactly why the drift block is red. 04-11 installs them.
requirements-advanced: [TAGR-04, TAGR-05]

# Metrics
duration: ~35min
completed: 2026-09-13
---

# Phase 4 Plan 10: Vendored `audio.bash` and the First Drift Assertion Summary

**The beets invocation is out of the post-processing hook in git, removed as a one-line diff against a byte-identical vendored copy, with the SAB_PP_STATUS guard provably untouched. The estate now has its first repo-vs-host drift assertion — and its first run was red for real, naming both files the host has not been given yet, while the routine health check stayed exactly on its 04-01 baseline.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-09-13
- **Tasks:** 3 of 3
- **Files:** 1 created, 3 modified in the repo (4 task commits), plus this summary. **Zero host appdata changes, zero container changes.**

## Accomplishments

- **The strip is auditable rather than asserted.** Commit 1 is byte-identical to the live host file; commit 2 removes one line and adds none. A reviewer does not have to take the guard's survival on trust — lines 27-35 hash identically (`50eada85…`) on both sides of the strip.
- **D-09 is closed, not deferred.** Both sabnzbd vendored files are now `:ro`. Plan 01-07 measured `:rw` blocking the rename-based overwrite but **not** `> dest` truncation; `:ro` closes that second hole.
- **TAGR-05's sabnzbd half is in git**, and the config's own header no longer claims anything invokes it.
- **The drift block was driven red on real state**, not merely observed. It named both undelivered files with both hashes, and its two override classes were each driven: an additive expectation turned a genuinely-green file red, and an unreachable root produced UNKNOWN rather than a zero.
- **No red window.** REVIEWS row 1 is answered by the candidate gate: the routine run's exit code and `❌`/`⚠️` set are **identical** to the 04-01 ROUTINE BASELINE, not merely a subset.

## Task Commits

| Task | Name | Commit |
|---|---|---|
| 1a | Vendor `audio.bash` VERBATIM | **`d24d2e3`** |
| 1b | Strip the beets invocation | **`b4717d2`** |
| 2 | `:ro` mounts; `plugins: embedart musicbrainz` | **`0c3922a`** |
| 3 | The vendored-file drift block (candidate) | **`3c10a05`** |

**Plan metadata:** this SUMMARY's own commit.

## Delivery

| Item | Value |
|---|---|
| Pushed | `1ebc449..3c10a05  main -> main` |
| origin `refs/heads/main` | `3c10a057b8931adba9dbf90fc2abd8e1f73e300c` |
| Host `/mnt/fast/stacks` HEAD before | `fc6d35f` |
| Host HEAD after `git pull --ff-only` | **`3c10a05`** (fast-forward, `pull_rc=0`) |
| Host porcelain | the same 2 pre-existing untracked files, before and after — not mine, untouched |

The pull also carried the unpushed wave-4 tracking commit (`517c5b7`) and `04-09-SUMMARY.md`.

---

## Re-derivation: what had drifted since 2026-09-12 (answer: nothing I depend on)

The orchestrator's facts were ~36 h old and explicitly flagged as hearsay. Every one was re-measured
from the live estate before being acted on.

| Fact | Orchestrator / 04-01 value | Re-derived 2026-09-13 | Verdict |
|---|---|---|---|
| live `audio.bash` sha256 | `fdcddca234b2…` | `fdcddca234b282e4cb396764fa125fcacdbce350c21a94dd3f4ac024f87077ca` | **unchanged** |
| live `audio.bash` size | 339 lines / 10230 B | 339 lines / 10230 B, mtime 2026-07-31 | **unchanged** |
| live sabnzbd `beets-config.yaml` | 6407 B, `7a059a40…`, line 35 `plugins: embedart` | 6407 B, `7a059a40…`, line 35 `plugins: embedart` | **unchanged** |
| host survivor `config.yaml` | `a2f94cb6…` (04-09) | `a2f94cb6…` | **unchanged** |
| containers | 97 (`docker ps -a`) | 97 all-states; 96 running | consistent |
| beets image pin at HEAD | `2.13.1-ls349` | `2.13.1-ls349` | see below |
| host HEAD | `fc6d35f` | `fc6d35f` | 2 behind origin, pulled |

**The expected D-30 `ls350` automerge has NOT happened.** The repo pin is still `ls349` and Renovate
has not proposed a patch. Per C2-b that is recorded as **"not yet observed"**, which is not the same
as "working" and not the same as drift. Nothing was done about it.

---

## Task 1: the two-commit vendoring

### The credential screen (this repository is PUBLIC)

`grep -niE 'api_?key|token|passw|secret|bearer|://[^/ ]*:[^/ ]*@'` over the live file: **zero hits.**
Not "hits that were judged benign" — zero. The script reads its settings from
`/config/extended.conf` via `source`, so no value of any kind is embedded. Nothing is redacted and
there is no placeholder substituted. The same screen over the edited `sabnzbd.yaml` returns only the
pre-existing `${SABNZBD_API_KEY}` / `${SABNZBD_AUTH_BYPASS_KEY}` **variable references** (plus the
word "Password" in a feature-list comment), which are references, not values.

### Commit 1 — byte identity

| Check | Value |
|---|---|
| sha256 of the repo copy | `fdcddca234b282e4cb396764fa125fcacdbce350c21a94dd3f4ac024f87077ca` |
| sha256 of the **blob at `d24d2e3`** | `fdcddca234b282e4cb396764fa125fcacdbce350c21a94dd3f4ac024f87077ca` |
| `cmp` against the live file | **byte-identical** |
| lines / bytes | 339 / 10230 |
| first line | `#!/usr/bin/with-contenv bash` — identical to the live file's |
| mode | 100755 (the host file is 0777; the execute bit survives) |

**No provenance header was added to this file.** C3-a asserts byte identity against the live copy and
a header would break it. The provenance lives in the `sabnzbd.yaml` NOTE instead.

### Commit 2 — the strip, located by CONTENT

The plan named line 285 and the orchestrator warned that this phase's line numbers have drifted
before (04-01 found a block at 298-301, not 297-300). So the line was located by text and the number
was read off the result rather than trusted:

```
matching lines: 1
REAL LINE NUMBER: 285   (the plan's number HELD this time)
<TAB><TAB><TAB>beet -c /config/scripts/beets-config.yaml -l /config/scripts/library.blb -d "$1" import -q "$1"<EOL>
CONTENT-EXACT-OK
```

The match count was asserted to be exactly 1 before deleting anything, so a second occurrence could
not have been silently left behind.

| Check | Required | Measured |
|---|---|---|
| removed lines in the diff | 1 | **1** |
| added lines in the diff | 0 | **0** |
| lines after | 338 | **338** |
| `bash -n` | 0 | **OK** |
| `grep -cE '^[[:space:]]*beet '` | 0 | **0** |
| guard lines 27-35 sha256, before | — | `50eada85fba6b68a08db85456a21eb0139cbaf5eac25b9d1a02fd11cb7e732d2` |
| guard lines 27-35 sha256, after | same | **`50eada85fba6b68a08db85456a21eb0139cbaf5eac25b9d1a02fd11cb7e732d2`** |
| `diff` vs the vendored blob | one `<`, zero `>` | **1 / 0** |
| stripped file sha256 | — | `7e3bfe6117b6015fdd30c93514278d836bbdf25341936a9dd8d91160682ca028` |

The whole diff, in full:

```diff
@@ -282,7 +282,6 @@ Main () {
 		if [ $(find "$1" -type f -regex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l) -gt 0 ]; then
-			beet -c /config/scripts/beets-config.yaml -l /config/scripts/library.blb -d "$1" import -q "$1"
 			if [ $(find "$1" -type f ... -newer "/config/scripts/beets-match" | wc -l) -gt 0 ]; then
```

### The D-10 inventory — reported, NOT removed

Everything below stays. Phase 8 (INGS-01) owns this hook's eventual shape.

**Still active under today's `extended.conf`:**

| Lines | Step | What it does |
|---|---|---|
| 133–158 | `clean()` | deletes every non-audio file, flattens subdirectories, and deletes MP3s when FLACs are present |
| 160–165 | `detectsinglefilealbums()` | `exit 1` above `MaxFileSize` |
| 167–188 | `verify()` | `flac -t`; on failure **`rm -rf "$1"/*`** |
| 269–301 | `beets()` body minus the invocation | the `Matching N tracks with Beets` log line, the transient `beets-match` touch/rm, and the `rm library.blb` at 272–275 |
| 322–324 | the `BeetsTagging = TRUE` gate | still calls `beets()` |
| 334–335 | `chmod 777/666` | fails EPERM on `tank` → the **baseline** `Exit(1)`, recorded on every music job since at least 2026-08-01 |

**Inactive under today's `extended.conf`:** `replaygain()`/`r128gain` (`ReplaygainTagging="false"` —
the only other tag writer), `conversion()` (`ConversionFormat="FLAC"`), `AudioQualityMatch()` (unset).

**Consequence:** after the strip **no tag-writing step is active at all**, which is what makes D-12's
"the folder lands untagged" a true expectation rather than a hope — and it is **conditional on
`ReplaygainTagging` staying `"false"`**, which 04-12 must re-assert for its observation window.

**Confirming REVIEWS' refutation of Grok H2:** lines 272–275 are
`if [ -f /config/scripts/library.blb ]; then rm …` — existence-guarded, so after 04-11 deletes that
file the `rm` cannot abort `beets()` under `set -e` before the baseline `chmod`. Read directly from
the vendored file rather than taken from the review.

**Residual supply-chain input, recorded not fixed (T-04-10-05):** `scripts_init.bash` still runs
`pip install -U beets` on every container boot. Nothing invokes beets after the strip; Phase 8 owns it.

---

## Task 2: `:ro` mounts and the defused config

### `sabnzbd.yaml`

| Check | Required | Measured |
|---|---|---|
| non-comment `audio.bash:/config/scripts/audio.bash:ro` | 1 | **1** |
| non-comment `beets-config.yaml:/config/scripts/beets-config.yaml:ro` | 1 | **1** |
| non-comment `beets-config.yaml:…:rw` | 0 | **0** |
| `grep -c 'Plan 01-09 folds'` | 0 | **0** |
| `grep -c 'soulbeet'` | 0 | **0** |

Four pieces of now-false text were corrected in the same edit, per the 04-PATTERNS table:

- the claim that this config is handed to beets on **every** music download — nothing reads it after the strip;
- `Same hybrid shape as arrs/soulbeet.yaml` — that file is deleted; re-pointed at `arrs/beets/config.yaml`;
- `the plugins line is knowingly broken … Phase 4 TAGR-05 owns it` — fixed in the same commit;
- the claim that an earlier plan had **already** folded a repo-vs-host comparison into
  `quick-health-check.sh`. Research F6 measured that no such comparison was ever built. Following the
  file's own withdrawn-claim convention it is **paraphrased, never quoted**, so a mechanical grep for
  it over this repo keeps returning zero — and it is re-pointed at the block that now does exist
  **by its section heading**, not by line number, since a stale pointer is how it survived this long.

### `beets-config.yaml`

The **only** non-comment change in the entire file:

```diff
-plugins: embedart
+plugins: embedart musicbrainz
```

| Check | Required | Measured |
|---|---|---|
| `grep -cx 'plugins: embedart musicbrainz'` | 1 | **1** |
| `grep -cx 'plugins: embedart'` | 0 | **0** |
| `grep -c 'auto: no'` | 3 (unchanged) | **3** |
| `grep -c 'soulbeet'` | 0 | **0** |
| credential re-screen (the file's own rule) | clean | **zero hits** |

`log: /config/scripts/beets.log` was **kept with the reason recorded inline** (D-10 scope; nothing
writes it now; 04-11 deletes the host file).

### Gate

`docker compose -f stacks/selfhosted/arrs/compose.yaml config --quiet` → **exit 0**, run
workstation-side. It was then **driven to fail** so the zero is known to discriminate: exit 1 on a
malformed scratch compose file (`yaml: line 1: did not find expected key`) and exit 1 on a missing
file. Every compose invocation used `--quiet`.

---

## Task 3: the drift block, and the four controls

### Shape

One bounded `ssh -n`, remote string starting `set -o pipefail`, `DRIFT_RC=$?` on the line directly
after the assignment with no local pipe, branch order empty → 124 → other non-zero → assert, every
UNKNOWN setting `EXIT_CODE=1`, and **no `info()` anywhere in the block**. Both halves of every
comparison are computed **host-side**, so the workstation checkout is irrelevant.

| `<verify>` check | Required | Measured |
|---|---|---|
| `/bin/bash -n` (bash 3.2.57) | 0 | **OK** |
| `grep -c 'EXIT-CODE BEHAVIOUR CHANGED'` | 5 (unchanged) | **5** |
| `grep -cx 'VENDORED_DRIFT_PROMOTED=0'` | 1 | **1** |
| non-comment `DRIFT_EXPECT_AUDIO_BASH` | ≥1 | **2** |
| `info ` inside the block | 0 | **0** |
| failure tail names the block | yes | **yes** |

### The four driven controls

Counts below are taken over the drift block **only**, with the next block's header excluded
(see Deviation 2 — my first instrument got this wrong).

| Control | Exit | `❌` in block | `⚠️` in block | `✅` in block |
|---|---|---|---|---|
| (a) candidate, real state | **1** | **2** | 0 | **0** |
| (b) + additive expectation | **1** | **3** | 0 | **0** |
| (c) + unreachable root | **1** | 0 | **2** | **0** |
| (d) ROUTINE, no env | **0** | 0 | 0 | 0 (block prints one CANDIDATE line) |

**(a) — the real negative control.** Red because the host has not been given these files; 04-11 is
what turns it green.

```
Vendored-file drift:
  ❌ audio.bash DRIFTED — repo=7e3bfe6117b6015fdd30c93514278d836bbdf25341936a9dd8d91160682ca028 host=fdcddca234b282e4cb396764fa125fcacdbce350c21a94dd3f4ac024f87077ca
  ❌ sabnzbd-beets-config.yaml DRIFTED — repo=ba7ef255a9580dae78a36abd54b11d12f508c3c9bde52e7d884f8c8110452370 host=7a059a407d3ca18c9d7902c96267f75fa17ae134daf21d64f8bcbf7c073ee6ea
```

Both hashes are named for each file, and the two are exactly the two files 04-11 installs. The
survivor config is **not** listed — it matches, because 04-09 installed it.

**(b) — an additive override turns a genuinely green file red.**

```
  ❌ survivor-config.yaml DRIFTED — repo=a2f94cb6…e3c9e9 host=a2f94cb6…e3c9e9 expected-override=0000…0000
```

Note `repo` and `host` are **equal** on that line: this is the proof that the survivor file really is
green in control (a), and simultaneously the proof that an override cannot produce a pass — only an
extra failure.

**(c) — could not look, and it says so.**

```
Vendored-file drift:
  ⚠️  DRIFT_APPDATA_ROOT override in effect — this run cannot report the vendored files green
sha256sum: /nonexistent-04/arrs/sabnzbd/config/scripts/audio.bash: No such file or directory
  ⚠️  UNKNOWN — could not look: the drift comparison produced no output (ssh exit 5).
  Nothing was compared. This is NOT 'the vendored files match'.
```

Exit 1, zero `✅`, and the remote's own stderr is visible rather than swallowed.

**(d) — ROUTINE PATH UNCHANGED.** This is the criterion the candidate gate exists to protect.

| Check | 04-01 ROUTINE BASELINE | This run |
|---|---|---|
| exit code | **0** | **0** |
| `❌` lines | sole `Traefik dashboard: ❌ Not accessible` | **sole `Traefik dashboard: ❌ Not accessible`** |
| `⚠️` lines | none | **none** |
| `DRIFTED` leaked | — | **0** |
| freeze fold-in | `✅ Intact` | `✅ Intact` |
| consumers / transcode fold-ins | `✅` | `✅` / `✅` |

The block printed exactly:

```
Vendored-file drift: CANDIDATE — not in the routine check until plan 04-11 promotes it (VENDORED_DRIFT_CANDIDATE=1 to run it)
```

**The finding set is identical to the baseline, not merely a subset.** `Containers running: 96` is
the count of **running** containers (`docker ps -q`), consistent with the 97 all-states containers
counted separately — two different queries, not a change in the estate.

---

## Deviations from Plan

### 1. [Defective assertion — recorded, NOT satisfied] Task 1's `<verify>` is timing-dependent

- **Found during:** final verification.
- **Issue:** the `<verify>` reads `git diff HEAD~1 -- $f`. That is only correct while the strip is the
  tip commit. By the time Tasks 2 and 3 had committed, `HEAD~1` was the Task 2 commit and the
  expression measured **0** removed lines, so it **fails on a completely correct outcome**. Executed
  and recorded as written: `AS-WRITTEN: FAIL`.
- **Resolution:** recorded as defective rather than satisfied. **No commit was reordered, amended or
  re-pointed to make a grep pass.** The intent — "the strip commit removes exactly one line and adds
  none" — was evaluated against the correct pair (`d24d2e3` → `b4717d2`): `removed=1 added=0
  lines=338` → **`TASK1-VERIFY-PASS`**.
- **Downstream:** any plan asserting a per-commit diff should name the commit pair, not `HEAD~N`.

### 2. [My own defective instrument, caught and re-measured] the `✅` count for control (c)

- **Found during:** Task 3, control (c).
- **Issue:** I counted `✅` with `sed -n '/^Vendored-file drift/,/^Music freeze harness/p'`. A `sed`
  range is **inclusive of its terminator**, so the range ended on `Music freeze harness: ✅ Intact`
  and my check reported `1` — apparently a `✅` printed by a block that had just failed.
- **Resolution:** the defect was in my grep, not in the block. Re-measured with an `awk` range that
  excludes the terminator: **0 `✅` inside the drift block** for all four controls. The block's
  verbatim output (quoted above) shows only the two `⚠️` lines.
- **Recorded because the near-miss matters:** had I read that `1` as a real finding I would have
  "fixed" a block that was behaving correctly.

### 3. [My own defective instrument] exit codes read through a pipe, twice

- **Found during:** the compose gate.
- **Issue:** I wrote `docker compose … | head -5` then read `$?`, which is **`head`'s** status, not
  compose's. It printed `compose_gate_rc=0` while telling me nothing, and the same shape made a
  failing `docker version` look like `rc=0`. This is the estate's own documented
  `timeout N cmd | wc -l` hazard in a new costume.
- **Resolution:** re-measured with no pipe, redirecting to files. Real results: `docker version`
  **rc 1** (daemon socket absent), `docker compose config --quiet` **rc 0** with empty stderr.

### 4. [Self-correction] I introduced a 6th `EXIT-CODE BEHAVIOUR CHANGED` match

- **Found during:** Task 3 `<verify>`.
- **Issue:** my new constant block described what 04-11 will add and **quoted the literal phrase**,
  taking the count from 5 to 6. That phrase is a greppable convention in this file, and this commit
  has no business changing its count — the plan asserts it stays at its pre-edit value.
- **Resolution:** reworded **my own comment** so the phrase is described rather than spelled out.
  Count back to **5**. **No existing notice was touched.**

### 5. [Ordering — differs from 04-08's finding] the compose gate DID run workstation-side

- 04-08 deviation 1 recorded the gate as unrunnable on this workstation because the Docker daemon is
  not running, and concluded such gates must run host-side.
- **Measured here:** the daemon is indeed down (`docker version` → rc 1, socket absent), but
  `docker compose config` is a **client-side** operation that parses and validates the compose files
  without contacting the daemon. It returned **rc 0** with empty stderr.
- Because a bare zero from a tool whose daemon is dead deserves suspicion, the gate was **driven to
  fail** (rc 1 on malformed YAML, rc 1 on a missing file) before the zero was believed.
- **Downstream:** `docker compose config` needs no daemon; commands that inspect or run containers
  still do.

### 6. [My own defective instrument] the self-check's STATE/ROADMAP baseline was wrong

- **Found during:** the self-check, before this SUMMARY was committed.
- **Issue:** I asserted "STATE.md and ROADMAP.md untouched" by diffing against `1ebc449`, the origin
  tip at plan start. That reported **both files as modified** — which would have read as this plan
  violating its own hard constraint. The workstation carried a **pre-existing unpushed commit**,
  `517c5b7 docs(phase-04): update tracking after wave 4` (authored 2026-09-12, the orchestrator's
  own wave-4 tracking commit), which is the commit that touched them.
- **Resolution:** the correct baseline is `517c5b7`, confirmed to be the **parent of my first
  commit** (`git rev-parse d24d2e3^` → `517c5b7`). Against it, `git diff --name-only 517c5b7 HEAD --
  .planning/STATE.md .planning/ROADMAP.md` is **empty**, and my five commits touch exactly five
  files. **Nothing was reverted or rewritten to make this true** — the finding was an artefact of my
  measurement, and the underlying work was already correct.
- **Recorded rather than silently corrected**, because a reader who re-runs the obvious
  `origin-at-start..HEAD` diff will see the same misleading result. Use `517c5b7..HEAD`.

### 7. [Design note, not a defect] a matching file is silent when another drifts

The block prints a line per **failure**, plus one aggregate `✅` when all three match. So in control
(a) the green survivor file produces no output at all. That is deliberate — the block's output is a
failure list, not a status table — but it means "green" is proven by the **absence** of a line, which
this estate is rightly suspicious of. Control (b) closes that gap by printing the survivor's repo and
host hashes and showing them equal. Recorded so 04-11 knows what a fully-green run looks like: one
`✅ vendored files match (3): …` line and nothing else.

---

**Total deviations:** 7 — 1 defective plan assertion recorded, **3 defective instruments of my own**
caught and re-measured, 1 self-correction, 1 ordering finding that reverses a prior plan's
conclusion, 1 design note. **None weakens an assertion, no control was made to pass by editing prose,
deleting a file or changing the estate, and no evidence was fabricated.**

Worth naming the pattern: three of the seven are **my instruments being wrong, not the estate**
(a `sed` range that swallowed the next block's `✅`, an exit code read through a pipe, and a diff
baseline that included someone else's commit). Each produced a plausible-looking wrong answer —
a green that was not green, a zero that was `head`'s, and an apparent violation of this plan's
own hard constraint. All three were caught by re-measuring rather than by reasoning.

## Threat Flags

None. No new network endpoint, auth path or trust boundary. The register's six entries:

- **T-04-10-01 (audio.bash in a public repo)** — credential screen before commit 1: zero hits, HALT
  condition never reached. Re-screened `sabnzbd.yaml` and `beets-config.yaml` after editing.
- **T-04-10-02 (silent revert by setup.bash / in-container write)** — both vendored files now `:ro`,
  which blocks the rename **and** the truncation; the fail-closed drift block detects the host-side
  edit that `:ro` cannot prevent, and it has been seen to fire.
- **T-04-10-03 (failed downloads post-processed)** — SAB_PP_STATUS guard asserted byte-identical by
  hash on both sides of the strip (`50eada85…`).
- **T-04-10-04 (drift false-green)** — "could not look" is a distinct verdict in three separate
  branches, all setting `EXIT_CODE=1`; expectations are additive only; a non-default root forces red;
  three driven controls plus the routine control.
- **T-04-10-05 (`pip install -U beets` at boot)** — **accepted**, recorded above. Nothing invokes
  beets after the strip; Phase 8 owns the hook's shape.
- **T-04-10-06 (permanent red in the routine check)** — the candidate gate, with control (d) proving
  the routine run sits exactly on the 04-01 baseline.

## Known Stubs

None. The drift block is fully implemented; it is **gated**, which is a deliberate lifecycle state
with a named owner (04-11), not a stub. The two red files are red because the estate has not been
changed yet — that is the plan's intent, stated in the block's own comment.

## Issues Encountered

- **No host appdata or container change was made**, per this plan's REPO-ONLY scope. Host contact was
  limited to `git pull --ff-only` and read-only hashing performed by the health check itself.
- No credential, `.env` value or release name was printed at any point; every compose invocation used
  `--quiet`.
- The host's two pre-existing untracked files were left exactly as found. A host
  `git status --porcelain` is non-empty **by design**, so any assertion demanding an empty porcelain
  remains defective (04-06 deviation 2).

## Next Phase Readiness

- **04-11** inherits both halves of its own gate. To turn control (a) green it must install the two
  files on the host, after which a run prints one `✅ vendored files match (3): …` line; it then sets
  `VENDORED_DRIFT_PROMOTED=1` in that same commit and adds the exit-code notice the promotion earns
  (this plan deliberately added none).
- **04-11's `:ro` recreate** now has a declared `audio.bash` mount to boot against. 04-09's prior
  stands: a `:ro` single-file mount into an LSIO `/config` logged zero EROFS on this estate. sabnzbd
  additionally runs `scripts_init.bash`'s `chmod 777 -R /config/scripts`, so its result may differ —
  and the rollback to `:rw` is 04-11's, with the `:ro` line in `sabnzbd.yaml` the only thing to revert.
  Carry 04-09's init-race lesson verbatim: **wait for readability, never for `running`**, and print a
  log's byte count beside any grep taken over it.
- **04-11 must also still decide** what to do about the survivor's 11 migration `.bak` (04-09
  Deviation 3). Unchanged by this plan.
- **04-12** should re-assert `ReplaygainTagging="false"` for its observation window: the D-10
  inventory above shows that is the single condition on which "the folder lands untagged" depends.
  The two residual `Audio.txt` lines remain expected and pre-declared.
- **PR #310 (sabnzbd 5.1.3) was open at 04-01** and 5.1.3 was not resident. 04-11 must re-check image
  residency of the exact tag in `sabnzbd.yaml` before `up -d sabnzbd` (Pitfall 8).

## Self-Check: PASSED

- FOUND all four task commits: `d24d2e3`, `b4717d2`, `0c3922a`, `3c10a05`; the tip is on
  `origin/main` (`3c10a057b893…`) and on the host at `3c10a05`.
- FOUND `stacks/selfhosted/arrs/sabnzbd/audio.bash` (338 lines, `bash -n` clean, zero `beet`
  invocations); the blob at `d24d2e3` hashes to `fdcddca234b2…`, equal to the live host file.
- FOUND `stacks/selfhosted/arrs/sabnzbd.yaml`, `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml`,
  `scripts/quick-health-check.sh`, and this SUMMARY.
- Task 1 `<verify>` PASSES against the correct commit pair (as-written form recorded defective);
  Task 2 `<verify>` → `TASK2-VERIFY-PASS`; Task 3 `<verify>` → `TASK3-VERIFY-PASS`.
- All four controls executed with exit codes captured: (a) 1, (b) 1, (c) 1, (d) **0**. Each recorded
  firing and not firing.
- Routine run exit 0 with exactly the 04-01 baseline finding set; zero census or drift rows leaked.
- **No host appdata path, container, image, DNS record or GitHub issue was touched.**
- **`.planning/STATE.md` and `.planning/ROADMAP.md` were NOT modified by this plan, and no
  `gsd-sdk query state.*` or `roadmap.*` verb was called.** Measured against the correct baseline
  `517c5b7` — the parent of this plan's first commit — where
  `git diff --name-only 517c5b7 HEAD -- .planning/STATE.md .planning/ROADMAP.md` is **empty**.
  **Do not diff from the origin tip at plan start (`1ebc449`):** the workstation carried a
  pre-existing unpushed wave-4 tracking commit that does touch both files, and that baseline
  reports a false violation (Deviation 6).
- My five commits touch exactly five files:
  `stacks/selfhosted/arrs/sabnzbd/audio.bash`, `stacks/selfhosted/arrs/sabnzbd.yaml`,
  `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml`, `scripts/quick-health-check.sh`,
  `.planning/phases/04-collapse-to-one-tagger/04-10-SUMMARY.md`.
- No commit deleted any tracked file (`git diff --diff-filter=D --name-only 517c5b7 HEAD` empty).

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-13*
