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
