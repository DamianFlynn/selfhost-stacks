#!/usr/bin/env python3
"""framecheck.py LIVE_ROOT SNAP_DIR [--limit N] [--negative-control]

Independent re-check of the two properties the tag writer must not move, against a before-side
this plan did not produce: the ZFS snapshot `tank/downloads@pre-phase5`, which predates the junk
sweep, the split and every tag write.

For each mp3 under LIVE_ROOT it finds the twin in SNAP_DIR by BASENAME (plan 05-07 proved the
4,746 basenames are distinct and 0 fail to join) and asserts:

  1. the ID3v2 frame-ID MULTISET is identical - parsed WITHOUT mutagen, so the assertion is not
     made by the library that did the writing;
  2. the trailing 128-byte ID3v1 block is BYTE-IDENTICAL.

Frame VALUES are deliberately not compared: TALB's value is exactly what this plan set out to
change. Frame IDENTITY and the ID3v1 bytes are what must not move.

--negative-control deliberately joins each file to the WRONG twin (the next basename in sort
order) and must report failures. An instrument that has only ever been seen to pass has not been
shown to distinguish anything.

Exit 0 only when every file joined and every assertion held; 1 otherwise; 2 on a usage error.
"""
import collections
import hashlib
import os
import sys


def frame_ids(path, offset=0):
    """Multiset of ID3v2 frame IDs as they are on disk. None if there is no parseable v2.3/2.4 tag."""
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
    ids = collections.Counter()
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
        ids[fid] += 1
        i += 10 + fsz
    return ids


def id3v1(path):
    """md5 of the trailing 128 bytes when they are an ID3v1 tag, else the literal 'none'."""
    try:
        if os.path.getsize(path) < 128:
            return "short"
        with open(path, "rb") as fh:
            fh.seek(-128, os.SEEK_END)
            tail = fh.read(128)
    except OSError:
        return "unreadable"
    return hashlib.md5(tail).hexdigest() if tail[:3] == b"TAG" else "none"


def fp(path):
    ids = frame_ids(path)
    return (None if ids is None else tuple(sorted((k.decode("latin-1"), v) for k, v in ids.items())),
            id3v1(path))


if len(sys.argv) < 3:
    sys.stderr.write(__doc__)
    sys.exit(2)

live_root, snap_dir = sys.argv[1], sys.argv[2]
negative = "--negative-control" in sys.argv[3:]

snap = {}
for name in os.listdir(snap_dir):
    if name.lower().endswith(".mp3"):
        snap[name] = os.path.join(snap_dir, name)

live = []
for dirpath, dirnames, filenames in os.walk(live_root):
    dirnames.sort()
    for name in sorted(filenames):
        if name.lower().endswith(".mp3"):
            live.append(os.path.join(dirpath, name))
live.sort()

snap_names = sorted(snap)
shift = {n: snap_names[(i + 1) % len(snap_names)] for i, n in enumerate(snap_names)}

unjoined, frameset_moved, id3v1_moved, unparseable = [], [], [], []
checked = 0
for path in live:
    base = os.path.basename(path)
    key = shift[base] if (negative and base in shift) else base
    twin = snap.get(key)
    if twin is None:
        unjoined.append(path)
        continue
    checked += 1
    a_ids, a_v1 = fp(path)
    b_ids, b_v1 = fp(twin)
    if a_ids is None or b_ids is None:
        unparseable.append(path)
        continue
    if a_ids != b_ids:
        frameset_moved.append((path, sorted(set(a_ids) ^ set(b_ids))))
    if a_v1 != b_v1:
        id3v1_moved.append((path, b_v1, a_v1))

print(f"mode                                   : {'NEGATIVE CONTROL' if negative else 'assertion'}")
print(f"live mp3 found                         : {len(live)}")
print(f"snapshot mp3 available                 : {len(snap)}")
print(f"joined by basename                     : {checked}")
print(f"UNJOINED (must be 0)                   : {len(unjoined)}")
for p in unjoined[:5]:
    print(f"    ! {p}")
print(f"UNPARSEABLE ID3v2 either side (must be 0): {len(unparseable)}")
for p in unparseable[:5]:
    print(f"    ! {p}")
print(f"ID3v2 FRAME SET MOVED (must be 0)      : {len(frameset_moved)}")
for p, d in frameset_moved[:5]:
    print(f"    ! {p}  symmetric difference={d}")
print(f"ID3v1 TRAILER MOVED (must be 0)        : {len(id3v1_moved)}")
for p, b, a in id3v1_moved[:5]:
    print(f"    ! {p}  before={b} after={a}")

fail = bool(unjoined or unparseable or frameset_moved or id3v1_moved)
print("VERDICT: " + ("FAIL" if fail else "PASS"))
sys.exit(1 if fail else 0)
