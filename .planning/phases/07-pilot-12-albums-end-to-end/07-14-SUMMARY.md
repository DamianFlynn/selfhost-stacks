---
phase: 07-pilot-12-albums-end-to-end
plan: 14
subsystem: music-tagging / E5 in-place tag repair of legacy library files (D-19a, D-24)
tags: [e5, def-leppard, albumartist, mediafile, in-place-tag-write, qual-02, jellyfin-targeted-update, ma-barrier, phase7]
requires: [07-13, 07-06, 07-07]
provides:
  - "STATE 07-14-REPAIRED: E5 applied and verified on 14/14 FLAC of Def Leppard/Def Leppard (2015)/ (albumartist only)"
  - "A guarded mediafile apply program pattern (exact path allowlist, per-file precondition, uid 568, abort on first mismatch) for in-place legacy-file tag repairs"
  - "DEF-07-14-01: MA 'Brian Coll' track-artist anomaly on 86 Def Leppard tracks, filed for 07-15"
affects: [07-15, phase-8, phase-9]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/07-14-SUMMARY.md
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-14-e5-repair.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Operator at the Task 1 gate: \"apply\" (2026-09-27T13:14:55Z), recorded as DISPOSITION: apply, so all 14 files, including MA's hard-erroring CD 01-06"
  - "E5 was repaired as albumartist only. The album tag stays \"Def Leppard\", because the release is the self-titled album"
  - "Taylor Swift (2006) has the same folder shape but is not defective (album_artist present, album tag differs from both folders), so it was excluded"
requirements-completed: [CONS-04, QUAL-02]
metrics:
  completed: 2026-09-27
  runs: 2 (Task 1 measurement + gate; continuation for Task 2)
  duration: "Task 2 13:14Z – 13:21Z (the write itself 13:16:29Z – 13:16:31Z)"
  tasks: 2
  files_changed_in_library: 14
---

# Phase 7 Plan 14: E5 Def Leppard (2015) albumartist repair — Summary

**The live E5 defect is closed on the files. All 14 FLAC in `Def Leppard/Def Leppard (2015)/` now
carry `albumartist = "Def Leppard"` (mediafile writes it as three Vorbis keys: `ALBUM ARTIST`,
`ALBUM_ARTIST` and `ALBUMARTIST`). Nothing else changed. `diff-music-tags.sh` over `pre-07-e5` →
`post-07-e5` exits 0 with 14 matched, 28 gained, 0 dropped and 0 changed, which is exactly what the
Task 1 scratch run predicted. Audio frames, the STREAMINFO md5 and decoded PCM are identical on
14/14 files. Ownership stays `568:568`, and a before/after manifest of the whole library (2,885
entries) shows only these 14 files changed.** It was a named operation, separate from the twelve,
and the ledger records it as such (`STATE 07-14-REPAIRED`).

## What was done

- **Task 1** (4b3ce16, previous agent): measured the defect, set the repair set to Def Leppard
  (2015) (14 FLAC) and excluded Taylor Swift (2006), which has the same shape but is not broken.
  It proved the tool on scratch copies, took the `pre-07-e5` capture, verified the fence, and
  proposed the repair.
- **Gate:** the operator answered `apply` (13:14:55Z), recorded verbatim with `DISPOSITION: apply`.
- **Re-verify before writing:** the live files sha-matched `.zfs/snapshot/pre-07-pilot` (14 OK). A
  fresh beets-flask fingerprint was identical to Task 1's. The next Jellyfin scheduled scan is
  ≈ 23:33Z, about 10 h 18 min of margin.
- **Apply:** `e5apply.py` is a new program, separate from the scratch-only `scratchwrite.py`. It
  runs once per file via `docker exec -i -u 568 beets-flask /venv/bin/python -`. Its guards are an
  exact 14-path allowlist, uid 568, regular-file only, and a precondition of albumartist None,
  album/artist "Def Leppard" and no raw albumartist key. It sets albumartist only, save()s,
  re-reads, and the loop aborts on the first non-zero RC. The refusal paths were driven first
  (non-allowlist RC 3, uid 0 RC 4, `..` path RC 3). The **BARRIER READ at 13:16:29Z was VERIFIED**
  in the same shell that gated the loop, and 14/14 files wrote with RC 0 between 13:16:29Z and
  13:16:31Z, in place (same inode, same size).
- **Verify:** see `artifacts/07-14-e5-repair.txt` § TASK 2, V1–V7. CD 01-06 (Sea of Love) is clean
  under `ffprobe -v error` and a full decode, the same as before: its "hard error" was always MA's,
  never the file's.
- **Jellyfin:** one targeted `POST /Library/Media/Updated` with the 14 file paths and `UpdateType
  Modified`, returning HTTP 204. It was re-read at 31 s and again at 140 s: AlbumArtist Def
  Leppard, and ArtistItems ["Def Leppard"] on all 14. `MetadataSavers` is still `[]` and no
  sidecar was written. No full refresh ran and no scan was triggered.
- **MA:** not synced. The barrier was VERIFIED again after the write (13:18:42Z), and counts are
  70/1244/66, unchanged. The Def Leppard (2015) rows in MA are unchanged too, which is correct
  while the barrier holds.
- **D-24 census:** 29, the pinned 29 from 07-07. None of them are in this folder, and the prose's
  "Def Leppard track" (`On Through the Night … Overture.flac`) is unchanged. As Task 1 established,
  this repair cannot move the census. The after-reading proper stays with 07-15.

## For 07-15

After the MA sync, read four things:

- whether album 116 stops mapping to the top-level `Def Leppard/` folder and gains
  album_artists;
- the album_artists of the 14 tracks;
- whether "Sea Of Love" gets an album;
- **DEF-07-14-01** ("Brian Coll", artist id 116 on 86 Def Leppard tracks). This one is separate
  from E5: do not score it as E5 success or failure.

The MA fs-sync tasks are still disabled, and the re-enable is owed at 07-15.

## Deviations from Plan

1. **[Rule 3 - Blocking, trivial] diff-music-tags.sh invocation.** The first call passed the bare
   capture names and returned RC 2 ("input not found"), a usage error that read nothing. It was
   re-run with the full `.ndjson.gz` paths and exited 0. Both calls are recorded in the artifact.
2. **Jellyfin re-read timing.** The first album/track re-read was taken 31 s after the POST,
   against the plan's ≥ 60 s. A second re-read at 140 s gave the same result, and both are
   recorded. Every value read was already true before the write, so the timing could not produce a
   false pass. `DateLastRefreshed` came back null through that query, so there is no evidence of
   whether Jellyfin re-probed the files.
3. **Ledger token name.** The token is `STATE 07-14-REPAIRED`, not an `E5-…` name, because the
   ledger's extraction grammar `07-14-[A-Z][A-Z-]*[A-Z]` does not match a name with a digit in
   it. "E5" is spelled out in the token's text, and the extraction returns the token.
4. **MA artist count.** `ma-0714.sh` prints albums and tracks only, so a read-only sibling
   (`ma-artists-0714.sh`, same login, `music/artists/library_items` with the provider filter) read
   the 66.

No STOP condition fired, and nothing needed recovery.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the guarded write program on LXC 100 (`/root/phase07-0714/e5apply.py`,
root-only directory). T-07-14-01/02/04/05 were mitigated as planned. T-07-14-03 was mitigated too:
no zfs write verb was used, and the artifact screen for the forbidden verbs counts 0.

## Self-Check: PASSED

- FOUND: artifacts/07-14-e5-repair.txt (both plan verify commands pass: TASK1-VERIFY-PASS, TASK2-VERIFY-PASS)
- FOUND: ledger `STATE 07-14-REPAIRED` (the grammar extraction returns it)
- FOUND: DEF-07-14-01 in deferred-items.md
- FOUND: commits 4b3ce16 (Task 1) and 4ef90d1 (Task 2)
