---
phase: 01-safety-harness-and-freeze-the-writers
plan: 09
subsystem: durable-record
status: COMPLETE — WRIT-04 closed, WRIT-01 asserted, phase closed on a criterion-by-criterion verdict
tags: [WRIT-04, WRIT-01, D-14, D-29, D-30, documentation, health-check, phase-closure]
requires:
  - scripts/check-music-freeze.sh (01-01)
  - the post-apply mount audit (01-05, completed by 01-06)
  - the fence and its snapshots (01-02)
  - the QUAL-01 capture (01-03 tooling, 01-04 run)
  - ownership normalised to 568:568 on disk (01-08)
provides:
  - "stacks/selfhosted/arrs/beets.md — the Phase 1 durable record (D-30) and the corrected chown (D-14)"
  - "scripts/quick-health-check.sh — harness folded in, first non-zero exit path (D-29)"
  - "scripts/check-music-freeze.sh — mode assertion scoped to a report, ownership still asserted"
  - ".planning/PROJECT.md + CLAUDE.md — ownership constraint resolved, three Key Decisions rows"
  - "VERIFIED: the whole-estate ownership census, five subtrees, 535,298 entries"
  - "RECORDED NOT ACTIONED: /mnt/tank/media/TV, 114,218 entries on gid 545, with the working method"
affects:
  - "Phase 2 (anonuid/anongid = 568:568 is now recorded in the repo; the 0777 tree forces a ro export)"
  - "Phase 4 (beets.md records that both beets definitions are :ro and wrtag's library mount is gone)"
  - "Phase 6 (the tagger is granted rw here; beets.md says so explicitly)"
  - "every later session (CLAUDE.md's ownership and Jellyfin constraints were both stale and are corrected)"
tech-stack:
  added: []
  patterns:
    - ".md-beside-the-stack (arrs/beets.md, media/dispatcharr.md) extended rather than a new document"
    - "quick-health-check.sh flat top-level block shape, one ssh per block"
    - "check-server-health.sh:8-11 unreachable-host precedent — UNKNOWN, never green"
key-files:
  created:
    - .planning/phases/01-safety-harness-and-freeze-the-writers/01-09-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets.md
    - scripts/quick-health-check.sh
    - scripts/check-music-freeze.sh
    - .planning/PROJECT.md
    - CLAUDE.md
decisions:
  - "the D-14 justification written into beets.md is the ORPHAN GID, verified live — not either of the two superseded reasons, both of which were committed to the repo before being caught"
  - "the mode assertion is scoped inside check-music-freeze.sh, not filtered inside the quick-health-check block, so the scoping is visible where the assertion lives"
  - "the current live audit is quoted in beets.md rather than 01-05's verbatim output — 01-05's shows lidarr failing, which was the pre-01-06 state and would misrepresent the record"
  - "quick-health-check.sh treats an unreachable host as exit 1 UNKNOWN, not a pass"
  - "TV is recorded as a backlog finding with the working method and deliberately not normalised"
metrics:
  duration: ~55 minutes
  completed: 2026-08-18
  tasks: 4
  commits: 5
  files_modified: 5
  final_audit_exit: 0
---

# Phase 01 Plan 09: The Durable Record and Phase Closure Summary

`beets.md` no longer instructs a `chown` to an orphan gid, and now carries the Phase 1 record —
ownership, the one-writer state, the Jellyfin carve-out, the fence, the traps and how to re-run.
The harness runs on every `quick-health-check.sh`, which can now fail. **The final assert-mode
audit exits 0.** Five of the six roadmap criteria are met as written; **criterion 5 is met on its
own wording and short on a target it does not name**, and that shortfall is stated rather than
rounded up.

## What Was Built

| Task | Output | Commit |
|------|--------|--------|
| 1 | `beets.md`: chown corrected + dated Phase 1 record, two stale facts fixed | `474f10f` |
| 1b | `beets.md`: the verified whole-estate ownership census | `cba8c9d` |
| 2 | `quick-health-check.sh` harness block + first `exit 1`; `check-music-freeze.sh` mode assertion scoped | `7e2e923` |
| 3 | `PROJECT.md` + `CLAUDE.md` ownership and Jellyfin constraints resolved; three Key Decisions rows | `f5eba52` |
| 4 | Phase closure verdict (this document) | this commit |

## The `beets.md` diff

**The corrected instruction** (`Gotchas found the hard way`):

```
- rsync -rlt --no-p --no-o --no-g, then `chown -R 568:545` to match the Music library convention.
+ rsync -rlt --no-p --no-o --no-g, then `chown -R 568:568` — and run that on the Proxmox host,
+ not on LXC 100.
```

**The justification written beneath it — the third one, and the first that survives checking:**

> This line used to instruct gid 545 (`568:545`); it was corrected on 2026-08-18. That value was
> not invented — **545 was the real on-disk gid on 1,171 entries here**, and Music was not alone
> on it (`/mnt/tank/media/TV` carries 114,218 entries on the same gid). It was corrected because
> **545 is an orphan gid**: `getent group 545` returns nothing on atlantis, and 545 is unmapped in
> LXC 100's idmap — which is exactly why the container ever reported `nogroup`/`65534`, and why
> `chown` fails `EPERM` from inside it. `568` is `apps` (`getent group 568` → `apps:x:568:`),
> stated independently in `STANDARDS.md:141`, `DEPLOYMENT.md:31`, `README.md:29` and `CLAUDE.md`.
> If you ran the old line, you set a gid that resolves to no group; re-run the new one from
> atlantis.

Every clause of that was verified with a command before it was written:

| Claim | Command | Result |
|---|---|---|
| 545 is an orphan gid | `ssh root@172.16.1.158 getent group 545` | no entry |
| 568 is `apps` | `ssh root@172.16.1.158 getent group 568` | `apps:x:568:` |
| 545 unmapped in LXC 100 | `grep idmap /etc/pve/lxc/100.conf` | targets are 100000+, 44, 110, 568 — 545 is in none |
| TV shares gid 545 | `find /mnt/tank/media/TV -printf '%U:%G\n' \| sort \| uniq -c` | 64,546 `0:545` + 49,672 `568:545` = **114,218** |
| 568 is the estate majority | same, all five subtrees | 408,391 of 535,298 media entries = **76%** |
| `STANDARDS.md:141` etc. | `grep -n 568 STANDARDS.md DEPLOYMENT.md README.md` | all three present |

**The two superseded justifications are named as history, not restated as fact.** D-14's original
("a Windows/SMB-era convention with no basis on this host, matching no folder") was false — it read
the 01-01 census through LXC 100's idmap. 01-08's first correction ("Music was the only media
subtree on gid 545") was also false — it came from a census that had not finished. Both were
committed before being caught. That is why the document now says which view every `uid:gid` came
from.

**The new dated section** — `## Phase 1 safety harness (2026-08-18)` — carries:

- **Ownership and modes**, with the mode half stated plainly as *recorded but not achieved* rather
  than as a clean claim: `0777` everywhere, `chmod` EPERM even as real root, and why the only fix
  is a dataset-property change bigger than the problem.
- **The one-writer state**, sections 1 and 2 of the audit quoted verbatim from a run I made myself
  at `2026-08-18T22:27:09Z`, with an explanation of why the two sections are different questions.
- **The Jellyfin exception**, named as consumer-class, application-layer-frozen, excluded from the
  tagger count, deliberately not `:ro` (subtitle/trickplay risk), and **permanent** — plus the
  measured limit that `SaveLocalMetadata: false` does not stop a `FullRefresh`.
- **The recovery fence**, both `@pre-project` snapshots and what each undoes, the off-box copies,
  and why neither half substitutes for the other (beets has no `undo`; a rollback alone leaves
  `incremental` state claiming the work is done).
- **Two traps**: the normalisation cannot be re-run from LXC 100 (same errno as the ACL problem,
  different cause), and every `uid:gid` must say which view it came from — with the collapse table
  and the ground-truth command.
- **The six-times pattern**: every false pass this phase produced, named, and the rule that follows
  from it — verify with a second independent instrument before writing it down.
- **How to re-run**, one line per script and subcommand.
- **Recorded not actioned**: TV, with the working method.

**Two stale facts corrected in the existing text while I was in there** (Rule 1 — a durable document
stating something now false is the exact hazard this plan exists to remove):
`SaveLocalMetadata: true` is no longer true for Music, and `dj-mixes` is **764** audio files, not
794 (the old figure counted the 30 JPEG scans as tracks and missed the 24 BMP scans).

## Was the mode assertion scoped, and how

**Yes.** Before this plan, `bash scripts/check-music-freeze.sh` exited **1** with exactly two
failures, forever:

```
❌ directory mode: 88 directories differ from 755
❌ file mode: 2586 files differ from 644
```

Folding that into a routine health check trains the reader to ignore it — the exact failure D-29
exists to prevent. **The scoping was done inside `check-music-freeze.sh`, not by filtering in the
`quick-health-check.sh` block**, so it is visible where the assertion lives:

- section 4's two `fail()` calls became `warn()`, with the text `REPORTED not asserted (D-12 scoped
  out, chmod impossible on tank)`;
- the summary block's two lines say the same;
- the section index and a new `MODE SCOPE` header block record the cause (`aclmode=restricted` +
  `aclinherit=passthrough` → non-trivial NFSv4 ACL even on new files, EPERM as real root), the
  reason for reporting rather than asserting, and the one-line instruction to restore the two
  `fail()` calls if the constraint is ever lifted.

**The counts are still printed**, so a *regression* is still visible; what is removed is only the
claim that they must be 755/644. **Ownership stays a hard assertion.**

After scoping, the same command exits **0**.

## The `quick-health-check.sh` exit-code behaviour change

The script previously **always exited 0** — it printed ❌ for a down Traefik with no other
consequence. It now has three outcomes on the harness block:

| Condition | Output | Exit |
|---|---|---|
| harness intact | `✅ Intact` + the four key summary counts | **0** |
| harness broken | `❌ BROKEN (exit N)`, the failed assertions, then the whole summary block | **1** |
| host unreachable / no output | `⚠️  UNKNOWN — 172.16.1.159 unreachable`, "NOT green", plus the manual re-run command | **1** |

All three were exercised, not assumed: green against the live host (exit 0); unreachable by
repointing a copy at `172.16.1.254` (exit 1); broken by substituting a stub that emits a red and a
summary and exits 1 (exit 1, with the red surfaced).

The behaviour change is stated in the file's header comment with its reason — other things may call
this script, and a silent-to-failing change should be visible in the file, not only in a plan. The
Traefik/Authelia blocks were deliberately **not** made fatal: the harness is the only block here
with a maintained assertion contract.

**One bug fixed while writing it (Rule 1):** the first draft captured `MUSIC_RC=$?` after piping ssh
through `sed`, which reads *sed's* exit status — the harness could have failed and the block would
have reported green. The strip is now a separate step after the capture. The ANSI strip also uses
bash `$'\033'` rather than `\x1b`, which is a GNU sed extension and this script runs on macOS.

## The three Key Decisions rows

| Decision | Outcome recorded |
|---|---|
| Library ownership normalised to `568:568`; modes stay `0777` | Done 2026-08-18 (01-08 ownership, 01-09 record). Mode half scoped out; export must stay `ro` |
| Jellyfin's Music metadata freeze is permanent | Done 2026-08-18 (01-06) |
| Jellyfin retained as the documented sole `rw` holder, not made `:ro` | Done 2026-08-18 (01-05/01-06). Revisit once the tagger owns the tree |

The ownership row's rationale states the **orphan-gid** reason, not the plan's own text (which still
carried the superseded "no basis on this host and matched no folder" wording — see Deviation 1). The
`0755`/`0644` target is recorded in the same row as **not achieved**, so the Key Decisions table
cannot be read as claiming a mode normalisation that did not happen.

## Where TV was recorded

`stacks/selfhosted/arrs/beets.md`, in the Phase 1 section under
**"Recorded, not actioned: `/mnt/tank/media/TV`"** — beside the stack, where someone fixing
ownership will be reading, rather than in a planning document they will not open. It carries the
verified five-subtree census table, the finding that Music and TV were on gid 545 *together*, the
explicit statement that this is deliberately left alone (no requirement covers TV; scope growth
followed by abandonment is this project's documented failure mode), and the working method:

```bash
# On the Proxmox host — NOT on LXC 100, where this fails EPERM on every entry
ssh root@172.16.1.158
zfs snapshot tank/media/TV@pre-chown
chown -R 568:568 /mnt/tank/media/TV
```

The uid-3000 finding (197,776 of `tank/downloads`' 209,039 entries, and the library's `.DS_Store`)
is recorded in the same place for the same reason.

## Phase closure: the six roadmap criteria, one at a time

Final audit: `bash scripts/check-music-freeze.sh` on LXC 100 at repo `7e2e923`, from a clean shell,
default asserting mode — **`FAILURES total: 0`, exit `0`, `✅ Music freeze harness intact`.**

### Criterion 1 — exactly one running container with a rw path to the library — **MET**

Live audit section 1: `tagger-class writers: 0`, `unclassified writers: 0`,
`consumer-class writers: 1 (jellyfin)` across 102 running containers and 164 enumerated mounts.
Section 2 (the declared-YAML false-pass guard): `declared rw reaching Music: 0`, zero `NO-SUFFIX`
rows estate-wide.

**wrtag's library mount is deleted, not just its restart policy changed** — `wrtag.yaml` contains no
`/mnt/tank/media` volume line at all; the only surviving `/music/library` string is inside
`WRTAG_PATH_FORMAT`, an environment variable, which mounts nothing.

Delivered by **01-05** (nine mounts narrowed or deleted; Prowlarr's removed outright) and **01-06**
(lidarr flipped `:ro`). Asserted here.

### Criterion 2 — Lidarr off the library tree — **MET, with the lever named correctly**

From `lidarr-api-after.json`, read back from Lidarr's **API** after a container recreate, never the
UI: root folder is `/downloads/lidarr-import` (id 2, the only one), `renameTracks: false`, all three
metadata consumers `enable: false`, plus `deleteEmptyFolders` and `embedCoverArt` closed under D-24's
intent.

**The nuance the criterion's wording hides:** deleting the old root folder did **not** repoint the 22
existing artists — an \*arr stores an absolute path per artist, and all 22 still target
`/media/Music/<Artist>`. **The `:ro` mount (D-25) is what actually closes the library**, not the
root-folder move (D-23). The criterion is met; anyone who reverts the `:ro` mount believing the root
folder is the control will reopen it.

Delivered by **01-06**.

### Criterion 3 — destructive defaults off everywhere, and Jellyfin writing nothing — **MET as two halves, the second with a named limit**

*Beets half (SAFE-01):* `scrub.auto: no`, `lastgenre.auto: no`, `embedart.auto: no` present in
**every** beets config in the estate — six files across four locations, not the three the phase
assumed. The two extra ones were the two most dangerous, including
`/mnt/fast/appdata/arrs/beets/config/config.yaml`, which is a docker-compose file saved into
`BEETSDIR`, meaning beets had been running on pure defaults. All three keys default to **yes** in
beets 2.13.1, measured with `beet config -d` — "key absent" was never "off". Verified by
container-side read-back, which is the only check that proves what the process sees. Delivered by
**01-07**.

*Jellyfin half (SAFE-05):* Music library `SaveLocalMetadata: false`, `EnableRealtimeMonitor: false`,
`SaveLyricsWithMedia: false` — the third switch is named in no plan and had written 944 of the 1,123
baseline sidecars. Database backed up (three Jellyfin DBs in the fence with integrity checks). The
watch **PASSED** over 374 minutes. Delivered by **01-06**.

**The limit, stated because rounding it up would be the failure this phase is about:**
`SaveLocalMetadata: false` gates the *automatic* save path only. An explicit `FullRefresh` — the
UI's "Refresh metadata" button — **still writes**, and rewrote 83 of the library's 91 `.nfo` in
place, 66 with changed content. "Jellyfin writes nothing into Music" is true **unprompted** and
false as an absolute. Both this and the fact that the original path-set watch returned a perfect
pass *while* those 83 files were being rewritten are now recorded in `beets.md`.

### Criterion 4 — the recovery fence exists and is readable — **MET, with a figure corrected**

Verified live: `library-db/` 18 files (each `.backup`-copied and `PRAGMA integrity_check`ed),
`dj-mixes-ffprobe/` **764** JSON with `TKEY` present in 148 and `EnergyLevel` in 45,
`cover-scans/` 54 files (**30 jpg + 24 bmp** — a jpg/png-only extension list archives 30 of 54),
`tags/` the QUAL-01 capture, `audit/` 27 evidence files. Both snapshots present
(`tank/media/Music@pre-project`, `tank/downloads@pre-project`), plus `@pre-chown` on both datasets
and `@safe05-watch-t0`. **No running container mounts any path under `/mnt/fast/safety`** — proven
from the same mount enumeration WRIT-01 uses, not asserted. Off-box on the Mac Mini: 70 files
(54 scans + 15 databases + MANIFEST).

**The criterion's own wording says "all 794 `dj-mixes` files". The real figure is 764** — 630 `.mp3`
+ 134 `.wav`. 794 was `764 audio + 30 jpg`: it counted the JPEG scans as tracks and missed the BMPs.
The fence covers **every audio file**, which is what the criterion means. `beets.md` and this
document now carry 764; the roadmap's 794 should be retired.

Delivered by **01-02**.

### Criterion 5 — one decided `uid:gid`, recorded in the repo — **MET on its own wording; the mode target it does not name is NOT met**

*Both halves of what the criterion actually asks:*
- `stat` returns one value: **2,674 of 2,674 entries at `568:568`**, library root included, verified
  from the Proxmox host and cross-checked with `zfs diff` against `@pre-chown`. Distinct `uid:gid`
  present under the library: exactly one row, `2674 568:568`. (**01-08**)
- Recorded in the repo: `beets.md`'s Phase 1 section, `PROJECT.md`'s corrected constraint and Key
  Decisions row, and `CLAUDE.md`'s mirrored constraint. (**this plan**)

*What is not met and is not rounded up:* **modes are `0777` — 88 directories and 2,586 files — and
will stay that way.** D-12's `0755`/`0644` target was scoped out by user decision after `chmod` was
re-verified failing `EPERM` on `tank` as real root on the hypervisor against a brand-new scratch
file. This does not fail criterion 5, which names the `uid:gid` only — but it is load-bearing for
**Phase 2**: ZFS `acltype=nfsv4` ACLs are not exported by knfsd, so mode bits are the only lever NFS
clients see, and a world-writable tree means **the export must be read-only**. Recorded in
`beets.md`, `PROJECT.md`, `CLAUDE.md` and the audit script's header.

Two further corrections this criterion surfaced, both now in the repo: the "12 of 13 folders at
`568:65534`" it quotes was the **container's** view, and the artist-folder count it frames the
question around (13) is a fraction of the 2,674 entries that actually needed normalising.

### Criterion 6 — a re-runnable before-state snapshot with a self-diff at zero — **MET**

`tags/pre-project.ndjson.gz`: **9,736 records** over 182.67 GB in 31m17s, `pre-project.done` 9,736
lines, `pre-project.failed` **0 bytes** — every visited file in exactly one ledger. Keyed on
`audio_md5`, the encoded bitstream, so a rename cannot break the join. The recorded self-diff
(`audit/self-diff-20260818T134638Z.txt`) ends `✅ No net metadata loss (exit 0)` across 8,672 matched
join keys with all five difference categories at zero — and it warns that 55 matched files had an
empty BEFORE tag set, so a vacuous pass cannot be misread as a real one. Paired with **01-03**'s
mutated-copy negative control, which returns exit 1 with exactly the right rows: the mechanism is
proven to detect a difference before it is trusted to prove there is none.

Delivered by **01-03** (tooling) and **01-04** (the capture).

### Verdict

**Six of six met as the roadmap words them.** One target that the roadmap does *not* word into a
criterion — D-12's `0755`/`0644` — is **not met, scoped out, and named** in four places rather than
absorbed. Two criteria carry figures that were wrong when written (794 `dj-mixes` files; the 12-of-13
`568:65534` census) and are corrected in the repo.

## Requirement-to-plan mapping — all ten

| Requirement | Delivered by | State |
|---|---|---|
| SAFE-01 destructive beets defaults off in *every* config | **01-07** | Met — six configs across four locations, verified by container-side read-back |
| SAFE-02 recoverable snapshot before any import | **01-02** | Met — `tank/media/Music@pre-project` + `tank/downloads@pre-project` + 18 database copies, same step |
| SAFE-03 DJ tag evidence captured where no tagger can overwrite it | **01-02** | Met — 764 full `ffprobe` JSON, `TKEY` 148 / `EnergyLevel` 45. **01-04** found 158 further `TKEY`-bearing files *outside* `dj-mixes` that this dump does not cover |
| SAFE-04 54 cover scans archived outside any tagger-writable path | **01-02** | Met — 30 jpg + 24 bmp, sha256-verified, also off-box |
| SAFE-05 Jellyfin stops writing into the library | **01-06** | Met — three switches off, 374-minute content-hashed watch PASSED. Limit: an explicit `FullRefresh` still writes |
| WRIT-01 exactly one rw path, verified from *running* containers | **01-05** + **01-06**, asserted **01-09** | Met — tagger 0, unclassified 0, consumer 1 (documented), declared rw 0 |
| WRIT-02 wrtag stopped, library mount removed from the definition | **01-05** | Met — the mount deleted, not suffixed; plus `restart: "no"` and a `profiles` gate |
| WRIT-03 Lidarr no longer renames or organises in the library | **01-06** | Met — API-verified; the `:ro` mount is the load-bearing control, not the root-folder move |
| WRIT-04 ownership normalised to one decided `uid:gid`, recorded in the repo | **01-08** (disk) + **01-09** (repo) | Met — 2,674/2,674 at `568:568`, recorded in `beets.md`/`PROJECT.md`/`CLAUDE.md`. Mode half scoped out |
| QUAL-01 re-runnable before-state tag snapshot with a zero self-diff | **01-03** (tooling) + **01-04** (capture) | Met — 9,736 records, self-diff exit 0, negative control exit 1 |

None unmapped.

**Nine SUMMARY files exist**, one per plan (`01-01` … `01-09`).

## Deviations from Plan

### 1. [Rule 1 - Bug] The plan's own Task 3 text carried the superseded justification

- **Found during:** Task 3
- **Issue:** Task 3's action still instructed the Key Decisions rationale to read
  "`568:545` had no basis on this host and matched no folder" — the **first** wrong justification,
  the one 01-08 disproved. The plan's Task 1 and `must_haves` were corrected; Task 3 was not.
- **Fix:** the Key Decisions row states the verified orphan-gid reason instead. Writing the plan's
  text would have re-committed a claim already proven false twice.
- **Files:** `.planning/PROJECT.md`
- **Commit:** `f5eba52`

### 2. [Rule 1 - Bug] `MUSIC_RC=$?` read sed's exit status, not the harness's

- **Found during:** Task 2, before the first run
- **Issue:** the block captured ssh's output through a `sed` colour-strip in the same pipeline, so
  `$?` was `sed`'s status — always 0. The harness could have failed and the block would have
  reported ✅.
- **Fix:** capture first, strip second. Also replaced `\x1b` (a GNU sed extension) with bash
  `$'\033'`, since this script runs on macOS.
- **Verified:** all three branches exercised — green 0, broken 1, unreachable 1.
- **Commit:** `7e2e923`

### 3. [Rule 2 - Missing critical] `beets.md` still stated `SaveLocalMetadata: true` twice

- **Found during:** Task 1
- **Issue:** two passages told the reader Jellyfin writes sidecars into `/media/Music` within
  minutes. That has been false since 01-06 for the Music library. A durable document stating a
  now-false fact is precisely the hazard this plan exists to remove, and the `chown` line was only
  the loudest instance.
- **Fix:** both corrected to the current state, keeping the staging warning (it still holds, because
  an explicit refresh still writes) and keeping the hazard for Movies and TV, which are unchanged.
- **Commit:** `474f10f`

### 4. [Rule 2 - Missing critical] `beets.md` and both constraint files carried the retired 794 figure

- **Found during:** Task 1
- **Issue:** `beets.md`'s census table said 794 `dj-mixes` files. 01-02 established the real figure
  is 764 audio; 794 counted the 30 JPEG scans as tracks and missed the 24 BMPs.
- **Fix:** corrected to 764 with the arithmetic shown so the correction is checkable.
- **Commit:** `474f10f`

### 5. [Plan text vs. verified fact] The current audit is quoted, not 01-05's verbatim output

- **Where:** Task 1's action, which says to quote 01-05's SUMMARY verbatim.
- **Reality:** 01-05's output shows `tagger-class writers: 1` and `❌ 1 declared rw/unsuffixed host
  paths` — that is the **pre-01-06** state. Pasting it into a durable record as "the one-writer
  state" would misrepresent the estate exactly as the record was meant to prevent.
- **Chosen:** quoted a run I made myself at `2026-08-18T22:27:09Z`, same script, same two sections,
  ANSI stripped and otherwise unedited, with 01-05 and 01-06 both credited for how it got there.

### 6. [Scope] The plan's automated check for Task 1 does not fit the record it asked for

- **Where:** `test "$(grep -c '568:545' stacks/selfhosted/arrs/beets.md)" -le 1`
- **Reality:** the file now names `568:545` three times — in the correction note, in the idmap
  collapse table, and in the TV census — all explanatory, none an instruction. The stricter,
  meaningful criterion is met: `grep -c 'chown -R 568:545'` returns **0**. The `-le 1` threshold was
  written for a minimal edit; the record the same task asked for necessarily cites the historic gid.

### 7. [Rule 2 - Missing critical] `CLAUDE.md`'s Jellyfin constraint was stale too

- **Found during:** Task 3
- **Issue:** the plan named only the ownership paragraph. The Jellyfin paragraph beneath it also
  asserted `SaveLocalMetadata: true`, in the file auto-loaded into every session.
- **Fix:** corrected in both files in the same commit, with the measured `FullRefresh` caveat rather
  than a clean claim.
- **Commit:** `f5eba52`

## Findings

1. **The whole-estate census, measured rather than inherited.** 535,298 entries across five media
   subtrees. `568` on **408,391 (76%)**. TV's 114,218 on gid 545 matches 01-08's figure exactly
   (64,546 `0:545` + 49,672 `568:545`) — re-measured here rather than quoted, because the last two
   things quoted from a census in this phase were both wrong.
2. **Music and TV are now divergent**, by decision. Recorded with the working method; not actioned.
3. **The pattern reached six and is now written where it will be read.** Every false pass this phase
   produced came from the same root: partial data stated as settled. It is in `beets.md`, not only
   in the SUMMARY files.
4. **`quick-health-check.sh` can now fail.** That is the first assertion contract on the estate's
   routine health path.

## For the Next Person

- **Phase 2** inherits `anonuid=568,anongid=568` — now recorded in the repo, which is what
  criterion 5's second half was for. **The export must be read-only:** the tree is `0777` and mode
  bits are the only lever NFS clients see.
- **Phase 4** should know that both beets definitions and Lidarr are `:ro` and wrtag's library mount
  is gone, so retirement starts from a known-safe state. The `plugins:` lines are deliberately
  untouched — TAGR-05 owns them, and `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml`
  declaring only `embedart` is the confirmed cause of the 1 and 8 Aug ingest skips.
- **Phase 6** grants the surviving tagger `rw` again. `beets.md` says so explicitly, so nobody has
  to guess whether the `:ro` mounts are permanent.
- **Anyone touching ownership anywhere on `tank`:** run it from `172.16.1.158`, never LXC 100, and
  check `getent group` before adopting a gid you found on disk.

## Self-Check: PASSED

| Claim | Check | Result |
|---|---|---|
| `01-09-SUMMARY.md` exists | `test -f` | FOUND |
| `beets.md` no longer instructs the bad chown | `grep -c 'chown -R 568:545'` | **0** |
| `beets.md` instructs the right one | `grep -c 'chown -R 568:568'` | 2 |
| `beets.md` carries the audit + fence | `grep -c 'tagger-class'` / `'music-pre-project'` | 3 / 2 |
| `quick-health-check.sh` parses | `bash -n` | exit 0 |
| `quick-health-check.sh` can fail | `grep -c 'exit 1'` | 1 |
| neither doc says ownership is undecided | `grep -c 'Ownership is undecided'` | 0 / 0 |
| both name `568:568` | `grep -c '568:568'` | 3 / 4 |
| final audit | `check-music-freeze.sh` on LXC 100 | **exit 0**, `FAILURES total: 0` |
| commits exist | `git log` | `474f10f`, `7e2e923`, `f5eba52`, `cba8c9d` all present |
| nine SUMMARY files | `ls 01-0*-SUMMARY.md \| wc -l` | 9 |
