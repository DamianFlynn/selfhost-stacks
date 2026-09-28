---
phase: 07-pilot-12-albums-end-to-end
plan: 20
subsystem: music-pipeline / beets-flask deploy
tags: [beets, fetchart, preferred-media, deploy, backfill, check-beets-config, T-06-33]
status: complete
requires: ["07-19"]
provides:
  - "07-19 art/media config live: appdata config == repo 9b482632…, host == origin == workstation"
  - "check-beets-config.sh T-06-33 key-scoped to fetchart's four shipped-default redacted keys"
  - "NOW 117 (P10) cover.jpg 6d83625a… == the CAA front, recorded as album 1's artpath"
affects: ["07-21", "07-22", "07-23"]
tech-stack:
  added: []
  patterns:
    - "Plugin defaults derived at runtime from add_default_config on a bare confuse root, never pinned"
    - "Redaction diff by key with an explicit allowlist; values are classified, never printed"
key-files:
  modified:
    - scripts/check-beets-config.sh
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-20-deploy-backfill.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/artifacts/07-pilot-ledger.txt
    - .planning/phases/07-pilot-12-albums-end-to-end/deferred-items.md
decisions:
  - "Gate 2026-09-28T11:54:15Z: deploy-and-backfill (Recommended), accepting DEF-07-19-05 and DEF-07-19-04"
  - "Halt answer 2026-09-28T12:22:07Z: 'Fix check, resume (Recommended)'. T-06-33 now passes a difference only on fetchart's four allowlisted keys at empty or the installed default"
  - "The T-06-33 allowlist is a literal (policy). The defaults are measured from the installed plugin on every run"
metrics:
  completed: 2026-09-28
  tasks: "2 of 2"
  duration: "~1h20m (11:14Z pre-gate to 12:33Z), including the halt"
---

# Phase 7 Plan 20: deploy the art/media config and backfill NOW 117's cover (Summary)

The 07-19 config (`fetchart` from the Cover Art Archive, `art_filename: cover`, and
`preferred.media: [Digital Media, CD]`) is live in beets-flask. NOW 117 now has its own
`cover.jpg`: one scoped fetchart call wrote it, and it is byte-equal to the Cover Art Archive front.
The first deploy halted on a false red in `check-beets-config.sh` T-06-33. The check was narrowed,
self-tested RED then GREEN, and the deploy and backfill completed.

## What happened

| Step | Reading |
|------|---------|
| Gate | `DISPOSITION: deploy-and-backfill` (11:54:15Z) |
| B1–B8 (first run) | push, host pull, safety copy of the old config (adf838dd…), install 760 568:568 (9b482632… == repo), beets-flask recreated alone, mounts correct, DB/state unchanged |
| B9 (first run) | RC=1 on T-06-33 alone, with every art/media assertion PASS. The writer was stopped: `STOP STATE 07-20-DEPLOY-FAIL`, DEF-07-20-01 |
| Halt answer | "Fix check, resume (Recommended)" (12:22:07Z) |
| Fix | 58e2d3d. Self-test 15 → 20: RED 1 of 20 under the old semantics, then GREEN 20/20 (16 red). Preflight on real throwaway dumps: rc 0 |
| B5'–B8' | host == origin == workstation at 5b8ee93. beets-flask recreated alone, ready in 15 s, inboxes exactly {02-review, 03-asis}. DB/state unchanged |
| B9' | `check-beets-config.sh` RC=0, FAILURES 0. T-06-33 `plugin-defaults-only [fanarttv_key=empty google_engine=default google_key=empty lastfm_key=empty]` |
| B10 | `SERVER LOADS FETCHART: yes`: loaded {fetchart, musicbrainz}, import_stages ['fetch_art'] |
| B11 | `vendored files match (4)`. D-04 pins unchanged (invocation-shaped 17, exempt 12, doc 2). The only red is D-28 (see Deviations) |
| C | pre-count 1. One `fetchart mb_albumid:b057dee8…`, rc 0, "found album art". `BACKFILL: PASS` |

## Backfill proof (artifact § C)

- `cover.jpg`: 9,041,762 bytes, JPEG 3540×3540, 568:568, sha256 `6d83625a…64e8`. That equals the CAA
  `/front` for the release, fetched independently.
- The 50-FLAC manifest (size, sha256, mtime) is byte-equal before and after, so there was no embed
  and no tag write.
- The `items` dump is sha-equal. The `albums` dump differs in exactly one cell: album 1 `artpath`,
  NULL → `Various Artists/Now That’s What I Call Music! 117/cover.jpg`.
- state.pickle is unchanged. library.db went from 8f5994b8… to 131255fc…, and the safety copy is at
  `/mnt/fast/safety/phase07/0720/library.db.pre-backfill`.
- Library `.nfo` is 91 and non-568 entries are 0. `.jpg` went from 88 to 89, attributable via
  artpath (DEF-07-19-04). `check-music-import.sh` exit 0.

## The T-06-33 fix (58e2d3d)

`assert_redaction_noop` is pure over two dump files and a defaults file.

- Byte-identical dumps PASS, as before.
- Otherwise it removes the four allowlisted fetchart keys from both dumps. What remains must be
  identical, or the result is RED.
- Each allowlisted key that differs must read `REDACTED` on the redacted side. Its unredacted value
  must be empty or equal to the installed plugin's default, or the result is RED.
- Unreadable input, a key missing on one side, and a mismatched redacted set are all UNKNOWN.

The live run derives the defaults inside the container from each fetchart source's
`add_default_config`, on a bare `confuse.RootView([])`. The real config is never read, and no beets
command runs for it. Values are only classified (empty / default / NON-DEFAULT). A difference
elsewhere is reported by top-level section name and line count only. Values stay out of argv.

## Deviations from Plan

**1. [Rule 1/3 - Bug, blocking] T-06-33 went red from plugin defaults, not a credential.**
- Found during: Task 2 step B9 (first run). The plan's failure path was taken: the writer was
  stopped and the plan halted.
- Fix: this was operator-approved, not auto-applied ("Fix check, resume"). T-06-33 is now key-scoped,
  as described above.
- Files: `scripts/check-beets-config.sh`. `ST_PLANNED_CASES` was re-pinned from 15 to 20 in the same
  commit (CONVENTIONS §5). No D-04 pin moved.
- Commit: 58e2d3d.

**2. [Scope] B11 accepted one pre-existing red the plan text did not name.**
- The consumers audit exits 1 on D-28, because the `Benson Boone/American Heart [093624834588]` pin is
  stale.
- It pins P04's dir, which 07-18 removed on purpose. A9 recorded it before any write, and G5 of the
  approved gate said it would remain.
- It is owned by 07-22 and was left untouched. The plan's "only CONF-04 exit 3" wording predates
  07-18.

**3. [Minor] Commands adjusted to the image, same intent.**
- `beet` is not on the PATH for `docker exec`, so the one invocation used `/venv/bin/beet`.
- The B10 read's first attempt called `load_plugins(names)`. In 2.12.0 it takes no arguments, so
  it raised TypeError, and the read was re-run with no arguments. Nothing was written.
- The library.db safety copy was taken on LXC 100, where `/mnt/fast/safety` lives, as B3 was.

## Known Stubs

None.

## Threat Flags

None. The only new remote read is a `${PY_BIN} -c` exec, the same shape as arm 1. It imports
`beetsplug.fetchart` and reads no config and no library.

## Estate at close

- beets-flask is RUNNING (StartedAt 12:28:51Z) with the new config, and 02-review holds 8 entries,
  untouched.
- Jellyfin and MA have not been written to. That is 07-21 and 07-22's work, and 07-21 now has
  P10's `cover.jpg` to hand to Jellyfin.

## Self-Check: PASSED

- Commits exist: 6ed1d90, eb794b5, e92720e, 58e2d3d, 5b8ee93, 0cfda7d.
- The artifact carries `OPERATOR ANSWER`, `DISPOSITION: deploy-and-backfill`,
  `POST-DEPLOY CHECK: PASS`, `SERVER LOADS FETCHART: yes`, `vendored files match (4)`,
  `DEPLOY: PASS (`, and `BACKFILL: PASS (cover.jpg `. It has 0 unbracketed forbidden tokens.
- `bash scripts/check-beets-config.sh --self-test`: 20/20.
