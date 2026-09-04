# Phase 3 deferred items

Out-of-scope discoveries made while executing Phase 3 plans. Logged rather than fixed: each is
pre-existing, none was caused by the plan that found it, and each would change a shared script or
a stack this phase is contractually forbidden to edit (D-03).

---

## DEF-03-01 — `check-music-freeze.sh` cannot see a beets run inside `sabnzbd`

**Found by:** plan 03-04, task 2, 2026-09-03.
**Severity:** the phase's primary safety instrument has a blind spot over a *live* tagging path.

`scripts/check-music-freeze.sh:80` classifies tagger containers by name:

```bash
TAGGER_PATTERN='beets|soulbeet|wrtag|lidarr'
```

`sabnzbd` does not match. But sabnzbd runs beets as a post-processing script — a live path, not a
historical one:

| Evidence | Value |
|---|---|
| Post-proc beets config | `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml` (bind-mounted `rw` into the container in its own right) |
| Its beets database | `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb` |
| Its log | `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets.log` |
| Most recent run | **2026-09-03 20:30 UTC**, on `Garth Brooks - Fun (2020) FLAC`, outcome `skip` |
| That run's side effect | migrated `library.blb` and wrote **11 `.bak` files** — Pitfall 1, on a real database |
| sabnzbd's mounts | `/mnt/tank/downloads:rw`; **no `/mnt/tank/media` mount at any mode** |

**What this does and does not mean.** D-20 is **not** violated: sabnzbd cannot reach
`/mnt/tank/media` at all, so nothing here holds `rw` on the library, and
`check-music-freeze.sh` correctly returned `declared rw reaching Music: 0`. What *is* true is that
`tagger-class writers: 0` is reported by an enumeration that structurally cannot observe this
container, so for this one tagger the counter is silent rather than clean. That distinction is
exactly the "could not look" versus "nothing is wrong" rule in README § Health Checks.

It also matters to the project's core value: this is a **tagging path that is running unattended
today**, on the same `complete/nzb/music/` tree Phase 3 is sampling from. The `skip` outcomes in
`beets.log` name folders plan 03-03 selected as D-10 album candidates (`Garth_Brooks-Ropin_The_Wind`,
`Def.Leppard-CD.Collection`, `Ed.Sheeran-Play.Extended.Edition`).

**Why not fixed here.** `scripts/check-music-freeze.sh` is a shared harness folded into
`quick-health-check.sh`; widening `TAGGER_PATTERN` changes the pass/fail behaviour of every future
run in every plan of this wave, and plan 03-04's scope is standing up a measurement container.
Changing a shared assertion mid-wave, on a plan that did not cause the finding, is the kind of
edit that makes a later result unattributable.

**Suggested fix (Phase 4, alongside TAGR-03/TAGR-04):** classify by *behaviour* rather than by
container name — a container is tagger-class if it mounts a beets/wrtag config or database path,
not if its name matches a regex. At minimum, add `sabnzbd` to `TAGGER_PATTERN` and assert on the
mtime of all **four** beets databases, not on name matching.

---

## DEF-03-02 — the before-state instrument must glob `*.blb`, not just `library.db`

**Found by:** plan 03-04, task 2, 2026-09-03.
**Severity:** low, already corrected inside 03-04; recorded so later plans inherit the fix.

Plan 03-04's acceptance criterion reads *"the mtime of every `library.db` under `/mnt/fast/appdata/`
is unchanged"*. That glob finds **two** of this estate's **four** beets databases. The other two
are named `.blb`:

```
/mnt/fast/appdata/arrs/beets/config/musiclibrary.blb
/mnt/fast/appdata/arrs/beets/config/library.db
/mnt/fast/appdata/arrs/sabnzbd/config/.config/beets/library.db
/mnt/fast/appdata/arrs/sabnzbd/config/scripts/library.blb      <- migrated 20:30, invisible to the glob
```

Four is consistent with Phase 1 plan 01-02's count; no new database has appeared. But the criterion
as written would have passed while a real beets database was being migrated three directories away.

**Inherited fix for plans 03-05 .. 03-11:** capture and compare
`find /mnt/fast/appdata \( -name '*.blb' -o -name 'library.db' \)`, and compare against the spike
container's `.Created` timestamp rather than against a wall-clock window — a window cannot
distinguish "this plan did it" from "something else did it while this plan ran".

---

## DEF-03-03 — `audio_md5` is not tag-invariant, and the whole tag-diff harness joins on it

**Found by:** plan 03-05, task 3, 2026-09-03.
**Severity:** the QUAL-02 gate Phase 7 depends on can report file-level loss where none occurred.

`scripts/snapshot-music-tags.sh:292` computes the join key as:

```bash
ffmpeg -nostdin -v error -i "$f" -map 0:a -c copy -f md5 -
```

`snapshot-music-tags.sh:35` states the claim outright — *"THE KEY (D-01):
`ffmpeg -map 0:a -c copy -f md5 -` hashes the **ENCODED AUDIO BITSTREAM ONLY**"* — and
`diff-music-tags.sh:8-13` builds on it: *"Only a key computed over the encoded audio bitstream
matches across that move and rename."* **The key is not computed over the encoded audio bitstream
only.** For some MP3 files, ffmpeg's mp3 demuxer emits the trailing 128-byte **ID3v1** block as part
of the `-c copy` stream, so an ID3v1 edit moves the key.

Measured on this plan's 335-file sample, on a write that touched **only** `album` and `artist` in
ID3v2:

| Evidence | Value |
|---|---|
| Files whose `audio_md5` moved | **37 of 335** |
| Of those 37, how many carry a trailing ID3v1 tag | **37** |
| Of those 37, how many do not | **0** |
| Files in the sample carrying an ID3v1 trailer at all | **235 of 335** |
| Differing bytes in the AUDIO region (`cmp` vs the untouched `raw/` twin) | **0**, every file examined |
| Audio payload byte-identical with ID3v2 tag and last 128 bytes excluded | **True**, every file examined |
| Decisive test — same md5 with the last 128 bytes removed? | **YES** on every moved file |
| What `diff-music-tags.sh` reported | `MISSING_AFTER: 37`, `NEW_AFTER: 37`, `FIELDS_DROPPED: 0`, **exit 1** |

So the tool reported **37 files lost** on a run that lost nothing at all. Note the asymmetry that
makes this dangerous rather than merely noisy: it fails **loud and wrong** here, but the same
property means a real tag-only corruption on an ID3v1-bearing file lands in `MISSING_AFTER`/
`NEW_AFTER` rather than in `FIELDS_DROPPED`, where the gate actually looks. Only **235 of 335**
files in this one sample carry an ID3v1 trailer, so the behaviour is per-file, not global — the
harness passes and fails on the same tree depending on which files were edited.

It is also not confined to this plan. `03-SAMPLE.md` § *De-duplication proof* keys the entire
`dj-mixes` ↔ `unsorted` disjointness argument on `audio_md5`, and plan 03-07 carries a
per-`audio_md5` cross-check beside its folder-weighted estimator. Both are sound **as long as
nothing writes a tag between the two readings** — which is exactly the condition Phase 7 will not
enjoy.

**Worked around inside plan 03-05, not fixed.** `normalise-dj-tags.py` now restores the ID3v1 block
byte-for-byte after every write (`preserve_id3v1_trailer()`), which makes the key stable for this
plan's write and makes "touch nothing else" true at the byte level. The verdict was additionally
recomputed **path-keyed** — valid here because this plan moves and renames nothing — and agreed:
335 matched, 0 missing, `FIELDS_DROPPED = 0`.

**Why not fixed here.** `snapshot-music-tags.sh` and `diff-music-tags.sh` are the shared Phase 1
harness, D-03 freezes them for this phase, and every other plan in this wave asserts against their
current behaviour. Changing the key definition mid-wave would make every result in the wave
unattributable — the same reason DEF-03-01 was left alone.

**Suggested fix (Phase 7, alongside the QUAL-02 gate):** compute the key over the audio with any
trailing ID3v1/APE/Lyrics3 block excluded — the simplest correct form is to feed ffmpeg the file
with the last 128 bytes removed when they begin `TAG`, or to switch to
`ffmpeg -map 0:a -f md5` over the *decoded* stream, which is tag-invariant by construction at the
cost of decode time. Whichever is chosen, add a regression test: edit only `album` on an
ID3v1-bearing MP3 and assert the key does **not** move.

---

## DEF-03-04 — the Discogs token is in the QUERY STRING, not the `Authorization` header

**Found by:** plan 03-06, task 2, 2026-09-03.
**Severity:** the phase's threat model names the wrong channel, so a mitigation reasoned about
correctly still leaked a live credential to a `644` file.

`03-06-PLAN.md` T-03-31 and `03-07-PLAN.md` T-03-38 both rest on this sentence: *"the Discogs
token travels in the `Authorization` header; `urllib3` DEBUG does **not** log headers"*. **Both
halves are true and the conclusion is false.** `python3-discogs-client` does not use an
Authorization header for a user token — it appends `?token=<value>` to the request URL, and
`urllib3.connectionpool` logs the full request line at DEBUG:

```
DEBUG urllib3.connectionpool https://api.discogs.com:443 "GET /releases/3542996?token=REDACTED HTTP/1.1" 200 None
```

So **criterion 2's independent request-counting instrument is also a credential sink.** On the
first smoke run it wrote the live 40-character token, in cleartext, to `smoke.stderr` at
`644 root:root` on a host running 100+ containers. Contained the same day: redacted copy retained
at `600`, original `shred -u -n 3`ed, re-sweep returns zero files, and no committed artefact ever
carried the value. **The token should be rotated** — it was also rendered into the executing
agent's transcript, which cannot be shredded.

**Fixed inside plan 03-06, at the logging record rather than at the reviewer's memory.**
`scripts/spike03-discogs-probe.py` carries a `SecretRedactingFilter` on **both** the stderr handler
and the `urllib3.connectionpool` logger, a `RedactingFormatter` covering rendered tracebacks, and
two independent nets (by parameter **name**, and by the live secret's exact **value**). The handler
is the load-bearing placement: a record that *propagates* from a descendant logger does **not**
re-run the ancestor logger's filters, so a logger-level filter alone leaves the hole open.

**Inherited by plans 03-07, 03-10 and 03-11**, which run this same probe and therefore get the fix
for free — but whose own text still needs correcting:

- `03-07-PLAN.md:443` describes the trust boundary as *"the token is in the `Authorization`
  header"*. It is not. The screening instruction in T-03-38 (screen for `Authorization` **and** for
  the token value) is still right, and it is the token-value half that does the work.
- Any later plan that captures `urllib3` DEBUG from a Discogs-authenticated process must either run
  it through this probe's redaction or screen the output for `token=` before quoting **or
  committing** it. Screen by **value**, from inside the container, printing only counts — a
  verification command that echoes the token to compare it is the exact lapse plan 03-04 recorded.

**Why not fixed in those plans here.** Editing another wave's plan file mid-wave changes what that
plan is measured against and makes its result unattributable — the same reason DEF-03-01 and
DEF-03-03 were left alone. The defect is closed where it can do harm (the code); the text
correction belongs to whoever executes those plans.

---

## DEF-03-05 — `grep -c '429'` is not an instrument for HTTP 429

**Found by:** plan 03-06, task 2, 2026-09-03.
**Severity:** low individually, but it is a **pre-committed T2 threshold limb**, so a false
positive would fire a disqualifier on a healthy run.

`03-06-PLAN.md` requires `grep -c '429' smoke.stderr` to return **0**, and `03-07-PLAN.md` repeats
it at lines 275, 333 and 414 — where *"any observed 429 during the 20-folder run"* is one of the
two limbs of the **pre-committed T2 threshold**. On a run with **zero** rate limiting the bare
substring grep returned **3**:

| Match | Why |
|---|---|
| `GET /releases/3542996?...` | the Discogs **release ID** `3542996` contains `429` at offset 3 |
| `... 0 x429)` | the probe's own per-folder progress line |
| `discogs 429 responses:        0` | the probe's own summary label |

The failure direction matters: it fires **false positive**, and the thing it would falsely fire is
a threshold committed before the run. Under `03-07-PLAN.md:275` the affected cell would be re-run
— burning 150-260 requests against a 60/min ceiling — on evidence that a release ID contained three
particular digits.

**The correct instruments, both already available:**

```bash
# 1. the HTTP status column, not a substring anywhere on the line
grep -oE 'HTTP/1\.1" [0-9]{3}' <stderr> | sort | uniq -c      # smoke run -> 13 x 200, nothing else

# 2. the probe's own in-process counter, printed in the summary block
#    discogs 429 responses:        0
```

The probe's counter parses the status code out of each `urllib3` response line and counts `429`
specifically, scoped to `api.discogs.com` — so it also does not confuse a `musicbrainz.org` line
for a Discogs one, which the plan's `grep -c 'api\.discogs\.com'` request counter correctly does
not either, but a `grep -c 'connectionpool'` would.

**Why not fixed here.** Same reason as DEF-03-04: 03-07's acceptance criteria are what 03-07 is
measured against.

**CLOSED by plan 03-07, 2026-09-04, with the failure demonstrated at full scale.** The substitution
was applied. On six cells the bare form returned **25 every time — including the two MB-only cells
that issued zero Discogs requests** — against a true count of **0 HTTP 429** on both correct
instruments. Recorded as a dated amendment in `03-DECISION.md` § *AMENDMENT — 2026-09-04*.

---

## DEF-03-06 — `grep -c 'api\.discogs\.com'` over-counts Discogs requests exactly 2×

**Found by:** plan 03-07, task 2, 2026-09-04.
**Severity:** low, corrected in place; recorded because it is named in **T2's own `Instrument`
column** in `03-DECISION.md` and will be inherited by any later plan that re-reads it.

T2's cross-check instrument is *"`grep -c 'api\.discogs\.com'` on the probe stderr (`urllib3`
DEBUG)"*. `urllib3` emits **two** lines mentioning the host per request:

```
DEBUG urllib3.connectionpool Starting new HTTPS connection (1): api.discogs.com:443
DEBUG urllib3.connectionpool https://api.discogs.com:443 "GET /database/search?...  HTTP/1.1" 200 None
```

So on the headline cell the bare form returns **150** where the probe's in-process counter — which
parses the status code and is scoped to `api.discogs.com` — returns **75**. The two "independent
instruments" T2 requires therefore disagree by a factor of two, and the naive one inflates the
request extrapolation and the API-floor minutes accordingly.

**The correct form, which reproduces the in-process counter exactly:**

```bash
grep -cE 'api\.discogs\.com.*HTTP/1\.1"' <stderr>     # -> 75, matching the probe
```

This also explains why the measured **M = 3.125** requests per folder sits so far below
03-RESEARCH.md's predicted 6–11: the prediction was sound, and 03-06's smoke measurement of 7 for
one folder was correct, but a folder whose search returns nothing costs **one** request with no
release fetches behind it, and this backlog has many of those.

**Suggested fix (Phase 4, or whoever re-reads T2):** quote the restricted form wherever the bare
one appears, and prefer the probe's own counter, which cannot confuse a connection with a request
or a `musicbrainz.org` line with a Discogs one.

---

## DEF-03-07 — MusicBrainz signals rate limiting with HTTP 503, not 429

**Found by:** plan 03-07, task 1, 2026-09-04.
**Severity:** medium for any later plan that watches for 429 as its rate-limit signal — it will
report a clean run while MusicBrainz is throttling it.

Every Discogs cell in plan 03-07 logged HTTP 503 responses, and **every one of them came from
`musicbrainz.org`; zero came from `api.discogs.com`**:

| Cell | 200 | 503 | All 503s from |
|---|---|---|---|
| `raw-mbdiscogs` | 216 | 13 | `musicbrainz.org` |
| `normalised-mbdiscogs` (headline) | 213 | **44** | `musicbrainz.org` |
| `raw-mbdiscogs-it` | 216 | 26 | `musicbrainz.org` |
| `normalised-mbdiscogs-it` | 219 | 28 | `musicbrainz.org` |
| `raw-mb` | 144 | 14 | `musicbrainz.org` |
| `normalised-mb` | 144 | 28 | `musicbrainz.org` |

**Two consequences that outlive this plan:**

1. **It is the dominant term in the wall-clock.** Projected wall-clock for the backlog is 21.8
   minutes against a pure-Discogs-API floor of 7.43 minutes — a ~3× gap, and MusicBrainz backoff is
   most of it. T2's 4-hour limb is nowhere near either figure, so nothing is at stake *here*; a
   phase that actually imports the backlog will feel it.
2. **It produced the only cross-check disagreement in this plan.** Two of the five hand-read
   `beet import -t` folders returned a different *MusicBrainz* candidate set from the probe, because
   the probe collected its set while MusicBrainz was returning 503s and the cross-check ran later.
   The Discogs half — the half T1 is computed from — agreed on 5 of 5.

**Why not fixed here.** Nothing to fix in this phase: T2 names 429 explicitly and Discogs returned
none, so the threshold is answered as written. This is a note about the *signal*, logged so a later
plan does not build a rate-limit guard that only ever looks for 429.

**Suggested fix (Phase 6/7, when bulk import is real):** treat `503` from `musicbrainz.org` and
`429` from `api.discogs.com` as the same class of event, and count both.

---

## DEF-03-08 — D-05's strict rule admits confident wrong matches

**Found by:** plan 03-07, task 1, 2026-09-04.
**Severity:** the phase's headline metric is an upper bound on the thing it is read as measuring.

D-05 defines a strict match as *a Discogs candidate appears AND its track count agrees with the
folder AND `extra_items == 0` AND `extra_tracks == 0`*. It does **not** require the candidate to be
the right release. Reading every strict-satisfying candidate on the headline cell:

| Folder | Queried `album` | Discogs release that satisfied D-05 | Confidence | Correct? |
|---|---|---|---|---|
| `Mastermix_Issue_410` / `_410.1` | `Mastermix Issue 410` | `32813244` *Mastermix Issue 410* | 75.6% | yes |
| `VA-Mastermix.Issue.426-2021` / `.1` | `Mastermix Issue 426` | `25298851` *Mastermix Issue 426* | 64.3% | yes |
| `VA-Mastermix.Issue.427.2CD-2021` | `Mastermix Issue 427` | `32816841` *Mastermix Issue 427* | 59.6% | yes |
| **`Mastermix_Issue_412`** | **`Issue 412`** | **`1534659` *Specialten Issue 14*** | **31.2%** | **NO** |

**One of six.** A 2006 Specialten DVD matched a Mastermix issue because both carry ten tracks —
precisely the outcome `CLAUDE.md` § *Autotagging ceiling* calls worse than no match.

The weighted rate is **27.08%** on D-05 as written and **22.80%** on "strict and correct". **T1
fires on both**, so the phase's verdict does not turn on this — but any later plan that reads
27.08% as "27% of the backlog will autotag correctly" is reading it wrong.

**The proximate cause is a stratum definition, not the rule.** `Mastermix_Issue_412`'s album tag is
the bare string `Issue 412`. It is classified **V1** — "already the good case" — so no normalisation
rule fired on it, and `Issue 412` is a hopelessly generic Discogs query. This is the same defect
class 03-SAMPLE.md found when it reclassified `album == artist` out of V1: **V1 admits album
strings that are clean but identify no release.**

**Why not fixed here.** D-05 is a pre-committed definition inside the threshold commit; changing it
mid-phase is exactly the goalpost move criterion 5 exists to prevent. The correct-match reading is
reported *beside* the D-05 reading instead.

**Suggested fix (Phase 4):** extend the V1 test to require the album string to contain the label
*and* an issue number, so `Issue 412` normalises to `Mastermix Issue 412` under rule 2 rather than
being exempted as already-clean. A confidence floor near 50% would also have separated all six
cleanly in this sample — every correct match scored ≥ 59.5% and the wrong one 31.2% — but that is a
one-sample observation, not a calibrated threshold.
