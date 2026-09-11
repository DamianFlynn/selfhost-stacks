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

---

## 6. Result

PENDING — filled by 04-12

| Field | Value |
|---|---|
| Stamp time (UTC) | PENDING — filled by 04-12 |
| Window open / close (UTC) | PENDING — filled by 04-12 |
| SAB row (completed UTC, status, truncated `script_line`, `storage` prefix only) | PENDING — filled by 04-12 |
| `find /mnt/fast/appdata/arrs/sabnzbd/config/scripts -newer <stamp>` output | PENDING — filled by 04-12 |
| `find /mnt/fast/appdata/arrs/sabnzbd/config -name '*.bak' -newer <stamp>` output | PENDING — filled by 04-12 |
| `Audio.txt` lines for the job (Europe/Dublin), and delta of the two residual-line counts | PENDING — filled by 04-12 |
| PRE-HOOK snapshot time, and its position relative to the `Matching` line | PENDING — filled by 04-12 |
| COMPLETION snapshot time | PENDING — filled by 04-12 |
| Per-file comparison summary (identical / MOVED / deleted-by-clean / changed / COMPLETION-only) | PENDING — filled by 04-12 |
| `extended.conf` at open: `ReplaygainTagging` line, sha256, mtime | PENDING — filled by 04-12 |
| `extended.conf` at close: `ReplaygainTagging` line, sha256, mtime | PENDING — filled by 04-12 |
| ffprobe tag-key sets (PRE-HOOK vs COMPLETION) | PENDING — filled by 04-12 |
| **Verdict** (PASS / FAIL / OPEN, with the reason) | PENDING — filled by 04-12 |
