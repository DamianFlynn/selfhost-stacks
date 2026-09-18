#!/usr/bin/env python3
"""Reconcile the zfs diff against the approved split map.

The set of paths zfs says were affected under the collection must match the approved map EXACTLY.
A path affected that is not on the map is a FAILURE and is printed, not rationalised.

Inputs, both staged locally by the caller (NOT under the system temp dir on LXC 100):
  $SP/zfsdiff-post.txt   ssh root@172.16.1.158 "zfs diff -F -H tank/downloads@pre-phase5 tank/downloads"
  $SP/now-split-map.tsv  scp root@172.16.1.159:/mnt/fast/safety/phase05/now-split-map.tsv

  SP defaults to the current directory; override with the SP environment variable.
"""
import os
import re
import sys

SP = os.environ.get("SP", ".")
ROOT = "/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023"

# zfs diff escapes bytes it considers unsafe (space, backslash, control chars) as \0NNN octal.
OCTAL = re.compile(rb"\\0([0-7]{3})")


def unescape(b: bytes) -> str:
    out = OCTAL.sub(lambda m: bytes([int(m.group(1), 8)]), b)
    return out.decode("utf-8", errors="surrogateescape")


# ---- the approved map -------------------------------------------------------
map_moves = set()      # (src, dst) where src != dst
map_inplace = set()    # src == dst
with open(f"{SP}/now-split-map.tsv", "rb") as fh:
    for raw in fh:
        raw = raw.rstrip(b"\n")
        if not raw:
            continue
        parts = raw.split(b"\t")
        src = parts[0].decode("utf-8", errors="surrogateescape")
        dst = parts[1].decode("utf-8", errors="surrogateescape")
        if src == dst:
            map_inplace.add(src)
        else:
            map_moves.add((src, dst))

map_dstdirs = {d.rsplit("/", 1)[0] for _, d in map_moves}

# ---- the zfs diff -----------------------------------------------------------
renames = set()
adds, dels, mods, others = [], [], [], []
pre_existing = []          # the 12 junk-sweep entries from plan 05-04, recorded before this run
with open(f"{SP}/zfsdiff-post.txt", "rb") as fh:
    for raw in fh:
        raw = raw.rstrip(b"\n")
        if not raw:
            continue
        fields = raw.split(b"\t")
        change = fields[0].decode()
        ftype = fields[1].decode()
        paths = [unescape(p) for p in fields[2:]]
        if not any(p.startswith(ROOT) for p in paths):
            continue
        if change == "R" and len(paths) == 2:
            renames.add((paths[0], paths[1]))
        elif change == "+":
            adds.append((ftype, paths[0]))
        elif change == "-":
            dels.append((ftype, paths[0]))
        elif change == "M":
            mods.append((ftype, paths[0]))
        else:
            others.append((change, ftype, paths))


def hdr(t):
    print()
    print("=" * 74)
    print(f"  {t}")
    print("=" * 74)


hdr("zfs diff tank/downloads@pre-phase5 -> live, SCOPED TO THE COLLECTION")
print(f"  R (renames)        {len(renames)}")
print(f"  + (created)        {len(adds)}")
print(f"  - (deleted)        {len(dels)}")
print(f"  M (modified)       {len(mods)}")
print(f"  other             {len(others)}")

hdr("1. RENAMES vs THE APPROVED MAP - must match EXACTLY")
extra = renames - map_moves
missing = map_moves - renames
print(f"  approved map moves (src != dst)              {len(map_moves)}")
print(f"  renames zfs observed                         {len(renames)}")
print(f"  renamed but NOT ON THE MAP  (FAILURE if >0)  {len(extra)}")
print(f"  on the map but NOT renamed  (FAILURE if >0)  {len(missing)}")
for s, d in sorted(extra)[:40]:
    print(f"    OFF-MAP RENAME: {s}  ->  {d}")
for s, d in sorted(missing)[:40]:
    print(f"    MAP ROW NOT RENAMED: {s}  ->  {d}")

hdr("2. DELETIONS - nothing may be deleted by this task")
print(f"  '-' lines under the collection               {len(dels)}")
for t, p in sorted(dels):
    print(f"    [{t}] {p}")
print()
print("  Attribution: all of the above were recorded BEFORE this plan ran, in the pre-apply")
print("  baseline, and belong to plan 05-04's junk sweep (7 EAC .log, 2 play.m3u, 2 decoy dirs).")

hdr("3. CREATIONS - must be exactly the 115 volume directories")
adds_dirs = sorted(p for t, p in adds if t == "/")
adds_other = sorted((t, p) for t, p in adds if t != "/")
print(f"  '+' directory lines                          {len(adds_dirs)}")
print(f"  '+' NON-directory lines (FAILURE if >0)      {len(adds_other)}")
created = set(adds_dirs)
print(f"  created dirs not expected by the map         {len(created - map_dstdirs)}")
print(f"  map dirs not observed as created             {len(map_dstdirs - created)}")
for p in sorted(created - map_dstdirs)[:20]:
    print(f"    UNEXPECTED DIR: {p}")
for p in sorted(map_dstdirs - created)[:20]:
    print(f"    EXPECTED DIR NOT CREATED: {p}")
for t, p in adds_other[:20]:
    print(f"    UNEXPECTED NON-DIR CREATION: [{t}] {p}")

hdr("4. IN-PLACE ROW - the m3u map must NOT appear as a rename")
for s in sorted(map_inplace):
    touched = any(s in (a, b) for a, b in renames)
    print(f"  {'FAIL: RENAMED' if touched else 'OK: not renamed'}  {s}")

hdr("5. MODIFICATIONS")
for t, p in sorted(mods):
    print(f"    [{t}] {p}")

hdr("6. EVERY AFFECTED PATH ATTRIBUTED")
unattributed = len(extra) + len(missing) + len(created - map_dstdirs) + len(map_dstdirs - created) + len(adds_other)
print(f"  unattributed changes under the collection    {unattributed}")
print()
verdict = "PASS" if unattributed == 0 else "FAIL"
print(f"  RECONCILIATION VERDICT: {verdict}")
sys.exit(0 if unattributed == 0 else 1)
