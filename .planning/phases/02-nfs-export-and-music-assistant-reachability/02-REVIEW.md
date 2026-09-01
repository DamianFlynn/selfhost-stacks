---
phase: 02-nfs-export-and-music-assistant-reachability
reviewed: 2026-09-01T16:29:30Z
depth: standard
diff_base: aa2b502
files_reviewed: 10
files_reviewed_list:
  - scripts/check-music-consumers.sh
  - scripts/quick-health-check.sh
  - scripts/disable-jellyfin-hwaccel.sh
  - infra/nfs-music-export.tf
  - infra/variables.tf
  - infra/outputs.tf
  - infra/lxc-selfhost.tf
  - infra/lxc-mpe.tf
  - NETWORK.md
  - stacks/selfhosted/arrs/beets.md
findings:
  critical: 4
  warning: 13
  info: 8
  total: 25
status: issues_found
remediation:
  applied: 2026-09-01
  fixed: 22
  partial: 1
  skipped: 2
  outcomes:
    CR-01: fixed
    CR-02: fixed
    CR-03: fixed
    CR-04: skipped        # operator-accepted; needs credential rotation, not a code change
    WR-01: fixed
    WR-02: fixed
    WR-03: fixed
    WR-04: fixed
    WR-05: fixed
    WR-06: fixed
    WR-07: fixed
    WR-08: fixed
    WR-09: fixed
    WR-10: fixed
    WR-11: partial        # exposure recorded as accepted risk; token mint NOT done
    WR-12: fixed
    WR-13: fixed
    IN-01: fixed
    IN-02: fixed
    IN-03: fixed
    IN-04: fixed
    IN-05: fixed
    IN-06: fixed
    IN-07: fixed
    IN-08: skipped        # needs the Jellyfin EncodingOptions element order; judgement call
---

# Phase 02: Code Review Report

**Reviewed:** 2026-09-01T16:29:30Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

The two things this phase was most at risk of getting wrong, it got right. The exit-code capture
in both folded-in blocks of `quick-health-check.sh` is correct (`RC=$?` immediately after the
assignment, no pipe in between); empty output is `UNKNOWN` + `EXIT_CODE=1` in both; the ANSI strip
uses `$'\033...'` rather than the GNU-only `\x1b`; `ssh -n` is applied to inline commands and
never to a `bash -s` heredoc; the Spotify provider filter is applied server-side *and* re-checked
client-side against `provider_mappings[]`; `exportfs -v` continuations are joined before parsing
in both the shell parser and the Terraform reconciler; Jellyfin is resolved at runtime via
`docker inspect` and never as a literal or a bare name. Those are the traps that were named, and
they were cleared.

The defects are in the parts nobody was watching, and they are the same shape as the six the phase
already caught — a check that is green because it could not observe, not because the thing is
healthy.

Four Critical findings:

1. `check-music-consumers.sh` places the Music Assistant account password, the MA JWT and the
   Jellyfin API key into **process arguments**, directly contradicting the claim written into the
   file three lines above the code that does it. On a public-repo estate with one prior credential
   exposure still open, a control that is asserted but not implemented is worse than no claim.
2. `disable-jellyfin-hwaccel.sh`'s `report_drm()` prints `✓ no processes hold amdgpu DRM handles`
   when the SSH probe fails, times out, or debugfs is unreadable — a green verdict from an
   unobservable state, in the post-mutation verification of the script whose reason for existing
   is a six-hour outage caused by exactly the thing it claims to have verified is absent.
3. The Terraform temp-export reconciler added in 02-07 has **no dependency edge on the resource it
   reconciles against**. Its enabled-branch assertion (`exactly 2 /mnt/tank exports`) and its
   `exportfs -ra` run in parallel with the resource that creates the second export. Enabling the
   control export is a coin flip between a hard apply failure and an assertion that passed for
   reasons unrelated to what it asserts.
4. The UCG-Max root password was redacted from `NETWORK.md` inside this diff range, but the value
   remains recoverable from this **public** repository's history. The rotation the redaction commit
   scheduled for 2026-08-28 is, per project memory, still outstanding.

The Terraform apply gates are also weaker than they read: three of them (`grep -q '<nuc-ip>'`,
`grep -q 'no_root_squash'`, `grep -cE '^/mnt/tank'`) assert over the **whole host export table**
rather than the drop-ins Terraform owns — so they can pass off the wrong line, and any unrelated
export on atlantis breaks every future apply.

Two documentation notes, both good: no credential appears in `NETWORK.md`, `beets.md`,
`TAILSCALE.md` or `CLAUDE.md` (verified by pattern scan), and the export line published in the docs
matches byte-for-byte what `infra/nfs-music-export.tf` generates plus knfsd's defaults.

---

## Remediation summary (added 2026-09-01)

Every finding below carries an **Outcome** line recording what was done. 22 fixed, 1 partial,
2 skipped. Nothing was weakened to make it pass; no assertion was made quieter. The commits are
`5d94d4e`, `26c3908`, `f0fc92a`, `a29fa95`, `fedbbdc`, `c18474e` — one per cluster, each scoped to
one file.

**Verified after the fixes, not assumed:**

- `bash scripts/quick-health-check.sh` exits **0** with both music blocks green and output
  identical to the pre-fix baseline.
- `terraform plan -detailed-exitcode` returns **0**. The saved plan holds 13 no-ops, **zero
  destroys**, and `proxmox_virtual_environment_container.selfhost` unchanged. **No apply was run** —
  CR-03 concerns the enable transition, which is disabled and torn down, so the graph edge was
  fixed and verified by plan alone.
- Every behavioural fix was **positive-controlled**: each new or changed detector was shown to FIRE
  on the state it is meant to catch, and the pre-fix code was run against the same input to
  confirm it did not. A detector that has only ever been seen to pass is the defect this phase
  exists to catch, and adding more of those would have been the wrong kind of fix.

**Still outstanding after this pass — these are NOT closed:**

1. **CR-04** — the UCG-Max root password rotation. Operator-accepted; only rotation fixes it.
2. **WR-11** — minting the revocable MA audit token. The exposure is now recorded as an accepted
   risk with its fix written down, but the account password is still what the audit replays.
3. **IN-08** — element ordering in `set_hwaccel`'s XML writer. Latent, and deliberately untouched.

---

## Critical Issues

### CR-01: MA password, MA JWT and Jellyfin API key are passed in process arguments — contradicting the file's own claim

**File:** `scripts/check-music-consumers.sh:296-302`, `:311-313`, `:334-340`

**Issue:** Line 296 states, as a comment immediately above the code:

> `# The password reaches curl through a jq-built body on stdin-equivalent (-d @-), never argv.`

That is true of `curl` and false of the process that actually receives the secret. Line 297 is:

```bash
body="$(jq -nc --arg u "$MA_USERNAME" --arg p "$MA_PASSWORD" \
        '{command:"auth/login",args:{username:$u,password:$p}}')"
```

`jq` is invoked with the plaintext MA account password as `argv[4]`. The same pattern repeats for
the two bearer credentials, which are placed in `curl`'s argv:

- `:313` — `-H "Authorization: Bearer ${MA_TOKEN}"` (a 90-day JWT)
- `:338` — `-H "Authorization: MediaBrowser Token=\"${JELLYFIN_API_KEY}\""`

`/proc/<pid>/cmdline` is world-readable by default on Linux; `hidepid` is not set on LXC 100.
Anything that samples the process table on that host — a monitoring agent, `ps aux` in a shell
history, an `atop`/`pidstat` sample, an audit log — captures all three. The file header at
:122-126 asserts the opposite posture ("were written there via stdin so neither value ever entered
the process list on a host running 100+ containers"), so a future reader will not go looking.

This becomes continuous rather than occasional now that 02-09 folded the script into
`quick-health-check.sh`: the password is re-exposed on every health check, forever.

**Failure scenario:** Any process or operator able to read the process table on LXC 100 recovers
(a) an MA account password, which per `beets.md` can mint further long-lived tokens via
`auth/token/create`, and (b) a Jellyfin API key with library-wide access. Neither is detectable
after the fact.

**Fix:** Keep all three out of argv. `jq` reads the environment directly:

```bash
ma_login() {
  local body resp
  body="$(MA_USERNAME="$MA_USERNAME" MA_PASSWORD="$MA_PASSWORD" jq -nc \
          '{command:"auth/login",args:{username:$ENV.MA_USERNAME,password:$ENV.MA_PASSWORD}}')"
  ...
}
```

For `curl`, use a config file on a pipe so the header never reaches argv:

```bash
ma_api() {
  local cmd="$1" args="${2:-}" body
  [[ -z "$args" ]] && args='{}'
  body="$(jq -nc --arg c "$cmd" --argjson a "$args" '{command:$c,args:$a}')"
  printf '%s' "$body" | curl -s --max-time 30 -X POST "${MA_URL}/api" \
    -H 'Content-Type: application/json' \
    -H @<(printf 'Authorization: Bearer %s\n' "$MA_TOKEN") --data-binary @- || true
}
```

(or `curl -K -` with the header written on stdin alongside `--data @file`). Then correct the
comments at :122-126 and :296 so they describe what the code does.

**Outcome: fixed** (`5d94d4e`)

Both mechanisms applied as suggested. `jq` reads `$ENV.MA_USERNAME` / `$ENV.MA_PASSWORD` placed in
its environment by a `VAR=... jq` command prefix; `curl` reads both Authorization headers via
`-H @<(printf ...)` (curl on LXC 100 is 8.14.1; `@file` is >= 7.55.0). `-K -` was not used because
the request body already owns stdin. The false claim at `:122-126` and the one above `ma_login`
are replaced with a description of the mechanism at each of the three sites.

**Proven, not asserted.** `jq` and `curl` were shimmed to record their own `/proc/$$/cmdline`, and
the pre-fix script at HEAD was run through the identical shims as a positive control:

| | invocations captured | argv carrying a secret or auth header |
|---|---|---|
| pre-fix (control) | 44 | **7** — MA username + password in jq's argv, `Authorization: Bearer <jwt>`, `MediaBrowser Token="<key>"` |
| fixed | 44 | **0**, with 6 × `-H @/dev/fd/63` |

Note for anyone repeating this: the obvious sampler (polling `/proc/*/cmdline` in a loop) is not
good enough — jq lives ~10 ms and a 7 Hz sampler misses it. The first attempt at this test returned
"0 leaks" for the *pre-fix* script too, which would have been a false all-clear.

WR-13's `set -a` removal landed in the same commit and is part of this fix: without it the values
were in `/proc/<pid>/environ` for every child regardless of argv.

---

### CR-02: `report_drm()` reports a clean GPU when it could not look

**File:** `scripts/disable-jellyfin-hwaccel.sh:152-168`, used at `:210` and `:246`

**Issue:**

```bash
drm_clients() {
  timeout 20 ssh -o ConnectTimeout=8 -o BatchMode=yes "root@${PROXMOX_HOST}" '
    for f in /sys/kernel/debug/dri/*/clients; do
      [ -r "$f" ] && cat "$f"
    done 2>/dev/null | awk "..." | sort -u
  ' 2>/dev/null
}

report_drm() {
  local clients; clients=$(drm_clients)
  if [ -z "$clients" ]; then
    ok "no processes hold amdgpu DRM handles"
```

Empty output is treated as proof of absence. Every one of these produces empty output:

- SSH to atlantis refused, timed out (`timeout 20`), or key not accepted (`BatchMode=yes`)
- `debugfs` not mounted on atlantis, so the glob matches nothing
- `/sys/kernel/debug/dri/*/clients` unreadable, swallowed by the inner `2>/dev/null`
- the outer `2>/dev/null` discarding whatever ssh had to say about any of the above

The exit status of `drm_clients` is discarded entirely — `clients=$(drm_clients)` is never tested.

This is the exact silent-pass class the phase spent nine plans cataloguing, and it sits in the
worst possible place: `do_disable()` calls `report_drm` at :246 as its **post-change
verification**, after the config edit and the container restart. An operator remediating the
amdgpu wedge reads `✓ no processes hold amdgpu DRM handles` and concludes the orphaned ffmpeg is
gone, when in fact atlantis simply did not answer — which is the *more likely* state, because a
wedged host is why they are running the script.

**Failure scenario:** atlantis is degraded (the condition this script exists for), ssh is slow and
hits the 20 s timeout, the operator sees a clean DRM table, declares the incident closed, and the
orphaned ffmpeg keeps holding its two DRM handles and 232 MB of VRAM into the next oops.

**Fix:** Distinguish "nothing held" from "could not look". Return the probe's status and make an
unknown state loud:

```bash
drm_clients() {
  timeout 20 ssh -o ConnectTimeout=8 -o BatchMode=yes "root@${PROXMOX_HOST}" '
    ls /sys/kernel/debug/dri/*/clients >/dev/null 2>&1 || { echo "PROBE-UNAVAILABLE"; exit 3; }
    cat /sys/kernel/debug/dri/*/clients 2>/dev/null \
      | awk "NR>1 && \$1 != \"command\" {print \$1, \$2}" | sort -u
  '
}

report_drm() {
  local clients rc
  clients=$(drm_clients); rc=$?
  if [ $rc -ne 0 ]; then
    bad "UNKNOWN — could not read the DRM client table on ${PROXMOX_HOST} (probe rc=$rc)."
    bad "This is NOT 'no handles held'. Check the host by hand before trusting this run."
    return 1
  fi
  if [ -z "$clients" ]; then ok "no processes hold amdgpu DRM handles"; else ... ; fi
}
```

and have `do_disable`'s verification block at :244-249 propagate that non-zero into its own
return value.

**Outcome: fixed** (`a29fa95`)

Applied as suggested. `drm_clients` exits 3 on an unreadable table, no longer swallows ssh's own
stderr, and returns its status; `report_drm` returns non-zero on UNKNOWN and spells out what each
rc means (3 = debugfs unreadable, 124 = timed out, 255 = ssh failed, "and an unreachable atlantis
is itself a symptom"). `do_disable` propagates it — VAAPI-off with an unreadable DRM table now
exits 1 and says explicitly not to close an incident on that run.

Verified on LXC 100 in both directions:

- against the real atlantis: `✓ no processes hold amdgpu DRM handles (table read successfully and
  was empty)` — the parenthetical is the point, it is now a statement about a read that happened.
- against an unreachable probe host: `✗ UNKNOWN — could not read the DRM client table … (probe
  rc=255)`, with ssh's `Connection timed out` now visible. The pre-fix code printed a green tick
  for this exact input.

`do_check` still exits 0 on findings — that is its documented contract (`:86-89`), and only the
mutating action's return value was in scope.

---

### CR-03: the temp-export reconciler races the resource it reconciles against

**File:** `infra/nfs-music-export.tf:332-374` (and `:235-286`)

**Issue:** `null_resource.nfs_music_temp_export_teardown` declares only:

```hcl
depends_on = [null_resource.nfs_music_export]
```

`null_resource.nfs_music_temp_export` declares the same. Neither depends on the other, so Terraform
places them as **siblings in the graph and walks them in parallel** (default `-parallelism=10`).

On the enable transition (`music_temp_export_enabled` false → true) both change in the same apply:
`nfs_music_temp_export[0]` is created, and the teardown resource's trigger flips `"false"` →
`"true"`, replacing it. Its enabled branch then runs (`:363-364`):

```hcl
"n=$(exportfs -v | grep -cE '^/mnt/tank'); test \"$n\" -eq 2 || { echo \"FATAL: expected 2 ...\"; exit 1; }"
```

If the reconciler wins the race, the drop-in `/etc/exports.d/music-temp.exports` has not been
written yet, `n` is `1`, and the apply hard-fails with a FATAL that describes a condition that was
never true. If it loses the race, the assertion passes — but for a reason unconnected to the
assertion, because nothing sequenced it. Both resources also run `exportfs -ra` (`:277` and `:356`)
concurrently against the same kernel export table.

The file's own header (`:288-331`) argues at length that the reconciler must exist so that
"teardown is still an apply, still visible in a plan diff, and still provable". The enable half is
none of those things while the ordering is undefined.

**Failure scenario:** Phase 7 (or a re-run of the 02-07 fallback control) sets
`music_temp_export_enabled = true` and applies. Roughly half the time the apply aborts with
`FATAL: expected 2 /mnt/tank exports while the control is enabled, found 1`, leaving
`nfs_music_temp_export[0]` created-or-not depending on interleaving, and the operator debugging a
Terraform resource rather than the control they were trying to run.

**Fix:** Add the missing edge. `depends_on` on a `count`ed resource is valid when the count is 0:

```hcl
resource "null_resource" "nfs_music_temp_export_teardown" {
  depends_on = [
    null_resource.nfs_music_export,
    null_resource.nfs_music_temp_export,
  ]
  ...
}
```

This is correct in both directions: on enable the reconciler runs after the export exists; on
teardown `nfs_music_temp_export[0]` is destroyed (a state-only no-op) before the reconciler runs,
which is the ordering the disabled branch already assumes.

**Outcome: fixed** (`c18474e`)

Edge added exactly as suggested, with the race and both of its outcomes written into the code
above the resource so the edge is not removed as redundant later.

**No apply was run, and none was needed.** The control is disabled and torn down, so the enable
transition exists only on the graph. Verified by plan alone:

- `terraform validate` — success; `terraform fmt -check` — clean.
- `terraform plan -detailed-exitcode` — **0**, before and after.
- the **saved plan file** (read as JSON, not trusted from the human output): 13 resource changes,
  all `no-op`; **destroy count 0**; `proxmox_virtual_environment_container.selfhost` present but
  unchanged.

---

### CR-04: the UCG-Max root password is still recoverable from this public repository

**File:** `NETWORK.md:19` (redacted in `eba340b`, inside `aa2b502..HEAD`)

**Issue:** The diff under review contains:

```diff
-- **Credentials:** `<Sc0rp10n!/>`
+- **Credentials:** `UNIFI_USG_SSH_USER` / `UNIFI_USG_SSH_PASS` in `~/.claude/secrets/ha-deercrest.env` — **never in this repo** (public)
```

The redaction itself is correct and the replacement pointer is accurate (`UNIFI_USG_SSH_PASS` is
present in `~/.claude/secrets/ha-deercrest.env`). But redaction is not remediation. The value is
recoverable in one command from any clone:

```
git log -S'Sc0rp10n' --all -- NETWORK.md
# eba340b docs(network): redact gateway root password, point at secrets store
# 5293db7 Decommission cerebro LXC and cleanup infrastructure
```

`eba340b`'s own commit message states this and schedules rotation for **2026-08-28**. Project
memory records that rotation as **OUTSTANDING** as of today, 2026-09-01. The credential has been
in public history since `b9c67e0` (2026-02-15) — over six months.

**Failure scenario:** The gateway is the sole primary subnet router for `172.16.1.0/24` and an exit
node. Anyone who has ever cloned or forked this repository — or any code-training crawler that
mirrored it — holds root on it. The stated mitigating factor (SSH is not port-forwarded) reduces
this to "requires LAN or tailnet access first", and the tailnet now has two exit nodes.

**Fix:** Rotate the UCG-Max root password in the UniFi console, update
`~/.claude/secrets/ha-deercrest.env`, and record the rotation date in `NETWORK.md`. History
rewriting is not worth attempting on a public repo with forks; rotation is the only real fix. Until
it is done, treat the value as compromised.

**Outcome: skipped — operator-accepted 2026-09-01.**

Reason: this can only be resolved by **rotating the credential on the device**, which is an
operator action on the UniFi console, not a code change. The operator reviewed and accepted the
finding as it stands.

Explicitly NOT done, and not to be attempted: no history rewrite, no `filter-branch`, no
force-push. The repository is public and may have forks and mirrors; rewriting would be
destructive, would not remove the value from anything already cloned, and was not asked for. The
finding's own text says the same.

**The finding stays open.** It is unchanged above and the analysis stands: the value has been in
public history since `b9c67e0` (2026-02-15), the gateway is the sole primary subnet router for
`172.16.1.0/24` and an exit node, and until rotation happens the credential is compromised.
Nothing in this remediation pass reduces that.

---

## Warnings

### WR-01: three `set -u` unbound-variable aborts kill the audit before it can report

**File:** `scripts/check-music-consumers.sh:338`, `:833`, `:297`

**Issue:** The script runs under `set -euo pipefail` (`:128`). Three variables are read without a
default on paths that are reachable:

1. **`JELLYFIN_API_KEY` (`:338`).** If `/mnt/fast/secrets/jellyfin-deercrest.env` is missing or
   unreadable, `:405` records a `fail` and increments `TOOLS_MISSING` — but `TOOLS_MISSING` is
   never used as a gate. Section 4 is entered on `JELLYFIN_ROUTE != unavailable` alone, which is
   set independently by `docker inspect` at `:429`. The first `jf_api` call then expands
   `${JELLYFIN_API_KEY}` and the shell exits: `check-music-consumers.sh: line 338:
   JELLYFIN_API_KEY: unbound variable`.
2. **`HA_SSH_HOST` (`:833`).** `:443` treats it as optional (`${HA_SSH_HOST:-nuc}`) while `:833`
   requires it (`"${HA_SSH_USER:-root}@${HA_SSH_HOST}"`). Setting `HA_SSH_KEY` without
   `HA_SSH_HOST` — the exact combination `:443` anticipates — aborts the run.
3. **`MA_USERNAME` / `MA_PASSWORD` (`:297`).** If the MA env file defines `MA_URL` but the
   credential keys are absent or renamed upstream, `ma_login` aborts instead of failing the
   assertion.

In all three the run dies mid-section: sections 5 and 6 never execute, so no summary, no
`FAILURES total`, and no per-consumer counts. `quick-health-check.sh` renders this as
`❌ BROKEN (check-music-consumers.sh exit 1)` followed by an empty `Summary:` block.

**Fix:** Default every externally-sourced variable at the point of use and gate the sections on the
precondition that was already detected:

```bash
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"
MA_USERNAME="${MA_USERNAME:-}"; MA_PASSWORD="${MA_PASSWORD:-}"
HA_SSH_HOST="${HA_SSH_HOST:-}"
```

then in the route block at `:396-407`, on a missing key set `JELLYFIN_ROUTE="unavailable"` so
section 4 takes its existing `jellyfin_fail "... UNKNOWN, not green"` branch; and require
`[[ -n "$HA_SSH_HOST" ]]` before setting `HA_ROUTE` at `:442`.

**Outcome: fixed** (`5d94d4e`)

Both halves applied. Every externally-sourced variable is defaulted at the top of the file *and*
re-defaulted after sourcing (the file may legitimately not define a key, or may have been refused
by WR-13's new gate). Defaulting alone would have been the wrong fix — it converts an abort into a
skip — so each precondition is gated at the **route**, which fires the existing "UNKNOWN, not
green" branches:

- missing `MA_URL`/`MA_USERNAME`/`MA_PASSWORD` → the MA route fails before `ma_login` is reached.
- missing `JELLYFIN_API_KEY` → the Jellyfin route fails before `docker inspect` sets an address, so
  section 4 cannot reach `jf_api` at all.
- `HA_SSH_KEY` set but `HA_SSH_HOST` empty — the exact combination the old `${HA_SSH_HOST:-nuc}`
  anticipated — is now its own branch, distinguished in the output from the by-design skip so it
  reads as the configuration gap it is.

A comment at the defaults names the coupling ("Do not add a default here without also adding its
gate there"), since a future default without a gate re-creates the silent skip.

---

### WR-02: the emergency-bind assertion can only ever pass

**File:** `scripts/check-music-consumers.sh:843-847`

**Issue:**

```bash
if "${HA_SSH[@]}" "mount" 2>/dev/null | grep -qF 'emergency/music'; then
  ma_fail "CONS-03: the Supervisor EMERGENCY BIND is in place for music — the real mount failed"
else
  pass "CONS-03: no emergency bind for music"
fi
```

Two independent problems, both producing a green:

1. If the SSH to the NUC fails for any reason, `mount` produces nothing, `grep -q` finds nothing,
   and the script reports `✅ CONS-03: no emergency bind for music`. Unreachable and healthy are
   indistinguishable — the failure this file's own header (`:29-31`) and `quick-health-check.sh`
   (`:95-98`) explicitly refuse to accept elsewhere.
2. `02-09-SUMMARY.md` records, from measurement, that `mount | grep emergency/music`
   **"matched 0 and can never match on this Supervisor version"** — it was retired as a false
   *negative* instrument during 02-08. The instrument is known dead and is still wired up here as
   an assertion, with no note in the file saying so. The only outcome it can produce is `pass`.

**Failure scenario:** A future operator copies the HA SSH key to LXC 100 (or runs the script from
the workstation), `HA_ROUTE` stops being `skipped`, and a check that structurally cannot fail
starts printing green next to real assertions — training the reader that this section means
something.

**Fix:** Either delete the check and record why, or replace it with the proof line 02-08 actually
established (`/media/music` present, a directory, mode `dr--r--r--`, **0 entries**), and capture
the SSH exit status so an unreachable NUC is `UNKNOWN` rather than `pass`:

```bash
MOUNT_TXT="$("${HA_SSH[@]}" "mount" 2>/dev/null)"; MOUNT_RC=$?
if [[ $MOUNT_RC -ne 0 ]]; then
  ma_fail "CONS-03: could not read the NUC's mount table (rc=$MOUNT_RC) — UNKNOWN, not green"
elif ...
```

**Outcome: fixed** (`26c3908`)

Took the second option: replaced with the proof 02-08 actually established, rather than deleting
the check. The probe reads `/media/music`'s type, mode, owner and **entry count** in one remote
command, and captures the ssh exit status.

The load-bearing assertion is **"0 entries is a failure"**. Mode and owner are reported alongside
but deliberately **not** asserted — a future Supervisor could plausibly move them while emptiness
stayed the tell, and asserting a mode that later changes produces a permanent red, which is the
failure mode 01-09 already recorded. Both reasons for the old check being unfailable are written
into the code above it, including that the `emergency/music` string can never match on this
Supervisor version.

This branch cannot run on LXC 100 (`HA_ROUTE=skipped` there by design), so it was verified against
six stubbed probe results:

| stub | verdict |
|---|---|
| ssh refused (exit 255) | FAIL — UNKNOWN, not green |
| empty output, exit 0 (timeout) | FAIL — UNKNOWN, not green |
| `/media/music` absent | FAIL — mount not in place |
| **`444\|root\|0`** — the 02-08 degraded signature | **FAIL** — the case the old check could never catch |
| `755\|root\|13` — healthy | pass |
| unparseable entry count | FAIL — UNKNOWN, not green |

Only a real, non-empty mount passes.

---

### WR-03: section 5's album count silently ignores `MA_LIBRARY_SCAN_LIMIT` and has no truncation guard

**File:** `scripts/check-music-consumers.sh:813` vs `:182`, `:684`, `:694-698`

**Issue:** `MA_LIBRARY_SCAN_LIMIT=2000` is defined at `:182` and used at `:684`, where `:695-698`
correctly warns when the result comes back at the limit and may be truncated:

> `raise MA_LIBRARY_SCAN_LIMIT before trusting a miss below.`

Section 5 then hardcodes the same number as a JSON literal:

```bash
CNT_JSON="$(ma_api music/albums/library_items "$(provider_filter '{"limit":2000}')")"
```

Two consequences. First, following the remedy the script prints — raising
`MA_LIBRARY_SCAN_LIMIT` — has no effect here, and the two queries silently diverge. Second,
section 5 has no `-ge limit` truncation check of its own, so once the local provider exceeds 2000
albums the summary line

```
MA albums, local provider:   2000   (target >= 3)
```

reports a ceiling as a measurement, with nothing indicating it is capped. The `>= 3` gate means
this cannot produce a false pass today, but the number is published in the committed transcript
that 02-09 treats as the drift record, and it is currently 70 — a full import brings it into range.

**Fix:**

```bash
CNT_JSON="$(ma_api music/albums/library_items \
            "$(provider_filter "$(jq -nc --argjson l "$MA_LIBRARY_SCAN_LIMIT" '{limit:$l}')")")"
...
if [[ "$MA_PROVIDER_ALBUM_COUNT" -ge "$MA_LIBRARY_SCAN_LIMIT" ]]; then
  warn "CONS-03: album count is at the query limit ($MA_LIBRARY_SCAN_LIMIT) — this is a floor, not a count"
fi
```

**Outcome: fixed** (`26c3908`)

Applied as suggested, both halves. Verified live on LXC 100: the count still reads 70 and the
truncation warning correctly stays silent at 70 < 2000.

---

### WR-04: the apply gate for the music export matches anywhere in the table

**File:** `infra/nfs-music-export.tf:202`

**Issue:**

```hcl
"exportfs -v | grep -q '${var.ha_nuc_ip}' || { echo 'FATAL: export for ${var.ha_nuc_ip} not present after exportfs -ra'; exit 1; }",
```

This asserts only that the string `172.16.1.31` appears *somewhere* in the entire kernel export
table. It never checks which export line it appeared on. When
`music_temp_export_enabled = true`, the temporary export at
`/mnt/tank/downloads/_phase2-albumartist-control` names the same client — so the gate passes off
the temp line even if `/mnt/tank/media/Music` failed to export entirely.

The same file spends `:358-362` warning about precisely this ("count the PATH lines … or a client
string gets credited to the wrong export") and `check-music-consumers.sh:477-482` implements the
continuation join to avoid it. The apply gate did not get the same treatment.

**Failure scenario:** The music drop-in is malformed or the dataset is unmounted at apply time, the
temp control is enabled, and the apply reports `--- music export ready ---` while serving only the
scratch export. Gate 1 of 2 (per the comment at `:200`) is satisfied by the wrong line.

**Fix:** Assert on the joined path line, the way the audit script does:

```hcl
"exportfs -v | awk '/^[^[:space:]]/ { if (NR>1) printf \"\\n\"; printf \"%s\", $0; next } { printf \" %s\", $1 } END { printf \"\\n\" }' | grep -q '^${local.music_export_path}[[:space:]]\\+${var.ha_nuc_ip}(' || { echo 'FATAL: ${local.music_export_path} not exported to ${var.ha_nuc_ip} after exportfs -ra'; exit 1; }",
```

**Outcome: fixed** (`c18474e`)

Applied. The join is factored into `local.exportfs_joined` rather than repeated, because this same
gate shape is now needed in four places and four hand-copied awk programs would drift. The same
treatment was applied to the temp export's own presence gate at `:280`, which had the identical
defect in the other direction.

Verified by rendering the gate through `terraform console` — the exact string Terraform will send
to the host — and running it against synthetic `exportfs -v` output, including the real wrapped
two-line form:

| export table | old gate | new gate |
|---|---|---|
| **temp export only, music export GONE** (the failure scenario) | **passes — wrongly** | fails: `FATAL-music-export-missing` |
| music only | passes | passes |
| music + temp | passes | passes |

---

### WR-05: three apply gates assert over the whole host export table, not the drop-ins Terraform owns

**File:** `infra/nfs-music-export.tf:206`, `:364`, `:369`

**Issue:** The file's design statement (`:12-13`) is explicit that Terraform owns exactly one
surface — `/etc/exports.d/music.exports` — "leaving `/etc/exports` untouched for anything else".
Three assertions then evaluate global state:

- `:206` — `exportfs -v | grep -q 'no_root_squash' && { echo 'FATAL: ...'; exit 1; }`
- `:364` — `n=$(exportfs -v | grep -cE '^/mnt/tank'); test "$n" -eq 2`
- `:369` — `n=$(exportfs -v | grep -cE '^/mnt/tank'); test "$n" -eq 1`

Every one of these fails on export lines Terraform neither wrote nor is responsible for.

**Failure scenario:** Someone adds an unrelated export on atlantis — a `no_root_squash` backup
share into `/etc/exports` (a common Proxmox pattern), or any second `/mnt/tank/*` export by any
mechanism. From that moment every `terraform apply` in `infra/` hard-fails with a FATAL about the
music export, which is fine, and about a condition the music export did not cause, which is not.
Because the failure is at the far end of a `remote-exec`, the message will not obviously point at
the unrelated export. The `-eq 1` / `-eq 2` magic numbers make the coupling invisible — nothing
names what the two exports are meant to be.

**Fix:** Scope the assertions to the Terraform-managed paths:

```hcl
# :206
"grep -q 'no_root_squash' /etc/exports.d/music.exports /etc/exports.d/music-temp.exports 2>/dev/null && { echo 'FATAL: no_root_squash in a Terraform-managed drop-in'; exit 1; } || true",
```

and replace the counts with presence/absence tests on the two known paths
(`local.music_export_path`, `var.music_temp_export_path`) rather than a count of everything under
`^/mnt/tank`. If a global `no_root_squash` scan is genuinely wanted as a whole-host guard, make
that a separate, separately-named check so its failure is not attributed to the music export.

**Outcome: fixed** (`c18474e`)

All three scoped as suggested. The counts became presence/absence tests on the two named paths, and
one assertion was **added** that the old code did not have: the disabled branch now checks the
load-bearing music export survived the teardown. The old `-eq 1` would have been satisfied by the
*wrong* export.

Confirmed the failure scenario is real before fixing it — with an unrelated
`/mnt/tank/backup 172.16.1.50(rw,no_root_squash,...)` export on the host and the control disabled,
the old gates produce:

```
n=$(exportfs -v|grep -cE ^/mnt/tank); test $n -eq 1  -> FATAL: expected exactly 1 ... found 2
exportfs -v | grep -q no_root_squash                 -> FATAL: no_root_squash present ...
```

Both would fail every `terraform apply` in `infra/`. The new gates return 0 against that same
table, and the `no_root_squash` gate still fires on a Terraform-owned drop-in that contains it.

One thing found while testing that is worth keeping: the suggested
`grep -q 'no_root_squash' music.exports music-temp.exports` is **implementation-dependent**, because
`music-temp.exports` is absent in steady state and grep's exit status with an unreadable operand
varies. It fires correctly under GNU grep 3.11 on atlantis but reports *clean* under BSD grep
against a drop-in that does contain `no_root_squash`. It was written as `cat f1 f2 2>/dev/null |
grep -q` instead, which is unambiguous on both. Verified on atlantis and on the workstation.

---

### WR-06: `remote-exec` inline lists are not run under `set -e`; failed installs and chowns do not fail the apply

**File:** `infra/nfs-music-export.tf:152-163`, `:253-262`

**Issue:** Terraform's `remote-exec` provisioner concatenates an `inline` list into a single
script and runs it; the provisioner's success is the *script's* exit status, i.e. the last
command's. It does not inject `set -e`. Every guard in this file that matters uses an explicit
`|| { ...; exit 1; }`, which is why the load-bearing gates work — but two commands have no such
guard and are not last in their list:

- `:157` — `dpkg -s nfs-kernel-server >/dev/null 2>&1 || (apt-get update -qq && ... install ...)`.
  A failed install (no archive reachable, dpkg lock held, disk full) returns non-zero, then
  `:161`'s `mkdir -p /etc/exports.d` succeeds and the provisioner reports success. The failure is
  caught two provisioners later by `systemctl enable --now nfs-server`, but the error the operator
  sees is "unit not found", not "the package did not install".
- `:260` — `chown ${var.apps_uid}:${var.apps_gid} ${var.music_temp_export_path}`. A failure here
  is not surfaced at all: the next provisioner is the `file` upload, then `exportfs -ra` and a
  presence check that passes. The comment at `:258-259` states the exact consequence — "apps must
  be able to read the scratch tree or the control scans as an empty provider" — which is a silent
  pass by construction.

**Fix:** Make `"set -e"` the first element of every `inline` list in this file. It costs one line
per provisioner and converts both of the above into an apply failure at the point of the failure.

**Outcome: fixed** (`c18474e`)

`"set -e"` is now the first element of all five `inline` lists in the file, with the reasoning
recorded once in full and cross-referenced from the other four. Every existing guard uses an
explicit `|| { ...; exit 1; }` or ends `|| true`, so none of them changes behaviour under `set -e`
— checked one by one.

`triggers` are untouched by this, so no resource re-runs and the plan stays clean; the change takes
effect the next time each provisioner runs for its own reasons.

---

### WR-07: `enable` restores the wrong backup — `ls -1t` sorts by mtime, but `cp -p` preserves the *source* mtime

**File:** `scripts/disable-jellyfin-hwaccel.sh:228-229`, `:255`

**Issue:** Backups are created with `cp -p`:

```bash
local backup="${JELLYFIN_CONFIG}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -p "$JELLYFIN_CONFIG" "$backup"
```

`-p` preserves mode, ownership **and timestamps** — so `<config>.bak.20260901T120000Z` carries
`encoding.xml`'s mtime, not the moment the backup was taken. `do_enable` then selects with:

```bash
backup=$(ls -1t "${JELLYFIN_CONFIG}".bak.* 2>/dev/null | head -1)
```

`ls -1t` sorts by mtime, which is now the wrong key. Concretely: `disable` → backup A (mtime
`M1`); `enable` restores A with `cp -p`, so `encoding.xml`'s mtime becomes `M1` again; the operator
changes the accel type in the Jellyfin UI (mtime `M2`); `disable` → backup B (mtime `M2`). So far
so good — but if instead the second `disable` follows an `enable` with no UI change in between,
A and B carry the *identical* mtime `M1`, and `ls -t`'s tie-break is unspecified. The filename
already encodes the true creation time in sortable ISO form and is being ignored.

**Failure scenario:** `enable` restores a stale `encoding.xml`, silently reverting whatever else
the operator changed in Jellyfin's Playback settings between the two backups — including settings
unrelated to hardware acceleration, since the whole file is restored. `do_enable` performs no
post-restore verification (see IN-06), so nothing reports it.

**Fix:** Sort by the timestamp that is actually in the name:

```bash
backup=$(ls -1 "${JELLYFIN_CONFIG}".bak.* 2>/dev/null | sort | tail -1)
```

and print the timestamp and the value being restored so the operator can refuse it.

**Outcome: fixed** (`a29fa95`)

Applied, including the second half — `do_enable` now prints the backup path, the timestamp taken
**from the filename** (with a note that mtime is unreliable and why), the `HardwareAccelerationType`
it is about to restore, and how many backups exist, before it writes anything.

Verified with two backups whose mtimes are deliberately inverted against their names:

```
OLD  ls -1t | head -1   -> enc.xml.bak.20260101T000000Z   <-- restores the JANUARY config
NEW  ls -1 | sort|tail  -> enc.xml.bak.20260901T120000Z   <-- restores the SEPTEMBER config
```

---

### WR-08: `preconditions()` proceeds when it could not measure, and treats an unparseable pressure value as healthy

**File:** `scripts/disable-jellyfin-hwaccel.sh:128-142`

**Issue:** The stated contract at `:128-129` is:

> `If the host is still wedged, dockerd is blocked behind the dead mmap_lock and 'docker restart'
> will hang rather than fail - so refuse before touching anything.`

The code does not refuse. Two gaps:

1. `:136-137` — when the probe returns nothing (ssh refused, timed out at `timeout 15`,
   `BatchMode` key rejected) it emits `warn` and leaves `fail=0`. `preconditions` returns 0, and
   `do_disable` proceeds to rewrite `encoding.xml` and `docker restart` the container. The one
   state that most strongly indicates a wedged host — atlantis not answering ssh — is the state
   that produces the weakest response.
2. `:138` — `elif awk "BEGIN{exit !(${io_full:-0} > 50)}"`. `io_full` is interpolated into an
   **awk program**, not passed as data. Any non-numeric value (`cut` returning a partial line, a
   locale-formatted number, an ssh banner fragment that survived the pipeline) makes awk exit 2 on
   a syntax error. Non-zero means the `elif` is false, so control falls to `:141`
   `ok "host io pressure full=${io_full}"` — an unparseable reading is reported as **healthy**.

**Fix:**

```bash
if [ -z "$io_full" ]; then
  bad "could not read io pressure from ${PROXMOX_HOST} — UNKNOWN, not healthy; refusing to mutate"; fail=1
elif ! printf '%s' "$io_full" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
  bad "io pressure value '${io_full}' is not a number — UNKNOWN, not healthy"; fail=1
elif awk -v v="$io_full" 'BEGIN{exit !(v > 50)}'; then
  bad "host io pressure full=${io_full} - still wedged; docker will hang. Reboot first."; fail=1
else
  ok "host io pressure full=${io_full}"
fi
```

`awk -v` passes the value as data rather than as program text, which also removes the injection
surface.

**Outcome: fixed** (`a29fa95`)

Applied verbatim. Both gaps confirmed against the old code before replacing it:

```
io_full='avg10'                              OLD -> REPORTED HEALTHY   NEW -> REFUSE (not a number)
io_full='0){system("echo INJECTED")};{'      OLD -> REPORTED HEALTHY   NEW -> REFUSE (not a number)
io_full=''                                   OLD -> warn, proceeds     NEW -> REFUSE (UNKNOWN)
io_full='96.10'                              OLD -> REFUSE             NEW -> REFUSE (wedged)
io_full='12.34'                              OLD -> ok                 NEW -> ok
```

**One correction to the finding**, recorded because the next reader should not inherit an
overstatement: the review calls the interpolation an "injection surface", and it is one — the value
is concatenated into awk *program* text. But an attempt to demonstrate an executing payload
**failed**. Three were tried; all three either failed to parse or parsed into a program where
`exit` runs before `system()`, so none executed. The demonstrated harm is therefore the
false-healthy fallthrough above, which is real and reproducible, not code execution. `awk -v` is
still the right fix — it closes the surface and fixes the fallthrough in one move — but it is
being adopted for the fallthrough.

---

### WR-09: the consumers block prints green without confirming the summary anchor was found

**File:** `scripts/quick-health-check.sh:134-136` (and `:102-104` for the freeze block)

**Issue:**

```bash
elif [ "$CONSUMERS_RC" -eq 0 ]; then
    echo "✅ Both consumers see the library"
    echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' | grep -E 'MA version|...' | sed 's/^/  /'
```

The success verdict is printed unconditionally; the evidence lines are best-effort. If the anchor
does not match, `sed -n` yields nothing, `grep` exits 1, and the block reports
`✅ Both consumers see the library` with no supporting detail and exit code 0.

`check-music-consumers.sh:853-855` treats this coupling as load-bearing and says so in capitals:

> `KEEP THIS HEADING LITERAL AND NEVER RENUMBER IT SILENTLY. Plan 02-09's fold-in anchors on it`

A documented coupling with no detector is a coupling that will break. Renumbering the sections
(adding a section 3b, splitting section 4) changes `6.` and breaks the anchor without any warning,
because the failing path is the one that still prints a tick. The same applies to `📊 7. Summary`
in the freeze block.

**Fix:**

```bash
elif [ "$CONSUMERS_RC" -eq 0 ]; then
    SUMMARY=$(echo "$CONSUMERS_OUT" | sed -n '/^📊 6\. Summary/,$p' \
              | grep -E 'MA version|albums matched in MA|albums matched in Jellyfin|FAILURES total')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — audit exited 0 but its '📊 6. Summary' block was not found."
        echo "  The section heading the fold-in anchors on has changed. State is UNKNOWN, not green."
        EXIT_CODE=1
    else
        echo "✅ Both consumers see the library"
        echo "$SUMMARY" | sed 's/^/  /'
    fi
```

**Outcome: fixed** (`fedbbdc`)

Applied to **both** blocks — the consumers block and the freeze block's `📊 7. Summary` anchor,
which had the identical defect.

Verified by simulating exactly the change the finding warns about (a renumbered heading, here
`📊 6b. Summary`): the block now prints `⚠️ UNKNOWN — the audit exited 0 but its '📊 6. Summary'
block was not found` and the script exits 1. Before the fix that same input printed a green tick
with no evidence lines and exited 0.

---

### WR-10: pre-existing silent pass in the same file — an unreachable host reports "✅ No unhealthy containers"

**File:** `scripts/quick-health-check.sh:68-74` (also `:46-53`, `:57-61`, `:64-65`, `:78-82`)

**Issue:** Not written by this phase, but it is in a file this phase modified, and it directly
contradicts the doctrine the new block's own comment states 60 lines further down ("Absence of a
failure signal is NOT evidence of health").

```bash
UNHEALTHY=$(ssh root@172.16.1.159 "docker ps --format '{{.Names}}' --filter health=unhealthy | wc -l" | tr -d ' ')
if [ "$UNHEALTHY" -gt 0 ]; then
```

There is no `BatchMode`/`ConnectTimeout` on these five ssh calls (the two new blocks have both).
When `172.16.1.159` is unreachable, `UNHEALTHY` is empty, `[ "" -gt 0 ]` writes
`integer expression expected` to stderr and returns 2, and the else branch prints
`✅ No unhealthy containers`. The Traefik and Authelia checks degrade the same way — ssh exit 255
renders as `❌ Not running`, a confident and wrong diagnosis rather than UNKNOWN.

**Failure scenario:** LXC 100 is down. The operator's health check prints `❌ Not running` for
Traefik and Authelia, `Containers running:` blank, and `✅ No unhealthy containers` — then the two
music blocks correctly report UNKNOWN and exit 1. The exit code saves it; the transcript above it
is misinformation.

**Fix:** Probe once and gate the whole file:

```bash
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 root@172.16.1.159 true 2>/dev/null; then
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable. No container state can be read."
    exit 1
fi
```

and add `-o BatchMode=yes -o ConnectTimeout=10` to the five legacy ssh calls so they cannot hang.

**Outcome: fixed** (`fedbbdc`)

Both halves applied — the single probe gates the file, and all five legacy calls now carry
`BatchMode`/`ConnectTimeout` via a shared `$SSH_OPTS`.

Reproduced the exact transcript the finding predicts, by pointing a copy at `192.0.2.1`:

```
Traefik: ssh: connect to host 192.0.2.1 port 22: Operation timed out
❌ Not running
Authelia: ❌ Not running
Containers running:
quick-health-check.sh: line 69: [: : integer expected
✅ No unhealthy containers
```

After: one statement, `⚠️ UNKNOWN — 192.0.2.1 (LXC 100) is unreachable over ssh`, exit 1. It is
also much faster — one bounded probe instead of five unbounded connect attempts.

One addition beyond the finding: the unhealthy count now rejects a **non-numeric** result even when
the host answered. `dockerd` can be blocked behind the amdgpu `mmap_lock` while `sshd` stays
perfectly healthy — that is precisely the Aug 31 signature this estate has already lived through —
so the reachability probe alone does not make `[ "$UNHEALTHY" -gt 0 ]` safe.

---

### WR-11: the audit stores and replays an MA account *password*, over plain HTTP, when a revocable token was available

**File:** `scripts/check-music-consumers.sh:72-83`, `:293-304`; cross-ref `stacks/selfhosted/arrs/beets.md`

**Issue:** The header justifies password auth as forced:

> `MA 2.11 has NO API-token UI. There is no such card in the Settings grid. Auth is
> username+password exchanged for a JWT via auth/login.`

That is accurate about the **UI** and is used to justify a decision about the **API**. This same
phase's `beets.md` records that `auth/token/create` exists and works, and used it to mint a
1-year, named, `token_id`-revocable token for the HA sync integration:

> `Minted via MA auth/token/create, name "HA M4 music sync (phase 02-08)", 1-year expiry,
> no auto-renew, revocable by token_id through auth/token/revoke.`

So a scoped, revocable, individually-auditable credential was available and demonstrably usable,
and the audit script instead stores the full account password. The password is strictly more
powerful than the token it replaces — among other things it can mint further tokens — and it
cannot be revoked without changing the account.

Compounding it: `MA_URL` is `http://172.16.1.31:8095` (per the committed transcript in
`02-09-SUMMARY.md`), so `auth/login` transmits the plaintext password over unencrypted HTTP on
**every run**, which since 02-09 means every `quick-health-check.sh`. This is a different exposure
from the accepted `sec=sys` NFS risk and is not recorded anywhere as a considered choice.

**Failure scenario:** Anyone with LAN or tailnet visibility of traffic to `172.16.1.31:8095`
captures an MA account password, not a revocable audit token, and revoking it requires a password
change that also breaks the HA sync integration and any browser session.

**Fix:** Mint a second named token (`"music consumers audit"`) via `auth/token/create`, store that
in `/mnt/fast/secrets/ma-deercrest.env` instead of the password, and drop `ma_login` in favour of
the stored bearer. Keep the per-run version banner as the expiry-drift detector. Record the
`token_id` next to the rotation list in `02-09-SUMMARY.md`. If password auth must be retained,
record the plaintext-HTTP exposure as an accepted risk the way `sec=sys` was.

**Outcome: partial — the risk is recorded, the token is NOT minted** (`f0fc92a`)

Took the finding's stated fallback, and only that. What was done:

- The header's `MA 2.11 has NO API-token UI` note now carries an explicit correction that it is a
  fact about the **UI** and not a justification for the **API** choice, naming
  `auth/token/create` and the `beets.md` evidence that it works.
- The plaintext-HTTP exposure is recorded as an **accepted risk**, in the same shape
  `infra/nfs-music-export.tf:30-45` records `sec=sys` — with its bound (LAN/tailnet only, 8095 not
  forwarded, and CR-01 means it is no longer in the process table as well) and with the real fix
  written out step by step.

**What was NOT done, and is still true today:** the audit still stores and replays the MA **account
password**, over plaintext HTTP, on every `quick-health-check.sh`. Minting the token is an operator
action against the live MA server — it creates and stores a credential and changes what is in
`/mnt/fast/secrets/ma-deercrest.env` — so it was deliberately left outstanding rather than
half-done from a fixer script. **Treat this finding as open.**

---

### WR-12: the standing audit does not detect the two option additions the Terraform names as forbidden

**File:** `scripts/check-music-consumers.sh:507-523` vs `infra/nfs-music-export.tf:90-95`

**Issue:** `nfs-music-export.tf:90-95` names three things as deliberately absent, with reasons:

```
#   fsid=            would relocate the NFSv4 pseudo-root ... would break
#   crossmnt         would implicitly export any child dataset created under
#                    the library later — a silent scope expansion
#   no_root_squash   forbidden outright, and moot under all_squash
```

The audit asserts the presence of `ro all_squash anonuid=568 anongid=568 mountpoint` and the
absence of `no_root_squash`. `crossmnt` and `fsid=` — one of which the Terraform explicitly
labels "a silent scope expansion" — have no detector at apply time or in the standing audit. Nor
is `sec=sys` asserted, so a change of security flavour would go unnoticed.

**Failure scenario:** A future edit adds `crossmnt` (a natural-looking fix for "the child dataset
isn't visible"). Every gate stays green while the export's scope silently widens to any dataset
later created under `/mnt/tank/media/Music` — exactly the outcome the comment was written to
prevent.

**Fix:** Add a forbidden-options loop mirroring the required-options loop at `:507`:

```bash
for opt in no_root_squash crossmnt rw insecure no_all_squash; do
  if printf '%s' ",$OPTS," | grep -qF ",$opt,"; then
    export_fail "CONS-01: FORBIDDEN option present — $opt (see infra/nfs-music-export.tf:90-95)"
  fi
done
printf '%s' "$OPTS" | grep -qE '(^|,)fsid=' && export_fail "CONS-01: fsid= present — relocates the NFSv4 pseudo-root"
```

and add `sec=sys` to the required list.

**Outcome: fixed** (`26c3908`)

Applied as suggested. `no_subtree_check` was added to the required list as well — it is in the
Terraform's deliberate option list with a stated reason and had no detector either.

Each detector was positive-controlled against a synthetic option string containing the thing it is
meant to catch, because a forbidden-options loop that has only ever been seen to pass is the same
defect in a new place:

| synthetic option set | missing-required | forbidden-present |
|---|---|---|
| the live export | none | none |
| live + `crossmnt` | none | **crossmnt** |
| live + `fsid=0` | none | **fsid=** |
| `rw,no_root_squash,no_all_squash,insecure` | ro, all_squash | **no_root_squash, rw, insecure, no_all_squash** |
| live minus `sec=sys` | **sec=sys** | none |

Confirmed live on LXC 100 against the real export: all seven required present, all six forbidden
absent, `FAILURES total: 0`.

---

### WR-13: the MA secrets file is sourced even after its mode/owner assertion fails, and every key is exported

**File:** `scripts/check-music-consumers.sh:382-394`, `:396-407`

**Issue:**

```bash
if [[ "$MA_MODE" == "600 root" ]]; then
  pass "MA credential $MA_SECRETS ($MA_MODE)"
else
  fail "MA credential $MA_SECRETS has mode/owner '$MA_MODE', want '600 root' (D-39)"
fi
set -a; . "$MA_SECRETS"; set +a
```

The `fail` is recorded and the file is sourced regardless. Two consequences:

1. A credential file that has become world-readable or is owned by someone else is executed as
   shell code by root. `.` runs arbitrary commands, not just assignments — if the file is
   writable by another account (which is precisely the state the assertion is detecting), that
   account has root code execution on LXC 100 the next time the health check runs.
2. `set -a` marks every variable in both files for export, so `MA_PASSWORD`, `MA_TOKEN`-adjacent
   values and `JELLYFIN_API_KEY` are placed in the environment of every subsequent child process —
   `ssh` to atlantis, `ssh` to the NUC, `docker inspect`, every `jq` and `curl`. That widens
   CR-01's exposure from argv to `/proc/<pid>/environ` for a large process tree.

**Fix:** Refuse to source a file that failed its own permission assertion, and stop exporting:

```bash
if [[ "$MA_MODE" != "600 root" ]]; then
  fail "MA credential $MA_SECRETS has mode/owner '$MA_MODE', want '600 root' (D-39) — REFUSING to source it"
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
else
  pass "MA credential $MA_SECRETS ($MA_MODE)"
  # shellcheck disable=SC1090
  . "$MA_SECRETS"      # no `set -a`: these are used in-process only
fi
```

(`set -a` is not needed — nothing here requires the values in a child's environment once CR-01 is
fixed with `$ENV.VAR`, which reads the *shell's* environment and does require export; in that case
export only the two variables that need it, immediately around the `jq` call, rather than
everything in both files.)

**Outcome: fixed** (`5d94d4e`, alongside CR-01 — the two are the same fix seen from two angles)

Both halves applied, for both credential files. A file that fails its mode/owner assertion is
**refused**, with the refusal stated in the output and `TOOLS_MISSING` incremented; the route gate
added for WR-01 then turns the resulting empty credential into a red "UNKNOWN, not green" rather
than a skip. `set -a` is gone.

The parenthetical's suggestion is exactly what CR-01 does: `MA_USERNAME="$MA_USERNAME"
MA_PASSWORD="$MA_PASSWORD" jq ...` is a command prefix, so the two values are in **jq's**
environment for that one command and are not exported to anything else. The argv/environ measurement
under CR-01 covers this: 0 of 44 invocations carried either value.

---

## Info

### IN-01: `MA_VERSION_LIVE` can be empty rather than `unknown`, defeating its own guard

**File:** `scripts/check-music-consumers.sh:421`, `:458`

`MA_VERSION_LIVE="$(curl -s --max-time 15 "${MA_URL}/info" | jq -r '.server_version // "unknown"' 2>/dev/null || echo unknown)"`.
When `curl` fails, `jq` receives empty input, produces no output and exits **0** — so the
`|| echo unknown` fallback never fires and `MA_VERSION_LIVE` is the empty string, not `unknown`.
The guard at `:458` (`!= "unknown"`) then passes and the drift warning prints
`MA version drift: running , assertions were proven at 2.11.0b0`. Cosmetic today, but the version
stamp is described as "the drift detector" (`:61-68`), so it should not be able to read blank.

**Fix:** `[[ -z "$MA_VERSION_LIVE" ]] && MA_VERSION_LIVE="unknown"` after the assignment.

**Outcome: fixed** (`5d94d4e`) — applied verbatim.

### IN-02: `grep -F "$LIBRARY "` is an unanchored substring match

**File:** `scripts/check-music-consumers.sh:483`

`EXPORT_LINE="$(printf '%s\n' "$EXPORT_TABLE" | grep -F "$LIBRARY " || true)"` selects any line
*containing* `/mnt/tank/media/Music `. A sibling export at `/mnt/tank/media/Music Videos` (a
plausible path in this estate) would be selected instead, or as well — and a two-line
`EXPORT_LINE` makes the client and option parsing at `:490-491` produce multi-line values. It
fails loudly rather than passing, but the diagnostic would be misleading.

**Fix:** `grep -E "^${LIBRARY//\//\\/}[[:space:]]"` after the continuation join, and fail
explicitly if more than one line matches.

**Outcome: fixed** (`26c3908`) — but **not with the suggested regex, which does not work.**

`^/mnt/tank/media/Music[[:space:]]` still matches `/mnt/tank/media/Music Videos 172.16.1.31(...)`,
because the space inside `Music Videos` *is* the `[[:space:]]`. Measured, not reasoned about — the
anchored form was written first and tested, and it selected the sibling exactly as the unanchored
one did.

Selection is instead an exact literal prefix (`index($0, p " ") == 1`, no regex over the path at
all) plus a shape check that what follows is a client field — one unspaced token ending in `(` —
which `Videos ` is not. Verified across four table shapes:

| table | selected |
|---|---|
| `Music Videos` sibling + the real export | the real export only |
| the `Music Videos` sibling alone | **nothing** → "not exported at all" |
| two clients on the same path | both → the new AMBIGUOUS branch |
| the live table | the real export |

The multi-line case is its own branch and reports AMBIGUOUS rather than falling through to "not
exported at all", which would have been a misleading second diagnosis.

### IN-03: the audit hardcodes `anonuid=568` where the Terraform forbids the literal

**File:** `scripts/check-music-consumers.sh:507` vs `infra/nfs-music-export.tf:55-58`

The Terraform states: *"Never write 568 as a literal — the point is that the inheritance is
visible in the code"*, and interpolates `var.apps_uid`/`var.apps_gid`. The standing audit that
guards that export then hardcodes `anonuid=568 anongid=568` in its required-options loop. Changing
`var.apps_uid` would apply cleanly and then fail the health check with a message that reads like an
export defect. Worth at least a comment naming the coupling, or reading the values from a shared
source.

**Outcome: fixed** (`26c3908`) — the comment, not the shared source.

The audit runs on LXC 100 and has no access to Terraform's variables, so a genuinely shared source
would mean a generated file or a new artifact for one pair of integers. The coupling is named
instead, in both directions and with the diagnosis spelled out ("if you are here because this line
went red after a var.apps_uid change, that is the reason, and both places must move together").

### IN-04: `do_check` presents an unreadable config as "VAAPI is ON"

**File:** `scripts/disable-jellyfin-hwaccel.sh:201-217`

`do_check` does not call `preconditions`, and `current_hwaccel` is invoked with `2>/dev/null`. If
`python3` is missing, `state` is empty; `${state%%|*}` is empty; the `case` at `:212` falls to `*)`
and prints `⚠ VAAPI is ON () - run 'disable' to remove the trigger`. The direction is safe (it
never falsely reports OFF) but it states a determinate fact it did not measure, and
`HardwareAccelType :` prints blank two lines above.

**Fix:** add an explicit `""|UNREADABLE*)` case reporting UNKNOWN.

**Outcome: fixed** (`a29fa95`) — applied as suggested, and the UNKNOWN arm points the operator at
`disable`, which does call `preconditions()` and will refuse with a specific reason.

### IN-05: the two new ssh calls in `quick-health-check.sh` omit `-n`

**File:** `scripts/quick-health-check.sh:88`, `:120`

`check-music-consumers.sh:188` establishes `-n` on inline ssh as a convention with a measured
reason ("so a nested ssh cannot eat this script's stdin"). Both remote invocations here are inline
`ssh host 'cmd'` — the shape the convention covers, not the `bash -s` heredoc shape it must be
kept away from — and neither carries `-n`. No current consequence (neither remote script reads
stdin), but the first ssh can drain the outer script's stdin if it is ever run with input attached,
leaving the second with nothing.

**Outcome: fixed** (`fedbbdc`) — `-n` added to both, with a comment recording why it is correct
here and where it must *not* go.

Re-confirmed by accident during this remediation: a nested `ssh A "ssh -n B 'bash -s'" <<EOF`
produced no output at all, because the inner `-n` fed the remote `bash -s` from `/dev/null`. That
is exactly the boundary the convention draws, met live.

### IN-06: `do_enable` has no post-restore verification

**File:** `scripts/disable-jellyfin-hwaccel.sh:252-266`

`do_disable` re-reads the config after the restart and fails if it does not read `none`
(`:247-248`). `do_enable` restores the backup, restarts, and warns — without ever re-reading what
was restored. Combined with WR-07 (wrong backup selected), the restore of a stale or wrong config
is completely silent.

**Fix:** mirror `do_disable`: `after=$(current_hwaccel)`, report the restored value, and fail if it
is `none` or unreadable.

**Outcome: fixed** (`a29fa95`) — mirrored as suggested. `do_enable` now re-reads after the restart
and fails on unreadable, on `none` and on `absent`, with the `none` case naming the actual cause
("the selected backup was taken while VAAPI was already off") and pointing at
`ls -1 <config>.bak.*` so the operator can pick another.

### IN-07: the temp-export reconciler is a transition hook, not a reconciler

**File:** `infra/nfs-music-export.tf:332-338`

`triggers = { temp_enabled = tostring(var.music_temp_export_enabled) }` means the resource re-runs
only when the flag *changes*. With the flag steady at `false`, a later `terraform apply` does not
re-run the `rm -f` or the `exportfs -ra`, so a hand-recreated `/etc/exports.d/music-temp.exports`
would persist across applies with a clean plan — a smaller instance of the drift the resource was
created to close. The header at `:288-296` describes it as a reconciler; it is a one-shot on
transition.

**Fix:** either document the limitation in the header, or add `timestamp()`/a run counter to make
it always-run (accepting a permanent "1 to change" in every plan), or move the assertion into the
standing consumers audit, which already reaches atlantis.

**Outcome: fixed** (`c18474e`) — took the first option of the three.

`timestamp()` was rejected for the reason the finding itself flags: it puts a permanent
"1 to change" in every plan of this repo, and a plan that is never clean is a plan nobody reads —
which would trade a narrow drift for a broad one. The limitation is documented in the header, and
the header no longer calls the resource a reconciler without qualification. The standing detector
for the drift is the consumers audit, which reaches atlantis on every health check and (after
WR-12) now asserts the export's full option set.

### IN-08: `set_hwaccel` appends missing elements to the end of a .NET-serialised XML config

**File:** `scripts/disable-jellyfin-hwaccel.sh:190-197`

```python
def setel(name, text):
    el = root.find(name)
    if el is None:
        el = ET.SubElement(root, name)
```

`encoding.xml` is produced by .NET's `XmlSerializer`, whose deserialiser is element-order sensitive
for sequence-typed schemas. When the element already exists (the normal case) only its text
changes and order is preserved, so this is latent rather than active — but on a config where
`HardwareAccelerationType` or `EnableHardwareEncoding` is genuinely absent, the element is appended
at the end of the document, where Jellyfin may refuse to deserialise it. `ET.write` also discards
any comments and rewrites the declaration.

**Fix:** insert at the correct index rather than appending, or refuse and tell the operator to set
it once in the UI (the same stance `do_enable` already takes at `:257-258`).

**Outcome: skipped — not trivially safe, needs a fact this pass does not have.**

"Insert at the correct index" requires knowing the canonical element order of Jellyfin's
`EncodingOptions` schema, which is not derivable from the file in front of me and was not measured.
Guessing an index is a worse failure than appending: it would reorder a config that currently
deserialises fine, in the normal case where the element already exists and nothing needs inserting
at all.

The alternative — refuse and tell the operator to set it in the UI — changes what `disable` does in
a case nobody has observed, and `disable` is the remediation path for a six-hour outage. Narrowing
it on an unmeasured hypothesis is not a trade worth making from a fix pass.

The finding's own assessment stands: **latent, not active.** On this estate's live config both
elements are present (`HardwareAccelType: none`, `HardwareEncoding: false`, read on 2026-09-01),
so `setel` only rewrites text and preserves order. Left as-is deliberately. If it is ever worth
closing, the missing input is the schema's element order, and the check is whether Jellyfin
re-reads a config with an appended element.

## What was checked and found sound

Recorded so a re-review does not re-litigate it:

- **Exit-code capture** (`quick-health-check.sh:88-90`, `:120-122`) — `RC=$?` immediately follows
  the assignment; the ANSI strip happens on a *later* line into a separate assignment, so no pipe
  intervenes. Both blocks. Correct.
- **Empty-output handling** in both folded-in blocks — `[ -z "$OUT" ]` → UNKNOWN + `EXIT_CODE=1`,
  and `2>&1` is placed inside the remote command string so local ssh errors deliberately do *not*
  populate the variable. This is what makes the unreachable-host branch fire, as 02-09 deviation 4
  demonstrated.
- **macOS portability** — `$'s/\033\\[[0-9;]*m//g'` with `LC_ALL=C`; no `\x1b`, no `sed -i`, no
  `grep -P`, no `readlink -f`, no GNU-only `date`/`stat` in the workstation-side script. `stat -c`
  appears only in `check-music-consumers.sh`, which runs on LXC 100.
- **`ssh -n` split** — `SSH_OPTS=(-n ...)` and `HA_SSH=(ssh -n ...)` are applied to inline commands
  only; there is no `bash -s` + heredoc anywhere in the phase's scripts.
- **Spotify false-pass defence** — server-side `provider` filter (`provider_filter`, `:319-329`)
  plus an independent client-side `provider_mappings[].provider_instance` re-check (`:711-713`).
  `music/albums/count` is not used. `search` is not used. All three deliberate choices are
  actually implemented.
- **`exportfs -v` continuation joining** — implemented in the audit (`:477-482`) and respected in
  the Terraform reconciler, which counts `^/mnt/tank` path lines rather than client lines
  (`:358-364`). Correct in both.
- **Jellyfin addressing** — resolved per-run via `docker inspect ... "t3_proxy"` (`:429-430`), with
  the `:8096` sentinel correctly detecting a failed resolution. No literal IP, no bare hostname.
- **`prevent_destroy` + `ignore_changes = [mount_point]`** on `lxc-selfhost.tf` / `lxc-mpe.tf` —
  present, and the accepted cost (real bind-mount edits plan clean and do nothing) is stated in the
  code, not only in a plan.
- **`var.proxmox_ssh_password`** is `sensitive = true` (`variables.tf:33-37`) and is referenced
  only from `connection` blocks, which Terraform does not persist to state. The `self.triggers`
  design rejected at `nfs-music-export.tf:301-320` was rejected for the right reason.
- **Secret scan** — `git grep` for JWT, bearer, `password=`, `api_key=` patterns across
  `NETWORK.md`, `TAILSCALE.md`, `CLAUDE.md`, `beets.md`, `scripts/` and `infra/` returns nothing.
  Every credential in the docs appears as a variable name, a file path, or a `!secret` reference.
- **Doc/code agreement** — the export line published in `NETWORK.md` and `beets.md`
  (`sync,wdelay,hide,no_subtree_check,mountpoint,anonuid=568,anongid=568,sec=sys,ro,secure,root_squash,all_squash`)
  is exactly what `local.music_export_line` generates plus knfsd's defaults; no `no_root_squash` on
  the Music export; `showmount`/`findmnt` appear only as prohibitions.

---

_Reviewed: 2026-09-01T16:29:30Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
