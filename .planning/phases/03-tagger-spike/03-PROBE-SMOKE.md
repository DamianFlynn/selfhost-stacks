# Phase 3 probe smoke test — the A1 hard gate

Companion to [`03-DECISION.md`](03-DECISION.md) (D-05, the strict rule this instrument implements),
[`03-SAMPLE.md`](03-SAMPLE.md) (the album this ran against) and
[`scripts/spike03-discogs-probe.py`](../../../scripts/spike03-discogs-probe.py) (the instrument).

Nothing here is applied by `docker compose`. This is the record of whether the probe can be
trusted, taken **before** it is pointed at the 24-folder sample.

State as of 2026-09-03 — **A1 CONFIRMED. The probe is trusted. One security finding overturns the
plan's own T-03-31 mitigation and is recorded below rather than quietly fixed.**

> **Verdict, up front: research assumption A1 is CONFIRMED.** The probe returns both a Discogs and
> a MusicBrainz candidate on a known-good album, its candidate set agrees with a hand-read
> `beet import -t` on source, ordering, score and track count, and it wrote nothing. The phase
> proceeds.

---

## Headline: the request-counting instrument is a credential sink

**T-03-31 in `03-06-PLAN.md` is wrong, and it is wrong in the dangerous direction.** It reasons
that the Discogs token is safe under `urllib3` DEBUG because *"the token travels in the
`Authorization` header; `urllib3` DEBUG does not log headers"*. **Both halves are true and the
conclusion is false.** `python3-discogs-client` does not use an Authorization header for a user
token — it appends `?token=<value>` to the **query string**, and `urllib3.connectionpool` logs the
full request line at DEBUG.

The first smoke run therefore wrote the live token, in cleartext, to a **`644 root:root`** file on
a host running 100+ containers:

```
DEBUG urllib3.connectionpool https://api.discogs.com:443 "GET /releases/3542996?token=REDACTED HTTP/1.1" 200 None
```

(the line above is the **post-fix** rendering; the pre-fix line carried the 40-character token in
place of `REDACTED`).

So **criterion 2's independent request-counting instrument is also a credential sink**, and no
amount of header discipline fixes it — the mitigation was aimed at the wrong channel. It is the
same shape as the two findings this phase has already produced: 03-04's *"a `config -d` block
proves nothing"* and 03-05's *"a bind mount pins the inode"*. In each case a control was in place,
was reasoned about correctly, and was **measuring the wrong thing**.

### Containment, stated rather than tidied away

| Step | Result |
|---|---|
| Exposure window | first smoke run, `22:52`–`22:54` UTC 2026-09-03, ~2 minutes |
| File and mode | `/mnt/fast/spike-03/out/smoke.stderr`, **`644 root:root`**, on LXC 100's ext4 root |
| Sweep for the value across `/mnt/fast/spike-03/out` | **1 file** — that one |
| Redacted copy retained | `smoke.stderr.leaked-redacted`, `600`, exact-token-hits **0** |
| Original | `shred -u -n 3` |
| Re-sweep after shred | **0 files** carrying `token=<40 chars>` |
| The value in the repository | **never** — no committed artefact has ever carried it (proven below) |

**The token was also rendered into the executing agent's transcript.** That is not a filesystem
exposure and cannot be shredded. It is recorded here because this project's standing rule is that
"pre-existing" and "contained" are claims that have to be earned. **Recommended action: rotate the
Discogs personal access token.** It is a read-scoped personal token on a public-catalogue API, so
the blast radius is small, but the rotation is cheap and the exposure is real.

### The fix, at the logging record rather than at the reviewer's memory

`spike03-discogs-probe.py` now redacts at two layers with two independent nets:

| Layer | What it covers |
|---|---|
| `SecretRedactingFilter` on the **stderr handler** | every record the handler writes, whatever logger produced it. **This is the load-bearing one:** a record that *propagates* from `urllib3.connectionpool` to the root handler does **not** re-run the root logger's filters, so a logger-level filter alone would have left the hole open |
| `SecretRedactingFilter` on the **`urllib3.connectionpool` logger** | the record is clean before *any* handler sees it, including the in-process counter and anything a later plan attaches |
| `RedactingFormatter` on the handler | the **fully formatted** line — which is what catches a rendered traceback (`exc_text`), a path `record.getMessage()` never touches |
| `redact()` on every `.failed` ledger detail | `discogs_client` raises exceptions carrying the request URL. Redact **before** truncating: truncating first can leave a token fragment the exact-value net no longer matches |

Net 1 matches by parameter **name** (`token`/`key`/`secret`/`signature`/`password`/`access_token`/
`api_key`), so a credential parameter we have not seen yet is still caught. Net 2 matches the live
secret by **exact value**, registered by `require_env()`, so a serialisation we have not seen is
still caught. Neither net alone is sufficient.

Post-fix, on the recorded run: **`token=` appears 7 times and `REDACTED` appears 7 times** — a
one-to-one correspondence, no unredacted occurrence.

---

## The album

**The plan's two named candidates do not exist as albums, and `03-SAMPLE.md` had already retracted
them.** `03-06-PLAN.md` says *"research observed `Ed Sheeran - ÷ (2017) FLAC` and
`Lady Gaga - The Fame (2008) FLAC`"*. `03-SAMPLE.md` § *The bucket-A and hard-shape candidates*
measured both: the Ed Sheeran folder is **completely empty**, and the Lady Gaga folder holds
**one file**. Using either would have produced a meaningless gate.

The album used is `03-SAMPLE.md`'s verified `clean-2` slot, which satisfies the plan's stated
requirement (*"a mainstream FLAC album… it should match on **both** sources, so a source that fails
to appear is a loading fault rather than a coverage fact"*) exactly:

| Property | Value |
|---|---|
| Album | Garth Brooks — *Ropin' The Wind* (1991, Capitol/Liberty, `CDP 7 96330 2`) |
| Source | `/mnt/tank/downloads/complete/nzb/music/_FAILED_Garth.Brooks-Ropin.The.Wind-CDP.7.06330-2-CD-FLAC-1991-EMG` |
| Staged to | `/mnt/tank/downloads/spike-03/smoke/` (same name) |
| Contents | **10 FLAC** + 1 `.nfo` + 1 `.zip` = 12 files |
| Copy route | **atlantis (172.16.1.158)** — `cp -r --reflink=always --preserve=timestamps` then `chown -R 568:568`. `--reflink` is **EPERM inside the unprivileged LXC** (03-03), and `-a` is EPERM on `tank` even as real root; both constraints are 03-03's, honoured unchanged |
| Mount mode into `beets-spike` | **`RW=false`** — so "the probe wrote nothing" is structurally true, not merely checked |

The `_FAILED_` prefix is a SABnzbd unpack marker on the *folder name*; the ten FLAC are present and
probe clean, exactly as `03-SAMPLE.md` records.

## Mandatory preflight — the bind-mount inode assertion

03-05 finding 3: a bind mount pins the directory **inode**, not the path, and a stale inode makes
the container see an empty tree while every command **exits 0 reporting 0 files**. 03-05 caught it
because 0 files is obviously wrong for a normalisation run. **This plan measures a rate, where zero
is a plausible-looking answer that would falsify T1 on an artefact**, so the assertion is made from
both sides before anything is recorded.

| Tree | Host count | Container count | Agree |
|---|---|---|---|
| `spike-03/raw` (audio) | 335 | 335 | yes |
| `spike-03/normalised` (audio) | 335 | 335 | yes |
| `spike-03/smoke` before staging | 0 | 0 | yes |
| `spike-03/smoke` FLAC after staging | **10** | **10** | **yes** |
| `spike-03/smoke` all files after staging | **12** | **12** | **yes** |

No force-recreate was needed: the `smoke/` **directory** was created by 03-04 and was never
re-materialised — only its contents were added — so the inode the mount pins is still live. The
container's own `ls` of the staged folder was read back and matches the host's byte for byte.

---

## The gate — three assertions, all of which hold

| # | Assertion | Command | Result | Verdict |
|---|---|---|---|---|
| 1 | ≥1 record with `source == "Discogs"` | `jq -s '[.[]\|select(.source=="Discogs")]\|length'` | **5** | **PASS** |
| 2 | ≥1 record with `source == "MusicBrainz"` | `jq -s '[.[]\|select(.source=="MusicBrainz")]\|length'` | **5** | **PASS** |
| 3 | requests actually left the process | `grep -c 'api\.discogs\.com' smoke.stderr` | **14** | **PASS** |

Gate 1 is the A1 gate. Had it returned 0 the phase would have stopped here.

## The emitted records, in full

Ten candidates, one folder, `index_tracks: no`, `search_limit: 5`. `distance` is rounded to four
places for width; the NDJSON carries full precision.

| # | source | album | album_id | n_tracks | n_files | extra_items | extra_tracks | distance | strict? |
|---|---|---|---|---|---|---|---|---|---|
| 1 | MusicBrainz | Ropin’ the Wind | `60dffd91-a9c7-3b78-a143-dcbdbf7ff4a0` | 10 | 10 | 0 | 0 | 0.1230 | n/a |
| 2 | **Discogs** | Ropin' The Wind | `1604274` | 10 | 10 | 0 | 0 | 0.1275 | **yes** |
| 3 | MusicBrainz | Ropin’ the Wind | `47ef4e8f-a2bc-4aae-a9eb-d4efed8bc1e2` | 10 | 10 | 0 | 0 | 0.1311 | n/a |
| 4 | **Discogs** | Ropin' The Wind | `4000841` | 10 | 10 | 0 | 0 | 0.1603 | **yes** |
| 5 | **Discogs** | Ropin' The Wind | `3876690` | 10 | 10 | 0 | 0 | 0.1603 | **yes** |
| 6 | MusicBrainz | Ropin’ the Wind | `b149f539-b320-435a-91c4-15d48861a306` | 11 | 10 | 0 | 1 | 0.1959 | n/a |
| 7 | MusicBrainz | Ropin’ the Wind | `7031cacb-9653-4780-83c1-20faad00912b` | 11 | 10 | 0 | 1 | 0.1959 | n/a |
| 8 | MusicBrainz | Ropin’ the Wind | `b13ced82-c04a-454a-9e3e-6c9cc55f3dec` | 14 | 10 | 0 | 4 | 0.2082 | n/a |
| 9 | **Discogs** | Ropin' The Wind | `1862096` | 14 | 10 | 0 | 4 | 0.2270 | no |
| 10 | **Discogs** | Ropin' The Wind | `3542996` | 14 | 10 | 0 | 4 | 0.2563 | no |

**Both halves of D-05 are exercised on one album**, which is worth more than a uniformly-passing
gate: three Discogs candidates satisfy the strict rule and two fail it on track count alone. The
loose/strict distinction is not theoretical.

One record in full, so the schema is on the record rather than described:

```json
{
  "album": "Ropin’ the Wind",
  "album_id": "60dffd91-a9c7-3b78-a143-dcbdbf7ff4a0",
  "arm": "smoke",
  "artist_policy_of_source": null,
  "candidates": 10,
  "cur_album": "Ropin' The Wind",
  "cur_artist": "Garth Brooks",
  "distance": 0.12295081967213115,
  "extra_items": 0,
  "extra_tracks": 0,
  "folder": "_FAILED_Garth.Brooks-Ropin.The.Wind-CDP.7.06330-2-CD-FLAC-1991-EMG",
  "folder_path": "/mnt/tank/downloads/spike-03/smoke/_FAILED_Garth.Brooks-Ropin.The.Wind-CDP.7.06330-2-CD-FLAC-1991-EMG",
  "index_tracks_setting": false,
  "n_files": 10,
  "n_tracks": 10,
  "plugins_enabled": ["discogs", "fromfilename", "importsource", "musicbrainz"],
  "probed_at": "2026-09-03T22:55:40Z",
  "recommendation": "medium",
  "record_type": "candidate",
  "search_limit": 5,
  "source": "MusicBrainz",
  "stratum": null,
  "tree": null
}
```

`tree` and `stratum` are `null` here **by design**: the scratch tree cannot tell you which backlog
tree a folder came from, so the probe takes them from an optional `--folder-meta` map and emits
`null` rather than a fabricated value when the key is absent. Plan 03-07 supplies the map from
`03-SAMPLE.md`'s draw table.

## The run banner and summary, verbatim

Screened before quoting — see § *Screening* below. `urllib3` DEBUG lines are elided for width; they
are quoted individually where they carry evidence.

```
spike03-discogs-probe.py - criterion 1/2 instrument (tag_album NDJSON emitter)
  MODE:              READ-ONLY (no library, no importer, no write)
  folders requested: 1
  already in .done:  0
  spike config:      /spike-config/spike.yaml
  spike library:     /spike-config/spike-probe.blb (exists=True, never opened)
  plugins loaded:    discogs, fromfilename, importsource, musicbrainz
  discogs.index_tracks / search_limit: False / 5
  discogs identity:  HTTP 200 as damian.flynn
  x-discogs-ratelimit: 60 (used 0, remaining 60)
  wall-clock ceiling: 1800s, enforced by signal.alarm()
  started:           2026-09-03T22:55:27Z

  [1/1] _FAILED_Garth.Brooks-...-EMG: 10 record(s), loose=True strict=True (13.6s, 7 discogs resp, 0 x429)

SUMMARY
  folders requested:            1
  folders probed this run:      1
  folders skipped (in .done):   0
  folders failed (.failed):     0
  audio items read:             10
  LOOSE  (>=1 Discogs cand.):   1  (100.0%)
  STRICT (D-05 track-count OK): 1  (100.0%)
  LOOSE-STRICT GAP:             0  (0.0% of folders probed)
  discogs.index_tracks:         False
  discogs.search_limit:         5
  discogs HTTP responses seen:  7
  discogs new connections:      7
  discogs 429 responses:        0
  x-discogs-ratelimit at start: 60
  wall clock:                   13.6s
  per folder (probed):          13.6s
  SPIKE_DB before/after:        {'exists': True, 'size': 53248, 'mtime': 1788469035} / {'exists': True, 'size': 53248, 'mtime': 1788469035}
  OK
```

## The rate limit, and the request arithmetic criterion 2 inherits

| Quantity | Measured |
|---|---|
| `x-discogs-ratelimit` | **60** — A6 re-confirmed, independently of 03-04's reading |
| `x-discogs-ratelimit-used` / `-remaining` at the identity probe | 0 / 60 |
| Discogs HTTP **responses** for the one folder | **7** |
| Discogs new **connections** for the one folder | 7 |
| The identity probe's own request | **1**, and it is **not** in the 7 |
| Total Discogs requests, this run | **8** |
| MusicBrainz requests over the same `urllib3` stream | **6**, all to `musicbrainz.org:443` |
| HTTP status distribution, all hosts | **13 × 200**, zero non-200 |
| Real HTTP **429** responses | **0** |

Two facts here matter to plan 03-07 and are easy to get wrong:

1. **The identity probe is not counted by the in-process counter.** It goes out through
   `urllib.request`, not `urllib3`, so it emits no `connectionpool` line. It is **one request per
   run**, not per folder. Criterion 2's per-folder figure is the 7, not the 8.
2. **beets' `musicbrainz` plugin also goes through `urllib3`**, so the same DEBUG stream carries
   `musicbrainz.org` lines. `grep -c 'api\.discogs\.com'` correctly excludes them; a naive
   `grep -c 'connectionpool'` would not. 7 Discogs requests for one folder sits inside
   03-RESEARCH.md's predicted 6–11.

## The reciprocal cross-check — hand-read `beet import -t`

```
printf "M\n2\nM\n9\nB\n" | docker exec -i beets-spike \
  beet -c /spike-config/spike.yaml -l /spike-config/smoke-crosscheck.blb import -t "<the album>"
```

`M` lists all candidates, a number opens one, `B` aborts. Nothing was applied. The transcript is
the on-screen candidate list, transcribed here with the ANSI colour codes stripped:

```
  Candidates:
  1. 87.7% Garth Brooks - Ropin’ the Wind      MusicBrainz, CD,       1991, US,           Liberty,                    CDP 7 96330 2
  2. 87.2% Garth Brooks - Ropin' The Wind      Discogs,     CD,       1991, US,           Liberty,                    CDP 7 96330 2
  3. 86.9% Garth Brooks - Ropin’ the Wind      MusicBrainz, CD,       1996, BR,           None,                       None
  4. 84.0% Garth Brooks - Ropin' The Wind      Discogs,     Vinyl,    1991, US,           Capitol Nashville,          C1-596330
  5. 84.0% Garth Brooks - Ropin' The Wind      Discogs,     Cassette, 1991, US,           Capitol Nashville,          C4 96330
  6. 80.4% Garth Brooks - Ropin’ the Wind      MusicBrainz, CD,       2000, US,           Capitol Records,            7243-5-30120-2-1
  7. 80.4% Garth Brooks - Ropin’ the Wind      MusicBrainz, CD,       2005, US,           Pearl Records,              85420-6001-145
  8. 79.2% Garth Brooks - Ropin’ the Wind      MusicBrainz, CD,       1992, GB,           Capitol Records Nashville,  79 8468 2
  9. 77.3% Garth Brooks - Ropin' The Wind      Discogs,     CD,       1992, UK & Europe,  Capitol Records Nashville,  CDP 7 98468 2
 10. 74.4% Garth Brooks - Ropin' The Wind      Discogs,     Vinyl,    1992, Europe,       Capitol Records Nashville,  79 8468 1
```

Track counts, read off the two candidates opened by number:

```
  Match (87.2%):  Discogs, CD, 1991, US, Liberty, CDP 7 96330 2
  * Album: Ropin' The Wind
     ≠ (#6) Shameless (4:19) -> (#6) Shameless (4:01)
  [no "Missing tracks" block]

  Match (77.3%):  Discogs, CD, 1992, UK & Europe, Capitol Records Nashville, CDP 7 98468 2
  * Album: Ropin' The Wind
     ≠ (#6) Shameless (4:19) -> (#6) Shameless (4:01)
  Missing tracks (4/14 - 28.6%):
   ! Alabama Clay (#11) (3:37)
   ! Everytime That It Rains (#12) (4:10)
   ! Nobody Gets Off In This Town (#13) (2:19)
   ! Cowboy Bill (#14) (4:32)
```

### The agreement verdict: **AGREE, on four independent properties**

| Property | Probe NDJSON | `beet import -t` | Agree |
|---|---|---|---|
| Candidate **count** | 10 | 10 | **yes** |
| **Source set** | 5 Discogs, 5 MusicBrainz | 5 Discogs, 5 MusicBrainz | **yes** |
| **Ordering** | by ascending `distance` | rows 1–10 as listed | **yes, row for row** |
| **Score**, all 10 | `distance` | `(1 - distance) × 100` | **yes** — 0.1230→87.7, 0.1275→87.2, 0.1311→86.9, 0.1603→84.0 ×2, 0.1959→80.4 ×2, 0.2082→79.2, 0.2270→77.3, 0.2563→74.4 |
| **Track count**, candidate 2 | `n_tracks 10`, `extra_tracks 0` | no *Missing tracks* block | **yes** |
| **Track count**, candidate 9 | `n_tracks 14`, `extra_tracks 4` | `Missing tracks (4/14 - 28.6%)` | **yes, exactly** |

**The paired-instrument rule is satisfied and the numbers are recorded.** Note the specific thing
this rules out, which is the only failure mode 03-RESEARCH.md said was worth testing for: *"the
probe reporting zero candidates for a folder where `beet import -t` shows some — means plugin
loading differs between the two paths"*. It does not: the two paths return the identical candidate
set. Timid mode also suppresses `tag_album`'s strong-MBID early return, so both instruments saw the
same set for the same reason.

One reading worth keeping: `beets` renders `≠ tracks` as a penalty on **track titles and lengths**,
and `Missing tracks` as the penalty on **count**. Candidates 4 and 5 carry `≠ … tracks …` while the
probe reports `n_tracks == n_files` and `extra_tracks == 0`. Those are not in conflict, and reading
`≠ tracks` as a count mismatch would have produced a false disagreement.

---

## The wall-clock ceiling, proven to fire inside a blocking sleep

A ceiling that only fires between folders is unenforceable against the condition it exists to catch
(`discogs_client` sleeps `2**i` seconds **inside** the library call, up to `MAX_ATTEMPTS = 100`). So
it is proven against a stub that blocks for 30 s inside `_tag_album`, with `--max-seconds 2`:

| Assertion | Result |
|---|---|
| Exit code | **1** |
| Wall clock | **2.6 s real**, against a 30 s stub sleep — the probe's own ceiling line fires at 2 s and the remaining ~0.6 s is `docker exec` + interpreter start + plugin load + the identity probe. **The alarm interrupted the sleep**, which is the whole claim |
| Folders emitted before the abort | 1 of 3 |
| NDJSON valid — `jq -s length` | **1**, parses |
| `.done` contents | **exactly** the one fully-emitted folder; the in-flight folder absent |
| `.failed` | 0 lines |
| Abort message | `[wall-clock ceiling of 2s reached - stopping; run is resumable]` + `folders completed: 1` + `429 responses so far: 0` |
| **Resume run** — folders probed | **2** (the interrupted folder + the unstarted one) |
| **Resume run** — folders skipped | **1** (the completed one) |
| Resume run exit | **0**, `.done` now holds all three |
| Union of the two runs' emitted folder sets | **exactly the 3 requested, each once** |
| Third run, everything in `.done` | 0 probed, **0 records**, exit 0 — idempotent |

**Every number in this document comes from one clean invocation of the final committed script.**
The ceiling test, the resume, the idempotence check and both refusals were first run against an
earlier build and were **re-run in full** against `0dd5520d…` after the redaction fix landed, rather
than carried forward — the same standard 03-05 set. The staged file, the working-tree file and
`git show HEAD:scripts/spike03-discogs-probe.py` all hash to `0dd5520d…`.

The stub is a test fixture, not a repo artefact. Recorded verbatim so the test is reproducible
without adding an unused file to `scripts/`:

```python
#!/usr/bin/env python3
"""usage: ceiling-stub.py SLEEP_FOLDER_BASENAME SLEEP_SECONDS -- <probe argv...>"""
import importlib.util, sys, time
from types import SimpleNamespace

sep = sys.argv.index("--")
sleep_folder, sleep_secs, probe_argv = sys.argv[1], float(sys.argv[2]), sys.argv[sep + 1:]

spec = importlib.util.spec_from_file_location(
    "spike03probe", "/mnt/fast/spike-03/out/spike03-discogs-probe.py")
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)

def fake_tag_album(items):
    folder = items[0].path.decode("utf-8", "replace") if items else ""
    if sleep_folder and sleep_folder in folder:
        time.sleep(sleep_secs)          # stands in for discogs_client's 2**i jittered backoff
    info = SimpleNamespace(data_source="Discogs", album="STUB ALBUM", album_id="stub-1",
                           tracks=[object()] * len(items))
    cand = SimpleNamespace(info=info, extra_items=[], extra_tracks=[], distance=0.10)
    prop = SimpleNamespace(candidates=[cand], recommendation=SimpleNamespace(name="strong"))
    return ("STUB ARTIST", "STUB CUR ALBUM", prop)

probe._tag_album = fake_tag_album
sys.exit(probe.main(probe_argv))
```

**It stubs `_tag_album` and nothing else** — the environment gate, the plugin gate and the *real*
Discogs identity probe all still ran, so the ceiling test exercises the whole startup path and
costs one API request per run rather than a folder's worth.

## The three refusals, each demonstrated

| Refusal | How it was forced | Result |
|---|---|---|
| Missing environment variable | `unset DISCOGS_USER_TOKEN` | **exit 2**, names `DISCOGS_USER_TOKEN`, **before** any audio file is opened and before either ledger file is created (`ls` of `PREFIX.*` → *No such file*) |
| Plugin not loaded | a config copy whose `plugins:` omits `discogs` | **exit 2**, naming the missing plugin, and printing `requested by config` **beside** `actually loaded` — two different questions, and a name in the first but not the second is a plugin that raised while building |
| Discogs identity ≠ 200 | not forced (would require an invalid token; the run's own probe returned 200) | the code path is a single unconditional `sys.exit(2)` on `status != 200`; recorded as **not exercised** rather than claimed |

---

## The probe wrote nothing — five instruments

| Instrument | Result |
|---|---|
| `find smoke/ -newer smoke.stamp -type f` | **0 lines** |
| `find smoke/ -newer smoke.stamp` (any type) | **0 lines** |
| Whole-subtree `%p\t%s\t%T@` manifest, before vs after | **diff empty** (14 entries) |
| Whole-subtree `sha256sum` manifest, before vs after | **diff empty** (12 files) |
| `docker inspect beets-spike` — the `smoke` mount | **`RW=false`** |

The five-file spot check is retired phase-wide (03-05); both manifests cover the whole subtree.

**No stray beets database appeared.** The throwaway `/mnt/fast/spike-03/beets-config/` gained
`smoke-crosscheck.blb` and its 11 migration `.bak` files — that is Pitfall 1 firing **inside the
containment**, which is the proof the containment works, exactly as 03-04 recorded. Outside it:

| Assertion | Result |
|---|---|
| `*.blb` / `library.db` / `*-before-*.bak` outside `/mnt/fast/spike-03/beets-config/` | only the **pre-existing** Phase 1 fence copies under `/mnt/fast/safety/music-pre-project/library-db/` |
| The estate's **four** real beets databases (DEF-03-02's corrected glob, `*.blb` **and** `library.db`) | **0 of 4** modified — newest mtime is `2026-09-03 21:17:20`, before `beets-spike` was created (`22:24:53`) and before this plan's first action |
| `.bak` files under `/mnt/fast/appdata` newer than the container's `.Created` | **0** |
| `*.blb` / `library.db` / `*-before-*.bak` anywhere under `/mnt/tank/downloads/spike-03` or `/mnt/fast/spike-03`, excluding the throwaway config dir | **0** |
| `bash scripts/check-music-freeze.sh` | **exit 0** — `tagger-class writers: 0`, `declared rw reaching Music: 0`, `FAILURES total: 0` |
| `df -h /` | **35 G free**, unchanged across the plan — well above OD-1's 8 GiB floor. `/mnt/fast/spike-03` is on LXC 100's ext4 **root**, not the `fast` pool (03-03 finding 4); watch `/`, not the pool |

`SPIKE_DB` is byte-identical and mtime-identical across the run (`size 53248`, `mtime 1788469035`
before and after), which is the probe's own in-band proof that it opened no library.

**Attribution is by mount table, not by clock** (DEF-03-01): `beets-spike` holds **no** mount under
`/mnt/fast/appdata` at any mode, so it could not have written there whatever the timestamps said —
and `sabnzbd` runs beets as a live post-processing path over the same backlog trees this album came
from.

## Screening

**The stderr was screened before any of it was quoted here**, and the screen is what found the
headline finding above. What it looked for, and what it found:

| Looked for | In | Result |
|---|---|---|
| the literal 40-character token value | every `smoke*` artefact and every staged `.py` under `/mnt/fast/spike-03/out` | **0 hits in all 16 files** |
| `Authorization` | the same set | **0** in every artefact; 4 in `spike03-discogs-probe.py` itself, all of them the word in code or prose, none a value |
| `token=<20+ alphanumerics>` | recursive sweep of `/mnt/fast/spike-03/out` | **0 files**, after the containment above |
| `token=` unredacted | `smoke.stderr` | 7 occurrences, **7 of them `token=REDACTED`** |

The token-value screen was executed **inside the container**, reading `os.environ` and printing
only counts, so the value was never materialised on the host side by the verification command
itself. That is the specific discipline 03-04's own leak was caused by lapsing.

---

## Corrections to this plan's acceptance criteria

Recorded as retractions rather than quiet replacements, in the `beets.md:55-58` house style. The
underlying facts hold; two of the *instruments* named in the plan do not.

**1. `grep -c '429' smoke.stderr` returning 0 is unsatisfiable, and it is the wrong instrument.**
The plan requires it to be **0**. It returns **3** on a run with **zero** rate limiting, because a
bare `429` substring matches (a) release ID `3542996`, which contains `429` at offset 3, and (b)
the probe's own summary labels `0 x429` and `discogs 429 responses: 0`. The correct instrument is
the HTTP **status column**, which the probe already counts in-process and prints:

```bash
grep -oE 'HTTP/1\.1" [0-9]{3}' smoke.stderr | sort | uniq -c     # -> 13 × 200, nothing else
```

The fact the criterion was reaching for holds and is proven by the better instrument: **0 HTTP 429
responses.** Plan 03-07 must not carry the substring form forward.

**2. The plan's two named smoke albums are already retracted by `03-SAMPLE.md`.** Recorded above.

**3. `plugins.load_plugins()` takes no arguments in beets 2.13.1.** 03-RESEARCH.md's probe sketch
(§ *Criterion 1*) passes `config["plugins"].as_str_seq()` and raises
`TypeError: load_plugins() takes 0 positional arguments but 1 was given`. The function reads
`get_plugin_names()` off `config` itself, which is why `config.set_file()` must come first. Checked
against `inspect.signature` in the live image, not assumed. It is also a **no-op when `_instances`
is already populated**, so it can be called only once per process — which is fine for a
one-shot probe and is a constraint any later plan embedding this in a longer-lived process
inherits.

**4. Task 1's "committed **and pushed** to `origin/main`" is discharged as *committed*.** A worktree
executor cannot push, and `/mnt/fast/stacks` sits at `c88c268`. The probe was staged to
`/mnt/fast/spike-03/out/` — deliberately **outside** the git checkout, so a later
`git pull --ff-only` is not blocked by an untracked file the incoming commit also adds — and
**sha256-verified identical to the committed blob before every run** (`0dd5520d…`, confirmed
against `git show HEAD:scripts/spike03-discogs-probe.py`). Publication is the orchestrator's. Same
deviation and same handling as plans 03-01, 03-03, 03-04, 03-05 and 03-08.

---

## A1: CONFIRMED

Research assumption **A1** — *"the plugin-loading incantation is the weak point; if the smoke test
does not return a Discogs candidate, stop"* — is **CONFIRMED**. The incantation works:
`config.set_file()` → `config["library"]` → `config["discogs"]["user_token"]` from `os.environ` →
`plugins.load_plugins()` (**no arguments**) → `plugins.find_plugins()`, in that order, with the
token assignment **before** the load because `DiscogsPlugin` reads it during `setup()`.

The probe returns both a Discogs and a MusicBrainz candidate on a known-good album, agrees with a
hand-transcribed `beet import -t` on count, source set, ordering, score and track count, wrote
nothing on five instruments, and prints the loose/strict gap itself.

**Plan 03-07 may proceed to the 24-folder sample.** It must carry forward: the corrected 429
instrument, the request arithmetic (7 per folder + 1 per run for the identity probe), the
`--folder-meta` map from `03-SAMPLE.md`'s draw table, and the preflight inode assertion before
every measurement run.
