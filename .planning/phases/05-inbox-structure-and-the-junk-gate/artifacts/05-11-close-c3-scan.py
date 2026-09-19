#!/usr/bin/env python3
"""Phase 5 closure — criterion 3 re-assertion from live state.

Walks the Now! collection as it stands, ffprobes every mp3, and reports:
  - depth-1 directory set and depth-2 directory count
  - per-volume mp3 counts and their sum
  - per-volume distinct album values
  - per-volume files == sum over discs of the MODAL tracktotal (05-05's instrument)
Read-only. Writes nothing into the collection.
"""
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict

ROOT = "/mnt/tank/downloads/complete/nzb/unsorted/VA-Now_That.s_What_I_Call_Music__1-115_2023"
OUT = "/mnt/fast/safety/phase05/close-c3-scan.json"


def probe(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", path],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        return None
    try:
        tags = json.loads(r.stdout).get("format", {}).get("tags", {})
    except Exception:
        return None
    return {k.lower(): v for k, v in tags.items()}


def num(s):
    if s is None:
        return None
    m = re.match(r"\s*(\d+)", str(s))
    return int(m.group(1)) if m else None


def main():
    d1 = sorted(e.name for e in os.scandir(ROOT) if e.is_dir(follow_symlinks=False))
    d2 = []
    for d in d1:
        for e in os.scandir(os.path.join(ROOT, d)):
            if e.is_dir(follow_symlinks=False):
                d2.append(os.path.join(d, e.name))

    root_files = [e.name for e in os.scandir(ROOT) if e.is_file(follow_symlinks=False)]
    root_mp3 = [f for f in root_files if f.lower().endswith(".mp3")]

    per_vol_files = {}
    per_vol_albums = defaultdict(Counter)
    per_vol_disc_tt = defaultdict(lambda: defaultdict(Counter))
    per_vol_disc_files = defaultdict(Counter)
    failed = []
    total = 0

    for d in d1:
        p = os.path.join(ROOT, d)
        mp3 = sorted(f for f in os.listdir(p) if f.lower().endswith(".mp3"))
        per_vol_files[d] = len(mp3)
        total += len(mp3)
        for f in mp3:
            t = probe(os.path.join(p, f))
            if t is None:
                failed.append(os.path.join(d, f))
                continue
            per_vol_albums[d][t.get("album", "")] += 1
            disc = num(t.get("disc")) or 1
            per_vol_disc_files[d][disc] += 1
            tt = num(t.get("track_total") or t.get("tracktotal") or t.get("totaltracks"))
            if tt is None:
                trk = t.get("track", "")
                if "/" in str(trk):
                    tt = num(str(trk).split("/", 1)[1])
            if tt is not None:
                per_vol_disc_tt[d][disc][tt] += 1

    exceptions = {}
    for d in d1:
        expect = 0
        for disc, cnt in per_vol_disc_tt[d].items():
            expect += cnt.most_common(1)[0][0]
        present = per_vol_files[d]
        if expect != present:
            exceptions[d] = {
                "files": present,
                "expected": expect,
                "delta": present - expect,
                "per_disc_files": dict(per_vol_disc_files[d]),
                "per_disc_modal_tt": {k: v.most_common(1)[0][0] for k, v in per_vol_disc_tt[d].items()},
            }

    multi_album = {d: dict(c) for d, c in per_vol_albums.items() if len(c) != 1}

    expected_names = [f"Vol {i:03d}" for i in range(1, 116)]
    result = {
        "root": ROOT,
        "depth1_dirs": len(d1),
        "depth1_names_match_Vol001_115": d1 == expected_names,
        "depth1_unexpected": [x for x in d1 if x not in expected_names],
        "depth1_missing": [x for x in expected_names if x not in d1],
        "depth2_dirs": len(d2),
        "depth2_list": d2[:20],
        "root_level_files": sorted(root_files),
        "root_level_mp3": len(root_mp3),
        "mp3_total_in_volumes": total,
        "ffprobe_failed": failed,
        "volumes_with_not_exactly_one_album": multi_album,
        "distinct_album_values_overall": len({a for c in per_vol_albums.values() for a in c}),
        "tracktotal_exceptions": exceptions,
        "tracktotal_exception_count": len(exceptions),
        "per_vol_files": per_vol_files,
        "per_vol_album": {d: list(c.keys())[0] if len(c) == 1 else None for d, c in per_vol_albums.items()},
    }
    with open(OUT, "w") as fh:
        json.dump(result, fh, indent=1)
    print("WROTE", OUT)
    print("depth1", result["depth1_dirs"], "namesok", result["depth1_names_match_Vol001_115"],
          "depth2", result["depth2_dirs"], "mp3", total, "rootmp3", len(root_mp3),
          "failed", len(failed), "multialbum", len(multi_album), "ttexc", len(exceptions))


if __name__ == "__main__":
    main()
