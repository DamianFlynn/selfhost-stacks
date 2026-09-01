# Phase 3: Tagger Spike - Pattern Map

**Mapped:** 2026-09-01
**Files analyzed:** 9 new artefacts (7 Wave 0 + 2 downstream)
**Analogs found:** 6 exact/strong / 9 · 3 have **no analog in this repo** and establish new convention

> **Read this first.** Two of the seven Wave 0 artefacts have no precedent here at all, and one of
> them is blocked on a host fact the research does not record. Both are in
> § *No Analog Found* and § *Blocking Findings*. Everything else copies cleanly from Phase 1's
> scripts, which are the strongest analogs this repo has and were written for exactly this job.

---

## Blocking Findings (measured on LXC 100, 2026-09-01)

These were established while hunting analogs. They change what the plan can write, so they lead.

### 1. `scripts/normalise-dj-tags.py` cannot import `mutagen` on LXC 100, and cannot be made to without a host package install

Measured over ssh, read-only:

```
python3            /usr/bin/python3   Python 3.13.5   (Debian GNU/Linux 13 trixie)
pip3               <absent>
python3-pip        <not installed>
python3-venv       <not installed>
python3-mutagen    <not installed>
import mutagen  -> ModuleNotFoundError
import ensurepip -> ModuleNotFoundError        <-- `python3 -m venv` will FAIL
/usr/lib/python3.13/EXTERNALLY-MANAGED  present <-- PEP 668 blocks system pip install
```

RESEARCH.md § *Standard Stack* asserts **"Nothing is installed on the host by this phase. The only
package installs happen inside throwaway containers."** That statement and D-13's
"Python + mutagen script on host" are **mutually exclusive as written**. There are exactly three
ways out and the planner must pick one explicitly:

| Option | Cost | Notes |
|---|---|---|
| **A.** `apt-get install python3-mutagen` on LXC 100 | ~1 MB; violates the "installs nothing" sentence | The Debian-packaged route. Cleanest, and `/` has 2.1 GB so it fits. Requires amending the research sentence, not ignoring it |
| **B.** Run the script **inside** the LSIO beets container | Zero host install; mutagen is already there as a beets dependency | But every existing script in `scripts/` is host- or workstation-resident; a container-resident script is a **new convention** (see § *No Analog Found*). Needs a mount of `scripts/` into the container |
| **C.** venv under `/mnt/fast` | **Not available** — `ensurepip` is missing, so `python3 -m venv` fails outright | Rule this out in the plan rather than discovering it at task time |

Option B also solves the probe script's home (it must run in-container anyway), giving one
convention for both Python artefacts instead of two. That is the recommendation, but it is the
planner's call and it must be **stated**, not assumed.

### 2. There is not one Python file in this repository

`find . -name '*.py' -not -path './.git/*'` returns **zero**. `.gitignore` lines 30–32 list three
`scripts/keeper-*.py` files as *abandoned experiments* — the only Python this repo has ever had, and
it is ignored. So `scripts/normalise-dj-tags.py` and the probe script **establish the Python
convention for this repo**. They do not follow one. The shell header/exit/idempotence conventions
below are transferable and should be transferred; nothing else exists to copy.

### 3. There is not one committed non-Markdown data artefact either

`git ls-files` outside `*.md`/`*.yaml`/`*.json5`/`*.sh`/`*.tf` returns only `.env.sample` files.
The variant survey and the ergonomics scoring sheet therefore have **no format precedent**. The
repo's data-recording convention is **a Markdown table inside a `.md` file** (`beets.md`,
`dispatcharr.md`) — see § *Pattern Assignments* for both artefacts.

### 4. `.gitignore` will silently swallow an artefact placed in the wrong directory

```
**/secrets/*
**/data/*
**/config/*/secrets/*
**/.env
```

`**/data/*` matches *any* `data/` directory at any depth. A scoring sheet at
`.planning/phases/03-tagger-spike/data/scoring.md` would be committed as nothing and the plan would
report a pass. Keep every Phase 3 artefact directly under the phase directory or under `scripts/`.

### 5. LXC 100 is at commit `90cdddc`; the workstation is at `5199db3`

Git is the delivery path. Nothing written in this phase can run on LXC 100 until it is **committed
and pushed to `origin`**, then `git pull --ff-only` on the host. Every Phase 1 script header states
this in its "Where it runs" block; the new scripts must too.

### 6. `/mnt/fast/secrets/discogs.env` is live and exactly matches the existing gate

```
-rw------- 1 root root  225 Aug 18 23:19 discogs.env      # mode 600, owner root -> passes the gate below
```

Variable name is **`DISCOGS_USER_TOKEN`** (key name read via `cut -d= -f1`; the value was never
read, printed or transported). Use the name; never the value.

---

## File Classification

| New file | Role | Data flow | Closest analog | Match |
|---|---|---|---|---|
| Discogs candidate probe (`tag_album()` NDJSON emitter) | measurement utility, **container-resident**, Python | batch read → NDJSON on stdout | `scripts/snapshot-music-tags.sh` | **structural exact**, language new |
| `scripts/normalise-dj-tags.py` | mutation utility, dry-run-default | file-I/O transform, per-file diff | `scripts/freeze-music-apply.sh` + `check-music-freeze.sh --baseline` | **strong**, language new |
| Variant survey artefact (folder → stratum) | data artefact + its derivation | batch transform over the Phase 1 ffprobe fence | `scripts/diff-music-tags.sh` § `FLATTEN_JQ` (derivation) · `stacks/selfhosted/arrs/beets.md` (format) | strong / format-only |
| Wave-0 disk-headroom + image-inventory helper | audit **then** gated mutation | inventory → operator approval → prune | `scripts/check-music-freeze.sh` (audit half) + `scripts/disable-jellyfin-hwaccel.sh` (gated-mutation half) | **exact** (two-analog composite) |
| Throwaway beets spike compose | config, scratch | declarative | `stacks/selfhosted/arrs/beets/beets.yaml` | **exact** (content) / **none** (location) |
| Throwaway beets-flask spike compose | config, scratch | declarative | `stacks/selfhosted/music/wrtag.yaml` | **exact** (content) / **none** (location) |
| wrtag two-arm dry-run harness (criterion 3) | measurement, docker-driving | request-response per arm | `scripts/disable-jellyfin-hwaccel.sh` | role-match |
| Ergonomics scoring-sheet template | data template | manual entry, 10 rows | *(none)* — nearest is a Markdown table in `beets.md` | **none** |
| Decision record (both axes, T1/T2/T3, outcomes) | durable doc | n/a | `stacks/selfhosted/arrs/beets.md` | **exact** |

---

## Pattern Assignments

### Discogs candidate probe — the `tag_album()` NDJSON emitter

**Analog:** `scripts/snapshot-music-tags.sh` (400 lines, 2026-08-18, the closest thing in the repo
to "walk a tree, emit one JSON record per unit, never write to the source").

**Why this analog and not the research sketch:** RESEARCH.md § *Criterion 1* gives a 30-line Python
sketch that prints raw `json.dumps` and has no resume, no failure ledger, no read-only assertion and
no progress output. `snapshot-music-tags.sh` has all four, and Phase 1 proved it over 9,736 files.
Port its *shape*, not just its output format.

**Read-only contract — reproduce this as the probe's own header** (`snapshot-music-tags.sh:31-33`):

```bash
# READ-ONLY against content (T-01-13). ffmpeg is invoked with `-f md5 -` writing to STDOUT and is
# never given an output file path; ffprobe is read-only by construction. This script contains no
# chown, chmod, mv or rm against any scan root - the only rm here targets its own output files.
```

The probe's equivalent claim is narrower and stronger: `tag_album()` reads `Item`s and returns a
`Proposal`; it opens no library database, runs no importer stage and moves no file. Say so, and say
it *at the call site* — Pitfall 5 in RESEARCH.md is exactly this risk.

**Resume ledger — copy verbatim in spirit** (`snapshot-music-tags.sh:53-63, 220-241, 320-325`):

```bash
# RESUMABILITY (D-02): the ledger, not a re-scan of the NDJSON. `<BASENAME>.done` is loaded once
#   into an associative array on start and any path already present is skipped.
#
#   Ordering within a file is: emit the NDJSON line, THEN append to `.done`. A hard kill in that
#   window re-emits one record on the next run; it never loses one.
```

```bash
      # Flush the record FIRST, then the ledger. A hard kill between the two re-emits one record
      # on resume; it never loses one.
      printf '%s\n' "$line" | gzip -cn >> "$OUT"
      printf '%s\n' "$f" >> "$DONE_LEDGER"
      DONE_MAP["$f"]=1
```

This matters more here than it did in Phase 1: a Discogs run that is rate-limited stalls invisibly
for hours (RESEARCH.md Pitfall 4, `MAX_ATTEMPTS = 100`). The operator **will** Ctrl-C it, and a
20-folder run that has to start over burns another 120–220 API requests against a 60/min ceiling.
One folder = one NDJSON line = one ledger entry.

**Failure ledger, not a silent skip** (`snapshot-music-tags.sh:61-63, 283-303`):

```bash
#   A file whose ffmpeg or ffprobe exits non-zero goes to `.failed` and is NOT written to `.done`,
#   so a re-run retries it rather than permanently skipping it.
```

```bash
      if [[ $rc -ne 0 ]]; then
        printf '%s\tffmpeg\t%s\n' "$f" "$rc" >> "$FAILED_LIST"
        R_FAIL=$((R_FAIL + 1)); TOT_FAIL=$((TOT_FAIL + 1))
        continue
      fi
```

A folder whose `tag_album()` raises must land in `.failed` with the exception class, **not** be
counted as "no Discogs candidate". Conflating an exception with a zero-candidate result is precisely
how Phase 1 produced six unearned passes, and it would corrupt the headline number this phase exists
to produce.

**Structured emission, never string concatenation** (`snapshot-music-tags.sh:44-46, 192-208`):

```bash
# The line is assembled BY jq, with the ffprobe JSON piped in as `.`, so unbalanced quotes,
# newlines and unicode inside third-party tag values cannot corrupt the stream (T-01-14).
# Nothing here concatenates strings into JSON.
```

The Python equivalent is `json.dumps(dict)` — which the research sketch already does. Keep it, and
never `f`-string a record. Album titles in this collection contain `:`, quotes and trailing spaces
(`'Mastermix Crate 068 : …'`, `'Mastermix - Issue 413 '`).

**Tool/precondition gate before any work** (`snapshot-music-tags.sh:146-163`):

```bash
# ─── preconditions (pg-migrate.sh guard-then-SKIP shape) ──────────────────────
MISSING_TOOLS=()
for t in ffmpeg ffprobe jq gzip stat find sort; do
  command -v "$t" >/dev/null 2>&1 || MISSING_TOOLS+=("$t")
done
if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  err "missing required tool(s): ${MISSING_TOOLS[*]}"
  echo "    This script installs nothing. Install them on LXC 100 and re-run." >&2
  exit 1
fi
```

The probe's preconditions are different but must be just as loud, and one of them is load-bearing:
**assert that the `discogs` plugin actually loaded** before probing anything. RESEARCH.md names the
exact failure — a customised `plugins:` list that omits `musicbrainz` silently disables autotagging
and looks like "no match found". Assert both plugins are in `plugins.find_plugins()` output and
exit 1 if not.

**Signal handling at a clean boundary** (`snapshot-music-tags.sh:169-176`):

```bash
STOP=0
on_signal() { STOP=1; echo ""; echo "  [signal received - stopping at the next file boundary]"; }
trap on_signal INT TERM
```

Python equivalent: a `signal.SIGINT` handler that sets a flag checked at the top of the folder loop.
Do not let Ctrl-C land mid-folder between the emit and the ledger append.

**Summary block + exit convention** (`snapshot-music-tags.sh:350-373, 386-400`):

```bash
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
...
if [[ $TOT_FAIL -gt 0 ]]; then
  echo -e "${RED}snapshot: complete with $TOT_FAIL failure(s)${NC}"
  exit 1
fi
echo -e "${GREEN}snapshot: complete${NC}"
```

The probe's summary must carry, at minimum: folders probed, folders with ≥1 Discogs candidate
(**loose**), folders passing the track-count test (**strict**), the gap between them, the `429`
count, and the `index_tracks` setting in force. D-05 and `<specifics>` both make the loose/strict gap
a deliverable in its own right — print it, do not make a reader compute it.

**Where it runs — new sub-convention.** Every existing script declares its home in the header. The
probe's is different from all of them and must say so:

```
# Where it runs:
#   INSIDE the throwaway LSIO beets container on LXC 100, not on the host. beets, the discogs
#   plugin and python3-discogs-client are all baked into lscr.io/linuxserver/beets:2.13.1-ls349;
#   LXC 100 itself has python3 3.13.5 with no pip, no venv (ensurepip absent) and PEP 668 set.
#   Delivered into the container by mounting the repo's scripts/ read-only.
```

**Pitfall 1 is a hard requirement, not advice.** `beet config` and any bare `beet` invocation opens
and migrates the *default* library. The probe must set both explicitly, as the research sketch does:

```python
config.set_file(os.environ["SPIKE_CONFIG"])          # explicit — never the default config
config["library"] = os.environ["SPIKE_DB"]           # explicit throwaway .blb
```

---

### `scripts/normalise-dj-tags.py`

**Analogs:** `scripts/freeze-music-apply.sh` (the repo's only mutating script over music content)
for the safety shape; `scripts/check-music-freeze.sh` for the mode-flag shape.

**The mutation banner — reproduce it** (`freeze-music-apply.sh:21-30`):

```bash
# ⚠️  This script MUTATES live state. Review, then run deliberately.
#     `fence`      creates two ZFS snapshots on the `tank` pool and writes ~350 MB under
#                  /mnt/fast/safety. It reads /mnt/tank; it never writes there.
#     `ownership`  recursively rewrites uid:gid across the ENTIRE Music dataset, library root
#                  included (2,674 entries as of 2026-08-18). It refuses to run unless the Music
#                  snapshot exists, because that snapshot is its only rollback.
```

Note the shape of the last clause: **"It refuses to run unless X exists, because X is its only
rollback."** That is the exact sentence `normalise-dj-tags.py` needs, with X =
`tank/downloads@spike-03-t0` (taken from atlantis — `zfs` does not exist on LXC 100).

**Mode-flag inversion.** D-08 and VALIDATION Wave 0 both require `--dry-run` to be the **default**.
This *inverts* the repo's existing convention and the plan must say so out loud, because
`check-music-freeze.sh` establishes the opposite (`check-music-freeze.sh:31-38`):

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

There is precedent for *stating* a deviation rather than silently inheriting — that whole block is
the precedent. Copy the practice: a `# FLAG CONVENTION (deliberately inverted from
check-music-freeze.sh)` block naming `--apply` as the writing mode and explaining that an
irreversible in-place tag write over reflinked copies earns a stricter default than a read-only
audit does.

**Argument parsing** (`snapshot-music-tags.sh:117-127`, `diff-music-tags.sh:80-92`) — the repo uses a
`while [[ $# -gt 0 ]]` / `case` loop with an explicit `-*) unknown option` arm and `exit 2` on usage
error. Python's `argparse` gives this for free; keep the **exit-2-on-usage** contract
(`diff-music-tags.sh:26-32`):

```bash
# EXIT CODES (the contract Phase 7 gates on):
#   0  no net metadata loss - MISSING_AFTER is 0 AND FIELDS_DROPPED is 0
#   1  loss detected        - either is non-zero
#   2  usage or input error
```

For `normalise-dj-tags.py`: `0` = ran (dry or applied) with no error; `1` = a rule failed or a file
could not be written; `2` = usage, or **a path outside the scratch root** (RESEARCH.md § D-08 rule 3
requires a hardcoded prefix refusal — make it exit 2, loudly, naming both paths).

**Never write to the system temp directory** (`snapshot-music-tags.sh:68-72`,
`diff-music-tags.sh:48-51`, `freeze-music-apply.sh:64-65`) — three separate scripts carry this and it
is the repo's most-repeated hazard:

```bash
# Nothing is written to the system temp directory. Two scratch files are needed for the join and
# they are created beside the BEFORE input - inside the fence - and removed by an EXIT trap. On
# LXC 100 the system temp directory is tmpfs backed by host RAM and a large spill there has
# previously taken the whole 28 GB box down (T-01-15).
```

`diff-music-tags.sh:103-112` is the concrete implementation to copy — scratch beside the input, with
a writability precheck and an `EXIT` trap:

```bash
SCRATCH_DIR="$(cd "$(dirname "$BEFORE")" && pwd)"
[[ -w "$SCRATCH_DIR" ]] || { ...; exit 2; }
FLAT_B="$(mktemp "${SCRATCH_DIR}/.diff-music-tags.before.XXXXXX")"
cleanup() { rm -f "$FLAT_B" "$FLAT_A"; }
trap cleanup EXIT
```

Python equivalent: `tempfile.NamedTemporaryFile(dir=scratch_root)`, never bare `tempfile.mkstemp()`.

**Verification of the script is already built.** Do not write a before/after comparator —
`snapshot-music-tags.sh --roots "$SCRATCH/normalised"` then `diff-music-tags.sh` gives the five
difference categories and `FIELDS_DROPPED` is the gate. `diff-music-tags.sh:288-292` even guards the
vacuous pass, which matters because 134 of 764 dj-mixes files are WAV and carry no format tags:

```bash
if [[ "$MATCHED" -gt 0 && "$NOFIELDS" -eq "$MATCHED" ]]; then
  echo -e "  ${YELLOW}⚠️  EVERY matched file had zero tag fields on the BEFORE side. \"No fields${NC}"
  echo -e "  ${YELLOW}    dropped\" is vacuously true here and proves nothing about metadata${NC}"
  echo -e "  ${YELLOW}    preservation. Read this result as untested, not as passed.${NC}"
fi
```

**Warn the planner:** `diff-music-tags.sh` joins on `audio_md5`. Normalisation rewrites *tags*, not
the encoded audio stream, so the key survives and the join is exact. That is the correct instrument.
It will also report the `dj-mixes` ↔ `unsorted` duplicates as an informational category
(`diff-music-tags.sh:22-24, 267-276`) which **does not affect the exit code** — expected, not a bug.

---

### Variant survey artefact (folder → stratum)

**Derivation analog:** `scripts/diff-music-tags.sh:126-152` — the streaming jq flatten over ffprobe
JSON. This is the exact operation the survey needs (read `format.tags` + audio-stream tags, normalise
key case, emit one compact record), already written and already proven:

```bash
FLATTEN_JQ='
  def flat:
    ( ((.ffprobe.format.tags // {}) | to_entries
        | map({ key: (.key | ascii_downcase),
                value: { n: .key, v: (.value | tostring) } }) )
      +
      ( [ .ffprobe.streams[]? | select(.codec_type == "audio") ]
        ...
    ) | from_entries;
  { k: (.audio_md5 // ""), p: (.source_path // ""), t: flat }
'
```

**Source:** `/mnt/fast/safety/music-pre-project/dj-mixes-ffprobe/` — one JSON per file, mirroring the
source tree (`freeze-music-apply.sh:40-46`). Read-only, no new I/O against `tank`. RESEARCH.md
finding 4 was produced from it in one pass; the task **formalises** that survey, it does not
discover it.

> Note the shape difference the planner must handle: the fence holds **one JSON file per audio
> file in a mirrored tree**, whereas `diff-music-tags.sh` consumes **NDJSON with an `audio_md5`
> envelope**. The fence JSONs are raw ffprobe output with no envelope. Either wrap them
> (`jq '{ffprobe: .}'`) before reusing `FLATTEN_JQ`, or address `.format.tags` directly. Do not
> assume the two formats are interchangeable — they are not.

**Output format analog:** `stacks/selfhosted/arrs/beets.md:44-52` — a committed Markdown table with
counts and a note on where the number came from:

```markdown
| Location | Files | Size | Tagged? |
|---|---|---|---|
| `downloads/complete/nzb/unsorted` | 7,451 | 97 G | no |
| `downloads/complete/nzb/dj-mixes` | 764 | 25 G | no |
```

and immediately beneath it, the retraction of a superseded figure — the house style for a corrected
census (`beets.md:55-58`):

```markdown
**764**, not 794: the older figure counted the 30 JPEG cover scans as tracks and missed the 24
BMP scans entirely (... ). Retire "794 dj-mixes files" wherever it appears.
```

The survey artefact should carry the same retraction for D-06's "84 folders" (real: 60 audio-bearing)
and for the claimed `artist`↔`album` swap (RESEARCH.md finding 4: not present).

**Format decision for the planner:** the repo has no committed TSV/CSV/NDJSON. Recommendation — the
folder→stratum mapping goes in the phase directory as Markdown (auditable in review, diffable, and
what everything else here does), with the machine-readable NDJSON written to the fence at
`/mnt/fast/safety/music-pre-project/` alongside the other captures and **not** committed. That keeps
the repo's zero-data-artefact convention intact while still giving the probe a machine input.

---

### Wave-0 disk-headroom + image-inventory helper

This is a **composite** — no single analog covers it, but two cover it exactly between them.

**Audit half — `scripts/check-music-freeze.sh`.** The counter/helper/summary/exit skeleton
(`check-music-freeze.sh:116-121`):

```bash
FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
rule() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
```

and the counts-then-exit summary (`check-music-freeze.sh:517-549`):

```bash
echo "📊 7. Summary"
rule
echo "  tagger-class writers:        $TAGGER_COUNT   (target 0)"
...
echo "  FAILURES total:              $FAILURES"

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

The headroom check's assertion is a single number with a stated floor: `df -h /` avail ≥ 8 GB
(VALIDATION Wave 0). Print the floor beside the value, exactly as the summary above prints
`(target 0)` beside each count.

**Gated-mutation half — `scripts/disable-jellyfin-hwaccel.sh`.** The subcommand split that keeps the
read-only path genuinely read-only (`disable-jellyfin-hwaccel.sh:11-19`):

```bash
# Usage:
#   bash scripts/disable-jellyfin-hwaccel.sh check     # read-only: report current state
#   bash scripts/disable-jellyfin-hwaccel.sh disable   # turn VAAPI off, restart, verify
#   bash scripts/disable-jellyfin-hwaccel.sh enable    # restore the most recent backup
#
# ⚠️  `disable` and `enable` MUTATE live state: they rewrite encoding.xml and restart a
#     container that is serving the house. `check` never writes anything.
```

and its idempotence contract (`disable-jellyfin-hwaccel.sh:78-86`):

```bash
# Idempotent:
#   `disable` re-run reports "already disabled" and changes nothing - no backup is taken and
#            the container is NOT restarted, because a needless restart of a service the house
#            is watching is a real cost.
#   `enable`  restores the most recent .bak; with no backup present it refuses rather than
#            guessing a previous value.
#   `check`   never writes.
```

Map directly: `inventory` (read-only; `docker images` diffed against
`docker ps -a --format '{{.Image}}'`, emits the reap list) → operator approves → `prune` (acts on
**the approved list only**, never `docker image prune -a`). VALIDATION § *Manual-Only Verifications*
makes the approval a human gate, so the two subcommands must be genuinely separable — the reap list
is written to a file by `inventory` and read from that file by `prune`.

**The blind spot this must not reproduce** — quoted in `check-music-freeze.sh:36-38` and in project
memory: `docker ps -a` filters on `status=restarting/dead/exited` **miss `created`**. A container in
`created` state has never run, and its image must not be reaped. `docker ps -a` with no status filter
sees it; a filtered query does not. State this in the header.

**No `read -r` confirmation prompt exists anywhere in `scripts/`** — every mutating script here is
non-interactive and gates on a *subcommand* plus a *precondition*, not on a typed "yes". Follow that;
do not introduce a prompt.

---

### Throwaway compose files (beets spike, beets-flask spike)

**Content analogs — both are exact.** `stacks/selfhosted/arrs/beets/beets.yaml:4-25`:

```yaml
  beets:
    hostname: beets
    image: lscr.io/linuxserver/beets:2.5.1-ls295
    container_name: beets
    security_opt:
      - no-new-privileges:true
    restart: "no"  # Don't run 24/7, start manually or via cron
    profiles: ["manual"]  # Exclude from 'docker compose up'
    environment:
      TZ: $TZ
      PUID: $PUID
      PGID: $PGID
    volumes:
      - /mnt/fast/appdata/arrs/beets/config:/config:rw  # Application config and library.db
      - /mnt/tank/downloads:/downloads:rw  # Import source — backlog staging area
      # NOTE (2026-08-18): :ro is deliberate (D-20). Nobody holds read-write on
      # /mnt/tank/media/Music during Phases 1-3, including this container. ...
      - /mnt/tank/media:/media:ro  # Existing library — READ-ONLY until Phase 6 (see above)
```

Copy: `security_opt: [no-new-privileges:true]`, `restart: "no"`, `profiles: ["manual"]`, the
comment-above-the-mount style, and the `:ro` on anything reaching Music. Drop: the `traefik.*` label
block and the published port (`beets.yaml:28-42`) — a throwaway spike does not get a public hostname
or an Authelia chain. `wrtag.yaml:39-58` shows the other half of the pattern, a **deleted** rather
than commented-out mount with the reason recorded in place:

```yaml
    volumes:
      # NOTE (2026-08-18): the destination library mount was DELETED here, not commented
      # out — WRIT-02 requires the mount gone, not just the restart policy changed. ...
      # Do not re-add a mount pointing at the music library here. wrtag is frozen, not
      # retired — Phase 4 owns deleting this definition and is independently shippable.
```

**Location — there is no analog and the planner must decide explicitly.** Every compose file in this
repo lives at `stacks/selfhosted/<stack>/<service>.yaml` and is pulled in by an explicit `include:`
list in that stack's `compose.yaml` (`music/compose.yaml:11-13`, `arrs/compose.yaml:21-30`). There is
no scratch, spike or temp compose precedent. Two viable placements:

| Placement | For | Against |
|---|---|---|
| `.planning/phases/03-tagger-spike/spike-*.yaml` | Committed → **delivered by the existing `git pull`**, auditable in review, deleted by a commit in the closing plan. Unambiguously not a stack | Compose files have never lived outside `stacks/` here |
| `stacks/selfhosted/spike-03/` | Matches the directory convention | Looks permanent; a reader six weeks later cannot tell it is throwaway; risks surviving the phase. Also risks a future reviewer reading it as a fourth tagging path — the precise failure mode this project exists to prevent |

Recommendation: the phase directory. It satisfies D-03 (not under `arrs/` or `music/`), satisfies
"scratch path", and inherits git as the delivery mechanism.

**The `.env` trap.** Compose resolves `.env` from the **compose file's own directory**. The stack
files above use `$TZ`/`$PUID`/`$PGID`, supplied by `stacks/selfhosted/<stack>/.env` — which is
gitignored (`.gitignore:1 **/.env`). A spike compose placed anywhere else has **no `.env` sibling**
and those variables will expand to empty with only a warning. Either write literal values
(`TZ: Europe/Dublin`, `USER_ID: 568`, `GROUP_ID: 568` — `568:568` is `apps:apps` per CLAUDE.md
§ *Storage and Permissions*) or pass `--env-file` explicitly. Do not copy `$TZ` verbatim and assume
it resolves.

**Secret delivery.** `env_file: /mnt/fast/secrets/discogs.env` — absolute path, outside the repo,
never `-e`, never a command line. The file is live and already `600 root` (§ *Blocking Findings* 6).

---

### wrtag two-arm dry-run harness (criterion 3)

**Analog:** `scripts/disable-jellyfin-hwaccel.sh` — the only script here that drives `docker` and
delegates the part it cannot see to atlantis (`disable-jellyfin-hwaccel.sh:5-10`):

```bash
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   Host-resident because it edits Jellyfin's config under /mnt/fast/appdata and restarts the
#   container. The ONE thing it cannot see from here is the GPU's DRM client table: /dev/dri is
#   passed INTO this container, but /sys/kernel/debug/dri lives on the Proxmox host. That check
#   is delegated over ssh to 172.16.1.158, the same convention check-music-freeze.sh uses for
#   its zfs queries.
```

and its constants block (`disable-jellyfin-hwaccel.sh:93-96`):

```bash
JELLYFIN_CONFIG="${JELLYFIN_CONFIG:-/mnt/fast/appdata/media/jellyfin/config/encoding.xml}"
JELLYFIN_CONTAINER="${JELLYFIN_CONTAINER:-jellyfin}"
PROXMOX_HOST="${PROXMOX_HOST:-172.16.1.158}"
```

Note the `${VAR:-default}` override shape — useful here so the two arms differ only by
`WRTAG_IMAGE=sentriz/wrtag:v0.20.0` vs `v0.34.0` on the same code path. Same command shape, same
mounts, same `WRTAG_PATH_FORMAT` taken **verbatim** from `wrtag.yaml:71`; only the image tag varies.
If the harness renders the path format itself instead of reading it from the file, the test proves
nothing about this repo's configuration.

**The "wrote nothing" assertion** (VALIDATION TAGR-02) has an analog in
`check-music-freeze.sh:509-514` — prove absence by enumerating, and fail with the list:

```bash
if [[ "$FENCE_MOUNT_COUNT" -eq 0 ]]; then
  pass "no running container mounts any path under /mnt/fast/safety (D-08, proven not asserted)"
else
  fence_fail "$FENCE_MOUNT_COUNT running containers mount a path under /mnt/fast/safety:"
  printf '%s' "$FENCE_MOUNTS" | sed 's/^/         /'
fi
```

Same shape for `find "$SCRATCH" -newer "$STAMP" -type f` → empty is a `pass`, non-empty prints the
paths and fails.

---

### Ergonomics scoring-sheet template

**No analog.** Nearest thing in the repo is a Markdown table with a stated capture method. Use the
`beets.md` table style, one row per (album × front end), 10 rows, committed **before** the trial with
every cell empty — VALIDATION Wave 0 requires the template to predate the evidence, and a committed
empty template is the only way that is provable afterwards.

Columns come straight from RESEARCH.md § *Criteria 6 and 8*: `front_end`, `album`, `wall_clock_s`,
`interventions`, `outcome`, `stuck_points`, `context_switches`. Add the ordering-control column the
research demands (which front end went first for that album) — without it the alternation cannot be
audited, only claimed.

The one convention worth importing from `check-music-freeze.sh:53-58` is the "why report and not
assert" reasoning style: state in the sheet's header **what counts as one intervention**, because
that definition is the measurement, and a definition invented after the run is not a measurement.

---

### Decision record

**Analog:** `stacks/selfhosted/arrs/beets.md` — 931 lines, and the repo's model for a durable record
that is not applied by anything (`beets.md:1-15`):

```markdown
# Beets: library state and the bulk-import backlog

Companion to [`beets/beets.yaml`](beets/beets.yaml) (manual container) and ...

Nothing here is applied by `docker compose`. This is the record of what the music library
currently looks like, why the tagging pipeline stalled, and how to work the backlog.

State as of 2026-08-18, after the Phase 1 safety harness (last section).

> **Both beets definitions now mount the library `:ro`, and wrtag's library mount is deleted.**
> Nothing in this document's "how to work the backlog" advice will write to `/mnt/tank/media/Music`
> until Phase 6 grants the surviving tagger `rw` again. That is intentional — see the last section.
```

Copy all four moves: (1) a **Companion to `<relative link>`** line, (2) an explicit "nothing here is
applied" disclaimer, (3) a dated state stamp, (4) a leading blockquote carrying the one thing a
reader must not miss. For Phase 3 that blockquote is the decision itself plus the fact that Phase 4
deletes the loser and Phase 6 grants rw — not before.

**Placement:** `stacks/selfhosted/arrs/beets.md` sits *beside the stack it documents*. The Phase 3
decision spans two stacks (`arrs/beets`, `music/wrtag`) and one uninstalled candidate
(beets-flask), so it belongs in the phase directory, with a pointer added to `beets.md`. Note
`beets.md` already anticipates this (`beets.md` last section and `wrtag.yaml:20-22`:
*"Phase 4 owns retirement — see .planning/ROADMAP.md"*).

**Content requirements already fixed elsewhere** — reproduce, don't reinvent: the D-12 claim-audit
table (RESEARCH.md, 16 rows, verdict + one-line impact), the T1/T2/T3 thresholds with a
tested/returned line each, the strict-vs-loose gap, the per-folder vs per-`audio_md5` denominator
statement, and the verbatim `wrtag.yaml:73` quote:

```
WRTAG_RESEARCH_LINK=https://www.discogs.com/search/?q={query},https://musicbrainz.org/search?query={query}
```

---

## Shared Patterns

### The script header block

**Source:** every script in `scripts/` written since 2026-06. Canonical instance:
`snapshot-music-tags.sh:1-72`. **Apply to:** all four new scripts.

Fixed section order, and it is genuinely fixed across all six recent scripts:

```
#!/usr/bin/env bash
# <name>.sh - <one-line purpose>
# Usage: ...
#
# Where it runs:        <host, path, "after a `git pull`", and WHY here and not the workstation>
# Usage:                <every invocation form, one per line, with its plan number>
# Workflow:             <the literal ssh + cd + git pull + run sequence>
# Outputs:              <every file written, with its purpose>
# <CONTRACT>:           READ-ONLY BY CONTRACT / ⚠️ This script MUTATES live state
# <THE KEY / WHY>:      the load-bearing design decision, with the decision ID (D-nn)
# Idempotent:           what a re-run does, per subcommand
# EXIT-CODE CONVENTION: stated, not inherited
# <HAZARD NOTES>:       ZFS NOTE / RSYNC NOTE / "NOTHING is written to /tmp"

set -euo pipefail
```

Two habits inside it are worth naming because they are unusual and deliberate:

1. **Decision IDs are cited inline.** `(D-01)`, `(T-01-13)`, `(WR-13)`, `(CR-01)` appear at the
   line they justify, not only in the header. Phase 3's new scripts should cite D-05, D-07, D-08.
2. **Corrections are recorded in place, not silently fixed.** `check-music-consumers.sh:156-172`
   keeps the wrong sentence and marks it:

```bash
# ⚠ CORRECTED 2026-09-01 (CR-01). The sentence above used to continue "...so neither value ever
#   entered the process list on a host running 100+ containers", asserting a property of THIS
#   SCRIPT that this script did not have.
```

RESEARCH.md falsifies three upstream premises (the swap that isn't, the 84→60 folder count, the
"~1,000 folders" backlog). The artefacts that supersede them should carry that same correction
marker rather than quietly presenting the new number.

### Secrets

**Source:** `scripts/check-music-consumers.sh:150-172` (the doctrine) and `:468-514` (the gate).
**Apply to:** anything touching `/mnt/fast/secrets/discogs.env` — the probe, both compose files.

```bash
# SECRETS (D-39, D-40). Both are read at runtime from /mnt/fast/secrets/ on LXC 100, mode 0600,
# root-owned, and were written there via stdin so the WRITE never entered the process list.
# NO TOKEN, PASSWORD OR KEY APPEARS IN THIS FILE OR ANYWHERE ELSE IN THIS REPOSITORY. The repo is
# public and has one prior credential exposure still recoverable via `git log -S`; a value
# committed here stays recoverable forever even after redaction.
```

The gate — **refuse to source a file whose mode/owner you cannot vouch for** (`:470-498`):

```bash
# WR-13: THE PERMISSION ASSERTION IS A GATE, NOT A REMARK. The previous version recorded the
# `fail` and then sourced the file anyway. `.` executes arbitrary shell, not just assignments —
# so the exact state the assertion detects (the file is writable by, or owned by, somebody other
# than root) was the state in which this script handed that somebody root code execution on
# LXC 100, on every quick-health-check run. Refuse instead.
if [[ -r "$MA_SECRETS" ]]; then
  MA_MODE="$(stat -c '%a %U' "$MA_SECRETS" 2>/dev/null || echo '? ?')"
  if [[ "$MA_MODE" == "600 root" ]]; then
    pass "MA credential $MA_SECRETS ($MA_MODE)"
    # shellcheck disable=SC1090
    . "$MA_SECRETS"          # no `set -a`: in-process only
  else
    fail "MA credential $MA_SECRETS has mode/owner '$MA_MODE', want '600 root' (D-39) — REFUSING"
```

Three rules that fall out, all of which apply to `DISCOGS_USER_TOKEN`:

- **`stat -c '%a %U'` must equal `600 root` before sourcing.** Verified live: `discogs.env` does.
- **No `set -a`.** Exporting puts the token in `/proc/<pid>/environ` of every child — and this
  phase spawns `docker`, which is exactly the wrong child (`:476-481`).
- **Never in argv.** `curl -H @<(printf ...)` and `VAR=... jq '$ENV.NAME'` are the two worked
  examples (`:387-398`). For the probe, the token reaches the container via
  `env_file:` and is read inside it from the environment — it must never appear in a
  `docker run -e`, a `beet` command line, or a config file in git.

### Delegating to the Proxmox host

**Source:** `check-music-freeze.sh:123-131`. **Apply to:** the `zfs snapshot tank/downloads@spike-03-t0`
step (D-07), the post-wave `zfs diff` (VALIDATION § *Sampling Rate*), and any `chown` on scratch.

```bash
ZFS_HOST="172.16.1.158"                 # Proxmox host "atlantis" - the only place zfs exists

# Delegate zfs to the Proxmox host when it is not resolvable locally. Read-only queries only.
ZFS_ROUTE="unavailable"
zfs_query() {
  if command -v zfs >/dev/null 2>&1; then
    zfs "$@"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${ZFS_HOST}" zfs "$@"
  fi
}
```

Two details that are not decoration: the function **tries local first** rather than hard-coding the
ssh (`freeze-music-apply.sh:49-55` explains why — "Nothing here is hard-coded to either
assumption"), and the **route taken is reported** in the output so a reader knows which machine
produced the number. `check-music-consumers.sh:525-531` shows the same for `exportfs`:

```bash
if exportfs_query true >/dev/null 2>&1; then
  EXPORT_ROUTE="ssh:${NFS_HOST}"
  pass "export queries delegated to root@${NFS_HOST} (exportfs does not exist on LXC 100)"
else
  fail "root@${NFS_HOST} unreachable over ssh — section 1 cannot be asserted"
```

Note the failure branch: **"cannot be asserted"**, not a skip and not a pass. Unreachable is UNKNOWN.

### Host-resident vs workstation-resident, and the ssh sandwich

**Source:** `check-music-freeze.sh:5-12` (host-resident) and `quick-health-check.sh:62-70`
(workstation-resident wrapper). **Apply to:** every new script's header, and to how the plan's
verification commands are written.

```bash
# Where it runs:
#   ON LXC 100 (root@172.16.1.159), from /mnt/fast/stacks, after a `git pull`.
#   It is host-resident rather than workstation-resident because `stat` over the library,
#   `find` across 1,200+ files and the docker mount enumeration cannot each be expressed as
#   one ssh'd command. Plan 01-09 folds it into the workstation-resident
#   scripts/quick-health-check.sh with a single
#     ssh root@172.16.1.159 'bash /mnt/fast/stacks/scripts/check-music-freeze.sh'
#   which is how both estate conventions are honoured without mixing them inside one file.
```

The rule: **a script is host-resident if it cannot be expressed as one ssh'd command**; otherwise it
is workstation-resident and every line is `ssh $SSH_OPTS root@172.16.1.159 "..."`. All four new
scripts are host-resident (the probe more so — it is *container*-resident).

And the reachability gate that must precede any remote read
(`quick-health-check.sh:41-70`):

```bash
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=10"
if ! ssh $SSH_OPTS root@172.16.1.159 true 2>/dev/null; then
    echo "⚠️  UNKNOWN — 172.16.1.159 (LXC 100) is unreachable over ssh."
    echo "  NO container state can be read, so nothing below would be a measurement."
    echo "  This is UNKNOWN, not healthy. Check the host, then re-run."
    exit 1
fi
```

The comment above it (`:44-60`) is the single best statement of this repo's measurement doctrine and
is directly on point for a phase whose whole output is numbers:

```bash
#   * UNHEALTHY=$(ssh ... | wc -l) comes back EMPTY, `[ "" -gt 0 ]` writes "integer expression
#     expected" to stderr and returns 2, and the else branch prints "✅ No unhealthy containers".
# ...
# Probing once and refusing is better than hardening five call sites: it makes the unreachable
# case a single, unmissable statement instead of five separately-wrong lines.
```

**Apply this to the Discogs probe.** An empty candidate list from a failed HTTP call and an empty
candidate list from a genuine no-match are the same value. Probe the API once at startup
(`GET /oauth/identity`, which D-04 already used) and refuse the whole run if it does not return 200 —
one unmissable statement instead of 20 folders of silently-wrong zeros.

### Output formatting

**Source:** `check-music-freeze.sh:83-88, 144-156` and `snapshot-music-tags.sh:131-144`.
**Apply to:** all four new scripts.

```bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
```

Run banner, always, listing every path and parameter the run will use plus the UTC date and the
active mode (`check-music-freeze.sh:144-156`):

```bash
echo "🎵 Music Freeze Harness Audit"
rule
echo "  library:   $LIBRARY"
echo "  fence:     $FENCE"
echo "  host:      $(hostname)"
echo "  date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [[ $BASELINE_MODE -eq 1 ]]; then
  echo -e "  mode:      ${YELLOW}--baseline (report only, always exits 0)${NC}"
else
  echo "  mode:      assert (exits non-zero on any failed check)"
fi
```

For `normalise-dj-tags.py` the mode line is the most important line it prints: `dry-run (default,
writes nothing)` vs `--apply (WRITES TAGS IN PLACE)`, in yellow and red respectively.

### Self-documenting `--help`

**Source:** `check-music-freeze.sh:96-99` — the header block *is* the help text:

```bash
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
```

`snapshot-music-tags.sh:102-115` and `diff-music-tags.sh:63-75` use the alternative — a `cat >&2
<<'EOF'` usage block plus `exit 2`. Either is established; pick one per script and keep it.

### Acceptance criteria must parse, not grep

**Source:** RESEARCH.md Pitfall 7, confirmed against Phase 1 plans 01-05 and 01-07. Reinforced by
`check-music-freeze.sh` itself, whose section 2 parses `docker inspect` output rather than grepping
YAML (`:207`, `:502`: `while IFS='|' read -r cname csrc cdst cflag`).

A comment explaining that a value was changed contains the literal string a grep searches for. Every
Phase 3 acceptance check should assert on `jq` over NDJSON, `docker inspect --format`, `stat -c`, or
`beet config -d` inside the container — never on `grep`ping the prose of a self-documenting file.
These new scripts have very long comment headers; the trap is live.

---

## No Analog Found

| File | Role | Data flow | Reason |
|---|---|---|---|
| Discogs probe (`*.py`) | measurement utility | batch → NDJSON | **No Python exists in this repo.** Also the first *container-resident* script — every existing script is host- or workstation-resident. Take the structure from `snapshot-music-tags.sh`; the language conventions (argparse, logging, `json.dumps`, exception→`.failed`) are being set here |
| `scripts/normalise-dj-tags.py` | mutation utility | file-I/O transform | Same. Additionally: **no dependency-management convention exists** — no `requirements.txt`, no `pyproject.toml`, no venv anywhere in the repo, and none is possible on LXC 100 as configured (§ *Blocking Findings* 1) |
| Ergonomics scoring sheet | data template | manual entry | **No committed data artefact of any kind exists.** Format decision is unconstrained; Markdown table matches everything else |
| Throwaway compose location | config | declarative | Every compose file lives under `stacks/selfhosted/<stack>/` and is `include:`d by that stack's `compose.yaml`. **No scratch/spike/temp compose precedent.** D-03 forbids the two obvious homes |

RESEARCH.md § *Code Examples* should be the fallback for all four — it carries verified upstream
source for `tag_album()`, the beets-flask inbox config, the wrtag `move -dry-run` invocation and the
compose sketch. Prefer it over inventing a shape, but port the *safety* conventions above onto it;
the research sketches have none.

---

## Metadata

**Analog search scope:** `scripts/` (14 files, 4,503 lines — all read or targeted-read),
`stacks/selfhosted/` (33 stacks, all compose + all 12 `.md`), `.gitignore`, `.planning/phases/01`,
`.planning/phases/02`, and live read-only probes of LXC 100 (`172.16.1.159`).
**Files scanned:** 60+
**Files read in full:** `scripts/snapshot-music-tags.sh`, `scripts/diff-music-tags.sh`,
`stacks/selfhosted/arrs/beets/beets.yaml`, `stacks/selfhosted/music/wrtag.yaml`,
`stacks/selfhosted/music/compose.yaml`
**Files read in part:** `scripts/check-music-freeze.sh` (1-175, 505-549),
`scripts/check-music-consumers.sh` (145-215, 460-534), `scripts/freeze-music-apply.sh` (1-110),
`scripts/disable-jellyfin-hwaccel.sh` (1-96), `scripts/quick-health-check.sh` (1-70),
`stacks/selfhosted/arrs/beets.md` (1-60)
**Live probes (read-only, no writes):** python3/pip/venv/ensurepip/mutagen availability on LXC 100;
`/etc/os-release`; `df -h /` and `/mnt/tank/downloads`; `/mnt/fast/secrets/` listing and
`discogs.env` **key names only**; `git log --oneline -1` at `/mnt/fast/stacks`; `command -v` for
ffprobe/jq/gzip/sha256sum/setsid/nohup. **No secret value was read, printed or transmitted.**
**Pattern extraction date:** 2026-09-01
