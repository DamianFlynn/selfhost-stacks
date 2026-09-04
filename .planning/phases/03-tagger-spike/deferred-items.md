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

---

## DEF-03-09 — `normalise-dj-tags.py`'s non-MP3 write path cannot write WAV, on any file

**Found by:** plan 03-09, task 1, 2026-09-04.
**Severity:** the tool D-13 has just named as *the* normalisation tool cannot write 3.2% of the
estate's audio. It fails **loudly**, which is why this is a gap rather than an incident.

`scripts/normalise-dj-tags.py:426` and `:547-549` are the non-MP3 path:

```python
handle = mutagen.File(path, easy=True)      # read_tags()
...
handle.tags[field] = [new]                  # write_tags()
handle.save()
```

**For a WAVE, `easy=True` does not yield an EasyID3-style mapping.** `handle.tags` comes back as a
raw `mutagen.id3.ID3` object keyed by **frame id** (`TALB`, `TPE1`, …), so `handle.tags["album"] =
["…"]` assigns a list where a `Frame` is required. Measured over all **134** WAV files in
`dj-mixes`:

| Evidence | Value |
|---|---|
| Files attempted | **134** |
| Files written | **0** |
| Failures | **134**, every one `TypeError: [...] not a Frame instance` |
| Files changed on disk | **0** — empty whole-subtree `.sha` manifest diff |
| What `diff-music-tags.sh` reported | `FIELDS_DROPPED 0`, `MISSING_AFTER 0`, **exit 0** — a **vacuous pass** |
| Also read-broken | `read_tags()` returns `album=None` for the 87 WAV that *do* carry an album, for the same reason |

**It is a defect in this script, not a limitation of mutagen.** Writing the same value through
mutagen's correct WAVE API succeeded on the first attempt on three probe copies — one untagged, one
ASCII-tagged, one with a non-ASCII `TPE1` — preserving `APIC`, `TDRC`, `TIT2`, `TPE1` and `TRCK`
each time:

```python
w = mutagen.wave.WAVE(path)
if w.tags is None:
    w.add_tags()
w.tags.setall("TALB", [mutagen.id3.TALB(encoding=3, text=[new])])
w.save()
```

**One further question the fix must answer, found in the same probe:** mutagen's WAVE write leaves
the RIFF `LIST`/`INFO` chunk **byte-identical**, so its `IPRD` (product/album) keeps the *old* album
while the ID3 tag carries the new one — two containers in one file disagreeing. wrtag's `metadata`
updates both. Decide deliberately which behaviour is wanted rather than inheriting one.

**Why not fixed here.** 03-09's scope is the D-13 bake-off, and the WAV result **is** one of its two
headline measurements. Editing the tool mid-comparison would have made that measurement
unattributable — the same reason DEF-03-01, DEF-03-03 and DEF-03-05 were left alone. The failure is
also loud (134 records in the `.failed` ledger, exit 1) rather than silent, so nothing depends on
fixing it before the phase closes.

**Scope, so the fix is not over-sized.** 268 of the estate's 8,492 audio files are WAV (**3.2%**),
in six folders across two trees, all of it `Now That's What I Call Music` 118/119/120. **None of it
is content the three committed rules fire on** — a dry run over all 134 reports `files that would
change: 0`, because rules 1 and 3 need a Mastermix/DMC label token in the folder name. So the fix is
needed for a *future* job, not for the DJ backlog this phase exists to work.

**Suggested fix (Phase 4, alongside TAGR-04):** branch `read_tags()`/`write_tags()` on WAVE
explicitly rather than relying on `easy=True`, add the `LIST`/`INFO` decision above, and add a
regression test that writes `album` to an untagged WAV, an ASCII-tagged WAV and a non-ASCII-tagged
WAV and asserts the value reads back with every other frame intact.

---

## DEF-03-10 — the field-loss gate answers a narrower question than "did the tool do what was asked"

**Found by:** plan 03-09, tasks 1 and 2, 2026-09-04. **Third occurrence in this phase.**
**Severity:** medium for Phase 7's QUAL-02 gate, which is `diff-music-tags.sh`'s exit code.

`diff-music-tags.sh` detects **field loss**, and it does that correctly. It is repeatedly being read
as if it detected *wrongness*. Three writes in this phase scored `FIELDS_DROPPED = 0` while doing
something nobody asked for:

| Write | What it did | What the gate said |
|---|---|---|
| 03-05, first `--apply` | mutagen's load-time `v2_version=4` translated `TYER` → `TDRC` on real files | **nothing** — `ffprobe` maps both to `date` |
| 03-09, `metadata` arm | promoted **205** files ID3v2.3 → v2.4, `TYER` → `TDRC` on **155**, rewrote **175** ID3v1 blocks, **created 30**, re-serialised **14** APEv2 tags | `FIELDS_DROPPED 0` on both joins |
| 03-09, driver run 1 | wrote the **artist value into the album field** on **20 of 205** files | `FIELDS_DROPPED 0` — a clean pass on a wrong result |

The third is the sharpest: a **correct-shaped wrong value drops no field**, so no field-loss gate can
ever see it. It was caught only by diffing the two arms' after-states against each other.

`ffprobe` is also blind to two whole containers on MP3 — the **ID3v1** trailer (which surfaces
instead as a moved join key, DEF-03-03) and any **APEv2** tag (invisible entirely; this sample has
14 APE-bearing files).

**Why not fixed here.** `diff-music-tags.sh` and `snapshot-music-tags.sh` are the shared Phase 1
harness, frozen by D-03, and every plan in this wave asserts against their current behaviour.

**Suggested fix (Phase 7, alongside QUAL-02):** keep the gate as the loss detector it is, and pair
it with a second assertion that the set of changed (file, field, value) triples **equals the set the
tool proposed** — which is exactly what `normalise-dj-tags.py`'s own dry-run NDJSON already provides
and what a blind tool structurally cannot. Add the on-disk ID3v2 frame-ID multiset comparison
against an untouched twin (03-05, re-used here) as the third instrument; it is the only one of the
three that saw the ID3v2.4 promotion.

---

## DEF-03-11 — `check-music-freeze.sh` run from the workstation reports a green summary while blind

**Found by:** plan 03-10, task 2, 2026-09-04.
**Severity:** medium. It fails closed today, but for a reason unrelated to what it prints.

The plan's acceptance criteria say to run `bash scripts/check-music-freeze.sh` and confirm
`tagger-class writers: 0` and `declared rw reaching Music: 0`. Run **from the macOS workstation**,
where `/mnt/tank`, `/mnt/fast/safety` and docker are all absent, it prints exactly that:

```
  [0;34m0 running containers, 0 mounts enumerated
  tagger-class writers:        0   (target 0)
  declared rw reaching Music:  0   (target 0, jellyfin.yaml excluded)
```

Both target counters read green **because nothing could be looked at**. The same run on LXC 100
enumerates a real container set and returns `consumer-class writers: 1` (Jellyfin, D-21).

**It does fail closed** — it exits 1 on the five missing fence assertions, and section 4 prints a
red `/mnt/tank/media/Music not present on this host`. So the script honours README § *Health
Checks* rule 1 overall. **The defect is narrower and is about how it will be read**: the § 7
summary block, which is the part a reader copies into a plan record, contains no indication that
sections 1 and 2 were unobservable. A future plan that greps the summary for
`declared rw reaching Music:  0` and records a pass will record a pass it did not measure — and
D-20 is the constraint being asserted.

**Why not fixed here.** `check-music-freeze.sh` is the shared Phase 1 harness, frozen by D-03, and
every plan in this wave asserts against its current behaviour.

**Suggested fix (Phase 7):** make section 1 distinguish "0 rw holders" from "docker unavailable",
and have the § 7 summary print counters as `UNKNOWN` rather than `0` whenever their input was
unobservable — the same "could not look is not nothing is wrong" rule the README already states,
applied to the summary block and not only to the exit code.

---

## DEF-03-12 — both spike compose files share one compose project, and compose offers to delete the other arm

**Found by:** plan 03-10, task 2, 2026-09-04. **Fixed for this file; the hazard is generic.**

Compose derives the project name from the compose file's directory when none is given. Both
`03-spike-beets.yaml` (terminal arm) and `03-spike-beets-flask.yaml` are run from
`/mnt/fast/spike-03`, so they shared the project `spike-03`. The first `up` of the flask file
printed:

```
level=warning msg="Found orphan containers ([beets-spike]) for this project.
 If you removed or renamed this service in your compose file, you can run this command
 with the --remove-orphans flag to clean it up."
```

`beets-spike` **is the terminal arm** — half of the axis-two experiment. Compose was suggesting a
flag that would delete it, in a message that reads like routine tidying.

**Fixed** in `03-spike-beets-flask.yaml` by an explicit `name: spike-03-beets-flask`, verified: the
warning is gone and `beets-spike` survived the recreate.

**Not fixed** in `03-spike-beets.yaml`, which is a frozen artefact of the earlier plans in this wave
and is asserted against by their records.

**Carry into plan 03-11 (teardown):** never pass `--remove-orphans` to either spike compose file.
With the explicit project name the flask file can no longer reach the terminal arm, but the
terminal arm's file can still reach anything else that ever ran unnamed from that directory.

---

## DEF-03-13 — beets-flask rc6's import page has no error boundary around its cover-art fetch

**Found by:** plan 03-10, task 3 (the operator's trial), 2026-09-04.
**Severity:** high for any adoption of rc6 — **the interactive picker cannot be relied on to
import.** This is an upstream defect, not a configuration error.

The candidate-selection page crashes to a full-page *"Unexpected Error"* with
`Error Type: TypeError`, `Message: Load failed` (Safari) / `Failed to fetch` (Arc/Chrome), and
`Stack Trace: No stack trace available`. `RETRY` merely navigates back one page. **Reproduced on
two albums (Garth Brooks, Lady Gaga) across two browsers.**

**The backend logged zero errors** — `docker logs beets-flask-spike | grep -icE
"error|traceback|exception"` returned **0** across the whole container lifetime. So nothing
server-side will ever alert on it.

**Root cause established, not inferred.** The DevTools initiator chain is
`art?url=…` → `front-250` → `mbid-<uuid>-…`. rc6 does **not proxy the image bytes**: it
*redirects the browser out* to third-party hosts (`coverartarchive.org`, which redirects again to
`ia*.us.archive.org`). The page is served from `http://127.0.0.1:5002` and `fetch()`es those
hosts, which is **CORS-blocked** — hence a failed status, a `TypeError`, and no server log.
Confirmed by asymmetry: calling the same proxy endpoint **from inside the container** returned
**HTTP 200, 3516 bytes** for both MusicBrainz and Cover Art Archive URLs, and container egress to
`coverartarchive.org` / `musicbrainz.org` / `api.discogs.com` is HTTP 200 in ~0.2–0.3 s.

**It is a missing rejection handler, not a missing fallback.** rc6 *does* ship a
`missing_cover-C8vp4wkz.webp` placeholder and renders it correctly for genuinely absent art. A
cosmetic thumbnail failure takes down the entire import page.

**Intermittent, which is the worse finding.** Later attempts held, with some art fetches succeeding
(`blob:http://127.0.0.1:5002/…`) alongside a pile of red failures. **An operator cannot tell in
advance whether a given run is safe.** The ergonomics cost, in the operator's own words:
*"this is what i see if i move fast"* — the diff modal had to be read by outrunning the crash.

**Why not fixed here.** It is a defect in a third-party release candidate's frontend, not in
anything this repository owns, and Phase 3 decides *whether* to adopt beets-flask rather than
patching it. Fixing it would also have altered the tool mid-trial and made the measurement
unattributable.

**Suggested action (plan 03-11, then whoever revisits beets-flask):** record it as an axis-two
finding against adoption, and if beets-flask is ever reconsidered, file it upstream and require a
release in which the art fetch is **proxied server-side** (or wrapped in an error boundary) before
pointing it at content that matters.

---

## DEF-03-14 — beets accepted a 75% match that dropped 9 files and mis-tagged 4 tracks, and the UI asserted nothing was missing

**Found by:** plan 03-10, task 3, 2026-09-04.
**Severity:** the highest-consequence finding in the phase. **This is D-05's confident-wrong-match
at *track* level.**

`hard-flat-multidisc` (Lady Gaga — *Born This Way: The Collection*) was imported at the highest
offered match, **75%**. Verified on disk at the time and **re-verified independently at plan
close**:

| Evidence | Value |
|---|---|
| Source audio files | **31** |
| Imported audio files | **22** |
| Silently dropped, no warning | **9** |
| Tracks written onto a different song | **4** |

The four titles beets wrote — `Born This Way (The Country Road version)`,
`Judas (DJ White Shadow remix)`, `Marry the Night (Zedd remix)` and
`Fashion of His Love (Fernando Garibay remix)` — **exist nowhere in the 31-file source folder.**
Their durations identify what the audio actually is:

| Imported as | Duration | Audio actually is | Source duration |
|---|---|---|---|
| `18 Born This Way (The Country Road version)` | 245.41 s | `Born This Way (Twin Shadow Remix)` | 245 s |
| `19 Judas (DJ White Shadow remix)` | 237.56 s | `Judas (Hurts Remix)` | 238 s |
| `20 Marry the Night (Zedd remix)` | 243.71 s | `Marry The Night (The Weekend & Illangelo Remix)` | 244 s |
| `22 Fashion of His Love (Fernando Garibay remix)` | 230.84 s | `You And I (Wild Beasts Remix)` | 231 s |

The last row is a **different song entirely**. The embedded `title` tags carry the wrong names, so
**the error is written into the files, not just into the paths.**

**On that same screen the UI asserted *"All tracks on disk found online"* AND *"All tracks online
present on disk"*. Both false.** An interface that states a falsifiable safety claim and gets it
wrong is worse than one that says nothing.

**Cause is the folder shape**, not a general defect: two releases (`Born This Way` 17 tracks +
`Born This Way: The Remix` 14 tracks) flattened into one directory. beets matched a 22-track
edition, took 17 + 5, mis-mapped those 5 and discarded 9.

**Bounded, not endemic — verified on the other three albums:** Taylor Swift 21→21, Garth Brooks
10→10 (2 non-audio correctly ignored), Now 116 47→47 (3 non-audio correctly ignored). **Zero
dropped.** The failure is specific to the flattened-two-releases shape, which is exactly why
`hard-flat-multidisc` was in the D-10 draw.

**Worse than 03-07's `Mastermix_Issue_412` → Specialten DVD (DEF-03-08),** because there the whole
album was obviously wrong, whereas here **17 of 22 tracks are perfect, so nothing looks amiss.**

**Why not fixed here.** Nothing to fix in this phase — it is a measured behaviour of the engine on
a known-hard folder shape, and it is one of the trial's two headline results.

**Suggested fix (Phase 6/7, alongside the import gate):** before accepting any album import, assert
**source audio count == imported item count** and fail closed on a mismatch. `CLAUDE.md` already
says *"never accept a match without a track-count check"*; this is that rule at file granularity,
and it is the only instrument that would have caught this. Add a duration cross-check per track
where the source carries one — it is what identified the mis-mapping here.

---

## DEF-03-15 — `DELETE IMPORTED FOLDERS` is keyed on a badge that does not mean what it reads as

**Found by:** plan 03-10, task 3, 2026-09-04.
**Severity:** high — a one-click bulk destructive action gated on an unreliable signal.

beets-flask's per-folder import-state badges (`Tagged` / `Imported`) are persistent and per-folder,
and are genuinely **the best resume signal either arm offers** — directly mitigating the
abandoned-halfway failure mode this project exists to prevent.

**But the Lady Gaga folder was badged `Imported` while being 9 audio files short and 4 tracks
mis-titled** (DEF-03-14). `DELETE IMPORTED FOLDERS` is a **one-click bulk destructive action whose
only signal is that badge.** Pressing it would have destroyed the only intact copy of the 9 dropped
tracks.

A second instance of the same shape: **`IMPORT BEST`** is a one-click bulk import of "best"
candidates with **no per-album review**, reachable from the inbox list — on a collection where
03-07 measured a **1-in-6 wrong-strict-match rate**.

**Why not fixed here.** Upstream UI behaviour in a throwaway RC container; and plan 03-11 owns
teardown. **Neither button was pressed or scripted at any point in this plan**, deliberately.

**Suggested action:** if beets-flask is ever adopted, treat `Imported` as *"an import ran"* and
never as *"the import was complete and correct"*, and gate any deletion on the file-count assertion
in DEF-03-14 rather than on the badge. Do not use `IMPORT BEST` on this collection at all.

---

## DEF-03-16 — `bootleg`'s outcome is decided by whether `album` is populated, with no UI signal either way

**Found by:** plan 03-10, tasks 2 and 3, 2026-09-04.
**Severity:** medium-high. The affordance is excellent and completely unguarded.

`autotag: "bootleg"` produced **the best single result either arm produced** on
`VA-Mastermix.Crate.068-070-2025` — a folder 03-07 measured at **zero** strict Discogs candidates.
One `mv`, zero candidate decisions, *"Imported 39 seconds ago"*. Re-verified on disk at plan close:

| Check | Result |
|---|---|
| Albums created | **3** — Crate 068 / 069 / 070, **20 files each** |
| Embedded cover art (`APIC`) | **60 / 60** |
| `TBPM` | **60 / 60** |
| `TALB` / `TCON` | **60 / 60** each; genre correct per crate |
| **`TRCK` (track number)** | **0 / 60 — absent, not zero** |
| Operation | `COPY`; source intact at 60 mp3 |

**Two caveats, both verified.** There is **no `track` tag at all**, so playback order is undefined
— the source has none and `-A` faithfully preserved none. And `album.nfo` was not carried across
(destination is audio-only); not a loss, the source retains it.

**The sharp edge:** the same button shredded `VA-Mastermix.Crate.071.Afro.House-2025` into **twenty
single-track albums** in Task 2, because that folder's `album` tag was **empty**. `--group-albums`
groups on the metadata that is *there*. **The only difference between the two outcomes is whether
`album` is populated, and nothing in the UI distinguishes the cases before the operator commits.**

**Why this is not a niche case:** sampling 12 Mastermix folders' embedded `album` tags, **~40%
carry the bare, useless `album=Mastermix`**, which identifies no release — precisely 03-03's
reclassified V5 stratum, and precisely the condition under which `bootleg` destroys a folder. **So
the Crate 068–070 success is not representative of the Mastermix backlog.**

**Why not fixed here.** Upstream behaviour, and PROJECT.md's *normalise first, then import*
sequencing already prescribes the mitigation.

**Suggested action (Phase 6/7):** never route a folder to `bootleg` without first asserting that
`album` is populated **and** distinct across the intended album groups. The committed
`scripts/normalise-dj-tags.py` (D-13's winner) is what makes that true; running `bootleg` before it
produces a confidently wrong library shape silently, which `CLAUDE.md` § *Autotagging ceiling*
names as worse than no match.

---

## DEF-03-17 — a publisher source is canonical for ~76% of the backlog, and it is plain HTML

**Found by:** the operator, during plan 03-10 task 3, 2026-09-04.
**Severity:** this is an **opportunity**, not a defect — and it reframes what T1's number means.

The operator identified `https://mastermixdj.com/product/crate-068-pop-dance-reimagined/` and the
release's back-cover tracklisting card.

| Evidence | Value |
|---|---|
| Catalogue | **MDJ2159** |
| Tracks | **20** |
| Stated running time | **1:09:43** |
| Running time beets-flask computed from the files | **1 h 9 m 44 s** — **one second apart** |
| Per-track data on the page | track number, artist, title, version, **BPM**, duration |
| BPM vs embedded `TBPM` | **every one matches** |
| Duration vs disk | **matches within ~1 s** |
| Format | **plain HTML table — no VLM required** |

So the missing track numbers (DEF-03-16) can be assigned **deterministically by duration match**,
not guessed. **The tracklist card is not embedded in the files** — verified via APIC frames: exactly
one picture per file, `comment=Cover (front)`. The running order must come from the web.

**Scale, measured on the real backlog rather than the sample:**

| | Folders |
|---|---|
| Backlog total | **151** (see DEF-03-18) |
| Mastermix-branded | **99** |
| DMC-branded | 13 |
| Toolkit-branded | 3 |
| Crate-branded | 2 |
| **DJ-service branded** | **115 ≈ 76%** |

**~76% of the backlog is publisher-branded content for which the publisher's own site is
canonical — while T1 fired at 27.08% measuring *Discogs* match rate against it.** That does **not**
invalidate T1's number, which was measured correctly against its stated definition and threshold.
It materially reframes what the number *means*: **Discogs was substantially the wrong instrument
for the majority of the backlog.** Recorded as a reframing in `03-DECISION.md` § *AMENDMENT —
2026-09-04, plan 03-10*; T1's threshold text, definition, denominator and measured value are
**unaltered**.

**Do not overstate it.** Only **one** product page was checked; coverage across all 99 Mastermix
folders is **unproven**. Mastermix's own tagging is inconsistent (~40% bare `album=Mastermix`, see
DEF-03-16), so folder-name parsing — not tags — is the likely join key. It is a **commercial site**:
any lookup must be gentle, cached, and rate-limited, and this project should not build a scraper
without checking the site's terms.

**Suggested action (Phase 4 research, then Phase 6):** measure publisher-page coverage across a
sample of the 99 Mastermix folders before designing anything around it. If coverage holds, this
likely displaces both the Discogs path *and* the planned VLM cover-scan extraction (54 images /
27 folders) for Mastermix content.

---

## DEF-03-18 — two backlog denominators are now in circulation, 151 and 144

**Found by:** plan 03-10, task 3, 2026-09-04.
**Severity:** low today, but a phase decided on weighted rates must not carry two denominators.

This session counted **151** backlog folders — `/mnt/tank/downloads/complete/nzb/{unsorted,music}`,
`-maxdepth 1 -type d` — against 03-03's deduplicated **144** (itself a correction of the committed
143; see `03-DECISION.md` § *AMENDMENT — 2026-09-04, plan 03-07*). Different path set and different
dedup rule. **Both figures are now in circulation.**

Nothing in this phase's results turns on it: T1's weights are stated as explicit fractions over
**144** (37/144, 39/144, 11/144, 0/144, 43/144, 14/144) and T2's 21.8-minute projection is nowhere
near its 4-hour limb, so neither threshold outcome moves. The risk is a later plan quoting 151
against weights computed on 144.

**Suggested action (plan 03-11):** state which denominator is authoritative and why — including the
exact path set and dedup rule — rather than letting both stand.

**CLOSED by plan 03-11, 2026-09-04 — and the re-measurement found a third figure, which is the
actual finding.** Re-run from LXC 100 on the same path set, all three readings reconcile exactly:

| Reading | Rule | Value |
|---|---|---|
| DEF-03-18's 151 | `-maxdepth 1 -type d`, **no audio test** | `unsorted` 121 + `music` 30 = **151** |
| Audio-bearing, 2026-09-04 | directory holds ≥ 1 audio file | `unsorted` 120 + `music` 25 = **145** |
| 03-03's census, 2026-09-03 20:36 UTC | audio-bearing, deduplicated | **144** |

**151 − 145 = six directories holding no audio at all**, enumerated: one misfiled movie rip in
`unsorted` (`Harry.Potter.And.The.Deathly.Hallows.Part.1…`), two `_UNPACK_` stubs and three
audio-free folders in `music`. That is `beets.md`'s **bucket D** — triage work, not tagging work.

**145 − 144 = one folder that arrived while the phase was running.**
`music/Taylor Swift - The Life Of A Showgirl-WEB-2025-ALTAiR INT-xpost`, 12 audio files, mtime
**2026-09-03 21:17:19 UTC** — **41 minutes after** 03-03's census commit
(`4a0b5f3239ba844dd4b312ec93df9274a8202dbe`, 2026-09-03 20:36:42 UTC). **The backlog is a live tree
with an unattended inflow** — DEF-03-01 recorded sabnzbd post-processing on that same tree at
20:30 UTC — so **every denominator is a timestamped snapshot of a moving population.**

**The ruling: 144 is authoritative for this phase and must always be quoted with its date**, not
because it is most recent (it is not) but because it is **the frozen basis of T1's estimator**,
whose weights are explicit fractions over it. A rate computed against one denominator may not be
quoted against another. **T1's and T2's outcomes do not move on any of the three figures.** Any
later re-count must record its path set, its audio test **and its timestamp**.

---

## DEF-03-19 — `zfs diff` on the Music snapshot cannot return clean, and three plans assert that it does

**Found by:** plan 03-10, task 3 close, 2026-09-04.
**Severity:** low, but it is a **closing safety assertion**, so a permanently-failing one trains
readers to wave it through.

`03-10-PLAN.md`'s Task 3 acceptance criteria require *"`zfs diff tank/media/Music@pre-project` run
from atlantis returns clean"*. **It cannot, and it could not before this trial began.** Measured
from atlantis at plan close:

| Evidence | Value |
|---|---|
| `zfs diff tank/media/Music@pre-project` | **2,674 lines** |
| Change types | **2,674 `M`** — zero `+`, zero `-`, zero `R` |
| `find /mnt/tank/media/Music \| wc -l` | **2,674** — the diff covers the **entire tree** |
| Snapshot creation | **2026-08-18 13:08** |

That is the signature of **Phase 1 plan 01-08's ownership normalisation**, which `CLAUDE.md` records
as *"`568:568` across all 2,674 entries, library root included, verified from the Proxmox host and
by `zfs diff`"*. The chown moved every inode's metadata, so every entry reports `M` against a
snapshot taken before it. **The diff has been non-clean since 2026-08-18 and will stay that way for
as long as the snapshot is retained.**

**The assertion the criterion was reaching for does hold, on a better instrument:**

```bash
find /mnt/tank/media/Music -newermt '2026-09-04 09:00' | wc -l   # -> 0
find /mnt/tank/media/Music -newerct '2026-09-04 09:00' | wc -l   # -> 0
```

Zero files under Music have an mtime **or** ctime inside the trial window, and neither spike
container mounts `/mnt/tank/media` at any mode.

**Why not fixed here.** Editing a plan's own acceptance criteria while executing it is the lapse
DEF-03-04 and DEF-03-05 both record; the criterion is answered honestly instead, with the better
instrument recorded beside it.

**Suggested fix (plan 03-11, and any later plan inheriting this assertion):** replace *"`zfs diff`
returns clean"* with either **"`zfs diff` reports zero `+`/`-`/`R` entries"** (which is the real
tamper signal and does pass) or the mtime/ctime window check above. A blanket "returns clean" on
this dataset is unsatisfiable and will be waved through on sight.

**ADOPTED by plan 03-11, 2026-09-04.** 03-11's own closing criteria carry the same unsatisfiable
*"`zfs diff` … returns clean"* wording. It was **not** answered by waving it through and **not** by
editing the criterion mid-execution. Both substitute instruments were run instead and are recorded
in `03-DECISION.md` § *Teardown*: the `+`/`-`/`R` count on the Music snapshot, and the mtime/ctime
window check over the plan's own execution window. **The defect remains open for Phase 4 and
beyond**, because the unsatisfiable wording is still inherited by any plan that copies it.

---

## DEF-03-20 — `grep -c PENDING` on `03-DECISION.md` cannot return 0 without destroying provenance

**Found by:** plan 03-11, task 1, 2026-09-04.
**Severity:** low, and the same shape as DEF-03-19 — a closing assertion that is unsatisfiable as
written, on a document whose whole value is that it was not rewritten after the fact.

`03-11-PLAN.md`'s Task 1 `<verify>` block and its first acceptance criterion both require
`grep -c PENDING .planning/phases/03-tagger-spike/03-DECISION.md` to return **0**. Seven
occurrences of the literal string survive after every result cell is filled, and **none of them is
an unfilled result cell**:

| Occurrences | Where | Why it must stay |
|---|---|---|
| 2 | § header (*"Every result cell in this document reads `PENDING` by design"*) and § *Pre-committed thresholds* (*"stay `PENDING` until the measuring plans run"*) | **Pre-committed prose from threshold commit `137b6d9e`.** It is the record of what the document looked like before any evidence existed — the exact thing criterion 5 rests on |
| 2 | § *Criterion 4* and § *D-13*, as `~~PENDING — filled by plan 03-0N~~ →` | **Strikethrough provenance markers added by plans 03-08 and 03-09**, deliberately showing each cell's prior state beside its filled value |
| 3 | Three amendment sections, *"Only `PENDING` result cells were replaced"* | Prior plans' own audit statements about what they did and did not change |

**Satisfying the criterion literally would require deleting pre-committed prose from the threshold
commit** — which is precisely the goalpost move criterion 5 exists to detect, done in the name of
passing a grep.

**Answered on a better instrument instead**, one that measures what the criterion was reaching for
— a `PENDING` occupying a table cell or a verdict slot rather than appearing anywhere in prose:

```bash
grep -cE '\| *PENDING *(\||$)|verdict:\*\* PENDING|status: PENDING' \
  .planning/phases/03-tagger-spike/03-DECISION.md
```

It returned **6** before plan 03-11 (axis one's three question rows plus its verdict, axis two's
verdict, and criterion 4's beets-terminal row) and **0** after. Recorded in `03-DECISION.md`
§ *AMENDMENT — 2026-09-04, plan 03-11* § 7.

**Why not fixed here.** Editing a plan's own acceptance criteria while executing it is the lapse
DEF-03-04, DEF-03-05 and DEF-03-19 all record. The criterion is answered honestly, with the better
instrument recorded beside it.

**Suggested fix (any later plan writing a completeness gate over a Markdown record):** gate on the
*shape* of an unfilled cell, not on the token appearing anywhere in the file. A record that
documents its own prior state will always contain the token, and a gate that forbids the token
punishes exactly the documents that keep the best provenance.
