---
phase: 03-tagger-spike
plan: 06
subsystem: measurement-instrument
tags: [beets, discogs, tag_album, ndjson, resume-ledger, signal-alarm, secret-redaction, A1-gate, TAGR-01, D-05, OD-6]
requires:
  - "03-03 — the reflinked scratch tree and the 24-folder sample this instrument will be pointed at"
  - "03-04 — beets-spike, the /spike-scripts delivery mount, the token-free spike config, and the runtime token file"
  - "03-05 — the normalised arm, and the bind-mount inode finding that forced this plan's preflight"
provides:
  - "scripts/spike03-discogs-probe.py — the criterion 1/2 instrument: tag_album() NDJSON emitter, folder-granular resume, failure ledger, signal.alarm() ceiling, in-process 429 and request counters, loose/strict gap printed"
  - ".planning/phases/03-tagger-spike/03-PROBE-SMOKE.md — the A1 gate result, CONFIRMED, with the paired-instrument agreement table"
  - "the measured per-folder Discogs request count: 7, plus 1 identity probe per run (not per folder)"
  - "x-discogs-ratelimit = 60, re-confirmed independently of 03-04"
  - "DEF-03-04 — the token is in the query string, not the Authorization header"
  - "DEF-03-05 — grep -c '429' is not an instrument for HTTP 429, and it fires false against a pre-committed T2 limb"
affects:
  - "03-07 — runs this probe on the 24-folder sample; must carry the corrected 429 instrument, the --folder-meta map, and the preflight inode assertion"
  - "03-07 and 03-10 — inherit the redaction fix for free by running this probe, but their own threat-register text still names the Authorization header"
  - "03-11 — teardown must remove /mnt/fast/spike-03/out (now also carries smoke*, test-ceiling* and the staged .py files)"
tech-stack:
  added: []
  patterns:
    - "Refusing the whole run at startup rather than emitting N units of silently-wrong zeros, because a failed call and a genuine no-match are the same value"
    - "Enforcing a wall-clock ceiling with signal.alarm() so it fires INSIDE a third-party library's blocking backoff sleep, which a loop-top elapsed check structurally cannot"
    - "Redacting secrets at the logging HANDLER, not the logger, because a propagated record does not re-run ancestor logger filters"
    - "Two independent redaction nets - by parameter name and by exact live value - because neither alone covers an unseen serialisation"
    - "Emitting a positive `no_candidates` record so a zero-rate unit is distinguishable from a unit that was never measured"
    - "Keeping the one third-party call behind a module-level indirection so a ceiling can be tested against a blocking stub without burning API budget"
key-files:
  created:
    - scripts/spike03-discogs-probe.py
    - .planning/phases/03-tagger-spike/03-PROBE-SMOKE.md
  modified:
    - .planning/phases/03-tagger-spike/deferred-items.md
decisions:
  - "T-03-31's mitigation was aimed at the wrong channel: python3-discogs-client passes the user token as a ?token= QUERY PARAMETER, so urllib3 DEBUG - criterion 2's own request counter - logs it. Fixed at the logging record, not by remembering to screen the file"
  - "`grep -c '429'` cannot be the 429 instrument: a Discogs release ID and the probe's own summary labels both match it. The HTTP status column and the in-process counter are"
  - "`plugins.load_plugins()` takes NO arguments in beets 2.13.1; 03-RESEARCH.md's probe sketch raises TypeError"
  - "The smoke album is 03-SAMPLE.md's verified `clean-2` slot, not either album 03-06-PLAN.md names - both of those were already retracted as empty / one-file"
  - "Exit 1 is widened to cover a signal-interrupted run, not only failures and the ceiling: a run that exits 0 having probed half its input is the silent partial success this phase exists to avoid"
  - "TAGR-01 is NOT marked complete: this plan builds and gates the instrument, it does not measure a rate"
metrics:
  duration: "~1h20m"
  completed: 2026-09-03
---

# Phase 3 Plan 06: The Discogs Candidate Probe and its A1 Gate Summary

Built criterion 1 and 2's instrument, gated it on a known-good album — **A1 CONFIRMED**, 5 Discogs
and 5 MusicBrainz candidates agreeing with a hand-read `beet import -t` on five properties — and
found in the process that **the plan's own credential mitigation was aimed at the wrong channel**:
the Discogs token is in the request **query string**, not the `Authorization` header, so criterion
2's independent request-counting instrument is also a credential sink.

## What was built

**`scripts/spike03-discogs-probe.py`** (~980 lines) — container-resident, delivered by the
read-only `scripts/` mount (OD-6). It calls `beets.autotag.match.tag_album()` directly, once per
folder, and emits one NDJSON record per candidate on stdout. That is the only mechanism that
yields **both** the loose and the strict D-05 figure mechanically: `AlbumMatch` carries the
candidate's track list *and* the item/track mismatch. `beet import --pretend` never calls the
lookup stage at all; `beet import -q --log` records only the outcome.

Five design choices carry the weight:

1. **Three refusals, all before any audio file is opened.** An empty result from a failed HTTP call
   and an empty result from a genuine no-match are **the same value**, so the probe probes once and
   refuses the whole run rather than emitting 24 folders of silently-wrong zeros. It asserts both
   plugins are in `plugins.find_plugins()` — the in-process equivalent of `beet … version`'s
   `plugins:` line, and authoritative for the same reason: `_get_plugin` returns `None` for a
   plugin that raised while building. It requires `GET /oauth/identity` to return 200. It names
   every missing environment variable, not just the first.
2. **The wall-clock ceiling is `signal.alarm()`, not a loop-top check**, and the difference is not
   stylistic. `discogs_client` retries a 429 up to `MAX_ATTEMPTS = 100` times with `2**i` jittered
   `time.sleep()` **inside** the library call, so a loop-top check — which only runs between
   folders — cannot interrupt the exact condition it exists to catch. `time.sleep()` *is*
   interruptible by a signal. The handler raises a dedicated `CeilingReached` so the stack unwinds
   through the folder loop's own `finally`, which flushes and `fsync`s stdout; the in-flight folder
   is never appended to `.done`, so a continuation re-probes exactly that one folder.
3. **Emit-then-append at folder granularity**, `snapshot-music-tags.sh:320-325` in Python. A hard
   kill in that window re-emits one folder's records and never loses one. This matters more here
   than in Phase 1: a rate-limited run stalls *invisibly* for hours, the operator will interrupt
   it, and a 24-folder restart burns another 150–260 requests against a 60/min ceiling.
4. **A raising folder goes to `.failed` with its exception class and is never counted as
   "no Discogs candidate".** Conflating an exception with a zero-candidate result would corrupt the
   headline number this phase exists to produce. A folder with zero audio files raises too, rather
   than folding a stale bind mount into the rate.
5. **The probe prints the loose/strict gap itself**, as a count and a percentage, beside the 429
   count, the request count, the `index_tracks` setting and the `search_limit` in force. D-05 and
   the CONTEXT `<specifics>` both make the gap a deliverable; a reader should not have to compute
   it.

**`.planning/phases/03-tagger-spike/03-PROBE-SMOKE.md`** (507 lines) — the A1 verdict, the full
candidate set, the hand-transcribed `beet import -t` list with a six-property agreement table, the
ceiling proof, the write-nothing proof on five instruments, the screening statement, and three
retractions of this plan's own acceptance criteria.

## Results

| Assertion | Result |
|---|---|
| `python3 -m py_compile`, workstation and in-container | **exit 0** both |
| `http.client` / `debuglevel` / `HTTPConnection` in the code, strings and comments stripped | **0 each** |
| `ImportSession` / `importer` / `Library` / `shutil` / `tempfile` / `os.rename` / `os.remove` / `os.chmod` / `os.chown` / `os.makedirs` in the code, stripped | **0 each** |
| Output sites (`write`/`print`/`json.dumps`) emitting a token **value** | **0** — the two that mention a token emit only the variable *name* in a refusal message |
| Token flows in the whole file | exactly **2**: `config["discogs"]["user_token"] = …` and the `Authorization` header |
| `SIGALRM` handler installed, alarm armed, folder loop, `alarm(0)` in the `finally` | lines 814 / 823 / 825 / 890 — **correct order** |
| **Refusal 3** — unset `DISCOGS_USER_TOKEN` | **exit 2**, naming it, **before** any audio file is opened and before either ledger file exists |
| **Refusal 1** — a config whose `plugins:` omits `discogs` | **exit 2**, naming the missing plugin, printing *requested by config* beside *actually loaded* |
| **Ceiling** — `--max-seconds 2` against a 30 s stub sleep | **exit 1 at 2.6 s real**, not 30 s |
| After the abort — NDJSON | valid, `jq -s length` = **1** |
| After the abort — `.done` | **exactly** the one fully-emitted folder; the in-flight folder absent |
| **Resume** | probes **2** (interrupted + unstarted), skips **1**, exit **0**; the two runs' emitted sets union to exactly the 3 requested, each once |
| **Idempotence** — third run, all in `.done` | 0 probed, **0 records**, exit 0 |
| **Preflight** — smoke tree, host vs container | **10 / 10** FLAC and **12 / 12** files, both sides |
| **A1 GATE 1** — `source == "Discogs"` records | **5** — **PASS** |
| **A1 GATE 2** — `source == "MusicBrainz"` records | **5** — **PASS** |
| **A1 GATE 3** — `grep -c 'api\.discogs\.com'` on stderr | **14** — **PASS** |
| D-05 strict, exercised in both directions on one album | 3 Discogs candidates pass (10 tracks = 10 files, extras 0), 2 fail on track count (14 tracks) |
| Real HTTP **429** responses | **0** — `13 × 200`, nothing else |
| `x-discogs-ratelimit` | **60** (used 0, remaining 60) — **A6 re-confirmed independently of 03-04** |
| Discogs requests, one folder | **7**, plus **1** identity probe per run (not per folder) |
| MusicBrainz requests over the same `urllib3` stream | **6**, all `musicbrainz.org` — correctly excluded by the `api.discogs.com` grep |
| **Cross-check** — `beet import -t` candidate count / source set / ordering / score / track count | **AGREE on all five**, row for row; `(1 - distance) × 100` reproduces every displayed % |
| Probe wrote nothing — `find -newer` (files / any) | **0 / 0 lines** |
| Probe wrote nothing — whole-subtree `.meta` and `.sha` manifest diffs | **empty**, both, before vs after **and** before vs final |
| `smoke` mount mode on `beets-spike` | **`RW=false`** |
| `SPIKE_DB` before / after | **byte- and mtime-identical** (`53248`, `1788469035`) — the probe's own in-band proof it opened no library |
| Stray `*.blb` / `library.db` / `*-before-*.bak` outside the throwaway config dir | **0** under both spike roots; elsewhere only the **pre-existing** Phase 1 fence copies |
| The estate's **four** beets databases (DEF-03-02's corrected glob) modified | **0 of 4** — newest mtime `21:17:20`, before the container's `22:24:53` creation |
| `.bak` under `/mnt/fast/appdata` newer than container creation | **0** |
| `bash scripts/check-music-freeze.sh` | **exit 0**, `tagger-class writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` |
| Token value in any artefact (16 files, screened **by value from inside the container**) | **0 hits in all 16** |
| `df -h /` | **35 G free**, unchanged |

## The findings that outlive this plan

**1. The Discogs token is in the QUERY STRING, and criterion 2's own instrument logs it
(DEF-03-04).** T-03-31 reasons that the token is safe under `urllib3` DEBUG because *"it travels in
the `Authorization` header and urllib3 does not log headers"*. Both halves are true and the
conclusion is false: `python3-discogs-client` appends `?token=<value>` to the URL, and
`urllib3.connectionpool` logs the request line. The first smoke run wrote the live 40-character
token to a **`644 root:root`** file on a host running 100+ containers.

This is the same shape as the two findings the phase has already produced — 03-04's *"a `config -d`
block proves nothing"* and 03-05's *"a bind mount pins the inode"*. In each case a control was in
place, was reasoned about correctly, and was **measuring or protecting the wrong thing**.

Fixed at the logging record rather than at the reviewer's memory: a `SecretRedactingFilter` on the
stderr **handler** *and* on the `urllib3.connectionpool` logger, a `RedactingFormatter` covering
rendered tracebacks, and two independent nets — by parameter **name** and by the live secret's
exact **value**. The handler placement is the load-bearing one: a record that *propagates* from a
descendant logger does **not** re-run the ancestor logger's filters, so a logger-level filter alone
would have left the hole open. Post-fix: `token=` appears 7 times and `REDACTED` 7 times.

**2. `grep -c '429'` is not an instrument for HTTP 429, and it fails false against a pre-committed
threshold (DEF-03-05).** On a run with zero rate limiting it returned **3**: the Discogs release ID
`3542996` contains `429` at offset 3, and the probe's own labels `0 x429` and
`discogs 429 responses: 0` match too. `03-07-PLAN.md` repeats the criterion at three lines, where
*"any observed 429"* is one of the two limbs of the **pre-committed T2 threshold** — so a false
positive fires a disqualifier and, under `03-07-PLAN.md:275`, re-runs a cell, burning 150–260
requests, on evidence that a release ID contained three particular digits. The correct instruments
are the HTTP status column (`grep -oE 'HTTP/1\.1" [0-9]{3}'`) and the probe's in-process counter,
which is scoped to `api.discogs.com`.

**3. `plugins.load_plugins()` takes no arguments in beets 2.13.1.** 03-RESEARCH.md's probe sketch
passes `config["plugins"].as_str_seq()` and raises `TypeError`. The function reads
`get_plugin_names()` off `config` itself, which is why `config.set_file()` must come first — and it
is a **no-op once `_instances` is populated**, so it can be called only once per process. Fine for
a one-shot probe; a constraint any later plan embedding this in a longer-lived process inherits.
Checked against the live `inspect.signature`, not assumed.

**4. The two instruments agree exactly, which is what makes the number recordable.** The probe's
`distance` reproduces every one of `beet import -t`'s ten displayed percentages as
`(1 - distance) × 100`, in the same order, with the same source split, and the two candidates
opened by number confirm the track counts: candidate 2 has no *Missing tracks* block against the
probe's `extra_tracks: 0`, and candidate 9 reports `Missing tracks (4/14 - 28.6%)` against the
probe's `n_tracks: 14, extra_tracks: 4`. The specific failure mode 03-RESEARCH.md said was worth
testing for — *"the probe reporting zero candidates where `beet import -t` shows some"* — does not
occur.

**5. `beets` renders `≠ tracks` and `Missing tracks` as different penalties**, on titles/lengths and
on count respectively. Candidates 4 and 5 carry `≠ … tracks …` while the probe reports
`n_tracks == n_files` and `extra_tracks == 0`. Reading `≠ tracks` as a count mismatch would have
produced a false disagreement and stopped the phase on a misreading.

**6. The identity probe is not counted by the request counter, and MusicBrainz is on the same
stream.** The identity probe goes out through `urllib.request`, not `urllib3`, so it emits no
`connectionpool` line — it is **one request per run, not per folder**, and criterion 2's per-folder
figure is 7, not 8. Meanwhile beets' `musicbrainz` plugin *does* use `urllib3`, so the DEBUG stream
carries 6 `musicbrainz.org` lines that `grep -c 'api\.discogs\.com'` correctly excludes but a
`grep -c 'connectionpool'` would not.

## Deviations from Plan

### 1. [Rule 2 — Missing security requirement] The token leaked through the request-counting instrument

- **Found during:** Task 2, on the first smoke run, by the screening step the plan mandates.
- **Issue:** finding 1 above. The plan's T-03-31 mitigation names the wrong channel.
- **Fix:** the two-layer, two-net redaction described above, plus `redact()` before truncating
  every `.failed` detail (`discogs_client` exceptions carry the request URL, and truncating first
  leaves a fragment the exact-value net can no longer match).
- **Contained, and recorded rather than tidied away:** exposure window ~2 minutes; redacted copy
  retained at `600`; original `shred -u -n 3`ed; re-sweep of `/mnt/fast/spike-03/out` returns zero
  files carrying the value; **no committed artefact ever carried it**, proven by a by-value screen
  executed inside the container over all 16 files. **The token was also rendered into the executing
  agent's transcript, which cannot be shredded — it should be rotated.**
- **Fixed the class, not only the instance:** the redaction is generic over credential parameter
  names and over any registered secret value, so the next library that puts a secret somewhere
  unexpected is covered without a code change.
- **Commit:** `0e64d36`

### 2. [Rule 1 — Bug] `plugins.load_plugins()` takes no arguments

- **Found during:** Task 1 verification, on the refusal-1 test.
- **Issue:** finding 3 above. 03-RESEARCH.md's sketch raises `TypeError` immediately.
- **Fix:** called with no arguments, with the measured signature cited inline. The error message
  now prints *requested by config* beside *actually loaded*, because those are different questions
  and a name in the first but not the second is precisely a plugin that raised while building —
  the 03-04 failure this refusal exists to catch.
- **Commit:** `03da9b9`

### 3. [Rule 1 — Bug] Both albums the plan names for the smoke test were already retracted

- **Found during:** Task 2 preparation.
- **Issue:** `03-06-PLAN.md` names `Ed Sheeran - ÷ (2017) FLAC` and `Lady Gaga - The Fame (2008)
  FLAC`. `03-SAMPLE.md` § *The bucket-A and hard-shape candidates* had already measured both: the
  first is **completely empty**, the second holds **one file**. Either would have produced a
  meaningless gate.
- **Fix:** used `03-SAMPLE.md`'s verified `clean-2` slot — Garth Brooks, *Ropin' The Wind*, 10 FLAC,
  flat, single artist, complete album — which satisfies the plan's stated *requirement* (a
  mainstream FLAC album that should match on **both** sources) exactly. Recorded as a retraction in
  `03-PROBE-SMOKE.md`, not a silent substitution.
- **Commit:** `1260f15`

### 4. [Rule 1 — Bug] The plan's 429 acceptance criterion is unsatisfiable

- **Found during:** Task 2, evaluating the gate.
- **Issue:** finding 2 above.
- **Fix:** recorded as an explicit dated retraction in `03-PROBE-SMOKE.md` § *Corrections*, with
  the correct instruments and their output, and logged as **DEF-03-05** so plan 03-07 inherits it
  rather than re-running a healthy cell. The *fact* the criterion reaches for holds and is proven
  by the better instrument: **0 HTTP 429s**.
- **Commit:** `80dacad`

### 5. [Rule 2 — Missing correctness requirement] Exit 1 widened to cover a signal-interrupted run

- The plan states exit `1` = failures **or** the ceiling fired. A SIGINT/SIGTERM stop is neither,
  which would have left a run that probed half its input exiting `0`. That is exactly the silent
  partial success this phase exists to avoid, and it is the shape of the `created`-state blind spot
  in project MEMORY. Widened, and the widening is stated in the header rather than inherited.
- **Commit:** `03da9b9`

### 6. [Method] Every recorded number comes from one clean invocation of the final committed script

- The ceiling test, the resume, the idempotence check and both refusals were first run against a
  pre-redaction build. They were **re-run in full** against the final build rather than carried
  forward — 03-05's standard. The working-tree file, the staged file on LXC 100 and
  `git show HEAD:scripts/spike03-discogs-probe.py` all hash to `0dd5520d…`.

### 7. [Deferred to the orchestrator] Delivery to LXC 100 was out-of-band, and no branch was pushed

Task 1's acceptance criterion asks for the probe to be *"committed **and pushed** to `origin/main`"*,
because `git pull --ff-only` into `/mnt/fast/stacks/scripts` (mounted `:ro` at `/spike-scripts`) is
the delivery path. **A worktree executor cannot push**, and `/mnt/fast/stacks` sits at `c88c268`.
The probe was staged to `/mnt/fast/spike-03/out/` — deliberately **outside** the git checkout, so a
later `git pull --ff-only` is not blocked by an untracked file the incoming commit also adds — and
sha256-verified identical to the committed blob before every recorded run. The criterion is
discharged as **committed**; publication is the orchestrator's. Same deviation and same handling as
plans 03-01, 03-03, 03-04, 03-05 and 03-08.

### 8. [Scope] Two out-of-scope findings logged rather than fixed

**DEF-03-04** and **DEF-03-05** both have implications for `03-07-PLAN.md`'s own text — its threat
register still describes the token as being in the `Authorization` header, and it repeats the
`grep -c '429'` criterion at three lines including a pre-committed threshold limb. Editing another
wave's plan file mid-wave changes what that plan is measured against and makes its result
unattributable, which is the same reason DEF-03-01 and DEF-03-03 were left alone. The defect is
closed where it can do harm — in the code 03-07 will actually run — and the text correction belongs
to whoever executes 03-07.

## Verification that could not be satisfied as written

**Refusal 2 (Discogs identity ≠ 200) was not exercised.** Forcing it requires an invalid token, and
the run's own identity probe returned 200. The code path is a single unconditional `sys.exit(2)` on
`status != 200` with no branch to get wrong. Recorded as **not exercised** rather than claimed —
the "could not look" versus "nothing is wrong" distinction from README § Health Checks.

**A full `/mnt/tank`-wide stray-database sweep did not complete inside the plan's window** (it is
scanning ~1 M entries across 14 TB). The bounded form is what the criterion actually asks about and
it is complete: **0** stray `*.blb` / `library.db` / `*-before-*.bak` anywhere under
`/mnt/tank/downloads/spike-03` or `/mnt/fast/spike-03` outside the throwaway config directory, and
all **four** of the estate's real beets databases unmodified with mtimes predating the container's
creation.

**`tagger-class writers: 0` remains silence rather than a clean reading for one tagger.**
`check-music-freeze.sh` exits 0 with every counter at 0, but its `TAGGER_PATTERN` cannot match
`sabnzbd`, which runs beets as a live post-processing path over the same `nzb/music` tree this
plan's smoke album was copied from — **DEF-03-01**, in the open for the fourth time in this phase.
The decisive attribution is the mount table, not the clock: `beets-spike` holds no mount under
`/mnt/fast/appdata` at any mode.

## Requirements

**TAGR-01 is deliberately NOT marked complete.** This plan builds and gates the instrument the
requirement's numbers will come from; it does not measure a Discogs coverage rate, which is plan
03-07's job. Marking it here would be a false claim on the phase's headline requirement — the same
call 03-05 made and for the same reason.

## Known Stubs

None in the committed artefacts. Three intentional not-yet-used states, all required by the design:

- `--folder-meta` is implemented and **unused** — the smoke run emits `tree: null` and
  `stratum: null` rather than fabricating them. Plan 03-07 supplies the map from `03-SAMPLE.md`'s
  draw table.
- `--folders-from` is implemented and unused; 03-07's 24-folder run is what it exists for.
- `ceiling-stub.py` is a **test fixture**, deliberately not committed to `scripts/` (it is not in
  the plan's `files_modified` and would be an unused file in a repo with none). Its source is
  recorded verbatim in `03-PROBE-SMOKE.md` so the ceiling test is reproducible without it.

## Threat Flags

No new security surface was introduced, but one existing surface was **found to be
mis-characterised** and is flagged rather than folded into the table:

| Flag | File | Description |
|------|------|-------------|
| threat_flag: information-disclosure | `scripts/spike03-discogs-probe.py` (stderr) | The Discogs token is transmitted as a URL **query parameter**, not an `Authorization` header, so any debug logging of request lines is a credential sink. T-03-31 and `03-07-PLAN.md`'s T-03-38 both state the opposite. Mitigated in code; the plan text is DEF-03-04 |

Every disposition in the plan's register was exercised:

| Threat | Outcome |
|---|---|
| T-03-31 (token in debug logs) | **FAILED as written, then held.** The stated mitigation was aimed at headers; the token was in the query string and did leak once. Now held by redaction at the logging record, proven by a by-value screen over 16 files returning 0 |
| T-03-32 (token in argv or a config file) | Held — read from `os.environ` supplied by `env_file`; no `docker exec -e`, no argv element, no committed key. Exactly two flows in the whole file |
| T-03-33 (real beets libraries and the scratch tree) | Held — `config.set_file()` and `config["library"]` set explicitly; **no `ImportSession` is constructed at all**; `SPIKE_DB` byte- and mtime-identical across the run; 0 stray databases; 0 of 4 real databases modified |
| T-03-34 (a wrong headline number) | Held — three refusals, two of them exercised and the third a single unconditional exit; a raising folder goes to `.failed` and is never a zero-candidate record; the A1 gate returned 5 Discogs candidates on a known-good album |
| T-03-35 (the shared 60 req/min budget) | Held — folder-granular resume proven by a real interrupt-and-continue; explicit 429 counter; the `signal.alarm()` ceiling proven to fire at 2.6 s against a 30 s blocking sleep. Total spend this plan: **~15 Discogs requests** |
| T-03-35b (a ceiling abort losing records or corrupting the ledger) | Held — after a forced abort the NDJSON parses, `.done` holds exactly the fully-emitted folder, and the resume probed exactly the interrupted folder plus the unstarted one |
| T-03-36 (`/mnt/tank/media/Music`) | Held — `beets-spike` mounts no path under `/mnt/tank/media`; `check-music-freeze.sh` exit 0 |
| T-03-SC (package installs) | Held — **zero** installs; beets 2.13.1 and `python3-discogs-client` are baked into the image |

One threat-adjacent note that is not a flag: `/mnt/fast/spike-03/out` now also carries the staged
`.py` files, the `smoke*` artefacts and the `test-ceiling*` ledgers, all on LXC 100's ext4 **root**.
`/` is unchanged at 35 G free. Plan 03-11's teardown must remove it.

## Self-Check: PASSED

- `scripts/spike03-discogs-probe.py` — FOUND (980 lines, well above the 220 minimum)
- `.planning/phases/03-tagger-spike/03-PROBE-SMOKE.md` — FOUND (507 lines, contains `Discogs`)
- `.planning/phases/03-tagger-spike/deferred-items.md` — FOUND (modified; DEF-03-04 and DEF-03-05 added)
- `tag_album` in the probe, called as a direct library call and never through the importer — VERIFIED
- `urllib3` in the probe, as the independent request and 429 counter — VERIFIED
- Commit `03da9b9` (`feat(03-06)`) — FOUND
- Commit `0e64d36` (`fix(03-06)`) — FOUND
- Commit `1260f15` (`docs(03-06)`) — FOUND
- Commit `80dacad` (`docs(03-06)`) — FOUND
- Committed blob sha256 == the staged file that produced every recorded run (`0dd5520d…`) — VERIFIED
