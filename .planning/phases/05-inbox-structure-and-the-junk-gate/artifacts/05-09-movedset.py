#!/usr/bin/env python3
"""movedset.py PRE.tsv POST.tsv OUT.txt - the set of paths whose mtime or size moved between two
`find -printf '%p\t%T@\t%s\n'` fingerprints. Prints counts and writes the moved paths, one per
line, so a later assertion can compare a SET rather than a number."""
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


pre, post = load(sys.argv[1]), load(sys.argv[2])
moved = sorted(p for p in pre if p in post and post[p] != pre[p])
size_moved = [p for p in moved if post[p][1] != pre[p][1]]
vanished, appeared = sorted(set(pre) - set(post)), sorted(set(post) - set(pre))
with open(sys.argv[3], "w", encoding="utf-8", errors="surrogateescape") as fh:
    for p in moved:
        fh.write(p + "\n")
print(f"pre_rows={len(pre)} post_rows={len(post)}")
print(f"moved={len(moved)} size_also_changed={len(size_moved)}")
print(f"vanished={len(vanished)} appeared={len(appeared)}")
sys.exit(1 if (vanished or appeared) else 0)
