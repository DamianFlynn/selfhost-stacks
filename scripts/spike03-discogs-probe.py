#!/usr/bin/env python3
"""spike03-discogs-probe.py - The criterion 1 / criterion 2 instrument for the Phase 3 tagger spike.

Calls `beets.autotag.match.tag_album()` directly, once per folder, and emits one NDJSON record per
candidate on stdout. This is the ONLY mechanism that yields BOTH the loose and the strict D-05
figure mechanically, because `AlbumMatch` carries the candidate's track list AND the item/track
mismatch (`extra_items` / `extra_tracks`).

WHY NOT `beet import`
  * `beet import --pretend` is UNUSABLE. `beets/importer/session.py` v2.13.1 replaces the entire
    pipeline with a file lister when `pretend` is set, so it never calls `lookup_candidates`,
    issues zero API calls and reports zero candidates. A rate measured that way is 0% by
    construction.
  * `beet import -q --log` records only the OUTCOME (`skip`/`asis`/`duplicate`), not the candidate
    set or its track counts, so it cannot satisfy D-05's strict rule.
  * `beet import -t` needs a human keypress per folder and its transcript is not machine-parseable.
    It is kept as the SECOND instrument on a small hand-transcribed subset, never as the first.

WHERE IT RUNS
  INSIDE the `beets-spike` container on LXC 100 (root@172.16.1.159), not on the host:

      docker exec beets-spike python3 /spike-scripts/spike03-discogs-probe.py \\
          --ledger /mnt/fast/spike-03/out/smoke \\
          /mnt/tank/downloads/spike-03/smoke/<album> \\
          > /mnt/fast/spike-03/out/smoke-candidates.ndjson \\
          2> /mnt/fast/spike-03/out/smoke.stderr

  OD-6, measured on LXC 100 2026-09-01: the host has python3 3.13.5 but NO `pip3`, NO
  `python3-venv`, `import ensurepip` raises ModuleNotFoundError (so `python3 -m venv` cannot work)
  and /usr/lib/python3.13/EXTERNALLY-MANAGED is present (so PEP 668 blocks a system pip install).
  `import beets` and `import discogs_client` are therefore impossible on the host and cannot be
  made possible without a host package install, which this phase does not do. beets 2.13.1 and
  python3-discogs-client 2.9 ship in lscr.io/linuxserver/beets:2.13.1-ls349.

  Delivery is by mount: `03-spike-beets.yaml` binds /mnt/fast/stacks/scripts READ-ONLY at
  /spike-scripts, so the container executes the repo checkout but cannot alter it. That means this
  file must be COMMITTED AND PUSHED TO `origin` AND PULLED ON LXC 100 before it can run from
  /spike-scripts - git is the delivery path. Until that happens the file may be staged to a path
  OUTSIDE the git checkout that the container can also see (/mnt/fast/spike-03/out is bound
  read-write at an identical path inside and outside), and its sha256 verified against the
  committed blob before every run. Never stage it into /mnt/fast/stacks/scripts: an untracked file
  that the incoming commit also adds blocks `git pull --ff-only`.

USAGE
  spike03-discogs-probe.py FOLDER [FOLDER ...] [--folders-from FILE] --ledger PREFIX
                           [--folder-meta FILE] [--max-seconds N] [--user-agent UA]

  FOLDER            one or more directories to probe. Each is probed as ONE album.
  --folders-from    a file of newline-separated folder paths, appended to the positional list.
  --ledger PREFIX   PREFIX.done (resume) and PREFIX.failed (failures). REQUIRED - see RESUMABILITY.
  --folder-meta     optional JSON object mapping folder BASENAME -> {"tree":..., "stratum":...}.
                    The scratch tree cannot tell you which backlog tree a folder came from; this
                    is how 03-SAMPLE.md's classification is carried into the record rather than
                    guessed. Absent keys emit null, never a fabricated value.
  --max-seconds N   wall-clock ceiling, enforced by signal.alarm(). Default 1800. See THE CEILING.
  --user-agent UA   User-Agent for the identity probe only (beets sets its own for the real calls).

ENVIRONMENT (all three REQUIRED; a missing one is exit 2 before any audio file is opened)
  SPIKE_CONFIG         path to the spike beets config. NEVER the image default - Pitfall 1.
  SPIKE_DB             path to a throwaway .blb under /mnt/fast/spike-03/beets-config/. Set on
                       `config["library"]` so that if anything ever did open a library it would
                       land in the throwaway tree. This script does not open one; see CONTRACT.
  DISCOGS_USER_TOKEN   supplied by compose `env_file`. Injected into `config` in Python. It never
                       appears in argv, never in a config file in this repository, never in a log
                       line and never in an emitted record. See SECURITY.

WORKFLOW
  # the container already carries DISCOGS_USER_TOKEN via env_file - never pass `docker exec -e`
  docker exec beets-spike sh -c 'SPIKE_CONFIG=/spike-config/spike.yaml \\
      SPIKE_DB=/spike-config/spike-probe.blb \\
      python3 /spike-scripts/spike03-discogs-probe.py --ledger /mnt/fast/spike-03/out/smoke \\
      /mnt/tank/downloads/spike-03/smoke/<album>' \\
      > /mnt/fast/spike-03/out/smoke-candidates.ndjson 2> /mnt/fast/spike-03/out/smoke.stderr
  jq -s '[.[]|select(.source=="Discogs")]|length' /mnt/fast/spike-03/out/smoke-candidates.ndjson
  grep -c 'api\\.discogs\\.com'  /mnt/fast/spike-03/out/smoke.stderr

OUTPUTS
  stdout          NDJSON, one object per CANDIDATE, plus exactly one `record_type:"no_candidates"`
                  object for a folder that returned none. A zero-candidate folder is therefore
                  DISTINGUISHABLE from a folder that was never probed - which is the whole point,
                  because this instrument measures a RATE and zero is a plausible-looking answer.
  stderr          the run banner, urllib3 request debug, progress, and the summary block.
  PREFIX.done     resume ledger, one folder path per line.
  PREFIX.failed   one JSON object per folder whose tag_album() raised, carrying its exception
                  CLASS. A raising folder is NEVER counted as "no Discogs candidate": conflating
                  an exception with a zero-candidate result would corrupt the headline number this
                  phase exists to produce.

CONTRACT - READ-ONLY, AND NARROWER THAN `snapshot-music-tags.sh`'s
  `tag_album()` reads `Item`s and returns a `Proposal`. This script:
    * opens NO library database - `beets.library.Library` is never imported or constructed, and
      the summary records the existence and mtime of SPIKE_DB before and after as proof;
    * runs NO importer stage - `ImportSession`, `beets.importer` and `beet import` appear nowhere;
    * moves, copies, renames or deletes NO file - there is no `os.rename`, `shutil`, `os.remove`,
      `os.chmod`, `os.chown` or `os.makedirs` in this file;
    * writes NO tag - `Item.write()`, `Item.store()` and `Item.move()` are never called.
  The claim is restated AT THE CALL SITE in probe_folder(), because Pitfall 5 in 03-RESEARCH.md is
  exactly the risk of a measurement quietly becoming an import.

THE THREE REFUSALS (all before any audio file is opened)
  An empty result from a failed HTTP call and an empty result from a genuine no-match are THE SAME
  VALUE. So this probe refuses the whole run rather than emit N folders of silently-wrong zeros:
    1. BOTH `musicbrainz` AND `discogs` must appear in `plugins.find_plugins()`. Exit 2 naming
       what is missing. A customised `plugins:` list that omits `musicbrainz` silently disables
       all autotagging and presents as "no match found", not as a config error - that is exactly
       the TAGR-05 defect. And plan 03-04 measured a SECOND instance with the same symptom: with
       no `user_token` the discogs plugin raises during setup and does not load, while
       `beet config -d` STILL prints a full `discogs:` block. PRESENCE OF A CONFIG BLOCK IS NOT
       PROOF OF LOADING. `plugins.find_plugins()` is the authoritative instrument, the in-process
       equivalent of `beet ... version`'s `plugins:` line.
    2. `GET https://api.discogs.com/oauth/identity` must return 200. Anything else is a refusal.
       The `x-discogs-ratelimit` header value goes into the run banner, because criterion 2's
       whole extrapolation rests on it (research assumption A6 says 60/min; VERIFY, do not trust).
       Headers are LOWERCASE on the wire - read them case-insensitively via HTTPMessage.get(),
       which plan 03-04 learned by getting it wrong and recording three nulls as "no rate-limit
       headers".
    3. Every required environment variable must be set, naming any that is not.

RESUMABILITY (the `snapshot-music-tags.sh:53-63` ledger, at FOLDER granularity)
  PREFIX.done is loaded once into a set on start and any folder already present is skipped.
  Ordering is: EMIT THE FOLDER'S NDJSON LINES FIRST, then append the folder to PREFIX.done. A hard
  kill in that window re-emits one folder's records on the next run and never loses one.
  This matters more here than it did in Phase 1: a rate-limited Discogs run stalls INVISIBLY for
  hours (see THE CEILING), the operator WILL interrupt it, and a 24-folder run that has to start
  over burns another 150-260 API requests against a 60/min ceiling. The run is CONTINUED, not
  restarted.
  A folder whose tag_album() raises goes to PREFIX.failed and is NOT written to PREFIX.done, so a
  re-run retries it rather than permanently skipping it.

THE CEILING - why signal.alarm() and not an elapsed-time check
  `python3-discogs-client`'s fetchers set `backoff_enabled = True` and the `@backoff` decorator
  retries a 429 up to `MAX_ATTEMPTS = 100` times with `2**i` seconds of jittered `time.sleep()`
  INSIDE the library call (discogs_client/utils.py, get_backoff_duration / backoff). A
  rate-saturated run therefore does NOT error - it stalls for hours while looking healthy
  (03-RESEARCH.md Pitfall 4).
  A loop-top elapsed-time check is UNENFORCEABLE against exactly that condition: it only runs
  between folders, so it cannot interrupt a backoff chain that is already sleeping. The probe
  would hang far past its stated ceiling and - worse for this phase - a hung probe during the
  timed run silently corrupts criterion 2's wall-clock number, which is the very number
  --max-seconds exists to protect.
  `time.sleep()` IS interruptible by a signal, so the ceiling is `signal.alarm(N)` set once before
  the folder loop. The handler:
    1. sets the same stop flag SIGINT/SIGTERM set, and raises CeilingReached so the stack unwinds
       through the folder loop's own `finally`;
    2. the `finally` flushes and os.fsync()s stdout, so no completed folder's records are lost;
    3. the in-flight folder is NOT appended to PREFIX.done - emit-then-append already guarantees
       this and the handler must not defeat it - so a continuation re-probes exactly that one
       folder and no other;
    4. prints an unmissable ceiling line with folders completed and the 429 count;
    5. exits 1, so a ceiling abort is never mistaken for a clean run.

REQUEST COUNTING - the independent second instrument
  `urllib3.connectionpool` is set to DEBUG on its OWN handler writing to stderr, so
  `grep -c 'api\\.discogs\\.com'` on the stderr file counts what actually left the process,
  independently of beets' own bookkeeping. Note that grep counts BOTH the
  "Starting new HTTPS connection" lines and the per-response lines, so this script additionally
  maintains an in-process counter of parsed RESPONSE lines and of HTTP 429s, and prints both. The
  429 count is recorded BESIDE the timing or the extrapolation is uninterpretable: Pitfall 4 means
  a rate-limited run does not fail, it sleeps.

IDEMPOTENT
  A re-run with every requested folder already in PREFIX.done probes 0 folders, issues 0 Discogs
  requests beyond the single identity probe, and exits 0. Delete PREFIX.done to force a re-probe.

EXIT-CODE CONVENTION (stated here deliberately, not inherited)
  0  every requested folder was probed and PREFIX.failed is empty
  1  one or more folders are in PREFIX.failed, OR the run stopped early - the signal.alarm()
     wall-clock ceiling fired, or SIGINT/SIGTERM stopped it at a folder boundary
  2  usage error, a missing environment variable, a required plugin not loaded, or the Discogs
     identity probe not returning 200

  `scripts/diff-music-tags.sh:26-32` establishes 0/1/2 for this estate's tag tooling and this
  follows it. NOTE the deliberate widening of `1`: a signal-interrupted run has not probed every
  requested folder, and a run that exits 0 having probed half its input is exactly the shape of
  silent partial success this phase exists to avoid.

SECURITY
  * The Discogs token travels in the `Authorization` header. `urllib3` DEBUG does NOT log headers;
    `http.client.HTTPConnection.debuglevel = 1` DOES. This file sets `urllib3.connectionpool` to
    DEBUG and NOTHING ELSE - in particular it never touches http.client debuglevel, and it does
    not call logging.basicConfig(level=DEBUG) on the ROOT logger, because that would enable DEBUG
    for every library in the process including any that logs headers (03-RESEARCH.md V7, ASVS V7).
  * The token is read from os.environ and assigned to `config["discogs"]["user_token"]`. It is
    never an argv element, never written to a file by this script, never logged, and never a value
    in an emitted record. Do not add a "config dump" debug flag to this file.
  * Before quoting ANY of the stderr in a committed artefact, screen it for `Authorization` and
    for the token value. Plan 03-04 briefly leaked the token to a 0644 file from an ad-hoc
    verification command; the discipline lapses at the verification step, not at the design step.

HAZARD NOTES
  * A BIND MOUNT PINS THE DIRECTORY INODE, NOT THE PATH (plan 03-05 finding 3). If a mounted tree
    is re-materialised on the host, the container keeps seeing the OLD inode - an empty tree - and
    this script would report 0 candidates and exit 0. Zero is a PLAUSIBLE result here, so it would
    not be caught the way plan 03-05 caught it. Assert the expected file count from INSIDE the
    container and cross-check it against the host BEFORE trusting any rate. This script helps by
    refusing a folder with zero audio files (it goes to PREFIX.failed, not to a zero-candidate
    record) and by printing the total item count in the summary.
  * NOTHING IS WRITTEN TO THE SYSTEM TEMP DIRECTORY. On LXC 100 the system temp directory is tmpfs
    backed by host RAM and a large spill there has previously taken the whole 28 GB box down
    (T-01-15). There is no `tempfile` import and no scratch path: NDJSON streams to stdout and the
    two ledgers are appended in place.
  * The ledgers land on LXC 100's ext4 ROOT filesystem. /mnt/fast/spike-03 is NOT on the `fast`
    ZFS pool - only the `mp` entries in /etc/pve/lxc/100.conf are real bind mounts and neither
    `spike-03` nor `safety` is among them (plan 03-03 finding 4). Watch `df -h /`, not the pool.
  * sabnzbd runs beets as a LIVE post-processing path over the same backlog trees this sample was
    drawn from, and `check-music-freeze.sh` cannot see it (deferred-items.md DEF-03-01). Attribute
    any unexpected file change by MOUNT TABLE, not by clock.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import signal
import sys
import time
import urllib.error
import urllib.request

# --------------------------------------------------------------------------------------------
# Constants.
# --------------------------------------------------------------------------------------------

# The two plugins whose absence would silently zero the measurement. TAGR-05 plus plan 03-04's
# second instance of the same symptom.
REQUIRED_PLUGINS = ("discogs", "musicbrainz")

REQUIRED_ENV = ("SPIKE_CONFIG", "SPIKE_DB", "DISCOGS_USER_TOKEN")

# Same extension set the research sketch uses. Deliberately NOT snapshot-music-tags.sh's wider
# AUDIO_EXT: beets' importer only ever sees what its own `Item.from_path` can read, and a
# `.ape`/`.alac` file that beets cannot open would land in PREFIX.failed for the wrong reason.
AUDIO_EXT = (".mp3", ".flac", ".wav", ".m4a")

IDENTITY_URL = "https://api.discogs.com/oauth/identity"
DEFAULT_USER_AGENT = "Spike03DiscogsProbe/1.0 (+selfhost-stacks phase-03 tagger spike)"

# Default wall-clock ceiling. Reasoned, not picked: 24 folders x 6-11 Discogs requests against a
# 60/min ceiling is a 3-5 minute API floor, and the measured 20-folder criterion-2 run is expected
# in the tens of minutes once MusicBrainz's 1 req/s and ZFS reads are added. 1800 s leaves ample
# headroom for a healthy run while bounding an unhealthy one: a single MAX_ATTEMPTS=100 backoff
# chain at 2**i seconds passes 1800 s by attempt 11 and would otherwise run for years.
DEFAULT_MAX_SECONDS = 1800

# api.discogs.com lines emitted by urllib3.connectionpool at DEBUG. Two shapes:
#   Starting new HTTPS connection (1): api.discogs.com:443
#   https://api.discogs.com:443 "GET /database/search?... HTTP/1.1" 200 None
RESPONSE_RE = re.compile(r'"[A-Z]+ [^"]*" (\d{3})')

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
NC = "\033[0m"

log = logging.getLogger("spike03-probe")


def colour(text: str, code: str) -> str:
    return f"{code}{text}{NC}" if sys.stderr.isatty() else text


# --------------------------------------------------------------------------------------------
# Run state, signals, and the wall-clock ceiling.
# --------------------------------------------------------------------------------------------


class CeilingReached(Exception):
    """Raised from the SIGALRM handler so the stack unwinds through the folder loop's finally."""


class RunState:
    """Mutable run state the signal handlers touch. Deliberately tiny."""

    def __init__(self) -> None:
        self.stop = False
        self.stop_reason = None
        self.ceiling_fired = False
        self.folders_completed = 0
        self.discogs_connections = 0
        self.discogs_responses = 0
        self.discogs_429 = 0


STATE = RunState()


def _on_interrupt(signum, _frame):
    """Clean-boundary stop. `snapshot-music-tags.sh:169-176` in Python."""
    STATE.stop = True
    STATE.stop_reason = "signal"
    sys.stderr.write("\n  [signal received - stopping at the next folder boundary]\n")
    sys.stderr.flush()


def _on_ceiling(signum, _frame):
    """The wall-clock ceiling. MUST raise, so it can unwind a blocking time.sleep() backoff.

    It sets the same flag SIGINT sets, and raises. It deliberately does NOT touch the resume
    ledger: emit-then-append already guarantees the in-flight folder is absent from PREFIX.done,
    and appending here would defeat exactly the property the ceiling needs.
    """
    STATE.stop = True
    STATE.stop_reason = "ceiling"
    STATE.ceiling_fired = True
    raise CeilingReached("wall-clock ceiling reached")


# --------------------------------------------------------------------------------------------
# Logging. urllib3.connectionpool at DEBUG and NOTHING ELSE (see SECURITY in the docstring).
# --------------------------------------------------------------------------------------------


class DiscogsTrafficCounter(logging.Handler):
    """Counts what actually left the process, in-process, beside the stderr grep.

    Reads only the RENDERED MESSAGE. urllib3 does not put headers in it, so the token cannot
    reach this handler even in principle.
    """

    def emit(self, record: logging.LogRecord) -> None:
        try:
            msg = record.getMessage()
        except Exception:  # noqa: BLE001 - a logging handler must never break the run
            return
        if "api.discogs.com" not in msg:
            return
        m = RESPONSE_RE.search(msg)
        if m is None:
            STATE.discogs_connections += 1
            return
        STATE.discogs_responses += 1
        if m.group(1) == "429":
            STATE.discogs_429 += 1


def configure_logging(verbose: bool) -> None:
    """Explicitly NOT logging.basicConfig(level=DEBUG).

    A root-level DEBUG would enable DEBUG for every library in the process. This turns DEBUG on
    for exactly one logger, and never touches http.client debuglevel, which WOULD log the
    Authorization header the Discogs token travels in.
    """
    handler = logging.StreamHandler(stream=sys.stderr)
    handler.setFormatter(logging.Formatter("%(levelname)s %(name)s %(message)s"))

    root = logging.getLogger()
    root.setLevel(logging.DEBUG if verbose else logging.INFO)
    root.addHandler(handler)

    pool = logging.getLogger("urllib3.connectionpool")
    pool.setLevel(logging.DEBUG)
    pool.addHandler(DiscogsTrafficCounter())


# --------------------------------------------------------------------------------------------
# The three refusals.
# --------------------------------------------------------------------------------------------


def require_env() -> dict[str, str]:
    """Refusal 3. Names every missing variable, not just the first."""
    missing = [k for k in REQUIRED_ENV if not os.environ.get(k)]
    if missing:
        sys.stderr.write(
            colour(
                "REFUSING TO RUN: required environment variable(s) not set: "
                + ", ".join(missing)
                + "\n"
                "  DISCOGS_USER_TOKEN reaches the container through compose `env_file`; never\n"
                "  pass it with `docker exec -e` (T-03-32: this host runs 100+ containers with a\n"
                "  readable process table). SPIKE_CONFIG and SPIKE_DB must name the THROWAWAY\n"
                "  spike paths, never the image defaults (Pitfall 1).\n",
                RED,
            )
        )
        sys.exit(2)
    return {k: os.environ[k] for k in REQUIRED_ENV}


def bootstrap_beets(env: dict[str, str]):
    """Configure beets EXPLICITLY, never by default, then load and verify the plugins.

    Pitfall 1: a bare `beet` invocation opens and migrates the DEFAULT library - it did exactly
    that in Phase 1, writing 11 `.bak` files beside the real database. Both paths are therefore
    set from the environment before anything else happens.
    """
    from beets import config, plugins  # noqa: PLC0415 - deliberate: keep module import cheap

    config.set_file(env["SPIKE_CONFIG"])  # explicit - never the image default (Pitfall 1)
    config["library"] = env["SPIKE_DB"]  # explicit throwaway .blb; never opened (see CONTRACT)
    # Injected in Python from the environment. Never an argv element, never a committed key.
    # This must happen BEFORE load_plugins: DiscogsPlugin reads user_token during setup(), and
    # without it the plugin RAISES and does not load while `beet config -d` still prints its
    # block (plan 03-04 finding 1).
    config["discogs"]["user_token"] = env["DISCOGS_USER_TOKEN"]

    # `load_plugins()` TAKES NO ARGUMENTS in beets 2.13.1 - verified against the live
    # `inspect.signature` in the image, not assumed. 03-RESEARCH.md's probe sketch passes
    # `config["plugins"].as_str_seq()` and raises `TypeError: load_plugins() takes 0 positional
    # arguments but 1 was given`. The function reads `get_plugin_names()` off `config` itself,
    # which is why `config.set_file()` above must come first. It is also a no-op when `_instances`
    # is already populated, so it can only be called once per process - fine here.
    requested = list(config["plugins"].as_str_seq())
    plugins.load_plugins()
    loaded = sorted(p.name for p in plugins.find_plugins())

    # Refusal 1. The authoritative instrument - the in-process equivalent of `beet ... version`'s
    # `plugins:` line, and it is authoritative for the same reason: `_get_plugin` returns None for
    # a plugin that raised during construction, so `find_plugins()` lists only the ones that
    # actually built. NOT the presence of a `config -d` block, which proves nothing (03-04).
    missing = [p for p in REQUIRED_PLUGINS if p not in loaded]
    if missing:
        sys.stderr.write(
            colour(
                "REFUSING TO RUN: required beets plugin(s) did not load: "
                + ", ".join(missing)
                + "\n"
                f"  requested by config: {', '.join(requested) or '(none)'}\n"
                f"  actually loaded:     {', '.join(loaded) or '(none)'}\n"
                f"  config: {env['SPIKE_CONFIG']}\n"
                "  `musicbrainz` missing silently disables ALL autotagging and presents as\n"
                "  'no match found', not as a config error (TAGR-05). `discogs` missing makes\n"
                "  every folder score 0% Discogs - the exact artefact that would falsify T1.\n"
                "  A `discogs:` block in `beet config -d` is NOT proof the plugin loaded.\n"
                "  Note the two lines above are DIFFERENT questions: a name present in the first\n"
                "  and absent from the second is a plugin that raised while building.\n",
                RED,
            )
        )
        sys.exit(2)
    return config, loaded


def discogs_identity_probe(token: str, user_agent: str) -> dict:
    """Refusal 2. One request. Refuses the WHOLE run on anything but 200.

    An empty result from a failed HTTP call and an empty result from a genuine no-match are the
    same value. Probing once and refusing is better than hardening every folder: it makes the
    unreachable case a single unmissable statement instead of N separately-wrong records.
    """
    req = urllib.request.Request(
        IDENTITY_URL,
        headers={
            # The token travels here and NOWHERE else. Not logged, not echoed, not emitted.
            "Authorization": f"Discogs token={token}",
            "User-Agent": user_agent,
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = resp.status
            # HTTPMessage.get() is CASE-INSENSITIVE. Discogs sends these headers LOWERCASE, and
            # flattening them into a plain dict then asking for `X-Discogs-Ratelimit` returns
            # None, which reads as "the endpoint carries no rate-limit headers" (plan 03-04
            # deviation 4 - recorded because it cost a request and nearly cost A6).
            ratelimit = resp.headers.get("x-discogs-ratelimit")
            used = resp.headers.get("x-discogs-ratelimit-used")
            remaining = resp.headers.get("x-discogs-ratelimit-remaining")
            body = json.loads(resp.read().decode("utf-8", "replace"))
            username = body.get("username")
    except urllib.error.HTTPError as exc:
        status, ratelimit, used, remaining, username = exc.code, None, None, None, None
    except Exception as exc:  # noqa: BLE001 - any failure here is a refusal, never a zero
        sys.stderr.write(
            colour(
                "REFUSING TO RUN: the Discogs identity probe could not complete.\n"
                f"  {IDENTITY_URL}\n"
                f"  {type(exc).__name__}: {str(exc)[:300]}\n"
                "  A failed HTTP call and a genuine no-match produce the SAME empty result, so\n"
                "  this run stops rather than emitting folders of silently-wrong zeros.\n",
                RED,
            )
        )
        sys.exit(2)

    if status != 200:
        sys.stderr.write(
            colour(
                "REFUSING TO RUN: Discogs identity probe returned "
                f"HTTP {status}, not 200.\n"
                f"  {IDENTITY_URL}\n"
                "  The token is unset, wrong, or revoked. Every folder would score zero Discogs\n"
                "  candidates and that zero would be indistinguishable from a real coverage gap.\n",
                RED,
            )
        )
        sys.exit(2)

    return {
        "status": status,
        "username": username,
        "ratelimit": ratelimit,
        "ratelimit_used": used,
        "ratelimit_remaining": remaining,
    }


# --------------------------------------------------------------------------------------------
# The probe itself.
# --------------------------------------------------------------------------------------------


def audio_paths(folder: str) -> list[str]:
    """One album = one folder. Deterministic, LC_ALL=C-equivalent byte order."""
    try:
        names = sorted(os.listdir(folder))
    except OSError:
        return []
    out = []
    for name in names:
        p = os.path.join(folder, name)
        if name.lower().endswith(AUDIO_EXT) and os.path.isfile(p):
            out.append(p)
    return out


def _tag_album(items):
    """The single call this whole instrument exists to make.

    READ-ONLY AT THE CALL SITE (restated here on purpose, Pitfall 5): `tag_album` reads the Items
    it is given and returns a `Proposal`. It opens no library database, constructs no
    ImportSession, runs no importer stage, moves no file and writes no tag. Nothing in this
    function or its callers calls `Item.write()`, `Item.store()` or `Item.move()`.

    Kept as a module-level indirection so the ceiling mechanism can be tested against a stub that
    blocks inside the call - which is the only way to prove signal.alarm() beats a
    MAX_ATTEMPTS=100 backoff chain, and the only way to test it without burning API budget.
    """
    from beets.autotag import match  # noqa: PLC0415

    return match.tag_album(items)


def _items_from_paths(paths: list[str]):
    from beets.library import Item  # noqa: PLC0415 - Item only; Library is never imported

    return [Item.from_path(p) for p in paths]


def probe_folder(folder: str, meta: dict, ctx: dict) -> list[dict]:
    """Probe one folder. Returns the records to emit. Raises on failure - never returns [].

    A raising folder must land in PREFIX.failed, NOT be counted as "no Discogs candidate".
    """
    paths = audio_paths(folder)
    if not paths:
        # NOT a zero-candidate result. A folder with no audio is a broken input or a stale bind
        # mount (03-05 finding 3), and both must be loud rather than fold into the rate.
        raise ValueError(f"no audio files in {folder}")

    items = _items_from_paths(paths)
    cur_artist, cur_album, prop = _tag_album(items)

    folder_meta = meta.get(os.path.basename(folder), {})
    base = {
        "folder": os.path.basename(folder),
        "folder_path": folder,
        "arm": ctx["arm_of"](folder),
        "tree": folder_meta.get("tree"),
        "stratum": folder_meta.get("stratum"),
        "n_files": len(items),
        "cur_artist": cur_artist,
        "cur_album": cur_album,
        "index_tracks_setting": ctx["index_tracks"],
        "search_limit": ctx["search_limit"],
        "plugins_enabled": ctx["plugins_enabled"],
        "artist_policy_of_source": folder_meta.get("artist_policy"),
        "probed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }

    candidates = list(getattr(prop, "candidates", []) or [])
    recommendation = getattr(
        getattr(prop, "recommendation", None), "name", str(getattr(prop, "recommendation", None))
    )

    if not candidates:
        # Emitted so a zero-candidate folder is distinguishable from a folder never probed.
        rec = dict(base)
        rec.update(
            {
                "record_type": "no_candidates",
                "candidates": 0,
                "source": None,
                "album": None,
                "album_id": None,
                "n_tracks": None,
                "extra_items": None,
                "extra_tracks": None,
                "distance": None,
                "recommendation": recommendation,
            }
        )
        # Never f-string a record: album titles here carry ':', quotes and trailing spaces
        # ('Mastermix Crate 068 : ...', 'Mastermix - Issue 413 ').
        return [rec]

    records = []
    for m in candidates:
        info = getattr(m, "info", None)
        tracks = getattr(info, "tracks", None) or []
        rec = dict(base)
        rec.update(
            {
                "record_type": "candidate",
                "candidates": len(candidates),
                "source": getattr(info, "data_source", None),
                "album": getattr(info, "album", None),
                "album_id": getattr(info, "album_id", None),
                "n_tracks": len(tracks),
                "extra_items": len(getattr(m, "extra_items", []) or []),
                "extra_tracks": len(getattr(m, "extra_tracks", []) or []),
                "distance": float(m.distance) if hasattr(m, "distance") else None,
                "recommendation": recommendation,
            }
        )
        records.append(rec)
    return records


# --------------------------------------------------------------------------------------------
# Scoring - D-05, applied mechanically so nobody has to compute it from the NDJSON by hand.
# --------------------------------------------------------------------------------------------


def score_folder(records: list[dict]) -> tuple[bool, bool]:
    """(loose, strict) for one folder's records.

    loose  = a Discogs candidate appeared at all
    strict = a Discogs candidate appeared AND its track count agrees with the folder AND
             extra_items == 0 AND extra_tracks == 0                                (D-05)
    """
    loose = strict = False
    for r in records:
        if r.get("source") != "Discogs":
            continue
        loose = True
        if (
            r.get("n_tracks") == r.get("n_files")
            and r.get("extra_items") == 0
            and r.get("extra_tracks") == 0
        ):
            strict = True
    return loose, strict


# --------------------------------------------------------------------------------------------
# I/O helpers. No tempfile, no scratch path - see HAZARD NOTES.
# --------------------------------------------------------------------------------------------


def fsync_stream(fh) -> None:
    """Flush and fsync. stdout may be a pipe or a tty, where fsync is EINVAL - not an error."""
    try:
        fh.flush()
    except (OSError, ValueError):
        return
    try:
        os.fsync(fh.fileno())
    except (OSError, ValueError, AttributeError):
        pass


def load_done(path: str) -> set[str]:
    if not os.path.isfile(path):
        return set()
    with open(path, "r", encoding="utf-8") as fh:
        return {line.strip() for line in fh if line.strip()}


def read_folder_meta(path: str | None) -> dict:
    if not path:
        return {}
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError("--folder-meta must be a JSON object keyed by folder basename")
    return data


def db_fingerprint(path: str) -> dict:
    """Proof for the CONTRACT clause 'opens NO library database'."""
    try:
        st = os.stat(path)
        return {"exists": True, "size": st.st_size, "mtime": int(st.st_mtime)}
    except OSError:
        return {"exists": False, "size": None, "mtime": None}


# --------------------------------------------------------------------------------------------
# Argument parsing. exit 2 on usage error - argparse's own default, kept deliberately.
# --------------------------------------------------------------------------------------------


def parse_args(argv):
    p = argparse.ArgumentParser(
        prog="spike03-discogs-probe.py",
        description=(
            "Criterion 1/2 instrument: calls beets.autotag.match.tag_album() per folder and "
            "emits one NDJSON record per candidate on stdout. Reads only; opens no library, "
            "runs no importer stage, writes no tag."
        ),
        epilog=(
            "Exit codes: 0 every folder probed with no failures; 1 failures in PREFIX.failed or "
            "the run stopped early (signal.alarm() ceiling, SIGINT/SIGTERM); 2 usage error, "
            "missing environment variable, a required plugin not loaded, or the Discogs identity "
            "probe not returning 200. Requires SPIKE_CONFIG, SPIKE_DB and DISCOGS_USER_TOKEN."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("folders", nargs="*", metavar="FOLDER", help="directories to probe, one album each")
    p.add_argument(
        "--folders-from",
        metavar="FILE",
        help="file of newline-separated folder paths, appended to the positional list",
    )
    p.add_argument(
        "--ledger",
        metavar="PREFIX",
        required=True,
        help="PREFIX.done (resume) and PREFIX.failed (failures). See RESUMABILITY",
    )
    p.add_argument(
        "--folder-meta",
        metavar="FILE",
        help="JSON object: folder basename -> {tree, stratum}. Absent keys emit null",
    )
    p.add_argument(
        "--max-seconds",
        type=int,
        default=DEFAULT_MAX_SECONDS,
        metavar="N",
        help=(
            f"wall-clock ceiling enforced by signal.alarm(), default {DEFAULT_MAX_SECONDS}. It "
            "fires INSIDE a blocking 429 backoff sleep; a loop-top check cannot"
        ),
    )
    p.add_argument("--user-agent", default=DEFAULT_USER_AGENT, help="UA for the identity probe only")
    p.add_argument("--verbose", action="store_true", help="DEBUG on the root logger too")
    return p.parse_args(argv)


# --------------------------------------------------------------------------------------------
# The run.
# --------------------------------------------------------------------------------------------


def main(argv=None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    configure_logging(args.verbose)

    folders = list(args.folders)
    if args.folders_from:
        with open(args.folders_from, "r", encoding="utf-8") as fh:
            folders += [ln.strip() for ln in fh if ln.strip()]
    folders = [os.path.abspath(f) for f in folders]
    if not folders:
        sys.stderr.write(colour("REFUSING TO RUN: no folders given.\n", RED))
        return 2
    if args.max_seconds < 1:
        sys.stderr.write(colour("REFUSING TO RUN: --max-seconds must be >= 1.\n", RED))
        return 2

    env = require_env()  # refusal 3
    try:
        meta = read_folder_meta(args.folder_meta)
    except Exception as exc:  # noqa: BLE001
        sys.stderr.write(colour(f"REFUSING TO RUN: --folder-meta unusable: {exc}\n", RED))
        return 2

    config, loaded = bootstrap_beets(env)  # refusal 1
    identity = discogs_identity_probe(env["DISCOGS_USER_TOKEN"], args.user_agent)  # refusal 2

    index_tracks = bool(config["discogs"]["index_tracks"].get())
    search_limit = int(config["discogs"]["search_limit"].get())
    scratch_root = "/mnt/tank/downloads/spike-03"

    def arm_of(folder: str) -> str | None:
        real = os.path.realpath(folder)
        if not real.startswith(scratch_root + os.sep):
            return None
        return real[len(scratch_root) + 1 :].split(os.sep)[0]

    ctx = {
        "arm_of": arm_of,
        "index_tracks": index_tracks,
        "search_limit": search_limit,
        "plugins_enabled": loaded,
    }

    done_path = args.ledger + ".done"
    failed_path = args.ledger + ".failed"
    done = load_done(done_path)
    # Rebuilt each run, like snapshot-music-tags.sh:235: a folder that failed last time is
    # retried (it is not in .done), and if it now succeeds it must not stay on the list.
    failed_fh = open(failed_path, "w", encoding="utf-8")
    done_fh = open(done_path, "a", encoding="utf-8")

    db_before = db_fingerprint(env["SPIKE_DB"])
    started = time.time()

    sys.stderr.write(
        "spike03-discogs-probe.py - criterion 1/2 instrument (tag_album NDJSON emitter)\n"
        f"  MODE:              {colour('READ-ONLY (no library, no importer, no write)', GREEN)}\n"
        f"  folders requested: {len(folders)}\n"
        f"  already in .done:  {len(done & set(folders))}\n"
        f"  ledger:            {done_path}\n"
        f"  failed ledger:     {failed_path}\n"
        f"  spike config:      {env['SPIKE_CONFIG']}\n"
        f"  spike library:     {env['SPIKE_DB']} (exists={db_before['exists']}, never opened)\n"
        f"  plugins loaded:    {', '.join(loaded)}\n"
        f"  discogs.index_tracks / search_limit: {index_tracks} / {search_limit}\n"
        f"  discogs identity:  HTTP {identity['status']} as {identity['username']}\n"
        f"  x-discogs-ratelimit: {identity['ratelimit']} "
        f"(used {identity['ratelimit_used']}, remaining {identity['ratelimit_remaining']})\n"
        f"  wall-clock ceiling: {args.max_seconds}s, enforced by signal.alarm()\n"
        f"  started:           {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(started))}\n\n"
    )

    signal.signal(signal.SIGINT, _on_interrupt)
    signal.signal(signal.SIGTERM, _on_interrupt)
    signal.signal(signal.SIGALRM, _on_ceiling)

    probed = skipped = failures = 0
    loose_folders = strict_folders = 0
    total_items = 0
    per_folder = []

    # Set ONCE, before the loop. It must be armed across the whole run, not re-armed per folder,
    # or a folder that blocks forever inside a backoff chain is never interrupted.
    signal.alarm(args.max_seconds)
    try:
        for folder in folders:
            if STATE.stop:
                break
            if folder in done:
                skipped += 1
                continue

            f_start = time.time()
            try:
                records = probe_folder(folder, meta, ctx)
            except CeilingReached:
                raise
            except Exception as exc:  # noqa: BLE001 - routed to the ledger, never swallowed
                failures += 1
                failed_fh.write(
                    json.dumps(
                        {
                            "folder": os.path.basename(folder),
                            "folder_path": folder,
                            "stage": "tag_album",
                            "exception": type(exc).__name__,
                            "detail": str(exc)[:400],
                        }
                    )
                    + "\n"
                )
                failed_fh.flush()
                log.error("probe failed %s: %s", folder, type(exc).__name__)
                # NOT written to .done: a re-run retries it. And NOT counted as a
                # zero-candidate folder, which would corrupt the headline rate.
                continue

            # EMIT FIRST. A hard kill between here and the .done append re-emits one folder's
            # records on the next run; it never loses one.
            for rec in records:
                sys.stdout.write(json.dumps(rec) + "\n")
            fsync_stream(sys.stdout)

            done_fh.write(folder + "\n")
            done_fh.flush()
            done.add(folder)

            loose, strict = score_folder(records)
            loose_folders += int(loose)
            strict_folders += int(strict)
            probed += 1
            STATE.folders_completed = probed
            total_items += records[0]["n_files"] if records else 0
            per_folder.append(
                {
                    "folder": os.path.basename(folder),
                    "loose": loose,
                    "strict": strict,
                    "seconds": round(time.time() - f_start, 2),
                }
            )
            sys.stderr.write(
                f"  [{probed}/{len(folders)}] {os.path.basename(folder)}: "
                f"{len(records)} record(s), loose={loose} strict={strict} "
                f"({round(time.time() - f_start, 1)}s, {STATE.discogs_responses} discogs resp, "
                f"{STATE.discogs_429} x429)\n"
            )
    except CeilingReached:
        pass
    finally:
        signal.alarm(0)
        # Flush and fsync no matter how we got here, so no completed folder's records are lost
        # in a buffer. The in-flight folder is already absent from .done by construction.
        fsync_stream(sys.stdout)
        done_fh.flush()
        os.fsync(done_fh.fileno())
        done_fh.close()
        failed_fh.flush()
        failed_fh.close()

    elapsed = time.time() - started
    db_after = db_fingerprint(env["SPIKE_DB"])

    if STATE.ceiling_fired:
        sys.stderr.write(
            colour(
                f"\n  [wall-clock ceiling of {args.max_seconds}s reached - stopping; "
                "run is resumable]\n"
                f"  folders completed: {probed}\n"
                f"  429 responses so far: {STATE.discogs_429}\n"
                "  The in-flight folder was NOT written to the resume ledger, so a continuation\n"
                "  re-probes exactly that one folder and no other. Re-run the SAME command.\n",
                RED,
            )
        )

    gap = loose_folders - strict_folders

    def pct(n: int) -> str:
        return f"{(100.0 * n / probed):.1f}%" if probed else "n/a"

    per_folder_mean = f"{(elapsed / probed):.1f}s" if probed else "n/a"
    sys.stderr.write(
        "\nSUMMARY\n"
        f"  folders requested:            {len(folders)}\n"
        f"  folders probed this run:      {probed}\n"
        f"  folders skipped (in .done):   {skipped}\n"
        f"  folders failed (.failed):     {failures}\n"
        f"  audio items read:             {total_items}\n"
        f"  LOOSE  (>=1 Discogs cand.):   {loose_folders}  ({pct(loose_folders)})\n"
        f"  STRICT (D-05 track-count OK): {strict_folders}  ({pct(strict_folders)})\n"
        f"  LOOSE-STRICT GAP:             {gap}  ({pct(gap)} of folders probed)\n"
        f"  discogs.index_tracks:         {index_tracks}\n"
        f"  discogs.search_limit:         {search_limit}\n"
        f"  discogs HTTP responses seen:  {STATE.discogs_responses}\n"
        f"  discogs new connections:      {STATE.discogs_connections}\n"
        f"  discogs 429 responses:        {STATE.discogs_429}\n"
        f"  x-discogs-ratelimit at start: {identity['ratelimit']}\n"
        f"  wall clock:                   {elapsed:.1f}s\n"
        f"  per folder (probed):          {per_folder_mean}\n"
    )
    sys.stderr.write(
        f"  SPIKE_DB before/after:        {db_before} / {db_after}\n"
        "  (no library was opened; both readings are printed so the claim is checkable)\n"
        f"  PER-FOLDER (json):            {json.dumps(per_folder)}\n"
    )

    if failures:
        sys.stderr.write(
            colour(
                f"  {failures} folder(s) raised and are recorded in {failed_path}. They are NOT\n"
                "  counted as zero-candidate folders. Re-run to retry them.\n",
                RED,
            )
        )
    if STATE.ceiling_fired:
        return 1
    if STATE.stop:
        sys.stderr.write(
            colour("  [interrupted at a folder boundary - run is resumable]\n", YELLOW)
        )
        return 1
    if failures:
        return 1
    sys.stderr.write(colour("  OK\n", GREEN))
    return 0


if __name__ == "__main__":
    sys.exit(main())
