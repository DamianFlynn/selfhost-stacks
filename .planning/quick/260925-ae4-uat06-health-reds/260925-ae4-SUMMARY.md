---
phase: quick/260925-ae4-uat06-health-reds
plan: 01
subsystem: health-checks
tags: [health-check, conventions-5, pinned-count, deploy, beets, lxc100]
requires:
  - scripts/check-music-freeze.sh
  - scripts/quick-health-check.sh
provides:
  - "DECLARED_INTERP_EXPECTED pinned at 13 with the thirteenth line declared in band"
  - "the deployed beets config carrying plan 06-07's retraction"
affects:
  - scripts/check-music-freeze.sh
  - /mnt/fast/appdata/arrs/beets/config/config.yaml (LXC 100)
  - /mnt/fast/stacks/scripts/check-music-freeze.sh (LXC 100)
tech-stack:
  added: []
  patterns:
    - "single-file scp deploy in place of a git pull, to avoid touching a diverged host checkout"
key-files:
  created:
    - .planning/quick/260925-ae4-uat06-health-reds/artifacts/qhc-after.txt
    - .planning/quick/260925-ae4-uat06-health-reds/artifacts/config.yaml.deployed-pre
  modified:
    - scripts/check-music-freeze.sh
decisions:
  - "Deployed the freeze script by scp of the single file rather than git pull, because /mnt/fast/stacks holds an unpushed commit 745611e and is diverged; resolving that divergence is the operator's call, not this task's"
  - "Did not restart beets-flask: the config change is comments-only and the mount is :ro, so a restart would be an unjustified side effect"
metrics:
  duration: ~25 min
  completed: 2026-09-25
---

# Quick 260925-ae4: Close the two UAT06 health-check reds — Summary

Moved `check-music-freeze.sh`'s interpolated-host-path pin from 12 to 13 with the thirteenth line
declared in band, deployed both the edited script and the stale beets config to LXC 100, and
asserted the two previously-red blocks green with present/absent token pairs.

## What Changed

### Task 1 — the pin and its in-band declaration (commit `0228f4f`)

One commit, both edits, per CONVENTIONS.md convention 5.

- `DECLARED_INTERP_EXPECTED="${DECLARED_INTERP_EXPECTED:-12}"` → `:-13`. The `${VAR:-default}` form
  is unchanged and the environment override was **not** used anywhere — convention 4 names it the
  repository's one policy-governed exception, and the script's own remediation arm says its sole
  sanctioned use is making the check redder.
- The existing `WHY (3) IS A PINNED INVENTORY` header was **extended in its own voice**, not
  annotated beside. `Twelve such lines exist right now` → `Thirteen`, spelled as a word to match the
  surrounding prose. A new `THE THIRTEENTH LINE, DECLARED` paragraph names the line
  (`${APPDATA_DIR}/monitoring/node-exporter-textfile:/var/lib/node_exporter/textfile_collector:ro`),
  its file (`stacks/selfhosted/monitoring/node-exporter.yaml`), the commit that added it (`2f19870`,
  2026-09-18) and three independent reasons it is safe: it is `:ro`; its host side is under
  `${APPDATA_DIR}`, not the `${MEDIA}` that plausibly expands to `/mnt/tank/media`; and it does not
  reach `/mnt/tank/media/Music`.
- Per convention 12 the paragraph records **what would falsify the declaration** rather than the
  UAT's round history — and in doing so states a limit the plan did not ask for but which the code
  bears out: *the pin gates on the SIZE of the inventory, not the CONTENT of any line in it.*
  Repointing `${APPDATA_DIR}` beneath the library, or dropping the `:ro`, leaves the count at
  thirteen and this section green while the declaration has quietly become false. Mutation of an
  existing interpolated line is a blind spot the inventory does not cover and now does not claim to.
- One clause states plainly that `2f19870` did not move the pin in its own commit, so this is the
  **remediation**, not the same-commit move convention 5 asks for. A reader who greps `2f19870`
  lands on that account rather than on a convention presented as honoured.

No stack file was touched. `bash -n` passes.

### Task 2 — refresh the deployed beets config (no commit; deploy action)

Nothing in the repository changed. On LXC 100, `/mnt/fast/appdata/arrs/beets/config/config.yaml`
was overwritten from the host checkout's own copy, host-side, through the existing inode.

Pre-change bytes preserved on the workstation at
`artifacts/config.yaml.deployed-pre` (472 lines) and asserted to hash `96a7c622…e3e1f7` before
anything was overwritten.

### Task 3 — deploy the freeze script and assert the acceptance run (no commit; deploy + verify)

`scp` of the single file to `/mnt/fast/stacks/scripts/check-music-freeze.sh`. **No `git pull`,
`rebase`, `merge`, `reset`, `checkout -f` or `clean` was issued on the host checkout at any point**,
and `745611e` was re-confirmed as host `HEAD` after the copy.

## Verification — asserted, not eyeballed

Every remote command was bounded Linux-side with `timeout` (convention 2), every remote pipeline
carried `set -o pipefail`, and every ssh return code was read. All greps in recorded measurements
used `/usr/bin/grep` by absolute path (convention 9).

| Assertion | Result |
|---|---|
| Workstation pin == 13 and tree count == 13 | `PIN=13 CNT=13` → `PIN-DECLARATION-OK` |
| LXC 100 tree count == 13, same distribution | `HOST_INTERP_COUNT=[13]` |
| Deployed config sha256 / owner / mode | `661c7297…4668f`, `apps:apps 660` → `DEPLOYED-CONFIG-OK` |
| `cp` wrote through the existing inode | `INODE_BEFORE=81295 INODE_AFTER=81295` |
| Source bytes == what the drift block reads | worktree sha == `git show HEAD:…` sha |
| Config change is comments-only | zero non-comment, non-blank differences pre vs post |
| Host freeze script sha256 == workstation | both `01b77f25c4745c6f0a2b5fc74e5af2c75bd5b264c338beb20d36219ec35a90a9` |
| Host freeze script owner / mode | `root:apps 755` (unmoved by `scp`; no restore needed) |
| Host copy pin and syntax | `HOST_PIN=[13]`, `bash -n` clean |
| `745611e` still host `HEAD` after the copy | confirmed |

### Acceptance run

`bash scripts/quick-health-check.sh` captured to `artifacts/qhc-after.txt` (6,983 bytes, 95 lines).
Non-emptiness asserted first — an empty capture is COULD NOT LOOK, a distinct verdict from
"nothing is wrong" (convention 1). The plan's verbatim assertion returned `ACCEPTANCE-OK`.

| Block | Present token | Absent token | Verdict |
|---|---|---|---|
| Vendored-file drift | `vendored files match (4)` ✓ | `survivor-config.yaml DRIFTED` = 0 | **green** |
| Music freeze harness | `Music freeze harness: ✅ Intact` ✓ | `interpolated-host-path inventory MOVED` = 0 | **green** |
| Music consumers audit | `CONF-04 MEASURED AND OPEN` ✓ | — (by design) | **pending, untouched** |

The positive half of each pair is the anti-vacuous guard: a zero count of a failure string is
indistinguishable from a block that never ran. A sweep for `UNKNOWN` across the capture returned
**0** — no block reported could-not-look.

### Overall exit code: 1 — and that is correct

The run exits **1**. Enumerating every non-green marker in the capture, the only block-level one is
the consumers audit's `⚠️ CONF-04 MEASURED AND OPEN … (exit 3)`. Every other `⚠️`/`FAIL` hit is
either a `FAILURES total: 0` line or the closing banner's own explanatory text. **CONF-04 pending is
the sole remaining holder of the non-zero exit**, exactly as the consumers fold-in's `exit 3` arm
intends; its own comment calls this the load-bearing half and forbids an override. The overall code
is not a CONF-04 signal and was not chased to zero.

## Deviations from Plan

**1. [Rule 1 — measurement artefact caught before it became evidence]** My first attempt to measure
the host tree's interpolated-line count through a nested double-quoted ssh string returned
`HOST_INTERP=0` — the pattern was mangled by shell quoting, not a real zero. Reported as COULD NOT
LOOK and re-measured by feeding the script over ssh stdin (`timeout 60 bash -s`), which returned
`[13]` with the same per-file distribution as the workstation. Had the 0 been taken at face value it
would have contradicted the plan's load-bearing "13 on both trees" claim on the strength of a broken
instrument. No file was written between the bad read and the good one.

**2. [Rule 2 — convention 8 sub-rule 3 applied where the plan asked for a confirmation]** Task 1
required confirming no published recipe counts tokens inside `check-music-freeze.sh`. The recipe used
was
`/usr/bin/grep -rnE '(grep[[:space:]]+-[a-zA-Z]*c[a-zA-Z]*|wc[[:space:]]+-l).*check-music-freeze\.sh'`
over `*.sh` and `*.md`, excluding `.planning/` and the stale `.claude/worktrees/` tree. It returned
no matches — and was then **driven against a control file containing the real token**, where it
returned a match. The zero is therefore a real negative, not a vacuous one. `quick-health-check.sh`
greps this script's **output** (`:2426` runs it over ssh and parses the result), never its bytes;
confirmed rather than assumed.

## Disclosed cost: the host checkout now carries one modified file

`/mnt/fast/stacks` reports `HOST_DIRTY_FILES=[1]`: ` M scripts/check-music-freeze.sh`. This is the
accepted, disclosed consequence of deploying by `scp` instead of `git pull`, and it is transient and
self-healing — once commit `0228f4f` reaches `origin/main` and the divergence is resolved, the
working file already matches the committed bytes and git reads clean. It was **not** "cleaned up",
because every mechanism for doing so risks the unpushed commit below.

## Operator action deliberately NOT taken: the host checkout is diverged

| | commit |
|---|---|
| workstation `HEAD` (after this task) | `0228f4f` |
| `origin/main` | `099bd5f` |
| LXC 100 `/mnt/fast/stacks` `HEAD` | `745611e` |
| common ancestor | `c406259` |

`745611e` is **"feat(neocortex-memory): a private tailnet route via tsbridge (TODO-317)"** — authored
2026-09-24 23:23, 25 insertions to `stacks/selfhosted/neocortex-memory/compose.yaml`. It exists
**only on the host and is unpushed**; `git cat-file -t 745611e` fails in the workstation repo. The
host is therefore 1 ahead and 1 behind, and `git pull --ff-only` cannot succeed.

**This is the operator's only copy of that work.** Resolving the divergence — pushing `745611e`, or
rebasing/merging it — is out of this task's scope and was deliberately not attempted. It is
surfaced here rather than silently fixed.

## Hard exclusions — verified

- `CONF-04` not ticked anywhere; `.planning/REQUIREMENTS.md` asserted untouched against the
  pre-task base.
- `.planning/ROADMAP.md` asserted untouched.
- `scripts/check-music-consumers.sh` asserted untouched.
- `zfs list -t snapshot` confirms `tank/media/Music@pre-06-41-conf04-reprobe` still exists —
  neither released nor destroyed.
- `DECLARED_INTERP_EXPECTED` was never exported or set; confirmed unset in the executing shell.
- `beets-flask` was not restarted or recreated.
- No Phase 6 plans created. No package-manager install performed.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change at a trust boundary
was introduced. The two file writes on LXC 100 were asserted for hash, owner and mode after the
fact (T-ae4-01, T-ae4-02, T-ae4-03), and T-ae4-06 was honoured by refusal — no git history on the
host was touched.

## Self-Check: PASSED

All four claimed files exist on disk; commit `0228f4f` exists in `git log --all` and its stat shows
exactly one file changed (`scripts/check-music-freeze.sh`, +21/-2), confirming the atomic
single-file claim.

## Note on the summary path

The plan's `<output>` block asks for `SUMMARY.md`; the orchestrator specified
`260925-ae4-SUMMARY.md`. The orchestrator's path is used. Flagged so the difference is visible
rather than silently resolved.
