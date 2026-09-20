---
phase: 06-tagger-configuration-and-dry-run
plan: 01
subsystem: tagger-configuration
tags: [beets, config, vendored, credential-screen, path-formats, rc6]
requires:
  - "Phase 4 D-28: exactly one beets library.db survives"
  - "Phase 4 D-24: no Discogs credential in this repo"
  - "Phase 6 D-03/D-04/D-05: one config, two containers, /media stays :ro"
provides:
  - "the single vendored beets configuration for both containers"
  - "CONF-01 copy/move pair, stated with its WHY"
  - "CONF-02 incremental + incremental_skip_later, paired"
  - "CONF-03 paths: stanza in first-match-wins order"
  - "CONF-05 match.preferred + musicbrainz.extra_tags"
  - "the D-18 protected DJ-field register, per container format"
  - "a credential screen proven capable of matching"
affects:
  - "plan 06-03 (deploys this file to $BEETSDIR before flask first starts)"
  - "plan 06-06 (asserts the SERVER-COMMITTED config under rc6's schema)"
  - "plan 06-08 (scripts/phase06-oracle.sh — the D-19a class assertion)"
  - "plan 04-10/04-11 (vendored-file drift block — this file's bytes changed)"
tech-stack:
  added: []
  patterns:
    - "an absent key is the on switch, not the off switch"
    - "dated retraction with the superseded sentence kept visible"
    - "positive control before trusting a screen that returns zero"
    - "a matcher described in prose is paraphrased so its own grep stays at zero"
key-files:
  created:
    - .planning/phases/06-tagger-configuration-and-dry-run/06-01-SUMMARY.md
  modified:
    - stacks/selfhosted/arrs/beets/config.yaml
decisions:
  - "Accept 02-05 as the multi-disc filename rendering; %right{$disc,1} rejected because it breaks at disc 10"
  - "The credential screen is split into two tiers; tier 1 is read in full, tier 2 ranks"
  - "The sha256 of the fenced pre-existing host file stays in the file, classified as a non-credential"
metrics:
  duration: ~35 min
  completed: 2026-09-20
  tasks: 2
  files: 1
  commits: 2
---

# Phase 6 Plan 01: Tagger Configuration — Vendored Config Rewrite Summary

The whole of Phase 6's tagger configuration now lives in `stacks/selfhosted/arrs/beets/config.yaml`
— 417 insertions over a 97-line file — offline-validated, credential-re-screened against a proven
screen, and committed. Nothing was deployed to the host.

## What Was Built

**Task 1 — the config rewrite** (`d4fead8`)

The file grew from the minimal TAGR-05 slice into the full Phase 6 stanza, preserving all four of
its header devices (Consumed-by block, vendored/authoritative split, per-key WHY comments,
credential screen) and the three SAFE-01 `auto: no` blocks verbatim.

| Area | What landed |
|---|---|
| D-10 | `plugins:` is now a one-element YAML flow sequence. rc6 types the key `list[str]` and rejects the string form, and a rejected config kills the inbox watchdog while the page keeps serving |
| rc6 landmines | `directory`, `statefile`, `import.duplicate_action`, `match.medium_rec_thresh` all pinned, each naming rc6's default as the thing being refused |
| CONF-01 | `copy: yes` / `move: no`, with rc6's `Literal[True]`/`Literal[False]` type enforcement noted as a **tripwire, not a safety net** |
| CONF-02 | `incremental` **and** `incremental_skip_later`, cited to `beets/importer/tasks.py@v2.12.0:310-322` |
| CONF-03 | the six-key `paths:` stanza in first-match-wins order |
| CONF-05 | `match.preferred.countries: ['GB','US']` + `original_year`, `musicbrainz.extra_tags` |
| Support keys | `per_disc_numbering`, `asciify_paths`, `va_name`, `max_filename_length`, the `aunique:` block |
| Comment-only | the D-18 register, the D-19a honesty note, the D-34/C-2 write-side amendment, the `02-05` rendering decision |

The header's scope statement was **rewritten as a dated retraction**, not silently outgrown. The
superseded sentence ("EVERYTHING ELSE ABOUT THIS TAGGER'S CONFIGURATION BELONGS TO PHASE 6 … Do not
add path formats, match thresholds or import behaviour here") is quoted verbatim above its
retraction, per `beets.md:70-77`. The prohibition was **discharged, not violated** — and what
survives of it is its reasoning, which is why the remainder landed in one commit rather than one key
at a time.

A new header warning records threat T-06-03: this file must exist at `$BEETSDIR/config.yaml`
*before* beets-flask first starts, because rc6's `write_examples_as_user_defaults()` copies in an
example that arms `embedart.auto`, `lastgenre.auto force`, `scrub` and `asciify_paths` when the file
is absent — three of the SAFE-01 switches Phase 1 turned off, installed by a container that looks
like it started cleanly.

**Task 2 — three offline proofs** (`18e9980`)

## Proof Output, Verbatim

**Proof 1 — the path keys parse as the beets queries intended.** All PASS.

```
  path-format keys, in config order (6):
    1. 'singleton'
    2. 'albumtype:=dj disctotal:2..'
    3. 'albumtype:=dj'
    4. 'disctotal:2..'
    5. 'comp'
    6. 'default'

  [PASS] shlex.split('albumtype:=dj disctotal:2..') -> 2 term(s) — got ['albumtype:=dj', 'disctotal:2..']
  [PASS] shlex.split('albumtype:=dj') -> 1 term(s) — got ['albumtype:=dj']
  [PASS] shlex.split('disctotal:2..') -> 1 term(s) — got ['disctotal:2..']
  [PASS] shlex.split('comp') -> 1 term(s) — got ['comp']
  [PASS] shlex.split('singleton') -> 1 term(s) — got ['singleton']
  [PASS] albumtype:=dj is a single term — ['albumtype:=dj']
  [PASS] its query prefix is '=' (exact MatchQuery), not a bare-colon SubstringQuery — field='albumtype' pattern='=dj'
  keys containing '/': 0
  [PASS] NO path-format key contains a '/' (PathQuery.is_path_query would rewrite it) — []
```

**Proof 2 — template functions.** All PASS.

```
  template functions used across all 6 path values: ['aunique', 'sunique']
  known beets template-function set (13): ['asciify', 'aunique', 'capitalize', 'first', 'if',
    'ifdef', 'left', 'lower', 'right', 'sunique', 'time', 'title', 'upper']
  [PASS] every function used exists — unknown: []
  [PASS] aunique is used (D-16 keeps it)
  [PASS] sunique is used (D-19b singleton rule)
```

**Proof 3 — the credential screen, positive control first.** All PASS.

```
  positive control (scratch copy, never the real file):
    keys named after a credential class:        real=0  control=1  (+1)
    URLs carrying embedded credentials:         real=0  control=1  (+1)
    e-mail addresses:                           real=0  control=2  (+2)
    opaque-run candidates (tier 1):             real=28 control=29 (+1)
    opaque-secret shape (tier 2):               real=1  control=2  (+1)
  [PASS] all five screens fired on the control — fired 5/5
  [PASS] the scratch copy was deleted

  screen of the REAL file — every count recorded, zeroes included:
    keys named after a credential class: 0
    URLs carrying embedded credentials: 0
    e-mail addresses: 0
    opaque-run candidates (tier 1, 20+ base64/hex/path chars): 28
    opaque-secret shape (tier 2): 1

  tier 2 — opaque-secret shape: 1 match(es), each classified by hand:
    '8b09078d4779b44cf145fbbb886ea19bcf9e6048b1f3f8c0389b6b575037f1ae'
        -> NOT A CREDENTIAL — published sha256 of the fenced pre-existing host file,
           quoted in the AUTHORED-NOT-SEEDED block. It grants nothing and stays.
  [PASS] every tier-2 match is a classified non-credential — unclassified: []

RESULT: ALL PROOFS PASSED
```

The positive control was appended to a scratch **copy** under the session scratchpad — outside the
repository — and deleted. `git status --porcelain` showed only `config.yaml` throughout.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The credential screen's "high-entropy" check was not a credential screen**

- **Found during:** Task 2, proof 3, first run
- **Issue:** the pattern the plan specified for "a high-entropy run of 20+ base64/hex characters" is
  `[A-Za-z0-9+/=_-]{20,}` — a character class that includes `/`, `_` and `-`. On a file dense with
  file paths and long identifiers it returned **25 matches**: `metasauce/beets-flask`,
  `incremental_skip_later`, `beets/library/models`, `PreferNonstandardArtistsTag` and so on. A
  screen whose output is 25 items of noise is not read; it is skimmed and waved through, which is
  the exact failure the plan's "a screen that has never matched anything is not a screen"
  instruction exists to prevent — inverted.
- **Fix:** split into two tiers rather than narrowing and losing coverage. **Tier 1** keeps the
  broad pattern and its **full match list is printed, never summarised**. **Tier 2** splits each
  tier-1 candidate on `/ _ . = -` and flags it only when a resulting segment is ≥20 chars carrying
  both a letter and a digit, or ≥32 chars of pure hex. Tier 2 returns exactly 1 — the sha256 — and
  the control token still fires both tiers.
- **Stated limit, recorded in the file:** a purely alphabetic secret of 20+ characters would not be
  *ranked* by tier 2. That is why tier 1 is printed in full rather than counted.
- **Files modified:** `stacks/selfhosted/arrs/beets/config.yaml` (the screen paragraph)
- **Commit:** `18e9980`

**2. [Rule 1 - Bug] My own comment instantiated the pattern it described**

- **Found during:** Task 2, verify command
- **Issue:** the credential-screen paragraph documented the embedded-credential check by writing the
  matcher out literally. The verify's own `://[^/\s]*:[^/\s]*@` then matched that comment, so the
  file failed its own screen — a false positive created by documenting the screen.
- **Fix:** paraphrased as "a user:pass pair between the scheme and the host", with an in-band note
  saying it is paraphrased deliberately so the grep stays at zero. This is this repo's existing
  convention for a described matcher (`quick-health-check.sh:920-923`).
- **Files modified:** `stacks/selfhosted/arrs/beets/config.yaml`
- **Commit:** `18e9980`

**3. [Rule 1 - Bug] The recorded tier-1 count drifted from the measured one**

- **Found during:** Task 2, after fixing deviation 1
- **Issue:** writing the counts into the file *added* identifiers to the file, moving tier 1 from 25
  to 28 — the screen measures the document that records its own result.
- **Fix:** re-ran to a fixed point and recorded 28/1, which the final run confirms.
- **Commit:** `18e9980`

### Worktree base correction

The worktree spawned at `c67d497`, an ancestor of the expected base `db281a2`. Corrected with
`git reset --hard db281a2` **after** the HEAD assertion passed (branch `worktree-agent-…`, in
namespace, not a protected ref). No self-recovery via `git update-ref` was attempted.

## Verification

| Check | Result |
|---|---|
| `python3 -c "import yaml; yaml.safe_load(...)"` | exit 0, `yaml parse OK` |
| Task 1 verify (26 assertions) | `config OK` |
| Task 2 verify | `offline proofs OK; template funcs used: ['aunique', 'sunique']` |
| `git diff --stat db281a2 HEAD` | `1 file changed, 417 insertions(+), 41 deletions(-)` |
| `grep -c 'plugins: \[musicbrainz\]'` | `1` |
| comment-stripped grep for the bare-colon DJ query | `0` |

## Success Criteria

- **CONF-01/02/03/05 all exist with a stated WHY** — TRUE. Each is asserted by the task 1 verify.
- **All four rc6 schema-default landmines set explicitly** — TRUE: `directory`, `statefile`,
  `import.duplicate_action: ask` (refusing rc6's `remove`), `match.medium_rec_thresh: 0.25`.
- **The file is credential-free and the screen was proven capable of matching** — TRUE. 0/0/0 on the
  three literal screens; 1 tier-2 match, classified; all five screens fired on the positive control.
- **Nothing was deployed** — TRUE. No host or container access of any kind. The appdata copy is
  still the pre-Phase-6 file; plan 06-03 deploys it.

## Notes for Following Plans

- ⚠ **This file's bytes changed, so the vendored-file drift hash changed.** `06-PATTERNS.md` flags
  this. The appdata copy at `/mnt/fast/appdata/arrs/beets/config/config.yaml` is now **divergent by
  design** until plan 06-03 deploys. Any drift check run between now and then will fire correctly.
- **Plan 06-03** must assert this file exists at `$BEETSDIR/config.yaml` *before* first start
  (T-06-03), and must not let rc6 write its example in.
- **Plan 06-06** is the first place rc6's eyconf schema validation is observable. This plan
  deliberately did **not** attempt it — no container exists yet, and a locally-invented schema check
  would have been a guess dressed as a proof.
- **Plan 06-08's oracle** carries the D-19a class assertion (no album directory whose basename
  equals its parent artist directory's, case-folded) because **no path template can express it** —
  beets has no field-to-field comparison. That absence is stated in the config so it does not read
  as an oversight.
- **The `%aunique{}` lower-bound caveat** is written into the config: an oracle run against a
  throwaway library reports *fewer* firings than a real import. If D-16 wants a count rather than a
  floor, the oracle must run against a copy of the real `library.db`, opened by flask's 2.12.0
  (D-04).
- **`import.write: yes` is set** as the Phase 7 behaviour. Every Phase 6 invocation must override it
  to `no` via the `-c` overlay. The config says so, but deliberately does not rely on it — the `:ro`
  mount (D-05) and the statefile sha256 (D-29) are the independent guards.

## Self-Check: PASSED

- `stacks/selfhosted/arrs/beets/config.yaml` — FOUND
- `.planning/phases/06-tagger-configuration-and-dry-run/06-01-SUMMARY.md` — FOUND
- commit `d4fead8` — FOUND
- commit `18e9980` — FOUND
