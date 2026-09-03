#!/usr/bin/env python3
"""normalise-dj-tags.py - Minimum-viable DJ tag normalisation for the Phase 3 tagger spike.

D-08 / OD-4. Repairs exactly two fields - `album` and `artist` - on reflinked COPIES of the DJ
backlog, so that criterion 1's Discogs match rate can be measured on normalised tags beside the
un-normalised pair. It is NOT the DJCC-01 field-mapping tool; that is v2 and the lowest-confidence
research area in the project. No cover-scan reading, no Discogs lookup, no per-folder rule files,
no interactive mode. It writes the minimum that makes the Discogs query valid and stops.

WHERE IT RUNS
  INSIDE the `beets-spike` container on LXC 100 (root@172.16.1.159), not on the host:

      docker exec beets-spike python3 <staged path>/normalise-dj-tags.py \\
          /mnt/tank/downloads/spike-03/normalised \\
          --out /mnt/fast/spike-03/out/normalise-dryrun.ndjson

  This differs from every other script in `scripts/` and the reason is OD-6, measured on
  LXC 100 2026-09-01: the host has python3 3.13.5 but NO `pip3`, NO `python3-venv`,
  `import ensurepip` raises ModuleNotFoundError (so `python3 -m venv` cannot work) and
  /usr/lib/python3.13/EXTERNALLY-MANAGED is present (so PEP 668 blocks a system pip install).
  `import mutagen` is therefore impossible on the host and cannot be made possible without a host
  package install, which this phase does not do. mutagen 1.48.1 ships in the LSIO beets image as a
  beets dependency.

  Delivery is by mount: `03-spike-beets.yaml` binds /mnt/fast/stacks/scripts READ-ONLY at
  /spike-scripts, so the container executes the repo checkout but cannot alter it. That means this
  file must be COMMITTED AND PUSHED TO `origin` AND PULLED ON LXC 100 before it can run from
  /spike-scripts - git is the delivery path. Until that happens the file may be staged to a path
  OUTSIDE the git checkout that the container can also see (/mnt/fast/spike-03/out is bound
  read-write at an identical path inside and outside), and its sha256 verified against the
  committed blob before every run. Never stage it into /mnt/fast/stacks/scripts: an untracked file
  that the incoming commit also adds blocks `git pull --ff-only`.

  The DRY RUN runs on `beets-spike`, where normalised/ is mounted `:ro`. The `--apply` runs on
  `beets-spike-rw`, the single writer arm, which is brought up for that one step and taken down
  immediately after.

USAGE
  normalise-dj-tags.py TARGET [--apply] [--dry-run] [--snapshot-proof FILE]
                              [--artist-policy {label,various,keep}] [--out FILE] [--verbose]

  TARGET                 a directory under /mnt/tank/downloads/spike-03. Anything else exits 2.
  --dry-run              THE DEFAULT. Reads and reports; writes no tag.
  --apply                writes tags in place. Requires --snapshot-proof.
  --snapshot-proof FILE  a file naming `tank/downloads@spike-03-t0`, written by the caller from
                         atlantis. See THE KEY below.
  --artist-policy        which value rule 3 sets. Default `label`. See RULES below.
  --out FILE             machine-readable NDJSON, one record per (file, field) change. Two
                         sidecars are written beside it: FILE.failed and FILE.summary.json.

WORKFLOW
  ssh root@172.16.1.158 'zfs list -t snapshot -H -o name tank/downloads@spike-03-t0' \\
      > /mnt/fast/spike-03/out/snapshot-proof.txt          # UNKNOWN if this fails - do not proceed
  docker exec beets-spike    python3 ... <TARGET> --out .../normalise-dryrun.ndjson   # review
  docker compose -f ... --profile manual up -d beets-spike-rw
  docker exec beets-spike-rw python3 ... <TARGET> --apply --snapshot-proof ... --out .../apply.ndjson
  docker compose -f ... --profile manual down beets-spike-rw     # take the writer arm down at once
  bash scripts/snapshot-music-tags.sh spike03-after --roots <TARGET>
  bash scripts/diff-music-tags.sh <before>.ndjson.gz <after>.ndjson.gz     # the field-loss gate

OUTPUTS
  stdout   one line per proposed/applied change, exactly `path :: field: old -> new`. Emitted in
           BOTH modes, so the dry run IS the review artefact D-08 asks for.
  stderr   the run banner, progress, warnings and the summary block.
  --out    NDJSON, one JSON object per change, with `rule` so per-rule hit counts are a `jq`
           group_by rather than a prose claim.
  .failed  one JSON object per file that raised, carrying its exception CLASS. A raising file is
           NEVER counted as "no change": conflating an exception with a no-op result is precisely
           how Phase 1 produced six unearned passes.
  .summary.json  the same counts the stderr summary block prints.

CONTRACT
  * Only `album` and `artist` are ever written. The writable set is the frozen constant
    WRITABLE_FIELDS and every write asserts membership before it happens. `title`, `track`,
    `date`, `genre`, `TKEY` and `EnergyLevel` are named here ONLY to say that no rule reads or
    writes them: 40 files in this corpus carry TKEY and 110 carry TXXX frames (which is where
    EnergyLevel lives), and they are part of Phase 1's irreplaceable ffprobe fence (SAFE-03).
  * Writes go through mutagen, which preserves every other frame - including the 295 GEOB and
    230 APIC frames in this sample.
  * ID3 major version is PRESERVED, not upgraded. All 335 files in the spike sample are ID3v2.3;
    saving as v2.4 would rewrite TYER/TDAT into TDRC and show up in `diff-music-tags.sh` as a
    change to `date`, which is a field this script has no business touching.
  * THE TRAILING ID3v1 BLOCK IS RESTORED BYTE-FOR-BYTE after every write. mutagen regenerates the
    whole 128-byte block from the ID3v2 frames, which both writes fields this script never asked
    for and MOVES `audio_md5` — the key `snapshot-music-tags.sh` and `diff-music-tags.sh` join on.
    See preserve_id3v1_trailer() for the measurement. This is why "touch nothing else" is true at
    the byte level here and not merely at the frame level.
  * The script contains no `rm`, no `mv`, no `chown`, no `chmod` and no directory creation.

THE KEY
  In `--apply` mode it REFUSES TO RUN unless a proof of `tank/downloads@spike-03-t0` is supplied,
  BECAUSE THAT SNAPSHOT IS ITS ONLY ROLLBACK. beets has no `undo`, and neither has this. The
  snapshot was taken after raw/ was populated and before the first write into normalised/, so
  rolling back to it removes normalised/ and leaves raw/ to re-reflink from.

  The check is DELEGATED, not skipped: `zfs` does not and cannot exist on LXC 100 (the container
  is unprivileged; the pool lives on the Proxmox host atlantis, 172.16.1.158) and it certainly
  does not exist inside this container. The caller runs the `zfs list` over ssh and redirects it
  to --snapshot-proof. An unreachable atlantis produces no proof file, the script exits 2, and the
  snapshot state is recorded as UNKNOWN - never as a skip and never as a pass.

IDEMPOTENT
  A second `--apply` over already-normalised files reports zero changes and writes nothing. Every
  rule is a pure function of the current tag value and is a fixed point on its own output: rule 1
  only fires on an EMPTY album, rule 2's canonical form is stable under re-canonicalisation, and
  rule 3 compares before it sets. The dry run and the apply run compute identical proposals; the
  only difference is whether the write happens.

EXIT-CODE CONVENTION (stated here deliberately, not inherited)
  0  ran - dry or applied - with no error
  1  a rule failed, or a file could not be written (the .failed ledger is non-empty)
  2  usage error, a TARGET outside the scratch root, or a missing/invalid snapshot proof

  `scripts/diff-music-tags.sh:26-32` establishes 0/1/2 for the tag tooling and this follows it.
  What this file INVERTS is the mode flag, and that is stated rather than inherited:

  FLAG CONVENTION (deliberately inverted from scripts/check-music-freeze.sh)
    `check-music-freeze.sh:31-38` makes the destructive-sounding mode the flag and the audit the
    default. Here it is the other way round: `--dry-run` IS THE DEFAULT and writing requires an
    explicit `--apply`. An irreversible in-place tag write over reflinked copies earns a stricter
    default than a read-only audit does, and inverting this is the single cheapest safety control
    available. The inversion is stated out loud because silently inheriting a convention is how
    the docker `created`-state blind spot hid two down containers for six weeks under a green
    check.

HAZARD NOTES
  * SCRATCH ROOT. D-07: normalisation runs on copies, never on originals. TARGET is resolved with
    os.path.realpath and must be the scratch root or a descendant of it. Anything else - most
    importantly /mnt/tank/media/Music - exits 2 naming BOTH the given path and the required root.
    This is the single most important behaviour in the file.
  * NOTHING IS WRITTEN TO THE SYSTEM TEMP DIRECTORY. On LXC 100 the system temp directory is
    tmpfs backed by host RAM and a large spill there has previously taken the whole 28 GB box
    down (T-01-15). This script needs no scratch file at all: mutagen saves in place and the
    NDJSON is streamed straight to --out, flushed per record so an interrupted run still leaves
    the evidence it had produced. There is therefore no `tempfile` import and no scratch path.
  * PATH-DERIVED DATA CROSSES A TRUST BOUNDARY. Rule 1 writes a folder name into file metadata
    (T-03-26). It is sanitised first: Unicode NFC-normalised, path separators stripped, control
    characters stripped, whitespace collapsed, length bounded, and the result rejected outright
    if it does not survive re-validation.
  * `--out` lands on LXC 100's ext4 ROOT filesystem. /mnt/fast/spike-03 is NOT on the `fast` ZFS
    pool - only the `mp` entries in /etc/pve/lxc/100.conf are real bind mounts and neither
    `spike-03` nor `safety` is among them (plan 03-03 finding 4). The outputs here are small
    (hundreds of KB) but the constraint is real; watch `df -h /`, not the pool.
  * sabnzbd runs beets as a live post-processing path over the same backlog trees this sample was
    drawn from, and `check-music-freeze.sh` cannot see it (deferred-items.md DEF-03-01). Attribute
    any unexpected file change by MOUNT TABLE, not by clock.
"""

from __future__ import annotations

import argparse
import collections
import json
import logging
import os
import re
import sys
import time
import unicodedata

# --------------------------------------------------------------------------------------------
# Constants. D-07: the fence is a hardcoded prefix, not an argument and not an env var.
# --------------------------------------------------------------------------------------------

SCRATCH_ROOT = "/mnt/tank/downloads/spike-03"
SNAPSHOT_NAME = "tank/downloads@spike-03-t0"

# The ONLY two fields this script may write. Asserted before every write (D-08 rule 4).
WRITABLE_FIELDS = ("album", "artist")

# ID3 frame per writable field. Nothing else appears in this table by design.
FIELD_FRAME = {"album": "TALB", "artist": "TPE1"}

AUDIO_EXT = (".mp3", ".flac", ".wav", ".m4a", ".aiff", ".aif", ".wma", ".ogg", ".opus", ".wv")

# Verbatim from beets/autotag/distance.py 2.13.1. A folder artist inside this set flips
# `va_likely` true in beets/autotag/match.py tag_album(), and
# beetsplug/discogs/__init__.py get_search_query_with_filters() then sends
# `f"{artist} {name}"` instead of `name` alone. That is why rule 3's chosen value is a recorded
# experimental parameter rather than an implementation detail.
VA_ARTISTS = ("", "various artists", "various", "va", "unknown")

# The DJ services present in the Phase 3 sample. Ordered longest-first where it matters.
LABELS = ("Mastermix", "DMC")
SERIES = (
    "Commercial Collection",
    "Essential Hits",
    "Chart Toppers",
    "Dance Charts",
    "Pro Disc",
    "Toolkit",
    "Issue",
    "Crate",
)
SERIES_BY_LEN = tuple(sorted(SERIES, key=len, reverse=True))

MAX_ALBUM_LEN = 200

CONTROL_RE = re.compile(r"[\x00-\x1f\x7f-\x9f]")
SEPARATOR_RE = re.compile(r"[/\\]")
FOLDER_SPLIT_RE = re.compile(r"[._\-]+")
WHITESPACE_RE = re.compile(r"\s+")

# Rule 2's six noise markers, each its own named pattern so a reader can check them one at a time.
TRAILING_DISC_RE = re.compile(r"\s*[-–]\s*Disc\s*\d+\s*$", re.IGNORECASE)
TRAILING_WEB_RE = re.compile(r"\s+WEB\s*$", re.IGNORECASE)
# `Vol` only counts as noise when a NUMBER follows it. Without the lookahead this eats the "Vol"
# out of a legitimate "Volume 5" and leaves "ume 5".
VOL_NOISE_RE = re.compile(r"\bVol\.?\s*(?=\d)", re.IGNORECASE)
LABEL_SEPARATOR_RE = re.compile(
    r"^(" + "|".join(re.escape(x) for x in LABELS) + r")\s*[-–]\s*", re.IGNORECASE
)

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
NC = "\033[0m"

log = logging.getLogger("normalise-dj-tags")


def colour(text: str, code: str) -> str:
    """ANSI only when stderr is a terminal; a captured transcript stays greppable."""
    return f"{code}{text}{NC}" if sys.stderr.isatty() else text


# --------------------------------------------------------------------------------------------
# Rule 1 - derive a missing album from the containing folder name. V3, the only stratum whose
# un-normalised rate is provably 0%: the discogs plugin issues NO query at all when artist and
# album are both empty (docs/plugins/discogs.rst).
# --------------------------------------------------------------------------------------------


def sanitise_derived(value: str) -> str | None:
    """Sanitise path-derived data before it becomes file metadata (T-03-26, ASVS V5).

    Returns the cleaned string, or None if it does not survive re-validation.
    """
    v = unicodedata.normalize("NFC", value)
    v = SEPARATOR_RE.sub(" ", v)
    v = CONTROL_RE.sub("", v)
    v = WHITESPACE_RE.sub(" ", v).strip()
    v = v[:MAX_ALBUM_LEN]
    # Re-validate rather than trust the transform above.
    if not v:
        return None
    if SEPARATOR_RE.search(v) or CONTROL_RE.search(v):
        return None
    if len(v) > MAX_ALBUM_LEN:
        return None
    if not re.search(r"\d", v):
        # A derived album with no issue number identifies no release, which CLAUDE.md
        # § Autotagging ceiling names as worse than no match.
        return None
    return v


def derive_album_from_folder(folder_name: str) -> tuple[str | None, str | None]:
    """`VA-Mastermix.Crate.071.Afro.House-2025` -> `Mastermix Crate 071`.

    Returns (album, None) or (None, reason).
    """
    raw = FOLDER_SPLIT_RE.sub(" ", folder_name)
    raw = WHITESPACE_RE.sub(" ", raw).strip()

    label = None
    label_end = None
    for candidate in LABELS:
        m = re.search(r"\b" + re.escape(candidate) + r"\b", raw, re.IGNORECASE)
        if m and (label_end is None or m.start() < label_end):
            label, label_end = candidate, m.end()
    if label is None:
        return None, "no_label_token"

    tail = raw[label_end:]
    series = None
    series_end = None
    for candidate in SERIES_BY_LEN:
        pat = r"\b" + r"\s+".join(re.escape(w) for w in candidate.split()) + r"\b"
        m = re.search(pat, tail, re.IGNORECASE)
        if m:
            series, series_end = candidate, m.end()
            break
    if series is None:
        return None, "no_series_token"

    mn = re.search(r"\b(\d{1,4})\b", tail[series_end:])
    if not mn:
        return None, "no_issue_number"

    derived = sanitise_derived(f"{label} {series} {mn.group(1)}")
    if derived is None:
        return None, "unsafe_derived_album"
    return derived, None


# --------------------------------------------------------------------------------------------
# Rule 2 - canonicalise a present-but-noisy album. V5.
# --------------------------------------------------------------------------------------------


def canonicalise_album(value: str) -> str:
    """Fixed point on its own output, which is what makes a second --apply a no-op.

    Target form is the SAME form rule 1 produces - `<Label> <Series> <NNN>` - because a
    canonicalisation that lands somewhere else than the derivation would leave the two halves of
    the sample carrying two different album shapes into the same Discogs query.
    """
    a = value.replace("_", " ")
    a = unicodedata.normalize("NFC", a)
    a = CONTROL_RE.sub("", a)
    a = WHITESPACE_RE.sub(" ", a).strip()
    a = TRAILING_DISC_RE.sub("", a)
    a = TRAILING_WEB_RE.sub("", a)
    a = VOL_NOISE_RE.sub("", a)
    m = LABEL_SEPARATOR_RE.match(a)
    if m:
        # The literal instruction is "strip a leading `Mastermix - ` prefix". Stripping the LABEL
        # would leave `Issue 410`, which is not rule 1's canonical form and is a hopelessly
        # generic Discogs query. What is actually noise is the SEPARATOR, so that is what goes.
        a = m.group(1) + " " + a[m.end():]
    return WHITESPACE_RE.sub(" ", a).strip()


def label_of(album: str) -> str | None:
    for candidate in LABELS:
        if re.match(r"^" + re.escape(candidate) + r"\b", album, re.IGNORECASE):
            return candidate
    return None


# --------------------------------------------------------------------------------------------
# Tag I/O. mutagen only, ID3 major version preserved, every other frame untouched.
# --------------------------------------------------------------------------------------------


def read_tags(path: str):
    """Return (handle, {'album': str|None, 'artist': str|None}). Raises on unreadable files."""
    import mutagen
    from mutagen.id3 import ID3NoHeaderError
    from mutagen.mp3 import MP3

    if path.lower().endswith(".mp3"):
        try:
            handle = MP3(path)
        except ID3NoHeaderError:
            handle = MP3(path)
            handle.add_tags()
        if handle.tags is None:
            handle.add_tags()
        values = {}
        for field in WRITABLE_FIELDS:
            frames = handle.tags.getall(FIELD_FRAME[field])
            text = frames[0].text[0] if frames and frames[0].text else None
            values[field] = text if (text is None or str(text).strip()) else None
        return handle, values

    handle = mutagen.File(path, easy=True)
    if handle is None:
        raise ValueError(f"mutagen could not identify {path}")
    if handle.tags is None:
        handle.add_tags()
    values = {}
    for field in WRITABLE_FIELDS:
        got = handle.tags.get(field)
        text = got[0] if got else None
        values[field] = text if (text is None or str(text).strip()) else None
    return handle, values


def read_id3v1_trailer(path: str) -> bytes | None:
    """The last 128 bytes, if and only if they are an ID3v1 tag. See preserve_id3v1_trailer()."""
    if os.path.getsize(path) < 128:
        return None
    with open(path, "rb") as fh:
        fh.seek(-128, os.SEEK_END)
        tail = fh.read(128)
    return tail if tail[:3] == b"TAG" else None


def preserve_id3v1_trailer(path: str, original: bytes | None) -> None:
    """Restore the pre-write ID3v1 block byte-for-byte. MEASURED, not precautionary.

    `mutagen.id3.ID3.save(v1=UPDATE)` REGENERATES the whole 128-byte ID3v1 block from the ID3v2
    frames whenever one is present. Two consequences were measured on this sample, and both are
    outside what rule 4 permits:

      1. It rewrites ID3v1 fields this script never asked it to touch. 109 of 335 files gained an
         `id3v1 comment` in `ffprobe` output, sourced from their own `COMM` frame.
      2. It moves `audio_md5`. `snapshot-music-tags.sh`'s key is
         `ffmpeg -map 0:a -c copy -f md5 -`, and for some files ffmpeg's mp3 demuxer emits the
         trailing ID3v1 bytes as part of the copied stream. 37 of 335 files changed key on the
         first apply — every one of them carrying an ID3v1 trailer, none without — which made
         `diff-music-tags.sh` report 37 MISSING_AFTER and exit 1 while nothing at all had been
         lost. The audio payload was byte-identical throughout: with the ID3v2 tag and the last
         128 bytes excluded, `cmp` against the untouched `raw/` twin returns zero differing bytes.

    Restoring the block makes "touch nothing else" true AT THE BYTE LEVEL rather than only at the
    ID3v2 frame level, and keeps the phase's own join key tag-invariant. The cost is that ID3v1
    then carries a stale album/artist — which nothing in this project reads: mutagen ignores ID3v1
    on read, so beets never sees it, and ffmpeg lets ID3v2 win for both fields.
    """
    if original is None:
        return
    with open(path, "r+b") as fh:
        fh.seek(-128, os.SEEK_END)
        current = fh.read(128)
        if current[:3] != b"TAG":
            raise RuntimeError("ID3v1 trailer disappeared during save; refusing to guess")
        if current != original:
            fh.seek(-128, os.SEEK_END)
            fh.write(original)


def write_tags(handle, path: str, changes: dict[str, str]) -> None:
    """Write ONLY the fields in WRITABLE_FIELDS. Asserted, not assumed."""
    for field in changes:
        if field not in WRITABLE_FIELDS:
            raise AssertionError(f"refusing to write non-writable field {field!r}")

    if path.lower().endswith(".mp3"):
        import mutagen.id3 as id3

        id3v1_before = read_id3v1_trailer(path)
        for field, new in changes.items():
            frame_id = FIELD_FRAME[field]
            existing = handle.tags.getall(frame_id)
            # Reuse the frame's existing text encoding when the new value fits it; otherwise
            # UTF-16 with BOM (3 is UTF-8, which ID3v2.3 does not define).
            encoding = existing[0].encoding if existing else 1
            try:
                new.encode({0: "latin-1", 1: "utf-16", 2: "utf-16-be", 3: "utf-8"}[encoding])
            except (UnicodeEncodeError, KeyError):
                encoding = 1
            handle.tags.setall(frame_id, [getattr(id3, frame_id)(encoding=encoding, text=[new])])
        # v2_version is pinned to what is already on disk. Every file in the Phase 3 sample is
        # ID3v2.3; silently promoting to v2.4 rewrites TYER/TDAT as TDRC and would surface in
        # diff-music-tags.sh as a change to `date`.
        major = handle.tags.version[1] if getattr(handle.tags, "version", None) else 3
        handle.tags.save(path, v2_version=3 if major <= 3 else 4)
        preserve_id3v1_trailer(path, id3v1_before)
        return

    for field, new in changes.items():
        handle.tags[field] = [new]
    handle.save()


# --------------------------------------------------------------------------------------------
# Argument parsing. exit 2 on usage error - argparse's own default, kept deliberately.
# --------------------------------------------------------------------------------------------


def parse_args(argv):
    p = argparse.ArgumentParser(
        prog="normalise-dj-tags.py",
        description=(
            "Minimum-viable DJ tag normalisation (D-08/OD-4). Writes ONLY `album` and `artist`, "
            "on copies under " + SCRATCH_ROOT + ", and only when --apply is given."
        ),
        epilog=(
            "FLAG CONVENTION: --dry-run is THE DEFAULT and writes nothing; --apply is required to "
            "write and is refused without --snapshot-proof. This inverts scripts/"
            "check-music-freeze.sh deliberately - see the module docstring. "
            "Exit codes: 0 ran, 1 a rule or a write failed, 2 usage / path outside the scratch "
            "root / missing snapshot proof."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("target", help=f"directory under {SCRATCH_ROOT}")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="THE DEFAULT: report every proposed change and write nothing",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="WRITE TAGS IN PLACE. Requires --snapshot-proof; not the default",
    )
    p.add_argument(
        "--snapshot-proof",
        metavar="FILE",
        help=(
            f"file naming {SNAPSHOT_NAME}, produced by the caller from atlantis. Required with "
            "--apply, because that snapshot is this script's only rollback"
        ),
    )
    p.add_argument(
        "--artist-policy",
        choices=("label", "various", "keep"),
        default="label",
        help=(
            "rule 3's chosen artist. `label` (default) sets the DJ service name, which is OUTSIDE "
            "beets' VA_ARTISTS, so va_likely is false and the Discogs query is the album alone. "
            "`various` sets `Various Artists`, which is INSIDE VA_ARTISTS, so the query becomes "
            "'<artist> <album>'. `keep` disables rule 3 entirely (control arm)"
        ),
    )
    p.add_argument("--out", metavar="FILE", help="NDJSON output, one record per change")
    p.add_argument("--verbose", action="store_true", help="DEBUG logging on stderr")
    return p.parse_args(argv)


def resolve_target_or_die(target: str) -> str:
    """The scratch-root fence (T-03-23). Refuses loudly, naming both paths, and exits 2."""
    root = os.path.realpath(SCRATCH_ROOT)
    real = os.path.realpath(target)
    if real != root and not real.startswith(root + os.sep):
        sys.stderr.write(
            colour(
                "REFUSING TO RUN: target is outside the spike scratch root.\n"
                f"  given:    {target}\n"
                f"  resolved: {real}\n"
                f"  required: {root} (or a descendant)\n"
                "D-07: normalisation runs on reflinked COPIES, never on originals and never on "
                "/mnt/tank/media/Music.\n",
                RED,
            )
        )
        sys.exit(2)
    if not os.path.isdir(real):
        sys.stderr.write(colour(f"REFUSING TO RUN: not a directory: {real}\n", RED))
        sys.exit(2)
    return real


def check_snapshot_proof_or_die(proof_path: str | None) -> str:
    """`--apply` refuses unless the rollback snapshot is proven to exist. Never a skip."""
    if not proof_path:
        sys.stderr.write(
            colour(
                "REFUSING TO APPLY: --snapshot-proof is required.\n"
                f"  {SNAPSHOT_NAME} is this script's ONLY rollback, and `zfs` cannot resolve on\n"
                "  LXC 100 or inside this container, so the check is delegated. Produce the proof\n"
                "  on atlantis and pass it:\n"
                "    ssh -o BatchMode=yes -o ConnectTimeout=5 root@172.16.1.158 \\\n"
                f"      'zfs list -t snapshot -H -o name {SNAPSHOT_NAME}' > <proof file>\n"
                "  An unreachable atlantis means the snapshot state is UNKNOWN, which is a refusal,\n"
                "  not a skip and not a pass.\n",
                RED,
            )
        )
        sys.exit(2)
    if not os.path.isfile(proof_path):
        sys.stderr.write(
            colour(
                f"REFUSING TO APPLY: snapshot proof not found: {proof_path}\n"
                f"  {SNAPSHOT_NAME} is this script's only rollback. Snapshot state is UNKNOWN.\n",
                RED,
            )
        )
        sys.exit(2)
    try:
        with open(proof_path, "r", encoding="utf-8", errors="replace") as fh:
            body = fh.read()
    except OSError as exc:
        sys.stderr.write(colour(f"REFUSING TO APPLY: cannot read {proof_path}: {exc}\n", RED))
        sys.exit(2)
    if SNAPSHOT_NAME not in body:
        sys.stderr.write(
            colour(
                f"REFUSING TO APPLY: {proof_path} does not name {SNAPSHOT_NAME}.\n"
                "  Snapshot state is UNKNOWN.\n",
                RED,
            )
        )
        sys.exit(2)
    route = "unrecorded in the proof file"
    for line in body.splitlines():
        if line.lower().lstrip("# ").startswith("route:"):
            route = line.lstrip("# ").split(":", 1)[1].strip()
            break
    return route


# --------------------------------------------------------------------------------------------
# The run.
# --------------------------------------------------------------------------------------------


def collect_folders(root: str) -> dict[str, list[str]]:
    folders: dict[str, list[str]] = collections.defaultdict(list)
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        for name in sorted(filenames):
            if name.lower().endswith(AUDIO_EXT):
                folders[dirpath].append(os.path.join(dirpath, name))
    return dict(sorted(folders.items()))


def main(argv=None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    logging.basicConfig(
        stream=sys.stderr,
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s %(message)s",
    )

    applying = bool(args.apply)
    target = resolve_target_or_die(args.target)

    route = None
    if applying:
        # Runs BEFORE any audio file is opened, which is the point.
        route = check_snapshot_proof_or_die(args.snapshot_proof)

    mode_line = (
        colour("--apply (WRITES TAGS IN PLACE)", RED)
        if applying
        else colour("dry-run (default, writes nothing)", YELLOW)
    )
    started = time.time()
    sys.stderr.write(
        "normalise-dj-tags.py - D-08/OD-4 minimum-viable DJ tag normalisation\n"
        f"  MODE:           {mode_line}\n"
        f"  target:         {target}\n"
        f"  scratch root:   {SCRATCH_ROOT}\n"
        f"  writable fields:{list(WRITABLE_FIELDS)}\n"
        f"  artist policy:  {args.artist_policy}\n"
        f"  snapshot proof: {args.snapshot_proof or '(not required in dry-run)'}"
        + (f"  route: {route}\n" if applying else "\n")
        + f"  out:            {args.out or '(none)'}\n"
        f"  started:        {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(started))}\n"
    )

    out_fh = failed_fh = None
    if args.out:
        out_fh = open(args.out, "w", encoding="utf-8")
        failed_fh = open(args.out + ".failed", "w", encoding="utf-8")

    folders = collect_folders(target)
    counts = collections.Counter()
    rule_hits = collections.Counter()
    folder_rows = []
    changed_paths = set()

    for folder, paths in folders.items():
        folder_name = os.path.basename(folder)
        loaded = []
        for path in paths:
            counts["files_seen"] += 1
            try:
                handle, values = read_tags(path)
            except Exception as exc:  # noqa: BLE001 - routed to the ledger, never swallowed
                counts["failed"] += 1
                log.error("read failed %s: %s", path, type(exc).__name__)
                if failed_fh:
                    failed_fh.write(
                        json.dumps(
                            {
                                "path": path,
                                "stage": "read",
                                "exception": type(exc).__name__,
                                "detail": str(exc)[:400],
                            }
                        )
                        + "\n"
                    )
                    failed_fh.flush()
                continue
            loaded.append((path, handle, values))

        if not loaded:
            continue

        # ---- rules 1 and 2, per file -----------------------------------------------------
        proposals: dict[str, dict[str, tuple[int, str | None, str]]] = {}
        for path, _handle, values in loaded:
            album = values["album"]
            if album is None or not album.strip():
                derived, reason = derive_album_from_folder(folder_name)
                if derived is None:
                    counts["skipped"] += 1
                    log.warning("rule 1 skipped %s: %s", path, reason)
                    continue
                proposals.setdefault(path, {})["album"] = (1, album, derived)
            else:
                canonical = canonicalise_album(album)
                if canonical and canonical != album:
                    proposals.setdefault(path, {})["album"] = (2, album, canonical)

        # ---- rule 3, per FOLDER, so beets sees a consensus artist ------------------------
        if args.artist_policy != "keep":
            originals = [v["artist"] for _p, _h, v in loaded]
            folded = [a.strip().casefold() for a in originals if a and a.strip()]
            missing_any = len(folded) < len(originals)
            placeholder_present = any(f in VA_ARTISTS for f in folded)
            if missing_any or placeholder_present:
                if args.artist_policy == "various":
                    chosen = "Various Artists"
                else:
                    finals = [
                        (proposals.get(p, {}).get("album", (None, None, v["album"]))[2])
                        for p, _h, v in loaded
                    ]
                    finals = [f for f in finals if f]
                    modal = collections.Counter(finals).most_common(1)
                    chosen = label_of(modal[0][0]) if modal else None
                if not chosen:
                    counts["skipped"] += len(loaded)
                    log.warning(
                        "rule 3 skipped folder %s: no label token in its albums", folder_name
                    )
                else:
                    for path, _handle, values in loaded:
                        if (values["artist"] or "") != chosen:
                            proposals.setdefault(path, {})["artist"] = (
                                3,
                                values["artist"],
                                chosen,
                            )

        # ---- emit, then (only under --apply) write ---------------------------------------
        folder_changed = 0
        for path, handle, _values in loaded:
            fields = proposals.get(path)
            if not fields:
                counts["unchanged"] += 1
                continue
            for field, (rule, old, new) in sorted(fields.items()):
                rule_hits[rule] += 1
                sys.stdout.write(
                    f"{path} :: {field}: {'<MISSING>' if old is None else old} -> {new}\n"
                )
            written = False
            if applying:
                try:
                    write_tags(handle, path, {f: v[2] for f, v in fields.items()})
                    written = True
                except Exception as exc:  # noqa: BLE001
                    counts["failed"] += 1
                    log.error("write failed %s: %s", path, type(exc).__name__)
                    if failed_fh:
                        failed_fh.write(
                            json.dumps(
                                {
                                    "path": path,
                                    "stage": "write",
                                    "exception": type(exc).__name__,
                                    "detail": str(exc)[:400],
                                }
                            )
                            + "\n"
                        )
                        failed_fh.flush()
                    continue
            counts["changed"] += 1
            folder_changed += 1
            changed_paths.add(path)
            if out_fh:
                for field, (rule, old, new) in sorted(fields.items()):
                    out_fh.write(
                        json.dumps(
                            {
                                "mode": "apply" if applying else "dry-run",
                                "folder": folder_name,
                                "path": path,
                                "field": field,
                                "rule": rule,
                                "old": old,
                                "new": new,
                                "written": written,
                                "artist_policy": args.artist_policy,
                            }
                        )
                        + "\n"
                    )
                out_fh.flush()

        folder_rows.append(
            {"folder": folder_name, "files": len(loaded), "changed": folder_changed}
        )

    sys.stdout.flush()

    summary = {
        "mode": "apply" if applying else "dry-run",
        "target": target,
        "artist_policy": args.artist_policy,
        "snapshot_proof": args.snapshot_proof,
        "snapshot_route": route,
        "folders_seen": len(folders),
        "files_seen": counts["files_seen"],
        "files_changed": counts["changed"],
        "files_unchanged": counts["unchanged"],
        "files_skipped": counts["skipped"],
        "failures": counts["failed"],
        "rule_hits": {str(k): v for k, v in sorted(rule_hits.items())},
        "per_folder": folder_rows,
        "elapsed_s": round(time.time() - started, 2),
    }

    verb = "did change" if applying else "would change"
    sys.stderr.write(
        "\nSUMMARY\n"
        f"  MODE:              {mode_line}\n"
        f"  folders seen:      {summary['folders_seen']}\n"
        f"  files seen:        {summary['files_seen']}\n"
        f"  files that {verb}: {summary['files_changed']}\n"
        f"  files unchanged:   {summary['files_unchanged']}\n"
        f"  rule 1 hits (album derived from folder):    {rule_hits[1]}\n"
        f"  rule 2 hits (album canonicalised):          {rule_hits[2]}\n"
        f"  rule 3 hits (artist set, policy={args.artist_policy}):"
        f"{' ' * max(1, 12 - len(args.artist_policy))}{rule_hits[3]}\n"
        f"  files skipped:     {summary['files_skipped']}\n"
        f"  failures:          {summary['failures']}\n"
        f"  elapsed:           {summary['elapsed_s']}s\n"
    )
    if not applying:
        sys.stderr.write(
            colour(
                "  NOTHING WAS WRITTEN. This was a dry run; re-run with --apply and "
                "--snapshot-proof to write.\n",
                YELLOW,
            )
        )
    else:
        sys.stderr.write(colour("  TAGS WERE WRITTEN IN PLACE.\n", RED))

    if out_fh:
        out_fh.close()
    if failed_fh:
        failed_fh.close()
    if args.out:
        with open(args.out + ".summary.json", "w", encoding="utf-8") as fh:
            json.dump(summary, fh, indent=2, sort_keys=True)
            fh.write("\n")

    if counts["failed"]:
        sys.stderr.write(
            colour(
                f"  {counts['failed']} file(s) raised and are recorded in the .failed ledger. "
                "They are NOT counted as unchanged.\n",
                RED,
            )
        )
        return 1
    sys.stderr.write(colour("  OK\n", GREEN))
    return 0


if __name__ == "__main__":
    sys.exit(main())
