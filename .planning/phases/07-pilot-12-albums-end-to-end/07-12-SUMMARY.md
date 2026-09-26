---
phase: 07-pilot-12-albums-end-to-end
plan: 12
subsystem: music-tagging / the remaining bucket-A albums through beets-flask 02-review
tags: [bucket-a, d-29, d-20, aunique, state-pickle, jellyfin-targeted-update, ma-barrier, phase7]
requires: [07-10, 07-11]
provides: ["STATE 07-12-PARTIAL — 7 albums / 177 items landed and read (P10 P02 P03 P04 P05 P06 P12); P09 and P01 held", "the %aunique{} reading of the real library for 07-15 (one firing, catalognum; move -p 0 re-path lines; numeric fallback one empty catalognum away)", "DEF-07-12-06 — partial state.pickle surgery procedure", "DEF-07-12-07 — candidate search is the DuplicateException retry route"]
affects: [07-13, 07-15, 07-17]
key-files:
  created:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-12-nine-imports.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/07-12-SUMMARY.md
  modified:
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Operator: \"Raise Authelia buffers (Recommended)\" — server.buffers read/write 4096 -> 16384 after the inbox page hit HTTP 431 (DEF-07-12-03; appdata, not in git)"
  - "Operator: \"Undo P01 + P09, keep rest\" — P02 kept on c0df8104 as imported-other"
  - "Operator authorisation (verbatim): \"i am explicitly authorising the work needed to get beets and the music system implemented, including live files like state.pickle\" — used for the partial state.pickle surgery"
  - "Operator: P04 \"imported c33163f3\" — via the candidate search, duplicate action Keep both"
requirements-completed: [IMPT-01, QUAL-02, QUAL-03, CONS-04]
metrics:
  completed: 2026-09-26
  runs: 1 (four continuation agents)
  duration: "21:09Z – 23:31Z (includes the operator gates, the 431 fix, the undo/surgery and the P04 re-decision)"
---

# Phase 7 Plan 12: remaining bucket-A albums imported and verified — Summary

**Six more albums landed through `02-review` and each was read on every per-album criterion. The
library now holds seven albums and 177 items: P10, P02, P03, P04, P05, P06 and P12. Two albums
are held: P09 is still staged, and P01 is unstaged. Criteria 3, 7 and 8 pass on all six.
Criterion 4 passes on five and has an instrument finding on P04. Jellyfin's half passes on five
and fails on P06. Music Assistant has seen none of the seven.**

## What the operator needs to know

1. **The 431 / Authelia fix (DEF-07-12-03).** The first UI attempt returned HTTP 431. The inbox
   page puts every staged folder's hash and path into one GET query string, and at 10 folders that
   overflowed Authelia's 4096 B read buffer. With your approval ("Raise Authelia buffers
   (Recommended)"), `server.buffers` read/write went from 4096 to 16384. The backup is
   `configuration.yml.bak-20260926-431`. Authelia was restarted healthy at 21:54:22Z. The file is in
   appdata and **not in git**. The query string grows with the inbox, so the new ceiling can be
   reached again.
2. **The UI-selected-card hazard (DEF-07-12-04 / DEF-07-12-05).** The candidate agreed at the
   gate reached beets on only **4 of the 6** albums that had one (P03, P05, P06, P12).
   - P02 landed on `c0df8104` (rank 2 of an exact three-way tie), not the agreed `e4fdb1dc`. It
     was kept as `imported-other`. It passes D-29 exactly as rank 1 would have.
   - P04's first request carried the default card `e4fdb1dc`, not the agreed `c33163f3`.
   - **P01 and P09 were imported against `hold`.** The beets-flask UI has no hold state, so every
     staged folder is one click away from import. Both were then **fully undone**: UNDO IMPORT
     (TREE 32→0 and 100→0, DB rows gone), plus state surgery for the incremental state.
3. **The state surgery procedure (DEF-07-12-06).** This is a new procedure, not 07-11's fence-copy
   restore. That restore would have erased the taghistory of the six albums that stayed. Instead,
   exactly two taghistory entries (P01, P09) were removed from the live `state.pickle`:
   - decode `/tmp` copies;
   - assert live == fence ∪ keep ∪ remove;
   - build the new file with beets' own writer (protocol 4) and prove new == fence ∪ keep;
   - stop beets-flask and `cp -p` a backup;
   - `cp` the new file onto the live one (owner, mode and inode kept);
   - start beets-flask, check the keys, re-decode.

   The sha went `585c5e56… → 9f2d1ba7…`. The backup is at
   `/mnt/fast/safety/phase07/0712-state/state.pickle.pre-0712-surgery`. It was done under your
   authorisation quoted above.
4. **P04's %aunique{} outcome.** The first import failed with DuplicateException. The re-decision
   used the folder page's candidate search, which recomputed the duplicate flags (DEF-07-12-07),
   and "Keep both". P04 landed at **`Benson Boone/American Heart [093624834588]/`**, with the
   disambiguator `catalognum`. That is exactly § E's re-measured prediction for `c33163f3`. P02
   kept `Benson Boone/American Heart/` untouched: same 10 files, and mtime/ctime unchanged from its
   21:58Z import. The frozen oracle's label suffix never fires, because MusicBrainz gives both
   releases the same label. A compliant `move -p` over a copy of the real library printed
   **0 re-path lines**. The control shows the landmine for 07-15: blank P04's catalognum and
   *both* albums fall back to the non-reproducible `[2]` / `[9]` album-id suffixes.

## Per-album readings

| P-ID | Landed at `/media/Music/…` | Release (rank) | C3 | C4 | C7 | C8 | Jellyfin |
|------|---------------------------|----------------|----|----|----|----|----------|
| P02 | Benson Boone/American Heart/ (10 FLAC) | c0df8104 (2 of a tie; imported-other) | PASS | PASS | PASS | PASS | PASS |
| P03 | Benson Boone/Fireworks & Rollerblades/ (15 FLAC) | ef528afc (1) | PASS | PASS | PASS | PASS | PASS |
| P04 | Benson Boone/American Heart [093624834588]/ (10 MP3) | c33163f3 (3 of a tie; agreed) | PASS | **FINDING** (DEF-07-12-09) | PASS | PASS | PASS |
| P05 | Various Artists/NOW That’s What I Call Music! 121/ (44 MP3) | 0a74adf8 (1) | PASS | PASS | PASS | PASS | PASS: one album, AlbumArtist Various Artists, 44 children |
| P06 | CYRIL/Stumblin’ In (LUNAX remix) (extended mix)/ (1 MP3, album not singleton) | 39fb4603 (1) | PASS | PASS | PASS | PASS | **FAIL** (DEF-07-12-11) |
| P12 | Various Artists/Now That’s What I Call Music! 116/ (47 MP3, 23+24) | 581244e0 (1, GB) | PASS | PASS | PASS | PASS | PASS |

- **Criterion 3:** 0 mismatches over 889 comparisons. The comparator was driven on a FLAC control
  and an MP3 control first. All 127 files are `568:568`, and there are 0 EPERM-class lines.
- **Criterion 4:** 0 fields dropped on every album.
  - P04's exit 1 comes from one file (track 01). Its audio frames are byte-identical, its PCM md5 is
    equal, and it lost 0 tags. The join key hashes the encoded stream, and on this MP3 the key
    reaches into the rewritten ID3v1 because the file's last frame is truncated. That is an
    instrument defect, recorded as a finding and not as a pass.
- **Criterion 7:** `check-music-import.sh` exited 0 on 177 items, with 0 findings and 0 UNKNOWN.
- **Criterion 8:** every source is unchanged, including held P09 and P01, and every staged copy
  equals its manifest.
- **Oracle:** 127 of 127 file names re-render from their DB rows, so TEMPLATE-DEFECT is 0. Every
  divergence is MATCH-CHANGED-TAG, except P06, which diverges on route (DEF-07-12-01).
- **Jellyfin:** one targeted `Created` POST of 127 paths returned 204. There was no scan and no
  FullRefresh-class call. MetadataSavers is still `[]`, and no sidecar appeared (.nfo still 91,
  0 new entries).
- **ADDED ORDER: FAIL.** P04 landed last and P06 landed before P05 (DEF-07-12-12). The P02<P04
  premise the %aunique{} reading needs is met.
- **Barrier:** VERIFIED at 23:14:45Z and 23:30:29Z. MA counts are 70 / 1,244 / 66, the baseline.
  The fence holds, with 3 of 3 snapshots present.

## Findings filed (deferred-items.md)

| ID | Finding |
|----|---------|
| DEF-07-12-01 | P06 has no singleton route through the D-20 front end, so it lands as an album |
| DEF-07-12-02 | P01's candidate set drifted between two previews of identical files |
| DEF-07-12-03 | The inbox query string overflowed Authelia's read buffer (431); buffers raised to 16384 |
| DEF-07-12-04 | The UI has no hold state: P01 and P09 were imported against hold, then fully undone |
| DEF-07-12-05 | An exact tie is shown as near-identical cards: P02 and P04 requests did not carry the agreed release |
| DEF-07-12-06 | New procedure: partial state.pickle surgery |
| DEF-07-12-07 | DuplicateException is not clearable by retry; the candidate search is the route; only "Keep both" is safe |
| DEF-07-12-08 | P03 sits beside a pre-existing, untracked `Fireworks & Rollerblades (2024)/` from `@pre-07-pilot` |
| DEF-07-12-09 | The diff key is not tag-invariant on a truncated-final-frame MP3 with ID3v1 (P04 criterion 4) |
| DEF-07-12-10 | Junk country `PMEDIA` survives a match whose MB release has no country (P03) |
| DEF-07-12-11 | A targeted update does not materialise a new top-level artist directory (P06 is absent from Jellyfin) |
| DEF-07-12-12 | ADDED ORDER FAIL |

## Deviations from Plan

- **Imports did not follow the gate (process).** See items 2 and 3 above. P01 and P09 were
  imported against hold and undone. The plan's own undo route (07-11) was unsafe with six albums
  landed, so the partial state surgery was used, under the operator's verbatim authorisation.
- **[Rule 3] Authelia buffer raised mid-gate** (operator-approved). Without it the UI could not
  load the inbox.
- **[Rule 1] MP3-aware criterion-3 comparator.** 07-10's `crit3.py` knows only the FLAC tag names.
  `crit3b.py` adds the ID3 aliases (`MusicBrainz Album Id`, `album_artist`). It was driven on an
  MP3 control before use.
- **P04 re-decided outside the gate.** Its one `DISPOSITION P04:` row was written only after a live
  re-check that agreed with the answer.
- **Self-caused log noise.** The Jellyfin poll helper also issued a user-less `GET /Items/<id>`,
  which produced 55 read-only [ERR] lines in Jellyfin's log. GET only, no state change.
- **Not remedied, by the plan's own limits:** P06's Jellyfin absence (the plan allows one POST),
  P04's criterion-4 instrument defect (scripts are outside this plan's files), and P09 still being
  staged (the plan unstages only P01).

## Carried forward

- **P09 is still staged** in `_inbox/02-review` (100 files) and, per DEF-07-12-04, one click from
  import. It should be removed or deliberately kept before anyone next opens the inbox.
- P06 needs a decision on how Jellyfin learns about new artist directories (DEF-07-12-11) before
  07-15 reads Jellyfin and MA together.
- MA fs-sync tasks are still disabled. The re-enable is owed at 07-15.
- Two dangling beets-flask folder rows exist for the P01 path (`d2772a06…`, `8569f3f4…`). They were
  read and not edited.
- `beets.md` lessons for 07-17: DEF-07-11-01, DEF-07-12-04 to 07, and DEF-07-12-11.

## Known Stubs

None.

## Self-Check: PASSED

- Artifact, ledger, deferred-items and this SUMMARY exist.
- Commits f7da154, c83bcd2, c319725, 6262abc, c4676a2 and 8249ee9 exist.
- The plan's Task 1, Task 2 and Task 3 automated verifies exit 0 (run under bash after 8249ee9).
