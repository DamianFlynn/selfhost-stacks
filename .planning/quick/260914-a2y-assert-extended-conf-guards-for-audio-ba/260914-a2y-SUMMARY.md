---
phase: quick/260914-a2y
plan: 01
subsystem: health-check
tags: [health-check, sabnzbd, audio.bash, destructive-guard, fail-closed]
requires:
  - scripts/quick-health-check.sh (the drift block's idiom and the REMOTE_TIMEOUT contract)
  - sabnzbd container /config/extended.conf (read-only, via docker exec)
provides:
  - a fail-closed assertion on the two extended.conf values that disarm audio.bash's two `rm -rf` branches
affects:
  - scripts/quick-health-check.sh
tech-stack:
  added: []
  patterns:
    - "remote-side matching, label-only return: assert values in a secrets-bearing file without copying it into a public repo"
    - "overrides that can only make a block redder (DRIFT_APPDATA_ROOT precedent)"
key-files:
  created:
    - .planning/quick/260914-a2y-assert-extended-conf-guards-for-audio-ba/artifacts/260914-a2y-negative-controls.txt
  modified:
    - scripts/quick-health-check.sh
decisions:
  - "Asserted the values remote-side rather than vendoring extended.conf — the repo is public and the file carries five API-key fields"
  - "Widened the review's ConversionFormat=FLAC assertion to {FLAC, OPUS}: FLAC-only would false-red a correct OPUS estate"
  - "Decoded the could-not-look causes inside the empty-output branch, preserving the house S1 order without collapsing four causes into one verdict"
  - "ReplaygainTagging deliberately out of scope — it gates a tag writer, not an rm -rf"
metrics:
  duration: ~20 minutes
  completed: 2026-09-14
requirements: [CR-01, WR-01]
---

# Quick Task 260914-a2y: Assert extended.conf Guards for audio.bash Summary

Closed code-review findings CR-01 (Critical) and WR-01 by adding a fifth fatal block to
`scripts/quick-health-check.sh` that asserts, on every routine run, the two `/config/extended.conf`
values that are the only thing disarming the two `rm -rf "$1"/*` branches in `audio.bash`.

## What Was Wrong

Phase 4 stripped the `beet` call out of `audio.bash`. `beets()` decides success by touching a
sentinel and then looking for audio files *newer* than it — and the stripped call was the only
writer that could ever produce one. So `SUCCESS: Matched with beets!` at `:286` is **structurally
unreachable**, and the `else` at `:287` runs on every music job. That `else` contains
`rm -rf "$1"/*` at `:290`, gated only by `requireBeetsMatch`. `conversion()` has the same shape
(WR-01): every `ConversionFormat` outside `{FLAC, OPUS}` reaches a second `rm -rf` at `:237`.

Both gates live in one host file that is not vendored, not in the D-13 drift set, and was asserted
nowhere. One edit to it — or any upstream restore — deletes every completed music download, against
content the project calls irreplaceable, with no `beet undo`.

## What Changed

One file, three edits, one commit:

- **`EXTCONF_HOST` / `EXTCONF_PATH`** override constants, following the `DRIFT_APPDATA_ROOT`
  precedent: any non-default value forces `EXIT_CODE=1` regardless of what the comparison finds.
  There is no success-producing override and no skip sentinel.
- **The assertion block**, inserted after the vendored-drift block. Reads the file via
  `docker exec sabnzbd`, matches **remote-side**, returns **two label lines only**. Distinct remote
  exit codes (3 = container absent, 4 = unreadable path, 6 = empty read, 124 = bound expiry) so
  every "could not look" gets its own named verdict.
- **The sixth `EXIT-CODE BEHAVIOUR CHANGED` notice** and **the tail fatal-block enumeration**,
  updated in the same commit.

## Deviations from Plan

### [Rule 2 - Missing critical functionality] The empty-output branch had to decode its own causes

- **Found during:** Task 1, confirmed by control 3 in Task 2.
- **Issue:** The plan specified the house S1 branch order (empty output first, deferring only to
  124) *and* a distinct UNKNOWN for remote exit 4. Those two requirements collide: a failed `cat`
  returns exit 4 **with no output**, so a plain empty-output-first branch swallows it and controls
  3 and 4 would have printed the same verdict — the exact "could not look" conflation this block
  exists to prevent, just relocated.
- **Fix:** Kept the S1 order exactly, but put a `case` on the status *inside* the empty-output
  branch, so 3 / 4 / 6 / 0 / ssh-failure each name themselves. Control 3 prints "could not read
  … (remote exit 4)"; control 4 prints "the ssh … failed (exit 255)".
- **Files modified:** `scripts/quick-health-check.sh`
- **Not a plan error** — the plan asked for both properties and this is what satisfying both
  requires.

### [Rule 2 - Missing critical functionality] Short-answer guard counts non-empty lines, not labels

- **Issue:** The drift block counts its `repo=` lines, which means an unrecognised label lands in
  the short-answer branch and that block's own `*)` case can never fire.
- **Fix:** This block counts **non-empty** lines, so a wrong label is still two lines and does reach
  the `*)` branch that names it. Both are fail-closed; this one can say *which* of the two failed.
  Recorded in-band so nobody "aligns" it back to the drift block's shape.

### Departure from the review's own snippet (deliberate, was in the plan)

The review's fix asserts `ConversionFormat="FLAC"` only. That would be a **false red on a correct
OPUS estate**, because OPUS genuinely is handled at `audio.bash:226-234` and never reaches the
`rm -rf`. The asserted set is `{FLAC, OPUS}` — the values that are actually safe.

`ReplaygainTagging`, the third switch in the review's snippet, is deliberately **out of scope** and
says so in the block: it gates a tag *writer*, which is a correctness problem, not a
data-destruction one. Stated so the omission reads as a decision rather than an oversight.

## Proofs Executed, Not Asserted

All four failure branches were **driven**, under a `trap`, transcript at
`artifacts/260914-a2y-negative-controls.txt`:

| Control | Fixture / override | Result |
|---|---|---|
| 1 | `requireBeetsMatch="true"`, `ConversionFormat="FLAC"` | requireBeetsMatch RED naming the `rm -rf`; ConversionFormat **not** red; exit 1 |
| 1b | `requireBeetsMatch` absent entirely | `found=(absent)` — absence treated as failure, not a pass; exit 1 |
| 2 | `ConversionFormat="MP3"`, `requireBeetsMatch="false" # comment` | ConversionFormat RED citing WR-01; requireBeetsMatch **green despite its trailing comment**; exit 1 |
| 3 | `EXTCONF_PATH=/config/does-not-exist-a2y.conf` | exit-4 UNKNOWN, in words "could not look"; exit 1 |
| 4 | `EXTCONF_HOST=root@192.0.2.1` (RFC 5737) | exit-255 UNKNOWN naming the unreachable host; exit 1 |

**Per-switch independence is proven by the pair, not claimed.** Control 1 reds only A; control 2
reds only B. Each switch is observed in both verdicts. A single flag reddening the whole block
would have made those two controls look identical.

**The green switch was evaluated, not skipped** — a non-obvious inference worth recording. An `ok`
label prints nothing locally, so its absence looks exactly like "never looked at". The short-answer
guard is the positive evidence: it fires unless exactly two labels return, and it never fired.

**Trailing-comment tolerance was driven against the defect**, not merely coded around it. Control
2's valid `requireBeetsMatch="false"` carries a trailing comment and stayed green — the shape plan
04-12 measured an end-anchored pattern returning 0 against.

## Safety

- **The live `/config/extended.conf` was never mutated.** sha256
  `54c5433b…b49d` asserted at the open **and** close of Task 2, identical. All fixtures went to the
  container's `/tmp`, never `/config`. Cleanup ran from a `trap` on EXIT/INT/TERM; post-cleanup
  fixture count 0.
- **Nothing from that file entered this public repo.** Matching is remote-side; only labels return.
  The optional `found=` text comes from greps anchored on the two switch names, so the five API-key
  fields cannot structurally reach the transcript — verified mechanically (count 0).
- **`audio.bash` is byte-unchanged**, so the D-13 drift block stays green (`✅ vendored files
  match (3)` on the final run).

## Verification

- `bash -n` passes; notice count 6 → **7** (the documented over-count: one notice quotes the phrase
  in its own body, so the count has always run one ahead of the number of notices).
- Executable-line greps (comment-stripped, this estate's most-repeated defect class): `EXTCONF_*`
  **13**, `docker exec sabnzbd` **2**, prohibited `grep -x` / end-anchored value patterns **0**.
- `bash scripts/quick-health-check.sh`, no overrides: **exit 0**, identifying line:
  `✅ extended.conf switches disarmed (2): requireBeetsMatch=false, ConversionFormat in {FLAC,OPUS}`

## Known Stubs

None.

## Notes for the Next Reader

`Traefik dashboard: ❌ Not accessible` appears on the green run and is **pre-existing and out of
scope** — one of the three sites documented in-file as WR-02, none of which touch `EXIT_CODE`. It
did not fail this run and was not introduced here.

STATE.md and ROADMAP.md were deliberately not touched: the orchestrator owns the Quick Tasks row,
and the `state.*` / `roadmap.*` SDK verbs corrupted unrelated lines three times during phase 4.
