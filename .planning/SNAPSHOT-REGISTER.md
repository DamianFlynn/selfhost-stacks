# Snapshot Register — project snapshots on `tank` and `fast`

**Created:** 2026-09-27 by plan 07-16 (D-19). **Measured:** 2026-09-27T14:07:16Z (listing) and
14:08:59Z (`written@` pairs), from atlantis (172.16.1.158) as real root. Evidence, verbatim:
`.planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-16-prune-decision.txt` § MEASURED STATE.

**07-16 gate outcome:** operator answered `hold` (2026-09-27T18:58:12Z). `PRUNE OUTCOME: NONE (hold)` —
no snapshot was released; a read-only re-list at 18:58:12Z returned the same 181 names (set
difference empty). The one ELIGIBLE row, `tank/media/Music@pre-phase5-chown`, is held.

## Purpose

Every ZFS snapshot this project creates is an undo point for a specific change. Before this
register, nine of them stood with no owner and no release condition (07-CONTEXT D-19), so nobody
could say which were still load-bearing. This file is the authority on what each project snapshot
protects and what event releases it. It lives at the project level, not inside a phase, because
snapshots outlive phases.

Notation: the destructive ZFS verbs are written bracketed — `zfs [d]estroy`, `zfs [r]ollback` —
everywhere in this file (CONVENTIONS §8). This file records decisions; it issues nothing.

## The eligibility rule (verbatim, D-19 as made mechanical by plan 07-16)

> A snapshot is ELIGIBLE for pruning iff (a) a strictly newer snapshot exists on the SAME dataset,
> (b) `zfs get -H -p -o value written@<older> <dataset>@<newer>` returns `0` — no byte changed
> between them, so the newer is byte-for-byte the same undo point — and (c) this register can NAME
> that newer snapshot as covering the older's undo, with the covered change identified.
> Otherwise it is NOT ELIGIBLE, with the failing clause named.

Standing interpretations, fixed here so they cannot be re-argued per snapshot:

1. **Clause (c) accepts only a cover that is itself a project row in this register** (an owner inside
   the music pipeline). A backup-series snapshot (`backup-*` / `inc-*`) can satisfy (b), but its
   lifetime is governed by `/usr/local/bin/backup-incremental.sh`, not by this register, so naming it
   as a cover would hand an undo to something that may rotate it away.
2. **Age is not a criterion.** `tank/downloads@pre-phase5` is the oldest-but-one and the most
   load-bearing.
3. **`tank/downloads@pre-phase5` is NOT ELIGIBLE by rule**, whatever `written@` says: it is
   operator-gated estate-wide (Phase 7 entry criterion E4, D-17, D-32).
4. **Snapshots owned outside the music pipeline are listed and never offered.**
5. **Eligibility is necessary, not sufficient.** Nothing is destroyed except through one
   `autonomous: false` operator gate naming exact snapshots (the 06-52 shape). No plan releases a
   snapshot on its own judgement. `zfs [r]ollback` is never an executor's to run.
6. **A cover inherits the undo it covers.** When an ELIGIBLE snapshot is released, its cover's row
   gains the covered undo, and the cover's own release must then account for it.

## Project snapshots

Sizes in bytes (`-p`). `used` = bytes unique to that snapshot (what `zfs [d]estroy` would free).
Pool `tank` avail at measurement: **5,957,403,611,856 B (5.42 TiB)**; `fast` avail 1.30 TiB.

| dataset | snapshot | creation (UTC) | used | owner (plan) | undo for | release condition | eligible? (reason) |
|---|---|---|---|---|---|---|---|
| tank/downloads | `@pre-project` | 2026-08-18T12:08:02Z | 469,216 | Phase 1, plan 01-02 (D-09 — taken in the same step as `tank/media/Music@pre-project`) | The whole of `tank/downloads` as it stood before this project wrote anything | none recorded — could not look further: searched `/usr/bin/grep -rnE '(releas\|destroy\|prune\|keep until\|must not be deleted)' .planning stacks/selfhosted/arrs/beets.md \| /usr/bin/grep -F 'downloads@pre-project'`, 1 hit (`03-VERIFICATION.md:65`, records it *kept* by Phase 3; states no release condition) | NOT ELIGIBLE — (b) fails: `written@pre-project` of the next newer (`@pre-chown`) = 469,216 |
| tank/downloads | `@pre-chown` | 2026-08-18T21:43:24Z | 469,216 | Phase 1, plan 01-08 (untouched-proof instrument for the library chown sweep) | Evidence baseline that the 01-08 library chown did not touch `tank/downloads` | none recorded — could not look further: same search with `/usr/bin/grep -F 'downloads@pre-chown'`, 1 hit (`03-VERIFICATION.md:65`, *kept*; no release condition) | NOT ELIGIBLE — (b) fails: `written@pre-chown` of `@pre-phase5` = 79,494,891,168 |
| tank/downloads | `@pre-phase5` | 2026-09-18T14:42:06Z | 862,048 | Phase 5, plan 05-01 | 05-07's 4,750 renames, 05-09's 751 tag writes and 05-10's 26,005 chowns — the only undo for all three | **operator-gated, estate-wide (E4, D-17) — not released by Phase 7** | NOT ELIGIBLE — by rule (interpretation 3). Also (b) fails: `written@pre-phase5` of `@pre-phase5-chown` = 108,257,144,512. **Never offered.** |
| tank/downloads | `@pre-phase5-chown` | 2026-09-19T20:42:02Z | 9,209,728 | Phase 5, plan 05-10 (`scripts/phase05-downloads-chown.sh`, fresh refusing baseline) | The 05-10 D-24 chown of `tank/downloads` to `568:568`; kept "deliberately — this run's evidence baselines" (05-10-SUMMARY:328). ⚠ Its name contains `pre-phase5` as a substring (05-REVIEW CR-01) | none recorded — could not look further: same search with `/usr/bin/grep -F 'downloads@pre-phase5-chown'`, 0 hits | NOT ELIGIBLE — (a) fails: no strictly newer snapshot on `tank/downloads` |
| tank/media/Music | `@pre-project` | 2026-08-18T12:08:01Z | 1,167,584 | Phase 1, plan 01-02 (D-09) | The library as it stood before this project wrote anything, including 01-08's ownership normalisation of 2,674 entries | none recorded — could not look further: same search with `/usr/bin/grep -F 'Music@pre-project'`, 1 hit (`03-VERIFICATION.md:65`, *kept*; no release condition) | NOT ELIGIBLE — (b) fails: `written@pre-project` of `@safe05-watch-t0` = 1,162,128 |
| tank/media/Music | `@safe05-watch-t0` | 2026-08-18T14:42:48Z | 87,296 | Phase 1, plan 01-06 (SAFE-05 watch baseline, T+0) | Baseline for the Jellyfin-writer freeze watch (01-06) | none recorded — could not look further: same search with `/usr/bin/grep -F '@safe05-watch-t0'`, 1 hit (`07-16-PLAN.md:17`, this plan's own must-have; no release condition) | NOT ELIGIBLE — (b) fails: `written@safe05-watch-t0` of `@pre-chown` = 87,296 |
| tank/media/Music | `@pre-chown` | 2026-08-18T21:29:38Z | 87,296 | Phase 1, plan 01-08 (the chown sweep's own verification baseline) | 01-08's chown of the library to `568:568` | none recorded — could not look further: same search with `/usr/bin/grep -F 'Music@pre-chown'`, 0 hits | NOT ELIGIBLE — (b) fails: `written@pre-chown` of `@pre-phase5-chown` = 1,243,968 |
| tank/media/Music | `@pre-phase5-chown` | 2026-09-19T20:42:02Z | **0** | Phase 5, plan 05-10 (library untouched-proof instrument, taken with `tank/downloads@pre-phase5-chown`) | Evidence baseline that 05-10's chown did not touch the library — 05-10 measured `zfs diff` = 0 lines (05-10-SUMMARY:306). There is no library change for it to undo | none recorded — could not look further: same search with `/usr/bin/grep -F 'Music@pre-phase5-chown'`, 0 hits | **ELIGIBLE** — (a) `@pre-06-41-conf04-reprobe` is strictly newer on the same dataset; (b) `written@pre-phase5-chown` of `tank/media/Music@pre-06-41-conf04-reprobe` = **0**; (c) covered by `@pre-06-41-conf04-reprobe` (a project row), covered change: none — the 05-10 chown wrote 0 bytes to the library, so the two points are byte-identical. **held (operator, 2026-09-27T18:58:12Z)** — the 07-16 gate was answered `hold`; nothing was released. Its cover remains `@pre-06-41-conf04-reprobe` (itself held by D-17, NOT ELIGIBLE). Re-offered only at a future operator gate, with `written@` re-measured there. |
| tank/media/Music | `@pre-06-41-conf04-reprobe` | 2026-09-24T08:05:13Z | 0 | Phase 6, plan 06-41 (taken in the same remote step as the mutation) | Round 5's three file-mtime touches under `tank/media/Music` (DEF-06-45-01). If `@pre-phase5-chown` is released it also inherits that row's (byte-identical) undo — interpretation 6 | **held by 07-11 — D-17 NOT FIRED: "(ii) STATE COVERED no (UNDO IMPORT left the taghistory entry; DEF-07-11-01) and (iii) the Task 2 answer was restore-then-rerun (file restore used); (i) and (iv) hold"; release condition DEF-06-52-01 unchanged** — release when Phase 7 Success Criterion 1 is SATISFIED (a new snapshot taken on the same dataset AND rollback exercised), by operator action | NOT ELIGIBLE — (b) fails: every newer snapshot has `written@pre-06-41-conf04-reprobe` ≥ 109,120 (the 06-41 mtime touches, first seen in `@backup-20260925`); nearest project cover `@pre-07-pilot` = 109,120. Not offered; stays held; DEF-06-45-01 / DEF-06-52-01 open |
| tank/media/Music | `@pre-07-pilot` | 2026-09-26T14:48:27Z | 0 | Phase 7, plan 07-09 (the pilot fence, taken with `fast/appdata/arrs@pre-07-pilot` ~1 s apart) | Every Phase 7 pilot write to the library: the nine landed albums, the E5 repair, P01/P09 and the P10 undo/re-run. Measured since: `written@pre-07-pilot` of `@inc-20260927-0015` = 2,636,000,928 | **MECHANICAL:** released when a newer project snapshot on `tank/media/Music` exists whose register row names it as covering the Phase 7 pilot's writes AND `written@pre-07-pilot` of that newer snapshot is `0` — in practice **Phase 9 batch 1's fence**. Until that event, held | NOT ELIGIBLE — (c) fails: no newer project row; the only newer snapshot is backup-owned (`@inc-20260927-0015`, and its `written@` is 2.6 GB anyway). Never offered in 07-16 |
| fast/appdata/arrs | `@pre-07-pilot` | 2026-09-26T14:48:28Z | 32,284,672 | Phase 7, plan 07-09 | beets `library.db` / `state.pickle` / config as they stood before the pilot. Used once already: 07-11's `state.pickle` file restore (DEF-07-11-01) | **MECHANICAL:** released when a newer project snapshot on `fast/appdata/arrs` exists whose register row names it as covering the Phase 7 pilot's writes AND `written@pre-07-pilot` of that newer snapshot is `0` — in practice **Phase 9 batch 1's fence** | NOT ELIGIBLE — (c) fails: no newer project row; `written@pre-07-pilot` of `@inc-20260927-0015` = 102,776,832. Never offered in 07-16 |

## Snapshots on project datasets owned OUTSIDE the music pipeline — listed, never offered

| dataset | snapshot(s) | creation (UTC) | used | owner | undo for / role | release condition | eligible? |
|---|---|---|---|---|---|---|---|
| tank/downloads/mybook-music-archive | `@copied-from-mybook-20260922` | 2026-09-22T06:29:53Z | 491,040 | MyBook ingest (operator session 2026-09-22, outside this project's plans) | Origin fence of the 1.28 T MyBook copy (07-CONTEXT:46) | none recorded — could not look further: same search with `/usr/bin/grep -F 'copied-from-mybook-20260922'`, 0 hits | owner outside the music pipeline — not offered |
| tank/downloads/mybook-music-archive | `@post-rescue-20260922` | 2026-09-22T07:05:24Z | 0 | MyBook ingest / hufflepuff rescue (outside) | State after the rescue pass | none recorded — could not look further: same search with `/usr/bin/grep -F 'post-rescue-20260922'`, 0 hits | owner outside the music pipeline — not offered |
| tank/downloads/mybook-music-archive | `@with-m4-20260922` | 2026-09-22T20:18:39Z | 20,858,288 | MyBook ingest, M4 DJ music added (outside) | State after the M4 DJ addition | none recorded — could not look further: same search with `/usr/bin/grep -F 'with-m4-20260922'`, 0 hits | owner outside the music pipeline — not offered |
| tank/media/Music, tank/downloads/mybook-music-archive, fast/appdata/arrs (and every other backed-up dataset) | the `backup-*` / `inc-*` series | 2026-09-22 → 2026-09-27 | see artifact | `/usr/local/bin/run-backup.sh` + `/usr/local/bin/backup-incremental.sh` (MyBook `backup` pool) | Incremental `zfs send -i` bases. ⚠ Destroying the newest snapshot common to both sides breaks the next incremental | governed by the backup scripts, not by this register | owner outside the music pipeline — not offered |

Other snapshots matching `pre-|safe0|copied-from` elsewhere on the pools, listed for completeness
and never offered: `tank/buzz@pre-landmine-20260925`, `tank/media/Photos@pre-takeout-20260918`,
`fast/appdata/immich/postgres@pre-v3-20260918`, `tank/backups/hufflepuff-scavenge@pre-mybook-wipe-20260922`
— none recorded in `.planning/` for three of the four (searched `/usr/bin/grep -rnF '<name>' .planning`,
0 hits; `pre-v3-20260918` has 1 hit, `.planning/analysis/STACK-MAP.md:463`, no release condition).
Their owners are operator sessions outside this project (Terraform landmine, Takeout import,
Immich v3 upgrade, hufflepuff scavenge).

File-level safety copies (e.g. under `/mnt/fast/safety/`) are not snapshots and are out of scope.

## How to add a row

Every plan that takes a fence snapshot adds its row here **in the same commit** as the artifact that
records the snapshot being taken: dataset, snapshot, creation (UTC), `used`, owner (plan), undo for,
a release condition that names a firing EVENT (never "later" or "when safe"), and its eligibility
computed by the rule above. A plan that proposes a release re-measures `written@` at the gate — the
eligibility column here is a record, not a licence. A missing value is written `none recorded —
could not look further: searched <exact command>, <n> hits`, never left blank (DEF-06-52-02,
CONVENTIONS §14).
