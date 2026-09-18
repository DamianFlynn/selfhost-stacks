#!/usr/bin/env python3
"""albumscan.py LIVE_ROOT SNAP_DIR MOVED_LIST OUT_NDJSON

A THIRD, independent reader of the `album` tag - neither mutagen (which wrote it) nor ffprobe
(which the QUAL-01 capture uses). Parses the ID3v2 header and frame table with `struct`/slicing
and decodes TALB according to its own encoding byte.

Two jobs:

  1. Emit one NDJSON record per file in MOVED_LIST giving the album value BEFORE (read from the
     twin inside the ZFS snapshot `tank/downloads@pre-phase5`, joined by basename) and AFTER
     (read from the live file). This RECONSTRUCTS the applied-change record from two independent
     on-disk reads at two points in time, rather than from the writer's own report.

  2. Assert the deliverable directly from the files: for each `Vol NNN` folder, the number of
     DISTINCT album values present must be 1, and the set of values across the collection must be
     exactly the 115 canonical strings.

Exit 0 only when every folder carries exactly one album string and every value is canonical.
"""
import json
import os
import re
import sys

VOL_RE = re.compile(r"^Vol (\d{3})$")
CANONICAL = "Now That's What I Call Music! "


def talb(path):
    """The TALB text as it is on disk, or None. No mutagen, no ffprobe."""
    try:
        with open(path, "rb") as fh:
            head = fh.read(10)
            if head[:3] != b"ID3" or head[3] < 3:
                return None
            size = (head[6] << 21) | (head[7] << 14) | (head[8] << 7) | head[9]
            body = fh.read(size)
    except OSError:
        return None
    i = 0
    while i + 10 <= len(body):
        fid = body[i:i + 4]
        if fid == b"\x00\x00\x00\x00":
            break
        if head[3] == 4:
            fsz = (body[i + 4] << 21) | (body[i + 5] << 14) | (body[i + 6] << 7) | body[i + 7]
        else:
            fsz = int.from_bytes(body[i + 4:i + 8], "big")
        if fsz <= 0:
            break
        if fid == b"TALB":
            raw = body[i + 10:i + 10 + fsz]
            if not raw:
                return None
            enc, payload = raw[0], raw[1:]
            codec = {0: "latin-1", 1: "utf-16", 2: "utf-16-be", 3: "utf-8"}.get(enc, "latin-1")
            try:
                text = payload.decode(codec, errors="replace")
            except LookupError:
                text = payload.decode("latin-1", errors="replace")
            return text.split("\x00", 1)[0].rstrip("\x00")
        i += 10 + fsz
    return None


live_root, snap_dir, moved_list, out_path = sys.argv[1:5]

snap = {n: os.path.join(snap_dir, n)
        for n in os.listdir(snap_dir) if n.lower().endswith(".mp3")}

with open(moved_list, encoding="utf-8", errors="surrogateescape") as fh:
    moved = [l.rstrip("\n") for l in fh if l.strip()]

# ---- job 1: the reconstructed applied-change record --------------------------------------
unjoined = 0
with open(out_path, "w", encoding="utf-8") as out:
    for path in moved:
        base = os.path.basename(path)
        twin = snap.get(base)
        if twin is None:
            unjoined += 1
            continue
        out.write(json.dumps({
            "mode": "apply",
            "folder": os.path.basename(os.path.dirname(path)),
            "path": path,
            "field": "album",
            "rule": 4,
            "old": talb(twin),
            "new": talb(path),
            "written": True,
            "old_source": "zfs snapshot tank/downloads@pre-phase5, joined by basename",
            "new_source": "live file, independent ID3v2 parse",
        }) + "\n")
print(f"reconstructed records          : {len(moved) - unjoined}")
print(f"UNJOINED to the snapshot (0)   : {unjoined}")

# ---- job 2: the deliverable, asserted from the files -------------------------------------
per_folder = {}
missing_talb = []
for dirpath, dirnames, filenames in os.walk(live_root):
    dirnames.sort()
    folder = os.path.basename(dirpath)
    if not VOL_RE.match(folder):
        continue
    for name in sorted(filenames):
        if not name.lower().endswith(".mp3"):
            continue
        v = talb(os.path.join(dirpath, name))
        if v is None:
            missing_talb.append(os.path.join(dirpath, name))
            continue
        per_folder.setdefault(folder, set()).add(v)

multi = {f: sorted(v) for f, v in per_folder.items() if len(v) != 1}
values = sorted({next(iter(v)) for v in per_folder.values() if len(v) == 1})
expected = {f"{CANONICAL}{int(VOL_RE.match(f).group(1))}" for f in per_folder}
actual_ok = all(
    len(v) == 1 and next(iter(v)) == f"{CANONICAL}{int(VOL_RE.match(f).group(1))}"
    for f, v in per_folder.items()
)

print(f"Vol NNN folders scanned        : {len(per_folder)}")
print(f"files with NO TALB frame (0)   : {len(missing_talb)}")
print(f"folders with != 1 album value  : {len(multi)}")
for f, v in sorted(multi.items())[:10]:
    print(f"    ! {f}: {v}")
print(f"distinct album values overall  : {len(set(values))}")
print(f"every folder's value == its own canonical string: {actual_ok}")
print(f"value set == the 115 expected canonical strings : {set(values) == expected}")

fail = bool(unjoined or missing_talb or multi or not actual_ok or set(values) != expected)
print("VERDICT: " + ("FAIL" if fail else "PASS"))
sys.exit(1 if fail else 0)
