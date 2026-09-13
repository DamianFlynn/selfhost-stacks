# Phase 4 — D-12 Evidence Checklist (success criterion 3, TAGR-04)

**Written:** 2026-09-11 by plan 04-01 (Task 3), **before** the stripped `audio.bash` is live and before
any post-strip music job exists or has been read.
**Filled by:** plan 04-12. Sections 1–5 are the contract. They are not edited after the job. Section 6
is the only section 04-12 writes.
**Sources:** D-12, D-31 (confirms D-10's one-line strip), `04-RESEARCH.md` F7 / F8 / Pitfalls 2–3 /
§ `audio.bash` anatomy, `04-REVIEWS.md` Consensus row 11, `04-VALIDATION.md` row C3-c. Every line
number below was re-read from the live `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/audio.bash`
(339 lines, sha256 `fdcddca234b282e4cb396764fa125fcacdbce350c21a94dd3f4ac024f87077ca`) on 2026-09-11.

A checklist written after the evidence has been read can be fitted to it. This one is written first
so that the residual log lines and the baseline `Exit(1)` cannot be read as a regression, and so that
"untagged" has a byte-level test fixed in advance, with an honest OPEN path.

---

## 1. Pass condition, stated before the job

Criterion 3 **PASSES** only on one real `music` SABnzbd job that completes **after** the stripped
`audio.bash` is live (plan 04-11), such that **ALL** of the following hold.

1. **The SAB row has the baseline shape.** The history status is `Completed` and `script_line` begins
   `Exit(1): chmod: changing permissions of '/downloads/complete/nzb/music/`.
   This is the F8 baseline, not a regression. `audio.bash:334` runs `chmod 777 "$1"`, which fails
   EPERM on `tank` (`acltype=nfsv4` + `aclmode=restricted`). Under the global `set -e` at lines 64–65
   that ends the hook with exit 1. The shape has been present on every music job since at least
   2026-08-01 (section 4). Per D-31 it is **not fixed in this phase**.
2. **No beets database or log activity.** Under `/mnt/fast/appdata/arrs/sabnzbd/config/scripts` there
   is no `library.blb`, no `library.blb*` backup (`library.blb-before-*.bak`) and no `beets.log`
   newer than the stamp.
3. **No `.bak` created** anywhere under sabnzbd `/config`, i.e.
   `find /mnt/fast/appdata/arrs/sabnzbd/config -name '*.bak' -newer <stamp>` prints nothing.
   - *Pre-declared exception, measured 2026-09-11:* `/mnt/fast/appdata/arrs/sabnzbd/config/sabnzbd.ini.bak`
     (9,837 B, mtime 2026-08-17 09:26 UTC) is written by SABnzbd itself when its settings are saved.
     It is not a beets artefact. If a newer one appears in the window, it is recorded by name and
     attributed to a SABnzbd settings save, and it does not fail this item. Any **other** new `.bak`
     fails it.
   - Baseline count on 2026-09-11 was 23 `.bak` under `/config`: 11 `scripts/library.blb-before-*`,
     11 `.config/beets/library.db-before-*` and `sabnzbd.ini.bak`. Plan 04-11 deletes the 22 beets
     ones.
4. **Untagged, proven by bytes, not inferred.** Every audio file present in both the job's PRE-HOOK
   snapshot and its COMPLETION snapshot is **byte-identical** by sha256.
   - **PRE-HOOK snapshot:** the first stable snapshot (two consecutive passes with identical per-file
     size and mtime) that plan 04-12's read-only watcher takes of the job folder. It is valid **only
     if** it precedes the job's `Matching N tracks with Beets` line in `Audio.txt`, which marks the
     stage where the stripped invocation used to run.
   - **COMPLETION snapshot:** taken at the first watcher poll after the job's SAB history row appears.
   - `MUSICBRAINZ_*` tags present in a byte-identical file came with the release, and are recorded as
     such.
   - Files present in PRE-HOOK but absent at COMPLETION are recorded and are **not** a failure.
     `clean()` (lines 133–158, called first in `Main` at line 308) deletes non-audio files, and
     deletes MP3s when FLAC is present.
   - Any file whose bytes changed, or any audio file that appears only at COMPLETION, is a **FAIL**.
   - *Pre-declared clarification, added by the 04-01 executor (recorded as a deviation in
     `04-01-SUMMARY.md`):* `clean()` also flattens subdirectories. A COMPLETION-only path whose
     sha256 equals the sha256 of a PRE-HOOK-only path is a **move** by `clean()`, not a new file. It
     is recorded as `MOVED <old> -> <new>` and counts as byte-identical. A COMPLETION-only audio file
     whose sha256 matches **no** PRE-HOOK file is still a FAIL. This only arises when the PRE-HOOK
     snapshot precedes `clean()`.
   - File mtimes are NOT used as tag provenance.

   > **Amended 2026-09-13 by plan 04-14 (gap closure, criterion 3 / TAGR-04).**
   >
   > **The clause being amended.** The PRE-HOOK snapshot above is defined as "the first stable
   > snapshot (two consecutive passes with identical per-file size and mtime) that plan 04-12's
   > read-only watcher takes of the job folder", valid only if it precedes the job's
   > `Matching N tracks with Beets` line in `Audio.txt`. Every word of that stands above; nothing
   > here edits or deletes it.
   >
   > **Why it is unsatisfiable, on the measurements already recorded in section 6.** SABnzbd moves a
   > finished job into `complete/nzb/music/` and only **then** invokes the hook, so the earliest
   > sighting a destination-tree watcher can have is already after the hook has started — job A's
   > first sighting was 12:18:00.074Z against a `Matching` line at 12:17:59Z. The first-stable rule
   > adds a 2–4 s floor on top of that, against a hook that ran start-to-finish in 1 second. And
   > `Audio.txt` resolves only to the second, which left job B's ordering indeterminate even at a
   > millisecond watcher clock. The defect is in the instrument, not the estate.
   >
   > **The replacement, in three load-bearing parts.**
   >
   > - **Where.** The PRE-HOOK snapshot is now the **last** stable snapshot (`STABLE_PASSES`
   >   consecutive passes with an identical whole-folder inventory) taken while the job folder still
   >   exists under `/mnt/tank/downloads/incomplete`, attributed to its completion folder through the
   >   SAB history row's `path` and `storage` columns.
   > - **When it is published.** Only if the folder's full recursive inventory is identical
   >   immediately before and immediately after the hash pass, **and** the folder still exists at the
   >   incomplete path when hashing finishes. `vanished.time` records when a later poll *observed*
   >   absence, not when the move occurred, and an already-open file descriptor survives a rename —
   >   so two timestamps alone cannot establish that the hash pass did not straddle the move.
   > - **When it is still valid at judgement time.** Only if `pre.time` is earlier than the recorded
   >   `vanished.time` **and** the inventory it was taken from (`pre.inv`) is identical to the last
   >   inventory observed before the folder vanished (`last.inv`). If the folder changed in between,
   >   the snapshot may be a proper subset of the final post-unpack set and the job is **UNPROVEN**,
   >   never FAIL.
   >
   > **The substance is kept, not reduced — it is strengthened.** The ordering becomes *structural*
   > rather than a timestamp comparison: SABnzbd cannot invoke the hook until it has performed the
   > move, and the move is what removes the folder from the incomplete tree. No comparison against a
   > second-resolution log is required for validity at all. The assumption this rests on is named
   > rather than hidden — **SABnzbd's move preserves bytes**, the hook being the only thing in the
   > pipeline that would rewrite them — and the byte comparison is precisely what tests it.
   >
   > **The COMPLETION-only FAIL clause is narrowed, because this is where a false-FAIL path was left
   > open.** The clause above makes "an audio file appearing only at COMPLETION whose sha256 matches
   > no PRE-HOOK file" a FAIL, and the 04-01 clarification scoped that to `clean()` flattening. It
   > needs a second scope, for three measured reasons: SABnzbd runs with `direct_unpack = 1`, so
   > audio extracts **during** the download; `incomplete` and `complete` are the same ZFS dataset
   > (both `stat -c %d` = 68), so the move is an instant rename with no observable window; and music
   > `postproc_time` is 1–3 s on recent jobs, with only 35 of 121 rows reaching 4 s. A mid-download
   > lull can therefore leave a subset stable and hashed, and the later-extracted files then appear
   > only at COMPLETION. **Bytes cannot distinguish that from a hook rewrite.** So the amended rule
   > is: the COMPLETION-only FAIL clause applies **only when the PRE-HOOK snapshot is established
   > complete** (`pre.inv` equals `last.inv`); otherwise the job is UNPROVEN, with the reason token
   > `baseline-stale`. The general principle, stated once: **every UNPROVEN clause is evaluated
   > before every FAIL clause**, so an unestablished baseline can never be reported as the estate
   > having rewritten bytes.
   >
   > **A floor against a vacuous pass.** A job with **zero** audio files present in both snapshots is
   > UNPROVEN (reason token `empty-intersection`), not BYTES-OK. "Every file present in both
   > snapshots is byte-identical" is vacuously true on an empty intersection, and PRE-only files are
   > explicitly exempt, so without this floor a zero-entry COMPLETION manifest would pass having
   > compared nothing.
   >
   > **The instrument, named by content.** `watch-d12b.sh`, sha256
   > `59f067bdc5dc236096fbd3281534ac5db992a83d8800328dc5d57dd87e92e759`, and `judge-d12b.sh`, sha256
   > `7ab24c9e96b0464f1632bf8f4a05967ceb778e5b38485462ab18ff56808837e2`. Both were driven against
   > eight synthetic controls before any real music job was spent on them, so this contract's reader
   > can see the judge is capable of all three outcomes and the watcher is capable of waiting:
   > **SC-2** returned FAIL on bytes deliberately changed after the move (`changed=1`); **SC-6** fed
   > it a would-be-FAIL input — a file present only at COMPLETION, matching no PRE-HOOK file — and
   > got `UNPROVEN reason=baseline-stale` rather than FAIL; and **SC-5** proved the watcher stays
   > alive on an empty window rather than self-exiting with nothing to watch.

The job folder is found by the SAB `history.storage` column. For all 119 `music` rows it is the final
path under `/downloads/complete/nzb/music/`, while `path` is the `/downloads/incomplete/…` working
directory (measured 2026-09-11, counts only). The container's `/downloads` is the host's
`/mnt/tank/downloads`.

## 2. Pre-declared residual lines, which are NOT evidence that beets ran (D-31 / F7)

The line-285 strip removes the `beet … import` invocation and nothing else. D-10's letter keeps the
`beets()` function body and the `BeetsTagging` gate at lines 322–324, and `extended.conf` keeps
`BeetsTagging="TRUE"` (line 28). So every music job after the strip still produces the following.

| Where (container path) | What | Why it still appears | Live line |
|---|---|---|---|
| `/config/logs/Audio.txt` | `Matching N tracks with Beets` | logged unconditionally at the top of `beets()` | 271 |
| `/config/logs/Audio.txt` | `ERROR: Unable to match using beets to a musicbrainz release` | with 285 gone, no audio file is newer than `beets-match`, so the `-newer` count at 286 is 0 and the else branch logs this | 289 |
| `/config/scripts/beets-match` | a transient file | `touch`ed at 281, removed within the same run by the existence-guarded block at 298–301. Its transient existence, and the resulting `/config/scripts` directory mtime change, are expected | 281, 298–301 |

- `requireBeetsMatch="false"` in `extended.conf` (line 29, measured 2026-09-11). The failure branch
  at 290–294 (`rm -rf "$1"/*`, exit 1) therefore does not fire. That branch compares against
  lowercase `true`.
- `beets()`'s `rm` of `library.blb` at lines 272–275 is existence-guarded
  (`if [ -f /config/scripts/library.blb ]`). An absent `library.blb`, which is the state after 04-11,
  does not abort the hook under `set -e` (refuted HIGH, `04-REVIEWS.md`).
- Line 276 tests the wrong path (`/config/scripts/beets/beets.log`), so `audio.bash` never deletes
  `beets.log`. Only `beet` writes it, so a `beets.log` newer than the stamp is direct evidence that
  `beet` ran.
- **The proof of non-invocation is the absence of the side effects** in section 1 items 2–3. It is
  not the absence of the word "Beets" in `Audio.txt`.
- **`Audio.txt` baseline (2026-09-11):** host path `/mnt/fast/appdata/arrs/sabnzbd/config/logs/Audio.txt`,
  236,596 B, mtime 2026-09-11 01:22 UTC. It holds 98 lines containing `tracks with Beets` and 87
  containing `Unable to match using beets to a musicbrainz release`. A post-strip job with at least
  one audio file adds one of each. 04-12 records the delta, not the totals.

## 3. Window prerequisite, asserted and not assumed

"Untagged" depends on `extended.conf` holding `ReplaygainTagging="false"` for the whole window.
`replaygain()` (`r128gain`, lines 263–267, gated at line 326) is the only other tag writer in
`audio.bash` (research § D-10 inventory).

Plan 04-12 asserts that line at window open **and** at window close, and asserts that `extended.conf`'s
sha256 and mtime are unchanged between the two. The baseline, from 04-01 Task 1 (2026-09-11):

| Property | Value |
|---|---|
| host path | `/mnt/fast/appdata/arrs/sabnzbd/config/extended.conf` |
| sha256 | `54c5433bba38c61e372425c34cc0c8aad2001922ca1fb6bd55e98dc1ada1b49d` |
| mtime | 2025-10-24T08:41:54Z |
| size | 2,955 B |
| line 27 | `ReplaygainTagging="false"` (followed by a trailing comment) |
| line 28 | `BeetsTagging="TRUE"` |
| line 29 | `requireBeetsMatch="false"` |

If the line is absent at either end, or the file changed between open and close, PASS is unavailable.
Criterion 3 is then recorded **OPEN**, with the reason.

## 4. Baseline SAB rows (F8)

These rows were read read-only with `sqlite3 "file:/mnt/fast/appdata/arrs/sabnzbd/config/admin/history1.db?mode=ro"`,
taking the last 8 rows with `category='music'` on 2026-09-11. `completed` is epoch UTC.
`script_line` is truncated to 60 characters, which stops before any release name.

| completed (UTC) | status | script_line (first 60 characters) |
|---|---|---|
| 2026-09-11 01:22:11 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-06 22:24:04 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-05 22:52:57 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-03 21:17:20 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-09-03 20:31:00 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-08-08 14:24:01 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-08-01 15:26:49 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |
| 2026-08-01 00:16:39 | Completed | `Exit(1): chmod: changing permissions of '/downloads/complete` |

Across the whole history there are 119 `music` rows since 2025-10-26 18:44:12 UTC. Of these, 87 match
`script_line LIKE 'Exit(1): chmod: changing permissions of ''/downloads/complete/nzb/music/%'`.

The `history` table's columns are: `id completed name nzb_name category pp script report url status
nzo_id storage path script_log script_line download_time postproc_time stage_log downloaded
completeness fail_message url_info bytes meta series md5sum password duplicate_key archive time_added`.

## 5. Window rules (orchestrator decision)

- If no music job arrives in the window plan 04-12 opens, criterion 3 is recorded **OPEN**, not
  passed.
- If a job arrives but no valid PRE-HOOK snapshot exists for it, the untagged condition is
  **UNPROVEN** and criterion 3 is recorded **OPEN**, not passed. "No valid PRE-HOOK snapshot" means
  the watcher was not running, or its first stable snapshot is later than the job's `Matching` line.
- If section 3's prerequisite fails, criterion 3 is **OPEN** (section 3).
- A FAIL on any item in section 1 is a **FAIL**, not OPEN.

**Timezone trap:** SAB `completed` is UTC. `sabnzbd.log`, `Audio.txt` and `beets.log`'s
`import started` headers are container-local, Europe/Dublin (UTC+1 in September). Measured pairing:
SAB `2026-09-06 22:24:04` UTC is `beets.log` `import started Sun Sep  6 23:24:04 2026`. Never compare
the two naively. Convert one side, and state which.

> **Amended 2026-09-13 by plan 04-14 (gap closure, criterion 3 / TAGR-04).**
>
> **Every rule above stands, unchanged and restated here so none is lost by implication:** if no
> music job arrives in the window, criterion 3 is recorded **OPEN**, not passed; if a job arrives but
> no valid PRE-HOOK snapshot exists for it, the untagged condition is **UNPROVEN** and criterion 3 is
> recorded **OPEN**, not passed; if section 3's prerequisite fails, criterion 3 is **OPEN**; and a
> FAIL on any item in section 1 is a **FAIL**, not OPEN. The timezone trap above is unchanged.
>
> **What changes is the definition of "no valid PRE-HOOK snapshot".** It previously meant "the
> watcher was not running, or its first stable snapshot is later than the job's `Matching` line".
> It now means any one of: the watcher was not running; no attributed `pre.sha256` exists for the
> job; `pre.time` is not earlier than that folder's `vanished.time`; the snapshot's inventory
> (`pre.inv`) does not match the last inventory observed before the folder vanished (`last.inv`);
> the COMPLETION manifest could not be acquired; or no audio file is present in both snapshots.
> Each maps to one reason token — `no-attributed-pre`, `ordering-unproven`, `baseline-stale`,
> `no-completion`, `empty-intersection` — and every one of them yields **UNPROVEN**, hence OPEN,
> never FAIL. The comparison against `Audio.txt`'s second-resolution `Matching` line is no longer
> required for validity, because the ordering is now structural (see the section 1 item 4
> amendment).
>
> **Two rules the first window did not need.** Window 1 produced **two** music jobs fourteen seconds
> apart from a single Lidarr search, so one job per window cannot be assumed.
>
> - **Every** post-stamp `category='music'` row is evaluated and recorded separately, and the
>   window's verdict is: **FAIL if any job is FAIL; otherwise OPEN if any job is UNPROVEN; otherwise
>   PASS if at least one job is BYTES-OK.**
> - The section 2 `Audio.txt` residual-line expectation is **per job**, so J jobs add `+J`
>   `Matching`, `+J` `ERROR: Unable to match` and `+0` `SUCCESS: Matched with beets`.
>
> **A second window is being opened under plan 04-15**, and its result is recorded in a new
> section 7. Section 6's window-1 record — including its single verdict line, which reads OPEN — is
> left standing verbatim as the honest record of the first window, and is not revised in the light
> of anything window 2 produces.
>
> **The window-2 verdict line has one exact form**, fixed here so that plans 04-15 and 04-16 cannot
> disagree about it. It begins at column 1 and matches the regular expression
> `^Verdict \(window 2\): (PASS|OPEN|FAIL) — `. The em-dash delimiter is required on **all three**
> outcomes, PASS included: without it, a line reading `Verdict (window 2): PASSING` would parse as
> PASS under a prefix match. Note that this form deliberately cannot collide with section 6's
> `^Verdict: ` line, so that file-wide invariant still counts exactly one of each.
>
> **A verdict must be supported, not asserted beside evidence.** Section 7 also carries a
> machine-readable observation block whose lines begin at column 1 with the token `OBS window2`, and
> the verdict is required to follow from those lines rather than to sit next to them.

---

## 6. Result

Filled by plan 04-12 on 2026-09-13. **Two** real `music` jobs completed inside the window, fourteen
seconds apart, both triggered by the operator's Lidarr search. Sections 1–5 were not edited.

Job folders are identified by a 12-character sha256 prefix of the folder name (`job A`, `job B`), so
the mapping to a release stays out of this public repo. The mapping lived only in host scratch and
was deleted with it.

| Field | Value |
|---|---|
| Stamp time (UTC) | **2026-09-13T09:56:48Z** (epoch `1789293408`), a 0-byte marker at `/mnt/fast/scratch-04/12/d12.stamp`, inode 1049970 |
| Window open / close (UTC) | open **2026-09-13T09:56:48Z** (stamp) → close **2026-09-13T12:21:30Z** (watcher stopped by `SIGTERM`; it was still alive, scheduled to self-exit at 12:23:00Z). Evidence read 12:21:27Z–12:24:55Z |
| SAB row (completed UTC, status, truncated `script_line`, `storage` prefix only) | **job A** `2026-09-13 12:17:59` · `Completed` · `Exit(1): chmod: changing permissions of '/downloads/complete` · `/downloads/complete/nzb/music/`<br>**job B** `2026-09-13 12:18:13` · `Completed` · `Exit(1): chmod: changing permissions of '/downloads/complete` · `/downloads/complete/nzb/music/`<br>Both are the F8 baseline shape of § 1 item 1. Music rows total 119 → **121**; rows between the § 2 baseline read (2026-09-11 01:22:11Z) and the stamp: **0**, so § 2's `Audio.txt` counts were still current at window open |
| `find …/config/scripts -newer <stamp>` output | RC **0**. Exactly **one** entry, the directory `/mnt/fast/appdata/arrs/sabnzbd/config/scripts` itself (last written 2026-09-13T12:18:13Z). **No `library.blb`, no `library.blb*`, no `beets.log`.** A second name-targeted `find` for `library.blb*` / `beets.log` / `beets-match` also returned nothing at RC **0**, and `test ! -e …/scripts/beets-match` held. Positive control: `audio.bash` is present in the same listing. The directory entry is the pre-declared § 2 row 3 — the transient `beets-match` created at line 281 and removed at 298–301 |
| `find …/config -name '*.bak' -newer <stamp>` output | RC **0**, **empty**. Positive control: the same `find` without `-newer` (RC 0) returns exactly one file, `…/config/sabnzbd.ini.bak`, 9,837 B, 2026-08-17 — the § 1 item 3 pre-declared exception, unchanged and identical to the listing plan 04-12 Task 1 recorded at window open |
| `Audio.txt` lines for the jobs (Europe/Dublin), and delta of the two residual-line counts | 240,997 B, 3,063 lines, last written 2026-09-13T12:18:13Z. `tracks with Beets` **98 → 100 (+2)**; `Unable to match using beets to a musicbrainz release` **87 → 89 (+2)**; `SUCCESS: Matched with beets` **0**. Quoted verbatim:<br>`2026-09-13 13:17:59 :: Audio :: 1.9 :: Matching 10 tracks with Beets`<br>`2026-09-13 13:17:59 :: Audio :: 1.9 :: ERROR: Unable to match using beets to a musicbrainz release`<br>`2026-09-13 13:18:12 :: Audio :: 1.9 :: Matching 15 tracks with Beets`<br>`2026-09-13 13:18:13 :: Audio :: 1.9 :: ERROR: Unable to match using beets to a musicbrainz release`<br>Converted (Dublin = UTC+1): job A `Matching` = **12:17:59Z**, job B `Matching` = **12:18:12Z**. Each job's first hook line (`Configuration:`) is 12:17:58Z and 12:18:10Z. **Exactly the two pre-declared D-31 residual lines per job, and no success line** |
| PRE-HOOK snapshot time, and its position relative to the `Matching` line | **job A** — folder first seen 12:18:00.074Z…**pre-snapshot time 12:18:00.074Z**, written 12:18:00.291Z, 10 files. Its `Matching` line is **12:17:59Z**. The snapshot is **LATER** than the `Matching` line → **INVALID**.<br>**job B** — **pre-snapshot time 12:18:12.758Z**, written 12:18:12.932Z, 15 files. Its `Matching` line is **12:18:12Z**, and `Audio.txt` resolves to one second, so the line falls anywhere in `[12:18:12.000Z, 12:18:13.000Z)`. The ordering is **INDETERMINATE** — not provably earlier → **INVALID**.<br>**Neither job has a valid PRE-HOOK snapshot under § 1 item 4 / § 5.** |
| COMPLETION snapshot time | **job A** 12:18:00.309Z, written 12:18:00.511Z, 10 files; row completed 12:17:59Z, so `post.time ≥ completed` holds. **job B** 12:18:17.067Z, written 12:18:17.249Z, 15 files; row completed 12:18:13Z, holds |
| Per-file comparison summary (identical / MOVED / deleted-by-clean / changed / COMPLETION-only) | **job A**: in both **10**, byte-identical **10**, changed **0**, PRE-only **0**, COMPLETION-only **0** (MOVED 0, new 0).<br>**job B**: in both **15**, byte-identical **15**, changed **0**, PRE-only **0**, COMPLETION-only **0** (MOVED 0, new 0).<br>**Totals 25 / 25 / 0 / 0 / 0.** No pass condition was violated — but see the verdict: both snapshots of each pair were taken at or after the hook had run, so this comparison does not span the stage it was built to span |
| `extended.conf` at open: `ReplaygainTagging` line, sha256, mtime | `ReplaygainTagging="false"` present (line 27, trailing comment on the same line); sha256 `54c5433bba38c61e372425c34cc0c8aad2001922ca1fb6bd55e98dc1ada1b49d`; mtime `2025-10-24T08:41:54Z`; size 2,955 B |
| `extended.conf` at close: `ReplaygainTagging` line, sha256, mtime | `ReplaygainTagging="false"` present, `grep -c '^ReplaygainTagging="false"'` = **1**; sha256 `54c5433bba38c61e372425c34cc0c8aad2001922ca1fb6bd55e98dc1ada1b49d`; mtime `2025-10-24T08:41:54Z`; size 2,955 B. **Unchanged open → close, and equal to the § 3 / 04-01 baseline.** The § 3 prerequisite **HELD at both ends** |
| ffprobe tag-key sets (PRE-HOOK vs COMPLETION) | Read at COMPLETION on all 25 files; because every file is byte-identical across the pair, the PRE-HOOK set is the same set by construction, not by a second read.<br>**job A**, identical on all 10: `ALBUM, ARTIST, DATE, GENRE, ORGANIZATION, TITLE, TRACKTOTAL, album_artist, disc, track`.<br>**job B**, identical on all 15: `ALBUM, ARTIST, COMMENT, COMPILATION, COPYRIGHT, DATE, DISCTOTAL, ENCODED-BY, PUBLISHER, RELEASECOUNTRY, TITLE, WORK, album_artist, disc, track`.<br>**`MUSICBRAINZ_*` keys: 0 of 25 files. `REPLAYGAIN_*` / `R128_*` keys: 0 of 25 files.** |
| **Verdict** (PASS / FAIL / OPEN, with the reason) | see the single verdict line below |

Pointer (2026-09-13, plan 04-15): the window-1 record above stands verbatim and is not revised in the light of anything window 2 produced. Criterion 3's current verdict is section 7's.

Verdict: OPEN — two music jobs completed in the window and every other pass condition held, but neither job has a valid PRE-HOOK snapshot: job A's was taken after its `Matching` line and job B's cannot be ordered against its own, so the "untagged by bytes" condition of § 1 item 4 is UNPROVEN and § 5 requires OPEN rather than PASS.

### Why no valid PRE-HOOK snapshot exists — the mechanism, recorded

This is a defect in the **instrument**, not in the estate, and it is structural rather than a
mis-execution.

SABnzbd moves a finished job into `/downloads/complete/nzb/music/` and **then** invokes the
post-processing script. The watcher armed in Task 1 watches that destination tree, so the earliest
moment it can see a job is the moment the hook is already starting. Measured on job A: the watcher's
first pass saw the folder at 12:18:00.074Z; the hook's own first line is timestamped 12:17:58Z and
its `Matching` line 12:17:59Z. On job B the first pass was 12:18:10.710Z against a hook that started
at 12:18:10Z and reached `Matching` at 12:18:12Z.

On top of that, § 1 item 4 requires the snapshot to be the *first stable* one — two consecutive
agreeing passes at least 2 s apart — which puts a floor of roughly 2–4 s between first sighting and
the snapshot. Job A's hook ran from first log line to SAB completion in **1 second**. No stability
rule with a 2-second floor can produce a snapshot inside that.

**What would close it**, for whoever carries criterion 3 forward: snapshot the job in
`/downloads/incomplete/` before the move, where the bytes are final after unpack but the hook has not
been invoked; or key the PRE-HOOK snapshot on the appearance of the folder with no stability wait,
accepting that a snapshot taken mid-move may need to be retaken. Both are changes to the watcher, not
to the estate.

### What the window did establish, recorded as weaker evidence and not as the pass condition

These are **not** substitutes for the byte proof, and they do not upgrade the verdict. They are
recorded because they are what the window bought.

- Nothing in `audio.bash`'s own artefact set reappeared: no `library.blb`, no `library.blb*` backup,
  no `beets.log`, no new `.bak`, and `beets-match` transient-then-gone exactly as § 2 pre-declares.
- Both jobs produced the two pre-declared residual log lines and **zero** `SUCCESS: Matched with
  beets`, with the `-newer beets-match` count structurally 0 now that line 285 is gone.
- No file in either job carries a single `MUSICBRAINZ_*` key.
- Both job folders are still in `complete/nzb/music/`, i.e. left in place.

### One correction to § 3's rationale, measured

§ 3 asserts the `ReplaygainTagging="false"` prerequisite, and that assertion **held**. But
`Audio.txt` logs `Replaygain Tagging: ENABLED` on both jobs, which reads as a contradiction and is
not one. In the live hook, that string is a **hardcoded literal at line 86 inside
`if [ "${ConversionFormat}" = FLAC ]`** — it never consults `ReplaygainTagging` at all. The real gate
is line 325, `if [ "${ReplaygainTagging}" = TRUE ]`, a case-sensitive comparison against the bare word
`TRUE` that the string `"false"` cannot satisfy. `replaygain()` therefore did not run, corroborated
independently by ffprobe: **0 `REPLAYGAIN_*` / `R128_*` keys across all 25 files**. Recorded so a
future reader meeting that log line does not conclude the prerequisite failed.

### Routine checks after the jobs

`bash scripts/quick-health-check.sh` from the workstation, 2026-09-13T12:24:42Z: **exit 0** in 13 s.
One `❌` (`Traefik dashboard: Not accessible`, report-only, in the 04-01 ROUTINE BASELINE), zero
`⚠️`. Census counters all at target — `beets databases: 1`, `tagger databases: 0`, `retired paths
present: 0`, `rw on Music, non-tagger: 0`, `rw on Music, tagger-capable: 0`, `FAILURES total: 0` —
and the drift block green (`✅ vendored files match (3)`). **No beets database was regenerated by
either job.**

---

## 7. Result — window 2 (plan 04-15)

Filled by plan 04-15 on 2026-09-13, under the contract as amended by plan 04-14 and committed at
`0022e91` — committer epoch `1789336341`, which is **717 seconds (11 m 57 s) earlier than this
window's stamp**, and an ancestor of HEAD. Sections 1–6 were not edited; the dated pointer line above
section 6's verdict is the only mark this plan leaves outside section 7.

**Three** real `music` jobs completed inside the window. Job folders are identified by a 12-character
sha256 prefix of the folder name, so the mapping to a release stays out of this public repo; the
mapping lived only in host scratch and was deleted with it.
**File mtimes are never used as provenance.**

| Field | Value |
|---|---|
| Stamp time (UTC) | **2026-09-13T22:04:18Z** (epoch `1789337058`), a 0-byte marker at `/mnt/fast/scratch-04/15/d12b.stamp`, inode 1050068 |
| Window open / close (UTC) | open **2026-09-13T22:04:18Z** (stamp) → close **2026-09-13T22:27:08Z**. The watcher had **not** exited on its own (`kill -0` succeeded); it was stopped by `SIGTERM` and was gone within 1 s. It was launched with an explicit `LINGER=604800` and had 7 days left to run. Evidence read 22:27:08Z–22:51Z |
| Watcher instrument state at stop | `watch.out` **0 bytes** and there is no separate `watch.err` — the production launch merges both streams with `2>&1`, so its absence is by design, not a failed read. `watch/hash.err` is **3,063 bytes / 45 lines**, and that is *expected*: every one of the 45 is `sha256sum: … : No such file or directory`, 44 of them on a `.flac`, from the single refused hash pass described below. Byte counts are quoted because an empty error log and an unreadable one look identical |
| SAB rows (READ 1, run **before** any branch, window-bounded `completed > open AND completed <= close`) | `history_rc` **0**, stderr **0 bytes**, **J = 3**.<br>**job 209cc6020f24** `2026-09-13 22:17:48` · `Completed` · `postproc_time` 0<br>**job b5a3ff6815c4** `2026-09-13 22:21:07` · `Completed` · `postproc_time` 10<br>**job 227d31189be6** `2026-09-13 22:21:54` · `Completed` · `postproc_time` 10<br>All three: `script_line` begins `Exit(1): chmod: changing permissions of '/downloads/complete`, `storage` parent `/downloads/complete/nzb/music`, `path` parent `/downloads/incomplete`. **All three are the F8 baseline shape of § 1 item 1.** Music rows total 121 → **124** at the close read, and `completed` rows between 04-12's close and this stamp: **0**, so § 2's counts were still current at window open |
| Activity outside the window, recorded so J is not mistaken for "all that happened" | By 22:50:52Z a further **25** `category='music'` rows had completed **after** the 22:27:08Z close (music rows 124 → 149). They are outside the window by construction and none is evaluated here. The side-effect reads below were taken while `MAX(completed)` was still `1789338114`, the last in-window row, so none of them can have swept in a post-window job |
| `find …/config/scripts -newer <stamp>` output | RC **0**. Exactly **one** entry, the directory `/mnt/fast/appdata/arrs/sabnzbd/config/scripts` itself. **No `library.blb`, no `library.blb*`, no `beets.log`.** A second name-targeted `find` across the whole `/config` tree for `library.blb*` / `beets.log` / `beets-match` also returned nothing at RC **0**, and `test ! -e …/scripts/beets-match` held. Positive control: `audio.bash` is present in the same listing, beside 8 other entries. The directory entry is the pre-declared § 2 row 3 — the transient `beets-match` created at line 281 and removed at 298–301 |
| `find …/config -name '*.bak' -newer <stamp>` output | RC **0**, **empty**. Positive control: the same `find` without `-newer` (RC 0) returns exactly one file, `…/config/sabnzbd.ini.bak`, 9,837 B, 2026-08-17 09:26 — the § 1 item 3 pre-declared exception, unchanged |
| `Audio.txt` delta, per job (§ 2 expectation for J = 3 is `+3 / +3 / +0`) | 248,650 B, 3,162 lines, last written 2026-09-13T22:21:54Z. `tracks with Beets` **+3** (total 103); `Unable to match using beets to a musicbrainz release` **+3** (total 92); `SUCCESS: Matched with beets` **+0** (total **0**). Derived two independent ways that agree: by filtering lines on their own in-window timestamp (3 / 3 / 0), and against 04-12's closing totals of 100 / 89 / 0. Quoted verbatim:<br>`2026-09-13 23:17:48 :: Audio :: 1.9 :: Matching 10 tracks with Beets`<br>`2026-09-13 23:17:48 :: Audio :: 1.9 :: ERROR: Unable to match using beets to a musicbrainz release`<br>`2026-09-13 23:21:07 :: Audio :: 1.9 :: Matching 16 tracks with Beets`<br>`2026-09-13 23:21:07 :: Audio :: 1.9 :: ERROR: Unable to match using beets to a musicbrainz release`<br>`2026-09-13 23:21:54 :: Audio :: 1.9 :: Matching 36 tracks with Beets`<br>`2026-09-13 23:21:54 :: Audio :: 1.9 :: ERROR: Unable to match using beets to a musicbrainz release`<br>**Converted, Dublin → UTC (subtract one hour):** `22:17:48Z`, `22:21:07Z`, `22:21:54Z` — each equal to its own SAB row's `completed` to the second. **Exactly the two pre-declared D-31 residual lines per job, and no success line** |
| PRE-HOOK snapshot, per job, with the § 1 item 4 validity and completeness results | **job 209cc6020f24** — under `incomplete/` 22:17:44.983Z → vanished 22:17:49.147Z (**4 polls**). `pre.sha256` **ABSENT**, `pre.inv` ABSENT, `pre_complete=na`. **No snapshot was published.**<br>**job b5a3ff6815c4** — under `incomplete/` 22:20:23.432Z → vanished 22:21:09.321Z (**41 polls**). `pre.sha256` **ABSENT**, `pre_complete=na`. **No snapshot was published.**<br>**job 227d31189be6** — under `incomplete/` 22:20:34.995Z → vanished 22:21:55.650Z (**67 polls**). One publication attempt at 22:21:45.096Z was **REFUSED** (`hash-rc-123`, `agree=2`): the folder's inventory went **62 entries before the hash pass → 19 after it**, and 45 files disappeared mid-pass. `pre.sha256` **ABSENT**, `pre_complete=na`. **No snapshot was published.**<br>**All three fall under the § 5 amendment's `no-attributed-pre` reason token, which yields UNPROVEN, never FAIL.** The structural-ordering argument that a published snapshot would have carried — taken while the folder was still at the incomplete path, inventory unchanged across the hash pass, and SABnzbd cannot invoke the hook before moving it — **is therefore unavailable for all three jobs**, and no `Audio.txt` comparison is substituted for it |
| COMPLETION snapshot, per job | **job 209cc6020f24** destination first seen 22:17:49.156Z, `post.time` 22:17:53.358Z, `post.rc` 0, **10** files; row completed 22:17:48Z.<br>**job b5a3ff6815c4** destination first seen 22:21:04.131Z, `post.time` 22:21:14.914Z, `post.rc` 0, **16** files; row completed 22:21:07Z.<br>**job 227d31189be6** destination first seen 22:21:45.120Z, `post.time` 22:22:00.892Z, **`post.rc` = 123**, **20** files against 36 the hook reported; row completed 22:21:54Z. That 123 is a *per-job acquisition status*, not one of the six producer statuses in the observation block below — its COMPLETION manifest is partial, which is an independent second reason this job could not be judged, and which the ladder would have caught at the `no-completion` clause had `no-attributed-pre` not already fired |
| Per-file comparison summary (judge status token lifted from `judge-d12b.sh`'s own stdout, `judge_rc` 0) | **job 209cc6020f24**: `STATUS=UNPROVEN reason=no-attributed-pre`, in both **0**, byte-identical 0, changed **0**, PRE-only 0, COMPLETION-only 10, MOVED 0.<br>**job b5a3ff6815c4**: `STATUS=UNPROVEN reason=no-attributed-pre`, in both **0**, changed **0**, COMPLETION-only 16.<br>**job 227d31189be6**: `STATUS=UNPROVEN reason=no-attributed-pre`, in both **0**, changed **0**, COMPLETION-only 20, `hash_span_refused=1`.<br>**No byte changed on any job — but nothing was compared, either.** A zero-file intersection is precisely what the § 1 item 4 amendment's `empty-intersection` floor exists to stop rendering as BYTES-OK, and the ladder resolved all three one clause earlier still |
| Job folders left in place (§ 1 / D-31) | At its COMPLETION snapshot **every one of the three was present at its destination under `complete/nzb/music/` and was hashed there** (10, 16 and 20 files), which is the measurement that speaks to what `audio.bash` did: it left all three in place. At window close + ~8 min, **1 of 3** (job 209cc6020f24, 10 files) was still at its recorded destination; the other two had been removed by something downstream, after the window, and were not found anywhere in the downloads tree. **Nothing that existed at window open was removed** — the pre-existing-folder set is intact (`pre_existing_folders_now_missing=0`), and `/mnt/tank/downloads/incomplete` still holds exactly its 6 stale January orphans, untouched. The removal is recorded as unattributed rather than guessed at; it is outside the window and is not evidence about the hook |
| `extended.conf` at open: `ReplaygainTagging` line, sha256, mtime | `ReplaygainTagging="false"` present (line 27, trailing comment on the same line); sha256 `54c5433bba38c61e372425c34cc0c8aad2001922ca1fb6bd55e98dc1ada1b49d`; mtime `2025-10-24T08:41:54Z`; size 2,955 B |
| `extended.conf` at close: `ReplaygainTagging` line, sha256, mtime | `grep -c '^ReplaygainTagging="false"'` = **1**; sha256 `54c5433bba38c61e372425c34cc0c8aad2001922ca1fb6bd55e98dc1ada1b49d`; mtime `2025-10-24T08:41:54Z`; size 2,955 B. **Unchanged open → close and equal to the § 3 / 04-01 baseline.** Proven more strongly than by comparing two reads: `find … -name extended.conf -newer <stamp>` returned **nothing**, so the file was never written during the window at all. The § 3 prerequisite **HELD at both ends** |
| ffprobe tag-key sets at COMPLETION (keys, never values) | Available for **job 209cc6020f24 only**, the one destination folder still in place; identical across all 10 files: `album, album_artist, artist, date, disc, encoded_by, genre, language, publisher, title, track`. **`MUSICBRAINZ_*` keys: 0. `REPLAYGAIN_*` / `R128_*` keys: 0.** For the other two jobs the COMPLETION-time tag-key read is **unavailable**, because their folders were removed downstream after the window; this is recorded as a gap rather than inferred, and it changes nothing, since ffprobe keys are weaker corroborating evidence that cannot upgrade a verdict in either direction |
| Estate side, re-asserted read-only | `cmp` of appdata `audio.bash` against the repo's vendored copy returns **0**; `grep -cE '^[[:space:]]*beet '` returns **0**. No estate file was modified by this plan |
| **Verdict** (PASS / FAIL / OPEN, with the reason) | see the single verdict line below |

### A fourth attributed row, which is not one of the three jobs

The watcher attributed **four** history rows in the window (`rows_seen=4`) and the judge returned
**`STATUS=BYTES-OK`** on one of them — job `77d1f79d8f07`, 15 of 15 files byte-identical,
`pre_complete=yes`. **It is deliberately excluded from the job set, and this is recorded here rather
than quietly dropped, because a BYTES-OK sitting in host scratch is exactly the kind of thing a later
reader would use to argue the window passed.** Five independent measurements say it is not a
post-processed music job:

1. READ 1, re-run window-bounded against the live database, returns **3** rows, not 4. A query for
   that row's exact `completed` value across **every** category returns **0**; a query for its
   recorded `storage` string returns **0**. The row existed when the watcher read it at 22:13:26.935Z
   and **no longer exists in SABnzbd's history**.
2. Its `storage` parent is `/mnt/tank/downloads/incomplete` — **not** `complete/nzb/music/`. Both its
   snapshots were therefore taken from the same incomplete folder, 1.26 s apart, with no move and no
   hook between them, which makes a byte-identical result structurally guaranteed and evidentially
   void.
3. `Audio.txt` carries **no hook lines at all** in that minute — no `Configuration:`, no `Matching`,
   no `ERROR`. The hook never ran for it.
4. The `category='music'` census after the stamp is `music → 3`, and the total moved 121 → 124,
   i.e. exactly the three jobs above.
5. Its `pp` and `status` cannot be re-read, because the row is gone.

Counting it as a fourth job would not change the verdict — § 5's window rule resolves to OPEN on the
first UNPROVEN regardless — but it would have put an unearned BYTES-OK in the record.

### Why no PRE-HOOK snapshot exists for any of the three jobs — measured per poll

This is plan 04-14's explicitly carried-forward HIGH residual risk firing on real jobs: *"whether a
real job's inventory actually holds still for `STABLE_PASSES` consecutive polls under
`incomplete/`."* It was flagged as a known limit rather than an assumed capability, the design was
built to fail **safe**, and it did. The window was armed at `POLL_FS=1` (half the default) precisely
to attack it, with `STABLE_PASSES=2` unchanged.

The watcher's publication gate requires, in order: `agree ≥ STABLE_PASSES`, a non-empty inventory,
**a non-empty audio list**, and an inventory differing from the last one hashed. Reconstructed from
each job's own poll trail — entry counts and audio-file counts per poll, names never read:

| | 209cc6020f24 | b5a3ff6815c4 | 227d31189be6 | *(77d1f79d8f07, excluded)* |
|---|---|---|---|---|
| polls under `incomplete/` | 4 | 41 | 67 | 63 |
| lifetime there | 3.1 s | 44 s | 80 s | 66 s |
| longest run of identical inventories | 1 | 5 | 19 | **57** |
| **audio files seen at any poll** | **0** | **0** | 4 → 35 | 15 |
| longest stable run **with audio present** | **0** | **0** | **2** | **57** |
| outcome | never stable | no audio ever visible | attempted once, refused | published at `passes=2` |

Two distinct mechanisms, both structural and neither a mis-execution:

- **Two of three jobs never showed a single audio file under `incomplete/`.** For job b5a3ff6815c4
  the destination folder was first seen at 22:21:04.131Z, **5.2 s before** the incomplete folder
  disappeared at 22:21:09.321Z, and that folder's final observed inventory was **empty**. The audio
  reached the destination without ever being visible to a 1-second poll of the incomplete path, so
  the gate that requires a non-empty audio list can never open. Job 209cc6020f24 existed under
  `incomplete/` for **3.1 seconds in total**, with `postproc_time=0`.
- **The one job that did show audio was still growing when it was moved.** Job 227d31189be6's audio
  count climbed 4 → 35 over 34 polls and then fell to 0 for its last 9 polls as SABnzbd took the
  contents away. It reached two agreeing passes once, at 22:21:45.096Z, and the hash pass was
  **refused by the instrument's own protocol** — the inventory went 62 → 19 across the pass and 45
  files vanished underneath it. That refusal is the 04-14 SC-7 control firing on a real job: it
  produced no snapshot rather than a snapshot that had straddled the move.

The contrast with the excluded row is the positive control this window did not otherwise have: when
a folder genuinely rests under `incomplete/` — 57 consecutive identical inventories with 15 audio
files present — **the instrument publishes, and publishes complete** (`pre.inv` equals `last.inv`).
The watcher is working as specified. What is unproven is the estate's behaviour, not the watcher's.

### Observations supporting the verdict

OBS window2 meta stamp_epoch=1789337058 open_utc=2026-09-13T22:04:18Z close_utc=2026-09-13T22:27:08Z jobs=3 rows_after_stamp=3
OBS window2 job=209cc6020f24 STATUS=UNPROVEN reason=no-attributed-pre attribution=path files_in_both=0 byte_identical=0 changed=0 pre_only=0 completion_only=10 moved=0 pre_complete=na
OBS window2 job=b5a3ff6815c4 STATUS=UNPROVEN reason=no-attributed-pre attribution=path files_in_both=0 byte_identical=0 changed=0 pre_only=0 completion_only=16 moved=0 pre_complete=na
OBS window2 job=227d31189be6 STATUS=UNPROVEN reason=no-attributed-pre attribution=path files_in_both=0 byte_identical=0 changed=0 pre_only=0 completion_only=20 moved=0 pre_complete=na
OBS window2 prereq replaygain_line=1 extended_conf_changed=no
OBS window2 sideeffects success_lines=0 bak_new=0 libraryblb=0 beetslog=0 matching_delta=3 error_delta=3
OBS window2 producers history_rc=0 find_scripts_rc=0 find_bak_rc=0 audiotxt_rc=0 judge_rc=0 qhc_rc=0

Verdict (window 2): OPEN — three music jobs completed in the window and every side-effect condition and both ends of the § 3 prerequisite held, but none of the three published a PRE-HOOK snapshot, so all three are STATUS=UNPROVEN reason=no-attributed-pre with a zero-file intersection: under direct_unpack two of them never exposed a single audio file to a 1-second poll of the incomplete tree and the third was still growing when SABnzbd moved it, its one hash attempt refused mid-pass, so the "untagged by bytes" condition of § 1 item 4 is UNPROVEN and § 5 requires OPEN rather than PASS.

**The precedence asymmetry, stated deliberately so it reads as designed rather than inconsistent.** A
FAIL takes precedence over an UNPROVEN **at the window level**, because a proven violation on one job
is a real finding even if another job could not be measured; inside a single job UNPROVEN takes
precedence over FAIL, because bytes alone cannot separate a late extraction from a hook rewrite.
Neither direction was exercised here: no job reached a FAIL clause, and every one of the three
resolved at the ladder's **first** UNPROVEN clause.

### What the window did establish, recorded as weaker evidence and explicitly not as the pass condition

These are **not** substitutes for the byte proof and none of them upgrades the verdict. They are
recorded because they are what the window bought, and they are the third independent confirmation of
the same side-effect set after 04-12's two jobs.

- Nothing in `audio.bash`'s own artefact set reappeared: no `library.blb`, no `library.blb*` backup,
  no `beets.log`, no new `.bak`, and `beets-match` transient-then-gone exactly as § 2 pre-declares.
- All three jobs produced the two pre-declared residual log lines and **zero** `SUCCESS: Matched with
  beets`, with the `-newer beets-match` count structurally 0 now that line 285 is gone.
- The one job whose folder could still be read carries **0** `MUSICBRAINZ_*` and **0** `REPLAYGAIN_*`
  / `R128_*` keys across all 10 files.
- The vendored `audio.bash` on the host is byte-identical to the repo copy and contains **0** `beet`
  invocations.

### Routine checks after the jobs

`bash scripts/quick-health-check.sh` from the workstation: **exit 0**. One `❌` (`Traefik dashboard:
Not accessible`, report-only, in the 04-01 ROUTINE BASELINE), zero `⚠️`. Census counters all at
target — `beets databases: 1`, `tagger databases: 0`, `retired paths present: 0`, `rw on Music,
non-tagger: 0`, `rw on Music, tagger-capable: 0`, `FAILURES total: 0` — and the drift block green
(`✅ vendored files match (3)`). **No beets database was regenerated by any of the three jobs.** No
standing guard went red, so none had to be recorded red.

### What would close it, for whoever carries criterion 3 forward

The estate side of criterion 3 has now been measured clean on **five** real post-strip music jobs
across two windows, with zero contrary indications. What remains unproven is only the byte-level
capture, and both remaining obstacles are now named and measured rather than suspected: the audio is
frequently **never visible under `incomplete/` at all**, and where it is visible it is still growing
when the move happens. A third window with the same instrument would most likely produce the same
result; closing this by bytes needs either a capture point that does not depend on the audio resting
in a tree SABnzbd is actively draining, or an explicit decision that the side-effect evidence — now
threefold and unanimous — is what criterion 3 will be discharged on.
