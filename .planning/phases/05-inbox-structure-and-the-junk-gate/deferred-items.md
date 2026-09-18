# Phase 5 — deferred items

Out-of-scope discoveries logged rather than fixed, per the executor scope boundary: only issues
DIRECTLY caused by this phase's own changes are auto-fixed.

---

## 1. `check-music-freeze.sh` §2 interpolated-host-path inventory has MOVED (found 2026-09-18, plan 05-02)

**What:** Every run of `scripts/quick-health-check.sh` is currently RED before Phase 5 touches
anything. The music freeze harness fails with:

```
❌ interpolated-host-path inventory MOVED: expected=12, found=13. These lines are invisible to
   §2's driving grep and cannot be resolved statically, so §2 is UNKNOWN until each new one is
   read by hand and DECLARED_INTERP_EXPECTED is moved in the same commit
```

**Not caused by plan 05-02, and that was checked rather than assumed.** The assertion counts
*compose volume lines* that interpolate a variable into the HOST side of a bind, and it runs from
the host-side copy of the repo at `/mnt/fast/stacks` (measured at `b27255b`, where
`grep -c MUSIC_UNDERSCORE_ROOT scripts/quick-health-check.sh` returns **0**). Plan 05-02's edits are
workstation-local and in a different file entirely, so they are not reachable by that count.

**Why it is not fixed here:** `check-music-freeze.sh:492` pins `DECLARED_INTERP_EXPECTED=12` and its
own failure text states the remedy — *each new line must be READ BY HAND and the constant moved in
the same commit*. That is a deliberate human-review gate on a compose change this phase did not
make; satisfying it by bumping the number is exactly the "edit the assertion to make it pass" move
this estate has repeatedly recorded as the defect rather than the fix.

**Consequence for this phase, stated so a verifier is not misled:** `bash scripts/quick-health-check.sh`
exits **1** today for a reason unrelated to Phase 5. A whole-script exit code is therefore
**non-discriminating** for Phase 5's criterion-4 assertion — the block's own verdict line must be
read. Plan 05-02's negative control was driven on the block's line and on the diff of the run's
red/amber line set, not on the script's exit code alone.

**Who should fix it:** whoever added the thirteenth interpolated volume line, by reading it and
moving `DECLARED_INTERP_EXPECTED` in the same commit.
