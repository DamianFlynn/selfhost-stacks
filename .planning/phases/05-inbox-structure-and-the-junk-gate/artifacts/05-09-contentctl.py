#!/usr/bin/env python3
"""contentctl.py SNAP_DIR WRITTEN_LIST ALL_LIST N

The replacement for the plan's `zfs diff` scope criterion, which is VACUOUS here: plan 05-07
renamed every mp3 in this collection relative to @pre-phase5, and `zfs diff` collapses
"renamed AND modified" into a single `R` record, so it reports 0 `M` lines on mp3 whether this
plan wrote 751 files or zero.

This compares FILE CONTENT against the snapshot twin instead, and it is discriminating in BOTH
directions, which is the whole point:

  * a sample of files this plan WROTE      -> whole-file md5 MUST DIFFER from the snapshot twin
  * a sample of files this plan DID NOT write -> whole-file md5 MUST BE IDENTICAL

Either expectation failing is a failure. A run where the second sample differed would mean the
write reached files outside its intended set; a run where the first sample matched would mean the
instrument cannot see a write at all, and every other "unchanged" result it reports is worthless.

Deliberately bounded to N files per arm: the twins are read off spinning disk and an unbounded
pass over 45 GB x 2 is what drove the host into memory pressure earlier in this plan.
"""
import hashlib
import os
import sys

snap_dir, written_list, all_list, n = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])


def read_list(p):
    with open(p, encoding="utf-8", errors="surrogateescape") as fh:
        return [l.rstrip("\n") for l in fh if l.strip()]


def md5(p):
    h = hashlib.md5()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


written = read_list(written_list)
allfiles = [l.split("\t")[0] if "\t" in l else l for l in read_list(all_list)]
allfiles = [p for p in allfiles if p.lower().endswith(".mp3")]
wset = set(written)
unwritten = [p for p in allfiles if p not in wset]

# Spread across volumes rather than taking a contiguous block: stride the sorted list.
def spread(xs, k):
    if len(xs) <= k:
        return list(xs)
    step = len(xs) / k
    return [xs[int(i * step)] for i in range(k)]


arm_w = spread(sorted(wset), n)
arm_u = spread(sorted(unwritten), n)

bad_w, bad_u, missing = [], [], []
for p in arm_w:
    twin = os.path.join(snap_dir, os.path.basename(p))
    if not os.path.exists(twin):
        missing.append(p)
        continue
    if md5(p) == md5(twin):
        bad_w.append(p)
for p in arm_u:
    twin = os.path.join(snap_dir, os.path.basename(p))
    if not os.path.exists(twin):
        missing.append(p)
        continue
    if md5(p) != md5(twin):
        bad_u.append(p)

print(f"WRITTEN arm   : {len(arm_w)} files, spread over "
      f"{len({os.path.basename(os.path.dirname(p)) for p in arm_w})} volumes")
print(f"  files whose content MATCHES the snapshot (must be 0): {len(bad_w)}")
for p in bad_w[:5]:
    print(f"    ! {p}")
print(f"UNWRITTEN arm : {len(arm_u)} files, spread over "
      f"{len({os.path.basename(os.path.dirname(p)) for p in arm_u})} volumes")
print(f"  files whose content DIFFERS from the snapshot (must be 0): {len(bad_u)}")
for p in bad_u[:5]:
    print(f"    ! {p}")
print(f"twins not found in the snapshot (must be 0): {len(missing)}")
fail = bool(bad_w or bad_u or missing)
print("VERDICT: " + ("FAIL" if fail else "PASS"))
sys.exit(1 if fail else 0)
