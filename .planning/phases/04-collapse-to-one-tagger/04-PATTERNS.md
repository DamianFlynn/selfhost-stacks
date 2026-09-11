# Phase 4: Collapse to One Tagger - Pattern Map

**Mapped:** 2026-09-11
**Files analyzed:** 25 repo files (2 new, 4 deleted, 19 modified) + 5 host-side operations with no repo file
**Analogs found:** 25 / 25 repo files (deletions need no analog but carry sweep obligations); 3 of 5 host-side operations have an in-repo analog

---

## ⚠ Corrections to premises in the pattern-mapping brief (read first)

Four analogs named in the brief do not exist in the shape it assumed. Each correction below was verified in the repo today.

| # | Brief assumed | Measured | Consequence for the planner |
|---|---|---|---|
| P1 | `scripts_init.bash` is a **vendored repo file** | **Not in git.** `git ls-files \| grep scripts_init` → nothing. It lives only on the host in `/mnt/fast/appdata/arrs/sabnzbd/arr-scripts/`, bind-mounted as a **directory** at `sabnzbd.yaml:55`. `04-RESEARCH.md` also records it as "host-only file, sha `b3927…`, not in git" | The **only** in-repo precedent for vendoring a runtime file is `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` plus its mount at `sabnzbd.yaml:95`. Do not cite `scripts_init.bash` as a repo analog |
| P2 | `ZFS_HOST` is an env-overridable precedent **in `check-music-freeze.sh`** | `check-music-freeze.sh:78` **hard-codes** `ZFS_HOST="172.16.1.158"`. The `${VAR:-default}` precedent is `check-jellyfin-transcode.sh:151-154` (`ZFS_HOST`, `JELLYFIN_CONTAINER`, `JELLYFIN_SECRETS`) and `:224-228` (`EXPECT_*`) | `RETIRED_DB_PATHS` and `SURVIVOR_DB` will be the **first** env overrides in `check-music-freeze.sh`. Copy the header doctrine and the block from `check-jellyfin-transcode.sh`, not from the freeze check |
| P3 | A `beets-config.yaml` drift comparison from plan 01-09 exists to extend | **Never built** (F6). Only the comment at `sabnzbd.yaml:89-90` claims it | D-13 is the first drift block. The nearest shape is the fold-in blocks in `quick-health-check.sh`, not an existing drift check |
| P4 | An env override can drive the `quick-health-check.sh` red path | The file **hard-codes** every remote command string. `REQUIREMENTS.md` line 256 (TRAN-05 addendum) records the limit: *"an `EXPECT_*` override cannot reach it"* | Only a variable interpolated **from the workstation side** into the remote string reaches the host. `REMOTE_TIMEOUT` (`:234`, interpolated at `:424`/`:492`) is the working precedent. D-13's driven control must be that shape, e.g. a workstation `DRIFT_EXPECT_*` that is compared locally or interpolated in |

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `stacks/selfhosted/arrs/soulbeet.yaml` | config (compose) | — | **DELETE** (D-01) | n/a |
| `stacks/selfhosted/arrs/soulbeet/beets_config.yaml` | config (beets) | — | **DELETE** (D-01). Record the pre-deletion SHA for the #306 comment | n/a |
| `stacks/selfhosted/music/compose.yaml` | config (compose project) | — | **DELETE whole directory** (D-05) | n/a |
| `stacks/selfhosted/music/wrtag.yaml` | config (compose) | — | **DELETE** (D-05). `spike03-wrtag-arms.sh:147` defaults to it (see that row) | n/a |
| `stacks/selfhosted/arrs/compose.yaml` | config (include list) | — | itself, lines 32-40 | exact |
| `stacks/selfhosted/arrs/beets/beets.yaml` | config (compose, survivor) | file-I/O (bind mounts) | `stacks/selfhosted/arrs/sabnzbd.yaml:56-95` (vendored-file mount + NOTE block) | exact |
| **NEW** `stacks/selfhosted/arrs/beets/config.yaml` *(suggested path; D-27)* | config (beets, vendored) | file-I/O | `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` (header + SAFE-01 block) | exact |
| `stacks/selfhosted/arrs/sabnzbd.yaml` | config (compose) | file-I/O | itself, lines 43-95 | exact |
| `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` | config (beets, vendored) | — | itself (header 1-35) | exact |
| **NEW** `stacks/selfhosted/arrs/sabnzbd/audio.bash` | utility (post-proc hook, vendored) | batch / file-I/O | vendoring shape: `beets-config.yaml` + `sabnzbd.yaml:95`; content = live host file | role-match (see P1, and the byte-identity constraint below) |
| `renovate.json5` | config (policy) | — | Jellyfin rule `renovate.json5:451-469`; `04-RESEARCH.md` Code Ex. 1 | exact |
| `scripts/check-renovate.sh` | utility (health check) | request-response | itself; PATH-stub harness in `02.1-08-SUMMARY.md` § 5 | exact |
| `scripts/check-music-freeze.sh` | utility (health check, host-resident) | batch census | itself § 1 (`:185-247`) + env-override doctrine `check-jellyfin-transcode.sh:121-133,151-154,205-228` + UNKNOWN summary `check-jellyfin-transcode.sh:759-774` | exact |
| `scripts/quick-health-check.sh` | utility (health check, workstation) | request-response over ssh | itself: count sites `:424-469`, fold-in `:491-557`, notices `:45-50,125-144`, tail `:734-746` | exact |
| `scripts/normalise-dj-tags.py` | utility (tag writer) | file-I/O / transform | its own MP3 branch `:480-499` and `:611-631`; `--self-test` shape from `spike03-wrtag-arms.sh:389-418` | exact (write path) / role-match (self-test) |
| `scripts/spike03-discogs-probe.py` | utility (probe) | request-response → NDJSON | itself: the `--require-plugin` parameterisation `:259-273,850-859,893` | exact |
| `scripts/spike03-image-headroom.sh` | utility | — | itself `:106-117` | exact |
| `scripts/spike03-wrtag-arms.sh` | utility (historical instrument) | — | itself header `:1-60`; defaults `:146-147` | exact (keep-with-reason) |
| `.gitignore` | config | — | itself `:38-50` | exact |
| `CLAUDE.md` | docs (generated regions) | — | itself; markers `:91,157,159,343` | exact |
| `.planning/research/STACK.md` | docs (source of `CLAUDE.md:159-343`) | — | in-band dated correction shape: `beets.md:981-990` | role-match |
| `.planning/PROJECT.md` | docs | — | `PROJECT.md:214` (reasoned dismissal, for D-24); table `:58-66` | exact |
| `.planning/ROADMAP.md` | docs (criteria) | — | `ROADMAP.md:262-273` (the 02.1-11 amendment) | exact |
| `.planning/REQUIREMENTS.md` | docs (requirements) | — | `REQUIREMENTS.md:256` (TRAN-05 `ADDENDUM 2026-09-03 (02.1-11)`) | exact |
| `stacks/selfhosted/arrs/beets.md` | docs (durable estate record) | — | `beets.md:199-238` (Phase 1 closure with a pasted executed run); `beets.md:945-990` (Phase 3 + in-band correction) | exact |

---

## Pattern Assignments

### `stacks/selfhosted/arrs/compose.yaml` (config, include list)

**Analog:** itself, lines 32-40
```yaml
#  - listenarr.yaml  # Image not yet published
  - bazarr.yaml
  ...
  - blockbusterr.yaml
#  - soulbeet.yaml
#  - boxarr.yaml  # Commented out - image not published to Docker Hub yet (needs to be built from source)
#  - beets.yaml
```
- Line 38 `#  - soulbeet.yaml`: **delete** (D-06).
- Line 40 `#  - beets.yaml`: **change to `#  - beets/beets.yaml`** and keep it commented (D-34, D-02). VALIDATION C1-c greps `'^#  - beets/beets.yaml$'` → 1, so keep the **two-space** indent after `#` exactly.
- Leave lines 32 and 39 alone (D-06).
- Gate: `docker compose -f stacks/selfhosted/arrs/compose.yaml config --quiet`. Always use `--quiet`, because without it compose renders `.env` secrets.

---

### `stacks/selfhosted/arrs/beets/beets.yaml` (survivor; D-03, D-27)

**Analog for the image line:** itself, line 6
```yaml
    image: lscr.io/linuxserver/beets:2.5.1-ls295
```
→ `lscr.io/linuxserver/beets:2.13.1-ls349` (D-03). The two Renovate rules added to `renovate.json5` match this package name exactly.

**Analog for the new vendored-config bind mount and its NOTE:** `sabnzbd.yaml:56-61`, `:92-95`
```yaml
      # beets config. NOTE (2026-08-18): sabnzbd/beets-config.yaml is now VENDORED in
      # this repo (plan 01-07, SAFE-01 / D-28). It is the config audio.bash line 285
      # hands to beets on EVERY music download:
      ...
      # The repo copy is for review and history; THIS appdata path is authoritative at
      # runtime. ...
      - /mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml:/config/scripts/beets-config.yaml:rw  # Vendored beets config (see above)
```
Insert the survivor's equivalent **after** line 17 (the `/config:rw` directory bind). A single-file bind shadows a path inside a directory bind, and that is the same shape sabnzbd uses (`:42` dir bind, `:95` file bind). Shape:
`- /mnt/fast/appdata/arrs/beets/config/config.yaml:/config/config.yaml:<ro|rw>`.
The `:ro` choice carries the same A1 EROFS risk as D-09. LSIO `init-beets-config` runs `lsiown -R abc:abc /config`. The D-19 `up` is therefore also the survivor's boot proof, and should record any EROFS lines.

**Keep verbatim** lines 10-11 (`restart: "no"`, `profiles: ["manual"]`) and lines 19-25 (the D-20 `:ro` NOTE and `/mnt/tank/media:/media:ro`). D-02 and Phase 1's D-20 both forbid touching them.

---

### NEW `stacks/selfhosted/arrs/beets/config.yaml` (vendored survivor beets config, D-27)

**Analog:** `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml`

**Header / provenance pattern** (lines 1-22). Copy the structure: *consumed by*, *VENDORED date (plan, requirement)*, *repo copy = review, appdata = authoritative*, *seeded from host path + sha256*, *credential screen*.
```yaml
# beets configuration for the SABnzbd post-processing pipeline
#
# Consumed by:
#   container  sabnzbd  (ghcr.io/linuxserver/sabnzbd — beets 2.13.1 ships inside the image)
#   ...
# VENDORED 2026-08-18 (plan 01-07, SAFE-01 / D-28). This file lived only on the host
# until now. The repo copy is for review and history; the compose mount in
# ../sabnzbd.yaml points at the appdata copy, which is authoritative at runtime.
# ...
# mtime 2026-06-24). No credential of any kind was present. Screened for a Discogs
# user credential, for any field named after a credential class, for URLs carrying
# embedded credentials, for e-mail addresses, and for high-entropy strings. All seven
# checks returned clean, so nothing here is redacted and there is no placeholder to
# substitute. Re-screen before committing any future change to this file.
```
**Difference:** this file is **authored, not seeded**. The live host `config.yaml` is a pasted compose file (F4), so the provenance line should say it *replaces* that file and name its sha256. It should not say it was seeded from it.

**SAFE-01 block to copy verbatim** (lines 114-144, all three `auto: no` keys with their comments):
```yaml
scrub:
    auto: no   # scrub STRIPS all existing tags from a file on import. ...
lastgenre:
    auto: no   # lastgenre OVERWRITES the genre field from Last.fm. ...
embedart:
    auto: no   # embedart REWRITES the audio file to embed cover artwork. ...
```
**Required keys (D-27):** `plugins: musicbrainz`, the three SAFE-01 keys above, `library: /config/library.db`. **Nothing else.** All other survivor configuration is Phase 6.

**Three hard content constraints**, each enforced by an existing tool that scans every `*.yaml` under `stacks/selfhosted/`:
1. **No non-comment `/mnt/tank/media` string.** `check-music-freeze.sh:276` runs `grep -rn '/mnt/tank/media' "$STACKS" --include='*.yaml'`, and section 2 parses each hit as a declared volume. Only lines whose body starts with `#` are skipped (`:266`). The live host file contains `/mnt/tank/media:/media:rw` (F4). **Never seed from it**, or section 2 goes red.
2. **No `image:` key.** `renovate.json5:28` (`"/stacks/selfhosted/.*\\.ya?ml$/"`) feeds every yaml here to the docker-compose manager, and `check-renovate.sh:90,100` inventory `image:` lines.
3. **Not under a directory named `beets-config/`.** `.gitignore:50` ignores `**/beets-config/*.yaml`. Verified: `git check-ignore` returns nothing for `stacks/selfhosted/arrs/beets/config.yaml`.

---

### `stacks/selfhosted/arrs/sabnzbd.yaml` (compose; D-08, D-09, sweep corrections)

**Analog:** itself. Mount line to copy for `audio.bash` is line 95:
```yaml
      - /mnt/fast/appdata/arrs/sabnzbd/config/scripts/beets-config.yaml:/config/scripts/beets-config.yaml:rw  # Vendored beets config (see above)
```
New line: `- /mnt/fast/appdata/arrs/sabnzbd/config/scripts/audio.bash:/config/scripts/audio.bash:ro`. The host file is `0777`, so the execute bit survives. D-09 discretion covers flipping line 95 to `:ro` in the same recreate.

**NOTE-block pattern to copy for the new mount:** lines 56-90. The house style has four parts: *what it is and who consumes it*, *why it is vendored*, *what breaks if you revert it*, *how much the mount actually protects, measured*.

**Text that becomes false and must be corrected in the same edit:**

| Lines | Current text | Why false after Phase 4 |
|---|---|---|
| 56-61 | "It is the config audio.bash line 285 hands to beets on EVERY music download" | line 285 is stripped (D-10) |
| 89-90 | "Plan 01-09 folds that comparison into scripts/quick-health-check.sh." | never built (F6). D-13 builds it, so re-point it at the new block by anchor, not by line |
| 93 | "Same hybrid shape as arrs/soulbeet.yaml." | file deleted |
| 93-94 | "`plugins:` line is knowingly broken ... Phase 4 TAGR-05 owns it." | fixed by TAGR-05 |

**Withdrawn-claim convention:** paraphrase a withdrawn claim, never quote it. See `quick-health-check.sh:238-241` and `:353-360`: *"paraphrased rather than quoted so a mechanical grep for it over this repo keeps returning zero"*.

**Recreate hazards (not a file pattern; carry into the plan).** PR #310 (`sabnzbd 5.1.0 → 5.1.3`) is open with automerge labels. Assert that the tag at line 32 is resident in `docker image ls` before `up -d sabnzbd` (Pitfall 8).

---

### `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` (TAGR-05, D-11)

**Analog:** itself.
- Line 35 `plugins: embedart` → `plugins: embedart musicbrainz`. D-17 requires the broken probe to differ **only** in this line.
- Lines 24-34 (the `KNOWN DEFECT — DO NOT "FIX" IT HERE` block) → replace with a dated *fixed by Phase 4 TAGR-05* note. Keep the explanation of the 2.4.0 plugin change: it is why the line matters.
- Lines 3-8 (*Consumed by … line 285*) → nothing invokes this config after the strip. Say that it is a **defused guard** (D-11) that exists to stop a stock `setup.bash` re-download.
- Line 13 (`Same hybrid shape as soulbeet/beets_config.yaml`) → re-point at the new survivor config or drop it.
- Line 110 `log: /config/scripts/beets.log`: leave it (D-10 scope). The sweep grep `beets\.log` will hit it, so record a **keep-with-reason** verdict.
- Line 22 is the file's own rule: re-screen for credentials before committing.

---

### NEW `stacks/selfhosted/arrs/sabnzbd/audio.bash` (vendored hook, D-08/D-10)

**Vendoring analog:** `beets-config.yaml` (repo copy) + `sabnzbd.yaml:95` (mount pointing at the appdata copy). Research Pattern 1 applies: appdata is runtime-authoritative, the repo copy is for review, and a drift check asserts byte equality.

**Content source:** the live host file `/mnt/fast/appdata/arrs/sabnzbd/config/scripts/audio.bash` (339 lines, sha256 `fdcddca2…`). There is no in-repo analog for the content itself.

**⚠ Byte-identity constraint: no provenance header in this file.** VALIDATION C3-a asserts that `diff` against the live copy shows **exactly one removed line** (285) and that guard lines 27-35 stay byte-identical. The `beets-config.yaml` convention of a comment header would break that assertion. **Put the provenance in the `sabnzbd.yaml` NOTE block instead** (that file already carries the provenance for `arr-scripts` at `:43-54`).

**Line map** from `04-RESEARCH.md` § *audio.bash anatomy*:
- Remove **only** line 285.
- Do **not** touch 27-35 (guard), 272-273 (`rm library.blb`), 286-295 (log lines, OQ5/D-31), 322-324 (gate), or 334-335 (`chmod`, baseline Exit(1)).

---

### `renovate.json5` (D-14, D-30, index-reference fix)

**Analog:** the Jellyfin rule, lines 451-469
```json5
    {
      "description": "Jellyfin: minor releases are de-facto majors -- require manual review. ... NO allowedVersions ceiling: see packageRules[3], the wrtag <0.30.0 pin added on a misdiagnosis on 2026-06-24, which has been enforcing a broken state ever since. KNOWN COSMETIC WART, documented rather than fixed: ...",
      "matchDatasources": [
        "docker"
      ],
      "matchPackageNames": [
        "jellyfin/jellyfin"
      ],
      "matchUpdateTypes": [
        "minor",
        "major"
      ],
      "automerge": false,
      "addLabels": [
        "stack:media",
        "major-update",
        "manual-review-required"
      ]
    }
```
**Edits:**
1. **Delete** lines 90-104 (the wrtag rule, `packageRules[3]`).
2. **Append after line 469** the two-rule shape from `04-RESEARCH.md` Code Example 1, formatted in this file's one-key-per-line array style: first a **versioning-only** rule (`"versioning": "regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)-ls(?<build>\\d+)$"`), then the **manual-review** rule. `versioning` and `matchUpdateTypes` in one object is **rejected** by the validator.
3. **Rewrite line 452's index references by description, not number.** It cites `packageRules[2]` (still correct), `packageRules[5] only catches MAJOR` (becomes `[4]`), and `see packageRules[3], the wrtag <0.30.0 pin` (after the delete, `[3]` is the Security rule). Point the wrtag reference at "the retired wrtag `<0.30.0` pin, deleted in Phase 4".
4. **Sweep item the research table missed:** lines 415-423, `"Auto-label by stack: Music"`, match `**/stacks/selfhosted/music/**`. That directory is deleted by D-05, so the rule matches nothing. The `wrtag|soulbeet` grep cannot see it. It needs a D-07 verdict (delete, or keep with a reason). Deleting it does not move `[2]` or `[4]`.

**Gate:** `renovate-config-validator --strict --no-global renovate.json5` → exit 0, then a scratch copy with `"automerg": false` → exit 1. Install the validator in a scratch prefix (`npm install --prefix "$S" renovate@44.80.0 --ignore-scripts`). **Never `npx --yes`**: `check-renovate.sh:56-58` forbids it by name.

---

### `scripts/check-renovate.sh` (D-22, F12, F13)

**Analog:** itself, plus the PATH-stub harness recorded in `02.1-08-SUMMARY.md` lines 152-175.

**Line 62** (F13, validates as *global* config today):
```bash
  if renovate-config-validator "$CONFIG_FILE"; then
```
→ `renovate-config-validator --no-global "$CONFIG_FILE"`

**Lines 90 and 100** (latent abort: `grep -r` exits 1 on zero matches under `set -euo pipefail`, line 5):
```bash
YAML_WITH_IMAGES=$(grep -rl "image:" stacks/selfhosted --include="*.yaml" --include="*.yml" 2>/dev/null | sort)
IMAGES=$(grep -rh "^\s*image:" stacks/selfhosted --include="*.yaml" --include="*.yml" 2>/dev/null | \
```
→ wrap the grep: `$( { grep -rl … || true; } | sort)` (Code Ex. 3).

**Lines 115, 138 and 157** (`grep -v '^$' | wc -l` aborts on an empty set; **157 aborts exactly when zero Renovate PRs are pending**):
```bash
POSTGRES_COUNT=$(echo "$POSTGRES_INSTANCES" | grep -v '^$' | wc -l | tr -d ' ')
REDIS_COUNT=$(echo "$REDIS_INSTANCES" | grep -v '^$' | wc -l | tr -d ' ')
RENOVATE_COUNT=$(echo "$RENOVATE_BRANCHES" | grep -v '^$' | wc -l | tr -d ' ')
```
→ `printf '%s\n' "$X" | awk 'NF{n++} END{print n+0}'`

**Out of scope, record only:** lines 101-103 `sed 's/^\s*…'` (`\s` under BSD sed, A6).

**PATH-stub harness to copy** (`02.1-08-SUMMARY.md:158-160`, and the 3-route table at `:164-168`):
> *"a four-line stub `renovate-config-validator` placed ahead of `PATH`. **Nothing was installed and no network call was made** — `command -v` cannot tell the difference. Created, used, deleted."*

For line 157 the stub is a fake `git`. It must return 0 for `fetch` (line 155 runs `git fetch origin --quiet`) and print nothing for `branch -r`. Expected output: `✅ No pending Renovate PRs`, exit 0. Record a route table in the same shape as 02.1-08's (stub input, script exit, verdict line). The stub is **not committed**. It lives in scratch and is deleted after use.

---

### `scripts/check-music-freeze.sh` (D-21, D-25 census)

**Analog A — mount enumeration and classification:** itself § 1, lines 188-246
```bash
  RUNNING_IDS="$(docker ps -q || true)"
  ...
    MOUNT_ROWS="$(docker inspect --format \
      '{{$n := .Name}}{{range .Mounts}}{{$n}}|{{.Source}}|{{.Destination}}|{{if .RW}}rw{{else}}ro{{end}}{{"\n"}}{{end}}' \
      $RUNNING_IDS 2>/dev/null | sed 's#^/##' | grep -v '^[[:space:]]*$' || true)"
...
while IFS='|' read -r cname csrc cdst cflag; do
  [[ -z "${cname:-}" ]] && continue
  [[ "${cflag:-ro}" != "rw" ]] && continue
  touches_library "$csrc" || continue
  entry="$cname ($csrc:$cdst:rw)"
  if [[ "$cname" =~ $TAGGER_PATTERN ]]; then
...
count_lines() { printf '%s' "${1:-}" | grep -c . || true; }
```
- **Line 80** `TAGGER_PATTERN='beets|soulbeet|wrtag|lidarr'` is the name-based classifier D-21 replaces. Reuse the same `|`-separated row format and `while IFS='|' read` loop, but classify a container as tagger-capable when a `.Source` contains a beets config or DB path.
- **Lines 190 and 199 use `docker ps -q`, which lists running containers only** (Pitfall 12). The new census must enumerate `docker ps -aq` so that `exited` and `created` containers are counted. This is the estate's `created`-state blind spot.
- **Pitfall 15:** print "tagger-capable (mounts a beets config/DB)" separately from "rw on the library". sabnzbd is permanently tagger-capable (D-11 keeps its config mount) and holds **no** `/mnt/tank/media` mount.

**Analog B — env overrides (P2): copy from `scripts/check-jellyfin-transcode.sh`**

Header doctrine, lines 121-133:
```bash
# ENV OVERRIDES - three, all in the ${VAR:-default} form so a grep can prove they exist:
#     ZFS_HOST             the Proxmox host that owns the pool
#     ...
#   They exist so plan 02.1-10's three NEGATIVE CONTROLS - the proofs that this check fails
#   closed rather than reporting green because it could not look - can be run WITHOUT MUTATING
#   ANY REAL FILE. ...
#   Overriding a path does NOT weaken the gate. ...
#   Do not relax the gate to accommodate a control.
```
The block itself, lines 150-154:
```bash
# --- env overrides (see ENV OVERRIDES in the header) ------------------------------------------
ZFS_HOST="${ZFS_HOST:-172.16.1.158}"
JELLYFIN_CONTAINER="${JELLYFIN_CONTAINER:-jellyfin}"
JELLYFIN_SECRETS="${JELLYFIN_SECRETS:-/mnt/fast/secrets/jellyfin-deercrest.env}"
```
The "override can only make it red" rule, lines 219-222 (*"(iii) OVERRIDING AN EXPECTATION CAN ONLY MAKE THIS CHECK RED, NEVER GREEN … assert_enc() has no skip branch"*). `RETIRED_DB_PATHS` pointed at an existing scratch file must therefore produce exit 1. No override value may suppress a check.

**Analog C — assertion helper with expected/found wording:** `check-jellyfin-transcode.sh:636-653` (`assert_enc`), which calls `fail "$key DRIFTED — expected='$want' found='$got' …"`. The per-path census helper should say, for example, `retired DB PRESENT: <path>` / `survivor DB count expected=1 found=N`.

**Analog D — "UNKNOWN, never 0" summary lines:** `check-jellyfin-transcode.sh:759-774`
```bash
if [[ $CONTAINER_PRESENT -eq 1 ]]; then
  echo "  volume mounts:           ${#VOLUME_MOUNTS}  (target 0)"
else
  echo "  volume mounts:           UNKNOWN — container absent or docker unavailable  (target 0)"
fi
...
if [[ $ENC_ASSERTED -eq 0 ]]; then
  echo "  encoding values:         UNKNOWN — section 5 could not look (see 'unreachable' below)"
```
Applied here: when docker is unavailable, the census counters print `UNKNOWN` and FAILURES increments (DEF-03-11).

**Analog E — summary-line style in this file:** lines 517-536
```bash
echo "📊 7. Summary"
rule
echo "  tagger-class writers:        $TAGGER_COUNT   (target 0)"
echo "  consumer-class writers:      $CONSUMER_COUNT   (Jellyfin, documented exception D-21)"
echo "  unclassified writers:        $UNCLASSIFIED_COUNT   (target 0)"
```
The three D-25 counters follow this `label: value   (target N)` shape, with Jellyfin printed on its own line (F10).

**⚠ Cross-file anchor, do not renumber silently.** `quick-health-check.sh:539` and `:555` anchor on `'/^📊 7\. Summary/'` and select `tagger-class|unclassified|declared rw|ownership mismatches` (`:540`). Rename any selected label, or renumber the summary heading when adding a section, and the fold-in lands in its WR-09 UNKNOWN branch. Either:
- insert the new census without renumbering, e.g. as section `6b`, or
- change both files in the same commit.

The selector must be widened to include the new counter labels (C5-a). `check-jellyfin-transcode.sh:740-755` is the cross-file contract comment to copy for listing the selected tokens.

**Also correct:**
- the header "What it covers" list (`:18-29`)
- section-2 prose `:252-255`, which names `arrs/soulbeet.yaml`
- the header `:9-12` fold-in description, if the invocation changes

**Pattern 3 (research): land this before the host deletion.** Its first run on the un-retired estate is the driven negative control, and it must go red naming each retired path.

---

### `scripts/quick-health-check.sh` (D-13 drift block; selector widening)

**Analog A — a remote command with a pipe, bound Linux-side, status branched on 124 first:** lines 424-437
```bash
RUNNING=$(ssh -n $SSH_OPTS root@172.16.1.159 "set -o pipefail; timeout $REMOTE_TIMEOUT docker ps -q | wc -l")
RUNNING_RC=$?   # ssh propagates the remote status — NO local pipe above, see the note above
RUNNING=$(printf '%s' "$RUNNING" | tr -d '[:space:]')
if [ "$RUNNING_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — 'docker ps' exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    echo "  Nothing was counted. This is NOT 'zero containers running'."
    EXIT_CODE=1
elif [ "$RUNNING_RC" -ne 0 ] || ! echo "$RUNNING" | grep -qE '^[0-9]+$'; then
    echo "⚠️  UNKNOWN — could not count running containers (ssh exit $RUNNING_RC, output '$RUNNING')."
    EXIT_CODE=1
else
```
The rule at `:217-226`: any remote string containing `|` needs **both** `set -o pipefail` and a captured ssh status. The rule at `:413-418`: take `RC=$?` on the **next line**, with **no local pipe** in the assignment, because `PIPESTATUS` does not rescue an assignment.

**Analog B — fold-in block ordering** (empty output before RC, 124 deferral, anchor guard): lines 491-557
```bash
MUSIC_OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 \
    "timeout $REMOTE_TIMEOUT bash /mnt/fast/stacks/scripts/check-music-freeze.sh 2>&1")
MUSIC_RC=$?   # ssh propagates the remote exit status — do NOT pipe before capturing this
MUSIC_OUT=$(printf '%s\n' "$MUSIC_OUT" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g')
if [ -z "$MUSIC_OUT" ] && [ "$MUSIC_RC" -ne 124 ]; then
    echo "⚠️  UNKNOWN — 172.16.1.159 unreachable or the audit produced no output"
    ...
    EXIT_CODE=1
elif [ "$MUSIC_RC" -eq 124 ]; then
    echo "⚠️  UNKNOWN — the remote audit exceeded its ${REMOTE_TIMEOUT}s bound and was killed."
    ...
    EXIT_CODE=1
elif [ "$MUSIC_RC" -eq 0 ]; then
    SUMMARY=$(echo "$MUSIC_OUT" | sed -n '/^📊 7\. Summary/,$p' \
              | grep -E 'tagger-class|unclassified|declared rw|ownership mismatches')
    if [ -z "$SUMMARY" ]; then
        echo "⚠️  UNKNOWN — the harness exited 0 but its '📊 7. Summary' block was not found."
        ...
        EXIT_CODE=1
    else
        echo "✅ Intact"
```
The D-13 block copies this order exactly:
1. empty output (unless RC 124) → UNKNOWN
2. RC 124 → UNKNOWN (timeout)
3. any other nonzero RC → UNKNOWN (could not look)
4. per-file `repo == host` comparison → `❌` naming the file **and both hashes**, `EXIT_CODE=1`

**Never `info()`**: the report-only shape is the CR-01 defect. The remote string from `04-RESEARCH.md` Code Ex. 6 contains pipes, so it must start `set -o pipefail;`. It compares `git show HEAD:<path>` with the appdata file **host-side**, so the workstation tree is irrelevant.

**Analog C — the driven-control variable (P4):** `REMOTE_TIMEOUT` at `:234` (`REMOTE_TIMEOUT="${REMOTE_TIMEOUT:-120}"`) is set on the workstation and interpolated into remote strings at `:424`, `:492`, `:568` and `:652`. It is the only way a caller's value reaches the far side. A D-13 drift expectation override should take this shape.

**Analog D — the in-file notice for a new fatal block:** lines 45-50
```bash
# ⚠️  EXIT-CODE BEHAVIOUR CHANGED AGAIN — A THIRD FATAL BLOCK WAS ADDED 2026-09-03 (phase 02.1,
#     plan 02.1-10, D-20).
#     scripts/check-jellyfin-transcode.sh now also runs here, and it too exits this script 1.
#     Stated in the file for the same reason as the two notices above: ...
```
Keep the literal phrase `EXIT-CODE BEHAVIOUR CHANGED`; it is greppable by convention (`:21-24`, `:126-130`). State what makes the block exit 1 and which rows are asserted versus reported, following `:58-78` and `:88-117`.

**Analog E — the failure tail must name every fatal block:** lines 742-744
```bash
    echo "❌ Health check FAILED. The failing block is whichever one above carries a ❌ or a ⚠️ —"
    echo "   that is any of: the container counts, the music freeze harness, the consumers audit,"
    echo "   or the Jellyfin transcode retention audit."
```
Add the vendored-file drift block to this list. Lines 736-741 explain why a stale pointer here is itself a defect.

**Place the new block after the Traefik-dashboard check (`:471-477`)**, inside the WR-10 reachability gate (`:306-344`). It inherits the gate and must not add a second probe.

---

### `scripts/normalise-dj-tags.py` (D-23 WAV write path, `--self-test`)

**The defect:** `read_tags()` lines 501-511 send every non-MP3, WAV included, through easy mode:
```python
    handle = mutagen.File(path, easy=True)
    if handle is None:
        raise ValueError(f"mutagen could not identify {path}")
    if handle.tags is None:
        handle.add_tags()
    values = {}
    for field in WRITABLE_FIELDS:
        got = handle.tags.get(field)
```
and `write_tags()` lines 633-635:
```python
    for field, new in changes.items():
        handle.tags[field] = [new]
    handle.save()
```
**Analog, in the same file:** the MP3 branch works at ID3 frame level through `FIELD_FRAME` (`:193`, `{"album": "TALB", "artist": "TPE1"}`). The read side is lines 480-499:
```python
        values = {}
        for field in WRITABLE_FIELDS:
            frames = tags.getall(FIELD_FRAME[field])
            text = frames[0].text[0] if frames and frames[0].text else None
            values[field] = text if (text is None or str(text).strip()) else None
        return tags, values
```
and the write side is lines 617-628 (encoding reuse + `setall`):
```python
        for field, new in changes.items():
            frame_id = FIELD_FRAME[field]
            existing = handle.getall(frame_id)
            encoding = existing[0].encoding if existing else 1
            try:
                new.encode({0: "latin-1", 1: "utf-16", 2: "utf-16-be", 3: "utf-8"}[encoding])
            except (UnicodeEncodeError, KeyError):
                encoding = 1
            handle.setall(frame_id, [getattr(id3, frame_id)(encoding=encoding, text=[new])])
```
Add a `.wav` branch in both functions with the same frame-level shape. Use `mutagen.wave.WAVE(path)`, `add_tags()` when `tags is None`, `w.tags.getall/setall`, then `w.save()` (`04-RESEARCH.md` Code Ex. 7). FLAC and other formats keep the easy path; D-23 scope is WAV only.

**⚠ Backstop blind spot for WAV.** `assert_frame_set_unchanged()` (`:562-596`) relies on `id3v2_frame_ids()` (`:440-472`), which reads an ID3 header at **file offset 0** (`head[:3] != b"ID3"`). In a WAV the ID3 tag sits inside a RIFF `id3 ` chunk, so the function returns `None`, and the assertion then **silently returns** (`if before is None: return`, `:575-576`). The five-frame "every other frame intact" check needed for WAV (`APIC`, `TDRC`, `TIT2`, `TPE1`, `TRCK`) must therefore come from either `mutagen.wave.WAVE(path).tags` read before and after, or a RIFF-chunk walk. `04-RESEARCH.md` Don't Hand-Roll already calls for "~20 lines of `struct` over the RIFF chunk list" for `IPRD`. One walker can serve both.

**NDJSON record to extend** (dry-run and apply), lines 967-982:
```python
                    out_fh.write(
                        json.dumps(
                            {
                                "mode": "apply" if applying else "dry-run",
                                "folder": folder_name,
                                "path": path,
                                "field": field,
                                "rule": rule,
                                "old": old,
                                "new": new,
                                "written": written,
                                "artist_policy": args.artist_policy,
                            }
```
Add `"info_iprd"` when a RIFF `LIST/INFO/IPRD` value disagrees with the new `TALB` (D-23: the disagreement is a recorded finding, not a silent one). Failures stay in the `.failed` ledger shape at `:949-958` (`path`, `stage`, `exception`, `detail`).

**`--self-test` analog:** `scripts/spike03-wrtag-arms.sh:389-418` is the only self-test in the repo. It is table-driven, with `ok`/`bad`, a `fails` counter, and a heredoc `CASES` table where each row carries an expected verdict and a reason. Carry the same idea over to Python: three cases (untagged, ASCII-tagged and non-ASCII-tagged WAV), each asserting the written album reads back and the five frames are byte-equal. Build the files in a temp directory; the stdlib `wave` module writes the PCM.

**argparse interaction:** `parse_args()` line 659 makes `target` a **required positional**, and `resolve_target_or_die` / `assert_inside_scratch` fence every path to `SCRATCH_ROOT` (`:186`). `--self-test` must be handled before or instead of the required `target`, or it will exit 2. Its temp files must not live under the scratch fence. Keep the self-test's own write path explicit, and **do not relax** `assert_inside_scratch` for the real run.

**Where it runs:** inside `lscr.io/linuxserver/beets:2.13.1-ls349` (`docker run --rm --entrypoint python3 …`), which is the only place mutagen 1.48.1 exists. Never pull.

---

### `scripts/spike03-discogs-probe.py` (MB-only mode, F14)

**Analog:** the existing `--require-plugin` parameterisation, which is the house pattern for "narrow the gate explicitly, visibly, never silently". Lines 259-273:
```python
# The gate is therefore PARAMETERISED, not weakened. `--require-plugin` is repeatable and
# defaults to REQUIRED_PLUGINS, so:
#   * every existing invocation keeps the full two-plugin gate with no change in behaviour;
#   * an MB-only cell must STATE its narrower expectation explicitly on the command line
#     (`--require-plugin musicbrainz`), so the weaker gate is visible in the run transcript
#     rather than silently inferred from the config.
...
REQUIRED_ENV = ("SPIKE_CONFIG", "SPIKE_DB", "DISCOGS_USER_TOKEN")
```
and lines 850-859 (the argparse shape to copy for `--mb-only`).

**Every place that hard-requires Discogs today; an `--mb-only` flag must guard each one:**

| Line | Code | MB-only behaviour |
|---|---|---|
| 273 | `REQUIRED_ENV = (…, "DISCOGS_USER_TOKEN")` | drop the token from the required set |
| 461-483 | `require_env()`; `:482` `SECRETS.append(env["DISCOGS_USER_TOKEN"])` | no token lookup, nothing appended |
| 505 | `config["discogs"]["user_token"] = env["DISCOGS_USER_TOKEN"]` | skip |
| 521-540 | refusal 1 | add the inverse check: **refuse if `discogs` IS loaded** (Pitfall 9) |
| 895 | `identity = discogs_identity_probe(...)` (refusal 2) | skip entirely |
| **897-898** | `config["discogs"]["index_tracks"].get()`, `config["discogs"]["search_limit"].get()` | **not named in research.** These run unconditionally and read the `discogs` config, which does not exist when the plugin is absent. Guard them |
| 938-940, 1072 | banner and summary print `identity[...]` | print "MB-only: no identity probe" instead |
| 816-820 | epilog: "Requires SPIKE_CONFIG, SPIKE_DB and DISCOGS_USER_TOKEN" | update |

`--ledger` is `required=True` (`:832`), so the D-16 invocation in `04-RESEARCH.md` Code Ex. 4 must add `--ledger /config/probe-04/<prefix>`. `arm_of()` (`:899-905`) returns `None` outside `/mnt/tank/downloads/spike-03`, which is harmless.

---

### `scripts/spike03-image-headroom.sh` (Pitfall 11)

**Analog:** itself, lines 106-117
```bash
# Allow-list. Anything whose REPOSITORY:TAG contains one of these substrings is never a candidate,
# even with no container referencing it. The three spike images are here so that a re-run of
# `inventory` after task 3's pulls cannot list the images the phase just fetched; ...
KEEP_PATTERNS=(
  "sentriz/wrtag"
  "lscr.io/linuxserver/beets"
  "linuxserver/beets"
  "metasauce/beets-flask"
  "redis"
)
```
Remove line 112 and update the comment at 107-110 ("The three spike images"). Keep `metasauce/beets-flask` (Phase 5) and both beets entries.

---

### `scripts/spike03-wrtag-arms.sh` (keep-with-reason)

**Analog:** its own header convention (lines 1-60: *Where it runs*, *Usage*, *WHAT THIS MEASURES*). Add a dated header note:
- the default `WRTAG_YAML="${WRTAG_YAML:-stacks/selfhosted/music/wrtag.yaml}"` (line 147) now points at a deleted file
- reproduce with `git show <pre-deletion-sha>:stacks/selfhosted/music/wrtag.yaml > <scratch>` plus `WRTAG_YAML=<scratch>`
- line 48 (`renovate.json5:91`) cites a rule that no longer exists

Do not delete the script: `03-WRTAG-EVIDENCE.md` cites it.

---

### `.gitignore` (sweep)

**Analog:** itself, lines 44-45
```
# Deliberately NARROW - it names the generated file, not `*config*.yaml`, so it cannot mask a
# legitimate tracked config such as stacks/selfhosted/music/wrtag.yaml or a stack's config.yaml.
```
Replace the deleted example. `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml` is the natural substitute, and so is the new survivor `config.yaml`. That fits: the comment's point is that tracked configs are *not* masked. Leave lines 49-50 as they are.

---

### `CLAUDE.md` and `.planning/research/STACK.md` (D-07, D-14, F15)

**Generated-region markers in `CLAUDE.md`:** `<!-- GSD:project-start source:PROJECT.md -->` (`:91`) to `:157`, and `<!-- GSD:stack-start source:research/STACK.md -->` (`:159`) to `:343`. Any correction inside those ranges must also land in the source file.

**The same text sits at two locations:**

| Claim | `CLAUDE.md` | `STACK.md` |
|---|---|---|
| "7,451 files across ~1,000 folders" (folder count off ~8×; real denominator 144) | 234 | 195 |
| "wrtag: EITHER fix the pin …" + "drop the Renovate rule pinning <0.30.0" | 276-279 | 412-415 |
| "Renovate rule pinning wrtag `<0.30.0`" row | 294 | 471 |

The remaining `CLAUDE.md` hits (102, 163-168, 198, 206, 212-236, 283, 293, 315-316, 325-327, 332/338) come from the `04-RESEARCH.md` § D-07 table. **Keep** line 309's `1-115` split instruction.

**In-band correction shape** for `STACK.md` (a dated research snapshot, so correct it in place with a note and keep the original visible): copy `beets.md:981-990`.
```markdown
### One correction to this page's own § *The recovery fence*

That section states, as a hard constraint, *"beets has **no `undo` command** — ..."*. **That remains
true of the beets CLI and is narrower than it reads: ...** The original wording is left standing
above because it was correct against what it measured.
```
The D-14 finding lands **verbatim** (CONTEXT § Specifics), quoted from D-14 in `04-CONTEXT.md:125-129`.

---

### `.planning/PROJECT.md` (entry-points table; D-24 dismissal)

**Analog for the table correction:** the table itself, lines 58-66. Correct the wrtag row (64) and the soulbeet row (63) in-band and dated. The 7,451 **file** count at line 72 is correct and stays.

**Analog for D-24's reasoned dismissal:** line 214 opens *"**Accepted residual risk: `sec=sys` on a trusted LAN.** … Recorded as a **choice, not an oversight or a silence**, so a future security review meets a reasoned answer."* Line 215 is the second instance of the same form. A Discogs-rotation row copies it: bold title, "choice, not an oversight or a silence", the operator's words verbatim, a pointer to `03-DECISION.md` § 9 and DEF-03-21, and a "Revisit if …" cell.

---

### `.planning/ROADMAP.md` (criterion 4 amendment, D-20)

**Analog:** lines 262-273, the 02.1-11 amendment, as an indented blockquote directly under the criterion:
```markdown
     > **Amended 2026-09-03 by plan 02.1-11 (gap closure, CR-01).** This criterion previously read
     > "…the transcode quota and the five encoding values", which was false as implemented: ...
     > The **substance is kept, not reduced** — ... What
     > changed in the wording is the ambiguity the verifier flagged: ...
```
The target is criterion 4 at lines 521-524 (*"…and a `--pretend` run on one known-good album returns a MusicBrainz candidate…"*). The amendment follows this sequence:
1. quote the original wording
2. explain why `--pretend` is unsatisfiable (`beets/importer/session.py` v2.13.1 replaces the pipeline with `log_files`, so `lookup_candidates` is never called)
3. name the substitute: the `tag_album()` probe plus a hand-read `beet import -t`, with the D-17 negative control, on the D-29 album
4. state "substance kept, not reduced"

Also: line 530 (`**Research**: not needed …`) is now false, and line 529 (`**Plans**: TBD`) becomes the plan list.

---

### `.planning/REQUIREMENTS.md` (TAGR-05 amendment, D-20)

**Analog:** the TRAN-05 traceability row at line 256. It contains `**ADDENDUM 2026-09-03 (02.1-11) — TRAN-05 was RE-OPENED …** The text above is an accurate record of what was true on 02.1-10 and is deliberately not rewritten.` The requirement line itself (`:97-100`) was edited to match the code, and the history went into the traceability row.

**Target:** TAGR-05 at lines 129-130 and its traceability row at line 267. TAGR-05 does not mention `--pretend`, so the amendment is a scope clarification (D-27 widens "every remaining beets config" to include the new survivor config). Put it in the traceability row, in the ADDENDUM shape.

---

### `stacks/selfhosted/arrs/beets.md` (D-14 correction, D-25 closure)

**Analog A — the header to correct:** lines 3-5 (links to `soulbeet.yaml`), line 13 (the banner "Both beets definitions … wrtag's library mount is deleted"), lines 27-47 (the "Two beets, one library" table and "The real tunables live in `soulbeet/beets_config.yaml`"). These are living text, so correct them in place.

**Analog B — the closure-section shape with a pasted executed run:** lines 199-204 and 232-238
```markdown
## Phase 1 safety harness (2026-08-18)

The library was writable by ten containers, four tagging entry points and Lidarr's renamer, with
no before-state of the tags anywhere. Phase 1 closed that. This section records **what is true
now and why**; the narrative lives in
`.planning/phases/01-safety-harness-and-freeze-the-writers/01-0N-SUMMARY.md`.
...
From `bash scripts/check-music-freeze.sh` on LXC 100, 2026-08-18T22:27:09Z, ANSI stripped,
otherwise unedited.
```
The new `## Phase 4 — one tagger (<date>)` section appends after line 1039 and follows this pattern. It:
- names the exact command and its UTC timestamp
- pastes the three D-25 counters "ANSI stripped, otherwise unedited" from an **executed** run, with Jellyfin printed separately (F10)
- names the standing check that keeps asserting them

**Analog C — the one-line outcome table:** lines 953-961 (`| | Chosen | Because |`).

**Analog D — the in-band correction of this page's own earlier sections:** lines 981-990. Use it for the D-14 verbatim finding. It also retires the "Standing action" at lines 1004-1039 for the Discogs token, which D-24 converts into a reasoned dismissal: amend in-band and dated, never delete.

Historical dated sections (Phase 1/2/3) are **kept** and amended in-band only (research § D-07 table).

---

## Shared Patterns

### S1. Fail-closed remote health block
**Source:** `scripts/quick-health-check.sh:424-437` (count), `:491-557` (fold-in), rules at `:192-234` and `:413-418`, notices at `:45-50`
**Apply to:** the D-13 drift block; any new selector token for D-21/D-25
```bash
OUT=$(ssh -n $SSH_OPTS root@172.16.1.159 "set -o pipefail; timeout $REMOTE_TIMEOUT <cmd | …>")
RC=$?   # NO local pipe in the assignment above
if [ -z "$OUT" ] && [ "$RC" -ne 124 ]; then  …UNKNOWN…; EXIT_CODE=1
elif [ "$RC" -eq 124 ]; then                 …UNKNOWN (timeout)…; EXIT_CODE=1
elif [ "$RC" -ne 0 ]; then                   …UNKNOWN / BROKEN…; EXIT_CODE=1
else                                         …assert, fail() names expected+found…
fi
```

### S2. `fail` / `pass` / `warn` / `info` helpers and the FAILURES counter
**Source:** `scripts/check-music-freeze.sh:116-121` (repeated verbatim in `spike03-image-headroom.sh:126-129`)
**Apply to:** every new assertion in `check-music-freeze.sh`
```bash
FAILURES=0
fail() { echo -e "  ${RED}❌ $*${NC}"; FAILURES=$((FAILURES + 1)); }
pass() { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}$*${NC}"; }
```
`info()` is **report-only**. An assertion must call `fail()` (CR-01).

### S3. Env-overridable expectations for driven negative controls
**Source:** `scripts/check-jellyfin-transcode.sh:121-133` (doctrine), `:150-154`, `:205-228` (the rule that an override can only make the check red)
**Apply to:** `RETIRED_DB_PATHS`, `SURVIVOR_DB` (freeze check); the drift expectation (quick-health-check, via the `REMOTE_TIMEOUT` interpolation shape, P4)

### S4. Vendored runtime file
**Source:** `stacks/selfhosted/arrs/sabnzbd/beets-config.yaml:1-22` (header) + `stacks/selfhosted/arrs/sabnzbd.yaml:56-95` (mount + NOTE)
**Apply to:** the survivor `config.yaml` (with its header) and `audio.bash` (**no header**; provenance goes in `sabnzbd.yaml`, because C3-a byte-identity forbids a header)

### S5. Deletion guard for `rm -rf` on appdata trees (D-04)
**Source:** `scripts/spike03-wrtag-arms.sh:242-286` (`fence_eval`: resolve both paths, then the prefix check, the required path component, the unresolved-string check, and the `..` component refusal), exercised by `self_test` at `:389-418`
**Apply to:** every host-side delete of `appdata/arrs/soulbeet`, `appdata/media/wrtag`, the sabnzbd `scripts/library.blb*`, `.config/beets/`, and the survivor's `library.db`/`musiclibrary.blb`/`config.yaml.old`. Research names this the CR-01 pattern (§ Known Threat Patterns).
```bash
  case "$real/" in
    "$preal/"*) : ;;
    *) FENCE_WHY="resolves to '$real', which is outside '$preal/'"; return 1 ;;
  esac
  ...
  case "$given" in
    *"/../"*|*"/.."|"../"*|"..")
      FENCE_WHY="contains a '..' path component - pass the resolved path instead"
      return 1
```

### S6. Fence copy of a live SQLite DB, then verification (D-35, and D-28/D-32 preconditions)
**Source:** `scripts/freeze-music-apply.sh:295-304` (copy), `:408-433` (verify), `:437-445` (MANIFEST header)
**Apply to:** the `wrtag.db` fence copy. It also gives the "confirm the fence holds a copy" check for every other DB before its `rm`.
```bash
    if command -v sqlite3 >/dev/null 2>&1 && sqlite3 "$src" ".backup '$dst'" 2>/dev/null; then
      mech="sqlite3-backup"
...
    if [[ -f "$src" ]] && [[ "$(sha "$src")" == "$(sha "$dst")" ]]; then
      chk_ok=$((chk_ok + 1))
    elif command -v sqlite3 >/dev/null 2>&1 \
         && [[ "$(sqlite3 "$dst" 'PRAGMA integrity_check;' 2>/dev/null | head -1)" == "ok" ]]; then
```
`.backup` rewrites page layout, so sha256 inequality is expected. `integrity_check ok` is the test (`:409-412`).

### S7. A secret passed to curl without entering argv (D-33 Cloudflare token)
**Source:** `scripts/check-music-consumers.sh:411`, `scripts/check-jellyfin-transcode.sh:613`
**Apply to:** the host-side `wrtag.deercrest.info` DNS record deletion using `/mnt/fast/appdata/traefik/secrets/cf_dns_api_token`
```bash
    -H @<(printf 'Authorization: Bearer %s\n' "$MA_TOKEN") --data-binary @- || true
```
Read the token file into a shell variable inside the process, never `$(cat …)` on a command line, and never `pgrep -af` (DEF-03-21).

### S8. In-band dated amendment that keeps the original wording
**Source:** `.planning/ROADMAP.md:262-273`; `.planning/REQUIREMENTS.md:256` (ADDENDUM); `stacks/selfhosted/arrs/beets.md:981-990`
**Apply to:** ROADMAP criterion 4, the TAGR-05 row, `PROJECT.md` rows 63-64, `STACK.md`, and the older `beets.md` sections. A withdrawn claim is **paraphrased, not quoted** (`quick-health-check.sh:238-241`), so a grep for it keeps returning zero.

### S9. Host-resident script conventions
**Source:** `scripts/check-music-freeze.sh:1-13,66-69`
**Apply to:** any new host-side helper
`#!/usr/bin/env bash`, `set -euo pipefail`, `REPO_ROOT=… ; cd "$REPO_ROOT"`, ALL-CAPS constants, a `# Where it runs:` header, and delivery by `git pull` at `/mnt/fast/stacks`. `quick-health-check.sh` is the exception: it is `#!/bin/bash` 3.2 on macOS, with no `timeout` and no GNU sed (`$'\033'`, not `\x1b`).

---

## No Analog Found

| File / operation | Role | Data Flow | Reason → use instead |
|---|---|---|---|
| Content of `stacks/selfhosted/arrs/sabnzbd/audio.bash` | hook | batch | Upstream third-party script on the host only. Content = the live file minus line 285. Only the vendoring shape has an analog (S4) |
| Survivor probe lifecycle (`up` → `beet version` ×2 → probe negative → positive → `import -t -W -C` → `down`) | host procedure | request-response | No script in the repo drives a manual-profile container. Use `04-RESEARCH.md` Pattern 2 and Code Ex. 4 directly. Host overlays `probe-04/{broken,fixed}.yaml` are **not** repo files. Note: D-27's `plugins: musicbrainz` in the survivor's base config means the `-c` overlay's `plugins:` now overrides a **present** key (research assumed the base had none). The D-17 ordering constraint (negative control before TAGR-05) already covers this, but the plan should record which base config was mounted during each run |
| Cloudflare DNS record deletion (D-33) | host procedure | request-response | No DNS-delete script in the repo. Only the token-handling half has an analog (S7) |
| Closing issue #306 (D-26) | manual/API | — | `gh issue close 306 --comment …`, with the four D-26 facts and the Pitfall 14 salvage answer |
| D-12 evidence checklist | artifact | — | `04-RESEARCH.md` Code Ex. 8 plus VALIDATION C3-c. It pre-declares the two `Audio.txt` lines (D-31) and the baseline `Exit(1): chmod` |

---

## Metadata

**Analog search scope:** `scripts/`, `stacks/selfhosted/arrs/`, `stacks/selfhosted/music/`, `renovate.json5`, `.gitignore`, `CLAUDE.md`, `.planning/{ROADMAP,REQUIREMENTS,PROJECT}.md`, `.planning/research/STACK.md`, `.planning/phases/02.1-*/02.1-08-SUMMARY.md`, `.planning/phases/04-collapse-to-one-tagger/`
**Files scanned:** 27
**Verification probes run (read-only):** `git ls-files` for vendored and tagger files; `git check-ignore -v` on the three proposed new paths (none ignored); a grep of `${VAR:-}` overrides across `scripts/*.sh`; line-anchored greps for every cited string
**Pattern extraction date:** 2026-09-11
