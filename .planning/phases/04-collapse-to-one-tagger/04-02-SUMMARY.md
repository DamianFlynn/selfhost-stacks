---
phase: 04-collapse-to-one-tagger
plan: 02
subsystem: tooling
tags: [mutagen, wav, id3, riff, self-test, carry-in, def-03-09, d-23]

# Dependency graph
requires:
  - phase: 03-tagger-spike
    provides: "scripts/normalise-dj-tags.py (D-13's named normalisation tool) and DEF-03-09, the measured WAV defect"
provides:
  - "WAV read/write branch in normalise-dj-tags.py: mutagen.wave.WAVE + add_tags() + tags.setall/getall, ID3 only, dispatched by the single predicate is_wave()"
  - "info_iprd on WAV album NDJSON records whenever the RIFF LIST/INFO IPRD disagrees with the new album (dry run and apply); info_riff_unreadable when INFO cannot be parsed"
  - "the frame-set backstop now covers WAV: assert_frame_set_unchanged() parses the RIFF id3 chunk instead of returning silently at offset 0"
  - "--self-test: three synthetic WAV cases driven through the real read_tags()/write_tags()/build_record(), proven able to fail twice (RED commit, disabled predicate)"
affects: [phase-05, phase-07, djcc-01]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Python self-test in the spike03-wrtag-arms.sh shape: table of cases, ok/bad line per case, a reason under every bad, exit 0/1, and exit 2 for could-not-run (mutagen absent)"
    - "The thing under test does not grade itself: the self-test oracle reads frames straight through mutagen.wave, not through read_tags()"
    - "A write-fence override is a validated keyword (fence_root_or_raise), never a relaxed check: only SCRATCH_ROOT or a real normalise-dj-selftest-* dir directly under the temp dir"

key-files:
  created:
    - .planning/phases/04-collapse-to-one-tagger/04-02-SUMMARY.md
  modified:
    - scripts/normalise-dj-tags.py

key-decisions:
  - "WAV is written as ID3 only; RIFF LIST/INFO is never modified, and a stale IPRD is reported as info_iprd (D-23)"
  - "The WAV frame-set backstop uses the existing mutagen-independent ID3 parser at the id3 chunk offset, not WAVE(path).tags.keys(). mutagen's translated view would hide a TYER->TDRC rewrite"
  - "A WAV load keeps the on-disk ID3 major and sets load_v1=False, mirroring the MP3 branch. New WAV tags are v2.3 with UTF-16, the MP3 branch's choice"
  - "info_iprd is attached to album-field records only; IART (INFO artist) is not surfaced (out of D-23's scope, flagged below)"

patterns-established:
  - "Pre-commit smoke run from a sha-verified copy under /mnt/fast/scratch-04/<plan>/, then the recorded run from the pulled checkout"

requirements-completed: []  # Deliberately empty. The plan lists TAGR-04, but 04-02 is the D-23 carry-in and closes DEF-03-09, not TAGR-04 (the sabnzbd beets strip, other plans).
requirements-advanced: [TAGR-04]

# Metrics
duration: ~15min
completed: 2026-09-11
---

# Phase 4 Plan 02: WAV Write Path (DEF-03-09, D-23) Summary

**`normalise-dj-tags.py` now writes a WAV's album as ID3 through `mutagen.wave.WAVE` + `add_tags()` + `tags.setall()`, reads it back through `tags.getall()`, and leaves the RIFF `LIST/INFO` chunk untouched. When `IPRD` disagrees with the new album, the NDJSON record carries `info_iprd`. A three-case `--self-test` covers this. It passes in the beets image (exit 0) and fails with exit 1 both against the pre-fix write path and against a copy with the WAV predicate disabled.**

## Performance

- **Duration:** ~15 min. The start is after the orchestrator's `0989bc6` at 19:38:13Z, and the last recorded run is just after `ddbd3ff` at 19:51:00Z.
- **Completed:** 2026-09-11
- **Tasks:** 2 of 2
- **Files modified:** 1 (`scripts/normalise-dj-tags.py`, +507/−29 across both commits)

## Accomplishments

- DEF-03-09 is closed by behaviour. On the synthetic fixtures the tool writes the album to an untagged WAV, an ASCII-tagged WAV and a non-ASCII-tagged WAV. APIC, TDRC, TIT2, TPE1 and TRCK come back equal each time.
- The two-container disagreement is now recorded, not silent. The non-ASCII case carries a stale `IPRD="Old Album"`, the write leaves the INFO chunk byte-for-byte as it was, and `build_record()` emits `info_iprd: "Old Album"`.
- The MP3 backstop's WAV blind spot is closed. `assert_frame_set_unchanged()` used to read `RIFF` at offset 0 and return silently for every WAV. It now parses the `id3 ` chunk, and a driven control proves it trips.
- FLAC and MP3 are unchanged. The MP3 frame-writing loop is identical at both commits, and the only lines removed between `0f6b96e` and `ddbd3ff` are four function signatures, one docstring line, one `id3v2_frame_ids(path)` call (now `…(path, offset)`) and the `return {` that became `record = {`.

## Task Commits

1. **Task 1 (RED): add `--self-test` with three synthetic WAV cases.** `0f6b96e` (test)
2. **Task 2 (GREEN): WAV branch via `mutagen.wave.WAVE`, `info_iprd`, and the negative control.** `ddbd3ff` (fix)

**Plan metadata:** this SUMMARY's own commit. It is not pushed; the orchestrator owns docs pushes.

Both code commits were pushed to `origin/main`, and LXC 100 was fast-forwarded to each in turn. **Host HEAD is now `ddbd3ff`, which equals local.** The checkout's script sha256 is `610c5590dda547c0…`, equal to local. The host's two pre-existing untracked files were left as found.

## Transcripts

Every run used `docker run --rm --pull never --network none --entrypoint python3 -v <dir>:/w:ro lscr.io/linuxserver/beets:2.13.1-ls349 /w/normalise-dj-tags.py --self-test` on LXC 100. The image was confirmed resident first (`sha256:159e62e4d611…`), and it reports Python 3.12.14 and mutagen 1.48.1.

### 1. RED: host HEAD `0f6b96e`, mount `/mnt/fast/stacks/scripts`, exit 1

```
== normalise-dj-tags.py --self-test: the WAV write path (D-23, DEF-03-09) ==
   python 3.12.14, mutagen 1.48.1
bad  untagged-wav: no ID3 chunk at all: the write must create one holding exactly TALB
       reason: write_tags() raised TypeError: ['Self Test Album'] not a Frame instance
bad  ascii-wav: ASCII ID3: TALB replaced, APIC/TDRC/TIT2/TPE1/TRCK untouched, no info_iprd without INFO
       reason: read_tags() album before the write = None, expected 'Old Album'
       reason: write_tags() raised TypeError: ['Self Test Album'] not a Frame instance
bad  non-ascii-wav: non-ASCII TPE1 + stale RIFF IPRD: ID3 written, INFO untouched, info_iprd recorded
       reason: read_tags() album before the write = None, expected 'Old Album'
       reason: write_tags() raised TypeError: ['Self Test Album'] not a Frame instance
-- 3 cases, 3 failed --
selftest_rc=1
```

These are DEF-03-09's two measured symptoms, reproduced exactly: the `TypeError` on write, and `album=None` read from a tagged WAV. No fixture non-vacuity check fired, so the failures belong to the defect and not to a broken fixture. At the same commit, running the script **with no arguments exited 2** in the image (`error: the following arguments are required: target`).

### 2. GREEN: host HEAD `ddbd3ff`, mount `/mnt/fast/stacks/scripts`, exit 0

This is the plan's Task 2 `<verify>` command, verbatim.

```
== normalise-dj-tags.py --self-test: the WAV write path (D-23, DEF-03-09) ==
   python 3.12.14, mutagen 1.48.1
ok   untagged-wav: no ID3 chunk at all: the write must create one holding exactly TALB
ok   ascii-wav: ASCII ID3: TALB replaced, APIC/TDRC/TIT2/TPE1/TRCK untouched, no info_iprd without INFO
ok   non-ascii-wav: non-ASCII TPE1 + stale RIFF IPRD: ID3 written, INFO untouched, info_iprd recorded
-- 3 cases, 0 failed --
green_rc=0
```

### 3. Disabled predicate: a copy of host HEAD `ddbd3ff`, mount `/mnt/fast/scratch-04/02`, exit 1

The copy differs from the checkout by exactly one line, proven by `diff`: `subs_in_copy=1`, and `checkout_predicate_intact=1`.

```
613c613
<     return path.lower().endswith(".wav")
---
>     return False  # NEGATIVE CONTROL: WAV predicate disabled
```
```
bad  untagged-wav: ...
       reason: write_tags() raised TypeError: ['Self Test Album'] not a Frame instance
bad  ascii-wav: ...
       reason: read_tags() album before the write = None, expected 'Old Album'
       reason: write_tags() raised TypeError: ['Self Test Album'] not a Frame instance
bad  non-ascii-wav: ...
       reason: read_tags() album before the write = None, expected 'Old Album'
       reason: write_tags() raised TypeError: ['Self Test Album'] not a Frame instance
-- 3 cases, 3 failed --
disabled_rc=1
```

Afterwards, `test ! -e /mnt/fast/scratch-04/02` returned **0**. The parent `/mnt/fast/scratch-04`, which this plan created, was removed with `rmdir`, and its `test ! -e` also returned 0. The checkout sha was unchanged by the control.

### 4. Probe of the behaviour this plan added beyond the plan text

This was a one-off run in the image against a sha-verified pre-commit copy (`610c5590…`, equal to the committed blob). It is recorded here as evidence and is not a regression test.

```
v23 before: major 3 frames ['TALB', 'TIT2', 'TYER']
v23 read before: {'album': 'Old', 'artist': None}
v23 after:  major 3 frames ['TALB', 'TIT2', 'TYER']
v23 read after: {'album': 'New', 'artist': None}
backstop tripped: ID3v2 frame set changed beyond ['TALB']: added/changed={b'TCOM': 1} removed/changed={}
refused: /mnt/tank/media/Music
refused: /tmp
refused: /tmp/normalise-dj-selftest-evil        (a symlink to /etc)
refused: /tmp/normalise-dj-selftest-absent
default root: /mnt/tank/downloads/spike-03
tmp gone: True
probe_rc=0
```

## Acceptance Criteria

| Criterion | Result |
|---|---|
| T1: `py_compile` exits 0 | 0 |
| T1: `def read_riff_info` (non-comment) = 1 | 1 |
| T1: no arguments still exits 2, measured in the image | 2 |
| T1: in-image `--self-test` at the RED commit exits 1, with a `bad` line naming a WAV case | exit 1, 3 `bad` (`0f6b96e`) |
| T2: in-image `--self-test` at the pushed HEAD exits 0 with three `ok` | exit 0, 3 `ok` (`ddbd3ff`) |
| T2: the disabled-predicate copy exits 1, with `bad` for at least the ASCII case | exit 1, 3 `bad` |
| T2: `mutagen.wave.WAVE` (non-comment) ≥ 1; `"info_iprd"` ≥ 1 | 4; 3 |
| T2: `git diff 0f6b96e HEAD` removes no line in the MP3 frame-writing loop, and the `handle.setall(frame_id, …)` line is unchanged | none removed; the line is present once at both commits (HEAD line 847) |
| T2: `/mnt/fast/scratch-04/02` absent (`test ! -e` rc 0) | 0 |
| VALIDATION row D-23 | discharged. The row's command omits `--pull never --network none`; the plan's stricter form was used |

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 - Blocking] The write fence would have refused the self-test, making RED fail for the wrong reason**
- **Found during:** Task 1
- **Issue:** `write_tags()` calls `assert_inside_scratch(path)` as its first statement, and that fences to `SCRATCH_ROOT`. A self-test writing into `mkdtemp()` would raise at the fence, never reaching the easy-mode defect, so the RED run would have proven nothing about DEF-03-09.
- **Fix:** a keyword-only `fence_root=SCRATCH_ROOT` on `write_tags()`/`assert_inside_scratch()`, validated by `fence_root_or_raise()`. The validator accepts only `SCRATCH_ROOT`, or an existing `normalise-dj-selftest-*` directory whose `realpath` parent is the temp directory. The symlink, non-regular and `st_nlink` checks all still run, and the real run never passes the keyword. The probe shows four refusals, including a disguised symlink to `/etc`.
- **Commit:** `0f6b96e`

**2. [Rule 2 - Missing critical] The plan's WAV backstop instrument would have been blind to the defect class it guards**
- **Found during:** Task 2
- **Issue:** the plan says to capture the frame-id set via `WAVE(path).tags.keys()` before and after. That is mutagen's translated in-memory model: a default load turns `TYER` into `TDRC` on both sides, so a v2.3 WAV rewritten from `TYER` to `TDRC` on disk would pass. This is the failure the file's CONTRACT describes for MP3, and the reason `id3v2_frame_ids()` avoids mutagen.
- **Fix:** `offset=0` parameters on `id3v2_major()`, `id3v2_frame_ids()` and `assert_frame_set_unchanged()`. The default keeps MP3 byte-identical in behaviour. The WAV branch passes the `id3 ` chunk offset, relocated after the save, and an empty multiset for an untagged WAV. Failures still land in the existing `.failed` ledger with `stage: write`. Driven control: a smuggled `TCOM` tripped it.
- **Commit:** `ddbd3ff`

**3. [Rule 2 - Missing critical] The WAV load and save keep the on-disk ID3 major, with `load_v1=False`**
- **Found during:** Task 2
- **Issue:** the plan's `w = mutagen.wave.WAVE(path)` would use mutagen's defaults (`v2_version=4`, `load_v1=True`). The MP3 branch documents both as defaults that broaden the write. On a v2.3 WAV the first would change frames, and deviation 2's backstop would then fail the file loudly.
- **Fix:** `mutagen.wave.WAVE(path, v2_version=<on-disk major>, load_v1=False)` and `save(v2_version=<same>)`. Before relying on this, `WAVE.load`/`save` were read in mutagen 1.48.1 source and confirmed to forward these kwargs. New tags follow the MP3 branch (v2.3, UTF-16). Probe: a v2.3 WAV kept major 3 and `TYER`.
- **Commit:** `ddbd3ff`

**4. [Rule 2 - Missing critical] Two fail-closed refusals on the WAV write path**
- **Issue:** the MP3 branch skips its backstop when the tag is v2.2 or unparseable. That is the silent path the backstop exists to close.
- **Fix:** a WAV whose `id3 ` chunk will not parse as v2.3/v2.4 is refused before any write, and so is a WAV with two ID3 chunks (`wave_id3_offset()` raises). **Neither path is exercised by a fixture.** They are recorded here as untested.
- **Commit:** `ddbd3ff`

**5. A Task 1 docstring omission, fixed in Task 2**
- **Issue:** Task 1 added `mkdtemp()` + `shutil.rmtree()`, which made the CONTRACT line "no `rm` … no directory creation" false. Task 1 updated the tempfile hazard note but missed this line.
- **Fix:** it now reads "A TARGET run contains no `rm` … `--self-test` creates exactly one mkdtemp() directory of its own and removes it."
- **Commit:** `ddbd3ff`

### Interpretation choices (not rule fixes)

- `info_iprd` is attached **only to `field == "album"` records**. The records are per (file, field), and "differs from the new album" has no meaning on an artist record. `info_riff_unreadable` was added so that "could not look" at INFO is not read as "no IPRD".
- The plan asks for "byte-equal" frames and names `HashKey` + `.data` + `.text`. The oracle compares `(FrameID, encoding, text, mime, type, desc, data)` per HashKey across **every** frame, and not only the five. It also checks that no frame outside `TALB` appeared or vanished.
- A **pre-commit smoke run** from a sha-verified copy in `/mnt/fast/scratch-04/02/pre/` ran before the GREEN commit, so a broken GREEN was never committed. It was removed before the recorded runs.
- RED failed on all three cases, including untagged. The plan required at least the ASCII and non-ASCII cases.

**Total deviations:** 5 auto-fixed (1 blocking, 4 missing-critical, one of them a docstring correction). **Impact:** none widens what the tool writes. Deviations 2–4 make the WAV path fail closed where the plan's text would have failed open.

## Known Limitations / Follow-ups

- **IART is not surfaced.** Rule 3 can write `artist` to a WAV, which would leave a stale RIFF `IART` with no record. This is the same class of finding as `IPRD`, but D-23 names only `IPRD`. It is a candidate for whichever plan next points this tool at WAV content with a label token (today, none: all 268 estate WAVs are `Now!` content that rules 1 and 3 never fire on).
- **Proven on synthetic fixtures only.** No run was made over the real 134 `dj-mixes` WAVs (the real-run fence remains Phase 3's `SCRATCH_ROOT`). Their ID3 versions are not measured.
- **The self-test is manual.** No health check runs it.
- **Which container a dual-container reader prefers is not established.** The docstring says so explicitly, rather than claiming ffprobe precedence.

## Known Stubs

None. The stub grep matched only `placeholder_present` (lines 1175–1176), which is rule 3's existing VA-placeholder-artist logic and not a stub.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: fence-override | scripts/normalise-dj-tags.py | New `fence_root` keyword on the write fence (T-04-02-02's boundary). Mitigated: `fence_root_or_raise()` accepts only `SCRATCH_ROOT` or a real `normalise-dj-selftest-*` dir under the temp dir after `realpath`, and the real run never passes it. Four refusals are proven in the probe |

No network endpoint, auth path or schema change was introduced. The self-test runs `--network none`, `:ro`, `--pull never`.

## Issues Encountered

- `py_compile` wrote `scripts/__pycache__/normalise-dj-tags.cpython-314.pyc` locally, in a pre-existing, gitignored directory. Only that one file was deleted, and the directory and its other `.pyc` were left alone.
- The first residency ssh returned rc 2 only because `ls` of the not-yet-created scratch path failed. The image inspect itself returned rc 0.

## Self-Check: PASSED

- `scripts/normalise-dj-tags.py` exists at sha256 `610c5590dda547c0…`, the same locally and on the host.
- Commits `0f6b96e` and `ddbd3ff` exist in `git log`, and both are on `origin/main`.
- Host HEAD is `ddbd3ff`, and both `test ! -e` checks on the scratch dirs returned 0.
- STATE.md and ROADMAP.md are untouched, and no `gsd-sdk` state or roadmap verb was called.

---
*Phase: 04-collapse-to-one-tagger*
*Completed: 2026-09-11*
