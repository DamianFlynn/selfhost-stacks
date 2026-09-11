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
  normalise-dj-tags.py --self-test

  TARGET                 a directory under /mnt/tank/downloads/spike-03. Anything else exits 2.
  --self-test            the WAV regression test (D-23). Takes no TARGET. See SELF-TEST below.
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
  * MUTAGEN DOES NOT WRITE BACK WHAT IT READ. It re-serialises its own normalised in-memory
    model, and THREE of its defaults quietly broaden the write past `album` and `artist`. All
    three were found by measurement on this sample, not by reading the docs, and each is set
    explicitly at the line it matters:
      - `ID3(path, v2_version=3)` at LOAD time, or `TYER`/`TDAT`/`TIME` are translated to `TDRC`
        in memory and written back as `TDRC` inside a v2.3 tag. `save(v2_version=3)` does NOT
        undo it. See id3v2_major().
      - `ID3(path, load_v1=False)`, or mutagen synthesises a `COMM:ID3v1 Comment:eng` frame from
        the trailing ID3v1 block and `save()` writes it to disk. See read_tags().
      - the trailing ID3v1 block is restored BYTE-FOR-BYTE after every save, because
        `save(v1=UPDATE)` regenerates all 128 bytes from the ID3v2 frames — which also MOVES
        `audio_md5`, the key `snapshot-music-tags.sh` and `diff-music-tags.sh` join on. See
        preserve_id3v1_trailer().
    And because a fourth such default is exactly the shape of defect that keeps recurring, every
    write is followed by assert_frame_set_unchanged(): the on-disk ID3v2 frame-ID multiset, parsed
    WITHOUT mutagen, must equal what it was plus the two frames this script wrote. Anything else
    is a hard failure into the .failed ledger, not a silently larger diff.
  * WAV (D-23, DEF-03-09). A WAVE carries TWO tag containers: an ID3 tag inside a RIFF `id3 `
    chunk, and a RIFF LIST/INFO chunk (`IPRD` is its album). This script writes the ID3 tag
    ONLY, through `mutagen.wave.WAVE` + `add_tags()` + `tags.setall()` and reads it back through
    `tags.getall()`. It never uses `mutagen.File(easy=True)` for a WAV: on a WAVE that yields a
    raw frame-keyed ID3, not an EasyID3 map, which is how the tool wrote 0 of 134 WAVs
    (`TypeError: ... not a Frame instance` on every one) and read album=None from the 87 that
    carry one. ID3 only, because D-23 records that ID3 is what both consumers read. The INFO
    chunk is left byte-identical, so a stale `IPRD` is REPORTED rather than silently kept:
    every album record for a WAV whose `IPRD` disagrees with the new album carries `info_iprd`,
    in the dry run and the apply alike. A later reader then meets a recorded finding, not two
    containers that look like corruption. Which value a reader that parses BOTH containers
    prefers is not established here, and that is the reason the disagreement is recorded. The
    same load options as MP3 apply (on-disk ID3 major kept, `load_v1=False`), and the frame-set
    backstop runs on the `id3 ` chunk rather than at file offset 0 (see
    assert_frame_set_unchanged()). FLAC and every other format keep the easy-mode path.
  * A TARGET run contains no `rm`, no `mv`, no `chown`, no `chmod` and no directory creation.
    `--self-test` creates exactly one mkdtemp() directory of its own and removes it.

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

SELF-TEST (D-23, DEF-03-09)
  `--self-test` builds three synthetic WAVs - untagged, ASCII-tagged, and non-ASCII-tagged with a
  hand-written RIFF LIST/INFO/IPRD chunk - and drives each one through the SAME read_tags(),
  write_tags() and build_record() the real run uses. Per case it asserts that the album reads
  back, that APIC, TDRC, TIT2, TPE1 and TRCK are equal before and after, that no other ID3 frame
  appeared or vanished, that the RIFF INFO chunk is untouched, and that the NDJSON record carries
  `info_iprd` exactly when IPRD disagrees with the new album. One `ok`/`bad` line per case, a
  reason under every `bad`. Exit 0 all passed, 1 any case failed, 2 could not run (mutagen is
  absent everywhere except the beets image - see WHERE IT RUNS):

      docker run --rm --pull never --network none --entrypoint python3 \\
          -v /mnt/fast/stacks/scripts:/w:ro lscr.io/linuxserver/beets:2.13.1-ls349 \\
          /w/normalise-dj-tags.py --self-test

  The test writes ONLY inside its own mkdtemp() directory. write_tags() still runs its fence
  first: the self-test passes that directory as `fence_root`, and fence_root_or_raise() accepts
  no override other than a real `normalise-dj-selftest-*` directory directly under the temp dir,
  so the real run's SCRATCH_ROOT fence is not relaxed.

HAZARD NOTES
  * SCRATCH ROOT. D-07: normalisation runs on copies, never on originals. TARGET is resolved with
    os.path.realpath and must be the scratch root or a descendant of it. Anything else - most
    importantly /mnt/tank/media/Music - exits 2 naming BOTH the given path and the required root.
    This is the single most important behaviour in the file.

    THE FENCE IS RE-ASSERTED ON EVERY FILE, NOT ONLY ON TARGET (CR-04). Fencing the target alone
    was not enough: collect_folders() returns symlinked FILES (os.walk declines to descend
    symlinked directories, which is a different thing), and both `handle.save(path, ...)` and
    preserve_id3v1_trailer()'s `r+b` open follow a symlink and write to its target. One symlink
    under the scratch tree pointing at the library defeated the fence silently - a normal
    `changed` count, and an NDJSON recording the scratch path rather than the path written. A
    hardlink did the same with no symlink involved. assert_inside_scratch() therefore re-checks
    the RESOLVED path, refuses a symlink, a non-regular file and st_nlink > 1, and runs BOTH in
    the per-file loop (so the dry run reports it) and as the first statement of write_tags() (so
    no caller can reach a write without it). A refusal is a .failed record, never a skip.
  * THE REAL RUN WRITES NOTHING TO THE SYSTEM TEMP DIRECTORY. On LXC 100 the system temp
    directory is tmpfs backed by host RAM and a large spill there has previously taken the whole
    28 GB box down (T-01-15). A TARGET run needs no scratch file at all: mutagen saves in place
    and the NDJSON is streamed straight to --out, flushed per record so an interrupted run still
    leaves the evidence it had produced. The ONE use of `tempfile` is --self-test, which writes
    three WAVs of ~1.6 KB each into a private mkdtemp() directory and removes it. It is meant to
    run in a throwaway `docker run --rm` container, whose temp dir is the container's own
    writable layer, not LXC 100's tmpfs.
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
import shutil
import stat
import struct
import sys
import tempfile
import time
import unicodedata

# --------------------------------------------------------------------------------------------
# Constants. D-07: the fence is a hardcoded prefix, not an argument and not an env var.
# --------------------------------------------------------------------------------------------

SCRATCH_ROOT = "/mnt/tank/downloads/spike-03"
SNAPSHOT_NAME = "tank/downloads@spike-03-t0"

# The only fence root other than SCRATCH_ROOT that write_tags() will accept: --self-test's own
# mkdtemp() directory. See fence_root_or_raise().
SELFTEST_PREFIX = "normalise-dj-selftest-"

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
# The D-07 fence, re-asserted PER FILE. resolve_target_or_die() fences the TARGET; this fences
# every path that is about to be written.
# --------------------------------------------------------------------------------------------


def fence_root_or_raise(fence_root: str) -> str:
    """The resolved fence root: SCRATCH_ROOT, or --self-test's own mkdtemp() directory. Nothing else.

    The override exists so --self-test can drive the REAL write_tags(), fence included, on files
    it built itself. It is not a general knob: anything other than SCRATCH_ROOT must resolve to an
    existing directory whose parent is the system temp directory and whose name carries
    SELFTEST_PREFIX. realpath() first, so a symlink named like a self-test directory that points
    at the library resolves to the library and is refused.
    """
    if fence_root == SCRATCH_ROOT:
        return os.path.realpath(SCRATCH_ROOT)
    root = os.path.realpath(fence_root)
    tmp = os.path.realpath(tempfile.gettempdir())
    if (
        os.path.dirname(root) != tmp
        or not os.path.basename(root).startswith(SELFTEST_PREFIX)
        or not os.path.isdir(root)
    ):
        raise RuntimeError(
            f"refusing fence root {fence_root} -> {root}: only {SCRATCH_ROOT} or a "
            f"{tmp}/{SELFTEST_PREFIX}* self-test directory is accepted (D-07)"
        )
    return root


def assert_inside_scratch(path: str, *, fence_root: str = SCRATCH_ROOT) -> None:
    """Refuse to touch a file whose RESOLVED path is outside the scratch root (CR-04).

    `fence_root` is for --self-test only, and fence_root_or_raise() refuses every value except
    SCRATCH_ROOT and the self-test's own temp directory. The real run never passes it.

    resolve_target_or_die() realpaths the TARGET and refuses anything outside SCRATCH_ROOT, and
    the module docstring calls that the single most important behaviour in the file. It was then
    never applied again, and the write path does not go back through it:

      * collect_folders() walks with os.walk, which correctly does not DESCEND symlinked
        directories - but it still returns every matching FILE name, symlinks included.
      * write_tags() calls handle.save(path, ...) and preserve_id3v1_trailer() opens `path`
        r+b and seeks. Both FOLLOW a symlink and write to its target.

    So one symlink under the scratch tree pointing at the real library defeated the fence
    silently: the run reported a normal `changed` count and the NDJSON recorded the scratch
    path, not the path that was actually written. A HARDLINK defeated it identically with no
    symlink involved and nothing for os.walk to notice.

    Reachability was reduced but not eliminated by how the tree happens to be built today (GNU
    `cp -r` dereferences, so the reflinked copy contains regular files). Not eliminated,
    because the source is unattended usenet content on a live tree with an inflow (DEF-03-01,
    DEF-03-18) and because D-13 names this script as THE normalisation tool for later phases
    that will point it at other trees. A fence whose correctness depends on how a caller
    happened to create the tree is not a fence.

    Called from two places, deliberately:
      1. in the per-file loop, in BOTH modes, so the DRY RUN surfaces the refusal - the dry run
         is the D-08 review artefact and a preview that silently omits a refusal is not one;
      2. as the first statement of write_tags(), unconditionally, so no future caller can reach
         a write without passing it.

    Raises rather than exits, which routes the refusal into the .failed ledger - the behaviour
    the rest of this file already establishes for a file it will not process. A refused file is
    NEVER counted as unchanged.
    """
    root = fence_root_or_raise(fence_root)
    real = os.path.realpath(path)
    if real != root and not real.startswith(root + os.sep):
        raise RuntimeError(
            f"refusing to touch a path that resolves outside {root}: "
            f"{path} -> {real} (D-07)"
        )
    st = os.lstat(path)
    if stat.S_ISLNK(st.st_mode):
        raise RuntimeError(
            f"refusing to write through a symlink: {path} -> {real}. A write here would land "
            "on the target while the NDJSON recorded this path (D-07)"
        )
    if not stat.S_ISREG(st.st_mode):
        raise RuntimeError(f"refusing to write a non-regular file: {path} (D-07)")
    if st.st_nlink != 1:
        raise RuntimeError(
            f"refusing to write {path}: it has {st.st_nlink} hard links, so writing here also "
            f"writes every other name for the same inode - and those names need not be under "
            f"{root} (D-07)"
        )


# --------------------------------------------------------------------------------------------
# Tag I/O. mutagen only, ID3 major version preserved, every other frame untouched.
# --------------------------------------------------------------------------------------------


def id3v2_major(path: str, offset: int = 0) -> int | None:
    """The ID3v2 major version as it is ON DISK, read from the 10-byte header.

    Needed BEFORE the tag is loaded, because mutagen's `v2_version` is a LOAD-time option, not
    only a save-time one: `ID3(path)` defaults to `v2_version=4` and silently translates
    `TYER`/`TDAT`/`TIME` into `TDRC` in memory. Saving that back with `save(v2_version=3)` does
    NOT undo the translation - mutagen requires an explicit `update_to_v23()` - so the file ends
    up with a v2.3 header carrying a `TDRC` frame, which is a v2.4-only frame ID. Measured: a
    `TYER` frame of 5 bytes came back as a `TDRC` frame of 6. `ffprobe` maps both to `date`, so
    `diff-music-tags.sh` reports nothing and the change is invisible to the phase's own gate.

    `offset` is 0 for an MP3. For a WAV it is the data offset of the RIFF `id3 ` chunk
    (wave_id3_offset()), because that is where a WAVE's ID3 header sits.
    """
    try:
        with open(path, "rb") as fh:
            fh.seek(offset)
            head = fh.read(10)
    except OSError:
        return None
    return head[3] if head[:3] == b"ID3" else None


def id3v2_frame_ids(path: str, offset: int = 0) -> "collections.Counter[bytes] | None":
    """Multiset of ID3v2 frame IDs as they are ON DISK, parsed without mutagen.

    Deliberately independent of the library doing the writing: a post-write assertion that used
    mutagen's own view of the file could not catch mutagen normalising something on load. Returns
    None for ID3v2.2 (3-byte frame IDs) and for files with no ID3v2 tag, in which case the caller
    skips the assertion rather than guessing. `offset` as for id3v2_major().
    """
    try:
        with open(path, "rb") as fh:
            fh.seek(offset)
            head = fh.read(10)
            if head[:3] != b"ID3" or head[3] < 3:
                return None
            size = (head[6] << 21) | (head[7] << 14) | (head[8] << 7) | head[9]
            body = fh.read(size)
    except OSError:
        return None
    ids: "collections.Counter[bytes]" = collections.Counter()
    i = 0
    while i + 10 <= len(body):
        frame_id = body[i:i + 4]
        if frame_id == b"\x00\x00\x00\x00":
            break  # padding
        if head[3] == 4:
            fsz = ((body[i + 4] << 21) | (body[i + 5] << 14)
                   | (body[i + 6] << 7) | body[i + 7])
        else:
            fsz = int.from_bytes(body[i + 4:i + 8], "big")
        if fsz <= 0:
            break
        ids[frame_id] += 1
        i += 10 + fsz
    return ids


def riff_chunks(path: str) -> list[tuple[bytes, int, int]]:
    """[(chunk_id, data_offset, data_size)] for every top-level chunk of a RIFF/WAVE file.

    A WAV's ID3 tag lives in an `id3 ` chunk, not at offset 0, and its LIST/INFO chunk is a
    second, independent tag container that mutagen's WAVE API neither reads nor writes (D-23).
    Plain `struct`, deliberately: the stdlib `chunk` module is gone in Python 3.13. Raises
    ValueError on anything that is not a well-formed RIFF/WAVE, so a caller can keep "could not
    look" distinct from "nothing there".
    """
    chunks = []
    with open(path, "rb") as fh:
        head = fh.read(12)
        if len(head) < 12 or head[:4] != b"RIFF" or head[8:12] != b"WAVE":
            raise ValueError(f"not a RIFF/WAVE file: {path}")
        end = min(8 + struct.unpack("<I", head[4:8])[0], os.fstat(fh.fileno()).st_size)
        pos = 12
        while pos + 8 <= end:
            fh.seek(pos)
            cid, size = struct.unpack("<4sI", fh.read(8))
            if pos + 8 + size > end:
                raise ValueError(f"chunk {cid!r} at offset {pos} overruns the RIFF body: {path}")
            chunks.append((cid, pos + 8, size))
            pos += 8 + size + (size & 1)
    return chunks


def read_riff_info(path: str) -> dict[str, str]:
    """The RIFF LIST/INFO chunk as {4-char key: text}, e.g. {'IPRD': album}. {} if there is none.

    Read-only. This script never writes RIFF INFO (D-23); it reads it only to report when `IPRD`
    disagrees with the ID3 album it is about to write.
    """
    info: dict[str, str] = {}
    with open(path, "rb") as fh:
        for cid, offset, size in riff_chunks(path):
            if cid != b"LIST" or size < 4:
                continue
            fh.seek(offset)
            if fh.read(4) != b"INFO":
                continue
            body = fh.read(size - 4)
            i = 0
            while i + 8 <= len(body):
                key, n = struct.unpack("<4sI", body[i:i + 8])
                if i + 8 + n > len(body):
                    raise ValueError(f"INFO subchunk {key!r} overruns its LIST chunk: {path}")
                raw = body[i + 8:i + 8 + n].split(b"\x00", 1)[0]
                try:
                    text = raw.decode("utf-8")
                except UnicodeDecodeError:
                    text = raw.decode("latin-1")
                info[key.decode("latin-1")] = text
                i += 8 + n + (n & 1)
    return info


def is_wave(path: str) -> bool:
    """The ONE predicate that routes a file to the WAV branch of read_tags()/write_tags() (D-23)."""
    return path.lower().endswith(".wav")


def wave_id3_offset(path: str) -> int | None:
    """Data offset of the WAV's RIFF `id3 ` chunk, or None if it has none.

    Raises if there are two: which one a reader honours is then undefined, and the frame-set
    backstop would be checking a chunk the write might not have touched.
    """
    offsets = [off for cid, off, _size in riff_chunks(path) if cid in (b"id3 ", b"ID3 ")]
    if len(offsets) > 1:
        raise ValueError(f"{len(offsets)} ID3 chunks in one WAV; refusing to guess: {path}")
    return offsets[0] if offsets else None


def read_tags(path: str):
    """Return (handle, {'album': str|None, 'artist': str|None}). Raises on unreadable files."""
    import mutagen
    from mutagen.id3 import ID3, ID3NoHeaderError

    if is_wave(path):
        import mutagen.wave

        # D-23 / DEF-03-09. NOT easy mode: on a WAVE, `mutagen.File(path, easy=True).tags` is a
        # raw frame-keyed ID3, so `.get("album")` read None from every tagged WAV. Frame level
        # through FIELD_FRAME instead, exactly as the MP3 branch below does, and with the same
        # two load options for the same reasons: keep the on-disk ID3 major (or TYER/TDAT/TIME
        # become TDRC in memory and are written back so), and never merge an ID3v1 block.
        # A WAV with no ID3 chunk reads as all-None; the tag is added at WRITE time, never here.
        offset = wave_id3_offset(path)
        major = (id3v2_major(path, offset) if offset is not None else None) or 4
        w = mutagen.wave.WAVE(path, v2_version=3 if major <= 3 else 4, load_v1=False)
        values = {}
        for field in WRITABLE_FIELDS:
            frames = w.tags.getall(FIELD_FRAME[field]) if w.tags is not None else []
            text = frames[0].text[0] if frames and frames[0].text else None
            values[field] = text if (text is None or str(text).strip()) else None
        return w, values

    if path.lower().endswith(".mp3"):
        major = id3v2_major(path) or 4
        # BOTH keyword arguments are load-bearing and BOTH default the wrong way for this job:
        #   v2_version=3   keeps TYER/TDAT/TIME as they are on disk (see id3v2_major).
        #   load_v1=False  stops mutagen MERGING THE ID3v1 TAG INTO THE ID3v2 FRAME SET. With the
        #                  default `load_v1=True` it synthesises a `COMM:ID3v1 Comment:eng` frame
        #                  from the trailing ID3v1 block - and `save()` then WRITES that frame to
        #                  disk. Measured: 107 of 335 files gained an `ID3v1 Comment` key in
        #                  ffprobe output on the first apply, and a frame-header dump confirmed a
        #                  second COMM frame present on disk afterwards and absent before.
        try:
            tags = ID3(path, v2_version=3 if major <= 3 else 4, load_v1=False)
        except ID3NoHeaderError:
            tags = ID3()
        values = {}
        for field in WRITABLE_FIELDS:
            frames = tags.getall(FIELD_FRAME[field])
            text = frames[0].text[0] if frames and frames[0].text else None
            values[field] = text if (text is None or str(text).strip()) else None
        return tags, values

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
    # O_NOFOLLOW so this open cannot land on a symlink's target even if `path` became one
    # between assert_inside_scratch() and here (CR-04). It is a backstop for a TOCTOU window,
    # not the fence itself. Absent on some platforms, hence the getattr.
    fd = os.open(path, os.O_RDWR | getattr(os, "O_NOFOLLOW", 0))
    with os.fdopen(fd, "r+b") as fh:
        fh.seek(-128, os.SEEK_END)
        current = fh.read(128)
        if current[:3] != b"TAG":
            raise RuntimeError("ID3v1 trailer disappeared during save; refusing to guess")
        if current != original:
            fh.seek(-128, os.SEEK_END)
            fh.write(original)


def assert_frame_set_unchanged(path, before, changes: dict[str, str], *, offset: int = 0) -> None:
    """After the write, the on-disk ID3v2 frame-ID multiset must be what it was, plus the two.

    `offset` is where the ID3 tag starts: 0 for MP3, the `id3 ` chunk for a WAV. Without it this
    read `RIFF` at offset 0 for every WAV and returned silently, a vacuous pass. The WAV branch
    re-locates the chunk AFTER the save (an untagged WAV has none before it), and passes an
    empty multiset, never None, as `before` for an untagged WAV so the check still runs.

    This is the backstop for the class of defect that produced three corrections in this plan:
    mutagen does not write back what it read - it re-serialises its own normalised model, and two
    of its defaults quietly broaden the write (`load_v1`, `v2_version`). Both are now set
    correctly, and this assertion exists so that a THIRD such default, or a change in a future
    mutagen release, fails LOUDLY into the .failed ledger instead of silently enlarging the diff.

    "Assert rather than report" - README § Health Checks. Frame ENCODINGS and SIZES are allowed to
    move (mutagen terminates latin-1 text frames with a NUL, which is legal and harmless); frame
    IDENTITY is not.
    """
    if before is None:
        return
    after = id3v2_frame_ids(path, offset)
    if after is None:
        raise RuntimeError("ID3v2 tag became unreadable during save")
    written = {FIELD_FRAME[f].encode("ascii") for f in changes}
    b = {k: v for k, v in before.items() if k not in written}
    a = {k: v for k, v in after.items() if k not in written}
    if a != b:
        added = {k: a[k] for k in a if b.get(k) != a[k]}
        removed = {k: b[k] for k in b if a.get(k) != b[k]}
        raise RuntimeError(
            f"ID3v2 frame set changed beyond {sorted(x.decode() for x in written)}: "
            f"added/changed={added} removed/changed={removed}"
        )
    for frame_id in written:
        if after.get(frame_id, 0) != 1:
            raise RuntimeError(
                f"expected exactly one {frame_id.decode()} frame after the write, "
                f"found {after.get(frame_id, 0)}"
            )


def write_tags(
    handle, path: str, changes: dict[str, str], *, fence_root: str = SCRATCH_ROOT
) -> None:
    """Write ONLY the fields in WRITABLE_FIELDS, and ONLY inside the scratch root.

    Both are asserted, not assumed, and the fence is FIRST - before any byte can move. It is
    also checked in the per-file loop so the dry run reports it, but this call is the one that
    cannot be bypassed by a future caller (CR-04).
    """
    assert_inside_scratch(path, fence_root=fence_root)

    for field in changes:
        if field not in WRITABLE_FIELDS:
            raise AssertionError(f"refusing to write non-writable field {field!r}")

    if is_wave(path):
        import mutagen.id3 as id3

        # D-23: ID3 ONLY. mutagen's WAVE save rewrites the `id3 ` chunk and leaves the RIFF
        # LIST/INFO chunk byte-identical; a stale IPRD is reported by build_record() as
        # `info_iprd`, never rewritten here.
        offset = wave_id3_offset(path)
        if offset is None:
            frames_before = collections.Counter()  # untagged: afterwards exactly the written set
            major = 3
        else:
            frames_before = id3v2_frame_ids(path, offset)
            if frames_before is None:
                # ID3v2.2 or an unparseable header. The MP3 branch skips its backstop here; a
                # WAV write refuses instead, because writing without the backstop is exactly the
                # silent path it exists to close.
                raise RuntimeError(
                    "WAV id3 chunk is not a parseable ID3v2.3/2.4 tag; refusing to write "
                    "without the frame-set backstop"
                )
            major = id3v2_major(path, offset) or 3
        if handle.tags is None:
            handle.add_tags()
        for field, new in changes.items():
            frame_id = FIELD_FRAME[field]
            existing = handle.tags.getall(frame_id)
            # The MP3 branch's encoding choice, unchanged: reuse the frame's encoding when the
            # new value fits it, otherwise UTF-16 with BOM.
            encoding = existing[0].encoding if existing else 1
            try:
                new.encode({0: "latin-1", 1: "utf-16", 2: "utf-16-be", 3: "utf-8"}[encoding])
            except (UnicodeEncodeError, KeyError):
                encoding = 1
            handle.tags.setall(frame_id, [getattr(id3, frame_id)(encoding=encoding, text=[new])])
        handle.save(v2_version=3 if major <= 3 else 4)
        offset_after = wave_id3_offset(path)
        if offset_after is None:
            raise RuntimeError("WAV has no id3 chunk after the save")
        assert_frame_set_unchanged(path, frames_before, changes, offset=offset_after)
        return

    if path.lower().endswith(".mp3"):
        import mutagen.id3 as id3

        id3v1_before = read_id3v1_trailer(path)
        frames_before = id3v2_frame_ids(path)
        major = id3v2_major(path) or 3
        for field, new in changes.items():
            frame_id = FIELD_FRAME[field]
            existing = handle.getall(frame_id)
            # Reuse the frame's existing text encoding when the new value fits it; otherwise
            # UTF-16 with BOM (3 is UTF-8, which ID3v2.3 does not define).
            encoding = existing[0].encoding if existing else 1
            try:
                new.encode({0: "latin-1", 1: "utf-16", 2: "utf-16-be", 3: "utf-8"}[encoding])
            except (UnicodeEncodeError, KeyError):
                encoding = 1
            handle.setall(frame_id, [getattr(id3, frame_id)(encoding=encoding, text=[new])])
        handle.save(path, v2_version=3 if major <= 3 else 4)
        preserve_id3v1_trailer(path, id3v1_before)
        assert_frame_set_unchanged(path, frames_before, changes)
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
    # nargs="?" only so --self-test can run without one; a missing TARGET is still an argparse
    # error and still exits 2, enforced below.
    p.add_argument("target", nargs="?", help=f"directory under {SCRATCH_ROOT}")
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
    p.add_argument(
        "--self-test",
        action="store_true",
        help=(
            "the D-23 WAV regression test: three synthetic WAVs in a private temp directory, "
            "driven through the real read/write/record code. Takes no TARGET. Run it inside "
            "the beets image"
        ),
    )
    args = p.parse_args(argv)
    if args.self_test:
        if args.target or args.apply or args.dry_run or args.snapshot_proof or args.out:
            p.error("--self-test takes no TARGET, no mode flag, no --snapshot-proof and no --out")
    elif args.target is None:
        p.error("the following arguments are required: target")
    return args


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


def build_record(*, mode, folder, path, field, rule, old, new, written, artist_policy) -> dict:
    """One NDJSON record per (file, field) change: the shape --out has always written.

    Factored out of main() so --self-test checks the record the real run emits, not a copy of it.

    D-23: an album record for a WAV whose RIFF `IPRD` is non-empty and differs from the new album
    carries `info_iprd`, the stale INFO value this script deliberately leaves in place. An INFO
    chunk that cannot be parsed is `info_riff_unreadable`, kept distinct from "no IPRD".
    """
    record = {
        "mode": mode,
        "folder": folder,
        "path": path,
        "field": field,
        "rule": rule,
        "old": old,
        "new": new,
        "written": written,
        "artist_policy": artist_policy,
    }
    if field == "album" and is_wave(path):
        try:
            iprd = read_riff_info(path).get("IPRD")
        except (OSError, ValueError) as exc:
            record["info_riff_unreadable"] = f"{type(exc).__name__}: {str(exc)[:200]}"
        else:
            if iprd and iprd.strip() and iprd.strip() != (new or "").strip():
                record["info_iprd"] = iprd
    return record


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

    if args.self_test:
        # Before resolve_target_or_die(): the self-test has no TARGET and touches only its own
        # temp directory.
        return self_test()

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
            # CR-04: the D-07 fence, on the RESOLVED path, in BOTH modes. Runs here as well as
            # inside write_tags() so the DRY RUN reports the refusal - the dry run is the D-08
            # review artefact, and a preview that silently omits a file the apply would refuse
            # is not a preview. A refusal is a .failed record, never a skip and never an
            # "unchanged".
            try:
                assert_inside_scratch(path)
            except Exception as exc:  # noqa: BLE001 - routed to the ledger, never swallowed
                counts["failed"] += 1
                log.error("fence refused %s: %s", path, exc)
                if failed_fh:
                    failed_fh.write(
                        json.dumps(
                            {
                                "path": path,
                                "stage": "fence",
                                "exception": type(exc).__name__,
                                "detail": str(exc)[:400],
                            }
                        )
                        + "\n"
                    )
                    failed_fh.flush()
                continue
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
                            build_record(
                                mode="apply" if applying else "dry-run",
                                folder=folder_name,
                                path=path,
                                field=field,
                                rule=rule,
                                old=old,
                                new=new,
                                written=written,
                                artist_policy=args.artist_policy,
                            )
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


# --------------------------------------------------------------------------------------------
# --self-test (D-23). Table-driven ok/bad in the shape of scripts/spike03-wrtag-arms.sh
# self_test(): one line per case, a reason under every `bad`, a failure count, exit 1 on any.
# --------------------------------------------------------------------------------------------

SELFTEST_NEW_ALBUM = "Self Test Album"
SELFTEST_OLD_ALBUM = "Old Album"
SELFTEST_KEPT_FRAMES = ("APIC", "TDRC", "TIT2", "TPE1", "TRCK")
SELFTEST_PNG = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR"

# name | ID3 tag? | TPE1 | RIFF IPRD (None = no LIST/INFO chunk) | why the case exists
SELFTEST_CASES = (
    ("untagged-wav", False, None, None,
     "no ID3 chunk at all: the write must create one holding exactly TALB"),
    ("ascii-wav", True, "Self Test Artist", None,
     "ASCII ID3: TALB replaced, APIC/TDRC/TIT2/TPE1/TRCK untouched, no info_iprd without INFO"),
    ("non-ascii-wav", True, "Beyoncé Knowles – Ñ", SELFTEST_OLD_ALBUM,
     "non-ASCII TPE1 + stale RIFF IPRD: ID3 written, INFO untouched, info_iprd recorded"),
)


def _selftest_inject_info(path: str, info: dict[str, str]) -> None:
    """Append a LIST/INFO chunk and fix up the RIFF size.

    SELF-TEST FIXTURE ONLY. The real run never writes RIFF INFO (D-23).
    """
    body = b"INFO"
    for key, value in info.items():
        data = value.encode("utf-8") + b"\x00"
        body += key.encode("ascii") + struct.pack("<I", len(data)) + data
        body += b"\x00" * (len(data) & 1)
    with open(path, "r+b") as fh:
        fh.seek(0, os.SEEK_END)
        fh.write(b"LIST" + struct.pack("<I", len(body)) + body)
        riff_size = fh.tell() - 8
        fh.seek(4)
        fh.write(struct.pack("<I", riff_size))


def _selftest_build(path: str, tagged: bool, artist: str | None, iprd: str | None) -> None:
    import wave

    import mutagen.id3 as id3
    import mutagen.wave

    with wave.open(path, "wb") as pcm:  # 0.1 s of 16-bit mono silence
        pcm.setnchannels(1)
        pcm.setsampwidth(2)
        pcm.setframerate(8000)
        pcm.writeframes(b"\x00\x00" * 800)
    if iprd is not None:
        _selftest_inject_info(path, {"IPRD": iprd, "INAM": "Self Test Title"})
    if tagged:
        w = mutagen.wave.WAVE(path)
        w.add_tags()
        for frame in (
            id3.TIT2(encoding=3, text=["Self Test Title"]),
            id3.TPE1(encoding=3, text=[artist]),
            id3.TRCK(encoding=3, text=["3/12"]),
            id3.TDRC(encoding=3, text=["2020-05-01"]),
            id3.APIC(encoding=3, mime="image/png", type=3, desc="cover", data=SELFTEST_PNG),
            id3.TALB(encoding=3, text=[SELFTEST_OLD_ALBUM]),
        ):
            w.tags.add(frame)
        w.save()


def _selftest_frames(path: str) -> dict[str, tuple]:
    """The oracle: {HashKey: (FrameID, encoding, text, mime, type, desc, data)} for every frame.

    Read straight through mutagen.wave, NOT through read_tags(): the thing under test does not
    get to grade itself.
    """
    import mutagen.wave

    w = mutagen.wave.WAVE(path)
    if w.tags is None:
        return {}
    out = {}
    for key in sorted(w.tags.keys()):
        f = w.tags[key]
        out[key] = (
            f.FrameID,
            getattr(f, "encoding", None),
            tuple(str(t) for t in getattr(f, "text", ())),
            getattr(f, "mime", None),
            getattr(f, "type", None),
            getattr(f, "desc", None),
            getattr(f, "data", None),
        )
    return out


def _selftest_case(tmp: str, name: str, tagged: bool, artist, iprd) -> list[str]:
    """Run one case through the real read_tags() / write_tags() / build_record(). [] means ok."""
    path = os.path.join(tmp, name + ".wav")
    _selftest_build(path, tagged, artist, iprd)
    frames_before = _selftest_frames(path)
    info_before = read_riff_info(path)
    problems: list[str] = []

    # Non-vacuity: a fixture that lacks what the checks compare would pass them trivially.
    if tagged:
        have = {v[0] for v in frames_before.values()}
        missing = [f for f in SELFTEST_KEPT_FRAMES + ("TALB",) if f not in have]
        if missing:
            problems.append(f"fixture lacks {missing}: the frame checks would be vacuous")
    if iprd is not None and info_before.get("IPRD") != iprd:
        problems.append(f"fixture IPRD = {info_before.get('IPRD')!r}, expected {iprd!r}")

    want_old = SELFTEST_OLD_ALBUM if tagged else None
    handle, values = read_tags(path)
    if values["album"] != want_old:
        problems.append(
            f"read_tags() album before the write = {values['album']!r}, expected {want_old!r}"
        )

    try:
        write_tags(handle, path, {"album": SELFTEST_NEW_ALBUM}, fence_root=tmp)
    except Exception as exc:  # noqa: BLE001 - the failure IS the finding
        problems.append(f"write_tags() raised {type(exc).__name__}: {str(exc)[:160]}")
        return problems

    _handle, after = read_tags(path)
    if after["album"] != SELFTEST_NEW_ALBUM:
        problems.append(
            f"read_tags() album after the write = {after['album']!r}, "
            f"expected {SELFTEST_NEW_ALBUM!r}"
        )

    frames_after = _selftest_frames(path)
    talb = [v[2] for v in frames_after.values() if v[0] == "TALB"]
    if talb != [(SELFTEST_NEW_ALBUM,)]:
        problems.append(f"on-disk TALB after the write = {talb}, expected [{SELFTEST_NEW_ALBUM!r}]")

    for key in sorted(set(frames_before) | set(frames_after)):
        fid = (frames_before.get(key) or frames_after.get(key))[0]
        if fid == "TALB":
            continue
        if frames_before.get(key) != frames_after.get(key):
            problems.append(
                f"{key} changed: {frames_before.get(key)!r} -> {frames_after.get(key)!r}"
            )

    info_after = read_riff_info(path)
    if info_after != info_before:
        problems.append(
            f"RIFF LIST/INFO changed: {info_before} -> {info_after} (D-23 writes ID3 only)"
        )

    rec = json.loads(
        json.dumps(
            build_record(
                mode="apply", folder="self-test", path=path, field="album", rule=0,
                old=want_old, new=SELFTEST_NEW_ALBUM, written=True, artist_policy="self-test",
            )
        )
    )
    if iprd is not None:
        if rec.get("info_iprd") != iprd:
            problems.append(f"NDJSON info_iprd = {rec.get('info_iprd')!r}, expected {iprd!r}")
    elif "info_iprd" in rec:
        problems.append(f"NDJSON carries info_iprd={rec['info_iprd']!r} with no RIFF IPRD")
    return problems


def self_test() -> int:
    """--self-test. Exit 0 every case ok, 1 any case bad, 2 could not run."""
    out = sys.stdout
    out.write("== normalise-dj-tags.py --self-test: the WAV write path (D-23, DEF-03-09) ==\n")
    try:
        import mutagen
        import mutagen.wave  # noqa: F401
    except ImportError as exc:
        out.write(
            f"COULD NOT RUN: mutagen is not importable ({exc}). Run inside "
            "lscr.io/linuxserver/beets:2.13.1-ls349 - see the module docstring.\n"
        )
        return 2
    out.write(f"   python {sys.version.split()[0]}, mutagen {mutagen.version_string}\n")
    fails = 0
    tmp = tempfile.mkdtemp(prefix=SELFTEST_PREFIX)
    try:
        for name, tagged, artist, iprd, why in SELFTEST_CASES:
            try:
                problems = _selftest_case(tmp, name, tagged, artist, iprd)
            except Exception as exc:  # noqa: BLE001 - a raising case is a failing case
                problems = [f"case raised {type(exc).__name__}: {str(exc)[:160]}"]
            if problems:
                fails += 1
                out.write(f"bad  {name}: {why}\n")
                for problem in problems:
                    out.write(f"       reason: {problem}\n")
            else:
                out.write(f"ok   {name}: {why}\n")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    if os.path.exists(tmp):
        fails += 1
        out.write(f"bad  cleanup: {tmp} still exists after rmtree\n")
    out.write(f"-- {len(SELFTEST_CASES)} cases, {fails} failed --\n")
    out.flush()
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
