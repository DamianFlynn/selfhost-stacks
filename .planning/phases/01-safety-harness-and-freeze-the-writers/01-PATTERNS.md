# Phase 1: Safety Harness and Freeze the Writers - Pattern Map

**Mapped:** 2026-08-17
**Files analyzed:** 19 (14 modified, 5 created)
**Analogs found:** 15 / 19

> This is a Docker Compose + shell + ZFS repository. There is no application code, no test
> framework, no Python anywhere in the tree (`find . -name "*.py"` returns zero results). The
> patterns that matter are: compose service-file volume blocks, service-file header comment
> blocks, `scripts/setup-*.sh` / `scripts/check-*.sh` bash conventions, and `.md`-beside-the-stack
> documentation. Four files in this phase have **no analog at all** and are called out in
> § "No Analog Found" — the planner should not invent one.

---

## File Classification

### Compose service files (modified)

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `stacks/selfhosted/arrs/radarr.yaml` | compose-service | file-I/O (mount narrowing) | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/arrs/sonarr.yaml` | compose-service | file-I/O | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/arrs/readarr.yaml` | compose-service | file-I/O | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/arrs/bazarr.yaml` | compose-service | file-I/O | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/arrs/janitorr.yaml` | compose-service | file-I/O | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/arrs/prowlarr.yaml` | compose-service | file-I/O (mount **deleted**) | none needed — line deletion | n/a |
| `stacks/selfhosted/arrs/lidarr.yaml` | compose-service | file-I/O (rw → ro) | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/arrs/beets/beets.yaml` | compose-service | file-I/O | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/arrs/soulbeet.yaml` | compose-service | file-I/O (discretionary) | `stacks/selfhosted/media/seerr.yaml:42` | exact |
| `stacks/selfhosted/music/wrtag.yaml` | compose-service | file-I/O + lifecycle gate | `stacks/selfhosted/arrs/beets/beets.yaml:10-11` | exact |
| `stacks/selfhosted/media/jellyfin.yaml` | compose-service | documentation-only change | `stacks/selfhosted/arrs/sabnzbd.yaml:43-55` | exact |

### Scripts

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `scripts/freeze-music-writers.sh` (new) | apply script | batch / idempotent mutate | `scripts/setup-mpe.sh` | role-match |
| `scripts/check-music-freeze.sh` (new) | verify script | batch / read-only audit | `scripts/check-renovate.sh` | role-match |
| `scripts/quick-health-check.sh` (modified) | health check | request-response over ssh | itself — append-block shape | exact |
| `scripts/snapshot-music-tags.sh` (new) | data-capture tool | streaming / file-I/O | `scripts/pg-migrate.sh` (function shape only) | partial |
| `scripts/diff-music-tags.sh` (new) | comparison tool | transform | **none** | none |

### Vendored config

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` (new) | vendored container config | config | `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` + `sabnzbd.yaml:43-55` | role-match |

### Documentation

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `stacks/selfhosted/arrs/beets.md` (modified) | stack doc | doc | itself + `stacks/selfhosted/media/dispatcharr.md` | exact |
| `.planning/PROJECT.md` (modified) | project doc | doc | its own `## Key Decisions` table | exact |

---

## Pattern Assignments

### Compose mount narrowing — `radarr.yaml`, `sonarr.yaml`, `readarr.yaml`, `bazarr.yaml`, `janitorr.yaml`, `lidarr.yaml`, `beets/beets.yaml`, `soulbeet.yaml`

**Analog:** `stacks/selfhosted/media/seerr.yaml` — the one file already correct.

**Volume-block pattern** (`seerr.yaml:40-42`):

```yaml
    volumes:
      - /mnt/fast/appdata/media/seerr/config:/app/config:rw  # Application config and database
      - /mnt/tank/media:/data:ro  # Read-only access to media library for availability checks
```

Two rules the analog fixes: **every volume line carries an explicit `:rw` or `:ro` suffix**, and
**every volume line carries a trailing `#` comment stating what it is for**. The whole estate does
this; the only volume in the arrs stack missing a suffix is jellyfin's (`jellyfin.yaml:93`), which
is precisely why it is rw by accident.

**Current shape to edit** — all six arrs files are byte-identical in this region except the
trailing comment. `radarr.yaml:39-43`:

```yaml
    volumes:
      - /etc/localtime:/etc/localtime:ro  # System timezone
      - /mnt/fast/appdata/arrs/radarr/config:/config:rw  # Application config and database
      - /mnt/tank/downloads:/downloads:rw  # Download client output directory
      - /mnt/tank/media:/media:rw  # Movie library destination
```

The D-19 edit changes the host side only, leaving the container-internal path prefix intact so no
arr needs reconfiguring:

| File | Line | Current host:container | D-19 target |
|---|---|---|---|
| `radarr.yaml` | 43 | `/mnt/tank/media:/media:rw` | `/mnt/tank/media/Movies:/media/Movies:rw` |
| `sonarr.yaml` | 44 | `/mnt/tank/media:/media:rw` | `/mnt/tank/media/TV:/media/TV:rw` |
| `readarr.yaml` | 43 | `/mnt/tank/media:/media:rw` | `/mnt/tank/media/Books:/media/Books:rw` |
| `bazarr.yaml` | 39 | `/mnt/tank/media:/media:rw` | two lines — `Movies` and `TV` subtrees |
| `janitorr.yaml` | 43 | `/mnt/tank/media:/data:rw` | subtree lines under `/data/…` |
| `prowlarr.yaml` | 42 | `/mnt/tank/media:/media:rw` | **line deleted** (D-19) |
| `lidarr.yaml` | 43 | `/mnt/tank/media:/media:rw` | `/mnt/tank/media:/media:ro` (D-25 — kept broad, made ro) |
| `beets/beets.yaml` | 19 | `/mnt/tank/media:/media:rw` | ro or narrowed (D-20: nobody holds rw in P1–3) |
| `soulbeet.yaml` | 37 | `/mnt/tank/media/Music:/music` | discretionary — no suffix today, so rw |

Note the D-19 targets are the *host-side directory names on `tank`*, which have not been verified
in this repo. The planner must have the apply/verify script confirm the real directory names under
`/mnt/tank/media` before hard-coding `Movies`/`TV`/`Books` — a typo silently creates an empty bind
mount rather than erroring.

**`janitorr.yaml` is the odd one out** — it also bind-mounts a single *file* rw
(`janitorr.yaml:41`, `application.yml:/workspace/application.yml:rw`), which is the same
file-level bind-mount mechanism D-28 needs. Reuse that shape:

```yaml
    volumes:
      - /mnt/fast/appdata/media/janitorr/application.yml:/workspace/application.yml:rw  # Main configuration file
      - /mnt/fast/appdata/media/janitorr/logs:/logs:rw  # Application logs
      - /mnt/tank/media:/data:rw  # Media library for cleanup operations
```

---

### `stacks/selfhosted/music/wrtag.yaml` (compose-service, lifecycle gate)

**Analog:** `stacks/selfhosted/arrs/beets/beets.yaml` — the estate's only example of a
manually-invoked, non-daemon container.

**Lifecycle-gate pattern** (`beets/beets.yaml:10-11`):

```yaml
    restart: "no"  # Don't run 24/7, start manually or via cron
    profiles: ["manual"]  # Exclude from 'docker compose up'
```

Both keys carry an inline comment explaining the effect. Copy this verbatim into `wrtag.yaml`,
replacing `restart: unless-stopped` at `wrtag.yaml:29`.

**Mount to delete** (`wrtag.yaml:34-40`) — remove line 40 only; lines 36 and 38 stay:

```yaml
    volumes:
      # Database and job queue
      - /mnt/fast/appdata/media/wrtag/data:/data
      # Source music (unsorted downloads)
      - /mnt/tank/downloads/complete/nzb/unsorted:/music/source
      # Destination organized library
      - /mnt/tank/media/Music:/music/library     # <-- DELETE this line and its comment (WRIT-02 / D-22)
```

Note this file uses **comment-above-the-line** rather than the trailing-comment style used across
`arrs/`. Keep whichever style the file already uses; do not restyle it in this phase.

Invocation for the manual container is documented in prose, not in the compose file
(`beets.md:66-69`):

```bash
docker compose -f arrs/beets.yaml --profile manual up beets
docker exec -it beets beet import "/downloads/complete/nzb/unsorted/<album folder>"
```

**Live gotcha the planner must account for:** `beets.yaml` is **commented out** of the arrs
include list (`arrs/compose.yaml:39` — `#  - beets.yaml`, and the path is wrong anyway; the file
is at `arrs/beets/beets.yaml`). `soulbeet.yaml` is likewise commented out at line 36. So neither
is in the compose graph today, and the WRIT-01 *running-container* audit will not see them
regardless of what their YAML declares. The audit therefore has to read the declared mounts too,
or it reports a false pass.

---

### `stacks/selfhosted/media/jellyfin.yaml` (documented exception — D-21)

**Analog:** `stacks/selfhosted/arrs/sabnzbd.yaml:43-55` — the estate's established way of
recording a load-bearing "why this is like this" carve-out directly beside the volume it governs.

```yaml
    volumes:
      - /mnt/fast/appdata/arrs/sabnzbd/config:/config:rw  # Application config, queue, and history database
      # Init scripts. NOTE (2026-07-31): arr-scripts/scripts_init.bash is a VENDORED copy of
      # RandomNinjaAtk/arr-scripts sabnzbd/setup.bash v3.2, with the blocks that download and
      # overwrite /config/scripts/{video,audio,audiobook}.bash removed. It no longer does
      # `curl <upstream> | bash` on every container start.
      #
      # Why: SABnzbd 5.0 runs post-processing scripts for FAILED jobs too (empty_postproc was
      # removed upstream), and arr-scripts has no job-status check. Those three scripts now carry
      # a local SAB_PP_STATUS guard, and are only durable because setup no longer re-downloads
      # them. Restoring the stock setup.bash silently reverts the guard and lets failed
      # downloads be post-processed into the library.
      #
      # The scripts live in /config/scripts (persistent) -- see each file's header for provenance.
      - /mnt/fast/appdata/arrs/sabnzbd/arr-scripts:/custom-cont-init.d  # Post-processing scripts (vendored, see above)
```

The conventions to copy: dated `NOTE (YYYY-MM-DD):` prefix, a **Why:** paragraph, an explicit
statement of what breaks if someone reverts it, and a trailing one-line comment on the volume
itself pointing back up at the block.

**Target region** (`jellyfin.yaml:90-95`):

```yaml
    volumes:
      - /etc/localtime:/etc/localtime:ro  # System timezone for scheduling
      - /mnt/fast/appdata/media/jellyfin:/config:rw  # Application config, metadata, and database
      - /mnt/tank/media:/media  # Media library (movies, TV, music, photos)
      # Transcode to RAM for better performance and reduced disk wear
      - /dev/shm:/data/transcode  # RAM disk for temporary transcoding files
```

Line 93 is the only volume in this file with no `:rw`/`:ro` suffix. D-21 keeps it rw, so the edit
is the NOTE block plus making the suffix explicit (`:rw`) so a future reader cannot mistake it for
an oversight — which is exactly what it looks like today.

---

### `scripts/freeze-music-writers.sh` (new — apply script, D-27)

**Analog:** `scripts/setup-mpe.sh` — the estate's cleanest idempotent host-side apply script.

**Header + strictness + path-resolution pattern** (`setup-mpe.sh:1-13`):

```bash
#!/usr/bin/env bash
# setup-mpe.sh — host-side prep for the MPE stack (run inside LXC 102 "mpe").
#
# Creates the appdata directory tree under the dedicated dataset and scaffolds
# .env files from samples with freshly generated secrets. Idempotent: existing
# .env files are never overwritten.
#
# Run from the repo root on the host: bash scripts/setup-mpe.sh
set -euo pipefail

APPDATA="/mnt/fast/appdata/mpe"
STACKS="$(cd "$(dirname "$0")/.." && pwd)/stacks/mpe"
UIDGID="568:568"
```

Conventions: `#!/usr/bin/env bash` (not `#!/bin/bash` — that is the older
`check-server-health.sh`/`quick-health-check.sh` style), a `script-name.sh — one-line purpose`
comment, an explicit statement of **where it runs**, an explicit **Idempotent:** sentence, then
`set -euo pipefail`, then ALL-CAPS constants at the top. `UIDGID="568:568"` is already the exact
constant D-11 decides on.

**Idempotency-guard pattern** (`setup-mpe.sh:32-40`) — the "check, report, skip" shape:

```bash
seed_env() { # $1=stack dir
  local d="$1"
  if [[ -f "${d}/.env" ]]; then
    echo "    ${d}/.env exists — leaving untouched"
  else
    cp "${d}/.env.sample" "${d}/.env"
    echo "    created ${d}/.env from sample"
  fi
}
```

**Progress-output pattern:** `echo "==> Doing thing..."` at each stage, four-space-indented
sub-lines for per-item results. Used consistently across `setup-mpe.sh` and
`setup-mpe-cloudflare.sh`.

**Ownership normalisation (WRIT-04 / D-13)** — the literal line to model on, `setup-mpe.sh:26-27`:

```bash
echo "==> Setting ownership ${UIDGID}..."
chown -R "${UIDGID}" "${APPDATA}"
```

**Required-env / precondition guards** (`setup-mpe-cloudflare.sh:26-32`):

```bash
: "${CF_API_TOKEN:?set CF_API_TOKEN}"
: "${CF_ACCOUNT_ID:?set CF_ACCOUNT_ID}"
CF_DNS_API_TOKEN="${CF_DNS_API_TOKEN:-$CF_API_TOKEN}"
TUNNEL_NAME="${TUNNEL_NAME:-mpe}"
```

**Destructive-operation warning** (`setup-mpe-cloudflare.sh:22-23`) — the precedent for a script
that takes ZFS snapshots and chowns 1,244 files:

```bash
# ⚠️  This script CREATES live Cloudflare resources. Review, then run deliberately.
# Idempotent: re-running reuses an existing tunnel of the same name.
```

**Where it runs:** on LXC 100 (`root@172.16.1.159`), from `/mnt/fast/stacks`. `zfs snapshot`,
`chown` and `chmod` on `/mnt/tank` cannot be done via per-command ssh the way
`quick-health-check.sh` does it. Follow `setup-mpe.sh` and `pg-migrate.sh`, both of which are
host-resident scripts run as `bash scripts/<name>.sh` after a `git pull`. `pg-migrate.sh:8-14`
documents that workflow explicitly:

```bash
# Workflow:
#   git pull                              # compose files now reference PG18
#   bash scripts/pg-migrate.sh all       # migrates data for each instance
#   docker compose up -d                  # everything starts on PG18
```

---

### `scripts/check-music-freeze.sh` (new — verify script, D-27)

**Analog:** `scripts/check-renovate.sh` — the estate's most developed read-only audit script.

**Header + repo-root anchoring** (`check-renovate.sh:1-8`):

```bash
#!/usr/bin/env bash
# check-renovate.sh - Validate Renovate configuration and coverage
# Usage: ./scripts/check-renovate.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
```

**Colour helpers** (`check-renovate.sh:14-19`) — copy verbatim, this is the estate's palette:

```bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
```

**Numbered-section pattern** (`check-renovate.sh:30-37`) — each check is `# N. Description`, an
emoji heading, a box-drawing rule, then the finding:

```bash
# 1. Check all compose.yaml files are tracked
echo "📋 Checking compose.yaml coverage..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

COMPOSE_FILES=$(find stacks/selfhosted -name "compose.yaml" | sort)
COMPOSE_COUNT=$(echo "$COMPOSE_FILES" | wc -l | tr -d ' ')

echo -e "${BLUE}Found $COMPOSE_COUNT compose.yaml files:${NC}"
```

**Pass/warn branch** (`check-renovate.sh:72-85`) — the exact shape D-21's "tagger-class: 0;
consumer-class: Jellyfin (documented exception)" report should take:

```bash
if [[ $POSTGRES_COUNT -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  Found $POSTGRES_COUNT PostgreSQL images:${NC}"
  ...
  echo -e "${YELLOW}⚠️  PostgreSQL major version updates are DISABLED in renovate.json${NC}"
  echo "   Manual migration required: pg_dump → restore → test"
else
  echo -e "${GREEN}✅ No PostgreSQL instances found${NC}"
fi
echo ""
```

**Summary block** (`check-renovate.sh:141-150`) — every audit ends with a counts table:

```bash
# 7. Summary
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Compose files:      $COMPOSE_COUNT"
echo "  Files with images:  $IMAGE_FILE_COUNT"
echo "  Unique images:      $IMAGE_COUNT"
```

**Exit-code convention — this is a real gap, and the planner must decide it explicitly.**
`check-renovate.sh` exits `1` only on a missing `renovate.json` (line 22-25); every other finding
is printed and the script still exits `0`. `check-server-health.sh:8-11` exits `1` on
unreachable-host and `0` otherwise. `quick-health-check.sh` never exits non-zero at all. So the
estate has **no** convention for "a check failed → non-zero". Since D-29 folds this into
`quick-health-check.sh`, and the whole point of D-29 is that the docker `created`-state blind spot
left two containers down for six weeks under a green check, the planner should establish
`exit 1` on any failed assertion here and say so, rather than inherit the silence.

---

### `scripts/quick-health-check.sh` (modified — D-29 extension point)

**Analog:** itself. There is **no function registry and no check-registration mechanism** — the
file is a flat 45-line sequence of top-level blocks. "Fold the verify script in" concretely means
"append one more block in this exact shape".

**The block shape to append** (`quick-health-check.sh:6-15`):

```bash
# Check Traefik is running
echo -n "Traefik: "
if ssh root@172.16.1.159 "docker ps --format '{{.Names}}' | grep -q '^traefik$'"; then
    echo "✅ Running"
    # Check if it's healthy
    STATUS=$(ssh root@172.16.1.159 "docker inspect traefik --format='{{.State.Health.Status}}' 2>/dev/null || echo 'no healthcheck'")
    echo "  Health: $STATUS"
else
    echo "❌ Not running"
fi
```

**The count-then-branch shape** (`quick-health-check.sh:29-36`) — the closest match to the WRIT-01
mount audit, which is "count rw holders on Music; if > expected, list them":

```bash
# Check for unhealthy
UNHEALTHY=$(ssh root@172.16.1.159 "docker ps --format '{{.Names}}' --filter health=unhealthy | wc -l" | tr -d ' ')
if [ "$UNHEALTHY" -gt 0 ]; then
    echo "⚠️  Unhealthy containers: $UNHEALTHY"
    ssh root@172.16.1.159 "docker ps --format '{{.Names}}' --filter health=unhealthy"
else
    echo "✅ No unhealthy containers"
fi
```

Note the conventions this file carries that differ from `check-renovate.sh`: `#!/bin/bash` (not
`env bash`), **no** `set -euo pipefail`, **no** colour variables (bare emoji), 4-space indent,
`[ ]` not `[[ ]]`, and one `ssh root@172.16.1.159 "…"` per command — the script runs from the
workstation, not on the host. Match the file you are editing; do not introduce `check-renovate.sh`
style into it mid-file.

`docker inspect` mount enumeration for the WRIT-01 audit has no analog in the repo. The relevant
Go-template surface is `{{range .Mounts}}{{.Source}}:{{.Destination}}:{{if .RW}}rw{{else}}ro{{end}}{{"\n"}}{{end}}`;
state it as new work in the plan rather than as a pattern being copied.

---

### `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` (new — vendored config, D-28)

**Analog:** `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` (the repo-side copy) plus
`stacks/selfhosted/arrs/soulbeet.yaml:38-39` (the mount).

**Important correction to the CONTEXT's framing of the "proven pattern".** D-28 says the SABnzbd
config is "vendored into the repo and bind-mounted". The SABnzbd `scripts_init.bash` precedent
does **not** work that way — it is not in git at all. `sabnzbd.yaml:55` mounts
`/mnt/fast/appdata/arrs/sabnzbd/arr-scripts:/custom-cont-init.d`, i.e. the vendored copy lives in
appdata on the host and the *repo* carries only the provenance comment block. The soulbeet case is
the closer analog and it is a hybrid: a repo copy at `soulbeet/beets_config.yaml` for review and
history, with the compose mount pointing at the appdata copy.

**Mount pattern** (`soulbeet.yaml:34-39`):

```yaml
    volumes:
      - /mnt/fast/appdata/arrs/soulbeet/data:/data  # Database and app data
      - /mnt/tank/downloads:/downloads              # Download folder (shared with slskd)
      - /mnt/tank/media/Music:/music                # Music library destination
      # Custom beets config for existing library integration
      - /mnt/fast/appdata/arrs/soulbeet/beets_config.yaml:/app/beets_config.yaml
```

**Content pattern** (`soulbeet/beets_config.yaml:1-4, 18-40`) — commented-section beets config,
inline `#` rationale on each tunable. This is also the file whose `auto: yes` settings D-28's new
file must invert:

```yaml
# Beets Configuration for Soulbeet
# Custom configuration for music library management

directory: /music
library: /data/beets_library.db
...
# Plugins
plugins:
  - fetchart      # Download album art
  - embedart      # Embed art in files
  - lastgenre     # Fetch genres from Last.fm
  - scrub         # Clean tags
...
embedart:
  auto: yes

lastgenre:
  auto: yes
  source: album
```

The planner should note: the D-28 target file (`/config/scripts/beets-config.yaml` on LXC 100)
declares `plugins: embedart` and nothing else — it is *not* this file, and it is much smaller.
Both files need the `scrub.auto: no` / `lastgenre.auto: no` / `embedart.auto: no` treatment, and
this soulbeet one shows all three currently set the wrong way.

**Provenance comment to attach to the new mount:** use the `sabnzbd.yaml:43-55` NOTE-block shape
quoted under the jellyfin section above — dated, with a **Why:**, and an explicit "what reverting
this breaks".

---

### `stacks/selfhosted/arrs/beets.md` (modified — D-30, D-14)

**Analog:** itself, and `stacks/selfhosted/media/dispatcharr.md` for the mature version of the
same form. Both are 160–195 lines.

**Document opening** (`beets.md:1-12`) — H1, a "Companion to" line linking the compose files it
documents, an explicit "nothing here is applied by docker compose" disclaimer, and a dated state
line:

```markdown
# Beets: library state and the bulk-import backlog

Companion to [`beets/beets.yaml`](beets/beets.yaml) (manual container) and
[`soulbeet.yaml`](soulbeet.yaml) + [`soulbeet/beets_config.yaml`](soulbeet/beets_config.yaml)
(automated Soulseek → beets path).

Nothing here is applied by `docker compose`. This is the record of what the music library
currently looks like, why the tagging pipeline stalled, and how to work the backlog.

State as of 2026-08-17.

---
```

**Existing section structure** (`beets.md`) — H2 sections separated by `---`, each opening with a
short prose paragraph then a table or a fenced block:

```
##  Two beets, one library         (l.14)  — comparison table
##  Current numbers                (l.38)  — census table + bolded headline
##  Why it stalled                 (l.58)  — prose + bash block
##  Two config gaps…               (l.73)  — H3 subsections, each with a yaml block
##  Suggested triage               (l.129) — bucket table + "### Before any bulk run"
##  Gotchas found the hard way     (l.153) — bulleted, bolded lead, cause then fix
```

`dispatcharr.md` proves the mature form: it adds a bolded state-line with live counts
(`State as of 2026-08-16: **139 channels, 319 stream links, ~21,800 programmes.**`) and a section
titled with its own warning — `## Linking a channel to its guide — this is the sharp edge`. It
also demonstrates the "record the misdiagnosis, not just the fix" habit, which D-30's mount audit
output and Jellyfin exception both need.

**Gotchas-section pattern** (`beets.md:155-159`) — bolded claim, mechanism, then the fix. **This
is also the exact text D-14 must correct** — the `chown -R 568:545` at line 159:

```markdown
- **`rsync -a` fails writing to `tank`** with `mkstemp ... Operation not permitted` on every
  file — while printing a stats block that looks like success (it reports bytes *sent*, not
  written; zero files land, exit code 23). Cause: `acltype=nfsv4` + `aclmode=restricted` reject
  rsync replicating source mode/ownership. Use `rsync -rlt --no-p --no-o --no-g`, then
  `chown -R 568:545` to match the Music library convention.
```

`568:545` appears exactly once in this file, at `beets.md:159`. It appears nowhere else in the
repo — `grep -n "568:" stacks/selfhosted/arrs/beets.md` returns only this line. The correction is
a single-token edit to `568:568`, and per D-30 should be accompanied by a note saying what the
value was and why it was wrong, in the same "record the misdiagnosis" style dispatcharr.md uses.

**Also correct while in the file:** `beets.md:22` states beets runs `restart: "no"`,
`profiles: ["manual"]` and `beets.md:67` gives the invocation as
`docker compose -f arrs/beets.yaml --profile manual up beets`. That path is wrong — the file is at
`arrs/beets/beets.yaml`, and it is commented out of `arrs/compose.yaml:39`.

---

### `.planning/PROJECT.md` (modified — D-17, D-11 Key Decisions)

**Analog:** its own `## Key Decisions` table (`PROJECT.md:148-157`). Three columns, `— Pending`
as the placeholder outcome:

```markdown
## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Tagger choice deferred to a spike phase | beets and wrtag both plausible; decide on evidence from a real sample rather than argument | — Pending |
| DJ content gets its own library path | Keeps `Compilations/` clean for genuine various-artist albums | — Pending |
```

D-17 (Jellyfin freeze is permanent) and D-11 (`568:568` decided) each become one row. Since both
are *settled* in this phase, their Outcome cells should carry a concrete result, not `— Pending`.

---

## Shared Patterns

### Service-file header comment block
**Source:** `STANDARDS.md:43-70`, exemplified by `stacks/selfhosted/media/seerr.yaml:1-24`
**Apply to:** every compose service file touched in this phase

```yaml
# Seerr - Unified Media Request Management System
#
# Purpose:
#   Unified fork of Jellyseerr and Overseerr for requesting movies and TV shows
#   ...
# Key Features:
#   - Self-service media requests with approval workflow
#   ...
# Workflow:
#   User requests → Approval (optional) → Radarr/Sonarr → Download → Media library
#
# Access:
#   URL: https://requests.deercrest.info
#   Middleware: chain-no-auth (public access for users)
#
services:
```

All eleven files in scope already have this block. This phase does not add headers — it must
avoid *breaking* them, and where a mount's meaning changes (Radarr no longer sees all of `media`,
wrtag no longer writes the library) the `Workflow:` line in the header should be updated to match
or it becomes stale documentation.

### Estate service account
**Source:** `STANDARDS.md:139-142`
**Apply to:** the apply script, the verify script, and `beets.md`

```markdown
### Volume Mounting
- **Base Path**: `/mnt/fast/appdata/{stack}/{component}`
- **User/Group**: 568:568 (apps:apps on TrueNAS SCALE)
- **Permissions**: 755 for directories, 644 for files
```

This is D-11 and D-12 already written down. `setup-mpe.sh:13` encodes it as `UIDGID="568:568"`,
and `seerr.yaml:32` as `user: "568:568"  # Run as apps:apps to match TrueNAS permissions`.

### Host access
**Source:** `CLAUDE.md` § Common Commands, `check-server-health.sh:8`
**Apply to:** both new scripts

```bash
ssh root@172.16.1.159
cd /mnt/fast/stacks
docker compose -f stacks/selfhosted/traefik/compose.yaml up -d
```

Two distinct conventions exist and the planner must pick per script:
- **Workstation-resident, ssh per command** — `quick-health-check.sh`, `check-server-health.sh`.
  Reachability guard: `if ! ssh -q root@172.16.1.159 exit; then echo "❌ Cannot connect…"; exit 1; fi`
- **Host-resident, run after `git pull`** — `setup-mpe.sh`, `pg-migrate.sh`. Uses
  `STACKS=/mnt/fast/stacks/stacks/selfhosted` (`pg-migrate.sh:18`) as the absolute anchor.

The apply script (ZFS snapshots, `chown -R`, `chmod`) must be host-resident. The verify script
folds into `quick-health-check.sh`, which is workstation-resident — so its checks have to be
expressible as single ssh'd commands.

### File mode of scripts
**Source:** `ls -l scripts/`

`check-renovate.sh`, `check-server-health.sh`, `pg-migrate.sh`, `setup-mpe.sh`,
`setup-mpe-cloudflare.sh` are `0755`. `quick-health-check.sh`, `setup-teleport.sh`,
`sync-repo.sh` are `0644` and are invoked as `bash scripts/<name>.sh`. New scripts should be
`0755` and committed with the exec bit — the `0644` files are drift, not a convention.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `scripts/diff-music-tags.sh` | comparison tool | transform | Nothing in this repo compares two structured datasets. `check-renovate.sh` counts and reports; it never diffs. Build from the `check-renovate.sh` shell skeleton (header, `set -euo pipefail`, colours, numbered sections, summary) with new comparison logic. |
| `scripts/snapshot-music-tags.sh` (core loop) | data-capture | streaming | No `ffprobe`/`ffmpeg` invocation exists anywhere in the repo, and nothing streams NDJSON. Only the *shape* transfers: `pg-migrate.sh`'s `migrate_pg()` function with a documented positional-arg contract, its `if ! docker ps … then echo "  SKIP: …"; return 0; fi` guard (the resumability idiom D-03 needs), and its `══` banner per unit of work. |
| Any Python module | — | — | **There is no Python in this repository.** `find . -name "*.py"` returns zero results outside `.git`. Do not scaffold a Python project (`pyproject.toml`, `requirements.txt`, `src/`) for D-01…D-05. Both tools are `ffprobe` + `jq` + `gzip` pipelines and belong in `scripts/*.sh` under the `setup-*.sh`/`check-*.sh` convention D-27 already names. |
| `docker inspect` mount enumeration (WRIT-01 audit) | audit logic | request-response | The repo uses `docker ps --format` and `docker inspect … --format='{{.State.Health.Status}}'` (`quick-health-check.sh:11`) but never enumerates `.Mounts`. New logic; the surrounding block shape is the analog, not the query. |

**Also worth stating plainly:** there is no analog for a ZFS snapshot in this repo. `infra/`
Terraform manages Proxmox host/LXC/VM resources, and `CLAUDE.md` § Infrastructure Rules confirms
Terraform is authoritative there — but `grep`ing the tree turns up no `zfs snapshot` invocation.
D-09's two snapshots are new work in the apply script, not a copied pattern.

---

## Metadata

**Analog search scope:** `scripts/`, `stacks/selfhosted/arrs/`, `stacks/selfhosted/media/`,
`stacks/selfhosted/music/`, `STANDARDS.md`, `CLAUDE.md`, `.planning/`
**Files scanned:** 22 read in full or in targeted ranges; ~60 matched by grep/glob
**Pattern extraction date:** 2026-08-17
