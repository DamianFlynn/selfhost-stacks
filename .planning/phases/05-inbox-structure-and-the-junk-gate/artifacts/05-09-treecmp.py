#!/usr/bin/env python3
"""treecmp.py PRE.tsv POST.tsv NDJSON [NDJSON...] - which files moved, and were they the ones told to.

Reads two `find -printf '%p\t%T@\t%s\n'` fingerprints and the apply NDJSON(s). Asserts that the
set of paths whose mtime OR size changed is EXACTLY the set of paths the NDJSON recorded as
written=true. Exits 1 on any mismatch, 0 only when every category is empty.
Tab-split is done with split('\t') on a rpartition-safe basis: paths may contain spaces, so the
fields are taken from the RIGHT (size, mtime) and everything left of them is the path.
"""
import json
import sys


def load(path):
    out = {}
    with open(path, encoding="utf-8", errors="surrogateescape") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line:
                continue
            head, _, size = line.rpartition("\t")
            p, _, mtime = head.rpartition("\t")
            out[p] = (mtime, size)
    return out


pre = load(sys.argv[1])
post = load(sys.argv[2])

written, recorded = set(), set()
for nd in sys.argv[3:]:
    with open(nd, encoding="utf-8") as fh:
        for line in fh:
            if not line.strip():
                continue
            r = json.loads(line)
            recorded.add(r["path"])
            if r.get("written") is True:
                written.add(r["path"])

moved = {p for p in pre if p in post and post[p] != pre[p]}
size_moved = {p for p in moved if post[p][1] != pre[p][1]}
vanished = set(pre) - set(post)
appeared = set(post) - set(pre)

unexpected = moved - written
unmoved = written - moved
noop_moved = (recorded - written) & moved

print(f"pre_rows                        : {len(pre)}")
print(f"post_rows                       : {len(post)}")
print(f"ndjson_records                  : {len(recorded)}")
print(f"ndjson_written_true             : {len(written)}")
print(f"paths whose mtime/size moved    : {len(moved)}")
print(f"  of which size also changed    : {len(size_moved)}")
print(f"MOVED BUT NOT WRITTEN (must be 0): {len(unexpected)}")
for p in sorted(unexpected)[:10]:
    print(f"    ! {p}")
print(f"WRITTEN BUT NOT MOVED (must be 0): {len(unmoved)}")
for p in sorted(unmoved)[:10]:
    print(f"    ! {p}")
print(f"NOOP FILES THAT MOVED (must be 0): {len(noop_moved)}")
for p in sorted(noop_moved)[:10]:
    print(f"    ! {p}")
print(f"VANISHED (must be 0)            : {len(vanished)}")
print(f"APPEARED (must be 0)            : {len(appeared)}")

fail = bool(unexpected or unmoved or noop_moved or vanished or appeared)
print("VERDICT: " + ("FAIL" if fail else "PASS"))
sys.exit(1 if fail else 0)
