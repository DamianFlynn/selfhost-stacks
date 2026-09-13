---
phase: 04-collapse-to-one-tagger
verified: 2026-09-13T13:00:00Z
status: gaps_found
score: 4/5 success criteria verified (1 OPEN, by the phase's own evidence file)
overrides_applied: 0
gaps:
  - truth: "The beets block is stripped from audio.bash, and a SABnzbd music job completes without invoking any tagger at all (ROADMAP Phase 4 success criterion 3 / TAGR-04)"
    status: partial
    reason: >
      The static half is verified: `grep -cE '^[[:space:]]*beet ' stacks/selfhosted/arrs/sabnzbd/audio.bash`
      = 0, and the vendored-file drift guard confirms the file matches the vendored copy. The
      behavioral half is explicitly OPEN in the phase's own evidence contract
      (04-D12-EVIDENCE.md § 6, single verdict line: "Verdict: OPEN"). Two real music jobs completed
      in the observation window (2026-09-13T12:17:59Z and 12:18:13Z) and produced clean side
      effects (0 library.blb/.bak/beets.log artefacts, 0 "SUCCESS: Matched with beets" lines,
      25/25 files byte-identical between snapshots, extended.conf unchanged) — but neither job has
      a valid PRE-HOOK snapshot: SABnzbd moves a finished job into complete/nzb/music/ and only
      then invokes the hook, so a watcher on the destination tree structurally cannot sample before
      the hook starts. Job A's snapshot was taken after its "Matching" line; job B's cannot be
      ordered against its own hook start (both resolve to the same wall-clock second in Audio.txt).
      Per 04-D12-EVIDENCE.md § 5 ("no valid PRE-HOOK snapshot" → OPEN, not PASS) and confirmed
      explicitly by 04-13-SUMMARY.md ("The phase is not closable, and /gsd-verify-work must treat
      criterion 3 as the open gap"), this is a real, acknowledged, unresolved item — not a SUMMARY
      overclaim to be caught, and not paperable-over as passing on the strength of the weaker
      side-effect evidence.
    artifacts:
      - path: ".planning/phases/04-collapse-to-one-tagger/04-D12-EVIDENCE.md"
        issue: "Section 6 (Result) records Verdict: OPEN, with the PRE-HOOK-snapshot mechanism explained in detail (lines 184-207)"
    missing:
      - "A watcher fix so a valid PRE-HOOK snapshot can be taken: either (a) snapshot the job in /downloads/incomplete/ before SABnzbd moves it to complete/nzb/music/, where bytes are final after unpack but the hook has not yet fired, or (b) key the PRE-HOOK snapshot on first sighting of the destination folder with no 2-second stability wait, accepting a snapshot taken mid-move may need to be retaken."
      - "One more real music job (organic, or operator-triggered via a Lidarr search) run after the watcher fix, producing a valid PRE-HOOK vs COMPLETION byte comparison per 04-D12-EVIDENCE.md § 1 item 4."
      - "04-D12-EVIDENCE.md § 6 updated with the new verdict line (PASS or FAIL), and stacks/selfhosted/arrs/beets.md's interim-status heading changed to a closure heading once the verdict is PASS."
---

# Phase 4: Collapse to One Tagger — Verification Report

**Phase Goal:** One tagger, one database, no idle container holding a rw mount — independently shippable
**Requirements:** TAGR-03, TAGR-04, TAGR-05
**Verified:** 2026-09-13T13:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Phase 4 Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Exactly one tagger definition exists in the repo; losing definitions deleted (not commented out); soulbeet gone, issue #306 closed | ✓ VERIFIED | `git ls-files stacks \| xargs grep -lE '^\s*image:\s*(lscr\.io/linuxserver/beets\|sentriz/wrtag\|ghcr\.io/terry90/soulbeet\|metasauce/beets-flask)'` → exactly `stacks/selfhosted/arrs/beets/beets.yaml`. `git ls-files \| grep -E 'soulbeet\|selfhosted/music/'` → empty (no tracked soulbeet/wrtag definitions; `stacks/selfhosted/music/` dir still exists on disk holding only untracked, gitignored `.env`/`.env.backup` — 04-05 explicitly ruled to leave it, so this is not a gap). `gh issue view 306 --json state,title` → `{"state":"CLOSED","title":"soulbeet: release it — the image no longer exists on GHCR"}`. Live census confirms `tagger definitions: 1` |
| 2 | Renovate no longer pins a retired tagger (including the wrtag `<0.30.0` rule); `renovate-config-validator` passes | ✓ VERIFIED | `grep -c 'sentriz/wrtag' renovate.json5` → 0 (the two remaining textual mentions of "wrtag" in renovate.json5, lines 428/457, are dated rule-description prose explaining *why* an allowedVersions ceiling is the wrong instrument, not a pin — confirmed in 04-13-SUMMARY sweep row 2). 04-13-SUMMARY records an independently re-run `renovate-config-validator --strict --no-global renovate.json5` → exit 0 ("Config validated successfully against 1 file(s)") on 2026-09-13, plus `check-renovate.sh` → exit 0, `Validator route: local`. The validator binary is not installed on this verification workstation (`npx renovate-config-validator` fails with "could not determine executable"), so this criterion is accepted on the SUMMARY's captured command transcript rather than independently re-run here; the underlying static fact (zero live wrtag pins) was independently re-confirmed |
| 3 | The beets block is stripped from `audio.bash`, and a SABnzbd music job completes without invoking any tagger at all | ✗ **OPEN (gap)** | Static half confirmed: `grep -cE '^[[:space:]]*beet ' audio.bash` → 0; vendored-file drift guard green. Behavioral half is explicitly **OPEN** per `04-D12-EVIDENCE.md` § 6 — two real jobs ran in-window with clean side effects, but neither has a valid PRE-HOOK snapshot (structural instrument limitation: SABnzbd moves the job before invoking the hook), so "untagged, proven by bytes" is UNPROVEN. See Gaps below |
| 4 | Every remaining beets config declares `musicbrainz`; MB-only probe pair shows 0 candidates on the broken config vs ≥1 on the fixed config | ✓ VERIFIED | `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml:54` → `plugins: embedart musicbrainz`; `stacks/selfhosted/arrs/beets/config.yaml:60` → `plugins: musicbrainz`. Probe pair recorded in 04-13-SUMMARY / 04-09-SUMMARY: 0 MusicBrainz candidates against live broken config, ≥1 (12/12 tracks, distance 0.048) against the one-line-fixed copy; hand-read `beet import -t` cross-check 95.2% |
| 5 | Estate is strictly better: one tagger, one `library.db`, zero rw library mounts on non-tagger/tagger-capable containers (Jellyfin's D-21 consumer exception printed separately, not folded into the counter) | ✓ VERIFIED | Live `bash scripts/quick-health-check.sh` run by this verifier, exit 0: `tagger definitions: 1`, `beets databases: 1`, `tagger databases: 0`, `retired paths present: 0`, `rw on Music, non-tagger: 0`, `rw on Music, tagger-capable: 0`, `rw on Music, Jellyfin D-21: 1` (printed on its own line, per the F10 amendment), `tagger-capable containers: 2` (sabnzbd + lidarr — the corrected REVIEWS row 9 expectation, both hold `:ro` or no library mount, neither fails the rw counter). `FAILURES total: 0` |

**Score:** 4/5 success criteria verified. Criterion 3 is OPEN by the phase's own written evidence contract, not by any inference of this verification.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| TAGR-03 | 04-01, 04-03, 04-04, 04-05, 04-06, 04-07, 04-13 | ✓ SATISFIED | Criteria 1, 2, 5 hold (one tagger def, Renovate clean, zero rw non-consumer mounts) |
| TAGR-04 | 04-01, 04-02, 04-03, 04-06, 04-07, 04-10, 04-11, 04-12, 04-13 | ✗ **BLOCKED (partial)** | The `#306`/audio.bash-strip/boot-proof halves are satisfied; the "a SABnzbd music job completes without invoking any tagger" behavioral half is OPEN (04-D12-EVIDENCE.md verdict). REQUIREMENTS.md's own Phase 4 row and 04-13-SUMMARY (`requirements-completed: []  # TAGR-04's behavioural half remains unsatisfied: criterion 3 is OPEN.`) agree with this reading |
| TAGR-05 | 04-04, 04-08, 04-09, 04-10, 04-11, 04-13 | ✓ SATISFIED | Criterion 4 holds: both remaining beets configs declare `musicbrainz`; probe pair measured |

No orphaned requirement IDs found — TAGR-03/04/05 are the only IDs REQUIREMENTS.md maps to Phase 4, and all three are claimed across the 13 plans' frontmatter.

### Key Link / Instrument Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `audio.bash` line 285 (beet invocation) | (removed) | static diff against vendored copy | ✓ WIRED (absence confirmed) | `grep -cE '^[[:space:]]*beet '` → 0; guard lines and `beets()` function body intact per D-10's letter |
| SABnzbd hook execution | PRE-HOOK byte snapshot | 04-12's read-only watcher | ✗ **NOT WIRED** | Structural: the watcher only sees the destination tree, which SABnzbd populates *after* invoking the hook. Both observed jobs (1s and ~2s hook duration) ran faster than the required 2-second-stable-snapshot floor could produce a valid pre-hook sample. This is the actual mechanism blocking criterion 3, documented in full in 04-D12-EVIDENCE.md lines 186-207 |
| `check-music-freeze.sh` census (§6b) | `quick-health-check.sh` routine path | `TAGGER_CENSUS_PROMOTED=1` | ✓ WIRED | Live run confirms census counters print unprompted, no env var required (04-11 promotion verified independently in this verification) |
| `quick-health-check.sh` vendored-file drift block | routine path | `VENDORED_DRIFT_PROMOTED=1` | ✓ WIRED | Live run: `✅ vendored files match (3): audio.bash, sabnzbd beets-config.yaml, survivor config.yaml` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full routine health check exits clean | `bash scripts/quick-health-check.sh` (workstation, live) | Exit 0, 96 containers running, census/drift counters all at target, sole `❌` is the pre-existing report-only "Traefik dashboard: Not accessible" (predates this phase) | ✓ PASS |
| wrtag DNS record removed | `dig +short wrtag.deercrest.info @1.1.1.1` | empty | ✓ PASS |
| No unresolved debt markers in phase-touched files | `grep -rn "TBD\|FIXME\|XXX" stacks/selfhosted/arrs/beets/ stacks/selfhosted/arrs/sabnzbd/ scripts/check-music-freeze.sh scripts/quick-health-check.sh scripts/check-renovate.sh` | no matches | ✓ PASS |
| Issue #306 closed | `gh issue view 306 --json state,title` | `CLOSED` | ✓ PASS |
| D-12 real-job evidence (the one behavior this phase could not close) | `04-D12-EVIDENCE.md` § 6 | `Verdict: OPEN` | ✗ FAIL (see Gaps) |

### Anti-Patterns Found

None found in phase-modified files that constitute a blocker. No unresolved `TBD`/`FIXME`/`XXX` markers. The one item that reads like a stub-risk on first pass — `stacks/selfhosted/music/` still present on disk — is confirmed to be an intentional, ruled-on leftover (04-05: leave in place, only untracked gitignored `.env`/`.env.backup` remain, nothing tracked in git references it) and is not a gap.

### Deferred Items (recorded, not gaps of this phase)

| Item | Addressed In | Evidence |
|---|---|---|
| `CLAUDE.md:152` and `.planning/PROJECT.md:187` still state "beets has no `undo` command" unqualified, when beets-flask rc6's `UNDO IMPORT` narrows that claim | Phase 7 | `deferred-items.md` DEF-04-01, explicit written deferral by plan 04-13, with the reason (both files must be amended together — `CLAUDE.md`'s region is generated from `PROJECT.md` — and 04-13's mandate is a single file) and the destination (Phase 7 owns the "undo exercised" criterion) |
| `beets.md`'s two open config gaps (`match.preferred.countries`, `fromfilename`/`edit` for bucket C) | Phase 6 | Recorded in 04-13-SUMMARY's living-text table; not a Phase 4 requirement |

### Human Verification Required

None. The remaining gap (criterion 3 / TAGR-04's behavioral half) is not a "please eyeball this" item — it requires an engineering change to the watcher instrument (see Missing, below) before a human-triggered or organic job can close it. It is reported as a structured gap, not routed to human sign-off.

## Gaps Summary

Four of five ROADMAP Phase 4 success criteria are measured and hold: exactly one tagger definition
(soulbeet retired, issue closed), Renovate cleaned of the inverted wrtag pin with a passing config,
every remaining beets config declaring `musicbrainz` with a measured 0-vs-≥1 MusicBrainz-candidate
probe pair, and a live census showing one tagger definition / one database / zero non-consumer rw
mounts (Jellyfin's D-21 consumer exception printed separately, exactly as the F10 amendment requires).

**Criterion 3 — "a SABnzbd music job completes without invoking any tagger at all" — is OPEN, not
passed.** This is not a case of a SUMMARY overclaiming and this verification catching it; the
phase's own evidence file (`04-D12-EVIDENCE.md`) and its own closing plan (`04-13`, whose SUMMARY
states outright "The phase is not closable, and `/gsd-verify-work` must treat criterion 3 as the
open gap") already say so. Two real music jobs ran inside the observation window with every
side-effect signal clean (no beets database, no `.bak`, no `beets.log`, no `SUCCESS: Matched with
beets` line, 25/25 files byte-identical, `extended.conf` unchanged) — but the specific proof the
criterion requires, a byte-identical comparison anchored to a snapshot taken *before* the hook ran,
could not be produced: SABnzbd moves a job into its destination tree and only then invokes the
post-processing hook, so a watcher on that tree structurally cannot sample first. Both jobs
completed their hook faster (1–2 seconds) than the watcher's required 2-second stability window
could resolve.

Closing this requires two things, both named in `04-D12-EVIDENCE.md`'s own "what would close it"
section and echoed in `04-13-SUMMARY.md`'s Next Phase Readiness: (1) a watcher change — either
snapshot the job in `/downloads/incomplete/` before SABnzbd's move, or drop the 2-second stability
wait and accept a possible retake — and (2) one more real music job (organic or
operator-triggered via a Lidarr search, as 04-12 did) run after that fix, to produce a valid
PRE-HOOK-vs-COMPLETION byte comparison. Neither is a large effort; the estate side of this
criterion is otherwise fully proven twice over. Given the phase's own "independently shippable"
framing, the estate is genuinely left better than it started (soulbeet gone, wrtag pin removed,
one database, boot-proven `:ro` mounts, both drift and census guards promoted to fatal) even with
this criterion open — but the ROADMAP contract for Phase 4 is not fully met, and `status: passed`
would misrepresent that.

---

_Verified: 2026-09-13T13:00:00Z_
_Verifier: Claude (gsd-verifier)_
