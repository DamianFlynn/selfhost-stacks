---
phase: 07-pilot-12-albums-end-to-end
plan: 13
subsystem: music-tagging / the DJ pair through beets-flask 02-review and E1 routing (D-08)
tags: [dj, d-08, e1-routing, route-dj-album, as-is, d-26, d-29, file-bytes, jellyfin-targeted-update, ma-barrier, phase7]
requires: [07-12, 07-04, 07-06, 07-07]
provides:
  - "STATE 07-13-PARTIAL: P11 held — P07 and P08 landed and routed under /media/Music/DJ/ (library 9 albums / 197 items)"
  - "E1 / D-08 proven on real imported content: route-dj-album.sh --apply (modify -W, DB-only) + move, 20/20 files byte-identical"
  - "DEF-07-13-01 — the route script's tag rewrite, found and fixed (-W) before any real --apply; open hazard beet update/write over DJ/"
  - "DEF-07-13-02 — a targeted Created body that includes the new top-level folder materialised DJ/ (DEF-07-12-11 did not recur)"
affects: [07-15, 07-17, phase-9]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-13-dj-pair.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/07-13-SUMMARY.md
  modified:
    - scripts/route-dj-album.sh
    - scripts/quick-health-check.sh
    - .planning/phases/07-pilot-12-albums-end-to-end/07-13-PLAN.md
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Operator at the gate: \"Fix script (-W), then import (Recommended)\" — route-dj-album.sh step (c) became `modify -a -M -W -y` (DB-only); the plan's file-tag albumtype check became DB ALBUMTYPE + FILE BYTES UNCHANGED (641498a)"
  - "Operator: \"P07 imported-asis\", \"P08 imported-asis\"; P11 held (unstaged)"
  - "Routing is DB-only: `dj` lives in library.db alone, and DJ files keep their tags byte-for-byte"
requirements-completed: [IMPT-01, QUAL-02, CONS-04]
metrics:
  completed: 2026-09-27
  runs: 1 (three agents; gate, route fix and continuation)
  duration: "11:53Z – 12:50Z (includes the gate, the -W fix and the operator's UI imports)"
---

# Phase 7 Plan 13: DJ pair imported as-is and routed to DJ/ by D-08 — Summary

**P07 (Mastermix Issue 420) and P08 (Mastermix Issue 421) were imported as-is through `02-review`.
`route-dj-album.sh --apply` then routed them to `/media/Music/DJ/`, and every return code was 0.
All 20 files are byte-identical to their staged copies, and `albumtype` reads `dj` in the database
on both albums and all 20 items. The final paths match the 20 frozen oracle lines exactly, and
every protected DJ field survived, including all seven BPM ranges. P11 is held. E1's routing
mechanism is now proven on real, imported content.**

## What the operator needs to know

1. **The route script would have damaged every DJ file, and it was fixed before it touched one
   (DEF-07-13-01).** As first written, step (c) ran `modify` without `-W`. Because
   `import.write: yes` is set, beets would have rewritten every tag of every file from its DB row.
   Measured on scratch copies, the old script changed 30 of 30 files:
   - BPM ranges were truncated (`116-117` became `116`, 7 of P07's 10 files);
   - keys were lower-cased (`5A` became `5a`, 9 of P11's files);
   - ID3 v2.3 was re-saved as v2.4, and TBPM `0` / TDRC `0000` were added.

   It could not even write `albumtype=dj` to the file, because mediafile's shared frame deletes
   it. Its own read-back still printed ✅.

   You chose the `-W` fix (998625b), which makes routing DB-only. On the same copies it left 30 of
   30 files byte-identical. On real content today it left 20 of 20 byte-identical.
   - **Open hazard:** the files carry no `dj`. A future `beet update` over `DJ/` would un-set it in
     the DB (a pretend run shows `albumtype: dj -> ''` on 10 of 10 items), and a `beet write` would
     redo the damage. Nothing in this pipeline runs either, but Phase 9 must not run them over `DJ/`.
2. **P11 is held (D-26 FALSE).** Its files carry two different album values, and as-is import
   would group all ten under one file's value. It was never imported. Its staged copy was removed
   at 12:22:44Z, and the source is unchanged.
3. **D-29: no candidate passed on any of the three folders.** Every MusicBrainz candidate was a
   different issue or a different artist, and each was refused on track count.
   - P07 shows the stub trap CLAUDE.md warns about. Rank 3, "Mastermix Issue 456", has 10 tracks,
     the same total as the files, so a total-count check alone would pass it. It fails per disc
     (one medium of 10 against the files' 5 + 5), and every mapped track is a different song.
   - That is why P07 and P08 went in as-is, inside `02-review`, and not through the `03-asis`
     bootleg inbox (D-26).
4. **Jellyfin picked up the new `DJ/` folder straight away (DEF-07-13-02).** The one targeted POST
   included the `/media/Music/DJ` folder path as well as the 20 file paths. Both albums appeared
   within 80 s, so DEF-07-12-11 (P06's new `CYRIL/` folder not appearing) did not recur. This is
   one observation, not a controlled test.

## Per-album readings

| P-ID | Final path `/media/Music/…` | Window in artist tree | DB albumtype | File bytes | Oracle | C3 | C4 | C7 | C8 | Jellyfin |
|------|-----------------------------|-----------------------|--------------|------------|--------|----|----|----|----|----------|
| P07 | DJ/Mastermix/Issue 420/ (10 MP3, 5 + 5) | 4 min 58 s | dj 10/10 | UNCHANGED 10/10 | = lines 157–166 | PASS | PASS | PASS | PASS | PASS: 1 album, Mastermix, 10 children, discs 1/2 |
| P08 | DJ/Various Artists/Mastermix Issue 421/ (10 MP3) | 4 min 44 s | dj 10/10 | UNCHANGED 10/10 | = lines 167–176 | PASS | PASS | PASS | PASS | PASS: 1 album, Various Artists, 10 children |

- **Protected fields:** P07 kept all 20 values (bpm 10, genre 10) and P08 kept all 10 (genre).
  Nothing changed and nothing was dropped. All 20 files are still ID3 v2.3. Neither album carries
  TKEY, so the key-case risk belonged only to P11, which is held.
- **Criterion 3:** 0 mismatches in 140 comparisons. The 07-12 comparator reported 30, and every
  one was a tag absent from the file against beets' null default (the as-is shape). `crit3c.py`
  handles that one class, and 3 of 3 planted controls still fire.
- **Criterion 4:** the diff exits 0, with 10 of 10 files matched per album and 0 dropped, gained
  or changed. The DEF-07-12-09 truncated-frame caveat did not arise.
- **Criterion 7:** `check-music-import.sh` exited 0 over 197 items, with `DJ as-is exception: 20`,
  0 findings and 0 UNKNOWN.
- **Criterion 8:** the P07, P08 and P11 sources are unchanged, and the P07 and P08 staged copies
  equal their manifests.
- **Transient directories:** `Mastermix/` and `Various Artists/Mastermix Issue 421/` are gone, and
  there are 0 empty directories. Jellyfin never indexed a transient path, and no POST was issued
  inside either window.
- **Sidecars:** MetadataSavers is still `[]`. There is no sidecar: nothing changed in the library
  5 min 22 s after the POST, and the .nfo count is still 91.
- **ADDED ORDER: PASS.** P07 landed at 12:32:54Z and P08 at 12:33:21Z, both after 07-12's latest
  album (P04, 23:11:42Z).
- **Barrier:** VERIFIED at 12:36:22Z (before routing) and 12:43:18Z (after). MA counts are
  70 / 1,244 / 66, unchanged. The fence holds, with 3 of 3 snapshots present.

## Findings filed (deferred-items.md)

| ID | Finding |
|----|---------|
| DEF-07-13-01 | The route script's `modify` rewrote every DJ tag. RESOLVED by `-W` (998625b). Open hazard: `beet update` / `beet write` over `DJ/` |
| DEF-07-13-02 | A targeted Created body that includes the new top-level folder materialised `DJ/` (observation; bears on DEF-07-12-11) |
| DEF-07-13-03 | P08 has no disc tag, so its tracks read 1..5 twice. This is source-tag quality, a job for Phase 9 normalisation and not for `beet write` |

## Deviations from Plan

- **[Operator decision, mid-plan] Route script fixed and plan amended before any import.** See
  item 1 above. Commits: 998625b (fix, RED 30 of 30 → GREEN 0 of 30), 641498a (amendment) and
  af40083 (record). D-04 pins unchanged.
- **[Rule 1] Criterion-3 comparator for as-is rows.** `crit3c.py` counts a tag absent from the file
  against beets' null default separately, instead of as a mismatch. It was driven on controls
  first, and the raw `crit3b` reading is kept on the record.
- **Jellyfin POST body included the folder path.** The body carried `/media/Music/DJ`, a final path,
  plus the 20 files. This is the shape the operator-approved post-07-12 remediation prepared for
  `CYRIL/`. It was still one POST, with no scan and no refresh. The helper also drops 07-12's
  user-less `GET /Items/<id>`, and the result was 0 [ERR] lines.
- **Process:** the plan's automated verifies word-split `$S`, so they must run under bash, not zsh.
  All three exit 0 under bash.

## Carried forward

- P07's and P08's staged copies remain in `02-review`, like the other seven imported albums
  (import.copy). DEF-07-12-04 applies: the UI has no hold state.
- `beet update` / `beet write` must never run over `DJ/` (DEF-07-13-01). The DB is the sole record
  of `dj`.
- MA fs-sync tasks are still disabled. The re-enable is owed at 07-15, and MA has seen none of the
  nine albums.
- P11's beets-flask session c811b63d is left dangling, PREVIEW_COMPLETED. It was read, not edited.

## Known Stubs

None.

## Self-Check: PASSED

- The artifact, ledger, deferred-items and this SUMMARY exist.
- Commits f349a2b, 036202d, 998625b, 641498a, af40083, f781323 and d0a4cd7 exist.
- Task 1, Task 2 and Task 3 automated verifies exit 0 (under bash, after d0a4cd7).
