---
phase: 03-tagger-spike
plan: 08
subsystem: criterion-3-wrtag-disqualifier
tags: [wrtag, path-format, renovate-pin, dry-run, mount-layer-safety, manifest-diff, TAGR-02, TAGR-03, D-01, D-03, D-22, OD-5]
requires:
  - "03-01 — the OD-1 disk-headroom gate and the three sentriz/wrtag image pulls"
  - "03-02 — the pre-committed thresholds this plan fills result cells in but does not touch"
  - "03-03 — the spike-03 scratch tree, the atlantis reflink route, and the D-10 album candidates"
provides:
  - "scripts/spike03-wrtag-arms.sh — one dry-run harness, three image tags, path format read verbatim from the frozen file"
  - ".planning/phases/03-tagger-spike/03-WRTAG-EVIDENCE.md — criterion 3 answered at three tags on two disc classes"
  - ".planning/phases/03-tagger-spike/03-wrtag-ablation-format.yaml — the one-line migration that isolates the cause of the startup refusal"
  - "the corrected pin analysis Phase 4's TAGR-03 must cite instead of renovate.json5:91's field list"
  - "the criterion 4 wrtag rows and the axis-one path-format cell in 03-DECISION.md"
  - "12 captured arms at /mnt/fast/spike-03/out/wrtag-*.{stdout,stderr,meta} and 96 subtree manifests"
affects:
  - "Phase 4 TAGR-03 — owns releasing the Renovate pin and rewriting renovate.json5:91; must cite this, not the field list"
  - "03-11 — the axis-one verdict reads the criterion 3 row from here; teardown must also remove spike-03/wrtag-src (1.2 G)"
  - "03-07, 03-09, 03-10 — any wrtag or MusicBrainz arm must pin the release MBID or it is not holding the disc class constant"
tech-stack:
  added: []
  patterns:
    - "Reading the string under test out of the frozen file at run time and recording its sha256, so the test cannot silently measure a re-typed copy"
    - "A positive allow-list on the write destination instead of a deny-list, so the script never has to name the path it must not touch — and the read-only contract greps assert literally"
    - "An ablation that changes exactly one thing, used to isolate the cause of a refusal rather than to argue about it"
    - "Pinning the upstream identifier (MBID) so the experimental class is a controlled variable rather than a property of a third-party database"
key-files:
  created:
    - scripts/spike03-wrtag-arms.sh
    - .planning/phases/03-tagger-spike/03-WRTAG-EVIDENCE.md
    - .planning/phases/03-tagger-spike/03-wrtag-ablation-format.yaml
  modified:
    - .planning/phases/03-tagger-spike/03-DECISION.md
decisions:
  - "Both ends of the wrtag pin are broken: v0.20.0 runs and renders `-1 - ` on every single-disc track; v0.33.0 and v0.34.0 refuse the format at startup with exit 2. CLAUDE.md's and PROJECT.md's 'the existing path format works unchanged at v0.33.0' is falsified"
  - "The sole cause of the startup refusal is the `Disc N/` SUBDIRECTORY, proven by a one-line ablation that changes nothing else and validates at both current tags"
  - "renovate.json5:91 names four fields and all four exist at v0.20.0; the one field genuinely absent, `.Media`, is the one it does not name"
  - "The disc class of a wrtag arm is a property of MusicBrainz, not of the folder — a 21-file no-disc-tag album resolved to a two-medium vinyl release on the first unpinned run. Arms must pin the MBID"
  - "TAGR-02's tags.Clear finding is recorded as a SOURCE READ, not a runtime observation, because -dry-run skips the write AND logTagChanges structurally cannot log a tag that is about to be wiped"
  - "The single-disc/multi-disc pair was drawn from ONE album under two pinned MBIDs rather than two folders, so the only difference between the classes is len(.Release.Media)"
metrics:
  duration: "~1h"
  completed: 2026-09-03
---

# Phase 3 Plan 08: The wrtag Path-Format Disqualifier Summary

Ran criterion 3 at three wrtag tags on two disc classes and found the pin is not inverted but
**broken at both ends** — v0.20.0 renders `-1 - ` as the track number on 21 of 21 paths, while
v0.33.0 and v0.34.0 **refuse this repo's path format at startup and exit 2 before reading a
file** — falsifying the "v0.33.0 works unchanged" claim carried in `CLAUDE.md`, `PROJECT.md`,
`03-RESEARCH.md` and `03-DECISION.md`, and isolating the sole cause to the `Disc N/`
subdirectory with a one-line ablation.

## What was built

**`scripts/spike03-wrtag-arms.sh`** (373 lines) — one `wrtag move -dry-run` harness taking
`--album`, `--image`, `--class`, `--mbid` and `--yes`, so three tags are three invocations of one
code path rather than three scripts.

Three design choices carry the weight:

1. **`WRTAG_PATH_FORMAT` is extracted from `$WRTAG_YAML` at run time and its sha256 recorded.**
   A re-typed copy would measure a string this repo does not use. Comment-stripped `grep -c
   'Compilations/'` returns **0** — no format string is embedded, and there is no way to pass one
   on the command line.
2. **The write destination is confined by a positive allow-list** (`/mnt/fast/spike-03/`), not a
   deny-list. A deny-list would have to name the real library; the allow-list refuses everything
   outside the phase's own scratch root *and* lets the file contain no reference to
   `/mnt/tank/media` at all — comment-stripped `grep -c` returns **0**. Same "absence beats
   detection" property plan 03-04 built the beets mounts on.
3. **Wrote-nothing is asserted per arm by two instruments**, never once at the end, so a single
   writing arm would be attributable. `find -newer` on both mounts is the cheap first; a
   whole-subtree `%p\t%s\t%T@` listing plus `sha256sum` over every file in `$SRC` and `$LIB`,
   diffed before against after, is the independent second. The five-file spot hash is retired
   phase-wide: it passes a tool that preserves mtimes and it passes any write outside the sample.

**`.planning/phases/03-tagger-spike/03-WRTAG-EVIDENCE.md`** — the six primary arms, the six
ablation arms, the corrected pin-inversion proof with both `Data` structs verbatim, why startup
validation never caught it, the v0.33.0-vs-v0.34.0 no-op, the explicitly-non-evidence list, the
TAGR-02 `tags.Clear` finding with its provenance stated, and the attribution of 12 backlog files
that changed during the run.

**`.planning/phases/03-tagger-spike/03-wrtag-ablation-format.yaml`** — the same format with the
disc component moved out of the directory and into the filename. Labelled `THROWAWAY — DO NOT
DEPLOY` on line 1, and explicitly **not** a proposed migration.

## Results

| Assertion | Result |
|---|---|
| `bash -n scripts/spike03-wrtag-arms.sh` | **exit 0** |
| Comment-stripped `grep -c "Compilations/"` (GNU grep, LXC 100) | **0** |
| Comment-stripped `grep -c "/mnt/tank/media"` | **0** |
| Comment-stripped `/music/source:ro` / `:rw` | **1** / **0** |
| Comment-stripped `WRTAG_PATH_FORMAT=` read out of `$WRTAG_YAML` | **3 lines**, incl. the `grep -m1` extraction |
| Nonexistent `--album`; no arguments | **exit 2**, **exit 2** |
| Committed script sha256 == staged-on-LXC sha256 | `54f2263f…` both |
| Primary stdout captures, one per arm | **6** |
| Total arms run and captured | **13** (6 primary + 6 ablation + 1 unpinned natural-match) |
| **v0.20.0 single-disc: rendered paths beginning `-1 - `** | **21 of 21** |
| **v0.20.0 multi-disc** | `can't evaluate field Media in type pathformat.Data`, container exit **1** |
| **v0.33.0 / v0.34.0, both classes** | **startup refusal**, `ambiguous format: multiple directories created for the same release`, container exit **2** |
| v0.33.0 refusal stderr, both classes | byte-identical, `8326eaa4…` |
| v0.34.0 refusal stderr, both classes | byte-identical, `6dd54332…` |
| Ablation: v0.33.0 / v0.34.0 startup validation | **passes** — the disc subdirectory is the sole cause |
| Ablation: `-1 - ` components at v0.33.0 / v0.34.0 | **0** in all four arms |
| Ablation: v0.33.0 vs v0.34.0 rendered path sets | **byte-identical** — single-disc `860581e1…`, multi-disc `a12d113c…` |
| Ablation multi-disc: disc components rendered | `Disc 1-` ×11, `Disc 2-` ×10 — the real 11/10 split |
| `grep -c "Track.Position = -1"` at v0.20.0 / v0.33.0 / v0.34.0 | **1** / **0** / **0** |
| `Media` field in `pathformat.Data` at v0.20.0 / v0.34.0 | **absent** / **present** |
| v0.20.0 `validate()` synthetic media per release | **1**, always (`pathformat.go:143-159`) |
| Path-format sha256, recorded vs fresh re-extraction | `3d977d43…` both |
| Ablation-format sha256, recorded vs fresh re-extraction | `3a38b604…` both |
| **Wrote-nothing, instrument 1** (`find -newer`, both mounts) | **0 lines**, all 12 harness arms |
| **Wrote-nothing, instrument 2** (subtree manifest diff, `.meta` + `.sha`, both trees) | **empty**, 48 of 48 diffs |
| `$LIB` empty at the start of each arm / at the end of each arm | **0 entries** / **0 entries**, all 12 |
| Subtree manifests written | **96** |
| Frozen files in this plan's diff (D-03) | **none** — `wrtag.yaml`, `beets.yaml`, `renovate.json5` all untouched |
| `bash scripts/check-music-freeze.sh` | **exit 0** — `tagger-class writers: 0`, `declared rw reaching Music: 0`, `unclassified writers: 0`, `FAILURES total: 0` |
| wrtag containers in `docker ps -a` | **none** — every arm used `--rm` |
| `df -h /` on LXC 100 | 35 G free, unchanged across the plan |

## The findings that outlive this plan

**1. Both ends of the pin are broken, and the newer end fails closed.** `renovate.json5:91` holds
wrtag at `<0.30.0` on the stated grounds that *"without this rule the automerge rules above would
silently land v0.33.0 and break music tagging again."* Measured: landing v0.33.0 would stop wrtag
from **starting** — exit 2 with a named, actionable error, on both disc classes, before any file
is read. That is strictly the safer of the two failures. The state the rule is protecting is the
one that silently renamed every file it ever moved to `-1 - Title.ext`. **The rule is not just
wrong about which fields; it is wrong about which direction is dangerous.**

**2. The cause is one subdirectory, and it is provable rather than arguable.** v0.30.0's release
notes list *"pathformat: add validations for multi disc releases"* as a **feature**; the block is
`pathformat.go:186-206`, which builds a synthetic two-medium release and refuses if
`filepath.Dir(path)` differs across its tracks. This repo's format sends disc 1 to `Disc 1/` and
disc 2 to `Disc 2/`. The ablation moves that one component into the filename, changes nothing
else, and both current tags validate and render. **The validation that would have caught
v0.20.0's silent breakage is the same validation that now rejects the format** — which is why
these are one finding and why "just unpin it" is not a fix.

**3. All four fields `renovate.json5:91` names are innocent; the guilty one is unnamed.**
`.Release.Date.Year` rendered `(2023)`, `.Release.Media` is read by v0.20.0's own `validate()`,
`.Track.Position` is a `musicbrainz.Track` field, `artistsString` is registered at
`pathformat.go:204`. The field genuinely absent from v0.20.0 is **`.Media`**. Phase 4 rewriting
that rule with the version numbers swapped would carry the same wrong analysis forward. The
v0.30.0 migration table (`.TrackNum`, `len .Tracks`, `.Tracks`) was read correctly as not
applying to this repo — what was missed is the validation shipped alongside it.

**4. The disc class of a wrtag arm is a property of MusicBrainz, not of the folder.** The very
first, unpinned arm took a 21-file, no-`disc`-tag, `track=N/21` album and got back
`b08e07b5-…`, a **two-medium 12" vinyl** release (11 + 10), then hard-errored on
`.Media.Position`. wrtag queries `…&limit=1&query=…tracks:(21)^10` and takes what comes back;
at least two of the twelve score-100 MB releases for this album are two-medium. **The
`.Media.Position` failure is not an exotic box-set case — it fires on an ordinary single-CD rip
whenever MusicBrainz happens to return a vinyl edition.** Any later plan that means to hold the
disc class constant must pin the MBID; one that does not is measuring MusicBrainz's mood. That
capture is kept as `wrtag-v0.20.0-natural-unpinned.stderr`.

**5. wrtag's most verbose instrument is structurally blind to the tag loss that matters.**
`logTagChanges` iterates `for k := range **after**` (`wrtag.go:1212-1219`), so a tag present in
the source and absent from wrtag's computed set — precisely the 148 `TKEY` / 45 `EnergyLevel`
case — is **never logged, even at DEBUG**. Arm 1 produced 588 tag-change lines and **zero**
`to=[]` lines, and that is not reassurance. So the `tags.Clear` finding stays a source read for
two independent reasons, not one: `-dry-run` skips the write, and the debug log could not have
shown it even if it had not.

**6. Three arms hit MusicBrainz 503s and v0.20.0 gave up on the first one.** Each needed a manual
re-run. v0.34.0's changelog adds *"musicbrainz: retry on 503, bump retry limit to 5"* and a 60 s
client timeout. Minor next to finding 1, but it is a real operational difference between the tags
and it was measured rather than read.

## Deviations from Plan

### 1. [Rule 3 - Blocking] The source population the plan names cannot satisfy its own acceptance criteria

- **Found during:** Task 2, before staging.
- **Issue:** The plan says *"Choose two albums from `/mnt/tank/downloads/spike-03/`"*. That tree
  holds only the 24-folder DJ draw — Mastermix and DMC — which is the exact content this phase
  exists to establish MusicBrainz does **not** carry. wrtag is MusicBrainz-only, so no arm on
  that population can render a destination path at all, and the criteria *"the v0.20.0
  single-disc arm's rendered path contains `-1 - `"* and *"the v0.20.0 multi-disc arm produces a
  Go template execute error naming `Media`"* are unreachable from it.
- **Fix:** the album was drawn from 03-SAMPLE.md's own D-10 candidate list —
  `Taylor.Swift-1989..Taylors.Version.-WEB-2023-MyMo`, slot `clean-1`, 21 MP3, flat, verified
  single-artist — and reflinked into `spike-03/wrtag-src/` **on atlantis**, the 03-03 route
  (`FICLONE` is EPERM inside the unprivileged container), with `chown 568:568` and no `chmod`.
- **Commit:** operational; the staging is recorded in `03-WRTAG-EVIDENCE.md` § *The six arms*.

### 2. [Rule 1 - Bug] The disc class was not a controlled variable

- **Found during:** Task 2, on the first arm.
- **Issue:** finding 4 above. The plan's method — pick "one genuinely single-disc and one
  genuinely multi-disc folder" — cannot work, because the branch under test is
  `{{ if gt (len .Release.Media) 1 }}`, which reads the **matched MusicBrainz release**, not the
  folder. My "genuinely single-disc" folder produced the multi-disc failure.
- **Fix:** added `--mbid` to the harness and pinned the release per class, **the same MBID to all
  three tags**. Both releases were taken from the same MB query at score 100 and both have 21
  tracks: `9b0c97d3-…` (CD, 1 medium) and `b08e07b5-…` (2×12" vinyl, 11+10) — the latter being
  the release MusicBrainz itself chose, unprompted, on the first run. This makes the only
  within-class difference the image and the only between-class difference
  `len(.Release.Media)`, which is a **stronger** experiment than two different folders, not a
  weaker one: any difference in output is attributable to the medium count alone.
- **Commit:** `3cfe27d`

### 3. [Rule 2 - Missing correctness requirement] Six more arms, because the primary six cannot answer two of the plan's own questions

- **Found during:** Task 2, on the first v0.33.0 arm.
- **Issue:** the plan requires *"the v0.33.0 and v0.34.0 single-disc arms render a real per-disc
  track position"*, *"render a `Disc N/` path component without error"* and *"the v0.33.0 and
  v0.34.0 rendered paths … are byte-identical"*. All three are **unreachable**: with this repo's
  format those versions never render anything. Recording "cannot be assessed" would have left
  OD-5's question — is v0.34.0 a path-format no-op? — unanswered, which is the whole reason OD-5
  added the third tag.
- **Fix:** six ablation arms through the **same script and the same extraction code path**, with
  `WRTAG_YAML` pointed at a new committed file whose only difference from the frozen format is
  the disc component's position. This both answers the three criteria and doubles as the proof of
  cause. The ablation format's sha256 is recorded beside the real one in the evidence file, so no
  reader has to take on trust which string produced which path.
- **New artefact not in the plan's `files_modified`:** `03-wrtag-ablation-format.yaml`. It is in
  the phase directory, not under `stacks/`, and carries `THROWAWAY — DO NOT DEPLOY` on line 1 —
  the 03-04 convention.
- **Commit:** `621a5b5`

### 4. [Scope] Thirteen stdout files, not six

The plan's criterion is *"`ls /mnt/fast/spike-03/out/wrtag-*.stdout | wc -l` returns `6`"*. The
**six primary arms** are present and were counted explicitly by name. The other seven are the six
ablation arms and the one unpinned natural-match arm, all of which are evidence. The glob-based
criterion is superseded by the by-name count; recorded rather than worked around.

### 5. [Rule 1 - Bug, in the evidence rather than the code] The plan's own correction was incomplete

The plan instructs a leading blockquote stating that *"`.Release.Media` and `.Track.Position`
both exist in v0.20.0 — only `.Media` is absent"*. That is **correct and confirmed**, but it
stops one field short: `.Release.Date.Year` and `artistsString`, the other two the Renovate rule
names, are also innocent — **all four are**. And the plan's framing throughout is that v0.20.0 is
the broken one and the newer tags are fine, which the measurement falsifies. The blockquote as
written was expanded to three numbered corrections rather than one, and the third is the headline
the plan did not anticipate.

### 6. [Deferred to the orchestrator] Delivery to LXC 100 was out-of-band, and no branch was pushed

A worktree executor cannot push, and `/mnt/fast/stacks` sits at `c88c268`. Both artefacts were
staged to `/mnt/fast/spike-03/` — deliberately outside the git checkout, so a later
`git pull --ff-only` is not blocked by an untracked file the incoming commit also adds — and the
harness was **sha256-verified identical to the committed file** (`54f2263f…`) before the arms
were run. Task 1's acceptance criterion *"committed and pushed to `origin/main`"* is discharged
as **committed**; publication is the orchestrator's. Same deviation and same handling as plans
03-01, 03-03 and 03-04.

## Attribution: 12 files changed in the backlog during this run, none of them mine

`find /mnt/tank/downloads/complete/nzb/music -newermt "2026-09-03 21:05" -type f` returns 12, all
inside `Taylor Swift - The Life Of A Showgirl-WEB-2025-ALTAiR INT-xpost`, a folder that did not
exist when this plan started (it is absent from the `ls -1` taken at 21:1x, which is in this
plan's transcript).

| Fact | Value |
|---|---|
| Files inside either album this plan staged | **0** |
| sabnzbd's beets log | `import started Thu Sep 3 22:17:20 2026` → `skip … Taylor Swift - The Life Of A Showgirl-…` (container TZ = 21:17:20 UTC) |
| sabnzbd's mounts | `/mnt/tank/downloads:rw` |
| This plan's mounts on `complete/` | **none, at any mode** — the arms mount only `spike-03/wrtag-src:ro` |

The decisive argument is the mount table, not the clock. This is **DEF-03-01** in the open for
the second time in this phase: a live, unattended tagging path operating on the exact population
Phase 3 samples from, which `check-music-freeze.sh` structurally cannot see because `sabnzbd`
does not match `TAGGER_PATTERN`. Not fixed here, for the reason 03-04 gave — widening a shared
harness mid-wave changes the pass/fail behaviour of every other plan in it.

## Verification that could not be satisfied as written

**Two acceptance criteria are unreachable and are recorded as measurements rather than as
passes**, exactly as the plan's own exit-code convention requires (*"a wrtag template error is
not a script failure — it is the measurement"*):

- *"The v0.33.0 and v0.34.0 single-disc arms render a real per-disc track position and contain no
  `-1 - ` component"* and *"the v0.33.0 and v0.34.0 multi-disc arms render a `Disc N/` path
  component without error"* — **not reachable with the frozen format**, because those versions
  refuse it at startup. Both are satisfied under the ablation, and the refusal is the more
  important answer.

Everything else in the plan's `<verification>` block passed as written.

## Known Stubs

None. `/mnt/tank/downloads/spike-03/wrtag-src` now holds **1.2 G** of reflinked albums; plan
03-11 owns deleting the scratch tree and must include `wrtag-src`, which was empty when 03-03
created it. `/mnt/fast/spike-03/out` grew to 2.8 M (13 captures, 96 manifests) on LXC 100's ext4
**root** — the 03-03 finding-4 constraint, watched not assumed: `/` is unchanged at 35 G free.

## Threat Flags

No new security surface. Every disposition in the plan's register was exercised:

| Threat | Outcome |
|---|---|
| T-03-44 (`/mnt/tank/media` tampering) | Held — no `/mnt/tank/media` path mounted in any arm; comment-stripped `grep -c` on the harness returns 0; `check-music-freeze.sh` exit 0 |
| T-03-45 (a `move` consuming its source) | Held — `:ro` at the mount layer, and the source is a reflinked copy under `spike-03/wrtag-src`, not the backlog |
| T-03-46 (a dry run that is not dry) | Held — verified in source (`CanModifyDest()` gates both `tags.WriteTags` and cover fetching) **and** asserted per arm: 12 arms, 12 `find -newer` zeroes, 48 empty manifest diffs |
| T-03-47 (measuring a re-typed path format) | Held — extracted at run time, sha256 recorded and re-verified against a fresh extraction; comment-stripped grep proves no embedded format string |
| T-03-48 (repeating the wrong pin-inversion evidence) | Held — runtime and source recorded together and required to agree; the correction is stated **as a correction**, in a dated amendment that leaves the superseded wording visible |
| T-03-49 (frozen stack definitions and the Renovate pin) | Held — this plan's diff touches `scripts/` and `.planning/phases/03-tagger-spike/` only |
| T-03-50 (third-party container privilege) | Held — `--rm`, `--security-opt no-new-privileges:true`, no published port, no Traefik label, no added capabilities, destination on scratch, zero containers left behind |
| T-03-SC (package installs) | Held — **zero** installs. All three `sentriz/wrtag` tags were already local from plan 03-01 |

One threat-adjacent note that is not a flag: the arms **do** reach the internet, on docker's
default bridge, because wrtag's only metadata source is MusicBrainz and `--network none` would
have made the measurement impossible. This is stated in the harness header rather than left
implicit, and the outbound traffic is MusicBrainz WS/2 only — visible in every captured stderr.

## Self-Check: PASSED

- `scripts/spike03-wrtag-arms.sh` — FOUND
- `.planning/phases/03-tagger-spike/03-WRTAG-EVIDENCE.md` — FOUND
- `.planning/phases/03-tagger-spike/03-wrtag-ablation-format.yaml` — FOUND
- `.planning/phases/03-tagger-spike/03-DECISION.md` — FOUND (modified; only `PENDING` result
  cells replaced, plus one dated amendment section; `git diff` removes **4** lines, none of them
  threshold, estimator or denominator text)
- Commit `c46ddea` (`feat(03-08)`) — FOUND
- Commit `3cfe27d` (`fix(03-08)`) — FOUND
- Commit `621a5b5` (`docs(03-08)`) — FOUND
- Committed harness sha256 == the sha256 of the file every arm actually ran (`54f2263f…`) —
  VERIFIED
