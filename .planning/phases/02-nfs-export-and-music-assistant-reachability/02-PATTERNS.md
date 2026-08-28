# Phase 2: NFS Export and Music Assistant Reachability - Pattern Map

**Mapped:** 2026-08-29
**Files analyzed:** 14 (4 created in-repo, 6 modified in-repo, 4 off-repo with no in-repo analog)
**Analogs found:** 9 / 14

> This is an infrastructure repo — Terraform under `infra/`, bash audit scripts under `scripts/`,
> Docker Compose under `stacks/selfhosted/`, and markdown at the root. **No test framework, no
> Python, no application code.** Phase 1's `01-PATTERNS.md` established the script analogs; this
> phase inherits them directly rather than re-deriving. The new ground is `infra/` Terraform,
> which Phase 1 never touched — and the three things this phase needs from Terraform
> (`triggers`, `provisioner "file"`, a conditional resource) **exist nowhere in `infra/` today**.
> Those are called out in § No Analog Found; the planner must not present them as copied patterns.

---

## File Classification

### Terraform (`infra/`)

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `infra/nfs-music-export.tf` (new) | host config | idempotent apply over SSH | `infra/lxc-mpe.tf:51-71` (shape) + `infra/host.tf:12-115` (idiom) | role-match |
| `infra/variables.tf` (modified) | config | config | itself — `variables.tf:3-7`, `131-141`, `250-254` | exact |
| `infra/outputs.tf` (modified, discretionary) | config | config | itself — `outputs.tf` `verify_commands` | exact |

### Scripts (`scripts/`)

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `scripts/check-music-consumers.sh` (new) | verify script | read-only audit, request-response over SSH + HTTP | `scripts/check-music-freeze.sh` | exact (contract), partial (transport) |
| `scripts/quick-health-check.sh` (modified) | health check | request-response over ssh | itself — `quick-health-check.sh:63-97` | exact |

### Documentation

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `stacks/selfhosted/arrs/beets.md` (modified, D-47) | stack doc | doc | itself — `beets.md:189-408` (the Phase 1 section) | exact |
| `.planning/PROJECT.md` (modified, D-47) | project doc | doc | its own `## Key Decisions` table, `PROJECT.md:176-188` | exact |
| `NETWORK.md` (modified, D-48) | network map | doc | `NETWORK.md:205-229` (host-level services) + `48-66` (host entry) | exact |

### Data / evidence artifacts

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| The three pinned albums (D-09) | test fixture | data | **none committed** — see § No Analog Found | none |
| Reboot / negative-control transcripts (D-37) | evidence | doc | `beets.md:227-262`, `01-06-SUMMARY.md:233-300` | role-match |

### Off-repo files this phase writes (no in-repo analog; state as new work)

| File | Where | Role | Written by |
|------|-------|------|-----------|
| `/etc/exports.d/music.exports` | atlantis `172.16.1.158` | config | Terraform `provisioner "file"` (D-12) |
| `/etc/systemd/system/nfs-server.service.d/10-zfs-order.conf` | atlantis | config | Terraform `remote-exec` (M2, D-33) |
| `/config/…` automation + `rest_command` + notification | NUC `172.16.1.31` | automation | operator / `ha` CLI (M4 D-33, D-34, D-54) |
| MA token + Jellyfin API key | `/mnt/fast/secrets/` on LXC 100 (D-39/D-40) | secret | operator, via stdin |

---

## Pattern Assignments

### `infra/nfs-music-export.tf` (new — host config, idempotent apply over SSH)

**Analogs — two, deliberately.** `infra/lxc-mpe.tf:51-71` for the *file shape* (a small,
single-purpose `null_resource`), `infra/host.tf` for the *inline-command idiom*.

**Shape pattern** (`lxc-mpe.tf:51-71`) — the whole resource, and it is short. This is what a
focused `null_resource` in this repo looks like:

```hcl
# ── Phase 1: ensure the dedicated ZFS dataset exists on the host ─────────────
# The mount_point below binds /mnt/fast/appdata/mpe, which must be a real ZFS
# dataset (raw bind of a non-dataset path fails EINVAL on an unprivileged LXC).
resource "null_resource" "mpe_dataset" {
  depends_on = [null_resource.host_setup]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "zfs list fast/appdata/mpe >/dev/null 2>&1 || zfs create -p fast/appdata/mpe",
      "chown ${var.apps_uid}:${var.apps_gid} /mnt/fast/appdata/mpe",
      "echo '--- MPE dataset ready ---' && zfs list fast/appdata/mpe",
    ]
  }
}
```

Four conventions to copy verbatim: the `# ── Section ─────` box comment above the resource with a
*why* sentence; `depends_on = [null_resource.host_setup]` (the export needs the pools imported and
mounted, which is `host_setup`'s job — `host.tf:44-58`); the four-key `connection` block using
`var.proxmox_host` / `var.proxmox_ssh_user` / `var.proxmox_ssh_password`; and a final `echo … &&
<verify command>` line so the apply log carries its own evidence.

**File header pattern** (`host.tf:1-11`) — numbered contract, then an explicit idempotency claim:

```hcl
# host.tf — Phase 1: Proxmox host baseline
#
# Runs once via SSH on the Proxmox host to:
#   1. Remove enterprise subscription nags and update packages
#   ...
# All operations are idempotent — safe to re-run if the resource is tainted.
```

`lxc-mpe.tf:8-14` uses the same form as a numbered *resource* index:

```hcl
#   1. null_resource.mpe_dataset        — ensure ZFS dataset fast/appdata/mpe exists
#   3. null_resource.patch_lxc_config_mpe — write apps-only idmap into the LXC conf
```

**Guarded-idempotent inline commands** — the exact idiom D-14's `dpkg -s … || apt-get install`
must match (`host.tf:67-70`, `112`, `26`):

```hcl
"getent group apps >/dev/null 2>&1 || groupadd -g ${var.apps_gid} apps",
# -r (system account) is required on Proxmox/Debian — without it useradd
# rejects UIDs below UID_MIN (1000) even when the UID is explicitly specified.
"id apps >/dev/null 2>&1 || useradd -r -u ${var.apps_uid} -g ${var.apps_gid} -M -s /usr/sbin/nologin apps",
```

```hcl
"pveam list ${var.template_storage} | grep -q '${var.lxc_template}' || pveam download ${var.template_storage} ${var.lxc_template}",
```

```hcl
"grep -qE '\\b${var.proxmox_node}\\b' /etc/hosts || echo '${var.proxmox_host} ${var.proxmox_node}' >> /etc/hosts",
```

Note the three sub-idioms: `<query> >/dev/null 2>&1 || <create>`, `<list> | grep -q '<x>' || <get>`,
and `grep -q … || echo … >>`. Also `host.tf:35-36`'s `… 2>/dev/null || true` for "harmless if
already done", and `host.tf:44`'s three-way `A || B || echo 'INFO: …'`. Every inline entry carries
a `#` comment above it explaining *why*, frequently with the failure it prevents named explicitly
("otherwise pct start will fail with `mount: special device not found`", `host.tf:61-62`).

**Interpolation of the estate service account** — already a variable, do not hardcode `568`:

```hcl
variable "apps_uid" {
  description = "UID for the apps service account (TrueNAS default: 568)"
  type        = number
  default     = 568
}
```
(`variables.tf:131-141`). D-12's `anonuid=568,anongid=568` becomes
`anonuid=${var.apps_uid},anongid=${var.apps_gid}` — this is how `lxc-mpe.tf:22`, `lxc-selfhost.tf:47`
and `host.tf:67` all reference it, and it is what makes the C-9 inheritance from Phase 1 WRIT-04
visible in the code rather than as a coincidence of literals.

**`locals` block placement** (`lxc-mpe.tf:20-48`, `lxc-selfhost.tf:43-84`) — a `locals {}` block
sits directly above the resources that consume it, one assignment per line, with a trailing `#`
comment giving the computed value:

```hcl
locals {
  mpe_u_r1_start = 0
  mpe_u_r1_host  = 100000
  mpe_u_r1_count = var.apps_uid # 568
  ...
  mpe_conf = "/etc/pve/lxc/${var.mpe_vmid}.conf"
}
```

**Multi-line string literal** — the only `<<-EOT` heredoc in `infra/` is `outputs.tf`
`verify_commands`. It is the shape for `local.music_export_file`:

```hcl
output "verify_commands" {
  description = "Quick verification commands to run after apply"
  value       = <<-EOT
    # On Proxmox host:
    ssh root@${var.proxmox_host} "zfs list | grep -E 'fast|tank'"
    ...
  EOT
}
```

**Three things in the RESEARCH.md recommended shape have no analog here — see § No Analog Found:**
`triggers = {}`, `provisioner "file"`, and any conditional/`count`-gated resource for D-15's
temporary export.

---

### `infra/variables.tf` (modified — `ha_nuc_ip`, D-15 enable flag)

**Analog:** itself. Two conventions, both universal in the file.

**Sectioning** (`variables.tf:1`, `39`, `47`, `129`, `167`, `235`):

```hcl
# ── UID/GID — must match TrueNAS filesystem ownership on fast/tank pools ────
```

**IP variable with a justifying description** (`variables.tf:61-65`, `250-254`) — descriptions here
carry the *reason for the value*, not a restatement of the name:

```hcl
variable "lxc_ip" {
  description = "Static IP for the Docker LXC — reuses old TrueNAS IP so no DNS/firewall changes needed"
  type        = string
  default     = "172.16.1.159"
}
```

```hcl
variable "mpe_ip" {
  description = "Static IP for the MPE LXC — next free in 172.16.1.16x (.160 freed by cerebro removal; .161/.162 in use)"
  type        = string
  default     = "172.16.1.163"
}
```

D-13's "the tailnet address is deliberately NOT in the export" belongs in the `ha_nuc_ip`
description, in exactly this register. The RESEARCH.md draft (`02-RESEARCH.md:1148-1152`) already
matches this convention.

**Boolean variables:** there are **zero** `type = bool` variables in `infra/` today. D-15's enable
flag is a new type in this file; follow the same description-carries-the-reason rule and state that
`false` is the teardown state, not merely the default.

---

### `scripts/check-music-consumers.sh` (new — verify script, D-41/D-42)

**Analog:** `scripts/check-music-freeze.sh` — the exit-code contract is inherited **exactly**
(D-41), and this file is where it is defined. `01-PATTERNS.md:366-373` records that the estate had
no convention before this file; do not go looking for an older one.

**The exit-code contract, stated in the header** (`check-music-freeze.sh:31-42`) — copy this
structure and its reasoning, adapted:

```bash
# EXIT-CODE CONVENTION (established here deliberately; the estate has none):
#   default mode  - every red finding increments FAILURES and the script ends non-zero.
#   --baseline    - every finding is printed and the script always ends zero, so the
#                   before-state can be recorded while the harness does not yet exist.
#   Why this is stated rather than inherited: check-renovate.sh exits zero on every finding
#   except a missing renovate.json, and quick-health-check.sh never exits non-zero at all.
#   Inheriting that silence is what let the docker `created`-state blind spot hide two down
#   containers for six weeks under a green check.
```

**The exit-code implementation** (`check-music-freeze.sh:539-549`) — three branches, in this order:

```bash
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "${YELLOW}--baseline: $FAILURES findings recorded, exiting 0. This is the before-state.${NC}"
  exit 0
fi

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}❌ $FAILURES failed checks${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Music freeze harness intact${NC}"
```

Note: `--baseline` exits 0 **after** printing the summary, not before — the counts are still
emitted. `exit $(( FAILURES > 0 ? 1 : 0 ))` (the RESEARCH.md skeleton, `02-RESEARCH.md:1421`) is
**not** the estate shape; use the three-branch form so `--baseline` is expressible.

**Strictness and constants** (`check-music-freeze.sh:66-88`) — `set -euo pipefail`, then ALL-CAPS
constants with trailing `#` comments giving the reason, then the colour palette:

```bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LIBRARY="/mnt/tank/media/Music"
MEDIA_ROOT="/mnt/tank/media"
STACKS="$REPO_ROOT/stacks/selfhosted"   # /mnt/fast/stacks/stacks/selfhosted on LXC 100
UIDGID="568:568"
ZFS_HOST="172.16.1.158"                 # Proxmox host "atlantis" - the only place zfs exists

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
```

`ZFS_HOST="172.16.1.158"` is already the atlantis constant the export checks need; add a NUC
constant beside it in the same style.

**Reporting helpers** (`check-music-freeze.sh:116-121`) — copy verbatim; `fail()` incrementing
`FAILURES` *is* the contract:

```bash
FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
```

Note the two-space indent baked into `fail`/`pass` — section headings are flush-left, findings are
indented. `warn()` exists and is the tool for D-11-adjacent things that are reported but not
asserted; `check-music-freeze.sh:405-416` is the precedent for **report-not-assert** with an inline
comment saying why, which the planner should reuse for anything MA-version-dependent (D-56).

**A scoped sub-counter** (`check-music-freeze.sh:473-474`) — the pattern for grouping a section's
failures while still feeding the global count:

```bash
FENCE_FAILURES=0
fence_fail() { fail "$*"; FENCE_FAILURES=$((FENCE_FAILURES + 1)); }
```

D-42's two consumers (Jellyfin, MA) map cleanly onto two such sub-counters, so the summary can say
which consumer failed.

**Argument parsing + `--help`** (`check-music-freeze.sh:90-106`):

```bash
BASELINE_MODE=0
for arg in "$@"; do
  case "$arg" in
    --baseline) BASELINE_MODE=1 ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: bash scripts/check-music-freeze.sh [--baseline] [--sidecars]" >&2
      exit 2
      ;;
  esac
done
```

`-h` re-prints the header comment block — which is why the header is worth writing carefully. Note
`exit 2` for a usage error, distinct from `exit 1` for a failed assertion.

**Run banner** (`check-music-freeze.sh:144-156`) — every run states its own parameters and mode, so
a committed transcript (D-37) is self-describing:

```bash
echo "🎵 Music Freeze Harness Audit"
rule
echo "  library:   $LIBRARY"
echo "  host:      $(hostname)"
echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "  mode:      ${YELLOW}--baseline (report only, always exits 0)${NC}"
else
  echo "  mode:      assert (exits non-zero on any failed check)"
fi
```

D-21 and D-56 require recording the exact MA version every criterion was proven at — this banner is
where it belongs, alongside `date`.

**Numbered sections** (`check-music-freeze.sh:158-159`, `185-186`, `249-250`, `517-518`) — emoji +
`N. Description (REQUIREMENT-IDs)`, then `rule`:

```bash
# 1. Running-container rw holders on the library (WRIT-01, D-26)
echo "🐳 1. Running-container rw holders on the library (WRIT-01, D-26)"
rule
```

The header's "What it covers" table (`check-music-freeze.sh:18-29`) maps each section to its
requirement ids — reproduce it for CONS-01 / CONS-02 / CONS-03.

**Summary block** (`check-music-freeze.sh:517-536`) — aligned label/value/target, one line per
assertion, `FAILURES total` last:

```bash
echo "📊 7. Summary"
rule
echo "  tagger-class writers:        $TAGGER_COUNT   (target 0)"
echo "  declared rw reaching Music:  $DECLARED_MUSIC_RW_COUNT   (target 0, jellyfin.yaml excluded)"
echo "  ownership mismatches:        $OWN_MISMATCH   (target 0, want $UIDGID)"
echo "  fence assertions failed:     $FENCE_FAILURES"
echo "  FAILURES total:              $FAILURES"
```

**Keep the `📊 N. Summary` heading literal** — `quick-health-check.sh:83` and `:89` extract it with
`sed -n '/^📊 7\. Summary/,$p'`. The fold-in (below) will need the same grep anchor, so pick the
section number and never renumber it silently.

**Remote-delegation pattern** (`check-music-freeze.sh:123-131`) — this is the analog for reaching
atlantis for `exportfs -v` and for reaching the NUC for `ha mounts info`:

```bash
ZFS_ROUTE="unavailable"
zfs_query() {
  if command -v zfs >/dev/null 2>&1; then
    zfs "$@"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${ZFS_HOST}" zfs "$@"
  fi
}
```

Two conventions carried by it: `-o BatchMode=yes -o ConnectTimeout=5` on every non-interactive ssh,
and a `*_ROUTE` variable recording *which* path was taken and printing it in the toolchain section
(`check-music-freeze.sh:173-182`). Do the same for the MA/HA reachability — "which route answered"
is exactly the ambiguity D-20 exists to remove.

**Toolchain preconditions** (`check-music-freeze.sh:158-183`) — section 0 asserts the binaries the
rest of the script needs before using them:

```bash
for t in ffprobe ffmpeg jq gzip sha256sum; do
  if command -v "$t" >/dev/null 2>&1; then
    ver="$("$t" --version 2>/dev/null | head -1 || true)"
    pass "$t $(command -v "$t") — ${ver:-version unknown}"
  else
    fail "$t NOT FOUND — CONS-04's completion test is written in ffprobe; a missing binary here is a harness failure, not a caller's local problem"
  fi
done
```

For this script the set is `curl jq ssh` (+ whatever the D-11 checksum uses). The "a missing binary
here is a harness failure, not a caller's local problem" framing is the estate's stance and should
be preserved.

**Absence-is-not-health** (`quick-health-check.sh:74-80`) — the rule the MA assertions must obey,
because an unreachable MA and a green MA must never look the same:

```bash
if [ -z "$MUSIC_OUT" ]; then
    # Unreachable host, or the script is not on the host at all. Absence of a failure signal is
    # NOT evidence of health — same precedent as scripts/check-server-health.sh:8-11.
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    EXIT_CODE=1
fi
```

**Where it runs — this is a real decision the planner must make, not a copied pattern.**
`check-music-freeze.sh` is **host-resident on LXC 100** and documents why
(`check-music-freeze.sh:5-12`):

```bash
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   It is host-resident rather than workstation-resident because `stat` over the library,
#   `find` across 1,200+ files and the docker mount enumeration cannot each be expressed as
#   one ssh'd command.
```

`check-music-consumers.sh` has no such forcing constraint — every one of its checks *is* a single
remote command — but it does have a credential problem pulling in two directions:

| Need | Lives on | Convention |
|---|---|---|
| `ssh root@172.16.1.158 'exportfs -v'` | either | `check-music-freeze.sh:129` already ssh's atlantis from LXC 100 |
| `ha mounts info` on the NUC | `HA_SSH_KEY`/`HA_SSH_PORT`/`HA_SSH_USER` in `~/.claude/secrets/ha-deercrest.env` | **workstation** — see § Shared Patterns |
| MA API token | `/mnt/fast/secrets/` on LXC 100 (**D-39**) | **LXC 100** |
| Jellyfin API key | `/mnt/fast/secrets/` on LXC 100 (**D-40**) | **LXC 100**; Jellyfin is at `192.168.90.31:8096`, a `t3_proxy` address reachable **only from LXC 100** (`01-06-SUMMARY.md:235-236`) |

The Jellyfin row is close to decisive: it publishes no host port and `localhost:8096` is refused, so
the D-42 Jellyfin half is naturally host-resident. That leaves the NUC SSH key, which today exists
only on the workstation. **State the resolution in the file header in the `# Where it runs:` form
above** — the two estate conventions are recorded in `01-PATTERNS.md:613-631` and mixing them inside
one file is what that section warns against.

---

### `scripts/quick-health-check.sh` (modified — D-41 fold-in, D-44 before/after)

**Analog:** itself, specifically the block 01-09 already added for `check-music-freeze.sh`
(`quick-health-check.sh:63-91`). "Fold the consumers check in" concretely means "append one more
block of this exact shape". Reproduced in full because every line of it is load-bearing:

```bash
# Music freeze harness (D-29). The audit is host-resident by design — stat over the library, a
# find across 2,674 entries and the docker mount enumeration are not one-liners — so it runs over
# a single ssh here. See scripts/check-music-freeze.sh for what it asserts.
echo -n "Music freeze harness: "
MUSIC_OUT=$(ssh -o BatchMode=yes -o ConnectTimeout=10 root@172.16.1.159 \
    "bash /mnt/fast/stacks/scripts/check-music-freeze.sh 2>&1")
MUSIC_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
# Strip ANSI colour separately. \x1b is a GNU sed extension and this script runs on macOS, so the
# ESC is spelled with bash's $'...' quoting instead.
MUSIC_OUT=$(printf '%s\n' "$MUSIC_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')

if [ -z "$MUSIC_OUT" ]; then
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    echo "  The harness state is unknown, NOT green. Check the host, then re-run:"
    echo "  ssh root@172.16.1.159 'cd /mnt/fast/stacks && bash scripts/check-music-freeze.sh'"
    EXIT_CODE=1
elif [ "$MUSIC_RC" -eq 0 ]; then
    echo "✅ Intact"
    echo "$MUSIC_OUT" | sed -n '/^📊 7\. Summary/,$p' | grep -E 'tagger-class|unclassified|declared rw|ownership mismatches' | sed 's/^/  /'
else
    echo "❌ BROKEN (check-music-freeze.sh exit $MUSIC_RC)"
    echo "  Failed assertions:"
    echo "$MUSIC_OUT" | grep '❌' | sed 's/^ */    /'
    echo "  Summary:"
    echo "$MUSIC_OUT" | sed -n '/^📊 7\. Summary/,$p' | sed 's/^/  /'
    EXIT_CODE=1
fi
```

Three traps this block already solved, all of which the new block inherits verbatim:
1. `MUSIC_RC=$?` is captured on the line **immediately after** the assignment and before any pipe.
2. ANSI stripping uses `$'\033'` because the script runs on **macOS** (BSD sed), not on the host.
3. Empty output is `UNKNOWN` + `EXIT_CODE=1`, never a silent pass.

**The file-level exit-code note** (`quick-health-check.sh:1-19`) — when the second fatal block is
added, this header must be extended, not left stale:

```bash
#!/bin/bash
# Quick diagnostic to check Traefik, container health and the music-library freeze harness.
#
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED 2026-08-18 (plan 01-09, D-29).
#     This script used to ALWAYS exit 0 — it printed ❌ for a down Traefik and carried on with no
#     other consequence. It now exits 1 when the music freeze harness fails or cannot be reached.
#     Stated here because other things may call this script and a silent-to-failing change is
#     exactly the kind of thing that should be visible in the file, not only in a plan.

EXIT_CODE=0
```

**Style rules specific to this file** (`01-PATTERNS.md:412-416`, still true): `#!/bin/bash` not
`env bash`, **no** `set -euo pipefail`, no colour variables, 4-space indent, `[ ]` not `[[ ]]`, and
one `ssh …` per command. Do not import `check-music-freeze.sh` style into it mid-file.

**D-44's before/after snapshot** needs no code — it is two invocations of this script with the
output captured. But note the ordering trap: if the consumers block is added *before* the export
exists, the "before" run is already red. Either add the block after the export is live, or run the
before-snapshot with the pre-existing script.

---

### `stacks/selfhosted/arrs/beets.md` (modified — D-47 operational record)

**Analog:** itself — `beets.md:189-408`, the Phase 1 section. This is a mature worked example of
exactly what D-47 asks for, written one phase ago.

**Section opener** (`beets.md:189-195`) — dated H2, what changed, and a pointer to where the
narrative lives so the doc stays a *record* rather than a retelling:

```markdown
## Phase 1 safety harness (2026-08-18)

The library was writable by ten containers, four tagging entry points and Lidarr's renamer, with
no before-state of the tags anywhere. Phase 1 closed that. This section records **what is true
now and why**; the narrative lives in
`.planning/phases/01-safety-harness-and-freeze-the-writers/01-0N-SUMMARY.md`.
```

**Value table with a Why column** (`beets.md:196-203`) — the shape for the export line, one row per
option:

```markdown
| | Value | Why |
|---|---|---|
| owner | **`568:568`** (`apps:apps`) | The estate service account, stated independently in `STANDARDS.md:141` … |
| directories | **`0755`** *(target — not achieved, see below)* | … |
```

**Committed transcript** (`beets.md:221-262`) — a fenced block, with the provenance line above it
stating host, timestamp and what was done to it:

```markdown
From `bash scripts/check-music-freeze.sh` on LXC 100, 2026-08-18T22:27:09Z, ANSI stripped,
otherwise unedited.
```

That sentence is the pattern for D-37's three proof lines. "ANSI stripped, otherwise unedited" is
the exact claim to make about a pasted transcript.

**"How to re-run" table** (`beets.md:357-371`) — the invocation surface, one row per command, and a
closing line about why it is folded into the health check:

```markdown
### How to re-run

Both scripts are host-resident and run from `/mnt/fast/stacks` on LXC 100 after a `git pull`.

| Command | Does |
|---|---|
| `bash scripts/check-music-freeze.sh` | audits all 8 sections; **exits 1** on any failed assertion. Read-only by contract |
| `bash scripts/check-music-freeze.sh --baseline` | same report, always exits 0 — for recording a before-state |

The audit also runs on every `scripts/quick-health-check.sh` from the workstation, which is the
path already in use — a harness nobody runs is the same failure as no harness.
```

**"Two traps that will mislead the next person"** (`beets.md:325-355`) — the record-the-misdiagnosis
habit. D-25 (Route B's evidence is different from Route A's) and D-20 (the NUC's source address)
are both trap-shaped and belong in this form. The section closes with the estate's own named
failure mode, which is worth re-reading before writing anything into this file:

> **Partial data stated as settled** is the failure mode of this estate. Verify with a second,
> independent instrument before you write it down.

**Runnable-command block with a warning comment** (`beets.md:398-403`) — the shape for the D-45
teardown and the D-35 simulated unmount:

```bash
# On the Proxmox host — NOT on LXC 100, where this fails EPERM on every entry
ssh root@172.16.1.158
zfs snapshot tank/media/TV@pre-chown
chown -R 568:568 /mnt/tank/media/TV
```

**One thing to correct while in the file:** `beets.md:215-217` already asserts what Phase 2
inherits ("`568:568` becomes the export's `anonuid`/`anongid`… the export must remain read-only").
The Phase 2 section should confirm that as *done*, not restate it as pending.

---

### `.planning/PROJECT.md` (modified — D-47 Key Decisions)

**Analog:** its own `## Key Decisions` table (`PROJECT.md:176-188`). Three columns. Note how the
Phase 1 rows differ from the original placeholder rows — a settled decision carries a dated
`Done YYYY-MM-DD (plan-id)` outcome plus a residual note, never `— Pending`:

```markdown
| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Library ownership normalised to `568:568`; modes stay `0777` | `568` is `apps`, the estate service account named independently in `STANDARDS.md:141` … `568:568` also sets the Phase 2 export's `anonuid`/`anongid`. The `0755`/`0644` target is **recorded but not achieved** — `chmod` fails `EPERM` on `tank` even as real root under `aclmode=restricted` | Done 2026-08-18 (01-08 ownership, 01-09 record). Mode half scoped out; export must stay `ro` |
| Jellyfin's Music metadata freeze is permanent | Once one tagger owns the tree, Jellyfin writing metadata into it is a second writer by another name. Nothing to remember to undo. Caveat measured, not assumed: the freeze gates the automatic path only — an explicit `FullRefresh` still writes | Done 2026-08-18 (01-06) |
```

Two habits to copy: the Rationale cell names its **independent corroborating sources with file:line**,
and it states the **measured limit** of the claim in the same cell. D-47's five Key Decisions (mount
route + loser's symptom, `folder_name` permanence, the export line and `mountpoint`, the
`172.16.1.31`-only choice) each become one row in this register.

**Also required by D-47 and easy to miss:** PROJECT.md's existing assertion that HA storage
configuration is the mount route must be *corrected*, not merely supplemented. It appears in the
CLAUDE.md-mirrored "Music Assistant on HAOS" material near `PROJECT.md` § Constraints /
§ Technology Stack; grep for `HAOS` and `Settings → System → Storage` before editing.

---

### `NETWORK.md` (modified — D-48)

**Analog:** two sections, and the planner should pick one deliberately.

**Host entry** (`NETWORK.md:48-66`) — bolded host name, then a bulleted IP/OS/SSH/role block:

```markdown
### Proxmox Cluster
**Host: atlantis** (Minisforum NS5Pro)
- **IP:** 172.16.1.158
- **Hardware:** Minisforum NS5Pro
- **OS:** Proxmox VE 9.1.6
- **SSH:** root@172.16.1.158
- **Containers:**
  - **LXC 100 "selfhost"** (172.16.1.159)
    - Role: Main Docker host for selfhosted services
```

**Host-level non-Docker services** (`NETWORK.md:205-229`) — the closer match, because `nfs-server`
on atlantis is exactly this class: a systemd unit holding a port that `docker ps` cannot see:

```markdown
### Host-level services on LXC 100 (NOT Docker, NOT in `stacks/`)

These run as **systemd services directly on the selfhost LXC**, so they do not appear in any
compose file and `docker ps` will not show them. They still consume host ports — check here before
assigning a new host port, or a container will fail to start.

**Pulse** — Proxmox/Docker monitoring (`/opt/pulse`, v6.2.1, installed 2026-03-10)

| Unit | Listens | Purpose |
|------|---------|---------|
| `pulse.service` | `*:7655` | Pulse server / web UI |
| `pulse-agent.service` | **`127.0.0.1:9191`** | agent health/metrics |
```

Followed by a `⚠️` paragraph naming the incident the entry exists to prevent, and a `>` blockquote
note. That is the register for "atlantis:2049 serving `/mnt/tank/media/Music` `ro` to
`172.16.1.31` only" plus the cross-link to `infra/nfs-music-export.tf` D-48 asks for.

**Cross-linking to source of truth** (`NETWORK.md:19`) — the credential-by-variable-name convention,
which is also the C-7 pattern:

```markdown
- **Credentials:** `UNIFI_USG_SSH_USER` / `UNIFI_USG_SSH_PASS` in `~/.claude/secrets/ha-deercrest.env` — **never in this repo** (public)
```

**Also worth updating while in the file:** `NETWORK.md:67-74` is the NUC entry, and it currently
says only "Docker not accessible via sysadmin account (runs HA Supervisor)". The Supervisor mount
and its `/media/music` user path belong there. A "Services by Host" line
(`NETWORK.md:231-236`) exists too and lists Home Assistant as "Core + addons" — Music Assistant is
not named anywhere in NETWORK.md today.

---

## Shared Patterns

### Estate service account — `568:568`
**Source:** `STANDARDS.md:139-142`; encoded as `var.apps_uid`/`var.apps_gid` in `infra/variables.tf:131-141`
**Apply to:** `infra/nfs-music-export.tf` (the `anonuid`/`anongid`), the audit script's constants

```markdown
### Volume Mounting
- **Base Path**: `/mnt/fast/appdata/{stack}/{component}`
- **User/Group**: 568:568 (apps:apps on TrueNAS SCALE)
```

Never write the literal `568` into `.tf`; use `${var.apps_uid}` / `${var.apps_gid}` as
`host.tf:67-70`, `lxc-mpe.tf:22` and `lxc-selfhost.tf:47` all do. In bash, the constant is
`UIDGID="568:568"` (`check-music-freeze.sh:75`, `freeze-music-apply.sh`, `setup-mpe.sh:13`).

### Secrets — by variable name only, never in the repo
**Source:** `NETWORK.md:19`, `TAILSCALE.md:317`, `stacks/selfhosted/postiz/README.md:22`,
`~/.claude/skills/ha-deercrest/SKILL.md:26-28`, CLAUDE.md C-7, MEMORY.md `gateway-password-exposed-rotate`
**Apply to:** the audit script, `beets.md`, `NETWORK.md`, every plan file

Two stores exist and this phase touches both:

```bash
# Workstation store — the ha-deercrest skill's convention (SKILL.md:66-68, 91-93)
source ~/.claude/secrets/ha-deercrest.env
TOKEN=$(cat $HA_TOKEN_FILE)
SSH="ssh -i $HA_SSH_KEY -o StrictHostKeyChecking=no -o BatchMode=yes -p $HA_SSH_PORT $HA_SSH_USER@$HA_SSH_HOST"
```

```
# Estate store — Phase 3 D-04 / this phase D-39, D-40
/mnt/fast/secrets/<name>.env on LXC 100, mode 0600, root-owned, written via stdin
```

`~/.claude/secrets/` currently holds `ha-deercrest.env`, `ha-deercrest.token`, `postiz.env` — there
is **no `ma-deercrest.env`**. RESEARCH.md (`02-RESEARCH.md:1394-1399`, `:600`) and
`02-VALIDATION.md:76` assume the workstation store; **CONTEXT D-39/D-40 decide `/mnt/fast/secrets/`
on LXC 100**. CONTEXT wins on the MA token and the Jellyfin key. The NUC SSH key is a third thing —
it is not a token, it is `HA_SSH_KEY` on the workstation — and the planner must say explicitly
whether it is replicated to LXC 100 or whether the NUC-side checks run from the workstation. This
is the single unresolved cross-cutting decision in the phase.

The repo is **public** (`MEMORY.md gateway-password-exposed-rotate`): a value committed here is
recoverable by `git log -S` even after redaction. Reference by variable name, always.

### Driving HAOS non-interactively — the `bash -lc` wrapper
**Source:** `~/.claude/skills/ha-deercrest/SKILL.md:101-122`
**Apply to:** every `ha` invocation in the audit script and in every plan step (D-22)

```bash
SSH="ssh -i ~/.ssh/id_ed25519 -o BatchMode=yes sysadmin@172.16.1.31"

$SSH "bash -lc 'ha core info'"          # ✅ works
$SSH "ha core info"                     # ❌ unauthorized
$SSH -tt "ha core info"                 # ❌ unauthorized (a PTY is NOT enough)
# zsh -lc prints the MOTD banner first — use bash -lc for parseable output

$SSH "bash -lc 'ha apps --raw-json'"    # add-on inventory ('addons' is deprecated)
```

Requires **protection mode OFF** on the Advanced SSH & Web Terminal add-on (Info tab → ⋮),
confirmed 2026-07-27 — which is exactly what D-22 re-verifies at Stage 0. `ha addons` is
deprecated in favour of `ha apps`; D-21's version probe must use `ha apps --raw-json`.

**Tailnet caveat that will bite the reboot test** (`SKILL.md:18-24`): while HA is the *standby*
subnet router, its LAN IP `172.16.1.31` is unreachable **from the tailnet** — the reply egresses
`tailscale0` with a source outside the peer's AllowedIPs. LAN clients are unaffected. So the audit
script must run from the LAN (workstation on-LAN, or LXC 100), or use `100.73.196.51`. This is the
same topology fact D-20 makes measurable.

### Non-interactive SSH flags
**Source:** `check-music-freeze.sh:129`, `quick-health-check.sh:67`, `check-server-health.sh:8`
**Apply to:** every remote call in the new script

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${ZFS_HOST}" zfs "$@"
ssh -o BatchMode=yes -o ConnectTimeout=10 root@172.16.1.159 "bash /mnt/fast/stacks/scripts/check-music-freeze.sh 2>&1"
```

`BatchMode=yes` is what turns a missing key into a fast failure instead of a password prompt that
hangs a health check.

### File mode of scripts
**Source:** `ls -l scripts/`

`check-music-freeze.sh`, `freeze-music-apply.sh`, `snapshot-music-tags.sh`, `diff-music-tags.sh`,
`check-renovate.sh`, `setup-mpe.sh` are `0755`. `quick-health-check.sh`, `setup-teleport.sh`,
`sync-repo.sh` are `0644` and invoked as `bash scripts/<name>.sh`. New scripts are `0755` with the
exec bit committed — the `0644` files are drift, not a convention.

### Terraform variable/state hygiene
**Source:** `infra/providers.tf:7-20`, `infra/.gitignore`, `infra/terraform.tfvars`

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = { source = "bpg/proxmox", version = "~> 0.95" }
    null    = { source = "hashicorp/null", version = "~> 3.2" }
  }
}
```

No new provider is needed — `hashicorp/null` is already declared. **`infra/terraform.tfstate` is
committed to this public repo** (`ls infra/` shows `terraform.tfstate`, `.backup`, and a dated
`.backup`). Nothing this phase adds may put a secret in state: `local.music_export_file` contains
only IPs and uids, which is fine; a token or password interpolated into a `null_resource` trigger
would be written to a public file. Secrets go in `terraform.tfvars` (gitignored) and are declared
`sensitive = true` (`variables.tf:21-25`, `33-37`, `109-113`).

---

## No Analog Found

| File / mechanism | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `triggers = { … }` on a `null_resource` | terraform | — | **`grep -rn 'triggers' infra/*.tf` returns nothing.** No resource in `infra/` has ever used one. Worse, this is not neutral: `host.tf`'s `null_resource.host_setup` has *no* `triggers`, so it never re-runs even when its inline script changes. RESEARCH.md (`02-RESEARCH.md:1162`) names this trap explicitly — copying `host.tf` wholesale would make the export unresponsive to edits, and D-14's "a re-apply is clean" unmeasurable. New work; state it as such and explain what `triggers` buys. |
| `provisioner "file"` | terraform | file-I/O | **Zero occurrences in `infra/`.** Every existing provisioner is `remote-exec`. Writing `/etc/exports.d/music.exports` as a whole file (`02-RESEARCH.md:1113-1116`, `:1299`) is a new mechanism for this repo. The existing repo idiom is `printf … > /path` inside `remote-exec` (see the M2 drop-in at `02-RESEARCH.md:1126`) — the planner should pick one and use it consistently, noting that `provisioner "file"` with `content =` is the idempotent-by-construction choice while `printf`-in-`remote-exec` matches the file's neighbours. |
| Conditional resource for the D-15 temporary export | terraform | — | **No `count = var.x ? 1 : 0` and no `for_each` anywhere in `infra/`.** Every `*_count` hit in `infra/` is an idmap range local, not a meta-argument. Also no `type = bool` variable exists. D-15's "Terraform-managed, behind an enable variable defaulting to off" is entirely new structure. |
| MA JSON-RPC calls (`music/sync`, `music/albums/library_items`, `config/providers/get`) | API client | request-response | Nothing in this repo calls any HTTP API. `check-renovate.sh` and `check-music-freeze.sh` shell out locally; `quick-health-check.sh:57` does exactly one `curl -s -o /dev/null -w '%{http_code}'` against a local dashboard and that is the extent of it. Build from `02-RESEARCH.md:1382-1421`'s `api()` helper — it is the only worked example and it was written from upstream source. |
| Jellyfin API calls (D-40, D-42) | API client | request-response | Same — no committed code. The only record is prose in `01-06-SUMMARY.md:233-300`: Jellyfin **10.11.11**, reachable from LXC 100 at **`192.168.90.31:8096`** (`t3_proxy` network; it publishes no host port and `localhost:8096` is refused), settings applied via `POST /Library/VirtualFolders/LibraryOptions` → HTTP 204. The `ApiKeys` table already holds 4 unattributable admin rows, which is exactly why D-40 mints a new purpose-named key. |
| HA automation / `rest_command` / notification YAML (M4 D-33, D-34, D-54) | automation | event-driven | **No Home Assistant configuration exists in this repo at all** — `grep -rl 'rest_command\|automation:' --include='*.yaml'` matches only three unrelated compose files. This lives at `/config/` on the NUC and is off-repo by nature. There is no in-repo file to pattern-match against and no place to commit it; the plan must say where the record of it goes (D-47 says `beets.md`). |
| `pilot-albums.txt` in the phase directory | test fixture | data | **Phase 1 committed zero non-`.md` artifacts under `.planning/`** (`git ls-files .planning/` → only `.md` plus `config.json`). Evidence was embedded as fenced blocks inside `SUMMARY.md` and `beets.md`. Note the upstream conflict: **CONTEXT D-09 says the three albums are "pinned in `scripts/check-music-consumers.sh`"**, while RESEARCH.md (`:1419`) and `02-VALIDATION.md:76` read them from an external `pilot-albums.txt`. D-09 is the decision and also the estate-consistent choice — pin them in the script, keyed on the QUAL-01 `audio_md5`. |
| The D-11 read-through checksum | verification | streaming | No checksum-over-a-mount comparison exists in the repo. `check-music-freeze.sh:162` asserts `sha256sum` is present as a toolchain precondition, and `01-06-SUMMARY.md` used sha256 content hashes for the sidecar watch — so `sha256sum` is the estate's hash and the tooling is known present on LXC 100. Whether it exists on the **HAOS busybox** side is unmeasured (research A13) and Stage 0 must check it. |
| `showmount`, `exportfs`, `findmnt` parsing | audit logic | request-response | New. The closest existing shape is `check-music-freeze.sh:259-276`'s "grep, then split on a chosen delimiter, then classify into named buckets" loop — reuse the *structure* (a `while IFS='|' read` over a rows variable, with a `count_lines` helper at `:221`), not the query. |

---

## Metadata

**Analog search scope:** `infra/` (all `.tf`), `scripts/` (all), `stacks/selfhosted/arrs/`,
`NETWORK.md`, `STANDARDS.md`, `CLAUDE.md`, `.planning/PROJECT.md`,
`.planning/phases/01-*/01-PATTERNS.md` + `01-06-SUMMARY.md`,
`~/.claude/skills/ha-deercrest/SKILL.md`, `~/.claude/secrets/` (listing only)
**Files scanned:** 14 read in full or targeted ranges; ~40 matched by grep/glob
**Prior pattern map reused:** `.planning/phases/01-safety-harness-and-freeze-the-writers/01-PATTERNS.md`
(§ scripts, § shared patterns) — not re-derived
**Pattern extraction date:** 2026-08-29
