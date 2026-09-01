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

### IN-02: `grep -F "$LIBRARY "` is an unanchored substring match

**File:** `scripts/check-music-consumers.sh:483`

`EXPORT_LINE="$(printf '%s\n' "$EXPORT_TABLE" | grep -F "$LIBRARY " || true)"` selects any line
*containing* `/mnt/tank/media/Music `. A sibling export at `/mnt/tank/media/Music Videos` (a
plausible path in this estate) would be selected instead, or as well — and a two-line
`EXPORT_LINE` makes the client and option parsing at `:490-491` produce multi-line values. It
fails loudly rather than passing, but the diagnostic would be misleading.

**Fix:** `grep -E "^${LIBRARY//\//\\/}[[:space:]]"` after the continuation join, and fail
explicitly if more than one line matches.

### IN-03: the audit hardcodes `anonuid=568` where the Terraform forbids the literal

**File:** `scripts/check-music-consumers.sh:507` vs `infra/nfs-music-export.tf:55-58`

The Terraform states: *"Never write 568 as a literal — the point is that the inheritance is
visible in the code"*, and interpolates `var.apps_uid`/`var.apps_gid`. The standing audit that
guards that export then hardcodes `anonuid=568 anongid=568` in its required-options loop. Changing
`var.apps_uid` would apply cleanly and then fail the health check with a message that reads like an
export defect. Worth at least a comment naming the coupling, or reading the values from a shared
source.

### IN-04: `do_check` presents an unreadable config as "VAAPI is ON"

**File:** `scripts/disable-jellyfin-hwaccel.sh:201-217`

`do_check` does not call `preconditions`, and `current_hwaccel` is invoked with `2>/dev/null`. If
`python3` is missing, `state` is empty; `${state%%|*}` is empty; the `case` at `:212` falls to `*)`
and prints `⚠ VAAPI is ON () - run 'disable' to remove the trigger`. The direction is safe (it
never falsely reports OFF) but it states a determinate fact it did not measure, and
`HardwareAccelType :` prints blank two lines above.

**Fix:** add an explicit `""|UNREADABLE*)` case reporting UNKNOWN.

### IN-05: the two new ssh calls in `quick-health-check.sh` omit `-n`

**File:** `scripts/quick-health-check.sh:88`, `:120`

`check-music-consumers.sh:188` establishes `-n` on inline ssh as a convention with a measured
reason ("so a nested ssh cannot eat this script's stdin"). Both remote invocations here are inline
`ssh host 'cmd'` — the shape the convention covers, not the `bash -s` heredoc shape it must be
kept away from — and neither carries `-n`. No current consequence (neither remote script reads
stdin), but the first ssh can drain the outer script's stdin if it is ever run with input attached,
leaving the second with nothing.

### IN-06: `do_enable` has no post-restore verification

**File:** `scripts/disable-jellyfin-hwaccel.sh:252-266`

`do_disable` re-reads the config after the restart and fails if it does not read `none`
(`:247-248`). `do_enable` restores the backup, restarts, and warns — without ever re-reading what
was restored. Combined with WR-07 (wrong backup selected), the restore of a stale or wrong config
is completely silent.

**Fix:** mirror `do_disable`: `after=$(current_hwaccel)`, report the restored value, and fail if it
is `none` or unreadable.

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

---

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
