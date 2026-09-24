---
phase: 06-tagger-configuration-and-dry-run
plan: 41
subsystem: infra
tags: [jellyfin, zfs, conf-04, mutation, snapshot-fence, mtime, library-media-updated]

requires:
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-40's before-state — the three pinned files' mtimes and content sha256, the proved three-path touch list, the .nfo/.lrc/.jpg hash manifest, and the assertion that tank/media/Music@pre-06-41-conf04-reprobe did not yet exist"
  - phase: 06-tagger-configuration-and-dry-run
    provides: "06-03's measured finding that a Default-mode refresh does not re-probe a file whose mtime has not changed, and its PASS 2 file-scope POST /Library/Media/Updated request shape, proved safe"
provides:
  - "The ZFS snapshot tank/media/Music@pre-06-41-conf04-reprobe — the single undo for the whole round"
  - "Three files under /mnt/tank/media/Music carrying a new mtime with byte-identical content"
  - "artifacts/06-41-conf04-reprobe-drive.txt, 693 lines — the snapshot name, the touch transcript, the zfs diff proof, the refresh request body, its HTTP status, and the LibraryMonitor log lines"
  - "POST_UTC: 1790237579 — the machine-readable moment of the refresh, which 06-42 subtracts from to prove its settle arithmetically"
  - "The measured fact that Jellyfin's LibraryMonitor fired on all three Audio items by full internal path, 60 s after the POST"
affects: [06-42, 06-43, 06-45, phase-07-entry-criterion-E6]

tech-stack:
  added: []
  patterns:
    - "Take the snapshot fence and the mutation in ONE remote step, in that order, so they cannot come apart — and list the snapshot back before touching anything"
    - "Probe a destructive-looking syscall with its own no-op form first (`touch -r f f`) so an EPERM is discovered before, not during, the mutation"
    - "Record the moment of an asynchronous trigger as an epoch NUMBER (`POST_UTC:`), so a later plan proves the mandatory wait by subtraction rather than inheriting a prose claim"
    - "Emit bash xtrace to a file and publish it as the COMMAND TRANSCRIPT, so 'no chmod/chown/zfs set was run' is asserted over commands actually executed rather than over the prose explaining why they were not"

key-files:
  created:
    - ".planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-41-conf04-reprobe-drive.txt"
  modified:
    - ".planning/ROADMAP.md"
    - ".planning/STATE.md"

key-decisions:
  - "The three FAIL verdicts the mutation run produced on (6b)/(6c)/(6d) were left STANDING in the artifact and annotated in band, rather than edited out, because they were a defect in this plan's own zfs-diff decoder and the honest record of an instrument that failed is worth more than a clean-looking file."
  - "The corrected assertions were recomputed against a RE-READ of `zfs diff` proved byte-identical to the already-captured block (`cmp -s`), so the one verbatim block in the artifact stays authoritative and the repair is a read rather than a second mutation."
  - "The two xtrace traces (mutation run and repair run) were CONCATENATED into the single COMMAND TRANSCRIPT block the plan allows, with no separator label. That satisfies 'nothing between the markers but command output' and makes the chmod/chown/zfs-set screen cover every command the task issued rather than only the first run's."
  - "The Jellyfin route was resolved fresh and NEITHER the plan's 192.168.90.25 nor 06-40's 192.168.90.17 was transcribed as a constant. docker returned 192.168.90.17 again; it is recorded as measured, with the contradiction stated in band."
  - "A GET /Library/VirtualFolders freeze re-read was added AFTER the refresh (not in the plan text) so T-06-41-02 has a direct measurement that the refresh did not re-arm a metadata saver, instead of resting only on the log scan and 06-42's later diff."

patterns-established:
  - "Pattern: when a derived value must survive a hostile encoding (zfs's \\0NNN escapes), decode with the primitive that already understands the format and add no pre-pass — a 'helpful' sed is the most likely source of the corruption"
  - "Pattern: a committed text artifact must be screened for NUL bytes, not only for credentials — a decoder overflow silently emitted three, and `file` reporting 'data' rather than 'text' was the only signal"

requirements-completed: []

duration: 22min
completed: 2026-09-24
---

# Phase 6 Plan 41: CONF-04 Re-probe Drive Summary

**The lever 06-03 named and never pulled has now been pulled: three mtimes moved inside a ZFS
snapshot fence taken in the same remote step, proved by `zfs diff` to be the only change on a
33.9 GB dataset and proved byte-identical in content, and Jellyfin was told about exactly those
three files through the one sanctioned endpoint — which returned 204 and named all three Audio
items in its own log 60 seconds later.**

## Performance

- **Duration:** ~22 min
- **Started:** 2026-09-24T08:03:00Z
- **Completed:** 2026-09-24T08:25:00Z
- **Tasks:** 3 of 3
- **Files modified:** 3 (1 artifact created, ROADMAP.md and STATE.md updated)

## Task 1 — the operator gate (`checkpoint:decision`)

The orchestrator presented the gate before this executor was spawned and before anything was
written. All six items the task required were shown with values read out of
`artifacts/06-40-conf04-reprobe-before.txt`: the three host paths with mtime/size/sha256, the
Section 9 (d) `TRUSTFALL = 0` exclusion proof together with the (e)/(e2) dual-instrument path
proof, the snapshot name and the verbatim one-line rollback, the four measured D-34/freeze option
values, the statement that the forbidden refresh mode is unreachable on every branch and that a
null result is a recorded negative, and the residual risk that 06-03's refreshes never actually
re-probed so the metadata-saver path was being exercised for the first time.

The checkpoint's own automated verify was run immediately before presenting: the snapshot count on
atlantis for `pre-06-41-conf04-reprobe` measured **`0`**. Nothing had been written.

**THE OPERATOR'S ANSWER, VERBATIM:** `proceed`

Task 1 writes no file; this section is its record.

## Accomplishments

- **The fence came first, and in the same remote step as the mutation.**
  `zfs snapshot tank/media/Music@pre-06-41-conf04-reprobe` returned 0 and was **listed back** and
  asserted equal to the name minted before any file was touched. It now exists beside the six
  pre-existing `tank/media/Music` snapshots. The one-line rollback is recorded verbatim three times
  in the artifact.
- **The touch list was re-derived on atlantis, not carried forward.** 06-40 proved it against a
  tree that had since had a snapshot taken, so all seven assertions were re-run: 3 lines, all
  `test -f`, all beginning with `/mnt/tank/media/Music/` by `index()==1` rather than a substring
  match, `TRUSTFALL` substring count **0**, `cmp -s` byte-identical on the reverse substitution
  including the U+2019, plus the independent `grep -qF` instrument that shares no code with the
  `awk` extractor. The source of truth was shipped over ssh STDIN from a **quoted heredoc** and its
  sha256 asserted `1ed695cf…` — equal to the workstation copy — **before** parsing.
- **The permission was probed before it was used.** `touch -r f f` sets a file's times to the values
  it already holds — the same `utimensat` step 4 needs, with no change. All three returned 0, stderr
  empty. Had any returned `EPERM` the recorded outcome was a negative result and a stop; no
  `zfs set aclmode=passthrough`, no `chmod`, no wider refresh.
- **Three mtimes moved; not one byte of audio did.** Each file's mtime is strictly newer than
  06-40 Section 5's value (2016-01-13 / 2016-02-22 / 2015-08-20 → all 2026-09-24T08:05:14Z) and each
  content sha256 is **identical** to 06-40 Section 9 (f). Sizes unchanged at 30,023,946 /
  29,357,615 / 23,920,625.
- **`zfs diff` is the round's strongest control and it came back clean.** Three `M` entries, zero
  non-`M`, **exactly three distinct paths and all three are the pinned ones**, and zero metadata,
  lyric or image sidecars and zero DO-NOT-RESCAN rows. On a 33.9 GB dataset shared by Jellyfin, Music
  Assistant and the operator, that is both halves of the safety claim from one source.
- **One write verb, 204, and Jellyfin's own log as the witness.** A single file-scope
  `POST /Library/Media/Updated` carrying three `{Path, UpdateType:"Modified"}` entries returned
  **204**. The body was built by `jq` from the derived list, so no path and no quote in it was
  hand-escaped. `LibraryMonitor` then named **all three Audio items by full internal path**,
  U+2019 included. No album-scope pass was issued — 06-03 already established file scope reaches the
  Audio items, and a narrower blast radius is strictly better.
- **The settle is a subtraction, not a sentence.** `POST_UTC: 1790237579` and
  `POST_UTC_ISO: 2026-09-24T08:12:59Z` were written immediately after the POST returned; the
  read-back began at 1790237714, **135 s** later, and the artifact asserts `>= 120` from those two
  numbers. 06-42 recomputes it from `POST_UTC` independently.
- **The early warning is clean and the freeze held.** Zero metadata-save, image-save or sidecar
  lines in the log window — recorded as the literal word `no`. And the four D-34 options plus
  `SaveLyricsWithMedia` were **re-read after the refresh** with `has($k)` (never jq's `//`, which
  treats `false` as empty): `PreferNonstandardArtistsTag` still `true`, the other four still `false`.
- **The forbidden mode was neither issued nor reachable.** The endpoint audit block shows exactly
  one line beginning with `POST`, naming `/Library/Media/Updated`; the only other two lines are
  `GET`s. Both prohibited scan endpoints are named descriptively only, so a grep for their literals
  across `artifacts/` stays a detector. `FullRefresh` count over the whole file: **0**.

## Task Commits

1. **Task 1: the operator gate** — no commit; it writes no file and its record is this summary.
2. **Task 2: snapshot and touch, proved by `zfs diff`** — `2410058` (docs)
3. **Task 3: the targeted file-scope refresh, 204, named in the log** — `4961271` (docs)

**Plan metadata:** see the final `docs(06-41)` commit (SUMMARY.md + STATE.md + ROADMAP.md).

## Files Created/Modified

- `.planning/phases/06-tagger-configuration-and-dry-run/artifacts/06-41-conf04-reprobe-drive.txt`
  — 693 lines. SECTION A (the fence, the re-proved touch list, the permission probe, the per-file
  before/after, the delimited `zfs diff`, STEP 6bis's corrected assertions, and the delimited command
  transcript) and SECTION B (the credential and route provenance, the delimited request body, the
  204, `POST_UTC`, the settle subtraction, the `LibraryMonitor` lines, the save scan, the
  post-refresh freeze re-read and the delimited endpoint audit).
- `.planning/ROADMAP.md` — 06-41 ticked; the Phase 6 progress cell moved 40/45 → 41/45 and gained a
  wave-19 paragraph. The pre-existing Notes cell was **appended to by hand**, not regenerated:
  `roadmap.update-plan-progress` has wiped a multi-thousand-character Notes cell on this repo before
  while `--stat` looked correct.
- `.planning/STATE.md` — a round-5 wave-19 block and the position line, **hand-edited**; the `state.*`
  verbs have corrupted this file's multi-line fields four times and 06-40 repaired the fourth.

## Decisions Made

See `key-decisions` in the frontmatter. The load-bearing one: the artifact keeps the three FAIL
verdicts its own defective decoder produced, annotated rather than deleted, and the corrected
verdicts sit beside them computed against a re-read proved byte-identical to the captured block.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The `zfs diff` path decoder corrupted every path, failing (6b)/(6c)/(6d)**

- **Found during:** Task 2, on reading the driver's own output — not by an assertion catching it,
  which is this phase's recurring lesson for the fifth round running.
- **Issue:** The driver decoded zfs's `\0NNN` escapes by piping each path through
  `sed 's/\\0/\\/g'` before `printf %b`. zfs writes a space as `\0040`; the sed rewrote that to
  `\40`, and `printf %b` then consumed a digit of the following filename — `CD 01-03` decoded as
  `CD 1-03`. Every decoded path therefore missed the pinned list (3 off-list) and every pinned path
  looked absent (3 absent), and the reported "6 distinct paths" was 3 mangled paths counted
  alongside the 3 correct ones. **The mutation and the captured `zfs diff` block were correct
  throughout; only the assertion over them was wrong.**
- **Fix:** `printf %b` already decodes the `\0nnn` form unaided; the sed was the entire bug and was
  removed. The corrected assertions were recomputed on atlantis in a **read-only** repair run that
  first re-read `zfs diff` and proved the re-read byte-identical to the already-captured block with
  `cmp -s`, so the one verbatim block in the artifact remains authoritative. All three now PASS.
- **Files modified:** the artifact (SECTION A, STEP 6bis and the in-band annotation)
- **Verification:** driven both ways — the buggy decoder was re-run locally on the captured bytes and
  reproduced `CD 1-03`; the corrected one returns `CD 01-03` and the U+2019 as the correct three
  UTF-8 bytes.
- **Committed in:** `2410058`

**2. [Rule 1 - Bug] The defective decoder emitted three NUL bytes into the report**

- **Found during:** Task 2, while assembling the artifact — `file` reported the assembled text as
  `data` rather than `text`, which was the only signal.
- **Issue:** The `\40` overflow in defect 1 produced a literal NUL byte in each of the three decoded
  paths. A NUL does not belong in a committed text artifact: it makes the file non-text, and several
  standard tools silently change behaviour on it.
- **Fix:** The defective decoder's three output lines are **deliberately not reproduced** in the
  artifact, with that omission and its reason stated in band; the correct decoding of the same three
  paths appears in STEP 6bis. The assembled file is asserted NUL-free (0 bytes removed by
  `tr -d '\000'`) and `file` reports `Unicode text, UTF-8 text`.
- **Files modified:** the artifact
- **Verification:** `wc -c` before and after `tr -d '\000'` are equal on the committed file.
- **Committed in:** `2410058`

**3. [Rule 2 - Missing critical verification] The Phase 1 freeze was re-read AFTER the refresh**

- **Found during:** Task 3 design
- **Issue:** T-06-41-02 is "Jellyfin writing sidecars into the library during the re-probe", and the
  plan's task 3 mitigations were the log scan (an early warning) and 06-42's later `zfs diff` (the
  proof). Neither directly answers "did the refresh re-arm a metadata saver", which is the state a
  later reader will want dated to this moment.
- **Fix:** Added a `GET /Library/VirtualFolders` after the refresh and asserted all five fields with
  `has($k)`. `PreferNonstandardArtistsTag` `true`; `UseCustomTagDelimiters`, `SaveLocalMetadata`,
  `EnableRealtimeMonitor`, `SaveLyricsWithMedia` all `false`. It is a GET, so the endpoint audit's
  "exactly one write verb" is unaffected.
- **Files modified:** the artifact (SECTION B)
- **Verification:** driven — all five PASS, recorded with their wanted values.
- **Committed in:** `4961271`

### Deliberate departures from the plan text

**4. The two xtrace traces were concatenated into the single COMMAND TRANSCRIPT block.** The plan
requires exactly one delimiter pair with nothing between the markers but command output. Task 2 ran
twice (the mutation, then the read-only assertion repair), so the two traces are concatenated with no
separator label. This satisfies the constraint literally and makes the `chmod`/`chown`/`zfs set`/
`zfs destroy` screen cover **every** command the task issued rather than only the first run's. The
concatenation is explained outside the block; the boundary is self-evident from the trace itself.

**5. The Jellyfin address in the plan's own context is wrong, again.** The prompt context states the
container is at 192.168.90.25 and that 06-40 measured 192.168.90.17. `docker inspect` returned
**192.168.90.17** at run time — 06-40's measurement, not the plan's number. Neither literal is
transcribed as a constant anywhere; the address is resolved fresh on every call and recorded as
measured, with the contradiction stated in band.

---

**Total deviations:** 3 auto-fixed (2× Rule 1, 1× Rule 2) + 2 recorded departures
**Impact on plan:** No scope change, no extra mutation. Both Rule 1 defects are in this plan's own
instruments and neither touched the estate — the `zfs diff` block they failed to parse was correct
from the first capture, and the repair that fixed the parsing is a read.

## Issues Encountered

**`grep` is a shell function in this session, and it silently matched nothing.** Several
pattern searches over the artifact returned empty while the content was demonstrably present. The
workstation shell sources a snapshot that shadows `grep`. Every screen reported in this summary was
re-run with `/usr/bin/grep` explicitly. The plan's `<automated>` verify blocks run under `bash -c`,
which does not inherit the function, and both passed. **A tool that answers "no matches" when it was
never really consulted is the exact shape of a false green** this phase exists to remove — worth
carrying forward for anyone screening artifacts from an interactive shell.

**Two of my own "is this byte present" tests were vacuous and had to be replaced.** `grep -c $'\000'`
and `awk 'index($0,"\000")'` both reduce the needle to an empty string, which matches every line;
both reported NULs in files that had none. The honest instrument is a byte-count comparison across
`tr -d '\000'`. This is the self-referential-measurement hazard (`DEF-06-39-06`) in a new costume —
the fifth consecutive round for that class.

**`ls` under `pipefail` returns 2 on an empty glob**, which briefly looked like a failed cleanup. Re-run
with `find`, which returns 0 on an empty result: `/tmp/06-41*` is empty on **both** atlantis and
LXC 100, every scratch file deleted and verified absent.

## User Setup Required

None. The operator gate is discharged (`proceed`). **The snapshot
`tank/media/Music@pre-06-41-conf04-reprobe` is now standing and is the only undo for this round —
it must not be destroyed before 06-43 records its branch.**

## Known Stubs

None. Every section of the artifact is measured.

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema was introduced. The one
write verb is the endpoint 06-03 already issued and proved safe, at a strictly narrower scope.

## What this does and does not establish

Stated plainly because the next plan depends on the distinction. It establishes that the refresh
**started** and reached the three Audio items themselves — the thing whose absence would make a null
result in 06-42 uninterpretable, since an unmoved census is consistent both with "never started" and
with "started and found nothing". It does **not** establish that the prober re-read the `ARTISTS`
tag, and it does **not** establish that any `ArtistItems` row moved. That is 06-42's measurement, and
a null result there is a legitimate recorded negative — not an argument for a wider refresh.

## Self-Check: PASSED

Verified after writing this summary, against disk and `git log`, not against the text above:

- `artifacts/06-41-conf04-reprobe-drive.txt` — FOUND, 693 lines, NUL-free, `Unicode text, UTF-8 text`
- `06-41-SUMMARY.md` — FOUND
- Commits `2410058`, `4961271` — both FOUND
- Both of the plan's `<automated>` verify blocks re-run against the **complete** file — both `OK`
- Delimiter pairs: `ZFS DIFF`, `COMMAND TRANSCRIPT`, `REFRESH REQUEST`, `ENDPOINT AUDIT` — **1 each**
- Forbidden-mode screen over the whole artifact: `FullRefresh` **0**, "replace all metadata" **0**
- Credential screen: no `MediaBrowser Token` value, no `X-Emby-Token`, no `Authorization:` header, no
  `Bearer`, no `JELLYFIN_API_KEY=`, no MA password. The credential file's MODE (`600 root`) is
  recorded; its contents are not
- `tank/media/Music@pre-06-41-conf04-reprobe` — PRESENT on atlantis, listed back by name
- `/tmp/06-41*` on atlantis and on LXC 100 — **0 files each**
