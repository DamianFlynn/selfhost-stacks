---
phase: 07-pilot-12-albums-end-to-end
reviewed: 2026-09-28T15:00:00Z
depth: standard
diff_base: 45419b1
id_namespace: CR8 / WR8 / IN8 (checked unused before writing: /usr/bin/grep -rl -- 'CR8-' scripts stacks .planning CONVENTIONS.md -> 0 files, the same for WR8- and IN8-; CONVENTIONS §13)
files_reviewed: 3
files_reviewed_list:
  - scripts/check-beets-config.sh
  - scripts/check-music-consumers.sh
  - stacks/selfhosted/arrs/beets/config.yaml
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 7: Code Review Report (gap round, 2026-09-28)

**Reviewed:** 2026-09-28
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Scope: `git diff 45419b1..HEAD` for the three listed files, from commits 1e054a6, 58e2d3d and 596438a.
I judged it against CONVENTIONS §1–§14.

What I did:

- Ran `bash scripts/check-beets-config.sh --self-test` on the workstation. It printed "all 20 cases
  behaved as expected (16 of them red)". `ST_PLANNED_CASES=20` matches the count: 8 dump cases, 1
  source case, 6 inbox cases and 5 redaction cases. Case 1's new expectation of 26 is 22 plus the 4
  new `expect_eq`.
- Pulled the T-06-33 judge (`REDACTION_JUDGE`) out into a scratch file and ran ten adversarial dump
  pairs through it: quoted defaults, a quoted `"null"`/`'~'`, a list-valued key, a nested-mapping
  key, a mismatched redacted shape, CRLF, tab indentation, partial key sets and an empty defaults file.

**T-06-33 verdict: no credential path to "plugin-defaults-only" was found.**

- Every non-empty value that is not the default goes RED. That includes multi-line, nested and list
  values, which extract as `None`.
- A difference outside the four keys goes RED before the defaults file is read at all.
- Plugin drift goes UNKNOWN in each of these cases: a different redacted set, a depth-3 redaction
  (`?`-prefixed), a module refactor that removes `ArtSource`, or an empty `{}`.
- A failed or timed-out derivation leaves the defaults file empty, and the result is UNKNOWN.
- Values reach the judge only as file contents. The in-container derivation reads no config, and
  its only argv is base64 of fixed source code.
- "Could not look" stays separate from "nothing is wrong": rc 2 goes to `REDACTION_VERDICT=UNKNOWN`
  and `fail`, and rc 1 goes to `DIFFERS`.

The weaknesses are in the tests and in the claims made around the check, not in the check itself:

- The judge's UNKNOWN branches are never driven (WR8-03).
- The Cover Art Archive config fetches more than its comment says (WR8-01).
- The D-28 section still reports green under an `%aunique{}` label it no longer measures (WR8-02).
- The media preference re-targets CD rips, and the in-band comment says nothing about it (WR8-04).

Confirmed:

- `embedart` is absent from `plugins:` (config.yaml:135).
- `embedart.auto: no` is still set (config.yaml:538-539) and still asserted (SAFE-01, check-beets-config.sh).
- The plugin-set assertion is exact and order-insensitive. A duplicate entry or a string-form
  `plugins:` goes red, and self-test case 5a drives the embedart red.
- No other script under `scripts/` asserts the old one-plugin shape (`/usr/bin/grep -rl
  "fetchart\|embedart\|plugins: \[musicbrainz\]" scripts/` returns only check-beets-config.sh).
- No new `${VAR:-default}` override was introduced (§4).
- The new remote exec goes through `beet_exec`, so it is bounded Linux-side by `timeout ${REMOTE_TIMEOUT}` (§2).

## Warnings

### WR8-01: `fetchart.sources: [coverart]` also fetches the release GROUP's art, so the art is not always "that release's own"

**File:** `stacks/selfhosted/arrs/beets/config.yaml:141-149`, pinned by `scripts/check-beets-config.sh:622`

**Issue:** The comment says: "`coverart` is keyed by the matched MusicBrainz release id, so the
image fetched is that release's own." A bare `coverart` entry means `coverart: *`, and that tries
both matching criteria. beets' `CoverArtArchive` yields the release's images first (`MetadataMatch.EXACT`).
If the release has no usable front, it falls back to `release-group/{mb_releasegroupid}`
(`MetadataMatch.FALLBACK`). The fallback returns whichever edition's front CAA promoted for the
group, which may be a different edition's cover. Gap 2 was exactly this class of error: an album
getting another edition's art.

`check-beets-config.sh:622` asserts `'["coverart"]'`, so the check locks in the permissive form. A
reviewer who reads the comment will believe it is strict. The live evidence so far (P10 and album
166) involves releases that do have their own front, so the fallback path has never been exercised.

**Fix:** Restrict the source to the release, then re-pin the assertion to whatever shape ARM 1
actually serialises. Measure that shape first; do not assume it.

```yaml
fetchart:
    auto: yes
    sources:
    - coverart: release
```

```bash
expect_eq "OD-2 fetchart.sources" '[{"coverart":"release"}]' "$(jget "$json" '.fetchart.sources | @json')"
```

If the group fallback is kept on purpose, correct the comment to say that a release without its own
front gets the release group's cover.

### WR8-02: D-28 prints a green "%aunique{} album" count for a control row, and can no longer see the failure mode it is named for

**File:** `scripts/check-music-consumers.sh:594-599` (the edit), with effects at `:1584`, `:1588`, `:1606` and `:1904`, and the stale header at `:1560-1582`

**Issue:** After the edit, `AUNIQUE_ROWS` holds one row, P02. By its own comment, that row's folder
name and album tag agree. D-28's failure mode, per the 4d header, needs folder and tag to
**differ**: `folder_name` then silently yields `Various Artists`. So the one row cannot produce the
D-28 red. It can only fail on absence, duplication or a wrong artist.

The output still says `D-28 aunique albums (MA): 1 (target 1)` and "`%aunique{}` album(s)". The 4d
header still describes the measured twins ("the Benson Boone twins legitimately give TWO title
hits", "MA holds the twins as two albums"). An operator who reads the green line will conclude that
`%aunique{}` attribution is verified. It is not, because no firing set exists.

The pin also moves only by hand. If the next import produces a firing set, the section stays green
until somebody rebuilds the inventory. That is the §5 trap, and a label claiming coverage makes it
worse. This is not fail-open for the rows it holds: absence and duplication are still UNKNOWN or red.
The problem is that the output reports more than it measures (§3).

**Fix:**
- Separate the control from the firings: `AUNIQUE_CONTROL_ROWS=( "Benson Boone/American Heart|Benson Boone" )`
  and `AUNIQUE_ROWS=()`.
- Print `D-28 %aunique{} firing sets: 0 pinned (control 1/1)`.
- Update the 4d header's twin narrative to past tense, or cite the phase artifact for it (§12).
- Better: add a detector so an unpinned firing goes red rather than silently green. For example,
  count library album dirs matching `\[[^]]+\]$`, or dirs whose name differs from the album tag,
  and fail when that count differs from the number of pinned rows.

### WR8-03: The T-06-33 judge's fail-closed branches are asserted but never driven (§3)

**File:** `scripts/check-beets-config.sh:1190-1237` (cases 14-18), for the branches at `:869-926`

**Issue:** §3 says: "Anything asserted must also be proven able to fail — driven red once." The five
redaction cases drive PASS (twice), NON-DEFAULT, outside-allowlist and unreadable-file. None of the
following is driven:

- (a) The defaults file naming a different set (`set(defaults) != ALLOW`). This is the only guard
  against a future beets marking a new key redacted, which the header names as the reason the
  allowlist is a literal.
- (b) A differing key whose redacted side is not `REDACTED`.
- (c) A key present in only one dump.
- (d) A key present twice (the `ValueError` path).
- (e) Non-UTF-8 input.
- (f) Bytes that differ with no key-level difference (`differing == 0`).
- (g) A multi-line value (`NON-DEFAULT(multi-line)`).
- (h) An empty or unparseable defaults file. This is the live path when the in-container
  derivation fails or times out.

My scratch runs show each of these behaves correctly today. A regression in any of them would ship
green: for example, a refactor that turns the drift guard into `set(defaults) >= ALLOW`.

**Fix:**
- Add driven cases, each with its expected rc:
  - defaults `{"fanarttv_key":null,"google_key":null,"lastfm_key":null}`, expect 2.
  - an empty defaults file with differing dumps, expect 2.
  - redacted `google_key: x` against unredacted `google_key: y`, expect 2.
  - a key in the unredacted dump only, expect 2.
  - an unredacted `google_key:` followed by `    - v`, expect 1.
- Re-pin `ST_PLANNED_CASES` and the red count in the same commit (§5).
- Consider also asserting the `why` substring, so a case cannot pass on the right rc for the wrong reason.

### WR8-04: `preferred.media` re-targets CD rips to Digital Media editions, and the in-band rationale does not say so

**File:** `stacks/selfhosted/arrs/beets/config.yaml:414-420`

**Issue:** The comment says "CD second, so a CD rip still beats vinyl". That is true, but it hides
the larger effect. beets' `add_priority` charges `index / len(options)`. With `['Digital Media',
'CD']`, a CD candidate costs 0.5 × weight 1.0, and a Digital Media candidate costs 0. The files carry
no media tag, so beets cannot tell a CD rip from a WEB rip. **Every CD rip whose album has a Digital
Media release with the same tracklist will now match the digital release.** That changes
`mb_albumid`, `catalognum`, label and barcode, and through `catalognum` it changes the `%aunique{}`
suffix and the path.

The effect is recorded as DEF-07-19-05, but only in the phase directory. The durable comment beside
the key says the reverse. 07-19 (d) also measured the new pick for P02 as an **exact tie**
(b3a1e018 against cfb585a2), so the preference does not fully decide the pick.

§12 asks the in-band comment to state what would falsify the branch. Here, that is a CD-sourced
album landing on a digital release.

**Fix:** State the trade-off in the comment and cite the DEF:

```yaml
# Trade-off (DEF-07-19-05): files carry no media tag, so a CD rip whose album also has a Digital Media
# release with the same tracklist will match the DIGITAL release (different catalognum, barcode and
# %aunique suffix). Accepted because the pipeline's input is overwhelmingly WEB. Revisit before any
# CD-sourced backlog bucket.
```

Also add a CD-sourced album to the next pilot's measurement set.

## Info

### IN8-01: Self-test prose next to the re-pinned count is stale in three places

**File:** `scripts/check-beets-config.sh:84`, `:956`, `:1084`

**Issue:**
- Line 84 says "The remaining one is a SOURCE assertion" directly after "TWENTY cases… Eight drive
  the assertion function". That leaves 12 cases unaccounted for, not one.
- Line 956 still reads "`--self-test`. SEVEN cases, SIX of which MUST go red".
- Line 1084 reads "The five above", but seven dump cases now precede case 6.

The banner is derived, but this prose is the self-invalidating kind the header warns about.

**Fix:** Reword all three to match 20/16, or point them at the derived banner.

### IN8-02: `CD` is an unanchored-end regex, so it also prefers `CD-R`, `CDV` and similar formats

**File:** `stacks/selfhosted/arrs/beets/config.yaml:420`

**Issue:** beets compiles each entry as `(\d+x)?(CD)` and uses `re.match`, which anchors only the
start. MusicBrainz formats `CD-R`, `CDV` and `CDDA` all match. A CD-R bootleg therefore ranks as
well as a pressed CD.

**Fix:** If that is not intended, use `'CD$'`, or list the formats you want explicitly.

### IN8-03: Round history was added in band (§12)

**File:** `scripts/check-beets-config.sh:785-793` and `:74-81`; `stacks/selfhosted/arrs/beets/config.yaml:131-145`

**Issue:**
- In check-beets-config.sh, "WHY IT IS NOT A WHOLE-FILE `cmp` ANY MORE… halted the 07-20 deploy"
  and "added 2026-09-28 for DEF-07-20-01" are round narrative.
- In config.yaml, "gave NOW 117 the Disney 3 cover… NOW 121's cover" is also round narrative.

§12 wants the reason and the falsifier in band, with the history kept in the phase directory and
cited by ID.

**Fix:** Cut these to the rule plus one DEF/OD citation.

### IN8-04: A timed-out defaults derivation is not reported as its own condition (§2)

**File:** `scripts/check-beets-config.sh:1567-1572`

**Issue:** An rc of 124 from the derivation exec prints only `info "…could not be read (rc=124)"`.
The counted verdict then reads "the installed plugin defaults could not be read". That still fails
closed, but every other arm in this file names the timeout in its `fail` line ("exceeded its
${REMOTE_TIMEOUT}s bound").

**Fix:** Branch on `BEET_EXEC_RC -eq 124` and add a matching `fail`, or append the rc to `REDACTION_WHY`.

### IN8-05: fetchart makes beets a second writer of `.jpg` under the library, and the Jellyfin-freeze sidecar inventory cannot attribute it

**File:** `stacks/selfhosted/arrs/beets/config.yaml:146-149`; affects `scripts/check-music-freeze.sh` section 5 (out of scope, reported only)

**Issue:** `.jpg` is in the SAFE-05 watched set, which is how a Jellyfin write is detected. From now
on, every matched import adds a `cover.jpg`. DEF-07-19-04 records this as an observation, and 07-20
attributed the 88 → 89 change by hand via `artpath`. No check does that attribution yet.

**Fix:** When the freeze and import checks are next touched, exclude paths that equal some album's
`artpath` in `library.db`, or at least count them separately.

---

_Reviewed: 2026-09-28T15:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
