---
phase: 3
slug: tagger-spike
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-01
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `03-RESEARCH.md` § *Validation Architecture*.

**This phase's entire output is numbers.** Phase 1 recorded six occasions where a check reported a
pass it had not earned, every one from partial data stated as settled. The governing rule from
`stacks/selfhosted/arrs/beets.md` therefore applies to every measurement here: **verify with a
second independent instrument before writing it down.**

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell + Python assertions against live estate state. **No pytest/jest — none exists in this repo and none is warranted.** The "tests" are measurement runs |
| **Config file** | none — see Wave 0 |
| **Quick run command** | `bash scripts/check-music-freeze.sh` (read-only by contract; exits 1 on any failed assertion) |
| **Full suite command** | `bash scripts/check-music-freeze.sh && bash scripts/quick-health-check.sh` |
| **Estimated runtime** | ~30 s quick · ~90 s full |

---

## Sampling Rate

- **After every task commit:** `bash scripts/check-music-freeze.sh` — cheap, read-only, exits 1 on
  any failed assertion.
- **After every plan wave:** the freeze check **plus** `zfs diff tank/media/Music@pre-project` run
  from atlantis (`ssh root@172.16.1.158` — `zfs` cannot resolve inside LXC 100), **plus**
  `find "$SCRATCH" -newer "$STAMP"` on any tree a tool touched.
- **Before `/gsd-verify-work`:** freeze check green; scratch tree deleted and its removal confirmed;
  both spike containers removed and confirmed absent from `docker ps -a`; the three pulled images
  either retained deliberately with a stated reason or pruned; `df -h /` recorded.
- **Max feedback latency:** 30 s (quick) / 90 s (full).

---

## Per-Task Verification Map

Populated by the planner. Every task must land in one of these rows or add its own.

| Req | Behaviour to validate | Type | Automated Command | File Exists |
|-----|----------------------|------|-------------------|-------------|
| TAGR-01 | Discogs strict + loose rates recorded over the sample, with the `index_tracks` setting stated | measurement + cross-check | `jq -s` over `candidates.ndjson` **vs** hand-transcribed `beet import -t` on 3 folders | ❌ W0 (probe script) |
| TAGR-01 | Request count and timing extrapolated to the 143-folder backlog | measurement + cross-check | wall-clock `time` **vs** `grep -c 'api\.discogs\.com'` on the probe stderr | ❌ W0 |
| TAGR-01 | Zero HTTP `429` observed during the timed run | assertion | `grep -c '429' probe.stderr` → must be `0` | ❌ W0 |
| TAGR-01 | The normalisation changed **only** `album` and `artist` | regression | `scripts/snapshot-music-tags.sh` + `scripts/diff-music-tags.sh` over `$SCRATCH/normalised` | ✅ exists (01-03) |
| TAGR-02 | wrtag path format renders at v0.20.0 vs v0.33.0 vs v0.34.0, single-disc **and** multi-disc | measurement + cross-check | `wrtag move -dry-run` output **vs** the `pathformat.go` `Data`-struct source diff | ❌ W0 (throwaway compose) |
| TAGR-02 | The dry run wrote nothing | assertion | `find "$SCRATCH" -newer "$STAMP" -type f` → empty, both mounts, every arm | ❌ W0 |
| TAGR-02 | The decision names one tagger and states the DJ-content answer concretely | doc review | decision record contains a named tool + a named mechanism | n/a |
| TAGR-06 | Both front ends scored on the same 5 albums, alternating order | measurement | the scoring sheet — 10 rows, no blanks | ❌ W0 (sheet template) |
| TAGR-06 | beets-flask evaluated by name with its frictions recorded | doc review | criterion 7 table reproduced in the decision record with the trial's own observations added | n/a |
| **all** | Nothing escaped to the library | **safety gate** | `bash scripts/check-music-freeze.sh` → exit 0, `tagger-class writers: 0`, `declared rw reaching Music: 0` | ✅ exists |
| **all** | The library is byte-identical to the Phase 1 baseline | **safety gate** | ownership/mode counts still `2,543 / 87 / 2,586`; `zfs diff tank/media/Music@pre-project` clean, from atlantis | ✅ exists |

---

## The Paired-Instrument Rule, Made Concrete

Every number this spike produces gets **two independent readings before it is written down**.

| Number | Instrument A | Instrument B (independent) |
|--------|--------------|----------------------------|
| Discogs loose/strict rate | `tag_album()` probe NDJSON | `beet import -t` transcript on 3 stratified folders |
| Requests per folder | derived from source (search + `search_limit` + masters) | `grep -c 'api.discogs.com'` on the probe's own stderr |
| Wall-clock per folder | `time` around the probe | per-folder timestamps in the NDJSON |
| wrtag v0.20.0 rendering | `move -dry-run` stdout | `pathformat.go` `Data` struct + the `= -1` line at each tag |
| Normalisation field loss | `diff-music-tags.sh` | `ffprobe` spot check on 5 files |
| Nothing written to Music | `check-music-freeze.sh` | `zfs diff` from atlantis |
| Nothing written to scratch by a dry run | `find -newer` | before/after `sha256sum` on 5 files |
| Sample population size | `ls`/`find` on the live tree | the Phase 1 ffprobe fence folder set |

**If A and B disagree, neither number is recorded** until the disagreement is explained.

---

## Wave 0 Requirements

- [ ] **Docker disk headroom on LXC 100** — *blocking; nothing else can start.* Root filesystem
      measured at 99% (2.2 GB free) and it holds `/var/lib/docker`. Inventory
      (`docker images` diffed against `docker ps -a --format '{{.Image}}'`) **before** any prune —
      the estate has a documented `created`-state blind spot where a container exists but never ran
      and its image must not be reaped. Floor: ≥ 8 GB free, verified with `df -h /`.
- [ ] `scripts/` probe script (the `tag_album()` NDJSON emitter) — smoke-tested on one known-good
      album *before* it is trusted on the sample
- [ ] `scripts/normalise-dj-tags.py` with `--dry-run` as the **default**
- [ ] Formal variant survey artefact (folder → stratum), derived from the existing Phase 1 ffprobe fence
- [ ] Throwaway compose files for the beets spike and the beets-flask spike, at a scratch path —
      **not** under `stacks/selfhosted/{arrs,music}/` (D-03: the frozen stacks are not edited)
- [ ] The ergonomics scoring-sheet template, committed **before** the trial
- [ ] The three pre-committed thresholds (T1/T2/T3) written into the plan **before** evidence
      collection — criterion 5 fails otherwise

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The ergonomics trial | TAGR-06 | D-09 is explicit: *"measured by a timed hands-on trial, run by the operator personally, not predicted from documentation."* The roadmap's own overturning threshold is an honest self-assessment that the interactive prompt will not be sat at — which can only be produced by sitting at it | Operator runs the same 5 albums (D-10: 2 clean mainstream, 2 hard shapes — one various-artist compilation, one flat multi-disc set — and 1 DJ folder Discogs will not match) through both front ends in alternating order. Record wall-clock, intervention count, and each point of being stuck or annoyed |
| The week-six verdict | TAGR-06 / criterion 8 | Not measurable by any instrument. *"It works"* is not the finding; *"it works and I will still open it"* is | Operator writes the verdict in their own terms into the decision record |
| Approving the image-prune reap list | — | Mutation on a live host running 103 containers | Operator reviews the inventoried reap list before the prune executes |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90 s
- [ ] Every recorded number has both instruments named and agreeing
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
