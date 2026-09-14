---
phase: 04-collapse-to-one-tagger
fixed_at: 2026-09-14
review_path: .planning/phases/04-collapse-to-one-tagger/04-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 13
fixed: 13
skipped: 0
deferred: 10
partial_findings: [WR-05]
requires_human_verification: [WR-03, WR-09]
status: all_fixed
---

# Phase 4: Code Review Fix Report

**Fixed at:** 2026-09-14
**Source review:** `.planning/phases/04-collapse-to-one-tagger/04-REVIEW.md`
**Iteration:** 1
**Scope:** Critical + Warning only (`CR-02`, `WR-02` … `WR-13`). Info tier deferred.

**Summary:**

- Findings in scope: **13**
- Fixed: **13** (one atomic commit each)
- Skipped: **0**
- Deferred (Info, out of scope): **10**

All work was done in an isolated git worktree and fast-forwarded onto `main`. Base commit
`a6b0a57`. No script was run against the live estate — every guard was driven locally against
temp fixtures or a stubbed `ssh`.

---

## ⚠️ READ THIS FIRST — two changes alter observable behaviour

### 1. `quick-health-check.sh` will now exit 1 on an estate that used to exit 0 (WR-09)

This was a **deliberate reversal of a previously deliberate decision**, made under explicit
instruction, and it is the single most consequential change in this batch.

The file previously declined this fix in-band, reasoning that a confident wrong diagnosis is not
a false green because the reader is still shown a red. That reasoning is now withdrawn and the
comment rewritten — it answered the wrong question. The Traefik, Authelia and dashboard probes all
printed `❌` **without touching `EXIT_CODE`**, so the estate's single health-check entry point
exited 0 — "healthy" to any caller reading the status rather than the transcript — with Traefik
down, which takes every `*.deercrest.info` service with it. The README contract is *exits 0
healthy, 1 on any violation*.

**The operational consequence is immediate.** The 2026-09-14 routine run recorded
`Traefik dashboard: ❌ Not accessible` while exiting 0. That underlying dashboard `❌` is
**pre-existing, real and still unfixed** — it was simply invisible in the exit code. The next
routine run will therefore **exit 1**, and that is correct, not a regression introduced here.
Anything that treats a non-zero exit from this script as an alarm will fire. Either fix the
dashboard or accept the red; do not revert the guard to silence it.

`stacks/selfhosted/arrs/beets.md` was amended in the same commit because this change falsified its
closing record, which described that `❌` as report-only.

### 2. `check-music-freeze.sh` §2 now carries a pinned inventory constant (WR-03)

`DECLARED_INTERP_EXPECTED` defaults to **12**, the measured number of volume lines that
interpolate a variable into the host path. **A change in that inventory fails §2**, which is fatal
to `quick-health-check.sh`. When a new interpolated mount legitimately lands, read it by hand and
move the constant in the same commit.

---

## Fixed Issues

| ID | Commit | Files | Outcome |
|---|---|---|---|
| CR-02 | `51038aa` | `scripts/quick-health-check.sh` | fixed |
| WR-02 | `655413f` | `stacks/selfhosted/arrs/beets/beets.yaml` | fixed |
| WR-03 | `5b07652` | `scripts/check-music-freeze.sh` | fixed — **requires human verification** |
| WR-04 | `c4e3daf` | `scripts/check-music-freeze.sh` | fixed |
| WR-05 | `8cafdc6` | `scripts/quick-health-check.sh` | fixed **(partial — see carve-out)** |
| WR-06 | `eca02a5` | `scripts/normalise-dj-tags.py` | fixed |
| WR-07 | `a951493` | `scripts/check-renovate.sh` | fixed |
| WR-08 | `7422a5c` | `scripts/spike03-image-headroom.sh` | fixed |
| WR-09 | `f57555a` | `scripts/quick-health-check.sh`, `stacks/selfhosted/arrs/beets.md` | fixed — **requires human verification** |
| WR-10 | `2179883` | `scripts/quick-health-check.sh` | fixed |
| WR-11 | `37c30b4` | `stacks/selfhosted/arrs/sabnzbd.yaml` | fixed |
| WR-12 | `9bd1a81` | `stacks/selfhosted/arrs/beets.md` | fixed |
| WR-13 | `6d91626` | `scripts/spike03-discogs-probe.py` | fixed |

### CR-02: extended.conf guard reported green on values that arm `rm -rf` — `51038aa`

Replaced both `grep -q` assertions with `_ec_val`, which takes the **last** matching assignment
(`tail -n 1`, matching `source` semantics), strips the key, and yields the value; the caller then
compares the **whole** value. No `$` anchor is added anywhere, so plan 04-12's trailing-comment
tolerance survives intact. Quoted values are taken verbatim up to the closing quote and are **not**
whitespace-stripped — that is what makes `ConversionFormat="FLAC "` correctly red. The `found=`
diagnostic now reports that same extracted value, so a red always quotes the line in force.

The parser lives in its own single-quoted `EXTCONF_PARSER` variable. That was a deliberate design
choice for two reasons: it needs zero backslash escaping inside the double-quoted remote command
string, and it can be `eval`'d locally against fixtures with no host.

**Driven, 12 controls, guard verdict compared against real bash `source` semantics — agreement in
every case:**

- Now RED (were green): `ConversionFormat="FLACX"`; duplicated `requireBeetsMatch` ending `true`;
  duplicated `ConversionFormat` ending `MP3`; `ConversionFormat="FLAC "`; absent key; empty value.
- Still GREEN (no false red): quoted; 04-12 trailing comments; unquoted + comment; single-quoted;
  leading indent; safe append (`true` then `false`).

### WR-03: §2 parser silently dropped three mount shapes — `5b07652`

Quote-stripping added before the split (closes the quoted-mapping hole). Uncommented long-form
`type: bind` now hard-fails — zero occurrences today, so green now and red the first time one
lands. Commented occurrences are correctly ignored.

**Deviation from the prescribed fix, and why.** The review's snippet blanket-`fail`s on any
variable-interpolated volume line. Applied verbatim that would have made §2 — and therefore
`quick-health-check.sh`, which folds it in fatally — **permanently red**, because twelve such lines
exist today and there is **no `.env` in this repo** to resolve them against (only `.env.sample`
files, none defining `MEDIA`). A permanently-red check trains the reader to ignore it: this is the
01-09 trap the file's own history warns about repeatedly. So the inventory is pinned to a named
constant, every line is printed, and a **change** is what fails — the estate's standing answer to
the permanent-red trap. Flagged for human verification because it is a judgment call, not the
literal prescription.

### WR-05: three in-band comments stating the opposite of the code — `8cafdc6` (partial)

Two of three rewritten, both in `scripts/quick-health-check.sh`: the opening notice that described
section 6b as an opt-in candidate, and the summary-selector note that told a future editor six
**live** tokens were inert. The second was the dangerous one — deleting a token fails silently,
because `SUMMARY` stays non-empty and the tick still prints. Withdrawn claims are paraphrased, not
quoted; all four withdrawn strings now grep to zero. Notice arithmetic deliberately untouched by
this commit.

**Carve-out — the third comment was NOT fixed.** See below.

### WR-09: down Traefik / Authelia / dashboard now exit 1 — `f57555a`

Each site now distinguishes three answers — running / not running / could not look — instead of
two. The subtle half: the **remote `grep -q` had to go**. With `set -o pipefail` and `grep -q` as
the last stage, `timeout` exits 124, `grep -q` exits 1 on the empty stream, and pipefail returns
the **rightmost** non-zero status — so 124 was laundered into 1 and read as "not running". The
container-count sites escape this only because `wc -l` exits 0, so adding `pipefail` here would
have looked like a fix and fixed nothing. Both container probes now capture `docker ps` with no
remote pipe and match locally; the dashboard drops its local `| grep -q "200"` and keeps ssh 255
(transport, could not look) distinct from any other curl exit (it ran, could not reach it).

Self-consistency updated in the same commit as required: a **seventh** notice header added
following the convention, the sixth notice's self-stated arithmetic amended in place, and the
failure tail extended to name all three probes. Verified **7 headers / shared-phrase count 8**.

Driven with a stubbed `ssh`, no network: 16 cases across running / not-running / 124 / 255 /
curl-exit / empty / non-numeric. All behaved as expected.

### Remaining fixes, briefly

- **WR-02** `655413f` — `networks: - t3_proxy` uncommented, host port removed (loopback form
  recorded in-band as the only acceptable restoration), `t3_proxy` declared external at top level
  so the file stands alone on its `manual` profile. Verified by parsing the YAML.
- **WR-04** `c4e3daf` — census matches the image **name** with an optional registry prefix and
  optional quoting, plus `picard`. Still resolves to exactly `beets.yaml`, so `TAGGER_DEFS` stays
  1; all four previously-missed forms now match, with no false positives.
- **WR-06** `eca02a5` — skip is now per-path state read once in the emit loop; buckets are
  disjoint; the reconciliation is a checked invariant recorded as `counts_reconciled` and exits 1
  on mismatch. Five routing cases reconcile.
- **WR-07** `a951493` — the three missed call sites use the `awk 'NF{n++} END{print n+0}'` form the
  file had already standardised on. `echo "" | wc -l` → 1; new form → 0.
- **WR-08** `7422a5c` — `|| b=""` makes the documented "could not read df" guard reachable under
  `set -euo pipefail`; the split declaration is kept split and now says why.
- **WR-10** `2179883` — sentinel created once and kept; watchdog writes into it; `[ -s ]` reads it;
  guessable fallback gone; unavailable `mktemp` is a named refusal that exits rather than returning
  (which both call sites would have misread as "host unreachable").
- **WR-11** `37c30b4` — D-10 inventory now names the `rm -rf` branch, why both log lines are
  unconditional, and that the gate lives in an unvendored host file asserted by the health check.
- **WR-12** `9bd1a81` — criterion 1 quotes the census pattern verbatim. Old command verified to
  return nothing (exit 1); new command returns exactly `beets.yaml`.
- **WR-13** `6d91626` — docstring, SECURITY bullet and a new in-band comment all now state that the
  root DEBUG **is** process-wide, that the handler is what makes it safe, and that
  `debuglevel` must stay unset.

---

## Carve-out: WR-05's third comment was deliberately not fixed

**File:** `stacks/selfhosted/arrs/beets/config.yaml:14-18`
**Status:** deferred, requires a coordinated host-side change

That paragraph still states in capitals that the vendored-file drift block "DOES NOT EXIST AT THIS
COMMIT" and that nothing detects divergence between the file and the host. Both claims are false —
the block is promoted (`VENDORED_DRIFT_PROMOTED=1`) and hashes this exact file.

It was **not** edited because `stacks/selfhosted/arrs/beets/config.yaml` is one of the three
**D-13 vendored files whose byte-identity against the host copy is asserted** by the drift block at
`scripts/quick-health-check.sh:689`. This is the same hazard class as `audio.bash`. Editing the
repo copy alone arms a guaranteed red the moment LXC 100 runs `git pull` — the drift block compares
host-git against host-appdata, so the comparison breaks as soon as the host checkout moves and the
appdata copy does not.

**Required follow-up, as one operation:**

1. Edit `stacks/selfhosted/arrs/beets/config.yaml` in the repo; commit and push.
2. `git pull --ff-only` in `/mnt/fast/stacks` on LXC 100.
3. Copy the file to `/mnt/fast/appdata/arrs/beets/config/config.yaml` (owner `568:568`).
4. Re-run `scripts/quick-health-check.sh` and confirm `✅ vendored files match (3)`.

That is an estate change, not a code fix, so it is recorded here rather than performed.

---

## Deferred — Info tier, out of scope without `--all`

Not attempted. Listed so none is lost.

| ID | Summary |
|---|---|
| IN-01 | `sqlite3` load-bearing in §6b but absent from §0 toolchain preconditions |
| IN-02 | `check-renovate.sh` omits `--strict`; computes an unused `VERSION` |
| IN-03 | `DRIFT_APPDATA_ROOT` / `REMOTE_TIMEOUT` interpolated unvalidated into a remote root shell |
| IN-04 | §2 Jellyfin exemption is file-scoped, not mapping-scoped |
| IN-05 | A failed write still prints a change line to the review artefact |
| IN-06 | Two upstream nits in vendored `audio.bash` — correctly recorded, not fixed |
| IN-07 | `--sidecars` emits a blank line when the sidecar set is empty |
| IN-08 | `EXTCONF_PATH` / `EXTCONF_HOST` extend the IN-03 injection surface |
| IN-09 | `beets.md` "Two standing guards" — there are now three |
| IN-10 | Unused loop variable in `spike03-image-headroom.sh` |

Note **IN-08** shares a file with CR-02 and **IN-09** shares a file with WR-12; both were left
untouched to keep commits scoped to their findings.

---

## Deliberately not touched

- **`stacks/selfhosted/arrs/sabnzbd/audio.bash`** — vendored, byte-identity asserted by the drift
  block and by a live health check. CR-02 and WR-11 were closed at the **guard** and
  **documentation** layers instead, exactly as required.
- **`ReplaygainTagging`** — its absence from the guard is a recorded scoped decision at
  `quick-health-check.sh:774-778`, not an oversight. No assertion added.
- **The `220dcf4` "defective Task 3 gate"** — a defect in a plan's acceptance grep, not in shipped
  source. Not chased.
- **CR-01 and WR-01** — already closed per the review's binding *Already Closed* table. Not
  re-applied.

---

## Verification performed

Every commit was gated on its own check; nothing was committed on a failing check, and no rollback
was needed.

- `bash -n`: `quick-health-check.sh`, `check-music-freeze.sh`, `check-renovate.sh`,
  `spike03-image-headroom.sh` — all pass.
- `python3 -m py_compile`: `normalise-dj-tags.py`, `spike03-discogs-probe.py` — both pass.
- YAML parse: `beets/beets.yaml`, `sabnzbd.yaml` — both pass.
- **Functional drives, all local, no estate contact:** CR-02 against 12 config fixtures
  cross-checked against real `source` semantics; WR-09 against 16 stubbed-`ssh` cases; WR-10
  against four real subprocess cases plus a sentinel-leak check; WR-03 against the real tree with
  its failure branch driven via the override; WR-04 and WR-12 against the real tree.

**Not done, by instruction:** no script was executed against `172.16.1.159` or `172.16.1.158`. The
first live run of `quick-health-check.sh` should be observed by a human — see the WR-09 warning at
the top of this report.

---

_Fixed: 2026-09-14_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
